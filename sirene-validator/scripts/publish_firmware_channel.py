#!/usr/bin/env python3
"""Publica o canal retained de firmware auto-OTA.

Tópico: {site}/firmware/atual
Payload: {"version":"1.8.19","url":"http://192.168.51.10:8080/sirene-validator.bin"}

As bancadas com firmware >= 1.8.19, ao ligar/conectar no MQTT, comparam a versão
local com este canal e disparam OTA se diferente (URL precisa ser alcançável na LAN).

Uso:
  python3 scripts/publish_firmware_channel.py \\
    --version 1.8.19 \\
    --url http://192.168.51.10:8080/sirene-validator.bin
"""
from __future__ import annotations

import argparse
import json
import ssl
import sys

try:
    import paho.mqtt.client as mqtt
except ImportError:
    print("Instale: pip install paho-mqtt", file=sys.stderr)
    sys.exit(1)


def main() -> None:
    p = argparse.ArgumentParser(description="Publica canal retained {site}/firmware/atual")
    p.add_argument("--site", default="producao")
    p.add_argument("--host", default="mqtt.diponto.com")
    p.add_argument("--port", type=int, default=443)
    p.add_argument("--user", default="devices")
    p.add_argument("--password", default="w1FefRLm+q1_O8H")
    p.add_argument("--ws-path", default="/ws")
    p.add_argument("--version", required=True, help="Versão publicada (ex.: 1.8.19)")
    p.add_argument("--url", required=True, help="URL HTTP LAN do sirene-validator.bin")
    p.add_argument(
        "--clear",
        action="store_true",
        help="Apaga a mensagem retained (payload vazio)",
    )
    args = p.parse_args()

    topic = f"{args.site}/firmware/atual"
    if args.clear:
        payload = ""
    else:
        version = args.version.strip()
        url = args.url.strip()
        if not version or not url:
            raise SystemExit("--version e --url são obrigatórios")
        if not url.startswith(("http://", "https://")):
            raise SystemExit("--url deve começar com http:// ou https://")
        payload = json.dumps({"version": version, "url": url}, separators=(",", ":"))

    client = mqtt.Client(mqtt.CallbackAPIVersion.VERSION2, transport="websockets")
    client.ws_set_options(path=args.ws_path)
    client.tls_set(cert_reqs=ssl.CERT_NONE)
    client.username_pw_set(args.user, args.password)
    client.connect(args.host, args.port, 60)
    info = client.publish(topic, payload, qos=1, retain=True)
    info.wait_for_publish(timeout=15)
    client.disconnect()
    if args.clear:
        print(f"Canal limpo: {topic}")
    else:
        print(f"Publicado retained {topic}")
        print(payload)


if __name__ == "__main__":
    main()
