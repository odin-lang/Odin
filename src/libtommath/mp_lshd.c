#include "tommath_private.h"
#ifdef MP_LSHD_C
/* LibTomMath, multiple-precision integer library -- Tom St Denis */
/* SPDX-License-Identifier: Unlicense */

/* shift left a certain amount of digits */
mp_err mp_lshd(mp_int *a, int b)
{
   mp_err err;
   int x;

   /* if its less than zero return */
   if (b <= 0) {
      return MP_OKAY;
   }
   /* no need to shift 0 around */
   if (mp_iszero(a)) {
      return MP_OKAY;
   }

   /* grow to fit the new digits */
   if ((err = mp_grow(a, a->used + b)) != MP_OKAY) {
      return err;
   }

   /* increment the used by the shift amount then copy upwards */
   a->used += b;

   /* much like mp_rshd this is implemented using a sliding window
    * except the window goes the otherway around.  Copying from
    * the bottom to the top.  see mp_rshd.c for more info.
    */
   for (x = a->used; x --> b;) {
      a->dp[x] = a->dp[x - b];
   }

   /* zero the lower digits */
   s_mp_zero_digs(a->dp, b);

   return MP_OKAY;
}
#endif
