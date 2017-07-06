#!/bin/bash
if [ "$LOGNAME" == 'root' ];then
   echo "please use non-root user execute"
   exit 1
fi
options="update|rollback"
if [ $# -ne 1 ];then
   echo "Usage: $0 $options"
   exit 1
fi
lock="$HOME/deploy.lock"
if [ -f $lock ];then
    echo "$0 is running"
    exit 1
else
    touch $lock
fi


option=$1
case $option in
   update)
          OFlag="current"
          ;;
   rollback)
          OFlag="rollback"
          ;;
        *)
          echo "error option"
          echo "Usage: $0 $options"
          rm $lock
          exit 1
          ;; 
esac


SNpath="/"
SNfile=`ls $SNpath |grep -E "SN[0-9]{10}"`
if [ $? -ne 0 ];then
    echo "${SNpath}SNfile is not exist"
    exit 1
#elif [ `cat $SNpath$SNfile|wc -l` -ne 10 ];then
#    echo "$SNpath$SNfile format is error "
#    exit 1
fi
check_file()
 {
   if [ $# -ne 3 ];then
       echo " $1 is not exist"
       exit 1
   fi
   file=$2
   stat=$3
   if [ "$file" == "/" -o "$file" == "rm" -o "$file" == "mv" ];then
       echo "$file can't be /"
       exit 1
   fi
   case $stat in
     f|d)
           if [ ! -$stat $file ];then
              echo "$file does not exis,please check"
              exit 1
           fi 
           ;;
       x)
          if [ ! -$stat $file ];then
              echo "$file does not exist or Permission denied"
              exit 1
          fi
              ;;
         *)
           echo "arguments is error"
           exit 1
           ;;
   esac
   
 }

check_val()
 { 
   if [ $# -ne 2 ];then
       echo "$1 is null"
       exit 1
   fi
 }

check_http_stats()
 {
  sfile=$1
  surl=$2
  httpcode=`curl --connect-timeout 3 -w %{http_code} --silent -o $sfile $surl`
  if [ "$httpcode" != "200" ];then
       echo "get remote server $surl error,please check"
       exit 1
  fi
   
 }

get_SNfile_data()
   {
    temp_data="/tmp/deploy_data"
    if [ ! -d $temp_data ];then
        mkdir -p $temp_data
    fi
    
    AppName=`awk -F= '/^Apps/ {print $2}' $SNpath$SNfile`
    Source=`awk -F= '/^Source/ {print $2 }' $SNpath$SNfile`
    WarName=`awk -F= '/^WarName/ {print $2}' $SNpath$SNfile`
    WebRoot=`awk -F= '/^WebRoot/ {print $2}' $SNpath$SNfile`
    WSPath=`awk -F= '/^WSPath/ {print $2}' $SNpath$SNfile`
    LocalIP=`awk -F= '/^LocalIP/ {print $2}' $SNpath$SNfile`
    App_Port=`awk -F= '/^App_Port/ {print $2}' $SNpath$SNfile`
    SFile=`awk -F= '/^SFile/ {print $2}' $SNpath$SNfile`
    LVS_Flag=`awk -F= '/^LVS_Flag/ {print $2}' $SNpath$SNfile`
    LVS_SF=`awk -F= '/^LVS_SF/ {print $2}' $SNpath$SNfile`
    Surl="${Source}${AppName}/${OFlag}/${SFile}"
    case $AppName in
          customer|pay|redeemcode|iticket|newticket|oldhotel|hangupSms|hotel_ebooking)
                  WebServer="Tomcat"
                  package="war"
                  WStart="$WSPath/bin/startup.sh"
                  Url="http://$LocalIP:$App_Port/${WarName%%.*}/" 
                  check_val AppName $AppName
                  check_val WSPath $WSPath
                  check_val LocalIP $LocalIP
                  check_val App_Port $App_Port
                  check_val WarName ${WarName}
                  check_file WebRoot $WebRoot d
                  check_file WStart $WStart x
                  if [ "a$LVS_Flag" == "aON" ];then
                      check_file LVS_SF $WebRoot/$LVS_SF f
                  fi
                  check_http_stats $temp_data/${WarName} $Surl
                  echo "$package $temp_data $WebRoot $WSPath $WStart   $WarName $Url LVS:$LVS_SF $LVS_Flag"
                 ;;
           hotel_fax|hotel_reserve|hotel_api|sms_api|sms_cron|hotel_cron|hotel_ebooking|hotel_joincenter|hotel_joinquartzc|hotel_joinquartz|NewITicket|ITicket|NewTicket|NewPortal|NewBalance|NewFlightPolicy|pay_gateway|ticket_PTB|openapi|wallet_service|WalletManageSite|sso|erm|GuestHistory|js_daemon|js_querycenter|js_job|jichu|HotelPFquartz|HotelPF|ProviderPF|NewFinancial|js_ec)    
                  WebServer="Tomcat"
                  package="tgz"
                  WStart="$WSPath/bin/startup.sh"
                  Url="http://$LocalIP:$App_Port/TAG"
                  Ver=`awk -F= '/^Version/ {print $2}' $SNpath$SNfile`
                  Vurl=${Source}${AppName}/${OFlag}/$Ver
                  Webdata=`awk -F= '/^Webdata/ {print $2}' $SNpath$SNfile`
                  check_val AppName $AppName
                  check_val WSPath $WSPath
                  check_val LocalIP $LocalIP
                  check_val App_Port $App_Port
                  check_val Version $Ver
                  check_val WebRoot $WebRoot 
                  check_file Webdata $Webdata d
                  check_file WStart $WStart x
                  if [ "a$LVS_Flag" == "aON" ];then
                      check_file LVS_SF $WebRoot/$LVS_SF f
                  fi
                  check_http_stats $temp_data/$Ver $Vurl 
                  check_http_stats $temp_data/${AppName}.tgz $Surl
                  echo "$package $temp_data $WebRoot $WSPath $WStart $Url LVS:$LVS_SF $Ver ${AppName}.tgz $Webdata $LVS_Flag" 
                 ;;
           
              *)
                  echo "error AppName,Please check $SNpath$SNfile"
                  exit 1
                  ;;
   esac
   }

check_url()
{
 url=$1
 hcode=`curl -w %{http_code} --silent -o /dev/null $url`
 hpr_code="200|301|302"
 echo $hpr_code|grep -w $hcode  >/dev/null 2>&1
 if [ $? -eq 0 ];then
    echo "ok"
 else
    echo "fail"
 fi
  
}

kill_app()
 {
   basename=$1
   sudo=$2
   tpid=`ps auxww|grep java|grep -v grep|grep $basename|awk '{print $2}'`
   if [ "a$tpid" != "a" ];then
       if [ "a$sudo" == "asudo" ];then
           sudo kill -9 $tpid
       else
           kill -9 $tpid
       fi
   fi  
 }

check_lvs_stats()
 {
  status=$1
  lvs_tmp_file=$2
  lvs_sfile=$3
  web_server=$4
  lvs_flag=$5
  if [ "a$status" == "aok" ];then
      echo "start $web_server is ok"
      if [ "a$lvs_flag" == "aON" ];then
          mv $lvs_tmp_file  $lvs_sfile
          if [ $? -eq 0 ];then
              echo "LVS status check ok"
          else
              echo "LVS status check fail,please check $lvs_sfile"
          fi
      fi
  else
      if [ "a$lvs_flag" == "aON" ];then
          mv $lvs_tmp_file  $lvs_sfile
      fi
      echo "start $web_server is fail,please check catalina.out"
  fi
  
 }


deploy_app()
 {
   case $1 in
      war)
          tmp_dir=$2
          webroot=$3
          wspath=$4
          wstart=$5
          webserver="Tomcat"
          warname=$6
          url=$7
          lvs_sf=$8
          lvs_flag=$9
          #if [ "a$lvs_flag" == "aON" ];then
          #    lvs_sf=${lvs_sf##*:}
          #    echo "LVS status check lost..."
          #    mv $webroot/$lvs_sf $tmp_dir/status.file
          #fi
             
         if [ "a$lvs_sf" != "aLVS:" ] && [ "a$lvs_flag" == "aON" ];then
            lvs_sf=${lvs_sf##*:}
            lvs_flag=ON
            echo "LVS status check lost..."
            mv $webroot/$lvs_sf $tmp_dir/status.file
         else
              lvs_flag=OFF
         fi 
              
          sleep 3
          echo "shutdown $webserver ..."
          #$wstop >/dev/null
          kill_app $wspath
          echo "shutdown $webserver is ok "
          rm -rf $webroot/${warname%%.*}
          rm -f $webroot/${warname}
          rm -rf $wspath/work/*
          /bin/cp $tmp_dir/${warname}  $webroot/
          echo "start $webserver ..."
          $wstart >/dev/null
          chmod 750 $webroot/${WarName%%.*}WEB-INF/classes/dbconfig.properties >/dev/null 2>&1
          chmod 750 $webroot/WEB-INF/classes/db.properties >/dev/null 2>&1
          sleep 40
          status=`check_url $url`
          check_lvs_stats $status $tmp_dir/status.file $webroot/$lvs_sf $webserver $lvs_flag
          ;;
       tgz)
           tmp_dir=$2
           webroot=$3
           wspath=$4
           wstart=$5
           webserver="Tomcat"
           url=$6
           lvs_sf=$7
           ver=$8
           gzfile=$9
           webdata=${10}
           lvs_flag=${11}
           cd $tmp_dir
           tdir=`date +%Y%m%d%H%M%S`
           tar zxf $gzfile
           if [ "a$lvs_sf" != "aLVS:" ] && [ "a$lvs_flag" == "aON" ];then
              lvs_sf=${lvs_sf##*:}
              lvs_flag=ON
              echo "LVS status check lost..."
              mv $webroot/$lvs_sf $tmp_dir/status.file
           else
              lvs_flag=OFF
           fi
           sleep 3
           echo "shutdown $webserver ..."
           kill_app $wspath sudo
           echo "shutdown $webserver is ok "
           sudo rm -rf $wspath/work/*
           sudo rm -rf $webroot/*
           #sudo rm -f $webroot
           re_dir=releases
           vdir=`cat $ver`
           if [ ! -d $webdata/$re_dir ];then
               sudo mkdir $webdata/$re_dir
               sudo chown -R yz:www $webdata/$re_dir
           fi
           sudo mv $vdir $webdata/$re_dir/$tdir
           sudo mv $ver $webdata/$re_dir/$tdir
           sudo chown -R yz:www $webdata/$re_dir
           sudo ln -s $webdata/current $webroot
           sudo rm -f $webdata/current 
           sudo ln -s $webdata/$re_dir/$tdir $webdata/current
           sudo -u www $wstart >/dev/null
           chmod 750 $webroot/WEB-INF/classes/db.properties >/dev/null 2>&1
           sleep 40
           status=`check_url $url`
           check_lvs_stats $status $tmp_dir/status.file $webroot/$lvs_sf $webserver $lvs_flag
           ;;
       *)
          echo "$*"
          rm $lock
          exit 1;
   esac
  
 }


dep_info=`get_SNfile_data`
deploy_app $dep_info
rm $lock
