idf_component_register(
    SRCS "wifi_prov.c"
    INCLUDE_DIRS "include"
    REQUIRES esp_wifi esp_http_server esp_netif nvs_flash board_config mqtt_config
)
