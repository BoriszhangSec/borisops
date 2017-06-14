<?php
function http_post($data_arr, $host, $port, $url, &$output) {
	$postdata = '';
	foreach ( array_keys ( $data_arr ) as $key ) {
		$postdata = $postdata . rawurlencode ( $key ) . "=" . rawurlencode ( $data_arr [$key] ) . "&";
	}
	$postdata = substr ( $postdata, 0, strlen ( $postdata ) - 1 );
    var_dump($host . ":" . $port . "/" . $url);
    $ch = curl_init ( $host . ":" . $port . "/" . $url );
	
	curl_setopt ( $ch, CURLOPT_POST, 1 );
	curl_setopt ( $ch, CURLOPT_POSTFIELDS, $postdata );
	curl_setopt ( $ch, CURLOPT_RETURNTRANSFER, 1 );
	curl_setopt ( $ch, CURLOPT_HTTPHEADER, array ('Expect:' ) );
	curl_setopt ( $ch, CURLOPT_TIMEOUT, 30 );
	$data = curl_exec ( $ch );
	curl_close ( $ch );
	if ($data) {
		$output = $data;
        var_dump($output);
		return TRUE;
	} else {
		return FALSE;
	}
}


$xml_str = '<?xml version="1.0" encoding="utf-8"?>
<root>
	<serverid>1</serverid>
	<reporter>
		<![CDATA[http://127.0.0.1:8080/cms/index.php/Admin/Interface/index_by_path]]>
	</reporter>
	<upload protocol="full">
		<content>
			<ctype>live</ctype>
			<guid>
				<![CDATA[cctv6]]>
			</guid>
			<description/>
			<title>
				<![CDATA[cctv6]]>
			</title>
			<priority>5</priority>
			<time/>
			<createdate>2012-09-27</createdate>
			<publishdate>2012-09-27</publishdate>
			<expireddate>2038-01-01</expireddate>
			<last_modify/>
			<files>
				<file>
                                        <video/>
                                        <audio/>
                                        <standard/>
                                        <format>ts</format>
                                        <server>TSS</server>
                                        <name>
                                                <![CDATA[http://192.168.160.20/live/jstv11?fmt=x264_1400k_mpegts&size=720x576]]>
                                        </name>
                                        <codec>x264</codec>
                                        <bitrate>1400</bitrate>
                                        <streamsense>16</streamsense>
                                        <framerate>0</framerate>
                                        <multicast/>
                                        <unplayable>0</unplayable>
                                        <resolution>6</resolution>
                                        <time/>
                                        <protocol/>
                                        <corrid>140</corrid>
                                        <timeshift>-2</timeshift>
                                        <download/>
                                        <status>valid</status>
                                        <protect/>
                                        <splitstream>0</splitstream>
                                </file>
				<file>
                                        <video/>
                                        <audio/>
                                        <standard/>
                                        <format>ts</format>
                                        <server>TSS</server>
                                        <name>
                                                <![CDATA[http://192.168.160.20/live/jstv11?fmt=x264_700k_mpegts&size=720x576]]>
                                        </name>
                                        <codec>x264</codec>
                                        <bitrate>700</bitrate>
                                        <streamsense>8</streamsense>
                                        <framerate>0</framerate>
                                        <multicast/>
                                        <unplayable>0</unplayable>
                                        <resolution>6</resolution>
                                        <time/>
                                        <protocol/>
                                        <corrid>140</corrid>
                                        <timeshift>-2</timeshift>
                                        <download/>
                                        <status>valid</status>
                                        <protect/>
                                        <splitstream>0</splitstream>
                                </file>
				<file>
					<video/>
					<audio/>
					<standard/>
					<format>ts</format>
					<server>TSS</server>
					<name>
						<![CDATA[http://192.168.160.20/live/jstv11?fmt=x264_400k_mpegts&size=720x576]]>
					</name>
					<codec>x264</codec>
					<bitrate>400</bitrate>
					<streamsense>4</streamsense>
					<framerate>0</framerate>
					<multicast/>
					<unplayable>0</unplayable>
					<resolution>6</resolution>
					<time/>
					<protocol/>
					<corrid>138</corrid>
					<timeshift>-2</timeshift>
					<download/>
					<status>valid</status>
					<protect/>
					<splitstream>0</splitstream>
				</file>
				<file>
					<video/>
					<audio/>
					<standard/>
					<format>ts</format>
					<server>TSS</server>
					<name>
						<![CDATA[http://192.168.160.20/live/jstv11?fmt=x264_200k_mpegts&size=720x576]]>
					</name>
					<codec>x264</codec>
					<bitrate>200</bitrate>
					<streamsense>2</streamsense>
					<framerate>0</framerate>
					<multicast/>
					<unplayable>0</unplayable>
					<resolution>6</resolution>
					<time/>
					<protocol/>
					<corrid>139</corrid>
					<timeshift>-2</timeshift>
					<download/>
					<status>valid</status>
					<protect/>
					<splitstream>0</splitstream>
				</file>
				<file>
					<video/>
					<audio/>
					<standard/>
					<format>ts</format>
					<server>TSS</server>
					<name>
						<![CDATA[http://192.168.160.20/live/jstv11?fmt=x264_100k_mpegts&size=720x576]]>
					</name>
					<codec>x264</codec>
					<bitrate>100</bitrate>
					<streamsense>1</streamsense>
					<framerate>0</framerate>
					<multicast/>
					<unplayable>0</unplayable>
					<resolution>6</resolution>
					<time/>
					<protocol/>
					<corrid>140</corrid>
					<timeshift>-2</timeshift>
					<download/>
					<status>valid</status>
					<protect/>
					<splitstream>0</splitstream>
				</file>
			</files>
		</content>
	</upload>
	<task_uuid>65</task_uuid>
</root>';



    //http post xml to dest server
        $data["dataType"] = "xml";
        $data["dataContent"] = $xml_str;
        
        $dest_server["server_ip"] = "127.0.0.1";
        $dest_server["server_port"] = 8080;
        $dest_server["server_interface"] = "upload_mf.php";
        
        $output="";
        if(http_post($data, $dest_server["server_ip"], $dest_server["server_port"], $dest_server["server_interface"],&$output)===TRUE)
        {
            echo $output;
            return TRUE;
        }
        else
        {
            return $output;
        }
        

?> 
