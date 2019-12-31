//+build !windows !amd64
package runtime

@(link_name="memset")
memset :: proc "c" (ptr: rawptr, val: i32, len: int) -> rawptr {
	b := byte(val);

	p_start := uintptr(ptr);
	p_end := p + uintptr(max(len, 0));
	for p := p_start; p < p_end; p += 1 {
		(^byte)(p)^ = b;
	}

	return ptr;
	// when size_of(rawptr) == 8 {
	// 	@(link_name="llvm.memset.p0i8.i64")
	// 	llvm_memset :: proc(dst: rawptr, val: byte, len: int, align: i32, is_volatile: bool) ---;
	// } else {
	// 	@(link_name="llvm.memset.p0i8.i32")
	// 	llvm_memset :: proc(dst: rawptr, val: byte, len: int, align: i32, is_volatile: bool) ---;
	// }

	// return llvm_memset(ptr, byte(val), len, 1, false);
}
