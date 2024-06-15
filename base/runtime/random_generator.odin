package runtime

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