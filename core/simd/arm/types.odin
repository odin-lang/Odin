#+build arm64,arm32
package simd_arm

// Type aliases to match `arm_neon.h`.
uint32_t :: u32

uint8x16_t :: #simd[16]u8
uint32x4_t :: #simd[4]u32
uint64x2_t :: #simd[2]u64
