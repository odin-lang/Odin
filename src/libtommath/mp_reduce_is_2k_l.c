#include "tommath_private.h"
#ifdef MP_REDUCE_IS_2K_L_C
/* LibTomMath, multiple-precision integer library -- Tom St Denis */
/* SPDX-License-Identifier: Unlicense */

/* determines if reduce_2k_l can be used */
bool mp_reduce_is_2k_l(const mp_int *a)
{
   if (mp_iszero(a)) {
      return false;
   } else if (a->used == 1) {
      return true;
   } else if (a->used > 1) {
      /* if more than half of the digits are -1 we're sold */
      int ix, iy;
      for (iy = ix = 0; ix < a->used; ix++) {
         if (a->dp[ix] == MP_DIGIT_MAX) {
            ++iy;
         }
      }
      return (iy >= (a->used/2));
   } else {
      return false;
   }
}

#endif
