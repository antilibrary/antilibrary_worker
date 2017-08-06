## Antilibrary worker


### About

Use this worker to donate harddrive space to storing books for the [Antilibrary](https://www.reddit.com/r/antilibrary/comments/6ow6tq/antilibrary_faq/) project. 

The files are stored on the [IPFS](https://ipfs.io/) network so the download bandwidth is shared among the peers.

### Is this secure?

Yes. The antilibrary worker will run inside an isolated virtual machine and it has no access to your computer.

If you're using a VPN, your ip will be hidden from the IPFS network.

By running the script inside the isolated VM and hiding your ip from the IPFS network, you will be as safe as I am (famous last words :) )

### Ubuntu install and run

- [Download and unzip this repository](https://github.com/antilibrary/antilibrary_worker/archive/master.zip)
- Open a terminal, browse to the unzipped folder and run: `bash provision/ubuntu_host.sh`
- During the setup you will be asked to run this command from another terminal: `./provision/pubsub.sh`
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
==> default:
==> default: Listening on: QmTwW5PyA8VaUY4cmjvcLqWTa8y3JPiuErKVoHPjBMRB4ssecretkeyword (keep this secret)
```

- This means your node is listening, now you need to send me your `Node nickname`, `Node ID` and `Secret keyword` so I can whitelist it on the tracker. Send this to [/u/antilibrary](https://www.reddit.com/user/antilibrary/) or antilibrary@protonmail.com

### Windows/Linux/Other install and Run

- [Download and install Vagrant](https://www.vagrantup.com/downloads.html) and [VirtualBox](https://www.virtualbox.org/wiki/Downloads)
- [Download and unzip IPFS](https://ipfs.io/docs/install/) (>=0.4.10)
- [Download and unzip this repository](https://github.com/antilibrary/antilibrary_worker/archive/master.zip)
- Browse to the antilibrary_worker folder and edit the file `config.yml` to set your node space, nickname and secret keyword
- Open a console (cmd on windows), browse to your IPFS folder and run:

```
ipfs init                                # this is required to run the next command
ipfs daemon --enable-pubsub-experiment   # this is the p2p messages listener used by antilibrary from within the VM
```

- Make sure you get a `Daemon is ready` message from the last command. The ipfs daemon must be running for the antilibrary worker to be able to communicate with the tracker.
- Open another console, browse to the antilibrary_worker folder and run `vagrant up`. This will run the worker inside the vagrant machine
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
==> default:
==> default: Listening on: QmTwW5PyA8VaUY4cmjvcLqWTa8y3JPiuErKVoHPjBMRB4ssecretkeyword (keep this secret)
```

- This means your node is listening, now you need to send me your `Node nickname`, `Node ID` and `Secret keyword` so I can whitelist it on the tracker. Send this to [/u/antilibrary](https://www.reddit.com/user/antilibrary/) or antilibrary@protonmail.com


### Important notes

- If you remove your vagrant box with `vagrant destroy` you will remove all books you have stored
- If you need to update the config.yml file, make sure to run `vagrant provision` to insert the new file into the vagrant box
- The ipfs daemon running on your machine (outside the vagrant box) is required just to receive and send the messages between the tracker and the worker


### FAQ


**How much bandwidth will this use?**

You should expect no more than 10GB per TB per month of books stored. So if you're donating 2TB you can expect a bandwidth usage of 20GB per month.

With that said, I must note that it is not possible to predict this with certainty. If someone decides to download the whole library you can expect that your node will have a higher bandwidth usage. Every file is stored in at least in 3 nodes to avoid excessive bandwidth usage from any single node.

**If I don't to contribute anymore, can I just delete everything and I'm good?**

While you could to that, the network will suffer if you do. Please let me know some time before if you are intending to stop seeding, this way I can spread the files you are sharing to other nodes before you leave.