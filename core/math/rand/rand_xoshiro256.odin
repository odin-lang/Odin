package rand

import "base:intrinsics"
import "base:runtime"

import "core:math/bits"

/*
The state for a xoshiro256** pseudorandom generator.
*/
Xoshiro256_Random_State :: struct {
	s: [4]u64,
}

xoshiro256_random_generator_proc :: proc(data: rawptr, mode: runtime.Random_Generator_Mode, p: []byte) {
	@(require_results)
	read_u64 :: proc "contextless" (r: ^Xoshiro256_Random_State) -> u64 {
		// xoshiro256** output function and state transition

		result := bits.rotate_left64(r.s[1] * 5, 7) * 9
		t := r.s[1] << 17

		r.s[2] = r.s[2] ~ r.s[0]
		r.s[3] = r.s[3] ~ r.s[1]
		r.s[1] = r.s[1] ~ r.s[2]
		r.s[0] = r.s[0] ~ r.s[3]
		r.s[2] = r.s[2] ~ t
		r.s[3] = bits.rotate_left64(r.s[3], 45)

		return result
	}

	@(thread_local)
	global_rand_seed: Xoshiro256_Random_State

	init :: proc "contextless" (r: ^Xoshiro256_Random_State, seed: u64) {
		// splitmix64 to expand a 64-bit seed into 256 bits of state
		sm64_next :: proc "contextless" (s: ^u64) -> u64 {
			s^ += 0x9E3779B97F4A7C15
			z := s^
			z = (z ~ (z >> 30)) * 0xBF58476D1CE4E5B9
			z = (z ~ (z >> 27)) * 0x94D049BB133111EB
			return z ~ (z >> 31)
		}

		local_seed := seed
		r.s[0] = sm64_next(&local_seed)
		r.s[1] = sm64_next(&local_seed)
		r.s[2] = sm64_next(&local_seed)
		r.s[3] = sm64_next(&local_seed)
		// Extremely unlikely all zero; ensure non-zero state
		if (r.s[0] | r.s[1] | r.s[2] | r.s[3]) == 0 {
			// force a minimal non-zero tweak
			r.s[0] = 1
		}
	}

	r: ^Xoshiro256_Random_State = ---
	if data == nil {
		r = &global_rand_seed
	} else {
		r = cast(^Xoshiro256_Random_State)data
	}

	switch mode {
	case .Read:
		if (r.s[0] | r.s[1] | r.s[2] | r.s[3]) == 0 {
			init(r, u64(intrinsics.read_cycle_counter()))
		}

		switch len(p) {
		case size_of(u64):
			// Fast path for a 64-bit destination.
			intrinsics.unaligned_store((^u64)(raw_data(p)), read_u64(r))
		case:
			// All other cases.
			n := len(p) / size_of(u64)
			buff := ([^]u64)(raw_data(p))[:n]
			for &e in buff {
				intrinsics.unaligned_store(&e, read_u64(r))
			}
			// Handle remaining bytes
			rem := len(p) % size_of(u64)
			if rem > 0 {
				val := read_u64(r)
				tail := p[len(p) - rem:]
				for &b in tail {
					b = byte(val)
					val >>= 8
				}
			}
		}

	case .Reset:
		seed: u64 = 0
		runtime.mem_copy_non_overlapping(&seed, raw_data(p), min(size_of(seed), len(p)))
		init(r, seed)

	case .Query_Info:
		if len(p) != size_of(Generator_Query_Info) {
			return
		}
		info := (^Generator_Query_Info)(raw_data(p))
		info^ += {.Uniform, .Resettable}
	}
}

/*
Returns an instance of the xoshiro256** pseudorandom generator.  If no
initial state is provided, the PRNG will be lazily initialized with the
system timestamp counter on first-use.

WARNING: This random number generator is NOT cryptographically secure.

Inputs:
- state: Optional initial PRNG state.

Returns:
- A `Generator` instance.
*/
@(require_results)
xoshiro256_random_generator :: proc "contextless" (state: ^Xoshiro256_Random_State = nil) -> Generator {
	return {
		procedure = xoshiro256_random_generator_proc,
		data = state,
	}
}
