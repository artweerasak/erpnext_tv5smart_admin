#!/bin/bash

# 💰 Script สำหรับสร้าง Budget Management System
# กู้คืน Budget System ที่หายไป

set -e

echo "💰 เริ่มสร้าง Budget Management System..."

docker compose -f docker-compose-fixed.yaml exec backend bash -c "
cd /home/frappe/frappe-bench

bench --site frontend console <<< \"
import frappe
import json

# สร้าง Department Budget DocType
if not frappe.db.exists('DocType', 'Department Budget'):
    doc = frappe.get_doc({
        'doctype': 'DocType',
        'name': 'Department Budget',
        'module': 'Accounts',
        'custom': 1,
        'is_submittable': 1,
        'autoname': 'naming_series:',
        'title_field': 'department',
        'fields': [
            {
                'fieldname': 'naming_series',
                'label': 'Naming Series',
                'fieldtype': 'Select',
                'options': 'DEPT-BUDGET-.YYYY.-',
                'default': 'DEPT-BUDGET-.YYYY.-',
                'reqd': 1
            },
            {
                'fieldname': 'department',
                'label': 'Department',
                'fieldtype': 'Link',
                'options': 'Department',
                'reqd': 1
            },
            {
                'fieldname': 'fiscal_year',
                'label': 'Fiscal Year',
                'fieldtype': 'Link', 
                'options': 'Fiscal Year',
                'reqd': 1
            },
            {
                'fieldname': 'budget_status',
                'label': 'Budget Status',
                'fieldtype': 'Select',
                'options': 'Draft\\nSubmitted\\nApproved\\nRejected\\nRevision Required',
                'default': 'Draft'
            },
            {
                'fieldname': 'column_break_1',
                'fieldtype': 'Column Break'
            },
            {
                'fieldname': 'total_budget',
                'label': 'Total Budget Amount',
                'fieldtype': 'Currency',
                'read_only': 1
            },
            {
                'fieldname': 'approved_amount',
                'label': 'Approved Amount',
                'fieldtype': 'Currency'
            },
            {
                'fieldname': 'section_break_1',
                'label': 'Budget Details',
                'fieldtype': 'Section Break'
            },
            {
                'fieldname': 'budget_items',
                'label': 'Budget Items',
                'fieldtype': 'Table',
                'options': 'Department Budget Item'
            },
            {
                'fieldname': 'section_break_2',
                'label': 'Approval',
                'fieldtype': 'Section Break'
            },
            {
                'fieldname': 'approved_by',
                'label': 'Approved By',
                'fieldtype': 'Link',
                'options': 'User'
            },
            {
                'fieldname': 'approval_date',
                'label': 'Approval Date',
                'fieldtype': 'Date'
            },
            {
                'fieldname': 'column_break_2',
                'fieldtype': 'Column Break'
            },
            {
                'fieldname': 'remarks',
                'label': 'Remarks',
                'fieldtype': 'Text'
            }
        ],
        'permissions': [
            {
                'role': 'Budget Manager',
                'permlevel': 0,
                'read': 1,
                'write': 1,
                'create': 1,
                'submit': 1,
                'cancel': 1
            },
            {
                'role': 'HR Manager', 
                'permlevel': 0,
                'read': 1,
                'write': 1,
                'create': 1
            }
        ]
    })
    doc.insert(ignore_permissions=True)
    print('✅ สร้าง Department Budget DocType แล้ว')

# สร้าง Department Budget Item Child Table
if not frappe.db.exists('DocType', 'Department Budget Item'):
    doc = frappe.get_doc({
        'doctype': 'DocType',
        'name': 'Department Budget Item',
        'module': 'Accounts',
        'custom': 1,
        'is_child_table': 1,
        'fields': [
            {
                'fieldname': 'budget_category',
                'label': 'Budget Category',
                'fieldtype': 'Select',
                'options': 'Personnel\\nOperating\\nCapital\\nTraining\\nTravel\\nOther',
                'reqd': 1,
                'in_list_view': 1
            },
            {
                'fieldname': 'description',
                'label': 'Description',
                'fieldtype': 'Text',
                'reqd': 1,
                'in_list_view': 1
            },
            {
                'fieldname': 'requested_amount',
                'label': 'Requested Amount',
                'fieldtype': 'Currency',
                'reqd': 1,
                'in_list_view': 1
            },
            {
                'fieldname': 'approved_amount',
                'label': 'Approved Amount',
                'fieldtype': 'Currency',
                'in_list_view': 1
            },
            {
                'fieldname': 'actual_spent',
                'label': 'Actual Spent',
                'fieldtype': 'Currency',
                'read_only': 1,
                'in_list_view': 1
            },
            {
                'fieldname': 'variance',
                'label': 'Variance',
                'fieldtype': 'Currency',
                'read_only': 1
            }
        ]
    })
    doc.insert(ignore_permissions=True)
    print('✅ สร้าง Department Budget Item Child Table แล้ว')

# สร้าง Budget Request DocType
if not frappe.db.exists('DocType', 'Budget Request'):
    doc = frappe.get_doc({
        'doctype': 'DocType',
        'name': 'Budget Request',
        'module': 'Accounts',
        'custom': 1,
        'is_submittable': 1,
        'autoname': 'naming_series:',
        'fields': [
            {
                'fieldname': 'naming_series',
                'label': 'Naming Series',
                'fieldtype': 'Select',
                'options': 'BUDGET-REQ-.YYYY.-',
                'default': 'BUDGET-REQ-.YYYY.-',
                'reqd': 1
            },
            {
                'fieldname': 'department',
                'label': 'Department',
                'fieldtype': 'Link',
                'options': 'Department',
                'reqd': 1
            },
            {
                'fieldname': 'request_date',
                'label': 'Request Date',
                'fieldtype': 'Date',
                'default': 'Today',
                'reqd': 1
            },
            {
                'fieldname': 'requested_by',
                'label': 'Requested By',
                'fieldtype': 'Link',
                'options': 'Employee',
                'reqd': 1
            },
            {
                'fieldname': 'column_break_1',
                'fieldtype': 'Column Break'
            },
            {
                'fieldname': 'urgency',
                'label': 'Urgency',
                'fieldtype': 'Select',
                'options': 'Low\\nMedium\\nHigh\\nUrgent',
                'default': 'Medium'
            },
            {
                'fieldname': 'status',
                'label': 'Status',
                'fieldtype': 'Select',
                'options': 'Pending\\nApproved\\nRejected\\nPartially Approved',
                'default': 'Pending'
            },
            {
                'fieldname': 'section_break_1',
                'label': 'Request Details',
                'fieldtype': 'Section Break'
            },
            {
                'fieldname': 'purpose',
                'label': 'Purpose',
                'fieldtype': 'Text',
                'reqd': 1
            },
            {
                'fieldname': 'requested_amount',
                'label': 'Requested Amount',
                'fieldtype': 'Currency',
                'reqd': 1
            },
            {
                'fieldname': 'justification',
                'label': 'Justification',
                'fieldtype': 'Text Editor'
            }
        ],
        'permissions': [
            {
                'role': 'Budget Manager',
                'permlevel': 0,
                'read': 1,
                'write': 1,
                'create': 1,
                'submit': 1,
                'cancel': 1
            },
            {
                'role': 'HR Manager',
                'permlevel': 0, 
                'read': 1,
                'write': 1,
                'create': 1,
                'submit': 1
            },
            {
                'role': 'HR User',
                'permlevel': 0,
                'read': 1,
                'write': 1,
                'create': 1
            }
        ]
    })
    doc.insert(ignore_permissions=True)
    print('✅ สร้าง Budget Request DocType แล้ว')

frappe.db.commit()
print('🎉 Budget Management System สร้างสำเร็จทั้งหมด!')

exit
\"
"

echo "✅ Budget Management System สร้างสำเร็จ!"
echo ""
echo "📋 DocTypes ที่สร้างแล้ว:"
echo "   • Department Budget - งบประมาณแผนก" 
echo "   • Department Budget Item - รายการงบประมาณ"
echo "   • Budget Request - คำขอใช้งบประมาณ"
echo ""
echo "👥 Roles ที่มีสิทธิ์:"
echo "   • Budget Manager - สิทธิ์เต็ม"
echo "   • HR Manager - อ่าน/เขียน/สร้าง"
echo "   • HR User - อ่าน/เขียน/สร้าง (Budget Request)"
echo ""
echo "📝 ขั้นตอนต่อไป: Import ข้อมูลพื้นฐาน"
echo "    คำสั่ง: ./import-basic-data.sh"
