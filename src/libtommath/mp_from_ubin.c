#include "tommath_private.h"
#ifdef MP_FROM_UBIN_C
/* LibTomMath, multiple-precision integer library -- Tom St Denis */
/* SPDX-License-Identifier: Unlicense */

/* reads a uint8_t array, assumes the msb is stored first [big endian] */
mp_err mp_from_ubin(mp_int *a, const uint8_t *buf, size_t size)
{
   mp_err err;

   /* make sure there are at least two digits */
   if ((err = mp_grow(a, 2)) != MP_OKAY) {
      return err;
   }

   /* zero the int */
   mp_zero(a);

   /* read the bytes in */
   while (size-- > 0u) {
      if ((err = mp_mul_2d(a, 8, a)) != MP_OKAY) {
         return err;
      }
      a->dp[0] |= *buf++;
      a->used += 1;
   }
   mp_clamp(a);
   return MP_OKAY;
}
#endif
