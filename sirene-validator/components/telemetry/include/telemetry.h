#pragma once

#include <stdbool.h>
#include <stddef.h>

typedef struct {
    int rssi;
    const char *estado;
    size_t fila;
    const char *firmware_version;
} telemetry_snapshot_t;

bool telemetry_init(void);
void telemetry_start(void);
void telemetry_set_snapshot_provider(bool (*provider)(telemetry_snapshot_t *out));
void telemetry_publish_now(void);
