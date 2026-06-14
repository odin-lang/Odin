package rexcode_ppc_vle_tests

import "core:fmt"
import "core:os"
import "core:strings"
import v ".."
import "../../isa"

@(private="file")
check :: proc(name: string, ok: bool) {
	if ok {
		fmt.printf("  [ok]   %s\n", name)
		ok_count += 1
	} else {
		fmt.printf("  [FAIL] %s\n", name)
		fail_count += 1
	}
}

run_extension :: proc() {
	fmt.println("==== ppc_vle extensions test ====")

	// ----- ELF reloc type numbers ------------------------------------------
	check("R_PPC_VLE_REL8 = 216",   v.elf_reloc_number(.R_PPC_VLE_REL8)  == 216)
	check("R_PPC_VLE_REL15 = 217",  v.elf_reloc_number(.R_PPC_VLE_REL15) == 217)
	check("R_PPC_VLE_REL24 = 218",  v.elf_reloc_number(.R_PPC_VLE_REL24) == 218)
	check("R_PPC_VLE_SDA21 = 225",  v.elf_reloc_number(.R_PPC_VLE_SDA21) == 225)
	check("R_PPC_VLE_ADDR20 = 233", v.elf_reloc_number(.R_PPC_VLE_ADDR20) == 233)

	// ----- Named SPR printing ----------------------------------------------
	{
		// se_mtlr — implicit LR target; but for explicit SPR test use a 32-bit
		// mtspr-style instruction. Since our VLE table doesn't have mtspr
		// explicitly, just verify register name lookup via direct print.
		// (We can't easily test this without an mtspr/mfspr-style mnemonic
		// with SPR operand in VLE encoding, so just confirm the constants
		// exist.)
		check("v.XER constant",    u16(v.XER)     == 0x6001)
		check("v.LR constant",     u16(v.LR)      == 0x6008)
		check("v.CTR constant",    u16(v.CTR)     == 0x6009)
		check("v.SRR0 constant",   u16(v.SRR0)    == 0x601A)
		check("v.IVPR constant",   u16(v.IVPR)    == 0x603F)
		check("v.SPRG0 constant",  u16(v.SPRG0)   == 0x6110)
		check("v.SPEFSCR constant",u16(v.SPEFSCR) == 0x6200)
	}

	// ----- Decode dispatch tables present ----------------------------------
	{
		// Just confirm DECODE_ENTRIES exists and has 222 entries
		check("DECODE_ENTRIES populated", len(v.DECODE_ENTRIES) == 222)
		check("DECODE_BUCKET_LIST populated", len(v.DECODE_BUCKET_LIST) == 222)
		check("DECODE_INDEX_SHORT 64 buckets", len(v.DECODE_INDEX_SHORT) == 64)
		check("DECODE_INDEX_LONG 64 buckets",  len(v.DECODE_INDEX_LONG) == 64)
	}

	// ----- Mixed-mode (VLE + standard PPC) demo ----------------------------
	// We can't directly mix in the same encoder pass, but we can show that
	// a sequence of VLE instructions encodes/decodes cleanly while the
	// ppc/ package handles standard PPC separately. This is just informational.
	{
		instructions := [?]v.Instruction{
			v.inst_r_r(.SE_MR, v.R3, v.R4),
			v.inst_r_r_i(.E_ADDI, v.R5, v.R3, 100),
			v.inst_none(.SE_BLR),
		}
		code := make([]u8, 16, context.temp_allocator)
		relocs: [dynamic]v.Relocation; defer delete(relocs)
		errors: [dynamic]v.Error;      defer delete(errors)
		labels: []isa.Label_Definition
		r := v.encode(instructions[:], labels, code, &relocs, &errors)
		check("mixed 16/32-bit sequence encodes", r.success)

		decoded: [dynamic]v.Instruction; defer delete(decoded)
		info:    [dynamic]v.Instruction_Info; defer delete(info)
		dlabs:   [dynamic]v.Label_Definition; defer delete(dlabs)
		derrs:   [dynamic]v.Error; defer delete(derrs)
		dr := v.decode(code[:r.byte_count], nil, &decoded, &info, &dlabs, &derrs)
		check("mixed sequence decodes", dr.success)
		check("decoded 3 instructions", len(decoded) == 3)
		check("first inst is SE_MR (16-bit)", decoded[0].length == 2)
		check("second inst is E_ADDI (32-bit)", decoded[1].length == 4)
		check("third inst is SE_BLR (16-bit)", decoded[2].length == 2)

		sb := strings.builder_make(context.temp_allocator)
		v.sbprint(&sb, decoded[:], info[:], dlabs[:], nil, nil)
		asm_text := strings.to_string(sb)
		check("printer outputs se_mr",   strings.contains(asm_text, "se_mr"))
		check("printer outputs e_addi",  strings.contains(asm_text, "e_addi"))
		check("printer outputs se_blr",  strings.contains(asm_text, "se_blr"))
		fmt.printf("Sample mixed disassembly:\n%s", asm_text)
	}

	fmt.printf("\n==> extensions: %d passed, %d failed\n", ok_count, fail_count)
	if fail_count > 0 { os.exit(1) }
}
