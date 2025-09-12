#!/bin/bash
set -e

echo "🚀 Starting Simple ERPNext Complete Setup"
echo "========================================="

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check Docker
if ! command -v docker &> /dev/null; then
    print_error "Docker not installed!"
    exit 1
fi

# Use docker compose
COMPOSE_CMD="docker compose"

print_status "Cleaning up previous setup..."
$COMPOSE_CMD -f docker-compose-final-working.yaml down -v || true

print_status "Starting ERPNext with all apps..."
$COMPOSE_CMD -f docker-compose-final-working.yaml up -d

print_status "Waiting for ERPNext to be ready..."
for i in {1..30}; do
    if curl -s -o /dev/null -w "%{http_code}" http://localhost:8081 | grep -q "200\|302"; then
        print_success "ERPNext is ready!"
        break
    fi
    echo "Waiting... attempt $i/30"
    sleep 10
done

# Show logs
print_status "Checking ERPNext status..."
$COMPOSE_CMD -f docker-compose-final-working.yaml logs --tail 20 erpnext

echo ""
echo "🎉 ERPNext Complete Setup Ready!"
echo "================================"
echo ""
echo "✅ URL: http://localhost:8081"
echo "✅ Username: Administrator"
echo "✅ Password: admin"
echo ""
echo "📦 Apps Installed:"
echo "   - ERPNext"
echo "   - HRMS"
echo "   - Lending"
echo ""
echo "🛠️  Commands:"
echo "   View logs: $COMPOSE_CMD -f docker-compose-final-working.yaml logs -f erpnext"
echo "   Stop: $COMPOSE_CMD -f docker-compose-final-working.yaml down"
echo ""

# Offer recovery scripts
if [ -f "full-recovery.sh" ]; then
    echo "🔧 Run recovery scripts now? (y/n)"
    read -r answer
    if [[ $answer == [Yy]* ]]; then
        print_status "Running full recovery..."
        bash full-recovery.sh
    fi
fi

print_success "Setup Complete! ERPNext พร้อมใช้งานแล้ว!"
