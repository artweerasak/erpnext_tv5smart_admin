#!/bin/bash
set -e

echo "🚀 Starting Complete ERPNext Development Setup"
echo "=============================================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

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

# Check if docker and docker-compose are available
if ! command -v docker &> /dev/null; then
    print_error "Docker is not installed!"
    exit 1
fi

if ! command -v docker-compose &> /dev/null && ! docker compose version &> /dev/null; then
    print_error "Docker Compose is not installed!"
    exit 1
fi

# Check if we can use docker compose or docker-compose
if docker compose version &> /dev/null; then
    COMPOSE_CMD="docker compose"
else
    COMPOSE_CMD="docker-compose"
fi

print_status "Using: $COMPOSE_CMD"

# Cleanup previous setup if exists
print_status "Cleaning up any existing containers and volumes..."
$COMPOSE_CMD -f docker-compose-development.yaml down -v || true

# Remove any existing volumes to start fresh
print_warning "Removing existing Docker volumes for fresh start..."
docker volume rm erpnext_tv5smart_admin_db-data 2>/dev/null || true
docker volume rm erpnext_tv5smart_admin_redis-cache-data 2>/dev/null || true
docker volume rm erpnext_tv5smart_admin_redis-queue-data 2>/dev/null || true
docker volume rm erpnext_tv5smart_admin_sites 2>/dev/null || true
docker volume rm erpnext_tv5smart_admin_logs 2>/dev/null || true

# Pull latest images
print_status "Pulling latest images..."
$COMPOSE_CMD -f docker-compose-development.yaml pull

# Start the database and redis first
print_status "Starting database and Redis services..."
$COMPOSE_CMD -f docker-compose-development.yaml up -d db redis-cache redis-queue

# Wait for database to be ready
print_status "Waiting for database to be ready..."
max_attempts=30
attempt=1
while [ $attempt -le $max_attempts ]; do
    # Try direct connection test instead of docker exec
    if $COMPOSE_CMD -f docker-compose-development.yaml exec -T db mysqladmin ping -h localhost -u root -padmin123 --silent 2>/dev/null; then
        print_success "Database is ready!"
        break
    fi
    print_status "Database not ready yet... attempt $attempt/$max_attempts"
    sleep 10
    ((attempt++))
done

if [ $attempt -gt $max_attempts ]; then
    print_error "Database failed to start after $max_attempts attempts"
    $COMPOSE_CMD -f docker-compose-development.yaml logs db
    exit 1
fi

# Start the configurator and site creation
print_status "Running site configuration and setup..."
$COMPOSE_CMD -f docker-compose-development.yaml up configurator create-site

# Check if setup completed successfully
print_status "Checking setup completion status..."
if docker run --rm -v erpnext_tv5smart_admin_sites:/sites alpine test -f /sites/setup_status.txt; then
    print_success "Setup completed successfully!"
    docker run --rm -v erpnext_tv5smart_admin_sites:/sites alpine cat /sites/setup_status.txt
else
    print_error "Setup may have failed. Checking logs..."
    $COMPOSE_CMD -f docker-compose-development.yaml logs create-site
    exit 1
fi

# Start all remaining services
print_status "Starting all ERPNext services..."
$COMPOSE_CMD -f docker-compose-development.yaml up -d

# Wait for backend to be healthy
print_status "Waiting for backend service to be healthy..."
max_attempts=20
attempt=1
while [ $attempt -le $max_attempts ]; do
    if $COMPOSE_CMD -f docker-compose-development.yaml ps backend | grep -q "healthy"; then
        print_success "Backend service is healthy!"
        break
    fi
    print_status "Backend not healthy yet... attempt $attempt/$max_attempts"
    sleep 15
    ((attempt++))
done

# Show final status
print_status "Checking all services status..."
$COMPOSE_CMD -f docker-compose-development.yaml ps

# Test the frontend
print_status "Testing ERPNext frontend..."
max_attempts=10
attempt=1
while [ $attempt -le $max_attempts ]; do
    if curl -s -o /dev/null -w "%{http_code}" http://localhost:8080 | grep -q "200\|302"; then
        print_success "ERPNext is accessible at http://localhost:8080"
        break
    fi
    print_status "Frontend not ready yet... attempt $attempt/$max_attempts"
    sleep 10
    ((attempt++))
done

# Show installed apps
print_status "Showing installed apps..."
$COMPOSE_CMD -f docker-compose-development.yaml exec backend bench --site frontend list-apps 2>/dev/null || true

# Final success message
echo ""
echo "🎉🎉🎉 ERPNext Development Environment Ready! 🎉🎉🎉"
echo "======================================================="
echo ""
echo "✅ ERPNext URL: http://localhost:8080"
echo "✅ Username: Administrator"
echo "✅ Password: admin"
echo "✅ Site: frontend"
echo ""
echo "📦 Installed Applications:"
echo "   - Frappe Framework"
echo "   - ERPNext"
echo "   - HRMS"
echo "   - Lending"
echo "   - Utility Billing (if available)"
echo ""
echo "🛠️  Development Commands:"
echo "   $COMPOSE_CMD -f docker-compose-development.yaml logs -f [service]"
echo "   $COMPOSE_CMD -f docker-compose-development.yaml exec backend bash"
echo "   $COMPOSE_CMD -f docker-compose-development.yaml exec backend bench --site frontend [command]"
echo ""
echo "🔄 To restart all services:"
echo "   $COMPOSE_CMD -f docker-compose-development.yaml restart"
echo ""
echo "🛑 To stop all services:"
echo "   $COMPOSE_CMD -f docker-compose-development.yaml down"
echo ""

# Offer to run recovery scripts
if [ -f "full-recovery.sh" ]; then
    echo "🔧 Found recovery scripts. Would you like to run them now? (y/n)"
    read -r answer
    if [[ $answer == [Yy]* ]]; then
        print_status "Running full recovery script..."
        bash full-recovery.sh
    fi
fi

print_success "Setup completed successfully! ERPNext development environment is ready!"
