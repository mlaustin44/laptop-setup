#!/bin/bash
# Create remaining script files

cd ansible-setup/files/scripts

# power-mode-menu
cat > power-mode-menu << 'EOF'
#!/bin/bash
MODES="⚡ Powersave\n⚖️  Balanced\n🚀 Performance\n🔥 Turbo"

if command -v wofi &> /dev/null; then
    CHOSEN=$(echo -e "$MODES" | wofi --dmenu --prompt "Power Mode:" | awk '{print tolower($2)}')
elif command -v rofi &> /dev/null; then
    CHOSEN=$(echo -e "$MODES" | rofi -dmenu -p "Power Mode:" | awk '{print tolower($2)}')
elif command -v bemenu &> /dev/null; then
    CHOSEN=$(echo -e "$MODES" | bemenu -p "Power Mode:" | awk '{print tolower($2)}')
else
    echo "No menu program found (wofi/rofi/bemenu)"
    exit 1
fi

if [ -n "$CHOSEN" ]; then
    ~/.local/bin/power-mode set "$CHOSEN"
fi
EOF

# wifi-switch
cat > wifi-switch << 'EOF'
#!/bin/bash
if command -v iwctl &> /dev/null; then
    echo "Current network:"
    iwctl station wlan0 show
    echo
    echo "Scanning for networks..."
    iwctl station wlan0 scan
    sleep 2
    echo
    echo "Available networks:"
    iwctl station wlan0 get-networks
    echo
    read -p "Enter SSID to connect (or press Enter to cancel): " SSID
    [ -n "$SSID" ] && iwctl station wlan0 connect "$SSID"
elif command -v nmcli &> /dev/null; then
    echo "Current connection:"
    nmcli -t -f NAME,TYPE,DEVICE con show --active | grep wifi
    echo
    echo "Available networks:"
    nmcli dev wifi list
    echo
    read -p "Enter SSID to connect (or press Enter to cancel): " SSID
    [ -n "$SSID" ] && nmcli dev wifi connect "$SSID"
else
    echo "No network manager found (iwd/NetworkManager)"
fi
EOF

# vpn-control
cat > vpn-control << 'EOF'
#!/bin/bash
case "$1" in
    tailscale|ts)
        if systemctl is-active tailscaled &>/dev/null; then
            sudo tailscale status
        else
            echo "Starting Tailscale..."
            sudo systemctl start tailscaled
            sudo tailscale up
        fi
        ;;
    down)
        echo "Disconnecting VPNs..."
        sudo tailscale down 2>/dev/null
        nmcli con down type vpn 2>/dev/null
        ;;
    status)
        echo "=== Tailscale ==="
        if systemctl is-active tailscaled &>/dev/null; then
            sudo tailscale status | head -5
        else
            echo "Not running"
        fi
        echo
        echo "=== NetworkManager VPNs ==="
        nmcli con show --active | grep vpn || echo "No active VPN"
        ;;
    *)
        echo "Usage: $0 {tailscale|ts|down|status}"
        exit 1
        ;;
esac
EOF

# backup-system
cat > backup-system << 'EOF'
#!/bin/bash
BACKUP_DIR="$HOME/backups/system-$(date +%Y%m%d-%H%M%S)"
mkdir -p "$BACKUP_DIR"

echo "📦 Creating system backup in $BACKUP_DIR..."

echo "📋 Backing up package lists..."
pacman -Qe > "$BACKUP_DIR/packages-explicit.txt"
pacman -Qm > "$BACKUP_DIR/packages-aur.txt"
pacman -Qq > "$BACKUP_DIR/packages-all.txt"

echo "📁 Backing up configurations..."
[ -d ~/.config ] && cp -r ~/.config "$BACKUP_DIR/config"
[ -f ~/.zshrc ] && cp ~/.zshrc "$BACKUP_DIR/"
[ -f ~/.bashrc ] && cp ~/.bashrc "$BACKUP_DIR/"
[ -f ~/.gitconfig ] && cp ~/.gitconfig "$BACKUP_DIR/"

echo "🔑 Backing up SSH config..."
[ -f ~/.ssh/config ] && cp ~/.ssh/config "$BACKUP_DIR/ssh-config"
[ -f ~/.ssh/known_hosts ] && cp ~/.ssh/known_hosts "$BACKUP_DIR/ssh-known-hosts"

cat > "$BACKUP_DIR/restore.sh" << 'RESTORE'
#!/bin/bash
echo "System Restore Helper"
echo "====================="
echo
echo "To restore packages:"
echo "  sudo pacman -S --needed \$(cat packages-explicit.txt)"
echo
echo "To restore AUR packages:"
echo "  paru -S --needed \$(cat packages-aur.txt)"
echo
echo "Configuration files are in their respective directories."
echo "Review and copy manually to avoid overwriting custom configs."
RESTORE
chmod +x "$BACKUP_DIR/restore.sh"

echo "✅ Backup complete: $BACKUP_DIR"
echo "📜 Run $BACKUP_DIR/restore.sh for restoration instructions"
EOF

# search-packages
cat > search-packages << 'EOF'
#!/bin/bash
if [ $# -eq 0 ]; then
    echo "Usage: $0 <package-name>"
    exit 1
fi

echo "=== Official Repositories ==="
pacman -Ss "$1" 2>/dev/null | head -20

echo
echo "=== AUR Packages ==="
paru -Ss "$1" 2>/dev/null | grep -E "^aur/" | head -20

echo
echo "💡 Tips:"
echo "  Install from repo: sudo pacman -S <package>"
echo "  Install from AUR:  paru -S <package>"
echo "  Package info:      pacman -Si <package>"
EOF

# Create remaining scripts...
# wallpaper-rotate, oled-protect, audio-switch, vol, btrfs-*, find-package

chmod +x *