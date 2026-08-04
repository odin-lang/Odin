#+build arm64,arm32
package simd_arm

// Type aliases to match `arm_neon.h`.
int8_t  :: i8
int16_t :: i16
int32_t :: i32
int64_t :: i64

uint8_t  :: u8
uint16_t :: u16
uint32_t :: u32
uint64_t :: u64

poly8_t   :: u8
poly16_t  :: u16
poly64_t  :: u64
poly128_t :: u128

int8x8_t  :: #simd[8]int8_t
int8x16_t :: #simd[16]int8_t
int16x4_t :: #simd[4]int16_t
int16x8_t :: #simd[8]int16_t
int32x2_t :: #simd[2]int32_t
int32x4_t :: #simd[4]int32_t
int64x1_t :: #simd[1]int64_t
int64x2_t :: #simd[2]int64_t

uint8x8_t  :: #simd[8]uint8_t
uint8x16_t :: #simd[16]uint8_t
uint16x4_t :: #simd[4]uint16_t
uint16x8_t :: #simd[8]uint16_t
uint32x2_t :: #simd[2]uint32_t
uint32x4_t :: #simd[4]uint32_t
uint64x1_t :: #simd[1]uint64_t
uint64x2_t :: #simd[2]uint64_t

poly8x8_t  :: #simd[8]poly8_t
poly8x16_t :: #simd[16]poly8_t
poly16x4_t :: #simd[4]poly16_t
poly16x8_t :: #simd[8]poly16_t
poly64x1_t :: #simd[1]poly64_t
poly64x2_t :: #simd[2]poly64_t
