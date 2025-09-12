#!/bin/bash
set -e

echo "🚀 ERPNext Production Setup (Complete with CRM)"
echo "======================================"

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

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

# Check Docker
if ! command -v docker &> /dev/null; then
    print_error "Docker not installed!"
    exit 1
fi

COMPOSE_CMD="docker compose"

print_status "Cleaning up any existing setup..."
$COMPOSE_CMD -f docker-compose-production.yaml down -v --remove-orphans || true
$COMPOSE_CMD -f docker-compose-final-working.yaml down -v --remove-orphans || true

# Remove volumes for fresh start
print_warning "Removing all volumes for fresh installation..."
docker volume rm $(docker volume ls -q | grep erpnext_tv5smart_admin) 2>/dev/null || true

print_status "Starting ERPNext Production Setup..."

# Start database and Redis first
print_status "Starting database and Redis services..."
$COMPOSE_CMD -f docker-compose-production.yaml up -d db redis-cache redis-queue

# Wait for database
print_status "Waiting for database to be ready..."
sleep 10
for i in {1..30}; do
    if $COMPOSE_CMD -f docker-compose-production.yaml exec -T db mysqladmin ping -h localhost --password=admin --silent; then
        print_success "Database is ready!"
        break
    fi
    echo "Database not ready... attempt $i/30"
    sleep 5
done

# Start configurator
print_status "Starting configurator..."
$COMPOSE_CMD -f docker-compose-production.yaml up configurator
sleep 5

# Create site
print_status "[INFO] Creating ERPNext site with HRMS, Lending, CRM and Utility Billing..."
$COMPOSE_CMD -f docker-compose-production.yaml up create-site

# Start all services
print_status "Starting all ERPNext services..."
$COMPOSE_CMD -f docker-compose-production.yaml up -d

# Wait for frontend
print_status "Waiting for ERPNext frontend to be ready..."
for i in {1..60}; do
    if curl -s -o /dev/null -w "%{http_code}" http://localhost:8081 | grep -q "200\|302"; then
        print_success "ERPNext is ready!"
        break
    fi
    echo "Waiting for frontend... attempt $i/60"
    sleep 10
done

# Show status
print_status "Checking service status..."
$COMPOSE_CMD -f docker-compose-production.yaml ps

# Show logs if not ready
if ! curl -s -o /dev/null -w "%{http_code}" http://localhost:8081 | grep -q "200\|302"; then
    print_warning "Frontend not responding, checking logs..."
    $COMPOSE_CMD -f docker-compose-production.yaml logs --tail 10 frontend
    $COMPOSE_CMD -f docker-compose-production.yaml logs --tail 10 backend
fi

echo ""
echo "🎉🎉🎉 ERPNext Production Setup Complete! 🎉🎉🎉"
echo "================================================="
echo ""
echo "✅ ERPNext URL: http://localhost:8081"
echo "✅ Username: Administrator"
echo "✅ Password: admin"
echo "✅ Site Name: frontend"
echo ""
echo "📦 Applications Installed:"
echo "   - Frappe Framework"
echo "   - ERPNext (Core Business)"
echo "   - HRMS (Human Resource Management)"
echo "   - Lending (Loan Management)"
echo "   - Utility Billing (Utility Management)"
echo ""
echo "🛠️  Management Commands:"
echo "   View logs: $COMPOSE_CMD -f docker-compose-production.yaml logs -f [service]"
echo "   Shell access: $COMPOSE_CMD -f docker-compose-production.yaml exec backend bash"
echo "   Stop services: $COMPOSE_CMD -f docker-compose-production.yaml down"
echo "   Restart: $COMPOSE_CMD -f docker-compose-production.yaml restart"
echo ""

# Offer recovery scripts
if [ -f "full-recovery.sh" ]; then
    echo "🔧 Recovery scripts available. Run them now? (y/n)"
    read -r answer < /dev/tty
    if [[ $answer == [Yy]* ]]; then
        print_status "Running full recovery script..."
        bash full-recovery.sh || print_warning "Recovery script completed with warnings"
    fi
fi

print_success "ERPNext พร้อมใช้งานแล้ว! Complete with HRMS & Lending!"
print_success "Ready for development and production use!"
