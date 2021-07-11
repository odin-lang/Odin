#include "tommath_private.h"
#ifdef MP_CUTOFFS_C
/* LibTomMath, multiple-precision integer library -- Tom St Denis */
/* SPDX-License-Identifier: Unlicense */

#ifndef MP_FIXED_CUTOFFS
#include "tommath_cutoffs.h"
int MP_MUL_KARATSUBA_CUTOFF = MP_DEFAULT_MUL_KARATSUBA_CUTOFF,
    MP_SQR_KARATSUBA_CUTOFF = MP_DEFAULT_SQR_KARATSUBA_CUTOFF,
    MP_MUL_TOOM_CUTOFF = MP_DEFAULT_MUL_TOOM_CUTOFF,
    MP_SQR_TOOM_CUTOFF = MP_DEFAULT_SQR_TOOM_CUTOFF;
#endif

#endif
