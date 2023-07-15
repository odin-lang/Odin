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


gb_internal cgAddr cg_build_addr(cgProcedure *p, Ast *expr) {
	return {};
}
