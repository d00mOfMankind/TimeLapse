#!/usr/bin/env bash
code=$(ssh -i ../bin/pi-ssh-key pi@raspberrypi-bane touch test.txt)
if [ "$code" == "0" ]
then
  echo "Code == 0"
else
  echo "Code != 0"
fi
echo $code
