#!/bin/bash

# 🚀 ERPNext Recovery - Working Solution
# สร้างระบบ ERPNext ที่ใช้งานได้และกู้คืน HRMS + Lending

set -e

echo "🚀 เริ่มกู้คืนระบบ ERPNext..."

# หยุดและทำความสะอาด
echo "🧹 ทำความสะอาดระบบ..."
docker compose -f docker-compose-fixed.yaml down 2>/dev/null || true
docker volume rm $(docker volume ls -q | grep erpnext_tv5smart_admin) 2>/dev/null || true

# สร้าง Working Docker Compose
echo "📝 สร้าง Docker Compose ที่ทำงานได้..."
cat > docker-compose-working.yaml << 'EOF'
services:
  db:
    image: mariadb:10.6
    restart: always
    environment:
      - MYSQL_ROOT_PASSWORD=admin
      - MYSQL_DATABASE=erpnext_db
      - MYSQL_USER=erpnext_user
      - MYSQL_PASSWORD=erpnext_pass
    volumes:
      - db-data:/var/lib/mysql
    command: --character-set-server=utf8mb4 --collation-server=utf8mb4_unicode_ci
    ports:
      - "3306:3306"

  redis-cache:
    image: redis:6.2-alpine
    restart: always

  redis-queue:
    image: redis:6.2-alpine  
    restart: always

  erpnext:
    image: frappe/erpnext:v15.78.1
    restart: always
    depends_on:
      - db
      - redis-cache
      - redis-queue
    ports:
      - "8080:8000"
    volumes:
      - sites:/home/frappe/frappe-bench/sites
    environment:
      - DB_HOST=db
      - DB_PORT=3306
      - REDIS_CACHE=redis://redis-cache:6379
      - REDIS_QUEUE=redis://redis-queue:6379

volumes:
  db-data:
  sites:
EOF

echo "🚀 เริ่มระบบ..."
docker compose -f docker-compose-working.yaml up -d

echo "⏳ รอให้ database พร้อม..."
sleep 30

# สร้าง site manually
echo "🏗️ สร้าง ERPNext site..."
docker compose -f docker-compose-working.yaml exec -T erpnext bash -c "
export DB_HOST=db
export DB_PORT=3306
export DB_NAME=erpnext_db
export DB_USER=erpnext_user
export DB_PASSWORD=erpnext_pass

# สร้าง common site config
cat > sites/common_site_config.json << 'EOFCONFIG'
{
 \"db_host\": \"db\",
 \"db_port\": 3306,
 \"redis_cache\": \"redis://redis-cache:6379\",
 \"redis_queue\": \"redis://redis-queue:6379\",
 \"redis_socketio\": \"redis://redis-queue:6379\"
}
EOFCONFIG

# สร้าง site
bench new-site frontend --admin-password admin --db-root-password admin --install-app erpnext --set-default

echo 'Site created successfully!'
" 2>/dev/null || echo "Site creation attempted..."

echo "⏳ รอให้ระบบเริ่มทำงาน..."
sleep 30

# ทดสอบการเข้าถึง
echo "🔍 ทดสอบการเข้าถึง..."
response=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:8080/login 2>/dev/null || echo "000")

if [ "$response" = "200" ] || [ "$response" = "302" ]; then
    echo "✅ ระบบ ERPNext พร้อมใช้งาน!"
    echo ""
    echo "🌐 เข้าใช้งาน: http://localhost:8080"
    echo "👤 Username: Administrator"
    echo "🔐 Password: admin"
    echo ""
    
    echo "🚀 เริ่มติดตั้ง HRMS และ Lending..."
    
    # ติดตั้ง HRMS
    docker compose -f docker-compose-working.yaml exec -T erpnext bash -c "
    cd /home/frappe/frappe-bench
    
    # Get HRMS
    if [ ! -d 'apps/hrms' ]; then
        echo 'Getting HRMS app...'
        bench get-app hrms https://github.com/frappe/hrms.git --branch version-15
    fi
    
    # Install HRMS
    echo 'Installing HRMS...'
    bench --site frontend install-app hrms
    
    # Get Lending  
    if [ ! -d 'apps/lending' ]; then
        echo 'Getting Lending app...'
        bench get-app lending https://github.com/frappe/lending.git --branch develop
    fi
    
    # Install Lending
    echo 'Installing Lending...'
    bench --site frontend install-app lending
    
    echo 'Apps installation completed!'
    " 2>/dev/null && echo "✅ HRMS และ Lending ติดตั้งสำเร็จ!" || echo "⚠️ อาจมี error ในการติดตั้ง apps"
    
    echo ""
    echo "🎉 การกู้คืนเสร็จสิ้น!"
    echo "📋 ตรวจสอบ apps: docker compose -f docker-compose-working.yaml exec erpnext bench --site frontend list-apps"
    echo "🛑 หยุดระบบ: docker compose -f docker-compose-working.yaml down"
    
else
    echo "❌ ระบบยังไม่พร้อม (response: $response)"
    echo "📋 ตรวจสอบ logs: docker compose -f docker-compose-working.yaml logs erpnext"
fi
