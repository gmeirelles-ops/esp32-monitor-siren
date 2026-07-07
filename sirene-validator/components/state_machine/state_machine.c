#include "state_machine.h"

#include "esp_log.h"
#include "freertos/FreeRTOS.h"
#include "freertos/semphr.h"
#include "ota_update.h"
#include "pzem.h"
#include "pure_logic.h"

static const char *TAG = "state";
static app_state_t s_state = STATE_PROVISIONING;
static state_change_cb_t s_cb;
static SemaphoreHandle_t s_mu;

void state_machine_init(state_change_cb_t cb)
{
    if (!s_mu) {
        s_mu = xSemaphoreCreateMutex();
    }
    s_cb = cb;
    s_state = STATE_PROVISIONING;
}

static void state_lock(void)
{
    if (s_mu) {
        xSemaphoreTake(s_mu, portMAX_DELAY);
    }
}

static void state_unlock(void)
{
    if (s_mu) {
        xSemaphoreGive(s_mu);
    }
}

app_state_t state_machine_get(void)
{
    state_lock();
    app_state_t state = s_state;
    state_unlock();
    return state;
}

void state_machine_set(app_state_t state)
{
    state_lock();
    if (s_state == state) {
        state_unlock();
        return;
    }
    app_state_t prev = s_state;
    s_state = state;
    state_unlock();
    ESP_LOGI(TAG, "%s -> %s", state_machine_name(prev), state_machine_name(state));
    if (s_cb) {
        s_cb(prev, state);
    }
}

const char *state_machine_name(app_state_t state)
{
    switch (state) {
    case STATE_PROVISIONING: return "PROVISIONING";
    case STATE_IDLE: return "IDLE";
    case STATE_BATCH_READY: return "BATCH_READY";
    case STATE_TESTING: return "TESTING";
    case STATE_HARDWARE_FAULT: return "HARDWARE_FAULT";
    case STATE_OTA_UPDATING: return "OTA_UPDATING";
    default: return "UNKNOWN";
    }
}

static pure_state_t to_pure_state(app_state_t state)
{
    return (pure_state_t)state;
}

static bool ota_blocks_commands(void)
{
    return ota_update_is_active() || state_machine_get() == STATE_OTA_UPDATING;
}

bool state_machine_can_start_test(void)
{
    state_lock();
    app_state_t state = s_state;
    state_unlock();
    return pure_fsm_can_start_test(to_pure_state(state), pzem_is_fault(), ota_blocks_commands());
}

bool state_machine_can_accept_batch_cmd(void)
{
    state_lock();
    app_state_t state = s_state;
    state_unlock();
    return pure_fsm_can_accept_batch(to_pure_state(state), ota_blocks_commands());
}

bool state_machine_can_accept_calibration(void)
{
    state_lock();
    app_state_t state = s_state;
    state_unlock();
    return pure_fsm_can_accept_calibration(to_pure_state(state), ota_blocks_commands());
}

bool state_machine_can_accept_ota(void)
{
    state_lock();
    app_state_t state = s_state;
    state_unlock();
    return pure_fsm_can_accept_ota(to_pure_state(state));
}
