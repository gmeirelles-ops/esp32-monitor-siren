#include <stdio.h>
#include <string.h>

#include "pure_logic.h"

int test_url(void)
{
    if (!pure_ota_url_valid("http://192.168.1.10/firmware.bin")) {
        printf("test_url: valid http rejected\n");
        return 1;
    }
    if (!pure_ota_url_valid("https://example.com/sirene-validator.bin")) {
        printf("test_url: valid https rejected\n");
        return 1;
    }
    if (pure_ota_url_valid("ftp://bad/file.bin")) {
        printf("test_url: ftp accepted\n");
        return 1;
    }
    if (pure_ota_url_valid("http://")) {
        printf("test_url: empty path accepted\n");
        return 1;
    }
    if (pure_ota_url_valid(NULL) || pure_ota_url_valid("")) {
        printf("test_url: empty url accepted\n");
        return 1;
    }
    return 0;
}
