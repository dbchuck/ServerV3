# -*- mode: ruby -*-
# vi: set ft=ruby :

# Check for required plugin(s)
['vagrant-hostmanager'].each do |plugin|
  unless Vagrant.has_plugin?(plugin)
    raise "#{plugin} plugin not found. Please install it via 'vagrant plugin install #{plugin}'"
  end
end

vagrant_dir = File.expand_path(File.dirname(__FILE__))

# Either libvirt or virtualbox
PROVIDER = "libvirt"
# Either centos or ubuntu
DISTRO = "centos"

# The libvirt graphics_ip used for each guest. Only applies if PROVIDER
# is libvirt.
GRAPHICSIP = "127.0.0.1"

# Configure a new SSH key and config so the operator is able to connect with
# the other cluster nodes.
unless File.file?(File.join(vagrant_dir, 'vagrantkey'))
  system("ssh-keygen -f #{File.join(vagrant_dir, 'vagrantkey')} -N '' -C this-is-vagrant")
end

Vagrant.configure(2) do |config|
  config.vm.provider :libvirt do |libvirt|
    libvirt.driver = "kvm"
  end
  config.hostmanager.enabled = false
  config.hostmanager.ip_resolver = proc do |machine|
    result = ""
    machine.communicate.execute("ip addr | grep 'dynamic eth0'") do |type, data|
        result << data if type == :stdout
    end
    (ip = /inet (\d+\.\d+\.\d+\.\d+)/.match(result)) && ip[1]
  end

  config.vm.box = "centos/7"

  my_privatekey = File.read(File.join(vagrant_dir, "vagrantkey"))
  my_publickey = File.read(File.join(vagrant_dir, "vagrantkey.pub"))
  username = "vagrant"
  user_home = "/home/#{username}"
  config.vm.network :private_network, type: "dhcp"
  config.vm.network :public_network, :libvirt__network_name => 'internet',
    :dev => "internal0",
    :mode => "bridge",
    :type => "bridge"
  config.vm.provision :hostmanager

  config.vm.provision :shell, inline: <<-EOS
    mkdir -p /root/.ssh
    echo '#{my_privatekey}' > /root/.ssh/id_rsa
    chmod 600 /root/.ssh/id_rsa
    echo '#{my_publickey}' > /root/.ssh/authorized_keys
    chmod 600 /root/.ssh/authorized_keys
    echo '#{my_publickey}' > /root/.ssh/id_rsa.pub
    chmod 644 /root/.ssh/id_rsa.pub
    mkdir -p #{user_home}/.ssh
    echo '#{my_privatekey}' > #{user_home}/.ssh/openstack
    chmod 600 #{user_home}/.ssh/*
    echo '#{my_publickey}' >> #{user_home}/.ssh/authorized_keys
    chmod 600 #{user_home}/.ssh/authorized_keys
    echo '#{my_publickey}' > #{user_home}/.ssh/openstack.pub
    chmod 644 #{user_home}/.ssh/openstack.pub
    echo 'Host *' > #{user_home}/.ssh/config
    echo StrictHostKeyChecking no >> #{user_home}/.ssh/config
    chown -R #{username} #{user_home}/.ssh
    echo "* * * * * root echo 3 > /proc/sys/vm/drop_caches" > /etc/crontab
    nmcli con mod 'System eth0' ipv4.never-default yes
    nmcli con mod 'System eth1' ipv4.never-default yes
    nmcli con down 'System eth0'; nmcli con up 'System eth0'
    nmcli con down 'System eth1'; nmcli con up 'System eth1'
  EOS

  # The operator controls the deployment
  config.vm.define "operator", primary: true do |admin|
    admin.vm.hostname = "operator.local"
    admin.hostmanager.aliases = "operator"
    # admin.vm.provision :shell, path: PROVISION_SCRIPT, args: ""
    admin.vm.synced_folder ".", "/vagrant", disabled: true
    admin.vm.provider PROVIDER do |vm|
      vm.memory = 4096
      vm.cpus = 4
      vm.nested = true
      vm.graphics_ip = GRAPHICSIP
    end
    admin.vm.provision :shell, inline: <<-EOS
      yum install python-devel libffi-devel gcc openssl-devel libselinux-python -y
      yum install git sshpass python-virtualenv libvirt -y
      su - vagrant bash -c 'echo -e "Host *\nIdentityFile ~/.ssh/openstack" > ~/.ssh/config'
      su - vagrant bash -c "mkdir ~/openstack-virt-env && virtualenv ~/openstack-virt-env"
      su - vagrant bash -c "source ~/openstack-virt-env/bin/activate && pip install -U pip"
      su - vagrant bash -c "source ~/openstack-virt-env/bin/activate && pip install ansible"
      su - vagrant bash -c "source ~/openstack-virt-env/bin/activate && pip install kolla-ansible"
    EOS
  end

  # The control nodes (that will host storage and networking OpenStack components as well)
  (0..2).each do |i|
    hostname = "control#{i}"
    config.vm.define hostname do |node|
      node.vm.hostname = "#{hostname}.local"
      node.hostmanager.aliases = hostname
      # node.vm.provision :shell, path: PROVISION_SCRIPT, args: ""
      node.vm.synced_folder ".", "/vagrant", disabled: true
      # Add additional ethernet port
      node.vm.network :public_network, :libvirt__network_name => 'internet',
        :dev => "internal0",
        :mode => "bridge",
        :type => "bridge"
      node.vm.provider PROVIDER do |vm|
        vm.memory = 8192
        vm.cpus = 4
        vm.nested = true
        vm.graphics_ip = GRAPHICSIP
        # vm.storage :file, :size => '5TB', :path => "storage#{i}.img", :type => 'raw'
      end
      node.vm.provision :shell, inline: <<-EOS
        nmcli con mod 'System eth2' ipv4.method disabled
        nmcli con down 'System eth2'; sudo nmcli con up 'System eth2'
        yum install -y yum-utils device-mapper-persistent-data lvm2
        yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
        yum install docker-ce docker-ce-cli containerd.io -y
      EOS
    end
  end

  (0..1).each do |i|
    hostname = "compute#{i}"
    config.vm.define hostname do |node|
      node.vm.hostname = "#{hostname}.local"
      node.hostmanager.aliases = hostname
      # node.vm.provision :shell, path: PROVISION_SCRIPT, args: ""
      node.vm.synced_folder ".", "/vagrant", disabled: true
      node.vm.provider PROVIDER do |vm|
        vm.memory = 16384
        vm.cpus = 8
        vm.nested = true
        vm.graphics_ip = GRAPHICSIP
      end
    end
  end
end
