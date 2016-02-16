#! /bin/bash
#
# Runs all workloads many times
#
# Usage: sh run-experiments.sh

if [ "$#" -ne 2 ]; then
  echo "Usage $0 <NUM_CLIENTS> <NUM_SERVERS>"
  exit 1
fi

NUM_CLIENTS=$1
NUM_SERVERS=$2

sh kill-experiment.sh $NUM_CLIENTS $NUM_SERVERS

# DUPLICATE UNAWARE

workloads="workload1 workload2 workloada workloadb workloadc workloadd workloade workloadf"
iterations=2
sizes="1000 5000"

echo "Building YCSB duplicate unaware..."
rm -rf YCSB
cp -r YCSB_unaware YCSB
sh build-ycsb.sh 1

for i in `seq 0 $iterations`;
do
  for RECORDSIZE in $sizes;
  do
    for workload in $workloads;
    do
      echo "Iteration $i (unaware): $workload w/ fieldlength = $RECORDSIZE ..."
      sh experiment.sh $workload 1 4 $workload $RECORDSIZE 1 4
    done
  done
done

# DUPLICATE AWARE SCHEDULING

echo "Building YCSB duplicate aware..."
rm -rf YCSB
cp -r YCSB_aware YCSB
sh build-ycsb.sh 1
cat make-dup-aware.sh | ssh jpfosi01@server-1.dup.comp150.emulab.net

for i in `seq 0 $iterations`;
do
  for RECORDSIZE in $sizes;
  do
    for workload in $workloads;
    do
      echo "Iteration $i (aware): $workload w/ fieldlength = $RECORDSIZE ..."
      sh experiment.sh $workload 2 4 $workload $RECORDSIZE 1 4
    done
  done
done

rm -rf YCSB

for workload in $workloads;
do
  echo "Plotting throughput for $workload..."
  sh plot-throughput.sh "Servers" "Throughput (ops / sec)" "Server Throughput" \
    $workload.data $workload\_throughput.png

  echo "Plotting load for $workload..."
  sh plot-load.sh "Servers" "Requests (total)" "Server Load" \
    $workload\_server.data $workload\_load.png
done
