/**
 * @file main.c
 * @brief Bancada QA Diponto – máquina de estados (PZEM + MQTT + Firebase).
 */

#include <stdio.h>

#include "comm.h"
#include "control.h"
#include "esp_log.h"
#include "freertos/FreeRTOS.h"
#include "freertos/task.h"
#include "pzem_sensor.h"

#define TAG                 "bancada"
#define SAMPLE_INTERVAL_MS  100
#define IDLE_POLL_MS        20
#define TASK_STACK          8192
#define TASK_PRIO           5

typedef enum {
    STATE_IDLE = 0,
    STATE_WAITING_FIREBASE,
    STATE_TESTING,
    STATE_SENDING_RESULT,
} bench_state_t;

static bench_state_t s_state = STATE_IDLE;
static int s_test_time_sec = 0;
static float s_max_power_w = 0.0f;

static const char *state_name(bench_state_t st)
{
    switch (st) {
    case STATE_IDLE:              return "IDLE";
    case STATE_WAITING_FIREBASE:  return "WAITING_FIREBASE";
    case STATE_TESTING:           return "TESTING";
    case STATE_SENDING_RESULT:    return "SENDING_RESULT";
    default:                      return "?";
    }
}

static void bench_task(void *pv)
{
    (void)pv;

    ESP_LOGI(TAG, "Task FSM iniciada (core %d)", xPortGetCoreID());

    for (;;) {
        switch (s_state) {
        case STATE_IDLE:
            if (button_is_pressed()) {
                ESP_LOGI(TAG, "[%s] Botão – buscar tempo no Firebase", state_name(s_state));
                s_state = STATE_WAITING_FIREBASE;
            } else {
                vTaskDelay(pdMS_TO_TICKS(IDLE_POLL_MS));
            }
            break;

        case STATE_WAITING_FIREBASE:
            s_test_time_sec = firebase_get_test_time();
            if (s_test_time_sec > 0) {
                ESP_LOGI(TAG, "[%s] tempo_teste=%d s → TESTING",
                         state_name(s_state), s_test_time_sec);
                s_max_power_w = 0.0f;
                s_state = STATE_TESTING;
            } else {
                ESP_LOGW(TAG, "[%s] Firebase indisponível – voltando IDLE",
                         state_name(s_state));
                s_state = STATE_IDLE;
            }
            break;

        case STATE_TESTING: {
            const uint32_t duration_ms = (uint32_t)s_test_time_sec * 1000U;
            const TickType_t deadline =
                xTaskGetTickCount() + pdMS_TO_TICKS(duration_ms);

            ESP_LOGI(TAG, "[%s] Relé ON – duração %d s", state_name(s_state), s_test_time_sec);
            relay_set(true);

            while (xTaskGetTickCount() < deadline) {
                const float power = pzem_get_power();

                if (power >= 0.0f) {
                    if (power > s_max_power_w) {
                        s_max_power_w = power;
                    }
                    mqtt_publish_power(power);
                    ESP_LOGI(TAG, "[%s] potência=%.2f W (pico=%.2f W)",
                             state_name(s_state), power, s_max_power_w);
                } else {
                    ESP_LOGW(TAG, "[%s] leitura PZEM falhou – ignorando amostra",
                             state_name(s_state));
                }

                vTaskDelay(pdMS_TO_TICKS(SAMPLE_INTERVAL_MS));
            }

            relay_set(false);
            ESP_LOGI(TAG, "[%s] Relé OFF – pico %.2f W", state_name(s_state), s_max_power_w);
            s_state = STATE_SENDING_RESULT;
            break;
        }

        case STATE_SENDING_RESULT:
            firebase_send_result(s_max_power_w);
            ESP_LOGI(TAG, "[%s] Resultado enviado – ciclo concluído", state_name(s_state));
            s_state = STATE_IDLE;
            vTaskDelay(pdMS_TO_TICKS(500));
            break;

        default:
            ESP_LOGW(TAG, "Estado inválido – reset IDLE");
            relay_set(false);
            s_state = STATE_IDLE;
            break;
        }
    }
}

void app_main(void)
{
    ESP_LOGI(TAG, "Bancada QA Diponto – ESP-IDF v5.x");

    control_init();
    comm_init();
    pzem_sensor_init();

    xTaskCreate(bench_task, "bench_fsm", TASK_STACK, NULL, TASK_PRIO, NULL);

    ESP_LOGI(TAG, "Sistema pronto – aguardando botão (GPIO 0)");
}
