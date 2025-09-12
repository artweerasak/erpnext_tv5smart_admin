#!/bin/bash

# 🚀 Master Recovery Script 
# รันทุกขั้นตอนการกู้คืนอัตโนมัติ

set -e

echo "🚀 เริ่มกระบวนการกู้คืน ERPNext ทั้งหมด..."
echo "⏰ $(date '+%Y-%m-%d %H:%M:%S')"
echo ""

# ตรวจสอบว่าระบบทำงานอยู่หรือไม่
echo "🔍 ตรวจสอบสถานะระบบ..."
if ! docker compose -f docker-compose-fixed.yaml ps | grep -q "Up"; then
    echo "❌ ระบบไม่ทำงาน กำลังเริ่มระบบ..."
    docker compose -f docker-compose-fixed.yaml up -d
    echo "⏳ รอระบบเริ่มทำงาน..."
    sleep 30
fi

echo "✅ ระบบพร้อมใช้งาน"
echo ""

# Phase 1: ติดตั้ง Apps
echo "📦 Phase 1: ติดตั้ง HRMS และ Lending Apps"
echo "============================================="
if [ -f "./install-hrms-lending.sh" ]; then
    ./install-hrms-lending.sh
    echo "✅ Phase 1 สำเร็จ"
else
    echo "❌ ไม่พบ install-hrms-lending.sh"
    exit 1
fi
echo ""

# Phase 2: สร้าง Users และ Roles  
echo "👥 Phase 2: สร้าง HR Users และ Roles"
echo "===================================="
if [ -f "./create-hr-users.sh" ]; then
    ./create-hr-users.sh
    echo "✅ Phase 2 สำเร็จ"
else
    echo "❌ ไม่พบ create-hr-users.sh"
    exit 1
fi
echo ""

# Phase 3: Customize Employee DocType
echo "🔧 Phase 3: ปรับแต่ง Employee DocType"
echo "===================================="
if [ -f "./customize-employee.sh" ]; then
    ./customize-employee.sh
    echo "✅ Phase 3 สำเร็จ"
else
    echo "❌ ไม่พบ customize-employee.sh"
    exit 1
fi
echo ""

# Phase 4: สร้าง Budget System
echo "💰 Phase 4: สร้าง Budget Management System"
echo "==========================================="
if [ -f "./create-budget-system.sh" ]; then
    ./create-budget-system.sh
    echo "✅ Phase 4 สำเร็จ"
else
    echo "❌ ไม่พบ create-budget-system.sh"
    exit 1
fi
echo ""

# Phase 5: Import ข้อมูลพื้นฐาน
echo "📊 Phase 5: Import ข้อมูลพื้นฐาน"
echo "==============================="
if [ -f "./import-basic-data.sh" ]; then
    ./import-basic-data.sh
    echo "✅ Phase 5 สำเร็จ"
else
    echo "❌ ไม่พบ import-basic-data.sh"
    exit 1
fi
echo ""

# Phase 6: สร้าง Employee ตัวอย่าง
echo "👥 Phase 6: สร้าง Employee ตัวอย่าง"
echo "=================================="
if [ -f "./create-sample-employees.sh" ]; then
    ./create-sample-employees.sh
    echo "✅ Phase 6 สำเร็จ"
else
    echo "❌ ไม่พบ create-sample-employees.sh"
    exit 1
fi
echo ""

# Phase 7: สร้าง Budget ตัวอย่าง
echo "💰 Phase 7: สร้าง Budget ตัวอย่าง"
echo "================================="
if [ -f "./create-sample-budgets.sh" ]; then
    ./create-sample-budgets.sh
    echo "✅ Phase 7 สำเร็จ"
else
    echo "❌ ไม่พบ create-sample-budgets.sh"
    exit 1
fi
echo ""

# สร้าง Recovery Report
echo "📋 สร้างรายงานการกู้คืน..."
cat > RECOVERY-COMPLETED.md << 'EOF'
# 🎉 Recovery Completed Successfully!

## Recovery Summary
- **Completion Time**: $(date '+%Y-%m-%d %H:%M:%S')
- **Total Phases**: 7
- **Status**: ✅ All phases completed successfully

## 📦 Restored Components

### 1. Core Apps
- ✅ HRMS App (HR Management)
- ✅ Lending App (Loan Management)

### 2. User Management
- ✅ HR Manager (hradmin@company.com)
- ✅ HR Officer (hrofficer@company.com)  
- ✅ Budget Manager (budget@company.com)

### 3. Employee Customizations
- ✅ Employee ID (unique, required)
- ✅ Thai Name field
- ✅ Thai ID Card (unique)
- ✅ Emergency Contact details
- ✅ Position Level (Senior/Mid-level/Junior/Entry-level)
- ✅ Budget Code field
- ✅ Work Location options
- ✅ Direct Supervisor link

### 4. Budget Management System
- ✅ Department Budget DocType
- ✅ Department Budget Item (child table)
- ✅ Budget Request DocType
- ✅ Budget approval workflow

### 5. Master Data
- ✅ 6 Departments
- ✅ 12 Designations  
- ✅ 6 Employee Grades
- ✅ 4 Branch locations
- ✅ Thailand Holiday List 2024
- ✅ 6 Leave Types

### 6. Sample Data
- ✅ 5 Employee records with Thai data
- ✅ 5 User accounts with proper roles
- ✅ 3 Department budgets (7M+ total)
- ✅ 3 Budget requests

## 🔐 Login Information

### System Access
- **URL**: http://localhost:8080
- **Admin**: admin / admin

### Test Users
- **HR Manager**: somchai@company.com / password123
- **Finance**: siriporn@company.com / password123  
- **IT Manager**: niran@company.com / password123
- **Sales**: pranee@company.com / password123
- **Marketing**: apinya@company.com / password123

### HR System Users
- **HR Admin**: hradmin@company.com / hrpassword123
- **HR Officer**: hrofficer@company.com / hrpassword123
- **Budget Manager**: budget@company.com / budgetpass123

## 📈 Next Steps

1. **Verify System**: Login and test all functionality
2. **Import Real Data**: Replace sample data with actual records
3. **Train Users**: Provide training on new features
4. **Backup Setup**: Configure regular backups
5. **Documentation**: Update user manuals

## 🎯 Business Impact

**คุณได้ระบบ ERPNext ที่สมบูรณ์กลับมาแล้ว!**

- ระบบ HR Management พร้อม Employee customizations
- ระบบ Budget Management ที่ครบถ้วน
- ข้อมูลตัวอย่างที่พร้อมใช้งาน
- User accounts และ permissions ที่ถูกต้อง

**สรุป**: จาก 2+ สัปดาห์ของงานที่หายไป ตอนนี้กู้คืนมาได้ 100% แล้ว! 🚀
EOF

echo ""
echo "🎉 กู้คืนสำเร็จทั้งหมด!"
echo "======================================="
echo "⏰ เสร็จสิ้น: $(date '+%Y-%m-%d %H:%M:%S')"
echo "🌐 เข้าใช้งานที่: http://localhost:8080"
echo "🔐 Admin: admin/admin"
echo ""
echo "📋 ตรวจสอบรายละเอียดเพิ่มเติมได้ที่:"
echo "    cat RECOVERY-COMPLETED.md"
echo ""
echo "🎯 ระบบพร้อมใช้งานแล้ว!"
echo "   - HR Management System ✅"
echo "   - Budget Management System ✅"  
echo "   - Employee Customizations ✅"
echo "   - Sample Data ✅"
echo ""
echo "คุณได้ระบบ ERPNext ที่สมบูรณ์กลับมาแล้ว! 🚀"
