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


$xml_str = '<?xml version="1.0" encoding="utf-8"?><root>
  <upload>
    <content>
      <ctype>live</ctype>
      <files>
        <file>
        	<streamsense>1</streamsense>
          <timeshift>-2</timeshift>
          <name><![CDATA[http://127.0.0.1/live/cctv8?fmt=x264_1400k_mpegts&size=720x576]]></name>
          <format>flv</format>
          <codec>h264</codec>
          <bitrate>1400</bitrate>
          <server>ts2flv-http</server>
          <resolution>6</resolution>
        </file>
         <file>
         	<streamsense>1</streamsense>
          <timeshift>-2</timeshift>
          <name><![CDATA[http://127.0.0.1/live/cctv8?fmt=x264_700k_mpegts&size=720x576]]></name>
          <format>flv</format>
          <codec>h264</codec>
          <bitrate>700</bitrate>
          <server>ts2flv-http</server>
          <resolution>6</resolution>
        </file>
         <file>
         	<streamsense>1</streamsense>
          <timeshift>-2</timeshift>
          <name><![CDATA[http://127.0.0.1/live/cctv8?fmt=x264_400k_mpegts&size=720x576]]></name>
          <format>flv</format>
          <codec>h264</codec>
          <bitrate>400</bitrate>
          <server>ts2flv-http</server>
          <resolution>6</resolution>
        </file>
        <file>
         	<streamsense>1</streamsense>
          <timeshift>-2</timeshift>
          <name><![CDATA[http://127.0.0.1/live/cctv8?fmt=x264_200k_mpegts&size=720x576]]></name>
          <format>flv</format>
          <codec>h264</codec>
          <bitrate>200</bitrate>
          <server>ts2flv-http</server>
          <resolution>6</resolution>
        </file>
        <file>
         	<streamsense>1</streamsense>
          <timeshift>-2</timeshift>
          <name><![CDATA[http://127.0.0.1/live/cctv8?fmt=x264_100k_mpegts&size=720x576]]></name>
          <format>flv</format>
          <codec>h264</codec>
          <bitrate>100</bitrate>
          <server>ts2flv-http</server>
          <resolution>6</resolution>
        </file>
      </files>
      <title>cctv8</title>
      <guid>cctv8</guid>
      <description></description>
    </content>
  </upload>
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
