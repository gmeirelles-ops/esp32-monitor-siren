#pragma once

typedef enum {
    STATE_PROVISIONING = 0,
    STATE_IDLE,
    STATE_BATCH_READY,
    STATE_TESTING,
    STATE_HARDWARE_FAULT,
    STATE_OTA_UPDATING,
} app_state_t;

typedef void (*state_change_cb_t)(app_state_t prev, app_state_t next);

void state_machine_init(state_change_cb_t cb);
app_state_t state_machine_get(void);
void state_machine_set(app_state_t state);
const char *state_machine_name(app_state_t state);
bool state_machine_can_start_test(void);
bool state_machine_can_accept_batch_cmd(void);
bool state_machine_can_accept_calibration(void);
bool state_machine_can_accept_ota(void);
