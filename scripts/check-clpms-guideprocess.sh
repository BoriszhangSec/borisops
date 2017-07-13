#!/bin/bash
source /app/yunwei/config.ini
clpmspath=${clpmspath:-/app/check_script}
alived=`ps -ef | grep check_clpms| grep -v grep | wc -l`
if [ $alived == "0" ];then
cd $clpmspath
python check_clpms &
fi
