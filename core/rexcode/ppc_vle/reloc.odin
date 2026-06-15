// rexcode  ·  Brendan Punsky (dotbmp@github), original author

package rexcode_ppc_vle

// =============================================================================
// PowerPC VLE Relocations
// =============================================================================
//
// VLE-specific branch and immediate relocation forms.
//
// Branch displacements (from binutils):
//   BD8  (16-bit): 8-bit signed << 1, PC-rel, ±256 bytes (se_b, se_bl)
//   BD8IO (16-bit): same width, with BO/BI baked
//   BD15 (32-bit): 15-bit signed << 1, PC-rel, ±32KB (e_bc, e_bcl)
//   EBD15/EBD15BI (32-bit): same width, with BO/BI baked
//   BD24 (32-bit): 24-bit signed << 1, PC-rel, ±16MB (e_b, e_bl)
//
// ELF relocation types (binutils elf/ppc.h R_PPC_VLE_*):
//   REL8/REL15/REL24    PC-relative branches (matches BD8/BD15/BD24)
//   LO16A/HI16A/HA16A   16-bit immediate halves, A-form (I16A imm position)
//   LO16D/HI16D/HA16D   16-bit immediate halves, D-form (32-bit D-form)
//   SDA21               21-bit small data area (e_add16i_sda variant)
//   SDAREL_*16{A,D}     SDA-relative variants of LO/HI/HA
//   ADDR20              20-bit absolute address (LI20 form)

Relocation_Type :: enum u8 {
	NONE = 0,

	// Internal (encoder-resolved) branch relocations
	BRANCH_BD8,   // 8-bit signed << 1 at bits 7..0 of halfword
	BRANCH_BD15,  // 15-bit signed << 1 at bits 1..15 of low halfword
	BRANCH_BD24,  // 24-bit signed << 1 at bits 1..24 of word

	// ELF-spec relocations (linker-bound — encoder emits them but doesn't
	// resolve them locally)
	R_PPC_VLE_REL8,         // 216 — like BRANCH_BD8 but ELF-emitted
	R_PPC_VLE_REL15,        // 217
	R_PPC_VLE_REL24,        // 218
	R_PPC_VLE_LO16A,        // 219 — low 16 bits, A-form imm (I16A bit positions)
	R_PPC_VLE_LO16D,        // 220 — low 16 bits, D-form imm
	R_PPC_VLE_HI16A,        // 221 — high 16 bits, A-form
	R_PPC_VLE_HI16D,        // 222 — high 16 bits, D-form
	R_PPC_VLE_HA16A,        // 223 — high-adjusted 16 bits, A-form
	R_PPC_VLE_HA16D,        // 224 — high-adjusted 16 bits, D-form
	R_PPC_VLE_SDA21,        // 225 — 21-bit small-data-area
	R_PPC_VLE_SDA21_LO,     // 226 — like SDA21 but no overflow check
	R_PPC_VLE_SDAREL_LO16A, // 227
	R_PPC_VLE_SDAREL_LO16D, // 228
	R_PPC_VLE_SDAREL_HI16A, // 229
	R_PPC_VLE_SDAREL_HI16D, // 230
	R_PPC_VLE_SDAREL_HA16A, // 231
	R_PPC_VLE_SDAREL_HA16D, // 232
	R_PPC_VLE_ADDR20,       // 233 — 20-bit absolute (LI20)
}

// Mapping table — each VLE reloc's official ELF number.
elf_reloc_number :: proc(t: Relocation_Type) -> u32 {
	#partial switch t {
	case .R_PPC_VLE_REL8:         return 216
	case .R_PPC_VLE_REL15:        return 217
	case .R_PPC_VLE_REL24:        return 218
	case .R_PPC_VLE_LO16A:        return 219
	case .R_PPC_VLE_LO16D:        return 220
	case .R_PPC_VLE_HI16A:        return 221
	case .R_PPC_VLE_HI16D:        return 222
	case .R_PPC_VLE_HA16A:        return 223
	case .R_PPC_VLE_HA16D:        return 224
	case .R_PPC_VLE_SDA21:        return 225
	case .R_PPC_VLE_SDA21_LO:     return 226
	case .R_PPC_VLE_SDAREL_LO16A: return 227
	case .R_PPC_VLE_SDAREL_LO16D: return 228
	case .R_PPC_VLE_SDAREL_HI16A: return 229
	case .R_PPC_VLE_SDAREL_HI16D: return 230
	case .R_PPC_VLE_SDAREL_HA16A: return 231
	case .R_PPC_VLE_SDAREL_HA16D: return 232
	case .R_PPC_VLE_ADDR20:       return 233
	}
	return 0
}

Relocation :: struct #packed {
	offset:   u32,
	label_id: u32,
	addend:   i32,
	type:     Relocation_Type,
	size:     u8,
	inst_idx: u16,
}
#assert(size_of(Relocation) == 16)
