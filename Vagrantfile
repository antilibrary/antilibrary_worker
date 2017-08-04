Vagrant.configure("2") do |config|

  config.vm.box = "ubuntu/trusty64"

  config.vm.provision "file", source: "config.yml", destination: "config.yml"
  config.vm.provision "file", source: "antilibrary_worker.rb", destination: "antilibrary_worker.rb"
  config.vm.provision "shell", path: "provision/vagrant.sh"
end
