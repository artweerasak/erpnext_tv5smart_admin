#!/bin/bash

# 🎯 Final Working ERPNext Setup
# ใช้ approach ที่รู้ว่าใช้งานได้จริง

set -e

echo "🎯 Final ERPNext Setup - ใช้งานได้จริง!"

# หยุดทุกอย่าง
docker compose -f docker-compose-final.yaml down 2>/dev/null || true
docker volume rm $(docker volume ls -q | grep erpnext_tv5smart_admin) 2>/dev/null || true

# ใช้ official ERPNext image ที่มี everything
echo "🚀 ใช้ official ERPNext complete setup..."

# สร้าง environment file
cat > .env << 'EOF'
ERPNEXT_VERSION=v15.78.1
FRAPPE_VERSION=v15.80.0
DB_PASSWORD=admin
ADMIN_PASSWORD=admin
ENCRYPTION_KEY=$(openssl rand -base64 32)
SITE_NAME=frontend
EOF

# ใช้ simplified single container approach
cat > docker-compose-complete.yaml << 'EOF'
services:
  erpnext-complete:
    image: frappe/erpnext:v15.78.1
    restart: always
    ports:
      - "8080:8000"
    volumes:
      - erpnext-data:/home/frappe/frappe-bench
    environment:
      - ADMIN_PASSWORD=admin
      - INSTALL_APPS=erpnext
    command: >
      bash -c "
        echo 'Setting up ERPNext...'
        
        # ตั้งค่า environment
        export ADMIN_PASSWORD=admin
        export INSTALL_APPS=erpnext
        
        cd /home/frappe/frappe-bench
        
        # สร้าง site ถ้ายังไม่มี
        if [ ! -d 'sites/frontend' ]; then
          echo 'Creating site frontend...'
          bench new-site frontend --admin-password admin --install-app erpnext --set-default
          bench --site frontend enable-scheduler
          echo 'Site created successfully!'
        else
          echo 'Site frontend already exists'
        fi
        
        # รัน ERPNext
        echo 'Starting ERPNext server...'
        exec gunicorn -b 0.0.0.0:8000 -w 4 --timeout 120 --preload frappe.app:application
      "

volumes:
  erpnext-data:
EOF

echo "🚀 เริ่มระบบ ERPNext..."
docker compose -f docker-compose-complete.yaml up -d

echo "⏳ รอให้ ERPNext เริ่มทำงาน..."
sleep 60

# ทดสอบการเข้าถึง
echo "🔍 ทดสอบการเข้าถึง..."
for i in {1..10}; do
    response=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:8080 2>/dev/null || echo "000")
    if [ "$response" = "200" ] || [ "$response" = "302" ]; then
        echo "✅ ERPNext พร้อมใช้งาน!"
        echo ""
        echo "🌐 URL: http://localhost:8080"
        echo "👤 Username: Administrator"
        echo "🔐 Password: admin"
        echo ""
        
        # ติดตั้ง HRMS และ Lending
        echo "📦 ติดตั้ง HRMS และ Lending..."
        docker compose -f docker-compose-complete.yaml exec erpnext-complete bash -c "
          cd /home/frappe/frappe-bench
          
          # Get และ Install HRMS
          echo 'Installing HRMS...'
          bench get-app hrms https://github.com/frappe/hrms.git --branch version-15 || echo 'HRMS get failed'
          bench --site frontend install-app hrms || echo 'HRMS install failed'
          
          # Get และ Install Lending
          echo 'Installing Lending...'
          bench get-app lending https://github.com/frappe/lending.git --branch develop || echo 'Lending get failed'
          bench --site frontend install-app lending || echo 'Lending install failed'
          
          echo 'Apps installation completed!'
        " 2>/dev/null
        
        echo ""
        echo "🎉 ระบบพร้อมใช้งาน!"
        echo "📋 รายการ apps:"
        docker compose -f docker-compose-complete.yaml exec erpnext-complete bench --site frontend list-apps || echo "Cannot list apps"
        
        echo ""
        echo "📝 ขั้นตอนต่อไป: รัน recovery scripts"
        echo "    ./full-recovery.sh"
        
        exit 0
    fi
    
    echo "รอสักครู่... ($i/10) Response: $response"
    sleep 15
done

echo "❌ ERPNext ยังไม่พร้อม"
echo "📋 ตรวจสอบ logs:"
echo "    docker compose -f docker-compose-complete.yaml logs erpnext-complete"
