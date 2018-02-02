# lapse.py
- run 'python lapse.py [arg1] [arg2]'
- arg1 being the time interval between images
- arg2 being the number of images you want to capture
- output.txt will tell you the run time and end time (assuming nothing has broken)


## if running from ssh
- run 'nohup python lapse.py [arg1] [arg2] &'
- arg1 being the time interval between images
- arg2 being the number of images you want to capture
- nohup will keep the program running when you disconnect
- & will return you to the terminal on program start


## is it working?
- you can use the command 'ps' to see the processes running
- python should be one of the top ones
- if not then something has gone wrong
- look in output.txt to see
- also a good idea to look in the tl/ folder to check that images are being created

