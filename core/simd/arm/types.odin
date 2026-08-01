#+build arm64,arm32
package simd_arm

// Type aliases to match `arm_neon.h`.
uint8_t  :: u8
uint16_t :: u16
uint32_t :: u32
uint64_t :: u64

poly8_t   :: u8
poly16_t  :: u16
poly64_t  :: u64
poly128_t :: u128

uint8x16_t :: #simd[16]u8
uint32x4_t :: #simd[4]u32
uint64x2_t :: #simd[2]u64

int32_t    :: i32
int8x16_t  :: #simd[16]i8

poly8x8_t  :: #simd[8]poly8_t
poly8x16_t :: #simd[16]poly8_t
poly16x4_t :: #simd[4]poly16_t
poly16x8_t :: #simd[8]poly16_t
poly64x1_t :: #simd[1]poly64_t
poly64x2_t :: #simd[2]poly64_t
