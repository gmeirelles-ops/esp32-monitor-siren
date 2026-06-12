#pragma once

#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>

typedef enum {
    PURE_STATE_PROVISIONING = 0,
    PURE_STATE_IDLE,
    PURE_STATE_BATCH_READY,
    PURE_STATE_TESTING,
    PURE_STATE_HARDWARE_FAULT,
    PURE_STATE_OTA_UPDATING,
} pure_state_t;

bool pure_verdict_approved(float average_w, float potencia_min, float potencia_max);

typedef struct {
    uint32_t head;
    uint32_t tail;
    uint32_t count;
    uint32_t capacity;
} pure_fifo_t;

void pure_fifo_init(pure_fifo_t *fifo, uint32_t capacity);
bool pure_fifo_push(pure_fifo_t *fifo, bool *dropped_oldest);
bool pure_fifo_pop(pure_fifo_t *fifo);
bool pure_fifo_is_full(const pure_fifo_t *fifo);

bool pure_fsm_can_start_test(pure_state_t state, bool pzem_fault, bool ota_active);
bool pure_fsm_can_accept_batch(pure_state_t state, bool ota_active);
bool pure_fsm_can_accept_calibration(pure_state_t state, bool ota_active);
bool pure_fsm_can_accept_ota(pure_state_t state);

bool pure_batch_quota_reached(uint32_t aprovados, uint32_t quantidade_total);

typedef struct {
    char numero_op[16];
    char id_produto[4];
    char ano[3];
    uint32_t tempo_teste_sec;
    float potencia_min;
    float potencia_max;
    uint32_t quantidade_total;
    uint32_t proximo_sequencial;
} pure_batch_input_t;

bool pure_batch_copy_str(char *dst, size_t dst_len, const char *src);
bool pure_batch_same_op(const char *a, const char *b);
bool pure_batch_fields_valid(const pure_batch_input_t *in);

bool pure_serial_body_valid(const char body[9]);

bool pure_ota_url_valid(const char *url);
