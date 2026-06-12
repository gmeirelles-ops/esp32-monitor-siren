#include <stdio.h>
#include <string.h>

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

static pure_batch_input_t valid_batch(void)
{
    pure_batch_input_t in;
    memset(&in, 0, sizeof(in));
    strcpy(in.numero_op, "2026001");
    strcpy(in.id_produto, "123");
    strcpy(in.ano, "26");
    in.tempo_teste_sec = 5;
    in.potencia_min = 18.0f;
    in.potencia_max = 22.0f;
    in.quantidade_total = 10;
    in.proximo_sequencial = 1;
    return in;
}

int test_batch_validation(void)
{
    failures = 0;

    char buf[16];
    expect_true(pure_batch_copy_str(buf, sizeof(buf), "2026001"), "copy ok");
    expect_true(strcmp(buf, "2026001") == 0, "copy content");
    expect_false(pure_batch_copy_str(buf, sizeof(buf), ""), "copy empty");
    expect_true(pure_batch_copy_str(buf, sizeof(buf), "123456789012345"), "copy max len");
    expect_true(buf[15] == '\0', "copy null terminated at max");

    expect_true(pure_batch_same_op("2026001", "2026001"), "same op");
    expect_false(pure_batch_same_op("2026001", "2026002"), "different op");

    pure_batch_input_t in = valid_batch();
    expect_true(pure_batch_fields_valid(&in), "valid batch");

    in.potencia_min = 22.0f;
    in.potencia_max = 18.0f;
    expect_false(pure_batch_fields_valid(&in), "inverted power limits");

    in = valid_batch();
    in.tempo_teste_sec = 0;
    expect_false(pure_batch_fields_valid(&in), "zero tempo_teste");

    in = valid_batch();
    strcpy(in.id_produto, "12");
    expect_false(pure_batch_fields_valid(&in), "id_produto short");

    in = valid_batch();
    strcpy(in.ano, "2");
    expect_false(pure_batch_fields_valid(&in), "ano short");

    in = valid_batch();
    in.proximo_sequencial = 0;
    expect_false(pure_batch_fields_valid(&in), "sequencial zero");

    if (failures) {
        printf("test_batch_validation FAILED (%d)\n", failures);
        return 1;
    }
    return 0;
}
