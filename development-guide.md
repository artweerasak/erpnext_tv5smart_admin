# ERPNext Development Environment with HRMS & Lending

🚀 Complete ERPNext development setup with HRMS (Human Resource Management) and Lending (Loan Management) applications pre-installed.

## 📦 Included Applications

- **ERPNext**: Core ERP functionality
- **HRMS**: Human Resource Management System
- **Lending**: Loan Management System

## 🏃‍♂️ Quick Start

### Option 1: Using VS Code Dev Container (Recommended)

1. Open this folder in VS Code
2. Click "Reopen in Container" when prompted (or use Command Palette: `Dev Containers: Reopen in Container`)
3. Wait for the container to build and start
4. Access ERPNext at http://localhost:8080

### Option 2: Using Docker Compose

```bash
# Start the development environment
./start-dev.sh

# Or manually
docker compose -f docker-compose-hrms.yaml up -d
```

## 🔑 Default Credentials

- **Username**: `Administrator`
- **Password**: `admin`
- **Site**: `frontend`

## 🌐 Access URLs

- **Frontend (ERPNext UI)**: http://localhost:8080
- **Backend (API)**: http://localhost:8000
- **Database**: localhost:3306

## 📊 Useful Commands

### Docker Compose Commands
```bash
# View service status
docker compose -f docker-compose-hrms.yaml ps

# View logs
docker compose -f docker-compose-hrms.yaml logs -f

# Stop all services
docker compose -f docker-compose-hrms.yaml down

# Restart services
docker compose -f docker-compose-hrms.yaml restart

# Rebuild and start
docker compose -f docker-compose-hrms.yaml up --build -d
```

### Bench Commands (inside container)
```bash
# Access the backend container
docker compose -f docker-compose-hrms.yaml exec backend bash

# Once inside the container:
bench --site frontend migrate
bench --site frontend clear-cache
bench --site frontend install-app [app-name]
bench --site frontend console
```

## 🔧 Development Workflow

1. **Start Environment**: Use VS Code Dev Container or run `./start-dev.sh`
2. **Access ERPNext**: Open http://localhost:8080 in your browser
3. **Make Changes**: Edit files in your local workspace
4. **Test Changes**: Refresh browser or restart services as needed

## 📁 Project Structure

```
.
├── .devcontainer/
│   └── devcontainer.json          # VS Code Dev Container configuration
├── docker-compose-hrms.yaml       # Docker Compose with HRMS & Lending
├── start-dev.sh                   # Quick start script
└── development-guide.md            # This file
```

## 🐛 Troubleshooting

### Container Won't Start
```bash
# Check Docker is running
docker info

# Check service logs
docker compose -f docker-compose-hrms.yaml logs

# Remove all containers and start fresh
docker compose -f docker-compose-hrms.yaml down -v
docker compose -f docker-compose-hrms.yaml up -d
```

### Site Not Loading
```bash
# Check if all services are healthy
docker compose -f docker-compose-hrms.yaml ps

# Restart frontend service
docker compose -f docker-compose-hrms.yaml restart frontend

# Check frontend logs
docker compose -f docker-compose-hrms.yaml logs frontend
```

### Database Connection Issues
```bash
# Check database service
docker compose -f docker-compose-hrms.yaml logs db

# Restart database
docker compose -f docker-compose-hrms.yaml restart db
```

## 📚 Additional Resources

- [ERPNext Documentation](https://docs.erpnext.com/)
- [HRMS Documentation](https://docs.erpnext.com/docs/user/manual/en/human-resources)
- [Frappe Framework](https://frappeframework.com/)

## ✨ Features

✅ Pre-configured with ERPNext, HRMS, and Lending applications  
✅ Development-friendly VS Code integration  
✅ Automatic port forwarding  
✅ Hot-reload support  
✅ Database persistence  
✅ Redis caching and queuing  
✅ Easy container management  

Happy coding! 🎉
