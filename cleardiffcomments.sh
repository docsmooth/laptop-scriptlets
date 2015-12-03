#!/bin/bash
file="$@"

SED=/bin/sed
if [ -x /usr/xpg4/bin/sed ]; then
    SED=/usr/xpg4/bin/sed
fi

$SED -e '/^[<>][[:space:]]*[#;\/]/d' -e '/^[[:space:]]*$/d' -e '/^[<>][[:space:]]*$/d' $file

