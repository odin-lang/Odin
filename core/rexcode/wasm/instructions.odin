// rexcode  ·  Brendan Punsky (dotbmp@github), original author
//             Ginger Bill (gingerBill@github)

package rexcode_wasm

// =============================================================================
// INSTRUCTION
// =============================================================================
//
// WASM instructions are variable length: a single opcode byte (or a prefix
// byte 0xFC/0xFD/0xFE plus an unsigned-LEB sub-opcode) followed by zero or
// more immediate fields. Two immediate slots cover every modelled form
// (e.g. call_indirect's typeidx + tableidx, table.copy's two tableidx).
//
// `br_table` is the one operator whose immediate is a *vector* of label
// depths; its default label lives in ops[0] and the case targets in the
// `targets` slice (caller-owned, like the rest of the input). `length` is
// filled by the encoder (and by the decoder) since it is not fixed.

Instruction_Flags :: bit_field u8 {
	_: u8 | 8,
}

Instruction :: struct {
	ops:           [2]Operand `fmt:"v,operand_count"`,
	targets:       []u32,                              // br_table case labels (default in ops[0])
	bytes:         [16]u8,                             // v128.const value / i8x16.shuffle lane mask (LANES16)
	mnemonic:      Mnemonic,
	operand_count: u8,
	flags:         Instruction_Flags,
	length:        u8,                                 // filled by encoder/decoder (1..N)
	_:             [3]u8,
}
#assert(size_of(Instruction) == 48 + 2*size_of(int))

// =============================================================================
// Builders (shape spelled out, comma-separated -- contract surface)
// =============================================================================

@(require_results)
inst_none :: #force_inline proc "contextless" (m: Mnemonic) -> Instruction {
	return Instruction{mnemonic = m, operand_count = 0}
}

// Single immediate constant (i32/i64/f32/f64.const, ref.null).
@(require_results)
inst_i :: #force_inline proc "contextless" (m: Mnemonic, o: Operand) -> Instruction {
	return Instruction{mnemonic = m, operand_count = 1, ops = {o, {}}}
}

// Single index immediate (local/global/func/.../label).
@(require_results)
inst_idx :: #force_inline proc "contextless" (m: Mnemonic, o: Operand) -> Instruction {
	return Instruction{mnemonic = m, operand_count = 1, ops = {o, {}}}
}

// Memory access: a single memarg.
@(require_results)
inst_memarg :: #force_inline proc "contextless" (m: Mnemonic, ma: Memarg) -> Instruction {
	return Instruction{mnemonic = m, operand_count = 1, ops = {op_mem(ma), {}}}
}

// Block / loop / if with a signature.
@(require_results)
inst_block :: #force_inline proc "contextless" (m: Mnemonic, bt: Block_Type = .EMPTY) -> Instruction {
	return Instruction{mnemonic = m, operand_count = 1, ops = {op_blocktype(bt), {}}}
}

// Branch with a relative label depth (br / br_if).
@(require_results)
inst_br :: #force_inline proc "contextless" (m: Mnemonic, depth: u32) -> Instruction {
	return Instruction{mnemonic = m, operand_count = 1, ops = {op_labelidx(depth), {}}}
}

// br_table: a vector of case depths plus a default depth.
@(require_results)
inst_br_table :: #force_inline proc "contextless" (targets: []u32, default_depth: u32) -> Instruction {
	return Instruction{
		mnemonic = .BR_TABLE, operand_count = 1,
		ops = {op_labelidx(default_depth), {}}, targets = targets,
	}
}

// call_indirect typeidx, tableidx.
@(require_results)
inst_call_indirect :: #force_inline proc "contextless" (type_index: u32, table_index: u32 = 0) -> Instruction {
	return Instruction{
		mnemonic = .CALL_INDIRECT, operand_count = 2,
		ops = {op_type(type_index), op_table(table_index)},
	}
}

// Two-index operators (table.init elemidx tableidx; table.copy dst src).
@(require_results)
inst_idx_idx :: #force_inline proc "contextless" (m: Mnemonic, a, b: Operand) -> Instruction {
	return Instruction{mnemonic = m, operand_count = 2, ops = {a, b}}
}

// -----------------------------------------------------------------------------
// SIMD (0xFD) builders
// -----------------------------------------------------------------------------

// v128.const: a 16-byte literal carried in `bytes` (no stack operand).
@(require_results)
inst_v128_const :: #force_inline proc "contextless" (value: [16]u8) -> Instruction {
	return Instruction{mnemonic = .V128_CONST, operand_count = 0, bytes = value}
}

// i8x16.shuffle: a 16-lane index mask carried in `bytes`.
@(require_results)
inst_shuffle :: #force_inline proc "contextless" (lanes: [16]u8) -> Instruction {
	return Instruction{mnemonic = .I8X16_SHUFFLE, operand_count = 0, bytes = lanes}
}

// extract_lane / replace_lane: a single lane index immediate.
@(require_results)
inst_lane :: #force_inline proc "contextless" (m: Mnemonic, lane: u8) -> Instruction {
	return Instruction{mnemonic = m, operand_count = 1, ops = {op_lane(lane), {}}}
}

// v128 load/store *_lane: a memarg plus a lane index.
@(require_results)
inst_mem_lane :: #force_inline proc "contextless" (m: Mnemonic, ma: Memarg, lane: u8) -> Instruction {
	return Instruction{mnemonic = m, operand_count = 2, ops = {op_mem(ma), op_lane(lane)}}
}

// =============================================================================
// Emitters (append to a [dynamic]Instruction)
// =============================================================================

emit_none :: #force_inline proc(buf: ^[dynamic]Instruction, m: Mnemonic) {
	append(buf, inst_none(m))
}
emit_i :: #force_inline proc(buf: ^[dynamic]Instruction, m: Mnemonic, o: Operand) {
	append(buf, inst_i(m, o))
}
emit_idx :: #force_inline proc(buf: ^[dynamic]Instruction, m: Mnemonic, o: Operand) {
	append(buf, inst_idx(m, o))
}
emit_memarg :: #force_inline proc(buf: ^[dynamic]Instruction, m: Mnemonic, ma: Memarg) {
	append(buf, inst_memarg(m, ma))
}
emit_block :: #force_inline proc(buf: ^[dynamic]Instruction, m: Mnemonic, bt: Block_Type = .EMPTY) {
	append(buf, inst_block(m, bt))
}
emit_br :: #force_inline proc(buf: ^[dynamic]Instruction, m: Mnemonic, depth: u32) {
	append(buf, inst_br(m, depth))
}
emit_call_indirect :: #force_inline proc(buf: ^[dynamic]Instruction, type_index: u32, table_index: u32 = 0) {
	append(buf, inst_call_indirect(type_index, table_index))
}
