#pragma once

#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>

typedef struct {
    int rssi;
    const char *estado;
    size_t fila;
    const char *firmware_version;
    const char *numero_op;
    uint32_t proximo_sequencial;
    uint32_t aprovados;
    bool batch_active;
} telemetry_snapshot_t;

bool telemetry_init(void);
void telemetry_start(void);
void telemetry_set_snapshot_provider(bool (*provider)(telemetry_snapshot_t *out));
void telemetry_publish_now(void);
