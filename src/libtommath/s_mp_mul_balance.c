#include "tommath_private.h"
#ifdef S_MP_MUL_BALANCE_C
/* LibTomMath, multiple-precision integer library -- Tom St Denis */
/* SPDX-License-Identifier: Unlicense */

/* single-digit multiplication with the smaller number as the single-digit */
mp_err s_mp_mul_balance(const mp_int *a, const mp_int *b, mp_int *c)
{
   mp_int a0, tmp, r;
   mp_err err;
   int i, j,
       nblocks = MP_MAX(a->used, b->used) / MP_MIN(a->used, b->used),
       bsize = MP_MIN(a->used, b->used);

   if ((err = mp_init_size(&a0, bsize + 2)) != MP_OKAY) {
      return err;
   }
   if ((err = mp_init_multi(&tmp, &r, NULL)) != MP_OKAY) {
      mp_clear(&a0);
      return err;
   }

   /* Make sure that A is the larger one*/
   if (a->used < b->used) {
      MP_EXCH(const mp_int *, a, b);
   }

   for (i = 0, j=0; i < nblocks; i++) {
      /* Cut a slice off of a */
      a0.used = bsize;
      s_mp_copy_digs(a0.dp, a->dp + j, a0.used);
      j += a0.used;
      mp_clamp(&a0);

      /* Multiply with b */
      if ((err = mp_mul(&a0, b, &tmp)) != MP_OKAY) {
         goto LBL_ERR;
      }
      /* Shift tmp to the correct position */
      if ((err = mp_lshd(&tmp, bsize * i)) != MP_OKAY) {
         goto LBL_ERR;
      }
      /* Add to output. No carry needed */
      if ((err = mp_add(&r, &tmp, &r)) != MP_OKAY) {
         goto LBL_ERR;
      }
   }
   /* The left-overs; there are always left-overs */
   if (j < a->used) {
      a0.used = a->used - j;
      s_mp_copy_digs(a0.dp, a->dp + j, a0.used);
      j += a0.used;
      mp_clamp(&a0);

      if ((err = mp_mul(&a0, b, &tmp)) != MP_OKAY) {
         goto LBL_ERR;
      }
      if ((err = mp_lshd(&tmp, bsize * i)) != MP_OKAY) {
         goto LBL_ERR;
      }
      if ((err = mp_add(&r, &tmp, &r)) != MP_OKAY) {
         goto LBL_ERR;
      }
   }

   mp_exch(&r,c);
LBL_ERR:
   mp_clear_multi(&a0, &tmp, &r,NULL);
   return err;
}
#endif
