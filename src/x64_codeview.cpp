// CodeView debug info in .debug$S (symbols, line tables) and .debug$T (types),
// from which lld-link builds the PDB.
//
// Struct, union and enum types are written as a forward reference first and
// defined later, so pointers can refer to a type that is still being built.

enum : u16 {
	XCV_LF_POINTER    = 0x1002,
	XCV_LF_PROCEDURE  = 0x1008,
	XCV_LF_ARGLIST    = 0x1201,
	XCV_LF_FIELDLIST  = 0x1203,
	XCV_LF_BITFIELD   = 0x1205,
	XCV_LF_INDEX      = 0x1404,
	XCV_LF_ENUMERATE  = 0x1502,
	XCV_LF_ARRAY      = 0x1503,
	XCV_LF_STRUCTURE  = 0x1505,
	XCV_LF_UNION      = 0x1506,
	XCV_LF_ENUM       = 0x1507,
	XCV_LF_MEMBER     = 0x150d,

	XCV_LF_CHAR       = 0x8000,
	XCV_LF_SHORT      = 0x8001,
	XCV_LF_USHORT     = 0x8002,
	XCV_LF_LONG       = 0x8003,
	XCV_LF_ULONG      = 0x8004,
	XCV_LF_QUADWORD   = 0x8009,
	XCV_LF_UQUADWORD  = 0x800a,

	XCV_S_END         = 0x0006,
	XCV_S_FRAMEPROC   = 0x1012,
	XCV_S_OBJNAME     = 0x1101,
	XCV_S_REGISTER    = 0x1106,
	XCV_S_CONSTANT    = 0x1107,
	XCV_S_LDATA32     = 0x110c,
	XCV_S_GDATA32     = 0x110d,
	XCV_S_REGREL32    = 0x1111,
	XCV_S_LTHREAD32   = 0x1112,
	XCV_S_GTHREAD32   = 0x1113,
	XCV_S_GPROC32     = 0x1110,
	XCV_S_BLOCK32     = 0x1103,
	XCV_S_COMPILE3    = 0x113c,

	XCV_DEBUG_S_SYMBOLS    = 0xf1,
	XCV_DEBUG_S_LINES      = 0xf2,
	XCV_DEBUG_S_STRINGTABLE = 0xf3,
	XCV_DEBUG_S_FILECHKSMS = 0xf4,

	XCV_PROP_FWDREF        = 0x80,
	XCV_PROP_HASUNIQUENAME = 0x200,

	XCV_AMD64_RBP = 334,
};

// simple types
enum : u32 {
	XCV_T_NOTYPE  = 0x00,
	XCV_T_VOID    = 0x03,
	XCV_T_CHAR    = 0x10,
	XCV_T_SHORT   = 0x11,
	XCV_T_QUAD    = 0x13,
	XCV_T_INT128  = 0x78,
	XCV_T_UCHAR   = 0x20,
	XCV_T_USHORT  = 0x21,
	XCV_T_UQUAD   = 0x23,
	XCV_T_UINT128 = 0x79,
	XCV_T_BOOL08  = 0x30,
	XCV_T_REAL32  = 0x40,
	XCV_T_REAL64  = 0x41,
	XCV_T_REAL16  = 0x46,
	XCV_T_RCHAR   = 0x70,
	XCV_T_INT4    = 0x74,
	XCV_T_UINT4   = 0x75,
	XCV_T_CHAR32  = 0x7b,
	XCV_T_64PUCHAR = 0x620,
	XCV_T_64PRCHAR = 0x670,
	XCV_T_64PWCHAR = 0x671,
};

struct xbCv {
	xbCoffWriter *w;
	Array<u8> *t;
	u32 next_index;
	PtrMap<Type *, u32> types;
	PtrMap<Type *, u32> refs;    // reference-to-type, for variables reached through a pointer
	Array<Type *> to_define;      // forward referenced, definition still to write
	Array<u32> to_define_index;
};

gb_internal void xb_cv_numeric(Array<u8> *b, i64 v) {
	if (v >= 0 && v < 0x8000) {
		xbb_u16(b, cast(u16)v);
	} else if (v >= -128 && v < 128) {
		xbb_u16(b, XCV_LF_CHAR); xbb_u8(b, cast(u8)cast(i8)v);
	} else if (v >= -32768 && v < 32768) {
		xbb_u16(b, XCV_LF_SHORT); xbb_u16(b, cast(u16)cast(i16)v);
	} else if (v >= 0 && v < 0x10000) {
		xbb_u16(b, XCV_LF_USHORT); xbb_u16(b, cast(u16)v);
	} else if (v >= I32_MIN && v <= I32_MAX) {
		xbb_u16(b, XCV_LF_LONG); xbb_u32(b, cast(u32)cast(i32)v);
	} else if (v >= 0 && v <= cast(i64)U32_MAX) {
		xbb_u16(b, XCV_LF_ULONG); xbb_u32(b, cast(u32)v);
	} else {
		xbb_u16(b, XCV_LF_QUADWORD); xbb_u64(b, cast(u64)v);
	}
}

gb_internal void xb_cv_name(Array<u8> *b, String s) {
	xbb_bytes(b, s.text, s.len);
	xbb_u8(b, 0);
}

// a type record: length, kind, then the caller's bytes; returns where it starts
gb_internal isize xb_cv_type_begin(xbCv *cv, u16 kind) {
	isize at = cv->t->count;
	xbb_u16(cv->t, 0);
	xbb_u16(cv->t, kind);
	return at;
}

gb_internal u32 xb_cv_type_end(xbCv *cv, isize at) {
	Array<u8> *b = cv->t;
	// LF_PAD3 LF_PAD2 LF_PAD1
	while (b->count % 4 != 0) xbb_u8(b, cast(u8)(0xf0 | (4 - b->count % 4)));
	u16 len = cast(u16)(b->count - at - 2);
	gb_memmove(b->data + at, &len, 2);
	return cv->next_index++;
}

// fields are padded inside a field list too
gb_internal void xb_cv_field_pad(Array<u8> *b) {
	while (b->count % 4 != 0) xbb_u8(b, cast(u8)(0xf0 | (4 - b->count % 4)));
}

gb_internal u32 xb_cv_type(xbCv *cv, Type *t);

gb_internal u32 xb_cv_pointer(xbCv *cv, u32 referent, bool reference) {
	isize at = xb_cv_type_begin(cv, XCV_LF_POINTER);
	xbb_u32(cv->t, referent);
	u32 attr = 0x0c | ((reference ? 1u : 0u) << 5) | (8u << 13); // 64-bit, size 8
	xbb_u32(cv->t, attr);
	return xb_cv_type_end(cv, at);
}

gb_internal u32 xb_cv_array(xbCv *cv, u32 elem, i64 size) {
	isize at = xb_cv_type_begin(cv, XCV_LF_ARRAY);
	xbb_u32(cv->t, elem);
	xbb_u32(cv->t, XCV_T_UQUAD);
	xb_cv_numeric(cv->t, size);
	xbb_u8(cv->t, 0); // no name
	return xb_cv_type_end(cv, at);
}

gb_internal String xb_cv_type_name(Type *t) {
	return type_to_canonical_string(permanent_allocator(), t);
}

gb_internal String xb_cv_unique_name(Type *t, String name) {
	char buf[32] = {};
	gb_snprintf(buf, gb_size_of(buf), "@%llx", cast(unsigned long long)type_hash_canonical_type(t));
	return concatenate_strings(permanent_allocator(), name, make_string_c(buf));
}

// the forward reference of a struct, union or enum
gb_internal u32 xb_cv_forward(xbCv *cv, Type *t, u16 kind) {
	String name = xb_cv_type_name(t);
	isize at = xb_cv_type_begin(cv, kind);
	Array<u8> *b = cv->t;
	xbb_u16(b, 0); // member count
	xbb_u16(b, XCV_PROP_FWDREF | XCV_PROP_HASUNIQUENAME);
	if (kind == XCV_LF_ENUM) {
		xbb_u32(b, 0); // underlying type
		xbb_u32(b, 0); // field list
	} else {
		xbb_u32(b, 0); // field list
		if (kind == XCV_LF_STRUCTURE) {
			xbb_u32(b, 0); // derived from
			xbb_u32(b, 0); // vtable shape
		}
		xb_cv_numeric(b, 0);
	}
	xb_cv_name(b, name);
	xb_cv_name(b, xb_cv_unique_name(t, name));
	u32 index = xb_cv_type_end(cv, at);
	array_add(&cv->to_define, t);
	return index;
}

// A field list from serialized fields. A record holds at most 64K, so a long list is
// split, each part continued (LF_INDEX) by the one written before it.
gb_internal u32 xb_cv_fieldlist(xbCv *cv, Array<u8> const &fields, Array<isize> const &starts) {
	isize const limit = 0xff00 - 16;
	isize n = starts.count;
	u32 next = 0;
	isize end = fields.count;
	isize first = n;
	while (first > 0) {
		// the last fields that fit
		isize i = first - 1;
		while (i > 0 && end - starts[i-1] <= limit) i--;
		Array<u8> *b = cv->t;
		isize at = xb_cv_type_begin(cv, XCV_LF_FIELDLIST);
		xbb_bytes(b, fields.data + starts[i], end - starts[i]);
		if (next != 0) {
			xbb_u16(b, XCV_LF_INDEX);
			xbb_u16(b, 0);
			xbb_u32(b, next);
		}
		next = xb_cv_type_end(cv, at);
		end = starts[i];
		first = i;
	}
	if (next == 0) {
		next = xb_cv_type_end(cv, xb_cv_type_begin(cv, XCV_LF_FIELDLIST));
	}
	return next;
}

struct xbCvMember {
	String name;
	u32 type;
	i64 offset;
};

gb_internal u32 xb_cv_record_def(xbCv *cv, Type *t, u16 kind, i64 size, Array<xbCvMember> const &members) {
	Array<u8> *b = cv->t;
	auto fields = array_make<u8>(heap_allocator(), 0, 256);
	auto starts = array_make<isize>(heap_allocator(), 0, members.count);
	for (xbCvMember const &mem : members) {
		array_add(&starts, fields.count);
		xbb_u16(&fields, XCV_LF_MEMBER);
		xbb_u16(&fields, 3); // public
		xbb_u32(&fields, mem.type);
		xb_cv_numeric(&fields, mem.offset);
		xb_cv_name(&fields, mem.name);
		xb_cv_field_pad(&fields);
	}
	u32 field_list = xb_cv_fieldlist(cv, fields, starts);
	array_free(&fields);
	array_free(&starts);

	String name = xb_cv_type_name(t);
	isize at = xb_cv_type_begin(cv, kind);
	xbb_u16(b, cast(u16)members.count);
	xbb_u16(b, XCV_PROP_HASUNIQUENAME);
	xbb_u32(b, field_list);
	if (kind == XCV_LF_STRUCTURE) {
		xbb_u32(b, 0);
		xbb_u32(b, 0);
	}
	xb_cv_numeric(b, size);
	xb_cv_name(b, name);
	xb_cv_name(b, xb_cv_unique_name(t, name));
	return xb_cv_type_end(cv, at);
}

gb_internal u32 xb_cv_basic(Type *bt) {
	i64 size = type_size_of(bt);
	switch (bt->Basic.kind) {
	case Basic_bool: case Basic_b8: case Basic_llvm_bool: return XCV_T_BOOL08;
	case Basic_b16: return 0x31;
	case Basic_b32: return 0x32;
	case Basic_b64: return 0x33;
	case Basic_f16: case Basic_f16le: case Basic_f16be: return XCV_T_REAL16;
	case Basic_f32: case Basic_f32le: case Basic_f32be: return XCV_T_REAL32;
	case Basic_f64: case Basic_f64le: case Basic_f64be: return XCV_T_REAL64;
	case Basic_rawptr: return XCV_T_64PUCHAR; // LLVM's rawptr points to an 8 bit "void"
	case Basic_cstring: return XCV_T_64PRCHAR;
	case Basic_cstring16: return XCV_T_64PWCHAR;
	case Basic_rune: return XCV_T_CHAR32;
	case Basic_typeid: return XCV_T_UQUAD;
	}
	if (bt->Basic.flags & BasicFlag_Integer) {
		bool u = (bt->Basic.flags & BasicFlag_Unsigned) != 0;
		switch (size) {
		case 1:  return u ? XCV_T_UCHAR : XCV_T_CHAR;
		case 2:  return u ? XCV_T_USHORT : XCV_T_SHORT;
		case 4:  return u ? XCV_T_UINT4 : XCV_T_INT4;
		case 8:  return u ? XCV_T_UQUAD : XCV_T_QUAD;
		case 16: return u ? XCV_T_UINT128 : XCV_T_INT128;
		}
	}
	return 0;
}

gb_internal bool xb_cv_is_record(Type *bt) {
	switch (bt->kind) {
	case Type_Struct:
		return bt->Struct.soa_kind == StructSoa_None;
	case Type_Union:
	case Type_Enum:
	case Type_Slice:
	case Type_DynamicArray:
	case Type_Map:
		return true;
	case Type_BitField:
		return bt->BitField.fields.count > 0;
	case Type_BitSet:
		return type_size_of(bt) > 0;
	case Type_Basic:
		return bt->Basic.kind == Basic_string || bt->Basic.kind == Basic_any || bt->Basic.kind == Basic_string16 ||
		       is_type_complex(bt) || is_type_quaternion(bt);
	}
	return false;
}

gb_internal u32 xb_cv_type(xbCv *cv, Type *t) {
	t = default_type(t);
	u32 *found = map_get(&cv->types, t);
	if (found) return *found;

	Type *bt = base_type(t);
	u32 index = 0;
	if (t->kind == Type_Named && !xb_cv_is_record(bt)) {
		// CodeView has no typedefs worth using: the base type stands in
		index = xb_cv_type(cv, bt);
	} else if (xb_cv_is_record(bt)) {
		u16 kind = XCV_LF_STRUCTURE;
		if (bt->kind == Type_Enum) kind = XCV_LF_ENUM;
		if (bt->kind == Type_Struct && bt->Struct.is_raw_union) kind = XCV_LF_UNION;
		if (bt->kind == Type_BitSet) kind = XCV_LF_UNION;
		index = xb_cv_forward(cv, t, kind);
		array_add(&cv->to_define_index, index);
	} else {
		switch (bt->kind) {
		case Type_Basic:
			index = xb_cv_basic(bt);
			if (index == 0) {
				// complex, quaternion, string16, ...: raw bytes
				index = xb_cv_array(cv, XCV_T_UCHAR, type_size_of(bt));
			}
			break;
		case Type_Pointer:
			index = xb_cv_pointer(cv, xb_cv_type(cv, bt->Pointer.elem), false);
			break;
		case Type_MultiPointer:
			index = xb_cv_pointer(cv, xb_cv_type(cv, bt->MultiPointer.elem), false);
			break;
		case Type_SoaPointer:
			index = xb_cv_array(cv, XCV_T_UCHAR, type_size_of(bt));
			break;
		case Type_Proc: {
			// a pointer to the procedure type
			TEMPORARY_ALLOCATOR_GUARD();
			auto args = array_make<u32>(temporary_allocator(), 0, 8);
			if (bt->Proc.params) {
				for (Entity *e : bt->Proc.params->Tuple.variables) {
					if (e->kind == Entity_Variable) array_add(&args, xb_cv_type(cv, e->type));
				}
			}
			u32 ret = XCV_T_VOID;
			if (bt->Proc.result_count == 1) {
				ret = xb_cv_type(cv, bt->Proc.results->Tuple.variables[0]->type);
			}
			isize al = xb_cv_type_begin(cv, XCV_LF_ARGLIST);
			xbb_u32(cv->t, cast(u32)args.count);
			for (u32 a : args) xbb_u32(cv->t, a);
			u32 arglist = xb_cv_type_end(cv, al);
			isize at = xb_cv_type_begin(cv, XCV_LF_PROCEDURE);
			xbb_u32(cv->t, ret);
			xbb_u8(cv->t, 0); // near C
			xbb_u8(cv->t, 0);
			xbb_u16(cv->t, cast(u16)args.count);
			xbb_u32(cv->t, arglist);
			u32 proc = xb_cv_type_end(cv, at);
			index = xb_cv_pointer(cv, proc, false);
			break;
		}
		case Type_Array:
			index = xb_cv_array(cv, xb_cv_type(cv, bt->Array.elem), type_size_of(bt));
			break;
		case Type_EnumeratedArray:
			index = xb_cv_array(cv, xb_cv_type(cv, bt->EnumeratedArray.elem), type_size_of(bt));
			break;
		case Type_SimdVector:
			index = xb_cv_array(cv, xb_cv_type(cv, bt->SimdVector.elem), type_size_of(bt));
			break;
		case Type_Matrix:
			index = xb_cv_array(cv, xb_cv_type(cv, bt->Matrix.elem), type_size_of(bt));
			break;
		case Type_BitSet:
			index = xb_cv_type(cv, bit_set_to_int(bt));
			break;
		default:
			index = xb_cv_array(cv, XCV_T_UCHAR, type_size_of(bt));
			break;
		}
	}
	map_set(&cv->types, t, index);
	return index;
}

// The full definition of a forward referenced type.
gb_internal void xb_cv_define(xbCv *cv, Type *t) {
	Type *bt = base_type(t);
	i64 size = type_size_of(bt);
	auto members = array_make<xbCvMember>(heap_allocator(), 0, 16);
	defer (array_free(&members));
	auto add = [&](String name, Type *type, i64 offset) {
		xbCvMember mem = {name, xb_cv_type(cv, type), offset};
		array_add(&members, mem);
	};
	auto add_struct_like = [&](std::initializer_list<std::pair<char const *, Type *>> fields) {
		i64 off = 0;
		for (auto const &f : fields) {
			i64 align = type_align_of(f.second);
			off = (off + align - 1) / align * align;
			add(make_string_c(f.first), f.second, off);
			off += type_size_of(f.second);
		}
	};

	switch (bt->kind) {
	case Type_Basic:
		if (bt->Basic.kind == Basic_string) {
			add_struct_like({{"data", t_u8_ptr}, {"len", t_int}});
		} else if (bt->Basic.kind == Basic_string16) {
			add_struct_like({{"data", t_u16_ptr}, {"len", t_int}});
		} else if (is_type_complex(bt)) {
			Type *e = base_complex_elem_type(bt);
			add_struct_like({{"real", e}, {"imag", e}});
		} else if (is_type_quaternion(bt)) {
			Type *e = base_complex_elem_type(bt);
			add_struct_like({{"imag", e}, {"jmag", e}, {"kmag", e}, {"real", e}});
		} else {
			add_struct_like({{"data", t_rawptr}, {"id", t_typeid}});
		}
		break;
	case Type_Slice:
		add_struct_like({{"data", alloc_type_pointer(bt->Slice.elem)}, {"len", t_int}});
		break;
	case Type_DynamicArray:
		add_struct_like({{"data", alloc_type_pointer(bt->DynamicArray.elem)}, {"len", t_int}, {"cap", t_int}, {"allocator", t_allocator}});
		break;
	case Type_Enum: {
		u32 utype = xb_cv_type(cv, bt->Enum.base_type);
		Array<u8> *b = cv->t;
		auto fields = array_make<u8>(heap_allocator(), 0, 256);
		auto starts = array_make<isize>(heap_allocator(), 0, bt->Enum.fields.count);
		for (Entity *f : bt->Enum.fields) {
			array_add(&starts, fields.count);
			xbb_u16(&fields, XCV_LF_ENUMERATE);
			xbb_u16(&fields, 3);
			xb_cv_numeric(&fields, exact_value_to_i64(f->Constant.value));
			xb_cv_name(&fields, f->token.string);
			xb_cv_field_pad(&fields);
		}
		u32 field_list = xb_cv_fieldlist(cv, fields, starts);
		array_free(&fields);
		array_free(&starts);
		String name = xb_cv_type_name(t);
		isize at = xb_cv_type_begin(cv, XCV_LF_ENUM);
		xbb_u16(b, cast(u16)bt->Enum.fields.count);
		xbb_u16(b, XCV_PROP_HASUNIQUENAME);
		xbb_u32(b, utype);
		xbb_u32(b, field_list);
		xb_cv_name(b, name);
		xb_cv_name(b, xb_cv_unique_name(t, name));
		xb_cv_type_end(cv, at);
		return;
	}
	case Type_Map: {
		init_map_internal_debug_types(bt);
		Type *st = base_type(bt->Map.debug_metadata_type);
		type_set_offsets(st);
		for_array(i, st->Struct.fields) {
			add(st->Struct.fields[i]->token.string, st->Struct.fields[i]->type, st->Struct.offsets[i]);
		}
		break;
	}
	case Type_Struct:
		type_set_offsets(bt);
		for_array(i, bt->Struct.fields) {
			Entity *f = bt->Struct.fields[i];
			add(f->token.string, f->type, bt->Struct.is_raw_union ? 0 : bt->Struct.offsets[i]);
		}
		break;
	case Type_Union: {
		// {variants..., tag}, numbered like LLVM's: from 1 when the union can be nil
		if (bt->Union.variants.count > 0 && !is_type_union_maybe_pointer(bt) && size > 0) {
			add(str_lit("tag"), union_tag_type(bt), bt->Union.variant_block_size);
		}
		isize first = (is_type_union_maybe_pointer(bt) || bt->Union.kind == UnionType_no_nil) ? 0 : 1;
		for_array(i, bt->Union.variants) {
			Type *v = bt->Union.variants[i];
			if (type_size_of(v) == 0) continue;
			char buf[32] = {};
			gb_snprintf(buf, gb_size_of(buf), "v%td", first+i);
			add(copy_string(permanent_allocator(), make_string_c(buf)), v, 0);
		}
		break;
	}
	case Type_BitField: {
		u64 offset = 0;
		for_array(i, bt->BitField.fields) {
			Entity *f = bt->BitField.fields[i];
			u8 bits = bt->BitField.bit_sizes[i];
			u32 base = xb_cv_type(cv, bt->BitField.backing_type);
			isize at = xb_cv_type_begin(cv, XCV_LF_BITFIELD);
			xbb_u32(cv->t, base);
			xbb_u8(cv->t, bits);
			xbb_u8(cv->t, cast(u8)offset);
			xbCvMember mem = {f->token.string, xb_cv_type_end(cv, at), 0};
			array_add(&members, mem);
			offset += bits;
		}
		break;
	}
	case Type_BitSet: {
		// a union of one bit bools named after the elements, like LLVM's
		auto add_bit = [&](String name, i64 bit) {
			isize at = xb_cv_type_begin(cv, XCV_LF_BITFIELD);
			xbb_u32(cv->t, XCV_T_BOOL08);
			xbb_u8(cv->t, 1);
			xbb_u8(cv->t, cast(u8)bit);
			xbCvMember mem = {name, xb_cv_type_end(cv, at), 0};
			array_add(&members, mem);
		};
		Type *elem = base_type(bt->BitSet.elem);
		if (elem->kind == Type_Enum) {
			for (Entity *f : elem->Enum.fields) {
				i64 bit = exact_value_to_i64(f->Constant.value) - bt->BitSet.lower;
				if (0 <= bit && bit < 8*size) add_bit(f->token.string, bit);
			}
		} else {
			for (i64 bit = 0; bit <= bt->BitSet.upper - bt->BitSet.lower && bit < 8*size; bit++) {
				char buf[32] = {};
				gb_snprintf(buf, gb_size_of(buf), "%lld", cast(long long)(bt->BitSet.lower + bit));
				add_bit(copy_string(permanent_allocator(), make_string_c(buf)), bit);
			}
		}
		break;
	}
	}
	u16 kind = ((bt->kind == Type_Struct && bt->Struct.is_raw_union) || bt->kind == Type_BitSet) ? XCV_LF_UNION : XCV_LF_STRUCTURE;
	xb_cv_record_def(cv, t, kind, size, members);
}

////////////////////////////////////////////////////////////////
// Symbols
////////////////////////////////////////////////////////////////

// a symbol record: length, kind, then the caller's bytes
gb_internal isize xb_cv_sym_begin(Array<u8> *b, u16 kind) {
	isize at = b->count;
	xbb_u16(b, 0);
	xbb_u16(b, kind);
	return at;
}

gb_internal void xb_cv_sym_end(Array<u8> *b, isize at) {
	while (b->count % 4 != 0) xbb_u8(b, 0);
	u16 len = cast(u16)(b->count - at - 2);
	gb_memmove(b->data + at, &len, 2);
}

gb_internal isize xb_cv_subsection_begin(Array<u8> *b, u32 kind) {
	xbb_u32(b, kind);
	isize at = b->count;
	xbb_u32(b, 0);
	return at;
}

gb_internal void xb_cv_subsection_end(Array<u8> *b, isize at) {
	u32 len = cast(u32)(b->count - at - 4);
	gb_memmove(b->data + at, &len, 4);
	while (b->count % 4 != 0) xbb_u8(b, 0);
}

// secrel32 + section16 of a code offset or a symbol
gb_internal void xb_cv_addr(xbCoffWriter *w, Array<u8> *b, i32 sym, i64 text_offset) {
	xbModule *m = w->m;
	xbCoffSec sec = xbCoff_Text;
	i64 off = text_offset;
	i32 rsym = -1;
	if (sym >= 0) {
		xbSymbol const &s = m->symbols[sym];
		if (s.flags & xbSymbolFlag_Global) {
			rsym = sym;
			off = 0;
		} else {
			sec = xb_coff_section_of(s.section);
			off = xb_coff_symbol_offset(w, s);
		}
	}
	xbCoffReloc r1 = {cast(u32)b->count, rsym, sec, XB_IMAGE_REL_AMD64_SECREL};
	array_add(&w->relocs[xbCoff_DebugS], r1);
	xbb_u32(b, cast(u32)off);
	xbCoffReloc r2 = {cast(u32)b->count, rsym, sec, XB_IMAGE_REL_AMD64_SECTION};
	array_add(&w->relocs[xbCoff_DebugS], r2);
	xbb_u16(b, 0);
}

gb_internal u16 xb_cv_reg_of_dwarf(u8 dwarf_reg) {
	// DWARF numbers rax, rdx, rcx, rbx, rsi, rdi, rbp, rsp, then r8..r15, then xmm0..xmm15
	static u16 const low[8] = {328, 331, 330, 329, 332, 333, 334, 335};
	if (dwarf_reg < 8) return low[dwarf_reg];
	if (dwarf_reg >= 17) return cast(u16)(dwarf_reg < 25 ? 154 + (dwarf_reg - 17) : 252 + (dwarf_reg - 25));
	return cast(u16)(336 + (dwarf_reg - 8));
}

// Where each lexical scope's code is, and which scopes get a block. Like LLVM, a scope
// without variables of its own, or whose code is interleaved with a sibling's, gets no
// block: its variables and blocks go to the parent.
struct xbCvScopes {
	Array<i32> lo, hi;     // the hull of the scope's code, cold code left out
	Array<i32> eff;        // the scope whose block holds the scope's variables
	Array<Array<i32>> kids; // the blocks directly inside a block
};

gb_internal void xb_cv_scopes_free(xbCvScopes *sc) {
	for (auto &k : sc->kids) array_free(&k);
	array_free(&sc->lo); array_free(&sc->hi); array_free(&sc->eff); array_free(&sc->kids);
}

gb_internal xbCvScopes xb_cv_scopes(xbProcDebug const &pd, u32 len) {
	xbCvScopes sc = {};
	isize n = gb_max(pd.scope_parent.count, cast(isize)1);
	auto parent = [&](i32 s) -> i32 { return s < pd.scope_parent.count ? pd.scope_parent[s] : -1; };
	sc.lo = array_make<i32>(heap_allocator(), n, n);
	sc.hi = array_make<i32>(heap_allocator(), n, n);
	sc.eff = array_make<i32>(heap_allocator(), n, n);
	sc.kids = array_make<Array<i32>>(heap_allocator(), n, n);
	for (isize s = 0; s < n; s++) {
		sc.lo[s] = I32_MAX;
		sc.hi[s] = 0;
		sc.kids[s] = array_make<i32>(heap_allocator(), 0, 0);
	}
	auto const &marks = pd.scope_marks;
	for_array(k, marks) {
		i32 lo = marks[k].code_offset;
		i32 hi = k+1 < marks.count ? marks[k+1].code_offset : cast(i32)len;
		if (marks[k].cold || hi <= lo) continue;
		for (i32 s = marks[k].scope; s >= 0; s = parent(s)) {
			sc.lo[s] = gb_min(sc.lo[s], lo);
			sc.hi[s] = gb_max(sc.hi[s], hi);
		}
	}
	// whether t is s or inside it, a scope's id is above its parent's
	auto inside = [&](i32 t, i32 s) -> bool {
		while (t > s) t = parent(t);
		return t == s;
	};
	auto own = array_make<i32>(heap_allocator(), n, n);
	for (isize s = 0; s < n; s++) own[s] = 0;
	for (xbDebugVar const &v : pd.vars) {
		if (v.scope < n) own[v.scope] += 1;
	}
	// parents first, by the ids
	for (isize s = 0; s < n; s++) {
		bool ok = s == 0 || (own[s] > 0 && sc.lo[s] < sc.hi[s]);
		for_array(k, marks) {
			if (!ok || s == 0) break;
			i32 lo = marks[k].code_offset;
			i32 hi = k+1 < marks.count ? marks[k+1].code_offset : cast(i32)len;
			if (marks[k].cold || hi <= lo || hi <= sc.lo[s] || lo >= sc.hi[s]) continue;
			i32 t = marks[k].scope;
			if (!inside(t, cast(i32)s) && !inside(cast(i32)s, t)) ok = false;
		}
		sc.eff[s] = ok ? cast(i32)s : sc.eff[parent(cast(i32)s)];
		if (ok && s > 0) array_add(&sc.kids[sc.eff[parent(cast(i32)s)]], cast(i32)s);
	}
	array_free(&own);
	return sc;
}

gb_internal void xb_codeview_emit(xbCoffWriter *w) {
	xbModule *m = w->m;
	xbCv cv_ = {};
	xbCv *cv = &cv_;
	cv->w = w;
	cv->t = &w->sec[xbCoff_DebugT];
	cv->next_index = 0x1000;
	map_init(&cv->types);
	map_init(&cv->refs);
	cv->to_define = array_make<Type *>(heap_allocator(), 0, 256);
	cv->to_define_index = array_make<u32>(heap_allocator(), 0, 256);
	xbb_u32(cv->t, 4); // CV_SIGNATURE_C13

	auto type_of = [&](Type *t, bool by_ref) -> u32 {
		u32 index = xb_cv_type(cv, t);
		if (!by_ref) return index;
		u32 *found = map_get(&cv->refs, t);
		if (found) return *found;
		u32 ref = xb_cv_pointer(cv, index, true);
		map_set(&cv->refs, t, ref);
		return ref;
	};

	xb_add_debug_constants(m);

	Array<u8> *b = &w->sec[xbCoff_DebugS];
	xbb_u32(b, 4); // CV_SIGNATURE_C13

	{
		isize ss = xb_cv_subsection_begin(b, XCV_DEBUG_S_SYMBOLS);
		isize at = xb_cv_sym_begin(b, XCV_S_OBJNAME);
		xbb_u32(b, 0);
		xb_cv_name(b, m->object_path);
		xb_cv_sym_end(b, at);
		at = xb_cv_sym_begin(b, XCV_S_COMPILE3);
		xbb_u32(b, 0);     // C, no flags
		xbb_u16(b, 0xd0);  // x64
		for (isize i = 0; i < 8; i++) xbb_u16(b, 0); // front and back end versions
		xb_cv_name(b, str_lit("odin (x64 backend)"));
		xb_cv_sym_end(b, at);
		xb_cv_subsection_end(b, ss);
	}

	for (xbProcDebug const &pd : m->proc_debug) {
		isize ss = xb_cv_subsection_begin(b, XCV_DEBUG_S_SYMBOLS);
		u32 proc_type = 0;
		if (pd.type) {
			Type *pt = base_type(pd.type);
			if (pt && pt->kind == Type_Proc) {
				// the pointer's referent is the LF_PROCEDURE, written just before it
				proc_type = xb_cv_type(cv, pd.type) - 1;
			}
		}
		u32 len = cast(u32)(pd.end - pd.start);
		isize at = xb_cv_sym_begin(b, XCV_S_GPROC32);
		xbb_u32(b, 0); // parent, end, next: lld-link fills them in
		xbb_u32(b, 0);
		xbb_u32(b, 0);
		xbb_u32(b, len);
		u32 body = pd.win_alloc_at ? pd.win_alloc_at : pd.win_setfp_at;
		xbb_u32(b, body);
		xbb_u32(b, len);
		xbb_u32(b, proc_type);
		xb_cv_addr(w, b, -1, pd.start);
		xbb_u8(b, 0);
		xb_cv_name(b, pd.link_name);
		xb_cv_sym_end(b, at);

		at = xb_cv_sym_begin(b, XCV_S_FRAMEPROC);
		xbb_u32(b, cast(u32)pd.win_alloc_size);
		xbb_u32(b, 0);
		xbb_u32(b, 0);
		xbb_u32(b, cast(u32)(8*pd.win_push_count + 16*pd.win_xmm_count));
		xbb_u32(b, 0);
		xbb_u16(b, 0);
		xbb_u32(b, (2u << 14) | (2u << 16)); // locals and parameters off rbp
		xb_cv_sym_end(b, at);

		auto emit_var = [&](xbDebugVar const &v) {
			isize at = 0;
			if (v.local < 0) {
				xbSymbol const &s = m->symbols[v.sym];
				bool tls = (s.flags & xbSymbolFlag_TLS) != 0;
				at = xb_cv_sym_begin(b, tls ? XCV_S_LTHREAD32 : XCV_S_LDATA32);
				xbb_u32(b, type_of(v.type, false));
				xb_cv_addr(w, b, v.sym, 0);
				xb_cv_name(b, v.name);
				xb_cv_sym_end(b, at);
				return;
			}
			if (v.in_reg && v.by_ref) {
				// the register holds the variable's address: it is at [reg+0]
				at = xb_cv_sym_begin(b, XCV_S_REGREL32);
				xbb_u32(b, 0);
				xbb_u32(b, type_of(v.type, false));
				xbb_u16(b, xb_cv_reg_of_dwarf(v.dwarf_reg));
				xb_cv_name(b, v.name);
				xb_cv_sym_end(b, at);
				return;
			}
			if (v.in_reg) {
				at = xb_cv_sym_begin(b, XCV_S_REGISTER);
				xbb_u32(b, type_of(v.type, false));
				xbb_u16(b, xb_cv_reg_of_dwarf(v.dwarf_reg));
				xb_cv_name(b, v.name);
				xb_cv_sym_end(b, at);
				return;
			}
			at = xb_cv_sym_begin(b, XCV_S_REGREL32);
			xbb_u32(b, cast(u32)v.frame_offset_fixup);
			xbb_u32(b, type_of(v.type, v.by_ref));
			xbb_u16(b, XCV_AMD64_RBP);
			xb_cv_name(b, v.name);
			xb_cv_sym_end(b, at);
		};
		xbCvScopes sc = xb_cv_scopes(pd, len);
		// a lexical block per scope that has variables, nested like the scopes
		auto emit_scope = [&](auto &self, i32 s) -> void {
			for (xbDebugVar const &v : pd.vars) {
				if (sc.eff[v.scope] == s) emit_var(v);
			}
			for (i32 c : sc.kids[s]) {
				isize at = xb_cv_sym_begin(b, XCV_S_BLOCK32);
				xbb_u32(b, 0); // parent, end: lld-link fills them in
				xbb_u32(b, 0);
				xbb_u32(b, cast(u32)(sc.hi[c] - sc.lo[c]));
				xb_cv_addr(w, b, -1, pd.start + sc.lo[c]);
				xb_cv_name(b, str_lit(""));
				xb_cv_sym_end(b, at);
				self(self, c);
				at = xb_cv_sym_begin(b, XCV_S_END);
				xb_cv_sym_end(b, at);
			}
		};
		emit_scope(emit_scope, 0);
		xb_cv_scopes_free(&sc);
		at = xb_cv_sym_begin(b, XCV_S_END);
		xb_cv_sym_end(b, at);
		xb_cv_subsection_end(b, ss);

		// lines, one block per run of the same file
		ss = xb_cv_subsection_begin(b, XCV_DEBUG_S_LINES);
		xb_cv_addr(w, b, -1, pd.start);
		xbb_u16(b, 1); // CV_LINES_HAVE_COLUMNS
		xbb_u32(b, len);
		struct Line { u32 offset; i32 line; i32 column; };
		auto lines = array_make<Line>(heap_allocator(), 0, pd.line_entry_count + 1);
		i32 file = gb_max(pd.file_id, 1);
		auto flush = [&]() {
			if (lines.count == 0) return;
			xbb_u32(b, cast(u32)(8*(file-1))); // the file's entry in the checksums
			xbb_u32(b, cast(u32)lines.count);
			xbb_u32(b, cast(u32)(12 + 12*lines.count));
			// not marked as statements, like LLVM
			for (Line const &l : lines) {
				xbb_u32(b, l.offset);
				xbb_u32(b, cast(u32)gb_max(l.line, 0) & 0xffffff);
			}
			for (Line const &l : lines) {
				xbb_u16(b, cast(u16)gb_clamp(l.column, 0, 0xffff));
				xbb_u16(b, 0);
			}
			lines.count = 0;
		};
		auto add_line = [&](i32 f, u32 offset, i32 line, i32 column) {
			if (f != file) {
				flush();
				file = f;
			}
			if (lines.count > 0 && lines[lines.count-1].offset == offset) {
				lines[lines.count-1].line = line;
				lines[lines.count-1].column = column;
				return;
			}
			Line l = {offset, line, column};
			array_add(&lines, l);
		};
		if (pd.line > 0 && (pd.line_entry_count == 0 || m->lines[pd.line_entry_start].code_offset != 0)) {
			// the prologue gets the declaration's line, debuggers look up the entry address
			add_line(gb_max(pd.file_id, 1), 0, pd.line, 0);
			if (pd.prologue_end > 0) add_line(gb_max(pd.file_id, 1), cast(u32)pd.prologue_end, pd.line, 0);
		}
		for (i32 i = 0; i < pd.line_entry_count; i++) {
			xbLineEntry const &e = m->lines[pd.line_entry_start + i];
			add_line(e.file_id, cast(u32)e.code_offset, e.line, e.column);
		}
		flush();
		array_free(&lines);
		xb_cv_subsection_end(b, ss);
	}

	// globals and constants
	if (m->global_debug.count > 0) {
		isize ss = xb_cv_subsection_begin(b, XCV_DEBUG_S_SYMBOLS);
		for (xbGlobalDebug const &g : m->global_debug) {
			if (g.sym < 0) {
				isize at = xb_cv_sym_begin(b, XCV_S_CONSTANT);
				xbb_u32(b, type_of(g.type, false));
				xb_cv_numeric(b, g.value);
				xb_cv_name(b, g.name);
				xb_cv_sym_end(b, at);
				continue;
			}
			bool tls = (m->symbols[g.sym].flags & xbSymbolFlag_TLS) != 0;
			isize at = xb_cv_sym_begin(b, tls ? XCV_S_GTHREAD32 : XCV_S_GDATA32);
			xbb_u32(b, type_of(g.type, false));
			xb_cv_addr(w, b, g.sym, 0);
			xb_cv_name(b, g.name);
			xb_cv_sym_end(b, at);
		}
		xb_cv_subsection_end(b, ss);
	}

	// file names and their (absent) checksums
	{
		auto strings = array_make<u8>(heap_allocator(), 0, 4096);
		xbb_u8(&strings, 0);
		isize ss = xb_cv_subsection_begin(b, XCV_DEBUG_S_FILECHKSMS);
		for (String const &f : m->files) {
			xbb_u32(b, cast(u32)strings.count);
			xbb_u8(b, 0); // checksum size
			xbb_u8(b, 0); // no checksum
			xbb_u16(b, 0);
			// debuggers match `file:line` against native paths, like LLVM writes them
			String native = copy_string(heap_allocator(), f);
			for (isize i = 0; i < native.len; i++) {
				if (native[i] == '/') native.text[i] = '\\';
			}
			xb_cv_name(&strings, native);
			gb_free(heap_allocator(), native.text);
		}
		xb_cv_subsection_end(b, ss);
		ss = xb_cv_subsection_begin(b, XCV_DEBUG_S_STRINGTABLE);
		xbb_bytes(b, strings.data, strings.count);
		xb_cv_subsection_end(b, ss);
		array_free(&strings);
	}

	// the definitions of the forward referenced types, which may forward reference more
	for (isize i = 0; i < cv->to_define.count; i++) {
		xb_cv_define(cv, cv->to_define[i]);
	}
	map_destroy(&cv->types);
	map_destroy(&cv->refs);
	array_free(&cv->to_define);
	array_free(&cv->to_define_index);
}
