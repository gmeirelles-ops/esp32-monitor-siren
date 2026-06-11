#include <stdio.h>

#include "pure_logic.h"

int test_fsm(void)
{
    int failures = 0;
    if (!pure_fsm_can_start_test(PURE_STATE_BATCH_READY, false, false)) failures++;
    if (pure_fsm_can_start_test(PURE_STATE_TESTING, false, false)) failures++;
    if (pure_fsm_can_accept_ota(PURE_STATE_TESTING)) failures++;
    if (!pure_fsm_can_accept_ota(PURE_STATE_IDLE)) failures++;
    if (pure_fsm_can_accept_calibration(PURE_STATE_BATCH_READY, false)) failures++;
    if (failures) {
        printf("test_fsm FAILED\n");
    }
    return failures > 0;
}
