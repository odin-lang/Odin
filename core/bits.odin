U8_MIN   ::   u8(0);
U16_MIN  ::  u16(0);
U32_MIN  ::  u32(0);
U64_MIN  ::  u64(0);
U128_MIN :: u128(0);

I8_MIN   ::   i8(-0x80);
I16_MIN  ::  i16(-0x8000);
I32_MIN  ::  i32(-0x8000_0000);
I64_MIN  ::  i64(-0x8000_0000_0000_0000);
I128_MIN :: i128(-0x8000_0000_0000_0000_0000_0000_0000_0000);

U8_MAX   ::   ~u8(0);
U16_MAX  ::  ~u16(0);
U32_MAX  ::  ~u32(0);
U64_MAX  ::  ~u64(0);
U128_MAX :: ~u128(0);

I8_MAX   ::   i8(0x7f);
I16_MAX  ::  i16(0x7fff);
I32_MAX  ::  i32(0x7fff_ffff);
I64_MAX  ::  i64(0x7fff_ffff_ffff_ffff);
I128_MAX :: i128(0x7fff_ffff_ffff_ffff_ffff_ffff_ffff_ffff);

count_ones :: proc(i:   u8) ->   u8 { foreign __llvm_core __llvm_ctpop :: proc(u8)   ->   u8 #link_name "llvm.ctpop.i8" ---;  return __llvm_ctpop(i); }
count_ones :: proc(i:   i8) ->   i8 { foreign __llvm_core __llvm_ctpop :: proc(i8)   ->   i8 #link_name "llvm.ctpop.i8" ---;  return __llvm_ctpop(i); }
count_ones :: proc(i:  u16) ->  u16 { foreign __llvm_core __llvm_ctpop :: proc(u16)  ->  u16 #link_name "llvm.ctpop.i16" ---; return __llvm_ctpop(i); }
count_ones :: proc(i:  i16) ->  i16 { foreign __llvm_core __llvm_ctpop :: proc(i16)  ->  i16 #link_name "llvm.ctpop.i16" ---; return __llvm_ctpop(i); }
count_ones :: proc(i:  u32) ->  u32 { foreign __llvm_core __llvm_ctpop :: proc(u32)  ->  u32 #link_name "llvm.ctpop.i32" ---; return __llvm_ctpop(i); }
count_ones :: proc(i:  i32) ->  i32 { foreign __llvm_core __llvm_ctpop :: proc(i32)  ->  i32 #link_name "llvm.ctpop.i32" ---; return __llvm_ctpop(i); }
count_ones :: proc(i:  u64) ->  u64 { foreign __llvm_core __llvm_ctpop :: proc(u64)  ->  u64 #link_name "llvm.ctpop.i64" ---; return __llvm_ctpop(i); }
count_ones :: proc(i:  i64) ->  i64 { foreign __llvm_core __llvm_ctpop :: proc(i64)  ->  i64 #link_name "llvm.ctpop.i64" ---; return __llvm_ctpop(i); }
count_ones :: proc(i: u128) -> u128 { foreign __llvm_core __llvm_ctpop :: proc(u128) -> u128 #link_name "llvm.ctpop.i128" ---;return __llvm_ctpop(i); }
count_ones :: proc(i: i128) -> i128 { foreign __llvm_core __llvm_ctpop :: proc(i128) -> i128 #link_name "llvm.ctpop.i128" ---;return __llvm_ctpop(i); }
count_ones :: proc(i: uint) -> uint { when size_of(uint) == size_of(u32) { return uint(count_ones(u32(i))); } else { return uint(count_ones(u64(i))); } }
count_ones :: proc(i:  int) ->  int { when size_of(int)  == size_of(i32) { return int(count_ones(i32(i)));  } else { return int(count_ones(i64(i))); } }

count_zeros :: proc(i:   u8) ->   u8 { return   8 - count_ones(i); }
count_zeros :: proc(i:   i8) ->   i8 { return   8 - count_ones(i); }
count_zeros :: proc(i:  u16) ->  u16 { return  16 - count_ones(i); }
count_zeros :: proc(i:  i16) ->  i16 { return  16 - count_ones(i); }
count_zeros :: proc(i:  u32) ->  u32 { return  32 - count_ones(i); }
count_zeros :: proc(i:  i32) ->  i32 { return  32 - count_ones(i); }
count_zeros :: proc(i:  u64) ->  u64 { return  64 - count_ones(i); }
count_zeros :: proc(i:  i64) ->  i64 { return  64 - count_ones(i); }
count_zeros :: proc(i: u128) -> u128 { return 128 - count_ones(i); }
count_zeros :: proc(i: i128) -> i128 { return 128 - count_ones(i); }
count_zeros :: proc(i: uint) -> uint { return 8*size_of(uint) - count_ones(i); }
count_zeros :: proc(i:  int) ->  int { return 8*size_of(int)  - count_ones(i); }


rotate_left :: proc(i: u8,   s: uint) ->   u8 { return (i << s)|(i >> (8*size_of(u8)   - s)); }
rotate_left :: proc(i: i8,   s: uint) ->   i8 { return (i << s)|(i >> (8*size_of(i8)   - s)); }
rotate_left :: proc(i: u16,  s: uint) ->  u16 { return (i << s)|(i >> (8*size_of(u16)  - s)); }
rotate_left :: proc(i: i16,  s: uint) ->  i16 { return (i << s)|(i >> (8*size_of(i16)  - s)); }
rotate_left :: proc(i: u32,  s: uint) ->  u32 { return (i << s)|(i >> (8*size_of(u32)  - s)); }
rotate_left :: proc(i: i32,  s: uint) ->  i32 { return (i << s)|(i >> (8*size_of(i32)  - s)); }
rotate_left :: proc(i: u64,  s: uint) ->  u64 { return (i << s)|(i >> (8*size_of(u64)  - s)); }
rotate_left :: proc(i: i64,  s: uint) ->  i64 { return (i << s)|(i >> (8*size_of(i64)  - s)); }
rotate_left :: proc(i: u128, s: uint) -> u128 { return (i << s)|(i >> (8*size_of(u128) - s)); }
rotate_left :: proc(i: i128, s: uint) -> i128 { return (i << s)|(i >> (8*size_of(i128) - s)); }
rotate_left :: proc(i: uint, s: uint) -> uint { when size_of(uint) == size_of(u32) { return uint(rotate_left(u32(i), s)); } else { return uint(rotate_left(u64(i), s)); } }
rotate_left :: proc(i:  int, s: uint) ->  int { when size_of(int)  == size_of(i32) { return  int(rotate_left(i32(i), s)); } else { return  int(rotate_left(i64(i), s)); } }


rotate_right :: proc(i: u8,   s: uint) ->   u8 { return (i >> s)|(i << (8*size_of(u8)   - s)); }
rotate_right :: proc(i: i8,   s: uint) ->   i8 { return (i >> s)|(i << (8*size_of(i8)   - s)); }
rotate_right :: proc(i: u16,  s: uint) ->  u16 { return (i >> s)|(i << (8*size_of(u16)  - s)); }
rotate_right :: proc(i: i16,  s: uint) ->  i16 { return (i >> s)|(i << (8*size_of(i16)  - s)); }
rotate_right :: proc(i: u32,  s: uint) ->  u32 { return (i >> s)|(i << (8*size_of(u32)  - s)); }
rotate_right :: proc(i: i32,  s: uint) ->  i32 { return (i >> s)|(i << (8*size_of(i32)  - s)); }
rotate_right :: proc(i: u64,  s: uint) ->  u64 { return (i >> s)|(i << (8*size_of(u64)  - s)); }
rotate_right :: proc(i: i64,  s: uint) ->  i64 { return (i >> s)|(i << (8*size_of(i64)  - s)); }
rotate_right :: proc(i: u128, s: uint) -> u128 { return (i >> s)|(i << (8*size_of(u128) - s)); }
rotate_right :: proc(i: i128, s: uint) -> i128 { return (i >> s)|(i << (8*size_of(i128) - s)); }
rotate_right :: proc(i: uint, s: uint) -> uint { when size_of(uint) == size_of(u32) { return uint(rotate_right(u32(i), s)); } else { return uint(rotate_right(u64(i), s)); } }
rotate_right :: proc(i:  int, s: uint) ->  int { when size_of(int)  == size_of(i32) { return  int(rotate_right(i32(i), s)); } else { return  int(rotate_right(i64(i), s)); } }


leading_zeros :: proc(i:   u8) ->   u8 { foreign __llvm_core __llvm_ctlz :: proc(u8,   bool) ->   u8 #link_name "llvm.ctlz.i8" ---;  return __llvm_ctlz(i, false); }
leading_zeros :: proc(i:   i8) ->   i8 { foreign __llvm_core __llvm_ctlz :: proc(i8,   bool) ->   i8 #link_name "llvm.ctlz.i8" ---;  return __llvm_ctlz(i, false); }
leading_zeros :: proc(i:  u16) ->  u16 { foreign __llvm_core __llvm_ctlz :: proc(u16,  bool) ->  u16 #link_name "llvm.ctlz.i16" ---; return __llvm_ctlz(i, false); }
leading_zeros :: proc(i:  i16) ->  i16 { foreign __llvm_core __llvm_ctlz :: proc(i16,  bool) ->  i16 #link_name "llvm.ctlz.i16" ---; return __llvm_ctlz(i, false); }
leading_zeros :: proc(i:  u32) ->  u32 { foreign __llvm_core __llvm_ctlz :: proc(u32,  bool) ->  u32 #link_name "llvm.ctlz.i32" ---; return __llvm_ctlz(i, false); }
leading_zeros :: proc(i:  i32) ->  i32 { foreign __llvm_core __llvm_ctlz :: proc(i32,  bool) ->  i32 #link_name "llvm.ctlz.i32" ---; return __llvm_ctlz(i, false); }
leading_zeros :: proc(i:  u64) ->  u64 { foreign __llvm_core __llvm_ctlz :: proc(u64,  bool) ->  u64 #link_name "llvm.ctlz.i64" ---; return __llvm_ctlz(i, false); }
leading_zeros :: proc(i:  i64) ->  i64 { foreign __llvm_core __llvm_ctlz :: proc(i64,  bool) ->  i64 #link_name "llvm.ctlz.i64" ---; return __llvm_ctlz(i, false); }
leading_zeros :: proc(i: u128) -> u128 { foreign __llvm_core __llvm_ctlz :: proc(u128, bool) -> u128 #link_name "llvm.ctlz.i128" ---;return __llvm_ctlz(i, false); }
leading_zeros :: proc(i: i128) -> i128 { foreign __llvm_core __llvm_ctlz :: proc(i128, bool) -> i128 #link_name "llvm.ctlz.i128" ---;return __llvm_ctlz(i, false); }
leading_zeros :: proc(i: uint) -> uint { when size_of(uint) == size_of(u32) { return uint(leading_zeros(u32(i))); } else { return uint(leading_zeros(u64(i))); } }
leading_zeros :: proc(i:  int) ->  int { when size_of(int)  == size_of(i32) { return  int(leading_zeros(i32(i))); } else { return  int(leading_zeros(i64(i))); } }

trailing_zeros :: proc(i:   u8) ->   u8 { foreign __llvm_core __llvm_cttz :: proc(u8,   bool) ->   u8 #link_name "llvm.cttz.i8" ---;  return __llvm_cttz(i, false); }
trailing_zeros :: proc(i:   i8) ->   i8 { foreign __llvm_core __llvm_cttz :: proc(i8,   bool) ->   i8 #link_name "llvm.cttz.i8" ---;  return __llvm_cttz(i, false); }
trailing_zeros :: proc(i:  u16) ->  u16 { foreign __llvm_core __llvm_cttz :: proc(u16,  bool) ->  u16 #link_name "llvm.cttz.i16" ---; return __llvm_cttz(i, false); }
trailing_zeros :: proc(i:  i16) ->  i16 { foreign __llvm_core __llvm_cttz :: proc(i16,  bool) ->  i16 #link_name "llvm.cttz.i16" ---; return __llvm_cttz(i, false); }
trailing_zeros :: proc(i:  u32) ->  u32 { foreign __llvm_core __llvm_cttz :: proc(u32,  bool) ->  u32 #link_name "llvm.cttz.i32" ---; return __llvm_cttz(i, false); }
trailing_zeros :: proc(i:  i32) ->  i32 { foreign __llvm_core __llvm_cttz :: proc(i32,  bool) ->  i32 #link_name "llvm.cttz.i32" ---; return __llvm_cttz(i, false); }
trailing_zeros :: proc(i:  u64) ->  u64 { foreign __llvm_core __llvm_cttz :: proc(u64,  bool) ->  u64 #link_name "llvm.cttz.i64" ---; return __llvm_cttz(i, false); }
trailing_zeros :: proc(i:  i64) ->  i64 { foreign __llvm_core __llvm_cttz :: proc(i64,  bool) ->  i64 #link_name "llvm.cttz.i64" ---; return __llvm_cttz(i, false); }
trailing_zeros :: proc(i: u128) -> u128 { foreign __llvm_core __llvm_cttz :: proc(u128, bool) -> u128 #link_name "llvm.cttz.i128" ---;return __llvm_cttz(i, false); }
trailing_zeros :: proc(i: i128) -> i128 { foreign __llvm_core __llvm_cttz :: proc(i128, bool) -> i128 #link_name "llvm.cttz.i128" ---;return __llvm_cttz(i, false); }
trailing_zeros :: proc(i: uint) -> uint { when size_of(uint) == size_of(u32) { return uint(trailing_zeros(u32(i))); } else { return uint(trailing_zeros(u64(i))); } }
trailing_zeros :: proc(i:  int) ->  int { when size_of(int)  == size_of(i32) { return  int(trailing_zeros(i32(i))); } else { return  int(trailing_zeros(i64(i))); } }


reverse_bits :: proc(i:   u8) ->   u8 { foreign __llvm_core __llvm_bitreverse :: proc(u8)   ->   u8 #link_name "llvm.bitreverse.i8" ---;  return __llvm_bitreverse(i); }
reverse_bits :: proc(i:   i8) ->   i8 { foreign __llvm_core __llvm_bitreverse :: proc(i8)   ->   i8 #link_name "llvm.bitreverse.i8" ---;  return __llvm_bitreverse(i); }
reverse_bits :: proc(i:  u16) ->  u16 { foreign __llvm_core __llvm_bitreverse :: proc(u16)  ->  u16 #link_name "llvm.bitreverse.i16" ---; return __llvm_bitreverse(i); }
reverse_bits :: proc(i:  i16) ->  i16 { foreign __llvm_core __llvm_bitreverse :: proc(i16)  ->  i16 #link_name "llvm.bitreverse.i16" ---; return __llvm_bitreverse(i); }
reverse_bits :: proc(i:  u32) ->  u32 { foreign __llvm_core __llvm_bitreverse :: proc(u32)  ->  u32 #link_name "llvm.bitreverse.i32" ---; return __llvm_bitreverse(i); }
reverse_bits :: proc(i:  i32) ->  i32 { foreign __llvm_core __llvm_bitreverse :: proc(i32)  ->  i32 #link_name "llvm.bitreverse.i32" ---; return __llvm_bitreverse(i); }
reverse_bits :: proc(i:  u64) ->  u64 { foreign __llvm_core __llvm_bitreverse :: proc(u64)  ->  u64 #link_name "llvm.bitreverse.i64" ---; return __llvm_bitreverse(i); }
reverse_bits :: proc(i:  i64) ->  i64 { foreign __llvm_core __llvm_bitreverse :: proc(i64)  ->  i64 #link_name "llvm.bitreverse.i64" ---; return __llvm_bitreverse(i); }
reverse_bits :: proc(i: u128) -> u128 { foreign __llvm_core __llvm_bitreverse :: proc(u128) -> u128 #link_name "llvm.bitreverse.i128" ---;return __llvm_bitreverse(i); }
reverse_bits :: proc(i: i128) -> i128 { foreign __llvm_core __llvm_bitreverse :: proc(i128) -> i128 #link_name "llvm.bitreverse.i128" ---;return __llvm_bitreverse(i); }
reverse_bits :: proc(i: uint) -> uint { when size_of(uint) == size_of(u32) { return uint(reverse_bits(u32(i))); } else { return uint(reverse_bits(u64(i))); } }
reverse_bits :: proc(i:  int) ->  int { when size_of(int)  == size_of(i32) { return  int(reverse_bits(i32(i))); } else { return  int(reverse_bits(i64(i))); } }

foreign __llvm_core {
	byte_swap :: proc(u16)  ->  u16 #link_name "llvm.bswap.i16" ---;
	byte_swap :: proc(i16)  ->  i16 #link_name "llvm.bswap.i16" ---;
	byte_swap :: proc(u32)  ->  u32 #link_name "llvm.bswap.i32" ---;
	byte_swap :: proc(i32)  ->  i32 #link_name "llvm.bswap.i32" ---;
	byte_swap :: proc(u64)  ->  u64 #link_name "llvm.bswap.i64" ---;
	byte_swap :: proc(i64)  ->  i64 #link_name "llvm.bswap.i64" ---;
	byte_swap :: proc(u128) -> u128 #link_name "llvm.bswap.i128" ---;
	byte_swap :: proc(i128) -> i128 #link_name "llvm.bswap.i128" ---;
}
byte_swap :: proc(i: uint) -> uint { when size_of(uint) == size_of(u32) { return uint(byte_swap(u32(i))); } else { return uint(byte_swap(u64(i))); } }
byte_swap :: proc(i:  int) ->  int { when size_of(int)  == size_of(i32) { return  int(byte_swap(i32(i))); } else { return  int(byte_swap(i64(i))); } }

from_be :: proc(i:   u8) ->   u8 { return i; }
from_be :: proc(i:   i8) ->   i8 { return i; }
from_be :: proc(i:  u16) ->  u16 { when ODIN_ENDIAN == "big" { return i; } else { return byte_swap(i); } }
from_be :: proc(i:  i16) ->  i16 { when ODIN_ENDIAN == "big" { return i; } else { return byte_swap(i); } }
from_be :: proc(i:  u32) ->  u32 { when ODIN_ENDIAN == "big" { return i; } else { return byte_swap(i); } }
from_be :: proc(i:  i32) ->  i32 { when ODIN_ENDIAN == "big" { return i; } else { return byte_swap(i); } }
from_be :: proc(i:  u64) ->  u64 { when ODIN_ENDIAN == "big" { return i; } else { return byte_swap(i); } }
from_be :: proc(i:  i64) ->  i64 { when ODIN_ENDIAN == "big" { return i; } else { return byte_swap(i); } }
from_be :: proc(i: u128) -> u128 { when ODIN_ENDIAN == "big" { return i; } else { return byte_swap(i); } }
from_be :: proc(i: i128) -> i128 { when ODIN_ENDIAN == "big" { return i; } else { return byte_swap(i); } }
from_be :: proc(i: uint) -> uint { when ODIN_ENDIAN == "big" { return i; } else { return byte_swap(i); } }
from_be :: proc(i:  int) ->  int { when ODIN_ENDIAN == "big" { return i; } else { return byte_swap(i); } }

from_le :: proc(i:   u8) ->   u8 { return i; }
from_le :: proc(i:   i8) ->   i8 { return i; }
from_le :: proc(i:  u16) ->  u16 { when ODIN_ENDIAN == "little" { return i; } else { return byte_swap(i); } }
from_le :: proc(i:  i16) ->  i16 { when ODIN_ENDIAN == "little" { return i; } else { return byte_swap(i); } }
from_le :: proc(i:  u32) ->  u32 { when ODIN_ENDIAN == "little" { return i; } else { return byte_swap(i); } }
from_le :: proc(i:  i32) ->  i32 { when ODIN_ENDIAN == "little" { return i; } else { return byte_swap(i); } }
from_le :: proc(i:  u64) ->  u64 { when ODIN_ENDIAN == "little" { return i; } else { return byte_swap(i); } }
from_le :: proc(i:  i64) ->  i64 { when ODIN_ENDIAN == "little" { return i; } else { return byte_swap(i); } }
from_le :: proc(i: u128) -> u128 { when ODIN_ENDIAN == "little" { return i; } else { return byte_swap(i); } }
from_le :: proc(i: i128) -> i128 { when ODIN_ENDIAN == "little" { return i; } else { return byte_swap(i); } }
from_le :: proc(i: uint) -> uint { when ODIN_ENDIAN == "little" { return i; } else { return byte_swap(i); } }
from_le :: proc(i:  int) ->  int { when ODIN_ENDIAN == "little" { return i; } else { return byte_swap(i); } }

to_be :: proc(i:   u8) ->   u8 { return i; }
to_be :: proc(i:   i8) ->   i8 { return i; }
to_be :: proc(i:  u16) ->  u16 { when ODIN_ENDIAN == "big" { return i; } else { return byte_swap(i); } }
to_be :: proc(i:  i16) ->  i16 { when ODIN_ENDIAN == "big" { return i; } else { return byte_swap(i); } }
to_be :: proc(i:  u32) ->  u32 { when ODIN_ENDIAN == "big" { return i; } else { return byte_swap(i); } }
to_be :: proc(i:  i32) ->  i32 { when ODIN_ENDIAN == "big" { return i; } else { return byte_swap(i); } }
to_be :: proc(i:  u64) ->  u64 { when ODIN_ENDIAN == "big" { return i; } else { return byte_swap(i); } }
to_be :: proc(i:  i64) ->  i64 { when ODIN_ENDIAN == "big" { return i; } else { return byte_swap(i); } }
to_be :: proc(i: u128) -> u128 { when ODIN_ENDIAN == "big" { return i; } else { return byte_swap(i); } }
to_be :: proc(i: i128) -> i128 { when ODIN_ENDIAN == "big" { return i; } else { return byte_swap(i); } }
to_be :: proc(i: uint) -> uint { when ODIN_ENDIAN == "big" { return i; } else { return byte_swap(i); } }
to_be :: proc(i:  int) ->  int { when ODIN_ENDIAN == "big" { return i; } else { return byte_swap(i); } }


to_le :: proc(i:   u8) ->   u8 { return i; }
to_le :: proc(i:   i8) ->   i8 { return i; }
to_le :: proc(i:  u16) ->  u16 { when ODIN_ENDIAN == "little" { return i; } else { return byte_swap(i); } }
to_le :: proc(i:  i16) ->  i16 { when ODIN_ENDIAN == "little" { return i; } else { return byte_swap(i); } }
to_le :: proc(i:  u32) ->  u32 { when ODIN_ENDIAN == "little" { return i; } else { return byte_swap(i); } }
to_le :: proc(i:  i32) ->  i32 { when ODIN_ENDIAN == "little" { return i; } else { return byte_swap(i); } }
to_le :: proc(i:  u64) ->  u64 { when ODIN_ENDIAN == "little" { return i; } else { return byte_swap(i); } }
to_le :: proc(i:  i64) ->  i64 { when ODIN_ENDIAN == "little" { return i; } else { return byte_swap(i); } }
to_le :: proc(i: u128) -> u128 { when ODIN_ENDIAN == "little" { return i; } else { return byte_swap(i); } }
to_le :: proc(i: i128) -> i128 { when ODIN_ENDIAN == "little" { return i; } else { return byte_swap(i); } }
to_le :: proc(i: uint) -> uint { when ODIN_ENDIAN == "little" { return i; } else { return byte_swap(i); } }
to_le :: proc(i:  int) ->  int { when ODIN_ENDIAN == "little" { return i; } else { return byte_swap(i); } }


overflowing_add :: proc(lhs, rhs:   u8) -> (u8, bool)   { foreign __llvm_core op :: proc(u8, u8)     -> (u8, bool)   #link_name "llvm.uadd.with.overflow.i8" ---;   return op(lhs, rhs); }
overflowing_add :: proc(lhs, rhs:   i8) -> (i8, bool)   { foreign __llvm_core op :: proc(i8, i8)     -> (i8, bool)   #link_name "llvm.sadd.with.overflow.i8" ---;   return op(lhs, rhs); }
overflowing_add :: proc(lhs, rhs:  u16) -> (u16, bool)  { foreign __llvm_core op :: proc(u16, u16)   -> (u16, bool)  #link_name "llvm.uadd.with.overflow.i16" ---;  return op(lhs, rhs); }
overflowing_add :: proc(lhs, rhs:  i16) -> (i16, bool)  { foreign __llvm_core op :: proc(i16, i16)   -> (i16, bool)  #link_name "llvm.sadd.with.overflow.i16" ---;  return op(lhs, rhs); }
overflowing_add :: proc(lhs, rhs:  u32) -> (u32, bool)  { foreign __llvm_core op :: proc(u32, u32)   -> (u32, bool)  #link_name "llvm.uadd.with.overflow.i32" ---;  return op(lhs, rhs); }
overflowing_add :: proc(lhs, rhs:  i32) -> (i32, bool)  { foreign __llvm_core op :: proc(i32, i32)   -> (i32, bool)  #link_name "llvm.sadd.with.overflow.i32" ---;  return op(lhs, rhs); }
overflowing_add :: proc(lhs, rhs:  u64) -> (u64, bool)  { foreign __llvm_core op :: proc(u64, u64)   -> (u64, bool)  #link_name "llvm.uadd.with.overflow.i64" ---;  return op(lhs, rhs); }
overflowing_add :: proc(lhs, rhs:  i64) -> (i64, bool)  { foreign __llvm_core op :: proc(i64, i64)   -> (i64, bool)  #link_name "llvm.sadd.with.overflow.i64" ---;  return op(lhs, rhs); }
overflowing_add :: proc(lhs, rhs: u128) -> (u128, bool) { foreign __llvm_core op :: proc(u128, u128) -> (u128, bool) #link_name "llvm.uadd.with.overflow.i128" ---; return op(lhs, rhs); }
overflowing_add :: proc(lhs, rhs: i128) -> (i128, bool) { foreign __llvm_core op :: proc(i128, i128) -> (i128, bool) #link_name "llvm.sadd.with.overflow.i128" ---; return op(lhs, rhs); }
overflowing_add :: proc(lhs, rhs: uint) -> (uint, bool) {
	when size_of(uint) == size_of(u32) {
		x, ok := overflowing_add(u32(lhs), u32(rhs));
		return uint(x), ok;
	} else {
		x, ok := overflowing_add(u64(lhs), u64(rhs));
		return uint(x), ok;
	}
}
overflowing_add :: proc(lhs, rhs: int) -> (int, bool) {
	when size_of(int) == size_of(i32) {
		x, ok := overflowing_add(i32(lhs), i32(rhs));
		return int(x), ok;
	} else {
		x, ok := overflowing_add(i64(lhs), i64(rhs));
		return int(x), ok;
	}
}

overflowing_sub :: proc(lhs, rhs:   u8) -> (u8, bool)   { foreign __llvm_core op :: proc(u8, u8)     -> (u8, bool)   #link_name "llvm.usub.with.overflow.i8" ---;   return op(lhs, rhs); }
overflowing_sub :: proc(lhs, rhs:   i8) -> (i8, bool)   { foreign __llvm_core op :: proc(i8, i8)     -> (i8, bool)   #link_name "llvm.ssub.with.overflow.i8" ---;   return op(lhs, rhs); }
overflowing_sub :: proc(lhs, rhs:  u16) -> (u16, bool)  { foreign __llvm_core op :: proc(u16, u16)   -> (u16, bool)  #link_name "llvm.usub.with.overflow.i16" ---;  return op(lhs, rhs); }
overflowing_sub :: proc(lhs, rhs:  i16) -> (i16, bool)  { foreign __llvm_core op :: proc(i16, i16)   -> (i16, bool)  #link_name "llvm.ssub.with.overflow.i16" ---;  return op(lhs, rhs); }
overflowing_sub :: proc(lhs, rhs:  u32) -> (u32, bool)  { foreign __llvm_core op :: proc(u32, u32)   -> (u32, bool)  #link_name "llvm.usub.with.overflow.i32" ---;  return op(lhs, rhs); }
overflowing_sub :: proc(lhs, rhs:  i32) -> (i32, bool)  { foreign __llvm_core op :: proc(i32, i32)   -> (i32, bool)  #link_name "llvm.ssub.with.overflow.i32" ---;  return op(lhs, rhs); }
overflowing_sub :: proc(lhs, rhs:  u64) -> (u64, bool)  { foreign __llvm_core op :: proc(u64, u64)   -> (u64, bool)  #link_name "llvm.usub.with.overflow.i64" ---;  return op(lhs, rhs); }
overflowing_sub :: proc(lhs, rhs:  i64) -> (i64, bool)  { foreign __llvm_core op :: proc(i64, i64)   -> (i64, bool)  #link_name "llvm.ssub.with.overflow.i64" ---;  return op(lhs, rhs); }
overflowing_sub :: proc(lhs, rhs: u128) -> (u128, bool) { foreign __llvm_core op :: proc(u128, u128) -> (u128, bool) #link_name "llvm.usub.with.overflow.i128" ---; return op(lhs, rhs); }
overflowing_sub :: proc(lhs, rhs: i128) -> (i128, bool) { foreign __llvm_core op :: proc(i128, i128) -> (i128, bool) #link_name "llvm.ssub.with.overflow.i128" ---; return op(lhs, rhs); }
overflowing_sub :: proc(lhs, rhs: uint) -> (uint, bool) {
	when size_of(uint) == size_of(u32) {
		x, ok := overflowing_sub(u32(lhs), u32(rhs));
		return uint(x), ok;
	} else {
		x, ok := overflowing_sub(u64(lhs), u64(rhs));
		return uint(x), ok;
	}
}
overflowing_sub :: proc(lhs, rhs: int) -> (int, bool) {
	when size_of(int) == size_of(i32) {
		x, ok := overflowing_sub(i32(lhs), i32(rhs));
		return int(x), ok;
	} else {
		x, ok := overflowing_sub(i64(lhs), i64(rhs));
		return int(x), ok;
	}
}

overflowing_mul :: proc(lhs, rhs:   u8) -> (u8, bool)   { foreign __llvm_core op :: proc(u8, u8)     -> (u8, bool)   #link_name "llvm.umul.with.overflow.i8" ---;   return op(lhs, rhs); }
overflowing_mul :: proc(lhs, rhs:   i8) -> (i8, bool)   { foreign __llvm_core op :: proc(i8, i8)     -> (i8, bool)   #link_name "llvm.smul.with.overflow.i8" ---;   return op(lhs, rhs); }
overflowing_mul :: proc(lhs, rhs:  u16) -> (u16, bool)  { foreign __llvm_core op :: proc(u16, u16)   -> (u16, bool)  #link_name "llvm.umul.with.overflow.i16" ---;  return op(lhs, rhs); }
overflowing_mul :: proc(lhs, rhs:  i16) -> (i16, bool)  { foreign __llvm_core op :: proc(i16, i16)   -> (i16, bool)  #link_name "llvm.smul.with.overflow.i16" ---;  return op(lhs, rhs); }
overflowing_mul :: proc(lhs, rhs:  u32) -> (u32, bool)  { foreign __llvm_core op :: proc(u32, u32)   -> (u32, bool)  #link_name "llvm.umul.with.overflow.i32" ---;  return op(lhs, rhs); }
overflowing_mul :: proc(lhs, rhs:  i32) -> (i32, bool)  { foreign __llvm_core op :: proc(i32, i32)   -> (i32, bool)  #link_name "llvm.smul.with.overflow.i32" ---;  return op(lhs, rhs); }
overflowing_mul :: proc(lhs, rhs:  u64) -> (u64, bool)  { foreign __llvm_core op :: proc(u64, u64)   -> (u64, bool)  #link_name "llvm.umul.with.overflow.i64" ---;  return op(lhs, rhs); }
overflowing_mul :: proc(lhs, rhs:  i64) -> (i64, bool)  { foreign __llvm_core op :: proc(i64, i64)   -> (i64, bool)  #link_name "llvm.smul.with.overflow.i64" ---;  return op(lhs, rhs); }
overflowing_mul :: proc(lhs, rhs: u128) -> (u128, bool) { foreign __llvm_core op :: proc(u128, u128) -> (u128, bool) #link_name "llvm.umul.with.overflow.i128" ---; return op(lhs, rhs); }
overflowing_mul :: proc(lhs, rhs: i128) -> (i128, bool) { foreign __llvm_core op :: proc(i128, i128) -> (i128, bool) #link_name "llvm.smul.with.overflow.i128" ---; return op(lhs, rhs); }
overflowing_mul :: proc(lhs, rhs: uint) -> (uint, bool) {
	when size_of(uint) == size_of(u32) {
		x, ok := overflowing_mul(u32(lhs), u32(rhs));
		return uint(x), ok;
	} else {
		x, ok := overflowing_mul(u64(lhs), u64(rhs));
		return uint(x), ok;
	}
}
overflowing_mul :: proc(lhs, rhs: int) -> (int, bool) {
	when size_of(int) == size_of(i32) {
		x, ok := overflowing_mul(i32(lhs), i32(rhs));
		return int(x), ok;
	} else {
		x, ok := overflowing_mul(i64(lhs), i64(rhs));
		return int(x), ok;
	}
}

is_power_of_two :: proc(i:   u8) -> bool { return i > 0 && (i & (i-1)) == 0; }
is_power_of_two :: proc(i:   i8) -> bool { return i > 0 && (i & (i-1)) == 0; }
is_power_of_two :: proc(i:  u16) -> bool { return i > 0 && (i & (i-1)) == 0; }
is_power_of_two :: proc(i:  i16) -> bool { return i > 0 && (i & (i-1)) == 0; }
is_power_of_two :: proc(i:  u32) -> bool { return i > 0 && (i & (i-1)) == 0; }
is_power_of_two :: proc(i:  i32) -> bool { return i > 0 && (i & (i-1)) == 0; }
is_power_of_two :: proc(i:  u64) -> bool { return i > 0 && (i & (i-1)) == 0; }
is_power_of_two :: proc(i:  i64) -> bool { return i > 0 && (i & (i-1)) == 0; }
is_power_of_two :: proc(i: u128) -> bool { return i > 0 && (i & (i-1)) == 0; }
is_power_of_two :: proc(i: i128) -> bool { return i > 0 && (i & (i-1)) == 0; }
is_power_of_two :: proc(i: uint) -> bool { return i > 0 && (i & (i-1)) == 0; }
is_power_of_two :: proc(i:  int) -> bool { return i > 0 && (i & (i-1)) == 0; }
