#!/bin/bash

GUIDFILE=$1
GUIDS=(`cat $GUIDFILE`)
GUIDNUM=${#GUIDS[@]}

post_address="http://127.0.0.1:8080/upload_mf.php"
for ((i=0;i<$GUIDNUM;i++))
do
	GUID=${GUIDS[i]}
#	echo $GUID
	xml="<root><reporter>http://127.0.0.1:8080/recv_report.php</reporter><task_uuid>0</task_uuid><delete><content><guid>$GUID</guid><ctype>vod</ctype></content></delete></root>"
	curl -d "dataContent=$xml" -d "dataType=xml"  -d "mode=db" $post_address > /dev/null
	sleep 2
done
