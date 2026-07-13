// rexcode  ·  Brendan Punsky (dotbmp@github), original author
//             Ginger Bill (gingerBill@github)

package rexcode_wasm

import "core:rexcode/ir"

// =============================================================================
// SECTION: Module  (the WASM module -- ir core + WASM's own container sections)
// =============================================================================
//
// `wasm.Module` is the `ir.Module` STACK core (functions -> blocks -> operations,
// dataflow = .STACK) plus the WASM binary-container sections the shared core has
// no slot for. A concrete IR carries those "alongside the core" per
// docs/ir_design.md §3; here that is literal -- `using base: ir.Module` embeds
// the core so `m.functions`, `m.globals`, ... read straight through -- exactly
// the shape `spirv.Module` uses for its preamble / debug / annotation sections.
//
// Mapping the WASM container onto the ir core:
//
//   * A WASM function body is one `expr` (a flat instruction stream). It lowers
//     to a single `ir.Block` of `ir.Operation`s under one `ir.Function`; the
//     structured control ops (block/loop/if/else/end) remain *operations* within
//     that block rather than nested `ir.Block`s -- WASM's structure is carried
//     by those ops and their label depths, matching how the decoder produced a
//     flat stream. (Nesting into regions is a valid later refinement.)
//
//   * WASM function signatures are `[]Value_Type -> []Value_Type`, not the ir
//     type table's `Type_Kind`. Rather than lower every primitive into
//     `ir.Module.types`, WASM keeps its value-typed signatures in the parallel
//     `func_types` side table (analogous to how `spirv.Module` keeps
//     `opaque_info` for what the shared core does not slot). `ir.Function.
//     signature` indexes `func_types` by convention.

Section_Id :: enum u8 { // Binary section ids (WebAssembly core spec §5.5.2).
	CUSTOM     = 0,
	TYPE       = 1,
	IMPORT     = 2,
	FUNCTION   = 3,
	TABLE      = 4,
	MEMORY     = 5,
	GLOBAL     = 6,
	EXPORT     = 7,
	START      = 8,
	ELEMENT    = 9,
	CODE       = 10,
	DATA       = 11,
	DATA_COUNT = 12,
}

External_Kind :: enum u8 {
	FUNC   = 0,
	TABLE  = 1,
	MEMORY = 2,
	GLOBAL = 3,
}

// A WASM function signature: value-typed params and results.
Func_Type :: struct {
	params:  []Value_Type,
	results: []Value_Type,
}

Import :: struct {
	kind:        External_Kind,
	module_name: string,
	field_name:  string,
	index:       u32,     // typeidx for FUNC, 0 for other kinds
}

Export :: struct {
	kind:  External_Kind,
	name:  string,
	index: u32,
}

// The WASM module -- the unit the verbs operate on. Embeds the ir core; adds the
// container metadata parsed from / emitted to the binary sections.
Module :: struct {
	using base: ir.Module,   // functions, globals, symbols, dataflow (= .STACK), target

	version: u32,            // WASM_VERSION if 0 on encode

	// --- container sections (the WASM-specific data the ir core has no slot for) ---
	func_types: []Func_Type, // the type section; ir.Function.signature indexes here
	imports:    []Import,
	exports:    []Export,
	start:      i64,         // -1 if absent, else the start funcidx

	// --- side tables parallel to the ir core arrays ---
	// A WASM function's declared locals (the code section's local groups), kept
	// parallel to base.functions since ir.Function has no locals slot.
	function_locals: [][]Value_Type,
}

// A freshly-made WASM module declares STACK dataflow so the shared verbs and the
// printer pick the stack-machine path (no SSA results, no value refs).
@(require_results)
make_module :: proc "contextless" () -> Module {
	m: Module
	m.base.dataflow = .STACK
	m.version       = WASM_VERSION
	m.start         = -1
	return m
}
