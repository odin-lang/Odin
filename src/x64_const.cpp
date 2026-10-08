// Constant data: Odin constants laid out as bytes with relocations, for global
// variables, static variables and large constant literals.

struct xbConstBuf {
	xbModule *     m;
	Array<u8>      bytes;
	Array<xbReloc> relocs; // offsets are relative to the start of `bytes`
	bool           writable;
	char const *   fail;
};

gb_internal i32 xb_const_global(xbModule *m, Type *type, ExactValue value, bool writable, char const **reason);

gb_internal void xb_cb_reloc(xbConstBuf *b, i64 off, i32 sym, i64 addend) {
	xbReloc r = {};
	r.kind = xbReloc_Abs64;
	r.offset = off;
	r.sym = sym;
	r.addend = addend;
	array_add(&b->relocs, r);
}

gb_internal void xb_cb_bytes(xbConstBuf *b, i64 off, void const *data, isize n) {
	gb_memmove(b->bytes.data + off, data, n);
}

gb_internal void xb_cb_int(xbConstBuf *b, i64 off, i64 size, u64 v, bool swap) {
	u8 tmp[8] = {};
	for (i64 i = 0; i < size && i < 8; i++) {
		tmp[i] = cast(u8)(v >> (8*i));
	}
	if (swap) {
		for (i64 i = 0; i < size/2; i++) {
			u8 t = tmp[i]; tmp[i] = tmp[size-1-i]; tmp[size-1-i] = t;
		}
	}
	xb_cb_bytes(b, off, tmp, gb_min(size, cast(i64)8));
}

gb_internal void xb_cb_big_int(xbConstBuf *b, i64 off, i64 size, BigInt const *a, bool swap) {
	// two's complement little endian bytes of any width
	u8 tmp[16] = {};
	BigInt v = {};
	big_int_init(&v, a);
	bool neg = big_int_is_neg(&v);
	if (neg) {
		BigInt mag = {};
		big_int_neg(&mag, &v);
		v = mag;
	}
	BigInt mask = {};
	big_int_from_u64(&mask, ~cast(u64)0);
	BigInt shift = {};
	big_int_from_u64(&shift, 64);
	u64 words[2] = {};
	for (int w = 0; w < 2; w++) {
		BigInt lo = {};
		big_int_and(&lo, &v, &mask);
		words[w] = big_int_to_u64(&lo);
		BigInt next = {};
		big_int_shr(&next, &v, &shift);
		v = next;
	}
	if (neg) {
		words[0] = ~words[0];
		words[1] = ~words[1];
		words[0] += 1;
		if (words[0] == 0) words[1] += 1;
	}
	gb_memmove(tmp, words, 16);
	if (swap) {
		for (i64 i = 0; i < size/2; i++) {
			u8 t = tmp[i]; tmp[i] = tmp[size-1-i]; tmp[size-1-i] = t;
		}
	}
	xb_cb_bytes(b, off, tmp, gb_min(size, cast(i64)16));
}

gb_internal bool xb_cb_write(xbConstBuf *b, Type *type, ExactValue value, i64 off);

gb_internal bool xb_cb_fail(xbConstBuf *b, char const *reason) {
	if (b->fail == nullptr) b->fail = reason;
	return false;
}

// The elements of an array-like compound literal, by index, with ranges expanded.
gb_internal bool xb_cb_array_elems(xbConstBuf *b, Ast *compound, Type *elem_type, i64 count, i64 min_index, i64 stride, i64 off) {
	ast_node(cl, CompoundLit, compound);
	if (cl->elems.count == 0) return true;
	if (cl->elems[0]->kind == Ast_FieldValue) {
		for (Ast *elem : cl->elems) {
			ast_node(fv, FieldValue, elem);
			if (is_ast_range(fv->field)) {
				ast_node(ie, BinaryExpr, fv->field);
				i64 lo = exact_value_to_i64(ie->left->tav.value) - min_index;
				i64 hi = exact_value_to_i64(ie->right->tav.value) - min_index;
				if (ie->op.kind != Token_RangeHalf) hi += 1;
				for (i64 k = lo; k < hi; k++) {
					if (!xb_cb_write(b, elem_type, fv->value->tav.value, off + k*stride)) return false;
				}
			} else {
				i64 index = exact_value_to_i64(fv->field->tav.value) - min_index;
				if (!xb_cb_write(b, elem_type, fv->value->tav.value, off + index*stride)) return false;
			}
		}
		return true;
	}
	i64 index = 0;
	for (Ast *elem : cl->elems) {
		TypeAndValue tav = elem->tav;
		if (is_type_tuple(tav.type)) {
			return xb_cb_fail(b, "tuple in constant array");
		}
		if (index >= count) break;
		if (!xb_cb_write(b, elem_type, tav.value, off + index*stride)) return false;
		index++;
	}
	return true;
}

gb_internal bool xb_cb_write(xbConstBuf *b, Type *type, ExactValue value, i64 off) {
	xbModule *m = b->m;
	type = default_type(type);
	Type *original_type = type;
	while (value.kind == ExactValue_Variant &&
	       (value.variant_type == nullptr || are_types_identical(value.variant_type, original_type))) {
		value = value.value_variant->tav.value;
	}
	if (!is_type_bit_field(original_type)) {
		type = core_type(type);
		value = convert_exact_value_for_type(value, type);
	}

	if (is_type_union(type) && (is_type_union_constantable(type) ||
	    (value.variant_type != nullptr && elem_type_can_be_constant(value.variant_type)))) {
		Type *bt = base_type(type);
		if (bt->Union.variants.count == 0) return true;
		Type *value_type = value.variant_type;
		switch (value.kind) {
		case ExactValue_Invalid:
			if (value_type == nullptr || are_types_identical(value_type, original_type)) return true;
			break;
		case ExactValue_Compound: {
			ast_node(cl, CompoundLit, value.value_compound);
			if (value_type == nullptr || are_types_identical(value_type, original_type)) {
				return true;
			}
			break;
		}
		case ExactValue_Variant:
			value = value.value_variant->tav.value;
			break;
		}
		if (value_type == nullptr || value_type == t_untyped_nil) return true;
		if (bt->Union.variants.count == 1) {
			Type *t = bt->Union.variants[0];
			if (!xb_cb_write(b, t, value, off)) return false;
			if (!is_type_union_maybe_pointer(type)) {
				Type *tag_type = union_tag_type(bt);
				i64 tag_value = bt->Union.kind == UnionType_no_nil ? 0 : 1;
				xb_cb_int(b, off + bt->Union.variant_block_size, type_size_of(tag_type), cast(u64)tag_value, false);
			}
			return true;
		}
		type_size_of(bt);
		if (!xb_cb_write(b, value_type, value, off)) return false;
		Type *tag_type = union_tag_type(bt);
		i64 tag_index = union_variant_index_checked(bt, value_type);
		xb_cb_int(b, off + bt->Union.variant_block_size, type_size_of(tag_type), cast(u64)tag_index, false);
		return true;
	}

	if (value.kind == ExactValue_Procedure) {
		for (;;) {
			Ast *expr = unparen_expr(value.value_procedure);
			if (expr->kind == Ast_ProcLit) {
				return xb_cb_fail(b, "procedure literal in constant data");
			}
			Entity *e = entity_from_expr(expr);
			if (e == nullptr) return xb_cb_fail(b, "procedure constant");
			if (e->kind != Entity_Constant) {
				if (e->kind != Entity_Procedure) return xb_cb_fail(b, "procedure constant");
				if (lb_enclosing_proc_decl(e->decl_info) != nullptr) return xb_cb_fail(b, "nested procedure in constant data");
				i32 sym = xb_symbol(m, xb_entity_name(m, e));
				m->symbols[sym].flags |= xbSymbolFlag_Func;
				if (e->Procedure.is_foreign) {
					m->symbols[sym].flags |= xbSymbolFlag_Foreign;
					xb_note_foreign_library(m, e->Procedure.foreign_library);
				}
				xb_cb_reloc(b, off, sym, 0);
				return true;
			}
			value = e->Constant.value;
		}
	}

	if (value.kind == ExactValue_Invalid) return true;

	if (value.kind == ExactValue_Typeid) {
		xb_cb_int(b, off, 8, type_hash_canonical_type(default_type(value.value_typeid)), false);
		return true;
	}

	if (value.kind == ExactValue_Compound) {
		ast_node(cl, CompoundLit, value.value_compound);
		if (cl->elems.count == 0) return true;
	}

	if (is_type_slice(type)) {
		Type *elem = base_type(type)->Slice.elem;
		if (value.kind == ExactValue_String) {
			String s = value.value_string;
			if (s.len > 0) {
				xb_cb_reloc(b, off, xb_string_literal(m, s), 0);
			}
			xb_cb_int(b, off+8, 8, cast(u64)s.len, false);
			return true;
		}
		if (value.kind != ExactValue_Compound) return xb_cb_fail(b, "slice constant");
		ast_node(cl, CompoundLit, value.value_compound);
		isize count = gb_max(cast(isize)cl->max_count, cl->elems.count);
		Type *t = alloc_type_array(elem, count);
		char const *reason = nullptr;
		i32 sym = xb_const_global(m, t, value, b->writable, &reason);
		if (sym < 0) return xb_cb_fail(b, reason);
		xb_cb_reloc(b, off, sym, 0);
		xb_cb_int(b, off+8, 8, cast(u64)count, false);
		return true;
	}

	if (is_type_array(type) && value.kind == ExactValue_String) {
		Type *elem = core_type(type->Array.elem);
		String s = value.value_string;
		if (is_type_u8(elem)) {
			xb_cb_bytes(b, off, s.text, gb_min(s.len, cast(isize)type->Array.count));
			return true;
		}
		i64 stride = type_size_of(elem);
		if (is_type_rune(elem) || (stride == 4 && is_type_integer(elem))) {
			isize offset = 0;
			for (i64 i = 0; i < type->Array.count && offset < s.len; i++) {
				Rune r = 0;
				isize width = utf8_decode(s.text+offset, s.len-offset, &r);
				offset += width;
				xb_cb_int(b, off + i*stride, stride, cast(u64)cast(i64)r, false);
			}
			return true;
		}
		if (is_type_u16(elem)) {
			String16 s16 = string_to_string16(temporary_allocator(), s);
			for (isize i = 0; i < s16.len && i < type->Array.count; i++) {
				xb_cb_int(b, off + i*2, 2, s16.text[i], false);
			}
			return true;
		}
		return xb_cb_fail(b, "string constant array");
	}

	if (is_type_array(type) && value.kind != ExactValue_Invalid && value.kind != ExactValue_Compound) {
		// a single value spread over the array
		Type *elem = type->Array.elem;
		i64 stride = type_size_of(elem);
		for (i64 i = 0; i < type->Array.count; i++) {
			if (!xb_cb_write(b, elem, value, off + i*stride)) return false;
		}
		return true;
	}
	if ((is_type_matrix(type) || is_type_simd_vector(type)) && value.kind != ExactValue_Compound) {
		return xb_cb_fail(b, "matrix/simd constant");
	}

	bool swap = is_type_different_to_arch_endianness(type);
	i64 size = type_size_of(type);

	switch (value.kind) {
	case ExactValue_Bool:
		xb_cb_int(b, off, size, value.value_bool ? 1 : 0, false);
		return true;
	case ExactValue_String: {
		String s = value.value_string;
		if (is_type_string16(type) || is_type_cstring16(type)) {
			isize len = 0;
			i32 sym = xb_string16_literal(m, s, &len);
			xb_cb_reloc(b, off, sym, 0);
			if (is_type_string16(type)) xb_cb_int(b, off+8, 8, cast(u64)len, false);
			return true;
		}
		if (is_type_cstring(type)) {
			xb_cb_reloc(b, off, xb_string_literal(m, s), 0);
			return true;
		}
		if (is_type_string(type)) {
			if (s.len > 0) xb_cb_reloc(b, off, xb_string_literal(m, s), 0);
			xb_cb_int(b, off+8, 8, cast(u64)s.len, false);
			return true;
		}
		return xb_cb_fail(b, "string constant type");
	}
	case ExactValue_String16: {
		if (!is_type_string16(type) && !is_type_cstring16(type)) return xb_cb_fail(b, "string16 constant");
		isize len = 0;
		i32 sym = xb_string16_literal_raw(m, value.value_string16, &len);
		xb_cb_reloc(b, off, sym, 0);
		if (is_type_string16(type)) xb_cb_int(b, off+8, 8, cast(u64)len, false);
		return true;
	}
	case ExactValue_Integer:
		if (is_type_float(type)) {
			value = exact_value_to_float(value);
			goto write_float;
		}
		xb_cb_big_int(b, off, size, &value.value_integer, swap);
		return true;
	case ExactValue_Rational:
		value = exact_value_to_float(value);
		/*fallthrough*/
	case ExactValue_Float:
	write_float:
		if (is_type_integer(type)) {
			xb_cb_int(b, off, size, cast(u64)cast(i64)value.value_float, swap);
			return true;
		}
		switch (size) {
		case 2: {
			u16 h = f32_to_f16(cast(f32)value.value_float);
			xb_cb_int(b, off, 2, h, swap);
			return true;
		}
		case 4: {
			f32 f = cast(f32)value.value_float;
			u32 u = 0;
			gb_memmove(&u, &f, 4);
			xb_cb_int(b, off, 4, u, swap);
			return true;
		}
		case 8: {
			u64 u = 0;
			gb_memmove(&u, &value.value_float, 8);
			xb_cb_int(b, off, 8, u, swap);
			return true;
		}
		}
		return xb_cb_fail(b, "float constant size");
	case ExactValue_Complex: {
		i64 es = size/2;
		f64 parts[2] = {exact_value_to_f64(value.value_complex->real), exact_value_to_f64(value.value_complex->imag)};
		for (int i = 0; i < 2; i++) {
			ExactValue ev = exact_value_float(parts[i]);
			Type *et = es == 2 ? t_f16 : es == 4 ? t_f32 : t_f64;
			if (!xb_cb_write(b, et, ev, off + i*es)) return false;
		}
		return true;
	}
	case ExactValue_Quaternion: {
		// @QuaternionLayout: i, j, k, real
		i64 es = size/4;
		f64 parts[4] = {
			exact_value_to_f64(value.value_quaternion->imag),
			exact_value_to_f64(value.value_quaternion->jmag),
			exact_value_to_f64(value.value_quaternion->kmag),
			exact_value_to_f64(value.value_quaternion->real),
		};
		for (int i = 0; i < 4; i++) {
			Type *et = es == 2 ? t_f16 : es == 4 ? t_f32 : t_f64;
			if (!xb_cb_write(b, et, exact_value_float(parts[i]), off + i*es)) return false;
		}
		return true;
	}
	case ExactValue_Pointer:
		xb_cb_int(b, off, 8, cast(u64)value.value_pointer, false);
		return true;
	case ExactValue_Compound: {
		if (is_type_bit_field(original_type)) return xb_cb_fail(b, "bit_field constant");
		if (is_type_soa_struct(type)) return xb_cb_fail(b, "soa constant");
		if (is_type_array(type)) {
			Type *elem = type->Array.elem;
			if (!elem_type_can_be_constant(elem)) return true;
			ast_node(cl, CompoundLit, value.value_compound);
			i64 stride = type_size_of(elem);
			Type *lit_type = value.value_compound->tav.type;
			// a literal of an element type (at any depth, or a variant of a union element) is spread over the elements
			if (lit_type != nullptr && lb_const_value_is_broadcast(elem, lit_type)) {
				for (i64 i = 0; i < type->Array.count; i++) {
					if (!xb_cb_write(b, elem, value, off + i*stride)) return false;
				}
				return true;
			}
			return xb_cb_array_elems(b, value.value_compound, elem, type->Array.count, 0, stride, off);
		}
		if (is_type_enumerated_array(type)) {
			Type *elem = type->EnumeratedArray.elem;
			if (!elem_type_can_be_constant(elem)) return true;
			i64 min_index = exact_value_to_i64(*type->EnumeratedArray.min_value);
			ast_node(cl, CompoundLit, value.value_compound);
			if (cl->elems[0]->kind != Ast_FieldValue) min_index = 0;
			return xb_cb_array_elems(b, value.value_compound, elem, type->EnumeratedArray.count, min_index, type_size_of(elem), off);
		}
		if (is_type_struct(type)) {
			ast_node(cl, CompoundLit, value.value_compound);
			if (is_type_raw_union(type)) {
				if (!is_type_raw_union_constantable(type)) return true;
				ast_node(fv, FieldValue, cl->elems[0]);
				Entity *f = entity_of_node(fv->field);
				return xb_cb_write(b, f->type, fv->value->tav.value, off);
			}
			type_set_offsets(type);
			if (cl->elems[0]->kind == Ast_FieldValue) {
				for (Ast *elem : cl->elems) {
					ast_node(fv, FieldValue, elem);
					Selection sel = lookup_field(type, fv->field->Ident.interned, false);
					if (sel.indirect) return xb_cb_fail(b, "indirect field in constant");
					// walk the selection to the field's offset
					Type *t = type;
					i64 foff = 0;
					for (i32 index : sel.index) {
						Type *bt = base_type(t);
						Type *ft = nullptr;
						if (bt->kind == Type_Struct) {
							if (bt->Struct.is_raw_union) {
								ft = bt->Struct.fields[index]->type;
							} else {
								foff += type_offset_of(bt, index, &ft);
							}
						} else if (bt->kind == Type_Array) {
							ft = bt->Array.elem;
							foff += index * type_size_of(ft);
						} else {
							return xb_cb_fail(b, "constant field path");
						}
						t = ft;
					}
					if (!elem_type_can_be_constant(t)) continue;
					if (!xb_cb_write(b, t, fv->value->tav.value, off + foff)) return false;
				}
			} else {
				isize offset_extra = 0;
				for_array(i, cl->elems) {
					TypeAndValue tav = cl->elems[i]->tav;
					if (is_type_tuple(tav.type)) return xb_cb_fail(b, "tuple in constant struct");
					isize fi = i + offset_extra;
					if (fi >= type->Struct.fields.count) break;
					Entity *f = type->Struct.fields[fi];
					if (!elem_type_can_be_constant(f->type)) continue;
					Type *ft = nullptr;
					i64 foff = type_offset_of(type, fi, &ft);
					if (!xb_cb_write(b, f->type, tav.value, off + foff)) return false;
				}
			}
			return true;
		}
		if (is_type_bit_set(type)) {
			ast_node(cl, CompoundLit, value.value_compound);
			BigInt bits = {};
			BigInt one = {};
			big_int_from_u64(&one, 1);
			for (Ast *e : cl->elems) {
				TypeAndValue tav = e->tav;
				if (tav.mode != Addressing_Constant) continue;
				i64 v = big_int_to_i64(&tav.value.value_integer);
				u64 index = cast(u64)(v - type->BitSet.lower);
				BigInt bit = {};
				big_int_from_u64(&bit, index);
				big_int_shl(&bit, &one, &bit);
				big_int_or(&bits, &bits, &bit);
			}
			xb_cb_big_int(b, off, size, &bits, is_type_different_to_arch_endianness(bit_set_to_int(type)));
			return true;
		}
		return xb_cb_fail(b, "compound constant type");
	}
	}
	return xb_cb_fail(b, "constant kind");
}

// An anonymous object holding the constant. Returns its symbol, or -1.
gb_internal i32 xb_const_global(xbModule *m, Type *type, ExactValue value, bool writable, char const **reason) {
	xbConstBuf b = {};
	b.m = m;
	b.writable = writable;
	i64 size = type_size_of(type);
	i64 align = gb_max(type_align_of(type), cast(i64)1);
	b.bytes = array_make<u8>(heap_allocator(), size, size);
	gb_zero_size(b.bytes.data, size);
	b.relocs = array_make<xbReloc>(heap_allocator(), 0, 4);
	defer (array_free(&b.bytes));
	defer (array_free(&b.relocs));
	if (!xb_cb_write(&b, type, value, 0)) {
		*reason = b.fail;
		return -1;
	}
	// anything with pointers is relocated at load time, so it goes into writable data
	xbSection sec = (writable || b.relocs.count > 0) ? xbSection_Data : xbSection_Rodata;
	Array<u8> *data = &m->sections[sec];
	while (data->count % align != 0) array_add(data, cast(u8)0);
	i64 at = data->count;
	array_add_elems(data, b.bytes.data, b.bytes.count);
	for (xbReloc r : b.relocs) {
		r.section = sec;
		r.offset += at;
		array_add(&m->relocs, r);
	}
	char name[64] = {};
	gb_snprintf(name, gb_size_of(name), ".Lxb.const.%d.%lld", cast(int)sec, cast(long long)at);
	i32 sym = xb_symbol(m, make_string_c(name));
	xbSymbol *s = &m->symbols[sym];
	s->section = sec;
	s->offset = at;
	s->size = size;
	s->flags = 0;
	return sym;
}

// Writes the constant into an existing object at `section`+`offset`.
gb_internal bool xb_const_write_at(xbModule *m, xbSection sec, i64 at, Type *type, ExactValue value, char const **reason) {
	xbConstBuf b = {};
	b.m = m;
	b.writable = sec == xbSection_Data || sec == xbSection_TData;
	i64 size = type_size_of(type);
	b.bytes = array_make<u8>(heap_allocator(), size, size);
	gb_zero_size(b.bytes.data, size);
	b.relocs = array_make<xbReloc>(heap_allocator(), 0, 4);
	defer (array_free(&b.bytes));
	defer (array_free(&b.relocs));
	if (!xb_cb_write(&b, type, value, 0)) {
		*reason = b.fail;
		return false;
	}
	gb_memmove(m->sections[sec].data + at, b.bytes.data, size);
	for (xbReloc r : b.relocs) {
		r.section = sec;
		r.offset += at;
		array_add(&m->relocs, r);
	}
	return true;
}
