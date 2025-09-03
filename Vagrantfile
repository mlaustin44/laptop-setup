# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure("2") do |config|
  # Use Arch Linux box
  config.vm.box = "archlinux/archlinux"
  
  # VM Name
  config.vm.hostname = "arch-test"
  
  # VirtualBox specific configuration
  config.vm.provider "virtualbox" do |vb|
    vb.name = "arch-ansible-test"
    vb.memory = "4096"
    vb.cpus = 2
    
    # Enable GUI for desktop testing (comment out for headless)
    vb.gui = true
    
    # Graphics controller with more VRAM for desktop environments
    vb.customize ["modifyvm", :id, "--graphicscontroller", "vmsvga"]
    vb.customize ["modifyvm", :id, "--vram", "128"]
    
    # Enable 3D acceleration
    vb.customize ["modifyvm", :id, "--accelerate3d", "on"]
    
    # Enable clipboard and drag-n-drop
    vb.customize ["modifyvm", :id, "--clipboard", "bidirectional"]
    vb.customize ["modifyvm", :id, "--draganddrop", "bidirectional"]
  end
  
  # QEMU/KVM (libvirt) provider configuration
  config.vm.provider "libvirt" do |libvirt|
    libvirt.memory = 4096
    libvirt.cpus = 2
    libvirt.graphics_type = "spice"
    libvirt.video_type = "qxl"
    libvirt.channel :type => 'spicevmc', :target_name => 'com.redhat.spice.0', :target_type => 'virtio'
  end
  
  # Synced folder for Ansible playbooks
  config.vm.synced_folder ".", "/vagrant", type: "rsync",
    rsync__exclude: [".git/", "*.backup"]
  
  # Provisioning script
  config.vm.provision "shell", inline: <<-SHELL
    set -e
    
    echo "==> Updating system..."
    pacman -Syu --noconfirm
    
    echo "==> Installing base requirements..."
    pacman -S --needed --noconfirm \
      base-devel \
      git \
      ansible \
      python \
      python-pip \
      sudo
    
    echo "==> Setting up user for testing..."
    useradd -m -G wheel -s /bin/bash testuser 2>/dev/null || true
    echo "testuser:password" | chpasswd
    echo "%wheel ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/wheel
    
    echo "==> Setting VM_MODE environment variable..."
    echo "export VM_MODE=true" >> /etc/environment
    
    echo "==> Copying Ansible files..."
    cp -r /vagrant/ansible-setup /home/testuser/
    chown -R testuser:testuser /home/testuser/ansible-setup
    
    echo "==> VM is ready for Ansible testing!"
    echo "==> To run the playbook:"
    echo "   vagrant ssh"
    echo "   cd ansible-setup"
    echo "   sudo ansible-playbook -i inventory/localhost site.yml"
  SHELL
  
  # Optional: Auto-run Ansible (uncomment to run automatically)
  # config.vm.provision "ansible_local" do |ansible|
  #   ansible.playbook = "ansible-setup/site.yml"
  #   ansible.inventory_path = "ansible-setup/inventory/localhost"
  #   ansible.extra_vars = {
  #     vm_mode: true,
  #     target_user: "testuser"
  #   }
  # end
end