#!/bin/bash
# ERPNext Health Check Script

echo "🔍 ERPNext Development Environment Health Check"
echo "=============================================="

# Check Docker
echo "🐳 Docker Status:"
if docker info > /dev/null 2>&1; then
    echo "   ✅ Docker is running"
else
    echo "   ❌ Docker is not running"
    exit 1
fi

# Check Docker Compose services
echo ""
echo "🏗️  Service Status:"
docker compose -f docker-compose-hrms.yaml ps --format "table {{.Name}}\t{{.Status}}\t{{.Ports}}"

# Check if ERPNext is accessible
echo ""
echo "🌐 Application Health:"

# Check if ports are accessible
if curl -s http://localhost:8080 > /dev/null 2>&1; then
    echo "   ✅ Frontend (ERPNext UI): http://localhost:8080 - Accessible"
else
    echo "   ⚠️  Frontend (ERPNext UI): http://localhost:8080 - Not accessible yet"
fi

if curl -s http://localhost:8000 > /dev/null 2>&1; then
    echo "   ✅ Backend API: http://localhost:8000 - Accessible"
else
    echo "   ⚠️  Backend API: http://localhost:8000 - Not accessible yet"
fi

# Check database connection
echo ""
echo "💾 Database Status:"
if docker compose -f docker-compose-hrms.yaml exec -T db mysqladmin ping -h localhost -u root -padmin 2>/dev/null; then
    echo "   ✅ MariaDB: Connection successful"
else
    echo "   ⚠️  MariaDB: Connection failed or starting"
fi

# Check installed apps
echo ""
echo "📦 Installed Applications:"
APPS_CHECK=$(docker compose -f docker-compose-hrms.yaml exec -T backend bench --site frontend list-apps 2>/dev/null || echo "Apps check failed")

if [[ "$APPS_CHECK" == *"erpnext"* ]]; then
    echo "   ✅ ERPNext: Installed"
else
    echo "   ⚠️  ERPNext: Not detected"
fi

if [[ "$APPS_CHECK" == *"hrms"* ]]; then
    echo "   ✅ HRMS: Installed"
else
    echo "   ⚠️  HRMS: Not detected"
fi

if [[ "$APPS_CHECK" == *"lending"* ]]; then
    echo "   ✅ Lending: Installed"
else
    echo "   ⚠️  Lending: Not detected"
fi

echo ""
echo "🏁 Health Check Complete!"
echo ""

if curl -s http://localhost:8080 > /dev/null 2>&1; then
    echo "✅ Your ERPNext development environment is ready!"
    echo "🌐 Access: http://localhost:8080"
    echo "🔑 Login: Administrator / admin"
else
    echo "⚠️  Environment is starting up. Please wait a few minutes and run this script again."
    echo "📝 View logs: docker compose -f docker-compose-hrms.yaml logs -f"
fi
