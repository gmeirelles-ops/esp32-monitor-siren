#pragma once

#include <stdbool.h>

#include "freertos/FreeRTOS.h"
#include "freertos/queue.h"

void button_init(QueueHandle_t event_queue);
bool button_is_test_in_progress(void);
void button_set_test_in_progress(bool in_progress);
