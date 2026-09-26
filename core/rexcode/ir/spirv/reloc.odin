// rexcode  ·  Brendan Punsky (dotbmp@github), original author

package rexcode_spirv

// =============================================================================
// SECTION: Relocation  (SPIR-V linkage fixups -- the per-IR reloc.odin)
// =============================================================================
//
// SPIR-V is normally self-contained: operands reference entities by <id>,
// resolved structurally, with no cross-object fixups. The one exception is
// *linkage*: an <id> decorated `LinkageAttributes` with `Import` is defined in
// another module and `Export` is offered to one. A linker matching imports to
// exports by name is the SPIR-V analog of an object-file symbol fixup, so it is
// surfaced as a `Relocation` the way each arch surfaces its own (parallel to an
// arch's reloc.odin), produced by `encode` for EXTERNAL references.
//
// Not #packed (unlike the small ISA Relocation): the linkage name is a string.

Relocation_Type :: enum u8 {
	NONE,
	IMPORT,   // the <id> is imported (LinkageType Import) -- undefined here
	EXPORT,   // the <id> is exported (LinkageType Export) -- visible to other modules
}

Relocation :: struct {
	id:   Id,                // the <id> carrying the LinkageAttributes decoration
	name: string,            // the external linkage name to match across modules
	type: Relocation_Type,
}
