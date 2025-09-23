# ERPNext v15 Production Deployment with Custom Data

## 🎯 Overview
This repository contains a production-ready ERPNext v15 setup with:
- **All customizations included** (custom doctypes, modified workflows, etc.)
- **Database backup with production data** 
- **Automated restore process**
- **5 Custom Apps**: ERPNext, HRMS, CRM, Lending, Utility Billing
- **Updated versions**: Frappe v15.82.1, ERPNext v15.79.0, HRMS v15.50.0

## 🚀 Quick Production Deployment

### Prerequisites
- Docker and Docker Compose installed
- At least 4GB RAM, 20GB storage
- Domain name or IP address

### Method 1: Automated Deployment (Recommended)
```bash
# 1. Clone repository
git clone https://github.com/artweerasak/erpnext_tv5smart_admin.git
cd erpnext_tv5smart_admin

# 2. Run automated deployment
./deploy-production.sh
```

### Method 2: Manual Deployment
```bash
# 1. Clone repository
git clone https://github.com/artweerasak/erpnext_tv5smart_admin.git
cd erpnext_tv5smart_admin

# 2. Configure environment
cp .env.production .env
nano .env  # Edit SITE_NAME, passwords, email settings

# 3. Start database services
docker-compose -f docker-compose.production.yaml up -d db redis-cache redis-queue

# 4. Wait for services to be ready
sleep 30

# 5. Restore custom data
docker-compose -f docker-compose.production.yaml --profile restore up restore-data

# 6. Start all services
docker-compose -f docker-compose.production.yaml up -d
```

## 📊 What's Included in Custom Data

### Custom DocTypes & Modifications
- All custom fields and forms
- Modified workflows and permissions
- Custom reports and dashboards
- User-defined data and settings

### Database Backup Contents
- **Database**: `20250924_002518-frontend-database.sql.gz` (2.4MB)
- **Files**: `20250924_002518-frontend-files.tar` (10KB)
- **Private Files**: `20250924_002518-frontend-private-files.tar` (1.5MB)
- **Site Config**: `20250924_002518-frontend-site_config_backup.json`

### Applications Included
1. **Frappe Framework** v15.82.1 - Core framework
2. **ERPNext** v15.79.0 - ERP functionality  
3. **HRMS** v15.50.0 - Human resources
4. **CRM** v1.52.11 - Customer management
5. **Lending** v0.0.1 - Loan management
6. **Utility Billing** v0.0.1 - Utility billing

## ⚙️ Environment Configuration

### Required Settings in `.env`
```bash
# Site Configuration
SITE_NAME=your-domain.com  # Your domain or IP
ADMIN_PASSWORD=your_admin_password

# Database
DB_PASSWORD=your_database_password
DB_ROOT_PASSWORD=your_root_password

# Ports
HTTP_PUBLISH_PORT=80
HTTPS_PUBLISH_PORT=443

# Email (for notifications)
MAIL_HOST=smtp.gmail.com
MAIL_USERNAME=your@email.com
MAIL_PASSWORD=your_email_password
```

## 🔄 Deployment Process

### What Happens During Deployment
1. **Database Setup** - MariaDB initialized
2. **Site Creation** - New ERPNext site created
3. **Apps Installation** - All 5 apps installed automatically
4. **Data Restore** - Custom data and configurations restored
5. **Services Start** - All services running and ready

### Restore Process Details
```bash
# The restore service automatically:
1. Creates new site with your domain name
2. Installs all required apps (erpnext, hrms, crm, lending, utility_billing)
3. Restores database from backup
4. Restores files and private files
5. Sets admin password
6. Applies all customizations
```

## 🛡️ Production Security

### Database Security
- Strong passwords required
- Database not exposed to public (only internal network)
- Regular backup rotation recommended

### Application Security  
- Admin password must be strong
- Enable HTTPS in production
- Configure firewall (allow only 80, 443, 22)

### File Security
- Private files protected
- Proper file permissions set
- Volume mapping for persistence

## 📈 Monitoring and Maintenance

### Check Service Status
```bash
docker-compose -f docker-compose.production.yaml ps
```

### View Logs
```bash
# All services
docker-compose -f docker-compose.production.yaml logs

# Specific service
docker-compose -f docker-compose.production.yaml logs backend
```

### Create New Backup
```bash
docker-compose -f docker-compose.production.yaml exec backend \
  bench --site your-site-name backup --with-files
```

### Update System
```bash
# Pull latest changes
git pull origin main

# Rebuild and restart
docker-compose -f docker-compose.production.yaml down
docker-compose -f docker-compose.production.yaml up -d --build
```

## 🔧 Troubleshooting

### Common Issues

1. **Port already in use**
   ```bash
   # Change ports in .env
   HTTP_PUBLISH_PORT=8080
   ```

2. **Database connection failed**
   ```bash
   # Check database logs
   docker-compose -f docker-compose.production.yaml logs db
   
   # Reset if needed
   docker-compose -f docker-compose.production.yaml down -v
   docker-compose -f docker-compose.production.yaml up -d
   ```

3. **Restore failed**
   ```bash
   # Manual restore
   docker-compose -f docker-compose.production.yaml exec backend \
     bench --site your-site restore /home/frappe/backups/20250924_002518-frontend-database.sql.gz --with-private-files --with-public-files
   ```

4. **Services not starting**
   ```bash
   # Check logs for errors
   docker-compose -f docker-compose.production.yaml logs
   
   # Restart specific service
   docker-compose -f docker-compose.production.yaml restart backend
   ```

### Performance Tuning

For production with higher load:
```bash
# Scale worker services
docker-compose -f docker-compose.production.yaml up -d --scale queue-default=2 --scale queue-short=2
```

## 📋 Production Checklist

- [ ] Configure `.env` with production settings
- [ ] Set strong passwords for all accounts
- [ ] Configure domain name and DNS
- [ ] Set up SSL/HTTPS certificates
- [ ] Configure email settings for notifications
- [ ] Set up firewall rules
- [ ] Configure backup strategy
- [ ] Test restore procedures
- [ ] Set up monitoring and alerting
- [ ] Document admin procedures

## 📞 Support

### Getting Help
- Check logs for error messages
- ERPNext Community: https://discuss.erpnext.com
- Frappe Documentation: https://docs.frappe.io

### Repository Issues
- Create issues in GitHub repository
- Include logs and error messages
- Describe steps to reproduce

## 🔄 Backup Strategy

### Automated Backups
```bash
# Add to crontab for daily backups
0 2 * * * cd /path/to/erpnext_tv5smart_admin && docker-compose -f docker-compose.production.yaml exec -T backend bench --site your-site backup --with-files
```

### Manual Backup
```bash
# Create backup
docker-compose -f docker-compose.production.yaml exec backend \
  bench --site your-site backup --with-files --backup-path /home/frappe/backups

# Copy backup files from container
docker cp container-name:/home/frappe/backups ./local-backups/
```

---

## 🎉 Ready for Production!

This setup provides:
✅ **Complete ERPNext installation** with all customizations
✅ **Automated deployment** process
✅ **Production-ready** configuration
✅ **Custom data preserved** and restored automatically
✅ **Scalable architecture** for growth
✅ **Easy maintenance** and updates

Your ERPNext system with all customizations will be ready for production use in minutes!