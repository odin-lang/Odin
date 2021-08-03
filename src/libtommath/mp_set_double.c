#include "tommath_private.h"
#ifdef MP_SET_DOUBLE_C
/* LibTomMath, multiple-precision integer library -- Tom St Denis */
/* SPDX-License-Identifier: Unlicense */

#if defined(MP_HAS_SET_DOUBLE)
mp_err mp_set_double(mp_int *a, double b)
{
   uint64_t frac;
   int exp;
   mp_err err;
   union {
      double   dbl;
      uint64_t bits;
   } cast;
   cast.dbl = b;

   exp = (int)((unsigned)(cast.bits >> 52) & 0x7FFu);
   frac = (cast.bits & (((uint64_t)1 << 52) - (uint64_t)1)) | ((uint64_t)1 << 52);

   if (exp == 0x7FF) { /* +-inf, NaN */
      return MP_VAL;
   }
   exp -= 1023 + 52;

   mp_set_u64(a, frac);

   err = (exp < 0) ? mp_div_2d(a, -exp, a, NULL) : mp_mul_2d(a, exp, a);
   if (err != MP_OKAY) {
      return err;
   }

   if (((cast.bits >> 63) != 0u) && !mp_iszero(a)) {
      a->sign = MP_NEG;
   }

   return MP_OKAY;
}
#else
/* pragma message() not supported by several compilers (in mostly older but still used versions) */
#  ifdef _MSC_VER
#    pragma message("mp_set_double implementation is only available on platforms with IEEE754 floating point format")
#  else
#    warning "mp_set_double implementation is only available on platforms with IEEE754 floating point format"
#  endif
#endif
#endif
