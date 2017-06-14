#!/bin/bash

GUIDFILE="/tmp/live.guid"
GUID=$1

getValue(){

URIS=(`grep "\<$1\>" $2 | grep "flv"`) 
URINUM=${#URIS[@]}
declare -i success=0
error="$1,"

for ((i=0;i<$URINUM;i++))
do
        BITRATE=`echo ${URIS[i]} | cut -d_ -f2`
#       echo ${URIS[i]}
#       echo ${URIS[$i]}
        result=`/usr/bin/curl -o /dev/null -Is -w %{http_code}"\n" "http://127.0.0.1/"${URIS[i]}`
        if [ $result -eq 200 ]
        then
                success=$((success+1))
        else
                error=${error}${BITRATE}","${result}";"
        fi
done

if [ $success -eq $URINUM ]
then
        echo "All Channels are OK"
else
        echo "$error"
fi

}

if [ ! -f $GUIDFILE ]
then    
        `/SO/bin/cns-walk -a | grep live |grep flv> $GUIDFILE`
	getValue $GUID $GUIDFILE
else
	URIS=(`grep "\<$1\>" $GUIDFILE | grep "flv"`)
	URINUM=${#URIS[@]}
#	echo $URINUM
        if [ $URINUM -eq 0 ]
        then 
		NEWURIS=(`/SO/bin/cns-walk -a | grep "\<$1\>" | grep flv`)
		NEWURINUM=${#NEWURIS[@]}
                if [ $NEWURINUM -ne 0 ]
                then 
                        `/SO/bin/cns-walk -a | grep "\<$1\>" | grep flv >> $GUIDFILE`
			getValue $GUID $GUIDFILE
		else 
			echo "ERROR GUID"

                fi
	else
		getValue $GUID $GUIDFILE
	fi
fi
