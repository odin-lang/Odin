package rexcode_mos65816

// =============================================================================
// W65C816S REGISTERS
// =============================================================================
//
//   A      accumulator   (8 or 16 bits per M flag)
//   X, Y   index regs    (8 or 16 bits per X flag)
//   S      stack pointer (8 in emulation, 16 in native)
//   D      direct page   (16-bit; replaces the fixed zero page -- "DP" can sit
//                         anywhere in bank 0)
//   DBR    data bank     (8-bit; high byte for data accesses)
//   PBR    program bank  (8-bit; high byte of PC)
//   P      status flags  (now includes M=mem-width, X=index-width, E=emulation)
//   PC     program counter
//
// Like 6502, almost no instruction names a register explicitly -- the
// register file is here mostly for completeness and for accumulator-implied
// ops (ASL A, ROL A, ...).

Register :: distinct u16

REG_NONE :: 0x0000
REG_GP   :: 0x0100   // A / X / Y / S / D
REG_SYS  :: 0x0200   // DBR / PBR / P / PC

NONE :: Register(0xFFFF)

A   :: Register(REG_GP  | 0)
X   :: Register(REG_GP  | 1)
Y   :: Register(REG_GP  | 2)
S   :: Register(REG_GP  | 3)
D   :: Register(REG_GP  | 4)
DBR :: Register(REG_SYS | 0)
PBR :: Register(REG_SYS | 1)
P   :: Register(REG_SYS | 2)
PC  :: Register(REG_SYS | 3)

GP :: enum u8 { A = 0, X = 1, Y = 2, S = 3, D = 4 }

@(require_results) reg_hw    :: #force_inline proc "contextless" (r: Register) -> u8  { return u8(r) & 0xFF }
@(require_results) reg_class :: #force_inline proc "contextless" (r: Register) -> u16 { return u16(r) & 0xFF00 }
