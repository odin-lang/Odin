package runtime

import "base:intrinsics"

@(require_results)
random_generator_read_bytes :: proc(rg: Random_Generator, p: []byte) -> bool {
	if rg.procedure != nil {
		rg.procedure(rg.data, .Read, p)
		return true
	}
	return false
}

@(require_results)
random_generator_read_ptr :: proc(rg: Random_Generator, p: rawptr, len: uint) -> bool {
	if rg.procedure != nil {
		rg.procedure(rg.data, .Read, ([^]byte)(p)[:len])
		return true
	}
	return false
}

@(require_results)
random_generator_query_info :: proc(rg: Random_Generator) -> (info: Random_Generator_Query_Info) {
	if rg.procedure != nil {
		rg.procedure(rg.data, .Query_Info, ([^]byte)(&info)[:size_of(info)])
	}
	return
}


random_generator_reset_bytes :: proc(rg: Random_Generator, p: []byte) {
	if rg.procedure != nil {
		rg.procedure(rg.data, .Reset, p)
	}
}

random_generator_reset_u64 :: proc(rg: Random_Generator, p: u64) {
	if rg.procedure != nil {
		p := p
		rg.procedure(rg.data, .Reset, ([^]byte)(&p)[:size_of(p)])
	}
}


Default_Random_State :: struct {
	s: [4]u64,
}

default_random_generator_proc :: proc(data: rawptr, mode: Random_Generator_Mode, p: []byte) {
	@(require_results)
	read_u64 :: proc "contextless" (r: ^Default_Random_State) -> u64 {
		// xoshiro256** output function and state transition
		rotl :: proc "contextless" (x: u64, k: u64) -> u64 {
			return (x << k) | (x >> ((-k) & 63))
		}

		result := rotl(r.s[1] * 5, 7) * 9
		t := r.s[1] << 17

		r.s[2] = r.s[2] ~ r.s[0]
		r.s[3] = r.s[3] ~ r.s[1]
		r.s[1] = r.s[1] ~ r.s[2]
		r.s[0] = r.s[0] ~ r.s[3]
		r.s[2] = r.s[2] ~ t
		r.s[3] = rotl(r.s[3], 45)

		return result
	}

	@(thread_local)
	global_rand_seed: Default_Random_State

	init :: proc "contextless" (r: ^Default_Random_State, seed: u64) {
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

	r: ^Default_Random_State = ---
	if data == nil {
		r = &global_rand_seed
	} else {
		r = cast(^Default_Random_State)data
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
		seed: u64 = 0
		mem_copy_non_overlapping(&seed, raw_data(p), min(size_of(seed), len(p)))
		init(r, seed)

	case .Query_Info:
		if len(p) != size_of(Random_Generator_Query_Info) {
			return
		}
		info := (^Random_Generator_Query_Info)(raw_data(p))
		info^ += {.Uniform, .Resettable}
	}
}

@(require_results)
default_random_generator :: proc "contextless" (state: ^Default_Random_State = nil) -> Random_Generator {
	return {
		procedure = default_random_generator_proc,
		data = state,
	}
}