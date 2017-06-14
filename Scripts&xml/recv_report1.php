<?php
$raw_post = file_get_contents("php://input");
preg_match('/<guid>(.+)<\/guid>/', "$raw_post", $matches);
$guid = $matches[1];
$file = str_replace("/" , "-", $guid);
file_put_contents("/result/$file.result", $raw_post);
?>
