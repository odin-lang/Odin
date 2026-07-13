// rexcode  ·  Brendan Punsky (dotbmp@github), original author

package rexcode_ir

// =============================================================================
// STRUCTURAL MODEL  (the core of the IR API)
// =============================================================================
//
// The central divergence from the ISA API. An ISA program is a flat
// `[]Instruction`; an IR program is a *typed, structured module* --
//
//     Module → []Function → []Block → []Operation
//
// where an operation may define an SSA result that later operations reference.
//
// Design stance vs the ISA API:
//
//   * The leaf is kept ISA-shaped on purpose. `Operation` is `isa.Instruction`
//     plus an optional typed `Result`; `opcode` is the concrete IR's Opcode
//     enum stored as a u16, exactly as `isa` stores `Mnemonic` as a u16. So the
//     opcode-table dispatch, the encode/decode/print verbs, and the relocation
//     model all carry over.
//
//   * `Operand` is *shared* here, where `isa.Operand` is per-arch. Justified:
//     ISA operands diverge wildly (ModRM/SIB vs shifted-register vs ...), but
//     SSA collapses IR operands to "a literal, a reference to an entity, or a
//     type", which is uniform enough to define once. Dialect-specific operand
//     encodings (WASM memarg, SPIR-V enum masks) ride in `aux` + the IR's own
//     opcode table -- they are an encoding detail, not a new operand shape.
//
//   * Both dataflow styles are first-class. `Dataflow` is a per-IR trait, NOT a
//     baked-in assumption: a stack IR (WASM) leaves `Result.id == ID_NONE` and
//     references nothing through VALUE; an SSA IR (SPIR-V/LLVM) names results
//     and threads them as REF operands. The model excludes neither.
//
// What is deliberately NOT here: the wire codec (`encode`/`decode`) and the
// printer. Those are per-IR -- just as `isa` defines no `encode`, each concrete
// IR provides its own, against the contract in `doc.odin`. This package is the
// shared *vocabulary*, not an implementation.

// Per-IR dataflow discipline. WASM = STACK; SPIR-V / LLVM / AIR / DXIL = SSA.
Dataflow :: enum u8 { STACK, SSA }

// -----------------------------------------------------------------------------
// Operand  (generalizes isa.Operand)
// -----------------------------------------------------------------------------

Operand_Kind :: enum u8 {
	NONE,
	LIT_INT,     // integer literal (value in `imm`)
	LIT_FLOAT,   // float literal (IEEE bits in `imm`, width in `aux`)
	REF,         // reference to an entity: `imm` is the Id, `space` the Ref_Space
	TYPE,        // a Type_Ref (in the low 32 bits of `imm`)
	ATTRIBUTE,   // a dialect enum / decoration / mask (value in `imm`, tag in `aux`)
}

// 16 bytes. The payload is one i64 (covers an Id, a Type_Ref, an int/float-bits
// literal, or an attribute value); `space`/`aux` discriminate the entity space
// or dialect tag. Large/aggregate constants are *entities* (a CONSTANT ref), not
// inline operands -- the SSA way -- so no inline byte blob is needed here.
Operand :: struct #packed {
	imm:   i64,
	kind:  Operand_Kind,
	space: Ref_Space,    // REF: which id space
	aux:   u16,          // LIT_FLOAT width / ATTRIBUTE tag / dialect bits
	flags: u32,
}
#assert(size_of(Operand) == 16)

@(require_results) op_int   :: #force_inline proc "contextless" (v: i64)             -> Operand { return Operand{kind = .LIT_INT,   imm = v} }
@(require_results) op_float :: #force_inline proc "contextless" (bits: u64, w: u16)  -> Operand { return Operand{kind = .LIT_FLOAT, imm = i64(bits), aux = w} }
@(require_results) op_type  :: #force_inline proc "contextless" (t: Type_Ref)        -> Operand { return Operand{kind = .TYPE, imm = i64(u32(t))} }

@(require_results)
op_ref :: #force_inline proc "contextless" (space: Ref_Space, id: Id) -> Operand {
	return Operand{kind = .REF, space = space, imm = i64(u32(id))}
}

@(require_results) op_value :: #force_inline proc "contextless" (id: Id) -> Operand { return op_ref(.VALUE, id) }
@(require_results) op_block :: #force_inline proc "contextless" (id: Id) -> Operand { return op_ref(.BLOCK, id) }

// Reconstruct the Id / Type_Ref carried by an operand.
@(require_results) operand_id   :: #force_inline proc "contextless" (o: Operand) -> Id       { return Id(u32(o.imm)) }
@(require_results) operand_type :: #force_inline proc "contextless" (o: Operand) -> Type_Ref { return Type_Ref(u32(o.imm)) }

// -----------------------------------------------------------------------------
// Operation  (the leaf -- parallels isa.Instruction)
// -----------------------------------------------------------------------------

Operation_Flags :: bit_field u8 {
	terminator: bool | 1,   // ends a block (br / ret / switch / unreachable)
	control:    bool | 1,   // structured-control op (block/loop/if/... for stack IRs)
	memory:     bool | 1,   // touches linear memory / pointers
	_:          u8   | 5,
}

// `opcode` is the concrete IR's Opcode enum, stored as u16 (like isa.Mnemonic).
// `operands` is variable-arity (calls, switch, phi) and caller-owned, like the
// rest of the decoded module -- the fixed `[4]Operand` of the ISA Instruction is
// the one shape that does not survive into IRs.
Operation :: struct {
	operands: []Operand,
	result:   Result,       // SSA def; `.id == ID_NONE` for stack/void ops
	opcode:   u16,
	flags:    Operation_Flags,
	_:        u8,
}

// What an operation produces.
Result :: struct #packed {
	id:   Id,         // ID_NONE if the op defines no value
	type: Type_Ref,
}
#assert(size_of(Result) == 8)

// -----------------------------------------------------------------------------
// Containers  (no ISA parallel -- the structured-module concession)
// -----------------------------------------------------------------------------

// A basic block (SSA) or a structured region (stack IRs). `params` are block
// arguments (SSA, phi-free form); empty for stack IRs. The terminator is the
// final operation (Operation_Flags.terminator).
Block :: struct {
	ops:    []Operation,
	params: []Result,
	id:     Id,
}

Function :: struct {
	blocks:    []Block,
	name:      string,
	signature: Type_Ref,   // a FUNCTION type in Module.types
	id:        Id, // not used by all formats
}

// A module-level mutable/immutable value.
Global :: struct {
	name: string,
	init: Id,          // a CONSTANT ref, or ID_NONE
	type: Type_Ref,
	mutable: bool,
}

// The module -- the unit the IR verbs operate on (where the ISA verbs take a
// flat `[]Instruction`). Metadata, decorations, and dialect custom sections are
// carried by the concrete IR alongside this core, the way each arch carries its
// own reloc.odin.
Module :: struct {
	target:    string,        // triple / capability profile / version tag
	types:     []Type,        // the type table; Type_Ref indexes here
	globals:   []Global,
	functions: []Function,
	symbols:   Symbol_Table,  // externally-visible names
	dataflow:  Dataflow,
}
