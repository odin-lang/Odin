// rexcode  ·  Brendan Punsky (dotbmp@github), original author

package rexcode_spirv

import "base:runtime"

// =============================================================================
// SECTION: Builder  (typed instruction construction -- infrastructure)
// =============================================================================
//
// The SPIR-V analog of an ISA's mnemonic builders comes in two layers, both
// GENERATED per opcode in builders_gen.odin (by tablegen/gen.odin):
//
//   * Low level -- `inst_<OpName>(buf, ...)`: a stateless, allocation-free typed
//     constructor returning an Operation. The caller owns `buf`, the operand
//     backing store (SPIR-V operands are a slice, so unlike an ISA's inline
//     [4]Operand they cannot be owned by the returned value).
//
//   * High level -- methods on the `Builder` below that own operand storage and
//     allocate result <id>s; `i_add(b, ty, a, c)` appends to the current block
//     and returns the new <id>. The ergonomic SSA-construction API.
//
// This file holds only the hand-written Builder infrastructure the generated
// high-level methods build on.

// Accumulates operations into the current block. `next_id` hands out fresh result
// <id>s; operand backing for each op is allocated from `alloc` (stable, unlike a
// shared growing pool). Build a function by emitting ops, then take_block into a
// Block; set Module.bound from `next_id`.
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

// Stable per-operation operand backing; used by the generated high-level methods.
opbuf :: #force_inline proc(b: ^Builder, n: int) -> []Operand {
	return make([]Operand, n, b.alloc)
}

// Composite operand kinds: variadic pairs (used by OpPhi / OpSwitch /
// OpGroupMemberDecorate). The generated builders take these as []Pair_*.
Pair_Id_Id  :: struct { a, b: Id }          // PairIdRefIdRef
Pair_Lit_Id :: struct { lit: i64, id: Id }  // PairLiteralIntegerIdRef
Pair_Id_Lit :: struct { id: Id, lit: i64 }  // PairIdRefLiteralInteger

// Pack a LiteralString operand into `buf` as op_int word operands (the UTF-8
// bytes, NUL-terminated, little-endian, word-padded). Returns the count written.
pack_string_operands :: proc "contextless" (buf: []Operand, s: string) -> int {
	nwords := (len(s) + 4) / 4
	for wi in 0 ..< nwords {
		word: u32 = 0
		for b in 0 ..< 4 {
			idx := wi * 4 + b
			if idx < len(s) { word |= u32(s[idx]) << uint(b * 8) }
		}
		buf[wi] = op_int(i64(word))
	}
	return nwords
}
