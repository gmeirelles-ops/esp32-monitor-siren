#pragma once

#include <stdbool.h>
#include <stdint.h>

void line_actuator_init(void);
void line_actuator_safe_all(void);
void line_actuator_on_approved(bool allow_physical);
void line_actuator_on_rejected(void);

/** Returns reject GPIO or -1 if disabled. For telemetry JSON. */
int line_actuator_reject_gpio(void);
uint16_t line_actuator_reject_pulse_ms(void);
