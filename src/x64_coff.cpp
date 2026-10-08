// COFF (x86-64) relocatable object writer for Windows, with .pdata/.xdata unwind
// info and CodeView debug info (x64_codeview.cpp).

enum xbCoffSec {
	xbCoff_Text,
	xbCoff_Rdata,
	xbCoff_Data,
	xbCoff_Bss,
	xbCoff_Tls,
	xbCoff_Pdata,
	xbCoff_Xdata,
	xbCoff_Drectve,
	xbCoff_DebugS,
	xbCoff_DebugT,
	xbCoff_COUNT,
};

enum : u16 {
	XB_IMAGE_REL_AMD64_ADDR64   = 0x1,
	XB_IMAGE_REL_AMD64_ADDR32   = 0x2,
	XB_IMAGE_REL_AMD64_ADDR32NB = 0x3,
	XB_IMAGE_REL_AMD64_REL32    = 0x4,
	XB_IMAGE_REL_AMD64_SECTION  = 0xA,
	XB_IMAGE_REL_AMD64_SECREL   = 0xB,
};

// a relocation in one of the sections this file builds, against a section's start
struct xbCoffReloc {
	u32 offset;
	i32 sym;         // xbModule symbol, or -1 for the start of `sym_section`
	xbCoffSec sym_section;
	u16 type;
};

struct xbCoffWriter {
	xbModule *m;
	Array<u8> sec[xbCoff_COUNT];
	Array<xbCoffReloc> relocs[xbCoff_COUNT];
	i64 bss_size;
	i64 tbss_base;   // .tbss follows .tdata in .tls$
	i64 align[xbCoff_COUNT];
};

gb_internal xbCoffSec xb_coff_section_of(xbSection s) {
	switch (s) {
	case xbSection_Text:   return xbCoff_Text;
	case xbSection_Rodata: return xbCoff_Rdata;
	case xbSection_Data:   return xbCoff_Data;
	case xbSection_Bss:    return xbCoff_Bss;
	case xbSection_TData:  return xbCoff_Tls;
	case xbSection_TBss:   return xbCoff_Tls;
	}
	GB_PANIC("bad section");
	return xbCoff_Text;
}

// The offset of a symbol in its COFF section.
gb_internal i64 xb_coff_symbol_offset(xbCoffWriter *w, xbSymbol const &s) {
	if (s.section == xbSection_TBss) return w->tbss_base + s.offset;
	return s.offset;
}

gb_internal void xb_coff_add_reloc(xbCoffWriter *w, xbCoffSec in, u32 offset, xbCoffSec target, u16 type) {
	xbCoffReloc r = {offset, -1, target, type};
	array_add(&w->relocs[in], r);
}

#include "x64_codeview.cpp"

////////////////////////////////////////////////////////////////
// Unwind info
////////////////////////////////////////////////////////////////

enum : u8 {
	XB_UWOP_PUSH_NONVOL = 0,
	XB_UWOP_ALLOC_LARGE = 1,
	XB_UWOP_ALLOC_SMALL = 2,
	XB_UWOP_SET_FPREG   = 3,
	XB_UWOP_SAVE_XMM128 = 8,
};

gb_internal void xb_coff_unwind(xbCoffWriter *w) {
	xbModule *m = w->m;
	Array<u8> *pdata = &w->sec[xbCoff_Pdata];
	Array<u8> *xdata = &w->sec[xbCoff_Xdata];
	for (xbProcDebug const &pd : m->proc_debug) {
		xbb_align(xdata, 4);
		u32 info_at = cast(u32)xdata->count;

		// the codes undo the prologue, so they are listed last operation first
		u16 codes[48] = {};
		i32 n = 0;
		auto code = [&](u8 at, u8 op, u8 info) {
			codes[n++] = cast(u16)(at | (op << 8) | (info << 12));
		};
		auto alloc = [&](u8 at, u32 size) {
			if (size <= 128) {
				code(at, XB_UWOP_ALLOC_SMALL, cast(u8)(size/8 - 1));
			} else if (size <= 512*1024 - 8) {
				code(at, XB_UWOP_ALLOC_LARGE, 0);
				codes[n++] = cast(u16)(size/8);
			} else {
				code(at, XB_UWOP_ALLOC_LARGE, 1);
				codes[n++] = cast(u16)(size & 0xffff);
				codes[n++] = cast(u16)(size >> 16);
			}
		};
		// the xmm saves are at rbp + 16*i, rbp being the frame base (frame offset 0)
		for (i32 i = pd.win_xmm_count-1; i >= 0; i--) {
			code(pd.win_xmm_at[i], XB_UWOP_SAVE_XMM128, pd.win_xmm_reg[i]);
			codes[n++] = cast(u16)i;
		}
		if (pd.win_alloc_at != 0) {
			alloc(pd.win_alloc_at, cast(u32)pd.win_alloc_size);
		}
		code(pd.win_setfp_at, XB_UWOP_SET_FPREG, 0);
		if (pd.win_pad_at != 0) {
			alloc(pd.win_pad_at, cast(u32)pd.win_pad_size);
		}
		for (i32 i = pd.win_push_count-1; i >= 0; i--) {
			code(pd.win_push_at[i], XB_UWOP_PUSH_NONVOL, pd.win_push_reg[i]);
		}
		u8 prolog_size = pd.win_alloc_at != 0 ? pd.win_alloc_at : pd.win_setfp_at;
		if (pd.win_xmm_count > 0) prolog_size = pd.win_xmm_at[pd.win_xmm_count-1];

		xbb_u8(xdata, 1); // version 1, no flags
		xbb_u8(xdata, prolog_size);
		xbb_u8(xdata, cast(u8)n);
		xbb_u8(xdata, cast(u8)(RBP | (0 << 4))); // frame register rbp, offset 0
		for (i32 i = 0; i < n; i++) xbb_u16(xdata, codes[i]);
		if (n % 2) xbb_u16(xdata, 0);

		u32 at = cast(u32)pdata->count;
		xbb_u32(pdata, cast(u32)pd.start);
		xbb_u32(pdata, cast(u32)pd.end);
		xbb_u32(pdata, info_at);
		xb_coff_add_reloc(w, xbCoff_Pdata, at + 0, xbCoff_Text, XB_IMAGE_REL_AMD64_ADDR32NB);
		xb_coff_add_reloc(w, xbCoff_Pdata, at + 4, xbCoff_Text, XB_IMAGE_REL_AMD64_ADDR32NB);
		xb_coff_add_reloc(w, xbCoff_Pdata, at + 8, xbCoff_Xdata, XB_IMAGE_REL_AMD64_ADDR32NB);
	}
}

////////////////////////////////////////////////////////////////
// The object file
////////////////////////////////////////////////////////////////

struct xbCoffSym {
	String name;
	u32    value;
	i16    section; // 1-based, 0 undefined
	u16    type;
	u8     storage_class;
	u8     aux_count;
	u8     aux[18];
};

gb_internal u32 xb_coff_align_flag(i64 align) {
	u32 log = 0;
	while ((cast(i64)1 << log) < align && log < 13) log++;
	return (log + 1) << 20;
}

gb_internal bool xb_coff_needs_quotes(String name) {
	for (isize i = 0; i < name.len; i++) {
		u8 c = name[i];
		bool plain = (c >= 'a' && c <= 'z') || (c >= 'A' && c <= 'Z') || (c >= '0' && c <= '9') ||
		             c == '_' || c == '$' || c == '@' || c == '?' || c == '.';
		if (!plain) return true;
	}
	return false;
}

gb_internal bool xb_write_coff(xbModule *m, String path) {
	xbCoffWriter w = {};
	w.m = m;
	for (isize i = 0; i < xbCoff_COUNT; i++) {
		w.sec[i] = array_make<u8>(heap_allocator(), 0, 0);
		w.relocs[i] = array_make<xbCoffReloc>(heap_allocator(), 0, 0);
		w.align[i] = 1;
	}
	auto copy_section = [&](xbCoffSec to, xbSection from) {
		array_add_elems(&w.sec[to], m->sections[from].data, m->sections[from].count);
		w.align[to] = gb_max(w.align[to], gb_max(m->section_align[from], cast(i64)16));
	};
	copy_section(xbCoff_Text, xbSection_Text);
	copy_section(xbCoff_Rdata, xbSection_Rodata);
	copy_section(xbCoff_Data, xbSection_Data);
	copy_section(xbCoff_Tls, xbSection_TData);
	w.align[xbCoff_Bss] = gb_max(m->section_align[xbSection_Bss], cast(i64)16);
	w.bss_size = m->nobits_size[xbSection_Bss];
	{
		// .tbss has no COFF counterpart, its zeros go after .tdata
		i64 a = gb_max(m->section_align[xbSection_TBss], cast(i64)1);
		w.align[xbCoff_Tls] = gb_max(w.align[xbCoff_Tls], a);
		xbb_align(&w.sec[xbCoff_Tls], cast(isize)a);
		w.tbss_base = w.sec[xbCoff_Tls].count;
		for (i64 i = 0; i < m->nobits_size[xbSection_TBss]; i++) xbb_u8(&w.sec[xbCoff_Tls], 0);
	}
	w.align[xbCoff_Pdata] = 4;
	w.align[xbCoff_Xdata] = 4;
	w.align[xbCoff_DebugS] = 4;
	w.align[xbCoff_DebugT] = 4;

	xb_coff_unwind(&w);
	if (build_context.ODIN_DEBUG) {
		xb_codeview_emit(&w);
	}

	// exports
	for (xbSymbol const &s : m->symbols) {
		if ((s.flags & xbSymbolFlag_Export) == 0 || s.section == xbSection_Undef) continue;
		Array<u8> *d = &w.sec[xbCoff_Drectve];
		xbb_bytes(d, " /EXPORT:", 9);
		if (xb_coff_needs_quotes(s.name)) {
			xbb_u8(d, '"'); xbb_bytes(d, s.name.text, s.name.len); xbb_u8(d, '"');
		} else {
			xbb_bytes(d, s.name.text, s.name.len);
		}
		if ((s.flags & xbSymbolFlag_Func) == 0) xbb_bytes(d, ",DATA", 5);
	}

	// which sections exist, numbered from 1
	char const *names[xbCoff_COUNT] = {".text", ".rdata", ".data", ".bss", ".tls$", ".pdata", ".xdata", ".drectve", ".debug$S", ".debug$T"};
	i16 number[xbCoff_COUNT] = {};
	i16 section_count = 0;
	for (isize i = 0; i < xbCoff_COUNT; i++) {
		bool present = i == xbCoff_Bss ? w.bss_size > 0 : w.sec[i].count > 0;
		if (i == xbCoff_Text) present = true;
		if (present) number[i] = ++section_count;
	}

	// symbols: section symbols, then the module's
	auto syms = array_make<xbCoffSym>(heap_allocator(), 0, m->symbols.count + 64);
	u32 sym_count = 0; // with aux records
	u32 section_sym[xbCoff_COUNT] = {};
	auto add_sym = [&](xbCoffSym const &s) -> u32 {
		u32 index = sym_count;
		array_add(&syms, s);
		sym_count += 1 + s.aux_count;
		return index;
	};
	for (isize i = 0; i < xbCoff_COUNT; i++) {
		if (number[i] == 0) continue;
		xbCoffSym s = {};
		s.name = make_string_c(names[i]);
		s.section = number[i];
		s.storage_class = 3; // static
		s.aux_count = 1;
		u32 length = cast(u32)(i == xbCoff_Bss ? w.bss_size : w.sec[i].count);
		gb_memmove(s.aux + 0, &length, 4);
		u16 num = cast(u16)number[i];
		gb_memmove(s.aux + 12, &num, 2);
		section_sym[i] = add_sym(s);
	}

	// lld-link reports every undefined symbol, so only the referenced ones go in
	auto referenced = array_make<bool>(heap_allocator(), m->symbols.count);
	for (xbReloc const &r : m->relocs) referenced[r.sym] = true;
	for (isize i = 0; i < xbCoff_COUNT; i++) {
		for (xbCoffReloc const &r : w.relocs[i]) if (r.sym >= 0) referenced[r.sym] = true;
	}

	auto sym_index = array_make<i64>(heap_allocator(), m->symbols.count);
	for_array(i, m->symbols) {
		xbSymbol const &s = m->symbols[i];
		sym_index[i] = -1;
		if ((s.flags & xbSymbolFlag_Global) == 0) continue; // referenced through its section symbol
		if (s.section == xbSection_Undef && !referenced[i]) continue;
		xbCoffSym cs = {};
		cs.name = s.name;
		cs.type = (s.flags & xbSymbolFlag_Func) ? 0x20 : 0;
		cs.storage_class = 2; // external
		if (s.section != xbSection_Undef) {
			xbCoffSec cs_sec = xb_coff_section_of(s.section);
			cs.section = number[cs_sec];
			cs.value = cast(u32)xb_coff_symbol_offset(&w, s);
		}
		if (s.section != xbSection_Undef && (s.flags & xbSymbolFlag_Weak)) {
			// a weak definition: a weak external that falls back to a uniquely named default, like LLVM's
			xbCoffSym def = cs;
			def.name = concatenate3_strings(permanent_allocator(), str_lit(".weak."), s.name, str_lit(".default.odin-x64"));
			u32 def_index = add_sym(def);
			xbCoffSym weak = {};
			weak.name = s.name;
			weak.type = cs.type;
			weak.storage_class = 105; // weak external
			weak.aux_count = 1;
			gb_memmove(weak.aux + 0, &def_index, 4);
			u32 search_alias = 3;
			gb_memmove(weak.aux + 4, &search_alias, 4);
			sym_index[i] = add_sym(weak);
		} else {
			sym_index[i] = add_sym(cs);
		}
	}

	// relocations, with the addend written into the section's bytes
	struct OutReloc { u32 offset; u32 sym; u16 type; };
	Array<OutReloc> out_relocs[xbCoff_COUNT] = {};
	for (isize i = 0; i < xbCoff_COUNT; i++) {
		out_relocs[i] = array_make<OutReloc>(heap_allocator(), 0, w.relocs[i].count);
	}
	auto write_addend = [&](xbCoffSec in, u32 offset, u16 type, i64 value) {
		u8 *p = w.sec[in].data + offset;
		if (type == XB_IMAGE_REL_AMD64_ADDR64) {
			gb_memmove(p, &value, 8);
		} else if (type == XB_IMAGE_REL_AMD64_SECTION) {
			u16 v = cast(u16)value;
			gb_memmove(p, &v, 2);
		} else {
			i32 v = cast(i32)value;
			gb_memmove(p, &v, 4);
		}
	};
	for (xbReloc const &r : m->relocs) {
		xbCoffSec in = xb_coff_section_of(r.section);
		xbSymbol const &s = m->symbols[r.sym];
		u32 target = 0;
		i64 base = 0;
		if (sym_index[r.sym] >= 0) {
			target = cast(u32)sym_index[r.sym];
		} else {
			GB_ASSERT_MSG(s.section != xbSection_Undef, "undefined local symbol %.*s", LIT(s.name));
			target = section_sym[xb_coff_section_of(s.section)];
			base = xb_coff_symbol_offset(&w, s);
		}
		u16 type = 0;
		i64 addend = r.addend + base;
		switch (r.kind) {
		case xbReloc_PC32:
		case xbReloc_PLT32:
			type = XB_IMAGE_REL_AMD64_REL32;
			addend += 4; // COFF counts from the end of the field
			break;
		case xbReloc_Abs64:    type = XB_IMAGE_REL_AMD64_ADDR64; break;
		case xbReloc_Abs32:    type = XB_IMAGE_REL_AMD64_ADDR32; break;
		case xbReloc_SecRel32: type = XB_IMAGE_REL_AMD64_SECREL; break;
		default:
			GB_PANIC("fast backend: relocation kind %d has no COFF form", r.kind);
		}
		u32 offset = cast(u32)r.offset;
		if (r.section == xbSection_TBss) offset += cast(u32)w.tbss_base;
		write_addend(in, offset, type, addend);
		OutReloc o = {offset, target, type};
		array_add(&out_relocs[in], o);
	}
	for (isize i = 0; i < xbCoff_COUNT; i++) {
		if (number[i] == 0) continue;
		// the section symbol's aux record carries the count
		u16 nrel = cast(u16)gb_min(out_relocs[i].count + w.relocs[i].count, cast(isize)0xffff);
		for (xbCoffSym &cs : syms) {
			if (cs.storage_class == 3 && cs.section == number[i]) gb_memmove(cs.aux + 4, &nrel, 2);
		}
		for (xbCoffReloc const &r : w.relocs[i]) {
			u32 target = 0;
			if (r.sym >= 0) {
				GB_ASSERT(sym_index[r.sym] >= 0);
				target = cast(u32)sym_index[r.sym];
			} else {
				target = section_sym[r.sym_section];
			}
			OutReloc o = {r.offset, target, r.type};
			array_add(&out_relocs[i], o);
		}
	}

	// string table
	auto strtab = array_make<u8>(heap_allocator(), 0, 4096);
	xbb_u32(&strtab, 0);

	// layout: header, section headers, section data with relocations, symbols, strings
	auto out = array_make<u8>(heap_allocator(), 0, 1024 + w.sec[xbCoff_Text].count*2);
	isize header_size = 20 + 40*section_count;
	out.count = header_size;
	gb_zero_size(out.data, header_size);

	u8 *hdr_base = nullptr;
	isize sh_at = 20;
	struct SecHdr {
		u8  name[8];
		u32 virtual_size, virtual_address, size_of_raw_data, pointer_to_raw_data;
		u32 pointer_to_relocations, pointer_to_linenumbers;
		u16 number_of_relocations, number_of_linenumbers;
		u32 characteristics;
	};
	GB_STATIC_ASSERT(gb_size_of(SecHdr) == 40);
	u32 const CNT_CODE = 0x20, CNT_INIT = 0x40, CNT_UNINIT = 0x80, LNK_INFO = 0x200, LNK_REMOVE = 0x800;
	u32 const NRELOC_OVFL = 0x01000000, DISCARDABLE = 0x02000000, MEM_EXEC = 0x20000000, MEM_READ = 0x40000000, MEM_WRITE = 0x80000000;
	SecHdr headers[xbCoff_COUNT] = {};
	for (isize i = 0; i < xbCoff_COUNT; i++) {
		if (number[i] == 0) continue;
		SecHdr &h = headers[i];
		String n = make_string_c(names[i]);
		gb_memmove(h.name, n.text, gb_min(n.len, cast(isize)8));
		u32 flags = 0;
		switch (i) {
		case xbCoff_Text:    flags = CNT_CODE | MEM_EXEC | MEM_READ; break;
		case xbCoff_Rdata:   flags = CNT_INIT | MEM_READ; break;
		case xbCoff_Data:    flags = CNT_INIT | MEM_READ | MEM_WRITE; break;
		case xbCoff_Bss:     flags = CNT_UNINIT | MEM_READ | MEM_WRITE; break;
		case xbCoff_Tls:     flags = CNT_INIT | MEM_READ | MEM_WRITE; break;
		case xbCoff_Pdata:   flags = CNT_INIT | MEM_READ; break;
		case xbCoff_Xdata:   flags = CNT_INIT | MEM_READ; break;
		case xbCoff_Drectve: flags = LNK_INFO | LNK_REMOVE; break;
		case xbCoff_DebugS:  flags = CNT_INIT | MEM_READ | DISCARDABLE; break;
		case xbCoff_DebugT:  flags = CNT_INIT | MEM_READ | DISCARDABLE; break;
		}
		flags |= xb_coff_align_flag(w.align[i]);
		if (i == xbCoff_Bss) {
			h.size_of_raw_data = cast(u32)w.bss_size;
		} else {
			xbb_align(&out, 16);
			h.pointer_to_raw_data = w.sec[i].count > 0 ? cast(u32)out.count : 0;
			h.size_of_raw_data = cast(u32)w.sec[i].count;
			xbb_bytes(&out, w.sec[i].data, w.sec[i].count);
		}
		isize nrel = out_relocs[i].count;
		if (nrel > 0) {
			xbb_align(&out, 2);
			h.pointer_to_relocations = cast(u32)out.count;
			if (nrel >= 0xffff) {
				// the real count goes in the first entry
				flags |= NRELOC_OVFL;
				h.number_of_relocations = 0xffff;
				xbb_u32(&out, cast(u32)(nrel + 1));
				xbb_u32(&out, 0);
				xbb_u16(&out, 0);
			} else {
				h.number_of_relocations = cast(u16)nrel;
			}
			for (OutReloc const &r : out_relocs[i]) {
				xbb_u32(&out, r.offset);
				xbb_u32(&out, r.sym);
				xbb_u16(&out, r.type);
			}
		}
		h.characteristics = flags;
	}
	gb_unused(hdr_base);
	for (isize i = 0; i < xbCoff_COUNT; i++) {
		if (number[i] == 0) continue;
		gb_memmove(out.data + sh_at + 40*(number[i]-1), &headers[i], 40);
	}

	xbb_align(&out, 4);
	u32 symtab_at = cast(u32)out.count;
	for (xbCoffSym const &s : syms) {
		u8 rec[18] = {};
		if (s.name.len <= 8) {
			gb_memmove(rec, s.name.text, s.name.len);
		} else {
			u32 off = cast(u32)strtab.count;
			xbb_bytes(&strtab, s.name.text, s.name.len);
			xbb_u8(&strtab, 0);
			gb_memmove(rec + 4, &off, 4);
		}
		gb_memmove(rec + 8, &s.value, 4);
		gb_memmove(rec + 12, &s.section, 2);
		gb_memmove(rec + 14, &s.type, 2);
		rec[16] = s.storage_class;
		rec[17] = s.aux_count;
		xbb_bytes(&out, rec, 18);
		if (s.aux_count) xbb_bytes(&out, s.aux, 18);
	}
	u32 strtab_size = cast(u32)strtab.count;
	gb_memmove(strtab.data, &strtab_size, 4);
	xbb_bytes(&out, strtab.data, strtab.count);

	u16 machine = 0x8664;
	u16 nsec = cast(u16)section_count;
	u32 zero = 0;
	gb_memmove(out.data + 0, &machine, 2);
	gb_memmove(out.data + 2, &nsec, 2);
	gb_memmove(out.data + 4, &zero, 4); // timestamp
	gb_memmove(out.data + 8, &symtab_at, 4);
	gb_memmove(out.data + 12, &sym_count, 4);

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
