#!/usr/bin/env bash
code=$(ssh -i ./bin/pi-ssh-key pi@raspberrypi-bane)
if [ "$code" == "0" ]
then
  echo "Connection"
else
  echo "No connection"
fi
