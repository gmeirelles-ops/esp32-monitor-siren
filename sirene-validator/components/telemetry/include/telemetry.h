#pragma once

#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>

typedef struct {
    int rssi;
    const char *estado;
    const char *wifi_ssid;
    size_t fila;
    const char *firmware_version;
    const char *numero_op;
    uint32_t proximo_sequencial;
    uint32_t aprovados;
    bool batch_active;
    uint32_t queue_drops;
    uint32_t pzem_faults;
    bool batch_nvs_fault;
    int reset_reason;
    bool time_synced;
    uint8_t pzem_addr;
    bool last_test_valid;
    const char *ultimo_veredito;
    float ultima_potencia;
    uint32_t ultimo_sequencial;
    int64_t ultimo_ts_ms;
} telemetry_snapshot_t;

bool telemetry_init(void);
void telemetry_start(void);
void telemetry_set_snapshot_provider(bool (*provider)(telemetry_snapshot_t *out));
void telemetry_publish_now(void);
