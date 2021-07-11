#include "tommath_private.h"
#ifdef S_MP_LOG_C
/* LibTomMath, multiple-precision integer library -- Tom St Denis */
/* SPDX-License-Identifier: Unlicense */

mp_err s_mp_log(const mp_int *a, mp_digit base, int *c)
{
   mp_err err;
   int high, low;
   mp_int bracket_low, bracket_high, bracket_mid, t, bi_base;

   mp_ord cmp = mp_cmp_d(a, base);
   if ((cmp == MP_LT) || (cmp == MP_EQ)) {
      *c = cmp == MP_EQ;
      return MP_OKAY;
   }

   if ((err =
           mp_init_multi(&bracket_low, &bracket_high,
                         &bracket_mid, &t, &bi_base, NULL)) != MP_OKAY) {
      return err;
   }

   low = 0;
   mp_set(&bracket_low, 1uL);
   high = 1;

   mp_set(&bracket_high, base);

   /*
       A kind of Giant-step/baby-step algorithm.
       Idea shamelessly stolen from https://programmingpraxis.com/2010/05/07/integer-logarithms/2/
       The effect is asymptotic, hence needs benchmarks to test if the Giant-step should be skipped
       for small n.
    */
   while (mp_cmp(&bracket_high, a) == MP_LT) {
      low = high;
      if ((err = mp_copy(&bracket_high, &bracket_low)) != MP_OKAY) {
         goto LBL_END;
      }
      high <<= 1;
      if ((err = mp_sqr(&bracket_high, &bracket_high)) != MP_OKAY) {
         goto LBL_END;
      }
   }
   mp_set(&bi_base, base);

   while ((high - low) > 1) {
      int mid = (high + low) >> 1;

      if ((err = mp_expt_n(&bi_base, mid - low, &t)) != MP_OKAY) {
         goto LBL_END;
      }
      if ((err = mp_mul(&bracket_low, &t, &bracket_mid)) != MP_OKAY) {
         goto LBL_END;
      }
      cmp = mp_cmp(a, &bracket_mid);
      if (cmp == MP_LT) {
         high = mid;
         mp_exch(&bracket_mid, &bracket_high);
      }
      if (cmp == MP_GT) {
         low = mid;
         mp_exch(&bracket_mid, &bracket_low);
      }
      if (cmp == MP_EQ) {
         *c = mid;
         goto LBL_END;
      }
   }

   *c = (mp_cmp(&bracket_high, a) == MP_EQ) ? high : low;

LBL_END:
   mp_clear_multi(&bracket_low, &bracket_high, &bracket_mid,
                  &t, &bi_base, NULL);
   return err;
}


#endif
