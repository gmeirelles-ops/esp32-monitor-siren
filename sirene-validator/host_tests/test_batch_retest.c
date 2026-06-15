#include <stdio.h>

#include "pure_logic.h"

int test_batch_retest(void)
{
    int failures = 0;
    if (!pure_batch_approval_updates_counters(false, true)) failures++;
    if (pure_batch_approval_updates_counters(true, true)) failures++;
    if (pure_batch_approval_updates_counters(false, false)) failures++;
    if (pure_batch_approval_updates_counters(true, false)) failures++;
    if (failures) {
        printf("test_batch_retest FAILED\n");
    }
    return failures > 0;
}
