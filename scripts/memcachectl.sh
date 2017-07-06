#!/bin/bash
export PATH=$PATH:/bin:/usr/local/bin:/usr/bin
COMMAND=/usr/bin/memcached
MCuser=memcached
MEMCACHE_VAR=" -u $MCuser -m 4000 -c 3000   -p 11211 -d"

start()
   {
      ps aux|grep -v grep|grep memcached >/dev/null 2>&1
      if [ $? -eq 0 ]
         then
              echo "memcached is runing";
              exit 1;
         else
              $COMMAND${MEMCACHE_VAR} >>/root/memcache.log
              if [ $? -eq 0 ]
                 then
                     echo "$(date +%Y%m%d-%H:%M) start memcached OK" >>/root/memcache.log;
                 else
                     "$(date +%Y%m%d-%H:%M) start memcached Fail" >>/root/memcache.log;
              fi
    fi
}

stop()
   {
      mpid=`ps aux|grep -v grep|grep memcached|awk '{print $2}'`
      if [ a"$mpid" == "a" ]
         then
              echo "memcached not run" ;
              exit 1;
      else
              kill -9 $mpid ;
              if [ $? -eq 0 ]
                 then
                     echo "$(date +%Y%m%d-%H:%M) stop memcached OK" >>/root/memcache.log;
                 else
                     echo "$(date +%Y%m%d-%H:%M) stop memcached fail">>/root/memcache.log;
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
