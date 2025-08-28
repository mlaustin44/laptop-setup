# Testing the Ansible Setup

## VM Testing (Recommended)

### Quick Start
```bash
# Install multipass if needed
sudo snap install multipass

# Run full test
./test-vm.sh fresh
```

### Test Script Usage
```bash
./test-vm.sh [command]
```

**Commands:**
- `fresh` - Create fresh VM and run complete test
- `ansible` - Run Ansible playbook on existing VM
- `verify` - Check installation on existing VM  
- `connect` - SSH into VM for manual inspection
- `info` - Show VM information
- `cleanup` - Delete test VM
- `menu` - Interactive menu (default)

### Manual VM Testing
```bash
# Create VM
multipass launch 25.04 --name test --memory 4G --disk 25G

# Transfer files
multipass transfer . test:/home/ubuntu/laptop-setup/

# Connect and test
multipass shell test
cd laptop-setup
sudo ./run-setup.sh
```

## Docker Testing (Limited)

For basic package installation testing only:

```bash
# Create test container
docker run -it --privileged ubuntu:25.04 bash

# In container
apt update && apt install -y git ansible
git clone <your-repo>
cd laptop-configs/ansible-setup

# Test package installation only (no desktop/flatpak)
ansible-playbook -i inventory/localhost site.yml --connection=local --skip-tags=desktop,flatpak
```

## What to Test

### ✅ Must Work
- All system packages install without errors
- All repositories are accessible  
- Docker installs and starts
- VSCode installs with extensions
- Development tools (Python, Node, Go, Rust) are available
- Shell environment (zsh, oh-my-zsh) is configured
- Manual binaries are downloaded and executable

### ⚠️ Expected Issues on Fresh VM
- Some Flatpaks may fail (need GUI session)
- Desktop environment settings (requires login)
- SSH key generation (manual step)
- Service starts that need user session

### 🔍 How to Debug
1. **Package failures**: Check repository URLs and keys
2. **Permission errors**: Verify ansible user/group setup  
3. **Network errors**: Check internet connection in VM
4. **Service failures**: Check if services need user login

## Test Checklist

After running the playbook, verify:

```bash
# Essential tools
which docker git code zsh python3 node go cargo
docker --version
git --version  
code --list-extensions | wc -l

# Manual binaries  
which kubectl helm aws claude-code temporal

# Development environments
python3 --version
node --version  
go version
cargo --version

# Shell setup
echo $SHELL
ls -la ~/.oh-my-zsh

# Flatpak (if GUI available)
flatpak list --app

# Services
systemctl status docker
systemctl status tailscaled
```

## Iteration Workflow

1. Run `./test-vm.sh fresh`
2. Note any failures in the output
3. Fix issues in the Ansible files
4. Run `./test-vm.sh ansible` to test fixes
5. Use `./test-vm.sh verify` to check results
6. Use `./test-vm.sh connect` for manual inspection
7. Repeat until all issues resolved

## Performance Notes

- VM creation: ~2-3 minutes
- Ansible playbook: ~15-30 minutes (depending on internet)
- Full test cycle: ~20-35 minutes
- Subsequent tests (existing VM): ~15-20 minutes