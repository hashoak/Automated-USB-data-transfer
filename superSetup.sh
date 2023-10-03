#!/usr/bin/sh

if [ $USER != "root" ]; then
    echo "Please run as root"
    exit 1
fi

echo "==================\e[1;34m Setup Started \e[0m=================="

ruledir="/etc/udev/rules.d/99-usb.rules"
servicedir="/etc/systemd/system/usb@.service"
scriptdir="/usr/local/bin/usb.sh"
localdir="/home/$SUDO_USER/usb-data"

echo "Rule file: $ruledir"
echo "Service file: $servicedir"
echo "Script file: $scriptdir"
echo "Local Storage: $localdir"

echo "Installing source files..."
install -o root -g root -m 644 rule $ruledir        # Create Rule file
install -o root -g root -m 644 service $servicedir  # Create Service file
install -o root -g root -m 744 script $scriptdir    # Create script file

usbdir=$(dirname $(pwd))
userial=$(udevadm info $(findmnt -no SOURCE $usbdir) | grep -oP "ID_SERIAL=\K.*")

echo "Setting variables..."
sed -i "s|SERIALID|$userial|" $ruledir      # Assign Serial ID in Rule file
sed -i "s|USER|$SUDO_USER|" $scriptdir      # Assign Local dir in Script file

localconf="$localdir/conf"
usbconf="$usbdir/Data/conf"
cserial=$(dmidecode -s chassis-serial-number)

echo "Creating data files..."
mkdir -m 777 -p "$localdir/Send"            # Create local send and
mkdir -m 777 -p "$localdir/Recv"            # recieve directories.
touch "$localdir/History"                   # Create history file.
mkdir -p "$usbdir/Data/1-to-2"              # Make this PC to other PC dir
mkdir -p "$usbdir/Data/2-to-1"              # and other PC to this PC dir.
touch "$usbdir/Data/1-to-2/todelete"        # Create todelete files in both
touch "$usbdir/Data/2-to-1/todelete"        # 1-to-2 and 2-to-1 directories.

if [ ! -f "$localconf" ]; then              # If config file doesn't exist,
    echo "Local config file created..."     # create one and set doTransfer
    echo "serial=$cserial" > $localconf     # to 1 and thiPC to 0.
    echo "doTransfer=1" >> $localconf       # to 1 and thiPC to 0.
    echo "thisPC=0" >> $localconf
else
    echo "Local config file found..."
    if [ $(grep -oP "doTransfer=\K.*" "$localdir/conf") -eq 0 ]; then
        echo "\e[0;33m└─doTransfer set to 0. Make it 1 to enable tranfer.\e[0m"
    fi
fi

if [ ! -f "$usbconf" ]; then                # If config file doesn't exist,
    echo "USB config file created..."       # create one and put default
    echo "timeout=60" > $usbconf            # timeout value of 60 sec.
else
    echo "USB config file found..."
fi

this=$(grep -oE "PC[1-2]=$cserial" $usbconf)
if [ $this ]; then this=$(echo $this | cut -c3)
elif [ ! $(grep "PC1=" $usbconf) ]; then this=1     # Check which numbers are
elif [ ! $(grep "PC2=" $usbconf) ]; then this=2     # occupied and which are
else                                                # not. And assign a
    echo "All system numbers occupied..."           # number to this PC.
    tail +2 "$usbconf"
    while [ "$this" != 1 -a "$this" != 2 ]; do                      # If both the numbers
        echo -n "Choose which system to replace (1/2): "; read this # are occupied, ask
    done                                                            # which PC to replace.
    printf "$(grep -v "PC$this=" $usbconf)\n" > $usbconf
fi
echo "System numbered as $this..."
[ ! $(grep "PC$this=" $usbconf) ] && echo "PC$this=$cserial" >> $usbconf    # Add the PC to conf file.

sed -i "/thisPC=/{s/[0-2]/$this/g}" $localconf

echo "Reloading Systemd and Udev..."
udevadm control -R                          # Reload Udev
systemctl daemon-reload                     # Reload Systemd

if ! which rsync > /dev/null; then
    echo "Installing rsync..."
    dpkg -i rsync_3.1.3-6_amd64.deb > /dev/null
fi

if ! which nocache > /dev/null; then
    echo "Installing nocache..."
    dpkg -i nocache_1.1-1_amd64.deb > /dev/null
fi

echo "=================\e[1;32m Setup Successful \e[0m================"