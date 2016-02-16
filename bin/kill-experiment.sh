#! /bin/bash
#
# This script kills any running memcached instances
#
# Usage ./kill-server <NUM_CLIENTS> <NUM_SERVERS>

if [ "$#" -ne 2 ]; then
  echo "Usage $0 <NUM_CLIENTS> <NUM_SERVERS>"
  exit 1
fi

NUM_CLIENTS=$1
NUM_SERVERS=$2

echo "Killing clients..."
for i in `seq 1 $NUM_CLIENTS`
do
  (echo "pkill -f 'bin/ycsb'; pkill -f 'java'" | ssh \
    jpfosi01@client-$i.dup.comp150.emulab.net &> /dev/null) &
done

echo "Killing servers..."
for i in `seq 1 $NUM_SERVERS`
do
  (echo "pkill memcached" | ssh jpfosi01@server-$i.dup.comp150.emulab.net &> \
    /dev/null) &
done

wait
