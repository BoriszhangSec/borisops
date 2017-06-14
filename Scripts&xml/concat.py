#!/usr/bin/env/python2.6
#-*- coding:utf-8 -*-

import os
import sys
import time

file_dir = sys.argv[1]
#video_files = os.popen("ls -lrht " + file_dir + "| grep -v total | head -n 10 | awk '{print $9}'").readlines()
video_files = os.popen("ls -lrht " + file_dir + "| grep -v total | awk '{print $9}'").readlines()
video_path_list = []
for video in video_files:
	video_path = file_dir + video.strip()
	video_path_list.append(video_path)

os.system("ffmpeg -i concat:'" + video_path_list[0] + "|" + video_path_list[1] + "' -vcodec copy -acodec copy -f mpegts tmp1")
for i in range(2,len(video_path_list)):
	os.system("ffmpeg -i concat:'tmp" + str(i-1) + "|" + video_path_list[i] + "' -vcodec copy -acodec copy -f mpegts tmp" + str(i))
	time.sleep(2)
	os.system("rm -f tmp" + str(i-1))
	
