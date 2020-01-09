#!/bin/sh
# From https://lonesysadmin.net/2013/03/26/preparing-linux-template-vms/
# Ubuntu from https://jimangel.io/post/create-a-vm-template-ubuntu-18.04/

release=`awk -F= '/DISTRIB_ID=/ { print $NF }' /etc/lsb-release`
if [ -z "$release" ]; then
	release=`awk '/(Cent|Red)/ { print $1 }' /etc/redhat-release`
fi

if [ "x$release" = "xUbuntu" ]; then
	service rsyslog stop
	service auditd stop
	apt clean
	cat << 'EOL' | sudo tee /etc/rc.local
#!/bin/sh -e
#
# rc.local
#
# This script is executed at the end of each multiuser runlevel.
# Make sure that the script will "" on success or any other
# value on error.
#
# In order to enable or disable this script just change the execution
# bits.
#
# By default this script does nothing.
# dynamically create hostname (optional)
#if hostname | grep localhost; then
#    hostnamectl set-hostname "$(head /dev/urandom | tr -dc A-Za-z0-9 | head -c 13 ; echo '')"
#fi
test -f /etc/ssh/ssh_host_dsa_key || dpkg-reconfigure openssh-server
exit 0
EOL

	# make sure the script is executable
	chmod +x /etc/rc.local
else
	/sbin/service/rsyslog stop
	/sbin/service/auditd stop
	/bin/package-cleanup --oldkernels --count=1
	yum clean all
fi
/usr/sbin/logrotate –f /etc/logrotate.conf
/bin/rm -f /var/log/*-???????? /var/log/*.gz
/bin/rm -f /var/log/dmesg.old
/bin/rm -rf /var/log/anaconda
/bin/cat /dev/null > /var/log/audit/audit.log
/bin/cat /dev/null > /var/log/wtmp
/bin/cat /dev/null > /var/log/lastlog
/bin/cat /dev/null > /var/log/grubby
/bin/rm -f /etc/udev/rules.d/70*
if [ -d /etc/sysconfig ]; then
	/bin/sed -i '/^(HWADDR|UUID)=/d' /etc/sysconfig/network-scripts/ifcfg-eth0
else
	sed -i 's/preserve_hostname: false/preserve_hostname: true/g' /etc/cloud/cloud.cfg
	truncate -s0 /etc/hostname
	hostnamectl set-hostname localhost
	sed -i 's/optional: true/dhcp-identifier: mac/g' /etc/netplan/50-cloud-init.yaml

	# cleans out all of the cloud-init cache / logs - this is mainly cleaning out networking info
	sudo cloud-init clean --logs
fi
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
elif [ ! -f "/etc/redhat-release" ]; then
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

