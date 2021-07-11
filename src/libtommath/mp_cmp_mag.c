#include "tommath_private.h"
#ifdef MP_CMP_MAG_C
/* LibTomMath, multiple-precision integer library -- Tom St Denis */
/* SPDX-License-Identifier: Unlicense */

/* compare maginitude of two ints (unsigned) */
mp_ord mp_cmp_mag(const mp_int *a, const mp_int *b)
{
   int n;

   /* compare based on # of non-zero digits */
   if (a->used != b->used) {
      return a->used > b->used ? MP_GT : MP_LT;
   }

   /* compare based on digits  */
   for (n = a->used; n --> 0;) {
      if (a->dp[n] != b->dp[n]) {
         return a->dp[n] > b->dp[n] ? MP_GT : MP_LT;
      }
   }

   return MP_EQ;
}
#endif
