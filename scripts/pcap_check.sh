#!/bin/bash

ncnt=`ps -ef|grep pcapsipdump|wc -l`

if [ $ncnt -lt 2 ] ; then
  sleep 1;
  ncnt=`ps -ef|grep pcapsipdump|wc -l`;
  if [ $ncnt -lt 2 ] ; then
	/usr/sbin/pcapsipdump -s -w 4 -d /app/sipdump/ -i any -B 512MiB -x 600 -R none -o 7600 -o 7610 -o 7690 -o 8600 -o 8610 -o 8690 -o 9600 -o 9610 -o 5080 -o 5060 -o 8880 &
	#/usr/sbin/pcapsipdump -s -w 4 -d /app/sipdump/ -i any -B 512MiB -x 600 -y 20 -o 7600 -o 7610 -o 7690 -o 8600 -o 8610 -o 8690 -o 9600 -o 9610 -o 5080 -o 5060 -o 8880 & 
 fi
fi

