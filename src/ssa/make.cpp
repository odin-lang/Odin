void ssa_module_add_value(ssaModule *m, Entity *e, ssaValue *v);


ssaValue *ssa_alloc_value(gbAllocator a, ssaValueKind kind) {
	ssaValue *v = gb_alloc_item(a, ssaValue);
	v->kind = kind;
	return v;
}
ssaValue *ssa_alloc_instr(ssaProcedure *proc, ssaInstrKind kind) {
	ssaValue *v = ssa_alloc_value(proc->module->allocator, ssaValue_Instr);
	v->Instr.kind = kind;
	return v;
}
ssaDebugInfo *ssa_alloc_debug_info(gbAllocator a, ssaDebugInfoKind kind) {
	ssaDebugInfo *di = gb_alloc_item(a, ssaDebugInfo);
	di->kind = kind;
	return di;
}




ssaValue *ssa_make_value_type_name(gbAllocator a, String name, Type *type) {
	ssaValue *v = ssa_alloc_value(a, ssaValue_TypeName);
	v->TypeName.name = name;
	v->TypeName.type = type;
	return v;
}

ssaValue *ssa_make_value_global(gbAllocator a, Entity *e, ssaValue *value) {
	ssaValue *v = ssa_alloc_value(a, ssaValue_Global);
	v->Global.entity = e;
	v->Global.type = make_type_pointer(a, e->type);
	v->Global.value = value;
	array_init(&v->Global.referrers, heap_allocator()); // TODO(bill): Replace heap allocator here
	return v;
}
ssaValue *ssa_make_value_param(gbAllocator a, ssaProcedure *parent, Entity *e) {
	ssaValue *v = ssa_alloc_value(a, ssaValue_Param);
	v->Param.parent = parent;
	v->Param.entity = e;
	v->Param.type   = e->type;
	array_init(&v->Param.referrers, heap_allocator()); // TODO(bill): Replace heap allocator here
	return v;
}
ssaValue *ssa_make_value_nil(gbAllocator a, Type *type) {
	ssaValue *v = ssa_alloc_value(a, ssaValue_Nil);
	v->Nil.type = type;
	return v;
}



ssaValue *ssa_make_instr_local(ssaProcedure *p, Entity *e, b32 zero_initialized) {
	ssaValue *v = ssa_alloc_instr(p, ssaInstr_Local);
	ssaInstr *i = &v->Instr;
	i->Local.entity = e;
	i->Local.type = make_type_pointer(p->module->allocator, e->type);
	i->Local.zero_initialized = zero_initialized;
	array_init(&i->Local.referrers, heap_allocator()); // TODO(bill): Replace heap allocator here
	ssa_module_add_value(p->module, e, v);
	return v;
}


ssaValue *ssa_make_instr_store(ssaProcedure *p, ssaValue *address, ssaValue *value) {
	ssaValue *v = ssa_alloc_instr(p, ssaInstr_Store);
	ssaInstr *i = &v->Instr;
	i->Store.address = address;
	i->Store.value = value;
	return v;
}

ssaValue *ssa_make_instr_zero_init(ssaProcedure *p, ssaValue *address) {
	ssaValue *v = ssa_alloc_instr(p, ssaInstr_ZeroInit);
	ssaInstr *i = &v->Instr;
	i->ZeroInit.address = address;
	return v;
}

ssaValue *ssa_make_instr_load(ssaProcedure *p, ssaValue *address) {
	ssaValue *v = ssa_alloc_instr(p, ssaInstr_Load);
	ssaInstr *i = &v->Instr;
	i->Load.address = address;
	i->Load.type = type_deref(ssa_type(address));
	return v;
}

ssaValue *ssa_make_instr_array_element_ptr(ssaProcedure *p, ssaValue *address, ssaValue *elem_index) {
	ssaValue *v = ssa_alloc_instr(p, ssaInstr_ArrayElementPtr);
	ssaInstr *i = &v->Instr;
	Type *t = ssa_type(address);
	GB_ASSERT(is_type_pointer(t));
	t = base_type(type_deref(t));
	GB_ASSERT(is_type_array(t));

	Type *result_type = make_type_pointer(p->module->allocator, t->Array.elem);

	i->ArrayElementPtr.address = address;
	i->ArrayElementPtr.elem_index = elem_index;
	i->ArrayElementPtr.result_type = result_type;

	GB_ASSERT_MSG(is_type_pointer(ssa_type(address)),
	              "%s", type_to_string(ssa_type(address)));
	return v;
}
ssaValue *ssa_make_instr_struct_element_ptr(ssaProcedure *p, ssaValue *address, i32 elem_index, Type *result_type) {
	ssaValue *v = ssa_alloc_instr(p, ssaInstr_StructElementPtr);
	ssaInstr *i = &v->Instr;
	i->StructElementPtr.address     = address;
	i->StructElementPtr.elem_index  = elem_index;
	i->StructElementPtr.result_type = result_type;

	GB_ASSERT_MSG(is_type_pointer(ssa_type(address)),
	              "%s", type_to_string(ssa_type(address)));
	return v;
}
ssaValue *ssa_make_instr_ptr_offset(ssaProcedure *p, ssaValue *address, ssaValue *offset) {
	ssaValue *v = ssa_alloc_instr(p, ssaInstr_PtrOffset);
	ssaInstr *i = &v->Instr;
	i->PtrOffset.address = address;
	i->PtrOffset.offset  = offset;

	GB_ASSERT_MSG(is_type_pointer(ssa_type(address)),
	              "%s", type_to_string(ssa_type(address)));
	GB_ASSERT_MSG(is_type_integer(ssa_type(offset)),
	              "%s", type_to_string(ssa_type(address)));

	return v;
}



ssaValue *ssa_make_instr_array_extract_value(ssaProcedure *p, ssaValue *address, i32 index) {
	ssaValue *v = ssa_alloc_instr(p, ssaInstr_ArrayExtractValue);
	ssaInstr *i = &v->Instr;
	i->ArrayExtractValue.address = address;
	i->ArrayExtractValue.index = index;
	Type *t = base_type(ssa_type(address));
	GB_ASSERT(is_type_array(t));
	i->ArrayExtractValue.result_type = t->Array.elem;
	return v;
}

ssaValue *ssa_make_instr_struct_extract_value(ssaProcedure *p, ssaValue *address, i32 index, Type *result_type) {
	ssaValue *v = ssa_alloc_instr(p, ssaInstr_StructExtractValue);
	ssaInstr *i = &v->Instr;
	i->StructExtractValue.address = address;
	i->StructExtractValue.index = index;
	i->StructExtractValue.result_type = result_type;
	return v;
}

ssaValue *ssa_make_instr_binary_op(ssaProcedure *p, TokenKind op, ssaValue *left, ssaValue *right, Type *type) {
	ssaValue *v = ssa_alloc_instr(p, ssaInstr_BinaryOp);
	ssaInstr *i = &v->Instr;
	i->BinaryOp.op = op;
	i->BinaryOp.left = left;
	i->BinaryOp.right = right;
	i->BinaryOp.type = type;
	return v;
}

ssaValue *ssa_make_instr_jump(ssaProcedure *p, ssaBlock *block) {
	ssaValue *v = ssa_alloc_instr(p, ssaInstr_Jump);
	ssaInstr *i = &v->Instr;
	i->Jump.block = block;
	return v;
}
ssaValue *ssa_make_instr_if(ssaProcedure *p, ssaValue *cond, ssaBlock *true_block, ssaBlock *false_block) {
	ssaValue *v = ssa_alloc_instr(p, ssaInstr_If);
	ssaInstr *i = &v->Instr;
	i->If.cond = cond;
	i->If.true_block = true_block;
	i->If.false_block = false_block;
	return v;
}


ssaValue *ssa_make_instr_phi(ssaProcedure *p, Array<ssaValue *> edges, Type *type) {
	ssaValue *v = ssa_alloc_instr(p, ssaInstr_Phi);
	ssaInstr *i = &v->Instr;
	i->Phi.edges = edges;
	i->Phi.type = type;
	return v;
}

ssaValue *ssa_make_instr_unreachable(ssaProcedure *p) {
	ssaValue *v = ssa_alloc_instr(p, ssaInstr_Unreachable);
	return v;
}

ssaValue *ssa_make_instr_return(ssaProcedure *p, ssaValue *value) {
	ssaValue *v = ssa_alloc_instr(p, ssaInstr_Return);
	v->Instr.Return.value = value;
	return v;
}

ssaValue *ssa_make_instr_select(ssaProcedure *p, ssaValue *cond, ssaValue *t, ssaValue *f) {
	ssaValue *v = ssa_alloc_instr(p, ssaInstr_Select);
	v->Instr.Select.cond = cond;
	v->Instr.Select.true_value = t;
	v->Instr.Select.false_value = f;
	return v;
}

ssaValue *ssa_make_instr_call(ssaProcedure *p, ssaValue *value, ssaValue **args, isize arg_count, Type *result_type) {
	ssaValue *v = ssa_alloc_instr(p, ssaInstr_Call);
	v->Instr.Call.value = value;
	v->Instr.Call.args = args;
	v->Instr.Call.arg_count = arg_count;
	v->Instr.Call.type = result_type;
	return v;
}

ssaValue *ssa_make_instr_conv(ssaProcedure *p, ssaConvKind kind, ssaValue *value, Type *from, Type *to) {
	ssaValue *v = ssa_alloc_instr(p, ssaInstr_Conv);
	v->Instr.Conv.kind = kind;
	v->Instr.Conv.value = value;
	v->Instr.Conv.from = from;
	v->Instr.Conv.to = to;
	return v;
}

ssaValue *ssa_make_instr_extract_element(ssaProcedure *p, ssaValue *vector, ssaValue *index) {
	ssaValue *v = ssa_alloc_instr(p, ssaInstr_VectorExtractElement);
	v->Instr.VectorExtractElement.vector = vector;
	v->Instr.VectorExtractElement.index = index;
	return v;
}

ssaValue *ssa_make_instr_insert_element(ssaProcedure *p, ssaValue *vector, ssaValue *elem, ssaValue *index) {
	ssaValue *v = ssa_alloc_instr(p, ssaInstr_VectorInsertElement);
	v->Instr.VectorInsertElement.vector = vector;
	v->Instr.VectorInsertElement.elem   = elem;
	v->Instr.VectorInsertElement.index  = index;
	return v;
}

ssaValue *ssa_make_instr_vector_shuffle(ssaProcedure *p, ssaValue *vector, i32 *indices, isize index_count) {
	ssaValue *v = ssa_alloc_instr(p, ssaInstr_VectorShuffle);
	v->Instr.VectorShuffle.vector      = vector;
	v->Instr.VectorShuffle.indices     = indices;
	v->Instr.VectorShuffle.index_count = index_count;

	Type *vt = base_type(ssa_type(vector));
	v->Instr.VectorShuffle.type = make_type_vector(p->module->allocator, vt->Vector.elem, index_count);

	return v;
}

ssaValue *ssa_make_instr_comment(ssaProcedure *p, String text) {
	ssaValue *v = ssa_alloc_instr(p, ssaInstr_Comment);
	v->Instr.Comment.text = text;
	return v;
}



ssaValue *ssa_make_value_constant(gbAllocator a, Type *type, ExactValue value) {
	ssaValue *v = ssa_alloc_value(a, ssaValue_Constant);
	v->Constant.type  = type;
	v->Constant.value = value;
	return v;
}


ssaValue *ssa_make_value_constant_slice(gbAllocator a, Type *type, ssaValue *backing_array, i64 count) {
	ssaValue *v = ssa_alloc_value(a, ssaValue_ConstantSlice);
	v->ConstantSlice.type = type;
	v->ConstantSlice.backing_array = backing_array;
	v->ConstantSlice.count = count;
	return v;
}

ssaValue *ssa_make_const_int(gbAllocator a, i64 i) {
	return ssa_make_value_constant(a, t_int, make_exact_value_integer(i));
}
ssaValue *ssa_make_const_i32(gbAllocator a, i64 i) {
	return ssa_make_value_constant(a, t_i32, make_exact_value_integer(i));
}
ssaValue *ssa_make_const_i64(gbAllocator a, i64 i) {
	return ssa_make_value_constant(a, t_i64, make_exact_value_integer(i));
}
ssaValue *ssa_make_const_bool(gbAllocator a, b32 b) {
	return ssa_make_value_constant(a, t_bool, make_exact_value_bool(b != 0));
}

ssaValue *ssa_add_module_constant(ssaModule *m, Type *type, ExactValue value) {
	if (is_type_slice(type)) {
		ast_node(cl, CompoundLit, value.value_compound);
		gbAllocator a = m->allocator;

		isize count = cl->elems.count;
		if (count > 0) {
			Type *elem = base_type(type)->Slice.elem;
			Type *t = make_type_array(a, elem, count);
			ssaValue *backing_array = ssa_add_module_constant(m, t, value);


			isize max_len = 7+8+1;
			u8 *str = cast(u8 *)gb_alloc_array(a, u8, max_len);
			isize len = gb_snprintf(cast(char *)str, max_len, "__csba$%x", m->global_array_index);
			m->global_array_index++;

			String name = make_string(str, len-1);

			Entity *e = make_entity_constant(a, NULL, make_token_ident(name), t, value);
			ssaValue *g = ssa_make_value_global(a, e, backing_array);
			ssa_module_add_value(m, e, g);
			map_set(&m->members, hash_string(name), g);

			return ssa_make_value_constant_slice(a, type, g, count);
		} else {
			return ssa_make_value_constant_slice(a, type, NULL, 0);
		}
	}

	return ssa_make_value_constant(m->allocator, type, value);
}


ssaValue *ssa_make_value_procedure(gbAllocator a, ssaModule *m, Entity *entity, Type *type, AstNode *type_expr, AstNode *body, String name) {
	ssaValue *v = ssa_alloc_value(a, ssaValue_Proc);
	v->Proc.module = m;
	v->Proc.entity = entity;
	v->Proc.type   = type;
	v->Proc.type_expr = type_expr;
	v->Proc.body   = body;
	v->Proc.name   = name;
	array_init(&v->Proc.referrers, heap_allocator(), 0); // TODO(bill): replace heap allocator
	return v;
}

ssaValue *ssa_make_value_block(ssaProcedure *proc, AstNode *node, Scope *scope, String label) {
	ssaValue *v = ssa_alloc_value(proc->module->allocator, ssaValue_Block);
	v->Block.label  = label;
	v->Block.node   = node;
	v->Block.scope  = scope;
	v->Block.parent = proc;

	array_init(&v->Block.instrs, heap_allocator());
	array_init(&v->Block.locals, heap_allocator());

	array_init(&v->Block.preds,  heap_allocator());
	array_init(&v->Block.succs,  heap_allocator());

	return v;
}

ssaBlock *ssa_add_block(ssaProcedure *proc, AstNode *node, char *label) {
	Scope *scope = NULL;
	if (node != NULL) {
		Scope **found = map_get(&proc->module->info->scopes, hash_pointer(node));
		if (found) {
			scope = *found;
		} else {
			GB_PANIC("Block scope not found for %.*s", LIT(ast_node_strings[node->kind]));
		}
	}

	ssaValue *value = ssa_make_value_block(proc, node, scope, make_string(label));
	ssaBlock *block = &value->Block;
	array_add(&proc->blocks, block);
	return block;
}





ssaDefer ssa_add_defer_node(ssaProcedure *proc, isize scope_index, AstNode *stmt) {
	ssaDefer d = {ssaDefer_Node};
	d.scope_index = scope_index;
	d.block = proc->curr_block;
	d.stmt = stmt;
	array_add(&proc->defer_stmts, d);
	return d;
}


ssaDefer ssa_add_defer_instr(ssaProcedure *proc, isize scope_index, ssaValue *instr) {
	ssaDefer d = {ssaDefer_Instr};
	d.scope_index = proc->scope_index;
	d.block = proc->curr_block;
	d.instr = instr; // NOTE(bill): It will make a copy everytime it is called
	array_add(&proc->defer_stmts, d);
	return d;
}





