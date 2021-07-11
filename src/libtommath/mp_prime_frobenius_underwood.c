#include "tommath_private.h"
#ifdef MP_PRIME_FROBENIUS_UNDERWOOD_C

/* LibTomMath, multiple-precision integer library -- Tom St Denis */
/* SPDX-License-Identifier: Unlicense */

/*
 *  See file mp_prime_is_prime.c or the documentation in doc/bn.tex for the details
 */
#ifndef LTM_USE_ONLY_MR

/*
 * floor of positive solution of
 * (2^16)-1 = (a+4)*(2*a+5)
 * TODO: Both values are smaller than N^(1/4), would have to use a bigint
 *       for a instead but any a biger than about 120 are already so rare that
 *       it is possible to ignore them and still get enough pseudoprimes.
 *       But it is still a restriction of the set of available pseudoprimes
 *       which makes this implementation less secure if used stand-alone.
 */
#define LTM_FROBENIUS_UNDERWOOD_A 32764

mp_err mp_prime_frobenius_underwood(const mp_int *N, bool *result)
{
   mp_int T1z, T2z, Np1z, sz, tz;
   int a, ap2, i;
   mp_err err;

   if ((err = mp_init_multi(&T1z, &T2z, &Np1z, &sz, &tz, NULL)) != MP_OKAY) {
      return err;
   }

   for (a = 0; a < LTM_FROBENIUS_UNDERWOOD_A; a++) {
      int j;

      /* TODO: That's ugly! No, really, it is! */
      if ((a==2) || (a==4) || (a==7) || (a==8) || (a==10) ||
          (a==14) || (a==18) || (a==23) || (a==26) || (a==28)) {
         continue;
      }

      mp_set_i32(&T1z, (int32_t)((a * a) - 4));

      if ((err = mp_kronecker(&T1z, N, &j)) != MP_OKAY)           goto LBL_END;

      if (j == -1) {
         break;
      }

      if (j == 0) {
         /* composite */
         *result = false;
         goto LBL_END;
      }
   }
   /* Tell it a composite and set return value accordingly */
   if (a >= LTM_FROBENIUS_UNDERWOOD_A) {
      err = MP_ITER;
      goto LBL_END;
   }
   /* Composite if N and (a+4)*(2*a+5) are not coprime */
   mp_set_u32(&T1z, (uint32_t)((a+4)*((2*a)+5)));

   if ((err = mp_gcd(N, &T1z, &T1z)) != MP_OKAY)                  goto LBL_END;

   if (!((T1z.used == 1) && (T1z.dp[0] == 1u))) {
      /* composite */
      *result = false;
      goto LBL_END;
   }

   ap2 = a + 2;
   if ((err = mp_add_d(N, 1uL, &Np1z)) != MP_OKAY)                goto LBL_END;

   mp_set(&sz, 1uL);
   mp_set(&tz, 2uL);

   for (i = mp_count_bits(&Np1z) - 2; i >= 0; i--) {
      /*
       * temp = (sz*(a*sz+2*tz))%N;
       * tz   = ((tz-sz)*(tz+sz))%N;
       * sz   = temp;
       */
      if ((err = mp_mul_2(&tz, &T2z)) != MP_OKAY)                 goto LBL_END;

      /* a = 0 at about 50% of the cases (non-square and odd input) */
      if (a != 0) {
         if ((err = mp_mul_d(&sz, (mp_digit)a, &T1z)) != MP_OKAY) goto LBL_END;
         if ((err = mp_add(&T1z, &T2z, &T2z)) != MP_OKAY)         goto LBL_END;
      }

      if ((err = mp_mul(&T2z, &sz, &T1z)) != MP_OKAY)             goto LBL_END;
      if ((err = mp_sub(&tz, &sz, &T2z)) != MP_OKAY)              goto LBL_END;
      if ((err = mp_add(&sz, &tz, &sz)) != MP_OKAY)               goto LBL_END;
      if ((err = mp_mul(&sz, &T2z, &tz)) != MP_OKAY)              goto LBL_END;
      if ((err = mp_mod(&tz, N, &tz)) != MP_OKAY)                 goto LBL_END;
      if ((err = mp_mod(&T1z, N, &sz)) != MP_OKAY)                goto LBL_END;
      if (s_mp_get_bit(&Np1z, i)) {
         /*
          *  temp = (a+2) * sz + tz
          *  tz   = 2 * tz - sz
          *  sz   = temp
          */
         if (a == 0) {
            if ((err = mp_mul_2(&sz, &T1z)) != MP_OKAY)           goto LBL_END;
         } else {
            if ((err = mp_mul_d(&sz, (mp_digit)ap2, &T1z)) != MP_OKAY) goto LBL_END;
         }
         if ((err = mp_add(&T1z, &tz, &T1z)) != MP_OKAY)          goto LBL_END;
         if ((err = mp_mul_2(&tz, &T2z)) != MP_OKAY)              goto LBL_END;
         if ((err = mp_sub(&T2z, &sz, &tz)) != MP_OKAY)           goto LBL_END;
         mp_exch(&sz, &T1z);
      }
   }

   mp_set_u32(&T1z, (uint32_t)((2 * a) + 5));
   if ((err = mp_mod(&T1z, N, &T1z)) != MP_OKAY)                  goto LBL_END;

   *result = mp_iszero(&sz) && (mp_cmp(&tz, &T1z) == MP_EQ);

LBL_END:
   mp_clear_multi(&tz, &sz, &Np1z, &T2z, &T1z, NULL);
   return err;
}

#endif
#endif
