#!/bin/bash

pipe=prova
ounter=0

trap "rm -f $pipe" EXIT

if [[ ! -p $pipe ]]; then
    mkfifo $pipe
fi

while true
do
    if read line <$pipe; then
        if [[ "$line" == 'quit' ]]; then
            break
        fi
         date=$(date +%s%N | cut -b1-13 | tr  '\n' ' ' | sed 's/ $/\n/')
         payload=$(/home/lucadag/node_modules/lora-packet/bin/lora-packet-decode --base64 $(echo "${line}" | jq -r '.phyPayload') | grep 'FCnt\|DevAddr')
         grepval1=$(echo "${payload}" | awk 'NR==2'| grep -o '[0-9]*')
         grepval2=$(echo "${payload}" | awk 'NR==4'| grep -o '[0-9]*') 
         res="${grepval1} ${grepval2} ${date}"
         echo "${res}" | tr  '\n' ' '| sed 's/ $/\n/'

    fi
done

echo "Reader exiting"
