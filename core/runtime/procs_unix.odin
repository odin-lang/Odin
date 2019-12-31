//+build linux, darwin
package runtime

@(link_name="memset")
memset :: proc "c" (ptr: rawptr, val: i32, len: int) -> rawptr {
	b := byte(val);

	p_start := uintptr(ptr);
	p_end := p_start + uintptr(max(len, 0));
	for p := p_start; p < p_end; p += 1 {
		(^byte)(p)^ = b;
	}

	return ptr;
}
