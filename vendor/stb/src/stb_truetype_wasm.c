#include <stddef.h>

void *stbtt_malloc(size_t size);
void stbtt_free(void *ptr);

void stbtt_qsort(void* base, size_t num, size_t size, int (*compare)(const void*, const void*));

double stbtt_floor(double x);
double stbtt_ceil(double x);
double stbtt_sqrt(double x);
double stbtt_pow(double x, double y);
double stbtt_fmod(double x, double y);
double stbtt_cos(double x);
double stbtt_acos(double x);
double stbtt_fabs(double x);

unsigned long stbtt_strlen(const char *str);

void *memcpy(void *dst, const void *src, size_t count);
void *memset(void *dst, int x, size_t count);

#define STBRP_SORT stbtt_qsort
#define STBRP_ASSERT(condition) ((void)0)

#define STBTT_malloc(x,u)  ((void)(u),stbtt_malloc(x))
#define STBTT_free(x,u)    ((void)(u),stbtt_free(x))

#define STBTT_assert(condition) ((void)0)

#define STBTT_ifloor(x)   ((int) stbtt_floor(x))
#define STBTT_iceil(x)    ((int) stbtt_ceil(x))
#define STBTT_sqrt(x)      stbtt_sqrt(x)
#define STBTT_pow(x,y)     stbtt_pow(x,y)
#define STBTT_fmod(x,y)    stbtt_fmod(x,y)
#define STBTT_cos(x)       stbtt_cos(x)
#define STBTT_acos(x)      stbtt_acos(x)
#define STBTT_fabs(x)      stbtt_fabs(x)
#define STBTT_strlen(x)    stbtt_strlen(x)
#define STBTT_memcpy       memcpy
#define STBTT_memset       memset

#define STB_RECT_PACK_IMPLEMENTATION
#include "stb_rect_pack.h"

#define STB_TRUETYPE_IMPLEMENTATION
#include "stb_truetype.h"
