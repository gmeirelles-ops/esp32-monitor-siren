#pragma once

#include <stdbool.h>
#include <stdint.h>

#include "batch_storage.h"
#include "freertos/FreeRTOS.h"
#include "freertos/queue.h"
#include "freertos/semphr.h"
#include "state_machine.h"

typedef struct {
    uint32_t on_sec;
    uint32_t off_sec;
    uint32_t total_sec;
} ensaio_params_t;

typedef enum {
    PZEM_WORK_TEST = 1,
    PZEM_WORK_CALIBRATION,
    PZEM_WORK_ENSAIO,
    PZEM_WORK_PROBE,
} pzem_work_type_t;

typedef struct {
    pzem_work_type_t type;
    uint32_t duration_sec;
    ensaio_params_t ensaio;
} pzem_work_item_t;

typedef enum {
    WORK_BUTTON_PRESS = 1,
    WORK_MQTT_PAYLOAD,
} work_type_t;

typedef struct {
    work_type_t type;
    char payload[512];
} work_item_t;

void app_runtime_init(SemaphoreHandle_t batch_mu, QueueHandle_t work_q, QueueHandle_t pzem_q);
void app_publish_or_queue(const char *topic_suffix, const char *json);
void app_batch_lock(void);
void app_batch_unlock(void);
batch_context_t *app_batch(void);
bool *app_batch_nvs_fault(void);
app_state_t *app_state_before_fault(void);
volatile bool *app_pzem_busy(void);
bool *app_calibrating(void);
volatile bool *app_ensaio_stop(void);
bool *app_ensaio_running(void);
QueueHandle_t app_pzem_queue(void);
QueueHandle_t app_work_queue(void);
int64_t app_now_ts_ms(void);
bool app_enqueue_pzem_work(pzem_work_type_t type, uint32_t duration_sec, const ensaio_params_t *ensaio);

typedef struct {
    bool valid;
    char veredito[16];
    float potencia_media;
    uint32_t sequencial;
    int64_t ts_ms;
} app_last_test_t;

void app_last_test_set(bool approved, float potencia_media, uint32_t sequencial, int64_t ts_ms);
void app_last_test_get(app_last_test_t *out);
