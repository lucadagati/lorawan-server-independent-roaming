#!/bin/bash
devEUI=1
counter=1
value=$1
while [ $counter -le $value ]
do
	devEUI2val=$(printf "%016d" $devEUI)
	nameval=$(printf "%03d" $devEUI)
	keyval=$(printf "%032d" $devEUI)
	devaddrval=$(printf "%08d" $devEUI)

if [ $counter -le $value ]
then 
random=$(shuf -i 60-180 -n 1)
json='
		"'"$counter"'": {
		"id": '$counter',
		"info": {
			"devEUI": "'"$devEUI2val"'",
			"devAddr": "'"$devaddrval"'",
			"nwkSKey": "'"$keyval"'",
			"appSKey": "'"$keyval"'",
			"appKey": "'"$keyval"'",
			"name": "'"$nameval"'",
			"status": {
				"mtype": "UnConfirmedDataUp",
				"payload": "hello",
				"active": true,
				"infoUplink": {
					"fport": 1,
					"fcnt": 0
				},
				"fcntDown": 0
			},
			"configuration": {
				"region": 1,
				"sendInterval": '$random',
				"ackTimeout": 2,
				"range": 10000,
				"disableFCntDown": true,
				"supportedOtaa": false,
				"supportedADR": true,
				"supportedFragment": true,
				"supportedClassB": false,
				"supportedClassC": false,
				"dataRate": 0,
				"rx1DROffset": 0,
				"nbRetransmission": 0
			},
			"location": {
				"latitude": 38.25952065453902,
				"longitude": 15.595605039949351,
				"altitude": 0
			},
			"rxs": [
				{
					"delay": 1,
					"durationOpen": 3,
					"channel": {
						"active": false,
						"enableUplink": false,
						"freqUplink": 0,
						"freqDownlink": 0,
						"minDR": 0,
						"maxDR": 0
					},
					"dataRate": 0
				},
				{
					"delay": 1,
					"durationOpen": 3,
					"channel": {
						"active": true,
						"enableUplink": false,
						"freqUplink": 0,
						"freqDownlink": 869525000,
						"minDR": 0,
						"maxDR": 0
					},
					"dataRate": 0
				}
			]
		}
	},'
else
json='
		"'"$counter"'": {
		"id": '$counter',
		"info": {
			"devEUI": "'"$devEUI2val"'",
			"devAddr": "'"$devaddrval"'",
			"nwkSKey": "'"$keyval"'",
			"appSKey": "'"$keyval"'",
			"appKey": "'"$keyval"'",
			"name": "'"$nameval"'",
			"status": {
				"mtype": "UnConfirmedDataUp",
				"payload": "hello",
				"active": false,
				"infoUplink": {
					"fport": 1,
					"fcnt": 0
				},
				"fcntDown": 0
			},
			"configuration": {
				"region": 1,
				"sendInterval": 10,
				"ackTimeout": 2,
				"range": 10000,
				"disableFCntDown": true,
				"supportedOtaa": false,
				"supportedADR": true,
				"supportedFragment": true,
				"supportedClassB": false,
				"supportedClassC": false,
				"dataRate": 0,
				"rx1DROffset": 0,
				"nbRetransmission": 0
			},
			"location": {
				"latitude": 38.25952065453902,
				"longitude": 15.595605039949351,
				"altitude": 0
			},
			"rxs": [
				{
					"delay": 1,
					"durationOpen": 3,
					"channel": {
						"active": false,
						"enableUplink": false,
						"freqUplink": 0,
						"freqDownlink": 0,
						"minDR": 0,
						"maxDR": 0
					},
					"dataRate": 0
				},
				{
					"delay": 1,
					"durationOpen": 3,
					"channel": {
						"active": true,
						"enableUplink": false,
						"freqUplink": 0,
						"freqDownlink": 869525000,
						"minDR": 0,
						"maxDR": 0
					},
					"dataRate": 0
				}
			]
		}
	},'
fi
	echo "$json" >> $value.json
	((counter++))
	((devEUI++))
	((name++))
#	jq -s add tempNodes.json static-nodes.json
done


