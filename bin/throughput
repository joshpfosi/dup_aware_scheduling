# /bin/bash
#
# The pipeline below process output from experiment.sh, averaging throughputs
# for identical experiments.

sed '/-.*/d' | ./fun_cat | ./aggregate | sort -n --key=2 | less
