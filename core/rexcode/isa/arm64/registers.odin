// rexcode  ·  Brendan Punsky (dotbmp@github), original author

package rexcode_arm64

// =============================================================================
// AArch64 REGISTERS
// =============================================================================
//
// AArch64 has:
//   X0..X30   64-bit general-purpose
//   W0..W30   32-bit views of the same registers
//   XZR/WZR   hardwired zero (encoded as register 31 in most instructions)
//   SP/WSP    stack pointer (also encoded as register 31, but only some
//             instructions accept it -- the rest read register 31 as ZR)
//   V0..V31   128-bit SIMD/FP registers
//   B/H/S/D/Q same registers, viewed as 8/16/32/64/128-bit scalars
//
// The SP-vs-ZR ambiguity at hw=31 is resolved by giving SP/WSP their own
// register *class*. An operand typed `XSP_REG` accepts X0..X30 OR SP;
// X_REG accepts X0..X30 OR XZR. Both still encode hw=31 for SP/XZR.
//
// Layout: the hardware number in bits 0-4, the class byte in bits 8-15,
// and -- for system registers only -- the 15-bit MRS/MSR field in bits
// 16-30. Every class except REG_SYS lives entirely in the low 16 bits,
// and `Memory` relies on that: it packs base and index into 16-bit
// fields, which is lossless for every class legal in an address. A
// system register is the one class with high bits, and it is never a
// valid base or index.

Register :: distinct u32

REG_NONE :: 0x0000
REG_X    :: 0x0100   // X0..X30, XZR (X31 = ZR semantically)
REG_W    :: 0x0200   // W0..W30, WZR
REG_XSP  :: 0x0300   // SP (only -- distinct class from X to opt-in)
REG_WSP  :: 0x0400   // WSP
REG_V    :: 0x0500   // V0..V31 (full 128-bit; used in NEON vector form)
REG_B    :: 0x0600   // B0..B31 (byte view)
REG_H    :: 0x0700   // H0..H31 (half view)
REG_S    :: 0x0800   // S0..S31 (single view)
REG_D    :: 0x0900   // D0..D31 (double view)
REG_Q    :: 0x0A00   // Q0..Q31 (quad view)
REG_Z    :: 0x0B00   // Z0..Z31 SVE scalable vector (low 128 aliased with V)
REG_P    :: 0x0C00   // P0..P15 SVE predicate
REG_PN   :: 0x0D00   // PN8..PN15 SME2 predicate-as-counter
REG_ZT   :: 0x0E00   // ZT0, the SME2 lookup table
REG_ZA   :: 0x0F00   // ZA0..ZA15, SME's accumulator tiles
REG_SYS  :: 0x1000   // system registers (MRS/MSR); the field is in bits 16-30

NONE :: Register(0xFFFF)

@(require_results) reg_hw    :: #force_inline proc "contextless" (r: Register) -> u8  { return u8(r) & 0x1F }
@(require_results) reg_class :: #force_inline proc "contextless" (r: Register) -> u16 { return u16(r) & 0xFF00 }

@(require_results) reg_is_x   :: #force_inline proc "contextless" (r: Register) -> bool { return reg_class(r) == REG_X   }
@(require_results) reg_is_w   :: #force_inline proc "contextless" (r: Register) -> bool { return reg_class(r) == REG_W   }
@(require_results) reg_is_xsp :: #force_inline proc "contextless" (r: Register) -> bool { return reg_class(r) == REG_XSP }
@(require_results) reg_is_wsp :: #force_inline proc "contextless" (r: Register) -> bool { return reg_class(r) == REG_WSP }

// SME2 addresses its predicates as counters rather than masks, and numbers
// them from 8: the encoding holds pn - 8.
PN8  :: Register(REG_PN |  8); PN9  :: Register(REG_PN |  9)
PN10 :: Register(REG_PN | 10); PN11 :: Register(REG_PN | 11)
PN12 :: Register(REG_PN | 12); PN13 :: Register(REG_PN | 13)
PN14 :: Register(REG_PN | 14); PN15 :: Register(REG_PN | 15)

// SME2's lookup table. There is exactly one, so it takes no bits.
ZT0 :: Register(REG_ZT | 0)

// -----------------------------------------------------------------------------
// 64-bit GPRs (X0..X30, XZR, SP)
// -----------------------------------------------------------------------------

X0  :: Register(REG_X | 0);  X1  :: Register(REG_X | 1);  X2  :: Register(REG_X | 2);  X3  :: Register(REG_X | 3)
X4  :: Register(REG_X | 4);  X5  :: Register(REG_X | 5);  X6  :: Register(REG_X | 6);  X7  :: Register(REG_X | 7)
X8  :: Register(REG_X | 8);  X9  :: Register(REG_X | 9);  X10 :: Register(REG_X | 10); X11 :: Register(REG_X | 11)
X12 :: Register(REG_X | 12); X13 :: Register(REG_X | 13); X14 :: Register(REG_X | 14); X15 :: Register(REG_X | 15)
X16 :: Register(REG_X | 16); X17 :: Register(REG_X | 17); X18 :: Register(REG_X | 18); X19 :: Register(REG_X | 19)
X20 :: Register(REG_X | 20); X21 :: Register(REG_X | 21); X22 :: Register(REG_X | 22); X23 :: Register(REG_X | 23)
X24 :: Register(REG_X | 24); X25 :: Register(REG_X | 25); X26 :: Register(REG_X | 26); X27 :: Register(REG_X | 27)
X28 :: Register(REG_X | 28); X29 :: Register(REG_X | 29); X30 :: Register(REG_X | 30)
XZR :: Register(REG_X | 31)

LR  :: X30   // procedure call link register
FP_REG :: X29   // frame pointer (avoid collision with `FP` if added later)

SP  :: Register(REG_XSP | 31)

// -----------------------------------------------------------------------------
// 32-bit GPRs (W0..W30, WZR, WSP)
// -----------------------------------------------------------------------------

W0  :: Register(REG_W | 0);  W1  :: Register(REG_W | 1);  W2  :: Register(REG_W | 2);  W3  :: Register(REG_W | 3)
W4  :: Register(REG_W | 4);  W5  :: Register(REG_W | 5);  W6  :: Register(REG_W | 6);  W7  :: Register(REG_W | 7)
W8  :: Register(REG_W | 8);  W9  :: Register(REG_W | 9);  W10 :: Register(REG_W | 10); W11 :: Register(REG_W | 11)
W12 :: Register(REG_W | 12); W13 :: Register(REG_W | 13); W14 :: Register(REG_W | 14); W15 :: Register(REG_W | 15)
W16 :: Register(REG_W | 16); W17 :: Register(REG_W | 17); W18 :: Register(REG_W | 18); W19 :: Register(REG_W | 19)
W20 :: Register(REG_W | 20); W21 :: Register(REG_W | 21); W22 :: Register(REG_W | 22); W23 :: Register(REG_W | 23)
W24 :: Register(REG_W | 24); W25 :: Register(REG_W | 25); W26 :: Register(REG_W | 26); W27 :: Register(REG_W | 27)
W28 :: Register(REG_W | 28); W29 :: Register(REG_W | 29); W30 :: Register(REG_W | 30)
WZR :: Register(REG_W | 31)
WSP :: Register(REG_WSP | 31)

// -----------------------------------------------------------------------------
// SIMD/FP register views (full Vn or scalar Bn/Hn/Sn/Dn/Qn)
// -----------------------------------------------------------------------------

V0  :: Register(REG_V | 0);  V1  :: Register(REG_V | 1);  V2  :: Register(REG_V | 2);  V3  :: Register(REG_V | 3)
V4  :: Register(REG_V | 4);  V5  :: Register(REG_V | 5);  V6  :: Register(REG_V | 6);  V7  :: Register(REG_V | 7)
V8  :: Register(REG_V | 8);  V9  :: Register(REG_V | 9);  V10 :: Register(REG_V | 10); V11 :: Register(REG_V | 11)
V12 :: Register(REG_V | 12); V13 :: Register(REG_V | 13); V14 :: Register(REG_V | 14); V15 :: Register(REG_V | 15)
V16 :: Register(REG_V | 16); V17 :: Register(REG_V | 17); V18 :: Register(REG_V | 18); V19 :: Register(REG_V | 19)
V20 :: Register(REG_V | 20); V21 :: Register(REG_V | 21); V22 :: Register(REG_V | 22); V23 :: Register(REG_V | 23)
V24 :: Register(REG_V | 24); V25 :: Register(REG_V | 25); V26 :: Register(REG_V | 26); V27 :: Register(REG_V | 27)
V28 :: Register(REG_V | 28); V29 :: Register(REG_V | 29); V30 :: Register(REG_V | 30); V31 :: Register(REG_V | 31)

// Scalar view constructors -- the hw number is the same V register.
@(require_results) b_reg :: #force_inline proc "contextless" (n: u8) -> Register { return Register(REG_B | u16(n & 0x1F)) }
@(require_results) h_reg :: #force_inline proc "contextless" (n: u8) -> Register { return Register(REG_H | u16(n & 0x1F)) }
@(require_results) s_reg :: #force_inline proc "contextless" (n: u8) -> Register { return Register(REG_S | u16(n & 0x1F)) }
@(require_results) d_reg :: #force_inline proc "contextless" (n: u8) -> Register { return Register(REG_D | u16(n & 0x1F)) }
@(require_results) q_reg :: #force_inline proc "contextless" (n: u8) -> Register { return Register(REG_Q | u16(n & 0x1F)) }
@(require_results) v_reg :: #force_inline proc "contextless" (n: u8) -> Register { return Register(REG_V | u16(n & 0x1F)) }
@(require_results) x_reg :: #force_inline proc "contextless" (n: u8) -> Register { return Register(REG_X | u16(n & 0x1F)) }
@(require_results) w_reg :: #force_inline proc "contextless" (n: u8) -> Register { return Register(REG_W | u16(n & 0x1F)) }

// =============================================================================
// AArch64 SYSTEM REGISTERS (MRS / MSR)
// =============================================================================
//
// A system register is a `Register` of class REG_SYS. MRS / MSR name their
// target as a 15-bit field at bits 19:5 of the word, packed MSB-first as
// o0 || op1 || CRn || CRm || op2:
//
//   o0  (1 bit)  op0 - 2   (op0 = 2 -> 0, op0 = 3 -> 1)
//   op1 (3 bits)
//   CRn (4 bits)
//   CRm (4 bits)
//   op2 (3 bits)
//
// That field cannot fit under an 8-bit class with an 8-bit number, so it
// rides in bits 16-30 of the u32 -- the one class that uses them. Each
// constant below carries its five architectural numbers in its comment, and
// every value is verified byte-exact against llvm-mc. The constant's low 16
// bits are the class, so `SPSR_EL1 :: Register(0x4200_1000)` names the
// register whose field is 0x4200.

// The 15-bit field MRS/MSR carry at bits 19:5 of the instruction word.
@(require_results)
sysreg_bits :: #force_inline proc "contextless" (r: Register) -> u32 {
	return (u32(r) >> 16) & 0x7FFF
}

// The register a decoded 15-bit MRS/MSR field names.
@(require_results)
sysreg_from_bits :: #force_inline proc "contextless" (bits: u32) -> Register {
	return Register((bits & 0x7FFF) << 16 | REG_SYS)
}

// -----------------------------------------------------------------------------
// Build a system register from the five architectural numbers, for a register
// this list does not name. op0 must be 2 or 3.
// -----------------------------------------------------------------------------

@(require_results)
sysreg_field :: #force_inline proc "contextless" (op0, op1, CRn, CRm, op2: u32) -> Register {
	o0 := (op0 - 2) & 0x1
	return sysreg_from_bits(
		(o0  << 14) |
		(op1 << 11) |
		(CRn <<  7) |
		(CRm <<  3) |
		 op2,
	)
}

// -----------------------------------------------------------------------------
// Process state, exceptions and stack pointers
// -----------------------------------------------------------------------------

//                                         op0 op1 CRn CRm op2
AFSR0_EL1         :: Register(0x4288_1000)  // 3   0   5   1   0
AFSR1_EL1         :: Register(0x4289_1000)  // 3   0   5   1   1
CURRENT_EL        :: Register(0x4212_1000)  // 3   0   4   2   2
DAIF              :: Register(0x5A11_1000)  // 3   3   4   2   1
ELR_EL1           :: Register(0x4201_1000)  // 3   0   4   0   1
ELR_EL2           :: Register(0x6201_1000)  // 3   4   4   0   1
ELR_EL3           :: Register(0x7201_1000)  // 3   6   4   0   1
ESR_EL1           :: Register(0x4290_1000)  // 3   0   5   2   0
ESR_EL2           :: Register(0x6290_1000)  // 3   4   5   2   0
FAR_EL1           :: Register(0x4300_1000)  // 3   0   6   0   0
FAR_EL2           :: Register(0x6300_1000)  // 3   4   6   0   0
ISR_EL1           :: Register(0x4608_1000)  // 3   0   12  1   0
NZCV              :: Register(0x5A10_1000)  // 3   3   4   2   0
SPSR_EL1          :: Register(0x4200_1000)  // 3   0   4   0   0
SPSR_EL2          :: Register(0x6200_1000)  // 3   4   4   0   0
SPSR_EL3          :: Register(0x7200_1000)  // 3   6   4   0   0
SP_EL0            :: Register(0x4208_1000)  // 3   0   4   1   0
SP_EL1            :: Register(0x6208_1000)  // 3   4   4   1   0
VBAR_EL1          :: Register(0x4600_1000)  // 3   0   12  0   0
VBAR_EL2          :: Register(0x6600_1000)  // 3   4   12  0   0
VBAR_EL3          :: Register(0x7600_1000)  // 3   6   12  0   0

// -----------------------------------------------------------------------------
// Floating-point control
// -----------------------------------------------------------------------------

//                                         op0 op1 CRn CRm op2
FPCR              :: Register(0x5A20_1000)  // 3   3   4   4   0
FPSR              :: Register(0x5A21_1000)  // 3   3   4   4   1
MVFR0_EL1         :: Register(0x4018_1000)  // 3   0   0   3   0
MVFR1_EL1         :: Register(0x4019_1000)  // 3   0   0   3   1
MVFR2_EL1         :: Register(0x401A_1000)  // 3   0   0   3   2

// -----------------------------------------------------------------------------
// Thread and process identity
// -----------------------------------------------------------------------------

//                                         op0 op1 CRn CRm op2
CONTEXTIDR_EL1    :: Register(0x4681_1000)  // 3   0   13  0   1
TPIDR2_EL0        :: Register(0x5E85_1000)  // 3   3   13  0   5 (SME thread pointer 2)
TPIDRRO_EL0       :: Register(0x5E83_1000)  // 3   3   13  0   3
TPIDR_EL0         :: Register(0x5E82_1000)  // 3   3   13  0   2
TPIDR_EL1         :: Register(0x4684_1000)  // 3   0   13  0   4
TPIDR_EL2         :: Register(0x6682_1000)  // 3   4   13  0   2
TPIDR_EL3         :: Register(0x7682_1000)  // 3   6   13  0   2

// -----------------------------------------------------------------------------
// Identification -- read-only feature bitmaps
// -----------------------------------------------------------------------------

//                                         op0 op1 CRn CRm op2
CCSIDR_EL1        :: Register(0x4800_1000)  // 3   1   0   0   0
CLIDR_EL1         :: Register(0x4801_1000)  // 3   1   0   0   1
CSSELR_EL1        :: Register(0x5000_1000)  // 3   2   0   0   0
CTR_EL0           :: Register(0x5801_1000)  // 3   3   0   0   1
DCZID_EL0         :: Register(0x5807_1000)  // 3   3   0   0   7 (used by __sve_max_vl-style probes too)
GMID_EL1          :: Register(0x4804_1000)  // 3   1   0   0   4 (FEAT_MTE)
ID_AA64AFR0_EL1   :: Register(0x402C_1000)  // 3   0   0   5   4 (auxiliary)
ID_AA64AFR1_EL1   :: Register(0x402D_1000)  // 3   0   0   5   5
ID_AA64DFR0_EL1   :: Register(0x4028_1000)  // 3   0   0   5   0
ID_AA64DFR1_EL1   :: Register(0x4029_1000)  // 3   0   0   5   1
ID_AA64DFR2_EL1   :: Register(0x402A_1000)  // 3   0   0   5   2
ID_AA64ISAR0_EL1  :: Register(0x4030_1000)  // 3   0   0   6   0
ID_AA64ISAR1_EL1  :: Register(0x4031_1000)  // 3   0   0   6   1
ID_AA64ISAR2_EL1  :: Register(0x4032_1000)  // 3   0   0   6   2
ID_AA64ISAR3_EL1  :: Register(0x4033_1000)  // 3   0   0   6   3
ID_AA64MMFR0_EL1  :: Register(0x4038_1000)  // 3   0   0   7   0
ID_AA64MMFR1_EL1  :: Register(0x4039_1000)  // 3   0   0   7   1
ID_AA64MMFR2_EL1  :: Register(0x403A_1000)  // 3   0   0   7   2
ID_AA64PFR0_EL1   :: Register(0x4020_1000)  // 3   0   0   4   0
ID_AA64PFR1_EL1   :: Register(0x4021_1000)  // 3   0   0   4   1
ID_AA64SMFR0_EL1  :: Register(0x4025_1000)  // 3   0   0   4   5 (SME feature ID)
ID_AA64ZFR0_EL1   :: Register(0x4024_1000)  // 3   0   0   4   4 (SVE feature ID)
ID_AFR0_EL1       :: Register(0x400B_1000)  // 3   0   0   1   3
ID_DFR0_EL1       :: Register(0x400A_1000)  // 3   0   0   1   2
ID_ISAR0_EL1      :: Register(0x4010_1000)  // 3   0   0   2   0
ID_ISAR1_EL1      :: Register(0x4011_1000)  // 3   0   0   2   1
ID_ISAR2_EL1      :: Register(0x4012_1000)  // 3   0   0   2   2
ID_ISAR3_EL1      :: Register(0x4013_1000)  // 3   0   0   2   3
ID_ISAR4_EL1      :: Register(0x4014_1000)  // 3   0   0   2   4
ID_ISAR5_EL1      :: Register(0x4015_1000)  // 3   0   0   2   5
ID_ISAR6_EL1      :: Register(0x4017_1000)  // 3   0   0   2   7
ID_MMFR0_EL1      :: Register(0x400C_1000)  // 3   0   0   1   4
ID_MMFR1_EL1      :: Register(0x400D_1000)  // 3   0   0   1   5
ID_MMFR2_EL1      :: Register(0x400E_1000)  // 3   0   0   1   6
ID_MMFR3_EL1      :: Register(0x400F_1000)  // 3   0   0   1   7
ID_MMFR4_EL1      :: Register(0x4016_1000)  // 3   0   0   2   6
ID_MMFR5_EL1      :: Register(0x401E_1000)  // 3   0   0   3   6
ID_PFR0_EL1       :: Register(0x4008_1000)  // 3   0   0   1   0
ID_PFR1_EL1       :: Register(0x4009_1000)  // 3   0   0   1   1
ID_PFR2_EL1       :: Register(0x401C_1000)  // 3   0   0   3   4
MIDR_EL1          :: Register(0x4000_1000)  // 3   0   0   0   0
MPIDR_EL1         :: Register(0x4005_1000)  // 3   0   0   0   5

// -----------------------------------------------------------------------------
// Pointer authentication keys (FEAT_PAuth)
// -----------------------------------------------------------------------------

//                                         op0 op1 CRn CRm op2
APDAKEYHI_EL1     :: Register(0x4111_1000)  // 3   0   2   2   1
APDAKEYLO_EL1     :: Register(0x4110_1000)  // 3   0   2   2   0
APDBKEYHI_EL1     :: Register(0x4113_1000)  // 3   0   2   2   3
APDBKEYLO_EL1     :: Register(0x4112_1000)  // 3   0   2   2   2
APGAKEYHI_EL1     :: Register(0x4119_1000)  // 3   0   2   3   1
APGAKEYLO_EL1     :: Register(0x4118_1000)  // 3   0   2   3   0
APIAKEYHI_EL1     :: Register(0x4109_1000)  // 3   0   2   1   1
APIAKEYLO_EL1     :: Register(0x4108_1000)  // 3   0   2   1   0 (FEAT_PAuth)
APIBKEYHI_EL1     :: Register(0x410B_1000)  // 3   0   2   1   3
APIBKEYLO_EL1     :: Register(0x410A_1000)  // 3   0   2   1   2

// -----------------------------------------------------------------------------
// Memory tagging (FEAT_MTE)
// -----------------------------------------------------------------------------

//                                         op0 op1 CRn CRm op2
GCR_EL1           :: Register(0x4086_1000)  // 3   0   1   0   6 (FEAT_MTE)
RGSR_EL1          :: Register(0x4085_1000)  // 3   0   1   0   5 (FEAT_MTE)
TFSRE0_EL1        :: Register(0x42B1_1000)  // 3   0   5   6   1 (FEAT_MTE)
TFSR_EL1          :: Register(0x42B0_1000)  // 3   0   5   6   0 (FEAT_MTE)

// -----------------------------------------------------------------------------
// SVE and SME configuration
// -----------------------------------------------------------------------------

//                                         op0 op1 CRn CRm op2
SMCR_EL1          :: Register(0x4096_1000)  // 3   0   1   2   6 (FEAT_SME)
SMCR_EL2          :: Register(0x6096_1000)  // 3   4   1   2   6
SVCR              :: Register(0x5A12_1000)  // 3   3   4   2   2 (FEAT_SME: SM + ZA bits)
ZCR_EL1           :: Register(0x4090_1000)  // 3   0   1   2   0 (FEAT_SVE)
ZCR_EL2           :: Register(0x6090_1000)  // 3   4   1   2   0
ZCR_EL3           :: Register(0x7090_1000)  // 3   6   1   2   0

// -----------------------------------------------------------------------------
// System control and memory management
// -----------------------------------------------------------------------------

//                                         op0 op1 CRn CRm op2
ACTLR_EL1         :: Register(0x4081_1000)  // 3   0   1   0   1
AMAIR_EL1         :: Register(0x4518_1000)  // 3   0   10  3   0
CPACR_EL1         :: Register(0x4082_1000)  // 3   0   1   0   2
LORC_EL1          :: Register(0x4523_1000)  // 3   0   10  4   3
LOREA_EL1         :: Register(0x4521_1000)  // 3   0   10  4   1
LORID_EL1         :: Register(0x4527_1000)  // 3   0   10  4   7
LORN_EL1          :: Register(0x4522_1000)  // 3   0   10  4   2
LORSA_EL1         :: Register(0x4520_1000)  // 3   0   10  4   0
MAIR_EL1          :: Register(0x4510_1000)  // 3   0   10  2   0
PAR_EL1           :: Register(0x43A0_1000)  // 3   0   7   4   0
SCTLR_EL1         :: Register(0x4080_1000)  // 3   0   1   0   0
SCTLR_EL2         :: Register(0x6080_1000)  // 3   4   1   0   0
SCTLR_EL3         :: Register(0x7080_1000)  // 3   6   1   0   0
TCR_EL1           :: Register(0x4102_1000)  // 3   0   2   0   2
TTBR0_EL1         :: Register(0x4100_1000)  // 3   0   2   0   0
TTBR1_EL1         :: Register(0x4101_1000)  // 3   0   2   0   1

// -----------------------------------------------------------------------------
// Generic timer
// -----------------------------------------------------------------------------

//                                         op0 op1 CRn CRm op2
CNTFRQ_EL0        :: Register(0x5F00_1000)  // 3   3   14  0   0
CNTHCTL_EL2       :: Register(0x6708_1000)  // 3   4   14  1   0
CNTHP_CTL_EL2     :: Register(0x6711_1000)  // 3   4   14  2   1
CNTHP_CVAL_EL2    :: Register(0x6712_1000)  // 3   4   14  2   2
CNTHP_TVAL_EL2    :: Register(0x6710_1000)  // 3   4   14  2   0
CNTHV_CTL_EL2     :: Register(0x6719_1000)  // 3   4   14  3   1
CNTHV_CVAL_EL2    :: Register(0x671A_1000)  // 3   4   14  3   2
CNTHV_TVAL_EL2    :: Register(0x6718_1000)  // 3   4   14  3   0
CNTKCTL_EL1       :: Register(0x4708_1000)  // 3   0   14  1   0
CNTPCT_EL0        :: Register(0x5F01_1000)  // 3   3   14  0   1
CNTPS_CTL_EL1     :: Register(0x7F11_1000)  // 3   7   14  2   1
CNTPS_CVAL_EL1    :: Register(0x7F12_1000)  // 3   7   14  2   2
CNTPS_TVAL_EL1    :: Register(0x7F10_1000)  // 3   7   14  2   0
CNTP_CTL_EL0      :: Register(0x5F11_1000)  // 3   3   14  2   1
CNTP_CVAL_EL0     :: Register(0x5F12_1000)  // 3   3   14  2   2
CNTP_TVAL_EL0     :: Register(0x5F10_1000)  // 3   3   14  2   0
CNTVCT_EL0        :: Register(0x5F02_1000)  // 3   3   14  0   2
CNTVOFF_EL2       :: Register(0x6703_1000)  // 3   4   14  0   3
CNTV_CTL_EL0      :: Register(0x5F19_1000)  // 3   3   14  3   1
CNTV_CVAL_EL0     :: Register(0x5F1A_1000)  // 3   3   14  3   2
CNTV_TVAL_EL0     :: Register(0x5F18_1000)  // 3   3   14  3   0

// -----------------------------------------------------------------------------
// Statistical profiling (FEAT_SPE)
// -----------------------------------------------------------------------------

//                                         op0 op1 CRn CRm op2
PMBIDR_EL1        :: Register(0x44D7_1000)  // 3   0   9   10  7
PMBLIMITR_EL1     :: Register(0x44D0_1000)  // 3   0   9   10  0
PMBPTR_EL1        :: Register(0x44D1_1000)  // 3   0   9   10  1
PMBSR_EL1         :: Register(0x44D3_1000)  // 3   0   9   10  3
PMSCR_EL1         :: Register(0x44C8_1000)  // 3   0   9   9   0
PMSELR_EL0        :: Register(0x5CE5_1000)  // 3   3   9   12  5
PMSEVFR_EL1       :: Register(0x44CD_1000)  // 3   0   9   9   5
PMSFCR_EL1        :: Register(0x44CC_1000)  // 3   0   9   9   4
PMSICR_EL1        :: Register(0x44CA_1000)  // 3   0   9   9   2
PMSIDR_EL1        :: Register(0x44CF_1000)  // 3   0   9   9   7
PMSIRR_EL1        :: Register(0x44CB_1000)  // 3   0   9   9   3
PMSLATFR_EL1      :: Register(0x44CE_1000)  // 3   0   9   9   6
PMSWINC_EL0       :: Register(0x5CE4_1000)  // 3   3   9   12  4

// -----------------------------------------------------------------------------
// Performance monitors
// -----------------------------------------------------------------------------

//                                         op0 op1 CRn CRm op2
PMCCFILTR_EL0     :: Register(0x5F7F_1000)  // 3   3   14  15  7
PMCCNTR_EL0       :: Register(0x5CE8_1000)  // 3   3   9   13  0
PMCEID0_EL0       :: Register(0x5CE6_1000)  // 3   3   9   12  6
PMCEID1_EL0       :: Register(0x5CE7_1000)  // 3   3   9   12  7
PMCNTENCLR_EL0    :: Register(0x5CE2_1000)  // 3   3   9   12  2
PMCNTENSET_EL0    :: Register(0x5CE1_1000)  // 3   3   9   12  1
PMCR_EL0          :: Register(0x5CE0_1000)  // 3   3   9   12  0
PMINTENCLR_EL1    :: Register(0x44F2_1000)  // 3   0   9   14  2
PMINTENSET_EL1    :: Register(0x44F1_1000)  // 3   0   9   14  1
PMOVSCLR_EL0      :: Register(0x5CE3_1000)  // 3   3   9   12  3
PMUSERENR_EL0     :: Register(0x5CF0_1000)  // 3   3   9   14  0

// -----------------------------------------------------------------------------
// Trace
// -----------------------------------------------------------------------------

//                                         op0 op1 CRn CRm op2
TRBBASER_EL1      :: Register(0x44DA_1000)  // 3   0   9   11  2
TRBIDR_EL1        :: Register(0x44DF_1000)  // 3   0   9   11  7
TRBLIMITR_EL1     :: Register(0x44D8_1000)  // 3   0   9   11  0
TRBMAR_EL1        :: Register(0x44DC_1000)  // 3   0   9   11  4
TRBPTR_EL1        :: Register(0x44D9_1000)  // 3   0   9   11  1
TRBSR_EL1         :: Register(0x44DB_1000)  // 3   0   9   11  3
TRBTRG_EL1        :: Register(0x44DE_1000)  // 3   0   9   11  6

// -----------------------------------------------------------------------------
// Debug
// -----------------------------------------------------------------------------

//                                         op0 op1 CRn CRm op2
DBGAUTHSTATUS_EL1 :: Register(0x03F6_1000)  // 2   0   7   14  6
DBGCLAIMCLR_EL1   :: Register(0x03CE_1000)  // 2   0   7   9   6
DBGCLAIMSET_EL1   :: Register(0x03C6_1000)  // 2   0   7   8   6
DBGDTRRX_EL0      :: Register(0x1828_1000)  // 2   3   0   5   0
DBGDTRTX_EL0      :: Register(0x1828_1000)  // 2   3   0   5   0 (write view of DBGDTRRX_EL0)
DBGDTR_EL0        :: Register(0x1820_1000)  // 2   3   0   4   0
DBGPRCR_EL1       :: Register(0x00A4_1000)  // 2   0   1   4   4
DLR_EL0           :: Register(0x5A29_1000)  // 3   3   4   5   1
DSPSR_EL0         :: Register(0x5A28_1000)  // 3   3   4   5   0
MDCCINT_EL1       :: Register(0x0010_1000)  // 2   0   0   2   0
MDRAR_EL1         :: Register(0x0080_1000)  // 2   0   1   0   0
MDSCR_EL1         :: Register(0x0012_1000)  // 2   0   0   2   2
OSLAR_EL1         :: Register(0x0084_1000)  // 2   0   1   0   4 (op0=2 -> o0=0)
OSLSR_EL1         :: Register(0x008C_1000)  // 2   0   1   1   4
PRSELR_EL1        :: Register(0x4311_1000)  // 3   0   6   2   1

// -----------------------------------------------------------------------------
// Generic interrupt controller
// -----------------------------------------------------------------------------

//                                         op0 op1 CRn CRm op2
ICC_ASGI1R_EL1    :: Register(0x465E_1000)  // 3   0   12  11  6
ICC_BPR0_EL1      :: Register(0x4643_1000)  // 3   0   12  8   3
ICC_BPR1_EL1      :: Register(0x4663_1000)  // 3   0   12  12  3
ICC_CTLR_EL1      :: Register(0x4664_1000)  // 3   0   12  12  4
ICC_CTLR_EL3      :: Register(0x7664_1000)  // 3   6   12  12  4
ICC_DIR_EL1       :: Register(0x4659_1000)  // 3   0   12  11  1
ICC_EOIR0_EL1     :: Register(0x4641_1000)  // 3   0   12  8   1
ICC_EOIR1_EL1     :: Register(0x4661_1000)  // 3   0   12  12  1
ICC_HPPIR0_EL1    :: Register(0x4642_1000)  // 3   0   12  8   2
ICC_HPPIR1_EL1    :: Register(0x4662_1000)  // 3   0   12  12  2
ICC_IAR0_EL1      :: Register(0x4640_1000)  // 3   0   12  8   0
ICC_IAR1_EL1      :: Register(0x4660_1000)  // 3   0   12  12  0
ICC_IGRPEN0_EL1   :: Register(0x4666_1000)  // 3   0   12  12  6
ICC_IGRPEN1_EL1   :: Register(0x4667_1000)  // 3   0   12  12  7
ICC_IGRPEN1_EL3   :: Register(0x7667_1000)  // 3   6   12  12  7
ICC_PMR_EL1       :: Register(0x4230_1000)  // 3   0   4   6   0
ICC_RPR_EL1       :: Register(0x465B_1000)  // 3   0   12  11  3
ICC_SGI0R_EL1     :: Register(0x465F_1000)  // 3   0   12  11  7
ICC_SGI1R_EL1     :: Register(0x465D_1000)  // 3   0   12  11  5
ICC_SRE_EL1       :: Register(0x4665_1000)  // 3   0   12  12  5
ICC_SRE_EL2       :: Register(0x664D_1000)  // 3   4   12  9   5
ICC_SRE_EL3       :: Register(0x7665_1000)  // 3   6   12  12  5
ICH_EISR_EL2      :: Register(0x665B_1000)  // 3   4   12  11  3
ICH_ELRSR_EL2     :: Register(0x665D_1000)  // 3   4   12  11  5
ICH_HCR_EL2       :: Register(0x6658_1000)  // 3   4   12  11  0
ICH_MISR_EL2      :: Register(0x665A_1000)  // 3   4   12  11  2
ICH_VMCR_EL2      :: Register(0x665F_1000)  // 3   4   12  11  7
ICH_VTR_EL2       :: Register(0x6659_1000)  // 3   4   12  11  1

// -----------------------------------------------------------------------------
// RAS -- error record registers
// -----------------------------------------------------------------------------

//                                         op0 op1 CRn CRm op2
DISR_EL1          :: Register(0x4609_1000)  // 3   0   12  1   1
ERRIDR_EL1        :: Register(0x4298_1000)  // 3   0   5   3   0
ERRSELR_EL1       :: Register(0x4299_1000)  // 3   0   5   3   1
ERXADDR_EL1       :: Register(0x42A3_1000)  // 3   0   5   4   3
ERXCTLR_EL1       :: Register(0x42A1_1000)  // 3   0   5   4   1
ERXFR_EL1         :: Register(0x42A0_1000)  // 3   0   5   4   0
ERXMISC0_EL1      :: Register(0x42A8_1000)  // 3   0   5   5   0
ERXMISC1_EL1      :: Register(0x42A9_1000)  // 3   0   5   5   1
ERXMISC2_EL1      :: Register(0x42AA_1000)  // 3   0   5   5   2
ERXMISC3_EL1      :: Register(0x42AB_1000)  // 3   0   5   5   3
ERXSTATUS_EL1     :: Register(0x42A2_1000)  // 3   0   5   4   2
VDISR_EL2         :: Register(0x6609_1000)  // 3   4   12  1   1
VSESR_EL2         :: Register(0x6293_1000)  // 3   4   5   2   3

// -----------------------------------------------------------------------------
// Virtualisation (EL2) and secure monitor (EL3)
// -----------------------------------------------------------------------------

//                                         op0 op1 CRn CRm op2
GPCCR_EL3         :: Register(0x710E_1000)  // 3   6   2   1   6 (Granule Protection Control)
GPTBR_EL3         :: Register(0x710C_1000)  // 3   6   2   1   4 (Granule Protection Table Base)
HCR_EL2           :: Register(0x6088_1000)  // 3   4   1   1   0
HSTR_EL2          :: Register(0x608B_1000)  // 3   4   1   1   3
MDCR_EL2          :: Register(0x6089_1000)  // 3   4   1   1   1
MFAR_EL3          :: Register(0x7305_1000)  // 3   6   6   0   5 (Multiple FAR)
VTCR_EL2          :: Register(0x610A_1000)  // 3   4   2   1   2
VTTBR_EL2         :: Register(0x6108_1000)  // 3   4   2   1   0

// -----------------------------------------------------------------------------
// AArch32 compatibility
// -----------------------------------------------------------------------------

//                                         op0 op1 CRn CRm op2
DACR32_EL2        :: Register(0x6180_1000)  // 3   4   3   0   0
FPEXC32_EL2       :: Register(0x6298_1000)  // 3   4   5   3   0

// -----------------------------------------------------------------------------
// Random number (FEAT_RNG)
// -----------------------------------------------------------------------------

//                                         op0 op1 CRn CRm op2
RNDR              :: Register(0x5920_1000)  // 3   3   2   4   0
RNDRRS            :: Register(0x5921_1000)  // 3   3   2   4   1

// -----------------------------------------------------------------------------
// Value -> name, for printing
// -----------------------------------------------------------------------------
//
// A disassembly has the packed field where an assembler wants a name. Sorted
// by value; binary search.
//
// 1 encoding carries two names: DBGDTRRX_EL0 and DBGDTRTX_EL0 are the read
// and write views of one register. The read name wins, since MRS is the
// direction that has to print.

Sysreg_Name :: struct {
	value: u16,      // the bare 15-bit MRS/MSR field (what sysreg_bits returns)
	name:  string,
}

@(rodata)
SYSREG_NAMES := [?]Sysreg_Name{
	{0x0010, "mdccint_el1"},
	{0x0012, "mdscr_el1"},
	{0x0080, "mdrar_el1"},
	{0x0084, "oslar_el1"},
	{0x008C, "oslsr_el1"},
	{0x00A4, "dbgprcr_el1"},
	{0x03C6, "dbgclaimset_el1"},
	{0x03CE, "dbgclaimclr_el1"},
	{0x03F6, "dbgauthstatus_el1"},
	{0x1820, "dbgdtr_el0"},
	{0x1828, "dbgdtrrx_el0"},
	{0x4000, "midr_el1"},
	{0x4005, "mpidr_el1"},
	{0x4008, "id_pfr0_el1"},
	{0x4009, "id_pfr1_el1"},
	{0x400A, "id_dfr0_el1"},
	{0x400B, "id_afr0_el1"},
	{0x400C, "id_mmfr0_el1"},
	{0x400D, "id_mmfr1_el1"},
	{0x400E, "id_mmfr2_el1"},
	{0x400F, "id_mmfr3_el1"},
	{0x4010, "id_isar0_el1"},
	{0x4011, "id_isar1_el1"},
	{0x4012, "id_isar2_el1"},
	{0x4013, "id_isar3_el1"},
	{0x4014, "id_isar4_el1"},
	{0x4015, "id_isar5_el1"},
	{0x4016, "id_mmfr4_el1"},
	{0x4017, "id_isar6_el1"},
	{0x4018, "mvfr0_el1"},
	{0x4019, "mvfr1_el1"},
	{0x401A, "mvfr2_el1"},
	{0x401C, "id_pfr2_el1"},
	{0x401E, "id_mmfr5_el1"},
	{0x4020, "id_aa64pfr0_el1"},
	{0x4021, "id_aa64pfr1_el1"},
	{0x4024, "id_aa64zfr0_el1"},
	{0x4025, "id_aa64smfr0_el1"},
	{0x4028, "id_aa64dfr0_el1"},
	{0x4029, "id_aa64dfr1_el1"},
	{0x402A, "id_aa64dfr2_el1"},
	{0x402C, "id_aa64afr0_el1"},
	{0x402D, "id_aa64afr1_el1"},
	{0x4030, "id_aa64isar0_el1"},
	{0x4031, "id_aa64isar1_el1"},
	{0x4032, "id_aa64isar2_el1"},
	{0x4033, "id_aa64isar3_el1"},
	{0x4038, "id_aa64mmfr0_el1"},
	{0x4039, "id_aa64mmfr1_el1"},
	{0x403A, "id_aa64mmfr2_el1"},
	{0x4080, "sctlr_el1"},
	{0x4081, "actlr_el1"},
	{0x4082, "cpacr_el1"},
	{0x4085, "rgsr_el1"},
	{0x4086, "gcr_el1"},
	{0x4090, "zcr_el1"},
	{0x4096, "smcr_el1"},
	{0x4100, "ttbr0_el1"},
	{0x4101, "ttbr1_el1"},
	{0x4102, "tcr_el1"},
	{0x4108, "apiakeylo_el1"},
	{0x4109, "apiakeyhi_el1"},
	{0x410A, "apibkeylo_el1"},
	{0x410B, "apibkeyhi_el1"},
	{0x4110, "apdakeylo_el1"},
	{0x4111, "apdakeyhi_el1"},
	{0x4112, "apdbkeylo_el1"},
	{0x4113, "apdbkeyhi_el1"},
	{0x4118, "apgakeylo_el1"},
	{0x4119, "apgakeyhi_el1"},
	{0x4200, "spsr_el1"},
	{0x4201, "elr_el1"},
	{0x4208, "sp_el0"},
	{0x4212, "currentel"},
	{0x4230, "icc_pmr_el1"},
	{0x4288, "afsr0_el1"},
	{0x4289, "afsr1_el1"},
	{0x4290, "esr_el1"},
	{0x4298, "erridr_el1"},
	{0x4299, "errselr_el1"},
	{0x42A0, "erxfr_el1"},
	{0x42A1, "erxctlr_el1"},
	{0x42A2, "erxstatus_el1"},
	{0x42A3, "erxaddr_el1"},
	{0x42A8, "erxmisc0_el1"},
	{0x42A9, "erxmisc1_el1"},
	{0x42AA, "erxmisc2_el1"},
	{0x42AB, "erxmisc3_el1"},
	{0x42B0, "tfsr_el1"},
	{0x42B1, "tfsre0_el1"},
	{0x4300, "far_el1"},
	{0x4311, "prselr_el1"},
	{0x43A0, "par_el1"},
	{0x44C8, "pmscr_el1"},
	{0x44CA, "pmsicr_el1"},
	{0x44CB, "pmsirr_el1"},
	{0x44CC, "pmsfcr_el1"},
	{0x44CD, "pmsevfr_el1"},
	{0x44CE, "pmslatfr_el1"},
	{0x44CF, "pmsidr_el1"},
	{0x44D0, "pmblimitr_el1"},
	{0x44D1, "pmbptr_el1"},
	{0x44D3, "pmbsr_el1"},
	{0x44D7, "pmbidr_el1"},
	{0x44D8, "trblimitr_el1"},
	{0x44D9, "trbptr_el1"},
	{0x44DA, "trbbaser_el1"},
	{0x44DB, "trbsr_el1"},
	{0x44DC, "trbmar_el1"},
	{0x44DE, "trbtrg_el1"},
	{0x44DF, "trbidr_el1"},
	{0x44F1, "pmintenset_el1"},
	{0x44F2, "pmintenclr_el1"},
	{0x4510, "mair_el1"},
	{0x4518, "amair_el1"},
	{0x4520, "lorsa_el1"},
	{0x4521, "lorea_el1"},
	{0x4522, "lorn_el1"},
	{0x4523, "lorc_el1"},
	{0x4527, "lorid_el1"},
	{0x4600, "vbar_el1"},
	{0x4608, "isr_el1"},
	{0x4609, "disr_el1"},
	{0x4640, "icc_iar0_el1"},
	{0x4641, "icc_eoir0_el1"},
	{0x4642, "icc_hppir0_el1"},
	{0x4643, "icc_bpr0_el1"},
	{0x4659, "icc_dir_el1"},
	{0x465B, "icc_rpr_el1"},
	{0x465D, "icc_sgi1r_el1"},
	{0x465E, "icc_asgi1r_el1"},
	{0x465F, "icc_sgi0r_el1"},
	{0x4660, "icc_iar1_el1"},
	{0x4661, "icc_eoir1_el1"},
	{0x4662, "icc_hppir1_el1"},
	{0x4663, "icc_bpr1_el1"},
	{0x4664, "icc_ctlr_el1"},
	{0x4665, "icc_sre_el1"},
	{0x4666, "icc_igrpen0_el1"},
	{0x4667, "icc_igrpen1_el1"},
	{0x4681, "contextidr_el1"},
	{0x4684, "tpidr_el1"},
	{0x4708, "cntkctl_el1"},
	{0x4800, "ccsidr_el1"},
	{0x4801, "clidr_el1"},
	{0x4804, "gmid_el1"},
	{0x5000, "csselr_el1"},
	{0x5801, "ctr_el0"},
	{0x5807, "dczid_el0"},
	{0x5920, "rndr"},
	{0x5921, "rndrrs"},
	{0x5A10, "nzcv"},
	{0x5A11, "daif"},
	{0x5A12, "svcr"},
	{0x5A20, "fpcr"},
	{0x5A21, "fpsr"},
	{0x5A28, "dspsr_el0"},
	{0x5A29, "dlr_el0"},
	{0x5CE0, "pmcr_el0"},
	{0x5CE1, "pmcntenset_el0"},
	{0x5CE2, "pmcntenclr_el0"},
	{0x5CE3, "pmovsclr_el0"},
	{0x5CE4, "pmswinc_el0"},
	{0x5CE5, "pmselr_el0"},
	{0x5CE6, "pmceid0_el0"},
	{0x5CE7, "pmceid1_el0"},
	{0x5CE8, "pmccntr_el0"},
	{0x5CF0, "pmuserenr_el0"},
	{0x5E82, "tpidr_el0"},
	{0x5E83, "tpidrro_el0"},
	{0x5E85, "tpidr2_el0"},
	{0x5F00, "cntfrq_el0"},
	{0x5F01, "cntpct_el0"},
	{0x5F02, "cntvct_el0"},
	{0x5F10, "cntp_tval_el0"},
	{0x5F11, "cntp_ctl_el0"},
	{0x5F12, "cntp_cval_el0"},
	{0x5F18, "cntv_tval_el0"},
	{0x5F19, "cntv_ctl_el0"},
	{0x5F1A, "cntv_cval_el0"},
	{0x5F7F, "pmccfiltr_el0"},
	{0x6080, "sctlr_el2"},
	{0x6088, "hcr_el2"},
	{0x6089, "mdcr_el2"},
	{0x608B, "hstr_el2"},
	{0x6090, "zcr_el2"},
	{0x6096, "smcr_el2"},
	{0x6108, "vttbr_el2"},
	{0x610A, "vtcr_el2"},
	{0x6180, "dacr32_el2"},
	{0x6200, "spsr_el2"},
	{0x6201, "elr_el2"},
	{0x6208, "sp_el1"},
	{0x6290, "esr_el2"},
	{0x6293, "vsesr_el2"},
	{0x6298, "fpexc32_el2"},
	{0x6300, "far_el2"},
	{0x6600, "vbar_el2"},
	{0x6609, "vdisr_el2"},
	{0x664D, "icc_sre_el2"},
	{0x6658, "ich_hcr_el2"},
	{0x6659, "ich_vtr_el2"},
	{0x665A, "ich_misr_el2"},
	{0x665B, "ich_eisr_el2"},
	{0x665D, "ich_elrsr_el2"},
	{0x665F, "ich_vmcr_el2"},
	{0x6682, "tpidr_el2"},
	{0x6703, "cntvoff_el2"},
	{0x6708, "cnthctl_el2"},
	{0x6710, "cnthp_tval_el2"},
	{0x6711, "cnthp_ctl_el2"},
	{0x6712, "cnthp_cval_el2"},
	{0x6718, "cnthv_tval_el2"},
	{0x6719, "cnthv_ctl_el2"},
	{0x671A, "cnthv_cval_el2"},
	{0x7080, "sctlr_el3"},
	{0x7090, "zcr_el3"},
	{0x710C, "gptbr_el3"},
	{0x710E, "gpccr_el3"},
	{0x7200, "spsr_el3"},
	{0x7201, "elr_el3"},
	{0x7305, "mfar_el3"},
	{0x7600, "vbar_el3"},
	{0x7664, "icc_ctlr_el3"},
	{0x7665, "icc_sre_el3"},
	{0x7667, "icc_igrpen1_el3"},
	{0x7682, "tpidr_el3"},
	{0x7F10, "cntps_tval_el1"},
	{0x7F11, "cntps_ctl_el1"},
	{0x7F12, "cntps_cval_el1"},
}

// Name for a system register, or ok=false when it is not one we know --
// callers should fall back to printing the raw field.
@(require_results)
sysreg_name :: proc "contextless" (sr: Register) -> (name: string, ok: bool) {
	v := u16(sysreg_bits(sr))
	lo, hi := 0, len(SYSREG_NAMES) - 1
	for lo <= hi {
		mid := (lo + hi) / 2
		e := SYSREG_NAMES[mid]
		switch {
		case e.value == v: return e.name, true
		case e.value <  v: lo = mid + 1
		case:              hi = mid - 1
		}
	}
	return "", false
}
