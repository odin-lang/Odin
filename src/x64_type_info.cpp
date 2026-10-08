gb_internal void xb_stat_fail(xbModule *m, char const *reason);
// The type info table: a port of lb_setup_type_info_data. Every entry is laid out byte by
// byte from the runtime's own Type_Info types, so the layout follows the runtime.

gb_internal i32 xb_equal_proc_sym(xbProc *caller, Type *type);
gb_internal i32 xb_map_info_sym(xbProc *caller, Type *map_type);

struct xbTypeInfoGen {
	xbModule *  m;
	xbProc *    caller; // for the equal procedures and map infos, which may bail
	i32 *       entry_syms;
	isize       count;
	bool        failed;
	char const *reason;
};

// writes into a local buffer, placed into .data once complete
struct xbBlob {
	xbConstBuf b;
};

gb_internal xbBlob xb_blob_make(xbModule *m, i64 size) {
	xbBlob blob = {};
	blob.b.m = m;
	blob.b.writable = false;
	blob.b.bytes = array_make<u8>(heap_allocator(), size, size);
	gb_zero_size(blob.b.bytes.data, size);
	blob.b.relocs = array_make<xbReloc>(heap_allocator(), 0, 4);
	return blob;
}

gb_internal void xb_blob_value(xbTypeInfoGen *g, xbBlob *blob, Type *type, ExactValue value, i64 off) {
	if (!xb_cb_write(&blob->b, type, value, off)) {
		g->failed = true;
		g->reason = blob->b.fail;
	}
}

gb_internal void xb_blob_int(xbBlob *blob, i64 off, i64 size, u64 v) {
	xb_cb_int(&blob->b, off, size, v, false);
}

gb_internal void xb_blob_ptr(xbBlob *blob, i64 off, i32 sym) {
	if (sym >= 0) xb_cb_reloc(&blob->b, off, sym, 0);
}

gb_internal void xb_blob_string(xbTypeInfoGen *g, xbBlob *blob, i64 off, String s) {
	if (s.len == 0) return;
	xb_blob_value(g, blob, t_string, exact_value_string(s), off);
}

// places the blob at `sym`, or a new local symbol when sym is -1
gb_internal i32 xb_blob_finish(xbModule *m, xbBlob *blob, i64 align, i32 sym=-1) {
	xbSection sec = blob->b.relocs.count > 0 ? xbSection_Data : xbSection_Rodata;
	i64 size = blob->b.bytes.count;
	i64 at = xb_section_reserve(m, sec, size, gb_max(align, cast(i64)1));
	gb_memmove(m->sections[sec].data + at, blob->b.bytes.data, size);
	for (xbReloc r : blob->b.relocs) {
		r.section = sec;
		r.offset += at;
		array_add(&m->relocs, r);
	}
	array_free(&blob->b.bytes);
	array_free(&blob->b.relocs);
	if (sym < 0) {
		char name[64] = {};
		gb_snprintf(name, gb_size_of(name), ".Lxb.blob.%d.%lld", cast(int)sec, cast(long long)at);
		sym = xb_symbol(m, make_string_c(name));
		m->symbols[sym].flags = 0;
	}
	xbSymbol *s = &m->symbols[sym];
	s->section = sec;
	s->offset = at;
	s->size = size;
	return sym;
}

gb_internal i32 xb_ti_ptr(xbTypeInfoGen *g, Type *type) {
	type = default_type(type);
	isize index = lb_type_info_index(g->m->info, type);
	GB_ASSERT(index >= 0 && index < g->count);
	return g->entry_syms[index];
}

// an array of `count` elements of `elem`, filled by the callback, -1 when empty
template <typename F>
gb_internal i32 xb_ti_array(xbTypeInfoGen *g, Type *elem, isize count, F const &fill) {
	if (count == 0) return -1;
	i64 stride = type_size_of(elem);
	xbBlob blob = xb_blob_make(g->m, stride*count);
	for (isize i = 0; i < count; i++) {
		fill(&blob, i*stride, i);
	}
	return xb_blob_finish(g->m, &blob, type_align_of(elem));
}

gb_internal i32 xb_ti_source_location(xbTypeInfoGen *g, String procedure, TokenPos pos) {
	String file = get_file_path_string(pos.file_id);
	i32 line = pos.line;
	i32 column = pos.column;
	switch (build_context.source_code_location_info) {
	case SourceCodeLocationInfo_Normal:
		break;
	case SourceCodeLocationInfo_Obfuscated:
		file = obfuscate_string(file, "F");
		procedure = obfuscate_string(procedure, "P");
		line = obfuscate_i32(line);
		column = obfuscate_i32(column);
		break;
	case SourceCodeLocationInfo_Filename:
		file = last_path_element(file);
		break;
	case SourceCodeLocationInfo_None:
		file = str_lit("");
		procedure = str_lit("");
		line = 0;
		column = 0;
		break;
	}
	Type *bt = base_type(t_source_code_location);
	xbBlob blob = xb_blob_make(g->m, type_size_of(bt));
	xb_blob_string(g, &blob, type_offset_of(bt, 0), file);
	xb_blob_int(&blob, type_offset_of(bt, 1), 4, cast(u32)line);
	xb_blob_int(&blob, type_offset_of(bt, 2), 4, cast(u32)column);
	xb_blob_string(g, &blob, type_offset_of(bt, 3), procedure);
	return xb_blob_finish(g->m, &blob, type_align_of(bt));
}

gb_internal i32 xb_ti_equal_proc(xbTypeInfoGen *g, Type *t) {
	if (!is_type_comparable(t) || is_type_simple_compare(t)) return -1;
	return xb_equal_proc_sym(g->caller, t);
}

// Writes the variant of entry `t` at `v`, the offset of the variant in the entry; returns the tag type.
gb_internal Type *xb_ti_variant(xbTypeInfoGen *g, xbBlob *blob, i64 v, Type *t) {
	auto field = [&](Type *tag_type, isize index) -> i64 {
		return v + type_offset_of(base_type(tag_type), index);
	};
	auto set_bool = [&](i64 off, bool b) { xb_blob_int(blob, off, 1, b ? 1 : 0); };
	auto set_int = [&](i64 off, i64 size, i64 x) { xb_blob_int(blob, off, size, cast(u64)x); };

	switch (t->kind) {
	case Type_Named: {
		Type *tt = t_type_info_named;
		Entity *tn = t->Named.type_name;
		xb_blob_string(g, blob, field(tt, 0), tn->token.string);
		xb_blob_ptr(blob, field(tt, 1), xb_ti_ptr(g, t->Named.base));
		if (tn->pkg) xb_blob_string(g, blob, field(tt, 2), tn->pkg->name);
		String proc_name = {};
		if (DeclInfo *pd = tn->parent_proc_decl) {
			Entity *e = pd->entity.load();
			if (e && e->kind == Entity_Procedure) proc_name = e->token.string;
		}
		xb_blob_ptr(blob, field(tt, 3), xb_ti_source_location(g, proc_name, tn->token.pos));
		return tt;
	}
	case Type_Basic:
		switch (t->Basic.kind) {
		case Basic_bool: case Basic_b8: case Basic_b16: case Basic_b32: case Basic_b64:
			return t_type_info_boolean;
		case Basic_i8: case Basic_u8: case Basic_i16: case Basic_u16: case Basic_i32: case Basic_u32:
		case Basic_i64: case Basic_u64: case Basic_i128: case Basic_u128:
		case Basic_i16le: case Basic_u16le: case Basic_i32le: case Basic_u32le: case Basic_i64le: case Basic_u64le:
		case Basic_i128le: case Basic_u128le:
		case Basic_i16be: case Basic_u16be: case Basic_i32be: case Basic_u32be: case Basic_i64be: case Basic_u64be:
		case Basic_i128be: case Basic_u128be:
		case Basic_int: case Basic_uint: case Basic_uintptr: {
			Type *tt = t_type_info_integer;
			set_bool(field(tt, 0), (t->Basic.flags & BasicFlag_Unsigned) == 0);
			u8 endian = (t->Basic.flags & BasicFlag_EndianLittle) ? 1 : (t->Basic.flags & BasicFlag_EndianBig) ? 2 : 0;
			set_int(field(tt, 1), 1, endian);
			return tt;
		}
		case Basic_rune:
			return t_type_info_rune;
		case Basic_f16: case Basic_f32: case Basic_f64:
		case Basic_f16le: case Basic_f32le: case Basic_f64le:
		case Basic_f16be: case Basic_f32be: case Basic_f64be: {
			Type *tt = t_type_info_float;
			u8 endian = (t->Basic.flags & BasicFlag_EndianLittle) ? 1 : (t->Basic.flags & BasicFlag_EndianBig) ? 2 : 0;
			set_int(field(tt, 0), 1, endian);
			return tt;
		}
		case Basic_complex32: case Basic_complex64: case Basic_complex128:
			return t_type_info_complex;
		case Basic_quaternion64: case Basic_quaternion128: case Basic_quaternion256:
			return t_type_info_quaternion;
		case Basic_rawptr:
			return t_type_info_pointer;
		case Basic_string: case Basic_cstring: case Basic_string16: case Basic_cstring16: {
			Type *tt = t_type_info_string;
			bool is_cstring = t->Basic.kind == Basic_cstring || t->Basic.kind == Basic_cstring16;
			bool is_16 = t->Basic.kind == Basic_string16 || t->Basic.kind == Basic_cstring16;
			set_bool(field(tt, 0), is_cstring);
			set_int(field(tt, 1), type_size_of(t_type_info_string_encoding_kind), is_16 ? 1 : 0);
			return tt;
		}
		case Basic_any:
			return t_type_info_any;
		case Basic_typeid:
			return t_type_info_typeid;
		}
		return nullptr;

	case Type_Pointer:
		xb_blob_ptr(blob, field(t_type_info_pointer, 0), xb_ti_ptr(g, t->Pointer.elem));
		return t_type_info_pointer;
	case Type_MultiPointer:
		xb_blob_ptr(blob, field(t_type_info_multi_pointer, 0), xb_ti_ptr(g, t->MultiPointer.elem));
		return t_type_info_multi_pointer;
	case Type_SoaPointer:
		xb_blob_ptr(blob, field(t_type_info_soa_pointer, 0), xb_ti_ptr(g, t->SoaPointer.elem));
		return t_type_info_soa_pointer;
	case Type_Array: {
		Type *tt = t_type_info_array;
		xb_blob_ptr(blob, field(tt, 0), xb_ti_ptr(g, t->Array.elem));
		set_int(field(tt, 1), 8, type_size_of(t->Array.elem));
		set_int(field(tt, 2), 8, t->Array.count);
		return tt;
	}
	case Type_EnumeratedArray: {
		Type *tt = t_type_info_enumerated_array;
		xb_blob_ptr(blob, field(tt, 0), xb_ti_ptr(g, t->EnumeratedArray.elem));
		xb_blob_ptr(blob, field(tt, 1), xb_ti_ptr(g, t->EnumeratedArray.index));
		set_int(field(tt, 2), 8, type_size_of(t->EnumeratedArray.elem));
		set_int(field(tt, 3), 8, t->EnumeratedArray.count);
		xb_blob_value(g, blob, t_type_info_enum_value, *t->EnumeratedArray.min_value, field(tt, 4));
		xb_blob_value(g, blob, t_type_info_enum_value, *t->EnumeratedArray.max_value, field(tt, 5));
		set_bool(field(tt, 6), t->EnumeratedArray.is_sparse);
		return tt;
	}
	case Type_DynamicArray: {
		Type *tt = t_type_info_dynamic_array;
		xb_blob_ptr(blob, field(tt, 0), xb_ti_ptr(g, t->DynamicArray.elem));
		set_int(field(tt, 1), 8, type_size_of(t->DynamicArray.elem));
		return tt;
	}
	case Type_FixedCapacityDynamicArray: {
		Type *tt = t_type_info_fixed_capacity_dynamic_array;
		xb_blob_ptr(blob, field(tt, 0), xb_ti_ptr(g, t->FixedCapacityDynamicArray.elem));
		set_int(field(tt, 1), 8, type_size_of(t->FixedCapacityDynamicArray.elem));
		set_int(field(tt, 2), 8, t->FixedCapacityDynamicArray.capacity);
		set_int(field(tt, 3), 8, type_offset_of(t, 1));
		return tt;
	}
	case Type_Slice: {
		Type *tt = t_type_info_slice;
		xb_blob_ptr(blob, field(tt, 0), xb_ti_ptr(g, t->Slice.elem));
		set_int(field(tt, 1), 8, type_size_of(t->Slice.elem));
		return tt;
	}
	case Type_Proc: {
		Type *tt = t_type_info_procedure;
		if (t->Proc.params)  xb_blob_ptr(blob, field(tt, 0), xb_ti_ptr(g, t->Proc.params));
		if (t->Proc.results) xb_blob_ptr(blob, field(tt, 1), xb_ti_ptr(g, t->Proc.results));
		set_bool(field(tt, 2), t->Proc.variadic);
		set_int(field(tt, 3), 1, t->Proc.calling_convention);
		return tt;
	}
	case Type_Tuple: {
		Type *tt = t_type_info_parameters;
		isize count = t->Tuple.variables.count;
		i32 types = xb_ti_array(g, t_type_info_ptr, count, [&](xbBlob *b, i64 off, isize i) {
			xb_blob_ptr(b, off, xb_ti_ptr(g, t->Tuple.variables[i]->type));
		});
		i32 names = xb_ti_array(g, t_string, count, [&](xbBlob *b, i64 off, isize i) {
			xb_blob_string(g, b, off, t->Tuple.variables[i]->token.string);
		});
		// two slices
		xb_blob_ptr(blob, field(tt, 0), types);
		set_int(field(tt, 0) + 8, 8, count);
		xb_blob_ptr(blob, field(tt, 1), names);
		set_int(field(tt, 1) + 8, 8, count);
		return tt;
	}
	case Type_Enum: {
		Type *tt = t_type_info_enum;
		GB_ASSERT(t->Enum.base_type != nullptr);
		xb_blob_ptr(blob, field(tt, 0), xb_ti_ptr(g, t->Enum.base_type));
		isize count = t->Enum.fields.count;
		if (count > 0) {
			auto fields = t->Enum.fields;
			i32 names = xb_ti_array(g, t_string, count, [&](xbBlob *b, i64 off, isize i) {
				xb_blob_string(g, b, off, fields[i]->token.string);
			});
			i32 values = xb_ti_array(g, t_type_info_enum_value, count, [&](xbBlob *b, i64 off, isize i) {
				xb_blob_value(g, b, t_i64, fields[i]->Constant.value, off);
			});
			xb_blob_ptr(blob, field(tt, 1), names);
			set_int(field(tt, 1) + 8, 8, count);
			xb_blob_ptr(blob, field(tt, 2), values);
			set_int(field(tt, 2) + 8, 8, count);
		}
		return tt;
	}
	case Type_Union: {
		Type *tt = t_type_info_union;
		isize count = t->Union.variants.count;
		i32 types = xb_ti_array(g, t_type_info_ptr, count, [&](xbBlob *b, i64 off, isize i) {
			xb_blob_ptr(b, off, xb_ti_ptr(g, t->Union.variants[i]));
		});
		xb_blob_ptr(blob, field(tt, 0), types);
		set_int(field(tt, 0) + 8, 8, count);
		i64 tag_size = union_tag_size(t);
		if (tag_size > 0) {
			set_int(field(tt, 1), 8, align_formula(t->Union.variant_block_size, tag_size));
			xb_blob_ptr(blob, field(tt, 2), xb_ti_ptr(g, union_tag_type(t)));
		}
		xb_blob_ptr(blob, field(tt, 3), xb_ti_equal_proc(g, t));
		set_bool(field(tt, 4), t->Union.custom_align != 0);
		set_bool(field(tt, 5), t->Union.kind == UnionType_no_nil);
		set_bool(field(tt, 6), t->Union.kind == UnionType_shared_nil);
		return tt;
	}
	case Type_Struct: {
		Type *tt = t_type_info_struct;
		u8 flags = 0;
		if (t->Struct.is_packed)      flags |= 1<<0;
		if (t->Struct.is_raw_union)   flags |= 1<<1;
		if (t->Struct.is_all_or_none) flags |= 1<<2;
		if (t->Struct.custom_align)   flags |= 1<<3;
		set_int(field(tt, 6), 1, flags);
		xb_blob_ptr(blob, field(tt, 10), xb_ti_equal_proc(g, t));
		if (t->Struct.soa_kind != StructSoa_None) {
			set_int(field(tt, 7), type_size_of(get_struct_field_type(tt, 7)), t->Struct.soa_kind);
			set_int(field(tt, 8), 4, t->Struct.soa_count);
			xb_blob_ptr(blob, field(tt, 9), xb_ti_ptr(g, t->Struct.soa_elem));
		}
		isize count = t->Struct.fields.count;
		if (count > 0) {
			type_set_offsets(t);
			auto fields = t->Struct.fields;
			i32 types = xb_ti_array(g, t_type_info_ptr, count, [&](xbBlob *b, i64 off, isize i) {
				xb_blob_ptr(b, off, xb_ti_ptr(g, fields[i]->type));
			});
			i32 names = xb_ti_array(g, t_string, count, [&](xbBlob *b, i64 off, isize i) {
				xb_blob_string(g, b, off, fields[i]->token.string);
			});
			i32 offsets = xb_ti_array(g, t_uintptr, count, [&](xbBlob *b, i64 off, isize i) {
				xb_blob_int(b, off, 8, t->Struct.is_raw_union ? 0 : cast(u64)t->Struct.offsets[i]);
			});
			i32 usings = xb_ti_array(g, t_bool, count, [&](xbBlob *b, i64 off, isize i) {
				xb_blob_int(b, off, 1, (fields[i]->flags & EntityFlag_Using) ? 1 : 0);
			});
			i32 tags = xb_ti_array(g, t_string, count, [&](xbBlob *b, i64 off, isize i) {
				if (t->Struct.tags != nullptr) xb_blob_string(g, b, off, t->Struct.tags[i]);
			});
			xb_blob_ptr(blob, field(tt, 0), types);
			xb_blob_ptr(blob, field(tt, 1), names);
			xb_blob_ptr(blob, field(tt, 2), offsets);
			xb_blob_ptr(blob, field(tt, 3), usings);
			xb_blob_ptr(blob, field(tt, 4), tags);
			set_int(field(tt, 5), 4, count);
		}
		return tt;
	}
	case Type_Map: {
		Type *tt = t_type_info_map;
		init_map_internal_debug_types(t);
		xb_blob_ptr(blob, field(tt, 0), xb_ti_ptr(g, t->Map.key));
		xb_blob_ptr(blob, field(tt, 1), xb_ti_ptr(g, t->Map.value));
		xb_blob_ptr(blob, field(tt, 2), xb_map_info_sym(g->caller, t));
		return tt;
	}
	case Type_BitSet: {
		Type *tt = t_type_info_bit_set;
		xb_blob_ptr(blob, field(tt, 0), xb_ti_ptr(g, t->BitSet.elem));
		Type *underlying = t->BitSet.underlying ? t->BitSet.underlying : bit_set_to_int(t);
		xb_blob_ptr(blob, field(tt, 1), xb_ti_ptr(g, underlying));
		set_bool(field(tt, 2), t->BitSet.underlying != nullptr);
		set_int(field(tt, 3), 8, t->BitSet.lower);
		set_int(field(tt, 4), 8, t->BitSet.upper);
		return tt;
	}
	case Type_SimdVector: {
		Type *tt = t_type_info_simd_vector;
		xb_blob_ptr(blob, field(tt, 0), xb_ti_ptr(g, t->SimdVector.elem));
		set_int(field(tt, 1), 8, type_size_of(t->SimdVector.elem));
		set_int(field(tt, 2), 8, t->SimdVector.count);
		return tt;
	}
	case Type_Matrix: {
		Type *tt = t_type_info_matrix;
		xb_blob_ptr(blob, field(tt, 0), xb_ti_ptr(g, t->Matrix.elem));
		set_int(field(tt, 1), 8, type_size_of(t->Matrix.elem));
		set_int(field(tt, 2), 8, matrix_type_stride_in_elems(t));
		set_int(field(tt, 3), 8, t->Matrix.row_count);
		set_int(field(tt, 4), 8, t->Matrix.column_count);
		set_int(field(tt, 5), 1, t->Matrix.is_row_major ? 1 : 0);
		return tt;
	}
	case Type_BitField: {
		Type *tt = t_type_info_bit_field;
		xb_blob_ptr(blob, field(tt, 0), xb_ti_ptr(g, t->BitField.backing_type));
		isize count = t->BitField.fields.count;
		if (count > 0) {
			auto fields = t->BitField.fields;
			i32 names = xb_ti_array(g, t_string, count, [&](xbBlob *b, i64 off, isize i) {
				xb_blob_string(g, b, off, fields[i]->token.string);
			});
			i32 types = xb_ti_array(g, t_type_info_ptr, count, [&](xbBlob *b, i64 off, isize i) {
				xb_blob_ptr(b, off, xb_ti_ptr(g, fields[i]->type));
			});
			i32 bit_sizes = xb_ti_array(g, t_uintptr, count, [&](xbBlob *b, i64 off, isize i) {
				xb_blob_int(b, off, 8, cast(u64)t->BitField.bit_sizes[i]);
			});
			i32 bit_offsets = xb_ti_array(g, t_uintptr, count, [&](xbBlob *b, i64 off, isize i) {
				u64 bit_offset = 0;
				for (isize j = 0; j < i; j++) bit_offset += cast(u64)t->BitField.bit_sizes[j];
				xb_blob_int(b, off, 8, bit_offset);
			});
			i32 tags = xb_ti_array(g, t_string, count, [&](xbBlob *b, i64 off, isize i) {
				if (t->BitField.tags) xb_blob_string(g, b, off, t->BitField.tags[i]);
			});
			xb_blob_ptr(blob, field(tt, 1), names);
			xb_blob_ptr(blob, field(tt, 2), types);
			xb_blob_ptr(blob, field(tt, 3), bit_sizes);
			xb_blob_ptr(blob, field(tt, 4), bit_offsets);
			xb_blob_ptr(blob, field(tt, 5), tags);
			set_int(field(tt, 6), 8, count);
		}
		return tt;
	}
	}
	return nullptr;
}

gb_internal bool xb_generate_type_info(xbModule *m, char const **reason) {
	CheckerInfo *info = m->info;
	xbTypeInfoGen g = {};
	g.m = m;
	g.count = info->type_info_types_hash_map.count;
	g.entry_syms = gb_alloc_array(heap_allocator(), i32, g.count);
	defer (gb_free(heap_allocator(), g.entry_syms));
	for (isize i = 0; i < g.count; i++) {
		char name[64] = {};
		gb_snprintf(name, gb_size_of(name), ".Lxb.ti.%lld", cast(long long)i);
		g.entry_syms[i] = xb_symbol(m, make_string_c(name));
		m->symbols[g.entry_syms[i]].flags = 0;
	}

	// on failure, entries already written may point at ones that never were
	auto place_missing = [&]() {
		for (isize i = 0; i < g.count; i++) {
			if (m->symbols[g.entry_syms[i]].section == xbSection_Undef) {
				xbBlob blob = xb_blob_make(m, 8);
				xb_blob_finish(m, &blob, 8, g.entry_syms[i]);
			}
		}
	};

	// the equal procedures and map infos need a procedure to fail in
	xbProc *caller = xb_new_proc(m, str_lit("__$type_info"), t_equal_proc);
	jmp_buf bail;
	caller->bail = &bail;
	if (setjmp(bail) != 0) {
		*reason = caller->fail_reason;
		place_missing();
		return false;
	}
	g.caller = caller;

	Type *tibt = base_type(t_type_info);
	GB_ASSERT(tibt->kind == Type_Struct && tibt->Struct.fields.count == 5);
	Type *ut = base_type(tibt->Struct.fields[4]->type);
	GB_ASSERT(ut->kind == Type_Union);
	i64 entry_size = type_size_of(tibt);
	i64 entry_align = type_align_of(tibt);
	i64 variant_offset = type_offset_of(tibt, 4);
	i64 tag_offset = variant_offset + ut->Union.variant_block_size;
	i64 tag_size = union_tag_size(ut);

	auto handled = slice_make<bool>(heap_allocator(), g.count);
	defer (gb_free(heap_allocator(), handled.data));

	// entry 0 stays zero
	{
		xbBlob blob = xb_blob_make(m, entry_size);
		xb_blob_finish(m, &blob, entry_align, g.entry_syms[0]);
		handled[0] = true;
	}
	for (auto const &tt : info->type_info_types_hash_map) {
		Type *t = tt.type;
		if (t == nullptr || t == t_invalid) continue;
		isize index = lb_type_info_index(info, tt, false);
		if (index <= 0 || handled[index]) continue;
		handled[index] = true;

		xbBlob blob = xb_blob_make(m, entry_size);
		xb_blob_int(&blob, type_offset_of(tibt, 0), 8, cast(u64)type_size_of(t));
		xb_blob_int(&blob, type_offset_of(tibt, 1), 8, cast(u64)type_align_of(t));
		xb_blob_int(&blob, type_offset_of(tibt, 2), type_size_of(tibt->Struct.fields[2]->type), type_info_flags_of_type(t));
		xb_blob_int(&blob, type_offset_of(tibt, 3), 8, type_hash_canonical_type(default_type(t)));
		Type *tag_type = xb_ti_variant(&g, &blob, variant_offset, t);
		if (g.failed) {
			*reason = g.reason ? g.reason : "type info";
			array_free(&blob.b.bytes);
			array_free(&blob.b.relocs);
			place_missing();
			return false;
		}
		if (tag_type != nullptr) {
			xb_blob_int(&blob, tag_offset, tag_size, cast(u64)union_variant_index_checked(ut, tag_type));
		}
		xb_blob_finish(m, &blob, entry_align, g.entry_syms[index]);
	}

	// __$type_info_data: a pointer to each entry
	{
		xbBlob blob = xb_blob_make(m, 8*g.count);
		for (isize i = 0; i < g.count; i++) {
			if (m->symbols[g.entry_syms[i]].section != xbSection_Undef) {
				xb_blob_ptr(&blob, 8*i, g.entry_syms[i]);
			}
		}
		i32 sym = xb_symbol(m, str_lit(LB_TYPE_INFO_DATA_NAME));
		xb_blob_finish(m, &blob, 8, sym);
		m->symbols[sym].flags = xbSymbolFlag_Global | xbSymbolFlag_Hidden;

		// runtime.type_table, a slice of it
		Entity *type_table = scope_lookup_current(info->runtime_package->scope, string_interner_insert(str_lit("type_table")));
		xbBlob tb = xb_blob_make(m, 16);
		xb_blob_ptr(&tb, 0, sym);
		xb_blob_int(&tb, 8, 8, cast(u64)g.count);
		i32 tsym = xb_symbol(m, xb_entity_name(m, type_table));
		xb_blob_finish(m, &tb, 8, tsym);
		m->symbols[tsym].flags = xbSymbolFlag_Global | xbSymbolFlag_Weak;
		ptr_set_add(&m->handled, type_table);
	}
	return true;
}

gb_internal void xb_build_type_info(xbModule *m) {
	if (build_context.no_rtti) return;
	char const *reason = nullptr;
	if (xb_generate_type_info(m, &reason)) {
		m->owns_type_info = true;
	} else {
		xb_stat_fail(m, reason ? reason : "type info");
		if (m->verbose) gb_printf_err("xb: type info left to LLVM: %s\n", reason);
	}
	xb_arena_reset();
}
