#include "tommath_private.h"
#ifdef S_MP_COPY_DIGS_C
/* LibTomMath, multiple-precision integer library -- Tom St Denis */
/* SPDX-License-Identifier: Unlicense */

#ifdef MP_USE_MEMOPS
#  include <string.h>
#endif

void s_mp_copy_digs(mp_digit *d, const mp_digit *s, int digits)
{
#ifdef MP_USE_MEMOPS
   if (digits > 0) {
      memcpy(d, s, (size_t)digits * sizeof(mp_digit));
   }
#else
   while (digits-- > 0) {
      *d++ = *s++;
   }
#endif
}

#endif
