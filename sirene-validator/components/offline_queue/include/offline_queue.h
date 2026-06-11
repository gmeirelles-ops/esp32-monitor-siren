#pragma once

#include <stdbool.h>
#include <stddef.h>

bool offline_queue_init(void);
bool offline_queue_push(const char *json);
bool offline_queue_peek(char *json, size_t json_len);
bool offline_queue_pop(void);
bool offline_queue_is_full(void);
size_t offline_queue_count(void);
void offline_queue_sync_task_start(void);
void offline_queue_sync_now(void);

typedef bool (*offline_queue_publish_fn)(const char *topic_suffix, const char *json);

void offline_queue_set_publish_fn(offline_queue_publish_fn fn);
