# install ipfs
if [[ ! -f "/usr/bin/ipfs" ]]; then 
  wget https://dist.ipfs.io/go-ipfs/v0.4.10/go-ipfs_v0.4.10_linux-amd64.tar.gz
  tar xzvf go-ipfs_v0.4.10_linux-amd64.tar.gz
  rm go-ipfs_v0.4.10_linux-amd64.tar.gz
  sudo mv go-ipfs/ipfs /usr/bin
  sudo chmod a+x /usr/bin/ipfs
fi

# install ruby
if [[ ! -f "/usr/bin/ruby2.4" ]]; then 
  sudo apt-add-repository -y ppa:brightbox/ruby-ng
  sudo apt update
  sudo apt install -y ruby2.4 ruby2.4-dev
fi

# start ipfs
if ! pgrep -x "ipfs" > /dev/null; then
  ipfs init
fi

# replace max ipfs storage with user defined value
sed -i "s/10GB/$(grep 'storage_limit:' config.yml | tail -n1 | awk '{ print $2}')GB/g" ~/.ipfs/config

# run guest daemon
if ! curl --silent localhost:5001 > /dev/null; then
  nohup ipfs daemon &
fi

while ! curl --silent localhost:5001 > /dev/null; do
  sleep 1
done

# get host ipfs daemon ip
export ipfs_api_addr=$(netstat -rn | grep "^0.0.0.0 " | cut -d " " -f10)

# start antilibrary worker
echo ' '
echo '#######################################################################'
echo ' '
echo 'Running Antilibrary Worker'
ruby /home/vagrant/antilibrary_worker.rb