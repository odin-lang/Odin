// rexcode  ·  Brendan Punsky (dotbmp@github), original author
//             Ginger Bill (gingerBill@github)

package rexcode_wasm

// =============================================================================
// WebAssembly RELOCATIONS
// =============================================================================
//
// Per the cross-arch design (§2.4) each arch owns its Relocation_Type. WASM's
// relocations are the object-file ("linking") relocations: symbolic index
// references the linker fixes up. They are emitted, never PC-relative -- WASM
// control flow uses structured label depths, not byte offsets, so the encoder
// does not resolve these in a pass 2; it records them and leaves the patching
// to the linker. The relocatable LEB encodings are written as fixed-width
// 5-byte placeholders so the patched value always fits.
//
// The subset modelled mirrors the names from the tool-conventions linking
// spec used by LLVM / wasm-ld.

Relocation_Type :: enum u8 {
	NONE = 0,

	FUNCTION_INDEX_LEB,    // funcidx, 5-byte ULEB (call, ref.func)
	TABLE_INDEX_SLEB,      // 5-byte SLEB table element index
	TABLE_INDEX_I32,       // 4-byte LE table element index
	MEMORY_ADDR_LEB,       // linear-memory address, 5-byte ULEB
	MEMORY_ADDR_SLEB,      // linear-memory address, 5-byte SLEB
	MEMORY_ADDR_I32,       // linear-memory address, 4-byte LE
	TYPE_INDEX_LEB,        // typeidx, 5-byte ULEB (call_indirect)
	GLOBAL_INDEX_LEB,      // globalidx, 5-byte ULEB
	TABLE_NUMBER_LEB,      // tableidx, 5-byte ULEB
}

Relocation :: struct #packed {
	offset:   u32,              // byte offset of the relocatable field
	label_id: u32,              // symbol / target label id
	addend:   i32,
	type:     Relocation_Type,
	size:     u8,               // bytes occupied by the field (5 for LEB, 4 for I32)
	inst_idx: u16,
}
#assert(size_of(Relocation) == 16)

// A set of relocations that apply to one section (parsed from a `reloc.<name>`
// custom section). Grouped by the section they target so the decoder can hand
// the CODE-section group to each function body it decodes.
Reloc_Group :: struct {
	target_section: Section_Id,
	relocs:         []Relocation,
}

// The relocations (if any) that patch fields in the given section.
@(require_results)
relocations_for_section :: proc "contextless" (groups: []Reloc_Group, id: Section_Id) -> []Relocation {
	for g in groups {
		if g.target_section == id { return g.relocs }
	}
	return nil
}

// -----------------------------------------------------------------------------
// Object-file (tool-conventions) relocation wire format
// -----------------------------------------------------------------------------

// Decode a relocation type byte from a `reloc.*` custom section. `ok` is false
// for a type this codec does not model (the entry is then skipped).
@(require_results)
reloc_type_from_wire :: proc "contextless" (code: u8) -> (Relocation_Type, bool) {
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

// MEMORY_ADDR_* (3,4,5) and the *_OFFSET_I32 forms (8,9) carry a trailing
// signed-LEB addend; the index-type relocations do not.
@(require_results)
reloc_has_addend :: proc "contextless" (code: u8) -> bool {
	switch code {
	case 3, 4, 5, 8, 9: return true
	}
	return false
}

// On-wire field width of a relocation, in bytes.
@(require_results)
reloc_field_size :: proc "contextless" (t: Relocation_Type) -> u8 {
	#partial switch t {
	case .TABLE_INDEX_I32, .MEMORY_ADDR_I32:
		return 4 // 4-byte LE field
	}
	return 5 // 5-byte padded (S)LEB field
}
