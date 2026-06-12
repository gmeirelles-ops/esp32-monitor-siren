#pragma once

#include <stdbool.h>

void relay_init_safe(void);
void relay_set(bool on);
bool relay_is_on(void);
