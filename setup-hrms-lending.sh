#!/bin/bash
# ERPNext HRMS & Lending Setup Script
# This script helps set up and configure HRMS and Lending applications for ERPNext

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to check if service is running
check_service() {
    local service=$1
    if docker compose -f docker-compose-hrms.yaml ps --services --filter "status=running" | grep -q "^${service}$"; then
        return 0
    else
        return 1
    fi
}

# Function to wait for service to be ready
wait_for_service() {
    local service=$1
    local timeout=${2:-120}
    local count=0
    
    print_status "Waiting for $service to be ready..."
    while ! check_service $service && [ $count -lt $timeout ]; do
        sleep 2
        count=$((count + 2))
        echo -n "."
    done
    echo ""
    
    if check_service $service; then
        print_success "$service is ready!"
        return 0
    else
        print_error "$service failed to start within $timeout seconds"
        return 1
    fi
}

# Main setup function
setup_environment() {
    print_status "🚀 Starting ERPNext HRMS & Lending Setup..."
    
    # Check if Docker is running
    if ! docker info > /dev/null 2>&1; then
        print_error "Docker is not running. Please start Docker first."
        exit 1
    fi
    
    # Check if docker-compose file exists
    if [ ! -f "docker-compose-hrms.yaml" ]; then
        print_error "docker-compose-hrms.yaml not found in current directory"
        exit 1
    fi
    
    print_status "📥 Pulling latest images..."
    docker compose -f docker-compose-hrms.yaml pull
    
    print_status "🏗️  Starting services..."
    docker compose -f docker-compose-hrms.yaml up -d
    
    # Wait for core services
    wait_for_service "db" 60
    wait_for_service "redis-cache" 30
    wait_for_service "redis-queue" 30
    
    print_status "⚙️  Running configurator..."
    docker compose -f docker-compose-hrms.yaml up configurator
    
    print_status "🏗️  Creating site with HRMS and Lending..."
    docker compose -f docker-compose-hrms.yaml up create-site
    
    # Wait for remaining services
    wait_for_service "backend" 60
    wait_for_service "frontend" 60
    
    print_success "✅ Environment setup completed!"
}

# Function to install additional apps
install_app() {
    local app_name=$1
    local site=${2:-"frontend"}
    
    print_status "📦 Installing $app_name on site $site..."
    
    if docker compose -f docker-compose-hrms.yaml exec backend bench --site $site install-app $app_name; then
        print_success "$app_name installed successfully!"
    else
        print_error "Failed to install $app_name"
        return 1
    fi
}

# Function to check installed apps
check_apps() {
    local site=${1:-"frontend"}
    
    print_status "📋 Checking installed apps on site $site..."
    
    if ! check_service "backend"; then
        print_error "Backend service is not running. Start the environment first."
        return 1
    fi
    
    echo ""
    docker compose -f docker-compose-hrms.yaml exec backend bench --site $site list-apps
    echo ""
}

# Function to setup sample data
setup_sample_data() {
    local site=${1:-"frontend"}
    
    print_status "📊 Setting up sample data..."
    
    print_status "Creating sample HRMS data..."
    docker compose -f docker-compose-hrms.yaml exec backend bench --site $site execute "frappe.utils.install.make_sample_doc" --args "['Employee', 10]" || print_warning "Failed to create sample employee data"
    
    print_status "Creating sample Lending data..."
    docker compose -f docker-compose-hrms.yaml exec backend bench --site $site execute "frappe.utils.install.make_sample_doc" --args "['Loan Type', 3]" || print_warning "Failed to create sample loan types"
    
    print_success "Sample data setup completed (where possible)"
}

# Function to show system status
show_status() {
    echo ""
    echo "📊 System Status"
    echo "==============="
    docker compose -f docker-compose-hrms.yaml ps --format "table {{.Name}}\t{{.Status}}\t{{.Ports}}"
    
    echo ""
    echo "🌐 Access URLs:"
    echo "  Frontend: http://localhost:8080"
    echo "  Backend:  http://localhost:8000"
    echo ""
    echo "🔑 Default Credentials:"
    echo "  Username: Administrator"
    echo "  Password: admin"
    echo ""
}

# Function to backup site
backup_site() {
    local site=${1:-"frontend"}
    local backup_dir="./backups"
    
    print_status "💾 Creating backup for site $site..."
    
    mkdir -p $backup_dir
    
    local timestamp=$(date +"%Y%m%d_%H%M%S")
    local backup_name="${site}_backup_${timestamp}"
    
    if docker compose -f docker-compose-hrms.yaml exec backend bench --site $site backup --backup-path /home/frappe/frappe-bench/sites/$site/backups/; then
        print_success "Backup created successfully!"
        print_status "Backup location: sites/$site/backups/"
    else
        print_error "Failed to create backup"
        return 1
    fi
}

# Function to restore site
restore_site() {
    local backup_file=$1
    local site=${2:-"frontend"}
    
    if [ -z "$backup_file" ]; then
        print_error "Please provide backup file path"
        echo "Usage: $0 restore <backup_file> [site_name]"
        return 1
    fi
    
    print_status "🔄 Restoring site $site from $backup_file..."
    
    if docker compose -f docker-compose-hrms.yaml exec backend bench --site $site restore $backup_file; then
        print_success "Site restored successfully!"
    else
        print_error "Failed to restore site"
        return 1
    fi
}

# Function to show help
show_help() {
    echo "ERPNext HRMS & Lending Setup Script"
    echo "===================================="
    echo ""
    echo "Usage: $0 <command> [options]"
    echo ""
    echo "Commands:"
    echo "  setup                    - Full environment setup with HRMS & Lending"
    echo "  status                   - Show system status"
    echo "  apps [site]              - List installed apps"
    echo "  install <app> [site]     - Install additional app"
    echo "  sample-data [site]       - Setup sample data for HRMS & Lending"
    echo "  backup [site]            - Create site backup"
    echo "  restore <file> [site]    - Restore site from backup"
    echo "  help                     - Show this help"
    echo ""
    echo "Examples:"
    echo "  $0 setup                 - Setup complete environment"
    echo "  $0 apps                  - List apps on default site (frontend)"
    echo "  $0 install custom_app    - Install custom_app on default site"
    echo "  $0 sample-data           - Create sample data"
    echo "  $0 backup                - Backup default site"
    echo ""
    echo "Default site: frontend"
    echo ""
}

# Main script logic
case "${1:-setup}" in
    setup)
        setup_environment
        show_status
        ;;
    status)
        show_status
        ;;
    apps)
        check_apps "$2"
        ;;
    install)
        if [ -z "$2" ]; then
            print_error "Please provide app name"
            echo "Usage: $0 install <app_name> [site_name]"
            exit 1
        fi
        install_app "$2" "$3"
        ;;
    sample-data)
        setup_sample_data "$2"
        ;;
    backup)
        backup_site "$2"
        ;;
    restore)
        restore_site "$2" "$3"
        ;;
    help|--help|-h)
        show_help
        ;;
    *)
        print_error "Unknown command: $1"
        echo ""
        show_help
        exit 1
        ;;
esac
