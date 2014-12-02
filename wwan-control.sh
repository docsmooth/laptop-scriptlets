#!/bin/bash
#As root, issue the following commands (tested on an IBM T61 running Kubuntu 8):

helptext() {
    echo "has 4 options:"
    echo "'disable' which turns the device off"
    echo "'enable' which turns it back on"
    echo "'power' which takes it out of powersave"
    echo "'load' which loads wwan firmware"
    echo "'reload' which unloads and loads wwan firmware"
    echo ""
    echo "works against:"
    echo "bluetooth (bt)"
    echo "wwan (wan)"
}

if [ $UID -ne 0 ]; then
    echo "Must be run as root"
    helptext
    exit 1
fi

power_wan()
{
    echo 'at!pcstate=1' > /dev/ttyUSB0
}
unload_wan()
{
    ifdown ppp0
    /sbin/modprobe -r qcserial
    /sbin/modprobe -r usbserial
}
load_wan()
{
    echo enabled > /proc/acpi/ibm/$radio
    sleep 2
    /sbin/modprobe usbserial
    /sbin/modprobe qcserial
    sleep 2
#    /sbin/gobi_loader /dev/ttyUSB0 /lib/firmware/gobi
#    sleep 2
#    power_wan
    sleep 1
    ifup ppp0
}

load_bt()
{
    /sbin/modprobe btusb
    sleep 1
    echo enabled > /proc/acpi/ibm/$radio
    sleep 2
    rfkill unblock $radio
    sleep 1
    hciconfig hci0 up
}
unload_bt()
{
    echo disabled > /proc/acpi/ibm/$radio
    hciconfig hci0 down
    sleep 1
#    /sbin/modprobe -r btusb
}

#tail -f /dev/ttyUSB0 & pid=$!
if [ "$2" = "bt" ]; then
    radio="bluetooth"
elif [ "$2" = "wan" ]; then
    radio="wan"
elif [ "$2" = "bluetooth" ]; then
    radio="bluetooth"
elif [ "$2" = "wwan" ]; then
    radio="wan"
else
    echo "Error: Only 2 radio choices!"
    helptext
    exit 2
fi

# Lets you tail the modem responses for each command.
if [ "$1" = "disable" ]; then
    # turn the device off.
    echo disabled > /proc/acpi/ibm/$radio
elif [ "$1" = "enable" ]; then 
    # turn the device on in powersave mode.
    echo enabled > /proc/acpi/ibm/$radio
elif [ "$1" = "power" ]; then
    # takes the device out of powersave mode, you should now be able to dial with it.
    if [ "$radio" = "wan" ]; then
        power_wan
    fi
elif [ "$1" = "load" ]; then
    if [ "$radio" = "wan" ]; then
        load_wan
    fi
    if [ "$radio" = "bluetooth" ]; then
        load_bt
    fi
elif [ "$1" = "unload" ]; then
    if [ "$radio" = "wan" ]; then
        unload_wan
    fi
    if [ "$radio" = "bluetooth" ]; then
        unload_bt
    fi
elif [ "$1" = "reload" ]; then
    if [ "$radio" = "wan" ]; then
        unload_wan
        sleep 1
        load_wan
    fi
    if [ "$radio" = "bluetooth" ]; then
        unload_bt
        sleep 1
        load_bt
    fi
else
    helptext
    exit 1
fi


#kill $pid
