#!/usr/bin/sh

exec > /tmp/udev.log 2>&1
echo "Process PID: $$"
date

local=CHANGE                                # Directory of local storage
usb="/mnt/USB"                              # Directory of USB mount point
conf="$usb/Data/info.conf"                  # Directory of config file

x=$(grep -oE "/PC-[0-9]* Data" "$local")
this=${x:4:${#x}-9}
echo "This PC's System number: $this"

echo "USB device location: $1"
echo "Local directory: $local"
echo "USB directory: $usb"

mkdir -p $usb                               # Create the mount point directory.
mount $1 $usb/                              # Mount the USB device to the mount point.
echo "USB device mounted..."

t=$(head -1 $conf)                          # Store the timeout val in variable t.
[ $t -lt 30 ] && t=30                       # If t<30, make t=30
t=$(( t - 10 ))                             # 10 seconds buffer.

echo "Total time: $t"

mkdir -m 777 -p $local/Send                 # Make send and recv directories
mkdir -m 777 -p $local/Recv                 # in local PC
echo "Local directories created..."

[ $this -eq 1 ] && pc=2; [ $this -eq 2 ] && pc=1

# To Sync the directories one after another:
t1=$(du -s "$usb/Data/$this-to-$pc" | awk '{print $1}') # Calc timeout
t2=$(du -s "$usb/Data/$pc-to-$this" | awk '{print $1}') # according to
t1=$(( t * t2 / ( t1 + t2 ) ))                          # the size of
t2=$(( t - t1 ))                                        # the directories.
echo "Time for first transfer: $t1"
echo "Time for second transfer: $t2"

while read -r dir ; do
    if [ -f "$dir" ]; then
        rm "$dir"
    else
        rmdir --ignore-fail-on-non-empty "$dir"
    fi
done < "$usb/Data/$this-to-$pc/stat"

statfile="$usb/Data/$pc-to-$this/stat"

# Sync the directories with timeouts t1 and t2.
timeout $t1 rsync -azq --partial --append \
$local/Send/ "$usb/Data/$this-to-$pc"
timeout $t2 rsync -azq --partial --append --remove-source-files --out-format="%n" \
"$usb/Data/$pc-to-$this"/ $local/Recv > $statfile
echo "Transfer done..."

[ $? ] && printf "$(head -n -1 $statfile)" > $statfile

# # To sync both the directories PARALLELLY:
# timeout $t bash -c 'rsync -azq --partial --append --remove-source-files \
# $local/Send/ "$usb/Data/$this-to-$pc" & \
# timeout $t2 rsync -azq --partial --append --remove-source-files \
# "$usb/Data/$pc-to-$this"/ $local/Recv'
# echo "Transfer done..."

umount $1                                   # Unmount the USB device
eject $1                                    # Eject the USB device
echo "USB device Ejected"

echo done
echo ---------------------------
