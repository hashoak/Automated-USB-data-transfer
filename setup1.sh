#!/usr/bin/sh

if [ $USER != "root" ]
  then echo "Please run as root"
  exit 0
fi

rulefile="/etc/udev/rules.d/99-usb.rules"
trigfile="/usr/local/bin/trigger.sh"
local="/home/$SUDO_USER/Data"

echo "Directory of Udev Rule file: $rulefile"
echo "Directory of Trigger Script file: $trigfile"
echo "Directory of Local Storage folder: $local"

mkdir -m 777 -p $local/Send
mkdir -m 777 -p $local/Recv

echo "Local Directory created..."

filesys=$(findmnt -no SOURCE $(dirname $(pwd)))
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