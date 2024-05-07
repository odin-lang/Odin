gb_internal lbValue lb_lookup_runtime_procedure(lbModule *m, String const &name);

gb_internal bool lb_is_type_aggregate(Type *t) {
	t = base_type(t);
	switch (t->kind) {
	case Type_Basic:
		switch (t->Basic.kind) {
		case Basic_string:
		case Basic_any:
			return true;

		case Basic_complex32:
		case Basic_complex64:
		case Basic_complex128:
		case Basic_quaternion64:
		case Basic_quaternion128:
		case Basic_quaternion256:
			return true;
		}
		break;

	case Type_Pointer:
		return false;

	case Type_Array:
	case Type_Slice:
	case Type_Struct:
	case Type_Union:
	case Type_Tuple:
	case Type_DynamicArray:
	case Type_Map:
	case Type_SimdVector:
		return true;

	case Type_Named:
		return lb_is_type_aggregate(t->Named.base);
	}

	return false;
}

gb_internal void lb_emit_unreachable(lbProcedure *p) {
	LLVMValueRef instr = LLVMGetLastInstruction(p->curr_block->block);
	if (instr == nullptr || !lb_is_instr_terminating(instr)) {
		lb_call_intrinsic(p, "llvm.trap", nullptr, 0, nullptr, 0);
		LLVMBuildUnreachable(p->builder);
	}
}

gb_internal lbValue lb_correct_endianness(lbProcedure *p, lbValue value) {
	Type *src = core_type(value.type);
	GB_ASSERT(is_type_integer(src) || is_type_float(src));
	if (is_type_different_to_arch_endianness(src)) {
		Type *platform_src_type = integer_endian_type_to_platform_type(src);
		value = lb_emit_byte_swap(p, value, platform_src_type);
	}
	return value;
}


gb_internal void lb_set_metadata_custom_u64(lbModule *m, LLVMValueRef v_ref, String name, u64 value) {
	unsigned md_id = LLVMGetMDKindIDInContext(m->ctx, cast(char const *)name.text, cast(unsigned)name.len);
	LLVMMetadataRef md = LLVMValueAsMetadata(LLVMConstInt(lb_type(m, t_u64), value, false));
	LLVMValueRef node = LLVMMetadataAsValue(m->ctx, LLVMMDNodeInContext2(m->ctx, &md, 1));
	LLVMSetMetadata(v_ref, md_id, node);
}
gb_internal u64 lb_get_metadata_custom_u64(lbModule *m, LLVMValueRef v_ref, String name) {
	unsigned md_id = LLVMGetMDKindIDInContext(m->ctx, cast(char const *)name.text, cast(unsigned)name.len);
	LLVMValueRef v_md = LLVMGetMetadata(v_ref, md_id);
	if (v_md == nullptr) {
		return 0;
	}
	unsigned node_count = LLVMGetMDNodeNumOperands(v_md);
	if (node_count == 0) {
		return 0;
	}
	GB_ASSERT(node_count == 1);
	LLVMValueRef value = nullptr;
	LLVMGetMDNodeOperands(v_md, &value);
	return LLVMConstIntGetZExtValue(value);
}

gb_internal LLVMValueRef lb_mem_zero_ptr_internal(lbProcedure *p, LLVMValueRef ptr, usize len, unsigned alignment, bool is_volatile) {
	return lb_mem_zero_ptr_internal(p, ptr, LLVMConstInt(lb_type(p->module, t_uint), len, false), alignment, is_volatile);
}

gb_internal LLVMValueRef lb_mem_zero_ptr_internal(lbProcedure *p, LLVMValueRef ptr, LLVMValueRef len, unsigned alignment, bool is_volatile) {
	bool is_inlinable = false;

	i64 const_len = 0;
	if (LLVMIsConstant(len)) {
		const_len = cast(i64)LLVMConstIntGetSExtValue(len);
		// TODO(bill): Determine when it is better to do the `*.inline` versions
		if (const_len <= lb_max_zero_init_size()) {
			is_inlinable = true;
		}
	}


	char const *name = "llvm.memset";
	if (is_inlinable) {
		name = "llvm.memset.inline";
	}

	LLVMTypeRef types[2] = {
		lb_type(p->module, t_rawptr),
		lb_type(p->module, t_int)
	};
	LLVMValueRef args[4] = {};
	args[0] = LLVMBuildPointerCast(p->builder, ptr, types[0], "");
	args[1] = LLVMConstInt(LLVMInt8TypeInContext(p->module->ctx), 0, false);
	args[2] = LLVMBuildIntCast2(p->builder, len, types[1], /*signed*/false, "");
	args[3] = LLVMConstInt(LLVMInt1TypeInContext(p->module->ctx), is_volatile, false);

	return lb_call_intrinsic(p, name, args, gb_count_of(args), types, gb_count_of(types));

}

gb_internal void lb_mem_zero_ptr(lbProcedure *p, LLVMValueRef ptr, Type *type, unsigned alignment) {
	LLVMTypeRef llvm_type = lb_type(p->module, type);

	LLVMTypeKind kind = LLVMGetTypeKind(llvm_type);
	i64 sz = type_size_of(type);
	switch (kind) {
	case LLVMStructTypeKind:
	case LLVMArrayTypeKind:
		// NOTE(bill): Enforce zeroing through memset to make sure padding is zeroed too
		lb_mem_zero_ptr_internal(p, ptr, lb_const_int(p->module, t_int, sz).value, alignment, false);
		break;
	default:
		LLVMBuildStore(p->builder, LLVMConstNull(lb_type(p->module, type)), ptr);
		break;
	}
}

gb_internal lbValue lb_emit_select(lbProcedure *p, lbValue cond, lbValue x, lbValue y) {
	cond = lb_emit_conv(p, cond, t_llvm_bool);
	lbValue res = {};
	res.value = LLVMBuildSelect(p->builder, cond.value, x.value, y.value, "");
	res.type = x.type;
	return res;
}

gb_internal lbValue lb_emit_min(lbProcedure *p, Type *t, lbValue x, lbValue y) {
	x = lb_emit_conv(p, x, t);
	y = lb_emit_conv(p, y, t);
	bool use_llvm_intrinsic = !is_arch_wasm() && (is_type_float(t) || (is_type_simd_vector(t) && is_type_float(base_array_type(t))));
	if (use_llvm_intrinsic) {
		LLVMValueRef args[2] = {x.value, y.value};
		LLVMTypeRef types[1] = {lb_type(p->module, t)};

		// NOTE(bill): f either operand is a NaN, returns NaN. Otherwise returns the lesser of the two arguments.
		// -0.0 is considered to be less than +0.0 for this intrinsic.
		// These semantics are specified by IEEE 754-2008.
		LLVMValueRef v = lb_call_intrinsic(p, "llvm.minnum", args, gb_count_of(args), types, gb_count_of(types));
		return {v, t};
	}
	return lb_emit_select(p, lb_emit_comp(p, Token_Lt, x, y), x, y);
}
gb_internal lbValue lb_emit_max(lbProcedure *p, Type *t, lbValue x, lbValue y) {
	x = lb_emit_conv(p, x, t);
	y = lb_emit_conv(p, y, t);
	bool use_llvm_intrinsic = !is_arch_wasm() && (is_type_float(t) || (is_type_simd_vector(t) && is_type_float(base_array_type(t))));
	if (use_llvm_intrinsic) {
		LLVMValueRef args[2] = {x.value, y.value};
		LLVMTypeRef types[1] = {lb_type(p->module, t)};

		// NOTE(bill): If either operand is a NaN, returns NaN. Otherwise returns the greater of the two arguments.
		// -0.0 is considered to be less than +0.0 for this intrinsic.
		// These semantics are specified by IEEE 754-2008.
		LLVMValueRef v = lb_call_intrinsic(p, "llvm.maxnum", args, gb_count_of(args), types, gb_count_of(types));
		return {v, t};
	}
	return lb_emit_select(p, lb_emit_comp(p, Token_Gt, x, y), x, y);
}


gb_internal lbValue lb_emit_clamp(lbProcedure *p, Type *t, lbValue x, lbValue min, lbValue max) {
	lbValue z = {};
	z = lb_emit_max(p, t, x, min);
	z = lb_emit_min(p, t, z, max);
	return z;
}



gb_internal lbValue lb_emit_string(lbProcedure *p, lbValue str_elem, lbValue str_len) {
	if (false && lb_is_const(str_elem) && lb_is_const(str_len)) {
		LLVMValueRef values[2] = {
			str_elem.value,
			str_len.value,
		};
		lbValue res = {};
		res.type = t_string;
		res.value = llvm_const_named_struct(p->module, t_string, values, gb_count_of(values));
		return res;
	} else {
		lbAddr res = lb_add_local_generated(p, t_string, false);
		lb_emit_store(p, lb_emit_struct_ep(p, res.addr, 0), str_elem);
		lb_emit_store(p, lb_emit_struct_ep(p, res.addr, 1), str_len);
		return lb_addr_load(p, res);
	}
}


gb_internal lbValue lb_emit_transmute(lbProcedure *p, lbValue value, Type *t) {
	Type *src_type = value.type;
	if (are_types_identical(t, src_type)) {
		return value;
	}

	lbValue res = {};
	res.type = t;


	Type *src = base_type(src_type);
	Type *dst = base_type(t);

	lbModule *m = p->module;

	i64 sz = type_size_of(src);
	i64 dz = type_size_of(dst);

	if (sz != dz) {
		LLVMTypeRef s = lb_type(m, src);
		LLVMTypeRef d = lb_type(m, dst);
		i64 llvm_sz = lb_sizeof(s);
		i64 llvm_dz = lb_sizeof(d);
		GB_ASSERT_MSG(llvm_sz == llvm_dz, "%s %s", LLVMPrintTypeToString(s), LLVMPrintTypeToString(d));
	}

	GB_ASSERT_MSG(sz == dz, "Invalid transmute conversion: '%s' to '%s'", type_to_string(src_type), type_to_string(t));

	// NOTE(bill): Casting between an integer and a pointer cannot be done through a bitcast
	if (is_type_internally_pointer_like(src)) {
		if (is_type_integer(dst)) {
			res.value = LLVMBuildPtrToInt(p->builder, value.value, lb_type(m, t), "");
			return res;
		} else if (is_type_internally_pointer_like(dst)) {
			res.value = LLVMBuildPointerCast(p->builder, value.value, lb_type(p->module, t), "");
			return res;
		} else if (is_type_float(dst)) {
			LLVMValueRef the_int = LLVMBuildPtrToInt(p->builder, value.value, lb_type(m, t_uintptr), "");
			res.value = LLVMBuildBitCast(p->builder, the_int, lb_type(m, t), "");
			return res;
		}
	}

	if (is_type_internally_pointer_like(dst)) {
		if (is_type_uintptr(src) && is_type_internally_pointer_like(dst)) {
			res.value = LLVMBuildIntToPtr(p->builder, value.value, lb_type(m, t), "");
			return res;
		} else if (is_type_integer(src) && is_type_internally_pointer_like(dst)) {
			res.value = LLVMBuildIntToPtr(p->builder, value.value, lb_type(m, t), "");
			return res;
		} else if (is_type_float(src)) {
			LLVMValueRef the_int = LLVMBuildBitCast(p->builder, value.value, lb_type(m, t_uintptr), "");
			res.value = LLVMBuildIntToPtr(p->builder, the_int, lb_type(m, t), "");
			return res;
		}
	}

	if (is_type_simd_vector(src) && is_type_simd_vector(dst)) {
		res.value = LLVMBuildBitCast(p->builder, value.value, lb_type(p->module, t), "");
		return res;
	} else if (is_type_array_like(src) && is_type_simd_vector(dst)) {
		unsigned align = cast(unsigned)gb_max(type_align_of(src), type_align_of(dst));
		lbValue ptr = lb_address_from_load_or_generate_local(p, value);
		if (lb_try_update_alignment(ptr, align)) {
			LLVMTypeRef result_type = lb_type(p->module, t);
			res.value = LLVMBuildPointerCast(p->builder, ptr.value, LLVMPointerType(result_type, 0), "");
			res.value = LLVMBuildLoad2(p->builder, result_type, res.value, "");
			return res;
		}
		lbAddr addr = lb_add_local_generated(p, t, false);
		lbValue ap = lb_addr_get_ptr(p, addr);
		ap = lb_emit_conv(p, ap, alloc_type_pointer(value.type));
		lb_emit_store(p, ap, value);
		return lb_addr_load(p, addr);
	} else if (is_type_map(src) && are_types_identical(t_raw_map, t)) {
		res.value = value.value;
		res.type = t;
		return res;
	} else if (lb_is_type_aggregate(src) || lb_is_type_aggregate(dst)) {
		lbValue s = lb_address_from_load_or_generate_local(p, value);
		lbValue d = lb_emit_transmute(p, s, alloc_type_pointer(t));
		return lb_emit_load(p, d);
	}

	res.value = OdinLLVMBuildTransmute(p, value.value, lb_type(m, res.type));
	return res;
}

gb_internal lbValue lb_copy_value_to_ptr(lbProcedure *p, lbValue val, Type *new_type, i64 alignment) {
	i64 type_alignment = type_align_of(new_type);
	if (alignment < type_alignment) {
		alignment = type_alignment;
	}
	GB_ASSERT_MSG(are_types_identical(new_type, val.type), "%s %s", type_to_string(new_type), type_to_string(val.type));

	lbAddr ptr = lb_add_local_generated(p, new_type, false);
	LLVMSetAlignment(ptr.addr.value, cast(unsigned)alignment);
	lb_addr_store(p, ptr, val);
	// ptr.kind = lbAddr_Context;
	return ptr.addr;
}


gb_internal lbValue lb_soa_zip(lbProcedure *p, AstCallExpr *ce, TypeAndValue const &tv) {
	GB_ASSERT(ce->args.count > 0);

	auto slices = slice_make<lbValue>(temporary_allocator(), ce->args.count);
	for_array(i, slices) {
		Ast *arg = ce->args[i];
		if (arg->kind == Ast_FieldValue) {
			arg = arg->FieldValue.value;
		}
		slices[i] = lb_build_expr(p, arg);
	}

	lbValue len = lb_slice_len(p, slices[0]);
	for (isize i = 1; i < slices.count; i++) {
		lbValue other_len = lb_slice_len(p, slices[i]);
		len = lb_emit_min(p, t_int, len, other_len);
	}

	GB_ASSERT(is_type_soa_struct(tv.type));
	lbAddr res = lb_add_local_generated(p, tv.type, true);
	for_array(i, slices) {
		lbValue src = lb_slice_elem(p, slices[i]);
		lbValue dst = lb_emit_struct_ep(p, res.addr, cast(i32)i);
		lb_emit_store(p, dst, src);
	}
	lbValue len_dst = lb_emit_struct_ep(p, res.addr, cast(i32)slices.count);
	lb_emit_store(p, len_dst, len);

	return lb_addr_load(p, res);
}

gb_internal lbValue lb_soa_unzip(lbProcedure *p, AstCallExpr *ce, TypeAndValue const &tv) {
	GB_ASSERT(ce->args.count == 1);

	lbValue arg = lb_build_expr(p, ce->args[0]);
	Type *t = base_type(arg.type);
	GB_ASSERT(is_type_soa_struct(t) && t->Struct.soa_kind == StructSoa_Slice);

	lbValue len = lb_soa_struct_len(p, arg);

	lbAddr res = lb_add_local_generated(p, tv.type, true);
	if (is_type_tuple(tv.type)) {
		lbValue rp = lb_addr_get_ptr(p, res);
		for (i32 i = 0; i < cast(i32)(t->Struct.fields.count-1); i++) {
			lbValue ptr = lb_emit_struct_ev(p, arg, i);
			lbAddr dst = lb_addr(lb_emit_struct_ep(p, rp, i));
			lb_fill_slice(p, dst, ptr, len);
		}
	} else {
		GB_ASSERT(is_type_slice(tv.type));
		lbValue ptr = lb_emit_struct_ev(p, arg, 0);
		lb_fill_slice(p, res, ptr, len);
	}

	return lb_addr_load(p, res);
}

gb_internal void lb_emit_try_lhs_rhs(lbProcedure *p, Ast *arg, TypeAndValue const &tv, lbValue *lhs_, lbValue *rhs_) {
	lbValue lhs = {};
	lbValue rhs = {};

	lbValue value = lb_build_expr(p, arg);
	if (is_type_tuple(value.type)) {
		i32 n = cast(i32)(value.type->Tuple.variables.count-1);
		if (value.type->Tuple.variables.count == 2) {
			lhs = lb_emit_tuple_ev(p, value, 0);
		} else {
			lbAddr lhs_addr = lb_add_local_generated(p, tv.type, false);
			lbValue lhs_ptr = lb_addr_get_ptr(p, lhs_addr);
			for (i32 i = 0; i < n; i++) {
				lb_emit_store(p, lb_emit_struct_ep(p, lhs_ptr, i), lb_emit_tuple_ev(p, value, i));
			}
			lhs = lb_addr_load(p, lhs_addr);
		}
		rhs = lb_emit_tuple_ev(p, value, n);
	} else {
		rhs = value;
	}

	GB_ASSERT(rhs.value != nullptr);

	if (lhs_) *lhs_ = lhs;
	if (rhs_) *rhs_ = rhs;
}


gb_internal lbValue lb_emit_try_has_value(lbProcedure *p, lbValue rhs) {
	lbValue has_value = {};
	if (is_type_boolean(rhs.type)) {
		has_value = rhs;
	} else {
		GB_ASSERT_MSG(type_has_nil(rhs.type), "%s", type_to_string(rhs.type));
		has_value = lb_emit_comp_against_nil(p, Token_CmpEq, rhs);
	}
	GB_ASSERT(has_value.value != nullptr);
	return has_value;
}


gb_internal lbValue lb_emit_or_else(lbProcedure *p, Ast *arg, Ast *else_expr, TypeAndValue const &tv) {
	if (arg->state_flags & StateFlag_DirectiveWasFalse) {
		return lb_build_expr(p, else_expr);
	}

	lbValue lhs = {};
	lbValue rhs = {};
	lb_emit_try_lhs_rhs(p, arg, tv, &lhs, &rhs);

	GB_ASSERT(else_expr != nullptr);

	Type *type = default_type(tv.type);

	if (is_diverging_expr(else_expr)) {
		lbBlock *then  = lb_create_block(p, "or_else.then");
		lbBlock *else_ = lb_create_block(p, "or_else.else");

		lb_emit_if(p, lb_emit_try_has_value(p, rhs), then, else_);
		// NOTE(bill): else block needs to be straight afterwards to make sure that the actual value is used
		// from the then block
		lb_start_block(p, else_);

		lb_build_expr(p, else_expr);
		lb_emit_unreachable(p); // add just in case

		lb_start_block(p, then);
		return lb_emit_conv(p, lhs, type);
	} else {
		LLVMValueRef incoming_values[2] = {};
		LLVMBasicBlockRef incoming_blocks[2] = {};

		lbBlock *then  = lb_create_block(p, "or_else.then");
		lbBlock *done  = lb_create_block(p, "or_else.done"); // NOTE(bill): Append later
		lbBlock *else_ = lb_create_block(p, "or_else.else");

		lb_emit_if(p, lb_emit_try_has_value(p, rhs), then, else_);
		lb_start_block(p, then);

		incoming_values[0] = lb_emit_conv(p, lhs, type).value;

		lb_emit_jump(p, done);
		lb_start_block(p, else_);

		incoming_values[1] = lb_emit_conv(p, lb_build_expr(p, else_expr), type).value;

		lb_emit_jump(p, done);
		lb_start_block(p, done);

		lbValue res = {};
		res.value = LLVMBuildPhi(p->builder, lb_type(p->module, type), "");
		res.type = type;

		GB_ASSERT(p->curr_block->preds.count >= 2);
		incoming_blocks[0] = p->curr_block->preds[0]->block;
		incoming_blocks[1] = p->curr_block->preds[1]->block;

		LLVMAddIncoming(res.value, incoming_values, incoming_blocks, 2);

		return res;
	}
}

gb_internal void lb_build_return_stmt(lbProcedure *p, Slice<Ast *> const &return_results);
gb_internal void lb_build_return_stmt_internal(lbProcedure *p, lbValue res);

gb_internal lbValue lb_emit_or_return(lbProcedure *p, Ast *arg, TypeAndValue const &tv) {
	lbValue lhs = {};
	lbValue rhs = {};
	lb_emit_try_lhs_rhs(p, arg, tv, &lhs, &rhs);

	lbBlock *return_block  = lb_create_block(p, "or_return.return");
	lbBlock *continue_block  = lb_create_block(p, "or_return.continue");

	lb_emit_if(p, lb_emit_try_has_value(p, rhs), continue_block, return_block);
	lb_start_block(p, return_block);
	{
		Type *proc_type = base_type(p->type);
		Type *results = proc_type->Proc.results;
		GB_ASSERT(results != nullptr && results->kind == Type_Tuple);
		TypeTuple *tuple = &results->Tuple;

		GB_ASSERT(tuple->variables.count != 0);

		Entity *end_entity = tuple->variables[tuple->variables.count-1];
		rhs = lb_emit_conv(p, rhs, end_entity->type);
		if (p->type->Proc.has_named_results) {
			GB_ASSERT(end_entity->token.string.len != 0);

			// NOTE(bill): store the named values before returning
			lbValue found = map_must_get(&p->module->values, end_entity);
			lb_emit_store(p, found, rhs);

			lb_build_return_stmt(p, {});
		} else {
			GB_ASSERT(tuple->variables.count == 1);
			lb_build_return_stmt_internal(p, rhs);
		}
	}
	lb_start_block(p, continue_block);
	if (tv.type != nullptr) {
		return lb_emit_conv(p, lhs, tv.type);
	}
	return {};
}


gb_internal void lb_emit_increment(lbProcedure *p, lbValue addr) {
	GB_ASSERT(is_type_pointer(addr.type));
	Type *type = type_deref(addr.type);
	lbValue v_one = lb_const_value(p->module, type, exact_value_i64(1));
	lb_emit_store(p, addr, lb_emit_arith(p, Token_Add, lb_emit_load(p, addr), v_one, type));

}

gb_internal lbValue lb_emit_byte_swap(lbProcedure *p, lbValue value, Type *end_type) {
	GB_ASSERT(type_size_of(value.type) == type_size_of(end_type));

	if (type_size_of(value.type) < 2) {
		return value;
	}

	Type *original_type = value.type;
	if (is_type_float(original_type)) {
		i64 sz = type_size_of(original_type);
		Type *integer_type = nullptr;
		switch (sz) {
		case 2: integer_type = t_u16; break;
		case 4: integer_type = t_u32; break;
		case 8: integer_type = t_u64; break;
		}
		GB_ASSERT(integer_type != nullptr);
		value = lb_emit_transmute(p, value, integer_type);
	}

	char const *name = "llvm.bswap";
	LLVMTypeRef types[1] = {lb_type(p->module, value.type)};

	LLVMValueRef args[1] = { value.value };

	lbValue res = {};
	res.value = lb_call_intrinsic(p, name, args, gb_count_of(args), types, gb_count_of(types));
	res.type = value.type;

	if (is_type_float(original_type)) {
		res = lb_emit_transmute(p, res, original_type);
	}
	res.type = end_type;
	return res;
}




gb_internal lbValue lb_emit_count_ones(lbProcedure *p, lbValue x, Type *type) {
	x = lb_emit_conv(p, x, type);

	char const *name = "llvm.ctpop";
	LLVMTypeRef types[1] = {lb_type(p->module, type)};
	LLVMValueRef args[1] = { x.value };

	lbValue res = {};
	res.value = lb_call_intrinsic(p, name, args, gb_count_of(args), types, gb_count_of(types));
	res.type = type;
	return res;
}

gb_internal lbValue lb_emit_count_zeros(lbProcedure *p, lbValue x, Type *type) {
	Type *elem = base_array_type(type);
	i64 sz = 8*type_size_of(elem);
	lbValue size = lb_const_int(p->module, elem, cast(u64)sz);
	size = lb_emit_conv(p, size, type);
	lbValue count = lb_emit_count_ones(p, x, type);
	return lb_emit_arith(p, Token_Sub, size, count, type);
}



gb_internal lbValue lb_emit_count_trailing_zeros(lbProcedure *p, lbValue x, Type *type) {
	x = lb_emit_conv(p, x, type);

	char const *name = "llvm.cttz";
	LLVMTypeRef types[1] = {lb_type(p->module, type)};

	LLVMValueRef args[2] = {
			x.value,
			LLVMConstNull(LLVMInt1TypeInContext(p->module->ctx)) };

	lbValue res = {};
	res.value = lb_call_intrinsic(p, name, args, gb_count_of(args), types, gb_count_of(types));
	res.type = type;
	return res;
}

gb_internal lbValue lb_emit_count_leading_zeros(lbProcedure *p, lbValue x, Type *type) {
	x = lb_emit_conv(p, x, type);

	char const *name = "llvm.ctlz";
	LLVMTypeRef types[1] = {lb_type(p->module, type)};

	LLVMValueRef args[2] = {
			x.value,
			LLVMConstNull(LLVMInt1TypeInContext(p->module->ctx)) };

	lbValue res = {};
	res.value = lb_call_intrinsic(p, name, args, gb_count_of(args), types, gb_count_of(types));
	res.type = type;
	return res;
}



gb_internal lbValue lb_emit_reverse_bits(lbProcedure *p, lbValue x, Type *type) {
	x = lb_emit_conv(p, x, type);

	char const *name = "llvm.bitreverse";
	LLVMTypeRef types[1] = {lb_type(p->module, type)};

	LLVMValueRef args[1] = { x.value };

	lbValue res = {};
	res.value = lb_call_intrinsic(p, name, args, gb_count_of(args), types, gb_count_of(types));
	res.type = type;
	return res;
}


gb_internal lbValue lb_emit_union_cast_only_ok_check(lbProcedure *p, lbValue value, Type *type, TokenPos pos) {
	GB_ASSERT(is_type_tuple(type));
	lbModule *m = p->module;

	Type *src_type = value.type;
	bool is_ptr = is_type_pointer(src_type);


	// IMPORTANT NOTE(bill): This assumes that the value is completely ignored
	// so when it does an assignment, it complete ignores the value.
	// Just make it two booleans and ignore the first one
	//
	// _, ok := x.(T);
	//
	Type *ok_type = type->Tuple.variables[1]->type;
	Type *gen_tuple_types[2] = {};
	gen_tuple_types[0] = ok_type;
	gen_tuple_types[1] = ok_type;

	Type *gen_tuple = alloc_type_tuple_from_field_types(gen_tuple_types, gb_count_of(gen_tuple_types), false, true);

	lbAddr v = lb_add_local_generated(p, gen_tuple, false);

	if (is_ptr) {
		value = lb_emit_load(p, value);
	}
	Type *src = base_type(type_deref(src_type));
	GB_ASSERT_MSG(is_type_union(src), "%s", type_to_string(src_type));
	Type *dst = type->Tuple.variables[0]->type;

	lbValue cond = {};

	if (is_type_union_maybe_pointer(src)) {
		lbValue data = lb_emit_transmute(p, value, dst);
		cond = lb_emit_comp_against_nil(p, Token_NotEq, data);
	} else {
		lbValue tag = lb_emit_union_tag_value(p, value);
		lbValue dst_tag = lb_const_union_tag(m, src, dst);
		cond = lb_emit_comp(p, Token_CmpEq, tag, dst_tag);
	}

	lbValue gep1 = lb_emit_struct_ep(p, v.addr, 1);
	lb_emit_store(p, gep1, cond);

	return lb_addr_load(p, v);
}

gb_internal lbValue lb_emit_union_cast(lbProcedure *p, lbValue value, Type *type, TokenPos pos) {
	lbModule *m = p->module;

	Type *src_type = value.type;
	bool is_ptr = is_type_pointer(src_type);

	bool is_tuple = true;
	Type *tuple = type;
	if (type->kind != Type_Tuple) {
		is_tuple = false;
		tuple = make_optional_ok_type(type);
	}

	lbAddr v = lb_add_local_generated(p, tuple, true);

	if (is_ptr) {
		value = lb_emit_load(p, value);
	}
	Type *src = base_type(type_deref(src_type));
	GB_ASSERT_MSG(is_type_union(src), "%s", type_to_string(src_type));
	Type *dst = tuple->Tuple.variables[0]->type;

	lbValue value_  = lb_address_from_load_or_generate_local(p, value);

	if ((p->state_flags & StateFlag_no_type_assert) != 0 && !is_tuple) {
		// just do a bit cast of the data at the front
		lbValue ptr = lb_emit_conv(p, value_, alloc_type_pointer(type));
		return lb_emit_load(p, ptr);
	}

	lbValue tag = {};
	lbValue dst_tag = {};
	lbValue cond = {};
	lbValue data = {};

	lbValue gep0 = lb_emit_struct_ep(p, v.addr, 0);
	lbValue gep1 = lb_emit_struct_ep(p, v.addr, 1);

	if (is_type_union_maybe_pointer(src)) {
		data = lb_emit_load(p, lb_emit_conv(p, value_, gep0.type));
	} else {
		tag     = lb_emit_load(p, lb_emit_union_tag_ptr(p, value_));
		dst_tag = lb_const_union_tag(m, src, dst);
	}

	lbBlock *ok_block = lb_create_block(p, "union_cast.ok");
	lbBlock *end_block = lb_create_block(p, "union_cast.end");

	if (data.value != nullptr) {
		GB_ASSERT(is_type_union_maybe_pointer(src));
		cond = lb_emit_comp_against_nil(p, Token_NotEq, data);
	} else {
		cond = lb_emit_comp(p, Token_CmpEq, tag, dst_tag);
	}

	lb_emit_if(p, cond, ok_block, end_block);
	lb_start_block(p, ok_block);



	if (data.value == nullptr) {
		data = lb_emit_load(p, lb_emit_conv(p, value_, gep0.type));
	}
	lb_emit_store(p, gep0, data);
	lb_emit_store(p, gep1, lb_const_bool(m, t_bool, true));

	lb_emit_jump(p, end_block);
	lb_start_block(p, end_block);

	if (!is_tuple) {
		if (!build_context.no_type_assert) {
			GB_ASSERT((p->state_flags & StateFlag_no_type_assert) == 0);
			// NOTE(bill): Panic on invalid conversion
			Type *dst_type = tuple->Tuple.variables[0]->type;

			isize arg_count = 7;
			if (build_context.no_rtti) {
				arg_count = 4;
			}

			lbValue ok = lb_emit_load(p, lb_emit_struct_ep(p, v.addr, 1));
			auto args = array_make<lbValue>(permanent_allocator(), arg_count);
			args[0] = ok;

			args[1] = lb_const_string(m, get_file_path_string(pos.file_id));
			args[2] = lb_const_int(m, t_i32, pos.line);
			args[3] = lb_const_int(m, t_i32, pos.column);

			if (!build_context.no_rtti) {
				args[4] = lb_typeid(m, src_type);
				args[5] = lb_typeid(m, dst_type);
				args[6] = lb_emit_conv(p, value_, t_rawptr);
			}
			lb_emit_runtime_call(p, "type_assertion_check2", args);
		}

		return lb_emit_load(p, lb_emit_struct_ep(p, v.addr, 0));
	}
	return lb_addr_load(p, v);
}

gb_internal lbAddr lb_emit_any_cast_addr(lbProcedure *p, lbValue value, Type *type, TokenPos pos) {
	lbModule *m = p->module;

	Type *src_type = value.type;

	if (is_type_pointer(src_type)) {
		value = lb_emit_load(p, value);
	}

	bool is_tuple = true;
	Type *tuple = type;
	if (type->kind != Type_Tuple) {
		is_tuple = false;
		tuple = make_optional_ok_type(type);
	}
	Type *dst_type = tuple->Tuple.variables[0]->type;

	if ((p->state_flags & StateFlag_no_type_assert) != 0 && !is_tuple) {
		// just do a bit cast of the data at the front
		lbValue ptr = lb_emit_struct_ev(p, value, 0);
		ptr = lb_emit_conv(p, ptr, alloc_type_pointer(type));
		return lb_addr(ptr);
	}

	lbAddr v = lb_add_local_generated(p, tuple, true);

	lbValue dst_typeid = lb_typeid(m, dst_type);
	lbValue any_typeid = lb_emit_struct_ev(p, value, 1);


	lbBlock *ok_block = lb_create_block(p, "any_cast.ok");
	lbBlock *end_block = lb_create_block(p, "any_cast.end");
	lbValue cond = lb_emit_comp(p, Token_CmpEq, any_typeid, dst_typeid);
	lb_emit_if(p, cond, ok_block, end_block);
	lb_start_block(p, ok_block);

	lbValue gep0 = lb_emit_struct_ep(p, v.addr, 0);
	lbValue gep1 = lb_emit_struct_ep(p, v.addr, 1);

	lbValue any_data = lb_emit_struct_ev(p, value, 0);
	lbValue ptr = lb_emit_conv(p, any_data, alloc_type_pointer(dst_type));
	lb_emit_store(p, gep0, lb_emit_load(p, ptr));
	lb_emit_store(p, gep1, lb_const_bool(m, t_bool, true));

	lb_emit_jump(p, end_block);
	lb_start_block(p, end_block);

	if (!is_tuple) {
		// NOTE(bill): Panic on invalid conversion
		if (!build_context.no_type_assert) {
			lbValue ok = lb_emit_load(p, lb_emit_struct_ep(p, v.addr, 1));

			isize arg_count = 7;
			if (build_context.no_rtti) {
				arg_count = 4;
			}
			auto args = array_make<lbValue>(permanent_allocator(), arg_count);
			args[0] = ok;

			args[1] = lb_const_string(m, get_file_path_string(pos.file_id));
			args[2] = lb_const_int(m, t_i32, pos.line);
			args[3] = lb_const_int(m, t_i32, pos.column);

			if (!build_context.no_rtti) {
				args[4] = any_typeid;
				args[5] = dst_typeid;
				args[6] = lb_emit_struct_ev(p, value, 0);
			}
			lb_emit_runtime_call(p, "type_assertion_check2", args);
		}

		return lb_addr(lb_emit_struct_ep(p, v.addr, 0));
	}
	return v;
}
gb_internal lbValue lb_emit_any_cast(lbProcedure *p, lbValue value, Type *type, TokenPos pos) {
	return lb_addr_load(p, lb_emit_any_cast_addr(p, value, type, pos));
}



gb_internal lbAddr lb_find_or_generate_context_ptr(lbProcedure *p) {
	if (p->context_stack.count > 0) {
		return p->context_stack[p->context_stack.count-1].ctx;
	}

	Type *pt = base_type(p->type);
	GB_ASSERT(pt->kind == Type_Proc);
	GB_ASSERT(pt->Proc.calling_convention != ProcCC_Odin);

	lbAddr c = lb_add_local_generated(p, t_context, true);
	c.kind = lbAddr_Context;
	lb_emit_init_context(p, c);
	lb_push_context_onto_stack(p, c);
	lb_add_debug_context_variable(p, c);

	return c;
}

gb_internal lbValue lb_address_from_load_or_generate_local(lbProcedure *p, lbValue value) {
	if (LLVMIsALoadInst(value.value)) {
		lbValue res = {};
		res.value = LLVMGetOperand(value.value, 0);
		res.type = alloc_type_pointer(value.type);
		return res;
	}

	GB_ASSERT(is_type_typed(value.type));

	lbAddr res = lb_add_local_generated(p, value.type, false);
	lb_addr_store(p, res, value);
	return res.addr;
}
gb_internal lbValue lb_address_from_load(lbProcedure *p, lbValue value) {
	if (LLVMIsALoadInst(value.value)) {
		lbValue res = {};
		res.value = LLVMGetOperand(value.value, 0);
		res.type = alloc_type_pointer(value.type);
		return res;
	}

	GB_PANIC("lb_address_from_load");
	return {};
}

gb_internal lbValue lb_address_from_load_if_readonly_parameter(lbProcedure *p, lbValue x) {
	if (!LLVMIsALoadInst(x.value)) {
		return {};
	}

	LLVMValueRef optr = LLVMGetOperand(x.value, 0);
	while (optr && LLVMIsABitCastInst(optr)) {
		optr = LLVMGetOperand(optr, 0);
	}
	LLVMAttributeIndex param_index = 1;
	if (p->return_ptr.addr.value) {
		param_index++;
	}

	bool is_parameter = false;
	for (LLVMValueRef param : p->raw_input_parameters) {
		if (param == optr) {
			is_parameter = true;
			break;
		}
		param_index++;
	}
	if (is_parameter) {
		unsigned readonly_attr_kind = LLVMGetEnumAttributeKindForName("readonly", 8);
		unsigned n = LLVMGetAttributeCountAtIndex(p->value, param_index);
		if (n) {
			TEMPORARY_ALLOCATOR_GUARD();
			LLVMAttributeRef *attrs = gb_alloc_array(temporary_allocator(), LLVMAttributeRef, n);
			LLVMGetAttributesAtIndex(p->value, param_index, attrs);
			for (unsigned i = 0; i < n; i++) {
				if (LLVMGetEnumAttributeKind(attrs[i]) == readonly_attr_kind) {
					return lb_address_from_load_or_generate_local(p, x);
				}
			}
		}
	}
	return {};
}


gb_internal lbStructFieldRemapping lb_get_struct_remapping(lbModule *m, Type *t) {
	t = base_type(t);

	LLVMTypeRef struct_type = lb_type(m, t);

	mutex_lock(&m->types_mutex);

	auto *field_remapping = map_get(&m->struct_field_remapping, cast(void *)struct_type);
	if (field_remapping == nullptr) {
		field_remapping = map_get(&m->struct_field_remapping, cast(void *)t);
	}

	mutex_unlock(&m->types_mutex);

	GB_ASSERT_MSG(field_remapping != nullptr, "%s", type_to_string(t));
	return *field_remapping;
}

gb_internal i32 lb_convert_struct_index(lbModule *m, Type *t, i32 index) {
	if (t->kind == Type_Struct) {
		auto field_remapping = lb_get_struct_remapping(m, t);
		return field_remapping[index];
	} else if (build_context.ptr_size != build_context.int_size) {
		switch (t->kind) {
		case Type_Basic:
			if (t->Basic.kind != Basic_string) {
				break;
			}
			/*fallthrough*/
		case Type_Slice:
			GB_ASSERT(build_context.ptr_size*2 == build_context.int_size);
			switch (index) {
			case 0: return 0; // data
			case 1: return 2; // len
			}
			break;
		case Type_DynamicArray:
			GB_ASSERT(build_context.ptr_size*2 == build_context.int_size);
			switch (index) {
			case 0: return 0; // data
			case 1: return 2; // len
			case 2: return 3; // cap
			case 3: return 4; // allocator
			}
			break;
		case Type_SoaPointer:
			GB_ASSERT(build_context.ptr_size*2 == build_context.int_size);
			switch (index) {
			case 0: return 0; // data
			case 1: return 2; // offset
			}
			break;
		}
	}
	return index;
}

gb_internal LLVMTypeRef lb_type_padding_filler(lbModule *m, i64 padding, i64 padding_align) {
	// NOTE(bill): limit to `[N x u64]` to prevent ABI issues
	padding_align = gb_clamp(padding_align, 1, 8);
	if (padding % padding_align == 0) {
		LLVMTypeRef elem = nullptr;
		isize len = padding/padding_align;
		switch (padding_align) {
		case 1: elem = lb_type(m, t_u8);  break;
		case 2: elem = lb_type(m, t_u16); break;
		case 4: elem = lb_type(m, t_u32); break;
		case 8: elem = lb_type(m, t_u64); break;
		}
		
		GB_ASSERT_MSG(elem != nullptr, "Invalid lb_type_padding_filler padding and padding_align: %lld", padding_align);
		if (len != 1) {
			return llvm_array_type(elem, len);
		} else {
			return elem;
		}
	} else {
		return llvm_array_type(lb_type(m, t_u8), padding);
	}
}


gb_global char const *llvm_type_kinds[] = {
	"LLVMVoidTypeKind",
	"LLVMHalfTypeKind",
	"LLVMFloatTypeKind",
	"LLVMDoubleTypeKind",
	"LLVMX86_FP80TypeKind",
	"LLVMFP128TypeKind",
	"LLVMPPC_FP128TypeKind",
	"LLVMLabelTypeKind",
	"LLVMIntegerTypeKind",
	"LLVMFunctionTypeKind",
	"LLVMStructTypeKind",
	"LLVMArrayTypeKind",
	"LLVMPointerTypeKind",
	"LLVMVectorTypeKind",
	"LLVMMetadataTypeKind",
	"LLVMX86_MMXTypeKind",
	"LLVMTokenTypeKind",
	"LLVMScalableVectorTypeKind",
	"LLVMBFloatTypeKind",
};

gb_internal lbValue lb_emit_struct_ep_internal(lbProcedure *p, lbValue s, i32 index, Type *result_type) {
	Type *t = base_type(type_deref(s.type));

	i32 original_index = index;
	index = lb_convert_struct_index(p->module, t, index);

	if (lb_is_const(s)) {
		// NOTE(bill): this cannot be replaced with lb_emit_epi
		lbModule *m = p->module;
		lbValue res = {};
		LLVMValueRef indices[2] = {llvm_zero(m), LLVMConstInt(lb_type(m, t_i32), index, false)};
		res.value = LLVMConstGEP2(lb_type(m, type_deref(s.type)), s.value, indices, gb_count_of(indices));
		res.type = alloc_type_pointer(result_type);
		return res;
	} else {
		lbValue res = {};
		LLVMTypeRef st = lb_type(p->module, type_deref(s.type));
		// gb_printf_err("%s\n", type_to_string(s.type));
		// gb_printf_err("%s\n", LLVMPrintTypeToString(LLVMTypeOf(s.value)));
		// gb_printf_err("%d\n", index);
		GB_ASSERT_MSG(LLVMGetTypeKind(st) == LLVMStructTypeKind, "%s", llvm_type_kinds[LLVMGetTypeKind(st)]);
		unsigned count = LLVMCountStructElementTypes(st);
		GB_ASSERT_MSG(count >= cast(unsigned)index, "%u %d %d", count, index, original_index);

		res.value = LLVMBuildStructGEP2(p->builder, st, s.value, cast(unsigned)index, "");
		res.type = alloc_type_pointer(result_type);
		return res;
	}
}

gb_internal lbValue lb_emit_tuple_ep(lbProcedure *p, lbValue ptr, i32 index) {
	Type *t = type_deref(ptr.type);
	GB_ASSERT(is_type_tuple(t));
	Type *result_type = t->Tuple.variables[index]->type;

	lbValue res = {};
	lbTupleFix *tf = map_get(&p->tuple_fix_map, ptr.value);
	if (tf) {
		res = tf->values[index];
		GB_ASSERT(are_types_identical(res.type, result_type));
		res = lb_address_from_load_or_generate_local(p, res);
	} else {
		res = lb_emit_struct_ep_internal(p, ptr, index, result_type);
	}
	return res;
}


gb_internal lbValue lb_emit_struct_ep(lbProcedure *p, lbValue s, i32 index) {
	GB_ASSERT(is_type_pointer(s.type));
	Type *t = base_type(type_deref(s.type));
	Type *result_type = nullptr;

	if (is_type_relative_pointer(t)) {
		s = lb_addr_get_ptr(p, lb_addr(s));
	}

	if (is_type_struct(t)) {
		result_type = get_struct_field_type(t, index);
	} else if (is_type_union(t)) {
		GB_ASSERT(index == -1);
		return lb_emit_union_tag_ptr(p, s);
	} else if (is_type_tuple(t)) {
		return lb_emit_tuple_ep(p, s, index);
	} else if (is_type_complex(t)) {
		Type *ft = base_complex_elem_type(t);
		switch (index) {
		case 0: result_type = ft; break;
		case 1: result_type = ft; break;
		}
	} else if (is_type_quaternion(t)) {
		Type *ft = base_complex_elem_type(t);
		switch (index) {
		case 0: result_type = ft; break;
		case 1: result_type = ft; break;
		case 2: result_type = ft; break;
		case 3: result_type = ft; break;
		}
	} else if (is_type_slice(t)) {
		switch (index) {
		case 0: result_type = alloc_type_pointer(t->Slice.elem); break;
		case 1: result_type = t_int; break;
		}
	} else if (is_type_string(t)) {
		switch (index) {
		case 0: result_type = t_u8_ptr; break;
		case 1: result_type = t_int;    break;
		}
	} else if (is_type_any(t)) {
		switch (index) {
		case 0: result_type = t_rawptr; break;
		case 1: result_type = t_typeid; break;
		}
	} else if (is_type_dynamic_array(t)) {
		switch (index) {
		case 0: result_type = alloc_type_pointer(t->DynamicArray.elem); break;
		case 1: result_type = t_int;       break;
		case 2: result_type = t_int;       break;
		case 3: result_type = t_allocator; break;
		}
	} else if (is_type_map(t)) {
		init_map_internal_debug_types(t);
		Type *itp = alloc_type_pointer(t_raw_map);
		s = lb_emit_transmute(p, s, itp);

		switch (index) {
		case 0: result_type = get_struct_field_type(t_raw_map, 0); break;
		case 1: result_type = get_struct_field_type(t_raw_map, 1); break;
		case 2: result_type = get_struct_field_type(t_raw_map, 2); break;
		}
	} else if (is_type_array(t)) {
		return lb_emit_array_epi(p, s, index);
	} else if (is_type_soa_pointer(t)) {
		switch (index) {
		case 0: result_type = alloc_type_pointer(t->SoaPointer.elem); break;
		case 1: result_type = t_int; break;
		}
	} else {
		GB_PANIC("TODO(bill): struct_gep type: %s, %d", type_to_string(s.type), index);
	}

	GB_ASSERT_MSG(result_type != nullptr, "%s %d", type_to_string(t), index);
	
	lbValue gep = lb_emit_struct_ep_internal(p, s, index, result_type);

	Type *bt = base_type(t);
	if (bt->kind == Type_Struct && bt->Struct.is_packed) {
		lb_set_metadata_custom_u64(p->module, gep.value, ODIN_METADATA_IS_PACKED, 1);
		GB_ASSERT(lb_get_metadata_custom_u64(p->module, gep.value, ODIN_METADATA_IS_PACKED) == 1);
	}

	return gep;
}

gb_internal lbValue lb_emit_tuple_ev(lbProcedure *p, lbValue value, i32 index) {
	Type *t = value.type;
	GB_ASSERT(is_type_tuple(t));
	Type *result_type = t->Tuple.variables[index]->type;

	lbValue res = {};
	lbTupleFix *tf = map_get(&p->tuple_fix_map, value.value);
	if (tf) {
		res = tf->values[index];
		GB_ASSERT(are_types_identical(res.type, result_type));
	} else {
		if (t->Tuple.variables.count == 1) {
			GB_ASSERT(index == 0);
			// value.type = result_type;
			return value;
		}
		if (LLVMIsALoadInst(value.value)) {
			lbValue res = {};
			res.value = LLVMGetOperand(value.value, 0);
			res.type = alloc_type_pointer(value.type);
			lbValue ptr = lb_emit_struct_ep(p, res, index);
			return lb_emit_load(p, ptr);
		}

		res.value = LLVMBuildExtractValue(p->builder, value.value, cast(unsigned)index, "");
		res.type = result_type;
	}
	return res;
}

gb_internal lbValue lb_emit_struct_ev(lbProcedure *p, lbValue s, i32 index) {
	Type *t = base_type(s.type);
	if (is_type_tuple(t)) {
		return lb_emit_tuple_ev(p, s, index);
	}

	if (LLVMIsALoadInst(s.value)) {
		lbValue res = {};
		res.value = LLVMGetOperand(s.value, 0);
		res.type = alloc_type_pointer(s.type);
		lbValue ptr = lb_emit_struct_ep(p, res, index);
		return lb_emit_load(p, ptr);
	}

	Type *result_type = nullptr;

	switch (t->kind) {
	case Type_Basic:
		switch (t->Basic.kind) {
		case Basic_string:
			switch (index) {
			case 0: result_type = t_u8_ptr; break;
			case 1: result_type = t_int;    break;
			}
			break;
		case Basic_any:
			switch (index) {
			case 0: result_type = t_rawptr; break;
			case 1: result_type = t_typeid; break;
			}
			break;
		case Basic_complex32:
		case Basic_complex64:
		case Basic_complex128:
		{
			Type *ft = base_complex_elem_type(t);
			switch (index) {
			case 0: result_type = ft; break;
			case 1: result_type = ft; break;
			}
			break;
		}
		case Basic_quaternion64:
		case Basic_quaternion128:
		case Basic_quaternion256:
		{
			Type *ft = base_complex_elem_type(t);
			switch (index) {
			case 0: result_type = ft; break;
			case 1: result_type = ft; break;
			case 2: result_type = ft; break;
			case 3: result_type = ft; break;
			}
			break;
		}
		}
		break;
	case Type_Struct:
		result_type = get_struct_field_type(t, index);
		break;
	case Type_Union:
		GB_ASSERT(index == -1);
		// return lb_emit_union_tag_value(p, s);
		GB_PANIC("lb_emit_union_tag_value");

	case Type_Tuple:
		return lb_emit_tuple_ev(p, s, index);
	case Type_Slice:
		switch (index) {
		case 0: result_type = alloc_type_pointer(t->Slice.elem); break;
		case 1: result_type = t_int; break;
		}
		break;
	case Type_DynamicArray:
		switch (index) {
		case 0: result_type = alloc_type_pointer(t->DynamicArray.elem); break;
		case 1: result_type = t_int;                                    break;
		case 2: result_type = t_int;                                    break;
		case 3: result_type = t_allocator;                              break;
		}
		break;

	case Type_Map:
		{
			init_map_internal_debug_types(t);
			switch (index) {
			case 0: result_type = get_struct_field_type(t_raw_map, 0); break;
			case 1: result_type = get_struct_field_type(t_raw_map, 1); break;
			case 2: result_type = get_struct_field_type(t_raw_map, 2); break;
			}
		}
		break;

	case Type_Array:
		result_type = t->Array.elem;
		break;

	case Type_SoaPointer:
		switch (index) {
		case 0: result_type = alloc_type_pointer(t->SoaPointer.elem); break;
		case 1: result_type = t_int; break;
		}
		break;

	default:
		GB_PANIC("TODO(bill): struct_ev type: %s, %d", type_to_string(s.type), index);
		break;
	}

	GB_ASSERT_MSG(result_type != nullptr, "%s, %d", type_to_string(s.type), index);
	
	index = lb_convert_struct_index(p->module, t, index);

	lbValue res = {};
	res.value = LLVMBuildExtractValue(p->builder, s.value, cast(unsigned)index, "");
	res.type = result_type;
	return res;
}

gb_internal lbValue lb_emit_deep_field_gep(lbProcedure *p, lbValue e, Selection sel) {
	GB_ASSERT(sel.index.count > 0);
	Type *type = type_deref(e.type);

	for_array(i, sel.index) {
		i32 index = cast(i32)sel.index[i];
		if (is_type_pointer(type)) {
			type = type_deref(type);
			e = lb_emit_load(p, e);
		}
		type = core_type(type);

		if (type->kind == Type_SoaPointer) {
			lbValue addr = lb_emit_struct_ep(p, e, 0);
			lbValue index = lb_emit_struct_ep(p, e, 1);
			addr = lb_emit_load(p, addr);
			index = lb_emit_load(p, index);

			i32 first_index = sel.index[0];
			Selection sub_sel = sel;
			sub_sel.index.data += 1;
			sub_sel.index.count -= 1;

			lbValue arr = lb_emit_struct_ep(p, addr, first_index);

			Type *t = base_type(type_deref(addr.type));
			GB_ASSERT(is_type_soa_struct(t));

			if (t->Struct.soa_kind == StructSoa_Fixed) {
				e = lb_emit_array_ep(p, arr, index);
			} else {
				e = lb_emit_ptr_offset(p, lb_emit_load(p, arr), index);
			}
		} else if (is_type_quaternion(type)) {
			e = lb_emit_struct_ep(p, e, index);
		} else if (is_type_raw_union(type)) {
			type = get_struct_field_type(type, index);
			GB_ASSERT(is_type_pointer(e.type));
			e = lb_emit_transmute(p, e, alloc_type_pointer(type));
		} else if (is_type_struct(type)) {
			type = get_struct_field_type(type, index);
			e = lb_emit_struct_ep(p, e, index);
		} else if (type->kind == Type_Union) {
			GB_ASSERT(index == -1);
			type = t_type_info_ptr;
			e = lb_emit_struct_ep(p, e, index);
		} else if (type->kind == Type_Tuple) {
			type = type->Tuple.variables[index]->type;
			e = lb_emit_struct_ep(p, e, index);
		} else if (type->kind == Type_Basic) {
			switch (type->Basic.kind) {
			case Basic_any: {
				if (index == 0) {
					type = t_rawptr;
				} else if (index == 1) {
					type = t_typeid;
				}
				e = lb_emit_struct_ep(p, e, index);
				break;
			}

			case Basic_string:
				e = lb_emit_struct_ep(p, e, index);
				break;

			default:
				GB_PANIC("un-gep-able type %s", type_to_string(type));
				break;
			}
		} else if (type->kind == Type_Slice) {
			e = lb_emit_struct_ep(p, e, index);
		} else if (type->kind == Type_DynamicArray) {
			e = lb_emit_struct_ep(p, e, index);
		} else if (type->kind == Type_Array) {
			e = lb_emit_array_epi(p, e, index);
		} else if (type->kind == Type_Map) {
			e = lb_emit_struct_ep(p, e, index);
		} else if (type->kind == Type_RelativePointer) {
			e = lb_emit_struct_ep(p, e, index);
		} else {
			GB_PANIC("un-gep-able type %s", type_to_string(type));
		}
	}

	return e;
}


gb_internal lbValue lb_emit_deep_field_ev(lbProcedure *p, lbValue e, Selection sel) {
	lbValue ptr = lb_address_from_load_or_generate_local(p, e);
	lbValue res = lb_emit_deep_field_gep(p, ptr, sel);
	return lb_emit_load(p, res);
}


gb_internal lbValue lb_emit_array_ep(lbProcedure *p, lbValue s, lbValue index) {
	Type *t = s.type;
	GB_ASSERT_MSG(is_type_pointer(t), "%s", type_to_string(t));
	Type *st = base_type(type_deref(t));
	GB_ASSERT_MSG(is_type_array(st) || is_type_enumerated_array(st) || is_type_matrix(st), "%s", type_to_string(st));
	GB_ASSERT_MSG(is_type_integer(core_type(index.type)), "%s", type_to_string(index.type));

	LLVMValueRef indices[2] = {};
	indices[0] = llvm_zero(p->module);
	indices[1] = lb_emit_conv(p, index, t_int).value;

	Type *ptr = base_array_type(st);
	lbValue res = {};

	if (LLVMIsConstant(s.value) && LLVMIsConstant(index.value)) {
		res.value = LLVMConstGEP2(lb_type(p->module, st), s.value, indices, gb_count_of(indices));
	} else {
		res.value = LLVMBuildGEP2(p->builder, lb_type(p->module, st), s.value, indices, gb_count_of(indices), "");
	}
	res.type = alloc_type_pointer(ptr);
	return res;
}

gb_internal lbValue lb_emit_array_epi(lbProcedure *p, lbValue s, isize index) {
	Type *t = s.type;
	GB_ASSERT(is_type_pointer(t));
	Type *st = base_type(type_deref(t));
	GB_ASSERT_MSG(is_type_array(st) || is_type_enumerated_array(st) || is_type_matrix(st), "%s", type_to_string(st));
	GB_ASSERT(0 <= index);
	return lb_emit_epi(p, s, index);
}
gb_internal lbValue lb_emit_array_epi(lbModule *m, lbValue s, isize index) {
	Type *t = s.type;
	GB_ASSERT(is_type_pointer(t));
	Type *st = base_type(type_deref(t));
	GB_ASSERT_MSG(is_type_array(st) || is_type_enumerated_array(st) || is_type_matrix(st), "%s", type_to_string(st));
	GB_ASSERT(0 <= index);
	return lb_emit_epi(m, s, index);
}

gb_internal lbValue lb_emit_ptr_offset(lbProcedure *p, lbValue ptr, lbValue index) {
	index = lb_emit_conv(p, index, t_int);
	LLVMValueRef indices[1] = {index.value};
	lbValue res = {};
	res.type = ptr.type;
	LLVMTypeRef type = lb_type(p->module, type_deref(res.type, true));

	if (lb_is_const(ptr) && lb_is_const(index)) {
		res.value = LLVMConstGEP2(type, ptr.value, indices, 1);
	} else {
		res.value = LLVMBuildGEP2(p->builder, type, ptr.value, indices, 1, "");
	}
	return res;
}

gb_internal lbValue lb_const_ptr_offset(lbModule *m, lbValue ptr, lbValue index) {
	LLVMValueRef indices[1] = {index.value};
	lbValue res = {};
	res.type = ptr.type;
	LLVMTypeRef type = lb_type(m, type_deref(res.type, true));

	GB_ASSERT(lb_is_const(ptr) && lb_is_const(index));
	res.value = LLVMConstGEP2(type, ptr.value, indices, 1);
	return res;
}

gb_internal lbValue lb_emit_matrix_epi(lbProcedure *p, lbValue s, isize row, isize column) {
	Type *t = s.type;
	GB_ASSERT(is_type_pointer(t));
	Type *mt = base_type(type_deref(t));

	if (!mt->Matrix.is_row_major) {
		if (column == 0) {
			GB_ASSERT_MSG(is_type_matrix(mt) || is_type_array_like(mt), "%s", type_to_string(mt));
			return lb_emit_epi(p, s, row);
		} else if (row == 0 && is_type_array_like(mt)) {
			return lb_emit_epi(p, s, column);
		}
	}
	
	GB_ASSERT_MSG(is_type_matrix(mt), "%s", type_to_string(mt));
	
	isize offset = matrix_indices_to_offset(mt, row, column);
	return lb_emit_epi(p, s, offset);
}

gb_internal lbValue lb_emit_matrix_ep(lbProcedure *p, lbValue s, lbValue row, lbValue column) {
	Type *t = s.type;
	GB_ASSERT(is_type_pointer(t));
	Type *mt = base_type(type_deref(t));
	GB_ASSERT_MSG(is_type_matrix(mt), "%s", type_to_string(mt));

	Type *ptr = base_array_type(mt);
	
	LLVMValueRef stride_elems = lb_const_int(p->module, t_int, matrix_type_stride_in_elems(mt)).value;
	
	row = lb_emit_conv(p, row, t_int);
	column = lb_emit_conv(p, column, t_int);
	
	LLVMValueRef index = nullptr;

	if (mt->Matrix.is_row_major) {
		index = LLVMBuildAdd(p->builder, column.value, LLVMBuildMul(p->builder, row.value, stride_elems, ""), "");
	} else {
		index = LLVMBuildAdd(p->builder, row.value, LLVMBuildMul(p->builder, column.value, stride_elems, ""), "");
	}

	LLVMValueRef indices[2] = {
		LLVMConstInt(lb_type(p->module, t_int), 0, false),
		index,
	};

	LLVMTypeRef type = lb_type(p->module, mt);
	lbValue res = {};
	if (lb_is_const(s)) {
		res.value = LLVMConstGEP2(type, s.value, indices, gb_count_of(indices));
	} else {
		res.value = LLVMBuildGEP2(p->builder, type, s.value, indices, gb_count_of(indices), "");
	}
	res.type = alloc_type_pointer(ptr);
	return res;
}


gb_internal lbValue lb_emit_matrix_ev(lbProcedure *p, lbValue s, isize row, isize column) {
	Type *st = base_type(s.type);
	GB_ASSERT_MSG(is_type_matrix(st), "%s", type_to_string(st));
	
	lbValue value = lb_address_from_load_or_generate_local(p, s);
	lbValue ptr = lb_emit_matrix_epi(p, value, row, column);
	return lb_emit_load(p, ptr);
}


gb_internal void lb_fill_slice(lbProcedure *p, lbAddr const &slice, lbValue base_elem, lbValue len) {
	Type *t = lb_addr_type(slice);
	GB_ASSERT(is_type_slice(t));
	lbValue ptr = lb_addr_get_ptr(p, slice);
	lb_emit_store(p, lb_emit_struct_ep(p, ptr, 0), base_elem);
	lb_emit_store(p, lb_emit_struct_ep(p, ptr, 1), len);
}
gb_internal void lb_fill_string(lbProcedure *p, lbAddr const &string, lbValue base_elem, lbValue len) {
	Type *t = lb_addr_type(string);
	GB_ASSERT(is_type_string(t));
	lbValue ptr = lb_addr_get_ptr(p, string);
	lb_emit_store(p, lb_emit_struct_ep(p, ptr, 0), base_elem);
	lb_emit_store(p, lb_emit_struct_ep(p, ptr, 1), len);
}

gb_internal lbValue lb_string_elem(lbProcedure *p, lbValue string) {
	Type *t = base_type(string.type);
	GB_ASSERT(t->kind == Type_Basic && t->Basic.kind == Basic_string);
	return lb_emit_struct_ev(p, string, 0);
}
gb_internal lbValue lb_string_len(lbProcedure *p, lbValue string) {
	Type *t = base_type(string.type);
	GB_ASSERT_MSG(t->kind == Type_Basic && t->Basic.kind == Basic_string, "%s", type_to_string(t));
	return lb_emit_struct_ev(p, string, 1);
}

gb_internal lbValue lb_cstring_len(lbProcedure *p, lbValue value) {
	GB_ASSERT(is_type_cstring(value.type));
	auto args = array_make<lbValue>(permanent_allocator(), 1);
	args[0] = lb_emit_conv(p, value, t_cstring);
	return lb_emit_runtime_call(p, "cstring_len", args);
}


gb_internal lbValue lb_array_elem(lbProcedure *p, lbValue array_ptr) {
	Type *t = type_deref(array_ptr.type);
	GB_ASSERT(is_type_array(t));
	return lb_emit_struct_ep(p, array_ptr, 0);
}

gb_internal lbValue lb_slice_elem(lbProcedure *p, lbValue slice) {
	GB_ASSERT(is_type_slice(slice.type));
	return lb_emit_struct_ev(p, slice, 0);
}
gb_internal lbValue lb_slice_len(lbProcedure *p, lbValue slice) {
	GB_ASSERT(is_type_slice(slice.type));
	return lb_emit_struct_ev(p, slice, 1);
}
gb_internal lbValue lb_dynamic_array_elem(lbProcedure *p, lbValue da) {
	GB_ASSERT(is_type_dynamic_array(da.type));
	return lb_emit_struct_ev(p, da, 0);
}
gb_internal lbValue lb_dynamic_array_len(lbProcedure *p, lbValue da) {
	GB_ASSERT(is_type_dynamic_array(da.type));
	return lb_emit_struct_ev(p, da, 1);
}
gb_internal lbValue lb_dynamic_array_cap(lbProcedure *p, lbValue da) {
	GB_ASSERT(is_type_dynamic_array(da.type));
	return lb_emit_struct_ev(p, da, 2);
}

gb_internal lbValue lb_map_len(lbProcedure *p, lbValue value) {
	GB_ASSERT_MSG(is_type_map(value.type) || are_types_identical(value.type, t_raw_map), "%s", type_to_string(value.type));
	lbValue len = lb_emit_struct_ev(p, value, 1);
	return lb_emit_conv(p, len, t_int);
}
gb_internal lbValue lb_map_len_ptr(lbProcedure *p, lbValue map_ptr) {
	Type *type = map_ptr.type;
	GB_ASSERT(is_type_pointer(type));
	type = type_deref(type);
	GB_ASSERT_MSG(is_type_map(type) || are_types_identical(type, t_raw_map), "%s", type_to_string(type));
	return lb_emit_struct_ep(p, map_ptr, 1);
}

gb_internal lbValue lb_map_cap(lbProcedure *p, lbValue value) {
	GB_ASSERT_MSG(is_type_map(value.type) || are_types_identical(value.type, t_raw_map), "%s", type_to_string(value.type));
	lbValue zero = lb_const_int(p->module, t_uintptr, 0);
	lbValue one = lb_const_int(p->module, t_uintptr, 1);

	lbValue mask = lb_const_int(p->module, t_uintptr, MAP_CACHE_LINE_SIZE-1);

	lbValue data = lb_emit_struct_ev(p, value, 0);
	lbValue log2_cap = lb_emit_arith(p, Token_And, data, mask, t_uintptr);
	lbValue cap = lb_emit_arith(p, Token_Shl, one, log2_cap, t_uintptr);
	lbValue cmp = lb_emit_comp(p, Token_CmpEq, data, zero);
	return lb_emit_conv(p, lb_emit_select(p, cmp, zero, cap), t_int);
}

gb_internal lbValue lb_map_data_uintptr(lbProcedure *p, lbValue value) {
	GB_ASSERT(is_type_map(value.type) || are_types_identical(value.type, t_raw_map));
	lbValue data = lb_emit_struct_ev(p, value, 0);
	u64 mask_value = 0;
	if (build_context.ptr_size == 4) {
		mask_value = 0xfffffffful & ~(MAP_CACHE_LINE_SIZE-1);
	} else {
		mask_value = 0xffffffffffffffffull & ~(MAP_CACHE_LINE_SIZE-1);
	}
	lbValue mask = lb_const_int(p->module, t_uintptr, mask_value);
	return lb_emit_arith(p, Token_And, data, mask, t_uintptr);
}


gb_internal lbValue lb_soa_struct_len(lbProcedure *p, lbValue value) {
	Type *t = base_type(value.type);
	bool is_ptr = false;
	if (is_type_pointer(t)) {
		is_ptr = true;
		t = base_type(type_deref(t));
	}


	if (t->Struct.soa_kind == StructSoa_Fixed) {
		return lb_const_int(p->module, t_int, t->Struct.soa_count);
	}

	GB_ASSERT(t->Struct.soa_kind == StructSoa_Slice ||
	          t->Struct.soa_kind == StructSoa_Dynamic);

	isize n = 0;
	Type *elem = base_type(t->Struct.soa_elem);
	if (elem->kind == Type_Struct) {
		n = cast(isize)elem->Struct.fields.count;
	} else if (elem->kind == Type_Array) {
		n = cast(isize)elem->Array.count;
	} else {
		GB_PANIC("Unreachable");
	}

	if (is_ptr) {
		lbValue v = lb_emit_struct_ep(p, value, cast(i32)n);
		return lb_emit_load(p, v);
	}
	return lb_emit_struct_ev(p, value, cast(i32)n);
}

gb_internal lbValue lb_soa_struct_cap(lbProcedure *p, lbValue value) {
	Type *t = base_type(value.type);

	bool is_ptr = false;
	if (is_type_pointer(t)) {
		is_ptr = true;
		t = base_type(type_deref(t));
	}

	if (t->Struct.soa_kind == StructSoa_Fixed) {
		return lb_const_int(p->module, t_int, t->Struct.soa_count);
	}

	GB_ASSERT(t->Struct.soa_kind == StructSoa_Dynamic);

	isize n = 0;
	Type *elem = base_type(t->Struct.soa_elem);
	if (elem->kind == Type_Struct) {
		n = cast(isize)elem->Struct.fields.count+1;
	} else if (elem->kind == Type_Array) {
		n = cast(isize)elem->Array.count+1;
	} else {
		GB_PANIC("Unreachable");
	}

	if (is_ptr) {
		lbValue v = lb_emit_struct_ep(p, value, cast(i32)n);
		return lb_emit_load(p, v);
	}
	return lb_emit_struct_ev(p, value, cast(i32)n);
}

gb_internal lbValue lb_emit_mul_add(lbProcedure *p, lbValue a, lbValue b, lbValue c, Type *t) {
	lbModule *m = p->module;
	
	a = lb_emit_conv(p, a, t);
	b = lb_emit_conv(p, b, t);
	c = lb_emit_conv(p, c, t);
	
	bool is_possible = !is_type_different_to_arch_endianness(t) && is_type_float(t);
	
	if (is_possible) {
		switch (build_context.metrics.arch) {
		case TargetArch_amd64:
			// NOTE: using the intrinsic when not supported causes slow codegen (See #2928).
			if (type_size_of(t) == 2 || !check_target_feature_is_enabled(str_lit("fma"), nullptr)) {
				is_possible = false;
			}
			break;
		case TargetArch_arm64:
			// possible
			break;
		case TargetArch_i386:
		case TargetArch_wasm32:
		case TargetArch_wasm64p32:
			is_possible = false;
			break;
		}
	}

	if (is_possible) {
		char const *name = "llvm.fma";
		LLVMTypeRef types[1] = { lb_type(m, t) };
		LLVMValueRef values[3] = {
				a.value,
				b.value,
				c.value };
		LLVMValueRef call = lb_call_intrinsic(p, name, values, gb_count_of(values), types, gb_count_of(types));
		return {call, t};
	} else {
		lbValue x = lb_emit_arith(p, Token_Mul, a, b, t);
		lbValue y = lb_emit_arith(p, Token_Add, x, c, t);
		return y;
	}
}

gb_internal LLVMValueRef llvm_mask_iota(lbModule *m, unsigned start, unsigned count) {
	auto iota = slice_make<LLVMValueRef>(temporary_allocator(), count);
	for (unsigned i = 0; i < count; i++) {
		iota[i] = lb_const_int(m, t_u32, start+i).value;
	}
	return LLVMConstVector(iota.data, count);
}

gb_internal LLVMValueRef llvm_mask_zero(lbModule *m, unsigned count) {
	return LLVMConstNull(LLVMVectorType(lb_type(m, t_u32), count));
}

#define LLVM_VECTOR_DUMMY_VALUE(type) LLVMGetUndef((type))
// #define LLVM_VECTOR_DUMMY_VALUE(type) LLVMConstNull((type))


gb_internal LLVMValueRef llvm_basic_shuffle(lbProcedure *p, LLVMValueRef vector, LLVMValueRef mask) {
	return LLVMBuildShuffleVector(p->builder, vector, LLVM_VECTOR_DUMMY_VALUE(LLVMTypeOf(vector)), mask, "");
}
gb_internal LLVMValueRef llvm_basic_const_shuffle(LLVMValueRef vector, LLVMValueRef mask) {
	return LLVMConstShuffleVector(vector, LLVM_VECTOR_DUMMY_VALUE(LLVMTypeOf(vector)), mask);
}



gb_internal LLVMValueRef llvm_vector_broadcast(lbProcedure *p, LLVMValueRef value, unsigned count) {
	GB_ASSERT(count > 0);
	if (LLVMIsConstant(value)) {
		LLVMValueRef single = LLVMConstVector(&value, 1);
		if (count == 1) {
			return single;
		}
		LLVMValueRef mask = llvm_mask_zero(p->module, count);
		return llvm_basic_const_shuffle(single, mask);
	}
	
	LLVMTypeRef single_type = LLVMVectorType(LLVMTypeOf(value), 1);
	LLVMValueRef single = LLVMBuildBitCast(p->builder, value, single_type, "");
	if (count == 1) {
		return single;
	}
	LLVMValueRef mask = llvm_mask_zero(p->module, count);
	return llvm_basic_shuffle(p, single, mask);
}

gb_internal LLVMValueRef llvm_vector_shuffle_reduction(lbProcedure *p, LLVMValueRef value, LLVMOpcode op_code) {
	LLVMTypeRef original_vector_type = LLVMTypeOf(value);
	
	GB_ASSERT(LLVMGetTypeKind(original_vector_type) == LLVMVectorTypeKind);
	unsigned len = LLVMGetVectorSize(original_vector_type);
	
	LLVMValueRef v_zero32 = lb_const_int(p->module, t_u32, 0).value;
	if (len == 1) {
		return LLVMBuildExtractElement(p->builder, value, v_zero32, "");
	}
	GB_ASSERT((len & (len-1)) == 0);
	
	for (unsigned i = len; i != 1; i >>= 1) {
		unsigned mask_len = i/2;
		LLVMValueRef lhs_mask = llvm_mask_iota(p->module, 0, mask_len);
		LLVMValueRef rhs_mask = llvm_mask_iota(p->module, mask_len, mask_len);
		GB_ASSERT(LLVMTypeOf(lhs_mask) == LLVMTypeOf(rhs_mask));

		LLVMValueRef lhs = llvm_basic_shuffle(p, value, lhs_mask);
		LLVMValueRef rhs = llvm_basic_shuffle(p, value, rhs_mask);
		GB_ASSERT(LLVMTypeOf(lhs) == LLVMTypeOf(rhs));
		
		value = LLVMBuildBinOp(p->builder, op_code, lhs, rhs, "");
	}
	return LLVMBuildExtractElement(p->builder, value, v_zero32, "");
}

gb_internal LLVMValueRef llvm_vector_expand_to_power_of_two(lbProcedure *p, LLVMValueRef value) {
	LLVMTypeRef vector_type = LLVMTypeOf(value);
	unsigned len = LLVMGetVectorSize(vector_type);
	if (len == 1) {
		return value;
	}
	if ((len & (len-1)) == 0) {
		return value;
	}
	
	unsigned expanded_len = cast(unsigned)next_pow2(cast(i64)len);
	LLVMValueRef mask = llvm_mask_iota(p->module, 0, expanded_len);
	return LLVMBuildShuffleVector(p->builder, value, LLVMConstNull(vector_type), mask, "");
}

gb_internal LLVMValueRef llvm_vector_reduce_add(lbProcedure *p, LLVMValueRef value) {
	LLVMTypeRef type = LLVMTypeOf(value);
	GB_ASSERT(LLVMGetTypeKind(type) == LLVMVectorTypeKind);
	LLVMTypeRef elem = OdinLLVMGetVectorElementType(type);
	unsigned len = LLVMGetVectorSize(type);
	if (len == 0) {
		return LLVMConstNull(type);
	}

	char const *name = nullptr;
	i32 value_offset = 0;
	i32 value_count  = 0;

	switch (LLVMGetTypeKind(elem)) {
	case LLVMHalfTypeKind:
	case LLVMFloatTypeKind:
	case LLVMDoubleTypeKind:
		name = "llvm.vector.reduce.fadd";
		value_offset = 0;
		value_count = 2;
		break;
	case LLVMIntegerTypeKind:
		name = "llvm.vector.reduce.add";
		value_offset = 1;
		value_count = 1;
		break;
	default:
		GB_PANIC("invalid vector type %s", LLVMPrintTypeToString(type));
		break;
	}

	unsigned id = LLVMLookupIntrinsicID(name, gb_strlen(name));
	if (id != 0 && false) {
		LLVMTypeRef types[1] = { type };
		LLVMValueRef values[2] = { LLVMConstNull(elem), value };
		return lb_call_intrinsic(p, name, values + value_offset, value_count, types, gb_count_of(types));
	}

	// Manual reduce
#if 0
	LLVMValueRef sum = LLVMBuildExtractElement(p->builder, value, lb_const_int(p->module, t_u32, 0).value, "");
	for (unsigned i = 0; i < len; i++) {
		LLVMValueRef val = LLVMBuildExtractElement(p->builder, value, lb_const_int(p->module, t_u32, i).value, "");
		if (LLVMGetTypeKind(elem) == LLVMIntegerTypeKind) {
			sum = LLVMBuildAdd(p->builder, sum, val, "");
		} else {
			sum = LLVMBuildFAdd(p->builder, sum, val, "");
		}
	}
	return sum;
#else
	LLVMOpcode op_code = LLVMFAdd;
	if (LLVMGetTypeKind(elem) == LLVMIntegerTypeKind) {
		op_code = LLVMAdd;
	}

	unsigned len_pow_2 = prev_pow2(len);
	if (len_pow_2 == len) {
		return llvm_vector_shuffle_reduction(p, value, op_code);
	} else {
		GB_ASSERT(len_pow_2 < len);
		LLVMValueRef lower_mask = llvm_mask_iota(p->module, 0, len_pow_2);
		LLVMValueRef upper_mask = llvm_mask_iota(p->module, len_pow_2, len-len_pow_2);
		LLVMValueRef lower = llvm_basic_shuffle(p, value, lower_mask);
		LLVMValueRef upper = llvm_basic_shuffle(p, value, upper_mask);
		upper = llvm_vector_expand_to_power_of_two(p, upper);

		LLVMValueRef lower_reduced = llvm_vector_shuffle_reduction(p, lower, op_code);
		LLVMValueRef upper_reduced = llvm_vector_shuffle_reduction(p, upper, op_code);
		GB_ASSERT(LLVMTypeOf(lower_reduced) == LLVMTypeOf(upper_reduced));

		return LLVMBuildBinOp(p->builder, op_code, lower_reduced, upper_reduced, "");
	}
#endif
}

gb_internal LLVMValueRef llvm_vector_add(lbProcedure *p, LLVMValueRef a, LLVMValueRef b) {
	GB_ASSERT(LLVMTypeOf(a) == LLVMTypeOf(b));
	
	LLVMTypeRef elem = OdinLLVMGetVectorElementType(LLVMTypeOf(a));
	
	if (LLVMGetTypeKind(elem) == LLVMIntegerTypeKind) {
		return LLVMBuildAdd(p->builder, a, b, "");
	}
	return LLVMBuildFAdd(p->builder, a, b, "");
}

gb_internal LLVMValueRef llvm_vector_mul(lbProcedure *p, LLVMValueRef a, LLVMValueRef b) {
	GB_ASSERT(LLVMTypeOf(a) == LLVMTypeOf(b));
	
	LLVMTypeRef elem = OdinLLVMGetVectorElementType(LLVMTypeOf(a));
	
	if (LLVMGetTypeKind(elem) == LLVMIntegerTypeKind) {
		return LLVMBuildMul(p->builder, a, b, "");
	}
	return LLVMBuildFMul(p->builder, a, b, "");
}


gb_internal LLVMValueRef llvm_vector_dot(lbProcedure *p, LLVMValueRef a, LLVMValueRef b) {
	return llvm_vector_reduce_add(p, llvm_vector_mul(p, a, b));
}

gb_internal LLVMValueRef llvm_vector_mul_add(lbProcedure *p, LLVMValueRef a, LLVMValueRef b, LLVMValueRef c) {

	LLVMTypeRef t = LLVMTypeOf(a);
	GB_ASSERT(t == LLVMTypeOf(b));
	GB_ASSERT(t == LLVMTypeOf(c));
	GB_ASSERT(LLVMGetTypeKind(t) == LLVMVectorTypeKind);
	
	LLVMTypeRef elem = OdinLLVMGetVectorElementType(t);
	
	bool is_possible = false;
	
	switch (LLVMGetTypeKind(elem)) {
	case LLVMHalfTypeKind:
		is_possible = true;
		break;
	case LLVMFloatTypeKind:
	case LLVMDoubleTypeKind:
		is_possible = true;
		break;
	}

	if (is_possible) {
		char const *name = "llvm.fmuladd";
		LLVMTypeRef types[1] = { t };
		LLVMValueRef values[3] = { a, b, c};
		LLVMValueRef call = lb_call_intrinsic(p, name, values, gb_count_of(values), types, gb_count_of(types));
		return call;
	} else {
		LLVMValueRef x = llvm_vector_mul(p, a, b);
		LLVMValueRef y = llvm_vector_add(p, x, c);
		return y;
	}
}

gb_internal LLVMValueRef llvm_get_inline_asm(LLVMTypeRef func_type, String const &str, String const &clobbers, bool has_side_effects=true, bool is_align_stack=false, LLVMInlineAsmDialect dialect=LLVMInlineAsmDialectATT) {
	return LLVMGetInlineAsm(func_type,
		cast(char *)str.text, cast(size_t)str.len,
		cast(char *)clobbers.text, cast(size_t)clobbers.len,
		has_side_effects, is_align_stack,
		dialect
	#if LLVM_VERSION_MAJOR >= 13
		, /*CanThrow*/false
	#endif
	);
}


gb_internal void lb_set_wasm_import_attributes(LLVMValueRef value, Entity *entity, String import_name) {
	if (!is_arch_wasm()) {
		return;
	}
	String module_name = str_lit("env");
	if (entity->Procedure.foreign_library != nullptr) {
		Entity *foreign_library = entity->Procedure.foreign_library;
		GB_ASSERT(foreign_library->kind == Entity_LibraryName);
		GB_ASSERT(foreign_library->LibraryName.paths.count == 1);
		
		module_name = foreign_library->LibraryName.paths[0];
		
		if (string_starts_with(import_name, module_name)) {
			import_name = substring(import_name, module_name.len+WASM_MODULE_NAME_SEPARATOR.len, import_name.len);
		}
		
	}
	LLVMAddTargetDependentFunctionAttr(value, "wasm-import-module", alloc_cstring(permanent_allocator(), module_name));
	LLVMAddTargetDependentFunctionAttr(value, "wasm-import-name",   alloc_cstring(permanent_allocator(), import_name));
}


gb_internal void lb_set_wasm_export_attributes(LLVMValueRef value, String export_name) {
	if (!is_arch_wasm()) {
		return;
	}
	LLVMSetLinkage(value, LLVMDLLExportLinkage);
	LLVMSetDLLStorageClass(value, LLVMDLLExportStorageClass);
	LLVMSetVisibility(value, LLVMDefaultVisibility);
	LLVMAddTargetDependentFunctionAttr(value, "wasm-export-name",   alloc_cstring(permanent_allocator(), export_name));
}



gb_internal lbAddr lb_handle_objc_find_or_register_selector(lbProcedure *p, String const &name) {
	lbAddr *found = string_map_get(&p->module->objc_selectors, name);
	if (found) {
		return *found;
	} else {
		lbModule *default_module = &p->module->gen->default_module;
		Entity *e = nullptr;
		lbAddr default_addr = lb_add_global_generated(default_module, t_objc_SEL, {}, &e);

		lbValue ptr = lb_find_value_from_entity(p->module, e);
		lbAddr local_addr = lb_addr(ptr);

		string_map_set(&default_module->objc_selectors, name, default_addr);
		if (default_module != p->module) {
			string_map_set(&p->module->objc_selectors, name, local_addr);
		}
		return local_addr;
	}
}

gb_internal lbValue lb_handle_objc_find_selector(lbProcedure *p, Ast *expr) {
	ast_node(ce, CallExpr, expr);

	auto tav = ce->args[0]->tav;
	GB_ASSERT(tav.value.kind == ExactValue_String);
	String name = tav.value.value_string;
	return lb_addr_load(p, lb_handle_objc_find_or_register_selector(p, name));
}

gb_internal lbValue lb_handle_objc_register_selector(lbProcedure *p, Ast *expr) {
	ast_node(ce, CallExpr, expr);
	lbModule *m = p->module;

	auto tav = ce->args[0]->tav;
	GB_ASSERT(tav.value.kind == ExactValue_String);
	String name = tav.value.value_string;
	lbAddr dst = lb_handle_objc_find_or_register_selector(p, name);

	auto args = array_make<lbValue>(permanent_allocator(), 1);
	args[0] = lb_const_value(m, t_cstring, exact_value_string(name));
	lbValue ptr = lb_emit_runtime_call(p, "sel_registerName", args);
	lb_addr_store(p, dst, ptr);

	return lb_addr_load(p, dst);
}

gb_internal lbAddr lb_handle_objc_find_or_register_class(lbProcedure *p, String const &name) {
	lbAddr *found = string_map_get(&p->module->objc_classes, name);
	if (found) {
		return *found;
	} else {
		lbModule *default_module = &p->module->gen->default_module;
		Entity *e = nullptr;
		lbAddr default_addr = lb_add_global_generated(default_module, t_objc_SEL, {}, &e);

		lbValue ptr = lb_find_value_from_entity(p->module, e);
		lbAddr local_addr = lb_addr(ptr);

		string_map_set(&default_module->objc_classes, name, default_addr);
		if (default_module != p->module) {
			string_map_set(&p->module->objc_classes, name, local_addr);
		}
		return local_addr;
	}
}

gb_internal lbValue lb_handle_objc_find_class(lbProcedure *p, Ast *expr) {
	ast_node(ce, CallExpr, expr);

	auto tav = ce->args[0]->tav;
	GB_ASSERT(tav.value.kind == ExactValue_String);
	String name = tav.value.value_string;
	return lb_addr_load(p, lb_handle_objc_find_or_register_class(p, name));
}

gb_internal lbValue lb_handle_objc_register_class(lbProcedure *p, Ast *expr) {
	ast_node(ce, CallExpr, expr);
	lbModule *m = p->module;

	auto tav = ce->args[0]->tav;
	GB_ASSERT(tav.value.kind == ExactValue_String);
	String name = tav.value.value_string;
	lbAddr dst = lb_handle_objc_find_or_register_class(p, name);

	auto args = array_make<lbValue>(permanent_allocator(), 3);
	args[0] = lb_const_nil(m, t_objc_Class);
	args[1] = lb_const_nil(m, t_objc_Class);
	args[2] = lb_const_int(m, t_uint, 0);
	lbValue ptr = lb_emit_runtime_call(p, "objc_allocateClassPair", args);
	lb_addr_store(p, dst, ptr);

	return lb_addr_load(p, dst);
}


gb_internal lbValue lb_handle_objc_id(lbProcedure *p, Ast *expr) {
	TypeAndValue const &tav = type_and_value_of_expr(expr);
	if (tav.mode == Addressing_Type) {
		Type *type = tav.type;
		GB_ASSERT_MSG(type->kind == Type_Named, "%s", type_to_string(type));
		Entity *e = type->Named.type_name;
		GB_ASSERT(e->kind == Entity_TypeName);
		String name = e->TypeName.objc_class_name;

		lbAddr *found = string_map_get(&p->module->objc_classes, name);
		if (found) {
			return lb_addr_load(p, *found);
		} else {
			lbModule *default_module = &p->module->gen->default_module;
			Entity *e = nullptr;
			lbAddr default_addr = lb_add_global_generated(default_module, t_objc_Class, {}, &e);

			lbValue ptr = lb_find_value_from_entity(p->module, e);
			lbAddr local_addr = lb_addr(ptr);

			string_map_set(&default_module->objc_classes, name, default_addr);
			if (default_module != p->module) {
				string_map_set(&p->module->objc_classes, name, local_addr);
			}
			return lb_addr_load(p, local_addr);
		}
	}

	return lb_build_expr(p, expr);
}

gb_internal lbValue lb_handle_objc_send(lbProcedure *p, Ast *expr) {
	ast_node(ce, CallExpr, expr);

	lbModule *m = p->module;
	CheckerInfo *info = m->info;
	ObjcMsgData data = map_must_get(&info->objc_msgSend_types, expr);
	GB_ASSERT(data.proc_type != nullptr);

	GB_ASSERT(ce->args.count >= 3);
	auto args = array_make<lbValue>(permanent_allocator(), 0, ce->args.count-1);

	lbValue id = lb_handle_objc_id(p, ce->args[1]);
	Ast *sel_expr = ce->args[2];
	GB_ASSERT(sel_expr->tav.value.kind == ExactValue_String);
	lbValue sel = lb_addr_load(p, lb_handle_objc_find_or_register_selector(p, sel_expr->tav.value.value_string));

	array_add(&args, id);
	array_add(&args, sel);
	for (isize i = 3; i < ce->args.count; i++) {
		lbValue arg = lb_build_expr(p, ce->args[i]);
		array_add(&args, arg);
	}


	lbValue the_proc = {};
	switch (data.kind) {
	default:
		GB_PANIC("unhandled ObjcMsgKind %u", data.kind);
		break;
	case ObjcMsg_normal: the_proc = lb_lookup_runtime_procedure(m, str_lit("objc_msgSend"));        break;
	case ObjcMsg_fpret:  the_proc = lb_lookup_runtime_procedure(m, str_lit("objc_msgSend_fpret"));  break;
	case ObjcMsg_fp2ret: the_proc = lb_lookup_runtime_procedure(m, str_lit("objc_msgSend_fp2ret")); break;
	case ObjcMsg_stret:  the_proc = lb_lookup_runtime_procedure(m, str_lit("objc_msgSend_stret"));  break;
	}

	the_proc = lb_emit_conv(p, the_proc, data.proc_type);

	return lb_emit_call(p, the_proc, args);
}




gb_internal LLVMAtomicOrdering llvm_atomic_ordering_from_odin(ExactValue const &value) {
	GB_ASSERT(value.kind == ExactValue_Integer);
	i64 v = exact_value_to_i64(value);
	switch (v) {
	case OdinAtomicMemoryOrder_relaxed: return LLVMAtomicOrderingUnordered;
	case OdinAtomicMemoryOrder_consume: return LLVMAtomicOrderingMonotonic;
	case OdinAtomicMemoryOrder_acquire: return LLVMAtomicOrderingAcquire;
	case OdinAtomicMemoryOrder_release: return LLVMAtomicOrderingRelease;
	case OdinAtomicMemoryOrder_acq_rel: return LLVMAtomicOrderingAcquireRelease;
	case OdinAtomicMemoryOrder_seq_cst: return LLVMAtomicOrderingSequentiallyConsistent;
	}
	GB_PANIC("Unknown atomic ordering");
	return LLVMAtomicOrderingSequentiallyConsistent;
}


gb_internal LLVMAtomicOrdering llvm_atomic_ordering_from_odin(Ast *expr) {
	ExactValue value = type_and_value_of_expr(expr).value;
	return llvm_atomic_ordering_from_odin(value);
}
