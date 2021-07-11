#include "tommath_private.h"
#ifdef MP_COMPLEMENT_C
/* LibTomMath, multiple-precision integer library -- Tom St Denis */
/* SPDX-License-Identifier: Unlicense */

/* b = ~a */
mp_err mp_complement(const mp_int *a, mp_int *b)
{
   mp_int a_ = *a;
   a_.sign = ((a_.sign == MP_ZPOS) && !mp_iszero(a)) ? MP_NEG : MP_ZPOS;
   return mp_sub_d(&a_, 1uL, b);
}
#endif
