#!/bin/bash

echo "🚀 Installing Additional Apps: HRMS, Lending, Utility Billing"

# Check current apps
echo "📋 Current apps in site:"
docker compose exec backend bench --site frontend list-apps

echo ""
echo "📦 Getting HRMS app..."
docker compose exec backend bench get-app --branch version-15 hrms

echo ""
echo "📦 Getting Lending app..."
docker compose exec backend bench get-app --branch version-15 lending

echo ""
echo "📦 Getting CRM app..."
docker compose exec backend bench get-app --branch version-15 crm

echo ""
echo "🔧 Installing HRMS to site..."
docker compose exec backend bench --site frontend install-app hrms

echo ""
echo "🔧 Installing Lending to site..."
docker compose exec backend bench --site frontend install-app lending

echo ""
echo "🔧 Installing CRM to site..."
docker compose exec backend bench --site frontend install-app crm

echo ""
echo "📋 Final apps list:"
docker compose exec backend bench --site frontend list-apps

echo ""
echo "🎉 All apps installed successfully!"
echo "🌐 Access ERPNext at: http://localhost:8081"
echo "👤 Username: Administrator"
echo "🔑 Password: admin"
