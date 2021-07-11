#include "tommath_private.h"
#ifdef MP_MOD_C
/* LibTomMath, multiple-precision integer library -- Tom St Denis */
/* SPDX-License-Identifier: Unlicense */

/* c = a mod b, 0 <= c < b if b > 0, b < c <= 0 if b < 0 */
mp_err mp_mod(const mp_int *a, const mp_int *b, mp_int *c)
{
   mp_err err;
   if ((err = mp_div(a, b, NULL, c)) != MP_OKAY) {
      return err;
   }
   return mp_iszero(c) || (c->sign == b->sign) ? MP_OKAY : mp_add(b, c, c);
}
#endif
