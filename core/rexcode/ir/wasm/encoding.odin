// rexcode  ·  Brendan Punsky (dotbmp@github), original author
//             Ginger Bill (gingerBill@github)

package rexcode_wasm

// =============================================================================
// SECTION: Encoding fundamentals  (the table-driven codec vocabulary)
// =============================================================================
//
// An instruction is:  [prefix?] opcode  immediate*
//
//   * `prefix` is 0 for the single-byte core opcodes, or one of 0xFC (misc),
//     0xFD (SIMD), 0xFE (threads). When present, the *sub*-opcode that follows
//     is an unsigned LEB128 (so SIMD's 0..0x113 fit).
//   * Integer immediates use LEB128 (unsigned for indices/alignment, signed for
//     i32.const/i64.const and the s33 blocktype).
//   * Float constants are raw little-endian IEEE-754 (4 or 8 bytes).
//
// There is at most one encoding form per opcode, so dispatch is a direct
// `ENCODING_TABLE[opcode]` lookup (O(1)) -- the docs/ir_design.md §5 "table-
// driven" strategy, literally the ISA `ENCODING_TABLE` shape. The immediate
// layout is described declaratively by `imm: [2]Imm_Kind`, walked in order by
// the encoder and decoder, each kind consuming zero or more `ir.Operand`s (see
// operands.odin for how a WASM immediate maps onto an `ir.Operand`).

Encoding_Flags :: bit_field u8 {
	control: bool | 1,   // structured control flow (block/loop/if/else/end/br*)
	memory:  bool | 1,   // touches linear memory
	_:       u8   | 6,
}

// How one immediate field is laid down after the opcode.
Imm_Kind :: enum u8 {
	NONE,
	BLOCKTYPE,    // signed LEB128 s33 (negative valtype byte, or type index)
	I32,          // signed LEB128 (i32.const)
	I64,          // signed LEB128 (i64.const)
	F32,          // 4 little-endian bytes
	F64,          // 8 little-endian bytes
	IDX,          // unsigned LEB128 index (space comes from the operand)
	MEMARG,       // unsigned LEB128 align, then unsigned LEB128 offset
	REFTYPE,      // single value-type byte (ref.null)
	BR_TABLE,     // unsigned LEB128 count, that many label depths, default depth
	ZERO_BYTE,    // a single reserved 0x00 byte (memidx placeholders)
	LANE,         // single byte lane index (SIMD extract/replace/load/store lane)
	LANES16,      // sixteen raw bytes (v128.const value / i8x16.shuffle mask)
}

Encoding :: struct #packed {
	mnemonic: Opcode,         // 2 -- redundant w/ table index, kept for parity
	prefix:   u8,             // 1 -- PREFIX_NONE / PREFIX_MISC / PREFIX_SIMD / PREFIX_ATOM
	opcode:   u16,            // 2 -- primary opcode, or sub-opcode within a prefix group
	imm:      [2]Imm_Kind,    // 2 -- immediate layout, walked in order
	flags:    Encoding_Flags, // 1
	inputs:   i8,             // 1 -- stack operands consumed;  -1 when it varies
	outputs:  i8,             // 1 -- stack results produced;   -1 when it varies
}
#assert(size_of(Encoding) == 10)

// `inputs`/`outputs` give an instruction's fixed stack arity: how many values
// it pops and pushes. They are -1 when the count is not a constant of the opcode
// -- i.e. it depends on a type/blocktype immediate or the surrounding control
// frame (call/call_indirect, block/loop/if/else/end, br*/return, unreachable).

// =============================================================================
// SECTION: Value types  (the leaf types WASM names -- block result/param types,
// ref.null heap types, select t* types). The numeric byte is the WASM binary
// encoding; the same byte sign-extends to the negative s33 used in a blocktype.
// =============================================================================

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
