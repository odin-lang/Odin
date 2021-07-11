#include "tommath_private.h"
#ifdef MP_MUL_2_C
/* LibTomMath, multiple-precision integer library -- Tom St Denis */
/* SPDX-License-Identifier: Unlicense */

/* b = a*2 */
mp_err mp_mul_2(const mp_int *a, mp_int *b)
{
   mp_err err;
   int x, oldused;
   mp_digit r;

   /* grow to accomodate result */
   if ((err = mp_grow(b, a->used + 1)) != MP_OKAY) {
      return err;
   }

   oldused = b->used;
   b->used = a->used;

   /* carry */
   r = 0;
   for (x = 0; x < a->used; x++) {

      /* get what will be the *next* carry bit from the
       * MSB of the current digit
       */
      mp_digit rr = a->dp[x] >> (mp_digit)(MP_DIGIT_BIT - 1);

      /* now shift up this digit, add in the carry [from the previous] */
      b->dp[x] = ((a->dp[x] << 1uL) | r) & MP_MASK;

      /* copy the carry that would be from the source
       * digit into the next iteration
       */
      r = rr;
   }

   /* new leading digit? */
   if (r != 0u) {
      /* add a MSB which is always 1 at this point */
      b->dp[b->used++] = 1;
   }

   /* now zero any excess digits on the destination
    * that we didn't write to
    */
   s_mp_zero_digs(b->dp + b->used, oldused - b->used);

   b->sign = a->sign;
   return MP_OKAY;
}
#endif
