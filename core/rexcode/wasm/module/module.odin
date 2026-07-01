package rexcode_wasm_module

import "base:runtime"
import "core:fmt"
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
	exported:      bool,
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
	customs:   []Custom_Section,
	types:     []Func_Type,
	imports:   []Import,
	functions: []Function, // whole function index space (imports + defined)
	exports:   []Export,
	start:     i64,        // -1 if absent, else the start funcidx

	reloc_groups: []Reloc_Group,

	data:      []u8,       // borrowed reference to the whole file (body decode reads from it)

	allocator: runtime.Allocator,
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
valtype_name :: #force_inline proc "contextless" (t: wasm.Value_Type) -> string {
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
external_kind_name :: #force_inline proc "contextless" (k: External_Kind) -> string {
	switch k {
	case .FUNC:   return "func"
	case .TABLE:  return "table"
	case .MEMORY: return "memory"
	case .GLOBAL: return "global"
	}
	return "?"
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
block_sig :: proc "contextless" (m: Module, imm: i64) -> (params: int, results: int) {
	if imm < 0 {
		if imm == i64(wasm.Block_Type.EMPTY) {
			return 0, 0
		}
		return 0, 1 // single value-type result
	}
	if int(imm) < len(m.types) {
		t := m.types[imm]
		return len(t.params), len(t.results)
	}
	return 0, 0
}



// Stack arity (operands consumed, results produced) for non-control operators,
// plus the control operators that flow through the plain path. Block/loop/if
// are handled directly by `wat_fold_region`.
@(require_results)
instruction_arity :: proc(m: Module, inst: wasm.Instruction) -> (inputs: int, outputs: int) {
	e := &wasm.ENCODING_TABLE[inst.mnemonic]
	inputs, outputs = int(e.inputs), int(e.outputs)
	if inputs < 0 || outputs < 0 {
		#partial switch inst.mnemonic {
		case .CALL, .RETURN_CALL:
			if int(inst.ops[0].index) < len(m.functions) {
				t := m.functions[inst.ops[0].index].type
				return len(t.params), len(t.results)
			}
			return 0, 0
		case .CALL_INDIRECT, .RETURN_CALL_INDIRECT:
			if int(inst.ops[0].index) < len(m.types) {
				t := m.types[inst.ops[0].index]
				return len(t.params) + 1, len(t.results)
			}
			return 1, 0

		case .RETURN:
			if int(inst.ops[0].index) < len(m.types) {
				t := m.types[inst.ops[0].index]
				return len(t.results), 0
			}
			return 0, 0
		}
		fmt.panicf("Unknown optional arity handling %v", inst.mnemonic)
	}
	return
}
