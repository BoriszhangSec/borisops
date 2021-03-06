#!/bin/bash

GUIDFILE=$1
GUIDS=(`cat $GUIDFILE`)
GUIDNUM=${#GUIDS[@]}

for ((i=0;i<$GUIDNUM;i++))
do
	GUID=${GUIDS[i]}
	echo $GUID
#<?xml version="1.0" encoding="utf-8"?>
	xml="<root><reporter>http://127.0.0.1:8080/recv_report.php</reporter><upload><content><ctype>live</ctype><guid>$GUID</guid><title>$GUID</title><createdate>2012-09-27</createdate><publishdate>2012-09-27</publishdate><expireddate>2038-01-01</expireddate><files><file><format>flv</format><server>ts2flv-http</server><name>http://127.0.0.1/live/$GUID?fmt=x264_1400k_mpegts%26amp;size=720x576</name><codec>x264</codec><bitrate>1400</bitrate><streamsense>16</streamsense><resolution>6</resolution><timeshift>-2</timeshift></file><file><format>flv</format><server>ts2flv-http</server><name>http://127.0.0.1/live/$GUID?fmt=x264_700k_mpegts%26amp;size=720x576</name><codec>x264</codec><bitrate>700</bitrate><streamsense>8</streamsense><resolution>6</resolution><timeshift>-2</timeshift></file><file><format>flv</format><server>ts2flv-http</server><name>http://127.0.0.1/live/$GUID?fmt=x264_400k_mpegts%26amp;size=720x576</name><codec>x264</codec><bitrate>400</bitrate><streamsense>4</streamsense><resolution>6</resolution><timeshift>-2</timeshift></file><file><format>flv</format><server>ts2flv-http</server><name>http://127.0.0.1/live/$GUID?fmt=x264_200k_mpegts%26amp;size=720x576</name><codec>x264</codec><bitrate>200</bitrate><streamsense>2</streamsense><resolution>6</resolution><timeshift>-2</timeshift></file><file><format>flv</format><server>ts2flv-http</server><name>http://127.0.0.1/live/$GUID?fmt=x264_100k_mpegts%26amp;size=720x576</name><codec>x264</codec><bitrate>100</bitrate><streamsense>1</streamsense><resolution>6</resolution><timeshift>-2</timeshift></file></files></content></upload></root>"
	echo $xml 
	#curl -d "dataContent=$xml" -d "dataType=xml"  -d "mode=db" $post_address > /dev/null
	post_address="http://127.0.0.1:8080/upload_mf.php"
	curl  -d "dataContent=$xml" -d "dataType=xml"  -d "mode=db" $post_address  --http1.0
	sleep 2
done
