#include "tommath_private.h"
#ifdef MP_REDUCE_2K_SETUP_C
/* LibTomMath, multiple-precision integer library -- Tom St Denis */
/* SPDX-License-Identifier: Unlicense */

/* determines the setup value */
mp_err mp_reduce_2k_setup(const mp_int *a, mp_digit *d)
{
   mp_err err;
   mp_int tmp;

   if ((err = mp_init(&tmp)) != MP_OKAY) {
      return err;
   }

   if ((err = mp_2expt(&tmp, mp_count_bits(a))) != MP_OKAY) {
      goto LBL_ERR;
   }

   if ((err = s_mp_sub(&tmp, a, &tmp)) != MP_OKAY) {
      goto LBL_ERR;
   }

   *d = tmp.dp[0];

LBL_ERR:
   mp_clear(&tmp);
   return err;
}
#endif
