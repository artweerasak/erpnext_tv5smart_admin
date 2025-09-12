#!/bin/bash

# 👥 Script สำหรับสร้างข้อมูล Employee ตัวอย่าง
# พร้อมข้อมูลภาษาไทยและ custom fields

set -e

echo "👥 เริ่มสร้างข้อมูล Employee ตัวอย่าง..."

docker compose -f docker-compose-fixed.yaml exec backend bash -c "
cd /home/frappe/frappe-bench

bench --site frontend console <<< \"
import frappe
import json

# ข้อมูล Employee ตัวอย่าง
employees = [
    {
        'employee_name': 'Somchai Jaidee',
        'thai_name': 'สมชาย ใจดี',
        'employee_number': 'EMP001',
        'gender': 'Male',
        'date_of_birth': '1985-05-15',
        'date_of_joining': '2020-01-15',
        'department': 'Human Resources',
        'designation': 'Manager',
        'branch': 'Head Office',
        'employee_grade': 'Management Level',
        'personal_email': 'somchai.j@email.com',
        'cell_number': '081-234-5678',
        'thai_id_card': '1234567890123',
        'emergency_contact_name': 'Siriporn Jaidee',
        'emergency_contact_phone': '081-234-5679',
        'position_level': 'Senior',
        'budget_code': 'HR-MGR-001'
    },
    {
        'employee_name': 'Siriporn Sukhum',
        'thai_name': 'ศิริพร สุขุม',
        'employee_number': 'EMP002', 
        'gender': 'Female',
        'date_of_birth': '1988-08-20',
        'date_of_joining': '2021-03-01',
        'department': 'Finance',
        'designation': 'Senior Officer',
        'branch': 'Head Office',
        'employee_grade': 'Grade A',
        'personal_email': 'siriporn.s@email.com',
        'cell_number': '082-345-6789',
        'thai_id_card': '2345678901234',
        'emergency_contact_name': 'Niran Sukhum',
        'emergency_contact_phone': '082-345-6790',
        'position_level': 'Mid-level',
        'budget_code': 'FIN-SR-002'
    },
    {
        'employee_name': 'Niran Kawkwan',
        'thai_name': 'นิรันดร์ เก่าขวาน',
        'employee_number': 'EMP003',
        'gender': 'Male', 
        'date_of_birth': '1992-12-10',
        'date_of_joining': '2022-06-01',
        'department': 'IT Department',
        'designation': 'Officer',
        'branch': 'Head Office',
        'employee_grade': 'Grade B',
        'personal_email': 'niran.k@email.com',
        'cell_number': '083-456-7890',
        'thai_id_card': '3456789012345',
        'emergency_contact_name': 'Pranee Kawkwan',
        'emergency_contact_phone': '083-456-7891',
        'position_level': 'Junior',
        'budget_code': 'IT-OFF-003'
    },
    {
        'employee_name': 'Pranee Malee',
        'thai_name': 'ปราณี มาลี',
        'employee_number': 'EMP004',
        'gender': 'Female',
        'date_of_birth': '1990-03-25',
        'date_of_joining': '2023-01-10', 
        'department': 'Sales',
        'designation': 'Coordinator',
        'branch': 'Branch 1',
        'employee_grade': 'Grade C',
        'personal_email': 'pranee.m@email.com',
        'cell_number': '084-567-8901',
        'thai_id_card': '4567890123456',
        'emergency_contact_name': 'Somsak Malee',
        'emergency_contact_phone': '084-567-8902',
        'position_level': 'Entry-level',
        'budget_code': 'SAL-CRD-004'
    },
    {
        'employee_name': 'Apinya Thongsuk',
        'thai_name': 'อภิญญา ทองสุข',
        'employee_number': 'EMP005',
        'gender': 'Female',
        'date_of_birth': '1987-07-08',
        'date_of_joining': '2019-09-15',
        'department': 'Marketing',
        'designation': 'Assistant Manager',
        'branch': 'Head Office',
        'employee_grade': 'Senior Level',
        'personal_email': 'apinya.t@email.com',
        'cell_number': '085-678-9012',
        'thai_id_card': '5678901234567',
        'emergency_contact_name': 'Wichai Thongsuk',
        'emergency_contact_phone': '085-678-9013',
        'position_level': 'Senior',
        'budget_code': 'MKT-AMGR-005'
    }
]

# สร้าง Employee records
for emp_data in employees:
    if not frappe.db.exists('Employee', emp_data['employee_number']):
        # สร้าง Employee record
        employee = frappe.get_doc({
            'doctype': 'Employee',
            'employee_name': emp_data['employee_name'],
            'employee_number': emp_data['employee_number'],
            'gender': emp_data['gender'],
            'date_of_birth': emp_data['date_of_birth'],
            'date_of_joining': emp_data['date_of_joining'],
            'department': emp_data['department'],
            'designation': emp_data['designation'],
            'branch': emp_data['branch'],
            'grade': emp_data['employee_grade'],
            'personal_email': emp_data['personal_email'],
            'cell_number': emp_data['cell_number'],
            'status': 'Active'
        })
        
        # เพิ่ม custom field values
        employee.set('custom_thai_name', emp_data['thai_name'])
        employee.set('custom_thai_id_card', emp_data['thai_id_card'])
        employee.set('custom_emergency_contact_name', emp_data['emergency_contact_name'])
        employee.set('custom_emergency_contact_phone', emp_data['emergency_contact_phone'])
        employee.set('custom_position_level', emp_data['position_level'])
        employee.set('custom_budget_code', emp_data['budget_code'])
        
        employee.insert(ignore_permissions=True)
        print(f'✅ สร้าง Employee: {emp_data[\"employee_name\"]} ({emp_data[\"thai_name\"]})')

# สร้าง User accounts สำหรับ Employees
user_data = [
    {'employee_number': 'EMP001', 'email': 'somchai@company.com', 'roles': ['HR Manager', 'Budget Manager']},
    {'employee_number': 'EMP002', 'email': 'siriporn@company.com', 'roles': ['Accounts User']},
    {'employee_number': 'EMP003', 'email': 'niran@company.com', 'roles': ['System Manager']},
    {'employee_number': 'EMP004', 'email': 'pranee@company.com', 'roles': ['Sales User']},
    {'employee_number': 'EMP005', 'email': 'apinya@company.com', 'roles': ['Marketing User']}
]

for user_info in user_data:
    if not frappe.db.exists('User', user_info['email']):
        employee = frappe.get_doc('Employee', user_info['employee_number'])
        
        user = frappe.get_doc({
            'doctype': 'User',
            'email': user_info['email'],
            'first_name': employee.employee_name.split(' ')[0],
            'last_name': ' '.join(employee.employee_name.split(' ')[1:]) if len(employee.employee_name.split(' ')) > 1 else '',
            'enabled': 1,
            'user_type': 'System User',
            'new_password': 'password123'
        })
        
        # เพิ่ม roles
        for role in user_info['roles']:
            user.append('roles', {'role': role})
        
        user.insert(ignore_permissions=True)
        
        # Link User กับ Employee
        employee.user_id = user_info['email']
        employee.save(ignore_permissions=True)
        
        print(f'✅ สร้าง User: {user_info[\"email\"]} สำหรับ {employee.employee_name}')

frappe.db.commit()
print('🎉 สร้างข้อมูล Employee ตัวอย่างสำเร็จทั้งหมด!')

exit
\"
"

echo "✅ สร้างข้อมูล Employee ตัวอย่างสำเร็จ!"
echo ""
echo "👥 Employee ที่สร้างแล้ว:"
echo "   • EMP001 - Somchai Jaidee (สมชาย ใจดี) - HR Manager"
echo "   • EMP002 - Siriporn Sukhum (ศิริพร สุขุม) - Finance Senior Officer"
echo "   • EMP003 - Niran Kawkwan (นิรันดร์ เก่าขวาน) - IT Officer"
echo "   • EMP004 - Pranee Malee (ปราณี มาลี) - Sales Coordinator"
echo "   • EMP005 - Apinya Thongsuk (อภิญญา ทองสุข) - Marketing Assistant Manager"
echo ""
echo "🔐 User accounts ที่สร้างแล้ว (รหัสผ่าน: password123):"
echo "   • somchai@company.com - HR Manager, Budget Manager"
echo "   • siriporn@company.com - Accounts User"
echo "   • niran@company.com - System Manager"
echo "   • pranee@company.com - Sales User"
echo "   • apinya@company.com - Marketing User"
echo ""
echo "📝 ขั้นตอนต่อไป: สร้าง Budget ตัวอย่าง"
echo "    คำสั่ง: ./create-sample-budgets.sh"
