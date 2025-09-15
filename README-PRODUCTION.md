# ERPNext v15 with Custom Apps - Production Setup

## Overview
This is a customized ERPNext v15 installation with the following apps:
- **ERPNext** v15.78.1 - Core ERP functionality  
- **HRMS** v15.49.2 - Human Resource Management
- **CRM** v1.52.11 - Customer Relationship Management
- **Lending** v0.0.1 - Loan Management
- **Utility Billing** v0.0.1 - Utility billing management

## Architecture
- Based on official [frappe-docker](https://github.com/frappe/frappe_docker)
- Custom Docker image: `tv5smart/erpnext-custom:v15`
- Production-ready with proper volume mapping and service separation

## Quick Start for Production Server

### Prerequisites
- Docker and Docker Compose installed
- At least 4GB RAM, 20GB storage
- Domain name pointed to server (optional, can use IP)

### 1. Clone Repository
```bash
git clone https://github.com/artweerasak/erpnext_tv5smart_admin.git
cd erpnext_tv5smart_admin
```

### 2. Configure Environment
```bash
# Copy example environment file
cp example.env .env

# Edit .env file with your settings
nano .env
```

**Important .env settings for production:**
```bash
# Database
DB_PASSWORD=your_strong_password_here
DB_ROOT_PASSWORD=your_strong_root_password_here

# Site
SITE_NAME=your-domain.com  # or your IP address
ADMIN_PASSWORD=your_admin_password_here

# Ports (change if needed)
HTTP_PUBLISH_PORT=80
HTTPS_PUBLISH_PORT=443

# Email (configure for production)
MAIL_HOST=your.smtp.server.com
MAIL_PORT=587
MAIL_USE_SSL=true
MAIL_USERNAME=your@email.com
MAIL_PASSWORD=your_email_password
```

### 3. Start Services
```bash
# Start database and cache first
docker-compose --profile=backend up -d

# Wait for services to be ready
sleep 30

# Start all services
docker-compose up -d
```

### 4. Create Site
```bash
# Create your site with custom apps
docker-compose exec backend bench --site $SITE_NAME install-app erpnext
docker-compose exec backend bench --site $SITE_NAME install-app hrms  
docker-compose exec backend bench --site $SITE_NAME install-app crm
docker-compose exec backend bench --site $SITE_NAME install-app lending
docker-compose exec backend bench --site $SITE_NAME install-app utility_billing
```

### 5. Setup Admin User
```bash
# Create admin user
docker-compose exec backend bench --site $SITE_NAME set-admin-password $ADMIN_PASSWORD
```

## Alternative: Using Pre-built Setup

### Option A: Use docker-compose-custom.yaml (Recommended)
This uses the pre-built custom image with all apps included:

```bash
# Start with custom image
docker-compose -f docker-compose-custom.yaml up -d

# Site will be created automatically with all apps installed
```

### Option B: Build Custom Image Yourself
If you want to build the custom image on your server:

```bash
# Build custom image with all apps
docker build \
  --build-arg=APPS_JSON_BASE64="$(base64 -w 0 apps.json)" \
  --tag=tv5smart/erpnext-custom:v15 \
  --file=images/custom/Containerfile .

# Then use docker-compose-custom.yaml
docker-compose -f docker-compose-custom.yaml up -d
```

## SSL/HTTPS Setup

### Using Traefik (Recommended)
```bash
# Copy SSL compose override
cp overrides/compose.traefik-ssl.yaml docker-compose.override.yaml

# Update your .env with domain
echo "SITE_NAME=yourdomain.com" >> .env

# Start with SSL
docker-compose up -d
```

### Using Let's Encrypt
```bash
# Copy SSL compose override  
cp overrides/compose.custom-domain-ssl.yaml docker-compose.override.yaml

# Update domain in .env
echo "SITE_NAME=yourdomain.com" >> .env
echo "EMAIL=your@email.com" >> .env

# Start services
docker-compose up -d
```

## Monitoring and Logs

### Check Service Status
```bash
docker-compose ps
```

### View Logs
```bash
# All services
docker-compose logs

# Specific service
docker-compose logs backend
docker-compose logs frontend
```

### Monitor Performance
```bash
# System resources
docker stats

# App logs
docker-compose exec backend tail -f /home/frappe/frappe-bench/logs/worker.log
```

## Backup and Restore

### Create Backup
```bash
# Create site backup
docker-compose exec backend bench --site $SITE_NAME backup --with-files

# Backup will be in sites/[site-name]/private/backups/
```

### Restore from Backup
```bash
# Copy backup file to container
docker cp backup-file.sql.gz container_name:/home/frappe/frappe-bench/sites/[site-name]/private/backups/

# Restore
docker-compose exec backend bench --site $SITE_NAME restore backup-file.sql.gz --with-private-files --with-public-files
```

## Troubleshooting

### Common Issues

1. **Port already in use**
   ```bash
   # Change ports in .env
   HTTP_PUBLISH_PORT=8080
   HTTPS_PUBLISH_PORT=8443
   ```

2. **Database connection issues**
   ```bash
   # Reset database
   docker-compose down
   docker volume rm erpnext_tv5smart_admin_db-data
   docker-compose up -d
   ```

3. **Memory issues**
   ```bash
   # Add swap space
   sudo fallocate -l 2G /swapfile
   sudo chmod 600 /swapfile
   sudo mkswap /swapfile
   sudo swapon /swapfile
   ```

### Getting Help
- Check logs: `docker-compose logs`
- ERPNext Forum: https://discuss.erpnext.com
- Frappe Docker Issues: https://github.com/frappe/frappe_docker/issues

## Production Checklist

- [ ] Configure proper .env with strong passwords
- [ ] Set up SSL/HTTPS
- [ ] Configure email settings
- [ ] Set up regular backups
- [ ] Configure firewall (only allow 80, 443, 22)
- [ ] Set up monitoring and alerts
- [ ] Test backup and restore procedures
- [ ] Configure log rotation
- [ ] Set up domain name and DNS

## Apps Information

### ERPNext (v15.78.1)
- Complete ERP solution
- Manufacturing, Accounting, Sales, Purchase, HR
- Repository: https://github.com/frappe/erpnext

### HRMS (v15.49.2) 
- Human Resource Management System
- Payroll, Leave, Attendance, Employee lifecycle
- Repository: https://github.com/frappe/hrms

### CRM (v1.52.11)
- Customer Relationship Management
- Lead management, Opportunity tracking
- Repository: https://github.com/frappe/crm

### Lending (v0.0.1)
- Loan Management System
- Loan applications, disbursements, repayments
- Repository: https://github.com/frappe/lending

### Utility Billing (v0.0.1)
- Utility billing management
- Water, electricity, gas billing
- Repository: https://github.com/navariltd/utility-billing

## Contact

For support with this specific setup, please create an issue in the repository or contact the administrator.