#include "tommath_private.h"
#ifdef MP_FWRITE_C
/* LibTomMath, multiple-precision integer library -- Tom St Denis */
/* SPDX-License-Identifier: Unlicense */

#ifndef MP_NO_FILE
mp_err mp_fwrite(const mp_int *a, int radix, FILE *stream)
{
   char *buf;
   mp_err err;
   size_t size, written;

   if ((err = mp_radix_size_overestimate(a, radix, &size)) != MP_OKAY) {
      return err;
   }

   buf = (char *) MP_MALLOC(size);
   if (buf == NULL) {
      return MP_MEM;
   }

   if ((err = mp_to_radix(a, buf, size, &written, radix)) == MP_OKAY) {
      if (fwrite(buf, written, 1uL, stream) != 1uL) {
         err = MP_ERR;
      }
   }

   MP_FREE_BUF(buf, size);
   return err;
}
#endif

#endif
