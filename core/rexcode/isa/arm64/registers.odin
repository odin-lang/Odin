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

Register :: distinct u16

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

NONE :: Register(0xFFFF)

@(require_results) reg_hw    :: #force_inline proc "contextless" (r: Register) -> u8  { return u8(r) & 0x1F }
@(require_results) reg_class :: #force_inline proc "contextless" (r: Register) -> u16 { return u16(r) & 0xFF00 }

@(require_results) reg_is_x   :: #force_inline proc "contextless" (r: Register) -> bool { return reg_class(r) == REG_X   }
@(require_results) reg_is_w   :: #force_inline proc "contextless" (r: Register) -> bool { return reg_class(r) == REG_W   }
@(require_results) reg_is_xsp :: #force_inline proc "contextless" (r: Register) -> bool { return reg_class(r) == REG_XSP }
@(require_results) reg_is_wsp :: #force_inline proc "contextless" (r: Register) -> bool { return reg_class(r) == REG_WSP }

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
