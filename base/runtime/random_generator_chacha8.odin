package runtime

import "base:intrinsics"

// This is an implementation of the Chacha8Rand DRBG, as specified
// in https://github.com/C2SP/C2SP/blob/main/chacha8rand.md
//
// There is a tradeoff to be made between state-size and performance,
// in terms of the amount of rng output buffered.
//
// The sensible buffer sizes are:
// - 256-bytes:  128-bit SIMD with 16x vector registers (SSE2)
// - 512-bytes:  128-bit SIMD with 32x vector registers (ARMv8),
//               256-bit SIMD with 16x vector registers (AVX2),
// - 1024-bytes: AVX-512
//
// Notes:
//  - Smaller than 256-bytes is possible but would require redundant
//    calls to the ChaCha8 function, which is prohibitively expensive.
//  - Larger than 1024-bytes is possible but pointless as the construct
//    is defined around 992-bytes of RNG output and 32-bytes of input
//    per iteration.
//
// This implementation opts for a 1024-byte buffer for simplicity,
// under the rationale that modern extremely memory constrained targets
// provide suitable functionality in hardware, and the language makes
// supporting the various SIMD flavors easy.

@(private = "file")
RNG_SEED_SIZE :: 32
@(private)
RNG_OUTPUT_PER_ITER :: 1024 - RNG_SEED_SIZE

@(private)
CHACHA_SIGMA_0: u32 : 0x61707865
@(private)
CHACHA_SIGMA_1: u32 : 0x3320646e
@(private)
CHACHA_SIGMA_2: u32 : 0x79622d32
@(private)
CHACHA_SIGMA_3: u32 : 0x6b206574
@(private)
CHACHA_ROUNDS :: 8

Default_Random_State :: struct {
	_buf:    [1024]byte,
	_off:    int,
	_seeded: bool,
}

@(require_results)
default_random_generator :: proc "contextless" (state: ^Default_Random_State = nil) -> Random_Generator {
	return {
		procedure = default_random_generator_proc,
		data = state,
	}
}

default_random_generator_proc :: proc(data: rawptr, mode: Random_Generator_Mode, p: []byte) {
	@(thread_local)
	state: Default_Random_State

	r: ^Default_Random_State = &state
	if data != nil {
		r = cast(^Default_Random_State)data
	}
	next_seed := r._buf[RNG_OUTPUT_PER_ITER:]

	switch mode {
	case .Read:
		if !r._seeded { // Unlikely.
			rand_bytes(next_seed)
			r._off = RNG_OUTPUT_PER_ITER // Force refill.
			r._seeded = true
		}

		assert(r._off <= RNG_OUTPUT_PER_ITER, "chacha8rand/BUG: outputed key material")
		if r._off >= RNG_OUTPUT_PER_ITER { // Unlikely.
			chacha8rand_refill(r)
		}

		// We are guaranteed to have at least some RNG output buffered.
		//
		// As an invariant each read will consume a multiple of 8-bytes
		// of output at a time.
		assert(r._off <= RNG_OUTPUT_PER_ITER - 8, "chacha8rand/BUG: less than 8-bytes of output available")
		assert(r._off % 8 == 0, "chacha8rand/BUG: buffered output is not a multiple of 8-bytes")

		p_len := len(p)
		if p_len == size_of(u64) {
			#no_bounds_check {
				// Fast path for a 64-bit destination.
				src := (^u64)(raw_data(r._buf[r._off:]))
				intrinsics.unaligned_store((^u64)(raw_data(p)), src^)
				src^ = 0 // Erasure (backtrack resistance)
				r._off += 8
			}
			return
		}

		p_ := p
		for remaining := p_len; remaining > 0; {
			sz := min(remaining, RNG_OUTPUT_PER_ITER - r._off)
			#no_bounds_check {
				copy(p_[:sz], r._buf[r._off:])
				p_ = p_[sz:]
				remaining -= sz
			}
			rounded_sz := ((sz + 7) / 8) * 8
			new_off := r._off + rounded_sz
			#no_bounds_check if new_off < RNG_OUTPUT_PER_ITER {
				// Erasure (backtrack resistance)
				intrinsics.mem_zero(raw_data(r._buf[r._off:]), rounded_sz)
				r._off = new_off
			} else {
				// Can omit erasure since we are overwriting the entire
				// buffer.
				chacha8rand_refill(r)
			}
		}

	case .Reset:
		// If no seed is passed, the next call to .Read will attempt to
		// reseed from the system entropy source.
		if len(p) == 0 {
			r._seeded = false
			return
		}

		// The cryptographic security of the output depends entirely
		// on the quality of the entropy in the seed, we will allow
		// re-seeding (as it makes testing easier), but callers that
		// decide to provide arbitrary seeds are on their own as far
		// as ensuring high-quality entropy.
		intrinsics.mem_zero(raw_data(next_seed), RNG_SEED_SIZE)
		copy(next_seed, p)
		r._seeded = true
		r._off = RNG_OUTPUT_PER_ITER // Force a refill.

	case .Query_Info:
		if len(p) != size_of(Random_Generator_Query_Info) {
			return
		}
		info := (^Random_Generator_Query_Info)(raw_data(p))
		info^ += {.Uniform, .Cryptographic, .Resettable}
	}
}

@(private = "file")
chacha8rand_refill :: proc(r: ^Default_Random_State) {
	assert(r._seeded == true, "chacha8rand/BUG: unseeded refill")

	// i386 has insufficient vector registers to use the
	// accelerated path at the moment.
	when ODIN_ARCH == .amd64 && intrinsics.has_target_feature("avx2") {
		chacha8rand_refill_simd256(r)
	} else when HAS_HARDWARE_SIMD && ODIN_ARCH != .i386 {
		chacha8rand_refill_simd128(r)
	} else {
		chacha8rand_refill_ref(r)
	}

	r._off = 0
}
