#include "tommath_private.h"
#ifdef MP_REDUCE_C
/* LibTomMath, multiple-precision integer library -- Tom St Denis */
/* SPDX-License-Identifier: Unlicense */

/* reduces x mod m, assumes 0 < x < m**2, mu is
 * precomputed via mp_reduce_setup.
 * From HAC pp.604 Algorithm 14.42
 */
mp_err mp_reduce(mp_int *x, const mp_int *m, const mp_int *mu)
{
   mp_int  q;
   mp_err  err;
   int     um = m->used;

   /* q = x */
   if ((err = mp_init_copy(&q, x)) != MP_OKAY) {
      return err;
   }

   /* q1 = x / b**(k-1)  */
   mp_rshd(&q, um - 1);

   /* according to HAC this optimization is ok */
   if ((mp_digit)um > ((mp_digit)1 << (MP_DIGIT_BIT - 1))) {
      if ((err = mp_mul(&q, mu, &q)) != MP_OKAY) {
         goto LBL_ERR;
      }
   } else if (MP_HAS(S_MP_MUL_HIGH)) {
      if ((err = s_mp_mul_high(&q, mu, &q, um)) != MP_OKAY) {
         goto LBL_ERR;
      }
   } else if (MP_HAS(S_MP_MUL_HIGH_COMBA)) {
      if ((err = s_mp_mul_high_comba(&q, mu, &q, um)) != MP_OKAY) {
         goto LBL_ERR;
      }
   } else {
      err = MP_VAL;
      goto LBL_ERR;
   }

   /* q3 = q2 / b**(k+1) */
   mp_rshd(&q, um + 1);

   /* x = x mod b**(k+1), quick (no division) */
   if ((err = mp_mod_2d(x, MP_DIGIT_BIT * (um + 1), x)) != MP_OKAY) {
      goto LBL_ERR;
   }

   /* q = q * m mod b**(k+1), quick (no division) */
   if ((err = s_mp_mul(&q, m, &q, um + 1)) != MP_OKAY) {
      goto LBL_ERR;
   }

   /* x = x - q */
   if ((err = mp_sub(x, &q, x)) != MP_OKAY) {
      goto LBL_ERR;
   }

   /* If x < 0, add b**(k+1) to it */
   if (mp_cmp_d(x, 0uL) == MP_LT) {
      mp_set(&q, 1uL);
      if ((err = mp_lshd(&q, um + 1)) != MP_OKAY) {
         goto LBL_ERR;
      }
      if ((err = mp_add(x, &q, x)) != MP_OKAY) {
         goto LBL_ERR;
      }
   }

   /* Back off if it's too big */
   while (mp_cmp(x, m) != MP_LT) {
      if ((err = s_mp_sub(x, m, x)) != MP_OKAY) {
         goto LBL_ERR;
      }
   }

LBL_ERR:
   mp_clear(&q);

   return err;
}
#endif
