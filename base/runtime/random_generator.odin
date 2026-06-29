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
