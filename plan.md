## Complete System Configuration Plan for ASUS Zenbook UM5606

### Pre-Installation Requirements

1. **EndeavourOS ISO** with latest version
2. **Backup** all data from current system
3. **UEFI Settings** to check:
   - Secure Boot: Keep enabled (test first, disable if issues)
   - TPM 2.0: Enabled (for LUKS auto-unlock)
4. **Update UEFI/BIOS** from ASUS website before installing

### Phase 1: Base Installation

#### 1.1 Boot Parameters
```bash
# Add to boot options when booting installer:
amdgpu.dcdebugmask=0x600
```

#### 1.2 Disk Partitioning (4TB NVMe)
```bash
# Partition layout:
/dev/nvme0n1p1  512MB  EFI System Partition (FAT32)
/dev/nvme0n1p2  Rest   LUKS encrypted container

# Inside LUKS:
btrfs with subvolumes:
  @          /          (root)
  @home      /home      (user data)
  @var       /var       (variable data)
  @log       /var/log   (logs)
  @snapshots /.snapshots (for Timeshift)
  @swap      /swap      (96GB swapfile location)
```

#### 1.3 BTRFS Mount Options
```
noatime,compress=zstd:1,space_cache=v2,autodefrag
```

#### 1.4 Installation Choices
- Desktop: GNOME
- Display Manager: GDM (will switch to greetd post-install)
- Bootloader: systemd-boot
- Kernel: linux (will upgrade post-install if needed)

### Phase 2: Post-Installation System Configuration

#### 2.1 System Updates & Kernel
```yaml
tasks:
  - name: Update system
    pacman:
      update_cache: yes
      upgrade: yes

  - name: Install newer kernel if needed for UM5606 support
    aur:
      name: linux-mainline
      state: present
    when: kernel_version < 6.14

  - name: Add kernel parameters
    lineinfile:
      path: /etc/kernel/cmdline
      line: "amdgpu.dcdebugmask=0x600 resume=UUID={{ swap_uuid }} resume_offset={{ swap_offset }}"
```

#### 2.2 LUKS with TPM2 Auto-unlock
```yaml
  - name: Install TPM2 tools
    pacman:
      name:
        - tpm2-tss
        - tpm2-tools
        - clevis

  - name: Enroll TPM2 for LUKS
    command: systemd-cryptenroll --tpm2-device=auto /dev/nvme0n1p2

  - name: Configure crypttab for TPM2
    lineinfile:
      path: /etc/crypttab.initramfs
      line: "cryptroot UUID={{ luks_uuid }} none tpm2-device=auto"
```

#### 2.3 Swap Configuration (96GB)
```yaml
  - name: Create swap subvolume and file
    shell: |
      mount -o subvol=@swap /dev/mapper/cryptroot /swap
      truncate -s 0 /swap/swapfile
      chattr +C /swap/swapfile
      fallocate -l 96G /swap/swapfile
      chmod 600 /swap/swapfile
      mkswap /swap/swapfile
      
  - name: Configure hibernation
    blockinfile:
      path: /etc/systemd/sleep.conf
      block: |
        [Sleep]
        AllowSuspend=yes
        AllowHibernation=yes
        AllowSuspendThenHibernate=yes
        HibernateDelaySec=1800
```

### Phase 3: Package Installation

#### 3.1 Core System Packages (Arch equivalents)
```yaml
core_packages:
  # Build tools
  - base-devel
  - cmake
  - clang
  - clang  # includes clang-format
  
  # Network tools
  - curl
  - wget
  - git
  - openssh
  - nmap
  - traceroute
  - gnu-netcat
  - mosh
  - socat
  
  # System utilities
  - vim
  - neovim
  - htop
  - tree
  - unzip
  - p7zip
  - jq
  - fzf
  - zsh
  - bc
  - lsof
  - screen
  - tmux
  - ripgrep
  - xxd
  - xz
  - moreutils
  
  # Development
  - python
  - python-pip
  - nodejs
  - npm
  - jre-openjdk
  - jdk21-openjdk
  - android-tools
  - make
  - gcc
  - gdb
  - doxygen
  - github-cli
  - minicom
  - picocom
  - putty
  
  # Desktop tools
  - wmctrl
  - upower
  - gnome-tweaks
  
  # Database clients
  - postgresql-libs
  - redis
  - sqlite
  
  # Multimedia
  - gimp
  - vlc
  - transmission-gtk
  - ffmpeg
  - imagemagick
  - v4l-utils
  
  # System tools
  - wireshark-qt
  - remmina
  - gparted
  - virtualbox
  - wine
  
  # Power management
  - tlp
  - tlp-rdw
  - powertop
  - acpid
  
  # Wayland/Display
  - kanshi
  - wlr-randr
  - wdisplays
  - brightnessctl
  - swayidle
  
  # Audio
  - pipewire
  - pipewire-pulse
  - pipewire-alsa
  - wireplumber
  - pavucontrol
  - pamixer
```

#### 3.2 AUR Packages
```yaml
aur_packages:
  - paru-bin  # AUR helper
  - keyd-git  # Keyboard remapping
  - auto-cpufreq
  - ryzenadj-git
  - asus-5606-fan-state-git
  - greetd-tuigreet
  - tailscale
  - visual-studio-code-bin
  - google-chrome
  - slack-desktop
  - uv  # Python package manager
  - pyenv
  - temporalio-bin
  - claude-desktop  # or claude-cli if available
```

### Phase 4: Development Environment

#### 4.1 Programming Languages
```yaml
  - name: Install Rust
    shell: |
      curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
      
  - name: Install Go
    pacman:
      name: go
      
  - name: Setup pyenv
    shell: |
      curl https://pyenv.run | bash
      pyenv install 3.11
      pyenv global 3.11
```

#### 4.2 Python Packages
```yaml
  - name: Install Python packages
    pip:
      name: "{{ item }}"
      executable: /home/{{ user }}/.pyenv/versions/3.11.*/bin/pip
    loop:
      # [Full list from requirements]
```

#### 4.3 Docker Setup
```yaml
  - name: Install Docker
    pacman:
      name:
        - docker
        - docker-compose
        - docker-buildx
        
  - name: Enable Docker service
    systemd:
      name: docker
      enabled: yes
      state: started
      
  - name: Add user to docker group
    user:
      name: "{{ user }}"
      groups: docker
      append: yes
```

### Phase 5: Desktop Environment Setup

#### 5.1 Display Manager Switch
```yaml
  - name: Install greetd
    aur:
      name:
        - greetd
        - greetd-tuigreet
        
  - name: Configure greetd
    copy:
      content: |
        [terminal]
        vt = 1
        
        [default_session]
        command = "tuigreet --time --remember --remember-user-session"
        user = "greeter"
      dest: /etc/greetd/config.toml
      
  - name: Switch from GDM to greetd
    shell: |
      systemctl disable gdm
      systemctl enable greetd
```

#### 5.2 Additional DEs
```yaml
  - name: Install Sway
    pacman:
      name:
        - sway
        - swaylock
        - swayidle
        - swaybg
        - waybar
        - wofi
        - mako
        - grim
        - slurp
        - wl-clipboard
        - xdg-desktop-portal-wlr
        - foot
        
  - name: Install Hyprland
    aur:
      name:
        - hyprland-git
        - hyprlock
        - hypridle
        - hyprpaper
        - waybar-hyprland-git
        - xdg-desktop-portal-hyprland-git
        - kitty
```

### Phase 6: Hardware-Specific Configuration

#### 6.1 Keyboard Configuration (keyd)
```yaml
  - name: Configure keyd
    copy:
      content: |
        [ids]
        *
        
        [main]
        capslock = esc
        leftshift+leftmeta+f23 = rightcontrol
      dest: /etc/keyd/default.conf
      
  - name: Enable keyd
    systemd:
      name: keyd
      enabled: yes
      state: started
```

#### 6.2 Network Configuration
```yaml
  - name: Switch to iwd for WiFi (UM5606 compatibility)
    shell: |
      systemctl disable NetworkManager
      systemctl enable --now iwd
      
  - name: Configure iwd for UM5606
    copy:
      content: |
        [Unit]
        After=sys-devices-pci0000:00-0000:00:02.3-0000:c3:00.0-net-wlan0.device
        Wants=sys-devices-pci0000:00-0000:00:02.3-0000:c3:00.0-net-wlan0.device
      dest: /etc/systemd/system/iwd.service.d/dependencies.conf
      
  - name: Set DNS to Cloudflare
    copy:
      content: |
        [Resolve]
        DNS=1.1.1.1 1.0.0.1
      dest: /etc/systemd/resolved.conf.d/dns.conf
```

#### 6.3 Power Management
```yaml
  - name: Configure TLP
    copy:
      src: files/tlp.conf
      dest: /etc/tlp.conf
      
  - name: Configure logind for lid behavior
    copy:
      content: |
        [Login]
        HandleLidSwitch=suspend-then-hibernate
        HandleLidSwitchDocked=ignore
        HandleLidSwitchExternalPower=suspend-then-hibernate
      dest: /etc/systemd/logind.conf.d/lid.conf
```

#### 6.4 Display Profiles (Kanshi)
```yaml
  - name: Create kanshi config
    copy:
      src: files/kanshi_config
      dest: /home/{{ user }}/.config/kanshi/config
      
  - name: Create display switch script with F7 toggle
    copy:
      content: |
        #!/bin/bash
        # F7 display toggle for mirror/extend on external displays
        
        CURRENT_MODE_FILE="/tmp/display_mode"
        CURRENT_MODE=$(cat $CURRENT_MODE_FILE 2>/dev/null || echo "extend")
        
        if wlr-randr | grep -q "3840x2160"; then
          if [ "$CURRENT_MODE" = "extend" ]; then
            kanshictl switch-to-profile external-4k-mirror
            echo "mirror" > $CURRENT_MODE_FILE
            notify-send "Display Mode" "Mirrored 4K"
          else
            kanshictl switch-to-profile external-4k-extend
            echo "extend" > $CURRENT_MODE_FILE
            notify-send "Display Mode" "Extended 4K"
          fi
        elif wlr-randr | grep -q "1920x1080"; then
          if [ "$CURRENT_MODE" = "extend" ]; then
            kanshictl switch-to-profile external-1080p-mirror
            echo "mirror" > $CURRENT_MODE_FILE
            notify-send "Display Mode" "Mirrored 1080p"
          else
            kanshictl switch-to-profile external-1080p-extend
            echo "extend" > $CURRENT_MODE_FILE
            notify-send "Display Mode" "Extended 1080p"
          fi
        else
          kanshictl switch-to-profile laptop
          notify-send "Display Mode" "Laptop Only"
        fi
      dest: /home/{{ user }}/.local/bin/display-toggle
      mode: '0755'
```

### Phase 7: OLED Protection & Power Scripts

#### 7.1 OLED Burn-in Prevention
```yaml
  - name: Configure swayidle for OLED
    copy:
      content: |
        timeout 60 'brightnessctl -s set 10%' resume 'brightnessctl -r'
        timeout 600 'swaymsg "output eDP-1 dpms off"' resume 'swaymsg "output eDP-1 dpms on"'
        timeout 900 'cat /sys/class/power_supply/AC/online | grep -q 0 && systemctl suspend-then-hibernate'
      dest: /home/{{ user }}/.config/swayidle/config
```

#### 7.2 Power Mode Management
```yaml
  - name: Install power mode scripts
    copy:
      src: "files/{{ item }}"
      dest: "/home/{{ user }}/.local/bin/{{ item }}"
      mode: '0755'
    loop:
      - power-mode
      - power-mode-status
      - power-mode-switcher
      - power-mode-menu
      
  - name: Configure sudo for fan control
    copy:
      content: |
        {{ user }} ALL=(ALL) NOPASSWD: /usr/bin/fan_state
        {{ user }} ALL=(ALL) NOPASSWD: /usr/bin/ryzenadj
      dest: /etc/sudoers.d/power-management
```

### Phase 8: VPN & Services

#### 8.1 Tailscale
```yaml
  - name: Enable Tailscale
    systemd:
      name: tailscaled
      enabled: yes
      state: started
```

#### 8.2 Bluetooth Configuration
```yaml
  - name: Configure Bluetooth auto-connect
    copy:
      content: |
        [General]
        Enable=Source,Sink,Media,Socket
        AutoConnect=true
        FastConnectable=true
        
        [Policy]
        AutoEnable=true
      dest: /etc/bluetooth/main.conf
```

### Phase 9: User Configuration

#### 9.1 Shell Setup
```yaml
  - name: Install Oh My Zsh
    become_user: "{{ user }}"
    shell: |
      sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
      
  - name: Set Zsh as default shell
    user:
      name: "{{ user }}"
      shell: /usr/bin/zsh
```

#### 9.2 Git Configuration
```yaml
  - name: Configure Git
    become_user: "{{ user }}"
    shell: |
      git config --global user.name "{{ git_user_name }}"
      git config --global core.editor vim
      git config --global push.autoSetupRemote true
```

### Phase 10: Flatpak Applications

```yaml
  - name: Install Flatpak apps
    flatpak:
      name: "{{ item }}"
      state: present
    loop:
      - com.slack.Slack
      - com.transmissionbt.Transmission
      - io.dbeaver.DBeaverCommunity
      - org.flameshot.Flameshot
      - org.telegram.desktop
      # ... rest of flatpak apps
```

### Phase 11: Final System Configuration

#### 11.1 Wake/Dock Handlers
```yaml
  - name: Install dock/wake handlers
    copy:
      src: files/dock-handler
      dest: /usr/local/bin/dock-handler
      mode: '0755'
      
  - name: Configure udev rules for dock
    copy:
      src: files/99-dock-wake.rules
      dest: /etc/udev/rules.d/99-dock-wake.rules
```

#### 11.2 Waybar Configuration
```yaml
  - name: Configure Waybar with power mode display
    copy:
      src: files/waybar/
      dest: /home/{{ user }}/.config/waybar/
      owner: "{{ user }}"
```

#### 11.3 Sway/Hyprland Keybindings
```yaml
  - name: Configure Sway keybindings
    blockinfile:
      path: /home/{{ user }}/.config/sway/config
      block: |
        # Display switching
        bindsym XF86Display exec display-toggle
        bindsym $mod+F7 exec display-toggle
        
        # Power modes
        bindsym $mod+Shift+p exec power-mode-menu
        bindsym $mod+bracketleft exec power-mode prev
        bindsym $mod+bracketright exec power-mode next
```

### Phase 12: Validation & Testing

#### 12.1 System Checks
```yaml
  - name: Verify critical services
    systemd:
      name: "{{ item }}"
      state: started
    loop:
      - iwd
      - greetd
      - keyd
      - tlp
      - tailscaled
      - bluetooth
      
  - name: Test power management
    shell: |
      systemctl suspend-then-hibernate --check
      fan_state get
```

### Critical Notes

1. **UM5606-Specific Issues**:
   - Must use kernel 6.14+ for proper audio and suspend
   - Use iwd instead of NetworkManager for WiFi stability
   - asus-5606-fan-state-git for fan control (not asusctl)
   - Boot parameter `amdgpu.dcdebugmask=0x600` required

2. **Missing from Original Requirements**:
   - ProtonVPN CLI no longer exists - removed
   - Claude Code may need manual installation depending on availability
   - Some flatpak apps may not be available in Arch

3. **Manual Steps Required**:
   - UEFI update before installation
   - Testing Secure Boot compatibility
   - Bluetooth device pairing
   - Google account setup for Drive

This plan provides a complete roadmap for Ansible automation with all necessary configurations for the UM5606.
