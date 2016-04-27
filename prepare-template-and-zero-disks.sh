#!/bin/sh
# From https://lonesysadmin.net/2013/03/26/preparing-linux-template-vms/

/sbin/service/rsyslog stop
/sbin/service/auditd stop
/bin/package-cleanup --oldkernels --count=1
yum clean all
/usr/sbin/logrotate –f /etc/logrotate.conf
/bin/rm -f /var/log/*-???????? /var/log/*.gz
/bin/rm -f /var/log/dmesg.old
/bin/rm -rf /var/log/anaconda
/bin/cat /dev/null > /var/log/audit/audit.log
/bin/cat /dev/null > /var/log/wtmp
/bin/cat /dev/null > /var/log/lastlog
/bin/cat /dev/null > /var/log/grubby
/bin/rm -f /etc/udev/rules.d/70*
/bin/sed -i '/^(HWADDR|UUID)=/d' /etc/sysconfig/network-scripts/ifcfg-eth0
/bin/rm -rf /tmp/*
/bin/rm -rf /var/tmp/*
/bin/rm -f /etc/ssh/*key*
/bin/rm -f ~root/.bash_history
unset HISTFILE
export HISTFILE
/bin/rm -rf ~root/.ssh/known_hosts
/bin/rm -f ~root/anaconda-ks.cfg
touch /.unconfigured

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

