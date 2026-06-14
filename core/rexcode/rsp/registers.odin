package rexcode_rsp

// =============================================================================
// N64 RSP REGISTERS
// =============================================================================
//
// The RSP has the standard 32 MIPS GPRs (same ABI names) plus its
// vector-unit registers:
//   $v0..$v31   -- 32 × 128-bit vector regs (each 8 × i16 elements)
//   VCO         -- carry/overflow flags from vector add/sub
//   VCC         -- compare results from VLT/VEQ/VNE/VGE/VCL/VCH/VCR
//   VCE         -- compare-extension flag (low bytes of VCH/VCR carry)
// And RSP-specific CP0 registers for DMA control (SP_MEM_ADDR,
// SP_DRAM_ADDR, SP_RD_LEN, SP_WR_LEN, SP_STATUS, SP_DMA_FULL, SP_DMA_BUSY,
// SP_SEMAPHORE, DP_START, DP_END, DP_CURRENT, DP_STATUS, DP_CLOCK,
// DP_BUFBUSY, DP_PIPEBUSY, DP_TMEM).

Register :: distinct u16

REG_NONE :: 0x0000
REG_GPR  :: 0x0100
REG_VR   :: 0x0200    // vector $v0..$v31
REG_VC   :: 0x0300    // VCO/VCC/VCE
REG_CP0  :: 0x0400    // RSP CP0 (DMA control etc.)

NONE :: Register(0xFFFF)

// -----------------------------------------------------------------------------
// GPR (same ABI names as MIPS)
// -----------------------------------------------------------------------------

GPR :: enum u8 {
	ZERO=0, AT=1,
	V0=2, V1=3,
	A0=4, A1=5, A2=6, A3=7,
	T0=8, T1=9, T2=10, T3=11, T4=12, T5=13, T6=14, T7=15,
	S0=16, S1=17, S2=18, S3=19, S4=20, S5=21, S6=22, S7=23,
	T8=24, T9=25,
	K0=26, K1=27,
	GP=28, SP=29, FP=30, RA=31,
}

ZERO :: Register(REG_GPR | 0);   AT :: Register(REG_GPR | 1)
V0 :: Register(REG_GPR | 2);     V1 :: Register(REG_GPR | 3)
A0 :: Register(REG_GPR | 4);     A1 :: Register(REG_GPR | 5)
A2 :: Register(REG_GPR | 6);     A3 :: Register(REG_GPR | 7)
T0 :: Register(REG_GPR | 8);     T1 :: Register(REG_GPR | 9)
T2 :: Register(REG_GPR | 10);    T3 :: Register(REG_GPR | 11)
T4 :: Register(REG_GPR | 12);    T5 :: Register(REG_GPR | 13)
T6 :: Register(REG_GPR | 14);    T7 :: Register(REG_GPR | 15)
S0 :: Register(REG_GPR | 16);    S1 :: Register(REG_GPR | 17)
S2 :: Register(REG_GPR | 18);    S3 :: Register(REG_GPR | 19)
S4 :: Register(REG_GPR | 20);    S5 :: Register(REG_GPR | 21)
S6 :: Register(REG_GPR | 22);    S7 :: Register(REG_GPR | 23)
T8 :: Register(REG_GPR | 24);    T9 :: Register(REG_GPR | 25)
K0 :: Register(REG_GPR | 26);    K1 :: Register(REG_GPR | 27)
GP :: Register(REG_GPR | 28);    SP :: Register(REG_GPR | 29)
FP :: Register(REG_GPR | 30);    RA :: Register(REG_GPR | 31)

// -----------------------------------------------------------------------------
// Vector registers $v0..$v31
// -----------------------------------------------------------------------------

VR :: enum u8 {
	V0=0, V1=1, V2=2, V3=3, V4=4, V5=5, V6=6, V7=7,
	V8=8, V9=9, V10=10, V11=11, V12=12, V13=13, V14=14, V15=15,
	V16=16, V17=17, V18=18, V19=19, V20=20, V21=21, V22=22, V23=23,
	V24=24, V25=25, V26=26, V27=27, V28=28, V29=29, V30=30, V31=31,
}

VR0  :: Register(REG_VR | 0);   VR1  :: Register(REG_VR | 1)
VR2  :: Register(REG_VR | 2);   VR3  :: Register(REG_VR | 3)
VR4  :: Register(REG_VR | 4);   VR5  :: Register(REG_VR | 5)
VR6  :: Register(REG_VR | 6);   VR7  :: Register(REG_VR | 7)
VR8  :: Register(REG_VR | 8);   VR9  :: Register(REG_VR | 9)
VR10 :: Register(REG_VR | 10);  VR11 :: Register(REG_VR | 11)
VR12 :: Register(REG_VR | 12);  VR13 :: Register(REG_VR | 13)
VR14 :: Register(REG_VR | 14);  VR15 :: Register(REG_VR | 15)
VR16 :: Register(REG_VR | 16);  VR17 :: Register(REG_VR | 17)
VR18 :: Register(REG_VR | 18);  VR19 :: Register(REG_VR | 19)
VR20 :: Register(REG_VR | 20);  VR21 :: Register(REG_VR | 21)
VR22 :: Register(REG_VR | 22);  VR23 :: Register(REG_VR | 23)
VR24 :: Register(REG_VR | 24);  VR25 :: Register(REG_VR | 25)
VR26 :: Register(REG_VR | 26);  VR27 :: Register(REG_VR | 27)
VR28 :: Register(REG_VR | 28);  VR29 :: Register(REG_VR | 29)
VR30 :: Register(REG_VR | 30);  VR31 :: Register(REG_VR | 31)

// -----------------------------------------------------------------------------
// Vector flag registers
// -----------------------------------------------------------------------------

VCO :: Register(REG_VC | 0)   // carry/overflow from vector add/sub
VCC :: Register(REG_VC | 1)   // compare results
VCE :: Register(REG_VC | 2)   // VCH/VCR low-byte carry

// -----------------------------------------------------------------------------
// RSP CP0 (DMA + status registers; selector via the rd field)
// -----------------------------------------------------------------------------

CP0_Reg :: enum u8 {
	SP_MEM_ADDR  = 0,   // DMEM/IMEM offset for DMA
	SP_DRAM_ADDR = 1,   // RDRAM address for DMA
	SP_RD_LEN    = 2,   // DMA read length
	SP_WR_LEN    = 3,   // DMA write length
	SP_STATUS    = 4,   // RSP status (halt/broke/busy)
	SP_DMA_FULL  = 5,
	SP_DMA_BUSY  = 6,
	SP_SEMAPHORE = 7,
	DP_START     = 8,   // RDP command buffer start
	DP_END       = 9,
	DP_CURRENT   = 10,
	DP_STATUS    = 11,
	DP_CLOCK     = 12,
	DP_BUFBUSY   = 13,
	DP_PIPEBUSY  = 14,
	DP_TMEM      = 15,
}

@(require_results) reg_hw    :: #force_inline proc "contextless" (r: Register) -> u8  { return u8(r) & 0x1F }
@(require_results) reg_class :: #force_inline proc "contextless" (r: Register) -> u16 { return u16(r) & 0xFF00 }

@(require_results)
gpr_from_num :: #force_inline proc "contextless" (num: u8) -> Register {
	return num < 32 ? Register(REG_GPR | u16(num)) : NONE
}
@(require_results)
vr_from_num :: #force_inline proc "contextless" (num: u8) -> Register {
	return num < 32 ? Register(REG_VR | u16(num)) : NONE
}
