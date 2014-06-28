FFmpegMaxFPS
============

Simple Bash script to measure the maximum number of FFmpeg processes
that can run in parallel on one machine without the overall fps 
dropping. The script can be used to get the ideal number of encoding 
jobs per server.

## Usage

```
Usage: ffmpegmaxfps.sh [-L <LOGDIR>] [-T <TEMPDIR>]
	[run|stresstest|printfps] COMMAND
```

## Sample Output

```
sh ffmpegmaxfps.sh stresstest ffmpeg -i sample.mp4 -vcodec libx264 -crf 27 -acodec copy out.mkv
Performing stress test:
############################
Starting process #1
Total FPS=31
Starting process #2
Total FPS=58
Starting process #3
Total FPS=63
Starting process #4
Total FPS=69
Starting process #5
Total FPS=79
Starting process #6
Total FPS=76
############################

The ideal # of processes is: 5
```
