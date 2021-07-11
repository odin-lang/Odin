#include "tommath_private.h"
#ifdef S_MP_ZERO_DIGS_C
/* LibTomMath, multiple-precision integer library -- Tom St Denis */
/* SPDX-License-Identifier: Unlicense */

#ifdef MP_USE_MEMOPS
#  include <string.h>
#endif

void s_mp_zero_digs(mp_digit *d, int digits)
{
#ifdef MP_USE_MEMOPS
   if (digits > 0) {
      memset(d, 0, (size_t)digits * sizeof(mp_digit));
   }
#else
   while (digits-- > 0) {
      *d++ = 0;
   }
#endif
}

#endif
