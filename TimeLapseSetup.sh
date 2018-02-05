#!/usr/bin/env bash

function usage() {
	echo "Usage: $(basename ${0}) --(viewtest {unique name} | start {unique name} {time interval} {number of images}"
	echo "                        --key {ssh key name})"
	echo ""
	echo "   Examples:   $(basename ${0}) --viewtest maleficent --key my-private-key"
	echo ""
	echo " --viewtest           - Get a single image from the remote camera to test the view."
	echo "                        'unique name' referes to the name suffix of the Raspberry Pi."
	echo " --start              - Start the timelapse camera."
	echo "                        'unique name' referes to the name suffix of the Raspberry Pi."
	echo "                        'time interval' refers to the time the camera will wait between images."
	echo "                        'number of images' refers to the number of images that you want the camera to take."
	echo " --key                - Provides the ssh key for the connection."
	echo ""
	exit -1
}

function load_ani() {
	echo -ne "[>.........]"\\r
	sleep 0.5
	echo -ne "[=>........]"\\r
	sleep 0.5
	echo -ne "[==>.......]"\\r
	sleep 0.5
	echo -ne "[===>......]"\\r
	sleep 0.5
	echo -ne "[====>.....]"\\r
	sleep 0.5
	echo -ne "[=====>....]"\\r
	sleep 0.5
	echo -ne "[======>...]"\\r
	sleep 0.5
	echo -ne "[=======>..]"\\r
	sleep 0.5
	echo -ne "[========>.]"\\r
	sleep 0.5
	echo -ne "[=========>]"\\r
	sleep 0.5
	echo -ne "[==========]"\\r
	echo ""

}

function get_static_image() {
	echo "INFO: Take test picture function called with target: $1  ssh key: $2"

}

function get_update() {
	echo "INFO: Get update called with target: $1  ssh key: $2"

}

function cancel_running_lapse() {
	echo "INFO: Cancel running time lapse called with target: $1  ssh key: $2"

}

function setup(){
	echo "INFO: Setup function called with target: $1  ssh key: $4"

	if [ -f ./bin/lapse.py ]
	then
		echo "ERROR: lapse.py program does not exist in bin."
		exit 1
	fi

	FOLDER_STATUS="ssh -i ./bin/$4 pi@raspberrypi-$1 if [ -d ~/TimeLapse/tl ]; then echo \"deep\"; elif [ -d ~/TimeLapse ] && [ ! -d ~/TimeLapse/tl ]; then echo \"shallow\"; elif [ ! -d ~/TimeLapse ]; then echo \"bare\"; fi"

	#if both folders exist
	if [ "$FOLDER_STATUS" == "deep" ]
	then
		echo "STATUS: Deep folder status found. Continuing..."
		scp -i ./bin/$4 ./bin/lapse.py pi@raspberrypi-$1:~/TimeLapse/lapse.py
		NUMBER="ssh -i ./bin/$4 pi@raspberrypi-$1 ls -1 ~/TimeLapse/tl | wc -l"

		if [ ! $NUMBER -eq 0 ]
		then
			echo "INFO: There are currently: $NUMBER images on $1"
			echo "    : If you continue with this setup they will be permanently removed."
			read -p "OPTION: Continue with this setup? y/n: " continueOption
			if [ "$continueOption" == "n" ] || [ "$continueOption" == "N" ] || [ "$continueOption" == "no" ] || [ "$continueOption" == "No" ]
			then
				echo "STATUS: Cancelling setup..."
				exit 1
			fi
			ssh -i ./bin/$4 pi@raspberrypi-$1 rm ~/TimeLapse/tl/*
		fi

	#if only top level folder exists
	elif [ "$FOLDER_STATUS" == "shallow" ]
	then
		echo "STATUS: Shallow folder status found. Continuing..."
		scp -i ./bin/$4 ./bin/lapse.py pi@raspberrypi-$1:~/TimeLapse/lapse.py

	#if no folders exist
	elif [ "$FOLDER_STATUS" == "bare" ]
	then
		echo "STATUS: ~/TimeLapse not found on $1. Creating..."
		ssh -i ./bin/$4 pi@raspberrypi-$1 mkdir ~/TimeLapse
		scp -i ./bin/$4 ./bin/lapse.py pi@raspberrypi-$1:~/TimeLapse/lapse.py
	else
		echo "ERROR: Unknown folder status."
		echo "$FOLDER_STATUS"
		exit 1
	fi

	echo "STATUS: Setting up program..."
	ssh -i ./bin/$4 pi@raspberrypi-$1 nohup ~/TimeLapse/lapse.py $2 $3 &
	if [ -f ./bin/output.txt ]
	then
		rm ./bin/output.txt
	fi

	load_ani
	scp -i ./bin/$4 pi@raspberrypi-$1:~/TimeLapse/output.txt ./bin/output.txt

	cat output.txt


}


UNIQUE_NAME=""
TIME_INTERVAL=""
NUMBER_OF_IMAGES=""
KEY_NAME=""
TOGGLE=""

if [[ $# -eq 0 ]]
then
  usage
  exit 1
fi

while [[ $# -gt 0 ]]; do
	case "${1}" in
	  -h|--help)
			usage;;
		--viewtest)
			if [ -z "${2}" ]
			then
			  echo "ERROR: (--viewtest) Target not defined."
			  exit 1
			else
				UNIQUE_NAME=${2}
				TOGGLE="view"
			fi
			shift 2
		--start)
			if [ -z "${2}" ]
			then
				echo "ERROR: (--start) Target not defined."
				exit 1
			elif [ -z "${3}" ]
			then
				echo "ERROR: (--start) Time interval not defined."
				exit 1
			elif [ -z "${4}" ]
			then
				echo "ERROR: (--start) Number of images not defined."
				exit 1
			else
				UNIQUE_NAME=${2}
				TIME_INTERVAL=${3}
				NUMBER_OF_IMAGES=${4}
				TOGGLE="start"
			fi
			shift 4
		--key)
			if [ -z "${2}" ]
			then
				echo "ERROR: (--key) ssh key not defined."
				exit 1
			elif [ -f "./bin/${2}" ]
      then
        echo "ERROR: Key: ./bin/${2} does not exist."
        exit 1
      else
      	KEY_NAME=${2}
      fi
      shift 2
		*)
			echo "FATAL: Unknown command-line argument or enviroment: ${1}"
			exit 1
	esac
done

if [ "$TOGGLE" == "start" ]
then
	setup $UNIQUE_NAME TIME_INTERVAL NUMBER_OF_IMAGES KEY_NAME
elif [ "$TOGGLE" == "view" ]
then
	get_static_image $UNIQUE_NAME KEY_NAME
else
	echo "FATAL: No mode selected."
	usage;;
fi
