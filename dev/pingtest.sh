#!/usr/bin/env bash
code=$(ssh -i ./bin/pi-ssh-key pi@raspberrypi-bane echo "0")
if [ "$code" == "0" ]
then
  echo "No connection"
else
  echo "Connection"
fi
echo $code
