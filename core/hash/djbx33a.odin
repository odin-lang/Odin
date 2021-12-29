package hash

djbx33a :: proc(data: []byte) -> (result: [16]byte) #no_bounds_check {
	state := [4]u32{5381, 5381, 5381, 5381}
	
	s: u32 = 0
	for p in data {
		state[s] = (state[s] << 5) + state[s] + u32(p)
		s = (s + 1) & 3
	}
	
	
	(^u32le)(&result[0])^  = u32le(state[0])
	(^u32le)(&result[4])^  = u32le(state[1])
	(^u32le)(&result[8])^  = u32le(state[2])
	(^u32le)(&result[12])^ = u32le(state[3])
	return
}