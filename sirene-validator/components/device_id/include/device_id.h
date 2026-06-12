#pragma once

#include <stddef.h>

void device_id_init(void);
const char *device_id_get(void);

void device_id_topic(char *buf, size_t buflen, const char *suffix);
