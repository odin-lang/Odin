// SIMD vectors (#simd[N]T). They live in memory like arrays and every operation
// runs lane by lane, following lb_build_builtin_simd_proc and lb_emit_conv.

gb_internal i64 xb_simd_count(Type *t) {
	return get_array_type_count(t);
}

gb_internal Type *xb_simd_elem(Type *t) {
	return base_array_type(t);
}

// the vreg type of a lane, for operations that work on the lanes directly
gb_internal xbType xb_simd_st(xbProc *p, Type *elem) {
	xbType st = xb_scalar_type(elem);
	if (st == xbType_None || is_type_different_to_arch_endianness(elem)) {
		XB_UNSUPPORTED(p, "simd element type");
	}
	return st;
}

gb_internal bool xb_simd_is_signed(Type *elem) {
	return !is_type_unsigned(elem);
}

gb_internal xbMem xb_simd_mem(xbProc *p, xbValue v) {
	return xb_address_from_load_or_generate_local(p, v);
}

gb_internal xbValue xb_simd_lane(xbProc *p, Type *vt, xbMem m, i64 i) {
	Type *elem = xb_simd_elem(vt);
	return xb_load_value(p, elem, xb_mem_offset(m, i*type_size_of(elem)));
}

gb_internal u32 xb_simd_lane_reg(xbProc *p, Type *vt, xbMem m, i64 i) {
	return xb_value_to_reg(p, xb_simd_lane(p, vt, m, i));
}

// a new vector of type `t`, lane i is f(i)
template <typename F>
gb_internal xbValue xb_simd_build(xbProc *p, Type *t, F const &f) {
	Type *elem = xb_simd_elem(t);
	i64 count = xb_simd_count(t);
	i64 stride = type_size_of(elem);
	xbMem res = xb_add_local(p, t, false);
	for (i64 i = 0; i < count; i++) {
		xb_store_value(p, xb_mem_offset(res, i*stride), f(i));
	}
	return xb_value_mem(t, res);
}

// same, with the lanes as vregs of type st
template <typename F>
gb_internal xbValue xb_simd_build_reg(xbProc *p, Type *t, F const &f) {
	Type *elem = xb_simd_elem(t);
	return xb_simd_build(p, t, [&](i64 i) { return xb_value_reg(elem, f(i)); });
}

gb_internal u32 xb_simd_all_ones(xbProc *p, xbType st, u32 cond) {
	return xb_select(p, st, cond, xb_iconst(p, st, -1), xb_iconst(p, st, 0));
}

gb_internal u32 xb_simd_float_bits(xbProc *p, xbType st, u32 v) {
	return xb_convop(p, xbOp_Bitcast, st == xbType_F32 ? xbType_I32 : xbType_I64, st, v);
}

gb_internal u32 xb_simd_bits_float(xbProc *p, xbType st, u32 v) {
	return xb_convop(p, xbOp_Bitcast, st, st == xbType_F32 ? xbType_I32 : xbType_I64, v);
}

gb_internal u32 xb_simd_fabs(xbProc *p, xbType st, u32 x) {
	xbType it = st == xbType_F32 ? xbType_I32 : xbType_I64;
	i64 mask = it == xbType_I32 ? 0x7FFFFFFF : 0x7FFFFFFFFFFFFFFFll;
	u32 bits = xb_binop(p, xbOp_And, it, xb_simd_float_bits(p, st, x), xb_iconst(p, it, mask));
	return xb_simd_bits_float(p, st, bits);
}

// the magnitude of `mag` with the sign of `sgn`
gb_internal u32 xb_simd_copysign(xbProc *p, xbType st, u32 mag, u32 sgn) {
	xbType it = st == xbType_F32 ? xbType_I32 : xbType_I64;
	i64 sign = it == xbType_I32 ? cast(i64)0x80000000ll : cast(i64)0x8000000000000000ull;
	u32 m = xb_binop(p, xbOp_And, it, xb_simd_float_bits(p, st, mag), xb_iconst(p, it, ~sign));
	u32 s = xb_binop(p, xbOp_And, it, xb_simd_float_bits(p, st, sgn), xb_iconst(p, it, sign));
	return xb_simd_bits_float(p, st, xb_binop(p, xbOp_Or, it, m, s));
}

// llvm.ceil/floor/trunc/nearbyint: values from 2^mantissa up are already integers
gb_internal u32 xb_simd_round(xbProc *p, BuiltinProcId id, xbType st, u32 x) {
	f64 limit = st == xbType_F32 ? 8388608.0 : 4503599627370496.0;
	u32 lim = xb_fconst(p, st, limit);
	u32 ax = xb_simd_fabs(p, st, x);
	u32 in_range = xb_cmp(p, xbCond_FLT, st, ax, lim); // false for NaN and infinities
	u32 r = 0;
	if (id == BuiltinProc_simd_nearest) {
		// adding 2^mantissa rounds to the nearest integer, ties to even
		u32 t = xb_binop(p, xbOp_FSub, st, xb_binop(p, xbOp_FAdd, st, ax, lim), lim);
		r = xb_simd_copysign(p, st, t, x);
	} else {
		u32 i = xb_convop(p, xbOp_FToSI, xbType_I64, st, x);
		u32 t = xb_simd_copysign(p, st, xb_convop(p, xbOp_SIToF, st, xbType_I64, i), x);
		if (id == BuiltinProc_simd_floor) {
			u32 gt = xb_cmp(p, xbCond_FGT, st, t, x);
			t = xb_select(p, st, gt, xb_binop(p, xbOp_FSub, st, t, xb_fconst(p, st, 1.0)), t);
		} else if (id == BuiltinProc_simd_ceil) {
			u32 lt = xb_cmp(p, xbCond_FLT, st, t, x);
			t = xb_select(p, st, lt, xb_binop(p, xbOp_FAdd, st, t, xb_fconst(p, st, 1.0)), t);
		}
		r = t;
	}
	return xb_select(p, st, in_range, r, x);
}

// calls a C library procedure `name(T, ..) -> T`, like LLVM does for llvm.fma without the fma feature
gb_internal u32 xb_simd_libc_call(xbProc *p, char const *name, Type *ft, u32 *args, isize n) {
	if (build_context.no_crt) XB_UNSUPPORTED(p, "libm call without crt");
	GB_ASSERT(n <= 3);
	// one procedure type per float type and arity, so the ABI is computed once
	gb_local_persist gb_thread_local Type *cache[2][4] = {};
	Type **slot = &cache[are_types_identical(ft, t_f32) ? 0 : 1][n];
	if (*slot == nullptr) {
		Type *types[3] = {ft, ft, ft};
		*slot = alloc_type_proc_from_types(types, cast(unsigned)n, ft, false, ProcCC_CDecl);
	}
	Type *pt = *slot;
	i32 sym = xb_symbol(p->m, make_string_c(name));
	xb_sym_add_flags(p->m, sym, xbSymbolFlag_Func | xbSymbolFlag_Foreign);
	xbValue vals[3] = {};
	for (isize i = 0; i < n; i++) vals[i] = xb_value_reg(ft, args[i]);
	xbValue proc = xb_value_reg(pt, 0);
	return xb_value_to_reg(p, xb_emit_call_internal(p, proc, sym, xb_args(vals, n)));
}

gb_internal u32 xb_simd_fma(xbProc *p, Type *ft, u32 a, u32 b, u32 c) {
	xbType st = xb_scalar_type(ft);
	if (st != xbType_F32 && st != xbType_F64) XB_UNSUPPORTED(p, "fma type");
	if (!xb_is_arm64() && check_target_feature_is_enabled(str_lit("fma"), nullptr)) {
		return xb_fma(p, st, a, b, c);
	}
	u32 args[3] = {a, b, c};
	return xb_simd_libc_call(p, st == xbType_F32 ? "fmaf" : "fma", st == xbType_F32 ? t_f32 : t_f64, args, 3);
}

// minnum/maxnum style compare-select used by the reductions: a NaN accumulator is replaced
gb_internal u32 xb_simd_minmax_num(xbProc *p, bool is_min, xbType st, u32 acc, u32 x) {
	u32 pick_x = xb_cmp(p, is_min ? xbCond_FLT : xbCond_FGT, st, x, acc);
	u32 acc_nan = xb_cmp(p, xbCond_FNE, st, acc, acc);
	u32 c = xb_binop(p, xbOp_Or, xbType_I8, pick_x, acc_nan);
	return xb_select(p, st, c, x, acc);
}

gb_internal u32 xb_simd_saturate(xbProc *p, bool is_add, bool is_signed, xbType st, u32 a, u32 b) {
	u32 zero = xb_iconst(p, st, 0);
	if (!is_signed) {
		if (is_add) {
			u32 r = xb_binop(p, xbOp_Add, st, a, b);
			return xb_select(p, st, xb_cmp(p, xbCond_ULT, st, r, a), xb_iconst(p, st, -1), r);
		}
		return xb_select(p, st, xb_cmp(p, xbCond_ULT, st, a, b), zero, xb_binop(p, xbOp_Sub, st, a, b));
	}
	i32 bits = 8*xb_type_size(st);
	i64 max = cast(i64)((cast(u64)1 << (bits-1)) - 1);
	i64 min = -max - 1;
	u32 r = 0;
	u32 t = 0;
	if (is_add) {
		r = xb_binop(p, xbOp_Add, st, a, b);
		t = xb_binop(p, xbOp_And, st, xb_binop(p, xbOp_Xor, st, a, r), xb_binop(p, xbOp_Xor, st, b, r));
	} else {
		r = xb_binop(p, xbOp_Sub, st, a, b);
		t = xb_binop(p, xbOp_And, st, xb_binop(p, xbOp_Xor, st, a, b), xb_binop(p, xbOp_Xor, st, a, r));
	}
	u32 ovf = xb_cmp(p, xbCond_SLT, st, t, zero);
	u32 sat = xb_select(p, st, xb_cmp(p, xbCond_SLT, st, a, zero), xb_iconst(p, st, min), xb_iconst(p, st, max));
	return xb_select(p, st, ovf, sat, r);
}

////////////////////////////////////////////////////////////////
// Conversions and comparisons
////////////////////////////////////////////////////////////////

// one lane of a vector conversion (lb_emit_conv's #simd part)
gb_internal xbValue xb_simd_conv_lane(xbProc *p, xbValue v, Type *src_elem, Type *dst_elem) {
	src_elem = core_type(src_elem);
	if (is_type_different_to_arch_endianness(src_elem) || is_type_different_to_arch_endianness(dst_elem)) {
		XB_UNSUPPORTED(p, "simd endian conversion");
	}
	bool src_int = is_type_integer(src_elem) || is_type_pointer(src_elem) || is_type_boolean(src_elem);
	bool dst_int = is_type_integer(dst_elem) || is_type_pointer(dst_elem);
	if (src_int && dst_int) {
		xbType ss = xb_simd_st(p, src_elem);
		xbType ds = xb_simd_st(p, dst_elem);
		// inttoptr and ptrtoint zero extend
		bool sgn = !is_type_unsigned(src_elem) && !is_type_pointer(src_elem) && !is_type_pointer(dst_elem);
		return xb_value_reg(dst_elem, xb_int_resize(p, xb_value_to_reg(p, v), ss, ds, sgn));
	}
	if (is_type_integer(src_elem) && is_type_boolean(dst_elem)) {
		// icmp ne, then widened with the sign of the source: a signed true is all ones
		xbType ss = xb_simd_st(p, src_elem);
		xbType ds = xb_simd_st(p, dst_elem);
		u32 ne = xb_cmp(p, xbCond_NE, ss, xb_value_to_reg(p, v), xb_iconst(p, ss, 0));
		if (!is_type_unsigned(src_elem)) {
			return xb_value_reg(dst_elem, xb_simd_all_ones(p, ds, ne));
		}
		return xb_value_reg(dst_elem, xb_int_resize(p, ne, xbType_I8, ds, false));
	}
	if ((is_type_float(src_elem) || is_type_integer(src_elem)) && (is_type_float(dst_elem) || is_type_integer(dst_elem))) {
		return xb_emit_conv(p, v, dst_elem);
	}
	XB_UNSUPPORTED(p, "simd conversion");
	return {};
}

gb_internal xbValue xb_simd_conv(xbProc *p, xbValue v, Type *t) {
	Type *src = core_type(v.type);
	Type *dst = core_type(t);
	Type *dst_elem = xb_simd_elem(dst);
	if (is_type_simd_vector(src)) {
		Type *src_elem = xb_simd_elem(src);
		GB_ASSERT(xb_simd_count(src) == xb_simd_count(dst));
		if (are_types_identical(core_type(src_elem), core_type(dst_elem))) {
			return xb_reinterpret(p, v, t);
		}
		xbMem m = xb_simd_mem(p, v);
		return xb_simd_build(p, t, [&](i64 i) {
			return xb_simd_conv_lane(p, xb_simd_lane(p, src, m, i), src_elem, dst_elem);
		});
	}
	if (is_type_array_like(src) || is_type_matrix(src)) {
		XB_UNSUPPORTED(p, "simd conversion");
	}
	// a scalar is spread over the lanes
	xbValue e = xb_emit_conv(p, v, dst_elem);
	if (e.kind == xbValue_Mem) e = xb_value_copy_to_temp(p, e);
	return xb_simd_build(p, t, [&](i64 i) { return e; });
}

// == and != of whole vectors: every lane equal, or any lane different
gb_internal xbValue xb_simd_comp(xbProc *p, TokenKind op, xbValue left, xbValue right) {
	if (op != Token_CmpEq && op != Token_NotEq) XB_UNSUPPORTED(p, "simd ordering");
	Type *vt = core_type(left.type);
	Type *elem = xb_simd_elem(vt);
	xbType st = xb_simd_st(p, elem);
	xbMem a = xb_simd_mem(p, left);
	xbMem b = xb_simd_mem(p, xb_emit_conv(p, right, left.type));
	bool eq = op == Token_CmpEq;
	u32 acc = xb_iconst(p, xbType_I8, eq ? 1 : 0);
	for (i64 i = 0; i < xb_simd_count(vt); i++) {
		u32 x = xb_simd_lane_reg(p, vt, a, i);
		u32 y = xb_simd_lane_reg(p, vt, b, i);
		xbCond c = xb_type_is_float(st) ? (eq ? xbCond_FEQ : xbCond_FNE) : (eq ? xbCond_EQ : xbCond_NE);
		acc = xb_binop(p, eq ? xbOp_And : xbOp_Or, xbType_I8, acc, xb_cmp(p, c, st, x, y));
	}
	return xb_value_reg(t_llvm_bool, acc);
}

// lane-wise negation (fneg for floats, unlike 0-x)
gb_internal xbValue xb_simd_neg(xbProc *p, xbValue x, Type *type) {
	Type *elem = xb_simd_elem(type);
	xbMem m = xb_simd_mem(p, xb_emit_conv(p, x, type));
	if (xb_is_f16(elem) && !is_type_different_to_arch_endianness(elem)) {
		return xb_simd_build(p, type, [&](i64 i) {
			xbMem r = xb_add_local(p, elem, false);
			u32 bits = xb_load(p, xbType_I16, xb_mem_offset(m, i*2));
			xb_store(p, xbType_I16, r, xb_binop(p, xbOp_Xor, xbType_I16, bits, xb_iconst(p, xbType_I16, 0x8000)));
			return xb_value_mem(elem, r);
		});
	}
	xbType st = xb_simd_st(p, elem);
	return xb_simd_build_reg(p, type, [&](i64 i) {
		return xb_unop(p, xb_type_is_float(st) ? xbOp_FNeg : xbOp_Neg, st, xb_simd_lane_reg(p, type, m, i));
	});
}

// lane-wise bitwise not, also for boolean lanes like LLVMBuildNot
gb_internal xbValue xb_simd_not(xbProc *p, xbValue x, Type *type) {
	Type *elem = xb_simd_elem(type);
	xbType st = xb_simd_st(p, elem);
	if (xb_type_is_float(st)) XB_UNSUPPORTED(p, "simd not of floats");
	xbMem m = xb_simd_mem(p, xb_emit_conv(p, x, type));
	return xb_simd_build_reg(p, type, [&](i64 i) {
		return xb_unop(p, xbOp_Not, st, xb_simd_lane_reg(p, type, m, i));
	});
}

////////////////////////////////////////////////////////////////
// Builtins
////////////////////////////////////////////////////////////////

// a vector picked from the lanes of `a` and then `b` (LLVMBuildShuffleVector)
gb_internal xbValue xb_simd_shuffle(xbProc *p, Type *rt, Type *vt, xbMem a, xbMem b, i64 const *indices) {
	i64 n = xb_simd_count(vt);
	return xb_simd_build(p, rt, [&](i64 i) {
		i64 k = indices[i];
		return k < n ? xb_simd_lane(p, vt, a, k) : xb_simd_lane(p, vt, b, k - n);
	});
}

// a reduction tree: each step combines lanes left[i] and right[i] of the remaining vector
gb_internal u32 xb_simd_reduce_tree(xbProc *p, Type *vt, xbMem m, bool pairs, xbOp op, xbType st) {
	i64 count = xb_simd_count(vt);
	auto lanes = array_make<u32>(xb_allocator(), count, count);
	for (i64 i = 0; i < count; i++) lanes[i] = xb_simd_lane_reg(p, vt, m, i);
	i64 remaining = count;
	while (remaining > 1) {
		remaining /= 2;
		for (i64 i = 0; i < remaining; i++) {
			u32 l = pairs ? lanes[2*i] : lanes[i];
			u32 r = pairs ? lanes[2*i+1] : lanes[i+remaining];
			lanes[i] = xb_binop(p, op, st, l, r);
		}
	}
	return lanes[0];
}

gb_internal u32 xb_simd_reduce_ordered(xbProc *p, Type *vt, xbMem m, i64 first, i64 n, bool is_mul, xbType st) {
	bool is_float = xb_type_is_float(st);
	u32 acc = 0;
	i64 start = first;
	if (is_float) {
		// llvm.vector.reduce.fadd/fmul start from 0.0/1.0
		acc = xb_fconst(p, st, is_mul ? 1.0 : 0.0);
	} else {
		acc = xb_simd_lane_reg(p, vt, m, first);
		start += 1;
	}
	xbOp op = is_float ? (is_mul ? xbOp_FMul : xbOp_FAdd) : (is_mul ? xbOp_Mul : xbOp_Add);
	for (i64 i = start; i < first+n; i++) {
		acc = xb_binop(p, op, st, acc, xb_simd_lane_reg(p, vt, m, i));
	}
	return acc;
}

// runs `body` only when the condition vreg is non-zero
template <typename F>
gb_internal void xb_simd_if(xbProc *p, u32 cond, F const &body) {
	xbBlock *then_ = xb_new_block(p);
	xbBlock *done = xb_new_block(p);
	xb_branch(p, cond, then_, done);
	xb_start_block(p, then_);
	body();
	xb_jump(p, done);
	xb_start_block(p, done);
}

// the low bit of a mask lane, like the trunc to <N x i1> LLVM does
gb_internal u32 xb_simd_mask_bit(xbProc *p, Type *mt, xbMem m, i64 i) {
	xbType st = xb_simd_st(p, xb_simd_elem(mt));
	u32 lane = xb_simd_lane_reg(p, mt, m, i);
	return xb_cmp(p, xbCond_NE, st, xb_binop(p, xbOp_And, st, lane, xb_iconst(p, st, 1)), xb_iconst(p, st, 0));
}

gb_internal xbValue xb_build_builtin_simd_proc(xbProc *p, Ast *expr, TypeAndValue const &tv, BuiltinProcId id) {
	ast_node(ce, CallExpr, expr);
	Type *rt = tv.type;

	switch (id) {
	case BuiltinProc_simd_indices: {
		Type *elem = xb_simd_elem(rt);
		return xb_simd_build(p, rt, [&](i64 i) { return xb_const_value(p, elem, exact_value_i64(i)); });
	}
	case BuiltinProc_simd_interleave: {
		isize n = ce->args.count;
		Type *vt = type_of_expr(ce->args[0]);
		auto mems = array_make<xbMem>(xb_allocator(), n, n);
		for (isize i = 0; i < n; i++) {
			mems[i] = xb_simd_mem(p, xb_emit_conv(p, xb_build_expr(p, ce->args[i]), vt));
		}
		if (n == 1) return xb_value_mem(rt, mems[0]);
		// replay the two-way shuffles on (operand, lane) pairs to find where each lane lands
		i64 width = xb_simd_count(vt);
		auto cur = array_make<Array<i64>>(xb_allocator(), n, n);
		for (isize i = 0; i < n; i++) {
			cur[i] = array_make<i64>(xb_allocator(), width, width);
			for (i64 k = 0; k < width; k++) cur[i][k] = i*width + k;
		}
		for (isize count = n; count > 1; count /= 2) {
			isize half = count/2;
			for (isize i = 0; i < half; i++) {
				isize w = cur[i].count;
				auto next = array_make<i64>(xb_allocator(), 2*w, 2*w);
				for (isize k = 0; k < w; k++) {
					next[2*k+0] = cur[i][k];
					next[2*k+1] = cur[i+half][k];
				}
				cur[i] = next;
			}
		}
		return xb_simd_build(p, rt, [&](i64 i) {
			i64 src = cur[0][i];
			return xb_simd_lane(p, vt, mems[src / width], src % width);
		});
	}
	case BuiltinProc_simd_deinterleave: {
		xbValue v = xb_build_expr(p, ce->args[0]);
		i64 n = exact_value_to_i64(ce->args[1]->tav.value);
		if (n == 1) {
			xbValue r = xb_value_copy_to_temp(p, v);
			r.type = rt;
			return r;
		}
		Type *vt = v.type;
		xbMem m = xb_simd_mem(p, v);
		i64 part = xb_simd_count(vt) / n;
		xbMem res = xb_add_local(p, rt, false);
		for (i64 j = 0; j < n; j++) {
			Type *ft = nullptr;
			i64 off = type_offset_of(rt, cast(i32)j, &ft);
			auto idx = array_make<i64>(xb_allocator(), part, part);
			for (i64 i = 0; i < part; i++) idx[i] = i*n + j;
			xbValue lanes = xb_simd_shuffle(p, ft, vt, m, m, idx.data);
			xb_store_value(p, xb_mem_offset(res, off), lanes);
		}
		return xb_value_mem(rt, res);
	}
	}

	// every runtime operand is built once, in order
	xbValue arg0 = {}; if (ce->args.count > 0) arg0 = xb_build_expr(p, ce->args[0]);
	xbValue arg1 = {}; if (ce->args.count > 1) arg1 = xb_build_expr(p, ce->args[1]);
	xbValue arg2 = {}; if (ce->args.count > 2) arg2 = xb_build_expr(p, ce->args[2]);

	Type *vt = arg0.type;
	Type *elem = xb_simd_elem(vt);
	bool is_float = is_type_float(elem);
	bool is_signed = xb_simd_is_signed(elem);
	i64 count = is_type_simd_vector(vt) ? xb_simd_count(vt) : 0;

	switch (id) {
	case BuiltinProc_simd_add:
	case BuiltinProc_simd_sub:
	case BuiltinProc_simd_mul:
	case BuiltinProc_simd_div:
	case BuiltinProc_simd_bit_and:
	case BuiltinProc_simd_bit_or:
	case BuiltinProc_simd_bit_xor:
	case BuiltinProc_simd_bit_and_not: {
		xbType st = xb_simd_st(p, elem);
		xbOp op = xbOp_Nop;
		switch (id) {
		case BuiltinProc_simd_add: op = is_float ? xbOp_FAdd : xbOp_Add; break;
		case BuiltinProc_simd_sub: op = is_float ? xbOp_FSub : xbOp_Sub; break;
		case BuiltinProc_simd_mul: op = is_float ? xbOp_FMul : xbOp_Mul; break;
		case BuiltinProc_simd_div:
			if (!is_float) XB_UNSUPPORTED(p, "simd integer division");
			op = xbOp_FDiv;
			break;
		case BuiltinProc_simd_bit_and:
		case BuiltinProc_simd_bit_and_not: op = xbOp_And; break;
		case BuiltinProc_simd_bit_or:  op = xbOp_Or;  break;
		case BuiltinProc_simd_bit_xor: op = xbOp_Xor; break;
		}
		xbMem a = xb_simd_mem(p, arg0);
		xbMem b = xb_simd_mem(p, arg1);
		return xb_simd_build_reg(p, rt, [&](i64 i) {
			u32 x = xb_simd_lane_reg(p, vt, a, i);
			u32 y = xb_simd_lane_reg(p, vt, b, i);
			if (id == BuiltinProc_simd_bit_and_not) y = xb_unop(p, xbOp_Not, st, y);
			return xb_binop(p, op, st, x, y);
		});
	}
	case BuiltinProc_simd_shl:
	case BuiltinProc_simd_shr:
	case BuiltinProc_simd_shl_masked:
	case BuiltinProc_simd_shr_masked: {
		xbType st = xb_simd_st(p, elem);
		Type *yt = arg1.type;
		xbType yst = xb_simd_st(p, xb_simd_elem(yt));
		bool masked = id == BuiltinProc_simd_shl_masked || id == BuiltinProc_simd_shr_masked;
		bool is_shl = id == BuiltinProc_simd_shl || id == BuiltinProc_simd_shl_masked;
		xbOp op = is_shl ? xbOp_Shl : (is_signed ? xbOp_AShr : xbOp_LShr);
		i64 bits = 8*type_size_of(elem) - 1;
		xbMem a = xb_simd_mem(p, arg0);
		xbMem b = xb_simd_mem(p, arg1);
		return xb_simd_build_reg(p, rt, [&](i64 i) {
			u32 x = xb_simd_lane_reg(p, vt, a, i);
			u32 y = xb_simd_lane_reg(p, yt, b, i);
			if (masked) {
				y = xb_binop(p, xbOp_And, yst, y, xb_iconst(p, yst, bits));
				return xb_binop(p, op, st, x, xb_int_resize(p, y, yst, st, false));
			}
			u32 in_range = xb_cmp(p, xbCond_ULE, yst, y, xb_iconst(p, yst, bits));
			u32 sh = xb_binop(p, op, st, x, xb_int_resize(p, y, yst, st, false));
			return xb_select(p, st, in_range, sh, xb_iconst(p, st, 0));
		});
	}
	case BuiltinProc_simd_saturating_add:
	case BuiltinProc_simd_saturating_sub: {
		xbType st = xb_simd_st(p, elem);
		xbMem a = xb_simd_mem(p, arg0);
		xbMem b = xb_simd_mem(p, arg1);
		return xb_simd_build_reg(p, rt, [&](i64 i) {
			return xb_simd_saturate(p, id == BuiltinProc_simd_saturating_add, is_signed, st, xb_simd_lane_reg(p, vt, a, i), xb_simd_lane_reg(p, vt, b, i));
		});
	}
	case BuiltinProc_simd_neg:
		return xb_simd_neg(p, arg0, rt);
	case BuiltinProc_simd_abs: {
		xbType st = xb_simd_st(p, elem);
		xbMem a = xb_simd_mem(p, arg0);
		if (!is_float && !is_signed) {
			return xb_value_copy_to_temp(p, arg0);
		}
		return xb_simd_build_reg(p, rt, [&](i64 i) {
			u32 x = xb_simd_lane_reg(p, vt, a, i);
			if (is_float) return xb_simd_fabs(p, st, x);
			// abs(min(T)) stays min(T)
			u32 neg = xb_cmp(p, xbCond_SLT, st, x, xb_iconst(p, st, 0));
			return xb_select(p, st, neg, xb_unop(p, xbOp_Neg, st, x), x);
		});
	}
	case BuiltinProc_simd_min:
	case BuiltinProc_simd_max: {
		xbType st = xb_simd_st(p, elem);
		bool is_min = id == BuiltinProc_simd_min;
		xbCond c = is_float ? (is_min ? xbCond_FLT : xbCond_FGT)
		                    : (is_min ? (is_signed ? xbCond_SLT : xbCond_ULT) : (is_signed ? xbCond_SGT : xbCond_UGT));
		xbMem a = xb_simd_mem(p, arg0);
		xbMem b = xb_simd_mem(p, arg1);
		return xb_simd_build_reg(p, rt, [&](i64 i) {
			u32 x = xb_simd_lane_reg(p, vt, a, i);
			u32 y = xb_simd_lane_reg(p, vt, b, i);
			return xb_select(p, st, xb_cmp(p, c, st, x, y), x, y);
		});
	}
	case BuiltinProc_simd_clamp: {
		xbType st = xb_simd_st(p, elem);
		xbCond lt = is_float ? xbCond_FLT : (is_signed ? xbCond_SLT : xbCond_ULT);
		xbCond gt = is_float ? xbCond_FGT : (is_signed ? xbCond_SGT : xbCond_UGT);
		xbMem a = xb_simd_mem(p, arg0);
		xbMem lo = xb_simd_mem(p, arg1);
		xbMem hi = xb_simd_mem(p, arg2);
		return xb_simd_build_reg(p, rt, [&](i64 i) {
			u32 x = xb_simd_lane_reg(p, vt, a, i);
			u32 l = xb_simd_lane_reg(p, vt, lo, i);
			u32 h = xb_simd_lane_reg(p, vt, hi, i);
			x = xb_select(p, st, xb_cmp(p, lt, st, x, l), l, x);
			return xb_select(p, st, xb_cmp(p, gt, st, x, h), h, x);
		});
	}
	case BuiltinProc_simd_lanes_eq:
	case BuiltinProc_simd_lanes_ne:
	case BuiltinProc_simd_lanes_lt:
	case BuiltinProc_simd_lanes_le:
	case BuiltinProc_simd_lanes_gt:
	case BuiltinProc_simd_lanes_ge: {
		xbType st = xb_simd_st(p, elem);
		xbType rst = xb_simd_st(p, xb_simd_elem(rt));
		xbCond c = xbCond_EQ;
		if (is_float) {
			switch (id) {
			case BuiltinProc_simd_lanes_eq: c = xbCond_FEQ; break;
			case BuiltinProc_simd_lanes_ne: c = xbCond_FNE; break;
			case BuiltinProc_simd_lanes_lt: c = xbCond_FLT; break;
			case BuiltinProc_simd_lanes_le: c = xbCond_FLE; break;
			case BuiltinProc_simd_lanes_gt: c = xbCond_FGT; break;
			case BuiltinProc_simd_lanes_ge: c = xbCond_FGE; break;
			}
		} else {
			switch (id) {
			case BuiltinProc_simd_lanes_eq: c = xbCond_EQ; break;
			case BuiltinProc_simd_lanes_ne: c = xbCond_NE; break;
			case BuiltinProc_simd_lanes_lt: c = is_signed ? xbCond_SLT : xbCond_ULT; break;
			case BuiltinProc_simd_lanes_le: c = is_signed ? xbCond_SLE : xbCond_ULE; break;
			case BuiltinProc_simd_lanes_gt: c = is_signed ? xbCond_SGT : xbCond_UGT; break;
			case BuiltinProc_simd_lanes_ge: c = is_signed ? xbCond_SGE : xbCond_UGE; break;
			}
		}
		xbMem a = xb_simd_mem(p, arg0);
		xbMem b = xb_simd_mem(p, arg1);
		return xb_simd_build_reg(p, rt, [&](i64 i) {
			u32 r = xb_cmp(p, c, st, xb_simd_lane_reg(p, vt, a, i), xb_simd_lane_reg(p, vt, b, i));
			return xb_simd_all_ones(p, rst, r);
		});
	}
	case BuiltinProc_simd_extract:
	case BuiltinProc_simd_replace: {
		xbMem a = xb_simd_mem(p, arg0);
		i64 stride = type_size_of(elem);
		xbMem lane = {};
		TypeAndValue itv = ce->args[1]->tav;
		if (itv.mode == Addressing_Constant) {
			lane = xb_mem_offset(a, (exact_value_to_i64(itv.value) & (count-1))*stride);
		} else {
			// an out of range index is poison in LLVM, keep the access inside the vector
			xbType ist = xb_simd_st(p, arg1.type);
			u32 idx = xb_int_resize(p, xb_value_to_reg(p, arg1), ist, xbType_I64, false);
			idx = xb_binop(p, xbOp_And, xbType_I64, idx, xb_iconst(p, xbType_I64, count-1));
			lane = xb_mem(xbMem_Reg, xb_ptr_add_scaled(p, xb_lea(p, a), idx, stride), 0);
		}
		if (id == BuiltinProc_simd_extract) {
			xbValue e = xb_load_value(p, elem, lane);
			if (e.kind == xbValue_Mem) e = xb_value_copy_to_temp(p, e);
			return e;
		}
		xbMem res = xb_add_local(p, rt, false);
		xb_memcopy(p, res, a, type_size_of(rt));
		xbMem dst = lane;
		if (itv.mode == Addressing_Constant) {
			dst = xb_mem_offset(res, (exact_value_to_i64(itv.value) & (count-1))*stride);
		} else {
			// the same lane of the copy
			u32 off = xb_binop(p, xbOp_Sub, xbType_I64, xb_lea(p, lane), xb_lea(p, a));
			dst = xb_mem(xbMem_Reg, xb_binop(p, xbOp_Add, xbType_I64, xb_lea(p, res), off), 0);
		}
		xb_store_value(p, dst, xb_emit_conv(p, arg2, elem));
		return xb_value_mem(rt, res);
	}
	case BuiltinProc_simd_reduce_add_bisect:
	case BuiltinProc_simd_reduce_mul_bisect:
	case BuiltinProc_simd_reduce_add_pairs:
	case BuiltinProc_simd_reduce_mul_pairs: {
		xbType st = xb_simd_st(p, elem);
		bool is_mul = id == BuiltinProc_simd_reduce_mul_bisect || id == BuiltinProc_simd_reduce_mul_pairs;
		bool pairs = id == BuiltinProc_simd_reduce_add_pairs || id == BuiltinProc_simd_reduce_mul_pairs;
		xbOp op = is_float ? (is_mul ? xbOp_FMul : xbOp_FAdd) : (is_mul ? xbOp_Mul : xbOp_Add);
		return xb_value_reg(rt, xb_simd_reduce_tree(p, vt, xb_simd_mem(p, arg0), pairs, op, st));
	}
	case BuiltinProc_simd_reduce_add_ordered:
	case BuiltinProc_simd_reduce_mul_ordered: {
		xbType st = xb_simd_st(p, elem);
		return xb_value_reg(rt, xb_simd_reduce_ordered(p, vt, xb_simd_mem(p, arg0), 0, count, id == BuiltinProc_simd_reduce_mul_ordered, st));
	}
	case BuiltinProc_simd_reduce_min:
	case BuiltinProc_simd_reduce_max:
	case BuiltinProc_simd_reduce_and:
	case BuiltinProc_simd_reduce_or:
	case BuiltinProc_simd_reduce_xor:
	case BuiltinProc_simd_reduce_any:
	case BuiltinProc_simd_reduce_all: {
		xbType st = xb_simd_st(p, elem);
		xbMem a = xb_simd_mem(p, arg0);
		bool is_min = id == BuiltinProc_simd_reduce_min;
		u32 acc = xb_simd_lane_reg(p, vt, a, 0);
		for (i64 i = 1; i < count; i++) {
			u32 x = xb_simd_lane_reg(p, vt, a, i);
			switch (id) {
			case BuiltinProc_simd_reduce_min:
			case BuiltinProc_simd_reduce_max:
				if (is_float) {
					acc = xb_simd_minmax_num(p, is_min, st, acc, x);
				} else {
					xbCond c = is_min ? (is_signed ? xbCond_SLT : xbCond_ULT) : (is_signed ? xbCond_SGT : xbCond_UGT);
					acc = xb_select(p, st, xb_cmp(p, c, st, x, acc), x, acc);
				}
				break;
			case BuiltinProc_simd_reduce_and:
			case BuiltinProc_simd_reduce_all:
				acc = xb_binop(p, xbOp_And, st, acc, x);
				break;
			case BuiltinProc_simd_reduce_or:
			case BuiltinProc_simd_reduce_any:
				acc = xb_binop(p, xbOp_Or, st, acc, x);
				break;
			case BuiltinProc_simd_reduce_xor:
				acc = xb_binop(p, xbOp_Xor, st, acc, x);
				break;
			}
		}
		if (id == BuiltinProc_simd_reduce_any || id == BuiltinProc_simd_reduce_all) {
			if (is_type_boolean(elem)) {
				return xb_value_reg(t_bool, xb_int_resize(p, acc, st, xbType_I8, false));
			}
			return xb_value_reg(t_bool, xb_cmp(p, xbCond_NE, st, acc, xb_iconst(p, st, 0)));
		}
		return xb_value_reg(rt, acc);
	}
	case BuiltinProc_simd_extract_lsbs:
	case BuiltinProc_simd_extract_msbs: {
		xbType st = xb_simd_st(p, elem);
		xbType rst = xb_scalar_type(rt);
		if (rst == xbType_None || count > 64) XB_UNSUPPORTED(p, "simd extract bits width");
		xbMem a = xb_simd_mem(p, arg0);
		i32 bits = 8*xb_type_size(st);
		u32 acc = xb_iconst(p, xbType_I64, 0);
		for (i64 i = 0; i < count; i++) {
			u32 x = xb_simd_lane_reg(p, vt, a, i);
			if (id == BuiltinProc_simd_extract_msbs) x = xb_binop(p, xbOp_LShr, st, x, xb_iconst(p, st, bits-1));
			x = xb_binop(p, xbOp_And, st, x, xb_iconst(p, st, 1));
			u32 w = xb_int_resize(p, x, st, xbType_I64, false);
			if (i != 0) w = xb_binop(p, xbOp_Shl, xbType_I64, w, xb_iconst(p, xbType_I64, i));
			acc = xb_binop(p, xbOp_Or, xbType_I64, acc, w);
		}
		return xb_value_reg(rt, xb_int_resize(p, acc, xbType_I64, rst, false));
	}
	case BuiltinProc_simd_shuffle: {
		i64 n = ce->args.count-2;
		auto idx = array_make<i64>(xb_allocator(), n, n);
		for (i64 i = 0; i < n; i++) idx[i] = exact_value_to_i64(ce->args[i+2]->tav.value);
		return xb_simd_shuffle(p, rt, vt, xb_simd_mem(p, arg0), xb_simd_mem(p, xb_emit_conv(p, arg1, vt)), idx.data);
	}
	case BuiltinProc_simd_odd_even: {
		auto idx = array_make<i64>(xb_allocator(), count, count);
		for (i64 i = 0; i < count/2; i++) {
			idx[i] = 2*i + 1;
			idx[i + count/2] = 2*i + count;
		}
		return xb_simd_shuffle(p, rt, vt, xb_simd_mem(p, arg0), xb_simd_mem(p, arg1), idx.data);
	}
	case BuiltinProc_simd_lanes_reverse: {
		auto idx = array_make<i64>(xb_allocator(), count, count);
		for (i64 i = 0; i < count; i++) idx[i] = count-1-i;
		xbMem a = xb_simd_mem(p, arg0);
		return xb_simd_shuffle(p, rt, vt, a, a, idx.data);
	}
	case BuiltinProc_simd_lanes_rotate_left:
	case BuiltinProc_simd_lanes_rotate_right: {
		ExactValue ev = exact_value_to_integer(ce->args[1]->tav.value);
		i64 k = exact_value_to_i64(ev);
		if (id == BuiltinProc_simd_lanes_rotate_right) k = -k;
		k = k % count;
		auto idx = array_make<i64>(xb_allocator(), count, count);
		for (i64 i = 0; i < count; i++) idx[i] = cast(i64)(cast(u64)(i+k) & cast(u64)(count-1));
		xbMem a = xb_simd_mem(p, arg0);
		return xb_simd_shuffle(p, rt, vt, a, a, idx.data);
	}
	case BuiltinProc_simd_pairwise_add:
	case BuiltinProc_simd_pairwise_sub: {
		xbType st = xb_simd_st(p, elem);
		xbOp op = is_float ? (id == BuiltinProc_simd_pairwise_add ? xbOp_FAdd : xbOp_FSub)
		                   : (id == BuiltinProc_simd_pairwise_add ? xbOp_Add : xbOp_Sub);
		xbMem a = xb_simd_mem(p, arg0);
		xbMem b = xb_simd_mem(p, arg1);
		auto pick = [&](i64 k) { return k < count ? xb_simd_lane_reg(p, vt, a, k) : xb_simd_lane_reg(p, vt, b, k - count); };
		return xb_simd_build_reg(p, rt, [&](i64 i) {
			u32 x = pick(2*i);
			u32 y = pick(2*i + 1);
			return xb_binop(p, op, st, x, y);
		});
	}
	case BuiltinProc_simd_sums_of_n: {
		xbType st = xb_simd_st(p, elem);
		i64 n = exact_value_to_i64(ce->args[1]->tav.value);
		xbMem a = xb_simd_mem(p, arg0);
		if (n == count) {
			return xb_value_reg(rt, xb_simd_reduce_ordered(p, vt, a, 0, count, false, st));
		}
		if (n == 2) {
			return xb_simd_build_reg(p, rt, [&](i64 i) {
				return xb_binop(p, is_float ? xbOp_FAdd : xbOp_Add, st, xb_simd_lane_reg(p, vt, a, 2*i), xb_simd_lane_reg(p, vt, a, 2*i+1));
			});
		}
		return xb_simd_build_reg(p, rt, [&](i64 i) {
			return xb_simd_reduce_ordered(p, vt, a, i*n, n, false, st);
		});
	}
	case BuiltinProc_simd_select: {
		Type *ct = arg0.type;
		xbType cst = xb_simd_st(p, xb_simd_elem(ct));
		Type *xt = arg1.type;
		xbMem c = xb_simd_mem(p, arg0);
		xbMem x = xb_simd_mem(p, arg1);
		xbMem y = xb_simd_mem(p, xb_emit_conv(p, arg2, xt));
		return xb_simd_build(p, rt, [&](i64 i) {
			u32 cond = xb_cmp(p, xbCond_NE, cst, xb_simd_lane_reg(p, ct, c, i), xb_iconst(p, cst, 0));
			xbValue a = xb_simd_lane(p, xt, x, i);
			xbValue b = xb_simd_lane(p, xt, y, i);
			xbType st = xb_simd_st(p, xb_simd_elem(xt));
			return xb_value_reg(xb_simd_elem(xt), xb_select(p, st, cond, xb_value_to_reg(p, a), xb_value_to_reg(p, b)));
		});
	}
	case BuiltinProc_simd_runtime_swizzle: {
		xbType st = xb_simd_st(p, elem);
		i64 stride = type_size_of(elem);
		xbMem src = xb_simd_mem(p, arg0);
		xbMem ind = xb_simd_mem(p, arg1);
		// x86 uses pshufb for 16 byte lanes: a set top bit gives zero
		bool pshufb = stride == 1 && count == 16 && check_target_feature_is_enabled(str_lit("ssse3"), nullptr);
		u32 base = xb_lea(p, src);
		return xb_simd_build_reg(p, rt, [&](i64 i) {
			u32 k = xb_simd_lane_reg(p, vt, ind, i);
			u32 masked = xb_binop(p, xbOp_And, st, k, xb_iconst(p, st, count-1));
			u32 off = xb_int_resize(p, masked, st, xbType_I64, false);
			u32 v = xb_load(p, st, xb_mem(xbMem_Reg, xb_ptr_add_scaled(p, base, off, stride), 0));
			if (pshufb) {
				u32 top = xb_cmp(p, xbCond_SLT, st, k, xb_iconst(p, st, 0));
				v = xb_select(p, st, top, xb_iconst(p, st, 0), v);
			}
			return v;
		});
	}
	case BuiltinProc_simd_ceil:
	case BuiltinProc_simd_floor:
	case BuiltinProc_simd_trunc:
	case BuiltinProc_simd_nearest: {
		xbType st = xb_simd_st(p, elem);
		xbMem a = xb_simd_mem(p, arg0);
		return xb_simd_build_reg(p, rt, [&](i64 i) {
			return xb_simd_round(p, id, st, xb_simd_lane_reg(p, vt, a, i));
		});
	}
	case BuiltinProc_simd_approx_recip:
	case BuiltinProc_simd_approx_recip_sqrt: {
		xbType st = xb_simd_st(p, elem);
		xbMem a = xb_simd_mem(p, arg0);
		if (st == xbType_F32 && !xb_is_arm64()) {
			// rcpps/rsqrtps on four lanes at a time, whose approximations only the hardware gives
			i64 count = xb_simd_count(vt);
			if (count >= 16 && check_target_feature_is_enabled(str_lit("avx512vl"), nullptr)) {
				XB_UNSUPPORTED(p, "simd approx recip with avx512");
			}
			i32 index = xb_vec_intrinsic_index(id == BuiltinProc_simd_approx_recip ? str_lit("llvm.x86.sse.rcp.ps") : str_lit("llvm.x86.sse.rsqrt.ps"));
			Type *v4 = alloc_type_simd_vector(4, t_f32);
			xbMem res = xb_add_local(p, rt, false);
			for (i64 chunk = 0; chunk < count; chunk += 4) {
				xbMem src = xb_mem_offset(a, cast(i32)(chunk*4));
				if (count < 4) {
					// the spare lanes repeat lane 0, as LLVM widens it
					src = xb_add_local(p, v4, false);
					for (i64 i = 0; i < 4; i++) {
						xb_store_value(p, xb_mem_offset(src, cast(i32)(i*4)), xb_simd_lane(p, vt, a, i < count ? i : 0));
					}
				}
				u32 ptr = xb_lea(p, src);
				xbValue r = xb_emit_vec128(p, index, ptr, ptr, 0, 0, v4);
				for (i64 i = 0; i < gb_min(count, cast(i64)4); i++) {
					xb_store_value(p, xb_mem_offset(res, cast(i32)((chunk+i)*4)), xb_simd_lane(p, v4, r.mem, i));
				}
			}
			return xb_value_mem(rt, res);
		}
		return xb_simd_build_reg(p, rt, [&](i64 i) {
			u32 x = xb_simd_lane_reg(p, vt, a, i);
			if (id == BuiltinProc_simd_approx_recip) {
				return xb_binop(p, xbOp_FDiv, st, xb_fconst(p, st, 1.0), x);
			}
			if (st != xbType_F64) {
				// LLVM guesses only for f64
				return xb_binop(p, xbOp_FDiv, st, xb_fconst(p, st, 1.0), xb_unop(p, xbOp_Sqrt, st, x));
			}
			// the magic constant guess and one Newton-Raphson step, as LLVM builds it
			u32 half = xb_binop(p, xbOp_FMul, st, x, xb_fconst(p, st, 0.5));
			u32 bits = xb_binop(p, xbOp_LShr, xbType_I64, xb_simd_float_bits(p, st, x), xb_iconst(p, xbType_I64, 1));
			u32 guess = xb_simd_bits_float(p, st, xb_binop(p, xbOp_Sub, xbType_I64, xb_iconst(p, xbType_I64, cast(i64)0x5FE6EB50C7B537A9ull), bits));
			u32 hg = xb_unop(p, xbOp_FNeg, st, xb_binop(p, xbOp_FMul, st, half, guess));
			u32 nma = xb_simd_fma(p, elem, hg, guess, xb_fconst(p, st, 1.5));
			return xb_binop(p, xbOp_FMul, st, guess, nma);
		});
	}
	case BuiltinProc_simd_to_bits:
	case BuiltinProc_simd_to_bits_signed:
		return xb_emit_transmute(p, arg0, rt);

	case BuiltinProc_simd_gather:
	case BuiltinProc_simd_scatter:
	case BuiltinProc_simd_masked_load:
	case BuiltinProc_simd_masked_store:
	case BuiltinProc_simd_masked_expand_load:
	case BuiltinProc_simd_masked_compress_store: {
		Type *valt = arg1.type;
		Type *ve = xb_simd_elem(valt);
		i64 n = xb_simd_count(valt);
		i64 stride = type_size_of(ve);
		Type *mt = arg2.type;
		xbMem vals = xb_simd_mem(p, arg1);
		xbMem mask = xb_simd_mem(p, arg2);
		bool is_load = id == BuiltinProc_simd_gather || id == BuiltinProc_simd_masked_load || id == BuiltinProc_simd_masked_expand_load;
		bool is_vector_ptr = id == BuiltinProc_simd_gather || id == BuiltinProc_simd_scatter;
		bool is_packed = id == BuiltinProc_simd_masked_expand_load || id == BuiltinProc_simd_masked_compress_store;
		xbMem ptrs = {};
		u32 base = 0;
		xbMem cursor = {};
		if (is_vector_ptr) {
			ptrs = xb_simd_mem(p, arg0);
		} else {
			base = xb_value_to_reg(p, arg0);
		}
		if (is_packed) {
			// the next element to read or write, it only moves for enabled lanes
			cursor = xb_mem(xbMem_Local, cast(u32)xb_add_local_raw(p, 8, 8));
			xb_store(p, xbType_I64, cursor, base);
		}
		xbMem res = {};
		if (is_load) {
			res = xb_add_local(p, valt, false);
			xb_memcopy(p, res, vals, type_size_of(valt));
		}
		for (i64 i = 0; i < n; i++) {
			u32 on = xb_simd_mask_bit(p, mt, mask, i);
			xb_simd_if(p, on, [&]() {
				xbMem at = {};
				if (is_vector_ptr) {
					at = xb_mem(xbMem_Reg, xb_simd_lane_reg(p, arg0.type, ptrs, i), 0);
				} else if (is_packed) {
					u32 c = xb_load(p, xbType_I64, cursor);
					at = xb_mem(xbMem_Reg, c, 0);
					xb_store(p, xbType_I64, cursor, xb_ptr_add_const(p, c, stride));
				} else {
					at = xb_mem(xbMem_Reg, base, cast(i32)(i*stride));
				}
				if (is_load) {
					xb_store_value(p, xb_mem_offset(res, i*stride), xb_load_value(p, ve, at));
				} else {
					xb_store_value(p, at, xb_load_value(p, ve, xb_mem_offset(vals, i*stride)));
				}
			});
		}
		if (is_load) return xb_value_mem(valt, res);
		return {};
	}
	}
	{
		gbString r = gb_string_make(permanent_allocator(), "builtin ");
		r = gb_string_append_length(r, builtin_procs[id].name.text, builtin_procs[id].name.len);
		XB_UNSUPPORTED(p, r);
	}
	return {};
}

// builtins that also take vectors: swizzle, sqrt and fused_mul_add
gb_internal xbValue xb_build_builtin_vector_proc(xbProc *p, Ast *expr, TypeAndValue const &tv, BuiltinProcId id) {
	ast_node(ce, CallExpr, expr);
	Type *rt = tv.type;
	switch (id) {
	case BuiltinProc_swizzle: {
		xbValue v = xb_build_expr(p, ce->args[0]);
		Type *vt = v.type;
		if (is_type_pointer(vt)) XB_UNSUPPORTED(p, "swizzle of pointer");
		i64 n = ce->args.count-1;
		if (n == 0) return v;
		auto idx = array_make<i64>(xb_allocator(), n, n);
		for (i64 i = 0; i < n; i++) idx[i] = exact_value_to_i64(ce->args[i+1]->tav.value);
		xbMem m = xb_simd_mem(p, v);
		if (is_type_simd_vector(rt)) {
			return xb_simd_shuffle(p, rt, vt, m, m, idx.data);
		}
		Type *elem = base_array_type(vt);
		i64 stride = type_size_of(elem);
		xbMem res = xb_add_local(p, rt, false);
		for (i64 i = 0; i < n; i++) {
			xb_store_value(p, xb_mem_offset(res, i*stride), xb_load_value(p, elem, xb_mem_offset(m, idx[i]*stride)));
		}
		return xb_value_mem(rt, res);
	}
	case BuiltinProc_sqrt: {
		xbMem m = xb_simd_mem(p, xb_emit_conv(p, xb_build_expr(p, ce->args[0]), rt));
		xbType st = xb_simd_st(p, xb_simd_elem(rt));
		return xb_simd_build_reg(p, rt, [&](i64 i) { return xb_unop(p, xbOp_Sqrt, st, xb_simd_lane_reg(p, rt, m, i)); });
	}
	case BuiltinProc_fused_mul_add: {
		xbValue x = xb_emit_conv(p, xb_build_expr(p, ce->args[0]), rt);
		xbValue y = xb_emit_conv(p, xb_build_expr(p, ce->args[1]), rt);
		xbValue z = xb_emit_conv(p, xb_build_expr(p, ce->args[2]), rt);
		if (!is_type_simd_vector(rt)) {
			if (is_type_different_to_arch_endianness(rt)) XB_UNSUPPORTED(p, "fma type");
			return xb_value_reg(rt, xb_simd_fma(p, rt, xb_value_to_reg(p, x), xb_value_to_reg(p, y), xb_value_to_reg(p, z)));
		}
		Type *elem = xb_simd_elem(rt);
		xb_simd_st(p, elem);
		xbMem a = xb_simd_mem(p, x);
		xbMem b = xb_simd_mem(p, y);
		xbMem c = xb_simd_mem(p, z);
		return xb_simd_build_reg(p, rt, [&](i64 i) {
			return xb_simd_fma(p, elem, xb_simd_lane_reg(p, rt, a, i), xb_simd_lane_reg(p, rt, b, i), xb_simd_lane_reg(p, rt, c, i));
		});
	}
	}
	XB_UNSUPPORTED(p, "vector builtin");
	return {};
}
