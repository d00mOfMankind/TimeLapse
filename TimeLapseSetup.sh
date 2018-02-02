#!/usr/bin/env bash

ssh pi@raspberrypi-"$1" 'bash -s' < setup.sh