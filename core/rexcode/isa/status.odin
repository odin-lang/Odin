// rexcode  ·  Brendan Punsky (dotbmp@github), original author

package rexcode_isa

// =============================================================================
// ERROR / RESULT TYPES (shared by encoder and decoder, all architectures)
// =============================================================================
//
// The struct shapes are universal. Error_Code holds the full set of codes
// any architecture may produce; per-arch encoders/decoders only emit the
// subset that applies to them. When an arch needs a new code (e.g.
// RISC-V's MISALIGNED_IMMEDIATE), add it here.

Error_Code :: enum u8 {
	NONE = 0,

	// Shared encoding errors
	INVALID_MNEMONIC,
	NO_MATCHING_ENCODING,
	OPERAND_MISMATCH,
	IMMEDIATE_OUT_OF_RANGE,
	BUFFER_OVERFLOW,
	LABEL_OUT_OF_RANGE,
	INVALID_OPERAND_COUNT,        // operand_count > 4 or doesn't match operands

	// Shared decoding errors
	BUFFER_TOO_SHORT,
	INVALID_OPCODE,

	// x86-specific decoding errors
	INVALID_MODRM,
	INVALID_SIB,
	INVALID_PREFIX,
	INVALID_VEX,
	INVALID_EVEX,
	TOO_MANY_PREFIXES,
}

Error :: struct #packed {
	inst_idx: u32,    // Which instruction failed (or byte offset for decode)
	code:     Error_Code,
	_:        [3]u8,
}
#assert(size_of(Error) == 8)

