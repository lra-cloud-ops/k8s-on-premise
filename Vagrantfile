ENV['VAGRANT_NO_PARALLEL'] = 'yes'

Vagrant.configure("2") do |config|
  config.vm.box = "ubuntu/jammy64"
  config.vm.box_check_update = false
  config.vm.boot_timeout = 600

  # Master Node
  config.vm.define "master" do |master|
    master.vm.hostname = "master-node"
    master.vm.network "private_network", ip: "192.168.56.10"
    master.vm.provider "virtualbox" do |v|
      v.name   = "master-node"
      v.memory = 4096
      v.cpus   = 2
    end
    master.vm.provision "shell", path: "scripts/common.sh"
    master.vm.provision "shell", path: "scripts/master.sh"
    master.vm.provision "shell", run: "always", inline: <<-SHELL
      systemctl restart kubelet
    SHELL
  end

  # Worker Node 1
  config.vm.define "worker1" do |worker1|
    worker1.vm.hostname = "worker-node1"
    worker1.vm.network "private_network", ip: "192.168.56.11"
    worker1.vm.provider "virtualbox" do |v|
      v.name   = "worker-node1"
      v.memory = 6144
      v.cpus   = 4
    end
    worker1.vm.provision "shell", path: "scripts/common.sh"
    worker1.vm.provision "shell", args: "192.168.56.11", path: "scripts/worker.sh"
    worker1.vm.provision "shell", run: "always", inline: <<-SHELL
      systemctl restart kubelet
    SHELL
  end

  # Worker Node 2
  config.vm.define "worker2" do |worker2|
    worker2.vm.hostname = "worker-node2"
    worker2.vm.network "private_network", ip: "192.168.56.12"
    worker2.vm.provider "virtualbox" do |v|
      v.name   = "worker-node2"
      v.memory = 6144
      v.cpus   = 4
    end
    worker2.vm.provision "shell", path: "scripts/common.sh"
    worker2.vm.provision "shell", args: "192.168.56.12", path: "scripts/worker.sh"
    worker2.vm.provision "shell", run: "always", inline: <<-SHELL
      systemctl restart kubelet
    SHELL
  end

end
