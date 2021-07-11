#include "tommath_private.h"
#ifdef MP_PRIME_NEXT_PRIME_C
/* LibTomMath, multiple-precision integer library -- Tom St Denis */
/* SPDX-License-Identifier: Unlicense */

/* finds the next prime after the number "a" using "t" trials
 * of Miller-Rabin.
 *
 * bbs_style = true means the prime must be congruent to 3 mod 4
 */
mp_err mp_prime_next_prime(mp_int *a, int t, bool bbs_style)
{
   int      x;
   mp_err   err;
   bool  res = false;
   mp_digit res_tab[MP_PRIME_TAB_SIZE], kstep;
   mp_int   b;

   /* force positive */
   a->sign = MP_ZPOS;

   /* simple algo if a is less than the largest prime in the table */
   if (mp_cmp_d(a, s_mp_prime_tab[MP_PRIME_TAB_SIZE-1]) == MP_LT) {
      /* find which prime it is bigger than "a" */
      for (x = 0; x < MP_PRIME_TAB_SIZE; x++) {
         mp_ord cmp = mp_cmp_d(a, s_mp_prime_tab[x]);
         if (cmp == MP_EQ) {
            continue;
         }
         if (cmp != MP_GT) {
            if ((bbs_style) && ((s_mp_prime_tab[x] & 3u) != 3u)) {
               /* try again until we get a prime congruent to 3 mod 4 */
               continue;
            } else {
               mp_set(a, s_mp_prime_tab[x]);
               return MP_OKAY;
            }
         }
      }
      /* fall through to the sieve */
   }

   /* generate a prime congruent to 3 mod 4 or 1/3 mod 4? */
   kstep = bbs_style ? 4 : 2;

   /* at this point we will use a combination of a sieve and Miller-Rabin */

   if (bbs_style) {
      /* if a mod 4 != 3 subtract the correct value to make it so */
      if ((a->dp[0] & 3u) != 3u) {
         if ((err = mp_sub_d(a, (a->dp[0] & 3u) + 1u, a)) != MP_OKAY) {
            return err;
         }
      }
   } else {
      if (mp_iseven(a)) {
         /* force odd */
         if ((err = mp_sub_d(a, 1uL, a)) != MP_OKAY) {
            return err;
         }
      }
   }

   /* generate the restable */
   for (x = 1; x < MP_PRIME_TAB_SIZE; x++) {
      if ((err = mp_mod_d(a, s_mp_prime_tab[x], res_tab + x)) != MP_OKAY) {
         return err;
      }
   }

   /* init temp used for Miller-Rabin Testing */
   if ((err = mp_init(&b)) != MP_OKAY) {
      return err;
   }

   for (;;) {
      mp_digit step = 0;
      bool y;
      /* skip to the next non-trivially divisible candidate */
      do {
         /* y == true if any residue was zero [e.g. cannot be prime] */
         y     = false;

         /* increase step to next candidate */
         step += kstep;

         /* compute the new residue without using division */
         for (x = 1; x < MP_PRIME_TAB_SIZE; x++) {
            /* add the step to each residue */
            res_tab[x] += kstep;

            /* subtract the modulus [instead of using division] */
            if (res_tab[x] >= s_mp_prime_tab[x]) {
               res_tab[x]  -= s_mp_prime_tab[x];
            }

            /* set flag if zero */
            if (res_tab[x] == 0u) {
               y = true;
            }
         }
      } while (y && (step < (((mp_digit)1 << MP_DIGIT_BIT) - kstep)));

      /* add the step */
      if ((err = mp_add_d(a, step, a)) != MP_OKAY) {
         goto LBL_ERR;
      }

      /* if didn't pass sieve and step == MP_MAX then skip test */
      if (y && (step >= (((mp_digit)1 << MP_DIGIT_BIT) - kstep))) {
         continue;
      }

      if ((err = mp_prime_is_prime(a, t, &res)) != MP_OKAY) {
         goto LBL_ERR;
      }
      if (res) {
         break;
      }
   }

LBL_ERR:
   mp_clear(&b);
   return err;
}

#endif
