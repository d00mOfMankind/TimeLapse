#!/usr/bin/env bash

function usage() {
	echo "Usage: "
	exit -1
}

function get_static_image() {
	echo "INFO: Take test picture function called."
}

function setup(){
	echo "INFO: Setup function called."
	#ssh pi@raspberrypi-"$1" 'bash -s' < setup.sh
}









