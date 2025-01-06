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
	32-bit hash functions
*/
XXH32_hash :: u32
xxh_u32    :: u32
XXH32_DEFAULT_SEED :: XXH32_hash(0)

XXH32_state :: struct {
	total_len_32: XXH32_hash,    /*!< Total length hashed, modulo 2^32 */
	large_len:    XXH32_hash,    /*!< Whether the hash is >= 16 (handles @ref total_len_32 overflow) */
	v1:           XXH32_hash,    /*!< First accumulator lane */
	v2:           XXH32_hash,    /*!< Second accumulator lane */
	v3:           XXH32_hash,    /*!< Third accumulator lane */
	v4:           XXH32_hash,    /*!< Fourth accumulator lane */
	mem32:        [4]XXH32_hash, /*!< Internal buffer for partial reads. Treated as unsigned char[16]. */
	memsize:      XXH32_hash,    /*!< Amount of data in @ref mem32 */
	reserved:     XXH32_hash,    /*!< Reserved field. Do not read or write to it, it may be removed. */
}

XXH32_canonical :: struct {
	digest: [4]u8,
}

XXH_PRIME32_1 :: 0x9E3779B1     /*!< 0b10011110001101110111100110110001 */
XXH_PRIME32_2 :: 0x85EBCA77     /*!< 0b10000101111010111100101001110111 */
XXH_PRIME32_3 :: 0xC2B2AE3D     /*!< 0b11000010101100101010111000111101 */
XXH_PRIME32_4 :: 0x27D4EB2F     /*!< 0b00100111110101001110101100101111 */
XXH_PRIME32_5 :: 0x165667B1     /*!< 0b00010110010101100110011110110001 */

@(optimization_mode="favor_size")
XXH32_round :: #force_inline proc(seed, input: XXH32_hash) -> (res: XXH32_hash) {
	seed := seed

	seed += input * XXH_PRIME32_2
	seed  = XXH_rotl32(seed, 13)
	seed *= XXH_PRIME32_1
	return seed
}

/*
	Mix all bits
*/
@(optimization_mode="favor_size")
XXH32_avalanche :: #force_inline proc(h32: u32) -> (res: u32) {
	h32 := h32

	h32 ~= h32 >> 15
	h32 *= XXH_PRIME32_2
	h32 ~= h32 >> 13
	h32 *= XXH_PRIME32_3
	h32 ~= h32 >> 16
	return h32
}

@(optimization_mode="favor_size")
XXH32_finalize :: #force_inline proc(h32: u32, buf: []u8, alignment: Alignment) -> (res: u32) {
	process_1 :: #force_inline proc(h32: u32, buf: []u8) -> (h32_res: u32, buf_res: []u8) {
		#no_bounds_check b := u32(buf[0])
		h32_res = h32 + b * XXH_PRIME32_5
		h32_res = XXH_rotl32(h32_res, 11) * XXH_PRIME32_1
		#no_bounds_check return h32_res, buf[1:]
	}

	process_4 :: #force_inline proc(h32: u32, buf: []u8, alignment: Alignment) -> (h32_res: u32, buf_res: []u8) {
		b := XXH32_read32(buf, alignment)
		h32_res = h32 + b * XXH_PRIME32_3
		h32_res = XXH_rotl32(h32_res, 17) * XXH_PRIME32_4
		#no_bounds_check return h32_res, buf[4:]
	}

	buf := buf
	h32 := h32

	switch len(buf) & 15 {
	case 12:
		h32, buf = process_4(h32, buf, alignment)
		fallthrough
	case 8:
		h32, buf = process_4(h32, buf, alignment)
		fallthrough
	case 4:
		h32, _ = process_4(h32, buf, alignment)
		return XXH32_avalanche(h32)

	case 13:
		h32, buf = process_4(h32, buf, alignment)
		fallthrough
	case 9:
		h32, buf = process_4(h32, buf, alignment)
		fallthrough
	case 5:
		h32, buf = process_4(h32, buf, alignment)
		h32, buf = process_1(h32, buf)
		return XXH32_avalanche(h32)

	case 14:
		h32, buf = process_4(h32, buf, alignment)
		fallthrough
	case 10:
		h32, buf = process_4(h32, buf, alignment)
		fallthrough
	case 6:
		h32, buf = process_4(h32, buf, alignment)
		h32, buf = process_1(h32, buf)
		h32, buf = process_1(h32, buf)
		return XXH32_avalanche(h32)

	case 15:
		h32, buf = process_4(h32, buf, alignment)
		fallthrough
	case 11:
		h32, buf = process_4(h32, buf, alignment)
		fallthrough
	case 7:
		h32, buf = process_4(h32, buf, alignment)
		fallthrough

	case 3:
		h32, buf = process_1(h32, buf)
		fallthrough
	case 2:
		h32, buf = process_1(h32, buf)
		fallthrough
	case 1:
		h32, buf = process_1(h32, buf)
		fallthrough
	case 0:
		return XXH32_avalanche(h32)
	}
	unreachable()
}

@(optimization_mode="favor_size")
XXH32_endian_align :: #force_inline proc(input: []u8, seed := XXH32_DEFAULT_SEED, alignment: Alignment) -> (res: XXH32_hash) {
	buf := input
	length := len(input)

	if length >= 16 {
		v1 := seed + XXH_PRIME32_1 + XXH_PRIME32_2
		v2 := seed + XXH_PRIME32_2
		v3 := seed + 0
		v4 := seed - XXH_PRIME32_1

		for len(buf) >= 16 {
			#no_bounds_check v1 = XXH32_round(v1, XXH32_read32(buf, alignment)); buf = buf[4:]
			#no_bounds_check v2 = XXH32_round(v2, XXH32_read32(buf, alignment)); buf = buf[4:]
			#no_bounds_check v3 = XXH32_round(v3, XXH32_read32(buf, alignment)); buf = buf[4:]
			#no_bounds_check v4 = XXH32_round(v4, XXH32_read32(buf, alignment)); buf = buf[4:]
		}

		res = XXH_rotl32(v1, 1)  + XXH_rotl32(v2, 7) + XXH_rotl32(v3, 12) + XXH_rotl32(v4, 18)
	} else {
		res  = seed + XXH_PRIME32_5
	}

	res += u32(length)
	return XXH32_finalize(res, buf, alignment)
}

XXH32 :: proc(input: []u8, seed := XXH32_DEFAULT_SEED) -> (digest: XXH32_hash) {
	when false {
		/*
			Simple version, good for code maintenance, but unfortunately slow for small inputs.
		*/
		state: XXH32_state
		XXH32_reset_state(&state, seed)
		XXH32_update(&state, input)
		return XXH32_digest(&state)
	} else {
		when XXH_FORCE_ALIGN_CHECK {
			if uintptr(raw_data(input)) & uintptr(3) == 0 {
				/*
					Input is 4-bytes aligned, leverage the speed benefit.
				*/
				return XXH32_endian_align(input, seed, .Aligned)
			}
		}
		return XXH32_endian_align(input, seed, .Unaligned)
	}
}

/*
	******   Hash streaming   ******
*/
XXH32_create_state :: proc(allocator := context.allocator) -> (res: ^XXH32_state, err: Error) {
	state := new(XXH32_state, allocator)
	XXH32_reset_state(state)
	return state, .None if state != nil else .Error
}

XXH32_destroy_state :: proc(state: ^XXH32_state, allocator := context.allocator) -> (err: Error) {
	free(state, allocator)
	return .None
}

XXH32_copy_state :: proc(dest, src: ^XXH32_state) {
	assert(dest != nil && src != nil)
	mem_copy(dest, src, size_of(XXH32_state))
}

XXH32_reset_state :: proc(state_ptr: ^XXH32_state, seed := XXH32_DEFAULT_SEED) -> (err: Error) {
	state := XXH32_state{}

	state.v1 = seed + XXH_PRIME32_1 + XXH_PRIME32_2
	state.v2 = seed + XXH_PRIME32_2
	state.v3 = seed + 0
	state.v4 = seed - XXH_PRIME32_1
	/*
		Do not write into reserved, planned to be removed in a future version.
	*/
	mem_copy(state_ptr, &state, size_of(state) - size_of(state.reserved))
	return .None
}

XXH32_update :: proc(state: ^XXH32_state, input: []u8) -> (err: Error) {

	buf    := input
	length := len(buf)

	state.total_len_32 += XXH32_hash(length)
	state.large_len |= 1 if length >= 16 || state.total_len_32 >= 16 else 0

	if state.memsize + u32(length) < 16 {   /* Fill in tmp buffer */
		ptr := uintptr(raw_data(state.mem32[:])) + uintptr(state.memsize)
		mem_copy(rawptr(ptr), raw_data(input), int(length))
		state.memsize += XXH32_hash(length)
		return .None
	}

	if state.memsize > 0 {/* Some data left from previous update */
		ptr := uintptr(raw_data(state.mem32[:])) + uintptr(state.memsize)
		mem_copy(rawptr(ptr), raw_data(input), int(16 - state.memsize))
		{
			#no_bounds_check state.v1 = XXH32_round(state.v1, state.mem32[0])
			#no_bounds_check state.v2 = XXH32_round(state.v2, state.mem32[1])
			#no_bounds_check state.v3 = XXH32_round(state.v3, state.mem32[2])
			#no_bounds_check state.v4 = XXH32_round(state.v4, state.mem32[3])
		}
		buf = buf[16 - state.memsize:]
		state.memsize = 0
	}

	if len(buf) >= 16 {
		v1 := state.v1
		v2 := state.v2
		v3 := state.v3
		v4 := state.v4

		for len(buf) >= 16 {
			#no_bounds_check v1 = XXH32_round(v1, XXH32_read32(buf, .Unaligned)); buf = buf[4:]
			#no_bounds_check v2 = XXH32_round(v2, XXH32_read32(buf, .Unaligned)); buf = buf[4:]
			#no_bounds_check v3 = XXH32_round(v3, XXH32_read32(buf, .Unaligned)); buf = buf[4:]
			#no_bounds_check v4 = XXH32_round(v4, XXH32_read32(buf, .Unaligned)); buf = buf[4:]
		}

		state.v1 = v1
		state.v2 = v2
		state.v3 = v3
		state.v4 = v4
	}

	length = len(buf)
	if length > 0 {
		mem_copy(raw_data(state.mem32[:]), raw_data(buf[:]), int(length))
		state.memsize = u32(length)
	}
	return .None
}

XXH32_digest :: proc(state: ^XXH32_state) -> (res: XXH32_hash) {
	if state.large_len > 0 {
		res = XXH_rotl32(state.v1, 1)  + XXH_rotl32(state.v2, 7) + XXH_rotl32(state.v3, 12) + XXH_rotl32(state.v4, 18)
	} else {
		res = state.v3 /* == seed */ + XXH_PRIME32_5
	}

	res += state.total_len_32

	buf := (^[16]u8)(&state.mem32)^
	alignment: Alignment = .Aligned if uintptr(&state.mem32) & 15 == 0 else .Unaligned
	return XXH32_finalize(res, buf[:state.memsize], alignment)
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
XXH32_canonical_from_hash :: proc(hash: XXH32_hash) -> (canonical: XXH32_canonical) {
	#assert(size_of(XXH32_canonical) == size_of(XXH32_hash))
	h := u32be(hash)
	mem_copy(&canonical, &h, size_of(canonical))
	return
}

XXH32_hash_from_canonical :: proc(canonical: ^XXH32_canonical) -> (hash: XXH32_hash) {
	h := (^u32be)(&canonical.digest)^
	return XXH32_hash(h)
}
