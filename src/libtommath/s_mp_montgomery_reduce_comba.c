#include "tommath_private.h"
#ifdef S_MP_MONTGOMERY_REDUCE_COMBA_C
/* LibTomMath, multiple-precision integer library -- Tom St Denis */
/* SPDX-License-Identifier: Unlicense */

/* computes xR**-1 == x (mod N) via Montgomery Reduction
 *
 * This is an optimized implementation of montgomery_reduce
 * which uses the comba method to quickly calculate the columns of the
 * reduction.
 *
 * Based on Algorithm 14.32 on pp.601 of HAC.
*/
mp_err s_mp_montgomery_reduce_comba(mp_int *x, const mp_int *n, mp_digit rho)
{
   int     ix, oldused;
   mp_err  err;
   mp_word W[MP_WARRAY];

   if (x->used > MP_WARRAY) {
      return MP_VAL;
   }

   /* get old used count */
   oldused = x->used;

   /* grow a as required */
   if ((err = mp_grow(x, n->used + 1)) != MP_OKAY) {
      return err;
   }

   /* first we have to get the digits of the input into
    * an array of double precision words W[...]
    */

   /* copy the digits of a into W[0..a->used-1] */
   for (ix = 0; ix < x->used; ix++) {
      W[ix] = x->dp[ix];
   }

   /* zero the high words of W[a->used..m->used*2] */
   if (ix < ((n->used * 2) + 1)) {
      s_mp_zero_buf(W + x->used, sizeof(mp_word) * (size_t)(((n->used * 2) + 1) - ix));
   }

   /* now we proceed to zero successive digits
    * from the least significant upwards
    */
   for (ix = 0; ix < n->used; ix++) {
      int iy;
      mp_digit mu;

      /* mu = ai * m' mod b
       *
       * We avoid a double precision multiplication (which isn't required)
       * by casting the value down to a mp_digit.  Note this requires
       * that W[ix-1] have  the carry cleared (see after the inner loop)
       */
      mu = ((W[ix] & MP_MASK) * rho) & MP_MASK;

      /* a = a + mu * m * b**i
       *
       * This is computed in place and on the fly.  The multiplication
       * by b**i is handled by offseting which columns the results
       * are added to.
       *
       * Note the comba method normally doesn't handle carries in the
       * inner loop In this case we fix the carry from the previous
       * column since the Montgomery reduction requires digits of the
       * result (so far) [see above] to work.  This is
       * handled by fixing up one carry after the inner loop.  The
       * carry fixups are done in order so after these loops the
       * first m->used words of W[] have the carries fixed
       */
      for (iy = 0; iy < n->used; iy++) {
         W[ix + iy] += (mp_word)mu * (mp_word)n->dp[iy];
      }

      /* now fix carry for next digit, W[ix+1] */
      W[ix + 1] += W[ix] >> (mp_word)MP_DIGIT_BIT;
   }

   /* now we have to propagate the carries and
    * shift the words downward [all those least
    * significant digits we zeroed].
    */

   for (; ix < (n->used * 2); ix++) {
      W[ix + 1] += W[ix] >> (mp_word)MP_DIGIT_BIT;
   }

   /* copy out, A = A/b**n
    *
    * The result is A/b**n but instead of converting from an
    * array of mp_word to mp_digit than calling mp_rshd
    * we just copy them in the right order
    */

   for (ix = 0; ix < (n->used + 1); ix++) {
      x->dp[ix] = W[n->used + ix] & (mp_word)MP_MASK;
   }

   /* set the max used */
   x->used = n->used + 1;

   /* zero oldused digits, if the input a was larger than
    * m->used+1 we'll have to clear the digits
    */
   s_mp_zero_digs(x->dp + x->used, oldused - x->used);

   mp_clamp(x);

   /* if A >= m then A = A - m */
   if (mp_cmp_mag(x, n) != MP_LT) {
      return s_mp_sub(x, n, x);
   }
   return MP_OKAY;
}
#endif
