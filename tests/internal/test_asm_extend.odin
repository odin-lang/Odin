package test_internal

import "core:testing"

// The sign/zero-extend family is the only one whose two operands differ in width, so its AT&T
// mnemonic names both -- `movsx` from i8 to i32 is `movsbl`. Emitting the name plus a single width
// suffix produced `movsxl`, which no assembler has, so none of these forms could be built
@(test)
asm_extend_mnemonics :: proc(t: ^testing.T) {
	when ODIN_ARCH == .amd64 {
		sx_8_16  :: asm(a: i8)  -> (r: i16) { movsx r, a; }
		sx_8_32  :: asm(a: i8)  -> (r: i32) { movsx r, a; }
		sx_8_64  :: asm(a: i8)  -> (r: i64) { movsx r, a; }
		sx_16_32 :: asm(a: i16) -> (r: i32) { movsx r, a; }
		sx_16_64 :: asm(a: i16) -> (r: i64) { movsx r, a; }
		zx_8_16  :: asm(a: u8)  -> (r: u16) { movzx r, a; }
		zx_8_32  :: asm(a: u8)  -> (r: u32) { movzx r, a; }
		zx_8_64  :: asm(a: u8)  -> (r: u64) { movzx r, a; }
		zx_16_32 :: asm(a: u16) -> (r: u32) { movzx r, a; }
		zx_16_64 :: asm(a: u16) -> (r: u64) { movzx r, a; }
		sxd      :: asm(a: i32) -> (r: i64) { movsxd r, a; }

		testing.expect_value(t, sx_8_16(-1),        i16(-1))
		testing.expect_value(t, sx_8_32(-1),        i32(-1))
		testing.expect_value(t, sx_8_64(-1),        i64(-1))
		testing.expect_value(t, sx_16_32(-300),     i32(-300))
		testing.expect_value(t, sx_16_64(-300),     i64(-300))
		testing.expect_value(t, sxd(-123456),       i64(-123456))

		testing.expect_value(t, zx_8_16(0xFF),      u16(255))
		testing.expect_value(t, zx_8_32(0xFF),      u32(255))
		testing.expect_value(t, zx_8_64(0xFF),      u64(255))
		testing.expect_value(t, zx_16_32(0xFFFF),   u32(65535))
		testing.expect_value(t, zx_16_64(0xFFFF),   u64(65535))

		// positive values too, so a mnemonic that merely truncates cannot pass
		testing.expect_value(t, sx_8_32(127),       i32(127))
		testing.expect_value(t, zx_8_32(1),         u32(1))
	}
}
