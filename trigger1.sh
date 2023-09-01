#!/usr/bin/sh

exec > /tmp/udev.log 2>&1
echo "Process PID: $$"
date

this="$(dmidecode -s system-serial-number)" # Serial number of this PC
echo "This PC's Serial ID: $this"

local=CHANGE                                # Directory of local storage
usb="/mnt/USB"                              # Directory of USB mount point
conf="$usb/Data/info.conf"                  # Directory of config file

echo "USB device location: $1"
echo "Local directory: $local"
echo "USB directory: $usb"

mkdir -p $usb                               # Create the mount point directory.
mount $1 $usb/                              # Mount the USB device to the mount point.
echo "USB device mounted..."

if [ ! -f "$conf" ]; then                   # If config file doesn't exist,
    printf "Config file not found...\nCreated...\n"
    mkdir -p $usb/Data                      # create one and put default
    echo 60 > $conf                         # timeout value of 60 sec.
else
    echo "Config file found..."
fi

if ! grep -q "$this" "$conf" ; then         # If this PC is not registered in the
    printf "PC not registered...\nRegistered...\n"
    echo $this >> $conf                     # config file, append it's serial number.
else
    echo "PC already registered..."
fi

t=$(head -1 $conf)                          # Store the timeout val in variable t.
[ $t -lt 30 ] && t=30                       # If t<30, make t=30
t=$(( t - 10 ))                             # 10 seconds buffer.

echo "Total time: $t"

mkdir -m 777 -p $local/Send                 # Make send and recv directories
mkdir -m 777 -p $local/Recv                 # in local PC
echo "Local directories created..."

i=2
while [ "$i" -le "$(wc -l $conf | awk '{print $1}')" ]; do  # For each PC available,
    pc="$(head -$i $conf | tail -1)"
    if [ "$pc" != "$this" ]; then                           # excluding this PC,
        echo "Current PC: $pc"
        mkdir -p $usb/Data/"$this-to-$pc"                   # Make this PC to other PC dir
        mkdir -p $usb/Data/"$pc-to-$this"                   # and other PC to this PC dir.
        echo "Data transfer directories created..."

        # To Sync the directories one after another:
        t1=$(du -s $usb/Data/"$this-to-$pc" | awk '{print $1}') # Calc timeout
        t2=$(du -s $usb/Data/"$pc-to-$this" | awk '{print $1}') # according to
        t1=$(( t * t2 / ( t1 + t2 ) ))                          # the size of
        t2=$(( t - t1 ))                                        # the directories.

        echo "Time for first transfer: $t1"
        echo "Time for second transfer: $t2"
        # Sync the directories with timeouts t1 and t2.
        timeout $t1 rsync -azq -partial --append --remove-source-files \
        $local/Send/ $usb/Data/"$this-to-$pc"
        timeout $t2 rsync -azq -partial --append --remove-source-files \
        $usb/Data/"$pc-to-$this"/ $local/Recv
        echo "Transfer done..."

        # # To sync both the directories PARALLELLY:
        # timeout $t bash -c 'rsync -azq -partial --append --remove-source-files \
        # $local/Send/ $usb/Data/"$this-to-$pc" & \
        # timeout $t2 rsync -azq -partial --append --remove-source-files \
        # $usb/Data/"$pc-to-$this"/ $local/Recv'
        # echo "Transfer done..."
    fi
    i=$(( i + 1 ))
done

umount $1                                   # Unmount the USB device
eject $1                                    # Eject the USB device
echo "USB device Ejected"

echo done
echo ---------------------------
