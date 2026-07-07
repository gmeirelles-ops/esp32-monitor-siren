#pragma once

#include <stdbool.h>
#include <stdint.h>

#include "state_machine.h"

void oled_display_init(void);
bool oled_display_is_ready(void);
void oled_display_refresh(void);
void oled_display_on_state_change(app_state_t prev, app_state_t next);
void oled_display_on_test_result(bool approved, float potencia_w);
void oled_display_set_batch(const char *numero_op, uint32_t aprovados, uint32_t sequencial);
