#include "offline_queue.h"

#include <stdio.h>
#include <string.h>

#include "board_config.h"
#include "esp_log.h"
#include "esp_task_wdt.h"
#include "freertos/FreeRTOS.h"
#include "freertos/task.h"
#include "nvs.h"
#include "nvs_flash.h"
#include "esp_spiffs.h"

static const char *TAG = "offline_q";
static offline_queue_publish_fn s_publish_fn;
static TaskHandle_t s_sync_task;

typedef struct {
    uint32_t head;
    uint32_t tail;
    uint32_t count;
} queue_meta_t;

static queue_meta_t s_meta;
static bool s_meta_loaded;

static bool load_meta_from_nvs(queue_meta_t *meta)
{
    nvs_handle_t handle;
    if (nvs_open(QUEUE_NVS_NAMESPACE, NVS_READONLY, &handle) != ESP_OK) {
        meta->head = meta->tail = meta->count = 0;
        return false;
    }
    nvs_get_u32(handle, "head", &meta->head);
    nvs_get_u32(handle, "tail", &meta->tail);
    nvs_get_u32(handle, "count", &meta->count);
    nvs_close(handle);
    return true;
}

static bool save_meta_to_nvs(const queue_meta_t *meta)
{
    nvs_handle_t handle;
    if (nvs_open(QUEUE_NVS_NAMESPACE, NVS_READWRITE, &handle) != ESP_OK) {
        return false;
    }
    nvs_set_u32(handle, "head", meta->head);
    nvs_set_u32(handle, "tail", meta->tail);
    nvs_set_u32(handle, "count", meta->count);
    esp_err_t err = nvs_commit(handle);
    nvs_close(handle);
    return err == ESP_OK;
}

static void meta_ensure_loaded(void)
{
    if (s_meta_loaded) {
        return;
    }
    load_meta_from_nvs(&s_meta);
    s_meta_loaded = true;
}

static bool meta_persist(void)
{
    return save_meta_to_nvs(&s_meta);
}

static void entry_path(char *path, size_t len, uint32_t index)
{
    snprintf(path, len, "/storage/q_%04lu.json", (unsigned long)index);
}

bool offline_queue_init(void)
{
    esp_vfs_spiffs_conf_t conf = {
        .base_path = "/storage",
        .partition_label = "storage",
        .max_files = OFFLINE_QUEUE_MAX + 4,
        .format_if_mount_failed = true,
    };
    esp_err_t ret = esp_vfs_spiffs_register(&conf);
    if (ret != ESP_OK) {
        ESP_LOGE(TAG, "SPIFFS mount failed: %s", esp_err_to_name(ret));
        return false;
    }
    meta_ensure_loaded();
    return true;
}

bool offline_queue_is_full(void)
{
    meta_ensure_loaded();
    return s_meta.count >= OFFLINE_QUEUE_MAX;
}

size_t offline_queue_count(void)
{
    meta_ensure_loaded();
    return s_meta.count;
}

bool offline_queue_push(const char *json)
{
    meta_ensure_loaded();
    if (s_meta.count >= OFFLINE_QUEUE_MAX) {
        ESP_LOGW(TAG, "fila cheia — descartando entrada mais antiga");
        char path[32];
        entry_path(path, sizeof(path), s_meta.head);
        remove(path);
        s_meta.head = (s_meta.head + 1) % OFFLINE_QUEUE_MAX;
        s_meta.count--;
    }

    char path[32];
    entry_path(path, sizeof(path), s_meta.tail);
    FILE *f = fopen(path, "w");
    if (!f) {
        return false;
    }
    fputs(json, f);
    fclose(f);

    s_meta.tail = (s_meta.tail + 1) % OFFLINE_QUEUE_MAX;
    s_meta.count++;
    return meta_persist();
}

bool offline_queue_peek(char *json, size_t json_len)
{
    meta_ensure_loaded();
    if (s_meta.count == 0) {
        return false;
    }
    char path[32];
    entry_path(path, sizeof(path), s_meta.head);
    FILE *f = fopen(path, "r");
    if (!f) {
        return false;
    }
    size_t n = fread(json, 1, json_len - 1, f);
    json[n] = '\0';
    fclose(f);
    return n > 0;
}

bool offline_queue_pop(void)
{
    meta_ensure_loaded();
    if (s_meta.count == 0) {
        return false;
    }
    char path[32];
    entry_path(path, sizeof(path), s_meta.head);
    remove(path);
    s_meta.head = (s_meta.head + 1) % OFFLINE_QUEUE_MAX;
    s_meta.count--;
    return meta_persist();
}

void offline_queue_set_publish_fn(offline_queue_publish_fn fn)
{
    s_publish_fn = fn;
}

static void drain_queue(void)
{
    char json[512];
    while (offline_queue_peek(json, sizeof(json)) && s_publish_fn) {
        esp_task_wdt_reset();
        if (s_publish_fn("status", json)) {
            offline_queue_pop();
        } else {
            break;
        }
    }
}

static void sync_task(void *arg)
{
    (void)arg;
    esp_task_wdt_add(NULL);
    while (true) {
        esp_task_wdt_reset();
        drain_queue();
        ulTaskNotifyTake(pdTRUE, pdMS_TO_TICKS(OFFLINE_SYNC_INTERVAL_MS));
    }
}

void offline_queue_sync_now(void)
{
    if (s_sync_task) {
        xTaskNotifyGive(s_sync_task);
    }
}

void offline_queue_sync_task_start(void)
{
    xTaskCreate(sync_task, "offline_sync", 4096, NULL, 5, &s_sync_task);
}
