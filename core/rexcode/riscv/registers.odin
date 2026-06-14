package rexcode_riscv

// =============================================================================
// RISC-V REGISTERS
// =============================================================================
//
// 32 general-purpose integer registers (x0..x31) and 32 floating-point
// registers (f0..f31). x0 is hardwired to zero. Both files use the same
// 5-bit hardware index in instructions; the operand kind tag plus the
// register class disambiguate.

Register :: distinct u16

REG_NONE :: 0x0000
REG_GPR  :: 0x0100   // x0..x31
REG_FPR  :: 0x0200   // f0..f31

NONE :: Register(0xFFFF)

reg_hw    :: #force_inline proc "contextless" (r: Register) -> u8  { return u8(r) & 0x1F }
reg_class :: #force_inline proc "contextless" (r: Register) -> u16 { return u16(r) & 0xFF00 }

reg_is_gpr :: #force_inline proc "contextless" (r: Register) -> bool { return reg_class(r) == REG_GPR }
reg_is_fpr :: #force_inline proc "contextless" (r: Register) -> bool { return reg_class(r) == REG_FPR }

gpr_from_num :: #force_inline proc "contextless" (n: u8) -> Register {
	return n < 32 ? Register(REG_GPR | u16(n)) : NONE
}
fpr_from_num :: #force_inline proc "contextless" (n: u8) -> Register {
	return n < 32 ? Register(REG_FPR | u16(n)) : NONE
}

// -----------------------------------------------------------------------------
// GPR ABI names (x0 = zero, x1 = ra, x2 = sp, ...)
// -----------------------------------------------------------------------------

GPR :: enum u8 {
	ZERO = 0,  RA = 1,  SP = 2,  GP = 3,  TP = 4,
	T0 = 5,    T1 = 6,  T2 = 7,
	S0 = 8,    S1 = 9,
	A0 = 10,   A1 = 11, A2 = 12, A3 = 13, A4 = 14, A5 = 15, A6 = 16, A7 = 17,
	S2 = 18,   S3 = 19, S4 = 20, S5 = 21, S6 = 22, S7 = 23, S8 = 24, S9 = 25,
	S10 = 26,  S11 = 27,
	T3 = 28,   T4 = 29, T5 = 30, T6 = 31,
}

FP :: GPR(8)   // S0 doubles as frame pointer in the ABI

ZERO :: Register(REG_GPR | 0)
RA   :: Register(REG_GPR | 1)
SP   :: Register(REG_GPR | 2)
GP   :: Register(REG_GPR | 3)
TP   :: Register(REG_GPR | 4)
T0   :: Register(REG_GPR | 5);   T1 :: Register(REG_GPR | 6);   T2 :: Register(REG_GPR | 7)
S0   :: Register(REG_GPR | 8);   S1 :: Register(REG_GPR | 9)
A0   :: Register(REG_GPR | 10);  A1 :: Register(REG_GPR | 11);  A2 :: Register(REG_GPR | 12);  A3 :: Register(REG_GPR | 13)
A4   :: Register(REG_GPR | 14);  A5 :: Register(REG_GPR | 15);  A6 :: Register(REG_GPR | 16);  A7 :: Register(REG_GPR | 17)
S2   :: Register(REG_GPR | 18);  S3 :: Register(REG_GPR | 19);  S4 :: Register(REG_GPR | 20);  S5 :: Register(REG_GPR | 21)
S6   :: Register(REG_GPR | 22);  S7 :: Register(REG_GPR | 23);  S8 :: Register(REG_GPR | 24);  S9 :: Register(REG_GPR | 25)
S10  :: Register(REG_GPR | 26);  S11 :: Register(REG_GPR | 27)
T3   :: Register(REG_GPR | 28);  T4 :: Register(REG_GPR | 29);  T5 :: Register(REG_GPR | 30);  T6 :: Register(REG_GPR | 31)

// -----------------------------------------------------------------------------
// FPR ABI names (f0 = ft0, ..., f8 = fs0, ..., f10 = fa0, ..., f28 = ft8, ...)
// -----------------------------------------------------------------------------

FPR :: enum u8 {
	FT0 = 0,  FT1 = 1,  FT2 = 2,  FT3 = 3,  FT4 = 4,  FT5 = 5,  FT6 = 6,  FT7 = 7,
	FS0 = 8,  FS1 = 9,
	FA0 = 10, FA1 = 11, FA2 = 12, FA3 = 13, FA4 = 14, FA5 = 15, FA6 = 16, FA7 = 17,
	FS2 = 18, FS3 = 19, FS4 = 20, FS5 = 21, FS6 = 22, FS7 = 23, FS8 = 24, FS9 = 25,
	FS10 = 26, FS11 = 27,
	FT8 = 28, FT9 = 29, FT10 = 30, FT11 = 31,
}

FT0  :: Register(REG_FPR | 0);  FT1  :: Register(REG_FPR | 1);  FT2  :: Register(REG_FPR | 2);  FT3  :: Register(REG_FPR | 3)
FT4  :: Register(REG_FPR | 4);  FT5  :: Register(REG_FPR | 5);  FT6  :: Register(REG_FPR | 6);  FT7  :: Register(REG_FPR | 7)
FS0  :: Register(REG_FPR | 8);  FS1  :: Register(REG_FPR | 9)
FA0  :: Register(REG_FPR | 10); FA1  :: Register(REG_FPR | 11); FA2  :: Register(REG_FPR | 12); FA3  :: Register(REG_FPR | 13)
FA4  :: Register(REG_FPR | 14); FA5  :: Register(REG_FPR | 15); FA6  :: Register(REG_FPR | 16); FA7  :: Register(REG_FPR | 17)
FS2  :: Register(REG_FPR | 18); FS3  :: Register(REG_FPR | 19); FS4  :: Register(REG_FPR | 20); FS5  :: Register(REG_FPR | 21)
FS6  :: Register(REG_FPR | 22); FS7  :: Register(REG_FPR | 23); FS8  :: Register(REG_FPR | 24); FS9  :: Register(REG_FPR | 25)
FS10 :: Register(REG_FPR | 26); FS11 :: Register(REG_FPR | 27)
FT8  :: Register(REG_FPR | 28); FT9  :: Register(REG_FPR | 29); FT10 :: Register(REG_FPR | 30); FT11 :: Register(REG_FPR | 31)
