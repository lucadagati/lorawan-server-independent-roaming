# Import required libraries
import json
import subprocess
import paho.mqtt.client as mqtt
import threading
import base64
import struct
from termcolor import colored

# Set NS IP Address, gateway ID and topic name
NS_IP_ADDRESS = "X.X.X.X"
GWid = "xxxxxxxxxxxx"
GWid_TOPIC_NAME = "xxxxxxxxxxxxxxxx"

# Function to decode LoRa packet
def decode_lora_packet(phyPayload: str):
    # Decode and hexlify base64 encoded phyPayload
    phyPayload = base64.b64decode(phyPayload.encode()).hex()
    # Get devAddr from phyPayload
    devAddr = phyPayload[3:10]
    # Reverse devAddr
    devAddr = devAddr[::-1]
    return devAddr

def modify_dict(payload_dict, key, value):
    if isinstance(payload_dict, dict):
        for k in payload_dict:
            if k == key:
                payload_dict[k] = value
            else:
                modify_dict(payload_dict[k], key, value)
    elif isinstance(payload_dict, list):
        for item in payload_dict:
            modify_dict(item, key, value)

# Function to handle incoming MQTT messages
def on_message(client, userdata, msg):
    # Decode payload and print message details
    payload = msg.payload.decode()
    print(colored("Received message on topic: " + msg.topic + " with payload: " + payload, "red"))

    # Check if the payload is a JSON object
#    try:
#        payload_dict = json.loads(payload)
#        if "gatewayID" in payload_dict:
#            payload_dict["gatewayID"] = GWid
#            payload = json.dumps(payload_dict)
#    except json.JSONDecodeError:
#        pass

    try:
        payload_dict = json.loads(payload)
        modify_dict(payload_dict, "gatewayID", GWid)
        payload = json.dumps(payload_dict)
    except json.JSONDecodeError:
        pass

    # Get topic name and type
    topic_name = msg.topic.split("/")[1]
    topic_type = msg.topic.split("/")[-1]
    print(msg.topic)
    new_topic = msg.topic.replace(topic_name, GWid_TOPIC_NAME)


    # Handle different topic types
    if topic_type == "up":
        print("event UP")
        payload_dict = json.loads(payload)
        payload_phy = payload_dict["phyPayload"]
        decoded_packet = decode_lora_packet(payload_phy)
    elif topic_type == "stats":
        print("event STATS")
    elif topic_type == "conn":
        print("state CONN")

    # Publish message to NS and print details
    publish_client = mqtt.Client()
    publish_client.connect(NS_IP_ADDRESS)
    publish_client.publish(new_topic, payload) # msg.topic is the same, should be changed 
    print(colored("Forwarded message on topic: " + new_topic + " with payload: " + payload, "green"))
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
