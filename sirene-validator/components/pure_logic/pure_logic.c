#include "pure_logic.h"

#include <ctype.h>
#include <stdio.h>
#include <string.h>

bool pure_verdict_approved(float average_w, float potencia_min, float potencia_max)
{
    return average_w >= potencia_min && average_w <= potencia_max;
}

void pure_fifo_init(pure_fifo_t *fifo, uint32_t capacity)
{
    fifo->head = 0;
    fifo->tail = 0;
    fifo->count = 0;
    fifo->capacity = capacity;
}

bool pure_fifo_push(pure_fifo_t *fifo, bool *dropped_oldest)
{
    if (dropped_oldest) {
        *dropped_oldest = false;
    }
    if (fifo->count >= fifo->capacity) {
        if (dropped_oldest) {
            *dropped_oldest = true;
        }
        fifo->head = (fifo->head + 1) % fifo->capacity;
        fifo->count--;
    }
    fifo->tail = (fifo->tail + 1) % fifo->capacity;
    fifo->count++;
    return true;
}

bool pure_fifo_pop(pure_fifo_t *fifo)
{
    if (fifo->count == 0) {
        return false;
    }
    fifo->head = (fifo->head + 1) % fifo->capacity;
    fifo->count--;
    return true;
}

bool pure_fifo_is_full(const pure_fifo_t *fifo)
{
    return fifo->count >= fifo->capacity;
}

bool pure_fsm_can_start_test(pure_state_t state, bool pzem_fault, bool ota_active)
{
    return state == PURE_STATE_BATCH_READY && !pzem_fault && !ota_active;
}

bool pure_fsm_can_accept_batch(pure_state_t state, bool ota_active)
{
    return state != PURE_STATE_TESTING && !ota_active;
}

bool pure_fsm_can_accept_calibration(pure_state_t state, bool ota_active)
{
    return state == PURE_STATE_IDLE && !ota_active;
}

bool pure_fsm_can_accept_ota(pure_state_t state)
{
    return state != PURE_STATE_TESTING && state != PURE_STATE_OTA_UPDATING;
}

bool pure_batch_quota_reached(uint32_t aprovados, uint32_t quantidade_total)
{
    return quantidade_total > 0 && aprovados >= quantidade_total;
}

bool pure_batch_copy_str(char *dst, size_t dst_len, const char *src)
{
    if (!dst || dst_len == 0 || !src || src[0] == '\0') {
        return false;
    }
    snprintf(dst, dst_len, "%s", src);
    return true;
}

bool pure_batch_same_op(const char *a, const char *b)
{
    if (!a || !b) {
        return false;
    }
    return strcmp(a, b) == 0;
}

static bool pure_digits_fixed_len(const char *s, size_t len)
{
    if (!s || strlen(s) != len) {
        return false;
    }
    for (size_t i = 0; i < len; i++) {
        if (!isdigit((unsigned char)s[i])) {
            return false;
        }
    }
    return true;
}

bool pure_batch_fields_valid(const pure_batch_input_t *in)
{
    if (!in || in->numero_op[0] == '\0') {
        return false;
    }
    if (!pure_digits_fixed_len(in->id_produto, 3)) {
        return false;
    }
    if (!pure_digits_fixed_len(in->ano, 2)) {
        return false;
    }
    if (in->tempo_teste_sec == 0 || in->tempo_teste_sec > 120) {
        return false;
    }
    if (in->potencia_min < 0.0f || in->potencia_max < 0.0f) {
        return false;
    }
    if (in->potencia_min >= in->potencia_max) {
        return false;
    }
    if (in->quantidade_total == 0) {
        return false;
    }
    if (in->proximo_sequencial == 0) {
        return false;
    }
    return true;
}

bool pure_serial_body_valid(const char body[9])
{
    for (int i = 0; i < 9; i++) {
        if (!isdigit((unsigned char)body[i])) {
            return false;
        }
    }
    return true;
}

bool pure_ota_url_valid(const char *url)
{
    if (!url || url[0] == '\0') {
        return false;
    }
    if (strncmp(url, "http://", 7) == 0) {
        return url[7] != '\0';
    }
    if (strncmp(url, "https://", 8) == 0) {
        return url[8] != '\0';
    }
    return false;
}
