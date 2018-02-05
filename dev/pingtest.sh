#!/usr/bin/env bash
code=$(ssh -i ~/projects/TimeLapse/bin/pi-ssh-key pi@raspberrypi-bane touch echo "foo")
if [ "$code" == "0" ]
then
  echo "Code == 0"
else
  echo "Code != 0"
fi
echo $code
