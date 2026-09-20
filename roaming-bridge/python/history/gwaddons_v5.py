# Import required libraries
import json
import subprocess
import paho.mqtt.client as mqtt
import threading
import base64
import struct
from termcolor import colored

# Set NS IP Address and gateway ID topic name
NS_IP_ADDRESS = "ip_address"
GWid_TOPIC_NAME = "weird_GW_ID"
GWid_TOPIC_NAME2 = "normal_GW_ID"

# Function to decode LoRa packet
def decode_lora_packet(phyPayload: str):
    # Decode and hexlify base64 encoded phyPayload
    phyPayload = base64.b64decode(phyPayload.encode()).hex()
    # Get devAddr from phyPayload
    devAddr = phyPayload[3:10]
    # Reverse devAddr
    devAddr = devAddr[::-1]
    return devAddr

# Function to handle incoming MQTT messages
def on_message(client, userdata, msg):
    # Decode payload and print message details
    payload = msg.payload.decode()
    print(colored("Received message on topic: " + msg.topic + " with payload: " + payload, "red"))

    # Check if the payload is a JSON object
    try:
        payload_dict = json.loads(payload)
        if "gatewayID" in payload_dict:
            payload_dict["gatewayID"] = GWid_TOPIC_NAME
            payload = json.dumps(payload_dict)
    except json.JSONDecodeError:
        pass

    # Get topic name and type
    topic_name = msg.topic.split("/")[1]
    topic_type = msg.topic.split("/")[-1]

    # Handle different topic types
    if topic_type == "up":
        print("event UP")
        payload_dict = json.loads(payload)
        if "rxInfo" in payload_dict:
            payload_dict2 = payload_dict["rxInfo"]
            if "gatewayID" in payload_dict2:
                payload_dict2["gatewayID"] = GWid_TOPIC_NAME
            payload_dict["rxInfo"] = payload_dict2
        payload = json.dumps(payload_dict)
        payload_phy = payload_dict["phyPayload"]
        decoded_packet = decode_lora_packet(payload_phy)
    elif topic_type == "stats":
        print("event STATS")
    elif topic_type == "conn":
        print("state CONN")

    # Publish message to NS and print details
    publish_client = mqtt.Client()
    publish_client.connect(NS_IP_ADDRESS)
    #publish_client.publish(msg.topic, payload)
    publish_client.publish("{}/{}/{}/{}".format("gateway", GWid_TOPIC_NAME2,"event", topic_type), payload)
    print(colored("Forwarded message on topic: " + "{}/{}/{}/{}".format("gateway", GWid_TOPIC_NAME2,"event", topic_type) + " with payload: " + payload, "green"))
    #print(colored("Forwarded message on topic: " + msg.topic + " with payload: " + payload, "green"))
    publish_client.disconnect()

# Function to subscribe to a given MQTT topic
def subscribe_to_topic(topic):
    # Initialize client and set on_message handler
    client = mqtt.Client()
    client.on_message = on_message
    client.connect("127.0.0.1")
    client.subscribe(topic)
    client.loop_forever()

# Create threads to subscribe to different topics
up_thread = threading.Thread(target=subscribe_to_topic, args=("gateway/+/event/up",))
stats_thread = threading.Thread(target=subscribe_to_topic, args=("gateway/+/event/stats",))
conn_thread = threading.Thread(target=subscribe_to_topic, args=("gateway/+/state/conn",))
app_up_thread = threading.Thread(target=subscribe_to_topic, args=("application/+/device/+/event/up",))

# Start threads
up_thread.start()
stats_thread.start()
conn_thread.start()
app_up_thread.start()

# Wait for threads to finish
up_thread.join()
stats_thread.join()
conn_thread.join()
app_up_thread.join()
