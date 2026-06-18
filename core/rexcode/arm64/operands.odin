// rexcode  ·  Brendan Punsky (dotbmp@github), original author

package rexcode_arm64

// =============================================================================
// AArch64 OPERANDS
// =============================================================================
//
// AArch64 has a rich addressing repertoire:
//
//   [Xn]                          OFFSET with imm=0
//   [Xn, #imm]                    OFFSET (signed 9 or unsigned scaled 12)
//   [Xn, #imm]!                   PRE_INDEXED (writeback before)
//   [Xn], #imm                    POST_INDEXED (writeback after)
//   [Xn, Xm{, LSL #s}]            REG_OFFSET (shift = log2(size) when present)
//   [Xn, Wm, SXTW|UXTW|SXTX #s]   EXT_REG_OFFSET
//   label                         LITERAL (PC-relative for LDR literal)
//
// `Shift_Type` and `Extend` enumerate the shifter/extender flavours that
// data-processing register and memory operand encodings need.

Operand_Kind :: enum u8 {
	NONE,
	REGISTER,
	IMMEDIATE,
	MEMORY,
	RELATIVE,
	SHIFTED_REG,      // X reg + shift type + shift amount
	EXTENDED_REG,     // X/W reg + extend + amount
	COND,             // 4-bit condition code (EQ/NE/.../AL/NV)
}

Shift_Type :: enum u8 {
	LSL = 0,
	LSR = 1,
	ASR = 2,
	ROR = 3,
}

Extend :: enum u8 {
	UXTB = 0,
	UXTH = 1,
	UXTW = 2,
	UXTX = 3,
	SXTB = 4,
	SXTH = 5,
	SXTW = 6,
	SXTX = 7,
}

Address_Mode :: enum u8 {
	OFFSET,           // [Xn, #imm]   (imm may be 0)
	PRE_INDEXED,      // [Xn, #imm]!
	POST_INDEXED,     // [Xn], #imm
	REG_OFFSET,       // [Xn, Xm{, LSL #s}]
	EXT_REG_OFFSET,   // [Xn, Wm, SXTW|UXTW|SXTX #s]
	LITERAL,          // PC-rel target (LDR literal)
}

// 16-byte memory operand: base + optional index + signed disp + addressing
// metadata. Index is `NONE` for non-register-offset modes.
Memory :: struct #packed {
	base:    Register,     // 2
	index:   Register,     // 2  (NONE for OFFSET/PRE/POST/LITERAL)
	disp:    i32,          // 4  (signed; pre/post can be -256..255 unscaled,
	                       //     OFFSET supports 0..32760 scaled via imm12*size)
	extend:  Extend,       // 1  (for EXT_REG_OFFSET; UXTX otherwise)
	shift:   u8,           // 1  (0..4 for register-offset / extended; or
	                       //     shift amount for shifted-register operands
	                       //     when reused there)
	mode:    Address_Mode, // 1
	_:       u8,           // 1
}
#assert(size_of(Memory) == 12)

Shifted_Reg :: struct #packed {
	reg:    Register,    // 2
	type:   Shift_Type,  // 1
	amount: u8,          // 1  (0..63 for 64-bit; 0..31 for 32-bit)
}
#assert(size_of(Shifted_Reg) == 4)

Extended_Reg :: struct #packed {
	reg:    Register,    // 2
	extend: Extend,      // 1
	amount: u8,          // 1  (0..4)
}
#assert(size_of(Extended_Reg) == 4)

// 16-byte tagged operand. The union holds whichever payload matches `kind`.
Operand :: struct #packed {
	using _: struct #raw_union #packed {
		reg:       Register,        // 2
		mem:       Memory,          // 12
		immediate: i64,             // 8
		relative:  i64,             // 8
		shifted:   Shifted_Reg,     // 8
		extended:  Extended_Reg,    // 8
		cond:      u8,              // 1
	}, // 12 total because of alignment
	kind: Operand_Kind,                 // 1
	size: u8,                           // 1 -- carried width info; meaning varies
}
#assert(size_of(Operand) == 14)

// -----------------------------------------------------------------------------
// Constructors -- generic
// -----------------------------------------------------------------------------

@(require_results)
op_reg   :: #force_inline proc "contextless" (r: Register) -> Operand {
	return Operand{reg = r, kind = .REGISTER, size = 4}
}
@(require_results)
op_imm   :: #force_inline proc "contextless" (v: i64, size: u8 = 4) -> Operand {
	return Operand{immediate = v, kind = .IMMEDIATE, size = size}
}
@(require_results)
op_label :: #force_inline proc "contextless" (label_id: u32, size: u8 = 4) -> Operand {
	return Operand{relative = i64(label_id), kind = .RELATIVE, size = size}
}
@(require_results)
op_rel_offset :: #force_inline proc "contextless" (off: i64) -> Operand {
	return Operand{relative = off, kind = .RELATIVE, size = 4}
}

@(require_results)
op_mem :: #force_inline proc "contextless" (m: Memory) -> Operand {
	return Operand{mem = m, kind = .MEMORY, size = 4}
}

@(require_results)
op_shifted :: #force_inline proc "contextless" (r: Register, type: Shift_Type, amount: u8) -> Operand {
	return Operand{shifted = Shifted_Reg{reg = r, type = type, amount = amount}, kind = .SHIFTED_REG, size = 4}
}

@(require_results)
op_extended :: #force_inline proc "contextless" (r: Register, ext: Extend, amount: u8) -> Operand {
	return Operand{extended = Extended_Reg{reg = r, extend = ext, amount = amount}, kind = .EXTENDED_REG, size = 4}
}

@(require_results)
op_cond :: #force_inline proc "contextless" (c: Cond) -> Operand {
	return Operand{cond = u8(c), kind = .COND, size = 1}
}

// -----------------------------------------------------------------------------
// SVE Z-register builders -- encode the element arrangement in op.size
// (B=1, H=2, S=4, D=8). Matcher uses op.size to disambiguate the right
// table form when multiple element sizes share a base mnemonic.
// -----------------------------------------------------------------------------

@(require_results)
op_z_b :: #force_inline proc "contextless" (n: u8) -> Operand {
	return Operand{reg = Register(REG_Z | u16(n & 0x1F)), kind = .REGISTER, size = 1}
}
@(require_results)
op_z_h :: #force_inline proc "contextless" (n: u8) -> Operand {
	return Operand{reg = Register(REG_Z | u16(n & 0x1F)), kind = .REGISTER, size = 2}
}
@(require_results)
op_z_s :: #force_inline proc "contextless" (n: u8) -> Operand {
	return Operand{reg = Register(REG_Z | u16(n & 0x1F)), kind = .REGISTER, size = 4}
}
@(require_results)
op_z_d :: #force_inline proc "contextless" (n: u8) -> Operand {
	return Operand{reg = Register(REG_Z | u16(n & 0x1F)), kind = .REGISTER, size = 8}
}

// -----------------------------------------------------------------------------
// NEON V-register arrangement builders -- op.size encodes lanes*elem-bytes:
//   .8B  = 8     .16B = 16
//   .4H  = 24    .8H  = 32
//   .2S  = 40    .4S  = 48
//   .1D  = 56    .2D  = 64
// (Encoded so that no two arrangements collide and so the value is easy
// to inspect.)
// -----------------------------------------------------------------------------

@(require_results)
op_v_8b  :: #force_inline proc "contextless" (n: u8) -> Operand {
	return Operand{reg = Register(REG_V | u16(n & 0x1F)), kind = .REGISTER, size = 8}
}
@(require_results)
op_v_16b :: #force_inline proc "contextless" (n: u8) -> Operand {
	return Operand{reg = Register(REG_V | u16(n & 0x1F)), kind = .REGISTER, size = 16}
}
@(require_results)
op_v_4h  :: #force_inline proc "contextless" (n: u8) -> Operand {
	return Operand{reg = Register(REG_V | u16(n & 0x1F)), kind = .REGISTER, size = 24}
}
@(require_results)
op_v_8h  :: #force_inline proc "contextless" (n: u8) -> Operand {
	return Operand{reg = Register(REG_V | u16(n & 0x1F)), kind = .REGISTER, size = 32}
}
@(require_results)
op_v_2s  :: #force_inline proc "contextless" (n: u8) -> Operand {
	return Operand{reg = Register(REG_V | u16(n & 0x1F)), kind = .REGISTER, size = 40}
}
@(require_results)
op_v_4s  :: #force_inline proc "contextless" (n: u8) -> Operand {
	return Operand{reg = Register(REG_V | u16(n & 0x1F)), kind = .REGISTER, size = 48}
}
@(require_results)
op_v_1d  :: #force_inline proc "contextless" (n: u8) -> Operand {
	return Operand{reg = Register(REG_V | u16(n & 0x1F)), kind = .REGISTER, size = 56}
}
@(require_results)
op_v_2d  :: #force_inline proc "contextless" (n: u8) -> Operand {
	return Operand{reg = Register(REG_V | u16(n & 0x1F)), kind = .REGISTER, size = 64}
}

// Element-indexed V views (V0.B[i]/.H[i]/.S[i]/.D[i]). The element size rides
// in op.size (1/2/4/8) so the matcher can disambiguate DUP/INS forms; the lane
// index is a separate immediate operand.
@(require_results)
op_v_elem_b :: #force_inline proc "contextless" (n: u8) -> Operand {
	return Operand{reg = Register(REG_V | u16(n & 0x1F)), kind = .REGISTER, size = 1}
}
@(require_results)
op_v_elem_h :: #force_inline proc "contextless" (n: u8) -> Operand {
	return Operand{reg = Register(REG_V | u16(n & 0x1F)), kind = .REGISTER, size = 2}
}
@(require_results)
op_v_elem_s :: #force_inline proc "contextless" (n: u8) -> Operand {
	return Operand{reg = Register(REG_V | u16(n & 0x1F)), kind = .REGISTER, size = 4}
}
@(require_results)
op_v_elem_d :: #force_inline proc "contextless" (n: u8) -> Operand {
	return Operand{reg = Register(REG_V | u16(n & 0x1F)), kind = .REGISTER, size = 8}
}

// -----------------------------------------------------------------------------
// Memory constructors (one per addressing mode)
// -----------------------------------------------------------------------------

@(require_results)
mem_offset :: #force_inline proc "contextless" (base: Register, disp: i32 = 0) -> Memory {
	return Memory{base = base, index = NONE, disp = disp, mode = .OFFSET}
}
@(require_results)
mem_pre :: #force_inline proc "contextless" (base: Register, disp: i32) -> Memory {
	return Memory{base = base, index = NONE, disp = disp, mode = .PRE_INDEXED}
}
@(require_results)
mem_post :: #force_inline proc "contextless" (base: Register, disp: i32) -> Memory {
	return Memory{base = base, index = NONE, disp = disp, mode = .POST_INDEXED}
}
@(require_results)
mem_reg :: #force_inline proc "contextless" (base, index: Register, shift_amount: u8 = 0) -> Memory {
	return Memory{base = base, index = index, mode = .REG_OFFSET, shift = shift_amount, extend = .UXTX}
}
@(require_results)
mem_ext :: #force_inline proc "contextless" (base, index: Register, ext: Extend, shift_amount: u8 = 0) -> Memory {
	return Memory{base = base, index = index, mode = .EXT_REG_OFFSET, extend = ext, shift = shift_amount}
}

// -----------------------------------------------------------------------------
// Condition codes
// -----------------------------------------------------------------------------

Cond :: enum u8 {
	EQ = 0x0,
	NE = 0x1,
	CS = 0x2,    // unsigned higher or same (alias HS)
	CC = 0x3,    // unsigned lower (alias LO)
	MI = 0x4,
	PL = 0x5,
	VS = 0x6,
	VC = 0x7,
	HI = 0x8,
	LS = 0x9,
	GE = 0xA,
	LT = 0xB,
	GT = 0xC,
	LE = 0xD,
	AL = 0xE,
	NV = 0xF,
}

// Architectural aliases for the two carry-style conditions.
COND_HS :: Cond.CS
COND_LO :: Cond.CC
