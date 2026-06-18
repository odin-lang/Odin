// rexcode  ·  Brendan Punsky (dotbmp@github), original author

package rexcode_mos6502

// =============================================================================
// MOS 6502 REGISTERS
// =============================================================================
//
// The 6502 has a famously sparse register file:
//   A      accumulator (8-bit)
//   X, Y   index registers (8-bit)
//   S      stack pointer (8-bit; stack is page 1 = $0100..$01FF)
//   P      processor status flags
//   PC     program counter (16-bit)
//
// For shape parity with `mips/` and `x86/` we keep the `distinct u16`
// register layout (class in the high byte, hardware index in the low byte)
// even though almost no opcode references registers explicitly — most are
// implied operands.

Register :: distinct u16

REG_NONE :: 0x0000
REG_GP   :: 0x0100   // A / X / Y
REG_SYS  :: 0x0200   // S / P / PC

NONE :: Register(0xFFFF)

A  :: Register(REG_GP  | 0)
X  :: Register(REG_GP  | 1)
Y  :: Register(REG_GP  | 2)
S  :: Register(REG_SYS | 0)
P  :: Register(REG_SYS | 1)
PC :: Register(REG_SYS | 2)

GP :: enum u8 { A = 0, X = 1, Y = 2 }

@(require_results)
reg_hw :: #force_inline proc "contextless" (r: Register) -> u8 {
	return u8(r) & 0xFF
}

@(require_results)
reg_class :: #force_inline proc "contextless" (r: Register) -> u16 {
	return u16(r) & 0xFF00
}

@(require_results)
reg_is_gp :: #force_inline proc "contextless" (r: Register) -> bool {
	return reg_class(r) == REG_GP
}
