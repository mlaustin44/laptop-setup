# laptop-configs

Ansible playbooks for Ubuntu/pop_os development environment setup.

## Prerequisites

- Ubuntu or ubuntu based installation
- Internet connection  
- User account with sudo privileges
- Git and Ansible: `sudo apt update && sudo apt install git ansible`

## Usage

```bash
cd ansible-setup
ansible-playbook -i inventory/localhost site.yml --ask-become-pass
```

## Structure

```
ansible-setup/
├── site.yml                 # Main playbook
├── inventory/              # Host configuration
├── group_vars/
│   └── all.yml            # Configuration variables
└── tasks/
    ├── system-packages.yml  # System packages and repositories
    ├── development.yml      # Programming languages
    ├── python-packages.yml  # Python environment
    ├── manual-binaries.yml  # Binary installations
    ├── applications.yml     # GUI applications
    ├── dotfiles.yml        # Shell and git config
    └── desktop.yml         # GNOME settings
```

## Configuration

Package lists, versions, and settings are defined in `group_vars/all.yml`.

## Testing

The repository includes a test script for validating the playbook in a virtual machine:

```bash
./test-vm.sh
```

The script uses multipass to create an Ubuntu VM for testing. Commands:
- `fresh` - Create new VM, run playbook, and create snapshot (after base setup, before copying ansible files) for fast retesting
- `fast` - Restore from snapshot and run playbook (requires previous `fresh` run)
- `ansible` - Run playbook on existing VM without restoring (but does overwrite files)
- `verify` - Check installation status
- `connect` - SSH into VM
- `snapshot` - Create snapshot of current VM state
- `cleanup` - Delete VM and all snapshots

The `fresh` command automatically creates a snapshot after initial VM setup, before running Ansible. Subsequent tests can use `fast` to restore from this clean snapshot, avoiding the need to recreate the VM and reinstall base packages.

## Manual VM Testing

```bash
multipass launch 25.04 --name test --memory 4G --disk 25G
multipass transfer . test:/home/ubuntu/laptop-setup/
multipass shell test
cd laptop-setup
ansible-playbook -i inventory/localhost site.yml --ask-become-pass
```

## Verification

After running the playbook:

```bash
# Check installed tools
which docker git code zsh python3 node go cargo kubectl aws

# Check versions
docker --version
python3 --version
node --version
go version

# Check services
systemctl status docker
```

## Notes

- Credentials and SSH keys require manual backup and restoration
- Flatpak applications require a GUI session
- Some services require user login to start