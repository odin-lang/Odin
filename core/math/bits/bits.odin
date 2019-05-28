package bits

import "core:os"

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

	@(link_name="llvm.ctlz.i8")         leading_zeros8  :: proc(i:  u8, is_zero_undef := false) ->  u8 ---
	@(link_name="llvm.ctlz.i16")        leading_zeros16 :: proc(i: u16, is_zero_undef := false) -> u16 ---
	@(link_name="llvm.ctlz.i32")        leading_zeros32 :: proc(i: u32, is_zero_undef := false) -> u32 ---
	@(link_name="llvm.ctlz.i64")        leading_zeros64 :: proc(i: u64, is_zero_undef := false) -> u64 ---

	@(link_name="llvm.cttz.i8")         trailing_zeros8  :: proc(i:  u8,  is_zero_undef := false) ->  u8 ---
	@(link_name="llvm.cttz.i16")        trailing_zeros16 :: proc(i: u16,  is_zero_undef := false) -> u16 ---
	@(link_name="llvm.cttz.i32")        trailing_zeros32 :: proc(i: u32,  is_zero_undef := false) -> u32 ---
	@(link_name="llvm.cttz.i64")        trailing_zeros64 :: proc(i: u64,  is_zero_undef := false) -> u64 ---

	@(link_name="llvm.bitreverse.i8")   reverse_bits8  :: proc(i:  u8) ->  u8 ---
	@(link_name="llvm.bitreverse.i16")  reverse_bits16 :: proc(i: u16) -> u16 ---
	@(link_name="llvm.bitreverse.i32")  reverse_bits32 :: proc(i: u32) -> u32 ---
	@(link_name="llvm.bitreverse.i64")  reverse_bits64 :: proc(i: u64) -> u64 ---

	@(link_name="llvm.bswap.i16")       byte_swap_u16 :: proc(u16) -> u16 ---
	@(link_name="llvm.bswap.i32")       byte_swap_u32 :: proc(u32) -> u32 ---
	@(link_name="llvm.bswap.i64")       byte_swap_u64 :: proc(u64) -> u64 ---
	@(link_name="llvm.bswap.i16")       byte_swap_i16 :: proc(i16) -> i16 ---
	@(link_name="llvm.bswap.i32")       byte_swap_i32 :: proc(i32) -> i32 ---
	@(link_name="llvm.bswap.i64")       byte_swap_i64 :: proc(i64) -> i64 ---
	@(link_name="llvm.bswap.i128")      byte_swap_u128 :: proc(u128) -> u128 ---
	@(link_name="llvm.bswap.i128")      byte_swap_i128 :: proc(i128) -> i128 ---
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


rotate_left8   :: proc(i: u8,   s: uint) ->   u8 { return (i << s)|(i >> (8*size_of(u8)   - s)); }
rotate_left16  :: proc(i: u16,  s: uint) ->  u16 { return (i << s)|(i >> (8*size_of(u16)  - s)); }
rotate_left32  :: proc(i: u32,  s: uint) ->  u32 { return (i << s)|(i >> (8*size_of(u32)  - s)); }
rotate_left64  :: proc(i: u64,  s: uint) ->  u64 { return (i << s)|(i >> (8*size_of(u64)  - s)); }


rotate_right8   :: proc(i: u8,   s: uint) ->   u8 { return (i >> s)|(i << (8*size_of(u8)   - s)); }
rotate_right16  :: proc(i: u16,  s: uint) ->  u16 { return (i >> s)|(i << (8*size_of(u16)  - s)); }
rotate_right32  :: proc(i: u32,  s: uint) ->  u32 { return (i >> s)|(i << (8*size_of(u32)  - s)); }
rotate_right64  :: proc(i: u64,  s: uint) ->  u64 { return (i >> s)|(i << (8*size_of(u64)  - s)); }

from_be_u8   :: proc(i:   u8) ->   u8 { return i; }
from_be_u16  :: proc(i:  u16) ->  u16 { when os.ENDIAN == "big" { return i; } else { return byte_swap(i); } }
from_be_u32  :: proc(i:  u32) ->  u32 { when os.ENDIAN == "big" { return i; } else { return byte_swap(i); } }
from_be_u64  :: proc(i:  u64) ->  u64 { when os.ENDIAN == "big" { return i; } else { return byte_swap(i); } }
from_be_uint :: proc(i: uint) -> uint { when os.ENDIAN == "big" { return i; } else { return byte_swap(i); } }

from_le_u8   :: proc(i:   u8) ->   u8 { return i; }
from_le_u16  :: proc(i:  u16) ->  u16 { when os.ENDIAN == "little" { return i; } else { return byte_swap(i); } }
from_le_u32  :: proc(i:  u32) ->  u32 { when os.ENDIAN == "little" { return i; } else { return byte_swap(i); } }
from_le_u64  :: proc(i:  u64) ->  u64 { when os.ENDIAN == "little" { return i; } else { return byte_swap(i); } }
from_le_uint :: proc(i: uint) -> uint { when os.ENDIAN == "little" { return i; } else { return byte_swap(i); } }

to_be_u8   :: proc(i:   u8) ->   u8 { return i; }
to_be_u16  :: proc(i:  u16) ->  u16 { when os.ENDIAN == "big" { return i; } else { return byte_swap(i); } }
to_be_u32  :: proc(i:  u32) ->  u32 { when os.ENDIAN == "big" { return i; } else { return byte_swap(i); } }
to_be_u64  :: proc(i:  u64) ->  u64 { when os.ENDIAN == "big" { return i; } else { return byte_swap(i); } }
to_be_uint :: proc(i: uint) -> uint { when os.ENDIAN == "big" { return i; } else { return byte_swap(i); } }


to_le_u8   :: proc(i:   u8) ->   u8 { return i; }
to_le_u16  :: proc(i:  u16) ->  u16 { when os.ENDIAN == "little" { return i; } else { return byte_swap(i); } }
to_le_u32  :: proc(i:  u32) ->  u32 { when os.ENDIAN == "little" { return i; } else { return byte_swap(i); } }
to_le_u64  :: proc(i:  u64) ->  u64 { when os.ENDIAN == "little" { return i; } else { return byte_swap(i); } }
to_le_uint :: proc(i: uint) -> uint { when os.ENDIAN == "little" { return i; } else { return byte_swap(i); } }


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
