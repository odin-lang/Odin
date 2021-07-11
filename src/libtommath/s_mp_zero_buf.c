#include "tommath_private.h"
#ifdef S_MP_ZERO_BUF_C
/* LibTomMath, multiple-precision integer library -- Tom St Denis */
/* SPDX-License-Identifier: Unlicense */

#ifdef MP_USE_MEMOPS
#  include <string.h>
#endif

void s_mp_zero_buf(void *mem, size_t size)
{
#ifdef MP_USE_MEMOPS
   memset(mem, 0, size);
#else
   char *m = (char *)mem;
   while (size-- > 0u) {
      *m++ = '\0';
   }
#endif
}

#endif
