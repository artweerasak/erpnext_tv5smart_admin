#!/bin/bash

# 🚀 ERPNext Utility Billing Recovery Script
# ช่วยแก้ปัญหา Internal Server Error และ Module Import Issues

echo "🔥 ERPNext TV5 Utility Billing Recovery Script"
echo "=============================================="

# 1. ล้างข้อมูลเก่าทั้งหมด
echo "📦 1. Cleaning old volumes and data..."
docker volume prune -f
docker system prune -f

# 2. สร้าง apps directory ใหม่
echo "📁 2. Creating fresh apps directory..."
rm -rf ./apps
mkdir -p ./apps

# 3. Download apps ใหม่ทั้งหมด
echo "⬇️ 3. Downloading all required apps..."
cd ./apps

# HRMS
git clone https://github.com/frappe/hrms.git --branch version-15 --depth 1
echo "✅ HRMS downloaded"

# Lending
git clone https://github.com/frappe/lending.git --branch version-15 --depth 1
echo "✅ Lending downloaded"

# CRM  
git clone https://github.com/frappe/crm.git --branch version-15 --depth 1
echo "✅ CRM downloaded"

# Utility Billing
git clone https://github.com/mymb-etml/frappe_utility_billing.git utility_billing --branch version-15 --depth 1
echo "✅ Utility Billing downloaded"

cd ..

# 4. สร้าง apps.txt
echo "📝 4. Creating apps.txt..."
mkdir -p sites
cat > sites/apps.txt << EOF
frappe
erpnext
hrms
lending
crm
utility_billing
EOF

# 5. Start services
echo "🚀 5. Starting ERPNext services..."
docker compose -f docker-compose-production.yaml up -d

# 6. รอให้ services พร้อม
echo "⏳ 6. Waiting for services to be ready..."
sleep 60

# 7. Install apps ใน bench
echo "🔧 7. Installing apps in bench..."
docker compose -f docker-compose-production.yaml exec backend bash -c "
cd /home/frappe/frappe-bench
./env/bin/pip install -e apps/hrms
./env/bin/pip install -e apps/lending  
./env/bin/pip install -e apps/crm
./env/bin/pip install -e apps/utility_billing
bench build
"

# 8. Install apps in site
echo "💾 8. Installing apps in site..."
docker compose -f docker-compose-production.yaml exec backend bash -c "
cd /home/frappe/frappe-bench
bench --site frontend install-app hrms
bench --site frontend install-app lending
bench --site frontend install-app crm
bench --site frontend install-app utility_billing
bench --site frontend migrate
"

# 9. Restart services
echo "🔄 9. Restarting all services..."
docker compose -f docker-compose-production.yaml restart

echo "✅ Recovery completed!"
echo "🌐 Access: http://localhost:8080"
echo "🔑 Default: Administrator / admin"
