###Antilibrary worker


####About

Use this worker to donate harddrive space to storing books for the [Antilibrary](https://www.reddit.com/r/antilibrary/comments/6ow6tq/antilibrary_faq/) project. 

The files are stored on IPFS so the download badnwidth is shared among the peers.

####Install

- [Download and install IPFS](https://ipfs.io/docs/install/)
- Download and install ruby (>2.3)) ([windows](https://rubyinstaller.org/) / [linux - mac](https://www.ruby-lang.org/en/documentation/installation/))
- Copy and paste the content of [antilibrary_worker.rb](#) to a file in your machine
- Open the file `antilibrary_worker.rb` with a text editor and set the variable `IPFS_BIN_PATH` to the IPFS binary file.

```
# Set IPFS_BIN_PATH with the full path to your ipfs bin file (it cannot be a relative path)
# Windows example: 
# IPFS_BIN_PATH = 'C:/go-ipfs/ipfs.exe'
# Linux example:
IPFS_BIN_PATH = './ipfs'
```

- Run the script with `ruby antilibrary_worker.rb -h` to see how to define your settings. Example run:

```
ruby al_worker.rb --storage-limit=1000GB --nickname=i_seed_books --secret_keyword=MyVerYSecreTkeyWORD
```

- Once you run it with your chosen settings you should see something like this:

```
Starting worker...
Getting local ipfs repo stat (this may take a while)...[DONE]

Starting node with the following settings (Make sure you've sent me this information - /u/antilibrary):
  Node nickname: my_node_1
  Node ID: QmSaUU735BcyNJ3aJpmSBDtYfAy1DYxjA4LacHh3uCjXtL
  Secret keyword: not_so_secret

Sending handshake message to tracker...[DONE]
```

- Now you need to send me your `Node nickname`, `Node ID` and `Secret keyword` so I can whitelist it on the tracker. Send this to [/u/antilibrary](https://www.reddit.com/user/antilibrary/) or antilibrary@protonmail.com
