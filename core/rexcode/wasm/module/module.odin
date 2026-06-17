package rexcode_wasm_module

import "base:runtime"
import "core:rexcode/wasm"

WASM_MAGIC   :: u32(0x6d736100)   // "\0asm" as a little-endian u32
WASM_VERSION :: u32(1)

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

Section :: struct {
	id:     Section_Id,
	offset: u32,      // file offset of the section *contents*
	size:   u32,      // contents length in bytes
	count:  u32,      // element count
	name:   string,   // custom-section name (borrowed)
}

External_Kind :: enum u8 {
	FUNC   = 0,
	TABLE  = 1,
	MEMORY = 2,
	GLOBAL = 3,
}

@(rodata)
external_kind_string := [External_Kind]string{
	.FUNC   = "func",
	.TABLE  = "table",
	.MEMORY = "memory",
	.GLOBAL = "global",
}

Func_Type :: struct {
	params:  []wasm.Value_Type,
	results: []wasm.Value_Type,
}

Import :: struct {
	kind:        External_Kind,
	module_name: string, // borrowed
	field_name:  string, // borrowed
	index:       u32,    // typeidx for FUNC, 0 for other kinds
}

Export :: struct {
	kind:  External_Kind,
	name:  string, // borrowed
	index: u32,
}

// A compressed run of declared locals (e.g. `3 x i32`)
Local_Group :: struct {
	count: u32,
	type:  wasm.Value_Type,
}

// A function in the module's function index space.
// Imported functions occupy the low indices, followed by the module-defined functions.
Function :: struct {
	func_index:    u32,
	type_index:    u32,
	type:          Func_Type,     // resolved signature ({} if the type id was out of range)
	imported:      bool,
	name:          string,        // export / name-section / import field (borrowed)
	import_module: string,        // borrowed, "" for defined functions
	import_field:  string,        // borrowed, "" for defined functions

	// defined functions only:
	locals:        []Local_Group,
	body_offset:   u32,           // file offset of the instruction stream
	body_size:     u32,           // instruction-stream length in bytes
}

Module :: struct {
	version:   u32,
	sections:  []Section,
	types:     []Func_Type,
	imports:   []Import,
	functions: []Function, // whole function index space (imports + defined)
	exports:   []Export,
	start:     i64,        // -1 if absent, else the start funcidx

	data:      []u8,       // borrowed reference to the whole file (body decode reads from it)

	allocator: runtime.Allocator,
}

// -----------------------------------------------------------------------------
// Small display helpers
// -----------------------------------------------------------------------------


@(require_results)
section_name :: proc(id: Section_Id) -> string {
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
valtype_name :: proc(t: wasm.Value_Type) -> string {
	switch t {
	case .I32:       return "i32"
	case .I64:       return "i64"
	case .F32:       return "f32"
	case .F64:       return "f64"
	case .V128:      return "v128"
	case .FUNCREF:   return "funcref"
	case .EXTERNREF: return "externref"
	}
	return "?"
}

@(require_results)
external_kind_name :: proc(k: External_Kind) -> string {
	switch k {
	case .FUNC:   return "func"
	case .TABLE:  return "table"
	case .MEMORY: return "memory"
	case .GLOBAL: return "global"
	}
	return "?"
}
