#!/bin/bash

# This script subscribes to a MQTT topic using mosquitto_sub.
# On each message received, you can execute whatever you want.

while true  # Keep an infinite loop to reconnect when connection lost/broker unavailable
do
   mosquitto_sub -h 127.0.0.1 -t application/1/device/+/event/up  | while read -r payload
   do
#	echo "${payload}"
#        date +%s%N | cut -b1-13 | tr  '\n' ' '
        echo "${payload}" | jq -r '.devEUI, .fCnt' | tr '\n' ' ' #| sed 's/ $/\n/'
        date +%s%N | cut -b1-13 | tr  '\n' ' ' | sed 's/ $/\n/'

#        echo "${payload}" | jq -r '.fCnt'
#        ~/node_modules/lora-packet/bin/lora-packet-decode --base64 $(echo "${payload}" | jq -r '.phyPayload')  |grep 'DevAddr = \|FCnt = '
#        ~/node_modules/lora-packet/bin/lora-packet-decode --base64 $(echo "${payload}" | jq -r '.phyPayload') |grep 'DevAddr = \|FCnt = ' | grep -o '[0-9]*' | tr '\n' ' ' | sed 's/ $/\n/'
#grep -o '[0-9]*' | tr '\n' ' ' | sed 's/ $/\n/'

        #~/node_modules/lora-packet/bin/lora-packet-decode --base64 $(echo "${payload}" | jq -r '.phyPayload') | grep 'DevAddr = \|FCnt = '

	#echo "${payload}" | jq -r '.phyPayload'
        #date +%s%N | cut -b1-13
   done
   echo "reconnect"
   sleep 5
done # &  # Discomment the & to run in background (but you should rather run THIS script in background)
