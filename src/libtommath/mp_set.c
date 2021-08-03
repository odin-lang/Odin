#include "tommath_private.h"
#ifdef MP_SET_C
/* LibTomMath, multiple-precision integer library -- Tom St Denis */
/* SPDX-License-Identifier: Unlicense */

/* set to a digit */
void mp_set(mp_int *a, mp_digit b)
{
   int oldused = a->used;
   a->dp[0] = b & MP_MASK;
   a->sign  = MP_ZPOS;
   a->used  = (a->dp[0] != 0u) ? 1 : 0;
   s_mp_zero_digs(a->dp + a->used, oldused - a->used);
}
#endif
