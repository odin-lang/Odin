#include "tommath_private.h"
#ifdef MP_SUB_C
/* LibTomMath, multiple-precision integer library -- Tom St Denis */
/* SPDX-License-Identifier: Unlicense */

/* high level subtraction (handles signs) */
mp_err mp_sub(const mp_int *a, const mp_int *b, mp_int *c)
{
   if (a->sign != b->sign) {
      /* subtract a negative from a positive, OR */
      /* subtract a positive from a negative. */
      /* In either case, ADD their magnitudes, */
      /* and use the sign of the first number. */
      c->sign = a->sign;
      return s_mp_add(a, b, c);
   }

   /* subtract a positive from a positive, OR */
   /* subtract a negative from a negative. */
   /* First, take the difference between their */
   /* magnitudes, then... */
   if (mp_cmp_mag(a, b) == MP_LT) {
      /* The second has a larger magnitude */
      /* The result has the *opposite* sign from */
      /* the first number. */
      c->sign = (!mp_isneg(a) ? MP_NEG : MP_ZPOS);
      MP_EXCH(const mp_int *, a, b);
   } else {
      /* The first has a larger or equal magnitude */
      /* Copy the sign from the first */
      c->sign = a->sign;
   }
   return s_mp_sub(a, b, c);
}

#endif
