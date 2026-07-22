// rexcode  ·  Brendan Punsky (dotbmp@github), original author

package rexcode_rsp

import "core:rexcode/isa"

// =============================================================================
// N64 RSP encoding fundamentals
// =============================================================================
//
// The Reality Signal Processor in the N64's RCP is a heavily-customised
// MIPS R4000 derivative. The scalar core implements a strict MIPS I
// subset -- *no* MULT/DIV/FPU/TLB/64-bit/LWL/LWR/SWL/SWR -- but the
// vector unit (COP2) is a major addition: 32 × 128-bit vector registers,
// each holding 8 × 16-bit signed elements, with a saturating
// fixed-point accumulator and three flag registers (VCO/VCC/VCE).
//
// Scalar instructions reuse the standard MIPS encodings (so we share
// Format/Operand_Encoding from the mips/ package's design). Vector
// instructions use COP2 (op=0x12) with a custom layout:
//
//   Vector ALU (CO=1):
//   [op=0x12 6][1=CO][element 4][vt 5][vs 5][vd 5][funct 6]
//
//   Vector load (op=0x32 LWC2-shape, no CO bit):
//   [op=0x32 6][base 5][vt 5][op2 5][element 4][offset 7]
//
//   Vector store (op=0x3A SWC2-shape): same as load layout.
//
// The 4-bit element field selects which lane of vt is broadcast (for
// ALU) or which element offset to start at (for L/S). The 7-bit offset
// is sign-extended and pre-scaled by element size, so the effective
// range is `±64 × element_size` bytes.

Error            :: isa.Error
Error_Code       :: isa.Error_Code
Label_Definition :: isa.Label_Definition
LABEL_UNDEFINED  :: isa.LABEL_UNDEFINED
Label_Map        :: isa.Label_Map
// Relocation and Relocation_Type live in reloc.odin (per-arch by design).

// N64 is big-endian; carry the same Endianness enum as mips/ for
// uniformity even though only BIG is "wire-correct" for RSP IMEM in
// most toolchains.
Endianness :: enum u8 {
	LITTLE = 0,
	BIG    = 1,
}

Feature :: enum u8 {
	RSP_SCALAR,    // scalar MIPS subset on the RSP core
	RSP_VU,        // RSP vector unit (COP2 with CO=1)
	RSP_VLS,       // RSP vector load/store (op=0x32/0x3A)
}

Encoding_Flags :: bit_field u8 {
	delay_slot: bool | 1,
	likely:     bool | 1,
	_:          u8   | 6,
}

Operand_Type :: enum u8 {
	NONE,
	GPR,                 // scalar GPR
	VR,                  // vector register $v0..$v31
	VR_ELEM,             // vector register with element selector (e.g. $v3[4])
	CP0_REG,             // RSP CP0 (DMA/status registers)
	CP2_CTRL,            // VCO / VCC / VCE
	IMM5,
	IMM16S,
	IMM16U,
	IMM20,
	IMM26,
	REL16,
	REL_J26,
	MEM,                 // scalar memory (base+disp16)
	VMEM,                // vector memory (base+offset7 with element)
}

Operand_Encoding :: enum u8 {
	NONE,
	RS,            // bits 25-21
	RT,            // bits 20-16
	RD,            // bits 15-11
	SHAMT,         // bits 10-6
	IMM_16,        // bits 15-0
	IMM_5,         // bits 10-6
	IMM_20,        // bits 25-6
	IMM_26,        // bits 25-0
	OFFSET_BASE,   // scalar memory (rs + 16-bit offset)
	BRANCH_16,
	IMPL,
	// Vector-unit placements
	VT,            // bits 20-16 (vector source 2)
	VS,            // bits 15-11 (vector source 1)
	VD,            // bits 10-6  (vector destination)
	ELEM,          // bits 24-21 (element selector for vector ALU)
	// Vector L/S placements
	VT_LS,         // bits 20-16 (target vector reg)
	VOP,           // bits 15-11 (vector L/S op selector LBV..LTV)
	VELEM_LS,      // bits 10-7  (element offset for L/S)
	VOFFSET,       // bits  6-0  (signed 7-bit offset, element-scaled)
	VBASE,         // bits 25-21 (GPR base for vector L/S)
}

Encoding :: struct #packed {
	mnemonic: Mnemonic,
	ops:      [4]Operand_Type,
	enc:      [4]Operand_Encoding,
	bits:     u32,
	mask:     u32,
	feature: Feature,
	flags:    Encoding_Flags,
}
#assert(size_of(Encoding) == 20)

MASK_OPCODE :: u32(0xFC000000)
MASK_RS     :: u32(0x03E00000)
MASK_RT     :: u32(0x001F0000)
MASK_RD     :: u32(0x0000F800)
MASK_SHAMT  :: u32(0x000007C0)
MASK_FUNCT  :: u32(0x0000003F)
MASK_VELEM  :: u32(0x01E00000)   // vector ALU element field (bits 24-21)
MASK_VOFFS7 :: u32(0x0000007F)   // vector L/S offset (bits 6-0)
