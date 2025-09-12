#!/bin/bash

# 🏢 Script สำหรับ Customize Employee DocType
# กู้คืน Employee Customizations ที่หายไป

set -e

echo "🏢 เริ่ม Customize Employee DocType..."

docker compose -f docker-compose-fixed.yaml exec backend bash -c "
cd /home/frappe/frappe-bench

bench --site frontend console <<< \"
import frappe
from frappe.custom.doctype.custom_field.custom_field import create_custom_field

# Employee ID Field
if not frappe.db.exists('Custom Field', 'Employee-employee_id'):
    create_custom_field('Employee', {
        'fieldname': 'employee_id',
        'label': 'Employee ID',
        'fieldtype': 'Data',
        'unique': 1,
        'reqd': 1,
        'insert_after': 'employee_name'
    })
    print('✅ เพิ่ม Employee ID field')

# Thai Name Field
if not frappe.db.exists('Custom Field', 'Employee-thai_name'):
    create_custom_field('Employee', {
        'fieldname': 'thai_name', 
        'label': 'ชื่อภาษาไทย',
        'fieldtype': 'Data',
        'insert_after': 'employee_id'
    })
    print('✅ เพิ่ม Thai Name field')

# Section Break
if not frappe.db.exists('Custom Field', 'Employee-personal_info_section'):
    create_custom_field('Employee', {
        'fieldname': 'personal_info_section',
        'label': 'ข้อมูลส่วนตัว',
        'fieldtype': 'Section Break',
        'insert_after': 'thai_name'
    })
    print('✅ เพิ่ม Personal Info section')

# Thai ID Card
if not frappe.db.exists('Custom Field', 'Employee-thai_id_card'):
    create_custom_field('Employee', {
        'fieldname': 'thai_id_card',
        'label': 'เลขบัตรประชาชน',
        'fieldtype': 'Data',
        'unique': 1,
        'insert_after': 'personal_info_section'
    })
    print('✅ เพิ่ม Thai ID Card field')

# Phone Number
if not frappe.db.exists('Custom Field', 'Employee-phone_number'):
    create_custom_field('Employee', {
        'fieldname': 'phone_number',
        'label': 'เบอร์โทรศัพท์',
        'fieldtype': 'Data',
        'insert_after': 'thai_id_card'
    })
    print('✅ เพิ่ม Phone Number field')

# Column Break
if not frappe.db.exists('Custom Field', 'Employee-column_break_1'):
    create_custom_field('Employee', {
        'fieldname': 'column_break_1',
        'fieldtype': 'Column Break',
        'insert_after': 'phone_number'
    })

# Emergency Contact
if not frappe.db.exists('Custom Field', 'Employee-emergency_contact'):
    create_custom_field('Employee', {
        'fieldname': 'emergency_contact',
        'label': 'ติดต่อฉุกเฉิน',
        'fieldtype': 'Data', 
        'insert_after': 'column_break_1'
    })
    print('✅ เพิ่ม Emergency Contact field')

# Emergency Contact Phone
if not frappe.db.exists('Custom Field', 'Employee-emergency_contact_phone'):
    create_custom_field('Employee', {
        'fieldname': 'emergency_contact_phone',
        'label': 'เบอร์ติดต่อฉุกเฉิน',
        'fieldtype': 'Data',
        'insert_after': 'emergency_contact'
    })
    print('✅ เพิ่ม Emergency Contact Phone field')

# Work Info Section
if not frappe.db.exists('Custom Field', 'Employee-work_info_section'):
    create_custom_field('Employee', {
        'fieldname': 'work_info_section',
        'label': 'ข้อมูลการทำงาน',
        'fieldtype': 'Section Break',
        'insert_after': 'emergency_contact_phone'
    })
    print('✅ เพิ่ม Work Info section')

# Position Level
if not frappe.db.exists('Custom Field', 'Employee-position_level'):
    create_custom_field('Employee', {
        'fieldname': 'position_level',
        'label': 'ระดับตำแหน่ง',
        'fieldtype': 'Select',
        'options': 'Officer\\nSenior Officer\\nSupervisor\\nManager\\nSenior Manager\\nDirector',
        'insert_after': 'work_info_section'
    })
    print('✅ เพิ่ม Position Level field')

# Work Location
if not frappe.db.exists('Custom Field', 'Employee-work_location'):
    create_custom_field('Employee', {
        'fieldname': 'work_location',
        'label': 'สถานที่ทำงาน',
        'fieldtype': 'Data',
        'insert_after': 'position_level'
    })
    print('✅ เพิ่ม Work Location field')

# Column Break 2  
if not frappe.db.exists('Custom Field', 'Employee-column_break_2'):
    create_custom_field('Employee', {
        'fieldname': 'column_break_2',
        'fieldtype': 'Column Break',
        'insert_after': 'work_location'
    })

# Direct Supervisor
if not frappe.db.exists('Custom Field', 'Employee-direct_supervisor'):
    create_custom_field('Employee', {
        'fieldname': 'direct_supervisor',
        'label': 'หัวหน้างานโดยตรง',
        'fieldtype': 'Link',
        'options': 'Employee',
        'insert_after': 'column_break_2'
    })
    print('✅ เพิ่ม Direct Supervisor field')

# Budget Code
if not frappe.db.exists('Custom Field', 'Employee-budget_code'):
    create_custom_field('Employee', {
        'fieldname': 'budget_code',
        'label': 'รหัสงบประมาณ',
        'fieldtype': 'Data',
        'insert_after': 'direct_supervisor'
    })
    print('✅ เพิ่ม Budget Code field')

frappe.db.commit()
print('🎉 Employee Customization สำเร็จทั้งหมด!')

exit
\"
"

echo "✅ Employee DocType Customization สำเร็จ!"
echo ""
echo "📋 Fields ที่เพิ่มแล้ว:"
echo "   • Employee ID (รหัสพนักงาน)"
echo "   • Thai Name (ชื่อภาษาไทย)"
echo "   • Thai ID Card (เลขบัตรประชาชน)"  
echo "   • Phone Number (เบอร์โทรศัพท์)"
echo "   • Emergency Contact (ติดต่อฉุกเฉิน)"
echo "   • Position Level (ระดับตำแหน่ง)"
echo "   • Work Location (สถานที่ทำงาน)"
echo "   • Direct Supervisor (หัวหน้างานโดยตรง)"
echo "   • Budget Code (รหัสงบประมาณ)"
echo ""
echo "📝 ขั้นตอนต่อไป: สร้าง Budget System"
echo "    คำสั่ง: ./create-budget-system.sh"
