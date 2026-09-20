#!/bin/bash

# This script subscribes to a MQTT topic using mosquitto_sub.
# On each message received, you can execute whatever you want.

while true  # Keep an infinite loop to reconnect when connection lost/broker unavailable
do
   mosquitto_sub -h 127.0.0.1 -t gateway/83a6659053f73652/event/up  | while read -r payload
   do
        # payload=$(echo "${payload}" | jq -r '.phyPayload')
	# echo "${payload}"
         payload=$(/home/lucadag/node_modules/lora-packet/bin/lora-packet-decode --base64 $(echo "${payload}" | jq -r '.phyPayload') | grep 'FCnt\|DevAddr')
#| grep -o '[0-9]*')
         grepval1=$(echo "${payload}" | awk 'NR==2'| grep -o '[0-9]*')
         grepval2=$(echo "${payload}" | awk 'NR==4'| grep -o '[0-9]*') 
         res="${grepval1} ${grepval2}"
         echo "${res}" | tr  '\n' ' '


#        echo "${payload}" | jq -r '.DevAddr, .FCnt' | tr '\n' ' ' | sed 's/ $/\n/'
        date +%s%N | cut -b1-13 | tr  '\n' ' ' | sed 's/ $/\n/'

   done
   echo "reconnect"
   sleep 5
done # &  # Discomment the & to run in background (but you should rather run THIS script in background)
