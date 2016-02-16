# This is a simple ns script developed from https://wiki.emulab.net/wiki/Emulab/wiki/Tutorial
set ns [new Simulator]                  
source tb_compat.tcl

set memcached0 [$ns node]
set memcached1 [$ns node]
set memcached2 [$ns node]
set memcached3 [$ns node]
set ycsbclient0 [$ns node]
set ycsbclient1 [$ns node]
set ycsbclient2 [$ns node]
set ycsbclient3 [$ns node]

set lan0 [$ns make-lan "$memcached0 $memcached1 $memcached2 $memcached3 $ycsbclient0 $ycsbclient1 $ycsbclient2 $ycsbclient3 " 10Gb 0ms]

# Set the OS on a couple.
tb-set-node-os $memcached0 UBUNTU14-64-STD
tb-set-node-os $memcached1 UBUNTU14-64-STD
tb-set-node-os $memcached2 UBUNTU14-64-STD
tb-set-node-os $memcached3 UBUNTU14-64-STD
tb-set-node-os $ycsbclient0 UBUNTU14-64-STD
tb-set-node-os $ycsbclient1 UBUNTU14-64-STD
tb-set-node-os $ycsbclient2 UBUNTU14-64-STD
tb-set-node-os $ycsbclient3 UBUNTU14-64-STD

# Allows routing
$ns rtproto Static

$ns run                                 

