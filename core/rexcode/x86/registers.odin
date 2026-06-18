// rexcode  ·  Brendan Punsky (dotbmp@github), original author

package rexcode_x86

// =============================================================================
// SECTION: 1. REGISTERS
// =============================================================================

// -----------------------------------------------------------------------------
// SECTION: 1.1 Register Type and Classes
// -----------------------------------------------------------------------------

// Register encoding: 0b_0000_CCCC_EEEN_NNNN
// NNNNN = hardware register number (0-31)
// E     = needs REX/VEX .B/.R/.X extension (hw num >= 8)
// EE    = needs EVEX for regs 16-31
// CCCC  = register class
Register :: distinct u16

// Register classes (upper byte)
REG_NONE  :: 0x000
REG_GPR64 :: 0x100
REG_GPR32 :: 0x200
REG_GPR16 :: 0x300
REG_GPR8  :: 0x400
REG_GPR8H :: 0x500  // AH, CH, DH, BH - legacy high byte regs
REG_XMM   :: 0x600
REG_YMM   :: 0x700
REG_ZMM   :: 0x800
REG_K     :: 0x900  // opmask
REG_SEG   :: 0xA00  // segment
REG_CR    :: 0xB00  // control
REG_DR    :: 0xC00  // debug
REG_BND   :: 0xD00  // bound
REG_MM    :: 0xE00  // MMX
REG_ST    :: 0xF00  // x87 FPU

// Sentinel
NONE :: Register(0xFFFF)

// -----------------------------------------------------------------------------
// SECTION: 1.1b Typed Register Enums (for compile-time type safety)
// -----------------------------------------------------------------------------
// These enums provide type-safe register handling. The enum value IS the hardware
// register number, allowing direct casting instead of table lookups.
// Use these with the typed operand constructors (op_gpr64, op_xmm, etc.)
// for compile-time safety: op_gpr64(.XMM0) is a compile error.

GPR64 :: enum u8 {
	RAX, RCX, RDX, RBX, RSP, RBP, RSI, RDI,
	R8,  R9,  R10, R11, R12, R13, R14, R15,
}

GPR32 :: enum u8 {
	EAX, ECX, EDX,  EBX,  ESP,  EBP,  ESI,  EDI,
	R8D, R9D, R10D, R11D, R12D, R13D, R14D, R15D,
}

GPR16 :: enum u8 {
	AX,  CX,  DX,   BX,   SP,   BP,   SI,   DI,
	R8W, R9W, R10W, R11W, R12W, R13W, R14W, R15W,
}

GPR8 :: enum u8 {
	AL,  CL,  DL,   BL,   SPL,  BPL,  SIL,  DIL,
	R8B, R9B, R10B, R11B, R12B, R13B, R14B, R15B,
}

// Legacy high-byte registers (AH, CH, DH, BH) - no REX allowed with these
// Hardware numbers 4-7 (not 0-3) because they share encoding space with SPL/BPL/SIL/DIL
GPR8H :: enum u8 { AH=4, CH=5, DH=6, BH=7 }

XMM :: enum u8 {
	XMM0,  XMM1,  XMM2,  XMM3,  XMM4,  XMM5,  XMM6,  XMM7,
	XMM8,  XMM9,  XMM10, XMM11, XMM12, XMM13, XMM14, XMM15,
	XMM16, XMM17, XMM18, XMM19, XMM20, XMM21, XMM22, XMM23,
	XMM24, XMM25, XMM26, XMM27, XMM28, XMM29, XMM30, XMM31,
}

YMM :: enum u8 {
	YMM0,  YMM1,  YMM2,  YMM3,  YMM4,  YMM5,  YMM6,  YMM7,
	YMM8,  YMM9,  YMM10, YMM11, YMM12, YMM13, YMM14, YMM15,
	YMM16, YMM17, YMM18, YMM19, YMM20, YMM21, YMM22, YMM23,
	YMM24, YMM25, YMM26, YMM27, YMM28, YMM29, YMM30, YMM31,
}

ZMM :: enum u8 {
	ZMM0,  ZMM1,  ZMM2,  ZMM3,  ZMM4,  ZMM5,  ZMM6,  ZMM7,
	ZMM8,  ZMM9,  ZMM10, ZMM11, ZMM12, ZMM13, ZMM14, ZMM15,
	ZMM16, ZMM17, ZMM18, ZMM19, ZMM20, ZMM21, ZMM22, ZMM23,
	ZMM24, ZMM25, ZMM26, ZMM27, ZMM28, ZMM29, ZMM30, ZMM31,
}

KREG :: enum u8 { K0, K1, K2, K3, K4, K5, K6, K7 }

SREG :: enum u8 { ES, CS, SS, DS, FS, GS }

MM :: enum u8 { MM0, MM1, MM2, MM3, MM4, MM5, MM6, MM7 }

// Control registers (non-contiguous: CR0, CR2, CR3, CR4, CR8)
CREG :: enum u8 { CR0=0, CR2=2, CR3=3, CR4=4, CR8=8 }

// Debug registers
DREG :: enum u8 { DR0, DR1, DR2, DR3, DR6, DR7 }

// x87 FPU registers
ST :: enum u8 { ST0, ST1, ST2, ST3, ST4, ST5, ST6, ST7 }

// Bound registers (MPX)
BND :: enum u8 { BND0, BND1, BND2, BND3 }

// -----------------------------------------------------------------------------
// SECTION: 1.2 GPR 64-bit Registers (RAX-R15)
// -----------------------------------------------------------------------------

// GPR 64-bit
RAX :: Register(REG_GPR64 | 0);  RCX :: Register(REG_GPR64 | 1)
RDX :: Register(REG_GPR64 | 2);  RBX :: Register(REG_GPR64 | 3)
RSP :: Register(REG_GPR64 | 4);  RBP :: Register(REG_GPR64 | 5)
RSI :: Register(REG_GPR64 | 6);  RDI :: Register(REG_GPR64 | 7)
R8  :: Register(REG_GPR64 | 8);  R9  :: Register(REG_GPR64 | 9)
R10 :: Register(REG_GPR64 | 10); R11 :: Register(REG_GPR64 | 11)
R12 :: Register(REG_GPR64 | 12); R13 :: Register(REG_GPR64 | 13)
R14 :: Register(REG_GPR64 | 14); R15 :: Register(REG_GPR64 | 15)

// -----------------------------------------------------------------------------
// SECTION: 1.3 GPR 32-bit Registers (EAX-R15D)
// -----------------------------------------------------------------------------

// GPR 32-bit
EAX  :: Register(REG_GPR32 | 0);  ECX  :: Register(REG_GPR32 | 1)
EDX  :: Register(REG_GPR32 | 2);  EBX  :: Register(REG_GPR32 | 3)
ESP  :: Register(REG_GPR32 | 4);  EBP  :: Register(REG_GPR32 | 5)
ESI  :: Register(REG_GPR32 | 6);  EDI  :: Register(REG_GPR32 | 7)
R8D  :: Register(REG_GPR32 | 8);  R9D  :: Register(REG_GPR32 | 9)
R10D :: Register(REG_GPR32 | 10); R11D :: Register(REG_GPR32 | 11)
R12D :: Register(REG_GPR32 | 12); R13D :: Register(REG_GPR32 | 13)
R14D :: Register(REG_GPR32 | 14); R15D :: Register(REG_GPR32 | 15)

// -----------------------------------------------------------------------------
// SECTION: 1.4 GPR 16-bit Registers (AX-R15W)
// -----------------------------------------------------------------------------

// GPR 16-bit
AX   :: Register(REG_GPR16 | 0);  CX   :: Register(REG_GPR16 | 1)
DX   :: Register(REG_GPR16 | 2);  BX   :: Register(REG_GPR16 | 3)
SP   :: Register(REG_GPR16 | 4);  BP   :: Register(REG_GPR16 | 5)
SI   :: Register(REG_GPR16 | 6);  DI   :: Register(REG_GPR16 | 7)
R8W  :: Register(REG_GPR16 | 8);  R9W  :: Register(REG_GPR16 | 9)
R10W :: Register(REG_GPR16 | 10); R11W :: Register(REG_GPR16 | 11)
R12W :: Register(REG_GPR16 | 12); R13W :: Register(REG_GPR16 | 13)
R14W :: Register(REG_GPR16 | 14); R15W :: Register(REG_GPR16 | 15)

// -----------------------------------------------------------------------------
// SECTION: 1.5 GPR 8-bit Registers (AL-R15B, AH-BH)
// -----------------------------------------------------------------------------

// GPR 8-bit (low)
AL   :: Register(REG_GPR8 | 0);   CL   :: Register(REG_GPR8 | 1)
DL   :: Register(REG_GPR8 | 2);   BL   :: Register(REG_GPR8 | 3)
SPL  :: Register(REG_GPR8 | 4);   BPL  :: Register(REG_GPR8 | 5)
SIL  :: Register(REG_GPR8 | 6);   DIL  :: Register(REG_GPR8 | 7)
R8B  :: Register(REG_GPR8 | 8);   R9B  :: Register(REG_GPR8 | 9)
R10B :: Register(REG_GPR8 | 10);  R11B :: Register(REG_GPR8 | 11)
R12B :: Register(REG_GPR8 | 12);  R13B :: Register(REG_GPR8 | 13)
R14B :: Register(REG_GPR8 | 14);  R15B :: Register(REG_GPR8 | 15)

// GPR 8-bit (high) - no REX allowed with these
AH :: Register(REG_GPR8H | 4);   CH :: Register(REG_GPR8H | 5)
DH :: Register(REG_GPR8H | 6);   BH :: Register(REG_GPR8H | 7)

// -----------------------------------------------------------------------------
// SECTION: 1.6 XMM Registers (XMM0-XMM31)
// -----------------------------------------------------------------------------

// XMM (0-31)
XMM0  :: Register(REG_XMM | 0);   XMM1  :: Register(REG_XMM | 1)
XMM2  :: Register(REG_XMM | 2);   XMM3  :: Register(REG_XMM | 3)
XMM4  :: Register(REG_XMM | 4);   XMM5  :: Register(REG_XMM | 5)
XMM6  :: Register(REG_XMM | 6);   XMM7  :: Register(REG_XMM | 7)
XMM8  :: Register(REG_XMM | 8);   XMM9  :: Register(REG_XMM | 9)
XMM10 :: Register(REG_XMM | 10);  XMM11 :: Register(REG_XMM | 11)
XMM12 :: Register(REG_XMM | 12);  XMM13 :: Register(REG_XMM | 13)
XMM14 :: Register(REG_XMM | 14);  XMM15 :: Register(REG_XMM | 15)
XMM16 :: Register(REG_XMM | 16);  XMM17 :: Register(REG_XMM | 17)
XMM18 :: Register(REG_XMM | 18);  XMM19 :: Register(REG_XMM | 19)
XMM20 :: Register(REG_XMM | 20);  XMM21 :: Register(REG_XMM | 21)
XMM22 :: Register(REG_XMM | 22);  XMM23 :: Register(REG_XMM | 23)
XMM24 :: Register(REG_XMM | 24);  XMM25 :: Register(REG_XMM | 25)
XMM26 :: Register(REG_XMM | 26);  XMM27 :: Register(REG_XMM | 27)
XMM28 :: Register(REG_XMM | 28);  XMM29 :: Register(REG_XMM | 29)
XMM30 :: Register(REG_XMM | 30);  XMM31 :: Register(REG_XMM | 31)

// -----------------------------------------------------------------------------
// SECTION: 1.7 YMM Registers (YMM0-YMM31)
// -----------------------------------------------------------------------------

// YMM (0-31)
YMM0  :: Register(REG_YMM | 0);   YMM1  :: Register(REG_YMM | 1)
YMM2  :: Register(REG_YMM | 2);   YMM3  :: Register(REG_YMM | 3)
YMM4  :: Register(REG_YMM | 4);   YMM5  :: Register(REG_YMM | 5)
YMM6  :: Register(REG_YMM | 6);   YMM7  :: Register(REG_YMM | 7)
YMM8  :: Register(REG_YMM | 8);   YMM9  :: Register(REG_YMM | 9)
YMM10 :: Register(REG_YMM | 10);  YMM11 :: Register(REG_YMM | 11)
YMM12 :: Register(REG_YMM | 12);  YMM13 :: Register(REG_YMM | 13)
YMM14 :: Register(REG_YMM | 14);  YMM15 :: Register(REG_YMM | 15)
YMM16 :: Register(REG_YMM | 16);  YMM17 :: Register(REG_YMM | 17)
YMM18 :: Register(REG_YMM | 18);  YMM19 :: Register(REG_YMM | 19)
YMM20 :: Register(REG_YMM | 20);  YMM21 :: Register(REG_YMM | 21)
YMM22 :: Register(REG_YMM | 22);  YMM23 :: Register(REG_YMM | 23)
YMM24 :: Register(REG_YMM | 24);  YMM25 :: Register(REG_YMM | 25)
YMM26 :: Register(REG_YMM | 26);  YMM27 :: Register(REG_YMM | 27)
YMM28 :: Register(REG_YMM | 28);  YMM29 :: Register(REG_YMM | 29)
YMM30 :: Register(REG_YMM | 30);  YMM31 :: Register(REG_YMM | 31)

// -----------------------------------------------------------------------------
// SECTION: 1.8 ZMM Registers (ZMM0-ZMM31)
// -----------------------------------------------------------------------------

// ZMM (0-31)
ZMM0  :: Register(REG_ZMM | 0);   ZMM1  :: Register(REG_ZMM | 1)
ZMM2  :: Register(REG_ZMM | 2);   ZMM3  :: Register(REG_ZMM | 3)
ZMM4  :: Register(REG_ZMM | 4);   ZMM5  :: Register(REG_ZMM | 5)
ZMM6  :: Register(REG_ZMM | 6);   ZMM7  :: Register(REG_ZMM | 7)
ZMM8  :: Register(REG_ZMM | 8);   ZMM9  :: Register(REG_ZMM | 9)
ZMM10 :: Register(REG_ZMM | 10);  ZMM11 :: Register(REG_ZMM | 11)
ZMM12 :: Register(REG_ZMM | 12);  ZMM13 :: Register(REG_ZMM | 13)
ZMM14 :: Register(REG_ZMM | 14);  ZMM15 :: Register(REG_ZMM | 15)
ZMM16 :: Register(REG_ZMM | 16);  ZMM17 :: Register(REG_ZMM | 17)
ZMM18 :: Register(REG_ZMM | 18);  ZMM19 :: Register(REG_ZMM | 19)
ZMM20 :: Register(REG_ZMM | 20);  ZMM21 :: Register(REG_ZMM | 21)
ZMM22 :: Register(REG_ZMM | 22);  ZMM23 :: Register(REG_ZMM | 23)
ZMM24 :: Register(REG_ZMM | 24);  ZMM25 :: Register(REG_ZMM | 25)
ZMM26 :: Register(REG_ZMM | 26);  ZMM27 :: Register(REG_ZMM | 27)
ZMM28 :: Register(REG_ZMM | 28);  ZMM29 :: Register(REG_ZMM | 29)
ZMM30 :: Register(REG_ZMM | 30);  ZMM31 :: Register(REG_ZMM | 31)

// -----------------------------------------------------------------------------
// SECTION: 1.9 Opmask Registers (K0-K7)
// -----------------------------------------------------------------------------

// Opmask registers
K0 :: Register(REG_K | 0); K1 :: Register(REG_K | 1)
K2 :: Register(REG_K | 2); K3 :: Register(REG_K | 3)
K4 :: Register(REG_K | 4); K5 :: Register(REG_K | 5)
K6 :: Register(REG_K | 6); K7 :: Register(REG_K | 7)

// -----------------------------------------------------------------------------
// SECTION: 1.10 Segment Registers (ES-GS)
// -----------------------------------------------------------------------------

// Segment registers
ES :: Register(REG_SEG | 0); CS :: Register(REG_SEG | 1)
SS :: Register(REG_SEG | 2); DS :: Register(REG_SEG | 3)
FS :: Register(REG_SEG | 4); GS :: Register(REG_SEG | 5)

// -----------------------------------------------------------------------------
// SECTION: 1.11 Control and Debug Registers
// -----------------------------------------------------------------------------

// Control registers
CR0 :: Register(REG_CR | 0);  CR2 :: Register(REG_CR | 2)
CR3 :: Register(REG_CR | 3);  CR4 :: Register(REG_CR | 4)
CR8 :: Register(REG_CR | 8)

// Debug registers
DR0 :: Register(REG_DR | 0); DR1 :: Register(REG_DR | 1)
DR2 :: Register(REG_DR | 2); DR3 :: Register(REG_DR | 3)
DR6 :: Register(REG_DR | 6); DR7 :: Register(REG_DR | 7)

// -----------------------------------------------------------------------------
// SECTION: 1.12 Other Registers (BND, MM, ST)
// -----------------------------------------------------------------------------

// Bound registers (MPX)
BND0 :: Register(REG_BND | 0); BND1 :: Register(REG_BND | 1)
BND2 :: Register(REG_BND | 2); BND3 :: Register(REG_BND | 3)

// MMX registers
MM0 :: Register(REG_MM | 0); MM1 :: Register(REG_MM | 1)
MM2 :: Register(REG_MM | 2); MM3 :: Register(REG_MM | 3)
MM4 :: Register(REG_MM | 4); MM5 :: Register(REG_MM | 5)
MM6 :: Register(REG_MM | 6); MM7 :: Register(REG_MM | 7)

// x87 FPU registers
ST0 :: Register(REG_ST | 0); ST1 :: Register(REG_ST | 1)
ST2 :: Register(REG_ST | 2); ST3 :: Register(REG_ST | 3)
ST4 :: Register(REG_ST | 4); ST5 :: Register(REG_ST | 5)
ST6 :: Register(REG_ST | 6); ST7 :: Register(REG_ST | 7)

// Special: RIP for RIP-relative addressing
RIP :: Register(0xFFFE)

// -----------------------------------------------------------------------------
// SECTION: 1.13 Register Utility Functions
// -----------------------------------------------------------------------------

// Register utility functions - all branchless single-cycle operations
@(require_results)
reg_hw :: #force_inline proc "contextless" (r: Register) -> u8 {
	return u8(r) & 0x1F
}

@(require_results)
reg_class :: #force_inline proc "contextless" (r: Register) -> u16 {
	return u16(r) & 0xFF00
}

@(require_results)
reg_needs_rex :: #force_inline proc "contextless" (r: Register) -> bool {
	return (u16(r) & 0x08) != 0
}

@(require_results)
reg_needs_rex_ext :: #force_inline proc "contextless" (r: Register) -> bool {
	return (u16(r) & 0x08) != 0 && reg_class(r) < REG_K
}

@(require_results)
reg_needs_evex :: #force_inline proc "contextless" (r: Register) -> bool {
	return (u16(r) & 0x10) != 0
}

@(require_results)
reg_is_gpr :: #force_inline proc "contextless" (r: Register) -> bool {
	c := reg_class(r)
	return REG_GPR64 <= c && c <= REG_GPR8H
}

@(require_results)
reg_is_vector :: #force_inline proc "contextless" (r: Register) -> bool {
	c := reg_class(r)
	return REG_XMM <= c && c <= REG_ZMM
}

@(require_results)
reg_is_high_byte :: #force_inline proc "contextless" (r: Register) -> bool {
	return reg_class(r) == REG_GPR8H
}

// Size in bits for register
@(require_results)
reg_size :: #force_inline proc "contextless" (r: Register) -> u16 {
	switch reg_class(r) {
	case REG_GPR64:           return 64
	case REG_GPR32:           return 32
	case REG_GPR16:           return 16
	case REG_GPR8, REG_GPR8H: return 8
	case REG_XMM:             return 128
	case REG_YMM:             return 256
	case REG_ZMM:             return 512
	case REG_K:               return 64
	case REG_MM:              return 64
	case REG_ST:              return 80
	case REG_SEG:             return 16
	case REG_CR, REG_DR:      return 64
	case REG_BND:             return 128
	}
	return 0
}

// -----------------------------------------------------------------------------
// SECTION: 1.14 Register-from-Number Constructors
// -----------------------------------------------------------------------------

// Register-from-number functions: direct cast, no table lookup.
// Since Register = class | hardware_number, and num IS the hardware number,
// we just OR with the class constant. This is O(1) with no stack allocation.

@(require_results)
gpr64_from_num :: #force_inline proc "contextless" (num: u8) -> Register {
	return num < 16 ? Register(REG_GPR64 | u16(num)) : NONE
}

@(require_results)
gpr32_from_num :: #force_inline proc "contextless" (num: u8) -> Register {
	return num < 16 ? Register(REG_GPR32 | u16(num)) : NONE
}

@(require_results)
gpr16_from_num :: #force_inline proc "contextless" (num: u8) -> Register {
	return num < 16 ? Register(REG_GPR16 | u16(num)) : NONE
}

@(require_results)
gpr8_from_num :: #force_inline proc "contextless" (num: u8, has_rex: bool) -> Register {
	// Without REX prefix, nums 4-7 encode AH/CH/DH/BH (high byte legacy regs)
	// With REX prefix, nums 4-7 encode SPL/BPL/SIL/DIL (low byte regs)
	if has_rex {
		return num < 16 ? Register(REG_GPR8 | u16(num)) : NONE
	} else if num < 4 {
		return Register(REG_GPR8 | u16(num))  // AL, CL, DL, BL
	} else if num < 8 {
		return Register(REG_GPR8H | u16(num))  // AH, CH, DH, BH (hw num 4-7)
	}
	return NONE
}

@(require_results)
xmm_from_num :: #force_inline proc "contextless" (num: u8) -> Register {
	return num < 32 ? Register(REG_XMM | u16(num)) : NONE
}

@(require_results)
ymm_from_num :: #force_inline proc "contextless" (num: u8) -> Register {
	return num < 32 ? Register(REG_YMM | u16(num)) : NONE
}

@(require_results)
zmm_from_num :: #force_inline proc "contextless" (num: u8) -> Register {
	return num < 32 ? Register(REG_ZMM | u16(num)) : NONE
}

@(require_results)
mm_from_num :: #force_inline proc "contextless" (num: u8) -> Register {
	return num < 8 ? Register(REG_MM | u16(num)) : NONE
}
