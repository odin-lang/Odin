#include "tommath_private.h"
#ifdef MP_RSHD_C
/* LibTomMath, multiple-precision integer library -- Tom St Denis */
/* SPDX-License-Identifier: Unlicense */

/* shift right a certain amount of digits */
void mp_rshd(mp_int *a, int b)
{
   int x;

   /* if b <= 0 then ignore it */
   if (b <= 0) {
      return;
   }

   /* if b > used then simply zero it and return */
   if (a->used <= b) {
      mp_zero(a);
      return;
   }

   /* shift the digits down.
    * this is implemented as a sliding window where
    * the window is b-digits long and digits from
    * the top of the window are copied to the bottom
    *
    * e.g.

    b-2 | b-1 | b0 | b1 | b2 | ... | bb |   ---->
                /\                   |      ---->
                 \-------------------/      ---->
    */
   for (x = 0; x < (a->used - b); x++) {
      a->dp[x] = a->dp[x + b];
   }

   /* zero the top digits */
   s_mp_zero_digs(a->dp + a->used - b, b);

   /* remove excess digits */
   a->used -= b;
}
#endif
