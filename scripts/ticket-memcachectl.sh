#!/bin/bash
export PATH=$PATH:/bin:/usr/local/bin:/usr/bin
COMMAND=/usr/bin/memcached
MCuser=memcached
MEMCACHE_VAR=" -u $MCuser -m 4000 -c 3000   -p 11211 -d"

start()
   {
      ps aux|grep -v grep|grep memcached|grep 11211 >/dev/null 2>&1
      if [ $? -eq 0 ]
         then
              echo " Ticket memcached is runing";
              exit 1;
         else
              $COMMAND${MEMCACHE_VAR} >>/root/memcache_ticket.log
              if [ $? -eq 0 ]
                 then
                     echo "$(date +%Y%m%d-%H:%M) start memcached OK" >>/root/memcache_ticket.log;
                 else
                     "$(date +%Y%m%d-%H:%M) start memcached Fail" >>/root/memcache_ticket.log;
              fi
    fi
}

stop()
   {
      mpid=`ps aux|grep -v grep|grep memcached|grep 11211|awk '{print $2}'`
      if [ a"$mpid" == "a" ]
         then
              echo "Ticket memcached not run" ;
              exit 1;
      else
              kill -9 $mpid ;
              if [ $? -eq 0 ]
                 then
                     echo "$(date +%Y%m%d-%H:%M) stop memcached OK" >>/root/memcache_ticket.log;
                 else
                     echo "$(date +%Y%m%d-%H:%M) stop memcached fail">>/root/memcache_ticket.log;
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
