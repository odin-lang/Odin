/* LibTomMath, multiple-precision integer library -- Tom St Denis */
/* SPDX-License-Identifier: Unlicense */

/* super class file for PK algos */

/* default ... include all MPI */
#ifndef LTM_NOTHING
#define LTM_ALL
#endif

/* RSA only (does not support DH/DSA/ECC) */
/* #define SC_RSA_1 */
/* #define SC_RSA_1_WITH_TESTS */

/* For reference.... On an Athlon64 optimizing for speed...

   LTM's mpi.o with all functions [striped] is 142KiB in size.

*/

#ifdef SC_RSA_1_WITH_TESTS
#   define MP_ERROR_TO_STRING_C
#   define MP_FREAD_C
#   define MP_FWRITE_C
#   define MP_INCR_C
#   define MP_ISEVEN_C
#   define MP_ISODD_C
#   define MP_NEG_C
#   define MP_PRIME_FROBENIUS_UNDERWOOD_C
#   define MP_RADIX_SIZE_C
#   define MP_RADIX_SIZE_OVERESTIMATE_C
#   define MP_LOG_N_C
#   define MP_RAND_C
#   define MP_REDUCE_C
#   define MP_REDUCE_2K_L_C
#   define MP_FROM_SBIN_C
#   define MP_ROOT_N_C
#   define MP_SET_L_C
#   define MP_SET_UL_C
#   define MP_SET_U64_C
#   define MP_SET_I64_C
#   define MP_SBIN_SIZE_C
#   define MP_TO_RADIX_C
#   define MP_TO_SBIN_C
#   define S_MP_RAND_JENKINS_C
#   define S_MP_RAND_PLATFORM_C
#endif

/* Works for RSA only, mpi.o is 68KiB */
#if defined(SC_RSA_1) || defined (SC_RSA_1_WITH_TESTS)
#   define MP_CUTOFFS_C
#   define MP_ADDMOD_C
#   define MP_CLEAR_MULTI_C
#   define MP_EXPTMOD_C
#   define MP_GCD_C
#   define MP_INIT_MULTI_C
#   define MP_INVMOD_C
#   define MP_LCM_C
#   define MP_MOD_C
#   define MP_MOD_D_C
#   define MP_MULMOD_C
#   define MP_PRIME_IS_PRIME_C
#   define MP_PRIME_RABIN_MILLER_TRIALS_C
#   define MP_PRIME_RAND_C
#   define MP_SET_INT_C
#   define MP_SHRINK_C
#   define MP_TO_UNSIGNED_BIN_C
#   define MP_UNSIGNED_BIN_SIZE_C
#   define S_MP_PRIME_TAB_C
#   define S_MP_RADIX_MAP_C

/* other modifiers */



/* here we are on the last pass so we turn things off.  The functions classes are still there
 * but we remove them specifically from the build.  This also invokes tweaks in functions
 * like removing support for even moduli, etc...
 */
#   ifdef LTM_LAST
#      undef MP_DR_IS_MODULUS_C
#      undef MP_DR_REDUCE_C
#      undef MP_DR_SETUP_C
#      undef MP_REDUCE_2K_C
#      undef MP_REDUCE_2K_SETUP_C
#      undef MP_REDUCE_IS_2K_C
#      undef MP_REDUCE_SETUP_C
#      undef S_MP_DIV_3_C
#      undef S_MP_EXPTMOD_C
#      undef S_MP_INVMOD_ODD_C
#      undef S_MP_MUL_BALANCE_C
#      undef S_MP_MUL_HIGH_C
#      undef S_MP_MUL_HIGH_COMBA_C
#      undef S_MP_MUL_KARATSUBA_C
#      undef S_MP_MUL_TOOM_C
#      undef S_MP_SQR_KARATSUBA_C
#      undef S_MP_SQR_TOOM_C

#      ifndef SC_RSA_1_WITH_TESTS
#         undef MP_REDUCE_C
#      endif

/* To safely undefine these you have to make sure your RSA key won't exceed the Comba threshold
 * which is roughly 255 digits [7140 bits for 32-bit machines, 15300 bits for 64-bit machines]
 * which means roughly speaking you can handle upto 2536-bit RSA keys with these defined without
 * trouble.
 */
#      undef MP_MONTGOMERY_REDUCE_C
#      undef S_MP_MUL_C
#      undef S_MP_SQR_C
#   endif

#endif
