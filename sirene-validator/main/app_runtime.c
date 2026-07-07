#include "app_runtime.h"

#include "board_config.h"
#include "esp_timer.h"
#include "led_feedback.h"
#include "mqtt_bridge.h"
#include "offline_queue.h"
#include "time_sync.h"

static SemaphoreHandle_t s_batch_mu;
static QueueHandle_t s_work_queue;
static QueueHandle_t s_pzem_queue;
static batch_context_t s_batch;
static bool s_batch_nvs_fault;
static app_state_t s_state_before_fault;
static volatile bool s_pzem_busy;
static bool s_calibrating;
static volatile bool s_ensaio_stop;
static bool s_ensaio_running;

void app_runtime_init(SemaphoreHandle_t batch_mu, QueueHandle_t work_q, QueueHandle_t pzem_q)
{
    s_batch_mu = batch_mu;
    s_work_queue = work_q;
    s_pzem_queue = pzem_q;
}

void app_batch_lock(void)
{
    if (s_batch_mu) {
        xSemaphoreTake(s_batch_mu, portMAX_DELAY);
    }
}

void app_batch_unlock(void)
{
    if (s_batch_mu) {
        xSemaphoreGive(s_batch_mu);
    }
}

batch_context_t *app_batch(void)
{
    return &s_batch;
}

bool *app_batch_nvs_fault(void)
{
    return &s_batch_nvs_fault;
}

app_state_t *app_state_before_fault(void)
{
    return &s_state_before_fault;
}

volatile bool *app_pzem_busy(void)
{
    return &s_pzem_busy;
}

bool *app_calibrating(void)
{
    return &s_calibrating;
}

volatile bool *app_ensaio_stop(void)
{
    return &s_ensaio_stop;
}

bool *app_ensaio_running(void)
{
    return &s_ensaio_running;
}

QueueHandle_t app_pzem_queue(void)
{
    return s_pzem_queue;
}

QueueHandle_t app_work_queue(void)
{
    return s_work_queue;
}

int64_t app_now_ts_ms(void)
{
    return esp_timer_get_time() / 1000;
}

void app_publish_or_queue(const char *topic_suffix, const char *json)
{
    if (mqtt_bridge_is_connected() && mqtt_bridge_publish(topic_suffix, json)) {
        return;
    }
    if (offline_queue_is_full()) {
        led_feedback_signal(FEEDBACK_QUEUE_FULL);
        return;
    }
    if (!offline_queue_push(topic_suffix, json)) {
        led_feedback_signal(FEEDBACK_QUEUE_FULL);
    }
}

bool app_enqueue_pzem_work(pzem_work_type_t type, uint32_t duration_sec, const ensaio_params_t *ensaio)
{
    if (s_pzem_busy) {
        return false;
    }
    pzem_work_item_t item = {
        .type = type,
        .duration_sec = duration_sec,
    };
    if (ensaio != NULL) {
        item.ensaio = *ensaio;
    }
    if (xQueueSend(s_pzem_queue, &item, 0) != pdTRUE) {
        return false;
    }
    s_pzem_busy = true;
    return true;
}