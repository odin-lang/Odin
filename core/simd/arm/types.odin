#+build arm64,arm32
package simd_arm

// Type aliases to match `arm_neon.h`.
uint8_t  :: u8
uint16_t :: u16
uint32_t :: u32
uint64_t :: u64

uint8x16_t :: #simd[16]u8
uint32x4_t :: #simd[4]u32
uint64x2_t :: #simd[2]u64
