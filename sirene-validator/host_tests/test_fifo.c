#include <stdio.h>

#include "pure_logic.h"

int test_fifo(void)
{
    pure_fifo_t fifo;
    pure_fifo_init(&fifo, 2);
    bool dropped = false;
    pure_fifo_push(&fifo, &dropped);
    pure_fifo_push(&fifo, &dropped);
    if (!pure_fifo_is_full(&fifo)) {
        printf("test_fifo: expected full\n");
        return 1;
    }
    pure_fifo_push(&fifo, &dropped);
    if (!dropped) {
        printf("test_fifo: expected drop on overflow\n");
        return 1;
    }
    pure_fifo_pop(&fifo);
    if (fifo.count != 1) {
        printf("test_fifo: pop failed\n");
        return 1;
    }
    return 0;
}
