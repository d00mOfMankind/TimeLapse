#!/usr/bin/env bash

function usage() {
  echo "Usage: $(basename ${0}) --[ remote {unique name}"
  echo "                          | fetch {unique name}"
  echo "                          | local {path}]"
  echo "                            --key {ssh key name}"
  echo "                            --help"
  echo ""
  echo "   Examples:   $(basename ${0}) --fetch maleficent --key my-private-key"
  echo "               $(basename ${0}) --local images"
  echo ""
  echo " --remote             - Fetch timelapse images from Raspberry Pi."
  echo "                        'unique name' referes to the name suffix of the Raspberry Pi."
  echo "                        remote assumes that the remote path is ~/TimeLapse_images"
  echo "                        'ssh key name' is the name of the ssh private key that the program."
  echo "                        will attempt to connect with. This should be placed in ./bin"
  echo " --local              - Use locally stored timelapse images."
  echo "                        'folder' is the name of the local folder (path from same working directory) to get images from."
  echo " --fetch              - Fetch timelapse images form Raspberry Pi, and save to folder."
  echo "                        Saves to folder ./images and will overwrite any images in ./images"
  echo "                        to prevent this rename the folder to something else. --fetch will create a new folder called ./images to save too."
  echo "                        'unique name' referes to the name suffix of the Raspberry Pi."
  echo ""
  echo " --key       -k/-i    - Provides the ssh key for the connection."
  echo ""
  echo " --help       -h      - View this page."
  echo ""
  exit -1
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

IMAGE_PATH="-"
UNIQUE_NAME="-"
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
      echo "FATAL: Unknown command-line argument or environment: ${1}"
      exit 1
      ;;
  esac
done

if [ "$TOGGLE" == "remote" ]
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