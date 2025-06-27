#!/bin/bash

# numactl -H
# available: 3 nodes (0-2)
# node 0 cpus: 0 1
# node 0 size: 1950 MB
# node 0 free: 1805 MB
# node 1 cpus: 2 3
# node 1 size: 1980 MB
# node 1 free: 1591 MB
# node 2 cpus:
# node 2 size: 3968 MB
# node 2 free: 3618 MB
# node distances:
# node     0    1    2 
#    0:   10   20   20 
#    1:   20   10   20 
#    2:   20   20   10 

echo 1 > /proc/sys/kernel/numa_balancing
echo 1 > /sys/kernel/mm/numa/demotion_enabled
echo online_movable >/sys/devices/system/memory/auto_online_blocks
ndctl create-namespace -f -e namespace0.0 --mode devdax
daxctl reconfigure-device --mode system-ram dax0.0 --movable --force
daxctl online-memory dax0.0 --movable 2>/dev/null

log=$(date +%s)
numactl -m 0-1 memhog -r200 3900M >/dev/null &
pid=$!
sleep 2
timeout 44 numactl memhog -r1000 2500M >/dev/null &

prefix=promotion
uname -a | grep -q nopatch && prefix=promotion-nopatch

mkdir -p $prefix
sar_log=$prefix/sar-"$log".log
pmbench_log=$prefix/pmbench-"$log".log
touch $sar_log $pmbench_log

echo "log_file: $sar_log $pmbench_log"

sleep 10
./pmbench/pmbench -m 4900 -j 4 -s 128 -a histo -c 30 >$pmbench_log &
pmbench_pid=$!

sar -B 1 >$sar_log &
sar_pid=$!

kill -9 $pid

echo 2 > /proc/sys/kernel/numa_balancing

wait $pmbench_pid
kill -9 $sar_pid
