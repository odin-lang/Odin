ssaValue *ssa_type_info       (ssaProcedure *proc, Type *type);
ssaValue *ssa_emit_conv       (ssaProcedure *proc, ssaValue *value, Type *t, b32 is_argument = false);
ssaValue *ssa_build_expr      (ssaProcedure *proc, AstNode *expr);
void      ssa_build_stmt      (ssaProcedure *proc, AstNode *node);
void      ssa_build_cond      (ssaProcedure *proc, AstNode *cond, ssaBlock *true_block, ssaBlock *false_block);
void      ssa_build_defer_stmt(ssaProcedure *proc, ssaDefer d);


ssaValue *ssa_emit(ssaProcedure *proc, ssaValue *instr) {
	GB_ASSERT(instr->kind == ssaValue_Instr);
	ssaBlock *b = proc->curr_block;
	instr->Instr.parent = b;
	if (b != NULL) {
		ssaInstr *i = ssa_get_last_instr(b);
		if (!ssa_is_instr_terminating(i)) {
			array_add(&b->instrs, instr);
		}
	}
	return instr;
}
ssaValue *ssa_emit_store(ssaProcedure *p, ssaValue *address, ssaValue *value) {
	return ssa_emit(p, ssa_make_instr_store(p, address, value));
}
ssaValue *ssa_emit_load(ssaProcedure *p, ssaValue *address) {
	return ssa_emit(p, ssa_make_instr_load(p, address));
}
ssaValue *ssa_emit_select(ssaProcedure *p, ssaValue *cond, ssaValue *t, ssaValue *f) {
	return ssa_emit(p, ssa_make_instr_select(p, cond, t, f));
}

ssaValue *ssa_emit_zero_init(ssaProcedure *p, ssaValue *address)  {
	return ssa_emit(p, ssa_make_instr_zero_init(p, address));
}

ssaValue *ssa_emit_comment(ssaProcedure *p, String text) {
	return ssa_emit(p, ssa_make_instr_comment(p, text));
}


ssaValue *ssa_add_local(ssaProcedure *proc, Entity *e, b32 zero_initialized = true) {
	ssaBlock *b = proc->decl_block; // all variables must be in the first block
	ssaValue *instr = ssa_make_instr_local(proc, e, zero_initialized);
	instr->Instr.parent = b;
	array_add(&b->instrs, instr);
	array_add(&b->locals, instr);

	// if (zero_initialized) {
		ssa_emit_zero_init(proc, instr);
	// }

	return instr;
}

ssaValue *ssa_add_local_for_identifier(ssaProcedure *proc, AstNode *name, b32 zero_initialized) {
	Entity **found = map_get(&proc->module->info->definitions, hash_pointer(name));
	if (found) {
		Entity *e = *found;
		ssa_emit_comment(proc, e->token.string);
		return ssa_add_local(proc, e, zero_initialized);
	}
	return NULL;
}

ssaValue *ssa_add_local_generated(ssaProcedure *proc, Type *type) {
	GB_ASSERT(type != NULL);

	Scope *scope = NULL;
	if (proc->curr_block) {
		scope = proc->curr_block->scope;
	}
	Entity *e = make_entity_variable(proc->module->allocator,
	                                 scope,
	                                 empty_token,
	                                 type);
	return ssa_add_local(proc, e, true);
}

ssaValue *ssa_add_param(ssaProcedure *proc, Entity *e) {
	ssaValue *v = ssa_make_value_param(proc->module->allocator, proc, e);
#if 1
	ssaValue *l = ssa_add_local(proc, e);
	ssa_emit_store(proc, l, v);
#else
	ssa_module_add_value(proc->module, e, v);
#endif
	return v;
}


ssaValue *ssa_emit_call(ssaProcedure *p, ssaValue *value, ssaValue **args, isize arg_count) {
	Type *pt = base_type(ssa_type(value));
	GB_ASSERT(pt->kind == Type_Proc);
	Type *results = pt->Proc.results;
	return ssa_emit(p, ssa_make_instr_call(p, value, args, arg_count, results));
}

ssaValue *ssa_emit_global_call(ssaProcedure *proc, char *name_, ssaValue **args, isize arg_count) {
	String name = make_string(name_);
	ssaValue **found = map_get(&proc->module->members, hash_string(name));
	GB_ASSERT_MSG(found != NULL, "%.*s", LIT(name));
	ssaValue *gp = *found;
	return ssa_emit_call(proc, gp, args, arg_count);
}



void ssa_emit_defer_stmts(ssaProcedure *proc, ssaDeferExitKind kind, ssaBlock *block) {
	isize count = proc->defer_stmts.count;
	isize i = count;
	while (i --> 0) {
		ssaDefer d = proc->defer_stmts[i];
		if (kind == ssaDeferExit_Default) {
			if (proc->scope_index == d.scope_index &&
			    d.scope_index > 1) {
				ssa_build_defer_stmt(proc, d);
				array_pop(&proc->defer_stmts);
				continue;
			} else {
				break;
			}
		} else if (kind == ssaDeferExit_Return) {
			ssa_build_defer_stmt(proc, d);
		} else if (kind == ssaDeferExit_Branch) {
			GB_ASSERT(block != NULL);
			isize lower_limit = block->scope_index+1;
			if (lower_limit < d.scope_index) {
				ssa_build_defer_stmt(proc, d);
			}
		}
	}
}


void ssa_open_scope(ssaProcedure *proc) {
	proc->scope_index++;
}

void ssa_close_scope(ssaProcedure *proc, ssaDeferExitKind kind, ssaBlock *block) {
	ssa_emit_defer_stmts(proc, kind, block);
	GB_ASSERT(proc->scope_index > 0);
	proc->scope_index--;
}



void ssa_emit_unreachable(ssaProcedure *proc) {
	ssa_emit(proc, ssa_make_instr_unreachable(proc));
}

void ssa_emit_return(ssaProcedure *proc, ssaValue *v) {
	ssa_emit_defer_stmts(proc, ssaDeferExit_Return, NULL);
	ssa_emit(proc, ssa_make_instr_return(proc, v));
}

void ssa_emit_jump(ssaProcedure *proc, ssaBlock *target_block) {
	ssaBlock *b = proc->curr_block;
	if (b == NULL) {
		return;
	}
	ssa_emit(proc, ssa_make_instr_jump(proc, target_block));
	ssa_add_edge(b, target_block);
	proc->curr_block = NULL;
}

void ssa_emit_if(ssaProcedure *proc, ssaValue *cond, ssaBlock *true_block, ssaBlock *false_block) {
	ssaBlock *b = proc->curr_block;
	if (b == NULL) {
		return;
	}
	ssa_emit(proc, ssa_make_instr_if(proc, cond, true_block, false_block));
	ssa_add_edge(b, true_block);
	ssa_add_edge(b, false_block);
	proc->curr_block = NULL;
}

void ssa_emit_startup_runtime(ssaProcedure *proc) {
	GB_ASSERT(proc->parent == NULL && proc->name == "main");
	ssa_emit(proc, ssa_alloc_instr(proc, ssaInstr_StartupRuntime));
}




ssaValue *ssa_addr_store(ssaProcedure *proc, ssaAddr addr, ssaValue *value) {
	if (addr.addr == NULL) {
		return NULL;
	}

	if (addr.kind == ssaAddr_Vector) {
		ssaValue *v = ssa_emit_load(proc, addr.addr);
		Type *elem_type = base_type(ssa_type(v))->Vector.elem;
		ssaValue *elem = ssa_emit_conv(proc, value, elem_type);
		ssaValue *out = ssa_emit(proc, ssa_make_instr_insert_element(proc, v, elem, addr.Vector.index));
		return ssa_emit_store(proc, addr.addr, out);
	} else {
		ssaValue *v = ssa_emit_conv(proc, value, ssa_addr_type(addr));
		return ssa_emit_store(proc, addr.addr, v);
	}
}
ssaValue *ssa_addr_load(ssaProcedure *proc, ssaAddr addr) {
	if (addr.addr == NULL) {
		GB_PANIC("Illegal addr load");
		return NULL;
	}

	if (addr.kind == ssaAddr_Vector) {
		ssaValue *v = ssa_emit_load(proc, addr.addr);
		return ssa_emit(proc, ssa_make_instr_extract_element(proc, v, addr.Vector.index));
	}
	Type *t = base_type(ssa_type(addr.addr));
	if (t->kind == Type_Proc) {
		// NOTE(bill): Imported procedures don't require a load as they are pointers
		return addr.addr;
	}
	return ssa_emit_load(proc, addr.addr);
}




ssaValue *ssa_emit_ptr_offset(ssaProcedure *proc, ssaValue *ptr, ssaValue *offset) {
	offset = ssa_emit_conv(proc, offset, t_int);
	return ssa_emit(proc, ssa_make_instr_ptr_offset(proc, ptr, offset));
}

ssaValue *ssa_emit_arith(ssaProcedure *proc, TokenKind op, ssaValue *left, ssaValue *right, Type *type) {
	Type *t_left = ssa_type(left);
	Type *t_right = ssa_type(right);

	if (op == Token_Add) {
		if (is_type_pointer(t_left)) {
			ssaValue *ptr = ssa_emit_conv(proc, left, type);
			ssaValue *offset = right;
			return ssa_emit_ptr_offset(proc, ptr, offset);
		} else if (is_type_pointer(ssa_type(right))) {
			ssaValue *ptr = ssa_emit_conv(proc, right, type);
			ssaValue *offset = left;
			return ssa_emit_ptr_offset(proc, ptr, offset);
		}
	} else if (op == Token_Sub) {
		if (is_type_pointer(t_left) && is_type_integer(t_right)) {
			// ptr - int
			ssaValue *ptr = ssa_emit_conv(proc, left, type);
			ssaValue *offset = right;
			return ssa_emit_ptr_offset(proc, ptr, offset);
		} else if (is_type_pointer(t_left) && is_type_pointer(t_right)) {
			GB_ASSERT(is_type_integer(type));
			Type *ptr_type = t_left;
			ssaModule *m = proc->module;
			ssaValue *x = ssa_emit_conv(proc, left, type);
			ssaValue *y = ssa_emit_conv(proc, right, type);
			ssaValue *diff = ssa_emit_arith(proc, op, x, y, type);
			ssaValue *elem_size = ssa_make_const_int(m->allocator, type_size_of(m->sizes, m->allocator, ptr_type));
			return ssa_emit_arith(proc, Token_Quo, diff, elem_size, type);
		}
	}


	switch (op) {
	case Token_AndNot: {
		// NOTE(bill): x &~ y == x & (~y) == x & (y ~ -1)
		// NOTE(bill): "not" `x` == `x` "xor" `-1`
		ssaValue *neg = ssa_add_module_constant(proc->module, type, make_exact_value_integer(-1));
		op = Token_Xor;
		right = ssa_emit_arith(proc, op, right, neg, type);
		GB_ASSERT(right->Instr.kind == ssaInstr_BinaryOp);
		right->Instr.BinaryOp.type = type;
		op = Token_And;
	} /* fallthrough */
	case Token_Add:
	case Token_Sub:
	case Token_Mul:
	case Token_Quo:
	case Token_Mod:
	case Token_And:
	case Token_Or:
	case Token_Xor:
		left  = ssa_emit_conv(proc, left, type);
		right = ssa_emit_conv(proc, right, type);
		break;
	}

	return ssa_emit(proc, ssa_make_instr_binary_op(proc, op, left, right, type));
}

ssaValue *ssa_emit_comp(ssaProcedure *proc, TokenKind op_kind, ssaValue *left, ssaValue *right) {
	Type *a = base_type(ssa_type(left));
	Type *b = base_type(ssa_type(right));

	if (are_types_identical(a, b)) {
		// NOTE(bill): No need for a conversion
	} else if (left->kind == ssaValue_Constant || left->kind == ssaValue_Nil) {
		left = ssa_emit_conv(proc, left, ssa_type(right));
	} else if (right->kind == ssaValue_Constant || right->kind == ssaValue_Nil) {
		right = ssa_emit_conv(proc, right, ssa_type(left));
	}

	Type *result = t_bool;
	if (is_type_vector(a)) {
		result = make_type_vector(proc->module->allocator, t_bool, a->Vector.count);
	}
	return ssa_emit(proc, ssa_make_instr_binary_op(proc, op_kind, left, right, result));
}

ssaValue *ssa_emit_array_ep(ssaProcedure *proc, ssaValue *s, ssaValue *index) {
	Type *st = base_type(type_deref(ssa_type(s)));
	GB_ASSERT(is_type_array(st));

	// NOTE(bill): For some weird legacy reason in LLVM, structure elements must be accessed as an i32
	index = ssa_emit_conv(proc, index, t_i32);
	return ssa_emit(proc, ssa_make_instr_array_element_ptr(proc, s, index));
}

ssaValue *ssa_emit_array_ep(ssaProcedure *proc, ssaValue *s, i32 index) {
	return ssa_emit_array_ep(proc, s, ssa_make_const_i32(proc->module->allocator, index));
}


ssaValue *ssa_emit_struct_ep(ssaProcedure *proc, ssaValue *s, i32 index) {
	gbAllocator a = proc->module->allocator;
	Type *t = base_type(type_deref(ssa_type(s)));
	Type *result_type = NULL;
	ssaValue *gep = NULL;

	if (is_type_struct(t)) {
		GB_ASSERT(t->Record.field_count > 0);
		GB_ASSERT(gb_is_between(index, 0, t->Record.field_count-1));
		result_type = make_type_pointer(a, t->Record.fields[index]->type);
	} else if (is_type_tuple(t)) {
		GB_ASSERT(t->Tuple.variable_count > 0);
		GB_ASSERT(gb_is_between(index, 0, t->Tuple.variable_count-1));
		result_type = make_type_pointer(a, t->Tuple.variables[index]->type);
	} else if (is_type_slice(t)) {
		switch (index) {
		case 0: result_type = make_type_pointer(a, make_type_pointer(a, t->Slice.elem)); break;
		case 1: result_type = make_type_pointer(a, t_int); break;
		case 2: result_type = make_type_pointer(a, t_int); break;
		}
	} else if (is_type_string(t)) {
		switch (index) {
		case 0: result_type = make_type_pointer(a, t_u8_ptr); break;
		case 1: result_type = make_type_pointer(a, t_int);    break;
		}
	} else if (is_type_any(t)) {
		switch (index) {
		case 0: result_type = make_type_pointer(a, t_type_info_ptr); break;
		case 1: result_type = make_type_pointer(a, t_rawptr);        break;
		}
	} else if (is_type_maybe(t)) {
		switch (index) {
		case 0: result_type = make_type_pointer(a, t->Maybe.elem); break;
		case 1: result_type = make_type_pointer(a, t_bool);        break;
		}
	} else if (is_type_union(t)) {
		switch (index) {
		case 1: result_type = make_type_pointer(a, t_int); break;

		case 0:
		default:
			GB_PANIC("TODO(bill): struct_gep 0 for unions");
			break;
		}
	} else {
		GB_PANIC("TODO(bill): struct_gep type: %s, %d", type_to_string(ssa_type(s)), index);
	}

	GB_ASSERT(result_type != NULL);

	gep = ssa_make_instr_struct_element_ptr(proc, s, index, result_type);
	return ssa_emit(proc, gep);
}



ssaValue *ssa_emit_array_ev(ssaProcedure *proc, ssaValue *s, i32 index) {
	Type *st = base_type(ssa_type(s));
	GB_ASSERT(is_type_array(st));
	return ssa_emit(proc, ssa_make_instr_array_extract_value(proc, s, index));
}

ssaValue *ssa_emit_struct_ev(ssaProcedure *proc, ssaValue *s, i32 index) {
	// NOTE(bill): For some weird legacy reason in LLVM, structure elements must be accessed as an i32

	gbAllocator a = proc->module->allocator;
	Type *t = base_type(ssa_type(s));
	Type *result_type = NULL;

	if (is_type_struct(t)) {
		GB_ASSERT(t->Record.field_count > 0);
		GB_ASSERT(gb_is_between(index, 0, t->Record.field_count-1));
		result_type = t->Record.fields[index]->type;
	} else if (is_type_tuple(t)) {
		GB_ASSERT(t->Tuple.variable_count > 0);
		GB_ASSERT(gb_is_between(index, 0, t->Tuple.variable_count-1));
		result_type = t->Tuple.variables[index]->type;
	} else if (is_type_slice(t)) {
		switch (index) {
		case 0: result_type = make_type_pointer(a, t->Slice.elem); break;
		case 1: result_type = t_int; break;
		case 2: result_type = t_int; break;
		}
	} else if (is_type_string(t)) {
		switch (index) {
		case 0: result_type = t_u8_ptr; break;
		case 1: result_type = t_int;    break;
		}
	} else if (is_type_any(t)) {
		switch (index) {
		case 0: result_type = t_type_info_ptr; break;
		case 1: result_type = t_rawptr;        break;
		}
	} else if (is_type_maybe(t)) {
		switch (index) {
		case 0: result_type = t->Maybe.elem; break;
		case 1: result_type = t_bool;        break;
		}
	} else if (is_type_union(t)) {
		switch (index) {
		case 1: result_type = t_int; break;

		case 0:
		default:
			GB_PANIC("TODO(bill): struct_gep 0 for unions");
			break;
		}
	} else {
		GB_PANIC("TODO(bill): struct_ev type: %s, %d", type_to_string(ssa_type(s)), index);
	}

	GB_ASSERT(result_type != NULL);

	return ssa_emit(proc, ssa_make_instr_struct_extract_value(proc, s, index, result_type));
}


ssaValue *ssa_emit_deep_field_gep(ssaProcedure *proc, Type *type, ssaValue *e, Selection sel) {
	GB_ASSERT(sel.index.count > 0);

	for_array(i, sel.index) {
		i32 index = cast(i32)sel.index[i];
		if (is_type_pointer(type)) {
			type = type_deref(type);
			e = ssa_emit_load(proc, e);
			e = ssa_emit_ptr_offset(proc, e, v_zero); // TODO(bill): Do I need these copies?
		}
		type = base_type(type);


		if (is_type_raw_union(type)) {
			type = type->Record.fields[index]->type;
			e = ssa_emit_conv(proc, e, make_type_pointer(proc->module->allocator, type));
		} else if (type->kind == Type_Record) {
			type = type->Record.fields[index]->type;
			e = ssa_emit_struct_ep(proc, e, index);
		} else if (type->kind == Type_Basic) {
			switch (type->Basic.kind) {
			case Basic_any: {
				if (index == 0) {
					type = t_type_info_ptr;
				} else if (index == 1) {
					type = t_rawptr;
				}
				e = ssa_emit_struct_ep(proc, e, index);
			} break;

			case Basic_string:
				e = ssa_emit_struct_ep(proc, e, index);
				break;

			default:
				GB_PANIC("un-gep-able type");
				break;
			}
		} else if (type->kind == Type_Slice) {
			e = ssa_emit_struct_ep(proc, e, index);
		} else {
			GB_PANIC("un-gep-able type");
		}
	}

	return e;
}


ssaValue *ssa_emit_deep_field_ev(ssaProcedure *proc, Type *type, ssaValue *e, Selection sel) {
	GB_ASSERT(sel.index.count > 0);

	for_array(i, sel.index) {
		isize index = sel.index[i];
		if (is_type_pointer(type)) {
			type = type_deref(type);
			e = ssa_emit_load(proc, e);
			e = ssa_emit_ptr_offset(proc, e, v_zero); // TODO(bill): Do I need these copies?
		}
		type = base_type(type);


		if (is_type_raw_union(type)) {
			type = type->Record.fields[index]->type;
			e = ssa_emit_conv(proc, e, make_type_pointer(proc->module->allocator, type));
		} else {
			e = ssa_emit_struct_ev(proc, e, index);
		}
	}

	return e;
}




ssaValue *ssa_array_elem(ssaProcedure *proc, ssaValue *array) {
	return ssa_emit_array_ep(proc, array, v_zero32);
}
ssaValue *ssa_array_len(ssaProcedure *proc, ssaValue *array) {
	Type *t = ssa_type(array);
	GB_ASSERT(t->kind == Type_Array);
	return ssa_make_const_int(proc->module->allocator, t->Array.count);
}
ssaValue *ssa_array_cap(ssaProcedure *proc, ssaValue *array) {
	return ssa_array_len(proc, array);
}

ssaValue *ssa_slice_elem(ssaProcedure *proc, ssaValue *slice) {
	Type *t = ssa_type(slice);
	GB_ASSERT(t->kind == Type_Slice);
	return ssa_emit_struct_ev(proc, slice, 0);
}
ssaValue *ssa_slice_len(ssaProcedure *proc, ssaValue *slice) {
	Type *t = ssa_type(slice);
	GB_ASSERT(t->kind == Type_Slice);
	return ssa_emit_struct_ev(proc, slice, 1);
}
ssaValue *ssa_slice_cap(ssaProcedure *proc, ssaValue *slice) {
	Type *t = ssa_type(slice);
	GB_ASSERT(t->kind == Type_Slice);
	return ssa_emit_struct_ev(proc, slice, 2);
}

ssaValue *ssa_string_elem(ssaProcedure *proc, ssaValue *string) {
	Type *t = ssa_type(string);
	GB_ASSERT(t->kind == Type_Basic && t->Basic.kind == Basic_string);
	return ssa_emit_struct_ev(proc, string, 0);
}
ssaValue *ssa_string_len(ssaProcedure *proc, ssaValue *string) {
	Type *t = ssa_type(string);
	GB_ASSERT(t->kind == Type_Basic && t->Basic.kind == Basic_string);
	return ssa_emit_struct_ev(proc, string, 1);
}



ssaValue *ssa_add_local_slice(ssaProcedure *proc, Type *slice_type, ssaValue *base, ssaValue *low, ssaValue *high, ssaValue *max) {
	// TODO(bill): array bounds checking for slice creation
	// TODO(bill): check that low < high <= max
	gbAllocator a = proc->module->allocator;
	Type *bt = base_type(ssa_type(base));

	if (low == NULL) {
		low = v_zero;
	}
	if (high == NULL) {
		switch (bt->kind) {
		case Type_Array:   high = ssa_array_len(proc, base); break;
		case Type_Slice:   high = ssa_slice_len(proc, base); break;
		case Type_Pointer: high = v_one;                     break;
		}
	}
	if (max == NULL) {
		switch (bt->kind) {
		case Type_Array:   max = ssa_array_cap(proc, base); break;
		case Type_Slice:   max = ssa_slice_cap(proc, base); break;
		case Type_Pointer: max = high;                      break;
		}
	}
	GB_ASSERT(max != NULL);

	ssaValue *len = ssa_emit_arith(proc, Token_Sub, high, low, t_int);
	ssaValue *cap = ssa_emit_arith(proc, Token_Sub, max,  low, t_int);

	ssaValue *elem = NULL;
	switch (bt->kind) {
	case Type_Array:   elem = ssa_array_elem(proc, base); break;
	case Type_Slice:   elem = ssa_slice_elem(proc, base); break;
	case Type_Pointer: elem = ssa_emit_load(proc, base);  break;
	}

	elem = ssa_emit_ptr_offset(proc, elem, low);

	ssaValue *slice = ssa_add_local_generated(proc, slice_type);

	ssaValue *gep = NULL;
	gep = ssa_emit_struct_ep(proc, slice, 0);
	ssa_emit_store(proc, gep, elem);

	gep = ssa_emit_struct_ep(proc, slice, 1);
	ssa_emit_store(proc, gep, len);

	gep = ssa_emit_struct_ep(proc, slice, 2);
	ssa_emit_store(proc, gep, cap);

	return slice;
}


ssaValue *ssa_add_global_string_array(ssaModule *m, String string) {
	gbAllocator a = m->allocator;

	isize max_len = 6+8+1;
	u8 *str = cast(u8 *)gb_alloc_array(a, u8, max_len);
	isize len = gb_snprintf(cast(char *)str, max_len, "__str$%x", m->global_string_index);
	m->global_string_index++;

	String name = make_string(str, len-1);
	Token token = {Token_String};
	token.string = name;
	Type *type = make_type_array(a, t_u8, string.len);
	ExactValue ev = make_exact_value_string(string);
	Entity *entity = make_entity_constant(a, NULL, token, type, ev);
	ssaValue *g = ssa_make_value_global(a, entity, ssa_add_module_constant(m, type, ev));
	g->Global.is_private  = true;
	// g->Global.is_constant = true;

	ssa_module_add_value(m, entity, g);
	map_set(&m->members, hash_string(name), g);

	return g;
}

ssaValue *ssa_emit_string(ssaProcedure *proc, ssaValue *elem, ssaValue *len) {
	ssaValue *str = ssa_add_local_generated(proc, t_string);
	ssaValue *str_elem = ssa_emit_struct_ep(proc, str, 0);
	ssaValue *str_len = ssa_emit_struct_ep(proc, str, 1);
	ssa_emit_store(proc, str_elem, elem);
	ssa_emit_store(proc, str_len, len);
	return ssa_emit_load(proc, str);
}


ssaValue *ssa_emit_global_string(ssaProcedure *proc, String str) {
	ssaValue *global_array = ssa_add_global_string_array(proc->module, str);
	ssaValue *elem = ssa_array_elem(proc, global_array);
	ssaValue *len =  ssa_make_const_int(proc->module->allocator, str.len);
	return ssa_emit_string(proc, elem, len);
}




String lookup_polymorphic_field(CheckerInfo *info, Type *dst, Type *src) {
	Type *prev_src = src;
	// Type *prev_dst = dst;
	src = base_type(type_deref(src));
	// dst = base_type(type_deref(dst));
	b32 src_is_ptr = src != prev_src;
	// b32 dst_is_ptr = dst != prev_dst;

	GB_ASSERT(is_type_struct(src));
	for (isize i = 0; i < src->Record.field_count; i++) {
		Entity *f = src->Record.fields[i];
		if (f->kind == Entity_Variable && f->Variable.anonymous) {
			if (are_types_identical(dst, f->type)) {
				return f->token.string;
			}
			if (src_is_ptr && is_type_pointer(dst)) {
				if (are_types_identical(type_deref(dst), f->type)) {
					return f->token.string;
				}
			}
			String name = lookup_polymorphic_field(info, dst, f->type);
			if (name.len > 0) {
				return name;
			}
		}
	}
	return make_string("");
}

ssaValue *ssa_emit_bitcast(ssaProcedure *proc, ssaValue *data, Type *type) {
	return ssa_emit(proc, ssa_make_instr_conv(proc, ssaConv_bitcast, data, ssa_type(data), type));
}


ssaValue *ssa_emit_conv(ssaProcedure *proc, ssaValue *value, Type *t, b32 is_argument) {
	Type *src_type = ssa_type(value);
	if (are_types_identical(t, src_type)) {
		return value;
	}


	Type *src = get_enum_base_type(base_type(src_type));
	Type *dst = get_enum_base_type(base_type(t));

	if (value->kind == ssaValue_Constant) {
		if (is_type_any(dst)) {
			ssaValue *default_value = ssa_add_local_generated(proc, default_type(src_type));
			ssa_emit_store(proc, default_value, value);
			return ssa_emit_conv(proc, ssa_emit_load(proc, default_value), t_any, is_argument);
		} else if (dst->kind == Type_Basic) {
			ExactValue ev = value->Constant.value;
			if (is_type_float(dst)) {
				ev = exact_value_to_float(ev);
			} else if (is_type_string(dst)) {
				// Handled elsewhere
				GB_ASSERT(ev.kind == ExactValue_String);
			} else if (is_type_integer(dst)) {
				ev = exact_value_to_integer(ev);
			} else if (is_type_pointer(dst)) {
				// IMPORTANT NOTE(bill): LLVM doesn't support pointer constants expect `null`
				ssaValue *i = ssa_add_module_constant(proc->module, t_uint, ev);
				return ssa_emit(proc, ssa_make_instr_conv(proc, ssaConv_inttoptr, i, t_uint, dst));
			}
			return ssa_add_module_constant(proc->module, t, ev);
		}
	}

	if (are_types_identical(src, dst)) {
		return value;
	}

	if (is_type_maybe(dst)) {
		ssaValue *maybe = ssa_add_local_generated(proc, dst);
		ssaValue *val = ssa_emit_struct_ep(proc, maybe, 0);
		ssaValue *set = ssa_emit_struct_ep(proc, maybe, 1);
		ssa_emit_store(proc, val, value);
		ssa_emit_store(proc, set, v_true);
		return ssa_emit_load(proc, maybe);
	}

	// integer -> integer
	if (is_type_integer(src) && is_type_integer(dst)) {
		GB_ASSERT(src->kind == Type_Basic &&
		          dst->kind == Type_Basic);
		i64 sz = type_size_of(proc->module->sizes, proc->module->allocator, src);
		i64 dz = type_size_of(proc->module->sizes, proc->module->allocator, dst);
		if (sz == dz) {
			// NOTE(bill): In LLVM, all integers are signed and rely upon 2's compliment
			return value;
		}

		ssaConvKind kind = ssaConv_trunc;
		if (dz >= sz) {
			kind = ssaConv_zext;
		}
		return ssa_emit(proc, ssa_make_instr_conv(proc, kind, value, src, dst));
	}

	// boolean -> integer
	if (is_type_boolean(src) && is_type_integer(dst)) {
		return ssa_emit(proc, ssa_make_instr_conv(proc, ssaConv_zext, value, src, dst));
	}

	// integer -> boolean
	if (is_type_integer(src) && is_type_boolean(dst)) {
		return ssa_emit_comp(proc, Token_NotEq, value, v_zero);
	}


	// float -> float
	if (is_type_float(src) && is_type_float(dst)) {
		i64 sz = basic_type_sizes[src->Basic.kind];
		i64 dz = basic_type_sizes[dst->Basic.kind];
		ssaConvKind kind = ssaConv_fptrunc;
		if (dz >= sz) {
			kind = ssaConv_fpext;
		}
		return ssa_emit(proc, ssa_make_instr_conv(proc, kind, value, src, dst));
	}

	// float <-> integer
	if (is_type_float(src) && is_type_integer(dst)) {
		ssaConvKind kind = ssaConv_fptosi;
		if (is_type_unsigned(dst)) {
			kind = ssaConv_fptoui;
		}
		return ssa_emit(proc, ssa_make_instr_conv(proc, kind, value, src, dst));
	}
	if (is_type_integer(src) && is_type_float(dst)) {
		ssaConvKind kind = ssaConv_sitofp;
		if (is_type_unsigned(src)) {
			kind = ssaConv_uitofp;
		}
		return ssa_emit(proc, ssa_make_instr_conv(proc, kind, value, src, dst));
	}

	// Pointer <-> int
	if (is_type_pointer(src) && is_type_int_or_uint(dst)) {
		return ssa_emit(proc, ssa_make_instr_conv(proc, ssaConv_ptrtoint, value, src, dst));
	}
	if (is_type_int_or_uint(src) && is_type_pointer(dst)) {
		return ssa_emit(proc, ssa_make_instr_conv(proc, ssaConv_inttoptr, value, src, dst));
	}

	if (is_type_union(dst)) {
		for (isize i = 0; i < dst->Record.field_count; i++) {
			Entity *f = dst->Record.fields[i];
			if (are_types_identical(f->type, src_type)) {
				ssa_emit_comment(proc, make_string("union - child to parent"));
				gbAllocator allocator = proc->module->allocator;
				ssaValue *parent = ssa_add_local_generated(proc, t);
				ssaValue *tag = ssa_make_const_int(allocator, i);
				ssa_emit_store(proc, ssa_emit_struct_ep(proc, parent, 1), tag);

				ssaValue *data = ssa_emit_conv(proc, parent, t_rawptr);

				Type *tag_type = src_type;
				Type *tag_type_ptr = make_type_pointer(allocator, tag_type);
				ssaValue *underlying = ssa_emit_bitcast(proc, data, tag_type_ptr);
				ssa_emit_store(proc, underlying, value);

				return ssa_emit_load(proc, parent);
			}
		}
	}

	// NOTE(bill): This has to be done beofre `Pointer <-> Pointer` as it's
	// subtype polymorphism casting
	if (true || is_argument) {
		Type *sb = base_type(type_deref(src));
		b32 src_is_ptr = src != sb;
		if (is_type_struct(sb)) {
			String field_name = lookup_polymorphic_field(proc->module->info, t, src);
			// gb_printf("field_name: %.*s\n", LIT(field_name));
			if (field_name.len > 0) {
				// NOTE(bill): It can be casted
				Selection sel = lookup_field(proc->module->allocator, sb, field_name, false);
				if (sel.entity != NULL) {
					ssa_emit_comment(proc, make_string("cast - polymorphism"));
					if (src_is_ptr) {
						value = ssa_emit_load(proc, value);
					}
					return ssa_emit_deep_field_ev(proc, sb, value, sel);
				}
			}
		}
	}



	// Pointer <-> Pointer
	if (is_type_pointer(src) && is_type_pointer(dst)) {
		return ssa_emit_bitcast(proc, value, dst);
	}



	// proc <-> proc
	if (is_type_proc(src) && is_type_proc(dst)) {
		return ssa_emit_bitcast(proc, value, dst);
	}

	// pointer -> proc
	if (is_type_pointer(src) && is_type_proc(dst)) {
		return ssa_emit_bitcast(proc, value, dst);
	}
	// proc -> pointer
	if (is_type_proc(src) && is_type_pointer(dst)) {
		return ssa_emit_bitcast(proc, value, dst);
	}



	// []byte/[]u8 <-> string
	if (is_type_u8_slice(src) && is_type_string(dst)) {
		ssaValue *elem = ssa_slice_elem(proc, value);
		ssaValue *len  = ssa_slice_len(proc, value);
		return ssa_emit_string(proc, elem, len);
	}
	if (is_type_string(src) && is_type_u8_slice(dst)) {
		ssaValue *elem = ssa_string_elem(proc, value);
		ssaValue *elem_ptr = ssa_add_local_generated(proc, ssa_type(elem));
		ssa_emit_store(proc, elem_ptr, elem);

		ssaValue *len  = ssa_string_len(proc, value);
		ssaValue *slice = ssa_add_local_slice(proc, dst, elem_ptr, v_zero, len, len);
		return ssa_emit_load(proc, slice);
	}

	if (is_type_vector(dst)) {
		Type *dst_elem = dst->Vector.elem;
		value = ssa_emit_conv(proc, value, dst_elem);
		ssaValue *v = ssa_add_local_generated(proc, t);
		v = ssa_emit_load(proc, v);
		v = ssa_emit(proc, ssa_make_instr_insert_element(proc, v, value, v_zero32));
		// NOTE(bill): Broadcast lowest value to all values
		isize index_count = dst->Vector.count;
		i32 *indices = gb_alloc_array(proc->module->allocator, i32, index_count);
		for (isize i = 0; i < index_count; i++) {
			indices[i] = 0;
		}

		v = ssa_emit(proc, ssa_make_instr_vector_shuffle(proc, v, indices, index_count));
		return v;
	}

	if (is_type_any(dst)) {
		ssaValue *result = ssa_add_local_generated(proc, t_any);

		if (is_type_untyped_nil(src)) {
			return ssa_emit_load(proc, result);
		}

		ssaValue *data = NULL;
		if (value->kind == ssaValue_Instr &&
		    value->Instr.kind == ssaInstr_Load) {
			// NOTE(bill): Addressable value
			data = value->Instr.Load.address;
		} else {
			// NOTE(bill): Non-addressable value
			data = ssa_add_local_generated(proc, src_type);
			ssa_emit_store(proc, data, value);
		}
		GB_ASSERT(is_type_pointer(ssa_type(data)));
		GB_ASSERT(is_type_typed(src_type));
		data = ssa_emit_conv(proc, data, t_rawptr);


		ssaValue *ti = ssa_type_info(proc, src_type);

		ssaValue *gep0 = ssa_emit_struct_ep(proc, result, 0);
		ssaValue *gep1 = ssa_emit_struct_ep(proc, result, 1);
		ssa_emit_store(proc, gep0, ti);
		ssa_emit_store(proc, gep1, data);

		return ssa_emit_load(proc, result);
	}

	if (is_type_untyped_nil(src) && type_has_nil(dst)) {
		return ssa_make_value_nil(proc->module->allocator, t);
	}


	gb_printf_err("ssa_emit_conv: src -> dst\n");
	gb_printf_err("Not Identical %s != %s\n", type_to_string(src_type), type_to_string(t));
	gb_printf_err("Not Identical %s != %s\n", type_to_string(src), type_to_string(dst));


	GB_PANIC("Invalid type conversion: `%s` to `%s`", type_to_string(src_type), type_to_string(t));

	return NULL;
}


ssaValue *ssa_emit_transmute(ssaProcedure *proc, ssaValue *value, Type *t) {
	Type *src_type = ssa_type(value);
	if (are_types_identical(t, src_type)) {
		return value;
	}

	Type *src = base_type(src_type);
	Type *dst = base_type(t);
	if (are_types_identical(t, src_type)) {
		return value;
	}

	i64 sz = type_size_of(proc->module->sizes, proc->module->allocator, src);
	i64 dz = type_size_of(proc->module->sizes, proc->module->allocator, dst);

	if (sz == dz) {
		return ssa_emit_bitcast(proc, value, dst);
	}


	GB_PANIC("Invalid transmute conversion: `%s` to `%s`", type_to_string(src_type), type_to_string(t));

	return NULL;
}

ssaValue *ssa_emit_down_cast(ssaProcedure *proc, ssaValue *value, Type *t) {
	GB_ASSERT(is_type_pointer(ssa_type(value)));
	gbAllocator allocator = proc->module->allocator;

	String field_name = check_down_cast_name(t, type_deref(ssa_type(value)));
	GB_ASSERT(field_name.len > 0);
	Selection sel = lookup_field(proc->module->allocator, t, field_name, false);
	Type *t_u8_ptr = make_type_pointer(allocator, t_u8);
	ssaValue *bytes = ssa_emit_conv(proc, value, t_u8_ptr);

	i64 offset_ = type_offset_of_from_selection(proc->module->sizes, allocator, type_deref(t), sel);
	ssaValue *offset = ssa_make_const_int(allocator, -offset_);
	ssaValue *head = ssa_emit_ptr_offset(proc, bytes, offset);
	return ssa_emit_conv(proc, head, t);
}

ssaValue *ssa_emit_union_cast(ssaProcedure *proc, ssaValue *value, Type *tuple) {
	GB_ASSERT(tuple->kind == Type_Tuple);
	gbAllocator a = proc->module->allocator;

	Type *src_type = ssa_type(value);
	b32 is_ptr = is_type_pointer(src_type);

	ssaValue *v = ssa_add_local_generated(proc, tuple);

	if (is_ptr) {
		Type *src = base_type(type_deref(src_type));
		Type *src_ptr = src_type;
		GB_ASSERT(is_type_union(src));
		Type *dst_ptr = tuple->Tuple.variables[0]->type;
		Type *dst = type_deref(dst_ptr);

		ssaValue *tag = ssa_emit_load(proc, ssa_emit_struct_ep(proc, value, 1));
		ssaValue *dst_tag = NULL;
		for (isize i = 1; i < src->Record.field_count; i++) {
			Entity *f = src->Record.fields[i];
			if (are_types_identical(f->type, dst)) {
				dst_tag = ssa_make_const_int(a, i);
				break;
			}
		}
		GB_ASSERT(dst_tag != NULL);

		ssaBlock *ok_block = ssa_add_block(proc, NULL, "union_cast.ok");
		ssaBlock *end_block = ssa_add_block(proc, NULL, "union_cast.end");
		ssaValue *cond = ssa_emit_comp(proc, Token_CmpEq, tag, dst_tag);
		ssa_emit_if(proc, cond, ok_block, end_block);
		proc->curr_block = ok_block;

		ssaValue *gep0 = ssa_emit_struct_ep(proc, v, 0);
		ssaValue *gep1 = ssa_emit_struct_ep(proc, v, 1);

		ssaValue *data = ssa_emit_conv(proc, value, dst_ptr);
		ssa_emit_store(proc, gep0, data);
		ssa_emit_store(proc, gep1, v_true);

		ssa_emit_jump(proc, end_block);
		proc->curr_block = end_block;

	} else {
		Type *src = base_type(src_type);
		GB_ASSERT(is_type_union(src));
		Type *dst = tuple->Tuple.variables[0]->type;
		Type *dst_ptr = make_type_pointer(a, dst);

		ssaValue *tag = ssa_emit_struct_ev(proc, value, 1);
		ssaValue *dst_tag = NULL;
		for (isize i = 1; i < src->Record.field_count; i++) {
			Entity *f = src->Record.fields[i];
			if (are_types_identical(f->type, dst)) {
				dst_tag = ssa_make_const_int(a, i);
				break;
			}
		}
		GB_ASSERT(dst_tag != NULL);

		// HACK(bill): This is probably not very efficient
		ssaValue *union_copy = ssa_add_local_generated(proc, src_type);
		ssa_emit_store(proc, union_copy, value);

		ssaBlock *ok_block = ssa_add_block(proc, NULL, "union_cast.ok");
		ssaBlock *end_block = ssa_add_block(proc, NULL, "union_cast.end");
		ssaValue *cond = ssa_emit_comp(proc, Token_CmpEq, tag, dst_tag);
		ssa_emit_if(proc, cond, ok_block, end_block);
		proc->curr_block = ok_block;

		ssaValue *gep0 = ssa_emit_struct_ep(proc, v, 0);
		ssaValue *gep1 = ssa_emit_struct_ep(proc, v, 1);

		ssaValue *data = ssa_emit_load(proc, ssa_emit_conv(proc, union_copy, dst_ptr));
		ssa_emit_store(proc, gep0, data);
		ssa_emit_store(proc, gep1, v_true);

		ssa_emit_jump(proc, end_block);
		proc->curr_block = end_block;

	}
	return ssa_emit_load(proc, v);
}


isize ssa_type_info_index(CheckerInfo *info, Type *type) {
	type = default_type(type);

	isize entry_index = -1;
	HashKey key = hash_pointer(type);
	auto *found_entry_index = map_get(&info->type_info_map, key);
	if (found_entry_index) {
		entry_index = *found_entry_index;
	}
	if (entry_index < 0) {
		// NOTE(bill): Do manual search
		// TODO(bill): This is O(n) and can be very slow
		for_array(i, info->type_info_map.entries){
			auto *e = &info->type_info_map.entries[i];
			Type *prev_type = cast(Type *)e->key.ptr;
			if (are_types_identical(prev_type, type)) {
				entry_index = e->value;
				// NOTE(bill): Add it to the search map
				map_set(&info->type_info_map, key, entry_index);
				break;
			}
		}
	}

	if (entry_index < 0) {
		compiler_error("Type_Info for `%s` could not be found", type_to_string(type));
	}
	return entry_index;
}

ssaValue *ssa_type_info(ssaProcedure *proc, Type *type) {
	ssaValue **found = map_get(&proc->module->members, hash_string(make_string(SSA_TYPE_INFO_DATA_NAME)));
	GB_ASSERT(found != NULL);
	ssaValue *type_info_data = *found;

	CheckerInfo *info = proc->module->info;
	ssaValue *entry_index = ssa_make_const_i32(proc->module->allocator, ssa_type_info_index(info, type));
	return ssa_emit_array_ep(proc, type_info_data, entry_index);
}



ssaValue *ssa_emit_logical_binary_expr(ssaProcedure *proc, AstNode *expr) {
	ast_node(be, BinaryExpr, expr);
#if 0
	ssaBlock *true_   = ssa_add_block(proc, NULL, "logical.cmp.true");
	ssaBlock *false_  = ssa_add_block(proc, NULL, "logical.cmp.false");
	ssaBlock *done  = ssa_add_block(proc, NULL, "logical.cmp.done");

	ssaValue *result = ssa_add_local_generated(proc, t_bool);
	ssa_build_cond(proc, expr, true_, false_);

	proc->curr_block = true_;
	ssa_emit_store(proc, result, v_true);
	ssa_emit_jump(proc, done);

	proc->curr_block = false_;
	ssa_emit_store(proc, result, v_false);
	ssa_emit_jump(proc, done);

	proc->curr_block = done;

	return ssa_emit_load(proc, result);
#else
	ssaBlock *rhs = ssa_add_block(proc, NULL, "logical.cmp.rhs");
	ssaBlock *done = ssa_add_block(proc, NULL, "logical.cmp.done");

	Type *type = type_of_expr(proc->module->info, expr);
	type = default_type(type);

	ssaValue *short_circuit = NULL;
	if (be->op.kind == Token_CmpAnd) {
		ssa_build_cond(proc, be->left, rhs, done);
		short_circuit = v_false;
	} else if (be->op.kind == Token_CmpOr) {
		ssa_build_cond(proc, be->left, done, rhs);
		short_circuit = v_true;
	}

	if (rhs->preds.count == 0) {
		proc->curr_block = done;
		return short_circuit;
	}

	if (done->preds.count == 0) {
		proc->curr_block = rhs;
		return ssa_build_expr(proc, be->right);
	}

	Array<ssaValue *> edges = {};
	array_init(&edges, proc->module->allocator, done->preds.count+1);
	for_array(i, done->preds) {
		array_add(&edges, short_circuit);
	}

	proc->curr_block = rhs;
	array_add(&edges, ssa_build_expr(proc, be->right));
	ssa_emit_jump(proc, done);
	proc->curr_block = done;

	return ssa_emit(proc, ssa_make_instr_phi(proc, edges, type));
#endif
}





