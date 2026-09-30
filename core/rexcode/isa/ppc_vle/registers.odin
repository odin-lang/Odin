// rexcode  ·  Brendan Punsky (dotbmp@github), original author

package rexcode_ppc_vle

// =============================================================================
// PowerPC VLE Registers
// =============================================================================
//
// VLE shares the PPC GPR file. Register class encoding is the same as ppc/.

Register :: distinct u16

// Class tag at top nibble (bits 12..15); 12-bit hardware index in low 12 bits.
// SPR space goes up to 1023, so we use 12-bit hw to avoid collisions.
REG_NONE :: 0x0000
REG_GPR  :: 0x1000
REG_CR   :: 0x5000
REG_SPR  :: 0x6000

NONE :: Register(0xFFFF)

@(require_results) reg_hw    :: #force_inline proc "contextless" (r: Register) -> u16 { return u16(r) & 0x0FFF }
@(require_results) reg_class :: #force_inline proc "contextless" (r: Register) -> u16 { return u16(r) & 0xF000 }

@(require_results) reg_is_gpr :: #force_inline proc "contextless" (r: Register) -> bool { return reg_class(r) == REG_GPR }
@(require_results) reg_is_cr  :: #force_inline proc "contextless" (r: Register) -> bool { return reg_class(r) == REG_CR  }
@(require_results) reg_is_spr :: #force_inline proc "contextless" (r: Register) -> bool { return reg_class(r) == REG_SPR }

R0  :: Register(REG_GPR | 0);  R1  :: Register(REG_GPR | 1);  R2  :: Register(REG_GPR | 2);  R3  :: Register(REG_GPR | 3)
R4  :: Register(REG_GPR | 4);  R5  :: Register(REG_GPR | 5);  R6  :: Register(REG_GPR | 6);  R7  :: Register(REG_GPR | 7)
R8  :: Register(REG_GPR | 8);  R9  :: Register(REG_GPR | 9);  R10 :: Register(REG_GPR | 10); R11 :: Register(REG_GPR | 11)
R12 :: Register(REG_GPR | 12); R13 :: Register(REG_GPR | 13); R14 :: Register(REG_GPR | 14); R15 :: Register(REG_GPR | 15)
R16 :: Register(REG_GPR | 16); R17 :: Register(REG_GPR | 17); R18 :: Register(REG_GPR | 18); R19 :: Register(REG_GPR | 19)
R20 :: Register(REG_GPR | 20); R21 :: Register(REG_GPR | 21); R22 :: Register(REG_GPR | 22); R23 :: Register(REG_GPR | 23)
R24 :: Register(REG_GPR | 24); R25 :: Register(REG_GPR | 25); R26 :: Register(REG_GPR | 26); R27 :: Register(REG_GPR | 27)
R28 :: Register(REG_GPR | 28); R29 :: Register(REG_GPR | 29); R30 :: Register(REG_GPR | 30); R31 :: Register(REG_GPR | 31)

CR0 :: Register(REG_CR | 0)
CR1 :: Register(REG_CR | 1)
CR2 :: Register(REG_CR | 2)
CR3 :: Register(REG_CR | 3)

@(require_results) spr_reg :: #force_inline proc "contextless" (n: u16) -> Register { return Register(REG_SPR) | Register(n & 0x3FF) }

// Common SPRs
XER   :: Register(REG_SPR | 1)
LR    :: Register(REG_SPR | 8)
CTR   :: Register(REG_SPR | 9)
DEC   :: Register(REG_SPR | 22)
SRR0  :: Register(REG_SPR | 26)
SRR1  :: Register(REG_SPR | 27)
PID   :: Register(REG_SPR | 48)
CSRR0 :: Register(REG_SPR | 58)
CSRR1 :: Register(REG_SPR | 59)
DEAR  :: Register(REG_SPR | 61)
ESR   :: Register(REG_SPR | 62)
IVPR  :: Register(REG_SPR | 63)

// SPRGs 0..7
SPRG0 :: Register(REG_SPR | 272); SPRG1 :: Register(REG_SPR | 273)
SPRG2 :: Register(REG_SPR | 274); SPRG3 :: Register(REG_SPR | 275)
SPRG4 :: Register(REG_SPR | 276); SPRG5 :: Register(REG_SPR | 277)
SPRG6 :: Register(REG_SPR | 278); SPRG7 :: Register(REG_SPR | 279)
TBL :: Register(REG_SPR | 284); TBU :: Register(REG_SPR | 285)
PIR :: Register(REG_SPR | 286); PVR :: Register(REG_SPR | 287)

// Debug
DBSR  :: Register(REG_SPR | 304)
DBCR0 :: Register(REG_SPR | 308); DBCR1 :: Register(REG_SPR | 309); DBCR2 :: Register(REG_SPR | 310)
IAC1  :: Register(REG_SPR | 312); IAC2  :: Register(REG_SPR | 313); IAC3 :: Register(REG_SPR | 314); IAC4 :: Register(REG_SPR | 315)
DAC1  :: Register(REG_SPR | 316); DAC2  :: Register(REG_SPR | 317)

// SPE FP control
SPEFSCR :: Register(REG_SPR | 512)
