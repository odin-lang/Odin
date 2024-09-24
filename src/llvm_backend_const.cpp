gb_internal bool lb_is_const(lbValue value) {
	LLVMValueRef v = value.value;
	if (is_type_untyped_nil(value.type)) {
		// TODO(bill): Is this correct behaviour?
		return true;
	}
	if (LLVMIsConstant(v)) {
		return true;
	}
	return false;
}

gb_internal bool lb_is_const_or_global(lbValue value) {
	if (lb_is_const(value)) {
		return true;
	}
	return false;
}


gb_internal bool lb_is_elem_const(Ast *elem, Type *elem_type) {
	if (!elem_type_can_be_constant(elem_type)) {
		return false;
	}
	if (elem->kind == Ast_FieldValue) {
		elem = elem->FieldValue.value;
	}
	TypeAndValue tav = type_and_value_of_expr(elem);
	GB_ASSERT_MSG(tav.mode != Addressing_Invalid, "%s %s", expr_to_string(elem), type_to_string(tav.type));
	return tav.value.kind != ExactValue_Invalid;
}


gb_internal bool lb_is_const_nil(lbValue value) {
	LLVMValueRef v = value.value;
	if (LLVMIsConstant(v)) {
		if (LLVMIsAConstantAggregateZero(v)) {
			return true;
		} else if (LLVMIsAConstantPointerNull(v)) {
			return true;
		}
	}
	return false;
}


gb_internal bool lb_is_expr_constant_zero(Ast *expr) {
	GB_ASSERT(expr != nullptr);
	auto v = exact_value_to_integer(expr->tav.value);
	if (v.kind == ExactValue_Integer) {
		return big_int_cmp_zero(&v.value_integer) == 0;
	}
	return false;
}

gb_internal String lb_get_const_string(lbModule *m, lbValue value) {
	GB_ASSERT(lb_is_const(value));
	GB_ASSERT(LLVMIsConstant(value.value));

	Type *t = base_type(value.type);
	GB_ASSERT(are_types_identical(t, t_string));



	unsigned     ptr_indices[1] = {0};
	unsigned     len_indices[1] = {1};
	LLVMValueRef underlying_ptr = llvm_const_extract_value(m, value.value, ptr_indices, gb_count_of(ptr_indices));
	LLVMValueRef underlying_len = llvm_const_extract_value(m, value.value, len_indices, gb_count_of(len_indices));

	GB_ASSERT(LLVMGetConstOpcode(underlying_ptr) == LLVMGetElementPtr);
	underlying_ptr = LLVMGetOperand(underlying_ptr, 0);
	GB_ASSERT(LLVMIsAGlobalVariable(underlying_ptr));
	underlying_ptr = LLVMGetInitializer(underlying_ptr);

	size_t length = 0;
	char const *text = LLVMGetAsString(underlying_ptr, &length);

	isize real_length = cast(isize)LLVMConstIntGetSExtValue(underlying_len);

	return make_string(cast(u8 const *)text, real_length);
}


gb_internal LLVMValueRef llvm_const_cast(LLVMValueRef val, LLVMTypeRef dst) {
	LLVMTypeRef src = LLVMTypeOf(val);
	if (src == dst) {
		return val;
	}
	if (LLVMIsNull(val)) {
		return LLVMConstNull(dst);
	}

	GB_ASSERT_MSG(lb_sizeof(dst) == lb_sizeof(src), "%s vs %s", LLVMPrintTypeToString(dst), LLVMPrintTypeToString(src));
	LLVMTypeKind kind = LLVMGetTypeKind(dst);
	switch (kind) {
	case LLVMPointerTypeKind:
		return LLVMConstPointerCast(val, dst);
	case LLVMStructTypeKind:
		// GB_PANIC("%s -> %s", LLVMPrintValueToString(val), LLVMPrintTypeToString(dst));
		// NOTE(bill): It's not possible to do a bit cast on a struct, why was this code even here in the first place?
		// It seems mostly to exist to get around the "anonymous -> named" struct assignments
		// return LLVMConstBitCast(val, dst);
		return val;
	default:
		GB_PANIC("Unhandled const cast %s to %s", LLVMPrintTypeToString(src), LLVMPrintTypeToString(dst));
	}

	return val;
}


gb_internal lbValue lb_const_ptr_cast(lbModule *m, lbValue value, Type *t) {
	GB_ASSERT(is_type_internally_pointer_like(value.type));
	GB_ASSERT(is_type_internally_pointer_like(t));
	GB_ASSERT(lb_is_const(value));

	lbValue res = {};
	res.value = LLVMConstPointerCast(value.value, lb_type(m, t));
	res.type = t;
	return res;
}


gb_internal LLVMValueRef llvm_const_string_internal(lbModule *m, Type *t, LLVMValueRef data, LLVMValueRef len) {
	if (build_context.metrics.ptr_size < build_context.metrics.int_size) {
		LLVMValueRef values[3] = {
			data,
			LLVMConstNull(lb_type(m, t_i32)),
			len,
		};
		return llvm_const_named_struct_internal(lb_type(m, t), values, 3);
	} else {
		LLVMValueRef values[2] = {
			data,
			len,
		};
		return llvm_const_named_struct_internal(lb_type(m, t), values, 2);
	}
}


gb_internal LLVMValueRef llvm_const_named_struct(lbModule *m, Type *t, LLVMValueRef *values, isize value_count_) {
	LLVMTypeRef struct_type = lb_type(m, t);
	GB_ASSERT(LLVMGetTypeKind(struct_type) == LLVMStructTypeKind);
	
	unsigned value_count = cast(unsigned)value_count_;
	unsigned elem_count = LLVMCountStructElementTypes(struct_type);
	if (elem_count == value_count) {
		return llvm_const_named_struct_internal(struct_type, values, value_count_);
	}
	Type *bt = base_type(t);
	GB_ASSERT(bt->kind == Type_Struct);
	
	GB_ASSERT(value_count_ == bt->Struct.fields.count);
	
	auto field_remapping = lb_get_struct_remapping(m, t);
	unsigned values_with_padding_count = elem_count;
	
	LLVMValueRef *values_with_padding = gb_alloc_array(permanent_allocator(), LLVMValueRef, values_with_padding_count);
	for (unsigned i = 0; i < value_count; i++) {
		values_with_padding[field_remapping[i]] = values[i];
	}
	for (unsigned i = 0; i < values_with_padding_count; i++) {
		if (values_with_padding[i] == nullptr) {
			values_with_padding[i] = LLVMConstNull(LLVMStructGetTypeAtIndex(struct_type, i));
		}
	}
	
	return llvm_const_named_struct_internal(struct_type, values_with_padding, values_with_padding_count);
}

gb_internal LLVMValueRef llvm_const_named_struct_internal(LLVMTypeRef t, LLVMValueRef *values, isize value_count_) {
	unsigned value_count = cast(unsigned)value_count_;
	unsigned elem_count = LLVMCountStructElementTypes(t);
	GB_ASSERT_MSG(value_count == elem_count, "%s %u %u", LLVMPrintTypeToString(t), value_count, elem_count);
	for (unsigned i = 0; i < elem_count; i++) {
		LLVMTypeRef elem_type = LLVMStructGetTypeAtIndex(t, i);
		values[i] = llvm_const_cast(values[i], elem_type);
	}
	return LLVMConstNamedStruct(t, values, value_count);
}

gb_internal LLVMValueRef llvm_const_array(LLVMTypeRef elem_type, LLVMValueRef *values, isize value_count_) {
	unsigned value_count = cast(unsigned)value_count_;
	for (unsigned i = 0; i < value_count; i++) {
		values[i] = llvm_const_cast(values[i], elem_type);
	}
	return LLVMConstArray(elem_type, values, value_count);
}

gb_internal LLVMValueRef llvm_const_slice_internal(lbModule *m, LLVMValueRef data, LLVMValueRef len) {
	if (build_context.metrics.ptr_size < build_context.metrics.int_size) {
		GB_ASSERT(build_context.metrics.ptr_size == 4);
		GB_ASSERT(build_context.metrics.int_size == 8);
		LLVMValueRef vals[3] = {
			data,
			LLVMConstNull(lb_type(m, t_u32)),
			len,
		};
		return LLVMConstStructInContext(m->ctx, vals, gb_count_of(vals), false);
	} else {
		LLVMValueRef vals[2] = {
			data,
			len,
		};
		return LLVMConstStructInContext(m->ctx, vals, gb_count_of(vals), false);
	}
}
gb_internal LLVMValueRef llvm_const_slice(lbModule *m, lbValue data, lbValue len) {
	GB_ASSERT(is_type_pointer(data.type) || is_type_multi_pointer(data.type));
	GB_ASSERT(are_types_identical(len.type, t_int));

	return llvm_const_slice_internal(m, data.value, len.value);
}



gb_internal lbValue lb_const_nil(lbModule *m, Type *type) {
	LLVMValueRef v = LLVMConstNull(lb_type(m, type));
	return lbValue{v, type};
}

gb_internal lbValue lb_const_undef(lbModule *m, Type *type) {
	LLVMValueRef v = LLVMGetUndef(lb_type(m, type));
	return lbValue{v, type};
}



gb_internal lbValue lb_const_int(lbModule *m, Type *type, u64 value) {
	lbValue res = {};
	res.value = LLVMConstInt(lb_type(m, type), cast(unsigned long long)value, !is_type_unsigned(type));
	res.type = type;
	return res;
}

gb_internal lbValue lb_const_string(lbModule *m, String const &value) {
	return lb_const_value(m, t_string, exact_value_string(value));
}


gb_internal lbValue lb_const_bool(lbModule *m, Type *type, bool value) {
	lbValue res = {};
	res.value = LLVMConstInt(lb_type(m, type), value, false);
	res.type = type;
	return res;
}

gb_internal LLVMValueRef lb_const_f16(lbModule *m, f32 f, Type *type=t_f16) {
	GB_ASSERT(type_size_of(type) == 2);

	u16 u = f32_to_f16(f);
	if (is_type_different_to_arch_endianness(type)) {
		u = gb_endian_swap16(u);
	}
	LLVMValueRef i = LLVMConstInt(LLVMInt16TypeInContext(m->ctx), u, false);
	return LLVMConstBitCast(i, lb_type(m, type));
}

gb_internal LLVMValueRef lb_const_f32(lbModule *m, f32 f, Type *type=t_f32) {
	GB_ASSERT(type_size_of(type) == 4);
	u32 u = bit_cast<u32>(f);
	if (is_type_different_to_arch_endianness(type)) {
		u = gb_endian_swap32(u);
	}
	LLVMValueRef i = LLVMConstInt(LLVMInt32TypeInContext(m->ctx), u, false);
	return LLVMConstBitCast(i, lb_type(m, type));
}



gb_internal bool lb_is_expr_untyped_const(Ast *expr) {
	auto const &tv = type_and_value_of_expr(expr);
	if (is_type_untyped(tv.type)) {
		return tv.value.kind != ExactValue_Invalid;
	}
	return false;
}


gb_internal lbValue lb_expr_untyped_const_to_typed(lbModule *m, Ast *expr, Type *t) {
	GB_ASSERT(is_type_typed(t));
	auto const &tv = type_and_value_of_expr(expr);
	return lb_const_value(m, t, tv.value);
}


gb_internal lbValue lb_const_source_code_location_const(lbModule *m, String const &procedure_, TokenPos const &pos) {
	String file = get_file_path_string(pos.file_id);
	String procedure = procedure_;

	i32 line   = pos.line;
	i32 column = pos.column;

	if (build_context.obfuscate_source_code_locations) {
		file = obfuscate_string(file, "F");
		procedure = obfuscate_string(procedure, "P");

		line   = obfuscate_i32(line);
		column = obfuscate_i32(column);
	}

	LLVMValueRef fields[4] = {};
	fields[0]/*file*/      = lb_find_or_add_entity_string(m, file).value;
	fields[1]/*line*/      = lb_const_int(m, t_i32, line).value;
	fields[2]/*column*/    = lb_const_int(m, t_i32, column).value;
	fields[3]/*procedure*/ = lb_find_or_add_entity_string(m, procedure).value;

	lbValue res = {};
	res.value = llvm_const_named_struct(m, t_source_code_location, fields, gb_count_of(fields));
	res.type = t_source_code_location;
	return res;
}


gb_internal lbValue lb_emit_source_code_location_const(lbProcedure *p, String const &procedure, TokenPos const &pos) {
	lbModule *m = p->module;
	return lb_const_source_code_location_const(m, procedure, pos);
}

gb_internal lbValue lb_emit_source_code_location_const(lbProcedure *p, Ast *node) {
	String proc_name = {};
	if (p->entity) {
		proc_name = p->entity->token.string;
	}
	TokenPos pos = {};
	if (node) {
		pos = ast_token(node).pos;
	}
	return lb_emit_source_code_location_const(p, proc_name, pos);
}


gb_internal lbValue lb_emit_source_code_location_as_global_ptr(lbProcedure *p, String const &procedure, TokenPos const &pos) {
	lbValue loc = lb_emit_source_code_location_const(p, procedure, pos);
	lbAddr addr = lb_add_global_generated(p->module, loc.type, loc, nullptr);
	lb_make_global_private_const(addr);
	return addr.addr;
}

gb_internal lbValue lb_const_source_code_location_as_global_ptr(lbModule *m, String const &procedure, TokenPos const &pos) {
	lbValue loc = lb_const_source_code_location_const(m, procedure, pos);
	lbAddr addr = lb_add_global_generated(m, loc.type, loc, nullptr);
	lb_make_global_private_const(addr);
	return addr.addr;
}




gb_internal lbValue lb_emit_source_code_location_as_global_ptr(lbProcedure *p, Ast *node) {
	lbValue loc = lb_emit_source_code_location_const(p, node);
	lbAddr addr = lb_add_global_generated(p->module, loc.type, loc, nullptr);
	lb_make_global_private_const(addr);
	return addr.addr;
}

gb_internal lbValue lb_emit_source_code_location_as_global(lbProcedure *p, String const &procedure, TokenPos const &pos) {
	return lb_emit_load(p, lb_emit_source_code_location_as_global_ptr(p, procedure, pos));
}

gb_internal lbValue lb_emit_source_code_location_as_global(lbProcedure *p, Ast *node) {
	return lb_emit_load(p, lb_emit_source_code_location_as_global_ptr(p, node));
}



gb_internal LLVMValueRef lb_build_constant_array_values(lbModule *m, Type *type, Type *elem_type, isize count, LLVMValueRef *values, bool allow_local, bool is_rodata) {
	if (allow_local) {
		is_rodata = false;
	}

	bool is_local = allow_local && m->curr_procedure != nullptr;
	bool is_const = true;
	if (is_local) {
		for (isize i = 0; i < count; i++) {
			GB_ASSERT(values[i] != nullptr);
			if (!LLVMIsConstant(values[i])) {
				is_const = false;
				break;
			}
		}
	}

	if (!is_const) {
		LLVMTypeRef llvm_elem_type = lb_type(m, elem_type);
		lbProcedure *p = m->curr_procedure;
		GB_ASSERT(p != nullptr);
		lbAddr v = lb_add_local_generated(p, type, false);
		lbValue ptr = lb_addr_get_ptr(p, v);
		for (isize i = 0; i < count; i++) {
			lbValue elem = lb_emit_array_epi(p, ptr, i);
			if (is_type_proc(elem_type)) {
				values[i] = LLVMConstPointerCast(values[i], llvm_elem_type);
			}
			LLVMBuildStore(p->builder, values[i], elem.value);
		}
		return lb_addr_load(p, v).value;
	}

	return llvm_const_array(lb_type(m, elem_type), values, cast(unsigned int)count);
}

gb_internal LLVMValueRef lb_big_int_to_llvm(lbModule *m, Type *original_type, BigInt const *a) {
	if (big_int_is_zero(a)) {
		return LLVMConstNull(lb_type(m, original_type));
	}

	size_t sz = cast(size_t)type_size_of(original_type);
	u64 rop64[4] = {}; // 2 u64 is the maximum we will ever need, so doubling it will be fine :P
	u8 *rop = cast(u8 *)rop64;

	size_t max_count = 0;
	size_t written = 0;
	size_t size = 1;
	size_t nails = 0;
	mp_endian endian = MP_LITTLE_ENDIAN;

	max_count = mp_pack_count(a, nails, size);
	if (sz < max_count) {
		debug_print_big_int(a);
		gb_printf_err("%s -> %tu\n", type_to_string(original_type), sz);;
	}
	GB_ASSERT_MSG(sz >= max_count, "max_count: %tu, sz: %tu, written: %tu, type %s", max_count, sz, written, type_to_string(original_type));
	GB_ASSERT(gb_size_of(rop64) >= sz);

	mp_err err = mp_pack(rop, sz, &written,
	                     MP_LSB_FIRST,
	                     size, endian, nails,
	                     a);
	GB_ASSERT(err == MP_OKAY);

	if (!is_type_endian_little(original_type)) {
		for (size_t i = 0; i < sz/2; i++) {
			u8 tmp = rop[i];
			rop[i] = rop[sz-1-i];
			rop[sz-1-i] = tmp;
		}
	}

	GB_ASSERT(!is_type_array(original_type));

	LLVMValueRef value = LLVMConstIntOfArbitraryPrecision(lb_type(m, original_type), cast(unsigned)((sz+7)/8), cast(u64 *)rop);
	if (big_int_is_neg(a)) {
		value = LLVMConstNeg(value);
	}

	return value;
}

gb_internal bool lb_is_nested_possibly_constant(Type *ft, Selection const &sel, Ast *elem) {
	GB_ASSERT(!sel.indirect);
	for (i32 index : sel.index) {
		Type *bt = base_type(ft);
		switch (bt->kind) {
		case Type_Struct:
			if (bt->Struct.is_raw_union) {
				return false;
			}
			ft = bt->Struct.fields[index]->type;
			break;
		case Type_Array:
			ft = bt->Array.elem;
			break;
		default:
			return false;
		}
	}


	if (is_type_raw_union(ft) || is_type_typeid(ft)) {
		return false;
	}
	return lb_is_elem_const(elem, ft);
}

gb_internal lbValue lb_const_value(lbModule *m, Type *type, ExactValue value, bool allow_local, bool is_rodata) {
	if (allow_local) {
		is_rodata = false;
	}

	LLVMContextRef ctx = m->ctx;

	type = default_type(type);
	Type *original_type = type;

	lbValue res = {};
	res.type = original_type;
	type = core_type(type);
	value = convert_exact_value_for_type(value, type);

	if (value.kind == ExactValue_Typeid) {
		return lb_typeid(m, value.value_typeid);
	}

	if (value.kind == ExactValue_Invalid) {
		return lb_const_nil(m, original_type);
	}

	if (value.kind == ExactValue_Procedure) {
		lbValue res = {};
		Ast *expr = unparen_expr(value.value_procedure);
		GB_ASSERT(expr != nullptr);
		if (expr->kind == Ast_ProcLit) {
			res = lb_generate_anonymous_proc_lit(m, str_lit("_proclit"), expr);
		} else {
			Entity *e = entity_from_expr(expr);
			res = lb_find_procedure_value_from_entity(m, e);
		}
		GB_ASSERT(res.value != nullptr);
		GB_ASSERT(LLVMGetValueKind(res.value) == LLVMFunctionValueKind);

		if (LLVMGetIntrinsicID(res.value) == 0) {
			// NOTE(bill): do not cast intrinsics as they are not really procedures that can be casted
			res.value = LLVMConstPointerCast(res.value, lb_type(m, res.type));
		}
		return res;
	}

	bool is_local = allow_local && m->curr_procedure != nullptr;

	// GB_ASSERT_MSG(is_type_typed(type), "%s", type_to_string(type));

	if (is_type_slice(type)) {
		if (value.kind == ExactValue_String) {
			GB_ASSERT(is_type_slice(type));
			res.value = lb_find_or_add_entity_string_byte_slice_with_type(m, value.value_string, original_type).value;
			return res;
		} else {
			ast_node(cl, CompoundLit, value.value_compound);

			isize count = cl->elems.count;
			if (count == 0) {
				return lb_const_nil(m, type);
			}
			count = gb_max(cast(isize)cl->max_count, count);
			Type *elem = base_type(type)->Slice.elem;
			Type *t = alloc_type_array(elem, count);
			lbValue backing_array = lb_const_value(m, t, value, allow_local, is_rodata);

			LLVMValueRef array_data = nullptr;

			if (is_local) {
				// NOTE(bill, 2020-06-08): This is a bit of a hack but a "constant" slice needs
				// its backing data on the stack
				lbProcedure *p = m->curr_procedure;
				LLVMTypeRef llvm_type = lb_type(m, t);

				array_data = llvm_alloca(p, llvm_type, 16);

				LLVMBuildStore(p->builder, backing_array.value, array_data);

				{
					LLVMValueRef indices[2] = {llvm_zero(m), llvm_zero(m)};
					LLVMValueRef ptr = LLVMBuildInBoundsGEP2(p->builder, llvm_type, array_data, indices, 2, "");
					LLVMValueRef len = LLVMConstInt(lb_type(m, t_int), count, true);

					lbAddr slice = lb_add_local_generated(p, original_type, false);
					map_set(&m->exact_value_compound_literal_addr_map, value.value_compound, slice);

					lb_fill_slice(p, slice, {ptr, alloc_type_pointer(elem)}, {len, t_int});
					return lb_addr_load(p, slice);
				}
			} else {
				isize max_len = 7+8+1;
				char *str = gb_alloc_array(permanent_allocator(), char, max_len);
				u32 id = m->gen->global_array_index.fetch_add(1);
				isize len = gb_snprintf(str, max_len, "csba$%x", id);

				String name = make_string(cast(u8 *)str, len-1);

				Entity *e = alloc_entity_constant(nullptr, make_token_ident(name), t, value);
				array_data = LLVMAddGlobal(m->mod, lb_type(m, t), str);
				LLVMSetInitializer(array_data, backing_array.value);

				if (is_rodata) {
					LLVMSetGlobalConstant(array_data, true);
				}

				lbValue g = {};
				g.value = array_data;
				g.type = t;

				lb_add_entity(m, e, g);
				lb_add_member(m, name, g);

				{
					LLVMValueRef indices[2] = {llvm_zero(m), llvm_zero(m)};
					LLVMValueRef ptr = LLVMConstInBoundsGEP2(lb_type(m, t), array_data, indices, 2);
					LLVMValueRef len = LLVMConstInt(lb_type(m, t_int), count, true);
					LLVMValueRef values[2] = {ptr, len};

					res.value = llvm_const_named_struct(m, original_type, values, 2);
					return res;
				}
			}


		}
	} else if (is_type_array(type) && value.kind == ExactValue_String && !is_type_u8(core_array_type(type))) {
		if (is_type_rune_array(type)) {
			i64 count  = type->Array.count;
			Type *elem = type->Array.elem;
			LLVMTypeRef et = lb_type(m, elem);

			Rune rune;
			isize offset = 0;
			isize width = 1;
			String s = value.value_string;

			LLVMValueRef *elems = gb_alloc_array(permanent_allocator(), LLVMValueRef, cast(isize)count);

			for (i64 i = 0; i < count && offset < s.len; i++) {
				width = utf8_decode(s.text+offset, s.len-offset, &rune);
				offset += width;

				elems[i] = LLVMConstInt(et, rune, true);

			}
			GB_ASSERT(offset == s.len);

			res.value = llvm_const_array(et, elems, cast(unsigned)count);
			return res;
		}
		// NOTE(bill, 2021-10-07): Allow for array programming value constants
		Type *core_elem = core_array_type(type);
		return lb_const_value(m, core_elem, value, allow_local, is_rodata);
	} else if (is_type_u8_array(type) && value.kind == ExactValue_String) {
		GB_ASSERT(type->Array.count == value.value_string.len);
		LLVMValueRef data = LLVMConstStringInContext(ctx,
			cast(char const *)value.value_string.text,
			cast(unsigned)value.value_string.len,
			true /*DontNullTerminate*/);
		res.value = data;
		return res;
	} else if (is_type_array(type) &&
		value.kind != ExactValue_Invalid &&
		value.kind != ExactValue_String &&
		value.kind != ExactValue_Compound) {

		i64 count  = type->Array.count;
		Type *elem = type->Array.elem;


		lbValue single_elem = lb_const_value(m, elem, value, allow_local, is_rodata);

		LLVMValueRef *elems = gb_alloc_array(permanent_allocator(), LLVMValueRef, cast(isize)count);
		for (i64 i = 0; i < count; i++) {
			elems[i] = single_elem.value;
		}

		res.value = llvm_const_array(lb_type(m, elem), elems, cast(unsigned)count);
		return res;
	} else if (is_type_matrix(type) &&
		value.kind != ExactValue_Invalid &&
		value.kind != ExactValue_Compound) {
		i64 row = type->Matrix.row_count;
		i64 column = type->Matrix.column_count;
		GB_ASSERT(row == column);
		
		Type *elem = type->Matrix.elem;
		
		lbValue single_elem = lb_const_value(m, elem, value, allow_local, is_rodata);
		single_elem.value = llvm_const_cast(single_elem.value, lb_type(m, elem));
				
		i64 total_elem_count = matrix_type_total_internal_elems(type);
		LLVMValueRef *elems = gb_alloc_array(permanent_allocator(), LLVMValueRef, cast(isize)total_elem_count);		
		for (i64 i = 0; i < row; i++) {
			elems[matrix_indices_to_offset(type, i, i)] = single_elem.value;
		}
		for (i64 i = 0; i < total_elem_count; i++) {
			if (elems[i] == nullptr) {
				elems[i] = LLVMConstNull(lb_type(m, elem));
			}
		}
		
		res.value = LLVMConstArray(lb_type(m, elem), elems, cast(unsigned)total_elem_count);
		return res;
	} else if (is_type_simd_vector(type) &&
		value.kind != ExactValue_Invalid &&
		value.kind != ExactValue_Compound) {
		i64 count = type->SimdVector.count;
		Type *elem = type->SimdVector.elem;

		lbValue single_elem = lb_const_value(m, elem, value, allow_local, is_rodata);
		single_elem.value = llvm_const_cast(single_elem.value, lb_type(m, elem));

		LLVMValueRef *elems = gb_alloc_array(permanent_allocator(), LLVMValueRef, count);
		for (i64 i = 0; i < count; i++) {
			elems[i] = single_elem.value;
		}

		res.value = LLVMConstVector(elems, cast(unsigned)count);
		return res;
	}

	switch (value.kind) {
	case ExactValue_Invalid:
		res.value = LLVMConstNull(lb_type(m, original_type));
		return res;
	case ExactValue_Bool:
		res.value = LLVMConstInt(lb_type(m, original_type), value.value_bool, false);
		return res;
	case ExactValue_String:
		{
			LLVMValueRef ptr = lb_find_or_add_entity_string_ptr(m, value.value_string);
			lbValue res = {};
			res.type = default_type(original_type);
			if (is_type_cstring(res.type)) {
				res.value = ptr;
			} else {
				if (value.value_string.len == 0) {
					ptr = LLVMConstNull(lb_type(m, t_u8_ptr));
				}
				LLVMValueRef str_len = LLVMConstInt(lb_type(m, t_int), value.value_string.len, true);
				GB_ASSERT(is_type_string(original_type));

				res.value = llvm_const_string_internal(m, original_type, ptr, str_len);
			}

			return res;
		}

	case ExactValue_Integer:
		if (is_type_pointer(type) || is_type_multi_pointer(type) || is_type_proc(type)) {
			LLVMTypeRef t = lb_type(m, original_type);
			LLVMValueRef i = lb_big_int_to_llvm(m, t_uintptr, &value.value_integer);
			res.value = LLVMConstIntToPtr(i, t);
		} else {
			res.value = lb_big_int_to_llvm(m, original_type, &value.value_integer);
		}
		return res;
	case ExactValue_Float:
		if (is_type_different_to_arch_endianness(type)) {
			if (type->Basic.kind == Basic_f32le || type->Basic.kind == Basic_f32be) {
				f32 f = static_cast<float>(value.value_float);
				u32 u = bit_cast<u32>(f);
				u = gb_endian_swap32(u);
				res.value = LLVMConstReal(lb_type(m, original_type), bit_cast<f32>(u));
			} else if (type->Basic.kind == Basic_f16le || type->Basic.kind == Basic_f16be) {
				f32 f = static_cast<float>(value.value_float);
				u16 u = f32_to_f16(f);
				u = gb_endian_swap16(u);
				res.value = LLVMConstReal(lb_type(m, original_type), f16_to_f32(u));
			} else {
				u64 u = bit_cast<u64>(value.value_float);
				u = gb_endian_swap64(u);
				res.value = LLVMConstReal(lb_type(m, original_type), bit_cast<f64>(u));
			}
		} else {
			res.value = LLVMConstReal(lb_type(m, original_type), value.value_float);
		}
		return res;
	case ExactValue_Complex:
		{
			LLVMValueRef values[2] = {};
			switch (8*type_size_of(type)) {
			case 32:
				values[0] = lb_const_f16(m, cast(f32)value.value_complex->real);
				values[1] = lb_const_f16(m, cast(f32)value.value_complex->imag);
				break;
			case 64:
				values[0] = lb_const_f32(m, cast(f32)value.value_complex->real);
				values[1] = lb_const_f32(m, cast(f32)value.value_complex->imag);
				break;
			case 128:
				values[0] = LLVMConstReal(lb_type(m, t_f64), value.value_complex->real);
				values[1] = LLVMConstReal(lb_type(m, t_f64), value.value_complex->imag);
				break;
			}

			res.value = llvm_const_named_struct(m, original_type, values, 2);
			return res;
		}
		break;
	case ExactValue_Quaternion:
		{
			LLVMValueRef values[4] = {};
			switch (8*type_size_of(type)) {
			case 64:
				// @QuaternionLayout
				values[3] = lb_const_f16(m, cast(f32)value.value_quaternion->real);
				values[0] = lb_const_f16(m, cast(f32)value.value_quaternion->imag);
				values[1] = lb_const_f16(m, cast(f32)value.value_quaternion->jmag);
				values[2] = lb_const_f16(m, cast(f32)value.value_quaternion->kmag);
				break;
			case 128:
				// @QuaternionLayout
				values[3] = lb_const_f32(m, cast(f32)value.value_quaternion->real);
				values[0] = lb_const_f32(m, cast(f32)value.value_quaternion->imag);
				values[1] = lb_const_f32(m, cast(f32)value.value_quaternion->jmag);
				values[2] = lb_const_f32(m, cast(f32)value.value_quaternion->kmag);
				break;
			case 256:
				// @QuaternionLayout
				values[3] = LLVMConstReal(lb_type(m, t_f64), value.value_quaternion->real);
				values[0] = LLVMConstReal(lb_type(m, t_f64), value.value_quaternion->imag);
				values[1] = LLVMConstReal(lb_type(m, t_f64), value.value_quaternion->jmag);
				values[2] = LLVMConstReal(lb_type(m, t_f64), value.value_quaternion->kmag);
				break;
			}

			res.value = llvm_const_named_struct(m, original_type, values, 4);
			return res;
		}
		break;

	case ExactValue_Pointer:
		res.value = LLVMConstIntToPtr(LLVMConstInt(lb_type(m, t_uintptr), value.value_pointer, false), lb_type(m, original_type));
		return res;

	case ExactValue_Compound:
		if (is_type_slice(type)) {
			return lb_const_value(m, type, value, allow_local, is_rodata);
		} else if (is_type_array(type)) {
			ast_node(cl, CompoundLit, value.value_compound);
			Type *elem_type = type->Array.elem;
			isize elem_count = cl->elems.count;
			if (elem_count == 0 || !elem_type_can_be_constant(elem_type)) {
				return lb_const_nil(m, original_type);
			}
			if (cl->elems[0]->kind == Ast_FieldValue) {
				// TODO(bill): This is O(N*M) and will be quite slow; it should probably be sorted before hand
				LLVMValueRef *values = gb_alloc_array(temporary_allocator(), LLVMValueRef, cast(isize)type->Array.count);

				isize value_index = 0;
				for (i64 i = 0; i < type->Array.count; i++) {
					bool found = false;

					for (isize j = 0; j < elem_count; j++) {
						Ast *elem = cl->elems[j];
						ast_node(fv, FieldValue, elem);
						if (is_ast_range(fv->field)) {
							ast_node(ie, BinaryExpr, fv->field);
							TypeAndValue lo_tav = ie->left->tav;
							TypeAndValue hi_tav = ie->right->tav;
							GB_ASSERT(lo_tav.mode == Addressing_Constant);
							GB_ASSERT(hi_tav.mode == Addressing_Constant);

							TokenKind op = ie->op.kind;
							i64 lo = exact_value_to_i64(lo_tav.value);
							i64 hi = exact_value_to_i64(hi_tav.value);
							if (op != Token_RangeHalf) {
								hi += 1;
							}
							if (lo == i) {
								TypeAndValue tav = fv->value->tav;
								LLVMValueRef val = lb_const_value(m, elem_type, tav.value, allow_local, is_rodata).value;
								for (i64 k = lo; k < hi; k++) {
									values[value_index++] = val;
								}

								found = true;
								i += (hi-lo-1);
								break;
							}
						} else {
							TypeAndValue index_tav = fv->field->tav;
							GB_ASSERT(index_tav.mode == Addressing_Constant);
							i64 index = exact_value_to_i64(index_tav.value);
							if (index == i) {
								TypeAndValue tav = fv->value->tav;
								LLVMValueRef val = lb_const_value(m, elem_type, tav.value, allow_local, is_rodata).value;
								values[value_index++] = val;
								found = true;
								break;
							}
						}
					}

					if (!found) {
						values[value_index++] = LLVMConstNull(lb_type(m, elem_type));
					}
				}

				res.value = lb_build_constant_array_values(m, type, elem_type, cast(isize)type->Array.count, values, allow_local, is_rodata);
				return res;
			} else {
				GB_ASSERT_MSG(elem_count == type->Array.count, "%td != %td", elem_count, type->Array.count);

				LLVMValueRef *values = gb_alloc_array(temporary_allocator(), LLVMValueRef, cast(isize)type->Array.count);

				for (isize i = 0; i < elem_count; i++) {
					TypeAndValue tav = cl->elems[i]->tav;
					GB_ASSERT(tav.mode != Addressing_Invalid);
					values[i] = lb_const_value(m, elem_type, tav.value, allow_local, is_rodata).value;
				}
				for (isize i = elem_count; i < type->Array.count; i++) {
					values[i] = LLVMConstNull(lb_type(m, elem_type));
				}

				res.value = lb_build_constant_array_values(m, type, elem_type, cast(isize)type->Array.count, values, allow_local, is_rodata);
				return res;
			}
		} else if (is_type_enumerated_array(type)) {
			ast_node(cl, CompoundLit, value.value_compound);
			Type *elem_type = type->EnumeratedArray.elem;
			isize elem_count = cl->elems.count;
			if (elem_count == 0 || !elem_type_can_be_constant(elem_type)) {
				return lb_const_nil(m, original_type);
			}
			if (cl->elems[0]->kind == Ast_FieldValue) {
				// TODO(bill): This is O(N*M) and will be quite slow; it should probably be sorted before hand
				LLVMValueRef *values = gb_alloc_array(temporary_allocator(), LLVMValueRef, cast(isize)type->EnumeratedArray.count);

				isize value_index = 0;

				i64 total_lo = exact_value_to_i64(*type->EnumeratedArray.min_value);
				i64 total_hi = exact_value_to_i64(*type->EnumeratedArray.max_value);

				for (i64 i = total_lo; i <= total_hi; i++) {
					bool found = false;

					for (isize j = 0; j < elem_count; j++) {
						Ast *elem = cl->elems[j];
						ast_node(fv, FieldValue, elem);
						if (is_ast_range(fv->field)) {
							ast_node(ie, BinaryExpr, fv->field);
							TypeAndValue lo_tav = ie->left->tav;
							TypeAndValue hi_tav = ie->right->tav;
							GB_ASSERT(lo_tav.mode == Addressing_Constant);
							GB_ASSERT(hi_tav.mode == Addressing_Constant);

							TokenKind op = ie->op.kind;
							i64 lo = exact_value_to_i64(lo_tav.value);
							i64 hi = exact_value_to_i64(hi_tav.value);
							if (op != Token_RangeHalf) {
								hi += 1;
							}
							if (lo == i) {
								TypeAndValue tav = fv->value->tav;
								LLVMValueRef val = lb_const_value(m, elem_type, tav.value, allow_local, is_rodata).value;
								for (i64 k = lo; k < hi; k++) {
									values[value_index++] = val;
								}

								found = true;
								i += (hi-lo-1);
								break;
							}
						} else {
							TypeAndValue index_tav = fv->field->tav;
							GB_ASSERT(index_tav.mode == Addressing_Constant);
							i64 index = exact_value_to_i64(index_tav.value);
							if (index == i) {
								TypeAndValue tav = fv->value->tav;
								LLVMValueRef val = lb_const_value(m, elem_type, tav.value, allow_local, is_rodata).value;
								values[value_index++] = val;
								found = true;
								break;
							}
						}
					}

					if (!found) {
						values[value_index++] = LLVMConstNull(lb_type(m, elem_type));
					}
				}

				res.value = lb_build_constant_array_values(m, type, elem_type, cast(isize)type->EnumeratedArray.count, values, allow_local, is_rodata);
				return res;
			} else {
				GB_ASSERT_MSG(elem_count == type->EnumeratedArray.count, "%td != %td", elem_count, type->EnumeratedArray.count);

				LLVMValueRef *values = gb_alloc_array(temporary_allocator(), LLVMValueRef, cast(isize)type->EnumeratedArray.count);

				for (isize i = 0; i < elem_count; i++) {
					TypeAndValue tav = cl->elems[i]->tav;
					GB_ASSERT(tav.mode != Addressing_Invalid);
					values[i] = lb_const_value(m, elem_type, tav.value, allow_local, is_rodata).value;
				}
				for (isize i = elem_count; i < type->EnumeratedArray.count; i++) {
					values[i] = LLVMConstNull(lb_type(m, elem_type));
				}

				res.value = lb_build_constant_array_values(m, type, elem_type, cast(isize)type->EnumeratedArray.count, values, allow_local, is_rodata);
				return res;
			}
		} else if (is_type_simd_vector(type)) {
			ast_node(cl, CompoundLit, value.value_compound);

			Type *elem_type = type->SimdVector.elem;
			isize elem_count = cl->elems.count;
			if (elem_count == 0) {
				return lb_const_nil(m, original_type);
			}
			GB_ASSERT(elem_type_can_be_constant(elem_type));
			isize total_elem_count = cast(isize)type->SimdVector.count;
			LLVMValueRef *values = gb_alloc_array(temporary_allocator(), LLVMValueRef, total_elem_count);

			if (cl->elems[0]->kind == Ast_FieldValue) {
				// TODO(bill): This is O(N*M) and will be quite slow; it should probably be sorted before hand
				isize value_index = 0;
				for (i64 i = 0; i < total_elem_count; i++) {
					bool found = false;

					for (isize j = 0; j < elem_count; j++) {
						Ast *elem = cl->elems[j];
						ast_node(fv, FieldValue, elem);
						if (is_ast_range(fv->field)) {
							ast_node(ie, BinaryExpr, fv->field);
							TypeAndValue lo_tav = ie->left->tav;
							TypeAndValue hi_tav = ie->right->tav;
							GB_ASSERT(lo_tav.mode == Addressing_Constant);
							GB_ASSERT(hi_tav.mode == Addressing_Constant);

							TokenKind op = ie->op.kind;
							i64 lo = exact_value_to_i64(lo_tav.value);
							i64 hi = exact_value_to_i64(hi_tav.value);
							if (op != Token_RangeHalf) {
								hi += 1;
							}
							if (lo == i) {
								TypeAndValue tav = fv->value->tav;
								LLVMValueRef val = lb_const_value(m, elem_type, tav.value, allow_local, is_rodata).value;
								for (i64 k = lo; k < hi; k++) {
									values[value_index++] = val;
								}

								found = true;
								i += (hi-lo-1);
								break;
							}
						} else {
							TypeAndValue index_tav = fv->field->tav;
							GB_ASSERT(index_tav.mode == Addressing_Constant);
							i64 index = exact_value_to_i64(index_tav.value);
							if (index == i) {
								TypeAndValue tav = fv->value->tav;
								LLVMValueRef val = lb_const_value(m, elem_type, tav.value, allow_local, is_rodata).value;
								values[value_index++] = val;
								found = true;
								break;
							}
						}
					}

					if (!found) {
						values[value_index++] = LLVMConstNull(lb_type(m, elem_type));
					}
				}

				res.value = LLVMConstVector(values, cast(unsigned)total_elem_count);
				return res;
			} else {
				for (isize i = 0; i < elem_count; i++) {
					TypeAndValue tav = cl->elems[i]->tav;
					GB_ASSERT(tav.mode != Addressing_Invalid);
					values[i] = lb_const_value(m, elem_type, tav.value, allow_local, is_rodata).value;
				}
				LLVMTypeRef et = lb_type(m, elem_type);

				for (isize i = elem_count; i < total_elem_count; i++) {
					values[i] = LLVMConstNull(et);
				}
				for (isize i = 0; i < total_elem_count; i++) {
					values[i] = llvm_const_cast(values[i], et);
				}

				res.value = LLVMConstVector(values, cast(unsigned)total_elem_count);
				return res;
			}
		} else if (is_type_struct(type)) {
			ast_node(cl, CompoundLit, value.value_compound);

			if (cl->elems.count == 0) {
				return lb_const_nil(m, original_type);
			}

			if (is_type_raw_union(type)) {
				return lb_const_nil(m, original_type);
			}
			
			LLVMTypeRef struct_type = lb_type(m, original_type);

			auto field_remapping = lb_get_struct_remapping(m, type);
			unsigned value_count = LLVMCountStructElementTypes(struct_type);
			
			LLVMValueRef *values = gb_alloc_array(temporary_allocator(), LLVMValueRef, value_count);
			bool *visited = gb_alloc_array(temporary_allocator(), bool, value_count);

			if (cl->elems[0]->kind == Ast_FieldValue) {
				isize elem_count = cl->elems.count;
				for (isize i = 0; i < elem_count; i++) {
					ast_node(fv, FieldValue, cl->elems[i]);
					String name = fv->field->Ident.token.string;

					TypeAndValue tav = fv->value->tav;
					GB_ASSERT(tav.mode != Addressing_Invalid);

					Selection sel = lookup_field(type, name, false);
					GB_ASSERT(!sel.indirect);

					Entity *f = type->Struct.fields[sel.index[0]];
					i32 index = field_remapping[f->Variable.field_index];
					if (elem_type_can_be_constant(f->type)) {
						if (sel.index.count == 1) {
							values[index]  = lb_const_value(m, f->type, tav.value, allow_local, is_rodata).value;
							visited[index] = true;
						} else {
							if (!visited[index]) {
								values[index]  = lb_const_value(m, f->type, {}, false).value;
								visited[index] = true;
							}

							unsigned idx_list_len = cast(unsigned)sel.index.count-1;
							unsigned *idx_list = gb_alloc_array(temporary_allocator(), unsigned, idx_list_len);

							if (lb_is_nested_possibly_constant(type, sel, fv->value)) {
								bool is_constant = true;
								Type *cv_type = f->type;
								for (isize j = 1; j < sel.index.count; j++) {
									i32 index = sel.index[j];
									Type *cvt = base_type(cv_type);

									if (cvt->kind == Type_Struct) {
										if (cvt->Struct.is_raw_union) {
											// sanity check which should have been caught by `lb_is_nested_possibly_constant`
											is_constant = false;
											break;
										}
										cv_type = cvt->Struct.fields[index]->type;

										if (is_type_struct(cvt)) {
											auto cv_field_remapping = lb_get_struct_remapping(m, cvt);
											unsigned remapped_index = cast(unsigned)cv_field_remapping[index];
											idx_list[j-1] = remapped_index;
										} else {
											idx_list[j-1] = cast(unsigned)index;
										}
									} else if (cvt->kind == Type_Array) {
										cv_type = cvt->Array.elem;

										idx_list[j-1] = cast(unsigned)index;
									} else {
										GB_PANIC("UNKNOWN TYPE: %s", type_to_string(cv_type));
									}
								}
								if (is_constant) {
									LLVMValueRef elem_value = lb_const_value(m, tav.type, tav.value, allow_local, is_rodata).value;
									if (LLVMIsConstant(elem_value)) {
										values[index] = llvm_const_insert_value(m, values[index], elem_value, idx_list, idx_list_len);
									} else {
										is_constant = false;
									}
								}
							}
						}
					}
				}
			} else {
				for_array(i, cl->elems) {
					Entity *f = type->Struct.fields[i];
					TypeAndValue tav = cl->elems[i]->tav;
					ExactValue val = {};
					if (tav.mode != Addressing_Invalid) {
						val = tav.value;
					}

					i32 index = field_remapping[f->Variable.field_index];
					if (elem_type_can_be_constant(f->type)) {
						values[index]  = lb_const_value(m, f->type, val, allow_local, is_rodata).value;
						visited[index] = true;
					}
				}
			}

			for (isize i = 0; i < value_count; i++) {
				if (!visited[i]) {
					GB_ASSERT(values[i] == nullptr);
					LLVMTypeRef type = LLVMStructGetTypeAtIndex(struct_type, cast(unsigned)i);
					values[i] = LLVMConstNull(type);
				}
			}

			bool is_constant = true;

			for (isize i = 0; i < value_count; i++) {
				LLVMValueRef val = values[i];
				if (!LLVMIsConstant(val)) {
					GB_ASSERT(is_local);
					GB_ASSERT(LLVMGetInstructionOpcode(val) == LLVMLoad);
					is_constant = false;
				}
			}

			if (is_constant) {
				res.value = llvm_const_named_struct_internal(struct_type, values, cast(unsigned)value_count);
				return res;
			} else {
				// TODO(bill): THIS IS HACK BUT IT WORKS FOR WHAT I NEED
				LLVMValueRef *old_values = values;
				LLVMValueRef *new_values = gb_alloc_array(temporary_allocator(), LLVMValueRef, value_count);
				for (isize i = 0; i < value_count; i++) {
					LLVMValueRef old_value = old_values[i];
					if (LLVMIsConstant(old_value)) {
						new_values[i] = old_value;
					} else {
						new_values[i] = LLVMConstNull(LLVMTypeOf(old_value));
					}
				}
				LLVMValueRef constant_value = llvm_const_named_struct_internal(struct_type, new_values, cast(unsigned)value_count);

				GB_ASSERT(is_local);
				lbProcedure *p = m->curr_procedure;
				lbAddr v = lb_add_local_generated(p, res.type, true);
				map_set(&m->exact_value_compound_literal_addr_map, value.value_compound, v);

				LLVMBuildStore(p->builder, constant_value, v.addr.value);
				for (isize i = 0; i < value_count; i++) {
					LLVMValueRef val = old_values[i];
					if (!LLVMIsConstant(val)) {
						LLVMValueRef dst = LLVMBuildStructGEP2(p->builder, llvm_addr_type(p->module, v.addr), v.addr.value, cast(unsigned)i, "");
						LLVMBuildStore(p->builder, val, dst);
					}
				}
				return lb_addr_load(p, v);
			}
		} else if (is_type_bit_set(type)) {
			ast_node(cl, CompoundLit, value.value_compound);
			if (cl->elems.count == 0) {
				return lb_const_nil(m, original_type);
			}

			i64 sz = type_size_of(type);
			if (sz == 0) {
				return lb_const_nil(m, original_type);
			}

			BigInt bits = {};
			BigInt one = {};
			big_int_from_u64(&one, 1);

			for_array(i, cl->elems) {
				Ast *e = cl->elems[i];
				GB_ASSERT(e->kind != Ast_FieldValue);

				TypeAndValue tav = e->tav;
				if (tav.mode != Addressing_Constant) {
					continue;
				}
				GB_ASSERT(tav.value.kind == ExactValue_Integer);
				i64 v = big_int_to_i64(&tav.value.value_integer);
				i64 lower = type->BitSet.lower;
				u64 index = cast(u64)(v-lower);
				BigInt bit = {};
				big_int_from_u64(&bit, index);
				big_int_shl(&bit, &one, &bit);
				big_int_or(&bits, &bits, &bit);
			}
			res.value = lb_big_int_to_llvm(m, original_type, &bits);
			return res;
		} else if (is_type_matrix(type)) {
			ast_node(cl, CompoundLit, value.value_compound);
			Type *elem_type = type->Matrix.elem;
			isize elem_count = cl->elems.count;
			if (elem_count == 0 || !elem_type_can_be_constant(elem_type)) {
				return lb_const_nil(m, original_type);
			}
			
			i64 max_count = type->Matrix.row_count*type->Matrix.column_count;
			i64 total_count = matrix_type_total_internal_elems(type);
			
			LLVMValueRef *values = gb_alloc_array(temporary_allocator(), LLVMValueRef, cast(isize)total_count);
			if (cl->elems[0]->kind == Ast_FieldValue) {
				for_array(j, cl->elems) {
					Ast *elem = cl->elems[j];
					ast_node(fv, FieldValue, elem);
					if (is_ast_range(fv->field)) {
						ast_node(ie, BinaryExpr, fv->field);
						TypeAndValue lo_tav = ie->left->tav;
						TypeAndValue hi_tav = ie->right->tav;
						GB_ASSERT(lo_tav.mode == Addressing_Constant);
						GB_ASSERT(hi_tav.mode == Addressing_Constant);

						TokenKind op = ie->op.kind;
						i64 lo = exact_value_to_i64(lo_tav.value);
						i64 hi = exact_value_to_i64(hi_tav.value);
						if (op != Token_RangeHalf) {
							hi += 1;
						}
						GB_ASSERT(0 <= lo && lo <= max_count);
						GB_ASSERT(0 <= hi && hi <= max_count);
						GB_ASSERT(lo <= hi);
						
						
						TypeAndValue tav = fv->value->tav;
						LLVMValueRef val = lb_const_value(m, elem_type, tav.value, allow_local, is_rodata).value;
						for (i64 k = lo; k < hi; k++) {
							i64 offset = matrix_row_major_index_to_offset(type, k);
							GB_ASSERT(values[offset] == nullptr);
							values[offset] = val;
						}
					} else {
						TypeAndValue index_tav = fv->field->tav;
						GB_ASSERT(index_tav.mode == Addressing_Constant);
						i64 index = exact_value_to_i64(index_tav.value);
						GB_ASSERT(index < max_count);
						TypeAndValue tav = fv->value->tav;
						LLVMValueRef val = lb_const_value(m, elem_type, tav.value, allow_local, is_rodata).value;
						i64 offset = matrix_row_major_index_to_offset(type, index);
						GB_ASSERT(values[offset] == nullptr);
						values[offset] = val;
					}
				}
				
				for (i64 i = 0; i < total_count; i++) {
					if (values[i] == nullptr) {
						values[i] = LLVMConstNull(lb_type(m, elem_type));
					}
				}

				res.value = lb_build_constant_array_values(m, type, elem_type, cast(isize)total_count, values, allow_local, is_rodata);
				return res;
			} else {
				GB_ASSERT_MSG(elem_count == max_count, "%td != %td", elem_count, max_count);

				LLVMValueRef *values = gb_alloc_array(temporary_allocator(), LLVMValueRef, cast(isize)total_count);
				for_array(i, cl->elems) {
					TypeAndValue tav = cl->elems[i]->tav;
					GB_ASSERT(tav.mode != Addressing_Invalid);
					i64 offset = 0;
					offset = matrix_row_major_index_to_offset(type, i);
					values[offset] = lb_const_value(m, elem_type, tav.value, allow_local, is_rodata).value;
				}
				for (isize i = 0; i < total_count; i++) {
					if (values[i] == nullptr) {
						values[i] = LLVMConstNull(lb_type(m, elem_type));
					}
				}

				res.value = lb_build_constant_array_values(m, type, elem_type, cast(isize)total_count, values, allow_local, is_rodata);
				return res;
			}
		} else {
			return lb_const_nil(m, original_type);
		}
		break;
	case ExactValue_Procedure:
		GB_PANIC("handled earlier");
		break;
	case ExactValue_Typeid:
		return lb_typeid(m, value.value_typeid);
	}

	return lb_const_nil(m, original_type);
}

