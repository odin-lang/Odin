//+private
package runtime

@(link_name="memset")
memset :: proc "c" (ptr: rawptr, val: i32, len: int) -> rawptr {
	addr := 0x1000 + 196 * size_of(int);
	fp := (rawptr(((^uintptr)(uintptr(addr)))^));
	return ((proc "c" (rawptr, i32, int) -> rawptr)(fp))(ptr, val, len);
}

@(link_name="memmove")
memmove :: proc "c" (dst, src: rawptr, len: int) -> rawptr {
	addr := 0x1000 + 195 * size_of(int);
	fp := (rawptr(((^uintptr)(uintptr(addr)))^));
	return ((proc "c" (rawptr, rawptr, int) -> rawptr)(fp))(dst, src, len);
}

@(link_name="memcpy")
memcpy :: proc "c" (dst, src: rawptr, len: int) -> rawptr {
	addr := 0x1000 + 194 * size_of(int);
	fp := (rawptr(((^uintptr)(uintptr(addr)))^));
	return ((proc "c" (rawptr, rawptr, int) -> rawptr)(fp))(dst, src, len);
}
