// Mach-O relocatable object writer for arm64 macOS.
//
// All sections live in one unnamed segment, as in the objects clang writes. A section's
// file offset mirrors its address, so `offset - fileoff == addr`.
//
// Thread locals follow the TLV scheme: the symbol names a descriptor in __thread_vars,
// which points at `__tlv_bootstrap` and at the initial value, the `$tlv$init` symbol.

enum : u32 {
	A64_MH_MAGIC_64       = 0xfeedfacf,
	A64_CPU_TYPE_ARM64    = 0x0100000c,
	A64_MH_OBJECT         = 1,
	A64_MH_SUBSECTIONS_VIA_SYMBOLS = 0x2000,

	A64_LC_SYMTAB         = 0x2,
	A64_LC_DYSYMTAB       = 0xb,
	A64_LC_SEGMENT_64     = 0x19,
	A64_LC_BUILD_VERSION  = 0x32,
	A64_PLATFORM_MACOS    = 1,

	A64_S_REGULAR                    = 0x0,
	A64_S_ZEROFILL                   = 0x1,
	A64_S_THREAD_LOCAL_REGULAR       = 0x11,
	A64_S_THREAD_LOCAL_ZEROFILL      = 0x12,
	A64_S_THREAD_LOCAL_VARIABLES     = 0x13,
	A64_S_ATTR_PURE_INSTRUCTIONS     = 0x80000000,
	A64_S_ATTR_SOME_INSTRUCTIONS     = 0x00000400,

	A64_ARM64_RELOC_UNSIGNED = 0,
};

enum : u8 {
	A64_N_UNDF = 0x0,
	A64_N_EXT  = 0x01,
	A64_N_SECT = 0x0e,
	A64_N_PEXT = 0x10,
};

enum : u16 {
	A64_N_WEAK_DEF = 0x80,
};

struct a64MachHeader {
	u32 magic;
	u32 cputype;
	u32 cpusubtype;
	u32 filetype;
	u32 ncmds;
	u32 sizeofcmds;
	u32 flags;
	u32 reserved;
};

struct a64SegmentCommand {
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

struct a64Section {
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

struct a64BuildVersion {
	u32 cmd;
	u32 cmdsize;
	u32 platform;
	u32 minos;
	u32 sdk;
	u32 ntools;
};

struct a64SymtabCommand {
	u32 cmd;
	u32 cmdsize;
	u32 symoff;
	u32 nsyms;
	u32 stroff;
	u32 strsize;
};

struct a64DysymtabCommand {
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

struct a64Nlist {
	u32 n_strx;
	u8  n_type;
	u8  n_sect;
	u16 n_desc;
	u64 n_value;
};

struct a64Reloc {
	i32 r_address;
	u32 r_info; // symbolnum:24, pcrel:1, length:2, extern:1, type:4
};

enum a64OutSection {
	a64Out_Text,
	a64Out_Const,      // read only data without relocations
	a64Out_DataConst,  // read only data with relocations
	a64Out_Data,
	a64Out_ThreadVars,
	a64Out_ThreadData,
	a64Out_Bss,
	a64Out_ThreadBss,
	a64Out_COUNT,
};

// A symbol of the output: one of the module's, or one this writer adds.
struct a64OutSym {
	String name;   // with the leading underscore
	u8     n_type;
	u16    n_desc;
	i32    out_section; // -1 if undefined
	i64    offset;      // within the output section
	u32    index;       // in the symbol table
};

// "11.0.0" -> 0x000b0000
gb_internal u32 a64_macho_version(String s) {
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

gb_internal void a64_set_name16(char *dst, char const *src) {
	gb_zero_size(dst, 16);
	isize n = gb_strlen(src);
	gb_memmove(dst, src, gb_min(n, cast(isize)16));
}

gb_internal bool a64_write_macho(xbModule *m, String path) {
	Array<u8> sec[a64Out_COUNT] = {};
	i64 sec_size[a64Out_COUNT] = {};
	i64 sec_align[a64Out_COUNT] = {};
	auto sec_relocs = slice_make<Array<a64Reloc>>(heap_allocator(), a64Out_COUNT);
	for (isize i = 0; i < a64Out_COUNT; i++) {
		sec[i] = array_make<u8>(heap_allocator(), 0, 0);
		sec_relocs[i] = array_make<a64Reloc>(heap_allocator(), 0, 0);
		sec_align[i] = 1;
	}

	bool rodata_has_relocs = false;
	for (xbReloc const &r : m->relocs) {
		if (r.section == xbSection_Rodata) rodata_has_relocs = true;
	}
	a64OutSection rodata_out = rodata_has_relocs ? a64Out_DataConst : a64Out_Const;

	auto out_section_of = [&](xbSection s) -> i32 {
		switch (s) {
		case xbSection_Text:   return a64Out_Text;
		case xbSection_Rodata: return rodata_out;
		case xbSection_Data:   return a64Out_Data;
		case xbSection_Bss:    return a64Out_Bss;
		case xbSection_TData:  return a64Out_ThreadData;
		case xbSection_TBss:   return a64Out_ThreadBss;
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
	sec_align[a64Out_Text] = gb_max(sec_align[a64Out_Text], cast(i64)4);
	sec_size[a64Out_Bss] = m->nobits_size[xbSection_Bss];
	sec_align[a64Out_Bss] = gb_max(m->section_align[xbSection_Bss], cast(i64)1);
	sec_size[a64Out_ThreadBss] = m->nobits_size[xbSection_TBss];
	sec_align[a64Out_ThreadBss] = gb_max(m->section_align[xbSection_TBss], cast(i64)1);

	// symbols
	auto out_syms = array_make<a64OutSym>(heap_allocator(), 0, m->symbols.count + 16);
	auto sym_out = array_make<i32>(heap_allocator(), m->symbols.count); // module symbol -> out_syms index
	auto add_sym = [&](String name, char const *prefix, char const *suffix) -> i32 {
		a64OutSym os = {};
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
			out_syms[o].n_type = A64_N_UNDF | A64_N_EXT;
			sym_out[i] = o;
			continue;
		}

		u8 n_type = A64_N_SECT;
		u16 n_desc = 0;
		if (global) {
			n_type |= A64_N_EXT;
			if ((s.flags & xbSymbolFlag_Hidden) && (s.flags & xbSymbolFlag_Export) == 0) {
				n_type |= A64_N_PEXT;
			}
			if (s.flags & xbSymbolFlag_Weak) {
				n_desc |= A64_N_WEAK_DEF;
			}
		}

		if (s.flags & xbSymbolFlag_TLS) {
			// the initial value, then the descriptor that carries the symbol's own name
			i32 init = add_sym(s.name, "_", "$tlv$init");
			out_syms[init].n_type = A64_N_SECT;
			out_syms[init].out_section = out_section_of(s.section);
			out_syms[init].offset = s.offset;

			if (tlv_bootstrap < 0) {
				tlv_bootstrap = add_sym(str_lit("_tlv_bootstrap"), "_", "");
				out_syms[tlv_bootstrap].n_type = A64_N_UNDF | A64_N_EXT;
			}
			Array<u8> *tv = &sec[a64Out_ThreadVars];
			i64 at = tv->count;
			array_resize(tv, at + 24);
			gb_zero_size(tv->data + at, 24);
			sec_size[a64Out_ThreadVars] = tv->count;
			sec_align[a64Out_ThreadVars] = 8;

			i32 o = add_sym(s.name, "_", "");
			out_syms[o].n_type = n_type;
			out_syms[o].n_desc = n_desc;
			out_syms[o].out_section = a64Out_ThreadVars;
			out_syms[o].offset = at;
			sym_out[i] = o;

			// symbol numbers are patched in once the table is ordered
			a64Reloc r0 = {cast(i32)at, cast(u32)tlv_bootstrap};
			a64Reloc r1 = {cast(i32)(at + 16), cast(u32)init};
			array_add(&sec_relocs[a64Out_ThreadVars], r0);
			array_add(&sec_relocs[a64Out_ThreadVars], r1);
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
		switch (r.kind) {
		case xbReloc_Abs64: {
			// the addend is stored in place
			gb_memmove(sec[to].data + r.offset, &r.addend, 8);
			a64Reloc ar = {cast(i32)r.offset, cast(u32)sym_out[r.sym]};
			array_add(&sec_relocs[to], ar);
			break;
		}
		default:
			GB_PANIC("relocation kind %d is not supported on arm64", r.kind);
		}
	}

	// the table is ordered: locals, defined externals, undefined externals
	auto order = array_make<i32>(heap_allocator(), 0, out_syms.count);
	u32 nlocal = 0, nextdef = 0, nundef = 0;
	for (i32 pass = 0; pass < 3; pass++) {
		isize first = order.count;
		for_array(i, out_syms) {
			a64OutSym const &os = out_syms[i];
			bool ext = (os.n_type & A64_N_EXT) != 0;
			bool undef = os.out_section < 0;
			i32 kind = !ext ? 0 : undef ? 2 : 1;
			if (kind == pass) array_add(&order, cast(i32)i);
		}
		isize n = order.count - first;
		if (pass > 0) {
			// sorted by name, like the objects of other tools
			for (isize a = first+1; a < order.count; a++) {
				i32 v = order[a];
				isize b = a;
				while (b > first && string_compare(out_syms[order[b-1]].name, out_syms[v].name) > 0) {
					order[b] = order[b-1];
					b -= 1;
				}
				order[b] = v;
			}
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
	SectInfo const infos[a64Out_COUNT] = {
		{"__text",        "__TEXT", A64_S_REGULAR | A64_S_ATTR_PURE_INSTRUCTIONS | A64_S_ATTR_SOME_INSTRUCTIONS, false},
		{"__const",       "__TEXT", A64_S_REGULAR, false},
		{"__const",       "__DATA", A64_S_REGULAR, false},
		{"__data",        "__DATA", A64_S_REGULAR, false},
		{"__thread_vars", "__DATA", A64_S_THREAD_LOCAL_VARIABLES, false},
		{"__thread_data", "__DATA", A64_S_THREAD_LOCAL_REGULAR, false},
		{"__bss",         "__DATA", A64_S_ZEROFILL, true},
		{"__thread_bss",  "__DATA", A64_S_THREAD_LOCAL_ZEROFILL, true},
	};
	i32 sect_number[a64Out_COUNT] = {}; // 1 based, 0 if not written
	i64 sect_addr[a64Out_COUNT] = {};
	i32 nsects = 0;
	i64 addr = 0;
	i64 file_end_addr = 0;
	for (isize i = 0; i < a64Out_COUNT; i++) {
		if (sec_size[i] == 0) continue;
		addr = align_formula(addr, sec_align[i]);
		sect_addr[i] = addr;
		sect_number[i] = ++nsects;
		addr += sec_size[i];
		if (!infos[i].zerofill) file_end_addr = addr;
	}
	i64 vmsize = addr;

	u32 sizeofcmds = cast(u32)(gb_size_of(a64SegmentCommand) + nsects*gb_size_of(a64Section) +
	                           gb_size_of(a64BuildVersion) + gb_size_of(a64SymtabCommand) + gb_size_of(a64DysymtabCommand));
	i64 data_start = align_formula(cast(i64)(gb_size_of(a64MachHeader) + sizeofcmds), 16);
	i64 max_align = 16;
	for (isize i = 0; i < a64Out_COUNT; i++) {
		if (sect_number[i]) max_align = gb_max(max_align, sec_align[i]);
	}
	// section addresses only line up with file offsets when the data starts that aligned
	data_start = align_formula(data_start, max_align);

	auto out = array_make<u8>(heap_allocator(), 0, data_start + file_end_addr + 4096);
	array_resize(&out, data_start + file_end_addr);
	gb_zero_size(out.data, out.count);
	for (isize i = 0; i < a64Out_COUNT; i++) {
		if (!sect_number[i] || infos[i].zerofill) continue;
		gb_memmove(out.data + data_start + sect_addr[i], sec[i].data, sec[i].count);
	}

	// relocations, with the final symbol numbers
	i64 reloff[a64Out_COUNT] = {};
	xbb_align(&out, 8);
	for (isize i = 0; i < a64Out_COUNT; i++) {
		if (!sect_number[i]) continue;
		reloff[i] = out.count;
		for (a64Reloc r : sec_relocs[i]) {
			u32 symnum = out_syms[r.r_info].index;
			r.r_info = symnum | (0u << 24) | (3u << 25) | (1u << 27) | (A64_ARM64_RELOC_UNSIGNED << 28);
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
		a64OutSym const &os = out_syms[idx];
		a64Nlist nl = {};
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
		a64SegmentCommand sc = {};
		sc.cmd = A64_LC_SEGMENT_64;
		sc.cmdsize = cast(u32)(gb_size_of(a64SegmentCommand) + nsects*gb_size_of(a64Section));
		sc.vmaddr = 0;
		sc.vmsize = cast(u64)vmsize;
		sc.fileoff = cast(u64)data_start;
		sc.filesize = cast(u64)file_end_addr;
		sc.maxprot = 7;
		sc.initprot = 7;
		sc.nsects = cast(u32)nsects;
		xbb_bytes(&cmds, &sc, gb_size_of(sc));
		for (isize i = 0; i < a64Out_COUNT; i++) {
			if (!sect_number[i]) continue;
			a64Section s = {};
			a64_set_name16(s.sectname, infos[i].sect);
			a64_set_name16(s.segname, infos[i].seg);
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
		a64BuildVersion bv = {};
		bv.cmd = A64_LC_BUILD_VERSION;
		bv.cmdsize = gb_size_of(bv);
		bv.platform = A64_PLATFORM_MACOS;
		bv.minos = a64_macho_version(build_context.minimum_os_version_string);
		xbb_bytes(&cmds, &bv, gb_size_of(bv));
	}
	{
		a64SymtabCommand st = {};
		st.cmd = A64_LC_SYMTAB;
		st.cmdsize = gb_size_of(st);
		st.symoff = cast(u32)symoff;
		st.nsyms = cast(u32)order.count;
		st.stroff = cast(u32)stroff;
		st.strsize = cast(u32)strtab.count;
		xbb_bytes(&cmds, &st, gb_size_of(st));
	}
	{
		a64DysymtabCommand dt = {};
		dt.cmd = A64_LC_DYSYMTAB;
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

	a64MachHeader h = {};
	h.magic = A64_MH_MAGIC_64;
	h.cputype = A64_CPU_TYPE_ARM64;
	h.cpusubtype = 0;
	h.filetype = A64_MH_OBJECT;
	h.ncmds = 4;
	h.sizeofcmds = sizeofcmds;
	// the linker splits sections at symbols, so a weak duplicate drops only its own bytes
	h.flags = A64_MH_SUBSECTIONS_VIA_SYMBOLS;
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
