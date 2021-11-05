bool lb_is_type_aggregate(Type *t) {
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


lbValue lb_correct_endianness(lbProcedure *p, lbValue value) {
	Type *src = core_type(value.type);
	GB_ASSERT(is_type_integer(src) || is_type_float(src));
	if (is_type_different_to_arch_endianness(src)) {
		Type *platform_src_type = integer_endian_type_to_platform_type(src);
		value = lb_emit_byte_swap(p, value, platform_src_type);
	}
	return value;
}

void lb_mem_zero_ptr_internal(lbProcedure *p, LLVMValueRef ptr, LLVMValueRef len, unsigned alignment, bool is_volatile) {
	bool is_inlinable = false;

	i64 const_len = 0;
	if (LLVMIsConstant(len)) {
		const_len = cast(i64)LLVMConstIntGetSExtValue(len);
		// TODO(bill): Determine when it is better to do the `*.inline` versions
		if (const_len <= 4*build_context.word_size) {
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
	unsigned id = LLVMLookupIntrinsicID(name, gb_strlen(name));
	GB_ASSERT_MSG(id != 0, "Unable to find %s.%s.%s", name, LLVMPrintTypeToString(types[0]), LLVMPrintTypeToString(types[1]));
	LLVMValueRef ip = LLVMGetIntrinsicDeclaration(p->module->mod, id, types, gb_count_of(types));

	LLVMValueRef args[4] = {};
	args[0] = LLVMBuildPointerCast(p->builder, ptr, types[0], "");
	args[1] = LLVMConstInt(LLVMInt8TypeInContext(p->module->ctx), 0, false);
	args[2] = LLVMBuildIntCast2(p->builder, len, types[1], /*signed*/false, "");
	args[3] = LLVMConstInt(LLVMInt1TypeInContext(p->module->ctx), is_volatile, false);

	LLVMBuildCall(p->builder, ip, args, gb_count_of(args), "");
}

void lb_mem_zero_ptr(lbProcedure *p, LLVMValueRef ptr, Type *type, unsigned alignment) {
	LLVMTypeRef llvm_type = lb_type(p->module, type);

	LLVMTypeKind kind = LLVMGetTypeKind(llvm_type);

	switch (kind) {
	case LLVMStructTypeKind:
	case LLVMArrayTypeKind:
		{
			// NOTE(bill): Enforce zeroing through memset to make sure padding is zeroed too
			i32 sz = cast(i32)type_size_of(type);
			lb_mem_zero_ptr_internal(p, ptr, lb_const_int(p->module, t_int, sz).value, alignment, false);
		}
		break;
	default:
		LLVMBuildStore(p->builder, LLVMConstNull(lb_type(p->module, type)), ptr);
		break;
	}
}

lbValue lb_emit_select(lbProcedure *p, lbValue cond, lbValue x, lbValue y) {
	cond = lb_emit_conv(p, cond, t_llvm_bool);
	lbValue res = {};
	res.value = LLVMBuildSelect(p->builder, cond.value, x.value, y.value, "");
	res.type = x.type;
	return res;
}

lbValue lb_emit_min(lbProcedure *p, Type *t, lbValue x, lbValue y) {
	x = lb_emit_conv(p, x, t);
	y = lb_emit_conv(p, y, t);
	return lb_emit_select(p, lb_emit_comp(p, Token_Lt, x, y), x, y);
}
lbValue lb_emit_max(lbProcedure *p, Type *t, lbValue x, lbValue y) {
	x = lb_emit_conv(p, x, t);
	y = lb_emit_conv(p, y, t);
	return lb_emit_select(p, lb_emit_comp(p, Token_Gt, x, y), x, y);
}


lbValue lb_emit_clamp(lbProcedure *p, Type *t, lbValue x, lbValue min, lbValue max) {
	lbValue z = {};
	z = lb_emit_max(p, t, x, min);
	z = lb_emit_min(p, t, z, max);
	return z;
}



lbValue lb_emit_string(lbProcedure *p, lbValue str_elem, lbValue str_len) {
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


lbValue lb_emit_transmute(lbProcedure *p, lbValue value, Type *t) {
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
	if (is_type_uintptr(src) && is_type_pointer(dst)) {
		res.value = LLVMBuildIntToPtr(p->builder, value.value, lb_type(m, t), "");
		return res;
	}
	if (is_type_pointer(src) && is_type_uintptr(dst)) {
		res.value = LLVMBuildPtrToInt(p->builder, value.value, lb_type(m, t), "");
		return res;
	}
	if (is_type_uintptr(src) && is_type_proc(dst)) {
		res.value = LLVMBuildIntToPtr(p->builder, value.value, lb_type(m, t), "");
		return res;
	}
	if (is_type_proc(src) && is_type_uintptr(dst)) {
		res.value = LLVMBuildPtrToInt(p->builder, value.value, lb_type(m, t), "");
		return res;
	}

	if (is_type_integer(src) && (is_type_pointer(dst) || is_type_cstring(dst))) {
		res.value = LLVMBuildIntToPtr(p->builder, value.value, lb_type(m, t), "");
		return res;
	} else if ((is_type_pointer(src) || is_type_cstring(src)) && is_type_integer(dst)) {
		res.value = LLVMBuildPtrToInt(p->builder, value.value, lb_type(m, t), "");
		return res;
	}

	if (is_type_pointer(src) && is_type_pointer(dst)) {
		res.value = LLVMBuildPointerCast(p->builder, value.value, lb_type(p->module, t), "");
		return res;
	}

	if (lb_is_type_aggregate(src) || lb_is_type_aggregate(dst)) {
		lbValue s = lb_address_from_load_or_generate_local(p, value);
		lbValue d = lb_emit_transmute(p, s, alloc_type_pointer(t));
		return lb_emit_load(p, d);
	}

	res.value = LLVMBuildBitCast(p->builder, value.value, lb_type(p->module, t), "");
	return res;
}

lbValue lb_copy_value_to_ptr(lbProcedure *p, lbValue val, Type *new_type, i64 alignment) {
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


lbValue lb_soa_zip(lbProcedure *p, AstCallExpr *ce, TypeAndValue const &tv) {
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

lbValue lb_soa_unzip(lbProcedure *p, AstCallExpr *ce, TypeAndValue const &tv) {
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

void lb_emit_try_lhs_rhs(lbProcedure *p, Ast *arg, TypeAndValue const &tv, lbValue *lhs_, lbValue *rhs_) {
	lbValue lhs = {};
	lbValue rhs = {};

	lbValue value = lb_build_expr(p, arg);
	if (is_type_tuple(value.type)) {
		i32 n = cast(i32)(value.type->Tuple.variables.count-1);
		if (value.type->Tuple.variables.count == 2) {
			lhs = lb_emit_struct_ev(p, value, 0);
		} else {
			lbAddr lhs_addr = lb_add_local_generated(p, tv.type, false);
			lbValue lhs_ptr = lb_addr_get_ptr(p, lhs_addr);
			for (i32 i = 0; i < n; i++) {
				lb_emit_store(p, lb_emit_struct_ep(p, lhs_ptr, i), lb_emit_struct_ev(p, value, i));
			}
			lhs = lb_addr_load(p, lhs_addr);
		}
		rhs = lb_emit_struct_ev(p, value, n);
	} else {
		rhs = value;
	}

	GB_ASSERT(rhs.value != nullptr);

	if (lhs_) *lhs_ = lhs;
	if (rhs_) *rhs_ = rhs;
}


lbValue lb_emit_try_has_value(lbProcedure *p, lbValue rhs) {
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


lbValue lb_emit_or_else(lbProcedure *p, Ast *arg, Ast *else_expr, TypeAndValue const &tv) {
	lbValue lhs = {};
	lbValue rhs = {};
	lb_emit_try_lhs_rhs(p, arg, tv, &lhs, &rhs);

	LLVMValueRef incoming_values[2] = {};
	LLVMBasicBlockRef incoming_blocks[2] = {};

	GB_ASSERT(else_expr != nullptr);
	lbBlock *then  = lb_create_block(p, "or_else.then");
	lbBlock *done  = lb_create_block(p, "or_else.done"); // NOTE(bill): Append later
	lbBlock *else_ = lb_create_block(p, "or_else.else");

	lb_emit_if(p, lb_emit_try_has_value(p, rhs), then, else_);
	lb_start_block(p, then);

	Type *type = default_type(tv.type);

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

void lb_build_return_stmt(lbProcedure *p, Slice<Ast *> const &return_results);
void lb_build_return_stmt_internal(lbProcedure *p, lbValue const &res);

lbValue lb_emit_or_return(lbProcedure *p, Ast *arg, TypeAndValue const &tv) {
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


void lb_emit_increment(lbProcedure *p, lbValue addr) {
	GB_ASSERT(is_type_pointer(addr.type));
	Type *type = type_deref(addr.type);
	lbValue v_one = lb_const_value(p->module, type, exact_value_i64(1));
	lb_emit_store(p, addr, lb_emit_arith(p, Token_Add, lb_emit_load(p, addr), v_one, type));

}

lbValue lb_emit_byte_swap(lbProcedure *p, lbValue value, Type *end_type) {
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
	unsigned id = LLVMLookupIntrinsicID(name, gb_strlen(name));
	GB_ASSERT_MSG(id != 0, "Unable to find %s.%s", name, LLVMPrintTypeToString(types[0]));
	LLVMValueRef ip = LLVMGetIntrinsicDeclaration(p->module->mod, id, types, gb_count_of(types));

	LLVMValueRef args[1] = {};
	args[0] = value.value;

	lbValue res = {};
	res.value = LLVMBuildCall(p->builder, ip, args, gb_count_of(args), "");
	res.type = value.type;

	if (is_type_float(original_type)) {
		res = lb_emit_transmute(p, res, original_type);
	}
	res.type = end_type;
	return res;
}




lbValue lb_emit_count_ones(lbProcedure *p, lbValue x, Type *type) {
	x = lb_emit_conv(p, x, type);

	char const *name = "llvm.ctpop";
	LLVMTypeRef types[1] = {lb_type(p->module, type)};
	unsigned id = LLVMLookupIntrinsicID(name, gb_strlen(name));
	GB_ASSERT_MSG(id != 0, "Unable to find %s.%s", name, LLVMPrintTypeToString(types[0]));
	LLVMValueRef ip = LLVMGetIntrinsicDeclaration(p->module->mod, id, types, gb_count_of(types));

	LLVMValueRef args[1] = {};
	args[0] = x.value;

	lbValue res = {};
	res.value = LLVMBuildCall(p->builder, ip, args, gb_count_of(args), "");
	res.type = type;
	return res;
}

lbValue lb_emit_count_zeros(lbProcedure *p, lbValue x, Type *type) {
	i64 sz = 8*type_size_of(type);
	lbValue size = lb_const_int(p->module, type, cast(u64)sz);
	lbValue count = lb_emit_count_ones(p, x, type);
	return lb_emit_arith(p, Token_Sub, size, count, type);
}



lbValue lb_emit_count_trailing_zeros(lbProcedure *p, lbValue x, Type *type) {
	x = lb_emit_conv(p, x, type);

	char const *name = "llvm.cttz";
	LLVMTypeRef types[1] = {lb_type(p->module, type)};
	unsigned id = LLVMLookupIntrinsicID(name, gb_strlen(name));
	GB_ASSERT_MSG(id != 0, "Unable to find %s.%s", name, LLVMPrintTypeToString(types[0]));
	LLVMValueRef ip = LLVMGetIntrinsicDeclaration(p->module->mod, id, types, gb_count_of(types));

	LLVMValueRef args[2] = {};
	args[0] = x.value;
	args[1] = LLVMConstNull(LLVMInt1TypeInContext(p->module->ctx));

	lbValue res = {};
	res.value = LLVMBuildCall(p->builder, ip, args, gb_count_of(args), "");
	res.type = type;
	return res;
}

lbValue lb_emit_count_leading_zeros(lbProcedure *p, lbValue x, Type *type) {
	x = lb_emit_conv(p, x, type);

	char const *name = "llvm.ctlz";
	LLVMTypeRef types[1] = {lb_type(p->module, type)};
	unsigned id = LLVMLookupIntrinsicID(name, gb_strlen(name));
	GB_ASSERT_MSG(id != 0, "Unable to find %s.%s", name, LLVMPrintTypeToString(types[0]));
	LLVMValueRef ip = LLVMGetIntrinsicDeclaration(p->module->mod, id, types, gb_count_of(types));

	LLVMValueRef args[2] = {};
	args[0] = x.value;
	args[1] = LLVMConstNull(LLVMInt1TypeInContext(p->module->ctx));

	lbValue res = {};
	res.value = LLVMBuildCall(p->builder, ip, args, gb_count_of(args), "");
	res.type = type;
	return res;
}



lbValue lb_emit_reverse_bits(lbProcedure *p, lbValue x, Type *type) {
	x = lb_emit_conv(p, x, type);

	char const *name = "llvm.bitreverse";
	LLVMTypeRef types[1] = {lb_type(p->module, type)};
	unsigned id = LLVMLookupIntrinsicID(name, gb_strlen(name));
	GB_ASSERT_MSG(id != 0, "Unable to find %s.%s", name, LLVMPrintTypeToString(types[0]));
	LLVMValueRef ip = LLVMGetIntrinsicDeclaration(p->module->mod, id, types, gb_count_of(types));

	LLVMValueRef args[1] = {};
	args[0] = x.value;

	lbValue res = {};
	res.value = LLVMBuildCall(p->builder, ip, args, gb_count_of(args), "");
	res.type = type;
	return res;
}


lbValue lb_emit_bit_set_card(lbProcedure *p, lbValue x) {
	GB_ASSERT(is_type_bit_set(x.type));
	Type *underlying = bit_set_to_int(x.type);
	lbValue card = lb_emit_count_ones(p, x, underlying);
	return lb_emit_conv(p, card, t_int);
}


lbValue lb_emit_union_cast_only_ok_check(lbProcedure *p, lbValue value, Type *type, TokenPos pos) {
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

lbValue lb_emit_union_cast(lbProcedure *p, lbValue value, Type *type, TokenPos pos) {
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
		{
			// NOTE(bill): Panic on invalid conversion
			Type *dst_type = tuple->Tuple.variables[0]->type;

			lbValue ok = lb_emit_load(p, lb_emit_struct_ep(p, v.addr, 1));
			auto args = array_make<lbValue>(permanent_allocator(), 7);
			args[0] = ok;

			args[1] = lb_const_string(m, get_file_path_string(pos.file_id));
			args[2] = lb_const_int(m, t_i32, pos.line);
			args[3] = lb_const_int(m, t_i32, pos.column);

			args[4] = lb_typeid(m, src_type);
			args[5] = lb_typeid(m, dst_type);
			args[6] = lb_emit_conv(p, value_, t_rawptr);
			lb_emit_runtime_call(p, "type_assertion_check2", args);
		}

		return lb_emit_load(p, lb_emit_struct_ep(p, v.addr, 0));
	}
	return lb_addr_load(p, v);
}

lbAddr lb_emit_any_cast_addr(lbProcedure *p, lbValue value, Type *type, TokenPos pos) {
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

		lbValue ok = lb_emit_load(p, lb_emit_struct_ep(p, v.addr, 1));
		auto args = array_make<lbValue>(permanent_allocator(), 7);
		args[0] = ok;

		args[1] = lb_const_string(m, get_file_path_string(pos.file_id));
		args[2] = lb_const_int(m, t_i32, pos.line);
		args[3] = lb_const_int(m, t_i32, pos.column);

		args[4] = any_typeid;
		args[5] = dst_typeid;
		args[6] = lb_emit_struct_ev(p, value, 0);;
		lb_emit_runtime_call(p, "type_assertion_check2", args);

		return lb_addr(lb_emit_struct_ep(p, v.addr, 0));
	}
	return v;
}
lbValue lb_emit_any_cast(lbProcedure *p, lbValue value, Type *type, TokenPos pos) {
	return lb_addr_load(p, lb_emit_any_cast_addr(p, value, type, pos));
}



lbAddr lb_find_or_generate_context_ptr(lbProcedure *p) {
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

lbValue lb_address_from_load_or_generate_local(lbProcedure *p, lbValue value) {
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
lbValue lb_address_from_load(lbProcedure *p, lbValue value) {
	if (LLVMIsALoadInst(value.value)) {
		lbValue res = {};
		res.value = LLVMGetOperand(value.value, 0);
		res.type = alloc_type_pointer(value.type);
		return res;
	}

	GB_PANIC("lb_address_from_load");
	return {};
}


lbStructFieldRemapping lb_get_struct_remapping(lbModule *m, Type *t) {
	t = base_type(t);
	LLVMTypeRef struct_type = lb_type(m, t);
	auto *field_remapping = map_get(&m->struct_field_remapping, cast(void *)struct_type);
	if (field_remapping == nullptr) {
		field_remapping = map_get(&m->struct_field_remapping, cast(void *)t);
	}
	GB_ASSERT(field_remapping != nullptr);
	return *field_remapping;
}

i32 lb_convert_struct_index(lbModule *m, Type *t, i32 index) {
	if (t->kind == Type_Struct) {
		auto field_remapping = lb_get_struct_remapping(m, t);
		index = field_remapping[index];
	}
	return index;
}

LLVMTypeRef lb_type_padding_filler(lbModule *m, i64 padding, i64 padding_align) {
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
			return LLVMArrayType(elem, cast(unsigned)len);
		} else {
			return elem;
		}
	} else {
		return LLVMArrayType(lb_type(m, t_u8), cast(unsigned)padding);
	}
}


char const *llvm_type_kinds[] = {
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

lbValue lb_emit_struct_ep(lbProcedure *p, lbValue s, i32 index) {
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
		GB_ASSERT(t->Tuple.variables.count > 0);
		result_type = t->Tuple.variables[index]->type;
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
		init_map_internal_types(t);
		Type *itp = alloc_type_pointer(t->Map.internal_type);
		s = lb_emit_transmute(p, s, itp);

		Type *gst = t->Map.internal_type;
		GB_ASSERT(gst->kind == Type_Struct);
		switch (index) {
		case 0: result_type = get_struct_field_type(gst, 0); break;
		case 1: result_type = get_struct_field_type(gst, 1); break;
		}
	} else if (is_type_array(t)) {
		return lb_emit_array_epi(p, s, index);
	} else if (is_type_relative_slice(t)) {
		switch (index) {
		case 0: result_type = t->RelativeSlice.base_integer; break;
		case 1: result_type = t->RelativeSlice.base_integer; break;
		}
	} else {
		GB_PANIC("TODO(bill): struct_gep type: %s, %d", type_to_string(s.type), index);
	}

	GB_ASSERT_MSG(result_type != nullptr, "%s %d", type_to_string(t), index);
	
	i32 original_index = index;
	index = lb_convert_struct_index(p->module, t, index);
	
	if (lb_is_const(s)) {
		lbModule *m = p->module;
		lbValue res = {};
		LLVMValueRef indices[2] = {llvm_zero(m), LLVMConstInt(lb_type(m, t_i32), index, false)};
		res.value = LLVMConstGEP(s.value, indices, gb_count_of(indices));
		res.type = alloc_type_pointer(result_type);
		return res;
	} else {
		lbValue res = {};
		LLVMTypeRef st = LLVMGetElementType(LLVMTypeOf(s.value));
		// gb_printf_err("%s\n", type_to_string(s.type));
		// gb_printf_err("%s\n", LLVMPrintTypeToString(LLVMTypeOf(s.value)));
		// gb_printf_err("%d\n", index);
		GB_ASSERT_MSG(LLVMGetTypeKind(st) == LLVMStructTypeKind, "%s", llvm_type_kinds[LLVMGetTypeKind(st)]);
		unsigned count = LLVMCountStructElementTypes(st);
		GB_ASSERT_MSG(count >= cast(unsigned)index, "%u %d %d", count, index, original_index);
		
		res.value = LLVMBuildStructGEP(p->builder, s.value, cast(unsigned)index, "");
		res.type = alloc_type_pointer(result_type);
		return res;
	}
}

lbValue lb_emit_struct_ev(lbProcedure *p, lbValue s, i32 index) {
	if (LLVMIsALoadInst(s.value)) {
		lbValue res = {};
		res.value = LLVMGetOperand(s.value, 0);
		res.type = alloc_type_pointer(s.type);
		lbValue ptr = lb_emit_struct_ep(p, res, index);
		return lb_emit_load(p, ptr);
	}

	Type *t = base_type(s.type);
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
		GB_ASSERT(t->Tuple.variables.count > 0);
		result_type = t->Tuple.variables[index]->type;
		if (t->Tuple.variables.count == 1) {
			return s;
		}
		break;
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
			init_map_internal_types(t);
			Type *gst = t->Map.generated_struct_type;
			switch (index) {
			case 0: result_type = get_struct_field_type(gst, 0); break;
			case 1: result_type = get_struct_field_type(gst, 1); break;
			}
		}
		break;

	case Type_Array:
		result_type = t->Array.elem;
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

lbValue lb_emit_deep_field_gep(lbProcedure *p, lbValue e, Selection sel) {
	GB_ASSERT(sel.index.count > 0);
	Type *type = type_deref(e.type);

	for_array(i, sel.index) {
		i32 index = cast(i32)sel.index[i];
		if (is_type_pointer(type)) {
			type = type_deref(type);
			e = lb_emit_load(p, e);
		}
		type = core_type(type);

		if (is_type_quaternion(type)) {
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
					type = t_type_info_ptr;
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


lbValue lb_emit_deep_field_ev(lbProcedure *p, lbValue e, Selection sel) {
	lbValue ptr = lb_address_from_load_or_generate_local(p, e);
	lbValue res = lb_emit_deep_field_gep(p, ptr, sel);
	return lb_emit_load(p, res);
}


lbValue lb_emit_array_ep(lbProcedure *p, lbValue s, lbValue index) {
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
	res.value = LLVMBuildGEP(p->builder, s.value, indices, 2, "");
	res.type = alloc_type_pointer(ptr);
	return res;
}

lbValue lb_emit_array_epi(lbProcedure *p, lbValue s, isize index) {
	Type *t = s.type;
	GB_ASSERT(is_type_pointer(t));
	Type *st = base_type(type_deref(t));
	GB_ASSERT_MSG(is_type_array(st) || is_type_enumerated_array(st) || is_type_matrix(st), "%s", type_to_string(st));

	GB_ASSERT(0 <= index);
	Type *ptr = base_array_type(st);


	LLVMValueRef indices[2] = {
		LLVMConstInt(lb_type(p->module, t_int), 0, false),
		LLVMConstInt(lb_type(p->module, t_int), cast(unsigned)index, false),
	};

	lbValue res = {};
	if (lb_is_const(s)) {
		res.value = LLVMConstGEP(s.value, indices, gb_count_of(indices));
	} else {
		res.value = LLVMBuildGEP(p->builder, s.value, indices, gb_count_of(indices), "");
	}
	res.type = alloc_type_pointer(ptr);
	return res;
}

lbValue lb_emit_ptr_offset(lbProcedure *p, lbValue ptr, lbValue index) {
	index = lb_correct_endianness(p, index);
	LLVMValueRef indices[1] = {index.value};
	lbValue res = {};
	res.type = ptr.type;

	if (lb_is_const(ptr) && lb_is_const(index)) {
		res.value = LLVMConstGEP(ptr.value, indices, 1);
	} else {
		res.value = LLVMBuildGEP(p->builder, ptr.value, indices, 1, "");
	}
	return res;
}

lbValue lb_emit_matrix_epi(lbProcedure *p, lbValue s, isize row, isize column) {
	Type *t = s.type;
	GB_ASSERT(is_type_pointer(t));
	Type *mt = base_type(type_deref(t));
	
	Type *ptr = base_array_type(mt);
	
	if (column == 0) {
		GB_ASSERT_MSG(is_type_matrix(mt) || is_type_array_like(mt), "%s", type_to_string(mt));
		
		LLVMValueRef indices[2] = {
			LLVMConstInt(lb_type(p->module, t_int), 0, false),
			LLVMConstInt(lb_type(p->module, t_int), cast(unsigned)row, false),
		};
		
		lbValue res = {};
		if (lb_is_const(s)) {
			res.value = LLVMConstGEP(s.value, indices, gb_count_of(indices));
		} else {
			res.value = LLVMBuildGEP(p->builder, s.value, indices, gb_count_of(indices), "");
		}
		
		Type *ptr = base_array_type(mt);
		res.type = alloc_type_pointer(ptr);
		return res;
	} else if (row == 0 && is_type_array_like(mt)) {
		LLVMValueRef indices[2] = {
			LLVMConstInt(lb_type(p->module, t_int), 0, false),
			LLVMConstInt(lb_type(p->module, t_int), cast(unsigned)column, false),
		};
		
		lbValue res = {};
		if (lb_is_const(s)) {
			res.value = LLVMConstGEP(s.value, indices, gb_count_of(indices));
		} else {
			res.value = LLVMBuildGEP(p->builder, s.value, indices, gb_count_of(indices), "");
		}
		
		Type *ptr = base_array_type(mt);
		res.type = alloc_type_pointer(ptr);
		return res;
	}
	
	
	GB_ASSERT_MSG(is_type_matrix(mt), "%s", type_to_string(mt));
	
	isize offset = matrix_indices_to_offset(mt, row, column);

	LLVMValueRef indices[2] = {
		LLVMConstInt(lb_type(p->module, t_int), 0, false),
		LLVMConstInt(lb_type(p->module, t_int), cast(unsigned)offset, false),
	};

	lbValue res = {};
	if (lb_is_const(s)) {
		res.value = LLVMConstGEP(s.value, indices, gb_count_of(indices));
	} else {
		res.value = LLVMBuildGEP(p->builder, s.value, indices, gb_count_of(indices), "");
	}
	res.type = alloc_type_pointer(ptr);
	return res;
}

lbValue lb_emit_matrix_ep(lbProcedure *p, lbValue s, lbValue row, lbValue column) {
	Type *t = s.type;
	GB_ASSERT(is_type_pointer(t));
	Type *mt = base_type(type_deref(t));
	GB_ASSERT_MSG(is_type_matrix(mt), "%s", type_to_string(mt));

	Type *ptr = base_array_type(mt);
	
	LLVMValueRef stride_elems = lb_const_int(p->module, t_int, matrix_type_stride_in_elems(mt)).value;
	
	row = lb_emit_conv(p, row, t_int);
	column = lb_emit_conv(p, column, t_int);
	
	LLVMValueRef index = LLVMBuildAdd(p->builder, row.value, LLVMBuildMul(p->builder, column.value, stride_elems, ""), "");

	LLVMValueRef indices[2] = {
		LLVMConstInt(lb_type(p->module, t_int), 0, false),
		index,
	};

	lbValue res = {};
	if (lb_is_const(s)) {
		res.value = LLVMConstGEP(s.value, indices, gb_count_of(indices));
	} else {
		res.value = LLVMBuildGEP(p->builder, s.value, indices, gb_count_of(indices), "");
	}
	res.type = alloc_type_pointer(ptr);
	return res;
}


lbValue lb_emit_matrix_ev(lbProcedure *p, lbValue s, isize row, isize column) {
	Type *st = base_type(s.type);
	GB_ASSERT_MSG(is_type_matrix(st), "%s", type_to_string(st));
	
	lbValue value = lb_address_from_load_or_generate_local(p, s);
	lbValue ptr = lb_emit_matrix_epi(p, value, row, column);
	return lb_emit_load(p, ptr);
}


void lb_fill_slice(lbProcedure *p, lbAddr const &slice, lbValue base_elem, lbValue len) {
	Type *t = lb_addr_type(slice);
	GB_ASSERT(is_type_slice(t));
	lbValue ptr = lb_addr_get_ptr(p, slice);
	lb_emit_store(p, lb_emit_struct_ep(p, ptr, 0), base_elem);
	lb_emit_store(p, lb_emit_struct_ep(p, ptr, 1), len);
}
void lb_fill_string(lbProcedure *p, lbAddr const &string, lbValue base_elem, lbValue len) {
	Type *t = lb_addr_type(string);
	GB_ASSERT(is_type_string(t));
	lbValue ptr = lb_addr_get_ptr(p, string);
	lb_emit_store(p, lb_emit_struct_ep(p, ptr, 0), base_elem);
	lb_emit_store(p, lb_emit_struct_ep(p, ptr, 1), len);
}

lbValue lb_string_elem(lbProcedure *p, lbValue string) {
	Type *t = base_type(string.type);
	GB_ASSERT(t->kind == Type_Basic && t->Basic.kind == Basic_string);
	return lb_emit_struct_ev(p, string, 0);
}
lbValue lb_string_len(lbProcedure *p, lbValue string) {
	Type *t = base_type(string.type);
	GB_ASSERT_MSG(t->kind == Type_Basic && t->Basic.kind == Basic_string, "%s", type_to_string(t));
	return lb_emit_struct_ev(p, string, 1);
}

lbValue lb_cstring_len(lbProcedure *p, lbValue value) {
	GB_ASSERT(is_type_cstring(value.type));
	auto args = array_make<lbValue>(permanent_allocator(), 1);
	args[0] = lb_emit_conv(p, value, t_cstring);
	return lb_emit_runtime_call(p, "cstring_len", args);
}


lbValue lb_array_elem(lbProcedure *p, lbValue array_ptr) {
	Type *t = type_deref(array_ptr.type);
	GB_ASSERT(is_type_array(t));
	return lb_emit_struct_ep(p, array_ptr, 0);
}

lbValue lb_slice_elem(lbProcedure *p, lbValue slice) {
	GB_ASSERT(is_type_slice(slice.type));
	return lb_emit_struct_ev(p, slice, 0);
}
lbValue lb_slice_len(lbProcedure *p, lbValue slice) {
	GB_ASSERT(is_type_slice(slice.type));
	return lb_emit_struct_ev(p, slice, 1);
}
lbValue lb_dynamic_array_elem(lbProcedure *p, lbValue da) {
	GB_ASSERT(is_type_dynamic_array(da.type));
	return lb_emit_struct_ev(p, da, 0);
}
lbValue lb_dynamic_array_len(lbProcedure *p, lbValue da) {
	GB_ASSERT(is_type_dynamic_array(da.type));
	return lb_emit_struct_ev(p, da, 1);
}
lbValue lb_dynamic_array_cap(lbProcedure *p, lbValue da) {
	GB_ASSERT(is_type_dynamic_array(da.type));
	return lb_emit_struct_ev(p, da, 2);
}
lbValue lb_dynamic_array_allocator(lbProcedure *p, lbValue da) {
	GB_ASSERT(is_type_dynamic_array(da.type));
	return lb_emit_struct_ev(p, da, 3);
}

lbValue lb_map_entries(lbProcedure *p, lbValue value) {
	Type *t = base_type(value.type);
	GB_ASSERT_MSG(t->kind == Type_Map, "%s", type_to_string(t));
	init_map_internal_types(t);
	i32 index = 1;
	lbValue entries = lb_emit_struct_ev(p, value, index);
	return entries;
}

lbValue lb_map_entries_ptr(lbProcedure *p, lbValue value) {
	Type *t = base_type(type_deref(value.type));
	GB_ASSERT_MSG(t->kind == Type_Map, "%s", type_to_string(t));
	init_map_internal_types(t);
	i32 index = 1;
	lbValue entries = lb_emit_struct_ep(p, value, index);	
	return entries;
}

lbValue lb_map_len(lbProcedure *p, lbValue value) {
	lbValue entries = lb_map_entries(p, value);
	return lb_dynamic_array_len(p, entries);
}

lbValue lb_map_cap(lbProcedure *p, lbValue value) {
	lbValue entries = lb_map_entries(p, value);
	return lb_dynamic_array_cap(p, entries);
}

lbValue lb_soa_struct_len(lbProcedure *p, lbValue value) {
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

lbValue lb_soa_struct_cap(lbProcedure *p, lbValue value) {
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

lbValue lb_emit_mul_add(lbProcedure *p, lbValue a, lbValue b, lbValue c, Type *t) {
	lbModule *m = p->module;
	
	a = lb_emit_conv(p, a, t);
	b = lb_emit_conv(p, b, t);
	c = lb_emit_conv(p, c, t);
	
	bool is_possible = !is_type_different_to_arch_endianness(t) && is_type_float(t);
	
	if (is_possible) {
		switch (build_context.metrics.arch) {
		case TargetArch_amd64:
			if (type_size_of(t) == 2) {
				is_possible = false;
			}
			break;
		case TargetArch_arm64:
			// possible
			break;
		case TargetArch_386:
		case TargetArch_wasm32:
		case TargetArch_wasm64:
			is_possible = false;
			break;
		}
	}

	if (is_possible) {
		char const *name = "llvm.fma";
		unsigned id = LLVMLookupIntrinsicID(name, gb_strlen(name));
		GB_ASSERT_MSG(id != 0, "Unable to find %s", name);
		
		LLVMTypeRef types[1] = {};
		types[0] = lb_type(m, t);
		
		LLVMValueRef ip = LLVMGetIntrinsicDeclaration(m->mod, id, types, gb_count_of(types));
		LLVMValueRef values[3] = {};
		values[0] = a.value;
		values[1] = b.value;
		values[2] = c.value;
		LLVMValueRef call = LLVMBuildCall(p->builder, ip, values, gb_count_of(values), "");
		return {call, t};
	} else {
		lbValue x = lb_emit_arith(p, Token_Mul, a, b, t);
		lbValue y = lb_emit_arith(p, Token_Add, x, c, t);
		return y;
	}
}

LLVMValueRef llvm_mask_iota(lbModule *m, unsigned start, unsigned count) {
	auto iota = slice_make<LLVMValueRef>(temporary_allocator(), count);
	for (unsigned i = 0; i < count; i++) {
		iota[i] = lb_const_int(m, t_u32, start+i).value;
	}
	return LLVMConstVector(iota.data, count);
}

LLVMValueRef llvm_mask_zero(lbModule *m, unsigned count) {
	return LLVMConstNull(LLVMVectorType(lb_type(m, t_u32), count));
}

LLVMValueRef llvm_vector_broadcast(lbProcedure *p, LLVMValueRef value, unsigned count) {
	GB_ASSERT(count > 0);
	if (LLVMIsConstant(value)) {
		LLVMValueRef single = LLVMConstVector(&value, 1);
		if (count == 1) {
			return single;
		}
		LLVMValueRef mask = llvm_mask_zero(p->module, count);
		return LLVMConstShuffleVector(single, LLVMGetUndef(LLVMTypeOf(single)), mask);
	}
	
	LLVMTypeRef single_type = LLVMVectorType(LLVMTypeOf(value), 1);
	LLVMValueRef single = LLVMBuildBitCast(p->builder, value, single_type, "");
	if (count == 1) {
		return single;
	}
	LLVMValueRef mask = llvm_mask_zero(p->module, count);
	return LLVMBuildShuffleVector(p->builder, single, LLVMGetUndef(LLVMTypeOf(single)), mask, "");
}

LLVMValueRef llvm_vector_shuffle_reduction(lbProcedure *p, LLVMValueRef value, LLVMOpcode op_code) {
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

		LLVMValueRef lhs = LLVMBuildShuffleVector(p->builder, value, LLVMGetUndef(LLVMTypeOf(value)), lhs_mask, "");
		LLVMValueRef rhs = LLVMBuildShuffleVector(p->builder, value, LLVMGetUndef(LLVMTypeOf(value)), rhs_mask, "");
		GB_ASSERT(LLVMTypeOf(lhs) == LLVMTypeOf(rhs));
		
		value = LLVMBuildBinOp(p->builder, op_code, lhs, rhs, "");
	}
	return LLVMBuildExtractElement(p->builder, value, v_zero32, "");
}

LLVMValueRef llvm_vector_expand_to_power_of_two(lbProcedure *p, LLVMValueRef value) {
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

LLVMValueRef llvm_vector_reduce_add(lbProcedure *p, LLVMValueRef value) {
	LLVMTypeRef type = LLVMTypeOf(value);
	GB_ASSERT(LLVMGetTypeKind(type) == LLVMVectorTypeKind);
	LLVMTypeRef elem = LLVMGetElementType(type);
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
		LLVMTypeRef types[1] = {};
		types[0] = type;
		
		LLVMValueRef ip = LLVMGetIntrinsicDeclaration(p->module->mod, id, types, gb_count_of(types));
		LLVMValueRef values[2] = {};
		values[0] = LLVMConstNull(elem);
		values[1] = value;
		LLVMValueRef call = LLVMBuildCall(p->builder, ip, values+value_offset, value_count, "");
		return call;
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
		LLVMValueRef lower = LLVMBuildShuffleVector(p->builder, value, LLVMGetUndef(LLVMTypeOf(value)), lower_mask, "");
		LLVMValueRef upper = LLVMBuildShuffleVector(p->builder, value, LLVMGetUndef(LLVMTypeOf(value)), upper_mask, "");
		upper = llvm_vector_expand_to_power_of_two(p, upper);

		LLVMValueRef lower_reduced = llvm_vector_shuffle_reduction(p, lower, op_code);
		LLVMValueRef upper_reduced = llvm_vector_shuffle_reduction(p, upper, op_code);
		GB_ASSERT(LLVMTypeOf(lower_reduced) == LLVMTypeOf(upper_reduced));

		return LLVMBuildBinOp(p->builder, op_code, lower_reduced, upper_reduced, "");
	}
#endif
}

LLVMValueRef llvm_vector_add(lbProcedure *p, LLVMValueRef a, LLVMValueRef b) {
	GB_ASSERT(LLVMTypeOf(a) == LLVMTypeOf(b));
	
	LLVMTypeRef elem = LLVMGetElementType(LLVMTypeOf(a));
	
	if (LLVMGetTypeKind(elem) == LLVMIntegerTypeKind) {
		return LLVMBuildAdd(p->builder, a, b, "");
	}
	return LLVMBuildFAdd(p->builder, a, b, "");
}

LLVMValueRef llvm_vector_mul(lbProcedure *p, LLVMValueRef a, LLVMValueRef b) {
	GB_ASSERT(LLVMTypeOf(a) == LLVMTypeOf(b));
	
	LLVMTypeRef elem = LLVMGetElementType(LLVMTypeOf(a));
	
	if (LLVMGetTypeKind(elem) == LLVMIntegerTypeKind) {
		return LLVMBuildMul(p->builder, a, b, "");
	}
	return LLVMBuildFMul(p->builder, a, b, "");
}


LLVMValueRef llvm_vector_dot(lbProcedure *p, LLVMValueRef a, LLVMValueRef b) {
	return llvm_vector_reduce_add(p, llvm_vector_mul(p, a, b));
}

LLVMValueRef llvm_vector_mul_add(lbProcedure *p, LLVMValueRef a, LLVMValueRef b, LLVMValueRef c) {
	lbModule *m = p->module;
	
	LLVMTypeRef t = LLVMTypeOf(a);
	GB_ASSERT(t == LLVMTypeOf(b));
	GB_ASSERT(t == LLVMTypeOf(c));
	GB_ASSERT(LLVMGetTypeKind(t) == LLVMVectorTypeKind);
	
	LLVMTypeRef elem = LLVMGetElementType(t);
	
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
		unsigned id = LLVMLookupIntrinsicID(name, gb_strlen(name));
		GB_ASSERT_MSG(id != 0, "Unable to find %s", name);
		
		LLVMTypeRef types[1] = {};
		types[0] = t;
		
		LLVMValueRef ip = LLVMGetIntrinsicDeclaration(m->mod, id, types, gb_count_of(types));
		LLVMValueRef values[3] = {};
		values[0] = a;
		values[1] = b;
		values[2] = c;
		LLVMValueRef call = LLVMBuildCall(p->builder, ip, values, gb_count_of(values), "");
		return call;
	} else {
		LLVMValueRef x = llvm_vector_mul(p, a, b);
		LLVMValueRef y = llvm_vector_add(p, x, c);
		return y;
	}
}

LLVMValueRef llvm_get_inline_asm(LLVMTypeRef func_type, String const &str, String const &clobbers, bool has_side_effects=true, bool is_align_stack=false, LLVMInlineAsmDialect dialect=LLVMInlineAsmDialectATT) {
	return LLVMGetInlineAsm(func_type,
		cast(char *)str.text, cast(size_t)str.len,
		cast(char *)clobbers.text, cast(size_t)clobbers.len,
		/*HasSideEffects*/true, /*IsAlignStack*/false,
		dialect
	#if LLVM_VERSION_MAJOR >= 13 
		, /*CanThrow*/false
	#endif
	);
}


void lb_set_wasm_import_attributes(LLVMValueRef value, Entity *entity, String import_name) {
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


void lb_set_wasm_export_attributes(LLVMValueRef value, String export_name) {
	if (!is_arch_wasm()) {
		return;
	}
	LLVMSetLinkage(value, LLVMDLLExportLinkage);
	LLVMSetDLLStorageClass(value, LLVMDLLExportStorageClass);
	LLVMSetVisibility(value, LLVMDefaultVisibility);
	LLVMAddTargetDependentFunctionAttr(value, "wasm-export-name",   alloc_cstring(permanent_allocator(), export_name));
}
