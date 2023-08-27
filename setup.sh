#!/usr/bin/sh

# exec > /tmp/udev.log 2>&1
# echo "Process PID: $$"
# date

if [ $USER != "root" ]
  then echo "Please run as root"
  exit 0
fi

rulefile="/etc/udev/rules.d/80-usb.rules"
trigfile="/usr/local/bin/trigger1.sh"

echo -n "Enter the storage directory: "
read local

mkdir -m 777 -p $local/Send
mkdir -m 777 -p $local/Recv

filesys=$(findmnt -no SOURCE $(dirname $(pwd)))
serial=$(udevadm info $filesys | grep "ID_SERIAL=" | cut -c 14-)

ruledata=$(printf "ACTION==\"add\", KERNEL==\"sd[a-z]1\", \
                  ENV{ID_SERIAL}==\"$serial\", \
                  RUN+=\"/usr/local/bin/trigger.sh '/dev/%%k'\"")
                  
echo $ruledata > $rulefile
cat code.txt > $trigfile
sed -i "s@CHANGE@$local@" $trigfile
chmod +x $trigfile

udevadm control -R

echo Setup Successful