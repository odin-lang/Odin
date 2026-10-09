// The arm64 calling conventions of Apple and of Linux (AAPCS64), which must match LLVM's
// because procedures from both backends call each other.
//
// The LLVM backend classifies on its lowered types (lbAbiArm64 in llvm_abi.cpp), then
// LLVM's CC_AArch64_DarwinPCS or CC_AArch64_AAPCS assigns the pieces. Both steps are
// mirrored here, on the same `xbLType` the x64 classifier uses:
//   - a scalar takes the next x or v register, then a stack slot of its own size on Apple,
//     of at least 8 bytes on Linux
//   - a homogeneous float aggregate of up to four members takes consecutive v registers,
//     and a 9 to 16 byte aggregate two x registers, all or nothing: when they do not fit,
//     every register of the class counts as used and the members go onto the stack
//   - an i128 takes two consecutive x registers, starting at an even one on Linux; Apple
//     drops that rule but never starts it at x7; on the stack it is 16 byte aligned
//   - anything larger than 16 bytes is passed by pointer, and returned through x8
//   - Apple makes the caller extend an integer narrower than 32 bits, Linux only a bool
//   - a C vararg goes onto the stack in an 8 byte slot on Apple, and is assigned like a
//     fixed argument on Linux

gb_internal bool xb_is_arm64(void) {
	return build_context.metrics.arch == TargetArch_arm64;
}

// Apple's arm64 calling convention, rather than AAPCS64
gb_internal bool a64_is_apple(void) {
	return build_context.metrics.os == TargetOs_darwin;
}

gb_internal bool xb_can_compile_procs(void) {
	return true;
}

enum : u8 {
	A64_SRET_REG = 8, // x8 carries the address of a result returned in memory
};

gb_internal bool a64_lt_is_register(xbLType *t) {
	switch (t->kind) {
	case xbLT_Int:
	case xbLT_Half:
	case xbLT_Float:
	case xbLT_Double:
	case xbLT_Ptr:
		return true;
	case xbLT_Vector:
		return t->size == 8 || t->size == 16;
	}
	return false;
}

// The member type of a homogeneous aggregate, compared like LLVM compares its types.
struct a64HfaBase {
	xbLTypeKind kind;   // Half, Float, Double, or Vector
	i64         size;
	xbLTypeKind elem_kind;
	i32         elem_bits;
	i64         elem_count;
};

gb_internal bool a64_hfa_base_eq(a64HfaBase const &a, a64HfaBase const &b) {
	if (a.kind != b.kind || a.size != b.size) return false;
	if (a.kind == xbLT_Vector) {
		return a.elem_kind == b.elem_kind && a.elem_bits == b.elem_bits && a.elem_count == b.elem_count;
	}
	return true;
}

// is_homogenous_aggregate on the lowered type
gb_internal bool a64_lt_hfa(xbLType *t, a64HfaBase *base, i64 *count) {
	switch (t->kind) {
	case xbLT_Half:
	case xbLT_Float:
	case xbLT_Double:
		*base = {};
		base->kind = t->kind;
		base->size = t->size;
		*count = 1;
		return true;
	case xbLT_Vector:
		if (t->size != 8 && t->size != 16) return false;
		*base = {};
		base->kind = xbLT_Vector;
		base->size = t->size;
		base->elem_kind = t->elem->kind;
		base->elem_bits = t->elem->bits;
		base->elem_count = t->count;
		*count = 1;
		return true;
	case xbLT_Array: {
		if (t->count == 0) return false;
		a64HfaBase b = {};
		i64 n = 0;
		if (!a64_lt_hfa(t->elem, &b, &n)) return false;
		*base = b;
		*count = n * t->count;
		return true;
	}
	case xbLT_Struct: {
		if (t->fields.count == 0) return false;
		bool found = false;
		a64HfaBase b = {};
		i64 total = 0;
		for (xbLType *f : t->fields) {
			if (f->kind == xbLT_Struct && f->size == 0) continue; // an empty struct occupies nothing
			a64HfaBase fb = {};
			i64 fn = 0;
			if (!a64_lt_hfa(f, &fb, &fn)) return false;
			if (!found) {
				b = fb;
				total = fn;
				found = true;
			} else {
				if (!a64_hfa_base_eq(b, fb)) return false;
				total += fn;
			}
		}
		if (!found) return false;
		if (t->size != b.size * total) return false;
		*base = b;
		*count = total;
		return true;
	}
	}
	return false;
}

// is_homogenous_aggregate_source: a #raw_union of floats is an aggregate by its source type
gb_internal bool a64_source_hfa(Type *t, a64HfaBase *base, i64 *count) {
	if (t == nullptr) return false;
	Type *bt = base_type(t);
	if (bt == nullptr) return false;
	switch (bt->kind) {
	case Type_Basic: {
		xbLTypeKind k = xbLT_Void;
		switch (bt->Basic.kind) {
		case Basic_f16: k = xbLT_Half; break;
		case Basic_f32: k = xbLT_Float; break;
		case Basic_f64: k = xbLT_Double; break;
		default: return false;
		}
		*base = {};
		base->kind = k;
		base->size = k == xbLT_Half ? 2 : k == xbLT_Float ? 4 : 8;
		*count = 1;
		return true;
	}
	case Type_Array: {
		if (bt->Array.count == 0) return false;
		a64HfaBase b = {};
		i64 n = 0;
		if (!a64_source_hfa(bt->Array.elem, &b, &n)) return false;
		*base = b;
		*count = n * bt->Array.count;
		return true;
	}
	case Type_Struct: {
		if (bt->Struct.is_packed || bt->Struct.soa_kind != StructSoa_None) return false;
		bool found = false;
		a64HfaBase b = {};
		i64 total = 0;
		for (Entity *f : bt->Struct.fields) {
			Type *fbt = base_type(f->type);
			if (fbt != nullptr && fbt->kind == Type_Struct && type_size_of(f->type) == 0) continue;
			a64HfaBase fb = {};
			i64 fn = 0;
			if (!a64_source_hfa(f->type, &fb, &fn)) return false;
			if (!found) {
				b = fb;
				total = fn;
				found = true;
			} else if (!a64_hfa_base_eq(b, fb)) {
				return false;
			} else {
				total = bt->Struct.is_raw_union ? gb_max(total, fn) : total + fn;
			}
		}
		if (!found) return false;
		if (type_size_of(bt) != b.size * total) return false;
		*base = b;
		*count = total;
		return true;
	}
	}
	return false;
}

// How one value is passed, before registers are handed out.
struct a64Class {
	xbArgKind kind;
	Array<xbAbiPiece> pieces;
	bool block;        // the pieces need consecutive registers of one class
	i64  block_align;  // stack alignment of the first piece when the block goes onto the stack
	bool i128_pair;    // two consecutive x registers, x7 cannot hold the first half
	i32  lane_size, lane_count; // a returned short integer vector, see xbAbiFunc::ret_lane_size
};

gb_internal xbType a64_int_piece_type(i64 size) {
	return size <= 1 ? xbType_I8 : size <= 2 ? xbType_I16 : size <= 4 ? xbType_I32 : xbType_I64;
}

gb_internal void a64_add_piece(a64Class *c, xbType type, i32 size, i32 offset, xbLocKind loc, xbExtKind ext=xbExt_None) {
	xbAbiPiece p = {};
	p.type = type;
	p.size = size;
	p.src_offset = offset;
	p.loc = loc;
	p.ext = ext;
	array_add(&c->pieces, p);
}

// A value LLVM keeps as one register type (is_register).
gb_internal void a64_register_pieces(a64Class *c, xbLType *t, Type *source_type) {
	switch (t->kind) {
	case xbLT_Ptr:    a64_add_piece(c, xbType_I64, 8, 0, xbLoc_Gpr); break;
	case xbLT_Half:   a64_add_piece(c, xbType_F32, 2, 0, xbLoc_Xmm); break;
	case xbLT_Float:  a64_add_piece(c, xbType_F32, 4, 0, xbLoc_Xmm); break;
	case xbLT_Double: a64_add_piece(c, xbType_F64, 8, 0, xbLoc_Xmm); break;
	case xbLT_Vector:
		if (t->size == 8) a64_add_piece(c, xbType_F64, 8, 0, xbLoc_Xmm);
		else              a64_add_piece(c, xbType_V128, 16, 0, xbLoc_Xmm);
		break;
	case xbLT_Int:
		if (t->size > 8) {
			a64_add_piece(c, xbType_I64, 8, 0, xbLoc_Gpr);
			a64_add_piece(c, xbType_I64, 8, 8, xbLoc_Gpr);
			c->i128_pair = true;
		} else {
			// Darwin makes the caller extend anything narrower than 32 bits
			xbExtKind ext = xbExt_None;
			if (t->size < 4) {
				if (t->bits == 1) {
					ext = xbExt_Zero;
				} else if (a64_is_apple() && source_type != nullptr && (is_type_integer_like(source_type) || is_type_enum(source_type))) {
					ext = (is_type_unsigned(source_type) || is_type_boolean(source_type)) ? xbExt_Zero : xbExt_Sign;
				}
			}
			i32 size = cast(i32)t->size;
			a64_add_piece(c, a64_int_piece_type(size), size, 0, xbLoc_Gpr, ext);
		}
		break;
	default:
		GB_PANIC("a64: not a register type");
	}
}

gb_internal void a64_hfa_pieces(a64Class *c, a64HfaBase const &base, i64 count) {
	c->block = true;
	c->block_align = gb_min(base.size, cast(i64)16);
	for (i64 i = 0; i < count; i++) {
		xbType type = base.size == 16 ? xbType_V128 : base.size == 8 ? xbType_F64 : xbType_F32;
		a64_add_piece(c, type, cast(i32)base.size, cast(i32)(i*base.size), xbLoc_Xmm);
	}
}

// An aggregate of up to 16 bytes that is not a float aggregate: an iN, or [2 x i64].
gb_internal void a64_int_coerced_pieces(a64Class *c, i64 size) {
	if (size == 0) {
		c->kind = xbArg_Ignore;
		return;
	}
	if (size <= 8) {
		a64_add_piece(c, a64_int_piece_type(size), cast(i32)size, 0, xbLoc_Gpr);
		return;
	}
	c->block = true;
	c->block_align = 8;
	a64_add_piece(c, xbType_I64, 8, 0, xbLoc_Gpr);
	a64_add_piece(c, xbType_I64, cast(i32)(size - 8), 8, xbLoc_Gpr);
}

// compute_arg_types
gb_internal a64Class a64_classify_arg(xbLType *t, Type *source_type) {
	a64Class c = {};
	c.kind = xbArg_Direct;
	c.pieces = array_make<xbAbiPiece>(temporary_allocator(), 0, 4);
	a64HfaBase base = {};
	i64 count = 0;
	if (a64_lt_is_register(t)) {
		a64_register_pieces(&c, t, source_type);
	} else if (a64_lt_hfa(t, &base, &count) && count <= 4) {
		a64_hfa_pieces(&c, base, count);
	} else if (a64_source_hfa(source_type, &base, &count) && count <= 4) {
		a64_hfa_pieces(&c, base, count);
	} else if (t->size <= 16) {
		a64_int_coerced_pieces(&c, t->size);
	} else {
		c.kind = xbArg_Indirect;
	}
	return c;
}

// compute_return_type, plus abi_info's raw union case for a single result
gb_internal a64Class a64_classify_ret(xbLType *t, Type *return_source) {
	a64Class c = {};
	c.kind = xbArg_Direct;
	c.pieces = array_make<xbAbiPiece>(temporary_allocator(), 0, 4);
	a64HfaBase base = {};
	i64 count = 0;
	if (a64_lt_is_register(t)) {
		a64_register_pieces(&c, t, nullptr);
		for (xbAbiPiece &p : c.pieces) p.ext = xbExt_None;
	} else if (a64_lt_hfa(t, &base, &count) && count <= 4) {
		a64_hfa_pieces(&c, base, count);
	} else if (a64_source_hfa(return_source, &base, &count) && count <= 4) {
		a64_hfa_pieces(&c, base, count);
	} else if (t->size > 16) {
		c.kind = xbArg_Indirect;
	} else if (t->kind == xbLT_Vector && t->size < 8 && t->elem->kind == xbLT_Int && t->count >= 2) {
		// a short integer vector is returned as itself in d0, its lanes widened to fill it
		a64_add_piece(&c, xbType_F64, 8, 0, xbLoc_Xmm);
		c.lane_size = cast(i32)(t->size / t->count);
		c.lane_count = cast(i32)t->count;
	} else if (t->kind == xbLT_Vector) {
		// a short vector is returned as itself, in v0
		a64_add_piece(&c, t->size > 4 ? xbType_F64 : xbType_F32, cast(i32)t->size, 0, xbLoc_Xmm);
	} else {
		a64_int_coerced_pieces(&c, t->size);
	}
	return c;
}

struct a64Assigner {
	i32 ngrn;  // next x register
	i32 nsrn;  // next v register
	i32 nsaa;  // next stack offset
};

// The stack slot of a scalar of `size` bytes, which is also its alignment
gb_internal i32 a64_slot_size(i32 size) {
	if (!a64_is_apple()) return size <= 8 ? 8 : 16;
	return size <= 1 ? 1 : size <= 2 ? 2 : size <= 4 ? 4 : size <= 8 ? 8 : 16;
}

// `packed`: a member of a block after its first, which follows the previous member directly
gb_internal void a64_assign_stack(a64Assigner *s, xbAbiPiece *p, i32 align, bool packed=false) {
	p->loc = xbLoc_Stack;
	s->nsaa = cast(i32)xb_lt_align_formula(s->nsaa, align);
	p->stack_offset = s->nsaa;
	s->nsaa += packed ? p->size : a64_slot_size(p->size);
}

gb_internal void a64_assign_pieces(xbAbiFunc *f, a64Assigner *s, a64Class const &c) {
	isize first = f->pieces.count;
	for (xbAbiPiece const &p : c.pieces) array_add(&f->pieces, p);
	xbAbiPiece *ps = f->pieces.data + first;
	isize n = c.pieces.count;

	if (c.i128_pair) {
		if (!a64_is_apple()) s->ngrn += s->ngrn & 1;
		if (s->ngrn + 2 <= 8) {
			ps[0].reg = cast(u8)s->ngrn++;
			ps[1].reg = cast(u8)s->ngrn++;
		} else {
			s->ngrn = 8;
			a64_assign_stack(s, &ps[0], 16);
			a64_assign_stack(s, &ps[1], 8);
		}
		return;
	}
	if (c.block) {
		bool gpr = ps[0].loc == xbLoc_Gpr;
		i32 *next = gpr ? &s->ngrn : &s->nsrn;
		if (*next + n <= 8) {
			for (isize i = 0; i < n; i++) ps[i].reg = cast(u8)(*next)++;
		} else {
			*next = 8;
			// the members are packed after the first, which Linux aligns to at least 8
			i32 align = a64_is_apple() ? cast(i32)c.block_align : gb_max(cast(i32)c.block_align, 8);
			for (isize i = 0; i < n; i++) {
				a64_assign_stack(s, &ps[i], i == 0 ? align : 1, true);
			}
		}
		return;
	}
	for (isize i = 0; i < n; i++) {
		xbAbiPiece *p = &ps[i];
		i32 *next = p->loc == xbLoc_Gpr ? &s->ngrn : &s->nsrn;
		if (*next < 8) {
			p->reg = cast(u8)(*next)++;
		} else {
			a64_assign_stack(s, p, a64_slot_size(p->size));
		}
	}
}

gb_internal void a64_add_pointer_arg(xbAbiFunc *f, a64Assigner *s, xbAbiArg *arg) {
	a64Class c = {};
	c.pieces = array_make<xbAbiPiece>(temporary_allocator(), 0, 1);
	a64_add_piece(&c, xbType_I64, 8, 0, xbLoc_Gpr);
	arg->piece_index = cast(i32)f->pieces.count;
	arg->piece_count = 1;
	a64_assign_pieces(f, s, c);
}

// Where LLVM's struct for a tuple puts each element, or an empty slice when that is Odin's layout.
gb_internal Slice<i64> a64_llvm_tuple_offsets(Type *tuple) {
	GB_ASSERT(tuple->kind == Type_Tuple);
	xbLType *lt = xb_ltype(tuple);
	GB_ASSERT(lt->kind == xbLT_Struct && lt->fields.count == tuple->Tuple.variables.count);
	auto offsets = slice_make<i64>(permanent_allocator(), lt->fields.count);
	bool differs = false;
	i64 at = 0;
	for_array(i, lt->fields) {
		xbLType *f = lt->fields[i];
		if (!lt->packed) at = xb_lt_align_formula(at, f->align);
		offsets[i] = at;
		if (at != type_offset_of(tuple, cast(i32)i)) differs = true;
		at += f->size;
	}
	if (!differs) return {};
	return offsets;
}

gb_internal xbAbiFunc *a64_abi_compute(Type *proc_type, char const **reason) {
	Type *pt = base_type(proc_type);
	GB_ASSERT(pt->kind == Type_Proc);
	ProcCallingConvention cc = pt->Proc.calling_convention;
	switch (cc) {
	case ProcCC_Odin:
	case ProcCC_Contextless:
	case ProcCC_CDecl:
		break;
	default:
		*reason = "calling convention";
		return nullptr;
	}

	xbAbiFunc *f = permanent_alloc_item<xbAbiFunc>();
	f->cc = cc;
	f->c_vararg = pt->Proc.c_vararg;
	f->is_odin_cc = cc == ProcCC_Odin;
	f->pieces = array_make<xbAbiPiece>(permanent_allocator(), 0, 8);
	f->params = array_make<xbAbiArg>(permanent_allocator(), 0, pt->Proc.param_count);
	f->split_ret_ptrs = array_make<xbAbiArg>(permanent_allocator(), 0, 0);

	TEMPORARY_ALLOCATOR_GUARD();

	// results first: a result returned through x8 takes no argument register
	Type *ret_type = nullptr;
	a64Class ret = {};
	ret.kind = xbArg_Ignore;
	if (pt->Proc.result_count != 0) {
		Type *single_ret = reduce_tuple_to_single_type(pt->Proc.results);
		if (is_type_proc(single_ret)) {
			single_ret = t_rawptr;
		}
		bool return_is_tuple = is_type_tuple(single_ret) && is_calling_convention_odin(cc);
		ret_type = single_ret;
		xbLType *lt = xb_ltype(single_ret);
		if (is_type_boolean(single_ret) && is_calling_convention_none(cc) && type_size_of(single_ret) <= 1) {
			lt = xb_lt_int(1);
		}
		Type *return_source = nullptr;
		if (!return_is_tuple && !is_type_tuple(single_ret) && pt->Proc.results->Tuple.variables.count == 1) {
			return_source = pt->Proc.results->Tuple.variables[0]->type;
		}
		ret = a64_classify_ret(lt, return_source);
		if (return_is_tuple && ret.kind == xbArg_Indirect) {
			// too big for x0:x1: all but the last result go through pointers appended to the params
			auto const &vars = single_ret->Tuple.variables;
			f->split_returns = true;
			for (isize i = 0; i < vars.count-1; i++) {
				xbAbiArg a = {};
				a.kind = xbArg_Indirect;
				a.type = vars[i]->type;
				array_add(&f->split_ret_ptrs, a);
			}
			ret_type = vars[vars.count-1]->type;
			ret = a64_classify_ret(xb_ltype(ret_type), nullptr);
		}
	}
	f->ret_type = ret_type;
	if (ret.kind == xbArg_Direct && !f->split_returns && is_type_tuple(ret_type)) {
		f->ret_tuple_offsets = a64_llvm_tuple_offsets(ret_type);
	}

	a64Assigner s = {};
	if (ret.kind == xbArg_Indirect) {
		f->has_sret = true;
		f->sret.kind = xbArg_Indirect;
		f->sret.type = ret_type;
		f->sret.piece_index = cast(i32)f->pieces.count;
		f->sret.piece_count = 1;
		xbAbiPiece p = {};
		p.type = xbType_I64;
		p.size = 8;
		p.loc = xbLoc_Gpr;
		p.reg = A64_SRET_REG;
		array_add(&f->pieces, p);
		f->ret.kind = xbArg_Indirect;
		f->ret.type = ret_type;
	} else if (ret.kind == xbArg_Direct) {
		f->ret.kind = xbArg_Direct;
		f->ret.type = ret_type;
	} else {
		f->ret.kind = xbArg_Ignore;
	}

	if (pt->Proc.param_count != 0) {
		for (Entity *e : pt->Proc.params->Tuple.variables) {
			if (e->kind != Entity_Variable) continue;
			if (e->flags & EntityFlag_CVarArg) continue;
			Type *e_type = reduce_tuple_to_single_type(e->type);
			xbAbiArg arg = {};
			arg.type = e->type;
			a64Class c = {};
			if (e->flags & EntityFlag_ByPtr) {
				c.kind = xbArg_Indirect;
			} else {
				c = a64_classify_arg(xb_abi_param_ltype(e, e_type), e->type);
			}
			arg.kind = c.kind;
			if (type_size_of(e->type) == 0 && c.kind == xbArg_Direct && c.pieces.count == 0) {
				arg.kind = xbArg_Ignore;
			}
			switch (arg.kind) {
			case xbArg_Ignore:
				break;
			case xbArg_Indirect:
				a64_add_pointer_arg(f, &s, &arg);
				break;
			case xbArg_Direct:
				arg.piece_index = cast(i32)f->pieces.count;
				arg.piece_count = cast(i32)c.pieces.count;
				a64_assign_pieces(f, &s, c);
				break;
			default:
				*reason = "abi param";
				return nullptr;
			}
			array_add(&f->params, arg);
		}
	}
	for (xbAbiArg &a : f->split_ret_ptrs) {
		a64_add_pointer_arg(f, &s, &a);
	}
	if (f->is_odin_cc) {
		f->context.kind = xbArg_Indirect;
		f->context.type = t_context;
		a64_add_pointer_arg(f, &s, &f->context);
	}
	f->gpr_count = s.ngrn;
	f->xmm_count = s.nsrn;
	f->stack_size = cast(i32)xb_lt_align_formula(s.nsaa, 8);

	if (f->ret.kind == xbArg_Direct) {
		f->ret_lane_size = ret.lane_size;
		f->ret_lane_count = ret.lane_count;
		f->ret.piece_index = cast(i32)f->pieces.count;
		f->ret.piece_count = cast(i32)ret.pieces.count;
		i32 gpr = 0;
		i32 fpr = 0;
		for (xbAbiPiece p : ret.pieces) {
			p.reg = cast(u8)(p.loc == xbLoc_Gpr ? gpr++ : fpr++);
			array_add(&f->pieces, p);
		}
	}
	return f;
}

// The variadic arguments of a C call: on macOS each one takes an 8 byte stack slot after
// the fixed arguments, never a register. On Linux each takes the next x or v register like
// a fixed argument, then an 8 byte stack slot.
gb_internal i32 a64_varargs(xbProc *p, xbAbiFunc *abi, Array<xbCallArg> *call_args, Slice<xbValue> args, isize arg_index) {
	i32 stack = cast(i32)xb_lt_align_formula(abi->stack_size, 8);
	i32 ngrn = a64_is_apple() ? 8 : abi->gpr_count;
	i32 nsrn = a64_is_apple() ? 8 : abi->xmm_count;
	for (; arg_index < args.count; arg_index++) {
		xbValue v = xb_c_vararg_value(p, args[arg_index]);
		xbType st = xb_scalar_type(v.type);
		if (st == xbType_None) XB_UNSUPPORTED(p, "aggregate c vararg");
		xbCallArg a = {};
		a.kind = xbCallArg_Stack;
		a.type = st;
		a.size = 8;
		a.vreg = xb_value_to_reg(p, v);
		a.stack_offset = stack;
		if (xb_type_is_int(st)) {
			a.ext = xb_type_is_signed(v.type) ? xbExt_Sign : xbExt_Zero;
		}
		if (st == xbType_F32) {
			a.vreg = xb_convop(p, xbOp_FExt, xbType_F64, xbType_F32, a.vreg);
			a.type = xbType_F64;
		}
		i32 *next = xb_type_is_float(a.type) ? &nsrn : &ngrn;
		if (*next < 8) {
			a.kind = xb_type_is_float(a.type) ? xbCallArg_Xmm : xbCallArg_Gpr;
			a.reg = cast(u8)(*next)++;
			a.stack_offset = 0;
		} else {
			stack += 8;
		}
		array_add(call_args, a);
	}
	return stack;
}
