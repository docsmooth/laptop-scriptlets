#!/bin/bash

# Cron job to update svn/git locations from source
# Simply add new repos to the lists below
# SVNPATH for svn locations, GITPATH for git locations
# Exit status is the number of updates that failed
# TODO: type the path as svn or git, and call appropriate code

# Set OUTPUT to 1 to print results of update command to STDOUT
if [ -n "$OUTPUT" ]; then
    OUTPUT=1
elif [ `echo $@ | grep -q output` ]; then
    OUTPUT=1
else
    OUTPUT=0
fi

echo $@ | grep -q workonly
errcode=$?
if [ -n "$workonly" ]; then
    workonly=1
    echo "Doing only work branches - env."
elif [ "$errcode" = "0" ]; then
    workonly=1
    echo "Doing only work branches - switch."
else
    workonly=0
fi
unset errcode
echo $* | grep -q personalonly
errcode=$?
if [ -n "$personalonly" ]; then
    personalonly=1
    workonly=0
    echo "Doing only personal branches - env."
elif [ "$errcode" = "0" ]; then
    personalonly=1
    workonly=0
    echo "Doing only personal branches - switch."
else
    personalonly=0
fi
# ERRCODE is the default exit status. It is equal to the number of failed updates
ERRCODE=0
unset SVNPATH   i
unset GITPATH   o

MYPATH=`pwd`

#/home/rob/bin/net-tmux
# Paths where svn repos live.
#SVNPATH[i++]="/home/rob/workspace/branches/likewise-oem-lexmark"
# Paths where git repos live
GITPATH[o++]="/home/rob/workspace/pbis-deployments"
GITPATH[o++]="/home/rob/workspace/branches/PBIS-Enterprise"
GITPATH[o++]="/home/rob/workspace/branches/PBIS-Platform"
GITPATH[o++]="/home/rob/workspace/rainbarf"
GITPATH[o++]="/home/rob/workspace/siplcs"
GITPATH[o++]="/home/rob/workspace/esxidown"
GITPATH[o++]="/home/rob/workspace/vmware-bumblebee"
GITPATH[o++]="/home/rob/workspace/vmware-patch"
GITPATH[o++]="/home/rob/workspace/branches/pbis"
GITPATH[o++]="/home/rob/workspace/pebble/laughingman"
GITPATH[o++]="/home/rob/workspace/creepy"
GITPATH[o++]="/home/rob/workspace/solarized"
GITPATH[o++]="/home/rob/workspace/onedrive"
GITPATH[o++]="/home/rob/workspace/rainbowstream"
GITPATH[o++]="/home/rob/workspace/rtm-cli"
GITPATH[o++]="/home/rob/workspace/wtf-console"
GITPATH[o++]="/net/192.168.0.21/home/share/programmers/pbis-branches/pbis"
GITPATH[o++]="/net/192.168.0.21/home/rob/programming/rainbarf"

for svnp in "${SVNPATH[@]}"; do 
    echo $svnp | egrep -q '(branches|pbis|Deployment)'
    if [ $? -eq 0 ]; then
        #this is a work branch
        work=1
    else
        work=0
    fi
    if [ "x$workonly" = "x1" -a "x$work" = "x0" ]; then
        continue
    elif [ "x$personalonly" = "x1" -a "x$work" = "x1" ]; then
        continue
    fi

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
        git branch | awk '{ print $NF }' | while read branch;
        do
            git checkout "$branch"
            RESULT=`git pull`
            if [ $? -ne 0 ]; then
                echo $RESULT
                ERRCODE=`expr $ERRCODE + 1`
            elif [ "$OUTPUT" -eq 1 ]; then
                echo $RESULT
            fi
            #if [ "$branch" != "master" ]; then
            #    RESULT=`git merge master`
            #    if [ $? -ne 0 ]; then
            #        echo $RESULT
            #        ERRCODE=`expr $ERRCODE + 1`
            #    elif [ "$OUTPUT" -eq 1 ]; then
            #        echo $RESULT
            #    fi
            #fi
        done
        git checkout master

        pwd
        cd $MYPATH
    fi
done

exit $ERRCODE
