#include <stdio.h>

#include "pure_logic.h"

int test_batch_cooldown(void)
{
    int failures = 0;
    const uint32_t cd = 5000;

    if (!pure_batch_blocks_repeat_after_approval(false, true, true, 1000, 3000, cd)) {
        failures++;
    }
    if (pure_batch_blocks_repeat_after_approval(false, true, true, 1000, 6000, cd)) {
        failures++;
    }
    if (pure_batch_blocks_repeat_after_approval(true, true, true, 1000, 2000, cd)) {
        failures++;
    }
    if (pure_batch_blocks_repeat_after_approval(false, true, false, 1000, 2000, cd)) {
        failures++;
    }
    if (pure_batch_blocks_repeat_after_approval(false, false, true, 1000, 2000, cd)) {
        failures++;
    }

    if (failures) {
        printf("test_batch_cooldown FAILED (%d)\n", failures);
    }
    return failures > 0;
}
