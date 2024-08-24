package simd

import "base:builtin"
import "base:intrinsics"

// IS_EMULATED is true iff the compile-time target lacks hardware support
// for at least 128-bit SIMD.
IS_EMULATED :: true when (ODIN_ARCH == .amd64 || ODIN_ARCH == .i386) && !intrinsics.has_target_feature("sse2") else
	true when (ODIN_ARCH == .arm64 || ODIN_ARCH == .arm32) && !intrinsics.has_target_feature("neon") else
	true when (ODIN_ARCH == .wasm64p32 || ODIN_ARCH == .wasm32) && !intrinsics.has_target_feature("simd128") else
	true when (ODIN_ARCH == .riscv64) && !intrinsics.has_target_feature("v") else
	false

// 128-bit vector aliases
u8x16 :: #simd[16]u8
i8x16 :: #simd[16]i8
u16x8 :: #simd[8]u16
i16x8 :: #simd[8]i16
u32x4 :: #simd[4]u32
i32x4 :: #simd[4]i32
u64x2 :: #simd[2]u64
i64x2 :: #simd[2]i64
f32x4 :: #simd[4]f32
f64x2 :: #simd[2]f64

boolx16 :: #simd[16]bool
b8x16   :: #simd[16]b8
b16x8   :: #simd[8]b16
b32x4   :: #simd[4]b32
b64x2   :: #simd[2]b64

// 256-bit vector aliases
u8x32  :: #simd[32]u8
i8x32  :: #simd[32]i8
u16x16 :: #simd[16]u16
i16x16 :: #simd[16]i16
u32x8  :: #simd[8]u32
i32x8  :: #simd[8]i32
u64x4  :: #simd[4]u64
i64x4  :: #simd[4]i64
f32x8  :: #simd[8]f32
f64x4  :: #simd[4]f64

boolx32 :: #simd[32]bool
b8x32   :: #simd[32]b8
b16x16  :: #simd[16]b16
b32x8   :: #simd[8]b32
b64x4   :: #simd[4]b64

// 512-bit vector aliases
u8x64  :: #simd[64]u8
i8x64  :: #simd[64]i8
u16x32 :: #simd[32]u16
i16x32 :: #simd[32]i16
u32x16 :: #simd[16]u32
i32x16 :: #simd[16]i32
u64x8  :: #simd[8]u64
i64x8  :: #simd[8]i64
f32x16 :: #simd[16]f32
f64x8  :: #simd[8]f64

boolx64 :: #simd[64]bool
b8x64   :: #simd[64]b8
b16x32  :: #simd[32]b16
b32x16  :: #simd[16]b32
b64x8   :: #simd[8]b64


add :: intrinsics.simd_add
sub :: intrinsics.simd_sub
mul :: intrinsics.simd_mul
div :: intrinsics.simd_div // floats only

// Keeps Odin's Behaviour
// (x << y) if y <= mask else 0
shl :: intrinsics.simd_shl
shr :: intrinsics.simd_shr

// Similar to C's Behaviour
// x << (y & mask)
shl_masked :: intrinsics.simd_shl_masked
shr_masked :: intrinsics.simd_shr_masked

// Saturation Arithmetic
saturating_add :: intrinsics.simd_saturating_add
saturating_sub :: intrinsics.simd_saturating_sub

bit_and     :: intrinsics.simd_bit_and
bit_or      :: intrinsics.simd_bit_or
bit_xor     :: intrinsics.simd_bit_xor
bit_and_not :: intrinsics.simd_bit_and_not

neg :: intrinsics.simd_neg

abs   :: intrinsics.simd_abs

min   :: intrinsics.simd_min
max   :: intrinsics.simd_max
clamp :: intrinsics.simd_clamp

// Return an unsigned integer of the same size as the input type
// NOT A BOOLEAN
// element-wise:
//     false => 0x00...00
//     true  => 0xff...ff
lanes_eq :: intrinsics.simd_lanes_eq
lanes_ne :: intrinsics.simd_lanes_ne
lanes_lt :: intrinsics.simd_lanes_lt
lanes_le :: intrinsics.simd_lanes_le
lanes_gt :: intrinsics.simd_lanes_gt
lanes_ge :: intrinsics.simd_lanes_ge


// Gather and Scatter intrinsics
gather  :: intrinsics.simd_gather
scatter :: intrinsics.simd_scatter
masked_load  :: intrinsics.simd_masked_load
masked_store :: intrinsics.simd_masked_store
masked_expand_load    :: intrinsics.simd_masked_expand_load
masked_compress_store :: intrinsics.simd_masked_compress_store

// extract :: proc(a: #simd[N]T, idx: uint) -> T
extract :: intrinsics.simd_extract
// replace :: proc(a: #simd[N]T, idx: uint, elem: T) -> #simd[N]T
replace :: intrinsics.simd_replace

reduce_add_ordered :: intrinsics.simd_reduce_add_ordered
reduce_mul_ordered :: intrinsics.simd_reduce_mul_ordered
reduce_min         :: intrinsics.simd_reduce_min
reduce_max         :: intrinsics.simd_reduce_max
reduce_and         :: intrinsics.simd_reduce_and
reduce_or          :: intrinsics.simd_reduce_or
reduce_xor         :: intrinsics.simd_reduce_xor

reduce_any         :: intrinsics.simd_reduce_any
reduce_all         :: intrinsics.simd_reduce_all

// swizzle :: proc(a: #simd[N]T, indices: ..int) -> #simd[len(indices)]T
swizzle :: builtin.swizzle

// shuffle :: proc(a, b: #simd[N]T, indices: #simd[max 2*N]u32) -> #simd[len(indices)]T
shuffle :: intrinsics.simd_shuffle

// select :: proc(cond: #simd[N]boolean_or_integer, true, false: #simd[N]T) -> #simd[N]T
select :: intrinsics.simd_select


sqrt    :: intrinsics.sqrt
ceil    :: intrinsics.simd_ceil
floor   :: intrinsics.simd_floor
trunc   :: intrinsics.simd_trunc
nearest :: intrinsics.simd_nearest

to_bits :: intrinsics.simd_to_bits

lanes_reverse :: intrinsics.simd_lanes_reverse

lanes_rotate_left  :: intrinsics.simd_lanes_rotate_left
lanes_rotate_right :: intrinsics.simd_lanes_rotate_right

count_ones           :: intrinsics.count_ones
count_zeros          :: intrinsics.count_zeros
count_trailing_zeros :: intrinsics.count_trailing_zeros
count_leading_zeros  :: intrinsics.count_leading_zeros
reverse_bits         :: intrinsics.reverse_bits

fused_mul_add :: intrinsics.fused_mul_add
fma           :: intrinsics.fused_mul_add

to_array_ptr :: #force_inline proc "contextless" (v: ^#simd[$LANES]$E) -> ^[LANES]E {
	return (^[LANES]E)(v)
}
to_array :: #force_inline proc "contextless" (v: #simd[$LANES]$E) -> [LANES]E {
	return transmute([LANES]E)(v)
}
from_array :: #force_inline proc "contextless" (v: $A/[$LANES]$E) -> #simd[LANES]E {
	return transmute(#simd[LANES]E)v
}

from_slice :: proc($T: typeid/#simd[$LANES]$E, slice: []E) -> T {
	assert(len(slice) >= LANES, "slice length must be a least the number of lanes")
	array: [LANES]E
	#no_bounds_check for i in 0..<LANES {
		array[i] = slice[i]
	}
	return transmute(T)array
}

bit_not :: #force_inline proc "contextless" (v: $T/#simd[$LANES]$E) -> T where intrinsics.type_is_integer(E) {
	return xor(v, T(~E(0)))
}

copysign :: #force_inline proc "contextless" (v, sign: $T/#simd[$LANES]$E) -> T where intrinsics.type_is_float(E) {
	neg_zero := to_bits(T(-0.0))
	sign_bit := to_bits(sign) & neg_zero
	magnitude := to_bits(v) &~ neg_zero
	return transmute(T)(sign_bit|magnitude)
}

signum :: #force_inline proc "contextless" (v: $T/#simd[$LANES]$E) -> T where intrinsics.type_is_float(E) {
	is_nan := lanes_ne(v, v)
	return select(is_nan, v, copysign(T(1), v))
}

recip :: #force_inline proc "contextless" (v: $T/#simd[$LANES]$E) -> T where intrinsics.type_is_float(E) {
	return T(1) / v
}
