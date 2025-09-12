#!/bin/bash

# 💰 Script สำหรับสร้าง Budget ตัวอย่าง
# สร้างงบประมาณแผนกและคำขออนุมัติตัวอย่าง

set -e

echo "💰 เริ่มสร้าง Budget ตัวอย่าง..."

docker compose -f docker-compose-fixed.yaml exec backend bash -c "
cd /home/frappe/frappe-bench

bench --site frontend console <<< \"
import frappe
import json
from datetime import datetime, date

# ตรวจสอบ Fiscal Year
current_year = datetime.now().year
fiscal_year_name = f'{current_year}-{current_year + 1}'

if not frappe.db.exists('Fiscal Year', fiscal_year_name):
    fiscal_year = frappe.get_doc({
        'doctype': 'Fiscal Year',
        'year': fiscal_year_name,
        'year_start_date': f'{current_year}-01-01',
        'year_end_date': f'{current_year}-12-31'
    })
    fiscal_year.insert(ignore_permissions=True)
    print(f'✅ สร้าง Fiscal Year: {fiscal_year_name}')

# สร้าง Department Budget ตัวอย่าง
department_budgets = [
    {
        'department': 'Human Resources',
        'total_budget': 2500000,
        'budget_items': [
            {'category': 'Personnel', 'description': 'เงินเดือนและค่าตอบแทน', 'requested': 1500000, 'approved': 1400000},
            {'category': 'Training', 'description': 'อบรมพัฒนาบุคลากร', 'requested': 300000, 'approved': 280000},
            {'category': 'Operating', 'description': 'ค่าใช้จ่ายในการดำเนินงาน', 'requested': 500000, 'approved': 450000},
            {'category': 'Other', 'description': 'ค่าใช้จ่ายอื่นๆ', 'requested': 200000, 'approved': 180000}
        ]
    },
    {
        'department': 'IT Department',
        'total_budget': 3200000,
        'budget_items': [
            {'category': 'Personnel', 'description': 'เงินเดือนทีม IT', 'requested': 1800000, 'approved': 1750000},
            {'category': 'Capital', 'description': 'จัดซื้อฮาร์ดแวร์และซอฟต์แวร์', 'requested': 800000, 'approved': 750000},
            {'category': 'Operating', 'description': 'ค่าบำรุงรักษาระบบ', 'requested': 400000, 'approved': 380000},
            {'category': 'Training', 'description': 'อบรมเทคโนโลยีใหม่', 'requested': 200000, 'approved': 180000}
        ]
    },
    {
        'department': 'Finance',
        'total_budget': 1800000,
        'budget_items': [
            {'category': 'Personnel', 'description': 'เงินเดือนทีมการเงิน', 'requested': 1200000, 'approved': 1150000},
            {'category': 'Operating', 'description': 'ค่าใช้จ่ายสำนักงาน', 'requested': 300000, 'approved': 280000},
            {'category': 'Other', 'description': 'ค่าธรรมเนียมและค่าบริการ', 'requested': 300000, 'approved': 270000}
        ]
    }
]

for budget_data in department_budgets:
    budget_name = f'DEPT-BUDGET-{current_year}-{budget_data[\"department\"].replace(\" \", \"-\")}'
    
    if not frappe.db.exists('Department Budget', budget_name):
        # สร้าง Department Budget
        budget = frappe.get_doc({
            'doctype': 'Department Budget',
            'naming_series': 'DEPT-BUDGET-.YYYY.-',
            'department': budget_data['department'],
            'fiscal_year': fiscal_year_name,
            'budget_status': 'Approved',
            'approved_amount': sum(item['approved'] for item in budget_data['budget_items']),
            'approved_by': 'Administrator',
            'approval_date': date.today(),
            'remarks': f'งบประมาณประจำปี {current_year} สำหรับแผนก {budget_data[\"department\"]}',
            'budget_items': []
        })
        
        # เพิ่ม Budget Items
        for item in budget_data['budget_items']:
            budget.append('budget_items', {
                'budget_category': item['category'],
                'description': item['description'],
                'requested_amount': item['requested'],
                'approved_amount': item['approved'],
                'actual_spent': 0,
                'variance': item['approved']
            })
        
        budget.insert(ignore_permissions=True)
        budget.submit()
        print(f'✅ สร้าง Department Budget สำหรับ {budget_data[\"department\"]}: {budget.total_budget:,.0f} บาท')

# สร้าง Budget Request ตัวอย่าง
budget_requests = [
    {
        'department': 'Human Resources',
        'purpose': 'จัดซื้อเครื่องปริ้นเตอร์สำหรับสำนักงาน HR',
        'requested_amount': 25000,
        'urgency': 'Medium',
        'requested_by': 'EMP001',
        'justification': 'เครื่องปริ้นเตอร์เก่าชำรุด ต้องการเครื่องใหม่สำหรับการพิมพ์เอกสาร HR'
    },
    {
        'department': 'IT Department', 
        'purpose': 'อบรมเจ้าหน้าที่ IT เรื่อง Cloud Computing',
        'requested_amount': 45000,
        'urgency': 'High',
        'requested_by': 'EMP003',
        'justification': 'จำเป็นต้องเพิ่มความรู้เรื่อง Cloud เพื่อรองรับการขยายธุรกิจ'
    },
    {
        'department': 'Finance',
        'purpose': 'จ้างที่ปรึกษาทางการเงินสำหรับโครงการพิเศษ',
        'requested_amount': 80000,
        'urgency': 'Low',
        'requested_by': 'EMP002',
        'justification': 'ต้องการผู้เชี่ยวชาญช่วยวิเคราะห์ผลกระทบทางการเงินของโครงการใหม่'
    }
]

for req_data in budget_requests:
    request_name = f'BUDGET-REQ-{current_year}-{req_data[\"department\"].replace(\" \", \"-\")[:3]}'
    
    if not frappe.db.exists('Budget Request', {'department': req_data['department'], 'purpose': req_data['purpose']}):
        budget_request = frappe.get_doc({
            'doctype': 'Budget Request',
            'naming_series': 'BUDGET-REQ-.YYYY.-',
            'department': req_data['department'],
            'request_date': date.today(),
            'requested_by': req_data['requested_by'],
            'urgency': req_data['urgency'],
            'status': 'Pending',
            'purpose': req_data['purpose'],
            'requested_amount': req_data['requested_amount'],
            'justification': req_data['justification']
        })
        
        budget_request.insert(ignore_permissions=True)
        print(f'✅ สร้าง Budget Request: {req_data[\"purpose\"]} - {req_data[\"requested_amount\"]:,.0f} บาท')

frappe.db.commit()
print('🎉 สร้าง Budget ตัวอย่างสำเร็จทั้งหมด!')

exit
\"
"

echo "✅ สร้าง Budget ตัวอย่างสำเร็จ!"
echo ""
echo "💰 Department Budgets ที่สร้างแล้ว:"
echo "   • Human Resources - 2,310,000 บาท (อนุมัติแล้ว)"
echo "   • IT Department - 3,060,000 บาท (อนุมัติแล้ว)"
echo "   • Finance - 1,700,000 บาท (อนุมัติแล้ว)"
echo ""
echo "📝 Budget Requests ที่สร้างแล้ว:"
echo "   • เครื่องปริ้นเตอร์ HR - 25,000 บาท (รอพิจารณา)"
echo "   • อบรม Cloud Computing - 45,000 บาท (ด่วน)"
echo "   • ที่ปรึกษาการเงิน - 80,000 บาท (ไม่ด่วน)"
echo ""
echo "🎯 ระบบ Budget Management พร้อมใช้งานแล้ว!"
echo "    เข้าใช้งานที่: http://localhost:8080"
