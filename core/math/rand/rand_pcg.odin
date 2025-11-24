package rand

import "base:intrinsics"
import "base:runtime"

/*
The state for a PCG64 RXS-M-XS pseudorandom generator.
*/
PCG_Random_State :: struct {
	state: u64,
	inc:   u64,
}

pcg_random_generator_proc :: proc(data: rawptr, mode: runtime.Random_Generator_Mode, p: []byte) {
	@(require_results)
	read_u64 :: proc "contextless" (r: ^PCG_Random_State) -> u64 {
		old_state := r.state
		r.state = old_state * 6364136223846793005 + (r.inc|1)
		xor_shifted := (((old_state >> 59) + 5) ~ old_state) * 12605985483714917081
		rot := (old_state >> 59)
		return (xor_shifted >> rot) | (xor_shifted << ((-rot) & 63))
	}

	@(thread_local)
	global_rand_seed: PCG_Random_State

	init :: proc "contextless" (r: ^PCG_Random_State, seed: u64) {
		seed := seed
		if seed == 0 {
			seed = u64(intrinsics.read_cycle_counter())
		}
		r.state = 0
		r.inc = (seed << 1) | 1
		_ = read_u64(r)
		r.state += seed
		_ = read_u64(r)
	}

	r: ^PCG_Random_State = ---
	if data == nil {
		r = &global_rand_seed
	} else {
		r = cast(^PCG_Random_State)data
	}

	switch mode {
	case .Read:
		if r.state == 0 && r.inc == 0 {
			init(r, 0)
		}

		switch len(p) {
		case size_of(u64):
			// Fast path for a 64-bit destination.
			intrinsics.unaligned_store((^u64)(raw_data(p)), read_u64(r))
		case:
			// All other cases.
			pos := i8(0)
			val := u64(0)
			for &v in p {
				if pos == 0 {
					val = read_u64(r)
					pos = 8
				}
				v = byte(val)
				val >>= 8
				pos -= 1
			}
		}

	case .Reset:
		seed: u64
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
Returns an instance of the PGC64 RXS-M-XS pseudorandom generator.  If no
initial state is provided, the PRNG will be lazily initialized with the
system timestamp counter on first-use.

WARNING: This random number generator is NOT cryptographically secure,
and is additionally known to be flawed.  It is only included for
backward compatibility with historical releases of Odin.
See: https://github.com/odin-lang/Odin/issues/5881

Inputs:
- state: Optional initial PRNG state.

Returns:
- A `Generator` instance.
*/
@(require_results)
pcg_random_generator :: proc "contextless" (state: ^PCG_Random_State = nil) -> Generator {
	return {
		procedure = pcg_random_generator_proc,
		data = state,
	}
}
