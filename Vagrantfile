# -*- mode: ruby -*-
# vim: set ft=ruby :
home = ENV['HOME'] # Используем глобальную переменную $HOME

MACHINES = {
  :backupserver => {
    :box_name => "centos/7",
    :box_version => "1804.02",
    :ip_addr => '192.168.10.101',
    :cpus => 3,
    :memory => "3072",
    :disks => {
        :sata1 => {
            :dfile => home + '/VirtualBox VMs/backup.vdi',
            :size => 2024, # Megabytes
            :port => 1
        },
    }
  },
  :client => {
    :box_name => "centos/7",
    :box_version => "1804.02",
    :ip_addr => '192.168.10.100',
    :cpus => 3,
    :memory => "3072",
    :disks => {
        :sata1 => {
            :dfile => home + '/VirtualBox VMs/client.vdi',
            :size => 2024, # Megabytes
            :port => 1
        },
    }
  },
}

Vagrant.configure("2") do |config|
  MACHINES.each do |boxname, boxconfig|
    config.vm.define boxname do |box|
      box.vm.box = boxconfig[:box_name]
      box.vm.box_version = boxconfig[:box_version]
      box.vm.host_name = boxname.to_s
      box.vm.network "private_network", ip: boxconfig[:ip_addr]

      box.vm.provider :virtualbox do |vb|
        vb.cpus = boxconfig[:cpus]
        vb.memory = boxconfig[:memory]
        needsController = false
        boxconfig[:disks].each do |dname, dconf|
          unless File.exist?(dconf[:dfile])
            vb.customize ['createhd', '--filename', dconf[:dfile], '--variant', 'Fixed', '--size', dconf[:size]]
            needsController =  true
          end
        end
        if needsController == true
          vb.customize ["storagectl", :id, "--name", "SATA", "--add", "sata" ]
          boxconfig[:disks].each do |dname, dconf|
              vb.customize ['storageattach', :id,  '--storagectl', 'SATA', '--port', dconf[:port], '--device', 0, '--type', 'hdd', '--medium', dconf[:dfile]]
          end
        end
      end
    config.vm.provision "shell", inline: <<-SHELL
            mkdir -p ~root/.ssh
            cp ~vagrant/.ssh/auth* ~root/.ssh
            
    SHELL
  end
end
end