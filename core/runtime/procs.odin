package runtime

memset :: proc "c" (ptr: rawptr, val: i32, len: int) -> rawptr {
	if ptr != nil && len != 0 {
		b := byte(val)
		p := ([^]byte)(ptr)
		for i in 0..<len {
			p[i] = b
		}
	}
	return ptr
}