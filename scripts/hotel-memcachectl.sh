#!/bin/bash
export PATH=$PATH:/bin:/usr/local/bin:/usr/bin
COMMAND=/usr/bin/memcached
MCuser=memcached
MEMCACHE_VAR=" -u $MCuser -m 4000 -c 3000   -p 11200 -d"
logs="/root/memcache_hotel.log"
start()
   {
      ps aux|grep -v grep|grep memcached|grep 11200 >/dev/null 2>&1
      if [ $? -eq 0 ]
         then
              echo " Hotel memcached is runing";
              exit 1;
         else
              $COMMAND${MEMCACHE_VAR} >>$logs
              if [ $? -eq 0 ]
                 then
                     echo "$(date +%Y%m%d-%H:%M) start memcached OK" >>$logs
                 else
                     "$(date +%Y%m%d-%H:%M) start memcached Fail" >>$logs
              fi
    fi
}

stop()
   {
      mpid=`ps aux|grep -v grep|grep memcached|grep 11200|awk '{print $2}'`
      if [ a"$mpid" == "a" ]
         then
              echo "Hotel memcached not run" ;
              exit 1;
      else
              kill -9 $mpid ;
              if [ $? -eq 0 ]
                 then
                     echo "$(date +%Y%m%d-%H:%M) stop memcached OK" >>$logs
                 else
                     echo "$(date +%Y%m%d-%H:%M) stop memcached fail">>$logs
              fi
       fi
   }


 case "$1" in
    start)
         start
         ;;
    stop)
         stop
         ;;
 restart)
        stop
        start
        ;; 

      *)
        echo "Usage : $0 {start|stop|restart}"
      ;;
 esac 
