// Frontend: calls, procedure bodies and statements

gb_internal xbAbiFunc *xb_get_abi(xbProc *p, Type *proc_type) {
	Type *pt = base_type(proc_type);
	xbAbiFunc **found = map_get(&p->m->abi_cache, pt);
	if (found) {
		if (*found == nullptr) XB_UNSUPPORTED(p, "abi");
		return *found;
	}
	char const *reason = nullptr;
	xbAbiFunc *f = xb_abi_compute(pt, &reason);
	map_set(&p->m->abi_cache, pt, f);
	if (f == nullptr) {
		XB_UNSUPPORTED(p, reason ? reason : "abi");
	}
	return f;
}

gb_internal void xb_set_debug_loc(xbProc *p, TokenPos pos) {
	if (pos.line <= 0 || pos.file_id <= 0) return;
	i32 file_id = xb_file_id(p->m, pos.file_id);
	if (pos.line == p->last_line && file_id == p->file_id) return;
	p->last_line = pos.line;
	p->last_column = pos.column;
	p->file_id = file_id;
	xbInstr i = xb_instr(xbOp_Loc);
	i.imm = pos.line;
	i.a = cast(u32)file_id;
	i.b = cast(u32)pos.column;
	xb_emit(p, i);
}

// The closing brace of a body, which LLVM gives the jump out of it so a debugger stops there
gb_internal void xb_set_debug_end_loc(xbProc *p, Ast *node) {
	if (node != nullptr && !xb_curr_terminated(p)) xb_set_debug_loc(p, ast_end_token(node).pos);
}

////////////////////////////////////////////////////////////////
// Calls
////////////////////////////////////////////////////////////////

// The address of a value passed by pointer under the Odin convention, which may
// alias the original since parameters are immutable.
gb_internal u32 xb_arg_address(xbProc *p, xbValue v, bool may_alias) {
	if (may_alias) {
		xbMem m = xb_address_from_load_or_generate_local(p, v);
		// the callee assumes the pointer is aligned for the type, a packed field is copied
		if (m.align == 0 || m.align >= type_align_of(v.type)) {
			return xb_lea(p, m);
		}
	}
	xbMem m = xb_add_local(p, v.type, false);
	xb_store_value(p, m, v);
	return xb_lea(p, m);
}

gb_internal void xb_add_piece_arg(xbProc *p, Array<xbCallArg> *out, xbAbiPiece const &piece, xbValue v, Type *type) {
	xbCallArg a = {};
	a.type = piece.type;
	a.size = piece.size;
	a.ext = piece.ext;
	xbType st = xb_scalar_type(type);
	bool whole_scalar = v.kind == xbValue_Reg && piece.src_offset == 0 && st != xbType_None &&
	                    xb_type_size(st) == piece.size && xb_type_is_float(st) == (piece.loc == xbLoc_Xmm || (piece.loc == xbLoc_Stack && xb_type_is_float(piece.type)));
	if (whole_scalar) {
		a.vreg = v.reg;
		a.type = st;
		if (xb_type_is_int(st) && xb_type_size(st) < 4) {
			a.ext = xb_type_is_signed(type) ? xbExt_Sign : xbExt_Zero;
		}
		switch (piece.loc) {
		case xbLoc_Gpr:   a.kind = xbCallArg_Gpr; a.reg = piece.reg; break;
		case xbLoc_Xmm:   a.kind = xbCallArg_Xmm; a.reg = piece.reg; break;
		case xbLoc_Stack: a.kind = xbCallArg_Stack; a.stack_offset = piece.stack_offset; break;
		}
	} else {
		xbMem m = xb_value_to_mem(p, v);
		a.mem = xb_mem_offset(m, piece.src_offset);
		switch (piece.loc) {
		case xbLoc_Gpr:   a.kind = xbCallArg_GprMem; a.reg = piece.reg; break;
		case xbLoc_Xmm:   a.kind = xbCallArg_XmmMem; a.reg = piece.reg; break;
		case xbLoc_Stack: a.kind = xbCallArg_StackMem; a.stack_offset = piece.stack_offset; break;
		}
	}
	array_add(out, a);
}

gb_internal void xb_add_ptr_arg(xbProc *p, Array<xbCallArg> *out, xbAbiFunc *abi, xbAbiArg const &arg, u32 ptr, i32 part=0) {
	GB_ASSERT(part < arg.piece_count);
	xbAbiPiece const &piece = abi->pieces[arg.piece_index+part];
	xbCallArg a = {};
	a.type = xbType_I64;
	a.size = 8;
	a.vreg = ptr;
	if (piece.loc == xbLoc_Gpr) {
		a.kind = xbCallArg_Gpr;
		a.reg = piece.reg;
	} else {
		a.kind = xbCallArg_Stack;
		a.stack_offset = piece.stack_offset;
	}
	array_add(out, a);
}

// The lanes of a short integer vector returned in d0, each in the low bytes of its widened lane,
// see xbAbiFunc::ret_lane_size
gb_internal void xb_narrow_ret_lanes(xbProc *p, xbAbiFunc *abi, xbMem dst, xbMem wide) {
	if (abi->ret_lane_count == 0) return;
	xbType lane_type = a64_int_piece_type(abi->ret_lane_size);
	i32 wide_size = 8 / abi->ret_lane_count;
	for (i32 i = 0; i < abi->ret_lane_count; i++) {
		u32 lane = xb_load(p, lane_type, xb_mem_offset(wide, i*wide_size));
		xb_store(p, lane_type, xb_mem_offset(dst, i*abi->ret_lane_size), lane);
	}
}

// Calls `proc` with arguments already converted to the parameter types. For C varargs,
// the extra arguments follow.
gb_internal xbValue xb_emit_call_internal(xbProc *p, xbValue proc, i32 direct_sym, Slice<xbValue> args) {
	Type *pt = base_type(proc.type);
	GB_ASSERT(pt->kind == Type_Proc);
	xbAbiFunc *abi = xb_get_abi(p, pt);

	auto call_args = array_make<xbCallArg>(xb_allocator(), 0, args.count+4);
	auto call_rets = array_make<xbCallRet>(xb_allocator(), 0, 2);

	Type *results = pt->Proc.results;
	Type *rt = reduce_tuple_to_single_type(results);
	xbMem result_mem = {};
	Type *result_type = nullptr;
	if (rt != nullptr) {
		result_type = rt;
		result_mem = xb_add_local(p, rt, abi->split_returns);
	}
	xbMem last_mem = result_mem;
	if (abi->split_returns) {
		Type *tuple = rt;
		isize n = tuple->Tuple.variables.count;
		Type *ft = nullptr;
		i64 off = type_offset_of(tuple, n-1, &ft);
		last_mem = xb_mem_offset(result_mem, off);
	}

	if (abi->has_sret) {
		xb_add_ptr_arg(p, &call_args, abi, abi->sret, xb_lea(p, last_mem));
	}

	isize arg_index = 0;
	isize param_index = 0;
	if (pt->Proc.param_count != 0) {
		for (Entity *e : pt->Proc.params->Tuple.variables) {
			if (e->kind != Entity_Variable) continue;
			if (e->flags & EntityFlag_CVarArg) continue;
			GB_ASSERT(arg_index < args.count);
			xbValue v = args[arg_index++];
			xbAbiArg const &arg = abi->params[param_index++];
			switch (arg.kind) {
			case xbArg_Ignore:
				break;
			case xbArg_Direct:
				for (i32 i = 0; i < arg.piece_count; i++) {
					xb_add_piece_arg(p, &call_args, abi->pieces[arg.piece_index+i], v, e->type);
				}
				break;
			case xbArg_Indirect: {
				if (arg.copy_part > 0) {
					i32 l = xb_add_local_raw(p, arg.copy_part*arg.piece_count, arg.copy_part);
					xbMem m = xb_mem(xbMem_Local, cast(u32)l);
					xb_store_value(p, m, v);
					for (i32 i = 0; i < arg.piece_count; i++) {
						xb_add_ptr_arg(p, &call_args, abi, arg, xb_lea(p, xb_mem_offset(m, i*arg.copy_part)), i);
					}
					break;
				}
				u32 ptr = xb_arg_address(p, v, is_calling_convention_odin(abi->cc) && !arg.copy);
				xb_add_ptr_arg(p, &call_args, abi, arg, ptr);
				break;
			}
			case xbArg_ByVal: {
				xbCallArg a = {};
				a.kind = xbCallArg_StackMem;
				a.mem = xb_value_to_mem(p, v);
				a.size = arg.byval_size;
				a.stack_offset = arg.stack_offset;
				array_add(&call_args, a);
				break;
			}
			}
		}
	}

	if (abi->split_returns) {
		Type *tuple = rt;
		for_array(i, abi->split_ret_ptrs) {
			Type *ft = nullptr;
			i64 off = type_offset_of(tuple, i, &ft);
			xb_add_ptr_arg(p, &call_args, abi, abi->split_ret_ptrs[i], xb_lea(p, xb_mem_offset(result_mem, off)));
		}
	}

	if (abi->is_odin_cc) {
		xb_add_ptr_arg(p, &call_args, abi, abi->context, xb_context_ptr(p));
	}

	i32 stack_size = abi->stack_size;
	i32 sse_count = -1;
	if (abi->c_vararg && xb_is_win64() && abi->cc != ProcCC_SysV) {
		stack_size = xb_win64_varargs(p, abi, &call_args, args, arg_index);
	} else if (abi->c_vararg && xb_is_arm64()) {
		stack_size = a64_varargs(p, abi, &call_args, args, arg_index);
	} else if (abi->c_vararg) {
		i32 gpr = abi->gpr_count;
		i32 xmm = abi->xmm_count;
		i32 stack = abi->stack_size;
		for (; arg_index < args.count; arg_index++) {
			xbValue v = args[arg_index];
			xbType st = xb_scalar_type(v.type);
			if (st == xbType_None) XB_UNSUPPORTED(p, "aggregate c vararg");
			xbCallArg a = {};
			a.type = st;
			a.size = xb_type_size(st);
			a.vreg = xb_value_to_reg(p, v);
			if (xb_type_is_int(st) && xb_type_size(st) < 4) {
				a.ext = xb_type_is_signed(v.type) ? xbExt_Sign : xbExt_Zero;
			}
			if (xb_type_is_float(st)) {
				if (st == xbType_F32) {
					a.vreg = xb_convop(p, xbOp_FExt, xbType_F64, xbType_F32, a.vreg);
					a.type = xbType_F64;
					a.size = 8;
				}
				if (xmm < 8) {
					a.kind = xbCallArg_Xmm;
					a.reg = cast(u8)xmm++;
				} else {
					a.kind = xbCallArg_Stack;
					a.stack_offset = stack;
					stack += 8;
				}
			} else {
				if (gpr < 6) {
					a.kind = xbCallArg_Gpr;
					a.reg = xb_sysv_int_regs[gpr++];
				} else {
					a.kind = xbCallArg_Stack;
					a.stack_offset = stack;
					stack += 8;
				}
			}
			array_add(&call_args, a);
		}
		stack_size = stack;
		sse_count = xmm;
	}

	xbMem llvm_layout = {};
	if (abi->ret_tuple_offsets.count > 0 || abi->ret_lane_count > 0) {
		llvm_layout = xb_mem(xbMem_Local, cast(u32)xb_add_local_raw(p, 16, 8));
	}
	if (abi->ret.kind == xbArg_Direct) {
		for (i32 i = 0; i < abi->ret.piece_count; i++) {
			xbAbiPiece const &piece = abi->pieces[abi->ret.piece_index+i];
			xbCallRet r = {};
			r.loc = piece.loc;
			r.reg = piece.reg;
			r.type = piece.type;
			r.size = piece.size;
			r.dst = xb_mem_offset(abi->ret_tuple_offsets.count > 0 || abi->ret_lane_count > 0 ? llvm_layout : last_mem, piece.src_offset);
			array_add(&call_rets, r);
		}
	}

	xbCall call = {};
	call.target_sym = direct_sym;
	call.target_vreg = 0;
	if (direct_sym < 0) {
		call.target_vreg = xb_value_to_reg(p, proc);
	}
	call.args = slice_from_array(call_args);
	call.rets = slice_from_array(call_rets);
	call.stack_size = stack_size;
	call.sse_count = sse_count;
	array_add(&p->calls, call);

	xbInstr i = xb_instr(xbOp_Call);
	i.imm = p->calls.count-1;
	xb_emit(p, i);

	for_array(i, abi->ret_tuple_offsets) {
		Type *ft = nullptr;
		i64 off = type_offset_of(rt, cast(i32)i, &ft);
		xb_memcopy(p, xb_mem_offset(result_mem, off), xb_mem_offset(llvm_layout, abi->ret_tuple_offsets[i]), type_size_of(ft));
	}
	xb_narrow_ret_lanes(p, abi, last_mem, llvm_layout);

	if (pt->Proc.diverging) {
		xb_unreachable(p);
	}

	if (result_type == nullptr) {
		xbValue v = {};
		return v;
	}
	return xb_load_value(p, result_type, result_mem);
}

gb_internal i32 xb_direct_symbol_of(xbProc *p, Ast *proc_expr, xbValue *proc_value) {
	Entity *e = entity_of_node(proc_expr);
	if (e != nullptr && e->kind == Entity_Procedure) {
		*proc_value = xb_proc_value_from_entity(p, e);
		return xb_entity_symbol(p, e);
	}
	return -1;
}

gb_internal xbValue xb_emit_call(xbProc *p, xbValue proc, Slice<xbValue> args, Ast *call_expr) {
	i32 sym = -1;
	// direct calls when the value is the address of a symbol
	if (proc.kind == xbValue_Reg && p->curr) {
		// find the defining instruction in the current block
		for (isize i = p->curr->instrs.count-1; i >= 0; i--) {
			xbInstr const &in = p->curr->instrs[i];
			if (in.dst == proc.reg && in.op == xbOp_Lea) {
				if (in.mem.kind == xbMem_Sym && in.mem.offset == 0) {
					sym = cast(i32)in.mem.base;
				}
				break;
			}
		}
	}
	return xb_emit_call_internal(p, proc, sym, args);
}

gb_internal void xb_add_values_to_array(xbProc *p, Array<xbValue> *out, xbValue v) {
	if (is_type_tuple(v.type)) {
		GB_ASSERT(v.kind == xbValue_Mem);
		for_array(i, v.type->Tuple.variables) {
			Type *ft = nullptr;
			i64 off = type_offset_of(v.type, i, &ft);
			array_add(out, xb_load_value(p, ft, xb_mem_offset(v.mem, off)));
		}
	} else {
		array_add(out, v);
	}
}

gb_internal xbValue xb_build_variadic_slice(xbProc *p, Type *slice_type, Slice<xbValue> var_args) {
	GB_ASSERT(is_type_slice(slice_type));
	if (var_args.count == 0) {
		return xb_zero_value(p, slice_type);
	}
	Type *elem = base_type(slice_type)->Slice.elem;
	i64 stride = type_size_of(elem);
	Type *arr = alloc_type_array(elem, var_args.count);
	xbMem m = xb_add_local(p, arr, false);
	for_array(i, var_args) {
		xb_store_value(p, xb_mem_offset(m, i*stride), xb_emit_conv(p, var_args[i], elem));
	}
	return xb_make_slice_value(p, slice_type, xb_lea(p, m), xb_iconst(p, xbType_I64, var_args.count));
}

gb_internal xbValue xb_source_code_location(xbProc *p, String proc_name, TokenPos pos) {
	// {file_path: string, line, column: i32, procedure: string}
	xbValue flc[3] = {};
	xb_file_line_col(p, pos, flc);
	Type *t = t_source_code_location;
	xbMem m = xb_add_local(p, t, true);
	Type *bt = base_type(t);
	Type *ft = nullptr;
	xb_store_value(p, xb_mem_offset(m, type_offset_of(bt, 0, &ft)), flc[0]);
	xb_store_value(p, xb_mem_offset(m, type_offset_of(bt, 1, &ft)), flc[1]);
	xb_store_value(p, xb_mem_offset(m, type_offset_of(bt, 2, &ft)), flc[2]);
	if (build_context.source_code_location_info == SourceCodeLocationInfo_Obfuscated) {
		proc_name = obfuscate_string(proc_name, "P");
	} else if (build_context.source_code_location_info == SourceCodeLocationInfo_None) {
		proc_name = str_lit("");
	}
	xb_store_value(p, xb_mem_offset(m, type_offset_of(bt, 3, &ft)), xb_const_string(p, proc_name, t_string));
	return xb_value_mem(t, m);
}

gb_internal xbValue xb_handle_param_value(xbProc *p, Type *parameter_type, ParameterValue const &param_value, TypeProc *procedure_type, Ast *call_expression) {
	switch (param_value.kind) {
	case ParameterValue_Constant:
		if (param_value.proc_entity != nullptr && is_type_proc(parameter_type)) {
			return xb_emit_conv(p, xb_proc_value_from_entity(p, param_value.proc_entity), parameter_type);
		}
		if (is_type_constant_type(parameter_type)) {
			return xb_const_value(p, parameter_type, param_value.value);
		} else {
			Type *type = type_of_expr(param_value.original_ast_expr);
			xbValue arg = {};
			if (type != nullptr) {
				arg = xb_const_value(p, type, param_value.value);
			} else {
				arg = xb_const_value(p, parameter_type, param_value.value);
			}
			return xb_emit_conv(p, arg, parameter_type);
		}
	case ParameterValue_Nil:
		return xb_zero_value(p, parameter_type);
	case ParameterValue_Location: {
		String proc_name = {};
		if (p->entity != nullptr) {
			proc_name = p->entity->token.string;
		}
		ast_node(ce, CallExpr, call_expression);
		TokenPos pos = ast_token(ce->proc).pos;
		return xb_source_code_location(p, proc_name, pos);
	}
	case ParameterValue_Expression: {
		Ast *orig = param_value.original_ast_expr;
		if (orig->kind == Ast_BasicDirective) {
			gbString expr = expr_to_string(call_expression, permanent_allocator());
			return xb_const_string(p, make_string_c(expr), t_string);
		}
		isize param_idx = -1;
		String param_str = {};
		{
			Ast *call = unparen_expr(orig);
			GB_ASSERT(call->kind == Ast_CallExpr);
			ast_node(ce, CallExpr, call);
			Ast *target = ce->args[0];
			param_str = target->Ident.token.string;
			param_idx = lookup_procedure_parameter(procedure_type, param_str);
		}
		Ast *target_expr = nullptr;
		ast_node(ce, CallExpr, call_expression);
		if (ce->split_args->positional.count > param_idx) {
			target_expr = ce->split_args->positional[param_idx];
		}
		for (Ast *arg : ce->split_args->named) {
			ast_node(fv, FieldValue, arg);
			if (fv->field->Ident.token.string == param_str) {
				target_expr = fv->value;
				break;
			}
		}
		gbString expr = expr_to_string(target_expr, permanent_allocator());
		return xb_const_string(p, make_string_c(expr), t_string);
	}
	case ParameterValue_Value:
		return xb_build_expr(p, param_value.ast_value);
	}
	return xb_zero_value(p, parameter_type);
}

// Calls to LLVM intrinsics declared as foreign procedures. At -O0 LLVM turns the libm
// ones into plain calls to the C library, and so does this.
// x86 vector intrinsics with no portable form run as the instruction itself, as LLVM does
gb_internal xbValue xb_emit_vec128(xbProc *p, i32 index, u32 a, u32 b, u32 c, u8 imm, Type *result_type) {
	xbInstr in = xb_instr(xbOp_Vec128);
	in.aux = cast(u8)index;
	in.a = a;
	in.b = b;
	in.c = c;
	in.imm = imm;
	in.mem = xb_add_local(p, result_type, false);
	xb_emit(p, in);
	return xb_value_mem(result_type, in.mem);
}

gb_internal bool xb_build_x86_vec_intrinsic(xbProc *p, String name, AstCallExpr *ce, Type *result_type, xbValue *res) {
	if (xb_is_arm64()) return false;
	i32 index = xb_vec_intrinsic_index(name);
	if (index < 0) return false;
	xbVecIntrinsic const &v = xb_vec_intrinsics[index];
	isize vec_args = 2;
	switch (v.form) {
	case xbVecForm_Unary:    vec_args = 1; break;
	case xbVecForm_ShiftImm: vec_args = 1; break;
	case xbVecForm_Xmm0:     vec_args = 3; break;
	case xbVecForm_Binary:   vec_args = 2; break;
	case xbVecForm_ToGpr:    vec_args = 1; break;
	case xbVecForm_Flags:    vec_args = 2; break;
	}
	bool scalar_result = v.form == xbVecForm_ToGpr || v.form == xbVecForm_Flags;
	i64 result_size = type_size_of(result_type);
	if (scalar_result ? (result_size != 4 && result_size != 8) : result_size != 16) XB_UNSUPPORTED(p, "llvm intrinsic");
	if (ce->args.count != vec_args + (v.imm ? 1 : 0)) XB_UNSUPPORTED(p, "llvm intrinsic");

	u32 ptrs[3] = {};
	for (isize i = 0; i < vec_args; i++) {
		xbValue x = xb_build_expr(p, ce->args[i]);
		if (type_size_of(x.type) != 16) XB_UNSUPPORTED(p, "llvm intrinsic");
		ptrs[i] = xb_lea(p, xb_address_from_load_or_generate_local(p, x));
	}
	if (vec_args == 1) ptrs[1] = ptrs[0];
	u8 imm = 0;
	if (v.imm) {
		TypeAndValue tv = type_and_value_of_expr(ce->args[vec_args]);
		if (tv.value.kind != ExactValue_Integer) XB_UNSUPPORTED(p, "llvm intrinsic");
		i64 k = exact_value_to_i64(tv.value);
		if (v.form == xbVecForm_ShiftImm) {
			// every count past the element width gives the same result
			k = gb_clamp(k, 0, 255);
		} else if (v.opcode == 0xC2 && (k < 0 || k > 7)) {
			// the predicates past 7 only exist in the VEX encoding
			XB_UNSUPPORTED(p, "llvm intrinsic");
		}
		imm = cast(u8)k;
	}
	*res = xb_emit_vec128(p, index, ptrs[0], ptrs[1], ptrs[2], imm, result_type);
	if (scalar_result) {
		*res = xb_value_reg(result_type, xb_load(p, xb_scalar_type(result_type), res->mem));
	}
	return true;
}

// The arm64 crypto intrinsics, on 16 byte operands in memory; a scalar operand or result
// is the low lane.
gb_internal bool xb_build_a64_vec_intrinsic(xbProc *p, String name, AstCallExpr *ce, Type *result_type, xbValue *res) {
	if (!xb_is_arm64()) return false;
	isize args = 0;
	i32 index = a64_vec_intrinsic_index(name, &args);
	if (index < 0) return false;
	if (ce->args.count != args) XB_UNSUPPORTED(p, "llvm intrinsic");
	u32 ptrs[3] = {};
	for (isize i = 0; i < args; i++) {
		xbValue x = xb_build_expr(p, ce->args[i]);
		i64 size = type_size_of(x.type);
		if (size == 16) {
			ptrs[i] = xb_lea(p, xb_address_from_load_or_generate_local(p, x));
		} else if (size == 4 && xb_is_scalar(x.type)) {
			xbMem m = xb_mem(xbMem_Local, cast(u32)xb_add_local_raw(p, 16, 16));
			xb_store_value(p, m, x);
			ptrs[i] = xb_lea(p, m);
		} else {
			XB_UNSUPPORTED(p, "llvm intrinsic");
		}
	}
	i64 result_size = type_size_of(result_type);
	if (result_size != 16 && result_size != 4) XB_UNSUPPORTED(p, "llvm intrinsic");
	xbInstr in = xb_instr(xbOp_Vec128);
	in.aux = cast(u8)index;
	in.a = ptrs[0];
	in.b = args > 1 ? ptrs[1] : ptrs[0];
	in.c = args > 2 ? ptrs[2] : 0;
	in.mem = xb_mem(xbMem_Local, cast(u32)xb_add_local_raw(p, 16, 16));
	xb_emit(p, in);
	*res = xb_load_value(p, result_type, in.mem);
	return true;
}

gb_internal xbValue xb_build_llvm_intrinsic_call(xbProc *p, Entity *e, AstCallExpr *ce, Type *result_type) {
	String name = e->Procedure.link_name;
	Type *pt = base_type(e->type);
	isize n = pt->Proc.param_count;
	xbValue vec_res = {};
	if (xb_build_x86_vec_intrinsic(p, name, ce, result_type, &vec_res)) {
		return vec_res;
	}
	if (xb_build_a64_vec_intrinsic(p, name, ce, result_type, &vec_res)) {
		return vec_res;
	}
	if (ce->args.count != n || pt->Proc.result_count != 1) XB_UNSUPPORTED(p, "llvm intrinsic");
	for (Ast *arg : ce->args) {
		if (arg->kind == Ast_FieldValue) XB_UNSUPPORTED(p, "llvm intrinsic");
	}

	isize dot = -1;
	for (isize i = name.len-1; i >= 0; i--) {
		if (name[i] == '.') { dot = i; break; }
	}
	String base = substring(name, 5, dot);
	String suffix = substring(name, dot+1, name.len);
	Type *ft = nullptr;
	if (suffix == "f16") ft = t_f16;
	if (suffix == "f32") ft = t_f32;
	if (suffix == "f64") ft = t_f64;
	if (ft == nullptr || !are_types_identical(core_type(pt->Proc.results->Tuple.variables[0]->type), ft)) {
		XB_UNSUPPORTED(p, "llvm intrinsic");
	}
	for (Entity *pe : pt->Proc.params->Tuple.variables) {
		if (!are_types_identical(core_type(pe->type), ft)) XB_UNSUPPORTED(p, "llvm intrinsic");
	}

	// f16 is computed in f32, like LLVM promotes it
	Type *ct = ft == t_f16 ? t_f32 : ft;
	xbType st = xb_scalar_type(ct);
	u32 args[3] = {};
	if (n > gb_count_of(args)) XB_UNSUPPORTED(p, "llvm intrinsic");
	for (isize i = 0; i < n; i++) {
		xbValue v = xb_build_expr(p, ce->args[i]);
		v = xb_emit_conv(p, xb_emit_conv(p, v, ft), ct);
		args[i] = xb_value_to_reg(p, v);
	}

	if (base == "fmuladd" && n == 3) {
		// only fused when the target has fma
		if (check_target_feature_is_enabled(str_lit("fma"), nullptr)) XB_UNSUPPORTED(p, "llvm intrinsic fmuladd with fma");
		u32 m = xb_binop(p, xbOp_FMul, st, args[0], args[1]);
		if (ft == t_f16) {
			// LLVM rounds the product to f16 before the add
			m = xb_value_to_reg(p, xb_f16_to_f32(p, xb_float_to_f16(p, xb_value_reg(ct, m), t_f16)));
		}
		return xb_emit_conv(p, xb_value_reg(ct, xb_binop(p, xbOp_FAdd, st, m, args[2])), result_type);
	}
	if (base == "sqrt" && n == 1) {
		return xb_emit_conv(p, xb_value_reg(ct, xb_unop(p, xbOp_Sqrt, st, args[0])), result_type);
	}

	struct LibmFn { char const *name; isize params; };
	static LibmFn const libm[] = {
		{"sin", 1}, {"cos", 1}, {"tan", 1}, {"asin", 1}, {"acos", 1}, {"atan", 1},
		{"sinh", 1}, {"cosh", 1}, {"tanh", 1},
		{"exp", 1}, {"exp2", 1}, {"exp10", 1}, {"log", 1}, {"log2", 1}, {"log10", 1},
		{"floor", 1}, {"ceil", 1}, {"trunc", 1}, {"round", 1}, {"rint", 1}, {"nearbyint", 1},
		{"pow", 2}, {"atan2", 2}, {"fma", 3},
	};
	char const *fn = nullptr;
	for (LibmFn const &f : libm) {
		if (base == make_string_c(f.name) && n == f.params) {
			fn = f.name;
			break;
		}
	}
	if (fn == nullptr) XB_UNSUPPORTED(p, "llvm intrinsic");

	char sym_name[32] = {};
	gb_snprintf(sym_name, gb_size_of(sym_name), "%s%s", fn, ct == t_f32 ? "f" : "");
	i32 sym = xb_symbol(p->m, make_string_c(sym_name));
	p->m->symbols[sym].flags |= xbSymbolFlag_Func | xbSymbolFlag_Foreign;

	Type *param_types[3] = {ct, ct, ct};
	xbValue callee = {};
	callee.type = alloc_type_proc_from_types(param_types, cast(unsigned)n, ct, false, ProcCC_CDecl);
	xbValue values[3] = {};
	for (isize i = 0; i < n; i++) {
		values[i] = xb_value_reg(ct, args[i]);
	}
	xbValue res = xb_emit_call_internal(p, callee, sym, xb_args(values, n));
	return xb_emit_conv(p, res, result_type);
}

gb_internal bool xb_should_inline(xbProc *p, Entity *e, ProcInlining call_inlining, ProcTailing tailing, Type *call_type);
gb_internal bool xb_try_inline_call(xbProc *p, Entity *e, Slice<xbValue> args, Ast *call_expr, xbValue *res);

// A call to the procedure `e`, whose value is `proc`, with converted arguments.
gb_internal xbValue xb_emit_call_entity(xbProc *p, Entity *e, xbValue proc, Slice<xbValue> args, Ast *call_expr) {
	xbValue res = {};
	if (e != nullptr && xb_should_inline(p, e, ProcInlining_none, ProcTailing_none, proc.type) &&
	    xb_try_inline_call(p, e, args, call_expr, &res)) {
		return res;
	}
	return xb_emit_call(p, proc, args, call_expr);
}

gb_internal xbValue xb_build_call_expr_internal(xbProc *p, Ast *expr) {
	TypeAndValue tv = type_and_value_of_expr(expr);
	ast_node(ce, CallExpr, expr);

	TypeAndValue proc_tv = type_and_value_of_expr(ce->proc);
	if (proc_tv.mode == Addressing_Type) {
		GB_ASSERT(ce->args.count == 1);
		xbValue x = xb_build_expr(p, ce->args[0]);
		xbValue y = xb_emit_conv(p, x, tv.type);
		y.type = tv.type;
		return y;
	}

	Ast *proc_expr = unparen_expr(ce->proc);
	Entity *proc_entity = entity_of_node(proc_expr);

	if (proc_tv.mode == Addressing_Builtin) {
		BuiltinProcId id = BuiltinProc_Invalid;
		if (proc_entity != nullptr) {
			id = cast(BuiltinProcId)proc_entity->Builtin.id;
		} else {
			id = BuiltinProc_DIRECTIVE;
		}
		return xb_build_builtin_proc(p, expr, tv, id);
	}

	if (proc_entity != nullptr) {
		if (proc_entity->flags & EntityFlag_Disabled) {
			xbValue v = {};
			return v;
		}
		if (proc_entity->kind == Entity_AsmTemplate) {
			return xb_build_asm_call(p, proc_entity, ce);
		}
		if (proc_entity->kind == Entity_Procedure && proc_entity->Procedure.is_foreign &&
		    base_type(proc_entity->type)->Proc.calling_convention == ProcCC_None &&
		    string_starts_with(proc_entity->Procedure.link_name, str_lit("llvm."))) {
			return xb_build_llvm_intrinsic_call(p, proc_entity, ce, tv.type);
		}

	}
	if (ce->tailing == ProcTailing_must_tail) XB_UNSUPPORTED(p, "must tail");

	// an Objective-C method is sent as a message, its procedure is not called
	bool is_objc_call = proc_entity != nullptr && proc_entity->kind == Entity_Procedure && proc_entity->Procedure.is_objc_impl_or_import;
	xbValue value = {};
	i32 direct_sym = -1;
	if (is_objc_call) {
		value.type = proc_tv.type;
	} else if (proc_expr->tav.mode == Addressing_Constant) {
		ExactValue v = proc_expr->tav.value;
		if (v.kind == ExactValue_Integer || v.kind == ExactValue_Pointer) {
			u64 u = v.kind == ExactValue_Integer ? big_int_to_u64(&v.value_integer) : cast(u64)v.value_pointer;
			value = xb_value_reg(proc_expr->tav.type, xb_iconst(p, xbType_I64, cast(i64)u));
		}
	}
	if (value.kind == xbValue_Invalid && !is_objc_call) {
		if (proc_entity != nullptr && proc_entity->kind == Entity_Procedure) {
			direct_sym = xb_direct_symbol_of(p, proc_expr, &value);
		} else {
			value = xb_build_expr(p, proc_expr);
		}
	}
	Type *callee_type = proc_expr->tav.type;
	if (callee_type != nullptr && callee_type != value.type && is_type_proc(callee_type) && base_type(callee_type)->Proc.is_poly_specialized) {
		value.type = callee_type;
	}

	Type *proc_type_ = base_type(value.type);
	GB_ASSERT(proc_type_->kind == Type_Proc);
	TypeProc *pt = &proc_type_->Proc;
	GB_ASSERT(ce->split_args != nullptr);

	auto args = array_make<xbValue>(xb_allocator(), 0, pt->param_count);
	defer (array_free(&args));

	bool vari_expand = (ce->ellipsis.pos.line != 0);
	bool is_c_vararg = pt->c_vararg;
	bool has_tuple_positional_arg = false;
	if (pt->variadic && !is_c_vararg && !vari_expand) {
		for (Ast *arg : ce->split_args->positional) {
			TypeAndValue tav = type_and_value_of_expr(arg);
			if (is_type_tuple(tav.type)) {
				has_tuple_positional_arg = true;
				break;
			}
		}
	}

	if (has_tuple_positional_arg) {
		auto flat_args = array_make<xbValue>(xb_allocator());
		defer (array_free(&flat_args));
		for_array(i, ce->split_args->positional) {
			Entity *e = pt->params->Tuple.variables[gb_min(i, cast(isize)pt->variadic_index)];
			if (e->kind == Entity_TypeName) {
				array_add(&flat_args, xb_zero_value(p, e->type));
			} else if (e->kind == Entity_Constant) {
				array_add(&flat_args, xb_const_value(p, e->type, e->Constant.value));
			} else {
				xbValue arg = xb_build_expr(p, ce->split_args->positional[i]);
				xb_add_values_to_array(p, &flat_args, arg);
			}
		}
		isize fixed_count = pt->variadic_index;
		isize supplied_fixed_count = gb_min(fixed_count, flat_args.count);
		for (isize i = 0; i < supplied_fixed_count; i++) {
			array_add(&args, flat_args[i]);
		}
		while (args.count < fixed_count) {
			xbValue empty = {};
			array_add(&args, empty);
		}
		Type *slice_type = pt->params->Tuple.variables[pt->variadic_index]->type;
		auto var_args = slice(slice_from_array(flat_args), supplied_fixed_count, flat_args.count);
		array_add(&args, xb_build_variadic_slice(p, slice_type, var_args));
	} else for_array(i, ce->split_args->positional) {
		Entity *e = pt->params->Tuple.variables[i];
		if (e->kind == Entity_TypeName) {
			array_add(&args, xb_zero_value(p, e->type));
			continue;
		} else if (e->kind == Entity_Constant) {
			array_add(&args, xb_const_value(p, e->type, e->Constant.value));
			continue;
		}
		if (pt->variadic && pt->variadic_index == i) {
			xbValue variadic_args = {};
			auto variadic = slice(ce->split_args->positional, pt->variadic_index, ce->split_args->positional.count);
			if (variadic.count != 0) {
				Type *slice_type = e->type;
				if (is_c_vararg) {
					Type *elem_type = base_type(slice_type)->Slice.elem;
					for (Ast *var_arg : variadic) {
						xbValue arg = xb_build_expr(p, var_arg);
						if (is_type_any(elem_type)) {
							if (is_type_untyped_nil(arg.type)) {
								arg = xb_value_reg(t_rawptr, xb_iconst(p, xbType_I64, 0));
							}
							if (is_type_untyped(arg.type)) {
								arg = xb_emit_conv(p, arg, default_type(arg.type));
							}
							xb_add_values_to_array(p, &args, arg);
						} else {
							xb_add_values_to_array(p, &args, xb_emit_conv(p, arg, elem_type));
						}
					}
					break;
				} else if (vari_expand) {
					variadic_args = xb_emit_conv(p, xb_build_expr(p, variadic[0]), slice_type);
				} else {
					auto var_args = array_make<xbValue>(xb_allocator(), 0, variadic.count);
					defer (array_free(&var_args));
					for (Ast *var_arg : variadic) {
						xb_add_values_to_array(p, &var_args, xb_build_expr(p, var_arg));
					}
					variadic_args = xb_build_variadic_slice(p, slice_type, slice_from_array(var_args));
				}
			}
			array_add(&args, variadic_args);
			break;
		} else {
			xbValue value = xb_build_expr(p, ce->split_args->positional[i]);
			xb_add_values_to_array(p, &args, value);
		}
	}

	if (!is_c_vararg) {
		while (args.count < pt->param_count) {
			xbValue empty = {};
			array_add(&args, empty);
		}
		args.count = pt->param_count;
	}

	for (Ast *arg : ce->split_args->named) {
		ast_node(fv, FieldValue, arg);
		String name = fv->field->Ident.token.string;
		isize param_index = lookup_procedure_parameter(pt, name);
		GB_ASSERT(param_index >= 0);
		Entity *e = pt->params->Tuple.variables[param_index];
		if (e->kind == Entity_TypeName) {
			args[param_index] = xb_zero_value(p, e->type);
		} else if (is_c_vararg && pt->variadic && pt->variadic_index == param_index) {
			XB_UNSUPPORTED(p, "named c vararg");
		} else {
			xbValue value = xb_build_expr(p, fv->value);
			GB_ASSERT(!is_type_tuple(value.type));
			args[param_index] = value;
		}
	}

	if (pt->params != nullptr) {
		for_array(arg_index, pt->params->Tuple.variables) {
			Entity *e = pt->params->Tuple.variables[arg_index];
			if (pt->variadic && arg_index == pt->variadic_index) {
				if (!is_c_vararg && args[arg_index].kind == xbValue_Invalid && args[arg_index].type == nullptr) {
					args[arg_index] = xb_zero_value(p, e->type);
				} else if (!is_c_vararg && args[arg_index].kind == xbValue_Invalid) {
					args[arg_index] = xb_zero_value(p, e->type);
				}
				continue;
			}
			xbValue arg = args[arg_index];
			if (arg.kind == xbValue_Invalid && arg.type == nullptr) {
				switch (e->kind) {
				case Entity_TypeName:
					args[arg_index] = xb_zero_value(p, e->type);
					break;
				case Entity_Variable:
					args[arg_index] = xb_emit_conv(p, xb_handle_param_value(p, e->type, e->Variable.param_value, pt, expr), e->type);
					break;
				case Entity_Constant:
					args[arg_index] = xb_const_value(p, e->type, e->Constant.value);
					break;
				default:
					GB_PANIC("Unknown entity kind");
				}
			} else {
				args[arg_index] = xb_emit_conv(p, arg, e->type);
			}
		}
	}

	// drop the non-variable params (type and constant params of polymorphic procedures)
	auto call_args = array_make<xbValue>(xb_allocator(), 0, args.count);
	defer (array_free(&call_args));
	isize final_count = is_c_vararg ? args.count : pt->param_count;
	for (isize i = 0; i < final_count; i++) {
		if (pt->params != nullptr && i < pt->params->Tuple.variables.count) {
			Entity *e = pt->params->Tuple.variables[i];
			if (e->kind != Entity_Variable) continue;
			if (is_c_vararg && (e->flags & EntityFlag_CVarArg)) {
				// the c vararg slot itself carries nothing, extra values follow
				if (i == pt->variadic_index && args[i].kind == xbValue_Invalid) continue;
			}
		}
		array_add(&call_args, args[i]);
	}

	if (is_objc_call) {
		return xb_objc_auto_send(p, expr, slice_from_array(call_args));
	}

	xbValue res = {};
	if (direct_sym < 0 || !xb_should_inline(p, proc_entity, ce->inlining, ce->tailing, value.type) ||
	    !xb_try_inline_call(p, proc_entity, slice_from_array(call_args), expr, &res)) {
		res = xb_emit_call_internal(p, value, direct_sym, slice_from_array(call_args));
	}

	if (proc_entity != nullptr && proc_entity->kind == Entity_Procedure && entity_has_deferred_procedure(proc_entity)) {
		DeferredProcedureKind kind = proc_entity->Procedure.deferred_procedure.kind;
		Entity *deferred_entity = proc_entity->Procedure.deferred_procedure.entity;
		bool by_ptr = false;
		auto result_as_args = array_make<xbValue>(xb_allocator(), 0, call_args.count+2);
		auto add_out = [&]() {
			if (res.kind == xbValue_Invalid) return;
			auto outs = array_make<xbValue>(xb_allocator(), 0, 2);
			xb_add_values_to_array(p, &outs, res);
			for (xbValue v : outs) array_add(&result_as_args, v);
			array_free(&outs);
		};
		switch (kind) {
		case DeferredProcedure_none: break;
		case DeferredProcedure_in_by_ptr: by_ptr = true; /*fallthrough*/
		case DeferredProcedure_in:
			for (xbValue v : call_args) array_add(&result_as_args, v);
			break;
		case DeferredProcedure_out_by_ptr: by_ptr = true; /*fallthrough*/
		case DeferredProcedure_out:
			add_out();
			break;
		case DeferredProcedure_in_out_by_ptr: by_ptr = true; /*fallthrough*/
		case DeferredProcedure_in_out:
			for (xbValue v : call_args) array_add(&result_as_args, v);
			add_out();
			break;
		}
		for_array(i, result_as_args) {
			xbValue v = result_as_args[i];
			if (by_ptr) {
				xbMem m = xb_address_from_load_or_generate_local(p, v);
				result_as_args[i] = xb_value_reg(alloc_type_pointer(v.type), xb_lea(p, m));
			} else if (v.kind == xbValue_Mem) {
				// the deferred call sees the values as they were
				result_as_args[i] = xb_value_copy_to_temp(p, v);
			}
		}
		xbDefer d = {};
		d.is_proc = true;
		d.scope_index = p->scope_index;
		d.context_stack_count = p->context_stack.count;
		d.proc = xb_proc_value_from_entity(p, deferred_entity);
		d.proc_entity = deferred_entity;
		d.args = result_as_args;
		d.pos = ast_token(expr).pos;
		array_add(&p->defers, d);
	}
	return res;
}

gb_internal xbValue xb_build_call_expr(xbProc *p, Ast *expr) {
	expr = unparen_expr(expr);
	ast_node(ce, CallExpr, expr);
	xbValue res = xb_build_call_expr_internal(p, expr);
	if (ce->optional_ok_one) {
		GB_ASSERT(is_type_tuple(res.type));
		Type *ft = nullptr;
		i64 off = type_offset_of(res.type, 0, &ft);
		return xb_load_value(p, ft, xb_mem_offset(res.mem, off));
	}
	return res;
}

////////////////////////////////////////////////////////////////
// #soa builtins
////////////////////////////////////////////////////////////////

gb_internal u32 xb_min_int(xbProc *p, u32 a, u32 b) {
	return xb_select(p, xbType_I64, xb_cmp(p, xbCond_SLT, xbType_I64, a, b), a, b);
}

gb_internal xbValue xb_build_soa_zip(xbProc *p, AstCallExpr *ce, TypeAndValue const &tv) {
	auto slices = array_make<xbMem>(xb_allocator(), ce->args.count);
	defer (array_free(&slices));
	for_array(i, ce->args) {
		Ast *arg = ce->args[i];
		if (arg->kind == Ast_FieldValue) arg = arg->FieldValue.value;
		slices[i] = xb_value_to_mem(p, xb_build_expr(p, arg));
	}
	u32 len = xb_load(p, xbType_I64, xb_mem_offset(slices[0], 8));
	for (isize i = 1; i < slices.count; i++) {
		len = xb_min_int(p, len, xb_load(p, xbType_I64, xb_mem_offset(slices[i], 8)));
	}
	Type *t = base_type(tv.type);
	xbMem res = xb_add_local(p, tv.type, true);
	Type *ft = nullptr;
	for_array(i, slices) {
		xb_store(p, xbType_I64, xb_mem_offset(res, type_offset_of(t, i, &ft)), xb_load(p, xbType_I64, slices[i]));
	}
	xb_store(p, xbType_I64, xb_mem_offset(res, type_offset_of(t, slices.count, &ft)), len);
	return xb_value_mem(tv.type, res);
}

gb_internal xbValue xb_build_soa_unzip(xbProc *p, AstCallExpr *ce, TypeAndValue const &tv) {
	xbValue arg = xb_build_expr(p, ce->args[0]);
	Type *t = base_type(arg.type);
	GB_ASSERT(is_type_soa_struct(t) && t->Struct.soa_kind == StructSoa_Slice);
	xbMem m = xb_value_to_mem(p, arg);
	u32 len = xb_soa_len(p, t, m);
	xbMem res = xb_add_local(p, tv.type, true);
	isize n = is_type_tuple(tv.type) ? xb_soa_column_count(t) : 1;
	for (isize i = 0; i < n; i++) {
		Type *ft = nullptr;
		i64 src = type_offset_of(t, i, &ft);
		i64 dst = is_type_tuple(tv.type) ? type_offset_of(tv.type, i, &ft) : 0;
		xb_store(p, xbType_I64, xb_mem_offset(res, dst), xb_load(p, xbType_I64, xb_mem_offset(m, src)));
		xb_store(p, xbType_I64, xb_mem_offset(res, dst+8), len);
	}
	return xb_value_mem(tv.type, res);
}

gb_internal void xb_build_soa_copy_from_slice(xbProc *p, AstCallExpr *ce) {
	xbValue ptr    = xb_build_expr(p, ce->args[0]);
	xbValue offset = xb_build_expr(p, ce->args[1]);
	xbValue args   = xb_build_expr(p, ce->args[2]);
	Type *t = base_type(type_deref(ptr.type));
	GB_ASSERT(is_type_soa_dynamic_array(t));
	Type *elem = t->Struct.soa_elem;
	isize n = xb_soa_column_count(t);
	if (n == 0) return;
	xbMem soa = xb_mem(xbMem_Reg, xb_value_to_reg(p, ptr), 0);
	xbMem am = xb_value_to_mem(p, args);
	u32 arg_ptr = xb_load(p, xbType_I64, am);
	u32 arg_len = xb_load(p, xbType_I64, xb_mem_offset(am, 8));
	u32 off = xb_value_to_reg(p, xb_emit_conv(p, offset, t_int));
	u32 max_soa_len = xb_binop(p, xbOp_Sub, xbType_I64, xb_soa_len(p, t, soa), off);
	u32 max_len = xb_min_int(p, arg_len, max_soa_len);
	i64 elem_size = type_size_of(elem);
	xbMem j_mem = xb_add_local(p, t_int, false);
	for (isize f = 0; f < n; f++) {
		Type *ct = nullptr;
		i64 coff = type_offset_of(t, f, &ct);
		Type *ft = nullptr;
		i64 foff = xb_soa_elem_component(p, elem, f, &ft);
		i64 fsize = type_size_of(ft);
		u32 col = xb_load(p, xbType_I64, xb_mem_offset(soa, coff));
		// for j in 0..<max_len: col[offset+j] = args[j].field
		xbBlock *loop = xb_new_block(p);
		xbBlock *body = xb_new_block(p);
		xbBlock *done = xb_new_block(p);
		xb_store(p, xbType_I64, j_mem, xb_iconst(p, xbType_I64, 0));
		xb_jump(p, loop);
		xb_start_block(p, loop);
		u32 j = xb_load(p, xbType_I64, j_mem);
		xb_branch(p, xb_cmp(p, xbCond_SLT, xbType_I64, j, max_len), body, done);
		xb_start_block(p, body);
		j = xb_load(p, xbType_I64, j_mem);
		u32 dst = xb_ptr_add_scaled(p, col, xb_binop(p, xbOp_Add, xbType_I64, j, off), fsize);
		u32 src = xb_ptr_add_const(p, xb_ptr_add_scaled(p, arg_ptr, j, elem_size), foff);
		xb_memcopy(p, xb_mem(xbMem_Reg, dst, 0), xb_mem(xbMem_Reg, src, 0), fsize);
		xb_store(p, xbType_I64, j_mem, xb_binop(p, xbOp_Add, xbType_I64, j, xb_iconst(p, xbType_I64, 1)));
		xb_jump(p, loop);
		xb_start_block(p, done);
	}
}

////////////////////////////////////////////////////////////////
// Builtins
////////////////////////////////////////////////////////////////

// minnum/maxnum of two floats: `a` when it compares so or `b` is a NaN, else `b`.
// An f16 is compared as f32 and keeps its own bits.
gb_internal xbValue xb_float_pick(xbProc *p, Type *t, xbValue a, xbValue b, bool is_max) {
	if (xb_is_f16(t)) {
		u32 af = xb_value_to_reg(p, xb_f16_to_f32(p, a));
		u32 bf = xb_value_to_reg(p, xb_f16_to_f32(p, b));
		u32 pick_a = xb_cmp(p, is_max ? xbCond_FGT : xbCond_FLT, xbType_F32, af, bf);
		u32 b_nan = xb_cmp(p, xbCond_FNE, xbType_F32, bf, bf);
		u32 cond = xb_binop(p, xbOp_Or, xbType_I8, pick_a, b_nan);
		u32 ab = xb_value_to_reg(p, xb_emit_transmute(p, a, t_u16));
		u32 bb = xb_value_to_reg(p, xb_emit_transmute(p, b, t_u16));
		return xb_emit_transmute(p, xb_value_reg(t_u16, xb_select(p, xbType_I16, cond, ab, bb)), t);
	}
	xbType st = xb_scalar_type(t);
	u32 ar = xb_value_to_reg(p, a);
	u32 br = xb_value_to_reg(p, b);
	u32 pick_a = xb_cmp(p, is_max ? xbCond_FGT : xbCond_FLT, st, ar, br);
	u32 r = xb_select(p, st, pick_a, ar, br);
	u32 b_nan = xb_cmp(p, xbCond_FNE, st, br, br);
	return xb_value_reg(t, xb_select(p, st, b_nan, ar, r));
}

gb_internal u32 xb_simd_saturate(xbProc *p, bool is_add, bool is_signed, xbType st, u32 a, u32 b);

gb_internal xbValue xb_select_128(xbProc *p, Type *t, u32 cond, xbValue a, xbValue b) {
	xbPair x = xb_pair_of(p, a);
	xbPair y = xb_pair_of(p, b);
	xbPair r = {xb_select(p, xbType_I64, cond, x.lo, y.lo), xb_select(p, xbType_I64, cond, x.hi, y.hi)};
	return xb_pair_value(p, t, r);
}

// llvm.[su]{mul,div}.fix[.sat]: the product shifted right by the scale, or the dividend shifted
// left and divided, exactly in 128 bits and rounded down like LLVM's expansion, then clamped
// to the type for .sat. A zero divisor gives what integer division gives, of the unscaled x.
gb_internal xbValue xb_build_fixed_point(xbProc *p, AstCallExpr *ce, Type *result_type, BuiltinProcId id) {
	Type *t = integer_endian_type_to_platform_type(result_type);
	xbType st = xb_scalar_type(t);
	if (st == xbType_None || xb_is_int128(t)) XB_UNSUPPORTED(p, "fixed point type");
	TypeAndValue scale_tv = type_and_value_of_expr(ce->args[2]);
	if (scale_tv.mode != Addressing_Constant) XB_UNSUPPORTED(p, "fixed point scale");
	bool is_signed = !is_type_unsigned(t);
	bool is_mul = id == BuiltinProc_fixed_point_mul || id == BuiltinProc_fixed_point_mul_sat;
	bool is_sat = id == BuiltinProc_fixed_point_mul_sat || id == BuiltinProc_fixed_point_div_sat;
	Type *wt = is_signed ? t_i128 : t_u128;

	xbValue x = xb_emit_conv(p, xb_build_expr(p, ce->args[0]), t);
	xbValue y = xb_emit_conv(p, xb_build_expr(p, ce->args[1]), t);
	xbValue scale = xb_const_int(p, t_u64, exact_value_to_i64(scale_tv.value));
	xbValue wx = xb_emit_conv(p, x, wt);
	xbValue wy = xb_emit_conv(p, y, wt);
	xbMem res = xb_add_local(p, t, false);
	xbBlock *done = nullptr;
	xbValue r = {};
	if (is_mul) {
		r = xb_emit_arith(p, Token_Shr, xb_emit_arith(p, Token_Mul, wx, wy, wt), scale, wt);
	} else {
		xbBlock *safe = xb_new_block(p);
		xbBlock *zero = xb_new_block(p);
		done = xb_new_block(p);
		xb_branch(p, xb_cmp(p, xbCond_NE, st, xb_value_to_reg(p, y), xb_iconst(p, st, 0)), safe, zero);
		xb_start_block(p, zero);
		switch (xb_division_by_zero_behaviour(p)) {
		case IntegerDivisionByZero_Trap:
			xb_emit(p, xb_instr(xbOp_Trap));
			xb_unreachable(p);
			break;
		case IntegerDivisionByZero_Zero:    xb_store(p, st, res, xb_iconst(p, st, 0)); break;
		case IntegerDivisionByZero_Self:    xb_store_value(p, res, x); break;
		case IntegerDivisionByZero_AllBits: xb_store(p, st, res, xb_iconst(p, st, -1)); break;
		}
		xb_jump(p, done);
		xb_start_block(p, safe);
		xbValue n = xb_emit_arith(p, Token_Shl, wx, scale, wt);
		r = xb_emit_arith(p, Token_Quo, n, wy, wt);
		if (is_signed) {
			// down when a remainder is left and the signs differ
			xbValue rem = xb_emit_arith(p, Token_Mod, n, wy, wt);
			xbValue z = xb_emit_conv(p, xb_const_int(p, t_i64, 0), wt);
			u32 inexact = xb_to_bool_reg(p, xb_emit_comp(p, Token_NotEq, rem, z));
			u32 rem_neg = xb_to_bool_reg(p, xb_emit_comp(p, Token_Lt, rem, z));
			u32 y_neg = xb_to_bool_reg(p, xb_emit_comp(p, Token_Lt, wy, z));
			u32 down = xb_binop(p, xbOp_And, xbType_I8, inexact, xb_binop(p, xbOp_Xor, xbType_I8, rem_neg, y_neg));
			xbValue one = xb_emit_conv(p, xb_const_int(p, t_i64, 1), wt);
			r = xb_select_128(p, wt, down, xb_emit_arith(p, Token_Sub, r, one, wt), r);
		}
	}
	if (is_sat) {
		i64 bits = 8*type_size_of(t);
		xbValue hi = {};
		if (is_signed) {
			i64 max = cast(i64)((cast(u64)1 << (bits-1)) - 1);
			hi = xb_emit_conv(p, xb_const_int(p, t_i64, max), wt);
			xbValue lo = xb_emit_conv(p, xb_const_int(p, t_i64, -max-1), wt);
			r = xb_select_128(p, wt, xb_to_bool_reg(p, xb_emit_comp(p, Token_Lt, r, lo)), lo, r);
		} else {
			u64 max = bits == 64 ? ~cast(u64)0 : (cast(u64)1 << bits) - 1;
			hi = xb_emit_conv(p, xb_const_int(p, t_u64, cast(i64)max), wt);
		}
		r = xb_select_128(p, wt, xb_to_bool_reg(p, xb_emit_comp(p, Token_Gt, r, hi)), hi, r);
	}
	xb_store_value(p, res, xb_emit_conv(p, r, t));
	if (done != nullptr) {
		xb_jump(p, done);
		xb_start_block(p, done);
	}
	return xb_emit_conv(p, xb_load_value(p, t, res), result_type);
}

// c_va_list on arm64 macOS is a pointer to the next 8 byte stack slot; the variadic arguments
// follow the fixed ones on the stack.
gb_internal void xb_build_c_va_start(xbProc *p, AstCallExpr *ce) {
	if (!xb_is_arm64() || !xb_is_darwin()) XB_UNSUPPORTED(p, "c_va_start outside arm64 macOS");
	if (p->inl != nullptr || !base_type(p->type)->Proc.c_vararg) XB_UNSUPPORTED(p, "c_va_start");
	u32 list = xb_value_to_reg(p, xb_build_expr(p, ce->args[0]));
	u32 first = xb_lea(p, xb_mem(xbMem_Incoming, 0, cast(i32)align_formula(p->abi->stack_size, 8)));
	xb_store(p, xbType_I64, xb_mem(xbMem_Reg, list, 0), first);
}

// LLVM's va_arg on arm64 macOS: integers and floats take 8 bytes, an f32 or f16 is passed as
// an f64, a more aligned value starts aligned.
gb_internal xbValue xb_build_c_va_arg(xbProc *p, AstCallExpr *ce, Type *type) {
	if (!xb_is_arm64() || !xb_is_darwin()) XB_UNSUPPORTED(p, "c_va_arg outside arm64 macOS");
	xbType st = xb_scalar_type(type);
	if (st == xbType_None || is_type_different_to_arch_endianness(type)) XB_UNSUPPORTED(p, "c_va_arg type");
	u32 list = xb_value_to_reg(p, xb_build_expr(p, ce->args[0]));
	xbMem lm = xb_mem(xbMem_Reg, list, 0);
	u32 ptr = xb_load(p, xbType_I64, lm);
	i64 align = type_align_of(type);
	if (align > 8) {
		ptr = xb_binop(p, xbOp_And, xbType_I64, xb_ptr_add_const(p, ptr, align-1), xb_iconst(p, xbType_I64, -align));
	}
	i64 size = gb_max(cast(i64)xb_type_size(st), cast(i64)8);
	xb_store(p, xbType_I64, lm, xb_ptr_add_const(p, ptr, size));
	if (xb_type_is_float(st) && st != xbType_F64) {
		xbValue d = xb_value_reg(t_f64, xb_load(p, xbType_F64, xb_mem(xbMem_Reg, ptr, 0)));
		return xb_emit_conv(p, d, type);
	}
	if (xb_is_f16(type)) {
		xbValue d = xb_value_reg(t_f64, xb_load(p, xbType_F64, xb_mem(xbMem_Reg, ptr, 0)));
		return xb_emit_conv(p, d, type);
	}
	return xb_load_value(p, type, xb_mem(xbMem_Reg, ptr, 0));
}

gb_internal xbValue xb_build_builtin_proc(xbProc *p, Ast *expr, TypeAndValue const &tv, BuiltinProcId id) {
	ast_node(ce, CallExpr, expr);
	if (BuiltinProc__simd_begin < id && id < BuiltinProc__simd_end) {
		return xb_build_builtin_simd_proc(p, expr, tv, id);
	}
	if (id == BuiltinProc_swizzle || id == BuiltinProc_fused_mul_add || (id == BuiltinProc_sqrt && is_type_simd_vector(tv.type))) {
		return xb_build_builtin_vector_proc(p, expr, tv, id);
	}
	switch (id) {
	case BuiltinProc_objc_send:
	case BuiltinProc_objc_find_selector:
	case BuiltinProc_objc_find_class:
	case BuiltinProc_objc_register_selector:
	case BuiltinProc_objc_register_class:
	case BuiltinProc_objc_ivar_get:
	case BuiltinProc_objc_block:
	case BuiltinProc_objc_super:
		return xb_build_objc_builtin(p, expr, id);
	case BuiltinProc_len:
	case BuiltinProc_cap: {
		xbValue v = xb_build_expr(p, ce->args[0]);
		Type *t = base_type(v.type);
		if (is_type_pointer(t)) {
			// len(^[N]T) is constant and handled earlier, len(^[]T) is not allowed
			t = base_type(type_deref(t));
			v = xb_load_value(p, type_deref(v.type), xb_mem_from_ptr(p, v));
		}
		if (is_type_cstring(t) || is_type_cstring16(t)) {
			if (id == BuiltinProc_cap) XB_UNSUPPORTED(p, "cap of cstring");
			xbValue args[1] = {v};
			return xb_emit_conv(p, xb_emit_runtime_call(p, is_type_cstring(t) ? "cstring_len" : "cstring16_len", xb_args(args, 1)), tv.type);
		}
		if (is_type_soa_struct(t)) {
			xbMem m = xb_value_to_mem(p, v);
			return xb_emit_conv(p, xb_value_reg(t_int, id == BuiltinProc_len ? xb_soa_len(p, t, m) : xb_soa_cap(p, t, m)), tv.type);
		}
		if (is_type_map(t)) {
			xbMem m = xb_value_to_mem(p, v);
			if (id == BuiltinProc_len) {
				return xb_emit_conv(p, xb_value_reg(t_int, xb_load(p, xbType_I64, xb_mem_offset(m, 8))), tv.type);
			}
			// cap = data == 0 ? 0 : 1 << (data & (MAP_CACHE_LINE_SIZE-1))
			u32 data = xb_load(p, xbType_I64, m);
			u32 log2_cap = xb_binop(p, xbOp_And, xbType_I64, data, xb_iconst(p, xbType_I64, MAP_CACHE_LINE_SIZE-1));
			u32 cap = xb_binop(p, xbOp_Shl, xbType_I64, xb_iconst(p, xbType_I64, 1), log2_cap);
			u32 is_zero = xb_cmp(p, xbCond_EQ, xbType_I64, data, xb_iconst(p, xbType_I64, 0));
			return xb_emit_conv(p, xb_value_reg(t_int, xb_select(p, xbType_I64, is_zero, xb_iconst(p, xbType_I64, 0), cap)), tv.type);
		}
		if (is_type_string(t) || is_type_slice(t) || is_type_dynamic_array(t)) {
			xbMem m = xb_value_to_mem(p, v);
			i64 off = (id == BuiltinProc_cap && is_type_dynamic_array(t)) ? 16 : 8;
			return xb_emit_conv(p, xb_value_reg(t_int, xb_load(p, xbType_I64, xb_mem_offset(m, off))), tv.type);
		}
		if (is_type_fixed_capacity_dynamic_array(t) && id == BuiltinProc_len) {
			xbMem m = xb_value_to_mem(p, v);
			return xb_emit_conv(p, xb_value_reg(t_int, xb_load(p, xbType_I64, xb_mem_offset(m, cast(i32)type_offset_of(t, 1)))), tv.type);
		}
		{
			gbString r = gb_string_make(permanent_allocator(), "len of ");
			r = gb_string_appendc(r, type_to_string(t));
			if (is_type_soa_struct(t)) r = gb_string_make(permanent_allocator(), "len of soa");
			XB_UNSUPPORTED(p, r);
		}
	}
	case BuiltinProc_complex: {
		xbValue parts[2] = {xb_build_expr(p, ce->args[0]), xb_build_expr(p, ce->args[1])};
		return xb_complex_build(p, tv.type, parts, 2);
	}
	case BuiltinProc_quaternion: {
		xbValue xyzw[4] = {};
		for (i32 i = 0; i < 4; i++) {
			ast_node(f, FieldValue, ce->args[i]);
			String name = f->field->Ident.token.string;
			i32 index = -1;
			// @QuaternionLayout
			if (name == "x" || name == "imag") index = 0;
			else if (name == "y" || name == "jmag") index = 1;
			else if (name == "z" || name == "kmag") index = 2;
			else if (name == "w" || name == "real") index = 3;
			GB_ASSERT(index >= 0);
			xyzw[index] = xb_build_expr(p, f->value);
		}
		return xb_complex_build(p, tv.type, xyzw, 4);
	}
	case BuiltinProc_real:
	case BuiltinProc_imag:
	case BuiltinProc_jmag:
	case BuiltinProc_kmag: {
		xbValue v = xb_build_expr(p, ce->args[0]);
		i64 index = 0;
		if (is_type_complex(v.type)) {
			index = id == BuiltinProc_real ? 0 : 1;
		} else {
			// @QuaternionLayout
			switch (id) {
			case BuiltinProc_real: index = 3; break;
			case BuiltinProc_imag: index = 0; break;
			case BuiltinProc_jmag: index = 1; break;
			case BuiltinProc_kmag: index = 2; break;
			}
		}
		return xb_emit_conv(p, xb_complex_part(p, v, index), tv.type);
	}
	case BuiltinProc_conj: {
		xbValue v = xb_build_expr(p, ce->args[0]);
		Type *t = v.type;
		if (is_type_complex(t)) {
			Type *ft = base_complex_elem_type(core_type(t));
			xbValue parts[2] = {xb_complex_part(p, v, 0), xb_emit_arith(p, Token_Sub, xb_zero_value(p, ft), xb_complex_part(p, v, 1), ft)};
			return xb_complex_build(p, tv.type, parts, 2);
		}
		if (is_type_quaternion(t)) {
			Type *ft = base_complex_elem_type(core_type(t));
			xbValue parts[4] = {};
			for (i64 i = 0; i < 3; i++) {
				parts[i] = xb_emit_arith(p, Token_Sub, xb_zero_value(p, ft), xb_complex_part(p, v, i), ft);
			}
			parts[3] = xb_complex_part(p, v, 3);
			return xb_complex_build(p, tv.type, parts, 4);
		}
		XB_UNSUPPORTED(p, "conj type");
	}
	case BuiltinProc_clamp: {
		// max then min, like lb_emit_clamp
		Type *t = default_type(tv.type);
		xbType st = xb_scalar_type(t);
		if (st == xbType_None && !xb_is_f16(t)) XB_UNSUPPORTED(p, "clamp type");
		xbValue x = xb_emit_conv(p, xb_build_expr(p, ce->args[0]), t);
		xbValue lo = xb_emit_conv(p, xb_build_expr(p, ce->args[1]), t);
		xbValue hi = xb_emit_conv(p, xb_build_expr(p, ce->args[2]), t);
		auto pick = [&](xbValue a, xbValue b, bool is_max) -> xbValue {
			if (xb_is_f16(t) || xb_type_is_float(st)) {
				return xb_float_pick(p, t, a, b, is_max);
			}
			u32 ar = xb_value_to_reg(p, a);
			u32 br = xb_value_to_reg(p, b);
			bool sgn = xb_type_is_signed(t);
			xbCond c = is_max ? (sgn ? xbCond_SGT : xbCond_UGT) : (sgn ? xbCond_SLT : xbCond_ULT);
			return xb_value_reg(t, xb_select(p, st, xb_cmp(p, c, st, ar, br), ar, br));
		};
		return pick(pick(x, lo, true), hi, false);
	}
	case BuiltinProc_raw_data: {
		xbValue v = xb_build_expr(p, ce->args[0]);
		Type *t = base_type(v.type);
		if (is_type_pointer(t) || is_type_multi_pointer(t)) {
			return xb_value_reg(tv.type, xb_value_to_reg(p, v));
		}
		if (is_type_string(t) || is_type_slice(t) || is_type_dynamic_array(t)) {
			xbMem m = xb_value_to_mem(p, v);
			return xb_value_reg(tv.type, xb_load(p, xbType_I64, m));
		}
		if (is_type_cstring(t) || is_type_cstring16(t)) {
			return xb_value_reg(tv.type, xb_value_to_reg(p, v));
		}
		XB_UNSUPPORTED(p, "raw_data of type");
	}
	case BuiltinProc_min:
	case BuiltinProc_max: {
		Type *t = default_type(tv.type);
		xbType st = xb_scalar_type(t);
		if ((st == xbType_None && !xb_is_f16(t)) || ce->args.count < 2) XB_UNSUPPORTED(p, "min/max");
		xbValue acc = xb_emit_conv(p, xb_build_expr(p, ce->args[0]), t);
		for (isize i = 1; i < ce->args.count; i++) {
			xbValue b = xb_emit_conv(p, xb_build_expr(p, ce->args[i]), t);
			if (xb_is_f16(t) || xb_type_is_float(st)) {
				acc = xb_float_pick(p, t, acc, b, id == BuiltinProc_max);
				continue;
			}
			bool sgn = xb_type_is_signed(t);
			xbCond c = id == BuiltinProc_min ? (sgn ? xbCond_SLT : xbCond_ULT) : (sgn ? xbCond_SGT : xbCond_UGT);
			u32 ar = xb_value_to_reg(p, acc);
			u32 br = xb_value_to_reg(p, b);
			u32 cond = xb_cmp(p, c, st, ar, br);
			acc = xb_value_reg(t, xb_select(p, st, cond, ar, br));
		}
		return acc;
	}
	case BuiltinProc_abs: {
		Type *t = default_type(tv.type);
		Type *at = core_type(type_of_expr(ce->args[0]));
		if (is_type_complex(at) || is_type_quaternion(at)) {
			i64 bits = 8*type_size_of(at);
			char const *name = nullptr;
			if (is_type_complex(at)) name = bits == 32 ? "abs_complex32" : bits == 64 ? "abs_complex64" : "abs_complex128";
			else name = bits == 64 ? "abs_quaternion64" : bits == 128 ? "abs_quaternion128" : "abs_quaternion256";
			xbValue args[1] = {xb_build_expr(p, ce->args[0])};
			return xb_emit_conv(p, xb_emit_runtime_call(p, name, xb_args(args, 1)), t);
		}
		if (xb_is_f16(t)) {
			// clear the sign bit
			xbValue x = xb_emit_conv(p, xb_build_expr(p, ce->args[0]), t);
			u32 bits = xb_load(p, xbType_I16, xb_value_to_mem(p, x));
			i64 mask = is_type_different_to_arch_endianness(t) ? 0xFF7F : 0x7FFF;
			xbMem m = xb_add_local(p, t, false);
			xb_store(p, xbType_I16, m, xb_binop(p, xbOp_And, xbType_I16, bits, xb_iconst(p, xbType_I16, mask)));
			return xb_value_mem(t, m);
		}
		if (is_type_different_to_arch_endianness(t) && !xb_is_int128(t) && !xb_is_f16(t)) {
			// in the platform order, then back
			Type *pt = integer_endian_type_to_platform_type(t);
			xbValue x = xb_emit_conv(p, xb_emit_conv(p, xb_build_expr(p, ce->args[0]), t), pt);
			if (is_type_float(pt)) {
				xbType st = xb_scalar_type(pt);
				xbType it = st == xbType_F32 ? xbType_I32 : xbType_I64;
				u32 bits = xb_convop(p, xbOp_Bitcast, it, st, xb_value_to_reg(p, x));
				i64 mask = it == xbType_I32 ? 0x7FFFFFFF : 0x7FFFFFFFFFFFFFFFll;
				u32 masked = xb_binop(p, xbOp_And, it, bits, xb_iconst(p, it, mask));
				return xb_emit_conv(p, xb_value_reg(pt, xb_convop(p, xbOp_Bitcast, st, it, masked)), t);
			}
			if (!is_type_unsigned(pt)) {
				xbType st = xb_scalar_type(pt);
				u32 r = xb_value_to_reg(p, x);
				u32 neg = xb_unop(p, xbOp_Neg, st, r);
				u32 is_neg = xb_cmp(p, xbCond_SLT, st, r, xb_iconst(p, st, 0));
				x = xb_value_reg(pt, xb_select(p, st, is_neg, neg, r));
			}
			return xb_emit_conv(p, x, t);
		}
		if (xb_is_int128(t)) {
			xbValue x = xb_emit_conv(p, xb_build_expr(p, ce->args[0]), t);
			if (is_type_unsigned(t)) return x;
			Type *pt = integer_endian_type_to_platform_type(t);
			x = xb_emit_conv(p, x, pt);
			xbPair a = xb_pair_of(p, x);
			xbPair n = xb_pair_of(p, xb_emit_arith_128(p, Token_Sub, xb_zero_value(p, pt), x, pt));
			u32 is_neg = xb_cmp(p, xbCond_SLT, xbType_I64, a.hi, xb_i64(p, 0));
			xbPair r = {xb_select(p, xbType_I64, is_neg, n.lo, a.lo), xb_select(p, xbType_I64, is_neg, n.hi, a.hi)};
			return xb_emit_conv(p, xb_pair_value(p, pt, r), t);
		}
		xbType st = xb_scalar_type(t);
		if (xb_type_is_float(st)) {
			xbType it = st == xbType_F32 ? xbType_I32 : xbType_I64;
			u32 x = xb_value_to_reg(p, xb_emit_conv(p, xb_build_expr(p, ce->args[0]), t));
			u32 bits = xb_convop(p, xbOp_Bitcast, it, st, x);
			i64 mask = it == xbType_I32 ? 0x7FFFFFFF : 0x7FFFFFFFFFFFFFFFll;
			u32 masked = xb_binop(p, xbOp_And, it, bits, xb_iconst(p, it, mask));
			return xb_value_reg(t, xb_convop(p, xbOp_Bitcast, st, it, masked));
		}
		if (st == xbType_None) XB_UNSUPPORTED(p, "abs type");
		xbValue x = xb_emit_conv(p, xb_build_expr(p, ce->args[0]), t);
		if (!xb_type_is_signed(t)) return x;
		u32 r = xb_value_to_reg(p, x);
		u32 neg = xb_unop(p, xbOp_Neg, st, r);
		u32 is_neg = xb_cmp(p, xbCond_SLT, st, r, xb_iconst(p, st, 0));
		return xb_value_reg(t, xb_select(p, st, is_neg, neg, r));
	}
	case BuiltinProc_type_info_of: {
		if (build_context.no_rtti) XB_UNSUPPORTED(p, "type_info_of without rtti");
		Ast *arg = ce->args[0];
		TypeAndValue atv = type_and_value_of_expr(arg);
		if (atv.mode == Addressing_Type) {
			Type *t = default_type(atv.type);
			isize index = lb_type_info_index(p->m->info, t);
			GB_ASSERT(index >= 0);
			// runtime.type_table[index], the table's own symbol may be private to LLVM's object
			Entity *table = xb_lookup_runtime_entity(p->m, "type_table");
			xbMem tm = xb_global_mem(p, table);
			u32 data = xb_load(p, xbType_I64, tm);
			return xb_value_reg(t_type_info_ptr, xb_load(p, xbType_I64, xb_mem(xbMem_Reg, data, cast(i32)(index*8))));
		}
		xbValue id = xb_emit_conv(p, xb_build_expr(p, arg), t_typeid);
		xbValue args[1] = {id};
		return xb_emit_runtime_call(p, "__type_info_of", xb_args(args, 1));
	}
	case BuiltinProc_mem_copy:
	case BuiltinProc_mem_copy_non_overlapping: {
		u32 dst = xb_value_to_reg(p, xb_emit_conv(p, xb_build_expr(p, ce->args[0]), t_rawptr));
		u32 src = xb_value_to_reg(p, xb_emit_conv(p, xb_build_expr(p, ce->args[1]), t_rawptr));
		u32 len = xb_value_to_reg(p, xb_emit_conv(p, xb_build_expr(p, ce->args[2]), t_int));
		xbInstr i = xb_instr(xbOp_MemMoveDyn);
		i.a = dst;
		i.b = src;
		i.c = len;
		xb_emit(p, i);
		return {};
	}
	case BuiltinProc_mem_zero:
	case BuiltinProc_mem_zero_volatile: {
		u32 ptr = xb_value_to_reg(p, xb_emit_conv(p, xb_build_expr(p, ce->args[0]), t_rawptr));
		u32 len = xb_value_to_reg(p, xb_emit_conv(p, xb_build_expr(p, ce->args[1]), t_int));
		xbInstr i = xb_instr(xbOp_MemSetDyn);
		i.a = ptr;
		i.b = xb_iconst(p, xbType_I8, 0);
		i.c = len;
		xb_emit(p, i);
		return {};
	}
	case BuiltinProc_ptr_offset: {
		xbValue ptr = xb_build_expr(p, ce->args[0]);
		u32 len = xb_value_to_reg(p, xb_emit_conv(p, xb_build_expr(p, ce->args[1]), t_int));
		Type *elem = type_deref(ptr.type, true);
		return xb_value_reg(ptr.type, xb_ptr_add_scaled(p, xb_value_to_reg(p, ptr), len, type_size_of(elem)));
	}
	case BuiltinProc_ptr_sub: {
		Type *elem = type_deref(type_of_expr(ce->args[0]), true);
		u32 a = xb_value_to_reg(p, xb_build_expr(p, ce->args[0]));
		u32 b = xb_value_to_reg(p, xb_build_expr(p, ce->args[1]));
		u32 diff = xb_binop(p, xbOp_Sub, xbType_I64, a, b);
		return xb_value_reg(t_int, xb_binop(p, xbOp_SDiv, xbType_I64, diff, xb_iconst(p, xbType_I64, type_size_of(elem))));
	}
	case BuiltinProc_atomic_thread_fence:
		xb_emit(p, xb_instr(xbOp_AtomicFence));
		return {};
	case BuiltinProc_atomic_signal_fence:
		return {};
	case BuiltinProc_volatile_store:
	case BuiltinProc_non_temporal_store:
	case BuiltinProc_atomic_store:
	case BuiltinProc_atomic_store_explicit:
	case BuiltinProc_unaligned_store: {
		xbValue dst = xb_build_expr(p, ce->args[0]);
		Type *t = type_deref(dst.type);
		xbValue val = xb_emit_conv(p, xb_build_expr(p, ce->args[1]), t);
		xbType st = xb_scalar_type(t);
		xbMem m = xb_mem(xbMem_Reg, xb_value_to_reg(p, dst), 0);
		if (id == BuiltinProc_atomic_store || id == BuiltinProc_atomic_store_explicit) {
			if (st == xbType_None) XB_UNSUPPORTED(p, "atomic store of aggregate");
			u32 r = xb_value_to_reg(p, val);
			if (xb_type_is_float(st)) r = xb_convop(p, xbOp_Bitcast, st == xbType_F32 ? xbType_I32 : xbType_I64, st, r);
			xbInstr i = xb_instr(xbOp_AtomicStore, xb_type_is_float(st) ? (st == xbType_F32 ? xbType_I32 : xbType_I64) : st);
			i.a = r;
			i.mem = m;
			xb_emit(p, i);
			return {};
		}
		xb_store_value(p, m, val);
		return {};
	}
	case BuiltinProc_volatile_load:
	case BuiltinProc_non_temporal_load:
	case BuiltinProc_atomic_load:
	case BuiltinProc_atomic_load_explicit:
	case BuiltinProc_unaligned_load: {
		xbValue src = xb_build_expr(p, ce->args[0]);
		Type *t = type_deref(src.type);
		xbMem m = xb_mem(xbMem_Reg, xb_value_to_reg(p, src), 0);
		xbType st = xb_scalar_type(t);
		if (st == xbType_None) {
			// copy it out, the source may change
			xbMem d = xb_add_local(p, t, false);
			xb_memcopy(p, d, m, type_size_of(t));
			return xb_value_mem(t, d);
		}
		return xb_value_reg(t, xb_load(p, st, m));
	}
	case BuiltinProc_atomic_add:
	case BuiltinProc_atomic_sub:
	case BuiltinProc_atomic_and:
	case BuiltinProc_atomic_nand:
	case BuiltinProc_atomic_or:
	case BuiltinProc_atomic_xor:
	case BuiltinProc_atomic_exchange:
	case BuiltinProc_atomic_add_explicit:
	case BuiltinProc_atomic_sub_explicit:
	case BuiltinProc_atomic_and_explicit:
	case BuiltinProc_atomic_nand_explicit:
	case BuiltinProc_atomic_or_explicit:
	case BuiltinProc_atomic_xor_explicit:
	case BuiltinProc_atomic_exchange_explicit: {
		xbValue dst = xb_build_expr(p, ce->args[0]);
		Type *t = type_deref(dst.type);
		xbType st = xb_scalar_type(t);
		if (st == xbType_None || xb_type_is_float(st)) XB_UNSUPPORTED(p, "atomic op type");
		xbValue val = xb_emit_conv(p, xb_build_expr(p, ce->args[1]), t);
		xbRmwOp op = xbRmw_Xchg;
		switch (id) {
		case BuiltinProc_atomic_add: case BuiltinProc_atomic_add_explicit: op = xbRmw_Add; break;
		case BuiltinProc_atomic_sub: case BuiltinProc_atomic_sub_explicit: op = xbRmw_Sub; break;
		case BuiltinProc_atomic_and: case BuiltinProc_atomic_and_explicit: op = xbRmw_And; break;
		case BuiltinProc_atomic_nand: case BuiltinProc_atomic_nand_explicit: op = xbRmw_Nand; break;
		case BuiltinProc_atomic_or: case BuiltinProc_atomic_or_explicit: op = xbRmw_Or; break;
		case BuiltinProc_atomic_xor: case BuiltinProc_atomic_xor_explicit: op = xbRmw_Xor; break;
		default: op = xbRmw_Xchg; break;
		}
		xbInstr i = xb_instr(xbOp_AtomicRmw, st);
		i.aux = op;
		i.a = xb_value_to_reg(p, val);
		i.mem = xb_mem(xbMem_Reg, xb_value_to_reg(p, dst), 0);
		i.dst = xb_new_vreg(p, st);
		xb_emit(p, i);
		return xb_value_reg(tv.type, i.dst);
	}
	case BuiltinProc_atomic_compare_exchange_strong:
	case BuiltinProc_atomic_compare_exchange_weak:
	case BuiltinProc_atomic_compare_exchange_strong_explicit:
	case BuiltinProc_atomic_compare_exchange_weak_explicit: {
		xbValue address = xb_build_expr(p, ce->args[0]);
		Type *elem = type_deref(address.type);
		xbType st = xb_scalar_type(elem);
		if (st == xbType_None) XB_UNSUPPORTED(p, "cas of aggregate");
		u32 oldv = xb_value_to_reg(p, xb_emit_conv(p, xb_build_expr(p, ce->args[1]), elem));
		u32 newv = xb_value_to_reg(p, xb_emit_conv(p, xb_build_expr(p, ce->args[2]), elem));
		xbType it = st;
		if (xb_type_is_float(st)) {
			it = st == xbType_F32 ? xbType_I32 : xbType_I64;
			oldv = xb_convop(p, xbOp_Bitcast, it, st, oldv);
			newv = xb_convop(p, xbOp_Bitcast, it, st, newv);
		}
		xbInstr i = xb_instr(xbOp_AtomicCas, it);
		i.a = oldv;
		i.b = newv;
		i.mem = xb_mem(xbMem_Reg, xb_value_to_reg(p, address), 0);
		i.dst = xb_new_vreg(p, it);
		i.c = xb_new_vreg(p, xbType_I8);
		xb_emit(p, i);
		u32 loaded = i.dst;
		if (it != st) loaded = xb_convop(p, xbOp_Bitcast, st, it, loaded);
		if (is_type_tuple(tv.type)) {
			xbMem m = xb_add_local(p, tv.type, false);
			Type *ft = nullptr;
			xb_store(p, st, xb_mem_offset(m, type_offset_of(tv.type, 0, &ft)), loaded);
			xb_store(p, xbType_I8, xb_mem_offset(m, type_offset_of(tv.type, 1, &ft)), i.c);
			return xb_value_mem(tv.type, m);
		}
		return xb_value_reg(tv.type, loaded);
	}
	case BuiltinProc_count_ones:
	case BuiltinProc_count_zeros:
	case BuiltinProc_count_trailing_zeros:
	case BuiltinProc_count_leading_zeros:
	case BuiltinProc_count_trailing_ones:
	case BuiltinProc_count_leading_ones: {
		Type *t = default_type(tv.type);
		if (xb_is_int128(t) && !is_type_different_to_arch_endianness(t)) {
			xbPair a = xb_pair_of(p, xb_emit_conv(p, xb_build_expr(p, ce->args[0]), t));
			if (id == BuiltinProc_count_trailing_ones || id == BuiltinProc_count_leading_ones) {
				a.lo = xb_unop(p, xbOp_Not, xbType_I64, a.lo);
				a.hi = xb_unop(p, xbOp_Not, xbType_I64, a.hi);
			}
			u32 r = 0;
			u32 zero = xb_i64(p, 0);
			switch (id) {
			case BuiltinProc_count_ones:
			case BuiltinProc_count_zeros:
				r = xb_binop(p, xbOp_Add, xbType_I64, xb_unop(p, xbOp_Popcount, xbType_I64, a.lo), xb_unop(p, xbOp_Popcount, xbType_I64, a.hi));
				if (id == BuiltinProc_count_zeros) r = xb_binop(p, xbOp_Sub, xbType_I64, xb_i64(p, 128), r);
				break;
			case BuiltinProc_count_trailing_zeros:
			case BuiltinProc_count_trailing_ones: {
				// the low half first, the high half once the low one is all zeros
				u32 lo_zero = xb_cmp(p, xbCond_EQ, xbType_I64, a.lo, zero);
				u32 high = xb_binop(p, xbOp_Add, xbType_I64, xb_i64(p, 64), xb_unop(p, xbOp_Ctz, xbType_I64, a.hi));
				r = xb_select(p, xbType_I64, lo_zero, high, xb_unop(p, xbOp_Ctz, xbType_I64, a.lo));
				break;
			}
			default: {
				u32 hi_zero = xb_cmp(p, xbCond_EQ, xbType_I64, a.hi, zero);
				u32 low = xb_binop(p, xbOp_Add, xbType_I64, xb_i64(p, 64), xb_unop(p, xbOp_Clz, xbType_I64, a.lo));
				r = xb_select(p, xbType_I64, hi_zero, low, xb_unop(p, xbOp_Clz, xbType_I64, a.hi));
				break;
			}
			}
			xbPair res = {r, zero};
			return xb_pair_value(p, t, res);
		}
		xbType st = xb_scalar_type(t);
		if (st == xbType_None || xb_type_is_float(st) || is_type_different_to_arch_endianness(t)) XB_UNSUPPORTED(p, "bit count type");
		u32 x = xb_value_to_reg(p, xb_emit_conv(p, xb_build_expr(p, ce->args[0]), t));
		if (id == BuiltinProc_count_trailing_ones || id == BuiltinProc_count_leading_ones) {
			x = xb_unop(p, xbOp_Not, st, x);
		}
		xbOp op = xbOp_Popcount;
		switch (id) {
		case BuiltinProc_count_ones: case BuiltinProc_count_zeros: op = xbOp_Popcount; break;
		case BuiltinProc_count_trailing_zeros: case BuiltinProc_count_trailing_ones: op = xbOp_Ctz; break;
		default: op = xbOp_Clz; break;
		}
		u32 r = xb_unop(p, op, st, x);
		u32 res = r;
		if (id == BuiltinProc_count_zeros) {
			res = xb_binop(p, xbOp_Sub, st, xb_iconst(p, st, 8*xb_type_size(st)), r);
		}
		return xb_value_reg(t, res);
	}
	case BuiltinProc_swizzle: {
		if (is_type_simd_vector(tv.type)) XB_UNSUPPORTED(p, "builtin swizzle");
		// the selected elements of the array, gathered
		xbAddr a = xb_build_addr(p, ce->args[0]);
		if (a.kind != xbAddr_Default) XB_UNSUPPORTED(p, "swizzle of special addr");
		Type *elem = base_array_type(tv.type);
		i64 stride = type_size_of(elem);
		xbMem res = xb_add_local(p, tv.type, false);
		for (isize i = 1; i < ce->args.count; i++) {
			i64 index = exact_value_to_i64(ce->args[i]->tav.value);
			xb_store_value(p, xb_mem_offset(res, (i-1)*stride), xb_load_value(p, elem, xb_mem_offset(a.mem, index*stride)));
		}
		return xb_value_mem(tv.type, res);
	}
	case BuiltinProc_transpose:
		return xb_emit_matrix_transpose(p, xb_build_expr(p, ce->args[0]), tv.type);
	case BuiltinProc_outer_product:
		return xb_emit_outer_product(p, xb_build_expr(p, ce->args[0]), xb_build_expr(p, ce->args[1]), tv.type);
	case BuiltinProc_hadamard_product: {
		xbValue a = xb_build_expr(p, ce->args[0]);
		xbValue b = xb_build_expr(p, ce->args[1]);
		if (is_type_array(tv.type)) return xb_emit_arith(p, Token_Mul, a, b, tv.type);
		return xb_emit_arith_matrix(p, Token_Mul, a, b, tv.type, true);
	}
	case BuiltinProc_matrix_flatten: {
		xbValue m = xb_build_expr(p, ce->args[0]);
		if (is_type_array(m.type)) {
			m.type = tv.type;
			return m;
		}
		xbValue r = xb_value_copy_to_temp(p, m);
		r.type = tv.type;
		return r;
	}
	case BuiltinProc_reverse_bits: {
		// llvm.bitreverse: swap the bytes, then the bits within each byte
		Type *t = default_type(tv.type);
		xbValue x = xb_emit_conv(p, xb_build_expr(p, ce->args[0]), t);
		auto rev = [&](xbType st, u32 r) -> u32 {
			if (xb_type_size(st) > 1) r = xb_unop(p, xbOp_Bswap, st, r);
			static u64 const masks[3] = {0x5555555555555555ull, 0x3333333333333333ull, 0x0f0f0f0f0f0f0f0full};
			for (i64 i = 0; i < 3; i++) {
				u64 bits = xb_type_size(st) == 8 ? masks[i] : masks[i] & ((1ull << (8*xb_type_size(st))) - 1);
				u32 m = xb_iconst(p, st, cast(i64)bits);
				u32 sh = xb_iconst(p, st, 1ll << i);
				u32 lo = xb_binop(p, xbOp_Shl, st, xb_binop(p, xbOp_And, st, r, m), sh);
				u32 hi = xb_binop(p, xbOp_And, st, xb_binop(p, xbOp_LShr, st, r, sh), m);
				r = xb_binop(p, xbOp_Or, st, lo, hi);
			}
			return r;
		};
		if (xb_is_int128(t)) {
			xbPair a = xb_pair_of(p, x);
			xbPair r = {rev(xbType_I64, a.hi), rev(xbType_I64, a.lo)};
			return xb_pair_value(p, t, r);
		}
		xbType st = xb_scalar_type(t);
		if (st == xbType_None || xb_type_is_float(st)) XB_UNSUPPORTED(p, "reverse_bits type");
		return xb_value_reg(t, rev(st, xb_value_to_reg(p, x)));
	}
	case BuiltinProc_byte_swap: {
		Type *t = default_type(tv.type);
		if (xb_is_int128(t)) {
			return xb_byte_swap(p, xb_emit_conv(p, xb_build_expr(p, ce->args[0]), t), t);
		}
		xbType st = xb_scalar_type(t);
		if (st == xbType_None) XB_UNSUPPORTED(p, "byte_swap type");
		xbValue x = xb_emit_conv(p, xb_build_expr(p, ce->args[0]), t);
		if (xb_type_size(st) == 1) return x;
		u32 r = xb_value_to_reg(p, x);
		xbType it = st;
		if (xb_type_is_float(st)) {
			it = st == xbType_F32 ? xbType_I32 : xbType_I64;
			r = xb_convop(p, xbOp_Bitcast, it, st, r);
		}
		u32 sw = xb_unop(p, xbOp_Bswap, it, r);
		if (it != st) sw = xb_convop(p, xbOp_Bitcast, st, it, sw);
		return xb_value_reg(t, sw);
	}
	case BuiltinProc_overflow_add:
	case BuiltinProc_overflow_sub:
	case BuiltinProc_overflow_mul: {
		Type *main_type = tv.type;
		Type *type = main_type;
		if (is_type_tuple(main_type)) {
			type = main_type->Tuple.variables[0]->type;
		}
		xbType st = xb_scalar_type(type);
		if (st == xbType_None || is_type_different_to_arch_endianness(type)) XB_UNSUPPORTED(p, "overflow op type");
		bool sgn = !is_type_unsigned(type);
		u32 x = xb_value_to_reg(p, xb_emit_conv(p, xb_build_expr(p, ce->args[0]), type));
		u32 y = xb_value_to_reg(p, xb_emit_conv(p, xb_build_expr(p, ce->args[1]), type));
		u32 res = 0;
		u32 ovf = 0;
		if (id == BuiltinProc_overflow_add) {
			res = xb_binop(p, xbOp_Add, st, x, y);
			if (sgn) {
				u32 t1 = xb_binop(p, xbOp_And, st, xb_binop(p, xbOp_Xor, st, x, res), xb_binop(p, xbOp_Xor, st, y, res));
				ovf = xb_cmp(p, xbCond_SLT, st, t1, xb_iconst(p, st, 0));
			} else {
				ovf = xb_cmp(p, xbCond_ULT, st, res, x);
			}
		} else if (id == BuiltinProc_overflow_sub) {
			res = xb_binop(p, xbOp_Sub, st, x, y);
			if (sgn) {
				u32 t1 = xb_binop(p, xbOp_And, st, xb_binop(p, xbOp_Xor, st, x, y), xb_binop(p, xbOp_Xor, st, x, res));
				ovf = xb_cmp(p, xbCond_SLT, st, t1, xb_iconst(p, st, 0));
			} else {
				ovf = xb_cmp(p, xbCond_ULT, st, x, y);
			}
		} else {
			if (xb_type_size(st) >= 4) {
				xbInstr i = xb_instr(xbOp_MulOvf, st);
				i.aux = sgn ? 1 : 0;
				i.a = x;
				i.b = y;
				i.dst = xb_new_vreg(p, st);
				i.c = xb_new_vreg(p, xbType_I8);
				xb_emit(p, i);
				res = i.dst;
				ovf = i.c;
			} else {
				// multiply in 32 bits and check the result fits
				u32 wx = xb_int_resize(p, x, st, xbType_I32, sgn);
				u32 wy = xb_int_resize(p, y, st, xbType_I32, sgn);
				u32 wp = xb_binop(p, xbOp_Mul, xbType_I32, wx, wy);
				res = xb_int_resize(p, wp, xbType_I32, st, sgn);
				u32 back = xb_int_resize(p, res, st, xbType_I32, sgn);
				ovf = xb_cmp(p, xbCond_NE, xbType_I32, back, wp);
			}
		}
		if (!is_type_tuple(main_type)) {
			return xb_value_reg(type, res);
		}
		xbMem m = xb_add_local(p, main_type, false);
		Type *ft = nullptr;
		xb_store(p, st, xb_mem_offset(m, type_offset_of(main_type, 0, &ft)), res);
		xb_store(p, xbType_I8, xb_mem_offset(m, type_offset_of(main_type, 1, &ft)), ovf);
		return xb_value_mem(main_type, m);
	}
	case BuiltinProc_saturating_add:
	case BuiltinProc_saturating_sub: {
		Type *t = tv.type;
		xbType st = xb_scalar_type(t);
		if (st == xbType_None || is_type_different_to_arch_endianness(t)) XB_UNSUPPORTED(p, "saturating op type");
		u32 x = xb_value_to_reg(p, xb_emit_conv(p, xb_build_expr(p, ce->args[0]), t));
		u32 y = xb_value_to_reg(p, xb_emit_conv(p, xb_build_expr(p, ce->args[1]), t));
		return xb_value_reg(t, xb_simd_saturate(p, id == BuiltinProc_saturating_add, !is_type_unsigned(t), st, x, y));
	}
	case BuiltinProc_fixed_point_mul:
	case BuiltinProc_fixed_point_div:
	case BuiltinProc_fixed_point_mul_sat:
	case BuiltinProc_fixed_point_div_sat:
		return xb_build_fixed_point(p, ce, tv.type, id);
	case BuiltinProc_c_va_start:
		xb_build_c_va_start(p, ce);
		return {};
	case BuiltinProc_c_va_end:
		// nothing to release on any target
		xb_build_expr(p, ce->args[0]);
		return {};
	case BuiltinProc_c_va_copy: {
		u32 dst = xb_value_to_reg(p, xb_build_expr(p, ce->args[0]));
		u32 src = xb_value_to_reg(p, xb_build_expr(p, ce->args[1]));
		xb_memcopy(p, xb_mem(xbMem_Reg, dst, 0), xb_mem(xbMem_Reg, src, 0), type_size_of(t_c_va_list));
		return {};
	}
	case BuiltinProc_c_va_arg:
		return xb_build_c_va_arg(p, ce, type_of_expr(ce->args[1]));
	case BuiltinProc_expand_values: {
		xbValue v = xb_build_expr(p, ce->args[0]);
		Type *t = base_type(v.type);
		xbMem src = xb_value_to_mem(p, v);
		Type *rt = tv.type;
		auto field = [&](isize i, Type **ft) -> i64 {
			if (t->kind == Type_Struct) {
				return type_offset_of(t, t->Struct.fields[i]->Variable.field_index, ft);
			}
			GB_ASSERT(is_type_array_like(t));
			*ft = base_array_type(t);
			return i * type_size_of(*ft);
		};
		if (!is_type_tuple(rt)) {
			Type *ft = nullptr;
			i64 off = field(0, &ft);
			return xb_load_value(p, ft, xb_mem_offset(src, off));
		}
		xbMem dst = xb_add_local(p, rt, false);
		for_array(i, rt->Tuple.variables) {
			Type *ft = nullptr;
			i64 off = field(i, &ft);
			Type *et = nullptr;
			i64 dst_off = type_offset_of(rt, i, &et);
			xb_store_value(p, xb_mem_offset(dst, dst_off), xb_load_value(p, ft, xb_mem_offset(src, off)));
		}
		return xb_value_mem(rt, dst);
	}
	case BuiltinProc_compress_values: {
		auto values = array_make<xbValue>(xb_allocator(), 0, ce->args.count);
		for (Ast *arg : ce->args) {
			xb_add_values_to_array(p, &values, xb_build_expr(p, arg));
		}
		if (values.count == 1) {
			return xb_emit_conv(p, values[0], tv.type);
		}
		Type *dt = base_type(tv.type);
		xbMem dst = xb_add_local(p, tv.type, true);
		for_array(i, values) {
			Type *ft = nullptr;
			i64 off = 0;
			if (is_type_struct(dt) || is_type_tuple(dt)) {
				off = type_offset_of(dt, cast(i32)i, &ft);
			} else if (is_type_array_like(dt)) {
				ft = base_array_type(dt);
				off = i * type_size_of(ft);
			} else {
				XB_UNSUPPORTED(p, "compress_values type");
			}
			xb_store_value(p, xb_mem_offset(dst, off), xb_emit_conv(p, values[i], ft));
		}
		return xb_value_mem(tv.type, dst);
	}
	case BuiltinProc_sqrt: {
		Type *t = default_type(tv.type);
		xbType st = xb_scalar_type(t);
		if (xb_is_f16(t)) {
			// in f32, which rounds to the same f16
			xbValue x = xb_f16_to_f32(p, xb_emit_conv(p, xb_build_expr(p, ce->args[0]), t));
			return xb_float_to_f16(p, xb_value_reg(t_f32, xb_unop(p, xbOp_Sqrt, xbType_F32, xb_value_to_reg(p, x))), t);
		}
		if (!xb_type_is_float(st)) XB_UNSUPPORTED(p, "sqrt type");
		u32 x = xb_value_to_reg(p, xb_emit_conv(p, xb_build_expr(p, ce->args[0]), t));
		return xb_value_reg(t, xb_unop(p, xbOp_Sqrt, st, x));
	}
	case BuiltinProc_read_cycle_counter: {
		xbInstr i = xb_instr(xbOp_ReadCycleCounter, xbType_I64);
		i.dst = xb_new_vreg(p, xbType_I64);
		xb_emit(p, i);
		return xb_value_reg(tv.type, i.dst);
	}
	case BuiltinProc_read_cycle_counter_frequency: {
		// LLVM's only has an arm64 form
		if (!xb_is_arm64()) XB_UNSUPPORTED(p, "cycle counter frequency");
		xbInstr i = xb_instr(xbOp_ReadCycleCounter, xbType_I64);
		i.imm = 1;
		i.dst = xb_new_vreg(p, xbType_I64);
		xb_emit(p, i);
		return xb_value_reg(tv.type, i.dst);
	}
	case BuiltinProc_cpu_relax:
		xb_emit(p, xb_instr(xbOp_CpuRelax));
		return {};
	case BuiltinProc_x86_cpuid:
	case BuiltinProc_x86_xgetbv: {
		if (xb_is_arm64()) XB_UNSUPPORTED(p, "x86 builtin on arm64");
		bool cpuid = id == BuiltinProc_x86_cpuid;
		Type *rt = tv.type;
		if (type_size_of(rt) != (cpuid ? 16 : 8)) XB_UNSUPPORTED(p, "cpuid result type");
		xbInstr i = xb_instr(cpuid ? xbOp_Cpuid : xbOp_Xgetbv);
		i.a = xb_value_to_reg(p, xb_emit_conv(p, xb_build_expr(p, ce->args[0]), t_u32));
		if (cpuid) {
			i.b = xb_value_to_reg(p, xb_emit_conv(p, xb_build_expr(p, ce->args[1]), t_u32));
		}
		i.mem = xb_add_local(p, rt, false);
		xb_emit(p, i);
		return xb_value_mem(rt, i.mem);
	}
	case BuiltinProc_valgrind_client_request: {
		u32 args[7] = {};
		for (isize k = 0; k < 7; k++) {
			args[k] = xb_value_to_reg(p, xb_emit_conv(p, xb_build_expr(p, ce->args[k]), t_uintptr));
		}
		if (!build_context.ODIN_VALGRIND_SUPPORT) {
			return xb_value_reg(t_uintptr, args[0]);
		}
		if (xb_is_arm64()) XB_UNSUPPORTED(p, "valgrind on arm64");
		xbMem array = xb_mem(xbMem_Local, cast(u32)xb_add_local_raw(p, 6*8, 8));
		for (isize k = 0; k < 6; k++) {
			xb_store(p, xbType_I64, xb_mem_offset(array, k*8), args[k+1]);
		}
		xbInstr i = xb_instr(xbOp_Valgrind, xbType_I64);
		i.a = args[0];
		i.b = xb_lea(p, array);
		i.dst = xb_new_vreg(p, xbType_I64);
		xb_emit(p, i);
		return xb_value_reg(t_uintptr, i.dst);
	}
	case BuiltinProc_alloca: {
		u32 size = xb_value_to_reg(p, xb_emit_conv(p, xb_build_expr(p, ce->args[0]), t_int));
		i64 align = exact_value_to_i64(type_and_value_of_expr(ce->args[1]).value);
		xbInstr i = xb_instr(xbOp_Alloca, xbType_I64);
		i.a = size;
		i.imm = gb_max(align, cast(i64)16);
		i.dst = xb_new_vreg(p, xbType_I64);
		xb_emit(p, i);
		return xb_value_reg(tv.type, i.dst);
	}
	case BuiltinProc_stack_pointer: {
		xbInstr i = xb_instr(xbOp_StackPointer, xbType_I64);
		i.dst = xb_new_vreg(p, xbType_I64);
		xb_emit(p, i);
		return xb_value_reg(tv.type, i.dst);
	}
	case BuiltinProc_frame_address:
	case BuiltinProc_return_address: {
		i64 level = 0;
		if (ce->args.count > 0) {
			TypeAndValue ltv = type_and_value_of_expr(ce->args[0]);
			if (ltv.mode != Addressing_Constant) XB_UNSUPPORTED(p, "non-constant frame level");
			level = exact_value_to_i64(ltv.value);
		}
		if (id == BuiltinProc_return_address && level == 0) {
			// found from the frame layout: a Win64 prologue pushes more than rbp
			xbInstr i = xb_instr(xbOp_ReturnAddress, xbType_I64);
			i.dst = xb_new_vreg(p, xbType_I64);
			xb_emit(p, i);
			return xb_value_reg(tv.type, i.dst);
		}
		// a Win64 frame does not start with the saved rbp
		if (level > 0 && xb_is_win64()) XB_UNSUPPORTED(p, "frame level on windows");
		// walk the saved frame pointers
		xbInstr i = xb_instr(xbOp_FrameAddress, xbType_I64);
		i.dst = xb_new_vreg(p, xbType_I64);
		xb_emit(p, i);
		u32 fa = i.dst;
		for (i64 k = 0; k < level; k++) {
			fa = xb_load(p, xbType_I64, xb_mem(xbMem_Reg, fa, 0));
		}
		if (id == BuiltinProc_frame_address) {
			return xb_value_reg(tv.type, fa);
		}
		return xb_value_reg(tv.type, xb_load(p, xbType_I64, xb_mem(xbMem_Reg, fa, 8)));
	}
	case BuiltinProc_address_of_return_address: {
		xbInstr i = xb_instr(xbOp_ReturnAddress, xbType_I64);
		i.imm = 1; // the slot's address
		i.dst = xb_new_vreg(p, xbType_I64);
		xb_emit(p, i);
		return xb_value_reg(tv.type, i.dst);
	}
	case BuiltinProc_expect:
	case BuiltinProc_likely:
	case BuiltinProc_unlikely:
		return xb_emit_conv(p, xb_build_expr(p, ce->args[0]), default_type(tv.type));
	case BuiltinProc_prefetch_read_instruction:
	case BuiltinProc_prefetch_read_data:
	case BuiltinProc_prefetch_write_instruction:
	case BuiltinProc_prefetch_write_data:
		xb_build_expr(p, ce->args[0]);
		return {};
	case BuiltinProc_syscall: {
		if (ce->args.count > 7) XB_UNSUPPORTED(p, "syscall arg count");
		if (xb_is_win64()) XB_UNSUPPORTED(p, "syscall on windows");
		u8 const x86_regs[7] = {RAX, RDI, RSI, RDX, R10, R8, R9};
		u8 const darwin_arm64_regs[7] = {16, 0, 1, 2, 3, 4, 5};
		u8 const linux_arm64_regs[7] = {8, 0, 1, 2, 3, 4, 5};
		u8 const *regs = !xb_is_arm64() ? x86_regs : xb_is_darwin() ? darwin_arm64_regs : linux_arm64_regs;
		auto args = array_make<xbCallArg>(xb_allocator(), 0, ce->args.count);
		for_array(i, ce->args) {
			xbValue v = xb_emit_conv(p, xb_build_expr(p, ce->args[i]), t_uintptr);
			xbCallArg a = {};
			a.kind = xbCallArg_Gpr;
			a.type = xbType_I64;
			a.size = 8;
			a.reg = regs[i];
			a.vreg = xb_value_to_reg(p, v);
			array_add(&args, a);
		}
		xbCall c = {};
		c.target_sym = -1;
		c.args = slice_from_array(args);
		c.sse_count = -1;
		c.result_vreg = xb_new_vreg(p, xbType_I64);
		array_add(&p->calls, c);
		xbInstr i = xb_instr(xbOp_Syscall);
		i.imm = p->calls.count-1;
		xb_emit(p, i);
		return xb_value_reg(t_uintptr, c.result_vreg);
	}
	case BuiltinProc_constant_utf16_cstring: {
		// encoded like the LLVM backend's, invalid runes become U+FFFD
		String value = type_and_value_of_expr(ce->args[0]).value.value_string;
		auto buf = array_make<u16>(xb_allocator(), 0, value.len + 1);
		while (value.len > 0) {
			Rune r = 0;
			isize w = gb_utf8_decode(value.text, value.len, &r);
			value.text += w;
			value.len  -= w;
			if ((0 <= r && r < 0xd800) || (0xe000 <= r && r < 0x10000)) {
				array_add(&buf, cast(u16)r);
			} else if (0x10000 <= r && r <= 0x10ffff) {
				r -= 0x10000;
				array_add(&buf, cast(u16)(0xd800 + ((r>>10)&0x3ff)));
				array_add(&buf, cast(u16)(0xdc00 + (r&0x3ff)));
			} else {
				array_add(&buf, cast(u16)0xfffd);
			}
		}
		array_add(&buf, cast(u16)0);
		i32 sym = xb_rodata(p->m, buf.data, buf.count*2, 2);
		return xb_value_reg(default_type(tv.type), xb_lea(p, xb_mem(xbMem_Sym, cast(u32)sym)));
	}
	case BuiltinProc_type_map_info: {
		i32 sym = xb_map_info_sym(p, ce->args[0]->tav.type);
		return xb_value_reg(t_map_info_ptr, xb_lea(p, xb_mem(xbMem_Sym, cast(u32)sym)));
	}
	case BuiltinProc_type_map_cell_info: {
		i32 sym = xb_map_cell_info_sym(p->m, ce->args[0]->tav.type);
		return xb_value_reg(t_map_cell_info_ptr, xb_lea(p, xb_mem(xbMem_Sym, cast(u32)sym)));
	}
	case BuiltinProc_type_hasher_proc: {
		i32 sym = xb_hasher_proc_sym(p, ce->args[0]->tav.type);
		return xb_value_reg(t_hasher_proc, xb_lea(p, xb_mem(xbMem_Sym, cast(u32)sym)));
	}
	case BuiltinProc_type_equal_proc: {
		i32 sym = xb_equal_proc_sym(p, ce->args[0]->tav.type);
		return xb_value_reg(t_equal_proc, xb_lea(p, xb_mem(xbMem_Sym, sym)));
	}
	case BuiltinProc_typeid_of: {
		Ast *arg = ce->args[0];
		TypeAndValue atv = type_and_value_of_expr(arg);
		if (atv.mode == Addressing_Type) {
			return xb_typeid_value(p, atv.type);
		}
		XB_UNSUPPORTED(p, "typeid_of value");
	}
	case BuiltinProc_DIRECTIVE: {
		ast_node(bd, BasicDirective, ce->proc);
		String name = bd->name.string;
		if (name == "location") {
			String procedure = {};
			if (p->entity != nullptr) procedure = p->entity->token.string;
			TokenPos pos = ast_token(ce->proc).pos;
			if (ce->args.count > 0) {
				Ast *ident = unselector_expr(ce->args[0]);
				GB_ASSERT(ident->kind == Ast_Ident);
				Entity *e = entity_of_node(ident);
				GB_ASSERT(e != nullptr);
				if (e->parent_proc_decl.load() != nullptr && e->parent_proc_decl.load()->entity != nullptr) {
					procedure = e->parent_proc_decl.load()->entity.load()->token.string;
				} else {
					procedure = str_lit("");
				}
				pos = e->token.pos;
			}
			return xb_source_code_location(p, procedure, pos);
		}
		if (name == "load_directory") {
			// a constant array of {name, data} for the files
			LoadDirectoryCache *cache = map_must_get(&p->m->info->load_directory_map, expr);
			isize count = cache->files.count;
			Type *array_type = alloc_type_array(t_load_directory_file, count);
			i64 size = type_size_of(array_type);
			xbConstBuf b = {};
			b.m = p->m;
			b.bytes = array_make<u8>(heap_allocator(), size, size);
			gb_zero_size(b.bytes.data, size);
			b.relocs = array_make<xbReloc>(heap_allocator(), 0, 2*count);
			defer (array_free(&b.bytes));
			defer (array_free(&b.relocs));
			i64 stride = type_size_of(t_load_directory_file);
			for_array(i, cache->files) {
				LoadFileCache *file = cache->files[i];
				Type *ft = nullptr;
				i64 name_off = type_offset_of(t_load_directory_file, 0, &ft);
				i64 data_off = type_offset_of(t_load_directory_file, 1, &ft);
				xb_cb_write(&b, t_string, exact_value_string(filename_without_directory(file->path)), i*stride + name_off);
				xb_cb_write(&b, t_u8_slice, exact_value_string(file->data), i*stride + data_off);
			}
			i32 sym = xb_const_place(&b, type_align_of(array_type));
			return xb_make_slice_value(p, tv.type, xb_lea(p, xb_mem(xbMem_Sym, cast(u32)sym)), xb_iconst(p, xbType_I64, count));
		}
		XB_UNSUPPORTED(p, "directive");
	}
	case BuiltinProc___entry_point:
		if (p->m->info->entry_point) {
			xbValue ep = xb_proc_value_from_entity(p, p->m->info->entry_point);
			xb_emit_call(p, ep, {}, nullptr);
		}
		return {};
	case BuiltinProc_trap:
		xb_emit(p, xb_instr(xbOp_Trap));
		xb_unreachable(p);
		return {};
	case BuiltinProc_debug_trap:
		xb_emit(p, xb_instr(xbOp_DebugTrap));
		return {};
	case BuiltinProc_unreachable:
		xb_emit(p, xb_instr(xbOp_Trap));
		xb_unreachable(p);
		return {};
	case BuiltinProc_soa_zip:
		return xb_build_soa_zip(p, ce, tv);
	case BuiltinProc_soa_unzip:
		return xb_build_soa_unzip(p, ce, tv);
	case BuiltinProc_soa_copy_from_slice:
		xb_build_soa_copy_from_slice(p, ce);
		return {};
	}
	{
		gbString r = gb_string_make(permanent_allocator(), "builtin ");
		r = gb_string_append_length(r, builtin_procs[id].name.text, builtin_procs[id].name.len);
		XB_UNSUPPORTED(p, r);
	}
	return {};
}

////////////////////////////////////////////////////////////////
// Unions
////////////////////////////////////////////////////////////////

// the union part of lb_emit_conv
gb_internal xbValue xb_union_conv(xbProc *p, xbValue v, Type *t, bool *ok) {
	Type *dst = core_type(t);
	Type *src_type = v.type;
	*ok = true;
	if (dst->Union.variants.count == 1) {
		Type *vt = dst->Union.variants[0];
		if (internal_check_is_assignable_to(src_type, vt)) {
			return xb_emit_union_wrap(p, t, vt, xb_emit_conv(p, v, vt));
		}
	}
	for (Type *vt : dst->Union.variants) {
		if (src_type == t_llvm_bool && is_type_boolean(vt)) {
			return xb_emit_union_wrap(p, t, vt, v);
		}
		if (are_types_identical(src_type, vt)) {
			return xb_emit_union_wrap(p, t, vt, v);
		}
	}
	isize valid_count = 0;
	isize first = -1;
	for_array(i, dst->Union.variants) {
		if (internal_check_is_assignable_to(src_type, dst->Union.variants[i])) {
			valid_count += 1;
			if (first < 0) first = i;
		}
	}
	if (valid_count >= 1) {
		// all scores are equal, so the first one wins
		Type *vt = dst->Union.variants[first];
		return xb_emit_union_wrap(p, t, vt, xb_emit_conv(p, v, vt));
	}
	*ok = false;
	return {};
}

gb_internal xbValue xb_emit_union_wrap(xbProc *p, Type *union_type, Type *variant, xbValue v) {
	Type *ut = base_type(union_type);
	GB_ASSERT(ut->kind == Type_Union);
	xbMem m = xb_add_local(p, union_type, true);
	if (type_size_of(variant) != 0) {
		xb_store_value(p, m, xb_emit_conv(p, v, variant));
	}
	if (is_type_union_maybe_pointer(ut)) {
		return xb_value_mem(union_type, m);
	}
	i64 tag = union_variant_index_checked(ut, variant);
	Type *tag_type = union_tag_type(ut);
	xbType tt = xb_scalar_type(tag_type);
	u32 tag_reg = xb_iconst(p, tt, tag);
	if (ut->Union.kind == UnionType_shared_nil) {
		// a nil variant makes the whole union nil
		xbValue vv = xb_emit_conv(p, v, variant);
		u32 is_nil = xb_value_to_reg(p, xb_emit_comp_against_nil(p, Token_CmpEq, vv));
		tag_reg = xb_select(p, tt, is_nil, xb_iconst(p, tt, 0), tag_reg);
	}
	xb_store(p, tt, xb_mem_offset(m, ut->Union.variant_block_size), tag_reg);
	return xb_value_mem(union_type, m);
}

////////////////////////////////////////////////////////////////
// Statements
////////////////////////////////////////////////////////////////

gb_internal void xb_build_stmt(xbProc *p, Ast *node);
gb_internal void xb_emit_defer_stmts(xbProc *p, bool is_return, xbBlock *branch_target, TokenPos pos);

gb_internal void xb_set_debug_scope(xbProc *p, i32 scope) {
	p->debug_scope = scope;
	xbInstr i = xb_instr(xbOp_Scope);
	i.imm = scope;
	xb_emit(p, i);
}

gb_internal void xb_open_scope(xbProc *p) {
	p->scope_index += 1;
	array_add(&p->debug_scope_parent, p->debug_scope);
	xb_set_debug_scope(p, cast(i32)p->debug_scope_parent.count-1);
}

gb_internal void xb_build_defer_stmt(xbProc *p, xbDefer const &d);

// The position #branch_location reports for the defers run when leaving at `node`, as LLVM picks it
gb_internal TokenPos xb_defer_pos(Ast *node) {
	if (node == nullptr) return {};
	if (node->kind == Ast_BlockStmt || node->kind == Ast_CaseClause) {
		return ast_end_token(node).pos;
	}
	return ast_token(node).pos;
}

gb_internal void xb_close_scope(xbProc *p, Ast *node) {
	TokenPos prev_pos = p->branch_location_pos;
	p->branch_location_pos = xb_defer_pos(node);
	defer (p->branch_location_pos = prev_pos);
	// run the defers of this scope
	while (p->defers.count > 0) {
		xbDefer d = p->defers[p->defers.count-1];
		if (d.scope_index != p->scope_index) break;
		array_pop(&p->defers);
		xb_build_defer_stmt(p, d);
	}
	while (p->context_stack.count > 0) {
		xbContextEntry *ctx = &p->context_stack[p->context_stack.count-1];
		if (ctx->scope_index >= p->scope_index) {
			array_pop(&p->context_stack);
		} else {
			break;
		}
	}
	p->scope_index -= 1;
	xb_set_debug_scope(p, p->debug_scope_parent[p->debug_scope]);
}

gb_internal void xb_build_defer_stmt(xbProc *p, xbDefer const &d) {
	if (xb_curr_terminated(p)) return;
	isize prev = p->context_stack.count;
	// the context stack only grows within a scope, so the old entries are still there
	p->context_stack.count = gb_min(d.context_stack_count, prev);
	if (d.is_proc) {
		xb_set_debug_loc(p, d.pos);
		Type *pt = base_type(d.proc.type);
		auto args = array_make<xbValue>(xb_allocator(), 0, d.args.count);
		isize j = 0;
		for (Entity *param : pt->Proc.params->Tuple.variables) {
			if (param->kind != Entity_Variable) continue;
			if (j < d.args.count) array_add(&args, xb_emit_conv(p, d.args[j++], param->type));
		}
		xb_emit_call_entity(p, d.proc_entity, d.proc, slice_from_array(args), nullptr);
		array_free(&args);
	} else {
		xb_build_stmt(p, d.stmt);
	}
	p->context_stack.count = prev;
}

gb_internal void xb_emit_defer_stmts(xbProc *p, bool is_return, xbBlock *branch_target, TokenPos pos) {
	TokenPos prev_pos = p->branch_location_pos;
	p->branch_location_pos = pos;
	defer (p->branch_location_pos = prev_pos);
	isize i = p->defers.count;
	while (i --> 0) {
		xbDefer const &d = p->defers[i];
		if (is_return) {
			xb_build_defer_stmt(p, d);
		} else {
			GB_ASSERT(branch_target != nullptr);
			if (branch_target->scope_index < d.scope_index) {
				xb_build_defer_stmt(p, d);
			}
		}
	}
}

gb_internal xbTargetList *xb_push_target_list(xbProc *p, Ast *label, xbBlock *break_, xbBlock *continue_, xbBlock *fallthrough_) {
	xbTargetList *tl = xb_alloc_item<xbTargetList>();
	tl->prev = p->targets;
	tl->break_ = break_;
	tl->continue_ = continue_;
	tl->fallthrough_ = fallthrough_;
	p->targets = tl;
	if (label != nullptr) {
		for (xbBranchBlocks &b : p->branch_blocks) {
			if (b.label == label) {
				b.break_ = break_;
				b.continue_ = continue_;
				return tl;
			}
		}
		GB_PANIC("unknown label");
	}
	return tl;
}

gb_internal void xb_pop_target_list(xbProc *p) {
	p->targets = p->targets->prev;
}

gb_internal xbBranchBlocks xb_lookup_branch_blocks(xbProc *p, Ast *ident) {
	Entity *e = entity_of_node(ident);
	GB_ASSERT(e->kind == Entity_Label);
	for (xbBranchBlocks const &b : p->branch_blocks) {
		if (b.label == e->Label.node) {
			return b;
		}
	}
	GB_PANIC("unreachable");
	return {};
}

gb_internal void xb_add_debug_var(xbProc *p, Entity *e, xbMem mem, bool by_ref, bool is_param) {
	if (e == nullptr || mem.kind != xbMem_Local) return;
	if (e->token.string.len == 0 || is_blank_ident(e->token.string)) return;
	xbDebugVar v = {};
	v.name = e->token.string;
	v.type = e->type;
	v.local = cast(i32)mem.base;
	v.frame_offset_fixup = mem.offset;
	v.by_ref = by_ref;
	v.is_param = is_param;
	v.line = e->token.pos.line;
	v.scope = p->debug_scope;
	array_add(&p->debug_vars, v);
}

gb_internal xbMem xb_add_local_entity(xbProc *p, Entity *e, bool zero) {
	i64 align = type_align_of(e->type);
	if (e->kind == Entity_Variable && e->Variable.custom_align > align) {
		align = e->Variable.custom_align;
	}
	i32 l = xb_add_local_raw(p, type_size_of(e->type), align);
	xbMem m = xb_mem(xbMem_Local, cast(u32)l);
	if (zero) {
		xb_memzero(p, m, type_size_of(e->type));
	}
	xbVar v = {};
	v.mem = m;
	map_set(&p->vars, e, v);
	xb_add_debug_var(p, e, m, false, false);
	return m;
}

gb_internal void xb_build_stmt_list(xbProc *p, Slice<Ast *> const &stmts);

gb_internal void xb_build_when_stmt(xbProc *p, AstWhenStmt *ws) {
	TypeAndValue tv = type_and_value_of_expr(ws->cond);
	GB_ASSERT(tv.value.kind == ExactValue_Bool);
	if (tv.value.value_bool) {
		xb_build_stmt_list(p, ws->body->BlockStmt.stmts);
	} else if (ws->else_stmt) {
		switch (ws->else_stmt->kind) {
		case Ast_BlockStmt:
			xb_build_stmt_list(p, ws->else_stmt->BlockStmt.stmts);
			break;
		case Ast_WhenStmt:
			xb_build_when_stmt(p, &ws->else_stmt->WhenStmt);
			break;
		}
	}
}

gb_internal void xb_check_nested_decls(xbProc *p, Slice<Ast *> const &stmts) {
	for (Ast *stmt : stmts) {
		if (stmt->kind == Ast_ValueDecl) {
			ast_node(vd, ValueDecl, stmt);
			if (vd->is_mutable) continue;
			for_array(i, vd->names) {
				Entity *e = entity_of_node(vd->names[i]);
				if (e == nullptr || e->kind != Entity_Procedure) continue;
				Ast *value = unparen_expr(vd->values[i]);
				if (value->kind != Ast_ProcLit) continue;
				if (value->ProcLit.body == nullptr) continue;
				// they belong to the family of the procedure they are declared in, which emits them
				if (p->inl != nullptr) continue;
				GenProcsData *gpd = e->Procedure.gen_procs;
				if (gpd != nullptr) {
					rw_mutex_shared_lock(&gpd->mutex);
					auto procs = array_clone(heap_allocator(), gpd->procs);
					rw_mutex_shared_unlock(&gpd->mutex);
					array_sort(procs, lb_polymorphic_instance_cmp);
					for (Entity *inst : procs) {
						if (inst->min_dep_count.load(std::memory_order_relaxed) == 0) continue;
						if ((inst->flags & EntityFlag_ProcBodyChecked) == 0) continue;
						Type *bt = base_type(inst->type);
						if (bt->Proc.is_polymorphic && !bt->Proc.is_poly_specialized) continue;
						xb_family_add(p->family, inst);
					}
					array_free(&procs);
					continue;
				}
				if (e->min_dep_count.load(std::memory_order_relaxed) == 0) continue;
				if ((e->flags & EntityFlag_ProcBodyChecked) == 0) continue;
				xb_family_add(p->family, e);
			}
		} else if (stmt->kind == Ast_ForeignBlockDecl) {
			// foreign procedures only need their symbols; variables would need more
			ast_node(fb, ForeignBlockDecl, stmt);
			for (Ast *decl : fb->body->BlockStmt.stmts) {
				if (decl->kind == Ast_ValueDecl && decl->ValueDecl.is_mutable) XB_UNSUPPORTED(p, "nested foreign variable");
			}
		}
	}
}

gb_internal void xb_build_stmt_list(xbProc *p, Slice<Ast *> const &stmts) {
	xb_check_nested_decls(p, stmts);
	for (Ast *stmt : stmts) {
		xb_build_stmt(p, stmt);
	}
}

gb_internal void xb_build_assign_stmt(xbProc *p, AstAssignStmt *as) {
	if (as->op.kind == Token_Eq) {
		TEMPORARY_ALLOCATOR_GUARD();
		auto lvals = array_make<xbAddr>(xb_allocator(), 0, as->lhs.count);
		defer (array_free(&lvals));
		for (Ast *lhs : as->lhs) {
			if (is_blank_ident(lhs)) {
				xbAddr a = {};
				a.kind = xbAddr_Discard;
				array_add(&lvals, a);
			} else {
				array_add(&lvals, xb_build_addr(p, lhs));
			}
		}
		if (as->lhs.count == as->rhs.count) {
			if (as->lhs.count == 1) {
				xbValue v = xb_build_expr(p, as->rhs[0]);
				if (lvals[0].kind == xbAddr_Discard) return;
				xb_addr_store(p, lvals[0], v);
				return;
			}
			// evaluate all values first, copying anything in memory
			auto vals = array_make<xbValue>(xb_allocator(), 0, as->rhs.count);
			defer (array_free(&vals));
			for (Ast *rhs : as->rhs) {
				xbValue v = xb_build_expr(p, rhs);
				if (v.kind == xbValue_Mem) {
					v = xb_value_copy_to_temp(p, v);
				}
				array_add(&vals, v);
			}
			for_array(i, lvals) {
				if (lvals[i].kind == xbAddr_Discard) continue;
				xb_addr_store(p, lvals[i], vals[i]);
			}
			return;
		}
		// a, b = f()
		auto vals = array_make<xbValue>(xb_allocator(), 0, as->lhs.count);
		defer (array_free(&vals));
		for (Ast *rhs : as->rhs) {
			xbValue v = xb_build_expr(p, rhs);
			if (v.kind == xbValue_Mem) {
				v = xb_value_copy_to_temp(p, v);
			}
			xb_add_values_to_array(p, &vals, v);
		}
		GB_ASSERT(vals.count == lvals.count);
		for_array(i, lvals) {
			if (lvals[i].kind == xbAddr_Discard) continue;
			xb_addr_store(p, lvals[i], vals[i]);
		}
		return;
	}

	// op-assign
	TokenKind op = cast(TokenKind)(cast(i32)as->op.kind + (Token_Add - Token_AddEq));
	if (op == Token_CmpAnd || op == Token_CmpOr) {
		xbValue v = xb_emit_logical_binary(p, op, as->lhs[0], as->rhs[0], type_of_expr(as->lhs[0]));
		xb_addr_store(p, xb_build_addr(p, as->lhs[0]), v);
		return;
	}
	xbAddr lhs = xb_build_addr(p, as->lhs[0]);
	if (lhs.kind == xbAddr_SwizzleSoa) {
		xb_soa_swizzle_op_assign(p, op, lhs, xb_build_expr(p, as->rhs[0]));
		return;
	}
	if (lhs.kind != xbAddr_Default && lhs.kind != xbAddr_Swizzle && lhs.kind != xbAddr_SoaVariable && lhs.kind != xbAddr_BitField && lhs.kind != xbAddr_Map) XB_UNSUPPORTED(p, "op-assign to special addr");
	// the right side goes first, so a call in it that writes the target is seen (as in the LLVM backend)
	xbValue rhs = xb_build_expr(p, as->rhs[0]);
	xbValue old = xb_addr_load(p, lhs);
	Type *type = lhs.type;
	Type *bt = core_type(type);
	xbValue res = {};
	if (is_type_bit_set(bt)) {
		xbType st = xb_scalar_type(type);
		if (st == xbType_None) {
			xb_addr_store(p, lhs, xb_bit_set_mem_op(p, op, old, rhs, type));
			return;
		}
		u32 a = xb_value_to_reg(p, old);
		u32 b = xb_value_to_reg(p, xb_emit_conv(p, rhs, type));
		switch (op) {
		case Token_Add: case Token_Or: res = xb_value_reg(type, xb_binop(p, xbOp_Or, st, a, b)); break;
		case Token_Sub: case Token_AndNot: res = xb_value_reg(type, xb_binop(p, xbOp_And, st, a, xb_unop(p, xbOp_Not, st, b))); break;
		case Token_And: res = xb_value_reg(type, xb_binop(p, xbOp_And, st, a, b)); break;
		case Token_Xor: res = xb_value_reg(type, xb_binop(p, xbOp_Xor, st, a, b)); break;
		default: XB_UNSUPPORTED(p, "bit_set op-assign");
		}
	} else if (op == Token_Mul && is_type_matrix(rhs.type) && is_type_array(type)) {
		// array *= matrix
		res = xb_emit_arith_matrix(p, op, old, rhs, old.type, false);
	} else if (is_type_matrix(type)) {
		res = xb_emit_arith(p, op, old, xb_emit_conv(p, rhs, type), type);
	} else {
		res = xb_emit_arith(p, op, old, rhs, type);
	}
	xb_addr_store(p, lhs, res);
}

gb_internal void xb_build_return_stmt(xbProc *p, Slice<Ast *> const &results, TokenPos pos);
gb_internal void xb_return_with_results(xbProc *p, Array<xbValue> &results, bool store_named, TokenPos pos);
gb_internal void xb_inline_return(xbProc *p, Array<xbValue> &results, TokenPos pos);

gb_internal void xb_emit_ret(xbProc *p, xbMem direct_result) {
	xbAbiFunc *abi = p->abi;
	auto args = array_make<xbCallArg>(xb_allocator(), 0, 2);
	if (abi->has_sret && !xb_is_arm64()) {
		// x86-64 hands the sret pointer back in rax
		xbCallArg a = {};
		a.kind = xbCallArg_Gpr;
		a.type = xbType_I64;
		a.size = 8;
		a.reg = RAX;
		a.vreg = xb_load(p, xbType_I64, xb_mem(xbMem_Local, cast(u32)p->sret_local));
		array_add(&args, a);
	} else if (abi->ret.kind == xbArg_Direct) {
		if (abi->ret_lane_count > 0) {
			// each lane zero extended into its widened lane
			xbMem wide = xb_mem(xbMem_Local, cast(u32)xb_add_local_raw(p, 8, 8));
			i32 wide_size = 8 / abi->ret_lane_count;
			for (i32 i = 0; i < abi->ret_lane_count; i++) {
				u32 lane = xb_load(p, a64_int_piece_type(abi->ret_lane_size), xb_mem_offset(direct_result, i*abi->ret_lane_size));
				u32 ext = xb_convop(p, xbOp_Zext, a64_int_piece_type(wide_size), a64_int_piece_type(abi->ret_lane_size), lane);
				xb_store(p, a64_int_piece_type(wide_size), xb_mem_offset(wide, i*wide_size), ext);
			}
			direct_result = wide;
		}
		for (i32 i = 0; i < abi->ret.piece_count; i++) {
			xbAbiPiece const &piece = abi->pieces[abi->ret.piece_index+i];
			xbCallArg a = {};
			a.kind = piece.loc == xbLoc_Gpr ? xbCallArg_GprMem : xbCallArg_XmmMem;
			a.type = piece.type;
			a.size = piece.size;
			a.reg = piece.reg;
			a.ext = piece.ext;
			a.mem = xb_mem_offset(direct_result, piece.src_offset);
			array_add(&args, a);
		}
	}
	xbCall c = {};
	c.target_sym = -1;
	c.args = slice_from_array(args);
	c.sse_count = -1;
	array_add(&p->calls, c);
	xbInstr i = xb_instr(xbOp_Ret);
	i.imm = p->calls.count-1;
	xb_emit(p, i);
}

gb_internal xbMem xb_result_ptr_mem(xbProc *p, i32 local) {
	return xb_mem(xbMem_Reg, xb_load(p, xbType_I64, xb_mem(xbMem_Local, cast(u32)local)), 0);
}

// A machine nop in debug builds, for a line whose code may all fold away: a debugger stops
// only on a line with code of its own.
gb_internal void xb_debug_line_nop(xbProc *p) {
	if (!build_context.ODIN_DEBUG || xb_curr_terminated(p)) return;
	xbInstr nop = xb_instr(xbOp_Nop);
	nop.imm = 1;
	xb_emit(p, nop);
}

// leaves the #force_inline body being built
gb_internal void xb_inline_exit(xbProc *p) {
	if (xb_curr_terminated(p)) return;
	xb_jump(p, p->inl->exit);
	p->inl->exits += 1;
	p->inl->exit_from = p->curr;
}

gb_internal void xb_build_return_stmt(xbProc *p, Slice<Ast *> const &return_results, TokenPos pos) {
	TypeProc *pt = &base_type(p->type)->Proc;
	isize return_count = pt->result_count;
	if (return_count == 0) {
		if (p->inl != nullptr) xb_debug_line_nop(p);
		xb_emit_defer_stmts(p, true, nullptr, pos);
		if (!xb_curr_terminated(p)) {
			if (p->inl != nullptr) {
				xb_inline_exit(p);
			} else {
				xb_emit_ret(p, {});
			}
		}
		return;
	}

	TypeTuple *tuple = &pt->results->Tuple;
	auto results = array_make<xbValue>(xb_allocator(), 0, return_count);
	defer (array_free(&results));
	if (return_results.count != 0) {
		for (Ast *r : return_results) {
			xbValue v = xb_build_expr(p, r);
			xb_add_values_to_array(p, &results, v);
		}
	} else {
		for (isize i = 0; i < return_count; i++) {
			Entity *e = tuple->variables[i];
			xbVar *found = map_get(&p->vars, e);
			GB_ASSERT(found != nullptr);
			array_add(&results, xb_load_value(p, e->type, found->mem));
		}
	}
	xb_return_with_results(p, results, return_results.count != 0, pos);
}

// Writes the results out, runs the defers and returns.
gb_internal void xb_return_with_results(xbProc *p, Array<xbValue> &results, bool store_named, TokenPos pos) {
	xbAbiFunc *abi = p->abi;
	TypeProc *pt = &base_type(p->type)->Proc;
	isize return_count = pt->result_count;
	TypeTuple *tuple = &pt->results->Tuple;
	GB_ASSERT(results.count == return_count);
	for_array(i, results) {
		results[i] = xb_emit_conv(p, results[i], tuple->variables[i]->type);
	}
	if (store_named && pt->has_named_results) {
		// store the named values before returning
		for_array(i, results) {
			if (results[i].kind == xbValue_Mem) {
				results[i] = xb_value_copy_to_temp(p, results[i]);
			}
		}
		for_array(i, tuple->variables) {
			Entity *e = tuple->variables[i];
			if (e->token.string == "") continue;
			xbVar *found = map_get(&p->vars, e);
			if (found) {
				xb_store_value(p, found->mem, results[i]);
			}
		}
	}

	if (p->inl != nullptr) {
		xb_inline_return(p, results, pos);
		return;
	}

	// write the results out before running the defers
	if (abi->split_returns) {
		for (isize i = 0; i < return_count-1; i++) {
			xb_store_value(p, xb_result_ptr_mem(p, p->split_ret_locals[i]), results[i]);
		}
	}
	xbValue last = results[return_count-1];
	Type *last_type = tuple->variables[return_count-1]->type;
	xbMem direct = {};
	if (!abi->split_returns && return_count > 1) {
		// one tuple result
		if (abi->has_sret) {
			xbMem dst = xb_result_ptr_mem(p, p->sret_local);
			for (isize i = 0; i < return_count; i++) {
				Type *ft = nullptr;
				i64 off = type_offset_of(pt->results, i, &ft);
				xb_store_value(p, xb_mem_offset(dst, off), results[i]);
			}
		} else {
			direct = xb_mem(xbMem_Local, cast(u32)p->ret_temp_local);
			for (isize i = 0; i < return_count; i++) {
				Type *ft = nullptr;
				i64 off = type_offset_of(pt->results, i, &ft);
				if (abi->ret_tuple_offsets.count > 0) off = abi->ret_tuple_offsets[i];
				xb_store_value(p, xb_mem_offset(direct, off), results[i]);
			}
		}
	} else if (abi->has_sret) {
		xb_store_value(p, xb_result_ptr_mem(p, p->sret_local), last);
	} else if (abi->ret.kind == xbArg_Direct) {
		direct = xb_mem(xbMem_Local, cast(u32)p->ret_temp_local);
		xb_store_value(p, direct, xb_emit_conv(p, last, last_type));
	}

	xb_emit_defer_stmts(p, true, nullptr, pos);
	if (!xb_curr_terminated(p)) {
		xb_emit_ret(p, direct);
	}
}

gb_internal void xb_build_if_stmt(xbProc *p, Ast *node) {
	ast_node(is, IfStmt, node);
	xb_open_scope(p);
	if (is->init != nullptr) {
		xb_build_stmt(p, is->init);
	}
	xbBlock *then_ = xb_new_block(p);
	xbBlock *done = xb_new_block(p);
	xbBlock *else_ = done;
	if (is->else_stmt != nullptr) {
		else_ = xb_new_block(p);
	}
	xbValue cond = xb_build_expr(p, is->cond);
	xb_branch(p, xb_to_bool_reg(p, cond), then_, else_);

	if (is->label != nullptr) {
		xbTargetList *tl = xb_push_target_list(p, is->label, done, nullptr, nullptr);
		tl->is_block = true;
	}

	xb_start_block(p, then_);
	xb_build_stmt(p, is->body);
	xb_set_debug_end_loc(p, is->body);
	xb_jump(p, done);

	if (is->else_stmt != nullptr) {
		xb_start_block(p, else_);
		xb_open_scope(p);
		xb_build_stmt(p, is->else_stmt);
		xb_close_scope(p, is->else_stmt);
		xb_set_debug_end_loc(p, is->else_stmt);
		xb_jump(p, done);
	}
	if (is->label != nullptr) {
		xb_pop_target_list(p);
	}
	xb_start_block(p, done);
	xb_close_scope(p, node);
}

gb_internal void xb_build_for_stmt(xbProc *p, Ast *node) {
	ast_node(fs, ForStmt, node);
	xb_open_scope(p);
	if (fs->init != nullptr) {
		xb_build_stmt(p, fs->init);
	}
	xbBlock *body = xb_new_block(p);
	xbBlock *done = xb_new_block(p);
	// like LLVM's, a loop without a condition goes straight back to its body
	xbBlock *loop = fs->cond != nullptr ? xb_new_block(p) : body;
	xbBlock *post = loop;
	if (fs->post != nullptr) {
		post = xb_new_block(p);
	}
	xb_jump(p, loop);
	if (fs->cond != nullptr) {
		xb_start_block(p, loop);
		// expressions set no position of their own
		xb_set_debug_loc(p, ast_token(fs->cond).pos);
		xbValue c = xb_build_expr(p, fs->cond);
		xb_branch(p, xb_to_bool_reg(p, c), body, done);
	}
	xb_push_target_list(p, fs->label, done, post, nullptr);
	xb_start_block(p, body);
	xb_build_stmt(p, fs->body);
	xb_pop_target_list(p);
	xb_set_debug_end_loc(p, fs->body);
	xb_jump(p, post);
	if (fs->post != nullptr) {
		xb_start_block(p, post);
		xb_build_stmt(p, fs->post);
		xb_jump(p, loop);
	}
	xb_start_block(p, done);
	xb_close_scope(p, node);
}

gb_internal Ast *xb_strip_and_prefix(Ast *ident) {
	if (ident != nullptr && ident->kind == Ast_UnaryExpr && ident->UnaryExpr.op.kind == Token_And) {
		ident = ident->UnaryExpr.expr;
	}
	return ident;
}

// lb_store_range_stmt_val: a by-reference loop value binds to where it was loaded from
gb_internal void xb_store_range_var(xbProc *p, Ast *name, xbValue v) {
	if (name == nullptr || is_blank_ident(name)) return;
	Entity *e = entity_of_node(name);
	if (e == nullptr) return;
	if ((e->flags & EntityFlag_Value) == 0 && (v.kind == xbValue_Mem || v.has_origin)) {
		xbMem src = v.kind == xbValue_Mem ? v.mem : v.origin;
		i32 l = xb_add_local_raw(p, 8, 8);
		xbMem m = xb_mem(xbMem_Local, cast(u32)l);
		xb_store(p, xbType_I64, m, xb_lea(p, src));
		xbVar var = {};
		var.mem = m;
		var.indirect = true;
		map_set(&p->vars, e, var);
		xb_add_debug_var(p, e, m, true, false);
		return;
	}
	xbVar *found = map_get(&p->vars, e);
	xbMem m = {};
	if (found && !found->indirect) {
		m = found->mem;
	} else {
		m = xb_add_local_entity(p, e, false);
	}
	xb_store_value(p, m, xb_emit_conv(p, v, e->type));
}

// LLVM keeps a parameter as a value, not a stack slot, so a loop head reading one starts by reloading it
gb_internal bool xb_expr_reads_param(Ast *expr) {
	if (expr == nullptr) return false;
	if (type_and_value_of_expr(expr).mode == Addressing_Constant) return false;
	switch (expr->kind) {
	case Ast_Ident: {
		Entity *e = entity_of_node(expr);
		return e != nullptr && e->kind == Entity_Variable && (e->flags & EntityFlag_Param) != 0 && type_size_of(e->type) > 0;
	}
	case Ast_ParenExpr:     return xb_expr_reads_param(expr->ParenExpr.expr);
	case Ast_UnaryExpr:     return xb_expr_reads_param(expr->UnaryExpr.expr);
	case Ast_DerefExpr:     return xb_expr_reads_param(expr->DerefExpr.expr);
	case Ast_SelectorExpr:  return xb_expr_reads_param(expr->SelectorExpr.expr);
	case Ast_TypeAssertion: return xb_expr_reads_param(expr->TypeAssertion.expr);
	case Ast_TypeCast:      return xb_expr_reads_param(expr->TypeCast.expr);
	case Ast_AutoCast:      return xb_expr_reads_param(expr->AutoCast.expr);
	case Ast_BinaryExpr:    return xb_expr_reads_param(expr->BinaryExpr.left) || xb_expr_reads_param(expr->BinaryExpr.right);
	case Ast_IndexExpr:     return xb_expr_reads_param(expr->IndexExpr.expr) || xb_expr_reads_param(expr->IndexExpr.index);
	case Ast_SliceExpr:
		return xb_expr_reads_param(expr->SliceExpr.expr) || xb_expr_reads_param(expr->SliceExpr.low) || xb_expr_reads_param(expr->SliceExpr.high);
	case Ast_TernaryIfExpr:
		return xb_expr_reads_param(expr->TernaryIfExpr.x) || xb_expr_reads_param(expr->TernaryIfExpr.cond) || xb_expr_reads_param(expr->TernaryIfExpr.y);
	case Ast_CallExpr:
		if (xb_expr_reads_param(expr->CallExpr.proc)) return true;
		for (Ast *arg : expr->CallExpr.args) {
			if (xb_expr_reads_param(arg)) return true;
		}
		return false;
	}
	return false;
}

gb_internal void xb_build_range_interval(xbProc *p, AstRangeStmt *rs, Ast *expr) {
	ast_node(ie, BinaryExpr, expr);
	Ast *val0 = rs->vals.count > 0 ? xb_strip_and_prefix(rs->vals[0]) : nullptr;
	Ast *val1 = rs->vals.count > 1 ? xb_strip_and_prefix(rs->vals[1]) : nullptr;
	Type *val0_type = (val0 && !is_blank_ident(val0)) ? type_of_expr(val0) : nullptr;
	Type *val1_type = (val1 && !is_blank_ident(val1)) ? type_of_expr(val1) : nullptr;

	TokenKind op = ie->op.kind == Token_RangeHalf ? Token_Lt : Token_LtEq;

	xbValue lower = xb_build_expr(p, ie->left);
	Type *value_type = val0_type ? val0_type : default_type(lower.type);
	xbType st = xb_scalar_type(value_type);
	if (st == xbType_None) XB_UNSUPPORTED(p, "range interval type");
	xbMem value_mem = {};
	if (val0_type) {
		value_mem = xb_add_local_entity(p, entity_of_node(val0), false);
	} else {
		value_mem = xb_add_local(p, value_type, false);
	}
	xb_store_value(p, value_mem, xb_emit_conv(p, lower, value_type));
	xbMem index_mem = {};
	if (val1_type) {
		index_mem = xb_add_local_entity(p, entity_of_node(val1), false);
	} else {
		index_mem = xb_add_local(p, t_int, false);
	}
	Type *index_type = val1_type ? val1_type : t_int;
	xb_store_value(p, index_mem, xb_const_int(p, index_type, 0));

	xbBlock *loop = xb_new_block(p);
	xbBlock *body = xb_new_block(p);
	xbBlock *done = xb_new_block(p);
	xb_jump(p, loop);
	xb_start_block(p, loop, !xb_expr_reads_param(ie->right));

	// the upper bound is evaluated on every iteration
	xbValue upper = xb_build_expr(p, ie->right);
	xbMem upper_mem = xb_add_local(p, value_type, false);
	xb_store_value(p, upper_mem, xb_emit_conv(p, upper, value_type));
	xbMem curr_mem = xb_add_local(p, value_type, false);
	xb_store_value(p, curr_mem, xb_load_value(p, value_type, value_mem));
	xbValue cond = xb_emit_comp(p, op, xb_load_value(p, value_type, curr_mem), xb_load_value(p, value_type, upper_mem));
	xb_branch(p, xb_value_to_reg(p, cond), body, done);
	xb_start_block(p, body);

	xbBlock *post = xb_new_block(p);
	xbBlock *check = nullptr;
	xbBlock *continue_block = post;
	if (op == Token_LtEq) {
		check = xb_new_block(p);
		continue_block = check;
	}
	xb_push_target_list(p, rs->label, done, continue_block, nullptr);
	xb_build_stmt(p, rs->body);
	xb_pop_target_list(p);
	xb_set_debug_end_loc(p, rs->body);
	if (check != nullptr) {
		xb_jump(p, check);
		xb_start_block(p, check);
		// stop before wrapping past the last value
		xbValue c = xb_emit_comp(p, Token_NotEq, xb_load_value(p, value_type, curr_mem), xb_load_value(p, value_type, upper_mem));
		xb_branch(p, xb_value_to_reg(p, c), post, done);
	} else {
		xb_jump(p, post);
	}
	xb_start_block(p, post);
	xbValue one = xb_const_int(p, value_type, 1);
	xb_store_value(p, value_mem, xb_emit_arith(p, Token_Add, xb_load_value(p, value_type, value_mem), one, value_type));
	xbValue ione = xb_const_int(p, index_type, 1);
	xb_store_value(p, index_mem, xb_emit_arith(p, Token_Add, xb_load_value(p, index_type, index_mem), ione, index_type));
	xb_jump(p, loop);
	xb_start_block(p, done);
}

// The loop skeleton shared by arrays, slices and dynamic arrays. `get_count`
// produces the length in the current block, `get_elem` the element pointer.
template <typename CountFn, typename ElemFn>
gb_internal void xb_build_range_indexed_loop(xbProc *p, AstRangeStmt *rs, Type *elem_type, CountFn const &get_count, ElemFn const &get_elem, Type *enum_index_type, ExactValue *enum_min, bool live_count=false) {
	Ast *val0 = rs->vals.count > 0 ? xb_strip_and_prefix(rs->vals[0]) : nullptr;
	Ast *val1 = rs->vals.count > 1 ? xb_strip_and_prefix(rs->vals[1]) : nullptr;
	xbMem index_mem = xb_add_local(p, t_int, false);
	xbBlock *loop = xb_new_block(p);
	xbBlock *body = xb_new_block(p);
	xbBlock *done = xb_new_block(p);
	if (!rs->reverse) {
		xb_store(p, xbType_I64, index_mem, xb_iconst(p, xbType_I64, -1));
		xb_jump(p, loop);
		// LLVM reads the length through a pointer it took before the loop
		xb_start_block(p, loop, !live_count);
		u32 incr = xb_binop(p, xbOp_Add, xbType_I64, xb_load(p, xbType_I64, index_mem), xb_iconst(p, xbType_I64, 1));
		xb_store(p, xbType_I64, index_mem, incr);
		u32 count = get_count();
		xb_branch(p, xb_cmp(p, xbCond_SLT, xbType_I64, incr, count), body, done);
	} else {
		u32 count = get_count();
		xb_store(p, xbType_I64, index_mem, count);
		xb_jump(p, loop);
		xb_start_block(p, loop);
		u32 decr = xb_binop(p, xbOp_Sub, xbType_I64, xb_load(p, xbType_I64, index_mem), xb_iconst(p, xbType_I64, 1));
		xb_store(p, xbType_I64, index_mem, decr);
		xb_branch(p, xb_cmp(p, xbCond_SLT, xbType_I64, decr, xb_iconst(p, xbType_I64, 0)), done, body);
	}
	xb_start_block(p, body);
	u32 idx = xb_load(p, xbType_I64, index_mem);
	if (val0 != nullptr && !is_blank_ident(val0)) {
		u32 ptr = get_elem(idx);
		xb_store_range_var(p, val0, xb_load_value(p, elem_type, xb_mem(xbMem_Reg, ptr, 0)));
	}
	if (val1 != nullptr && !is_blank_ident(val1)) {
		xbValue iv = xb_value_reg(t_int, idx);
		if (enum_index_type != nullptr) {
			iv = xb_emit_conv(p, iv, enum_index_type);
			if (enum_min && compare_exact_values(Token_NotEq, *enum_min, exact_value_u64(0))) {
				iv = xb_emit_arith(p, Token_Add, iv, xb_const_value(p, enum_index_type, *enum_min), enum_index_type);
			}
		}
		xb_store_range_var(p, val1, iv);
	}
	xb_push_target_list(p, rs->label, done, loop, nullptr);
	xb_build_stmt(p, rs->body);
	xb_pop_target_list(p);
	xb_set_debug_end_loc(p, rs->body);
	xb_jump(p, loop);
	xb_start_block(p, done);
}

gb_internal void xb_build_range_indexed(xbProc *p, AstRangeStmt *rs) {
	Ast *expr = unparen_expr(rs->expr);
	Type *expr_type = type_of_expr(expr);
	Type *et = base_type(type_deref(expr_type));

	switch (et->kind) {
	case Type_Array:
	case Type_EnumeratedArray: {
		xbAddr addr = xb_build_addr(p, expr);
		if (addr.kind == xbAddr_Swizzle || addr.kind == xbAddr_SwizzleSoa) {
			addr = xb_addr(addr.type, xb_addr_mem(p, addr));
		}
		if (addr.kind == xbAddr_Default && is_type_soa_pointer(addr.type)) {
			addr = xb_soa_variable_from_soa_ptr(p, xb_load_value(p, addr.type, addr.mem));
		}
		if (addr.kind == xbAddr_SoaVariable) {
			// for v in soa[i]: the components of the element live in different columns
			xb_soa_bounds_check(p, addr);
			addr.soa_index_expr = nullptr;
			Type *elem = et->Array.elem;
			i64 count = et->Array.count;
			xb_build_range_indexed_loop(p, rs, elem,
				[&]() { return xb_iconst(p, xbType_I64, count); },
				[&](u32 idx) { return xb_lea(p, xb_soa_component_dynamic(p, addr, idx)); },
				nullptr, nullptr);
			return;
		}
		if (addr.kind != xbAddr_Default) XB_UNSUPPORTED(p, "range over special addr");
		xbMem array = addr.mem;
		if (is_type_pointer(addr.type)) {
			array = xb_mem(xbMem_Reg, xb_load(p, xbType_I64, array), 0);
		}
		i32 base_local = xb_add_local_raw(p, 8, 8);
		xb_store(p, xbType_I64, xb_mem(xbMem_Local, cast(u32)base_local), xb_lea(p, array));
		Type *elem = et->kind == Type_Array ? et->Array.elem : et->EnumeratedArray.elem;
		i64 count = et->kind == Type_Array ? et->Array.count : et->EnumeratedArray.count;
		i64 stride = type_size_of(elem);
		xb_build_range_indexed_loop(p, rs, elem,
			[&]() { return xb_iconst(p, xbType_I64, count); },
			[&](u32 idx) { return xb_ptr_add_scaled(p, xb_load(p, xbType_I64, xb_mem(xbMem_Local, cast(u32)base_local)), idx, stride); },
			et->kind == Type_EnumeratedArray ? et->EnumeratedArray.index : nullptr,
			et->kind == Type_EnumeratedArray ? et->EnumeratedArray.min_value : nullptr);
		return;
	}
	case Type_DynamicArray: {
		// the live array: its length and data are read on every iteration
		xbAddr addr = xb_build_addr(p, expr);
		if (addr.kind != xbAddr_Default) XB_UNSUPPORTED(p, "range over special addr");
		xbMem array = addr.mem;
		if (is_type_pointer(addr.type)) {
			array = xb_mem(xbMem_Reg, xb_load(p, xbType_I64, array), 0);
		}
		i32 base_local = xb_add_local_raw(p, 8, 8);
		xb_store(p, xbType_I64, xb_mem(xbMem_Local, cast(u32)base_local), xb_lea(p, array));
		Type *elem = et->DynamicArray.elem;
		i64 stride = type_size_of(elem);
		auto arr = [&]() { return xb_mem(xbMem_Reg, xb_load(p, xbType_I64, xb_mem(xbMem_Local, cast(u32)base_local)), 0); };
		xb_build_range_indexed_loop(p, rs, elem,
			[&]() { return xb_load(p, xbType_I64, xb_mem_offset(arr(), 8)); },
			[&](u32 idx) { return xb_ptr_add_scaled(p, xb_load(p, xbType_I64, arr()), idx, stride); },
			nullptr, nullptr, true);
		return;
	}
	case Type_FixedCapacityDynamicArray: {
		// the elements live inline, the length is read on every iteration
		xbAddr addr = xb_build_addr(p, expr);
		if (addr.kind != xbAddr_Default) XB_UNSUPPORTED(p, "range over special addr");
		xbMem array = addr.mem;
		if (is_type_pointer(addr.type)) {
			array = xb_mem(xbMem_Reg, xb_load(p, xbType_I64, array), 0);
		}
		i32 base_local = xb_add_local_raw(p, 8, 8);
		xb_store(p, xbType_I64, xb_mem(xbMem_Local, cast(u32)base_local), xb_lea(p, array));
		Type *elem = et->FixedCapacityDynamicArray.elem;
		i64 stride = type_size_of(elem);
		i64 len_offset = type_offset_of(et, 1);
		auto base = [&]() { return xb_load(p, xbType_I64, xb_mem(xbMem_Local, cast(u32)base_local)); };
		xb_build_range_indexed_loop(p, rs, elem,
			[&]() { return xb_load(p, xbType_I64, xb_mem(xbMem_Reg, base(), cast(i32)len_offset)); },
			[&](u32 idx) { return xb_ptr_add_scaled(p, base(), idx, stride); },
			nullptr, nullptr, true);
		return;
	}
	case Type_Slice: {
		xbValue v = xb_build_expr(p, expr);
		i32 count_local = -1;
		xbValue slice = v;
		if (is_type_pointer(v.type)) {
			// the length is read through the pointer each time
			u32 ptr = xb_value_to_reg(p, v);
			count_local = xb_add_local_raw(p, 8, 8);
			xb_store(p, xbType_I64, xb_mem(xbMem_Local, cast(u32)count_local), xb_ptr_add_const(p, ptr, 8));
			slice = xb_load_value(p, type_deref(v.type), xb_mem(xbMem_Reg, ptr, 0));
		}
		slice = xb_value_copy_to_temp(p, slice);
		xbMem sm = slice.mem;
		Type *elem = et->Slice.elem;
		i64 stride = type_size_of(elem);
		xb_build_range_indexed_loop(p, rs, elem,
			[&]() {
				if (count_local >= 0) {
					u32 cp = xb_load(p, xbType_I64, xb_mem(xbMem_Local, cast(u32)count_local));
					return xb_load(p, xbType_I64, xb_mem(xbMem_Reg, cp, 0));
				}
				return xb_load(p, xbType_I64, xb_mem_offset(sm, 8));
			},
			[&](u32 idx) { return xb_ptr_add_scaled(p, xb_load(p, xbType_I64, sm), idx, stride); },
			nullptr, nullptr, count_local >= 0);
		return;
	}
	default:
		XB_UNSUPPORTED(p, "range indexed type");
	}
}

gb_internal void xb_build_range_string(xbProc *p, AstRangeStmt *rs) {
	Ast *expr = unparen_expr(rs->expr);
	Ast *val0 = rs->vals.count > 0 ? xb_strip_and_prefix(rs->vals[0]) : nullptr;
	Ast *val1 = rs->vals.count > 1 ? xb_strip_and_prefix(rs->vals[1]) : nullptr;
	xbValue s = xb_build_expr(p, expr);
	if (is_type_pointer(s.type)) {
		s = xb_load_value(p, type_deref(s.type), xb_mem_from_ptr(p, s));
	}
	if (is_type_untyped(s.type)) s = xb_emit_conv(p, s, default_type(s.type));
	bool is16 = is_type_string16(s.type);
	Type *str_type = is16 ? t_string16 : t_string;
	xbMem str = xb_value_copy_to_temp(p, s).mem;
	xbMem offset_mem = xb_add_local(p, t_int, false);

	xbBlock *loop = xb_new_block(p);
	xbBlock *body = xb_new_block(p);
	xbBlock *done = xb_new_block(p);
	if (!rs->reverse) {
		xb_store(p, xbType_I64, offset_mem, xb_iconst(p, xbType_I64, 0));
		xb_jump(p, loop);
		// LLVM compares with the length it took before the loop
		xb_start_block(p, loop, false);
		u32 off = xb_load(p, xbType_I64, offset_mem);
		xb_branch(p, xb_cmp(p, xbCond_SLT, xbType_I64, off, xb_load(p, xbType_I64, xb_mem_offset(str, 8))), body, done);
	} else {
		xb_store(p, xbType_I64, offset_mem, xb_load(p, xbType_I64, xb_mem_offset(str, 8)));
		xb_jump(p, loop);
		xb_start_block(p, loop);
		u32 off = xb_load(p, xbType_I64, offset_mem);
		xb_branch(p, xb_cmp(p, xbCond_SGT, xbType_I64, off, xb_iconst(p, xbType_I64, 0)), body, done);
	}
	xb_start_block(p, body);
	u32 off = xb_load(p, xbType_I64, offset_mem);
	u32 base = xb_load(p, xbType_I64, str);
	u32 len = xb_load(p, xbType_I64, xb_mem_offset(str, 8));
	xbValue res = {};
	u32 idx = 0;
	if (!rs->reverse) {
		xbValue rest = xb_make_slice_value(p, str_type, xb_ptr_add_scaled(p, base, off, is16 ? 2 : 1), xb_binop(p, xbOp_Sub, xbType_I64, len, off));
		xbValue args[1] = {rest};
		res = xb_emit_runtime_call(p, is16 ? "string16_decode_rune" : "string_decode_rune", xb_args(args, 1));
		Type *ft = nullptr;
		u32 w = xb_load(p, xbType_I64, xb_mem_offset(res.mem, type_offset_of(res.type, 1, &ft)));
		xb_store(p, xbType_I64, offset_mem, xb_binop(p, xbOp_Add, xbType_I64, off, w));
		idx = off;
	} else {
		xbValue prefix = xb_make_slice_value(p, str_type, base, off);
		xbValue args[1] = {prefix};
		res = xb_emit_runtime_call(p, is16 ? "string16_decode_last_rune" : "string_decode_last_rune", xb_args(args, 1));
		Type *ft = nullptr;
		u32 w = xb_load(p, xbType_I64, xb_mem_offset(res.mem, type_offset_of(res.type, 1, &ft)));
		u32 next = xb_binop(p, xbOp_Sub, xbType_I64, off, w);
		xb_store(p, xbType_I64, offset_mem, next);
		idx = next;
	}
	Type *ft = nullptr;
	xbValue r = xb_load_value(p, t_rune, xb_mem_offset(res.mem, type_offset_of(res.type, 0, &ft)));
	xb_store_range_var(p, val0, xb_value_reg(t_rune, xb_value_to_reg(p, r)));
	xb_store_range_var(p, val1, xb_value_reg(t_int, idx));
	xb_push_target_list(p, rs->label, done, loop, nullptr);
	xb_build_stmt(p, rs->body);
	xb_pop_target_list(p);
	xb_set_debug_end_loc(p, rs->body);
	xb_jump(p, loop);
	xb_start_block(p, done);
}

gb_internal void xb_build_range_tuple(xbProc *p, AstRangeStmt *rs) {
	Ast *expr = unparen_expr(rs->expr);
	xbBlock *loop = xb_new_block(p);
	xbBlock *body = xb_new_block(p);
	xbBlock *done = xb_new_block(p);
	xb_jump(p, loop);
	xb_start_block(p, loop);
	xbValue tuple_value = xb_build_expr(p, expr);
	Type *tuple = tuple_value.type;
	GB_ASSERT(tuple->kind == Type_Tuple);
	xbMem tm = xb_value_to_mem(p, tuple_value);
	isize count = tuple->Tuple.variables.count;
	Type *ft = nullptr;
	i64 coff = type_offset_of(tuple, count-1, &ft);
	xbValue cond = xb_load_value(p, ft, xb_mem_offset(tm, coff));
	xb_branch(p, xb_to_bool_reg(p, cond), body, done);
	xb_start_block(p, body);
	for (isize i = 0; i < rs->vals.count; i++) {
		Ast *val = rs->vals[i];
		if (val == nullptr) continue;
		i64 off = type_offset_of(tuple, i, &ft);
		xbValue v = xb_load_value(p, ft, xb_mem_offset(tm, off));
		if (v.kind == xbValue_Mem) v = xb_value_copy_to_temp(p, v);
		v.has_origin = false;
		xb_store_range_var(p, xb_strip_and_prefix(val), v);
	}
	xb_push_target_list(p, rs->label, done, loop, nullptr);
	xb_build_stmt(p, rs->body);
	xb_pop_target_list(p);
	xb_set_debug_end_loc(p, rs->body);
	xb_jump(p, loop);
	xb_start_block(p, done);
}

gb_internal void xb_build_range_enum(xbProc *p, AstRangeStmt *rs, Type *enum_type) {
	Ast *val0 = rs->vals.count > 0 ? xb_strip_and_prefix(rs->vals[0]) : nullptr;
	Ast *val1 = rs->vals.count > 1 ? xb_strip_and_prefix(rs->vals[1]) : nullptr;
	Type *t = base_type(enum_type);
	if (!is_type_integer(core_type(t))) XB_UNSUPPORTED(p, "enum range core type");
	// the values as an array of i64, like lb_enum_values_slice
	isize n = t->Enum.fields.count;
	auto vals = array_make<i64>(heap_allocator(), n);
	for_array(i, t->Enum.fields) {
		vals[i] = exact_value_to_i64(t->Enum.fields[i]->Constant.value);
	}
	i32 sym = xb_rodata(p->m, vals.data, gb_max(n, cast(isize)1)*8, 8);
	array_free(&vals);

	xbMem offset_mem = xb_add_local(p, t_int, false);
	xb_store(p, xbType_I64, offset_mem, xb_iconst(p, xbType_I64, 0));
	xbBlock *loop = xb_new_block(p);
	xbBlock *body = xb_new_block(p);
	xbBlock *done = xb_new_block(p);
	xb_jump(p, loop);
	xb_start_block(p, loop);
	u32 off = xb_load(p, xbType_I64, offset_mem);
	xb_branch(p, xb_cmp(p, xbCond_SLT, xbType_I64, off, xb_iconst(p, xbType_I64, n)), body, done);
	xb_start_block(p, body);
	u32 off2 = xb_load(p, xbType_I64, offset_mem);
	u32 ptr = xb_ptr_add_scaled(p, xb_lea(p, xb_mem(xbMem_Sym, cast(u32)sym)), off2, 8);
	xb_store(p, xbType_I64, offset_mem, xb_binop(p, xbOp_Add, xbType_I64, off2, xb_iconst(p, xbType_I64, 1)));
	if (val0 != nullptr && !is_blank_ident(val0)) {
		xbValue i = xb_value_reg(t_i64, xb_load(p, xbType_I64, xb_mem(xbMem_Reg, ptr, 0)));
		xb_store_range_var(p, val0, xb_emit_conv(p, i, enum_type));
	}
	xb_store_range_var(p, val1, xb_value_reg(t_int, off2));
	xb_push_target_list(p, rs->label, done, loop, nullptr);
	xb_build_stmt(p, rs->body);
	xb_pop_target_list(p);
	xb_set_debug_end_loc(p, rs->body);
	xb_jump(p, loop);
	xb_start_block(p, done);
}

// the address of cell element `index` in a map's key or value array
gb_internal u32 xb_map_cell_index(xbProc *p, Type *type, u32 cells_ptr, u32 index) {
	i64 size = 0, len = 0;
	i64 elem_sz = type_size_of(type);
	map_cell_size_and_len(type, &size, &len);
	if (size == len*elem_sz) {
		return xb_ptr_add_scaled(p, cells_ptr, index, elem_sz);
	}
	u32 cell_index = 0;
	u32 data_index = 0;
	if (is_power_of_two(len)) {
		u64 log2_len = floor_log2(cast(u64)len);
		cell_index = log2_len == 0 ? index : xb_binop(p, xbOp_LShr, xbType_I64, index, xb_iconst(p, xbType_I64, cast(i64)log2_len));
		data_index = xb_binop(p, xbOp_And, xbType_I64, index, xb_iconst(p, xbType_I64, len-1));
	} else {
		cell_index = xb_binop(p, xbOp_UDiv, xbType_I64, index, xb_iconst(p, xbType_I64, len));
		data_index = xb_binop(p, xbOp_URem, xbType_I64, index, xb_iconst(p, xbType_I64, len));
	}
	u32 base = xb_binop(p, xbOp_Add, xbType_I64, cells_ptr, xb_binop(p, xbOp_Mul, xbType_I64, cell_index, xb_iconst(p, xbType_I64, size)));
	return xb_ptr_add_scaled(p, base, data_index, elem_sz);
}

gb_internal void xb_build_range_map(xbProc *p, AstRangeStmt *rs, Type *type) {
	Ast *expr = unparen_expr(rs->expr);
	Ast *val0 = rs->vals.count > 0 ? xb_strip_and_prefix(rs->vals[0]) : nullptr;
	Ast *val1 = rs->vals.count > 1 ? xb_strip_and_prefix(rs->vals[1]) : nullptr;
	xbAddr ma = xb_build_addr(p, expr);
	xbMem mm = xb_addr_mem(p, ma);
	u32 map_ptr = is_type_pointer(ma.type) ? xb_load(p, xbType_I64, mm) : xb_lea(p, mm);
	i32 map_local = xb_add_local_raw(p, 8, 8);
	xb_store(p, xbType_I64, xb_mem(xbMem_Local, cast(u32)map_local), map_ptr);
	auto map = [&]() { return xb_mem(xbMem_Reg, xb_load(p, xbType_I64, xb_mem(xbMem_Local, cast(u32)map_local)), 0); };

	xbMem index_mem = xb_add_local(p, t_int, false);
	xb_store(p, xbType_I64, index_mem, xb_iconst(p, xbType_I64, -1));
	xbBlock *loop = xb_new_block(p);
	xbBlock *hash_check = xb_new_block(p);
	xbBlock *body = xb_new_block(p);
	xbBlock *done = xb_new_block(p);
	xb_jump(p, loop);
	// LLVM reads the map through its address, a reload unless it is a local's or a global's stack slot or symbol
	Entity *me = expr->kind == Ast_Ident ? entity_of_node(expr) : nullptr;
	bool slot = me != nullptr && me->kind == Entity_Variable && (me->flags & EntityFlag_Param) == 0 && !is_type_pointer(me->type);
	xb_start_block(p, loop, slot);
	u32 incr = xb_binop(p, xbOp_Add, xbType_I64, xb_load(p, xbType_I64, index_mem), xb_iconst(p, xbType_I64, 1));
	xb_store(p, xbType_I64, index_mem, incr);
	auto capacity = [&](u32 data) {
		u32 log2_cap = xb_binop(p, xbOp_And, xbType_I64, data, xb_iconst(p, xbType_I64, MAP_CACHE_LINE_SIZE-1));
		u32 cap = xb_binop(p, xbOp_Shl, xbType_I64, xb_iconst(p, xbType_I64, 1), log2_cap);
		u32 is_zero = xb_cmp(p, xbCond_EQ, xbType_I64, data, xb_iconst(p, xbType_I64, 0));
		return xb_select(p, xbType_I64, is_zero, xb_iconst(p, xbType_I64, 0), cap);
	};
	{
		u32 data = xb_load(p, xbType_I64, map());
		xb_branch(p, xb_cmp(p, xbCond_SLT, xbType_I64, incr, capacity(data)), hash_check, done);
	}
	xb_start_block(p, hash_check);
	u32 data = xb_load(p, xbType_I64, map());
	u32 cap = capacity(data);
	u32 ks = xb_binop(p, xbOp_And, xbType_I64, data, xb_iconst(p, xbType_I64, cast(i64)~cast(u64)(MAP_CACHE_LINE_SIZE-1)));
	u32 vs = xb_map_cell_index(p, type->Map.key, ks, cap);
	u32 hs = xb_map_cell_index(p, type->Map.value, vs, cap);
	u32 idx = xb_load(p, xbType_I64, index_mem);
	u32 hash = xb_load(p, xbType_I64, xb_mem(xbMem_Reg, xb_ptr_add_scaled(p, hs, idx, 8), 0));
	// (hash != 0) && (hash >> 63 == 0)
	u32 not_empty = xb_cmp(p, xbCond_NE, xbType_I64, hash, xb_iconst(p, xbType_I64, 0));
	u32 not_deleted = xb_cmp(p, xbCond_EQ, xbType_I64, xb_binop(p, xbOp_LShr, xbType_I64, hash, xb_iconst(p, xbType_I64, 63)), xb_iconst(p, xbType_I64, 0));
	xb_branch(p, xb_binop(p, xbOp_And, xbType_I8, not_empty, not_deleted), body, loop);
	xb_start_block(p, body);
	{
		u32 data2 = xb_load(p, xbType_I64, map());
		u32 cap2 = capacity(data2);
		u32 ks2 = xb_binop(p, xbOp_And, xbType_I64, data2, xb_iconst(p, xbType_I64, cast(i64)~cast(u64)(MAP_CACHE_LINE_SIZE-1)));
		u32 vs2 = xb_map_cell_index(p, type->Map.key, ks2, cap2);
		u32 idx2 = xb_load(p, xbType_I64, index_mem);
		u32 key_ptr = xb_map_cell_index(p, type->Map.key, ks2, idx2);
		u32 val_ptr = xb_map_cell_index(p, type->Map.value, vs2, idx2);
		xb_store_range_var(p, val0, xb_load_value(p, type->Map.key, xb_mem(xbMem_Reg, key_ptr, 0)));
		xb_store_range_var(p, val1, xb_load_value(p, type->Map.value, xb_mem(xbMem_Reg, val_ptr, 0)));
	}
	xb_push_target_list(p, rs->label, done, loop, nullptr);
	xb_build_stmt(p, rs->body);
	xb_pop_target_list(p);
	xb_set_debug_end_loc(p, rs->body);
	xb_jump(p, loop);
	xb_start_block(p, done);
}

// a 128 bit set, as two 64 bit words
gb_internal void xb_build_range_bit_set_128(xbProc *p, AstRangeStmt *rs, Type *et, xbValue set, Ast *val0) {
	BigInt all = exact_bit_set_all_set_mask(et).value_integer;
	BigInt mask = {};
	big_int_from_u64(&mask, ~cast(u64)0);
	BigInt shift = {};
	big_int_from_u64(&shift, 64);
	BigInt lo = {}, hi = {};
	big_int_and(&lo, &all, &mask);
	big_int_shr(&hi, &all, &shift);
	big_int_and(&hi, &hi, &mask);

	xbPair bits = xb_pair_of(p, set);
	xbMem rem_lo = xb_add_local(p, t_u64, false);
	xbMem rem_hi = xb_add_local(p, t_u64, false);
	xb_store(p, xbType_I64, rem_lo, xb_binop(p, xbOp_And, xbType_I64, bits.lo, xb_i64(p, cast(i64)big_int_to_u64(&lo))));
	xb_store(p, xbType_I64, rem_hi, xb_binop(p, xbOp_And, xbType_I64, bits.hi, xb_i64(p, cast(i64)big_int_to_u64(&hi))));
	xbMem index = xb_add_local(p, t_i64, false);

	xbBlock *loop = xb_new_block(p);
	xbBlock *low = xb_new_block(p);
	xbBlock *check_high = xb_new_block(p);
	xbBlock *high = xb_new_block(p);
	xbBlock *body = xb_new_block(p);
	xbBlock *done = xb_new_block(p);
	xb_jump(p, loop);

	xb_start_block(p, loop);
	u32 l = xb_load(p, xbType_I64, rem_lo);
	xb_branch(p, xb_cmp(p, xbCond_NE, xbType_I64, l, xb_i64(p, 0)), low, check_high);

	xb_start_block(p, low);
	u32 l2 = xb_load(p, xbType_I64, rem_lo);
	xb_store(p, xbType_I64, index, xb_unop(p, xbOp_Ctz, xbType_I64, l2));
	xb_store(p, xbType_I64, rem_lo, xb_binop(p, xbOp_And, xbType_I64, l2, xb_binop(p, xbOp_Sub, xbType_I64, l2, xb_i64(p, 1))));
	xb_jump(p, body);

	xb_start_block(p, check_high);
	u32 h = xb_load(p, xbType_I64, rem_hi);
	xb_branch(p, xb_cmp(p, xbCond_NE, xbType_I64, h, xb_i64(p, 0)), high, done);

	xb_start_block(p, high);
	u32 h2 = xb_load(p, xbType_I64, rem_hi);
	xb_store(p, xbType_I64, index, xb_binop(p, xbOp_Add, xbType_I64, xb_i64(p, 64), xb_unop(p, xbOp_Ctz, xbType_I64, h2)));
	xb_store(p, xbType_I64, rem_hi, xb_binop(p, xbOp_And, xbType_I64, h2, xb_binop(p, xbOp_Sub, xbType_I64, h2, xb_i64(p, 1))));
	xb_jump(p, body);

	xb_start_block(p, body);
	Type *elem = et->BitSet.elem;
	xbValue val = xb_emit_conv(p, xb_value_reg(t_i64, xb_load(p, xbType_I64, index)), elem);
	val = xb_emit_arith(p, Token_Add, val, xb_const_int(p, elem, et->BitSet.lower), elem);
	xb_store_range_var(p, val0, val);
	xb_push_target_list(p, rs->label, done, loop, nullptr);
	xb_build_stmt(p, rs->body);
	xb_pop_target_list(p);
	xb_set_debug_end_loc(p, rs->body);
	xb_jump(p, loop);
	xb_start_block(p, done);
}

gb_internal void xb_build_range_bit_set(xbProc *p, AstRangeStmt *rs, Type *et) {
	Ast *expr = unparen_expr(rs->expr);
	Ast *val0 = rs->vals.count > 0 ? xb_strip_and_prefix(rs->vals[0]) : nullptr;
	if (rs->reverse) XB_UNSUPPORTED(p, "#reverse bit_set range");
	xbValue set = xb_build_expr(p, expr);
	if (is_type_pointer(set.type)) set = xb_load_value(p, type_deref(set.type), xb_mem_from_ptr(p, set));
	Type *mask_type = bit_set_to_int(et);
	xbType st = xb_scalar_type(et);
	if (st == xbType_None && type_size_of(et) == 16) {
		xb_build_range_bit_set_128(p, rs, et, set, val0);
		return;
	}
	if (st == xbType_None) XB_UNSUPPORTED(p, "large bit_set range");
	BigInt all = exact_bit_set_all_set_mask(et).value_integer;
	u64 all_mask = big_int_to_u64(&all);
	u32 initial = xb_binop(p, xbOp_And, st, xb_value_to_reg(p, set), xb_iconst(p, st, cast(i64)all_mask));
	xbMem remaining = xb_add_local(p, mask_type, false);
	xb_store(p, st, remaining, initial);
	xbBlock *loop = xb_new_block(p);
	xbBlock *body = xb_new_block(p);
	xbBlock *done = xb_new_block(p);
	xb_jump(p, loop);
	xb_start_block(p, loop);
	u32 rem = xb_load(p, st, remaining);
	xb_branch(p, xb_cmp(p, xbCond_NE, st, rem, xb_iconst(p, st, 0)), body, done);
	xb_start_block(p, body);
	u32 rem2 = xb_load(p, st, remaining);
	u32 tz = xb_unop(p, xbOp_Ctz, st, rem2);
	Type *elem = et->BitSet.elem;
	xbValue val = xb_emit_conv(p, xb_value_reg(mask_type, tz), elem);
	val = xb_emit_arith(p, Token_Add, val, xb_const_int(p, elem, et->BitSet.lower), elem);
	u32 reduced = xb_binop(p, xbOp_And, st, rem2, xb_binop(p, xbOp_Sub, st, rem2, xb_iconst(p, st, 1)));
	xb_store(p, st, remaining, reduced);
	xb_store_range_var(p, val0, val);
	xb_push_target_list(p, rs->label, done, loop, nullptr);
	xb_build_stmt(p, rs->body);
	xb_pop_target_list(p);
	xb_set_debug_end_loc(p, rs->body);
	xb_jump(p, loop);
	xb_start_block(p, done);
}

gb_internal void xb_build_range_soa(xbProc *p, AstRangeStmt *rs) {
	Ast *expr = unparen_expr(rs->expr);
	Ast *val0 = rs->vals.count > 0 ? xb_strip_and_prefix(rs->vals[0]) : nullptr;
	Ast *val1 = rs->vals.count > 1 ? xb_strip_and_prefix(rs->vals[1]) : nullptr;

	xbAddr array = xb_build_addr(p, expr);
	if (array.kind != xbAddr_Default) XB_UNSUPPORTED(p, "range over special soa addr");
	Type *t = array.type;
	xbMem container = array.mem;
	if (is_type_pointer(t)) {
		container = xb_mem(xbMem_Reg, xb_load(p, xbType_I64, container), 0);
		t = type_deref(t);
	}
	i32 cont_local = xb_add_local_raw(p, 8, 8);
	xb_store(p, xbType_I64, xb_mem(xbMem_Local, cast(u32)cont_local), xb_lea(p, container));
	u32 count = xb_soa_len(p, t, container);
	xbMem count_mem = xb_add_local(p, t_int, false);
	xb_store(p, xbType_I64, count_mem, count);
	i32 index_local = xb_add_local_raw(p, 8, 8);
	xbMem index_mem = xb_mem(xbMem_Local, cast(u32)index_local);

	xbBlock *loop = xb_new_block(p);
	xbBlock *body = xb_new_block(p);
	xbBlock *done = xb_new_block(p);
	if (!rs->reverse) {
		xb_store(p, xbType_I64, index_mem, xb_iconst(p, xbType_I64, -1));
		xb_jump(p, loop);
		// LLVM compares with the length it took before the loop, a constant for a fixed #soa array
		xb_start_block(p, loop, base_type(t)->Struct.soa_kind == StructSoa_Fixed);
		u32 incr = xb_binop(p, xbOp_Add, xbType_I64, xb_load(p, xbType_I64, index_mem), xb_iconst(p, xbType_I64, 1));
		xb_store(p, xbType_I64, index_mem, incr);
		xb_branch(p, xb_cmp(p, xbCond_SLT, xbType_I64, incr, xb_load(p, xbType_I64, count_mem)), body, done);
	} else {
		xb_store(p, xbType_I64, index_mem, xb_load(p, xbType_I64, count_mem));
		xb_jump(p, loop);
		xb_start_block(p, loop);
		u32 decr = xb_binop(p, xbOp_Sub, xbType_I64, xb_load(p, xbType_I64, index_mem), xb_iconst(p, xbType_I64, 1));
		xb_store(p, xbType_I64, index_mem, decr);
		xb_branch(p, xb_cmp(p, xbCond_SLT, xbType_I64, decr, xb_iconst(p, xbType_I64, 0)), done, body);
	}
	xb_start_block(p, body);
	if (val0 != nullptr && !is_blank_ident(val0)) {
		Entity *e = entity_of_node(val0);
		if (e != nullptr) {
			xbVar v = {};
			v.mem = xb_mem(xbMem_Local, cast(u32)cont_local);
			v.is_soa = true;
			v.soa_index_local = index_local;
			v.soa_container = t;
			map_set(&p->vars, e, v);
		}
	}
	if (val1 != nullptr && !is_blank_ident(val1)) {
		xb_store_range_var(p, val1, xb_value_reg(t_int, xb_load(p, xbType_I64, index_mem)));
	}
	xb_push_target_list(p, rs->label, done, loop, nullptr);
	xb_build_stmt(p, rs->body);
	xb_pop_target_list(p);
	xb_set_debug_end_loc(p, rs->body);
	xb_jump(p, loop);
	xb_start_block(p, done);
}

gb_internal void xb_build_range_stmt(xbProc *p, AstRangeStmt *rs) {
	xb_open_scope(p);
	if (rs->init != nullptr) {
		xb_build_stmt(p, rs->init);
	}
	Ast *expr = unparen_expr(rs->expr);
	if (is_ast_range(expr)) {
		xb_build_range_interval(p, rs, expr);
	} else {
		TypeAndValue tav = type_and_value_of_expr(expr);
		if (tav.mode == Addressing_Type) {
			xb_build_range_enum(p, rs, type_deref(tav.type));
		} else {
			Type *et = type_of_expr(expr);
			Type *t = base_type(type_deref(et));
			if (is_type_soa_struct(t)) {
				xb_build_range_soa(p, rs);
			} else if (t->kind == Type_Tuple) {
				xb_build_range_tuple(p, rs);
			} else if (is_type_string(t) && !is_type_cstring(t) && !is_type_cstring16(t)) {
				xb_build_range_string(p, rs);
			} else if (t->kind == Type_Array || t->kind == Type_EnumeratedArray || t->kind == Type_Slice || t->kind == Type_DynamicArray ||
			           t->kind == Type_FixedCapacityDynamicArray) {
				xb_build_range_indexed(p, rs);
			} else if (t->kind == Type_BitSet) {
				xb_build_range_bit_set(p, rs, t);
			} else if (t->kind == Type_Map) {
				xb_build_range_map(p, rs, t);
			} else {
				gbString r = gb_string_make(permanent_allocator(), "range over ");
				r = gb_string_appendc(r, type_to_string(t));
				if (t->kind == Type_Map) r = gb_string_make(permanent_allocator(), "range over map");
				XB_UNSUPPORTED(p, r);
			}
		}
	}
	xb_close_scope(p, is_ast_range(expr) ? expr->BinaryExpr.left : rs->body);
}

gb_internal void xb_build_switch_stmt(xbProc *p, AstSwitchStmt *ss) {
	xb_open_scope(p);
	if (ss->init != nullptr) {
		xb_build_stmt(p, ss->init);
	}
	xbValue tag = {};
	bool has_tag = ss->tag != nullptr;
	if (has_tag) {
		xbValue v = xb_build_expr(p, ss->tag);
		tag = xb_value_copy_to_temp(p, v);
		if (xb_is_scalar(v.type)) {
			tag = xb_load_value(p, v.type, tag.mem);
		}
	}
	ast_node(body, BlockStmt, ss->body);
	Slice<Ast *> clauses = body->stmts;
	xbBlock *done = xb_new_block(p);

	auto bodies = array_make<xbBlock *>(xb_allocator(), clauses.count);
	defer (array_free(&bodies));
	xbBlock *default_block = nullptr;
	isize default_index = -1;
	for_array(i, clauses) {
		bodies[i] = xb_new_block(p);
		ast_node(cc, CaseClause, clauses[i]);
		if (cc->list.count == 0) {
			default_block = bodies[i];
			default_index = i;
		}
	}

	// tests, in order. LLVM makes a jump table of constant integer cases, all on the switch's line,
	// other tests belong to their case's line
	bool trivial = lb_switch_stmt_can_be_trivial_jump_table(ss, nullptr);
	for_array(i, clauses) {
		ast_node(cc, CaseClause, clauses[i]);
		if (!trivial && cc->list.count > 0) xb_set_debug_loc(p, ast_token(clauses[i]).pos);
		for (Ast *expr : cc->list) {
			expr = unparen_expr(expr);
			xbBlock *next = xb_new_block(p);
			u32 cond = 0;
			if (is_ast_range(expr)) {
				ast_node(ie, BinaryExpr, expr);
				xbValue lo = xb_build_expr(p, ie->left);
				xbValue hi = xb_build_expr(p, ie->right);
				TokenKind op = ie->op.kind == Token_RangeHalf ? Token_Lt : Token_LtEq;
				u32 c1 = xb_value_to_reg(p, xb_emit_comp(p, Token_LtEq, lo, tag));
				u32 c2 = xb_value_to_reg(p, xb_emit_comp(p, op, tag, hi));
				cond = xb_binop(p, xbOp_And, xbType_I8, c1, c2);
			} else if (has_tag) {
				xbValue v = xb_build_expr(p, expr);
				cond = xb_value_to_reg(p, xb_emit_comp(p, Token_CmpEq, tag, v));
			} else {
				xbValue v = xb_build_expr(p, expr);
				cond = xb_to_bool_reg(p, v);
			}
			xb_branch(p, cond, bodies[i], next);
			xb_start_block(p, next);
		}
	}
	xb_jump(p, default_block ? default_block : done);

	for_array(i, clauses) {
		ast_node(cc, CaseClause, clauses[i]);
		xbBlock *fall = done;
		if (i+1 < clauses.count) {
			fall = bodies[i+1];
		}
		xb_start_block(p, bodies[i]);
		xb_push_target_list(p, ss->label, done, nullptr, fall);
		xb_open_scope(p);
		xb_build_stmt_list(p, cc->stmts);
		xb_close_scope(p, clauses[i]);
		xb_pop_target_list(p);
		xb_jump(p, done);
	}
	xb_start_block(p, done);
	xb_close_scope(p, ss->body);
}

gb_internal void xb_bind_var(xbProc *p, Entity *e, xbMem mem, bool indirect) {
	xbVar v = {mem, indirect};
	map_set(&p->vars, e, v);
}

// binds the implicit entity of a type switch clause to a pointer value
gb_internal void xb_bind_var_ptr(xbProc *p, Entity *e, u32 ptr) {
	i32 l = xb_add_local_raw(p, 8, 8);
	xbMem m = xb_mem(xbMem_Local, cast(u32)l);
	xb_store(p, xbType_I64, m, ptr);
	xb_bind_var(p, e, m, true);
	xb_add_debug_var(p, e, m, true, false);
}

gb_internal void xb_store_type_case_implicit(xbProc *p, Ast *clause, xbValue value, bool value_is_ptr, bool is_default_case) {
	Entity *e = implicit_entity_of_node(clause);
	GB_ASSERT(e != nullptr);
	if (e->flags & EntityFlag_Value) {
		xbMem m = xb_add_local_entity(p, e, false);
		if (value_is_ptr && !are_types_identical(e->type, value.type)) {
			xb_store_value(p, m, xb_load_value(p, e->type, xb_mem_from_ptr(p, value)));
		} else {
			xb_store_value(p, m, value);
		}
	} else {
		GB_ASSERT(value_is_ptr);
		xb_bind_var_ptr(p, e, xb_value_to_reg(p, value));
	}
}

gb_internal void xb_build_type_switch_stmt(xbProc *p, AstTypeSwitchStmt *ss) {
	xb_open_scope(p);
	ast_node(as, AssignStmt, ss->tag);
	xbValue parent = xb_build_expr(p, as->rhs[0]);
	bool is_parent_ptr = is_type_pointer(parent.type);
	Type *parent_base_type = type_deref(parent.type);
	TypeSwitchKind switch_kind = check_valid_type_switch_type(parent.type);

	xbValue parent_value = parent;
	u32 parent_ptr = 0;
	if (is_parent_ptr) {
		parent_ptr = xb_value_to_reg(p, parent);
	} else {
		parent_ptr = xb_lea(p, xb_address_from_load_or_generate_local(p, parent));
	}
	// both are needed in other blocks
	xbMem parent_ptr_mem = xb_add_local(p, t_rawptr, false);
	xb_store(p, xbType_I64, parent_ptr_mem, parent_ptr);
	if (parent_value.kind == xbValue_Reg) {
		parent_value = xb_value_copy_to_temp(p, parent_value);
	}

	xbType tag_type = xbType_I64;
	u32 tag = 0;
	Type *ut = base_type(parent_base_type);
	if (switch_kind == TypeSwitch_Union) {
		xbMem um = xb_mem(xbMem_Reg, parent_ptr, 0);
		if (is_type_union_maybe_pointer(ut)) {
			u32 d = xb_load(p, xbType_I64, um);
			tag = xb_cmp(p, xbCond_NE, xbType_I64, d, xb_iconst(p, xbType_I64, 0));
			tag_type = xbType_I8;
		} else if (type_size_of(ut) == 0 || union_tag_size(ut) == 0) {
			tag_type = xbType_I64;
			tag = xb_iconst(p, xbType_I64, 0);
		} else {
			tag_type = xb_scalar_type(union_tag_type(ut));
			tag = xb_load(p, tag_type, xb_mem_offset(um, ut->Union.variant_block_size));
		}
	} else if (switch_kind == TypeSwitch_Any) {
		tag = xb_load(p, xbType_I64, xb_mem(xbMem_Reg, parent_ptr, 8));
	} else {
		XB_UNSUPPORTED(p, "type switch kind");
	}
	xbMem tag_mem = xb_add_local(p, t_u64, false);
	xb_store(p, tag_type, tag_mem, tag);

	ast_node(body, BlockStmt, ss->body);
	xbBlock *done = xb_new_block(p);
	xbBlock *default_block = nullptr;
	for (Ast *clause : body->stmts) {
		ast_node(cc, CaseClause, clause);
		if (cc->list.count == 0) {
			default_block = xb_new_block(p);
		}
	}

	bool all_by_reference = false;
	for (Ast *clause : body->stmts) {
		ast_node(cc, CaseClause, clause);
		if (cc->list.count != 1) continue;
		Entity *case_entity = implicit_entity_of_node(clause);
		all_by_reference |= (case_entity->flags & EntityFlag_Value) == 0;
		break;
	}
	i32 backing_local = -1;
	if (!all_by_reference) {
		i64 max_size = 0;
		i64 max_align = 1;
		bool found = false;
		for (Ast *clause : body->stmts) {
			ast_node(cc, CaseClause, clause);
			if (cc->list.count != 1) continue;
			Entity *case_entity = implicit_entity_of_node(clause);
			if (!is_type_untyped_nil(case_entity->type)) {
				max_size = gb_max(max_size, type_size_of(case_entity->type));
				max_align = gb_max(max_align, type_align_of(case_entity->type));
				found = true;
			}
		}
		if (found) {
			backing_local = xb_add_local_raw(p, max_size, max_align);
		}
	}

	// the dispatch, as a chain of comparisons
	auto bodies = array_make<xbBlock *>(xb_allocator(), body->stmts.count);
	defer (array_free(&bodies));
	for_array(i, body->stmts) {
		ast_node(cc, CaseClause, body->stmts[i]);
		bodies[i] = cc->list.count == 0 ? default_block : xb_new_block(p);
		for (Ast *type_expr : cc->list) {
			Type *case_type = type_of_expr(type_expr);
			i64 on_val = 0;
			if (switch_kind == TypeSwitch_Union) {
				if (is_type_untyped_nil(case_type)) {
					on_val = 0;
				} else {
					on_val = union_variant_index_checked(ut, case_type);
				}
			} else {
				on_val = is_type_untyped_nil(case_type) ? 0 : cast(i64)type_hash_canonical_type(default_type(case_type));
			}
			xbBlock *next = xb_new_block(p);
			u32 t = xb_load(p, tag_type, tag_mem);
			xb_branch(p, xb_cmp(p, xbCond_EQ, tag_type, t, xb_iconst(p, tag_type, on_val)), bodies[i], next);
			xb_start_block(p, next);
		}
	}
	xb_jump(p, default_block ? default_block : done);

	for_array(i, body->stmts) {
		Ast *clause = body->stmts[i];
		ast_node(cc, CaseClause, clause);
		Entity *case_entity = implicit_entity_of_node(clause);
		xb_open_scope(p);
		xb_start_block(p, bodies[i]);
		xb_set_debug_loc(p, ast_token(clause).pos);
		u32 pp = xb_load(p, xbType_I64, parent_ptr_mem);
		xbValue pptr = xb_value_reg(alloc_type_pointer(parent_base_type), pp);
		if (cc->list.count == 0) {
			if (case_entity->flags & EntityFlag_Value) {
				xb_store_type_case_implicit(p, clause, is_parent_ptr ? pptr : parent_value, is_parent_ptr, true);
			} else {
				xb_store_type_case_implicit(p, clause, pptr, true, true);
			}
		} else {
			bool saw_nil = false;
			for (Ast *type_expr : cc->list) {
				if (is_type_untyped_nil(type_of_expr(type_expr))) saw_nil = true;
			}
			bool by_reference = (case_entity->flags & EntityFlag_Value) == 0;
			if (cc->list.count == 1 && !saw_nil) {
				u32 data = 0;
				if (switch_kind == TypeSwitch_Union) {
					data = pp;
				} else {
					data = xb_load(p, xbType_I64, xb_mem(xbMem_Reg, pp, 0));
				}
				if (backing_local >= 0) {
					xbMem bm = xb_mem(xbMem_Local, cast(u32)backing_local);
					xb_memcopy(p, bm, xb_mem(xbMem_Reg, data, 0), type_size_of(case_entity->type));
					xb_bind_var(p, case_entity, bm, false);
					xb_add_debug_var(p, case_entity, bm, false, false);
				} else {
					GB_ASSERT(by_reference);
					xb_bind_var_ptr(p, case_entity, data);
				}
			} else {
				if (by_reference) {
					xb_store_type_case_implicit(p, clause, pptr, true, false);
				} else {
					xb_store_type_case_implicit(p, clause, is_parent_ptr ? pptr : parent_value, is_parent_ptr, false);
				}
			}
		}
		xb_push_target_list(p, ss->label, done, nullptr, nullptr);
		xb_build_stmt_list(p, cc->stmts);
		xb_close_scope(p, clause);
		xb_pop_target_list(p);
		xb_jump(p, done);
	}
	xb_start_block(p, done);
	xb_close_scope(p, ss->body);
}

gb_internal void xb_build_static_variables(xbProc *p, AstValueDecl *vd) {
	xbModule *m = p->m;
	for_array(i, vd->names) {
		Ast *ident = vd->names[i];
		Entity *e = entity_of_node(ident);
		bool tls = e->Variable.thread_local_model.len != 0;
		xbSection sec = tls ? xbSection_TData : xbSection_Data;
		i64 size = gb_max(type_size_of(e->type), cast(i64)1);
		i64 align = gb_max(gb_max(type_align_of(e->type), cast(i64)e->Variable.custom_align), cast(i64)1);
		if (i64 realign = lb_tls_realign(e)) {
			if (vd->values.count > 0) XB_UNSUPPORTED(p, "initialized over-aligned thread local");
			size += realign - 16;
			align = 16;
		}
		if (p->inl != nullptr) {
			// the inlined copies share one storage, which may differ from the procedure's own,
			// so only one that is never written
			if (!e->Variable.is_rodata) XB_UNSUPPORTED(p, "inlined static variable");
			if (i32 *shared = map_get(&m->inline_statics, e)) {
				xbVar v = {};
				v.mem = xb_mem(xbMem_Sym, cast(u32)*shared);
				map_set(&p->vars, e, v);
				if (p->family) map_set(&p->family->statics, e, *shared);
				continue;
			}
		}
		i64 at = xb_section_reserve(m, sec, size, align);

		if (vd->values.count > 0) {
			Ast *ast_value = vd->values[i];
			char const *reason = nullptr;
			if (is_type_any(e->type)) {
				Type *var_type = default_type(ast_value->tav.type);
				i32 backing = xb_const_global(m, var_type, ast_value->tav.value, true, &reason);
				if (backing < 0) XB_UNSUPPORTED(p, reason);
				xb_add_reloc(m, sec, xbReloc_Abs64, at, backing, 0);
				u64 id = type_hash_canonical_type(var_type);
				gb_memmove(m->sections[sec].data + at + 8, &id, 8);
			} else if (!xb_const_write_at(m, sec, at, e->type, ast_value->tav.value, &reason)) {
				XB_UNSUPPORTED(p, reason);
			}
		}

		char name[96] = {};
		// thread locals get a real symbol, TLS relocations want one
		gb_snprintf(name, gb_size_of(name), tls ? "__$xb_tls_static.%lld" : ".Lxb.static.%lld", cast(long long)at);
		i32 sym = xb_symbol(m, make_string_c(name));
		xbSymbol *s = &m->symbols[sym];
		s->section = sec;
		s->offset = at;
		s->size = size;
		s->flags = tls ? (xbSymbolFlag_Global | xbSymbolFlag_Hidden | xbSymbolFlag_TLS) : 0;
		s->realign = lb_tls_realign(e);

		if (!tls) {
			// a thread local's address is asked for at each use, see xb_tls_mem
			xbVar v = {};
			v.mem = xb_mem(xbMem_Sym, cast(u32)sym);
			map_set(&p->vars, e, v);
		}
		if (p->family) map_set(&p->family->statics, e, sym);
		if (p->inl != nullptr) map_set(&m->inline_statics, e, sym);

		if (!is_blank_ident(e->token.string)) {
			xbDebugVar dv = {};
			dv.name = e->token.string;
			dv.type = e->type;
			dv.local = -1;
			dv.sym = sym;
			dv.line = e->token.pos.line;
			array_add(&p->debug_vars, dv);
		}
	}
}

gb_internal void xb_build_unroll_range_stmt(xbProc *p, AstUnrollRangeStmt *rs) {
	xb_open_scope(p);
	if (rs->init != nullptr) xb_build_stmt(p, rs->init);
	Ast *val0 = xb_strip_and_prefix(rs->val0);
	Ast *val1 = xb_strip_and_prefix(rs->val1);
	Type *val0_type = (val0 && !is_blank_ident(val0)) ? type_of_expr(val0) : nullptr;
	Type *val1_type = (val1 && !is_blank_ident(val1)) ? type_of_expr(val1) : nullptr;
	xbMem v0 = {}, v1 = {};
	if (val0_type) v0 = xb_add_local_entity(p, entity_of_node(val0), true);
	if (val1_type) v1 = xb_add_local_entity(p, entity_of_node(val1), true);
	Ast *expr = unparen_expr(rs->expr);
	TypeAndValue tav = type_and_value_of_expr(expr);
	auto iteration = [&](xbValue a, xbValue b) {
		if (val0_type) xb_store_value(p, v0, xb_emit_conv(p, a, val0_type));
		if (val1_type) xb_store_value(p, v1, xb_emit_conv(p, b, val1_type));
		xb_build_stmt(p, rs->body);
	};
	if (rs->args.count != 0) XB_UNSUPPORTED(p, "#unroll(n)");
	if (is_ast_range(expr)) {
		TokenKind op = expr->BinaryExpr.op.kind;
		ExactValue start = expr->BinaryExpr.left->tav.value;
		ExactValue end = expr->BinaryExpr.right->tav.value;
		ExactValue index = exact_value_i64(0);
		for (ExactValue val = start;
		     compare_exact_values(op != Token_RangeHalf ? Token_LtEq : Token_Lt, val, end);
		     val = exact_value_increment_one(val), index = exact_value_increment_one(index)) {
			iteration(val0_type ? xb_const_value(p, val0_type, val) : xbValue{},
			          val1_type ? xb_const_value(p, val1_type, index) : xbValue{});
		}
	} else if (tav.mode == Addressing_Type) {
		Type *bet = base_type(type_deref(tav.type));
		for_array(i, bet->Enum.fields) {
			Entity *field = bet->Enum.fields[i];
			iteration(val0_type ? xb_const_value(p, val0_type, field->Constant.value) : xbValue{},
			          val1_type ? xb_const_value(p, val1_type, exact_value_i64(i)) : xbValue{});
		}
	} else {
		Type *t = base_type(expr->tav.type);
		if (t->kind == Type_Basic && is_type_string(t) && expr->tav.mode == Addressing_Constant) {
			String str = expr->tav.value.value_string;
			isize offset = 0;
			do {
				Rune codepoint = 0;
				isize width = utf8_decode(str.text+offset, str.len-offset, &codepoint);
				iteration(val0_type ? xb_const_value(p, val0_type, exact_value_i64(codepoint)) : xbValue{},
				          val1_type ? xb_const_value(p, val1_type, exact_value_i64(offset)) : xbValue{});
				offset += width;
			} while (offset < str.len);
		} else if (t->kind == Type_Array || t->kind == Type_EnumeratedArray) {
			i64 count = t->kind == Type_Array ? t->Array.count : t->EnumeratedArray.count;
			Type *elem = t->kind == Type_Array ? t->Array.elem : t->EnumeratedArray.elem;
			if (count > 0) {
				xbValue v = xb_build_expr(p, expr);
				xbMem m = xb_address_from_load_or_generate_local(p, v);
				for (i64 i = 0; i < count; i++) {
					xbValue e = val0_type ? xb_load_value(p, elem, xb_mem_offset(m, i*type_size_of(elem))) : xbValue{};
					xbValue idx = {};
					if (val1_type) {
						if (t->kind == Type_EnumeratedArray) {
							ExactValue ev = exact_value_add(*t->EnumeratedArray.min_value, exact_value_i64(i));
							idx = xb_const_value(p, val1_type, ev);
						} else {
							idx = xb_const_value(p, val1_type, exact_value_i64(i));
						}
					}
					iteration(e, idx);
				}
			}
		} else {
			XB_UNSUPPORTED(p, "#unroll over type");
		}
	}
	xb_close_scope(p, rs->body);
}

gb_internal void xb_build_stmt(xbProc *p, Ast *node) {
	Ast *prev_stmt = p->curr_stmt;
	defer (p->curr_stmt = prev_stmt);
	p->curr_stmt = node;

	if (xb_curr_terminated(p)) {
		// unreachable code is not generated
		return;
	}

	xb_set_debug_loc(p, ast_token(node).pos);

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
	case_ast_node(fb, ForeignBlockDecl, node);
	case_end;
	case_ast_node(us, UsingStmt, node);
	case_end;
	case_ast_node(ws, WhenStmt, node);
		xb_build_when_stmt(p, ws);
	case_end;

	case_ast_node(bs, BlockStmt, node);
		xbBlock *done = nullptr;
		if (bs->label != nullptr) {
			xbBlock *body = xb_new_block(p);
			done = xb_new_block(p);
			xb_jump(p, body);
			xb_start_block(p, body);
			xbTargetList *tl = xb_push_target_list(p, bs->label, done, nullptr, nullptr);
			tl->is_block = true;
		}
		xb_open_scope(p);
		xb_build_stmt_list(p, bs->stmts);
		xb_close_scope(p, node);
		if (done != nullptr) {
			xb_jump(p, done);
			xb_start_block(p, done);
			xb_pop_target_list(p);
		}
	case_end;

	case_ast_node(vd, ValueDecl, node);
		if (!vd->is_mutable) {
			return;
		}
		for (Ast *name : vd->names) {
			if (!is_blank_ident(name)) {
				Entity *e = entity_of_node(name);
				if (e->flags & EntityFlag_Static) {
					xb_build_static_variables(p, vd);
					return;
				}
			}
		}
		if (vd->values.count == 0) {
			for (Ast *name : vd->names) {
				if (!is_blank_ident(name)) {
					xb_add_local_entity(p, entity_of_node(name), true);
				}
			}
			return;
		}
		auto inits = array_make<xbValue>(xb_allocator(), 0, vd->names.count);
		defer (array_free(&inits));
		for (Ast *rhs : vd->values) {
			xbValue init = xb_build_expr(p, rhs);
			if (vd->values.count > 1 && init.kind == xbValue_Mem) {
				init = xb_value_copy_to_temp(p, init);
			}
			xb_add_values_to_array(p, &inits, init);
		}
		GB_ASSERT(inits.count == vd->names.count);
		for_array(i, vd->names) {
			Ast *name = vd->names[i];
			if (is_blank_ident(name)) continue;
			Entity *e = entity_of_node(name);
			xbValue init = inits[i];
			bool uninit = init.kind == xbValue_Invalid && init.type != nullptr && is_type_untyped_uninit(init.type);
			xbMem m = xb_add_local_entity(p, e, false);
			if (uninit) {
				continue;
			}
			if (init.kind == xbValue_Invalid && init.type == nullptr) {
				xb_memzero(p, m, type_size_of(e->type));
				continue;
			}
			xb_store_value(p, m, xb_emit_conv(p, init, e->type));
		}
	case_end;

	case_ast_node(as, AssignStmt, node);
		xb_build_assign_stmt(p, as);
	case_end;

	case_ast_node(es, ExprStmt, node);
		xb_build_expr(p, es->expr);
	case_end;

	case_ast_node(ds, DeferStmt, node);
		xbDefer d = {};
		d.scope_index = p->scope_index;
		d.context_stack_count = p->context_stack.count;
		d.stmt = ds->stmt;
		array_add(&p->defers, d);
	case_end;

	case_ast_node(rs, ReturnStmt, node);
		xb_build_return_stmt(p, rs->results, ast_token(node).pos);
	case_end;

	case_ast_node(is, IfStmt, node);
		xb_build_if_stmt(p, node);
	case_end;

	case_ast_node(fs, ForStmt, node);
		xb_build_for_stmt(p, node);
	case_end;

	case_ast_node(rs, RangeStmt, node);
		xb_build_range_stmt(p, rs);
	case_end;

	case_ast_node(rs, UnrollRangeStmt, node);
		xb_build_unroll_range_stmt(p, rs);
	case_end;

	case_ast_node(ss, SwitchStmt, node);
		xb_build_switch_stmt(p, ss);
	case_end;

	case_ast_node(ss, TypeSwitchStmt, node);
		xb_build_type_switch_stmt(p, ss);
	case_end;

	case_ast_node(bs, BranchStmt, node);
		xbBlock *block = nullptr;
		if (bs->label != nullptr) {
			xbBranchBlocks bb = xb_lookup_branch_blocks(p, bs->label);
			switch (bs->token.kind) {
			case Token_break:    block = bb.break_;    break;
			case Token_continue: block = bb.continue_; break;
			}
		} else {
			for (xbTargetList *t = p->targets; t != nullptr && block == nullptr; t = t->prev) {
				if (t->is_block) continue;
				switch (bs->token.kind) {
				case Token_break:       block = t->break_;       break;
				case Token_continue:    block = t->continue_;    break;
				case Token_fallthrough: block = t->fallthrough_; break;
				}
			}
		}
		GB_ASSERT(block != nullptr);
		xb_emit_defer_stmts(p, false, block, xb_defer_pos(node));
		// the next case's body may follow right after, with no jump left on this line
		if (bs->token.kind == Token_fallthrough) xb_debug_line_nop(p);
		xb_jump(p, block);
	case_end;

	default:
		XB_UNSUPPORTED(p, "statement kind");
	}
}

////////////////////////////////////////////////////////////////
// Procedure bodies
////////////////////////////////////////////////////////////////

gb_internal void xb_param_in(xbProc *p, xbAbiPiece const &piece, xbMem dst) {
	xbParamIn in = {};
	in.loc = piece.loc;
	in.reg = piece.reg;
	in.type = piece.type;
	in.size = piece.size;
	in.stack_offset = piece.stack_offset;
	in.dst = dst;
	array_add(&p->params_in, in);
}

gb_internal i32 xb_param_ptr_local(xbProc *p, xbAbiFunc *abi, xbAbiArg const &arg, i32 part=0) {
	i32 l = xb_add_local_raw(p, 8, 8);
	xb_param_in(p, abi->pieces[arg.piece_index+part], xb_mem(xbMem_Local, cast(u32)l));
	return l;
}

gb_internal void xb_begin_proc(xbProc *p) {
	TypeProc *pt = &base_type(p->type)->Proc;
	xbAbiFunc *abi = p->abi;

	DeclInfo *decl = p->entity ? decl_info_of_entity(p->entity) : nullptr;
	if (decl != nullptr) {
		for (BlockLabel const &bl : decl->labels) {
			xbBranchBlocks bb = {bl.label, nullptr, nullptr};
			array_add(&p->branch_blocks, bb);
		}
	}

	xbBlock *entry = xb_new_block(p);
	xb_start_block(p, entry);
	if (p->entity) xb_set_debug_loc(p, p->entity->token.pos);

	p->sret_local = -1;
	p->ret_temp_local = -1;
	if (p->naked) return;
	if (abi->has_sret) {
		p->sret_local = xb_param_ptr_local(p, abi, abi->sret);
	}

	if (pt->params != nullptr) {
		isize param_index = 0;
		for (Entity *e : pt->params->Tuple.variables) {
			if (e->kind != Entity_Variable) continue;
			if (e->flags & EntityFlag_CVarArg) continue;
			xbAbiArg const &arg = abi->params[param_index++];
			bool named = e->token.string.len != 0 && !is_blank_ident(e->token.string);
			switch (arg.kind) {
			case xbArg_Ignore: {
				xbMem m = xb_add_local(p, e->type, true);
				xbVar v = {m, false};
				map_set(&p->vars, e, v);
				break;
			}
			case xbArg_Direct: {
				i64 size = type_size_of(e->type);
				for (i32 i = 0; i < arg.piece_count; i++) {
					xbAbiPiece const &piece = abi->pieces[arg.piece_index+i];
					size = gb_max(size, cast(i64)(piece.src_offset + piece.size));
				}
				i32 l = xb_add_local_raw(p, size, gb_max(type_align_of(e->type), cast(i64)8));
				xbMem m = xb_mem(xbMem_Local, cast(u32)l);
				for (i32 i = 0; i < arg.piece_count; i++) {
					xbAbiPiece const &piece = abi->pieces[arg.piece_index+i];
					xb_param_in(p, piece, xb_mem_offset(m, piece.src_offset));
				}
				xbVar v = {m, false};
				map_set(&p->vars, e, v);
				if (named) xb_add_debug_var(p, e, m, false, true);
				break;
			}
			case xbArg_Indirect: {
				i64 sz = type_size_of(e->type);
				if (arg.piece_count > 1) {
					// a vector split into parts, each behind its own pointer
					xbMem m = xb_add_local(p, e->type, false);
					for (i32 i = 0; i < arg.piece_count; i++) {
						i32 pl = xb_param_ptr_local(p, abi, arg, i);
						i64 off = i*arg.copy_part;
						xb_memcopy(p, xb_mem_offset(m, off), xb_mem(xbMem_Reg, xb_load(p, xbType_I64, xb_mem(xbMem_Local, cast(u32)pl)), 0), gb_min(cast(i64)arg.copy_part, sz - off));
					}
					xbVar v = {m, false};
					map_set(&p->vars, e, v);
					if (named) xb_add_debug_var(p, e, m, false, true);
					break;
				}
				i32 l = xb_param_ptr_local(p, abi, arg);
				if (is_calling_convention_odin(abi->cc) && sz <= 16) {
					// callee copy, like the LLVM backend
					xbMem m = xb_add_local(p, e->type, false);
					xb_memcopy(p, m, xb_mem(xbMem_Reg, xb_load(p, xbType_I64, xb_mem(xbMem_Local, cast(u32)l)), 0), sz);
					xbVar v = {m, false};
					map_set(&p->vars, e, v);
					if (named) xb_add_debug_var(p, e, m, false, true);
				} else {
					xbVar v = {xb_mem(xbMem_Local, cast(u32)l), true};
					map_set(&p->vars, e, v);
					if (named) xb_add_debug_var(p, e, v.mem, true, true);
				}
				break;
			}
			case xbArg_ByVal: {
				xbVar v = {xb_mem(xbMem_Incoming, 0, arg.stack_offset), false};
				// copy into the frame so the debugger and everything else can treat it as a local
				xbMem m = xb_add_local(p, e->type, false);
				xb_memcopy(p, m, v.mem, type_size_of(e->type));
				v.mem = m;
				map_set(&p->vars, e, v);
				if (named) xb_add_debug_var(p, e, m, false, true);
				break;
			}
			}
		}
	}

	if (abi->split_returns) {
		p->split_ret_locals = array_make<i32>(xb_allocator(), 0, abi->split_ret_ptrs.count);
		for (xbAbiArg const &a : abi->split_ret_ptrs) {
			array_add(&p->split_ret_locals, xb_param_ptr_local(p, abi, a));
		}
	}
	if (abi->is_odin_cc) {
		i32 l = xb_param_ptr_local(p, abi, abi->context);
		xb_push_context(p, xb_mem(xbMem_Local, cast(u32)l), true);
		xbDebugVar dv = {};
		dv.name = str_lit("context");
		dv.type = t_context;
		dv.local = l;
		dv.by_ref = true;
		dv.line = p->entity ? p->entity->token.pos.line : 0;
		array_add(&p->debug_vars, dv);
		p->context_stack[p->context_stack.count-1].scope_index = -1;
		p->context_stack[p->context_stack.count-1].uses = 1;
	}
	if (abi->ret.kind == xbArg_Direct) {
		Type *rt = reduce_tuple_to_single_type(pt->results);
		i64 size = type_size_of(rt);
		for (i32 i = 0; i < abi->ret.piece_count; i++) {
			xbAbiPiece const &piece = abi->pieces[abi->ret.piece_index+i];
			size = gb_max(size, cast(i64)(piece.src_offset + piece.size));
		}
		p->ret_temp_local = xb_add_local_raw(p, size, gb_max(type_align_of(rt), cast(i64)8));
		if (abi->split_returns) {
			// the direct part is only the last result
			Type *last = pt->results->Tuple.variables[pt->results->Tuple.variables.count-1]->type;
			gb_unused(last);
		}
	}

	if (pt->has_named_results) {
		for (Entity *e : pt->results->Tuple.variables) {
			if (e->token.string == "") continue;
			xbMem m = xb_add_local_entity(p, e, true);
			if (e->Variable.param_value.kind != ParameterValue_Invalid) {
				xbValue c = xb_handle_param_value(p, e->type, e->Variable.param_value, nullptr, nullptr);
				xb_store_value(p, m, xb_emit_conv(p, c, e->type));
			}
		}
	}
}

gb_internal void xb_end_proc(xbProc *p) {
	TypeProc *pt = &base_type(p->type)->Proc;
	if (!xb_curr_terminated(p)) {
		if (pt->result_count == 0) {
			xb_set_debug_end_loc(p, p->body);
			xb_emit_defer_stmts(p, true, nullptr, xb_defer_pos(p->body));
			if (!xb_curr_terminated(p)) {
				xb_emit_ret(p, {});
			}
		} else {
			xb_unreachable(p);
		}
	}
	// every placed block must end in a terminator
	for (xbBlock *b : p->order) {
		if (!xb_block_terminated(b)) {
			xbInstr i = xb_instr(xbOp_Unreachable);
			array_add(&b->instrs, i);
		}
	}
	if (xb_is_arm64()) {
		a64_check_proc(p);
	}
}

////////////////////////////////////////////////////////////////
// #force_inline
////////////////////////////////////////////////////////////////

// Like LLVM, which inlines these even without optimization, the callee's body is built
// straight into the caller. A body that cannot be inlined rolls the caller back to the
// call, which is then made normally.

gb_internal bool xb_proc_is_candidate(Entity *e);

gb_internal bool xb_should_inline(xbProc *p, Entity *e, ProcInlining call_inlining, ProcTailing tailing, Type *call_type) {
	if (e == nullptr || e->kind != Entity_Procedure) return false;
	if (tailing != ProcTailing_none) return false;
	if (!xb_proc_is_candidate(e)) return false;
	ProcInlining inlining = call_inlining;
	ProcInlining declared = e->decl_info->proc_lit->ProcLit.inlining;
	if (declared != ProcInlining_none) inlining = declared;
	if (inlining != ProcInlining_inline) return false;
	if (ptr_set_exists(&p->m->inline_failed, e)) return false;

	Type *pt = base_type(e->type);
	if (pt->Proc.c_vararg || pt->Proc.calling_convention == ProcCC_Naked) return false;
	// the body's parameters are the entities of the procedure's own type
	if (!are_types_identical(base_type(call_type), pt)) return false;
	if (e->Procedure.has_instrumentation && p->m->info->instrumentation_enter_entity != nullptr) return false;

	// a recursive procedure is inlined once, then called
	if (p->entity == e) return false;
	isize depth = 0;
	for (xbInline *in = p->inl; in != nullptr; in = in->prev) {
		if (in->caller == e) return false;
		depth += 1;
	}
	return depth < 16;
}

// Parameters are immutable, so a large argument in memory is used in place, as the Odin
// convention passes it by pointer.
gb_internal void xb_inline_bind_param(xbProc *p, Entity *e, xbValue v, ProcCallingConvention cc) {
	i64 size = type_size_of(e->type);
	if (v.kind == xbValue_Mem && is_calling_convention_odin(cc) && size > 16 &&
	    (v.mem.align == 0 || v.mem.align >= type_align_of(e->type))) {
		xbVar var = {v.mem, false};
		map_set(&p->vars, e, var);
		xb_add_debug_var(p, e, v.mem, false, false);
		return;
	}
	xbMem m = xb_add_local(p, e->type, false);
	if (v.kind == xbValue_Invalid) {
		xb_memzero(p, m, size);
	} else {
		xb_store_value(p, m, v);
	}
	xbVar var = {m, false};
	map_set(&p->vars, e, var);
	xb_add_debug_var(p, e, m, false, false);
}

gb_internal void xb_inline_return(xbProc *p, Array<xbValue> &results, TokenPos pos) {
	TypeProc *pt = &base_type(p->type)->Proc;
	xb_debug_line_nop(p);
	for_array(i, results) {
		i64 off = 0;
		if (results.count > 1) {
			Type *ft = nullptr;
			off = type_offset_of(pt->results, i, &ft);
		}
		xb_store_value(p, xb_mem_offset(p->inl->result, off), results[i]);
	}
	xb_emit_defer_stmts(p, true, nullptr, pos);
	if (!xb_curr_terminated(p)) {
		xb_inline_exit(p);
	}
}

gb_internal void xb_inline_body(xbProc *p, Entity *e, Slice<xbValue> args) {
	TypeProc *pt = &base_type(e->type)->Proc;
	Ast *body = e->decl_info->proc_lit->ProcLit.body;

	for (BlockLabel const &bl : e->decl_info->labels) {
		xbBranchBlocks bb = {bl.label, nullptr, nullptr};
		array_add(&p->branch_blocks, bb);
	}

	// the body's variables get a lexical scope of their own, which the debug info makes a frame
	array_add(&p->debug_scope_parent, p->debug_scope);
	xb_set_debug_scope(p, cast(i32)p->debug_scope_parent.count-1);
	p->inl->site.scope = p->debug_scope;
	array_add(&p->inline_sites, p->inl->site);
	xb_set_debug_loc(p, e->token.pos);

	if (pt->params != nullptr) {
		isize k = 0;
		for (Entity *pe : pt->params->Tuple.variables) {
			if (pe->kind != Entity_Variable) continue;
			GB_ASSERT(k < args.count);
			xb_inline_bind_param(p, pe, args[k++], pt->calling_convention);
		}
		GB_ASSERT(k == args.count);
	}
	if (pt->has_named_results) {
		for (Entity *re : pt->results->Tuple.variables) {
			if (re->token.string == "") continue;
			xbMem m = xb_add_local_entity(p, re, true);
			if (re->Variable.param_value.kind != ParameterValue_Invalid) {
				xbValue c = xb_handle_param_value(p, re->type, re->Variable.param_value, nullptr, nullptr);
				xb_store_value(p, m, xb_emit_conv(p, c, re->type));
			}
		}
	}

	xb_build_stmt(p, body);

	if (!xb_curr_terminated(p)) {
		if (pt->result_count == 0) {
			xb_emit_defer_stmts(p, true, nullptr, xb_defer_pos(body));
			if (!xb_curr_terminated(p)) xb_inline_exit(p);
		} else {
			xb_unreachable(p);
		}
	}
}

// Everything building the body may change, to roll back to.
struct xbInlineSave {
	xbBlock *curr;
	isize    curr_instrs;
	isize    blocks, order, vregs, locals, calls, asms;
	isize    debug_vars, debug_scope_parent, inline_sites, branch_blocks, selector_cache, context_stack;
	Array<xbDefer> defers;
	xbTargetList *targets;
	isize    scope_index;
	i32      debug_scope;
	i32      file_id, last_line, last_column;
	u16      state_flags;
	Ast *    curr_stmt;
	TokenPos branch_location_pos;
	Entity * entity;
	Type *   type;
	Ast *    body;
	DeclInfo *decl;
	jmp_buf *bail;
	xbInline *inl;
};

gb_internal void xb_inline_restore(xbProc *p, xbInlineSave const &s, bool rollback) {
	if (rollback) {
		p->curr = s.curr;
		p->curr->instrs.count = s.curr_instrs;
		p->blocks.count = s.blocks;
		p->order.count = s.order;
		p->vregs.count = s.vregs;
		p->locals.count = s.locals;
		p->calls.count = s.calls;
		p->asms.count = s.asms;
		p->debug_vars.count = s.debug_vars;
		p->debug_scope_parent.count = s.debug_scope_parent;
		p->inline_sites.count = s.inline_sites;
		p->file_id = s.file_id;
		p->last_line = s.last_line;
		p->last_column = s.last_column;
	}
	p->branch_blocks.count = s.branch_blocks;
	p->selector_cache.count = gb_min(p->selector_cache.count, s.selector_cache);
	p->context_stack.count = s.context_stack;
	p->defers = s.defers;
	p->targets = s.targets;
	p->scope_index = s.scope_index;
	p->debug_scope = s.debug_scope;
	p->state_flags = s.state_flags;
	p->curr_stmt = s.curr_stmt;
	p->branch_location_pos = s.branch_location_pos;
	p->entity = s.entity;
	p->type = s.type;
	p->body = s.body;
	p->decl = s.decl;
	p->bail = s.bail;
	p->inl = s.inl;
}

// Builds the body of `e` in place of a call to it with `args`, which are already converted
// to the parameter types. Returns false, with nothing emitted, if it cannot.
gb_internal bool xb_try_inline_call(xbProc *p, Entity *e, Slice<xbValue> args, Ast *call_expr, xbValue *res) {
	TypeProc *pt = &base_type(e->type)->Proc;
	isize param_count = 0;
	if (pt->params != nullptr) {
		for (Entity *pe : pt->params->Tuple.variables) {
			if (pe->kind == Entity_Variable) param_count += 1;
		}
	}
	if (param_count != args.count) return false;
	if (pt->calling_convention == ProcCC_Odin && p->context_stack.count == 0) {
		// made before the body, so every path through it sees the context
		xb_context_mem(p);
	}

	xbInlineSave s = {};
	s.curr = p->curr;
	s.curr_instrs = p->curr->instrs.count;
	s.blocks = p->blocks.count;
	s.order = p->order.count;
	s.vregs = p->vregs.count;
	s.locals = p->locals.count;
	s.calls = p->calls.count;
	s.asms = p->asms.count;
	s.debug_vars = p->debug_vars.count;
	s.debug_scope_parent = p->debug_scope_parent.count;
	s.inline_sites = p->inline_sites.count;
	s.branch_blocks = p->branch_blocks.count;
	s.selector_cache = p->selector_cache.count;
	s.context_stack = p->context_stack.count;
	s.defers = p->defers;
	s.targets = p->targets;
	s.scope_index = p->scope_index;
	s.debug_scope = p->debug_scope;
	s.file_id = p->file_id;
	s.last_line = p->last_line;
	s.last_column = p->last_column;
	s.state_flags = p->state_flags;
	s.curr_stmt = p->curr_stmt;
	s.branch_location_pos = p->branch_location_pos;
	s.entity = p->entity;
	s.type = p->type;
	s.body = p->body;
	s.decl = p->decl;
	s.bail = p->bail;
	s.inl = p->inl;
	TokenPos saved_fail_pos = p->m->fail_pos;

	xbInline inl = {};
	inl.prev = p->inl;
	inl.caller = p->entity;

	jmp_buf bail;
	p->bail = &bail;
	if (setjmp(bail) != 0) {
		if (p->m->verbose) {
			gb_printf_err("xb:   not inlining %.*s: %s\n", LIT(e->token.string), p->fail_reason);
		}
		// a generated procedure has no family, which some bodies need; others may still inline it
		if (p->family != nullptr) ptr_set_add(&p->m->inline_failed, e);
		xb_inline_restore(p, s, true);
		p->fail_reason = nullptr;
		p->fail_node = nullptr;
		p->m->fail_pos = saved_fail_pos;
		return false;
	}

	Type *rt = reduce_tuple_to_single_type(pt->results);
	if (rt != nullptr) inl.result = xb_add_local(p, rt, false);
	inl.exit = xb_new_block(p);
	inl.site.name = xb_entity_name(p->m, e);
	inl.site.decl_file = e->token.pos.file_id > 0 ? xb_file_id(p->m, e->token.pos.file_id) : 0;
	inl.site.decl_line = e->token.pos.line;
	inl.site.call_file = p->file_id;
	inl.site.call_line = gb_max(p->last_line, 0);
	inl.site.call_column = gb_max(p->last_column, 0);
	if (call_expr != nullptr) {
		TokenPos pos = ast_token(call_expr).pos;
		if (pos.file_id > 0 && pos.line > 0) {
			inl.site.call_file = xb_file_id(p->m, pos.file_id);
			inl.site.call_line = pos.line;
			inl.site.call_column = pos.column;
		}
	}

	p->inl = &inl;
	p->entity = e;
	p->type = e->type;
	p->body = e->decl_info->proc_lit->ProcLit.body;
	p->decl = e->decl_info;
	p->defers = array_make<xbDefer>(xb_allocator(), 0, 4);
	p->targets = nullptr;
	p->state_flags = 0;
	p->branch_location_pos = {};

	// the call's line needs code before the body's
	xb_debug_line_nop(p);
	xb_inline_body(p, e, args);

	xb_inline_restore(p, s, false);
	// the caller's code after the call has its own line row and scope
	p->last_line = -1;
	// Code after a terminator, like the end of the body's scope after its return, goes to a
	// block that is never placed.
	xbBlock *b = inl.exit_from;
	if (inl.exits == 1 && p->order.count > 0 && p->order[p->order.count-1] == b && b->instrs.count > 0 &&
	    b->instrs[b->instrs.count-1].op == xbOp_Jump && b->instrs[b->instrs.count-1].imm == inl.exit->index) {
		// the body's one return ends it: the caller goes on in the same block, where loads see
		// what the return stored
		b->instrs.count -= 1;
		p->curr = b;
	} else {
		xb_start_block(p, inl.exit);
	}
	xb_set_debug_scope(p, s.debug_scope);
	if (call_expr != nullptr) {
		xb_set_debug_loc(p, ast_token(call_expr).pos);
	} else if (s.last_line > 0) {
		// a call the compiler made goes on at the caller's line
		p->last_line = s.last_line;
		p->last_column = s.last_column;
		p->file_id = s.file_id;
		xbInstr loc = xb_instr(xbOp_Loc);
		loc.imm = s.last_line;
		loc.a = cast(u32)s.file_id;
		loc.b = cast(u32)s.last_column;
		xb_emit(p, loc);
	}

	if (pt->diverging) {
		xb_unreachable(p);
	}
	p->m->stats.calls_inlined += 1;
	*res = {};
	if (rt != nullptr) {
		*res = xb_load_value(p, rt, inl.result);
	}
	return true;
}
