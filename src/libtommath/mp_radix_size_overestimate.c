#include "tommath_private.h"
#ifdef MP_RADIX_SIZE_OVERESTIMATE_C
/* LibTomMath, multiple-precision integer library -- Tom St Denis */
/* SPDX-License-Identifier: Unlicense */

mp_err mp_radix_size_overestimate(const mp_int *a, const int radix, size_t *size)
{
   if (MP_HAS(S_MP_RADIX_SIZE_OVERESTIMATE)) {
      return s_mp_radix_size_overestimate(a, radix, size);
   }
   if (MP_HAS(MP_RADIX_SIZE)) {
      return mp_radix_size(a, radix, size);
   }
   return MP_ERR;
}

#endif
