#pragma once

#include <stdbool.h>
#include <stdint.h>

typedef void (*pzem_fault_cb_t)(bool fault);

bool pzem_init(pzem_fault_cb_t fault_cb);
bool pzem_read_power_w(float *power_w);
bool pzem_read_active_power_w(float *power_w);
bool pzem_probe_read(float *power_w);
bool pzem_boot_self_test(void);
bool pzem_is_fault(void);
void pzem_mark_fault(void);
void pzem_clear_fault(void);
uint8_t pzem_get_slave_addr(void);
uint32_t pzem_get_fault_count(void);

typedef struct {
    float average_w;
    float max_w;
    uint32_t sample_count;
    bool uart_error;
} pzem_cycle_result_t;

typedef void (*pzem_sample_cb_t)(float power_w, uint32_t elapsed_ms, void *ctx);

bool pzem_measure_cycle(uint32_t duration_sec, uint32_t inrush_discard_ms, pzem_cycle_result_t *out,
                        pzem_sample_cb_t sample_cb, void *sample_ctx);
