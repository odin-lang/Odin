#include "tommath_private.h"
#ifdef MP_SHRINK_C
/* LibTomMath, multiple-precision integer library -- Tom St Denis */
/* SPDX-License-Identifier: Unlicense */

/* shrink a bignum */
mp_err mp_shrink(mp_int *a)
{
   int alloc = MP_MAX(MP_MIN_DIGIT_COUNT, a->used);
   if (a->alloc != alloc) {
      mp_digit *dp = (mp_digit *) MP_REALLOC(a->dp,
                                             (size_t)a->alloc * sizeof(mp_digit),
                                             (size_t)alloc * sizeof(mp_digit));
      if (dp == NULL) {
         return MP_MEM;
      }
      a->dp    = dp;
      a->alloc = alloc;
   }
   return MP_OKAY;
}
#endif
