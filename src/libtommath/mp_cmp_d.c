#include "tommath_private.h"
#ifdef MP_CMP_D_C
/* LibTomMath, multiple-precision integer library -- Tom St Denis */
/* SPDX-License-Identifier: Unlicense */

/* compare a digit */
mp_ord mp_cmp_d(const mp_int *a, mp_digit b)
{
   /* compare based on sign */
   if (mp_isneg(a)) {
      return MP_LT;
   }

   /* compare based on magnitude */
   if (a->used > 1) {
      return MP_GT;
   }

   /* compare the only digit of a to b */
   if (a->dp[0] != b) {
      return a->dp[0] > b ? MP_GT : MP_LT;
   }

   return MP_EQ;
}
#endif
