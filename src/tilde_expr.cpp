gb_internal cgContextData *cg_push_context_onto_stack(cgProcedure *p, cgAddr ctx) {
	ctx.kind = cgAddr_Context;
	cgContextData *cd = array_add_and_get(&p->context_stack);
	cd->ctx = ctx;
	cd->scope_index = p->scope_index;
	return cd;
}

gb_internal cgAddr cg_find_or_generate_context_ptr(cgProcedure *p) {
	if (p->context_stack.count > 0) {
		return p->context_stack[p->context_stack.count-1].ctx;
	}

	Type *pt = base_type(p->type);
	GB_ASSERT(pt->kind == Type_Proc);
	GB_ASSERT(pt->Proc.calling_convention != ProcCC_Odin);

	cgAddr c = cg_add_local(p, t_context, nullptr, true);
	tb_node_append_attrib(c.addr.node, tb_function_attrib_variable(p->func, -1, "context", cg_debug_type(p->module, t_context)));
	c.kind = cgAddr_Context;
	// lb_emit_init_context(p, c);
	cg_push_context_onto_stack(p, c);
	// lb_add_debug_context_variable(p, c);

	return c;
}

gb_internal cgValue cg_find_value_from_entity(cgModule *m, Entity *e) {
	e = strip_entity_wrapping(e);
	GB_ASSERT(e != nullptr);

	GB_ASSERT(e->token.string != "_");

	if (e->kind == Entity_Procedure) {
		return cg_find_procedure_value_from_entity(m, e);
	}

	cgValue *found = nullptr;
	rw_mutex_shared_lock(&m->values_mutex);
	found = map_get(&m->values, e);
	rw_mutex_shared_unlock(&m->values_mutex);
	if (found) {
		return *found;
	}

	// GB_PANIC("\n\tError in: %s, missing value '%.*s'\n", token_pos_to_string(e->token.pos), LIT(e->token.string));
	return {};
}

gb_internal cgAddr cg_build_addr_from_entity(cgProcedure *p, Entity *e, Ast *expr) {
	GB_ASSERT(e != nullptr);
	if (e->kind == Entity_Constant) {
		Type *t = default_type(type_of_expr(expr));
		cgValue v = cg_const_value(p, t, e->Constant.value);
		GB_PANIC("TODO(bill): cg_add_global_generated");
		// return cg_add_global_generated(p->module, t, v);
		return {};
	}


	cgValue v = {};

	cgModule *m = p->module;

	rw_mutex_lock(&m->values_mutex);
	cgValue *found = map_get(&m->values, e);
	rw_mutex_unlock(&m->values_mutex);
	if (found) {
		v = *found;
	} else if (e->kind == Entity_Variable && e->flags & EntityFlag_Using) {
		GB_PANIC("TODO(bill): cg_get_using_variable");
		// NOTE(bill): Calculate the using variable every time
		// v = cg_get_using_variable(p, e);
	} else if (e->flags & EntityFlag_SoaPtrField) {
		GB_PANIC("TODO(bill): cg_get_soa_variable_addr");
		// return cg_get_soa_variable_addr(p, e);
	}


	if (v.node == nullptr) {
		return cg_addr(cg_find_value_from_entity(m, e));
	}

	return cg_addr(v);
}

gb_internal cgValue cg_typeid(cgModule *m, Type *t) {
	GB_ASSERT("TODO(bill): cg_typeid");
	return {};
}


gb_internal cgValue cg_emit_conv(cgProcedure *p, cgValue value, Type *type) {
	// TODO(bill): cg_emit_conv
	return value;
}

gb_internal cgValue cg_emit_transmute(cgProcedure *p, cgValue value, Type *type) {
	GB_ASSERT(type_size_of(value.type) == type_size_of(type));

	if (value.kind == cgValue_Symbol) {
		GB_ASSERT(is_type_pointer(value.type));
		value = cg_value(tb_inst_get_symbol_address(p->func, value.symbol), type);
	}

	i64 src_align = type_align_of(value.type);
	i64 dst_align = type_align_of(type);

	if (dst_align > src_align) {
		cgAddr local = cg_add_local(p, type, nullptr, false);
		cgValue dst = local.addr;
		dst.type = alloc_type_pointer(value.type);
		cg_emit_store(p, dst, value);
		return cg_addr_load(p, local);
	}

	TB_DataType dt = cg_data_type(type);
	switch (value.kind) {
	case cgValue_Value:
		GB_ASSERT(!TB_IS_VOID_TYPE(dt));
		value.type = type;
		value.node = tb_inst_bitcast(p->func, value.node, dt);
		return value;
	case cgValue_Addr:
		value.type = type;
		return value;
	case cgValue_Symbol:
		GB_PANIC("should be handled above");
		break;
	}
	return value;

}



gb_internal cgValue cg_build_expr_internal(cgProcedure *p, Ast *expr);
gb_internal cgValue cg_build_expr(cgProcedure *p, Ast *expr) {
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
		// cgValue *pp = map_get(&p->selector_values, expr);
		// if (pp != nullptr) {
		// 	cgValue res = *pp;
		// 	map_remove(&p->selector_values, expr);
		// 	return res;
		// }
		// cgAddr *pa = map_get(&p->selector_addr, expr);
		// if (pa != nullptr) {
		// 	cgAddr res = *pa;
		// 	map_remove(&p->selector_addr, expr);
		// 	return cg_addr_load(p, res);
		// }
	}

	cgValue res = cg_build_expr_internal(p, expr);
	if (res.kind == cgValue_Symbol) {
		GB_ASSERT(is_type_internally_pointer_like(res.type));
		res = cg_value(tb_inst_get_symbol_address(p->func, res.symbol), res.type);
	}

	if (expr->state_flags & StateFlag_SelectorCallExpr) {
		// map_set(&p->selector_values, expr, res);
	}
	return res;
}



gb_internal cgValue cg_build_expr_internal(cgProcedure *p, Ast *expr) {
	cgModule *m = p->module;

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
		return cg_const_value(p, type, tv.value);
	} else if (tv.mode == Addressing_Type) {
		// NOTE(bill, 2023-01-16): is this correct? I hope so at least
		return cg_typeid(m, tv.type);
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
			GB_PANIC("TODO: cg_find_ident nil");
			// TODO(bill): is this correct?
			return cg_value(cast(TB_Node *)nullptr, e->type);
		}
		GB_ASSERT(e->kind != Entity_ProcGroup);
		// return cg_find_ident(p, m, e, expr);
		GB_PANIC("TODO: cg_find_ident");
		return {};
	case_end;

	case_ast_node(i, Implicit, expr);
		return cg_addr_load(p, cg_build_addr(p, expr));
	case_end;

	case_ast_node(u, Uninit, expr);
		if (is_type_untyped(type)) {
			return cg_value(cast(TB_Node *)nullptr, t_untyped_uninit);
		}
		return cg_value(tb_inst_poison(p->func), type);
	case_end;

	case_ast_node(de, DerefExpr, expr);
		return cg_addr_load(p, cg_build_addr(p, expr));
	case_end;


	case_ast_node(se, SelectorExpr, expr);
		TypeAndValue tav = type_and_value_of_expr(expr);
		GB_ASSERT(tav.mode != Addressing_Invalid);
		return cg_addr_load(p, cg_build_addr(p, expr));
	case_end;

	case_ast_node(ise, ImplicitSelectorExpr, expr);
		TypeAndValue tav = type_and_value_of_expr(expr);
		GB_ASSERT(tav.mode == Addressing_Constant);

		return cg_const_value(p, type, tv.value);
	case_end;


	case_ast_node(se, SelectorCallExpr, expr);
		GB_ASSERT(se->modified_call);
		return cg_build_call_expr(p, se->call);
	case_end;

	case_ast_node(i, CallExpr, expr);
		return cg_build_call_expr(p, expr);
	case_end;


	case_ast_node(te, TernaryIfExpr, expr);
		GB_PANIC("TODO(bill): TernaryIfExpr");
	case_end;

	case_ast_node(te, TernaryWhenExpr, expr);
		TypeAndValue tav = type_and_value_of_expr(te->cond);
		GB_ASSERT(tav.mode == Addressing_Constant);
		GB_ASSERT(tav.value.kind == ExactValue_Bool);
		if (tav.value.value_bool) {
			return cg_build_expr(p, te->x);
		} else {
			return cg_build_expr(p, te->y);
		}
	case_end;

	case_ast_node(tc, TypeCast, expr);
		cgValue e = cg_build_expr(p, tc->expr);
		switch (tc->token.kind) {
		case Token_cast:
			return cg_emit_conv(p, e, type);
		case Token_transmute:
			return cg_emit_transmute(p, e, type);
		}
		GB_PANIC("Invalid AST TypeCast");
	case_end;

	case_ast_node(ac, AutoCast, expr);
		cgValue value = cg_build_expr(p, ac->expr);
		return cg_emit_conv(p, value, type);
	case_end;
	}
	GB_PANIC("TODO(bill): cg_build_expr_internal %.*s", LIT(ast_strings[expr->kind]));
	return {};

}


gb_internal cgAddr cg_build_addr_internal(cgProcedure *p, Ast *expr);
gb_internal cgAddr cg_build_addr(cgProcedure *p, Ast *expr) {
	expr = unparen_expr(expr);

	// IMPORTANT NOTE(bill):
	// Selector Call Expressions (foo->bar(...))
	// must only evaluate `foo` once as it gets transformed into
	// `foo.bar(foo, ...)`
	// And if `foo` is a procedure call or something more complex, storing the value
	// once is a very good idea
	// If a stored value is found, it must be removed from the cache
	if (expr->state_flags & StateFlag_SelectorCallExpr) {
		// lbAddr *pp = map_get(&p->selector_addr, expr);
		// if (pp != nullptr) {
		// 	lbAddr res = *pp;
		// 	map_remove(&p->selector_addr, expr);
		// 	return res;
		// }
	}
	cgAddr addr = cg_build_addr_internal(p, expr);
	if (expr->state_flags & StateFlag_SelectorCallExpr) {
		// map_set(&p->selector_addr, expr, addr);
	}
	return addr;
}


gb_internal cgAddr cg_build_addr_internal(cgProcedure *p, Ast *expr) {
	switch (expr->kind) {
	case_ast_node(i, Implicit, expr);
		cgAddr v = {};
		switch (i->kind) {
		case Token_context:
			v = cg_find_or_generate_context_ptr(p);
			break;
		}

		GB_ASSERT(v.addr.node != nullptr);
		return v;
	case_end;

	case_ast_node(i, Ident, expr);
		if (is_blank_ident(expr)) {
			cgAddr val = {};
			return val;
		}
		String name = i->token.string;
		Entity *e = entity_of_node(expr);
		return cg_build_addr_from_entity(p, e, expr);
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