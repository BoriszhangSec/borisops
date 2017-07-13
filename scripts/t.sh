#!/bin/bash
c=5001
while [ $c -le 10000 ]
 do
  mosquitto_sub -d -h 223.202.102.78  -p 4883 -k 900 -u wjy_mqtt  -P zk21fElgSJ  -t $c &
 (( c++ ))
 done
