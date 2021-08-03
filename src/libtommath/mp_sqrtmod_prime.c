#include "tommath_private.h"
#ifdef MP_SQRTMOD_PRIME_C
/* LibTomMath, multiple-precision integer library -- Tom St Denis */
/* SPDX-License-Identifier: Unlicense */

/* Tonelli-Shanks algorithm
 * https://en.wikipedia.org/wiki/Tonelli%E2%80%93Shanks_algorithm
 * https://gmplib.org/list-archives/gmp-discuss/2013-April/005300.html
 *
 */

mp_err mp_sqrtmod_prime(const mp_int *n, const mp_int *prime, mp_int *ret)
{
   mp_err err;
   int legendre;
   /* The type is "int" because of the types in the mp_int struct.
      Don't forget to change them here when you change them there! */
   int S, M, i;
   mp_int t1, C, Q, Z, T, R, two;

   /* first handle the simple cases */
   if (mp_cmp_d(n, 0uL) == MP_EQ) {
      mp_zero(ret);
      return MP_OKAY;
   }
   /* "prime" must be odd and > 2 */
   if (mp_iseven(prime) || (mp_cmp_d(prime, 3uL) == MP_LT))      return MP_VAL;
   if ((err = mp_kronecker(n, prime, &legendre)) != MP_OKAY)     return err;
   /* n \not\cong 0 (mod p) and n \cong r^2 (mod p) for some r \in N^+ */
   if (legendre != 1)                                            return MP_VAL;

   if ((err = mp_init_multi(&t1, &C, &Q, &Z, &T, &R, &two, NULL)) != MP_OKAY) {
      return err;
   }

   /* SPECIAL CASE: if prime mod 4 == 3
    * compute directly: err = n^(prime+1)/4 mod prime
    * Handbook of Applied Cryptography algorithm 3.36
    */
   /* x%4 == x&3 for x in N and x>0 */
   if ((prime->dp[0] & 3u) == 3u) {
      if ((err = mp_add_d(prime, 1uL, &t1)) != MP_OKAY)           goto LBL_END;
      if ((err = mp_div_2(&t1, &t1)) != MP_OKAY)                  goto LBL_END;
      if ((err = mp_div_2(&t1, &t1)) != MP_OKAY)                  goto LBL_END;
      if ((err = mp_exptmod(n, &t1, prime, ret)) != MP_OKAY)      goto LBL_END;
      err = MP_OKAY;
      goto LBL_END;
   }

   /* NOW: Tonelli-Shanks algorithm */

   /* factor out powers of 2 from prime-1, defining Q and S as: prime-1 = Q*2^S */
   if ((err = mp_copy(prime, &Q)) != MP_OKAY)                    goto LBL_END;
   if ((err = mp_sub_d(&Q, 1uL, &Q)) != MP_OKAY)                 goto LBL_END;
   /* Q = prime - 1 */
   S = 0;
   /* S = 0 */
   while (mp_iseven(&Q)) {
      if ((err = mp_div_2(&Q, &Q)) != MP_OKAY)                    goto LBL_END;
      /* Q = Q / 2 */
      S++;
      /* S = S + 1 */
   }

   /* find a Z such that the Legendre symbol (Z|prime) == -1 */
   mp_set(&Z, 2uL);
   /* Z = 2 */
   for (;;) {
      if ((err = mp_kronecker(&Z, prime, &legendre)) != MP_OKAY)     goto LBL_END;
      /* If "prime" (p) is an odd prime Jacobi(k|p) = 0 for k \cong 0 (mod p) */
      /* but there is at least one non-quadratic residue before k>=p if p is an odd prime. */
      if (legendre == 0) {
         err = MP_VAL;
         goto LBL_END;
      }
      if (legendre == -1) break;
      if ((err = mp_add_d(&Z, 1uL, &Z)) != MP_OKAY)               goto LBL_END;
      /* Z = Z + 1 */
   }

   if ((err = mp_exptmod(&Z, &Q, prime, &C)) != MP_OKAY)         goto LBL_END;
   /* C = Z ^ Q mod prime */
   if ((err = mp_add_d(&Q, 1uL, &t1)) != MP_OKAY)                goto LBL_END;
   if ((err = mp_div_2(&t1, &t1)) != MP_OKAY)                    goto LBL_END;
   /* t1 = (Q + 1) / 2 */
   if ((err = mp_exptmod(n, &t1, prime, &R)) != MP_OKAY)         goto LBL_END;
   /* R = n ^ ((Q + 1) / 2) mod prime */
   if ((err = mp_exptmod(n, &Q, prime, &T)) != MP_OKAY)          goto LBL_END;
   /* T = n ^ Q mod prime */
   M = S;
   /* M = S */
   mp_set(&two, 2uL);

   for (;;) {
      if ((err = mp_copy(&T, &t1)) != MP_OKAY)                    goto LBL_END;
      i = 0;
      for (;;) {
         if (mp_cmp_d(&t1, 1uL) == MP_EQ) break;
         /*  No exponent in the range 0 < i < M found
            (M is at least 1 in the first round because "prime" > 2) */
         if (M == i) {
            err = MP_VAL;
            goto LBL_END;
         }
         if ((err = mp_exptmod(&t1, &two, prime, &t1)) != MP_OKAY) goto LBL_END;
         i++;
      }
      if (i == 0) {
         if ((err = mp_copy(&R, ret)) != MP_OKAY)                  goto LBL_END;
         err = MP_OKAY;
         goto LBL_END;
      }
      mp_set_i32(&t1, M - i - 1);
      if ((err = mp_exptmod(&two, &t1, prime, &t1)) != MP_OKAY)   goto LBL_END;
      /* t1 = 2 ^ (M - i - 1) */
      if ((err = mp_exptmod(&C, &t1, prime, &t1)) != MP_OKAY)     goto LBL_END;
      /* t1 = C ^ (2 ^ (M - i - 1)) mod prime */
      if ((err = mp_sqrmod(&t1, prime, &C)) != MP_OKAY)           goto LBL_END;
      /* C = (t1 * t1) mod prime */
      if ((err = mp_mulmod(&R, &t1, prime, &R)) != MP_OKAY)       goto LBL_END;
      /* R = (R * t1) mod prime */
      if ((err = mp_mulmod(&T, &C, prime, &T)) != MP_OKAY)        goto LBL_END;
      /* T = (T * C) mod prime */
      M = i;
      /* M = i */
   }

LBL_END:
   mp_clear_multi(&t1, &C, &Q, &Z, &T, &R, &two, NULL);
   return err;
}

#endif
