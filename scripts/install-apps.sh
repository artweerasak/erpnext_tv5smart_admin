#!/bin/bash
set -e

echo "Installing custom apps..."

# Install HRMS
if [ -d "/home/frappe/frappe-bench/apps/hrms" ]; then
    echo "Installing HRMS package..."
    pip install -e /home/frappe/frappe-bench/apps/hrms
    echo "HRMS package installed successfully!"
else
    echo "HRMS app directory not found!"
fi

# Install Lending
if [ -d "/home/frappe/frappe-bench/apps/lending" ]; then
    echo "Installing Lending package..."
    pip install -e /home/frappe/frappe-bench/apps/lending
    echo "Lending package installed successfully!"
else
    echo "Lending app directory not found!"
fi

echo "All custom apps installed successfully!"
