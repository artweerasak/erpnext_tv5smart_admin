#!/bin/bash
set -e

echo "Clearing pending data imports..."

# Execute through Frappe console
cd /home/frappe/frappe-bench

python << 'EOF'
import frappe
from frappe.utils.data import now

# Initialize Frappe
frappe.init(site="frontend")
frappe.connect()

# Get all pending Data Import records
pending_imports = frappe.get_all(
    "Data Import", 
    filters={"status": "Pending"},
    fields=["name", "doctype", "import_file"]
)

print(f"Found {len(pending_imports)} pending imports")

for imp in pending_imports:
    try:
        # Delete the pending import record
        frappe.delete_doc("Data Import", imp.name, force=True)
        print(f"Deleted pending import: {imp.name}")
    except Exception as e:
        print(f"Error deleting {imp.name}: {str(e)}")

frappe.db.commit()
print("All pending imports cleared successfully!")
frappe.destroy()
EOF
