#!/bin/dash

version=$1
oldconfig=$2

if [ -z "$FUZZ" ]; then
    FUZZ=2
fi

TODAY=`date '+%Y%m%d'`
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
    echo $version | egrep -q '^4\.'
    if [ $? -eq 0 ]; then
        verspath="v4.x"
    else
        verspath="v5.x"
    fi
    wget https://cdn.kernel.org/pub/linux/kernel/${verspath}/linux-$version.tar.xz
    if [ $? -ne 0 ]; then
        echo "FAILED Downloading https://cdn.kernel.org/pub/linux/kernel/${verspath}/linux-$version.tar.xz"
        echo "Please check the version and try again."
        exit 2
    fi
else
    echo "skipping download of new kernel - it already exists locally"
fi
tar -Jxf ./linux-$version.tar.xz
if [ $? -ne 0 ]; then
    echo "ERROR: Failed to extract ./linux-$version.tar.xz - did it download correctly?"
    exit 2
fi
rm /usr/src/linux
ln -s /usr/src/linux-$version /usr/src/linux
linkstatus=$?
cd linux
if [ $? -ne 0 -o $linkstatus -ne 0 ]; then
    echo "ERROR: could not update /usr/src/linux symclink to new version!"
    exit 2
fi
if [ -z "$oldconfig" ]; then
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
        oldconfig=/boot/config-$currentkernel
    fi
fi
if [ ! -r "$oldconfig" ]; then
    echo "ERROR: Even after all that, we can't read $oldconfig!"
    exit 2
fi
cp $oldconfig /usr/src/linux/.config

#Try to add MuQSS patch
muqsspatch=`ls -rt /usr/src/bfs/*Multi* |tail -1`
if [ -n "$muqsspatch" ]; then
    # we have a patch, but is it right?  From CK's versioning, I don't know how to tell
    # maybe we should wget the latest every time from his site instead of reading here.
    # TODO
    # so in the meantime...
    cd /usr/src/linux
    output=`patch -F $FUZZ -p1 < ${muqsspatch}`
    if [ $? -ne 0 ]; then
        echo "ERROR: Can't patch MuQSS into this kernel."
        echo "patch -p1 < ${muqsspatch}"
        echo $output
        exit 2
    fi
fi

cd /usr/src/linux
make oldconfig
if [ $? -ne 0 ]; then
    echo "ERROR: 'make oldconfig' failed - check that output, and try by hand!"
    exit 4
fi
df -h
time make-kpkg --rootcmd fakeroot --initrd --append-to-version=.$TODAY --jobs ${JOBS}  kernel_image kernel_headers > ../$TODAY.log
result=$?
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
