// ELF64 relocatable object writer for x86-64 and arm64, with .eh_frame. The DWARF sections
// come from xb_dwarf.cpp.

enum : u32 {
	XB_R_X86_64_64            = 1,
	XB_R_X86_64_PC32          = 2,
	XB_R_X86_64_PLT32         = 4,
	XB_R_X86_64_GOTPCREL      = 9,
	XB_R_X86_64_32            = 10,
	XB_R_X86_64_DTPOFF64      = 17,
	XB_R_X86_64_TLSGD         = 19,
	XB_R_X86_64_GOTTPOFF      = 22,
	XB_R_X86_64_TPOFF32       = 23,
	XB_R_X86_64_GOTPCRELX     = 41,
	XB_R_X86_64_REX_GOTPCRELX = 42,

	XB_R_AARCH64_ABS64                       = 257,
	XB_R_AARCH64_ABS32                       = 258,
	XB_R_AARCH64_PREL32                      = 261,
	XB_R_AARCH64_ADR_PREL_PG_HI21            = 275,
	XB_R_AARCH64_ADD_ABS_LO12_NC             = 277,
	XB_R_AARCH64_CALL26                      = 283,
	XB_R_AARCH64_ADR_GOT_PAGE                = 311,
	XB_R_AARCH64_LD64_GOT_LO12_NC            = 312,
	XB_R_AARCH64_TLSIE_ADR_GOTTPREL_PAGE21   = 541,
	XB_R_AARCH64_TLSIE_LD64_GOTTPREL_LO12_NC = 542,
	XB_R_AARCH64_TLSDESC_ADR_PAGE21          = 562,
	XB_R_AARCH64_TLSDESC_LD64_LO12           = 563,
	XB_R_AARCH64_TLSDESC_ADD_LO12            = 564,
	XB_R_AARCH64_TLSDESC_CALL                = 569,
};

// DW_CFA_offset of a register saved at cfa-8*n, for registers past the 6 bit short form too
gb_internal void xb_cfa_offset(Array<u8> *b, u32 reg, u64 n) {
	if (reg < 64) {
		xbb_u8(b, cast(u8)(0x80 | reg));
	} else {
		xbb_u8(b, 0x05); // offset_extended
		xbb_uleb(b, reg);
	}
	xbb_uleb(b, n);
}

// DW_CFA_advance_loc by `delta` code alignment units
gb_internal void xb_cfa_advance(Array<u8> *b, u32 delta) {
	if (delta < 64) {
		xbb_u8(b, cast(u8)(0x40 | delta));
	} else {
		xbb_u8(b, 0x03); xbb_u8(b, cast(u8)delta); xbb_u8(b, cast(u8)(delta >> 8)); // advance_loc2
	}
}

struct xbBuf {
	Array<u8> data;
};

// relocations for the sections this file builds (debug info, eh_frame)
struct xbExtraReloc {
	i64 offset;
	i32 sym_section; // a section symbol, by output section index
	u32 type;
	i64 addend;
};

// a relocation in .debug_info against one of the module's symbols
struct xbSymReloc {
	i64 offset;
	i32 sym;
	u32 type;
};

enum xbOutSection {
	xbOut_Null,
	xbOut_Text,
	xbOut_Rodata,
	xbOut_Data,
	xbOut_Bss,
	xbOut_TData,
	xbOut_TBss,
	xbOut_EhFrame,
	xbOut_DebugAbbrev,
	xbOut_DebugInfo,
	xbOut_DebugLine,
	xbOut_DebugRanges,
	xbOut_DebugGdbScripts,
	xbOut_NoteStack,
	xbOut_RelaText,
	xbOut_RelaData,
	xbOut_RelaRodata,
	xbOut_RelaTData,
	xbOut_RelaEhFrame,
	xbOut_RelaDebugInfo,
	xbOut_RelaDebugLine,
	xbOut_Symtab,
	xbOut_Strtab,
	xbOut_Shstrtab,
	xbOut_COUNT,
};

////////////////////////////////////////////////////////////////
// Object file
////////////////////////////////////////////////////////////////

struct xbElfShdr {
	u32 sh_name;
	u32 sh_type;
	u64 sh_flags;
	u64 sh_addr;
	u64 sh_offset;
	u64 sh_size;
	u32 sh_link;
	u32 sh_info;
	u64 sh_addralign;
	u64 sh_entsize;
};

struct xbElfSym {
	u32 st_name;
	u8  st_info;
	u8  st_other;
	u16 st_shndx;
	u64 st_value;
	u64 st_size;
};

struct xbElfRela {
	u64 r_offset;
	u64 r_info;
	i64 r_addend;
};

gb_internal bool xb_write_object(xbModule *m, String path) {
	Array<u8> sec[xbOut_COUNT] = {};
	for (isize i = 0; i < xbOut_COUNT; i++) {
		sec[i] = array_make<u8>(heap_allocator(), 0, 0);
	}
	auto extra_relocs = array_make<xbExtraReloc>(heap_allocator(), 0, 256);   // .eh_frame
	auto info_relocs  = array_make<xbExtraReloc>(heap_allocator(), 0, 256);   // .debug_info
	auto line_relocs  = array_make<xbExtraReloc>(heap_allocator(), 0, 256);   // .debug_line
	auto info_sym_relocs = array_make<xbSymReloc>(heap_allocator(), 0, 256); // .debug_info

	array_add_elems(&sec[xbOut_Text], m->sections[xbSection_Text].data, m->sections[xbSection_Text].count);
	array_add_elems(&sec[xbOut_Rodata], m->sections[xbSection_Rodata].data, m->sections[xbSection_Rodata].count);
	array_add_elems(&sec[xbOut_Data], m->sections[xbSection_Data].data, m->sections[xbSection_Data].count);
	array_add_elems(&sec[xbOut_TData], m->sections[xbSection_TData].data, m->sections[xbSection_TData].count);

	bool arm64 = xb_is_arm64();
	u32 const r_abs64 = arm64 ? XB_R_AARCH64_ABS64  : XB_R_X86_64_64;
	u32 const r_abs32 = arm64 ? XB_R_AARCH64_ABS32  : XB_R_X86_64_32;
	u32 const r_pc32  = arm64 ? XB_R_AARCH64_PREL32 : XB_R_X86_64_PC32;

	// .eh_frame
	{
		Array<u8> *b = &sec[xbOut_EhFrame];
		isize cie_start = b->count;
		xbb_u32(b, 0); // length
		xbb_u32(b, 0); // CIE id
		xbb_u8(b, 1);  // version
		xbb_cstr(b, "zR");
		xbb_uleb(b, arm64 ? 4 : 1);   // code alignment
		xbb_sleb(b, -8);              // data alignment
		xbb_uleb(b, arm64 ? 30 : 16); // return address register
		xbb_uleb(b, 1);  // augmentation data length
		xbb_u8(b, 0x1b); // FDE pointers: pcrel sdata4
		if (arm64) {
			xbb_u8(b, 0x0c); xbb_uleb(b, 31); xbb_uleb(b, 0); // def_cfa sp+0, the return address stays in x30
		} else {
			xbb_u8(b, 0x0c); xbb_uleb(b, 7); xbb_uleb(b, 8); // def_cfa rsp+8
			xb_cfa_offset(b, 16, 1);                         // rip at cfa-8
		}
		xbb_align(b, 8);
		xbb_patch_u32(b, cie_start, cast(u32)(b->count - cie_start - 4));

		for (xbProcDebug const &pd : m->proc_debug) {
			isize fde_start = b->count;
			xbb_u32(b, 0);
			xbb_u32(b, cast(u32)(b->count - cie_start)); // CIE pointer
			xbExtraReloc r = {b->count, xbOut_Text, r_pc32, pd.start};
			array_add(&extra_relocs, r);
			xbb_u32(b, 0); // pc begin
			xbb_u32(b, cast(u32)(pd.end - pd.start));
			xbb_uleb(b, 0); // augmentation data length
			if (pd.naked) {
				// no frame, the cie's rsp+8 holds throughout
				xbb_align(b, 8);
				xbb_patch_u32(b, fde_start, cast(u32)(b->count - fde_start - 4));
				continue;
			}
			if (arm64) {
				xb_cfa_advance(b, 1);                   // stp x29, x30, [sp, #-16]!
				xbb_u8(b, 0x0e); xbb_uleb(b, 16);       // def_cfa_offset 16
				xb_cfa_offset(b, 29, 2);                // x29 at cfa-16
				xb_cfa_offset(b, 30, 1);                // x30 at cfa-8
				xb_cfa_advance(b, 1);                   // mov x29, sp
				xbb_u8(b, 0x0c); xbb_uleb(b, 29); xbb_uleb(b, 16); // def_cfa x29+16
			} else {
				xb_cfa_advance(b, 1);                   // push rbp
				xbb_u8(b, 0x0e); xbb_uleb(b, 16);       // def_cfa_offset 16
				xb_cfa_offset(b, 6, 2);                 // rbp at cfa-16
				xb_cfa_advance(b, 3);                   // mov rbp, rsp
				xbb_u8(b, 0x0d); xbb_uleb(b, 6);        // def_cfa_register rbp
			}
			if (pd.saved_regs.count > 0) {
				// after the saves, counted from the end of the frame setup
				xb_cfa_advance(b, arm64 ? cast(u32)(pd.saved_at - 8) / 4 : cast(u32)(pd.saved_at - 4));
				for (auto const &s : pd.saved_regs) {
					// saved at fp+off, the cfa is fp+16
					xb_cfa_offset(b, cast(u32)s.dwarf_reg, cast(u64)((16 - s.frame_offset) / 8));
				}
			}
			xbb_align(b, 8);
			xbb_patch_u32(b, fde_start, cast(u32)(b->count - fde_start - 4));
		}
	}

	bool debug = build_context.ODIN_DEBUG;
	if (debug) {
		xbDwarf d = {};
		xb_dwarf_build(m, &d);
		sec[xbOut_DebugAbbrev] = d.abbrev;
		sec[xbOut_DebugInfo] = d.info;
		sec[xbOut_DebugLine] = d.line;
		sec[xbOut_DebugRanges] = d.ranges;
		xbExtraReloc ra = {d.abbrev_offset_at, xbOut_DebugAbbrev, r_abs32, 0};
		xbExtraReloc rs = {d.stmt_list_at, xbOut_DebugLine, r_abs32, 0};
		array_add(&info_relocs, ra);
		array_add(&info_relocs, rs);
		for (isize at : d.ranges_refs) {
			u32 off = 0;
			gb_memmove(&off, d.info.data + at, 4);
			xbExtraReloc r = {at, xbOut_DebugRanges, r_abs32, off};
			array_add(&info_relocs, r);
		}
		for (xbDwarfAddr const &a : d.info_addrs) {
			if (a.sym < 0) {
				xbExtraReloc r = {a.offset, xbOut_Text, r_abs64, a.addend};
				array_add(&info_relocs, r);
			} else {
				bool tls = (m->symbols[a.sym].flags & xbSymbolFlag_TLS) != 0;
				GB_ASSERT(!tls || !arm64);
				xbSymReloc r = {a.offset, a.sym, tls ? XB_R_X86_64_DTPOFF64 : r_abs64};
				array_add(&info_sym_relocs, r);
			}
		}
		for (xbDwarfAddr const &a : d.line_addrs) {
			xbExtraReloc r = {a.offset, xbOut_Text, r_abs64, a.addend};
			array_add(&line_relocs, r);
		}
	}

	// the gdb pretty printers, the same entry LLVM writes (see `debug_gdb_scripts` in llvm_backend.cpp), so the linker merges the two
	if (debug) {
		String script_path = concatenate_strings(temporary_allocator(), odin_root_dir(), str_lit("base/runtime/odin_debugger.py"));
		gbFileContents fc = gb_file_read_contents(heap_allocator(), false, alloc_cstring(temporary_allocator(), script_path));
		if (fc.data != nullptr) {
			Array<u8> *b = &sec[xbOut_DebugGdbScripts];
			xbb_u8(b, 4); // an entry of kind 4 is the script's name, a newline, then its text
			xbb_bytes(b, "odin_debugger.py\n", 17);
			for (isize i = 0; i < fc.size; i++) {
				u8 c = (cast(u8 *)fc.data)[i];
				if (c != '\r') xbb_u8(b, c);
			}
			xbb_u8(b, 0);
			gb_file_free_contents(&fc);
		}
	}

	// symbols: null, section symbols, then globals
	auto strtab = array_make<u8>(heap_allocator(), 0, 4096);
	xbb_u8(&strtab, 0);
	auto syms = array_make<xbElfSym>(heap_allocator(), 0, m->symbols.count + 16);
	xbElfSym null_sym = {};
	array_add(&syms, null_sym);

	i32 section_sym[xbOut_COUNT] = {};
	xbOutSection sym_sections[] = {xbOut_Text, xbOut_Rodata, xbOut_Data, xbOut_Bss, xbOut_TData, xbOut_TBss, xbOut_EhFrame, xbOut_DebugAbbrev, xbOut_DebugInfo, xbOut_DebugLine, xbOut_DebugRanges};
	for (xbOutSection s : sym_sections) {
		xbElfSym es = {};
		es.st_info = (0 << 4) | 3; // local, section
		es.st_shndx = cast(u16)s;
		section_sym[s] = cast(i32)syms.count;
		array_add(&syms, es);
	}
	u32 first_global = cast(u32)syms.count;

	auto out_section_of = [](xbSection s) -> xbOutSection {
		switch (s) {
		case xbSection_Text:   return xbOut_Text;
		case xbSection_Rodata: return xbOut_Rodata;
		case xbSection_Data:   return xbOut_Data;
		case xbSection_Bss:    return xbOut_Bss;
		case xbSection_TData:  return xbOut_TData;
		case xbSection_TBss:   return xbOut_TBss;
		}
		return xbOut_Null;
	};

	auto sym_index = array_make<i32>(heap_allocator(), m->symbols.count);
	for_array(i, m->symbols) {
		xbSymbol const &s = m->symbols[i];
		sym_index[i] = -1;
		bool is_local = (s.flags & xbSymbolFlag_Global) == 0;
		if (is_local) {
			continue; // referenced through its section symbol
		}
		xbElfSym es = {};
		es.st_name = cast(u32)strtab.count;
		xbb_str(&strtab, s.name);
		u8 bind = (s.flags & xbSymbolFlag_Weak) ? 2 : 1;
		u8 type = (s.flags & xbSymbolFlag_TLS) ? 6 : 0;
		if (s.section != xbSection_Undef) {
			type = (s.flags & xbSymbolFlag_Func) ? 2 : (s.flags & xbSymbolFlag_TLS) ? 6 : 1;
			es.st_shndx = cast(u16)out_section_of(s.section);
			es.st_value = cast(u64)s.offset;
			es.st_size = cast(u64)s.size;
			if (s.flags & xbSymbolFlag_Hidden) {
				es.st_other = 2; // STV_HIDDEN
			}
		}
		es.st_info = cast(u8)((bind << 4) | type);
		sym_index[i] = cast(i32)syms.count;
		array_add(&syms, es);
	}

	// relocations
	auto rela_for = [&](xbOutSection target) -> Array<u8> * {
		switch (target) {
		case xbOut_Text:      return &sec[xbOut_RelaText];
		case xbOut_Data:      return &sec[xbOut_RelaData];
		case xbOut_Rodata:    return &sec[xbOut_RelaRodata];
		case xbOut_TData:     return &sec[xbOut_RelaTData];
		case xbOut_EhFrame:   return &sec[xbOut_RelaEhFrame];
		case xbOut_DebugInfo: return &sec[xbOut_RelaDebugInfo];
		case xbOut_DebugLine: return &sec[xbOut_RelaDebugLine];
		}
		GB_PANIC("bad rela");
		return nullptr;
	};
	for (xbReloc const &r : m->relocs) {
		xbSymbol const &s = m->symbols[r.sym];
		u32 elf_sym = 0;
		i64 addend = r.addend;
		if (sym_index[r.sym] >= 0) {
			elf_sym = cast(u32)sym_index[r.sym];
		} else {
			GB_ASSERT(s.section != xbSection_Undef);
			elf_sym = cast(u32)section_sym[out_section_of(s.section)];
			addend += s.offset;
		}
		u32 type = 0;
		switch (r.kind) {
		case xbReloc_PC32:          type = XB_R_X86_64_PC32; break;
		case xbReloc_PLT32:         type = XB_R_X86_64_PLT32; break;
		case xbReloc_GOTPCRELX:     type = XB_R_X86_64_GOTPCRELX; break;
		case xbReloc_REX_GOTPCRELX: type = XB_R_X86_64_REX_GOTPCRELX; break;
		case xbReloc_Abs64:         type = XB_R_X86_64_64; break;
		case xbReloc_Abs32:         type = XB_R_X86_64_32; break;
		case xbReloc_TPOFF32:       type = XB_R_X86_64_TPOFF32; break;
		case xbReloc_GOTTPOFF:      type = XB_R_X86_64_GOTTPOFF; break;
		case xbReloc_TLSGD:         type = XB_R_X86_64_TLSGD; break;
		case xbReloc_A64_Branch26:      type = XB_R_AARCH64_CALL26; break;
		case xbReloc_A64_Page21:        type = XB_R_AARCH64_ADR_PREL_PG_HI21; break;
		case xbReloc_A64_PageOff12:     type = XB_R_AARCH64_ADD_ABS_LO12_NC; break;
		case xbReloc_A64_GotPage21:     type = XB_R_AARCH64_ADR_GOT_PAGE; break;
		case xbReloc_A64_GotPageOff12:  type = XB_R_AARCH64_LD64_GOT_LO12_NC; break;
		case xbReloc_A64_TlsIePage21:   type = XB_R_AARCH64_TLSIE_ADR_GOTTPREL_PAGE21; break;
		case xbReloc_A64_TlsIeLo12:     type = XB_R_AARCH64_TLSIE_LD64_GOTTPREL_LO12_NC; break;
		case xbReloc_A64_TlsDescPage21: type = XB_R_AARCH64_TLSDESC_ADR_PAGE21; break;
		case xbReloc_A64_TlsDescLd:     type = XB_R_AARCH64_TLSDESC_LD64_LO12; break;
		case xbReloc_A64_TlsDescAdd:    type = XB_R_AARCH64_TLSDESC_ADD_LO12; break;
		case xbReloc_A64_TlsDescCall:   type = XB_R_AARCH64_TLSDESC_CALL; break;
		}
		if (arm64 && r.kind == xbReloc_Abs64) type = XB_R_AARCH64_ABS64;
		GB_ASSERT_MSG(type != 0, "relocation kind %d has no ELF form", r.kind);
		xbElfRela er = {};
		er.r_offset = cast(u64)r.offset;
		er.r_info = (cast(u64)elf_sym << 32) | type;
		er.r_addend = addend;
		xbb_bytes(rela_for(out_section_of(r.section)), &er, gb_size_of(er));
	}
	auto add_extra = [&](xbOutSection target, Array<xbExtraReloc> const &rs) {
		for (xbExtraReloc const &r : rs) {
			xbElfRela er = {};
			er.r_offset = cast(u64)r.offset;
			er.r_info = (cast(u64)section_sym[r.sym_section] << 32) | r.type;
			er.r_addend = r.addend;
			xbb_bytes(rela_for(target), &er, gb_size_of(er));
		}
	};
	add_extra(xbOut_EhFrame, extra_relocs);
	add_extra(xbOut_DebugInfo, info_relocs);
	add_extra(xbOut_DebugLine, line_relocs);
	for (xbSymReloc const &r : info_sym_relocs) {
		xbSymbol const &s = m->symbols[r.sym];
		xbElfRela er = {};
		er.r_offset = cast(u64)r.offset;
		if (sym_index[r.sym] >= 0) {
			er.r_info = (cast(u64)sym_index[r.sym] << 32) | r.type;
		} else {
			er.r_info = (cast(u64)section_sym[out_section_of(s.section)] << 32) | r.type;
			er.r_addend = s.offset;
		}
		xbb_bytes(&sec[xbOut_RelaDebugInfo], &er, gb_size_of(er));
	}

	for (xbElfSym const &es : syms) {
		xbb_bytes(&sec[xbOut_Symtab], &es, gb_size_of(es));
	}
	sec[xbOut_Strtab] = strtab;

	// section headers
	char const *names[xbOut_COUNT] = {
		"", ".text", ".rodata", ".data", ".bss", ".tdata", ".tbss", ".eh_frame", ".debug_abbrev", ".debug_info", ".debug_line", ".debug_ranges", ".debug_gdb_scripts",
		".note.GNU-stack", ".rela.text", ".rela.data", ".rela.rodata", ".rela.tdata", ".rela.eh_frame",
		".rela.debug_info", ".rela.debug_line", ".symtab", ".strtab", ".shstrtab",
	};
	u32 name_off[xbOut_COUNT] = {};
	Array<u8> *shstr = &sec[xbOut_Shstrtab];
	for (isize i = 0; i < xbOut_COUNT; i++) {
		name_off[i] = cast(u32)shstr->count;
		xbb_cstr(shstr, names[i]);
	}

	xbElfShdr sh[xbOut_COUNT] = {};
	auto set = [&](xbOutSection s, u32 type, u64 flags, u64 align, u64 entsize=0, u32 link=0, u32 info=0) {
		sh[s].sh_name = name_off[s];
		sh[s].sh_type = type;
		sh[s].sh_flags = flags;
		sh[s].sh_addralign = align;
		sh[s].sh_entsize = entsize;
		sh[s].sh_link = link;
		sh[s].sh_info = info;
	};
	u64 const SHF_WRITE = 1, SHF_ALLOC = 2, SHF_EXEC = 4, SHF_MERGE = 0x10, SHF_STRINGS = 0x20, SHF_INFO_LINK = 0x40, SHF_TLS = 0x400;
	u32 const SHT_PROGBITS = 1, SHT_SYMTAB = 2, SHT_STRTAB = 3, SHT_RELA = 4, SHT_NOBITS = 8;
	auto align_of = [&](xbSection s) -> u64 { return cast(u64)gb_max(m->section_align[s], cast(i64)16); };
	set(xbOut_Text,        SHT_PROGBITS, SHF_ALLOC|SHF_EXEC, align_of(xbSection_Text));
	set(xbOut_Rodata,      SHT_PROGBITS, SHF_ALLOC, align_of(xbSection_Rodata));
	set(xbOut_Data,        SHT_PROGBITS, SHF_ALLOC|SHF_WRITE, align_of(xbSection_Data));
	set(xbOut_Bss,         SHT_NOBITS,   SHF_ALLOC|SHF_WRITE, align_of(xbSection_Bss));
	set(xbOut_TData,       SHT_PROGBITS, SHF_ALLOC|SHF_WRITE|SHF_TLS, align_of(xbSection_TData));
	set(xbOut_TBss,        SHT_NOBITS,   SHF_ALLOC|SHF_WRITE|SHF_TLS, align_of(xbSection_TBss));
	set(xbOut_EhFrame,     SHT_PROGBITS, SHF_ALLOC, 8);
	set(xbOut_DebugAbbrev, SHT_PROGBITS, 0, 1);
	set(xbOut_DebugInfo,   SHT_PROGBITS, 0, 1);
	set(xbOut_DebugLine,   SHT_PROGBITS, 0, 1);
	set(xbOut_DebugRanges, SHT_PROGBITS, 0, 1);
	set(xbOut_DebugGdbScripts, SHT_PROGBITS, SHF_MERGE|SHF_STRINGS, 1, 1);
	set(xbOut_NoteStack,   SHT_PROGBITS, 0, 1);
	set(xbOut_RelaText,      SHT_RELA, SHF_INFO_LINK, 8, 24, xbOut_Symtab, xbOut_Text);
	set(xbOut_RelaData,      SHT_RELA, SHF_INFO_LINK, 8, 24, xbOut_Symtab, xbOut_Data);
	set(xbOut_RelaRodata,    SHT_RELA, SHF_INFO_LINK, 8, 24, xbOut_Symtab, xbOut_Rodata);
	set(xbOut_RelaTData,     SHT_RELA, SHF_INFO_LINK, 8, 24, xbOut_Symtab, xbOut_TData);
	set(xbOut_RelaEhFrame,   SHT_RELA, SHF_INFO_LINK, 8, 24, xbOut_Symtab, xbOut_EhFrame);
	set(xbOut_RelaDebugInfo, SHT_RELA, SHF_INFO_LINK, 8, 24, xbOut_Symtab, xbOut_DebugInfo);
	set(xbOut_RelaDebugLine, SHT_RELA, SHF_INFO_LINK, 8, 24, xbOut_Symtab, xbOut_DebugLine);
	set(xbOut_Symtab,   SHT_SYMTAB, 0, 8, 24, xbOut_Strtab, first_global);
	set(xbOut_Strtab,   SHT_STRTAB, 0, 1);
	set(xbOut_Shstrtab, SHT_STRTAB, 0, 1);

	// layout: header, section data, section headers
	auto out = array_make<u8>(heap_allocator(), 0, 64 + m->sections[xbSection_Text].count*2);
	out.count = 64;
	gb_zero_size(out.data, 64);
	for (isize i = 1; i < xbOut_COUNT; i++) {
		xbb_align(&out, cast(isize)gb_max(sh[i].sh_addralign, cast(u64)1));
		sh[i].sh_offset = cast(u64)out.count;
		sh[i].sh_size = cast(u64)sec[i].count;
		xbb_bytes(&out, sec[i].data, sec[i].count);
		if (i == xbOut_Bss)  sh[i].sh_size = cast(u64)m->nobits_size[xbSection_Bss];
		if (i == xbOut_TBss) sh[i].sh_size = cast(u64)m->nobits_size[xbSection_TBss];
	}
	xbb_align(&out, 8);
	u64 shoff = cast(u64)out.count;
	xbb_bytes(&out, sh, gb_size_of(sh));

	u8 *h = out.data;
	h[0] = 0x7f; h[1] = 'E'; h[2] = 'L'; h[3] = 'F';
	h[4] = 2; // 64 bit
	h[5] = 1; // little endian
	h[6] = 1; // version
	h[7] = 0; // System V
	u16 e_type = 1;      // relocatable
	u16 e_machine = arm64 ? 183 : 62; // aarch64 or x86-64
	u32 e_version = 1;
	u64 zero = 0;
	u16 e_ehsize = 64;
	u16 e_shentsize = gb_size_of(xbElfShdr);
	u16 e_shnum = xbOut_COUNT;
	u16 e_shstrndx = xbOut_Shstrtab;
	gb_memmove(h + 16, &e_type, 2);
	gb_memmove(h + 18, &e_machine, 2);
	gb_memmove(h + 20, &e_version, 4);
	gb_memmove(h + 24, &zero, 8); // entry
	gb_memmove(h + 32, &zero, 8); // phoff
	gb_memmove(h + 40, &shoff, 8);
	gb_memmove(h + 52, &e_ehsize, 2);
	gb_memmove(h + 58, &e_shentsize, 2);
	gb_memmove(h + 60, &e_shnum, 2);
	gb_memmove(h + 62, &e_shstrndx, 2);

	gbFile f = {};
	char const *cpath = alloc_cstring(temporary_allocator(), path);
	if (gb_file_create(&f, cpath) != gbFileError_None) {
		gb_printf_err("fast backend: failed to create %s\n", cpath);
		return false;
	}
	gb_file_write(&f, out.data, out.count);
	gb_file_close(&f);
	return true;
}
