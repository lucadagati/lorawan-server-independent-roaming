# roaming-bridge

`python/gwaddons.py` is the core of the roaming mechanism (see
[`../docs/architecture.md`](../docs/architecture.md)). It needs a
`roamingdb.json` next to it — copy `python/roamingdb.example.json` and fill
in real DevAddr → (home NS IP, home GatewayID) rows.

`legacy-bash-prototypes/` are the earlier, single-purpose mosquitto_sub/jq
proof of concepts that predated the Python script (hardcoded gateway IDs
and NS IPs, one script per MQTT topic). Kept for reference; not maintained.

There is no Golang version in this repository — see
[`../docs/as-built-vs-paper.md`](../docs/as-built-vs-paper.md) point 3.
