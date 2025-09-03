#!/bin/bash

# VM Testing Script for Arch Linux Ansible Setup
# Supports both Vagrant (cross-platform) and Multipass (Ubuntu hosts)

set -e

VM_NAME="arch-ansible-test"
VM_MEMORY="4096"
VM_DISK="25G"
VM_CPUS="2"

echo "🚀 Arch Linux Ansible Setup VM Test Script"
echo "=========================================="

# Detect which VM provider to use
detect_provider() {
    if command -v vagrant &> /dev/null; then
        echo "vagrant"
    elif command -v multipass &> /dev/null; then
        echo "multipass"
    else
        echo "none"
    fi
}

PROVIDER=${VM_PROVIDER:-$(detect_provider)}

if [ "$PROVIDER" = "none" ]; then
    echo "❌ No VM provider found!"
    echo ""
    echo "Please install one of the following:"
    echo "  - Vagrant (recommended, cross-platform):"
    echo "    https://www.vagrantup.com/downloads"
    echo ""
    echo "  - Multipass (Ubuntu/macOS only):"
    echo "    sudo snap install multipass"
    echo ""
    echo "You can also set VM_PROVIDER environment variable:"
    echo "  VM_PROVIDER=vagrant $0"
    exit 1
fi

echo "📦 Using provider: $PROVIDER"
echo ""

# =============================================================================
# Vagrant Functions
# =============================================================================

vagrant_cleanup() {
    echo "🧹 Cleaning up Vagrant VM..."
    vagrant destroy -f 2>/dev/null || true
    rm -rf .vagrant
}

vagrant_create() {
    echo "🏗️  Creating Arch Linux VM with Vagrant..."
    
    if [ ! -f Vagrantfile ]; then
        echo "❌ Vagrantfile not found!"
        exit 1
    fi
    
    vagrant up
    echo "✅ VM created successfully"
}

vagrant_snapshot_create() {
    echo "📸 Creating Vagrant snapshot..."
    vagrant snapshot save clean-setup
    echo "✅ Snapshot 'clean-setup' created"
}

vagrant_snapshot_restore() {
    echo "⏪ Restoring from Vagrant snapshot..."
    vagrant snapshot restore clean-setup
    echo "✅ VM restored from snapshot"
}

vagrant_snapshot_exists() {
    vagrant snapshot list 2>/dev/null | grep -q "clean-setup"
}

vagrant_run_ansible() {
    echo "🎭 Running Ansible playbook in Vagrant VM..."
    
    # Sync latest files
    vagrant rsync
    
    vagrant ssh -c "
        cd /home/testuser/ansible-setup && 
        echo 'Running Ansible playbook...' &&
        sudo VM_MODE=true ansible-playbook -i inventory/localhost site.yml --connection=local -v
    "
}

vagrant_verify() {
    echo "🔍 Verifying installation in Vagrant VM..."
    
    vagrant ssh -c "
        echo '=== System Info ==='
        cat /etc/os-release | grep -E '^NAME|^VERSION'
        echo
        
        echo '=== Key Packages ==='
        which docker && docker --version || echo 'Docker: ❌'
        which code && echo 'VSCode: ✅' || echo 'VSCode: ❌'
        which git && git --version || echo 'Git: ❌'
        which zsh && zsh --version || echo 'Zsh: ❌'
        which python3 && python3 --version || echo 'Python: ❌'
        which node && node --version || echo 'Node: ❌'
        which go && go version || echo 'Go: ❌'
        which cargo && cargo --version || echo 'Rust: ❌'
        echo
        
        echo '=== AUR Helper ==='
        which paru && echo 'paru: ✅' || echo 'paru: ❌'
        which yay && echo 'yay: ✅' || echo 'yay: ❌'
        echo
        
        echo '=== Desktop Environment ==='
        which gnome-shell && echo 'GNOME: ✅' || echo 'GNOME: ❌'
        which sway && echo 'Sway: ✅' || echo 'Sway: ❌'
        which Hyprland && echo 'Hyprland: ✅' || echo 'Hyprland: ❌'
        echo
        
        echo '=== Services ==='
        systemctl is-active docker || echo 'Docker service: ❌'
        systemctl is-active bluetooth || echo 'Bluetooth service: ❌'
        systemctl is-active tlp || echo 'TLP service: ❌'
        echo
        
        echo '=== Shell Setup ==='
        echo \$SHELL
        test -d ~/.oh-my-zsh && echo 'Oh-My-Zsh: ✅' || echo 'Oh-My-Zsh: ❌'
    "
}

vagrant_connect() {
    echo "🔌 Connecting to Vagrant VM..."
    echo "Use 'exit' to return to host"
    vagrant ssh
}

vagrant_info() {
    echo "📊 Vagrant VM Information:"
    vagrant status
}

# =============================================================================
# Multipass Functions (for Arch Linux using cloud-init)
# =============================================================================

multipass_cleanup() {
    echo "🧹 Cleaning up Multipass VM..."
    multipass delete "$VM_NAME" 2>/dev/null || true
    multipass purge 2>/dev/null || true
}

multipass_create() {
    echo "🏗️  Creating Arch Linux VM with Multipass..."
    echo "⚠️  Note: Multipass doesn't have official Arch images."
    echo "   Using Ubuntu and converting to Arch-like environment for testing..."
    
    # Create cloud-init config for Arch-like setup
    cat > /tmp/cloud-init-arch.yaml << 'EOF'
#cloud-config
package_update: true
package_upgrade: true
packages:
  - git
  - ansible
  - python3
  - python3-pip
  - build-essential
  - curl
  - wget

runcmd:
  - echo "VM_MODE=true" >> /etc/environment
  - mkdir -p /home/ubuntu/ansible-setup
  - echo "Arch-like test environment ready"
EOF
    
    multipass launch 22.04 \
        --name "$VM_NAME" \
        --memory "$VM_MEMORY" \
        --disk "$VM_DISK" \
        --cpus "$VM_CPUS" \
        --cloud-init /tmp/cloud-init-arch.yaml
    
    echo "✅ VM created (Ubuntu base for Arch testing)"
    
    # Transfer files
    echo "📁 Transferring Ansible files to VM..."
    multipass transfer --recursive ansible-setup "$VM_NAME":/home/ubuntu/
    
    rm /tmp/cloud-init-arch.yaml
}

multipass_snapshot_create() {
    echo "📸 Creating Multipass snapshot..."
    multipass stop "$VM_NAME"
    multipass snapshot "$VM_NAME" --name "clean-setup"
    multipass start "$VM_NAME"
    echo "✅ Snapshot 'clean-setup' created"
}

multipass_snapshot_restore() {
    echo "⏪ Restoring from Multipass snapshot..."
    multipass stop "$VM_NAME"
    multipass restore "$VM_NAME.clean-setup" --destructive
    multipass start "$VM_NAME"
    
    # Update ansible files after restore
    echo "📁 Updating Ansible files..."
    multipass transfer --recursive ansible-setup "$VM_NAME":/home/ubuntu/
    echo "✅ VM restored and files updated"
}

multipass_snapshot_exists() {
    multipass info "$VM_NAME" --snapshots 2>/dev/null | grep -q "clean-setup"
}

multipass_run_ansible() {
    echo "🎭 Running Ansible playbook in Multipass VM..."
    echo "⚠️  Note: Running on Ubuntu base, some Arch-specific tasks may be skipped"
    
    # Update files
    multipass transfer --recursive ansible-setup "$VM_NAME":/home/ubuntu/
    
    multipass exec "$VM_NAME" -- bash -c "
        cd /home/ubuntu/ansible-setup && 
        echo 'Running Ansible playbook...' &&
        sudo VM_MODE=true ansible-playbook -i inventory/localhost site.yml --connection=local -v
    "
}

multipass_verify() {
    echo "🔍 Verifying installation in Multipass VM..."
    
    multipass exec "$VM_NAME" -- bash -c "
        echo '=== System Info ==='
        lsb_release -a 2>/dev/null || cat /etc/os-release | grep -E '^NAME|^VERSION'
        echo
        
        echo '=== Test Results ==='
        echo 'Note: This is Ubuntu simulating Arch environment'
        echo 'Some Arch-specific features will not be available'
        echo
        
        echo '=== Installed Tools ==='
        which git && git --version || echo 'Git: ❌'
        which ansible && ansible --version | head -1 || echo 'Ansible: ❌'
        which python3 && python3 --version || echo 'Python: ❌'
        echo
        
        echo 'Use Vagrant for full Arch Linux testing'
    "
}

multipass_connect() {
    echo "🔌 Connecting to Multipass VM..."
    echo "Use 'exit' to return to host"
    multipass shell "$VM_NAME"
}

multipass_info() {
    echo "📊 Multipass VM Information:"
    multipass info "$VM_NAME"
}

# =============================================================================
# Generic wrapper functions that call the appropriate provider
# =============================================================================

cleanup_vm() {
    ${PROVIDER}_cleanup
}

create_vm() {
    ${PROVIDER}_create
}

snapshot_create() {
    ${PROVIDER}_snapshot_create
}

snapshot_restore() {
    ${PROVIDER}_snapshot_restore
}

snapshot_exists() {
    ${PROVIDER}_snapshot_exists
}

run_ansible() {
    ${PROVIDER}_run_ansible
}

verify_setup() {
    ${PROVIDER}_verify
}

connect_vm() {
    ${PROVIDER}_connect
}

show_vm_info() {
    ${PROVIDER}_info
}

# =============================================================================
# Main Menu
# =============================================================================

show_menu() {
    echo
    echo "VM Provider: $PROVIDER"
    echo
    echo "Choose an option:"
    echo "1) 🆕 Create fresh VM and run full test"
    echo "2) ⚡ Fast test (restore from snapshot + run Ansible)"
    echo "3) 🎭 Run Ansible playbook on existing VM"  
    echo "4) 🔍 Verify installation on existing VM"
    echo "5) 📸 Create snapshot of current VM state"
    echo "6) 🔌 Connect to existing VM"
    echo "7) 📊 Show VM info"
    echo "8) 🧹 Cleanup VM"
    echo "9) 🔄 Switch VM provider"
    echo "0) 🚪 Exit"
    echo
    read -p "Enter choice [0-9]: " choice
}

switch_provider() {
    echo "Select VM provider:"
    echo "1) Vagrant (recommended for Arch testing)"
    echo "2) Multipass (Ubuntu-based testing)"
    echo
    read -p "Enter choice [1-2]: " provider_choice
    
    case $provider_choice in
        1)
            if ! command -v vagrant &> /dev/null; then
                echo "❌ Vagrant not installed!"
                echo "Install from: https://www.vagrantup.com/downloads"
                return
            fi
            PROVIDER="vagrant"
            echo "✅ Switched to Vagrant"
            ;;
        2)
            if ! command -v multipass &> /dev/null; then
                echo "❌ Multipass not installed!"
                echo "Install with: sudo snap install multipass"
                return
            fi
            PROVIDER="multipass"
            echo "✅ Switched to Multipass"
            ;;
        *)
            echo "❌ Invalid choice"
            ;;
    esac
}

# =============================================================================
# Main Execution
# =============================================================================

case "${1:-menu}" in
    "fresh")
        cleanup_vm
        create_vm
        if ! snapshot_exists; then
            echo "📸 Creating snapshot before running Ansible..."
            snapshot_create
            echo "⏸️  Snapshot created. Press Enter to run Ansible, or Ctrl+C to stop here..."
            read -p ""
        fi
        run_ansible
        verify_setup
        echo "🎉 Full test completed!"
        ;;
    "fast")
        if snapshot_exists; then
            snapshot_restore
            run_ansible
            verify_setup
            echo "⚡ Fast test completed!"
        else
            echo "❌ No snapshot found. Run '$0 fresh' first"
            exit 1
        fi
        ;;
    "ansible")
        run_ansible
        ;;
    "verify")
        verify_setup
        ;;
    "snapshot")
        snapshot_create
        ;;
    "connect")
        connect_vm
        ;;
    "info")
        show_vm_info
        ;;
    "cleanup")
        cleanup_vm
        echo "✅ VM cleaned up"
        ;;
    "menu"|*)
        while true; do
            show_menu
            case $choice in
                1)
                    cleanup_vm
                    create_vm
                    if ! snapshot_exists; then
                        echo "📸 Creating snapshot before running Ansible..."
                        snapshot_create
                        echo "⏸️  Snapshot created. Press Enter to run Ansible, or Ctrl+C to stop here..."
                        read -p ""
                    fi
                    run_ansible
                    verify_setup
                    echo "🎉 Full test completed!"
                    ;;
                2)
                    if snapshot_exists; then
                        snapshot_restore
                        run_ansible
                        verify_setup
                        echo "⚡ Fast test completed!"
                    else
                        echo "❌ No snapshot found. Run option 1 first"
                    fi
                    ;;
                3)
                    run_ansible
                    ;;
                4)
                    verify_setup
                    ;;
                5)
                    snapshot_create
                    ;;
                6)
                    connect_vm
                    ;;
                7)
                    show_vm_info
                    ;;
                8)
                    cleanup_vm
                    echo "✅ VM cleaned up"
                    ;;
                9)
                    switch_provider
                    ;;
                0)
                    echo "👋 Goodbye!"
                    exit 0
                    ;;
                *)
                    echo "❌ Invalid option"
                    ;;
            esac
            echo
            read -p "Press Enter to continue..."
        done
        ;;
esac