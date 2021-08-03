#include "tommath_private.h"
#ifdef S_MP_ADD_C
/* LibTomMath, multiple-precision integer library -- Tom St Denis */
/* SPDX-License-Identifier: Unlicense */

/* low level addition, based on HAC pp.594, Algorithm 14.7 */
mp_err s_mp_add(const mp_int *a, const mp_int *b, mp_int *c)
{
   int oldused, min, max, i;
   mp_digit u;
   mp_err err;

   /* find sizes, we let |a| <= |b| which means we have to sort
    * them.  "x" will point to the input with the most digits
    */
   if (a->used < b->used) {
      MP_EXCH(const mp_int *, a, b);
   }

   min = b->used;
   max = a->used;

   /* init result */
   if ((err = mp_grow(c, max + 1)) != MP_OKAY) {
      return err;
   }

   /* get old used digit count and set new one */
   oldused = c->used;
   c->used = max + 1;

   /* zero the carry */
   u = 0;
   for (i = 0; i < min; i++) {
      /* Compute the sum at one digit, T[i] = A[i] + B[i] + U */
      c->dp[i] = a->dp[i] + b->dp[i] + u;

      /* U = carry bit of T[i] */
      u = c->dp[i] >> (mp_digit)MP_DIGIT_BIT;

      /* take away carry bit from T[i] */
      c->dp[i] &= MP_MASK;
   }

   /* now copy higher words if any, that is in A+B
    * if A or B has more digits add those in
    */
   if (min != max) {
      for (; i < max; i++) {
         /* T[i] = A[i] + U */
         c->dp[i] = a->dp[i] + u;

         /* U = carry bit of T[i] */
         u = c->dp[i] >> (mp_digit)MP_DIGIT_BIT;

         /* take away carry bit from T[i] */
         c->dp[i] &= MP_MASK;
      }
   }

   /* add carry */
   c->dp[i] = u;

   /* clear digits above oldused */
   s_mp_zero_digs(c->dp + c->used, oldused - c->used);

   mp_clamp(c);
   return MP_OKAY;
}
#endif
