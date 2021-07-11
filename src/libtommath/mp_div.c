#include "tommath_private.h"
#ifdef MP_DIV_C
/* LibTomMath, multiple-precision integer library -- Tom St Denis */
/* SPDX-License-Identifier: Unlicense */

mp_err mp_div(const mp_int *a, const mp_int *b, mp_int *c, mp_int *d)
{
   mp_err err;

   /* is divisor zero ? */
   if (mp_iszero(b)) {
      return MP_VAL;
   }

   /* if a < b then q = 0, r = a */
   if (mp_cmp_mag(a, b) == MP_LT) {
      if (d != NULL) {
         if ((err = mp_copy(a, d)) != MP_OKAY) {
            return err;
         }
      }
      if (c != NULL) {
         mp_zero(c);
      }
      return MP_OKAY;
   }

   if (MP_HAS(S_MP_DIV_RECURSIVE)
       && (b->used > (2 * MP_MUL_KARATSUBA_CUTOFF))
       && (b->used <= ((a->used/3)*2))) {
      err = s_mp_div_recursive(a, b, c, d);
   } else if (MP_HAS(S_MP_DIV_SCHOOL)) {
      err = s_mp_div_school(a, b, c, d);
   } else if (MP_HAS(S_MP_DIV_SMALL)) {
      err = s_mp_div_small(a, b, c, d);
   } else {
      err = MP_VAL;
   }

   return err;
}
#endif
