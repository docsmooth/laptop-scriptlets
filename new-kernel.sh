#!/bin/dash

version=$1
oldconfig=$2

if [ -z "$FUZZ" ]; then
    FUZZ=2
fi

TODAY=`date '+%Y%m%d'`
if [ -z "$JOBS" ]; then
    JOBS=10
fi

if [ -z "$version" ]; then
    echo "Please supply a version like 4.15.17 and re-run."
    exit 2
fi
oldpwd=`pwd`
cd /usr/src
base="linux-"
if [ ! -f ./${base}${version}.tar.xz ]; then
    if [ -f ./linux-source-$version/linux-source-$version.tar.bz2 ]; then
        base="linux-source-"
        if [ -L /usr/src/${base}${version}.tar.bz2 ]; then
            sudo rm /usr/src/${base}${version}.tar.bz2
        fi
        sudo chown -R $USER:src /usr/src/${base}${version}
        mv ./${base}${version}/${base}${version}.tar.bz2 /usr/src
        tarcmd="tar -jxf ./${base}$version.tar.bz2"
    elif [ -f ./linux-source-$version.tar.bz2 ]; then
        base="linux-source-"
        sudo chown -R $USER:src /usr/src/${base}${version}
        tarcmd="tar -jxf ./${base}${version}.tar.bz2"
    else
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
        tarcmd="tar -Jxf ./${base}$version.tar.xz"
    fi
    cd /usr/src/linux
    if [ $? -eq 0 ]; then
        #we have an old kernel to clean up
        oldkernel=`pwd -P`
        cd /usr/src
        rm -Rf $oldkernel
        rm linux
    fi
else
    echo "skipping download of new kernel - it already exists locally"
fi
cd /usr/src
$tarcmd
if [ $? -ne 0 ]; then
    echo "ERROR: Failed to run $tarcmd - did it download correctly?"
    exit 2
fi
rm /usr/src/linux
ln -s /usr/src/${base}$version /usr/src/linux
linkstatus=$?
cd linux
if [ $? -ne 0 -o $linkstatus -ne 0 ]; then
    echo "ERROR: could not update /usr/src/linux symclink to new version!"
    exit 2
fi
if [ ! -f /usr/src/linux/ubuntu/hio/Makefile ]; then
    #bug in Ubuntu kernel sources 5.19.17
    mkdir -p /usr/src/linux/ubuntu/hio
    touch /usr/src/linux/ubuntu/hio/Makefile
fi
if [ ! -d /usr/src/linux/debian ]; then
    #we wiped out the debian build rules.
    echo "WARNING: the debian directory was removed, restoring from /usr/src/6.5.0-rules.tar.gz"
    tar -zxf /usr/src/6.5.0-rules.tar.gz
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
sed -e 's/CONFIG_LOCALVERSION=.*/CONFIG_LOCALVERSION=.'$TODAY'/' $oldconfig > /usr/src/linux/.config
#cp $oldconfig /usr/src/linux/.config

cd /usr/src/linux
make oldconfig
if [ $? -ne 0 ]; then
    echo "ERROR: 'make oldconfig' failed - check that output, and try by hand!"
    exit 4
fi
df -h
#compilecmd="make-kpkg --rootcmd fakeroot --initrd --append-to-version=.$TODAY --jobs ${JOBS}  kernel_image kernel_headers"
#compilecmd="fakeroot make -j ${JOBS} deb-pkg"
compilecmd="dpkg-buildpackage -b"
logfile="../$TODAY.log"
echo "$compilecmd |tee $logfile"
time $compilecmd |tee $logfile
result=$?
if [ "x$result" = "x0" ]; then 
    buildresult=$result
else
    echo "ERROR: Build failed!  Check /usr/src/$TODAY.log"
    exit 8
fi
# must sign kernel now...
if [ -d /tmp/extracted-files ]; then
    rm -Rf /tmp/extracted-files
fi
mkdir /tmp/extracted-files
newpkg=`ls /usr/src/linux-image-$version{.,-}*.deb`
if [ -z "$newpkg" -o ! -f "$newpkg" ]; then
    # probably because the version is "5.19.0" instead of "5.19.17"
    #TODO Fix this
    newvers=`echo $version | sed -re 's/\.[[:digit:]]*$//'`
    newpkg=`ls -rt /usr/src/linux-image-${newvers}{.,-}*.deb 2>/dev/null |tail -1`
    if [ -z "$newpkg" -o ! -f "$newpkg" ]; then
        echo "ERROR: Can't find new package /usr/src/linux-image-$version{.,-}*.deb"
        echo "ERROR: Can't find new package /usr/src/linux-image-${newvers}{.,-}*.deb"
        exit 8
    fi
    # rewrite version from 5.19.0 to 5.19.whatever so the packages match below
    version=`echo $newpkg | sed -r -e 's/.*('${newvers}'\.[[:digit:]]*).*/\1/'`
fi
fullvers=`echo $newpkg | sed -n -r -e 's/.*('${newvers}'\.[[:digit:]]*\.[[:digit:]]*).*/\1/p'`
dpkg-deb -R $newpkg /tmp/extracted-files/
cd /tmp
sudo sbsign --key ~/workspace/codesigning/codesign.pem --cert ~/workspace/codesigning/codesign.pem extracted-files/boot/vmlinuz-$fullvers --output extracted-files/boot/vmlinuz-${fullvers}.signed
sudo mv extracted-files/boot/vmlinuz-${fullvers}.signed extracted-files/boot/vmlinuz-${fullvers}
sudo find /tmp/extracted-files/ -iname "*.ko" -exec kmodsign sha512 /var/lib/shim-signed/mok/MOK.priv ~/workspace/codesigning/MOK.der {} \;
cd /tmp
dpkg-deb -b extracted-files/ $newpkg
df -h
if [ "x$result" = "x0" ]; then 
    sudo dpkg -i /usr/src/linux-image-$version{.,-}*.deb /usr/src/linux-headers-$version.*.deb
    result=$?
else
    echo "ERROR: Build failed!  Check /usr/src/$TODAY.log"
    exit 8
fi

if [ "x$result" = "x0" ]; then
    echo "Installation of linux-image-$version successful."
    echo "you can reboot now."
    exit 0
fi
