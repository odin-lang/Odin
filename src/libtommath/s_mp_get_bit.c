#include "tommath_private.h"
#ifdef S_MP_GET_BIT_C

/* LibTomMath, multiple-precision integer library -- Tom St Denis */
/* SPDX-License-Identifier: Unlicense */

/* Get bit at position b and return true if the bit is 1, false if it is 0 */
bool s_mp_get_bit(const mp_int *a, int b)
{
   mp_digit bit;
   int limb = b / MP_DIGIT_BIT;

   if (limb < 0 || limb >= a->used) {
      return false;
   }

   bit = (mp_digit)1 << (b % MP_DIGIT_BIT);
   return ((a->dp[limb] & bit) != 0u);
}

#endif
