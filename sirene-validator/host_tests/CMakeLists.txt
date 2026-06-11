cmake_minimum_required(VERSION 3.16)
project(sirene_host_tests C)

set(CMAKE_C_STANDARD 11)

add_library(pure_logic STATIC
    ../components/pure_logic/pure_logic.c
)
target_include_directories(pure_logic PUBLIC ../components/pure_logic/include)

add_executable(host_tests
    test_main.c
    test_verdict.c
    test_fifo.c
    test_fsm.c
    test_serial.c
    test_url.c
    test_batch_quota.c
)
target_include_directories(host_tests PRIVATE .)
target_link_libraries(host_tests pure_logic m)

enable_testing()
add_test(NAME host_tests COMMAND host_tests)
