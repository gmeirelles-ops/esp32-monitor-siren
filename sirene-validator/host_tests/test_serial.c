#include <stdio.h>
#include <string.h>

#include "pure_logic.h"

int test_serial(void)
{
    char body[10] = "123260019";
    if (!pure_serial_body_valid(body)) {
        printf("test_serial: valid body rejected\n");
        return 1;
    }
    body[3] = 'X';
    if (pure_serial_body_valid(body)) {
        printf("test_serial: invalid body accepted\n");
        return 1;
    }
    if (strlen(body) != 9) {
        printf("test_serial: unexpected length\n");
        return 1;
    }
    return 0;
}
