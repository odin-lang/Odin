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

gb_internal void cg_emit_store(cgProcedure *p, cgValue dst, cgValue const &src, bool is_volatile) {
	GB_ASSERT_MSG(dst.kind != cgValue_Multi, "cannot store to multiple values at once");

	if (dst.kind == cgValue_Addr) {
		dst = cg_emit_load(p, dst, is_volatile);
	} else if (dst.kind == cgValue_Symbol) {
		dst = cg_value(tb_inst_get_symbol_address(p->func, dst.symbol), dst.type);
	}

	GB_ASSERT(is_type_pointer(dst.type));
	Type *dst_type = type_deref(dst.type);

	GB_ASSERT_MSG(are_types_identical(dst_type, src.type), "%s vs %s", type_to_string(dst_type), type_to_string(src.type));

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
		tb_inst_memcpy(p->func, dst_ptr, src_ptr, count, alignment, is_volatile);
		return;
	}

	switch (dst.kind) {
	case cgValue_Value:
		switch (dst.kind) {
		case cgValue_Value:
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
			TB_Node *ptr = load_inst->inputs[1];
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
		value = cg_value(tb_inst_poison(p->func), t);
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
		GB_PANIC("TODO(bill): cgAddr_Map");
	} else if (addr.kind == cgAddr_Context) {
		GB_PANIC("TODO(bill): cgAddr_Context");
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
	ptr.node = tb_inst_array_access(p->func, ptr.node, index.node, stride);
	return ptr;
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
	s.node = tb_inst_array_access(p->func, s.node, index.node, stride);
	return s;
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
		{
			type_set_offsets(t);
			result_type = t->Struct.fields[index]->type;
			offset = t->Struct.offsets[index];
		}
		break;
	case Type_Union:
		GB_ASSERT(index == -1);
		GB_PANIC("TODO(bill): cg_emit_union_tag_ptr");
		break;
		// return cg_emit_union_tag_ptr(p, s);
	case Type_Tuple:
		GB_PANIC("TODO(bill): cg_emit_tuple_ep");
		break;
		// return cg_emit_tuple_ep(p, s, index);
	case Type_Slice:
		switch (index) {
		case 0:
			result_type = alloc_type_pointer(t->Slice.elem);
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
				result_type = t_u8_ptr;
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
			result_type = alloc_type_pointer(t->DynamicArray.elem);
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
	case Type_RelativeSlice:
		{
			Type *bi = t->RelativeSlice.base_integer;
			i64 sz = type_size_of(bi);
			switch (index) {
			case 0:
			case 1:
				result_type = bi;
				offset = sz * index;
				break;
			default:
				goto error_case;
			}
		}
		break;
	case Type_SoaPointer:
		switch (index) {
		case 0: result_type = alloc_type_pointer(t->SoaPointer.elem); break;
		case 1: result_type = t_int; break;
		}
		break;
	default:
	error_case:;
		GB_PANIC("TODO(bill): struct_gep type: %s, %d", type_to_string(s.type), index);
		break;
	}

	GB_ASSERT_MSG(result_type != nullptr, "%s %d", type_to_string(t), index);
	GB_ASSERT(offset >= 0);

	GB_ASSERT(s.kind == cgValue_Value);
	return cg_value(
		tb_inst_member_access(p->func, s.node, offset),
		alloc_type_pointer(result_type)
	);
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








gb_internal cgBranchBlocks cg_lookup_branch_blocks(cgProcedure *p, Ast *ident) {
	GB_ASSERT(ident->kind == Ast_Ident);
	Entity *e = entity_of_node(ident);
	GB_ASSERT(e->kind == Entity_Label);
	for (cgBranchBlocks const &b : p->branch_blocks) {
		if (b.label == e->Label.node) {
			return b;
		}
	}

	GB_PANIC("Unreachable");
	cgBranchBlocks empty = {};
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

		for (cgBranchBlocks &b : p->branch_blocks) {
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
		tb_node_append_attrib(local, tb_function_attrib_variable(p->func, name.len, cast(char const *)name.text, debug_type));
	}

	if (zero_init) {
		bool is_volatile = false;
		TB_Node *zero = tb_inst_uint(p->func, TB_TYPE_I8, 0);
		TB_Node *count = tb_inst_uint(p->func, TB_TYPE_I32, cast(u64)size);
		tb_inst_memset(p->func, local, zero, count, alignment, is_volatile);
	}

	cgAddr addr = cg_addr(cg_value(local, alloc_type_pointer(type)));
	if (e) {
		map_set(&p->variable_map, e, addr);
	}
	return addr;
}

gb_internal cgValue cg_address_from_load_or_generate_local(cgProcedure *p, cgValue value) {
	switch (value.kind) {
	case cgValue_Value:
		if (value.node->type == TB_LOAD) {
			TB_Node *ptr = value.node->inputs[1];
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


gb_internal void cg_scope_open(cgProcedure *p, Scope *scope) {
	// TODO(bill): cg_scope_open
}

gb_internal void cg_scope_close(cgProcedure *p, cgDeferExitKind kind, TB_Node *control_region, bool pop_stack=true) {
	// TODO(bill): cg_scope_close
}

gb_internal void cg_emit_defer_stmts(cgProcedure *p, cgDeferExitKind kind, TB_Node *control_region) {
	// TODO(bill): cg_emit_defer_stmts
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
	for_array(i, inits) {
		cgAddr lval = lvals[i];
		cgValue init = inits[i];
		if (init.type == nullptr) {
			// TODO(bill): figure out how to do this
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

gb_internal void cg_build_return_stmt(cgProcedure *p, Slice<Ast *> const &return_results) {
	TypeTuple *tuple  = &p->type->Proc.results->Tuple;
	isize return_count = p->type->Proc.result_count;
	gb_unused(tuple);
	isize res_count = return_results.count;
	gb_unused(res_count);

	if (return_count == 0) {
		tb_inst_ret(p->func, 0, nullptr);
		return;
	} else if (return_count == 1) {
		Entity *e = tuple->variables[0];
		if (res_count == 0) {
			cgValue zero = cg_const_nil(p, tuple->variables[0]->type);
			if (zero.kind == cgValue_Value) {
				tb_inst_ret(p->func, 1, &zero.node);
			}
			return;
		}
		cgValue res = cg_build_expr(p, return_results[0]);
		res = cg_emit_conv(p, res, e->type);
		if (res.kind == cgValue_Value) {
			tb_inst_ret(p->func, 1, &res.node);
		}
		return;
	} else {
		GB_PANIC("TODO(bill): MUTLIPLE RETURN VALUES");
	}
}

gb_internal void cg_build_if_stmt(cgProcedure *p, Ast *node) {
	ast_node(is, IfStmt, node);
	cg_scope_open(p, is->scope); // Scope #1
	defer (cg_scope_close(p, cgDeferExit_Default, nullptr));

	if (is->init != nullptr) {
		TB_Node *init = tb_inst_region_with_name(p->func, -1, "if_init");
		tb_inst_goto(p->func, init);
		tb_inst_set_control(p->func, init);
		cg_build_stmt(p, is->init);
	}

	TB_Node *then  = tb_inst_region_with_name(p->func, -1, "if_then");
	TB_Node *done  = tb_inst_region_with_name(p->func, -1, "if_done");
	TB_Node *else_ = done;
	if (is->else_stmt != nullptr) {
		else_ = tb_inst_region_with_name(p->func, -1, "if_else");
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

	tb_inst_goto(p->func, done);

	if (is->else_stmt != nullptr) {
		tb_inst_set_control(p->func, else_);

		cg_scope_open(p, scope_of_node(is->else_stmt));
		cg_build_stmt(p, is->else_stmt);
		cg_scope_close(p, cgDeferExit_Default, nullptr);

		tb_inst_goto(p->func, done);
	}

	tb_inst_set_control(p->func, done);
}

gb_internal void cg_build_for_stmt(cgProcedure *p, Ast *node) {
	ast_node(fs, ForStmt, node);

	cg_scope_open(p, fs->scope);
	defer (cg_scope_close(p, cgDeferExit_Default, nullptr));

	if (fs->init != nullptr) {
		TB_Node *init = tb_inst_region_with_name(p->func, -1, "for_init");
		tb_inst_goto(p->func, init);
		tb_inst_set_control(p->func, init);
		cg_build_stmt(p, fs->init);
	}
	TB_Node *body = tb_inst_region_with_name(p->func, -1, "for_body");
	TB_Node *done = tb_inst_region_with_name(p->func, -1, "for_done");
	TB_Node *loop = body;
	if (fs->cond != nullptr) {
		loop = tb_inst_region_with_name(p->func, -1, "for_loop");
	}
	TB_Node *post = loop;
	if (fs->post != nullptr) {
		post = tb_inst_region_with_name(p->func, -1, "for_post");
	}

	tb_inst_goto(p->func, loop);
	tb_inst_set_control(p->func, loop);

	if (loop != body) {
		cg_build_cond(p, fs->cond, body, done);
		tb_inst_set_control(p->func, body);
	}

	cg_push_target_list(p, fs->label, done, post, nullptr);
	cg_build_stmt(p, fs->body);
	cg_pop_target_list(p);

	tb_inst_goto(p->func, post);

	if (fs->post != nullptr) {
		tb_inst_set_control(p->func, post);
		cg_build_stmt(p, fs->post);
		tb_inst_goto(p->func, loop);
	}
	tb_inst_set_control(p->func, done);
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

	TB_Node *done = tb_inst_region_with_name(p->func, -1, "switch_done");

	ast_node(body, BlockStmt, ss->body);

	isize case_count = body->stmts.count;
	Slice<Ast *> default_stmts = {};
	TB_Node *default_fall  = nullptr;
	TB_Node *default_block = nullptr;
	Scope *  default_scope = nullptr;
	TB_Node *fall = nullptr;

	auto body_blocks = slice_make<TB_Node *>(permanent_allocator(), body->stmts.count);
	auto body_scopes = slice_make<Scope *>(permanent_allocator(), body->stmts.count);
	for_array(i, body->stmts) {
		Ast *clause = body->stmts[i];
		ast_node(cc, CaseClause, clause);

		body_blocks[i] = tb_inst_region_with_name(p->func, -1, cc->list.count == 0 ? "switch_default_body" : "switch_case_body");
		body_scopes[i] = cc->scope;
		if (cc->list.count == 0) {
			default_block = body_blocks[i];
			default_scope = cc->scope;
		}
	}

	for_array(i, body->stmts) {
		Ast *clause = body->stmts[i];
		ast_node(cc, CaseClause, clause);

		TB_Node *body = body_blocks[i];
		Scope *body_scope = body_scopes[i];
		fall = done;
		if (i+1 < case_count) {
			fall = body_blocks[i+1];
		}

		if (cc->list.count == 0) {
			// default case
			default_stmts = cc->stmts;
			default_fall  = fall;
			default_block = body;
			continue;
		}

		TB_Node *next_cond = nullptr;
		for (Ast *expr : cc->list) {
			expr = unparen_expr(expr);

			next_cond = tb_inst_region_with_name(p->func, -1, "switch_case_next");

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
					cgValue e = cg_typeid(p->module, expr->tav.type);
					e = cg_emit_conv(p, e, tag.type);
					cond = cg_emit_comp(p, Token_CmpEq, tag, e);
				} else {
					cond = cg_emit_comp(p, Token_CmpEq, tag, cg_build_expr(p, expr));
				}
			}

			GB_ASSERT(cond.kind == cgValue_Value);
			tb_inst_if(p->func, cond.node, body, next_cond);
			tb_inst_set_control(p->func, next_cond);
		}

		tb_inst_set_control(p->func, body);

		cg_push_target_list(p, ss->label, done, nullptr, fall);
		cg_scope_open(p, body_scope);
		cg_build_stmt_list(p, cc->stmts);
		cg_scope_close(p, cgDeferExit_Default, body);
		cg_pop_target_list(p);

		tb_inst_goto(p->func, done);
		tb_inst_set_control(p->func, next_cond);
	}

	if (default_block != nullptr) {
		tb_inst_goto(p->func, default_block);
		tb_inst_set_control(p->func, default_block);

		cg_push_target_list(p, ss->label, done, nullptr, default_fall);
		cg_scope_open(p, default_scope);
		cg_build_stmt_list(p, default_stmts);
		cg_scope_close(p, cgDeferExit_Default, default_block);
		cg_pop_target_list(p);
	}

	tb_inst_goto(p->func, done);
	tb_inst_set_control(p->func, done);

	cg_scope_close(p, cgDeferExit_Default, done);
}


gb_internal void cg_build_stmt(cgProcedure *p, Ast *node) {
	Ast *prev_stmt = p->curr_stmt;
	defer (p->curr_stmt = prev_stmt);
	p->curr_stmt = node;

	// TODO(bill): check if last instruction was a terminating one or not

	{
		TokenPos pos = ast_token(node).pos;
		TB_FileID *file_id = map_get(&p->module->file_id_map, cast(uintptr)pos.file_id);
		if (file_id) {
			tb_inst_set_location(p->func, *file_id, pos.line);
		}
	}

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
			done = tb_inst_region_with_name(p->func, -1, "block_done");
			cgTargetList *tl = cg_push_target_list(p, bs->label, done, nullptr, nullptr);
			tl->is_block = true;
		}

		cg_scope_open(p, bs->scope);
		cg_build_stmt_list(p, bs->stmts);
		cg_scope_close(p, cgDeferExit_Default, nullptr);

		if (done != nullptr) {
			tb_inst_goto(p->func, done);
			tb_inst_set_control(p->func, done);
		}

		if (bs->label != nullptr) {
			cg_pop_target_list(p);
		}
	case_end;

	case_ast_node(vd, ValueDecl, node);
		if (!vd->is_mutable) {
			return;
		}

		bool is_static = false;
		if (vd->names.count > 0) {
			for (Ast *name : vd->names) {
				if (!is_blank_ident(name)) {
					GB_ASSERT(name->kind == Ast_Ident);
					Entity *e = entity_of_node(name);
					TokenPos pos = ast_token(name).pos;
					GB_ASSERT_MSG(e != nullptr, "\n%s missing entity for %.*s", token_pos_to_string(pos), LIT(name->Ident.token.string));
					if (e->flags & EntityFlag_Static) {
						// NOTE(bill): If one of the entities is static, they all are
						is_static = true;
						break;
					}
				}
			}
		}
		if (is_static) {
			GB_PANIC("TODO(bill): build static variables");
			return;
		}

		TEMPORARY_ALLOCATOR_GUARD();

		auto const &values = vd->values;
		if (values.count == 0) {
			for (Ast *name : vd->names) {
				if (!is_blank_ident(name)) {
					Entity *e = entity_of_node(name);
					cgAddr addr = cg_add_local(p, e->type, e, true);
					gb_unused(addr);
				}
			}
		} else {
			auto lvals = slice_make<cgAddr>(temporary_allocator(), vd->names.count);
			auto inits = array_make<cgValue>(temporary_allocator(), 0, lvals.count);
			for (Ast *rhs : values) {
				rhs = unparen_expr(rhs);
				cgValue init = cg_build_expr(p, rhs);
				cg_append_tuple_values(p, &inits, init);
			}

			for_array(i, vd->names) {
				Ast *name = vd->names[i];
				if (!is_blank_ident(name)) {
					Entity *e = entity_of_node(name);
					lvals[i] = cg_add_local(p, e->type, e, true);
				}
			}
			GB_ASSERT(lvals.count == inits.count);
			for_array(i, inits) {
				cgAddr lval = lvals[i];
				cgValue init = inits[i];
				cg_addr_store(p, lval, init);
			}
		}
	case_end;

	case_ast_node(bs, BranchStmt, node);
		TB_Node *prev_block = tb_inst_get_control(p->func);

		TB_Node *block = nullptr;

		if (bs->label != nullptr) {
			cgBranchBlocks bb = cg_lookup_branch_blocks(p, bs->label);
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
		if (block != nullptr) {
			cg_emit_defer_stmts(p, cgDeferExit_Branch, block);
		}


		tb_inst_goto(p->func, block);
		tb_inst_set_control(p->func, block);
		tb_inst_unreachable(p->func);

		tb_inst_set_control(p->func, prev_block);
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

	case_ast_node(fs, SwitchStmt, node);
		cg_build_switch_stmt(p, node);
	case_end;

	default:
		GB_PANIC("TODO cg_build_stmt %.*s", LIT(ast_strings[node->kind]));
		break;
	}
}


gb_internal void cg_build_stmt_list(cgProcedure *p, Slice<Ast *> const &stmts) {
	for (Ast *stmt : stmts) {
		switch (stmt->kind) {
		case_ast_node(vd, ValueDecl, stmt);
			// TODO(bill)
			// cg_build_constant_value_decl(p, vd);
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

