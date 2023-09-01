#!/usr/bin/sh

if [ $USER != "root" ]
  then echo "Please run as root"
  exit 1
fi

dir=$(dirname $(pwd))

if [ ! -f "$dir/Data/conf" ]; then                   # If config file doesn't exist,
    printf "Config file not found...\nCreated...\n"
    mkdir -p $dir/Data                      # create one and put default
    echo 60 > $dir/Data/conf                         # timeout value of 60 sec.
else
    echo "Config file found..."
fi

x=0
if [ ! $(grep "1" $dir/Data/conf) ]; then x=1
else if [ ! $(grep "2" $dir/Data/conf) ]; then x=2
else
    echo "All system numbers occupied..."
    tail +2 "$dir/Data/conf"
    while [ $x -ne 1 -a $x -ne 2 ]; do
        echo -n "Choose which system to replace (1/2): "; read x
    done
fi
echo "System numbered as $x..."; echo "$x-$(dmidecode -s system-serial-number)" >> $dir/Data/conf

rulefile="/etc/udev/rules.d/99-usb.rules"
trigfile="/usr/local/bin/trigger.sh"
local="/home/$SUDO_USER/PC-$x Data"

echo "Directory of Udev Rule file: $rulefile"
echo "Directory of Trigger Script file: $trigfile"
echo "Directory of Local Storage folder: $local"

mkdir -m 777 -p $local/Send
mkdir -m 777 -p $local/Recv
echo "Local Directory created..."

mkdir -p "$usb/Data/1-to-2"                   # Make this PC to other PC dir
mkdir -p "$usb/Data/2-to-1"                   # and other PC to this PC dir.

filesys=$(findmnt -no SOURCE $dir)
serial=$(udevadm info $filesys | grep "ID_SERIAL=" | cut -c 14-)

echo "Device location: $filesys"
echo "Device Serial ID: $serial"

ruledata=$(printf "ACTION==\"add\", KERNEL==\"sd[a-z]1\", \
                  ENV{ID_SERIAL}==\"$serial\", \
                  RUN+=\"/usr/local/bin/trigger.sh '/dev/%%k'\"")
                  
echo $ruledata > $rulefile
echo "Rule file created..."
cat code > $trigfile
sed -i "s@CHANGE@\"$local\"@" $trigfile
chmod +x $trigfile
echo "Trigger script created..."

udevadm control -R
echo "Udev rules reloaded..."

echo "Setup Successful"