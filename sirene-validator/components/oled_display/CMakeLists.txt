idf_component_register(
    SRCS "oled_display.c"
    INCLUDE_DIRS "include"
    REQUIRES board_config driver state_machine batch_storage mqtt_bridge wifi_prov
)
