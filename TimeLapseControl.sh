#!/usr/bin/env bash

function usage() {
	echo "Usage: $(basename ${0}) --[ viewtest {unique name}"
	echo "                          | start {unique name} {time interval} {number of images}"
	echo "                          | status {unique name}"
	echo "                          | cancel {unique name}"
	echo "                          | remote {unique name}"
	echo "                          | fetch {unique name}]"
	echo "                            --key {ssh key name}"
	echo "                          | local {folder}"
	echo "                          	--help"
	echo ""
	echo "               Examples:"
	echo "               $(basename ${0}) --key my-private-key --start maleficent 5 2000"
	echo "               $(basename ${0}) --i my-private-key --status maleficent"
	echo "               $(basename ${0}) --local folder_of_images"
	echo ""
	echo ""
	echo "    Camera interface controls:"
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
	echo "        Render controls:"
	echo " --remote             - Fetch timelapse images from Raspberry Pi, then render them."
	echo "                        'unique name' referes to the name suffix of the Raspberry Pi."
 	echo "                        Assumes that the remote path is ~/TimeLapse_images/"
 	echo "                        Saves images to ./images/ in same working directory."
 	echo " --local              - Use locally stored timelapse images."
 	echo "                        'folder' is the name of the local folder (path from same working directory) to get images from."
	echo ""
	echo " --key       -k/-i    - Provides the ssh key for the connection."
	echo ""
	echo " --help        -h     - This page."
	echo ""
	echo " --fetch              - Fetch timelapse images form Raspberry Pi, and save to folder."
	echo "                        Saves to folder ./images and will overwrite any images in ./images"
	echo "                        to prevent this rename the folder to something else. --fetch will create a new folder called ./images to save too."
	echo "                        'unique name' referes to the name suffix of the Raspberry Pi."
	echo ""
	echo ""
	echo " Hint."
	echo "      If you enter mutiple of the control switches the program will run the last one entered."
	echo ""
	exit -1
}

function load_ani() {
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

	echo ""

	#key name check
	if [ "$key" == "-" ]
	then
		echo "ERROR: (--key) ssh key not defined."
		exit 1
	fi

	#hostname ping test
	ping -c 1 raspberrypi-$host > /dev/null 2>&1
	if [ $? -ne 0 ]
	then
		echo "ERROR: Host raspberrypi-$host unreachable/offline."
		exit 1
	else
		echo "INFO: Host raspberrypi-$host online."
	fi

	echo ""

	#connection test
	extcode=$(ssh -i ./bin/$key pi@raspberrypi-$host echo "ssh connection test")
	if [ "$extcode" == "ssh connection test" ]
	then
	  echo "INFO: Connection to raspberrypi-$host established."
	else
	  echo "ERROR: Unable to establish ssh connection to raspberrypi-$host"
	  echo "     : Most probable cause, wrong ssh key used."
	  echo "     : Make sure your key is in ./bin"
	  exit 1
	fi

	echo ""

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
	
	EXIST=$(ssh -i ./bin/$2 pi@raspberrypi-$1 'if [ -f timelapse_status.txt ]; then echo "y"; fi')

	if [ ! "$EXIST" == "y" ]
	then
		echo -e "    ====--------||--------====\n    Program not yet started.\n    ====--------||--------===="
	else
		ssh -i ./bin/$2 pi@raspberrypi-$1 cat timelapse_status.txt
	fi

	NUMBER=$(ssh -i ./bin/$2 pi@raspberrypi-$1 ls -1 TimeLapse_images | wc -l)

	echo "INFO: There are $NUMBER images currently on host $1"

}

function cancel_running_lapse() {
	echo "INFO: Cancel running time lapse called with target: $1  ssh key: $2"

	RUNNING=$(ssh -i ./bin/$2 pi@raspberrypi-$1 pidof python)
	echo "$RUNNING"
	if [ ! "$RUNNING" == "" ]
	then
		NUMBER=$(ssh -i ./bin/$2 pi@raspberrypi-$1 ls -1 TimeLapse_images | wc -l)
		echo "STATUS: Downloading output file..."
		scp -i ./bin/$2 pi@raspberrypi-$1:timelapse_output.txt ./bin/output.txt

		echo ""
		cat ./bin/output.txt
		echo ""
		echo "$NUMBER images have already been taken (and will not be deleted if you halt)."
		read -p "OPTION: Are you sure you want to halt the timelapse? y/n: " halt_option

		if [ "$halt_option" == "y" ] || [ "$halt_option" == "Y" ] || [ "$halt_option" == "yes" ] || [ "$halt_option" == "Yes" ]
		then
			ssh -i ./bin/$2 pi@raspberrypi-$1 'killall -w python; rm timelapse_status.txt'
		fi
	else
		echo "INFO: Timelapse is not running, therefore cannot be halted."
	fi

	echo ""
	echo "INFO: python process successfully killed on target $1"
	echo "INFO: Timelapse halted."
	NUMBER=$(ssh -i ./bin/$2 pi@raspberrypi-$1 ls -1 TimeLapse_images | wc -l)
	echo "INFO: $NUMBER images remain on device."

}

function image_removal(){
	NUMBER=$(ssh -i ./bin/$2 pi@raspberrypi-$1 ls -1 TimeLapse_images | wc -l)

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

	echo ""
	cat ./bin/output.txt

}

function fetch_images() {
  echo "INFO: Fetch images function called with target: $1  ssh key: $2"
  FOLDER_EXIST=$(ssh -i ./bin/$2 pi@raspberrypi-$1 'if [ -d TimeLapse_images ]; then echo "y"; fi')
  NUMBER=$(ssh -i ./bin/$2 pi@raspberrypi-$1 ls -1 TimeLapse_images | wc -l)

  if [ ! "$FOLDER_EXIST" == "y" ] || [ "$NUMBER" == "0" ]
  then
    echo "ERROR: No files exist on target."
    exit 1
  fi

  if [ -d images ]
  then
  	echo "INFO: Default images folder exists."
  	echo "    : Continuing with this download will remove all currently stored images in ./images."
  	read -p "OPTION: Do you want to continue with this download? y/n: " rmimages

  	if [ "$rmimages" == "y" ] || [ "$rmimages" == "Y" ] || [ "$rmimages" == "yes" ] || [ "$rmimages" == "Yes" ]
  	then
			echo "STATUS: Removing local ./images..."
			rm -r images || exit 1
		else
			echo "STATUS: Cancelling download..."
			exit 1
		fi
  fi

  echo "STATUS: Saving images to folder ./images ..."
  scp -r -i ./bin/$2 pi@raspberrypi-$1:~/TimeLapse_images ./images
  echo "INFO: $NUMBER files downloaded..."

}

function render() {
  echo "INFO: Rendering Function called with path: $1"

  #Check if directory is empty
  if [ "$(ls -A $1)" ]
  then
    echo "STATUS: $1 has files in it. Continuing..."
  else
    echo "ERROR: $1 is empty."
    exit 1
  fi

  #Check if ffmpeg exists
  if [ ! -f ffmpeg ]
  then
  	echo "ERROR: ffmpeg does not exist in local directory."
  	echo "     : Download ffmpeg from either"
    echo "     : https://www.ffmpeg.org/Download/ or http://ffbinaries.com/downloads"
    echo "     : and extract the ffmpeg file to local location."
    echo "     : The images will not be deleted."
  	exit 1
  fi


  #Does the user want to clean up afterwards
  read -p "OPTION: Do you want to remove ALL files in the image directory after render complete? y/n: " remove_option
  read -p "OPTION: What framerate do you want in the output video? (Leave blank for 20): " fps 

  if [ "$fps" == "" ]
  then
    fps="20"
  fi

  #Render
  ./ffmpeg -r $fps -start_number 0001 -i $1/%04d.jpeg -s 1920x1080 -vcodec libx264 video.mp4

  #Removing unneeded files (possibly)
  if [ "$remove_option" == "y" ] || [ "$remove_option" == "Y" ] || [ "$remove_option" == "yes" ] || [ "$remove_option" == "Yes" ]
  then
  	echo "STATUS: Cleaning up unneeded files..."
  	rm -r $1
  fi

  echo "INFO: Render complete."

}


UNIQUE_NAME="-"
TIME_INTERVAL="-"
NUMBER_OF_IMAGES="-"
KEY_NAME="-"
TOGGLE="-"
IMAGE_PATH="-"

if [[ $# -eq 0 ]]
then
  usage
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
    --remote)
			if [ -z "${2}" ] || [[ "${2}" == -* ]]
			then
				echo "ERROR: (--remote) Target not defined."
				exit 1
			else
				UNIQUE_NAME=${2}
	      IMAGE_PATH="./images"
	      TOGGLE="remote"
    	fi
    	shift 2
   	 	;;
  	--local)
	    if [ -z "${2}" ] || [[ "${2}" == -* ]]
	    then
	      echo "ERROR: (--local) Path not defined."
	      exit 1
	    else
	      if [ -d ${2} ]
	      then
	        IMAGE_PATH=${2}
	        TOGGLE="local"
	      else
	        echo "ERROR: Path: ${2} does not exist."
	        exit 1
	      fi
	    fi
	    shift 2
	    ;;
	  --fetch)
			if [ -z "${2}" ] || [[ "${2}" == -* ]]
			then
				echo "ERROR: (--fetch) Target not defined."
				exit 1
			else
				UNIQUE_NAME=${2}
				TOGGLE="fetch"
			fi
			shift 2
			;;
		*)
			echo "FATAL: Unknown command-line argument or enviroment: ${1}"
			exit 1
			;;
	esac
done



if [ "$TOGGLE" == "start" ]
then
	validation $KEY_NAME $UNIQUE_NAME
	setup $UNIQUE_NAME $TIME_INTERVAL $NUMBER_OF_IMAGES $KEY_NAME

elif [ "$TOGGLE" == "view" ]
then
	validation $KEY_NAME $UNIQUE_NAME
	get_static_image $UNIQUE_NAME $KEY_NAME

elif [ "$TOGGLE" == "status" ]
then
	validation $KEY_NAME $UNIQUE_NAME
	get_update $UNIQUE_NAME $KEY_NAME

elif [ "$TOGGLE" == "cancel" ]
then
	validation $KEY_NAME $UNIQUE_NAME
	cancel_running_lapse $UNIQUE_NAME $KEY_NAME

elif [ "$TOGGLE" == "remote" ]
then
	validation $KEY_NAME $UNIQUE_NAME
	fetch_images $UNIQUE_NAME $KEY_NAME
	render $IMAGE_PATH

elif [ "$TOGGLE" == "local" ]
then
	render $IMAGE_PATH

elif [ "$TOGGLE" == "fetch" ]
then
	validation $KEY_NAME $UNIQUE_NAME
	fetch_images $UNIQUE_NAME $KEY_NAME

else
	echo "FATAL: No mode selected."
	usage
fi
