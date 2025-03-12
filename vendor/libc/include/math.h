#ifdef __cplusplus
extern "C" {
#endif

#pragma once

#include <stdbool.h>

#define INFINITY (1.0 / 0.0)
#define NAN      (0.0 / 0.0)

float sqrtf(float);
float cosf(float);
float sinf(float);
float atan2f(float, float);

float floorf(float x);
double floor(double x);
float ceilf(float x);
double ceil(double x);
double sqrt(double x);
float powf(float x, float y);
double pow(double x, double y);
float fmodf(float x, float y);
double fmod(double x, double y);
double cos(double x);
float acosf(float x);
double acos(double x);
float fabsf(float x);
double fabs(double x);
int abs(int);
double ldexp(double, int);
double exp(double);
float logf(float);
double log(double);
double sin(double);
double trunc(double);
double log2(double);
double log10(double);
double asin(double);
double atan(double);
double tan(double);
double atan2(double, double);
double modf(double, double*);

bool __isnanf(float);
bool __isnand(double);
#define isnan(x)                                           \
    ( sizeof(x) == sizeof(float)  ? __isnanf((float)(x))   \
    :                             : __isnand((double)(x)))

bool __isinff(float);
bool __isinfd(double);
#define isinf(x)                                           \
    ( sizeof(x) == sizeof(float)  ? __isinff((float)(x))   \
    :                             : __isinfd((double)(x)))

bool __isfinitef(float);
bool __isfinited(double);
#define isfinite(x)                                           \
    ( sizeof(x) == sizeof(float)  ? __isfinitef((float)(x))   \
    :                             : __isfinited((double)(x)))

#ifdef __cplusplus
}
#endif
