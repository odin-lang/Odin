#include "tommath_private.h"
#ifdef MP_CNT_LSB_C
/* LibTomMath, multiple-precision integer library -- Tom St Denis */
/* SPDX-License-Identifier: Unlicense */

static const char lnz[16] = {
   4, 0, 1, 0, 2, 0, 1, 0, 3, 0, 1, 0, 2, 0, 1, 0
};

/* Counts the number of lsbs which are zero before the first zero bit */
int mp_cnt_lsb(const mp_int *a)
{
   int x;
   mp_digit q;

   /* easy out */
   if (mp_iszero(a)) {
      return 0;
   }

   /* scan lower digits until non-zero */
   for (x = 0; (x < a->used) && (a->dp[x] == 0u); x++) {}
   q = a->dp[x];
   x *= MP_DIGIT_BIT;

   /* now scan this digit until a 1 is found */
   if ((q & 1u) == 0u) {
      mp_digit p;
      do {
         p = q & 15u;
         x += lnz[p];
         q >>= 4;
      } while (p == 0u);
   }
   return x;
}

#endif
