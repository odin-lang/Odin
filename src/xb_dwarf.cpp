// DWARF 4 debug info, shared by the ELF and Mach-O object writers, and the byte buffer
// helpers every object writer uses.

#include <initializer_list>
#include <utility>

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

////////////////////////////////////////////////////////////////
// DWARF
////////////////////////////////////////////////////////////////

enum {
	XDW_TAG_array_type       = 0x01,
	XDW_TAG_enumeration_type = 0x04,
	XDW_TAG_formal_parameter = 0x05,
	XDW_TAG_lexical_block    = 0x0b,
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
	XDW_TAG_inlined_subroutine = 0x1d,
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
	XDW_AT_ranges          = 0x55,
	XDW_AT_linkage_name    = 0x6e,
	XDW_AT_inline          = 0x20,
	XDW_AT_abstract_origin = 0x31,
	XDW_AT_call_column     = 0x57,
	XDW_AT_call_file       = 0x58,
	XDW_AT_call_line       = 0x59,

	XDW_INL_declared_inlined = 3,

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
	XDW_ATE_unsigned = 0x07,
	XDW_ATE_UTF      = 0x10,

	XDW_OP_addr    = 0x03,
	XDW_OP_deref   = 0x06,
	XDW_OP_const8u = 0x0e,
	XDW_OP_GNU_push_tls_address = 0xe0,
	XDW_OP_form_tls_address = 0x9b,
	XDW_OP_fbreg = 0x91,
	XDW_OP_reg0  = 0x50,
	XDW_OP_reg6  = 0x56,
	XDW_OP_breg0 = 0x70,
	XDW_OP_regx  = 0x90,
	XDW_OP_constu = 0x10,
	XDW_OP_and    = 0x1a,
	XDW_OP_plus_uconst = 0x23,
	XDW_OP_call_frame_cfa = 0x9c,

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
	xbAbbrev_LexicalBlock,
	xbAbbrev_LexicalBlockRanges,
	xbAbbrev_AbstractSubprogram,
	xbAbbrev_InlinedSubroutine,
	xbAbbrev_InlinedSubroutineRanges,
};

gb_internal void xb_dwarf_abbrevs(Array<u8> *b) {
	auto abbrev = [&](xbAbbrev code, u32 tag, bool children, std::initializer_list<u32> attrs) {
		xbb_uleb(b, code);
		xbb_uleb(b, tag);
		xbb_u8(b, cast(u8)(children ? XDW_CHILDREN_yes : XDW_CHILDREN_no));
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
	abbrev(xbAbbrev_LexicalBlock, XDW_TAG_lexical_block, true, {
		XDW_AT_low_pc, XDW_FORM_addr,
		XDW_AT_high_pc, XDW_FORM_data4,
	});
	abbrev(xbAbbrev_LexicalBlockRanges, XDW_TAG_lexical_block, true, {
		XDW_AT_ranges, XDW_FORM_sec_offset,
	});
	// a #force_inline procedure, which inlined_subroutine entries refer to
	abbrev(xbAbbrev_AbstractSubprogram, XDW_TAG_subprogram, false, {
		XDW_AT_name, XDW_FORM_string,
		XDW_AT_decl_file, XDW_FORM_udata,
		XDW_AT_decl_line, XDW_FORM_udata,
		XDW_AT_inline, XDW_FORM_data1,
	});
	abbrev(xbAbbrev_InlinedSubroutine, XDW_TAG_inlined_subroutine, true, {
		XDW_AT_abstract_origin, XDW_FORM_ref4,
		XDW_AT_low_pc, XDW_FORM_addr,
		XDW_AT_high_pc, XDW_FORM_data4,
		XDW_AT_call_file, XDW_FORM_udata,
		XDW_AT_call_line, XDW_FORM_udata,
		XDW_AT_call_column, XDW_FORM_udata,
	});
	abbrev(xbAbbrev_InlinedSubroutineRanges, XDW_TAG_inlined_subroutine, true, {
		XDW_AT_abstract_origin, XDW_FORM_ref4,
		XDW_AT_ranges, XDW_FORM_sec_offset,
		XDW_AT_call_file, XDW_FORM_udata,
		XDW_AT_call_line, XDW_FORM_udata,
		XDW_AT_call_column, XDW_FORM_udata,
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
			enc = XDW_ATE_UTF; break;
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
				enc = cast(u8)((bt->Basic.flags & BasicFlag_Unsigned) ? XDW_ATE_unsigned : XDW_ATE_signed);
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
		// a typedef of the same name, like LLVM's, or a debugger shows the C type's name
		xbb_uleb(b, xbAbbrev_Typedef);
		xbb_str(b, name);
		xbb_u32(b, cast(u32)(b->count + 4 - dt->cu_start));
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

gb_internal i32 xb_file_id(xbModule *m, i32 global_file_id) {
	AstFile *f = global_files[global_file_id];
	i32 *found = map_get(&m->file_ids, f);
	if (found) return *found;
	i32 id = cast(i32)m->files.count + 1;
	array_add(&m->files, f->fullpath);
	map_set(&m->file_ids, f, id);
	return id;
}

gb_internal void xb_add_debug_constants(xbModule *m);

// An address in .debug_info or .debug_line, relocated by the object writer.
struct xbDwarfAddr {
	isize offset; // in the debug section
	i32   sym;    // a module symbol, or -1 for the text section
	i64   addend; // the offset in the text section, when sym < 0
};

// The DWARF sections, which every object format shares but for their relocations.
struct xbDwarf {
	Array<u8> abbrev;
	Array<u8> info;
	Array<u8> line;
	Array<u8> ranges;
	Array<xbDwarfAddr> info_addrs;
	Array<xbDwarfAddr> line_addrs;
	Array<isize> ranges_refs; // in .debug_info, the offsets into .debug_ranges, which ELF relocates
	isize abbrev_offset_at; // in .debug_info, the offsets into .debug_abbrev and .debug_line
	isize stmt_list_at;
};

// The lexical blocks of a procedure. Like LLVM, a scope gets one when it has variables of its
// own and code; otherwise its variables and blocks go to the parent's block.
struct xbDwarfScopes {
	struct Range { i32 lo, hi, next; };
	Array<i32> eff;                  // per scope: the scope whose block holds its variables
	Array<i32> kid, sib;             // the first block inside a block, the next block beside it
	Array<i32> head, tail;           // per scope: its code ranges, a list in `pool`
	Array<i32> var_head, var_tail, var_next; // the variables a block holds, in order
	Array<i32> site;                 // per scope: its index in inline_sites, or -1
	Array<Range> pool;
};

gb_internal void xb_dwarf_scopes(xbDwarfScopes *sc, xbProcDebug const &pd, i32 len) {
	isize n = gb_max(pd.scope_parent.count, cast(isize)1);
	auto parent = [&](i32 s) -> i32 { return s < pd.scope_parent.count ? pd.scope_parent[s] : -1; };
	array_resize(&sc->eff, n);
	array_resize(&sc->kid, n);
	array_resize(&sc->sib, n);
	array_resize(&sc->head, n);
	array_resize(&sc->tail, n);
	array_resize(&sc->var_head, n);
	array_resize(&sc->var_tail, n);
	array_resize(&sc->var_next, pd.vars.count);
	array_resize(&sc->site, n);
	sc->pool.count = 0;
	for (isize s = 0; s < n; s++) {
		sc->eff[s] = 0; // 1 here: the scope has variables of its own, or is an inlined body
		sc->kid[s] = sc->sib[s] = sc->head[s] = sc->tail[s] = sc->var_head[s] = sc->var_tail[s] = sc->site[s] = -1;
	}
	for (xbDebugVar const &v : pd.vars) {
		if (v.scope < n) sc->eff[v.scope] = 1;
	}
	for_array(i, pd.inline_sites) {
		i32 s = pd.inline_sites[i].scope;
		if (s > 0 && s < n) {
			sc->eff[s] = 1;
			sc->site[s] = cast(i32)i;
		}
	}
	// the code of a scope, with its nested scopes' and its cold blocks', so it may be in pieces
	auto const &marks = pd.scope_marks;
	for_array(k, marks) {
		i32 lo = marks[k].code_offset;
		i32 hi = k+1 < marks.count ? marks[k+1].code_offset : len;
		if (hi <= lo) continue;
		for (i32 s = marks[k].scope; s > 0; s = parent(s)) {
			if (sc->eff[s] == 0) continue;
			i32 t = sc->tail[s];
			if (t >= 0 && sc->pool[t].hi == lo) {
				sc->pool[t].hi = hi;
				continue;
			}
			xbDwarfScopes::Range r = {lo, hi, -1};
			i32 at = cast(i32)sc->pool.count;
			array_add(&sc->pool, r);
			if (t >= 0) sc->pool[t].next = at; else sc->head[s] = at;
			sc->tail[s] = at;
		}
	}
	// parents first, by the ids; kids are linked in reverse, then put back in order
	sc->eff[0] = 0;
	for (isize s = 1; s < n; s++) {
		i32 pe = sc->eff[parent(cast(i32)s)];
		if (sc->eff[s] == 1 && sc->head[s] >= 0) {
			sc->eff[s] = cast(i32)s;
			sc->sib[s] = sc->kid[pe];
			sc->kid[pe] = cast(i32)s;
		} else {
			sc->eff[s] = pe;
		}
	}
	for (isize s = 0; s < n; s++) {
		i32 prev = -1;
		for (i32 c = sc->kid[s]; c >= 0; ) {
			i32 next = sc->sib[c];
			sc->sib[c] = prev;
			prev = c;
			c = next;
		}
		sc->kid[s] = prev;
	}
	for_array(i, pd.vars) {
		i32 s = pd.vars[i].scope < n ? sc->eff[pd.vars[i].scope] : 0;
		sc->var_next[i] = -1;
		if (sc->var_tail[s] >= 0) sc->var_next[sc->var_tail[s]] = cast(i32)i; else sc->var_head[s] = cast(i32)i;
		sc->var_tail[s] = cast(i32)i;
	}
}

// DW_AT_location of a symbol's storage: its address, or its offset in the thread's TLS block.
// On macOS the symbol of a thread local is its TLV descriptor, which lldb resolves with form_tls_address.
// Like LLVM, a thread local on arm64 Linux has an empty location: its linkers reject the relocation.
gb_internal void xb_dwarf_symbol_location(xbModule *m, Array<u8> *b, Array<xbDwarfAddr> *addrs, i32 sym) {
	bool tls = (m->symbols[sym].flags & xbSymbolFlag_TLS) != 0;
	if (tls && xb_is_arm64() && !xb_is_darwin()) {
		xbb_uleb(b, 0);
		return;
	}
	i64 realign = m->symbols[sym].realign;
	Array<u8> round = array_make<u8>(heap_allocator(), 0, 16);
	defer (array_free(&round));
	if (realign != 0) {
		// up to the next multiple of the alignment, see lb_tls_realign
		xbb_u8(&round, cast(u8)XDW_OP_plus_uconst);
		xbb_uleb(&round, cast(u64)(realign-1));
		xbb_u8(&round, cast(u8)XDW_OP_constu);
		xbb_uleb(&round, ~cast(u64)(realign-1));
		xbb_u8(&round, cast(u8)XDW_OP_and);
	}
	xbb_uleb(b, (tls ? 10 : 9) + cast(u64)round.count);
	xbb_u8(b, cast(u8)(tls ? XDW_OP_const8u : XDW_OP_addr));
	xbDwarfAddr r = {b->count, sym, 0};
	array_add(addrs, r);
	xbb_u64(b, 0);
	if (tls) xbb_u8(b, cast(u8)(xb_is_darwin() ? XDW_OP_form_tls_address : XDW_OP_GNU_push_tls_address));
	xbb_bytes(b, round.data, round.count);
}

gb_internal void xb_dwarf_build(xbModule *m, xbDwarf *d) {
	d->abbrev = array_make<u8>(heap_allocator(), 0, 4096);
	d->info = array_make<u8>(heap_allocator(), 0, 1<<16);
	d->line = array_make<u8>(heap_allocator(), 0, 1<<16);
	d->ranges = array_make<u8>(heap_allocator(), 0, 0);
	d->ranges_refs = array_make<isize>(heap_allocator(), 0, 0);
	d->info_addrs = array_make<xbDwarfAddr>(heap_allocator(), 0, 256);
	d->line_addrs = array_make<xbDwarfAddr>(heap_allocator(), 0, 256);
	u8 const frame_reg = xb_is_arm64() ? XDW_OP_reg0 + 29 : XDW_OP_reg6; // x29 or rbp

	xb_add_debug_constants(m);
	xb_dwarf_abbrevs(&d->abbrev);
	// the compilation directory is the entry file's, like LLVM's, so debuggers show its files by their short names
	String cwd = {};
	if (m->info->init_package->files.count > 0) { // every file can be excluded by build tags
		cwd = m->info->init_package->files[0]->directory;
	}
	if (Entity *entry_point = m->info->entry_point) {
		if (Ast *ident = entry_point->identifier.load()) {
			if (ident->file_id) cwd = ident->file()->directory;
		}
	}
	if (cwd.len == 0) {
		cwd = get_working_directory(permanent_allocator());
	}

	// .debug_line
	{
		Array<u8> *b = &d->line;
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
			xbDwarfAddr r = {b->count, -1, pd.start};
			array_add(&d->line_addrs, r);
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
				if (pd.prologue_end > 0) {
					xbb_u8(b, 2); // advance_pc
					xbb_uleb(b, cast(u64)pd.prologue_end);
					cur_addr = pd.prologue_end;
					xbb_u8(b, 10); // set_prologue_end
					xbb_u8(b, 1);
				}
			}
			for (i32 i = 0; i < pd.line_entry_count; i++) {
				xbLineEntry const &e = m->lines[pd.line_entry_start + i];
				// a row that covers no code would still give its line an extra breakpoint location
				if (i+1 < pd.line_entry_count && m->lines[pd.line_entry_start + i+1].code_offset == e.code_offset) continue;
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
		Array<u8> *b = &d->info;
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
		d->abbrev_offset_at = b->count;
		xbb_u32(b, 0); // abbrev offset
		xbb_u8(b, 8);  // address size

		xbb_uleb(b, xbAbbrev_CompileUnit);
		xbb_cstr(b, xb_is_arm64() ? "odin (arm64 backend)" : "odin (x64 backend)");
		xbb_u16(b, XDW_LANG_C99);
		String name = m->files.count > 0 ? m->files[0] : str_lit("odin");
		xbb_str(b, name);
		xbb_str(b, cwd);
		xbDwarfAddr rl = {b->count, -1, 0};
		array_add(&d->info_addrs, rl);
		xbb_u64(b, 0); // low pc
		xbb_u64(b, cast(u64)m->sections[xbSection_Text].count); // high pc (length)
		d->stmt_list_at = b->count;
		xbb_u32(b, 0); // stmt list

		for (xbGlobalDebug const &g : m->global_debug) {
			xbb_uleb(b, g.sym >= 0 ? xbAbbrev_GlobalVar : xbAbbrev_Constant);
			xbb_str(b, g.name);
			xb_dwarf_type_ref(&dt, g.type);
			if (g.sym >= 0) {
				xbb_uleb(b, cast(u64)g.file_id);
				xbb_uleb(b, cast(u64)gb_max(g.line, 0));
				xb_dwarf_symbol_location(m, b, &d->info_addrs, g.sym);
			} else {
				xbb_sleb(b, g.value);
			}
		}

		// one abstract entry per inlined procedure, by name
		StringMap<u32> abstract_dies = {};
		string_map_init(&abstract_dies);
		for (xbProcDebug const &pd : m->proc_debug) {
			for (xbInlineSite const &site : pd.inline_sites) {
				if (string_map_get(&abstract_dies, site.name) != nullptr) continue;
				string_map_set(&abstract_dies, site.name, cast(u32)(b->count - start));
				xbb_uleb(b, xbAbbrev_AbstractSubprogram);
				xbb_str(b, site.name);
				xbb_uleb(b, cast(u64)gb_max(site.decl_file, 1));
				xbb_uleb(b, cast(u64)gb_max(site.decl_line, 0));
				xbb_u8(b, XDW_INL_declared_inlined);
			}
		}

		auto emit_var = [&](xbDebugVar const &v) {
			xbb_uleb(b, v.is_param ? xbAbbrev_Param : xbAbbrev_Var);
			xbb_str(b, v.name);
			if (v.local < 0) {
				xb_dwarf_symbol_location(m, b, &d->info_addrs, v.sym);
				xbb_uleb(b, cast(u64)gb_max(v.line, 0));
				xb_dwarf_type_ref(&dt, v.type);
				return;
			}
			Array<u8> expr = array_make<u8>(heap_allocator(), 0, 16);
			if (v.in_reg && v.by_ref) {
				xbb_u8(&expr, cast(u8)(XDW_OP_breg0 + v.dwarf_reg));
				xbb_sleb(&expr, 0);
			} else if (v.in_reg && v.dwarf_reg >= 32) {
				xbb_u8(&expr, XDW_OP_regx);
				xbb_uleb(&expr, v.dwarf_reg);
			} else if (v.in_reg) {
				xbb_u8(&expr, cast(u8)(XDW_OP_reg0 + v.dwarf_reg));
			} else {
				// the frame pointer is the frame base
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
		};
		xbDwarfScopes sc = {};
		sc.eff = array_make<i32>(heap_allocator(), 0, 0);
		sc.kid = array_make<i32>(heap_allocator(), 0, 0);
		sc.sib = array_make<i32>(heap_allocator(), 0, 0);
		sc.head = array_make<i32>(heap_allocator(), 0, 0);
		sc.tail = array_make<i32>(heap_allocator(), 0, 0);
		sc.var_head = array_make<i32>(heap_allocator(), 0, 0);
		sc.var_tail = array_make<i32>(heap_allocator(), 0, 0);
		sc.var_next = array_make<i32>(heap_allocator(), 0, 0);
		sc.site = array_make<i32>(heap_allocator(), 0, 0);
		sc.pool = array_make<xbDwarfScopes::Range>(heap_allocator(), 0, 0);
		// a block's variables, then its blocks, nested like the scopes
		auto emit_block = [&](auto &self, xbProcDebug const &pd, i32 s) -> void {
			for (i32 i = sc.var_head[s]; i >= 0; i = sc.var_next[i]) emit_var(pd.vars[i]);
			for (i32 c = sc.kid[s]; c >= 0; c = sc.sib[c]) {
				xbDwarfScopes::Range const &r = sc.pool[sc.head[c]];
				xbInlineSite const *site = sc.site[c] >= 0 ? &pd.inline_sites[sc.site[c]] : nullptr;
				auto origin = [&]() {
					u32 *at = string_map_get(&abstract_dies, site->name);
					GB_ASSERT(at != nullptr);
					xbb_u32(b, *at);
				};
				auto call_site = [&]() {
					xbb_uleb(b, cast(u64)gb_max(site->call_file, 1));
					xbb_uleb(b, cast(u64)gb_max(site->call_line, 0));
					xbb_uleb(b, cast(u64)gb_max(site->call_column, 0));
				};
				if (r.next < 0) {
					xbb_uleb(b, site ? xbAbbrev_InlinedSubroutine : xbAbbrev_LexicalBlock);
					if (site) origin();
					xbDwarfAddr a = {b->count, -1, pd.start + r.lo};
					array_add(&d->info_addrs, a);
					xbb_u64(b, 0);
					xbb_u32(b, cast(u32)(r.hi - r.lo));
					if (site) call_site();
				} else {
					xbb_uleb(b, site ? xbAbbrev_InlinedSubroutineRanges : xbAbbrev_LexicalBlockRanges);
					if (site) origin();
					array_add(&d->ranges_refs, b->count);
					xbb_u32(b, cast(u32)d->ranges.count);
					// offsets from the unit's low_pc, the start of the text section
					for (i32 k = sc.head[c]; k >= 0; k = sc.pool[k].next) {
						xbb_u64(&d->ranges, cast(u64)(pd.start + sc.pool[k].lo));
						xbb_u64(&d->ranges, cast(u64)(pd.start + sc.pool[k].hi));
					}
					xbb_u64(&d->ranges, 0);
					xbb_u64(&d->ranges, 0);
					if (site) call_site();
				}
				self(self, pd, c);
				xbb_u8(b, 0);
			}
		};

		for (xbProcDebug const &pd : m->proc_debug) {
			bool has_children = pd.vars.count > 0 || pd.inline_sites.count > 0;
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
			xbDwarfAddr r = {b->count, -1, pd.start};
			array_add(&d->info_addrs, r);
			xbb_u64(b, 0);
			xbb_u32(b, cast(u32)(pd.end - pd.start));
			xbb_uleb(b, 1);
			xbb_u8(b, pd.naked ? XDW_OP_call_frame_cfa : frame_reg);
			xbb_uleb(b, cast(u64)gb_max(pd.file_id, 1));
			xbb_uleb(b, cast(u64)gb_max(pd.line, 0));
			if (ret) xb_dwarf_type_ref(&dt, ret);
			if (has_children) {
				xb_dwarf_scopes(&sc, pd, cast(i32)(pd.end - pd.start));
				emit_block(emit_block, pd, 0);
				xbb_u8(b, 0);
			}
		}

		array_free(&sc.eff); array_free(&sc.kid); array_free(&sc.sib);
		array_free(&sc.head); array_free(&sc.tail); array_free(&sc.pool);
		array_free(&sc.var_head); array_free(&sc.var_tail); array_free(&sc.var_next);
		array_free(&sc.site);
		string_map_destroy(&abstract_dies);

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
