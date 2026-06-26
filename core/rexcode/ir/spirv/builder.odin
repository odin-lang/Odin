// rexcode  ·  Brendan Punsky (dotbmp@github), original author

package rexcode_spirv

import "base:runtime"

// =============================================================================
// SECTION: Builders  (typed instruction construction)
// =============================================================================
//
// Two layers, the SPIR-V analog of an ISA's mnemonic builders:
//
//   * Low level -- `inst_<OpName>(buf, ...)`: a stateless, allocation-free typed
//     constructor returning an Operation. The caller owns `buf`, the operand
//     backing store (SPIR-V operands are a slice, so unlike an ISA's inline
//     [4]Operand they cannot be owned by the returned value).
//
//   * High level -- a `Builder` that owns operand storage and allocates result
//     <id>s; `b->iadd(ty, a, c)` appends to the current block and returns the new
//     <id>. The ergonomic SSA-construction API.
//
// This file hand-writes a representative slice (covering Id / no-result / variadic
// / enum operands) to fix the pattern; `tablegen/gen.odin` will generate the full
// per-opcode set for both layers from the grammar.

// -----------------------------------------------------------------------------
// Low-level constructors  (caller owns `buf`)
// -----------------------------------------------------------------------------

inst_OpIAdd :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, operand_1, operand_2: Id) -> Operation {
	buf[0] = op_value(operand_1)
	buf[1] = op_value(operand_2)
	return Operation{opcode = u16(Opcode.OpIAdd), result = {result, result_type}, operands = buf[:2]}
}

inst_OpLoad :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result, pointer: Id) -> Operation {
	buf[0] = op_value(pointer)
	return Operation{opcode = u16(Opcode.OpLoad), result = {result, result_type}, operands = buf[:1]}
}

inst_OpStore :: #force_inline proc "contextless" (buf: []Operand, pointer, object: Id) -> Operation {
	buf[0] = op_value(pointer)
	buf[1] = op_value(object)
	return Operation{opcode = u16(Opcode.OpStore), result = {id = ID_NONE}, operands = buf[:2]}
}

inst_OpReturn :: #force_inline proc "contextless" () -> Operation {
	return Operation{opcode = u16(Opcode.OpReturn), result = {id = ID_NONE}}
}

inst_OpReturnValue :: #force_inline proc "contextless" (buf: []Operand, value: Id) -> Operation {
	buf[0] = op_value(value)
	return Operation{opcode = u16(Opcode.OpReturnValue), result = {id = ID_NONE}, operands = buf[:1]}
}

// A variadic operand (the call arguments) is a trailing slice.
inst_OpFunctionCall :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result, function: Id, arguments: []Id) -> Operation {
	buf[0] = op_value(function)
	for a, i in arguments { buf[1 + i] = op_value(a) }
	return Operation{opcode = u16(Opcode.OpFunctionCall), result = {result, result_type}, operands = buf[:1 + len(arguments)]}
}

// An enum operand (the storage class) becomes a typed parameter.
inst_OpVariable :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, storage_class: Storage_Class) -> Operation {
	buf[0] = op_int(i64(storage_class))
	return Operation{opcode = u16(Opcode.OpVariable), result = {result, result_type}, operands = buf[:1]}
}

// -----------------------------------------------------------------------------
// High-level builder  (owns storage, allocates <id>s)
// -----------------------------------------------------------------------------

// Accumulates operations into the current block. `next_id` hands out fresh result
// <id>s; operand backing for each op is allocated from `alloc` (stable, unlike a
// shared growing pool). Drive a function with begin_block / end into Blocks, and
// set Module.bound from `next_id`.
Builder :: struct {
	alloc:   runtime.Allocator,
	next_id: u32,
	ops:     [dynamic]Operation,   // current block
}

@(require_results)
builder_make :: proc(first_id: u32 = 1, allocator := context.allocator) -> Builder {
	b: Builder
	b.alloc = allocator
	b.next_id = first_id
	b.ops.allocator = allocator
	return b
}

// Allocate a fresh result <id>.
@(require_results)
alloc_id :: proc(b: ^Builder) -> Id {
	id := Id(b.next_id)
	b.next_id += 1
	return id
}

// Detach the accumulated operations as a block body (and reset for the next block).
@(require_results)
take_block :: proc(b: ^Builder, label: Id) -> Block {
	blk := Block{id = label, ops = b.ops[:]}
	b.ops = nil
	b.ops.allocator = b.alloc
	return blk
}

@(private="file")
opbuf :: #force_inline proc(b: ^Builder, n: int) -> []Operand {
	return make([]Operand, n, b.alloc)
}

iadd :: proc(b: ^Builder, result_type: Type_Ref, a, c: Id) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpIAdd(opbuf(b, 2), result_type, r, a, c))
	return r
}

load :: proc(b: ^Builder, result_type: Type_Ref, pointer: Id) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpLoad(opbuf(b, 1), result_type, r, pointer))
	return r
}

store :: proc(b: ^Builder, pointer, object: Id) {
	append(&b.ops, inst_OpStore(opbuf(b, 2), pointer, object))
}

call :: proc(b: ^Builder, result_type: Type_Ref, function: Id, arguments: []Id) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpFunctionCall(opbuf(b, 1 + len(arguments)), result_type, r, function, arguments))
	return r
}

variable :: proc(b: ^Builder, result_type: Type_Ref, storage_class: Storage_Class) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpVariable(opbuf(b, 1), result_type, r, storage_class))
	return r
}

ret :: proc(b: ^Builder) {
	append(&b.ops, inst_OpReturn())
}

ret_value :: proc(b: ^Builder, value: Id) {
	append(&b.ops, inst_OpReturnValue(opbuf(b, 1), value))
}
