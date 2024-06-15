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


@(private="file")
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

	switch mode {
	case .Read:
		r := &global_rand_seed

		if r.state == 0 &&
		   r.inc == 0 {
		   	seed := u64(intrinsics.read_cycle_counter())
		   	r.state = 0
		   	r.inc = (seed << 1) | 1
		   	_ = read_u64(r)
		   	r.state += seed
		   	_ = read_u64(r)
		}

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
		return
	case .Query_Info:
		if len(p) != size_of(Random_Generator_Query_Info) {
			return
		}
		info := (^Random_Generator_Query_Info)(raw_data(p))
		info^ += {.Uniform}
	}
}

default_random_generator :: proc "contextless" () -> Random_Generator {
	return {
		procedure = default_random_generator_proc,
		data = nil,
	}
}