# 🚀 ERPNext Production Deployment Guide

คู่มือการย้ายระบบจาก Development (WSL) ไปยัง Production Server

## 📋 สิ่งที่ต้องเตรียมก่อน Deploy

### 1. 🔧 Infrastructure Requirements

**Server Specifications (แนะนำ):**
- **CPU**: 4+ cores
- **RAM**: 8GB+ (16GB สำหรับการใช้งานหนัก)
- **Storage**: 100GB+ SSD
- **OS**: Ubuntu 20.04/22.04 LTS หรือ CentOS 8+
- **Network**: Static IP, Domain name

**Software Requirements:**
- Docker & Docker Compose
- Nginx (reverse proxy)
- SSL Certificate (Let's Encrypt)
- Backup solution

### 2. 📊 Database & Data Migration

```bash
# Export database from current system
docker compose exec backend bench --site frontend backup --with-files

# Files จะอยู่ที่
docker compose exec backend ls /home/frappe/frappe-bench/sites/frontend/private/backups/
```

### 3. 🔒 Security Considerations

**Environment Variables:**
- เปลี่ยน default passwords
- Generate strong secrets
- Configure proper database credentials

## 🎯 Production Deployment Options

### Option 1: Docker Compose (แนะนำ)

**ข้อดี:**
- ✅ Easy to deploy และ maintain
- ✅ Consistent environment
- ✅ Easy backup & restore
- ✅ Scalable

**การ Deploy:**

1. **Setup Production Server**
```bash
# Install Docker & Docker Compose
curl -fsSL https://get.docker.com -o get-docker.sh
sh get-docker.sh
sudo apt install docker-compose-plugin

# Clone repository
git clone https://github.com/artweerasak/erpnext_tv5smart_admin.git
cd erpnext_tv5smart_admin
```

2. **Configure Production Environment**
```bash
# Copy และแก้ไข .env file
cp .env .env.production
nano .env.production
```

3. **Deploy Services**
```bash
# Start production services
docker compose -f compose.yaml --env-file .env.production up -d

# หรือใช้ production compose file
docker compose -f docker-compose-production.yml up -d
```

### Option 2: Managed Hosting Services

**Frappe Cloud (แนะนำสำหรับ SME):**
- ✅ Fully managed
- ✅ Auto scaling
- ✅ Built-in backups
- ✅ SSL certificates
- ❌ Higher cost

**DigitalOcean/AWS/GCP:**
- ✅ Full control
- ✅ Cost effective
- ❌ Requires DevOps knowledge

## 🔧 Production Configuration

### 1. Environment Configuration

**สร้าง `.env.production`:**
```bash
# Database
DB_HOST=db
DB_ROOT_PASSWORD=<STRONG_PASSWORD>
MYSQL_ROOT_PASSWORD=<STRONG_PASSWORD>

# Redis
REDIS_CACHE=redis-cache:6379
REDIS_QUEUE=redis-queue:6379

# ERPNext
ADMIN_PASSWORD=<STRONG_ADMIN_PASSWORD>
SITE_NAME=<YOUR_DOMAIN>
FRAPPE_ENV=production

# Email (สำคัญ!)
MAIL_SERVER=smtp.gmail.com
MAIL_PORT=587
MAIL_LOGIN=your-email@domain.com
MAIL_PASSWORD=<APP_PASSWORD>

# Backup
BACKUP_RETENTION=7
```

### 2. Reverse Proxy (Nginx)

**สร้าง `nginx.conf`:**
```nginx
server {
    listen 80;
    server_name your-domain.com;
    return 301 https://$server_name$request_uri;
}

server {
    listen 443 ssl http2;
    server_name your-domain.com;

    ssl_certificate /etc/letsencrypt/live/your-domain.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/your-domain.com/privkey.pem;

    location / {
        proxy_pass http://localhost:8081;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

### 3. SSL Certificate

```bash
# Install Certbot
sudo apt install certbot python3-certbot-nginx

# Get SSL certificate
sudo certbot --nginx -d your-domain.com

# Auto renewal
sudo crontab -e
# Add: 0 12 * * * /usr/bin/certbot renew --quiet
```

## 📦 Data Migration Process

### 1. Export from Development

```bash
# สร้าง backup ครบถ้วน
docker compose exec backend bench --site frontend backup --with-files

# Copy backup files ออกมา
docker compose cp backend:/home/frappe/frappe-bench/sites/frontend/private/backups/ ./backups/

# Export apps configuration
docker compose exec backend bench --site frontend list-apps > apps.txt
```

### 2. Import to Production

```bash
# 1. Setup clean installation
docker compose up -d

# 2. Create site (without apps first)
docker compose exec backend bench new-site <DOMAIN> --admin-password <PASSWORD>

# 3. Install apps
docker compose exec backend bench --site <DOMAIN> install-app erpnext
docker compose exec backend bench --site <DOMAIN> install-app hrms
docker compose exec backend bench --site <DOMAIN> install-app crm
docker compose exec backend bench --site <DOMAIN> install-app lending
docker compose exec backend bench --site <DOMAIN> install-app utility_billing

# 4. Restore backup
docker compose exec backend bench --site <DOMAIN> restore /path/to/backup.sql.gz --with-private-files /path/to/files.tar
```

## 🔄 Backup & Maintenance Strategy

### 1. Automated Backups

**สร้าง backup script:**
```bash
#!/bin/bash
# backup.sh
DATE=$(date +%Y%m%d_%H%M%S)
BACKUP_DIR="/opt/erpnext-backups"

# Database backup
docker compose exec backend bench --site frontend backup --with-files

# Copy to backup directory
docker compose cp backend:/home/frappe/frappe-bench/sites/frontend/private/backups/. $BACKUP_DIR/$DATE/

# Upload to cloud storage (optional)
# aws s3 sync $BACKUP_DIR s3://your-backup-bucket/
```

**Cron job:**
```bash
# Daily backup at 2 AM
0 2 * * * /opt/scripts/backup.sh
```

### 2. Monitoring & Logging

**Health checks:**
```bash
# สร้าง monitoring script
#!/bin/bash
# monitor.sh

# Check services
docker compose ps

# Check disk space
df -h

# Check logs
docker compose logs --tail=100 backend | grep -i error
```

## 🚨 Production Checklist

### Pre-deployment
- [ ] Server specs meet requirements
- [ ] Domain name configured
- [ ] SSL certificate ready
- [ ] Environment variables configured
- [ ] Database backup created
- [ ] Apps compatibility tested

### During deployment
- [ ] Services started successfully
- [ ] Database restored properly
- [ ] All apps installed and working
- [ ] SSL certificate applied
- [ ] Email configuration tested
- [ ] User access verified

### Post-deployment
- [ ] Backup automation setup
- [ ] Monitoring configured
- [ ] Documentation updated
- [ ] Team training completed
- [ ] Support contacts established

## 🔧 Troubleshooting Common Issues

### 1. Port Conflicts
```bash
# Check what's using port 8081
sudo netstat -tlnp | grep 8081

# Change port in compose.yaml if needed
```

### 2. Permission Issues
```bash
# Fix file permissions
sudo chown -R frappe:frappe /opt/erpnext-data
```

### 3. Memory Issues
```bash
# Increase swap space
sudo fallocate -l 4G /swapfile
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile
```

### 4. Database Connection Issues
```bash
# Check database logs
docker compose logs db

# Test connection
docker compose exec backend bench --site frontend console
```

## 📞 Support & Resources

- **Official Documentation**: https://frappeframework.com/docs
- **Community Forum**: https://discuss.frappe.io
- **ERPNext Documentation**: https://docs.erpnext.com

---

**💡 คำแนะนำ:** เริ่มต้นด้วย staging server ก่อน deploy production เพื่อทดสอบทุกอย่างให้แน่ใจ
