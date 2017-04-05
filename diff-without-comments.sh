#!/bin/bash

args=""
x=$1
echo $x | egrep '^-' > /dev/null
err=$?
while [ $err -eq 0 ]; do
    args="${args}${x} "
    shift
    x=$1
    echo $x | egrep '^-' > /dev/null
    err=$?
done
file1=$x
file2=$2

SED=/bin/sed
if [ -x /usr/xpg4/bin/sed ]; then
    SED=/usr/xpg4/bin/sed
fi

diff ${args} <($SED -e '/^[[:space:]]*[#;\/]/d' -e '/^[[:space:]]*$/d' -e '/^[[:space:]]*$/d' $file1) <($SED -e '/^[[:space:]]*[#;\/]/d' -e '/^[[:space:]]*$/d' -e '/^[[:space:]]*$/d' $file2)

