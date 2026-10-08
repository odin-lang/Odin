// Frontend: expressions

gb_internal xbValue xb_build_expr(xbProc *p, Ast *expr);
gb_internal xbAddr  xb_build_addr(xbProc *p, Ast *expr);
gb_internal xbValue xb_addr_load(xbProc *p, xbAddr const &addr);
gb_internal void    xb_addr_store(xbProc *p, xbAddr const &addr, xbValue v);
gb_internal xbValue xb_build_call_expr(xbProc *p, Ast *expr);
gb_internal xbValue xb_emit_call(xbProc *p, xbValue proc, Slice<xbValue> args, Ast *call_expr);
gb_internal xbValue xb_emit_comp(xbProc *p, TokenKind op, xbValue x, xbValue y);
gb_internal xbValue xb_emit_arith(xbProc *p, TokenKind op, xbValue x, xbValue y, Type *type);
gb_internal xbValue xb_emit_arith_array(xbProc *p, TokenKind op, xbValue x, xbValue y, Type *type);
gb_internal xbValue xb_build_compound_lit(xbProc *p, Ast *expr);
gb_internal xbValue xb_proc_value_from_entity(xbProc *p, Entity *e);
gb_internal void    xb_emit_bounds_check(xbProc *p, Token token, u32 index, u32 len);
gb_internal xbValue xb_emit_union_wrap(xbProc *p, Type *union_type, Type *variant, xbValue v);
gb_internal void    xb_set_debug_loc(xbProc *p, TokenPos pos);
gb_internal xbValue xb_build_builtin_proc(xbProc *p, Ast *expr, TypeAndValue const &tv, BuiltinProcId id);
gb_internal xbValue xb_source_code_location(xbProc *p, String proc_name, TokenPos pos);
gb_internal xbAddr  xb_emit_any_cast_addr(xbProc *p, xbValue value, Type *type, TokenPos pos);
gb_internal xbValue xb_emit_union_cast(xbProc *p, xbValue value, Type *type, TokenPos pos);

gb_internal Entity *xb_lookup_runtime_entity(xbModule *m, char const *name) {
	AstPackage *pkg = m->info->runtime_package;
	Entity *e = scope_lookup_current(pkg->scope, string_interner_insert(make_string_c(name)));
	GB_ASSERT_MSG(e != nullptr, "runtime procedure not found: %s", name);
	return e;
}

gb_internal xbValue xb_emit_runtime_call(xbProc *p, char const *name, Slice<xbValue> args) {
	Entity *e = xb_lookup_runtime_entity(p->m, name);
	xbValue proc = xb_proc_value_from_entity(p, e);
	// convert the arguments to the parameter types
	Type *pt = base_type(e->type);
	TEMPORARY_ALLOCATOR_GUARD();
	auto conv = slice_make<xbValue>(temporary_allocator(), args.count);
	isize j = 0;
	for (Entity *param : pt->Proc.params->Tuple.variables) {
		if (param->kind != Entity_Variable) continue;
		if (j >= args.count) break;
		conv[j] = xb_emit_conv(p, args[j], param->type);
		j++;
	}
	return xb_emit_call(p, proc, conv, nullptr);
}

gb_internal void xb_emit_runtime_call_init_context(xbProc *p, xbMem ctx) {
	xbValue args[1] = {xb_value_reg(t_context_ptr, xb_lea(p, ctx))};
	xb_emit_runtime_call(p, "__init_context", xb_args(args, 1));
}

////////////////////////////////////////////////////////////////
// Constants
////////////////////////////////////////////////////////////////

gb_internal xbValue xb_const_string(xbProc *p, String s, Type *t) {
	Type *bt = core_type(t);
	if (is_type_cstring(bt)) {
		i32 sym = xb_string_literal(p->m, s);
		return xb_value_reg(t, xb_lea(p, xb_mem(xbMem_Sym, sym)));
	}
	if (is_type_cstring16(bt)) {
		isize len = 0;
		i32 sym = xb_string16_literal(p->m, s, &len);
		return xb_value_reg(t, xb_lea(p, xb_mem(xbMem_Sym, sym)));
	}
	if (is_type_string16(bt)) {
		isize len = 0;
		i32 sym = xb_string16_literal(p->m, s, &len);
		xbMem m = xb_add_local(p, t_string16, false);
		xb_store(p, xbType_I64, m, xb_lea(p, xb_mem(xbMem_Sym, sym)));
		xb_store(p, xbType_I64, xb_mem_offset(m, 8), xb_iconst(p, xbType_I64, len));
		return xb_value_mem(t, m);
	}
	if (is_type_string(bt)) {
		xbMem m = xb_add_local(p, t_string, false);
		u32 ptr = 0;
		if (s.len == 0) {
			ptr = xb_iconst(p, xbType_I64, 0);
		} else {
			ptr = xb_lea(p, xb_mem(xbMem_Sym, xb_string_literal(p->m, s)));
		}
		xb_store(p, xbType_I64, m, ptr);
		xb_store(p, xbType_I64, xb_mem_offset(m, 8), xb_iconst(p, xbType_I64, s.len));
		return xb_value_mem(t, m);
	}
	if (is_type_array(bt) || is_type_u8_slice(bt)) {
		XB_UNSUPPORTED(p, "string constant as array");
	}
	XB_UNSUPPORTED(p, "string constant type");
	return {};
}

// The entity of an anonymous procedure literal, made the same way as the LLVM backend
gb_internal Entity *xb_proc_lit_entity(xbProc *p, Ast *expr) {
	ast_node(pl, ProcLit, expr);
	Entity *e = pl->decl->entity.load();
	if (e == nullptr) {
		Token token = {};
		token.pos = ast_token(expr).pos;
		token.kind = Token_Ident;
		token.string = lb_local_proc_name(&p->m->gen->default_module, pl->decl);
		Entity *new_e = alloc_entity_procedure(nullptr, token, type_of_expr(expr), pl->tags);
		new_e->file = expr->file();
		new_e->scope = new_e->file->scope;
		new_e->decl_info = pl->decl;
		new_e->parent_proc_decl = pl->decl->parent;
		new_e->Procedure.is_anonymous = true;
		new_e->flags |= EntityFlag_ProcBodyChecked;
		if (pl->decl->entity.compare_exchange_strong(e, new_e)) {
			e = new_e;
		}
	}
	return e;
}

gb_internal xbValue xb_proc_lit_value(xbProc *p, Ast *expr, Type *type) {
	ast_node(pl, ProcLit, expr);
	if (pl->body == nullptr) XB_UNSUPPORTED(p, "procedure literal without body");
	Entity *e = xb_proc_lit_entity(p, expr);
	DeclInfo *enclosing = lb_enclosing_proc_decl(pl->decl);
	if (enclosing != nullptr) {
		bool inside = false;
		for (DeclInfo *a = enclosing; a != nullptr; a = lb_enclosing_proc_decl(a)) {
			if (ptr_set_exists(&p->family->roots, a)) {
				inside = true;
				break;
			}
		}
		if (!inside) XB_UNSUPPORTED(p, "procedure literal of another procedure");
	}
	xb_family_add(p->family, e);
	i32 sym = xb_entity_symbol(p, e);
	xbValue v = xb_value_reg(type ? type : e->type, xb_lea(p, xb_mem(xbMem_Sym, sym)));
	return v;
}

gb_internal xbValue xb_make_slice_value(xbProc *p, Type *t, u32 data, u32 len);
gb_internal u32     xb_map_get_ptr(xbProc *p, u32 map_ptr, Type *map_type, xbValue key);
gb_internal void    xb_map_set(xbProc *p, u32 map_ptr, Type *map_type, xbValue key, xbValue value, TokenPos pos);
gb_internal xbValue xb_map_load(xbProc *p, xbAddr const &addr);
gb_internal i32     xb_map_info_sym(xbProc *caller, Type *map_type);

// whether a constant of the type holds slices, whose backing data must be fresh local memory
gb_internal bool xb_type_contains_slice(Type *t, isize depth=0) {
	if (depth > 16) return true;
	t = base_type(t);
	switch (t->kind) {
	case Type_Slice: return true;
	case Type_Array: return xb_type_contains_slice(t->Array.elem, depth+1);
	case Type_EnumeratedArray: return xb_type_contains_slice(t->EnumeratedArray.elem, depth+1);
	case Type_Struct:
		for (Entity *f : t->Struct.fields) {
			if (xb_type_contains_slice(f->type, depth+1)) return true;
		}
		return false;
	case Type_Union:
		for (Type *v : t->Union.variants) {
			if (xb_type_contains_slice(v, depth+1)) return true;
		}
		return false;
	}
	return false;
}

// a float constant, byte swapped for big endian float types
gb_internal i64 xb_section_reserve(xbModule *m, xbSection sec, i64 size, i64 align);

// zeroed storage that lives as long as the program
gb_internal xbMem xb_static_storage(xbProc *p, Type *type) {
	i64 size = gb_max(type_size_of(type), cast(i64)1);
	i64 at = xb_section_reserve(p->m, xbSection_Bss, size, gb_max(type_align_of(type), cast(i64)1));
	char name[64] = {};
	gb_snprintf(name, gb_size_of(name), ".Lxb.bss.%lld", cast(long long)at);
	i32 sym = xb_symbol(p->m, make_string_c(name));
	xbSymbol *s = &p->m->symbols[sym];
	s->section = xbSection_Bss;
	s->offset = at;
	s->size = size;
	s->flags = 0;
	return xb_mem(xbMem_Sym, cast(u32)sym);
}

gb_internal xbValue xb_endian_fconst(xbProc *p, Type *type, xbType st, f64 f) {
	if (!is_type_different_to_arch_endianness(type)) {
		return xb_value_reg(type, xb_fconst(p, st, f));
	}
	if (st == xbType_F32) {
		f32 f32v = cast(f32)f;
		u32 bits = 0;
		gb_memmove(&bits, &f32v, 4);
		u32 r = xb_iconst(p, xbType_I32, cast(i64)gb_endian_swap32(bits));
		return xb_value_reg(type, xb_convop(p, xbOp_Bitcast, xbType_F32, xbType_I32, r));
	}
	u64 bits = 0;
	gb_memmove(&bits, &f, 8);
	u32 r = xb_iconst(p, xbType_I64, cast(i64)gb_endian_swap64(bits));
	return xb_value_reg(type, xb_convop(p, xbOp_Bitcast, xbType_F64, xbType_I64, r));
}

gb_internal xbValue xb_const_value(xbProc *p, Type *type, ExactValue value) {
	type = default_type(type);
	Type *bt = core_type(type);
	xbType st = xb_scalar_type(type);
	if (st != xbType_None) {
		while (value.kind == ExactValue_Variant) {
			value = value.value_variant->tav.value;
		}
	}
	if (value.kind == ExactValue_Rational) {
		value = exact_value_to_float(value);
	}

	// aggregates other than strings are laid out as data and copied into a local
	if (st == xbType_None && value.kind != ExactValue_Invalid && value.kind != ExactValue_Compound && !xb_type_contains_slice(type) &&
	    value.kind != ExactValue_Procedure && value.kind != ExactValue_Typeid &&
	    !is_type_string(bt) && !is_type_any(bt) && !xb_is_int128(bt) && !xb_is_f16(bt) && !is_type_untyped(type)) {
		char const *reason = nullptr;
		i32 sym = xb_const_global(p->m, type, value, false, &reason);
		if (sym >= 0) {
			xbMem local = xb_add_local(p, type, false);
			xb_memcopy(p, local, xb_mem(xbMem_Sym, cast(u32)sym), type_size_of(type));
			return xb_value_mem(type, local);
		}
	}

	switch (value.kind) {
	case ExactValue_Invalid:
		return xb_zero_value(p, type);
	case ExactValue_Bool:
		if (st == xbType_None) XB_UNSUPPORTED(p, "bool constant type");
		return xb_value_reg(type, xb_iconst(p, st, value.value_bool ? 1 : 0));
	case ExactValue_Integer:
		if (xb_type_is_float(st)) {
			return xb_endian_fconst(p, type, st, big_int_to_f64(&value.value_integer));
		}
		if (xb_type_is_int(st)) {
			i64 v = 0;
			if (big_int_is_neg(&value.value_integer)) {
				v = big_int_to_i64(&value.value_integer);
			} else {
				v = cast(i64)big_int_to_u64(&value.value_integer);
			}
			if (is_type_different_to_arch_endianness(bt) && xb_type_size(st) > 1) {
				// the bits of a non-native endian value are byte swapped
				u64 u = cast(u64)v;
				switch (xb_type_size(st)) {
				case 2: u = gb_endian_swap16(cast(u16)u); break;
				case 4: u = gb_endian_swap32(cast(u32)u); break;
				case 8: u = gb_endian_swap64(u); break;
				}
				v = cast(i64)u;
			}
			return xb_value_reg(type, xb_iconst(p, st, v));
		}
		if (is_type_integer_128bit(bt) || (bt->kind == Type_BitSet && type_size_of(bt) == 16)) {
			// two 64 bit halves
			BigInt lo = {};
			BigInt hi = {};
			BigInt mask = {};
			big_int_from_u64(&mask, ~cast(u64)0);
			big_int_and(&lo, &value.value_integer, &mask);
			BigInt shift = {};
			big_int_from_u64(&shift, 64);
			big_int_shr(&hi, &value.value_integer, &shift);
			big_int_and(&hi, &hi, &mask);
			u64 lo_v = big_int_to_u64(&lo);
			u64 hi_v = big_int_to_u64(&hi);
			if (big_int_is_neg(&value.value_integer)) {
				// two's complement of the magnitude
				BigInt mag = {};
				big_int_neg(&mag, &value.value_integer);
				BigInt mlo = {};
				BigInt mhi = {};
				big_int_and(&mlo, &mag, &mask);
				big_int_shr(&mhi, &mag, &shift);
				u64 a = big_int_to_u64(&mlo);
				u64 b = big_int_to_u64(&mhi);
				lo_v = ~a + 1;
				hi_v = ~b + (lo_v == 0 ? 1 : 0);
			}
			if (is_type_different_to_arch_endianness(bt)) {
				u64 t = gb_endian_swap64(lo_v);
				lo_v = gb_endian_swap64(hi_v);
				hi_v = t;
			}
			xbMem m = xb_add_local(p, type, false);
			xb_store(p, xbType_I64, m, xb_iconst(p, xbType_I64, cast(i64)lo_v));
			xb_store(p, xbType_I64, xb_mem_offset(m, 8), xb_iconst(p, xbType_I64, cast(i64)hi_v));
			return xb_value_mem(type, m);
		}
		if (xb_is_f16(bt)) {
			return xb_const_value(p, type, exact_value_to_float(value));
		}
		{
			gbString r = gb_string_make(permanent_allocator(), "integer constant of ");
			r = gb_string_appendc(r, type_to_string(bt));
			XB_UNSUPPORTED(p, r);
		}
		break;
	case ExactValue_Float:
		if (xb_type_is_float(st)) {
			return xb_endian_fconst(p, type, st, value.value_float);
		}
		if (xb_is_f16(bt)) {
			u16 h = f32_to_f16(cast(f32)value.value_float);
			if (is_type_different_to_arch_endianness(bt)) h = gb_endian_swap16(h);
			xbMem m = xb_add_local(p, type, false);
			xb_store(p, xbType_I16, m, xb_iconst(p, xbType_I16, h));
			return xb_value_mem(type, m);
		}
		if (xb_type_is_int(st)) {
			return xb_value_reg(type, xb_iconst(p, st, cast(i64)value.value_float));
		}
		XB_UNSUPPORTED(p, "float constant type");
		break;
	case ExactValue_String:
		return xb_const_string(p, value.value_string, type);
	case ExactValue_String16: {
		isize len = 0;
		if (is_type_cstring16(bt)) {
			i32 sym = xb_string16_literal_raw(p->m, value.value_string16, &len);
			return xb_value_reg(type, xb_lea(p, xb_mem(xbMem_Sym, sym)));
		}
		if (!is_type_string16(bt)) XB_UNSUPPORTED(p, "string16 constant type");
		i32 sym = xb_string16_literal_raw(p->m, value.value_string16, &len);
		xbMem m = xb_add_local(p, type, false);
		xb_store(p, xbType_I64, m, xb_lea(p, xb_mem(xbMem_Sym, sym)));
		xb_store(p, xbType_I64, xb_mem_offset(m, 8), xb_iconst(p, xbType_I64, len));
		return xb_value_mem(type, m);
	}
	case ExactValue_Pointer:
		if (st == xbType_None) XB_UNSUPPORTED(p, "pointer constant type");
		return xb_value_reg(type, xb_iconst(p, st, cast(i64)value.value_pointer));
	case ExactValue_Typeid:
		return xb_typeid_value(p, value.value_typeid);
	case ExactValue_Procedure: {
		Ast *node = value.value_procedure;
		Entity *e = entity_of_node(node);
		if (e == nullptr && node->kind == Ast_ProcLit) {
			return xb_proc_lit_value(p, node, type);
		}
		if (e == nullptr) XB_UNSUPPORTED(p, "procedure constant");
		xbValue v = xb_proc_value_from_entity(p, e);
		v.type = type;
		return v;
	}
	case ExactValue_Compound: {
		ast_node(cl, CompoundLit, value.value_compound);
		if (cl->elems.count == 0) {
			return xb_zero_value(p, type);
		}
		// lay the constant out as data and copy it into a fresh local
		char const *reason = nullptr;
		if (p->is_startup && !is_type_bit_set(bt)) {
			// the value may end up in a global, so it is used in place, like LLVM's startup does
			if (is_type_slice(bt)) {
				isize count = gb_max(cast(isize)cl->max_count, cl->elems.count);
				Type *arr = alloc_type_array(bt->Slice.elem, count);
				i32 sym = xb_const_global(p->m, arr, value, true, &reason);
				if (sym >= 0) {
					return xb_make_slice_value(p, type, xb_lea(p, xb_mem(xbMem_Sym, cast(u32)sym)), xb_iconst(p, xbType_I64, count));
				}
			} else {
				i32 sym = xb_const_global(p->m, type, value, true, &reason);
				if (sym >= 0) {
					xbMem local = xb_add_local(p, type, false);
					xb_memcopy(p, local, xb_mem(xbMem_Sym, cast(u32)sym), type_size_of(type));
					return xb_value_mem(type, local);
				}
			}
			XB_UNSUPPORTED(p, reason ? reason : "startup constant");
		}
		if (is_type_slice(bt) && xb_type_contains_slice(bt->Slice.elem)) {
			// nested slices: built at run time, every backing array on the stack
		} else if (!is_type_slice(bt) && xb_type_contains_slice(bt)) {
			// same
		} else if (is_type_slice(bt)) {
			isize count = gb_max(cast(isize)cl->max_count, cl->elems.count);
			Type *arr = alloc_type_array(bt->Slice.elem, count);
			i32 sym = xb_const_global(p->m, arr, value, false, &reason);
			if (sym >= 0) {
				xbMem local = xb_add_local(p, arr, false);
				xb_memcopy(p, local, xb_mem(xbMem_Sym, cast(u32)sym), type_size_of(arr));
				return xb_make_slice_value(p, type, xb_lea(p, local), xb_iconst(p, xbType_I64, count));
			}
		} else if (!is_type_bit_set(bt)) {
			i32 sym = xb_const_global(p->m, type, value, false, &reason);
			if (sym >= 0) {
				xbMem local = xb_add_local(p, type, false);
				xb_memcopy(p, local, xb_mem(xbMem_Sym, cast(u32)sym), type_size_of(type));
				return xb_value_mem(type, local);
			}
		}
		if (is_type_struct(bt) || is_type_array(bt) || is_type_enumerated_array(bt) || is_type_slice(bt) || is_type_bit_set(bt)) {
			return xb_build_compound_lit(p, value.value_compound);
		}
		XB_UNSUPPORTED(p, reason ? reason : "compound constant");
		break;
	}
	case ExactValue_Complex:
	case ExactValue_Quaternion:
		XB_UNSUPPORTED(p, "complex constant");
		break;
	}
	{
		gbString r = gb_string_make(permanent_allocator(), "constant ");
		r = gb_string_append_fmt(r, "kind %d of %s", value.kind, type_to_string(bt));
		XB_UNSUPPORTED(p, r);
	}
	return {};
}

gb_internal xbValue xb_typeid_value(xbProc *p, Type *t) {
	if (build_context.no_rtti) {
		XB_UNSUPPORTED(p, "typeid with no rtti");
	}
	t = default_type(t);
	u64 data = type_hash_canonical_type(t);
	return xb_value_reg(t_typeid, xb_iconst(p, xbType_I64, cast(i64)data));
}

////////////////////////////////////////////////////////////////
// Entities
////////////////////////////////////////////////////////////////


gb_internal xbValue xb_proc_value_from_entity(xbProc *p, Entity *e) {
	GB_ASSERT(e->kind == Entity_Procedure);
	if (e->flags & EntityFlag_Disabled) {
		XB_UNSUPPORTED(p, "disabled procedure value");
	}
	if (e->Procedure.is_foreign && e->Procedure.is_objc_impl_or_import) {
		XB_UNSUPPORTED(p, "objc procedure");
	}
	DeclInfo *d = e->decl_info;
	if (!e->Procedure.is_foreign && d != nullptr && d->proc_lit != nullptr) {
		// nested procedures are generated together with their outermost procedure
		if (lb_enclosing_proc_decl(d) != nullptr) {
			bool inside = false;
			for (DeclInfo *a = lb_enclosing_proc_decl(d); a != nullptr; a = lb_enclosing_proc_decl(a)) {
				if (ptr_set_exists(&p->family->roots, a)) {
					inside = true;
					break;
				}
			}
			if (!inside) XB_UNSUPPORTED(p, "reference to a nested procedure of another procedure");
			xb_family_add(p->family, e);
		} else if (e->min_dep_count.load(std::memory_order_relaxed) == 0 && d->proc_lit->ProcLit.body != nullptr) {
			// nothing else generates it, so it comes along
			if ((e->flags & EntityFlag_ProcBodyChecked) == 0) XB_UNSUPPORTED(p, "unchecked procedure");
			if (is_type_polymorphic(e->type) && !base_type(e->type)->Proc.is_poly_specialized) XB_UNSUPPORTED(p, "unspecialized procedure");
			ptr_set_add(&p->family->on_demand, e);
			ptr_set_add(&p->family->roots, d);
			xb_family_add(p->family, e);
		}
	}
	i32 sym = xb_entity_symbol(p, e);
	xbMem m = xb_mem(xbMem_Sym, sym);
	return xb_value_reg(e->type, xb_lea(p, m));
}

gb_internal xbMem xb_global_mem(xbProc *p, Entity *e) {
	GB_ASSERT(e->kind == Entity_Variable);
	if (e->Variable.thread_local_model.len != 0 && build_context.build_mode != BuildMode_Executable) {
		XB_UNSUPPORTED(p, "thread local variable outside an executable");
	}
	if (e->min_dep_count.load(std::memory_order_relaxed) == 0) {
		XB_UNSUPPORTED(p, "unreferenced global");
	}
	i32 sym = xb_entity_symbol(p, e);
	return xb_mem(xbMem_Sym, sym);
}

gb_internal xbAddr xb_build_addr_from_entity(xbProc *p, Entity *e, Ast *expr) {
	GB_ASSERT(e != nullptr);
	if (e->kind == Entity_Constant) {
		Type *t = default_type(type_of_expr(expr));
		xbValue v = xb_const_value(p, t, e->Constant.value);
		return xb_addr(t, xb_value_to_mem(p, v));
	}
	xbVar *found = map_get(&p->vars, e);
	if (found && found->is_soa) {
		xbAddr a = {};
		a.kind = xbAddr_SoaVariable;
		a.type = e->type;
		a.mem = xb_mem(xbMem_Reg, xb_load(p, xbType_I64, found->mem), 0);
		a.soa_index = xb_load(p, xbType_I64, xb_mem(xbMem_Local, cast(u32)found->soa_index_local));
		a.soa_container = found->soa_container;
		return a;
	}
	if (found) {
		if (found->indirect) {
			return xb_addr(e->type, xb_mem(xbMem_Reg, xb_load(p, xbType_I64, found->mem), 0));
		}
		return xb_addr(e->type, found->mem);
	}
	if (e->kind == Entity_Variable && (e->flags & EntityFlag_Using)) {
		Entity *parent = e->using_parent;
		if (parent == nullptr) XB_UNSUPPORTED(p, "using variable");
		Selection sel = lookup_field(parent->type, string_interner_insert(e->token.string), false);
		if (sel.entity == nullptr) XB_UNSUPPORTED(p, "using variable lookup");
		xbAddr pa = xb_build_addr_from_entity(p, parent, nullptr);
		if (pa.kind != xbAddr_Default) XB_UNSUPPORTED(p, "using variable addr");
		// walk the selection
		Type *type = pa.type;
		xbMem mem = pa.mem;
		for (i32 index : sel.index) {
			if (is_type_pointer(type)) {
				type = type_deref(type);
				mem = xb_mem(xbMem_Reg, xb_load(p, xbType_I64, mem), 0);
			}
			Type *ft = nullptr;
			Type *bt = core_type(type);
			if (bt->kind != Type_Struct || bt->Struct.soa_kind != StructSoa_None) XB_UNSUPPORTED(p, "using through non-struct");
			i64 off = type_offset_of(bt, index, &ft);
			mem = xb_mem_offset(mem, off);
			type = ft;
		}
		return xb_addr(type, mem);
	}
	if (e->kind == Entity_Variable) {
		if (e->flags & EntityFlag_SoaPtrField) XB_UNSUPPORTED(p, "soa pointer field");
		if (e->scope && (e->scope->flags & (ScopeFlag_File|ScopeFlag_Pkg)) == 0 && (e->flags & EntityFlag_Static) == 0) {
			XB_UNSUPPORTED(p, "unknown local variable");
		}
		if (e->flags & EntityFlag_Static) {
			XB_UNSUPPORTED(p, "static local variable");
		}
		return xb_addr(e->type, xb_global_mem(p, e));
	}
	if (e->kind == Entity_Procedure) {
		xbValue v = xb_proc_value_from_entity(p, e);
		return xb_addr(e->type, xb_value_to_mem(p, v));
	}
	XB_UNSUPPORTED(p, "entity address");
	return {};
}


////////////////////////////////////////////////////////////////
// #soa
////////////////////////////////////////////////////////////////

gb_internal Type *xb_soa_container_type(xbAddr const &a) {
	Type *t = base_type(a.soa_container);
	GB_ASSERT(t->kind == Type_Struct && t->Struct.soa_kind != StructSoa_None);
	return t;
}

gb_internal isize xb_soa_column_count(Type *t) {
	isize n = t->Struct.fields.count;
	if (t->Struct.soa_kind == StructSoa_Slice) n -= 1;
	else if (t->Struct.soa_kind == StructSoa_Dynamic) n -= 3;
	return n;
}

gb_internal u32 xb_soa_len(xbProc *p, Type *t, xbMem container) {
	t = base_type(t);
	if (t->Struct.soa_kind == StructSoa_Fixed) {
		return xb_iconst(p, xbType_I64, t->Struct.soa_count);
	}
	isize n = xb_soa_column_count(t);
	Type *ft = nullptr;
	i64 off = type_offset_of(t, n, &ft);
	return xb_load(p, xbType_I64, xb_mem_offset(container, off));
}

gb_internal u32 xb_soa_cap(xbProc *p, Type *t, xbMem container) {
	t = base_type(t);
	if (t->Struct.soa_kind == StructSoa_Fixed) {
		return xb_iconst(p, xbType_I64, t->Struct.soa_count);
	}
	if (t->Struct.soa_kind == StructSoa_Slice) {
		return xb_soa_len(p, t, container);
	}
	isize n = xb_soa_column_count(t);
	Type *ft = nullptr;
	i64 off = type_offset_of(t, n+1, &ft);
	return xb_load(p, xbType_I64, xb_mem_offset(container, off));
}

// the address of column `field` of element `index`
gb_internal xbMem xb_soa_elem_field(xbProc *p, Type *t, xbMem container, u32 index, isize field, Type **field_type) {
	t = base_type(t);
	Type *ft = nullptr;
	i64 off = type_offset_of(t, field, &ft);
	Type *col = base_type(ft);
	if (t->Struct.soa_kind == StructSoa_Fixed) {
		GB_ASSERT(col->kind == Type_Array);
		*field_type = col->Array.elem;
		u32 base = xb_lea(p, xb_mem_offset(container, off));
		return xb_mem(xbMem_Reg, xb_ptr_add_scaled(p, base, index, type_size_of(col->Array.elem)), 0);
	}
	GB_ASSERT(col->kind == Type_MultiPointer);
	*field_type = col->MultiPointer.elem;
	u32 base = xb_load(p, xbType_I64, xb_mem_offset(container, off));
	return xb_mem(xbMem_Reg, xb_ptr_add_scaled(p, base, index, type_size_of(col->MultiPointer.elem)), 0);
}

gb_internal void xb_soa_bounds_check(xbProc *p, xbAddr const &a) {
	if (a.soa_index_expr == nullptr) return;
	Type *t = xb_soa_container_type(a);
	if (t->Struct.soa_kind == StructSoa_Fixed && a.soa_index_expr->tav.mode == Addressing_Constant) return;
	u32 len = xb_soa_len(p, t, a.mem);
	xb_emit_bounds_check(p, ast_token(a.soa_index_expr), a.soa_index, len);
}

gb_internal xbValue xb_soa_load(xbProc *p, xbAddr const &a) {
	Type *t = xb_soa_container_type(a);
	Type *elem = t->Struct.soa_elem;
	if (base_type(elem)->kind != Type_Struct) XB_UNSUPPORTED(p, "#soa of non-struct");
	xb_soa_bounds_check(p, a);
	xbMem res = xb_add_local(p, elem, true);
	isize n = xb_soa_column_count(t);
	Type *bt = base_type(elem);
	for (isize i = 0; i < n; i++) {
		Type *ft = nullptr;
		xbMem src = xb_soa_elem_field(p, t, a.mem, a.soa_index, i, &ft);
		Type *dt = nullptr;
		i64 doff = type_offset_of(bt, i, &dt);
		xb_store_value(p, xb_mem_offset(res, doff), xb_load_value(p, ft, src));
	}
	return xb_value_mem(elem, res);
}

gb_internal void xb_soa_store(xbProc *p, xbAddr const &a, xbValue v) {
	Type *t = xb_soa_container_type(a);
	Type *elem = t->Struct.soa_elem;
	if (base_type(elem)->kind != Type_Struct) XB_UNSUPPORTED(p, "#soa of non-struct");
	v = xb_emit_conv(p, v, elem);
	xbMem vm = xb_value_to_mem(p, v);
	xb_soa_bounds_check(p, a);
	isize n = xb_soa_column_count(t);
	Type *bt = base_type(elem);
	for (isize i = 0; i < n; i++) {
		Type *ft = nullptr;
		xbMem dst = xb_soa_elem_field(p, t, a.mem, a.soa_index, i, &ft);
		Type *st = nullptr;
		i64 soff = type_offset_of(bt, i, &st);
		xb_store_value(p, dst, xb_load_value(p, st, xb_mem_offset(vm, soff)));
	}
}

////////////////////////////////////////////////////////////////
// Addresses
////////////////////////////////////////////////////////////////

// gathers the selected elements into a new local
gb_internal xbMem xb_swizzle_gather(xbProc *p, xbAddr const &addr) {
	i64 stride = type_size_of(addr.swizzle_elem);
	xbMem res = xb_add_local(p, addr.type, false);
	for (u8 i = 0; i < addr.swizzle_count; i++) {
		u8 index = (addr.swizzle_indices >> (i*2)) & 3;
		xb_store_value(p, xb_mem_offset(res, i*stride), xb_load_value(p, addr.swizzle_elem, xb_mem_offset(addr.mem, index*stride)));
	}
	return res;
}

gb_internal xbValue xb_addr_load(xbProc *p, xbAddr const &addr) {
	switch (addr.kind) {
	case xbAddr_Swizzle:
		return xb_value_mem(addr.type, xb_swizzle_gather(p, addr));
	case xbAddr_Default:
		return xb_load_value(p, addr.type, addr.mem);
	case xbAddr_Context: {
		xbMem ctx = xb_context_mem(p);
		Type *type = t_context;
		xbMem mem = ctx;
		for (i32 index : addr.ctx_sel.index) {
			if (is_type_pointer(type)) {
				type = type_deref(type);
				mem = xb_mem(xbMem_Reg, xb_load(p, xbType_I64, mem), 0);
			}
			Type *ft = nullptr;
			i64 off = type_offset_of(core_type(type), index, &ft);
			mem = xb_mem_offset(mem, off);
			type = ft;
		}
		return xb_load_value(p, type, mem);
	}
	case xbAddr_BitField: {
		XB_UNSUPPORTED(p, "bit field load");
	}
	case xbAddr_SoaVariable:
		return xb_soa_load(p, addr);
	case xbAddr_Map:
		return xb_map_load(p, addr);
	}
	XB_UNSUPPORTED(p, "addr load");
	return {};
}

gb_internal void xb_addr_store(xbProc *p, xbAddr const &addr, xbValue v) {
	switch (addr.kind) {
	case xbAddr_Discard:
		return;
	case xbAddr_Swizzle: {
		// copy first: the value may overlap the elements written
		xbValue c = xb_emit_conv(p, v, addr.type);
		xbMem src = xb_add_local(p, addr.type, false);
		xb_store_value(p, src, c);
		i64 stride = type_size_of(addr.swizzle_elem);
		for (u8 i = 0; i < addr.swizzle_count; i++) {
			u8 index = (addr.swizzle_indices >> (i*2)) & 3;
			xb_store_value(p, xb_mem_offset(addr.mem, index*stride), xb_load_value(p, addr.swizzle_elem, xb_mem_offset(src, i*stride)));
		}
		return;
	}
	case xbAddr_SoaVariable:
		xb_soa_store(p, addr, v);
		return;
	case xbAddr_Map: {
		u32 map_ptr = xb_load(p, xbType_I64, addr.mem);
		TokenPos pos = p->curr_stmt ? ast_token(p->curr_stmt).pos : TokenPos{};
		xb_map_set(p, map_ptr, addr.map_type, addr.map_key, v, pos);
		return;
	}
	case xbAddr_Default:
		xb_store_value(p, addr.mem, xb_emit_conv(p, v, addr.type));
		return;
	case xbAddr_Context: {
		// assigning to (part of) the context makes a new context for the rest of the scope
		xbMem old = xb_context_mem(p);
		xbContextEntry *top = &p->context_stack[p->context_stack.count-1];
		top->uses -= 1; // the read above does not count
		bool create_new = true;
		if (!top->indirect && top->uses <= 0 && top->scope_index >= p->scope_index) {
			create_new = false;
		}
		xbMem next = old;
		if (create_new) {
			next = xb_add_local(p, t_context, false);
			xb_memcopy(p, next, old, type_size_of(t_context));
			xb_push_context(p, next, false);
		}
		Type *type = t_context;
		xbMem mem = next;
		for (i32 index : addr.ctx_sel.index) {
			if (is_type_pointer(type)) {
				type = type_deref(type);
				mem = xb_mem(xbMem_Reg, xb_load(p, xbType_I64, mem), 0);
			}
			Type *ft = nullptr;
			i64 off = type_offset_of(core_type(type), index, &ft);
			mem = xb_mem_offset(mem, off);
			type = ft;
		}
		xb_store_value(p, mem, xb_emit_conv(p, v, type));
		return;
	}
	}
	XB_UNSUPPORTED(p, "addr store");
}

gb_internal xbMem xb_addr_mem(xbProc *p, xbAddr const &addr) {
	if (addr.kind == xbAddr_Default) {
		return addr.mem;
	}
	if (addr.kind == xbAddr_Context && addr.ctx_sel.index.count == 0) {
		return xb_context_mem(p);
	}
	if (addr.kind == xbAddr_Swizzle) {
		return xb_swizzle_gather(p, addr);
	}
	if (addr.kind == xbAddr_Context) {
		xbMem ctx = xb_context_mem(p);
		Type *type = t_context;
		xbMem mem = ctx;
		for (i32 index : addr.ctx_sel.index) {
			if (is_type_pointer(type)) {
				type = type_deref(type);
				mem = xb_mem(xbMem_Reg, xb_load(p, xbType_I64, mem), 0);
			}
			Type *ft = nullptr;
			i64 off = type_offset_of(core_type(type), index, &ft);
			mem = xb_mem_offset(mem, off);
			type = ft;
		}
		return mem;
	}
	if (addr.kind == xbAddr_Map) {
		// a pointer into the map's storage, nil if the key is missing
		u32 map_ptr = xb_load(p, xbType_I64, addr.mem);
		return xb_mem(xbMem_Reg, xb_map_get_ptr(p, map_ptr, addr.map_type, addr.map_key), 0);
	}
	XB_UNSUPPORTED(p, "address of special addr");
	return {};
}

// Walks a field selection from memory `mem` holding a value of type `type`.
gb_internal xbAddr xb_emit_deep_field(xbProc *p, Type *type, xbMem mem, Selection const &sel) {
	for (i32 index : sel.index) {
		if (is_type_pointer(type)) {
			type = type_deref(type);
			mem = xb_mem(xbMem_Reg, xb_load(p, xbType_I64, mem), 0);
		}
		Type *bt = core_type(type);
		Type *ft = nullptr;
		i64 off = 0;
		switch (bt->kind) {
		case Type_Struct:
			if (bt->Struct.is_packed && mem.align == 0) {
				mem.align = 1;
			}
			if (bt->Struct.is_raw_union) {
				ft = bt->Struct.fields[index]->type;
				off = 0;
			} else {
				off = type_offset_of(bt, index, &ft);
			}
			break;
		case Type_Tuple:
			off = type_offset_of(bt, index, &ft);
			break;
		case Type_Basic:
			if (bt->Basic.kind == Basic_any || bt->Basic.kind == Basic_string || bt->Basic.kind == Basic_string16) {
				off = type_offset_of(bt, index, &ft);
			} else if (is_type_complex(bt)) {
				ft = base_complex_elem_type(bt);
				off = index * type_size_of(ft);
			} else {
				XB_UNSUPPORTED(p, "basic field");
			}
			break;
		case Type_Slice:
		case Type_DynamicArray:
			off = type_offset_of(bt, index, &ft);
			break;
		case Type_Array:
			ft = bt->Array.elem;
			off = index * type_size_of(ft);
			break;
		case Type_Map:
			init_map_internal_debug_types(bt);
			off = type_offset_of(base_type(t_raw_map), index, &ft);
			break;
		default:
			XB_UNSUPPORTED(p, "field of type");
		}
		GB_ASSERT(ft != nullptr);
		mem = xb_mem_offset(mem, off);
		type = ft;
	}
	return xb_addr(type, mem);
}

gb_internal xbMem xb_build_addr_mem(xbProc *p, Ast *expr) {
	xbAddr a = xb_build_addr(p, expr);
	return xb_addr_mem(p, a);
}

gb_internal bool xb_bounds_check_disabled(xbProc *p) {
	if (build_context.no_bounds_check) return true;
	if (p->state_flags & StateFlag_no_bounds_check) return true;
	return false;
}

gb_internal void xb_file_line_col(xbProc *p, TokenPos pos, xbValue *out) {
	String file = get_file_path_string(pos.file_id);
	i32 line = pos.line;
	i32 col  = pos.column;
	switch (build_context.source_code_location_info) {
	case SourceCodeLocationInfo_Normal:
		break;
	case SourceCodeLocationInfo_Obfuscated:
		file = obfuscate_string(file, "F");
		line = obfuscate_i32(line);
		col  = obfuscate_i32(col);
		break;
	case SourceCodeLocationInfo_Filename:
		file = last_path_element(file);
		break;
	case SourceCodeLocationInfo_None:
		file = str_lit("");
		line = 0;
		col  = 0;
		break;
	}
	out[0] = xb_const_string(p, file, t_string);
	out[1] = xb_value_reg(t_i32, xb_iconst(p, xbType_I32, line));
	out[2] = xb_value_reg(t_i32, xb_iconst(p, xbType_I32, col));
}

gb_internal void xb_emit_bounds_check(xbProc *p, Token token, u32 index, u32 len) {
	if (xb_bounds_check_disabled(p)) return;
	xbValue args[5] = {};
	xb_file_line_col(p, token.pos, args);
	args[3] = xb_value_reg(t_int, index);
	args[4] = xb_value_reg(t_int, len);
	char const *handler = "bounds_check_error_contextless";
	if (p->context_stack.count > 0) {
		handler = "bounds_check_error_with_context";
	}
	xb_emit_runtime_call(p, handler, xb_args(args, 5));
}

gb_internal u32 xb_build_index_int(xbProc *p, Ast *index_expr) {
	xbValue idx = xb_build_expr(p, index_expr);
	return xb_value_to_reg(p, xb_emit_conv(p, idx, t_int));
}

// the (data, len) of a string, slice or dynamic array value
gb_internal u32 xb_value_data(xbProc *p, xbValue v) {
	GB_ASSERT(v.kind == xbValue_Mem);
	return xb_load(p, xbType_I64, v.mem);
}
gb_internal u32 xb_value_len(xbProc *p, xbValue v) {
	GB_ASSERT(v.kind == xbValue_Mem);
	return xb_load(p, xbType_I64, xb_mem_offset(v.mem, 8));
}

gb_internal xbAddr xb_build_addr_index_expr(xbProc *p, Ast *expr) {
	ast_node(ie, IndexExpr, expr);
	Type *t = base_type(type_of_expr(ie->expr));
	bool deref = is_type_pointer(t);
	t = base_type(type_deref(t));
	Type *result_type = type_of_expr(expr);

	if (is_type_soa_struct(t)) {
		xbMem container = {};
		if (deref) {
			container = xb_mem(xbMem_Reg, xb_value_to_reg(p, xb_build_expr(p, ie->expr)), 0);
		} else {
			container = xb_build_addr_mem(p, ie->expr);
		}
		xbAddr a = {};
		a.kind = xbAddr_SoaVariable;
		a.type = t->Struct.soa_elem;
		a.soa_container = t;
		a.mem = container;
		a.soa_index = xb_build_index_int(p, ie->index);
		a.soa_index_expr = ie->index;
		return a;
	}
	if (ie->expr->tav.mode == Addressing_SoaVariable) XB_UNSUPPORTED(p, "soa variable index");
	if (is_type_map(t)) {
		xbAddr map_addr = xb_build_addr(p, ie->expr);
		xbMem map_mem = xb_addr_mem(p, map_addr);
		u32 map_ptr = 0;
		if (is_type_pointer(map_addr.type)) {
			map_ptr = xb_load(p, xbType_I64, map_mem);
		} else {
			map_ptr = xb_lea(p, map_mem);
		}
		xbValue key = xb_emit_conv(p, xb_build_expr(p, ie->index), t->Map.key);
		if (key.kind == xbValue_Mem) key = xb_value_copy_to_temp(p, key);
		i32 l = xb_add_local_raw(p, 8, 8);
		xb_store(p, xbType_I64, xb_mem(xbMem_Local, cast(u32)l), map_ptr);
		xbAddr a = {};
		a.kind = xbAddr_Map;
		a.type = type_of_expr(expr);
		a.mem = xb_mem(xbMem_Local, cast(u32)l);
		a.map_key = key;
		a.map_type = t;
		a.map_result = type_of_expr(expr);
		return a;
	}

	auto index_tv = type_and_value_of_expr(ie->index);

	switch (t->kind) {
	case Type_Matrix:
		XB_UNSUPPORTED(p, "matrix index");
	case Type_Array:
	case Type_EnumeratedArray: {
		xbMem base = {};
		if (deref) {
			base = xb_mem(xbMem_Reg, xb_value_to_reg(p, xb_build_expr(p, ie->expr)), 0);
		} else {
			base = xb_build_addr_mem(p, ie->expr);
		}
		Type *elem = nullptr;
		i64 count = 0;
		ExactValue min_value = exact_value_i64(0);
		i64 stride = 0;
		if (t->kind == Type_Array) {
			elem = t->Array.elem;
			count = t->Array.count;
			stride = type_size_of(elem);
		} else if (t->kind == Type_EnumeratedArray) {
			elem = t->EnumeratedArray.elem;
			count = t->EnumeratedArray.count;
			min_value = *t->EnumeratedArray.min_value;
			stride = type_size_of(elem);
		}
		if (index_tv.mode == Addressing_Constant) {
			ExactValue idx = exact_value_sub(index_tv.value, min_value);
			i64 i = exact_value_to_i64(idx);
			return xb_addr(elem, xb_mem_offset(base, i*stride));
		}
		u32 index = 0;
		if (compare_exact_values(Token_NotEq, min_value, exact_value_i64(0))) {
			xbValue iv = xb_build_expr(p, ie->index);
			Type *index_type = t->EnumeratedArray.index;
			xbValue minv = xb_const_value(p, index_type, min_value);
			xbValue sub = xb_emit_arith(p, Token_Sub, xb_emit_conv(p, iv, index_type), minv, index_type);
			index = xb_value_to_reg(p, xb_emit_conv(p, sub, t_int));
		} else {
			index = xb_build_index_int(p, ie->index);
		}
		xb_emit_bounds_check(p, ast_token(ie->index), index, xb_iconst(p, xbType_I64, count));
		u32 ptr = xb_ptr_add_scaled(p, xb_lea(p, base), index, stride);
		xbMem em = xb_mem(xbMem_Reg, ptr, 0);
		if (base.align != 0) em.align = cast(u8)gb_min(cast(i64)base.align, type_align_of(elem));
		return xb_addr(elem, em);
	}
	case Type_Slice:
	case Type_DynamicArray:
	case Type_Basic: {
		if (t->kind == Type_Basic && !is_type_string(t)) XB_UNSUPPORTED(p, "index basic");
		if (is_type_cstring(t) || is_type_cstring16(t)) XB_UNSUPPORTED(p, "cstring index");
		xbValue v = xb_build_expr(p, ie->expr);
		if (deref) {
			v = xb_load_value(p, type_deref(v.type), xb_mem_from_ptr(p, v));
		}
		Type *elem = nullptr;
		if (t->kind == Type_Slice) elem = t->Slice.elem;
		else if (t->kind == Type_DynamicArray) elem = t->DynamicArray.elem;
		else elem = is_type_string16(t) ? t_u16 : t_u8;
		v = xb_value_mem(v.type, xb_value_to_mem(p, v));
		u32 data = xb_value_data(p, v);
		u32 len  = xb_value_len(p, v);
		u32 index = xb_build_index_int(p, ie->index);
		xb_emit_bounds_check(p, ast_token(ie->index), index, len);
		u32 ptr = xb_ptr_add_scaled(p, data, index, type_size_of(elem));
		return xb_addr(elem, xb_mem(xbMem_Reg, ptr, 0));
	}
	case Type_MultiPointer: {
		xbValue v = xb_build_expr(p, ie->expr);
		if (deref) {
			v = xb_load_value(p, type_deref(v.type), xb_mem_from_ptr(p, v));
		}
		Type *elem = t->MultiPointer.elem;
		u32 index = xb_build_index_int(p, ie->index);
		u32 ptr = xb_ptr_add_scaled(p, xb_value_to_reg(p, v), index, type_size_of(elem));
		return xb_addr(elem, xb_mem(xbMem_Reg, ptr, 0));
	}
	case Type_FixedCapacityDynamicArray:
		XB_UNSUPPORTED(p, "fixed capacity dynamic array index");
	}
	XB_UNSUPPORTED(p, "index expression");
	return {};
}

gb_internal xbAddr xb_build_addr(xbProc *p, Ast *expr) {
	expr = unparen_expr(expr);
	if (expr->state_flags & StateFlag_SelectorCallExpr) {
		XB_UNSUPPORTED(p, "selector call expression");
	}
	switch (expr->kind) {
	case_ast_node(i, Implicit, expr);
		if (i->kind == Token_context) {
			xbAddr a = {};
			a.kind = xbAddr_Context;
			a.type = t_context;
			return a;
		}
		XB_UNSUPPORTED(p, "implicit addr");
	case_end;

	case_ast_node(i, Ident, expr);
		if (is_blank_ident(expr)) {
			xbAddr a = {};
			a.kind = xbAddr_Discard;
			return a;
		}
		Entity *e = entity_of_node(expr);
		return xb_build_addr_from_entity(p, e, expr);
	case_end;

	case_ast_node(se, SelectorExpr, expr);
		Ast *sel_node = unparen_expr(se->selector);
		if (sel_node->kind != Ast_Ident) XB_UNSUPPORTED(p, "selector");
		InternedString selector = sel_node->Ident.interned;
		TypeAndValue tav = type_and_value_of_expr(se->expr);
		if (tav.mode == Addressing_Invalid) {
			// package.name
			return xb_build_addr(p, sel_node);
		}
		if (tav.mode == Addressing_Type) {
			XB_UNSUPPORTED(p, "type selector");
		}
		if (se->swizzle_count > 0) {
			Type *array_type = base_type(type_deref(tav.type));
			if (array_type->kind != Type_Array) XB_UNSUPPORTED(p, "simd swizzle");
			if (is_type_soa_pointer(tav.type)) XB_UNSUPPORTED(p, "soa swizzle");
			xbMem base = {};
			if (is_type_pointer(tav.type)) {
				base = xb_mem(xbMem_Reg, xb_value_to_reg(p, xb_build_expr(p, se->expr)), 0);
			} else {
				xbAddr a = xb_build_addr(p, se->expr);
				if (a.kind != xbAddr_Default) XB_UNSUPPORTED(p, "swizzle of special addr");
				base = a.mem;
			}
			xbAddr a = xb_addr(type_deref(expr->tav.type), base);
			a.kind = xbAddr_Swizzle;
			a.swizzle_count = se->swizzle_count;
			a.swizzle_indices = se->swizzle_indices;
			a.swizzle_elem = array_type->Array.elem;
			return a;
		}
		Selection sel = lookup_field(tav.type, selector, false);
		GB_ASSERT(sel.entity != nullptr);
		if (sel.pseudo_field) XB_UNSUPPORTED(p, "pseudo field");
		if (sel.is_bit_field) XB_UNSUPPORTED(p, "bit field selector");
		if (is_type_soa_pointer(tav.type)) XB_UNSUPPORTED(p, "soa pointer selector");
		Type *deref_type = type_deref(tav.type);
		if (tav.type->kind == Type_Pointer && deref_type->kind == Type_Named && deref_type->Named.type_name->TypeName.objc_ivar) {
			XB_UNSUPPORTED(p, "objc ivar");
		}

		xbAddr addr = xb_build_addr(p, se->expr);
		if (addr.kind == xbAddr_Context) {
			if (addr.ctx_sel.index.count > 0) {
				sel = selection_combine(addr.ctx_sel, sel);
			}
			addr.ctx_sel = sel;
			return addr;
		}
		if (addr.kind == xbAddr_SoaVariable) {
			Type *t = xb_soa_container_type(addr);
			xb_soa_bounds_check(p, addr);
			Type *ft = nullptr;
			xbMem m = xb_soa_elem_field(p, t, addr.mem, addr.soa_index, sel.index[0], &ft);
			Selection sub = sel;
			sub.index.data += 1;
			sub.index.count -= 1;
			if (sub.index.count == 0) return xb_addr(ft, m);
			return xb_emit_deep_field(p, ft, m, sub);
		}
		if (addr.kind == xbAddr_Map) {
			xbValue v = xb_addr_load(p, addr);
			xbMem m = xb_address_from_load_or_generate_local(p, v);
			return xb_emit_deep_field(p, v.type, m, sel);
		}
		if (addr.kind != xbAddr_Default) XB_UNSUPPORTED(p, "selector on special addr");
		return xb_emit_deep_field(p, addr.type, addr.mem, sel);
	case_end;

	case_ast_node(ie, IndexExpr, expr);
		return xb_build_addr_index_expr(p, expr);
	case_end;

	case_ast_node(de, DerefExpr, expr);
		Type *t = type_of_expr(de->expr);
		if (is_type_soa_pointer(t)) XB_UNSUPPORTED(p, "soa pointer deref");
				xbValue ptr = xb_build_expr(p, de->expr);
		return xb_addr(type_deref(t), xb_mem_from_ptr(p, ptr));
	case_end;

	case_ast_node(cl, CompoundLit, expr);
		xbValue v = xb_build_compound_lit(p, expr);
		return xb_addr(v.type, xb_value_to_mem(p, v));
	case_end;

	case_ast_node(ta, TypeAssertion, expr);
		xbValue e = xb_build_expr(p, ta->expr);
		Type *t = type_deref(e.type);
		if (is_type_any(t)) {
			return xb_emit_any_cast_addr(p, e, type_of_expr(expr), ast_token(expr).pos);
		}
		xbValue v = xb_emit_union_cast(p, e, type_of_expr(expr), ast_token(expr).pos);
		return xb_addr(v.type, xb_value_copy_to_temp(p, v).mem);
	case_end;
	}

	// not addressable: evaluate into a temporary
	xbValue v = xb_build_expr(p, expr);
	if (v.kind == xbValue_Invalid) XB_UNSUPPORTED(p, "addr of invalid value");
	if (v.kind == xbValue_Mem) {
		return xb_addr(v.type, v.mem);
	}
	return xb_addr(v.type, xb_value_to_mem(p, v));
}

////////////////////////////////////////////////////////////////
// Arithmetic
////////////////////////////////////////////////////////////////

gb_internal bool xb_is_numeric_scalar(Type *t) {
	xbType st = xb_scalar_type(t);
	return st != xbType_None;
}

// the value of a vreg defined by a constant in the current block
gb_internal bool xb_vreg_const(xbProc *p, u32 v, i64 *out) {
	if (p->curr == nullptr) return false;
	for (isize i = p->curr->instrs.count-1; i >= 0; i--) {
		xbInstr const &in = p->curr->instrs[i];
		if (in.dst == v) {
			if (in.op == xbOp_IConst) {
				*out = in.imm;
				return true;
			}
			return false;
		}
	}
	return false;
}

gb_internal IntegerDivisionByZeroKind xb_division_by_zero_behaviour(xbProc *p) {
	AstFile *file = nullptr;
	if (p->body && p->body->file()) {
		file = p->body->file();
	} else if (p->entity && p->entity->file) {
		file = p->entity->file;
	}
	u64 flags = (file != nullptr && file->feature_flags_set) ? file->feature_flags : 0;
	if (flags & OptInFeatureFlag_IntegerDivisionByZero_Trap)    return IntegerDivisionByZero_Trap;
	if (flags & OptInFeatureFlag_IntegerDivisionByZero_Zero)    return IntegerDivisionByZero_Zero;
	if (flags & OptInFeatureFlag_IntegerDivisionByZero_Self)    return IntegerDivisionByZero_Self;
	if (flags & OptInFeatureFlag_IntegerDivisionByZero_AllBits) return IntegerDivisionByZero_AllBits;
	return build_context.integer_division_by_zero_behaviour;
}

gb_internal u32 xb_mask_of(xbProc *p, xbType st, i64 v) {
	return xb_iconst(p, st, v);
}

// lb_integer_division and lb_integer_modulo
gb_internal u32 xb_integer_division(xbProc *p, TokenKind op, xbType st, bool is_signed, u32 a, u32 b) {
	IntegerDivisionByZeroKind behaviour = xb_division_by_zero_behaviour(p);
	bool is_div = op == Token_Quo;
	bool floored = op == Token_ModMod;

	auto do_op = [&]() -> u32 {
		if (is_div) {
			return xb_binop(p, is_signed ? xbOp_SDiv : xbOp_UDiv, st, a, b);
		}
		if (!is_signed) {
			return xb_binop(p, xbOp_URem, st, a, b);
		}
		// min(T) % -1 is 0 and must not trap: a -1 divisor becomes 1
		i64 bc = 0;
		bool const_b = xb_vreg_const(p, b, &bc);
		if (floored && const_b && bc == -1) {
			return xb_iconst(p, st, 0);
		}
		u32 minus_one = xb_iconst(p, st, -1);
		u32 safe_b = xb_select(p, st, xb_cmp(p, xbCond_EQ, st, b, minus_one), xb_iconst(p, st, 1), b);
		u32 r = xb_binop(p, xbOp_SRem, st, a, safe_b);
		if (!floored) {
			return r;
		}
		// r + b when the signs differ and r is not zero
		u32 zero = xb_iconst(p, st, 0);
		u32 corrected = xb_binop(p, xbOp_Add, st, r, b);
		u32 different = xb_cmp(p, xbCond_SLT, st, xb_binop(p, xbOp_Xor, st, a, b), zero);
		u32 nonzero = xb_cmp(p, xbCond_NE, st, r, zero);
		u32 cond = xb_binop(p, xbOp_And, xbType_I8, different, nonzero);
		return xb_select(p, st, cond, corrected, r);
	};

	i64 bc = 0;
	if (xb_vreg_const(p, b, &bc)) {
		if (bc != 0) {
			return do_op();
		}
		if (behaviour != IntegerDivisionByZero_Trap) {
			if (is_div) {
				switch (behaviour) {
				case IntegerDivisionByZero_Self:    return a;
				case IntegerDivisionByZero_Zero:    return xb_iconst(p, st, 0);
				case IntegerDivisionByZero_AllBits: return xb_iconst(p, st, -1);
				}
			} else {
				switch (behaviour) {
				case IntegerDivisionByZero_Self:    return xb_iconst(p, st, 0);
				case IntegerDivisionByZero_Zero:
				case IntegerDivisionByZero_AllBits: return a;
				}
			}
		}
	}

	xbMem res = xb_mem(xbMem_Local, cast(u32)xb_add_local_raw(p, 8, 8));
	xbBlock *safe_block = xb_new_block(p);
	xbBlock *edge_block = xb_new_block(p);
	xbBlock *done_block = xb_new_block(p);
	u32 nonzero = xb_cmp(p, xbCond_NE, st, b, xb_iconst(p, st, 0));
	xb_branch(p, nonzero, safe_block, edge_block);
	xb_start_block(p, safe_block);
	xb_store(p, st, res, do_op());
	xb_jump(p, done_block);
	xb_start_block(p, edge_block);
	switch (behaviour) {
	case IntegerDivisionByZero_Trap:
		xb_emit(p, xb_instr(xbOp_Trap));
		xb_unreachable(p);
		break;
	case IntegerDivisionByZero_Zero:
		xb_store(p, st, res, is_div ? xb_iconst(p, st, 0) : a);
		break;
	case IntegerDivisionByZero_Self:
		xb_store(p, st, res, is_div ? a : xb_iconst(p, st, 0));
		break;
	case IntegerDivisionByZero_AllBits:
		xb_store(p, st, res, is_div ? xb_iconst(p, st, -1) : a);
		break;
	}
	xb_jump(p, done_block);
	xb_start_block(p, done_block);
	return xb_load(p, st, res);
}

// element by element, scalars are spread over the array
gb_internal xbValue xb_emit_arith_array(xbProc *p, TokenKind op, xbValue x, xbValue y, Type *type) {
	Type *elem = base_array_type(type);
	i64 count = get_array_type_count(type);
	i64 stride = type_size_of(elem);
	xbMem a = xb_address_from_load_or_generate_local(p, xb_emit_conv(p, x, type));
	xbMem b = xb_address_from_load_or_generate_local(p, (op == Token_Shl || op == Token_Shr) && !is_type_array_like(y.type) ? xb_emit_conv(p, y, type) : xb_emit_conv(p, y, type));
	xbMem res = xb_add_local(p, type, false);
	if (count <= 16) {
		for (i64 i = 0; i < count; i++) {
			xbValue ea = xb_load_value(p, elem, xb_mem_offset(a, i*stride));
			xbValue eb = xb_load_value(p, elem, xb_mem_offset(b, i*stride));
			xb_store_value(p, xb_mem_offset(res, i*stride), xb_emit_arith(p, op, ea, eb, elem));
		}
		return xb_value_mem(type, res);
	}
	// a loop for long arrays
	u32 pa = xb_lea(p, a);
	u32 pb = xb_lea(p, b);
	u32 pr = xb_lea(p, res);
	i32 la = xb_add_local_raw(p, 8, 8), lb2 = xb_add_local_raw(p, 8, 8), lr = xb_add_local_raw(p, 8, 8);
	xb_store(p, xbType_I64, xb_mem(xbMem_Local, cast(u32)la), pa);
	xb_store(p, xbType_I64, xb_mem(xbMem_Local, cast(u32)lb2), pb);
	xb_store(p, xbType_I64, xb_mem(xbMem_Local, cast(u32)lr), pr);
	xbMem idx = xb_add_local(p, t_int, false);
	xb_store(p, xbType_I64, idx, xb_iconst(p, xbType_I64, 0));
	xbBlock *loop = xb_new_block(p);
	xbBlock *body = xb_new_block(p);
	xbBlock *done = xb_new_block(p);
	xb_jump(p, loop);
	xb_start_block(p, loop);
	xb_branch(p, xb_cmp(p, xbCond_SLT, xbType_I64, xb_load(p, xbType_I64, idx), xb_iconst(p, xbType_I64, count)), body, done);
	xb_start_block(p, body);
	u32 i = xb_load(p, xbType_I64, idx);
	auto at = [&](i32 l) { return xb_mem(xbMem_Reg, xb_ptr_add_scaled(p, xb_load(p, xbType_I64, xb_mem(xbMem_Local, cast(u32)l)), i, stride), 0); };
	xbValue ea = xb_load_value(p, elem, at(la));
	xbValue eb = xb_load_value(p, elem, at(lb2));
	xb_store_value(p, at(lr), xb_emit_arith(p, op, ea, eb, elem));
	xb_store(p, xbType_I64, idx, xb_binop(p, xbOp_Add, xbType_I64, i, xb_iconst(p, xbType_I64, 1)));
	xb_jump(p, loop);
	xb_start_block(p, done);
	return xb_value_mem(type, res);
}

gb_internal xbValue xb_emit_arith(xbProc *p, TokenKind op, xbValue x, xbValue y, Type *type) {
	Type *bt = core_type(type);
	if (is_type_complex(bt)) {
		x = xb_emit_conv(p, x, type);
		y = xb_emit_conv(p, y, type);
		Type *ft = base_complex_elem_type(bt);
		if (op == Token_Quo) {
			xbValue args[2] = {x, y};
			char const *name = type_size_of(ft) == 2 ? "quo_complex32" : type_size_of(ft) == 4 ? "quo_complex64" : "quo_complex128";
			return xb_emit_conv(p, xb_emit_runtime_call(p, name, xb_args(args, 2)), type);
		}
		xbValue a = xb_complex_part(p, x, 0);
		xbValue b = xb_complex_part(p, x, 1);
		xbValue c = xb_complex_part(p, y, 0);
		xbValue d = xb_complex_part(p, y, 1);
		xbValue parts[2] = {};
		switch (op) {
		case Token_Add:
		case Token_Sub:
			parts[0] = xb_emit_arith(p, op, a, c, ft);
			parts[1] = xb_emit_arith(p, op, b, d, ft);
			break;
		case Token_Mul:
			parts[0] = xb_emit_arith(p, Token_Sub, xb_emit_arith(p, Token_Mul, a, c, ft), xb_emit_arith(p, Token_Mul, b, d, ft), ft);
			parts[1] = xb_emit_arith(p, Token_Add, xb_emit_arith(p, Token_Mul, b, c, ft), xb_emit_arith(p, Token_Mul, a, d, ft), ft);
			break;
		default:
			XB_UNSUPPORTED(p, "complex operation");
		}
		return xb_complex_build(p, type, parts, 2);
	}
	if (is_type_quaternion(bt)) {
		x = xb_emit_conv(p, x, type);
		y = xb_emit_conv(p, y, type);
		Type *ft = base_complex_elem_type(bt);
		if (op == Token_Add || op == Token_Sub) {
			xbValue parts[4] = {};
			for (i64 i = 0; i < 4; i++) {
				parts[i] = xb_emit_arith(p, op, xb_complex_part(p, x, i), xb_complex_part(p, y, i), ft);
			}
			return xb_complex_build(p, type, parts, 4);
		}
		char const *name = nullptr;
		i64 bits = 8*type_size_of(ft);
		if (op == Token_Mul) name = bits == 16 ? "mul_quaternion64" : bits == 32 ? "mul_quaternion128" : "mul_quaternion256";
		else if (op == Token_Quo) name = bits == 16 ? "quo_quaternion64" : bits == 32 ? "quo_quaternion128" : "quo_quaternion256";
		else XB_UNSUPPORTED(p, "quaternion operation");
		xbValue args[2] = {x, y};
		return xb_emit_conv(p, xb_emit_runtime_call(p, name, xb_args(args, 2)), type);
	}
	if (is_type_array_like(bt)) {
		return xb_emit_arith_array(p, op, x, y, type);
	}
	if (is_type_matrix(bt) || is_type_simd_vector(bt)) {
		XB_UNSUPPORTED(p, "aggregate arithmetic");
	}
	if (xb_is_int128(type) && !is_type_different_to_arch_endianness(type)) {
		return xb_emit_arith_128(p, op, x, y, type);
	}
	if (xb_is_f16(type)) {
		xbValue a = xb_f16_to_f32(p, xb_emit_conv(p, x, type));
		xbValue b = xb_f16_to_f32(p, xb_emit_conv(p, y, type));
		return xb_float_to_f16(p, xb_emit_arith(p, op, a, b, t_f32), type);
	}
	if (is_type_different_to_arch_endianness(type) && (is_type_integer(type) || is_type_float(type))) {
		// compute in the platform's byte order
		Type *pt = integer_endian_type_to_platform_type(type);
		xbValue a = xb_emit_conv(p, xb_emit_conv(p, x, type), pt);
		xbValue b = (op == Token_Shl || op == Token_Shr) ? y : xb_emit_conv(p, xb_emit_conv(p, y, type), pt);
		return xb_emit_conv(p, xb_emit_arith(p, op, a, b, pt), type);
	}
	xbType st = xb_scalar_type(type);
	if (st == xbType_None) {
		XB_UNSUPPORTED(p, "arithmetic type");
	}

	// shifts take an unsigned count of any width
	if (op == Token_Shl || op == Token_Shr || op == Token_AndNot) {
		// handled below
	}

	if (op == Token_Shl || op == Token_Shr) {
		x = xb_emit_conv(p, x, type);
		u32 a = xb_value_to_reg(p, x);
		xbType yt = xb_scalar_type(y.type);
		if (yt == xbType_None || xb_type_is_float(yt)) XB_UNSUPPORTED(p, "shift count type");
		u32 count = xb_value_to_reg(p, y);
		// widen the count to the value width (unsigned)
		u32 cnt = xb_int_resize(p, count, yt, st, false);
		if (xb_type_size(yt) > xb_type_size(st)) {
			// a huge count still has to give zero, keep it saturated
			u32 big = xb_cmp(p, xbCond_UGE, yt, count, xb_iconst(p, yt, 8*xb_type_size(st)));
			cnt = xb_select(p, st, big, xb_iconst(p, st, 8*xb_type_size(st)), cnt);
		}
		i32 bits = 8*xb_type_size(st);
		bool is_signed = xb_type_is_signed(type);
		u32 in_range = xb_cmp(p, xbCond_ULT, st, cnt, xb_iconst(p, st, bits));
		if (op == Token_Shl) {
			u32 r = xb_binop(p, xbOp_Shl, st, a, cnt);
			return xb_value_reg(type, xb_select(p, st, in_range, r, xb_iconst(p, st, 0)));
		}
		if (is_signed) {
			// saturate the count to bits-1
			u32 c = xb_select(p, st, in_range, cnt, xb_iconst(p, st, bits-1));
			return xb_value_reg(type, xb_binop(p, xbOp_AShr, st, a, c));
		}
		u32 r = xb_binop(p, xbOp_LShr, st, a, cnt);
		return xb_value_reg(type, xb_select(p, st, in_range, r, xb_iconst(p, st, 0)));
	}

	x = xb_emit_conv(p, x, type);
	y = xb_emit_conv(p, y, type);
	u32 a = xb_value_to_reg(p, x);
	u32 b = xb_value_to_reg(p, y);

	if (xb_type_is_float(st)) {
		switch (op) {
		case Token_Add: return xb_value_reg(type, xb_binop(p, xbOp_FAdd, st, a, b));
		case Token_Sub: return xb_value_reg(type, xb_binop(p, xbOp_FSub, st, a, b));
		case Token_Mul: return xb_value_reg(type, xb_binop(p, xbOp_FMul, st, a, b));
		case Token_Quo: return xb_value_reg(type, xb_binop(p, xbOp_FDiv, st, a, b));
		case Token_Mod:
		case Token_ModMod:
			XB_UNSUPPORTED(p, "float modulo");
		}
		XB_UNSUPPORTED(p, "float op");
	}

	bool is_signed = !is_type_unsigned(type);
	switch (op) {
	case Token_Add: return xb_value_reg(type, xb_binop(p, xbOp_Add, st, a, b));
	case Token_Sub: return xb_value_reg(type, xb_binop(p, xbOp_Sub, st, a, b));
	case Token_Mul: return xb_value_reg(type, xb_binop(p, xbOp_Mul, st, a, b));
	case Token_Quo:
	case Token_Mod:
	case Token_ModMod:
		return xb_value_reg(type, xb_integer_division(p, op, st, is_signed, a, b));
	case Token_And: return xb_value_reg(type, xb_binop(p, xbOp_And, st, a, b));
	case Token_Or:  return xb_value_reg(type, xb_binop(p, xbOp_Or,  st, a, b));
	case Token_Xor: return xb_value_reg(type, xb_binop(p, xbOp_Xor, st, a, b));
	case Token_AndNot: {
		u32 nb = xb_unop(p, xbOp_Not, st, b);
		return xb_value_reg(type, xb_binop(p, xbOp_And, st, a, nb));
	}
	}
	XB_UNSUPPORTED(p, "integer op");
	return {};
}

gb_internal xbCond xb_cond_for(TokenKind op, bool is_signed, bool is_float) {
	if (is_float) {
		switch (op) {
		case Token_CmpEq: return xbCond_FEQ;
		case Token_NotEq: return xbCond_FNE;
		case Token_Lt:    return xbCond_FLT;
		case Token_LtEq:  return xbCond_FLE;
		case Token_Gt:    return xbCond_FGT;
		case Token_GtEq:  return xbCond_FGE;
		}
	}
	switch (op) {
	case Token_CmpEq: return xbCond_EQ;
	case Token_NotEq: return xbCond_NE;
	case Token_Lt:    return is_signed ? xbCond_SLT : xbCond_ULT;
	case Token_LtEq:  return is_signed ? xbCond_SLE : xbCond_ULE;
	case Token_Gt:    return is_signed ? xbCond_SGT : xbCond_UGT;
	case Token_GtEq:  return is_signed ? xbCond_SGE : xbCond_UGE;
	}
	GB_PANIC("bad comparison");
	return xbCond_EQ;
}

gb_internal xbValue xb_bool_not(xbProc *p, xbValue v) {
	u32 r = xb_value_to_reg(p, v);
	return xb_value_reg(t_llvm_bool, xb_binop(p, xbOp_Xor, xbType_I8, r, xb_iconst(p, xbType_I8, 1)));
}

gb_internal xbValue xb_cmp_zero(xbProc *p, TokenKind op, xbType st, u32 r) {
	xbCond c = op == Token_CmpEq ? xbCond_EQ : xbCond_NE;
	return xb_value_reg(t_llvm_bool, xb_cmp(p, c, st, r, xb_iconst(p, st, 0)));
}

gb_internal xbValue xb_emit_comp_against_nil(xbProc *p, TokenKind op, xbValue x) {
	Type *t = x.type;
	Type *bt = base_type(t);
	switch (bt->kind) {
	case Type_Basic:
		switch (bt->Basic.kind) {
		case Basic_rawptr:
		case Basic_cstring:
		case Basic_cstring16:
			return xb_cmp_zero(p, op, xbType_I64, xb_value_to_reg(p, x));
		case Basic_any: {
			xbMem m = xb_value_to_mem(p, x);
			u32 data = xb_load(p, xbType_I64, m);
			u32 id = xb_load(p, xbType_I64, xb_mem_offset(m, 8));
			if (op == Token_CmpEq) {
				u32 a = xb_cmp(p, xbCond_EQ, xbType_I64, data, xb_iconst(p, xbType_I64, 0));
				u32 b = xb_cmp(p, xbCond_EQ, xbType_I64, id, xb_iconst(p, xbType_I64, 0));
				return xb_value_reg(t_llvm_bool, xb_binop(p, xbOp_Or, xbType_I8, a, b));
			}
			u32 a = xb_cmp(p, xbCond_NE, xbType_I64, data, xb_iconst(p, xbType_I64, 0));
			u32 b = xb_cmp(p, xbCond_NE, xbType_I64, id, xb_iconst(p, xbType_I64, 0));
			return xb_value_reg(t_llvm_bool, xb_binop(p, xbOp_And, xbType_I8, a, b));
		}
		case Basic_typeid:
			return xb_cmp_zero(p, op, xbType_I64, xb_value_to_reg(p, x));
		}
		break;
	case Type_Enum:
	case Type_Pointer:
	case Type_MultiPointer:
	case Type_Proc: {
		xbType st = xb_scalar_type(t);
		return xb_cmp_zero(p, op, st, xb_value_to_reg(p, x));
	}
	case Type_BitSet: {
		xbType st = xb_scalar_type(t);
		if (st == xbType_None) XB_UNSUPPORTED(p, "large bit_set nil comparison");
		return xb_cmp_zero(p, op, st, xb_value_to_reg(p, x));
	}
	case Type_Slice:
	case Type_DynamicArray:
	case Type_Map: {
		xbMem m = xb_value_to_mem(p, x);
		return xb_cmp_zero(p, op, xbType_I64, xb_load(p, xbType_I64, m));
	}
	case Type_Union: {
		if (type_size_of(t) == 0) {
			return xb_const_bool(p, op == Token_CmpEq);
		}
		xbMem m = xb_value_to_mem(p, x);
		if (is_type_union_maybe_pointer(t)) {
			return xb_cmp_zero(p, op, xbType_I64, xb_load(p, xbType_I64, m));
		}
		Type *tag_type = union_tag_type(bt);
		xbType tt = xb_scalar_type(tag_type);
		return xb_cmp_zero(p, op, tt, xb_load(p, tt, xb_mem_offset(m, bt->Union.variant_block_size)));
	}
	}
	XB_UNSUPPORTED(p, "nil comparison");
	return {};
}

gb_internal xbValue xb_runtime_cmp(xbProc *p, char const *prefix, TokenKind op, xbValue x, xbValue y) {
	char const *suffix = nullptr;
	switch (op) {
	case Token_CmpEq: suffix = "eq"; break;
	case Token_NotEq: suffix = "ne"; break;
	case Token_Lt:    suffix = "lt"; break;
	case Token_Gt:    suffix = "gt"; break;
	case Token_LtEq:  suffix = "le"; break;
	case Token_GtEq:  suffix = "ge"; break;
	}
	char name[64] = {};
	gb_snprintf(name, gb_size_of(name), "%s_%s", prefix, suffix);
	xbValue args[2] = {x, y};
	return xb_emit_runtime_call(p, name, xb_args(args, 2));
}

gb_internal xbValue xb_emit_comp(xbProc *p, TokenKind op, xbValue left, xbValue right) {
	Type *a = core_type(left.type);
	Type *b = core_type(right.type);

	if (!is_type_array_like(left.type) && !is_type_array_like(right.type)) {
		if (is_type_untyped_nil(left.type) || is_type_untyped_uninit(left.type)) {
			return xb_emit_comp_against_nil(p, op, right);
		}
		if (is_type_untyped_nil(right.type) || is_type_untyped_uninit(right.type)) {
			return xb_emit_comp_against_nil(p, op, left);
		}
	}

	if (are_types_identical(a, b)) {
		// nothing to convert
	} else if (is_type_untyped(left.type)) {
		left = xb_emit_conv(p, left, right.type);
	} else if (is_type_untyped(right.type)) {
		right = xb_emit_conv(p, right, left.type);
	} else {
		Type *lt = left.type;
		Type *rt = right.type;
		i64 ls = type_size_of(lt);
		i64 rs = type_size_of(rt);
		if (check_is_assignable_to_using_subtype(lt, rt)) {
			left = xb_emit_conv(p, left, rt);
		} else if (check_is_assignable_to_using_subtype(rt, lt)) {
			right = xb_emit_conv(p, right, lt);
		} else if (ls < rs) {
			left = xb_emit_conv(p, left, rt);
		} else if (ls > rs) {
			right = xb_emit_conv(p, right, lt);
		} else if (is_type_union(rt)) {
			left = xb_emit_conv(p, left, rt);
		} else {
			right = xb_emit_conv(p, right, lt);
		}
	}

	a = core_type(left.type);
	b = core_type(right.type);

	if (is_type_array_like(a) && !is_type_simple_compare(a) && (op == Token_CmpEq || op == Token_NotEq)) {
		Type *elem = base_array_type(a);
		i64 count = get_array_type_count(a);
		i64 stride = type_size_of(elem);
		if (count > 64) XB_UNSUPPORTED(p, "long array comparison");
		xbMem ma = xb_address_from_load_or_generate_local(p, left);
		xbMem mb = xb_address_from_load_or_generate_local(p, right);
		u32 acc = xb_iconst(p, xbType_I8, op == Token_CmpEq ? 1 : 0);
		for (i64 i = 0; i < count; i++) {
			xbValue c = xb_emit_comp(p, op, xb_load_value(p, elem, xb_mem_offset(ma, i*stride)), xb_load_value(p, elem, xb_mem_offset(mb, i*stride)));
			acc = xb_binop(p, op == Token_CmpEq ? xbOp_And : xbOp_Or, xbType_I8, acc, xb_value_to_reg(p, c));
		}
		return xb_value_reg(t_llvm_bool, acc);
	}
	if (is_type_matrix(a) || is_type_array_like(a)) {
		if (op != Token_CmpEq && op != Token_NotEq) XB_UNSUPPORTED(p, "array ordering");
		if (!is_type_simple_compare(a) && !is_type_matrix(a)) XB_UNSUPPORTED(p, "array comparison");
		xbValue args[3] = {
			xb_value_reg(t_rawptr, xb_lea(p, xb_value_to_mem(p, left))),
			xb_value_reg(t_rawptr, xb_lea(p, xb_value_to_mem(p, right))),
			xb_value_reg(t_int, xb_iconst(p, xbType_I64, type_size_of(a))),
		};
		xbValue val = xb_emit_runtime_call(p, "memory_compare", xb_args(args, 3));
		return xb_cmp_zero(p, op, xb_scalar_type(val.type), xb_value_to_reg(p, val));
	}

	if ((is_type_struct(a) || is_type_union(a)) && is_type_comparable(a)) {
		i64 size = type_size_of(a);
		if (size == 0) return xb_const_bool(p, op == Token_CmpEq);
		if (!is_type_simple_compare(a)) {
			return xb_emit_record_equal(p, op, left, right, a);
		}
		xbValue args[3] = {
			xb_value_reg(t_rawptr, xb_lea(p, xb_value_to_mem(p, left))),
			xb_value_reg(t_rawptr, xb_lea(p, xb_value_to_mem(p, right))),
			xb_value_reg(t_int, xb_iconst(p, xbType_I64, size)),
		};
		xbValue res = xb_emit_runtime_call(p, "memory_equal", xb_args(args, 3));
		if (op == Token_NotEq) res = xb_bool_not(p, res);
		return res;
	}

	if (is_type_string16(a) || is_type_cstring16(a)) {
		if (is_type_cstring16(a) && is_type_cstring16(b)) {
			return xb_runtime_cmp(p, "cstring16", op, xb_emit_conv(p, left, t_cstring16), xb_emit_conv(p, right, t_cstring16));
		}
		if (is_type_cstring16(a) != is_type_cstring16(b)) {
			left = xb_emit_conv(p, left, t_string16);
			right = xb_emit_conv(p, right, t_string16);
		}
		return xb_runtime_cmp(p, "string16", op, left, right);
	}
	if (is_type_string(a)) {
		if (is_type_cstring(a) && is_type_cstring(b)) {
			return xb_runtime_cmp(p, "cstring", op, xb_emit_conv(p, left, t_cstring), xb_emit_conv(p, right, t_cstring));
		}
		if (is_type_cstring(a) != is_type_cstring(b)) {
			left = xb_emit_conv(p, left, t_string);
			right = xb_emit_conv(p, right, t_string);
		}
		return xb_runtime_cmp(p, "string", op, left, right);
	}

	if (is_type_complex(a) || is_type_quaternion(a)) {
		char const *prefix = nullptr;
		i64 sz = 8*type_size_of(a);
		if (is_type_complex(a)) {
			prefix = sz == 32 ? "complex32" : sz == 64 ? "complex64" : "complex128";
		} else {
			prefix = sz == 64 ? "quaternion64" : sz == 128 ? "quaternion128" : "quaternion256";
		}
		return xb_runtime_cmp(p, prefix, op, left, right);
	}

	if (is_type_bit_set(a)) {
		xbType st = xb_scalar_type(a);
		if (st == xbType_None) XB_UNSUPPORTED(p, "large bit_set comparison");
		if (is_type_different_to_arch_endianness(bit_set_to_int(a))) XB_UNSUPPORTED(p, "endian bit_set");
		u32 l = xb_value_to_reg(p, left);
		u32 r = xb_value_to_reg(p, right);
		switch (op) {
		case Token_CmpEq:
		case Token_NotEq:
			return xb_value_reg(t_llvm_bool, xb_cmp(p, op == Token_CmpEq ? xbCond_EQ : xbCond_NE, st, l, r));
		default: {
			u32 both = xb_binop(p, xbOp_And, st, l, r);
			u32 res = 0;
			if (op == Token_Lt || op == Token_LtEq) {
				res = xb_cmp(p, xbCond_EQ, st, both, l);
			} else {
				res = xb_cmp(p, xbCond_EQ, st, both, r);
			}
			if (op == Token_Lt || op == Token_Gt) {
				u32 eq = xb_cmp(p, xbCond_EQ, st, l, r);
				res = xb_binop(p, xbOp_And, xbType_I8, res, xb_binop(p, xbOp_Xor, xbType_I8, eq, xb_iconst(p, xbType_I8, 1)));
			}
			return xb_value_reg(t_llvm_bool, res);
		}
		}
	}

	if (xb_is_int128(a) && !is_type_different_to_arch_endianness(left.type)) {
		return xb_emit_comp_128(p, op, left, xb_emit_conv(p, right, left.type), left.type);
	}
	if (xb_is_f16(a)) {
		return xb_emit_comp(p, op, xb_f16_to_f32(p, left), xb_f16_to_f32(p, xb_emit_conv(p, right, left.type)));
	}
	if (is_type_different_to_arch_endianness(left.type) && (is_type_integer(left.type) || is_type_float(left.type))) {
		Type *pt = integer_endian_type_to_platform_type(left.type);
		return xb_emit_comp(p, op, xb_emit_conv(p, left, pt), xb_emit_conv(p, xb_emit_conv(p, right, left.type), pt));
	}

	xbType st = xb_scalar_type(a);
	if (is_type_integer(a) || is_type_boolean(a) || is_type_pointer(a) || is_type_multi_pointer(a) || is_type_proc(a) || is_type_enum(a)) {
		if (st == xbType_None) XB_UNSUPPORTED(p, "comparison of wide integer");
		u32 l = xb_value_to_reg(p, left);
		u32 r = xb_value_to_reg(p, xb_emit_conv(p, right, left.type));
		if (is_type_boolean(a) && is_type_boolean(b) && (op == Token_CmpEq || op == Token_NotEq)) {
			// anything not 0 is true
			l = xb_cmp(p, xbCond_NE, st, l, xb_iconst(p, st, 0));
			r = xb_cmp(p, xbCond_NE, xb_scalar_type(b), r, xb_iconst(p, xb_scalar_type(b), 0));
			st = xbType_I8;
		}
		bool is_unsigned = is_type_unsigned(left.type);
		return xb_value_reg(t_llvm_bool, xb_cmp(p, xb_cond_for(op, !is_unsigned, false), st, l, r));
	}
	if (is_type_float(a)) {
		if (st == xbType_None) XB_UNSUPPORTED(p, "f16 comparison");
		u32 l = xb_value_to_reg(p, left);
		u32 r = xb_value_to_reg(p, right);
		return xb_value_reg(t_llvm_bool, xb_cmp(p, xb_cond_for(op, true, true), st, l, r));
	}
	if (is_type_typeid(a)) {
		u32 l = xb_value_to_reg(p, left);
		u32 r = xb_value_to_reg(p, right);
		return xb_value_reg(t_llvm_bool, xb_cmp(p, xb_cond_for(op, false, false), xbType_I64, l, r));
	}
	XB_UNSUPPORTED(p, "comparison");
	return {};
}

// a && b, a || b
gb_internal xbValue xb_build_logical_binary(xbProc *p, Ast *expr) {
	ast_node(be, BinaryExpr, expr);
	Type *type = default_type(type_of_expr(expr));
	xbMem res = xb_add_local(p, t_bool, false);
	xbBlock *rhs = xb_new_block(p);
	xbBlock *done = xb_new_block(p);

	xbValue l = xb_build_expr(p, be->left);
	u32 lc = xb_to_bool_reg(p, l);
	xb_store(p, xbType_I8, res, lc);
	if (be->op.kind == Token_CmpAnd) {
		xb_branch(p, lc, rhs, done);
	} else {
		xb_branch(p, lc, done, rhs);
	}
	xb_start_block(p, rhs);
	xbValue r = xb_build_expr(p, be->right);
	u32 rc = xb_to_bool_reg(p, r);
	xb_store(p, xbType_I8, res, rc);
	xb_jump(p, done);
	xb_start_block(p, done);
	u32 v = xb_load(p, xbType_I8, res);
	return xb_emit_conv(p, xb_value_reg(t_bool, v), type);
}

gb_internal xbValue xb_build_binary_expr(xbProc *p, Ast *expr) {
	ast_node(be, BinaryExpr, expr);
	TypeAndValue tv = type_and_value_of_expr(expr);

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
		xbValue left = xb_build_expr(p, be->left);
		xbValue right = xb_build_expr(p, be->right);
		Type *bt = core_type(type);
		if (is_type_bit_set(bt)) {
			// set operations on the backing integer
			xbType st = xb_scalar_type(type);
			if (st == xbType_None) XB_UNSUPPORTED(p, "large bit_set op");
			u32 a = xb_value_to_reg(p, xb_emit_conv(p, left, type));
			u32 b = xb_value_to_reg(p, xb_emit_conv(p, right, type));
			switch (be->op.kind) {
			case Token_Add: case Token_Or: return xb_value_reg(type, xb_binop(p, xbOp_Or, st, a, b));
			case Token_Sub: case Token_AndNot: return xb_value_reg(type, xb_binop(p, xbOp_And, st, a, xb_unop(p, xbOp_Not, st, b)));
			case Token_And: return xb_value_reg(type, xb_binop(p, xbOp_And, st, a, b));
			case Token_Xor: return xb_value_reg(type, xb_binop(p, xbOp_Xor, st, a, b));
			}
			XB_UNSUPPORTED(p, "bit_set op");
		}
		if (is_type_pointer(bt) || is_type_multi_pointer(bt)) {
			XB_UNSUPPORTED(p, "pointer arithmetic");
		}
		return xb_emit_arith(p, be->op.kind, left, right, type);
	}
	case Token_Shl:
	case Token_Shr: {
		Type *type = default_type(tv.type);
		xbValue left = xb_build_expr(p, be->left);
		xbValue right = xb_build_expr(p, be->right);
		return xb_emit_arith(p, be->op.kind, left, right, type);
	}
	case Token_CmpEq:
	case Token_NotEq:
	case Token_Lt:
	case Token_LtEq:
	case Token_Gt:
	case Token_GtEq: {
		xbValue left = {};
		xbValue right = {};
		if (be->left->tav.mode == Addressing_Type) {
			left = xb_typeid_value(p, be->left->tav.type);
		}
		if (be->right->tav.mode == Addressing_Type) {
			right = xb_typeid_value(p, be->right->tav.type);
		}
		if (left.kind == xbValue_Invalid) left = xb_build_expr(p, be->left);
		if (right.kind == xbValue_Invalid) right = xb_build_expr(p, be->right);
		if (is_type_bit_set(core_type(left.type)) && be->op.kind != Token_CmpEq && be->op.kind != Token_NotEq) {
			XB_UNSUPPORTED(p, "bit_set subset comparison");
		}
		xbValue cmp = xb_emit_comp(p, be->op.kind, left, right);
		Type *type = default_type(tv.type);
		return xb_emit_conv(p, cmp, type);
	}
	case Token_CmpAnd:
	case Token_CmpOr:
		return xb_build_logical_binary(p, expr);
	case Token_in:
	case Token_not_in: {
		xbValue left = xb_build_expr(p, be->left);
		Type *rt = base_type(type_of_expr(be->right));
		if (is_type_pointer(rt)) rt = base_type(type_deref(rt));
		if (rt->kind == Type_BitSet) {
			xbValue right = xb_build_expr(p, be->right);
			if (is_type_pointer(right.type)) XB_UNSUPPORTED(p, "in pointer to bit_set");
			Type *key_type = rt->BitSet.elem;
			xbType st = xb_scalar_type(rt);
			if (st == xbType_None) XB_UNSUPPORTED(p, "large bit_set in");
			xbValue key = xb_emit_conv(p, left, key_type);
			xbType kt = xb_scalar_type(key_type);
			u32 k = xb_int_resize(p, xb_value_to_reg(p, key), kt, xbType_I64, xb_type_is_signed(key_type));
			if (rt->BitSet.lower != 0) {
				k = xb_binop(p, xbOp_Sub, xbType_I64, k, xb_iconst(p, xbType_I64, rt->BitSet.lower));
			}
			u32 kk = xb_int_resize(p, k, xbType_I64, st, false);
			u32 bit = xb_binop(p, xbOp_Shl, st, xb_iconst(p, st, 1), kk);
			u32 set = xb_value_to_reg(p, right);
			u32 masked = xb_binop(p, xbOp_And, st, set, bit);
			u32 res = xb_cmp(p, be->op.kind == Token_in ? xbCond_NE : xbCond_EQ, st, masked, xb_iconst(p, st, 0));
			return xb_emit_conv(p, xb_value_reg(t_llvm_bool, res), default_type(tv.type));
		}
		if (rt->kind == Type_Map) {
			xbValue right = xb_build_expr(p, be->right);
			u32 map_ptr = 0;
			if (is_type_pointer(right.type)) {
				map_ptr = xb_value_to_reg(p, right);
			} else {
				map_ptr = xb_lea(p, xb_address_from_load_or_generate_local(p, right));
			}
			u32 ptr = xb_map_get_ptr(p, map_ptr, rt, left);
			u32 res = xb_cmp(p, be->op.kind == Token_in ? xbCond_NE : xbCond_EQ, xbType_I64, ptr, xb_iconst(p, xbType_I64, 0));
			return xb_emit_conv(p, xb_value_reg(t_llvm_bool, res), default_type(tv.type));
		}
		XB_UNSUPPORTED(p, "in");
	}
	}
	XB_UNSUPPORTED(p, "binary expression");
	return {};
}

// &x.(T), as ^T or as (^T, bool)
gb_internal xbValue xb_build_address_of_type_assertion(xbProc *p, Ast *expr) {
	ast_node(ue, UnaryExpr, expr);
	TypeAndValue tv = type_and_value_of_expr(expr);
	Ast *ue_expr = unparen_expr(ue->expr);
	ast_node(ta, TypeAssertion, ue_expr);
	TokenPos pos = ast_token(expr).pos;
	Type *type = type_of_expr(ue_expr);
	xbValue e = xb_build_expr(p, ta->expr);
	Type *t = type_deref(e.type);

	u32 ok = 0;
	u32 data_ptr = 0;
	u32 src_id = 0;
	if (is_type_union(t)) {
		u32 v = 0;
		if (is_type_pointer(e.type)) {
			v = xb_value_to_reg(p, e);
		} else {
			v = xb_lea(p, xb_address_from_load_or_generate_local(p, e));
		}
		Type *src_type = base_type(t);
		if (is_type_union_maybe_pointer(src_type)) {
			ok = xb_cmp(p, xbCond_NE, xbType_I64, xb_load(p, xbType_I64, xb_mem(xbMem_Reg, v, 0)), xb_iconst(p, xbType_I64, 0));
		} else {
			Type *tag_type = union_tag_type(src_type);
			xbType tt = xb_scalar_type(tag_type);
			u32 tag = xb_load(p, tt, xb_mem(xbMem_Reg, v, cast(i32)src_type->Union.variant_block_size));
			ok = xb_cmp(p, xbCond_EQ, tt, tag, xb_iconst(p, tt, union_variant_index_checked(src_type, type)));
		}
		data_ptr = v;
	} else if (is_type_any(t)) {
		xbValue v = e;
		if (is_type_pointer(v.type)) v = xb_load_value(p, t, xb_mem_from_ptr(p, v));
		xbMem vm = xb_value_to_mem(p, v);
		data_ptr = xb_load(p, xbType_I64, vm);
		src_id = xb_load(p, xbType_I64, xb_mem_offset(vm, 8));
		ok = xb_cmp(p, xbCond_EQ, xbType_I64, src_id, xb_typeid_value(p, type).reg);
	} else {
		XB_UNSUPPORTED(p, "address of type assertion");
	}

	if (is_type_tuple(tv.type)) {
		Type *tuple = tv.type;
		Type *ptr_type = tuple->Tuple.variables[0]->type;
		Type *ok_type = tuple->Tuple.variables[1]->type;
		xbMem res = xb_add_local(p, tuple, true);
		Type *ft = nullptr;
		u32 sel = xb_select(p, xbType_I64, ok, data_ptr, xb_iconst(p, xbType_I64, 0));
		xb_store(p, xbType_I64, xb_mem_offset(res, type_offset_of(tuple, 0, &ft)), sel);
		xb_store_value(p, xb_mem_offset(res, type_offset_of(tuple, 1, &ft)), xb_emit_conv(p, xb_value_reg(t_llvm_bool, ok), ok_type));
		gb_unused(ptr_type);
		return xb_value_mem(tuple, res);
	}

	bool do_type_check = !build_context.no_type_assert && (p->state_flags & StateFlag_no_type_assert) == 0;
	if (do_type_check) {
		xbValue args[6] = {};
		args[0] = xb_value_reg(t_bool, ok);
		xb_file_line_col(p, pos, args+1);
		isize arg_count = 4;
		if (!build_context.no_rtti) {
			arg_count = 6;
			args[4] = is_type_any(t) ? xb_value_reg(t_typeid, src_id) : xb_typeid_value(p, t);
			args[5] = xb_typeid_value(p, type);
		}
		char const *name = p->context_stack.count > 0 ? "type_assertion_check_with_context" : "type_assertion_check_contextless";
		xb_emit_runtime_call(p, name, xb_args(args, arg_count));
	}
	return xb_value_reg(tv.type, data_ptr);
}

gb_internal xbValue xb_build_unary_expr(xbProc *p, Ast *expr) {
	ast_node(ue, UnaryExpr, expr);
	TypeAndValue tv = type_and_value_of_expr(expr);
	Type *type = default_type(tv.type);
	switch (ue->op.kind) {
	case Token_And: {
		Ast *ue_expr = unparen_expr(ue->expr);
		if (ue_expr->kind == Ast_IndexExpr && tv.mode == Addressing_OptionalOkPtr && is_type_tuple(tv.type)) {
			Type *tuple = tv.type;
			Type *map_type = type_of_expr(ue_expr->IndexExpr.expr);
			Type *mt = base_type(type_deref(map_type));
			xbAddr ma = xb_build_addr(p, ue_expr->IndexExpr.expr);
			xbMem mm = xb_addr_mem(p, ma);
			u32 map_ptr = is_type_pointer(ma.type) ? xb_load(p, xbType_I64, mm) : xb_lea(p, mm);
			xbValue key = xb_emit_conv(p, xb_build_expr(p, ue_expr->IndexExpr.index), mt->Map.key);
			u32 ptr = xb_map_get_ptr(p, map_ptr, mt, key);
			u32 ok = xb_cmp(p, xbCond_NE, xbType_I64, ptr, xb_iconst(p, xbType_I64, 0));
			xbMem res = xb_add_local(p, tuple, false);
			Type *ft = nullptr;
			xb_store(p, xbType_I64, xb_mem_offset(res, type_offset_of(tuple, 0, &ft)), ptr);
			xb_store_value(p, xb_mem_offset(res, type_offset_of(tuple, 1, &ft)), xb_emit_conv(p, xb_value_reg(t_llvm_bool, ok), tuple->Tuple.variables[1]->type));
			return xb_value_mem(tuple, res);
		}
		if (ue_expr->kind == Ast_CompoundLit) {
			xbValue v = xb_build_compound_lit(p, ue_expr);
			if (p->is_startup) {
				// the pointer may be stored in a global
				xbMem g = xb_static_storage(p, v.type);
				xb_store_value(p, g, v);
				return xb_value_reg(type, xb_lea(p, g));
			}
			return xb_value_reg(type, xb_lea(p, xb_value_to_mem(p, v)));
		}
		if (ue_expr->kind == Ast_TypeAssertion) {
			return xb_build_address_of_type_assertion(p, expr);
		}
		if (ue_expr->kind == Ast_IndexExpr && is_type_soa_struct(type_deref(type_of_expr(ue_expr->IndexExpr.expr)))) {
			XB_UNSUPPORTED(p, "soa pointer");
		}
		if (is_type_soa_pointer(type)) XB_UNSUPPORTED(p, "soa pointer");
		xbAddr a = xb_build_addr(p, ue->expr);
		return xb_value_reg(type, xb_lea(p, xb_addr_mem(p, a)));
	}
	case Token_Add:
		return xb_emit_conv(p, xb_build_expr(p, ue->expr), type);
	case Token_Sub: {
		xbValue x = xb_emit_conv(p, xb_build_expr(p, ue->expr), type);
		if (is_type_array_like(type)) {
			return xb_emit_arith_array(p, Token_Sub, xb_zero_value(p, type), x, type);
		}
		if (is_type_complex(type) || is_type_quaternion(type)) {
			isize n = is_type_complex(type) ? 2 : 4;
			xbValue parts[4] = {};
			Type *ft = base_complex_elem_type(core_type(type));
			for (isize i = 0; i < n; i++) {
				parts[i] = xb_emit_arith(p, Token_Sub, xb_zero_value(p, ft), xb_complex_part(p, x, i), ft);
			}
			return xb_complex_build(p, type, parts, n);
		}
		if (xb_is_int128(type) || is_type_different_to_arch_endianness(type) || xb_is_f16(type)) {
			if (xb_is_f16(type)) {
				xbMem m = xb_add_local(p, type, false);
				u32 bits = xb_load(p, xbType_I16, xb_value_to_mem(p, x));
				xb_store(p, xbType_I16, m, xb_binop(p, xbOp_Xor, xbType_I16, bits, xb_iconst(p, xbType_I16, 0x8000)));
				return xb_value_mem(type, m);
			}
			return xb_emit_arith(p, Token_Sub, xb_zero_value(p, type), x, type);
		}
		xbType st = xb_scalar_type(type);
		if (st == xbType_None) XB_UNSUPPORTED(p, "negate aggregate");
		if (xb_type_is_float(st)) {
			return xb_value_reg(type, xb_unop(p, xbOp_FNeg, st, xb_value_to_reg(p, x)));
		}
		return xb_value_reg(type, xb_unop(p, xbOp_Neg, st, xb_value_to_reg(p, x)));
	}
	case Token_Xor: {
		xbValue x = xb_emit_conv(p, xb_build_expr(p, ue->expr), type);
		if (is_type_array_like(type)) {
			Type *elem = base_array_type(type);
			xbValue ones = xb_emit_conv(p, xb_value_reg(elem, xb_iconst(p, xb_scalar_type(elem) == xbType_None ? xbType_I64 : xb_scalar_type(elem), -1)), type);
			return xb_emit_arith_array(p, Token_Xor, x, ones, type);
		}
		if (xb_is_int128(type)) {
			// complementing the bits does not care about their order
			xbPair a = xb_pair_of(p, x);
			xbPair r = {xb_unop(p, xbOp_Not, xbType_I64, a.lo), xb_unop(p, xbOp_Not, xbType_I64, a.hi)};
			return xb_pair_value(p, type, r);
		}
		xbType st = xb_scalar_type(type);
		if (st == xbType_None || xb_type_is_float(st)) XB_UNSUPPORTED(p, "complement type");
		if (is_type_bit_set(type)) {
			// only the bits of the set
			Type *bt = core_type(type);
			i64 bits = bt->BitSet.upper - bt->BitSet.lower + 1;
			u32 r = xb_unop(p, xbOp_Not, st, xb_value_to_reg(p, x));
			if (bits < 8*xb_type_size(st)) {
				u64 mask = (bits >= 64) ? ~cast(u64)0 : ((cast(u64)1 << bits) - 1);
				r = xb_binop(p, xbOp_And, st, r, xb_iconst(p, st, cast(i64)mask));
			}
			return xb_value_reg(type, r);
		}
		return xb_value_reg(type, xb_unop(p, xbOp_Not, st, xb_value_to_reg(p, x)));
	}
	case Token_Not: {
		xbValue x = xb_build_expr(p, ue->expr);
		u32 b = xb_to_bool_reg(p, x);
		u32 r = xb_binop(p, xbOp_Xor, xbType_I8, b, xb_iconst(p, xbType_I8, 1));
		return xb_emit_conv(p, xb_value_reg(t_bool, r), type);
	}
	}
	XB_UNSUPPORTED(p, "unary expression");
	return {};
}

gb_internal xbValue xb_build_ternary(xbProc *p, Ast *expr) {
	ast_node(te, TernaryIfExpr, expr);
	Type *type = default_type(type_of_expr(expr));
	xbMem res = xb_add_local(p, type, false);
	xbBlock *then_ = xb_new_block(p);
	xbBlock *else_ = xb_new_block(p);
	xbBlock *done = xb_new_block(p);
	xbValue c = xb_build_expr(p, te->cond);
	xb_branch(p, xb_to_bool_reg(p, c), then_, else_);
	xb_start_block(p, then_);
	xb_store_value(p, res, xb_emit_conv(p, xb_build_expr(p, te->x), type));
	xb_jump(p, done);
	xb_start_block(p, else_);
	xb_store_value(p, res, xb_emit_conv(p, xb_build_expr(p, te->y), type));
	xb_jump(p, done);
	xb_start_block(p, done);
	return xb_load_value(p, type, res);
}

gb_internal xbValue xb_build_type_cast(xbProc *p, Ast *expr) {
	ast_node(tc, TypeCast, expr);
	Type *type = type_of_expr(expr);
	xbValue e = xb_build_expr(p, tc->expr);
	switch (tc->token.kind) {
	case Token_cast:
		return xb_emit_conv(p, e, type);
	case Token_transmute:
		return xb_emit_transmute(p, e, type);
	}
	XB_UNSUPPORTED(p, "type cast");
	return {};
}

////////////////////////////////////////////////////////////////
// Slices
////////////////////////////////////////////////////////////////

gb_internal xbValue xb_make_slice_value(xbProc *p, Type *t, u32 data, u32 len) {
	xbMem m = xb_add_local(p, t, false);
	xb_store(p, xbType_I64, m, data);
	xb_store(p, xbType_I64, xb_mem_offset(m, 8), len);
	return xb_value_mem(t, m);
}

gb_internal void xb_emit_slice_bounds_check(xbProc *p, Token token, u32 low, u32 high, u32 len, bool lower_value_used) {
	if (xb_bounds_check_disabled(p)) return;
	xbValue args[6] = {};
	xb_file_line_col(p, token.pos, args);
	if (lower_value_used) {
		args[3] = xb_value_reg(t_int, low);
		args[4] = xb_value_reg(t_int, high);
		args[5] = xb_value_reg(t_int, len);
		char const *handler = p->context_stack.count > 0 ? "slice_expr_error_lo_hi_with_context" : "slice_expr_error_lo_hi_contextless";
		xb_emit_runtime_call(p, handler, xb_args(args, 6));
	} else {
		args[3] = xb_value_reg(t_int, high);
		args[4] = xb_value_reg(t_int, len);
		char const *handler = p->context_stack.count > 0 ? "slice_expr_error_hi_with_context" : "slice_expr_error_hi_contextless";
		xb_emit_runtime_call(p, handler, xb_args(args, 5));
	}
}

gb_internal xbValue xb_build_slice_expr(xbProc *p, Ast *expr) {
	ast_node(se, SliceExpr, expr);
	Type *type = type_of_expr(expr);
	Type *t = base_type(type_of_expr(se->expr));
	bool deref = is_type_pointer(t);
	if (deref) t = base_type(type_deref(t));

	u32 data = 0;
	u32 len = 0;
	i64 elem_size = 0;
	switch (t->kind) {
	case Type_Array: {
		xbMem base = {};
		if (deref) {
			base = xb_mem(xbMem_Reg, xb_value_to_reg(p, xb_build_expr(p, se->expr)), 0);
		} else {
			base = xb_build_addr_mem(p, se->expr);
		}
		data = xb_lea(p, base);
		len = xb_iconst(p, xbType_I64, t->Array.count);
		elem_size = type_size_of(t->Array.elem);
		break;
	}
	case Type_Slice:
	case Type_DynamicArray:
	case Type_Basic: {
		if (t->kind == Type_Basic && (!is_type_string(t) || is_type_cstring(t) || is_type_cstring16(t))) XB_UNSUPPORTED(p, "slice of basic");
		xbValue v = xb_build_expr(p, se->expr);
		if (deref) {
			v = xb_load_value(p, type_deref(v.type), xb_mem_from_ptr(p, v));
		}
		v = xb_value_mem(v.type, xb_value_to_mem(p, v));
		data = xb_value_data(p, v);
		len = xb_value_len(p, v);
		if (t->kind == Type_Slice) elem_size = type_size_of(t->Slice.elem);
		else if (t->kind == Type_DynamicArray) elem_size = type_size_of(t->DynamicArray.elem);
		else elem_size = is_type_string16(t) ? 2 : 1;
		break;
	}
	case Type_MultiPointer: {
		xbValue v = xb_build_expr(p, se->expr);
		if (deref) {
			v = xb_load_value(p, type_deref(v.type), xb_mem_from_ptr(p, v));
		}
		u32 ptr = xb_value_to_reg(p, v);
		elem_size = type_size_of(t->MultiPointer.elem);
		if (se->high == nullptr) {
			// [^]T[lo:] gives a multi pointer
			u32 lo = se->low ? xb_build_index_int(p, se->low) : xb_iconst(p, xbType_I64, 0);
			return xb_value_reg(type, xb_ptr_add_scaled(p, ptr, lo, elem_size));
		}
		u32 lo = se->low ? xb_build_index_int(p, se->low) : xb_iconst(p, xbType_I64, 0);
		u32 hi = xb_build_index_int(p, se->high);
		if (!xb_bounds_check_disabled(p)) {
			xbValue args[5] = {};
			xb_file_line_col(p, ast_token(expr).pos, args);
			args[3] = xb_value_reg(t_int, lo);
			args[4] = xb_value_reg(t_int, hi);
			char const *handler = p->context_stack.count > 0 ? "multi_pointer_slice_expr_error_with_context" : "multi_pointer_slice_expr_error_contextless";
			xb_emit_runtime_call(p, handler, xb_args(args, 5));
		}
		u32 d = xb_ptr_add_scaled(p, ptr, lo, elem_size);
		u32 n = xb_binop(p, xbOp_Sub, xbType_I64, hi, lo);
		return xb_make_slice_value(p, type, d, n);
	}
	default:
		XB_UNSUPPORTED(p, "slice expression");
	}

	u32 lo = se->low ? xb_build_index_int(p, se->low) : xb_iconst(p, xbType_I64, 0);
	u32 hi = se->high ? xb_build_index_int(p, se->high) : len;
	bool low_const = se->low == nullptr || se->low->tav.mode == Addressing_Constant;
	bool high_const = se->high == nullptr || se->high->tav.mode == Addressing_Constant;
	bool skip_check = false;
	if (t->kind == Type_Array && low_const && high_const) {
		skip_check = true; // checked at compile time
	}
	if (!skip_check) {
		xb_emit_slice_bounds_check(p, se->open, lo, hi, len, se->low != nullptr);
	}
	u32 d = xb_ptr_add_scaled(p, data, lo, elem_size);
	u32 n = xb_binop(p, xbOp_Sub, xbType_I64, hi, lo);
	Type *rt = core_type(type);
	if (is_type_string(rt) || is_type_slice(rt)) {
		return xb_make_slice_value(p, type, d, n);
	}
	XB_UNSUPPORTED(p, "slice result type");
	return {};
}

////////////////////////////////////////////////////////////////
// Compound literals
////////////////////////////////////////////////////////////////

gb_internal xbValue xb_build_compound_lit(xbProc *p, Ast *expr) {
	ast_node(cl, CompoundLit, expr);
	Type *type = type_of_expr(expr);
	Type *bt = core_type(type);

	if (cl->elems.count == 0) {
		return xb_value_mem(type, xb_add_local(p, type, true));
	}

	switch (bt->kind) {
	case Type_Struct: {
		if (bt->Struct.soa_kind != StructSoa_None) XB_UNSUPPORTED(p, "soa compound literal");
		if (bt->Struct.is_raw_union && cl->elems.count > 0) {
			// fallthrough: a raw union literal sets one field
		}
		xbMem m = xb_add_local(p, type, true);
		TypeStruct *st = &bt->Struct;
		isize field_index = 0;
		for (Ast *elem : cl->elems) {
			Ast *value_expr = elem;
			Selection sel = {};
			Type *ft = nullptr;
			i64 off = 0;
			if (elem->kind == Ast_FieldValue) {
				ast_node(fv, FieldValue, elem);
				sel = lookup_field(bt, fv->field->Ident.interned, false);
				GB_ASSERT(sel.entity != nullptr);
				if (sel.is_bit_field) XB_UNSUPPORTED(p, "bit field compound literal");
				value_expr = fv->value;
				xbAddr a = xb_emit_deep_field(p, type, m, sel);
				xbValue v = xb_build_expr(p, value_expr);
				if (is_type_tuple(v.type)) XB_UNSUPPORTED(p, "tuple in compound literal");
				xb_store_value(p, a.mem, xb_emit_conv(p, v, a.type));
				continue;
			}
			if (field_index >= st->fields.count) XB_UNSUPPORTED(p, "compound literal index");
			off = type_offset_of(bt, field_index, &ft);
			field_index++;
			xbValue v = xb_build_expr(p, value_expr);
			if (is_type_tuple(v.type)) XB_UNSUPPORTED(p, "tuple in compound literal");
			xb_store_value(p, xb_mem_offset(m, off), xb_emit_conv(p, v, ft));
		}
		return xb_value_mem(type, m);
	}
	case Type_Array:
	case Type_EnumeratedArray:
	case Type_Slice: {
		Type *et = nullptr;
		i64 count = 0;
		ExactValue min_value = exact_value_i64(0);
		if (bt->kind == Type_Array) {
			et = bt->Array.elem;
			count = bt->Array.count;
		} else if (bt->kind == Type_EnumeratedArray) {
			et = bt->EnumeratedArray.elem;
			count = bt->EnumeratedArray.count;
			min_value = *bt->EnumeratedArray.min_value;
		} else {
			et = bt->Slice.elem;
			count = cl->max_count;
		}
		i64 stride = type_size_of(et);
		xbMem m = {};
		if (bt->kind == Type_Slice) {
			Type *backing = alloc_type_array(et, count);
			m = p->is_startup ? xb_static_storage(p, backing) : xb_add_local(p, backing, true);
		} else {
			m = xb_add_local(p, type, true);
		}
		i64 elem_index = 0;
		for (Ast *elem : cl->elems) {
			if (elem->kind == Ast_FieldValue) {
				ast_node(fv, FieldValue, elem);
				if (is_ast_range(fv->field)) {
					ast_node(ie, BinaryExpr, fv->field);
					i64 lo = exact_value_to_i64(exact_value_sub(ie->left->tav.value, min_value));
					i64 hi = exact_value_to_i64(exact_value_sub(ie->right->tav.value, min_value));
					if (ie->op.kind != Token_RangeHalf) hi += 1;
					xbValue v = xb_emit_conv(p, xb_build_expr(p, fv->value), et);
					if (hi - lo > 256) XB_UNSUPPORTED(p, "large ranged compound literal");
					for (i64 k = lo; k < hi; k++) {
						xb_store_value(p, xb_mem_offset(m, k*stride), v);
					}
				} else {
					i64 index = exact_value_to_i64(exact_value_sub(fv->field->tav.value, min_value));
					xbValue v = xb_emit_conv(p, xb_build_expr(p, fv->value), et);
					xb_store_value(p, xb_mem_offset(m, index*stride), v);
				}
			} else {
				xbValue v = xb_build_expr(p, elem);
				if (is_type_tuple(v.type)) XB_UNSUPPORTED(p, "tuple in compound literal");
				v = xb_emit_conv(p, v, et);
				xb_store_value(p, xb_mem_offset(m, elem_index*stride), v);
				elem_index++;
			}
		}
		if (bt->kind == Type_Slice) {
			return xb_make_slice_value(p, type, xb_lea(p, m), xb_iconst(p, xbType_I64, count));
		}
		return xb_value_mem(type, m);
	}
	case Type_DynamicArray: {
		xbMem m = xb_add_local(p, type, true);
		Type *et = bt->DynamicArray.elem;
		i64 item_count = gb_max(cast(i64)cl->max_count, cast(i64)cl->elems.count);
		String proc_name = p->entity ? p->entity->token.string : str_lit("");
		TokenPos pos = ast_token(expr).pos;
		{
			xbValue args[5] = {
				xb_value_reg(t_rawptr, xb_lea(p, m)),
				xb_value_reg(t_int, xb_iconst(p, xbType_I64, type_size_of(et))),
				xb_value_reg(t_int, xb_iconst(p, xbType_I64, type_align_of(et))),
				xb_value_reg(t_int, xb_iconst(p, xbType_I64, item_count)),
				xb_source_code_location(p, proc_name, pos),
			};
			xb_emit_runtime_call(p, "__dynamic_array_reserve", xb_args(args, 5));
		}
		// the items in a local array, appended in one go
		Type *arr = alloc_type_array(et, item_count);
		xbMem items = xb_add_local(p, arr, true);
		i64 stride = type_size_of(et);
		i64 elem_index = 0;
		for (Ast *elem : cl->elems) {
			if (elem->kind == Ast_FieldValue) {
				ast_node(fv, FieldValue, elem);
				if (is_ast_range(fv->field)) {
					ast_node(ie, BinaryExpr, fv->field);
					i64 lo = exact_value_to_i64(ie->left->tav.value);
					i64 hi = exact_value_to_i64(ie->right->tav.value);
					if (ie->op.kind != Token_RangeHalf) hi += 1;
					xbValue v = xb_emit_conv(p, xb_build_expr(p, fv->value), et);
					for (i64 k = lo; k < hi; k++) xb_store_value(p, xb_mem_offset(items, k*stride), v);
				} else {
					i64 index = exact_value_to_i64(fv->field->tav.value);
					xb_store_value(p, xb_mem_offset(items, index*stride), xb_emit_conv(p, xb_build_expr(p, fv->value), et));
				}
			} else {
				xb_store_value(p, xb_mem_offset(items, elem_index*stride), xb_emit_conv(p, xb_build_expr(p, elem), et));
				elem_index++;
			}
		}
		{
			xbValue args[6] = {
				xb_value_reg(t_rawptr, xb_lea(p, m)),
				xb_value_reg(t_int, xb_iconst(p, xbType_I64, type_size_of(et))),
				xb_value_reg(t_int, xb_iconst(p, xbType_I64, type_align_of(et))),
				xb_value_reg(t_rawptr, xb_lea(p, items)),
				xb_value_reg(t_int, xb_iconst(p, xbType_I64, item_count)),
				xb_source_code_location(p, proc_name, pos),
			};
			xb_emit_runtime_call(p, "__dynamic_array_append", xb_args(args, 6));
		}
		return xb_value_mem(type, m);
	}
	case Type_Map: {
		xbMem m = xb_add_local(p, type, true);
		u32 map_ptr = xb_lea(p, m);
		i32 info = xb_map_info_sym(p, bt);
		String proc_name = p->entity ? p->entity->token.string : str_lit("");
		xbValue args[4] = {
			xb_value_reg(t_rawptr, map_ptr),
			xb_value_reg(t_map_info_ptr, xb_lea(p, xb_mem(xbMem_Sym, cast(u32)info))),
			xb_value_reg(t_uint, xb_iconst(p, xbType_I64, 2*cl->elems.count)),
			xb_source_code_location(p, proc_name, ast_token(expr).pos),
		};
		xb_emit_runtime_call(p, "__dynamic_map_reserve", xb_args(args, 4));
		for (Ast *elem : cl->elems) {
			ast_node(fv, FieldValue, elem);
			xbValue key = xb_build_expr(p, fv->field);
			xbValue value = xb_build_expr(p, fv->value);
			xb_map_set(p, xb_lea(p, m), bt, key, value, ast_token(elem).pos);
		}
		return xb_value_mem(type, m);
	}
	case Type_Basic:
		if (bt->Basic.kind == Basic_any) {
			xbMem m = xb_add_local(p, type, true);
			isize index = 0;
			for (Ast *elem : cl->elems) {
				Ast *value_expr = elem;
				i64 field = index++;
				if (elem->kind == Ast_FieldValue) {
					ast_node(fv, FieldValue, elem);
					Selection sel = lookup_field(bt, fv->field->Ident.interned, false);
					field = sel.index[0];
					value_expr = fv->value;
				}
				Type *ft = nullptr;
				i64 off = type_offset_of(bt, field, &ft);
				xb_store_value(p, xb_mem_offset(m, off), xb_emit_conv(p, xb_build_expr(p, value_expr), ft));
			}
			return xb_value_mem(type, m);
		}
		break;
	case Type_BitSet: {
		xbType st = xb_scalar_type(type);
		if (st == xbType_None) XB_UNSUPPORTED(p, "large bit_set literal");
		u32 acc = xb_iconst(p, st, 0);
		Type *et = bt->BitSet.elem;
		for (Ast *elem : cl->elems) {
			xbValue v = xb_build_expr(p, elem);
			xbType kt = xb_scalar_type(et);
			if (kt == xbType_None) XB_UNSUPPORTED(p, "bit_set elem type");
			u32 k = xb_int_resize(p, xb_value_to_reg(p, xb_emit_conv(p, v, et)), kt, xbType_I64, xb_type_is_signed(et));
			if (bt->BitSet.lower != 0) {
				k = xb_binop(p, xbOp_Sub, xbType_I64, k, xb_iconst(p, xbType_I64, bt->BitSet.lower));
			}
			u32 kk = xb_int_resize(p, k, xbType_I64, st, false);
			acc = xb_binop(p, xbOp_Or, st, acc, xb_binop(p, xbOp_Shl, st, xb_iconst(p, st, 1), kk));
		}
		return xb_value_reg(type, acc);
	}
	}
	{
		gbString r = gb_string_make(permanent_allocator(), "compound literal ");
		r = gb_string_appendc(r, type_to_string(bt));
		if (bt->kind == Type_Struct) r = gb_string_make(permanent_allocator(), "compound literal struct");
		XB_UNSUPPORTED(p, r);
	}
	return {};
}

////////////////////////////////////////////////////////////////
// Expressions
////////////////////////////////////////////////////////////////

////////////////////////////////////////////////////////////////
// or_return, or_else, or_break, or_continue
////////////////////////////////////////////////////////////////

gb_internal void xb_return_with_results(xbProc *p, Array<xbValue> &results, bool store_named);
gb_internal void xb_build_return_stmt(xbProc *p, Slice<Ast *> const &results, TokenPos pos);
gb_internal void xb_emit_defer_stmts(xbProc *p, bool is_return, xbBlock *branch_target);
gb_internal xbBranchBlocks xb_lookup_branch_blocks(xbProc *p, Ast *ident);

gb_internal void xb_emit_try_lhs_rhs(xbProc *p, Ast *arg, TypeAndValue const &tv, xbValue *lhs_, xbValue *rhs_) {
	xbValue lhs = {};
	xbValue rhs = {};
	xbValue value = xb_build_expr(p, arg);
	if (is_type_tuple(value.type)) {
		Type *tt = value.type;
		isize n = tt->Tuple.variables.count-1;
		xbMem m = xb_value_to_mem(p, value);
		Type *ft = nullptr;
		if (tt->Tuple.variables.count == 2) {
			i64 off = type_offset_of(tt, 0, &ft);
			lhs = xb_load_value(p, ft, xb_mem_offset(m, off));
		} else if (tt->Tuple.variables.count > 2) {
			xbMem lm = xb_add_local(p, tv.type, false);
			for (isize i = 0; i < n; i++) {
				Type *dt = nullptr;
				i64 doff = type_offset_of(tv.type, i, &dt);
				i64 soff = type_offset_of(tt, i, &ft);
				xb_store_value(p, xb_mem_offset(lm, doff), xb_load_value(p, ft, xb_mem_offset(m, soff)));
			}
			lhs = xb_value_mem(tv.type, lm);
		}
		i64 off = type_offset_of(tt, n, &ft);
		rhs = xb_load_value(p, ft, xb_mem_offset(m, off));
	} else {
		rhs = value;
	}
	if (lhs_) *lhs_ = lhs;
	if (rhs_) *rhs_ = rhs;
}

gb_internal u32 xb_emit_try_has_value(xbProc *p, xbValue rhs) {
	if (is_type_boolean(rhs.type)) {
		return xb_to_bool_reg(p, rhs);
	}
	return xb_value_to_reg(p, xb_emit_comp_against_nil(p, Token_CmpEq, rhs));
}

gb_internal xbValue xb_emit_or_return(xbProc *p, Ast *arg, TypeAndValue const &tv) {
	xbValue lhs = {};
	xbValue rhs = {};
	xb_emit_try_lhs_rhs(p, arg, tv, &lhs, &rhs);
	xbBlock *return_block = xb_new_block(p);
	xbBlock *continue_block = xb_new_block(p);
	xb_branch(p, xb_emit_try_has_value(p, rhs), continue_block, return_block);
	xb_start_block(p, return_block);
	{
		Type *proc_type = base_type(p->type);
		TypeTuple *tuple = &proc_type->Proc.results->Tuple;
		Entity *end_entity = tuple->variables[tuple->variables.count-1];
		rhs = xb_emit_conv(p, rhs, end_entity->type);
		if (proc_type->Proc.has_named_results) {
			xbVar *found = map_get(&p->vars, end_entity);
			GB_ASSERT(found != nullptr);
			xb_store_value(p, found->mem, rhs);
			xb_build_return_stmt(p, {}, ast_token(arg).pos);
		} else {
			GB_ASSERT(tuple->variables.count == 1);
			auto results = array_make<xbValue>(xb_allocator(), 0, 1);
			array_add(&results, rhs);
			xb_return_with_results(p, results, false);
			array_free(&results);
		}
	}
	xb_start_block(p, continue_block);
	if (tv.type != nullptr && lhs.kind != xbValue_Invalid) {
		return xb_emit_conv(p, lhs, tv.type);
	}
	return {};
}

gb_internal xbValue xb_emit_or_else(xbProc *p, Ast *arg, Ast *else_expr, TypeAndValue const &tv) {
	if (arg->state_flags & StateFlag_DirectiveWasFalse) {
		return xb_build_expr(p, else_expr);
	}
	xbValue lhs = {};
	xbValue rhs = {};
	xb_emit_try_lhs_rhs(p, arg, tv, &lhs, &rhs);
	Type *type = default_type(tv.type);

	if (is_diverging_expr(else_expr)) {
		xbBlock *then_ = xb_new_block(p);
		xbBlock *else_ = xb_new_block(p);
		xb_branch(p, xb_emit_try_has_value(p, rhs), then_, else_);
		xb_start_block(p, else_);
		xb_build_expr(p, else_expr);
		xb_unreachable(p);
		xb_start_block(p, then_);
		if (lhs.kind != xbValue_Invalid && type != nullptr) {
			return xb_emit_conv(p, lhs, type);
		}
		return {};
	}
	xbMem res = xb_add_local(p, type, false);
	xbBlock *then_ = xb_new_block(p);
	xbBlock *else_ = xb_new_block(p);
	xbBlock *done = xb_new_block(p);
	xb_branch(p, xb_emit_try_has_value(p, rhs), then_, else_);
	xb_start_block(p, then_);
	xb_store_value(p, res, xb_emit_conv(p, lhs, type));
	xb_jump(p, done);
	xb_start_block(p, else_);
	xb_store_value(p, res, xb_emit_conv(p, xb_build_expr(p, else_expr), type));
	xb_jump(p, done);
	xb_start_block(p, done);
	return xb_load_value(p, type, res);
}

gb_internal xbValue xb_emit_or_branch(xbProc *p, Ast *expr, TypeAndValue const &tv) {
	ast_node(be, OrBranchExpr, expr);
	xbBlock *block = nullptr;
	if (be->label != nullptr) {
		xbBranchBlocks bb = xb_lookup_branch_blocks(p, be->label);
		switch (be->token.kind) {
		case Token_or_break:    block = bb.break_;    break;
		case Token_or_continue: block = bb.continue_; break;
		}
	} else {
		for (xbTargetList *t = p->targets; t != nullptr && block == nullptr; t = t->prev) {
			if (t->is_block) continue;
			switch (be->token.kind) {
			case Token_or_break:    block = t->break_;    break;
			case Token_or_continue: block = t->continue_; break;
			}
		}
	}
	GB_ASSERT(block != nullptr);
	xbValue lhs = {};
	xbValue rhs = {};
	xb_emit_try_lhs_rhs(p, be->expr, tv, &lhs, &rhs);
	Type *type = default_type(tv.type);
	if (lhs.kind != xbValue_Invalid) {
		lhs = xb_emit_conv(p, lhs, type);
	} else if (type != nullptr && type != t_invalid) {
		lhs = xb_zero_value(p, type);
	}
	xbBlock *then_ = xb_new_block(p);
	xbBlock *else_ = xb_new_block(p);
	xb_branch(p, xb_emit_try_has_value(p, rhs), then_, else_);
	xb_start_block(p, else_);
	xb_emit_defer_stmts(p, false, block);
	xb_jump(p, block);
	xb_start_block(p, then_);
	return lhs;
}

////////////////////////////////////////////////////////////////
// Type assertions
////////////////////////////////////////////////////////////////

gb_internal void xb_emit_type_assertion_check(xbProc *p, u32 ok, TokenPos pos, Type *src_type, Type *dst_type, u32 src_typeid, u32 data_ptr) {
	if (build_context.no_type_assert) return;
	xbValue args[7] = {};
	args[0] = xb_value_reg(t_bool, ok);
	xb_file_line_col(p, pos, args+1);
	isize arg_count = 4;
	if (!build_context.no_rtti) {
		arg_count = 7;
		args[4] = src_typeid ? xb_value_reg(t_typeid, src_typeid) : xb_typeid_value(p, src_type);
		args[5] = xb_typeid_value(p, dst_type);
		args[6] = xb_value_reg(t_rawptr, data_ptr);
	}
	char const *name = p->context_stack.count > 0 ? "type_assertion_check2_with_context" : "type_assertion_check2_contextless";
	xb_emit_runtime_call(p, name, xb_args(args, arg_count));
}

// x.(T) on a union, as a (T, bool) tuple or just T
gb_internal xbValue xb_emit_union_cast(xbProc *p, xbValue value, Type *type, TokenPos pos) {
	Type *src_type = value.type;
	bool is_ptr = is_type_pointer(src_type);
	bool is_tuple = type->kind == Type_Tuple;
	Type *tuple = is_tuple ? type : make_optional_ok_type(type);
	if (is_ptr) {
		value = xb_load_value(p, type_deref(src_type), xb_mem_from_ptr(p, value));
	}
	Type *src = base_type(type_deref(src_type));
	Type *dst = tuple->Tuple.variables[0]->type;
	xbMem vm = xb_address_from_load_or_generate_local(p, value);

	if ((p->state_flags & StateFlag_no_type_assert) != 0 && !is_tuple) {
		return xb_load_value(p, type, vm);
	}

	xbMem res = xb_add_local(p, tuple, true);
	Type *ft = nullptr;
	i64 off0 = type_offset_of(tuple, 0, &ft);
	i64 off1 = type_offset_of(tuple, 1, &ft);

	u32 cond = 0;
	if (is_type_union_maybe_pointer(src)) {
		u32 data = xb_load(p, xbType_I64, vm);
		cond = xb_cmp(p, xbCond_NE, xbType_I64, data, xb_iconst(p, xbType_I64, 0));
	} else {
		Type *tag_type = union_tag_type(src);
		xbType tt = xb_scalar_type(tag_type);
		u32 tag = xb_load(p, tt, xb_mem_offset(vm, src->Union.variant_block_size));
		cond = xb_cmp(p, xbCond_EQ, tt, tag, xb_iconst(p, tt, union_variant_index_checked(src, dst)));
	}
	xbBlock *ok_block = xb_new_block(p);
	xbBlock *end_block = xb_new_block(p);
	xb_branch(p, cond, ok_block, end_block);
	xb_start_block(p, ok_block);
	xb_memcopy(p, xb_mem_offset(res, off0), vm, type_size_of(dst));
	xb_store(p, xbType_I8, xb_mem_offset(res, off1), xb_iconst(p, xbType_I8, 1));
	xb_jump(p, end_block);
	xb_start_block(p, end_block);

	if (!is_tuple) {
		if (!build_context.no_type_assert) {
			u32 ok = xb_load(p, xbType_I8, xb_mem_offset(res, off1));
			xb_emit_type_assertion_check(p, ok, pos, src_type, dst, 0, xb_lea(p, vm));
		}
		return xb_load_value(p, dst, xb_mem_offset(res, off0));
	}
	return xb_value_mem(tuple, res);
}

// x.(T) on an any. Without the ok value, the result is the address of the data.
gb_internal xbAddr xb_emit_any_cast_addr(xbProc *p, xbValue value, Type *type, TokenPos pos) {
	Type *src_type = value.type;
	if (is_type_pointer(src_type)) {
		value = xb_load_value(p, type_deref(src_type), xb_mem_from_ptr(p, value));
	}
	bool is_tuple = type->kind == Type_Tuple;
	Type *tuple = is_tuple ? type : make_optional_ok_type(type);
	Type *dst_type = tuple->Tuple.variables[0]->type;
	xbMem vm = xb_value_to_mem(p, value);

	if ((p->state_flags & StateFlag_no_type_assert) != 0 && !is_tuple) {
		u32 ptr = xb_load(p, xbType_I64, vm);
		return xb_addr(type, xb_mem(xbMem_Reg, ptr, 0));
	}

	xbMem res = xb_add_local(p, tuple, true);
	Type *ft = nullptr;
	i64 off0 = type_offset_of(tuple, 0, &ft);
	i64 off1 = type_offset_of(tuple, 1, &ft);

	xbValue dst_typeid = xb_typeid_value(p, dst_type);
	u32 any_typeid = xb_load(p, xbType_I64, xb_mem_offset(vm, 8));
	u32 cond = xb_cmp(p, xbCond_EQ, xbType_I64, any_typeid, dst_typeid.reg);
	xbBlock *ok_block = xb_new_block(p);
	xbBlock *end_block = xb_new_block(p);
	xb_branch(p, cond, ok_block, end_block);
	xb_start_block(p, ok_block);
	u32 data = xb_load(p, xbType_I64, vm);
	xb_memcopy(p, xb_mem_offset(res, off0), xb_mem(xbMem_Reg, data, 0), type_size_of(dst_type));
	xb_store(p, xbType_I8, xb_mem_offset(res, off1), xb_iconst(p, xbType_I8, 1));
	xb_jump(p, end_block);
	xb_start_block(p, end_block);

	if (!is_tuple) {
		if (!build_context.no_type_assert) {
			u32 ok = xb_load(p, xbType_I8, xb_mem_offset(res, off1));
			u32 tid = xb_load(p, xbType_I64, xb_mem_offset(vm, 8));
			u32 dp = xb_load(p, xbType_I64, vm);
			xb_emit_type_assertion_check(p, ok, pos, nullptr, dst_type, tid, dp);
		}
		return xb_addr(dst_type, xb_mem_offset(res, off0));
	}
	return xb_addr(tuple, res);
}

gb_internal xbValue xb_build_type_assertion(xbProc *p, Ast *expr) {
	ast_node(ta, TypeAssertion, expr);
	TokenPos pos = ast_token(expr).pos;
	Type *type = type_of_expr(expr);
	xbValue e = xb_build_expr(p, ta->expr);
	Type *t = type_deref(e.type);
	if (is_type_union(t)) {
		return xb_emit_union_cast(p, e, type, pos);
	} else if (is_type_any(t)) {
		return xb_addr_load(p, xb_emit_any_cast_addr(p, e, type, pos));
	}
	XB_UNSUPPORTED(p, "type assertion");
	return {};
}

gb_internal xbValue xb_build_expr_internal(xbProc *p, Ast *expr) {
	expr = unparen_expr(expr);
	TypeAndValue tv = type_and_value_of_expr(expr);
	Type *type = type_of_expr(expr);

	if (tv.value.kind != ExactValue_Invalid) {
		return xb_const_value(p, type, tv.value);
	} else if (tv.mode == Addressing_Type) {
		return xb_typeid_value(p, tv.type);
	}

	switch (expr->kind) {
	case_ast_node(i, Implicit, expr);
		return xb_addr_load(p, xb_build_addr(p, expr));
	case_end;

	case_ast_node(u, Uninit, expr);
		xbValue v = {};
		v.kind = xbValue_Invalid;
		v.type = is_type_untyped(type) ? t_untyped_uninit : type;
		if (!is_type_untyped(type)) {
			return xb_value_mem(type, xb_add_local(p, type, false));
		}
		return v;
	case_end;

	case_ast_node(i, Ident, expr);
		Entity *e = entity_from_expr(expr);
		e = strip_entity_wrapping(e);
		GB_ASSERT(e != nullptr);
		if (e->kind == Entity_Nil) {
			xbValue v = {};
			v.kind = xbValue_Invalid;
			v.type = e->type;
			return v;
		}
		if (e->kind == Entity_Builtin) XB_UNSUPPORTED(p, "builtin as value");
		if (e->kind == Entity_Procedure) {
			return xb_proc_value_from_entity(p, e);
		}
		xbAddr a = xb_build_addr_from_entity(p, e, expr);
		return xb_addr_load(p, a);
	case_end;

	case_ast_node(de, DerefExpr, expr);
		return xb_addr_load(p, xb_build_addr(p, expr));
	case_end;

	case_ast_node(se, SelectorExpr, expr);
		return xb_addr_load(p, xb_build_addr(p, expr));
	case_end;

	case_ast_node(ie, IndexExpr, expr);
		return xb_addr_load(p, xb_build_addr(p, expr));
	case_end;

	case_ast_node(se, SliceExpr, expr);
		return xb_build_slice_expr(p, expr);
	case_end;

	case_ast_node(ue, UnaryExpr, expr);
		return xb_build_unary_expr(p, expr);
	case_end;

	case_ast_node(be, BinaryExpr, expr);
		return xb_build_binary_expr(p, expr);
	case_end;

	case_ast_node(tc, TypeCast, expr);
		return xb_build_type_cast(p, expr);
	case_end;

	case_ast_node(ac, AutoCast, expr);
		return xb_emit_conv(p, xb_build_expr(p, ac->expr), type);
	case_end;

	case_ast_node(te, TernaryIfExpr, expr);
		return xb_build_ternary(p, expr);
	case_end;

	case_ast_node(te, TernaryWhenExpr, expr);
		TypeAndValue ctv = type_and_value_of_expr(te->cond);
		GB_ASSERT(ctv.value.kind == ExactValue_Bool);
		if (ctv.value.value_bool) {
			return xb_emit_conv(p, xb_build_expr(p, te->x), type);
		}
		return xb_emit_conv(p, xb_build_expr(p, te->y), type);
	case_end;

	case_ast_node(cl, CompoundLit, expr);
		return xb_build_compound_lit(p, expr);
	case_end;

	case_ast_node(ce, CallExpr, expr);
		return xb_build_call_expr(p, expr);
	case_end;

	case_ast_node(pl, ProcLit, expr);
		return xb_proc_lit_value(p, expr, type);
	case_end;

	case_ast_node(oe, OrElseExpr, expr);
		return xb_emit_or_else(p, oe->x, oe->y, tv);
	case_end;

	case_ast_node(ta, TypeAssertion, expr);
		return xb_build_type_assertion(p, expr);
	case_end;

	case_ast_node(oe, OrReturnExpr, expr);
		return xb_emit_or_return(p, oe->expr, tv);
	case_end;

	case_ast_node(be, OrBranchExpr, expr);
		return xb_emit_or_branch(p, expr, tv);
	case_end;
	}

	{
		gbString r = gb_string_make(permanent_allocator(), "expression ");
		r = gb_string_append_length(r, ast_strings[expr->kind].text, ast_strings[expr->kind].len);
		XB_UNSUPPORTED(p, r);
	}
	return {};
}

gb_internal xbValue xb_build_expr(xbProc *p, Ast *expr) {
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
	if (expr->state_flags & StateFlag_SelectorCallExpr) {
		XB_UNSUPPORTED(p, "selector call expression");
	}
	return xb_build_expr_internal(p, expr);
}
