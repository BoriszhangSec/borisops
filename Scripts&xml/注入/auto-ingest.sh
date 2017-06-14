#!/bin/bash
# MANAGED BY PUPPET
#===============================================================================
#
#          FILE:  auto-ingest.sh
#         USAGE:  ./auto-ingest.sh 1GUID_FILE 2HOSTNAME 3SS_PORT 4BITRATE 5SOURCE_IP 6STREAMSENSE
# 
#   DESCRIPTION:  For Live.
# 
#        AUTHOR: Sun Qi, sunqi@streamocean.com
#       COMPANY: StreamOcean, Inc.
#       CREATED: 01/22/2014 18:34:50 PM CST
#      REVISION: V0.1
#
#===============================================================================

usage(){
    echo "    Usage: `basename $0` GUID_FILE HOSTNAME SS_PORT BITRATE SOURCE_IP STREAMSENSE"
    exit
}

if [ $# -ne 6 ] ;then
    usage
fi

GUID_FILE=$1
GUID_LIST=(`cat $GUID_FILE | grep -v "#"`)
GUID_NUM=${#GUID_LIST[@]}


for ((i=0;i<$GUID_NUM;i++))
do

GUID=${GUID_LIST[i]}

XML_FILES="
<?xml version=\"1.0\" encoding=\"utf-8\"?>
<root>
    <serverid></serverid>
    <upload protocol=\"full\">
        <content>
            <ctype>live</ctype>
            <guid><![CDATA[$GUID]]></guid>
            <description/>
            <title><![CDATA[$GUID]]></title>
            <priority>5</priority>
            <time/>
            <createdate>2013-09-27</createdate>
            <publishdate>2012-09-27</publishdate>
            <expireddate>2038-01-01</expireddate>
            <last_modify/>
            <files>
                <file>
                    <format>ts</format>
                    <server>tss</server>
                    <name><![CDATA[http://$5:$3/live/$GUID?fmt=x264_$4k_mpegts]]></name>
                    <codec>x264</codec>
                    <bitrate>$4</bitrate>
                    <streamsense>$6</streamsense>
                    <splitstream>0</splitstream>
                    <multicast/>
                    <unplayable>0</unplayable>
                    <framerate>25</framerate>
                    <time/>
                    <protocol/>
                    <corrid></corrid>
                    <timeshift>86400</timeshift>
                    <download>1</download>
                    <status>valid</status>
                    <protect>0</protect>
                </file>
           </files>
        </content>
    </upload>
    <task_uuid></task_uuid>
</root>
"

echo $XML_FILES>./xml/aaaaa$GUID
POST_ADDRESS="http://$2:8080/upload_mf.php"
echo $i,$GUID
curl -d "dataContent=$XML_FILES" -d "dataType=xml" $POST_ADDRESS --http1.0
CURL_RESULT=$?
echo $CURL_RESULT
if [ $CURL_RESULT -ne 0 ] ;then
    i=$[$i-1]
fi



sleep 1
done
