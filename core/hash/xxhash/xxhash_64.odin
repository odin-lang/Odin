/*
	An implementation of Yann Collet's [xxhash Fast Hash Algorithm](https://cyan4973.github.io/xxHash/).
	Copyright 2021 Jeroen van Rijn <nom@duclavier.com>.

	Made available under Odin's BSD-3 license, based on the original C code.

	List of contributors:
		Jeroen van Rijn: Initial implementation.
*/

package xxhash

import "base:intrinsics"

/*
	64-bit hash functions
*/
XXH64_hash :: u64
xxh_u64    :: u64
XXH64_DEFAULT_SEED :: XXH64_hash(0)

XXH64_state :: struct {
	total_len:    XXH64_hash,    /*!< Total length hashed. This is always 64-bit. */
	v1:           XXH64_hash,    /*!< First accumulator lane */
	v2:           XXH64_hash,    /*!< Second accumulator lane */
	v3:           XXH64_hash,    /*!< Third accumulator lane */
	v4:           XXH64_hash,    /*!< Fourth accumulator lane */
	mem64:        [4]XXH64_hash, /*!< Internal buffer for partial reads. Treated as unsigned char[32]. */
	memsize:      XXH32_hash,    /*!< Amount of data in @ref mem64 */
	reserved32:   XXH32_hash,    /*!< Reserved field, needed for padding anyways*/
	reserved64:   XXH64_hash,    /*!< Reserved field. Do not read or write to it, it may be removed. */
}

XXH64_canonical :: struct {
	digest: [8]u8,
}

XXH_PRIME64_1 :: 0x9E3779B185EBCA87 /*!< 0b1001111000110111011110011011000110000101111010111100101010000111 */
XXH_PRIME64_2 :: 0xC2B2AE3D27D4EB4F /*!< 0b1100001010110010101011100011110100100111110101001110101101001111 */
XXH_PRIME64_3 :: 0x165667B19E3779F9 /*!< 0b0001011001010110011001111011000110011110001101110111100111111001 */
XXH_PRIME64_4 :: 0x85EBCA77C2B2AE63 /*!< 0b1000010111101011110010100111011111000010101100101010111001100011 */
XXH_PRIME64_5 :: 0x27D4EB2F165667C5 /*!< 0b0010011111010100111010110010111100010110010101100110011111000101 */

@(optimization_mode="favor_size")
XXH64_round :: proc(acc, input: xxh_u64) -> (res: xxh_u64) {
	acc := acc

	acc += input * XXH_PRIME64_2
	acc  = XXH_rotl64(acc, 31)
	acc *= XXH_PRIME64_1
	return acc
}

@(optimization_mode="favor_size")
XXH64_mergeRound :: proc(acc, val: xxh_u64) -> (res: xxh_u64) {
	res  = acc ~ XXH64_round(0, val)
	res  = res * XXH_PRIME64_1 + XXH_PRIME64_4
	return res
}

@(optimization_mode="favor_size")
XXH64_avalanche :: proc(h64: xxh_u64) -> (res: xxh_u64) {
	res = h64
	res ~= res >> 33
	res *= XXH_PRIME64_2
	res ~= res >> 29
	res *= XXH_PRIME64_3
	res ~= res >> 32
	return res
}

@(optimization_mode="favor_size")
XXH64_finalize :: proc(h64: xxh_u64, buf: []u8, alignment: Alignment) -> (res: xxh_u64) {
	buf := buf
	length := len(buf) & 31
	res = h64

	for length >= 8 {
		b := XXH64_read64(buf, alignment)
		k1 := XXH64_round(0, b)
		#no_bounds_check buf = buf[8:]
		res ~= k1
		res  = XXH_rotl64(res, 27) * XXH_PRIME64_1 + XXH_PRIME64_4
		length -= 8
	}

	if length >= 4 {
		res ~= xxh_u64(XXH32_read32(buf, alignment)) * XXH_PRIME64_1
		#no_bounds_check buf = buf[4:]
		res = XXH_rotl64(res, 23) * XXH_PRIME64_2 + XXH_PRIME64_3
		length -= 4
	}

	for length > 0 {
		#no_bounds_check b := xxh_u64(buf[0])
		buf = buf[1:]
		res ~= b * XXH_PRIME64_5
		res = XXH_rotl64(res, 11) * XXH_PRIME64_1
		length -= 1
	}
	return XXH64_avalanche(res)
}

@(optimization_mode="favor_size")
XXH64_endian_align :: proc(input: []u8, seed := XXH64_DEFAULT_SEED, alignment := Alignment.Unaligned) -> (res: xxh_u64) {
	buf    := input
	length := len(buf)

	if length >= 32 {
		v1 := seed + XXH_PRIME64_1 + XXH_PRIME64_2
		v2 := seed + XXH_PRIME64_2
		v3 := seed + 0
		v4 := seed - XXH_PRIME64_1

		for len(buf) >= 32 {
			v1 = XXH64_round(v1, XXH64_read64(buf, alignment)); buf = buf[8:]
			v2 = XXH64_round(v2, XXH64_read64(buf, alignment)); buf = buf[8:]
			v3 = XXH64_round(v3, XXH64_read64(buf, alignment)); buf = buf[8:]
			v4 = XXH64_round(v4, XXH64_read64(buf, alignment)); buf = buf[8:]
		}

		res = XXH_rotl64(v1, 1) + XXH_rotl64(v2, 7) + XXH_rotl64(v3, 12) + XXH_rotl64(v4, 18)
		res = XXH64_mergeRound(res, v1)
		res = XXH64_mergeRound(res, v2)
		res = XXH64_mergeRound(res, v3)
		res = XXH64_mergeRound(res, v4)
	} else {
		res = seed + XXH_PRIME64_5
	}
	res += xxh_u64(length)

	return XXH64_finalize(res, buf, alignment)
}

XXH64 :: proc(input: []u8, seed := XXH64_DEFAULT_SEED) -> (digest: XXH64_hash) {
	when false {
		/*
			Simple version, good for code maintenance, but unfortunately slow for small inputs.
		*/
		state: XXH64_state
		XXH64_reset_state(&state, seed)
		buf := input
		for len(buf) > 0 {
			l := min(65536, len(buf))
			XXH64_update(&state, buf[:l])
			buf = buf[l:]
		}
		return XXH64_digest(&state)
	} else {
		when XXH_FORCE_ALIGN_CHECK {
			if uintptr(raw_data(input)) & uintptr(7) == 0 {
				/*
					Input is 8-bytes aligned, leverage the speed benefit.
				*/
				return XXH64_endian_align(input, seed, .Aligned)
			}
		}
		return XXH64_endian_align(input, seed, .Unaligned)
	}
}

/*
	******   Hash Streaming   ******
*/
XXH64_create_state :: proc(allocator := context.allocator) -> (res: ^XXH64_state, err: Error) {
	state := new(XXH64_state, allocator)
	XXH64_reset_state(state)
	return state, .None if state != nil else .Error
}

XXH64_destroy_state :: proc(state: ^XXH64_state, allocator := context.allocator) -> (err: Error) {
	free(state, allocator)
	return .None
}

XXH64_copy_state :: proc(dest, src: ^XXH64_state) {
	assert(dest != nil && src != nil)
	mem_copy(dest, src, size_of(XXH64_state))
}

XXH64_reset_state :: proc(state_ptr: ^XXH64_state, seed := XXH64_DEFAULT_SEED) -> (err: Error) {
	state := XXH64_state{}

	state.v1 = seed + XXH_PRIME64_1 + XXH_PRIME64_2
	state.v2 = seed + XXH_PRIME64_2
	state.v3 = seed + 0
	state.v4 = seed - XXH_PRIME64_1
	/*
		Fo not write into reserved64, might be removed in a future version.
	*/
	mem_copy(state_ptr, &state, size_of(state) - size_of(state.reserved64))
	return .None
}

@(optimization_mode="favor_size")
XXH64_update :: proc(state: ^XXH64_state, input: []u8) -> (err: Error) {
	buf    := input
	length := len(buf)

	state.total_len += u64(length)

	if state.memsize + u32(length) < 32 {  /* fill in tmp buffer */
		ptr := uintptr(raw_data(state.mem64[:])) + uintptr(state.memsize)
		mem_copy(rawptr(ptr), raw_data(input), int(length))
		state.memsize += u32(length)
		return .None
	}

	if state.memsize > 0 {   /* tmp buffer is full */
		ptr := uintptr(raw_data(state.mem64[:])) + uintptr(state.memsize)
		mem_copy(rawptr(ptr), raw_data(input), int(32 - state.memsize))
		{
			#no_bounds_check state.v1 = XXH64_round(state.v1, state.mem64[0])
			#no_bounds_check state.v2 = XXH64_round(state.v2, state.mem64[1])
			#no_bounds_check state.v3 = XXH64_round(state.v3, state.mem64[2])
			#no_bounds_check state.v4 = XXH64_round(state.v4, state.mem64[3])
		}
		buf = buf[32 - state.memsize:]
		state.memsize = 0
	}

	if len(buf) >= 32 {
		v1 := state.v1
		v2 := state.v2
		v3 := state.v3
		v4 := state.v4

		for len(buf) >= 32 {
			#no_bounds_check v1 = XXH64_round(v1, XXH64_read64(buf, .Unaligned)); buf = buf[8:]
			#no_bounds_check v2 = XXH64_round(v2, XXH64_read64(buf, .Unaligned)); buf = buf[8:]
			#no_bounds_check v3 = XXH64_round(v3, XXH64_read64(buf, .Unaligned)); buf = buf[8:]
			#no_bounds_check v4 = XXH64_round(v4, XXH64_read64(buf, .Unaligned)); buf = buf[8:]
		}

		state.v1 = v1
		state.v2 = v2
		state.v3 = v3
		state.v4 = v4
	}

	length = len(buf)
	if length > 0 {
		mem_copy(raw_data(state.mem64[:]), raw_data(buf[:]), int(length))
		state.memsize = u32(length)
	}
	return .None
}

@(optimization_mode="favor_size")
XXH64_digest :: proc(state: ^XXH64_state) -> (res: XXH64_hash) {
	if state.total_len >= 32 {
		v1 := state.v1
		v2 := state.v2
		v3 := state.v3
		v4 := state.v4

		res = XXH_rotl64(v1, 1) + XXH_rotl64(v2, 7) + XXH_rotl64(v3, 12) + XXH_rotl64(v4, 18)
		res = XXH64_mergeRound(res, v1)
		res = XXH64_mergeRound(res, v2)
		res = XXH64_mergeRound(res, v3)
		res = XXH64_mergeRound(res, v4)
	} else {
		res = state.v3 /*seed*/ + XXH_PRIME64_5
	}
	res += XXH64_hash(state.total_len)

	buf := (^[32]u8)(&state.mem64)^
	alignment: Alignment = .Aligned if uintptr(&state.mem64) & 15 == 0 else .Unaligned
	return XXH64_finalize(res, buf[:state.memsize], alignment)
}

/*
	******   Canonical representation   ******

	The default return values from XXH functions are unsigned 32 and 64 bit integers.

	The canonical representation uses big endian convention,
	the same convention as human-readable numbers (large digits first).

	This way, hash values can be written into a file or buffer, remaining
	comparable across different systems.

	The following functions allow transformation of hash values to and from their
	canonical format.
*/
XXH64_canonical_from_hash :: proc(hash: XXH64_hash) -> (canonical: XXH64_canonical) {
	#assert(size_of(XXH64_canonical) == size_of(XXH64_hash))
	h := u64be(hash)
	mem_copy(&canonical, &h, size_of(canonical))
	return
}

XXH64_hash_from_canonical :: proc(canonical: ^XXH64_canonical) -> (hash: XXH64_hash) {
	h := (^u64be)(&canonical.digest)^
	return XXH64_hash(h)
}
