#pragma once

#include <stdio.h>

#ifndef PRIx64
#define PRIx64 "llx"
#endif

#ifndef PRIu64
#define PRIu64 "llu"
#endif

int fscanf(FILE* restrict stream, const char* restrict format, ...);
