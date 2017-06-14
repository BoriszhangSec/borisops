<?php
function http_post($data_arr, $host, $port, $url, &$output) {
	$postdata = '';
	foreach ( array_keys ( $data_arr ) as $key ) {
		$postdata = $postdata . rawurlencode ( $key ) . "=" . rawurlencode ( $data_arr [$key] ) . "&";
	}
	$postdata = substr ( $postdata, 0, strlen ( $postdata ) - 1 );
    var_dump($host . ":" . $port . "/" . $url);
    $ch = curl_init ( $host . ":" . $port . "/" . $url );
	var_dump($ch);
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


$news_id = $_POST['news_id'];
$xml_task=$_POST['dataContent'];	
$svr_ip="192.168.160.20";
$svr_port="8080";
    //http post xml to dest server
        $data["dataType"] = "xml";
        $data["dataContent"] = $_POST['dataContent'];
        
        $dest_server["server_ip"] = $svr_ip;
        $dest_server["server_port"] = 8080;
        $dest_server["server_interface"] = "upload_mf.php";
        
        $output="";
        if(http_post($data, $dest_server["server_ip"], $dest_server["server_port"], $dest_server["server_interface"],&$output)===TRUE)
        {
            echo "ddd";
            echo $output;
            return TRUE;
        }
        else
        {
            return $output;
        }
        

?> 
