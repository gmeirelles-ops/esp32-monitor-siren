#pragma once

#include <stdint.h>

/* GPIO map — ajuste conforme o hardware da placa */
#define GPIO_RELAY            4
#define GPIO_BUTTON           5
#define GPIO_LED_STATUS       25
#define GPIO_BUZZER           33

/* UART PZEM-004T */
#define PZEM_UART_NUM         UART_NUM_2
#define PZEM_TX_PIN           27
#define PZEM_RX_PIN           26
#define PZEM_BAUD_RATE        9600
#define PZEM_SLAVE_ADDR       0x01   /* PZEM-004T v1/clones; v3.0 de fábrica usa 0xF8 */
#define PZEM_READ_ALL_REGS    10
#define PZEM_RESPONSE_ALL_LEN 25     /* 3 + (10 regs × 2) + CRC */
#define PZEM_RESPONSE_DELAY_MS  100
#define PZEM_READ_TIMEOUT_MS    300

/* MQTT broker (fallback de fábrica — sobrescrito por NVS mqtt_cfg se provisionado) */
#define MQTT_BROKER_URI       "mqtt://192.168.51.87:1883"
#define MQTT_TOPIC_PREFIX     "sirene"
#define MQTT_NVS_NAMESPACE    "mqtt_cfg"
#define MQTT_NVS_HOST_KEY     "host"
#define MQTT_NVS_PORT_KEY     "port"
#define MQTT_DEFAULT_PORT     1883

/* Timing */
#define INRUSH_DISCARD_MS         500
#define PZEM_SAMPLE_READ_RETRIES  3
#define CALIBRATION_SEC           5
#define CALIBRATION_SAMPLE_MS     500
#define BUTTON_DEBOUNCE_MS    50

/* Offline queue */
#define OFFLINE_QUEUE_MAX     64

/* Wi-Fi provisioning */
#define WIFI_AP_SSID          "SireneValidator"
#define WIFI_AP_PASS          ""
#define WIFI_AP_IP            "192.168.4.1"
#define WIFI_NVS_NAMESPACE    "wifi_cfg"
#define WIFI_NVS_SSID_KEY     "ssid"
#define WIFI_NVS_PASS_KEY     "pass"

/* NVS namespaces */
#define BATCH_NVS_NAMESPACE   "batch"
#define QUEUE_NVS_NAMESPACE   "queue"

/* Telemetria e robustez */
#define HEARTBEAT_INTERVAL_SEC    30
#define WIFI_RECONNECT_BASE_MS      1000
#define WIFI_RECONNECT_MAX_MS       30000
#define MQTT_RECONNECT_BASE_MS      1000
#define MQTT_RECONNECT_MAX_MS       30000
#define WIFI_STA_VALIDATE_TIMEOUT_MS 15000
#define OFFLINE_SYNC_INTERVAL_MS    5000
#define FIRMWARE_VERSION            "1.4.2"
