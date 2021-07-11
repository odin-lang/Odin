#include "tommath_private.h"
#ifdef MP_READ_RADIX_C
/* LibTomMath, multiple-precision integer library -- Tom St Denis */
/* SPDX-License-Identifier: Unlicense */

/* read a string [ASCII] in a given radix */
mp_err mp_read_radix(mp_int *a, const char *str, int radix)
{
   mp_err   err;
   mp_sign  sign = MP_ZPOS;

   /* make sure the radix is ok */
   if ((radix < 2) || (radix > 64)) {
      return MP_VAL;
   }

   /* if the leading digit is a
    * minus set the sign to negative.
    */
   if (*str == '-') {
      ++str;
      sign = MP_NEG;
   }

   /* set the integer to the default of zero */
   mp_zero(a);

   /* process each digit of the string */
   while (*str != '\0') {
      /* if the radix <= 36 the conversion is case insensitive
       * this allows numbers like 1AB and 1ab to represent the same  value
       * [e.g. in hex]
       */
      uint8_t y;
      char ch = (radix <= 36) ? (char)MP_TOUPPER((int)*str) : *str;
      unsigned pos = (unsigned)(ch - '+');
      if (MP_RADIX_MAP_REVERSE_SIZE <= pos) {
         break;
      }
      y = s_mp_radix_map_reverse[pos];

      /* if the char was found in the map
       * and is less than the given radix add it
       * to the number, otherwise exit the loop.
       */
      if (y >= radix) {
         break;
      }
      if ((err = mp_mul_d(a, (mp_digit)radix, a)) != MP_OKAY) {
         return err;
      }
      if ((err = mp_add_d(a, y, a)) != MP_OKAY) {
         return err;
      }
      ++str;
   }

   /* if an illegal character was found, fail. */
   if ((*str != '\0') && (*str != '\r') && (*str != '\n')) {
      return MP_VAL;
   }

   /* set the sign only if a != 0 */
   if (!mp_iszero(a)) {
      a->sign = sign;
   }
   return MP_OKAY;
}
#endif
