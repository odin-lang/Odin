#include "tommath_private.h"
#ifdef MP_SQRMOD_C
/* LibTomMath, multiple-precision integer library -- Tom St Denis */
/* SPDX-License-Identifier: Unlicense */

/* c = a * a (mod b) */
mp_err mp_sqrmod(const mp_int *a, const mp_int *b, mp_int *c)
{
   mp_err err;
   if ((err = mp_sqr(a, c)) != MP_OKAY) {
      return err;
   }
   return mp_mod(c, b, c);
}
#endif
