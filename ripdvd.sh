#!/bin/bash

##############################################################
# 20061210 Robert Auch
#
# Duplication of DVDs for personal backup
# Rips DVD to ISO for later burning
# 
# No compression done - if you start with DVD9, you end
# up with DVD9, cause that's what I wanted.
#
# Requires vobcopy and mkisofs installed and in $PATH
# Expects bash installed as shell, cause I don't know any
# other shells.
#
# I suggest testing a few of your .iso files
# with:
# sudo mkdir /mnt/isotest
# sudo mount ./isofile.iso /mnt/isotest -t iso9660 -o loop,ro
# mplayer dvd:///mnt/isotest
# xine dvd:///mnt/isotest
# kaffeine dvd:///mnt/isotest
# or your favorite player.
#
##############################################################

errordelay=1
mounted=0

helptext="\n\
Rip DVD to ISO for burning back to backup DVD.\n\
No compression - copying a DVD9 requires\n\
 DualLayer DVD media.\n\
Requires vobcopy and mkisofs\n\
\n\
Options:\n\
Required:
    -t=Movie Title\n\
	-t \"Office Space\"\n\
Optional:
    -i=input source\n\
       -i /dev/cdrom\n\
    -w=working directory\n\
       -w /tmp/isos\n\
    -? This help text\n\
\n\
Generally, to get a full ISO in the CWD, you\n\
only need to run:\n\
ripdvd.sh -t \"Office Space\"\n\
\n"

#  process command line options

while getopts ":i:t:w" optn; do
    case $optn in
    t ) output=$OPTARG
        echo Ouput will be $output
        ;;
    i ) input=$OPTARG
        echo Reading from $input
        ;;
    w ) workdir=$OPTARG
        echo Using $workdir for working directory
        ;;
    \? ) printf "$helptext"
        sleep $errordelay
        exit 1
        ;;
    esac
done
if [ -z $output ]; then
	printf "$helptext"
	sleep $errordelay
	exit 1
fi
if [ -z $input ]; then
		# Attempt to find and mount DVD
		# first attempting to find it in fstab via filesystem type
		# if that fails, we fail out completely
		# if successful, we test if it's already mounted, then mount if not.
		dvddrive=$(grep iso9660 /etc/fstab |gawk  '{ print $2 }') # finding the DVD drive mountpoint
		if [ -d $dvddrive ]; then
			if [ -z `grep $dvddrive /etc/mtab` ]; then 
				errorcode=$(mount $dvddrive) || (printf "Could not mount $dvddrive - please check your DVD drive path.\n" && exit 1)
				$mounted=1
			fi
		else
			printf "could not find a DVD drive to mount.\nPlease mount your drive, then rerun.\n"
			sleep $errordelay
			exit 1
		fi
fi

# vobcopy picks up the mounted DVD well enough on my own system
# so I leave won't pass through what I've found above.  however,
# I won't be surprised if others who use this find a need
# to pass in the above $dvddrive value here.

errorcode=$(vobcopy $input -l -O . -t $output)
#if [ -z $errorcode]; then
#	printf "Vobcopy failed.  Read the above errors, then try again\n"
#	sleep $errordelay
#	exit 1
#fi
if [ $mounted = 1 ]; then
	umount $dvddrive
fi
mkisofs -dvd-video -udf $output > $output.iso

if [ -s $output.iso ]; then
	rm -R $output
fi
