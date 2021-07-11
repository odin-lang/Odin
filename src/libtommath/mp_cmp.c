#include "tommath_private.h"
#ifdef MP_CMP_C
/* LibTomMath, multiple-precision integer library -- Tom St Denis */
/* SPDX-License-Identifier: Unlicense */

/* compare two ints (signed)*/
mp_ord mp_cmp(const mp_int *a, const mp_int *b)
{
   /* compare based on sign */
   if (a->sign != b->sign) {
      return mp_isneg(a) ? MP_LT : MP_GT;
   }

   /* if negative compare opposite direction */
   if (mp_isneg(a)) {
      MP_EXCH(const mp_int *, a, b);
   }

   return mp_cmp_mag(a, b);
}
#endif
