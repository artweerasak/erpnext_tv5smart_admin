#!/bin/bash

# 👥 Script สำหรับสร้าง HR Users และ Roles
# กู้คืน User Management ที่หายไป

set -e

echo "👥 เริ่มสร้าง HR Users และ Roles..."

# สร้าง HR Roles และ Users
docker compose -f docker-compose-fixed.yaml exec backend bash -c "
cd /home/frappe/frappe-bench

bench --site frontend console <<< \"
import frappe
from frappe.core.doctype.user.user import User

# สร้าง HR Manager Role (ถ้ายังไม่มี)
if not frappe.db.exists('Role', 'HR Manager'):
    role = frappe.get_doc({
        'doctype': 'Role',
        'role_name': 'HR Manager',
        'desk_access': 1
    })
    role.insert(ignore_permissions=True)
    print('✅ สร้าง HR Manager Role แล้ว')

# สร้าง HR User Role (ถ้ายังไม่มี)  
if not frappe.db.exists('Role', 'HR User'):
    role = frappe.get_doc({
        'doctype': 'Role',
        'role_name': 'HR User',
        'desk_access': 1
    })
    role.insert(ignore_permissions=True)
    print('✅ สร้าง HR User Role แล้ว')

# สร้าง Budget Manager Role
if not frappe.db.exists('Role', 'Budget Manager'):
    role = frappe.get_doc({
        'doctype': 'Role', 
        'role_name': 'Budget Manager',
        'desk_access': 1
    })
    role.insert(ignore_permissions=True)
    print('✅ สร้าง Budget Manager Role แล้ว')

# สร้าง HR Manager User
hr_manager_email = 'hr.manager@company.com'
if not frappe.db.exists('User', hr_manager_email):
    user = frappe.get_doc({
        'doctype': 'User',
        'email': hr_manager_email,
        'first_name': 'HR',
        'last_name': 'Manager',
        'send_welcome_email': 0,
        'roles': [
            {'role': 'HR Manager'},
            {'role': 'HR User'},
            {'role': 'Employee Self Service'}
        ]
    })
    user.insert(ignore_permissions=True)
    user.new_password = 'hr123456'
    user.save(ignore_permissions=True)
    print('✅ สร้าง HR Manager User แล้ว')
    print('   Email: hr.manager@company.com')
    print('   Password: hr123456')

# สร้าง HR Officer User
hr_officer_email = 'hr.officer@company.com'
if not frappe.db.exists('User', hr_officer_email):
    user = frappe.get_doc({
        'doctype': 'User',
        'email': hr_officer_email,
        'first_name': 'HR',
        'last_name': 'Officer',
        'send_welcome_email': 0,
        'roles': [
            {'role': 'HR User'},
            {'role': 'Employee Self Service'}
        ]
    })
    user.insert(ignore_permissions=True) 
    user.new_password = 'hr123456'
    user.save(ignore_permissions=True)
    print('✅ สร้าง HR Officer User แล้ว')
    print('   Email: hr.officer@company.com')
    print('   Password: hr123456')

# สร้าง Budget Manager User
budget_manager_email = 'budget.manager@company.com'
if not frappe.db.exists('User', budget_manager_email):
    user = frappe.get_doc({
        'doctype': 'User',
        'email': budget_manager_email,
        'first_name': 'Budget',
        'last_name': 'Manager',
        'send_welcome_email': 0,
        'roles': [
            {'role': 'Budget Manager'},
            {'role': 'Accounts User'}
        ]
    })
    user.insert(ignore_permissions=True)
    user.new_password = 'budget123'
    user.save(ignore_permissions=True)
    print('✅ สร้าง Budget Manager User แล้ว')
    print('   Email: budget.manager@company.com') 
    print('   Password: budget123')

frappe.db.commit()
print('🎉 สร้าง Users และ Roles สำเร็จทั้งหมด!')

exit
\"
"

echo "✅ สร้าง HR Users และ Roles สำเร็จ!"
echo ""
echo "👤 Users ที่สร้างแล้ว:"
echo "   1. HR Manager: hr.manager@company.com / hr123456"
echo "   2. HR Officer: hr.officer@company.com / hr123456"
echo "   3. Budget Manager: budget.manager@company.com / budget123"
echo ""
echo "📝 ขั้นตอนต่อไป: Customize Employee DocType"
echo "    คำสั่ง: ./customize-employee.sh"
