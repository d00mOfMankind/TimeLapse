#!/usr/bin/python
import os

def usage():
  print("Usage: $(basename ${0}) --(fetch {user@hostname} | local {path}) [-h | --help]")
  print("")
  print(" --fetch     - Fetch timelapse images from Raspberry Pi.")
  print(" --local     - Use locally stored timelapse images.")
  print(" --help  -h  - View this page.")
  print("")
  exit()


def fetch_images(user, host, ssh_key):
	print("INFO: Fetch images function called.")


def render(path):
	print("INFO: Rendering Function called with path: " + path)

	#check if directory is empty
	if os.listdir(path) == []:
		print(path + " is empty.")
		exit()
	else:
		print(path + " has files in it. Continuing...")

	#check if ffmpeg exists
	if os.path.isfile("ffmpeg"):
		pass
