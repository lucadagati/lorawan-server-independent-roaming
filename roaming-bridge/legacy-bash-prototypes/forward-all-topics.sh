#!/bin/bash


function mqtt_up () {
    mosquitto_sub -h 127.0.0.1 -t gateway/+/event/up  | while read -r payload_up
    do
	echo "Sub Time Up Topic"
	date +%s%N | cut -b1-13
	echo "${payload_up}"
	payload_up_grep=`echo "${payload_up}" | jq -r '.phyPayload'`
	echo "${payload_up}" 
	devAddr=`~/node_modules/lora-packet/bin/lora-packet-decode --base64 $payload_up_grep | grep 'DevAddr = ' |grep -o '[0-9]*'`	
	echo "${devAddr}"
	mosquitto_pub -h 127.0.0.1 -t gateway/de2b5906b8e2ca64/event/up  -m "${payload_up}"
        echo "Pub Time Stat Topic"
	date +%s%N | cut -b1-13
    done
}

function mqtt_stats () {
    mosquitto_sub -h 127.0.0.1 -t gateway/+/event/stats  | while read -r payload_stats
    do
	echo "Sub Time Stat Topic"
	date +%s%N | cut -b1-13	
	echo "${payload_stats}"
        stats_message=$(echo "${payload_stats}" | (jq '(.gatewayID) |= sub("g6ZlkFP3NlI="; "3itZBrjiymQ=")')) 
        echo "publishing ${stats_message}"
	mosquitto_pub -h 127.0.0.1 -t gateway/de2b5906b8e2ca64/event/stats  -m "${stats_message}"
        echo "Pub Time Stat Topic"
	date +%s%N | cut -b1-13
    done
}

function mqtt_conn () {
    mosquitto_sub -h 127.0.0.1 -t gateway/+/state/conn   | while read -r payload_conn
    do
	echo "Sub State Conn Topic"
	echo "${payload_conn}"
	date +%s%N | cut -b1-13
	conn_message=$(echo "${payload_conn}" | (jq '(.gatewayID) |= sub("g6ZlkFP3NlI="; "3itZBrjiymQ=")')) 
	echo "${conn_message}"
	mosquitto_pub -h 127.0.0.1 -t gateway/de2b5906b8e2ca64/state/conn  -m "${conn_message}"
        echo "Pub State Conn Topic"
	date +%s%N | cut -b1-13
    done
}

while true  # Keep an infinite loop to reconnect when connection lost/broker unavailable
do
mqtt_up  & mqtt_stats & mqtt_conn
done 
