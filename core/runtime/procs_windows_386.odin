//+private
package runtime

@require foreign import "system:int64.lib"

foreign import kernel32 "system:Kernel32.lib"

windows_trap_array_bounds :: proc "contextless" () -> ! {
	DWORD :: u32
	ULONG_PTR :: uint

	EXCEPTION_ARRAY_BOUNDS_EXCEEDED :: 0xC000008C

	foreign kernel32 {
		RaiseException :: proc "stdcall" (dwExceptionCode, dwExceptionFlags, nNumberOfArguments: DWORD, lpArguments: ^ULONG_PTR) -> ! ---
	}

	RaiseException(EXCEPTION_ARRAY_BOUNDS_EXCEEDED, 0, 0, nil)
}

windows_trap_type_assertion :: proc "contextless" () -> ! {
	windows_trap_array_bounds()
}

@(private, require, link_name="_fltused") _fltused: i32 = 0x9875

@(private, require, link_name="_tls_index") _tls_index: u32
@(private, require, link_name="_tls_array") _tls_array: u32



@(link_name="memcpy")
memcpy :: proc "c" (dst, src: rawptr, len: int) -> rawptr {
	if dst == nil || src == nil || len == 0 || dst == src {
		return dst
	}
	d := ([^]byte)(dst)
	s := ([^]byte)(src)

	for i in 0..<len {
		d[i] = s[i]
	}

	return dst;
}

@(link_name="memmove")
memmove :: proc "c" (dst, src: rawptr, len: int) -> rawptr {
	if dst == nil || src == nil || len == 0 || dst == src {
		return dst
	}

	d := ([^]byte)(dst)
	s := ([^]byte)(src)

	if s < d && d < s[len:] {
		// Overlap
		for i := len-1; len >= 0; i -= 1 {
			d[i] = s[i]
		}

	} else {
		for i in 0..<len {
			d[i] = s[i]
		}
	}

	return dst
}

@(link_name="memset")
memset :: proc "c" (ptr: rawptr, val: i32, len: int) -> rawptr {
	if ptr != nil && len != 0 {
		b := byte(val)
		p := ([^]byte)(ptr)[:len]
		for v in &p {
			v = b
		}
	}
	return ptr
}
