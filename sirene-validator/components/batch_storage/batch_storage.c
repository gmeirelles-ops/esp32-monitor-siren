#include "batch_storage.h"

#include <string.h>

#include "board_config.h"
#include "esp_log.h"
#include "nvs.h"
#include "nvs_flash.h"

static const char *TAG = "batch_nvs";

bool batch_storage_save(const batch_context_t *ctx)
{
    nvs_handle_t handle;
    esp_err_t err = nvs_open(BATCH_NVS_NAMESPACE, NVS_READWRITE, &handle);
    if (err != ESP_OK) {
        ESP_LOGE(TAG, "nvs_open failed: %s", esp_err_to_name(err));
        return false;
    }

    nvs_set_u8(handle, "active", ctx->active ? 1 : 0);
    nvs_set_str(handle, "numero_op", ctx->numero_op);
    nvs_set_str(handle, "id_produto", ctx->id_produto);
    nvs_set_str(handle, "ano", ctx->ano);
    nvs_set_u32(handle, "tempo_teste", ctx->tempo_teste_sec);
    nvs_set_blob(handle, "pot_min", &ctx->potencia_min, sizeof(float));
    nvs_set_blob(handle, "pot_max", &ctx->potencia_max, sizeof(float));
    nvs_set_u32(handle, "qtd_total", ctx->quantidade_total);
    nvs_set_u32(handle, "sequencial", ctx->proximo_sequencial);
    nvs_set_u32(handle, "aprovados", ctx->aprovados);
    nvs_set_u8(handle, "modo_reteste", ctx->modo_reteste ? 1 : 0);
    err = nvs_commit(handle);
    nvs_close(handle);
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

    uint8_t active = 0;
    if (nvs_get_u8(handle, "active", &active) != ESP_OK || !active) {
        nvs_close(handle);
        return false;
    }

    size_t len = sizeof(ctx->numero_op);
    nvs_get_str(handle, "numero_op", ctx->numero_op, &len);
    len = sizeof(ctx->id_produto);
    nvs_get_str(handle, "id_produto", ctx->id_produto, &len);
    len = sizeof(ctx->ano);
    nvs_get_str(handle, "ano", ctx->ano, &len);
    nvs_get_u32(handle, "tempo_teste", &ctx->tempo_teste_sec);
    size_t blob_len = sizeof(float);
    nvs_get_blob(handle, "pot_min", &ctx->potencia_min, &blob_len);
    blob_len = sizeof(float);
    nvs_get_blob(handle, "pot_max", &ctx->potencia_max, &blob_len);
    nvs_get_u32(handle, "qtd_total", &ctx->quantidade_total);
    nvs_get_u32(handle, "sequencial", &ctx->proximo_sequencial);
    nvs_get_u32(handle, "aprovados", &ctx->aprovados);
    uint8_t modo_reteste = 0;
    if (nvs_get_u8(handle, "modo_reteste", &modo_reteste) == ESP_OK) {
        ctx->modo_reteste = modo_reteste != 0;
    }
    ctx->active = true;
    nvs_close(handle);
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
