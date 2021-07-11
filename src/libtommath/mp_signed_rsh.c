#include "tommath_private.h"
#ifdef MP_SIGNED_RSH_C
/* LibTomMath, multiple-precision integer library -- Tom St Denis */
/* SPDX-License-Identifier: Unlicense */

/* shift right by a certain bit count with sign extension */
mp_err mp_signed_rsh(const mp_int *a, int b, mp_int *c)
{
   mp_err err;
   if (!mp_isneg(a)) {
      return mp_div_2d(a, b, c, NULL);
   }

   if ((err = mp_add_d(a, 1uL, c)) != MP_OKAY) {
      return err;
   }

   err = mp_div_2d(c, b, c, NULL);
   return (err == MP_OKAY) ? mp_sub_d(c, 1uL, c) : err;
}
#endif
