package rexcode_x86

// =============================================================================
// SECTION: 6. ENCODING TABLES
// =============================================================================

import "../isa"

// -----------------------------------------------------------------------------
// SECTION: 6.0 Re-exports from isa (status, relocation)
// -----------------------------------------------------------------------------

Result          :: isa.Result
Error           :: isa.Error
Error_Code      :: isa.Error_Code
// Relocation and Relocation_Type live in reloc.odin (per-arch by design).

// -----------------------------------------------------------------------------
// SECTION: 6.0b CPU mode
// -----------------------------------------------------------------------------
//
// x86 has two encoding modes this package fully handles: 64-bit long
// mode (the default) and 32-bit protected mode (i386 / IA-32). The mode
// is passed to encode/decode and gates a handful of divergent rules:
//
//   - Opcodes 0x40-0x4F are REX prefixes in _64, short-form INC/DEC in _32.
//   - ModRM.mod=00, rm=101 (no SIB) is [RIP+disp32] in _64, [disp32] in _32.
//   - Memory base/index registers are 64-bit in _64, 32-bit in _32.
//   - REX is illegal in _32; SPL/BPL/SIL/DIL and R8-R15 don't exist there.
//   - default_64 (PUSH/POP/CALL implicit 64-bit operand size) applies only in _64.
//   - 64-bit-only operand types (R64/RM64/IMM64) are unreachable in _32.
//
// `_16` (16-bit real mode) is declared so callers can refer to it
// symbolically, but encode/decode panic if it is actually passed --
// real-mode ModRM addressing uses a completely different model
// (`[BX+SI]`, `[BP+DI]`, `[SI]`, etc., no SIB byte, 16-bit
// displacements) and needs a separate addressing path. Adding it later:
//   1. Implement a 16-bit ModRM decode table parallel to MODRM_TABLE.
//   2. Branch in decode_memory_operand on state.mode == ._16 to use it.
//   3. Mirror in the encoder (separate ModRM/SIB emission path).
//   4. Reject any 32-bit or 64-bit operand-type matches in ._16.
//   5. Add a default_16 / mode_16_only flag mirror of default_64 /
//      mode_32_only for the few opcodes that exist only in real mode.
Mode :: enum u8 {
	_64,    // long mode (x86-64), default
	_32,    // protected mode (i386 / IA-32)
	_16,    // real mode -- declared but not yet implemented; see comment above
}

// Mode-rewrite for `default_64` encodings: in i386, an encoding tagged
// `default_64` is the "default operand size" form, which is 32-bit (not
// 64-bit) -- so its R64/RM64 operand types decode/match as R32/RM32. The
// encoded bytes are identical (default_64 means no REX.W); only the
// interpretation of the operand width changes.
mode_rewrite_op_type :: #force_inline proc "contextless" (op_type: Operand_Type, mode: Mode, default_64: bool) -> Operand_Type {
	if mode == ._32 && default_64 {
		#partial switch op_type {
		case .R64:  return .R32
		case .RM64: return .RM32
		}
	}
	return op_type
}

// -----------------------------------------------------------------------------
// SECTION: 6.1 Operand Type Descriptors
// -----------------------------------------------------------------------------

// Operand type descriptors for instruction definitions
Operand_Type :: enum u8 {
	NONE,

	// GPR by size
	R8,             // 8-bit register
	R16,            // 16-bit register
	R32,            // 32-bit register
	R64,            // 64-bit register

	// GPR or memory
	RM8,            // r/m8
	RM16,           // r/m16
	RM32,           // r/m32
	RM64,           // r/m64

	// Memory only (for LEA, etc.)
	M,              // any memory
	M8,             // memory 8-bit
	M16,            // memory 16-bit
	M32,            // memory 32-bit
	M64,            // memory 64-bit
	M80,            // memory 80-bit (x87)
	M128,           // memory 128-bit
	M256,           // memory 256-bit
	M512,           // memory 512-bit

	// Immediates
	IMM8,           // 8-bit immediate
	IMM16,          // 16-bit immediate
	IMM32,          // 32-bit immediate
	IMM64,          // 64-bit immediate (only for MOV r64, imm64)

	// Sign-extended immediates
	IMM8SX,         // 8-bit sign-extended to operand size

	// Relative offsets
	REL8,           // 8-bit relative
	REL32,          // 32-bit relative

	// Fixed registers (implicit)
	AL_IMPL,        // implicit AL
	AX_IMPL,        // implicit AX
	EAX_IMPL,       // implicit EAX
	RAX_IMPL,       // implicit RAX
	CL_IMPL,        // implicit CL (for shifts)
	DX_IMPL,        // implicit DX (for IN/OUT)
	ONE_IMPL,       // implicit 1 (for shifts)

	// Segment registers
	SREG,           // segment register

	// Control/debug registers
	CR,             // control register
	DR,             // debug register

	// Vector registers
	XMM,            // XMM register
	YMM,            // YMM register
	ZMM,            // ZMM register

	// Vector register or memory
	XMM_M32,        // xmm or m32
	XMM_M64,        // xmm or m64
	XMM_M128,       // xmm or m128
	YMM_M256,       // ymm or m256
	ZMM_M512,       // zmm or m512

	// MMX
	MM,             // MMX register
	MM_M64,         // MMX or m64

	// x87 FPU
	ST0_IMPL,       // implicit ST(0)
	STI,            // ST(i) register

	// Implicit XMM0 (for BLENDV, SHA256RNDS2)
	XMM0_IMPL,      // implicit XMM0

	// Opmask
	K,              // opmask register
	K_M8,           // opmask or m8
	K_M16,          // opmask or m16
	K_M32,          // opmask or m32
	K_M64,          // opmask or m64

	// Special
	MOFFS8,         // memory offset 8-bit (MOV AL, moffs)
	MOFFS16,        // memory offset 16-bit
	MOFFS32,        // memory offset 32-bit
	MOFFS64,        // memory offset 64-bit

	// Far pointers
	PTR16_16,       // 16:16 far pointer
	PTR16_32,       // 16:32 far pointer
	PTR16_64,       // 16:64 far pointer
	M16_16,         // memory 16:16
	M16_32,         // memory 16:32
	M16_64,         // memory 16:64
}


// -----------------------------------------------------------------------------
// SECTION: 6.2 Operand Encoding
// -----------------------------------------------------------------------------

Operand_Encoding :: enum u8 {
	NONE,

	// ModR/M based
	MR,             // operand in ModR/M r/m field (register or memory)
	REG,            // operand in ModR/M reg field

	// VEX/EVEX specific
	VVVV,           // operand in VEX.vvvv

	// Opcode-embedded
	OP_R,           // register encoded in low 3 bits of opcode (+rb, +rw, +rd, +ro)

	// Immediate
	IB,             // immediate byte following instruction
	IW,             // immediate word following instruction
	ID,             // immediate dword following instruction
	IQ,             // immediate qword following instruction

	// Implicit
	IMPL,           // implicit operand (not encoded)

	// Special
	IS4,            // high 4 bits of 8-bit immediate (for some AVX)

	// EVEX
	AAA,            // opmask in EVEX.aaa
}


// -----------------------------------------------------------------------------
// SECTION: 6.3 Opcode Escape Sequences
// -----------------------------------------------------------------------------

Escape :: enum u8 {
	NONE,           // single-byte opcode
	_0F,            // 0F xx
	_0F38,          // 0F 38 xx
	_0F3A,          // 0F 3A xx
}


// -----------------------------------------------------------------------------
// SECTION: 6.4 VEX/EVEX Prefix Types
// -----------------------------------------------------------------------------

VEX_Type :: enum u8 {
	NONE,           // legacy encoding
	VEX,            // VEX prefix (AVX)
	EVEX,           // EVEX prefix (AVX-512)
	XOP,            // XOP prefix (AMD)
}

// VEX.W / EVEX.W field
VEX_W :: enum u8 {
	WIG,            // W ignored
	W0,             // W = 0
	W1,             // W = 1
}

// VEX.L / EVEX.L'L field
VEX_L :: enum u8 {
	LIG,            // L ignored
	L0,             // L = 0 (128-bit / scalar)
	L1,             // L = 1 (256-bit)
	L2,             // L = 2 (512-bit, EVEX only)
}

// -----------------------------------------------------------------------------
// SECTION: 6.5 Encoding Flags
// -----------------------------------------------------------------------------

Encoding_Flags :: bit_field u32 {
	esc:           Escape   | 2, // escape sequence
	prefix:        u8       | 2, // mandatory prefix: 0=none, 1=66, 2=F3, 3=F2
	vex_type:      VEX_Type | 2, // VEX/EVEX/XOP
	vex_w:         VEX_W    | 2, // VEX.W requirement
	vex_l:         VEX_L    | 2, // VEX.L requirement
	default_64:    bool     | 1, // default to 64-bit operand size (PUSH, POP, etc.)
	force_rex_w:   bool     | 1, // always emit REX.W
	no_rex:        bool     | 1, // REX prefix not allowed (high byte regs)
	lock_ok:       bool     | 1, // LOCK prefix valid
	rep_ok:        bool     | 1, // REP prefix valid
	modrm_reg_ext: bool     | 1, // ModR/M reg field is opcode extension (use ext field)
	mode_32_only:  bool     | 1, // only valid in Mode._32 (e.g. short-form INC/DEC at 0x40-0x4F)
}

// -----------------------------------------------------------------------------
// SECTION: 6.6 Encoding struct
// -----------------------------------------------------------------------------

Encoding :: struct #packed {
	mnemonic: Mnemonic,            // 2 bytes
	ops:      [4]Operand_Type,     // 4 bytes - operand types
	enc:      [4]Operand_Encoding, // 4 bytes - operand encodings
	opcode:   u8,                  // 1 byte - primary opcode byte
	ext:      u8,                  // 1 byte - ModR/M reg extension (/0-/7) or secondary opcode
	flags:    Encoding_Flags,      // 4 bytes
}
#assert(size_of(Encoding) == 16)

// Prefix byte constants
PREFIX_66 :: 1
PREFIX_F3 :: 2
PREFIX_F2 :: 3

// -----------------------------------------------------------------------------
// SECTION: 6.7 Helper Functions
// -----------------------------------------------------------------------------

encoding_flags :: #force_inline proc "contextless" (
	esc:           Escape   = .NONE,
	prefix:        u8       = 0,
	vex_type:      VEX_Type = .NONE,
	vex_w:         VEX_W    = .WIG,
	vex_l:         VEX_L    = .LIG,
	default_64:    bool     = false,
	force_rex_w:   bool     = false,
	no_rex:        bool     = false,
	lock_ok:       bool     = false,
	rep_ok:        bool     = false,
	modrm_reg_ext: bool     = false,
	mode_32_only:  bool     = false,
) -> Encoding_Flags {
	return Encoding_Flags{
		esc           = esc,
		prefix        = prefix,
		vex_type      = vex_type,
		vex_w         = vex_w,
		vex_l         = vex_l,
		default_64    = default_64,
		force_rex_w   = force_rex_w,
		no_rex        = no_rex,
		lock_ok       = lock_ok,
		rep_ok        = rep_ok,
		modrm_reg_ext = modrm_reg_ext,
		mode_32_only  = mode_32_only,
	}
}

// -----------------------------------------------------------------------------
// SECTION: 6.8 Operand Type Size Helper
// -----------------------------------------------------------------------------

op_type_to_size :: proc(op_type: Operand_Type) -> u8 {
	#partial switch op_type {
	case .R8,  .RM8,      .M8,  .IMM8:            return 1
	case .R16, .RM16,     .M16, .IMM16:           return 2
	case .R32, .RM32,     .M32, .IMM32, .XMM_M32: return 4
	case .R64, .RM64,     .M64, .IMM64, .XMM_M64: return 8
	case .XMM, .XMM_M128, .M128:                  return 16
	case .YMM, .YMM_M256, .M256:                  return 32
	case .ZMM, .ZMM_M512, .M512:                  return 64
	}
	return 0
}
