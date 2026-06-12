idf_component_register(
    SRCS "led_feedback.c"
    INCLUDE_DIRS "include"
    REQUIRES esp_driver_gpio board_config
)
