#include "time_sync.h"

#include <time.h>

#include "esp_log.h"
#include "esp_sntp.h"

static const char *TAG = "time_sync";
static bool s_ready;

static void on_time_sync(struct timeval *tv)
{
    (void)tv;
    s_ready = true;
    ESP_LOGI(TAG, "SNTP sincronizado");
}

void time_sync_start(void)
{
    if (esp_sntp_enabled()) {
        return;
    }
    esp_sntp_setoperatingmode(SNTP_OPMODE_POLL);
    esp_sntp_setservername(0, "pool.ntp.org");
    esp_sntp_setservername(1, "time.google.com");
    esp_sntp_set_time_sync_notification_cb(on_time_sync);
    esp_sntp_init();
    ESP_LOGI(TAG, "SNTP iniciado");
}

bool time_sync_ready(void)
{
    if (s_ready) {
        return true;
    }
    time_t now = 0;
    time(&now);
    if (now > 1700000000L) {
        s_ready = true;
    }
    return s_ready;
}

int64_t time_sync_unix(void)
{
    if (!time_sync_ready()) {
        return 0;
    }
    time_t now = 0;
    time(&now);
    return (int64_t)now;
}
