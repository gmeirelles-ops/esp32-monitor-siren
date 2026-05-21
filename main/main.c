/**
 * @file main.c
 * @brief Ponto de entrada: inicialização e criação das tasks FreeRTOS.
 */

#include "esp_log.h"
#include "nvs_flash.h"
#include "freertos/FreeRTOS.h"
#include "freertos/task.h"

#include "hardware.h"
#include "pzem_sensor.h"
#include "wifi_manager.h"

#define TASK_WIFI_STACK   (4096)
#define TASK_TESTE_STACK  (6144)
#define TASK_WIFI_PRIO    (5)
#define TASK_TESTE_PRIO   (6)

static const char *TAG = "main";

void app_main(void)
{
    ESP_LOGI(TAG, "Sistema de Teste de Sirenes – ESP-IDF v5.3.2");

    esp_err_t ret = nvs_flash_init();
    if (ret == ESP_ERR_NVS_NO_FREE_PAGES || ret == ESP_ERR_NVS_NEW_VERSION_FOUND) {
        ESP_ERROR_CHECK(nvs_flash_erase());
        ESP_ERROR_CHECK(nvs_flash_init());
    }

    ESP_ERROR_CHECK(hardware_init());
    ESP_ERROR_CHECK(pzem_sensor_init());
    ESP_ERROR_CHECK(wifi_manager_init());

    xTaskCreatePinnedToCore(
        wifi_manager_task,
        "Task_WiFi",
        TASK_WIFI_STACK,
        NULL,
        TASK_WIFI_PRIO,
        NULL,
        0);

    xTaskCreatePinnedToCore(
        hardware_test_task,
        "Task_Teste",
        TASK_TESTE_STACK,
        NULL,
        TASK_TESTE_PRIO,
        NULL,
        1);

    ESP_LOGI(TAG, "Tasks: Task_WiFi (core 0), Task_Teste (core 1)");
}
