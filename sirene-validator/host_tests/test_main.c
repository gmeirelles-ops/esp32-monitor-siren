#include <stdio.h>

int test_verdict(void);
int test_fifo(void);
int test_fsm(void);
int test_serial(void);
int test_url(void);
int test_batch_quota(void);

int main(void)
{
    int failures = 0;
    failures += test_verdict();
    failures += test_fifo();
    failures += test_fsm();
    failures += test_serial();
    failures += test_url();
    failures += test_batch_quota();
    if (failures == 0) {
        printf("ALL TESTS PASSED\n");
        return 0;
    }
    printf("%d TEST(S) FAILED\n", failures);
    return 1;
}
