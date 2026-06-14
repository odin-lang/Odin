package rexcode_arm32

// =============================================================================
// AArch32 REGISTERS
// =============================================================================
//
// The Register type is a u8: high 3 bits encode the register class, low 5 bits
// the hardware number. This keeps the encoder/decoder fast (single byte) and
// trivially extractable via masks.
//
//   Bits 7-5  Class   Members
//   ----------------------------------------------------------------------
//   000       GPR     R0..R15 (R13=SP, R14=LR, R15=PC)
//   001       SPR     S0..S31 (VFP single-precision; aliases low D regs)
//   010       DPR     D0..D31 (VFP/NEON double-precision)
//   011       QPR     Q0..Q15 (NEON 128-bit; aliases D2n / D2n+1)
//   100       SREG    PSR/CPSR/SPSR/APSR (limited)
//   101       FPSC    FPSCR / FPSID / FPEXC / etc.
//   110       BANKED  Banked SPSR_*/R*_* registers (MSR/MRS specialised)
//   111       COPROC  Coprocessor register (CPx CRn / CRm) -- value stored as packed
//
// The hw number is masked to 5 bits, giving 32 possible regs per class
// (sufficient for VFPv3+'s D0..D31 and NEON's S0..S31 / Q0..Q15).

Register :: distinct u16

REG_NONE   :: u16(0x0000)
REG_GPR    :: u16(0x1000)
REG_SPR    :: u16(0x2000)
REG_DPR    :: u16(0x3000)
REG_QPR    :: u16(0x4000)
REG_SREG   :: u16(0x5000)
REG_FPSC   :: u16(0x6000)
REG_BANKED :: u16(0x7000)
REG_COPROC :: u16(0x8000)

REG_CLASS_MASK :: u16(0xF000)
REG_HW_MASK    :: u16(0x0FFF)

// ---- GPR ---------------------------------------------------------------------
R0  :: Register(REG_GPR | 0)
R1  :: Register(REG_GPR | 1)
R2  :: Register(REG_GPR | 2)
R3  :: Register(REG_GPR | 3)
R4  :: Register(REG_GPR | 4)
R5  :: Register(REG_GPR | 5)
R6  :: Register(REG_GPR | 6)
R7  :: Register(REG_GPR | 7)
R8  :: Register(REG_GPR | 8)
R9  :: Register(REG_GPR | 9)
R10 :: Register(REG_GPR | 10)
R11 :: Register(REG_GPR | 11)
R12 :: Register(REG_GPR | 12)
R13 :: Register(REG_GPR | 13)
R14 :: Register(REG_GPR | 14)
R15 :: Register(REG_GPR | 15)

// Conventional aliases
SB  :: R9                      // static base (PCS)
SL  :: R10                     // stack limit
FP  :: R11                     // frame pointer
IP  :: R12                     // intra-procedure scratch
SP  :: R13                     // stack pointer
LR  :: R14                     // link register
PC  :: R15                     // program counter

// ---- VFP single-precision ---------------------------------------------------
S0  :: Register(REG_SPR | 0)
S1  :: Register(REG_SPR | 1)
S2  :: Register(REG_SPR | 2)
S3  :: Register(REG_SPR | 3)
S4  :: Register(REG_SPR | 4)
S5  :: Register(REG_SPR | 5)
S6  :: Register(REG_SPR | 6)
S7  :: Register(REG_SPR | 7)
S8  :: Register(REG_SPR | 8)
S9  :: Register(REG_SPR | 9)
S10 :: Register(REG_SPR | 10)
S11 :: Register(REG_SPR | 11)
S12 :: Register(REG_SPR | 12)
S13 :: Register(REG_SPR | 13)
S14 :: Register(REG_SPR | 14)
S15 :: Register(REG_SPR | 15)
S16 :: Register(REG_SPR | 16)
S17 :: Register(REG_SPR | 17)
S18 :: Register(REG_SPR | 18)
S19 :: Register(REG_SPR | 19)
S20 :: Register(REG_SPR | 20)
S21 :: Register(REG_SPR | 21)
S22 :: Register(REG_SPR | 22)
S23 :: Register(REG_SPR | 23)
S24 :: Register(REG_SPR | 24)
S25 :: Register(REG_SPR | 25)
S26 :: Register(REG_SPR | 26)
S27 :: Register(REG_SPR | 27)
S28 :: Register(REG_SPR | 28)
S29 :: Register(REG_SPR | 29)
S30 :: Register(REG_SPR | 30)
S31 :: Register(REG_SPR | 31)

// ---- VFP/NEON double-precision (D0..D31) ------------------------------------
D0  :: Register(REG_DPR | 0)
D1  :: Register(REG_DPR | 1)
D2  :: Register(REG_DPR | 2)
D3  :: Register(REG_DPR | 3)
D4  :: Register(REG_DPR | 4)
D5  :: Register(REG_DPR | 5)
D6  :: Register(REG_DPR | 6)
D7  :: Register(REG_DPR | 7)
D8  :: Register(REG_DPR | 8)
D9  :: Register(REG_DPR | 9)
D10 :: Register(REG_DPR | 10)
D11 :: Register(REG_DPR | 11)
D12 :: Register(REG_DPR | 12)
D13 :: Register(REG_DPR | 13)
D14 :: Register(REG_DPR | 14)
D15 :: Register(REG_DPR | 15)
D16 :: Register(REG_DPR | 16)
D17 :: Register(REG_DPR | 17)
D18 :: Register(REG_DPR | 18)
D19 :: Register(REG_DPR | 19)
D20 :: Register(REG_DPR | 20)
D21 :: Register(REG_DPR | 21)
D22 :: Register(REG_DPR | 22)
D23 :: Register(REG_DPR | 23)
D24 :: Register(REG_DPR | 24)
D25 :: Register(REG_DPR | 25)
D26 :: Register(REG_DPR | 26)
D27 :: Register(REG_DPR | 27)
D28 :: Register(REG_DPR | 28)
D29 :: Register(REG_DPR | 29)
D30 :: Register(REG_DPR | 30)
D31 :: Register(REG_DPR | 31)

// ---- NEON quad-word (Q0..Q15) -----------------------------------------------
Q0  :: Register(REG_QPR | 0)
Q1  :: Register(REG_QPR | 1)
Q2  :: Register(REG_QPR | 2)
Q3  :: Register(REG_QPR | 3)
Q4  :: Register(REG_QPR | 4)
Q5  :: Register(REG_QPR | 5)
Q6  :: Register(REG_QPR | 6)
Q7  :: Register(REG_QPR | 7)
Q8  :: Register(REG_QPR | 8)
Q9  :: Register(REG_QPR | 9)
Q10 :: Register(REG_QPR | 10)
Q11 :: Register(REG_QPR | 11)
Q12 :: Register(REG_QPR | 12)
Q13 :: Register(REG_QPR | 13)
Q14 :: Register(REG_QPR | 14)
Q15 :: Register(REG_QPR | 15)

// ---- Status / control registers ---------------------------------------------
APSR  :: Register(REG_SREG | 0)
CPSR  :: Register(REG_SREG | 1)
SPSR  :: Register(REG_SREG | 2)
// Field-selectors for MSR APSR_nzcvq, etc, are encoded as separate Operand_Type
// values rather than expanding the Register set.

// FPSCR / FPSID and friends
FPSID :: Register(REG_FPSC | 0)
FPSCR :: Register(REG_FPSC | 1)
MVFR2 :: Register(REG_FPSC | 5)
MVFR1 :: Register(REG_FPSC | 6)
MVFR0 :: Register(REG_FPSC | 7)
FPEXC :: Register(REG_FPSC | 8)

// ---- Helpers ----------------------------------------------------------------
@(require_results)
reg_class :: #force_inline proc "contextless" (r: Register) -> u16 {
	return u16(r) & REG_CLASS_MASK
}

@(require_results)
reg_hw :: #force_inline proc "contextless" (r: Register) -> u16 {
	return u16(r) & REG_HW_MASK
}

@(require_results) is_gpr :: #force_inline proc "contextless" (r: Register) -> bool { return reg_class(r) == REG_GPR }
@(require_results) is_spr :: #force_inline proc "contextless" (r: Register) -> bool { return reg_class(r) == REG_SPR }
@(require_results) is_dpr :: #force_inline proc "contextless" (r: Register) -> bool { return reg_class(r) == REG_DPR }
@(require_results) is_qpr :: #force_inline proc "contextless" (r: Register) -> bool { return reg_class(r) == REG_QPR }
@(require_results)
is_fp_scalar :: #force_inline proc "contextless" (r: Register) -> bool {
	c := reg_class(r); return c == REG_SPR || c == REG_DPR
}
@(require_results)
is_simd   :: #force_inline proc "contextless" (r: Register) -> bool {
	c := reg_class(r); return c == REG_SPR || c == REG_DPR || c == REG_QPR
}
