## Antilibrary worker


### About

Use this worker to donate harddrive space to storing books for the [Antilibrary](https://www.reddit.com/r/antilibrary/comments/6ow6tq/antilibrary_faq/) project. 

The files are stored on IPFS so the download bandwidth is shared among the peers.

### Is this secure?

Yes. The script will run inside an isolated virtual machine and it has no access to your computer.

If you're using a VPN, your ip will be hidden from the IPFS network.

By running the script inside the isolated VM and hiding your ip from the IPFS network, you will be as safe as I am (famous last words :) )

### Run with Vagrant (recommended)

- [Download and install Vagrant](https://www.vagrantup.com/downloads.html) and [VirtualBox](https://www.virtualbox.org/wiki/Downloads)
- [Download this repository](https://github.com/antilibrary/antilibrary_worker/archive/master.zip) and unzip on your computer
- Edit the file `config.yml` and set your node space, nickname and secret keyword.
- Open your console and run `vagrant up` inside the unzipped directory. This will run the worker inside the vagrant machine.
- Once everything is finished you should see something like:

```
==> default: #######################################################################
==> default:
==> default: Running Antilibrary Worker
==> default:
==> default: Starting Antilibrary worker with the following settings (Make sure you've sent me this information - /u/antilibrary):
==> default:   Node nickname: [YOUR_NODE_NICKNAME]
==> default:   Node ID: QmTwW5PyA8VaUY4cmjvcLqWTa8y3JPiuErKVoHPjBMRB4s
==> default:   Secret keyword: [SECRET_KEYWORD_YOU_DEFINED]
```

- This means your node is listening, now you need to send me your `Node nickname`, `Node ID` and `Secret keyword` so I can whitelist it on the tracker. Send this to [/u/antilibrary](https://www.reddit.com/user/antilibrary/) or antilibrary@protonmail.com
- Please note that if you remove your vagrant box with `vagrant destroy` you will remove all books you have stored.
- If you need to update the config.yml file, make sure to run `vagrant provision` to insert the new file into the vagrant box.

### Run with ruby

- [Download and install IPFS](https://ipfs.io/docs/install/) (>=0.4.10)
- Download and install ruby (>=2.0)) ([windows](https://rubyinstaller.org/) / [linux - mac](https://www.ruby-lang.org/en/documentation/installation/))
- [Download this repository](https://github.com/antilibrary/antilibrary_worker/archive/master.zip) and unzip on your computer
- Edit the file `config.yml` and set your node space, nickname and secret keyword.
- Run the script with `ruby antilibrary_worker.rb`
- Once you run it with your chosen settings you should see something like this:

```
Starting node with the following settings (Make sure you've sent me this information - /u/antilibrary):
  Node nickname: my_node_1
  Node ID: QmSaUU735BcyNJ3aJpmSBDtYfAy1DYxjA4LacHh3uCjXtL
  Secret keyword: not_so_secret

Getting local ipfs repo stat (this may take a while)...[DONE]
Sending handshake message to tracker...[DONE]
```

- Now you need to send me your `Node nickname`, `Node ID` and `Secret keyword` so I can whitelist it on the tracker. Send this to [/u/antilibrary](https://www.reddit.com/user/antilibrary/) or antilibrary@protonmail.com
