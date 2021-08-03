#include "tommath_private.h"
#ifdef S_MP_DIV_RECURSIVE_C
/* LibTomMath, multiple-precision integer library -- Tom St Denis */
/* SPDX-License-Identifier: Unlicense */

/*
   Direct implementation of algorithms 1.8 "RecursiveDivRem" and 1.9 "UnbalancedDivision"
   from:

      Brent, Richard P., and Paul Zimmermann. "Modern computer arithmetic"
      Vol. 18. Cambridge University Press, 2010
      Available online at https://arxiv.org/pdf/1004.4710

   pages 19ff. in the above online document.
*/

static mp_err s_recursion(const mp_int *a, const mp_int *b, mp_int *q, mp_int *r)
{
   mp_err err;
   mp_int A1, A2, B1, B0, Q1, Q0, R1, R0, t;
   int m = a->used - b->used, k = m/2;

   if (m < (MP_MUL_KARATSUBA_CUTOFF)) {
      return s_mp_div_school(a, b, q, r);
   }

   if ((err = mp_init_multi(&A1, &A2, &B1, &B0, &Q1, &Q0, &R1, &R0, &t, NULL)) != MP_OKAY) {
      goto LBL_ERR;
   }

   /* B1 = b / beta^k, B0 = b % beta^k*/
   if ((err = mp_div_2d(b, k * MP_DIGIT_BIT, &B1, &B0)) != MP_OKAY)        goto LBL_ERR;

   /* (Q1, R1) =  RecursiveDivRem(A / beta^(2k), B1) */
   if ((err = mp_div_2d(a, 2*k * MP_DIGIT_BIT, &A1, &t)) != MP_OKAY)       goto LBL_ERR;
   if ((err = s_recursion(&A1, &B1, &Q1, &R1)) != MP_OKAY)                 goto LBL_ERR;

   /* A1 = (R1 * beta^(2k)) + (A % beta^(2k)) - (Q1 * B0 * beta^k) */
   if ((err = mp_lshd(&R1, 2*k)) != MP_OKAY)                               goto LBL_ERR;
   if ((err = mp_add(&R1, &t, &A1)) != MP_OKAY)                            goto LBL_ERR;
   if ((err = mp_mul(&Q1, &B0, &t)) != MP_OKAY)                            goto LBL_ERR;
   if ((err = mp_lshd(&t, k)) != MP_OKAY)                                  goto LBL_ERR;
   if ((err = mp_sub(&A1, &t, &A1)) != MP_OKAY)                            goto LBL_ERR;

   /* while A1 < 0 do Q1 = Q1 - 1, A1 = A1 + (beta^k * B) */
   if (mp_cmp_d(&A1, 0uL) == MP_LT) {
      if ((err = mp_mul_2d(b, k * MP_DIGIT_BIT, &t)) != MP_OKAY)           goto LBL_ERR;
      do {
         if ((err = mp_decr(&Q1)) != MP_OKAY)                              goto LBL_ERR;
         if ((err = mp_add(&A1, &t, &A1)) != MP_OKAY)                      goto LBL_ERR;
      } while (mp_cmp_d(&A1, 0uL) == MP_LT);
   }
   /* (Q0, R0) =  RecursiveDivRem(A1 / beta^(k), B1) */
   if ((err = mp_div_2d(&A1, k * MP_DIGIT_BIT, &A1, &t)) != MP_OKAY)       goto LBL_ERR;
   if ((err = s_recursion(&A1, &B1, &Q0, &R0)) != MP_OKAY)                 goto LBL_ERR;

   /* A2 = (R0*beta^k) +  (A1 % beta^k) - (Q0*B0) */
   if ((err = mp_lshd(&R0, k)) != MP_OKAY)                                 goto LBL_ERR;
   if ((err = mp_add(&R0, &t, &A2)) != MP_OKAY)                            goto LBL_ERR;
   if ((err = mp_mul(&Q0, &B0, &t)) != MP_OKAY)                            goto LBL_ERR;
   if ((err = mp_sub(&A2, &t, &A2)) != MP_OKAY)                            goto LBL_ERR;

   /* while A2 < 0 do Q0 = Q0 - 1, A2 = A2 + B */
   while (mp_cmp_d(&A2, 0uL) == MP_LT) {
      if ((err = mp_decr(&Q0)) != MP_OKAY)                                 goto LBL_ERR;
      if ((err = mp_add(&A2, b, &A2)) != MP_OKAY)                          goto LBL_ERR;
   }
   /* return q = (Q1*beta^k) + Q0, r = A2 */
   if ((err = mp_lshd(&Q1, k)) != MP_OKAY)                                 goto LBL_ERR;
   if ((err = mp_add(&Q1, &Q0, q)) != MP_OKAY)                             goto LBL_ERR;

   if ((err = mp_copy(&A2, r)) != MP_OKAY)                                 goto LBL_ERR;

LBL_ERR:
   mp_clear_multi(&A1, &A2, &B1, &B0, &Q1, &Q0, &R1, &R0, &t, NULL);
   return err;
}


mp_err s_mp_div_recursive(const mp_int *a, const mp_int *b, mp_int *q, mp_int *r)
{
   int j, m, n, sigma;
   mp_err err;
   bool neg;
   mp_digit msb_b, msb;
   mp_int A, B, Q, Q1, R, A_div, A_mod;

   if ((err = mp_init_multi(&A, &B, &Q, &Q1, &R, &A_div, &A_mod, NULL)) != MP_OKAY) {
      goto LBL_ERR;
   }

   /* most significant bit of a limb */
   /* assumes  MP_DIGIT_MAX < (sizeof(mp_digit) * CHAR_BIT) */
   msb = (MP_DIGIT_MAX + (mp_digit)(1)) >> 1;
   sigma = 0;
   msb_b = b->dp[b->used - 1];
   while (msb_b < msb) {
      sigma++;
      msb_b <<= 1;
   }
   /* Use that sigma to normalize B */
   if ((err = mp_mul_2d(b, sigma, &B)) != MP_OKAY) {
      goto LBL_ERR;
   }
   if ((err = mp_mul_2d(a, sigma, &A)) != MP_OKAY) {
      goto LBL_ERR;
   }

   /* fix the sign */
   neg = (a->sign != b->sign);
   A.sign = B.sign = MP_ZPOS;

   /*
      If the magnitude of "A" is not more more than twice that of "B" we can work
      on them directly, otherwise we need to work at "A" in chunks
    */
   n = B.used;
   m = A.used - B.used;

   /* Q = 0 */
   mp_zero(&Q);
   while (m > n) {
      /* (q, r) = RecursiveDivRem(A / (beta^(m-n)), B) */
      j = (m - n) * MP_DIGIT_BIT;
      if ((err = mp_div_2d(&A, j, &A_div, &A_mod)) != MP_OKAY)                   goto LBL_ERR;
      if ((err = s_recursion(&A_div, &B, &Q1, &R)) != MP_OKAY)                goto LBL_ERR;
      /* Q = (Q*beta!(n)) + q */
      if ((err = mp_mul_2d(&Q, n * MP_DIGIT_BIT, &Q)) != MP_OKAY)                goto LBL_ERR;
      if ((err = mp_add(&Q, &Q1, &Q)) != MP_OKAY)                                goto LBL_ERR;
      /* A = (r * beta^(m-n)) + (A % beta^(m-n))*/
      if ((err = mp_mul_2d(&R, (m - n) * MP_DIGIT_BIT, &R)) != MP_OKAY)          goto LBL_ERR;
      if ((err = mp_add(&R, &A_mod, &A)) != MP_OKAY)                             goto LBL_ERR;
      /* m = m - n */
      m = m - n;
   }
   /* (q, r) = RecursiveDivRem(A, B) */
   if ((err = s_recursion(&A, &B, &Q1, &R)) != MP_OKAY)                       goto LBL_ERR;
   /* Q = (Q * beta^m) + q, R = r */
   if ((err = mp_mul_2d(&Q, m * MP_DIGIT_BIT, &Q)) != MP_OKAY)                   goto LBL_ERR;
   if ((err = mp_add(&Q, &Q1, &Q)) != MP_OKAY)                                   goto LBL_ERR;

   /* get sign before writing to c */
   R.sign = (mp_iszero(&Q) ? MP_ZPOS : a->sign);

   if (q != NULL) {
      mp_exch(&Q, q);
      q->sign = (neg ? MP_NEG : MP_ZPOS);
   }
   if (r != NULL) {
      /* de-normalize the remainder */
      if ((err = mp_div_2d(&R, sigma, &R, NULL)) != MP_OKAY)                      goto LBL_ERR;
      mp_exch(&R, r);
   }
LBL_ERR:
   mp_clear_multi(&A, &B, &Q, &Q1, &R, &A_div, &A_mod, NULL);
   return err;
}

#endif
