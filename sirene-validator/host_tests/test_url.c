#include <stdio.h>
#include <string.h>

#include "pure_logic.h"

int test_url(void)
{
    if (!pure_ota_url_valid("http://192.168.1.10/firmware.bin")) {
        printf("test_url: valid http rejected\n");
        return 1;
    }
    if (!pure_ota_url_allowed("http://192.168.1.10/firmware.bin", NULL)) {
        printf("test_url: private LAN http rejected\n");
        return 1;
    }
    if (!pure_ota_url_allowed("https://ota.local/sirene-validator.bin", NULL)) {
        printf("test_url: .local https rejected\n");
        return 1;
    }
    if (pure_ota_url_allowed("https://example.com/sirene-validator.bin", NULL)) {
        printf("test_url: public host accepted\n");
        return 1;
    }
    if (pure_ota_url_allowed("https://evil.com/malware.bin", NULL)) {
        printf("test_url: evil host accepted\n");
        return 1;
    }
    if (!pure_ota_url_allowed("http://10.0.0.5/fw.bin", NULL)) {
        printf("test_url: 10.x host rejected\n");
        return 1;
    }
    if (!pure_ota_url_allowed("http://172.16.0.5/fw.bin", NULL)) {
        printf("test_url: 172.16 host rejected\n");
        return 1;
    }
    if (!pure_ota_url_allowed_ex("https://192.168.1.10/fw.bin", NULL, true)) {
        printf("test_url: https LAN rejected\n");
        return 1;
    }
    if (pure_ota_url_allowed_ex("http://192.168.1.10/fw.bin", NULL, true)) {
        printf("test_url: http accepted with require_https\n");
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
