idf_component_register(
    SRCS
        "main.c"
        "wifi_manager.c"
        "pzem_sensor.c"
    INCLUDE_DIRS "."
    REQUIRES
        nvs_flash
        esp_wifi
        esp_event
        esp_netif
        esp_http_client
        esp_http_server
        json
        driver
        lwip
)
