#!/bin/bash
# run ipfs in a screen if it's not already running
if [ -z "$STY" ]; then exec screen -dm -S pubsub /bin/bash "$0"; fi
	
# start ipfs
if ! pgrep -x "ipfs" > /dev/null; then
  ipfs init
fi

# run host daemon
if ! curl --silent localhost:5001 > /dev/null; then
  ipfs daemon --enable-pubsub-experiment
fi