#pragma once

#include <stdbool.h>
#include <stdint.h>

typedef struct {
    bool active;
    char numero_op[16];
    char id_produto[4];
    char ano[3];
    uint32_t tempo_teste_sec;
    float potencia_min;
    float potencia_max;
    uint32_t quantidade_total;
    uint32_t proximo_sequencial;
    uint32_t aprovados;
} batch_context_t;

bool batch_storage_save(const batch_context_t *ctx);
bool batch_storage_load(batch_context_t *ctx);
void batch_storage_clear(void);
bool batch_storage_has_active(void);
