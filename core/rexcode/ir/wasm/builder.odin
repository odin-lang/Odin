// rexcode  ·  Brendan Punsky (dotbmp@github), original author
//             Ginger Bill (gingerBill@github)

package rexcode_wasm

import "base:runtime"

// =============================================================================
// SECTION: Builder  (constructing ir.Operations for a WASM function body)
// =============================================================================
//
// The IR leaf is `ir.Operation` -- an opcode (u16), a variable-arity `[]Operand`
// (caller-owned, unlike the old ISA `Instruction`'s inline [2]Operand), and an
// optional typed `Result` (always `.id == ID_NONE` here: WASM is a stack machine
// and names no results). So every builder that carries operands must allocate
// their backing store; the `Builder` below owns that store and accumulates ops
// into the current block, mirroring `spirv.Builder`.

// Operation flags derived from the opcode's ENCODING_TABLE form, plus the
// terminator bit for the ops that end a stack-IR region.
@(require_results)
op_flags_for :: proc "contextless" (opcode: Opcode) -> Operation_Flags {
	e := ENCODING_TABLE[opcode]
	f: Operation_Flags
	f.control = e.flags.control
	f.memory  = e.flags.memory
	#partial switch opcode {
	case .RETURN, .UNREACHABLE,
	     .BR, .BR_TABLE,
	     .RETURN_CALL, .RETURN_CALL_INDIRECT:
		f.terminator = true
	}
	return f
}

// The stack-IR result: WASM defines no SSA value, so every operation's result is
// empty. (Kept as a helper so the intent is explicit at every call site.)
@(require_results)
no_result :: #force_inline proc "contextless" () -> Result {
	return Result{id = ID_NONE, type = TYPE_NONE}
}

// -----------------------------------------------------------------------------
// Stateless construction (caller owns `operands`)
// -----------------------------------------------------------------------------

// Build an Operation over an already-owned operand slice (no allocation).
@(require_results)
operation :: #force_inline proc "contextless" (opcode: Opcode, operands: []Operand = nil) -> Operation {
	return Operation{
		opcode   = u16(opcode),
		operands = operands,
		result   = no_result(),
		flags    = op_flags_for(opcode),
	}
}

// -----------------------------------------------------------------------------
// Builder
// -----------------------------------------------------------------------------

Builder :: struct {
	alloc: runtime.Allocator,
	ops:   [dynamic]Operation,   // current block
}

@(require_results)
builder_make :: proc(allocator := context.allocator) -> Builder {
	b: Builder
	b.alloc = allocator
	b.ops.allocator = allocator
	return b
}

// Detach the accumulated operations as a block body (and reset for the next).
@(require_results)
take_block :: proc(b: ^Builder, label: Id = ID_NONE) -> Block {
	blk := Block{id = label, ops = b.ops[:]}
	b.ops = nil
	b.ops.allocator = b.alloc
	return blk
}

// Stable per-operation operand backing.
@(require_results)
opbuf :: proc(b: ^Builder, ops: ..Operand) -> []Operand {
	if len(ops) == 0 {
		return nil
	}
	buf := make([]Operand, len(ops), b.alloc)
	copy(buf, ops)
	return buf
}

// Append an operation with the given operands, allocating their backing.
emit :: proc(b: ^Builder, opcode: Opcode, operands: ..Operand) {
	append(&b.ops, operation(opcode, opbuf(b, ..operands)))
}

// -----------------------------------------------------------------------------
// Convenience emitters (a representative set; `emit` covers the rest)
// -----------------------------------------------------------------------------

emit_none  :: proc(b: ^Builder, opcode: Opcode) { emit(b, opcode) }

emit_i32   :: proc(b: ^Builder, v: i32) { emit(b, .I32_CONST, op_i32(v)) }
emit_i64   :: proc(b: ^Builder, v: i64) { emit(b, .I64_CONST, op_i64(v)) }
emit_f32   :: proc(b: ^Builder, v: f32) { emit(b, .F32_CONST, op_f32(v)) }
emit_f64   :: proc(b: ^Builder, v: f64) { emit(b, .F64_CONST, op_f64(v)) }

emit_local_get  :: proc(b: ^Builder, n: u32) { emit(b, .LOCAL_GET,  op_local(n)) }
emit_local_set  :: proc(b: ^Builder, n: u32) { emit(b, .LOCAL_SET,  op_local(n)) }
emit_local_tee  :: proc(b: ^Builder, n: u32) { emit(b, .LOCAL_TEE,  op_local(n)) }
emit_global_get :: proc(b: ^Builder, n: u32) { emit(b, .GLOBAL_GET, op_global(n)) }
emit_global_set :: proc(b: ^Builder, n: u32) { emit(b, .GLOBAL_SET, op_global(n)) }

emit_call :: proc(b: ^Builder, funcidx: u32) { emit(b, .CALL, op_func(funcidx)) }
emit_call_indirect :: proc(b: ^Builder, typeidx: u32, tableidx: u32 = 0) {
	emit(b, .CALL_INDIRECT, op_typeidx(typeidx), op_table(tableidx))
}

emit_block :: proc(b: ^Builder, bt: Block_Type = .EMPTY) { emit(b, .BLOCK, op_blocktype(bt)) }
emit_loop  :: proc(b: ^Builder, bt: Block_Type = .EMPTY) { emit(b, .LOOP,  op_blocktype(bt)) }
emit_if    :: proc(b: ^Builder, bt: Block_Type = .EMPTY) { emit(b, .IF,    op_blocktype(bt)) }
emit_else  :: proc(b: ^Builder) { emit(b, .ELSE) }
emit_end   :: proc(b: ^Builder) { emit(b, .END) }

emit_br    :: proc(b: ^Builder, depth: u32) { emit(b, .BR,    op_labelidx(depth)) }
emit_br_if :: proc(b: ^Builder, depth: u32) { emit(b, .BR_IF, op_labelidx(depth)) }

// br_table: operands are [default, case0, case1, ...], every entry a label depth.
emit_br_table :: proc(b: ^Builder, targets: []u32, default_depth: u32) {
	buf := make([]Operand, len(targets)+1, b.alloc)
	buf[0] = op_labelidx(default_depth)
	for t, i in targets {
		buf[i+1] = op_labelidx(t)
	}
	append(&b.ops, operation(.BR_TABLE, buf))
}

emit_return      :: proc(b: ^Builder) { emit(b, .RETURN) }
emit_unreachable :: proc(b: ^Builder) { emit(b, .UNREACHABLE) }

emit_load  :: proc(b: ^Builder, opcode: Opcode, ma: Memarg) { emit(b, opcode, op_memarg(ma)) }
emit_store :: proc(b: ^Builder, opcode: Opcode, ma: Memarg) { emit(b, opcode, op_memarg(ma)) }

// v128.const / i8x16.shuffle: the 16-byte immediate as two ATTRIBUTE halves.
emit_v128_const :: proc(b: ^Builder, value: [16]u8) {
	lo, hi := op_v128(value)
	emit(b, .V128_CONST, lo, hi)
}
emit_shuffle :: proc(b: ^Builder, lanes: [16]u8) {
	lo, hi := op_v128(lanes)
	emit(b, .I8X16_SHUFFLE, lo, hi)
}
