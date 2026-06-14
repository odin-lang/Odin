package rexcode_mips

// =============================================================================
// MIPS REGISTERS
// =============================================================================
//
// Register encoding (distinct u16):
//   bits 0- 7  hardware number (0-31 for most classes; 0-127 for VFPU)
//   bits 8-15  class
//
// Sentinel: NONE = 0xFFFF.

Register :: distinct u16

REG_NONE  :: 0x0000
REG_GPR   :: 0x0100    // $0-$31 general-purpose
REG_FPR   :: 0x0200    // $f0-$f31 floating-point
REG_FCR   :: 0x0300    // FP control ($fcr0..$fcr31)
REG_CP0   :: 0x0400    // system control coprocessor 0 registers
REG_CP2D  :: 0x0500    // COP2 data register (GTE V*/MAC*/SXY*; VU vf*)
REG_CP2C  :: 0x0600    // COP2 control register
REG_HILO  :: 0x0700    // HI / LO multiply-divide accumulators
REG_VFPU  :: 0x0800    // PSP Allegrex VFPU (matrix-organised)
REG_MSA   :: 0x0900    // MIPS SIMD Architecture $w0-$w31 (128-bit vectors)

NONE :: Register(0xFFFF)

// -----------------------------------------------------------------------------
// GPR ($0-$31) -- typed enum + ABI-named constants
// -----------------------------------------------------------------------------

GPR :: enum u8 {
	ZERO = 0, AT = 1,
	V0 = 2,  V1 = 3,
	A0 = 4,  A1 = 5,  A2 = 6,  A3 = 7,
	T0 = 8,  T1 = 9,  T2 = 10, T3 = 11, T4 = 12, T5 = 13, T6 = 14, T7 = 15,
	S0 = 16, S1 = 17, S2 = 18, S3 = 19, S4 = 20, S5 = 21, S6 = 22, S7 = 23,
	T8 = 24, T9 = 25,
	K0 = 26, K1 = 27,
	GP = 28, SP = 29, FP = 30, RA = 31,
}

ZERO :: Register(REG_GPR | 0);   AT   :: Register(REG_GPR | 1)
V0   :: Register(REG_GPR | 2);   V1   :: Register(REG_GPR | 3)
A0   :: Register(REG_GPR | 4);   A1   :: Register(REG_GPR | 5)
A2   :: Register(REG_GPR | 6);   A3   :: Register(REG_GPR | 7)
T0   :: Register(REG_GPR | 8);   T1   :: Register(REG_GPR | 9)
T2   :: Register(REG_GPR | 10);  T3   :: Register(REG_GPR | 11)
T4   :: Register(REG_GPR | 12);  T5   :: Register(REG_GPR | 13)
T6   :: Register(REG_GPR | 14);  T7   :: Register(REG_GPR | 15)
S0   :: Register(REG_GPR | 16);  S1   :: Register(REG_GPR | 17)
S2   :: Register(REG_GPR | 18);  S3   :: Register(REG_GPR | 19)
S4   :: Register(REG_GPR | 20);  S5   :: Register(REG_GPR | 21)
S6   :: Register(REG_GPR | 22);  S7   :: Register(REG_GPR | 23)
T8   :: Register(REG_GPR | 24);  T9   :: Register(REG_GPR | 25)
K0   :: Register(REG_GPR | 26);  K1   :: Register(REG_GPR | 27)
GP   :: Register(REG_GPR | 28);  SP   :: Register(REG_GPR | 29)
FP   :: Register(REG_GPR | 30);  RA   :: Register(REG_GPR | 31)
S8   :: Register(REG_GPR | 30)   // alias of FP per the canonical o32/n32 ABIs

// -----------------------------------------------------------------------------
// FPR ($f0-$f31)
// -----------------------------------------------------------------------------

FPR :: enum u8 {
	F0=0,  F1=1,  F2=2,  F3=3,  F4=4,  F5=5,  F6=6,  F7=7,
	F8=8,  F9=9,  F10=10, F11=11, F12=12, F13=13, F14=14, F15=15,
	F16=16, F17=17, F18=18, F19=19, F20=20, F21=21, F22=22, F23=23,
	F24=24, F25=25, F26=26, F27=27, F28=28, F29=29, F30=30, F31=31,
}

F0  :: Register(REG_FPR | 0);   F1  :: Register(REG_FPR | 1)
F2  :: Register(REG_FPR | 2);   F3  :: Register(REG_FPR | 3)
F4  :: Register(REG_FPR | 4);   F5  :: Register(REG_FPR | 5)
F6  :: Register(REG_FPR | 6);   F7  :: Register(REG_FPR | 7)
F8  :: Register(REG_FPR | 8);   F9  :: Register(REG_FPR | 9)
F10 :: Register(REG_FPR | 10);  F11 :: Register(REG_FPR | 11)
F12 :: Register(REG_FPR | 12);  F13 :: Register(REG_FPR | 13)
F14 :: Register(REG_FPR | 14);  F15 :: Register(REG_FPR | 15)
F16 :: Register(REG_FPR | 16);  F17 :: Register(REG_FPR | 17)
F18 :: Register(REG_FPR | 18);  F19 :: Register(REG_FPR | 19)
F20 :: Register(REG_FPR | 20);  F21 :: Register(REG_FPR | 21)
F22 :: Register(REG_FPR | 22);  F23 :: Register(REG_FPR | 23)
F24 :: Register(REG_FPR | 24);  F25 :: Register(REG_FPR | 25)
F26 :: Register(REG_FPR | 26);  F27 :: Register(REG_FPR | 27)
F28 :: Register(REG_FPR | 28);  F29 :: Register(REG_FPR | 29)
F30 :: Register(REG_FPR | 30);  F31 :: Register(REG_FPR | 31)

// -----------------------------------------------------------------------------
// FP control ($fcr0..$fcr31; the meaningful ones)
// -----------------------------------------------------------------------------

FCR0  :: Register(REG_FCR | 0)    // FIR  (FP implementation/revision)
FCR25 :: Register(REG_FCR | 25)   // FCCR (FP condition codes, R2+)
FCR26 :: Register(REG_FCR | 26)   // FEXR (FP exceptions, R2+)
FCR28 :: Register(REG_FCR | 28)   // FENR (FP enables, R2+)
FCR31 :: Register(REG_FCR | 31)   // FCSR (FP control/status)

// -----------------------------------------------------------------------------
// CP0 (system control). MIPS R1: 32 registers; R2+: each can have selectors 0-7.
// -----------------------------------------------------------------------------

CP0_Reg :: enum u8 {
	INDEX    = 0,  RANDOM   = 1,  ENTRYLO0 = 2,  ENTRYLO1 = 3,
	CONTEXT  = 4,  PAGEMASK = 5,  WIRED    = 6,  HWRENA   = 7,
	BADVADDR = 8,  COUNT    = 9,  ENTRYHI  = 10, COMPARE  = 11,
	STATUS   = 12, CAUSE    = 13, EPC      = 14, PRID     = 15,
	CONFIG   = 16, LLADDR   = 17, WATCHLO  = 18, WATCHHI  = 19,
	XCONTEXT = 20,
	DEBUG    = 23, DEPC     = 24, PERFCNT  = 25,
	ERRCTL   = 26, CACHEERR = 27, TAGLO    = 28, TAGHI    = 29,
	ERROREPC = 30, DESAVE   = 31,
}

// -----------------------------------------------------------------------------
// PS1 GTE (COP2 data registers; accessed via MFC2/MTC2 with rd selecting these)
// -----------------------------------------------------------------------------

GTE_DataReg :: enum u8 {
	VXY0 = 0,  VZ0  = 1,  VXY1 = 2,  VZ1  = 3,  VXY2 = 4,  VZ2  = 5,
	RGBC = 6,  OTZ  = 7,
	IR0  = 8,  IR1  = 9,  IR2  = 10, IR3  = 11,
	SXY0 = 12, SXY1 = 13, SXY2 = 14, SXYP = 15,
	SZ0  = 16, SZ1  = 17, SZ2  = 18, SZ3  = 19,
	RGB0 = 20, RGB1 = 21, RGB2 = 22, RES1 = 23,
	MAC0 = 24, MAC1 = 25, MAC2 = 26, MAC3 = 27,
	IRGB = 28, ORGB = 29, LZCS = 30, LZCR = 31,
}

// PS1 GTE control registers (CFC2/CTC2).
GTE_CtrlReg :: enum u8 {
	R11R12 = 0,  R13R21 = 1,  R22R23 = 2,  R31R32 = 3,  R33    = 4,
	TRX    = 5,  TRY    = 6,  TRZ    = 7,
	L11L12 = 8,  L13L21 = 9,  L22L23 = 10, L31L32 = 11, L33    = 12,
	RBK    = 13, GBK    = 14, BBK    = 15,
	LR1LR2 = 16, LR3LG1 = 17, LG2LG3 = 18, LB1LB2 = 19, LB3    = 20,
	RFC    = 21, GFC    = 22, BFC    = 23,
	OFX    = 24, OFY    = 25, H      = 26,
	DQA    = 27, DQB    = 28, ZSF3   = 29, ZSF4   = 30, FLAG   = 31,
}

// -----------------------------------------------------------------------------
// HI/LO
// -----------------------------------------------------------------------------

HI :: Register(REG_HILO | 0)
LO :: Register(REG_HILO | 1)

// PS2 second hi/lo pair (R5900 has two MAC units).
HI1 :: Register(REG_HILO | 2)
LO1 :: Register(REG_HILO | 3)

// -----------------------------------------------------------------------------
// Utility
// -----------------------------------------------------------------------------

@(require_results)
reg_hw :: #force_inline proc "contextless" (r: Register) -> u8 {
	return u8(r) & 0x1F
}

@(require_results)
reg_class :: #force_inline proc "contextless" (r: Register) -> u16 {
	return u16(r) & 0xFF00
}

@(require_results)
reg_is_gpr :: #force_inline proc "contextless" (r: Register) -> bool {
	return reg_class(r) == REG_GPR
}

@(require_results)
reg_is_fpr :: #force_inline proc "contextless" (r: Register) -> bool {
	return reg_class(r) == REG_FPR
}

@(require_results)
gpr_from_num :: #force_inline proc "contextless" (num: u8) -> Register {
	return num < 32 ? Register(REG_GPR | u16(num)) : NONE
}

@(require_results)
fpr_from_num :: #force_inline proc "contextless" (num: u8) -> Register {
	return num < 32 ? Register(REG_FPR | u16(num)) : NONE
}

@(require_results)
cp0_from_num :: #force_inline proc "contextless" (num: u8) -> Register {
	return num < 32 ? Register(REG_CP0 | u16(num)) : NONE
}

@(require_results)
cp2d_from_num :: #force_inline proc "contextless" (num: u8) -> Register {
	return num < 32 ? Register(REG_CP2D | u16(num)) : NONE
}

@(require_results)
cp2c_from_num :: #force_inline proc "contextless" (num: u8) -> Register {
	return num < 32 ? Register(REG_CP2C | u16(num)) : NONE
}

@(require_results)
msa_from_num :: #force_inline proc "contextless" (num: u8) -> Register {
	return num < 32 ? Register(REG_MSA | u16(num)) : NONE
}

// VFPU register builder. 7-bit hardware index (0..127); the high bit of
// the byte (bit 7) is reserved for future use as an orientation flag if
// needed. Callers requesting a VFPU.s/.p/.t/.q operand bake the format
// into the mnemonic.
@(require_results)
vfpu_from_num :: #force_inline proc "contextless" (num: u8) -> Register {
	return num < 128 ? Register(REG_VFPU | u16(num)) : NONE
}

@(require_results)
reg_is_vfpu :: #force_inline proc "contextless" (r: Register) -> bool {
	return reg_class(r) == REG_VFPU
}

// VFPU hardware-id accessor (7 bits vs the standard reg_hw's 5).
@(require_results)
reg_vfpu_hw :: #force_inline proc "contextless" (r: Register) -> u8 {
	return u8(r) & 0x7F
}

@(require_results)
reg_is_msa :: #force_inline proc "contextless" (r: Register) -> bool {
	return reg_class(r) == REG_MSA
}

// MSA $w0..$w31 constants for ergonomic use.
W0  :: Register(REG_MSA |  0); W1  :: Register(REG_MSA |  1); W2  :: Register(REG_MSA |  2); W3  :: Register(REG_MSA |  3)
W4  :: Register(REG_MSA |  4); W5  :: Register(REG_MSA |  5); W6  :: Register(REG_MSA |  6); W7  :: Register(REG_MSA |  7)
W8  :: Register(REG_MSA |  8); W9  :: Register(REG_MSA |  9); W10 :: Register(REG_MSA | 10); W11 :: Register(REG_MSA | 11)
W12 :: Register(REG_MSA | 12); W13 :: Register(REG_MSA | 13); W14 :: Register(REG_MSA | 14); W15 :: Register(REG_MSA | 15)
W16 :: Register(REG_MSA | 16); W17 :: Register(REG_MSA | 17); W18 :: Register(REG_MSA | 18); W19 :: Register(REG_MSA | 19)
W20 :: Register(REG_MSA | 20); W21 :: Register(REG_MSA | 21); W22 :: Register(REG_MSA | 22); W23 :: Register(REG_MSA | 23)
W24 :: Register(REG_MSA | 24); W25 :: Register(REG_MSA | 25); W26 :: Register(REG_MSA | 26); W27 :: Register(REG_MSA | 27)
W28 :: Register(REG_MSA | 28); W29 :: Register(REG_MSA | 29); W30 :: Register(REG_MSA | 30); W31 :: Register(REG_MSA | 31)
