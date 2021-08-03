#include "tommath_private.h"
#ifdef MP_PRIME_MILLER_RABIN_C
/* LibTomMath, multiple-precision integer library -- Tom St Denis */
/* SPDX-License-Identifier: Unlicense */

/* Miller-Rabin test of "a" to the base of "b" as described in
 * HAC pp. 139 Algorithm 4.24
 *
 * Sets result to 0 if definitely composite or 1 if probably prime.
 * Randomly the chance of error is no more than 1/4 and often
 * very much lower.
 */
mp_err mp_prime_miller_rabin(const mp_int *a, const mp_int *b, bool *result)
{
   mp_int  n1, y, r;
   mp_err  err;
   int     s, j;

   /* ensure b > 1 */
   if (mp_cmp_d(b, 1uL) != MP_GT) {
      return MP_VAL;
   }

   /* get n1 = a - 1 */
   if ((err = mp_init_copy(&n1, a)) != MP_OKAY) {
      return err;
   }
   if ((err = mp_sub_d(&n1, 1uL, &n1)) != MP_OKAY) {
      goto LBL_ERR1;
   }

   /* set 2**s * r = n1 */
   if ((err = mp_init_copy(&r, &n1)) != MP_OKAY) {
      goto LBL_ERR1;
   }

   /* count the number of least significant bits
    * which are zero
    */
   s = mp_cnt_lsb(&r);

   /* now divide n - 1 by 2**s */
   if ((err = mp_div_2d(&r, s, &r, NULL)) != MP_OKAY) {
      goto LBL_ERR2;
   }

   /* compute y = b**r mod a */
   if ((err = mp_init(&y)) != MP_OKAY) {
      goto LBL_ERR2;
   }
   if ((err = mp_exptmod(b, &r, a, &y)) != MP_OKAY) {
      goto LBL_END;
   }

   /* if y != 1 and y != n1 do */
   if ((mp_cmp_d(&y, 1uL) != MP_EQ) && (mp_cmp(&y, &n1) != MP_EQ)) {
      j = 1;
      /* while j <= s-1 and y != n1 */
      while ((j <= (s - 1)) && (mp_cmp(&y, &n1) != MP_EQ)) {
         if ((err = mp_sqrmod(&y, a, &y)) != MP_OKAY) {
            goto LBL_END;
         }

         /* if y == 1 then composite */
         if (mp_cmp_d(&y, 1uL) == MP_EQ) {
            *result = false;
            goto LBL_END;
         }

         ++j;
      }

      /* if y != n1 then composite */
      if (mp_cmp(&y, &n1) != MP_EQ) {
         *result = false;
         goto LBL_END;
      }
   }

   /* probably prime now */
   *result = true;

LBL_END:
   mp_clear(&y);
LBL_ERR2:
   mp_clear(&r);
LBL_ERR1:
   mp_clear(&n1);
   return err;
}
#endif
