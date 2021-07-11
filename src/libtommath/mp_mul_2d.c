#include "tommath_private.h"
#ifdef MP_MUL_2D_C
/* LibTomMath, multiple-precision integer library -- Tom St Denis */
/* SPDX-License-Identifier: Unlicense */

/* shift left by a certain bit count */
mp_err mp_mul_2d(const mp_int *a, int b, mp_int *c)
{
   mp_err err;

   if (b < 0) {
      return MP_VAL;
   }

   if ((err = mp_copy(a, c)) != MP_OKAY) {
      return err;
   }

   if ((err = mp_grow(c, c->used + (b / MP_DIGIT_BIT) + 1)) != MP_OKAY) {
      return err;
   }

   /* shift by as many digits in the bit count */
   if (b >= MP_DIGIT_BIT) {
      if ((err = mp_lshd(c, b / MP_DIGIT_BIT)) != MP_OKAY) {
         return err;
      }
   }

   /* shift any bit count < MP_DIGIT_BIT */
   b %= MP_DIGIT_BIT;
   if (b != 0u) {
      mp_digit shift, mask, r;
      int x;

      /* bitmask for carries */
      mask = ((mp_digit)1 << b) - (mp_digit)1;

      /* shift for msbs */
      shift = (mp_digit)(MP_DIGIT_BIT - b);

      /* carry */
      r    = 0;
      for (x = 0; x < c->used; x++) {
         /* get the higher bits of the current word */
         mp_digit rr = (c->dp[x] >> shift) & mask;

         /* shift the current word and OR in the carry */
         c->dp[x] = ((c->dp[x] << b) | r) & MP_MASK;

         /* set the carry to the carry bits of the current word */
         r = rr;
      }

      /* set final carry */
      if (r != 0u) {
         c->dp[(c->used)++] = r;
      }
   }
   mp_clamp(c);
   return MP_OKAY;
}
#endif
