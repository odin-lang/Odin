gb_internal bool cg_emit_goto(cgProcedure *p, TB_Node *control_region) {
	if (tb_inst_get_control(p->func)) {
		tb_inst_goto(p->func, control_region);
		return true;
	}
	return false;
}

gb_internal TB_Node *cg_control_region(cgProcedure *p, char const *name) {
	TEMPORARY_ALLOCATOR_GUARD();

	isize n = gb_strlen(name);

	char *new_name = gb_alloc_array(temporary_allocator(), char, n+12);
	n = -1 + gb_snprintf(new_name, n+11, "%.*s_%u", cast(int)n, name, p->control_regions.count);

	TB_Node *region = tb_inst_region(p->func);
	tb_inst_set_region_name(p->func, region, n, new_name);

	GB_ASSERT(p->scope_index >= 0);
	array_add(&p->control_regions, cgControlRegion{region, p->scope_index});

	return region;
}

gb_internal cgValue cg_emit_load(cgProcedure *p, cgValue const &ptr, bool is_volatile) {
	GB_ASSERT(is_type_pointer(ptr.type));
	Type *type = type_deref(ptr.type);
	TB_DataType dt = cg_data_type(type);

	if (TB_IS_VOID_TYPE(dt)) {
		switch (ptr.kind) {
		case cgValue_Value:
			return cg_lvalue_addr(ptr.node, type);
		case cgValue_Addr:
			GB_PANIC("NOT POSSIBLE - Cannot load an lvalue to begin with");
			break;
		case cgValue_Multi:
			GB_PANIC("NOT POSSIBLE - Cannot load multiple values at once");
			break;
		case cgValue_Symbol:
			return cg_lvalue_addr(tb_inst_get_symbol_address(p->func, ptr.symbol), type);
		}
	}
	GB_ASSERT(dt.type != TB_MEMORY);
	GB_ASSERT(dt.type != TB_TUPLE);

	// use the natural alignment
	// if people need a special alignment, they can use `intrinsics.unaligned_load`
	TB_CharUnits alignment = cast(TB_CharUnits)type_align_of(type);

	TB_Node *the_ptr = nullptr;
	switch (ptr.kind) {
	case cgValue_Value:
		the_ptr = ptr.node;
		break;
	case cgValue_Addr:
		the_ptr = tb_inst_load(p->func, TB_TYPE_PTR, ptr.node, alignment, is_volatile);
		break;
	case cgValue_Multi:
		GB_PANIC("NOT POSSIBLE - Cannot load multiple values at once");
		break;
	case cgValue_Symbol:
		the_ptr = tb_inst_get_symbol_address(p->func, ptr.symbol);
		break;
	}
	return cg_value(tb_inst_load(p->func, dt, the_ptr, alignment, is_volatile), type);
}

gb_internal void cg_emit_store(cgProcedure *p, cgValue dst, cgValue src, bool is_volatile) {
	GB_ASSERT_MSG(dst.kind != cgValue_Multi, "cannot store to multiple values at once");

	if (dst.kind == cgValue_Addr) {
		dst = cg_emit_load(p, dst, is_volatile);
	} else if (dst.kind == cgValue_Symbol) {
		dst = cg_value(tb_inst_get_symbol_address(p->func, dst.symbol), dst.type);
	}

	GB_ASSERT(is_type_pointer(dst.type));
	Type *dst_type = type_deref(dst.type);

	GB_ASSERT_MSG(are_types_identical(core_type(dst_type), core_type(src.type)), "%s vs %s", type_to_string(dst_type), type_to_string(src.type));

	TB_DataType dt = cg_data_type(dst_type);
	TB_DataType st = cg_data_type(src.type);
	GB_ASSERT(dt.raw == st.raw);

	// use the natural alignment
	// if people need a special alignment, they can use `intrinsics.unaligned_store`
	TB_CharUnits alignment = cast(TB_CharUnits)type_align_of(dst_type);

	if (TB_IS_VOID_TYPE(dt)) {
		TB_Node *dst_ptr = nullptr;
		TB_Node *src_ptr = nullptr;

		switch (dst.kind) {
		case cgValue_Value:
			dst_ptr	= dst.node;
			break;
		case cgValue_Addr:
			GB_PANIC("DST cgValue_Addr should be handled above");
			break;
		case cgValue_Symbol:
			dst_ptr = tb_inst_get_symbol_address(p->func, dst.symbol);
			break;
		}

		switch (src.kind) {
		case cgValue_Value:
			GB_PANIC("SRC cgValue_Value should be handled above");
			break;
		case cgValue_Symbol:
			GB_PANIC("SRC cgValue_Symbol should be handled above");
			break;
		case cgValue_Addr:
			src_ptr = src.node;
			break;
		}

		// IMPORTANT TODO(bill): needs to be memmove
		i64 sz = type_size_of(dst_type);
		TB_Node *count = tb_inst_uint(p->func, TB_TYPE_INT, cast(u64)sz);
		tb_inst_memcpy(p->func, dst_ptr, src_ptr, count, alignment/*, is_volatile*/);
		return;
	}


	switch (dst.kind) {
	case cgValue_Value:
		switch (src.kind) {
		case cgValue_Value:
			if (src.node->dt.type == TB_INT && src.node->dt.data == 1) {
				src.node = tb_inst_zxt(p->func, src.node, dt);
			}
			tb_inst_store(p->func, dt, dst.node, src.node, alignment, is_volatile);
			return;
		case cgValue_Addr:
			tb_inst_store(p->func, dt, dst.node,
			              tb_inst_load(p->func, st, src.node, alignment, is_volatile),
			              alignment, is_volatile);
			return;
		case cgValue_Symbol:
			tb_inst_store(p->func, dt, dst.node,
			              tb_inst_get_symbol_address(p->func, src.symbol),
			              alignment, is_volatile);
			return;
		}
	case cgValue_Addr:
		GB_PANIC("cgValue_Addr should be handled above");
		break;
	case cgValue_Symbol:
		GB_PANIC(" cgValue_Symbol should be handled above");
		break;
	}
}


gb_internal cgValue cg_address_from_load(cgProcedure *p, cgValue value) {
	switch (value.kind) {
	case cgValue_Value:
		{
			TB_Node *load_inst = value.node;
			GB_ASSERT_MSG(load_inst->type == TB_LOAD, "expected a load instruction");
			TB_Node *ptr = load_inst->inputs[2];
			return cg_value(ptr, alloc_type_pointer(value.type));
		}
	case cgValue_Addr:
		return cg_value(value.node, alloc_type_pointer(value.type));
	case cgValue_Symbol:
		GB_PANIC("Symbol is an invalid use case for cg_address_from_load");
		return {};
	case cgValue_Multi:
		GB_PANIC("Multi is an invalid use case for cg_address_from_load");
		break;
	}
	GB_PANIC("Invalid cgValue for cg_address_from_load");
	return {};

}

gb_internal bool cg_addr_is_empty(cgAddr const &addr) {
	switch (addr.kind) {
	case cgValue_Value:
	case cgValue_Addr:
		return addr.addr.node == nullptr;
	case cgValue_Symbol:
		return addr.addr.symbol == nullptr;
	case cgValue_Multi:
		return addr.addr.multi == nullptr;
	}
	return true;
}

gb_internal Type *cg_addr_type(cgAddr const &addr) {
	if (cg_addr_is_empty(addr)) {
		return nullptr;
	}
	switch (addr.kind) {
	case cgAddr_Map:
		{
			Type *t = base_type(addr.map.type);
			GB_ASSERT(is_type_map(t));
			return t->Map.value;
		}
	case cgAddr_Swizzle:
		return addr.swizzle.type;
	case cgAddr_SwizzleLarge:
		return addr.swizzle_large.type;
	case cgAddr_Context:
		if (addr.ctx.sel.index.count > 0) {
			Type *t = t_context;
			for_array(i, addr.ctx.sel.index) {
				GB_ASSERT(is_type_struct(t));
				t = base_type(t)->Struct.fields[addr.ctx.sel.index[i]]->type;
			}
			return t;
		}
		break;
	}
	return type_deref(addr.addr.type);
}

gb_internal cgValue cg_addr_load(cgProcedure *p, cgAddr addr) {
	if (addr.addr.node == nullptr) {
		return {};
	}
	switch (addr.kind) {
	case cgAddr_Default:
		return cg_emit_load(p, addr.addr);

	case cgAddr_Map:
		{
			Type *map_type = base_type(type_deref(addr.addr.type));
			GB_ASSERT(map_type->kind == Type_Map);
			cgAddr v_addr = cg_add_local(p, map_type->Map.value, nullptr, true);

			cgValue ptr = cg_internal_dynamic_map_get_ptr(p, addr.addr, addr.map.key);
			cgValue ok = cg_emit_conv(p, cg_emit_comp_against_nil(p, Token_NotEq, ptr), t_bool);

			TB_Node *then = cg_control_region(p, "map.get.then");
			TB_Node *done = cg_control_region(p, "map.get.done");
			cg_emit_if(p, ok, then, done);
			tb_inst_set_control(p->func, then);
			{
				cgValue value = cg_emit_conv(p, ptr, alloc_type_pointer(map_type->Map.value));
				value = cg_emit_load(p, value);
				cg_addr_store(p, v_addr, value);
			}
			cg_emit_goto(p, done);
			tb_inst_set_control(p->func, done);

			cgValue v = cg_addr_load(p, v_addr);
			if (is_type_tuple(addr.map.result)) {
				return cg_value_multi2(v, ok, addr.map.result);
			} else {
				return v;
			}
		}

	case cgAddr_SoaVariable:
		{
			Type *t = type_deref(addr.addr.type);
			t = base_type(t);
			GB_ASSERT(t->kind == Type_Struct && t->Struct.soa_kind != StructSoa_None);
			Type *elem = t->Struct.soa_elem;

			cgValue len = {};
			if (t->Struct.soa_kind == StructSoa_Fixed) {
				len = cg_const_int(p, t_int, t->Struct.soa_count);
			} else {
				cgValue v = cg_emit_load(p, addr.addr);
				len = cg_builtin_len(p, v);
			}

			cgAddr res = cg_add_local(p, elem, nullptr, true);

			// if (addr.soa.index_expr != nullptr && (!cg_is_const(addr.soa.index) || t->Struct.soa_kind != StructSoa_Fixed)) {
			// 	cg_emit_bounds_check(p, ast_token(addr.soa.index_expr), addr.soa.index, len);
			// }

			if (t->Struct.soa_kind == StructSoa_Fixed) {
				for_array(i, t->Struct.fields) {
					Entity *field = t->Struct.fields[i];
					Type *base_type = field->type;
					GB_ASSERT(base_type->kind == Type_Array);

					cgValue dst = cg_emit_struct_ep(p, res.addr, cast(i32)i);
					cgValue src_ptr = cg_emit_struct_ep(p, addr.addr, cast(i32)i);
					src_ptr = cg_emit_array_ep(p, src_ptr, addr.soa.index);
					cgValue src = cg_emit_load(p, src_ptr);
					cg_emit_store(p, dst, src);
				}
			} else {
				isize field_count = t->Struct.fields.count;
				if (t->Struct.soa_kind == StructSoa_Slice) {
					field_count -= 1;
				} else if (t->Struct.soa_kind == StructSoa_Dynamic) {
					field_count -= 3;
				}
				for (isize i = 0; i < field_count; i++) {
					Entity *field = t->Struct.fields[i];
					Type *base_type = field->type;
					GB_ASSERT(base_type->kind == Type_Pointer);

					cgValue dst = cg_emit_struct_ep(p, res.addr, cast(i32)i);
					cgValue src_ptr = cg_emit_struct_ep(p, addr.addr, cast(i32)i);
					cgValue src = cg_emit_load(p, src_ptr);
					src = cg_emit_ptr_offset(p, src, addr.soa.index);
					src = cg_emit_load(p, src);
					cg_emit_store(p, dst, src);
				}
			}

			return cg_addr_load(p, res);
		}
	}
	GB_PANIC("TODO(bill): cg_addr_load %p", addr.addr.node);
	return {};
}


gb_internal void cg_addr_store(cgProcedure *p, cgAddr addr, cgValue value) {
	if (cg_addr_is_empty(addr)) {
		return;
	}
	GB_ASSERT(value.type != nullptr);
	if (is_type_untyped_uninit(value.type)) {
		Type *t = cg_addr_type(addr);
		value = cg_value(tb_inst_poison(p->func, cg_data_type(t)), t);
		// TODO(bill): IS THIS EVEN A GOOD IDEA?
	} else if (is_type_untyped_nil(value.type)) {
		Type *t = cg_addr_type(addr);
		value = cg_const_nil(p, t);
	}

	if (addr.kind == cgAddr_RelativePointer && addr.relative.deref) {
		addr = cg_addr(cg_address_from_load(p, cg_addr_load(p, addr)));
	}

	if (addr.kind == cgAddr_RelativePointer) {
		GB_PANIC("TODO(bill): cgAddr_RelativePointer");
	} else if (addr.kind == cgAddr_RelativeSlice) {
		GB_PANIC("TODO(bill): cgAddr_RelativeSlice");
	} else if (addr.kind == cgAddr_Map) {
		cg_internal_dynamic_map_set(p, addr.addr, addr.map.type, addr.map.key, value, p->curr_stmt);
		return;
	} else if (addr.kind == cgAddr_Context) {
		cgAddr old_addr = cg_find_or_generate_context_ptr(p);

		bool create_new = true;
		for_array(i, p->context_stack) {
			cgContextData *ctx_data = &p->context_stack[i];
			if (ctx_data->ctx.addr.node == old_addr.addr.node) {
				if (ctx_data->uses > 0) {
					create_new = true;
				} else if (p->scope_index > ctx_data->scope_index) {
					create_new = true;
				} else {
					// gb_printf_err("%.*s (curr:%td) (ctx:%td) (uses:%td)\n", LIT(p->name), p->scope_index, ctx_data->scope_index, ctx_data->uses);
					create_new = false;
				}
				break;
			}
		}

		cgValue next = {};
		if (create_new) {
			cgValue old = cg_addr_load(p, old_addr);
			cgAddr next_addr = cg_add_local(p, t_context, nullptr, true);
			cg_addr_store(p, next_addr, old);
			cg_push_context_onto_stack(p, next_addr);
			next = next_addr.addr;
		} else {
			next = old_addr.addr;
		}

		if (addr.ctx.sel.index.count > 0) {
			cgValue lhs = cg_emit_deep_field_gep(p, next, addr.ctx.sel);
			cgValue rhs = cg_emit_conv(p, value, type_deref(lhs.type));
			cg_emit_store(p, lhs, rhs);
		} else {
			cgValue lhs = next;
			cgValue rhs = cg_emit_conv(p, value, cg_addr_type(addr));
			cg_emit_store(p, lhs, rhs);
		}
		return;
	} else if (addr.kind == cgAddr_SoaVariable) {
		GB_PANIC("TODO(bill): cgAddr_SoaVariable");
	} else if (addr.kind == cgAddr_Swizzle) {
		GB_ASSERT(addr.swizzle.count <= 4);
		GB_PANIC("TODO(bill): cgAddr_Swizzle");
	} else if (addr.kind == cgAddr_SwizzleLarge) {
		GB_PANIC("TODO(bill): cgAddr_SwizzleLarge");
	}

	value = cg_emit_conv(p, value, cg_addr_type(addr));
	cg_emit_store(p, addr.addr, value);
}

gb_internal cgValue cg_addr_get_ptr(cgProcedure *p, cgAddr const &addr) {
	if (cg_addr_is_empty(addr)) {
		GB_PANIC("Illegal addr -> nullptr");
		return {};
	}

	switch (addr.kind) {
	case cgAddr_Map:
		GB_PANIC("TODO(bill): cg_addr_get_ptr cgAddr_Map");
		// return cg_internal_dynamic_map_get_ptr(p, addr.addr, addr.map.key);
		break;

	case cgAddr_RelativePointer: {
		Type *rel_ptr = base_type(cg_addr_type(addr));
		GB_ASSERT(rel_ptr->kind == Type_RelativePointer);

		cgValue ptr = cg_emit_conv(p, addr.addr, t_uintptr);
		cgValue offset = cg_emit_conv(p, ptr, alloc_type_pointer(rel_ptr->RelativePointer.base_integer));
		offset = cg_emit_load(p, offset);

		if (!is_type_unsigned(rel_ptr->RelativePointer.base_integer)) {
			offset = cg_emit_conv(p, offset, t_i64);
		}
		offset = cg_emit_conv(p, offset, t_uintptr);

		cgValue absolute_ptr = cg_emit_arith(p, Token_Add, ptr, offset, t_uintptr);
		absolute_ptr = cg_emit_conv(p, absolute_ptr, rel_ptr->RelativePointer.pointer_type);

		GB_PANIC("TODO(bill): cg_addr_get_ptr cgAddr_RelativePointer");
		// cgValue cond = cg_emit_comp(p, Token_CmpEq, offset, cg_const_nil(p->module, rel_ptr->RelativePointer.base_integer));

		// NOTE(bill): nil check
		// cgValue nil_ptr = cg_const_nil(p->module, rel_ptr->RelativePointer.pointer_type);
		// cgValue final_ptr = cg_emit_select(p, cond, nil_ptr, absolute_ptr);
		// return final_ptr;
		break;
	}

	case cgAddr_SoaVariable:
		// TODO(bill): FIX THIS HACK
		return cg_address_from_load(p, cg_addr_load(p, addr));

	case cgAddr_Context:
		GB_PANIC("cgAddr_Context should be handled elsewhere");
		break;

	case cgAddr_Swizzle:
	case cgAddr_SwizzleLarge:
		// TOOD(bill): is this good enough logic?
		break;
	}

	return addr.addr;
}

gb_internal cgValue cg_emit_ptr_offset(cgProcedure *p, cgValue ptr, cgValue index) {
	GB_ASSERT(ptr.kind == cgValue_Value);
	GB_ASSERT(index.kind == cgValue_Value);
	GB_ASSERT(is_type_pointer(ptr.type) || is_type_multi_pointer(ptr.type));
	GB_ASSERT(is_type_integer(index.type));

	Type *elem = type_deref(ptr.type, true);
	i64 stride = type_size_of(elem);
	return cg_value(tb_inst_array_access(p->func, ptr.node, index.node, stride), alloc_type_pointer(elem));
}
gb_internal cgValue cg_emit_array_ep(cgProcedure *p, cgValue s, cgValue index) {
	GB_ASSERT(s.kind == cgValue_Value);
	GB_ASSERT(index.kind == cgValue_Value);

	Type *t = s.type;
	GB_ASSERT_MSG(is_type_pointer(t), "%s", type_to_string(t));
	Type *st = base_type(type_deref(t));
	GB_ASSERT_MSG(is_type_array(st) || is_type_enumerated_array(st) || is_type_matrix(st), "%s", type_to_string(st));
	GB_ASSERT_MSG(is_type_integer(core_type(index.type)), "%s", type_to_string(index.type));


	Type *elem = base_array_type(st);
	i64 stride = type_size_of(elem);
	return cg_value(tb_inst_array_access(p->func, s.node, index.node, stride), alloc_type_pointer(elem));
}
gb_internal cgValue cg_emit_array_epi(cgProcedure *p, cgValue s, i64 index) {
	return cg_emit_array_ep(p, s, cg_const_int(p, t_int, index));
}


gb_internal cgValue cg_emit_struct_ep(cgProcedure *p, cgValue s, i64 index) {
	s = cg_flatten_value(p, s);

	GB_ASSERT(is_type_pointer(s.type));
	Type *t = base_type(type_deref(s.type));
	Type *result_type = nullptr;

	if (is_type_relative_pointer(t)) {
		s = cg_addr_get_ptr(p, cg_addr(s));
	}
	i64 offset = -1;
	i64 int_size = build_context.int_size;
	i64 ptr_size = build_context.ptr_size;

	switch (t->kind) {
	case Type_Struct:
		type_set_offsets(t);
		result_type = t->Struct.fields[index]->type;
		offset = t->Struct.offsets[index];
		break;
	case Type_Union:
		GB_ASSERT(index == -1);
		GB_PANIC("TODO(bill): cg_emit_union_tag_ptr");
		break;
		// return cg_emit_union_tag_ptr(p, s);
	case Type_Tuple:
		type_set_offsets(t);
		result_type = t->Tuple.variables[index]->type;
		offset = t->Tuple.offsets[index];
		GB_PANIC("TODO(bill): cg_emit_tuple_ep %d", s.kind);
		break;
		// return cg_emit_tuple_ep(p, s, index);
	case Type_Slice:
		switch (index) {
		case 0:
			result_type = alloc_type_multi_pointer(t->Slice.elem);
			offset = 0;
			break;
		case 1:
			result_type = t_int;
			offset = int_size;
			break;
		}
		break;
	case Type_Basic:
		switch (t->Basic.kind) {
		case Basic_string:
			switch (index) {
			case 0:
				result_type = t_u8_multi_ptr;
				offset = 0;
				break;
			case 1:
				result_type = t_int;
				offset = int_size;
				break;
			}
			break;
		case Basic_any:
			switch (index) {
			case 0:
				result_type = t_rawptr;
				offset = 0;
				break;
			case 1:
				result_type = t_typeid;
				offset = ptr_size;
				break;
			}
			break;

		case Basic_complex32:
		case Basic_complex64:
		case Basic_complex128:
			{
				Type *ft = base_complex_elem_type(t);
				i64 sz = type_size_of(ft);
				switch (index) {
				case 0: case 1:
					result_type = ft; offset = sz * index; break;
				default: goto error_case;
				}
				break;
			}
		case Basic_quaternion64:
		case Basic_quaternion128:
		case Basic_quaternion256:
			{
				Type *ft = base_complex_elem_type(t);
				i64 sz = type_size_of(ft);
				switch (index) {
				case 0: case 1: case 2: case 3:
					result_type = ft; offset = sz * index; break;
				default: goto error_case;
				}
			}
			break;
		default:
			goto error_case;
		}
		break;
	case Type_DynamicArray:
		switch (index) {
		case 0:
			result_type = alloc_type_multi_pointer(t->DynamicArray.elem);
			offset = index*int_size;
			break;
		case 1: case 2:
			result_type = t_int;
			offset = index*int_size;
			break;
		case 3:
			result_type = t_allocator;
			offset = index*int_size;
			break;
		default: goto error_case;
		}
		break;
	case Type_Map:
		{
			init_map_internal_types(t);
			Type *itp = alloc_type_pointer(t_raw_map);
			s = cg_emit_transmute(p, s, itp);

			Type *rms = base_type(t_raw_map);
			GB_ASSERT(rms->kind == Type_Struct);

			if (0 <= index && index < 3) {
				result_type = rms->Struct.fields[index]->type;
				offset = rms->Struct.offsets[index];
			} else {
				goto error_case;
			}
			break;
		}
	case Type_Array:
		return cg_emit_array_epi(p, s, index);
	case Type_SoaPointer:
		switch (index) {
		case 0:
			result_type = alloc_type_pointer(t->SoaPointer.elem);
			offset = 0;
			break;
		case 1:
			result_type = t_int;
			offset = int_size;
			break;
		}
		break;
	default:
	error_case:;
		GB_PANIC("TODO(bill): struct_gep type: %s, %lld", type_to_string(s.type), cast(long long)index);
		break;
	}

	GB_ASSERT_MSG(result_type != nullptr, "%s %lld", type_to_string(t), cast(long long)index);
	GB_ASSERT_MSG(offset >= 0, "%s %lld", type_to_string(t), cast(long long)offset);

	GB_ASSERT(s.kind == cgValue_Value);
	return cg_value(
		tb_inst_member_access(p->func, s.node, offset),
		alloc_type_pointer(result_type)
	);
}


gb_internal cgValue cg_emit_struct_ev(cgProcedure *p, cgValue s, i64 index) {
	s = cg_address_from_load_or_generate_local(p, s);
	cgValue ptr = cg_emit_struct_ep(p, s, index);
	return cg_flatten_value(p, cg_emit_load(p, ptr));
}


gb_internal cgValue cg_emit_deep_field_gep(cgProcedure *p, cgValue e, Selection const &sel) {
	GB_ASSERT(sel.index.count > 0);
	Type *type = type_deref(e.type);

	for_array(i, sel.index) {
		i64 index = sel.index[i];
		if (is_type_pointer(type)) {
			type = type_deref(type);
			e = cg_emit_load(p, e);
		}
		type = core_type(type);

		switch (type->kind) {
		case Type_SoaPointer: {
			cgValue addr = cg_emit_struct_ep(p, e, 0);
			cgValue index = cg_emit_struct_ep(p, e, 1);
			addr = cg_emit_load(p, addr);
			index = cg_emit_load(p, index);

			i64 first_index = sel.index[0];
			Selection sub_sel = sel;
			sub_sel.index.data += 1;
			sub_sel.index.count -= 1;

			cgValue arr = cg_emit_struct_ep(p, addr, first_index);

			Type *t = base_type(type_deref(addr.type));
			GB_ASSERT(is_type_soa_struct(t));

			if (t->Struct.soa_kind == StructSoa_Fixed) {
				e = cg_emit_array_ep(p, arr, index);
			} else {
				e = cg_emit_ptr_offset(p, cg_emit_load(p, arr), index);
			}
			break;
		}
		case Type_Basic:
			switch (type->Basic.kind) {
			case Basic_any:
				if (index == 0) {
					type = t_rawptr;
				} else if (index == 1) {
					type = t_type_info_ptr;
				}
				e = cg_emit_struct_ep(p, e, index);
				break;
			default:
				e = cg_emit_struct_ep(p, e, index);
				break;
			}
			break;
		case Type_Struct:
			if (type->Struct.is_raw_union) {
				type = get_struct_field_type(type, index);
				GB_ASSERT(is_type_pointer(e.type));
				e = cg_emit_transmute(p, e, alloc_type_pointer(type));
			} else {
				type = get_struct_field_type(type, index);
				e = cg_emit_struct_ep(p, e, index);
			}
			break;
		case Type_Union:
			GB_ASSERT(index == -1);
			type = t_type_info_ptr;
			e = cg_emit_struct_ep(p, e, index);
			break;
		case Type_Tuple:
			type = type->Tuple.variables[index]->type;
			e = cg_emit_struct_ep(p, e, index);
			break;
		case Type_Slice:
		case Type_DynamicArray:
		case Type_Map:
		case Type_RelativePointer:
			e = cg_emit_struct_ep(p, e, index);
			break;
		case Type_Array:
			e = cg_emit_array_epi(p, e, index);
			break;
		default:
			GB_PANIC("un-gep-able type %s", type_to_string(type));
			break;
		}
	}

	return e;
}








gb_internal cgBranchRegions cg_lookup_branch_regions(cgProcedure *p, Ast *ident) {
	GB_ASSERT(ident->kind == Ast_Ident);
	Entity *e = entity_of_node(ident);
	GB_ASSERT(e->kind == Entity_Label);
	for (cgBranchRegions const &b : p->branch_regions) {
		if (b.label == e->Label.node) {
			return b;
		}
	}

	GB_PANIC("Unreachable");
	cgBranchRegions empty = {};
	return empty;
}

gb_internal cgTargetList *cg_push_target_list(cgProcedure *p, Ast *label, TB_Node *break_, TB_Node *continue_, TB_Node *fallthrough_) {
	cgTargetList *tl = gb_alloc_item(permanent_allocator(), cgTargetList);
	tl->prev = p->target_list;
	tl->break_ = break_;
	tl->continue_ = continue_;
	tl->fallthrough_ = fallthrough_;
	p->target_list = tl;

	if (label != nullptr) { // Set label blocks
		GB_ASSERT(label->kind == Ast_Label);

		for (cgBranchRegions &b : p->branch_regions) {
			GB_ASSERT(b.label != nullptr && label != nullptr);
			GB_ASSERT(b.label->kind == Ast_Label);
			if (b.label == label) {
				b.break_    = break_;
				b.continue_ = continue_;
				return tl;
			}
		}

		GB_PANIC("Unreachable");
	}

	return tl;
}

gb_internal void cg_pop_target_list(cgProcedure *p) {
	p->target_list = p->target_list->prev;
}
gb_internal cgAddr cg_add_local(cgProcedure *p, Type *type, Entity *e, bool zero_init) {
	GB_ASSERT(type != nullptr);

	isize size = type_size_of(type);
	TB_CharUnits alignment = cast(TB_CharUnits)type_align_of(type);
	if (is_type_matrix(type)) {
		alignment *= 2; // NOTE(bill): Just in case
	}

	TB_Node *local = tb_inst_local(p->func, cast(u32)size, alignment);

	if (e != nullptr && e->token.string.len > 0 && e->token.string != "_") {
		// NOTE(bill): for debugging purposes only
		String name = e->token.string;
		TB_DebugType *debug_type = cg_debug_type(p->module, type);
		tb_function_attrib_variable(p->func, local, nullptr, name.len, cast(char const *)name.text, debug_type);
	}

	if (zero_init) {
		bool is_volatile = false;
		gb_unused(is_volatile);
		TB_Node *zero = tb_inst_uint(p->func, TB_TYPE_I8, 0);
		TB_Node *count = tb_inst_uint(p->func, TB_TYPE_I32, cast(u64)size);
		tb_inst_memset(p->func, local, zero, count, alignment/*, is_volatile*/);
	}

	cgAddr addr = cg_addr(cg_value(local, alloc_type_pointer(type)));
	if (e) {
		map_set(&p->variable_map, e, addr);
	}
	return addr;
}

gb_internal cgAddr cg_add_global(cgProcedure *p, Type *type, Entity *e) {
	GB_ASSERT(type != nullptr);

	isize size = type_size_of(type);
	TB_CharUnits alignment = cast(TB_CharUnits)type_align_of(type);
	if (is_type_matrix(type)) {
		alignment *= 2; // NOTE(bill): Just in case
	}

	TB_Global *global = tb_global_create(p->module->mod, 0, "", nullptr, TB_LINKAGE_PRIVATE);
	tb_global_set_storage(p->module->mod, tb_module_get_data(p->module->mod), global, size, alignment, 0);
	TB_Node *local = tb_inst_get_symbol_address(p->func, cast(TB_Symbol *)global);

	if (e != nullptr && e->token.string.len > 0 && e->token.string != "_") {
		// NOTE(bill): for debugging purposes only
		String name = e->token.string;
		TB_DebugType *debug_type = cg_debug_type(p->module, type);
		tb_function_attrib_variable(p->func, local, nullptr, name.len, cast(char const *)name.text, debug_type);
	}

	cgAddr addr = cg_addr(cg_value(local, alloc_type_pointer(type)));
	if (e) {
		map_set(&p->variable_map, e, addr);
	}
	return addr;
}


gb_internal cgValue cg_copy_value_to_ptr(cgProcedure *p, cgValue value, Type *original_type, isize min_alignment) {
	TB_CharUnits size  = cast(TB_CharUnits)type_size_of(original_type);
	TB_CharUnits align = cast(TB_CharUnits)gb_max(type_align_of(original_type), min_alignment);
	TB_Node *copy = tb_inst_local(p->func, size, align);
	if (value.kind == cgValue_Value) {
		tb_inst_store(p->func, cg_data_type(original_type), copy, value.node, align, false);
	} else {
		GB_ASSERT(value.kind == cgValue_Addr);
		tb_inst_memcpy(p->func, copy, value.node, tb_inst_uint(p->func, TB_TYPE_INT, size), align);
	}

	return cg_value(copy, alloc_type_pointer(original_type));
}

gb_internal cgValue cg_address_from_load_or_generate_local(cgProcedure *p, cgValue value) {
	switch (value.kind) {
	case cgValue_Value:
		if (value.node->type == TB_LOAD) {
			TB_Node *ptr = value.node->inputs[2];
			return cg_value(ptr, alloc_type_pointer(value.type));
		}
		break;
	case cgValue_Addr:
		return cg_value(value.node, alloc_type_pointer(value.type));
	case cgValue_Multi:
		GB_PANIC("cgValue_Multi not allowed");
	}

	cgAddr res = cg_add_local(p, value.type, nullptr, false);
	cg_addr_store(p, res, value);
	return res.addr;
}


gb_internal void cg_build_defer_stmt(cgProcedure *p, cgDefer const &d) {
	TB_Node *curr_region = tb_inst_get_control(p->func);
	if (curr_region == nullptr) {
		return;
	}

	// NOTE(bill): The prev block may defer injection before it's terminator
	TB_Node *last_inst = nullptr;
	// if (curr_region->input_count) {
	// 	last_inst = *(curr_region->inputs + curr_region->input_count);
	// }
	// if (last_inst && TB_IS_NODE_TERMINATOR(last_inst->type)) {
	// 	// NOTE(bill): ReturnStmt defer stuff will be handled previously
	// 	return;
	// }

	isize prev_context_stack_count = p->context_stack.count;
	GB_ASSERT(prev_context_stack_count <= p->context_stack.capacity);
	defer (p->context_stack.count = prev_context_stack_count);
	p->context_stack.count = d.context_stack_count;

	TB_Node *b = cg_control_region(p, "defer");
	if (last_inst == nullptr) {
		cg_emit_goto(p, b);
	}

	tb_inst_set_control(p->func, b);
	if (d.kind == cgDefer_Node) {
		cg_build_stmt(p, d.stmt);
	} else if (d.kind == cgDefer_Proc) {
		cg_emit_call(p, d.proc.deferred, d.proc.result_as_args);
	}
}


gb_internal void cg_emit_defer_stmts(cgProcedure *p, cgDeferExitKind kind, TB_Node *control_region) {
	isize count = p->defer_stack.count;
	isize i = count;
	while (i --> 0) {
		cgDefer const &d = p->defer_stack[i];

		if (kind == cgDeferExit_Default) {
			if (p->scope_index == d.scope_index &&
			    d.scope_index > 0) {
				cg_build_defer_stmt(p, d);
				array_pop(&p->defer_stack);
				continue;
			} else {
				break;
			}
		} else if (kind == cgDeferExit_Return) {
			cg_build_defer_stmt(p, d);
		} else if (kind == cgDeferExit_Branch) {
			GB_ASSERT(control_region != nullptr);
			isize lower_limit = -1;
			for (auto const &cr : p->control_regions) {
				if (cr.control_region == control_region) {
					lower_limit = cr.scope_index;
					break;
				}
			}
			GB_ASSERT(lower_limit >= 0);
			if (lower_limit < d.scope_index) {
				cg_build_defer_stmt(p, d);
			}
		}
	}
}

gb_internal void cg_scope_open(cgProcedure *p, Scope *scope) {
	// TODO(bill): debug scope information
	p->scope_index += 1;
	array_add(&p->scope_stack, scope);
}

gb_internal void cg_scope_close(cgProcedure *p, cgDeferExitKind kind, TB_Node *control_region) {
	cg_emit_defer_stmts(p, kind, control_region);
	GB_ASSERT(p->scope_index > 0);

	while (p->context_stack.count > 0) {
		auto *ctx = &p->context_stack[p->context_stack.count-1];
		if (ctx->scope_index < p->scope_index) {
			break;
		}
		array_pop(&p->context_stack);
	}

	p->scope_index -= 1;
	array_pop(&p->scope_stack);
}


gb_internal isize cg_append_tuple_values(cgProcedure *p, Array<cgValue> *dst_values, cgValue src_value) {
	isize init_count = dst_values->count;
	Type *t = src_value.type;
	if (t && t->kind == Type_Tuple) {
		GB_ASSERT(src_value.kind == cgValue_Multi);
		GB_ASSERT(src_value.multi != nullptr);
		GB_ASSERT(src_value.multi->values.count == t->Tuple.variables.count);
		for (cgValue const &value : src_value.multi->values) {
			array_add(dst_values, value);
		}
	} else {
		array_add(dst_values, src_value);
	}
	return dst_values->count - init_count;
}
gb_internal void cg_build_assignment(cgProcedure *p, Array<cgAddr> const &lvals, Slice<Ast *> const &values) {
	if (values.count == 0) {
		return;
	}

	auto inits = array_make<cgValue>(permanent_allocator(), 0, lvals.count);

	for (Ast *rhs : values) {
		cgValue init = cg_build_expr(p, rhs);
		cg_append_tuple_values(p, &inits, init);
	}

	bool prev_in_assignment = p->in_multi_assignment;

	isize lval_count = 0;
	for (cgAddr const &lval : lvals) {
		if (!cg_addr_is_empty(lval)) {
			// check if it is not a blank identifier
			lval_count += 1;
		}
	}
	p->in_multi_assignment = lval_count > 1;

	GB_ASSERT(lvals.count == inits.count);


	if (inits.count > 1) for_array(i, inits) {
		cgAddr lval = lvals[i];
		cgValue init = cg_flatten_value(p, inits[i]);

		GB_ASSERT(init.kind != cgValue_Multi);
		if (init.type == nullptr) {
			continue;
		}

		Type *type = cg_addr_type(lval);
		if (!cg_addr_is_empty(lval)) {
			GB_ASSERT_MSG(are_types_identical(init.type, type), "%s = %s", type_to_string(init.type), type_to_string(type));
		}

		if (init.kind == cgValue_Addr &&
		    !cg_addr_is_empty(lval)) {
			// NOTE(bill): This is needed for certain constructs such as this:
			// a, b = b, a
			// NOTE(bill): This is a bodge and not necessarily a good way of doing things whatsoever
			TB_CharUnits size  = cast(TB_CharUnits)type_size_of(type);
			TB_CharUnits align = cast(TB_CharUnits)type_align_of(type);
			TB_Node *copy = tb_inst_local(p->func, size, align);
			tb_inst_memcpy(p->func, copy, init.node, tb_inst_uint(p->func, TB_TYPE_INT, size), align);
			// use the copy instead
			init.node = copy;
		}
		inits[i] = init;
	}

	for_array(i, inits) {
		cgAddr  lval = lvals[i];
		cgValue init = inits[i];
		GB_ASSERT(init.kind != cgValue_Multi);
		if (init.type == nullptr) {
			continue;
		}
		cg_addr_store(p, lval, init);
	}

	p->in_multi_assignment = prev_in_assignment;
}

gb_internal void cg_build_assign_stmt(cgProcedure *p, AstAssignStmt *as) {
	if (as->op.kind == Token_Eq) {
		auto lvals = array_make<cgAddr>(permanent_allocator(), 0, as->lhs.count);

		for (Ast *lhs : as->lhs) {
			cgAddr lval = {};
			if (!is_blank_ident(lhs)) {
				lval = cg_build_addr(p, lhs);
			}
			array_add(&lvals, lval);
		}
		cg_build_assignment(p, lvals, as->rhs);
		return;
	}

	GB_ASSERT(as->lhs.count == 1);
	GB_ASSERT(as->rhs.count == 1);
	// NOTE(bill): Only 1 += 1 is allowed, no tuples
	// +=, -=, etc

	i32 op_ = cast(i32)as->op.kind;
	op_ += Token_Add - Token_AddEq; // Convert += to +
	TokenKind op = cast(TokenKind)op_;

	if (op == Token_CmpAnd || op == Token_CmpOr) {
		GB_PANIC("TODO(bill): cg_emit_logical_binary_expr");
		// Type *type = as->lhs[0]->tav.type;
		// cgValue new_value = cg_emit_logical_binary_expr(p, op, as->lhs[0], as->rhs[0], type);

		// cgAddr lhs = cg_build_addr(p, as->lhs[0]);
		// cg_addr_store(p, lhs, new_value);
	} else {
		cgAddr lhs = cg_build_addr(p, as->lhs[0]);
		cgValue value = cg_build_expr(p, as->rhs[0]);
		Type *lhs_type = cg_addr_type(lhs);

		// NOTE(bill): Allow for the weird edge case of:
		// array *= matrix
		if (op == Token_Mul && is_type_matrix(value.type) && is_type_array(lhs_type)) {
			GB_PANIC("TODO(bill): array *= matrix");
			// cgValue old_value = cg_addr_load(p, lhs);
			// Type *type = old_value.type;
			// cgValue new_value = cg_emit_vector_mul_matrix(p, old_value, value, type);
			// cg_addr_store(p, lhs, new_value);
			// return;
		}

		if (is_type_array(lhs_type)) {
			GB_PANIC("TODO(bill): cg_build_assign_stmt_array");
			// cg_build_assign_stmt_array(p, op, lhs, value);
			// return;
		} else {
			cgValue old_value = cg_addr_load(p, lhs);
			Type *type = old_value.type;

			cgValue change = cg_emit_conv(p, value, type);
			cgValue new_value = cg_emit_arith(p, op, old_value, change, type);
			cg_addr_store(p, lhs, new_value);
		}
	}
}

gb_internal void cg_build_return_stmt_internal_single(cgProcedure *p, cgValue result) {
	Slice<cgValue> results = {};
	results.data = &result;
	results.count = 1;
	cg_build_return_stmt_internal(p, results);
}


gb_internal void cg_build_return_stmt_internal(cgProcedure *p, Slice<cgValue> const &results) {
	TypeTuple *tuple  = &p->type->Proc.results->Tuple;
	isize return_count = p->type->Proc.result_count;

	if (return_count == 0) {
		tb_inst_ret(p->func, 0, nullptr);
		return;
	}

	if (p->split_returns_index >= 0) {
		GB_ASSERT(is_calling_convention_odin(p->type->Proc.calling_convention));

		for (isize i = 0; i < return_count-1; i++) {
			Entity *e = tuple->variables[i];
			TB_Node *ret_ptr = tb_inst_param(p->func, cast(int)(p->split_returns_index+i));
			cgValue ptr = cg_value(ret_ptr, alloc_type_pointer(e->type));
			cg_emit_store(p, ptr, results[i]);
		}

		if (p->return_by_ptr) {
			Entity *e = tuple->variables[return_count-1];
			TB_Node *ret_ptr = tb_inst_param(p->func, 0);
			cgValue ptr = cg_value(ret_ptr, alloc_type_pointer(e->type));
			cg_emit_store(p, ptr, results[return_count-1]);

			tb_inst_ret(p->func, 0, nullptr);
			return;
		} else {
			GB_ASSERT(p->proto->return_count == 1);
			TB_DataType dt = TB_PROTOTYPE_RETURNS(p->proto)->dt;

			cgValue result = results[return_count-1];
			result = cg_flatten_value(p, result);
			TB_Node *final_res = nullptr;
			if (result.kind == cgValue_Addr) {
				TB_CharUnits align = cast(TB_CharUnits)type_align_of(result.type);
				final_res = tb_inst_load(p->func, dt, result.node, align, false);
			} else {
				GB_ASSERT(result.kind == cgValue_Value);
				TB_DataType st = result.node->dt;
				GB_ASSERT(st.type == dt.type);
				if (st.raw == dt.raw) {
					final_res = result.node;
				} else if (st.type == TB_INT && st.data == 1) {
					final_res = tb_inst_zxt(p->func, result.node, dt);
				} else {
					final_res = tb_inst_bitcast(p->func, result.node, dt);
				}
			}
			GB_ASSERT(final_res != nullptr);

			tb_inst_ret(p->func, 1, &final_res);
			return;
		}

	} else {
		GB_ASSERT_MSG(!is_calling_convention_odin(p->type->Proc.calling_convention), "missing %s", proc_calling_convention_strings[p->type->Proc.calling_convention]);

		if (p->return_by_ptr) {
			Entity *e = tuple->variables[return_count-1];
			TB_Node *ret_ptr = tb_inst_param(p->func, 0);
			cgValue ptr = cg_value(ret_ptr, alloc_type_pointer(e->type));
			cg_emit_store(p, ptr, results[return_count-1]);

			tb_inst_ret(p->func, 0, nullptr);
			return;
		} else {
			GB_ASSERT(p->proto->return_count == 1);
			TB_DataType dt = TB_PROTOTYPE_RETURNS(p->proto)->dt;
			if (results.count == 1) {
				cgValue result = results[0];
				result = cg_flatten_value(p, result);

				TB_Node *final_res = nullptr;
				if (result.kind == cgValue_Addr) {
					TB_CharUnits align = cast(TB_CharUnits)type_align_of(result.type);
					final_res = tb_inst_load(p->func, dt, result.node, align, false);
				} else {
					GB_ASSERT(result.kind == cgValue_Value);
					TB_DataType st = result.node->dt;
					GB_ASSERT(st.type == dt.type);
					if (st.raw == dt.raw) {
						final_res = result.node;
					} else if (st.type == TB_INT && st.data == 1) {
						final_res = tb_inst_zxt(p->func, result.node, dt);
					} else {
						final_res = tb_inst_bitcast(p->func, result.node, dt);
					}
				}

				GB_ASSERT(final_res != nullptr);

				tb_inst_ret(p->func, 1, &final_res);
				return;
			} else {
				GB_ASSERT_MSG(results.count == 1, "TODO(bill): multi-return values for the return");
				return;
			}
		}

	}
}


gb_internal void cg_build_return_stmt(cgProcedure *p, Slice<Ast *> const &return_results) {
	TypeTuple *tuple  = &p->type->Proc.results->Tuple;
	isize return_count = p->type->Proc.result_count;

	if (return_count == 0) {
		tb_inst_ret(p->func, 0, nullptr);
		return;
	}
	TEMPORARY_ALLOCATOR_GUARD();

	auto results = array_make<cgValue>(temporary_allocator(), 0, return_count);

	if (return_results.count != 0) {
		for (isize i = 0; i < return_results.count; i++) {
			cgValue res = cg_build_expr(p, return_results[i]);
			cg_append_tuple_values(p, &results, res);
		}
	} else {
		for_array(i, tuple->variables) {
			Entity *e = tuple->variables[i];
			cgAddr addr = map_must_get(&p->variable_map, e);
			cgValue res = cg_addr_load(p, addr);
			array_add(&results, res);
		}
	}
	GB_ASSERT(results.count == return_count);

	if (return_results.count != 0 && p->type->Proc.has_named_results) {
		// NOTE(bill): store the named values before returning
		for_array(i, tuple->variables) {
			Entity *e = tuple->variables[i];
			cgAddr addr = map_must_get(&p->variable_map, e);
			cg_addr_store(p, addr, results[i]);
		}
	}
	for_array(i, tuple->variables) {
		Entity *e = tuple->variables[i];
		results[i] = cg_emit_conv(p, results[i], e->type);
	}

	cg_build_return_stmt_internal(p, slice_from_array(results));
}

gb_internal void cg_build_if_stmt(cgProcedure *p, Ast *node) {
	ast_node(is, IfStmt, node);
	cg_scope_open(p, is->scope); // Scope #1
	defer (cg_scope_close(p, cgDeferExit_Default, nullptr));

	if (is->init != nullptr) {
		TB_Node *init = cg_control_region(p, "if_init");
		cg_emit_goto(p, init);
		tb_inst_set_control(p->func, init);
		cg_build_stmt(p, is->init);
	}

	TB_Node *then  = cg_control_region(p, "if_then");
	TB_Node *done  = cg_control_region(p, "if_done");
	TB_Node *else_ = done;
	if (is->else_stmt != nullptr) {
		else_ = cg_control_region(p, "if_else");
	}

	cgValue cond = cg_build_cond(p, is->cond, then, else_);
	gb_unused(cond);

	if (is->label != nullptr) {
		cgTargetList *tl = cg_push_target_list(p, is->label, done, nullptr, nullptr);
		tl->is_block = true;
	}

	// TODO(bill): should we do a constant check?
	// Which philosophy are we following?
	// - IR represents what the code represents (probably this)
	// - IR represents what the code executes

	tb_inst_set_control(p->func, then);

	cg_build_stmt(p, is->body);

	cg_emit_goto(p, done);

	if (is->else_stmt != nullptr) {
		tb_inst_set_control(p->func, else_);

		cg_scope_open(p, scope_of_node(is->else_stmt));
		cg_build_stmt(p, is->else_stmt);
		cg_scope_close(p, cgDeferExit_Default, nullptr);

		cg_emit_goto(p, done);
	}

	tb_inst_set_control(p->func, done);
}

gb_internal void cg_build_for_stmt(cgProcedure *p, Ast *node) {
	ast_node(fs, ForStmt, node);

	cg_scope_open(p, fs->scope);
	defer (cg_scope_close(p, cgDeferExit_Default, nullptr));

	if (fs->init != nullptr) {
		TB_Node *init = cg_control_region(p, "for_init");
		cg_emit_goto(p, init);
		tb_inst_set_control(p->func, init);
		cg_build_stmt(p, fs->init);
	}
	TB_Node *body = cg_control_region(p, "for_body");
	TB_Node *done = cg_control_region(p, "for_done");
	TB_Node *loop = body;
	if (fs->cond != nullptr) {
		loop = cg_control_region(p, "for_loop");
	}
	TB_Node *post = loop;
	if (fs->post != nullptr) {
		post = cg_control_region(p, "for_post");
	}

	cg_emit_goto(p, loop);
	tb_inst_set_control(p->func, loop);

	if (loop != body) {
		cg_build_cond(p, fs->cond, body, done);
		tb_inst_set_control(p->func, body);
	}

	cg_push_target_list(p, fs->label, done, post, nullptr);
	cg_build_stmt(p, fs->body);
	cg_pop_target_list(p);

	cg_emit_goto(p, post);

	if (fs->post != nullptr) {
		tb_inst_set_control(p->func, post);
		cg_build_stmt(p, fs->post);
		cg_emit_goto(p, loop);
	}
	tb_inst_set_control(p->func, done);
}


gb_internal Ast *cg_strip_and_prefix(Ast *ident) {
	if (ident != nullptr) {
		if (ident->kind == Ast_UnaryExpr && ident->UnaryExpr.op.kind == Token_And) {
			ident = ident->UnaryExpr.expr;
		}
		GB_ASSERT(ident->kind == Ast_Ident);
	}
	return ident;
}

gb_internal void cg_emit_increment(cgProcedure *p, cgValue addr) {
	GB_ASSERT(is_type_pointer(addr.type));
	Type *type = type_deref(addr.type);
	cgValue v_one = cg_const_value(p, type, exact_value_i64(1));
	cg_emit_store(p, addr, cg_emit_arith(p, Token_Add, cg_emit_load(p, addr), v_one, type));

}

gb_internal void cg_range_stmt_store_val(cgProcedure *p, Ast *stmt_val, cgValue const &value) {
	Entity *e = entity_of_node(stmt_val);
	if (e == nullptr) {
		return;
	}

	if (e->flags & EntityFlag_Value) {
		if (value.kind == cgValue_Addr) {
			cgValue ptr = cg_address_from_load_or_generate_local(p, value);
			cg_add_entity(p->module, e, ptr);
			return;
		}
	}

	cgAddr addr = cg_add_local(p, e->type, e, false);
	cg_addr_store(p, addr, value);
	return;
}

gb_internal void cg_build_range_stmt_interval(cgProcedure *p, AstBinaryExpr *node,
                                              AstRangeStmt *rs, Scope *scope) {
	bool ADD_EXTRA_WRAPPING_CHECK = true;

	cg_scope_open(p, scope);

	Ast *val0 = rs->vals.count > 0 ? cg_strip_and_prefix(rs->vals[0]) : nullptr;
	Ast *val1 = rs->vals.count > 1 ? cg_strip_and_prefix(rs->vals[1]) : nullptr;
	Type *val0_type = nullptr;
	Type *val1_type = nullptr;
	if (val0 != nullptr && !is_blank_ident(val0)) {
		val0_type = type_of_expr(val0);
	}
	if (val1 != nullptr && !is_blank_ident(val1)) {
		val1_type = type_of_expr(val1);
	}

	TokenKind op = Token_Lt;
	switch (node->op.kind) {
	case Token_Ellipsis:  op = Token_LtEq; break;
	case Token_RangeFull: op = Token_LtEq; break;
	case Token_RangeHalf: op = Token_Lt;  break;
	default: GB_PANIC("Invalid interval operator"); break;
	}


	cgValue lower = cg_build_expr(p, node->left);
	cgValue upper = {}; // initialized each time in the loop

	cgAddr value;
	if (val0_type != nullptr) {
		value = cg_add_local(p, val0_type, entity_of_node(val0), false);
	} else {
		value = cg_add_local(p, lower.type, nullptr, false);
	}
	cg_addr_store(p, value, lower);

	cgAddr index;
	if (val1_type != nullptr) {
		index = cg_add_local(p, val1_type, entity_of_node(val1), false);
	} else {
		index = cg_add_local(p, t_int, nullptr, false);
	}
	cg_addr_store(p, index, cg_const_int(p, t_int, 0));

	TB_Node *loop = cg_control_region(p, "for_interval_loop");
	TB_Node *body = cg_control_region(p, "for_interval_body");
	TB_Node *done = cg_control_region(p, "for_interval_done");

	cg_emit_goto(p, loop);
	tb_inst_set_control(p->func, loop);

	upper = cg_build_expr(p, node->right);
	cgValue curr_value = cg_addr_load(p, value);
	cgValue cond = cg_emit_comp(p, op, curr_value, upper);
	cg_emit_if(p, cond, body, done);
	tb_inst_set_control(p->func, body);

	cgValue val = cg_addr_load(p, value);
	cgValue idx = cg_addr_load(p, index);

	if (val0_type) cg_range_stmt_store_val(p, val0, val);
	if (val1_type) cg_range_stmt_store_val(p, val1, idx);


	{
		// NOTE: this check block will most likely be optimized out, and is here
		// to make this code easier to read
		TB_Node *check = nullptr;
		TB_Node *post = cg_control_region(p, "for_interval_post");

		TB_Node *continue_block = post;

		if (ADD_EXTRA_WRAPPING_CHECK &&
		    op == Token_LtEq) {
			check = cg_control_region(p, "for_interval_check");
			continue_block = check;
		}

		cg_push_target_list(p, rs->label, done, continue_block, nullptr);

		cg_build_stmt(p, rs->body);

		cg_scope_close(p, cgDeferExit_Default, nullptr);
		cg_pop_target_list(p);

		if (check != nullptr) {
			cg_emit_goto(p, check);
			tb_inst_set_control(p->func, check);

			cgValue check_cond = cg_emit_comp(p, Token_NotEq, curr_value, upper);
			cg_emit_if(p, check_cond, post, done);
		} else {
			cg_emit_goto(p, post);
		}

		tb_inst_set_control(p->func, post);
		cg_emit_increment(p, value.addr);
		cg_emit_increment(p, index.addr);
		cg_emit_goto(p, loop);
	}

	tb_inst_set_control(p->func, done);
}

gb_internal void cg_build_range_stmt_indexed(cgProcedure *p, cgValue expr, Type *val_type, cgValue count_ptr,
                                             cgValue *val_, cgValue *idx_, TB_Node **loop_, TB_Node **done_,
                                             bool is_reverse) {
	cgValue count = {};
	Type *expr_type = base_type(type_deref(expr.type));
	switch (expr_type->kind) {
	case Type_Array:
		count = cg_const_int(p, t_int, expr_type->Array.count);
		break;
	}

	cgValue val = {};
	cgValue idx = {};
	TB_Node *loop = nullptr;
	TB_Node *done = nullptr;
	TB_Node *body = nullptr;

	loop = cg_control_region(p, "for_index_loop");
	body = cg_control_region(p, "for_index_body");
	done = cg_control_region(p, "for_index_done");

	cgAddr index = cg_add_local(p, t_int, nullptr, false);

	if (!is_reverse) {
		/*
			for x, i in array {
				...
			}

			i := -1
			for {
				i += 1
				if !(i < len(array)) {
					break
				}
				#no_bounds_check x := array[i]
				...
			}
		*/

		cg_addr_store(p, index, cg_const_int(p, t_int, cast(u64)-1));

		cg_emit_goto(p, loop);
		tb_inst_set_control(p->func, loop);

		cgValue incr = cg_emit_arith(p, Token_Add, cg_addr_load(p, index), cg_const_int(p, t_int, 1), t_int);
		cg_addr_store(p, index, incr);

		if (count.node == nullptr) {
			GB_ASSERT(count_ptr.node != nullptr);
			count = cg_emit_load(p, count_ptr);
		}
		cgValue cond = cg_emit_comp(p, Token_Lt, incr, count);
		cg_emit_if(p, cond, body, done);
	} else {
		// NOTE(bill): REVERSED LOGIC
		/*
			#reverse for x, i in array {
				...
			}

			i := len(array)
			for {
				i -= 1
				if i < 0 {
					break
				}
				#no_bounds_check x := array[i]
				...
			}
		*/

		if (count.node == nullptr) {
			GB_ASSERT(count_ptr.node != nullptr);
			count = cg_emit_load(p, count_ptr);
		}
		count = cg_emit_conv(p, count, t_int);
		cg_addr_store(p, index, count);

		cg_emit_goto(p, loop);
		tb_inst_set_control(p->func, loop);

		cgValue incr = cg_emit_arith(p, Token_Sub, cg_addr_load(p, index), cg_const_int(p, t_int, 1), t_int);
		cg_addr_store(p, index, incr);

		cgValue anti_cond = cg_emit_comp(p, Token_Lt, incr, cg_const_int(p, t_int, 0));
		cg_emit_if(p, anti_cond, done, body);
	}

	tb_inst_set_control(p->func, body);

	idx = cg_addr_load(p, index);
	switch (expr_type->kind) {
	case Type_Array: {
		if (val_type != nullptr) {
			val = cg_emit_load(p, cg_emit_array_ep(p, expr, idx));
		}
		break;
	}
	case Type_EnumeratedArray: {
		if (val_type != nullptr) {
			val = cg_emit_load(p, cg_emit_array_ep(p, expr, idx));
			// NOTE(bill): Override the idx value for the enumeration
			Type *index_type = expr_type->EnumeratedArray.index;
			if (compare_exact_values(Token_NotEq, *expr_type->EnumeratedArray.min_value, exact_value_u64(0))) {
				idx = cg_emit_arith(p, Token_Add, idx, cg_const_value(p, index_type, *expr_type->EnumeratedArray.min_value), index_type);
			}
		}
		break;
	}
	case Type_Slice: {
		if (val_type != nullptr) {
			cgValue elem = cg_builtin_raw_data(p, expr);
			val = cg_emit_load(p, cg_emit_ptr_offset(p, elem, idx));
		}
		break;
	}
	case Type_DynamicArray: {
		if (val_type != nullptr) {
			cgValue elem = cg_emit_struct_ep(p, expr, 0);
			elem = cg_emit_load(p, elem);
			val = cg_emit_load(p, cg_emit_ptr_offset(p, elem, idx));
		}
		break;
	}
	case Type_Struct: {
		GB_ASSERT(is_type_soa_struct(expr_type));
		break;
	}

	default:
		GB_PANIC("Cannot do range_indexed of %s", type_to_string(expr_type));
		break;
	}

	if (val_)  *val_  = val;
	if (idx_)  *idx_  = idx;
	if (loop_) *loop_ = loop;
	if (done_) *done_ = done;

}

gb_internal void cg_build_range_stmt_enum(cgProcedure *p, Type *enum_type, Type *val_type, cgValue *val_, cgValue *idx_, TB_Node **loop_, TB_Node **done_) {
	Type *t = enum_type;
	GB_ASSERT(is_type_enum(t));
	t = base_type(t);
	Type *core_elem = core_type(t);
	GB_ASSERT(t->kind == Type_Enum);
	i64 enum_count = t->Enum.fields.count;
	cgValue max_count = cg_const_int(p, t_int, enum_count);

	cgValue ti          = cg_type_info(p, t);
	cgValue variant     = cg_emit_struct_ep(p, ti, 4);
	cgValue eti_ptr     = cg_emit_conv(p, variant, t_type_info_enum_ptr);
	cgValue values      = cg_emit_load(p, cg_emit_struct_ep(p, eti_ptr, 2));
	cgValue values_data = cg_builtin_raw_data(p, values);

	cgAddr offset_ = cg_add_local(p, t_int, nullptr, false);
	cg_addr_store(p, offset_, cg_const_int(p, t_int, 0));

	TB_Node *loop = cg_control_region(p, "for_enum_loop");
	cg_emit_goto(p, loop);
	tb_inst_set_control(p->func, loop);

	TB_Node *body = cg_control_region(p, "for_enum_body");
	TB_Node *done = cg_control_region(p, "for_enum_done");

	cgValue offset = cg_addr_load(p, offset_);
	cgValue cond = cg_emit_comp(p, Token_Lt, offset, max_count);
	cg_emit_if(p, cond, body, done);
	tb_inst_set_control(p->func, body);

	cgValue val_ptr = cg_emit_ptr_offset(p, values_data, offset);
	cg_emit_increment(p, offset_.addr);

	cgValue val = {};
	if (val_type != nullptr) {
		GB_ASSERT(are_types_identical(enum_type, val_type));

		if (is_type_integer(core_elem)) {
			cgValue i = cg_emit_load(p, cg_emit_conv(p, val_ptr, t_i64_ptr));
			val = cg_emit_conv(p, i, t);
		} else {
			GB_PANIC("TODO(bill): enum core type %s", type_to_string(core_elem));
		}
	}

	if (val_)  *val_  = val;
	if (idx_)  *idx_  = offset;
	if (loop_) *loop_ = loop;
	if (done_) *done_ = done;
}

gb_internal void cg_build_range_stmt_struct_soa(cgProcedure *p, AstRangeStmt *rs, Scope *scope) {
	Ast *expr = unparen_expr(rs->expr);
	TypeAndValue tav = type_and_value_of_expr(expr);

	TB_Node *loop = nullptr;
	TB_Node *body = nullptr;
	TB_Node *done = nullptr;

	bool is_reverse = rs->reverse;

	cg_scope_open(p, scope);

	Ast *val0 = rs->vals.count > 0 ? cg_strip_and_prefix(rs->vals[0]) : nullptr;
	Ast *val1 = rs->vals.count > 1 ? cg_strip_and_prefix(rs->vals[1]) : nullptr;
	Type *val_types[2] = {};
	if (val0 != nullptr && !is_blank_ident(val0)) {
		val_types[0] = type_of_expr(val0);
	}
	if (val1 != nullptr && !is_blank_ident(val1)) {
		val_types[1] = type_of_expr(val1);
	}

	cgAddr array = cg_build_addr(p, expr);
	if (is_type_pointer(cg_addr_type(array))) {
		array = cg_addr(cg_addr_load(p, array));
	}
	cgValue count = cg_builtin_len(p, cg_addr_load(p, array));


	cgAddr index = cg_add_local(p, t_int, nullptr, false);

	if (!is_reverse) {
		/*
			for x, i in array {
				...
			}

			i := -1
			for {
				i += 1
				if !(i < len(array)) {
					break
				}
				x := array[i] // but #soa-ified
				...
			}
		*/

		cg_addr_store(p, index, cg_const_int(p, t_int, cast(u64)-1));

		loop = cg_control_region(p, "for_soa_loop");
		cg_emit_goto(p, loop);
		tb_inst_set_control(p->func, loop);

		cgValue incr = cg_emit_arith(p, Token_Add, cg_addr_load(p, index), cg_const_int(p, t_int, 1), t_int);
		cg_addr_store(p, index, incr);

		body = cg_control_region(p, "for_soa_body");
		done = cg_control_region(p, "for_soa_done");

		cgValue cond = cg_emit_comp(p, Token_Lt, incr, count);
		cg_emit_if(p, cond, body, done);
	} else {
		// NOTE(bill): REVERSED LOGIC
		/*
			#reverse for x, i in array {
				...
			}

			i := len(array)
			for {
				i -= 1
				if i < 0 {
					break
				}
				#no_bounds_check x := array[i] // but #soa-ified
				...
			}
		*/
		cg_addr_store(p, index, count);

		loop = cg_control_region(p, "for_soa_loop");
		cg_emit_goto(p, loop);
		tb_inst_set_control(p->func, loop);

		cgValue incr = cg_emit_arith(p, Token_Sub, cg_addr_load(p, index), cg_const_int(p, t_int, 1), t_int);
		cg_addr_store(p, index, incr);

		body = cg_control_region(p, "for_soa_body");
		done = cg_control_region(p, "for_soa_done");

		cgValue cond = cg_emit_comp(p, Token_Lt, incr, cg_const_int(p, t_int, 0));
		cg_emit_if(p, cond, done, body);
	}
	tb_inst_set_control(p->func, body);


	if (val_types[0]) {
		Entity *e = entity_of_node(val0);
		if (e != nullptr) {
			cgAddr soa_val = cg_addr_soa_variable(array.addr, cg_addr_load(p, index), nullptr);
			map_set(&p->soa_values_map, e, soa_val);
		}
	}
	if (val_types[1]) {
		cg_range_stmt_store_val(p, val1, cg_addr_load(p, index));
	}


	cg_push_target_list(p, rs->label, done, loop, nullptr);

	cg_build_stmt(p, rs->body);

	cg_scope_close(p, cgDeferExit_Default, nullptr);
	cg_pop_target_list(p);
	cg_emit_goto(p, loop);
	tb_inst_set_control(p->func, done);

}


gb_internal void cg_build_range_stmt(cgProcedure *p, Ast *node) {
	ast_node(rs, RangeStmt, node);

	Ast *expr = unparen_expr(rs->expr);

	if (is_ast_range(expr)) {
		cg_build_range_stmt_interval(p, &expr->BinaryExpr, rs, rs->scope);
		return;
	}

	Type *expr_type = type_of_expr(expr);
	if (expr_type != nullptr) {
		Type *et = base_type(type_deref(expr_type));
	 	if (is_type_soa_struct(et)) {
			cg_build_range_stmt_struct_soa(p, rs, rs->scope);
			return;
		}
	}

	cg_scope_open(p, rs->scope);


	Ast *val0 = rs->vals.count > 0 ? cg_strip_and_prefix(rs->vals[0]) : nullptr;
	Ast *val1 = rs->vals.count > 1 ? cg_strip_and_prefix(rs->vals[1]) : nullptr;
	Type *val0_type = nullptr;
	Type *val1_type = nullptr;
	if (val0 != nullptr && !is_blank_ident(val0)) {
		val0_type = type_of_expr(val0);
	}
	if (val1 != nullptr && !is_blank_ident(val1)) {
		val1_type = type_of_expr(val1);
	}

	cgValue val = {};
	cgValue key = {};
	TB_Node *loop = nullptr;
	TB_Node *done = nullptr;
	bool is_map = false;
	TypeAndValue tav = type_and_value_of_expr(expr);

	if (tav.mode == Addressing_Type) {
		cg_build_range_stmt_enum(p, type_deref(tav.type), val0_type, &val, &key, &loop, &done);
	} else {
		Type *expr_type = type_of_expr(expr);
		Type *et = base_type(type_deref(expr_type));
		switch (et->kind) {
		case Type_Map: {
			is_map = true;
			cgValue map = cg_build_addr_ptr(p, expr);
			if (is_type_pointer(type_deref(map.type))) {
				map = cg_emit_load(p, map);
			}
			GB_PANIC("TODO(bill): cg_build_range_map");
			// cg_build_range_map(p, map, val1_type, &val, &key, &loop, &done);
			break;
		}
		case Type_Array: {
			cgValue array = cg_build_addr_ptr(p, expr);
			if (is_type_pointer(type_deref(array.type))) {
				array = cg_emit_load(p, array);
			}
			cgAddr count_ptr = cg_add_local(p, t_int, nullptr, false);
			cg_addr_store(p, count_ptr, cg_const_int(p, t_int, et->Array.count));
			cg_build_range_stmt_indexed(p, array, val0_type, count_ptr.addr, &val, &key, &loop, &done, rs->reverse);
			break;
		}
		case Type_EnumeratedArray: {
			cgValue array = cg_build_addr_ptr(p, expr);
			if (is_type_pointer(type_deref(array.type))) {
				array = cg_emit_load(p, array);
			}
			cgAddr count_ptr = cg_add_local(p, t_int, nullptr, false);
			cg_addr_store(p, count_ptr, cg_const_int(p, t_int, et->EnumeratedArray.count));
			cg_build_range_stmt_indexed(p, array, val0_type, count_ptr.addr, &val, &key, &loop, &done, rs->reverse);
			break;
		}
		case Type_DynamicArray: {
			cgValue count_ptr = {};
			cgValue array = cg_build_addr_ptr(p, expr);
			if (is_type_pointer(type_deref(array.type))) {
				array = cg_emit_load(p, array);
			}
			count_ptr = cg_emit_struct_ep(p, array, 1);
			cg_build_range_stmt_indexed(p, array, val0_type, count_ptr, &val, &key, &loop, &done, rs->reverse);
			break;
		}
		case Type_Slice: {
			cgValue count_ptr = {};
			cgValue slice = cg_build_expr(p, expr);
			if (is_type_pointer(slice.type)) {
				count_ptr = cg_emit_struct_ep(p, slice, 1);
				slice = cg_emit_load(p, slice);
			} else {
				count_ptr = cg_add_local(p, t_int, nullptr, false).addr;
				cg_emit_store(p, count_ptr, cg_builtin_len(p, slice));
			}
			cg_build_range_stmt_indexed(p, slice, val0_type, count_ptr, &val, &key, &loop, &done, rs->reverse);
			break;
		}
		case Type_Basic: {
			cgValue string = cg_build_expr(p, expr);
			if (is_type_pointer(string.type)) {
				string = cg_emit_load(p, string);
			}
			if (is_type_untyped(expr_type)) {
				cgAddr s = cg_add_local(p, default_type(string.type), nullptr, false);
				cg_addr_store(p, s, string);
				string = cg_addr_load(p, s);
			}
			Type *t = base_type(string.type);
			GB_ASSERT(!is_type_cstring(t));
			GB_PANIC("TODO(bill): cg_build_range_string");
			// cg_build_range_string(p, string, val0_type, &val, &key, &loop, &done, rs->reverse);
			break;
		}
		case Type_Tuple:
			GB_PANIC("TODO(bill): cg_build_range_tuple");
			// cg_build_range_tuple(p, expr, val0_type, val1_type, &val, &key, &loop, &done);
			break;
		default:
			GB_PANIC("Cannot range over %s", type_to_string(expr_type));
			break;
		}
	}

	if (is_map) {
		if (val0_type) cg_range_stmt_store_val(p, val0, key);
		if (val1_type) cg_range_stmt_store_val(p, val1, val);
	} else {
		if (val0_type) cg_range_stmt_store_val(p, val0, val);
		if (val1_type) cg_range_stmt_store_val(p, val1, key);
	}

	cg_push_target_list(p, rs->label, done, loop, nullptr);

	cg_build_stmt(p, rs->body);

	cg_scope_close(p, cgDeferExit_Default, nullptr);
	cg_pop_target_list(p);
	cg_emit_goto(p, loop);
	tb_inst_set_control(p->func, done);
}

gb_internal bool cg_switch_stmt_can_be_trivial_jump_table(AstSwitchStmt *ss) {
	if (ss->tag == nullptr) {
		return false;
	}
	bool is_typeid = false;
	TypeAndValue tv = type_and_value_of_expr(ss->tag);
	if (is_type_integer(core_type(tv.type))) {
		if (type_size_of(tv.type) > 8) {
			return false;
		}
		// okay
	} else if (is_type_typeid(tv.type)) {
		// okay
		is_typeid = true;
	} else {
		return false;
	}

	ast_node(body, BlockStmt, ss->body);
	for (Ast *clause : body->stmts) {
		ast_node(cc, CaseClause, clause);

		if (cc->list.count == 0) {
			continue;
		}

		for (Ast *expr : cc->list) {
			expr = unparen_expr(expr);
			if (is_ast_range(expr)) {
				return false;
			}
			if (expr->tav.mode == Addressing_Type) {
				GB_ASSERT(is_typeid);
				continue;
			}
			tv = type_and_value_of_expr(expr);
			if (tv.mode != Addressing_Constant) {
				return false;
			}
			if (!is_type_integer(core_type(tv.type))) {
				return false;
			}
		}

	}

	return true;
}


gb_internal void cg_build_switch_stmt(cgProcedure *p, Ast *node) {
	ast_node(ss, SwitchStmt, node);
	cg_scope_open(p, ss->scope);

	if (ss->init != nullptr) {
		cg_build_stmt(p, ss->init);
	}
	cgValue tag = {};
	if (ss->tag != nullptr) {
		tag = cg_build_expr(p, ss->tag);
	} else {
		tag = cg_const_bool(p, t_bool, true);
	}

	TB_Node *done = cg_control_region(p, "switch_done");

	ast_node(body, BlockStmt, ss->body);

	isize case_count = body->stmts.count;
	Slice<Ast *> default_stmts = {};
	TB_Node *default_fall  = nullptr;
	TB_Node *default_block = nullptr;
	Scope *  default_scope = nullptr;
	TB_Node *fall = nullptr;


	auto body_regions = slice_make<TB_Node *>(permanent_allocator(), body->stmts.count);
	auto body_scopes = slice_make<Scope *>(permanent_allocator(), body->stmts.count);
	for_array(i, body->stmts) {
		Ast *clause = body->stmts[i];
		ast_node(cc, CaseClause, clause);

		body_regions[i] = cg_control_region(p, cc->list.count == 0 ? "switch_default_body" : "switch_case_body");
		body_scopes[i] = cc->scope;
		if (cc->list.count == 0) {
			default_block = body_regions[i];
			default_scope = cc->scope;
		}
	}

	bool is_trivial = cg_switch_stmt_can_be_trivial_jump_table(ss);
	if (is_trivial) {
		isize key_count = 0;
		for (Ast *clause : body->stmts) {
			ast_node(cc, CaseClause, clause);
			key_count += cc->list.count;
		}
		TB_SwitchEntry *keys = gb_alloc_array(temporary_allocator(), TB_SwitchEntry, key_count);
		isize key_index = 0;
		for_array(i, body->stmts) {
			Ast *clause = body->stmts[i];
			ast_node(cc, CaseClause, clause);

			TB_Node *region = body_regions[i];
			for (Ast *expr : cc->list) {
				i64 key = 0;
				expr = unparen_expr(expr);
				GB_ASSERT(!is_ast_range(expr));
				if (expr->tav.mode == Addressing_Type) {
					Type *type = expr->tav.value.value_typeid;
					if (type == nullptr || type == t_invalid) {
						type = expr->tav.type;
					}
					key = cg_typeid_as_u64(p->module, type);
				} else {
					auto tv = type_and_value_of_expr(expr);
					GB_ASSERT(tv.mode == Addressing_Constant);
					key = exact_value_to_i64(tv.value);
				}
				keys[key_index++] = {key, region};
			}
		}
		GB_ASSERT(key_index == key_count);

		TB_Node *end_block = done;
		if (default_block) {
			end_block = default_block;
		}

		TB_DataType dt = cg_data_type(tag.type);
		GB_ASSERT(tag.kind == cgValue_Value);
		GB_ASSERT(!TB_IS_VOID_TYPE(dt));

		tb_inst_branch(p->func, dt, tag.node, end_block, key_count, keys);
	}

	for_array(i, body->stmts) {
		Ast *clause = body->stmts[i];
		ast_node(cc, CaseClause, clause);

		TB_Node *body_region = body_regions[i];
		Scope *body_scope = body_scopes[i];
		fall = done;
		if (i+1 < case_count) {
			fall = body_regions[i+1];
		}

		if (cc->list.count == 0) {
			// default case
			default_stmts = cc->stmts;
			default_fall  = fall;
			GB_ASSERT(default_block == body_region);
			continue;
		}

		TB_Node *next_cond = nullptr;
		if (!is_trivial) for (Ast *expr : cc->list) {
			expr = unparen_expr(expr);

			next_cond = cg_control_region(p, "switch_case_next");

			cgValue cond = {};
			if (is_ast_range(expr)) {
				ast_node(ie, BinaryExpr, expr);
				TokenKind op = Token_Invalid;
				switch (ie->op.kind) {
				case Token_Ellipsis:  op = Token_LtEq; break;
				case Token_RangeFull: op = Token_LtEq; break;
				case Token_RangeHalf: op = Token_Lt;   break;
				default: GB_PANIC("Invalid interval operator"); break;
				}
				cgValue lhs = cg_build_expr(p, ie->left);
				cgValue rhs = cg_build_expr(p, ie->right);

				cgValue cond_lhs = cg_emit_comp(p, Token_LtEq, lhs, tag);
				cgValue cond_rhs = cg_emit_comp(p, op, tag, rhs);
				cond = cg_emit_arith(p, Token_And, cond_lhs, cond_rhs, t_bool);
			} else {
				if (expr->tav.mode == Addressing_Type) {
					GB_ASSERT(is_type_typeid(tag.type));
					cgValue e = cg_typeid(p, expr->tav.type);
					e = cg_emit_conv(p, e, tag.type);
					cond = cg_emit_comp(p, Token_CmpEq, tag, e);
				} else {
					cond = cg_emit_comp(p, Token_CmpEq, tag, cg_build_expr(p, expr));
				}
			}

			GB_ASSERT(cond.kind == cgValue_Value);
			tb_inst_if(p->func, cond.node, body_region, next_cond);
			tb_inst_set_control(p->func, next_cond);
		}

		tb_inst_set_control(p->func, body_region);

		cg_push_target_list(p, ss->label, done, nullptr, fall);
		cg_scope_open(p, body_scope);
		cg_build_stmt_list(p, cc->stmts);
		cg_scope_close(p, cgDeferExit_Default, body_region);
		cg_pop_target_list(p);

		cg_emit_goto(p, done);
		tb_inst_set_control(p->func, next_cond);
	}

	if (default_block != nullptr) {
		if (!is_trivial) {
			cg_emit_goto(p, default_block);
		}
		tb_inst_set_control(p->func, default_block);

		cg_push_target_list(p, ss->label, done, nullptr, default_fall);
		cg_scope_open(p, default_scope);
		cg_build_stmt_list(p, default_stmts);
		cg_scope_close(p, cgDeferExit_Default, default_block);
		cg_pop_target_list(p);
	}


	cg_emit_goto(p, done);
	tb_inst_set_control(p->func, done);

	cg_scope_close(p, cgDeferExit_Default, done);
}

gb_internal void cg_build_type_switch_stmt(cgProcedure *p, Ast *node) {
	ast_node(ss, TypeSwitchStmt, node);

	TB_Node *done_region = cg_control_region(p, "typeswitch_done");
	TB_Node *else_region = done_region;
	TB_Node *default_region = nullptr;
	isize num_cases = 0;

	cg_scope_open(p, ss->scope);
	defer (cg_scope_close(p, cgDeferExit_Default, done_region));

	ast_node(as, AssignStmt, ss->tag);
	GB_ASSERT(as->lhs.count == 1);
	GB_ASSERT(as->rhs.count == 1);

	cgValue parent = cg_build_expr(p, as->rhs[0]);
	bool is_parent_ptr = is_type_pointer(parent.type);
	Type *parent_base_type = type_deref(parent.type);
	gb_unused(parent_base_type);

	TypeSwitchKind switch_kind = check_valid_type_switch_type(parent.type);
	GB_ASSERT(switch_kind != TypeSwitch_Invalid);


	cgValue parent_value = parent;

	cgValue parent_ptr = parent;
	if (!is_parent_ptr) {
		parent_ptr = cg_address_from_load_or_generate_local(p, parent);
	}

	cgValue tag = {};
	cgValue union_data = {};
	if (switch_kind == TypeSwitch_Union) {
		union_data = cg_emit_conv(p, parent_ptr, t_rawptr);
		Type *union_type = type_deref(parent_ptr.type);
		if (is_type_union_maybe_pointer(union_type)) {
			tag = cg_emit_conv(p, cg_emit_comp_against_nil(p, Token_NotEq, union_data), t_int);
		} else if (union_tag_size(union_type) == 0) {
			tag = {}; // there is no tag for a zero sized union
		} else {
			cgValue tag_ptr = cg_emit_union_tag_ptr(p, parent_ptr);
			tag = cg_emit_load(p, tag_ptr);
		}
	} else if (switch_kind == TypeSwitch_Any) {
		tag = cg_emit_load(p, cg_emit_struct_ep(p, parent_ptr, 1));
	} else {
		GB_PANIC("Unknown switch kind");
	}

	ast_node(body, BlockStmt, ss->body);

	for (Ast *clause : body->stmts) {
		ast_node(cc, CaseClause, clause);
		num_cases += cc->list.count;
		if (cc->list.count == 0) {
			GB_ASSERT(default_region == nullptr);
			default_region = cg_control_region(p, "typeswitch_default_body");
			else_region = default_region;
		}
	}

	bool all_by_reference = false;
	for (Ast *clause : body->stmts) {
		ast_node(cc, CaseClause, clause);
		if (cc->list.count != 1) {
			continue;
		}
		Entity *case_entity = implicit_entity_of_node(clause);
		all_by_reference |= (case_entity->flags & EntityFlag_Value) == 0;
		break;
	}

	TB_Node *backing_ptr = nullptr;
	if (!all_by_reference) {
		bool variants_found = false;
		i64 max_size = 0;
		i64 max_align = 1;
		for (Ast *clause : body->stmts) {
			ast_node(cc, CaseClause, clause);
			if (cc->list.count != 1) {
				continue;
			}
			Entity *case_entity = implicit_entity_of_node(clause);
			if (!is_type_untyped_nil(case_entity->type)) {
				max_size = gb_max(max_size, type_size_of(case_entity->type));
				max_align = gb_max(max_align, type_align_of(case_entity->type));
				variants_found = true;
			}
		}
		if (variants_found) {
			backing_ptr = tb_inst_local(p->func, cast(TB_CharUnits)max_size, cast(TB_CharUnits)max_align);
		}
	}

	TEMPORARY_ALLOCATOR_GUARD();
	TB_Node **control_regions = gb_alloc_array(temporary_allocator(), TB_Node *, body->stmts.count);
	TB_SwitchEntry *switch_entries = gb_alloc_array(temporary_allocator(), TB_SwitchEntry, num_cases);

	isize case_index = 0;
	for_array(i, body->stmts) {
		Ast *clause = body->stmts[i];
		ast_node(cc, CaseClause, clause);
		if (cc->list.count == 0) {
			control_regions[i] = default_region;
			continue;
		}

		TB_Node *region = cg_control_region(p, "typeswitch_body");
		control_regions[i] = region;

		for (Ast *type_expr : cc->list) {
			Type *case_type = type_of_expr(type_expr);
			i64 key = -1;
			if (switch_kind == TypeSwitch_Union) {
				Type *ut = base_type(type_deref(parent.type));
				if (is_type_untyped_nil(case_type)) {
					key = 0;
				} else {
					key = union_variant_index(ut, case_type);
				}
			} else if (switch_kind == TypeSwitch_Any) {
				if (is_type_untyped_nil(case_type)) {
					key = 0;
				} else {
					key = cast(i64)cg_typeid_as_u64(p->module, case_type);
				}
			}
			GB_ASSERT(key >= 0);

			switch_entries[case_index++] = TB_SwitchEntry{key, region};
		}
	}

	GB_ASSERT(case_index == num_cases);

	{
		TB_DataType dt = {};
		TB_Node *key = nullptr;
		if (type_size_of(parent_base_type) == 0) {
			GB_ASSERT(tag.node == nullptr);
			key = tb_inst_bool(p->func, false);
			dt = cg_data_type(t_bool);
		} else {
			GB_ASSERT(tag.kind == cgValue_Value && tag.node != nullptr);
			dt = cg_data_type(tag.type);
			key = tag.node;
		}

		GB_ASSERT(!TB_IS_VOID_TYPE(dt));
		tb_inst_branch(p->func, dt, key, else_region, num_cases, switch_entries);
	}


	for_array(i, body->stmts) {
		Ast *clause = body->stmts[i];
		ast_node(cc, CaseClause, clause);

		bool saw_nil = false;
		for (Ast *type_expr : cc->list) {
			Type *case_type = type_of_expr(type_expr);
			if (is_type_untyped_nil(case_type)) {
				saw_nil = true;
			}
		}

		Entity *case_entity = implicit_entity_of_node(clause);
		bool by_reference = (case_entity->flags & EntityFlag_Value) == 0;

		cg_scope_open(p, cc->scope);

		TB_Node *body_region = control_regions[i];
		tb_inst_set_control(p->func, body_region);

		if (cc->list.count == 1 && !saw_nil) {
			cgValue data = {};
			if (switch_kind == TypeSwitch_Union) {
				data = union_data;
			} else if (switch_kind == TypeSwitch_Any) {
				data = cg_emit_load(p, cg_emit_struct_ep(p, parent_ptr, 0));
			}
			GB_ASSERT(data.kind == cgValue_Value);

			Type *ct = case_entity->type;
			Type *ct_ptr = alloc_type_pointer(ct);

			cgValue ptr = {};

			if (backing_ptr) { // by value
				GB_ASSERT(!by_reference);

				i64 size = type_size_of(case_entity->type);
				i64 align = type_align_of(case_entity->type);

				// make a copy of the case value
				tb_inst_memcpy(p->func,
				               backing_ptr, // dst
				               data.node,   // src
				               tb_inst_uint(p->func, TB_TYPE_INT, size),
				               cast(TB_CharUnits)align
				);

				ptr = cg_value(backing_ptr, ct_ptr);

			} else { // by reference
				GB_ASSERT(by_reference);
				ptr = cg_emit_conv(p, data, ct_ptr);
			}
			GB_ASSERT(are_types_identical(case_entity->type, type_deref(ptr.type)));

			cg_add_entity(p->module, case_entity, ptr);
			String name = case_entity->token.string;
			tb_function_attrib_variable(p->func, ptr.node, nullptr, name.len, cast(char const *)name.text, cg_debug_type(p->module, ct));
		} else {
			if (case_entity->flags & EntityFlag_Value) {
				// by value
				cgAddr x = cg_add_local(p, case_entity->type, case_entity, false);
				cg_addr_store(p, x, parent_value);
			} else {
				// by reference
				cg_add_entity(p->module, case_entity, parent_value);
			}
		}

		cg_push_target_list(p, ss->label, done_region, nullptr, nullptr);
		cg_build_stmt_list(p, cc->stmts);
		cg_scope_close(p, cgDeferExit_Default, body_region);
		cg_pop_target_list(p);

		cg_emit_goto(p, done_region);
	}

	cg_emit_goto(p, done_region);
	tb_inst_set_control(p->func, done_region);
}


gb_internal void cg_build_mutable_value_decl(cgProcedure *p, Ast *node) {
	ast_node(vd, ValueDecl, node);
	if (!vd->is_mutable) {
		return;
	}

	bool is_static = false;
	for (Ast *name : vd->names) if (!is_blank_ident(name)) {
		// NOTE(bill): Sanity check to check for the existence of the variable's Entity
		GB_ASSERT(name->kind == Ast_Ident);
		Entity *e = entity_of_node(name);
		TokenPos pos = ast_token(name).pos;
		GB_ASSERT_MSG(e != nullptr, "\n%s missing entity for %.*s", token_pos_to_string(pos), LIT(name->Ident.token.string));
		if (e->flags & EntityFlag_Static) {
			// NOTE(bill): If one of the entities is static, they all are
			is_static = true;
		}
	}

	if (is_static) {
		for_array(i, vd->names) {
			Ast *ident = vd->names[i];
			GB_ASSERT(!is_blank_ident(ident));
			Entity *e = entity_of_node(ident);
			GB_ASSERT(e->flags & EntityFlag_Static);
			String name = e->token.string;

			String mangled_name = {};
			{
				gbString str = gb_string_make_length(permanent_allocator(), p->name.text, p->name.len);
				str = gb_string_appendc(str, "-");
				str = gb_string_append_fmt(str, ".%.*s-%llu", LIT(name), cast(long long)e->id);
				mangled_name.text = cast(u8 *)str;
				mangled_name.len = gb_string_length(str);
			}

			cgModule *m = p->module;

			TB_DebugType *debug_type = cg_debug_type(m, e->type);
			TB_Global *global = tb_global_create(m->mod, mangled_name.len, cast(char const *)mangled_name.text, debug_type, TB_LINKAGE_PRIVATE);

			TB_ModuleSectionHandle section = tb_module_get_data(m->mod);
			if (e->Variable.thread_local_model != "") {
				section = tb_module_get_tls(m->mod);
				String model = e->Variable.thread_local_model;
				if (model == "default") {
					// TODO(bill): Thread Local Storage models
				} else if (model == "localdynamic") {
					// TODO(bill): Thread Local Storage models
				} else if (model == "initialexec") {
					// TODO(bill): Thread Local Storage models
				} else if (model == "localexec") {
					// TODO(bill): Thread Local Storage models
				} else {
					GB_PANIC("Unhandled thread local mode %.*s", LIT(model));
				}
			}

			i64 max_objects = 0;
			ExactValue value = {};

			if (vd->values.count > 0) {
				GB_ASSERT(vd->names.count == vd->values.count);
				Ast *ast_value = vd->values[i];
				GB_ASSERT(ast_value->tav.mode == Addressing_Constant ||
				          ast_value->tav.mode == Addressing_Invalid);

				value = ast_value->tav.value;
				max_objects = cg_global_const_calculate_region_count(value, e->type);
			}
			tb_global_set_storage(m->mod, section, global, type_size_of(e->type), type_align_of(e->type), max_objects);

			cg_global_const_add_region(m, value, e->type, global, 0);

			TB_Node *node = tb_inst_get_symbol_address(p->func, cast(TB_Symbol *)global);
			cgValue global_val = cg_value(node, alloc_type_pointer(e->type));
			cg_add_entity(p->module, e, global_val);
			cg_add_member(p->module, mangled_name, global_val);
		}
		return;
	}

	TEMPORARY_ALLOCATOR_GUARD();



	auto inits = array_make<cgValue>(temporary_allocator(), 0, vd->values.count != 0 ? vd->names.count : 0);
	for (Ast *rhs : vd->values) {
		cgValue init = cg_build_expr(p, rhs);
		cg_append_tuple_values(p, &inits, init);
	}


	auto lvals = slice_make<cgAddr>(temporary_allocator(), vd->names.count);
	for_array(i, vd->names) {
		Ast *name = vd->names[i];
		if (!is_blank_ident(name)) {
			Entity *e = entity_of_node(name);
			bool zero_init = vd->values.count == 0;
			if (vd->names.count == vd->values.count) {
				Ast *expr = unparen_expr(vd->values[i]);
				if (expr->kind == Ast_CompoundLit &&
				    inits[i].kind == cgValue_Addr) {
				    	TB_Node *ptr = inits[i].node;

				    	if (e != nullptr && e->token.string.len > 0 && e->token.string != "_") {
				    		// NOTE(bill): for debugging purposes only
				    		String name = e->token.string;
				    		TB_DebugType *debug_type = cg_debug_type(p->module, e->type);
						tb_function_attrib_variable(p->func, ptr, nullptr, name.len, cast(char const *)name.text, debug_type);
				    	}

					cgAddr addr = cg_addr(inits[i]);
					map_set(&p->variable_map, e, addr);
					continue;
				}
			}

			lvals[i] = cg_add_local(p, e->type, e, zero_init);
		}
	}


	GB_ASSERT(vd->values.count == 0 || lvals.count == inits.count);
	for_array(i, inits) {
		cgAddr  lval = lvals[i];
		cgValue init = inits[i];
		cg_addr_store(p, lval, init);
	}
}


gb_internal void cg_build_stmt(cgProcedure *p, Ast *node) {
	Ast *prev_stmt = p->curr_stmt;
	defer (p->curr_stmt = prev_stmt);
	p->curr_stmt = node;

	// TODO(bill): check if last instruction was a terminating one or not

	cg_set_debug_pos_from_node(p, node);

	u16 prev_state_flags = p->state_flags;
	defer (p->state_flags = prev_state_flags);

	if (node->state_flags != 0) {
		u16 in = node->state_flags;
		u16 out = p->state_flags;

		if (in & StateFlag_bounds_check) {
			out |= StateFlag_bounds_check;
			out &= ~StateFlag_no_bounds_check;
		} else if (in & StateFlag_no_bounds_check) {
			out |= StateFlag_no_bounds_check;
			out &= ~StateFlag_bounds_check;
		}
		if (in & StateFlag_no_type_assert) {
			out |= StateFlag_no_type_assert;
			out &= ~StateFlag_type_assert;
		} else if (in & StateFlag_type_assert) {
			out |= StateFlag_type_assert;
			out &= ~StateFlag_no_type_assert;
		}

		p->state_flags = out;
	}

	switch (node->kind) {
	case_ast_node(bs, EmptyStmt, node);
	case_end;

	case_ast_node(us, UsingStmt, node);
	case_end;

	case_ast_node(ws, WhenStmt, node);
		cg_build_when_stmt(p, ws);
	case_end;

	case_ast_node(bs, BlockStmt, node);
		TB_Node *done = nullptr;
		if (bs->label != nullptr) {
			done = cg_control_region(p, "block_done");
			cgTargetList *tl = cg_push_target_list(p, bs->label, done, nullptr, nullptr);
			tl->is_block = true;
		}

		cg_scope_open(p, bs->scope);
		cg_build_stmt_list(p, bs->stmts);
		cg_scope_close(p, cgDeferExit_Default, nullptr);

		if (done != nullptr) {
			cg_emit_goto(p, done);
			tb_inst_set_control(p->func, done);
		}

		if (bs->label != nullptr) {
			cg_pop_target_list(p);
		}
	case_end;

	case_ast_node(vd, ValueDecl, node);
		cg_build_mutable_value_decl(p, node);
	case_end;

	case_ast_node(bs, BranchStmt, node);
 		TB_Node *block = nullptr;

		if (bs->label != nullptr) {
			cgBranchRegions bb = cg_lookup_branch_regions(p, bs->label);
			switch (bs->token.kind) {
			case Token_break:    block = bb.break_;    break;
			case Token_continue: block = bb.continue_; break;
			case Token_fallthrough:
				GB_PANIC("fallthrough cannot have a label");
				break;
			}
		} else {
			for (cgTargetList *t = p->target_list; t != nullptr && block == nullptr; t = t->prev) {
				if (t->is_block) {
					continue;
				}

				switch (bs->token.kind) {
				case Token_break:       block = t->break_;       break;
				case Token_continue:    block = t->continue_;    break;
				case Token_fallthrough: block = t->fallthrough_; break;
				}
			}
		}
		GB_ASSERT(block != nullptr);

		cg_emit_defer_stmts(p, cgDeferExit_Branch, block);
		cg_emit_goto(p, block);
	case_end;

	case_ast_node(es, ExprStmt, node);
		cg_build_expr(p, es->expr);
	case_end;

	case_ast_node(as, AssignStmt, node);
		cg_build_assign_stmt(p, as);
	case_end;

	case_ast_node(rs, ReturnStmt, node);
		cg_build_return_stmt(p, rs->results);
	case_end;

	case_ast_node(is, IfStmt, node);
		cg_build_if_stmt(p, node);
	case_end;

	case_ast_node(fs, ForStmt, node);
		cg_build_for_stmt(p, node);
	case_end;

	case_ast_node(rs, RangeStmt, node);
		cg_build_range_stmt(p, node);
	case_end;

	case_ast_node(rs, UnrollRangeStmt, node);
		GB_PANIC("TODO(bill): lb_build_unroll_range_stmt");
		// cg_build_range_stmt(p, rs, rs->scope);
	case_end;

	case_ast_node(fs, SwitchStmt, node);
		cg_build_switch_stmt(p, node);
	case_end;

	case_ast_node(ts, TypeSwitchStmt, node);
		cg_build_type_switch_stmt(p, node);
	case_end;

	case_ast_node(ds, DeferStmt, node);
		Type *pt = base_type(p->type);
		GB_ASSERT(pt->kind == Type_Proc);
		if (pt->Proc.calling_convention == ProcCC_Odin) {
			GB_ASSERT(p->context_stack.count != 0);
		}

		cgDefer *d = array_add_and_get(&p->defer_stack);
		d->kind = cgDefer_Node;
		d->scope_index = p->scope_index;
		d->context_stack_count = p->context_stack.count;
		d->control_region = tb_inst_get_control(p->func);
		GB_ASSERT(d->control_region != nullptr);
		d->stmt = ds->stmt;
	case_end;



	default:
		GB_PANIC("TODO cg_build_stmt %.*s", LIT(ast_strings[node->kind]));
		break;
	}
}

gb_internal void cg_build_constant_value_decl(cgProcedure *p, AstValueDecl *vd) {
	if (vd == nullptr || vd->is_mutable) {
		return;
	}

	auto *min_dep_set = &p->module->info->minimum_dependency_set;

	static i32 global_guid = 0;

	for (Ast *ident : vd->names) {
		GB_ASSERT(ident->kind == Ast_Ident);
		Entity *e = entity_of_node(ident);
		GB_ASSERT(e != nullptr);
		if (e->kind != Entity_TypeName) {
			continue;
		}

		bool polymorphic_struct = false;
		if (e->type != nullptr && e->kind == Entity_TypeName) {
			Type *bt = base_type(e->type);
			if (bt->kind == Type_Struct) {
				polymorphic_struct = bt->Struct.is_polymorphic;
			}
		}

		if (!polymorphic_struct && !ptr_set_exists(min_dep_set, e)) {
			continue;
		}

		if (e->TypeName.ir_mangled_name.len != 0) {
			// NOTE(bill): Already set
			continue;
		}

		cg_set_nested_type_name_ir_mangled_name(e, p);
	}

	for_array(i, vd->names) {
		Ast *ident = vd->names[i];
		GB_ASSERT(ident->kind == Ast_Ident);
		Entity *e = entity_of_node(ident);
		GB_ASSERT(e != nullptr);
		if (e->kind != Entity_Procedure) {
			continue;
		}
		GB_ASSERT (vd->values[i] != nullptr);

		Ast *value = unparen_expr(vd->values[i]);
		if (value->kind != Ast_ProcLit) {
			continue; // It's an alias
		}

		DeclInfo *decl = decl_info_of_entity(e);
		ast_node(pl, ProcLit, decl->proc_lit);
		if (pl->body != nullptr) {
			GenProcsData *gpd = e->Procedure.gen_procs;
			if (gpd) {
				rw_mutex_shared_lock(&gpd->mutex);
				for (Entity *e : gpd->procs) {
					if (!ptr_set_exists(min_dep_set, e)) {
						continue;
					}
					DeclInfo *d = decl_info_of_entity(e);
					cg_build_nested_proc(p, &d->proc_lit->ProcLit, e);
				}
				rw_mutex_shared_unlock(&gpd->mutex);
			} else {
				cg_build_nested_proc(p, pl, e);
			}
		} else {

			// FFI - Foreign function interace
			String original_name = e->token.string;
			String name = original_name;

			if (e->Procedure.is_foreign) {
				GB_PANIC("cg_add_foreign_library_path");
				// cg_add_foreign_library_path(p->module, e->Procedure.foreign_library);
			}

			if (e->Procedure.link_name.len > 0) {
				name = e->Procedure.link_name;
			}

			cgValue *prev_value = string_map_get(&p->module->members, name);
			if (prev_value != nullptr) {
				// NOTE(bill): Don't do mutliple declarations in the IR
				return;
			}

			e->Procedure.link_name = name;

			cgProcedure *nested_proc = cg_procedure_create(p->module, e);

			cgValue value = p->value;

			array_add(&p->children, nested_proc);
			string_map_set(&p->module->members, name, value);
			cg_add_procedure_to_queue(nested_proc);
		}
	}
}


gb_internal void cg_build_stmt_list(cgProcedure *p, Slice<Ast *> const &stmts) {
	for (Ast *stmt : stmts) {
		switch (stmt->kind) {
		case_ast_node(vd, ValueDecl, stmt);
			cg_build_constant_value_decl(p, vd);
		case_end;
		case_ast_node(fb, ForeignBlockDecl, stmt);
			ast_node(block, BlockStmt, fb->body);
			cg_build_stmt_list(p, block->stmts);
		case_end;
		}
	}
	for (Ast *stmt : stmts) {
		cg_build_stmt(p, stmt);
	}
}


gb_internal void cg_build_when_stmt(cgProcedure *p, AstWhenStmt *ws) {
	TypeAndValue tv = type_and_value_of_expr(ws->cond);
	GB_ASSERT(is_type_boolean(tv.type));
	GB_ASSERT(tv.value.kind == ExactValue_Bool);
	if (tv.value.value_bool) {
		cg_build_stmt_list(p, ws->body->BlockStmt.stmts);
	} else if (ws->else_stmt) {
		switch (ws->else_stmt->kind) {
		case Ast_BlockStmt:
			cg_build_stmt_list(p, ws->else_stmt->BlockStmt.stmts);
			break;
		case Ast_WhenStmt:
			cg_build_when_stmt(p, &ws->else_stmt->WhenStmt);
			break;
		default:
			GB_PANIC("Invalid 'else' statement in 'when' statement");
			break;
		}
	}
}

