#pragma once

#include <stdbool.h>

#include "cJSON.h"
#include "state_machine.h"

void mqtt_cmd_process_payload(const char *payload);
bool mqtt_cmd_is_blocked(const char *payload);
void mqtt_cmd_on_command(const char *payload, int len);
void hardware_fault_enter(app_state_t restore_state, const char *falha);
