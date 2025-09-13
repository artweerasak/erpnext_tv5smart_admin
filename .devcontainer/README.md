# ERPNext Development Container

Development Container สำหรับ ERPNext พร้อม Apps ครบชุด

## 📦 Applications
- Frappe Framework
- ERPNext 
- HRMS
- CRM
- Lending
- Utility Billing

## 🚀 การใช้งาน

1. เปิด VS Code ใน folder นี้
2. `Ctrl+Shift+P` → "Dev Containers: Reopen in Container" 
3. รอให้ container พร้อม
4. เข้าใช้งาน: http://localhost:8081
5. Login: Administrator / admin

## 📁 สำคัญ
- `devcontainer.json` - การตั้งค่า Dev Container หลัก
- `dev-setup.sh` - Helper scripts สำหรับ development

ระบบจะทำงานในแบบ multi-container ผ่าน Docker Compose