#include "batch_storage.h"

#include <string.h>

#include "board_config.h"
#include "esp_log.h"
#include "nvs.h"
#include "pure_logic.h"

static const char *TAG = "batch_nvs";
static const char *BATCH_BLOB_KEY = "blob_v1";

typedef struct __attribute__((packed)) {
    uint8_t active;
    char numero_op[16];
    char id_produto[4];
    char ano[3];
    uint32_t tempo_teste_sec;
    float potencia_min;
    float potencia_max;
    uint32_t quantidade_total;
    uint32_t proximo_sequencial;
    uint32_t aprovados;
    uint8_t modo_reteste;
} batch_nvs_blob_t;

static void batch_to_pure_input(const batch_context_t *ctx, pure_batch_input_t *in)
{
    memset(in, 0, sizeof(*in));
    strncpy(in->numero_op, ctx->numero_op, sizeof(in->numero_op) - 1);
    strncpy(in->id_produto, ctx->id_produto, sizeof(in->id_produto) - 1);
    strncpy(in->ano, ctx->ano, sizeof(in->ano) - 1);
    in->tempo_teste_sec = ctx->tempo_teste_sec;
    in->potencia_min = ctx->potencia_min;
    in->potencia_max = ctx->potencia_max;
    in->quantidade_total = ctx->quantidade_total;
    in->proximo_sequencial = ctx->proximo_sequencial;
}

static bool batch_context_valid(const batch_context_t *ctx)
{
    if (!ctx || !ctx->active) {
        return false;
    }
    pure_batch_input_t in;
    batch_to_pure_input(ctx, &in);
    if (!pure_batch_fields_valid(&in)) {
        return false;
    }
    if (ctx->aprovados > ctx->quantidade_total) {
        return false;
    }
    return true;
}

static void ctx_to_blob(const batch_context_t *ctx, batch_nvs_blob_t *blob)
{
    memset(blob, 0, sizeof(*blob));
    blob->active = ctx->active ? 1 : 0;
    strncpy(blob->numero_op, ctx->numero_op, sizeof(blob->numero_op) - 1);
    strncpy(blob->id_produto, ctx->id_produto, sizeof(blob->id_produto) - 1);
    strncpy(blob->ano, ctx->ano, sizeof(blob->ano) - 1);
    blob->tempo_teste_sec = ctx->tempo_teste_sec;
    blob->potencia_min = ctx->potencia_min;
    blob->potencia_max = ctx->potencia_max;
    blob->quantidade_total = ctx->quantidade_total;
    blob->proximo_sequencial = ctx->proximo_sequencial;
    blob->aprovados = ctx->aprovados;
    blob->modo_reteste = ctx->modo_reteste ? 1 : 0;
}

static void blob_to_ctx(const batch_nvs_blob_t *blob, batch_context_t *ctx)
{
    memset(ctx, 0, sizeof(*ctx));
    ctx->active = blob->active != 0;
    strncpy(ctx->numero_op, blob->numero_op, sizeof(ctx->numero_op) - 1);
    strncpy(ctx->id_produto, blob->id_produto, sizeof(ctx->id_produto) - 1);
    strncpy(ctx->ano, blob->ano, sizeof(ctx->ano) - 1);
    ctx->tempo_teste_sec = blob->tempo_teste_sec;
    ctx->potencia_min = blob->potencia_min;
    ctx->potencia_max = blob->potencia_max;
    ctx->quantidade_total = blob->quantidade_total;
    ctx->proximo_sequencial = blob->proximo_sequencial;
    ctx->aprovados = blob->aprovados;
    ctx->modo_reteste = blob->modo_reteste != 0;
}

bool batch_storage_save(const batch_context_t *ctx)
{
    if (!batch_context_valid(ctx)) {
        ESP_LOGE(TAG, "recusa salvar lote invalido");
        return false;
    }

    batch_nvs_blob_t blob;
    ctx_to_blob(ctx, &blob);

    nvs_handle_t handle;
    esp_err_t err = nvs_open(BATCH_NVS_NAMESPACE, NVS_READWRITE, &handle);
    if (err != ESP_OK) {
        ESP_LOGE(TAG, "nvs_open failed: %s", esp_err_to_name(err));
        return false;
    }

    err = nvs_set_blob(handle, BATCH_BLOB_KEY, &blob, sizeof(blob));
    if (err == ESP_OK) {
        err = nvs_commit(handle);
    }
    nvs_close(handle);
    if (err != ESP_OK) {
        ESP_LOGE(TAG, "nvs_commit failed: %s", esp_err_to_name(err));
    }
    return err == ESP_OK;
}

bool batch_storage_load(batch_context_t *ctx)
{
    memset(ctx, 0, sizeof(*ctx));
    nvs_handle_t handle;
    esp_err_t err = nvs_open(BATCH_NVS_NAMESPACE, NVS_READONLY, &handle);
    if (err != ESP_OK) {
        return false;
    }

    batch_nvs_blob_t blob;
    size_t blob_len = sizeof(blob);
    err = nvs_get_blob(handle, BATCH_BLOB_KEY, &blob, &blob_len);
    nvs_close(handle);
    if (err != ESP_OK || blob_len != sizeof(blob) || !blob.active) {
        return false;
    }

    blob_to_ctx(&blob, ctx);
    if (!batch_context_valid(ctx)) {
        ESP_LOGW(TAG, "lote NVS invalido — apagando");
        batch_storage_clear();
        memset(ctx, 0, sizeof(*ctx));
        return false;
    }
    return true;
}

void batch_storage_clear(void)
{
    nvs_handle_t handle;
    if (nvs_open(BATCH_NVS_NAMESPACE, NVS_READWRITE, &handle) == ESP_OK) {
        nvs_erase_all(handle);
        nvs_commit(handle);
        nvs_close(handle);
    }
}

bool batch_storage_has_active(void)
{
    batch_context_t ctx;
    return batch_storage_load(&ctx);
}
