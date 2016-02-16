#! /bin/bash
#
# This script runs a Memcached server on Emulab
#
# Usage: ./run-server <PORT> <CONNS_PER_SERVER> <NUM_THREADS>

if [ "$#" -ne 3 ]; then
  echo "Usage $0 <PORT> <CONNS_PER_SERVER> <NUM_THREADS>"
  exit 1
fi

cd /usr/local/comp112/memcached
./memcached -p $1 -t $3

