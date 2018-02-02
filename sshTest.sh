#!/usr/bin/env bash
testName="bane"
scp -r -q pi@raspberrypi-$testName:~/TimeLapse/tl ./images
