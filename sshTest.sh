#!/usr/bin/env bash
testName="bane"
scp -r -c arcfour -q pi@raspberrypi-$testName:~/TimeLapse/tl ./images
