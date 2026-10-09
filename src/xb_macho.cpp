// Mach-O relocatable object writer for macOS, arm64 and x86-64.
//
// All sections live in one unnamed segment, as in the objects clang writes. A section's
// file offset mirrors its address, so `offset - fileoff == addr`.
//
// Thread locals follow the TLV scheme: the symbol names a descriptor in __thread_vars,
// which points at `__tlv_bootstrap` and at the initial value, the `$tlv$init` symbol.

enum : u32 {
	MACHO_MH_MAGIC_64       = 0xfeedfacf,
	MACHO_CPU_TYPE_ARM64    = 0x0100000c,
	MACHO_CPU_TYPE_X86_64   = 0x01000007,
	MACHO_CPU_SUBTYPE_X86_64_ALL = 3,
	MACHO_MH_OBJECT         = 1,
	MACHO_MH_SUBSECTIONS_VIA_SYMBOLS = 0x2000,

	MACHO_LC_SYMTAB         = 0x2,
	MACHO_LC_DYSYMTAB       = 0xb,
	MACHO_LC_SEGMENT_64     = 0x19,
	MACHO_LC_BUILD_VERSION  = 0x32,
	MACHO_PLATFORM_MACOS    = 1,

	MACHO_S_REGULAR                    = 0x0,
	MACHO_S_ZEROFILL                   = 0x1,
	MACHO_S_THREAD_LOCAL_REGULAR       = 0x11,
	MACHO_S_THREAD_LOCAL_ZEROFILL      = 0x12,
	MACHO_S_THREAD_LOCAL_VARIABLES     = 0x13,
	MACHO_S_ATTR_PURE_INSTRUCTIONS     = 0x80000000,
	MACHO_S_ATTR_SOME_INSTRUCTIONS     = 0x00000400,
	MACHO_S_ATTR_DEBUG                 = 0x02000000,

	MACHO_RELOC_UNSIGNED                  = 0, // the same number on both
	MACHO_ARM64_RELOC_BRANCH26            = 2,
	MACHO_ARM64_RELOC_PAGE21              = 3,
	MACHO_ARM64_RELOC_PAGEOFF12           = 4,
	MACHO_ARM64_RELOC_GOT_LOAD_PAGE21     = 5,
	MACHO_ARM64_RELOC_GOT_LOAD_PAGEOFF12  = 6,
	MACHO_ARM64_RELOC_TLVP_LOAD_PAGE21    = 8,
	MACHO_ARM64_RELOC_TLVP_LOAD_PAGEOFF12 = 9,

	MACHO_X86_64_RELOC_SIGNED   = 1,
	MACHO_X86_64_RELOC_BRANCH   = 2,
	MACHO_X86_64_RELOC_GOT_LOAD = 3,
	MACHO_X86_64_RELOC_SIGNED_1 = 6, // SIGNED_n: n immediate bytes follow the field
	MACHO_X86_64_RELOC_SIGNED_2 = 7,
	MACHO_X86_64_RELOC_SIGNED_4 = 8,
	MACHO_X86_64_RELOC_TLV      = 9,

	MACHO_UNWIND_ARM64_MODE_FRAME  = 0x04000000,
	MACHO_UNWIND_X86_64_MODE_RBP_FRAME = 0x01000000,
	MACHO_UNWIND_X86_64_MODE_STACK_IMMD = 0x02000000,
};

enum : u8 {
	MACHO_N_UNDF = 0x0,
	MACHO_N_EXT  = 0x01,
	MACHO_N_SECT = 0x0e,
	MACHO_N_PEXT = 0x10,
};

enum : u16 {
	MACHO_N_WEAK_DEF = 0x80,
};

struct machoHeader {
	u32 magic;
	u32 cputype;
	u32 cpusubtype;
	u32 filetype;
	u32 ncmds;
	u32 sizeofcmds;
	u32 flags;
	u32 reserved;
};

struct machoSegmentCommand {
	u32  cmd;
	u32  cmdsize;
	char segname[16];
	u64  vmaddr;
	u64  vmsize;
	u64  fileoff;
	u64  filesize;
	u32  maxprot;
	u32  initprot;
	u32  nsects;
	u32  flags;
};

struct machoSection {
	char sectname[16];
	char segname[16];
	u64  addr;
	u64  size;
	u32  offset;
	u32  align;
	u32  reloff;
	u32  nreloc;
	u32  flags;
	u32  reserved1;
	u32  reserved2;
	u32  reserved3;
};

struct machoBuildVersion {
	u32 cmd;
	u32 cmdsize;
	u32 platform;
	u32 minos;
	u32 sdk;
	u32 ntools;
};

struct machoSymtabCommand {
	u32 cmd;
	u32 cmdsize;
	u32 symoff;
	u32 nsyms;
	u32 stroff;
	u32 strsize;
};

struct machoDysymtabCommand {
	u32 cmd;
	u32 cmdsize;
	u32 ilocalsym;
	u32 nlocalsym;
	u32 iextdefsym;
	u32 nextdefsym;
	u32 iundefsym;
	u32 nundefsym;
	u32 rest[12];
};

struct machoNlist {
	u32 n_strx;
	u8  n_type;
	u8  n_sect;
	u16 n_desc;
	u64 n_value;
};

struct machoReloc {
	i32 r_address;
	u32 r_info; // symbolnum:24, pcrel:1, length:2, extern:1, type:4
};

// A relocation before the symbol table is ordered: `sym` indexes the output symbols,
// or the output sections when `by_section`.
struct machoPendingReloc {
	i32 address;
	i32 sym;
	u32 type;
	bool pcrel;
	u32 length; // log2 of the size
	bool by_section;
};

enum machoOutSection {
	machoOut_Text,
	machoOut_Const,      // read only data without relocations
	machoOut_DataConst,  // read only data with relocations
	machoOut_Data,
	machoOut_ThreadVars,
	machoOut_ThreadData,
	machoOut_DebugAbbrev,
	machoOut_DebugInfo,
	machoOut_DebugLine,
	machoOut_DebugRanges,
	machoOut_CompactUnwind,
	machoOut_Bss,        // the zerofill sections come last
	machoOut_ThreadBss,
	machoOut_COUNT,
};

// A symbol of the output: one of the module's, or one this writer adds.
struct machoOutSym {
	String name;   // with the leading underscore
	u8     n_type;
	u16    n_desc;
	i32    out_section; // -1 if undefined
	i64    offset;      // within the output section
	u32    index;       // in the symbol table
};

gb_internal bool xb_is_darwin(void) {
	return build_context.metrics.os == TargetOs_darwin;
}

// "11.0.0" -> 0x000b0000
gb_internal u32 macho_version(String s) {
	u32 parts[3] = {};
	isize part = 0;
	for (isize i = 0; i < s.len && part < 3; i++) {
		if (s[i] == '.') {
			part += 1;
		} else if (s[i] >= '0' && s[i] <= '9') {
			parts[part] = parts[part]*10 + cast(u32)(s[i] - '0');
		}
	}
	return (parts[0] << 16) | ((parts[1] & 0xff) << 8) | (parts[2] & 0xff);
}

gb_internal void macho_set_name16(char *dst, char const *src) {
	gb_zero_size(dst, 16);
	isize n = gb_strlen(src);
	gb_memmove(dst, src, gb_min(n, cast(isize)16));
}

struct machoSortKey {
	String name;
	i32    index;
};

// equal names keep their order
gb_internal GB_COMPARE_PROC(macho_sort_key_cmp) {
	machoSortKey const *x = cast(machoSortKey const *)a;
	machoSortKey const *y = cast(machoSortKey const *)b;
	int c = string_compare(x->name, y->name);
	return c != 0 ? c : i32_cmp(x->index, y->index);
}

gb_internal bool xb_write_macho(xbModule *m, String path) {
	Array<u8> sec[machoOut_COUNT] = {};
	i64 sec_size[machoOut_COUNT] = {};
	i64 sec_align[machoOut_COUNT] = {};
	auto sec_relocs = slice_make<Array<machoPendingReloc>>(heap_allocator(), machoOut_COUNT);
	for (isize i = 0; i < machoOut_COUNT; i++) {
		sec[i] = array_make<u8>(heap_allocator(), 0, 0);
		sec_relocs[i] = array_make<machoPendingReloc>(heap_allocator(), 0, 0);
		sec_align[i] = 1;
	}

	bool rodata_has_relocs = false;
	for (xbReloc const &r : m->relocs) {
		if (r.section == xbSection_Rodata) rodata_has_relocs = true;
	}
	machoOutSection rodata_out = rodata_has_relocs ? machoOut_DataConst : machoOut_Const;

	auto out_section_of = [&](xbSection s) -> i32 {
		switch (s) {
		case xbSection_Text:   return machoOut_Text;
		case xbSection_Rodata: return rodata_out;
		case xbSection_Data:   return machoOut_Data;
		case xbSection_Bss:    return machoOut_Bss;
		case xbSection_TData:  return machoOut_ThreadData;
		case xbSection_TBss:   return machoOut_ThreadBss;
		}
		return -1;
	};
	auto take = [&](xbSection from) {
		i32 to = out_section_of(from);
		array_add_elems(&sec[to], m->sections[from].data, m->sections[from].count);
		sec_size[to] = m->sections[from].count;
		sec_align[to] = gb_max(m->section_align[from], cast(i64)1);
	};
	take(xbSection_Text);
	take(xbSection_Rodata);
	take(xbSection_Data);
	take(xbSection_TData);
	sec_align[machoOut_Text] = gb_max(sec_align[machoOut_Text], cast(i64)4);
	sec_size[machoOut_Bss] = m->nobits_size[xbSection_Bss];
	sec_align[machoOut_Bss] = gb_max(m->section_align[xbSection_Bss], cast(i64)1);
	sec_size[machoOut_ThreadBss] = m->nobits_size[xbSection_TBss];
	sec_align[machoOut_ThreadBss] = gb_max(m->section_align[xbSection_TBss], cast(i64)1);

	// symbols
	auto out_syms = array_make<machoOutSym>(heap_allocator(), 0, m->symbols.count + 16);
	auto sym_out = array_make<i32>(heap_allocator(), m->symbols.count); // module symbol -> out_syms index
	auto add_sym = [&](String name, char const *prefix, char const *suffix) -> i32 {
		machoOutSym os = {};
		gbString s = gb_string_make(heap_allocator(), prefix);
		s = gb_string_append_length(s, name.text, name.len);
		s = gb_string_appendc(s, suffix);
		os.name = make_string(cast(u8 *)s, gb_string_length(s));
		os.out_section = -1;
		array_add(&out_syms, os);
		return cast(i32)(out_syms.count - 1);
	};

	// only undefined symbols that something refers to, the linker reports every other one
	auto referenced = slice_make<bool>(heap_allocator(), m->symbols.count);
	for (xbReloc const &r : m->relocs) {
		referenced[r.sym] = true;
	}

	i32 tlv_bootstrap = -1;
	for_array(i, m->symbols) {
		xbSymbol const &s = m->symbols[i];
		sym_out[i] = -1;
		bool global = (s.flags & xbSymbolFlag_Global) != 0;
		if (s.section == xbSection_Undef) {
			if (!referenced[i]) continue;
			i32 o = add_sym(s.name, "_", "");
			out_syms[o].n_type = MACHO_N_UNDF | MACHO_N_EXT;
			sym_out[i] = o;
			continue;
		}

		u8 n_type = MACHO_N_SECT;
		u16 n_desc = 0;
		if (global) {
			n_type |= MACHO_N_EXT;
			if ((s.flags & xbSymbolFlag_Hidden) && (s.flags & xbSymbolFlag_Export) == 0) {
				n_type |= MACHO_N_PEXT;
			}
			if (s.flags & xbSymbolFlag_Weak) {
				n_desc |= MACHO_N_WEAK_DEF;
			}
		}

		if (s.flags & xbSymbolFlag_TLS) {
			// the initial value, then the descriptor that carries the symbol's own name
			i32 init = add_sym(s.name, "_", "$tlv$init");
			out_syms[init].n_type = MACHO_N_SECT;
			out_syms[init].out_section = out_section_of(s.section);
			out_syms[init].offset = s.offset;

			if (tlv_bootstrap < 0) {
				tlv_bootstrap = add_sym(str_lit("_tlv_bootstrap"), "_", "");
				out_syms[tlv_bootstrap].n_type = MACHO_N_UNDF | MACHO_N_EXT;
			}
			Array<u8> *tv = &sec[machoOut_ThreadVars];
			i64 at = tv->count;
			array_resize(tv, at + 24);
			gb_zero_size(tv->data + at, 24);
			sec_size[machoOut_ThreadVars] = tv->count;
			sec_align[machoOut_ThreadVars] = 8;

			i32 o = add_sym(s.name, "_", "");
			out_syms[o].n_type = n_type;
			out_syms[o].n_desc = n_desc;
			out_syms[o].out_section = machoOut_ThreadVars;
			out_syms[o].offset = at;
			sym_out[i] = o;

			// symbol numbers are patched in once the table is ordered
			machoPendingReloc r0 = {cast(i32)at, tlv_bootstrap, MACHO_RELOC_UNSIGNED, false, 3};
			machoPendingReloc r1 = {cast(i32)(at + 16), init, MACHO_RELOC_UNSIGNED, false, 3};
			array_add(&sec_relocs[machoOut_ThreadVars], r0);
			array_add(&sec_relocs[machoOut_ThreadVars], r1);
			continue;
		}

		i32 o = add_sym(s.name, "_", "");
		out_syms[o].n_type = n_type;
		out_syms[o].n_desc = n_desc;
		out_syms[o].out_section = out_section_of(s.section);
		out_syms[o].offset = s.offset;
		sym_out[i] = o;
	}

	for (xbReloc const &r : m->relocs) {
		i32 to = out_section_of(r.section);
		GB_ASSERT(to >= 0);
		GB_ASSERT_MSG(sym_out[r.sym] >= 0, "%.*s", LIT(m->symbols[r.sym].name));
		machoPendingReloc ar = {cast(i32)r.offset, sym_out[r.sym], 0, false, 2};
		// x86-64 stores the addend in place, counted from the end of the field like COFF
		i32 rel_addend = cast(i32)(r.addend + 4);
		switch (r.kind) {
		case xbReloc_Abs64:
			gb_memmove(sec[to].data + r.offset, &r.addend, 8);
			ar.type = MACHO_RELOC_UNSIGNED;
			ar.length = 3;
			break;
		case xbReloc_PC32:
			gb_memmove(sec[to].data + r.offset, &rel_addend, 4);
			ar.pcrel = true;
			switch (r.tail) {
			case 0: ar.type = MACHO_X86_64_RELOC_SIGNED;   break;
			case 1: ar.type = MACHO_X86_64_RELOC_SIGNED_1; break;
			case 2: ar.type = MACHO_X86_64_RELOC_SIGNED_2; break;
			case 4: ar.type = MACHO_X86_64_RELOC_SIGNED_4; break;
			default: GB_PANIC("rip relative field followed by %d bytes", r.tail);
			}
			break;
		case xbReloc_PLT32:
		case xbReloc_REX_GOTPCRELX:
		case xbReloc_TLV:
			// a call, a mov from the GOT, a mov of the descriptor's address: no addend
			GB_ASSERT(rel_addend == 0);
			ar.pcrel = true;
			ar.type = r.kind == xbReloc_PLT32 ? MACHO_X86_64_RELOC_BRANCH :
			          r.kind == xbReloc_TLV   ? MACHO_X86_64_RELOC_TLV : MACHO_X86_64_RELOC_GOT_LOAD;
			break;
		// the code relocations carry no addend, the instruction fields stay zero
		case xbReloc_A64_Branch26:     ar.type = MACHO_ARM64_RELOC_BRANCH26;            ar.pcrel = true; break;
		case xbReloc_A64_Page21:       ar.type = MACHO_ARM64_RELOC_PAGE21;              ar.pcrel = true; break;
		case xbReloc_A64_PageOff12:    ar.type = MACHO_ARM64_RELOC_PAGEOFF12;           break;
		case xbReloc_A64_GotPage21:    ar.type = MACHO_ARM64_RELOC_GOT_LOAD_PAGE21;     ar.pcrel = true; break;
		case xbReloc_A64_GotPageOff12: ar.type = MACHO_ARM64_RELOC_GOT_LOAD_PAGEOFF12;  break;
		case xbReloc_A64_TlvPage21:    ar.type = MACHO_ARM64_RELOC_TLVP_LOAD_PAGE21;    ar.pcrel = true; break;
		case xbReloc_A64_TlvPageOff12: ar.type = MACHO_ARM64_RELOC_TLVP_LOAD_PAGEOFF12; break;
		default:
			GB_PANIC("relocation kind %d has no Mach-O form", r.kind);
		}
		GB_ASSERT(r.addend == 0 || r.kind == xbReloc_Abs64 || !xb_is_arm64());
		array_add(&sec_relocs[to], ar);
	}

	// One compact unwind entry per procedure. Every frame has the standard frame record:
	// on arm64 the callee saved pairs sit right below it, on x86-64 the saved registers
	// take the slots right below rbp.
	for (xbProcDebug const &pd : m->proc_debug) {
		Array<u8> *cu = &sec[machoOut_CompactUnwind];
		i64 at = cu->count;
		array_resize(cu, at + 32);
		gb_zero_size(cu->data + at, 32);
		u32 length = cast(u32)(pd.end - pd.start);
		u32 encoding = 0;
		if (xb_is_arm64()) {
			encoding = MACHO_UNWIND_ARM64_MODE_FRAME;
			for (auto const &s : pd.saved_regs) {
				// dwarf x19-x28, then d8-d15 as 72-79
				if (s.dwarf_reg >= 19 && s.dwarf_reg <= 28) encoding |= 1u << ((s.dwarf_reg - 19) / 2);
				if (s.dwarf_reg >= 72 && s.dwarf_reg <= 79) encoding |= 0x100u << ((s.dwarf_reg - 72) / 2);
			}
		} else if (pd.naked) {
			// no frame, the stack holds only the return address
			encoding = MACHO_UNWIND_X86_64_MODE_STACK_IMMD | (1u << 16);
		} else {
			// the slot count below rbp, then a 3 bit register number per slot, the lowest slot first
			i32 slots = 0;
			for (auto const &s : pd.saved_regs) slots = gb_max(slots, cast(i32)(-s.frame_offset / 8));
			GB_ASSERT(slots <= 5);
			encoding = MACHO_UNWIND_X86_64_MODE_RBP_FRAME | (cast(u32)slots << 16);
			for (auto const &s : pd.saved_regs) {
				// dwarf rbx 3, r12-r15 12-15; compact unwind rbx 1, r12-r15 2-5
				u32 reg = s.dwarf_reg == 3 ? 1 : cast(u32)(s.dwarf_reg - 10);
				GB_ASSERT(reg >= 1 && reg <= 5);
				i32 slot = slots - cast(i32)(-s.frame_offset / 8);
				encoding |= reg << (3*slot);
			}
		}
		gb_memmove(cu->data + at + 8, &length, 4);
		gb_memmove(cu->data + at + 12, &encoding, 4);
		GB_ASSERT(sym_out[pd.sym] >= 0);
		machoPendingReloc r = {cast(i32)at, sym_out[pd.sym], MACHO_RELOC_UNSIGNED, false, 3};
		array_add(&sec_relocs[machoOut_CompactUnwind], r);
	}
	sec_size[machoOut_CompactUnwind] = sec[machoOut_CompactUnwind].count;
	sec_align[machoOut_CompactUnwind] = 8;

	// DWARF stays in the object: dsymutil and lldb read it there through the executable's debug map.
	// Its addresses are object addresses with a relocation against their section, as clang writes them.
	struct DwarfAddr { i32 sect; i64 offset; i32 target; i64 target_offset; i32 ext_sym; };
	auto dwarf_addrs = array_make<DwarfAddr>(heap_allocator(), 0, 0);
	if (build_context.ODIN_DEBUG) {
		xbDwarf d = {};
		xb_dwarf_build(m, &d);
		sec[machoOut_DebugAbbrev] = d.abbrev;
		sec[machoOut_DebugInfo] = d.info;
		sec[machoOut_DebugLine] = d.line;
		sec[machoOut_DebugRanges] = d.ranges;
		for (i32 i = machoOut_DebugAbbrev; i <= machoOut_DebugRanges; i++) {
			sec_size[i] = sec[i].count;
		}
		auto add = [&](i32 sect, xbDwarfAddr const &a) {
			DwarfAddr da = {sect, cast(i64)a.offset, machoOut_Text, a.addend, -1};
			if (a.sym >= 0) {
				i32 o = sym_out[a.sym];
				if (o < 0) return; // an unused undefined symbol, the address stays 0
				da.target = out_syms[o].out_section;
				da.target_offset = out_syms[o].offset;
				if (da.target < 0) da.ext_sym = o;
			}
			array_add(&dwarf_addrs, da);
		};
		for (xbDwarfAddr const &a : d.info_addrs) add(machoOut_DebugInfo, a);
		for (xbDwarfAddr const &a : d.line_addrs) add(machoOut_DebugLine, a);
	}

	// the table is ordered: locals, defined externals, undefined externals
	auto order = array_make<i32>(heap_allocator(), 0, out_syms.count);
	u32 nlocal = 0, nextdef = 0, nundef = 0;
	for (i32 pass = 0; pass < 3; pass++) {
		isize first = order.count;
		for_array(i, out_syms) {
			machoOutSym const &os = out_syms[i];
			bool ext = (os.n_type & MACHO_N_EXT) != 0;
			bool undef = os.out_section < 0;
			i32 kind = !ext ? 0 : undef ? 2 : 1;
			if (kind == pass) array_add(&order, cast(i32)i);
		}
		isize n = order.count - first;
		if (pass > 0) {
			// sorted by name, like the objects of other tools
			auto keys = array_make<machoSortKey>(heap_allocator(), n);
			for (isize k = 0; k < n; k++) {
				keys[k] = {out_syms[order[first+k]].name, order[first+k]};
			}
			array_sort(keys, macho_sort_key_cmp);
			for (isize k = 0; k < n; k++) {
				order[first+k] = keys[k].index;
			}
			array_free(&keys);
		}
		if (pass == 0) nlocal = cast(u32)n;
		if (pass == 1) nextdef = cast(u32)n;
		if (pass == 2) nundef = cast(u32)n;
	}
	for_array(i, order) {
		out_syms[order[i]].index = cast(u32)i;
	}

	// sections: the ones with contents, the zerofill ones last
	struct SectInfo { char const *sect; char const *seg; u32 flags; bool zerofill; };
	SectInfo const infos[machoOut_COUNT] = {
		{"__text",        "__TEXT", MACHO_S_REGULAR | MACHO_S_ATTR_PURE_INSTRUCTIONS | MACHO_S_ATTR_SOME_INSTRUCTIONS, false},
		{"__const",       "__TEXT", MACHO_S_REGULAR, false},
		{"__const",       "__DATA", MACHO_S_REGULAR, false},
		{"__data",        "__DATA", MACHO_S_REGULAR, false},
		{"__thread_vars", "__DATA", MACHO_S_THREAD_LOCAL_VARIABLES, false},
		{"__thread_data", "__DATA", MACHO_S_THREAD_LOCAL_REGULAR, false},
		{"__debug_abbrev", "__DWARF", MACHO_S_REGULAR | MACHO_S_ATTR_DEBUG, false},
		{"__debug_info",   "__DWARF", MACHO_S_REGULAR | MACHO_S_ATTR_DEBUG, false},
		{"__debug_line",   "__DWARF", MACHO_S_REGULAR | MACHO_S_ATTR_DEBUG, false},
		{"__debug_ranges", "__DWARF", MACHO_S_REGULAR | MACHO_S_ATTR_DEBUG, false},
		{"__compact_unwind", "__LD", MACHO_S_REGULAR | MACHO_S_ATTR_DEBUG, false},
		{"__bss",         "__DATA", MACHO_S_ZEROFILL, true},
		{"__thread_bss",  "__DATA", MACHO_S_THREAD_LOCAL_ZEROFILL, true},
	};
	i32 sect_number[machoOut_COUNT] = {}; // 1 based, 0 if not written
	i64 sect_addr[machoOut_COUNT] = {};
	i32 nsects = 0;
	i64 addr = 0;
	i64 file_end_addr = 0;
	for (isize i = 0; i < machoOut_COUNT; i++) {
		if (sec_size[i] == 0) continue;
		addr = align_formula(addr, sec_align[i]);
		sect_addr[i] = addr;
		sect_number[i] = ++nsects;
		addr += sec_size[i];
		if (!infos[i].zerofill) file_end_addr = addr;
	}
	i64 vmsize = addr;

	u32 sizeofcmds = cast(u32)(gb_size_of(machoSegmentCommand) + nsects*gb_size_of(machoSection) +
	                           gb_size_of(machoBuildVersion) + gb_size_of(machoSymtabCommand) + gb_size_of(machoDysymtabCommand));
	i64 data_start = align_formula(cast(i64)(gb_size_of(machoHeader) + sizeofcmds), 16);
	i64 max_align = 16;
	for (isize i = 0; i < machoOut_COUNT; i++) {
		if (sect_number[i]) max_align = gb_max(max_align, sec_align[i]);
	}
	// section addresses only line up with file offsets when the data starts that aligned
	data_start = align_formula(data_start, max_align);

	for (DwarfAddr const &da : dwarf_addrs) {
		machoPendingReloc r = {cast(i32)da.offset, da.ext_sym, MACHO_RELOC_UNSIGNED, false, 3, false};
		u64 value = 0;
		if (da.ext_sym < 0) {
			GB_ASSERT(sect_number[da.target] != 0);
			value = cast(u64)(sect_addr[da.target] + da.target_offset);
			r.sym = da.target;
			r.by_section = true;
		}
		gb_memmove(sec[da.sect].data + da.offset, &value, 8);
		array_add(&sec_relocs[da.sect], r);
	}

	auto out = array_make<u8>(heap_allocator(), 0, data_start + file_end_addr + 4096);
	array_resize(&out, data_start + file_end_addr);
	gb_zero_size(out.data, out.count);
	for (isize i = 0; i < machoOut_COUNT; i++) {
		if (!sect_number[i] || infos[i].zerofill) continue;
		gb_memmove(out.data + data_start + sect_addr[i], sec[i].data, sec[i].count);
	}

	// relocations, with the final symbol numbers
	i64 reloff[machoOut_COUNT] = {};
	xbb_align(&out, 8);
	for (isize i = 0; i < machoOut_COUNT; i++) {
		if (!sect_number[i]) continue;
		reloff[i] = out.count;
		for (machoPendingReloc const &pr : sec_relocs[i]) {
			machoReloc r = {};
			r.r_address = pr.address;
			if (pr.by_section) {
				r.r_info = cast(u32)sect_number[pr.sym] | ((pr.pcrel ? 1u : 0u) << 24) | (pr.length << 25) | (pr.type << 28);
			} else {
				r.r_info = out_syms[pr.sym].index | ((pr.pcrel ? 1u : 0u) << 24) | (pr.length << 25) | (1u << 27) | (pr.type << 28);
			}
			xbb_bytes(&out, &r, gb_size_of(r));
		}
	}

	// the symbol and string tables
	auto strtab = array_make<u8>(heap_allocator(), 0, 4096);
	xbb_u8(&strtab, ' ');
	xbb_u8(&strtab, 0);
	xbb_align(&out, 8);
	i64 symoff = out.count;
	for (i32 idx : order) {
		machoOutSym const &os = out_syms[idx];
		machoNlist nl = {};
		nl.n_strx = cast(u32)strtab.count;
		xbb_str(&strtab, os.name);
		nl.n_type = os.n_type;
		nl.n_desc = os.n_desc;
		if (os.out_section >= 0) {
			GB_ASSERT(sect_number[os.out_section] != 0);
			nl.n_sect = cast(u8)sect_number[os.out_section];
			nl.n_value = cast(u64)(sect_addr[os.out_section] + os.offset);
		}
		xbb_bytes(&out, &nl, gb_size_of(nl));
	}
	xbb_align(&strtab, 8);
	i64 stroff = out.count;
	xbb_bytes(&out, strtab.data, strtab.count);

	// header and load commands
	Array<u8> cmds = array_make<u8>(heap_allocator(), 0, sizeofcmds);
	{
		machoSegmentCommand sc = {};
		sc.cmd = MACHO_LC_SEGMENT_64;
		sc.cmdsize = cast(u32)(gb_size_of(machoSegmentCommand) + nsects*gb_size_of(machoSection));
		sc.vmaddr = 0;
		sc.vmsize = cast(u64)vmsize;
		sc.fileoff = cast(u64)data_start;
		sc.filesize = cast(u64)file_end_addr;
		sc.maxprot = 7;
		sc.initprot = 7;
		sc.nsects = cast(u32)nsects;
		xbb_bytes(&cmds, &sc, gb_size_of(sc));
		for (isize i = 0; i < machoOut_COUNT; i++) {
			if (!sect_number[i]) continue;
			machoSection s = {};
			macho_set_name16(s.sectname, infos[i].sect);
			macho_set_name16(s.segname, infos[i].seg);
			s.addr = cast(u64)sect_addr[i];
			s.size = cast(u64)sec_size[i];
			s.offset = infos[i].zerofill ? 0 : cast(u32)(data_start + sect_addr[i]);
			u32 align_log2 = 0;
			while ((cast(i64)1 << align_log2) < sec_align[i]) align_log2 += 1;
			s.align = align_log2;
			s.nreloc = cast(u32)sec_relocs[i].count;
			s.reloff = s.nreloc ? cast(u32)reloff[i] : 0;
			s.flags = infos[i].flags;
			xbb_bytes(&cmds, &s, gb_size_of(s));
		}
	}
	{
		machoBuildVersion bv = {};
		bv.cmd = MACHO_LC_BUILD_VERSION;
		bv.cmdsize = gb_size_of(bv);
		bv.platform = MACHO_PLATFORM_MACOS;
		bv.minos = macho_version(build_context.minimum_os_version_string);
		xbb_bytes(&cmds, &bv, gb_size_of(bv));
	}
	{
		machoSymtabCommand st = {};
		st.cmd = MACHO_LC_SYMTAB;
		st.cmdsize = gb_size_of(st);
		st.symoff = cast(u32)symoff;
		st.nsyms = cast(u32)order.count;
		st.stroff = cast(u32)stroff;
		st.strsize = cast(u32)strtab.count;
		xbb_bytes(&cmds, &st, gb_size_of(st));
	}
	{
		machoDysymtabCommand dt = {};
		dt.cmd = MACHO_LC_DYSYMTAB;
		dt.cmdsize = gb_size_of(dt);
		dt.ilocalsym = 0;
		dt.nlocalsym = nlocal;
		dt.iextdefsym = nlocal;
		dt.nextdefsym = nextdef;
		dt.iundefsym = nlocal + nextdef;
		dt.nundefsym = nundef;
		xbb_bytes(&cmds, &dt, gb_size_of(dt));
	}
	GB_ASSERT(cmds.count == sizeofcmds);

	machoHeader h = {};
	h.magic = MACHO_MH_MAGIC_64;
	h.cputype = xb_is_arm64() ? MACHO_CPU_TYPE_ARM64 : MACHO_CPU_TYPE_X86_64;
	h.cpusubtype = xb_is_arm64() ? 0 : MACHO_CPU_SUBTYPE_X86_64_ALL;
	h.filetype = MACHO_MH_OBJECT;
	h.ncmds = 4;
	h.sizeofcmds = sizeofcmds;
	// the linker splits sections at symbols, so a weak duplicate drops only its own bytes
	h.flags = MACHO_MH_SUBSECTIONS_VIA_SYMBOLS;
	gb_memmove(out.data, &h, gb_size_of(h));
	gb_memmove(out.data + gb_size_of(h), cmds.data, cmds.count);

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
