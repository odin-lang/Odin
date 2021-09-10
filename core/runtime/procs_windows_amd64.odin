//+private
package runtime

foreign import kernel32 "system:Kernel32.lib"

@(private)
foreign kernel32 {
	RaiseException :: proc "stdcall" (dwExceptionCode, dwExceptionFlags, nNumberOfArguments: u32, lpArguments: ^uint) -> ! ---
}

windows_trap_array_bounds :: proc "contextless" () -> ! {
	EXCEPTION_ARRAY_BOUNDS_EXCEEDED :: 0xC000008C


	RaiseException(EXCEPTION_ARRAY_BOUNDS_EXCEEDED, 0, 0, nil)
}

windows_trap_type_assertion :: proc "contextless" () -> ! {
	windows_trap_array_bounds()
}

// @private
// @(link_name="_tls_index")
// _tls_index: u32;

// @private
// @(link_name="_fltused")
// _fltused: i32 = 0x9875;

// @(link_name="memcpy")
memcpy :: proc "c" (dst, src: rawptr, len: int) -> rawptr {
	foreign kernel32 {
		RtlCopyMemory :: proc "c" (dst, src: rawptr, len: int) ---
	}
	if dst == nil || src == nil || len == 0 {
		return dst
	}
	RtlCopyMemory(dst, src, len)
	return dst
}

// @(link_name="memmove")
memmove :: proc "c" (dst, src: rawptr, len: int) -> rawptr {
	foreign kernel32 {
		RtlMoveMemory :: proc "c" (dst, src: rawptr, len: int) ---
	}
	if dst == nil || src == nil || len == 0 {
		return dst
	}
	RtlMoveMemory(dst, src, len)
	return dst
}

// @(link_name="memset")
memset :: proc "c" (ptr: rawptr, val: i32, len: int) -> rawptr #no_bounds_check {
	if ptr != nil && len != 0 {
		b := byte(val)
		p := ([^]byte)(ptr)[:len]
		for v in &p {
			v = b
		}
	}
	return ptr
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
