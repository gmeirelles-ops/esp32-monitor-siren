idf_component_register(
    SRCS "mqtt_bridge.c"
    INCLUDE_DIRS "include"
    REQUIRES mqtt device_id board_config mqtt_config
)
