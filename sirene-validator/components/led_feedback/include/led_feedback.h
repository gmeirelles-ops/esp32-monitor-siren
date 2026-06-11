#pragma once

typedef enum {
    FEEDBACK_NONE = 0,
    FEEDBACK_APPROVED,
    FEEDBACK_REJECTED,
    FEEDBACK_FAULT,
    FEEDBACK_QUEUE_FULL,
} feedback_signal_t;

void led_feedback_init(void);
void led_feedback_signal(feedback_signal_t signal);
