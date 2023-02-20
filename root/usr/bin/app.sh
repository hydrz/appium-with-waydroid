#!/usr/bin/bash

set -e

# start waydroid session
waydroid session start 2>&1 | tee /var/log/waydroid.log &

sleep 3

# adb connect to waydroid
ipAddress=$(waydroid shell ip addr show eth0 | grep "inet " | awk '{print $2}' | cut -d/ -f1)
while [ -z "$ipAddress" ]; do
    echo "Waiting for waydroid to start"
    sleep 1
    ipAddress=$(waydroid shell ip addr show eth0 | grep "inet " | awk '{print $2}' | cut -d/ -f1)
done

echo "Waydroid started with ip address: $ipAddress"

adb connect $ipAddress:5555

# start appium
/usr/bin/appium --allow-cors 2>&1 | tee /var/log/appium.log &

# combine weston, waydroid and appium logs
tail -n 0 -f /var/log/waydroid.log /var/log/appium.log
