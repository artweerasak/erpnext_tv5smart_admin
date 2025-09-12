#!/bin/bash

# 🚀 Script สำหรับติดตั้ง HRMS และ Lending อัตโนมัติ
# กู้คืนงานที่หายไป

set -e

echo "🚀 เริ่มติดตั้ง HRMS และ Lending..."

# ตรวจสอบว่าระบบทำงานอยู่หรือไม่
if ! docker compose -f docker-compose-fixed.yaml ps | grep -q "Up"; then
    echo "❌ ระบบไม่ทำงาน กรุณาเริ่มระบบก่อน: ./manage.sh start"
    exit 1
fi

# ติดตั้ง HRMS app
echo "📦 ติดตั้ง HRMS App..."
docker compose -f docker-compose-fixed.yaml exec backend bash -c "
cd /home/frappe/frappe-bench

echo '=== Getting HRMS from GitHub ==='
if [ ! -d 'apps/hrms' ]; then
    bench get-app --branch version-15 hrms https://github.com/frappe/hrms.git
    echo 'HRMS app downloaded successfully!'
else
    echo 'HRMS app already exists!'
fi

echo '=== Installing HRMS package ==='
pip install -e apps/hrms

echo '=== Installing HRMS to site ==='
bench --site frontend install-app hrms
"

# ติดตั้ง Lending app  
echo "💰 ติดตั้ง Lending App..."
docker compose -f docker-compose-fixed.yaml exec backend bash -c "
cd /home/frappe/frappe-bench

echo '=== Getting Lending from GitHub ==='
if [ ! -d 'apps/lending' ]; then
    bench get-app --branch develop lending https://github.com/frappe/lending.git
    echo 'Lending app downloaded successfully!'
else
    echo 'Lending app already exists!'
fi

echo '=== Installing Lending package ==='
pip install -e apps/lending

echo '=== Installing Lending to site ==='
bench --site frontend install-app lending
"

# รีสตาร์ทระบบให้รับรู้ apps ใหม่
echo "🔄 รีสตาร์ทระบบ..."
docker compose -f docker-compose-fixed.yaml restart backend queue-long queue-short scheduler

# ตรวจสอบการติดตั้ง
echo "✅ ตรวจสอบการติดตั้ง..."
sleep 15

docker compose -f docker-compose-fixed.yaml exec backend bash -c "
cd /home/frappe/frappe-bench
echo '=== Apps ที่ติดตั้งแล้ว ==='
bench --site frontend list-apps
"

echo "🎉 ติดตั้ง HRMS และ Lending สำเร็จ!"
echo "📝 ขั้นตอนต่อไป: สร้าง HR Users และ Roles"
echo "    คำสั่ง: ./create-hr-users.sh"
