#!/usr/bin/bash

path="/dev/safety1"

mount $path /mnt/hd

t=`cat /mnt/hd/Data/timeout.txt`

x=$((t-2))

/usr/bin/date >> /tmp/udev.log

timeout -s SIGINT $x bash -c 'rsync /mnt/hd/Data/Take /home/hash/Data/Received/; rsync /home/hash/Data/Send/ /mnt/hd/Data/Give'

umount $path

echo done
