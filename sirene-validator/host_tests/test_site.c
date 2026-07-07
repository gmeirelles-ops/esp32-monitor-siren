#include <stdio.h>

#include "pure_logic.h"

int test_site(void)
{
    if (!pure_site_name_valid("producao")) {
        printf("test_site: producao rejected\n");
        return 1;
    }
    if (!pure_site_name_valid("site_1")) {
        printf("test_site: underscore rejected\n");
        return 1;
    }
    if (pure_site_name_valid("foo/bar")) {
        printf("test_site: slash accepted\n");
        return 1;
    }
    if (pure_site_name_valid("")) {
        printf("test_site: empty accepted\n");
        return 1;
    }
    return 0;
}
