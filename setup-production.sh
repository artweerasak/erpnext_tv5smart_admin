#!/bin/bash

# ERPNext v15 Production Quick Setup Script
# This script helps you quickly deploy ERPNext with custom apps to production

set -e  # Exit on any error

echo "🚀 ERPNext v15 Production Setup Script"
echo "======================================="

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
    echo "❌ Docker is not installed. Please install Docker first."
    echo "   Ubuntu/Debian: sudo apt update && sudo apt install docker.io docker-compose"
    echo "   CentOS/RHEL: sudo yum install docker docker-compose"
    exit 1
fi

# Check if Docker Compose is available
if ! command -v docker-compose &> /dev/null; then
    echo "❌ Docker Compose is not installed. Please install Docker Compose first."
    exit 1
fi

# Check if .env file exists
if [ ! -f .env ]; then
    echo "⚙️  Setting up environment file..."
    if [ -f .env.production ]; then
        cp .env.production .env
        echo "✅ Copied .env.production to .env"
        echo "📝 Please edit .env file with your production settings:"
        echo "   - SITE_NAME (your domain or IP)"
        echo "   - DB_PASSWORD (strong database password)" 
        echo "   - ADMIN_PASSWORD (ERPNext admin password)"
        echo "   - Email settings (MAIL_HOST, MAIL_USERNAME, etc.)"
        echo ""
        read -p "Do you want to edit .env now? (y/n): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            ${EDITOR:-nano} .env
        fi
    else
        echo "❌ .env.production file not found. Please create .env manually."
        exit 1
    fi
fi

echo ""
echo "🔧 Loading environment settings..."
source .env

# Validate required settings
if [ -z "$SITE_NAME" ] || [ "$SITE_NAME" = "your-domain.com" ]; then
    echo "❌ Please set SITE_NAME in .env file"
    exit 1
fi

if [ -z "$DB_PASSWORD" ] || [ "$DB_PASSWORD" = "your_very_strong_database_password_here" ]; then
    echo "❌ Please set a strong DB_PASSWORD in .env file"
    exit 1
fi

if [ -z "$ADMIN_PASSWORD" ] || [ "$ADMIN_PASSWORD" = "your_admin_password_here" ]; then
    echo "❌ Please set ADMIN_PASSWORD in .env file"
    exit 1
fi

echo "✅ Environment settings validated"
echo ""

# Choose deployment method
echo "📦 Choose deployment method:"
echo "1) Quick setup with pre-built image (recommended)"
echo "2) Build custom image locally"
echo ""
read -p "Enter choice (1-2): " -n 1 -r
echo

case $REPLY in
    1)
        echo "🚀 Starting with pre-built custom image..."
        COMPOSE_FILE="docker-compose-custom.yaml"
        ;;
    2)
        echo "🏗️  Building custom image locally..."
        echo "This may take 15-20 minutes..."
        
        # Build custom image
        docker build \
            --build-arg=APPS_JSON_BASE64="$(base64 -w 0 apps.json)" \
            --tag=tv5smart/erpnext-custom:v15 \
            --file=images/custom/Containerfile .
        
        COMPOSE_FILE="docker-compose-custom.yaml"
        ;;
    *)
        echo "❌ Invalid choice"
        exit 1
        ;;
esac

echo ""
echo "🗄️  Starting database and cache services..."
docker-compose -f $COMPOSE_FILE up -d db redis-cache redis-queue

echo "⏳ Waiting for services to initialize..."
sleep 30

echo "🌐 Starting all services..."
docker-compose -f $COMPOSE_FILE up -d

echo "⏳ Waiting for ERPNext to be ready..."
sleep 60

# Check if site was created successfully
echo "🔍 Checking site creation..."
if docker-compose -f $COMPOSE_FILE exec -T backend bench --site $SITE_NAME list-apps > /dev/null 2>&1; then
    echo "✅ Site created successfully!"
    echo ""
    echo "📱 Installed apps:"
    docker-compose -f $COMPOSE_FILE exec -T backend bench --site $SITE_NAME list-apps
else
    echo "⚠️  Site creation may still be in progress..."
    echo "📋 Check logs with: docker-compose -f $COMPOSE_FILE logs create-site"
fi

echo ""
echo "🎉 ERPNext deployment complete!"
echo "================================="
echo ""
echo "📍 Access your ERPNext at:"
if [ "$HTTP_PUBLISH_PORT" = "80" ]; then
    echo "   http://$SITE_NAME"
else
    echo "   http://$SITE_NAME:$HTTP_PUBLISH_PORT"
fi

if [ "${HTTPS_PUBLISH_PORT:-}" = "443" ]; then
    echo "   https://$SITE_NAME (if SSL is configured)"
elif [ -n "${HTTPS_PUBLISH_PORT:-}" ]; then
    echo "   https://$SITE_NAME:$HTTPS_PUBLISH_PORT (if SSL is configured)"
fi

echo ""
echo "👤 Login credentials:"
echo "   Username: Administrator"
echo "   Password: $ADMIN_PASSWORD"
echo ""

echo "📚 Installed Applications:"
echo "   • ERPNext v15.78.1 - Core ERP"
echo "   • HRMS v15.49.2 - Human Resources"  
echo "   • CRM v1.52.11 - Customer Relations"
echo "   • Lending v0.0.1 - Loan Management"
echo "   • Utility Billing v0.0.1 - Utility Bills"
echo ""

echo "🔧 Useful commands:"
echo "   View status:    docker-compose -f $COMPOSE_FILE ps"
echo "   View logs:      docker-compose -f $COMPOSE_FILE logs"
echo "   Stop services:  docker-compose -f $COMPOSE_FILE down"
echo "   Start services: docker-compose -f $COMPOSE_FILE up -d"
echo ""

echo "📖 For more information, see README-PRODUCTION.md"
echo ""

# Offer to set up SSL if domain is configured
if [[ "$SITE_NAME" != *"localhost"* ]] && [[ "$SITE_NAME" != *"127.0.0.1"* ]] && [[ "$SITE_NAME" != *".local"* ]]; then
    echo "🔒 Would you like to set up SSL/HTTPS? (requires domain name)"
    read -p "Setup SSL now? (y/n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo "📝 SSL setup requires manual configuration."
        echo "   See README-PRODUCTION.md for SSL setup instructions."
        echo "   You can use either Traefik or Let's Encrypt methods."
    fi
fi

echo ""
echo "✨ Setup completed successfully!"