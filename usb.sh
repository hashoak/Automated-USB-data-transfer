#!/usr/bin/sh

exec > /tmp/usb.log 2>&1
echo "===========\e[1;34m Process Started \e[0m==========="
echo "Process PID: $$"
date

s=$(date +%s)                       # Start time

localdir="/home/USER/usb-data"      # Directory of local storage
usbdir="/media/USER/usb"            # Directory of USB mount point

if [ $(grep "doTransfer=" "$localdir/conf" | cut -c 12-) -eq 0 ]; then
    echo "\e[1;31mTransfer Aborted\e[0m"
    echo "\e[0;33mdoTransfer set to 0. Make it 1 to make tranfer.\e[0m"
    exit 1
fi

this=$(grep "thisPC=" "$localdir/conf" | cut -c 8-)  # This PC's number
echo "This PC's number: $this"

echo "USB device location: $1"
echo "Local directory: $localdir"
echo "USB directory: $usbdir"

mkdir -p $usbdir                    # Create the mount point directory.
mount $1 $usbdir                    # Mount the USB device to the mount point.
echo "USB device mounted..."

# clamscan -ri --bytecode=yes --bell --leave-temps $usbdir   # Virus scan on USB

t=$(head -1 "$usbdir/Data/conf" | cut -c9-) # Store the timeout val in variable t.
[ $t -lt 60 ] && t=60                       # If t<60, make t=60
t=$(( t - ( $(date +%s) - $s + 10 ) ))      # Removing Virus scan time and 10 seconds buffer.
echo "Total time: $t"

other=$(( 1 + $this % 2 ))                  # Other PC's number

# To Sync the directories one after another:
t1=$(du -s "$localdir/Send" | awk '{print $1}')                 # Calc timeout
t2=$(du -s "$usbdir/Data/$other-to-$this" | awk '{print $1}')   # according to
t1=$(( t * t1 / ( t1 + t2 ) ))                                  # the size of
t2=$(( t - t1 ))                                                # the directories.
echo "Time for Send transfer: $t1"
echo "Time for Recv transfer: $t2"

echo "Transfer stared..."
printf "\n$(date) - SENT\n" >> "$localdir/History"      # Make send history entry.
while read -r dir ; do                                  # Delete the files which
    if [ -f "$localdir/Send/$dir" ]; then               # are successfully
        rm "$localdir/Send/$dir"                        # transferred.
        echo "$dir" >> "$localdir/History"; fi          # Append sent file name.
done < "$usbdir/Data/$this-to-$other/todelete"
find $localdir/Send/* -type d -empty -delete            # Remove empty directories.

todeletefile="$usbdir/Data/$other-to-$this/todelete"

# Sync the directories with timeouts t1 and t2.
echo "-----------\e[1;32m Sending Started \e[0m-----------"
timeout -k 5 $t1 rsync -aPh --no-o --no-g --append \
$localdir/Send/ "$usbdir/Data/$this-to-$other/"
echo "------------\e[1;31m Sending Done \e[0m-------------"

echo "----------\e[1;32m Receiving Started \e[0m----------"
timeout -k 5 $t2 rsync -aPh --append --remove-source-files \
--exclude 'todelete' "$usbdir/Data/$other-to-$this/" "$localdir/Recv/"
echo "-----------\e[1;31m Receiving Done \e[0m------------"

find $usbdir/Data/$other-to-$this/* -type d -empty -delete

find $localdir/Recv/* -type f ! -user root | \
cut -c `expr ${#local} + 7`- > "/tmp/temp.txt"
echo "$(diff /tmp/temp.txt $todeletefile | grep "^< ")" | \
cut -c 3- >> $todeletefile
printf "\n$(date) - RECEIVED\n" >> "$localdir/History"
cat $todeletefile >> "$localdir/History"                    # Update Recv History
echo "$(sort -n $todeletefile | uniq)" > $todeletefile      # Update todelete log
echo "Transfer done..."

umount -f $1                        # Unmount the USB device
eject -s $1                         # Eject the USB device
echo "USB device Ejected"

echo "============\e[1;32m Process Done \e[0m============="
