#include "tommath_private.h"
#ifdef S_MP_LOG_D_C
/* LibTomMath, multiple-precision integer library -- Tom St Denis */
/* SPDX-License-Identifier: Unlicense */

static mp_word s_pow(mp_word base, mp_word exponent)
{
   mp_word result = 1u;
   while (exponent != 0u) {
      if ((exponent & 1u) == 1u) {
         result *= base;
      }
      exponent >>= 1;
      base *= base;
   }

   return result;
}

int s_mp_log_d(mp_digit base, mp_digit n)
{
   mp_word bracket_low = 1uLL, bracket_high = base, N = n;
   int ret, high = 1, low = 0;

   if (n < base) {
      return 0;
   }
   if (n == base) {
      return 1;
   }

   while (bracket_high < N) {
      low = high;
      bracket_low = bracket_high;
      high <<= 1;
      bracket_high *= bracket_high;
   }

   while (((mp_digit)(high - low)) > 1uL) {
      int mid = (low + high) >> 1;
      mp_word bracket_mid = bracket_low * s_pow(base, (mp_word)(mid - low));

      if (N < bracket_mid) {
         high = mid ;
         bracket_high = bracket_mid ;
      }
      if (N > bracket_mid) {
         low = mid ;
         bracket_low = bracket_mid ;
      }
      if (N == bracket_mid) {
         return mid;
      }
   }

   if (bracket_high == N) {
      ret = high;
   } else {
      ret = low;
   }

   return ret;
}

#endif
