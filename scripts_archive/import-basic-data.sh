#!/bin/bash

# 📊 Script สำหรับ Import ข้อมูลพื้นฐานที่จำเป็น
# สำหรับระบบ HR และ Budget

set -e

echo "📊 เริ่ม Import ข้อมูลพื้นฐาน..."

docker compose -f docker-compose-fixed.yaml exec backend bash -c "
cd /home/frappe/frappe-bench

bench --site frontend console <<< \"
import frappe
import json

# สร้าง Departments พื้นฐาน
departments = [
    {'name': 'Human Resources', 'department_name': 'Human Resources', 'parent_department': '', 'is_group': 0},
    {'name': 'Finance', 'department_name': 'Finance', 'parent_department': '', 'is_group': 0},
    {'name': 'IT Department', 'department_name': 'IT Department', 'parent_department': '', 'is_group': 0},
    {'name': 'Operations', 'department_name': 'Operations', 'parent_department': '', 'is_group': 0},
    {'name': 'Sales', 'department_name': 'Sales', 'parent_department': '', 'is_group': 0},
    {'name': 'Marketing', 'department_name': 'Marketing', 'parent_department': '', 'is_group': 0}
]

for dept_data in departments:
    if not frappe.db.exists('Department', dept_data['name']):
        dept = frappe.get_doc({
            'doctype': 'Department',
            'department_name': dept_data['department_name'],
            'parent_department': dept_data['parent_department'],
            'is_group': dept_data['is_group']
        })
        dept.insert(ignore_permissions=True)
        print(f'✅ สร้าง Department: {dept_data[\"department_name\"]}')

# สร้าง Designations พื้นฐาน
designations = [
    'Manager', 'Assistant Manager', 'Senior Officer', 'Officer', 
    'Junior Officer', 'Coordinator', 'Specialist', 'Analyst',
    'Administrator', 'Executive', 'Director', 'Vice President'
]

for designation in designations:
    if not frappe.db.exists('Designation', designation):
        des = frappe.get_doc({
            'doctype': 'Designation',
            'designation_name': designation
        })
        des.insert(ignore_permissions=True)
        print(f'✅ สร้าง Designation: {designation}')

# สร้าง Employee Grades
grades = [
    {'name': 'Grade A', 'grade_name': 'Grade A'},
    {'name': 'Grade B', 'grade_name': 'Grade B'}, 
    {'name': 'Grade C', 'grade_name': 'Grade C'},
    {'name': 'Grade D', 'grade_name': 'Grade D'},
    {'name': 'Senior Level', 'grade_name': 'Senior Level'},
    {'name': 'Management Level', 'grade_name': 'Management Level'}
]

for grade_data in grades:
    if not frappe.db.exists('Employee Grade', grade_data['name']):
        grade = frappe.get_doc({
            'doctype': 'Employee Grade',
            'name': grade_data['name'],
            'grade_name': grade_data['grade_name']
        })
        grade.insert(ignore_permissions=True)
        print(f'✅ สร้าง Employee Grade: {grade_data[\"grade_name\"]}')

# สร้าง Branch/Location พื้นฐาน
branches = [
    {'branch': 'Head Office', 'address': 'Bangkok, Thailand'},
    {'branch': 'Branch 1', 'address': 'Chiang Mai, Thailand'}, 
    {'branch': 'Branch 2', 'address': 'Phuket, Thailand'},
    {'branch': 'Remote Office', 'address': 'Work from Home'}
]

for branch_data in branches:
    if not frappe.db.exists('Branch', branch_data['branch']):
        branch = frappe.get_doc({
            'doctype': 'Branch', 
            'branch': branch_data['branch'],
            'address': branch_data['address']
        })
        branch.insert(ignore_permissions=True)
        print(f'✅ สร้าง Branch: {branch_data[\"branch\"]}')

# สร้าง Holiday List สำหรับไทย
if not frappe.db.exists('Holiday List', 'Thailand Holidays 2024'):
    holiday_list = frappe.get_doc({
        'doctype': 'Holiday List',
        'holiday_list_name': 'Thailand Holidays 2024',
        'from_date': '2024-01-01',
        'to_date': '2024-12-31',
        'holidays': [
            {'holiday_date': '2024-01-01', 'description': 'New Year Day'},
            {'holiday_date': '2024-02-26', 'description': 'Makha Bucha Day'},
            {'holiday_date': '2024-04-06', 'description': 'Chakri Day'},
            {'holiday_date': '2024-04-13', 'description': 'Songkran Festival'},
            {'holiday_date': '2024-04-14', 'description': 'Songkran Festival'},
            {'holiday_date': '2024-04-15', 'description': 'Songkran Festival'},
            {'holiday_date': '2024-05-01', 'description': 'Labour Day'},
            {'holiday_date': '2024-05-04', 'description': 'Coronation Day'},
            {'holiday_date': '2024-05-22', 'description': 'Visakha Bucha Day'},
            {'holiday_date': '2024-07-20', 'description': 'Buddhist Lent Day'},
            {'holiday_date': '2024-07-28', 'description': 'King Vajiralongkorn Birthday'},
            {'holiday_date': '2024-08-12', 'description': 'Queen Mother Birthday'},
            {'holiday_date': '2024-10-13', 'description': 'King Bhumibol Memorial Day'},
            {'holiday_date': '2024-10-23', 'description': 'Chulalongkorn Day'},
            {'holiday_date': '2024-12-05', 'description': 'King Bhumibol Birthday'},
            {'holiday_date': '2024-12-10', 'description': 'Constitution Day'},
            {'holiday_date': '2024-12-31', 'description': 'New Year Eve'}
        ]
    })
    holiday_list.insert(ignore_permissions=True)
    print('✅ สร้าง Thailand Holiday List 2024')

# สร้าง Leave Types พื้นฐาน
leave_types = [
    {'leave_type_name': 'Annual Leave', 'max_leaves_allowed': 15, 'is_carry_forward': 1},
    {'leave_type_name': 'Sick Leave', 'max_leaves_allowed': 30, 'is_carry_forward': 0},
    {'leave_type_name': 'Maternity Leave', 'max_leaves_allowed': 98, 'is_carry_forward': 0},
    {'leave_type_name': 'Paternity Leave', 'max_leaves_allowed': 15, 'is_carry_forward': 0},
    {'leave_type_name': 'Personal Leave', 'max_leaves_allowed': 3, 'is_carry_forward': 0},
    {'leave_type_name': 'Emergency Leave', 'max_leaves_allowed': 5, 'is_carry_forward': 0}
]

for leave_data in leave_types:
    if not frappe.db.exists('Leave Type', leave_data['leave_type_name']):
        leave_type = frappe.get_doc({
            'doctype': 'Leave Type',
            'leave_type_name': leave_data['leave_type_name'],
            'max_leaves_allowed': leave_data['max_leaves_allowed'],
            'is_carry_forward': leave_data['is_carry_forward'],
            'is_optional_leave': 0,
            'allow_negative': 0,
            'include_holiday': 1
        })
        leave_type.insert(ignore_permissions=True)
        print(f'✅ สร้าง Leave Type: {leave_data[\"leave_type_name\"]}')

frappe.db.commit()
print('🎉 Import ข้อมูลพื้นฐานสำเร็จทั้งหมด!')

exit
\"
"

echo "✅ Import ข้อมูลพื้นฐานสำเร็จ!"
echo ""
echo "📋 ข้อมูลที่สร้างแล้ว:"
echo "   • 6 Departments พื้นฐาน"
echo "   • 12 Designations"
echo "   • 6 Employee Grades"  
echo "   • 4 Branches/Locations"
echo "   • Thailand Holiday List 2024"
echo "   • 6 Leave Types พื้นฐาน"
echo ""
echo "📝 ขั้นตอนต่อไป: สร้าง Employee sample data"
echo "    คำสั่ง: ./create-sample-employees.sh"
