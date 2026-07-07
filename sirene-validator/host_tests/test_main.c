#include <stdio.h>

int test_verdict(void);
int test_fifo(void);
int test_fsm(void);
int test_serial(void);
int test_url(void);
int test_batch_quota(void);
int test_batch_validation(void);
int test_batch_retest(void);
int test_ensaio(void);

int test_site(void);
int test_host_lan(void);

int main(void)
{
    int failures = 0;
    failures += test_verdict();
    failures += test_fifo();
    failures += test_fsm();
    failures += test_serial();
    failures += test_url();
    failures += test_batch_quota();
    failures += test_batch_validation();
    failures += test_batch_retest();
    failures += test_ensaio();
    failures += test_site();
    failures += test_host_lan();
    if (failures == 0) {
        printf("ALL TESTS PASSED\n");
        return 0;
    }
    printf("%d TEST(S) FAILED\n", failures);
    return 1;
}
