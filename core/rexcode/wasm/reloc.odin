// rexcode  ·  Brendan Punsky (dotbmp@github), original author
//             Ginger Bill (gingerBill@github)
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
