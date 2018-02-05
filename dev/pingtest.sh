#!/usr/bin/env bash
count=$(ping -c 1 raspberrypi-bane | grep icmp* | wc -l)
echo $count
