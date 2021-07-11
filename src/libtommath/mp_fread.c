#include "tommath_private.h"
#ifdef MP_FREAD_C
/* LibTomMath, multiple-precision integer library -- Tom St Denis */
/* SPDX-License-Identifier: Unlicense */

#ifndef MP_NO_FILE
/* read a bigint from a file stream in ASCII */
mp_err mp_fread(mp_int *a, int radix, FILE *stream)
{
   mp_err err;
   mp_sign sign = MP_ZPOS;
   int ch;

   /* make sure the radix is ok */
   if ((radix < 2) || (radix > 64)) {
      return MP_VAL;
   }

   /* if first digit is - then set negative */
   ch = fgetc(stream);
   if (ch == (int)'-') {
      sign = MP_NEG;
      ch = fgetc(stream);
   }

   /* no digits, return error */
   if (ch == EOF) {
      return MP_ERR;
   }

   /* clear a */
   mp_zero(a);

   do {
      uint8_t y;
      unsigned pos;
      ch = (radix <= 36) ? MP_TOUPPER(ch) : ch;
      pos = (unsigned)(ch - (int)'+');
      if (MP_RADIX_MAP_REVERSE_SIZE <= pos) {
         break;
      }

      y = s_mp_radix_map_reverse[pos];

      if (y >= radix) {
         break;
      }

      /* shift up and add */
      if ((err = mp_mul_d(a, (mp_digit)radix, a)) != MP_OKAY) {
         return err;
      }
      if ((err = mp_add_d(a, y, a)) != MP_OKAY) {
         return err;
      }
   } while ((ch = fgetc(stream)) != EOF);

   if (!mp_iszero(a)) {
      a->sign = sign;
   }

   return MP_OKAY;
}
#endif

#endif
