#!/bin/bash
#export JAVA_HOME='/usr/local/jdk'
SNpath="/"
SNfile=`ls $SNpath |grep -E "SN[0-9]{10}$"`
LogFile="$HOME/tomcat_ctl.log"
LockFile="$HOME/tomcat.lock"
if [ $? -ne 0 ];then
    echo "${SNpath}SNfile is not exist"
    exit 1
fi
WSPath=`awk -F= '/^WSPath/ {print $2}' $SNpath$SNfile`
if [ ! -d "$WSPath" ];then
     echo "WSPath is not exist"
     exit 1
fi

if [ -f $LockFile ];then
    echo "$0 is running" 
    echo "`date +"%Y-%m-%d %H:%M:%S"` $0 is running" >>$LogFile
    exit 1
else
    touch $LockFile
fi




start()
{
  command="$WSPath/bin/startup.sh"
  if [ "$USER" ==  'yz' ] || [ "$USER" ==  'root' ] ;then
    sudo -u www $command
  elif [ "$USER" == 'tomcat' ];then
   $command
  fi
  if [ $? -ne 0 ];then
      echo "tomcat startup fail"
      echo "`date +"%Y-%m-%d %H:%M:%S"` tomcat startup fail" >>$LogFile
  else
      echo "tomcat startup ok"
      echo "`date +"%Y-%m-%d %H:%M:%S"` Tomcat start" >>$LogFile
  fi 
}



stop()
{  
 TPID=`ps aux|grep $WSPath|grep -v grep|awk '{print $2}'`
 if  [ "a$TPID" != "a" ];then 
    if [ "$USER" == 'yz' ] || [ "$USER" ==  'root' ];then
         sudo kill -9 "$TPID" 
         sudo rm -rf $WSPath/work/*
    elif [ "$USER" == 'tomcat' ];then
         kill -9 "$TPID"
         rm -rf $WSPath/work/*
    fi 
     echo " Tomcat stop ok"   
     echo "`date +"%Y-%m-%d %H:%M:%S"` Tomcat stop" >>$LogFile   
 fi 

}


case "$1" in
    start)
         start
         rm $LockFile
         ;;
    stop)
         stop
          rm $LockFile
         ;;
 restart)
        stop
        start
        rm $LockFile
        ;; 

      *)
        echo "Usage : tomcatctl.sh {start|stop|restart}"
         rm $LockFile
      ;;
 esac 

