#!/bin/bash

# 📦 ERPNext Data Migration Script
# This script helps migrate data from development to production

set -e

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKUP_DIR="$SCRIPT_DIR/migration_backup"
DATE=$(date +%Y%m%d_%H%M%S)

print_header() {
    echo -e "\n${GREEN}================================${NC}"
    echo -e "${GREEN} $1${NC}"
    echo -e "${GREEN}================================${NC}\n"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

create_backup() {
    print_header "Creating Development Backup"
    
    # Create backup directory
    mkdir -p "$BACKUP_DIR/$DATE"
    
    # Check if development environment is running
    if ! docker compose ps | grep -q "Up"; then
        print_error "Development environment is not running"
        echo "Please start it with: docker compose up -d"
        exit 1
    fi
    
    # Create database backup
    echo "Creating database backup..."
    docker compose exec backend bench --site frontend backup --with-files
    
    # Copy backup files
    echo "Copying backup files..."
    docker compose exec backend bash -c "
        cd /home/frappe/frappe-bench/sites/frontend/private/backups
        tar -czf /tmp/erpnext_backup_$DATE.tar.gz *.sql.gz *.tar
        cp /tmp/erpnext_backup_$DATE.tar.gz /home/frappe/
    "
    
    # Extract to host
    docker compose cp backend:/home/frappe/erpnext_backup_$DATE.tar.gz "$BACKUP_DIR/$DATE/"
    
    # Get apps information
    docker compose exec backend bench --site frontend list-apps > "$BACKUP_DIR/$DATE/apps_list.txt"
    
    # Export site configuration
    docker compose exec backend bench --site frontend export-fixtures > "$BACKUP_DIR/$DATE/fixtures_export.log" 2>&1 || true
    
    echo -e "${GREEN}✅ Backup created at: $BACKUP_DIR/$DATE${NC}"
}

generate_production_config() {
    print_header "Generating Production Configuration"
    
    # Copy environment template
    if [ ! -f "$SCRIPT_DIR/.env.production" ]; then
        cp "$SCRIPT_DIR/.env.production.template" "$SCRIPT_DIR/.env.production"
        echo -e "${YELLOW}⚠️  Please edit .env.production with your production settings${NC}"
        
        # Basic validation prompts
        read -p "Enter your domain name: " domain
        read -p "Enter database root password: " -s db_password
        echo
        read -p "Enter admin password: " -s admin_password
        echo
        
        # Update configuration file
        sed -i "s/your-domain.com/$domain/g" "$SCRIPT_DIR/.env.production"
        sed -i "s/CHANGE_THIS_STRONG_PASSWORD_123!/$db_password/g" "$SCRIPT_DIR/.env.production"
        sed -i "s/CHANGE_THIS_ADMIN_PASSWORD_789!/$admin_password/g" "$SCRIPT_DIR/.env.production"
        
        echo -e "${GREEN}✅ Production configuration created${NC}"
    else
        echo -e "${YELLOW}Production configuration already exists${NC}"
    fi
}

validate_production_env() {
    print_header "Validating Production Environment"
    
    if [ ! -f "$SCRIPT_DIR/.env.production" ]; then
        print_error "Production environment file not found"
        exit 1
    fi
    
    source "$SCRIPT_DIR/.env.production"
    
    # Check required variables
    required_vars=("SITE_NAME" "DB_ROOT_PASSWORD" "ADMIN_PASSWORD")
    for var in "${required_vars[@]}"; do
        if [ -z "${!var}" ]; then
            print_error "Required variable $var is not set in .env.production"
            exit 1
        fi
    done
    
    # Check if still using template values
    if [[ "$DB_ROOT_PASSWORD" == *"CHANGE_THIS"* ]] || [[ "$ADMIN_PASSWORD" == *"CHANGE_THIS"* ]]; then
        print_error "Please update default passwords in .env.production"
        exit 1
    fi
    
    echo -e "${GREEN}✅ Production environment validated${NC}"
}

create_migration_package() {
    print_header "Creating Migration Package"
    
    # Create migration package
    PACKAGE_DIR="$BACKUP_DIR/migration_package_$DATE"
    mkdir -p "$PACKAGE_DIR"
    
    # Copy necessary files
    cp -r "$BACKUP_DIR/$DATE"/* "$PACKAGE_DIR/"
    cp "$SCRIPT_DIR/.env.production" "$PACKAGE_DIR/"
    cp "$SCRIPT_DIR/docker-compose.prod.yml" "$PACKAGE_DIR/"
    cp "$SCRIPT_DIR/deploy.sh" "$PACKAGE_DIR/"
    cp -r "$SCRIPT_DIR/config" "$PACKAGE_DIR/"
    
    # Create migration instructions
    cat > "$PACKAGE_DIR/MIGRATION_INSTRUCTIONS.md" << 'EOF'
# ERPNext Production Migration Instructions

## Prerequisites
- Ubuntu 20.04/22.04 LTS server
- Docker and Docker Compose installed
- Domain name configured
- SSL certificate (optional, can be auto-generated)

## Migration Steps

1. **Upload this package to your production server**
   ```bash
   scp -r migration_package_* user@your-server:/opt/erpnext/
   cd /opt/erpnext/migration_package_*
   ```

2. **Review and update configuration**
   ```bash
   nano .env.production
   ```

3. **Run deployment**
   ```bash
   chmod +x deploy.sh
   sudo ./deploy.sh
   ```

4. **Restore data**
   ```bash
   # Extract backup
   cd /opt/erpnext
   tar -xzf migration_package_*/erpnext_backup_*.tar.gz
   
   # Restore to production site
   docker compose -f docker-compose.prod.yml exec backend bench --site YOUR_DOMAIN restore /path/to/backup.sql.gz --with-private-files /path/to/files.tar
   ```

5. **Verify installation**
   - Access https://your-domain.com
   - Login with Administrator credentials
   - Check all apps are installed
   - Verify data integrity

## Post-Migration Checklist
- [ ] SSL certificate working
- [ ] Email configuration tested
- [ ] Backup system configured
- [ ] Monitoring set up
- [ ] User access verified
- [ ] Performance optimization applied
EOF
    
    # Create README
    cat > "$PACKAGE_DIR/README.txt" << EOF
ERPNext Migration Package
Generated: $DATE

Contents:
- erpnext_backup_$DATE.tar.gz    # Database and files backup
- apps_list.txt                  # List of installed apps  
- .env.production               # Production environment config
- docker-compose.prod.yml       # Production Docker Compose
- deploy.sh                     # Deployment script
- config/                       # Nginx and MariaDB configs
- MIGRATION_INSTRUCTIONS.md     # Detailed instructions

Quick Start:
1. Review .env.production
2. Run: chmod +x deploy.sh && sudo ./deploy.sh
3. Follow MIGRATION_INSTRUCTIONS.md
EOF
    
    # Create compressed package
    cd "$BACKUP_DIR"
    tar -czf "erpnext_migration_$DATE.tar.gz" "migration_package_$DATE"
    
    echo -e "${GREEN}✅ Migration package created: $BACKUP_DIR/erpnext_migration_$DATE.tar.gz${NC}"
}

show_summary() {
    print_header "Migration Summary"
    
    echo -e "${GREEN}Migration package ready!${NC}\n"
    
    echo "📦 Package Location:"
    echo "   $BACKUP_DIR/erpnext_migration_$DATE.tar.gz"
    echo ""
    
    echo "📋 Next Steps:"
    echo "1. Upload package to production server"
    echo "2. Extract: tar -xzf erpnext_migration_$DATE.tar.gz"
    echo "3. Review .env.production configuration"
    echo "4. Run deployment: sudo ./deploy.sh"
    echo "5. Follow MIGRATION_INSTRUCTIONS.md"
    echo ""
    
    echo -e "${YELLOW}Important Notes:${NC}"
    echo "• Backup your production database before restoration"
    echo "• Test migration on staging environment first"
    echo "• Update DNS records to point to new server"
    echo "• Configure monitoring and backup systems"
}

# Main function
main() {
    case "${1:-all}" in
        backup)
            create_backup
            ;;
        config)
            generate_production_config
            ;;
        validate)
            validate_production_env
            ;;
        package)
            create_migration_package
            ;;
        all)
            create_backup
            generate_production_config
            validate_production_env
            create_migration_package
            show_summary
            ;;
        *)
            echo "Usage: $0 {backup|config|validate|package|all}"
            echo ""
            echo "Commands:"
            echo "  backup   - Create development backup"
            echo "  config   - Generate production configuration"
            echo "  validate - Validate production environment"
            echo "  package  - Create migration package"
            echo "  all      - Run all steps (default)"
            exit 1
            ;;
    esac
}

# Run main function
main "$@"
