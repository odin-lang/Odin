#include "tommath_private.h"
#ifdef MP_ADDMOD_C
/* LibTomMath, multiple-precision integer library -- Tom St Denis */
/* SPDX-License-Identifier: Unlicense */

/* d = a + b (mod c) */
mp_err mp_addmod(const mp_int *a, const mp_int *b, const mp_int *c, mp_int *d)
{
   mp_err err;
   if ((err = mp_add(a, b, d)) != MP_OKAY) {
      return err;
   }
   return mp_mod(d, c, d);
}
#endif
