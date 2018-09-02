package runtime

foreign import kernel32 "system:Kernel32.lib"

@(link_name="memcpy")
memcpy :: proc "c" (dst, src: rawptr, len: int) -> rawptr {
	foreign kernel32 {
		RtlCopyMemory :: proc "c" (dst, src: rawptr, len: int) ---
	}
	RtlCopyMemory(dst, src, len);
	return dst;
}

@(link_name="memmove")
memmove :: proc "c" (dst, src: rawptr, len: int) -> rawptr {
	foreign kernel32 {
		RtlMoveMemory :: proc "c" (dst, src: rawptr, len: int) ---
	}
	RtlMoveMemory(dst, src, len);
	return dst;
}

@(link_name="memset")
memset :: proc "c" (ptr: rawptr, val: i32, len: int) -> rawptr {
	foreign kernel32 {
		RtlFillMemory :: proc "c" (dst: rawptr, len: int, fill: byte) ---
	}
	RtlFillMemory(ptr, len, byte(val));
	return ptr;
}

// @(link_name="memcmp")
// memcmp :: proc "c" (dst, src: rawptr, len: int) -> i32 {
// 	if dst == nil || src == nil {
// 		return 0;
// 	}
// 	if dst == src {
// 		return 0;
// 	}
// 	d, s := uintptr(dst), uintptr(src);
// 	n := uintptr(len);

// 	for i := uintptr(0); i < n; i += 1 {
// 		x, y := (^byte)(d+i)^, (^byte)(s+i)^;
// 		if x != y {
// 			return x < y ? -1 : +1;
// 		}
// 	}
// 	return 0;
// }
