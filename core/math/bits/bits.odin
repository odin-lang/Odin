package math_bits

import "core:runtime"

U8_MIN  :: 0;
U16_MIN :: 0;
U32_MIN :: 0;
U64_MIN :: 0;

U8_MAX  :: 1 <<  8 - 1;
U16_MAX :: 1 << 16 - 1;
U32_MAX :: 1 << 32 - 1;
U64_MAX :: 1 << 64 - 1;

I8_MIN  :: - 1 << 7;
I16_MIN :: - 1 << 15;
I32_MIN :: - 1 << 31;
I64_MIN :: - 1 << 63;

I8_MAX  :: 1 <<  7 - 1;
I16_MAX :: 1 << 15 - 1;
I32_MAX :: 1 << 31 - 1;
I64_MAX :: 1 << 63 - 1;

@(default_calling_convention="none")
foreign {
	@(link_name="llvm.ctpop.i8")        count_ones8  :: proc(i:  u8) ->  u8 ---
	@(link_name="llvm.ctpop.i16")       count_ones16 :: proc(i: u16) -> u16 ---
	@(link_name="llvm.ctpop.i32")       count_ones32 :: proc(i: u32) -> u32 ---
	@(link_name="llvm.ctpop.i64")       count_ones64 :: proc(i: u64) -> u64 ---

	@(link_name="llvm.cttz.i8")         trailing_zeros8  :: proc(i:  u8,  is_zero_undef := false) ->  u8 ---
	@(link_name="llvm.cttz.i16")        trailing_zeros16 :: proc(i: u16,  is_zero_undef := false) -> u16 ---
	@(link_name="llvm.cttz.i32")        trailing_zeros32 :: proc(i: u32,  is_zero_undef := false) -> u32 ---
	@(link_name="llvm.cttz.i64")        trailing_zeros64 :: proc(i: u64,  is_zero_undef := false) -> u64 ---

	@(link_name="llvm.bitreverse.i8")   reverse_bits8  :: proc(i:  u8) ->  u8 ---
	@(link_name="llvm.bitreverse.i16")  reverse_bits16 :: proc(i: u16) -> u16 ---
	@(link_name="llvm.bitreverse.i32")  reverse_bits32 :: proc(i: u32) -> u32 ---
	@(link_name="llvm.bitreverse.i64")  reverse_bits64 :: proc(i: u64) -> u64 ---
}


trailing_zeros_uint :: proc(i: uint) -> uint {
	when size_of(uint) == size_of(u64) {
		return uint(trailing_zeros64(u64(i)));
	} else {
		return uint(trailing_zeros32(u32(i)));
	}
}


leading_zeros_u8  :: proc(i:  u8) -> int {
	return 8*size_of(i) - len_u8(i);
}
leading_zeros_u16 :: proc(i: u16) -> int {
	return 8*size_of(i) - len_u16(i);
}
leading_zeros_u32 :: proc(i: u32) -> int {
	return 8*size_of(i) - len_u32(i);
}
leading_zeros_u64 :: proc(i: u64) -> int {
	return 8*size_of(i) - len_u64(i);
}


byte_swap_u16 :: proc(x: u16) -> u16 {
	return u16(runtime.bswap_16(u16(x)));
}
byte_swap_u32 :: proc(x: u32) -> u32 {
	return u32(runtime.bswap_32(u32(x)));
}
byte_swap_u64 :: proc(x: u64) -> u64 {
	return u64(runtime.bswap_64(u64(x)));
}
byte_swap_i16 :: proc(x: i16) -> i16 {
	return i16(runtime.bswap_16(u16(x)));
}
byte_swap_i32 :: proc(x: i32) -> i32 {
	return i32(runtime.bswap_32(u32(x)));
}
byte_swap_i64 :: proc(x: i64) -> i64 {
	return i64(runtime.bswap_64(u64(x)));
}
byte_swap_u128 :: proc(x: u128) -> u128 {
	return u128(runtime.bswap_128(u128(x)));
}
byte_swap_i128 :: proc(x: i128) -> i128 {
	return i128(runtime.bswap_128(u128(x)));
}

byte_swap_uint :: proc(i: uint) -> uint {
	when size_of(uint) == size_of(u32) {
		return uint(byte_swap_u32(u32(i)));
	} else {
		return uint(byte_swap_u64(u64(i)));
	}
}
byte_swap_int :: proc(i: int) -> int {
	when size_of(int) == size_of(i32) {
		return int(byte_swap_i32(i32(i)));
	} else {
		return int(byte_swap_i64(i64(i)));
	}
}

byte_swap :: proc{
	byte_swap_u16,
	byte_swap_u32,
	byte_swap_u64,
	byte_swap_u128,
	byte_swap_i16,
	byte_swap_i32,
	byte_swap_i64,
	byte_swap_i128,
	byte_swap_uint,
	byte_swap_int,
};

count_zeros8   :: proc(i:   u8) ->   u8 { return   8 - count_ones8(i); }
count_zeros16  :: proc(i:  u16) ->  u16 { return  16 - count_ones16(i); }
count_zeros32  :: proc(i:  u32) ->  u32 { return  32 - count_ones32(i); }
count_zeros64  :: proc(i:  u64) ->  u64 { return  64 - count_ones64(i); }


rotate_left8 :: proc(x: u8,  k: int) -> u8 {
	n :: 8;
	s := uint(k) & (n-1);
	return x <<s | x>>(n-s);
}
rotate_left16 :: proc(x: u16, k: int) -> u16 {
	n :: 16;
	s := uint(k) & (n-1);
	return x <<s | x>>(n-s);
}
rotate_left32 :: proc(x: u32, k: int) -> u32 {
	n :: 32;
	s := uint(k) & (n-1);
	return x <<s | x>>(n-s);
}
rotate_left64 :: proc(x: u64, k: int) -> u64 {
	n :: 64;
	s := uint(k) & (n-1);
	return x <<s | x>>(n-s);
}

rotate_left :: proc(x: uint, k: int) -> uint {
	n :: 8*size_of(uint);
	s := uint(k) & (n-1);
	return x <<s | x>>(n-s);
}

from_be_u8   :: proc(i:   u8) ->   u8 { return i; }
from_be_u16  :: proc(i:  u16) ->  u16 { when ODIN_ENDIAN == "big" { return i; } else { return byte_swap(i); } }
from_be_u32  :: proc(i:  u32) ->  u32 { when ODIN_ENDIAN == "big" { return i; } else { return byte_swap(i); } }
from_be_u64  :: proc(i:  u64) ->  u64 { when ODIN_ENDIAN == "big" { return i; } else { return byte_swap(i); } }
from_be_uint :: proc(i: uint) -> uint { when ODIN_ENDIAN == "big" { return i; } else { return byte_swap(i); } }

from_le_u8   :: proc(i:   u8) ->   u8 { return i; }
from_le_u16  :: proc(i:  u16) ->  u16 { when ODIN_ENDIAN == "little" { return i; } else { return byte_swap(i); } }
from_le_u32  :: proc(i:  u32) ->  u32 { when ODIN_ENDIAN == "little" { return i; } else { return byte_swap(i); } }
from_le_u64  :: proc(i:  u64) ->  u64 { when ODIN_ENDIAN == "little" { return i; } else { return byte_swap(i); } }
from_le_uint :: proc(i: uint) -> uint { when ODIN_ENDIAN == "little" { return i; } else { return byte_swap(i); } }

to_be_u8   :: proc(i:   u8) ->   u8 { return i; }
to_be_u16  :: proc(i:  u16) ->  u16 { when ODIN_ENDIAN == "big" { return i; } else { return byte_swap(i); } }
to_be_u32  :: proc(i:  u32) ->  u32 { when ODIN_ENDIAN == "big" { return i; } else { return byte_swap(i); } }
to_be_u64  :: proc(i:  u64) ->  u64 { when ODIN_ENDIAN == "big" { return i; } else { return byte_swap(i); } }
to_be_uint :: proc(i: uint) -> uint { when ODIN_ENDIAN == "big" { return i; } else { return byte_swap(i); } }


to_le_u8   :: proc(i:   u8) ->   u8 { return i; }
to_le_u16  :: proc(i:  u16) ->  u16 { when ODIN_ENDIAN == "little" { return i; } else { return byte_swap(i); } }
to_le_u32  :: proc(i:  u32) ->  u32 { when ODIN_ENDIAN == "little" { return i; } else { return byte_swap(i); } }
to_le_u64  :: proc(i:  u64) ->  u64 { when ODIN_ENDIAN == "little" { return i; } else { return byte_swap(i); } }
to_le_uint :: proc(i: uint) -> uint { when ODIN_ENDIAN == "little" { return i; } else { return byte_swap(i); } }


@(default_calling_convention="none")
foreign {
	@(link_name="llvm.uadd.with.overflow.i8")  overflowing_add_u8  :: proc(lhs, rhs:  u8) -> (u8, bool)  ---
	@(link_name="llvm.sadd.with.overflow.i8")  overflowing_add_i8  :: proc(lhs, rhs:  i8) -> (i8, bool)  ---
	@(link_name="llvm.uadd.with.overflow.i16") overflowing_add_u16 :: proc(lhs, rhs: u16) -> (u16, bool) ---
	@(link_name="llvm.sadd.with.overflow.i16") overflowing_add_i16 :: proc(lhs, rhs: i16) -> (i16, bool) ---
	@(link_name="llvm.uadd.with.overflow.i32") overflowing_add_u32 :: proc(lhs, rhs: u32) -> (u32, bool) ---
	@(link_name="llvm.sadd.with.overflow.i32") overflowing_add_i32 :: proc(lhs, rhs: i32) -> (i32, bool) ---
	@(link_name="llvm.uadd.with.overflow.i64") overflowing_add_u64 :: proc(lhs, rhs: u64) -> (u64, bool) ---
	@(link_name="llvm.sadd.with.overflow.i64") overflowing_add_i64 :: proc(lhs, rhs: i64) -> (i64, bool) ---
}

overflowing_add_uint :: proc(lhs, rhs: uint) -> (uint, bool) {
	when size_of(uint) == size_of(u32) {
		x, ok := overflowing_add_u32(u32(lhs), u32(rhs));
		return uint(x), ok;
	} else {
		x, ok := overflowing_add_u64(u64(lhs), u64(rhs));
		return uint(x), ok;
	}
}
overflowing_add_int :: proc(lhs, rhs: int) -> (int, bool) {
	when size_of(int) == size_of(i32) {
		x, ok := overflowing_add_i32(i32(lhs), i32(rhs));
		return int(x), ok;
	} else {
		x, ok := overflowing_add_i64(i64(lhs), i64(rhs));
		return int(x), ok;
	}
}

overflowing_add :: proc{
	overflowing_add_u8,   overflowing_add_i8,
	overflowing_add_u16,  overflowing_add_i16,
	overflowing_add_u32,  overflowing_add_i32,
	overflowing_add_u64,  overflowing_add_i64,
	overflowing_add_uint, overflowing_add_int,
};

@(default_calling_convention="none")
foreign {
	@(link_name="llvm.usub.with.overflow.i8")  overflowing_sub_u8  :: proc(lhs, rhs:  u8) -> (u8, bool)  ---
	@(link_name="llvm.ssub.with.overflow.i8")  overflowing_sub_i8  :: proc(lhs, rhs:  i8) -> (i8, bool)  ---
	@(link_name="llvm.usub.with.overflow.i16") overflowing_sub_u16 :: proc(lhs, rhs: u16) -> (u16, bool) ---
	@(link_name="llvm.ssub.with.overflow.i16") overflowing_sub_i16 :: proc(lhs, rhs: i16) -> (i16, bool) ---
	@(link_name="llvm.usub.with.overflow.i32") overflowing_sub_u32 :: proc(lhs, rhs: u32) -> (u32, bool) ---
	@(link_name="llvm.ssub.with.overflow.i32") overflowing_sub_i32 :: proc(lhs, rhs: i32) -> (i32, bool) ---
	@(link_name="llvm.usub.with.overflow.i64") overflowing_sub_u64 :: proc(lhs, rhs: u64) -> (u64, bool) ---
	@(link_name="llvm.ssub.with.overflow.i64") overflowing_sub_i64 :: proc(lhs, rhs: i64) -> (i64, bool) ---
}
overflowing_sub_uint :: proc(lhs, rhs: uint) -> (uint, bool) {
	when size_of(uint) == size_of(u32) {
		x, ok := overflowing_sub_u32(u32(lhs), u32(rhs));
		return uint(x), ok;
	} else {
		x, ok := overflowing_sub_u64(u64(lhs), u64(rhs));
		return uint(x), ok;
	}
}
overflowing_sub_int :: proc(lhs, rhs: int) -> (int, bool) {
	when size_of(int) == size_of(i32) {
		x, ok := overflowing_sub_i32(i32(lhs), i32(rhs));
		return int(x), ok;
	} else {
		x, ok := overflowing_sub_i64(i64(lhs), i64(rhs));
		return int(x), ok;
	}
}

overflowing_sub :: proc{
	overflowing_sub_u8,   overflowing_sub_i8,
	overflowing_sub_u16,  overflowing_sub_i16,
	overflowing_sub_u32,  overflowing_sub_i32,
	overflowing_sub_u64,  overflowing_sub_i64,
	overflowing_sub_uint, overflowing_sub_int,
};

@(default_calling_convention="none")
foreign {
	@(link_name="llvm.umul.with.overflow.i8")  overflowing_mul_u8  :: proc(lhs, rhs:  u8) -> (u8, bool)  ---
	@(link_name="llvm.smul.with.overflow.i8")  overflowing_mul_i8  :: proc(lhs, rhs:  i8) -> (i8, bool)  ---
	@(link_name="llvm.umul.with.overflow.i16") overflowing_mul_u16 :: proc(lhs, rhs: u16) -> (u16, bool) ---
	@(link_name="llvm.smul.with.overflow.i16") overflowing_mul_i16 :: proc(lhs, rhs: i16) -> (i16, bool) ---
	@(link_name="llvm.umul.with.overflow.i32") overflowing_mul_u32 :: proc(lhs, rhs: u32) -> (u32, bool) ---
	@(link_name="llvm.smul.with.overflow.i32") overflowing_mul_i32 :: proc(lhs, rhs: i32) -> (i32, bool) ---
	@(link_name="llvm.umul.with.overflow.i64") overflowing_mul_u64 :: proc(lhs, rhs: u64) -> (u64, bool) ---
	@(link_name="llvm.smul.with.overflow.i64") overflowing_mul_i64 :: proc(lhs, rhs: i64) -> (i64, bool) ---
}
overflowing_mul_uint :: proc(lhs, rhs: uint) -> (uint, bool) {
	when size_of(uint) == size_of(u32) {
		x, ok := overflowing_mul_u32(u32(lhs), u32(rhs));
		return uint(x), ok;
	} else {
		x, ok := overflowing_mul_u64(u64(lhs), u64(rhs));
		return uint(x), ok;
	}
}
overflowing_mul_int :: proc(lhs, rhs: int) -> (int, bool) {
	when size_of(int) == size_of(i32) {
		x, ok := overflowing_mul_i32(i32(lhs), i32(rhs));
		return int(x), ok;
	} else {
		x, ok := overflowing_mul_i64(i64(lhs), i64(rhs));
		return int(x), ok;
	}
}

overflowing_mul :: proc{
	overflowing_mul_u8,   overflowing_mul_i8,
	overflowing_mul_u16,  overflowing_mul_i16,
	overflowing_mul_u32,  overflowing_mul_i32,
	overflowing_mul_u64,  overflowing_mul_i64,
	overflowing_mul_uint, overflowing_mul_int,
};


len_u8 :: proc(x: u8) -> int {
	return int(len_u8_table[x]);
}
len_u16 :: proc(x: u16) -> (n: int) {
	x := x;
	if x >= 1<<8 {
		x >>= 8;
		n = 8;
	}
	return n + int(len_u8_table[x]);
}
len_u32 :: proc(x: u32) -> (n: int) {
	x := x;
	if x >= 1<<16 {
		x >>= 16;
		n = 16;
	}
	if x >= 1<<8 {
		x >>= 8;
		n += 8;
	}
	return n + int(len_u8_table[x]);
}
len_u64 :: proc(x: u64) -> (n: int) {
	x := x;
	if x >= 1<<32 {
		x >>= 32;
		n = 32;
	}
	if x >= 1<<16 {
		x >>= 16;
		n += 16;
	}
	if x >= 1<<8 {
		x >>= 8;
		n += 8;
	}
	return n + int(len_u8_table[x]);
}
len_uint :: proc(x: uint) -> (n: int) {
	when size_of(uint) == size_of(u64) {
		return len_u64(u64(x));
	} else {
		return len_u32(u32(x));
	}
}

// returns the minimum number of bits required to represent x
len :: proc{len_u8, len_u16, len_u32, len_u64, len_uint};


add_u32 :: proc(x, y, carry: u32) -> (sum, carry_out: u32) {
	yc := y + carry;
	sum = x + yc;
	if sum < x || yc < y {
		carry_out = 1;
	}
	return;
}
add_u64 :: proc(x, y, carry: u64) -> (sum, carry_out: u64) {
	yc := y + carry;
	sum = x + yc;
	if sum < x || yc < y {
		carry_out = 1;
	}
	return;
}
add_uint :: proc(x, y, carry: uint) -> (sum, carry_out: uint) {
	yc := y + carry;
	sum = x + yc;
	if sum < x || yc < y {
		carry_out = 1;
	}
	return;
}
add :: proc{add_u32, add_u64, add_uint};


sub_u32 :: proc(x, y, borrow: u32) -> (diff, borrow_out: u32) {
	yb := y + borrow;
	diff = x - yb;
	if diff > x || yb < y {
		borrow_out = 1;
	}
	return;
}
sub_u64 :: proc(x, y, borrow: u64) -> (diff, borrow_out: u64) {
	yb := y + borrow;
	diff = x - yb;
	if diff > x || yb < y {
		borrow_out = 1;
	}
	return;
}
sub_uint :: proc(x, y, borrow: uint) -> (diff, borrow_out: uint) {
	yb := y + borrow;
	diff = x - yb;
	if diff > x || yb < y {
		borrow_out = 1;
	}
	return;
}
sub :: proc{sub_u32, sub_u64, sub_uint};


mul_u32 :: proc(x, y: u32) -> (hi, lo: u32) {
	z := u64(x) * u64(y);
	hi, lo = u32(z>>32), u32(z);
	return;
}
mul_u64 :: proc(x, y: u64) -> (hi, lo: u64) {
	mask :: 1<<32 - 1;

	x0, x1 := x & mask, x >> 32;
	y0, y1 := y & mask, y >> 32;

	w0 := x0 * y0;
	t := x1*y0 + w0>>32;

	w1, w2 := t & mask, t >> 32;
	w1 += x0 * y1;
	hi = x1*y1 + w2 + w1>>32;
	lo = x * y;
	return;
}

mul_uint :: proc(x, y: uint) -> (hi, lo: uint) {
	when size_of(uint) == size_of(u32) {
		a, b := mul_u32(u32(x), u32(y));
	} else {
		#assert(size_of(uint) == size_of(u64));
		a, b := mul_u64(u64(x), u64(y));
	}
	return uint(a), uint(b);
}

mul :: proc{mul_u32, mul_u64, mul_uint};


div_u32 :: proc(hi, lo, y: u32) -> (quo, rem: u32) {
	assert(y != 0 && y <= hi);
	z := u64(hi)<<32 | u64(lo);
	quo, rem = u32(z/u64(y)), u32(z%u64(y));
	return;
}
div_u64 :: proc(hi, lo, y: u64) -> (quo, rem: u64) {
	y := y;
	two32  :: 1 << 32;
	mask32 :: two32 - 1;
	if y == 0 {
		panic("divide error");
	}
	if y <= hi {
		panic("overflow error");
	}

	s := uint(leading_zeros_u64(y));
	y <<= s;

	yn1 := y >> 32;
	yn0 := y & mask32;
	un32 := hi<<s | lo>>(64-s);
	un10 := lo << s;
	un1 := un10 >> 32;
	un0 := un10 & mask32;
	q1 := un32 / yn1;
	rhat := un32 - q1*yn1;

	for q1 >= two32 || q1*yn0 > two32*rhat+un1 {
		q1 -= 1;
		rhat += yn1;
		if rhat >= two32 {
			break;
		}
	}

	un21 := un32*two32 + un1 - q1*y;
	q0 := un21 / yn1;
	rhat = un21 - q0*yn1;

	for q0 >= two32 || q0*yn0 > two32*rhat+un0 {
		q0 -= 1;
		rhat += yn1;
		if rhat >= two32 {
			break;
		}
	}

	return q1*two32 + q0, (un21*two32 + un0 - q0*y) >> s;
}
div_uint :: proc(hi, lo, y: uint) -> (quo, rem: uint) {
	when size_of(uint) == size_of(u32) {
		a, b := div_u32(u32(hi), u32(lo), u32(y));
	} else {
		#assert(size_of(uint) == size_of(u64));
		a, b := div_u64(u64(hi), u64(lo), u64(y));
	}
	return uint(a), uint(b);
}
div :: proc{div_u32, div_u64, div_uint};



is_power_of_two_u8   :: proc(i:   u8) -> bool { return i > 0 && (i & (i-1)) == 0; }
is_power_of_two_i8   :: proc(i:   i8) -> bool { return i > 0 && (i & (i-1)) == 0; }
is_power_of_two_u16  :: proc(i:  u16) -> bool { return i > 0 && (i & (i-1)) == 0; }
is_power_of_two_i16  :: proc(i:  i16) -> bool { return i > 0 && (i & (i-1)) == 0; }
is_power_of_two_u32  :: proc(i:  u32) -> bool { return i > 0 && (i & (i-1)) == 0; }
is_power_of_two_i32  :: proc(i:  i32) -> bool { return i > 0 && (i & (i-1)) == 0; }
is_power_of_two_u64  :: proc(i:  u64) -> bool { return i > 0 && (i & (i-1)) == 0; }
is_power_of_two_i64  :: proc(i:  i64) -> bool { return i > 0 && (i & (i-1)) == 0; }
is_power_of_two_uint :: proc(i: uint) -> bool { return i > 0 && (i & (i-1)) == 0; }
is_power_of_two_int  :: proc(i:  int) -> bool { return i > 0 && (i & (i-1)) == 0; }

is_power_of_two :: proc{
	is_power_of_two_u8,   is_power_of_two_i8,
	is_power_of_two_u16,  is_power_of_two_i16,
	is_power_of_two_u32,  is_power_of_two_i32,
	is_power_of_two_u64,  is_power_of_two_i64,
	is_power_of_two_uint, is_power_of_two_int,
};


@private
len_u8_table := [256]u8{
	0         = 0,
	1         = 1,
	2..<4     = 2,
	4..<8     = 3,
	8..<16    = 4,
	16..<32   = 5,
	32..<64   = 6,
	64..<128  = 7,
	128..<256 = 8,
};


