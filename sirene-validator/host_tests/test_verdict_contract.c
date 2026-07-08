#include <stdio.h>

#include "pure_logic.h"

/**
 * Contract 004: pure_logic computes verdict only; firmware batch_cmd_apply_verdict
 * MUST drive GPIO/actuator before MQTT. This test documents that split — order
 * is not testable in host_tests without ESP-IDF mocks.
 */
int test_verdict_contract(void)
{
    /* Verdict in range → approved (GPIO order enforced in batch_cmd.c, not here). */
    if (!pure_verdict_approved(20.0f, 18.0f, 22.0f)) {
        printf("test_verdict_contract FAILED: expected approved in range\n");
        return 1;
    }
    if (pure_verdict_approved(10.0f, 18.0f, 22.0f)) {
        printf("test_verdict_contract FAILED: expected rejected below min\n");
        return 1;
    }
    return 0;
}
