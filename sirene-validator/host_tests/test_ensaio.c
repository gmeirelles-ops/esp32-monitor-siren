#include <stdio.h>

#include "pure_logic.h"

static int failures;

static void expect_true(bool v, const char *msg)
{
    if (!v) {
        printf("  FAIL: %s\n", msg);
        failures++;
    }
}

static void expect_false(bool v, const char *msg)
{
    expect_true(!v, msg);
}

int test_ensaio(void)
{
    failures = 0;

    expect_true(pure_ensaio_params_valid(30, 15, 7200), "valid 30/15/7200");
    expect_true(pure_ensaio_params_valid(1, 1, 10), "min valid");
    expect_true(pure_ensaio_params_valid(600, 600, 28800), "max valid");

    expect_false(pure_ensaio_params_valid(0, 15, 7200), "on zero");
    expect_false(pure_ensaio_params_valid(30, 0, 7200), "off zero");
    expect_false(pure_ensaio_params_valid(30, 15, 9), "total too short");
    expect_false(pure_ensaio_params_valid(30, 15, 28801), "total too long");
    expect_false(pure_ensaio_params_valid(601, 15, 7200), "on too long");
    expect_false(pure_ensaio_params_valid(30, 601, 7200), "off too long");
    expect_false(pure_ensaio_params_valid(30, 15, 40), "on+off > total");

    if (failures) {
        printf("test_ensaio FAILED (%d)\n", failures);
        return 1;
    }
    return 0;
}
