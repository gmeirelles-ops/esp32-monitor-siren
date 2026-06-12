idf_component_register(
    SRCS "mqtt_config.c"
    INCLUDE_DIRS "include"
    REQUIRES nvs_flash board_config
)
