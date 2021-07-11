#include "tommath_private.h"
#ifdef MP_DR_REDUCE_C
/* LibTomMath, multiple-precision integer library -- Tom St Denis */
/* SPDX-License-Identifier: Unlicense */

/* reduce "x" in place modulo "n" using the Diminished Radix algorithm.
 *
 * Based on algorithm from the paper
 *
 * "Generating Efficient Primes for Discrete Log Cryptosystems"
 *                 Chae Hoon Lim, Pil Joong Lee,
 *          POSTECH Information Research Laboratories
 *
 * The modulus must be of a special format [see manual]
 *
 * Has been modified to use algorithm 7.10 from the LTM book instead
 *
 * Input x must be in the range 0 <= x <= (n-1)**2
 */
mp_err mp_dr_reduce(mp_int *x, const mp_int *n, mp_digit k)
{
   mp_err err;

   /* m = digits in modulus */
   int m = n->used;

   /* ensure that "x" has at least 2m digits */
   if ((err = mp_grow(x, m + m)) != MP_OKAY) {
      return err;
   }

   /* top of loop, this is where the code resumes if
    * another reduction pass is required.
    */
   for (;;) {
      int i;
      mp_digit mu = 0;

      /* compute (x mod B**m) + k * [x/B**m] inline and inplace */
      for (i = 0; i < m; i++) {
         mp_word r         = ((mp_word)x->dp[i + m] * (mp_word)k) + x->dp[i] + mu;
         x->dp[i]  = (mp_digit)(r & MP_MASK);
         mu        = (mp_digit)(r >> ((mp_word)MP_DIGIT_BIT));
      }

      /* set final carry */
      x->dp[i] = mu;

      /* zero words above m */
      s_mp_zero_digs(x->dp + m + 1, (x->used - m) - 1);

      /* clamp, sub and return */
      mp_clamp(x);

      /* if x >= n then subtract and reduce again
       * Each successive "recursion" makes the input smaller and smaller.
       */
      if (mp_cmp_mag(x, n) == MP_LT) {
         break;
      }

      if ((err = s_mp_sub(x, n, x)) != MP_OKAY) {
         return err;
      }
   }
   return MP_OKAY;
}
#endif
