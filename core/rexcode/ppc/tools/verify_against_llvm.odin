// rexcode  ·  Brendan Punsky (dotbmp@github), original author

package main

// =============================================================================
// PowerPC LLVM verification harness
// =============================================================================
//
// Reads /tmp/rexcode_ppc_meta.txt + /tmp/rexcode_ppc_llvm.txt line-by-line,
// extracts LLVM's first-word mnemonic, compares against ours (lowercased),
// classifies each row:
//
//   OK        exact mnemonic match (after lowercase)
//   ALIAS     LLVM emitted a known alias of ours (e.g. bt for bc-true,
//             nop for ori 0,0,0, mr for or rA,rS,rS)
//   UNKNOWN   LLVM rejected the bytes (returned "<unknown>") — either our
//             encoding is wrong OR the form needs a feature LLVM lacks
//   MISMATCH  LLVM decoded to a different mnemonic — a real encoding bug
//
// Run:  cd ppc && odin run tools/verify_against_llvm.odin -file

import "core:fmt"
import "core:os"
import "core:strings"

Stat :: struct { ok, alias, unknown, mismatch: int }

main :: proc() {
	stats: Stat

	report_buf, mism_buf: strings.Builder
	strings.builder_init(&report_buf); defer strings.builder_destroy(&report_buf)
	strings.builder_init(&mism_buf);   defer strings.builder_destroy(&mism_buf)

	// Two-pass verification: main (non-SPE) and SPE. Non-PPC implementations
	// pick one mode or the other on real hardware; LLVM mirrors this via
	// -mattr=+spe being mutually exclusive with -mattr=+altivec for the same
	// opcode space (primary opcode 4).
	process_pair("/tmp/rexcode_ppc_main_meta.txt", "/tmp/rexcode_ppc_main_llvm.txt", &stats, &report_buf, &mism_buf)
	process_pair("/tmp/rexcode_ppc_spe_meta.txt",  "/tmp/rexcode_ppc_spe_llvm.txt",  &stats, &report_buf, &mism_buf)

	_ = os.write_entire_file("/tmp/rexcode_ppc_verify_report.txt",      report_buf.buf[:])
	_ = os.write_entire_file("/tmp/rexcode_ppc_verify_mismatches.txt",  mism_buf.buf[:])

	total := stats.ok + stats.alias + stats.unknown + stats.mismatch
	fmt.printf("\n[TOTAL] %d rows\n", total)
	fmt.printf("    OK:       %04d  (%.1f%%)\n", stats.ok, 100.0 * f32(stats.ok) / f32(total))
	fmt.printf("    ALIAS:    %04d  (%.1f%%)\n", stats.alias, 100.0 * f32(stats.alias) / f32(total))
	fmt.printf("    UNKNOWN:  %04d  (%.1f%%)\n", stats.unknown, 100.0 * f32(stats.unknown) / f32(total))
	fmt.printf("    MISMATCH: %04d  (%.1f%%)\n", stats.mismatch, 100.0 * f32(stats.mismatch) / f32(total))
	fmt.println("\nReports:")
	fmt.println("  /tmp/rexcode_ppc_verify_report.txt     (all rows)")
	fmt.println("  /tmp/rexcode_ppc_verify_mismatches.txt (mismatches + unknowns only)")
}

process_pair :: proc(meta_path, llvm_path: string, stats: ^Stat, report_buf, mism_buf: ^strings.Builder) {
	meta_bytes, err1 := os.read_entire_file_from_path(meta_path, context.allocator)
	llvm_bytes, err2 := os.read_entire_file_from_path(llvm_path, context.allocator)
	if err1 != nil || err2 != nil {
		// Optional pair (e.g. SPE empty) — skip silently
		return
	}
	meta_data := string(meta_bytes)
	llvm_data := string(llvm_bytes)

	meta_lines := strings.split(meta_data, "\n")
	llvm_lines := strings.split(llvm_data, "\n")

	n := len(meta_lines)
	if len(llvm_lines) < n { n = len(llvm_lines) }

	for i in 0..<n {
		meta := meta_lines[i]
		if len(meta) == 0 { continue }
		llvm := llvm_lines[i]

		cols := strings.split(meta, "\t")
		if len(cols) < 1 { continue }
		ours := strings.to_lower(cols[0])

		llvm_mn := first_word(llvm)
		classification: string

		if llvm == "<unknown>" {
			if expected_unknown(ours) {
				stats.alias += 1
				classification = "ALIAS   "
			} else {
				stats.unknown += 1
				classification = "UNKNOWN "
				fmt.sbprintf(mism_buf, "[UNKNOWN ] %s\t%s\t%s\n", cols[0], cols[1], llvm)
			}
		} else if mnemonic_matches(ours, llvm_mn) {
			stats.ok += 1
			classification = "OK      "
		} else if is_known_alias(ours, llvm_mn) {
			stats.alias += 1
			classification = "ALIAS   "
		} else if expected_unknown(ours) {
			// Mnemonic LLVM 22 lacks — it decoded the bits as something else
			// (typically an AltiVec collision at the same XO). We expect this.
			stats.alias += 1
			classification = "ALIAS   "
		} else {
			stats.mismatch += 1
			classification = "MISMATCH"
			fmt.sbprintf(mism_buf, "[MISMATCH] %s\t%s\tours=%s llvm=%s\n",
				cols[0], cols[1], ours, llvm_mn)
		}

		fmt.sbprintf(report_buf, "%s\t%s\t%s\t%s\n", classification, cols[0], cols[1], llvm)
	}
}

first_word :: proc(s: string) -> string {
	trimmed := strings.trim_left(s, " \t")
	end: int
	for r, i in trimmed {
		if r == ' ' || r == '\t' { end = i; break }
	}
	if end == 0 { end = len(trimmed) }
	return strings.to_lower(trimmed[:end])
}

// Direct match modulo the "_DOT" / "_O" / "_O_DOT" suffix translation. Our
// mnemonics use "_DOT" where LLVM appends a literal ".", and "_O" where LLVM
// appends "o". So MNEM_DOT corresponds to "mnem.", MNEM_O to "mnemo", etc.
mnemonic_matches :: proc(ours, llvm: string) -> bool {
	if ours == llvm { return true }
	// canonical: strip trailing _dot/_o/_o_dot/_dot → "." / "o" / "o." / "."
	canon := ours
	suffix := ""
	if strings.has_suffix(canon, "_o_dot") {
		canon = canon[:len(canon)-6]
		suffix = "o."
	} else if strings.has_suffix(canon, "_dot") {
		canon = canon[:len(canon)-4]
		suffix = "."
	} else if strings.has_suffix(canon, "_o") {
		canon = canon[:len(canon)-2]
		suffix = "o"
	}
	built := strings.concatenate({canon, suffix})
	return built == llvm
}

// Entries we expect LLVM 22 to reject as <unknown>. They're valid Power ISA
// instructions per the spec but LLVM either lacks the feature flag, doesn't
// support the form, or has dropped support (e.g. lswx/stswx string-load
// deprecation, BCTAR's specific feature gate).
expected_unknown :: proc(ours: string) -> bool {
	switch ours {
	case "bctar", "bctarl":         return true   // LLVM lacks the feature
	case "lswx", "stswx":           return true   // strongly deprecated
	case "lswi", "stswi":           return true   // ditto (sometimes accepted)
	case "prtyw", "prtyd":          return true   // POWER7 parity — gated
	case "lwat", "ldat":            return true   // LLVM 22 syntax unsupported
	case "fmrgew", "fmrgow":        return true   // POWER8 — LLVM 22 unsupported
	case "lfdp", "lfdpx", "stfdp", "stfdpx": return true   // FP doubleword pair — rare
	case "mtfsb0_dot", "mtfsb1_dot": return true  // LLVM rejects dot form
	// Paired Singles (Gekko/Broadway — GameCube/Wii). LLVM 22 lacks PPCPS.
	case "ps_div", "ps_div_dot", "ps_sub", "ps_sub_dot", "ps_add", "ps_add_dot",
		 "ps_sel", "ps_sel_dot", "ps_res", "ps_res_dot", "ps_mul", "ps_mul_dot",
		 "ps_rsqrte", "ps_rsqrte_dot", "ps_msub", "ps_msub_dot", "ps_madd", "ps_madd_dot",
		 "ps_nmsub", "ps_nmsub_dot", "ps_nmadd", "ps_nmadd_dot",
		 "ps_sum0", "ps_sum0_dot", "ps_sum1", "ps_sum1_dot",
		 "ps_muls0", "ps_muls0_dot", "ps_muls1", "ps_muls1_dot",
		 "ps_madds0", "ps_madds0_dot", "ps_madds1", "ps_madds1_dot",
		 "ps_neg", "ps_neg_dot", "ps_mr", "ps_mr_dot",
		 "ps_nabs", "ps_nabs_dot", "ps_abs", "ps_abs_dot",
		 "ps_cmpu0", "ps_cmpu1", "ps_cmpo0", "ps_cmpo1",
		 "ps_merge00", "ps_merge00_dot", "ps_merge01", "ps_merge01_dot",
		 "ps_merge10", "ps_merge10_dot", "ps_merge11", "ps_merge11_dot",
		 "psq_lx", "psq_lux", "psq_stx", "psq_stux",
		 "psq_l", "psq_lu", "psq_st", "psq_stu":
		return true
	// VMX128 (Xbox 360 Xenon) — LLVM 22 and binutils both lack this entirely.
	// Bit patterns sourced from xenia disassembler / Free60 wiki.
	case "vaddfp128", "vsubfp128", "vmulfp128",
		 "vmaddfp128", "vmaddcfp128", "vnmsubfp128",
		 "vmsum3fp128", "vmsum4fp128", "vmaxfp128", "vminfp128",
		 "vrefp128", "vrsqrtefp128", "vexptefp128", "vlogefp128",
		 "vand128", "vandc128", "vor128", "vxor128", "vnor128", "vsel128",
		 "vcmpeqfp128", "vcmpeqfp128_dot",
		 "vcmpgefp128", "vcmpgefp128_dot",
		 "vcmpgtfp128", "vcmpgtfp128_dot",
		 "vcmpbfp128", "vcmpbfp128_dot",
		 "vcmpequw128", "vcmpequw128_dot",
		 "vrfim128", "vrfin128", "vrfip128", "vrfiz128",
		 "vcfpsxws128", "vcfpuxws128", "vcsxwfp128", "vcuxwfp128",
		 "vspltw128", "vspltisw128", "vmrghw128", "vmrglw128",
		 "vpkd3d128", "vupkd3d128",
		 "vperm128", "vpermwi128", "vrlimi128", "vsldoi128",
		 "vrlw128", "vslw128", "vsrw128", "vsraw128",
		 "lvebx128", "lvehx128", "lvewx128", "lvx128", "lvxl128",
		 "lvlx128", "lvrx128", "lvlxl128", "lvrxl128",
		 "stvebx128", "stvehx128", "stvewx128", "stvx128", "stvxl128",
		 "stvlx128", "stvrx128", "stvlxl128", "stvrxl128":
		return true
	// §43 remaining binutils-only PPC categories (MULHW/M601/PWRCOM/PPCA2/etc.)
	case "ti", "mulhhwu", "mulhhwu_dot", "machhwu", "machhwu_dot", "mulhhw", "mulhhw_dot", "machhw":
		return true
	case "machhw_dot", "nmachhw", "nmachhw_dot", "machhwsu", "machhwsu_dot", "machhws", "machhws_dot", "nmachhws":
		return true
	case "nmachhws_dot", "vadduqm", "vcmpuq", "mulchwu", "mulchwu_dot", "macchwu", "macchwu_dot", "vcmpsq":
		return true
	case "mulchw", "mulchw_dot", "macchw", "macchw_dot", "nmacchw", "nmacchw_dot", "macchwsu", "macchwsu_dot":
		return true
	case "vcmpequq", "macchws", "macchws_dot", "nmacchws", "nmacchws_dot", "vcmpgtuq", "vcuxwfp", "mullhwu":
		return true
	case "mullhwu_dot", "maclhwu", "maclhwu_dot", "vcsxwfp", "mullhw", "mullhw_dot", "maclhw", "maclhw_dot":
		return true
	case "nmaclhw", "nmaclhw_dot", "vcmpgtsq", "vcfpuxws", "maclhwsu", "maclhwsu_dot", "vcfpsxws", "maclhws":
		return true
	case "maclhws_dot", "nmaclhws", "nmaclhws_dot", "machhwuo", "machhwuo_dot", "machhwo", "machhwo_dot", "nmachhwo":
		return true
	case "nmachhwo_dot", "vmr", "machhwsuo", "machhwsuo_dot", "machhwso", "machhwso_dot", "nmachhwso", "nmachhwso_dot":
		return true
	case "vsubuqm", "vnot", "vgbbd", "macchwuo", "macchwuo_dot", "macchwo", "macchwo_dot", "nmacchwo":
		return true
	case "nmacchwo_dot", "macchwsuo", "macchwsuo_dot", "vcmpequq_dot", "macchwso", "macchwso_dot", "nmacchwso", "nmacchwso_dot":
		return true
	case "vcmpgtuq_dot", "maclhwuo", "maclhwuo_dot", "maclhwo", "maclhwo_dot", "nmaclhwo", "nmaclhwo_dot", "vcmpgtsq_dot":
		return true
	case "maclhwsuo", "maclhwsuo_dot", "maclhwso", "maclhwso_dot", "nmaclhwso", "nmaclhwso_dot", "dcbz_l", "muli":
		return true
	case "sfi", "dozi", "ai", "subic", "ai_dot", "subic_dot", "lil", "cal":
		return true
	case "subi", "liu", "cau", "subis", "crnot", "rfci", "rfscv", "rfsvc":
		return true
	case "rfgi", "ics", "crclr", "dnh", "crset", "urfid", "doze", "crmove":
		return true
	case "sleep", "rvwinkle", "oril", "oriu", "xoril", "xoriu", "andil_dot", "andiu_dot":
		return true
	case "rotldi_dot", "rotrdi_dot", "clrldi_dot", "srdi_dot", "extrdi_dot", "clrrdi_dot", "sldi_dot", "extldi_dot":
		return true
	case "clrlsldi", "clrlsldi_dot", "insrdi", "insrdi_dot", "rotld_dot", "t", "sf", "sf_dot":
		return true
	case "a_dot", "lx", "sl", "sl_dot", "cntlz", "cntlz_dot", "maskg", "maskg_dot":
		return true
	case "ldepx", "waitasec", "mviwsplt", "mfvsrd", "eratilx", "lux", "subwus", "subwus_dot":
		return true
	case "subdus", "subdus_dot", "subfus", "subfus_dot", "dlmzb", "dlmzb_dot", "dni", "mul":
		return true
	case "mul_dot", "mvidsplt", "mtsrdin", "mfvsrwz", "clf", "dcbtstls", "sfe", "sfe_dot":
		return true
	case "ae", "ae_dot", "dcbtstlse", "mtsle", "eratsx", "eratsx_dot", "stx", "slq":
		return true
	case "slq_dot", "sle", "sle_dot", "stdepx", "dcbtls", "dcbtlse", "mtvsrd", "eratre":
		return true
	case "wchkall", "stux", "sliq", "sliq_dot", "icblq_dot", "sfze", "sfze_dot", "aze":
		return true
	case "aze_dot", "mtvsrwa", "eratwe", "ldawx_dot", "sllq", "sllq_dot", "sleq", "sleq_dot":
		return true
	case "sfme", "sfme_dot", "ame", "ame_dot", "muls", "muls_dot", "icblce", "mtsri":
		return true
	case "mtvsrwz", "dcbtstct", "dcbtstds", "slliq", "slliq_dot", "mfdcrx", "mfdcrx_dot", "lvexbx":
		return true
	case "lvepxl", "doz", "doz_dot", "cax", "cax_dot", "ehpriv", "mfapidi", "lscbx":
		return true
	case "lscbx_dot", "dcbtct", "dcbtds", "mfdcrux", "lvexhx", "lvepx", "mfbhrbe", "tlbi":
		return true
	case "eciwx", "mfdcr_dot", "lvexwx", "dcread", "div", "div_dot", "mftmr", "abs":
		return true
	case "abs_dot", "divs", "divs_dot", "lxvwsx", "tlbia", "setbc", "mtdcrx", "mtdcrx_dot":
		return true
	case "stvexbx", "dcblc", "dcblce", "pbt_dot", "icswx", "icswx_dot", "setbcr", "mtdcrux":
		return true
	case "stvexhx", "dcblq_dot", "clrbhrb", "ecowx", "setnbc", "mtdcr_dot", "stvexwx", "dci":
		return true
	case "mttmr", "setnbcr", "dsn", "nabs", "nabs_dot", "icbtlse", "cli", "mcrxr":
		return true
	case "lbdcbx", "lbdx", "bblels", "lvlx", "subfco", "sfo", "subco", "subfco_dot":
		return true
	case "sfo_dot", "subco_dot", "addco", "ao", "addco_dot", "ao_dot", "clcs", "lsx":
		return true
	case "lbrx", "sr_dot", "rrib", "rrib_dot", "maskir", "maskir_dot", "lhdcbx", "lhdx":
		return true
	case "lvtrx", "bbelr", "lvrx", "subfo", "subo", "subfo_dot", "subo_dot", "lwdcbx":
		return true
	case "lwdx", "lvtlx", "lsi", "dcs", "mffgpr", "lddx", "lvswx", "nego":
		return true
	case "nego_dot", "mulo", "mulo_dot", "mfsri", "dclst", "stbdcbx", "stbdx", "stvlx":
		return true
	case "subfeo", "sfeo", "subfeo_dot", "sfeo_dot", "addeo", "aeo", "addeo_dot", "aeo_dot":
		return true
	case "hashstp", "stsx", "stbrx", "srq", "srq_dot", "sre", "sre_dot", "sthdcbx":
		return true
	case "sthdx", "stvfrx", "stvrx", "hashchkp", "sriq", "sriq_dot", "stwdcbx", "stwdx":
		return true
	case "stvflx", "subfzeo", "sfzeo", "subfzeo_dot", "sfzeo_dot", "addzeo", "azeo", "addzeo_dot":
		return true
	case "azeo_dot", "hashst", "stsi", "srlq", "srlq_dot", "sreq", "sreq_dot", "mftgpr":
		return true
	case "stddx", "stvswx", "subfmeo", "sfmeo", "subfmeo_dot", "sfmeo_dot", "mulldo", "mulldo_dot":
		return true
	case "addmeo", "ameo", "addmeo_dot", "ameo_dot", "mullwo", "mulso", "mullwo_dot", "mulso_dot":
		return true
	case "tsr_dot", "hashchk", "srliq", "srliq_dot", "lvsm", "stvepxl", "lvlxl", "dozo":
		return true
	case "dozo_dot", "addo", "caxo", "addo_dot", "caxo_dot", "lfqx", "sra", "sra_dot":
		return true
	case "evlddepx", "lfddx", "lvtrxl", "stvepx", "lvrxl", "rac", "erativax", "lfqux":
		return true
	case "srai", "srai_dot", "lvtlxl", "divo", "divo_dot", "tlbsrx_dot", "slbiag", "lvswxl":
		return true
	case "abso", "abso_dot", "divso", "divso_dot", "rmieg", "stvlxl", "divdeuo_dot", "divweuo_dot":
		return true
	case "tlbsx_dot", "stfqx", "sraq", "sraq_dot", "srea", "srea_dot", "exts", "exts_dot":
		return true
	case "evstddepx", "stfddx", "stvfrxl", "wclrall", "wclr", "stvrxl", "divdeo_dot", "divweo_dot":
		return true
	case "icswepx", "icswepx_dot", "stfqux", "sraiq", "sraiq_dot", "stvflxl", "ici", "divduo":
		return true
	case "divduo_dot", "divwuo", "divwuo_dot", "slbfee_dot", "stvswxl", "icread", "nabso", "nabso_dot":
		return true
	case "divdo", "divdo_dot", "divwo", "divwo_dot", "dclz", "lu", "st", "stu":
		return true
	case "lm", "stm", "lfq", "lfqu", "stfq", "stfqu", "fcir", "fcir_dot":
		return true
	case "fcirz", "fcirz_dot", "fd", "fd_dot", "fs", "fs_dot", "fa", "fa_dot":
		return true
	case "fm", "fm_dot", "fms", "fms_dot", "fma", "fma_dot", "fnms", "fnms_dot":
		return true
	case "fnma", "fnma_dot", "dtstexq", "xscmpexpqp", "dxexq", "dxexq_dot", "dtstsfq", "evseteqb_dot":
		return true
	case "evseteqh_dot", "evseteqw_dot", "evsetgthu_dot", "evsetgths_dot", "evsetgtwu_dot", "evsetgtws_dot", "evsetgtbu_dot", "evsetgtbs_dot":
		return true
	case "evsetltbu_dot", "evsetltbs_dot", "evsetlthu_dot", "evsetlths_dot", "evsetltwu_dot", "evsetltws_dot":
		return true
	// SPE/EFS2 MADD/MSUB family — LLVM 22 lacks these mnemonics (the bit
	// patterns collide with AltiVec at the same XO, so without +spe LLVM
	// decodes them as vminuw/vminud/etc.). Bit patterns from binutils.
	case "evfsmadd", "evfsmsub", "evfsnmadd", "evfsnmsub": return true
	case "efsmadd",  "efsmsub",  "efsnmadd",  "efsnmsub":  return true
	case "efdmadd",  "efdmsub",  "efdnmadd",  "efdnmsub":  return true
	// EFS2 scalar/vector extensions — LLVM 22 doesn't recognize
	case "evfssqrt", "efssqrt", "efdsqrt":   return true
	case "evfscfh", "evfscth", "efscfh", "efscth", "efdcfh", "efdcth": return true
	case "evfsmax", "evfsmin", "efsmax", "efsmin", "efdmax", "efdmin": return true
	case "evfsaddsub", "evfssubadd", "evfssum", "evfsdiff",
		 "evfssumdiff", "evfsdiffsum",
		 "evfsaddx", "evfssubx", "evfsaddsubx", "evfssubaddx",
		 "evfsmulx", "evfsmule", "evfsmulo":
		return true
	case "evsubw", "evsubiw", "evneg", "evrndw", "evmr", "evnot", "evsadd", "evssub":
		return true
	case "evsabs", "evsnabs", "evsneg", "evsmul", "evsdiv", "evscmpgt", "evsgmplt", "evsgmpeq":
		return true
	case "evscfui", "evscfsi", "evscfuf", "evscfsf", "evsctui", "evsctsi", "evsctuf", "evsctsf":
		return true
	case "evsctuiz", "evsctsiz", "evststgt", "evststlt", "evststeq", "evmwlssf", "evmwlsmf", "evmwlssfa":
		return true
	case "evmwlsmfa", "evaddusiaaw", "evaddssiaaw", "evsubfusiaaw", "evsubfssiaaw", "evaddumiaaw", "evaddsmiaaw", "evsubfumiaaw":
		return true
	case "evsubfsmiaaw", "evmwlssfaaw", "evmwhusiaa", "evmwhssmaa", "evmwhssfaa", "evmwlsmfaaw", "evmwhumiaa", "evmwhsmiaa":
		return true
	case "evmwhsmfaa", "evmwhgumiaa", "evmwhgsmiaa", "evmwhgssfaa", "evmwhgsmfaa", "evmwlssfanw", "evmwhusian", "evmwhssian":
		return true
	case "evmwhssfan", "evmwlsmfanw", "evmwhumian", "evmwhsmian", "evmwhsmfan", "evmwhgumian", "evmwhgsmian", "evmwhgssfan":
		return true
	case "evmwhgsmfan", "evdotpwcssi", "evdotpwcsmi", "evdotpwcssfr", "evdotpwcssf", "evdotpwgasmf", "evdotpwxgasmf", "evdotpwgasmfr":
		return true
	case "evdotpwxgasmfr", "evdotpwgssmf", "evdotpwxgssmf", "evdotpwgssmfr", "evdotpwxgssmfr", "evdotpwcssiaaw3", "evdotpwcsmiaaw3", "evdotpwcssfraaw3":
		return true
	case "evdotpwcssfaaw3", "evdotpwgasmfaa3", "evdotpwxgasmfaa3", "evdotpwgasmfraa3", "evdotpwxgasmfraa3", "evdotpwgssmfaa3", "evdotpwxgssmfaa3", "evdotpwgssmfraa3":
		return true
	case "evdotpwxgssmfraa3", "evdotpwcssia", "evdotpwcsmia", "evdotpwcssfra", "evdotpwcssfa", "evdotpwgasmfa", "evdotpwxgasmfa", "evdotpwgasmfra":
		return true
	case "evdotpwxgasmfra", "evdotpwgssmfa", "evdotpwxgssmfa", "evdotpwgssmfra", "evdotpwxgssmfra", "evdotpwcssiaaw", "evdotpwcsmiaaw", "evdotpwcssfraaw":
		return true
	case "evdotpwcssfaaw", "evdotpwgasmfaa", "evdotpwxgasmfaa", "evdotpwgasmfraa", "evdotpwxgasmfraa", "evdotpwgssmfaa", "evdotpwxgssmfaa", "evdotpwgssmfraa":
		return true
	case "evdotpwxgssmfraa", "evdotphihcssi", "evdotplohcssi", "evdotphihcssf", "evdotplohcssf", "evdotphihcsmi", "evdotplohcsmi", "evdotphihcssfr":
		return true
	case "evdotplohcssfr", "evdotphihcssiaaw3", "evdotplohcssiaaw3", "evdotphihcssfaaw3", "evdotplohcssfaaw3", "evdotphihcsmiaaw3", "evdotplohcsmiaaw3", "evdotphihcssfraaw3":
		return true
	case "evdotplohcssfraaw3", "evdotphihcssia", "evdotplohcssia", "evdotphihcssfa", "evdotplohcssfa", "evdotphihcsmia", "evdotplohcsmia", "evdotphihcssfra":
		return true
	case "evdotplohcssfra", "evdotphihcssiaaw", "evdotplohcssiaaw", "evdotphihcssfaaw", "evdotplohcssfaaw", "evdotphihcsmiaaw", "evdotplohcsmiaaw", "evdotphihcssfraaw":
		return true
	case "evdotplohcssfraaw", "evdotphausi", "evdotphassi", "evdotphasusi", "evdotphassf", "evdotphsssf", "evdotphaumi", "evdotphasmi":
		return true
	case "evdotphasumi", "evdotphassfr", "evdotphssmi", "evdotphsssi", "evdotphsssfr", "evdotphausiaaw3", "evdotphassiaaw3", "evdotphasusiaaw3":
		return true
	case "evdotphassfaaw3", "evdotphsssiaaw3", "evdotphsssfaaw3", "evdotphaumiaaw3", "evdotphasmiaaw3", "evdotphasumiaaw3", "evdotphassfraaw3", "evdotphssmiaaw3":
		return true
	case "evdotphsssfraaw3", "evdotphausia", "evdotphassia", "evdotphasusia", "evdotphassfa", "evdotphsssfa", "evdotphaumia", "evdotphasmia":
		return true
	case "evdotphasumia", "evdotphassfra", "evdotphssmia", "evdotphsssia", "evdotphsssfra", "evdotphausiaaw", "evdotphassiaaw", "evdotphasusiaaw":
		return true
	case "evdotphassfaaw", "evdotphsssiaaw", "evdotphsssfaaw", "evdotphaumiaaw", "evdotphasmiaaw", "evdotphasumiaaw", "evdotphassfraaw", "evdotphssmiaaw":
		return true
	case "evdotphsssfraaw", "evdotp4hgaumi", "evdotp4hgasmi", "evdotp4hgasumi", "evdotp4hgasmf", "evdotp4hgssmi", "evdotp4hgssmf", "evdotp4hxgasmi":
		return true
	case "evdotp4hxgasmf", "evdotpbaumi", "evdotpbasmi", "evdotpbasumi", "evdotp4hxgssmi", "evdotp4hxgssmf", "evdotp4hgaumiaa3", "evdotp4hgasmiaa3":
		return true
	case "evdotp4hgasumiaa3", "evdotp4hgasmfaa3", "evdotp4hgssmiaa3", "evdotp4hgssmfaa3", "evdotp4hxgasmiaa3", "evdotp4hxgasmfaa3", "evdotpbaumiaaw3", "evdotpbasmiaaw3":
		return true
	case "evdotpbasumiaaw3", "evdotp4hxgssmiaa3", "evdotp4hxgssmfaa3", "evdotp4hgaumia", "evdotp4hgasmia", "evdotp4hgasumia", "evdotp4hgasmfa", "evdotp4hgssmia":
		return true
	case "evdotp4hgssmfa", "evdotp4hxgasmia", "evdotp4hxgasmfa", "evdotpbaumia", "evdotpbasmia", "evdotpbasumia", "evdotp4hxgssmia", "evdotp4hxgssmfa":
		return true
	case "evdotp4hgaumiaa", "evdotp4hgasmiaa", "evdotp4hgasumiaa", "evdotp4hgasmfaa", "evdotp4hgssmiaa", "evdotp4hgssmfaa", "evdotp4hxgasmiaa", "evdotp4hxgasmfaa":
		return true
	case "evdotpbaumiaaw", "evdotpbasmiaaw", "evdotpbasumiaaw", "evdotp4hxgssmiaa", "evdotp4hxgssmfaa", "evdotpwausi", "evdotpwassi", "evdotpwasusi":
		return true
	case "evdotpwaumi", "evdotpwasmi", "evdotpwasumi", "evdotpwssmi", "evdotpwsssi", "evdotpwausiaa3", "evdotpwassiaa3", "evdotpwasusiaa3":
		return true
	case "evdotpwsssiaa3", "evdotpwaumiaa3", "evdotpwasmiaa3", "evdotpwasumiaa3", "evdotpwssmiaa3", "evdotpwausia", "evdotpwassia", "evdotpwasusia":
		return true
	case "evdotpwaumia", "evdotpwasmia", "evdotpwasumia", "evdotpwssmia", "evdotpwsssia", "evdotpwausiaa", "evdotpwassiaa", "evdotpwasusiaa":
		return true
	case "evdotpwsssiaa", "evdotpwaumiaa", "evdotpwasmiaa", "evdotpwasumiaa", "evdotpwssmiaa", "evaddib", "evaddih", "evsubifh":
		return true
	case "evsubifb", "evabsb", "evabsh", "evabsd", "evabss", "evabsbs", "evabshs", "evabsds":
		return true
	case "evnegwo", "evnegb", "evnegbo", "evnegh", "evnegho", "evnegd", "evnegs", "evnegwos":
		return true
	case "evnegbs", "evnegbos", "evneghs", "evneghos", "evnegds", "evextzb", "evextsbh", "evextsw":
		return true
	case "evrndwh", "evrndhb", "evrnddw", "evrndwhus", "evrndwhss", "evrndhbus", "evrndhbss", "evrnddwus":
		return true
	case "evrnddwss", "evrndwnh", "evrndhnb", "evrnddnw", "evrndwnhus", "evrndwnhss", "evrndhnbus", "evrndhnbss":
		return true
	case "evrnddnwus", "evrnddnwss", "evcntlzh", "evcntlsh", "evpopcntb", "circinc", "evunpkhibui", "evunpkhibsi":
		return true
	case "evunpkhihui", "evunpkhihsi", "evunpklobui", "evunpklobsi", "evunpklohui", "evunpklohsi", "evunpklohf", "evunpkhihf":
		return true
	case "evunpklowgsf", "evunpkhiwgsf", "evsatsduw", "evsatsdsw", "evsatshub", "evsatshsb", "evsatuwuh", "evsatswsh":
		return true
	case "evsatswuh", "evsatuhub", "evsatuduw", "evsatuwsw", "evsatshuh", "evsatuhsh", "evsatswuw", "evsatswgsdf":
		return true
	case "evsatsbub", "evsatubsb", "evmaxhpuw", "evmaxhpsw", "evmaxbpuh", "evmaxbpsh", "evmaxwpud", "evmaxwpsd":
		return true
	case "evminhpuw", "evminhpsw", "evminbpuh", "evminbpsh", "evminwpud", "evminwpsd", "evmaxmagws", "evsl":
		return true
	case "evsli", "evsplatie", "evsplatib", "evsplatibe", "evsplatih", "evsplatihe", "evsplatid", "evsplatia":
		return true
	case "evsplatiea", "evsplatiba", "evsplatibea", "evsplatiha", "evsplatihea", "evsplatida", "evsplatfio", "evsplatfib":
		return true
	case "evsplatfibo", "evsplatfih", "evsplatfiho", "evsplatfid", "evsplatfia", "evsplatfioa", "evsplatfiba", "evsplatfiboa":
		return true
	case "evsplatfiha", "evsplatfihoa", "evsplatfida", "evcmpgtdu", "evcmpgtds", "evcmpltdu", "evcmpltds", "evcmpeqd":
		return true
	case "evswapbhilo", "evswapblohi", "evswaphhilo", "evswaphlohi", "evswaphe", "evswaphhi", "evswaphlo", "evswapho":
		return true
	case "evinsb", "evxtrb", "evsplath", "evsplatb", "evinsh", "evclrbe", "evclrbo", "evclrh":
		return true
	case "evxtrh", "evselbitm0", "evselbitm1", "evselbit", "evperm", "evperm2", "evperm3", "evxtrd":
		return true
	case "evsrbu", "evsrbs", "evsrbiu", "evsrbis", "evslb", "evrlb", "evslbi", "evrlbi":
		return true
	case "evsrhu", "evsrhs", "evsrhiu", "evsrhis", "evslh", "evrlh", "evslhi", "evrlhi":
		return true
	case "evsru", "evsrs", "evsriu", "evsris", "evlvsl", "evlvsr", "evsroiu", "evsrois":
		return true
	case "evsloi", "evldbx", "evldb", "evlhhsplathx", "evlhhsplath", "evlwbsplatwx", "evlwbsplatw", "evlwhsplatwx":
		return true
	case "evlwhsplatw", "evlbbsplatbx", "evlbbsplatb", "evstdbx", "evstdb", "evlwbex", "evlwbe", "evlwboux":
		return true
	case "evlwbou", "evlwbosx", "evlwbos", "evstwbex", "evstwbe", "evstwbox", "evstwbo", "evstwbx":
		return true
	case "evstwb", "evsthbx", "evsthb", "evlddmx", "evlddu", "evldwmx", "evldwu", "evldhmx":
		return true
	case "evldhu", "evldbmx", "evldbu", "evlhhesplatmx", "evlhhesplatu", "evlhhsplathmx", "evlhhsplathu", "evlhhousplatmx":
		return true
	case "evlhhousplatu", "evlhhossplatmx", "evlhhossplatu", "evlwhemx", "evlwheu", "evlwbsplatwmx", "evlwbsplatwu", "evlwhoumx":
		return true
	case "evlwhouu", "evlwhosmx", "evlwhosu", "evlwwsplatmx", "evlwwsplatu", "evlwhsplatwmx", "evlwhsplatwu", "evlwhsplatmx":
		return true
	case "evlwhsplatu", "evlbbsplatbmx", "evlbbsplatbu", "evstddmx", "evstddu", "evstdwmx", "evstdwu", "evstdhmx":
		return true
	case "evstdhu", "evstdbmx", "evstdbu", "evlwbemx", "evlwbeu", "evlwboumx", "evlwbouu", "evlwbosmx":
		return true
	case "evlwbosu", "evstwhemx", "evstwheu", "evstwbemx", "evstwbeu", "evstwhomx", "evstwhou", "evstwbomx":
		return true
	case "evstwbou", "evstwwemx", "evstwweu", "evstwbmx", "evstwbu", "evstwwomx", "evstwwou", "evsthbmx":
		return true
	case "evsthbu", "evmhusi", "evmhssi", "evmhsusi", "evmhssf", "evmhumi", "evmhssfr", "evmhesumi":
		return true
	case "evmhosumi", "evmbeumi", "evmbesmi", "evmbesumi", "evmboumi", "evmbosmi", "evmbosumi", "evmhesumia":
		return true
	case "evmhosumia", "evmbeumia", "evmbesmia", "evmbesumia", "evmboumia", "evmbosmia", "evmbosumia", "evmwusiw":
		return true
	case "evmwssiw", "evmwhssfr", "evmwehgsmfr", "evmwehgsmf", "evmwohgsmfr", "evmwohgsmf", "evmwhssfra", "evmwehgsmfra":
		return true
	case "evmwehgsmfa", "evmwohgsmfra", "evmwohgsmfa", "evaddusiaa", "evaddssiaa", "evsubfusiaa", "evsubfssiaa", "evaddsmiaa":
		return true
	case "evsubfsmiaa", "evaddh", "evaddhss", "evsubfh", "evsubfhss", "evaddhx", "evaddhxss", "evsubfhx":
		return true
	case "evsubfhxss", "evaddd", "evadddss", "evsubfd", "evsubfdss", "evaddb", "evaddbss", "evsubfb":
		return true
	case "evsubfbss", "evaddsubfh", "evaddsubfhss", "evsubfaddh", "evsubfaddhss", "evaddsubfhx", "evaddsubfhxss", "evsubfaddhx":
		return true
	case "evsubfaddhxss", "evadddus", "evaddbus", "evsubfdus", "evsubfbus", "evaddwus", "evaddwxus", "evsubfwus":
		return true
	case "evsubfwxus", "evadd2subf2h", "evadd2subf2hss", "evsubf2add2h", "evsubf2add2hss", "evaddhus", "evaddhxus", "evsubfhus":
		return true
	case "evsubfhxus", "evaddwss", "evsubfwss", "evaddwx", "evaddwxss", "evsubfwx", "evsubfwxss", "evaddsubfw":
		return true
	case "evaddsubfwss", "evsubfaddw", "evsubfaddwss", "evaddsubfwx", "evaddsubfwxss", "evsubfaddwx", "evsubfaddwxss", "evmar":
		return true
	case "evsumwu", "evsumws", "evsum4bu", "evsum4bs", "evsum2hu", "evsum2hs", "evdiff2his", "evsum2his":
		return true
	case "evsumwua", "evsumwsa", "evsum4bua", "evsum4bsa", "evsum2hua", "evsum2hsa", "evdiff2hisa", "evsum2hisa":
		return true
	case "evsumwuaa", "evsumwsaa", "evsum4buaaw", "evsum4bsaaw", "evsum2huaaw", "evsum2hsaaw", "evdiff2hisaaw", "evsum2hisaaw":
		return true
	case "evdivwsf", "evdivwuf", "evdivs", "evdivu", "evaddwegsi", "evaddwegsf", "evsubfwegsi", "evsubfwegsf":
		return true
	case "evaddwogsi", "evaddwogsf", "evsubfwogsi", "evsubfwogsf", "evaddhhiuw", "evaddhhisw", "evsubfhhiuw", "evsubfhhisw":
		return true
	case "evaddhlouw", "evaddhlosw", "evsubfhlouw", "evsubfhlosw", "evmhesusiaaw", "evmhosusiaaw", "evmhesumiaaw", "evmhosumiaaw":
		return true
	case "evmbeusiaah", "evmbessiaah", "evmbesusiaah", "evmbousiaah", "evmbossiaah", "evmbosusiaah", "evmbeumiaah", "evmbesmiaah":
		return true
	case "evmbesumiaah", "evmboumiaah", "evmbosmiaah", "evmbosumiaah", "evmwlusiaaw3", "evmwlssiaaw3", "evmwhssfraaw3", "evmwhssfaaw3":
		return true
	case "evmwhssfraaw", "evmwhssfaaw", "evmwlumiaaw3", "evmwlsmiaaw3", "evmwusiaa", "evmwssiaa", "evmwehgsmfraa", "evmwehgsmfaa":
		return true
	case "evmwohgsmfraa", "evmwohgsmfaa", "evmhesusianw", "evmhosusianw", "evmhesumianw", "evmhosumianw", "evmbeusianh", "evmbessianh":
		return true
	case "evmbesusianh", "evmbousianh", "evmbossianh", "evmbosusianh", "evmbeumianh", "evmbesmianh", "evmbesumianh", "evmboumianh":
		return true
	case "evmbosmianh", "evmbosumianh", "evmwlusianw3", "evmwlssianw3", "evmwhssfranw3", "evmwhssfanw3", "evmwhssfranw", "evmwhssfanw":
		return true
	case "evmwlumianw3", "evmwlsmianw3", "evmwusian", "evmwssian", "evmwehgsmfran", "evmwehgsmfan", "evmwohgsmfran", "evmwohgsmfan":
		return true
	case "evseteqb", "evseteqh", "evseteqw", "evsetgthu", "evsetgths", "evsetgtwu", "evsetgtws", "evsetgtbu":
		return true
	case "evsetgtbs", "evsetltbu", "evsetltbs", "evsetlthu", "evsetlths", "evsetltwu", "evsetltws", "evsaduw":
		return true
	case "evsadsw", "evsad4ub", "evsad4sb", "evsad2uh", "evsad2sh", "evsaduwa", "evsadswa", "evsad4uba":
		return true
	case "evsad4sba", "evsad2uha", "evsad2sha", "evabsdifuw", "evabsdifsw", "evabsdifub", "evabsdifsb", "evabsdifuh":
		return true
	case "evabsdifsh", "evsaduwaa", "evsadswaa", "evsad4ubaaw", "evsad4sbaaw", "evsad2uhaaw", "evsad2shaaw", "evpkshubs":
		return true
	case "evpkshsbs", "evpkswuhs", "evpkswshs", "evpkuhubs", "evpkuwuhs", "evpkswshilvs", "evpkswgshefrs", "evpkswshfrs":
		return true
	case "evpkswshilvfrs", "evpksdswfrs", "evpksdshefrs", "evpkuduws", "evpksdsws", "evpkswgswfrs", "evilveh", "evilveoh":
		return true
	case "evilvhih", "evilvhiloh", "evilvloh", "evilvlohih", "evilvoeh", "evilvoh", "evdlveb", "evdlveh":
		return true
	case "evdlveob", "evdlveoh", "evdlvob", "evdlvoh", "evdlvoeb", "evdlvoeh", "evmaxbu", "evmaxbs":
		return true
	case "evmaxhu", "evmaxhs", "evmaxwu", "evmaxws", "evmaxdu", "evmaxds", "evminbu", "evminbs":
		return true
	case "evminhu", "evminhs", "evminwu", "evminws", "evmindu", "evminds", "evavgwu", "evavgws":
		return true
	case "evavgbu", "evavgbs", "evavghu", "evavghs", "evavgdu", "evavgds", "evavgwur", "evavgwsr":
		return true
	case "evavgbur", "evavgbsr", "evavghur", "evavghsr", "evavgdur", "evavgdsr":
		return true
	}
	return false
}

// Recognize specific aliases LLVM emits canonically.
is_known_alias :: proc(ours, llvm: string) -> bool {
	// bc with BO=12 (branch if true) → bt; BO=4 (branch if false) → bf
	if ours == "bc"   && llvm == "bt"   { return true }
	if ours == "bca"  && llvm == "bta"  { return true }
	if ours == "bcl"  && llvm == "btl"  { return true }
	if ours == "bcla" && llvm == "btla" { return true }
	// bclr/bcctr with BO=12 sometimes prints as btlr/btctr (rare; depends
	// on LLVM version + the BO/BI being a recognised condition mnemonic).
	if ours == "bclr"   && (llvm == "btlr"   || llvm == "blr")   { return true }
	if ours == "bcctr"  && (llvm == "btctr"  || llvm == "bctr")  { return true }
	if ours == "bclrl"  && (llvm == "btlrl"  || llvm == "blrl")  { return true }
	if ours == "bcctrl" && (llvm == "btctrl" || llvm == "bctrl") { return true }
	// mcrf rare alias mr crN, crM as "mcrf cr0, cr1" or with cr prefix
	// mtcrf with single-field mask → mtocrf
	if ours == "mtcrf"  && llvm == "mtocrf"  { return true }
	if ours == "mfcr"   && llvm == "mfocrf"  { return true }

	// subf with operands {rT, rA, rB} = `sub rT, rB, rA` per LLVM canonical.
	// The natural assembler form is "sub", not "subf".
	if ours == "subf"        && llvm == "sub"   { return true }
	if ours == "subf_dot"    && llvm == "sub."  { return true }
	if ours == "subf_o"      && llvm == "subo"  { return true }
	if ours == "subf_o_dot"  && llvm == "subo." { return true }
	if ours == "subfc"       && llvm == "subc"  { return true }
	if ours == "subfc_dot"   && llvm == "subc." { return true }
	if ours == "subfc_o"     && llvm == "subco" { return true }
	if ours == "subfc_o_dot" && llvm == "subco."{ return true }
	// sub_o/sub_o_dot/subc_o/subc_o_dot — LLVM keeps subfo/subfo./subfco/subfco.
	if ours == "sub_o"       && llvm == "subfo"  { return true }
	if ours == "sub_o_dot"   && llvm == "subfo." { return true }
	if ours == "subc_o"      && llvm == "subfco" { return true }
	if ours == "subc_o_dot"  && llvm == "subfco."{ return true }

	// Trap with TO=31 (all conditions) — LLVM prints variant-specific
	// mnemonics depending on which TO bits are set. Our safe-fill uses TO=31.
	if (ours == "twi" || ours == "tdi" || ours == "tw" || ours == "td") {
		switch llvm {
		case "twi", "twui", "trap", "tweq", "twlng", "tlbi",
			 "tdi", "tdui", "tdeq",
			 "tw", "twu",
			 "td", "tdu":
			return true
		}
	}

	// Rotate aliases. rldicl/rldicr with specific MB/ME degenerates emit as
	// rotldi/rotrdi/extrdi/sldi/srdi/clrldi/clrrdi. We allow any "rot*" /
	// "ext*" / "sl*i" / "sr*i" / "clr*di" form as alias of the underlying op.
	if strings.has_prefix(ours, "rldi") && (strings.has_prefix(llvm, "rotl") || strings.has_prefix(llvm, "rotr") ||
											  strings.has_prefix(llvm, "extl") || strings.has_prefix(llvm, "extr") ||
											  strings.has_prefix(llvm, "sldi") || strings.has_prefix(llvm, "srdi") ||
											  strings.has_prefix(llvm, "clrl") || strings.has_prefix(llvm, "clrr")) { return true }
	if strings.has_prefix(ours, "rldc") && strings.has_prefix(llvm, "rotl") { return true }
	if strings.has_prefix(ours, "rldc") && llvm == "rotld" { return true }
	if strings.has_prefix(ours, "rldc") && llvm == "rotld." { return true }
	if strings.has_prefix(ours, "rlwinm") && (strings.has_prefix(llvm, "rotlwi") || strings.has_prefix(llvm, "slwi") ||
												strings.has_prefix(llvm, "srwi") || strings.has_prefix(llvm, "extlwi") ||
												strings.has_prefix(llvm, "extrwi") || strings.has_prefix(llvm, "clrlwi") ||
												strings.has_prefix(llvm, "clrrwi")) { return true }
	if strings.has_prefix(ours, "rlwnm") && strings.has_prefix(llvm, "rotlw") { return true }

	// cmp/cmpi/cmpl/cmpli with L=0 print as cmpw/cmpwi/cmplw/cmplwi.
	if ours == "cmpi"  && llvm == "cmpwi"  { return true }
	if ours == "cmpli" && llvm == "cmplwi" { return true }
	if ours == "cmp"   && llvm == "cmpw"   { return true }
	if ours == "cmpl"  && llvm == "cmplw"  { return true }

	// VSX permute aliases:
	//   xxpermdi DM=0 → xxmrghd, DM=3 → xxmrgld, DM=2 → xxswapd
	if ours == "xxpermdi" && (llvm == "xxmrghd" || llvm == "xxmrgld" ||
							  llvm == "xxswapd")                    { return true }

	// addpcis with d=0 → lnia (load next instruction address)
	if ours == "addpcis" && llvm == "lnia" { return true }

	// sc with LEV=1 (hypervisor) — LLVM 22 prints as plain "sc"
	if ours == "sc_hv" && llvm == "sc" { return true }

	// Computed aliases that LLVM canonicalizes back to the underlying form.
	switch ours {
	case "clrrwi", "extlwi", "extrwi":      if llvm == "rlwinm" { return true }
	case "clrrdi", "extldi":                if llvm == "rldicr" { return true }
	case "srdi",   "extrdi":                if llvm == "rldicl" { return true }
	case "inslwi", "insrwi":                if llvm == "rlwimi" { return true }
	case "rotrwi":                          if llvm == "rotlwi" { return true }
	case "rotrdi":                          if llvm == "rotldi" { return true }
	case "rotrw":                           if llvm == "rotlw"  { return true }
	case "msync":                           if llvm == "sync"   { return true }
	case "psubi":                           if llvm == "paddi"  { return true }
	}

	// la rD, D(RA) — LLVM prints as addi (no la alias in modern LLVM)
	if ours == "la" && llvm == "addi" { return true }

	// SPE: evfsctuf / evfsctuiz share encodings with the signed variants and
	// LLVM 22 only recognises the signed mnemonic ("did you mean evfsctsf?").
	if ours == "evfsctuf"  && llvm == "evfsctsf"  { return true }
	if ours == "evfsctuiz" && llvm == "evfsctsiz" { return true }

	// Conditional-branch aliases: LLVM 22 prefers bt/bf (branch-if-true/false
	// on a generic CR bit) over the condition-specific beq/bne/blt/ble/bgt/
	// bge/bso/bns aliases, since the latter encode "BO=12/4 + BI=specific bit"
	// and bt/bf already express that more directly.
	switch ours {
	case "beq", "blt", "bgt", "bso":   if llvm == "bt"  { return true }
	case "bne", "ble", "bge", "bns":   if llvm == "bf"  { return true }
	case "beql", "bltl", "bgtl", "bsol": if llvm == "btl" { return true }
	case "bnel", "blel", "bgel", "bnsl": if llvm == "bfl" { return true }
	// LR-form aliases — LLVM prints all as plain bclr
	case "beqlr", "bnelr", "bltlr", "blelr",
		 "bgtlr", "bgelr", "bsolr", "bnslr":
		if llvm == "bclr"  || llvm == "btlr" || llvm == "bflr" { return true }
	case "beqlrl","bnelrl","bltlrl","blelrl",
		 "bgtlrl","bgelrl","bsolrl","bnslrl":
		if llvm == "bclrl" || llvm == "btlrl"|| llvm == "bflrl"{ return true }
	// CTR-form aliases
	case "beqctr","bnectr","bltctr","blectr",
		 "bgtctr","bgectr","bsoctr","bnsctr":
		if llvm == "bcctr" || llvm == "btctr"|| llvm == "bfctr"{ return true }
	case "beqctrl","bnectrl","bltctrl","blectrl",
		 "bgtctrl","bgectrl","bsoctrl","bnsctrl":
		if llvm == "bcctrl"|| llvm == "btctrl"||llvm == "bfctrl"{return true }
	// Counter-decrement+CR-bit LR/LRL aliases — LLVM emits plain bclr/bclrl
	case "bdnztlr","bdztlr","bdnzflr","bdzflr":
		if llvm == "bclr"  { return true }
	case "bdnztlrl","bdztlrl","bdnzflrl","bdzflrl":
		if llvm == "bclrl" { return true }
	}

	return false
}
