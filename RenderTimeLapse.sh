#!/usr/bin/env bash

function usage() {
  echo "Usage: $(basename ${0}) --(fetch {unique name} | local {path}) [-h | --help]"
  echo ""
  echo " --fetch     - Fetch timelapse images from Raspberry Pi. 'Unique name' referes to the name suffix of the Raspberry Pi"
  echo "               Fetch assumes that the remote path is ~/TimeLapse/tl/"
  echo " --local     - Use locally stored timelapse images."
  echo " --help  -h  - View this page."
  echo ""
  exit -1
}

function fetch_images() {
  echo "INFO: Fetch images function called."

  scp -r pi@raspberrypi-$1:~/TimeLapse/tl ./images
  
  IMAGE_PATH="./images"

  render $IMAGE_PATH

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
    echo "=--------------------------------------------------------------------------------------------------="
  	exit 1
  fi

  #Does the user want to clean up afterwards
  read -p "Do you want to remove ALL .jpeg images in the image directory after render complete? y/n: " removeOption

  #Render
  cp ffmpeg $1/ffmpeg
  $1/ffmpeg -r 20 -start_number 0001 -i "%04d.jpeg" -s 1920x1080 -vcodec libx264 video.mp4
  rm $1/ffmpeg
  mv $1/video.mp4 ./video.mp4

  #Removing unneeded files (possibly)
  if [ "$removeOption" == "y" ] || [ "$removeOption" == "Y" ] || [ "$removeOption" == "yes" ] || [ "$removeOption" == "Yes" ]
  then
  	echo "Cleaning up unneeded files..."
  	rm -r $1
  fi

  echo "INFO: Render complete."

}

IMAGE_PATH="./images"
UNIQUE_NAME="bane"

if [[ $# -eq 0 ]]
then
  usage
  exit 1
fi

while [[ $# -gt 0 ]]; do
  case "${1}" in
    -h|--help)
      usage;;
    --fetch)
			if [ -z "${2}" ]
			then
				echo "ERROR: (--fetch) Target not defined"
				exit 1
			else
				UNIQUE_NAME=${2}
				fetch_images $UNIQUE_NAME
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
          echo "ERROR: Path: ${2} Does not exist"
          exit 1
        fi
      fi
      shift 2;;
    *)
      echo "FATAL: Unknown command-line argument or environment: ${1}"
      exit 1
  esac
done
