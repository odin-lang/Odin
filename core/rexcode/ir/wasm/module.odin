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

// A parsed binary section header: where its *contents* live in the file and how
// many entries it declares. Kept so sections the ir core does not model
// structurally (table/memory/global/element/data) stay re-readable from `data`.
Section :: struct {
	id:     Section_Id,
	offset: u32,      // file offset of the section contents
	size:   u32,      // contents length in bytes
	count:  u32,      // declared element count (0 for CUSTOM / START)
	name:   string,   // custom-section name (borrowed from `data`)
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
//
// After `decode`, `base.functions` spans the whole WASM function index space:
// imported functions occupy the low indices (their `blocks` are empty -- an
// import has no body) followed by the module-defined functions (each a single
// `ir.Block` whose ops are the decoded body). `ir.Function.signature` is the
// function's typeidx (an index into `func_types`, by convention), and its
// `name` is resolved from the export and "name" custom sections.
Module :: struct {
	using base: ir.Module,   // functions, globals, symbols, dataflow (= .STACK), target

	version: u32,            // WASM_VERSION if 0 on encode

	// --- container sections (the WASM-specific data the ir core has no slot for) ---
	func_types: []Func_Type, // the type section; ir.Function.signature indexes here
	imports:    []Import,
	exports:    []Export,
	start:      i64,         // -1 if absent, else the start funcidx

	customs:    []Custom_Section,

	// --- side tables parallel to the ir core arrays ---
	// A WASM function's declared locals (the code section's local groups), kept
	// parallel to base.functions since ir.Function has no locals slot.
	function_locals: [][]Value_Type,

	// --- preserved binary framing (so nothing decoded is lost / is re-readable) ---
	sections:    []Section,     // every section header, in file order
	relocations: []Reloc_Group, // object-file relocations, grouped by target section
	data:        []u8,          // borrowed whole-file bytes (table/memory/... re-readable)
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


// -----------------------------------------------------------------------------
// Custom Section Layout
// -----------------------------------------------------------------------------

Custom_Section :: struct {
	section: Section,
	payload: []byte, // borrowed, m.data[section.offset:][:section.size]
	variant: union {
		Custom_Section_Name,
		Custom_Section_Target_Features,
	},
}

Custom_Section_Name_Function :: struct {
	id:   u32,
	name: string, // borrowed
}

Custom_Section_Name_Local :: struct {
	idx:  u32,
	name: string, // borrowed
}

Custom_Section_Name_Function_Locals :: struct {
	func_idx: u32,
	locals: []Custom_Section_Name_Local,
}

Custom_Section_Name :: struct {
	module_name: string,
	functions:   []Custom_Section_Name_Function,
	locals:      []Custom_Section_Name_Function_Locals,
}

Custom_Section_Target_Feature_Prefix :: enum u8 {
	Used       = '+',
	Disallowed = '-',
	Required   = '=',
}

Custom_Section_Target_Feature :: struct {
	prefix:  Custom_Section_Target_Feature_Prefix,
	feature: string, // borrowed
}


Custom_Section_Target_Features :: struct {
	features: []Custom_Section_Target_Feature,
}


@(require_results)
section_name :: #force_inline proc "contextless" (id: Section_Id) -> string {
	switch id {
	case .CUSTOM:     return "custom"
	case .TYPE:       return "type"
	case .IMPORT:     return "import"
	case .FUNCTION:   return "function"
	case .TABLE:      return "table"
	case .MEMORY:     return "memory"
	case .GLOBAL:     return "global"
	case .EXPORT:     return "export"
	case .START:      return "start"
	case .ELEMENT:    return "element"
	case .CODE:       return "code"
	case .DATA:       return "data"
	case .DATA_COUNT: return "data.count"
	}
	return "unknown"
}


@(require_results)
count_import_kind :: proc "contextless" (m: Module, k: External_Kind) -> u32 {
	n: u32 = 0
	for imp in m.imports {
		if imp.kind == k {
			n += 1
		}
	}
	return n
}


@(require_results)
module_name :: proc "contextless" (m: Module) -> (string, bool) {
	for c in m.customs {
		#partial switch v in c.variant {
		case Custom_Section_Name:
			if v.module_name != "" {
				return v.module_name, true
			}
		}
	}
	return "", false
}