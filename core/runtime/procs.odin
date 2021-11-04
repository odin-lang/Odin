package runtime

when ODIN_ARCH == "wasm32" || ODIN_ARCH == "wasm64" || (ODIN_NO_CRT && ODIN_OS != "windows") {
	@(link_name="memset", linkage="strong", require)
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
	
	@(link_name="memmove", linkage="strong", require)
	memmove :: proc "c" (dst, src: rawptr, len: int) -> rawptr {
		if dst != src {
			d, s := ([^]byte)(dst), ([^]byte)(src)
			d_end, s_end := d[len:], s[len:]
			for i := len-1; i >= 0; i -= 1 {
				d[i] = s[i]
			}
		}
		return dst
		
	}
	@(link_name="memcpy", linkage="strong", require)
	memcpy :: proc "c" (dst, src: rawptr, len: int) -> rawptr {
		if dst != src {
			d, s := ([^]byte)(dst), ([^]byte)(src)
			d_end, s_end := d[len:], s[len:]
			for i := len-1; i >= 0; i -= 1 {
				d[i] = s[i]
			}
		}
		return dst
		
	}
} else when ODIN_NO_CRT && ODIN_OS == "windows" {
	foreign import Kernel32 "system:Kernel32.lib"
	
	@(private="file")
	@(default_calling_convention="std")
	foreign Kernel32 {
		RtlMoveMemory :: proc(dst, src: rawptr, length: int) ---
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
} else {
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
}