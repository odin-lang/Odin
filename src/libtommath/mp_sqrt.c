#include "tommath_private.h"
#ifdef MP_SQRT_C
/* LibTomMath, multiple-precision integer library -- Tom St Denis */
/* SPDX-License-Identifier: Unlicense */

/* this function is less generic than mp_n_root, simpler and faster */
mp_err mp_sqrt(const mp_int *arg, mp_int *ret)
{
   mp_err err;
   mp_int t1, t2;

   /* must be positive */
   if (mp_isneg(arg)) {
      return MP_VAL;
   }

   /* easy out */
   if (mp_iszero(arg)) {
      mp_zero(ret);
      return MP_OKAY;
   }

   if ((err = mp_init_copy(&t1, arg)) != MP_OKAY) {
      return err;
   }

   if ((err = mp_init(&t2)) != MP_OKAY) {
      goto LBL_ERR2;
   }

   /* First approx. (not very bad for large arg) */
   mp_rshd(&t1, t1.used/2);

   /* t1 > 0  */
   if ((err = mp_div(arg, &t1, &t2, NULL)) != MP_OKAY) {
      goto LBL_ERR1;
   }
   if ((err = mp_add(&t1, &t2, &t1)) != MP_OKAY) {
      goto LBL_ERR1;
   }
   if ((err = mp_div_2(&t1, &t1)) != MP_OKAY) {
      goto LBL_ERR1;
   }
   /* And now t1 > sqrt(arg) */
   do {
      if ((err = mp_div(arg, &t1, &t2, NULL)) != MP_OKAY) {
         goto LBL_ERR1;
      }
      if ((err = mp_add(&t1, &t2, &t1)) != MP_OKAY) {
         goto LBL_ERR1;
      }
      if ((err = mp_div_2(&t1, &t1)) != MP_OKAY) {
         goto LBL_ERR1;
      }
      /* t1 >= sqrt(arg) >= t2 at this point */
   } while (mp_cmp_mag(&t1, &t2) == MP_GT);

   mp_exch(&t1, ret);

LBL_ERR1:
   mp_clear(&t2);
LBL_ERR2:
   mp_clear(&t1);
   return err;
}

#endif
