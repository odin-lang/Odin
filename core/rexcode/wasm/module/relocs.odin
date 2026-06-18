package rexcode_wasm_module

import "base:runtime"
import "core:strings"
import wasm "core:rexcode/wasm"

Reloc_Group :: struct {
	target_section: Section_Id, // index of the section these apply to
	relocs:         []wasm.Relocation,
}

@(require_results)
parse_relocations :: proc(m: Module, allocator: runtime.Allocator) -> (reloc_groups: []Reloc_Group, err: Reader_Error) {
	groups: [dynamic]Reloc_Group
	groups.allocator = m.allocator
	for sec in m.sections {
		if !(sec.id == .CUSTOM && strings.has_prefix(sec.name, "reloc.")) {
			continue
		}

		r := reader(m.data[sec.offset:][:sec.size], 0)
		_ = rd_name(&r) or_return // step past the custom-section name
		target := Section_Id(rd_u32(&r) or_return)
		count  := rd_u32(&r) or_return

		out := make([]wasm.Relocation, int(count), m.allocator)
		w := 0
		for _ in 0..<count {
			code   := rd_byte(&r) or_return
			offset := rd_u32(&r)  or_return // offset of the field within target_section
			index  := rd_u32(&r)  or_return // symbol / target index
			addend: i32 = 0
			if reloc_has_addend(code) {
				addend = i32(rd_sleb(&r) or_return)
			}

			t := reloc_type_from_wire(code) or_continue

			out[w] = wasm.Relocation{
				offset   = offset,
				label_id = index,
				addend   = addend,
				type     = t,
				size     = reloc_field_size(t),
			}
			w += 1
		}
		append(&groups, Reloc_Group{target_section = target, relocs = out[:w]}) or_return
	}
	reloc_groups = groups[:]
	return
}

relocations_destroy :: proc(groups: []Reloc_Group, allocator: runtime.Allocator) {
	context.allocator = allocator
	for g in groups { delete(g.relocs) }
	delete(groups)
}

@(require_results)
reloc_type_from_wire :: proc(code: u8) -> (wasm.Relocation_Type, bool) {
	switch code {
	case 0:  return .FUNCTION_INDEX_LEB, true   // R_WASM_FUNCTION_INDEX_LEB
	case 1:  return .TABLE_INDEX_SLEB,   true   // R_WASM_TABLE_INDEX_SLEB
	case 2:  return .TABLE_INDEX_I32,    true   // R_WASM_TABLE_INDEX_I32
	case 3:  return .MEMORY_ADDR_LEB,    true   // R_WASM_MEMORY_ADDR_LEB
	case 4:  return .MEMORY_ADDR_SLEB,   true   // R_WASM_MEMORY_ADDR_SLEB
	case 5:  return .MEMORY_ADDR_I32,    true   // R_WASM_MEMORY_ADDR_I32
	case 6:  return .TYPE_INDEX_LEB,     true   // R_WASM_TYPE_INDEX_LEB
	case 7:  return .GLOBAL_INDEX_LEB,   true   // R_WASM_GLOBAL_INDEX_LEB
	case 20: return .TABLE_NUMBER_LEB,   true   // R_WASM_TABLE_NUMBER_LEB
	}
	return .NONE, false
}

// MEMORY_ADDR_* (3,4,5) and the *_OFFSET_I32 (8,9) forms carry a trailing
// signed-LEB addend; the index-type relocations do not.
@(require_results)
reloc_has_addend :: proc(code: u8) -> bool {
	switch code {
	case 3, 4, 5, 8, 9: return true
	}
	return false
}

@(require_results)
reloc_field_size :: proc(t: wasm.Relocation_Type) -> u8 {
	#partial switch t {
	case .TABLE_INDEX_I32, .MEMORY_ADDR_I32:
		return 4 // 4-byte LE field
	}
	return 5 // 5-byte padded (S)LEB field
}
