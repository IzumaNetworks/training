#!/usr/bin/env bash
remote=tbuild3
sdcard=/dev/rdisk4
output=/tmp/rpi3.wic.gz
img=core-image-minimal-raspberrypi3-64.wic.gz
img="lmp-base-console-image-raspberrypi3-64.wic.gz"
imagePath="build/build-lmp/deploy/images/raspberrypi3-64/${img}"
rm -rf $output
scp tbuild3:~/$imagePath $output
ls ${sdcard}?* | xargs -n1 diskutil umount
gunzip -c ${output} | sudo dd bs=4m of=${sdcard} conv=sync
