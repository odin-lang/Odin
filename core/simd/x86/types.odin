//+build amd64
package simd_amd64

bf16 :: u16

__m128i :: #simd[2]i64
__m128  :: #simd[4]f32
__m128d :: #simd[2]f64

__m256i :: #simd[4]i64
__m256  :: #simd[8]f32
__m256d :: #simd[4]f64

__m512i :: #simd[8]i64
__m512  :: #simd[16]f32
__m512d :: #simd[8]f64

__m128bh :: #simd[8]bf16
__m256bh :: #simd[16]bf16
__m512bh :: #simd[32]bf16


/// The `__mmask64` type used in AVX-512 intrinsics, a 64-bit integer
__mmask64 :: u64

/// The `__mmask32` type used in AVX-512 intrinsics, a 32-bit integer
__mmask32 :: u32

/// The `__mmask16` type used in AVX-512 intrinsics, a 16-bit integer
__mmask16 :: u16

/// The `__mmask8` type used in AVX-512 intrinsics, a 8-bit integer
__mmask8 :: u8

/// The `_MM_CMPINT_ENUM` type used to specify comparison operations in AVX-512 intrinsics.
_MM_CMPINT_ENUM :: i32

/// The `MM_MANTISSA_NORM_ENUM` type used to specify mantissa normalized operations in AVX-512 intrinsics.
_MM_MANTISSA_NORM_ENUM :: i32

/// The `MM_MANTISSA_SIGN_ENUM` type used to specify mantissa signed operations in AVX-512 intrinsics.
_MM_MANTISSA_SIGN_ENUM :: i32

_MM_PERM_ENUM :: i32