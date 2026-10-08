// Objective-C: the objc_* builtins, calls of Objective-C methods, blocks, and the setup
// procedure that registers selectors and classes at startup. A port of the LLVM backend's:
// the globals have the same names, so code of either backend uses the other's.

String lb_get_objc_type_encoding(Type *t, isize pointer_depth);

gb_internal xbProc *xb_new_proc(xbModule *m, String name, Type *type);

gb_internal char const *const xb_objc_prefixes[xbObjc_COUNT] = {"__$objc_SEL::", "__$objc_Class::", "__$objc_ivar::"};

// The symbol of the global for a selector, class or ivar offset `name`.
gb_internal i32 xb_objc_find(xbModule *m, xbObjcKind kind, String name, Type *class_type=nullptr) {
	i32 *found = string_map_get(&m->objc_global_map[kind], name);
	if (found) {
		xbObjcGlobal *g = &m->objc_globals[kind][*found];
		if (g->class_type == nullptr) g->class_type = class_type;
		return g->sym;
	}
	gbString s = gb_string_make(heap_allocator(), xb_objc_prefixes[kind]);
	s = gb_string_append_length(s, name.text, name.len);
	xbObjcGlobal g = {};
	g.name = copy_string(permanent_allocator(), name);
	g.sym = xb_symbol(m, make_string(cast(u8 *)s, gb_string_length(s)));
	g.class_type = class_type;
	gb_string_free(s);
	string_map_set(&m->objc_global_map[kind], g.name, cast(i32)m->objc_globals[kind].count);
	array_add(&m->objc_globals[kind], g);
	return g.sym;
}

gb_internal xbMem xb_objc_selector_mem(xbProc *p, String name) {
	return xb_mem(xbMem_Sym, cast(u32)xb_objc_find(p->m, xbObjc_Selector, name));
}

gb_internal xbMem xb_objc_class_mem(xbProc *p, Entity *tn) {
	GB_ASSERT(tn->kind == Entity_TypeName);
	Type *impl = tn->TypeName.objc_is_implementation ? tn->type : nullptr;
	return xb_mem(xbMem_Sym, cast(u32)xb_objc_find(p->m, xbObjc_Class, tn->TypeName.objc_class_name, impl));
}

gb_internal xbValue xb_objc_selector(xbProc *p, String name) {
	return xb_value_reg(t_objc_SEL, xb_load(p, xbType_I64, xb_objc_selector_mem(p, name)));
}

// The ivar of the object `self` points at, from the offset the setup found.
gb_internal xbValue xb_objc_ivar_ptr(xbProc *p, xbValue self) {
	Type *self_type = type_deref(self.type);
	GB_ASSERT(is_type_pointer(self.type) && self_type->kind == Type_Named);
	Entity *tn = self_type->Named.type_name;
	i32 sym = xb_objc_find(p->m, xbObjc_Ivar, tn->TypeName.objc_class_name, self_type);
	u32 offset = xb_load(p, xbType_I64, xb_mem(xbMem_Sym, cast(u32)sym));
	u32 ptr = xb_binop(p, xbOp_Add, xbType_I64, xb_value_to_reg(p, self), offset);
	return xb_value_reg(alloc_type_pointer(tn->TypeName.objc_ivar), ptr);
}

// The receiver of objc_send: a class given by its type, or an object.
gb_internal xbValue xb_objc_id(xbProc *p, Ast *expr) {
	TypeAndValue const &tav = type_and_value_of_expr(expr);
	if (tav.mode == Addressing_Type) {
		GB_ASSERT(tav.type->kind == Type_Named);
		return xb_value_reg(t_objc_Class, xb_load(p, xbType_I64, xb_objc_class_mem(p, tav.type->Named.type_name)));
	}
	return xb_build_expr(p, expr);
}

gb_internal xbValue xb_objc_msg_send(xbProc *p, ObjcMsgData const &data, bool super, Slice<xbValue> args) {
	char const *name = "objc_msgSend";
	switch (data.kind) {
	case ObjcMsg_normal: name = super ? "objc_msgSendSuper2" : "objc_msgSend"; break;
	case ObjcMsg_fpret:  name = super ? "objc_msgSendSuper2" : "objc_msgSend_fpret"; break;
	case ObjcMsg_fp2ret: name = super ? "objc_msgSendSuper2" : "objc_msgSend_fp2ret"; break;
	case ObjcMsg_stret:  name = super ? "objc_msgSendSuper2_stret" : "objc_msgSend_stret"; break;
	}
	Entity *e = xb_lookup_runtime_entity(p->m, name);
	i32 sym = xb_entity_symbol(p, e);
	// called as the procedure type the checker made for this message
	Type *pt = base_type(data.proc_type);
	if (pt->Proc.param_count != args.count) XB_UNSUPPORTED(p, "objc message arguments");
	for_array(i, args) {
		args[i] = xb_emit_conv(p, args[i], pt->Proc.params->Tuple.variables[i]->type);
	}
	xbValue callee = {};
	callee.type = data.proc_type;
	return xb_emit_call_internal(p, callee, sym, args);
}

gb_internal xbValue xb_build_objc_send(xbProc *p, Ast *expr) {
	ast_node(ce, CallExpr, expr);
	ObjcMsgData data = map_must_get(&p->m->info->objc_msgSend_types, expr);
	auto args = array_make<xbValue>(xb_allocator(), 0, ce->args.count-1);
	array_add(&args, xb_objc_id(p, ce->args[1]));
	GB_ASSERT(ce->args[2]->tav.value.kind == ExactValue_String);
	array_add(&args, xb_objc_selector(p, ce->args[2]->tav.value.value_string));
	for (isize i = 3; i < ce->args.count; i++) {
		array_add(&args, xb_build_expr(p, ce->args[i]));
	}
	return xb_objc_msg_send(p, data, false, slice_from_array(args));
}

// A call of a method of an Objective-C class, sent as a message.
gb_internal xbValue xb_objc_auto_send(xbProc *p, Ast *expr, Slice<xbValue> arg_values) {
	ast_node(ce, CallExpr, expr);
	ObjcMsgData data = map_must_get(&p->m->info->objc_msgSend_types, expr);
	Entity *method = entity_of_node(ce->proc);
	GB_ASSERT(method != nullptr && method->kind == Entity_Procedure);

	Type *super_type = nullptr;
	if (ce->args.count > 0) {
		super_type = unparen_expr(ce->args[0])->tav.objc_super_target;
	}

	isize arg_offset = 1;
	xbValue id = {};
	if (!method->Procedure.is_objc_class_method) {
		id = arg_values[0];
		if (super_type != nullptr) {
			// objc_msgSendSuper2 looks the method up from the superclass of the class given
			GB_ASSERT(super_type->kind == Type_Named);
			u32 cls = xb_load(p, xbType_I64, xb_objc_class_mem(p, super_type->Named.type_name));
			xbMem sup = xb_add_local(p, t_objc_super, false);
			xb_store(p, xbType_I64, sup, xb_value_to_reg(p, xb_emit_conv(p, id, t_objc_id)));
			xb_store(p, xbType_I64, xb_mem_offset(sup, 8), cls);
			id = xb_value_reg(t_objc_super_ptr, xb_lea(p, sup));
		}
	} else {
		Entity *cls = method->Procedure.objc_class;
		if (ce->proc->kind == Ast_SelectorExpr) {
			// `Foo.alloc()` sends to Foo, even when the method is declared by a superclass
			ast_node(se, SelectorExpr, ce->proc);
			cls = entity_from_expr(se->expr);
			if (cls->TypeName.is_type_alias) {
				cls = cls->type->Named.type_name;
			}
		}
		id = xb_value_reg(t_objc_Class, xb_load(p, xbType_I64, xb_objc_class_mem(p, cls)));
		arg_offset = 0;
	}

	auto args = array_make<xbValue>(xb_allocator(), 0, arg_values.count + 2);
	array_add(&args, id);
	array_add(&args, xb_objc_selector(p, method->Procedure.objc_selector_name));
	for (isize i = arg_offset; i < arg_values.count; i++) {
		array_add(&args, arg_values[i]);
	}
	return xb_objc_msg_send(p, data, super_type != nullptr, slice_from_array(args));
}

////////////////////////////////////////////////////////////////
// Generated procedures
////////////////////////////////////////////////////////////////

// The value of parameter `index` of a generated procedure.
gb_internal xbValue xb_objc_param(xbProc *p, isize index) {
	Entity *e = base_type(p->type)->Proc.params->Tuple.variables[index];
	xbVar *v = map_get(&p->vars, e);
	GB_ASSERT(v != nullptr);
	xbMem m = v->indirect ? xb_mem(xbMem_Reg, xb_load(p, xbType_I64, v->mem), 0) : v->mem;
	return xb_load_value(p, e->type, m);
}

gb_internal void xb_objc_return(xbProc *p, xbValue result) {
	if (base_type(p->type)->Proc.result_count == 0) return;
	auto results = array_make<xbValue>(xb_allocator(), 1, 1);
	results[0] = result;
	xb_return_with_results(p, results, false, {});
}

// Builds a procedure of type `pt` into the family, local to the object. Bails out of
// `caller`, or returns false without one, if it cannot be built.
template <typename F>
gb_internal i32 xb_objc_build_proc(xbModule *m, xbFamily *family, xbProc *caller, String name, Type *pt, F const &body) {
	name = copy_string(permanent_allocator(), name);
	xbProc *p = xb_new_proc(m, name, pt);
	p->family = family;
	jmp_buf bail;
	p->bail = &bail;
	if (setjmp(bail) != 0) {
		if (caller != nullptr) XB_UNSUPPORTED(caller, p->fail_reason);
		return -1;
	}
	p->abi = xb_get_abi(p, pt);
	p->sym = xb_symbol(m, name);
	m->symbols[p->sym].flags = xbSymbolFlag_Func;
	xb_begin_proc(p);
	body(p);
	xb_end_proc(p);
	array_add(&family->procs, p);
	return p->sym;
}

////////////////////////////////////////////////////////////////
// Blocks
////////////////////////////////////////////////////////////////

// https://clang.llvm.org/docs/Block-ABI-Apple.html
enum : i32 {
	XB_BLOCK_FIELD_IS_OBJECT = 3,
	XB_BLOCK_FIELD_IS_BLOCK  = 7,
	XB_BLOCK_HAS_COPY_DISPOSE = 1<<25,
	XB_BLOCK_IS_GLOBAL        = 1<<28,
};

gb_internal bool xb_objc_is_block_type(Type *type, Type *block_base) {
	Type *base = base_type(type_deref(type));
	GB_ASSERT(base->kind == Type_Struct);
	while (is_type_polymorphic_record_specialized(base)) {
		if (base->Struct.polymorphic_parent) {
			base = base->Struct.polymorphic_parent;
			if (base == block_base) return true;
			base = base_type(base);
			GB_ASSERT(base->kind == Type_Struct);
		}
	}
	return false;
}

gb_internal xbValue xb_build_objc_block(xbProc *p, Ast *expr) {
	ast_node(ce, CallExpr, expr);
	xbModule *m = p->m;
	if (p->family == nullptr) XB_UNSUPPORTED(p, "objc block outside a family");
	isize capture_count = ce->args.count - 1;
	Ast *handler = ce->args[capture_count];
	Type *handler_type = base_type(type_of_expr(handler));
	GB_ASSERT(handler_type->kind == Type_Proc);
	TypeProc *hp = &handler_type->Proc;
	bool odin_cc = hp->calling_convention == ProcCC_Odin;
	bool is_global = capture_count == 0 && !odin_cc;
	isize forward_count = hp->param_count - capture_count;

	auto captures = array_make<xbValue>(xb_allocator(), capture_count, capture_count);
	auto is_object = array_make<bool>(xb_allocator(), capture_count, capture_count);
	bool has_objects = false;
	for (isize i = 0; i < capture_count; i++) {
		xbValue v = xb_build_expr(p, ce->args[i]);
		is_object[i] = is_type_pointer(v.type) && is_type_objc_object(v.type);
		has_objects |= is_object[i];
		captures[i] = xb_emit_conv(p, v, hp->params->Tuple.variables[forward_count+i]->type);
	}

	// The literal is laid out like LLVM's: isa, flags, reserved, invoke, then room for the
	// descriptor struct, whose address is stored at its start, then the context and captures.
	i64 desc_size = has_objects ? 32 : 16;
	i64 off = 24 + desc_size;
	i64 align = 8;
	i64 context_off = -1;
	if (odin_cc) {
		context_off = align_formula(off, type_align_of(t_context));
		off = context_off + type_size_of(t_context);
		align = gb_max(align, type_align_of(t_context));
	}
	auto capture_off = array_make<i64>(xb_allocator(), capture_count, capture_count);
	for (isize i = 0; i < capture_count; i++) {
		Type *t = captures[i].type;
		capture_off[i] = align_formula(off, type_align_of(t));
		off = capture_off[i] + type_size_of(t);
		align = gb_max(align, type_align_of(t));
	}
	i64 lit_size = align_formula(off, align);

	i32 id = m->objc_block_count++;
	char name[64] = {};

	// invoke(block, forwarded params...): calls the handler with the captures behind them
	auto invoker_params = array_make<Type *>(xb_allocator(), 0, forward_count+1);
	array_add(&invoker_params, t_rawptr);
	for (isize i = 0; i < forward_count; i++) {
		array_add(&invoker_params, hp->params->Tuple.variables[i]->type);
	}
	Type *result = hp->result_count > 0 ? hp->results->Tuple.variables[0]->type : nullptr;
	Type *invoker_type = alloc_type_proc_from_types(invoker_params.data, cast(unsigned)invoker_params.count, result, false, ProcCC_CDecl);
	gb_snprintf(name, gb_size_of(name), "__$xb_objc_block_invoker_%d", id);
	i32 invoker = xb_objc_build_proc(m, p->family, p, make_string_c(name), invoker_type, [&](xbProc *q) {
		auto args = array_make<xbValue>(xb_allocator(), 0, hp->param_count);
		for (isize i = 0; i < forward_count; i++) {
			array_add(&args, xb_objc_param(q, i+1));
		}
		u32 lit = xb_value_to_reg(q, xb_objc_param(q, 0));
		for (isize i = 0; i < capture_count; i++) {
			array_add(&args, xb_load_value(q, captures[i].type, xb_mem(xbMem_Reg, lit, cast(i32)capture_off[i])));
		}
		if (odin_cc) {
			xbMem ctx = xb_add_local(q, t_rawptr, false);
			xb_store(q, xbType_I64, ctx, xb_ptr_add_const(q, lit, context_off));
			xb_push_context(q, ctx, true);
		}
		xbValue f = xb_build_expr(q, handler);
		xb_objc_return(q, xb_emit_call(q, f, slice_from_array(args), nullptr));
	});

	i32 copy_helper = -1;
	i32 dispose_helper = -1;
	if (has_objects) {
		Type *block_base = find_core_type(m->info->checker, str_lit("Objc_Block"));
		Type *types[3] = {t_rawptr, t_rawptr, t_i32};
		gb_snprintf(name, gb_size_of(name), "__$xb_objc_block_copy_helper_%d", id);
		copy_helper = xb_objc_build_proc(m, p->family, p, make_string_c(name), alloc_type_proc_from_types(types, 3, nullptr, false, ProcCC_CDecl), [&](xbProc *q) {
			for (isize i = 0; i < capture_count; i++) {
				if (!is_object[i]) continue;
				i32 flag = xb_objc_is_block_type(captures[i].type, block_base) ? XB_BLOCK_FIELD_IS_BLOCK : XB_BLOCK_FIELD_IS_OBJECT;
				u32 dst = xb_value_to_reg(q, xb_objc_param(q, 0));
				u32 src = xb_value_to_reg(q, xb_objc_param(q, 1));
				xbValue args[3] = {
					xb_value_reg(t_rawptr, xb_ptr_add_const(q, dst, capture_off[i])),
					xb_value_reg(t_rawptr, xb_load(q, xbType_I64, xb_mem(xbMem_Reg, src, cast(i32)capture_off[i]))),
					xb_const_int(q, t_i32, flag),
				};
				xb_emit_runtime_call(q, "_Block_object_assign", xb_args(args, 3));
			}
		});
		gb_snprintf(name, gb_size_of(name), "__$xb_objc_block_dispose_helper_%d", id);
		dispose_helper = xb_objc_build_proc(m, p->family, p, make_string_c(name), alloc_type_proc_from_types(types+1, 2, nullptr, false, ProcCC_CDecl), [&](xbProc *q) {
			for (isize i = 0; i < capture_count; i++) {
				if (!is_object[i]) continue;
				i32 flag = xb_objc_is_block_type(captures[i].type, block_base) ? XB_BLOCK_FIELD_IS_BLOCK : XB_BLOCK_FIELD_IS_OBJECT;
				u32 src = xb_value_to_reg(q, xb_objc_param(q, 0));
				xbValue args[2] = {
					xb_value_reg(t_rawptr, xb_load(q, xbType_I64, xb_mem(xbMem_Reg, src, cast(i32)capture_off[i]))),
					xb_const_int(q, t_i32, flag),
				};
				xb_emit_runtime_call(q, "_Block_object_dispose", xb_args(args, 2));
			}
		});
	}

	// The descriptor and a global literal are static. They are filled in where the block is
	// made, with the same values every time, so nothing in the data refers to the helpers,
	// which are left out with the procedure if it goes to LLVM.
	xbMem desc = xb_static_storage(p, alloc_type_array(t_u8, desc_size));
	xb_store(p, xbType_I64, desc, xb_iconst(p, xbType_I64, 0));
	xb_store(p, xbType_I64, xb_mem_offset(desc, 8), xb_iconst(p, xbType_I64, lit_size));
	if (has_objects) {
		xb_store(p, xbType_I64, xb_mem_offset(desc, 16), xb_lea(p, xb_mem(xbMem_Sym, cast(u32)copy_helper)));
		xb_store(p, xbType_I64, xb_mem_offset(desc, 24), xb_lea(p, xb_mem(xbMem_Sym, cast(u32)dispose_helper)));
	}

	xbMem lit = {};
	if (is_global) {
		lit = xb_static_storage(p, alloc_type_array(t_u8, lit_size));
	} else {
		lit = xb_mem(xbMem_Local, cast(u32)xb_add_local_raw(p, lit_size, align));
	}
	Entity *isa = xb_lookup_runtime_entity(m, is_global ? "_NSConcreteGlobalBlock" : "_NSConcreteStackBlock");
	i32 flags = (is_global ? XB_BLOCK_IS_GLOBAL : 0) | (has_objects ? XB_BLOCK_HAS_COPY_DISPOSE : 0);
	xb_store(p, xbType_I64, lit, xb_lea(p, xb_global_mem(p, isa)));
	xb_store(p, xbType_I32, xb_mem_offset(lit, 8), xb_iconst(p, xbType_I32, flags));
	xb_store(p, xbType_I32, xb_mem_offset(lit, 12), xb_iconst(p, xbType_I32, 0));
	xb_store(p, xbType_I64, xb_mem_offset(lit, 16), xb_lea(p, xb_mem(xbMem_Sym, cast(u32)invoker)));
	xb_store(p, xbType_I64, xb_mem_offset(lit, 24), xb_lea(p, desc));
	if (odin_cc) {
		xb_memcopy(p, xb_mem_offset(lit, context_off), xb_context_mem(p), type_size_of(t_context));
	}
	for (isize i = 0; i < capture_count; i++) {
		xb_store_value(p, xb_mem_offset(lit, capture_off[i]), captures[i]);
	}
	return xb_value_reg(type_of_expr(expr), xb_lea(p, lit));
}

////////////////////////////////////////////////////////////////
// Builtins
////////////////////////////////////////////////////////////////

gb_internal xbValue xb_build_objc_builtin(xbProc *p, Ast *expr, BuiltinProcId id) {
	ast_node(ce, CallExpr, expr);
	switch (id) {
	case BuiltinProc_objc_send:
		return xb_build_objc_send(p, expr);
	case BuiltinProc_objc_find_selector:
		return xb_objc_selector(p, ce->args[0]->tav.value.value_string);
	case BuiltinProc_objc_find_class: {
		String name = ce->args[0]->tav.value.value_string;
		xbMem g = xb_mem(xbMem_Sym, cast(u32)xb_objc_find(p->m, xbObjc_Class, name));
		return xb_value_reg(t_objc_Class, xb_load(p, xbType_I64, g));
	}
	case BuiltinProc_objc_register_selector: {
		String name = ce->args[0]->tav.value.value_string;
		xbValue args[1] = {xb_const_value(p, t_cstring, exact_value_string(name))};
		xbValue sel = xb_emit_runtime_call(p, "sel_registerName", xb_args(args, 1));
		xbMem g = xb_objc_selector_mem(p, name);
		xb_store(p, xbType_I64, g, xb_value_to_reg(p, sel));
		return xb_value_reg(t_objc_SEL, xb_load(p, xbType_I64, g));
	}
	case BuiltinProc_objc_register_class: {
		// LLVM's passes a nil Class as the name, which it cannot convert; this passes the name
		String name = ce->args[0]->tav.value.value_string;
		xbValue args[3] = {
			xb_zero_value(p, t_objc_Class),
			xb_const_value(p, t_cstring, exact_value_string(name)),
			xb_const_int(p, t_uint, 0),
		};
		xbValue cls = xb_emit_runtime_call(p, "objc_allocateClassPair", xb_args(args, 3));
		xbMem g = xb_mem(xbMem_Sym, cast(u32)xb_objc_find(p->m, xbObjc_Class, name));
		xb_store(p, xbType_I64, g, xb_value_to_reg(p, cls));
		return xb_value_reg(t_objc_Class, xb_load(p, xbType_I64, g));
	}
	case BuiltinProc_objc_ivar_get:
		return xb_emit_conv(p, xb_objc_ivar_ptr(p, xb_build_expr(p, ce->args[0])), type_of_expr(expr));
	case BuiltinProc_objc_block:
		return xb_build_objc_block(p, expr);
	case BuiltinProc_objc_super:
		// only marks the receiver of a message, see xb_objc_auto_send
		return xb_build_expr(p, ce->args[0]);
	}
	GB_PANIC("unhandled objc builtin");
	return {};
}

////////////////////////////////////////////////////////////////
// Setup
////////////////////////////////////////////////////////////////

gb_internal GB_COMPARE_PROC(xb_objc_global_cmp) {
	xbObjcGlobal const *x = cast(xbObjcGlobal const *)a;
	xbObjcGlobal const *y = cast(xbObjcGlobal const *)b;
	return string_compare(x->name, y->name);
}

gb_internal GB_COMPARE_PROC(xb_objc_method_cmp) {
	ObjcMethodData const *x = cast(ObjcMethodData const *)a;
	ObjcMethodData const *y = cast(ObjcMethodData const *)b;
	return entity_source_order_cmp(x->proc_entity, y->proc_entity);
}

gb_internal GB_COMPARE_PROC(init_procedures_cmp);

// A method's implementation as the runtime calls it: (self, _cmd, params...) with the C
// convention, a context from the class's context provider for an Odin method.
gb_internal i32 xb_objc_method_wrapper(xbModule *m, xbFamily *family, Type *class_type, ObjcMethodData const &md) {
	Entity *tn = class_type->Named.type_name;
	Type *method_type = md.proc_entity->type;
	bool class_method = md.ac.objc_is_class_method;
	isize param_count = method_type->Proc.param_count;
	isize param_offset = 0;
	if (!class_method) {
		param_count -= 1;
		param_offset = 1;
	}
	auto params = array_make<Type *>(xb_allocator(), 0, param_count+2);
	array_add(&params, class_method ? t_objc_Class : alloc_type_pointer(class_type));
	array_add(&params, t_objc_SEL);
	for (isize i = 0; i < param_count; i++) {
		array_add(&params, method_type->Proc.params->Tuple.variables[param_offset+i]->type);
	}
	Type *result = method_type->Proc.result_count > 0 ? method_type->Proc.results->Tuple.variables[0]->type : nullptr;
	Type *pt = alloc_type_proc_from_types(params.data, cast(unsigned)params.count, result, false, ProcCC_CDecl);

	gbString s = gb_string_make(heap_allocator(), "__$objc_method::");
	s = gb_string_append_length(s, tn->TypeName.objc_class_name.text, tn->TypeName.objc_class_name.len);
	s = gb_string_appendc(s, "::");
	s = gb_string_append_length(s, md.ac.objc_name.text, md.ac.objc_name.len);
	String name = make_string(cast(u8 *)s, gb_string_length(s));
	defer (gb_string_free(s));

	return xb_objc_build_proc(m, family, nullptr, name, pt, [&](xbProc *q) {
		auto args = array_make<xbValue>(xb_allocator(), 0, param_count+1);
		if (!class_method) {
			array_add(&args, xb_emit_conv(q, xb_objc_param(q, 0), method_type->Proc.params->Tuple.variables[0]->type));
		}
		for (isize i = 0; i < param_count; i++) {
			array_add(&args, xb_objc_param(q, i+2));
		}
		if (method_type->Proc.calling_convention == ProcCC_Odin) {
			Entity *provider = tn->TypeName.objc_context_provider;
			GB_ASSERT(provider != nullptr);
			Type *self_ptr_type = base_type(provider->type->Proc.params->Tuple.variables[0]->type);
			Type *self_named = base_named_type(type_deref(self_ptr_type));
			Type *ivar_type = tn->TypeName.objc_ivar;
			xbValue self = xb_objc_param(q, 0);
			if (ivar_type != nullptr && internal_check_is_assignable_to(self_named, ivar_type)) {
				// the provider takes the ivar
				self = xb_objc_ivar_ptr(q, xb_value_reg(alloc_type_pointer(class_type), xb_value_to_reg(q, self)));
			}
			xbValue pargs[1] = {xb_emit_conv(q, self, self_ptr_type)};
			xbValue ctx = xb_emit_call(q, xb_proc_value_from_entity(q, provider), xb_args(pargs, 1), nullptr);
			xb_push_context(q, xb_address_from_load_or_generate_local(q, ctx), false);
		}
		xbValue f = xb_proc_value_from_entity(q, md.proc_entity);
		xb_objc_return(q, xb_emit_call(q, f, slice_from_array(args), nullptr));
	});
}

struct xbObjcSetup {
	xbModule *         m;
	Array<xbObjcGlobal> impls;     // in registration order, superclasses first
	StringSet          handled;
	PtrMap<Type *, Array<i32>> wrappers; // per class, per method
};

gb_internal void xb_objc_setup_destroy(xbObjcSetup *s) {
	array_free(&s->impls);
	string_set_destroy(&s->handled);
	for (auto &entry : s->wrappers) {
		array_free(&entry.value);
	}
	map_destroy(&s->wrappers);
}

gb_internal void xb_objc_add_impl(xbObjcSetup *s, xbObjcGlobal const &g) {
	if (string_set_update(&s->handled, g.name)) return;
	Type *super = g.class_type->Named.type_name->TypeName.objc_superclass;
	if (super != nullptr) {
		i32 *found = string_map_get(&s->m->objc_global_map[xbObjc_Class], super->Named.type_name->TypeName.objc_class_name);
		GB_ASSERT(found != nullptr);
		xbObjcGlobal sg = s->m->objc_globals[xbObjc_Class][*found];
		if (sg.class_type != nullptr) xb_objc_add_impl(s, sg);
	}
	array_add(&s->impls, g);
}

gb_internal void xb_objc_setup_body(xbProc *p, xbObjcSetup *s) {
	xbModule *m = p->m;
	auto load = [&](i32 sym) { return xb_load(p, xbType_I64, xb_mem(xbMem_Sym, cast(u32)sym)); };
	auto cstr = [&](String str) { return xb_const_value(p, t_cstring, exact_value_string(str)); };

	for (xbObjcGlobal const &g : m->objc_globals[xbObjc_Class]) {
		if (g.class_type != nullptr) continue;
		xbValue args[1] = {cstr(g.name)};
		xb_store(p, xbType_I64, xb_mem(xbMem_Sym, cast(u32)g.sym), xb_value_to_reg(p, xb_emit_runtime_call(p, "objc_lookUpClass", xb_args(args, 1))));
	}
	for (xbObjcGlobal const &g : m->objc_globals[xbObjc_Selector]) {
		xbValue args[1] = {cstr(g.name)};
		xb_store(p, xbType_I64, xb_mem(xbMem_Sym, cast(u32)g.sym), xb_value_to_reg(p, xb_emit_runtime_call(p, "sel_registerName", xb_args(args, 1))));
	}

	for (xbObjcGlobal const &g : s->impls) {
		Type *class_type = g.class_type;
		Entity *tn = class_type->Named.type_name;
		xbValue super = xb_zero_value(p, t_objc_Class);
		if (Type *st = tn->TypeName.objc_superclass) {
			i32 *found = string_map_get(&m->objc_global_map[xbObjc_Class], st->Named.type_name->TypeName.objc_class_name);
			super = xb_value_reg(t_objc_Class, load(m->objc_globals[xbObjc_Class][*found].sym));
		}
		xbValue args[5] = {super, cstr(g.name), xb_const_int(p, t_uint, 0)};
		u32 cls = xb_value_to_reg(p, xb_emit_runtime_call(p, "objc_allocateClassPair", xb_args(args, 3)));
		xb_store(p, xbType_I64, xb_mem(xbMem_Sym, cast(u32)g.sym), cls);

		Type *ivar_type = tn->TypeName.objc_ivar;
		Array<ObjcMethodData> *methods = map_get(&m->info->objc_method_implementations, class_type);
		if (methods == nullptr) {
			continue;
		}
		Array<i32> *wrappers = map_get(&s->wrappers, class_type);
		u32 meta = 0;
		for (ObjcMethodData const &md : *methods) {
			if (!md.ac.objc_is_class_method) continue;
			xbValue margs[1] = {xb_value_reg(t_objc_Class, load(g.sym))};
			meta = xb_value_to_reg(p, xb_emit_runtime_call(p, "object_getClass", xb_args(margs, 1)));
			break;
		}
		for_array(i, *methods) {
			ObjcMethodData const &md = (*methods)[i];
			Type *method_type = md.proc_entity->type;
			String encoding = str_lit("v");
			if (method_type->Proc.result_count != 0) {
				encoding = lb_get_objc_type_encoding(method_type->Proc.results->Tuple.variables[0]->type, 0);
			}
			encoding = concatenate_strings(temporary_allocator(), encoding, md.ac.objc_is_class_method ? str_lit("#:") : str_lit("@:"));
			isize offset = md.ac.objc_is_class_method ? 0 : 1;
			for (isize k = offset; k < method_type->Proc.param_count; k++) {
				Type *pt = method_type->Proc.params->Tuple.variables[k]->type;
				encoding = concatenate_strings(temporary_allocator(), encoding, lb_get_objc_type_encoding(pt, 0));
			}
			Entity *imp_type = xb_lookup_runtime_entity(m, "objc_IMP");
			xbValue cargs[4] = {
				xb_value_reg(t_objc_Class, md.ac.objc_is_class_method ? meta : load(g.sym)),
				xb_objc_selector(p, md.ac.objc_selector),
				xb_value_reg(imp_type->type, xb_lea(p, xb_mem(xbMem_Sym, cast(u32)(*wrappers)[i]))),
				cstr(encoding),
			};
			xb_emit_runtime_call(p, "class_addMethod", xb_args(cargs, 4));
		}
		if (ivar_type != nullptr) {
			// one ivar of the whole type, without a type encoding to keep it private
			Type *base = ivar_type->Named.base;
			xbValue iargs[5] = {
				xb_value_reg(t_objc_Class, load(g.sym)),
				cstr(str_lit("__$ivar")),
				xb_const_int(p, t_uint, type_size_of(base)),
				xb_const_int(p, t_u8, cast(i64)floor_log2(cast(u64)type_align_of(base))),
				cstr(str_lit("{= }")),
			};
			xb_emit_runtime_call(p, "class_addIvar", xb_args(iargs, 5));
		}
		xbValue rargs[1] = {xb_value_reg(t_objc_Class, load(g.sym))};
		xb_emit_runtime_call(p, "objc_registerClassPair", xb_args(rargs, 1));
	}

	for (xbObjcGlobal const &g : m->objc_globals[xbObjc_Ivar]) {
		Entity *tn = g.class_type->Named.type_name;
		i32 cls = xb_objc_find(m, xbObjc_Class, tn->TypeName.objc_class_name);
		xbValue args[2] = {xb_value_reg(t_objc_Class, load(cls)), cstr(str_lit("__$ivar"))};
		xbValue ivar = xb_emit_runtime_call(p, "class_getInstanceVariable", xb_args(args, 2));
		xbValue oargs[1] = {ivar};
		xbValue offset = xb_emit_runtime_call(p, "ivar_getOffset", xb_args(oargs, 1));
		xb_store(p, xbType_I64, xb_mem(xbMem_Sym, cast(u32)g.sym), xb_value_to_reg(p, xb_emit_conv(p, offset, t_int)));
	}
}

// __$init_objc_names, which the startup calls first: looks up the classes and selectors,
// registers the classes this program implements, and finds their ivars.
gb_internal bool xb_build_objc_names(xbModule *m, char const **reason) {
	CheckerInfo *info = m->info;
	TEMPORARY_ALLOCATOR_GUARD();

	// every implemented class is registered, referenced or not; the queue stays for LLVM
	auto implementations = array_make<Entity *>(heap_allocator(), 0, 16);
	defer (array_free(&implementations));
	for (Entity *e = {}; mpsc_dequeue(&info->objc_class_implementations, &e); /**/) {
		array_add(&implementations, e);
	}
	for (Entity *e : implementations) {
		mpsc_enqueue(&info->objc_class_implementations, e);
	}
	array_sort(implementations, init_procedures_cmp);
	for (Entity *e : implementations) {
		xb_objc_find(m, xbObjc_Class, e->TypeName.objc_class_name, e->type);
	}
	// an implemented class registers after its superclass, which needs a global too
	for (isize i = 0; i < m->objc_globals[xbObjc_Class].count; i++) {
		Type *t = m->objc_globals[xbObjc_Class][i].class_type;
		if (t == nullptr) continue;
		Type *super = t->Named.type_name->TypeName.objc_superclass;
		if (super == nullptr) continue;
		Entity *stn = super->Named.type_name;
		xb_objc_find(m, xbObjc_Class, stn->TypeName.objc_class_name, stn->TypeName.objc_is_implementation ? super : nullptr);
	}
	for (xbObjcGlobal const &g : m->objc_globals[xbObjc_Class]) {
		if (g.class_type == nullptr) continue;
		Array<ObjcMethodData> *methods = map_get(&info->objc_method_implementations, g.class_type);
		if (methods == nullptr) continue;
		array_sort(*methods, xb_objc_method_cmp);
		for (ObjcMethodData const &md : *methods) {
			xb_objc_find(m, xbObjc_Selector, md.ac.objc_selector);
		}
	}

	xbFamily family = {};
	xb_family_init(&family, nullptr);
	defer (xb_family_destroy(&family));

	xbObjcSetup s = {};
	s.m = m;
	s.impls = array_make<xbObjcGlobal>(heap_allocator(), 0, 8);
	string_set_init(&s.handled);
	map_init(&s.wrappers);
	defer (xb_objc_setup_destroy(&s));

	// the method wrappers first, they may ask for ivar offsets
	for (xbObjcGlobal const &g : m->objc_globals[xbObjc_Class]) {
		if (g.class_type == nullptr) continue;
		Array<ObjcMethodData> *methods = map_get(&info->objc_method_implementations, g.class_type);
		if (methods == nullptr) continue;
		auto wrappers = array_make<i32>(heap_allocator(), 0, methods->count);
		for (ObjcMethodData const &md : *methods) {
			i32 sym = xb_objc_method_wrapper(m, &family, g.class_type, md);
			if (sym < 0) {
				*reason = "objc method wrapper";
				array_free(&wrappers);
				return false;
			}
			array_add(&wrappers, sym);
		}
		map_set(&s.wrappers, g.class_type, wrappers);
	}

	for (Array<xbObjcGlobal> &list : m->objc_globals) {
		array_sort(list, xb_objc_global_cmp);
	}
	for (isize k = 0; k < xbObjc_COUNT; k++) {
		for_array(i, m->objc_globals[k]) {
			string_map_set(&m->objc_global_map[k], m->objc_globals[k][i].name, cast(i32)i);
		}
	}
	for (xbObjcGlobal const &g : m->objc_globals[xbObjc_Class]) {
		if (g.class_type != nullptr) xb_objc_add_impl(&s, g);
	}

	Type *pt = alloc_type_proc(nullptr, nullptr, 0, nullptr, 0, false, ProcCC_CDecl);
	i32 sym = xb_objc_build_proc(m, &family, nullptr, str_lit("__$init_objc_names"), pt, [&](xbProc *p) {
		p->is_startup = true;
		xb_objc_setup_body(p, &s);
	});
	if (sym < 0 || !xb_family_build(m, &family, nullptr, reason)) {
		if (*reason == nullptr) *reason = "objc setup";
		return false;
	}
	// hidden, so a shared library calls its own
	m->symbols[sym].flags = xbSymbolFlag_Global | xbSymbolFlag_Func | xbSymbolFlag_Weak | xbSymbolFlag_Hidden;
	xb_family_lower(m, &family, nullptr);

	for (Array<xbObjcGlobal> const &list : m->objc_globals) {
		for (xbObjcGlobal const &g : list) {
			xbSymbol *gs = &m->symbols[g.sym];
			gs->section = xbSection_Bss;
			gs->offset = xb_section_reserve(m, xbSection_Bss, 8, 8);
			gs->size = 8;
			gs->flags = xbSymbolFlag_Global | xbSymbolFlag_Hidden;
		}
	}
	return true;
}

// When LLVM makes the setup, the names this backend's code uses go to it, and it defines
// their globals.
gb_internal void xb_objc_hand_over(xbModule *m) {
	lbProcedure p = {};
	p.module = &m->gen->default_module;
	for (xbObjcGlobal const &g : m->objc_globals[xbObjc_Selector]) {
		lb_handle_objc_find_or_register_selector(&p, g.name);
	}
	for (xbObjcGlobal const &g : m->objc_globals[xbObjc_Class]) {
		lb_handle_objc_find_or_register_class(&p, g.name, g.class_type);
	}
	for (xbObjcGlobal const &g : m->objc_globals[xbObjc_Ivar]) {
		lb_handle_objc_find_or_register_ivar(p.module, g.class_type);
	}
}
