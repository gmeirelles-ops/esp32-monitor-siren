idf_component_register(
    SRCS "offline_queue.c"
    INCLUDE_DIRS "include"
    REQUIRES nvs_flash spiffs board_config
)
