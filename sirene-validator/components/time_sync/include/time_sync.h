#pragma once

#include <stdbool.h>
#include <stdint.h>

void time_sync_start(void);
bool time_sync_ready(void);
int64_t time_sync_unix(void);
