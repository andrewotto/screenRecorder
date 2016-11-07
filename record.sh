#!/bin/bash

###Screen Recorder for Bash ( root capture )
###Super Stripped Down Version
###2005 - 2016 Andrew F. Otto

#check parameters
# -d <recording directory> , ~ by default
# -w <window handle to record>, root ( desktop ) by default
#    xwininfo id property ( xwininfo | grep Window )
#
# e.g ./record.sh -d /tmp -w 0x00000001 -t Lesson3
DIRECTORY=~
WINDOW=""
MOVIETITLE="movie"

function show_usage()
{
	echo "Usage: record.sh " \
		 "-d  --directory    The temporary directory to work in." \
		 "                   Also the output directory. Default is /tmp." \
		 "-w  --window       The window handle ( e.g. 0x00000001 ). Default " \
		 "                   is the entire desktop" \
		 "-t  --title        Name of the resulting movie. Default is movie."		 
}

while [[ $# -gt 1 ]]
do
key="$1"

case $key in
    -d|--directory)
    DIRECTORY="$2"
    shift # past argument
    ;;
    -w|--window)
    WINDOW="$2"
    shift # past argument
    ;;
    -t|--title)
    MOVIETITLE="$2"
    shift # past argument
    ;;
    -h|--help)
	show_usage   #this exits
	exit 0
    ;;
    *)
          # unknown option
    ;;
esac
shift # past argument or value
done

#Step 1 Acquire dumps ( requires alot of disk space )
outputDirectory="$DIRECTORY/`date +%A%s`/"

mkdir -p $outputDirectory
frameRate=15  #frames per second
itr=0

echo "Capturing frames to: $outputDirectory"
echo "touch /tmp/sc to escape loop"

while [[ ! -e /tmp/sc ]]
do
	sleep 0.06
	if [[ ${#WINDOW} -eq 0 ]]; then
	   xwd -root -out $outputDirectory/$(printf %08d.dmp $itr)
    else
	   xwd -id $WINDOW -out $outputDirectory/$(printf %08d.dmp $itr)
    fi
	itr=$((itr+1))
done

rm -f /tmp/sc

#Step 2 Convert each image
echo "Converting images"
for I in $outputDirectory/*
do
	newFile=${I%.*}.png
	convert $I $newFile
	if [[ -e $newFile ]]; then
		rm -f $I
	fi
done

#Step 4 Make a movie
echo "Making a movie"
ffmpeg -r 15 -f image2 -s 1920x1080 -i $outputDirectory/%08d.png -vcodec libx264 -crf 25  -pix_fmt yuv420p $outputDirectory/$MOVIETITLE.mp4

#Step 5 Clean up the disk
if [[ -e $outputDirectory/movie.mp4 ]]; then

   used=$(du -sh $outputDirectory)
   echo "Cleaning up $used worth of captures"
   rm -f $outputDirectory/*.png

fi
