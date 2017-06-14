#!/bin/bash
# MANAGED BY PUPPET
#===============================================================================
#
#          FILE:  monitor_service.sh
#         USAGE:  ./monitor_service.sh
# 
#   DESCRIPTION:  For monitor service status and restart it when the service in error
#                 status but stop.
# 
#        AUTHOR: Sun Qi, sunqi@streamocean.com
#       COMPANY: StreamOcean, Inc.
#       CREATED: 07/26/2013 15:18:06 PM CST
#      REVISION: V0.1
#
#===============================================================================
#set -x
MONITOR_LOG="/tmp/monitor_service.log"
SERVICE_STATUS=`/etc/init.d/streamocean status >& /dev/null;echo $?`
SERVICE_START=`ps -ef|grep streamocean|grep start|grep -v "grep"|wc -l`
SERVICE_RESTART=`ps -ef|grep streamocean|grep restart|grep -v "grep"|wc -l`
RESTARTTIME=`date`
export PATH=/sbin:/usr/sbin:/bin:/usr/bin:/root/bin:$PATH
exec 1>>$MONITOR_LOG 2>&1

if [ "$SERVICE_STATUS" == "1" ] && [ "$SERVICE_RESTART" == "0" ] && [ "$SERVICE_START" == "0" ]
then
    echo "service restart at $RESTARTTIME"
    
    echo "=================="
    free -m
    
    echo "=================="
    df -h
    
    echo "=================="
    top -b -d 3 -n 1

    /etc/init.d/streamocean restart
fi
