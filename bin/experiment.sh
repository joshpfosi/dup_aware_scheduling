#! /bin/bash
#
# Usage sh run-client <WORKLOAD> <CONNS_PER_SERVER> <NUM_THREADS> <OUTPUT> <NUM_CLIENTS> <NUM_SERVERS>

if [ "$#" -ne 9 ]; then
  echo "Usage $0 <WORKLOAD> <CONNS_PER_SERVER> <NUM_THREADS> <OUTPUT> \
  <RECORDSIZE> <CLIENT_THREADS> <NUM_CLIENTS> <NUM_SERVERS> <NUM_OPS>"
  exit 1
fi

OUTPUT_DIR=$4_data/

PORT=5555
WORKLOAD=$1
CONNS_PER_SERVER=$2
NUM_THREADS=$3
OUTPUT=$4
RECORDSIZE=$5
CLIENT_THREADS=$6
NUM_CLIENTS=$7
NUM_SERVERS=$8
NUM_OPS=$9

MAX_CONNS=1024
REQ_CONNS=$(($NUM_THREADS * $CONNS_PER_SERVER * $CLIENT_THREADS * $NUM_CLIENTS))

if [ $REQ_CONNS -ge $MAX_CONNS ]; then
  echo "Too many client connections ($REQ_CONNS). Memcached only supports $MAX_CONNS."
  exit 1
fi

rm -rf $OUTPUT_DIR
mkdir -p $OUTPUT_DIR

SSH="ssh -o ServerAliveInterval=100"

for i in `seq $NUM_SERVERS`
do
  HOST=jpfosi01@server-$i.dup.comp150.emulab.net
  echo "Booting $HOST..."
  cat run-server.sh | $SSH $HOST bash -s - $PORT $CONNS_PER_SERVER $NUM_THREADS &
done

# ------------------------------------------------------------------------------
# Run clients
# ------------------------------------------------------------------------------

echo $@ | tee -a $OUTPUT_DIR/$OUTPUT.data $OUTPUT_DIR/$OUTPUT-debug.data > /dev/null

for i in `seq $NUM_CLIENTS`
do
  (
  echo "Running YCSB on client-$i: workload=$WORKLOAD"
  cat run-client.sh | $SSH jpfosi01@client-$i.dup.comp150.emulab.net bash -s - \
    $PORT $WORKLOAD $CONNS_PER_SERVER $NUM_THREADS $RECORDSIZE $CLIENT_THREADS $NUM_SERVERS \
    $NUM_OPS 2> $OUTPUT_DIR/$OUTPUT-$i-debug.data | tee -a \
    $OUTPUT_DIR/$OUTPUT-$i-debug.data | grep Throughput\|AverageLatency | cut -d"," -f3 | \
    xargs >> $OUTPUT_DIR/$OUTPUT.data
  ) &
  pids[$i]=$!
done

for pid in ${pids[*]}; do wait $pid; done;

#
# Gather stats from each server and echo to $OUTPUT_server.data
#

# echo "Saving STATS from servers to $OUTPUT\_server.data..."
# for i in `seq 1 $NUM_SERVERS`
# do
#   read cmd_get cmd_set <<< `echo "stats" | nc server-$i.dup.comp150.emulab.net $PORT | grep "cmd_get\|set" | cut -d" " -f3`
#   cmd_get="${cmd_get/$'\r'/}" ; cmd_set="${cmd_set/$'\r'/}" ; total=`expr $cmd_get + $cmd_set`
#   echo "$i $total $CONNS_PER_SERVER" >> $OUTPUT\_server.data
#   # Use CONNS_PER_SERVER to color scatter plot by unaware/aware
# done

sh kill-experiment.sh $NUM_CLIENTS $NUM_SERVERS
