#! /bin/bash
#
# This script runs the Python YCSB script on Emulab

if [ "$#" -ne 8 ]; then
  echo "Usage $0 <PORT> <WORKLOAD> <CONNS_PER_SERVER> <NUM_THREADS> <RECORDSIZE> \
  <CLIENT_THREADS> <NUM_SERVERS> <NUM_OPS>"
  exit 1
fi

PORT=$1
WORKLOAD=$2
CONNS_PER_SERVER=$3
NUM_THREADS=$4
RECORDSIZE=$5
CLIENT_THREADS=$6
NUM_SERVERS=$7
NUM_OPS=$8

cd /usr/local/comp112/YCSB

for i in `seq $NUM_SERVERS`; do SERVERS="$SERVERS server-$i.dup.comp150.emulab.net"; done
SERVERS=`echo $SERVERS | sed 's/^ *//g'`
SERVERS="memcached.servers=$SERVERS"

./bin/ycsb load memcached -s -P workloads/$WORKLOAD -p "memcached.port=$PORT" -p "$SERVERS" \
 -p "memcached.connsPerServer=$CONNS_PER_SERVER" -p \
"memcached.numThreads=$NUM_THREADS" -p "fieldlength=$RECORDSIZE" -p \
"requestdistribution=uniform" -p "recordcount=$NUM_OPS" -threads $CLIENT_THREADS &> /dev/null

# Send to /dev/null as we do not care about it's throughput

./bin/ycsb run memcached -s -P workloads/$WORKLOAD -p "memcached.port=$PORT" -p "$SERVERS" \
-p "memcached.connsPerServer=$CONNS_PER_SERVER" -p \
"memcached.numThreads=$NUM_THREADS" -p "fieldlength=$RECORDSIZE" -p \
"requestdistribution=uniform" -p "recordcount=$NUM_OPS" -threads $CLIENT_THREADS

if [ $? -ne 0 ]
then
  echo "YCSB FAILED..."
  exit 1
fi
