idf_component_register(
    SRCS "pzem.c"
    INCLUDE_DIRS "include"
    REQUIRES esp_driver_uart board_config esp_system
)
