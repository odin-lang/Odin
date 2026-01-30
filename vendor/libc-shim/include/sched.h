#ifdef __cplusplus
extern "C" {
#endif

#pragma once

#include <stdint.h>

#define CLOCK_MONOTONIC 1

struct timespec
{
    int64_t tv_sec;
    int64_t tv_nsec;
};

int clock_gettime(int clockid, struct timespec *tp);

int sched_yield();

#ifdef __cplusplus
}
#endif
