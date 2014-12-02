#!/bin/bash

helptext() {
    echo "Runas $0 'moviename'"
    echo "if dvd://0 is not correct path to feature,"
    echo "Run as: '$0 moviename 1' for dvd://1"
}

if [ "$1" = "" ]; then
    helptext
    exit 2
fi
if [ $2 -gt 0 ]; then
    video=$2
else
    video=0
fi

movie=$1
#outpath="/home/rob/media/movies/feature"
outpath="/net/srv1/home/share/media/movies"

echo "Ripping $movie from dvd://$video"
echo "CTRL-C to cancel"
sleep 5

#mencoder -o $outpath/$movie.mp4 -oac mp3lame -lameopts preset=medium -ovc lavc -lavcopts vstrict=-1:vcodec=mpeg4:autoaspect:vbitrate=2100:vpass=1 -xy 1080 -zoom -vf scale -alang en -nosub  dvd://$video
#mencoder -o $outpath/$movie.mp4 -oac mp3lame -lameopts preset=medium -ovc lavc -lavcopts vstrict=-1:vcodec=mpeg4:autoaspect:vbitrate=2100:vpass=2 -xy 1080 -zoom -vf scale -alang en -nosub  dvd://$video
# 12/20/2012 on Ubuntu 12.10: - no video sometimes
mencoder -o $outpath/$movie.mp4 -oac mp3lame -lameopts preset=medium -ovc lavc -lavcopts vstrict=-1:vcodec=mpeg4:autoaspect:vbitrate=2100:vpass=1 -xy 1080 -zoom -vf scale -alang en -nosub -of lavf -lavfopts format=mp4 dvd://$video
mencoder -o $outpath/$movie.mp4 -oac mp3lame -lameopts preset=medium -ovc lavc -lavcopts vstrict=-1:vcodec=mpeg4:autoaspect:vbitrate=2100:vpass=2 -xy 1080 -zoom -vf scale -alang en -nosub -of lavf -lavfopts format=mp4 dvd://$video

# ffmpeg -i DSCF4605.AVI -s 320x240 -r 29.97 -ar 16000 -ab 128 -ac 1 -target dv test.dv

# CONCURRENCY_LEVEL=2
# fakeroot make-kpkg --initrd --append-to-version=.100701 kernel_image kernel_headers

#the concurrency level makes make use both cores.  don't forget --initrd

#mencoder -o familyguy100.avi -oac mp3lame -lameopts preset=medium -ovc lavc -lavcopts vstrict=-1:vcodec=xvid:autoaspect:vbitrate=2100:vpass=2 -xy 720 -zoom -vf scale,expand=720:540,dsize=4:3 dvd://0   

#mencoder -o /home/rauch/ff7-adventchildren.avi -oac pcm -ovc lavc -lavcopts vstrict=-1:vcodec=ffv1:autoaspect -xy 720 -zoom -vf scale,expand=720:540,dsize=4:3 dvd://0
