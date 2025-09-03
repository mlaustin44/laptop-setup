# Arch Linux Development Machine Setup

Comprehensive Ansible playbook for setting up Arch Linux (or EndeavourOS) as a development workstation, optimized for the ASUS Zenbook UM5606 but adaptable to other hardware.

## Features

### System Configuration
- Full Arch Linux system configuration with optimizations for AMD Ryzen CPUs
- BTRFS with subvolumes and compression
- LUKS encryption with TPM2 auto-unlock support
- Hibernation support with large swap file (96GB for 64GB RAM systems)
- Systemd-boot or GRUB bootloader configuration

### Hardware Support (UM5606 Specific)
- AMD GPU driver configuration with proper kernel parameters
- OLED display burn-in protection
- Advanced power management with multiple power profiles
- Keyboard remapping via keyd
- Automatic display switching for external monitors
- Fan control and thermal management

### Desktop Environments
- **GNOME** - Full GNOME desktop with extensions
- **Sway** - Tiling Wayland compositor with full configuration
- **Hyprland** - Modern, animated Wayland compositor
- Greetd with TUI greeter as display manager

### Development Environment
- **Languages**: Python (via pyenv), Rust, Go, Node.js, Java
- **Containers**: Docker, Podman, Kubernetes tools
- **Cloud**: AWS CLI, Azure CLI, Google Cloud SDK
- **Editors**: Neovim, VS Code, JetBrains Toolbox
- **Databases**: PostgreSQL, MySQL/MariaDB, MongoDB, Redis clients
- **Version Control**: Git with sensible defaults, GitHub CLI

### Network & Security
- iwd for improved WiFi on modern hardware
- Tailscale VPN integration
- UFW firewall configuration
- Bluetooth with auto-connect
- Systemd-resolved with DNS over TLS

### Power Management
- TLP for battery optimization
- Auto-cpufreq for dynamic CPU frequency scaling
- Multiple power modes (powersave, balanced, performance, turbo)
- Suspend-then-hibernate configuration
- OLED-specific power saving

## Requirements

### For Installation Target
- Arch Linux or EndeavourOS (fresh installation recommended)
- UEFI boot mode
- 64-bit AMD or Intel processor
- Minimum 8GB RAM (16GB+ recommended)
- 50GB+ free disk space

### For Testing (VM)
- **Option 1**: Vagrant with VirtualBox or libvirt
- **Option 2**: Multipass (limited Arch support)
- 4GB RAM for VM
- 25GB disk space for VM

## Quick Start

### 1. Clone the Repository
```bash
git clone https://github.com/yourusername/laptop-setup.git
cd laptop-setup
```

### 2. Configure Variables
Edit `ansible-setup/group_vars/all.yml`:
```yaml
target_user: "yourusername"
git_user_name: "Your Name"
git_user_email: "your.email@example.com"
hostname: "your-hostname"
timezone: "America/Los_Angeles"
```

### 3. Test in VM (Recommended)
```bash
# Using Vagrant (recommended for full Arch testing)
./test-vm.sh fresh

# Or run manually
vagrant up
vagrant ssh
cd /home/testuser/ansible-setup
sudo ansible-playbook -i inventory/localhost site.yml
```

### 4. Run on Real Hardware
```bash
cd ansible-setup
sudo ansible-playbook -i inventory/localhost site.yml
```

## Usage

### Running Specific Tags
```bash
# Only install packages
sudo ansible-playbook -i inventory/localhost site.yml --tags packages

# Only configure desktop
sudo ansible-playbook -i inventory/localhost site.yml --tags desktop

# Skip desktop installation
sudo ansible-playbook -i inventory/localhost site.yml --skip-tags desktop
```

### Available Tags
- `base` - Base system configuration
- `hardware` - Hardware-specific configuration
- `packages` - Package installation (core and AUR)
- `development` - Development environment setup
- `desktop` - Desktop environment installation
- `power` - Power management configuration
- `network` - Network and VPN setup
- `user` - User configuration and dotfiles
- `services` - System services configuration
- `flatpak` - Flatpak installation (optional)
- `finalize` - Final configuration and validation

### VM Testing Commands
```bash
./test-vm.sh           # Interactive menu
./test-vm.sh fresh     # Create new VM and run full test
./test-vm.sh fast      # Restore snapshot and run test
./test-vm.sh ansible   # Just run Ansible on existing VM
./test-vm.sh verify    # Verify installation
./test-vm.sh connect   # SSH into VM
./test-vm.sh cleanup   # Destroy VM
```

## Post-Installation

After running the playbook, you'll find:
- `~/post-install-checklist.md` - Checklist of manual steps
- System information: run `sysinfo`
- Update everything: run `update-all`
- Power management: run `power-mode-menu`
- Package search: run `search-packages <name>`

### Essential Commands
```bash
# System
sysinfo              # Display system information
update-all           # Update system and all packages
backup-system        # Create system backup

# Power Management
power-mode get       # Show current power mode
power-mode set turbo # Set power mode
power-mode-menu      # GUI power mode selector

# Network
wifi-switch          # Switch WiFi networks
vpn-control status   # VPN status
vpn-control tailscale # Connect Tailscale

# Packages
search-packages vim  # Search for packages
paru -S package-name # Install from AUR
```

## Customization

### Hardware Profiles
Edit `group_vars/all.yml`:
```yaml
hardware_model: "UM5606"  # Set your hardware model
laptop_mode: true         # Enable laptop optimizations
oled_display: true        # Enable OLED protection
```

### Desktop Selection
```yaml
primary_desktop: "gnome"  # Options: gnome, sway, hyprland
install_sway: true        # Install Sway WM
install_hyprland: true    # Install Hyprland
```

### Development Tools
```yaml
install_rust: true
install_go: true
install_docker: true
python_version: "3.11"
```

## Troubleshooting

### VM Issues
- **Vagrant not found**: Install from https://www.vagrantup.com
- **VirtualBox issues**: Ensure virtualization is enabled in BIOS
- **Arch box download fails**: Try `vagrant box add archlinux/archlinux`

### Installation Issues
- **GPG key errors**: Update keyring with `sudo pacman -Sy archlinux-keyring`
- **AUR build fails**: Ensure base-devel is installed
- **Service fails to start**: Check logs with `journalctl -xe`

### Hardware Issues
- **WiFi not working**: Try switching between NetworkManager and iwd
- **Suspend issues**: Check kernel parameters in `/etc/default/grub`
- **Display issues**: Verify GPU drivers with `lspci -k`

## Contributing

1. Fork the repository
2. Create a feature branch
3. Test your changes in VM
4. Submit a pull request

## License

MIT License - See LICENSE file for details

## Acknowledgments

- Based on experience with EndeavourOS and Arch Linux
- Optimized for ASUS Zenbook UM5606 hardware
- Community configurations from r/archlinux and r/AsusZenbook

## Support

For issues specific to:
- **This playbook**: Open an issue on GitHub
- **Arch Linux**: https://bbs.archlinux.org/
- **EndeavourOS**: https://forum.endeavouros.com/
- **Hardware**: Check Arch Wiki for your specific model