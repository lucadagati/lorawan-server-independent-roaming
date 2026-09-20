#!/bin/bash
# Bulk-provisions ABP test devices on a ChirpStack v3 Application Server via
# its REST API, with sequential DevEUI/DevAddr/keys derived from a counter.
#
# Originally hardcoded a live API key and instance URL; both are now read
# from the environment so the script can be committed without leaking
# credentials (see docs/as-built-vs-paper.md for context on why one had
# leaked into the source repo this was extracted from).
set -euo pipefail

: "${CHIRPSTACK_AS_URL:?Set CHIRPSTACK_AS_URL, e.g. http://localhost:8080}"
: "${CHIRPSTACK_API_TOKEN:?Set CHIRPSTACK_API_TOKEN to a Grpc-Metadata-Authorization bearer token}"
: "${CHIRPSTACK_APPLICATION_ID:=1}"
: "${CHIRPSTACK_DEVICE_PROFILE_ID:?Set CHIRPSTACK_DEVICE_PROFILE_ID}"
DEVICE_COUNT="${1:-100}"

devEUI=1
counter=1
while [ "$counter" -le "$DEVICE_COUNT" ]; do
	devEUI2val=$(printf "%016d" "$devEUI")
	nameval=$(printf "%03d" "$devEUI")
	keyval=$(printf "%032d" "$devEUI")
	devaddrval=$(printf "%08d" "$devEUI")
	echo "Provisioning device $counter/$DEVICE_COUNT (DevEUI $devEUI2val)"

	curl -sS -X POST \
		--header 'Content-Type: application/json' \
		--header 'Accept: application/json' \
		--header "Grpc-Metadata-Authorization: Bearer ${CHIRPSTACK_API_TOKEN}" \
		-d '{"device": {
			"applicationID": "'"$CHIRPSTACK_APPLICATION_ID"'",
			"description": "Applicazione di test",
			"devEUI": "'"$devEUI2val"'",
			"deviceProfileID": "'"$CHIRPSTACK_DEVICE_PROFILE_ID"'",
			"isDisabled": false,
			"name": "'"$nameval"'",
			"referenceAltitude": 0,
			"skipFCntCheck": true,
			"tags": {},
			"variables": {}
		}}' "${CHIRPSTACK_AS_URL}/api/devices"

	curl -sS -X POST \
		--header 'Content-Type: application/json' \
		--header 'Accept: application/json' \
		--header "Grpc-Metadata-Authorization: Bearer ${CHIRPSTACK_API_TOKEN}" \
		-d '{
			"deviceActivation": {
				"aFCntDown": 0,
				"appSKey": "'"$keyval"'",
				"devAddr": "'"$devaddrval"'",
				"devEUI": "'"$devEUI2val"'",
				"fCntUp": 1,
				"fNwkSIntKey": "'"$keyval"'",
				"nFCntDown": 0,
				"nwkSEncKey": "'"$keyval"'",
				"sNwkSIntKey": "'"$keyval"'"
			}
		}' "${CHIRPSTACK_AS_URL}/api/devices/${devEUI2val}/activate"

	counter=$((counter + 1))
	devEUI=$((devEUI + 1))
done

echo "All done"
