#pragma once

#include "app_runtime.h"
#include "cJSON.h"

bool batch_cmd_parse_set_batch(cJSON *root);
void batch_cmd_end_batch(void);
void batch_cmd_end_batch_with_reason(const char *motivo);
void batch_cmd_publish_ack(void);
void batch_cmd_publish_nvs_fault(void);
void batch_cmd_run_test_cycle(uint32_t duration_sec);
