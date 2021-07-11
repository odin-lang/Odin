#include "tommath_private.h"
#ifdef MP_LOG_N_C
/* LibTomMath, multiple-precision integer library -- Tom St Denis */
/* SPDX-License-Identifier: Unlicense */

mp_err mp_log_n(const mp_int *a, int base, int *c)
{
   if (mp_isneg(a) || mp_iszero(a) || (base < 2) || (unsigned)base > (unsigned)MP_DIGIT_MAX) {
      return MP_VAL;
   }

   if (MP_HAS(S_MP_LOG_2EXPT) && MP_IS_2EXPT((mp_digit)base)) {
      *c = s_mp_log_2expt(a, (mp_digit)base);
      return MP_OKAY;
   }

   if (MP_HAS(S_MP_LOG_D) && (a->used == 1)) {
      *c = s_mp_log_d((mp_digit)base, a->dp[0]);
      return MP_OKAY;
   }

   if (MP_HAS(S_MP_LOG)) {
      return s_mp_log(a, (mp_digit)base, c);
   }

   return MP_VAL;
}

#endif
