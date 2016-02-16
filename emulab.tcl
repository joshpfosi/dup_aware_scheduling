# This is a simple ns script developed from https://wiki.emulab.net/wiki/Emulab/wiki/Tutorial
set ns [new Simulator]                  
source tb_compat.tcl

set num_servers 8
set num_clients 24

for {set i 1} {$i <= $num_servers} {incr i} {
  set server($i) [$ns node]
  append lanstr "$server($i) "
  tb-set-node-os $server($i) UBUNTU14-64-STD
  tb-set-hardware $server($i) d430
}

for {set i 1} {$i <= $num_clients} {incr i} {
  set client($i) [$ns node]
  append lanstr "$client($i) "
  tb-set-node-os $client($i) UBUNTU14-64-STD
  tb-set-hardware $client($i) pc3000
}

# Put all the nodes in a lan
set big-lan [$ns make-lan "$lanstr" 1Gb 0ms]

# Allows routing
$ns rtproto Static

$ns run                                 
