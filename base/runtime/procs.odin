package runtime

when ODIN_NO_CRT && ODIN_OS == .Windows {
	foreign import lib "system:NtDll.lib"
	
	@(private="file")
	@(default_calling_convention="system")
	foreign lib {
		RtlMoveMemory :: proc(dst, s: rawptr, length: int) ---
		RtlFillMemory :: proc(dst: rawptr, length: int, fill: i32) ---
	}
	
	@(link_name="memset", linkage="strong", require)
	memset :: proc "c" (ptr: rawptr, val: i32, len: int) -> rawptr {
		RtlFillMemory(ptr, len, val)
		return ptr
	}
	@(link_name="memmove", linkage="strong", require)
	memmove :: proc "c" (dst, src: rawptr, len: int) -> rawptr {
		RtlMoveMemory(dst, src, len)
		return dst
	}
	@(link_name="memcpy", linkage="strong", require)
	memcpy :: proc "c" (dst, src: rawptr, len: int) -> rawptr {
		RtlMoveMemory(dst, src, len)
		return dst
	}
} else when ODIN_NO_CRT || (ODIN_ARCH == .wasm32 || ODIN_ARCH == .wasm64p32) {
	// NOTE: on wasm, calls to these procs are generated (by LLVM) with type `i32` instead of `int`.
	//
	// NOTE: `#any_int` is also needed, because calls that we generate (and package code)
	//       will be using `int` and need to be converted.
	int_t :: i32 when ODIN_ARCH == .wasm64p32 else int

	@(link_name="memset", linkage="strong", require)
	memset :: proc "c" (ptr: rawptr, val: i32, #any_int len: int_t) -> rawptr {
		if ptr != nil && len != 0 {
			b := byte(val)
			p := ([^]byte)(ptr)
			for i := int_t(0); i < len; i += 1 {
				p[i] = b
			}
		}
		return ptr
	}

	@(link_name="bzero", linkage="strong", require)
	bzero :: proc "c" (ptr: rawptr, #any_int len: int_t) -> rawptr {
		if ptr != nil && len != 0 {
			p := ([^]byte)(ptr)
			for i := int_t(0); i < len; i += 1 {
				p[i] = 0
			}
		}
		return ptr
	}

	@(link_name="memmove", linkage="strong", require)
	memmove :: proc "c" (dst, src: rawptr, #any_int len: int_t) -> rawptr {
		d, s := ([^]byte)(dst), ([^]byte)(src)
		if d == s || len == 0 {
			return dst
		}
		if d > s && uintptr(d)-uintptr(s) < uintptr(len) {
			for i := len-1; i >= 0; i -= 1 {
				d[i] = s[i]
			}
			return dst
		}

		if s > d && uintptr(s)-uintptr(d) < uintptr(len) {
			for i := int_t(0); i < len; i += 1 {
				d[i] = s[i]
			}
			return dst
		}
		return memcpy(dst, src, len)
	}
	@(link_name="memcpy", linkage="strong", require)
	memcpy :: proc "c" (dst, src: rawptr, #any_int len: int_t) -> rawptr {
		d, s := ([^]byte)(dst), ([^]byte)(src)
		if d != s {
			for i := int_t(0); i < len; i += 1 {
				d[i] = s[i]
			}
		}
		return d
		
	}
} else {
	memset :: proc "c" (ptr: rawptr, val: i32, len: int) -> rawptr {
		if ptr != nil && len != 0 {
			b := byte(val)
			p := ([^]byte)(ptr)
			for i := 0; i < len; i += 1 {
				p[i] = b
			}
		}
		return ptr
	}
}
