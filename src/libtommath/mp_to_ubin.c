#include "tommath_private.h"
#ifdef MP_TO_UBIN_C
/* LibTomMath, multiple-precision integer library -- Tom St Denis */
/* SPDX-License-Identifier: Unlicense */

/* store in unsigned [big endian] format */
mp_err mp_to_ubin(const mp_int *a, uint8_t *buf, size_t maxlen, size_t *written)
{
   size_t  x, count;
   mp_err  err;
   mp_int  t;

   count = mp_ubin_size(a);
   if (count > maxlen) {
      return MP_BUF;
   }

   if ((err = mp_init_copy(&t, a)) != MP_OKAY) {
      return err;
   }

   for (x = count; x --> 0u;) {
      buf[x] = (uint8_t)(t.dp[0] & 255u);
      if ((err = mp_div_2d(&t, 8, &t, NULL)) != MP_OKAY) {
         goto LBL_ERR;
      }
   }

   if (written != NULL) {
      *written = count;
   }

LBL_ERR:
   mp_clear(&t);
   return err;
}
#endif
