#! /bin/bash
#
# Script to copy YCSB/workloads/* over to Emulab clients' directories
#
# Usage: sh load-workloads.sh <NUM_CLIENTS>

if [ "$#" -ne 1 ]; then
  echo "Usage: $0 <NUM_CLIENTS>"
  exit 1
fi

NUM_CLIENTS=$1

for i in `seq $NUM_CLIENTS`;
do
  (
  HOST=jpfosi01@client-$i\.dup.comp150.emulab.net
  scp ./YCSB/workloads/* $HOST:/usr/local/comp112/YCSB/workloads/
  ) &
done

wait
