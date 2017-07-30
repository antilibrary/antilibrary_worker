Vagrant.configure("2") do |config|

  config.vm.box = "ubuntu/trusty64"

  config.vm.provision "file", source: "config.yml", destination: "config.yml"
  config.vm.provision "file", source: "antilibrary_worker.rb", destination: "antilibrary_worker.rb"
  config.vm.provision "shell", inline: <<-SHELL
    # install ipfs if not already instealled
    if [ ! -d /home/vagrant/go-ipfs ]; then wget https://dist.ipfs.io/go-ipfs/v0.4.10/go-ipfs_v0.4.10_linux-amd64.tar.gz &&  tar xzvf go-ipfs_v0.4.10_linux-amd64.tar.gz && rm go-ipfs_v0.4.10_linux-amd64.tar.gz; fi

    # install ruby
    sudo apt-add-repository -y ppa:brightbox/ruby-ng
    sudo apt-get update
    sudo apt-get install -y ruby2.4 ruby2.4-dev

    # start ipfs
    /home/vagrant/go-ipfs/ipfs init
    nohup /home/vagrant/go-ipfs/ipfs daemon --enable-pubsub-experiment &
    sleep 10

    # start antilibrary worker
    echo ' '
    echo '#######################################################################'
    echo ' '
    echo 'Running Antilibrary Worker'
    ruby /home/vagrant/antilibrary_worker.rb
  SHELL
end
