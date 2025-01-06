/*
	An implementation of Yann Collet's [xxhash Fast Hash Algorithm](https://cyan4973.github.io/xxHash/).
	Copyright 2021 Jeroen van Rijn <nom@duclavier.com>.

	Made available under Odin's BSD-3 license, based on the original C code.

	List of contributors:
		Jeroen van Rijn: Initial implementation.
*/

package xxhash

import "core:mem"
import "base:intrinsics"

/*
	===   XXH3 128-bit streaming   ===

	All the functions are actually the same as for 64-bit streaming variant.
	The only difference is the finalization routine.
*/
XXH3_128_reset :: proc(state: ^XXH3_state) -> (err: Error) {
	if state == nil {
		return .Error
	}
	XXH3_reset_internal(state, 0, XXH3_kSecret[:], len(XXH3_kSecret))
	return .None
}
XXH3_64_reset :: XXH3_128_reset

XXH3_128_reset_with_secret :: proc(state: ^XXH3_state, secret: []u8) -> (err: Error) {
	if state == nil {
		return .Error
	}
	if secret == nil || len(secret) < XXH3_SECRET_SIZE_MIN {
		return .Error
	}
	XXH3_reset_internal(state, 0, secret, len(secret))
	return .None
}
XXH3_64_reset_with_secret :: XXH3_128_reset_with_secret

XXH3_128_reset_with_seed :: proc(state: ^XXH3_state, seed: XXH64_hash) -> (err: Error) {
	if seed == 0 {
		return XXH3_128_reset(state)
	}
	if seed != state.seed {
		XXH3_init_custom_secret(state.custom_secret[:], seed)
	}
	XXH3_reset_internal(state, seed, nil, XXH_SECRET_DEFAULT_SIZE)
	return .None
}
XXH3_64_reset_with_seed :: XXH3_128_reset_with_seed

XXH3_128_update :: proc(state: ^XXH3_state, input: []u8) -> (err: Error) {
	return XXH3_update(state, input, XXH3_accumulate_512, XXH3_scramble_accumulator)
}
XXH3_64_update :: XXH3_128_update

XXH3_128_digest :: proc(state: ^XXH3_state) -> (hash: XXH3_128_hash) {
	secret := state.custom_secret[:] if len(state.external_secret) == 0 else state.external_secret[:]

	if state.total_length > XXH3_MIDSIZE_MAX {
		acc: [XXH_ACC_NB]XXH64_hash
		XXH3_digest_long(acc[:], state, secret)

		assert(state.secret_limit + XXH_STRIPE_LEN >= XXH_ACC_NB + XXH_SECRET_MERGEACCS_START)
		{
			h128 := XXH128_hash_t{}

			h128.low  = XXH3_mergeAccs(
				acc[:],
				secret[XXH_SECRET_MERGEACCS_START:],
				state.total_length * XXH_PRIME64_1)

			h128.high = XXH3_mergeAccs(
				acc[:],
				secret[state.secret_limit + XXH_STRIPE_LEN - size_of(acc) - XXH_SECRET_MERGEACCS_START:],
				~(u64(state.total_length) * XXH_PRIME64_2))

			return h128.h
		}
	}
	/* len <= XXH3_MIDSIZE_MAX : short code */
	if state.seed != 0 {
		return XXH3_128_with_seed(state.buffer[:state.total_length], state.seed)
	}
	return XXH3_128_with_secret(state.buffer[:state.total_length], secret[:state.secret_limit + XXH_STRIPE_LEN])
}

/*======   Canonical representation   ======*/

XXH3_128_canonical_from_hash :: proc(hash: XXH128_hash_t) -> (canonical: XXH128_canonical) {
	#assert(size_of(XXH128_canonical) == size_of(XXH128_hash_t))

	t := hash
	when ODIN_ENDIAN == .Little {
		t.high = byte_swap(t.high)
		t.low  = byte_swap(t.low)
	}
	mem_copy(&canonical.digest,    &t.high, size_of(u64))
	mem_copy(&canonical.digest[8], &t.low,  size_of(u64))
	return
}

XXH3_128_hash_from_canonical :: proc(src: ^XXH128_canonical) -> (hash: u128) {
	h := XXH128_hash_t{}

	high := (^u64be)(&src.digest[0])^
	low  := (^u64be)(&src.digest[8])^

	h.high = u64(high)
	h.low  = u64(low)
	return h.h
}

/* ===   XXH3 streaming   === */

XXH3_init_state :: proc(state: ^XXH3_state) {
	state.seed = 0
}

XXH3_create_state :: proc(allocator := context.allocator) -> (res: ^XXH3_state, err: Error) {
	state, mem_error := mem.new_aligned(XXH3_state, 64, allocator)
	err = nil if mem_error == nil else .Error

	XXH3_init_state(state)
	XXH3_128_reset(state)
	return state, nil
}

XXH3_destroy_state :: proc(state: ^XXH3_state, allocator := context.allocator) -> (err: Error) {
	free(state, allocator)
	return .None
}

XXH3_copy_state :: proc(dest, src: ^XXH3_state) {
	assert(dest != nil && src != nil)
	mem_copy(dest, src, size_of(XXH3_state))
}

XXH3_reset_internal :: proc(state: ^XXH3_state, seed: XXH64_hash, secret: []u8, secret_size: uint) {
	assert(state != nil)

	init_start  := offset_of(XXH3_state, buffered_size)
	init_length := offset_of(XXH3_state, stripes_per_block) - init_start

	assert(offset_of(XXH3_state, stripes_per_block) > init_start)

	/*
		Set members from buffered_size to stripes_per_block (excluded) to 0
	*/
	offset  := rawptr(uintptr(state) + uintptr(init_start))
	intrinsics.mem_zero(offset, init_length)

	state.acc[0] = XXH_PRIME32_3
	state.acc[1] = XXH_PRIME64_1
	state.acc[2] = XXH_PRIME64_2
	state.acc[3] = XXH_PRIME64_3
	state.acc[4] = XXH_PRIME64_4
	state.acc[5] = XXH_PRIME32_2
	state.acc[6] = XXH_PRIME64_5
	state.acc[7] = XXH_PRIME32_1
	state.seed = seed
	state.external_secret = secret

	assert(secret_size >= XXH3_SECRET_SIZE_MIN)

	state.secret_limit = secret_size - XXH_STRIPE_LEN
	state.stripes_per_block = state.secret_limit / XXH_SECRET_CONSUME_RATE
}

/*
	Note: when XXH3_consumeStripes() is invoked, there must be a guarantee that at least
	one more byte must be consumed from input so that the function can blindly consume
	all stripes using the "normal" secret segment.
*/

XXH3_consume_stripes :: #force_inline proc(
		acc: []xxh_u64, stripes_so_far: ^uint, stripes_per_block: uint, input: []u8,
		number_of_stripes: uint, secret: []u8, secret_limit: uint,
		f_acc512: XXH3_accumulate_512_f, f_scramble: XXH3_scramble_accumulator_f) {

	assert(number_of_stripes <= stripes_per_block) /* can handle max 1 scramble per invocation */
	assert(stripes_so_far^ < stripes_per_block)

	if stripes_per_block - stripes_so_far^ <= number_of_stripes {
		/* need a scrambling operation */
		stripes_to_end_of_block := stripes_per_block - stripes_so_far^
		stripes_after_block     := number_of_stripes - stripes_to_end_of_block

		XXH3_accumulate(acc, input, secret[stripes_so_far^ * XXH_SECRET_CONSUME_RATE:], stripes_to_end_of_block, f_acc512)

		f_scramble(acc, secret[secret_limit:])
		XXH3_accumulate(acc, input[stripes_to_end_of_block * XXH_STRIPE_LEN:], secret, stripes_after_block, f_acc512)
		stripes_so_far^ = stripes_after_block
	} else {
		XXH3_accumulate(acc, input, secret[stripes_so_far^ * XXH_SECRET_CONSUME_RATE:], number_of_stripes, f_acc512)
		stripes_so_far^ += number_of_stripes
	}
}

/*
	Both XXH3_64bits_update and XXH3_128bits_update use this routine.
*/
XXH3_update :: #force_inline proc(
		state: ^XXH3_state, input: []u8,
		f_acc512: XXH3_accumulate_512_f,
		f_scramble: XXH3_scramble_accumulator_f) -> (err: Error) {

	input  := input
	length := len(input)
	secret := state.custom_secret[:] if len(state.external_secret) == 0 else state.external_secret[:]

	if len(input) == 0 {
		return
	}

	state.total_length += u64(length)
	assert(state.buffered_size <= XXH3_INTERNAL_BUFFER_SIZE)

	if int(state.buffered_size) + length <= XXH3_INTERNAL_BUFFER_SIZE {  /* fill in tmp buffer */
		mem_copy(&state.buffer[state.buffered_size], &input[0], length)
		state.buffered_size += u32(length)
		return .None
	}

	/* total input is now > XXH3_INTERNAL_BUFFER_SIZE */
	XXH3_INTERNAL_BUFFER_STRIPES :: XXH3_INTERNAL_BUFFER_SIZE / XXH_STRIPE_LEN
	#assert(XXH3_INTERNAL_BUFFER_SIZE % XXH_STRIPE_LEN == 0) /* clean multiple */

	/*
		Internal buffer is partially filled (always, except at beginning)
		Complete it, then consume it.
	*/
	if state.buffered_size > 0 {
		load_size := int(XXH3_INTERNAL_BUFFER_SIZE - state.buffered_size)

		state_ptr := rawptr(uintptr(raw_data(state.buffer[:])) + uintptr(state.buffered_size))
		mem_copy(state_ptr, raw_data(input), load_size)
		input = input[load_size:]

		XXH3_consume_stripes(
			state.acc[:], &state.stripes_so_far, state.stripes_per_block,
			state.buffer[:], XXH3_INTERNAL_BUFFER_STRIPES,
			secret, state.secret_limit, f_acc512, f_scramble)
		state.buffered_size = 0
	}
	assert(len(input) > 0)

	/* Consume input by a multiple of internal buffer size */
	if len(input) > XXH3_INTERNAL_BUFFER_SIZE {
		tail := input[:len(input) - XXH_STRIPE_LEN]
		for len(input) > XXH3_INTERNAL_BUFFER_SIZE {
			XXH3_consume_stripes(
				state.acc[:], &state.stripes_so_far, state.stripes_per_block,
				input, XXH3_INTERNAL_BUFFER_STRIPES,
				secret, state.secret_limit, f_acc512, f_scramble)

			input = input[XXH3_INTERNAL_BUFFER_SIZE:]
		}
		/* for last partial stripe */
		mem_copy(&state.buffer[XXH3_INTERNAL_BUFFER_SIZE - XXH_STRIPE_LEN], &tail[0], XXH_STRIPE_LEN)
	}

	length = len(input)
	assert(length > 0)

	/* Some remaining input (always) : buffer it */
	mem_copy(&state.buffer[0], &input[0], length)
	state.buffered_size = u32(length)
	return .None
}

XXH3_digest_long :: #force_inline proc(acc: []u64, state: ^XXH3_state, secret: []u8) {
	/*
		Digest on a local copy. This way, the state remains unaltered, and it can
		continue ingesting more input afterwards.
	*/
	mem_copy(&acc[0], &state.acc[0], size_of(state.acc))

	if state.buffered_size >= XXH_STRIPE_LEN {
		number_of_stripes := uint((state.buffered_size - 1) / XXH_STRIPE_LEN)
		stripes_so_far    := state.stripes_so_far

		XXH3_consume_stripes(
			acc[:], &stripes_so_far, state.stripes_per_block, state.buffer[:], number_of_stripes,
			secret, state.secret_limit, XXH3_accumulate_512, XXH3_scramble_accumulator)

		/* last stripe */
		XXH3_accumulate_512(
			acc[:],
			state.buffer[state.buffered_size - XXH_STRIPE_LEN:],
			secret[state.secret_limit - XXH_SECRET_LASTACC_START:])

	} else {  /* bufferedSize < XXH_STRIPE_LEN */
		last_stripe: [XXH_STRIPE_LEN]u8
		catchup_size := int(XXH_STRIPE_LEN) - int(state.buffered_size)
		assert(state.buffered_size > 0)  /* there is always some input buffered */

		mem_copy(&last_stripe[0],            &state.buffer[XXH3_INTERNAL_BUFFER_SIZE - catchup_size], catchup_size)
		mem_copy(&last_stripe[catchup_size], &state.buffer[0],                                        int(state.buffered_size))
		XXH3_accumulate_512(acc[:], last_stripe[:], secret[state.secret_limit - XXH_SECRET_LASTACC_START:])
	}
}

XXH3_64_digest :: proc(state: ^XXH3_state) -> (hash: XXH64_hash) {
	secret := state.custom_secret[:] if len(state.external_secret) == 0 else state.external_secret[:]

	if state.total_length > XXH3_MIDSIZE_MAX {
		acc: [XXH_ACC_NB]xxh_u64
		XXH3_digest_long(acc[:], state, secret[:])

		return XXH3_mergeAccs(acc[:], secret[ XXH_SECRET_MERGEACCS_START:], state.total_length * XXH_PRIME64_1)
	}

	/* totalLen <= XXH3_MIDSIZE_MAX: digesting a short input */
	if state.seed == 0 {
		return XXH3_64_with_seed(state.buffer[:state.total_length], state.seed)
	}
	return XXH3_64_with_secret(state.buffer[:state.total_length], secret[:state.secret_limit + XXH_STRIPE_LEN])
}

XXH3_generate_secret :: proc(secret_buffer: []u8, custom_seed: []u8) {
	secret_length := len(secret_buffer)
	assert(secret_length >= XXH3_SECRET_SIZE_MIN)

	custom_seed_size := len(custom_seed)
	if custom_seed_size == 0 {
		k := XXH3_kSecret
		mem_copy(&secret_buffer[0], &k[0], XXH_SECRET_DEFAULT_SIZE)
		return
	}

	{
		segment_size :: size_of(XXH128_hash_t)
		number_of_segments := u64(XXH_SECRET_DEFAULT_SIZE / segment_size)

		seeds: [12]u64le
		assert(number_of_segments == 12)
		assert(segment_size * number_of_segments == XXH_SECRET_DEFAULT_SIZE) /* exact multiple */

		scrambler := XXH3_128_canonical_from_hash(XXH128_hash_t{h=XXH3_128(custom_seed[:])})

		/*
			Copy customSeed to seeds[], truncating or repeating as necessary.
			TODO: Convert `mem_copy` to slice copies.
		*/
		{
			to_fill := min(custom_seed_size, size_of(seeds))
			filled  := to_fill
			mem_copy(&seeds[0], &custom_seed[0], to_fill)
			for filled < size_of(seeds) {
				to_fill = min(filled, size_of(seeds) - filled)
				seed_offset := rawptr(uintptr(&seeds[0]) + uintptr(filled))
				mem_copy(seed_offset, &seeds[0], to_fill)
				filled += to_fill
			}
		}

		/*
			Generate secret
		*/
		mem_copy(&secret_buffer[0], &scrambler, size_of(scrambler))

		for segment_number := u64(1); segment_number < number_of_segments; segment_number += 1 {
			segment_start := segment_number * segment_size

			this_seed := u64(seeds[segment_number]) + segment_number
			segment := XXH3_128_canonical_from_hash(XXH128_hash_t{h=XXH3_128(scrambler.digest[:], this_seed)})

			mem_copy(&secret_buffer[segment_start], &segment, size_of(segment))
		}
	}
}
