idf_component_register(
    SRCS "batch_storage.c"
    INCLUDE_DIRS "include"
    REQUIRES nvs_flash board_config
)
