#pragma once

#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>

bool mqtt_topics_init(void);
bool mqtt_topics_is_configured(void);
bool mqtt_topics_build(char *buf, size_t len, const char *suffix);
bool mqtt_topics_save(uint8_t bancada, const char *site);
uint8_t mqtt_topics_get_bancada(void);
const char *mqtt_topics_get_site(void);
bool mqtt_topics_clear(void);
