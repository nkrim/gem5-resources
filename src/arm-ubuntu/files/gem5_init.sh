#!/bin/bash

# mount /proc and /sys
mount -t proc /proc /proc
mount -t sysfs /sys /sys
# Read /proc/cmdline and parse options
cmdline=$(cat /proc/cmdline)
no_systemd=false

# Load gem5_bridge driver
## Default parameters (ARM64)
gem5_bridge_baseaddr=0x10010000
gem5_bridge_rangesize=0x10000
## Try to read overloads from kernel arguments
if [[ $cmdline =~ gem5_bridge_baseaddr=([[:alnum:]]+) ]]; then
    gem5_bridge_baseaddr=${BASH_REMATCH[1]}
fi
if [[ $cmdline =~ gem5_bridge_rangesize=([[:alnum:]]+) ]]; then
    gem5_bridge_rangesize=${BASH_REMATCH[1]}
fi
## Insert driver
modprobe gem5_bridge \
    gem5_bridge_baseaddr=$gem5_bridge_baseaddr \
    gem5_bridge_rangesize=$gem5_bridge_rangesize

# gem5-bridge exit signifying that kernel is booted
printf "Kernel booted, starting gem5 init...\n"
echo 0 > /dev/gem5/exit # TODO: Make this a specialized event.

if [[ $cmdline == *"no_systemd"* ]]; then
    no_systemd=true
fi

# Run systemd via exec if not disabled
if [[ $no_systemd == false ]]; then
    printf "Starting systemd...\n"
    exec /lib/systemd/systemd
else
    printf "Dropping to shell as gem5 user...\n"
    exec su - gem5
fi
