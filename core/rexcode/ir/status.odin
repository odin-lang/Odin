// rexcode  ·  Brendan Punsky (dotbmp@github), original author

package rexcode_ir

// =============================================================================
// ERROR / RESULT TYPES (shared by every IR codec)
// =============================================================================
//
// Parallels isa.status. The `Error` struct shape is intentionally identical to
// `isa.Error` (8 bytes: a u32 location + a 1-byte code) so a tool can surface
// ISA and IR diagnostics through one path. `Error_Code` keeps the encode/decode
// codes shared with the ISA side, then adds the codes only a *typed, structured*
// IR can produce. Per-IR codecs emit the subset that applies to them.

Error_Code :: enum u8 {
	NONE = 0,

	// Shared with the ISA side (encode/decode of the byte/word stream).
	INVALID_OPCODE,
	NO_MATCHING_ENCODING,
	OPERAND_MISMATCH,
	IMMEDIATE_OUT_OF_RANGE,
	BUFFER_OVERFLOW,
	BUFFER_TOO_SHORT,

	// IR-specific (no ISA analog -- these need a type system / SSA / a module).
	INVALID_TYPE,         // malformed or out-of-range Type_Ref
	TYPE_MISMATCH,        // an operand/result type disagrees with the op signature
	UNDEFINED_REF,        // a Ref to an id/symbol that is never defined
	DUPLICATE_DEFINITION, // an id/symbol defined twice
	MALFORMED_MODULE,     // structural violation (block without terminator, ...)
	UNSUPPORTED_FEATURE,  // a capability/extension the codec does not implement
}

// `location` is the operation index on encode, or the byte offset on decode --
// mirroring isa.Error.inst_idx.
Error :: struct #packed {
	location: u32,
	code:     Error_Code,
	_:        [3]u8,
}
#assert(size_of(Error) == 8)
