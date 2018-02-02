#!/usr/bin/env bash
testName="bane"
scp -r -c arcfour pi@raspberrypi-$testName:~/TimeLapse/tl ./images
