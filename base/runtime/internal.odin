package runtime

import "base:intrinsics"

@(private="file")
IS_WASM :: ODIN_ARCH == .wasm32 || ODIN_ARCH == .wasm64p32

@(private)
RUNTIME_LINKAGE :: "strong" when (
	(ODIN_USE_SEPARATE_MODULES || 
	ODIN_BUILD_MODE == .Dynamic ||
	!ODIN_NO_CRT) &&
	!IS_WASM) else "internal"
RUNTIME_REQUIRE :: false // !ODIN_TILDE

@(private)
__float16 :: f16 when __ODIN_LLVM_F16_SUPPORTED else u16


@(private)
byte_slice :: #force_inline proc "contextless" (data: rawptr, len: int) -> []byte #no_bounds_check {
	return ([^]byte)(data)[:max(len, 0)]
}

is_power_of_two_int :: #force_inline proc "contextless" (x: int) -> bool {
	if x <= 0 {
		return false
	}
	return (x & (x-1)) == 0
}

align_forward_int :: #force_inline proc(ptr, align: int) -> int {
	assert(is_power_of_two_int(align))

	p := ptr
	modulo := p & (align-1)
	if modulo != 0 {
		p += align - modulo
	}
	return p
}

is_power_of_two_uint :: #force_inline proc "contextless" (x: uint) -> bool {
	if x <= 0 {
		return false
	}
	return (x & (x-1)) == 0
}

align_forward_uint :: #force_inline proc(ptr, align: uint) -> uint {
	assert(is_power_of_two_uint(align))

	p := ptr
	modulo := p & (align-1)
	if modulo != 0 {
		p += align - modulo
	}
	return p
}

is_power_of_two_uintptr :: #force_inline proc "contextless" (x: uintptr) -> bool {
	if x <= 0 {
		return false
	}
	return (x & (x-1)) == 0
}

align_forward_uintptr :: #force_inline proc(ptr, align: uintptr) -> uintptr {
	assert(is_power_of_two_uintptr(align))

	p := ptr
	modulo := p & (align-1)
	if modulo != 0 {
		p += align - modulo
	}
	return p
}

is_power_of_two :: proc {
	is_power_of_two_int,
	is_power_of_two_uint,
	is_power_of_two_uintptr,
}

align_forward :: proc {
	align_forward_int,
	align_forward_uint,
	align_forward_uintptr,
}

mem_zero :: proc "contextless" (data: rawptr, len: int) -> rawptr {
	if data == nil {
		return nil
	}
	if len <= 0 {
		return data
	}
	intrinsics.mem_zero(data, len)
	return data
}

mem_copy :: proc "contextless" (dst, src: rawptr, len: int) -> rawptr {
	if src != nil && dst != src && len > 0 {
		// NOTE(bill): This _must_ be implemented like C's memmove
		intrinsics.mem_copy(dst, src, len)
	}
	return dst
}

mem_copy_non_overlapping :: proc "contextless" (dst, src: rawptr, len: int) -> rawptr {
	if src != nil && dst != src && len > 0 {
		// NOTE(bill): This _must_ be implemented like C's memcpy
		intrinsics.mem_copy_non_overlapping(dst, src, len)
	}
	return dst
}

DEFAULT_ALIGNMENT :: 2*align_of(rawptr)

mem_alloc_bytes :: #force_inline proc(size: int, alignment: int = DEFAULT_ALIGNMENT, allocator := context.allocator, loc := #caller_location) -> ([]byte, Allocator_Error) {
	if size == 0 {
		return nil, nil
	}
	if allocator.procedure == nil {
		return nil, nil
	}
	return allocator.procedure(allocator.data, .Alloc, size, alignment, nil, 0, loc)
}

mem_alloc :: #force_inline proc(size: int, alignment: int = DEFAULT_ALIGNMENT, allocator := context.allocator, loc := #caller_location) -> ([]byte, Allocator_Error) {
	if size == 0 || allocator.procedure == nil {
		return nil, nil
	}
	return allocator.procedure(allocator.data, .Alloc, size, alignment, nil, 0, loc)
}

mem_alloc_non_zeroed :: #force_inline proc(size: int, alignment: int = DEFAULT_ALIGNMENT, allocator := context.allocator, loc := #caller_location) -> ([]byte, Allocator_Error) {
	if size == 0 || allocator.procedure == nil {
		return nil, nil
	}
	return allocator.procedure(allocator.data, .Alloc_Non_Zeroed, size, alignment, nil, 0, loc)
}

mem_free :: #force_inline proc(ptr: rawptr, allocator := context.allocator, loc := #caller_location) -> Allocator_Error {
	if ptr == nil || allocator.procedure == nil {
		return nil
	}
	_, err := allocator.procedure(allocator.data, .Free, 0, 0, ptr, 0, loc)
	return err
}

mem_free_with_size :: #force_inline proc(ptr: rawptr, byte_count: int, allocator := context.allocator, loc := #caller_location) -> Allocator_Error {
	if ptr == nil || allocator.procedure == nil {
		return nil
	}
	_, err := allocator.procedure(allocator.data, .Free, 0, 0, ptr, byte_count, loc)
	return err
}

mem_free_bytes :: #force_inline proc(bytes: []byte, allocator := context.allocator, loc := #caller_location) -> Allocator_Error {
	if bytes == nil || allocator.procedure == nil {
		return nil
	}
	_, err := allocator.procedure(allocator.data, .Free, 0, 0, raw_data(bytes), len(bytes), loc)
	return err
}


mem_free_all :: #force_inline proc(allocator := context.allocator, loc := #caller_location) -> (err: Allocator_Error) {
	if allocator.procedure != nil {
		_, err = allocator.procedure(allocator.data, .Free_All, 0, 0, nil, 0, loc)
	}
	return
}

_mem_resize :: #force_inline proc(ptr: rawptr, old_size, new_size: int, alignment: int = DEFAULT_ALIGNMENT, allocator := context.allocator, should_zero: bool, loc := #caller_location) -> (data: []byte, err: Allocator_Error) {
	if allocator.procedure == nil {
		return nil, nil
	}
	if new_size == 0 {
		if ptr != nil {
			_, err = allocator.procedure(allocator.data, .Free, 0, 0, ptr, old_size, loc)
			return
		}
		return
	} else if ptr == nil {
		if should_zero {
			return allocator.procedure(allocator.data, .Alloc, new_size, alignment, nil, 0, loc)
		} else {
			return allocator.procedure(allocator.data, .Alloc_Non_Zeroed, new_size, alignment, nil, 0, loc)
		}
	} else if old_size == new_size && uintptr(ptr) % uintptr(alignment) == 0 {
		data = ([^]byte)(ptr)[:old_size]
		return
	}

	if should_zero {
		data, err = allocator.procedure(allocator.data, .Resize, new_size, alignment, ptr, old_size, loc)
	} else {
		data, err = allocator.procedure(allocator.data, .Resize_Non_Zeroed, new_size, alignment, ptr, old_size, loc)
	}
	if err == .Mode_Not_Implemented {
		if should_zero {
			data, err = allocator.procedure(allocator.data, .Alloc, new_size, alignment, nil, 0, loc)
		} else {
			data, err = allocator.procedure(allocator.data, .Alloc_Non_Zeroed, new_size, alignment, nil, 0, loc)
		}
		if err != nil {
			return
		}
		copy(data, ([^]byte)(ptr)[:old_size])
		_, err = allocator.procedure(allocator.data, .Free, 0, 0, ptr, old_size, loc)
	}
	return
}

mem_resize :: proc(ptr: rawptr, old_size, new_size: int, alignment: int = DEFAULT_ALIGNMENT, allocator := context.allocator, loc := #caller_location) -> (data: []byte, err: Allocator_Error) {
	return _mem_resize(ptr, old_size, new_size, alignment, allocator, true, loc)
}
non_zero_mem_resize :: proc(ptr: rawptr, old_size, new_size: int, alignment: int = DEFAULT_ALIGNMENT, allocator := context.allocator, loc := #caller_location) -> (data: []byte, err: Allocator_Error) {
	return _mem_resize(ptr, old_size, new_size, alignment, allocator, false, loc)
}

memory_equal :: proc "contextless" (x, y: rawptr, n: int) -> bool {
	switch {
	case n == 0: return true
	case x == y: return true
	}
	a, b := ([^]byte)(x), ([^]byte)(y)
	length := uint(n)

	for i := uint(0); i < length; i += 1 {
		if a[i] != b[i] {
			return false
		}
	}
	return true
	
/*

	when size_of(uint) == 8 {
		if word_length := length >> 3; word_length != 0 {
			for _ in 0..<word_length {
				if intrinsics.unaligned_load((^u64)(a)) != intrinsics.unaligned_load((^u64)(b)) {
					return false
				}
				a = a[size_of(u64):]
				b = b[size_of(u64):]
			}
		}
		
		if length & 4 != 0 {
			if intrinsics.unaligned_load((^u32)(a)) != intrinsics.unaligned_load((^u32)(b)) {
				return false
			}
			a = a[size_of(u32):]
			b = b[size_of(u32):]
		}
		
		if length & 2 != 0 {
			if intrinsics.unaligned_load((^u16)(a)) != intrinsics.unaligned_load((^u16)(b)) {
				return false
			}
			a = a[size_of(u16):]
			b = b[size_of(u16):]
		}
		
		if length & 1 != 0 && a[0] != b[0] {
			return false	
		}
		return true
	} else {
		if word_length := length >> 2; word_length != 0 {
			for _ in 0..<word_length {
				if intrinsics.unaligned_load((^u32)(a)) != intrinsics.unaligned_load((^u32)(b)) {
					return false
				}
				a = a[size_of(u32):]
				b = b[size_of(u32):]
			}
		}
		
		length &= 3
		
		if length != 0 {
			for i in 0..<length {
				if a[i] != b[i] {
					return false
				}
			}
		}

		return true
	}
*/

}
memory_compare :: proc "contextless" (a, b: rawptr, n: int) -> int #no_bounds_check {
	switch {
	case a == b:   return 0
	case a == nil: return -1
	case b == nil: return +1
	}

	x := uintptr(a)
	y := uintptr(b)
	n := uintptr(n)

	SU :: size_of(uintptr)
	fast := n/SU + 1
	offset := (fast-1)*SU
	curr_block := uintptr(0)
	if n < SU {
		fast = 0
	}

	for /**/; curr_block < fast; curr_block += 1 {
		va := (^uintptr)(x + curr_block * size_of(uintptr))^
		vb := (^uintptr)(y + curr_block * size_of(uintptr))^
		if va ~ vb != 0 {
			for pos := curr_block*SU; pos < n; pos += 1 {
				a := (^byte)(x+pos)^
				b := (^byte)(y+pos)^
				if a ~ b != 0 {
					return -1 if (int(a) - int(b)) < 0 else +1
				}
			}
		}
	}

	for /**/; offset < n; offset += 1 {
		a := (^byte)(x+offset)^
		b := (^byte)(y+offset)^
		if a ~ b != 0 {
			return -1 if (int(a) - int(b)) < 0 else +1
		}
	}

	return 0
}

memory_compare_zero :: proc "contextless" (a: rawptr, n: int) -> int #no_bounds_check {
	x := uintptr(a)
	n := uintptr(n)

	SU :: size_of(uintptr)
	fast := n/SU + 1
	offset := (fast-1)*SU
	curr_block := uintptr(0)
	if n < SU {
		fast = 0
	}

	for /**/; curr_block < fast; curr_block += 1 {
		va := (^uintptr)(x + curr_block * size_of(uintptr))^
		if va ~ 0 != 0 {
			for pos := curr_block*SU; pos < n; pos += 1 {
				a := (^byte)(x+pos)^
				if a ~ 0 != 0 {
					return -1 if int(a) < 0 else +1
				}
			}
		}
	}

	for /**/; offset < n; offset += 1 {
		a := (^byte)(x+offset)^
		if a ~ 0 != 0 {
			return -1 if int(a) < 0 else +1
		}
	}

	return 0
}

string_eq :: proc "contextless" (lhs, rhs: string) -> bool {
	x := transmute(Raw_String)lhs
	y := transmute(Raw_String)rhs
	if x.len != y.len {
		return false
	}
	return #force_inline memory_equal(x.data, y.data, x.len)
}

string_cmp :: proc "contextless" (a, b: string) -> int {
	x := transmute(Raw_String)a
	y := transmute(Raw_String)b

	ret := memory_compare(x.data, y.data, min(x.len, y.len))
	if ret == 0 && x.len != y.len {
		return -1 if x.len < y.len else +1
	}
	return ret
}

string_ne :: #force_inline proc "contextless" (a, b: string) -> bool { return !string_eq(a, b) }
string_lt :: #force_inline proc "contextless" (a, b: string) -> bool { return string_cmp(a, b) < 0 }
string_gt :: #force_inline proc "contextless" (a, b: string) -> bool { return string_cmp(a, b) > 0 }
string_le :: #force_inline proc "contextless" (a, b: string) -> bool { return string_cmp(a, b) <= 0 }
string_ge :: #force_inline proc "contextless" (a, b: string) -> bool { return string_cmp(a, b) >= 0 }

cstring_len :: proc "contextless" (s: cstring) -> int {
	p0 := uintptr((^byte)(s))
	p := p0
	for p != 0 && (^byte)(p)^ != 0 {
		p += 1
	}
	return int(p - p0)
}

cstring_to_string :: proc "contextless" (s: cstring) -> string {
	if s == nil {
		return ""
	}
	ptr := (^byte)(s)
	n := cstring_len(s)
	return transmute(string)Raw_String{ptr, n}
}


cstring_eq :: proc "contextless" (lhs, rhs: cstring) -> bool {
	x := ([^]byte)(lhs)
	y := ([^]byte)(rhs)
	if x == y {
		return true
	}
	if (x == nil) ~ (y == nil) {
		return false
	}
	xn := cstring_len(lhs)
	yn := cstring_len(rhs)
	if xn != yn {
		return false
	}
	return #force_inline memory_equal(x, y, xn)
}

cstring_cmp :: proc "contextless" (lhs, rhs: cstring) -> int {
	x := ([^]byte)(lhs)
	y := ([^]byte)(rhs)
	if x == y {
		return 0
	}
	if (x == nil) ~ (y == nil) {
		return -1 if x == nil else +1
	}
	xn := cstring_len(lhs)
	yn := cstring_len(rhs)
	ret := memory_compare(x, y, min(xn, yn))
	if ret == 0 && xn != yn {
		return -1 if xn < yn else +1
	}
	return ret
}

cstring_ne :: #force_inline proc "contextless" (a, b: cstring) -> bool { return !cstring_eq(a, b) }
cstring_lt :: #force_inline proc "contextless" (a, b: cstring) -> bool { return cstring_cmp(a, b) < 0 }
cstring_gt :: #force_inline proc "contextless" (a, b: cstring) -> bool { return cstring_cmp(a, b) > 0 }
cstring_le :: #force_inline proc "contextless" (a, b: cstring) -> bool { return cstring_cmp(a, b) <= 0 }
cstring_ge :: #force_inline proc "contextless" (a, b: cstring) -> bool { return cstring_cmp(a, b) >= 0 }


complex32_eq :: #force_inline proc "contextless"  (a, b: complex32)  -> bool { return real(a) == real(b) && imag(a) == imag(b) }
complex32_ne :: #force_inline proc "contextless"  (a, b: complex32)  -> bool { return real(a) != real(b) || imag(a) != imag(b) }

complex64_eq :: #force_inline proc "contextless"  (a, b: complex64)  -> bool { return real(a) == real(b) && imag(a) == imag(b) }
complex64_ne :: #force_inline proc "contextless"  (a, b: complex64)  -> bool { return real(a) != real(b) || imag(a) != imag(b) }

complex128_eq :: #force_inline proc "contextless" (a, b: complex128) -> bool { return real(a) == real(b) && imag(a) == imag(b) }
complex128_ne :: #force_inline proc "contextless" (a, b: complex128) -> bool { return real(a) != real(b) || imag(a) != imag(b) }


quaternion64_eq :: #force_inline proc "contextless"  (a, b: quaternion64)  -> bool { return real(a) == real(b) && imag(a) == imag(b) && jmag(a) == jmag(b) && kmag(a) == kmag(b) }
quaternion64_ne :: #force_inline proc "contextless"  (a, b: quaternion64)  -> bool { return real(a) != real(b) || imag(a) != imag(b) || jmag(a) != jmag(b) || kmag(a) != kmag(b) }

quaternion128_eq :: #force_inline proc "contextless"  (a, b: quaternion128)  -> bool { return real(a) == real(b) && imag(a) == imag(b) && jmag(a) == jmag(b) && kmag(a) == kmag(b) }
quaternion128_ne :: #force_inline proc "contextless"  (a, b: quaternion128)  -> bool { return real(a) != real(b) || imag(a) != imag(b) || jmag(a) != jmag(b) || kmag(a) != kmag(b) }

quaternion256_eq :: #force_inline proc "contextless" (a, b: quaternion256) -> bool { return real(a) == real(b) && imag(a) == imag(b) && jmag(a) == jmag(b) && kmag(a) == kmag(b) }
quaternion256_ne :: #force_inline proc "contextless" (a, b: quaternion256) -> bool { return real(a) != real(b) || imag(a) != imag(b) || jmag(a) != jmag(b) || kmag(a) != kmag(b) }


string_decode_rune :: #force_inline proc "contextless" (s: string) -> (rune, int) {
	// NOTE(bill): Duplicated here to remove dependency on package unicode/utf8

	@(static, rodata) accept_sizes := [256]u8{
		0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, // 0x00-0x0f
		0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, // 0x10-0x1f
		0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, // 0x20-0x2f
		0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, // 0x30-0x3f
		0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, // 0x40-0x4f
		0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, // 0x50-0x5f
		0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, // 0x60-0x6f
		0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, // 0x70-0x7f

		0xf1, 0xf1, 0xf1, 0xf1, 0xf1, 0xf1, 0xf1, 0xf1, 0xf1, 0xf1, 0xf1, 0xf1, 0xf1, 0xf1, 0xf1, 0xf1, // 0x80-0x8f
		0xf1, 0xf1, 0xf1, 0xf1, 0xf1, 0xf1, 0xf1, 0xf1, 0xf1, 0xf1, 0xf1, 0xf1, 0xf1, 0xf1, 0xf1, 0xf1, // 0x90-0x9f
		0xf1, 0xf1, 0xf1, 0xf1, 0xf1, 0xf1, 0xf1, 0xf1, 0xf1, 0xf1, 0xf1, 0xf1, 0xf1, 0xf1, 0xf1, 0xf1, // 0xa0-0xaf
		0xf1, 0xf1, 0xf1, 0xf1, 0xf1, 0xf1, 0xf1, 0xf1, 0xf1, 0xf1, 0xf1, 0xf1, 0xf1, 0xf1, 0xf1, 0xf1, // 0xb0-0xbf
		0xf1, 0xf1, 0x02, 0x02, 0x02, 0x02, 0x02, 0x02, 0x02, 0x02, 0x02, 0x02, 0x02, 0x02, 0x02, 0x02, // 0xc0-0xcf
		0x02, 0x02, 0x02, 0x02, 0x02, 0x02, 0x02, 0x02, 0x02, 0x02, 0x02, 0x02, 0x02, 0x02, 0x02, 0x02, // 0xd0-0xdf
		0x13, 0x03, 0x03, 0x03, 0x03, 0x03, 0x03, 0x03, 0x03, 0x03, 0x03, 0x03, 0x03, 0x23, 0x03, 0x03, // 0xe0-0xef
		0x34, 0x04, 0x04, 0x04, 0x44, 0xf1, 0xf1, 0xf1, 0xf1, 0xf1, 0xf1, 0xf1, 0xf1, 0xf1, 0xf1, 0xf1, // 0xf0-0xff
	}
	Accept_Range :: struct {lo, hi: u8}

	@(static, rodata) accept_ranges := [5]Accept_Range{
		{0x80, 0xbf},
		{0xa0, 0xbf},
		{0x80, 0x9f},
		{0x90, 0xbf},
		{0x80, 0x8f},
	}

	MASKX :: 0b0011_1111
	MASK2 :: 0b0001_1111
	MASK3 :: 0b0000_1111
	MASK4 :: 0b0000_0111

	LOCB :: 0b1000_0000
	HICB :: 0b1011_1111


	RUNE_ERROR :: '\ufffd'

	n := len(s)
	if n < 1 {
		return RUNE_ERROR, 0
	}
	s0 := s[0]
	x := accept_sizes[s0]
	if x >= 0xF0 {
		mask := rune(x) << 31 >> 31 // NOTE(bill): Create 0x0000 or 0xffff.
		return rune(s[0])&~mask | RUNE_ERROR&mask, 1
	}
	sz := x & 7
	accept := accept_ranges[x>>4]
	if n < int(sz) {
		return RUNE_ERROR, 1
	}
	b1 := s[1]
	if b1 < accept.lo || accept.hi < b1 {
		return RUNE_ERROR, 1
	}
	if sz == 2 {
		return rune(s0&MASK2)<<6 | rune(b1&MASKX), 2
	}
	b2 := s[2]
	if b2 < LOCB || HICB < b2 {
		return RUNE_ERROR, 1
	}
	if sz == 3 {
		return rune(s0&MASK3)<<12 | rune(b1&MASKX)<<6 | rune(b2&MASKX), 3
	}
	b3 := s[3]
	if b3 < LOCB || HICB < b3 {
		return RUNE_ERROR, 1
	}
	return rune(s0&MASK4)<<18 | rune(b1&MASKX)<<12 | rune(b2&MASKX)<<6 | rune(b3&MASKX), 4
}

string_decode_last_rune :: proc "contextless" (s: string) -> (rune, int) {
	RUNE_ERROR :: '\ufffd'
	RUNE_SELF  :: 0x80
	UTF_MAX    :: 4

	r: rune
	size: int
	start, end, limit: int

	end = len(s)
	if end == 0 {
		return RUNE_ERROR, 0
	}
	start = end-1
	r = rune(s[start])
	if r < RUNE_SELF {
		return r, 1
	}

	limit = max(end - UTF_MAX, 0)

	for start-=1; start >= limit; start-=1 {
		if (s[start] & 0xc0) != RUNE_SELF {
			break
		}
	}

	start = max(start, 0)
	r, size = string_decode_rune(s[start:end])
	if start+size != end {
		return RUNE_ERROR, 1
	}
	return r, size
}

abs_complex32 :: #force_inline proc "contextless" (x: complex32) -> f16 {
	p, q := abs(real(x)), abs(imag(x))
	if p < q {
		p, q = q, p
	}
	if p == 0 {
		return 0
	}
	q = q / p
	return p * f16(intrinsics.sqrt(f32(1 + q*q)))
}
abs_complex64 :: #force_inline proc "contextless" (x: complex64) -> f32 {
	p, q := abs(real(x)), abs(imag(x))
	if p < q {
		p, q = q, p
	}
	if p == 0 {
		return 0
	}
	q = q / p
	return p * intrinsics.sqrt(1 + q*q)
}
abs_complex128 :: #force_inline proc "contextless" (x: complex128) -> f64 {
	p, q := abs(real(x)), abs(imag(x))
	if p < q {
		p, q = q, p
	}
	if p == 0 {
		return 0
	}
	q = q / p
	return p * intrinsics.sqrt(1 + q*q)
}
abs_quaternion64 :: #force_inline proc "contextless" (x: quaternion64) -> f16 {
	r, i, j, k := real(x), imag(x), jmag(x), kmag(x)
	return f16(intrinsics.sqrt(f32(r*r + i*i + j*j + k*k)))
}
abs_quaternion128 :: #force_inline proc "contextless" (x: quaternion128) -> f32 {
	r, i, j, k := real(x), imag(x), jmag(x), kmag(x)
	return intrinsics.sqrt(r*r + i*i + j*j + k*k)
}
abs_quaternion256 :: #force_inline proc "contextless" (x: quaternion256) -> f64 {
	r, i, j, k := real(x), imag(x), jmag(x), kmag(x)
	return intrinsics.sqrt(r*r + i*i + j*j + k*k)
}


quo_complex32 :: proc "contextless" (n, m: complex32) -> complex32 {
	e, f: f16

	if abs(real(m)) >= abs(imag(m)) {
		ratio := imag(m) / real(m)
		denom := real(m) + ratio*imag(m)
		e = (real(n) + imag(n)*ratio) / denom
		f = (imag(n) - real(n)*ratio) / denom
	} else {
		ratio := real(m) / imag(m)
		denom := imag(m) + ratio*real(m)
		e = (real(n)*ratio + imag(n)) / denom
		f = (imag(n)*ratio - real(n)) / denom
	}

	return complex(e, f)
}


quo_complex64 :: proc "contextless" (n, m: complex64) -> complex64 {
	e, f: f32

	if abs(real(m)) >= abs(imag(m)) {
		ratio := imag(m) / real(m)
		denom := real(m) + ratio*imag(m)
		e = (real(n) + imag(n)*ratio) / denom
		f = (imag(n) - real(n)*ratio) / denom
	} else {
		ratio := real(m) / imag(m)
		denom := imag(m) + ratio*real(m)
		e = (real(n)*ratio + imag(n)) / denom
		f = (imag(n)*ratio - real(n)) / denom
	}

	return complex(e, f)
}

quo_complex128 :: proc "contextless" (n, m: complex128) -> complex128 {
	e, f: f64

	if abs(real(m)) >= abs(imag(m)) {
		ratio := imag(m) / real(m)
		denom := real(m) + ratio*imag(m)
		e = (real(n) + imag(n)*ratio) / denom
		f = (imag(n) - real(n)*ratio) / denom
	} else {
		ratio := real(m) / imag(m)
		denom := imag(m) + ratio*real(m)
		e = (real(n)*ratio + imag(n)) / denom
		f = (imag(n)*ratio - real(n)) / denom
	}

	return complex(e, f)
}

mul_quaternion64 :: proc "contextless" (q, r: quaternion64) -> quaternion64 {
	q0, q1, q2, q3 := real(q), imag(q), jmag(q), kmag(q)
	r0, r1, r2, r3 := real(r), imag(r), jmag(r), kmag(r)

	t0 := r0*q0 - r1*q1 - r2*q2 - r3*q3
	t1 := r0*q1 + r1*q0 - r2*q3 + r3*q2
	t2 := r0*q2 + r1*q3 + r2*q0 - r3*q1
	t3 := r0*q3 - r1*q2 + r2*q1 + r3*q0

	return quaternion(w=t0, x=t1, y=t2, z=t3)
}

mul_quaternion128 :: proc "contextless" (q, r: quaternion128) -> quaternion128 {
	q0, q1, q2, q3 := real(q), imag(q), jmag(q), kmag(q)
	r0, r1, r2, r3 := real(r), imag(r), jmag(r), kmag(r)

	t0 := r0*q0 - r1*q1 - r2*q2 - r3*q3
	t1 := r0*q1 + r1*q0 - r2*q3 + r3*q2
	t2 := r0*q2 + r1*q3 + r2*q0 - r3*q1
	t3 := r0*q3 - r1*q2 + r2*q1 + r3*q0

	return quaternion(w=t0, x=t1, y=t2, z=t3)
}

mul_quaternion256 :: proc "contextless" (q, r: quaternion256) -> quaternion256 {
	q0, q1, q2, q3 := real(q), imag(q), jmag(q), kmag(q)
	r0, r1, r2, r3 := real(r), imag(r), jmag(r), kmag(r)

	t0 := r0*q0 - r1*q1 - r2*q2 - r3*q3
	t1 := r0*q1 + r1*q0 - r2*q3 + r3*q2
	t2 := r0*q2 + r1*q3 + r2*q0 - r3*q1
	t3 := r0*q3 - r1*q2 + r2*q1 + r3*q0

	return quaternion(w=t0, x=t1, y=t2, z=t3)
}

quo_quaternion64 :: proc "contextless" (q, r: quaternion64) -> quaternion64 {
	q0, q1, q2, q3 := real(q), imag(q), jmag(q), kmag(q)
	r0, r1, r2, r3 := real(r), imag(r), jmag(r), kmag(r)

	invmag2 := 1.0 / (r0*r0 + r1*r1 + r2*r2 + r3*r3)

	t0 := (r0*q0 + r1*q1 + r2*q2 + r3*q3) * invmag2
	t1 := (r0*q1 - r1*q0 - r2*q3 - r3*q2) * invmag2
	t2 := (r0*q2 - r1*q3 - r2*q0 + r3*q1) * invmag2
	t3 := (r0*q3 + r1*q2 + r2*q1 - r3*q0) * invmag2

	return quaternion(w=t0, x=t1, y=t2, z=t3)
}

quo_quaternion128 :: proc "contextless" (q, r: quaternion128) -> quaternion128 {
	q0, q1, q2, q3 := real(q), imag(q), jmag(q), kmag(q)
	r0, r1, r2, r3 := real(r), imag(r), jmag(r), kmag(r)

	invmag2 := 1.0 / (r0*r0 + r1*r1 + r2*r2 + r3*r3)

	t0 := (r0*q0 + r1*q1 + r2*q2 + r3*q3) * invmag2
	t1 := (r0*q1 - r1*q0 - r2*q3 - r3*q2) * invmag2
	t2 := (r0*q2 - r1*q3 - r2*q0 + r3*q1) * invmag2
	t3 := (r0*q3 + r1*q2 + r2*q1 - r3*q0) * invmag2

	return quaternion(w=t0, x=t1, y=t2, z=t3)
}

quo_quaternion256 :: proc "contextless" (q, r: quaternion256) -> quaternion256 {
	q0, q1, q2, q3 := real(q), imag(q), jmag(q), kmag(q)
	r0, r1, r2, r3 := real(r), imag(r), jmag(r), kmag(r)

	invmag2 := 1.0 / (r0*r0 + r1*r1 + r2*r2 + r3*r3)

	t0 := (r0*q0 + r1*q1 + r2*q2 + r3*q3) * invmag2
	t1 := (r0*q1 - r1*q0 - r2*q3 - r3*q2) * invmag2
	t2 := (r0*q2 - r1*q3 - r2*q0 + r3*q1) * invmag2
	t3 := (r0*q3 + r1*q2 + r2*q1 - r3*q0) * invmag2

	return quaternion(w=t0, x=t1, y=t2, z=t3)
}

@(link_name="__truncsfhf2", linkage=RUNTIME_LINKAGE, require=RUNTIME_REQUIRE)
truncsfhf2 :: proc "c" (value: f32) -> __float16 {
	v: struct #raw_union { i: u32, f: f32 }
	i, s, e, m: i32

	v.f = value
	i = i32(v.i)

	s =  (i >> 16) & 0x00008000
	e = ((i >> 23) & 0x000000ff) - (127 - 15)
	m =   i        & 0x007fffff


	if e <= 0 {
		if e < -10 {
			return transmute(__float16)u16(s)
		}
		m = (m | 0x00800000) >> u32(1 - e)

		if m & 0x00001000 != 0 {
			m += 0x00002000
		}

		return transmute(__float16)u16(s | (m >> 13))
	} else if e == 0xff - (127 - 15) {
		if m == 0 {
			return transmute(__float16)u16(s | 0x7c00) /* NOTE(bill): infinity */
		} else {
			/* NOTE(bill): NAN */
			m >>= 13
			return transmute(__float16)u16(s | 0x7c00 | m | i32(m == 0))
		}
	} else {
		if m & 0x00001000 != 0 {
			m += 0x00002000
			if (m & 0x00800000) != 0 {
				m = 0
				e += 1
			}
		}

		if e > 30 {
			f := i64(1e12)
			for j := 0; j < 10; j += 1 {
				/* NOTE(bill): Cause overflow */
				g := intrinsics.volatile_load(&f)
				g *= g
				intrinsics.volatile_store(&f, g)
			}

			return transmute(__float16)u16(s | 0x7c00)
		}

		return transmute(__float16)u16(s | (e << 10) | (m >> 13))
	}
}

@(link_name="__aeabi_d2h", linkage=RUNTIME_LINKAGE, require=RUNTIME_REQUIRE)
aeabi_d2h :: proc "c" (value: f64) -> __float16 {
	return truncsfhf2(f32(value))
}

@(link_name="__truncdfhf2", linkage=RUNTIME_LINKAGE, require=RUNTIME_REQUIRE)
truncdfhf2 :: proc "c" (value: f64) -> __float16 {
	return truncsfhf2(f32(value))
}

@(link_name="__gnu_h2f_ieee", linkage=RUNTIME_LINKAGE, require=RUNTIME_REQUIRE)
gnu_h2f_ieee :: proc "c" (value_: __float16) -> f32 {
	fp32 :: struct #raw_union { u: u32, f: f32 }

	value := transmute(u16)value_
	v: fp32
	magic, inf_or_nan: fp32
	magic.u = u32((254 - 15) << 23)
	inf_or_nan.u = u32((127 + 16) << 23)

	v.u = u32(value & 0x7fff) << 13
	v.f *= magic.f
	if v.f >= inf_or_nan.f {
		v.u |= 255 << 23
	}
	v.u |= u32(value & 0x8000) << 16
	return v.f
}


@(link_name="__gnu_f2h_ieee", linkage=RUNTIME_LINKAGE, require=RUNTIME_REQUIRE)
gnu_f2h_ieee :: proc "c" (value: f32) -> __float16 {
	return truncsfhf2(value)
}

@(link_name="__extendhfsf2", linkage=RUNTIME_LINKAGE, require=RUNTIME_REQUIRE)
extendhfsf2 :: proc "c" (value: __float16) -> f32 {
	return gnu_h2f_ieee(value)
}



@(link_name="__floattidf", linkage=RUNTIME_LINKAGE, require=RUNTIME_REQUIRE)
floattidf :: proc "c" (a: i128) -> f64 {
when IS_WASM {
	return 0
} else {
	DBL_MANT_DIG :: 53
	if a == 0 {
		return 0.0
	}
	a := a
	N :: size_of(i128) * 8
	s := a >> (N-1)
	a = (a ~ s) - s
	sd: = N - intrinsics.count_leading_zeros(a)  // number of significant digits
	e := i32(sd - 1)        // exponent
	if sd > DBL_MANT_DIG {
		switch sd {
		case DBL_MANT_DIG + 1:
			a <<= 1
		case DBL_MANT_DIG + 2:
			// okay
		case:
			a = i128(u128(a) >> u128(sd - (DBL_MANT_DIG+2))) |
			    i128(u128(a) & (~u128(0) >> u128(N + DBL_MANT_DIG+2 - sd)) != 0)
		}

		a |= i128((a & 4) != 0)
		a += 1
		a >>= 2

		if a & (i128(1) << DBL_MANT_DIG) != 0 {
			a >>= 1
			e += 1
		}
	} else {
		a <<= u128(DBL_MANT_DIG - sd) & 127
	}
	fb: [2]u32
	fb[1] = (u32(s) & 0x80000000) |          // sign
	        (u32(e + 1023) << 20) |          // exponent
	        u32((u64(a) >> 32) & 0x000FFFFF) // mantissa-high
	fb[0] = u32(a)                           // mantissa-low
	return transmute(f64)fb
}
}


@(link_name="__floattidf_unsigned", linkage=RUNTIME_LINKAGE, require=RUNTIME_REQUIRE)
floattidf_unsigned :: proc "c" (a: u128) -> f64 {
when IS_WASM {
	return 0
} else {
	DBL_MANT_DIG :: 53
	if a == 0 {
		return 0.0
	}
	a := a
	N :: size_of(u128) * 8
	sd: = N - intrinsics.count_leading_zeros(a)  // number of significant digits
	e := i32(sd - 1)        // exponent
	if sd > DBL_MANT_DIG {
		switch sd {
		case DBL_MANT_DIG + 1:
			a <<= 1
		case DBL_MANT_DIG + 2:
			// okay
		case:
			a = u128(u128(a) >> u128(sd - (DBL_MANT_DIG+2))) |
				u128(u128(a) & (~u128(0) >> u128(N + DBL_MANT_DIG+2 - sd)) != 0)
		}

		a |= u128((a & 4) != 0)
		a += 1
		a >>= 2

		if a & (1 << DBL_MANT_DIG) != 0 {
			a >>= 1
			e += 1
		}
	} else {
		a <<= u128(DBL_MANT_DIG - sd)
	}
	fb: [2]u32
	fb[1] = (0) |                            // sign
	        u32((e + 1023) << 20) |          // exponent
	        u32((u64(a) >> 32) & 0x000FFFFF) // mantissa-high
	fb[0] = u32(a)                           // mantissa-low
	return transmute(f64)fb
}
}



@(link_name="__fixunsdfti", linkage=RUNTIME_LINKAGE, require=RUNTIME_REQUIRE)
fixunsdfti :: #force_no_inline proc "c" (a: f64) -> u128 {
	// TODO(bill): implement `fixunsdfti` correctly
	x := u64(a)
	return u128(x)
}

@(link_name="__fixunsdfdi", linkage=RUNTIME_LINKAGE, require=RUNTIME_REQUIRE)
fixunsdfdi :: #force_no_inline proc "c" (a: f64) -> i128 {
	// TODO(bill): implement `fixunsdfdi` correctly
	x := i64(a)
	return i128(x)
}




@(link_name="__umodti3", linkage=RUNTIME_LINKAGE, require=RUNTIME_REQUIRE)
umodti3 :: proc "c" (a, b: u128) -> u128 {
	r: u128 = ---
	_ = udivmod128(a, b, &r)
	return r
}


@(link_name="__udivmodti4", linkage=RUNTIME_LINKAGE, require=RUNTIME_REQUIRE)
udivmodti4 :: proc "c" (a, b: u128, rem: ^u128) -> u128 {
	return udivmod128(a, b, rem)
}

when !IS_WASM {
	@(link_name="__udivti3", linkage=RUNTIME_LINKAGE, require=RUNTIME_REQUIRE)
	udivti3 :: proc "c" (a, b: u128) -> u128 {
		return udivmodti4(a, b, nil)
	}
}


@(link_name="__modti3", linkage=RUNTIME_LINKAGE, require=RUNTIME_REQUIRE)
modti3 :: proc "c" (a, b: i128) -> i128 {
	s_a := a >> (128 - 1)
	s_b := b >> (128 - 1)
	an := (a ~ s_a) - s_a
	bn := (b ~ s_b) - s_b

	r: u128 = ---
	_ = udivmod128(transmute(u128)an, transmute(u128)bn, &r)
	return (transmute(i128)r ~ s_a) - s_a
}


@(link_name="__divmodti4", linkage=RUNTIME_LINKAGE, require=RUNTIME_REQUIRE)
divmodti4 :: proc "c" (a, b: i128, rem: ^i128) -> i128 {
	u := udivmod128(transmute(u128)a, transmute(u128)b, cast(^u128)rem)
	return transmute(i128)u
}

@(link_name="__divti3", linkage=RUNTIME_LINKAGE, require=RUNTIME_REQUIRE)
divti3 :: proc "c" (a, b: i128) -> i128 {
	u := udivmodti4(transmute(u128)a, transmute(u128)b, nil)
	return transmute(i128)u
}


@(link_name="__fixdfti", linkage=RUNTIME_LINKAGE, require=RUNTIME_REQUIRE)
fixdfti :: proc(a: u64) -> i128 {
	significandBits :: 52
	typeWidth       :: (size_of(u64)*8)
	exponentBits    :: (typeWidth - significandBits - 1)
	maxExponent     :: ((1 << exponentBits) - 1)
	exponentBias    :: (maxExponent >> 1)

	implicitBit     :: (u64(1) << significandBits)
	significandMask :: (implicitBit - 1)
	signBit         :: (u64(1) << (significandBits + exponentBits))
	absMask         :: (signBit - 1)
	exponentMask    :: (absMask ~ significandMask)

	// Break a into sign, exponent, significand
	aRep := a
	aAbs := aRep & absMask
	sign := i128(-1 if aRep & signBit != 0 else 1)
	exponent := u64((aAbs >> significandBits) - exponentBias)
	significand := u64((aAbs & significandMask) | implicitBit)

	// If exponent is negative, the result is zero.
	if exponent < 0 {
		return 0
	}

	// If the value is too large for the integer type, saturate.
	if exponent >= size_of(i128) * 8 {
		return max(i128) if sign == 1 else min(i128)
	}

	// If 0 <= exponent < significandBits, right shift to get the result.
	// Otherwise, shift left.
	if exponent < significandBits {
		return sign * i128(significand >> (significandBits - exponent))
	} else {
		return sign * (i128(significand) << (exponent - significandBits))
	}

}



__write_bits :: proc "contextless" (dst, src: [^]byte, offset: uintptr, size: uintptr) {
	for i in 0..<size {
		j := offset+i
		the_bit := byte((src[i>>3]) & (1<<(i&7)) != 0)
		dst[j>>3] &~=       1<<(j&7)
		dst[j>>3]  |= the_bit<<(j&7)
	}
}

__read_bits :: proc "contextless" (dst, src: [^]byte, offset: uintptr, size: uintptr) {
	for j in 0..<size {
		i := offset+j
		the_bit := byte((src[i>>3]) & (1<<(i&7)) != 0)
		dst[j>>3] &~=       1<<(j&7)
		dst[j>>3]  |= the_bit<<(j&7)
	}
}
