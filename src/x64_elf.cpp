// ELF64 relocatable object writer, with .eh_frame and DWARF 4 debug info.

#include <initializer_list>
#include <utility>
#include <unistd.h>

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
};

struct xbBuf {
	Array<u8> data;
};

gb_internal void xbb_u8 (Array<u8> *b, u8  v) { array_add(b, v); }
gb_internal void xbb_u16(Array<u8> *b, u16 v) { array_add_elems(b, cast(u8 *)&v, 2); }
gb_internal void xbb_u32(Array<u8> *b, u32 v) { array_add_elems(b, cast(u8 *)&v, 4); }
gb_internal void xbb_u64(Array<u8> *b, u64 v) { array_add_elems(b, cast(u8 *)&v, 8); }
gb_internal void xbb_bytes(Array<u8> *b, void const *p, isize n) { array_add_elems(b, cast(u8 const *)p, n); }
gb_internal void xbb_str(Array<u8> *b, String s) {
	array_add_elems(b, s.text, s.len);
	array_add(b, cast(u8)0);
}
gb_internal void xbb_cstr(Array<u8> *b, char const *s) {
	xbb_str(b, make_string_c(s));
}
gb_internal void xbb_uleb(Array<u8> *b, u64 v) {
	do {
		u8 byte = v & 0x7f;
		v >>= 7;
		if (v != 0) byte |= 0x80;
		array_add(b, byte);
	} while (v != 0);
}
gb_internal void xbb_sleb(Array<u8> *b, i64 v) {
	bool more = true;
	while (more) {
		u8 byte = v & 0x7f;
		v >>= 7;
		if ((v == 0 && (byte & 0x40) == 0) || (v == -1 && (byte & 0x40) != 0)) {
			more = false;
		} else {
			byte |= 0x80;
		}
		array_add(b, byte);
	}
}
gb_internal void xbb_align(Array<u8> *b, isize align, u8 fill=0) {
	while (b->count % align != 0) array_add(b, fill);
}
gb_internal void xbb_patch_u32(Array<u8> *b, isize at, u32 v) {
	gb_memmove(b->data + at, &v, 4);
}

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
// DWARF
////////////////////////////////////////////////////////////////

enum {
	XDW_TAG_array_type       = 0x01,
	XDW_TAG_enumeration_type = 0x04,
	XDW_TAG_formal_parameter = 0x05,
	XDW_TAG_member           = 0x0d,
	XDW_TAG_pointer_type     = 0x0f,
	XDW_TAG_compile_unit     = 0x11,
	XDW_TAG_structure_type   = 0x13,
	XDW_TAG_typedef          = 0x16,
	XDW_TAG_union_type       = 0x17,
	XDW_TAG_subroutine_type  = 0x15,
	XDW_TAG_subrange_type    = 0x21,
	XDW_TAG_base_type        = 0x24,
	XDW_TAG_enumerator       = 0x28,
	XDW_TAG_subprogram       = 0x2e,
	XDW_TAG_variable         = 0x34,

	XDW_CHILDREN_no  = 0,
	XDW_CHILDREN_yes = 1,

	XDW_AT_location        = 0x02,
	XDW_AT_name            = 0x03,
	XDW_AT_byte_size       = 0x0b,
	XDW_AT_bit_size        = 0x0d,
	XDW_AT_stmt_list       = 0x10,
	XDW_AT_low_pc          = 0x11,
	XDW_AT_high_pc         = 0x12,
	XDW_AT_language        = 0x13,
	XDW_AT_comp_dir        = 0x1b,
	XDW_AT_const_value     = 0x1c,
	XDW_AT_upper_bound     = 0x2f,
	XDW_AT_producer        = 0x25,
	XDW_AT_count           = 0x37,
	XDW_AT_data_member_location = 0x38,
	XDW_AT_decl_file       = 0x3a,
	XDW_AT_decl_line       = 0x3b,
	XDW_AT_encoding        = 0x3e,
	XDW_AT_external        = 0x3f,
	XDW_AT_frame_base      = 0x40,
	XDW_AT_type            = 0x49,
	XDW_AT_data_bit_offset = 0x6b,
	XDW_AT_linkage_name    = 0x6e,

	XDW_FORM_addr         = 0x01,
	XDW_FORM_data2        = 0x05,
	XDW_FORM_data4        = 0x06,
	XDW_FORM_data8        = 0x07,
	XDW_FORM_string       = 0x08,
	XDW_FORM_data1        = 0x0b,
	XDW_FORM_sdata        = 0x0d,
	XDW_FORM_udata        = 0x0f,
	XDW_FORM_ref4         = 0x13,
	XDW_FORM_sec_offset   = 0x17,
	XDW_FORM_exprloc      = 0x18,
	XDW_FORM_flag_present = 0x19,

	XDW_ATE_boolean  = 0x02,
	XDW_ATE_float    = 0x04,
	XDW_ATE_signed   = 0x05,
	XDW_ATE_unsigned = 0x08,
	XDW_ATE_unsigned_char = 0x08,

	XDW_OP_addr    = 0x03,
	XDW_OP_deref   = 0x06,
	XDW_OP_const8u = 0x0e,
	XDW_OP_GNU_push_tls_address = 0xe0,
	XDW_OP_fbreg = 0x91,
	XDW_OP_reg0  = 0x50,
	XDW_OP_reg6  = 0x56,

	XDW_LANG_C99 = 0x0c,
};

enum xbAbbrev {
	xbAbbrev_None,
	xbAbbrev_CompileUnit,
	xbAbbrev_Subprogram,
	xbAbbrev_SubprogramNoChildren,
	xbAbbrev_Param,
	xbAbbrev_Var,
	xbAbbrev_BaseType,
	xbAbbrev_PointerType,
	xbAbbrev_StructType,
	xbAbbrev_Member,
	xbAbbrev_ArrayType,
	xbAbbrev_Subrange,
	xbAbbrev_Typedef,
	xbAbbrev_EnumType,
	xbAbbrev_Enumerator,
	xbAbbrev_UnionType,
	xbAbbrev_GlobalVar,
	xbAbbrev_Constant,
	xbAbbrev_EmptyStructType,
	xbAbbrev_BitMember,
	xbAbbrev_SubroutineType,
	xbAbbrev_SubprogramRet,
	xbAbbrev_SubprogramRetNoChildren,
	xbAbbrev_NamedPointerType,
	xbAbbrev_Enumerator64,
};

gb_internal void xb_dwarf_abbrevs(Array<u8> *b) {
	auto abbrev = [&](xbAbbrev code, u32 tag, bool children, std::initializer_list<u32> attrs) {
		xbb_uleb(b, code);
		xbb_uleb(b, tag);
		xbb_u8(b, children ? XDW_CHILDREN_yes : XDW_CHILDREN_no);
		u32 const *it = attrs.begin();
		for (isize i = 0; i < cast(isize)attrs.size(); i += 2) {
			xbb_uleb(b, it[i]);
			xbb_uleb(b, it[i+1]);
		}
		xbb_u8(b, 0);
		xbb_u8(b, 0);
	};
	abbrev(xbAbbrev_CompileUnit, XDW_TAG_compile_unit, true, {
		XDW_AT_producer, XDW_FORM_string,
		XDW_AT_language, XDW_FORM_data2,
		XDW_AT_name, XDW_FORM_string,
		XDW_AT_comp_dir, XDW_FORM_string,
		XDW_AT_low_pc, XDW_FORM_addr,
		XDW_AT_high_pc, XDW_FORM_data8,
		XDW_AT_stmt_list, XDW_FORM_sec_offset,
	});
	abbrev(xbAbbrev_Subprogram, XDW_TAG_subprogram, true, {
		XDW_AT_name, XDW_FORM_string,
		XDW_AT_linkage_name, XDW_FORM_string,
		XDW_AT_low_pc, XDW_FORM_addr,
		XDW_AT_high_pc, XDW_FORM_data4,
		XDW_AT_frame_base, XDW_FORM_exprloc,
		XDW_AT_decl_file, XDW_FORM_udata,
		XDW_AT_decl_line, XDW_FORM_udata,
		XDW_AT_external, XDW_FORM_flag_present,
	});
	abbrev(xbAbbrev_SubprogramNoChildren, XDW_TAG_subprogram, false, {
		XDW_AT_name, XDW_FORM_string,
		XDW_AT_linkage_name, XDW_FORM_string,
		XDW_AT_low_pc, XDW_FORM_addr,
		XDW_AT_high_pc, XDW_FORM_data4,
		XDW_AT_frame_base, XDW_FORM_exprloc,
		XDW_AT_decl_file, XDW_FORM_udata,
		XDW_AT_decl_line, XDW_FORM_udata,
		XDW_AT_external, XDW_FORM_flag_present,
	});
	abbrev(xbAbbrev_SubprogramRet, XDW_TAG_subprogram, true, {
		XDW_AT_name, XDW_FORM_string,
		XDW_AT_linkage_name, XDW_FORM_string,
		XDW_AT_low_pc, XDW_FORM_addr,
		XDW_AT_high_pc, XDW_FORM_data4,
		XDW_AT_frame_base, XDW_FORM_exprloc,
		XDW_AT_decl_file, XDW_FORM_udata,
		XDW_AT_decl_line, XDW_FORM_udata,
		XDW_AT_external, XDW_FORM_flag_present,
		XDW_AT_type, XDW_FORM_ref4,
	});
	abbrev(xbAbbrev_SubprogramRetNoChildren, XDW_TAG_subprogram, false, {
		XDW_AT_name, XDW_FORM_string,
		XDW_AT_linkage_name, XDW_FORM_string,
		XDW_AT_low_pc, XDW_FORM_addr,
		XDW_AT_high_pc, XDW_FORM_data4,
		XDW_AT_frame_base, XDW_FORM_exprloc,
		XDW_AT_decl_file, XDW_FORM_udata,
		XDW_AT_decl_line, XDW_FORM_udata,
		XDW_AT_external, XDW_FORM_flag_present,
		XDW_AT_type, XDW_FORM_ref4,
	});
	abbrev(xbAbbrev_Param, XDW_TAG_formal_parameter, false, {
		XDW_AT_name, XDW_FORM_string,
		XDW_AT_location, XDW_FORM_exprloc,
		XDW_AT_decl_line, XDW_FORM_udata,
		XDW_AT_type, XDW_FORM_ref4,
	});
	abbrev(xbAbbrev_Var, XDW_TAG_variable, false, {
		XDW_AT_name, XDW_FORM_string,
		XDW_AT_location, XDW_FORM_exprloc,
		XDW_AT_decl_line, XDW_FORM_udata,
		XDW_AT_type, XDW_FORM_ref4,
	});
	abbrev(xbAbbrev_BaseType, XDW_TAG_base_type, false, {
		XDW_AT_name, XDW_FORM_string,
		XDW_AT_encoding, XDW_FORM_data1,
		XDW_AT_byte_size, XDW_FORM_udata,
	});
	abbrev(xbAbbrev_PointerType, XDW_TAG_pointer_type, false, {
		XDW_AT_byte_size, XDW_FORM_data1,
		XDW_AT_type, XDW_FORM_ref4,
	});
	abbrev(xbAbbrev_NamedPointerType, XDW_TAG_pointer_type, false, {
		XDW_AT_name, XDW_FORM_string,
		XDW_AT_byte_size, XDW_FORM_data1,
		XDW_AT_type, XDW_FORM_ref4,
	});
	abbrev(xbAbbrev_StructType, XDW_TAG_structure_type, true, {
		XDW_AT_name, XDW_FORM_string,
		XDW_AT_byte_size, XDW_FORM_udata,
	});
	abbrev(xbAbbrev_Member, XDW_TAG_member, false, {
		XDW_AT_name, XDW_FORM_string,
		XDW_AT_type, XDW_FORM_ref4,
		XDW_AT_data_member_location, XDW_FORM_udata,
	});
	abbrev(xbAbbrev_ArrayType, XDW_TAG_array_type, true, {
		XDW_AT_name, XDW_FORM_string,
		XDW_AT_type, XDW_FORM_ref4,
	});
	abbrev(xbAbbrev_Subrange, XDW_TAG_subrange_type, false, {
		XDW_AT_count, XDW_FORM_udata,
	});
	abbrev(xbAbbrev_Typedef, XDW_TAG_typedef, false, {
		XDW_AT_name, XDW_FORM_string,
		XDW_AT_type, XDW_FORM_ref4,
	});
	abbrev(xbAbbrev_EnumType, XDW_TAG_enumeration_type, true, {
		XDW_AT_name, XDW_FORM_string,
		XDW_AT_type, XDW_FORM_ref4,
		XDW_AT_byte_size, XDW_FORM_udata,
	});
	abbrev(xbAbbrev_Enumerator, XDW_TAG_enumerator, false, {
		XDW_AT_name, XDW_FORM_string,
		XDW_AT_const_value, XDW_FORM_sdata,
	});
	abbrev(xbAbbrev_Enumerator64, XDW_TAG_enumerator, false, {
		XDW_AT_name, XDW_FORM_string,
		XDW_AT_const_value, XDW_FORM_data8,
	});
	abbrev(xbAbbrev_UnionType, XDW_TAG_union_type, true, {
		XDW_AT_name, XDW_FORM_string,
		XDW_AT_byte_size, XDW_FORM_udata,
	});
	abbrev(xbAbbrev_EmptyStructType, XDW_TAG_structure_type, false, {
		XDW_AT_name, XDW_FORM_string,
		XDW_AT_byte_size, XDW_FORM_udata,
	});
	abbrev(xbAbbrev_BitMember, XDW_TAG_member, false, {
		XDW_AT_name, XDW_FORM_string,
		XDW_AT_type, XDW_FORM_ref4,
		XDW_AT_bit_size, XDW_FORM_udata,
		XDW_AT_data_bit_offset, XDW_FORM_udata,
	});
	abbrev(xbAbbrev_SubroutineType, XDW_TAG_subroutine_type, false, {});
	abbrev(xbAbbrev_GlobalVar, XDW_TAG_variable, false, {
		XDW_AT_name, XDW_FORM_string,
		XDW_AT_type, XDW_FORM_ref4,
		XDW_AT_external, XDW_FORM_flag_present,
		XDW_AT_decl_file, XDW_FORM_udata,
		XDW_AT_decl_line, XDW_FORM_udata,
		XDW_AT_location, XDW_FORM_exprloc,
	});
	abbrev(xbAbbrev_Constant, XDW_TAG_variable, false, {
		XDW_AT_name, XDW_FORM_string,
		XDW_AT_type, XDW_FORM_ref4,
		XDW_AT_external, XDW_FORM_flag_present,
		XDW_AT_const_value, XDW_FORM_sdata,
	});
	xbb_u8(b, 0);
}

struct xbDwarfTypes {
	Array<u8> *info;
	PtrMap<Type *, u32> offsets;  // type -> DIE offset in .debug_info
	// types whose DIE is referenced before it is written
	struct Pending { isize at; Type *type; };
	Array<Pending> pending;
	Array<Type *> queue;
	PtrSet<Type *> queued;
	u32 void_ptr;
	u32 byte_type;
	isize cu_start;
	CheckerInfo *checker;
};

gb_internal u32 xb_dwarf_type_ref(xbDwarfTypes *dt, Type *t) {
	// writes a ref4 placeholder, patched once the type is written
	t = default_type(t);
	isize at = dt->info->count;
	xbb_u32(dt->info, 0);
	xbDwarfTypes::Pending pd = {at, t};
	array_add(&dt->pending, pd);
	if (!ptr_set_exists(&dt->queued, t)) {
		ptr_set_add(&dt->queued, t);
		array_add(&dt->queue, t);
	}
	return 0;
}

// a member of one bit, or of a bit_field's bits
gb_internal void xb_dwarf_bit_member(xbDwarfTypes *dt, String name, Type *type, u64 bit_size, u64 bit_offset) {
	Array<u8> *b = dt->info;
	xbb_uleb(b, xbAbbrev_BitMember);
	xbb_str(b, name);
	xb_dwarf_type_ref(dt, type);
	xbb_uleb(b, bit_size);
	xbb_uleb(b, bit_offset);
}

gb_internal void xb_dwarf_write_struct_like(xbDwarfTypes *dt, Type *t, String name, std::initializer_list<std::pair<char const *, Type *>> fields) {
	Array<u8> *b = dt->info;
	xbb_uleb(b, xbAbbrev_StructType);
	xbb_str(b, name);
	xbb_uleb(b, cast(u64)type_size_of(t));
	i64 off = 0;
	for (auto const &f : fields) {
		i64 align = type_align_of(f.second);
		off = (off + align - 1) / align * align;
		xbb_uleb(b, xbAbbrev_Member);
		xbb_cstr(b, f.first);
		xb_dwarf_type_ref(dt, f.second);
		xbb_uleb(b, cast(u64)off);
		off += type_size_of(f.second);
	}
	xbb_u8(b, 0);
}

// a pointer to a character type, `char` or `wchar_t` like LLVM's: the pointer, then the typedef and base type it points to
gb_internal void xb_dwarf_char_pointer(xbDwarfTypes *dt, char const *name, char const *char_name, i64 char_size) {
	Array<u8> *b = dt->info;
	if (name != nullptr) {
		xbb_uleb(b, xbAbbrev_NamedPointerType);
		xbb_cstr(b, name);
	} else {
		xbb_uleb(b, xbAbbrev_PointerType);
	}
	xbb_u8(b, 8);
	xbb_u32(b, cast(u32)(b->count + 4 - dt->cu_start));
	xbb_uleb(b, xbAbbrev_Typedef);
	xbb_cstr(b, char_name);
	xbb_u32(b, cast(u32)(b->count + 4 - dt->cu_start));
	xbb_uleb(b, xbAbbrev_BaseType);
	xbb_cstr(b, char_name);
	xbb_u8(b, XDW_ATE_unsigned);
	xbb_uleb(b, cast(u64)char_size);
}

struct xbDwarfNamedType {
	String name;
	Type * type;
};

gb_internal GB_COMPARE_PROC(xb_dwarf_named_type_cmp) {
	return string_compare((cast(xbDwarfNamedType const *)a)->name, (cast(xbDwarfNamedType const *)b)->name);
}

// `typeid` as an enum of the type table by canonical name, like lb_debug_typeid_enum
gb_internal void xb_dwarf_typeid_enum(xbDwarfTypes *dt, CheckerInfo *info) {
	Array<u8> *b = dt->info;
	auto types = array_make<xbDwarfNamedType>(heap_allocator(), 0, info->type_info_types_hash_map.count);
	for (TypeInfoPair const &tt : info->type_info_types_hash_map) {
		if (tt.type != nullptr && tt.type != t_invalid) {
			array_add(&types, xbDwarfNamedType{type_to_canonical_string(temporary_allocator(), tt.type), tt.type});
		}
	}
	array_sort(types, xb_dwarf_named_type_cmp);
	xbb_uleb(b, xbAbbrev_EnumType);
	xbb_cstr(b, "typeid");
	xb_dwarf_type_ref(dt, t_u64);
	xbb_uleb(b, 8);
	for (xbDwarfNamedType const &nt : types) {
		xbb_uleb(b, xbAbbrev_Enumerator64);
		xbb_str(b, nt.name);
		xbb_u64(b, type_hash_canonical_type(nt.type));
	}
	xbb_u8(b, 0);
	array_free(&types);
}

gb_internal void xb_dwarf_write_type(xbDwarfTypes *dt, Type *t) {
	Array<u8> *b = dt->info;
	map_set(&dt->offsets, t, cast(u32)b->count);
	TEMPORARY_ALLOCATOR_GUARD();
	// the names LLVM gives them, with the package
	String name = type_to_canonical_string(temporary_allocator(), t);
	Type *bt = base_type(t);

	if (t->kind == Type_Named && bt->kind != Type_Struct && bt->kind != Type_Union && bt->kind != Type_Enum) {
		xbb_uleb(b, xbAbbrev_Typedef);
		xbb_str(b, name);
		xb_dwarf_type_ref(dt, bt);
		return;
	}

	switch (bt->kind) {
	case Type_Basic: {
		u8 enc = 0;
		i64 size = type_size_of(bt);
		switch (bt->Basic.kind) {
		case Basic_bool: case Basic_b8: case Basic_b16: case Basic_b32: case Basic_b64: case Basic_llvm_bool:
			enc = XDW_ATE_boolean; break;
		case Basic_rune:
			enc = XDW_ATE_signed; break;
		case Basic_f16: case Basic_f32: case Basic_f64:
		case Basic_f16le: case Basic_f32le: case Basic_f64le:
		case Basic_f16be: case Basic_f32be: case Basic_f64be:
			enc = XDW_ATE_float; break;
		case Basic_rawptr:
			xb_dwarf_char_pointer(dt, "rawptr", "void", 1);
			return;
		case Basic_cstring:
			xb_dwarf_char_pointer(dt, "cstring", "char", 1);
			return;
		case Basic_cstring16:
			xb_dwarf_char_pointer(dt, "cstring16", "wchar_t", 2);
			return;
		case Basic_string:
			xb_dwarf_write_struct_like(dt, bt, name, {{"data", t_u8_ptr}, {"len", t_int}});
			return;
		case Basic_string16: {
			// the data is a `wchar_t` pointer, written after the struct
			xbb_uleb(b, xbAbbrev_StructType);
			xbb_str(b, name);
			xbb_uleb(b, 16);
			xbb_uleb(b, xbAbbrev_Member);
			xbb_cstr(b, "data");
			isize data_ref = b->count;
			xbb_u32(b, 0);
			xbb_uleb(b, 0);
			xbb_uleb(b, xbAbbrev_Member);
			xbb_cstr(b, "len");
			xb_dwarf_type_ref(dt, t_int);
			xbb_uleb(b, 8);
			xbb_u8(b, 0);
			xbb_patch_u32(b, data_ref, cast(u32)(b->count - dt->cu_start));
			xb_dwarf_char_pointer(dt, nullptr, "wchar_t", 2);
			return;
		}
		case Basic_any:
			xb_dwarf_write_struct_like(dt, bt, name, {{"data", t_rawptr}, {"id", t_typeid}});
			return;
		case Basic_typeid:
			if (!build_context.no_rtti) {
				xb_dwarf_typeid_enum(dt, dt->checker);
				return;
			}
			enc = XDW_ATE_unsigned; break;
		default:
			if (bt->Basic.flags & BasicFlag_Integer) {
				enc = (bt->Basic.flags & BasicFlag_Unsigned) ? XDW_ATE_unsigned : XDW_ATE_signed;
			} else {
				// complex, quaternion, string16, ...: raw bytes
				xbb_uleb(b, xbAbbrev_ArrayType);
				xbb_str(b, name);
				xb_dwarf_type_ref(dt, t_u8);
				xbb_uleb(b, xbAbbrev_Subrange);
				xbb_uleb(b, cast(u64)size);
				xbb_u8(b, 0);
				return;
			}
		}
		xbb_uleb(b, xbAbbrev_BaseType);
		xbb_str(b, name);
		xbb_u8(b, enc);
		xbb_uleb(b, cast(u64)size);
		return;
	}
	case Type_Pointer:
		xbb_uleb(b, xbAbbrev_PointerType);
		xbb_u8(b, 8);
		xb_dwarf_type_ref(dt, bt->Pointer.elem);
		return;
	case Type_MultiPointer:
		xbb_uleb(b, xbAbbrev_PointerType);
		xbb_u8(b, 8);
		xb_dwarf_type_ref(dt, bt->MultiPointer.elem);
		return;
	case Type_Proc:
		// named pointer to a subroutine, the two written right after the name
		xbb_uleb(b, xbAbbrev_Typedef);
		xbb_str(b, name);
		xbb_u32(b, cast(u32)(b->count + 4 - dt->cu_start));
		xbb_uleb(b, xbAbbrev_PointerType);
		xbb_u8(b, 8);
		xbb_u32(b, cast(u32)(b->count + 4 - dt->cu_start));
		xbb_uleb(b, xbAbbrev_SubroutineType);
		return;
	case Type_Array:
		xbb_uleb(b, xbAbbrev_ArrayType);
		xbb_str(b, name);
		xb_dwarf_type_ref(dt, bt->Array.elem);
		xbb_uleb(b, xbAbbrev_Subrange);
		xbb_uleb(b, cast(u64)bt->Array.count);
		xbb_u8(b, 0);
		return;
	case Type_EnumeratedArray:
		xbb_uleb(b, xbAbbrev_ArrayType);
		xbb_str(b, name);
		xb_dwarf_type_ref(dt, bt->EnumeratedArray.elem);
		xbb_uleb(b, xbAbbrev_Subrange);
		xbb_uleb(b, cast(u64)bt->EnumeratedArray.count);
		xbb_u8(b, 0);
		return;
	case Type_Slice:
		xb_dwarf_write_struct_like(dt, bt, name, {{"data", alloc_type_pointer(bt->Slice.elem)}, {"len", t_int}});
		return;
	case Type_DynamicArray:
		xb_dwarf_write_struct_like(dt, bt, name, {{"data", alloc_type_pointer(bt->DynamicArray.elem)}, {"len", t_int}, {"cap", t_int}, {"allocator", t_allocator}});
		return;
	case Type_FixedCapacityDynamicArray:
		xbb_uleb(b, xbAbbrev_StructType);
		xbb_str(b, name);
		xbb_uleb(b, cast(u64)type_size_of(bt));
		xbb_uleb(b, xbAbbrev_Member);
		xbb_cstr(b, "data");
		xb_dwarf_type_ref(dt, alloc_type_array(bt->FixedCapacityDynamicArray.elem, bt->FixedCapacityDynamicArray.capacity));
		xbb_uleb(b, 0);
		xbb_uleb(b, xbAbbrev_Member);
		xbb_cstr(b, "len");
		xb_dwarf_type_ref(dt, t_int);
		xbb_uleb(b, cast(u64)type_offset_of(bt, 1));
		xbb_u8(b, 0);
		return;
	case Type_Enum: {
		xbb_uleb(b, xbAbbrev_EnumType);
		xbb_str(b, name);
		xb_dwarf_type_ref(dt, bt->Enum.base_type);
		xbb_uleb(b, cast(u64)type_size_of(bt));
		for (Entity *f : bt->Enum.fields) {
			xbb_uleb(b, xbAbbrev_Enumerator);
			xbb_str(b, f->token.string);
			xbb_sleb(b, exact_value_to_i64(f->Constant.value));
		}
		xbb_u8(b, 0);
		return;
	}
	case Type_Map:
		init_map_internal_debug_types(bt);
		bt = base_type(bt->Map.debug_metadata_type);
		GB_ASSERT(bt->kind == Type_Struct);
		/*fallthrough*/
	case Type_Struct: {
		if (bt->Struct.fields.count == 0) {
			xbb_uleb(b, xbAbbrev_EmptyStructType);
			xbb_str(b, name);
			xbb_uleb(b, cast(u64)type_size_of(bt));
			return;
		}
		xbb_uleb(b, bt->Struct.is_raw_union ? xbAbbrev_UnionType : xbAbbrev_StructType);
		xbb_str(b, name);
		xbb_uleb(b, cast(u64)type_size_of(bt));
		type_set_offsets(bt);
		for_array(i, bt->Struct.fields) {
			Entity *f = bt->Struct.fields[i];
			xbb_uleb(b, xbAbbrev_Member);
			xbb_str(b, f->token.string);
			xb_dwarf_type_ref(dt, f->type);
			xbb_uleb(b, cast(u64)(bt->Struct.is_raw_union ? 0 : bt->Struct.offsets[i]));
		}
		xbb_u8(b, 0);
		return;
	}
	case Type_Union: {
		// {tag, v<n>...} like lb_debug_union, which the pretty printers rely on
		xbb_uleb(b, xbAbbrev_UnionType);
		xbb_str(b, name);
		xbb_uleb(b, cast(u64)type_size_of(bt));
		if (!is_type_union_maybe_pointer(bt) && type_size_of(bt) > 0) {
			xbb_uleb(b, xbAbbrev_Member);
			xbb_cstr(b, "tag");
			xb_dwarf_type_ref(dt, union_tag_type(bt));
			xbb_uleb(b, cast(u64)bt->Union.variant_block_size);
		}
		// numbered like LLVM's: from 1 when the union can be nil
		isize first = (is_type_union_maybe_pointer(bt) || bt->Union.kind == UnionType_no_nil) ? 0 : 1;
		for_array(i, bt->Union.variants) {
			Type *v = bt->Union.variants[i];
			char buf[32] = {};
			gb_snprintf(buf, gb_size_of(buf), "v%td", first+i);
			xbb_uleb(b, xbAbbrev_Member);
			xbb_str(b, copy_string(permanent_allocator(), make_string_c(buf)));
			xb_dwarf_type_ref(dt, v);
			xbb_uleb(b, 0);
		}
		xbb_u8(b, 0);
		return;
	}
	case Type_BitSet: {
		// a union of one bool bit per element, like LLVM's
		Type *elem = base_type(bt->BitSet.elem);
		i64 count = bt->BitSet.upper - bt->BitSet.lower + 1;
		if ((elem->kind != Type_Enum && !is_type_integer(elem)) || count <= 0 || count > 128 ||
		    is_type_different_to_arch_endianness(bit_set_to_int(bt))) {
			xbb_uleb(b, xbAbbrev_Typedef);
			xbb_str(b, name);
			xb_dwarf_type_ref(dt, bit_set_to_int(bt));
			return;
		}
		if (elem->kind == Type_Enum && type_size_of(bt) <= 8) {
			// a flag enum, like lb_debug_bitset, which DWARF debuggers show as `A | C`
			xbb_uleb(b, xbAbbrev_EnumType);
			xbb_str(b, name);
			xb_dwarf_type_ref(dt, bit_set_to_int(bt));
			xbb_uleb(b, cast(u64)type_size_of(bt));
			u64 bits = 0;
			for (Entity *f : elem->Enum.fields) {
				i64 val = exact_value_to_i64(f->Constant.value);
				if (val < bt->BitSet.lower || bt->BitSet.upper < val) continue;
				u64 flag = 1ull << cast(u64)(val - bt->BitSet.lower);
				if (bits & flag) continue; // an alias
				bits |= flag;
				xbb_uleb(b, xbAbbrev_Enumerator);
				xbb_str(b, f->token.string);
				xbb_sleb(b, cast(i64)flag);
			}
			xbb_u8(b, 0);
			return;
		}
		xbb_uleb(b, xbAbbrev_UnionType);
		xbb_str(b, name);
		xbb_uleb(b, cast(u64)type_size_of(bt));
		if (elem->kind == Type_Enum) {
			for (Entity *f : elem->Enum.fields) {
				i64 bit = exact_value_to_i64(f->Constant.value) - bt->BitSet.lower;
				if (bit < 0 || bit >= 8*type_size_of(bt)) continue;
				xb_dwarf_bit_member(dt, f->token.string, t_bool, 1, cast(u64)bit);
			}
		} else {
			for (i64 i = 0; i < count; i++) {
				char buf[32] = {};
				gb_snprintf(buf, gb_size_of(buf), "%lld", cast(long long)(bt->BitSet.lower + i));
				xb_dwarf_bit_member(dt, make_string_c(buf), t_bool, 1, cast(u64)i);
			}
		}
		xbb_u8(b, 0);
		return;
	}
	case Type_BitField: {
		if (bt->BitField.fields.count == 0) break;
		xbb_uleb(b, xbAbbrev_StructType);
		xbb_str(b, name);
		xbb_uleb(b, cast(u64)type_size_of(bt));
		u64 offset = 0;
		for_array(i, bt->BitField.fields) {
			Entity *f = bt->BitField.fields[i];
			u8 bits = bt->BitField.bit_sizes[i];
			xb_dwarf_bit_member(dt, f->token.string, f->type, bits, offset);
			offset += bits;
		}
		xbb_u8(b, 0);
		return;
	}
	}

	// anything else: an array of bytes of the right size
	xbb_uleb(b, xbAbbrev_ArrayType);
	xbb_str(b, name);
	xb_dwarf_type_ref(dt, t_u8);
	xbb_uleb(b, xbAbbrev_Subrange);
	xbb_uleb(b, cast(u64)type_size_of(t));
	xbb_u8(b, 0);
}

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

gb_internal i32 xb_file_id(xbModule *m, i32 global_file_id) {
	AstFile *f = global_files[global_file_id];
	i32 *found = map_get(&m->file_ids, f);
	if (found) return *found;
	i32 id = cast(i32)m->files.count + 1;
	array_add(&m->files, f->fullpath);
	map_set(&m->file_ids, f, id);
	return id;
}

// DW_AT_location of a symbol's storage: its address, or its offset in the thread's TLS block
gb_internal void xb_dwarf_symbol_location(xbModule *m, Array<u8> *b, Array<xbSymReloc> *relocs, i32 sym) {
	bool tls = (m->symbols[sym].flags & xbSymbolFlag_TLS) != 0;
	xbb_uleb(b, tls ? 10 : 9);
	xbb_u8(b, tls ? XDW_OP_const8u : XDW_OP_addr);
	xbSymReloc r = {b->count, sym, tls ? XB_R_X86_64_DTPOFF64 : XB_R_X86_64_64};
	array_add(relocs, r);
	xbb_u64(b, 0);
	if (tls) xbb_u8(b, XDW_OP_GNU_push_tls_address);
}

gb_internal void xb_add_debug_constants(xbModule *m);

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

	// .eh_frame
	{
		Array<u8> *b = &sec[xbOut_EhFrame];
		isize cie_start = b->count;
		xbb_u32(b, 0); // length
		xbb_u32(b, 0); // CIE id
		xbb_u8(b, 1);  // version
		xbb_cstr(b, "zR");
		xbb_uleb(b, 1);  // code alignment
		xbb_sleb(b, -8); // data alignment
		xbb_uleb(b, 16); // return address register
		xbb_uleb(b, 1);  // augmentation data length
		xbb_u8(b, 0x1b); // FDE pointers: pcrel sdata4
		xbb_u8(b, 0x0c); xbb_uleb(b, 7); xbb_uleb(b, 8); // def_cfa rsp+8
		xbb_u8(b, 0x80 | 16); xbb_uleb(b, 1);             // rip at cfa-8
		xbb_align(b, 8);
		xbb_patch_u32(b, cie_start, cast(u32)(b->count - cie_start - 4));

		for (xbProcDebug const &pd : m->proc_debug) {
			isize fde_start = b->count;
			xbb_u32(b, 0);
			xbb_u32(b, cast(u32)(b->count - cie_start)); // CIE pointer
			xbExtraReloc r = {b->count, xbOut_Text, XB_R_X86_64_PC32, pd.start};
			array_add(&extra_relocs, r);
			xbb_u32(b, 0); // pc begin
			xbb_u32(b, cast(u32)(pd.end - pd.start));
			xbb_uleb(b, 0); // augmentation data length
			xbb_u8(b, 0x40 | 1);                    // advance 1 (push rbp)
			xbb_u8(b, 0x0e); xbb_uleb(b, 16);       // def_cfa_offset 16
			xbb_u8(b, 0x80 | 6); xbb_uleb(b, 2);    // rbp at cfa-16
			xbb_u8(b, 0x40 | 3);                    // advance 3 (mov rbp, rsp)
			xbb_u8(b, 0x0d); xbb_uleb(b, 6);        // def_cfa_register rbp
			if (pd.saved_regs.count > 0) {
				u32 delta = cast(u32)(pd.saved_at - 4);
				if (delta < 64) {
					xbb_u8(b, cast(u8)(0x40 | delta)); // advance_loc
				} else {
					xbb_u8(b, 0x03); xbb_u8(b, cast(u8)delta); xbb_u8(b, cast(u8)(delta >> 8)); // advance_loc2
				}
				for (auto const &s : pd.saved_regs) {
					// saved at rbp+off, the cfa is rbp+16
					xbb_u8(b, cast(u8)(0x80 | s.dwarf_reg));
					xbb_uleb(b, cast(u64)((16 - s.frame_offset) / 8));
				}
			}
			xbb_align(b, 8);
			xbb_patch_u32(b, fde_start, cast(u32)(b->count - fde_start - 4));
		}
	}

	bool debug = build_context.ODIN_DEBUG;
	if (debug) {
		xb_add_debug_constants(m);
		xb_dwarf_abbrevs(&sec[xbOut_DebugAbbrev]);
		String cwd = {};
		{
			char buf[4096] = {};
			if (getcwd(buf, gb_size_of(buf)-1) != nullptr) {
				cwd = copy_string(permanent_allocator(), make_string_c(buf));
			}
		}

		// .debug_line
		{
			Array<u8> *b = &sec[xbOut_DebugLine];
			isize start = b->count;
			xbb_u32(b, 0); // unit length
			xbb_u16(b, 4); // version
			isize header_len_at = b->count;
			xbb_u32(b, 0); // header length
			isize header_start = b->count;
			xbb_u8(b, 1);  // min instruction length
			xbb_u8(b, 1);  // max ops per instruction
			xbb_u8(b, 1);  // default is_stmt
			xbb_u8(b, cast(u8)cast(i8)-5); // line base
			xbb_u8(b, 14); // line range
			xbb_u8(b, 13); // opcode base
			u8 const std_lengths[12] = {0,1,1,1,1,0,0,0,1,0,0,1};
			xbb_bytes(b, std_lengths, 12);
			// directories and base names, so debuggers show short file names like LLVM's
			auto last_slash = [](String f) -> isize {
				for (isize j = f.len-1; j > 0; j--) if (f[j] == '/') return j;
				return -1;
			};
			StringMap<u64> dirs = {};
			string_map_init(&dirs);
			auto file_dirs = array_make<u64>(heap_allocator(), m->files.count);
			for_array(i, m->files) {
				isize slash = last_slash(m->files[i]);
				file_dirs[i] = 0;
				if (slash < 0) continue;
				String dir = substring(m->files[i], 0, slash);
				if (dir == cwd) continue; // index 0 is the compilation directory
				u64 *found = string_map_get(&dirs, dir);
				if (found == nullptr) {
					string_map_set(&dirs, dir, cast(u64)dirs.count + 1);
					xbb_str(b, dir);
					found = string_map_get(&dirs, dir);
				}
				file_dirs[i] = *found;
			}
			xbb_u8(b, 0);
			for_array(i, m->files) {
				String f = m->files[i];
				isize slash = last_slash(f);
				bool short_name = slash >= 0 && (file_dirs[i] != 0 || substring(f, 0, slash) == cwd);
				xbb_str(b, short_name ? substring(f, slash+1, f.len) : f);
				xbb_uleb(b, file_dirs[i]);
				xbb_uleb(b, 0);
				xbb_uleb(b, 0);
			}
			string_map_destroy(&dirs);
			array_free(&file_dirs);
			xbb_u8(b, 0);
			xbb_patch_u32(b, header_len_at, cast(u32)(b->count - header_start));

			for (xbProcDebug const &pd : m->proc_debug) {
				// set address
				xbb_u8(b, 0);
				xbb_uleb(b, 9);
				xbb_u8(b, 2);
				xbExtraReloc r = {b->count, xbOut_Text, XB_R_X86_64_64, pd.start};
				array_add(&line_relocs, r);
				xbb_u64(b, 0);
				i64 cur_addr = 0;
				i64 cur_line = 1;
				i32 cur_file = 1;
				if (pd.line > 0 && (pd.line_entry_count == 0 || m->lines[pd.line_entry_start].code_offset != 0)) {
					// the prologue gets the declaration's line, debuggers look up the entry address
					if (pd.file_id > 0 && pd.file_id != cur_file) {
						xbb_u8(b, 4);
						xbb_uleb(b, cast(u64)pd.file_id);
						cur_file = pd.file_id;
					}
					xbb_u8(b, 3);
					xbb_sleb(b, pd.line - cur_line);
					cur_line = pd.line;
					xbb_u8(b, 1);
				}
				for (i32 i = 0; i < pd.line_entry_count; i++) {
					xbLineEntry const &e = m->lines[pd.line_entry_start + i];
					if (e.file_id != cur_file) {
						xbb_u8(b, 4); // set_file
						xbb_uleb(b, cast(u64)e.file_id);
						cur_file = e.file_id;
					}
					if (e.code_offset != cur_addr) {
						xbb_u8(b, 2); // advance_pc
						xbb_uleb(b, cast(u64)(e.code_offset - cur_addr));
						cur_addr = e.code_offset;
					}
					if (e.line != cur_line) {
						xbb_u8(b, 3); // advance_line
						xbb_sleb(b, e.line - cur_line);
						cur_line = e.line;
					}
					xbb_u8(b, 5); // set_column
					xbb_uleb(b, cast(u64)gb_max(e.column, 0));
					xbb_u8(b, 1); // copy
				}
				i64 end = pd.end - pd.start;
				if (end != cur_addr) {
					xbb_u8(b, 2);
					xbb_uleb(b, cast(u64)(end - cur_addr));
				}
				// end sequence
				xbb_u8(b, 0);
				xbb_uleb(b, 1);
				xbb_u8(b, 1);
			}
			xbb_patch_u32(b, start, cast(u32)(b->count - start - 4));
		}

		// .debug_info
		{
			Array<u8> *b = &sec[xbOut_DebugInfo];
			xbDwarfTypes dt = {};
			dt.info = b;
			map_init(&dt.offsets);
			ptr_set_init(&dt.queued);
			dt.pending = array_make<xbDwarfTypes::Pending>(heap_allocator(), 0, 256);
			dt.queue = array_make<Type *>(heap_allocator(), 0, 256);

			isize start = b->count;
			dt.cu_start = start;
			dt.checker = m->info;
			xbb_u32(b, 0); // unit length
			xbb_u16(b, 4); // version
			xbExtraReloc ra = {b->count, xbOut_DebugAbbrev, XB_R_X86_64_32, 0};
			array_add(&info_relocs, ra);
			xbb_u32(b, 0); // abbrev offset
			xbb_u8(b, 8);  // address size

			xbb_uleb(b, xbAbbrev_CompileUnit);
			xbb_cstr(b, "odin (x64 backend)");
			xbb_u16(b, XDW_LANG_C99);
			String name = m->files.count > 0 ? m->files[0] : str_lit("odin");
			xbb_str(b, name);
			xbb_str(b, cwd);
			xbExtraReloc rl = {b->count, xbOut_Text, XB_R_X86_64_64, 0};
			array_add(&info_relocs, rl);
			xbb_u64(b, 0); // low pc
			xbb_u64(b, cast(u64)m->sections[xbSection_Text].count); // high pc (length)
			xbExtraReloc rs = {b->count, xbOut_DebugLine, XB_R_X86_64_32, 0};
			array_add(&info_relocs, rs);
			xbb_u32(b, 0); // stmt list

			for (xbGlobalDebug const &g : m->global_debug) {
				xbb_uleb(b, g.sym >= 0 ? xbAbbrev_GlobalVar : xbAbbrev_Constant);
				xbb_str(b, g.name);
				xb_dwarf_type_ref(&dt, g.type);
				if (g.sym >= 0) {
					xbb_uleb(b, cast(u64)g.file_id);
					xbb_uleb(b, cast(u64)gb_max(g.line, 0));
					xb_dwarf_symbol_location(m, b, &info_sym_relocs, g.sym);
				} else {
					xbb_sleb(b, g.value);
				}
			}

			for (xbProcDebug const &pd : m->proc_debug) {
				bool has_children = pd.vars.count > 0;
				// the single result, so `finish` shows it
				Type *ret = nullptr;
				Type *pt = pd.type ? base_type(pd.type) : nullptr;
				if (pt && pt->kind == Type_Proc && pt->Proc.result_count == 1) {
					ret = pt->Proc.results->Tuple.variables[0]->type;
				}
				if (ret) {
					xbb_uleb(b, has_children ? xbAbbrev_SubprogramRet : xbAbbrev_SubprogramRetNoChildren);
				} else {
					xbb_uleb(b, has_children ? xbAbbrev_Subprogram : xbAbbrev_SubprogramNoChildren);
				}
				// the full name, like LLVM's, so `break pkg::proc` finds it
				xbb_str(b, pd.link_name);
				xbb_str(b, pd.link_name);
				xbExtraReloc r = {b->count, xbOut_Text, XB_R_X86_64_64, pd.start};
				array_add(&info_relocs, r);
				xbb_u64(b, 0);
				xbb_u32(b, cast(u32)(pd.end - pd.start));
				xbb_uleb(b, 1);
				xbb_u8(b, XDW_OP_reg6);
				xbb_uleb(b, cast(u64)gb_max(pd.file_id, 1));
				xbb_uleb(b, cast(u64)gb_max(pd.line, 0));
				if (ret) xb_dwarf_type_ref(&dt, ret);
				if (has_children) {
					for (xbDebugVar const &v : pd.vars) {
						xbb_uleb(b, v.is_param ? xbAbbrev_Param : xbAbbrev_Var);
						xbb_str(b, v.name);
						if (v.local < 0) {
							xb_dwarf_symbol_location(m, b, &info_sym_relocs, v.sym);
							xbb_uleb(b, cast(u64)gb_max(v.line, 0));
							xb_dwarf_type_ref(&dt, v.type);
							continue;
						}
						Array<u8> expr = array_make<u8>(heap_allocator(), 0, 16);
						if (v.in_reg) {
							xbb_u8(&expr, cast(u8)(XDW_OP_reg0 + v.dwarf_reg));
						} else {
							// rbp is the frame base
							xbb_u8(&expr, XDW_OP_fbreg);
							xbb_sleb(&expr, v.frame_offset_fixup);
							if (v.by_ref) {
								xbb_u8(&expr, XDW_OP_deref);
							}
						}
						xbb_uleb(b, cast(u64)expr.count);
						xbb_bytes(b, expr.data, expr.count);
						array_free(&expr);
						xbb_uleb(b, cast(u64)gb_max(v.line, 0));
						xb_dwarf_type_ref(&dt, v.type);
					}
					xbb_u8(b, 0);
				}
			}

			// types, written after their first use
			for (isize i = 0; i < dt.queue.count; i++) {
				xb_dwarf_write_type(&dt, dt.queue[i]);
			}
			for (auto const &pd : dt.pending) {
				u32 *off = map_get(&dt.offsets, pd.type);
				GB_ASSERT(off != nullptr);
				xbb_patch_u32(b, pd.at, cast(u32)(*off - start));
			}

			xbb_u8(b, 0); // end of compile unit children
			xbb_patch_u32(b, start, cast(u32)(b->count - start - 4));
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
	xbOutSection sym_sections[] = {xbOut_Text, xbOut_Rodata, xbOut_Data, xbOut_Bss, xbOut_TData, xbOut_TBss, xbOut_EhFrame, xbOut_DebugAbbrev, xbOut_DebugInfo, xbOut_DebugLine};
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
		}
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
		"", ".text", ".rodata", ".data", ".bss", ".tdata", ".tbss", ".eh_frame", ".debug_abbrev", ".debug_info", ".debug_line", ".debug_gdb_scripts",
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
	set(xbOut_Text,        SHT_PROGBITS, SHF_ALLOC|SHF_EXEC, 16);
	set(xbOut_Rodata,      SHT_PROGBITS, SHF_ALLOC, align_of(xbSection_Rodata));
	set(xbOut_Data,        SHT_PROGBITS, SHF_ALLOC|SHF_WRITE, align_of(xbSection_Data));
	set(xbOut_Bss,         SHT_NOBITS,   SHF_ALLOC|SHF_WRITE, align_of(xbSection_Bss));
	set(xbOut_TData,       SHT_PROGBITS, SHF_ALLOC|SHF_WRITE|SHF_TLS, align_of(xbSection_TData));
	set(xbOut_TBss,        SHT_NOBITS,   SHF_ALLOC|SHF_WRITE|SHF_TLS, align_of(xbSection_TBss));
	set(xbOut_EhFrame,     SHT_PROGBITS, SHF_ALLOC, 8);
	set(xbOut_DebugAbbrev, SHT_PROGBITS, 0, 1);
	set(xbOut_DebugInfo,   SHT_PROGBITS, 0, 1);
	set(xbOut_DebugLine,   SHT_PROGBITS, 0, 1);
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
	u16 e_machine = 62;  // x86-64
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
		gb_printf_err("x64 backend: failed to create %s\n", cpath);
		return false;
	}
	gb_file_write(&f, out.data, out.count);
	gb_file_close(&f);
	return true;
}
