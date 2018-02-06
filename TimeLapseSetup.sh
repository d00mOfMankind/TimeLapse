#!/usr/bin/env bash

function usage() {
	echo "Usage: $(basename ${0}) --[ viewtest {unique name}"
	echo "                          | start {unique name} {time interval} {number of images}"
	echo "                          | status {unique name}"
	echo "                          | cancel {unique name}]"
	echo "                            --key {ssh key name}"
	echo "                          	--help"
	echo ""
	echo "   Examples:   $(basename ${0}) --viewtest maleficent --key my-private-key"
	echo "               $(basename ${0}) --key my-private-key --start maleficent 5 2000"
	echo "               $(basename ${0}) --i my-private-key --status maleficent"
	echo ""
	echo " --viewtest           - Get a single image from the remote camera to test the view."
	echo "                        'unique name' referes to the name suffix of the Raspberry Pi."
	echo " --start       -s     - Start the timelapse camera."
	echo "                        'unique name' referes to the name suffix of the Raspberry Pi."
	echo "                        'time interval' refers to the time the camera will wait between images."
	echo "                        'number of images' refers to the number of images that you want the camera to take."
	echo " --status             - Prints the status of the Raspberry Pi time lapse server."
	echo "                        'unique name' referes to the name suffix of the Raspberry Pi."
	echo " --cancel             - Cancels a running time lapse, the images that have already been taken are not removed."
	echo "                        'unique name' referes to the name suffix of the Raspberry Pi."
	echo ""
	echo " --key       -k/-i    - Provides the ssh key for the connection."
	echo ""
	echo " --help        -h     - This page."
	echo ""
	exit -1
}

function load_ani() {
	#echo -ne "[>.........]   0%"\\r
	#sleep 0.5
	#echo -ne "[=>........]  10%"\\r
	#sleep 0.5
	#echo -ne "[==>.......]  20%"\\r
	#sleep 0.5
	#echo -ne "[===>......]  30%"\\r
	#sleep 0.5
	#echo -ne "[====>.....]  40%"\\r
	#sleep 0.5
	#echo -ne "[=====>....]  50%"\\r
	#sleep 0.5
	#echo -ne "[======>...]  60%"\\r
	#sleep 0.5
	#echo -ne "[=======>..]  70%"\\r
	#sleep 0.5
	#echo -ne "[========>.]  80%"\\r
	#sleep 0.5
	#echo -ne "[=========>]  90%"\\r
	#sleep 0.5
	#echo -ne "[==========] 100%"\\r
	#echo ""

	per=100
	lstring="="
	load=""
	point=">"
	dot="."
	dots=""

	while [ $per -ge 1 ]; do
		dots=$dots$dot
		per=$((per-1))
	done

	while [ $per -le 100 ]; do
		echo -ne "[$load$point$dots] $per %" \\r
		load=$load$lstring
		dots=${dots%?}
		per=$((per+1))
		sleep 0.05
	done

	echo ""

}

# var1 = sshkey, var2 = hostname
function validation() {
	host=$2
	echo "Hostname: $host"
	key=$1
	echo "ssh key : $key"

	#key name check
	if [ "$key" == "-" ]
	then
		echo "ERROR: (--key) ssh key not defined."
		exit 1
	fi

	#hostname ping test
	extcode=$(ping -c 1 raspberrypi-$host)
	echo "$extcode"
	if [ "$extcode" == "0" ] || [ "$extcode" == "" ]
	then
		echo "ERROR: Host raspberrypi-$host unreachable/offline."
		exit 1
	else
		echo "INFO: Host raspberrypi-$host online."
	fi

	#connection test
	extcode=$(ssh -i ./bin/$key pi@raspberrypi-$host echo "ssh connection test")
	if [ "$extcode" == "ssh connection test" ]
	then
	  echo "INFO: Connection to raspberrypi-$host established."
	else
	  echo "ERROR: Unable to establish ssh connection to raspberrypi-$host"
	  echo "     : Most probable cause, wrong ssh key used."
	  echo "     : Make sure your key is in ./bin"
	fi
}

function get_static_image() {
	echo "INFO: Take test picture function called with target: $1  ssh key: $2"
	ssh -i ./bin/$2 pi@raspberrypi-$1 rm testimg.jpeg
	ssh -i ./bin/$2 pi@raspberrypi-$1 raspistill -t 1 -o testimg.jpeg -n -w 1920 -h 1080
	load_ani
	echo "STATUS: Downloading image."
	scp -i ./bin/$2 pi@raspberrypi-$1:~/testimg.jpeg ./testimg.jpeg
	ssh -i ./bin/$2 pi@raspberrypi-$1 rm testimg.jpeg
	

}

function get_update() {
	echo "INFO: Get update called with target: $1  ssh key: $2"

	if [ -f ./bin/check.sh ]
	then
		rm ./bin/check.sh
	fi

	touch ./bin/check.sh

	echo "#!/usr/bin/env bash
	if [ -f timelapse_status.txt ]
	then
		cat timelapse_status.txt
	else
		echo \"
		====--------||--------====
    Program not yet started.
    ====--------||--------====\" >> timelapse_status.txt
		cat timelapse_status.txt
	fi
	" >> ./bin/check.sh

	ssh -i ./bin/$2 pi@raspberrypi-$1 'bash -s' < ./bin/check.sh

	rm ./bin/check.sh

}

function cancel_running_lapse() {
	echo "INFO: Cancel running time lapse called with target: $1  ssh key: $2"


	

}

function image_removal(){
	NUMBER=$(ssh -i ./bin/$2 pi@raspberrypi-$1 ls -1 $3/TimeLapse_images | wc -l)

	#if there are images
	if ! [ $NUMBER -eq 0 ]
	then
		echo "INFO: There are currently: $NUMBER images on $1"
		echo "    : If you continue with this setup they will be permanently removed."
		read -p "OPTION: Continue with this setup? y/n: " continue_option
		if [ "$continue_option" == "n" ] || [ "$continue_option" == "N" ] || [ "$continue_option" == "no" ] || [ "$continue_option" == "No" ]
		then
			echo "STATUS: Cancelling setup..."
			exit 1
		fi
		#remove all files
		ssh -i ./bin/$2 pi@raspberrypi-$1 rm $3/TimeLapse_images/*
	fi
}

function setup(){
	echo "INFO: Setup function called with target: $1  ssh key: $4"

	

	HOME=/home/pi
	TIMELAPSE=/home/pi/TimeLapse

	if [ ! -f ./bin/lapse.py ]
	then
		echo "ERROR: lapse.py program does not exist in bin."
		exit 1
	fi

	if [ -f ./bin/check.sh ]
	then
		rm ./bin/check.sh
	fi

	touch ./bin/check.sh

	echo "#!/usr/bin/env bash
	if [ -d ~/TimeLapse ] && [ -d ~/TimeLapse_images ]
	then
	  echo \"both\"

	elif [ ! -d ~/TimeLapse ] && [ -d ~/TimeLapse_images ]
	then
	  echo \"image\"

	elif [ -d ~/TimeLapse ] && [ ! -d ~/TimeLapse_images ]
	then
	  echo \"main\"

	elif [ ! -d ~/TimeLapse ] && [ ! -d ~/TimeLapse_images ]
	then
		echo \"none\"

	fi
	" >> ./bin/check.sh

	FOLDER_STATUS=$(ssh -i ./bin/$4 pi@raspberrypi-$1 'bash -s' < ./bin/check.sh)

	rm ./bin/check.sh

	#if both folders exist
	if [ "$FOLDER_STATUS" == "both" ]
	then
		echo "STATUS: All folder exist status. Continuing..."
		image_removal $1 $4 $HOME

	#if only image folder exists
	elif [ "$FOLDER_STATUS" == "image" ]
	then
	echo "STATUS: $TIMELAPSE not found on $1. Creating..."
	ssh -i ./bin/$4 pi@raspberrypi-$1 mkdir $HOME/TimeLapse
	image_removal $1 $4 $HOME


	#if only main folder exists
	elif [ "$FOLDER_STATUS" == "main" ]
	then
	echo "STATUS: Folder status acceptable on $1. Continuing..."

	#if no folders exist
	elif [ "$FOLDER_STATUS" == "none" ]
	then
		echo "STATUS: $TIMELAPSE not found on $1. Creating..."
		ssh -i ./bin/$4 pi@raspberrypi-$1 mkdir $HOME/TimeLapse
	else
		echo "ERROR: Unknown folder status."
		echo "     : This could be from an incorrect ssh key."
		echo "$FOLDER_STATUS"
		exit 1
	fi

	#copy lapse.py to server
	echo "STATUS: Uploading camera control file..."
	scp -i ./bin/$4 ./bin/lapse.py pi@raspberrypi-$1:$TIMELAPSE/lapse.py

	#ssh -i ./bin/$4 pi@raspberrypi-$1 ls "$TIMELAPSE"

	echo "STATUS: Setting up program..."
	ssh -i ./bin/$4 pi@raspberrypi-$1 nohup python $TIMELAPSE/lapse.py $2 $3 &
	if [ -f ./bin/output.txt ]
	then
		rm ./bin/output.txt
	fi

	if [ -f ./nohup.out ]
	then
		rm ./nohup.out
	fi

	load_ani
	echo "STATUS: Downloading output file..."
	scp -i ./bin/$4 pi@raspberrypi-$1:$HOME/timelapse_output.txt ./bin/output.txt

	cat ./bin/output.txt


}


UNIQUE_NAME="-"
TIME_INTERVAL="-"
NUMBER_OF_IMAGES="-"
KEY_NAME="-"
TOGGLE="-"

if [[ $# -eq 0 ]]
then
  usage
  exit 1
fi

while [[ $# -gt 0 ]]; do
	case "${1}" in
	  -h|--help)
			usage
			;;
		--viewtest)
			if [ -z "${2}" ] || [[ "${2}" == -* ]]
			then
			  echo "ERROR: (--viewtest) Target not defined."
			  exit 1
			else
				UNIQUE_NAME=${2}
				TOGGLE="view"
			fi
			shift 2
			;;
		--cancel)
			if [ -z "${2}" ] || [[ "${2}" == -* ]]
			then
				echo "ERROR: (--cancel) Target not defined."
				exit 1
			else
				UNIQUE_NAME=${2}
				TOGGLE="cancel"
			fi
			shift 2
			;;
		--status)
			if [ -z "${2}" ] || [[ "${2}" == -* ]]
			then
				echo "ERROR: (--status) Target not defined."
				exit 1
			else
				UNIQUE_NAME=${2}
				TOGGLE="status"
			fi
			shift 2
			;;
		--start|-s)
			if [ -z "${2}" ] || [[ "${2}" == -* ]]
			then
				echo "ERROR: (--start) Target not defined."
				exit 1
			elif [ -z "${3}" ] || [[ "${3}" == -* ]]
			then
				echo "ERROR: (--start) Time interval not defined."
				exit 1
			elif [ -z "${4}" ] || [[ "${4}" == -* ]]
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
			;;
		--key|-k|-i)
			if [ -z "${2}" ] || [[ "${2}" == -* ]]
			then
				echo "ERROR: (--key) ssh key not defined."
				exit 1
			elif [ ! -f "./bin/${2}" ]
      then
        echo "ERROR: Key: ./bin/${2} does not exist."
        exit 1
      else
      	KEY_NAME=${2}
      fi
      shift 2
      ;;
		*)
			echo "FATAL: Unknown command-line argument or enviroment: ${1}"
			exit 1
			;;
	esac
done

#check that all neede variables set
validation $KEY_NAME $UNIQUE_NAME

if [ "$TOGGLE" == "start" ]
then
	setup $UNIQUE_NAME $TIME_INTERVAL $NUMBER_OF_IMAGES $KEY_NAME
elif [ "$TOGGLE" == "view" ]
then
	get_static_image $UNIQUE_NAME $KEY_NAME
elif [ "$TOGGLE" == "status" ]
then
	get_update $UNIQUE_NAME $KEY_NAME
elif [ "$TOGGLE" == "cancel" ]
then
	cancel_running_lapse $UNIQUE_NAME $KEY_NAME
else
	echo "FATAL: No mode selected."
	usage
fi
