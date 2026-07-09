#!/usr/bin/env python3
"""Publica OTA_UPDATE uma vez via MQTT (Windows/Linux)."""
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


def _use_websocket(host: str, port: int, force_ws: bool | None) -> bool:
    if force_ws is not None:
        return force_ws
    if port in (443, 80):
        return True
    return host.endswith("diponto.com")


def publish_ota(
    *,
    topic: str,
    payload: str,
    host: str,
    port: int,
    user: str,
    password: str,
    use_tls: bool,
    insecure: bool,
    use_websocket: bool | None,
    ws_path: str,
) -> None:
    transport = "websockets" if _use_websocket(host, port, use_websocket) else "tcp"
    client = mqtt.Client(mqtt.CallbackAPIVersion.VERSION2, transport=transport)
    if transport == "websockets":
        client.ws_set_options(path=ws_path)
    if use_tls or transport == "websockets":
        if insecure:
            client.tls_set(cert_reqs=ssl.CERT_NONE)
        else:
            client.tls_set()
    if user:
        client.username_pw_set(user, password or None)
    client.connect(host, port, 60)
    info = client.publish(topic, payload, qos=1)
    info.wait_for_publish(timeout=15)
    client.disconnect()


def main() -> None:
    p = argparse.ArgumentParser(description="Publica OTA_UPDATE no topico comando da bancada.")
    p.add_argument("--bancada", type=int, required=True)
    p.add_argument("--site", default="producao")
    p.add_argument("--host", default="mqtt.diponto.com")
    p.add_argument("--port", type=int, default=443)
    p.add_argument("--user", default="devices")
    p.add_argument("--password", default="w1FefRLm+q1_O8H")
    p.add_argument("--url", required=True)
    p.add_argument(
        "--tls",
        action="store_true",
        help="MQTT over TLS (WSS na porta 443 no broker cloud)",
    )
    p.add_argument(
        "--insecure",
        action="store_true",
        default=True,
        help="TLS sem verificar certificado (padrao LAN/dev)",
    )
    p.add_argument(
        "--websocket",
        action="store_true",
        help="Forca transporte WebSocket (padrao em :443 e diponto.com)",
    )
    p.add_argument(
        "--no-websocket",
        action="store_true",
        help="Forca TCP (ex.: broker LAN :1883)",
    )
    p.add_argument("--ws-path", default="/ws")
    args = p.parse_args()

    topic = f"{args.site}/bancada-{args.bancada:02d}/comando"
    payload = json.dumps({"cmd": "OTA_UPDATE", "url": args.url})

    use_ws = None
    if args.websocket:
        use_ws = True
    elif args.no_websocket:
        use_ws = False

    use_tls = args.tls or _use_websocket(args.host, args.port, use_ws)

    publish_ota(
        topic=topic,
        payload=payload,
        host=args.host,
        port=args.port,
        user=args.user,
        password=args.password,
        use_tls=use_tls,
        insecure=args.insecure,
        use_websocket=use_ws,
        ws_path=args.ws_path,
    )
    print(f"OK {topic}")
    print(payload)


if __name__ == "__main__":
    main()
