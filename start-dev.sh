#!/bin/bash
# ERPNext Development Environment Startup Script

echo "🚀 Starting ERPNext Development Environment with HRMS & Lending..."

# Check if Docker is running
if ! docker info > /dev/null 2>&1; then
    echo "❌ Docker is not running. Please start Docker first."
    exit 1
fi

# Pull latest images
echo "📥 Pulling latest ERPNext images..."
docker compose -f docker-compose-hrms.yaml pull

# Start the development environment
echo "🏗️  Building and starting development environment..."
docker compose -f docker-compose-hrms.yaml up -d

# Wait for services to be ready
echo "⏳ Waiting for services to start..."
sleep 10

# Check service status
echo "📊 Service Status:"
docker compose -f docker-compose-hrms.yaml ps

echo ""
echo "✅ Development environment is starting up!"
echo ""
echo "📋 Next Steps:"
echo "1. Wait for all services to be healthy (check with: docker compose -f docker-compose-hrms.yaml ps)"
echo "2. Access ERPNext at: http://localhost:8080"
echo "3. Login with:"
echo "   - Username: Administrator"
echo "   - Password: admin"
echo ""
echo "🔧 Available Apps:"
echo "   - ERPNext (Core ERP)"
echo "   - HRMS (Human Resource Management)"
echo "   - Lending (Loan Management)"
echo ""
echo "📝 Useful Commands:"
echo "   - View logs: docker compose -f docker-compose-hrms.yaml logs -f"
echo "   - Stop environment: docker compose -f docker-compose-hrms.yaml down"
echo "   - Restart services: docker compose -f docker-compose-hrms.yaml restart"
