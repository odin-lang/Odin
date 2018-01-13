U8_MIN   ::   u8(0);
U16_MIN  ::  u16(0);
U32_MIN  ::  u32(0);
U64_MIN  ::  u64(0);

U8_MAX   ::   ~u8(0);
U16_MAX  ::  ~u16(0);
U32_MAX  ::  ~u32(0);
U64_MAX  ::  ~u64(0);

I8_MIN   ::   i8(  ~u8(0) >> 1);
I16_MIN  ::  i16( ~u16(0) >> 1);
I32_MIN  ::  i32( ~u32(0) >> 1);
I64_MIN  ::  i64( ~u64(0) >> 1);

I8_MAX   ::   -I8_MIN - 1;
I16_MAX  ::  -I16_MIN - 1;
I32_MAX  ::  -I32_MIN - 1;
I64_MAX  ::  -I64_MIN - 1;

foreign __llvm_core {
	@(link_name="llvm.ctpop.i8")        __llvm_ctpop8   :: proc(u8)   ->   u8 ---;
	@(link_name="llvm.ctpop.i16")       __llvm_ctpop16  :: proc(u16)  ->  u16 ---;
	@(link_name="llvm.ctpop.i32")       __llvm_ctpop32  :: proc(u32)  ->  u32 ---;
	@(link_name="llvm.ctpop.i64")       __llvm_ctpop64  :: proc(u64)  ->  u64 ---;

	@(link_name="llvm.ctlz.i8")         __llvm_ctlz8   :: proc(u8,   bool) ->   u8 ---;
	@(link_name="llvm.ctlz.i16")        __llvm_ctlz16  :: proc(u16,  bool) ->  u16 ---;
	@(link_name="llvm.ctlz.i32")        __llvm_ctlz32  :: proc(u32,  bool) ->  u32 ---;
	@(link_name="llvm.ctlz.i64")        __llvm_ctlz64  :: proc(u64,  bool) ->  u64 ---;

	@(link_name="llvm.cttz.i8")         __llvm_cttz8   :: proc(u8,   bool) ->   u8 ---;
	@(link_name="llvm.cttz.i16")        __llvm_cttz16  :: proc(u16,  bool) ->  u16 ---;
	@(link_name="llvm.cttz.i32")        __llvm_cttz32  :: proc(u32,  bool) ->  u32 ---;
	@(link_name="llvm.cttz.i64")        __llvm_cttz64  :: proc(u64,  bool) ->  u64 ---;

	@(link_name="llvm.bitreverse.i8")   __llvm_bitreverse8   :: proc(u8)   ->   u8 ---;
	@(link_name="llvm.bitreverse.i16")  __llvm_bitreverse16  :: proc(u16)  ->  u16 ---;
	@(link_name="llvm.bitreverse.i32")  __llvm_bitreverse32  :: proc(u32)  ->  u32 ---;
	@(link_name="llvm.bitreverse.i64")  __llvm_bitreverse64  :: proc(u64)  ->  u64 ---;

	@(link_name="llvm.bswap.i16")  byte_swap16  :: proc(u16)  ->  u16 ---;
	@(link_name="llvm.bswap.i32")  byte_swap32  :: proc(u32)  ->  u32 ---;
	@(link_name="llvm.bswap.i64")  byte_swap64  :: proc(u64)  ->  u64 ---;
}

byte_swap_uint :: proc(i: uint) -> uint {
	when size_of(uint) == size_of(u32) {
		return uint(byte_swap32(u32(i)));
	} else {
		return uint(byte_swap64(u64(i)));
	}
}

byte_swap :: proc[byte_swap16, byte_swap32, byte_swap64, byte_swap_uint];

count_ones8   :: proc(i:   u8) ->   u8 { return __llvm_ctpop8(i); }
count_ones16  :: proc(i:  u16) ->  u16 { return __llvm_ctpop16(i); }
count_ones32  :: proc(i:  u32) ->  u32 { return __llvm_ctpop32(i); }
count_ones64  :: proc(i:  u64) ->  u64 { return __llvm_ctpop64(i); }

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

leading_zeros8   :: proc(i:   u8) ->   u8 { return __llvm_ctlz8(i, false); }
leading_zeros16  :: proc(i:  u16) ->  u16 { return __llvm_ctlz16(i, false); }
leading_zeros32  :: proc(i:  u32) ->  u32 { return __llvm_ctlz32(i, false); }
leading_zeros64  :: proc(i:  u64) ->  u64 { return __llvm_ctlz64(i, false); }

trailing_zeros8   :: proc(i:   u8) ->   u8 { return __llvm_cttz8(i, false); }
trailing_zeros16  :: proc(i:  u16) ->  u16 { return __llvm_cttz16(i, false); }
trailing_zeros32  :: proc(i:  u32) ->  u32 { return __llvm_cttz32(i, false); }
trailing_zeros64  :: proc(i:  u64) ->  u64 { return __llvm_cttz64(i, false); }


reverse_bits8   :: proc(i:   u8) ->   u8 { return __llvm_bitreverse8(i); }
reverse_bits16  :: proc(i:  u16) ->  u16 { return __llvm_bitreverse16(i); }
reverse_bits32  :: proc(i:  u32) ->  u32 { return __llvm_bitreverse32(i); }
reverse_bits64  :: proc(i:  u64) ->  u64 { return __llvm_bitreverse64(i); }

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


overflowing_add_u8   :: proc(lhs, rhs:   u8) -> (u8, bool)   { foreign __llvm_core @(link_name="llvm.uadd.with.overflow.i8")   op :: proc(u8, u8)     -> (u8, bool)   ---; return op(lhs, rhs); }
overflowing_add_i8   :: proc(lhs, rhs:   i8) -> (i8, bool)   { foreign __llvm_core @(link_name="llvm.sadd.with.overflow.i8")   op :: proc(i8, i8)     -> (i8, bool)   ---; return op(lhs, rhs); }
overflowing_add_u16  :: proc(lhs, rhs:  u16) -> (u16, bool)  { foreign __llvm_core @(link_name="llvm.uadd.with.overflow.i16")  op :: proc(u16, u16)   -> (u16, bool)  ---; return op(lhs, rhs); }
overflowing_add_i16  :: proc(lhs, rhs:  i16) -> (i16, bool)  { foreign __llvm_core @(link_name="llvm.sadd.with.overflow.i16")  op :: proc(i16, i16)   -> (i16, bool)  ---; return op(lhs, rhs); }
overflowing_add_u32  :: proc(lhs, rhs:  u32) -> (u32, bool)  { foreign __llvm_core @(link_name="llvm.uadd.with.overflow.i32")  op :: proc(u32, u32)   -> (u32, bool)  ---; return op(lhs, rhs); }
overflowing_add_i32  :: proc(lhs, rhs:  i32) -> (i32, bool)  { foreign __llvm_core @(link_name="llvm.sadd.with.overflow.i32")  op :: proc(i32, i32)   -> (i32, bool)  ---; return op(lhs, rhs); }
overflowing_add_u64  :: proc(lhs, rhs:  u64) -> (u64, bool)  { foreign __llvm_core @(link_name="llvm.uadd.with.overflow.i64")  op :: proc(u64, u64)   -> (u64, bool)  ---; return op(lhs, rhs); }
overflowing_add_i64  :: proc(lhs, rhs:  i64) -> (i64, bool)  { foreign __llvm_core @(link_name="llvm.sadd.with.overflow.i64")  op :: proc(i64, i64)   -> (i64, bool)  ---; return op(lhs, rhs); }
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

overflowing_add :: proc[
	overflowing_add_u8,   overflowing_add_i8,
	overflowing_add_u16,  overflowing_add_i16,
	overflowing_add_u32,  overflowing_add_i32,
	overflowing_add_u64,  overflowing_add_i64,
	overflowing_add_uint, overflowing_add_int,
];

overflowing_sub_u8   :: proc(lhs, rhs:   u8) -> (u8, bool)   { foreign __llvm_core @(link_name="llvm.usub.with.overflow.i8")   op :: proc(u8, u8)     -> (u8, bool)   ---; return op(lhs, rhs); }
overflowing_sub_i8   :: proc(lhs, rhs:   i8) -> (i8, bool)   { foreign __llvm_core @(link_name="llvm.ssub.with.overflow.i8")   op :: proc(i8, i8)     -> (i8, bool)   ---; return op(lhs, rhs); }
overflowing_sub_u16  :: proc(lhs, rhs:  u16) -> (u16, bool)  { foreign __llvm_core @(link_name="llvm.usub.with.overflow.i16")  op :: proc(u16, u16)   -> (u16, bool)  ---; return op(lhs, rhs); }
overflowing_sub_i16  :: proc(lhs, rhs:  i16) -> (i16, bool)  { foreign __llvm_core @(link_name="llvm.ssub.with.overflow.i16")  op :: proc(i16, i16)   -> (i16, bool)  ---; return op(lhs, rhs); }
overflowing_sub_u32  :: proc(lhs, rhs:  u32) -> (u32, bool)  { foreign __llvm_core @(link_name="llvm.usub.with.overflow.i32")  op :: proc(u32, u32)   -> (u32, bool)  ---; return op(lhs, rhs); }
overflowing_sub_i32  :: proc(lhs, rhs:  i32) -> (i32, bool)  { foreign __llvm_core @(link_name="llvm.ssub.with.overflow.i32")  op :: proc(i32, i32)   -> (i32, bool)  ---; return op(lhs, rhs); }
overflowing_sub_u64  :: proc(lhs, rhs:  u64) -> (u64, bool)  { foreign __llvm_core @(link_name="llvm.usub.with.overflow.i64")  op :: proc(u64, u64)   -> (u64, bool)  ---; return op(lhs, rhs); }
overflowing_sub_i64  :: proc(lhs, rhs:  i64) -> (i64, bool)  { foreign __llvm_core @(link_name="llvm.ssub.with.overflow.i64")  op :: proc(i64, i64)   -> (i64, bool)  ---; return op(lhs, rhs); }
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

overflowing_sub :: proc[
	overflowing_sub_u8,   overflowing_sub_i8,
	overflowing_sub_u16,  overflowing_sub_i16,
	overflowing_sub_u32,  overflowing_sub_i32,
	overflowing_sub_u64,  overflowing_sub_i64,
	overflowing_sub_uint, overflowing_sub_int,
];


overflowing_mul_u8   :: proc(lhs, rhs:   u8) -> (u8, bool)   { foreign __llvm_core @(link_name="llvm.umul.with.overflow.i8")   op :: proc(u8, u8)     -> (u8, bool)   ---; return op(lhs, rhs); }
overflowing_mul_i8   :: proc(lhs, rhs:   i8) -> (i8, bool)   { foreign __llvm_core @(link_name="llvm.smul.with.overflow.i8")   op :: proc(i8, i8)     -> (i8, bool)   ---; return op(lhs, rhs); }
overflowing_mul_u16  :: proc(lhs, rhs:  u16) -> (u16, bool)  { foreign __llvm_core @(link_name="llvm.umul.with.overflow.i16")  op :: proc(u16, u16)   -> (u16, bool)  ---; return op(lhs, rhs); }
overflowing_mul_i16  :: proc(lhs, rhs:  i16) -> (i16, bool)  { foreign __llvm_core @(link_name="llvm.smul.with.overflow.i16")  op :: proc(i16, i16)   -> (i16, bool)  ---; return op(lhs, rhs); }
overflowing_mul_u32  :: proc(lhs, rhs:  u32) -> (u32, bool)  { foreign __llvm_core @(link_name="llvm.umul.with.overflow.i32")  op :: proc(u32, u32)   -> (u32, bool)  ---; return op(lhs, rhs); }
overflowing_mul_i32  :: proc(lhs, rhs:  i32) -> (i32, bool)  { foreign __llvm_core @(link_name="llvm.smul.with.overflow.i32")  op :: proc(i32, i32)   -> (i32, bool)  ---; return op(lhs, rhs); }
overflowing_mul_u64  :: proc(lhs, rhs:  u64) -> (u64, bool)  { foreign __llvm_core @(link_name="llvm.umul.with.overflow.i64")  op :: proc(u64, u64)   -> (u64, bool)  ---; return op(lhs, rhs); }
overflowing_mul_i64  :: proc(lhs, rhs:  i64) -> (i64, bool)  { foreign __llvm_core @(link_name="llvm.smul.with.overflow.i64")  op :: proc(i64, i64)   -> (i64, bool)  ---; return op(lhs, rhs); }
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

overflowing_mul :: proc[
	overflowing_mul_u8,   overflowing_mul_i8,
	overflowing_mul_u16,  overflowing_mul_i16,
	overflowing_mul_u32,  overflowing_mul_i32,
	overflowing_mul_u64,  overflowing_mul_i64,
	overflowing_mul_uint, overflowing_mul_int,
];

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

is_power_of_two :: proc[
	is_power_of_two_u8,   is_power_of_two_i8,
	is_power_of_two_u16,  is_power_of_two_i16,
	is_power_of_two_u32,  is_power_of_two_i32,
	is_power_of_two_u64,  is_power_of_two_i64,
	is_power_of_two_uint, is_power_of_two_int,
]
