#!/bin/sh

sed -e 's/192.168.[[:alnum:]]*\./x.x.x./g' -e 's/1700:5650:16a8:[[:alnum:]]*:[[:alnum:]]*:[[:alnum:]]/:x:/g' -e 's/:[[:alnum:]]*:[[:alnum:]]*:[[:alnum:]]*:/:x:/g'
