set(SRCS
    "src/main.c"
    "src/control.c"
    "src/comm.c"
    "src/pzem_sensor.c"
    "src/wifi_manager.c"
    "src/firebase.c"
    # "src/hardware.c"  # legado (GPIO4 + API antiga PZEM) – não linkar com FSM atual
)

idf_component_register(
    SRCS ${SRCS}
    INCLUDE_DIRS "inc"
    REQUIRES
        nvs_flash
        esp_wifi
        esp_event
        esp_netif
        esp_http_client
        esp_http_server
        mqtt
        json
        driver
        lwip
    PRIV_REQUIRES
        pzem004t
)
