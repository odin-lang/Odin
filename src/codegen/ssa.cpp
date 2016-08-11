struct ssaModule;
struct ssaProcedure;
struct ssaBlock;
struct ssaValue;


struct ssaModule {
	CheckerInfo * info;
	BaseTypeSizes sizes;
	gbArena       arena;
	gbAllocator   allocator;

	String layout;

	Map<ssaValue *> values;  // Key: Entity *
	Map<ssaValue *> members; // Key: String
	i32 global_string_index;
};


struct ssaBlock {
	i32 id;
	AstNode *node;
	Scope *scope;
	String label;
	ssaProcedure *parent;

	gbArray(ssaValue *) instrs;
	gbArray(ssaValue *) values;
};

struct ssaTargetList {
	ssaTargetList *prev;
	ssaBlock *     break_;
	ssaBlock *     continue_;
	ssaBlock *     fallthrough_;
};

struct ssaProcedure {
	ssaProcedure *parent;
	ssaModule *   module;
	String        name;
	Type *        type;
	AstNode *     type_expr;
	AstNode *     body;

	gbArray(ssaBlock *) blocks;
	ssaBlock *          curr_block;
	ssaTargetList *     target_list;

	gbArray(ssaProcedure *) anon_procs;
	gbArray(ssaProcedure *) nested_procs;
};



#define SSA_INSTR_KINDS \
	SSA_INSTR_KIND(Invalid), \
	SSA_INSTR_KIND(Local), \
	SSA_INSTR_KIND(Store), \
	SSA_INSTR_KIND(Load), \
	SSA_INSTR_KIND(GetElementPtr), \
	SSA_INSTR_KIND(ExtractValue), \
	SSA_INSTR_KIND(Conv), \
	SSA_INSTR_KIND(Br), \
	SSA_INSTR_KIND(Ret), \
	SSA_INSTR_KIND(Select), \
	SSA_INSTR_KIND(Unreachable), \
	SSA_INSTR_KIND(BinaryOp), \
	SSA_INSTR_KIND(Call), \
	SSA_INSTR_KIND(CopyMemory), \
	SSA_INSTR_KIND(Count),

enum ssaInstrKind {
#define SSA_INSTR_KIND(x) GB_JOIN2(ssaInstr_, x)
	SSA_INSTR_KINDS
#undef SSA_INSTR_KIND
};

String const ssa_instr_strings[] = {
#define SSA_INSTR_KIND(x) {cast(u8 *)#x, gb_size_of(#x)-1}
	SSA_INSTR_KINDS
#undef SSA_INSTR_KIND
};

#define SSA_CONV_KINDS \
	SSA_CONV_KIND(Invalid), \
	SSA_CONV_KIND(trunc), \
	SSA_CONV_KIND(zext), \
	SSA_CONV_KIND(fptrunc), \
	SSA_CONV_KIND(fpext), \
	SSA_CONV_KIND(fptoui), \
	SSA_CONV_KIND(fptosi), \
	SSA_CONV_KIND(uitofp), \
	SSA_CONV_KIND(sitofp), \
	SSA_CONV_KIND(ptrtoint), \
	SSA_CONV_KIND(inttoptr), \
	SSA_CONV_KIND(bitcast), \
	SSA_CONV_KIND(Count)

enum ssaConvKind {
#define SSA_CONV_KIND(x) GB_JOIN2(ssaConv_, x)
	SSA_CONV_KINDS
#undef SSA_CONV_KIND
};

String const ssa_conv_strings[] = {
#define SSA_CONV_KIND(x) {cast(u8 *)#x, gb_size_of(#x)-1}
	SSA_CONV_KINDS
#undef SSA_CONV_KIND
};

struct ssaInstr {
	ssaInstrKind kind;

	ssaBlock *parent;
	Type *type;
	TokenPos pos;

	union {
		struct {
			Entity *entity;
			Type *type;
		} local;
		struct {
			ssaValue *address;
			ssaValue *value;
		} store;
		struct {
			Type *type;
			ssaValue *address;
		} load;
		struct {
			ssaValue *address;
			Type *    result_type;
			Type *    elem_type;
			ssaValue *indices[2];
			isize     index_count;
			b32       inbounds;
		} get_element_ptr;
		struct {
			ssaValue *address;
			Type *    result_type;
			Type *    elem_type;
			i32       index;
		} extract_value;
		struct {
			ssaConvKind kind;
			ssaValue *value;
			Type *from, *to;
		} conv;
		struct {
			ssaValue *cond;
			ssaBlock *true_block;
			ssaBlock *false_block;
		} br;
		struct { ssaValue *value; } ret;
		struct {} unreachable;
		struct {
			ssaValue *cond;
			ssaValue *true_value;
			ssaValue *false_value;
		} select;
		struct {
			Type *type;
			Token op;
			ssaValue *left, *right;
		} binary_op;
		struct {
			Type *type; // return type
			ssaValue *value;
			ssaValue **args;
			isize arg_count;
		} call;
		struct {
			ssaValue *dst, *src;
			ssaValue *len;
			i32 align;
			b32 is_volatile;
		} copy_memory;
	};
};


enum ssaValueKind {
	ssaValue_Invalid,

	ssaValue_Constant,
	ssaValue_TypeName,
	ssaValue_Global,
	ssaValue_Param,
	ssaValue_GlobalString,

	ssaValue_Proc,
	ssaValue_Block,
	ssaValue_Instr,

	ssaValue_Count,
};

struct ssaValue {
	ssaValueKind kind;
	i32 id;

	union {
		struct {
			Type *     type;
			ExactValue value;
		} constant;
		struct {
			Entity *entity;
			Type *  type;
		} type_name;
		struct {
			b32 is_constant;
			Entity *  entity;
			Type *    type;
			ssaValue *value;
		} global;
		struct {
			ssaProcedure *parent;
			Entity *entity;
			Type *  type;
		} param;
		ssaProcedure proc;
		ssaBlock     block;
		ssaInstr     instr;
	};
};

gb_global ssaValue *v_zero    = NULL;
gb_global ssaValue *v_one     = NULL;
gb_global ssaValue *v_zero32  = NULL;
gb_global ssaValue *v_one32   = NULL;
gb_global ssaValue *v_two32   = NULL;
gb_global ssaValue *v_false   = NULL;
gb_global ssaValue *v_true    = NULL;

enum ssaLvalueKind {
	ssaLvalue_Blank,
	ssaLvalue_Address,

	ssaLvalue_Count,
};

struct ssaLvalue {
	ssaLvalueKind kind;
	union {
		struct {} blank;
		struct {
			ssaValue *value;
			AstNode *expr;
		} address;
	};
};





ssaLvalue ssa_make_lvalue_address(ssaValue *value, AstNode *expr) {
	ssaLvalue lval = {ssaLvalue_Address};
	lval.address.value = value;
	lval.address.expr = expr;
	return lval;
}


void ssa_module_init(ssaModule *m, Checker *c) {
	isize token_count = c->parser->total_token_count;
	isize arena_size = 3 * token_count * gb_size_of(ssaValue);
	gb_arena_init_from_allocator(&m->arena, gb_heap_allocator(), arena_size);
	m->allocator = gb_arena_allocator(&m->arena);
	m->info = &c->info;
	m->sizes = c->sizes;

	map_init(&m->values,  m->allocator);
	map_init(&m->members, m->allocator);
}

void ssa_module_destroy(ssaModule *m) {
	map_destroy(&m->values);
	map_destroy(&m->members);
	gb_arena_free(&m->arena);
}

void ssa_module_add_value(ssaModule *m, Entity *e, ssaValue *v) {
	map_set(&m->values, hash_pointer(e), v);
}


Type *ssa_value_type(ssaValue *value);
void  ssa_value_set_type(ssaValue *value, Type *type);

Type *ssa_instr_type(ssaInstr *instr) {
	switch (instr->kind) {
	case ssaInstr_Local:
		return instr->local.type;
	case ssaInstr_Store:
		return ssa_value_type(instr->store.address);
	case ssaInstr_Load:
		return instr->load.type;
	case ssaInstr_GetElementPtr:
		return instr->get_element_ptr.result_type;
	case ssaInstr_ExtractValue:
		return instr->extract_value.result_type;
	case ssaInstr_BinaryOp:
		return instr->binary_op.type;
	case ssaInstr_Conv:
		return instr->conv.to;
	case ssaInstr_Select:
		return ssa_value_type(instr->select.true_value);
	case ssaInstr_Call: {
		Type *pt = instr->call.type;
		GB_ASSERT(pt->kind == Type_Proc);
		auto *tuple = &pt->proc.results->tuple;
		if (tuple->variable_count != 1)
			return pt->proc.results;
		else
			return tuple->variables[0]->type;
	}
	case ssaInstr_CopyMemory:
		return t_int;
	}
	return NULL;
}

void ssa_instr_set_type(ssaInstr *instr, Type *type) {
	switch (instr->kind) {
	case ssaInstr_Local:
		instr->local.type = type;
		break;
	case ssaInstr_Store:
		ssa_value_set_type(instr->store.value, type);
		break;
	case ssaInstr_Load:
		instr->load.type = type;
		break;
	case ssaInstr_GetElementPtr:
		instr->get_element_ptr.result_type = type;
		break;
	case ssaInstr_ExtractValue:
		instr->extract_value.result_type = type;
		break;
	case ssaInstr_BinaryOp:
		instr->binary_op.type = type;
		break;
	case ssaInstr_Conv:
		instr->conv.to = type;
		break;
	case ssaInstr_Call:
		instr->call.type = type;
		break;
	}
}

Type *ssa_value_type(ssaValue *value) {
	switch (value->kind) {
	case ssaValue_Constant:
		return value->constant.type;
	case ssaValue_TypeName:
		return value->type_name.type;
	case ssaValue_Global:
		return value->global.type;
	case ssaValue_Param:
		return value->param.type;
	case ssaValue_Proc:
		return value->proc.type;
	case ssaValue_Instr:
		return ssa_instr_type(&value->instr);
	}
	return NULL;
}


void ssa_value_set_type(ssaValue *value, Type *type) {
	switch (value->kind) {
	case ssaValue_TypeName:
		value->type_name.type = type;
		break;
	case ssaValue_Global:
		value->global.type = type;
		break;
	case ssaValue_Proc:
		value->proc.type = type;
		break;
	case ssaValue_Constant:
		value->constant.type = type;
		break;
	case ssaValue_Instr:
		ssa_instr_set_type(&value->instr, type);
		break;
	}
}



ssaValue *ssa_build_expr(ssaProcedure *proc, AstNode *expr);
ssaValue *ssa_build_single_expr(ssaProcedure *proc, AstNode *expr, TypeAndValue *tv);
ssaLvalue ssa_build_addr(ssaProcedure *proc, AstNode *expr);
ssaValue *ssa_emit_conv(ssaProcedure *proc, ssaValue *value, Type *a_type);
void      ssa_build_proc(ssaValue *value, ssaProcedure *parent);




ssaValue *ssa_alloc_value(gbAllocator a, ssaValueKind kind) {
	ssaValue *v = gb_alloc_item(a, ssaValue);
	v->kind = kind;
	return v;
}

ssaValue *ssa_alloc_instr(gbAllocator a, ssaInstrKind kind) {
	ssaValue *v = ssa_alloc_value(a, ssaValue_Instr);
	v->instr.kind = kind;
	return v;
}

ssaValue *ssa_make_value_type_name(gbAllocator a, Entity *e) {
	ssaValue *v = ssa_alloc_value(a, ssaValue_TypeName);
	v->type_name.entity = e;
	v->type_name.type = e->type;
	return v;
}

ssaValue *ssa_make_value_global(gbAllocator a, Entity *e, ssaValue *value) {
	ssaValue *v = ssa_alloc_value(a, ssaValue_Global);
	v->global.entity = e;
	v->global.type = e->type;
	v->global.value = value;
	return v;
}
ssaValue *ssa_make_value_param(gbAllocator a, ssaProcedure *parent, Entity *e) {
	ssaValue *v = ssa_alloc_value(a, ssaValue_Param);
	v->param.parent = parent;
	v->param.entity = e;
	v->param.type   = e->type;
	return v;
}


ssaValue *ssa_make_instr_local(ssaProcedure *p, Entity *e) {
	ssaValue *v = ssa_alloc_instr(p->module->allocator, ssaInstr_Local);
	ssaInstr *i = &v->instr;
	i->local.entity = e;
	i->local.type = e->type;
	if (p->curr_block) {
		gb_array_append(p->curr_block->values, v);
	}
	ssa_module_add_value(p->module, e, v);
	return v;
}


ssaValue *ssa_make_instr_store(ssaProcedure *p, ssaValue *address, ssaValue *value) {
	ssaValue *v = ssa_alloc_instr(p->module->allocator, ssaInstr_Store);
	ssaInstr *i = &v->instr;
	i->store.address = address;
	i->store.value = value;
	if (p->curr_block) {
		gb_array_append(p->curr_block->values, v);
	}
	return v;
}

ssaValue *ssa_make_instr_load(ssaProcedure *p, ssaValue *address) {
	ssaValue *v = ssa_alloc_instr(p->module->allocator, ssaInstr_Load);
	ssaInstr *i = &v->instr;
	i->load.address = address;
	i->load.type = ssa_value_type(address);
	if (p->curr_block) {
		gb_array_append(p->curr_block->values, v);
	}
	return v;
}

ssaValue *ssa_make_instr_get_element_ptr(ssaProcedure *p, ssaValue *address,
                                               ssaValue *index0, ssaValue *index1, isize index_count,
                                               b32 inbounds) {
	ssaValue *v = ssa_alloc_instr(p->module->allocator, ssaInstr_GetElementPtr);
	ssaInstr *i = &v->instr;
	i->get_element_ptr.address = address;
	i->get_element_ptr.indices[0]   = index0;
	i->get_element_ptr.indices[1]   = index1;
	i->get_element_ptr.index_count  = index_count;
	i->get_element_ptr.elem_type = ssa_value_type(address);
	i->get_element_ptr.inbounds     = inbounds;
	if (p->curr_block) {
		gb_array_append(p->curr_block->values, v);
	}
	return v;
}

ssaValue *ssa_make_instr_extract_value(ssaProcedure *p, ssaValue *address, i32 index, Type *result_type) {
	ssaValue *v = ssa_alloc_instr(p->module->allocator, ssaInstr_ExtractValue);
	ssaInstr *i = &v->instr;
	i->extract_value.address = address;
	i->extract_value.index = index;
	i->extract_value.result_type = result_type;
	Type *et = ssa_value_type(address);
	i->extract_value.elem_type = et;
	GB_ASSERT(et->kind == Type_Structure || et->kind == Type_Array || et->kind == Type_Tuple);
	if (p->curr_block) {
		gb_array_append(p->curr_block->values, v);
	}
	return v;
}


ssaValue *ssa_make_instr_binary_op(ssaProcedure *p, Token op, ssaValue *left, ssaValue *right) {
	ssaValue *v = ssa_alloc_instr(p->module->allocator, ssaInstr_BinaryOp);
	ssaInstr *i = &v->instr;
	i->binary_op.op = op;
	i->binary_op.left = left;
	i->binary_op.right = right;
	if (p->curr_block) {
		gb_array_append(p->curr_block->values, v);
	}
	return v;
}

ssaValue *ssa_make_instr_br(ssaProcedure *p, ssaValue *cond, ssaBlock *true_block, ssaBlock *false_block) {
	ssaValue *v = ssa_alloc_instr(p->module->allocator, ssaInstr_Br);
	ssaInstr *i = &v->instr;
	i->br.cond = cond;
	i->br.true_block = true_block;
	i->br.false_block = false_block;
	if (p->curr_block) {
		gb_array_append(p->curr_block->values, v);
	}
	return v;
}

ssaValue *ssa_make_instr_unreachable(ssaProcedure *p) {
	ssaValue *v = ssa_alloc_instr(p->module->allocator, ssaInstr_Unreachable);
	if (p->curr_block) {
		gb_array_append(p->curr_block->values, v);
	}
	return v;
}

ssaValue *ssa_make_instr_ret(ssaProcedure *p, ssaValue *value) {
	ssaValue *v = ssa_alloc_instr(p->module->allocator, ssaInstr_Ret);
	v->instr.ret.value = value;
	if (p->curr_block) {
		gb_array_append(p->curr_block->values, v);
	}
	return v;
}

ssaValue *ssa_make_instr_select(ssaProcedure *p, ssaValue *cond, ssaValue *t, ssaValue *f) {
	ssaValue *v = ssa_alloc_instr(p->module->allocator, ssaInstr_Select);
	v->instr.select.cond = cond;
	v->instr.select.true_value = t;
	v->instr.select.false_value = f;
	if (p->curr_block) {
		gb_array_append(p->curr_block->values, v);
	}
	return v;
}

ssaValue *ssa_make_instr_call(ssaProcedure *p, ssaValue *value, ssaValue **args, isize arg_count, Type *result_type) {
	ssaValue *v = ssa_alloc_instr(p->module->allocator, ssaInstr_Call);
	v->instr.call.value = value;
	v->instr.call.args = args;
	v->instr.call.arg_count = arg_count;
	v->instr.call.type = result_type;
	if (p->curr_block) {
		gb_array_append(p->curr_block->values, v);
	}
	return v;
}

ssaValue *ssa_make_instr_copy_memory(ssaProcedure *p, ssaValue *dst, ssaValue *src, ssaValue *len, i32 align, b32 is_volatile) {
	ssaValue *v = ssa_alloc_instr(p->module->allocator, ssaInstr_CopyMemory);
	v->instr.copy_memory.dst = dst;
	v->instr.copy_memory.src = src;
	v->instr.copy_memory.len = len;
	v->instr.copy_memory.align = align;
	v->instr.copy_memory.is_volatile = is_volatile;
	if (p->curr_block) {
		gb_array_append(p->curr_block->values, v);
	}
	return v;
}

ssaValue *ssa_make_instr_conv(ssaProcedure *p, ssaConvKind kind, ssaValue *value, Type *from, Type *to) {
	ssaValue *v = ssa_alloc_instr(p->module->allocator, ssaInstr_Conv);
	v->instr.conv.kind = kind;
	v->instr.conv.value = value;
	v->instr.conv.from = from;
	v->instr.conv.to = to;
	if (p->curr_block) {
		gb_array_append(p->curr_block->values, v);
	}
	return v;
}




ssaValue *ssa_make_value_constant(gbAllocator a, Type *type, ExactValue value) {
	ssaValue *v = ssa_alloc_value(a, ssaValue_Constant);
	v->constant.type  = type;
	v->constant.value = value;
	return v;
}

ssaValue *ssa_make_value_procedure(gbAllocator a, ssaModule *m, Type *type, AstNode *type_expr, AstNode *body, String name) {
	ssaValue *v = ssa_alloc_value(a, ssaValue_Proc);
	v->proc.module = m;
	v->proc.type   = type;
	v->proc.type_expr = type_expr;
	v->proc.body   = body;
	v->proc.name   = name;
	return v;
}

ssaValue *ssa_make_value_block(ssaProcedure *proc, AstNode *node, Scope *scope, String label) {
	ssaValue *v = ssa_alloc_value(proc->module->allocator, ssaValue_Block);
	v->block.label  = label;
	v->block.node   = node;
	v->block.scope  = scope;
	v->block.parent = proc;

	gb_array_init(v->block.instrs, gb_heap_allocator());
	gb_array_init(v->block.values, gb_heap_allocator());

	return v;
}

b32 ssa_is_blank_ident(AstNode *node) {
	if (node->kind == AstNode_Ident) {
		ast_node(i, Ident, node);
		return are_strings_equal(i->token.string, make_string("_"));
	}
	return false;
}


ssaInstr *ssa_get_last_instr(ssaBlock *block) {
	isize len = gb_array_count(block->instrs);
	if (len > 0) {
		ssaValue *v = block->instrs[len-1];
		GB_ASSERT(v->kind == ssaValue_Instr);
		return &v->instr;
	}
	return NULL;

}

b32 ssa_is_instr_terminating(ssaInstr *i) {
	if (i != NULL) {
		switch (i->kind) {
		case ssaInstr_Ret:
		case ssaInstr_Unreachable:
			return true;
		}
	}

	return false;
}

ssaValue *ssa_emit(ssaProcedure *proc, ssaValue *instr) {
	ssaBlock *b = proc->curr_block;
	instr->instr.parent = b;
	if (b) {
		ssaInstr *i = ssa_get_last_instr(b);
		if (!ssa_is_instr_terminating(i)) {
			gb_array_append(b->instrs, instr);
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


ssaValue *ssa_add_local(ssaProcedure *proc, Entity *e) {
	return ssa_emit(proc, ssa_make_instr_local(proc, e));
}

ssaValue *ssa_add_local_for_identifier(ssaProcedure *proc, AstNode *name) {
	Entity **found = map_get(&proc->module->info->definitions, hash_pointer(name));
	if (found) {
		return ssa_add_local(proc, *found);
	}
	return NULL;
}

ssaValue *ssa_add_local_generated(ssaProcedure *proc, Type *type) {
	Entity *entity = make_entity_variable(proc->module->allocator,
	                                      proc->curr_block->scope,
	                                      empty_token,
	                                      type);
	return ssa_emit(proc, ssa_make_instr_local(proc, entity));
}

ssaValue *ssa_add_param(ssaProcedure *proc, Entity *e) {
	ssaValue *v = ssa_make_value_param(proc->module->allocator, proc, e);
	ssaValue *l = ssa_add_local(proc, e);
	ssa_emit_store(proc, l, v);
	return v;
}


ssaValue *ssa_lvalue_store(ssaLvalue lval, ssaProcedure *p, ssaValue *value) {
	switch (lval.kind) {
	case ssaLvalue_Address:
		return ssa_emit_store(p, lval.address.value, value);
	}
	return NULL;
}

ssaValue *ssa_lvalue_load(ssaLvalue lval, ssaProcedure *p) {
	switch (lval.kind) {
	case ssaLvalue_Address:
		return ssa_emit_load(p, lval.address.value);
	}
	GB_PANIC("Illegal lvalue load");
	return NULL;
}


ssaValue *ssa_lvalue_address(ssaLvalue lval, ssaProcedure *p) {
	switch (lval.kind) {
	case ssaLvalue_Address:
		return lval.address.value;
	}
	return NULL;
}

Type *ssa_lvalue_type(ssaLvalue lval) {
	switch (lval.kind) {
	case ssaLvalue_Address:
		// return type_deref(ssa_value_type(lval.address.value));
		return ssa_value_type(lval.address.value);
	}
	return NULL;
}


void ssa_build_stmt(ssaProcedure *proc, AstNode *s);

void ssa_emit_defer_stmts(ssaProcedure *proc, ssaBlock *block) {
	if (block == NULL)
		return;

	// IMPORTANT TODO(bill): ssa defer - Place where needed!!!

#if 0
	Scope *curr_scope = block->scope;
	if (curr_scope == NULL) {
		// GB_PANIC("No scope found for deferred statements");
	}

	for (Scope *s = curr_scope; s != NULL; s = s->parent) {
		isize count = gb_array_count(s->deferred_stmts);
		for (isize i = count-1; i >= 0; i--) {
			ssa_build_stmt(proc, s->deferred_stmts[i]);
		}
	}
#endif
}

void ssa_emit_unreachable(ssaProcedure *proc) {
	ssa_emit(proc, ssa_make_instr_unreachable(proc));
}

void ssa_emit_ret(ssaProcedure *proc, ssaValue *v) {
	ssa_emit_defer_stmts(proc, proc->curr_block);
	ssa_emit(proc, ssa_make_instr_ret(proc, v));
}

void ssa_emit_jump(ssaProcedure *proc, ssaBlock *block) {
	ssa_emit(proc, ssa_make_instr_br(proc, NULL, block, NULL));
	proc->curr_block = NULL;
}

void ssa_emit_if(ssaProcedure *proc, ssaValue *cond, ssaBlock *true_block, ssaBlock *false_block) {
	ssaValue *br = ssa_make_instr_br(proc, cond, true_block, false_block);
	ssa_emit(proc, br);
	proc->curr_block = NULL;
}




ssaBlock *ssa__make_block(ssaProcedure *proc, AstNode *node, String label) {
	Scope *scope = NULL;
	if (node != NULL) {
		Scope **found = map_get(&proc->module->info->scopes, hash_pointer(node));
		if (found) {
			scope = *found;
		} else {
			GB_PANIC("Block scope not found for %.*s", LIT(ast_node_strings[node->kind]));
		}
	}

	ssaValue *block = ssa_make_value_block(proc, node, scope, label);
	return &block->block;
}

ssaBlock *ssa_add_block(ssaProcedure *proc, AstNode *node, String label) {
	ssaBlock *block = ssa__make_block(proc, node, label);
	gb_array_append(proc->blocks, block);
	return block;
}


void ssa_begin_procedure_body(ssaProcedure *proc) {
	gb_array_init(proc->blocks, gb_heap_allocator());
	proc->curr_block = ssa_add_block(proc, proc->type_expr, make_string("entry"));

	if (proc->type->proc.params != NULL) {
		auto *params = &proc->type->proc.params->tuple;
		for (isize i = 0; i < params->variable_count; i++) {
			Entity *e = params->variables[i];
			ssa_add_param(proc, e);
		}
	}
}

void ssa_end_procedure_body(ssaProcedure *proc) {
	if (proc->type->proc.result_count == 0) {
		ssa_emit_ret(proc, NULL);
	}

// Number blocks and registers
	i32 reg_id = 0;
	gb_for_array(i, proc->blocks) {
		ssaBlock *b = proc->blocks[i];
		b->id = i;
		gb_for_array(j, b->instrs) {
			ssaValue *value = b->instrs[j];
			GB_ASSERT(value->kind == ssaValue_Instr);
			ssaInstr *instr = &value->instr;
			// NOTE(bill): Ignore non-returning instructions
			switch (instr->kind) {
			case ssaInstr_Store:
			case ssaInstr_Br:
			case ssaInstr_Ret:
			case ssaInstr_Unreachable:
			case ssaInstr_CopyMemory:
				continue;
			case ssaInstr_Call:
				if (instr->call.type->proc.results == NULL) {
					continue;
				}
				break;
			}
			value->id = reg_id;
			reg_id++;
		}
	}
}

void ssa_push_target_list(ssaProcedure *proc, ssaBlock *break_, ssaBlock *continue_, ssaBlock *fallthrough_) {
	ssaTargetList *tl = gb_alloc_item(proc->module->allocator, ssaTargetList);
	tl->prev          = proc->target_list;
	tl->break_        = break_;
	tl->continue_     = continue_;
	tl->fallthrough_  = fallthrough_;
	proc->target_list = tl;
}

void ssa_pop_target_list(ssaProcedure *proc) {
	proc->target_list = proc->target_list->prev;
}



ssaValue *ssa_emit_arith(ssaProcedure *proc, Token op, ssaValue *left, ssaValue *right, Type *type) {
	switch (op.kind) {
	case Token_AndNot: {
		// NOTE(bill): x &~ y == x & (~y) == x & (y ~ -1)
		// NOTE(bill): "not" `x` == `x` "xor" `-1`
		ssaValue *neg = ssa_make_value_constant(proc->module->allocator, type, make_exact_value_integer(-1));
		op.kind = Token_Xor;
		right = ssa_emit_arith(proc, op, right, neg, type);
		ssa_value_set_type(right, type);
		op.kind = Token_And;
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

	ssaValue *v = ssa_make_instr_binary_op(proc, op, left, right);
	ssa_value_set_type(v, type);
	return ssa_emit(proc, v);
}

ssaValue *ssa_emit_comp(ssaProcedure *proc, Token op, ssaValue *left, ssaValue *right) {
	Type *a = get_base_type(ssa_value_type(left));
	Type *b = get_base_type(ssa_value_type(right));

	if (are_types_identical(a, b)) {
		// NOTE(bill): No need for a conversion
	} else if (left->kind == ssaValue_Constant) {
		left = ssa_emit_conv(proc, left, ssa_value_type(right));
	} else if (right->kind == ssaValue_Constant) {
		right = ssa_emit_conv(proc, right, ssa_value_type(left));
	}

	ssaValue *v = ssa_make_instr_binary_op(proc, op, left, right);
	ssa_value_set_type(v, t_bool);
	return ssa_emit(proc, v);
}

ssaValue *ssa_emit_ptr_offset(ssaProcedure *proc, ssaValue *ptr, ssaValue *offset) {
	Type *type = ssa_value_type(ptr);
	ssaValue *gep = NULL;
	offset = ssa_emit_conv(proc, offset, t_int);
	gep = ssa_make_instr_get_element_ptr(proc, ptr, offset, NULL, 1, false);
	gep->instr.get_element_ptr.elem_type = type_deref(type);
	gep->instr.get_element_ptr.result_type  = type;
	return ssa_emit(proc, gep);
}

ssaValue *ssa_emit_struct_gep(ssaProcedure *proc, ssaValue *s, ssaValue *index, Type *result_type) {
	ssaValue *gep = NULL;
	// NOTE(bill): For some weird legacy reason in LLVM, structure elements must be accessed as an i32
	index = ssa_emit_conv(proc, index, t_i32);
	gep = ssa_make_instr_get_element_ptr(proc, s, v_zero, index, 2, true);
	gep->instr.get_element_ptr.elem_type = ssa_value_type(s);
	gep->instr.get_element_ptr.result_type = result_type;

	return ssa_emit(proc, gep);
}

ssaValue *ssa_emit_struct_gep(ssaProcedure *proc, ssaValue *s, i32 index, Type *result_type) {
	ssaValue *i = ssa_make_value_constant(proc->module->allocator, t_i32, make_exact_value_integer(index));
	return ssa_emit_struct_gep(proc, s, i, result_type);
}


ssaValue *ssa_emit_struct_ev(ssaProcedure *proc, ssaValue *s, i32 index, Type *result_type) {
	// NOTE(bill): For some weird legacy reason in LLVM, structure elements must be accessed as an i32
	return ssa_emit(proc, ssa_make_instr_extract_value(proc, s, index, result_type));
}



ssaValue *ssa_array_elem(ssaProcedure *proc, ssaValue *array) {
	Type *t = ssa_value_type(array);
	GB_ASSERT(t->kind == Type_Array);
	Type *base_type = t->array.elem;
	ssaValue *elem = ssa_make_instr_get_element_ptr(proc, array, v_zero, v_zero, 2, true);
	Type *result_type = make_type_pointer(proc->module->allocator, base_type);
	elem->instr.get_element_ptr.elem_type = t;
	elem->instr.get_element_ptr.result_type = result_type;
	return ssa_emit(proc, elem);
}
ssaValue *ssa_array_len(ssaProcedure *proc, ssaValue *array) {
	Type *t = ssa_value_type(array);
	GB_ASSERT(t->kind == Type_Array);
	return ssa_make_value_constant(proc->module->allocator, t_int, make_exact_value_integer(t->array.count));
}
ssaValue *ssa_array_cap(ssaProcedure *proc, ssaValue *array) {
	return ssa_array_len(proc, array);
}

ssaValue *ssa_slice_elem(ssaProcedure *proc, ssaValue *slice) {
	Type *t = ssa_value_type(slice);
	GB_ASSERT(t->kind == Type_Slice);

	Type *result_type = make_type_pointer(proc->module->allocator, t->slice.elem);
	return ssa_emit_load(proc, ssa_emit_struct_gep(proc, slice, v_zero32, result_type));
}
ssaValue *ssa_slice_len(ssaProcedure *proc, ssaValue *slice) {
	Type *t = ssa_value_type(slice);
	GB_ASSERT(t->kind == Type_Slice);
	return ssa_emit_load(proc, ssa_emit_struct_gep(proc, slice, v_one32, t_int));
}
ssaValue *ssa_slice_cap(ssaProcedure *proc, ssaValue *slice) {
	Type *t = ssa_value_type(slice);
	GB_ASSERT(t->kind == Type_Slice);
	return ssa_emit_load(proc, ssa_emit_struct_gep(proc, slice, v_two32, t_int));
}

ssaValue *ssa_string_elem(ssaProcedure *proc, ssaValue *string) {
	Type *t = ssa_value_type(string);
	GB_ASSERT(t->kind == Type_Basic && t->basic.kind == Basic_string);
	Type *base_type = t_u8;
	ssaValue *elem = ssa_make_instr_get_element_ptr(proc, string, v_zero, v_zero32, 2, true);
	Type *result_type = make_type_pointer(proc->module->allocator, base_type);
	elem->instr.get_element_ptr.elem_type = t;
	elem->instr.get_element_ptr.result_type = result_type;
	ssa_emit(proc, elem);

	return ssa_emit_load(proc, elem);
}
ssaValue *ssa_string_len(ssaProcedure *proc, ssaValue *string) {
	Type *t = ssa_value_type(string);
	GB_ASSERT(t->kind == Type_Basic && t->basic.kind == Basic_string);
	return ssa_emit_load(proc, ssa_emit_struct_gep(proc, string, v_one32, t_int));
}



ssaValue *ssa_emit_slice(ssaProcedure *proc, Type *slice_type, ssaValue *base, ssaValue *low, ssaValue *high, ssaValue *max) {
	// TODO(bill): array bounds checking for slice creation
	// TODO(bill): check that low < high <= max
	gbAllocator a = proc->module->allocator;
	Type *base_type = get_base_type(ssa_value_type(base));

	if (low == NULL) {
		low = v_zero;
	}
	if (high == NULL) {
		switch (base_type->kind) {
		case Type_Array:   high = ssa_array_len(proc, base); break;
		case Type_Slice:   high = ssa_slice_len(proc, base); break;
		case Type_Pointer: high = v_one;                     break;
		}
	}
	if (max == NULL) {
		switch (base_type->kind) {
		case Type_Array:   max = ssa_array_cap(proc, base); break;
		case Type_Slice:   max = ssa_slice_cap(proc, base); break;
		case Type_Pointer: max = high;                      break;
		}
	}
	GB_ASSERT(max != NULL);

	Token op_sub = {Token_Sub};
	ssaValue *len = ssa_emit_arith(proc, op_sub, high, low, t_int);
	ssaValue *cap = ssa_emit_arith(proc, op_sub, max,  low, t_int);

	ssaValue *elem = NULL;
	switch (base_type->kind) {
	case Type_Array:   elem = ssa_array_elem(proc, base); break;
	case Type_Slice:   elem = ssa_slice_elem(proc, base); break;
	case Type_Pointer: elem = base;                       break;
	}

	elem = ssa_emit_ptr_offset(proc, elem, low);

	ssaValue *slice = ssa_add_local_generated(proc, slice_type);

	ssaValue *gep = NULL;
	gep = ssa_emit_struct_gep(proc, slice, v_zero32, ssa_value_type(elem));
	ssa_emit_store(proc, gep, elem);

	gep = ssa_emit_struct_gep(proc, slice, v_one32, t_int);
	ssa_emit_store(proc, gep, len);

	gep = ssa_emit_struct_gep(proc, slice, v_two32, t_int);
	ssa_emit_store(proc, gep, cap);

	return slice;
}

ssaValue *ssa_emit_substring(ssaProcedure *proc, ssaValue *base, ssaValue *low, ssaValue *high) {
	Type *bt = get_base_type(ssa_value_type(base));
	GB_ASSERT(bt == t_string);
	if (low == NULL) {
		low = v_zero;
	}
	if (high == NULL) {
		high = ssa_string_len(proc, base);
	}

	Token op_sub = {Token_Sub};
	ssaValue *elem, *len;
	len = ssa_emit_arith(proc, op_sub, high, low, t_int);

	elem = ssa_string_elem(proc, base);
	elem = ssa_emit_ptr_offset(proc, elem, low);

	ssaValue *str, *gep;
	str = ssa_add_local_generated(proc, t_string);
	gep = ssa_emit_struct_gep(proc, str, v_zero32, ssa_value_type(elem));
	ssa_emit_store(proc, gep, elem);

	gep = ssa_emit_struct_gep(proc, str, v_one32, t_int);
	ssa_emit_store(proc, gep, len);

	return str;
}


ssaValue *ssa_add_global_string_array(ssaProcedure *proc, ExactValue value) {
	GB_ASSERT(value.kind == ExactValue_String);
	gbAllocator a = gb_heap_allocator();

	isize max_len = 4+8+1;
	u8 *str = cast(u8 *)gb_alloc_array(a, u8, max_len);
	isize len = gb_snprintf(cast(char *)str, max_len, ".str%x", proc->module->global_string_index);
	proc->module->global_string_index++;

	String name = make_string(str, len-1);
	Token token = {Token_String};
	token.string = name;
	Type *type = make_type_array(a, t_u8, value.value_string.len);
	Entity *entity = make_entity_constant(a, NULL, token, type, value);
	ssaValue *g = ssa_make_value_global(a, entity, ssa_make_value_constant(a, type, value));

	map_set(&proc->module->values, hash_pointer(entity), g);
	map_set(&proc->module->members, hash_string(name), g);

	return g;
}

ssaValue *ssa_emit_string(ssaProcedure *proc, ssaValue *elem, ssaValue *len) {
	Type *t_u8_ptr = ssa_value_type(elem);
	GB_ASSERT(t_u8_ptr->kind == Type_Pointer);

	GB_ASSERT(is_type_u8(t_u8_ptr->pointer.elem));

	ssaValue *str = ssa_add_local_generated(proc, t_string);
	ssaValue *str_elem = ssa_emit_struct_gep(proc, str, v_zero32, t_u8_ptr);
	ssaValue *str_len = ssa_emit_struct_gep(proc, str, v_one32, t_int);
	ssa_emit_store(proc, str_elem, elem);
	ssa_emit_store(proc, str_len, len);
	return str;
}




ssaValue *ssa_emit_conv(ssaProcedure *proc, ssaValue *value, Type *t) {
	Type *src_type = ssa_value_type(value);
	if (are_types_identical(t, src_type))
		return value;

	Type *src = get_base_type(src_type);
	Type *dst = get_base_type(t);
	if (are_types_identical(t, src_type))
		return value;

	if (value->kind == ssaValue_Constant) {
		if (dst->kind == Type_Basic)
			return ssa_make_value_constant(proc->module->allocator, t, value->constant.value);
	}

	// integer -> integer
	if (is_type_integer(src) && is_type_integer(dst)) {
		i64 sz = basic_type_sizes[src->basic.kind];
		i64 dz = basic_type_sizes[dst->basic.kind];
		ssaConvKind kind = ssaConv_trunc;
		if (dz >= sz) {
			kind = ssaConv_zext;
		}

		if (sz == dz) {
			// NOTE(bill): In LLVM, all integers are signed and rely upon 2's compliment
			return value;
		}

		return ssa_emit(proc, ssa_make_instr_conv(proc, kind, value, src, dst));
	}

	// float -> float
	if (is_type_float(src) && is_type_float(dst)) {
		i64 sz = basic_type_sizes[src->basic.kind];
		i64 dz = basic_type_sizes[dst->basic.kind];
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
		ssaValue *p = ssa_emit_load(proc, value);
		return ssa_emit(proc, ssa_make_instr_conv(proc, ssaConv_ptrtoint, p, src, dst));
	}
	if (is_type_int_or_uint(src) && is_type_pointer(dst)) {
		ssaValue *i = ssa_emit_load(proc, value);
		return ssa_emit(proc, ssa_make_instr_conv(proc, ssaConv_inttoptr, i, src, dst));
	}

	// Pointer <-> Pointer
	if (is_type_pointer(src) && is_type_pointer(dst)) {
		return ssa_emit(proc, ssa_make_instr_conv(proc, ssaConv_bitcast, value, src, dst));
	}


	// []byte/[]u8 <-> string
	if (is_type_u8_slice(src) && is_type_string(dst)) {
		ssaValue *slice = ssa_add_local_generated(proc, src);
		ssa_emit_store(proc, slice, value);
		ssaValue *elem = ssa_slice_elem(proc, slice);
		ssaValue *len  = ssa_slice_len(proc, slice);
		return ssa_emit_load(proc, ssa_emit_string(proc, elem, len));
	}
	if (is_type_string(src) && is_type_u8_slice(dst)) {
		ssaValue *str = ssa_add_local_generated(proc, src);
		ssa_emit_store(proc, str, value);
		ssaValue *elem = ssa_string_elem(proc, str);
		ssaValue *len  = ssa_string_len(proc, str);
		return ssa_emit_load(proc, ssa_emit_slice(proc, dst, elem, v_zero, len, len));
	}


	GB_PANIC("Invalid type conversion: `%s` to `%s`", type_to_string(src_type), type_to_string(t));

	return NULL;
}





ssaValue *ssa_build_single_expr(ssaProcedure *proc, AstNode *expr, TypeAndValue *tv) {
	switch (expr->kind) {
	case_ast_node(bl, BasicLit, expr);
		GB_PANIC("Non-constant basic literal");
	case_end;

	case_ast_node(i, Ident, expr);
		Entity *e = *map_get(&proc->module->info->uses, hash_pointer(expr));
		if (e->kind == Entity_Builtin) {
			GB_PANIC("TODO(bill): ssa_build_single_expr Entity_Builtin");
			return NULL;
		}

		auto *found = map_get(&proc->module->values, hash_pointer(e));
		if (found) {
			ssaValue *v = *found;
			if (v->kind == ssaValue_Proc)
				return v;
			return ssa_emit_load(proc, v);
		}
		return NULL;
	case_end;

	case_ast_node(pe, ParenExpr, expr);
		return ssa_build_single_expr(proc, unparen_expr(expr), tv);
	case_end;

	case_ast_node(de, DerefExpr, expr);
		return ssa_lvalue_load(ssa_build_addr(proc, expr), proc);
	case_end;

	case_ast_node(se, SelectorExpr, expr);
		return ssa_lvalue_load(ssa_build_addr(proc, expr), proc);
	case_end;

	case_ast_node(ue, UnaryExpr, expr);
		switch (ue->op.kind) {
		case Token_Pointer: {
			ssaLvalue lval = ssa_build_addr(proc, ue->expr);
			return ssa_lvalue_address(lval, proc);
		}
		case Token_Add:
			return ssa_build_expr(proc, ue->expr);
		case Token_Sub: {
			// NOTE(bill): -`x` == 0 - `x`
			ssaValue *left = v_zero;
			ssaValue *right = ssa_build_expr(proc, ue->expr);
			return ssa_emit_arith(proc, ue->op, left, right, tv->type);
		} break;
		case Token_Xor: { // Bitwise not
			// NOTE(bill): "not" `x` == `x` "xor" `-1`
			ExactValue neg_one = make_exact_value_integer(-1);
			ssaValue *left = ssa_build_expr(proc, ue->expr);
			ssaValue *right = ssa_make_value_constant(proc->module->allocator, tv->type, neg_one);
			return ssa_emit_arith(proc, ue->op, left, right, tv->type);
		} break;
		case Token_Not: // Boolean not
			GB_PANIC("Token_Not");
			return NULL;

		}
	case_end;

	case_ast_node(be, BinaryExpr, expr);
		switch (be->op.kind) {
		case Token_Add:
		case Token_Sub:
		case Token_Mul:
		case Token_Quo:
		case Token_Mod:
		case Token_And:
		case Token_Or:
		case Token_Xor:
		case Token_AndNot:
		case Token_Shl:
		case Token_Shr:
			return ssa_emit_arith(proc, be->op,
			                      ssa_build_expr(proc, be->left),
			                      ssa_build_expr(proc, be->right),
			                      tv->type);


		case Token_CmpEq:
		case Token_NotEq:
		case Token_Lt:
		case Token_LtEq:
		case Token_Gt:
		case Token_GtEq: {
			ssaValue *left  = ssa_build_expr(proc, be->left);
			ssaValue *right = ssa_build_expr(proc, be->right);
			ssaValue *cmp = ssa_emit_comp(proc, be->op, left, right);
			return ssa_emit_conv(proc, cmp, default_type(tv->type));
		} break;

		default:
			GB_PANIC("Invalid binary expression");
			break;
		}
	case_end;

	case_ast_node(pl, ProcLit, expr);
		if (proc->anon_procs == NULL) {
			// TODO(bill): Cleanup
			gb_array_init(proc->anon_procs, gb_heap_allocator());
		}
		// NOTE(bill): Generate a new name
		// parent$count
		isize name_len = proc->name.len + 1 + 8 + 1;
		u8 *name_text = gb_alloc_array(proc->module->allocator, u8, name_len);
		name_len = gb_snprintf(cast(char *)name_text, name_len, "%.*s$%d", LIT(proc->name), cast(i32)gb_array_count(proc->anon_procs));
		String name = make_string(name_text, name_len-1);


		// auto **found = map_get(&proc->module->info->definitions,
		                       // hash_pointer(expr))
		Type *type = type_of_expr(proc->module->info, expr);
		ssaValue *value = ssa_make_value_procedure(proc->module->allocator,
		                                           proc->module, type, pl->type, pl->body, name);
		ssaProcedure *np = &value->proc;

		gb_array_append(proc->anon_procs, np);
		ssa_build_proc(value, proc);

		return value; // TODO(bill): Is this correct?
	case_end;


	case_ast_node(pl, CompoundLit, expr);
		GB_PANIC("TODO(bill): ssa_build_single_expr CompoundLit");
	case_end;

	case_ast_node(ce, CastExpr, expr);
		return ssa_emit_conv(proc, ssa_build_expr(proc, ce->expr), tv->type);
	case_end;

	case_ast_node(ce, CallExpr, expr);
		AstNode *p = unparen_expr(ce->proc);
		if (p->kind == AstNode_Ident) {
			Entity **found = map_get(&proc->module->info->uses, hash_pointer(p));
			if (found && (*found)->kind == Entity_Builtin) {
				Entity *e = *found;
				switch (e->builtin.id) {
				case BuiltinProc_len: {
					// len :: proc(Type) -> int
					// NOTE(bill): len of an array is a constant expression
					ssaValue *v = ssa_lvalue_address(ssa_build_addr(proc, ce->arg_list), proc);
					Type *t = get_base_type(ssa_value_type(v));
					if (t == t_string)
						return ssa_string_len(proc, v);
					else if (t->kind == Type_Slice)
						return ssa_slice_len(proc, v);
				} break;
				case BuiltinProc_cap: {
					// cap :: proc(Type) -> int
					// NOTE(bill): cap of an array is a constant expression
					ssaValue *v = ssa_lvalue_address(ssa_build_addr(proc, ce->arg_list), proc);
					Type *t = get_base_type(ssa_value_type(v));
					return ssa_slice_cap(proc, v);
				} break;
				case BuiltinProc_copy: {
					// copy :: proc(dst, src: []Type) -> int
					AstNode *dst_node = ce->arg_list;
					AstNode *src_node = ce->arg_list->next;
					ssaValue *dst_slice = ssa_lvalue_address(ssa_build_addr(proc, dst_node), proc);
					ssaValue *src_slice = ssa_lvalue_address(ssa_build_addr(proc, src_node), proc);
					Type *slice_type = get_base_type(ssa_value_type(dst_slice));
					GB_ASSERT(slice_type->kind == Type_Slice);
					Type *elem_type = slice_type->slice.elem;
					i64 size_of_elem = type_size_of(proc->module->sizes, proc->module->allocator, elem_type);

					ssaValue *dst = ssa_emit_conv(proc, ssa_slice_elem(proc, dst_slice), t_rawptr);
					ssaValue *src = ssa_emit_conv(proc, ssa_slice_elem(proc, src_slice), t_rawptr);

					ssaValue *len_dst = ssa_slice_len(proc, dst_slice);
					ssaValue *len_src = ssa_slice_len(proc, src_slice);

					Token lt = {Token_Lt};
					ssaValue *cond = ssa_emit_comp(proc, lt, len_dst, len_src);
					ssaValue *len = ssa_emit_select(proc, cond, len_dst, len_src);
					Token mul = {Token_Mul};
					ssaValue *elem_size = ssa_make_value_constant(proc->module->allocator, t_int,
					                                              make_exact_value_integer(size_of_elem));
					ssaValue *byte_count = ssa_emit_arith(proc, mul, len, elem_size, t_int);


					i32 align = cast(i32)type_align_of(proc->module->sizes, proc->module->allocator, elem_type);
					b32 is_volatile = false;

					ssa_emit(proc, ssa_make_instr_copy_memory(proc, dst, src, byte_count, align, is_volatile));
					return len;
				} break;
				case BuiltinProc_append: {
					// copy :: proc(s: ^[]Type, value: Type) -> bool
					GB_PANIC("TODO(bill): BuiltinProc_append");
				} break;
				case BuiltinProc_print: {
					// print :: proc(...)
					GB_PANIC("TODO(bill): BuiltinProc_print");
				} break;
				case BuiltinProc_println: {
					// println :: proc(...)
					GB_PANIC("TODO(bill): BuiltinProc_println");
				} break;
				}
			}
		}


		// NOTE(bill): Regular call
		ssaValue *value = ssa_build_expr(proc, ce->proc);
		Type *proc_type_ = ssa_value_type(value);
		GB_ASSERT(proc_type_->kind == Type_Proc);
		auto *type = &proc_type_->proc;

		isize arg_index = 0;
		isize arg_count = type->param_count;
		ssaValue **args = gb_alloc_array(proc->module->allocator, ssaValue *, arg_count);

		for (AstNode *arg = ce->arg_list; arg != NULL; arg = arg->next) {
			ssaValue *a = ssa_build_expr(proc, arg);
			Type *at = ssa_value_type(a);
			if (at->kind == Type_Tuple) {
				for (isize i = 0; i < at->tuple.variable_count; i++) {
					Entity *e = at->tuple.variables[i];
					ssaValue *v = ssa_emit_struct_ev(proc, a, i, e->type);
					args[arg_index++] = v;
				}
			} else {
				args[arg_index++] = a;
			}
		}

		ssaValue *call = ssa_make_instr_call(proc, value, args, arg_count, tv->type);
		ssa_value_set_type(call, proc_type_);
		return ssa_emit(proc, call);
	case_end;

	case_ast_node(se, SliceExpr, expr);
		return ssa_emit_load(proc, ssa_lvalue_address(ssa_build_addr(proc, expr), proc));
	case_end;

	case_ast_node(ie, IndexExpr, expr);
		return ssa_emit_load(proc, ssa_lvalue_address(ssa_build_addr(proc, expr), proc));
	case_end;
	}

	GB_PANIC("Unexpected expression: %.*s", LIT(ast_node_strings[expr->kind]));
	return NULL;
}


ssaValue *ssa_build_expr(ssaProcedure *proc, AstNode *expr) {
	expr = unparen_expr(expr);

	TypeAndValue *tv = map_get(&proc->module->info->types, hash_pointer(expr));
	GB_ASSERT_NOT_NULL(tv);

	if (tv->value.kind != ExactValue_Invalid) {
		if (tv->value.kind == ExactValue_String) {
			// TODO(bill): Optimize by not allocating everytime
			ssaValue *array = ssa_add_global_string_array(proc, tv->value);
			ssaValue *elem = ssa_array_elem(proc, array);
			return ssa_emit_load(proc, ssa_emit_string(proc, elem, ssa_array_len(proc, array)));
		}
		return ssa_make_value_constant(proc->module->allocator, tv->type, tv->value);
	}

	ssaValue *value = NULL;
	if (tv->mode == Addressing_Variable) {
		value = ssa_lvalue_load(ssa_build_addr(proc, expr), proc);
	} else {
		value = ssa_build_single_expr(proc, expr, tv);
	}

	return value;
}


ssaLvalue ssa_build_addr(ssaProcedure *proc, AstNode *expr) {
	switch (expr->kind) {
	case_ast_node(i, Ident, expr);
		if (ssa_is_blank_ident(expr)) {
			ssaLvalue val = {ssaLvalue_Blank};
			return val;
		}

		Entity *e = entity_of_ident(proc->module->info, expr);
		ssaValue *v = NULL;
		ssaValue **found = map_get(&proc->module->values, hash_pointer(e));
		if (found) v = *found;
		return ssa_make_lvalue_address(v, expr);
	case_end;

	case_ast_node(pe, ParenExpr, expr);
		return ssa_build_addr(proc, unparen_expr(expr));
	case_end;

	case_ast_node(se, SelectorExpr, expr);
		Type *type = type_of_expr(proc->module->info, se->expr);

		isize field_index = 0;
		Entity *entity = lookup_field(type, unparen_expr(se->selector), &field_index);
		GB_ASSERT(entity != NULL);

		ssaValue *e = ssa_lvalue_address(ssa_build_addr(proc, se->expr), proc);

		if (type->kind == Type_Pointer) {
			// NOTE(bill): Allow x^.y and x.y to be the same
			type = type_deref(type);
			e = ssa_emit_load(proc, e);
		}

		ssaValue *v = ssa_emit_struct_gep(proc, e, field_index, entity->type);
		return ssa_make_lvalue_address(v, expr);
	case_end;

	case_ast_node(ie, IndexExpr, expr);
		ssaValue *v = NULL;
		Type *t = get_base_type(type_of_expr(proc->module->info, ie->expr));
		ssaValue *elem = NULL;
		switch (t->kind) {
		case Type_Array: {
			ssaValue *array = ssa_lvalue_address(ssa_build_addr(proc, ie->expr), proc);
			elem = ssa_array_elem(proc, array);
		} break;
		case Type_Slice: {
			ssaValue *slice = ssa_lvalue_address(ssa_build_addr(proc, ie->expr), proc);
			elem = ssa_slice_elem(proc, slice);
		} break;
		case Type_Basic: { // Basic_string
			TypeAndValue *tv = map_get(&proc->module->info->types, hash_pointer(ie->expr));
			if (tv->mode == Addressing_Constant) {
				ssaValue *array = ssa_add_global_string_array(proc, tv->value);
				elem = ssa_array_elem(proc, array);
			} else {
				ssaLvalue lval = ssa_build_addr(proc, ie->expr);
				ssaValue *str = ssa_lvalue_address(lval, proc);
				elem = ssa_string_elem(proc, str);
			}
		} break;
		case Type_Pointer: {
			elem = ssa_emit_load(proc, ssa_lvalue_address(ssa_build_addr(proc, ie->expr), proc));
		} break;
		}

		ssaValue *index = ssa_emit_conv(proc, ssa_build_expr(proc, ie->index), t_int);
		v = ssa_emit_ptr_offset(proc, elem, index);

		ssa_value_set_type(v, type_deref(ssa_value_type(v)));
		return ssa_make_lvalue_address(v, expr);
	case_end;

	case_ast_node(se, SliceExpr, expr);
		ssaValue *low  = NULL;
		ssaValue *high = NULL;
		ssaValue *max  = NULL;

		if (se->low  != NULL)    low  = ssa_build_expr(proc, se->low);
		if (se->high != NULL)    high = ssa_build_expr(proc, se->high);
		if (se->triple_indexed)  max  = ssa_build_expr(proc, se->max);
		Type *type = type_of_expr(proc->module->info, expr);

		switch (type->kind) {
		case Type_Slice:
		case Type_Array: {
			ssaValue *base = ssa_lvalue_address(ssa_build_addr(proc, se->expr), proc);
			return ssa_make_lvalue_address(ssa_emit_slice(proc, type, base, low, high, max), expr);
		} break;
		case Type_Basic: {
			// NOTE(bill): max is not needed
			ssaValue *base = ssa_lvalue_address(ssa_build_addr(proc, se->expr), proc);
			return ssa_make_lvalue_address(ssa_emit_substring(proc, base, low, high), expr);
		} break;
		}

		GB_PANIC("Unknown slicable type");
	case_end;

	case_ast_node(de, DerefExpr, expr);
		ssaValue *e = ssa_emit_load(proc, ssa_lvalue_address(ssa_build_addr(proc, de->expr), proc));
		ssaValue *gep = ssa_make_instr_get_element_ptr(proc, e, NULL, NULL, 0, false);
		Type *t = type_deref(get_base_type(ssa_value_type(e)));
		gep->instr.get_element_ptr.result_type  = t;
		gep->instr.get_element_ptr.elem_type = t;
		ssaValue *v = ssa_emit(proc, gep);
		return ssa_make_lvalue_address(v, expr);
	case_end;
	}

	GB_PANIC("Unexpected address expression\n"
	         "\tAstNode: %.*s\n", LIT(ast_node_strings[expr->kind]));

	ssaLvalue blank = {ssaLvalue_Blank};
	return blank;
}

void ssa_build_assign_op(ssaProcedure *proc, ssaLvalue lhs, ssaValue *value, Token op) {
	ssaValue *old_value = ssa_lvalue_load(lhs, proc);
	ssaValue *change = ssa_emit_conv(proc, value, ssa_value_type(old_value));
	ssaValue *new_value = ssa_emit_arith(proc, op, old_value, change, ssa_lvalue_type(lhs));
	ssa_lvalue_store(lhs, proc, new_value);
}

void ssa_build_cond(ssaProcedure *proc, AstNode *cond, ssaBlock *true_block, ssaBlock *false_block) {
	switch (cond->kind) {
	case_ast_node(pe, ParenExpr, cond);
		ssa_build_cond(proc, pe->expr, true_block, false_block);
		return;
	case_end;

	case_ast_node(ue, UnaryExpr, cond);
		if (ue->op.kind == Token_Not) {
			ssa_build_cond(proc, ue->expr, false_block, true_block);
			return;
		}
	case_end;

	case_ast_node(be, BinaryExpr, cond);
		if (be->op.kind == Token_CmpAnd) {
			ssaBlock *block = ssa_add_block(proc, NULL, make_string("cmp-and"));
			ssa_build_cond(proc, be->left, block, false_block);
			proc->curr_block = block;
			ssa_build_cond(proc, be->right, true_block, false_block);
			return;
		} else if (be->op.kind == Token_CmpOr) {
			ssaBlock *block = ssa_add_block(proc, NULL, make_string("cmp-or"));
			ssa_build_cond(proc, be->left, true_block, block);
			proc->curr_block = block;
			ssa_build_cond(proc, be->right, true_block, false_block);
			return;
		}
	case_end;
	}

	ssaValue *expr = ssa_build_expr(proc, cond);
	ssa_emit_if(proc, expr, true_block, false_block);
}



void ssa_build_stmt_list(ssaProcedure *proc, AstNode *list) {
	for (AstNode *stmt = list ; stmt != NULL; stmt = stmt->next)
		ssa_build_stmt(proc, stmt);
}

void ssa_build_stmt(ssaProcedure *proc, AstNode *node) {
	switch (node->kind) {
	case_ast_node(bs, EmptyStmt, node);
	case_end;

	case_ast_node(vd, VarDecl, node);
		if (vd->kind == Declaration_Mutable) {
			if (vd->name_count == vd->value_count) { // 1:1 assigment
				gbArray(ssaLvalue)  lvals;
				gbArray(ssaValue *) inits;
				gb_array_init_reserve(lvals, gb_heap_allocator(), vd->name_count);
				gb_array_init_reserve(inits, gb_heap_allocator(), vd->name_count);
				defer (gb_array_free(lvals));
				defer (gb_array_free(inits));

				for (AstNode *name = vd->name_list; name != NULL; name = name->next) {
					ssaLvalue lval = {ssaLvalue_Blank};
					if (!ssa_is_blank_ident(name)) {
						ssa_add_local_for_identifier(proc, name);
						lval = ssa_build_addr(proc, name);
						GB_ASSERT(lval.address.value != NULL);
					}

					gb_array_append(lvals, lval);
				}

				for (AstNode *value = vd->value_list; value != NULL; value = value->next) {
					ssaValue *init = ssa_build_expr(proc, value);
					gb_array_append(inits, init);
				}


				gb_for_array(i, inits) {
					if (lvals[i].kind != ssaLvalue_Blank) {
						ssaValue *v = ssa_emit_conv(proc, inits[i], ssa_lvalue_type(lvals[i]));
						ssa_lvalue_store(lvals[i], proc, v);
					}
				}

			} else if (vd->value_count == 0) { // declared and zero-initialized
				for (AstNode *name = vd->name_list; name != NULL; name = name->next) {
					if (!ssa_is_blank_ident(name)) {
						ssa_add_local_for_identifier(proc, name);
					}
				}
			} else { // Tuple(s)
				gbArray(ssaLvalue)  lvals;
				gbArray(ssaValue *) inits;
				gb_array_init_reserve(lvals, gb_heap_allocator(), vd->name_count);
				gb_array_init_reserve(inits, gb_heap_allocator(), vd->name_count);
				defer (gb_array_free(lvals));
				defer (gb_array_free(inits));

				for (AstNode *name = vd->name_list; name != NULL; name = name->next) {
					ssaLvalue lval = {ssaLvalue_Blank};
					if (!ssa_is_blank_ident(name)) {
						ssa_add_local_for_identifier(proc, name);
						lval = ssa_build_addr(proc, name);
					}

					gb_array_append(lvals, lval);
				}

				for (AstNode *value = vd->value_list; value != NULL; value = value->next) {
					ssaValue *init = ssa_build_expr(proc, value);
					Type *t = ssa_value_type(init);
					if (t->kind == Type_Tuple) {
						for (isize i = 0; i < t->tuple.variable_count; i++) {
							Entity *e = t->tuple.variables[i];
							ssaValue *v = ssa_emit_struct_ev(proc, init, i, e->type);
							gb_array_append(inits, v);
						}
					} else {
						gb_array_append(inits, init);
					}
				}


				gb_for_array(i, inits) {
					ssaValue *v = ssa_emit_conv(proc, inits[i], ssa_lvalue_type(lvals[i]));
					ssa_lvalue_store(lvals[i], proc, v);
				}
			}
		}
	case_end;

	case_ast_node(pd, ProcDecl, node);
		if (proc->nested_procs == NULL) {
			// TODO(bill): Cleanup
			gb_array_init(proc->nested_procs, gb_heap_allocator());
		}
		// NOTE(bill): Generate a new name
		// parent$name
		String pd_name = pd->name->Ident.token.string;
		isize name_len = proc->name.len + 1 + pd_name.len + 1;
		u8 *name_text = gb_alloc_array(proc->module->allocator, u8, name_len);
		name_len = gb_snprintf(cast(char *)name_text, name_len, "%.*s$%.*s", LIT(proc->name), LIT(pd_name));
		String name = make_string(name_text, name_len-1);

		Entity *e = *map_get(&proc->module->info->definitions, hash_pointer(pd->name));
		ssaValue *value = ssa_make_value_procedure(proc->module->allocator,
		                                           proc->module, e->type, pd->type, pd->body, name);
		ssaProcedure *np = &value->proc;
		gb_array_append(proc->nested_procs, np);
		ssa_build_proc(value, proc);

		map_set(&proc->module->values, hash_pointer(e), value);

	case_end;

	case_ast_node(ids, IncDecStmt, node);
		Token op = ids->op;
		if (op.kind == Token_Increment) {
			op.kind = Token_Add;
		} else if (op.kind == Token_Decrement) {
			op.kind = Token_Sub;
		}
		ssaLvalue lval = ssa_build_addr(proc, ids->expr);
		ssaValue *one = ssa_emit_conv(proc, v_one, ssa_lvalue_type(lval));
		ssa_build_assign_op(proc, lval, one, op);

	case_end;

	case_ast_node(as, AssignStmt, node);
		switch (as->op.kind) {
		case Token_Eq: {
			gbArray(ssaLvalue) lvals;
			gb_array_init(lvals, gb_heap_allocator());
			defer (gb_array_free(lvals));

			for (AstNode *lhs = as->lhs_list;
			     lhs != NULL;
			     lhs = lhs->next) {
				ssaLvalue lval = {};
				if (!ssa_is_blank_ident(lhs)) {
					lval = ssa_build_addr(proc, lhs);
				}
				gb_array_append(lvals, lval);
			}

			if (as->lhs_count == as->rhs_count) {
				if (as->lhs_count == 1) {
					AstNode *rhs = as->rhs_list;
					ssaValue *init = ssa_build_expr(proc, rhs);
					ssa_lvalue_store(lvals[0], proc, init);
				} else {
					gbArray(ssaValue *) inits;
					gb_array_init_reserve(inits, gb_heap_allocator(), gb_array_count(lvals));
					defer (gb_array_free(inits));

					for (AstNode *rhs = as->rhs_list; rhs != NULL; rhs = rhs->next) {
						ssaValue *init = ssa_build_expr(proc, rhs);
						gb_array_append(inits, init);
					}

					gb_for_array(i, inits) {
						ssa_lvalue_store(lvals[i], proc, inits[i]);
					}
				}
			} else {
				gbArray(ssaValue *) inits;
				gb_array_init_reserve(inits, gb_heap_allocator(), gb_array_count(lvals));
				defer (gb_array_free(inits));

				for (AstNode *rhs = as->rhs_list; rhs != NULL; rhs = rhs->next) {
					ssaValue *init = ssa_build_expr(proc, rhs);
					Type *t = ssa_value_type(init);
					// TODO(bill): refactor for code reuse as this is repeated a bit
					if (t->kind == Type_Tuple) {
						for (isize i = 0; i < t->tuple.variable_count; i++) {
							Entity *e = t->tuple.variables[i];
							ssaValue *v = ssa_emit_struct_ev(proc, init, i, e->type);
							gb_array_append(inits, v);
						}
					} else {
						gb_array_append(inits, init);
					}
				}

				gb_for_array(i, inits) {
					ssa_lvalue_store(lvals[i], proc, inits[i]);
				}
			}

		} break;

		default: {
			// NOTE(bill): Only 1 += 1 is allowed, no tuples
			// +=, -=, etc
			Token op = as->op;
			i32 kind = op.kind;
			kind += Token_Add - Token_AddEq; // Convert += to +
			op.kind = cast(TokenKind)kind;
			ssaLvalue lhs = ssa_build_addr(proc, as->lhs_list);
			ssaValue *value = ssa_build_expr(proc, as->rhs_list);
			ssa_build_assign_op(proc, lhs, value, op);
		} break;
		}
	case_end;

	case_ast_node(es, ExprStmt, node);
		// NOTE(bill): No need to use return value
		ssa_build_expr(proc, es->expr);
	case_end;

	case_ast_node(bs, BlockStmt, node);
		ssa_build_stmt_list(proc, bs->list);
	case_end;

	case_ast_node(bs, DeferStmt, node);
		GB_PANIC("DeferStmt");
	case_end;

	case_ast_node(rs, ReturnStmt, node);
		ssaValue *v = NULL;
		auto *return_type_tuple  = &proc->type->proc.results->tuple;
		isize return_count = proc->type->proc.result_count;
		if (rs->result_count == 1 && return_count > 1) {
			GB_PANIC("ReturnStmt tuple return statement");
		} else if (return_count == 1) {
			Entity *e = return_type_tuple->variables[0];
			v = ssa_build_expr(proc, rs->result_list);
			ssa_value_set_type(v, e->type);
		} else if (return_count == 0) {
			// No return values
		} else {
			// 1:1 multiple return values
			Type *ret_type = proc->type->proc.results;
			v = ssa_add_local_generated(proc, ret_type);
			isize i = 0;
			AstNode *r = rs->result_list;
			for (;
			     i < return_count && r != NULL;
			     i++, r = r->next) {
				Entity *e = return_type_tuple->variables[i];
				ssaValue *res = ssa_build_expr(proc, r);
				ssa_value_set_type(res, e->type);
				ssaValue *field = ssa_emit_struct_gep(proc, v, i, e->type);
				ssa_emit_store(proc, field, res);
			}
			v = ssa_emit_load(proc, v);
		}

		ssa_emit_ret(proc, v);

	case_end;

	case_ast_node(is, IfStmt, node);
		if (is->init != NULL) {
			ssa_build_stmt(proc, is->init);
		}
		ssaBlock *then = ssa_add_block(proc, node, make_string("if.then"));
		ssaBlock *done = ssa__make_block(proc, node, make_string("if.done")); // NOTE(bill): Append later
		ssaBlock *else_ = done;
		if (is->else_stmt != NULL) {
			else_ = ssa_add_block(proc, is->else_stmt, make_string("if.else"));
		}

		ssa_build_cond(proc, is->cond, then, else_);
		proc->curr_block = then;
		ssa_build_stmt(proc, is->body);
		ssa_emit_jump(proc, done);

		if (is->else_stmt != NULL) {
			proc->curr_block = else_;
			ssa_build_stmt(proc, is->else_stmt);
			ssa_emit_jump(proc, done);
		}
		gb_array_append(proc->blocks, done);
		proc->curr_block = done;
	case_end;

	case_ast_node(fs, ForStmt, node);
		if (fs->init != NULL) {
			ssa_build_stmt(proc, fs->init);
		}
		ssaBlock *body = ssa_add_block(proc, node, make_string("for.body"));
		ssaBlock *done = ssa__make_block(proc, node, make_string("for.done")); // NOTE(bill): Append later

		ssaBlock *loop = body;

		if (fs->cond != NULL) {
			loop = ssa_add_block(proc, node, make_string("for.loop"));
		}
		ssaBlock *cont = loop;
		if (fs->post != NULL) {
			cont = ssa_add_block(proc, node, make_string("for.post"));
		}
		ssa_emit_jump(proc, loop);
		proc->curr_block = loop;
		if (loop != body) {
			ssa_build_cond(proc, fs->cond, body, done);
			proc->curr_block = body;
		}

		ssa_push_target_list(proc, done, cont, NULL);
		ssa_build_stmt(proc, fs->body);
		ssa_pop_target_list(proc);
		ssa_emit_jump(proc, cont);

		if (fs->post != NULL) {
			proc->curr_block = cont;
			ssa_build_stmt(proc, fs->post);
			ssa_emit_jump(proc, loop);
		}
		gb_array_append(proc->blocks, done);
		proc->curr_block = done;

	case_end;

	case_ast_node(bs, BranchStmt, node);
		ssaBlock *block = NULL;
		switch (bs->token.kind) {
		#define BRANCH_GET_BLOCK(kind_) \
			case GB_JOIN2(Token_, kind_): { \
				for (ssaTargetList *t = proc->target_list; t != NULL && block == NULL; t = t->prev) { \
					block = GB_JOIN3(t->, kind_, _); \
				} \
			} break
		BRANCH_GET_BLOCK(break);
		BRANCH_GET_BLOCK(continue);
		BRANCH_GET_BLOCK(fallthrough);
		#undef BRANCH_GET_BLOCK
		}
		ssa_emit_jump(proc, block);
		ssa_emit_unreachable(proc);
	case_end;

	}
}

void ssa_build_proc(ssaValue *value, ssaProcedure *parent) {
	ssaProcedure *proc = &value->proc;

	proc->parent = parent;

	if (proc->body != NULL) {
		ssa_begin_procedure_body(proc);
		ssa_build_stmt(proc, proc->body);
		ssa_end_procedure_body(proc);
	}
}
