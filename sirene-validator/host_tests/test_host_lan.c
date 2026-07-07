#include <stdio.h>

#include "pure_logic.h"

int test_host_lan(void)
{
    if (!pure_host_is_private_lan("192.168.1.1")) {
        printf("test_host_lan: 192.168 rejected\n");
        return 1;
    }
    if (!pure_host_is_private_lan("10.0.0.1")) {
        printf("test_host_lan: 10.x rejected\n");
        return 1;
    }
    if (!pure_host_is_private_lan("172.16.5.1")) {
        printf("test_host_lan: 172.16 rejected\n");
        return 1;
    }
    if (pure_host_is_private_lan("172.32.0.1")) {
        printf("test_host_lan: 172.32 accepted\n");
        return 1;
    }
    if (pure_host_is_private_lan("mqtt.diponto.com")) {
        printf("test_host_lan: public host accepted\n");
        return 1;
    }
    return 0;
}
