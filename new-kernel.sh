#!/bin/dash

version=$1
oldkernel=$2

TODAY=`date '+%y%m%d%H%M'`
if [ -z "$JOBS" ]; then
    JOBS=4
fi

if [ -z "$version" ]; then
    echo "Please supply a version like 4.15.17 and re-run."
fi
oldpwd=`pwd`
cd /usr/src/linux
if [ $? -eq 0 ]; then
    #we have an old kernel to clean up
    oldkernel=`pwd -P`
    cd /usr/src
    rm -Rf $oldkernel
    rm linux
fi
cd /usr/src
if [ ! -f ./linux-$version.tar.xz ]; then
    wget https://cdn.kernel.org/pub/linux/kernel/v4.x/linux-$version.tar.xz
    if [ $? -ne 0 ]; then
        echo "FAILED Downloading https://cdn.kernel.org/pub/linux/kernel/v4.x/linux-$version.tar.xz"
        echo "Please check the version and try again."
        exit 2
    fi
else
    echo "skipping download of new kernel - it already exists locally"
fi
tar -Jxf ./linux-$version.tar.xz
ln -s /usr/src/linux-$version /usr/src/linux
cd linux
currentkernel=`uname -r`
echo $currentkernel | grep -q generic
if [ $? -eq 0 ]; then
    # this is a generic kernel, not one of mine, so we don't want to use that as the base for our automatic config
    if [ -z "$2" ]; then
        echo "Currently running a generic kernel, and a previous config wasn't passed as option 2!"
        echo "Please re-run as '$0 $version /usr/src/oldconfig'"
        exit 2
    fi
    if [ ! -r "$2" ]; then
        echo "Can't read $2 as an old config!"
        echo "Please re-run as '$0 $version /usr/src/oldconfig'"
        exit 2
    fi
else
    oldkernel=/boot/config-$currentkernel
fi
if [ ! -r "$oldkernel" ]; then
    echo "ERROR: Even after all that, we can't read $oldkernel!"
    exit 2
fi
cp $oldkernel /usr/src/linux/.config
cd /usr/src/linux
make oldconfig
if [ $? -ne 0 ]; then
    echo "ERROR: 'make oldconfig' failed - check that output, and try by hand!"
    exit 4
fi
df -h
time make-kpkg --rootcmd fakeroot --initrd --append-to-version=.20180412 --jobs 4 kernel_image kernel_headers > ../$TODAY.log
result=$
if [ "x$result" = "x0" ]; then 
    sudo dpkg -i /usr/src/linux-image-$version.*.deb /usr/src/linux-headers-$version.*.deb
    result=$?
else
    echo "ERROR: Build failed!  Check /usr/src/$TODAY.log"
    exit 8
fi
df -h

if [ "x$result" = "x0" ]; then
    echo "Installation of linux-image-$version successful."
    echo "you can reboot now."
    exit 0
fi
