# install ipfs
if [ ! -d /home/vagrant/go-ipfs ]; then wget https://dist.ipfs.io/go-ipfs/v0.4.10/go-ipfs_v0.4.10_linux-amd64.tar.gz &&  tar xzvf go-ipfs_v0.4.10_linux-amd64.tar.gz && rm go-ipfs_v0.4.10_linux-amd64.tar.gz; fi

# install ruby
sudo apt-add-repository -y ppa:brightbox/ruby-ng
sudo apt-get update
sudo apt-get install -y ruby2.4 ruby2.4-dev

# start ipfs
/home/vagrant/go-ipfs/ipfs init

# replace max ipfs storage with user defined value
sed -i "s/10GB/$(grep 'storage_limit:' config.yml | tail -n1 | awk '{ print $2}')GB/g" ~/.ipfs/config

# run guest daemon
nohup /home/vagrant/go-ipfs/ipfs daemon &
sleep 10

# get host ipfs daemon ip
export ipfs_api_addr=$(netstat -rn | grep "^0.0.0.0 " | cut -d " " -f10)

# start antilibrary worker
echo ' '
echo '#######################################################################'
echo ' '
echo 'Running Antilibrary Worker'
ruby /home/vagrant/antilibrary_worker.rb