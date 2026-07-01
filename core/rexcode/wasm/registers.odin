// rexcode  ·  Brendan Punsky (dotbmp@github), original author
//             Ginger Bill (gingerBill@github)

package rexcode_wasm

// =============================================================================
// WebAssembly "REGISTERS"
// =============================================================================
//
// WebAssembly is a stack machine: it has no general-purpose register file.
// Operands live on an implicit value stack and instructions reference locals,
// globals, and various index spaces by LEB128 immediate -- never by register.
//
// The cross-arch naming contract still asks every package for a `Register`
// type plus `reg_hw` / `reg_class` accessors, so we keep the same packed
// `distinct u16` scheme (class in the high byte, index in the low byte) used
// by the register-machine arches. It is *vestigial* here: the REGISTER
// operand kind is never produced by the encoder or decoder, and the value
// stack is modelled implicitly. The real per-arch content WASM cares about --
// value types and the index spaces -- lives below and in operands.odin.

Register :: distinct u16

REG_NONE :: 0x0000

NONE :: Register(0xFFFF)

@(require_results)
reg_hw :: #force_inline proc "contextless" (r: Register) -> u8 {
	return u8(r) & 0xFF
}

@(require_results)
reg_class :: #force_inline proc "contextless" (r: Register) -> u16 {
	return u16(r) & 0xFF00
}

@(require_results)
reg_size :: #force_inline proc "contextless" (_: Register) -> u8 {
	return 0   // no fixed width: the value stack is implicit
}

// -----------------------------------------------------------------------------
// Value types (the bytes WASM actually uses where a register would otherwise
// appear: block result/param types, ref.null heap types, select t* types).
//
// The numeric byte is the WASM binary encoding; the same byte sign-extends to
// the negative s33 value used inside a blocktype. See operands.odin /
// Block_Type for how these participate in block / loop / if.
// -----------------------------------------------------------------------------

Value_Type :: enum u8 {
	I32       = 0x7F,
	I64       = 0x7E,
	F32       = 0x7D,
	F64       = 0x7C,
	V128      = 0x7B,
	FUNCREF   = 0x70,
	EXTERNREF = 0x6F,
}

@(require_results)
value_type_is_num :: #force_inline proc "contextless" (t: Value_Type) -> bool {
	#partial switch t {
	case .I32, .I64, .F32, .F64: return true
	}
	return false
}

@(require_results)
value_type_is_ref :: #force_inline proc "contextless" (t: Value_Type) -> bool {
	#partial switch t {
	case .FUNCREF, .EXTERNREF: return true
	}
	return false
}
