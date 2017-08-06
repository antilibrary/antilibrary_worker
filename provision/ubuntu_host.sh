#!/bin/bash
sudo apt-get update
sudo apt-get install -y tar
sudo apt-get install -y wget
sudo apt-get install -y screen
sudo apt-get install -y virtualbox
sudo apt-get install -y vagrant

# ipfs
if [[ ! -f "/usr/bin/ipfs" ]]; then 
  wget https://dist.ipfs.io/go-ipfs/v0.4.10/go-ipfs_v0.4.10_linux-amd64.tar.gz
  tar xzvf go-ipfs_v0.4.10_linux-amd64.tar.gz
  rm go-ipfs_v0.4.10_linux-amd64.tar.gz
  sudo mv go-ipfs/ipfs /usr/bin
  sudo chmod a+x /usr/bin/ipfs
fi

# pubsub
chmod a+x pubsub.sh
if ! screen -list | grep -q "pubsub"; then
	read -p "Run 'pubsub.sh' in another terminal and then press enter to continue: "
fi

if ! screen -list | grep -q "pubsub"; then
	echo "pubsub initiation failed, exiting"
	exit
fi

# vagrant
cd ..
if vagrant global-status | grep antilibrary_worker | grep running > /dev/null; then
	echo "Worker is up, running 'vagrant provision'"
	vagrant provision
else
	echo "Worker is down, running 'vagrant up --provision'"
	vagrant up --provision
fi