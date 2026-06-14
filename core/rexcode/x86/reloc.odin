package rexcode_x86

// =============================================================================
// x86 RELOCATIONS
// =============================================================================
//
// The Relocation struct shape (offset, label_id, addend, type, size,
// inst_idx) mirrors ELF rela so a downstream object emitter can consume it
// unchanged. Per the cross-arch design (§2.4) each arch owns its own
// Relocation_Type values; nothing about the resolution semantics is
// shared across architectures.

Relocation_Type :: enum u8 {
	NONE = 0,
	REL8,    // 8-bit PC-relative (short jump)
	REL32,   // 32-bit PC-relative (call, jmp, RIP-relative)
	ABS32,   // 32-bit absolute address
	ABS64,   // 64-bit absolute address (movabs)
}

Relocation :: struct #packed {
	offset:   u32,             // byte offset in output where fixup needed
	label_id: u32,             // label ID this references
	addend:   i32,             // addend for relocation calculation
	type:     Relocation_Type,
	size:     u8,              // bytes to patch (1, 4, or 8)
	inst_idx: u16,             // instruction index (for error reporting)
}
#assert(size_of(Relocation) == 16)

// =============================================================================
// Patch primitives
// =============================================================================
//
// Byte-level write helpers for the four x86 relocation kinds. These are
// `#force_inline` so the encoder's pass-2 dispatch collapses into one
// straight-line block.

// 8-bit signed PC-relative offset. Returns false if the resolved offset
// falls outside [-128, 127]; the byte is still written (truncated) so the
// caller can decide how to report.
patch_pcrel_i8 :: #force_inline proc "contextless" (
	code: []u8, patch_offset: u32, target: u32, next_pc: u32, addend: i32,
) -> bool {
	relative := i32(target) - i32(next_pc) + addend
	code[patch_offset] = u8(i8(relative))
	return relative >= -128 && relative <= 127
}

// 32-bit signed PC-relative offset.
patch_pcrel_i32 :: #force_inline proc "contextless" (
	code: []u8, patch_offset: u32, target: u32, next_pc: u32, addend: i32,
) {
	relative := i32(target) - i32(next_pc) + addend
	code[patch_offset]     = u8(relative)
	code[patch_offset + 1] = u8(relative >> 8)
	code[patch_offset + 2] = u8(relative >> 16)
	code[patch_offset + 3] = u8(relative >> 24)
}

// 32-bit absolute address: base + target + addend.
patch_abs32 :: #force_inline proc "contextless" (
	code: []u8, patch_offset: u32, target: u32, base_address: u64, addend: i32,
) {
	absolute := u32(base_address) + target + u32(addend)
	code[patch_offset]     = u8(absolute)
	code[patch_offset + 1] = u8(absolute >> 8)
	code[patch_offset + 2] = u8(absolute >> 16)
	code[patch_offset + 3] = u8(absolute >> 24)
}

// 64-bit absolute address: base + target + addend.
patch_abs64 :: #force_inline proc "contextless" (
	code: []u8, patch_offset: u32, target: u32, base_address: u64, addend: i32,
) {
	absolute := base_address + u64(target) + u64(addend)
	for j in u32(0)..<8 {
		code[patch_offset + j] = u8(absolute >> (j * 8))
	}
}
