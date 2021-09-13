/*
	An implementation of Yann Collet's [xxhash Fast Hash Algorithm](https://cyan4973.github.io/xxHash/).
	Copyright 2021 Jeroen van Rijn <nom@duclavier.com>.

	Made available under Odin's BSD-3 license, based on the original C code.

	List of contributors:
		Jeroen van Rijn: Initial implementation.
*/
package xxhash

import "core:intrinsics"

/*
*************************************************************************
* XXH3
* New generation hash designed for speed on small keys and vectorization
*************************************************************************
* One goal of XXH3 is to make it fast on both 32-bit and 64-bit, while
* remaining a true 64-bit/128-bit hash function.
* ==========================================
* XXH3 default settings
* ==========================================
*/

/*
	Custom secrets have a default length of 192, but can be set to a different size.
	The minimum secret size is 136 bytes. It must also be a multiple of 64.
*/
XXH_SECRET_DEFAULT_SIZE :: max(XXH3_SECRET_SIZE_MIN, #config(XXH_SECRET_DEFAULT_SIZE, 192))
#assert(XXH_SECRET_DEFAULT_SIZE % 64 == 0)

XXH3_kSecret :: [?]u8{
	0xb8, 0xfe, 0x6c, 0x39, 0x23, 0xa4, 0x4b, 0xbe, 0x7c, 0x01, 0x81, 0x2c, 0xf7, 0x21, 0xad, 0x1c,
	0xde, 0xd4, 0x6d, 0xe9, 0x83, 0x90, 0x97, 0xdb, 0x72, 0x40, 0xa4, 0xa4, 0xb7, 0xb3, 0x67, 0x1f,
	0xcb, 0x79, 0xe6, 0x4e, 0xcc, 0xc0, 0xe5, 0x78, 0x82, 0x5a, 0xd0, 0x7d, 0xcc, 0xff, 0x72, 0x21,
	0xb8, 0x08, 0x46, 0x74, 0xf7, 0x43, 0x24, 0x8e, 0xe0, 0x35, 0x90, 0xe6, 0x81, 0x3a, 0x26, 0x4c,
	0x3c, 0x28, 0x52, 0xbb, 0x91, 0xc3, 0x00, 0xcb, 0x88, 0xd0, 0x65, 0x8b, 0x1b, 0x53, 0x2e, 0xa3,
	0x71, 0x64, 0x48, 0x97, 0xa2, 0x0d, 0xf9, 0x4e, 0x38, 0x19, 0xef, 0x46, 0xa9, 0xde, 0xac, 0xd8,
	0xa8, 0xfa, 0x76, 0x3f, 0xe3, 0x9c, 0x34, 0x3f, 0xf9, 0xdc, 0xbb, 0xc7, 0xc7, 0x0b, 0x4f, 0x1d,
	0x8a, 0x51, 0xe0, 0x4b, 0xcd, 0xb4, 0x59, 0x31, 0xc8, 0x9f, 0x7e, 0xc9, 0xd9, 0x78, 0x73, 0x64,
	0xea, 0xc5, 0xac, 0x83, 0x34, 0xd3, 0xeb, 0xc3, 0xc5, 0x81, 0xa0, 0xff, 0xfa, 0x13, 0x63, 0xeb,
	0x17, 0x0d, 0xdd, 0x51, 0xb7, 0xf0, 0xda, 0x49, 0xd3, 0x16, 0x55, 0x26, 0x29, 0xd4, 0x68, 0x9e,
	0x2b, 0x16, 0xbe, 0x58, 0x7d, 0x47, 0xa1, 0xfc, 0x8f, 0xf8, 0xb8, 0xd1, 0x7a, 0xd0, 0x31, 0xce,
	0x45, 0xcb, 0x3a, 0x8f, 0x95, 0x16, 0x04, 0x28, 0xaf, 0xd7, 0xfb, 0xca, 0xbb, 0x4b, 0x40, 0x7e,
}
/*
	Do not change this constant.
*/
XXH3_SECRET_SIZE_MIN    :: 136
#assert(size_of(XXH3_kSecret) == 192 && size_of(XXH3_kSecret) > XXH3_SECRET_SIZE_MIN)

XXH_ACC_ALIGN           :: 8   /* scalar */

/*
	This is the optimal update size for incremental hashing.
*/
XXH3_INTERNAL_BUFFER_SIZE :: 256

/*
	Streaming state.

	IMPORTANT: This structure has a strict alignment requirement of 64 bytes!! **
	Do not allocate this with `make()` or `new`, it will not be sufficiently aligned.
	Use`XXH3_create_state` and `XXH3_destroy_state, or stack allocation.
*/
XXH3_state :: struct {
	acc:               [8]u64,
	custom_secret:     [XXH_SECRET_DEFAULT_SIZE]u8,
	buffer:            [XXH3_INTERNAL_BUFFER_SIZE]u8,
	buffered_size:     u32,
	reserved32:        u32,
	stripes_so_far:    uint,
	total_len:         u64,
	stripes_per_block: uint,
	secret_limit:      uint,
	seed:              u64,
	reserved64:        u64,
	external_secret:   ^[]u8,
}
#assert(offset_of(XXH3_state, acc)    % 64 == 0 && offset_of(XXH3_state, custom_secret) % 64 == 0 &&
        offset_of(XXH3_state, buffer) % 64 == 0)

/************************************************************************
*  XXH3 128-bit variant
************************************************************************/

/*
	Stored in little endian order, although the fields themselves are in native endianness.
*/
xxh_u128              :: u128
XXH3_128_hash         :: u128

XXH128_hash_t :: struct #raw_union {
	using raw: struct {
		low:  XXH64_hash, /*!< `value & 0xFFFFFFFFFFFFFFFF` */
		high: XXH64_hash, /*!< `value >> 64` */
	},
	h: xxh_u128,
}
#assert(size_of(xxh_u128) == size_of(XXH128_hash_t))

/*
	The reason for the separate function is to prevent passing too many structs
	around by value. This will hopefully inline the multiply, but we don't force it.

	@param lhs, rhs The 64-bit integers to multiply
	@return The low 64 bits of the product XOR'd by the high 64 bits.
*/
@(optimization_mode="speed")
XXH_mul_64_to_128_fold_64 :: #force_inline proc(lhs, rhs: xxh_u64) -> (res: xxh_u64) {
	t := u128(lhs) * u128(rhs)
	return u64(t & 0xFFFFFFFFFFFFFFFF) ~ u64(t >> 64)
}

@(optimization_mode="speed")
XXH_xorshift_64 :: #force_inline proc(v: xxh_u64, auto_cast shift: uint) -> (res: xxh_u64) {
	return v ~ (v >> shift)
}

/*
	This is a fast avalanche stage, suitable when input bits are already partially mixed
*/
@(optimization_mode="speed")
XXH3_avalanche :: #force_inline proc(h64: xxh_u64) -> (res: xxh_u64) {
	res = XXH_xorshift_64(h64, 37)
	res *= 0x165667919E3779F9
	res = XXH_xorshift_64(res, 32)
	return
}

/*
	This is a stronger avalanche, inspired by Pelle Evensen's rrmxmx
	preferable when input has not been previously mixed
*/
@(optimization_mode="speed")
XXH3_rrmxmx :: #force_inline proc(h64, length: xxh_u64) -> (res: xxh_u64) {
	/* this mix is inspired by Pelle Evensen's rrmxmx */
	res = h64
	res ~= XXH_rotl64(res, 49) ~ XXH_rotl64(res, 24)
	res *= 0x9FB21C651E98DF25
	res ~= (res >> 35) + length 
	res *= 0x9FB21C651E98DF25
	return XXH_xorshift_64(res, 28)
}

/*
	==========================================
	       XXH3 128 bits (a.k.a XXH128)
	==========================================
	XXH3's 128-bit variant has better mixing and strength than the 64-bit variant,
	even without counting the significantly larger output size.

 	For example, extra steps are taken to avoid the seed-dependent collisions
	in 17-240 byte inputs (See XXH3_mix16B and XXH128_mix32B).

	This strength naturally comes at the cost of some speed, especially on short
	lengths. Note that longer hashes are about as fast as the 64-bit version
	due to it using only a slight modification of the 64-bit loop.

	XXH128 is also more oriented towards 64-bit machines. It is still extremely
	fast for a _128-bit_ hash on 32-bit (it usually clears XXH64).
*/

@(optimization_mode="speed")
XXH3_len_1to3_128b :: #force_inline proc(input: []u8, secret: []u8, seed: xxh_u64) -> (res: xxh_u128) {
	/* A doubled version of 1to3_64b with different constants. */
	length := len(input)
	/*
	 * len = 1: combinedl = { input[0], 0x01, input[0], input[0] }
	 * len = 2: combinedl = { input[1], 0x02, input[0], input[1] }
	 * len = 3: combinedl = { input[2], 0x03, input[0], input[1] }
	 */
	#no_bounds_check {
		c1 := input[          0]
		c2 := input[length >> 1]
		c3 := input[length  - 1]
		combinedl := (u32(c1) << 16) | (u32(c2) << 24) | (u32(c3) << 0) | (u32(length) << 8)
		combinedh := XXH_rotl32(byte_swap(combinedl), 13)
		bitflipl  := u64(XXH32_read32(secret[0:]) ~ XXH32_read32(secret[4: ])) + seed
		bitfliph  := u64(XXH32_read32(secret[8:]) ~ XXH32_read32(secret[12:])) - seed
		keyed_lo  := u64(combinedl) ~ bitflipl
		keyed_hi  := u64(combinedh) ~ bitfliph
		
		return xxh_u128(XXH64_avalanche(keyed_lo)) | xxh_u128(XXH64_avalanche(keyed_hi)) << 64
	}
}

@(optimization_mode="speed")
XXH3_len_4to8_128b :: #force_inline proc(input: []u8, secret: []u8, seed: xxh_u64) -> (res: xxh_u128) {
	length := len(input)
	seed   := seed

	seed ~= u64(byte_swap(u32(seed))) << 32
	#no_bounds_check {
		input_lo := u64(XXH32_read32(input[0:]))
		input_hi := u64(XXH32_read32(input[length - 4:]))
		input_64 := u64(input_lo) + u64(input_hi) << 32
		bitflip  := (XXH64_read64(secret[16:]) ~ XXH64_read64(secret[24:])) + seed
		keyed    := input_64 ~ bitflip

		/* Shift len to the left to ensure it is even, this avoids even multiplies. */
		m128 := XXH128_hash_t{
			h = u128(keyed) * (XXH_PRIME64_1 + u128(length) << 2),
		}
		m128.high += (m128.low  << 1)
		m128.low  ~= (m128.high >> 3)

		m128.low   = XXH_xorshift_64(m128.low, 35)
		m128.low  *= 0x9FB21C651E98DF25
		m128.low   = XXH_xorshift_64(m128.low, 28)
		m128.high  = XXH3_avalanche(m128.high)

		return m128.h
	}
}

@(optimization_mode="speed")
XXH3_len_9to16_128b :: #force_inline proc(input: []u8, secret: []u8, seed: xxh_u64) -> (res: xxh_u128) {
	length := len(input)

	#no_bounds_check {
		bitflipl := (XXH64_read64(secret[32:]) ~ XXH64_read64(secret[40:])) - seed
		bitfliph := (XXH64_read64(secret[48:]) ~ XXH64_read64(secret[56:])) + seed
		input_lo := XXH64_read64(input[0:])
		input_hi := XXH64_read64(input[length - 8:])
		m128     := XXH128_hash_t{
			h = u128(input_lo ~ input_hi ~ bitflipl) * XXH_PRIME64_1,
		}
		/*
		 * Put len in the middle of m128 to ensure that the length gets mixed to
		 * both the low and high bits in the 128x64 multiply below.
		 */
		m128.low += u64(length - 1) << 54
		input_hi ~= bitfliph
		/*
		 * Add the high 32 bits of input_hi to the high 32 bits of m128, then
		 * add the long product of the low 32 bits of input_hi and XXH_XXH_PRIME32_2 to
		 * the high 64 bits of m128.
		 */
		m128.high += input_hi + u64(u32(input_hi)) * u64(XXH_PRIME32_2 - 1)

		/* m128 ^= XXH_swap64(m128 >> 64); */
		m128.low ~= byte_swap(m128.high)
		{   /* 128x64 multiply: h128 = m128 * XXH_PRIME64_2; */
			h128 := XXH128_hash_t{
				h = u128(m128.low) * XXH_PRIME64_2,
			}
			h128.high += m128.high * XXH_PRIME64_2
			h128.low   = XXH3_avalanche(h128.low)
			h128.high  = XXH3_avalanche(h128.high)
			return h128.h
		}
	}
}

/*
	Assumption: `secret` size is >= XXH3_SECRET_SIZE_MIN
*/
@(optimization_mode="speed")
XXH3_len_0to16_128b :: #force_inline proc(input: []u8, secret: []u8, seed: xxh_u64) -> (res: xxh_u128) {
	length := len(input)

	switch {
	case length  > 8: return XXH3_len_9to16_128b(input, secret, seed)
	case length >= 4: return XXH3_len_4to8_128b (input, secret, seed)
	case length  > 0: return XXH3_len_1to3_128b (input, secret, seed)
	case:
		#no_bounds_check bitflipl := XXH64_read64(secret[64:]) ~ XXH64_read64(secret[72:])
		#no_bounds_check bitfliph := XXH64_read64(secret[80:]) ~ XXH64_read64(secret[88:])
		return xxh_u128(XXH64_avalanche(seed ~ bitflipl)) | xxh_u128(XXH64_avalanche(seed ~ bitfliph)) << 64
	}
}

/*
	A bit slower than XXH3_mix16B, but handles multiply by zero better.
*/
@(optimization_mode="speed")
XXH128_mix32B :: #force_inline proc(acc: xxh_u128, input_1: []u8, input_2: []u8, secret: []u8, seed: xxh_u64) -> (res: xxh_u128) {
	acc128 := XXH128_hash_t{
		h = acc,
	}
	#no_bounds_check {
		acc128.low  += XXH3_mix16B (input_1, secret[0:], seed)
		acc128.low  ~= XXH64_read64(input_2[0:]) + XXH64_read64(input_2[8:])
		acc128.high += XXH3_mix16B (input_2, secret[16:], seed)
		acc128.high ~= XXH64_read64(input_1) + XXH64_read64(input_1[8:])
		return acc128.h
	}
}




@(optimization_mode="speed")
XXH3_len_17to128_128b :: #force_inline proc(input: []u8, secret: []u8, seed: xxh_u64) -> (res: xxh_u128) {
	length := len(input)

	acc  := XXH128_hash_t{}
	acc.low = xxh_u64(length) * XXH_PRIME64_1

	switch{
	case length > 96:
		#no_bounds_check acc.h = XXH128_mix32B(acc.h, input[48:], input[length - 64:], secret[96:], seed)
		fallthrough
	case length > 64:
		#no_bounds_check acc.h = XXH128_mix32B(acc.h, input[32:], input[length - 48:], secret[64:], seed)
		fallthrough
	case length > 32:
		#no_bounds_check acc.h = XXH128_mix32B(acc.h, input[16:], input[length - 32:], secret[32:], seed)
		fallthrough
	case:
		#no_bounds_check acc.h = XXH128_mix32B(acc.h, input,      input[length - 16:], secret,      seed)

		h128     := XXH128_hash_t{}
		h128.low  = acc.low + acc.high
		h128.high = (acc.low * XXH_PRIME64_1) + (acc.high * XXH_PRIME64_4) + ((u64(length) - seed) * XXH_PRIME64_2)
		h128.low  = XXH3_avalanche(h128.low)
		h128.high = u64(i64(0) - i64(XXH3_avalanche(h128.high)))
		return h128.h
	}
	unreachable()
}

@(optimization_mode="speed")
XXH3_len_129to240_128b :: #force_inline proc(input: []u8, secret: []u8, seed: xxh_u64) -> (res: xxh_u128) {
	length := len(input)

	#no_bounds_check {
		acc := XXH128_hash_t{}
		acc.low = u64(length) * XXH_PRIME64_1

		nbRounds := length / 32

		i: int
		#no_bounds_check for i = 0; i < 4; i += 1 {
			acc.h = XXH128_mix32B(acc.h,
				                  input[32 * i:],
				                  input [32 * i + 16:],
				                  secret[32 * i:],
				                  seed)
		}
		acc.low  = XXH3_avalanche(acc.low)
		acc.high = XXH3_avalanche(acc.high)

		#no_bounds_check for i = 4; i < nbRounds; i += 1 {
			acc.h = XXH128_mix32B(acc.h,
				                  input[32 * i:], input[32 * i + 16:],
				                  secret[XXH3_MIDSIZE_STARTOFFSET + (32 * (i - 4)):],
								  seed)
		}
		/* last bytes */
		#no_bounds_check acc.h = XXH128_mix32B(acc.h,
							input[length - 16:],
							input[length - 32:],
							secret[XXH3_SECRET_SIZE_MIN - XXH3_MIDSIZE_LASTOFFSET - 16:],
							u64(i64(0) - i64(seed)))

		#no_bounds_check {
			h128 := XXH128_hash_t{}
			h128.low  = acc.low + acc.high
			h128.high = u64(
				        u128(acc.low  * XXH_PRIME64_1) \
			          + u128(acc.high * XXH_PRIME64_4) \
			          + u128((u64(length) - seed) * XXH_PRIME64_2))
			h128.low  = XXH3_avalanche(h128.low)
			h128.high = u64(i64(0) - i64(XXH3_avalanche(h128.high)))
			return h128.h
		}
	}
	unreachable()
}

XXH3_INIT_ACC :: [XXH_ACC_NB]xxh_u64{
	XXH_PRIME32_3, XXH_PRIME64_1, XXH_PRIME64_2, XXH_PRIME64_3,
	XXH_PRIME64_4, XXH_PRIME32_2, XXH_PRIME64_5, XXH_PRIME32_1,
}

XXH_SECRET_MERGEACCS_START :: 11

@(optimization_mode="speed")
XXH3_hashLong_128b_internal :: #force_inline proc(
			input: []u8,
			secret: []u8,
			f_acc512: XXH3_accumulate_512_f,
			f_scramble: XXH3_scramble_accumulator_f) -> (res: XXH3_128_hash) {

	acc := XXH3_INIT_ACC
	#assert(size_of(acc) == 64)

	XXH3_hashLong_internal_loop(acc[:], input, secret, f_acc512, f_scramble)

	/* converge into final hash */
	{
		length      := len(input)
		secret_size := len(secret)

		h128 := XXH128_hash_t{}
		h128.low  = XXH3_mergeAccs(acc[:], secret[XXH_SECRET_MERGEACCS_START:], u64(length) * XXH_PRIME64_1)
		h128.high = XXH3_mergeAccs(acc[:], secret[secret_size - size_of(acc) - XXH_SECRET_MERGEACCS_START:],
				~(u64(length) * XXH_PRIME64_2))
		return h128.h
	}
}

/*
 * It's important for performance that XXH3_hashLong is not inlined.
 */
XXH3_hashLong_128b_default :: #force_no_inline proc(input: []u8, seed: xxh_u64, secret: []u8) -> (res: XXH3_128_hash) {
	k_secret := XXH3_kSecret
	return XXH3_hashLong_128b_internal(input, k_secret[:], XXH3_accumulate_512, XXH3_scramble_accumulator)
}

/*
 * It's important for performance that XXH3_hashLong is not inlined.
 */
XXH3_hashLong_128b_withSecret :: #force_no_inline proc(input: []u8, seed: xxh_u64, secret: []u8) -> (res: XXH3_128_hash) {
	return XXH3_hashLong_128b_internal(input, secret, XXH3_accumulate_512, XXH3_scramble_accumulator)
}

XXH3_hashLong_128b_withSeed_internal :: #force_inline proc(
								input: []u8, seed: xxh_u64, secret: []u8,
								f_acc512: XXH3_accumulate_512_f,
								f_scramble: XXH3_scramble_accumulator_f,
								f_initSec: XXH3_init_custom_secret_f) -> (res: XXH3_128_hash) {

	if seed == 0 {
		k := XXH3_kSecret
		return XXH3_hashLong_128b_internal(input, k[:], f_acc512, f_scramble)
	}

	{
		_secret := [XXH_SECRET_DEFAULT_SIZE]u8{}
		f_initSec(_secret[:], seed)
		return XXH3_hashLong_128b_internal(input, _secret[:], f_acc512, f_scramble)
	}
}

/*
 * It's important for performance that XXH3_hashLong is not inlined.
 */
XXH3_hashLong_128b_withSeed :: #force_no_inline proc(input: []u8, seed: xxh_u64, secret: []u8) -> (res: XXH3_128_hash) {
	return XXH3_hashLong_128b_withSeed_internal(input, seed, secret, XXH3_accumulate_512, XXH3_scramble_accumulator , XXH3_init_custom_secret)
}

XXH3_hashLong128_f :: #type proc(input: []u8, seed: xxh_u64, secret: []u8)  -> (res: XXH3_128_hash)

XXH3_128bits_internal :: #force_inline proc(
	input: []u8, seed: xxh_u64, secret: []u8, f_hl128: XXH3_hashLong128_f) -> (res: XXH3_128_hash) {

	assert(len(secret) >= XXH3_SECRET_SIZE_MIN)
	/*
	 * If an action is to be taken if `secret` conditions are not respected,
	 * it should be done here.
	 * For now, it's a contract pre-condition.
	 * Adding a check and a branch here would cost performance at every hash.
	 */
	length := len(input)

	switch {
	case length <= 16:
		return XXH3_len_0to16_128b(input, secret, seed)
	case length <= 128:
		return XXH3_len_17to128_128b(input, secret, seed)
	case length <= XXH3_MIDSIZE_MAX:
		return XXH3_len_129to240_128b(input, secret, seed)
	case:
		return f_hl128(input, seed, secret)
	}
}

/* ===   Public XXH128 API   === */

XXH3_128_default :: proc(input: []u8) -> (hash: XXH3_128_hash) {
	k := XXH3_kSecret
	return XXH3_128bits_internal(input, 0, k[:], XXH3_hashLong_128b_withSeed)
}

XXH3_128_with_seed :: proc(input: []u8, seed: xxh_u64) -> (hash: XXH3_128_hash) {
	k := XXH3_kSecret
	return XXH3_128bits_internal(input, seed, k[:], XXH3_hashLong_128b_withSeed)
}

XXH3_128_with_secret :: proc(input: []u8, secret: []u8) -> (hash: XXH3_128_hash) {
	return XXH3_128bits_internal(input, 0, secret, XXH3_hashLong_128b_withSecret)
}
XXH3_128 :: proc { XXH3_128_default, XXH3_128_with_seed, XXH3_128_with_secret }

/* ===   XXH3 128-bit streaming   === */

/*
	All the functions are actually the same as for 64-bit streaming variant.
	The only difference is the finalization routine.
*/

/*

XXH_PUBLIC_API XXH_errorcode
XXH3_128bits_reset(XXH3_state_t* statePtr)
{
	if (statePtr == NULL) return XXH_ERROR;
	XXH3_reset_internal(statePtr, 0, XXH3_kSecret, XXH_SECRET_DEFAULT_SIZE);
	return XXH_OK;
}

/*! @ingroup xxh3_family */
XXH_PUBLIC_API XXH_errorcode
XXH3_128bits_reset_withSecret(XXH3_state_t* statePtr, const void* secret, size_t secretSize)
{
	if (statePtr == NULL) return XXH_ERROR;
	XXH3_reset_internal(statePtr, 0, secret, secretSize);
	if (secret == NULL) return XXH_ERROR;
	if (secretSize < XXH3_SECRET_SIZE_MIN) return XXH_ERROR;
	return XXH_OK;
}

/*! @ingroup xxh3_family */
XXH_PUBLIC_API XXH_errorcode
XXH3_128bits_reset_withSeed(XXH3_state_t* statePtr, XXH64_hash_t seed)
{
	if (statePtr == NULL) return XXH_ERROR;
	if (seed==0) return XXH3_128bits_reset(statePtr);
	if (seed != statePtr->seed) XXH3_initCustomSecret(statePtr->customSecret, seed);
	XXH3_reset_internal(statePtr, seed, NULL, XXH_SECRET_DEFAULT_SIZE);
	return XXH_OK;
}

/*! @ingroup xxh3_family */
XXH_PUBLIC_API XXH_errorcode
XXH3_128bits_update(XXH3_state_t* state, const void* input, size_t len)
{
	return XXH3_update(state, (const xxh_u8*)input, len,
					   XXH3_accumulate_512, XXH3_scrambleAcc);
}

/*! @ingroup xxh3_family */
XXH_PUBLIC_API XXH128_hash_t XXH3_128bits_digest (const XXH3_state_t* state)
{
	const unsigned char* const secret = (state->extSecret == NULL) ? state->customSecret : state->extSecret;
	if (state->totalLen > XXH3_MIDSIZE_MAX) {
		XXH_ALIGN(XXH_ACC_ALIGN) XXH64_hash_t acc[XXH_ACC_NB];
		XXH3_digest_long(acc, state, secret);
		XXH_ASSERT(state->secretLimit + XXH_STRIPE_LEN >= sizeof(acc) + XXH_SECRET_MERGEACCS_START);
		{   XXH128_hash_t h128;
			h128.low64  = XXH3_mergeAccs(acc,
										 secret + XXH_SECRET_MERGEACCS_START,
										 (xxh_u64)state->totalLen * XXH_PRIME64_1);
			h128.high64 = XXH3_mergeAccs(acc,
										 secret + state->secretLimit + XXH_STRIPE_LEN
												- sizeof(acc) - XXH_SECRET_MERGEACCS_START,
										 ~((xxh_u64)state->totalLen * XXH_PRIME64_2));
			return h128;
		}
	}
	/* len <= XXH3_MIDSIZE_MAX : short code */
	if (state->seed)
		return XXH3_128bits_withSeed(state->buffer, (size_t)state->totalLen, state->seed);
	return XXH3_128bits_withSecret(state->buffer, (size_t)(state->totalLen),
								   secret, state->secretLimit + XXH_STRIPE_LEN);
}

/* 128-bit utility functions */

#include <string.h>   /* memcmp, memcpy */

/* return : 1 is equal, 0 if different */
/*! @ingroup xxh3_family */
XXH_PUBLIC_API int XXH128_isEqual(XXH128_hash_t h1, XXH128_hash_t h2)
{
	/* note : XXH128_hash_t is compact, it has no padding byte */
	return !(memcmp(&h1, &h2, sizeof(h1)));
}

/* This prototype is compatible with stdlib's qsort().
 * return : >0 if *h128_1  > *h128_2
 *          <0 if *h128_1  < *h128_2
 *          =0 if *h128_1 == *h128_2  */
/*! @ingroup xxh3_family */
XXH_PUBLIC_API int XXH128_cmp(const void* h128_1, const void* h128_2)
{
	XXH128_hash_t const h1 = *(const XXH128_hash_t*)h128_1;
	XXH128_hash_t const h2 = *(const XXH128_hash_t*)h128_2;
	int const hcmp = (h1.high64 > h2.high64) - (h2.high64 > h1.high64);
	/* note : bets that, in most cases, hash values are different */
	if (hcmp) return hcmp;
	return (h1.low64 > h2.low64) - (h2.low64 > h1.low64);
}


/*======   Canonical representation   ======*/
/*! @ingroup xxh3_family */
XXH_PUBLIC_API void
XXH128_canonicalFromHash(XXH128_canonical_t* dst, XXH128_hash_t hash)
{
	XXH_STATIC_ASSERT(sizeof(XXH128_canonical_t) == sizeof(XXH128_hash_t));
	if (XXH_CPU_LITTLE_ENDIAN) {
		hash.high64 = XXH_swap64(hash.high64);
		hash.low64  = XXH_swap64(hash.low64);
	}
	memcpy(dst, &hash.high64, sizeof(hash.high64));
	memcpy((char*)dst + sizeof(hash.high64), &hash.low64, sizeof(hash.low64));
}

/*! @ingroup xxh3_family */
XXH_PUBLIC_API XXH128_hash_t
XXH128_hashFromCanonical(const XXH128_canonical_t* src)
{
	XXH128_hash_t h;
	h.high64 = XXH_readBE64(src);
	h.low64  = XXH_readBE64(src->digest + 8);
	return h;
}

*/


/*
	==========================================
	Short keys
	==========================================
	One of the shortcomings of XXH32 and XXH64 was that their performance was
	sub-optimal on short lengths. It used an iterative algorithm which strongly
	favored lengths that were a multiple of 4 or 8.

	Instead of iterating over individual inputs, we use a set of single shot
	functions which piece together a range of lengths and operate in constant time.
	Additionally, the number of multiplies has been significantly reduced. This
	reduces latency, especially when emulating 64-bit multiplies on 32-bit.

	Depending on the platform, this may or may not be faster than XXH32, but it
	is almost guaranteed to be faster than XXH64.
*/

/*
	At very short lengths, there isn't enough input to fully hide secrets, or use the entire secret.

	There is also only a limited amount of mixing we can do before significantly impacting performance.

	Therefore, we use different sections of the secret and always mix two secret samples with an XOR.
	This should have no effect on performance on the seedless or withSeed variants because everything
	_should_ be constant folded by modern compilers.

	The XOR mixing hides individual parts of the secret and increases entropy.
	This adds an extra layer of strength for custom secrets.
*/
@(optimization_mode="speed")
XXH3_len_1to3_64b :: #force_inline proc(input: []u8, secret: []u8, seed: xxh_u64) -> (res: xxh_u64) {
	length := u32(len(input))
	assert(input != nil)
	assert(1 <= length && length <= 3)
	assert(secret != nil)
	/*
		len = 1: combined = { input[0], 0x01, input[0], input[0] }
		len = 2: combined = { input[1], 0x02, input[0], input[1] }
		len = 3: combined = { input[2], 0x03, input[0], input[1] }
	*/
	#no_bounds_check {
		c1 := u32(input[0          ])
		c2 := u32(input[length >> 1])
		c3 := u32(input[length  - 1])

		combined := c1 << 16 | c2  << 24 | c3 << 0 | length << 8
		bitflip  := (u64(XXH32_read32(secret)) ~ u64(XXH32_read32(secret[4:]))) + seed
		keyed    := u64(combined) ~ bitflip
		return XXH64_avalanche(keyed)
	}
}

@(optimization_mode="speed")
XXH3_len_4to8_64b :: #force_inline proc(input: []u8, secret: []u8, seed: xxh_u64) -> (res: xxh_u64) {
	length := u32(len(input))
	assert(input != nil)
	assert(4 <= length && length <= 8)
	assert(secret != nil)
	seed := seed

	seed ~= (u64(byte_swap(u32(seed))) << 32)

	#no_bounds_check {
		input1  := XXH32_read32(input)
		input2  := XXH32_read32(input[length - 4:])
		bitflip := (XXH64_read64(secret[8:]) ~ XXH64_read64(secret[16:])) - seed
		input64 := u64(input2) + (u64(input1) << 32)
		keyed   := input64 ~ bitflip
		return XXH3_rrmxmx(keyed, u64(length))
	}
}

@(optimization_mode="speed")
XXH3_len_9to16_64b :: #force_inline proc(input: []u8, secret: []u8, seed: xxh_u64) -> (res: xxh_u64) {
	length := u64(len(input))
	assert(input != nil)
	assert(9 <= length && length <= 16)
	assert(secret != nil)
	#no_bounds_check {
		bitflip1 := (XXH64_read64(secret[24:]) ~ XXH64_read64(secret[32:])) + seed
		bitflip2 := (XXH64_read64(secret[40:]) ~ XXH64_read64(secret[48:])) - seed
		input_lo := XXH64_read64(input)              ~ bitflip1
		input_hi := XXH64_read64(input[length - 8:]) ~ bitflip2
		acc      := length + byte_swap(input_lo) + input_hi \
					+ XXH_mul_64_to_128_fold_64(input_lo, input_hi)
		return XXH3_avalanche(acc)
	}
}

@(optimization_mode="speed")
XXH3_len_0to16_64b :: #force_inline proc(input: []u8, secret: []u8, seed: xxh_u64) -> (res: xxh_u64) {
	length := u64(len(input))
	assert(input != nil)
	assert(length <= 16)
	#no_bounds_check {
		switch {
		case length  > 8: return #force_inline XXH3_len_9to16_64b(input, secret, seed)
		case length >= 4: return #force_inline XXH3_len_4to8_64b (input, secret, seed)
		case length  > 0: return #force_inline XXH3_len_1to3_64b (input, secret, seed)
		case:
			return #force_inline XXH64_avalanche(seed ~ (XXH64_read64(secret[56:]) ~ XXH64_read64(secret[64:])))
		}
	}
}

/*
	DISCLAIMER: There are known *seed-dependent* multicollisions here due to
	multiplication by zero, affecting hashes of lengths 17 to 240.

	However, they are very unlikely.

	Keep this in mind when using the unseeded XXH3_64bits() variant: As with all
	unseeded non-cryptographic hashes, it does not attempt to defend itself
	against specially crafted inputs, only random inputs.

	Compared to classic UMAC where a 1 in 2^31 chance of 4 consecutive bytes
	cancelling out the secret is taken an arbitrary number of times (addressed
	in XXH3_accumulate_512), this collision is very unlikely with random inputs
	and/or proper seeding:

	This only has a 1 in 2^63 chance of 8 consecutive bytes cancelling out, in a
	function that is only called up to 16 times per hash with up to 240 bytes of
	input.

	This is not too bad for a non-cryptographic hash function, especially with
	only 64 bit outputs.

	The 128-bit variant (which trades some speed for strength) is NOT affected
	by this, although it is always a good idea to use a proper seed if you care
	about strength.
*/
@(optimization_mode="speed")
XXH3_mix16B :: #force_inline proc(input: []u8, secret: []u8, seed: xxh_u64) -> (res: xxh_u64) {
	input_lo := XXH64_read64(input[0:])
	input_hi := XXH64_read64(input[8:])

	input_lo ~= (XXH64_read64(secret[0:]) + seed)
	input_hi ~= (XXH64_read64(secret[8:]) - seed)
	return XXH_mul_64_to_128_fold_64(input_lo, input_hi)
}

/* For mid range keys, XXH3 uses a Mum-hash variant. */
@(optimization_mode="speed")
XXH3_len_17to128_64b :: proc(input: []u8, secret: []u8, seed: xxh_u64) -> (res: xxh_u64) {
	assert(len(secret) >= XXH3_SECRET_SIZE_MIN)
	length := len(input)
	assert(16 < length && length <= 128)

	#no_bounds_check {
		acc := u64(length) * XXH_PRIME64_1
		switch {
		case length > 96:
			acc += XXH3_mix16B(input[48:         ], secret[96: ], seed)
			acc += XXH3_mix16B(input[length - 64:], secret[112:], seed)
			fallthrough
		case length > 64:
			acc += XXH3_mix16B(input[32:         ], secret[64: ], seed)
			acc += XXH3_mix16B(input[length - 48:], secret[80: ], seed)
			fallthrough
		case length > 32:
			acc += XXH3_mix16B(input[16:         ], secret[32: ], seed)
			acc += XXH3_mix16B(input[length - 32:], secret[48: ], seed)
			fallthrough
		case:
			acc += XXH3_mix16B(input[0:          ], secret[0:  ], seed)
			acc += XXH3_mix16B(input[length - 16:], secret[16: ], seed)
		}
		return XXH3_avalanche(acc)
	}
}

XXH3_MIDSIZE_MAX         :: 240
XXH3_MIDSIZE_STARTOFFSET :: 3
XXH3_MIDSIZE_LASTOFFSET  :: 17

@(optimization_mode="speed")
XXH3_len_129to240_64b :: proc(input: []u8, secret: []u8, seed: xxh_u64) -> (res: xxh_u64) {
	assert(len(secret) >= XXH3_SECRET_SIZE_MIN)
	length := len(input)
	assert(128 < length && length <= XXH3_MIDSIZE_MAX)

	#no_bounds_check {
		acc := u64(length) * XXH_PRIME64_1
		nbRounds := length / 16

		i: int
		for i = 0; i < 8; i += 1 {
			acc += XXH3_mix16B(input[16 * i:], secret[16 * i:], seed)
		}

		acc = XXH3_avalanche(acc)
		assert(nbRounds >= 8)

		for i = 8; i < nbRounds; i += 1 {
			acc += XXH3_mix16B(input[16 * i:], secret[(16 * (i - 8)) + XXH3_MIDSIZE_STARTOFFSET:], seed)
		}
		/* last bytes */
		acc += XXH3_mix16B(input[length - 16:], secret[XXH3_SECRET_SIZE_MIN - XXH3_MIDSIZE_LASTOFFSET:], seed)
		return XXH3_avalanche(acc)
	}
}

/* =======     Long Keys     ======= */

XXH_STRIPE_LEN          :: 64
XXH_SECRET_CONSUME_RATE :: 8 /* nb of secret bytes consumed at each accumulation */
XXH_ACC_NB              :: (XXH_STRIPE_LEN / size_of(xxh_u64))

@(optimization_mode="speed")
XXH_writeLE64 :: #force_inline proc(dst: []u8, v64: u64le) {
	v := v64
	mem_copy(raw_data(dst), &v, size_of(v64))
}

/*
 * XXH3_accumulate_512 is the tightest loop for long inputs, and it is the most optimized.
 *
 * It is a hardened version of UMAC, based off of FARSH's implementation.
 *
 * This was chosen because it adapts quite well to 32-bit, 64-bit, and SIMD
 * implementations, and it is ridiculously fast.
 *
 * We harden it by mixing the original input to the accumulators as well as the product.
 *
 * This means that in the (relatively likely) case of a multiply by zero, the
 * original input is preserved.
 *
 * On 128-bit inputs, we swap 64-bit pairs when we add the input to improve
 * cross-pollination, as otherwise the upper and lower halves would be
 * essentially independent.
 *
 * This doesn't matter on 64-bit hashes since they all get merged together in
 * the end, so we skip the extra step.
 *
 * Both XXH3_64bits and XXH3_128bits use this subroutine.
 */

XXH3_accumulate_512_f       :: #type proc(acc: []xxh_u64, input:  []u8, secret: []u8)
XXH3_scramble_accumulator_f :: #type proc(acc: []xxh_u64, secret: []u8)
XXH3_init_custom_secret_f   :: #type proc(custom_secret: []u8, seed64: xxh_u64)

XXH3_accumulate_512       : XXH3_accumulate_512_f       = XXH3_accumulate_512_scalar
XXH3_scramble_accumulator : XXH3_scramble_accumulator_f = XXH3_scramble_accumulator_scalar
XXH3_init_custom_secret   : XXH3_init_custom_secret_f   = XXH3_init_custom_secret_scalar

/* scalar variants - universal */
@(optimization_mode="speed")
XXH3_accumulate_512_scalar :: #force_inline proc(acc: []xxh_u64, input: []u8, secret: []u8) {
	xacc    := acc     /* presumed aligned */
	xinput  := input   /* no alignment restriction */
	xsecret := secret  /* no alignment restriction */

	assert(uintptr(raw_data(acc)) & uintptr(XXH_ACC_ALIGN - 1) == 0)

	#no_bounds_check for i := uint(0); i < XXH_ACC_NB; i += 1 {
		data_val    := XXH64_read64(xinput[8 * i:])
		data_key    := data_val ~ XXH64_read64(xsecret[8 * i:])
		xacc[i ~ 1] += data_val /* swap adjacent lanes */
		xacc[i    ] += u64(u32(data_key)) * u64(data_key >> 32)
	}
}

@(optimization_mode="speed")
XXH3_scramble_accumulator_scalar :: #force_inline proc(acc: []xxh_u64, secret: []u8) {
	xacc    := acc     /* presumed aligned */
	xsecret := secret  /* no alignment restriction */

	assert(uintptr(raw_data(acc)) & uintptr(XXH_ACC_ALIGN - 1) == 0)

	#no_bounds_check for i := uint(0); i < XXH_ACC_NB; i += 1 {
		key64   := XXH64_read64(xsecret[8 * i:])
		acc64   := xacc[i]
		acc64    = XXH_xorshift_64(acc64, 47)
		acc64   ~= key64
		acc64   *= u64(XXH_PRIME32_1)
		xacc[i]  = acc64
	}
}

@(optimization_mode="speed")
XXH3_init_custom_secret_scalar :: #force_inline proc(custom_secret: []u8, seed64: xxh_u64) {
	#assert((XXH_SECRET_DEFAULT_SIZE & 15) == 0)

	kSecretPtr := XXH3_kSecret

	nbRounds := XXH_SECRET_DEFAULT_SIZE / 16
	#no_bounds_check for i := 0; i < nbRounds; i += 1 {
		lo := XXH64_read64(kSecretPtr[16 * i:    ]) + seed64
		hi := XXH64_read64(kSecretPtr[16 * i + 8:]) - seed64
		XXH_writeLE64(custom_secret[16 * i:    ], u64le(lo))
		XXH_writeLE64(custom_secret[16 * i + 8:], u64le(hi))
	}
}

XXH_PREFETCH_DIST :: 320

/*
 * XXH3_accumulate()
 * Loops over XXH3_accumulate_512().
 * Assumption: nbStripes will not overflow the secret size
 */
@(optimization_mode="speed")
XXH3_accumulate :: #force_inline proc(acc: []xxh_u64, input: []u8, secret: []u8, nbStripes: uint,
	f_acc512: XXH3_accumulate_512_f) {

	for n := uint(0); n < nbStripes; n += 1 {
		when !XXH_DISABLE_PREFETCH {
			in_ptr := &input[n * XXH_STRIPE_LEN]
			prefetch(in_ptr, XXH_PREFETCH_DIST)
		}
		f_acc512(acc, input[n * XXH_STRIPE_LEN:], secret[n * XXH_SECRET_CONSUME_RATE:])
	}
}

@(optimization_mode="speed")
XXH3_hashLong_internal_loop :: #force_inline proc(acc: []xxh_u64, input: []u8, secret: []u8,
	f_acc512: XXH3_accumulate_512_f, f_scramble: XXH3_scramble_accumulator_f) {

	length      := uint(len(input))
	secret_size := uint(len(secret))
	stripes_per_block := (secret_size - XXH_STRIPE_LEN) / XXH_SECRET_CONSUME_RATE

	block_len   := XXH_STRIPE_LEN * stripes_per_block
	blocks      := (length - 1) / block_len

	#no_bounds_check for n := uint(0); n < blocks; n += 1 {
		XXH3_accumulate(acc, input[n * block_len:], secret, stripes_per_block, f_acc512)
		f_scramble(acc, secret[secret_size - XXH_STRIPE_LEN:])
	}

	/* last partial block */
	#no_bounds_check {
		stripes := ((length - 1) - (block_len * blocks)) / XXH_STRIPE_LEN
		XXH3_accumulate(acc, input[blocks * block_len:], secret, stripes, f_acc512)

		/* last stripe */
		#no_bounds_check {
			p := input[length - XXH_STRIPE_LEN:]
			XXH_SECRET_LASTACC_START :: 7  /* not aligned on 8, last secret is different from acc & scrambler */
			f_acc512(acc, p, secret[secret_size - XXH_STRIPE_LEN - XXH_SECRET_LASTACC_START:])
		}
	}
}

@(optimization_mode="speed")
XXH3_mix2Accs :: #force_inline proc(acc: []xxh_u64, secret: []u8) -> (res: xxh_u64) {
	return XXH_mul_64_to_128_fold_64(
		acc[0] ~ XXH64_read64(secret),
		acc[1] ~ XXH64_read64(secret[8:]))
}

@(optimization_mode="speed")
XXH3_mergeAccs :: #force_inline proc(acc: []xxh_u64, secret: []u8, start: xxh_u64) -> (res: xxh_u64) {
	result64 := start
	#no_bounds_check for i := 0; i < 4; i += 1 {
		result64 += XXH3_mix2Accs(acc[2 * i:], secret[16 * i:])
	}
	return XXH3_avalanche(result64)
}

@(optimization_mode="speed")
XXH3_hashLong_64b_internal :: #force_inline proc(input: []u8, secret: []u8,
			f_acc512: XXH3_accumulate_512_f, f_scramble: XXH3_scramble_accumulator_f) -> (hash: xxh_u64) {

	acc: [XXH_ACC_NB]xxh_u64 = XXH3_INIT_ACC

	XXH3_hashLong_internal_loop(acc[:], input, secret, f_acc512, f_scramble)

	/* converge into final hash */
	#assert(size_of(acc) == 64)
	/* do not align on 8, so that the secret is different from the accumulator */
	XXH_SECRET_MERGEACCS_START :: 11
	assert(len(secret) >= size_of(acc) + XXH_SECRET_MERGEACCS_START)
	return XXH3_mergeAccs(acc[:], secret[XXH_SECRET_MERGEACCS_START:], xxh_u64(len(input)) * XXH_PRIME64_1)
}

/*
	It's important for performance that XXH3_hashLong is not inlined.
*/
XXH3_hashLong_64b_withSecret :: #force_no_inline proc(input: []u8, seed64: xxh_u64, secret: []u8) -> (hash: xxh_u64) {
	return XXH3_hashLong_64b_internal(input, secret, XXH3_accumulate_512, XXH3_scramble_accumulator)
}

/*
	It's important for performance that XXH3_hashLong is not inlined.
	Since the function is not inlined, the compiler may not be able to understand that,
	in some scenarios, its `secret` argument is actually a compile time constant.
	This variant enforces that the compiler can detect that,
	and uses this opportunity to streamline the generated code for better performance.
*/
XXH3_hashLong_64b_default :: #force_no_inline proc(input: []u8, seed64: xxh_u64, secret: []u8) -> (hash: xxh_u64) {
	k := XXH3_kSecret	
	return XXH3_hashLong_64b_internal(input, k[:], XXH3_accumulate_512, XXH3_scramble_accumulator)
}

/*
	XXH3_hashLong_64b_withSeed():
	Generate a custom key based on alteration of default XXH3_kSecret with the seed,
	and then use this key for long mode hashing.

	This operation is decently fast but nonetheless costs a little bit of time.
	Try to avoid it whenever possible (typically when seed==0).

	It's important for performance that XXH3_hashLong is not inlined. Not sure
	why (uop cache maybe?), but the difference is large and easily measurable.
*/
XXH3_hashLong_64b_withSeed_internal :: #force_no_inline proc(input: []u8,
									seed:        xxh_u64,
									f_acc512:    XXH3_accumulate_512_f,
									f_scramble:  XXH3_scramble_accumulator_f,
									f_init_sec:  XXH3_init_custom_secret_f) -> (hash: xxh_u64) {
	if seed == 0 {
		k := XXH3_kSecret
		return XXH3_hashLong_64b_internal(input, k[:], f_acc512, f_scramble)
	}
	{
		secret: [XXH_SECRET_DEFAULT_SIZE]u8
		f_init_sec(secret[:], seed)
		return XXH3_hashLong_64b_internal(input, secret[:], f_acc512, f_scramble)
	}
}

/*
	It's important for performance that XXH3_hashLong is not inlined.
*/
XXH3_hashLong_64b_withSeed :: #force_no_inline proc(input: []u8, seed: xxh_u64, secret: []u8) -> (hash: xxh_u64) {
	return XXH3_hashLong_64b_withSeed_internal(input, seed, XXH3_accumulate_512, XXH3_scramble_accumulator, XXH3_init_custom_secret)
}


XXH3_hashLong64_f :: #type proc(input: []u8, seed: xxh_u64, secret: []u8)  -> (res: xxh_u64)

XXH3_64bits_internal :: proc(input: []u8, seed: xxh_u64, secret: []u8, f_hashLong: XXH3_hashLong64_f) -> (hash: xxh_u64) {




	assert(len(secret) >= XXH3_SECRET_SIZE_MIN)
	/*
		If an action is to be taken if len(secret) condition is not respected, it should be done here.
		For now, it's a contract pre-condition.
		Adding a check and a branch here would cost performance at every hash.
		Also, note that function signature doesn't offer room to return an error.
	*/
	length := len(input)
	switch {
	case length <=  16: return XXH3_len_0to16_64b(input, secret, seed)
	case length <= 128: return XXH3_len_17to128_64b(input, secret, seed)
	case length <= XXH3_MIDSIZE_MAX: return XXH3_len_129to240_64b(input, secret, seed)
	case: return f_hashLong(input, seed, secret)
	}
	unreachable()
}

/* ===   Public entry point   === */

XXH3_64_default :: proc(input: []u8) -> (hash: xxh_u64) {
	k := XXH3_kSecret
	return XXH3_64bits_internal(input, 0, k[:], XXH3_hashLong_64b_default)
}

XXH3_64_with_seed :: proc(input: []u8, seed: xxh_u64) -> (hash: xxh_u64) {
	k := XXH3_kSecret
	return XXH3_64bits_internal(input, seed, k[:], XXH3_hashLong_64b_withSeed)
}

XXH3_64_with_secret :: proc(input, secret: []u8) -> (hash: xxh_u64) {
	return XXH3_64bits_internal(input, 0, secret, XXH3_hashLong_64b_withSecret)
}

XXH3_64 :: proc { XXH3_64_default, XXH3_64_with_seed, XXH3_64_with_secret }

/*

/* ===   XXH3 streaming   === */

/*
 * Malloc's a pointer that is always aligned to align.
 *
 * This must be freed with `XXH_alignedFree()`.
 *
 * malloc typically guarantees 16 byte alignment on 64-bit systems and 8 byte
 * alignment on 32-bit. This isn't enough for the 32 byte aligned loads in AVX2
 * or on 32-bit, the 16 byte aligned loads in SSE2 and NEON.
 *
 * This underalignment previously caused a rather obvious crash which went
 * completely unnoticed due to XXH3_createState() not actually being tested.
 * Credit to RedSpah for noticing this bug.
 *
 * The alignment is done manually: Functions like posix_memalign or _mm_malloc
 * are avoided: To maintain portability, we would have to write a fallback
 * like this anyways, and besides, testing for the existence of library
 * functions without relying on external build tools is impossible.
 *
 * The method is simple: Overallocate, manually align, and store the offset
 * to the original behind the returned pointer.
 *
 * Align must be a power of 2 and 8 <= align <= 128.
 */
static void* XXH_alignedMalloc(size_t s, size_t align)
{
	XXH_ASSERT(align <= 128 && align >= 8); /* range check */
	XXH_ASSERT((align & (align-1)) == 0);   /* power of 2 */
	XXH_ASSERT(s != 0 && s < (s + align));  /* empty/overflow */
	{   /* Overallocate to make room for manual realignment and an offset byte */
		xxh_u8* base = (xxh_u8*)XXH_malloc(s + align);
		if (base != NULL) {
			/*
			 * Get the offset needed to align this pointer.
			 *
			 * Even if the returned pointer is aligned, there will always be
			 * at least one byte to store the offset to the original pointer.
			 */
			size_t offset = align - ((size_t)base & (align - 1)); /* base % align */
			/* Add the offset for the now-aligned pointer */
			xxh_u8* ptr = base + offset;

			XXH_ASSERT((size_t)ptr % align == 0);

			/* Store the offset immediately before the returned pointer. */
			ptr[-1] = (xxh_u8)offset;
			return ptr;
		}
		return NULL;
	}
}
/*
 * Frees an aligned pointer allocated by XXH_alignedMalloc(). Don't pass
 * normal malloc'd pointers, XXH_alignedMalloc has a specific data layout.
 */
static void XXH_alignedFree(void* p)
{
	if (p != NULL) {
		xxh_u8* ptr = (xxh_u8*)p;
		/* Get the offset byte we added in XXH_malloc. */
		xxh_u8 offset = ptr[-1];
		/* Free the original malloc'd pointer */
		xxh_u8* base = ptr - offset;
		XXH_free(base);
	}
}
/*! @ingroup xxh3_family */
XXH_PUBLIC_API XXH3_state_t* XXH3_createState(void)
{
	XXH3_state_t* const state = (XXH3_state_t*)XXH_alignedMalloc(sizeof(XXH3_state_t), 64);
	if (state==NULL) return NULL;
	XXH3_INITSTATE(state);
	return state;
}

/*! @ingroup xxh3_family */
XXH_PUBLIC_API XXH_errorcode XXH3_freeState(XXH3_state_t* statePtr)
{
	XXH_alignedFree(statePtr);
	return XXH_OK;
}

/*! @ingroup xxh3_family */
XXH_PUBLIC_API void
XXH3_copyState(XXH3_state_t* dst_state, const XXH3_state_t* src_state)
{
	memcpy(dst_state, src_state, sizeof(*dst_state));
}

static void
XXH3_reset_internal(XXH3_state_t* statePtr,
						   XXH64_hash_t seed,
						   const void* secret, size_t secretSize)
{
	size_t const initStart = offsetof(XXH3_state_t, bufferedSize);
	size_t const initLength = offsetof(XXH3_state_t, nbStripesPerBlock) - initStart;
	XXH_ASSERT(offsetof(XXH3_state_t, nbStripesPerBlock) > initStart);
	XXH_ASSERT(statePtr != NULL);
	/* set members from bufferedSize to nbStripesPerBlock (excluded) to 0 */
	memset((char*)statePtr + initStart, 0, initLength);
	statePtr->acc[0] = XXH_XXH_PRIME32_3;
	statePtr->acc[1] = XXH_PRIME64_1;
	statePtr->acc[2] = XXH_PRIME64_2;
	statePtr->acc[3] = XXH_PRIME64_3;
	statePtr->acc[4] = XXH_PRIME64_4;
	statePtr->acc[5] = XXH_XXH_PRIME32_2;
	statePtr->acc[6] = XXH_PRIME64_5;
	statePtr->acc[7] = XXH_XXH_PRIME32_1;
	statePtr->seed = seed;
	statePtr->extSecret = (const unsigned char*)secret;
	XXH_ASSERT(secretSize >= XXH3_SECRET_SIZE_MIN);
	statePtr->secretLimit = secretSize - XXH_STRIPE_LEN;
	statePtr->nbStripesPerBlock = statePtr->secretLimit / XXH_SECRET_CONSUME_RATE;
}

/*! @ingroup xxh3_family */
XXH_PUBLIC_API XXH_errorcode
XXH3_64bits_reset(XXH3_state_t* statePtr)
{
	if (statePtr == NULL) return XXH_ERROR;
	XXH3_reset_internal(statePtr, 0, XXH3_kSecret, XXH_SECRET_DEFAULT_SIZE);
	return XXH_OK;
}

/*! @ingroup xxh3_family */
XXH_PUBLIC_API XXH_errorcode
XXH3_64bits_reset_withSecret(XXH3_state_t* statePtr, const void* secret, size_t secretSize)
{
	if (statePtr == NULL) return XXH_ERROR;
	XXH3_reset_internal(statePtr, 0, secret, secretSize);
	if (secret == NULL) return XXH_ERROR;
	if (secretSize < XXH3_SECRET_SIZE_MIN) return XXH_ERROR;
	return XXH_OK;
}

/*! @ingroup xxh3_family */
XXH_PUBLIC_API XXH_errorcode
XXH3_64bits_reset_withSeed(XXH3_state_t* statePtr, XXH64_hash_t seed)
{
	if (statePtr == NULL) return XXH_ERROR;
	if (seed==0) return XXH3_64bits_reset(statePtr);
	if (seed != statePtr->seed) XXH3_initCustomSecret(statePtr->customSecret, seed);
	XXH3_reset_internal(statePtr, seed, NULL, XXH_SECRET_DEFAULT_SIZE);
	return XXH_OK;
}

/* Note : when XXH3_consumeStripes() is invoked,
 * there must be a guarantee that at least one more byte must be consumed from input
 * so that the function can blindly consume all stripes using the "normal" secret segment */
XXH_FORCE_INLINE void
XXH3_consumeStripes(xxh_u64* XXH_RESTRICT acc,
					size_t* XXH_RESTRICT nbStripesSoFarPtr, size_t nbStripesPerBlock,
					const xxh_u8* XXH_RESTRICT input, size_t nbStripes,
					const xxh_u8* XXH_RESTRICT secret, size_t secretLimit,
					XXH3_f_accumulate_512 f_acc512,
					XXH3_f_scrambleAcc f_scramble)
{
	XXH_ASSERT(nbStripes <= nbStripesPerBlock);  /* can handle max 1 scramble per invocation */
	XXH_ASSERT(*nbStripesSoFarPtr < nbStripesPerBlock);
	if (nbStripesPerBlock - *nbStripesSoFarPtr <= nbStripes) {
		/* need a scrambling operation */
		size_t const nbStripesToEndofBlock = nbStripesPerBlock - *nbStripesSoFarPtr;
		size_t const nbStripesAfterBlock = nbStripes - nbStripesToEndofBlock;
		XXH3_accumulate(acc, input, secret + nbStripesSoFarPtr[0] * XXH_SECRET_CONSUME_RATE, nbStripesToEndofBlock, f_acc512);
		f_scramble(acc, secret + secretLimit);
		XXH3_accumulate(acc, input + nbStripesToEndofBlock * XXH_STRIPE_LEN, secret, nbStripesAfterBlock, f_acc512);
		*nbStripesSoFarPtr = nbStripesAfterBlock;
	} else {
		XXH3_accumulate(acc, input, secret + nbStripesSoFarPtr[0] * XXH_SECRET_CONSUME_RATE, nbStripes, f_acc512);
		*nbStripesSoFarPtr += nbStripes;
	}
}

/*
 * Both XXH3_64bits_update and XXH3_128bits_update use this routine.
 */
XXH_FORCE_INLINE XXH_errorcode
XXH3_update(XXH3_state_t* state,
			const xxh_u8* input, size_t len,
			XXH3_f_accumulate_512 f_acc512,
			XXH3_f_scrambleAcc f_scramble)
{
	if (input==NULL)
#if defined(XXH_ACCEPT_NULL_INPUT_POINTER) && (XXH_ACCEPT_NULL_INPUT_POINTER>=1)
		return XXH_OK;
#else
		return XXH_ERROR;
#endif

	{   const xxh_u8* const bEnd = input + len;
		const unsigned char* const secret = (state->extSecret == NULL) ? state->customSecret : state->extSecret;

		state->totalLen += len;
		XXH_ASSERT(state->bufferedSize <= XXH3_INTERNALBUFFER_SIZE);

		if (state->bufferedSize + len <= XXH3_INTERNALBUFFER_SIZE) {  /* fill in tmp buffer */
			XXH_memcpy(state->buffer + state->bufferedSize, input, len);
			state->bufferedSize += (XXH32_hash_t)len;
			return XXH_OK;
		}
		/* total input is now > XXH3_INTERNALBUFFER_SIZE */

		#define XXH3_INTERNALBUFFER_STRIPES (XXH3_INTERNALBUFFER_SIZE / XXH_STRIPE_LEN)
		XXH_STATIC_ASSERT(XXH3_INTERNALBUFFER_SIZE % XXH_STRIPE_LEN == 0);   /* clean multiple */

		/*
		 * Internal buffer is partially filled (always, except at beginning)
		 * Complete it, then consume it.
		 */
		if (state->bufferedSize) {
			size_t const loadSize = XXH3_INTERNALBUFFER_SIZE - state->bufferedSize;
			XXH_memcpy(state->buffer + state->bufferedSize, input, loadSize);
			input += loadSize;
			XXH3_consumeStripes(state->acc,
							   &state->nbStripesSoFar, state->nbStripesPerBlock,
								state->buffer, XXH3_INTERNALBUFFER_STRIPES,
								secret, state->secretLimit,
								f_acc512, f_scramble);
			state->bufferedSize = 0;
		}
		XXH_ASSERT(input < bEnd);

		/* Consume input by a multiple of internal buffer size */
		if (bEnd - input > XXH3_INTERNALBUFFER_SIZE) {
			const xxh_u8* const limit = bEnd - XXH3_INTERNALBUFFER_SIZE;
			do {
				XXH3_consumeStripes(state->acc,
								   &state->nbStripesSoFar, state->nbStripesPerBlock,
									input, XXH3_INTERNALBUFFER_STRIPES,
									secret, state->secretLimit,
									f_acc512, f_scramble);
				input += XXH3_INTERNALBUFFER_SIZE;
			} while (input<limit);
			/* for last partial stripe */
			memcpy(state->buffer + sizeof(state->buffer) - XXH_STRIPE_LEN, input - XXH_STRIPE_LEN, XXH_STRIPE_LEN);
		}
		XXH_ASSERT(input < bEnd);

		/* Some remaining input (always) : buffer it */
		XXH_memcpy(state->buffer, input, (size_t)(bEnd-input));
		state->bufferedSize = (XXH32_hash_t)(bEnd-input);
	}

	return XXH_OK;
}

/*! @ingroup xxh3_family */
XXH_PUBLIC_API XXH_errorcode
XXH3_64bits_update(XXH3_state_t* state, const void* input, size_t len)
{
	return XXH3_update(state, (const xxh_u8*)input, len,
					   XXH3_accumulate_512, XXH3_scrambleAcc);
}


XXH_FORCE_INLINE void
XXH3_digest_long (XXH64_hash_t* acc,
				  const XXH3_state_t* state,
				  const unsigned char* secret)
{
	/*
	 * Digest on a local copy. This way, the state remains unaltered, and it can
	 * continue ingesting more input afterwards.
	 */
	memcpy(acc, state->acc, sizeof(state->acc));
	if (state->bufferedSize >= XXH_STRIPE_LEN) {
		size_t const nbStripes = (state->bufferedSize - 1) / XXH_STRIPE_LEN;
		size_t nbStripesSoFar = state->nbStripesSoFar;
		XXH3_consumeStripes(acc,
						   &nbStripesSoFar, state->nbStripesPerBlock,
							state->buffer, nbStripes,
							secret, state->secretLimit,
							XXH3_accumulate_512, XXH3_scrambleAcc);
		/* last stripe */
		XXH3_accumulate_512(acc,
							state->buffer + state->bufferedSize - XXH_STRIPE_LEN,
							secret + state->secretLimit - XXH_SECRET_LASTACC_START);
	} else {  /* bufferedSize < XXH_STRIPE_LEN */
		xxh_u8 lastStripe[XXH_STRIPE_LEN];
		size_t const catchupSize = XXH_STRIPE_LEN - state->bufferedSize;
		XXH_ASSERT(state->bufferedSize > 0);  /* there is always some input buffered */
		memcpy(lastStripe, state->buffer + sizeof(state->buffer) - catchupSize, catchupSize);
		memcpy(lastStripe + catchupSize, state->buffer, state->bufferedSize);
		XXH3_accumulate_512(acc,
							lastStripe,
							secret + state->secretLimit - XXH_SECRET_LASTACC_START);
	}
}

/*! @ingroup xxh3_family */
XXH_PUBLIC_API XXH64_hash_t XXH3_64bits_digest (const XXH3_state_t* state)
{
	const unsigned char* const secret = (state->extSecret == NULL) ? state->customSecret : state->extSecret;
	if (state->totalLen > XXH3_MIDSIZE_MAX) {
		XXH_ALIGN(XXH_ACC_ALIGN) XXH64_hash_t acc[XXH_ACC_NB];
		XXH3_digest_long(acc, state, secret);
		return XXH3_mergeAccs(acc,
							  secret + XXH_SECRET_MERGEACCS_START,
							  (xxh_u64)state->totalLen * XXH_PRIME64_1);
	}
	/* totalLen <= XXH3_MIDSIZE_MAX: digesting a short input */
	if (state->seed)
		return XXH3_64bits_withSeed(state->buffer, (size_t)state->totalLen, state->seed);
	return XXH3_64bits_withSecret(state->buffer, (size_t)(state->totalLen),
								  secret, state->secretLimit + XXH_STRIPE_LEN);
}


#define XXH_MIN(x, y) (((x) > (y)) ? (y) : (x))

/*! @ingroup xxh3_family */
XXH_PUBLIC_API void
XXH3_generateSecret(void* secretBuffer, const void* customSeed, size_t customSeedSize)
{
	XXH_ASSERT(secretBuffer != NULL);
	if (customSeedSize == 0) {
		memcpy(secretBuffer, XXH3_kSecret, XXH_SECRET_DEFAULT_SIZE);
		return;
	}
	XXH_ASSERT(customSeed != NULL);

	{   size_t const segmentSize = sizeof(XXH128_hash_t);
		size_t const nbSegments = XXH_SECRET_DEFAULT_SIZE / segmentSize;
		XXH128_canonical_t scrambler;
		XXH64_hash_t seeds[12];
		size_t segnb;
		XXH_ASSERT(nbSegments == 12);
		XXH_ASSERT(segmentSize * nbSegments == XXH_SECRET_DEFAULT_SIZE); /* exact multiple */
		XXH128_canonicalFromHash(&scrambler, XXH128(customSeed, customSeedSize, 0));

		/*
		* Copy customSeed to seeds[], truncating or repeating as necessary.
		*/
		{   size_t toFill = XXH_MIN(customSeedSize, sizeof(seeds));
			size_t filled = toFill;
			memcpy(seeds, customSeed, toFill);
			while (filled < sizeof(seeds)) {
				toFill = XXH_MIN(filled, sizeof(seeds) - filled);
				memcpy((char*)seeds + filled, seeds, toFill);
				filled += toFill;
		}   }

		/* generate secret */
		memcpy(secretBuffer, &scrambler, sizeof(scrambler));
		for (segnb=1; segnb < nbSegments; segnb++) {
			size_t const segmentStart = segnb * segmentSize;
			XXH128_canonical_t segment;
			XXH128_canonicalFromHash(&segment,
				XXH128(&scrambler, sizeof(scrambler), XXH64_read64(seeds + segnb) + segnb) );
			memcpy((char*)secretBuffer + segmentStart, &segment, sizeof(segment));
	}   }
}

*/
