#include "tommath_private.h"
#ifdef MP_RADIX_SIZE_C
/* LibTomMath, multiple-precision integer library -- Tom St Denis */
/* SPDX-License-Identifier: Unlicense */

/* returns size of ASCII representation */
mp_err mp_radix_size(const mp_int *a, int radix, size_t *size)
{
   mp_err err;
   mp_int a_;
   int b;

   /* make sure the radix is in range */
   if ((radix < 2) || (radix > 64)) {
      return MP_VAL;
   }

   if (mp_iszero(a)) {
      *size = 2;
      return MP_OKAY;
   }

   a_ = *a;
   a_.sign = MP_ZPOS;
   if ((err = mp_log_n(&a_, radix, &b)) != MP_OKAY) {
      return err;
   }

   /* mp_ilogb truncates to zero, hence we need one extra put on top and one for `\0`. */
   *size = (size_t)b + 2U + (mp_isneg(a) ? 1U : 0U);

   return MP_OKAY;
}
#endif
