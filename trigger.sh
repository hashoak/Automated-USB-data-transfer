#!/usr/bin/sh

exec > /tmp/udev.log 2>&1
date

path1=`findmnt $1 -o TARGET | awk '/\//{print}'`
echo $path1
path2="/home/hash"

# if [ ! -d "$path1/Data/timeout.txt" ]; then
#     mkdir -p $path1/Data
#     touch $path1/Data/timeout.txt
#     echo 60 > $path1/Data/timeout.txt
# fi
# t=`cat $path1/Data/timeout.txt`

# x=$((t-2))

# timeout -s SIGINT $x bash -c \
# 'rsync $path2/Data/Take $path2/Data/Received/; \
# rsync $path2/Data/Send/ $path2/Data/Give/ '


# sleep 10

umount -l $path1

echo done