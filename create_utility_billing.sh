#!/bin/bash

echo "🔧 Creating Complete Utility Billing App..."

# สร้าง utility billing app ใหม่
docker compose exec backend bench new-app utility_billing

# สร้าง DocTypes สำหรับ Utility Billing
echo "📋 Creating DocTypes..."

# สร้าง Utility Customer DocType
docker compose exec backend bench --site frontend make-doctype "Utility Customer" <<EOF
{
    "name": "Utility Customer",
    "module": "Utility Billing",
    "fields": [
        {"fieldname": "customer_id", "fieldtype": "Data", "label": "Customer ID", "reqd": 1},
        {"fieldname": "customer_name", "fieldtype": "Data", "label": "Customer Name", "reqd": 1},
        {"fieldname": "address", "fieldtype": "Text", "label": "Address"},
        {"fieldname": "phone", "fieldtype": "Data", "label": "Phone"},
        {"fieldname": "email", "fieldtype": "Data", "label": "Email"},
        {"fieldname": "meter_number", "fieldtype": "Data", "label": "Meter Number", "reqd": 1}
    ]
}
EOF

# สร้าง Utility Bill DocType
docker compose exec backend bench --site frontend make-doctype "Utility Bill" <<EOF
{
    "name": "Utility Bill",
    "module": "Utility Billing",
    "fields": [
        {"fieldname": "customer", "fieldtype": "Link", "label": "Customer", "options": "Utility Customer", "reqd": 1},
        {"fieldname": "bill_period", "fieldtype": "Data", "label": "Bill Period", "reqd": 1},
        {"fieldname": "meter_reading_start", "fieldtype": "Float", "label": "Meter Reading Start"},
        {"fieldname": "meter_reading_end", "fieldtype": "Float", "label": "Meter Reading End"},
        {"fieldname": "units_consumed", "fieldtype": "Float", "label": "Units Consumed"},
        {"fieldname": "rate_per_unit", "fieldtype": "Currency", "label": "Rate per Unit"},
        {"fieldname": "amount", "fieldtype": "Currency", "label": "Amount"},
        {"fieldname": "due_date", "fieldtype": "Date", "label": "Due Date"}
    ]
}
EOF

# สร้าง Utility Payment DocType
docker compose exec backend bench --site frontend make-doctype "Utility Payment" <<EOF
{
    "name": "Utility Payment",
    "module": "Utility Billing",
    "fields": [
        {"fieldname": "bill", "fieldtype": "Link", "label": "Utility Bill", "options": "Utility Bill", "reqd": 1},
        {"fieldname": "customer", "fieldtype": "Link", "label": "Customer", "options": "Utility Customer", "reqd": 1},
        {"fieldname": "payment_date", "fieldtype": "Date", "label": "Payment Date", "reqd": 1},
        {"fieldname": "amount_paid", "fieldtype": "Currency", "label": "Amount Paid", "reqd": 1},
        {"fieldname": "payment_method", "fieldtype": "Select", "label": "Payment Method", "options": "Cash\nBank Transfer\nCredit Card\nOnline"}
    ]
}
EOF

echo "✅ Utility Billing App created successfully!"
echo "🚀 Installing the app..."

# ติดตั้ง app
docker compose exec backend bench --site frontend install-app utility_billing

echo "🎉 Utility Billing App installed with DocTypes!"
