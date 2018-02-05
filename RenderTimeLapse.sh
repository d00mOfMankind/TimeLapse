#!/usr/bin/env bash

function usage() {
  echo "Usage: $(basename ${0}) --(remote {unique name} {ssh key name} | local {path}) [-h | --help]"
  echo ""
  echo "   Example:   $(basename ${0}) --remote maleficent my-private-key"
  echo ""
  echo " --remote             - Fetch timelapse images from Raspberry Pi."
  echo "                        'unique name' referes to the name suffix of the Raspberry Pi."
  echo "                        remote assumes that the remote path is ~/TimeLapse/tl/"
  echo "                        'ssh key name' is the name of the ssh private key that the program."
  echo "                        will attempt to connect with. This should be placed in ./bin"
  echo " --local              - Use locally stored timelapse images."
  echo " --help       -h      - View this page."
  echo ""
  exit -1
}

function fetch_images() {
  echo "INFO: Fetch images function called with target: $1"

  scp -r pi@raspberrypi-$1:~/TimeLapse/tl ./images

}

function render() {
  echo "INFO: Rendering Function called with path: $1"

  #Check if directory is empty
  if [ "$(ls -A $1)" ]
  then
    echo "$1 has files in it. Continuing..."
  else
    echo "=--------------------------------------------------------------------------------------------------="
    echo "$1 is empty."
    echo "=--------------------------------------------------------------------------------------------------="
    exit 1
  fi

  #Check if ffmpeg exists
  if [ ! -f ffmpeg ]
  then
    echo "=--------------------------------------------------------------------------------------------------="
  	echo "ffmpeg does not exist in local directory."
  	echo "Download ffmpeg from https://www.ffmpeg.org/Download/ and extract the ffmpeg file to local location."
    echo "The images will not be deleted."
    echo "=--------------------------------------------------------------------------------------------------="
  	exit 1
  fi


  #Does the user want to clean up afterwards
  read -p "Do you want to remove ALL files in the image directory after render complete? y/n: " removeOption
  read -p "What framerate do you want in the output video? : " fps 

  #Render
  ./ffmpeg -r $fps -start_number 0001 -i $1/%04d.jpeg -s 1920x1080 -vcodec libx264 video.mp4

  #Removing unneeded files (possibly)
  if [ "$removeOption" == "y" ] || [ "$removeOption" == "Y" ] || [ "$removeOption" == "yes" ] || [ "$removeOption" == "Yes" ]
  then
  	echo "Cleaning up unneeded files..."
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
while [[ $# -gt 0 ]]; do
  case "${1}" in
    -h|--help)
      usage;;
    --remote)
			if [ -z "${2}" ]
			then
				echo "ERROR: (--remote) Target not defined."
				exit 1
      elif [ -z "${3}" ]
      then
        echo "ERROR: (--remote) ssh key not defined."
        exit 1
			else
        if [ -f "${3}" ]
        then
          echo "ERROR: Key: ${3} does not exist."
        fi
				UNIQUE_NAME=${2}
				fetch_images $UNIQUE_NAME
        render $IMAGE_PATH
      fi
      shift 2;;
    --local)
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
      shift 2;;
    *)
      echo "FATAL: Unknown command-line argument or environment: ${1}"
      exit 1
  esac
done
