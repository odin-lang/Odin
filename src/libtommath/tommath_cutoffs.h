/* LibTomMath, multiple-precision integer library -- Tom St Denis */
/* SPDX-License-Identifier: Unlicense */
/*
   Current values evaluated on an AMD A8-6600K (64-bit).
   Type "make tune" to optimize them for your machine but
   be aware that it may take a long time. It took 2:30 minutes
   on the aforementioned machine for example.
 */

#define MP_DEFAULT_MUL_KARATSUBA_CUTOFF 80
#define MP_DEFAULT_SQR_KARATSUBA_CUTOFF 120
#define MP_DEFAULT_MUL_TOOM_CUTOFF      350
#define MP_DEFAULT_SQR_TOOM_CUTOFF      400
