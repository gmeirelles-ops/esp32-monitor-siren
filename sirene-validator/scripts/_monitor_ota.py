#!/usr/bin/env python3
import json
import ssl
import sys
import time

import paho.mqtt.client as mqtt

site = sys.argv[1] if len(sys.argv) > 1 else "producao"
bancada = int(sys.argv[2]) if len(sys.argv) > 2 else 1
seconds = int(sys.argv[3]) if len(sys.argv) > 3 else 120

prefix = f"{site}/bancada-{bancada:02d}"


def on_message(client, userdata, msg):
    text = msg.payload.decode("utf-8", errors="replace")
    if msg.topic.endswith("/heartbeat"):
        try:
            data = json.loads(text)
            print(
                f"hb estado={data.get('estado')} "
                f"version={data.get('firmware_version')} uptime={data.get('uptime')}"
            )
        except json.JSONDecodeError:
            print("hb", text[:200])
    elif "ota" in text.lower():
        print(msg.topic, text[:400])


client = mqtt.Client(mqtt.CallbackAPIVersion.VERSION2, transport="websockets")
client.ws_set_options(path="/ws")
client.tls_set(cert_reqs=ssl.CERT_NONE)
client.username_pw_set("devices", "w1FefRLm+q1_O8H")
client.on_message = on_message
client.connect("mqtt.diponto.com", 443, 60)
client.subscribe(f"{prefix}/#", qos=1)
client.loop_start()
time.sleep(seconds)
client.loop_stop()
client.disconnect()
