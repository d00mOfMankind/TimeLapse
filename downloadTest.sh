#!/usr/bin/env bash
SECONDS=0
scp -r -i ./bin/pi-ssh-key pi@raspberrypi-bane:~/TimeLapse_images ./images
durationMulti=$SECONDS
SECONDS=0
ssh -i ./bin/pi-ssh-key pi@raspberrypi-bane zip -r images.zip TimeLapse_images
durationZip=$SECONDS
SECONDS=0
scp -i ./bin/pi-ssh-key pi@raspberrypi-bane:~/images.zip ./images.zip
unzip images.zip -d images
durationSingle=$SECONDS

echo ""
echo "Multiple duration download : $durationMulti"
echo "Zip duration               : $durationZip"
echo "Single duration download   : $durationSingle"
