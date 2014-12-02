#!/bin/bash

# Cron job to update svn/git locations from source
# Simply add new repos to the lists below
# SVNPATH for svn locations, GITPATH for git locations
# Exit status is the number of updates that failed
# TODO: type the path as svn or git, and call appropriate code

# Set OUTPUT to 1 to print results of update command to STDOUT
if [ -z "$OUTPUT" ]; then
    OUTPUT=0
else
    OUTPUT=1
fi
# ERRCODE is the default exit status. It is equal to the number of failed updates
ERRCODE=0
unset SVNPATH   i
unset GITPATH   o

MYPATH=`pwd`

#/home/rob/bin/net-tmux
# Paths where svn repos live.
SVNPATH[i++]="/home/rob/workspace/Deployment"
SVNPATH[i++]="/home/rob/workspace/branches/trunk"
SVNPATH[i++]="/home/rob/workspace/branches/Platform-8.1"
SVNPATH[i++]="/home/rob/workspace/branches/Enterprise-8.1"
SVNPATH[i++]="/home/rob/workspace/branches/Platform-8.2"
SVNPATH[i++]="/home/rob/workspace/branches/Enterprise-8.2"
SVNPATH[i++]="/home/rob/workspace/branches/Platform-8.0"
SVNPATH[i++]="/home/rob/workspace/branches/Enterprise-8.0"
SVNPATH[i++]="/home/rob/workspace/branches/Enterprise-7.5"
SVNPATH[i++]="/home/rob/workspace/branches/Platform-7.5"
SVNPATH[i++]="/home/rob/workspace/branches/likewise-oem-lexmark"
SVNPATH[i++]="/net/192.168.0.21/home/share/programmers/pbis-branches/trunk"
SVNPATH[i++]="/net/192.168.0.21/home/share/programmers/pbis-branches/Enterprise-8.1"
SVNPATH[i++]="/net/192.168.0.21/home/share/programmers/pbis-branches/Platform-8.1"
SVNPATH[i++]="/net/192.168.0.21/home/share/programmers/pbis-branches/Enterprise-8.2"
SVNPATH[i++]="/net/192.168.0.21/home/share/programmers/pbis-branches/Platform-8.2"
# Paths where git repos live
GITPATH[o++]="/home/rob/workspace/rainbarf"
GITPATH[o++]="/home/rob/workspace/siplcs"
GITPATH[o++]="/home/rob/workspace/esxidown"
GITPATH[o++]="/home/rob/workspace/vmware-bumblebee"
GITPATH[o++]="/home/rob/workspace/branches/pbis"
GITPATH[o++]="/home/rob/workspace/pebble/laughingman"
GITPATH[o++]="/net/192.168.0.21/home/share/programmers/pbis-branches/pbis"
GITPATH[o++]="/net/192.168.0.21/home/rob/programming/rainbarf"

for svnp in "${SVNPATH[@]}"; do 
    if [ -d $svnp ]; then
        cd $svnp
        if [ "$OUTPUT" -eq 1 ]; then
            pwd
        fi
        RESULT=`svn up`
        if [ $? -ne 0 ]; then
            echo $RESULT
            ERRCODE=`expr $ERRCODE + 1`
        elif [ "$OUTPUT" -eq 1 ]; then
            echo $RESULT
        fi
        cd $MYPATH
        if [ "$OUTPUT" -eq 1 ]; then
            pwd
        fi
    fi
done

for gitp in "${GITPATH[@]}"; do
    if [ -d $gitp ]; then
        cd $gitp
        if [ "$OUTPUT" -eq 1 ]; then
            pwd
        fi
        RESULT=`git pull`
        if [ $? -ne 0 ]; then
            echo $RESULT
            ERRCODE=`expr $ERRCODE + 1`
        elif [ "$OUTPUT" -eq 1 ]; then
            echo $RESULT
        fi
        git branch -r | grep -q upstream
        if [ $? -eq 0 ]; then
            # we have an upstream branch worth tracking
            URL=`git remote show upstream |awk '/Push/ { print $NF }'`
            #RESULT=`git merge upstream/master`
            RESULT=`git pull $URL`
            if [ $? -ne 0 ]; then
                echo $RESULT
                ERRCODE=`expr $ERRCODE + 1`
            elif [ "$OUTPUT" -eq 1 ]; then
                echo $RESULT
            fi
        fi
        cd $MYPATH
        if [ "$OUTPUT" -eq 1 ]; then
            pwd
        fi
    fi
done

exit $ERRCODE
