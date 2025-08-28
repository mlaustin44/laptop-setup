#!/bin/bash

# Development Laptop Setup Script for Ubuntu 25.04+
# This script sets up Ansible and runs the laptop configuration playbook

set -e

echo "🖥️  Development Laptop Setup for Ubuntu 25.04+"
echo "=============================================="

# Check if running on Ubuntu/Debian
if ! command -v apt &> /dev/null; then
    echo "❌ This script requires a Debian-based system (Ubuntu, Pop!_OS, etc.)"
    exit 1
fi

# Update package lists
echo "📦 Updating package lists..."
sudo apt update

# Install Ansible if not present
if ! command -v ansible &> /dev/null; then
    echo "🔧 Installing Ansible..."
    sudo apt install -y ansible
else
    echo "✅ Ansible already installed"
fi

# Install required Ansible collections
echo "📚 Installing Ansible collections..."
ansible-galaxy collection install community.general --force

# Verify inventory
if [ ! -f "inventory/localhost" ]; then
    echo "❌ Ansible inventory not found. Make sure you're in the correct directory."
    exit 1
fi

# Run the playbook
echo "🚀 Running Ansible playbook..."
echo "   You'll be prompted for your sudo password"
echo ""

ansible-playbook -i inventory/localhost site.yml --ask-become-pass -v

echo ""
echo "✅ Laptop setup completed!"
echo ""
echo "🔄 Next steps:"
echo "1. Restore your credentials from backup"
echo "2. Reboot to ensure all changes take effect"
echo "3. Log back in and verify everything works"
echo "4. Restore browser bookmarks and extensions"
echo "5. Set up IDE workspaces and projects"
echo ""
echo "⚠️  Note: Some applications may need to be launched once to complete setup"