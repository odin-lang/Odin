#include "tommath_private.h"
#ifdef S_MP_MUL_HIGH_C
/* LibTomMath, multiple-precision integer library -- Tom St Denis */
/* SPDX-License-Identifier: Unlicense */

/* multiplies |a| * |b| and does not compute the lower digs digits
 * [meant to get the higher part of the product]
 */
mp_err s_mp_mul_high(const mp_int *a, const mp_int *b, mp_int *c, int digs)
{
   mp_int   t;
   int      pa, pb, ix;
   mp_err   err;

   /* can we use the fast multiplier? */
   if (MP_HAS(S_MP_MUL_HIGH_COMBA)
       && ((a->used + b->used + 1) < MP_WARRAY)
       && (MP_MIN(a->used, b->used) < MP_MAX_COMBA)) {
      return s_mp_mul_high_comba(a, b, c, digs);
   }

   if ((err = mp_init_size(&t, a->used + b->used + 1)) != MP_OKAY) {
      return err;
   }
   t.used = a->used + b->used + 1;

   pa = a->used;
   pb = b->used;
   for (ix = 0; ix < pa; ix++) {
      int iy;
      mp_digit u = 0;

      for (iy = digs - ix; iy < pb; iy++) {
         /* calculate the double precision result */
         mp_word r = (mp_word)t.dp[ix + iy] +
                     ((mp_word)a->dp[ix] * (mp_word)b->dp[iy]) +
                     (mp_word)u;

         /* get the lower part */
         t.dp[ix + iy] = (mp_digit)(r & (mp_word)MP_MASK);

         /* carry the carry */
         u       = (mp_digit)(r >> (mp_word)MP_DIGIT_BIT);
      }
      t.dp[ix + pb] = u;
   }
   mp_clamp(&t);
   mp_exch(&t, c);
   mp_clear(&t);
   return MP_OKAY;
}
#endif
