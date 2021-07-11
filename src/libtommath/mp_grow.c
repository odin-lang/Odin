#include "tommath_private.h"
#ifdef MP_GROW_C
/* LibTomMath, multiple-precision integer library -- Tom St Denis */
/* SPDX-License-Identifier: Unlicense */

/* grow as required */
mp_err mp_grow(mp_int *a, int size)
{
   /* if the alloc size is smaller alloc more ram */
   if (a->alloc < size) {
      mp_digit *dp;

      if (size > MP_MAX_DIGIT_COUNT) {
         return MP_OVF;
      }

      /* reallocate the array a->dp
       *
       * We store the return in a temporary variable
       * in case the operation failed we don't want
       * to overwrite the dp member of a.
       */
      dp = (mp_digit *) MP_REALLOC(a->dp,
                                   (size_t)a->alloc * sizeof(mp_digit),
                                   (size_t)size * sizeof(mp_digit));
      if (dp == NULL) {
         /* reallocation failed but "a" is still valid [can be freed] */
         return MP_MEM;
      }

      /* reallocation succeeded so set a->dp */
      a->dp = dp;

      /* zero excess digits */
      s_mp_zero_digs(a->dp + a->alloc, size - a->alloc);
      a->alloc = size;
   }
   return MP_OKAY;
}
#endif
