#!/bin/sh
# From https://lonesysadmin.net/2013/03/26/preparing-linux-template-vms/

# Determine the version of RHEL
COND=`grep -i Taroon /etc/redhat-release`
if [ "$COND" = "" ]; then
        export PREFIX="/usr/sbin"
else
        export PREFIX="/sbin"
fi

FileSystem=`awk -F" " '/(ext|xfs)/ { print $2 }' /etc/mnttab`

for i in $FileSystem
do
        echo $i
        number=`df -B 512 $i | awk -F" " '{print $3}' | grep -v Used`
        echo $number
        percent=$(echo "scale=0; $number * 99 / 100" | bc )
        echo $percent
        dd count=`echo $percent` if=/dev/zero of=`echo $i`/zf
        /bin/sync
        sleep 15
        rm -f $i/zf
done

VolumeGroup=`$PREFIX/vgdisplay | awk -F" " '/Name/ { print $3 }'`

for j in $VolumeGroup
do
        VGFree=`$PREFIX/vgdisplay $j | awk -F" " '/Free/ { print $5 }'`
        if [ ! "x$VGFree" = "x0" ]; then
                echo $j
                $PREFIX/lvcreate -l `$PREFIX/vgdisplay $j | awk -F" " '/Free/ { print $5 }'` -n zero $j
                if [ -a /dev/$j/zero ]; then
                       cat /dev/zero > /dev/$j/zero
                       /bin/sync
                       sleep 15
                       $PREFIX/lvremove -f /dev/$j/zero
               fi
        else
                echo "$j has no free volume space, skipping."
        fi
done

