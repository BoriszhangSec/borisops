#!/bin/bash
#script name:dump_disk_check.sh
 
find /app/callcenter/logs -name "*.log" -mtime +5 |xargs -I {}  rm -f {}
find /app/callcenter/ccproxy-tomcat/logs -mtime +5 |xargs -I {}  rm -f {}
find /app/dumpdata/ -name "fs_signal.*" -mtime +4 |xargs -I {} rm -f {}
find /app/clpms/ -name "clpms.log.*" -mtime +3 |xargs -I {} rm -f {}
find /app/ccp_pgm_server/log -name "sip.log*" -mtime +4 |xargs -I {} rm -f {}
find /app/callmanager/ -name "*.log" -mtime +0  |xargs -I {} rm -f {}
find /app/TTSVOICE/  -name *.wav -mtime +1 |xargs -I {} rm -f {}
find /app/dumpdata/ -name "*cap*" -mtime +5 |xargs -I {} rm {} -f
find /app/rmserver/log/ -name "*.log" -mtime +3 |xargs -I {} rm {} -f 
find /data/clpss-log/  -name "*.log" -mtime +5 |xargs -I {} rm -f {}
find /app/clpss/log/ -name "*.log" -mtime +7 |xargs -I {} rm -f {}
find /app/callmanager/ -name "*.cdr" -mtime +63 |xargs -I {} rm -f {}
find /app/cdrserver/ -name "*.cdr.done" -mtime +65 |xargs -I {} rm -f {}
find /data/alarmcenter-log/logfiles-2015/  -type d -mtime +2 |xargs -I {} rm -rf {}
find /app/RDMServer/work/log  -name "*.log" -mtime +18 |xargs -I {} rm -f
find /app/clpms/ -name "*.ring_asr.pcm" -mtime +1 |xargs -I {} rm -f {}
find /app/clpms/ -name "Master.csv*" -mtime +90|grep  log/cdr-csv/Master.csv |xargs -I {} rm -f {}
find /app/restserver_2002/logs -mtime +5 |xargs -I {} rm -f {}
find /app/restserver_2001/logs -mtime +5 |xargs -I {} rm -f {}
find /app/sipdump/  -maxdepth 2 -type d -mtime +2 |xargs -I {} rm -rf {}
find /app/server/portal-tomcat-6.0.36/logs -mtime +30 |xargs -I {} rm -f {}
sipdump=`du -sh /app/sipdump |awk -F G '{print $1}'`
if [ $sipdump -ge 230 ]
	then
		find /app/sipdump/  -maxdepth 1 -type d -mtime +1 |xargs -I {} rm -rf {}
		sipdump=`du -sh /app/sipdump |awk -F G '{print $1}'`
		if [ $sipdump -ge 230 ]
		then
			find /app/sipdump/  -maxdepth 1 -type d -mtime +0 |xargs -I {} rm -rf {}
fi
fi
#1 2 * * *  /app/yunwei/dump_disk_check.sh > /dev/null 2>&1

