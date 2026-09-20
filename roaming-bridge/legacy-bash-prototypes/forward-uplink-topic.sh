#!/bin/bash

# This script subscribes to a MQTT topic using mosquitto_sub.
# On each message received, you can execute whatever you want.

while true  # Keep an infinite loop to reconnect when connection lost/broker unavailable
do
    mosquitto_sub -h 127.0.0.1 -t gateway/d48ba5322d97655e/event/up  | while read -r payload
    do
	echo "After sub"
        date +%s%N | cut -b1-13
        # Here is the callback to execute whenever you receive a message
        variable=$(echo "${payload}" | (jq '(.rxInfo.gatewayID) |= sub("1IulMi2XZV4="; "3itZBrjiymQ=")'))
        mosquitto_pub -h 192.168.0.99 -t gateway/de2b5906b8e2ca64/event/up -m "${variable}"
	echo "Publishing Time"
        date +%s%N | cut -b1-13

    done
    sleep 0.1  # Wait 10 seconds until reconnection
done # &  # Discomment the & to run in background (but you should rather run THIS script in background)
