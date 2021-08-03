#include "tommath_private.h"
#ifdef MP_CLEAR_MULTI_C
/* LibTomMath, multiple-precision integer library -- Tom St Denis */
/* SPDX-License-Identifier: Unlicense */

#include <stdarg.h>

void mp_clear_multi(mp_int *mp, ...)
{
   va_list args;
   va_start(args, mp);
   while (mp != NULL) {
      mp_clear(mp);
      mp = va_arg(args, mp_int *);
   }
   va_end(args);
}
#endif
