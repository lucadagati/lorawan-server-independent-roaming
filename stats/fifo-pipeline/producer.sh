#!/bin/bash

pipe=prova
counter=0

if [[ ! -p $pipe ]]; then
    echo "Reader not running"
    exit 1
fi

while true  # Keep an infinite loop to reconnect when connection lost/broker unavailable
do
    mosquitto_sub -h 127.0.0.1 -t gateway/83a6659053f73652/event/up | while read -r payload
    do
       echo "${payload}" > $pipe 
       ((counter++))
       echo $counter
       sleep 0.01
    done
done # &  # Discomment the & to run in background (but you should rather run THIS script in background)
