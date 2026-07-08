idf_component_register(
    SRCS "main.c" "app_runtime.c" "batch_cmd.c" "calibration.c" "ensaio.c" "mqtt_cmd.c"
    INCLUDE_DIRS "."
    REQUIRES nvs_flash board_config device_id relay button led_feedback state_machine line_actuator
             batch_storage pzem wifi_prov mqtt_bridge offline_queue cjson
             ota_update telemetry pure_logic time_sync mqtt_topics mqtt_config
             oled_display
)
