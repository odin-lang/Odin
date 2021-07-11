#include "tommath_private.h"
#ifdef MP_DIV_2D_C
/* LibTomMath, multiple-precision integer library -- Tom St Denis */
/* SPDX-License-Identifier: Unlicense */

/* shift right by a certain bit count (store quotient in c, optional remainder in d) */
mp_err mp_div_2d(const mp_int *a, int b, mp_int *c, mp_int *d)
{
   mp_err err;

   if (b < 0) {
      return MP_VAL;
   }

   if ((err = mp_copy(a, c)) != MP_OKAY) {
      return err;
   }

   /* 'a' should not be used after here - it might be the same as d */

   /* get the remainder */
   if (d != NULL) {
      if ((err = mp_mod_2d(a, b, d)) != MP_OKAY) {
         return err;
      }
   }

   /* shift by as many digits in the bit count */
   if (b >= MP_DIGIT_BIT) {
      mp_rshd(c, b / MP_DIGIT_BIT);
   }

   /* shift any bit count < MP_DIGIT_BIT */
   b %= MP_DIGIT_BIT;
   if (b != 0u) {
      int x;
      mp_digit r, mask, shift;

      /* mask */
      mask = ((mp_digit)1 << b) - 1uL;

      /* shift for lsb */
      shift = (mp_digit)(MP_DIGIT_BIT - b);

      /* carry */
      r = 0;
      for (x = c->used; x --> 0;) {
         /* get the lower  bits of this word in a temp */
         mp_digit rr = c->dp[x] & mask;

         /* shift the current word and mix in the carry bits from the previous word */
         c->dp[x] = (c->dp[x] >> b) | (r << shift);

         /* set the carry to the carry bits of the current word found above */
         r = rr;
      }
   }
   mp_clamp(c);
   return MP_OKAY;
}
#endif
