#include "tommath_private.h"
#ifdef S_MP_RADIX_SIZE_OVERESTIMATE_C
/* LibTomMath, multiple-precision integer library -- Tom St Denis */
/* SPDX-License-Identifier: Unlicense */

/*
   Overestimate the size needed for the bigint to string conversion by a very small amount.
   The error is about 10^-8; it will overestimate the result by at most 11 elements for
   a number of the size 2^(2^31)-1 which is currently the largest possible in this library.
   Some short tests gave no results larger than 5 (plus 2 for sign and EOS).
 */

/*
   Table of {0, INT(log_2([1..64])*2^p)+1 } where p is the scale
   factor defined in MP_RADIX_SIZE_SCALE and INT() extracts the integer part (truncating).
   Good for 32 bit "int". Set MP_RADIX_SIZE_SCALE = 61 and recompute values
   for 64 bit "int".
 */
/* *INDENT-OFF* */
#define MP_RADIX_SIZE_SCALE 29
static const uint32_t s_log_bases[65] = {
           0u,         0u, 0x20000001u, 0x14309399u, 0x10000001u,
   0xdc81a35u, 0xc611924u, 0xb660c9eu,   0xaaaaaabu,  0xa1849cdu,
   0x9a209a9u, 0x94004e1u, 0x8ed19c2u,   0x8a5ca7du,  0x867a000u,
   0x830cee3u, 0x8000001u, 0x7d42d60u,   0x7ac8b32u,  0x7887847u,
   0x7677349u, 0x749131fu, 0x72d0163u,   0x712f657u,  0x6fab5dbu,
   0x6e40d1bu, 0x6ced0d0u, 0x6badbdeu,   0x6a80e3bu,  0x6964c19u,
   0x6857d31u, 0x6758c38u, 0x6666667u,   0x657fb21u,  0x64a3b9fu,
   0x63d1ab4u, 0x6308c92u, 0x624869eu,   0x618ff47u,  0x60dedeau,
   0x6034ab0u, 0x5f90e7bu, 0x5ef32cbu,   0x5e5b1b2u,  0x5dc85c3u,
   0x5d3aa02u, 0x5cb19d9u, 0x5c2d10fu,   0x5bacbbfu,  0x5b3064fu,
   0x5ab7d68u, 0x5a42df0u, 0x59d1506u,   0x5962ffeu,  0x58f7c57u,
   0x588f7bcu, 0x582a000u, 0x57c7319u,   0x5766f1du,  0x5709243u,
   0x56adad9u, 0x565474du, 0x55fd61fu,   0x55a85e8u,  0x5555556u
};
/* *INDENT-ON* */

mp_err s_mp_radix_size_overestimate(const mp_int *a, const int radix, size_t *size)
{
   int bit_count;
   mp_int bi_bit_count, bi_k;
   mp_err err = MP_OKAY;

   if ((radix < 2) || (radix > 64)) {
      return MP_VAL;
   }

   if (mp_iszero(a)) {
      *size = 2U;
      return MP_OKAY;
   }

   if (MP_HAS(S_MP_LOG_2EXPT) && MP_IS_2EXPT((mp_digit)radix)) {
      /* floor(log_{2^n}(a)) + 1 + EOS + sign */
      *size = (size_t)(s_mp_log_2expt(a, (mp_digit)radix) + 3);
      return MP_OKAY;
   }

   if ((err = mp_init_multi(&bi_bit_count, &bi_k, NULL)) != MP_OKAY) {
      return err;
   }

   /* la = floor(log_2(a)) + 1 */
   bit_count = mp_count_bits(a);

   mp_set_u32(&bi_bit_count, (uint32_t)bit_count);
   /* k = floor(2^29/log_2(radix)) + 1 */
   mp_set_u32(&bi_k, s_log_bases[radix]);
   /* n = floor((la *  k) / 2^29) + 1 */
   if ((err = mp_mul(&bi_bit_count, &bi_k, &bi_bit_count)) != MP_OKAY)                         goto LBL_ERR;
   if ((err = mp_div_2d(&bi_bit_count, MP_RADIX_SIZE_SCALE, &bi_bit_count, NULL)) != MP_OKAY) goto LBL_ERR;

   /* The "+1" here is the "+1" in "floor((la *  k) / 2^29) + 1" */
   /* n = n + 1 + EOS + sign */
   *size = (size_t)(mp_get_u64(&bi_bit_count) + 3U);

LBL_ERR:
   mp_clear_multi(&bi_bit_count, &bi_k, NULL);
   return err;
}

#endif
