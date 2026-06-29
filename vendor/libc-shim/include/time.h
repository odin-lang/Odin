#ifdef __cplusplus
extern "C" {
#endif

#pragma once

#include <stdint.h>

typedef int64_t clock_t;
typedef clock_t time_t;

clock_t clock();

#ifdef __cplusplus
}
#endif
