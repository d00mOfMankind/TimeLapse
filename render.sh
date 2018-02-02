#!/bin/bash

function usage() {
  echo "Usage: $(basename ${0}) --(fetch {unique name} | local {path}) [-h | --help]"
  echo ""
  echo " --fetch     - Fetch timelapse images from Raspberry Pi. 'Unique name' referes to the name suffix of the Raspberry Pi"
  echo " --local     - Use locally stored timelapse images."
  echo " --help  -h  - View this page."
  echo ""
  exit -1
}

function fetch_images() {
  echo "INFO: Fetch images function called."


}

function render() {
  echo "INFO: Rendering Function called with path: $1"

  #Check if directory is empty
  if [ "$(ls -A $1)" ]
  then
    echo "$1 has files in it. Continuing..."
  else
    echo "$1 is empty."
    exit 1
  fi

  #Check if ffmpeg exists
  if [ ! -f ffmpeg ]
  then
  	if [ -f ffmpeg.tar.xz ]
  	then
  		echo "Unzipping ffmpeg..."
  		tar -xf ffmpeg.tar.xz
  	else
  		echo "ffmpeg does not exist in local directory."
  		echo "Download from https://www.ffmpeg.org/Download/ and extract to local location"
  		exit 1
  	fi
  fi

  #Does the user want to clean up afterwards
  read -p "Do you want to remove ALL .jpeg images in the image directory y/n: " removeOption

  #Render
  cp ffmpeg $1/ffmpeg
  $1/ffmpeg -r 20 -start_number 0001 -i "%%04d.jpeg" -s 1920x1080 -vcodec libx264 video.mp4
  rm $1/ffmpeg

  #Removing unneeded files (possibly)
  if [ removeOption -eq "y" ] || [ removeOption -eq "Y" ] || [ removeOption -eq "yes" ] || [ removeOption -eq "Yes" ]
  then
  	echo "Cleaning up unneeded files..."
  	rm $1/*.jpeg
  fi



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
      shift;;
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
