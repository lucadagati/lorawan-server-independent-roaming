"""Server-independent LoRaWAN roaming bridge.

Sits next to the ChirpStack Gateway Bridge MQTT broker on the foreign
(visited) gateway. It subscribes to the raw gateway topics, looks up the
DevAddr of every uplink in a local TinyDB roaming table, and republishes the
packet on the home network's broker under one of its own registered
GatewayIDs. To the home Network Server, the packet looks like it arrived
through one of its own gateways (see docs/architecture.md for why this is
the load-bearing trick of the whole approach, and docs/as-built-vs-paper.md
for where this script diverges from Algorithm 1 in the paper).

Consolidated from three earlier iterations found in the original
GW_LoRa_Roaming repository (gwaddons.py, gwaddons-v5, gwaddons-v7):
- the recursive `rewrite_key` payload walk comes from the last iteration
  (gwaddons.py), which generalized the two hand-written nested-field cases
  ("gatewayID" and "rxInfo.gatewayID") from the v5 script.
- the per-device TinyDB lookup (NS IP + roaming GatewayID keyed by DevAddr)
  comes from v7; the last iteration had regressed to hardcoded globals.
"""

import base64
import json
import os
import threading

import paho.mqtt.client as mqtt
from termcolor import colored
from tinydb import Query, TinyDB

# Local (visited-network) broker the physical gateway publishes to.
LOCAL_BROKER = os.environ.get("ROAMING_LOCAL_BROKER", "127.0.0.1")

# TinyDB roaming table: one row per known DevAddr, e.g.
#   {"device_address": "26011bda", "ns_ip": "10.0.0.10", "roaming_gw_id": "de2b5906b8e2ca64"}
ROAMING_DB_PATH = os.environ.get("ROAMING_DB_PATH", "roamingdb.json")

TOPICS = (
    "gateway/+/event/up",
    "gateway/+/event/stats",
    "gateway/+/state/conn",
)


def decode_dev_addr(phy_payload_b64: str) -> str:
    """Extract the DevAddr (as 8 lowercase hex chars, big-endian) from a base64 PHYPayload.

    Frame layout: MHDR (1 byte) | DevAddr (4 bytes, little-endian on the air) | FCtrl ...
    The DevAddr is therefore bytes 1..4 of the frame, reversed byte-wise.
    (The historical scripts sliced 7 hex digits and reversed nibbles, which does
    not yield a valid DevAddr; see docs/as-built-vs-paper.md.)
    """
    phy_payload = base64.b64decode(phy_payload_b64.encode())
    return phy_payload[1:5][::-1].hex()


def rewrite_key(payload, key, value):
    """Recursively overwrite every occurrence of `key` inside a JSON-decoded
    payload, however deep it is nested (covers both the top-level
    "gatewayID" field on stats/conn messages and the nested
    "rxInfo[].gatewayID" field on uplink messages)."""
    if isinstance(payload, dict):
        for k, v in payload.items():
            if k == key:
                payload[k] = value
            else:
                rewrite_key(v, key, value)
    elif isinstance(payload, list):
        for item in payload:
            rewrite_key(item, key, value)


def lookup_roaming_target(dev_addr: str):
    """Return (home_ns_ip, home_gateway_id) for a DevAddr, or None if this
    device isn't a known roaming device (message is then dropped)."""
    db = TinyDB(ROAMING_DB_PATH)
    row = Query()
    matches = db.search(row.device_address == dev_addr)
    if not matches:
        return None
    return matches[0]["ns_ip"], matches[0]["roaming_gw_id"]


def on_message(client, userdata, msg):
    payload_raw = msg.payload.decode()
    topic_type = msg.topic.split("/")[-1]

    try:
        payload = json.loads(payload_raw)
    except json.JSONDecodeError:
        print(colored(f"Dropped non-JSON message on {msg.topic}", "yellow"))
        return

    if topic_type == "up":
        dev_addr = decode_dev_addr(payload["phyPayload"])
        target = lookup_roaming_target(dev_addr)
        if target is None:
            print(colored(f"DevAddr {dev_addr} is not a known roaming device, dropping", "yellow"))
            return
        ns_ip, home_gw_id = target
    elif topic_type in ("stats", "conn"):
        # Stats/keepalive messages aren't tied to a DevAddr; forward them
        # to every home NS we currently roam devices for. Left as a no-op
        # placeholder in this consolidated version -- see
        # docs/as-built-vs-paper.md, this fan-out was never implemented.
        return
    else:
        return

    rewrite_key(payload, "gatewayID", home_gw_id)
    new_topic = msg.topic.replace(msg.topic.split("/")[1], home_gw_id)

    publish_client = mqtt.Client()
    publish_client.connect(ns_ip)
    publish_client.publish(new_topic, json.dumps(payload))
    publish_client.disconnect()
    print(colored(f"Forwarded {msg.topic} -> {ns_ip}/{new_topic}", "green"))


def subscribe(topic: str):
    client = mqtt.Client()
    client.on_message = on_message
    client.connect(LOCAL_BROKER)
    client.subscribe(topic)
    client.loop_forever()


def main():
    threads = [threading.Thread(target=subscribe, args=(t,)) for t in TOPICS]
    for t in threads:
        t.start()
    for t in threads:
        t.join()


if __name__ == "__main__":
    main()
