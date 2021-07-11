/* LibTomMath, multiple-precision integer library -- Tom St Denis */
/* SPDX-License-Identifier: Unlicense */

/*
 * This header defines custom types which
 * are used in c89 mode.
 *
 * By default, the source uses stdbool.h
 * and stdint.h. The command `make c89`
 * can be used to convert the source,
 * such that this header is used instead.
 * Use `make c99` to convert back.
 *
 * Please adapt the following definitions to your needs!
 */

/* stdbool.h replacement types */
typedef enum { MP_NO, MP_YES } mp_bool;

/* stdint.h replacement types */
typedef __INT8_TYPE__   mp_i8;
typedef __INT16_TYPE__  mp_i16;
typedef __INT32_TYPE__  mp_i32;
typedef __INT64_TYPE__  mp_i64;
typedef __UINT8_TYPE__  mp_u8;
typedef __UINT16_TYPE__ mp_u16;
typedef __UINT32_TYPE__ mp_u32;
typedef __UINT64_TYPE__ mp_u64;

/* inttypes.h replacement, printf format specifier */
# if __WORDSIZE == 64
#  define MP_PRI64_PREFIX "l"
# else
#  define MP_PRI64_PREFIX "ll"
# endif
#define MP_PRIi64 MP_PRI64_PREFIX "i"
#define MP_PRIu64 MP_PRI64_PREFIX "u"
#define MP_PRIx64 MP_PRI64_PREFIX "x"

#define MP_FUNCTION_NAME __func__
