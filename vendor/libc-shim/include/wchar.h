#ifdef __cplusplus
extern "C" {
#endif

#pragma once

#include <stddef.h>

typedef struct { unsigned int __state; } mbstate_t;

size_t wcslen(const wchar_t *);

// "C" locale only: code points above 0x7F fail with EILSEQ.
size_t wcsrtombs(char *, const wchar_t **, size_t, mbstate_t *);

#ifdef __cplusplus
}
#endif
