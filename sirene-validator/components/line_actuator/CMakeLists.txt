idf_component_register(
    SRCS "line_actuator.c"
    INCLUDE_DIRS "include"
    REQUIRES esp_driver_gpio esp_timer board_config
)
