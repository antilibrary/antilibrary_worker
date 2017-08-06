#!/bin/bash

# install base packages
sudo apt-get update
sudo apt-get install -y tar wget screen lsb-release

# install virtualbox
if [[ ! -f "/usr/bin/virtualbox" ]]; then 
	# add virtualbox repo
	codename=`lsb_release --codename | cut -f2`
	if ! grep "deb http://download.virtualbox.org/virtualbox/debian $codename contrib" /etc/apt/sources.list
	then
		sudo /bin/sh -c 'codename=`lsb_release --codename | cut -f2` && echo "deb http://download.virtualbox.org/virtualbox/debian $codename contrib" >> /etc/apt/sources.list'
		sudo wget -q https://www.virtualbox.org/download/oracle_vbox_2016.asc -O- | sudo apt-key add -
		sudo wget -q https://www.virtualbox.org/download/oracle_vbox.asc -O- | sudo apt-key add -
	fi

	sudo apt-get update
	sudo apt-get install -y dkms virtualbox-4.3
fi

# install vagrant
sudo wget "https://releases.hashicorp.com/vagrant/1.9.7/vagrant_1.9.7_$(uname -m).deb"
sudo dpkg -i "vagrant_1.9.7_$(uname -m).deb"
sudo rm "vagrant_1.9.7_$(uname -m).deb"

# ipfs
if [[ ! -f "/usr/bin/ipfs" ]]; then 
  wget https://dist.ipfs.io/go-ipfs/v0.4.10/go-ipfs_v0.4.10_linux-amd64.tar.gz
  tar xzvf go-ipfs_v0.4.10_linux-amd64.tar.gz
  rm go-ipfs_v0.4.10_linux-amd64.tar.gz
  sudo mv go-ipfs/ipfs /usr/bin
  sudo chmod a+x /usr/bin/ipfs
fi

# pubsub
chmod a+x provision/pubsub.sh
if ! screen -list | grep -q "pubsub"; then
	read -p "Run './provision/pubsub.sh' in another terminal and then press enter to continue: "
fi

if ! screen -list | grep -q "pubsub"; then
	echo "Pubsub listener initiation failed, exiting."
	exit
else
	echo "Pubsub listener is running. You can view the logs with 'screen -x pubsub'. Use CTRL-A CTLR-D to exist the logs."
	echo "If you stop the IPFS listener, the antilibrary worker will not work. ;)"
fi

# vagrant
if vagrant global-status | grep antilibrary_worker | grep running > /dev/null; then
	echo "Worker is up, running 'vagrant provision'"
	vagrant provision
else
	echo "Worker is down, running 'vagrant up --provision'"
	vagrant up --provision
fi