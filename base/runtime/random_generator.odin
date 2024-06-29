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
	state: u64,
	inc:   u64,
}

default_random_generator_proc :: proc(data: rawptr, mode: Random_Generator_Mode, p: []byte) {
	@(require_results)
	read_u64 :: proc "contextless" (r: ^Default_Random_State) -> u64 {
		old_state := r.state
		r.state = old_state * 6364136223846793005 + (r.inc|1)
		xor_shifted := (((old_state >> 59) + 5) ~ old_state) * 12605985483714917081
		rot := (old_state >> 59)
		return (xor_shifted >> rot) | (xor_shifted << ((-rot) & 63))
	}

	@(thread_local)
	global_rand_seed: Default_Random_State

	init :: proc "contextless" (r: ^Default_Random_State, seed: u64) {
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

	r: ^Default_Random_State = ---
	if data == nil {
		r = &global_rand_seed
	} else {
		r = cast(^Default_Random_State)data
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
					pos = 7
				}
				v = byte(val)
				val >>= 8
				pos -= 1
			}
		}

	case .Reset:
		seed: u64
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

default_random_generator :: proc "contextless" (state: ^Default_Random_State = nil) -> Random_Generator {
	return {
		procedure = default_random_generator_proc,
		data = state,
	}
}