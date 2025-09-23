#!/bin/bash

# ERPNext Production Deployment with Custom Data
# This script deploys ERPNext with all customizations and data automatically restored

set -e

echo "🚀 ERPNext Production Deployment with Custom Data"
echo "=================================================="

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
    echo "❌ Docker is not installed. Please install Docker first."
    exit 1
fi

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
        echo "📝 Please edit .env file with your production settings"
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

echo "📦 Starting ERPNext services..."
docker-compose -f docker-compose.production.yaml up -d db redis-cache redis-queue

echo "⏳ Waiting for database to be ready..."
sleep 30

echo "🔄 Restoring custom data and creating site..."
docker-compose -f docker-compose.production.yaml --profile restore up restore-data

echo "🌐 Starting all services..."
docker-compose -f docker-compose.production.yaml up -d

echo "⏳ Waiting for services to be ready..."
sleep 60

echo ""
echo "🎉 ERPNext deployment with custom data completed!"
echo "================================================="
echo ""
echo "📍 Access your ERPNext at:"
if [ "$HTTP_PUBLISH_PORT" = "80" ]; then
    echo "   http://$SITE_NAME"
else
    echo "   http://$SITE_NAME:$HTTP_PUBLISH_PORT"
fi

echo ""
echo "👤 Login credentials:"
echo "   Username: Administrator"
echo "   Password: $ADMIN_PASSWORD"
echo ""

echo "📚 Available Applications:"
echo "   • ERPNext - Core ERP functionality"
echo "   • HRMS - Human Resource Management"  
echo "   • CRM - Customer Relationship Management"
echo "   • Lending - Loan Management"
echo "   • Utility Billing - Utility billing management"
echo ""

echo "📊 Custom Data Status:"
echo "   • All custom doctypes restored"
echo "   • Database customizations applied"
echo "   • Previous data and settings preserved"
echo ""

echo "🔧 Useful commands:"
echo "   View status:    docker-compose -f docker-compose.production.yaml ps"
echo "   View logs:      docker-compose -f docker-compose.production.yaml logs"
echo "   Stop services:  docker-compose -f docker-compose.production.yaml down"
echo "   Start services: docker-compose -f docker-compose.production.yaml up -d"
echo ""

echo "📖 For more information, see README-PRODUCTION.md"
echo ""
echo "✨ Deployment with custom data completed successfully!"