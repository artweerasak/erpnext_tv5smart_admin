#!/bin/bash

# 🚀 ขั้นตอนสุดท้าย - ERPNext พร้อม HRMS และ Lending
# ใช้ frappe_docker official approach

set -e

echo "🚀 ขั้นตอนสุดท้าย - Setup ERPNext แบบสมบูรณ์"

# ทำความสะอาด
docker volume rm $(docker volume ls -q | grep erpnext_tv5smart_admin) 2>/dev/null || true

# Clone frappe_docker repo
if [ ! -d "frappe_docker" ]; then
    echo "📥 Cloning frappe_docker..."
    git clone https://github.com/frappe/frappe_docker.git
    cd frappe_docker
else
    cd frappe_docker
    git pull
fi

# เตรียม environment
echo "📝 เตรียม environment..."
cp example.env .env

# แก้ไข .env file
sed -i 's/ERPNEXT_VERSION=.*/ERPNEXT_VERSION=v15.78.1/' .env
sed -i 's/FRAPPE_VERSION=.*/FRAPPE_VERSION=v15.80.0/' .env
echo "INSTALL_APPS=erpnext,hrms,lending" >> .env

# ใช้ docker compose production setup
echo "🚀 เริ่มระบบ..."
docker compose -f compose.yaml -f overrides/compose.mariadb.yaml -f overrides/compose.redis.yaml -f pwd.yml up -d

echo "⏳ รอให้ระบบเริ่ม..."
sleep 60

# สร้าง site
echo "🏗️ สร้าง ERPNext site..."
docker compose -f compose.yaml -f overrides/compose.mariadb.yaml -f overrides/compose.redis.yaml -f pwd.yml exec backend bench new-site frontend --admin-password admin --db-root-password admin --install-app erpnext --set-default

# ติดตั้ง HRMS
echo "📦 ติดตั้ง HRMS..."
docker compose -f compose.yaml -f overrides/compose.mariadb.yaml -f overrides/compose.redis.yaml -f pwd.yml exec backend bench get-app hrms https://github.com/frappe/hrms.git --branch version-15
docker compose -f compose.yaml -f overrides/compose.mariadb.yaml -f overrides/compose.redis.yaml -f pwd.yml exec backend bench --site frontend install-app hrms

# ติดตั้ง Lending
echo "📦 ติดตั้ง Lending..."
docker compose -f compose.yaml -f overrides/compose.mariadb.yaml -f overrides/compose.redis.yaml -f pwd.yml exec backend bench get-app lending https://github.com/frappe/lending.git --branch develop
docker compose -f compose.yaml -f overrides/compose.mariadb.yaml -f overrides/compose.redis.yaml -f pwd.yml exec backend bench --site frontend install-app lending

echo ""
echo "🎉 ERPNext พร้อม HRMS และ Lending สำเร็จ!"
echo "🌐 URL: http://localhost:8080"
echo "👤 Username: Administrator"
echo "🔐 Password: admin"
echo ""
echo "📋 ขั้นตอนต่อไป:"
echo "    cd .. && ./full-recovery.sh"
