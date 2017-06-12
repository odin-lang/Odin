const U8_MIN   =   u8(0);
const U16_MIN  =  u16(0);
const U32_MIN  =  u32(0);
const U64_MIN  =  u64(0);
const U128_MIN = u128(0);

const I8_MIN   =   i8(-0x80);
const I16_MIN  =  i16(-0x8000);
const I32_MIN  =  i32(-0x8000_0000);
const I64_MIN  =  i64(-0x8000_0000_0000_0000);
const I128_MIN = i128(-0x8000_0000_0000_0000_0000_0000_0000_0000);

const U8_MAX   =   ~u8(0);
const U16_MAX  =  ~u16(0);
const U32_MAX  =  ~u32(0);
const U64_MAX  =  ~u64(0);
const U128_MAX = ~u128(0);

const I8_MAX   =   i8(0x7f);
const I16_MAX  =  i16(0x7fff);
const I32_MAX  =  i32(0x7fff_ffff);
const I64_MAX  =  i64(0x7fff_ffff_ffff_ffff);
const I128_MAX = i128(0x7fff_ffff_ffff_ffff_ffff_ffff_ffff_ffff);


proc count_ones(i:   u8) ->   u8 { proc __llvm_ctpop(u8)   ->   u8 #foreign __llvm_core "llvm.ctpop.i8";  return __llvm_ctpop(i); }
proc count_ones(i:   i8) ->   i8 { proc __llvm_ctpop(i8)   ->   i8 #foreign __llvm_core "llvm.ctpop.i8";  return __llvm_ctpop(i); }
proc count_ones(i:  u16) ->  u16 { proc __llvm_ctpop(u16)  ->  u16 #foreign __llvm_core "llvm.ctpop.i16"; return __llvm_ctpop(i); }
proc count_ones(i:  i16) ->  i16 { proc __llvm_ctpop(i16)  ->  i16 #foreign __llvm_core "llvm.ctpop.i16"; return __llvm_ctpop(i); }
proc count_ones(i:  u32) ->  u32 { proc __llvm_ctpop(u32)  ->  u32 #foreign __llvm_core "llvm.ctpop.i32"; return __llvm_ctpop(i); }
proc count_ones(i:  i32) ->  i32 { proc __llvm_ctpop(i32)  ->  i32 #foreign __llvm_core "llvm.ctpop.i32"; return __llvm_ctpop(i); }
proc count_ones(i:  u64) ->  u64 { proc __llvm_ctpop(u64)  ->  u64 #foreign __llvm_core "llvm.ctpop.i64"; return __llvm_ctpop(i); }
proc count_ones(i:  i64) ->  i64 { proc __llvm_ctpop(i64)  ->  i64 #foreign __llvm_core "llvm.ctpop.i64"; return __llvm_ctpop(i); }
proc count_ones(i: u128) -> u128 { proc __llvm_ctpop(u128) -> u128 #foreign __llvm_core "llvm.ctpop.i128";return __llvm_ctpop(i); }
proc count_ones(i: i128) -> i128 { proc __llvm_ctpop(i128) -> i128 #foreign __llvm_core "llvm.ctpop.i128";return __llvm_ctpop(i); }
proc count_ones(i: uint) -> uint { when size_of(uint) == size_of(u32) { return uint(count_ones(u32(i))); } else { return uint(count_ones(u64(i))); } }
proc count_ones(i:  int) ->  int { when size_of(int)  == size_of(i32) { return int(count_ones(i32(i)));  } else { return int(count_ones(i64(i))); } }

proc count_zeros(i:   u8) ->   u8 { return   8 - count_ones(i); }
proc count_zeros(i:   i8) ->   i8 { return   8 - count_ones(i); }
proc count_zeros(i:  u16) ->  u16 { return  16 - count_ones(i); }
proc count_zeros(i:  i16) ->  i16 { return  16 - count_ones(i); }
proc count_zeros(i:  u32) ->  u32 { return  32 - count_ones(i); }
proc count_zeros(i:  i32) ->  i32 { return  32 - count_ones(i); }
proc count_zeros(i:  u64) ->  u64 { return  64 - count_ones(i); }
proc count_zeros(i:  i64) ->  i64 { return  64 - count_ones(i); }
proc count_zeros(i: u128) -> u128 { return 128 - count_ones(i); }
proc count_zeros(i: i128) -> i128 { return 128 - count_ones(i); }
proc count_zeros(i: uint) -> uint { return 8*size_of(uint) - count_ones(i); }
proc count_zeros(i:  int) ->  int { return 8*size_of(int)  - count_ones(i); }


proc rotate_left(i: u8,   s: uint) ->   u8 { return (i << s)|(i >> (8*size_of(u8)   - s)); }
proc rotate_left(i: i8,   s: uint) ->   i8 { return (i << s)|(i >> (8*size_of(i8)   - s)); }
proc rotate_left(i: u16,  s: uint) ->  u16 { return (i << s)|(i >> (8*size_of(u16)  - s)); }
proc rotate_left(i: i16,  s: uint) ->  i16 { return (i << s)|(i >> (8*size_of(i16)  - s)); }
proc rotate_left(i: u32,  s: uint) ->  u32 { return (i << s)|(i >> (8*size_of(u32)  - s)); }
proc rotate_left(i: i32,  s: uint) ->  i32 { return (i << s)|(i >> (8*size_of(i32)  - s)); }
proc rotate_left(i: u64,  s: uint) ->  u64 { return (i << s)|(i >> (8*size_of(u64)  - s)); }
proc rotate_left(i: i64,  s: uint) ->  i64 { return (i << s)|(i >> (8*size_of(i64)  - s)); }
proc rotate_left(i: u128, s: uint) -> u128 { return (i << s)|(i >> (8*size_of(u128) - s)); }
proc rotate_left(i: i128, s: uint) -> i128 { return (i << s)|(i >> (8*size_of(i128) - s)); }
proc rotate_left(i: uint, s: uint) -> uint { when size_of(uint) == size_of(u32) { return uint(rotate_left(u32(i), s)); } else { return uint(rotate_left(u64(i), s)); } }
proc rotate_left(i:  int, s: uint) ->  int { when size_of(int)  == size_of(i32) { return  int(rotate_left(i32(i), s)); } else { return  int(rotate_left(i64(i), s)); } }


proc rotate_right(i: u8,   s: uint) ->   u8 { return (i >> s)|(i << (8*size_of(u8)   - s)); }
proc rotate_right(i: i8,   s: uint) ->   i8 { return (i >> s)|(i << (8*size_of(i8)   - s)); }
proc rotate_right(i: u16,  s: uint) ->  u16 { return (i >> s)|(i << (8*size_of(u16)  - s)); }
proc rotate_right(i: i16,  s: uint) ->  i16 { return (i >> s)|(i << (8*size_of(i16)  - s)); }
proc rotate_right(i: u32,  s: uint) ->  u32 { return (i >> s)|(i << (8*size_of(u32)  - s)); }
proc rotate_right(i: i32,  s: uint) ->  i32 { return (i >> s)|(i << (8*size_of(i32)  - s)); }
proc rotate_right(i: u64,  s: uint) ->  u64 { return (i >> s)|(i << (8*size_of(u64)  - s)); }
proc rotate_right(i: i64,  s: uint) ->  i64 { return (i >> s)|(i << (8*size_of(i64)  - s)); }
proc rotate_right(i: u128, s: uint) -> u128 { return (i >> s)|(i << (8*size_of(u128) - s)); }
proc rotate_right(i: i128, s: uint) -> i128 { return (i >> s)|(i << (8*size_of(i128) - s)); }
proc rotate_right(i: uint, s: uint) -> uint { when size_of(uint) == size_of(u32) { return uint(rotate_right(u32(i), s)); } else { return uint(rotate_right(u64(i), s)); } }
proc rotate_right(i:  int, s: uint) ->  int { when size_of(int)  == size_of(i32) { return  int(rotate_right(i32(i), s)); } else { return  int(rotate_right(i64(i), s)); } }


proc leading_zeros(i:   u8) ->   u8 { proc __llvm_ctlz(u8,   bool) ->   u8 #foreign __llvm_core "llvm.ctlz.i8";  return __llvm_ctlz(i, false); }
proc leading_zeros(i:   i8) ->   i8 { proc __llvm_ctlz(i8,   bool) ->   i8 #foreign __llvm_core "llvm.ctlz.i8";  return __llvm_ctlz(i, false); }
proc leading_zeros(i:  u16) ->  u16 { proc __llvm_ctlz(u16,  bool) ->  u16 #foreign __llvm_core "llvm.ctlz.i16"; return __llvm_ctlz(i, false); }
proc leading_zeros(i:  i16) ->  i16 { proc __llvm_ctlz(i16,  bool) ->  i16 #foreign __llvm_core "llvm.ctlz.i16"; return __llvm_ctlz(i, false); }
proc leading_zeros(i:  u32) ->  u32 { proc __llvm_ctlz(u32,  bool) ->  u32 #foreign __llvm_core "llvm.ctlz.i32"; return __llvm_ctlz(i, false); }
proc leading_zeros(i:  i32) ->  i32 { proc __llvm_ctlz(i32,  bool) ->  i32 #foreign __llvm_core "llvm.ctlz.i32"; return __llvm_ctlz(i, false); }
proc leading_zeros(i:  u64) ->  u64 { proc __llvm_ctlz(u64,  bool) ->  u64 #foreign __llvm_core "llvm.ctlz.i64"; return __llvm_ctlz(i, false); }
proc leading_zeros(i:  i64) ->  i64 { proc __llvm_ctlz(i64,  bool) ->  i64 #foreign __llvm_core "llvm.ctlz.i64"; return __llvm_ctlz(i, false); }
proc leading_zeros(i: u128) -> u128 { proc __llvm_ctlz(u128, bool) -> u128 #foreign __llvm_core "llvm.ctlz.i128";return __llvm_ctlz(i, false); }
proc leading_zeros(i: i128) -> i128 { proc __llvm_ctlz(i128, bool) -> i128 #foreign __llvm_core "llvm.ctlz.i128";return __llvm_ctlz(i, false); }
proc leading_zeros(i: uint) -> uint { when size_of(uint) == size_of(u32) { return uint(leading_zeros(u32(i))); } else { return uint(leading_zeros(u64(i))); } }
proc leading_zeros(i:  int) ->  int { when size_of(int)  == size_of(i32) { return  int(leading_zeros(i32(i))); } else { return  int(leading_zeros(i64(i))); } }

proc trailing_zeros(i:   u8) ->   u8 { proc __llvm_cttz(u8,   bool) ->   u8 #foreign __llvm_core "llvm.cttz.i8";  return __llvm_cttz(i, false); }
proc trailing_zeros(i:   i8) ->   i8 { proc __llvm_cttz(i8,   bool) ->   i8 #foreign __llvm_core "llvm.cttz.i8";  return __llvm_cttz(i, false); }
proc trailing_zeros(i:  u16) ->  u16 { proc __llvm_cttz(u16,  bool) ->  u16 #foreign __llvm_core "llvm.cttz.i16"; return __llvm_cttz(i, false); }
proc trailing_zeros(i:  i16) ->  i16 { proc __llvm_cttz(i16,  bool) ->  i16 #foreign __llvm_core "llvm.cttz.i16"; return __llvm_cttz(i, false); }
proc trailing_zeros(i:  u32) ->  u32 { proc __llvm_cttz(u32,  bool) ->  u32 #foreign __llvm_core "llvm.cttz.i32"; return __llvm_cttz(i, false); }
proc trailing_zeros(i:  i32) ->  i32 { proc __llvm_cttz(i32,  bool) ->  i32 #foreign __llvm_core "llvm.cttz.i32"; return __llvm_cttz(i, false); }
proc trailing_zeros(i:  u64) ->  u64 { proc __llvm_cttz(u64,  bool) ->  u64 #foreign __llvm_core "llvm.cttz.i64"; return __llvm_cttz(i, false); }
proc trailing_zeros(i:  i64) ->  i64 { proc __llvm_cttz(i64,  bool) ->  i64 #foreign __llvm_core "llvm.cttz.i64"; return __llvm_cttz(i, false); }
proc trailing_zeros(i: u128) -> u128 { proc __llvm_cttz(u128, bool) -> u128 #foreign __llvm_core "llvm.cttz.i128";return __llvm_cttz(i, false); }
proc trailing_zeros(i: i128) -> i128 { proc __llvm_cttz(i128, bool) -> i128 #foreign __llvm_core "llvm.cttz.i128";return __llvm_cttz(i, false); }
proc trailing_zeros(i: uint) -> uint { when size_of(uint) == size_of(u32) { return uint(trailing_zeros(u32(i))); } else { return uint(trailing_zeros(u64(i))); } }
proc trailing_zeros(i:  int) ->  int { when size_of(int)  == size_of(i32) { return  int(trailing_zeros(i32(i))); } else { return  int(trailing_zeros(i64(i))); } }


proc reverse_bits(i:   u8) ->   u8 { proc __llvm_bitreverse(u8)   ->   u8 #foreign __llvm_core "llvm.bitreverse.i8";  return __llvm_bitreverse(i); }
proc reverse_bits(i:   i8) ->   i8 { proc __llvm_bitreverse(i8)   ->   i8 #foreign __llvm_core "llvm.bitreverse.i8";  return __llvm_bitreverse(i); }
proc reverse_bits(i:  u16) ->  u16 { proc __llvm_bitreverse(u16)  ->  u16 #foreign __llvm_core "llvm.bitreverse.i16"; return __llvm_bitreverse(i); }
proc reverse_bits(i:  i16) ->  i16 { proc __llvm_bitreverse(i16)  ->  i16 #foreign __llvm_core "llvm.bitreverse.i16"; return __llvm_bitreverse(i); }
proc reverse_bits(i:  u32) ->  u32 { proc __llvm_bitreverse(u32)  ->  u32 #foreign __llvm_core "llvm.bitreverse.i32"; return __llvm_bitreverse(i); }
proc reverse_bits(i:  i32) ->  i32 { proc __llvm_bitreverse(i32)  ->  i32 #foreign __llvm_core "llvm.bitreverse.i32"; return __llvm_bitreverse(i); }
proc reverse_bits(i:  u64) ->  u64 { proc __llvm_bitreverse(u64)  ->  u64 #foreign __llvm_core "llvm.bitreverse.i64"; return __llvm_bitreverse(i); }
proc reverse_bits(i:  i64) ->  i64 { proc __llvm_bitreverse(i64)  ->  i64 #foreign __llvm_core "llvm.bitreverse.i64"; return __llvm_bitreverse(i); }
proc reverse_bits(i: u128) -> u128 { proc __llvm_bitreverse(u128) -> u128 #foreign __llvm_core "llvm.bitreverse.i128";return __llvm_bitreverse(i); }
proc reverse_bits(i: i128) -> i128 { proc __llvm_bitreverse(i128) -> i128 #foreign __llvm_core "llvm.bitreverse.i128";return __llvm_bitreverse(i); }
proc reverse_bits(i: uint) -> uint { when size_of(uint) == size_of(u32) { return uint(reverse_bits(u32(i))); } else { return uint(reverse_bits(u64(i))); } }
proc reverse_bits(i:  int) ->  int { when size_of(int)  == size_of(i32) { return  int(reverse_bits(i32(i))); } else { return  int(reverse_bits(i64(i))); } }


proc byte_swap(u16)  ->  u16 #foreign __llvm_core "llvm.bswap.i16";
proc byte_swap(i16)  ->  i16 #foreign __llvm_core "llvm.bswap.i16";
proc byte_swap(u32)  ->  u32 #foreign __llvm_core "llvm.bswap.i32";
proc byte_swap(i32)  ->  i32 #foreign __llvm_core "llvm.bswap.i32";
proc byte_swap(u64)  ->  u64 #foreign __llvm_core "llvm.bswap.i64";
proc byte_swap(i64)  ->  i64 #foreign __llvm_core "llvm.bswap.i64";
proc byte_swap(u128) -> u128 #foreign __llvm_core "llvm.bswap.i128";
proc byte_swap(i128) -> i128 #foreign __llvm_core "llvm.bswap.i128";
proc byte_swap(i: uint) -> uint { when size_of(uint) == size_of(u32) { return uint(byte_swap(u32(i))); } else { return uint(byte_swap(u64(i))); } }
proc byte_swap(i:  int) ->  int { when size_of(int)  == size_of(i32) { return  int(byte_swap(i32(i))); } else { return  int(byte_swap(i64(i))); } }


proc from_be(i:   u8) ->   u8 { return i; }
proc from_be(i:   i8) ->   i8 { return i; }
proc from_be(i:  u16) ->  u16 { when ODIN_ENDIAN == "big" { return i; } else { return byte_swap(i); } }
proc from_be(i:  i16) ->  i16 { when ODIN_ENDIAN == "big" { return i; } else { return byte_swap(i); } }
proc from_be(i:  u32) ->  u32 { when ODIN_ENDIAN == "big" { return i; } else { return byte_swap(i); } }
proc from_be(i:  i32) ->  i32 { when ODIN_ENDIAN == "big" { return i; } else { return byte_swap(i); } }
proc from_be(i:  u64) ->  u64 { when ODIN_ENDIAN == "big" { return i; } else { return byte_swap(i); } }
proc from_be(i:  i64) ->  i64 { when ODIN_ENDIAN == "big" { return i; } else { return byte_swap(i); } }
proc from_be(i: u128) -> u128 { when ODIN_ENDIAN == "big" { return i; } else { return byte_swap(i); } }
proc from_be(i: i128) -> i128 { when ODIN_ENDIAN == "big" { return i; } else { return byte_swap(i); } }
proc from_be(i: uint) -> uint { when ODIN_ENDIAN == "big" { return i; } else { return byte_swap(i); } }
proc from_be(i:  int) ->  int { when ODIN_ENDIAN == "big" { return i; } else { return byte_swap(i); } }

proc from_le(i:   u8) ->   u8 { return i; }
proc from_le(i:   i8) ->   i8 { return i; }
proc from_le(i:  u16) ->  u16 { when ODIN_ENDIAN == "little" { return i; } else { return byte_swap(i); } }
proc from_le(i:  i16) ->  i16 { when ODIN_ENDIAN == "little" { return i; } else { return byte_swap(i); } }
proc from_le(i:  u32) ->  u32 { when ODIN_ENDIAN == "little" { return i; } else { return byte_swap(i); } }
proc from_le(i:  i32) ->  i32 { when ODIN_ENDIAN == "little" { return i; } else { return byte_swap(i); } }
proc from_le(i:  u64) ->  u64 { when ODIN_ENDIAN == "little" { return i; } else { return byte_swap(i); } }
proc from_le(i:  i64) ->  i64 { when ODIN_ENDIAN == "little" { return i; } else { return byte_swap(i); } }
proc from_le(i: u128) -> u128 { when ODIN_ENDIAN == "little" { return i; } else { return byte_swap(i); } }
proc from_le(i: i128) -> i128 { when ODIN_ENDIAN == "little" { return i; } else { return byte_swap(i); } }
proc from_le(i: uint) -> uint { when ODIN_ENDIAN == "little" { return i; } else { return byte_swap(i); } }
proc from_le(i:  int) ->  int { when ODIN_ENDIAN == "little" { return i; } else { return byte_swap(i); } }

proc to_be(i:   u8) ->   u8 { return i; }
proc to_be(i:   i8) ->   i8 { return i; }
proc to_be(i:  u16) ->  u16 { when ODIN_ENDIAN == "big" { return i; } else { return byte_swap(i); } }
proc to_be(i:  i16) ->  i16 { when ODIN_ENDIAN == "big" { return i; } else { return byte_swap(i); } }
proc to_be(i:  u32) ->  u32 { when ODIN_ENDIAN == "big" { return i; } else { return byte_swap(i); } }
proc to_be(i:  i32) ->  i32 { when ODIN_ENDIAN == "big" { return i; } else { return byte_swap(i); } }
proc to_be(i:  u64) ->  u64 { when ODIN_ENDIAN == "big" { return i; } else { return byte_swap(i); } }
proc to_be(i:  i64) ->  i64 { when ODIN_ENDIAN == "big" { return i; } else { return byte_swap(i); } }
proc to_be(i: u128) -> u128 { when ODIN_ENDIAN == "big" { return i; } else { return byte_swap(i); } }
proc to_be(i: i128) -> i128 { when ODIN_ENDIAN == "big" { return i; } else { return byte_swap(i); } }
proc to_be(i: uint) -> uint { when ODIN_ENDIAN == "big" { return i; } else { return byte_swap(i); } }
proc to_be(i:  int) ->  int { when ODIN_ENDIAN == "big" { return i; } else { return byte_swap(i); } }


proc to_le(i:   u8) ->   u8 { return i; }
proc to_le(i:   i8) ->   i8 { return i; }
proc to_le(i:  u16) ->  u16 { when ODIN_ENDIAN == "little" { return i; } else { return byte_swap(i); } }
proc to_le(i:  i16) ->  i16 { when ODIN_ENDIAN == "little" { return i; } else { return byte_swap(i); } }
proc to_le(i:  u32) ->  u32 { when ODIN_ENDIAN == "little" { return i; } else { return byte_swap(i); } }
proc to_le(i:  i32) ->  i32 { when ODIN_ENDIAN == "little" { return i; } else { return byte_swap(i); } }
proc to_le(i:  u64) ->  u64 { when ODIN_ENDIAN == "little" { return i; } else { return byte_swap(i); } }
proc to_le(i:  i64) ->  i64 { when ODIN_ENDIAN == "little" { return i; } else { return byte_swap(i); } }
proc to_le(i: u128) -> u128 { when ODIN_ENDIAN == "little" { return i; } else { return byte_swap(i); } }
proc to_le(i: i128) -> i128 { when ODIN_ENDIAN == "little" { return i; } else { return byte_swap(i); } }
proc to_le(i: uint) -> uint { when ODIN_ENDIAN == "little" { return i; } else { return byte_swap(i); } }
proc to_le(i:  int) ->  int { when ODIN_ENDIAN == "little" { return i; } else { return byte_swap(i); } }


proc overflowing_add(lhs, rhs:   u8) -> (u8, bool)   { proc op(u8, u8)     -> (u8, bool)   #foreign __llvm_core "llvm.uadd.with.overflow.i8";   return op(lhs, rhs); }
proc overflowing_add(lhs, rhs:   i8) -> (i8, bool)   { proc op(i8, i8)     -> (i8, bool)   #foreign __llvm_core "llvm.sadd.with.overflow.i8";   return op(lhs, rhs); }
proc overflowing_add(lhs, rhs:  u16) -> (u16, bool)  { proc op(u16, u16)   -> (u16, bool)  #foreign __llvm_core "llvm.uadd.with.overflow.i16";  return op(lhs, rhs); }
proc overflowing_add(lhs, rhs:  i16) -> (i16, bool)  { proc op(i16, i16)   -> (i16, bool)  #foreign __llvm_core "llvm.sadd.with.overflow.i16";  return op(lhs, rhs); }
proc overflowing_add(lhs, rhs:  u32) -> (u32, bool)  { proc op(u32, u32)   -> (u32, bool)  #foreign __llvm_core "llvm.uadd.with.overflow.i32";  return op(lhs, rhs); }
proc overflowing_add(lhs, rhs:  i32) -> (i32, bool)  { proc op(i32, i32)   -> (i32, bool)  #foreign __llvm_core "llvm.sadd.with.overflow.i32";  return op(lhs, rhs); }
proc overflowing_add(lhs, rhs:  u64) -> (u64, bool)  { proc op(u64, u64)   -> (u64, bool)  #foreign __llvm_core "llvm.uadd.with.overflow.i64";  return op(lhs, rhs); }
proc overflowing_add(lhs, rhs:  i64) -> (i64, bool)  { proc op(i64, i64)   -> (i64, bool)  #foreign __llvm_core "llvm.sadd.with.overflow.i64";  return op(lhs, rhs); }
proc overflowing_add(lhs, rhs: u128) -> (u128, bool) { proc op(u128, u128) -> (u128, bool) #foreign __llvm_core "llvm.uadd.with.overflow.i128"; return op(lhs, rhs); }
proc overflowing_add(lhs, rhs: i128) -> (i128, bool) { proc op(i128, i128) -> (i128, bool) #foreign __llvm_core "llvm.sadd.with.overflow.i128"; return op(lhs, rhs); }
proc overflowing_add(lhs, rhs: uint) -> (uint, bool) {
	when size_of(uint) == size_of(u32) {
		var x, ok = overflowing_add(u32(lhs), u32(rhs));
		return uint(x), ok;
	} else {
		var x, ok = overflowing_add(u64(lhs), u64(rhs));
		return uint(x), ok;
	}
}
proc overflowing_add(lhs, rhs: int) -> (int, bool) {
	when size_of(int) == size_of(i32) {
		var x, ok = overflowing_add(i32(lhs), i32(rhs));
		return int(x), ok;
	} else {
		var x, ok = overflowing_add(i64(lhs), i64(rhs));
		return int(x), ok;
	}
}

proc overflowing_sub(lhs, rhs:   u8) -> (u8, bool)   { proc op(u8, u8)     -> (u8, bool)   #foreign __llvm_core "llvm.usub.with.overflow.i8";   return op(lhs, rhs); }
proc overflowing_sub(lhs, rhs:   i8) -> (i8, bool)   { proc op(i8, i8)     -> (i8, bool)   #foreign __llvm_core "llvm.ssub.with.overflow.i8";   return op(lhs, rhs); }
proc overflowing_sub(lhs, rhs:  u16) -> (u16, bool)  { proc op(u16, u16)   -> (u16, bool)  #foreign __llvm_core "llvm.usub.with.overflow.i16";  return op(lhs, rhs); }
proc overflowing_sub(lhs, rhs:  i16) -> (i16, bool)  { proc op(i16, i16)   -> (i16, bool)  #foreign __llvm_core "llvm.ssub.with.overflow.i16";  return op(lhs, rhs); }
proc overflowing_sub(lhs, rhs:  u32) -> (u32, bool)  { proc op(u32, u32)   -> (u32, bool)  #foreign __llvm_core "llvm.usub.with.overflow.i32";  return op(lhs, rhs); }
proc overflowing_sub(lhs, rhs:  i32) -> (i32, bool)  { proc op(i32, i32)   -> (i32, bool)  #foreign __llvm_core "llvm.ssub.with.overflow.i32";  return op(lhs, rhs); }
proc overflowing_sub(lhs, rhs:  u64) -> (u64, bool)  { proc op(u64, u64)   -> (u64, bool)  #foreign __llvm_core "llvm.usub.with.overflow.i64";  return op(lhs, rhs); }
proc overflowing_sub(lhs, rhs:  i64) -> (i64, bool)  { proc op(i64, i64)   -> (i64, bool)  #foreign __llvm_core "llvm.ssub.with.overflow.i64";  return op(lhs, rhs); }
proc overflowing_sub(lhs, rhs: u128) -> (u128, bool) { proc op(u128, u128) -> (u128, bool) #foreign __llvm_core "llvm.usub.with.overflow.i128"; return op(lhs, rhs); }
proc overflowing_sub(lhs, rhs: i128) -> (i128, bool) { proc op(i128, i128) -> (i128, bool) #foreign __llvm_core "llvm.ssub.with.overflow.i128"; return op(lhs, rhs); }
proc overflowing_sub(lhs, rhs: uint) -> (uint, bool) {
	when size_of(uint) == size_of(u32) {
		var x, ok = overflowing_sub(u32(lhs), u32(rhs));
		return uint(x), ok;
	} else {
		var x, ok = overflowing_sub(u64(lhs), u64(rhs));
		return uint(x), ok;
	}
}
proc overflowing_sub(lhs, rhs: int) -> (int, bool) {
	when size_of(int) == size_of(i32) {
		var x, ok = overflowing_sub(i32(lhs), i32(rhs));
		return int(x), ok;
	} else {
		var x, ok = overflowing_sub(i64(lhs), i64(rhs));
		return int(x), ok;
	}
}

proc overflowing_mul(lhs, rhs:   u8) -> (u8, bool)   { proc op(u8, u8)     -> (u8, bool)   #foreign __llvm_core "llvm.umul.with.overflow.i8";   return op(lhs, rhs); }
proc overflowing_mul(lhs, rhs:   i8) -> (i8, bool)   { proc op(i8, i8)     -> (i8, bool)   #foreign __llvm_core "llvm.smul.with.overflow.i8";   return op(lhs, rhs); }
proc overflowing_mul(lhs, rhs:  u16) -> (u16, bool)  { proc op(u16, u16)   -> (u16, bool)  #foreign __llvm_core "llvm.umul.with.overflow.i16";  return op(lhs, rhs); }
proc overflowing_mul(lhs, rhs:  i16) -> (i16, bool)  { proc op(i16, i16)   -> (i16, bool)  #foreign __llvm_core "llvm.smul.with.overflow.i16";  return op(lhs, rhs); }
proc overflowing_mul(lhs, rhs:  u32) -> (u32, bool)  { proc op(u32, u32)   -> (u32, bool)  #foreign __llvm_core "llvm.umul.with.overflow.i32";  return op(lhs, rhs); }
proc overflowing_mul(lhs, rhs:  i32) -> (i32, bool)  { proc op(i32, i32)   -> (i32, bool)  #foreign __llvm_core "llvm.smul.with.overflow.i32";  return op(lhs, rhs); }
proc overflowing_mul(lhs, rhs:  u64) -> (u64, bool)  { proc op(u64, u64)   -> (u64, bool)  #foreign __llvm_core "llvm.umul.with.overflow.i64";  return op(lhs, rhs); }
proc overflowing_mul(lhs, rhs:  i64) -> (i64, bool)  { proc op(i64, i64)   -> (i64, bool)  #foreign __llvm_core "llvm.smul.with.overflow.i64";  return op(lhs, rhs); }
proc overflowing_mul(lhs, rhs: u128) -> (u128, bool) { proc op(u128, u128) -> (u128, bool) #foreign __llvm_core "llvm.umul.with.overflow.i128"; return op(lhs, rhs); }
proc overflowing_mul(lhs, rhs: i128) -> (i128, bool) { proc op(i128, i128) -> (i128, bool) #foreign __llvm_core "llvm.smul.with.overflow.i128"; return op(lhs, rhs); }
proc overflowing_mul(lhs, rhs: uint) -> (uint, bool) {
	when size_of(uint) == size_of(u32) {
		var x, ok = overflowing_mul(u32(lhs), u32(rhs));
		return uint(x), ok;
	} else {
		var x, ok = overflowing_mul(u64(lhs), u64(rhs));
		return uint(x), ok;
	}
}
proc overflowing_mul(lhs, rhs: int) -> (int, bool) {
	when size_of(int) == size_of(i32) {
		var x, ok = overflowing_mul(i32(lhs), i32(rhs));
		return int(x), ok;
	} else {
		var x, ok = overflowing_mul(i64(lhs), i64(rhs));
		return int(x), ok;
	}
}

proc is_power_of_two(i:   u8) -> bool { return i > 0 && (i & (i-1)) == 0; }
proc is_power_of_two(i:   i8) -> bool { return i > 0 && (i & (i-1)) == 0; }
proc is_power_of_two(i:  u16) -> bool { return i > 0 && (i & (i-1)) == 0; }
proc is_power_of_two(i:  i16) -> bool { return i > 0 && (i & (i-1)) == 0; }
proc is_power_of_two(i:  u32) -> bool { return i > 0 && (i & (i-1)) == 0; }
proc is_power_of_two(i:  i32) -> bool { return i > 0 && (i & (i-1)) == 0; }
proc is_power_of_two(i:  u64) -> bool { return i > 0 && (i & (i-1)) == 0; }
proc is_power_of_two(i:  i64) -> bool { return i > 0 && (i & (i-1)) == 0; }
proc is_power_of_two(i: u128) -> bool { return i > 0 && (i & (i-1)) == 0; }
proc is_power_of_two(i: i128) -> bool { return i > 0 && (i & (i-1)) == 0; }
proc is_power_of_two(i: uint) -> bool { return i > 0 && (i & (i-1)) == 0; }
proc is_power_of_two(i:  int) -> bool { return i > 0 && (i & (i-1)) == 0; }
