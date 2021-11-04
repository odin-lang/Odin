package runtime

when ODIN_ARCH == "wasm32" || ODIN_ARCH == "wasm64" {
	@(link_name="memset")
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
	
	@(link_name="memmove")
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
} else when ODIN_NO_CRT {
	@(link_name="memset")
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
	
	@(link_name="memmove")
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
	@(link_name="memcpy")
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