#!/usr/bin/sh

exec > /tmp/udev.log 2>&1
echo "Process PID: $$"
date

this="$(dmidecode -s system-serial-number)" # Serial number of this PC
echo "This PC's Serial ID: $this"

local=/home/vit                                # Directory of local storage
usb="/mnt/USB"                              # Directory of USB mount point
conf="$usb/Data/info.conf"                  # Directory of config file

echo "Local dir: $local"
echo "USBdir: $usb"

mkdir -p $usb                               # Create the mount point directory.
mount $1 $usb                               # Mount the USB device to the mount point.

if [ ! -f "$conf" ]; then                   # If config file doesn't exist,
    printf "Config file not found.\nCreated.\n"
    mkdir -p $usb/Data                      # create one and put default
    echo 60 > $conf                         # timeout value of 60 sec.
fi

if ! grep -q "$this" "$conf" ; then         # If this PC is not registered
    printf "PC not registered.\nRegistered.\n"
    echo $this >> $conf                     # in the config file, append
fi                                          # it's serial number.

t=$(head -1 $conf)                          # Store the timeout val in variable t.
[ $t -lt 30 ] && t=30                       # If t<30, make t=30
t=$(( t - 10 ))                             # 10 seconds buffer.

echo "Total time: $t"

mkdir -m 777 -p $local/Send                 # Make send and recv directories
mkdir -m 777 -p $local/Recv                 # in local PC

i=2
while [ "$i" -le "$(wc -l $conf | awk '{print $1}')" ]; do  # For each PC available,
    pc="$(head -$i $conf | tail -1)"
    if [ "$pc" != "$this" ]; then                           # excluding this PC,
        echo "Current PC: $pc"
        mkdir -p $usb/Data/"$this->$pc"                     # Make this PC to other PC dir
        mkdir -p $usb/Data/"$pc->$this"                     # and other PC to this PC dir.

        # To Sync the directories one after another:
        t1=$(du -s $usb/Data/"$this->$pc" | awk '{print $1}')   # Calc timeout
        t2=$(du -s $usb/Data/"$pc->$this" | awk '{print $1}')   # according to
        t1=$(( t * t2 / ( t1 + t2 ) ))                          # the size of
        t2=$(( t - t1 ))                                        # the directories.

        echo "Time for first transf: $t1"
        echo "Time for second transf: $t2"
        # Sync the directories with timeouts t1 and t2.
        timeout $t1 rsync -az -partial --append --remove-source-files \
        $local/Send/ $usb/Data/"$this->$pc"
        timeout $t2 rsync -az -partial --append --remove-source-files \
        $usb/Data/"$pc->$this"/ $local/Recv

        # # To sync both the directories PARALLELLY:
        # timeout $t bash -c 'rsync -az -partial --append --remove-source-files \
        # $local/Send/ $usb/Data/"$this->$pc" & \
        # timeout $t2 rsync -az -partial --append --remove-source-files \
        # $usb/Data/"$pc->$this"/ $local/Recv'
    fi
    i=$(( i + 1 ))
done

eject $1                                  # eject the USB device

echo done
echo ---------------------------
