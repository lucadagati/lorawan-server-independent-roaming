#!/bin/bash

counter=1
devEUI=0

# Inizializza l'output JSON
echo "{" > tempNodes.json

while [ $counter -le 5 ]
do
	devEUI2val=$(printf "%016d" $devEUI)
	nameval=$(printf "%03d" $devEUI)
	keyval=$(printf "%032d" $devEUI)
	devaddrval=$(printf "%08d" $devEUI)

	json='
		"'$counter'": {
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

	# Aggiungi il JSON generato al file temporaneo
	echo "$json" >> tempNodes.json

	((counter++))
	((devEUI++))
done

# Rimuovi la virgola finale
sed -i '$s/,$//' tempNodes.json

# Chiudi l'oggetto JSON
echo "}" >> tempNodes.json

# Unisci il nuovo JSON con il vecchio se necessario
# jq -s add tempNodes.json static-nodes.json

