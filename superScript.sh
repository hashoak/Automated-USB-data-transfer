#!/usr/bin/sh

exec > /tmp/usb.log 2>&1
echo "=================\e[1;34m Process Started \e[0m================="
echo "Process PID: $$"
date

s=$(date +%s)                       # Start time

localdir=/home/USER/usb-data        # Directory of local storage
usbdir=/media/USER/usb              # Directory of USB mount point

if [ ! -d "$localdir" -o ! -d "$usbdir" ]; then
    echo "\e[1;31mData Directories Inexistent\e[0m"
    echo "\e[0;33m└─Run setup to create required directories.\e[0m"
    exit 1
fi

if [ "$(grep -oP "doTransfer=\K.*" "$localdir"/conf)" -eq 0 ]; then
    echo "\e[1;31mTransfer Stopped doTransfer=0\e[0m"
    echo "\e[0;33m└─Set doTransfer to 1.\e[0m"
    exit 1
fi

this=$(grep -oP "thisPC=\K.*" "$localdir"/conf)     # This PC's number
echo "This PC's number: $this"

echo "USB device location: $1"
echo "Local directory: $localdir"
echo "USB directory: $usbdir"

mkdir -p $usbdir                    # Create the mount point directory.
mount $1 $usbdir                    # Mount the USB device to the mount point.
echo "USB device mounted..."

# clamscan -ri --bytecode=yes --bell --leave-temps $usbdir       # Virus scan on USB

if [ "$(grep -oP "serial=\K.*" "$localdir/conf")" != "$(grep -oP "PC$this=\K.*" "$usbdir/Data/conf")" ]; then
    echo "\e[1;31mPC Number Mismatch\e[0m"
    echo "\e[0;33m└─Run setup to change PC numbers.\e[0m"
    exit 1
fi

t=$(grep -oP "timeout=\K.*" "$usbdir/Data/conf")    # Store the timeout val in variable t.
[ $t -lt 60 ] && t=60                               # If t<60, make t=60
t=$(( t - ( $(date +%s) - $s + 30 ) ))              # Removing Virus scan time and 30 seconds buffer.
echo "Total time: $t"

other=$(( 1 + $this % 2 ))                          # Other PC's number

# To Sync the directories one after another:
t1=$(du -s "$localdir/Send" | awk '{print $1}')                 # Calc timeout
t2=$(du -s "$usbdir/Data/$other-to-$this" | awk '{print $1}')   # according to
t1=$(( t * t1 / ( t1 + t2 ) ))                                  # the size of
t2=$(( t - t1 ))                                                # the directories.
echo "Time for Send transfer: $t1"
echo "Time for Recv transfer: $t2"

echo "Transfer stared..."
printf "\n$(date) - SENT\n" >> "$localdir/History"  # Make send history entry.
while read -r dir ; do                              # Delete the files which
    if [ -f "$localdir/Send/$dir" ]; then           # are successfully
        rm "$localdir/Send/$dir"                    # transferred.
        echo "$dir" >> "$localdir/History"; fi      # Append sent file name.
done < "$usbdir/Data/$this-to-$other/todelete"
find $localdir/Send/* -type d -empty -delete        # Remove empty directories.

todeletefile="$usbdir/Data/$other-to-$this/todelete"

# Sync the directories with timeouts t1 and t2.
du -ha $usbdir/Data/$this-to-$other/*
echo "-----------------\e[1;32m Sending Started \e[0m-----------------"
timeout -k 5 $t1 nocache rsync -aPh --no-o --no-g --append \
$localdir/Send/ "$usbdir/Data/$this-to-$other/"
echo "------------------\e[1;31m Sending Done \e[0m-------------------"

ps -e | grep rsync
lsof -w | grep $usbdir

echo "----------------\e[1;32m Receiving Started \e[0m----------------"
timeout -k 5 $t2 nocache rsync -aPh --append --remove-source-files \
--exclude 'todelete' "$usbdir/Data/$other-to-$this/" "$localdir/Recv/"
echo "-----------------\e[1;31m Receiving Done \e[0m------------------"

find $usbdir/Data/$other-to-$this/* -type d -empty -delete

find $localdir/Recv/* -type f ! -user root | \
cut -c $(( ${#localdir} + 7 ))- > "/tmp/temp.txt"
echo "$(diff /tmp/temp.txt $todeletefile | grep "^< ")" | \
cut -c 3- >> $todeletefile
printf "\n$(date) - RECEIVED\n" >> "$localdir/History"
cat $todeletefile >> "$localdir/History"                    # Update Recv History
echo "$(sort -n $todeletefile | uniq)" > $todeletefile      # Update todelete log
echo "Transfer done..."
du -ha $usbdir/Data/$this-to-$other/*

sync
echo "synced"
until umount -v $usbdir; do sleep 1; done   # Unmount the USB device
udisksctl power-off -b $1                   # Disconnect the USB device
rmdir $usbdir
echo "USB device Disconnected"

echo "==================\e[1;32m Process Done \e[0m==================="