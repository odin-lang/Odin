gb_internal lbValue lb_emit_arith_matrix(lbProcedure *p, TokenKind op, lbValue lhs, lbValue rhs, Type *type, bool component_wise);

gb_internal lbValue lb_emit_logical_binary_expr(lbProcedure *p, TokenKind op, Ast *left, Ast *right, Type *final_type) {
	lbModule *m = p->module;

	lbBlock *rhs  = lb_create_block(p, "logical.cmp.rhs");
	lbBlock *done = lb_create_block(p, "logical.cmp.done");

	lbValue short_circuit = {};
	if (op == Token_CmpAnd) {
		lb_build_cond(p, left, rhs, done);
		short_circuit = lb_const_bool(m, t_llvm_bool, false);
	} else if (op == Token_CmpOr) {
		lb_build_cond(p, left, done, rhs);
		short_circuit = lb_const_bool(m, t_llvm_bool, true);
	}

	if (rhs->preds.count == 0) {
		lb_start_block(p, done);
		return short_circuit;
	}

	if (done->preds.count == 0) {
		lb_start_block(p, rhs);
		if (lb_is_expr_untyped_const(right)) {
			return lb_expr_untyped_const_to_typed(m, right, default_type(final_type));
		}
		return lb_build_expr(p, right);
	}

	Array<LLVMValueRef> incoming_values = {};
	Array<LLVMBasicBlockRef> incoming_blocks = {};
	array_init(&incoming_values, heap_allocator(), done->preds.count+1);
	array_init(&incoming_blocks, heap_allocator(), done->preds.count+1);

	for_array(i, done->preds) {
		incoming_values[i] = short_circuit.value;
		incoming_blocks[i] = done->preds[i]->block;
	}

	lb_start_block(p, rhs);
	lbValue edge = {};
	if (lb_is_expr_untyped_const(right)) {
		edge = lb_expr_untyped_const_to_typed(m, right, t_llvm_bool);
	} else {
		edge = lb_emit_conv(p, lb_build_expr(p, right), t_llvm_bool);
	}
	GB_ASSERT(edge.type == t_llvm_bool);

	incoming_values[done->preds.count] = edge.value;
	incoming_blocks[done->preds.count] = p->curr_block->block;

	lb_emit_jump(p, done);
	lb_start_block(p, done);	
	
	LLVMTypeRef dst_type = lb_type(m, t_llvm_bool);
	LLVMValueRef phi = nullptr;
	
	GB_ASSERT(incoming_values.count == incoming_blocks.count);
	GB_ASSERT(incoming_values.count > 0);

	LLVMTypeRef phi_type = nullptr;
	for (LLVMValueRef incoming_value : incoming_values) {
		if (!LLVMIsConstant(incoming_value)) {
			phi_type = LLVMTypeOf(incoming_value);
			break;
		}
	}

	lbValue res = {};
	
	if (phi_type == nullptr) {
		phi = LLVMBuildPhi(p->builder, dst_type, "");
		LLVMAddIncoming(phi, incoming_values.data, incoming_blocks.data, cast(unsigned)incoming_values.count);
		res.value = phi;
		res.type = t_llvm_bool;
	} else {
		for_array(i, incoming_values) {
			LLVMValueRef incoming_value = incoming_values[i];
			LLVMTypeRef incoming_type = LLVMTypeOf(incoming_value);

			if (phi_type != incoming_type) {
				GB_ASSERT_MSG(LLVMIsConstant(incoming_value), "%s vs %s", LLVMPrintTypeToString(phi_type), LLVMPrintTypeToString(incoming_type));
				bool ok = !!LLVMConstIntGetZExtValue(incoming_value);
				incoming_values[i] = LLVMConstInt(phi_type, ok, false);
			}

		}

		// NOTE(bill): this now only uses i1 for the logic to prevent issues with corrupted booleans which are not of value 0 or 1 (e.g. 2)
		// Doing this may produce slightly worse code as a result but it will be correct behaviour

		phi = LLVMBuildPhi(p->builder, phi_type, "");
		LLVMAddIncoming(phi, incoming_values.data, incoming_blocks.data, cast(unsigned)incoming_values.count);
		res.value = phi;
		res.type = t_llvm_bool;
	}
	return lb_emit_conv(p, res, default_type(final_type));
}


gb_internal lbValue lb_emit_unary_arith(lbProcedure *p, TokenKind op, lbValue x, Type *type) {
	switch (op) {
	case Token_Add:
		return x;
	case Token_Not: // Boolean not
	case Token_Xor: // Bitwise not
	case Token_Sub: // Number negation
		break;
	case Token_Pointer:
		GB_PANIC("This should be handled elsewhere");
		break;
	}

	if (is_type_array_like(x.type)) {
		// IMPORTANT TODO(bill): This is very wasteful with regards to stack memory
		Type *tl = base_type(x.type);
		lbValue val = lb_address_from_load_or_generate_local(p, x);
		GB_ASSERT(is_type_array_like(type));
		Type *elem_type = base_array_type(type);

		// NOTE(bill): Doesn't need to be zero because it will be initialized in the loops
		lbAddr res_addr = lb_add_local(p, type, nullptr, false, true);
		lbValue res = lb_addr_get_ptr(p, res_addr);

		bool inline_array_arith = lb_can_try_to_inline_array_arith(type);

		i32 count = cast(i32)get_array_type_count(tl);

		LLVMTypeRef vector_type = nullptr;
		if (op != Token_Not && lb_try_vector_cast(p->module, val, &vector_type)) {
			LLVMValueRef vp = LLVMBuildPointerCast(p->builder, val.value, LLVMPointerType(vector_type, 0), "");
			LLVMValueRef v = LLVMBuildLoad2(p->builder, vector_type, vp, "");

			LLVMValueRef opv = nullptr;
			switch (op) {
			case Token_Xor:
				opv = LLVMBuildNot(p->builder, v, "");
				break;
			case Token_Sub:
				if (is_type_float(elem_type)) {
					opv = LLVMBuildFNeg(p->builder, v, "");
				} else {
					opv = LLVMBuildNeg(p->builder, v, "");
				}
				break;
			}

			if (opv != nullptr) {
				LLVMSetAlignment(res.value, cast(unsigned)lb_alignof(vector_type));
				LLVMValueRef res_ptr = LLVMBuildPointerCast(p->builder, res.value, LLVMPointerType(vector_type, 0), "");
				LLVMBuildStore(p->builder, opv, res_ptr);
				return lb_emit_conv(p, lb_emit_load(p, res), type);
			}
		}

		if (inline_array_arith) {
			// inline
			for (i32 i = 0; i < count; i++) {
				lbValue e = lb_emit_load(p, lb_emit_array_epi(p, val, i));
				lbValue z = lb_emit_unary_arith(p, op, e, elem_type);
				lb_emit_store(p, lb_emit_array_epi(p, res, i), z);
			}
		} else {
			auto loop_data = lb_loop_start(p, count, t_i32);

			lbValue e = lb_emit_load(p, lb_emit_array_ep(p, val, loop_data.idx));
			lbValue z = lb_emit_unary_arith(p, op, e, elem_type);
			lb_emit_store(p, lb_emit_array_ep(p, res, loop_data.idx), z);

			lb_loop_end(p, loop_data);
		}
		return lb_emit_load(p, res);

	}

	if (op == Token_Xor) {
		lbValue cmp = {};
		cmp.value = LLVMBuildNot(p->builder, x.value, "");
		cmp.type = x.type;
		return lb_emit_conv(p, cmp, type);
	}

	if (op == Token_Not) {
		lbValue cmp = {};
		LLVMValueRef zero =  LLVMConstInt(lb_type(p->module, x.type), 0, false);
		cmp.value = LLVMBuildICmp(p->builder, LLVMIntEQ, x.value, zero, "");
		cmp.type = t_llvm_bool;
		return lb_emit_conv(p, cmp, type);
	}

	if (op == Token_Sub && is_type_integer(type) && is_type_different_to_arch_endianness(type)) {
		Type *platform_type = integer_endian_type_to_platform_type(type);
		lbValue v = lb_emit_byte_swap(p, x, platform_type);

		lbValue res = {};
		res.value = LLVMBuildNeg(p->builder, v.value, "");
		res.type = platform_type;

		return lb_emit_byte_swap(p, res, type);
	}

	if (op == Token_Sub && is_type_float(type) && is_type_different_to_arch_endianness(type)) {
		Type *platform_type = integer_endian_type_to_platform_type(type);
		lbValue v = lb_emit_byte_swap(p, x, platform_type);

		lbValue res = {};
		res.value = LLVMBuildFNeg(p->builder, v.value, "");
		res.type = platform_type;

		return lb_emit_byte_swap(p, res, type);
	}

	lbValue res = {};

	switch (op) {
	case Token_Not: // Boolean not
	case Token_Xor: // Bitwise not
		res.value = LLVMBuildNot(p->builder, x.value, "");
		res.type = x.type;
		return res;
	case Token_Sub: // Number negation
		if (is_type_integer(x.type)) {
			res.value = LLVMBuildNeg(p->builder, x.value, "");
		} else if (is_type_float(x.type)) {
			res.value = LLVMBuildFNeg(p->builder, x.value, "");
		} else if (is_type_complex(x.type)) {
			LLVMValueRef v0 = LLVMBuildFNeg(p->builder, LLVMBuildExtractValue(p->builder, x.value, 0, ""), "");
			LLVMValueRef v1 = LLVMBuildFNeg(p->builder, LLVMBuildExtractValue(p->builder, x.value, 1, ""), "");

			lbAddr addr = lb_add_local_generated(p, x.type, false);
			LLVMTypeRef type = llvm_addr_type(p->module, addr.addr);
			LLVMBuildStore(p->builder, v0, LLVMBuildStructGEP2(p->builder, type, addr.addr.value, 0, ""));
			LLVMBuildStore(p->builder, v1, LLVMBuildStructGEP2(p->builder, type, addr.addr.value, 1, ""));
			return lb_addr_load(p, addr);

		} else if (is_type_quaternion(x.type)) {
			LLVMValueRef v0 = LLVMBuildFNeg(p->builder, LLVMBuildExtractValue(p->builder, x.value, 0, ""), "");
			LLVMValueRef v1 = LLVMBuildFNeg(p->builder, LLVMBuildExtractValue(p->builder, x.value, 1, ""), "");
			LLVMValueRef v2 = LLVMBuildFNeg(p->builder, LLVMBuildExtractValue(p->builder, x.value, 2, ""), "");
			LLVMValueRef v3 = LLVMBuildFNeg(p->builder, LLVMBuildExtractValue(p->builder, x.value, 3, ""), "");

			lbAddr addr = lb_add_local_generated(p, x.type, false);
			LLVMTypeRef type = llvm_addr_type(p->module, addr.addr);
			LLVMBuildStore(p->builder, v0, LLVMBuildStructGEP2(p->builder, type, addr.addr.value, 0, ""));
			LLVMBuildStore(p->builder, v1, LLVMBuildStructGEP2(p->builder, type, addr.addr.value, 1, ""));
			LLVMBuildStore(p->builder, v2, LLVMBuildStructGEP2(p->builder, type, addr.addr.value, 2, ""));
			LLVMBuildStore(p->builder, v3, LLVMBuildStructGEP2(p->builder, type, addr.addr.value, 3, ""));
			return lb_addr_load(p, addr);
		} else if (is_type_simd_vector(x.type)) {
			Type *elem = base_array_type(x.type);
			if (is_type_float(elem)) {
				res.value = LLVMBuildFNeg(p->builder, x.value, "");
			} else {
				res.value = LLVMBuildNeg(p->builder, x.value, "");
			}
		} else if (is_type_matrix(x.type)) {
			lbValue zero = {};
			zero.value = LLVMConstNull(lb_type(p->module, type));
			zero.type = type;
			return lb_emit_arith_matrix(p, Token_Sub, zero, x, type, true);
		} else {
			GB_PANIC("Unhandled type %s", type_to_string(x.type));
		}
		res.type = x.type;
		return res;
	}

	return res;
}

gb_internal bool lb_try_direct_vector_arith(lbProcedure *p, TokenKind op, lbValue lhs, lbValue rhs, Type *type, lbValue *res_) {
	GB_ASSERT(is_type_array_like(type));
	Type *elem_type = base_array_type(type);

	// NOTE(bill): Shift operations cannot be easily dealt with due to Odin's semantics
	if (op == Token_Shl || op == Token_Shr) {
		return false;
	}

	if (!LLVMIsALoadInst(lhs.value) || !LLVMIsALoadInst(rhs.value)) {
		return false;
	}

	lbValue lhs_ptr = {};
	lbValue rhs_ptr = {};
	lhs_ptr.value = LLVMGetOperand(lhs.value, 0);
	lhs_ptr.type = alloc_type_pointer(lhs.type);
	rhs_ptr.value = LLVMGetOperand(rhs.value, 0);
	rhs_ptr.type = alloc_type_pointer(rhs.type);

	LLVMTypeRef vector_type0 = nullptr;
	LLVMTypeRef vector_type1 = nullptr;
	if (lb_try_vector_cast(p->module, lhs_ptr, &vector_type0) &&
	    lb_try_vector_cast(p->module, rhs_ptr, &vector_type1)) {
		GB_ASSERT(vector_type0 == vector_type1);
		LLVMTypeRef vector_type = vector_type0;

		LLVMValueRef lhs_vp = LLVMBuildPointerCast(p->builder, lhs_ptr.value, LLVMPointerType(vector_type, 0), "");
		LLVMValueRef rhs_vp = LLVMBuildPointerCast(p->builder, rhs_ptr.value, LLVMPointerType(vector_type, 0), "");
		LLVMValueRef x = LLVMBuildLoad2(p->builder, vector_type, lhs_vp, "");
		LLVMValueRef y = LLVMBuildLoad2(p->builder, vector_type, rhs_vp, "");
		LLVMValueRef z = nullptr;

		Type *integral_type = base_type(elem_type);
		if (is_type_simd_vector(integral_type)) {
			integral_type = core_array_type(integral_type);
		}
		if (is_type_bit_set(integral_type)) {
			switch (op) {
			case Token_Add: op = Token_Or;     break;
			case Token_Sub: op = Token_AndNot; break;
			}
		}

		if (is_type_float(integral_type)) {
			switch (op) {
			case Token_Add:
				z = LLVMBuildFAdd(p->builder, x, y, "");
				break;
			case Token_Sub:
				z = LLVMBuildFSub(p->builder, x, y, "");
				break;
			case Token_Mul:
				z = LLVMBuildFMul(p->builder, x, y, "");
				break;
			case Token_Quo:
				z = LLVMBuildFDiv(p->builder, x, y, "");
				break;
			case Token_Mod:
				z = LLVMBuildFRem(p->builder, x, y, "");
				break;
			default:
				GB_PANIC("Unsupported vector operation %.*s", LIT(token_strings[op]));
				break;
			}

		} else {

			switch (op) {
			case Token_Add:
				z = LLVMBuildAdd(p->builder, x, y, "");
				break;
			case Token_Sub:
				z = LLVMBuildSub(p->builder, x, y, "");
				break;
			case Token_Mul:
				z = LLVMBuildMul(p->builder, x, y, "");
				break;
			case Token_Quo:
				if (is_type_unsigned(integral_type)) {
					z = LLVMBuildUDiv(p->builder, x, y, "");
				} else {
					z = LLVMBuildSDiv(p->builder, x, y, "");
				}
				break;
			case Token_Mod:
				if (is_type_unsigned(integral_type)) {
					z = LLVMBuildURem(p->builder, x, y, "");
				} else {
					z = LLVMBuildSRem(p->builder, x, y, "");
				}
				break;
			case Token_ModMod:
				if (is_type_unsigned(integral_type)) {
					z = LLVMBuildURem(p->builder, x, y, "");
				} else {
					LLVMValueRef a = LLVMBuildSRem(p->builder, x, y, "");
					LLVMValueRef b = LLVMBuildAdd(p->builder, a, y, "");
					z = LLVMBuildSRem(p->builder, b, y, "");
				}
				break;
			case Token_And:
				z = LLVMBuildAnd(p->builder, x, y, "");
				break;
			case Token_AndNot:
				z = LLVMBuildAnd(p->builder, x, LLVMBuildNot(p->builder, y, ""), "");
				break;
			case Token_Or:
				z = LLVMBuildOr(p->builder, x, y, "");
				break;
			case Token_Xor:
				z = LLVMBuildXor(p->builder, x, y, "");
				break;
			default:
				GB_PANIC("Unsupported vector operation");
				break;
			}
		}


		if (z != nullptr) {
			lbAddr res = lb_add_local_generated_temp(p, type, lb_alignof(vector_type));

			LLVMValueRef vp = LLVMBuildPointerCast(p->builder, res.addr.value, LLVMPointerType(vector_type, 0), "");
			LLVMBuildStore(p->builder, z, vp);
			lbValue v = lb_addr_load(p, res);
			if (res_) *res_ = v;
			return true;
		}
	}

	return false;
}


gb_internal lbValue lb_emit_arith_array(lbProcedure *p, TokenKind op, lbValue lhs, lbValue rhs, Type *type) {
	GB_ASSERT(is_type_array_like(lhs.type) || is_type_array_like(rhs.type));

	lhs = lb_emit_conv(p, lhs, type);
	rhs = lb_emit_conv(p, rhs, type);

	GB_ASSERT(is_type_array_like(type));
	Type *elem_type = base_array_type(type);

	i64 count = get_array_type_count(type);
	unsigned n = cast(unsigned)count;

	// NOTE(bill, 2021-06-12): Try to do a direct operation as a vector, if possible
	lbValue direct_vector_res = {};
	if (lb_try_direct_vector_arith(p, op, lhs, rhs, type, &direct_vector_res)) {
		return direct_vector_res;
	}

	bool inline_array_arith = lb_can_try_to_inline_array_arith(type);
	if (inline_array_arith) {

		auto dst_ptrs = slice_make<lbValue>(temporary_allocator(), n);

		auto a_loads = slice_make<lbValue>(temporary_allocator(), n);
		auto b_loads = slice_make<lbValue>(temporary_allocator(), n);
		auto c_ops = slice_make<lbValue>(temporary_allocator(), n);

		for (unsigned i = 0; i < n; i++) {
			a_loads[i].value = LLVMBuildExtractValue(p->builder, lhs.value, i, "");
			a_loads[i].type = elem_type;
		}
		for (unsigned i = 0; i < n; i++) {
			b_loads[i].value = LLVMBuildExtractValue(p->builder, rhs.value, i, "");
			b_loads[i].type = elem_type;
		}
		for (unsigned i = 0; i < n; i++) {
			c_ops[i] = lb_emit_arith(p, op, a_loads[i], b_loads[i], elem_type);
		}

		lbAddr res = lb_add_local_generated(p, type, false);
		for (unsigned i = 0; i < n; i++) {
			dst_ptrs[i] = lb_emit_array_epi(p, res.addr, i);
		}
		for (unsigned i = 0; i < n; i++) {
			lb_emit_store(p, dst_ptrs[i], c_ops[i]);
		}


		return lb_addr_load(p, res);
	} else {
		lbValue x = lb_address_from_load_or_generate_local(p, lhs);
		lbValue y = lb_address_from_load_or_generate_local(p, rhs);

		lbAddr res = lb_add_local_generated(p, type, false);

		auto loop_data = lb_loop_start(p, cast(isize)count, t_i32);

		lbValue a_ptr = lb_emit_array_ep(p, x, loop_data.idx);
		lbValue b_ptr = lb_emit_array_ep(p, y, loop_data.idx);
		lbValue dst_ptr = lb_emit_array_ep(p, res.addr, loop_data.idx);

		lbValue a = lb_emit_load(p, a_ptr);
		lbValue b = lb_emit_load(p, b_ptr);
		lbValue c = lb_emit_arith(p, op, a, b, elem_type);
		lb_emit_store(p, dst_ptr, c);

		lb_loop_end(p, loop_data);

		return lb_addr_load(p, res);
	}
}

gb_internal bool lb_is_matrix_simdable(Type *t) {
	Type *mt = base_type(t);
	GB_ASSERT(mt->kind == Type_Matrix);
	
	Type *elem = core_type(mt->Matrix.elem);
	if (is_type_complex(elem)) {
		return false;
	}
	
	if (is_type_different_to_arch_endianness(elem)) {
		return false;
	}
	
	switch (build_context.metrics.arch) {
	default:
		return false;
	case TargetArch_amd64:
	case TargetArch_arm64:
		break;
	}

	if (type_align_of(t) < 16) {
		// it's not aligned well enough to use the vector instructions
		return false;
	}
	if ((mt->Matrix.row_count & 1) ^ (mt->Matrix.column_count & 1)) {
		return false;
	}
	
	if (elem->kind == Type_Basic) {
		switch (elem->Basic.kind) {
		case Basic_f16:
		case Basic_f16le:
		case Basic_f16be:
			switch (build_context.metrics.arch) {
			case TargetArch_amd64:
				return false;
			case TargetArch_arm64:
				// TODO(bill): determine when this is fine
				return true;
			case TargetArch_i386:
			case TargetArch_wasm32:
			case TargetArch_wasm64p32:
				return false;
			}
		}
	}
	
	return true;
}


gb_internal LLVMValueRef lb_matrix_to_vector(lbProcedure *p, lbValue matrix) {
	Type *mt = base_type(matrix.type);
	GB_ASSERT(mt->kind == Type_Matrix);
	LLVMTypeRef elem_type = lb_type(p->module, mt->Matrix.elem);
	
	unsigned total_count = cast(unsigned)matrix_type_total_internal_elems(mt);
	LLVMTypeRef total_matrix_type = LLVMVectorType(elem_type, total_count);
	
#if 1
	LLVMValueRef ptr = lb_address_from_load_or_generate_local(p, matrix).value;
	LLVMValueRef matrix_vector_ptr = LLVMBuildPointerCast(p->builder, ptr, LLVMPointerType(total_matrix_type, 0), "");
	LLVMValueRef matrix_vector = LLVMBuildLoad2(p->builder, total_matrix_type, matrix_vector_ptr, "");
	LLVMSetAlignment(matrix_vector, cast(unsigned)type_align_of(mt));
	return matrix_vector;
#else
	LLVMValueRef matrix_vector = LLVMBuildBitCast(p->builder, matrix.value, total_matrix_type, "");
	return matrix_vector;
#endif
}

gb_internal LLVMValueRef lb_matrix_trimmed_vector_mask(lbProcedure *p, Type *mt) {
	mt = base_type(mt);
	GB_ASSERT(mt->kind == Type_Matrix);

	unsigned stride = cast(unsigned)matrix_type_stride_in_elems(mt);
	unsigned row_count = cast(unsigned)mt->Matrix.row_count;
	unsigned column_count = cast(unsigned)mt->Matrix.column_count;
	unsigned mask_elems_index = 0;
	auto mask_elems = slice_make<LLVMValueRef>(permanent_allocator(), row_count*column_count);
	for (unsigned j = 0; j < column_count; j++) {
		for (unsigned i = 0; i < row_count; i++) {
			unsigned offset = stride*j + i;
			mask_elems[mask_elems_index++] = lb_const_int(p->module, t_u32, offset).value;
		}
	}

	LLVMValueRef mask = LLVMConstVector(mask_elems.data, cast(unsigned)mask_elems.count);
	return mask;
}

gb_internal LLVMValueRef lb_matrix_to_trimmed_vector(lbProcedure *p, lbValue m) {
	LLVMValueRef vector = lb_matrix_to_vector(p, m);

	Type *mt = base_type(m.type);
	GB_ASSERT(mt->kind == Type_Matrix);

	unsigned stride = cast(unsigned)matrix_type_stride_in_elems(mt);
	unsigned row_count = cast(unsigned)mt->Matrix.row_count;
	if (stride == row_count) {
		return vector;
	}

	LLVMValueRef mask = lb_matrix_trimmed_vector_mask(p, mt);
	LLVMValueRef trimmed_vector = llvm_basic_shuffle(p, vector, mask);
	return trimmed_vector;
}


gb_internal lbValue lb_emit_matrix_tranpose(lbProcedure *p, lbValue m, Type *type) {
	if (is_type_array(m.type)) {
		i32 rank = type_math_rank(m.type);
		if (rank == 2) {
			lbAddr addr = lb_add_local_generated(p, type, false);
			lbValue dst = addr.addr;
			lbValue src = m;
			i32 n = cast(i32)get_array_type_count(m.type);
			i32 m = cast(i32)get_array_type_count(type);
			// m.type == [n][m]T
			// type   == [m][n]T

			for (i32 j = 0; j < m; j++) {
				lbValue dst_col = lb_emit_struct_ep(p, dst, j);
				for (i32 i = 0; i < n; i++) {
					lbValue dst_row = lb_emit_struct_ep(p, dst_col, i);
					lbValue src_col = lb_emit_struct_ev(p, src, i);
					lbValue src_row = lb_emit_struct_ev(p, src_col, j);
					lb_emit_store(p, dst_row, src_row);
				}
			}
			return lb_addr_load(p, addr);
		}
		// no-op
		m.type = type;
		return m;
	}
	Type *mt = base_type(m.type);
	GB_ASSERT(mt->kind == Type_Matrix);

	if (lb_is_matrix_simdable(mt)) {
		unsigned stride = cast(unsigned)matrix_type_stride_in_elems(mt);
		unsigned row_count    = cast(unsigned)mt->Matrix.row_count;
		unsigned column_count = cast(unsigned)mt->Matrix.column_count;

		auto rows = slice_make<LLVMValueRef>(permanent_allocator(), row_count);
		auto mask_elems = slice_make<LLVMValueRef>(permanent_allocator(), column_count);

		LLVMValueRef vector = lb_matrix_to_vector(p, m);
		for (unsigned i = 0; i < row_count; i++) {
			for (unsigned j = 0; j < column_count; j++) {
				unsigned offset = stride*j + i;
				mask_elems[j] = lb_const_int(p->module, t_u32, offset).value;
			}

			// transpose mask
			LLVMValueRef mask = LLVMConstVector(mask_elems.data, column_count);
			LLVMValueRef row = llvm_basic_shuffle(p, vector, mask);
			rows[i] = row;
		}

		lbAddr res = lb_add_local_generated(p, type, true);
		for_array(i, rows) {
			LLVMValueRef row = rows[i];
			lbValue dst_row_ptr = lb_emit_matrix_epi(p, res.addr, 0, i);
			LLVMValueRef ptr = dst_row_ptr.value;
			ptr = LLVMBuildPointerCast(p->builder, ptr, LLVMPointerType(LLVMTypeOf(row), 0), "");
			LLVMBuildStore(p->builder, row, ptr);
		}

		return lb_addr_load(p, res);
	}

	lbAddr res = lb_add_local_generated(p, type, true);

	i64 row_count = mt->Matrix.row_count;
	i64 column_count = mt->Matrix.column_count;
	for (i64 j = 0; j < column_count; j++) {
		for (i64 i = 0; i < row_count; i++) {
			lbValue src = lb_emit_matrix_ev(p, m, i, j);
			lbValue dst = lb_emit_matrix_epi(p, res.addr, j, i);
			lb_emit_store(p, dst, src);
		}
	}
	return lb_addr_load(p, res);
}

gb_internal lbValue lb_matrix_cast_vector_to_type(lbProcedure *p, LLVMValueRef vector, Type *type) {
	lbAddr res = lb_add_local_generated(p, type, true);
	LLVMValueRef res_ptr = res.addr.value;
	unsigned alignment = cast(unsigned)gb_max(type_align_of(type), lb_alignof(LLVMTypeOf(vector)));
	LLVMSetAlignment(res_ptr, alignment);

	res_ptr = LLVMBuildPointerCast(p->builder, res_ptr, LLVMPointerType(LLVMTypeOf(vector), 0), "");
	LLVMBuildStore(p->builder, vector, res_ptr);

	return lb_addr_load(p, res);
}

gb_internal lbValue lb_emit_matrix_flatten(lbProcedure *p, lbValue m, Type *type) {
	if (is_type_array(m.type)) {
		// no-op
		m.type = type;
		return m;
	}
	Type *mt = base_type(m.type);
	GB_ASSERT(mt->kind == Type_Matrix);

	// TODO(bill): Determine why this fails on Windows sometimes
	if (false && lb_is_matrix_simdable(mt)) {
		LLVMValueRef vector = lb_matrix_to_trimmed_vector(p, m);
		return lb_matrix_cast_vector_to_type(p, vector, type);
	}

	lbAddr res = lb_add_local_generated(p, type, true);

	i64 row_count = mt->Matrix.row_count;
	i64 column_count = mt->Matrix.column_count;
	TEMPORARY_ALLOCATOR_GUARD();

	auto srcs = array_make<lbValue>(temporary_allocator(), 0, row_count*column_count);
	auto dsts = array_make<lbValue>(temporary_allocator(), 0, row_count*column_count);

	for (i64 j = 0; j < column_count; j++) {
		for (i64 i = 0; i < row_count; i++) {
			lbValue src = lb_emit_matrix_ev(p, m, i, j);
			array_add(&srcs, src);
		}
	}

	for (i64 j = 0; j < column_count; j++) {
		for (i64 i = 0; i < row_count; i++) {
			lbValue dst = lb_emit_array_epi(p, res.addr, i + j*row_count);
			array_add(&dsts, dst);
		}
	}

	GB_ASSERT(srcs.count == dsts.count);
	for_array(i, srcs) {
		lb_emit_store(p, dsts[i], srcs[i]);
	}
	return lb_addr_load(p, res);
}


gb_internal lbValue lb_emit_outer_product(lbProcedure *p, lbValue a, lbValue b, Type *type) {
	Type *mt = base_type(type);
	Type *at = base_type(a.type);
	Type *bt = base_type(b.type);
	GB_ASSERT(mt->kind == Type_Matrix);
	GB_ASSERT(at->kind == Type_Array);
	GB_ASSERT(bt->kind == Type_Array);


	i64 row_count = mt->Matrix.row_count;
	i64 column_count = mt->Matrix.column_count;

	GB_ASSERT(row_count == at->Array.count);
	GB_ASSERT(column_count == bt->Array.count);


	lbAddr res = lb_add_local_generated(p, type, true);

	for (i64 j = 0; j < column_count; j++) {
		for (i64 i = 0; i < row_count; i++) {
			lbValue x = lb_emit_struct_ev(p, a, cast(i32)i);
			lbValue y = lb_emit_struct_ev(p, b, cast(i32)j);
			lbValue src = lb_emit_arith(p, Token_Mul, x, y, mt->Matrix.elem);
			lbValue dst = lb_emit_matrix_epi(p, res.addr, i, j);
			lb_emit_store(p, dst, src);
		}
	}
	return lb_addr_load(p, res);

}

gb_internal lbValue lb_emit_matrix_mul(lbProcedure *p, lbValue lhs, lbValue rhs, Type *type) {
	// TODO(bill): Handle edge case for f16 types on x86(-64) platforms

	Type *xt = base_type(lhs.type);
	Type *yt = base_type(rhs.type);

	GB_ASSERT(is_type_matrix(type));
	GB_ASSERT(is_type_matrix(xt));
	GB_ASSERT(is_type_matrix(yt));
	GB_ASSERT(xt->Matrix.column_count == yt->Matrix.row_count);
	GB_ASSERT(are_types_identical(xt->Matrix.elem, yt->Matrix.elem));

	Type *elem = xt->Matrix.elem;

	unsigned outer_rows    = cast(unsigned)xt->Matrix.row_count;
	unsigned inner         = cast(unsigned)xt->Matrix.column_count;
	unsigned outer_columns = cast(unsigned)yt->Matrix.column_count;

	if (lb_is_matrix_simdable(xt)) {
		unsigned x_stride = cast(unsigned)matrix_type_stride_in_elems(xt);
		unsigned y_stride = cast(unsigned)matrix_type_stride_in_elems(yt);

		auto x_rows    = slice_make<LLVMValueRef>(permanent_allocator(), outer_rows);
		auto y_columns = slice_make<LLVMValueRef>(permanent_allocator(), outer_columns);

		LLVMValueRef x_vector = lb_matrix_to_vector(p, lhs);
		LLVMValueRef y_vector = lb_matrix_to_vector(p, rhs);

		auto mask_elems = slice_make<LLVMValueRef>(permanent_allocator(), inner);
		for (unsigned i = 0; i < outer_rows; i++) {
			for (unsigned j = 0; j < inner; j++) {
				unsigned offset = x_stride*j + i;
				mask_elems[j] = lb_const_int(p->module, t_u32, offset).value;
			}

			// transpose mask
			LLVMValueRef mask = LLVMConstVector(mask_elems.data, inner);
			LLVMValueRef row = llvm_basic_shuffle(p, x_vector, mask);
			x_rows[i] = row;
		}

		for (unsigned i = 0; i < outer_columns; i++) {
			LLVMValueRef mask = llvm_mask_iota(p->module, y_stride*i, inner);
			LLVMValueRef column = llvm_basic_shuffle(p, y_vector, mask);
			y_columns[i] = column;
		}

		lbAddr res = lb_add_local_generated(p, type, true);
		for_array(i, x_rows) {
			LLVMValueRef x_row = x_rows[i];
			for_array(j, y_columns) {
				LLVMValueRef y_column = y_columns[j];
				LLVMValueRef elem = llvm_vector_dot(p, x_row, y_column);
				lbValue dst = lb_emit_matrix_epi(p, res.addr, i, j);
				LLVMBuildStore(p->builder, elem, dst.value);
			}
		}
		return lb_addr_load(p, res);
	}

	{
		lbAddr res = lb_add_local_generated(p, type, true);

		auto inners = slice_make<lbValue[2]>(permanent_allocator(), inner);

		for (unsigned j = 0; j < outer_columns; j++) {
			for (unsigned i = 0; i < outer_rows; i++) {
				lbValue dst = lb_emit_matrix_epi(p, res.addr, i, j);
				for (unsigned k = 0; k < inner; k++) {
					inners[k][0] = lb_emit_matrix_ev(p, lhs, i, k);
					inners[k][1] = lb_emit_matrix_ev(p, rhs, k, j);
				}

				lbValue sum = lb_const_nil(p->module, elem);
				for (unsigned k = 0; k < inner; k++) {
					lbValue a = inners[k][0];
					lbValue b = inners[k][1];
					sum = lb_emit_mul_add(p, a, b, sum, elem);
				}
				lb_emit_store(p, dst, sum);
			}
		}

		return lb_addr_load(p, res);
	}
}

gb_internal lbValue lb_emit_matrix_mul_vector(lbProcedure *p, lbValue lhs, lbValue rhs, Type *type) {
	// TODO(bill): Handle edge case for f16 types on x86(-64) platforms

	Type *mt = base_type(lhs.type);
	Type *vt = base_type(rhs.type);

	GB_ASSERT(is_type_matrix(mt));
	GB_ASSERT(is_type_array_like(vt));

	i64 vector_count = get_array_type_count(vt);

	GB_ASSERT(mt->Matrix.column_count == vector_count);
	GB_ASSERT(are_types_identical(mt->Matrix.elem, base_array_type(vt)));

	Type *elem = mt->Matrix.elem;

	if (lb_is_matrix_simdable(mt)) {
		unsigned stride = cast(unsigned)matrix_type_stride_in_elems(mt);

		unsigned row_count = cast(unsigned)mt->Matrix.row_count;
		unsigned column_count = cast(unsigned)mt->Matrix.column_count;
		auto m_columns = slice_make<LLVMValueRef>(permanent_allocator(), column_count);
		auto v_rows = slice_make<LLVMValueRef>(permanent_allocator(), column_count);

		LLVMValueRef matrix_vector = lb_matrix_to_vector(p, lhs);

		for (unsigned column_index = 0; column_index < column_count; column_index++) {
			LLVMValueRef mask = llvm_mask_iota(p->module, stride*column_index, row_count);
			LLVMValueRef column = llvm_basic_shuffle(p, matrix_vector, mask);
			m_columns[column_index] = column;
		}

		for (unsigned row_index = 0; row_index < column_count; row_index++) {
			LLVMValueRef value = lb_emit_struct_ev(p, rhs, row_index).value;
			LLVMValueRef row = llvm_vector_broadcast(p, value, row_count);
			v_rows[row_index] = row;
		}

		GB_ASSERT(column_count > 0);

		LLVMValueRef vector = nullptr;
		for (i64 i = 0; i < column_count; i++) {
			if (i == 0) {
				vector = llvm_vector_mul(p, m_columns[i], v_rows[i]);
			} else {
				vector = llvm_vector_mul_add(p, m_columns[i], v_rows[i], vector);
			}
		}

		return lb_matrix_cast_vector_to_type(p, vector, type);
	}

	lbAddr res = lb_add_local_generated(p, type, true);

	for (i64 i = 0; i < mt->Matrix.row_count; i++) {
		for (i64 j = 0; j < mt->Matrix.column_count; j++) {
			lbValue dst = lb_emit_matrix_epi(p, res.addr, i, 0);
			lbValue d0 = lb_emit_load(p, dst);

			lbValue a = lb_emit_matrix_ev(p, lhs, i, j);
			lbValue b = lb_emit_struct_ev(p, rhs, cast(i32)j);
			lbValue c = lb_emit_mul_add(p, a, b, d0, elem);
			lb_emit_store(p, dst, c);
		}
	}

	return lb_addr_load(p, res);
}

gb_internal lbValue lb_emit_vector_mul_matrix(lbProcedure *p, lbValue lhs, lbValue rhs, Type *type) {
	// TODO(bill): Handle edge case for f16 types on x86(-64) platforms

	Type *mt = base_type(rhs.type);
	Type *vt = base_type(lhs.type);

	GB_ASSERT(is_type_matrix(mt));
	GB_ASSERT(is_type_array_like(vt));

	i64 vector_count = get_array_type_count(vt);

	GB_ASSERT(vector_count == mt->Matrix.row_count);
	GB_ASSERT(are_types_identical(mt->Matrix.elem, base_array_type(vt)));

	Type *elem = mt->Matrix.elem;

	if (lb_is_matrix_simdable(mt)) {
		unsigned stride = cast(unsigned)matrix_type_stride_in_elems(mt);

		unsigned row_count = cast(unsigned)mt->Matrix.row_count;
		unsigned column_count = cast(unsigned)mt->Matrix.column_count; gb_unused(column_count);
		auto m_columns = slice_make<LLVMValueRef>(permanent_allocator(), row_count);
		auto v_rows = slice_make<LLVMValueRef>(permanent_allocator(), row_count);

		LLVMValueRef matrix_vector = lb_matrix_to_vector(p, rhs);

		auto mask_elems = slice_make<LLVMValueRef>(permanent_allocator(), column_count);
		for (unsigned row_index = 0; row_index < row_count; row_index++) {
			for (unsigned column_index = 0; column_index < column_count; column_index++) {
				unsigned offset = row_index + column_index*stride;
				mask_elems[column_index] = lb_const_int(p->module, t_u32, offset).value;
			}

			// transpose mask
			LLVMValueRef mask = LLVMConstVector(mask_elems.data, column_count);
			LLVMValueRef column = llvm_basic_shuffle(p, matrix_vector, mask);
			m_columns[row_index] = column;
		}

		for (unsigned column_index = 0; column_index < row_count; column_index++) {
			LLVMValueRef value = lb_emit_struct_ev(p, lhs, column_index).value;
			LLVMValueRef row = llvm_vector_broadcast(p, value, column_count);
			v_rows[column_index] = row;
		}

		GB_ASSERT(row_count > 0);

		LLVMValueRef vector = nullptr;
		for (i64 i = 0; i < row_count; i++) {
			if (i == 0) {
				vector = llvm_vector_mul(p, v_rows[i], m_columns[i]);
			} else {
				vector = llvm_vector_mul_add(p, v_rows[i], m_columns[i], vector);
			}
		}

		lbAddr res = lb_add_local_generated(p, type, true);
		LLVMValueRef res_ptr = res.addr.value;
		unsigned alignment = cast(unsigned)gb_max(type_align_of(type), lb_alignof(LLVMTypeOf(vector)));
		LLVMSetAlignment(res_ptr, alignment);

		res_ptr = LLVMBuildPointerCast(p->builder, res_ptr, LLVMPointerType(LLVMTypeOf(vector), 0), "");
		LLVMBuildStore(p->builder, vector, res_ptr);

		return lb_addr_load(p, res);
	}

	lbAddr res = lb_add_local_generated(p, type, true);

	for (i64 j = 0; j < mt->Matrix.column_count; j++) {
		for (i64 k = 0; k < mt->Matrix.row_count; k++) {
			lbValue dst = lb_emit_matrix_epi(p, res.addr, 0, j);
			lbValue d0 = lb_emit_load(p, dst);

			lbValue a = lb_emit_struct_ev(p, lhs, cast(i32)k);
			lbValue b = lb_emit_matrix_ev(p, rhs, k, j);
			lbValue c = lb_emit_mul_add(p, a, b, d0, elem);
			lb_emit_store(p, dst, c);
		}
	}

	return lb_addr_load(p, res);
}




gb_internal lbValue lb_emit_arith_matrix(lbProcedure *p, TokenKind op, lbValue lhs, lbValue rhs, Type *type, bool component_wise) {
	GB_ASSERT(is_type_matrix(lhs.type) || is_type_matrix(rhs.type));

	if (op == Token_Mul && !component_wise) {
		Type *xt = base_type(lhs.type);
		Type *yt = base_type(rhs.type);

		if (xt->kind == Type_Matrix) {
			if (yt->kind == Type_Matrix) {
				return lb_emit_matrix_mul(p, lhs, rhs, type);
			} else if (is_type_array_like(yt)) {
				return lb_emit_matrix_mul_vector(p, lhs, rhs, type);
			}
		} else if (is_type_array_like(xt)) {
			GB_ASSERT(yt->kind == Type_Matrix);
			return lb_emit_vector_mul_matrix(p, lhs, rhs, type);
		} else {
			GB_ASSERT(xt->kind == Type_Basic);
			GB_ASSERT(yt->kind == Type_Matrix);
			GB_ASSERT(is_type_matrix(type));

			Type *array_type = alloc_type_array(yt->Matrix.elem, matrix_type_total_internal_elems(yt));
			GB_ASSERT(type_size_of(array_type) == type_size_of(yt));

			lbValue array_lhs = lb_emit_conv(p, lhs, array_type);
			lbValue array_rhs = rhs;
			array_rhs.type = array_type;

			lbValue array = lb_emit_arith(p, op, array_lhs, array_rhs, array_type);
			array.type = type;
			return array;
		}
	} else {
		if (is_type_matrix(lhs.type)) {
			rhs = lb_emit_conv(p, rhs, lhs.type);
		} else {
			lhs = lb_emit_conv(p, lhs, rhs.type);
		}

		Type *xt = base_type(lhs.type);
		Type *yt = base_type(rhs.type);

		GB_ASSERT_MSG(are_types_identical(xt, yt), "%s %.*s %s", type_to_string(lhs.type), LIT(token_strings[op]), type_to_string(rhs.type));
		GB_ASSERT(xt->kind == Type_Matrix);
		// element-wise arithmetic
		// pretend it is an array
		lbValue array_lhs = lhs;
		lbValue array_rhs = rhs;
		Type *array_type = alloc_type_array(xt->Matrix.elem, matrix_type_total_internal_elems(xt));
		GB_ASSERT(type_size_of(array_type) == type_size_of(xt));

		array_lhs.type = array_type;
		array_rhs.type = array_type;

		if (token_is_comparison(op)) {
			lbValue res = lb_emit_comp(p, op, array_lhs, array_rhs);
			return lb_emit_conv(p, res, type);
		} else {
			lbValue array = lb_emit_arith(p, op, array_lhs, array_rhs, array_type);
			array.type = type;
			return array;
		}

	}

	GB_PANIC("TODO: lb_emit_arith_matrix");

	return {};
}



gb_internal lbValue lb_emit_arith(lbProcedure *p, TokenKind op, lbValue lhs, lbValue rhs, Type *type) {
	if (is_type_array_like(lhs.type) || is_type_array_like(rhs.type)) {
		return lb_emit_arith_array(p, op, lhs, rhs, type);
	} else if (is_type_matrix(lhs.type) || is_type_matrix(rhs.type)) {
		return lb_emit_arith_matrix(p, op, lhs, rhs, type, false);
	} else if (is_type_complex(type)) {
		lhs = lb_emit_conv(p, lhs, type);
		rhs = lb_emit_conv(p, rhs, type);

		Type *ft = base_complex_elem_type(type);

		if (op == Token_Quo) {
			TEMPORARY_ALLOCATOR_GUARD();

			auto args = array_make<lbValue>(temporary_allocator(), 2);
			args[0] = lhs;
			args[1] = rhs;

			switch (type_size_of(ft)) {
			case 2: return lb_emit_runtime_call(p, "quo_complex32", args);
			case 4: return lb_emit_runtime_call(p, "quo_complex64", args);
			case 8: return lb_emit_runtime_call(p, "quo_complex128", args);
			default: GB_PANIC("Unknown float type"); break;
			}
		}

		lbAddr res = lb_add_local_generated(p, type, false); // NOTE: initialized in full later
		lbValue a = lb_emit_struct_ev(p, lhs, 0);
		lbValue b = lb_emit_struct_ev(p, lhs, 1);
		lbValue c = lb_emit_struct_ev(p, rhs, 0);
		lbValue d = lb_emit_struct_ev(p, rhs, 1);

		lbValue real = {};
		lbValue imag = {};

		switch (op) {
		case Token_Add:
			real = lb_emit_arith(p, Token_Add, a, c, ft);
			imag = lb_emit_arith(p, Token_Add, b, d, ft);
			break;
		case Token_Sub:
			real = lb_emit_arith(p, Token_Sub, a, c, ft);
			imag = lb_emit_arith(p, Token_Sub, b, d, ft);
			break;
		case Token_Mul: {
			lbValue x = lb_emit_arith(p, Token_Mul, a, c, ft);
			lbValue y = lb_emit_arith(p, Token_Mul, b, d, ft);
			real = lb_emit_arith(p, Token_Sub, x, y, ft);
			lbValue z = lb_emit_arith(p, Token_Mul, b, c, ft);
			lbValue w = lb_emit_arith(p, Token_Mul, a, d, ft);
			imag = lb_emit_arith(p, Token_Add, z, w, ft);
			break;
		}
		}

		lb_emit_store(p, lb_emit_struct_ep(p, res.addr, 0), real);
		lb_emit_store(p, lb_emit_struct_ep(p, res.addr, 1), imag);

		return lb_addr_load(p, res);
	} else if (is_type_quaternion(type)) {
		lhs = lb_emit_conv(p, lhs, type);
		rhs = lb_emit_conv(p, rhs, type);

		Type *ft = base_complex_elem_type(type);

		if (op == Token_Add || op == Token_Sub) {
			lbAddr res = lb_add_local_generated(p, type, false); // NOTE: initialized in full later
			lbValue x0 = lb_emit_struct_ev(p, lhs, 0);
			lbValue x1 = lb_emit_struct_ev(p, lhs, 1);
			lbValue x2 = lb_emit_struct_ev(p, lhs, 2);
			lbValue x3 = lb_emit_struct_ev(p, lhs, 3);

			lbValue y0 = lb_emit_struct_ev(p, rhs, 0);
			lbValue y1 = lb_emit_struct_ev(p, rhs, 1);
			lbValue y2 = lb_emit_struct_ev(p, rhs, 2);
			lbValue y3 = lb_emit_struct_ev(p, rhs, 3);

			lbValue z0 = lb_emit_arith(p, op, x0, y0, ft);
			lbValue z1 = lb_emit_arith(p, op, x1, y1, ft);
			lbValue z2 = lb_emit_arith(p, op, x2, y2, ft);
			lbValue z3 = lb_emit_arith(p, op, x3, y3, ft);

			lb_emit_store(p, lb_emit_struct_ep(p, res.addr, 0), z0);
			lb_emit_store(p, lb_emit_struct_ep(p, res.addr, 1), z1);
			lb_emit_store(p, lb_emit_struct_ep(p, res.addr, 2), z2);
			lb_emit_store(p, lb_emit_struct_ep(p, res.addr, 3), z3);

			return lb_addr_load(p, res);
		} else if (op == Token_Mul) {
			TEMPORARY_ALLOCATOR_GUARD();

			auto args = array_make<lbValue>(temporary_allocator(), 2);
			args[0] = lhs;
			args[1] = rhs;

			switch (8*type_size_of(ft)) {
			case 16: return lb_emit_runtime_call(p, "mul_quaternion64", args);
			case 32: return lb_emit_runtime_call(p, "mul_quaternion128", args);
			case 64: return lb_emit_runtime_call(p, "mul_quaternion256", args);
			default: GB_PANIC("Unknown float type"); break;
			}
		} else if (op == Token_Quo) {
			TEMPORARY_ALLOCATOR_GUARD();

			auto args = array_make<lbValue>(temporary_allocator(), 2);
			args[0] = lhs;
			args[1] = rhs;

			switch (8*type_size_of(ft)) {
			case 16: return lb_emit_runtime_call(p, "quo_quaternion64", args);
			case 32: return lb_emit_runtime_call(p, "quo_quaternion128", args);
			case 64: return lb_emit_runtime_call(p, "quo_quaternion256", args);
			default: GB_PANIC("Unknown float type"); break;
			}
		}
	}

	lhs = lb_emit_conv(p, lhs, type);
	rhs = lb_emit_conv(p, rhs, type);

	if (is_type_integer(type) && is_type_different_to_arch_endianness(type)) {
		switch (op) {
		case Token_AndNot:
		case Token_And:
		case Token_Or:
		case Token_Xor:
			goto handle_op;
		}

		Type *platform_type = integer_endian_type_to_platform_type(type);
		lbValue x = lb_emit_byte_swap(p, lhs, integer_endian_type_to_platform_type(lhs.type));
		lbValue y = lb_emit_byte_swap(p, rhs, integer_endian_type_to_platform_type(rhs.type));

		lbValue res = lb_emit_arith(p, op, x, y, platform_type);

		return lb_emit_byte_swap(p, res, type);
	}

	if (is_type_float(type) && is_type_different_to_arch_endianness(type)) {
		Type *platform_type = integer_endian_type_to_platform_type(type);
		lbValue x = lb_emit_conv(p, lhs, integer_endian_type_to_platform_type(lhs.type));
		lbValue y = lb_emit_conv(p, rhs, integer_endian_type_to_platform_type(rhs.type));

		lbValue res = lb_emit_arith(p, op, x, y, platform_type);

		return lb_emit_byte_swap(p, res, type);
	}

handle_op:;
	lbValue res = {};
	res.type = type;

	// NOTE(bill): Bit Set Aliases for + and -
	if (is_type_bit_set(type)) {
		switch (op) {
		case Token_Add: op = Token_Or;     break;
		case Token_Sub: op = Token_AndNot; break;
		}
	}

	Type *integral_type = type;
	if (is_type_simd_vector(integral_type)) {
		integral_type = core_array_type(integral_type);
	}

	switch (op) {
	case Token_Add:
		if (is_type_float(integral_type)) {
			res.value = LLVMBuildFAdd(p->builder, lhs.value, rhs.value, "");
			return res;
		}
		res.value = LLVMBuildAdd(p->builder, lhs.value, rhs.value, "");
		return res;
	case Token_Sub:
		if (is_type_float(integral_type)) {
			res.value = LLVMBuildFSub(p->builder, lhs.value, rhs.value, "");
			return res;
		}
		res.value = LLVMBuildSub(p->builder, lhs.value, rhs.value, "");
		return res;
	case Token_Mul:
		if (is_type_float(integral_type)) {
			res.value = LLVMBuildFMul(p->builder, lhs.value, rhs.value, "");
			return res;
		}
		res.value = LLVMBuildMul(p->builder, lhs.value, rhs.value, "");
		return res;
	case Token_Quo:
		if (is_type_float(integral_type)) {
			res.value = LLVMBuildFDiv(p->builder, lhs.value, rhs.value, "");
			return res;
		} else if (is_type_unsigned(integral_type)) {
			res.value = LLVMBuildUDiv(p->builder, lhs.value, rhs.value, "");
			return res;
		}
		res.value = LLVMBuildSDiv(p->builder, lhs.value, rhs.value, "");
		return res;
	case Token_Mod:
		if (is_type_float(integral_type)) {
			res.value = LLVMBuildFRem(p->builder, lhs.value, rhs.value, "");
			return res;
		} else if (is_type_unsigned(integral_type)) {
			res.value = LLVMBuildURem(p->builder, lhs.value, rhs.value, "");
			return res;
		}
		res.value = LLVMBuildSRem(p->builder, lhs.value, rhs.value, "");
		return res;
	case Token_ModMod:
		if (is_type_unsigned(integral_type)) {
			res.value = LLVMBuildURem(p->builder, lhs.value, rhs.value, "");
			return res;
		} else {
			LLVMValueRef a = LLVMBuildSRem(p->builder, lhs.value, rhs.value, "");
			LLVMValueRef b = LLVMBuildAdd(p->builder, a, rhs.value, "");
			LLVMValueRef c = LLVMBuildSRem(p->builder, b, rhs.value, "");
			res.value = c;
			return res;
		}

	case Token_And:
		res.value = LLVMBuildAnd(p->builder, lhs.value, rhs.value, "");
		return res;
	case Token_Or:
		res.value = LLVMBuildOr(p->builder, lhs.value, rhs.value, "");
		return res;
	case Token_Xor:
		res.value = LLVMBuildXor(p->builder, lhs.value, rhs.value, "");
		return res;
	case Token_Shl:
		{
			rhs = lb_emit_conv(p, rhs, lhs.type);
			LLVMValueRef lhsval = lhs.value;
			LLVMValueRef bits = rhs.value;

			LLVMValueRef bit_size = LLVMConstInt(lb_type(p->module, rhs.type), 8*type_size_of(lhs.type), false);

			LLVMValueRef width_test = LLVMBuildICmp(p->builder, LLVMIntULT, bits, bit_size, "");

			res.value = LLVMBuildShl(p->builder, lhsval, bits, "");
			LLVMValueRef zero = LLVMConstNull(lb_type(p->module, lhs.type));
			res.value = LLVMBuildSelect(p->builder, width_test, res.value, zero, "");
			return res;
		}
	case Token_Shr:
		{
			rhs = lb_emit_conv(p, rhs, lhs.type);
			LLVMValueRef lhsval = lhs.value;
			LLVMValueRef bits = rhs.value;
			bool is_unsigned = is_type_unsigned(integral_type);

			LLVMValueRef bit_size = LLVMConstInt(lb_type(p->module, rhs.type), 8*type_size_of(lhs.type), false);

			LLVMValueRef width_test = LLVMBuildICmp(p->builder, LLVMIntULT, bits, bit_size, "");

			if (is_unsigned) {
				res.value = LLVMBuildLShr(p->builder, lhsval, bits, "");
			} else {
				res.value = LLVMBuildAShr(p->builder, lhsval, bits, "");
			}

			LLVMValueRef zero = LLVMConstNull(lb_type(p->module, lhs.type));
			res.value = LLVMBuildSelect(p->builder, width_test, res.value, zero, "");
			return res;
		}
	case Token_AndNot:
		{
			LLVMValueRef new_rhs = LLVMBuildNot(p->builder, rhs.value, "");
			res.value = LLVMBuildAnd(p->builder, lhs.value, new_rhs, "");
			return res;
		}
		break;
	}

	GB_PANIC("unhandled operator of lb_emit_arith");

	return {};
}

gb_internal bool lb_is_empty_string_constant(Ast *expr) {
	if (expr->tav.value.kind == ExactValue_String &&
	    is_type_string(expr->tav.type)) {
		String s = expr->tav.value.value_string;
		return s.len == 0;
	}
	return false;
}

gb_internal lbValue lb_build_binary_expr(lbProcedure *p, Ast *expr) {
	ast_node(be, BinaryExpr, expr);

	TypeAndValue tv = type_and_value_of_expr(expr);

	if (is_type_matrix(be->left->tav.type) || is_type_matrix(be->right->tav.type)) {
		lbValue left = lb_build_expr(p, be->left);
		lbValue right = lb_build_expr(p, be->right);
		return lb_emit_arith_matrix(p, be->op.kind, left, right, default_type(tv.type), false);
	}


	switch (be->op.kind) {
	case Token_Add:
	case Token_Sub:
	case Token_Mul:
	case Token_Quo:
	case Token_Mod:
	case Token_ModMod:
	case Token_And:
	case Token_Or:
	case Token_Xor:
	case Token_AndNot: {
		Type *type = default_type(tv.type);
		lbValue left = lb_build_expr(p, be->left);
		lbValue right = lb_build_expr(p, be->right);
		return lb_emit_arith(p, be->op.kind, left, right, type);
	}

	case Token_Shl:
	case Token_Shr: {
		lbValue left, right;
		Type *type = default_type(tv.type);
		left = lb_build_expr(p, be->left);

		if (lb_is_expr_untyped_const(be->right)) {
			// NOTE(bill): RHS shift operands can still be untyped
			// Just bypass the standard lb_build_expr
			right = lb_expr_untyped_const_to_typed(p->module, be->right, type);
		} else {
			right = lb_build_expr(p, be->right);
		}
		return lb_emit_arith(p, be->op.kind, left, right, type);
	}

	case Token_CmpEq:
	case Token_NotEq:
		if (is_type_untyped_nil(be->right->tav.type)) {
			// `x == nil` or `x != nil`
			lbValue left = lb_build_expr(p, be->left);
			lbValue cmp = lb_emit_comp_against_nil(p, be->op.kind, left);
			Type *type = default_type(tv.type);
			return lb_emit_conv(p, cmp, type);
		} else if (is_type_untyped_nil(be->left->tav.type)) {
			// `nil == x` or `nil != x`
			lbValue right = lb_build_expr(p, be->right);
			lbValue cmp = lb_emit_comp_against_nil(p, be->op.kind, right);
			Type *type = default_type(tv.type);
			return lb_emit_conv(p, cmp, type);
		} else if (lb_is_empty_string_constant(be->right)) {
			// `x == ""` or `x != ""`
			lbValue s = lb_build_expr(p, be->left);
			s = lb_emit_conv(p, s, t_string);
			lbValue len = lb_string_len(p, s);
			lbValue cmp = lb_emit_comp(p, be->op.kind, len, lb_const_int(p->module, t_int, 0));
			Type *type = default_type(tv.type);
			return lb_emit_conv(p, cmp, type);
		} else if (lb_is_empty_string_constant(be->left)) {
			// `"" == x` or `"" != x`
			lbValue s = lb_build_expr(p, be->right);
			s = lb_emit_conv(p, s, t_string);
			lbValue len = lb_string_len(p, s);
			lbValue cmp = lb_emit_comp(p, be->op.kind, len, lb_const_int(p->module, t_int, 0));
			Type *type = default_type(tv.type);
			return lb_emit_conv(p, cmp, type);
		}
		/*fallthrough*/
	case Token_Lt:
	case Token_LtEq:
	case Token_Gt:
	case Token_GtEq:
		{
			lbValue left = {};
			lbValue right = {};

			if (be->left->tav.mode == Addressing_Type) {
				left = lb_typeid(p->module, be->left->tav.type);
			}
			if (be->right->tav.mode == Addressing_Type) {
				right = lb_typeid(p->module, be->right->tav.type);
			}
			if (left.value == nullptr)  left  = lb_build_expr(p, be->left);
			if (right.value == nullptr) right = lb_build_expr(p, be->right);
			lbValue cmp = lb_emit_comp(p, be->op.kind, left, right);
			Type *type = default_type(tv.type);
			return lb_emit_conv(p, cmp, type);
		}

	case Token_CmpAnd:
	case Token_CmpOr:
		return lb_emit_logical_binary_expr(p, be->op.kind, be->left, be->right, tv.type);

	case Token_in:
	case Token_not_in:
		{
			lbValue left = lb_build_expr(p, be->left);
			lbValue right = lb_build_expr(p, be->right);
			Type *rt = base_type(right.type);
			if (is_type_pointer(rt)) {
				right = lb_emit_load(p, right);
				rt = base_type(type_deref(rt));
			}

			switch (rt->kind) {
			case Type_Map:
				{
					lbValue map_ptr = lb_address_from_load_or_generate_local(p, right);
					lbValue key = left;
					lbValue ptr = lb_internal_dynamic_map_get_ptr(p, map_ptr, key);
					if (be->op.kind == Token_in) {
						return lb_emit_conv(p, lb_emit_comp_against_nil(p, Token_NotEq, ptr), t_bool);
					} else {
						return lb_emit_conv(p, lb_emit_comp_against_nil(p, Token_CmpEq, ptr), t_bool);
					}
				}
				break;
			case Type_BitSet:
				{
					Type *key_type = rt->BitSet.elem;
					GB_ASSERT(are_types_identical(left.type, key_type));

					Type *it = bit_set_to_int(rt);
					left = lb_emit_conv(p, left, it);
					if (is_type_different_to_arch_endianness(it)) {
						left = lb_emit_byte_swap(p, left, integer_endian_type_to_platform_type(it));
					}

					lbValue lower = lb_const_value(p->module, left.type, exact_value_i64(rt->BitSet.lower));
					lbValue key = lb_emit_arith(p, Token_Sub, left, lower, left.type);
					lbValue bit = lb_emit_arith(p, Token_Shl, lb_const_int(p->module, left.type, 1), key, left.type);
					bit = lb_emit_conv(p, bit, it);

					lbValue old_value = lb_emit_transmute(p, right, it);
					lbValue new_value = lb_emit_arith(p, Token_And, old_value, bit, it);

					if (be->op.kind == Token_in) {
						return lb_emit_conv(p, lb_emit_comp(p, Token_NotEq, new_value, lb_const_int(p->module, new_value.type, 0)), t_bool);
					} else {
						return lb_emit_conv(p, lb_emit_comp(p, Token_CmpEq, new_value, lb_const_int(p->module, new_value.type, 0)), t_bool);
					}
				}
				break;
			default:
				GB_PANIC("Invalid 'in' type");
			}
			break;
		}
		break;
	default:
		GB_PANIC("Invalid binary expression");
		break;
	}
	return {};
}

gb_internal lbValue lb_emit_conv(lbProcedure *p, lbValue value, Type *t) {
	lbModule *m = p->module;
	t = reduce_tuple_to_single_type(t);

	Type *src_type = value.type;
	if (are_types_identical(t, src_type)) {
		return value;
	}

	Type *src = core_type(src_type);
	Type *dst = core_type(t);
	GB_ASSERT(src != nullptr);
	GB_ASSERT(dst != nullptr);

	if (is_type_untyped_uninit(src)) {
		return lb_const_undef(m, t);
	}
	if (is_type_untyped_nil(src)) {
		return lb_const_nil(m, t);
	}

	if (LLVMIsConstant(value.value)) {
		if (is_type_any(dst)) {
			Type *st = default_type(src_type);
			lbAddr default_value = lb_add_local_generated(p, st, false);
			lb_addr_store(p, default_value, value);
			lbValue data = lb_emit_conv(p, default_value.addr, t_rawptr);
			lbValue id = lb_typeid(m, st);

			lbAddr res = lb_add_local_generated(p, t, false);
			lbValue a0 = lb_emit_struct_ep(p, res.addr, 0);
			lbValue a1 = lb_emit_struct_ep(p, res.addr, 1);
			lb_emit_store(p, a0, data);
			lb_emit_store(p, a1, id);
			return lb_addr_load(p, res);
		} else if (dst->kind == Type_Basic) {
			if (src->Basic.kind == Basic_string && dst->Basic.kind == Basic_cstring) {
				String str = lb_get_const_string(m, value);
				lbValue res = {};
				res.type = t;
				res.value = llvm_cstring(m, str);
				return res;
			}
			// if (is_type_float(dst)) {
			// 	return value;
			// } else if (is_type_integer(dst)) {
			// 	return value;
			// }
			// ExactValue ev = value->Constant.value;
			// if (is_type_float(dst)) {
			// 	ev = exact_value_to_float(ev);
			// } else if (is_type_complex(dst)) {
			// 	ev = exact_value_to_complex(ev);
			// } else if (is_type_quaternion(dst)) {
			// 	ev = exact_value_to_quaternion(ev);
			// } else if (is_type_string(dst)) {
			// 	// Handled elsewhere
			// 	GB_ASSERT_MSG(ev.kind == ExactValue_String, "%d", ev.kind);
			// } else if (is_type_integer(dst)) {
			// 	ev = exact_value_to_integer(ev);
			// } else if (is_type_pointer(dst)) {
			// 	// IMPORTANT NOTE(bill): LLVM doesn't support pointer constants expect 'null'
			// 	lbValue i = lb_add_module_constant(p->module, t_uintptr, ev);
			// 	return lb_emit(p, lb_instr_conv(p, irConv_inttoptr, i, t_uintptr, dst));
			// }
			// return lb_const_value(p->module, t, ev);
		}
	}

	if (are_types_identical(src, dst)) {
		if (!are_types_identical(src_type, t)) {
			return lb_emit_transmute(p, value, t);
		}
		return value;
	}



	// bool <-> llvm bool
	if (is_type_boolean(src) && dst == t_llvm_bool) {
		lbValue res = {};
		res.value = LLVMBuildICmp(p->builder, LLVMIntNE, value.value, LLVMConstNull(lb_type(m, src)), "");
		res.type = t;
		return res;
	}
	if (src == t_llvm_bool && is_type_boolean(dst)) {
		lbValue res = {};
		res.value = LLVMBuildZExt(p->builder, value.value, lb_type(m, dst), "");
		res.type = t;
		return res;
	}


	// integer -> integer
	if (is_type_integer(src) && is_type_integer(dst)) {
		GB_ASSERT(src->kind == Type_Basic &&
		          dst->kind == Type_Basic);
		i64 sz = type_size_of(default_type(src));
		i64 dz = type_size_of(default_type(dst));


		if (sz == dz) {
			if (dz > 1 && !types_have_same_internal_endian(src, dst)) {
				return lb_emit_byte_swap(p, value, t);
			}
			lbValue res = {};
			res.value = value.value;
			res.type = t;
			return res;
		}

		if (sz > 1 && is_type_different_to_arch_endianness(src)) {
			Type *platform_src_type = integer_endian_type_to_platform_type(src);
			value = lb_emit_byte_swap(p, value, platform_src_type);
		}
		LLVMOpcode op = LLVMTrunc;

		if (dz < sz) {
			op = LLVMTrunc;
		} else if (dz == sz) {
			// NOTE(bill): In LLVM, all integers are signed and rely upon 2's compliment
			// NOTE(bill): Copy the value just for type correctness
			op = LLVMBitCast;
		} else if (dz > sz) {
			op = is_type_unsigned(src) ? LLVMZExt : LLVMSExt; // zero extent
		}

		if (dz > 1 && is_type_different_to_arch_endianness(dst)) {
			Type *platform_dst_type = integer_endian_type_to_platform_type(dst);
			lbValue res = {};
			res.value = LLVMBuildCast(p->builder, op, value.value, lb_type(m, platform_dst_type), "");
			res.type = t;
			return lb_emit_byte_swap(p, res, t);
		} else {
			lbValue res = {};
			res.value = LLVMBuildCast(p->builder, op, value.value, lb_type(m, t), "");
			res.type = t;
			return res;
		}
	}


	// boolean -> boolean/integer
	if (is_type_boolean(src) && (is_type_boolean(dst) || is_type_integer(dst))) {
		LLVMValueRef b = LLVMBuildICmp(p->builder, LLVMIntNE, value.value, LLVMConstNull(lb_type(m, value.type)), "");
		lbValue res = {};
		res.value = LLVMBuildIntCast2(p->builder, b, lb_type(m, t), false, "");
		res.type = t;
		return res;
	}

	if (is_type_cstring(src) && is_type_u8_ptr(dst)) {
		return lb_emit_transmute(p, value, dst);
	}
	if (is_type_u8_ptr(src) && is_type_cstring(dst)) {
		return lb_emit_transmute(p, value, dst);
	}
	if (is_type_cstring(src) && is_type_u8_multi_ptr(dst)) {
		return lb_emit_transmute(p, value, dst);
	}
	if (is_type_u8_multi_ptr(src) && is_type_cstring(dst)) {
		return lb_emit_transmute(p, value, dst);
	}
	if (is_type_cstring(src) && is_type_rawptr(dst)) {
		return lb_emit_transmute(p, value, dst);
	}
	if (is_type_rawptr(src) && is_type_cstring(dst)) {
		return lb_emit_transmute(p, value, dst);
	}

	if (are_types_identical(src, t_cstring) && are_types_identical(dst, t_string)) {
		TEMPORARY_ALLOCATOR_GUARD();

		lbValue c = lb_emit_conv(p, value, t_cstring);
		auto args = array_make<lbValue>(temporary_allocator(), 1);
		args[0] = c;
		lbValue s = lb_emit_runtime_call(p, "cstring_to_string", args);
		return lb_emit_conv(p, s, dst);
	}


	// integer -> boolean
	if (is_type_integer(src) && is_type_boolean(dst)) {
		lbValue res = {};
		res.value = LLVMBuildICmp(p->builder, LLVMIntNE, value.value, LLVMConstNull(lb_type(m, value.type)), "");
		res.type = t_llvm_bool;
		return lb_emit_conv(p, res, t);
	}

	// float -> float
	if (is_type_float(src) && is_type_float(dst)) {
		i64 sz = type_size_of(src);
		i64 dz = type_size_of(dst);


		if (dz == sz) {
			if (types_have_same_internal_endian(src, dst)) {
				lbValue res = {};
				res.type = t;
				res.value = value.value;
				return res;
			} else {
				return lb_emit_byte_swap(p, value, t);
			}
		}

		if (is_type_different_to_arch_endianness(src) || is_type_different_to_arch_endianness(dst)) {
			Type *platform_src_type = integer_endian_type_to_platform_type(src);
			Type *platform_dst_type = integer_endian_type_to_platform_type(dst);
			lbValue res = {};
			res = lb_emit_conv(p, value, platform_src_type);
			res = lb_emit_conv(p, res, platform_dst_type);
			if (is_type_different_to_arch_endianness(dst)) {
				res = lb_emit_byte_swap(p, res, t);
			}
			return lb_emit_conv(p, res, t);
		}


		lbValue res = {};
		res.type = t;

		if (dz >= sz) {
			res.value = LLVMBuildFPExt(p->builder, value.value, lb_type(m, t), "");
		} else {
			res.value = LLVMBuildFPTrunc(p->builder, value.value, lb_type(m, t), "");
		}
		return res;
	}


	if (is_type_complex(src) && is_type_complex(dst)) {
		Type *ft = base_complex_elem_type(dst);
		lbAddr gen = lb_add_local_generated(p, t, false);
		lbValue gp = lb_addr_get_ptr(p, gen);
		lbValue real = lb_emit_conv(p, lb_emit_struct_ev(p, value, 0), ft);
		lbValue imag = lb_emit_conv(p, lb_emit_struct_ev(p, value, 1), ft);
		lb_emit_store(p, lb_emit_struct_ep(p, gp, 0), real);
		lb_emit_store(p, lb_emit_struct_ep(p, gp, 1), imag);
		return lb_addr_load(p, gen);
	}

	if (is_type_quaternion(src) && is_type_quaternion(dst)) {
		// @QuaternionLayout
		Type *ft = base_complex_elem_type(dst);
		lbAddr gen = lb_add_local_generated(p, t, false);
		lbValue gp = lb_addr_get_ptr(p, gen);
		lbValue q0 = lb_emit_conv(p, lb_emit_struct_ev(p, value, 0), ft);
		lbValue q1 = lb_emit_conv(p, lb_emit_struct_ev(p, value, 1), ft);
		lbValue q2 = lb_emit_conv(p, lb_emit_struct_ev(p, value, 2), ft);
		lbValue q3 = lb_emit_conv(p, lb_emit_struct_ev(p, value, 3), ft);
		lb_emit_store(p, lb_emit_struct_ep(p, gp, 0), q0);
		lb_emit_store(p, lb_emit_struct_ep(p, gp, 1), q1);
		lb_emit_store(p, lb_emit_struct_ep(p, gp, 2), q2);
		lb_emit_store(p, lb_emit_struct_ep(p, gp, 3), q3);
		return lb_addr_load(p, gen);
	}

	if (is_type_integer(src) && is_type_complex(dst)) {
		Type *ft = base_complex_elem_type(dst);
		lbAddr gen = lb_add_local_generated(p, t, true);
		lbValue gp = lb_addr_get_ptr(p, gen);
		lbValue real = lb_emit_conv(p, value, ft);
		lb_emit_store(p, lb_emit_struct_ep(p, gp, 0), real);
		return lb_addr_load(p, gen);
	}
	if (is_type_float(src) && is_type_complex(dst)) {
		Type *ft = base_complex_elem_type(dst);
		lbAddr gen = lb_add_local_generated(p, t, true);
		lbValue gp = lb_addr_get_ptr(p, gen);
		lbValue real = lb_emit_conv(p, value, ft);
		lb_emit_store(p, lb_emit_struct_ep(p, gp, 0), real);
		return lb_addr_load(p, gen);
	}


	if (is_type_integer(src) && is_type_quaternion(dst)) {
		Type *ft = base_complex_elem_type(dst);
		lbAddr gen = lb_add_local_generated(p, t, true);
		lbValue gp = lb_addr_get_ptr(p, gen);
		lbValue real = lb_emit_conv(p, value, ft);
		// @QuaternionLayout
		lb_emit_store(p, lb_emit_struct_ep(p, gp, 3), real);
		return lb_addr_load(p, gen);
	}
	if (is_type_float(src) && is_type_quaternion(dst)) {
		Type *ft = base_complex_elem_type(dst);
		lbAddr gen = lb_add_local_generated(p, t, true);
		lbValue gp = lb_addr_get_ptr(p, gen);
		lbValue real = lb_emit_conv(p, value, ft);
		// @QuaternionLayout
		lb_emit_store(p, lb_emit_struct_ep(p, gp, 3), real);
		return lb_addr_load(p, gen);
	}
	if (is_type_complex(src) && is_type_quaternion(dst)) {
		Type *ft = base_complex_elem_type(dst);
		lbAddr gen = lb_add_local_generated(p, t, true);
		lbValue gp = lb_addr_get_ptr(p, gen);
		lbValue real = lb_emit_conv(p, lb_emit_struct_ev(p, value, 0), ft);
		lbValue imag = lb_emit_conv(p, lb_emit_struct_ev(p, value, 1), ft);
		// @QuaternionLayout
		lb_emit_store(p, lb_emit_struct_ep(p, gp, 3), real);
		lb_emit_store(p, lb_emit_struct_ep(p, gp, 0), imag);
		return lb_addr_load(p, gen);
	}

	// float <-> integer
	if (is_type_float(src) && is_type_integer(dst)) {
		if (is_type_different_to_arch_endianness(src) || is_type_different_to_arch_endianness(dst)) {
			Type *platform_src_type = integer_endian_type_to_platform_type(src);
			Type *platform_dst_type = integer_endian_type_to_platform_type(dst);
			lbValue res = {};
			res = lb_emit_conv(p, value, platform_src_type);
			res = lb_emit_conv(p, res, platform_dst_type);
			return lb_emit_conv(p, res, t);
		}

		if (is_type_integer_128bit(dst)) {
			TEMPORARY_ALLOCATOR_GUARD();

			auto args = array_make<lbValue>(temporary_allocator(), 1);
			args[0] = value;
			char const *call = "fixunsdfdi";
			if (is_type_unsigned(dst)) {
				call = "fixunsdfti";
			}
			lbValue res_i128 = lb_emit_runtime_call(p, call, args);
			return lb_emit_conv(p, res_i128, t);
		}

		lbValue res = {};
		res.type = t;
		if (is_type_unsigned(dst)) {
			res.value = LLVMBuildFPToUI(p->builder, value.value, lb_type(m, t), "");
		} else {
			res.value = LLVMBuildFPToSI(p->builder, value.value, lb_type(m, t), "");
		}
		return res;
	}
	if (is_type_integer(src) && is_type_float(dst)) {
		if (is_type_different_to_arch_endianness(src) || is_type_different_to_arch_endianness(dst)) {
			Type *platform_src_type = integer_endian_type_to_platform_type(src);
			Type *platform_dst_type = integer_endian_type_to_platform_type(dst);
			lbValue res = {};
			res = lb_emit_conv(p, value, platform_src_type);
			res = lb_emit_conv(p, res, platform_dst_type);
			if (is_type_different_to_arch_endianness(dst)) {
				res = lb_emit_byte_swap(p, res, t);
			}
			return lb_emit_conv(p, res, t);
		}

		if (is_type_integer_128bit(src)) {
			TEMPORARY_ALLOCATOR_GUARD();

			auto args = array_make<lbValue>(temporary_allocator(), 1);
			args[0] = value;
			char const *call = "floattidf";
			if (is_type_unsigned(src)) {
				call = "floattidf_unsigned";
			}
			lbValue res_f64 = lb_emit_runtime_call(p, call, args);
			return lb_emit_conv(p, res_f64, t);
		}

		lbValue res = {};
		res.type = t;
		if (is_type_unsigned(src)) {
			res.value = LLVMBuildUIToFP(p->builder, value.value, lb_type(m, t), "");
		} else {
			res.value = LLVMBuildSIToFP(p->builder, value.value, lb_type(m, t), "");
		}
		return res;
	}

	if (is_type_simd_vector(dst)) {
		Type *et = base_array_type(dst);
		if (is_type_simd_vector(src)) {
			Type *src_elem = core_array_type(src);
			Type *dst_elem = core_array_type(dst);

			GB_ASSERT(src->SimdVector.count == dst->SimdVector.count);

			lbValue res = {};
			res.type = t;
			if (are_types_identical(src_elem, dst_elem)) {
				res.value = value.value;
			} else if (is_type_float(src_elem) && is_type_integer(dst_elem)) {
				if (is_type_unsigned(dst_elem)) {
					res.value = LLVMBuildFPToUI(p->builder, value.value, lb_type(m, t), "");
				} else {
					res.value = LLVMBuildFPToSI(p->builder, value.value, lb_type(m, t), "");
				}
			} else if (is_type_integer(src_elem) && is_type_float(dst_elem)) {
				if (is_type_unsigned(src_elem)) {
					res.value = LLVMBuildUIToFP(p->builder, value.value, lb_type(m, t), "");
				} else {
					res.value = LLVMBuildSIToFP(p->builder, value.value, lb_type(m, t), "");
				}
			} else if ((is_type_integer(src_elem) || is_type_boolean(src_elem)) && is_type_integer(dst_elem)) {
				res.value = LLVMBuildIntCast2(p->builder, value.value, lb_type(m, t), !is_type_unsigned(src_elem), "");
			} else if (is_type_float(src_elem) && is_type_float(dst_elem)) {
				res.value = LLVMBuildFPCast(p->builder, value.value, lb_type(m, t), "");
			} else if (is_type_integer(src_elem) && is_type_boolean(dst_elem)) {
				LLVMValueRef i1vector = LLVMBuildICmp(p->builder, LLVMIntNE, value.value, LLVMConstNull(LLVMTypeOf(value.value)), "");
				res.value = LLVMBuildIntCast2(p->builder, i1vector, lb_type(m, t), !is_type_unsigned(src_elem), "");
			} else {
				GB_PANIC("Unhandled simd vector conversion: %s -> %s", type_to_string(src), type_to_string(dst));
			}
			return res;
		} else {
			i64 count = get_array_type_count(dst);
			LLVMTypeRef vt = lb_type(m, t);
			LLVMTypeRef llvm_u32 = lb_type(m, t_u32);
			LLVMValueRef elem = lb_emit_conv(p, value, et).value;
			LLVMValueRef vector = LLVMConstNull(vt);
			for (i64 i = 0; i < count; i++) {
				LLVMValueRef idx = LLVMConstInt(llvm_u32, i, false);
				vector = LLVMBuildInsertElement(p->builder, vector, elem, idx, "");
			}
			lbValue res = {};
			res.type = t;
			res.value = vector;
			return res;
		}
	}

	// bit_field <-> backing type
	if (is_type_bit_field(src)) {
		if (are_types_identical(src->BitField.backing_type, dst)) {
			lbValue res = {};
			res.type = t;
			res.value = value.value;
			return res;
		}
	}
	if (is_type_bit_field(dst)) {
		if (are_types_identical(src, dst->BitField.backing_type)) {
			lbValue res = {};
			res.type = t;
			res.value = value.value;
			return res;
		}
	}


	// Pointer <-> uintptr
	if (is_type_pointer(src) && is_type_uintptr(dst)) {
		lbValue res = {};
		res.type = t;
		res.value = LLVMBuildPtrToInt(p->builder, value.value, lb_type(m, t), "");
		return res;
	}
	if (is_type_uintptr(src) && is_type_pointer(dst)) {
		lbValue res = {};
		res.type = t;
		res.value = LLVMBuildIntToPtr(p->builder, value.value, lb_type(m, t), "");
		return res;
	}
	if (is_type_multi_pointer(src) && is_type_uintptr(dst)) {
		lbValue res = {};
		res.type = t;
		res.value = LLVMBuildPtrToInt(p->builder, value.value, lb_type(m, t), "");
		return res;
	}
	if (is_type_uintptr(src) && is_type_multi_pointer(dst)) {
		lbValue res = {};
		res.type = t;
		res.value = LLVMBuildIntToPtr(p->builder, value.value, lb_type(m, t), "");
		return res;
	}

	if (is_type_union(dst)) {
		for (Type *vt : dst->Union.variants) {
			if (are_types_identical(vt, src_type)) {
				lbAddr parent = lb_add_local_generated(p, t, true);
				lb_emit_store_union_variant(p, parent.addr, value, vt);
				return lb_addr_load(p, parent);
			}
		}
		if (dst->Union.variants.count == 1) {
			Type *vt = dst->Union.variants[0];
			if (internal_check_is_assignable_to(src_type, vt)) {
				value = lb_emit_conv(p, value, vt);
				lbAddr parent = lb_add_local_generated(p, t, true);
				lb_emit_store_union_variant(p, parent.addr, value, vt);
				return lb_addr_load(p, parent);
			}
		}
	}

	// NOTE(bill): This has to be done before 'Pointer <-> Pointer' as it's
	// subtype polymorphism casting
	if (check_is_assignable_to_using_subtype(src_type, t)) {
		Type *st = type_deref(src_type);
		st = type_deref(st);

		bool st_is_ptr = is_type_pointer(src_type);
		st = base_type(st);

		Type *dt = t;

		GB_ASSERT(is_type_struct(st) || is_type_raw_union(st));
		Selection sel = {};
		sel.index.allocator = heap_allocator();
		defer (array_free(&sel.index));
		if (lookup_subtype_polymorphic_selection(t, src_type, &sel)) {
			if (sel.entity == nullptr) {
				GB_PANIC("invalid subtype cast  %s -> ", type_to_string(src_type), type_to_string(t));
			}
			if (st_is_ptr) {
				lbValue res = lb_emit_deep_field_gep(p, value, sel);
				Type *rt = res.type;
				if (!are_types_identical(rt, dt) && are_types_identical(type_deref(rt), dt)) {
					res = lb_emit_load(p, res);
				}
				return res;
			} else {
				if (is_type_pointer(value.type)) {
					Type *rt = value.type;
					if (!are_types_identical(rt, dt) && are_types_identical(type_deref(rt), dt)) {
						value = lb_emit_load(p, value);
					} else {
						value = lb_emit_deep_field_gep(p, value, sel);
						return lb_emit_load(p, value);
					}
				}

				return lb_emit_deep_field_ev(p, value, sel);

			}
		}
	}



	// Pointer <-> Pointer
	if (is_type_pointer(src) && is_type_pointer(dst)) {
		lbValue res = {};
		res.type = t;
		res.value = LLVMBuildPointerCast(p->builder, value.value, lb_type(m, t), "");
		return res;
	}
	if (is_type_multi_pointer(src) && is_type_pointer(dst)) {
		lbValue res = {};
		res.type = t;
		res.value = LLVMBuildPointerCast(p->builder, value.value, lb_type(m, t), "");
		return res;
	}
	if (is_type_pointer(src) && is_type_multi_pointer(dst)) {
		lbValue res = {};
		res.type = t;
		res.value = LLVMBuildPointerCast(p->builder, value.value, lb_type(m, t), "");
		return res;
	}
	if (is_type_multi_pointer(src) && is_type_multi_pointer(dst)) {
		lbValue res = {};
		res.type = t;
		res.value = LLVMBuildPointerCast(p->builder, value.value, lb_type(m, t), "");
		return res;
	}




	// proc <-> proc
	if (is_type_proc(src) && is_type_proc(dst)) {
		lbValue res = {};
		res.type = t;
		res.value = LLVMBuildPointerCast(p->builder, value.value, lb_type(m, t), "");
		return res;
	}

	// pointer -> proc
	if (is_type_pointer(src) && is_type_proc(dst)) {
		lbValue res = {};
		res.type = t;
		res.value = LLVMBuildPointerCast(p->builder, value.value, lb_type(m, t), "");
		return res;
	}
	// proc -> pointer
	if (is_type_proc(src) && is_type_pointer(dst)) {
		lbValue res = {};
		res.type = t;
		res.value = LLVMBuildPointerCast(p->builder, value.value, lb_type(m, t), "");
		return res;
	}

	// []byte/[]u8 <-> string
	if (is_type_u8_slice(src) && is_type_string(dst)) {
		return lb_emit_transmute(p, value, t);
	}
	if (is_type_string(src) && is_type_u8_slice(dst)) {
		return lb_emit_transmute(p, value, t);
	}

	if (is_type_array_like(dst)) {
		Type *elem = base_array_type(dst);
		lbValue e = lb_emit_conv(p, value, elem);
		// NOTE(bill): Doesn't need to be zero because it will be initialized in the loops
		lbAddr v = lb_add_local_generated(p, t, false);
		isize index_count = cast(isize)get_array_type_count(dst);

		for (isize i = 0; i < index_count; i++) {
			lbValue elem = lb_emit_array_epi(p, v.addr, i);
			lb_emit_store(p, elem, e);
		}
		return lb_addr_load(p, v);
	}

	if (is_type_matrix(dst) && !is_type_matrix(src)) {
		GB_ASSERT_MSG(dst->Matrix.row_count == dst->Matrix.column_count, "%s <- %s", type_to_string(dst), type_to_string(src));

		Type *elem = base_array_type(dst);
		lbValue e = lb_emit_conv(p, value, elem);
		lbAddr v = lb_add_local_generated(p, t, false);
		lbValue zero = lb_const_value(p->module, elem, exact_value_i64(0), true);
		for (i64 j = 0; j < dst->Matrix.column_count; j++) {
			for (i64 i = 0; i < dst->Matrix.row_count; i++) {
				lbValue ptr = lb_emit_matrix_epi(p, v.addr, i, j);
				lb_emit_store(p, ptr, i == j ? e : zero);
			}
		}


		return lb_addr_load(p, v);
	}

	if (is_type_matrix(dst) && is_type_matrix(src)) {
		GB_ASSERT(dst->kind == Type_Matrix);
		GB_ASSERT(src->kind == Type_Matrix);
		lbAddr v = lb_add_local_generated(p, t, true);

		if (is_matrix_square(dst) && is_matrix_square(dst)) {
			for (i64 j = 0; j < dst->Matrix.column_count; j++) {
				for (i64 i = 0; i < dst->Matrix.row_count; i++) {
					if (i < src->Matrix.row_count && j < src->Matrix.column_count) {
						lbValue d = lb_emit_matrix_epi(p, v.addr, i, j);
						lbValue s = lb_emit_matrix_ev(p, value, i, j);
						lb_emit_store(p, d, s);
					} else if (i == j) {
						lbValue d = lb_emit_matrix_epi(p, v.addr, i, j);
						lbValue s = lb_const_value(p->module, dst->Matrix.elem, exact_value_i64(1), true);
						lb_emit_store(p, d, s);
					}
				}
			}
		} else {
			i64 dst_count = dst->Matrix.row_count*dst->Matrix.column_count;
			i64 src_count = src->Matrix.row_count*src->Matrix.column_count;
			GB_ASSERT(dst_count == src_count);

			lbValue pdst = v.addr;
			lbValue psrc = lb_address_from_load_or_generate_local(p, value);

			bool same_elem_base_types = are_types_identical(
				base_type(dst->Matrix.elem),
				base_type(src->Matrix.elem)
			);

			if (same_elem_base_types && type_size_of(dst) == type_size_of(src)) {
				lb_mem_copy_overlapping(p, v.addr, psrc, lb_const_int(p->module, t_int, type_size_of(dst)));
			} else {
				for (i64 i = 0; i < src_count; i++) {
					lbValue dp = lb_emit_array_epi(p, v.addr, matrix_column_major_index_to_offset(dst, i));
					lbValue sp = lb_emit_array_epi(p, psrc,   matrix_column_major_index_to_offset(src, i));
					lbValue s = lb_emit_load(p, sp);
					s = lb_emit_conv(p, s, dst->Matrix.elem);
					lb_emit_store(p, dp, s);
				}
			}
		}
		return lb_addr_load(p, v);
	}



	if (is_type_any(dst)) {
		if (is_type_untyped_uninit(src)) {
			return lb_const_undef(p->module, t);
		}
		if (is_type_untyped_nil(src)) {
			return lb_const_nil(p->module, t);
		}

		lbAddr result = lb_add_local_generated(p, t, true);

		Type *st = default_type(src_type);

		lbValue data = lb_address_from_load_or_generate_local(p, value);
		GB_ASSERT_MSG(is_type_pointer(data.type), "%s", type_to_string(data.type));
		GB_ASSERT_MSG(is_type_typed(st), "%s", type_to_string(st));
		data = lb_emit_conv(p, data, t_rawptr);

		lbValue id = lb_typeid(p->module, st);
		lbValue any_data = lb_emit_struct_ep(p, result.addr, 0);
		lbValue any_id   = lb_emit_struct_ep(p, result.addr, 1);

		lb_emit_store(p, any_data, data);
		lb_emit_store(p, any_id,   id);

		return lb_addr_load(p, result);
	}


	i64 src_sz = type_size_of(src);
	i64 dst_sz = type_size_of(dst);

	if (src_sz == dst_sz) {
		// bit_set <-> integer
		if (is_type_integer(src) && is_type_bit_set(dst)) {
			lbValue res = lb_emit_conv(p, value, bit_set_to_int(dst));
			res.type = t;
			return res;
		}
		if (is_type_bit_set(src) && is_type_integer(dst)) {
			lbValue bs = value;
			bs.type = bit_set_to_int(src);
			return lb_emit_conv(p, bs, dst);
		}

		// typeid <-> integer
		if (is_type_integer(src) && is_type_typeid(dst)) {
			return lb_emit_transmute(p, value, dst);
		}
		if (is_type_typeid(src) && is_type_integer(dst)) {
			return lb_emit_transmute(p, value, dst);
		}
	}



	if (is_type_untyped(src)) {
		if (is_type_string(src) && is_type_string(dst)) {
			lbAddr result = lb_add_local_generated(p, t, false);
			lb_addr_store(p, result, value);
			return lb_addr_load(p, result);
		}
	}

	gb_printf_err("%.*s\n", LIT(p->name));
	gb_printf_err("lb_emit_conv: src -> dst\n");
	gb_printf_err("Not Identical %s != %s\n", type_to_string(src_type), type_to_string(t));
	gb_printf_err("Not Identical %s != %s\n", type_to_string(src), type_to_string(dst));
	gb_printf_err("Not Identical %p != %p\n", src_type, t);
	gb_printf_err("Not Identical %p != %p\n", src, dst);


	GB_PANIC("Invalid type conversion: '%s' to '%s' for procedure '%.*s'",
	         type_to_string(src_type), type_to_string(t),
	         LIT(p->name));

	return {};
}

gb_internal lbValue lb_compare_records(lbProcedure *p, TokenKind op_kind, lbValue left, lbValue right, Type *type) {
	GB_ASSERT((is_type_struct(type) || is_type_union(type)) && is_type_comparable(type));
	lbValue left_ptr  = lb_address_from_load_or_generate_local(p, left);
	lbValue right_ptr = lb_address_from_load_or_generate_local(p, right);
	lbValue res = {};
	if (type_size_of(type) == 0) {
		switch (op_kind) {
		case Token_CmpEq:
			return lb_const_bool(p->module, t_bool, true);
		case Token_NotEq:
			return lb_const_bool(p->module, t_bool, false);
		}
		GB_PANIC("invalid operator");
	}
	TEMPORARY_ALLOCATOR_GUARD();
	if (is_type_simple_compare(type)) {
		// TODO(bill): Test to see if this is actually faster!!!!
		auto args = array_make<lbValue>(temporary_allocator(), 3);
		args[0] = lb_emit_conv(p, left_ptr, t_rawptr);
		args[1] = lb_emit_conv(p, right_ptr, t_rawptr);
		args[2] = lb_const_int(p->module, t_int, type_size_of(type));
		res = lb_emit_runtime_call(p, "memory_equal", args);
	} else {
		lbValue value = lb_equal_proc_for_type(p->module, type);
		auto args = array_make<lbValue>(temporary_allocator(), 2);
		args[0] = lb_emit_conv(p, left_ptr, t_rawptr);
		args[1] = lb_emit_conv(p, right_ptr, t_rawptr);
		res = lb_emit_call(p, value, args);
	}
	if (op_kind == Token_NotEq) {
		res = lb_emit_unary_arith(p, Token_Not, res, res.type);
	}
	return res;
}



gb_internal lbValue lb_emit_comp(lbProcedure *p, TokenKind op_kind, lbValue left, lbValue right) {
	Type *a = core_type(left.type);
	Type *b = core_type(right.type);

	GB_ASSERT(gb_is_between(op_kind, Token__ComparisonBegin+1, Token__ComparisonEnd-1));

	lbValue nil_check = {};

	if (is_type_array_like(left.type) || is_type_array_like(right.type)) {
		// don't do `nil` check if it is array-like
	} else if (is_type_untyped_nil(left.type)) {
		nil_check = lb_emit_comp_against_nil(p, op_kind, right);
	} else if (is_type_untyped_nil(right.type)) {
		nil_check = lb_emit_comp_against_nil(p, op_kind, left);
	}
	if (nil_check.value != nullptr) {
		return nil_check;
	}

	if (are_types_identical(a, b)) {
		// NOTE(bill): No need for a conversion
	} else if (lb_is_const(left) || lb_is_const_nil(left)) {
		left = lb_emit_conv(p, left, right.type);
	} else if (lb_is_const(right) || lb_is_const_nil(right)) {
		right = lb_emit_conv(p, right, left.type);
	} else {
		Type *lt = left.type;
		Type *rt = right.type;

		lt = left.type;
		rt = right.type;
		i64 ls = type_size_of(lt);
		i64 rs = type_size_of(rt);

		// NOTE(bill): Quick heuristic, larger types are usually the target type
		if (ls < rs) {
			left = lb_emit_conv(p, left, rt);
		} else if (ls > rs) {
			right = lb_emit_conv(p, right, lt);
		} else {
			if (is_type_union(rt)) {
				left = lb_emit_conv(p, left, rt);
			} else {
				right = lb_emit_conv(p, right, lt);
			}
		}
	}

	a = core_type(left.type);
	b = core_type(right.type);

	if (is_type_matrix(a) && (op_kind == Token_CmpEq || op_kind == Token_NotEq)) {
		Type *tl = base_type(a);
		lbValue lhs = lb_address_from_load_or_generate_local(p, left);
		lbValue rhs = lb_address_from_load_or_generate_local(p, right);


		// TODO(bill): Test to see if this is actually faster!!!!
		auto args = array_make<lbValue>(permanent_allocator(), 3);
		args[0] = lb_emit_conv(p, lhs, t_rawptr);
		args[1] = lb_emit_conv(p, rhs, t_rawptr);
		args[2] = lb_const_int(p->module, t_int, type_size_of(tl));
		lbValue val = lb_emit_runtime_call(p, "memory_compare", args);
		lbValue res = lb_emit_comp(p, op_kind, val, lb_const_nil(p->module, val.type));
		return lb_emit_conv(p, res, t_bool);
	}
	if (is_type_array_like(a)) {
		Type *tl = base_type(a);
		lbValue lhs = lb_address_from_load_or_generate_local(p, left);
		lbValue rhs = lb_address_from_load_or_generate_local(p, right);


		TokenKind cmp_op = Token_And;
		lbValue res = lb_const_bool(p->module, t_llvm_bool, true);
		if (op_kind == Token_NotEq) {
			res = lb_const_bool(p->module, t_llvm_bool, false);
			cmp_op = Token_Or;
		} else if (op_kind == Token_CmpEq) {
			res = lb_const_bool(p->module, t_llvm_bool, true);
			cmp_op = Token_And;
		}

		bool inline_array_arith = lb_can_try_to_inline_array_arith(tl);
		i32 count = 0;
		switch (tl->kind) {
		case Type_Array:           count = cast(i32)tl->Array.count;           break;
		case Type_EnumeratedArray: count = cast(i32)tl->EnumeratedArray.count; break;
		}

		if (inline_array_arith) {
			// inline
			lbAddr val = lb_add_local_generated(p, t_bool, false);
			lb_addr_store(p, val, res);
			for (i32 i = 0; i < count; i++) {
				lbValue x = lb_emit_load(p, lb_emit_array_epi(p, lhs, i));
				lbValue y = lb_emit_load(p, lb_emit_array_epi(p, rhs, i));
				lbValue cmp = lb_emit_comp(p, op_kind, x, y);
				lbValue new_res = lb_emit_arith(p, cmp_op, lb_addr_load(p, val), cmp, t_bool);
				lb_addr_store(p, val, lb_emit_conv(p, new_res, t_bool));
			}

			return lb_addr_load(p, val);
		} else {
			if (is_type_simple_compare(tl) && (op_kind == Token_CmpEq || op_kind == Token_NotEq)) {
				// TODO(bill): Test to see if this is actually faster!!!!
				auto args = array_make<lbValue>(permanent_allocator(), 3);
				args[0] = lb_emit_conv(p, lhs, t_rawptr);
				args[1] = lb_emit_conv(p, rhs, t_rawptr);
				args[2] = lb_const_int(p->module, t_int, type_size_of(tl));
				lbValue val = lb_emit_runtime_call(p, "memory_compare", args);
				lbValue res = lb_emit_comp(p, op_kind, val, lb_const_nil(p->module, val.type));
				return lb_emit_conv(p, res, t_bool);
			} else {
				lbAddr val = lb_add_local_generated(p, t_bool, false);
				lb_addr_store(p, val, res);
				auto loop_data = lb_loop_start(p, count, t_i32);
				{
					lbValue i = loop_data.idx;
					lbValue x = lb_emit_load(p, lb_emit_array_ep(p, lhs, i));
					lbValue y = lb_emit_load(p, lb_emit_array_ep(p, rhs, i));
					lbValue cmp = lb_emit_comp(p, op_kind, x, y);
					lbValue new_res = lb_emit_arith(p, cmp_op, lb_addr_load(p, val), cmp, t_bool);
					lb_addr_store(p, val, lb_emit_conv(p, new_res, t_bool));
				}
				lb_loop_end(p, loop_data);

				return lb_addr_load(p, val);
			}
		}
	}


	if ((is_type_struct(a) || is_type_union(a)) && is_type_comparable(a)) {
		return lb_compare_records(p, op_kind, left, right, a);
	}

	if ((is_type_struct(b) || is_type_union(b)) && is_type_comparable(b)) {
		return lb_compare_records(p, op_kind, left, right, b);
	}

	if (is_type_string(a)) {
		if (is_type_cstring(a) && is_type_cstring(b)) {
			left  = lb_emit_conv(p, left, t_cstring);
			right = lb_emit_conv(p, right, t_cstring);
			char const *runtime_procedure = nullptr;
			switch (op_kind) {
			case Token_CmpEq: runtime_procedure = "cstring_eq"; break;
			case Token_NotEq: runtime_procedure = "cstring_ne"; break;
			case Token_Lt:    runtime_procedure = "cstring_lt"; break;
			case Token_Gt:    runtime_procedure = "cstring_gt"; break;
			case Token_LtEq:  runtime_procedure = "cstring_le"; break;
			case Token_GtEq:  runtime_procedure = "cstring_gt"; break;
			}
			GB_ASSERT(runtime_procedure != nullptr);

			auto args = array_make<lbValue>(permanent_allocator(), 2);
			args[0] = left;
			args[1] = right;
			return lb_emit_runtime_call(p, runtime_procedure, args);
		}


		if (is_type_cstring(a) ^ is_type_cstring(b)) {
			left  = lb_emit_conv(p, left, t_string);
			right = lb_emit_conv(p, right, t_string);
		}

		char const *runtime_procedure = nullptr;
		switch (op_kind) {
		case Token_CmpEq: runtime_procedure = "string_eq"; break;
		case Token_NotEq: runtime_procedure = "string_ne"; break;
		case Token_Lt:    runtime_procedure = "string_lt"; break;
		case Token_Gt:    runtime_procedure = "string_gt"; break;
		case Token_LtEq:  runtime_procedure = "string_le"; break;
		case Token_GtEq:  runtime_procedure = "string_gt"; break;
		}
		GB_ASSERT(runtime_procedure != nullptr);

		auto args = array_make<lbValue>(permanent_allocator(), 2);
		args[0] = left;
		args[1] = right;
		return lb_emit_runtime_call(p, runtime_procedure, args);
	}

	if (is_type_complex(a)) {
		char const *runtime_procedure = "";
		i64 sz = 8*type_size_of(a);
		switch (sz) {
		case 32:
			switch (op_kind) {
			case Token_CmpEq: runtime_procedure = "complex32_eq"; break;
			case Token_NotEq: runtime_procedure = "complex32_ne"; break;
			}
			break;
		case 64:
			switch (op_kind) {
			case Token_CmpEq: runtime_procedure = "complex64_eq"; break;
			case Token_NotEq: runtime_procedure = "complex64_ne"; break;
			}
			break;
		case 128:
			switch (op_kind) {
			case Token_CmpEq: runtime_procedure = "complex128_eq"; break;
			case Token_NotEq: runtime_procedure = "complex128_ne"; break;
			}
			break;
		}
		GB_ASSERT(runtime_procedure != nullptr);

		auto args = array_make<lbValue>(permanent_allocator(), 2);
		args[0] = left;
		args[1] = right;
		return lb_emit_runtime_call(p, runtime_procedure, args);
	}

	if (is_type_quaternion(a)) {
		char const *runtime_procedure = "";
		i64 sz = 8*type_size_of(a);
		switch (sz) {
		case 64:
			switch (op_kind) {
			case Token_CmpEq: runtime_procedure = "quaternion64_eq"; break;
			case Token_NotEq: runtime_procedure = "quaternion64_ne"; break;
			}
			break;
		case 128:
			switch (op_kind) {
			case Token_CmpEq: runtime_procedure = "quaternion128_eq"; break;
			case Token_NotEq: runtime_procedure = "quaternion128_ne"; break;
			}
			break;
		case 256:
			switch (op_kind) {
			case Token_CmpEq: runtime_procedure = "quaternion256_eq"; break;
			case Token_NotEq: runtime_procedure = "quaternion256_ne"; break;
			}
			break;
		}
		GB_ASSERT(runtime_procedure != nullptr);

		auto args = array_make<lbValue>(permanent_allocator(), 2);
		args[0] = left;
		args[1] = right;
		return lb_emit_runtime_call(p, runtime_procedure, args);
	}

	if (is_type_bit_set(a)) {
		switch (op_kind) {
		case Token_Lt:
		case Token_LtEq:
		case Token_Gt:
		case Token_GtEq:
			{
				Type *it = bit_set_to_int(a);
				lbValue lhs = lb_emit_transmute(p, left, it);
				lbValue rhs = lb_emit_transmute(p, right, it);
				lbValue res = lb_emit_arith(p, Token_And, lhs, rhs, it);

				if (op_kind == Token_Lt || op_kind == Token_LtEq) {
					// (lhs & rhs) == lhs
					res.value = LLVMBuildICmp(p->builder, LLVMIntEQ, res.value, lhs.value, "");
					res.type = t_llvm_bool;
				} else if (op_kind == Token_Gt || op_kind == Token_GtEq) {
					// (lhs & rhs) == rhs
					res.value = LLVMBuildICmp(p->builder, LLVMIntEQ, res.value, rhs.value, "");
					res.type = t_llvm_bool;
				}

				// NOTE(bill): Strict subsets
				if (op_kind == Token_Lt || op_kind == Token_Gt) {
					// res &~ (lhs == rhs)
					lbValue eq = {};
					eq.value = LLVMBuildICmp(p->builder, LLVMIntEQ, lhs.value, rhs.value, "");
					eq.type = t_llvm_bool;
					res = lb_emit_arith(p, Token_AndNot, res, eq, t_llvm_bool);
				}

				return res;
			}

		case Token_CmpEq:
		case Token_NotEq:
			{
				LLVMIntPredicate pred = {};
				switch (op_kind) {
				case Token_CmpEq: pred = LLVMIntEQ;  break;
				case Token_NotEq: pred = LLVMIntNE;  break;
				}
				lbValue res = {};
				res.type = t_llvm_bool;
				res.value = LLVMBuildICmp(p->builder, pred, left.value, right.value, "");
				return res;
			}
		}
	}

	if (op_kind != Token_CmpEq && op_kind != Token_NotEq) {
		Type *t = left.type;
		if (is_type_integer(t) && is_type_different_to_arch_endianness(t)) {
			Type *platform_type = integer_endian_type_to_platform_type(t);
			lbValue x = lb_emit_byte_swap(p, left, platform_type);
			lbValue y = lb_emit_byte_swap(p, right, platform_type);
			left = x;
			right = y;
		} else if (is_type_float(t) && is_type_different_to_arch_endianness(t)) {
			Type *platform_type = integer_endian_type_to_platform_type(t);
			lbValue x = lb_emit_conv(p, left, platform_type);
			lbValue y = lb_emit_conv(p, right, platform_type);
			left = x;
			right = y;
		}
	}

	a = core_type(left.type);
	b = core_type(right.type);


	lbValue res = {};
	res.type = t_llvm_bool;
	if (is_type_integer(a) ||
	    is_type_boolean(a) ||
	    is_type_pointer(a) ||
	    is_type_multi_pointer(a) ||
	    is_type_proc(a) ||
	    is_type_enum(a)) {
		LLVMIntPredicate pred = {};
		if (is_type_unsigned(left.type)) {
			switch (op_kind) {
			case Token_Gt:   pred = LLVMIntUGT; break;
			case Token_GtEq: pred = LLVMIntUGE; break;
			case Token_Lt:   pred = LLVMIntULT; break;
			case Token_LtEq: pred = LLVMIntULE; break;
			}
		} else {
			switch (op_kind) {
			case Token_Gt:   pred = LLVMIntSGT; break;
			case Token_GtEq: pred = LLVMIntSGE; break;
			case Token_Lt:   pred = LLVMIntSLT; break;
			case Token_LtEq: pred = LLVMIntSLE; break;
			}
		}
		switch (op_kind) {
		case Token_CmpEq: pred = LLVMIntEQ;  break;
		case Token_NotEq: pred = LLVMIntNE;  break;
		}
		LLVMValueRef lhs = left.value;
		LLVMValueRef rhs = right.value;
		if (LLVMTypeOf(lhs) != LLVMTypeOf(rhs)) {
			if (lb_is_type_kind(LLVMTypeOf(lhs), LLVMPointerTypeKind)) {
				rhs = LLVMBuildPointerCast(p->builder, rhs, LLVMTypeOf(lhs), "");
			}
		}

		res.value = LLVMBuildICmp(p->builder, pred, lhs, rhs, "");
	} else if (is_type_float(a)) {
		LLVMRealPredicate pred = {};
		switch (op_kind) {
		case Token_CmpEq: pred = LLVMRealOEQ; break;
		case Token_Gt:    pred = LLVMRealOGT; break;
		case Token_GtEq:  pred = LLVMRealOGE; break;
		case Token_Lt:    pred = LLVMRealOLT; break;
		case Token_LtEq:  pred = LLVMRealOLE; break;
		case Token_NotEq: pred = LLVMRealONE; break;
		}
		res.value = LLVMBuildFCmp(p->builder, pred, left.value, right.value, "");
	} else if (is_type_typeid(a)) {
		LLVMIntPredicate pred = {};
		switch (op_kind) {
		case Token_Gt:   pred = LLVMIntUGT; break;
		case Token_GtEq: pred = LLVMIntUGE; break;
		case Token_Lt:   pred = LLVMIntULT; break;
		case Token_LtEq: pred = LLVMIntULE; break;
		case Token_CmpEq: pred = LLVMIntEQ;  break;
		case Token_NotEq: pred = LLVMIntNE;  break;
		}
		res.value = LLVMBuildICmp(p->builder, pred, left.value, right.value, "");
	} else if (is_type_simd_vector(a)) {
		LLVMValueRef mask = nullptr;
		Type *elem = base_array_type(a);
		if (is_type_float(elem)) {
			LLVMRealPredicate pred = {};
			switch (op_kind) {
			case Token_CmpEq: pred = LLVMRealOEQ; break;
			case Token_NotEq: pred = LLVMRealONE; break;
			}
			mask = LLVMBuildFCmp(p->builder, pred, left.value, right.value, "");
		} else {
			LLVMIntPredicate pred = {};
			switch (op_kind) {
			case Token_CmpEq: pred = LLVMIntEQ; break;
			case Token_NotEq: pred = LLVMIntNE; break;
			}
			mask = LLVMBuildICmp(p->builder, pred, left.value, right.value, "");
		}
		GB_ASSERT_MSG(mask != nullptr, "Unhandled comparison kind %s (%s) %.*s %s (%s)", type_to_string(left.type), type_to_string(base_type(left.type)), LIT(token_strings[op_kind]), type_to_string(right.type), type_to_string(base_type(right.type)));

		/* NOTE(bill, 2022-05-28):
			Thanks to Per Vognsen, sign extending <N x i1> to
			a vector of the same width as the input vector, bit casting to an integer,
			and then comparing against zero is the better option
			See: https://lists.llvm.org/pipermail/llvm-dev/2012-September/053046.html

			// Example assuming 128-bit vector

			%1 = <4 x float> ...
			%2 = <4 x float> ...
			%3 = fcmp oeq <4 x float> %1, %2
			%4 = sext <4 x i1> %3 to <4 x i32>
			%5 = bitcast <4 x i32> %4 to i128
			%6 = icmp ne i128 %5, 0
			br i1 %6, label %true1, label %false2

			This will result in 1 cmpps + 1 ptest + 1 br
			(even without SSE4.1, contrary to what the mail list states, because of pmovmskb)

		*/

		unsigned count = cast(unsigned)get_array_type_count(a);
		unsigned elem_sz = cast(unsigned)(type_size_of(elem)*8);
		LLVMTypeRef mask_type = LLVMVectorType(LLVMIntTypeInContext(p->module->ctx, elem_sz), count);
		mask = LLVMBuildSExtOrBitCast(p->builder, mask, mask_type, "");

		LLVMTypeRef mask_int_type = LLVMIntTypeInContext(p->module->ctx, cast(unsigned)(8*type_size_of(a)));
		LLVMValueRef mask_int = LLVMBuildBitCast(p->builder, mask, mask_int_type, "");
		res.value = LLVMBuildICmp(p->builder, LLVMIntNE, mask_int, LLVMConstNull(LLVMTypeOf(mask_int)), "");
		return res;

	} else {
		GB_PANIC("Unhandled comparison kind %s (%s) %.*s %s (%s)", type_to_string(left.type), type_to_string(base_type(left.type)), LIT(token_strings[op_kind]), type_to_string(right.type), type_to_string(base_type(right.type)));
	}

	return res;
}



gb_internal lbValue lb_emit_comp_against_nil(lbProcedure *p, TokenKind op_kind, lbValue x) {
	lbValue res = {};
	res.type = t_llvm_bool;
	Type *t = x.type;
	Type *bt = base_type(t);
	TypeKind type_kind = bt->kind;

	switch (type_kind) {
	case Type_Basic:
		switch (bt->Basic.kind) {
		case Basic_rawptr:
		case Basic_cstring:
			if (op_kind == Token_CmpEq) {
				res.value = LLVMBuildIsNull(p->builder, x.value, "");
			} else if (op_kind == Token_NotEq) {
				res.value = LLVMBuildIsNotNull(p->builder, x.value, "");
			}
			return res;
		case Basic_any:
			{
				// TODO(bill): is this correct behaviour for nil comparison for any?
				lbValue data = lb_emit_struct_ev(p, x, 0);
				lbValue ti   = lb_emit_struct_ev(p, x, 1);
				if (op_kind == Token_CmpEq) {
					LLVMValueRef a =  LLVMBuildIsNull(p->builder, data.value, "");
					LLVMValueRef b =  LLVMBuildIsNull(p->builder, ti.value, "");
					res.value = LLVMBuildOr(p->builder, a, b, "");
					return res;
				} else if (op_kind == Token_NotEq) {
					LLVMValueRef a =  LLVMBuildIsNotNull(p->builder, data.value, "");
					LLVMValueRef b =  LLVMBuildIsNotNull(p->builder, ti.value, "");
					res.value = LLVMBuildAnd(p->builder, a, b, "");
					return res;
				}
			}
			break;
		case Basic_typeid:
			lbValue invalid_typeid = lb_const_value(p->module, t_typeid, exact_value_i64(0));
			return lb_emit_comp(p, op_kind, x, invalid_typeid);
		}
		break;

	case Type_Enum:
	case Type_Pointer:
	case Type_MultiPointer:
	case Type_Proc:
	case Type_BitSet:
		if (op_kind == Token_CmpEq) {
			res.value = LLVMBuildIsNull(p->builder, x.value, "");
		} else if (op_kind == Token_NotEq) {
			res.value = LLVMBuildIsNotNull(p->builder, x.value, "");
		}
		return res;

	case Type_Slice:
		{
			lbValue data = lb_emit_struct_ev(p, x, 0);
			if (op_kind == Token_CmpEq) {
				res.value = LLVMBuildIsNull(p->builder, data.value, "");
				return res;
			} else if (op_kind == Token_NotEq) {
				res.value = LLVMBuildIsNotNull(p->builder, data.value, "");
				return res;
			}
		}
		break;

	case Type_DynamicArray:
		{
			lbValue data = lb_emit_struct_ev(p, x, 0);
			if (op_kind == Token_CmpEq) {
				res.value = LLVMBuildIsNull(p->builder, data.value, "");
				return res;
			} else if (op_kind == Token_NotEq) {
				res.value = LLVMBuildIsNotNull(p->builder, data.value, "");
				return res;
			}
		}
		break;

	case Type_Map:
		{
			lbValue data_ptr = lb_emit_struct_ev(p, x, 0);

			if (op_kind == Token_CmpEq) {
				res.value = LLVMBuildIsNull(p->builder, data_ptr.value, "");
				return res;
			} else {
				res.value = LLVMBuildIsNotNull(p->builder, data_ptr.value, "");
				return res;
			}
		}
		break;

	case Type_Union:
		{
			if (type_size_of(t) == 0) {
				if (op_kind == Token_CmpEq) {
					return lb_const_bool(p->module, t_llvm_bool, true);
				} else if (op_kind == Token_NotEq) {
					return lb_const_bool(p->module, t_llvm_bool, false);
				}
			} else if (is_type_union_maybe_pointer(t)) {
				lbValue tag = lb_emit_transmute(p, x, t_rawptr);
				return lb_emit_comp_against_nil(p, op_kind, tag);
			} else {
				lbValue tag = lb_emit_union_tag_value(p, x);
				return lb_emit_comp(p, op_kind, tag, lb_zero(p->module, tag.type));
			}
		}
	case Type_Struct:
		if (is_type_soa_struct(t)) {
			Type *bt = base_type(t);
			if (bt->Struct.soa_kind == StructSoa_Slice) {
				LLVMValueRef the_value = {};
				if (bt->Struct.fields.count == 0) {
					lbValue len = lb_soa_struct_len(p, x);
					the_value = len.value;
				} else {
					lbValue first_field = lb_emit_struct_ev(p, x, 0);
					the_value = first_field.value;
				}
				if (op_kind == Token_CmpEq) {
					res.value = LLVMBuildIsNull(p->builder, the_value, "");
					return res;
				} else if (op_kind == Token_NotEq) {
					res.value = LLVMBuildIsNotNull(p->builder, the_value, "");
					return res;
				}
			} else if (bt->Struct.soa_kind == StructSoa_Dynamic) {
				LLVMValueRef the_value = {};
				if (bt->Struct.fields.count == 0) {
					lbValue cap = lb_soa_struct_cap(p, x);
					the_value = cap.value;
				} else {
					lbValue first_field = lb_emit_struct_ev(p, x, 0);
					the_value = first_field.value;
				}
				if (op_kind == Token_CmpEq) {
					res.value = LLVMBuildIsNull(p->builder, the_value, "");
					return res;
				} else if (op_kind == Token_NotEq) {
					res.value = LLVMBuildIsNotNull(p->builder, the_value, "");
					return res;
				}
			}
		} else if (is_type_struct(t) && type_has_nil(t)) {
			auto args = array_make<lbValue>(permanent_allocator(), 2);
			lbValue lhs = lb_address_from_load_or_generate_local(p, x);
			args[0] = lb_emit_conv(p, lhs, t_rawptr);
			args[1] = lb_const_int(p->module, t_int, type_size_of(t));
			lbValue val = lb_emit_runtime_call(p, "memory_compare_zero", args);
			lbValue res = lb_emit_comp(p, op_kind, val, lb_const_int(p->module, t_int, 0));
			return res;
		}
		break;
	}
	GB_PANIC("Unknown handled type: %s -> %s", type_to_string(t), type_to_string(bt));
	return {};
}

gb_internal lbValue lb_make_soa_pointer(lbProcedure *p, Type *type, lbValue const &addr, lbValue const &index) {
	lbAddr v = lb_add_local_generated(p, type, false);
	lbValue ptr = lb_emit_struct_ep(p, v.addr, 0);
	lbValue idx = lb_emit_struct_ep(p, v.addr, 1);
	lb_emit_store(p, ptr, addr);
	lb_emit_store(p, idx, lb_emit_conv(p, index, t_int));

	return lb_addr_load(p, v);
}

gb_internal lbValue lb_build_unary_and(lbProcedure *p, Ast *expr) {
	ast_node(ue, UnaryExpr, expr);
	auto tv = type_and_value_of_expr(expr);

	Ast *ue_expr = unparen_expr(ue->expr);
	if (ue_expr->kind == Ast_IndexExpr && tv.mode == Addressing_OptionalOkPtr && is_type_tuple(tv.type)) {
		Type *tuple = tv.type;

		Type *map_type = type_of_expr(ue_expr->IndexExpr.expr);
		Type *ot = base_type(map_type);
		Type *t = base_type(type_deref(ot));
		bool deref = t != ot;
		GB_ASSERT(t->kind == Type_Map);
		ast_node(ie, IndexExpr, ue_expr);

		lbValue map_val = lb_build_addr_ptr(p, ie->expr);
		if (deref) {
			map_val = lb_emit_load(p, map_val);
		}

		lbValue key = lb_build_expr(p, ie->index);
		key = lb_emit_conv(p, key, t->Map.key);

		lbAddr addr = lb_addr_map(map_val, key, t, alloc_type_pointer(t->Map.value));
		lbValue ptr = lb_addr_get_ptr(p, addr);

		lbValue ok = lb_emit_comp_against_nil(p, Token_NotEq, ptr);
		ok = lb_emit_conv(p, ok, tuple->Tuple.variables[1]->type);

		lbAddr res = lb_add_local_generated(p, tuple, false);
		lbValue gep0 = lb_emit_struct_ep(p, res.addr, 0);
		lbValue gep1 = lb_emit_struct_ep(p, res.addr, 1);
		lb_emit_store(p, gep0, ptr);
		lb_emit_store(p, gep1, ok);
		return lb_addr_load(p, res);

	} else if (is_type_soa_pointer(tv.type)) {
		ast_node(ie, IndexExpr, ue_expr);
		lbValue addr = lb_build_addr_ptr(p, ie->expr);

		if (is_type_pointer(type_deref(addr.type))) {
			addr = lb_emit_load(p, addr);
		}
		GB_ASSERT(is_type_pointer(addr.type));

		lbValue index = lb_build_expr(p, ie->index);

		if (!build_context.no_bounds_check) {
			// TODO(bill): soa bounds checking
		}

		return lb_make_soa_pointer(p, tv.type, addr, index);
	} else if (ue_expr->kind == Ast_CompoundLit) {
		lbValue v = lb_build_expr(p, ue->expr);

		Type *type = v.type;
		lbAddr addr = {};
		if (p->is_startup) {
			addr = lb_add_global_generated(p->module, type, v);
		} else {
			addr = lb_add_local_generated(p, type, false);
		}
		lb_addr_store(p, addr, v);
		return addr.addr;

	} else if (ue_expr->kind == Ast_TypeAssertion) {
		if (is_type_tuple(tv.type)) {
			Type *tuple = tv.type;
			Type *ptr_type = tuple->Tuple.variables[0]->type;
			Type *ok_type = tuple->Tuple.variables[1]->type;

			ast_node(ta, TypeAssertion, ue_expr);
			TokenPos pos = ast_token(expr).pos;
			Type *type = type_of_expr(ue_expr);
			GB_ASSERT(!is_type_tuple(type));

			lbValue e = lb_build_expr(p, ta->expr);
			Type *t = type_deref(e.type);
			if (is_type_union(t)) {
				lbValue v = e;
				if (!is_type_pointer(v.type)) {
					v = lb_address_from_load_or_generate_local(p, v);
				}
				Type *src_type = type_deref(v.type);
				Type *dst_type = type;

				lbValue src_tag = {};
				lbValue dst_tag = {};
				if (is_type_union_maybe_pointer(src_type)) {
					src_tag = lb_emit_comp_against_nil(p, Token_NotEq, v);
					dst_tag = lb_const_bool(p->module, t_bool, true);
				} else {
					src_tag = lb_emit_load(p, lb_emit_union_tag_ptr(p, v));
					dst_tag = lb_const_union_tag(p->module, src_type, dst_type);
				}

				lbValue ok = lb_emit_comp(p, Token_CmpEq, src_tag, dst_tag);

				lbValue data_ptr = lb_emit_conv(p, v, ptr_type);
				lbAddr res = lb_add_local_generated(p, tuple, true);
				lbValue gep0 = lb_emit_struct_ep(p, res.addr, 0);
				lbValue gep1 = lb_emit_struct_ep(p, res.addr, 1);
				lb_emit_store(p, gep0, lb_emit_select(p, ok, data_ptr, lb_const_nil(p->module, ptr_type)));
				lb_emit_store(p, gep1, lb_emit_conv(p, ok, ok_type));
				return lb_addr_load(p, res);
			} else if (is_type_any(t)) {
				lbValue v = e;
				if (is_type_pointer(v.type)) {
					v = lb_emit_load(p, v);
				}

				lbValue data_ptr = lb_emit_conv(p, lb_emit_struct_ev(p, v, 0), ptr_type);
				lbValue any_id = lb_emit_struct_ev(p, v, 1);
				lbValue id = lb_typeid(p->module, type);

				lbValue ok = lb_emit_comp(p, Token_CmpEq, any_id, id);

				lbAddr res = lb_add_local_generated(p, tuple, false);
				lbValue gep0 = lb_emit_struct_ep(p, res.addr, 0);
				lbValue gep1 = lb_emit_struct_ep(p, res.addr, 1);
				lb_emit_store(p, gep0, lb_emit_select(p, ok, data_ptr, lb_const_nil(p->module, ptr_type)));
				lb_emit_store(p, gep1, lb_emit_conv(p, ok, ok_type));
				return lb_addr_load(p, res);
			} else {
				GB_PANIC("TODO(bill): type assertion %s", type_to_string(type));
			}

		} else {
			GB_ASSERT(is_type_pointer(tv.type));

			ast_node(ta, TypeAssertion, ue_expr);
			TokenPos pos = ast_token(expr).pos;
			Type *type = type_of_expr(ue_expr);
			GB_ASSERT(!is_type_tuple(type));

			lbValue e = lb_build_expr(p, ta->expr);
			Type *t = type_deref(e.type);
			if (is_type_union(t)) {
				lbValue v = e;
				if (!is_type_pointer(v.type)) {
					v = lb_address_from_load_or_generate_local(p, v);
				}
				Type *src_type = type_deref(v.type);
				Type *dst_type = type;


				if ((p->state_flags & StateFlag_no_type_assert) == 0) {
					lbValue src_tag = {};
					lbValue dst_tag = {};
					if (is_type_union_maybe_pointer(src_type)) {
						src_tag = lb_emit_comp_against_nil(p, Token_NotEq, v);
						dst_tag = lb_const_bool(p->module, t_bool, true);
					} else {
						src_tag = lb_emit_load(p, lb_emit_union_tag_ptr(p, v));
						dst_tag = lb_const_union_tag(p->module, src_type, dst_type);
					}


					isize arg_count = 6;
					if (build_context.no_rtti) {
						arg_count = 4;
					}

					lbValue ok = lb_emit_comp(p, Token_CmpEq, src_tag, dst_tag);
					auto args = array_make<lbValue>(permanent_allocator(), arg_count);
					args[0] = ok;

					args[1] = lb_find_or_add_entity_string(p->module, get_file_path_string(pos.file_id));
					args[2] = lb_const_int(p->module, t_i32, pos.line);
					args[3] = lb_const_int(p->module, t_i32, pos.column);

					if (!build_context.no_rtti) {
						args[4] = lb_typeid(p->module, src_type);
						args[5] = lb_typeid(p->module, dst_type);
					}
					lb_emit_runtime_call(p, "type_assertion_check", args);
				}

				lbValue data_ptr = v;
				return lb_emit_conv(p, data_ptr, tv.type);
			} else if (is_type_any(t)) {
				lbValue v = e;
				if (is_type_pointer(v.type)) {
					v = lb_emit_load(p, v);
				}
				lbValue data_ptr = lb_emit_struct_ev(p, v, 0);
				if ((p->state_flags & StateFlag_no_type_assert) == 0) {
					GB_ASSERT(!build_context.no_rtti);

					lbValue any_id = lb_emit_struct_ev(p, v, 1);

					lbValue id = lb_typeid(p->module, type);
					lbValue ok = lb_emit_comp(p, Token_CmpEq, any_id, id);
					auto args = array_make<lbValue>(permanent_allocator(), 6);
					args[0] = ok;

					args[1] = lb_find_or_add_entity_string(p->module, get_file_path_string(pos.file_id));
					args[2] = lb_const_int(p->module, t_i32, pos.line);
					args[3] = lb_const_int(p->module, t_i32, pos.column);

					args[4] = any_id;
					args[5] = id;
					lb_emit_runtime_call(p, "type_assertion_check", args);
				}

				return lb_emit_conv(p, data_ptr, tv.type);
			} else {
				GB_PANIC("TODO(bill): type assertion %s", type_to_string(type));
			}
		}
	}

	return lb_build_addr_ptr(p, ue->expr);
}

gb_internal lbValue lb_build_expr_internal(lbProcedure *p, Ast *expr);
gb_internal lbValue lb_build_expr(lbProcedure *p, Ast *expr) {
	u16 prev_state_flags = p->state_flags;
	defer (p->state_flags = prev_state_flags);

	if (expr->state_flags != 0) {
		u16 in = expr->state_flags;
		u16 out = p->state_flags;

		if (in & StateFlag_bounds_check) {
			out |= StateFlag_bounds_check;
			out &= ~StateFlag_no_bounds_check;
		} else if (in & StateFlag_no_bounds_check) {
			out |= StateFlag_no_bounds_check;
			out &= ~StateFlag_bounds_check;
		}

		if (in & StateFlag_type_assert) {
			out |= StateFlag_type_assert;
			out &= ~StateFlag_no_type_assert;
		} else if (in & StateFlag_no_type_assert) {
			out |= StateFlag_no_type_assert;
			out &= ~StateFlag_type_assert;
		}

		p->state_flags = out;
	}


	// IMPORTANT NOTE(bill):
	// Selector Call Expressions (foo->bar(...))
	// must only evaluate `foo` once as it gets transformed into
	// `foo.bar(foo, ...)`
	// And if `foo` is a procedure call or something more complex, storing the value
	// once is a very good idea
	// If a stored value is found, it must be removed from the cache
	if (expr->state_flags & StateFlag_SelectorCallExpr) {
		lbValue *pp = map_get(&p->selector_values, expr);
		if (pp != nullptr) {
			lbValue res = *pp;
			map_remove(&p->selector_values, expr);
			return res;
		}
		lbAddr *pa = map_get(&p->selector_addr, expr);
		if (pa != nullptr) {
			lbAddr res = *pa;
			map_remove(&p->selector_addr, expr);
			return lb_addr_load(p, res);
		}
	}
	lbValue res = lb_build_expr_internal(p, expr);
	if (expr->state_flags & StateFlag_SelectorCallExpr) {
		map_set(&p->selector_values, expr, res);
	}
	return res;
}

gb_internal lbValue lb_build_expr_internal(lbProcedure *p, Ast *expr) {
	lbModule *m = p->module;

	expr = unparen_expr(expr);

	TokenPos expr_pos = ast_token(expr).pos;
	TypeAndValue tv = type_and_value_of_expr(expr);
	Type *type = type_of_expr(expr);
	GB_ASSERT_MSG(tv.mode != Addressing_Invalid, "invalid expression '%s' (tv.mode = %d, tv.type = %s) @ %s\n Current Proc: %.*s : %s", expr_to_string(expr), tv.mode, type_to_string(tv.type), token_pos_to_string(expr_pos), LIT(p->name), type_to_string(p->type));

	if (tv.value.kind != ExactValue_Invalid) {
		// NOTE(bill): The commented out code below is just for debug purposes only
		// if (is_type_untyped(type)) {
		// 	gb_printf_err("%s %s : %s @ %p\n", token_pos_to_string(expr_pos), expr_to_string(expr), type_to_string(expr->tav.type), expr);
		// 	GB_PANIC("%s\n", type_to_string(tv.type));
		// }

		// NOTE(bill): Short on constant values
		return lb_const_value(p->module, type, tv.value);
	} else if (tv.mode == Addressing_Type) {
		// NOTE(bill, 2023-01-16): is this correct? I hope so at least
		return lb_typeid(m, tv.type);
	}

	switch (expr->kind) {
	case_ast_node(bl, BasicLit, expr);
		TokenPos pos = bl->token.pos;
		GB_PANIC("Non-constant basic literal %s - %.*s", token_pos_to_string(pos), LIT(token_strings[bl->token.kind]));
	case_end;

	case_ast_node(bd, BasicDirective, expr);
		TokenPos pos = bd->token.pos;
		GB_PANIC("Non-constant basic literal %s - %.*s", token_pos_to_string(pos), LIT(bd->name.string));
	case_end;

	case_ast_node(i, Implicit, expr);
		return lb_addr_load(p, lb_build_addr(p, expr));
	case_end;

	case_ast_node(u, Uninit, expr)
		lbValue res = {};
		if (is_type_untyped(type)) {
			res.value = nullptr;
			res.type  = t_untyped_uninit;
		} else {
			res.value = LLVMGetUndef(lb_type(m, type));
			res.type  = type;
		}
		return res;
	case_end;

	case_ast_node(i, Ident, expr);
		Entity *e = entity_from_expr(expr);
		e = strip_entity_wrapping(e);

		GB_ASSERT_MSG(e != nullptr, "%s in %.*s %p", expr_to_string(expr), LIT(p->name), expr);
		if (e->kind == Entity_Builtin) {
			Token token = ast_token(expr);
			GB_PANIC("TODO(bill): lb_build_expr Entity_Builtin '%.*s'\n"
			         "\t at %s", LIT(builtin_procs[e->Builtin.id].name),
			         token_pos_to_string(token.pos));
			return {};
		} else if (e->kind == Entity_Nil) {
			lbValue res = {};
			res.value = nullptr;
			res.type = e->type;
			return res;
		}
		GB_ASSERT(e->kind != Entity_ProcGroup);

		return lb_find_ident(p, m, e, expr);
	case_end;

	case_ast_node(de, DerefExpr, expr);
		return lb_addr_load(p, lb_build_addr(p, expr));
	case_end;

	case_ast_node(se, SelectorExpr, expr);
		TypeAndValue tav = type_and_value_of_expr(expr);
		GB_ASSERT(tav.mode != Addressing_Invalid);
		return lb_addr_load(p, lb_build_addr(p, expr));
	case_end;

	case_ast_node(ise, ImplicitSelectorExpr, expr);
		TypeAndValue tav = type_and_value_of_expr(expr);
		GB_ASSERT(tav.mode == Addressing_Constant);

		return lb_const_value(p->module, type, tv.value);
	case_end;

	case_ast_node(se, SelectorCallExpr, expr);
		GB_ASSERT(se->modified_call);
		return lb_build_call_expr(p, se->call);
	case_end;

	case_ast_node(te, TernaryIfExpr, expr);
		LLVMValueRef incoming_values[2] = {};
		LLVMBasicBlockRef incoming_blocks[2] = {};

		GB_ASSERT(te->y != nullptr);
		lbBlock *then  = lb_create_block(p, "if.then");
		lbBlock *done  = lb_create_block(p, "if.done"); // NOTE(bill): Append later
		lbBlock *else_ = lb_create_block(p, "if.else");

		lb_build_cond(p, te->cond, then, else_);
		lb_start_block(p, then);

		Type *type = default_type(type_of_expr(expr));
		LLVMTypeRef llvm_type = lb_type(p->module, type);

		incoming_values[0] = lb_emit_conv(p, lb_build_expr(p, te->x), type).value;
		if (is_type_internally_pointer_like(type)) {
			incoming_values[0] = LLVMBuildBitCast(p->builder, incoming_values[0], llvm_type, "");
		}

		lb_emit_jump(p, done);
		lb_start_block(p, else_);

		incoming_values[1] = lb_emit_conv(p, lb_build_expr(p, te->y), type).value;

		if (is_type_internally_pointer_like(type)) {
			incoming_values[1] = LLVMBuildBitCast(p->builder, incoming_values[1], llvm_type, "");
		}

		lb_emit_jump(p, done);
		lb_start_block(p, done);

		lbValue res = {};
		res.value = LLVMBuildPhi(p->builder, llvm_type, "");
		res.type = type;

		GB_ASSERT(p->curr_block->preds.count >= 2);
		incoming_blocks[0] = p->curr_block->preds[0]->block;
		incoming_blocks[1] = p->curr_block->preds[1]->block;

		LLVMAddIncoming(res.value, incoming_values, incoming_blocks, 2);

		return res;
	case_end;

	case_ast_node(te, TernaryWhenExpr, expr);
		TypeAndValue tav = type_and_value_of_expr(te->cond);
		GB_ASSERT(tav.mode == Addressing_Constant);
		GB_ASSERT(tav.value.kind == ExactValue_Bool);
		if (tav.value.value_bool) {
			return lb_build_expr(p, te->x);
		} else {
			return lb_build_expr(p, te->y);
		}
	case_end;

	case_ast_node(oe, OrElseExpr, expr);
		return lb_emit_or_else(p, oe->x, oe->y, tv);
	case_end;

	case_ast_node(oe, OrReturnExpr, expr);
		return lb_emit_or_return(p, oe->expr, tv);
	case_end;

	case_ast_node(be, OrBranchExpr, expr);
		lbBlock *block = nullptr;

		if (be->label != nullptr) {
			lbBranchBlocks bb = lb_lookup_branch_blocks(p, be->label);
			switch (be->token.kind) {
			case Token_or_break:    block = bb.break_;    break;
			case Token_or_continue: block = bb.continue_; break;
			}
		} else {
			for (lbTargetList *t = p->target_list; t != nullptr && block == nullptr; t = t->prev) {
				if (t->is_block) {
					continue;
				}

				switch (be->token.kind) {
				case Token_or_break:    block = t->break_;    break;
				case Token_or_continue: block = t->continue_; break;
				}
			}
		}

		GB_ASSERT(block != nullptr);

		lbValue lhs = {};
		lbValue rhs = {};
		lb_emit_try_lhs_rhs(p, be->expr, tv, &lhs, &rhs);
		Type *type = default_type(tv.type);
		if (lhs.value) {
			lhs = lb_emit_conv(p, lhs, type);
		} else if (type != nullptr && type != t_invalid) {
			lhs = lb_const_nil(p->module, type);
		}

		lbBlock *then  = lb_create_block(p, "or_branch.then");
		lbBlock *else_ = lb_create_block(p, "or_branch.else");

		lb_emit_if(p, lb_emit_try_has_value(p, rhs), then, else_);
		lb_start_block(p, else_);
		lb_emit_defer_stmts(p, lbDeferExit_Branch, block);
		lb_emit_jump(p, block);
		lb_start_block(p, then);

		return lhs;
	case_end;

	case_ast_node(ta, TypeAssertion, expr);
		TokenPos pos = ast_token(expr).pos;
		lbValue e = lb_build_expr(p, ta->expr);
		Type *t = type_deref(e.type);
		if (is_type_union(t)) {
			if (ta->ignores[0]) {
				// NOTE(bill): This is not needed for optimization levels other than 0
				return lb_emit_union_cast_only_ok_check(p, e, type, pos);
			}
			return lb_emit_union_cast(p, e, type, pos);
		} else if (is_type_any(t)) {
			return lb_emit_any_cast(p, e, type, pos);
		} else {
			GB_PANIC("TODO(bill): type assertion %s", type_to_string(e.type));
		}
	case_end;

	case_ast_node(tc, TypeCast, expr);
		lbValue e = lb_build_expr(p, tc->expr);
		switch (tc->token.kind) {
		case Token_cast:
			return lb_emit_conv(p, e, type);
		case Token_transmute:
			return lb_emit_transmute(p, e, type);
		}
		GB_PANIC("Invalid AST TypeCast");
	case_end;

	case_ast_node(ac, AutoCast, expr);
		lbValue value = lb_build_expr(p, ac->expr);
		return lb_emit_conv(p, value, type);
	case_end;

	case_ast_node(ue, UnaryExpr, expr);
		switch (ue->op.kind) {
		case Token_And:
			return lb_build_unary_and(p, expr);
		default:
			{
				lbValue v = lb_build_expr(p, ue->expr);
				return lb_emit_unary_arith(p, ue->op.kind, v, type);
			}
		}
	case_end;

	case_ast_node(be, BinaryExpr, expr);
		return lb_build_binary_expr(p, expr);
	case_end;

	case_ast_node(pl, ProcLit, expr);
		return lb_generate_anonymous_proc_lit(p->module, p->name, expr, p);
	case_end;

	case_ast_node(cl, CompoundLit, expr);
		return lb_addr_load(p, lb_build_addr(p, expr));
	case_end;

	case_ast_node(ce, CallExpr, expr);
		return lb_build_call_expr(p, expr);
	case_end;

	case_ast_node(se, SliceExpr, expr);
		if (is_type_slice(type_of_expr(se->expr))) {
			// NOTE(bill): Quick optimization
			if (se->high == nullptr &&
			    (se->low == nullptr || lb_is_expr_constant_zero(se->low))) {
				return lb_build_expr(p, se->expr);
			}
		}
		return lb_addr_load(p, lb_build_addr(p, expr));
	case_end;

	case_ast_node(ie, IndexExpr, expr);
		return lb_addr_load(p, lb_build_addr(p, expr));
	case_end;
	
	case_ast_node(ie, MatrixIndexExpr, expr);
		return lb_addr_load(p, lb_build_addr(p, expr));
	case_end;

	case_ast_node(ia, InlineAsmExpr, expr);
		Type *t = type_of_expr(expr);
		GB_ASSERT(is_type_asm_proc(t));

		String asm_string = {};
		String constraints_string = {};

		TypeAndValue tav;
		tav = type_and_value_of_expr(ia->asm_string);
		GB_ASSERT(is_type_string(tav.type));
		GB_ASSERT(tav.value.kind == ExactValue_String);
		asm_string = tav.value.value_string;

		tav = type_and_value_of_expr(ia->constraints_string);
		GB_ASSERT(is_type_string(tav.type));
		GB_ASSERT(tav.value.kind == ExactValue_String);
		constraints_string = tav.value.value_string;


		LLVMInlineAsmDialect dialect = LLVMInlineAsmDialectATT;
		switch (ia->dialect) {
		case InlineAsmDialect_Default: dialect = LLVMInlineAsmDialectATT;   break;
		case InlineAsmDialect_ATT:     dialect = LLVMInlineAsmDialectATT;   break;
		case InlineAsmDialect_Intel:   dialect = LLVMInlineAsmDialectIntel; break;
		default: GB_PANIC("Unhandled inline asm dialect"); break;
		}

		LLVMTypeRef func_type = lb_type_internal_for_procedures_raw(p->module, t);
		LLVMValueRef the_asm = llvm_get_inline_asm(func_type, asm_string, constraints_string, ia->has_side_effects, ia->has_side_effects, dialect);
		GB_ASSERT(the_asm != nullptr);
		return {the_asm, t};
	case_end;
	}

	GB_PANIC("lb_build_expr: %.*s", LIT(ast_strings[expr->kind]));

	return {};
}

gb_internal lbAddr lb_get_soa_variable_addr(lbProcedure *p, Entity *e) {
	return map_must_get(&p->module->soa_values, e);
}
gb_internal lbValue lb_get_using_variable(lbProcedure *p, Entity *e) {
	GB_ASSERT(e->kind == Entity_Variable && e->flags & EntityFlag_Using);
	String name = e->token.string;
	Entity *parent = e->using_parent;
	Selection sel = lookup_field(parent->type, name, false);
	GB_ASSERT(sel.entity != nullptr);
	lbValue *pv = map_get(&p->module->values, parent);

	lbValue v = {};

	if (pv == nullptr && parent->flags & EntityFlag_SoaPtrField) {
		// NOTE(bill): using SOA value (probably from for-in statement)
		lbAddr parent_addr = lb_get_soa_variable_addr(p, parent);
		v = lb_addr_get_ptr(p, parent_addr);
	} else if (pv != nullptr) {
		v = *pv;
	} else {
		GB_ASSERT_MSG(e->using_expr != nullptr, "%.*s", LIT(name));
		v = lb_build_addr_ptr(p, e->using_expr);
	}
	GB_ASSERT(v.value != nullptr);
	GB_ASSERT_MSG(parent->type == type_deref(v.type), "%s %s", type_to_string(parent->type), type_to_string(v.type));
	lbValue ptr = lb_emit_deep_field_gep(p, v, sel);
	if (parent->scope) {
		if ((parent->scope->flags & (ScopeFlag_File|ScopeFlag_Pkg)) == 0) {
			lb_add_debug_local_variable(p, ptr.value, e->type, e->token);
		}
	} else {
		lb_add_debug_local_variable(p, ptr.value, e->type, e->token);
	}
	return ptr;
}



gb_internal lbAddr lb_build_addr_from_entity(lbProcedure *p, Entity *e, Ast *expr) {
	GB_ASSERT(e != nullptr);
	if (e->kind == Entity_Constant) {
		Type *t = default_type(type_of_expr(expr));
		lbValue v = lb_const_value(p->module, t, e->Constant.value);
		if (LLVMIsConstant(v.value)) {
			lbAddr g = lb_add_global_generated(p->module, t, v);
			return g;
		}
		GB_ASSERT(LLVMIsALoadInst(v.value));
		lbValue ptr = {};
		ptr.value = LLVMGetOperand(v.value, 0);
		ptr.type = alloc_type_pointer(t);
		return lb_addr(ptr);
	}


	lbValue v = {};
	lbValue *found = map_get(&p->module->values, e);
	if (found) {
		v = *found;
	} else if (e->kind == Entity_Variable && e->flags & EntityFlag_Using) {
		// NOTE(bill): Calculate the using variable every time
		v = lb_get_using_variable(p, e);
	} else if (e->flags & EntityFlag_SoaPtrField) {
		return lb_get_soa_variable_addr(p, e);
	}


	if (v.value == nullptr) {
		return lb_addr(lb_find_value_from_entity(p->module, e));

		// error(expr, "%.*s Unknown value: %.*s, entity: %p %.*s",
		//       LIT(p->name),
		//       LIT(e->token.string), e, LIT(entity_strings[e->kind]));
		// GB_PANIC("Unknown value");
	}

	return lb_addr(v);
}

gb_internal lbAddr lb_build_array_swizzle_addr(lbProcedure *p, AstCallExpr *ce, TypeAndValue const &tv) {
	isize index_count = ce->args.count-1;
	lbAddr addr = lb_build_addr(p, ce->args[0]);
	if (index_count == 0) {
		return addr;
	}
	Type *type = base_type(lb_addr_type(addr));
	GB_ASSERT(type->kind == Type_Array);
	i64 count = type->Array.count;
	if (count <= 4) {
		u8 indices[4] = {};
		u8 index_count = 0;
		for (i32 i = 1; i < ce->args.count; i++) {
			TypeAndValue tv = type_and_value_of_expr(ce->args[i]);
			GB_ASSERT(is_type_integer(tv.type));
			GB_ASSERT(tv.value.kind == ExactValue_Integer);

			i64 src_index = big_int_to_i64(&tv.value.value_integer);
			indices[index_count++] = cast(u8)src_index;
		}
		return lb_addr_swizzle(lb_addr_get_ptr(p, addr), tv.type, index_count, indices);
	}
	auto indices = slice_make<i32>(permanent_allocator(), ce->args.count-1);
	isize index_index = 0;
	for (i32 i = 1; i < ce->args.count; i++) {
		TypeAndValue tv = type_and_value_of_expr(ce->args[i]);
		GB_ASSERT(is_type_integer(tv.type));
		GB_ASSERT(tv.value.kind == ExactValue_Integer);

		i64 src_index = big_int_to_i64(&tv.value.value_integer);
		indices[index_index++] = cast(i32)src_index;
	}
	return lb_addr_swizzle_large(lb_addr_get_ptr(p, addr), tv.type, indices);
}


gb_internal lbAddr lb_build_addr_internal(lbProcedure *p, Ast *expr);
gb_internal lbAddr lb_build_addr(lbProcedure *p, Ast *expr) {
	expr = unparen_expr(expr);

	// IMPORTANT NOTE(bill):
	// Selector Call Expressions (foo->bar(...))
	// must only evaluate `foo` once as it gets transformed into
	// `foo.bar(foo, ...)`
	// And if `foo` is a procedure call or something more complex, storing the value
	// once is a very good idea
	// If a stored value is found, it must be removed from the cache
	if (expr->state_flags & StateFlag_SelectorCallExpr) {
		lbAddr *pp = map_get(&p->selector_addr, expr);
		if (pp != nullptr) {
			lbAddr res = *pp;
			map_remove(&p->selector_addr, expr);
			return res;
		}
	}
	lbAddr addr = lb_build_addr_internal(p, expr);
	if (expr->state_flags & StateFlag_SelectorCallExpr) {
		map_set(&p->selector_addr, expr, addr);
	}
	return addr;
}

gb_internal void lb_build_addr_compound_lit_populate(lbProcedure *p, Slice<Ast *> const &elems, Array<lbCompoundLitElemTempData> *temp_data, Type *compound_type) {
	Type *bt = base_type(compound_type);
	Type *et = nullptr;
	switch (bt->kind) {
	case Type_Array:           et = bt->Array.elem;           break;
	case Type_EnumeratedArray: et = bt->EnumeratedArray.elem; break;
	case Type_Slice:           et = bt->Slice.elem;           break;
	case Type_BitSet:          et = bt->BitSet.elem;          break;
	case Type_DynamicArray:    et = bt->DynamicArray.elem;    break;
	case Type_SimdVector:      et = bt->SimdVector.elem;      break;
	case Type_Matrix:          et = bt->Matrix.elem;          break;
	}
	GB_ASSERT(et != nullptr);


	// NOTE(bill): Separate value, gep, store into their own chunks
	for_array(i, elems) {
		Ast *elem = elems[i];
		if (elem->kind == Ast_FieldValue) {
			ast_node(fv, FieldValue, elem);
			if (bt->kind != Type_DynamicArray && lb_is_elem_const(fv->value, et)) {
				continue;
			}
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

				lbValue value = lb_emit_conv(p, lb_build_expr(p, fv->value), et);

				GB_ASSERT((hi-lo) > 0);

				if (bt->kind == Type_Matrix) {
					for (i64 k = lo; k < hi; k++) {
						lbCompoundLitElemTempData data = {};
						data.value = value;

						data.elem_index = matrix_row_major_index_to_offset(bt, k);
						array_add(temp_data, data);
					}
				} else {
					enum {MAX_ELEMENT_AMOUNT = 32};
					if ((hi-lo) <= MAX_ELEMENT_AMOUNT) {
						for (i64 k = lo; k < hi; k++) {
							lbCompoundLitElemTempData data = {};
							data.value = value;
							data.elem_index = k;
							array_add(temp_data, data);
						}
					} else {
						lbCompoundLitElemTempData data = {};
						data.value = value;
						data.elem_index = lo;
						data.elem_length = hi-lo;
						array_add(temp_data, data);
					}
				}
			} else {
				auto tav = fv->field->tav;
				GB_ASSERT(tav.mode == Addressing_Constant);
				i64 index = exact_value_to_i64(tav.value);

				lbValue value = lb_emit_conv(p, lb_build_expr(p, fv->value), et);
				GB_ASSERT(!is_type_tuple(value.type));

				lbCompoundLitElemTempData data = {};
				data.value = value;
				data.expr = fv->value;
				if (bt->kind == Type_Matrix) {
					data.elem_index = matrix_row_major_index_to_offset(bt, index);
				} else {
					data.elem_index = index;
				}
				array_add(temp_data, data);
			}

		} else {
			if (bt->kind != Type_DynamicArray && lb_is_elem_const(elem, et)) {
				continue;
			}

			lbValue field_expr = lb_build_expr(p, elem);
			GB_ASSERT(!is_type_tuple(field_expr.type));

			lbValue ev = lb_emit_conv(p, field_expr, et);

			lbCompoundLitElemTempData data = {};
			data.value = ev;
			if (bt->kind == Type_Matrix) {
				data.elem_index = matrix_row_major_index_to_offset(bt, i);
			} else {
				data.elem_index = i;
			}
			array_add(temp_data, data);
		}
	}
}
gb_internal void lb_build_addr_compound_lit_assign_array(lbProcedure *p, Array<lbCompoundLitElemTempData> const &temp_data) {
	for (auto const &td : temp_data) {
		if (td.value.value != nullptr) {
			if (td.elem_length > 0) {
				auto loop_data = lb_loop_start(p, cast(isize)td.elem_length, t_i32);
				{
					lbValue dst = td.gep;
					dst = lb_emit_ptr_offset(p, dst, loop_data.idx);
					lb_emit_store(p, dst, td.value);
				}
				lb_loop_end(p, loop_data);
			} else {
				lb_emit_store(p, td.gep, td.value);
			}
		}
	}
}

gb_internal lbAddr lb_build_addr_index_expr(lbProcedure *p, Ast *expr) {
	ast_node(ie, IndexExpr, expr);

	Type *t = base_type(type_of_expr(ie->expr));

	bool deref = is_type_pointer(t);
	t = base_type(type_deref(t));
	if (is_type_soa_struct(t)) {
		// SOA STRUCTURES!!!!
		lbValue val = lb_build_addr_ptr(p, ie->expr);
		if (deref) {
			val = lb_emit_load(p, val);
		}

		lbValue index = lb_build_expr(p, ie->index);
		return lb_addr_soa_variable(val, index, ie->index);
	}

	if (ie->expr->tav.mode == Addressing_SoaVariable) {
		// SOA Structures for slices/dynamic arrays
		GB_ASSERT(is_type_pointer(type_of_expr(ie->expr)));

		lbValue field = lb_build_expr(p, ie->expr);
		lbValue index = lb_build_expr(p, ie->index);


		if (!build_context.no_bounds_check) {
			// TODO HACK(bill): Clean up this hack to get the length for bounds checking
			// GB_ASSERT(LLVMIsALoadInst(field.value));

			// lbValue a = {};
			// a.value = LLVMGetOperand(field.value, 0);
			// a.type = alloc_type_pointer(field.type);

			// irInstr *b = &a->Instr;
			// GB_ASSERT(b->kind == irInstr_StructElementPtr);
			// lbValue base_struct = b->StructElementPtr.address;

			// GB_ASSERT(is_type_soa_struct(type_deref(ir_type(base_struct))));
			// lbValue len = ir_soa_struct_len(p, base_struct);
			// lb_emit_bounds_check(p, ast_token(ie->index), index, len);
		}
		lbValue val = lb_emit_ptr_offset(p, field, index);
		return lb_addr(val);
	}

	GB_ASSERT_MSG(is_type_indexable(t), "%s %s", type_to_string(t), expr_to_string(expr));

	if (is_type_map(t)) {
		lbAddr map_addr = lb_build_addr(p, ie->expr);
		lbValue key = lb_build_expr(p, ie->index);
		key = lb_emit_conv(p, key, t->Map.key);

		Type *result_type = type_of_expr(expr);
		lbValue map_ptr = lb_addr_get_ptr(p, map_addr);
		if (is_type_pointer(type_deref(map_ptr.type))) {
			map_ptr = lb_emit_load(p, map_ptr);
		}
		return lb_addr_map(map_ptr, key, t, result_type);
	}

	switch (t->kind) {
	case Type_Array: {
		lbValue array = {};
		array = lb_build_addr_ptr(p, ie->expr);
		if (deref) {
			array = lb_emit_load(p, array);
		}
		lbValue index = lb_build_expr(p, ie->index);
		index = lb_emit_conv(p, index, t_int);
		lbValue elem = lb_emit_array_ep(p, array, index);

		auto index_tv = type_and_value_of_expr(ie->index);
		if (index_tv.mode != Addressing_Constant) {
			lbValue len = lb_const_int(p->module, t_int, t->Array.count);
			lb_emit_bounds_check(p, ast_token(ie->index), index, len);
		}
		return lb_addr(elem);
	}

	case Type_EnumeratedArray: {
		lbValue array = {};
		array = lb_build_addr_ptr(p, ie->expr);
		if (deref) {
			array = lb_emit_load(p, array);
		}

		Type *index_type = t->EnumeratedArray.index;

		auto index_tv = type_and_value_of_expr(ie->index);

		lbValue index = {};
		if (compare_exact_values(Token_NotEq, *t->EnumeratedArray.min_value, exact_value_i64(0))) {
			if (index_tv.mode == Addressing_Constant) {
				ExactValue idx = exact_value_sub(index_tv.value, *t->EnumeratedArray.min_value);
				index = lb_const_value(p->module, index_type, idx);
			} else {
				index = lb_emit_arith(p, Token_Sub,
				                      lb_build_expr(p, ie->index),
				                      lb_const_value(p->module, index_type, *t->EnumeratedArray.min_value),
				                      index_type);
				index = lb_emit_conv(p, index, t_int);
			}
		} else {
			index = lb_emit_conv(p, lb_build_expr(p, ie->index), t_int);
		}

		lbValue elem = lb_emit_array_ep(p, array, index);

		if (index_tv.mode != Addressing_Constant) {
			lbValue len = lb_const_int(p->module, t_int, t->EnumeratedArray.count);
			lb_emit_bounds_check(p, ast_token(ie->index), index, len);
		}
		return lb_addr(elem);
	}

	case Type_Slice: {
		lbValue slice = {};
		slice = lb_build_expr(p, ie->expr);
		if (deref) {
			slice = lb_emit_load(p, slice);
		}
		lbValue elem = lb_slice_elem(p, slice);
		lbValue index = lb_emit_conv(p, lb_build_expr(p, ie->index), t_int);
		lbValue len = lb_slice_len(p, slice);
		lb_emit_bounds_check(p, ast_token(ie->index), index, len);
		lbValue v = lb_emit_ptr_offset(p, elem, index);
		return lb_addr(v);
	}

	case Type_MultiPointer: {
		lbValue multi_ptr = {};
		multi_ptr = lb_build_expr(p, ie->expr);
		if (deref) {
			multi_ptr = lb_emit_load(p, multi_ptr);
		}
		lbValue index = lb_build_expr(p, ie->index);
		index = lb_emit_conv(p, index, t_int);
		lbValue v = {};

		LLVMValueRef indices[1] = {index.value};
		v.value = LLVMBuildGEP2(p->builder, lb_type(p->module, t->MultiPointer.elem), multi_ptr.value, indices, 1, "");
		v.type = alloc_type_pointer(t->MultiPointer.elem);
		return lb_addr(v);
	}

	case Type_RelativeMultiPointer: {
		lbAddr rel_ptr_addr = {};
		if (deref) {
			lbValue rel_ptr_ptr = lb_build_expr(p, ie->expr);
			rel_ptr_addr = lb_addr(rel_ptr_ptr);
		} else {
			rel_ptr_addr = lb_build_addr(p, ie->expr);
		}
		lbValue rel_ptr = lb_relative_pointer_to_pointer(p, rel_ptr_addr);

		lbValue index = lb_build_expr(p, ie->index);
		index = lb_emit_conv(p, index, t_int);
		lbValue v = {};

		Type *pointer_type = base_type(t->RelativeMultiPointer.pointer_type);
		GB_ASSERT(pointer_type->kind == Type_MultiPointer);
		Type *elem = pointer_type->MultiPointer.elem;

		LLVMValueRef indices[1] = {index.value};
		v.value = LLVMBuildGEP2(p->builder, lb_type(p->module, elem), rel_ptr.value, indices, 1, "");
		v.type = alloc_type_pointer(elem);
		return lb_addr(v);
	}

	case Type_DynamicArray: {
		lbValue dynamic_array = {};
		dynamic_array = lb_build_expr(p, ie->expr);
		if (deref) {
			dynamic_array = lb_emit_load(p, dynamic_array);
		}
		lbValue elem = lb_dynamic_array_elem(p, dynamic_array);
		lbValue len = lb_dynamic_array_len(p, dynamic_array);
		lbValue index = lb_emit_conv(p, lb_build_expr(p, ie->index), t_int);
		lb_emit_bounds_check(p, ast_token(ie->index), index, len);
		lbValue v = lb_emit_ptr_offset(p, elem, index);
		return lb_addr(v);
	}

	case Type_Matrix: {
		lbValue matrix = {};
		matrix = lb_build_addr_ptr(p, ie->expr);
		if (deref) {
			matrix = lb_emit_load(p, matrix);
		}
		lbValue index = lb_build_expr(p, ie->index);
		index = lb_emit_conv(p, index, t_int);
		lbValue elem = lb_emit_matrix_ep(p, matrix, lb_const_int(p->module, t_int, 0), index);
		elem = lb_emit_conv(p, elem, alloc_type_pointer(type_of_expr(expr)));

		auto index_tv = type_and_value_of_expr(ie->index);
		if (index_tv.mode != Addressing_Constant) {
			lbValue len = lb_const_int(p->module, t_int, t->Matrix.column_count);
			lb_emit_bounds_check(p, ast_token(ie->index), index, len);
		}
		return lb_addr(elem);
	}


	case Type_Basic: { // Basic_string
		lbValue str;
		lbValue elem;
		lbValue len;
		lbValue index;

		str = lb_build_expr(p, ie->expr);
		if (deref) {
			str = lb_emit_load(p, str);
		}
		elem = lb_string_elem(p, str);
		len = lb_string_len(p, str);

		index = lb_emit_conv(p, lb_build_expr(p, ie->index), t_int);
		lb_emit_bounds_check(p, ast_token(ie->index), index, len);

		return lb_addr(lb_emit_ptr_offset(p, elem, index));
	}
	}
	return {};
}


gb_internal lbAddr lb_build_addr_slice_expr(lbProcedure *p, Ast *expr) {
	ast_node(se, SliceExpr, expr);

	lbValue low  = lb_const_int(p->module, t_int, 0);
	lbValue high = {};

	if (se->low  != nullptr) {
		low = lb_correct_endianness(p, lb_build_expr(p, se->low));
	}
	if (se->high != nullptr) {
		high = lb_correct_endianness(p, lb_build_expr(p, se->high));
	}

	bool no_indices = se->low == nullptr && se->high == nullptr;

	lbAddr addr = lb_build_addr(p, se->expr);
	lbValue base = lb_addr_load(p, addr);
	Type *type = base_type(base.type);

	if (is_type_pointer(type)) {
		type = base_type(type_deref(type));
		addr = lb_addr(base);
		base = lb_addr_load(p, addr);
	}

	switch (type->kind) {
	case Type_Slice: {
		Type *slice_type = type;
		lbValue len = lb_slice_len(p, base);
		if (high.value == nullptr) high = len;

		if (!no_indices) {
			lb_emit_slice_bounds_check(p, se->open, low, high, len, se->low != nullptr);
		}

		lbValue elem    = lb_emit_ptr_offset(p, lb_slice_elem(p, base), low);
		lbValue new_len = lb_emit_arith(p, Token_Sub, high, low, t_int);

		lbAddr slice = lb_add_local_generated(p, slice_type, false);
		lb_fill_slice(p, slice, elem, new_len);
		return slice;
	}

	case Type_RelativePointer:
		GB_PANIC("TODO(bill): Type_RelativePointer should be handled above already on the lb_addr_load");
		break;
	case Type_RelativeMultiPointer:
		GB_PANIC("TODO(bill): Type_RelativeMultiPointer should be handled above already on the lb_addr_load");
		break;

	case Type_DynamicArray: {
		Type *elem_type = type->DynamicArray.elem;
		Type *slice_type = alloc_type_slice(elem_type);

		lbValue len = lb_dynamic_array_len(p, base);
		if (high.value == nullptr) high = len;

		if (!no_indices) {
			lb_emit_slice_bounds_check(p, se->open, low, high, len, se->low != nullptr);
		}

		lbValue elem    = lb_emit_ptr_offset(p, lb_dynamic_array_elem(p, base), low);
		lbValue new_len = lb_emit_arith(p, Token_Sub, high, low, t_int);

		lbAddr slice = lb_add_local_generated(p, slice_type, false);
		lb_fill_slice(p, slice, elem, new_len);
		return slice;
	}

	case Type_MultiPointer: {
		lbAddr res = lb_add_local_generated(p, type_of_expr(expr), false);
		if (se->high == nullptr) {
			lbValue offset = base;
			LLVMValueRef indices[1] = {low.value};
			offset.value = LLVMBuildGEP2(p->builder, lb_type(p->module, offset.type->MultiPointer.elem), offset.value, indices, 1, "");
			lb_addr_store(p, res, offset);
		} else {
			low = lb_emit_conv(p, low, t_int);
			high = lb_emit_conv(p, high, t_int);

			lb_emit_multi_pointer_slice_bounds_check(p, se->open, low, high);

			LLVMValueRef indices[1] = {low.value};
			LLVMValueRef ptr = LLVMBuildGEP2(p->builder, lb_type(p->module, base.type->MultiPointer.elem), base.value, indices, 1, "");
			LLVMValueRef len = LLVMBuildSub(p->builder, high.value, low.value, "");

			LLVMValueRef gep0 = lb_emit_struct_ep(p, res.addr, 0).value;
			LLVMValueRef gep1 = lb_emit_struct_ep(p, res.addr, 1).value;
			LLVMBuildStore(p->builder, ptr, gep0);
			LLVMBuildStore(p->builder, len, gep1);
		}
		return res;
	}

	case Type_Array: {
		Type *slice_type = alloc_type_slice(type->Array.elem);
		lbValue len = lb_const_int(p->module, t_int, type->Array.count);

		if (high.value == nullptr) high = len;

		bool low_const  = type_and_value_of_expr(se->low).mode  == Addressing_Constant;
		bool high_const = type_and_value_of_expr(se->high).mode == Addressing_Constant;

		if (!low_const || !high_const) {
			if (!no_indices) {
				lb_emit_slice_bounds_check(p, se->open, low, high, len, se->low != nullptr);
			}
		}
		lbValue elem    = lb_emit_ptr_offset(p, lb_array_elem(p, lb_addr_get_ptr(p, addr)), low);
		lbValue new_len = lb_emit_arith(p, Token_Sub, high, low, t_int);

		lbAddr slice = lb_add_local_generated(p, slice_type, false);
		lb_fill_slice(p, slice, elem, new_len);
		return slice;
	}

	case Type_Basic: {
		GB_ASSERT_MSG(are_types_identical(type, t_string), "got %s", type_to_string(type));
		lbValue len = lb_string_len(p, base);
		if (high.value == nullptr) high = len;

		if (!no_indices) {
			lb_emit_slice_bounds_check(p, se->open, low, high, len, se->low != nullptr);
		}

		lbValue elem    = lb_emit_ptr_offset(p, lb_string_elem(p, base), low);
		lbValue new_len = lb_emit_arith(p, Token_Sub, high, low, t_int);

		lbAddr str = lb_add_local_generated(p, t_string, false);
		lb_fill_string(p, str, elem, new_len);
		return str;
	}


	case Type_Struct:
		if (is_type_soa_struct(type)) {
			lbValue len = lb_soa_struct_len(p, lb_addr_get_ptr(p, addr));
			if (high.value == nullptr) high = len;

			if (!no_indices) {
				lb_emit_slice_bounds_check(p, se->open, low, high, len, se->low != nullptr);
			}
			#if 1

			lbAddr dst = lb_add_local_generated(p, type_of_expr(expr), true);
			if (type->Struct.soa_kind == StructSoa_Fixed) {
				i32 field_count = cast(i32)type->Struct.fields.count;
				for (i32 i = 0; i < field_count; i++) {
					lbValue field_dst = lb_emit_struct_ep(p, dst.addr, i);
					lbValue field_src = lb_emit_struct_ep(p, lb_addr_get_ptr(p, addr), i);
					field_src = lb_emit_array_ep(p, field_src, low);
					lb_emit_store(p, field_dst, field_src);
				}

				lbValue len_dst = lb_emit_struct_ep(p, dst.addr, field_count);
				lbValue new_len = lb_emit_arith(p, Token_Sub, high, low, t_int);
				lb_emit_store(p, len_dst, new_len);
			} else if (type->Struct.soa_kind == StructSoa_Slice) {
				if (no_indices) {
					lb_addr_store(p, dst, base);
				} else {
					i32 field_count = cast(i32)type->Struct.fields.count - 1;
					for (i32 i = 0; i < field_count; i++) {
						lbValue field_dst = lb_emit_struct_ep(p, dst.addr, i);
						lbValue field_src = lb_emit_struct_ev(p, base, i);
						field_src = lb_emit_ptr_offset(p, field_src, low);
						lb_emit_store(p, field_dst, field_src);
					}


					lbValue len_dst = lb_emit_struct_ep(p, dst.addr, field_count);
					lbValue new_len = lb_emit_arith(p, Token_Sub, high, low, t_int);
					lb_emit_store(p, len_dst, new_len);
				}
			} else if (type->Struct.soa_kind == StructSoa_Dynamic) {
				i32 field_count = cast(i32)type->Struct.fields.count - 3;
				for (i32 i = 0; i < field_count; i++) {
					lbValue field_dst = lb_emit_struct_ep(p, dst.addr, i);
					lbValue field_src = lb_emit_struct_ev(p, base, i);
					field_src = lb_emit_ptr_offset(p, field_src, low);
					lb_emit_store(p, field_dst, field_src);
				}


				lbValue len_dst = lb_emit_struct_ep(p, dst.addr, field_count);
				lbValue new_len = lb_emit_arith(p, Token_Sub, high, low, t_int);
				lb_emit_store(p, len_dst, new_len);
			}

			return dst;
			#endif
		}
		break;

	}

	GB_PANIC("Unknown slicable type");
	return {};
}

gb_internal lbAddr lb_build_addr_compound_lit(lbProcedure *p, Ast *expr) {
	ast_node(cl, CompoundLit, expr);

	Type *type = type_of_expr(expr);
	Type *bt = base_type(type);

	lbAddr v = lb_add_local_generated(p, type, true);

	TEMPORARY_ALLOCATOR_GUARD();

	Type *et = nullptr;
	switch (bt->kind) {
	case Type_Array:           et = bt->Array.elem;           break;
	case Type_EnumeratedArray: et = bt->EnumeratedArray.elem; break;
	case Type_Slice:           et = bt->Slice.elem;           break;
	case Type_BitSet:          et = bt->BitSet.elem;          break;
	case Type_SimdVector:      et = bt->SimdVector.elem;      break;
	case Type_Matrix:          et = bt->Matrix.elem;          break;
	}

	String proc_name = {};
	if (p->entity) {
		proc_name = p->entity->token.string;
	}
	TokenPos pos = ast_token(expr).pos;

	switch (bt->kind) {
	default: GB_PANIC("Unknown CompoundLit type: %s", type_to_string(type)); break;

	case Type_BitField:
		for (Ast *elem : cl->elems) {
			ast_node(fv, FieldValue, elem);
			String name = fv->field->Ident.token.string;
			Selection sel = lookup_field(bt, name, false);
			GB_ASSERT(sel.is_bit_field);
			GB_ASSERT(!sel.indirect);
			GB_ASSERT(sel.index.count == 1);
			GB_ASSERT(sel.entity != nullptr);

			i64 index = sel.index[0];
			i64 bit_offset = 0;
			i64 bit_size = -1;
			for_array(i, bt->BitField.fields) {
				Entity *f = bt->BitField.fields[i];
				if (f == sel.entity) {
					bit_offset = bt->BitField.bit_offsets[i];
					bit_size   = bt->BitField.bit_sizes[i];
					break;
				}
			}
			GB_ASSERT(bit_size > 0);

			Type *field_type = sel.entity->type;
			lbValue field_expr = lb_build_expr(p, fv->value);
			field_expr = lb_emit_conv(p, field_expr, field_type);

			lbAddr field_addr = lb_addr_bit_field(v.addr, field_type, index, bit_offset, bit_size);
			lb_addr_store(p, field_addr, field_expr);
		}
		return v;

	case Type_Struct: {
		// TODO(bill): "constant" '#raw_union's are not initialized constantly at the moment.
		// NOTE(bill): This is due to the layout of the unions when printed to LLVM-IR
		bool is_raw_union = is_type_raw_union(bt);
		GB_ASSERT(is_type_struct(bt) || is_raw_union);
		TypeStruct *st = &bt->Struct;
		if (cl->elems.count > 0) {
			lb_addr_store(p, v, lb_const_value(p->module, type, exact_value_compound(expr)));
			lbValue comp_lit_ptr = lb_addr_get_ptr(p, v);

			for_array(field_index, cl->elems) {
				Ast *elem = cl->elems[field_index];

				lbValue field_expr = {};
				Entity *field = nullptr;
				isize index = field_index;

				if (elem->kind == Ast_FieldValue) {
					ast_node(fv, FieldValue, elem);
					String name = fv->field->Ident.token.string;
					Selection sel = lookup_field(bt, name, false);
					GB_ASSERT(!sel.indirect);

					elem = fv->value;
					if (sel.index.count > 1) {
						if (lb_is_nested_possibly_constant(type, sel, elem)) {
							continue;
						}
						lbValue dst = lb_emit_deep_field_gep(p, comp_lit_ptr, sel);
						field_expr = lb_build_expr(p, elem);
						field_expr = lb_emit_conv(p, field_expr, sel.entity->type);
						lb_emit_store(p, dst, field_expr);
						continue;
					}

					index = sel.index[0];
				} else {
					Selection sel = lookup_field_from_index(bt, st->fields[field_index]->Variable.field_index);
					GB_ASSERT(sel.index.count == 1);
					GB_ASSERT(!sel.indirect);
					index = sel.index[0];
				}

				field = st->fields[index];
				Type *ft = field->type;
				if (!is_raw_union && !is_type_typeid(ft) && lb_is_elem_const(elem, ft)) {
					continue;
				}

				field_expr = lb_build_expr(p, elem);

				lbValue gep = {};
				if (is_raw_union) {
					gep = lb_emit_conv(p, comp_lit_ptr, alloc_type_pointer(ft));
				} else {
					gep = lb_emit_struct_ep(p, comp_lit_ptr, cast(i32)index);
				}

				Type *fet = field_expr.type;
				GB_ASSERT(fet->kind != Type_Tuple);

				// HACK TODO(bill): THIS IS A MASSIVE HACK!!!!
				if (is_type_union(ft) && !are_types_identical(fet, ft) && !is_type_untyped(fet)) {
					GB_ASSERT_MSG(union_variant_index(ft, fet) >= 0, "%s", type_to_string(fet));

					lb_emit_store_union_variant(p, gep, field_expr, fet);
				} else {
					lbValue fv = lb_emit_conv(p, field_expr, ft);
					lb_emit_store(p, gep, fv);
				}
			}
		}
		break;
	}

	case Type_Map: {
		if (cl->elems.count == 0) {
			break;
		}
		GB_ASSERT(!build_context.no_dynamic_literals);

		lbValue err = lb_dynamic_map_reserve(p, v.addr, 2*cl->elems.count, pos);
		gb_unused(err);

		for (Ast *elem : cl->elems) {
			ast_node(fv, FieldValue, elem);

			lbValue key   = lb_build_expr(p, fv->field);
			lbValue value = lb_build_expr(p, fv->value);
			lb_internal_dynamic_map_set(p, v.addr, type, key, value, elem);
		}
		break;
	}

	case Type_Array: {
		if (cl->elems.count > 0) {
			lb_addr_store(p, v, lb_const_value(p->module, type, exact_value_compound(expr)));

			auto temp_data = array_make<lbCompoundLitElemTempData>(temporary_allocator(), 0, cl->elems.count);

			lb_build_addr_compound_lit_populate(p, cl->elems, &temp_data, type);

			lbValue dst_ptr = lb_addr_get_ptr(p, v);
			for_array(i, temp_data) {
				i32 index = cast(i32)(temp_data[i].elem_index);
				temp_data[i].gep = lb_emit_array_epi(p, dst_ptr, index);
			}

			lb_build_addr_compound_lit_assign_array(p, temp_data);
		}
		break;
	}
	case Type_EnumeratedArray: {
		if (cl->elems.count > 0) {
			lb_addr_store(p, v, lb_const_value(p->module, type, exact_value_compound(expr)));

			auto temp_data = array_make<lbCompoundLitElemTempData>(temporary_allocator(), 0, cl->elems.count);

			lb_build_addr_compound_lit_populate(p, cl->elems, &temp_data, type);

			lbValue dst_ptr = lb_addr_get_ptr(p, v);
			i64 index_offset = exact_value_to_i64(*bt->EnumeratedArray.min_value);
			for_array(i, temp_data) {
				i32 index = cast(i32)(temp_data[i].elem_index - index_offset);
				temp_data[i].gep = lb_emit_array_epi(p, dst_ptr, index);
			}

			lb_build_addr_compound_lit_assign_array(p, temp_data);
		}
		break;
	}
	case Type_Slice: {
		if (cl->elems.count > 0) {
			lbValue slice = lb_const_value(p->module, type, exact_value_compound(expr));

			lbValue data = lb_slice_elem(p, slice);

			auto temp_data = array_make<lbCompoundLitElemTempData>(temporary_allocator(), 0, cl->elems.count);

			lb_build_addr_compound_lit_populate(p, cl->elems, &temp_data, type);

			for_array(i, temp_data) {
				temp_data[i].gep = lb_emit_ptr_offset(p, data, lb_const_int(p->module, t_int, temp_data[i].elem_index));
			}

			lb_build_addr_compound_lit_assign_array(p, temp_data);

			{
				lbValue count = {};
				count.type = t_int;

				unsigned len_index = lb_convert_struct_index(p->module, type, 1);
				if (lb_is_const(slice)) {
					unsigned indices[1] = {len_index};
					count.value = llvm_const_extract_value(p->module, slice.value, indices, gb_count_of(indices));
				} else {
					count.value = LLVMBuildExtractValue(p->builder, slice.value, len_index, "");
				}
				lb_fill_slice(p, v, data, count);
			}
		}
		break;
	}

	case Type_DynamicArray: {
		if (cl->elems.count == 0) {
			break;
		}
		GB_ASSERT(!build_context.no_dynamic_literals);

		Type *et = bt->DynamicArray.elem;
		lbValue size  = lb_const_int(p->module, t_int, type_size_of(et));
		lbValue align = lb_const_int(p->module, t_int, type_align_of(et));

		i64 item_count = gb_max(cl->max_count, cl->elems.count);
		{

			auto args = array_make<lbValue>(temporary_allocator(), 5);
			args[0] = lb_emit_conv(p, lb_addr_get_ptr(p, v), t_rawptr);
			args[1] = size;
			args[2] = align;
			args[3] = lb_const_int(p->module, t_int, item_count);
			args[4] = lb_emit_source_code_location_as_global(p, proc_name, pos);
			lb_emit_runtime_call(p, "__dynamic_array_reserve", args);
		}

		lbValue items = lb_generate_local_array(p, et, item_count);

		auto temp_data = array_make<lbCompoundLitElemTempData>(temporary_allocator(), 0, cl->elems.count);
		lb_build_addr_compound_lit_populate(p, cl->elems, &temp_data, type);

		for_array(i, temp_data) {
			temp_data[i].gep = lb_emit_array_epi(p, items, temp_data[i].elem_index);
		}
		lb_build_addr_compound_lit_assign_array(p, temp_data);

		{
			auto args = array_make<lbValue>(temporary_allocator(), 6);
			args[0] = lb_emit_conv(p, v.addr, t_rawptr);
			args[1] = size;
			args[2] = align;
			args[3] = lb_emit_conv(p, items, t_rawptr);
			args[4] = lb_const_int(p->module, t_int, item_count);
			args[5] = lb_emit_source_code_location_as_global(p, proc_name, pos);
			lb_emit_runtime_call(p, "__dynamic_array_append", args);
		}
		break;
	}

	case Type_Basic: {
		GB_ASSERT(is_type_any(bt));
		if (cl->elems.count > 0) {
			lb_addr_store(p, v, lb_const_value(p->module, type, exact_value_compound(expr)));
			String field_names[2] = {
				str_lit("data"),
				str_lit("id"),
			};
			Type *field_types[2] = {
				t_rawptr,
				t_typeid,
			};

			for_array(field_index, cl->elems) {
				Ast *elem = cl->elems[field_index];

				lbValue field_expr = {};
				isize index = field_index;

				if (elem->kind == Ast_FieldValue) {
					ast_node(fv, FieldValue, elem);
					Selection sel = lookup_field(bt, fv->field->Ident.token.string, false);
					index = sel.index[0];
					elem = fv->value;
				} else {
					TypeAndValue tav = type_and_value_of_expr(elem);
					Selection sel = lookup_field(bt, field_names[field_index], false);
					index = sel.index[0];
				}

				field_expr = lb_build_expr(p, elem);

				GB_ASSERT(field_expr.type->kind != Type_Tuple);

				Type *ft = field_types[index];
				lbValue fv = lb_emit_conv(p, field_expr, ft);
				lbValue gep = lb_emit_struct_ep(p, lb_addr_get_ptr(p, v), cast(i32)index);
				lb_emit_store(p, gep, fv);
			}
		}

		break;
	}

	case Type_BitSet: {
		i64 sz = type_size_of(type);
		if (cl->elems.count > 0 && sz > 0) {
			lb_addr_store(p, v, lb_const_value(p->module, type, exact_value_compound(expr)));

			lbValue lower = lb_const_value(p->module, t_int, exact_value_i64(bt->BitSet.lower));
			for (Ast *elem : cl->elems) {
				GB_ASSERT(elem->kind != Ast_FieldValue);

				if (lb_is_elem_const(elem, et)) {
					continue;
				}

				lbValue expr = lb_build_expr(p, elem);
				GB_ASSERT(expr.type->kind != Type_Tuple);

				Type *it = bit_set_to_int(bt);
				lbValue one = lb_const_value(p->module, it, exact_value_i64(1));
				lbValue e = lb_emit_conv(p, expr, it);
				e = lb_emit_arith(p, Token_Sub, e, lower, it);
				e = lb_emit_arith(p, Token_Shl, one, e, it);

				lbValue old_value = lb_emit_transmute(p, lb_addr_load(p, v), it);
				lbValue new_value = lb_emit_arith(p, Token_Or, old_value, e, it);
				new_value = lb_emit_transmute(p, new_value, type);
				lb_addr_store(p, v, new_value);
			}
		}
		break;
	}

	case Type_Matrix: {
		if (cl->elems.count > 0) {
			lb_addr_store(p, v, lb_const_value(p->module, type, exact_value_compound(expr)));

			auto temp_data = array_make<lbCompoundLitElemTempData>(temporary_allocator(), 0, cl->elems.count);

			lb_build_addr_compound_lit_populate(p, cl->elems, &temp_data, type);

			lbValue dst_ptr = lb_addr_get_ptr(p, v);
			for_array(i, temp_data) {
				temp_data[i].gep = lb_emit_array_epi(p, dst_ptr, temp_data[i].elem_index);
			}

			lb_build_addr_compound_lit_assign_array(p, temp_data);
		}
		break;
	}

	case Type_SimdVector: {
		if (cl->elems.count > 0) {
			lbValue vector_value = lb_const_value(p->module, type, exact_value_compound(expr));
			defer (lb_addr_store(p, v, vector_value));

			auto temp_data = array_make<lbCompoundLitElemTempData>(temporary_allocator(), 0, cl->elems.count);

			lb_build_addr_compound_lit_populate(p, cl->elems, &temp_data, type);

			// TODO(bill): reduce the need for individual `insertelement` if a `shufflevector`
			// might be a better option
			for (auto const &td : temp_data) {
				if (td.value.value != nullptr) {
					if (td.elem_length > 0) {
						for (i64 k = 0; k < td.elem_length; k++) {
							LLVMValueRef index = lb_const_int(p->module, t_u32, td.elem_index + k).value;
							vector_value.value = LLVMBuildInsertElement(p->builder, vector_value.value, td.value.value, index, "");
						}
					} else {
						LLVMValueRef index = lb_const_int(p->module, t_u32, td.elem_index).value;
						vector_value.value = LLVMBuildInsertElement(p->builder, vector_value.value, td.value.value, index, "");

					}
				}
			}
		}
		break;
	}
	}

	return v;
}


gb_internal lbAddr lb_build_addr_internal(lbProcedure *p, Ast *expr) {
	switch (expr->kind) {
	case_ast_node(i, Implicit, expr);
		lbAddr v = {};
		switch (i->kind) {
		case Token_context:
			v = lb_find_or_generate_context_ptr(p);
			break;
		}

		GB_ASSERT(v.addr.value != nullptr);
		return v;
	case_end;

	case_ast_node(i, Ident, expr);
		if (is_blank_ident(expr)) {
			lbAddr val = {};
			return val;
		}
		String name = i->token.string;
		Entity *e = entity_of_node(expr);
		return lb_build_addr_from_entity(p, e, expr);
	case_end;

	case_ast_node(se, SelectorExpr, expr);
		Ast *sel_node = unparen_expr(se->selector);
		if (sel_node->kind == Ast_Ident) {
			String selector = sel_node->Ident.token.string;
			TypeAndValue tav = type_and_value_of_expr(se->expr);

			if (tav.mode == Addressing_Invalid) {
				// NOTE(bill): Imports
				Entity *imp = entity_of_node(se->expr);
				if (imp != nullptr) {
					GB_ASSERT(imp->kind == Entity_ImportName);
				}
				return lb_build_addr(p, unparen_expr(se->selector));
			}


			Type *type = base_type(tav.type);
			if (tav.mode == Addressing_Type) { // Addressing_Type
				Selection sel = lookup_field(tav.type, selector, true);
				if (sel.pseudo_field) {
					GB_ASSERT(sel.entity->kind == Entity_Procedure);
					return lb_addr(lb_find_value_from_entity(p->module, sel.entity));
				}
				GB_PANIC("Unreachable %.*s", LIT(selector));
			}

			if (se->swizzle_count > 0) {
				Type *array_type = base_type(type_deref(tav.type));
				GB_ASSERT(array_type->kind == Type_Array);
				u8 swizzle_count = se->swizzle_count;
				u8 swizzle_indices_raw = se->swizzle_indices;
				u8 swizzle_indices[4] = {};
				for (u8 i = 0; i < swizzle_count; i++) {
					u8 index = swizzle_indices_raw>>(i*2) & 3;
					swizzle_indices[i] = index;
				}
				lbValue a = {};
				if (is_type_pointer(tav.type)) {
					a = lb_build_expr(p, se->expr);
				} else {
					lbAddr addr = lb_build_addr(p, se->expr);
					a = lb_addr_get_ptr(p, addr);
				}

				GB_ASSERT(is_type_array(expr->tav.type));
				return lb_addr_swizzle(a, expr->tav.type, swizzle_count, swizzle_indices);
			}

			Selection sel = lookup_field(type, selector, false);
			GB_ASSERT(sel.entity != nullptr);
			if (sel.pseudo_field) {
				GB_ASSERT(sel.entity->kind == Entity_Procedure || sel.entity->kind == Entity_ProcGroup);
				Entity *e = entity_of_node(sel_node);
				GB_ASSERT(e->kind == Entity_Procedure);
				return lb_addr(lb_find_value_from_entity(p->module, e));
			}

			if (sel.is_bit_field) {
				lbAddr addr = lb_build_addr(p, se->expr);

				Selection sub_sel = sel;
				sub_sel.index.count -= 1;

				lbValue ptr = lb_addr_get_ptr(p, addr);
				if (sub_sel.index.count > 0) {
					ptr = lb_emit_deep_field_gep(p, ptr, sub_sel);
				}

				Type *bf_type = type_deref(ptr.type);
				bf_type = base_type(type_deref(bf_type));
				GB_ASSERT(bf_type->kind == Type_BitField);

				i32 index = sel.index[sel.index.count-1];

				Entity *f = bf_type->BitField.fields[index];
				u8 bit_size = bf_type->BitField.bit_sizes[index];
				i64 bit_offset = bf_type->BitField.bit_offsets[index];

				return lb_addr_bit_field(ptr, f->type, index, bit_offset, bit_size);
			}

			{
				lbAddr addr = lb_build_addr(p, se->expr);
				if (addr.kind == lbAddr_Map) {
					lbValue v = lb_addr_load(p, addr);
					lbValue a = lb_address_from_load_or_generate_local(p, v);
					a = lb_emit_deep_field_gep(p, a, sel);
					return lb_addr(a);
				} else if (addr.kind == lbAddr_Context) {
					GB_ASSERT(sel.index.count > 0);
					if (addr.ctx.sel.index.count >= 0) {
						sel = selection_combine(addr.ctx.sel, sel);
					}
					addr.ctx.sel = sel;
					addr.kind = lbAddr_Context;
					return addr;
				} else if (addr.kind == lbAddr_SoaVariable) {
					lbValue index = addr.soa.index;
					i32 first_index = sel.index[0];
					Selection sub_sel = sel;
					sub_sel.index.data += 1;
					sub_sel.index.count -= 1;

					lbValue arr = lb_emit_struct_ep(p, addr.addr, first_index);

					Type *t = base_type(type_deref(addr.addr.type));
					GB_ASSERT(is_type_soa_struct(t));

					if (addr.soa.index_expr != nullptr && (!lb_is_const(addr.soa.index) || t->Struct.soa_kind != StructSoa_Fixed)) {
						lbValue len = lb_soa_struct_len(p, addr.addr);
						lb_emit_bounds_check(p, ast_token(addr.soa.index_expr), addr.soa.index, len);
					}

					lbValue item = {};

					if (t->Struct.soa_kind == StructSoa_Fixed) {
						item = lb_emit_array_ep(p, arr, index);
					} else {
						item = lb_emit_ptr_offset(p, lb_emit_load(p, arr), index);
					}
					if (sub_sel.index.count > 0) {
						item = lb_emit_deep_field_gep(p, item, sub_sel);
					}
					return lb_addr(item);
				} else if (addr.kind == lbAddr_Swizzle) {
					GB_ASSERT(sel.index.count > 0);
					// NOTE(bill): just patch the index in place
					sel.index[0] = addr.swizzle.indices[sel.index[0]];
				} else if (addr.kind == lbAddr_SwizzleLarge) {
					GB_ASSERT(sel.index.count > 0);
					// NOTE(bill): just patch the index in place
					sel.index[0] = addr.swizzle.indices[sel.index[0]];
				}

				lbValue a = lb_addr_get_ptr(p, addr);
				a = lb_emit_deep_field_gep(p, a, sel);
				return lb_addr(a);
			}
		} else {
			GB_PANIC("Unsupported selector expression");
		}
	case_end;

	case_ast_node(se, SelectorCallExpr, expr);
		lbValue e = lb_build_expr(p, expr);
		return lb_addr(lb_address_from_load_or_generate_local(p, e));
	case_end;

	case_ast_node(ta, TypeAssertion, expr);
		TokenPos pos = ast_token(expr).pos;
		lbValue e = lb_build_expr(p, ta->expr);
		Type *t = type_deref(e.type);
		if (is_type_union(t)) {
			Type *type = type_of_expr(expr);
			lbAddr v = lb_add_local_generated(p, type, false);
			lb_addr_store(p, v, lb_emit_union_cast(p, lb_build_expr(p, ta->expr), type, pos));
			return v;
		} else if (is_type_any(t)) {
			Type *type = type_of_expr(expr);
			return lb_emit_any_cast_addr(p, lb_build_expr(p, ta->expr), type, pos);
		} else {
			GB_PANIC("TODO(bill): type assertion %s", type_to_string(e.type));
		}
	case_end;

	case_ast_node(ue, UnaryExpr, expr);
		switch (ue->op.kind) {
		case Token_And: {
			lbValue ptr = lb_build_expr(p, expr);
			return lb_addr(lb_address_from_load_or_generate_local(p, ptr));
		}
		default:
			GB_PANIC("Invalid unary expression for lb_build_addr");
		}
	case_end;
	case_ast_node(be, BinaryExpr, expr);
		lbValue v = lb_build_expr(p, expr);
		Type *t = v.type;
		if (is_type_pointer(t)) {
			return lb_addr(v);
		}
		return lb_addr(lb_address_from_load_or_generate_local(p, v));
	case_end;

	case_ast_node(ie, IndexExpr, expr);
		return lb_build_addr_index_expr(p, expr);
	case_end;

	case_ast_node(ie, MatrixIndexExpr, expr);
		Type *t = base_type(type_of_expr(ie->expr));

		bool deref = is_type_pointer(t);
		t = base_type(type_deref(t));

		lbValue m = {};
		m = lb_build_addr_ptr(p, ie->expr);
		if (deref) {
			m = lb_emit_load(p, m);
		}
		lbValue row_index = lb_build_expr(p, ie->row_index);
		lbValue column_index = lb_build_expr(p, ie->column_index);
		row_index = lb_emit_conv(p, row_index, t_int);
		column_index = lb_emit_conv(p, column_index, t_int);
		lbValue elem = lb_emit_matrix_ep(p, m, row_index, column_index);

		auto row_index_tv = type_and_value_of_expr(ie->row_index);
		auto column_index_tv = type_and_value_of_expr(ie->column_index);
		if (row_index_tv.mode != Addressing_Constant || column_index_tv.mode != Addressing_Constant) {
			lbValue row_count = lb_const_int(p->module, t_int, t->Matrix.row_count);
			lbValue column_count = lb_const_int(p->module, t_int, t->Matrix.column_count);
			lb_emit_matrix_bounds_check(p, ast_token(ie->row_index), row_index, column_index, row_count, column_count);
		}
		return lb_addr(elem);


	case_end;

	case_ast_node(se, SliceExpr, expr);
		return lb_build_addr_slice_expr(p, expr);
	case_end;

	case_ast_node(de, DerefExpr, expr);
		Type *t = type_of_expr(de->expr);
		if (is_type_relative_pointer(t)) {
			lbAddr addr = lb_build_addr(p, de->expr);
			addr.relative.deref = true;
			return addr;
		} else if (is_type_soa_pointer(t)) {
			lbValue value = lb_build_expr(p, de->expr);
			lbValue ptr = lb_emit_struct_ev(p, value, 0);
			lbValue idx = lb_emit_struct_ev(p, value, 1);
			return lb_addr_soa_variable(ptr, idx, nullptr);
		}
		lbValue addr = lb_build_expr(p, de->expr);
		return lb_addr(addr);
	case_end;

	case_ast_node(ce, CallExpr, expr);
		BuiltinProcId builtin_id = BuiltinProc_Invalid;
		if (ce->proc->tav.mode == Addressing_Builtin) {
			Entity *e = entity_of_node(ce->proc);
			if (e != nullptr) {
				builtin_id = cast(BuiltinProcId)e->Builtin.id;
			} else {
				builtin_id = BuiltinProc_DIRECTIVE;
			}
		}
		auto const &tv = expr->tav;
		if (builtin_id == BuiltinProc_swizzle &&
		    is_type_array(tv.type)) {
		    	// NOTE(bill, 2021-08-09): `swizzle` has some bizarre semantics so it needs to be
		    	// specialized here for to be addressable
			return lb_build_array_swizzle_addr(p, ce, tv);
		}

		// NOTE(bill): This is make sure you never need to have an 'array_ev'
		lbValue e = lb_build_expr(p, expr);
	#if 1
		return lb_addr(lb_address_from_load_or_generate_local(p, e));
	#else
		lbAddr v = lb_add_local_generated(p, e.type, false);
		lb_addr_store(p, v, e);
		return v;
	#endif
	case_end;

	case_ast_node(cl, CompoundLit, expr);
		return lb_build_addr_compound_lit(p, expr);
	case_end;

	case_ast_node(tc, TypeCast, expr);
		Type *type = type_of_expr(expr);
		lbValue x = lb_build_expr(p, tc->expr);
		lbValue e = {};
		switch (tc->token.kind) {
		case Token_cast:
			e = lb_emit_conv(p, x, type);
			break;
		case Token_transmute:
			e = lb_emit_transmute(p, x, type);
			break;
		default:
			GB_PANIC("Invalid AST TypeCast");
		}
		lbAddr v = lb_add_local_generated(p, type, false);
		lb_addr_store(p, v, e);
		return v;
	case_end;

	case_ast_node(ac, AutoCast, expr);
		return lb_build_addr(p, ac->expr);
	case_end;
	
	case_ast_node(te, TernaryIfExpr, expr);
		LLVMValueRef incoming_values[2] = {};
		LLVMBasicBlockRef incoming_blocks[2] = {};

		GB_ASSERT(te->y != nullptr);
		lbBlock *then  = lb_create_block(p, "if.then");
		lbBlock *done  = lb_create_block(p, "if.done"); // NOTE(bill): Append later
		lbBlock *else_ = lb_create_block(p, "if.else");

		lb_build_cond(p, te->cond, then, else_);
		lb_start_block(p, then);

		Type *ptr_type = alloc_type_pointer(default_type(type_of_expr(expr)));

		incoming_values[0] = lb_emit_conv(p, lb_build_addr_ptr(p, te->x), ptr_type).value;

		lb_emit_jump(p, done);
		lb_start_block(p, else_);

		incoming_values[1] = lb_emit_conv(p, lb_build_addr_ptr(p, te->y), ptr_type).value;

		lb_emit_jump(p, done);
		lb_start_block(p, done);

		lbValue res = {};
		res.value = LLVMBuildPhi(p->builder, lb_type(p->module, ptr_type), "");
		res.type = ptr_type;

		GB_ASSERT(p->curr_block->preds.count >= 2);
		incoming_blocks[0] = p->curr_block->preds[0]->block;
		incoming_blocks[1] = p->curr_block->preds[1]->block;

		LLVMAddIncoming(res.value, incoming_values, incoming_blocks, 2);

		return lb_addr(res);
	case_end;
	
	case_ast_node(oe, OrElseExpr, expr);
		lbValue ptr = lb_address_from_load_or_generate_local(p, lb_build_expr(p, expr));
		return lb_addr(ptr);
	case_end;
	
	case_ast_node(oe, OrReturnExpr, expr);
		lbValue ptr = lb_address_from_load_or_generate_local(p, lb_build_expr(p, expr));
		return lb_addr(ptr);
	case_end;
	}

	TokenPos token_pos = ast_token(expr).pos;
	GB_PANIC("Unexpected address expression\n"
	         "\tAst: %.*s @ "
	         "%s\n",
	         LIT(ast_strings[expr->kind]),
	         token_pos_to_string(token_pos));


	return {};
}


