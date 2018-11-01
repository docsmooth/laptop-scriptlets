#!/bin/sh

sed -re 's/(192\.168|10\.[[:alnum:]]*)\.[[:alnum:]]*\./x.x.x./g' -e 's/:1700:5650:16a8:[[:alnum:]]*:[[:alnum:]]*:[[:alnum:]]/:x:/g' -e 's/:[[:alnum:]]{2}:[[:alnum:]]{2}:[[:alnum:]]{2}:/:xx:xx:xx:/g'
