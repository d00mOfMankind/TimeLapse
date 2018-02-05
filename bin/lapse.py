# Program to take time lapse photos

from picamera import PiCamera
cam = PiCamera()
cam.resolution = (1920, 1080) #set resolution
import datetime
import sys
import os
#import time #debug

if os.path.isfile("output.txt"):
	os.remove("output.txt")


outputFile = open("output.txt", "a")


#take time interval, number of photos
try:
	ti = float(sys.argv[1])
	number = float(sys.argv[2])
except ValueError:
	print("ERROR: Enter integers for both arguments.\narg 1 = time interval\narg 2 = number of images to capture")
	outputFile.write("ERROR: Enter integers for both arguments.\narg 1 = time interval\narg 2 = number of images to capture")
	exit()
except IndexError:
	print("ERROR: Must enter a value for both arguments.\narg 1 = time interval\narg 2 = number of images to capture")
	outputFile.write("ERROR: Must enter a value for both arguments.\narg 1 = time interval\narg 2 = number of images to capture")
	exit()
	
ti = int(ti) #remove decimal
ti = float(ti) #return to float
number = int(number)
number = float(number)

outputFile.write("Time interval    : " + str(ti) + "\n")
outputFile.write("Number of images : " + str(number) + "\n")

#print datetime that program will be finished
startTime = datetime.datetime.now()
lastTime = startTime
runTime = (ti * number)
endTime = startTime + datetime.timedelta(seconds = int(runTime))
calcRunTime = ""
if (runTime/60) >= 60:
	calcRunTime = str((runTime/60)/60) + " hours." #if run time larger than an hour
else:
	calcRunTime = str(runTime/60) + " minutes." #if run time smaller than an hour

outputFile.write("Start time       : " + str(startTime) + "\n")
outputFile.write("Run time         : " + calcRunTime + "\n") #how long the program will run for
outputFile.write("End time         : " + str(endTime) + "\n") #the time that the program will end
outputFile.close()
#print("Start time       : " + str(startTime) + "\nRun time         : " + calcRunTime + "\nEnd time         : " + str(endTime) + "\n")

#start main loop
#MAKE SURE TO ACCOUNT FOR COMPUTE TIME BETWEEN IMAGES
counter = 0
imgLoc = ""
if not (os.path.isdir("tl")):
	os.makedirs("tl")

while True:
	now = datetime.datetime.now()
	if now >= lastTime + datetime.timedelta(seconds = ti): #if it has been ti time since last image taken

		imgLoc = "tl/" + "{0:0>4}".format(str(counter+1)) + ".jpeg"
		lastTime = now
		counter+=1

		
		#outputFile.write("PICTURE") #debug
		#time.sleep(1) #debug
		cam.capture(imgLoc) #take picture

	if counter >= number: #when we have taken all pictures
		break

outputFile = open("output.txt", "a")
outputFile.write("Program has now completed.\nfin")
outputFile.close()
