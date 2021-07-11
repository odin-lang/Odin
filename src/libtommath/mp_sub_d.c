#include "tommath_private.h"
#ifdef MP_SUB_D_C
/* LibTomMath, multiple-precision integer library -- Tom St Denis */
/* SPDX-License-Identifier: Unlicense */

/* single digit subtraction */
mp_err mp_sub_d(const mp_int *a, mp_digit b, mp_int *c)
{
   mp_err err;
   int oldused;

   /* fast path for a == c */
   if (a == c) {
      if ((c->sign == MP_NEG) &&
          ((c->dp[0] + b) < MP_DIGIT_MAX)) {
         c->dp[0] += b;
         return MP_OKAY;
      }
      if ((c->sign == MP_ZPOS) &&
          (c->dp[0] > b)) {
         c->dp[0] -= b;
         return MP_OKAY;
      }
   }

   /* grow c as required */
   if ((err = mp_grow(c, a->used + 1)) != MP_OKAY) {
      return err;
   }

   /* if a is negative just do an unsigned
    * addition [with fudged signs]
    */
   if (a->sign == MP_NEG) {
      mp_int a_ = *a;
      a_.sign = MP_ZPOS;
      err     = mp_add_d(&a_, b, c);
      c->sign = MP_NEG;

      /* clamp */
      mp_clamp(c);

      return err;
   }

   oldused = c->used;

   /* if a <= b simply fix the single digit */
   if (((a->used == 1) && (a->dp[0] <= b)) || mp_iszero(a)) {
      c->dp[0] = (a->used == 1) ? b - a->dp[0] : b;

      /* negative/1digit */
      c->sign = MP_NEG;
      c->used = 1;
   } else {
      int i;
      mp_digit mu = b;

      /* positive/size */
      c->sign = MP_ZPOS;
      c->used = a->used;

      /* subtract digits, mu is carry */
      for (i = 0; i < a->used; i++) {
         c->dp[i] = a->dp[i] - mu;
         mu = c->dp[i] >> (MP_SIZEOF_BITS(mp_digit) - 1u);
         c->dp[i] &= MP_MASK;
      }
   }

   /* zero excess digits */
   s_mp_zero_digs(c->dp + c->used, oldused - c->used);

   mp_clamp(c);
   return MP_OKAY;
}

#endif
