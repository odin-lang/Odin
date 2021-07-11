/* LibTomMath, multiple-precision integer library -- Tom St Denis */
/* SPDX-License-Identifier: Unlicense */

#if !(defined(LTM1) && defined(LTM2) && defined(LTM3))
#define LTM_INSIDE
#if defined(LTM2)
#   define LTM3
#endif
#if defined(LTM1)
#   define LTM2
#endif
#define LTM1
#if defined(LTM_ALL)
#   define MP_2EXPT_C
#   define MP_ABS_C
#   define MP_ADD_C
#   define MP_ADD_D_C
#   define MP_ADDMOD_C
#   define MP_AND_C
#   define MP_CLAMP_C
#   define MP_CLEAR_C
#   define MP_CLEAR_MULTI_C
#   define MP_CMP_C
#   define MP_CMP_D_C
#   define MP_CMP_MAG_C
#   define MP_CNT_LSB_C
#   define MP_COMPLEMENT_C
#   define MP_COPY_C
#   define MP_COUNT_BITS_C
#   define MP_CUTOFFS_C
#   define MP_DIV_C
#   define MP_DIV_2_C
#   define MP_DIV_2D_C
#   define MP_DIV_D_C
#   define MP_DR_IS_MODULUS_C
#   define MP_DR_REDUCE_C
#   define MP_DR_SETUP_C
#   define MP_ERROR_TO_STRING_C
#   define MP_EXCH_C
#   define MP_EXPT_N_C
#   define MP_EXPTMOD_C
#   define MP_EXTEUCLID_C
#   define MP_FREAD_C
#   define MP_FROM_SBIN_C
#   define MP_FROM_UBIN_C
#   define MP_FWRITE_C
#   define MP_GCD_C
#   define MP_GET_DOUBLE_C
#   define MP_GET_I32_C
#   define MP_GET_I64_C
#   define MP_GET_L_C
#   define MP_GET_MAG_U32_C
#   define MP_GET_MAG_U64_C
#   define MP_GET_MAG_UL_C
#   define MP_GROW_C
#   define MP_INIT_C
#   define MP_INIT_COPY_C
#   define MP_INIT_I32_C
#   define MP_INIT_I64_C
#   define MP_INIT_L_C
#   define MP_INIT_MULTI_C
#   define MP_INIT_SET_C
#   define MP_INIT_SIZE_C
#   define MP_INIT_U32_C
#   define MP_INIT_U64_C
#   define MP_INIT_UL_C
#   define MP_INVMOD_C
#   define MP_IS_SQUARE_C
#   define MP_KRONECKER_C
#   define MP_LCM_C
#   define MP_LOG_N_C
#   define MP_LSHD_C
#   define MP_MOD_C
#   define MP_MOD_2D_C
#   define MP_MONTGOMERY_CALC_NORMALIZATION_C
#   define MP_MONTGOMERY_REDUCE_C
#   define MP_MONTGOMERY_SETUP_C
#   define MP_MUL_C
#   define MP_MUL_2_C
#   define MP_MUL_2D_C
#   define MP_MUL_D_C
#   define MP_MULMOD_C
#   define MP_NEG_C
#   define MP_OR_C
#   define MP_PACK_C
#   define MP_PACK_COUNT_C
#   define MP_PRIME_FERMAT_C
#   define MP_PRIME_FROBENIUS_UNDERWOOD_C
#   define MP_PRIME_IS_PRIME_C
#   define MP_PRIME_MILLER_RABIN_C
#   define MP_PRIME_NEXT_PRIME_C
#   define MP_PRIME_RABIN_MILLER_TRIALS_C
#   define MP_PRIME_RAND_C
#   define MP_PRIME_STRONG_LUCAS_SELFRIDGE_C
#   define MP_RADIX_SIZE_C
#   define MP_RADIX_SIZE_OVERESTIMATE_C
#   define MP_RAND_C
#   define MP_RAND_SOURCE_C
#   define MP_READ_RADIX_C
#   define MP_REDUCE_C
#   define MP_REDUCE_2K_C
#   define MP_REDUCE_2K_L_C
#   define MP_REDUCE_2K_SETUP_C
#   define MP_REDUCE_2K_SETUP_L_C
#   define MP_REDUCE_IS_2K_C
#   define MP_REDUCE_IS_2K_L_C
#   define MP_REDUCE_SETUP_C
#   define MP_ROOT_N_C
#   define MP_RSHD_C
#   define MP_SBIN_SIZE_C
#   define MP_SET_C
#   define MP_SET_DOUBLE_C
#   define MP_SET_I32_C
#   define MP_SET_I64_C
#   define MP_SET_L_C
#   define MP_SET_U32_C
#   define MP_SET_U64_C
#   define MP_SET_UL_C
#   define MP_SHRINK_C
#   define MP_SIGNED_RSH_C
#   define MP_SQRMOD_C
#   define MP_SQRT_C
#   define MP_SQRTMOD_PRIME_C
#   define MP_SUB_C
#   define MP_SUB_D_C
#   define MP_SUBMOD_C
#   define MP_TO_RADIX_C
#   define MP_TO_SBIN_C
#   define MP_TO_UBIN_C
#   define MP_UBIN_SIZE_C
#   define MP_UNPACK_C
#   define MP_XOR_C
#   define MP_ZERO_C
#   define S_MP_ADD_C
#   define S_MP_COPY_DIGS_C
#   define S_MP_DIV_3_C
#   define S_MP_DIV_RECURSIVE_C
#   define S_MP_DIV_SCHOOL_C
#   define S_MP_DIV_SMALL_C
#   define S_MP_EXPTMOD_C
#   define S_MP_EXPTMOD_FAST_C
#   define S_MP_GET_BIT_C
#   define S_MP_INVMOD_C
#   define S_MP_INVMOD_ODD_C
#   define S_MP_LOG_C
#   define S_MP_LOG_2EXPT_C
#   define S_MP_LOG_D_C
#   define S_MP_MONTGOMERY_REDUCE_COMBA_C
#   define S_MP_MUL_C
#   define S_MP_MUL_BALANCE_C
#   define S_MP_MUL_COMBA_C
#   define S_MP_MUL_HIGH_C
#   define S_MP_MUL_HIGH_COMBA_C
#   define S_MP_MUL_KARATSUBA_C
#   define S_MP_MUL_TOOM_C
#   define S_MP_PRIME_IS_DIVISIBLE_C
#   define S_MP_PRIME_TAB_C
#   define S_MP_RADIX_MAP_C
#   define S_MP_RADIX_SIZE_OVERESTIMATE_C
#   define S_MP_RAND_PLATFORM_C
#   define S_MP_SQR_C
#   define S_MP_SQR_COMBA_C
#   define S_MP_SQR_KARATSUBA_C
#   define S_MP_SQR_TOOM_C
#   define S_MP_SUB_C
#   define S_MP_ZERO_BUF_C
#   define S_MP_ZERO_DIGS_C
#endif
#endif
#if defined(MP_2EXPT_C)
#   define MP_GROW_C
#   define MP_ZERO_C
#endif

#if defined(MP_ABS_C)
#   define MP_COPY_C
#endif

#if defined(MP_ADD_C)
#   define MP_CMP_MAG_C
#   define S_MP_ADD_C
#   define S_MP_SUB_C
#endif

#if defined(MP_ADD_D_C)
#   define MP_CLAMP_C
#   define MP_GROW_C
#   define MP_SUB_D_C
#   define S_MP_ZERO_DIGS_C
#endif

#if defined(MP_ADDMOD_C)
#   define MP_ADD_C
#   define MP_MOD_C
#endif

#if defined(MP_AND_C)
#   define MP_CLAMP_C
#   define MP_GROW_C
#endif

#if defined(MP_CLAMP_C)
#endif

#if defined(MP_CLEAR_C)
#   define S_MP_ZERO_DIGS_C
#endif

#if defined(MP_CLEAR_MULTI_C)
#   define MP_CLEAR_C
#endif

#if defined(MP_CMP_C)
#   define MP_CMP_MAG_C
#endif

#if defined(MP_CMP_D_C)
#endif

#if defined(MP_CMP_MAG_C)
#endif

#if defined(MP_CNT_LSB_C)
#endif

#if defined(MP_COMPLEMENT_C)
#   define MP_SUB_D_C
#endif

#if defined(MP_COPY_C)
#   define MP_GROW_C
#   define S_MP_COPY_DIGS_C
#   define S_MP_ZERO_DIGS_C
#endif

#if defined(MP_COUNT_BITS_C)
#endif

#if defined(MP_CUTOFFS_C)
#endif

#if defined(MP_DIV_C)
#   define MP_CMP_MAG_C
#   define MP_COPY_C
#   define MP_ZERO_C
#   define S_MP_DIV_RECURSIVE_C
#   define S_MP_DIV_SCHOOL_C
#   define S_MP_DIV_SMALL_C
#endif

#if defined(MP_DIV_2_C)
#   define MP_CLAMP_C
#   define MP_GROW_C
#   define S_MP_ZERO_DIGS_C
#endif

#if defined(MP_DIV_2D_C)
#   define MP_CLAMP_C
#   define MP_COPY_C
#   define MP_MOD_2D_C
#   define MP_RSHD_C
#endif

#if defined(MP_DIV_D_C)
#   define MP_CLAMP_C
#   define MP_CLEAR_C
#   define MP_COPY_C
#   define MP_DIV_2D_C
#   define MP_DIV_2_C
#   define MP_EXCH_C
#   define MP_INIT_SIZE_C
#   define S_MP_DIV_3_C
#endif

#if defined(MP_DR_IS_MODULUS_C)
#endif

#if defined(MP_DR_REDUCE_C)
#   define MP_CLAMP_C
#   define MP_CMP_MAG_C
#   define MP_GROW_C
#   define S_MP_SUB_C
#   define S_MP_ZERO_DIGS_C
#endif

#if defined(MP_DR_SETUP_C)
#endif

#if defined(MP_ERROR_TO_STRING_C)
#endif

#if defined(MP_EXCH_C)
#endif

#if defined(MP_EXPT_N_C)
#   define MP_CLEAR_C
#   define MP_INIT_COPY_C
#   define MP_MUL_C
#   define MP_SET_C
#endif

#if defined(MP_EXPTMOD_C)
#   define MP_ABS_C
#   define MP_CLEAR_MULTI_C
#   define MP_DR_IS_MODULUS_C
#   define MP_INIT_MULTI_C
#   define MP_INVMOD_C
#   define MP_REDUCE_IS_2K_C
#   define MP_REDUCE_IS_2K_L_C
#   define S_MP_EXPTMOD_C
#   define S_MP_EXPTMOD_FAST_C
#endif

#if defined(MP_EXTEUCLID_C)
#   define MP_CLEAR_MULTI_C
#   define MP_COPY_C
#   define MP_DIV_C
#   define MP_EXCH_C
#   define MP_INIT_MULTI_C
#   define MP_MUL_C
#   define MP_NEG_C
#   define MP_SET_C
#   define MP_SUB_C
#endif

#if defined(MP_FREAD_C)
#   define MP_ADD_D_C
#   define MP_MUL_D_C
#   define MP_ZERO_C
#endif

#if defined(MP_FROM_SBIN_C)
#   define MP_FROM_UBIN_C
#endif

#if defined(MP_FROM_UBIN_C)
#   define MP_CLAMP_C
#   define MP_GROW_C
#   define MP_MUL_2D_C
#   define MP_ZERO_C
#endif

#if defined(MP_FWRITE_C)
#   define MP_RADIX_SIZE_OVERESTIMATE_C
#   define MP_TO_RADIX_C
#   define S_MP_ZERO_BUF_C
#endif

#if defined(MP_GCD_C)
#   define MP_ABS_C
#   define MP_CLEAR_C
#   define MP_CMP_MAG_C
#   define MP_CNT_LSB_C
#   define MP_DIV_2D_C
#   define MP_EXCH_C
#   define MP_INIT_COPY_C
#   define MP_MUL_2D_C
#   define S_MP_SUB_C
#endif

#if defined(MP_GET_DOUBLE_C)
#endif

#if defined(MP_GET_I32_C)
#   define MP_GET_MAG_U32_C
#endif

#if defined(MP_GET_I64_C)
#   define MP_GET_MAG_U64_C
#endif

#if defined(MP_GET_L_C)
#   define MP_GET_MAG_UL_C
#endif

#if defined(MP_GET_MAG_U32_C)
#endif

#if defined(MP_GET_MAG_U64_C)
#endif

#if defined(MP_GET_MAG_UL_C)
#endif

#if defined(MP_GROW_C)
#   define S_MP_ZERO_DIGS_C
#endif

#if defined(MP_INIT_C)
#endif

#if defined(MP_INIT_COPY_C)
#   define MP_CLEAR_C
#   define MP_COPY_C
#   define MP_INIT_SIZE_C
#endif

#if defined(MP_INIT_I32_C)
#   define MP_INIT_C
#   define MP_SET_I32_C
#endif

#if defined(MP_INIT_I64_C)
#   define MP_INIT_C
#   define MP_SET_I64_C
#endif

#if defined(MP_INIT_L_C)
#   define MP_INIT_C
#   define MP_SET_L_C
#endif

#if defined(MP_INIT_MULTI_C)
#   define MP_CLEAR_C
#   define MP_INIT_C
#endif

#if defined(MP_INIT_SET_C)
#   define MP_INIT_C
#   define MP_SET_C
#endif

#if defined(MP_INIT_SIZE_C)
#endif

#if defined(MP_INIT_U32_C)
#   define MP_INIT_C
#   define MP_SET_U32_C
#endif

#if defined(MP_INIT_U64_C)
#   define MP_INIT_C
#   define MP_SET_U64_C
#endif

#if defined(MP_INIT_UL_C)
#   define MP_INIT_C
#   define MP_SET_UL_C
#endif

#if defined(MP_INVMOD_C)
#   define MP_CMP_D_C
#   define MP_ZERO_C
#   define S_MP_INVMOD_C
#   define S_MP_INVMOD_ODD_C
#endif

#if defined(MP_IS_SQUARE_C)
#   define MP_CLEAR_C
#   define MP_CMP_MAG_C
#   define MP_DIV_D_C
#   define MP_GET_I32_C
#   define MP_INIT_U32_C
#   define MP_MOD_C
#   define MP_MUL_C
#   define MP_SQRT_C
#endif

#if defined(MP_KRONECKER_C)
#   define MP_CLEAR_C
#   define MP_CMP_D_C
#   define MP_CNT_LSB_C
#   define MP_COPY_C
#   define MP_DIV_2D_C
#   define MP_INIT_C
#   define MP_INIT_COPY_C
#   define MP_MOD_C
#endif

#if defined(MP_LCM_C)
#   define MP_CLEAR_MULTI_C
#   define MP_CMP_MAG_C
#   define MP_DIV_C
#   define MP_GCD_C
#   define MP_INIT_MULTI_C
#   define MP_MUL_C
#endif

#if defined(MP_LOG_N_C)
#   define S_MP_LOG_2EXPT_C
#   define S_MP_LOG_C
#   define S_MP_LOG_D_C
#endif

#if defined(MP_LSHD_C)
#   define MP_GROW_C
#   define S_MP_ZERO_DIGS_C
#endif

#if defined(MP_MOD_C)
#   define MP_ADD_C
#   define MP_DIV_C
#endif

#if defined(MP_MOD_2D_C)
#   define MP_CLAMP_C
#   define MP_COPY_C
#   define MP_ZERO_C
#   define S_MP_ZERO_DIGS_C
#endif

#if defined(MP_MONTGOMERY_CALC_NORMALIZATION_C)
#   define MP_2EXPT_C
#   define MP_CMP_MAG_C
#   define MP_COUNT_BITS_C
#   define MP_MUL_2_C
#   define MP_SET_C
#   define S_MP_SUB_C
#endif

#if defined(MP_MONTGOMERY_REDUCE_C)
#   define MP_CLAMP_C
#   define MP_CMP_MAG_C
#   define MP_GROW_C
#   define MP_RSHD_C
#   define S_MP_MONTGOMERY_REDUCE_COMBA_C
#   define S_MP_SUB_C
#endif

#if defined(MP_MONTGOMERY_SETUP_C)
#endif

#if defined(MP_MUL_C)
#   define S_MP_MUL_BALANCE_C
#   define S_MP_MUL_C
#   define S_MP_MUL_COMBA_C
#   define S_MP_MUL_KARATSUBA_C
#   define S_MP_MUL_TOOM_C
#   define S_MP_SQR_C
#   define S_MP_SQR_COMBA_C
#   define S_MP_SQR_KARATSUBA_C
#   define S_MP_SQR_TOOM_C
#endif

#if defined(MP_MUL_2_C)
#   define MP_GROW_C
#   define S_MP_ZERO_DIGS_C
#endif

#if defined(MP_MUL_2D_C)
#   define MP_CLAMP_C
#   define MP_COPY_C
#   define MP_GROW_C
#   define MP_LSHD_C
#endif

#if defined(MP_MUL_D_C)
#   define MP_CLAMP_C
#   define MP_COPY_C
#   define MP_GROW_C
#   define MP_MUL_2D_C
#   define MP_MUL_2_C
#   define S_MP_ZERO_DIGS_C
#endif

#if defined(MP_MULMOD_C)
#   define MP_MOD_C
#   define MP_MUL_C
#endif

#if defined(MP_NEG_C)
#   define MP_COPY_C
#endif

#if defined(MP_OR_C)
#   define MP_CLAMP_C
#   define MP_GROW_C
#endif

#if defined(MP_PACK_C)
#   define MP_CLEAR_C
#   define MP_DIV_2D_C
#   define MP_INIT_COPY_C
#   define MP_PACK_COUNT_C
#endif

#if defined(MP_PACK_COUNT_C)
#   define MP_COUNT_BITS_C
#endif

#if defined(MP_PRIME_FERMAT_C)
#   define MP_CLEAR_C
#   define MP_CMP_C
#   define MP_CMP_D_C
#   define MP_EXPTMOD_C
#   define MP_INIT_C
#endif

#if defined(MP_PRIME_FROBENIUS_UNDERWOOD_C)
#   define MP_ADD_C
#   define MP_ADD_D_C
#   define MP_CLEAR_MULTI_C
#   define MP_CMP_C
#   define MP_COUNT_BITS_C
#   define MP_EXCH_C
#   define MP_GCD_C
#   define MP_INIT_MULTI_C
#   define MP_KRONECKER_C
#   define MP_MOD_C
#   define MP_MUL_2_C
#   define MP_MUL_C
#   define MP_MUL_D_C
#   define MP_SET_C
#   define MP_SET_I32_C
#   define MP_SET_U32_C
#   define MP_SUB_C
#   define S_MP_GET_BIT_C
#endif

#if defined(MP_PRIME_IS_PRIME_C)
#   define MP_CLEAR_C
#   define MP_CMP_C
#   define MP_CMP_D_C
#   define MP_COUNT_BITS_C
#   define MP_DIV_2D_C
#   define MP_INIT_SET_C
#   define MP_IS_SQUARE_C
#   define MP_PRIME_MILLER_RABIN_C
#   define MP_PRIME_STRONG_LUCAS_SELFRIDGE_C
#   define MP_RAND_C
#   define MP_READ_RADIX_C
#   define MP_SET_C
#   define S_MP_PRIME_IS_DIVISIBLE_C
#endif

#if defined(MP_PRIME_MILLER_RABIN_C)
#   define MP_CLEAR_C
#   define MP_CMP_C
#   define MP_CMP_D_C
#   define MP_CNT_LSB_C
#   define MP_DIV_2D_C
#   define MP_EXPTMOD_C
#   define MP_INIT_C
#   define MP_INIT_COPY_C
#   define MP_SQRMOD_C
#   define MP_SUB_D_C
#endif

#if defined(MP_PRIME_NEXT_PRIME_C)
#   define MP_ADD_D_C
#   define MP_CLEAR_C
#   define MP_CMP_D_C
#   define MP_DIV_D_C
#   define MP_INIT_C
#   define MP_PRIME_IS_PRIME_C
#   define MP_SET_C
#   define MP_SUB_D_C
#endif

#if defined(MP_PRIME_RABIN_MILLER_TRIALS_C)
#endif

#if defined(MP_PRIME_RAND_C)
#   define MP_ADD_D_C
#   define MP_DIV_2_C
#   define MP_FROM_UBIN_C
#   define MP_MUL_2_C
#   define MP_PRIME_IS_PRIME_C
#   define MP_SUB_D_C
#   define S_MP_RAND_SOURCE_C
#   define S_MP_ZERO_BUF_C
#endif

#if defined(MP_PRIME_STRONG_LUCAS_SELFRIDGE_C)
#   define MP_ADD_C
#   define MP_ADD_D_C
#   define MP_CLEAR_C
#   define MP_CLEAR_MULTI_C
#   define MP_CMP_C
#   define MP_CMP_D_C
#   define MP_CNT_LSB_C
#   define MP_COUNT_BITS_C
#   define MP_DIV_2D_C
#   define MP_DIV_2_C
#   define MP_GCD_C
#   define MP_INIT_C
#   define MP_INIT_MULTI_C
#   define MP_KRONECKER_C
#   define MP_MOD_C
#   define MP_MUL_2_C
#   define MP_MUL_C
#   define MP_SET_C
#   define MP_SET_I32_C
#   define MP_SET_U32_C
#   define MP_SUB_C
#   define MP_SUB_D_C
#   define S_MP_GET_BIT_C
#endif

#if defined(MP_RADIX_SIZE_C)
#   define MP_LOG_N_C
#endif

#if defined(MP_RADIX_SIZE_OVERESTIMATE_C)
#   define MP_RADIX_SIZE_C
#   define S_MP_RADIX_SIZE_OVERESTIMATE_C
#endif

#if defined(MP_RAND_C)
#   define MP_GROW_C
#   define MP_ZERO_C
#   define S_MP_RAND_SOURCE_C
#endif

#if defined(MP_RAND_SOURCE_C)
#   define S_MP_RAND_PLATFORM_C
#endif

#if defined(MP_READ_RADIX_C)
#   define MP_ADD_D_C
#   define MP_MUL_D_C
#   define MP_ZERO_C
#endif

#if defined(MP_REDUCE_C)
#   define MP_ADD_C
#   define MP_CLEAR_C
#   define MP_CMP_C
#   define MP_CMP_D_C
#   define MP_INIT_COPY_C
#   define MP_LSHD_C
#   define MP_MOD_2D_C
#   define MP_MUL_C
#   define MP_RSHD_C
#   define MP_SET_C
#   define MP_SUB_C
#   define S_MP_MUL_C
#   define S_MP_MUL_HIGH_C
#   define S_MP_MUL_HIGH_COMBA_C
#   define S_MP_SUB_C
#endif

#if defined(MP_REDUCE_2K_C)
#   define MP_CLEAR_C
#   define MP_CMP_MAG_C
#   define MP_COUNT_BITS_C
#   define MP_DIV_2D_C
#   define MP_INIT_C
#   define MP_MUL_D_C
#   define S_MP_ADD_C
#   define S_MP_SUB_C
#endif

#if defined(MP_REDUCE_2K_L_C)
#   define MP_CLEAR_C
#   define MP_CMP_MAG_C
#   define MP_COUNT_BITS_C
#   define MP_DIV_2D_C
#   define MP_INIT_C
#   define MP_MUL_C
#   define S_MP_ADD_C
#   define S_MP_SUB_C
#endif

#if defined(MP_REDUCE_2K_SETUP_C)
#   define MP_2EXPT_C
#   define MP_CLEAR_C
#   define MP_COUNT_BITS_C
#   define MP_INIT_C
#   define S_MP_SUB_C
#endif

#if defined(MP_REDUCE_2K_SETUP_L_C)
#   define MP_2EXPT_C
#   define MP_CLEAR_C
#   define MP_COUNT_BITS_C
#   define MP_INIT_C
#   define S_MP_SUB_C
#endif

#if defined(MP_REDUCE_IS_2K_C)
#   define MP_COUNT_BITS_C
#endif

#if defined(MP_REDUCE_IS_2K_L_C)
#endif

#if defined(MP_REDUCE_SETUP_C)
#   define MP_2EXPT_C
#   define MP_DIV_C
#endif

#if defined(MP_ROOT_N_C)
#   define MP_2EXPT_C
#   define MP_ADD_D_C
#   define MP_CLEAR_MULTI_C
#   define MP_CMP_C
#   define MP_COPY_C
#   define MP_COUNT_BITS_C
#   define MP_DIV_C
#   define MP_EXCH_C
#   define MP_EXPT_N_C
#   define MP_INIT_MULTI_C
#   define MP_MUL_C
#   define MP_MUL_D_C
#   define MP_SET_C
#   define MP_SUB_C
#   define MP_SUB_D_C
#endif

#if defined(MP_RSHD_C)
#   define MP_ZERO_C
#   define S_MP_ZERO_DIGS_C
#endif

#if defined(MP_SBIN_SIZE_C)
#   define MP_UBIN_SIZE_C
#endif

#if defined(MP_SET_C)
#   define S_MP_ZERO_DIGS_C
#endif

#if defined(MP_SET_DOUBLE_C)
#   define MP_DIV_2D_C
#   define MP_MUL_2D_C
#   define MP_SET_U64_C
#endif

#if defined(MP_SET_I32_C)
#   define MP_SET_U32_C
#endif

#if defined(MP_SET_I64_C)
#   define MP_SET_U64_C
#endif

#if defined(MP_SET_L_C)
#   define MP_SET_UL_C
#endif

#if defined(MP_SET_U32_C)
#   define S_MP_ZERO_DIGS_C
#endif

#if defined(MP_SET_U64_C)
#   define S_MP_ZERO_DIGS_C
#endif

#if defined(MP_SET_UL_C)
#   define S_MP_ZERO_DIGS_C
#endif

#if defined(MP_SHRINK_C)
#endif

#if defined(MP_SIGNED_RSH_C)
#   define MP_ADD_D_C
#   define MP_DIV_2D_C
#   define MP_SUB_D_C
#endif

#if defined(MP_SQRMOD_C)
#   define MP_MOD_C
#   define MP_MUL_C
#endif

#if defined(MP_SQRT_C)
#   define MP_ADD_C
#   define MP_CLEAR_C
#   define MP_CMP_MAG_C
#   define MP_DIV_2_C
#   define MP_DIV_C
#   define MP_EXCH_C
#   define MP_INIT_C
#   define MP_INIT_COPY_C
#   define MP_RSHD_C
#   define MP_ZERO_C
#endif

#if defined(MP_SQRTMOD_PRIME_C)
#   define MP_ADD_D_C
#   define MP_CLEAR_MULTI_C
#   define MP_CMP_D_C
#   define MP_COPY_C
#   define MP_DIV_2_C
#   define MP_EXPTMOD_C
#   define MP_INIT_MULTI_C
#   define MP_KRONECKER_C
#   define MP_MULMOD_C
#   define MP_SET_C
#   define MP_SET_I32_C
#   define MP_SQRMOD_C
#   define MP_SUB_D_C
#   define MP_ZERO_C
#endif

#if defined(MP_SUB_C)
#   define MP_CMP_MAG_C
#   define S_MP_ADD_C
#   define S_MP_SUB_C
#endif

#if defined(MP_SUB_D_C)
#   define MP_ADD_D_C
#   define MP_CLAMP_C
#   define MP_GROW_C
#   define S_MP_ZERO_DIGS_C
#endif

#if defined(MP_SUBMOD_C)
#   define MP_MOD_C
#   define MP_SUB_C
#endif

#if defined(MP_TO_RADIX_C)
#   define MP_CLEAR_C
#   define MP_DIV_D_C
#   define MP_INIT_COPY_C
#endif

#if defined(MP_TO_SBIN_C)
#   define MP_TO_UBIN_C
#endif

#if defined(MP_TO_UBIN_C)
#   define MP_CLEAR_C
#   define MP_DIV_2D_C
#   define MP_INIT_COPY_C
#   define MP_UBIN_SIZE_C
#endif

#if defined(MP_UBIN_SIZE_C)
#   define MP_COUNT_BITS_C
#endif

#if defined(MP_UNPACK_C)
#   define MP_CLAMP_C
#   define MP_MUL_2D_C
#   define MP_ZERO_C
#endif

#if defined(MP_XOR_C)
#   define MP_CLAMP_C
#   define MP_GROW_C
#endif

#if defined(MP_ZERO_C)
#   define S_MP_ZERO_DIGS_C
#endif

#if defined(S_MP_ADD_C)
#   define MP_CLAMP_C
#   define MP_GROW_C
#   define S_MP_ZERO_DIGS_C
#endif

#if defined(S_MP_COPY_DIGS_C)
#endif

#if defined(S_MP_DIV_3_C)
#   define MP_CLAMP_C
#   define MP_CLEAR_C
#   define MP_EXCH_C
#   define MP_INIT_SIZE_C
#endif

#if defined(S_MP_DIV_RECURSIVE_C)
#   define MP_ADD_C
#   define MP_CLEAR_MULTI_C
#   define MP_CMP_D_C
#   define MP_COPY_C
#   define MP_DIV_2D_C
#   define MP_EXCH_C
#   define MP_INIT_MULTI_C
#   define MP_LSHD_C
#   define MP_MUL_2D_C
#   define MP_MUL_C
#   define MP_SUB_C
#   define MP_SUB_D_C
#   define MP_ZERO_C
#   define S_MP_DIV_SCHOOL_C
#endif

#if defined(S_MP_DIV_SCHOOL_C)
#   define MP_ADD_C
#   define MP_CLAMP_C
#   define MP_CLEAR_C
#   define MP_CMP_C
#   define MP_CMP_MAG_C
#   define MP_COPY_C
#   define MP_COUNT_BITS_C
#   define MP_DIV_2D_C
#   define MP_EXCH_C
#   define MP_INIT_C
#   define MP_INIT_COPY_C
#   define MP_INIT_SIZE_C
#   define MP_LSHD_C
#   define MP_MUL_2D_C
#   define MP_MUL_D_C
#   define MP_RSHD_C
#   define MP_SUB_C
#   define MP_ZERO_C
#endif

#if defined(S_MP_DIV_SMALL_C)
#   define MP_ABS_C
#   define MP_ADD_C
#   define MP_CLEAR_MULTI_C
#   define MP_CMP_C
#   define MP_COUNT_BITS_C
#   define MP_DIV_2D_C
#   define MP_EXCH_C
#   define MP_INIT_MULTI_C
#   define MP_MUL_2D_C
#   define MP_SET_C
#   define MP_SUB_C
#endif

#if defined(S_MP_EXPTMOD_C)
#   define MP_CLEAR_C
#   define MP_COPY_C
#   define MP_COUNT_BITS_C
#   define MP_EXCH_C
#   define MP_INIT_C
#   define MP_MOD_C
#   define MP_MUL_C
#   define MP_REDUCE_2K_L_C
#   define MP_REDUCE_2K_SETUP_L_C
#   define MP_REDUCE_C
#   define MP_REDUCE_SETUP_C
#   define MP_SET_C
#endif

#if defined(S_MP_EXPTMOD_FAST_C)
#   define MP_CLEAR_C
#   define MP_COPY_C
#   define MP_COUNT_BITS_C
#   define MP_DR_REDUCE_C
#   define MP_DR_SETUP_C
#   define MP_EXCH_C
#   define MP_INIT_SIZE_C
#   define MP_MOD_C
#   define MP_MONTGOMERY_CALC_NORMALIZATION_C
#   define MP_MONTGOMERY_REDUCE_C
#   define MP_MONTGOMERY_SETUP_C
#   define MP_MULMOD_C
#   define MP_MUL_C
#   define MP_REDUCE_2K_C
#   define MP_REDUCE_2K_SETUP_C
#   define MP_SET_C
#   define S_MP_MONTGOMERY_REDUCE_COMBA_C
#endif

#if defined(S_MP_GET_BIT_C)
#endif

#if defined(S_MP_INVMOD_C)
#   define MP_ADD_C
#   define MP_CLEAR_MULTI_C
#   define MP_CMP_C
#   define MP_CMP_D_C
#   define MP_CMP_MAG_C
#   define MP_COPY_C
#   define MP_DIV_2_C
#   define MP_EXCH_C
#   define MP_INIT_MULTI_C
#   define MP_MOD_C
#   define MP_SET_C
#   define MP_SUB_C
#endif

#if defined(S_MP_INVMOD_ODD_C)
#   define MP_ADD_C
#   define MP_CLEAR_MULTI_C
#   define MP_CMP_C
#   define MP_CMP_D_C
#   define MP_CMP_MAG_C
#   define MP_COPY_C
#   define MP_DIV_2_C
#   define MP_EXCH_C
#   define MP_INIT_MULTI_C
#   define MP_MOD_C
#   define MP_SET_C
#   define MP_SUB_C
#endif

#if defined(S_MP_LOG_C)
#   define MP_CLEAR_MULTI_C
#   define MP_CMP_C
#   define MP_CMP_D_C
#   define MP_COPY_C
#   define MP_EXCH_C
#   define MP_EXPT_N_C
#   define MP_INIT_MULTI_C
#   define MP_MUL_C
#   define MP_SET_C
#endif

#if defined(S_MP_LOG_2EXPT_C)
#   define MP_COUNT_BITS_C
#endif

#if defined(S_MP_LOG_D_C)
#endif

#if defined(S_MP_MONTGOMERY_REDUCE_COMBA_C)
#   define MP_CLAMP_C
#   define MP_CMP_MAG_C
#   define MP_GROW_C
#   define S_MP_SUB_C
#   define S_MP_ZERO_BUF_C
#   define S_MP_ZERO_DIGS_C
#endif

#if defined(S_MP_MUL_C)
#   define MP_CLAMP_C
#   define MP_CLEAR_C
#   define MP_EXCH_C
#   define MP_INIT_SIZE_C
#   define S_MP_MUL_COMBA_C
#endif

#if defined(S_MP_MUL_BALANCE_C)
#   define MP_ADD_C
#   define MP_CLAMP_C
#   define MP_CLEAR_C
#   define MP_CLEAR_MULTI_C
#   define MP_EXCH_C
#   define MP_INIT_MULTI_C
#   define MP_INIT_SIZE_C
#   define MP_LSHD_C
#   define MP_MUL_C
#   define S_MP_COPY_DIGS_C
#endif

#if defined(S_MP_MUL_COMBA_C)
#   define MP_CLAMP_C
#   define MP_GROW_C
#   define S_MP_ZERO_DIGS_C
#endif

#if defined(S_MP_MUL_HIGH_C)
#   define MP_CLAMP_C
#   define MP_CLEAR_C
#   define MP_EXCH_C
#   define MP_INIT_SIZE_C
#   define S_MP_MUL_HIGH_COMBA_C
#endif

#if defined(S_MP_MUL_HIGH_COMBA_C)
#   define MP_CLAMP_C
#   define MP_GROW_C
#   define S_MP_ZERO_DIGS_C
#endif

#if defined(S_MP_MUL_KARATSUBA_C)
#   define MP_ADD_C
#   define MP_CLAMP_C
#   define MP_CLEAR_C
#   define MP_INIT_SIZE_C
#   define MP_LSHD_C
#   define MP_MUL_C
#   define S_MP_ADD_C
#   define S_MP_COPY_DIGS_C
#   define S_MP_SUB_C
#endif

#if defined(S_MP_MUL_TOOM_C)
#   define MP_ADD_C
#   define MP_CLAMP_C
#   define MP_CLEAR_C
#   define MP_CLEAR_MULTI_C
#   define MP_DIV_2_C
#   define MP_INIT_MULTI_C
#   define MP_INIT_SIZE_C
#   define MP_LSHD_C
#   define MP_MUL_2_C
#   define MP_MUL_C
#   define MP_SUB_C
#   define S_MP_COPY_DIGS_C
#   define S_MP_DIV_3_C
#endif

#if defined(S_MP_PRIME_IS_DIVISIBLE_C)
#   define MP_DIV_D_C
#endif

#if defined(S_MP_PRIME_TAB_C)
#endif

#if defined(S_MP_RADIX_MAP_C)
#endif

#if defined(S_MP_RADIX_SIZE_OVERESTIMATE_C)
#   define MP_CLEAR_MULTI_C
#   define MP_COUNT_BITS_C
#   define MP_DIV_2D_C
#   define MP_GET_I64_C
#   define MP_INIT_MULTI_C
#   define MP_MUL_C
#   define MP_SET_U32_C
#   define S_MP_LOG_2EXPT_C
#endif

#if defined(S_MP_RAND_PLATFORM_C)
#endif

#if defined(S_MP_SQR_C)
#   define MP_CLAMP_C
#   define MP_CLEAR_C
#   define MP_EXCH_C
#   define MP_INIT_SIZE_C
#endif

#if defined(S_MP_SQR_COMBA_C)
#   define MP_CLAMP_C
#   define MP_GROW_C
#   define S_MP_ZERO_DIGS_C
#endif

#if defined(S_MP_SQR_KARATSUBA_C)
#   define MP_ADD_C
#   define MP_CLAMP_C
#   define MP_CLEAR_C
#   define MP_INIT_SIZE_C
#   define MP_LSHD_C
#   define MP_MUL_C
#   define S_MP_ADD_C
#   define S_MP_COPY_DIGS_C
#   define S_MP_SUB_C
#endif

#if defined(S_MP_SQR_TOOM_C)
#   define MP_ADD_C
#   define MP_CLAMP_C
#   define MP_CLEAR_C
#   define MP_DIV_2_C
#   define MP_INIT_C
#   define MP_INIT_SIZE_C
#   define MP_LSHD_C
#   define MP_MUL_2_C
#   define MP_MUL_C
#   define MP_SUB_C
#   define S_MP_COPY_DIGS_C
#endif

#if defined(S_MP_SUB_C)
#   define MP_CLAMP_C
#   define MP_GROW_C
#   define S_MP_ZERO_DIGS_C
#endif

#if defined(S_MP_ZERO_BUF_C)
#endif

#if defined(S_MP_ZERO_DIGS_C)
#endif

#ifdef LTM_INSIDE
#undef LTM_INSIDE
#ifdef LTM3
#   define LTM_LAST
#endif

#include "tommath_superclass.h"
#include "tommath_class.h"
#else
#   define LTM_LAST
#endif
