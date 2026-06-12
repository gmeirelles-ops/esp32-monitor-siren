#include "state_machine.h"

#include "esp_log.h"
#include "pure_logic.h"

static const char *TAG = "state";
static app_state_t s_state = STATE_PROVISIONING;
static state_change_cb_t s_cb;

void state_machine_init(state_change_cb_t cb)
{
    s_cb = cb;
    s_state = STATE_PROVISIONING;
}

app_state_t state_machine_get(void)
{
    return s_state;
}

void state_machine_set(app_state_t state)
{
    if (s_state == state) {
        return;
    }
    app_state_t prev = s_state;
    s_state = state;
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

bool state_machine_can_start_test(void)
{
    return pure_fsm_can_start_test(to_pure_state(s_state), false, false);
}

bool state_machine_can_accept_batch_cmd(void)
{
    return pure_fsm_can_accept_batch(to_pure_state(s_state), false);
}

bool state_machine_can_accept_calibration(void)
{
    return pure_fsm_can_accept_calibration(to_pure_state(s_state), false);
}

bool state_machine_can_accept_ota(void)
{
    return pure_fsm_can_accept_ota(to_pure_state(s_state));
}
