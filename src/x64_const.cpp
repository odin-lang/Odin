// Constant data: Odin constants laid out as bytes with relocations, for global
// variables, static variables and large constant literals.

struct xbConstBuf {
	xbModule *     m;
	Array<u8>      bytes;
	Array<xbReloc> relocs; // offsets are relative to the start of `bytes`
	bool           writable;
	char const *   fail;
	Array<Entity *> *proc_lits; // procedure literals the data refers to, if allowed
};

gb_internal Entity *xb_proc_lit_entity(xbModule *m, Ast *expr);

gb_internal i32 xb_const_global(xbModule *m, Type *type, ExactValue value, bool writable, char const **reason);
gb_internal i32 xb_const_place(xbConstBuf *b, i64 align);

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
	// two's complement little endian bytes of any width (wide bit_sets hold more than 128 bits)
	i64 nwords = gb_max((size + 7)/8, cast(i64)2);
	u64 *words = gb_alloc_array(temporary_allocator(), u64, nwords);
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
	for (i64 w = 0; w < nwords; w++) {
		BigInt lo = {};
		big_int_and(&lo, &v, &mask);
		words[w] = big_int_to_u64(&lo);
		BigInt next = {};
		big_int_shr(&next, &v, &shift);
		v = next;
	}
	if (neg) {
		bool carry = true;
		for (i64 w = 0; w < nwords; w++) {
			words[w] = ~words[w];
			if (carry) {
				words[w] += 1;
				carry = words[w] == 0;
			}
		}
	}
	u8 *tmp = cast(u8 *)words;
	if (swap) {
		for (i64 i = 0; i < size/2; i++) {
			u8 t = tmp[i]; tmp[i] = tmp[size-1-i]; tmp[size-1-i] = t;
		}
	}
	xb_cb_bytes(b, off, tmp, size);
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

// lb_const_value_bit_field: each field's low bits at its bit offset, numbered little endian
gb_internal bool xb_cb_bit_field(xbConstBuf *b, Type *type, ExactValue value, i64 off) {
	Type *bt = base_type(type);
	ast_node(cl, CompoundLit, value.value_compound);
	for (Ast *elem : cl->elems) {
		ast_node(fv, FieldValue, elem);
		Selection sel = lookup_field(bt, fv->field->Ident.interned, false);
		GB_ASSERT(sel.is_bit_field && sel.index.count == 1);
		if (fv->value->tav.mode != Addressing_Constant) continue;
		Type *ft = sel.entity->type;
		if (is_type_different_to_arch_endianness(ft) || is_type_endian_big(ft)) return xb_cb_fail(b, "endian bit_field constant");
		i64 bit_offset = bt->BitField.bit_offsets[sel.index[0]];
		i64 bit_size   = bt->BitField.bit_sizes[sel.index[0]];
		ExactValue v = fv->value->tav.value;
		u64 bits = 0;
		if (v.kind == ExactValue_Bool) {
			bits = v.value_bool ? 1 : 0;
		} else {
			v = exact_value_to_integer(v);
			if (v.kind != ExactValue_Integer) return xb_cb_fail(b, "bit_field constant value");
			bits = big_int_is_neg(&v.value_integer) ? cast(u64)big_int_to_i64(&v.value_integer) : big_int_to_u64(&v.value_integer);
		}
		for (i64 i = 0; i < bit_size; i++) {
			if ((bits >> i) & 1) {
				i64 at = bit_offset + i;
				b->bytes[off + (at >> 3)] |= cast(u8)(1 << (at & 7));
			}
		}
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
				// compiled along with the global that refers to it
				if (b->proc_lits == nullptr) return xb_cb_fail(b, "procedure literal in constant data");
				ast_node(pl, ProcLit, expr);
				if (pl->body == nullptr || lb_enclosing_proc_decl(pl->decl) != nullptr) return xb_cb_fail(b, "procedure literal in constant data");
				Entity *e = xb_proc_lit_entity(m, expr);
				i32 sym = xb_symbol(m, xb_entity_name(m, e));
				m->symbols[sym].flags |= xbSymbolFlag_Func;
				xb_cb_reloc(b, off, sym, 0);
				array_add(b->proc_lits, e);
				return true;
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
	if (is_type_matrix(type) && value.kind != ExactValue_Compound) {
		// a scalar is the diagonal
		Type *elem = type->Matrix.elem;
		i64 es = type_size_of(elem);
		for (i64 i = 0; i < gb_min(type->Matrix.row_count, type->Matrix.column_count); i++) {
			if (!xb_cb_write(b, elem, value, off + matrix_indices_to_offset(type, i, i)*es)) return false;
		}
		return true;
	}
	if (is_type_simd_vector(type) && value.kind != ExactValue_Compound) {
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
		if (is_type_bit_field(original_type)) return xb_cb_bit_field(b, original_type, value, off);
		if (is_type_soa_struct(type)) return xb_cb_fail(b, "soa constant");
		if (is_type_array(type)) {
			Type *elem = type->Array.elem;
			if (!elem_type_can_be_constant(elem)) return true;
			ast_node(cl, CompoundLit, value.value_compound);
			i64 stride = type_size_of(elem);
			Type *lit_type = value.value_compound->tav.type;
			// a literal of an element type, at any depth of a nested array, is spread over the elements
			bool spread = false;
			if (lit_type != nullptr && !is_type_array(lit_type)) {
				for (Type *e = elem; e != nullptr; e = is_type_array(e) ? base_type(e)->Array.elem : nullptr) {
					if (are_types_identical(base_type(lit_type), base_type(e))) {
						spread = true;
						break;
					}
				}
			}
			if (spread) {
				for (i64 i = 0; i < type->Array.count; i++) {
					if (!xb_cb_write(b, elem, value, off + i*stride)) return false;
				}
				return true;
			}
			return xb_cb_array_elems(b, value.value_compound, elem, type->Array.count, 0, stride, off);
		}
		if (is_type_matrix(type)) {
			// elements in row major order
			Type *elem = type->Matrix.elem;
			if (!elem_type_can_be_constant(elem)) return true;
			i64 es = type_size_of(elem);
			ast_node(cl, CompoundLit, value.value_compound);
			i64 index = 0;
			for (Ast *e : cl->elems) {
				if (e->kind == Ast_FieldValue) {
					ast_node(fv, FieldValue, e);
					i64 lo = 0, hi = 0;
					if (is_ast_range(fv->field)) {
						ast_node(ie, BinaryExpr, fv->field);
						lo = exact_value_to_i64(ie->left->tav.value);
						hi = exact_value_to_i64(ie->right->tav.value);
						if (ie->op.kind != Token_RangeHalf) hi += 1;
					} else {
						lo = exact_value_to_i64(fv->field->tav.value);
						hi = lo + 1;
					}
					for (i64 k = lo; k < hi; k++) {
						if (!xb_cb_write(b, elem, fv->value->tav.value, off + matrix_row_major_index_to_offset(type, k)*es)) return false;
					}
				} else {
					if (!xb_cb_write(b, elem, e->tav.value, off + matrix_row_major_index_to_offset(type, index++)*es)) return false;
				}
			}
			return true;
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
		if (is_type_bit_set(type) && is_type_array(bit_set_to_int(type))) {
			// bit k lives in byte k/8 of little endian elements
			Type *et = base_array_type(bit_set_to_int(type));
			if (type_size_of(et) > 1 && is_type_different_to_arch_endianness(et)) return xb_cb_fail(b, "bit_set of endian array");
			ast_node(cl, CompoundLit, value.value_compound);
			for (Ast *e : cl->elems) {
				if (e->tav.mode != Addressing_Constant) continue;
				i64 k = exact_value_to_i64(e->tav.value) - type->BitSet.lower;
				if (k < 0 || k >= 8*size) continue;
				b->bytes[off + (k >> 3)] |= cast(u8)(1 << (k & 7));
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
	return xb_const_place(&b, align);
}

// Puts the bytes of a constant buffer into an anonymous object. Returns its symbol.
gb_internal i32 xb_const_place(xbConstBuf *bp, i64 align) {
	xbConstBuf &b = *bp;
	xbModule *m = b.m;
	i64 size = b.bytes.count;
	// anything with pointers is relocated at load time, so it goes into writable data
	xbSection sec = (b.writable || b.relocs.count > 0) ? xbSection_Data : xbSection_Rodata;
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
