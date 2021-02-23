package runtime

bswap_16 :: proc "none" (x: u16) -> u16 {
	return x>>8 | x<<8;
}

bswap_32 :: proc "none" (x: u32) -> u32 {
	return x>>24 | (x>>8)&0xff00 | (x<<8)&0xff0000 | x<<24;
}

bswap_64 :: proc "none" (x: u64) -> u64 {
	return u64(bswap_32(u32(x))) | u64(bswap_32(u32(x>>32)));
}

bswap_128 :: proc "none" (x: u128) -> u128 {
	return u128(bswap_64(u64(x))) | u128(bswap_64(u64(x>>64)));
}


bswap_f32 :: proc "none" (f: f32) -> f32 {
	x := transmute(u32)f;
	z := x>>24 | (x>>8)&0xff00 | (x<<8)&0xff0000 | x<<24;
	return transmute(f32)z;

}

bswap_f64 :: proc "none" (f: f64) -> f64 {
	x := transmute(u64)f;
	z := u64(bswap_32(u32(x))) | u64(bswap_32(u32(x>>32)));
	return transmute(f64)z;
}



ptr_offset :: #force_inline proc "contextless" (ptr: $P/^$T, n: int) -> P {
	new := int(uintptr(ptr)) + size_of(T)*n;
	return P(uintptr(new));
}

is_power_of_two_int :: #force_inline proc(x: int) -> bool {
	if x <= 0 {
		return false;
	}
	return (x & (x-1)) == 0;
}

align_forward_int :: #force_inline proc(ptr, align: int) -> int {
	assert(is_power_of_two_int(align));

	p := ptr;
	modulo := p & (align-1);
	if modulo != 0 {
		p += align - modulo;
	}
	return p;
}

is_power_of_two_uintptr :: #force_inline proc(x: uintptr) -> bool {
	if x <= 0 {
		return false;
	}
	return (x & (x-1)) == 0;
}

align_forward_uintptr :: #force_inline proc(ptr, align: uintptr) -> uintptr {
	assert(is_power_of_two_uintptr(align));

	p := ptr;
	modulo := p & (align-1);
	if modulo != 0 {
		p += align - modulo;
	}
	return p;
}

mem_zero :: proc "contextless" (data: rawptr, len: int) -> rawptr {
	if data == nil {
		return nil;
	}
	if len < 0 {
		return data;
	}
	memset(data, 0, len);
	return data;
}

mem_copy :: proc "contextless" (dst, src: rawptr, len: int) -> rawptr {
	if src == nil {
		return dst;
	}
	// NOTE(bill): This _must_ be implemented like C's memmove
	foreign _ {
		when ODIN_USE_LLVM_API {
			when size_of(rawptr) == 8 {
				@(link_name="llvm.memmove.p0i8.p0i8.i64")
				llvm_memmove :: proc "none" (dst, src: rawptr, len: int, is_volatile: bool = false) ---;
			} else {
				@(link_name="llvm.memmove.p0i8.p0i8.i32")
				llvm_memmove :: proc "none" (dst, src: rawptr, len: int, is_volatile: bool = false) ---;
			}
		} else {
			when size_of(rawptr) == 8 {
				@(link_name="llvm.memmove.p0i8.p0i8.i64")
				llvm_memmove :: proc "none" (dst, src: rawptr, len: int, align: i32 = 1, is_volatile: bool = false) ---;
			} else {
				@(link_name="llvm.memmove.p0i8.p0i8.i32")
				llvm_memmove :: proc "none" (dst, src: rawptr, len: int, align: i32 = 1, is_volatile: bool = false) ---;
			}
		}
	}
	llvm_memmove(dst, src, len);
	return dst;
}

mem_copy_non_overlapping :: proc "contextless" (dst, src: rawptr, len: int) -> rawptr {
	if src == nil {
		return dst;
	}
	// NOTE(bill): This _must_ be implemented like C's memcpy
	foreign _ {
		when ODIN_USE_LLVM_API {
			when size_of(rawptr) == 8 {
				@(link_name="llvm.memcpy.p0i8.p0i8.i64")
				llvm_memcpy :: proc "none" (dst, src: rawptr, len: int, is_volatile: bool = false) ---;
			} else {
				@(link_name="llvm.memcpy.p0i8.p0i8.i32")
				llvm_memcpy :: proc "none" (dst, src: rawptr, len: int, is_volatile: bool = false) ---;
			}
		} else {
			when size_of(rawptr) == 8 {
				@(link_name="llvm.memcpy.p0i8.p0i8.i64")
				llvm_memcpy :: proc "none" (dst, src: rawptr, len: int, align: i32 = 1, is_volatile: bool = false) ---;
			} else {
				@(link_name="llvm.memcpy.p0i8.p0i8.i32")
				llvm_memcpy :: proc "none" (dst, src: rawptr, len: int, align: i32 = 1, is_volatile: bool = false) ---;
			}
		}
	}
	llvm_memcpy(dst, src, len);
	return dst;
}

DEFAULT_ALIGNMENT :: 2*align_of(rawptr);

mem_alloc :: #force_inline proc(size: int, alignment: int = DEFAULT_ALIGNMENT, allocator := context.allocator, loc := #caller_location) -> rawptr {
	if size == 0 {
		return nil;
	}
	if allocator.procedure == nil {
		return nil;
	}
	return allocator.procedure(allocator.data, .Alloc, size, alignment, nil, 0, 0, loc);
}

mem_free :: #force_inline proc(ptr: rawptr, allocator := context.allocator, loc := #caller_location) {
	if ptr == nil {
		return;
	}
	if allocator.procedure == nil {
		return;
	}
	allocator.procedure(allocator.data, .Free, 0, 0, ptr, 0, 0, loc);
}

mem_free_all :: #force_inline proc(allocator := context.allocator, loc := #caller_location) {
	if allocator.procedure != nil {
		allocator.procedure(allocator.data, .Free_All, 0, 0, nil, 0, 0, loc);
	}
}

mem_resize :: #force_inline proc(ptr: rawptr, old_size, new_size: int, alignment: int = DEFAULT_ALIGNMENT, allocator := context.allocator, loc := #caller_location) -> rawptr {
	switch {
	case allocator.procedure == nil:
		return nil;
	case new_size == 0:
		allocator.procedure(allocator.data, .Free, 0, 0, ptr, 0, 0, loc);
		return nil;
	case ptr == nil:
		return allocator.procedure(allocator.data, .Alloc, new_size, alignment, nil, 0, 0, loc);
	}
	return allocator.procedure(allocator.data, .Resize, new_size, alignment, ptr, old_size, 0, loc);
}
memory_equal :: proc "contextless" (a, b: rawptr, n: int) -> bool {
	return memory_compare(a, b, n) == 0;
}
memory_compare :: proc "contextless" (a, b: rawptr, n: int) -> int #no_bounds_check {
	switch {
	case a == b:   return 0;
	case a == nil: return -1;
	case b == nil: return +1;
	}

	x := uintptr(a);
	y := uintptr(b);
	n := uintptr(n);

	SU :: size_of(uintptr);
	fast := uintptr(n/SU + 1);
	offset := (fast-1)*SU;
	curr_block := uintptr(0);
	if n < SU {
		fast = 0;
	}

	for /**/; curr_block < fast; curr_block += 1 {
		va := (^uintptr)(x + curr_block * size_of(uintptr))^;
		vb := (^uintptr)(y + curr_block * size_of(uintptr))^;
		if va ~ vb != 0 {
			for pos := curr_block*SU; pos < n; pos += 1 {
				a := (^byte)(x+pos)^;
				b := (^byte)(y+pos)^;
				if a ~ b != 0 {
					return -1 if (int(a) - int(b)) < 0 else +1;
				}
			}
		}
	}

	for /**/; offset < n; offset += 1 {
		a := (^byte)(x+offset)^;
		b := (^byte)(y+offset)^;
		if a ~ b != 0 {
			return -1 if (int(a) - int(b)) < 0 else +1;
		}
	}

	return 0;
}

memory_compare_zero :: proc "contextless" (a: rawptr, n: int) -> int #no_bounds_check {
	x := uintptr(a);
	n := uintptr(n);

	SU :: size_of(uintptr);
	fast := uintptr(n/SU + 1);
	offset := (fast-1)*SU;
	curr_block := uintptr(0);
	if n < SU {
		fast = 0;
	}

	for /**/; curr_block < fast; curr_block += 1 {
		va := (^uintptr)(x + curr_block * size_of(uintptr))^;
		if va ~ 0 != 0 {
			for pos := curr_block*SU; pos < n; pos += 1 {
				a := (^byte)(x+pos)^;
				if a ~ 0 != 0 {
					return -1 if int(a) < 0 else +1;
				}
			}
		}
	}

	for /**/; offset < n; offset += 1 {
		a := (^byte)(x+offset)^;
		if a ~ 0 != 0 {
			return -1 if int(a) < 0 else +1;
		}
	}

	return 0;
}

string_eq :: proc "contextless" (a, b: string) -> bool {
	x := transmute(Raw_String)a;
	y := transmute(Raw_String)b;
	switch {
	case x.len != y.len: return false;
	case x.len == 0:      return true;
	case x.data == y.data:   return true;
	}
	return string_cmp(a, b) == 0;
}

string_cmp :: proc "contextless" (a, b: string) -> int {
	x := transmute(Raw_String)a;
	y := transmute(Raw_String)b;
	return memory_compare(x.data, y.data, min(x.len, y.len));
}

string_ne :: #force_inline proc "contextless" (a, b: string) -> bool { return !string_eq(a, b); }
string_lt :: #force_inline proc "contextless" (a, b: string) -> bool { return string_cmp(a, b) < 0; }
string_gt :: #force_inline proc "contextless" (a, b: string) -> bool { return string_cmp(a, b) > 0; }
string_le :: #force_inline proc "contextless" (a, b: string) -> bool { return string_cmp(a, b) <= 0; }
string_ge :: #force_inline proc "contextless" (a, b: string) -> bool { return string_cmp(a, b) >= 0; }

cstring_len :: proc "contextless" (s: cstring) -> int {
	p0 := uintptr((^byte)(s));
	p := p0;
	for p != 0 && (^byte)(p)^ != 0 {
		p += 1;
	}
	return int(p - p0);
}

cstring_to_string :: proc "contextless" (s: cstring) -> string {
	if s == nil {
		return "";
	}
	ptr := (^byte)(s);
	n := cstring_len(s);
	return transmute(string)Raw_String{ptr, n};
}


complex64_eq :: #force_inline proc "contextless"  (a, b: complex64)  -> bool { return real(a) == real(b) && imag(a) == imag(b); }
complex64_ne :: #force_inline proc "contextless"  (a, b: complex64)  -> bool { return real(a) != real(b) || imag(a) != imag(b); }

complex128_eq :: #force_inline proc "contextless" (a, b: complex128) -> bool { return real(a) == real(b) && imag(a) == imag(b); }
complex128_ne :: #force_inline proc "contextless" (a, b: complex128) -> bool { return real(a) != real(b) || imag(a) != imag(b); }


quaternion128_eq :: #force_inline proc "contextless"  (a, b: quaternion128)  -> bool { return real(a) == real(b) && imag(a) == imag(b) && jmag(a) == jmag(b) && kmag(a) == kmag(b); }
quaternion128_ne :: #force_inline proc "contextless"  (a, b: quaternion128)  -> bool { return real(a) != real(b) || imag(a) != imag(b) || jmag(a) != jmag(b) || kmag(a) != kmag(b); }

quaternion256_eq :: #force_inline proc "contextless" (a, b: quaternion256) -> bool { return real(a) == real(b) && imag(a) == imag(b) && jmag(a) == jmag(b) && kmag(a) == kmag(b); }
quaternion256_ne :: #force_inline proc "contextless" (a, b: quaternion256) -> bool { return real(a) != real(b) || imag(a) != imag(b) || jmag(a) != jmag(b) || kmag(a) != kmag(b); }


string_decode_rune :: #force_inline proc "contextless" (s: string) -> (rune, int) {
	// NOTE(bill): Duplicated here to remove dependency on package unicode/utf8

	@static accept_sizes := [256]u8{
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
	};
	Accept_Range :: struct {lo, hi: u8};

	@static accept_ranges := [5]Accept_Range{
		{0x80, 0xbf},
		{0xa0, 0xbf},
		{0x80, 0x9f},
		{0x90, 0xbf},
		{0x80, 0x8f},
	};

	MASKX :: 0b0011_1111;
	MASK2 :: 0b0001_1111;
	MASK3 :: 0b0000_1111;
	MASK4 :: 0b0000_0111;

	LOCB :: 0b1000_0000;
	HICB :: 0b1011_1111;


	RUNE_ERROR :: '\ufffd';

	n := len(s);
	if n < 1 {
		return RUNE_ERROR, 0;
	}
	s0 := s[0];
	x := accept_sizes[s0];
	if x >= 0xF0 {
		mask := rune(x) << 31 >> 31; // NOTE(bill): Create 0x0000 or 0xffff.
		return rune(s[0])&~mask | RUNE_ERROR&mask, 1;
	}
	sz := x & 7;
	accept := accept_ranges[x>>4];
	if n < int(sz) {
		return RUNE_ERROR, 1;
	}
	b1 := s[1];
	if b1 < accept.lo || accept.hi < b1 {
		return RUNE_ERROR, 1;
	}
	if sz == 2 {
		return rune(s0&MASK2)<<6 | rune(b1&MASKX), 2;
	}
	b2 := s[2];
	if b2 < LOCB || HICB < b2 {
		return RUNE_ERROR, 1;
	}
	if sz == 3 {
		return rune(s0&MASK3)<<12 | rune(b1&MASKX)<<6 | rune(b2&MASKX), 3;
	}
	b3 := s[3];
	if b3 < LOCB || HICB < b3 {
		return RUNE_ERROR, 1;
	}
	return rune(s0&MASK4)<<18 | rune(b1&MASKX)<<12 | rune(b2&MASKX)<<6 | rune(b3&MASKX), 4;
}

@(default_calling_convention = "none")
foreign {
	@(link_name="llvm.sqrt.f32") _sqrt_f32 :: proc(x: f32) -> f32 ---
	@(link_name="llvm.sqrt.f64") _sqrt_f64 :: proc(x: f64) -> f64 ---
}
abs_f32 :: #force_inline proc "contextless" (x: f32) -> f32 {
	foreign {
		@(link_name="llvm.fabs.f32") _abs :: proc "none" (x: f32) -> f32 ---
	}
	return _abs(x);
}
abs_f64 :: #force_inline proc "contextless" (x: f64) -> f64 {
	foreign {
		@(link_name="llvm.fabs.f64") _abs :: proc "none" (x: f64) -> f64 ---
	}
	return _abs(x);
}

min_f32 :: proc(a, b: f32) -> f32 {
	foreign {
		@(link_name="llvm.minnum.f32") _min :: proc "none" (a, b: f32) -> f32 ---
	}
	return _min(a, b);
}
min_f64 :: proc(a, b: f64) -> f64 {
	foreign {
		@(link_name="llvm.minnum.f64") _min :: proc "none" (a, b: f64) -> f64 ---
	}
	return _min(a, b);
}
max_f32 :: proc(a, b: f32) -> f32 {
	foreign {
		@(link_name="llvm.maxnum.f32") _max :: proc "none" (a, b: f32) -> f32 ---
	}
	return _max(a, b);
}
max_f64 :: proc(a, b: f64) -> f64 {
	foreign {
		@(link_name="llvm.maxnum.f64") _max :: proc "none" (a, b: f64) -> f64 ---
	}
	return _max(a, b);
}

abs_complex64 :: #force_inline proc "contextless" (x: complex64) -> f32 {
	r, i := real(x), imag(x);
	return _sqrt_f32(r*r + i*i);
}
abs_complex128 :: #force_inline proc "contextless" (x: complex128) -> f64 {
	r, i := real(x), imag(x);
	return _sqrt_f64(r*r + i*i);
}
abs_quaternion128 :: #force_inline proc "contextless" (x: quaternion128) -> f32 {
	r, i, j, k := real(x), imag(x), jmag(x), kmag(x);
	return _sqrt_f32(r*r + i*i + j*j + k*k);
}
abs_quaternion256 :: #force_inline proc "contextless" (x: quaternion256) -> f64 {
	r, i, j, k := real(x), imag(x), jmag(x), kmag(x);
	return _sqrt_f64(r*r + i*i + j*j + k*k);
}

quo_complex64 :: proc "contextless" (n, m: complex64) -> complex64 {
	e, f: f32;

	if abs(real(m)) >= abs(imag(m)) {
		ratio := imag(m) / real(m);
		denom := real(m) + ratio*imag(m);
		e = (real(n) + imag(n)*ratio) / denom;
		f = (imag(n) - real(n)*ratio) / denom;
	} else {
		ratio := real(m) / imag(m);
		denom := imag(m) + ratio*real(m);
		e = (real(n)*ratio + imag(n)) / denom;
		f = (imag(n)*ratio - real(n)) / denom;
	}

	return complex(e, f);
}

quo_complex128 :: proc "contextless" (n, m: complex128) -> complex128 {
	e, f: f64;

	if abs(real(m)) >= abs(imag(m)) {
		ratio := imag(m) / real(m);
		denom := real(m) + ratio*imag(m);
		e = (real(n) + imag(n)*ratio) / denom;
		f = (imag(n) - real(n)*ratio) / denom;
	} else {
		ratio := real(m) / imag(m);
		denom := imag(m) + ratio*real(m);
		e = (real(n)*ratio + imag(n)) / denom;
		f = (imag(n)*ratio - real(n)) / denom;
	}

	return complex(e, f);
}

mul_quaternion128 :: proc "contextless" (q, r: quaternion128) -> quaternion128 {
	q0, q1, q2, q3 := real(q), imag(q), jmag(q), kmag(q);
	r0, r1, r2, r3 := real(r), imag(r), jmag(r), kmag(r);

	t0 := r0*q0 - r1*q1 - r2*q2 - r3*q3;
	t1 := r0*q1 + r1*q0 - r2*q3 + r3*q2;
	t2 := r0*q2 + r1*q3 + r2*q0 - r3*q1;
	t3 := r0*q3 - r1*q2 + r2*q1 + r3*q0;

	return quaternion(t0, t1, t2, t3);
}

mul_quaternion256 :: proc "contextless" (q, r: quaternion256) -> quaternion256 {
	q0, q1, q2, q3 := real(q), imag(q), jmag(q), kmag(q);
	r0, r1, r2, r3 := real(r), imag(r), jmag(r), kmag(r);

	t0 := r0*q0 - r1*q1 - r2*q2 - r3*q3;
	t1 := r0*q1 + r1*q0 - r2*q3 + r3*q2;
	t2 := r0*q2 + r1*q3 + r2*q0 - r3*q1;
	t3 := r0*q3 - r1*q2 + r2*q1 + r3*q0;

	return quaternion(t0, t1, t2, t3);
}

quo_quaternion128 :: proc "contextless" (q, r: quaternion128) -> quaternion128 {
	q0, q1, q2, q3 := real(q), imag(q), jmag(q), kmag(q);
	r0, r1, r2, r3 := real(r), imag(r), jmag(r), kmag(r);

	invmag2 := 1.0 / (r0*r0 + r1*r1 + r2*r2 + r3*r3);

	t0 := (r0*q0 + r1*q1 + r2*q2 + r3*q3) * invmag2;
	t1 := (r0*q1 - r1*q0 - r2*q3 - r3*q2) * invmag2;
	t2 := (r0*q2 - r1*q3 - r2*q0 + r3*q1) * invmag2;
	t3 := (r0*q3 + r1*q2 + r2*q1 - r3*q0) * invmag2;

	return quaternion(t0, t1, t2, t3);
}

quo_quaternion256 :: proc "contextless" (q, r: quaternion256) -> quaternion256 {
	q0, q1, q2, q3 := real(q), imag(q), jmag(q), kmag(q);
	r0, r1, r2, r3 := real(r), imag(r), jmag(r), kmag(r);

	invmag2 := 1.0 / (r0*r0 + r1*r1 + r2*r2 + r3*r3);

	t0 := (r0*q0 + r1*q1 + r2*q2 + r3*q3) * invmag2;
	t1 := (r0*q1 - r1*q0 - r2*q3 - r3*q2) * invmag2;
	t2 := (r0*q2 - r1*q3 - r2*q0 + r3*q1) * invmag2;
	t3 := (r0*q3 + r1*q2 + r2*q1 - r3*q0) * invmag2;

	return quaternion(t0, t1, t2, t3);
}
