#!/bin/bash
# Deletes the same sequential range of ABP test devices created by
# add_device_to_chirpstack.sh. Same credential handling: see that script.
set -euo pipefail

: "${CHIRPSTACK_AS_URL:?Set CHIRPSTACK_AS_URL, e.g. http://localhost:8080}"
: "${CHIRPSTACK_API_TOKEN:?Set CHIRPSTACK_API_TOKEN to a Grpc-Metadata-Authorization bearer token}"
DEVICE_COUNT="${1:-100}"

devEUI=1
counter=1
while [ "$counter" -le "$DEVICE_COUNT" ]; do
	devEUI2val=$(printf "%016d" "$devEUI")
	echo "Deleting device $counter/$DEVICE_COUNT (DevEUI $devEUI2val)"

	curl -sS -X DELETE \
		--header 'Accept: application/json' \
		--header "Grpc-Metadata-Authorization: Bearer ${CHIRPSTACK_API_TOKEN}" \
		"${CHIRPSTACK_AS_URL}/api/devices/${devEUI2val}"

	counter=$((counter + 1))
	devEUI=$((devEUI + 1))
done

echo "All done"
