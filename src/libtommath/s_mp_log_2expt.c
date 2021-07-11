#include "tommath_private.h"
#ifdef S_MP_LOG_2EXPT_C
/* LibTomMath, multiple-precision integer library -- Tom St Denis */
/* SPDX-License-Identifier: Unlicense */

int s_mp_log_2expt(const mp_int *a, mp_digit base)
{
   int y;
   for (y = 0; (base & 1) == 0; y++, base >>= 1) {}
   return (mp_count_bits(a) - 1) / y;
}
#endif
