#! /bin/bash
#
# Generate basic scatter plot
#
# Usage: sh plot-load.sh <XLABEL> <YLABEL> <TITLE> <DATA> <OUTPUT>

if [ "$#" -ne 5 ]; then
  echo "Usage: $0 <XLABEL> <YLABEL> <TITLE> <DATA> <OUTPUT>"
  exit 1
fi

XLABEL=$1
YLABEL=$2
TITLE=$3
DATA=$4
OUTPUT=$5

gnuplot -e "set terminal png;\
  unset colorbox;
  set xrange [-1:4];
  set xlabel '$XLABEL';\
  set ylabel '$YLABEL';\
  set output '$OUTPUT';\
  set title '$TITLE';\
  plot '$DATA' with points palette"
