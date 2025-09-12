#!/bin/bash

# 🚀 ERPNext Production Deployment Script
# This script helps deploy ERPNext to production server

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$SCRIPT_DIR"
BACKUP_DIR="/opt/erpnext-backups"
LOG_FILE="/var/log/erpnext-deployment.log"

# Functions
log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE"
}

print_header() {
    echo -e "\n${BLUE}================================${NC}"
    echo -e "${BLUE} $1${NC}"
    echo -e "${BLUE}================================${NC}\n"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

check_requirements() {
    print_header "Checking Requirements"
    
    # Check if running as root or with sudo
    if [[ $EUID -eq 0 ]]; then
        print_warning "Running as root. This is not recommended for production."
    fi
    
    # Check Docker
    if ! command -v docker &> /dev/null; then
        print_error "Docker is not installed"
        exit 1
    fi
    print_success "Docker is installed"
    
    # Check Docker Compose
    if ! command -v docker-compose &> /dev/null && ! docker compose version &> /dev/null; then
        print_error "Docker Compose is not installed"
        exit 1
    fi
    print_success "Docker Compose is available"
    
    # Check if .env.production exists
    if [ ! -f "$PROJECT_DIR/.env.production" ]; then
        print_error ".env.production file not found"
        echo "Please copy .env.production.template to .env.production and configure it"
        exit 1
    fi
    print_success ".env.production file found"
    
    # Check available disk space (minimum 10GB)
    available_space=$(df / | awk 'NR==2 {printf "%.0f", $4/1024/1024}')
    if [ "$available_space" -lt 10 ]; then
        print_warning "Available disk space is less than 10GB ($available_space GB)"
    fi
    print_success "Disk space check passed ($available_space GB available)"
}

create_directories() {
    print_header "Creating Directories"
    
    # Create backup directory
    sudo mkdir -p "$BACKUP_DIR"
    sudo chown $USER:$USER "$BACKUP_DIR"
    print_success "Created backup directory: $BACKUP_DIR"
    
    # Create log directory
    sudo mkdir -p /var/log/erpnext
    sudo chown $USER:$USER /var/log/erpnext
    print_success "Created log directory: /var/log/erpnext"
}

setup_environment() {
    print_header "Setting up Environment"
    
    # Load environment variables
    source "$PROJECT_DIR/.env.production"
    
    # Validate required environment variables
    required_vars=("DB_ROOT_PASSWORD" "ADMIN_PASSWORD" "SITE_NAME")
    for var in "${required_vars[@]}"; do
        if [ -z "${!var}" ]; then
            print_error "Required environment variable $var is not set"
            exit 1
        fi
    done
    print_success "Environment variables validated"
}

deploy_services() {
    print_header "Deploying Services"
    
    cd "$PROJECT_DIR"
    
    # Pull latest images
    log "Pulling latest Docker images"
    docker compose -f docker-compose.prod.yml --env-file .env.production pull
    print_success "Docker images pulled"
    
    # Start services
    log "Starting services"
    docker compose -f docker-compose.prod.yml --env-file .env.production up -d
    print_success "Services started"
    
    # Wait for services to be ready
    print_header "Waiting for Services"
    sleep 30
    
    # Check if services are running
    if ! docker compose -f docker-compose.prod.yml ps | grep -q "Up"; then
        print_error "Some services failed to start"
        docker compose -f docker-compose.prod.yml logs
        exit 1
    fi
    print_success "All services are running"
}

setup_site() {
    print_header "Setting up ERPNext Site"
    
    cd "$PROJECT_DIR"
    source .env.production
    
    # Check if site already exists
    if docker compose -f docker-compose.prod.yml exec -T backend bench list-sites | grep -q "$SITE_NAME"; then
        print_warning "Site $SITE_NAME already exists, skipping creation"
        return
    fi
    
    # Create new site
    log "Creating site: $SITE_NAME"
    docker compose -f docker-compose.prod.yml exec -T backend bench new-site "$SITE_NAME" \
        --no-mariadb-socket \
        --admin-password="$ADMIN_PASSWORD" \
        --db-root-password="$DB_ROOT_PASSWORD" \
        --install-app erpnext \
        --set-default
    
    print_success "Site $SITE_NAME created"
    
    # Install additional apps
    apps=("hrms" "crm" "lending" "utility_billing")
    for app in "${apps[@]}"; do
        log "Installing app: $app"
        docker compose -f docker-compose.prod.yml exec -T backend bench --site "$SITE_NAME" install-app "$app" || true
    done
    
    print_success "Apps installation completed"
}

setup_ssl() {
    print_header "Setting up SSL Certificate"
    
    source "$PROJECT_DIR/.env.production"
    
    if [ -z "$DOMAIN" ]; then
        print_warning "DOMAIN not set, skipping SSL setup"
        return
    fi
    
    # Install certbot if not installed
    if ! command -v certbot &> /dev/null; then
        log "Installing certbot"
        sudo apt update
        sudo apt install -y certbot python3-certbot-nginx
    fi
    
    # Get SSL certificate
    log "Obtaining SSL certificate for $DOMAIN"
    sudo certbot certonly --standalone --agree-tos --no-eff-email --email "admin@$DOMAIN" -d "$DOMAIN" || true
    
    # Setup auto-renewal
    (crontab -l 2>/dev/null; echo "0 12 * * * /usr/bin/certbot renew --quiet") | crontab -
    
    print_success "SSL setup completed"
}

setup_backup() {
    print_header "Setting up Backup System"
    
    # Create backup script
    cat > /tmp/erpnext-backup.sh << 'EOF'
#!/bin/bash
cd /opt/erpnext
DATE=$(date +%Y%m%d_%H%M%S)
BACKUP_DIR="/opt/erpnext-backups/$DATE"
mkdir -p "$BACKUP_DIR"

# Create backup
docker compose -f docker-compose.prod.yml exec -T backend bench --site frontend backup --with-files

# Copy backup files
docker compose -f docker-compose.prod.yml exec -T backend find /home/frappe/frappe-bench/sites/frontend/private/backups/ -type f -exec cp {} "$BACKUP_DIR/" \;

# Compress backup
cd /opt/erpnext-backups
tar -czf "$DATE.tar.gz" "$DATE"
rm -rf "$DATE"

# Keep only last 30 backups
find /opt/erpnext-backups -name "*.tar.gz" -type f -mtime +30 -delete

echo "Backup completed: $DATE.tar.gz"
EOF
    
    sudo mv /tmp/erpnext-backup.sh /usr/local/bin/erpnext-backup.sh
    sudo chmod +x /usr/local/bin/erpnext-backup.sh
    
    # Setup daily backup cron
    (crontab -l 2>/dev/null; echo "0 2 * * * /usr/local/bin/erpnext-backup.sh") | crontab -
    
    print_success "Backup system configured"
}

setup_monitoring() {
    print_header "Setting up Monitoring"
    
    # Create monitoring script
    cat > /tmp/erpnext-monitor.sh << 'EOF'
#!/bin/bash
cd /opt/erpnext

# Check services
if ! docker compose -f docker-compose.prod.yml ps | grep -q "Up"; then
    echo "WARNING: Some ERPNext services are down"
    docker compose -f docker-compose.prod.yml ps
fi

# Check disk space
used_space=$(df / | awk 'NR==2 {printf "%.0f", $5}' | sed 's/%//')
if [ "$used_space" -gt 90 ]; then
    echo "WARNING: Disk space usage is high: $used_space%"
fi

# Check memory usage
mem_usage=$(free | grep Mem | awk '{printf "%.0f", $3/$2 * 100.0}')
if [ "$mem_usage" -gt 90 ]; then
    echo "WARNING: Memory usage is high: $mem_usage%"
fi
EOF
    
    sudo mv /tmp/erpnext-monitor.sh /usr/local/bin/erpnext-monitor.sh
    sudo chmod +x /usr/local/bin/erpnext-monitor.sh
    
    # Setup monitoring cron (every 5 minutes)
    (crontab -l 2>/dev/null; echo "*/5 * * * * /usr/local/bin/erpnext-monitor.sh") | crontab -
    
    print_success "Monitoring configured"
}

print_final_info() {
    print_header "🎉 Deployment Complete!"
    
    source "$PROJECT_DIR/.env.production"
    
    echo -e "${GREEN}ERPNext has been successfully deployed!${NC}\n"
    
    echo -e "${BLUE}Access Information:${NC}"
    echo -e "🌐 URL: https://$SITE_NAME"
    echo -e "👤 Username: Administrator"
    echo -e "🔑 Password: $ADMIN_PASSWORD"
    echo ""
    
    echo -e "${BLUE}Management Commands:${NC}"
    echo -e "📊 Check status: docker compose -f docker-compose.prod.yml ps"
    echo -e "📋 View logs: docker compose -f docker-compose.prod.yml logs -f [service]"
    echo -e "🔄 Restart: docker compose -f docker-compose.prod.yml restart"
    echo -e "💾 Backup: /usr/local/bin/erpnext-backup.sh"
    echo -e "🔍 Monitor: /usr/local/bin/erpnext-monitor.sh"
    echo ""
    
    echo -e "${YELLOW}Important:${NC}"
    echo -e "• Change default passwords"
    echo -e "• Setup firewall rules"
    echo -e "• Configure monitoring alerts"
    echo -e "• Test backup and restore procedures"
}

# Main deployment flow
main() {
    print_header "🚀 ERPNext Production Deployment"
    
    check_requirements
    create_directories
    setup_environment
    deploy_services
    setup_site
    setup_ssl
    setup_backup
    setup_monitoring
    print_final_info
    
    log "Deployment completed successfully"
}

# Handle script arguments
case "${1:-deploy}" in
    deploy)
        main
        ;;
    backup)
        /usr/local/bin/erpnext-backup.sh
        ;;
    monitor)
        /usr/local/bin/erpnext-monitor.sh
        ;;
    *)
        echo "Usage: $0 {deploy|backup|monitor}"
        exit 1
        ;;
esac
