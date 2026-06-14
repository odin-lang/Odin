package rexcode_ppc

// =============================================================================
// PowerPC REGISTERS
// =============================================================================
//
// Register classes — top nibble of the u16 Register value selects the class,
// low 12 bits hold the hardware index. The wider hw field is needed because
// SPR values run up to 1023 (10-bit field on the wire) — see e.g. TBL=268.
//
//   GPR    r0..r31         32 general-purpose (32-bit on PPC32, 64-bit on PPC64)
//   FPR    f0..f31         32 floating-point
//   VR     v0..v31         32 AltiVec (128-bit)
//   VSR    vs0..vs63       64 VSX. vs0..vs31 alias f0..f31; vs32..vs63 alias v0..v31.
//   CR     full 32-bit condition register (a single register addressed
//          by field via the CR_FIELD operand type, or by bit via CR_BIT).
//   CRF    cr0..cr7        the 8 4-bit CR fields, addressed individually.
//   SPR    LR/CTR/XER/...  numbered special-purpose registers (10-bit SPR field
//          on wire; the high and low 5 bits are SWAPPED in encoded form)
//   VR128  vr0..vr127      VMX128 vector registers (7-bit hw index)
//
// PPC convention: r0 in the "RA" slot of D-form load/store/addi means *literal
// zero*, not r0's value. The Operand_Type GPR_OR_ZERO opts into this; the
// encoder/decoder treat r0-in-RA as the zero source unless the form is a
// "real" GPR-only form.
//
// Sibling package `ppc_vle` uses the same scheme so register values are
// interchangeable for shared-mnemonic ops.

Register :: distinct u16

REG_NONE  :: 0x0000
REG_GPR   :: 0x1000
REG_FPR   :: 0x2000
REG_VR    :: 0x3000
REG_VSR   :: 0x4000
REG_CR    :: 0x5000   // CRF: cr0..cr7 in low 3 bits
REG_SPR   :: 0x6000   // SPR number in low 10 bits (0..1023)
REG_VR128 :: 0x7000   // VMX128 vector register (vr0..vr127, 7-bit hw index)

NONE :: Register(0xFFFF)

reg_hw    :: #force_inline proc "contextless" (r: Register) -> u16 { return u16(r) & 0x0FFF }
reg_class :: #force_inline proc "contextless" (r: Register) -> u16 { return u16(r) & 0xF000 }

reg_is_gpr   :: #force_inline proc "contextless" (r: Register) -> bool { return reg_class(r) == REG_GPR }
reg_is_fpr   :: #force_inline proc "contextless" (r: Register) -> bool { return reg_class(r) == REG_FPR }
reg_is_vr    :: #force_inline proc "contextless" (r: Register) -> bool { return reg_class(r) == REG_VR  }
reg_is_vsr   :: #force_inline proc "contextless" (r: Register) -> bool { return reg_class(r) == REG_VSR }
reg_is_cr    :: #force_inline proc "contextless" (r: Register) -> bool { return reg_class(r) == REG_CR  }
reg_is_spr   :: #force_inline proc "contextless" (r: Register) -> bool { return reg_class(r) == REG_SPR }
reg_is_vr128 :: #force_inline proc "contextless" (r: Register) -> bool { return reg_class(r) == REG_VR128 }

// VMX128: vr0..vr127, 7-bit hw index. Constructor for the Xenon-specific
// extended vector register file.
vr128_reg :: #force_inline proc "contextless" (n: u8) -> Register { return Register(REG_VR128 | u16(n & 0x7F)) }

// -----------------------------------------------------------------------------
// GPRs
// -----------------------------------------------------------------------------

R0  :: Register(REG_GPR | 0);  R1  :: Register(REG_GPR | 1);  R2  :: Register(REG_GPR | 2);  R3  :: Register(REG_GPR | 3)
R4  :: Register(REG_GPR | 4);  R5  :: Register(REG_GPR | 5);  R6  :: Register(REG_GPR | 6);  R7  :: Register(REG_GPR | 7)
R8  :: Register(REG_GPR | 8);  R9  :: Register(REG_GPR | 9);  R10 :: Register(REG_GPR | 10); R11 :: Register(REG_GPR | 11)
R12 :: Register(REG_GPR | 12); R13 :: Register(REG_GPR | 13); R14 :: Register(REG_GPR | 14); R15 :: Register(REG_GPR | 15)
R16 :: Register(REG_GPR | 16); R17 :: Register(REG_GPR | 17); R18 :: Register(REG_GPR | 18); R19 :: Register(REG_GPR | 19)
R20 :: Register(REG_GPR | 20); R21 :: Register(REG_GPR | 21); R22 :: Register(REG_GPR | 22); R23 :: Register(REG_GPR | 23)
R24 :: Register(REG_GPR | 24); R25 :: Register(REG_GPR | 25); R26 :: Register(REG_GPR | 26); R27 :: Register(REG_GPR | 27)
R28 :: Register(REG_GPR | 28); R29 :: Register(REG_GPR | 29); R30 :: Register(REG_GPR | 30); R31 :: Register(REG_GPR | 31)

// ABI conventions (System V / PowerOpen / ELFv2):
//   r1 = stack pointer
//   r2 = TOC pointer (ELFv2) / system reserved (Linux)
//   r3..r10 = arg/return regs
//   r13 = TLS pointer (Linux) / small data anchor (eabi)
SP_PPC :: R1

// -----------------------------------------------------------------------------
// FPRs
// -----------------------------------------------------------------------------

F0  :: Register(REG_FPR | 0);  F1  :: Register(REG_FPR | 1);  F2  :: Register(REG_FPR | 2);  F3  :: Register(REG_FPR | 3)
F4  :: Register(REG_FPR | 4);  F5  :: Register(REG_FPR | 5);  F6  :: Register(REG_FPR | 6);  F7  :: Register(REG_FPR | 7)
F8  :: Register(REG_FPR | 8);  F9  :: Register(REG_FPR | 9);  F10 :: Register(REG_FPR | 10); F11 :: Register(REG_FPR | 11)
F12 :: Register(REG_FPR | 12); F13 :: Register(REG_FPR | 13); F14 :: Register(REG_FPR | 14); F15 :: Register(REG_FPR | 15)
F16 :: Register(REG_FPR | 16); F17 :: Register(REG_FPR | 17); F18 :: Register(REG_FPR | 18); F19 :: Register(REG_FPR | 19)
F20 :: Register(REG_FPR | 20); F21 :: Register(REG_FPR | 21); F22 :: Register(REG_FPR | 22); F23 :: Register(REG_FPR | 23)
F24 :: Register(REG_FPR | 24); F25 :: Register(REG_FPR | 25); F26 :: Register(REG_FPR | 26); F27 :: Register(REG_FPR | 27)
F28 :: Register(REG_FPR | 28); F29 :: Register(REG_FPR | 29); F30 :: Register(REG_FPR | 30); F31 :: Register(REG_FPR | 31)

// -----------------------------------------------------------------------------
// AltiVec VRs
// -----------------------------------------------------------------------------

V0  :: Register(REG_VR | 0);  V1  :: Register(REG_VR | 1);  V2  :: Register(REG_VR | 2);  V3  :: Register(REG_VR | 3)
V4  :: Register(REG_VR | 4);  V5  :: Register(REG_VR | 5);  V6  :: Register(REG_VR | 6);  V7  :: Register(REG_VR | 7)
V8  :: Register(REG_VR | 8);  V9  :: Register(REG_VR | 9);  V10 :: Register(REG_VR | 10); V11 :: Register(REG_VR | 11)
V12 :: Register(REG_VR | 12); V13 :: Register(REG_VR | 13); V14 :: Register(REG_VR | 14); V15 :: Register(REG_VR | 15)
V16 :: Register(REG_VR | 16); V17 :: Register(REG_VR | 17); V18 :: Register(REG_VR | 18); V19 :: Register(REG_VR | 19)
V20 :: Register(REG_VR | 20); V21 :: Register(REG_VR | 21); V22 :: Register(REG_VR | 22); V23 :: Register(REG_VR | 23)
V24 :: Register(REG_VR | 24); V25 :: Register(REG_VR | 25); V26 :: Register(REG_VR | 26); V27 :: Register(REG_VR | 27)
V28 :: Register(REG_VR | 28); V29 :: Register(REG_VR | 29); V30 :: Register(REG_VR | 30); V31 :: Register(REG_VR | 31)

// -----------------------------------------------------------------------------
// VSX (64 registers; vs0..vs31 alias f0..f31, vs32..vs63 alias v0..v31)
// -----------------------------------------------------------------------------

vs_reg :: #force_inline proc "contextless" (n: u8) -> Register { return Register(REG_VSR | u16(n & 0x3F)) }

// -----------------------------------------------------------------------------
// CR (condition register) — 8 4-bit fields cr0..cr7
// -----------------------------------------------------------------------------

CR0 :: Register(REG_CR | 0)
CR1 :: Register(REG_CR | 1)
CR2 :: Register(REG_CR | 2)
CR3 :: Register(REG_CR | 3)
CR4 :: Register(REG_CR | 4)
CR5 :: Register(REG_CR | 5)
CR6 :: Register(REG_CR | 6)
CR7 :: Register(REG_CR | 7)

// -----------------------------------------------------------------------------
// SPRs (selected, see Power ISA Book III §4 for the full numbered set)
// -----------------------------------------------------------------------------

spr_reg :: #force_inline proc "contextless" (n: u16) -> Register { return Register(REG_SPR) | Register(n & 0x3FF) }

XER     :: Register(REG_SPR | 1)
LR      :: Register(REG_SPR | 8)
CTR     :: Register(REG_SPR | 9)
DSCR    :: Register(REG_SPR | 17)   // ISA 2.06
DSISR   :: Register(REG_SPR | 18)
DAR     :: Register(REG_SPR | 19)
DEC     :: Register(REG_SPR | 22)
SRR0    :: Register(REG_SPR | 26)
SRR1    :: Register(REG_SPR | 27)
TBL     :: Register(REG_SPR | 268)
TBU     :: Register(REG_SPR | 269)
VRSAVE  :: Register(REG_SPR | 256)
