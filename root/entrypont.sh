#!/usr/bin/bash

set -e

# start weston
weston -B headless-backend.so 2>&1 | tee /var/log/weston.log &

# init waydroid
waydroid init

# start waydroid session
waydroid session start 2>&1 | tee /var/log/waydroid.log &

# get ip address from waydroid
IP_ADDR=$(waydroid shell ip addr show eth0 | grep "inet " | awk '{print $2}' | cut -d/ -f1)

# wait for getting ip address
while [ -z "$IP_ADDR" ]; do
    sleep 1
    IP_ADDR=$(waydroid shell ip addr show eth0 | grep "inet " | awk '{print $2}' | cut -d/ -f1)
done

# forward waydroid :5555 port to host
iptables -t nat -A PREROUTING -p tcp --dport 5555 -j DNAT --to-destination $IP_ADDR:5555

# combine weston, waydroid logs
tail -f /var/log/weston.log /var/log/waydroid.log
