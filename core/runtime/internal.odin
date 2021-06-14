package runtime

import "intrinsics"

bswap_16 :: proc "none" (x: u16) -> u16 {
	return x>>8 | x<<8;
}

bswap_32 :: proc "none" (x: u32) -> u32 {
	return x>>24 | (x>>8)&0xff00 | (x<<8)&0xff0000 | x<<24;
}

bswap_64 :: proc "none" (x: u64) -> u64 {
	z := x;
	z = (z & 0x00000000ffffffff) << 32 | (z & 0xffffffff00000000) >> 32;
	z = (z & 0x0000ffff0000ffff) << 16 | (z & 0xffff0000ffff0000) >> 16;
	z = (z & 0x00ff00ff00ff00ff) << 8  | (z & 0xff00ff00ff00ff00) >> 8;
	return z;
}

bswap_128 :: proc "none" (x: u128) -> u128 {
	z := transmute([4]u32)x;
	z[0] = bswap_32(z[3]);
	z[1] = bswap_32(z[2]);
	z[2] = bswap_32(z[1]);
	z[3] = bswap_32(z[0]);
	return transmute(u128)z;
}

bswap_f16 :: proc "none" (f: f16) -> f16 {
	x := transmute(u16)f;
	z := bswap_16(x);
	return transmute(f16)z;

}

bswap_f32 :: proc "none" (f: f32) -> f32 {
	x := transmute(u32)f;
	z := bswap_32(x);
	return transmute(f32)z;

}

bswap_f64 :: proc "none" (f: f64) -> f64 {
	x := transmute(u64)f;
	z := bswap_64(x);
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
	intrinsics.mem_zero(data, len);
	return data;
}

mem_copy :: proc "contextless" (dst, src: rawptr, len: int) -> rawptr {
	if src == nil {
		return dst;
	}

	// NOTE(bill): This _must_ be implemented like C's memmove
	intrinsics.mem_copy(dst, src, len);
	return dst;
}

mem_copy_non_overlapping :: proc "contextless" (dst, src: rawptr, len: int) -> rawptr {
	if src == nil {
		return dst;
	}

	// NOTE(bill): This _must_ be implemented like C's memcpy
	intrinsics.mem_copy_non_overlapping(dst, src, len);
	return dst;
}

DEFAULT_ALIGNMENT :: 2*align_of(rawptr);

mem_alloc_bytes :: #force_inline proc(size: int, alignment: int = DEFAULT_ALIGNMENT, allocator := context.allocator, loc := #caller_location) -> ([]byte, Allocator_Error) {
	if size == 0 {
		return nil, nil;
	}
	if allocator.procedure == nil {
		return nil, nil;
	}
	return allocator.procedure(allocator.data, .Alloc, size, alignment, nil, 0, loc);
}

mem_alloc :: #force_inline proc(size: int, alignment: int = DEFAULT_ALIGNMENT, allocator := context.allocator, loc := #caller_location) -> (rawptr, Allocator_Error) {
	if size == 0 {
		return nil, nil;
	}
	if allocator.procedure == nil {
		return nil, nil;
	}
	data, err := allocator.procedure(allocator.data, .Alloc, size, alignment, nil, 0, loc);
	return raw_data(data), err;
}

mem_free :: #force_inline proc(ptr: rawptr, allocator := context.allocator, loc := #caller_location) -> Allocator_Error {
	if ptr == nil {
		return .None;
	}
	if allocator.procedure == nil {
		return .None;
	}
	_, err := allocator.procedure(allocator.data, .Free, 0, 0, ptr, 0, loc);
	return err;
}

mem_free_all :: #force_inline proc(allocator := context.allocator, loc := #caller_location) -> (err: Allocator_Error) {
	if allocator.procedure != nil {
		_, err = allocator.procedure(allocator.data, .Free_All, 0, 0, nil, 0, loc);
	}
	return;
}

mem_resize :: #force_inline proc(ptr: rawptr, old_size, new_size: int, alignment: int = DEFAULT_ALIGNMENT, allocator := context.allocator, loc := #caller_location) -> (new_ptr: rawptr, err: Allocator_Error) {
	new_data: []byte;
	switch {
	case allocator.procedure == nil:
		return;
	case new_size == 0:
		new_data, err = allocator.procedure(allocator.data, .Free, 0, 0, ptr, 0, loc);
	case ptr == nil:
		new_data, err = allocator.procedure(allocator.data, .Alloc, new_size, alignment, nil, 0, loc);
	case:
		new_data, err = allocator.procedure(allocator.data, .Resize, new_size, alignment, ptr, old_size, loc);
	}
	new_ptr = raw_data(new_data);
	return;
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
	fast := n/SU + 1;
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
	fast := n/SU + 1;
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


complex32_eq :: #force_inline proc "contextless"  (a, b: complex32)  -> bool { return real(a) == real(b) && imag(a) == imag(b); }
complex32_ne :: #force_inline proc "contextless"  (a, b: complex32)  -> bool { return real(a) != real(b) || imag(a) != imag(b); }

complex64_eq :: #force_inline proc "contextless"  (a, b: complex64)  -> bool { return real(a) == real(b) && imag(a) == imag(b); }
complex64_ne :: #force_inline proc "contextless"  (a, b: complex64)  -> bool { return real(a) != real(b) || imag(a) != imag(b); }

complex128_eq :: #force_inline proc "contextless" (a, b: complex128) -> bool { return real(a) == real(b) && imag(a) == imag(b); }
complex128_ne :: #force_inline proc "contextless" (a, b: complex128) -> bool { return real(a) != real(b) || imag(a) != imag(b); }


quaternion64_eq :: #force_inline proc "contextless"  (a, b: quaternion64)  -> bool { return real(a) == real(b) && imag(a) == imag(b) && jmag(a) == jmag(b) && kmag(a) == kmag(b); }
quaternion64_ne :: #force_inline proc "contextless"  (a, b: quaternion64)  -> bool { return real(a) != real(b) || imag(a) != imag(b) || jmag(a) != jmag(b) || kmag(a) != kmag(b); }

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

abs_f16 :: #force_inline proc "contextless" (x: f16) -> f16 {
	return -x if x < 0 else x;
}
abs_f32 :: #force_inline proc "contextless" (x: f32) -> f32 {
	return -x if x < 0 else x;
}
abs_f64 :: #force_inline proc "contextless" (x: f64) -> f64 {
	return -x if x < 0 else x;
}

min_f16 :: #force_inline proc "contextless" (a, b: f16) -> f16 {
	return a if a < b else b;
}
min_f32 :: #force_inline proc "contextless" (a, b: f32) -> f32 {
	return a if a < b else b;
}
min_f64 :: #force_inline proc "contextless" (a, b: f64) -> f64 {
	return a if a < b else b;
}
max_f16 :: #force_inline proc "contextless" (a, b: f16) -> f16 {
	return a if a > b else b;
}
max_f32 :: #force_inline proc "contextless" (a, b: f32) -> f32 {
	return a if a > b else b;
}
max_f64 :: #force_inline proc "contextless" (a, b: f64) -> f64 {
	return a if a > b else b;
}

abs_complex32 :: #force_inline proc "contextless" (x: complex32) -> f16 {
	r, i := real(x), imag(x);
	return f16(intrinsics.sqrt(f32(r*r + i*i)));
}
abs_complex64 :: #force_inline proc "contextless" (x: complex64) -> f32 {
	r, i := real(x), imag(x);
	return intrinsics.sqrt(r*r + i*i);
}
abs_complex128 :: #force_inline proc "contextless" (x: complex128) -> f64 {
	r, i := real(x), imag(x);
	return intrinsics.sqrt(r*r + i*i);
}
abs_quaternion64 :: #force_inline proc "contextless" (x: quaternion64) -> f16 {
	r, i, j, k := real(x), imag(x), jmag(x), kmag(x);
	return f16(intrinsics.sqrt(f32(r*r + i*i + j*j + k*k)));
}
abs_quaternion128 :: #force_inline proc "contextless" (x: quaternion128) -> f32 {
	r, i, j, k := real(x), imag(x), jmag(x), kmag(x);
	return intrinsics.sqrt(r*r + i*i + j*j + k*k);
}
abs_quaternion256 :: #force_inline proc "contextless" (x: quaternion256) -> f64 {
	r, i, j, k := real(x), imag(x), jmag(x), kmag(x);
	return intrinsics.sqrt(r*r + i*i + j*j + k*k);
}


quo_complex32 :: proc "contextless" (n, m: complex32) -> complex32 {
	e, f: f16;

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

mul_quaternion64 :: proc "contextless" (q, r: quaternion64) -> quaternion64 {
	q0, q1, q2, q3 := real(q), imag(q), jmag(q), kmag(q);
	r0, r1, r2, r3 := real(r), imag(r), jmag(r), kmag(r);

	t0 := r0*q0 - r1*q1 - r2*q2 - r3*q3;
	t1 := r0*q1 + r1*q0 - r2*q3 + r3*q2;
	t2 := r0*q2 + r1*q3 + r2*q0 - r3*q1;
	t3 := r0*q3 - r1*q2 + r2*q1 + r3*q0;

	return quaternion(t0, t1, t2, t3);
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

quo_quaternion64 :: proc "contextless" (q, r: quaternion64) -> quaternion64 {
	q0, q1, q2, q3 := real(q), imag(q), jmag(q), kmag(q);
	r0, r1, r2, r3 := real(r), imag(r), jmag(r), kmag(r);

	invmag2 := 1.0 / (r0*r0 + r1*r1 + r2*r2 + r3*r3);

	t0 := (r0*q0 + r1*q1 + r2*q2 + r3*q3) * invmag2;
	t1 := (r0*q1 - r1*q0 - r2*q3 - r3*q2) * invmag2;
	t2 := (r0*q2 - r1*q3 - r2*q0 + r3*q1) * invmag2;
	t3 := (r0*q3 + r1*q2 + r2*q1 - r3*q0) * invmag2;

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

@(link_name="__truncsfhf2")
truncsfhf2 :: proc "c" (value: f32) -> u16 {
	v: struct #raw_union { i: u32, f: f32 };
	i, s, e, m: i32;

	v.f = value;
	i = i32(v.i);

	s =  (i >> 16) & 0x00008000;
	e = ((i >> 23) & 0x000000ff) - (127 - 15);
	m =   i        & 0x007fffff;


	if e <= 0 {
		if e < -10 {
			return u16(s);
		}
		m = (m | 0x00800000) >> u32(1 - e);

		if m & 0x00001000 != 0 {
			m += 0x00002000;
		}

		return u16(s | (m >> 13));
	} else if e == 0xff - (127 - 15) {
		if m == 0 {
			return u16(s | 0x7c00); /* NOTE(bill): infinity */
		} else {
			/* NOTE(bill): NAN */
			m >>= 13;
			return u16(s | 0x7c00 | m | i32(m == 0));
		}
	} else {
		if m & 0x00001000 != 0 {
			m += 0x00002000;
			if (m & 0x00800000) != 0 {
				m = 0;
				e += 1;
			}
		}

		if e > 30 {
			f := i64(1e12);
			for j := 0; j < 10; j += 1 {
				/* NOTE(bill): Cause overflow */
				g := intrinsics.volatile_load(&f);
				g *= g;
				intrinsics.volatile_store(&f, g);
			}

			return u16(s | 0x7c00);
		}

		return u16(s | (e << 10) | (m >> 13));
	}
}


@(link_name="__truncdfhf2")
truncdfhf2 :: proc "c" (value: f64) -> u16 {
	return truncsfhf2(f32(value));
}

@(link_name="__gnu_h2f_ieee")
gnu_h2f_ieee :: proc "c" (value: u16) -> f32 {
	fp32 :: struct #raw_union { u: u32, f: f32 };

	v: fp32;
	magic, inf_or_nan: fp32;
	magic.u = u32((254 - 15) << 23);
	inf_or_nan.u = u32((127 + 16) << 23);

	v.u = u32(value & 0x7fff) << 13;
	v.f *= magic.f;
	if v.f >= inf_or_nan.f {
		v.u |= 255 << 23;
	}
	v.u |= u32(value & 0x8000) << 16;
	return v.f;
}


@(link_name="__gnu_f2h_ieee")
gnu_f2h_ieee :: proc "c" (value: f32) -> u16 {
	return truncsfhf2(value);
}

@(link_name="__extendhfsf2")
extendhfsf2 :: proc "c" (value: u16) -> f32 {
	return gnu_h2f_ieee(value);
}



@(link_name="__floattidf")
floattidf :: proc(a: i128) -> f64 {
	DBL_MANT_DIG :: 53;
	if a == 0 {
		return 0.0;
	}
	a := a;
	N :: size_of(i128) * 8;
	s := a >> (N-1);
	a = (a ~ s) - s;
	sd: = N - intrinsics.count_leading_zeros(a);  // number of significant digits
	e := u32(sd - 1);        // exponent
	if sd > DBL_MANT_DIG {
		switch sd {
		case DBL_MANT_DIG + 1:
			a <<= 1;
		case DBL_MANT_DIG + 2:
			// okay
		case:
			a = i128(u128(a) >> u128(sd - (DBL_MANT_DIG+2))) |
				i128(u128(a) & (~u128(0) >> u128(N + DBL_MANT_DIG+2 - sd)) != 0);
		};

		a |= i128((a & 4) != 0);
		a += 1;
		a >>= 2;

		if a & (1 << DBL_MANT_DIG) != 0 {
			a >>= 1;
			e += 1;
		}
	} else {
		a <<= u128(DBL_MANT_DIG - sd);
	}
	fb: [2]u32;
	fb[1] = (u32(s) & 0x80000000) |           // sign
	        ((e + 1023) << 20)    |           // exponent
	        u32((u64(a) >> 32) & 0x000FFFFF); // mantissa-high
	fb[1] = u32(a);                           // mantissa-low
	return transmute(f64)fb;
}


@(link_name="__floattidf_unsigned")
floattidf_unsigned :: proc(a: u128) -> f64 {
	DBL_MANT_DIG :: 53;
	if a == 0 {
		return 0.0;
	}
	a := a;
	N :: size_of(u128) * 8;
	sd: = N - intrinsics.count_leading_zeros(a);  // number of significant digits
	e := u32(sd - 1);        // exponent
	if sd > DBL_MANT_DIG {
		switch sd {
		case DBL_MANT_DIG + 1:
			a <<= 1;
		case DBL_MANT_DIG + 2:
			// okay
		case:
			a = u128(u128(a) >> u128(sd - (DBL_MANT_DIG+2))) |
				u128(u128(a) & (~u128(0) >> u128(N + DBL_MANT_DIG+2 - sd)) != 0);
		};

		a |= u128((a & 4) != 0);
		a += 1;
		a >>= 2;

		if a & (1 << DBL_MANT_DIG) != 0 {
			a >>= 1;
			e += 1;
		}
	} else {
		a <<= u128(DBL_MANT_DIG - sd);
	}
	fb: [2]u32;
	fb[1] = (0) |                             // sign
	        ((e + 1023) << 20) |              // exponent
	        u32((u64(a) >> 32) & 0x000FFFFF); // mantissa-high
	fb[1] = u32(a);                           // mantissa-low
	return transmute(f64)fb;
}
