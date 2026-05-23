/**
 * @file control.h
 * @brief Botão físico e relé SSR da bancada QA.
 */

#pragma once

#include <stdbool.h>

#ifdef __cplusplus
extern "C" {
#endif

void control_init(void);
void relay_set(bool state);
bool button_is_pressed(void);

#ifdef __cplusplus
}
#endif
