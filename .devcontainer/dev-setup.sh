#!/bin/bash

# ERPNext Development Container Setup Script

echo "🚀 Setting up ERPNext Development Environment..."

# Wait for backend container to be ready
echo "⏳ Waiting for ERPNext backend to be ready..."
sleep 10

# Check if we can access the backend container
while ! docker compose exec backend echo "Backend is ready" 2>/dev/null; do
    echo "Waiting for backend container..."
    sleep 5
done

echo "✅ Backend container is ready!"

# Ensure legacy path compatibility
if [ ! -d /home/frappe/frappe-bench ] && [ -d /workspaces/${PWD##*/} ]; then
   echo "🔗 Creating legacy path symlink /home/frappe/frappe-bench -> /workspaces/${PWD##*/}"
   sudo mkdir -p /home/frappe || true
   sudo ln -s /workspaces/${PWD##*/} /home/frappe/frappe-bench || true
fi

# Create convenience scripts
echo "📝 Creating convenience scripts..."

# Create a script to enter ERPNext backend
cat > /workspaces/${PWD##*/}/enter-backend.sh << 'EOF'
#!/bin/bash
echo "🚀 Entering ERPNext Backend Container..."
docker compose exec backend bash -c "cd /home/frappe/frappe-bench && /bin/bash"
EOF

chmod +x /workspaces/${PWD##*/}/enter-backend.sh

# Create development helper script
cat > /workspaces/${PWD##*/}/dev-help.sh << 'EOF'
#!/bin/bash

echo "🛠️  ERPNext Development Helper"
echo "=============================="
echo ""
echo "📦 Docker Commands:"
echo "  docker compose ps                     - View services status"
echo "  docker compose logs -f backend       - View backend logs"
echo "  docker compose exec backend bash     - Enter backend container"
echo ""
echo "🔧 ERPNext Commands (inside backend container):"
echo "  bench start                          - Start development server"
echo "  bench --site frontend console       - Open ERPNext console"
echo "  bench --site frontend clear-cache   - Clear cache"
echo "  bench --site frontend migrate       - Run database migration"
echo "  bench --site frontend list-apps     - List installed apps"
echo ""
echo "🌐 Access URLs:"
echo "  Frontend: http://localhost:8081"
echo "  Backend:  http://localhost:8000"
echo "  Login:    Administrator / admin"
echo ""
echo "💡 Quick Start:"
echo "  1. Run: ./enter-backend.sh"
echo "  2. In backend container: bench start"
echo "  3. Open: http://localhost:8081"
EOF

chmod +x /workspaces/${PWD##*/}/dev-help.sh

# Update bashrc with helpful aliases
cat >> ~/.bashrc << 'EOF'

# ERPNext Development Aliases
alias erp-backend='docker compose exec backend bash -c "cd /home/frappe/frappe-bench && /bin/bash"'
alias erp-logs='docker compose logs -f backend'
alias erp-status='docker compose ps'
alias erp-help='./dev-help.sh'

echo ""
echo "🎉 ERPNext Development Environment Ready!"
echo "💡 Use 'erp-help' to see available commands"
echo "🚀 Use 'erp-backend' to enter ERPNext backend container"
echo ""
EOF

# Create README for the development environment
cat > /workspaces/${PWD##*/}/DEV_README.md << 'EOF'
# ERPNext Development Container

## 🚀 Quick Start

1. **Enter Backend Container**
   ```bash
   ./enter-backend.sh
   # or
   erp-backend
   ```

2. **Start Development Server** (inside backend container)
   ```bash
   bench start
   ```

3. **Access ERPNext**
   - Frontend: http://localhost:8081
   - Login: Administrator / admin

## 🛠️ Development Commands

### Outside Container (Host Terminal)
```bash
erp-help      # Show help
erp-backend   # Enter backend container
erp-logs      # View backend logs
erp-status    # Check services status
```

### Inside Backend Container
```bash
bench start                          # Start dev server
bench --site frontend console       # ERPNext console
bench --site frontend clear-cache   # Clear cache
bench --site frontend migrate       # Database migration
bench --site frontend list-apps     # List apps
```

## 📁 Project Structure
```
/workspaces/erpnext_tv5smart_admin/  # Dev container workspace
/home/frappe/frappe-bench/           # ERPNext backend (in container)
```

## 🔧 Troubleshooting
- If terminal doesn't work: Rebuild container
- If backend is down: `docker compose restart backend`  
- If site not found: Check `docker compose exec backend bench list-sites`
EOF

echo "✅ ERPNext Development Environment Setup Complete!"
echo ""
echo "🎉 Ready to develop!"
echo "💡 Run './dev-help.sh' to see available commands"
echo "🚀 Run './enter-backend.sh' to enter ERPNext backend"