#include <stdio.h>

#include "pure_logic.h"

int test_verdict(void)
{
    int failures = 0;
    if (!pure_verdict_approved(20.0f, 18.0f, 22.0f)) failures++;
    if (pure_verdict_approved(17.9f, 18.0f, 22.0f)) failures++;
    if (pure_verdict_approved(22.1f, 18.0f, 22.0f)) failures++;
    if (failures) {
        printf("test_verdict FAILED\n");
    }
    return failures > 0;
}
