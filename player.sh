#!/bin/bash
vmplayer -h 192.168.0.250 -u "root" "[esx1:storage${2}] $1/$1.vmx"
