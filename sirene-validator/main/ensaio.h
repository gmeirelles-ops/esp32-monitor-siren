#pragma once

#include "app_runtime.h"
#include "cJSON.h"

bool ensaio_parse_start(cJSON *root, ensaio_params_t *out);
bool ensaio_enqueue_work(ensaio_params_t params);
void ensaio_handle_start(ensaio_params_t params);
void ensaio_handle_stop(void);
