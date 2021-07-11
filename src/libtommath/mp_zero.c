#include "tommath_private.h"
#ifdef MP_ZERO_C
/* LibTomMath, multiple-precision integer library -- Tom St Denis */
/* SPDX-License-Identifier: Unlicense */

/* set to zero */
void mp_zero(mp_int *a)
{
   a->sign = MP_ZPOS;
   s_mp_zero_digs(a->dp, a->used);
   a->used = 0;
}
#endif
