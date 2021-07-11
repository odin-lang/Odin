/* LibTomMath, multiple-precision integer library -- Tom St Denis */
/* SPDX-License-Identifier: Unlicense */

#ifndef TOMMATH_H_
#define TOMMATH_H_

#include <stddef.h>
#include <stdint.h>
#include <stdbool.h>

#ifndef MP_NO_FILE
#  include <stdio.h>
#endif

#ifdef __cplusplus
extern "C" {
#endif

/* MS Visual C++ doesn't have a 128bit type for words, so fall back to 32bit MPI's (where words are 64bit) */
#if (defined(_MSC_VER) || defined(__LLP64__) || defined(__e2k__) || defined(__LCC__)) && !defined(MP_64BIT)
#   define MP_32BIT
#endif

/* detect 64-bit mode if possible */
#if defined(__x86_64__) || defined(_M_X64) || defined(_M_AMD64) || \
    defined(__powerpc64__) || defined(__ppc64__) || defined(__PPC64__) || \
    defined(__s390x__) || defined(__arch64__) || defined(__aarch64__) || \
    defined(__sparcv9) || defined(__sparc_v9__) || defined(__sparc64__) || \
    defined(__ia64) || defined(__ia64__) || defined(__itanium__) || defined(_M_IA64) || \
    defined(__LP64__) || defined(_LP64) || defined(__64BIT__)
#   if !(defined(MP_64BIT) || defined(MP_32BIT) || defined(MP_16BIT))
#      if defined(__GNUC__) && !defined(__hppa)
/* we support 128bit integers only via: __attribute__((mode(TI))) */
#         define MP_64BIT
#      else
/* otherwise we fall back to MP_32BIT even on 64bit platforms */
#         define MP_32BIT
#      endif
#   endif
#endif

#ifdef MP_DIGIT_BIT
#   error Defining MP_DIGIT_BIT is disallowed, use MP_16/31/32/64BIT
#endif

/* some default configurations.
 *
 * A "mp_digit" must be able to hold MP_DIGIT_BIT + 1 bits
 * A "mp_word" must be able to hold 2*MP_DIGIT_BIT + 1 bits
 *
 * At the very least a mp_digit must be able to hold 7 bits
 * [any size beyond that is ok provided it doesn't overflow the data type]
 */

#if defined(MP_16BIT)
typedef uint16_t             mp_digit;
#   define MP_DIGIT_BIT 15
#elif defined(MP_64BIT)
typedef uint64_t mp_digit;
#   define MP_DIGIT_BIT 60
#else
typedef uint32_t             mp_digit;
#   ifdef MP_31BIT
/*
 * This is an extension that uses 31-bit digits.
 * Please be aware that not all functions support this size, especially s_mp_mul_comba
 * will be reduced to work on small numbers only:
 * Up to 8 limbs, 248 bits instead of up to 512 limbs, 15872 bits with MP_28BIT.
 */
#      define MP_DIGIT_BIT 31
#   else
/* default case is 28-bit digits, defines MP_28BIT as a handy macro to test */
#      define MP_DIGIT_BIT 28
#      define MP_28BIT
#   endif
#endif

#define MP_MASK          ((((mp_digit)1)<<((mp_digit)MP_DIGIT_BIT))-((mp_digit)1))
#define MP_DIGIT_MAX     MP_MASK

/* Primality generation flags */
#define MP_PRIME_BBS      0x0001 /* BBS style prime */
#define MP_PRIME_SAFE     0x0002 /* Safe prime (p-1)/2 == prime */
#define MP_PRIME_2MSB_ON  0x0008 /* force 2nd MSB to 1 */

typedef enum {
   MP_ZPOS = 0,   /* positive */
   MP_NEG = 1     /* negative */
} mp_sign;

typedef enum {
   MP_LT = -1,    /* less than */
   MP_EQ = 0,     /* equal */
   MP_GT = 1      /* greater than */
} mp_ord;

typedef enum {
   MP_OKAY  = 0,   /* no error */
   MP_ERR   = -1,  /* unknown error */
   MP_MEM   = -2,  /* out of mem */
   MP_VAL   = -3,  /* invalid input */
   MP_ITER  = -4,  /* maximum iterations reached */
   MP_BUF   = -5,  /* buffer overflow, supplied buffer too small */
   MP_OVF   = -6   /* mp_int overflow, too many digits */
} mp_err;

typedef enum {
   MP_LSB_FIRST = -1,
   MP_MSB_FIRST =  1
} mp_order;

typedef enum {
   MP_LITTLE_ENDIAN  = -1,
   MP_NATIVE_ENDIAN  =  0,
   MP_BIG_ENDIAN     =  1
} mp_endian;

/* tunable cutoffs */
#ifndef MP_FIXED_CUTOFFS
extern int
MP_MUL_KARATSUBA_CUTOFF,
MP_SQR_KARATSUBA_CUTOFF,
MP_MUL_TOOM_CUTOFF,
MP_SQR_TOOM_CUTOFF;
#endif

/* define this to use lower memory usage routines (exptmods mostly) */
/* #define MP_LOW_MEM */

#if defined(__GNUC__) && __GNUC__ >= 4
#   define MP_NULL_TERMINATED __attribute__((sentinel))
#else
#   define MP_NULL_TERMINATED
#endif

/*
 * MP_WUR - warn unused result
 * ---------------------------
 *
 * The result of functions annotated with MP_WUR must be
 * checked and cannot be ignored.
 *
 * Most functions in libtommath return an error code.
 * This error code must be checked in order to prevent crashes or invalid
 * results.
 */
#if defined(__GNUC__) && __GNUC__ >= 4
#   define MP_WUR __attribute__((warn_unused_result))
#else
#   define MP_WUR
#endif

#if defined(__GNUC__) && (__GNUC__ * 100 + __GNUC_MINOR__ >= 405)
#  define MP_DEPRECATED(x) __attribute__((deprecated("replaced by " #x)))
#elif defined(_MSC_VER) && _MSC_VER >= 1500
#  define MP_DEPRECATED(x) __declspec(deprecated("replaced by " #x))
#else
#  define MP_DEPRECATED(x)
#endif

#ifndef MP_NO_DEPRECATED_PRAGMA
#if defined(__GNUC__) && (__GNUC__ * 100 + __GNUC_MINOR__ >= 301)
#  define PRIVATE_MP_DEPRECATED_PRAGMA(s) _Pragma(#s)
#  define MP_DEPRECATED_PRAGMA(s) PRIVATE_MP_DEPRECATED_PRAGMA(GCC warning s)
#elif defined(_MSC_VER) && _MSC_VER >= 1500
#  define MP_DEPRECATED_PRAGMA(s) __pragma(message(s))
#endif
#endif

#ifndef MP_DEPRECATED_PRAGMA
#  define MP_DEPRECATED_PRAGMA(s)
#endif

/* the infamous mp_int structure */
typedef struct  {
   int used, alloc;
   mp_sign sign;
   mp_digit *dp;
} mp_int;

/* error code to char* string */
const char *mp_error_to_string(mp_err code) MP_WUR;

/* ---> init and deinit bignum functions <--- */
/* init a bignum */
mp_err mp_init(mp_int *a) MP_WUR;

/* free a bignum */
void mp_clear(mp_int *a);

/* init a null terminated series of arguments */
mp_err mp_init_multi(mp_int *mp, ...) MP_NULL_TERMINATED MP_WUR;

/* clear a null terminated series of arguments */
void mp_clear_multi(mp_int *mp, ...) MP_NULL_TERMINATED;

/* exchange two ints */
void mp_exch(mp_int *a, mp_int *b);

/* shrink ram required for a bignum */
mp_err mp_shrink(mp_int *a) MP_WUR;

/* grow an int to a given size */
mp_err mp_grow(mp_int *a, int size) MP_WUR;

/* init to a given number of digits */
mp_err mp_init_size(mp_int *a, int size) MP_WUR;

/* ---> Basic Manipulations <--- */
#define mp_iszero(a) ((a)->used == 0)
#define mp_isneg(a)  ((a)->sign == MP_NEG)
#define mp_iseven(a) (((a)->used == 0) || (((a)->dp[0] & 1u) == 0u))
#define mp_isodd(a)  (!mp_iseven(a))

/* set to zero */
void mp_zero(mp_int *a);

/* get and set doubles */
double mp_get_double(const mp_int *a) MP_WUR;
mp_err mp_set_double(mp_int *a, double b) MP_WUR;

/* get integer, set integer and init with integer (int32_t) */
int32_t mp_get_i32(const mp_int *a) MP_WUR;
void mp_set_i32(mp_int *a, int32_t b);
mp_err mp_init_i32(mp_int *a, int32_t b) MP_WUR;

/* get integer, set integer and init with integer, behaves like two complement for negative numbers (uint32_t) */
#define mp_get_u32(a) ((uint32_t)mp_get_i32(a))
void mp_set_u32(mp_int *a, uint32_t b);
mp_err mp_init_u32(mp_int *a, uint32_t b) MP_WUR;

/* get integer, set integer and init with integer (int64_t) */
int64_t mp_get_i64(const mp_int *a) MP_WUR;
void mp_set_i64(mp_int *a, int64_t b);
mp_err mp_init_i64(mp_int *a, int64_t b) MP_WUR;

/* get integer, set integer and init with integer, behaves like two complement for negative numbers (uint64_t) */
#define mp_get_u64(a) ((uint64_t)mp_get_i64(a))
void mp_set_u64(mp_int *a, uint64_t b);
mp_err mp_init_u64(mp_int *a, uint64_t b) MP_WUR;

/* get magnitude */
uint32_t mp_get_mag_u32(const mp_int *a) MP_WUR;
uint64_t mp_get_mag_u64(const mp_int *a) MP_WUR;
unsigned long mp_get_mag_ul(const mp_int *a) MP_WUR;

/* get integer, set integer (long) */
long mp_get_l(const mp_int *a) MP_WUR;
void mp_set_l(mp_int *a, long b);
mp_err mp_init_l(mp_int *a, long b) MP_WUR;

/* get integer, set integer (unsigned long) */
#define mp_get_ul(a) ((unsigned long)mp_get_l(a))
void mp_set_ul(mp_int *a, unsigned long b);
mp_err mp_init_ul(mp_int *a, unsigned long b) MP_WUR;

/* set to single unsigned digit, up to MP_DIGIT_MAX */
void mp_set(mp_int *a, mp_digit b);
mp_err mp_init_set(mp_int *a, mp_digit b) MP_WUR;

/* copy, b = a */
mp_err mp_copy(const mp_int *a, mp_int *b) MP_WUR;

/* inits and copies, a = b */
mp_err mp_init_copy(mp_int *a, const mp_int *b) MP_WUR;

/* trim unused digits */
void mp_clamp(mp_int *a);

/* unpack binary data */
mp_err mp_unpack(mp_int *rop, size_t count, mp_order order, size_t size, mp_endian endian,
                 size_t nails, const void *op) MP_WUR;

/* pack binary data */
size_t mp_pack_count(const mp_int *a, size_t nails, size_t size) MP_WUR;
mp_err mp_pack(void *rop, size_t maxcount, size_t *written, mp_order order, size_t size,
               mp_endian endian, size_t nails, const mp_int *op) MP_WUR;

/* ---> digit manipulation <--- */

/* right shift by "b" digits */
void mp_rshd(mp_int *a, int b);

/* left shift by "b" digits */
mp_err mp_lshd(mp_int *a, int b) MP_WUR;

/* c = a / 2**b, implemented as c = a >> b */
mp_err mp_div_2d(const mp_int *a, int b, mp_int *c, mp_int *d) MP_WUR;

/* b = a/2 */
mp_err mp_div_2(const mp_int *a, mp_int *b) MP_WUR;

/* c = a * 2**b, implemented as c = a << b */
mp_err mp_mul_2d(const mp_int *a, int b, mp_int *c) MP_WUR;

/* b = a*2 */
mp_err mp_mul_2(const mp_int *a, mp_int *b) MP_WUR;

/* c = a mod 2**b */
mp_err mp_mod_2d(const mp_int *a, int b, mp_int *c) MP_WUR;

/* computes a = 2**b */
mp_err mp_2expt(mp_int *a, int b) MP_WUR;

/* Counts the number of lsbs which are zero before the first zero bit */
int mp_cnt_lsb(const mp_int *a) MP_WUR;

/* I Love Earth! */

/* makes a pseudo-random mp_int of a given size */
// mp_err mp_rand(mp_int *a, int digits) MP_WUR;
/* use custom random data source instead of source provided the platform */
// void mp_rand_source(mp_err(*source)(void *out, size_t size));

/* ---> binary operations <--- */

/* c = a XOR b (two complement) */
mp_err mp_xor(const mp_int *a, const mp_int *b, mp_int *c) MP_WUR;

/* c = a OR b (two complement) */
mp_err mp_or(const mp_int *a, const mp_int *b, mp_int *c) MP_WUR;

/* c = a AND b (two complement) */
mp_err mp_and(const mp_int *a, const mp_int *b, mp_int *c) MP_WUR;

/* b = ~a (bitwise not, two complement) */
mp_err mp_complement(const mp_int *a, mp_int *b) MP_WUR;

/* right shift with sign extension */
mp_err mp_signed_rsh(const mp_int *a, int b, mp_int *c) MP_WUR;

/* ---> Basic arithmetic <--- */

/* b = -a */
mp_err mp_neg(const mp_int *a, mp_int *b) MP_WUR;

/* b = |a| */
mp_err mp_abs(const mp_int *a, mp_int *b) MP_WUR;

/* compare a to b */
mp_ord mp_cmp(const mp_int *a, const mp_int *b) MP_WUR;

/* compare |a| to |b| */
mp_ord mp_cmp_mag(const mp_int *a, const mp_int *b) MP_WUR;

/* c = a + b */
mp_err mp_add(const mp_int *a, const mp_int *b, mp_int *c) MP_WUR;

/* c = a - b */
mp_err mp_sub(const mp_int *a, const mp_int *b, mp_int *c) MP_WUR;

/* c = a * b */
mp_err mp_mul(const mp_int *a, const mp_int *b, mp_int *c) MP_WUR;

/* b = a*a  */
#define mp_sqr(a, b) mp_mul((a), (a), (b))

/* a/b => cb + d == a */
mp_err mp_div(const mp_int *a, const mp_int *b, mp_int *c, mp_int *d) MP_WUR;

/* c = a mod b, 0 <= c < b  */
mp_err mp_mod(const mp_int *a, const mp_int *b, mp_int *c) MP_WUR;

/* Increment "a" by one like "a++". Changes input! */
#define mp_incr(a) mp_add_d((a), 1u, (a))

/* Decrement "a" by one like "a--". Changes input! */
#define mp_decr(a) mp_sub_d((a), 1u, (a))

/* ---> single digit functions <--- */

/* compare against a single digit */
mp_ord mp_cmp_d(const mp_int *a, mp_digit b) MP_WUR;

/* c = a + b */
mp_err mp_add_d(const mp_int *a, mp_digit b, mp_int *c) MP_WUR;

/* c = a - b */
mp_err mp_sub_d(const mp_int *a, mp_digit b, mp_int *c) MP_WUR;

/* c = a * b */
mp_err mp_mul_d(const mp_int *a, mp_digit b, mp_int *c) MP_WUR;

/* a/b => cb + d == a */
mp_err mp_div_d(const mp_int *a, mp_digit b, mp_int *c, mp_digit *d) MP_WUR;

/* c = a mod b, 0 <= c < b  */
#define mp_mod_d(a, b, c) mp_div_d((a), (b), NULL, (c))

/* ---> number theory <--- */

/* d = a + b (mod c) */
mp_err mp_addmod(const mp_int *a, const mp_int *b, const mp_int *c, mp_int *d) MP_WUR;

/* d = a - b (mod c) */
mp_err mp_submod(const mp_int *a, const mp_int *b, const mp_int *c, mp_int *d) MP_WUR;

/* d = a * b (mod c) */
mp_err mp_mulmod(const mp_int *a, const mp_int *b, const mp_int *c, mp_int *d) MP_WUR;

/* c = a * a (mod b) */
mp_err mp_sqrmod(const mp_int *a, const mp_int *b, mp_int *c) MP_WUR;

/* c = 1/a (mod b) */
mp_err mp_invmod(const mp_int *a, const mp_int *b, mp_int *c) MP_WUR;

/* c = (a, b) */
mp_err mp_gcd(const mp_int *a, const mp_int *b, mp_int *c) MP_WUR;

/* produces value such that U1*a + U2*b = U3 */
mp_err mp_exteuclid(const mp_int *a, const mp_int *b, mp_int *U1, mp_int *U2, mp_int *U3) MP_WUR;

/* c = [a, b] or (a*b)/(a, b) */
mp_err mp_lcm(const mp_int *a, const mp_int *b, mp_int *c) MP_WUR;

/* Integer logarithm to integer base */
mp_err mp_log_n(const mp_int *a, int base, int *c) MP_WUR;

/* c = a**b */
mp_err mp_expt_n(const mp_int *a, int b, mp_int *c) MP_WUR;

/* finds one of the b'th root of a, such that |c|**b <= |a|
 *
 * returns error if a < 0 and b is even
 */
mp_err mp_root_n(const mp_int *a, int b, mp_int *c) MP_WUR;

/* special sqrt algo */
mp_err mp_sqrt(const mp_int *arg, mp_int *ret) MP_WUR;

/* special sqrt (mod prime) */
mp_err mp_sqrtmod_prime(const mp_int *n, const mp_int *prime, mp_int *ret) MP_WUR;

/* is number a square? */
mp_err mp_is_square(const mp_int *arg, bool *ret) MP_WUR;

/* computes the Kronecker symbol c = (a | p) (like jacobi() but with {a,p} in Z */
mp_err mp_kronecker(const mp_int *a, const mp_int *p, int *c) MP_WUR;

/* used to setup the Barrett reduction for a given modulus b */
mp_err mp_reduce_setup(mp_int *a, const mp_int *b) MP_WUR;

/* Barrett Reduction, computes a (mod b) with a precomputed value c
 *
 * Assumes that 0 < x <= m*m, note if 0 > x > -(m*m) then you can merely
 * compute the reduction as -1 * mp_reduce(mp_abs(x)) [pseudo code].
 */
mp_err mp_reduce(mp_int *x, const mp_int *m, const mp_int *mu) MP_WUR;

/* setups the montgomery reduction */
mp_err mp_montgomery_setup(const mp_int *n, mp_digit *rho) MP_WUR;

/* computes a = B**n mod b without division or multiplication useful for
 * normalizing numbers in a Montgomery system.
 */
mp_err mp_montgomery_calc_normalization(mp_int *a, const mp_int *b) MP_WUR;

/* computes x/R == x (mod N) via Montgomery Reduction */
mp_err mp_montgomery_reduce(mp_int *x, const mp_int *n, mp_digit rho) MP_WUR;

/* returns 1 if a is a valid DR modulus */
bool mp_dr_is_modulus(const mp_int *a) MP_WUR;

/* sets the value of "d" required for mp_dr_reduce */
void mp_dr_setup(const mp_int *a, mp_digit *d);

/* reduces a modulo n using the Diminished Radix method */
mp_err mp_dr_reduce(mp_int *x, const mp_int *n, mp_digit k) MP_WUR;

/* returns true if a can be reduced with mp_reduce_2k */
bool mp_reduce_is_2k(const mp_int *a) MP_WUR;

/* determines k value for 2k reduction */
mp_err mp_reduce_2k_setup(const mp_int *a, mp_digit *d) MP_WUR;

/* reduces a modulo b where b is of the form 2**p - k [0 <= a] */
mp_err mp_reduce_2k(mp_int *a, const mp_int *n, mp_digit d) MP_WUR;

/* returns true if a can be reduced with mp_reduce_2k_l */
bool mp_reduce_is_2k_l(const mp_int *a) MP_WUR;

/* determines k value for 2k reduction */
mp_err mp_reduce_2k_setup_l(const mp_int *a, mp_int *d) MP_WUR;

/* reduces a modulo b where b is of the form 2**p - k [0 <= a] */
mp_err mp_reduce_2k_l(mp_int *a, const mp_int *n, const mp_int *d) MP_WUR;

/* Y = G**X (mod P) */
mp_err mp_exptmod(const mp_int *G, const mp_int *X, const mp_int *P, mp_int *Y) MP_WUR;

/* ---> Primes <--- */

/* performs one Fermat test of "a" using base "b".
 * Sets result to 0 if composite or 1 if probable prime
 */
mp_err mp_prime_fermat(const mp_int *a, const mp_int *b, bool *result) MP_WUR;

/* performs one Miller-Rabin test of "a" using base "b".
 * Sets result to 0 if composite or 1 if probable prime
 */
mp_err mp_prime_miller_rabin(const mp_int *a, const mp_int *b, bool *result) MP_WUR;

/* This gives [for a given bit size] the number of trials required
 * such that Miller-Rabin gives a prob of failure lower than 2^-96
 */
int mp_prime_rabin_miller_trials(int size) MP_WUR;

/* performs one strong Lucas-Selfridge test of "a".
 * Sets result to 0 if composite or 1 if probable prime
 */
mp_err mp_prime_strong_lucas_selfridge(const mp_int *a, bool *result) MP_WUR;

/* performs one Frobenius test of "a" as described by Paul Underwood.
 * Sets result to 0 if composite or 1 if probable prime
 */
mp_err mp_prime_frobenius_underwood(const mp_int *N, bool *result) MP_WUR;

/* performs t random rounds of Miller-Rabin on "a" additional to
 * bases 2 and 3.  Also performs an initial sieve of trial
 * division.  Determines if "a" is prime with probability
 * of error no more than (1/4)**t.
 * Both a strong Lucas-Selfridge to complete the BPSW test
 * and a separate Frobenius test are available at compile time.
 * With t<0 a deterministic test is run for primes up to
 * 318665857834031151167461. With t<13 (abs(t)-13) additional
 * tests with sequential small primes are run starting at 43.
 * Is Fips 186.4 compliant if called with t as computed by
 * mp_prime_rabin_miller_trials();
 *
 * Sets result to 1 if probably prime, 0 otherwise
 */
mp_err mp_prime_is_prime(const mp_int *a, int t, bool *result) MP_WUR;

/* finds the next prime after the number "a" using "t" trials
 * of Miller-Rabin.
 *
 * bbs_style = true means the prime must be congruent to 3 mod 4
 */
mp_err mp_prime_next_prime(mp_int *a, int t, bool bbs_style) MP_WUR;

/* makes a truly random prime of a given size (bits),
 *
 * Flags are as follows:
 *
 *   MP_PRIME_BBS      - make prime congruent to 3 mod 4
 *   MP_PRIME_SAFE     - make sure (p-1)/2 is prime as well (implies MP_PRIME_BBS)
 *   MP_PRIME_2MSB_ON  - make the 2nd highest bit one
 *
 * You have to supply a callback which fills in a buffer with random bytes.  "dat" is a parameter you can
 * have passed to the callback (e.g. a state or something).  This function doesn't use "dat" itself
 * so it can be NULL
 *
 */
// mp_err mp_prime_rand(mp_int *a, int t, int size, int flags) MP_WUR;

/* ---> radix conversion <--- */
int mp_count_bits(const mp_int *a) MP_WUR;

size_t mp_ubin_size(const mp_int *a) MP_WUR;
mp_err mp_from_ubin(mp_int *a, const uint8_t *buf, size_t size) MP_WUR;
mp_err mp_to_ubin(const mp_int *a, uint8_t *buf, size_t maxlen, size_t *written) MP_WUR;

size_t mp_sbin_size(const mp_int *a) MP_WUR;
mp_err mp_from_sbin(mp_int *a, const uint8_t *buf, size_t size) MP_WUR;
mp_err mp_to_sbin(const mp_int *a, uint8_t *buf, size_t maxlen, size_t *written) MP_WUR;

mp_err mp_read_radix(mp_int *a, const char *str, int radix) MP_WUR;
mp_err mp_to_radix(const mp_int *a, char *str, size_t maxlen, size_t *written, int radix) MP_WUR;

mp_err mp_radix_size(const mp_int *a, int radix, size_t *size) MP_WUR;
mp_err mp_radix_size_overestimate(const mp_int *a, const int radix, size_t *size) MP_WUR;

#ifndef MP_NO_FILE
mp_err mp_fread(mp_int *a, int radix, FILE *stream) MP_WUR;
mp_err mp_fwrite(const mp_int *a, int radix, FILE *stream) MP_WUR;
#endif

#define mp_to_binary(M, S, N)  mp_to_radix((M), (S), (N), NULL, 2)
#define mp_to_octal(M, S, N)   mp_to_radix((M), (S), (N), NULL, 8)
#define mp_to_decimal(M, S, N) mp_to_radix((M), (S), (N), NULL, 10)
#define mp_to_hex(M, S, N)     mp_to_radix((M), (S), (N), NULL, 16)

#ifdef __cplusplus
}
#endif

#endif
