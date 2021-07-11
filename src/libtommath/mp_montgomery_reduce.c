#include "tommath_private.h"
#ifdef MP_MONTGOMERY_REDUCE_C
/* LibTomMath, multiple-precision integer library -- Tom St Denis */
/* SPDX-License-Identifier: Unlicense */

/* computes xR**-1 == x (mod N) via Montgomery Reduction */
mp_err mp_montgomery_reduce(mp_int *x, const mp_int *n, mp_digit rho)
{
   mp_err err;
   int ix, digs;

   /* can the fast reduction [comba] method be used?
    *
    * Note that unlike in mul you're safely allowed *less*
    * than the available columns [255 per default] since carries
    * are fixed up in the inner loop.
    */
   digs = (n->used * 2) + 1;
   if ((digs < MP_WARRAY) &&
       (x->used <= MP_WARRAY) &&
       (n->used < MP_MAX_COMBA)) {
      return s_mp_montgomery_reduce_comba(x, n, rho);
   }

   /* grow the input as required */
   if ((err = mp_grow(x, digs)) != MP_OKAY) {
      return err;
   }
   x->used = digs;

   for (ix = 0; ix < n->used; ix++) {
      int iy;
      mp_digit u, mu;

      /* mu = ai * rho mod b
       *
       * The value of rho must be precalculated via
       * montgomery_setup() such that
       * it equals -1/n0 mod b this allows the
       * following inner loop to reduce the
       * input one digit at a time
       */
      mu = (mp_digit)(((mp_word)x->dp[ix] * (mp_word)rho) & MP_MASK);

      /* a = a + mu * m * b**i */

      /* Multiply and add in place */
      u = 0;
      for (iy = 0; iy < n->used; iy++) {
         /* compute product and sum */
         mp_word r = ((mp_word)mu * (mp_word)n->dp[iy]) +
                     (mp_word)u + (mp_word)x->dp[ix + iy];

         /* get carry */
         u       = (mp_digit)(r >> (mp_word)MP_DIGIT_BIT);

         /* fix digit */
         x->dp[ix + iy] = (mp_digit)(r & (mp_word)MP_MASK);
      }
      /* At this point the ix'th digit of x should be zero */

      /* propagate carries upwards as required*/
      while (u != 0u) {
         x->dp[ix + iy]   += u;
         u        = x->dp[ix + iy] >> MP_DIGIT_BIT;
         x->dp[ix + iy] &= MP_MASK;
         ++iy;
      }
   }

   /* at this point the n.used'th least
    * significant digits of x are all zero
    * which means we can shift x to the
    * right by n.used digits and the
    * residue is unchanged.
    */

   /* x = x/b**n.used */
   mp_clamp(x);
   mp_rshd(x, n->used);

   /* if x >= n then x = x - n */
   if (mp_cmp_mag(x, n) != MP_LT) {
      return s_mp_sub(x, n, x);
   }

   return MP_OKAY;
}
#endif
