#!/bin/bash

function usage() {
  echo "Usage: $(basename ${0}) --(fetch | local) [-h | --help]"
  echo "        -p {path}"
  echo ""
  echo " --fetch    - Fetch timelapse images from Raspberry Pi."
  echo " --local    - Use locally stored timelapse images."
  echo ""
  echo " --path     -p    - Path to local timelapse image directory."
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
    echo "Directory has  in it. Continuing."
  else
    echo "Directory is empty.  this "
    exit 1
  fi
}

IMAGE_PATH="./images"

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
      fetch_images
      render $IMAGE_PATH
      shift;;
    --path)
      if [ -z "${2}" ]
      then
        echo "ERROR: (--path|-p) Path not defined"
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
