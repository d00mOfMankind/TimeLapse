#!/usr/bin/env bash

function usage() {
  echo "Usage: $(basename ${0}) --[ remote {unique name} {ssh key name}"
  echo "                          | local {path}]"
  echo "                            --help"
  echo ""
  echo "   Examples:   $(basename ${0}) --remote maleficent my-private-key"
  echo "               $(basename ${0}) --local images"
  echo ""
  echo " --remote     -r      - Fetch timelapse images from Raspberry Pi."
  echo "                        'unique name' referes to the name suffix of the Raspberry Pi."
  echo "                        remote assumes that the remote path is ~/TimeLapse_images"
  echo "                        'ssh key name' is the name of the ssh private key that the program."
  echo "                        will attempt to connect with. This should be placed in ./bin"
  echo " --local      -l      - Use locally stored timelapse images."
  echo ""
  echo " --help       -h      - View this page."
  echo ""
  exit -1
}

function fetch_images() {
  echo "INFO: Fetch images function called with target: $1  ssh key: $2"

  scp -i ./bin/$2 -r pi@raspberrypi-$1:~/TimeLapse_images ./images

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
  read -p "OPTION: What framerate do you want in the output video? : " fps 

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

IMAGE_PATH=""
UNIQUE_NAME=""
KEY_NAME=""

if [[ $# -eq 0 ]]
then
  usage
  exit 1
fi

#this is a redundant while loop... But will remain as example

case "${1}" in
  -h|--help)
    usage
    ;;
  --remote|-r)
		if [ -z "${2}" ]
		then
			echo "ERROR: (--remote) Target not defined."
			exit 1
    elif [ -z "${3}" ]
    then
      echo "ERROR: (--remote) ssh key not defined."
      exit 1
		else
      if [ ! -f "./bin/${3}" ]
      then
        echo "ERROR: Key: ./bin/${3} does not exist."
      fi
			UNIQUE_NAME=${2}
      KEY_NAME=${3}
      IMAGE_PATH="./images"
			fetch_images $UNIQUE_NAME $KEY_NAME
      render $IMAGE_PATH
    fi
    ;;
  --local|-l)
    if [ -z "${2}" ]
    then
      echo "ERROR: (--local) Path not defined."
      exit 1
    else
      if [ -d ${2} ]
      then
        IMAGE_PATH=${2}
        render $IMAGE_PATH
      else
        echo "ERROR: Path: ${2} does not exist."
        exit 1
      fi
    fi
    ;;
  *)
    echo "FATAL: Unknown command-line argument or environment: ${1}"
    exit 1
    ;;
esac
