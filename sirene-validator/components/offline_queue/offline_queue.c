#include "offline_queue.h"

#include <stdio.h>
#include <string.h>

#include "board_config.h"
#include "cJSON.h"
#include "esp_log.h"
#include "esp_spiffs.h"
#include "esp_task_wdt.h"
#include "freertos/FreeRTOS.h"
#include "freertos/semphr.h"
#include "freertos/task.h"
#include "nvs.h"
#include "nvs_flash.h"

static const char *TAG = "offline_q";
static offline_queue_publish_fn s_publish_fn;
static TaskHandle_t s_sync_task;
static SemaphoreHandle_t s_mu;
static uint32_t s_drop_count;

#define OFFLINE_ENTRY_MAX 512

typedef struct {
    uint32_t head;
    uint32_t tail;
    uint32_t count;
} queue_meta_t;

static queue_meta_t s_meta;
static bool s_meta_loaded;

static void queue_lock(void)
{
    if (s_mu) {
        xSemaphoreTake(s_mu, portMAX_DELAY);
    }
}

static void queue_unlock(void)
{
    if (s_mu) {
        xSemaphoreGive(s_mu);
    }
}

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

static bool read_entry_raw(uint32_t index, char *raw, size_t raw_len)
{
    char path[32];
    entry_path(path, sizeof(path), index);
    FILE *f = fopen(path, "r");
    if (!f) {
        return false;
    }
    size_t n = fread(raw, 1, raw_len - 1, f);
    raw[n] = '\0';
    fclose(f);
    return n > 0;
}

static bool write_entry_raw(uint32_t index, const char *raw)
{
    char path[32];
    entry_path(path, sizeof(path), index);
    FILE *f = fopen(path, "w");
    if (!f) {
        return false;
    }
    fputs(raw, f);
    fclose(f);
    return true;
}

static bool write_envelope(uint32_t index, const char *topic_suffix, const char *json)
{
    const char *topic = (topic_suffix && topic_suffix[0] != '\0') ? topic_suffix : "status";

    cJSON *root = cJSON_CreateObject();
    if (!root) {
        return false;
    }
    cJSON_AddStringToObject(root, "topic", topic);
    cJSON *payload = cJSON_Parse(json);
    if (!payload) {
        cJSON_Delete(root);
        return false;
    }
    cJSON_AddItemToObject(root, "payload", payload);

    char *printed = cJSON_PrintUnformatted(root);
    cJSON_Delete(root);
    if (!printed) {
        return false;
    }

    bool ok = write_entry_raw(index, printed);
    free(printed);
    return ok;
}

static bool decode_entry(const char *raw, char *topic_out, size_t topic_len, char *json_out, size_t json_len)
{
    cJSON *root = cJSON_Parse(raw);
    if (!root) {
        return false;
    }

    cJSON *topic = cJSON_GetObjectItem(root, "topic");
    cJSON *payload = cJSON_GetObjectItem(root, "payload");
    if (cJSON_IsString(topic) && payload != NULL) {
        strncpy(topic_out, topic->valuestring, topic_len - 1);
        topic_out[topic_len - 1] = '\0';
        char *printed = cJSON_PrintUnformatted(payload);
        if (!printed) {
            cJSON_Delete(root);
            return false;
        }
        strncpy(json_out, printed, json_len - 1);
        json_out[json_len - 1] = '\0';
        free(printed);
    } else {
        strncpy(topic_out, "status", topic_len - 1);
        topic_out[topic_len - 1] = '\0';
        strncpy(json_out, raw, json_len - 1);
        json_out[json_len - 1] = '\0';
    }

    cJSON_Delete(root);
    return true;
}

bool offline_queue_init(void)
{
    if (!s_mu) {
        s_mu = xSemaphoreCreateMutex();
    }
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
    queue_lock();
    meta_ensure_loaded();
    bool full = s_meta.count >= OFFLINE_QUEUE_MAX;
    queue_unlock();
    return full;
}

size_t offline_queue_count(void)
{
    queue_lock();
    meta_ensure_loaded();
    size_t count = s_meta.count;
    queue_unlock();
    return count;
}

uint32_t offline_queue_drop_count(void)
{
    return s_drop_count;
}

bool offline_queue_push(const char *topic_suffix, const char *json)
{
    queue_lock();
    meta_ensure_loaded();
    if (s_meta.count >= OFFLINE_QUEUE_MAX) {
        s_drop_count++;
        ESP_LOGE(TAG, "fila cheia (%u) — mensagem NAO gravada (drops=%lu)",
                 OFFLINE_QUEUE_MAX, (unsigned long)s_drop_count);
        queue_unlock();
        return false;
    }

    bool ok = false;
    if (write_envelope(s_meta.tail, topic_suffix, json)) {
        s_meta.tail = (s_meta.tail + 1) % OFFLINE_QUEUE_MAX;
        s_meta.count++;
        ok = meta_persist();
    }
    queue_unlock();
    return ok;
}

bool offline_queue_peek(const char *topic_suffix, size_t topic_len, char *json, size_t json_len)
{
    queue_lock();
    meta_ensure_loaded();
    if (s_meta.count == 0) {
        queue_unlock();
        return false;
    }

    char raw[OFFLINE_ENTRY_MAX];
    bool ok = read_entry_raw(s_meta.head, raw, sizeof(raw));
    if (ok) {
        ok = decode_entry(raw, (char *)topic_suffix, topic_len, json, json_len);
    }
    queue_unlock();
    return ok;
}

bool offline_queue_pop(void)
{
    queue_lock();
    meta_ensure_loaded();
    if (s_meta.count == 0) {
        queue_unlock();
        return false;
    }
    char path[32];
    entry_path(path, sizeof(path), s_meta.head);
    remove(path);
    s_meta.head = (s_meta.head + 1) % OFFLINE_QUEUE_MAX;
    s_meta.count--;
    bool ok = meta_persist();
    queue_unlock();
    return ok;
}

void offline_queue_set_publish_fn(offline_queue_publish_fn fn)
{
    s_publish_fn = fn;
}

static void drain_queue(void)
{
    char topic[32];
    char json[OFFLINE_ENTRY_MAX];
    while (offline_queue_peek(topic, sizeof(topic), json, sizeof(json)) && s_publish_fn) {
        esp_task_wdt_reset();
        if (s_publish_fn(topic, json)) {
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
