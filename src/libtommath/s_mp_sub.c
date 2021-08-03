#include "tommath_private.h"
#ifdef S_MP_SUB_C
/* LibTomMath, multiple-precision integer library -- Tom St Denis */
/* SPDX-License-Identifier: Unlicense */

/* low level subtraction (assumes |a| > |b|), HAC pp.595 Algorithm 14.9 */
mp_err s_mp_sub(const mp_int *a, const mp_int *b, mp_int *c)
{
   int oldused = c->used, min = b->used, max = a->used, i;
   mp_digit u;
   mp_err err;

   /* init result */
   if ((err = mp_grow(c, max)) != MP_OKAY) {
      return err;
   }

   c->used = max;

   /* set carry to zero */
   u = 0;
   for (i = 0; i < min; i++) {
      /* T[i] = A[i] - B[i] - U */
      c->dp[i] = (a->dp[i] - b->dp[i]) - u;

      /* U = carry bit of T[i]
       * Note this saves performing an AND operation since
       * if a carry does occur it will propagate all the way to the
       * MSB.  As a result a single shift is enough to get the carry
       */
      u = c->dp[i] >> (MP_SIZEOF_BITS(mp_digit) - 1u);

      /* Clear carry from T[i] */
      c->dp[i] &= MP_MASK;
   }

   /* now copy higher words if any, e.g. if A has more digits than B  */
   for (; i < max; i++) {
      /* T[i] = A[i] - U */
      c->dp[i] = a->dp[i] - u;

      /* U = carry bit of T[i] */
      u = c->dp[i] >> (MP_SIZEOF_BITS(mp_digit) - 1u);

      /* Clear carry from T[i] */
      c->dp[i] &= MP_MASK;
   }

   /* clear digits above used (since we may not have grown result above) */
   s_mp_zero_digs(c->dp + c->used, oldused - c->used);

   mp_clamp(c);
   return MP_OKAY;
}

#endif
