Vagrant.configure("2") do |config|
 config.vm.box = "spencercooley/centos6.4"
 config.vm.define "pbs_host" do |sc|
     sc.vm.provider "virtualbox" do |vb|
        vb.name = "pbs_host"
     end
     sc.vm.host_name="pbs-host"
     sc.vm.network "private_network", ip:"172.28.128.10"
 end

 config.vm.define "pbs_mom_1" do |cs|
     cs.vm.provider "virtualbox" do |vb|
        vb.name = "pbs_mom_1"
     end
     cs.vm.host_name="pbs-mom-1"
     cs.vm.network "private_network", ip:"172.28.128.11"
 end

 config.vm.define "pbs_mom_2" do |cs|
     cs.vm.provider "virtualbox" do |vb|
        vb.name = "pbs_mom_2"
     end
     cs.vm.host_name="pbs-mom-2"
     cs.vm.network "private_network", ip:"172.28.128.12"
 end
end
