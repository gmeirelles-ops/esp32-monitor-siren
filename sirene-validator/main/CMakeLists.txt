idf_component_register(
    SRCS "main.c"
    INCLUDE_DIRS "."
    REQUIRES nvs_flash board_config device_id relay button led_feedback state_machine
             batch_storage pzem wifi_prov mqtt_bridge offline_queue cjson
             ota_update telemetry pure_logic
)
