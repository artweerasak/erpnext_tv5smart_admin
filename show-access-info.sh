#!/bin/bash
# Show ERPNext Access Information for Remote Access

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${BLUE}🌐 ERPNext Remote Access Information${NC}"
echo "====================================="
echo ""

# Get server IP addresses
echo -e "${YELLOW}📍 Server IP Addresses:${NC}"
echo "Internal IPs:"

# Get local network IPs
hostname -I | tr ' ' '\n' | grep -E '^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$' | while read ip; do
    echo "  🔸 $ip"
done

echo ""
echo "External IP (if available):"
# Try to get external IP
EXTERNAL_IP=$(curl -s -m 5 ifconfig.me 2>/dev/null || curl -s -m 5 ipinfo.io/ip 2>/dev/null || echo "Unable to determine")
echo "  🔸 $EXTERNAL_IP"

echo ""
echo -e "${GREEN}🚀 Access URLs:${NC}"
echo ""

# Show access URLs for each IP
hostname -I | tr ' ' '\n' | grep -E '^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$' | while read ip; do
    echo "Via $ip:"
    echo "  🌐 ERPNext Frontend: http://$ip:8080"
    echo "  🔧 Backend API:     http://$ip:8000"
    echo "  📡 WebSocket:       http://$ip:9000"
    echo ""
done

if [ "$EXTERNAL_IP" != "Unable to determine" ] && [ "$EXTERNAL_IP" != "" ]; then
    echo "Via External IP $EXTERNAL_IP (if ports are forwarded):"
    echo "  🌐 ERPNext Frontend: http://$EXTERNAL_IP:8080"
    echo "  🔧 Backend API:     http://$EXTERNAL_IP:8000"
    echo "  📡 WebSocket:       http://$EXTERNAL_IP:9000"
    echo ""
fi

echo -e "${YELLOW}🔑 Login Credentials:${NC}"
echo "  Username: Administrator"
echo "  Password: admin"
echo "  Site:     frontend"
echo ""

echo -e "${YELLOW}📦 Applications Available:${NC}"
echo "  ✅ ERPNext (Core ERP)"
echo "  ✅ HRMS (Human Resources)"
echo "  ✅ Lending (Loan Management)"
echo ""

echo -e "${BLUE}🔧 Docker Services Status:${NC}"
if docker compose -f docker-compose-hrms.yaml ps > /dev/null 2>&1; then
    docker compose -f docker-compose-hrms.yaml ps --format "table {{.Name}}\t{{.Status}}\t{{.Ports}}"
else
    echo "  ⚠️  Services not running. Start with: ./start-dev.sh"
fi

echo ""
echo -e "${YELLOW}⚠️  Notes:${NC}"
echo "  • Make sure Docker containers are running"
echo "  • Ensure firewall allows ports 8000, 8080, 9000"
echo "  • For external access, configure port forwarding on router/firewall"
echo "  • Use internal IPs for access within the same network"
echo ""

# Check if ports are accessible
echo -e "${BLUE}🔍 Port Accessibility Check:${NC}"
for port in 8080 8000 9000; do
    if netstat -ln 2>/dev/null | grep -q ":$port "; then
        echo "  ✅ Port $port is listening"
    else
        echo "  ❌ Port $port is not listening"
    fi
done
