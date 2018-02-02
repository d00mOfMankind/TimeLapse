#!/usr/bin/env bash

function usage() {
	echo "Usage: $(basename ${0}) --(viewtest {unique name} | start {unique name} {time interval} {number of images})"
	echo ""
	echo " --viewtest   -v      - Get a single image from the remote camera to test the view."
	echo "                        'unique name' referes to the name suffix of the Raspberry Pi"
	echo ""
	exit -1
}

function get_static_image() {
	echo "INFO: Take test picture function called."
}

function setup(){
	echo "INFO: Setup function called."

	#if bin does not exist create it
	if [ ! -d ./bin ]
	then
		mkdir ./bin
	fi

	#if setup file exists remove it (we want to start fresh)
	if [ -f ./bin/setup.sh ]
	then
		rm ./bin/setup.sh
	fi

	#create setup file
	touch ./bin/setup.sh

	#write to file
	echo "#!/usr/bin/env bash
	if [ ! -d ~/TimeLapse ]
	then
		mkdir ~/TimeLapse
	fi

	if [ ! -f ~/TimeLapse/lapse.py ]
	then
		rm ~/TimeLapse/lapse.py
		wget https://raw.githubusercontent.com/d00mOfMankind/TimeLapse/master/bin/lapse.py
		mv lapse.py ~/TimeLapse/lapse.py
	fi


	" >> ./bin/setup.sh
	#look here to continue
	#http://blogs.perl.org/users/smylers/2011/08/ssh-productivity-tips.html


	#ssh pi@raspberrypi-$1 'bash -s' < setup.sh
}


UNIQUE_NAME=""
TIME_INTERVAL=""
NUMBER_OF_IMAGES=""

if [[ $# -eq 0 ]]
then
  usage
  exit 1
fi

case "${1}" in
  -h|--help)
		usage;;
	-v|--viewtest)
		if [ -z "${2}" ]
		then
		  echo "ERROR: (--viewtest|-v) Target not defined."
		  exit 1
		else
			UNIQUE_NAME=${2}
			get_static_image $UNIQUE_NAME
		fi
	-s|--start)
		if [ -z "${2}" ]
		then
			echo "ERROR: (--start|-s) Target not defined."
			exit 1
		elif [ -z "${3}" ]
		then
			echo "ERROR: (--start|-s) Time interval not defined."
			exit 1
		elif [ -z "${4}" ]
		then
			echo "ERROR: (--start|-s) Number of images not defined."
			exit 1
		else
			UNIQUE_NAME=${2}
			TIME_INTERVAL=${3}
			NUMBER_OF_IMAGES=${4}
			setup $UNIQUE_NAME TIME_INTERVAL NUMBER_OF_IMAGES
		fi
	*)
		echo "FATAL: Unknown command-line argument or enviroment: ${1}"
esac
