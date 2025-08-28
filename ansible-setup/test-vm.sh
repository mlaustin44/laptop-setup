#!/bin/bash

# VM Testing Script for Ansible Laptop Setup
# This script automates VM creation and testing of the Ansible playbook

set -e

VM_NAME="ansible-test"
VM_MEMORY="4G"
VM_DISK="25G"
VM_CPUS="2"
UBUNTU_VERSION="25.04"

echo "🚀 Ansible Laptop Setup VM Test Script"
echo "======================================"

# Check if multipass is installed
if ! command -v multipass &> /dev/null; then
    echo "❌ Multipass not found. Installing..."
    echo "Run: sudo snap install multipass"
    echo "Or download from: https://multipass.run/"
    exit 1
fi

# Function to cleanup existing VM
cleanup_vm() {
    echo "🧹 Cleaning up existing VM..."
    multipass delete "$VM_NAME" 2>/dev/null || true
    multipass purge 2>/dev/null || true
}

# Function to create fresh VM
create_vm() {
    echo "🏗️  Creating fresh Ubuntu $UBUNTU_VERSION VM..."
    multipass launch "$UBUNTU_VERSION" \
        --name "$VM_NAME" \
        --memory "$VM_MEMORY" \
        --disk "$VM_DISK" \
        --cpus "$VM_CPUS"
    
    echo "✅ VM created successfully"
}

# Function to setup VM for testing
setup_vm() {
    echo "⚙️  Setting up VM for Ansible testing..."
    
    # Update system and install basic requirements
    multipass exec "$VM_NAME" -- sudo apt update
    multipass exec "$VM_NAME" -- sudo apt install -y git ansible
    
    # Create test directory and copy ansible files
    multipass exec "$VM_NAME" -- mkdir -p /home/ubuntu/laptop-setup
    
    echo "📁 Transferring Ansible files to VM..."
    multipass transfer --recursive . "$VM_NAME":/home/ubuntu/laptop-setup/
    
    echo "✅ VM setup complete"
}

# Function to create snapshot
create_snapshot() {
    echo "📸 Creating snapshot for faster future tests..."
    echo "⏹️  Stopping VM to create snapshot..."
    multipass stop "$VM_NAME"
    multipass snapshot "$VM_NAME" --name "clean-setup"
    echo "▶️  Starting VM back up..."
    multipass start "$VM_NAME"
    echo "✅ Snapshot 'clean-setup' created"
}

# Function to restore from snapshot
restore_snapshot() {
    echo "⏪ Restoring from clean snapshot..."
    echo "⏹️  Stopping VM to restore snapshot..."
    multipass stop "$VM_NAME"
    multipass restore "$VM_NAME.clean-setup" --destructive
    echo "▶️  Starting VM back up..."
    multipass start "$VM_NAME"
    
    # Update ansible files after restore
    echo "📁 Updating Ansible files..."
    multipass transfer --recursive . "$VM_NAME":/home/ubuntu/laptop-setup/
    echo "✅ VM restored and files updated"
}

# Function to check if snapshot exists
snapshot_exists() {
    multipass info "$VM_NAME" --snapshots 2>/dev/null | grep -q "clean-setup"
}

# Function to run the Ansible playbook
run_ansible() {
    echo "🎭 Running Ansible playbook in VM..."
    
    # Always update files before running
    echo "📁 Updating Ansible files..."
    multipass transfer --recursive . "$VM_NAME":/home/ubuntu/laptop-setup/
    
    multipass exec "$VM_NAME" -- bash -c "
        cd /home/ubuntu/laptop-setup && 
        echo 'Running Ansible playbook...' &&
        sudo ansible-playbook -i inventory/localhost site.yml --connection=local -v
    "
}

# Function to run verification tests
verify_setup() {
    echo "🔍 Verifying installation..."
    
    echo "Checking installed packages..."
    multipass exec "$VM_NAME" -- bash -c "
        echo '=== System Info ==='
        lsb_release -a
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
        
        echo '=== Flatpak Apps ==='
        flatpak list --app 2>/dev/null | wc -l || echo 'Flatpak: ❌'
        echo
        
        echo '=== Manual Binaries ==='
        which kubectl && echo 'kubectl: ✅' || echo 'kubectl: ❌'
        which helm && echo 'helm: ✅' || echo 'helm: ❌'
        which aws && echo 'AWS CLI: ✅' || echo 'AWS CLI: ❌'
        echo
        
        echo '=== Shell Setup ==='
        echo \$SHELL
        test -d ~/.oh-my-zsh && echo 'Oh-My-Zsh: ✅' || echo 'Oh-My-Zsh: ❌'
    "
}

# Function to connect to VM for manual testing
connect_vm() {
    echo "🔌 Connecting to VM for manual inspection..."
    echo "Use 'exit' to return to host"
    multipass shell "$VM_NAME"
}

# Function to show VM info
show_vm_info() {
    echo "📊 VM Information:"
    multipass info "$VM_NAME"
}

# Main menu
show_menu() {
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
    echo "9) 🚪 Exit"
    echo
    read -p "Enter choice [1-9]: " choice
}

# Main execution
case "${1:-menu}" in
    "fresh")
        cleanup_vm
        create_vm
        setup_vm
        if ! snapshot_exists; then
            echo "📸 Creating snapshot before running Ansible..."
            create_snapshot
            echo "⏸️  Snapshot created. Press Enter to run Ansible, or Ctrl+C to stop here..."
            read -p ""
        else
            echo "📸 Snapshot already exists, proceeding with Ansible..."
        fi
        run_ansible
        verify_setup
        echo "🎉 Full test completed! Use '$0 fast' for quick retests"
        ;;
    "fast")
        if snapshot_exists; then
            restore_snapshot
            run_ansible
            verify_setup
            echo "⚡ Fast test completed!"
        else
            echo "❌ No snapshot found. Run '$0 fresh' first to create one"
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
        create_snapshot
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
                    setup_vm
                    if ! snapshot_exists; then
                        echo "📸 Creating snapshot before running Ansible..."
                        create_snapshot
                        echo "⏸️  Snapshot created. Press Enter to run Ansible, or Ctrl+C to stop here..."
                        read -p ""
                    else
                        echo "📸 Snapshot already exists, proceeding with Ansible..."
                    fi
                    run_ansible
                    verify_setup
                    echo "🎉 Full test completed!"
                    ;;
                2)
                    if snapshot_exists; then
                        restore_snapshot
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
                    create_snapshot
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