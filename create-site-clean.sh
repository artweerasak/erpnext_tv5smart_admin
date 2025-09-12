#!/bin/bash

echo "🚀 สร้าง ERPNext Site หลังทำความสะอาด..."

# Wait for services
echo "⏳ รอ services..."
sleep 10

# Create site with all apps
echo "📦 สร้าง site พร้อม apps ทั้งหมด..."
docker compose exec -T backend bench new-site frontend \
  --no-mariadb-socket \
  --admin-password=admin \
  --db-root-password=admin \
  --install-app erpnext \
  --install-app hrms \
  --install-app crm \
  --install-app lending \
  --install-app utility_billing \
  --set-default

# Check site status  
echo "✅ เช็คสถานะ site..."
docker compose exec -T backend bench --site frontend list-apps

echo "🎉 สร้าง site เสร็จแล้ว!"
echo "🌐 เข้าใช้งานได้ที่: http://localhost:8081"
echo "👤 Username: Administrator" 
echo "🔑 Password: admin"
