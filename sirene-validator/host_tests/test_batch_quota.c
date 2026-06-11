#include <stdio.h>

#include "pure_logic.h"

int test_batch_quota(void)
{
    int failures = 0;
    if (!pure_batch_quota_reached(10, 10)) failures++;
    if (pure_batch_quota_reached(9, 10)) failures++;
    if (pure_batch_quota_reached(0, 0)) failures++;
    if (!pure_batch_quota_reached(5, 5)) failures++;
    if (failures) {
        printf("test_batch_quota FAILED\n");
    }
    return failures > 0;
}
