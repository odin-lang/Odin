package runtime

foreign import kernel32 "system:Kernel32.lib"

windows_trap_array_bounds :: proc "contextless" () -> ! {
	DWORD :: u32;
	ULONG_PTR :: uint;

	EXCEPTION_ARRAY_BOUNDS_EXCEEDED :: 0xC000008C;

	foreign kernel32 {
		RaiseException :: proc "stdcall" (dwExceptionCode, dwExceptionFlags, nNumberOfArguments: DWORD, lpArguments: ^ULONG_PTR) -> ! ---
	}

	RaiseException(EXCEPTION_ARRAY_BOUNDS_EXCEEDED, 0, 0, nil);
}

windows_trap_type_assertion :: proc "contextless" () -> ! {
	windows_trap_array_bounds();
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
		return dst;
	}
	RtlCopyMemory(dst, src, len);
	return dst;
}

// @(link_name="memmove")
memmove :: proc "c" (dst, src: rawptr, len: int) -> rawptr {
	foreign kernel32 {
		RtlMoveMemory :: proc "c" (dst, src: rawptr, len: int) ---
	}
	if dst == nil || src == nil || len == 0 {
		return dst;
	}
	RtlMoveMemory(dst, src, len);
	return dst;
}

// @(link_name="memset")
memset :: proc "c" (ptr: rawptr, val: i32, len: int) -> rawptr {
	if ptr == nil || len == 0 {
		return ptr;
	}

	b := byte(val);

	p_start := uintptr(ptr);
	p_end := p_start + uintptr(max(len, 0));
	for p := p_start; p < p_end; p += 1 {
		(^byte)(p)^ = b;
	}

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
