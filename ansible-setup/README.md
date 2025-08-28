# Development Laptop Ansible Setup

This Ansible playbook will configure a fresh Ubuntu system to match your development environment.

## System Overview

This setup includes:
- Ubuntu 25.04+ base system (adaptable to other versions)
- Essential development packages and tools
- Flatpak applications
- Development environments: Python, Node.js, Go, Rust, Zig, Android
- Docker and Kubernetes tools
- VSCode with extensions
- oh-my-zsh with custom configuration
- GNOME desktop customizations

## Prerequisites

1. Fresh Ubuntu 25.04+ installation (or similar Debian-based distro)
2. Internet connection
3. User account with sudo privileges
4. Git installed: `sudo apt update && sudo apt install git ansible`

## Quick Start

1. Run the playbook on your new system:
```bash
git clone <repo-url>
cd laptop-configs/ansible-setup
ansible-playbook -i inventory/localhost site.yml --ask-become-pass
```

2. Restore your credentials manually after the playbook completes

## What's Included

### Development Tools
- Build essentials, CMake, clang
- Python with pyenv
- Node.js with nvm  
- Go, Rust, Zig compilers
- Docker and docker-compose
- Kubernetes tools (kubectl, k9s, helm)
- Android development tools

### Applications (via Flatpak)
- DBeaver Community
- Telegram Desktop
- Flameshot
- Anki
- Transmission
- Bottles
- And more...

### Shell Environment
- zsh as default shell
- oh-my-zsh with plugins
- Custom aliases and PATH
- fzf integration

### Desktop Environment
- GNOME customizations
- App organization
- Keyboard shortcuts

## Customization

Edit variables in the playbook files to customize:
- Package selections
- User preferences  
- Application configurations
- Desktop settings

## Structure

```
ansible-setup/
├── README.md
├── site.yml                # Main playbook
├── inventory/
├── group_vars/
├── roles/
└── files/
```