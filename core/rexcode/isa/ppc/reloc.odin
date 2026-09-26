// rexcode  ·  Brendan Punsky (dotbmp@github), original author

package rexcode_ppc

// =============================================================================
// PowerPC RELOCATIONS
// =============================================================================
//
// PowerPC has two PC-relative branch forms in the base ISA:
//
//   * I-form b/bl/ba/bla:    24-bit signed << 2 (±32MB)
//   * B-form bc/bca/bcl/bcla: 14-bit signed << 2 (±32KB) with BO/BI fixed
//
// Power ISA 3.1 prefixed PC-relative loads/stores extend the displacement
// to 34 bits via the prefix word's R=1 form, but those are normally encoded
// via the prefixed-immediate path, not via relocations.
//
// PC for PowerPC is the address of the current instruction (not pc+8 like
// ARM). The resolver subtracts the current offset.

Relocation_Type :: enum u8 {
	NONE = 0,
	BRANCH_I_24,     // I-form: LI (24-bit signed << 2 at bits 2..25 LSB)
	BRANCH_B_14,     // B-form: BD (14-bit signed << 2 at bits 2..15 LSB)
	PREFIXED_34,     // Power ISA 3.1: 34-bit signed at IMM18(prefix)||D(suffix)
}

Relocation :: struct #packed {
	offset:   u32,             // byte offset into code buffer
	label_id: u32,
	addend:   i32,
	type:     Relocation_Type,
	size:     u8,              // 4 (base) or 8 (prefixed)
	inst_idx: u16,
}
#assert(size_of(Relocation) == 16)
