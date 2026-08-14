// rexcode  ·  Brendan Punsky (dotbmp@github), original author

package rexcode_ir

// =============================================================================
// REFERENCES  (the IR analog of isa.labels)
// =============================================================================
//
// This is the first place the IR API genuinely diverges from the ISA API.
//
// An ISA resolves control flow as *PC-relative labels*: `Label_Definition`
// maps a label id to an instruction index and `encode()` rewrites it to a byte
// offset (isa.labels.rewrite_label_defs_to_offsets). That model is wrong for an
// IR: IR operands reference *entities by id* -- SSA results, blocks, functions,
// globals, types -- which are stable indices into the module's entity tables,
// not byte offsets, and resolve *structurally* (no PC-relative pass).
//
// So the label machinery is replaced, not re-exported. What survives in spirit:
//   * a small distinct-u32 id type with an "undefined" sentinel (forward refs),
//   * a name<->id table for the externally-visible symbols (the Label_Map analog).
//
// Object-file *symbol* fixups (a linker patching a function/global index) are
// still real and still produce Relocations -- but that is a codec concern,
// defined per-IR (parallel to each arch's reloc.odin), not here.

// A stable id into one of the module's entity spaces (see Ref_Space).
Id :: distinct u32

ID_NONE :: Id(0xFFFFFFFF)

// Which id space a reference addresses. Drives validation, printer annotation,
// and (for EXTERNAL) relocation-type selection. This is the union of the spaces
// the modelled IRs use; a concrete IR uses only the subset it needs -- a stack
// IR (WASM) never produces a VALUE ref, an untyped IR never produces a TYPE ref.
Ref_Space :: enum u8 {
	NONE,
	VALUE,      // an SSA result (or a local/stack slot)
	BLOCK,      // a basic block / structured-control label (branch target)
	FUNCTION,
	GLOBAL,
	TYPE,
	CONSTANT,   // a constant-pool entry
	MEMORY,     // a linear memory / address space
	METADATA,   // a metadata/debug node
	EXTERNAL,   // an imported/exported symbol -- relocatable across object files
}

// A typed reference: which space, plus the id within it. Carried by REF operands
// and by branch targets. 8 bytes, like isa.Label_Definition is u32-cheap.
Ref :: struct #packed {
	id:    Id,
	space: Ref_Space,
	_:     [3]u8,
}
#assert(size_of(Ref) == 8)

@(require_results)
ref :: #force_inline proc "contextless" (space: Ref_Space, id: Id) -> Ref {
	return Ref{id = id, space = space}
}

// -----------------------------------------------------------------------------
// Symbol table  (the IR analog of isa.Label_Map: name <-> id for visible names)
// -----------------------------------------------------------------------------

Symbol_Table :: struct {
	names: map[string]Id,
	space: Ref_Space,   // what these names address (usually FUNCTION/GLOBAL)
}

symbol_table_init :: #force_inline proc(st: ^Symbol_Table, space := Ref_Space.EXTERNAL, allocator := context.allocator) {
	st.names = make(map[string]Id, allocator = allocator)
	st.space = space
}

symbol_table_destroy :: #force_inline proc(st: ^Symbol_Table) {
	delete(st.names)
}

// Bind a name to an id (e.g. when a definition is emitted).
symbol_define :: #force_inline proc(st: ^Symbol_Table, name: string, id: Id) {
	st.names[name] = id
}

// Reserve a name for a forward reference; resolve later with symbol_define.
@(require_results)
symbol_reserve :: #force_inline proc(st: ^Symbol_Table, name: string) -> Id {
	if existing, ok := st.names[name]; ok {
		return existing
	}
	st.names[name] = ID_NONE
	return ID_NONE
}

@(require_results)
symbol_lookup :: #force_inline proc(st: ^Symbol_Table, name: string) -> (id: Id, ok: bool) {
	id, ok = st.names[name]
	return
}
