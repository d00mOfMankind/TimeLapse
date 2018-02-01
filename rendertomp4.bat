title Render Script
.\ffmpeg.exe -r 20 -start_number 0001 -i "%%04d.jpeg" -s 1920x1080 -vcodec libx264 temp.mp4
.\ffmpeg.exe -i temp.mp4 -vf "transpose=2,transpose=2" video.mp4
del "temp.mp4"
pause
