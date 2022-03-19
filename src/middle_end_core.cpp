
struct meGenerator {
	CheckerInfo *info;

	Array<String> output_object_paths;
	Array<String> output_temp_paths;
	String   output_base;
	String   output_name;
	PtrMap<AstPackage *, meModule *> modules;
	meModule default_module;

	PtrMap<Ast *, meProcedure *> anonymous_proc_lits;

	std::atomic<u32> global_array_index;
	std::atomic<u32> global_generated_index;
};

gb_internal meGenerator me_gen;

gb_global Arena global_me_arena = {};
gbAllocator me_allocator() {
	return arena_allocator(&global_me_arena);
}

#define me_new(TYPE) gb_alloc_item(me_allocator(), TYPE)

meValue me_value(meInstruction *instr) {
	meValue value = {meValue_Instruction};
	value.instr = instr;
	return value;
}
meValue me_value(meConstant *constant) {
	meValue value = {meValue_ConstantValue};
	value.constant = constant;
	return value;
}
meValue me_value(meBlock *block) {
	meValue value = {meValue_Block};
	value.block = block;
	return value;
}
meValue me_value(meProcedure *proc) {
	meValue value = {meValue_Procedure};
	value.proc = proc;
	return value;
}
meValue me_value(meGlobalVariable *global) {
	meValue value = {meValue_GlobalVariable};
	value.global = global;
	return value;
}
meValue me_value(meParameter *param) {
	meValue value = {meValue_Parameter};
	value.param = param;
	return value;
}

bool me_is_const(meValue value) {
	return value.kind == meValue_ConstantValue;
}

bool me_is_const_nil(meValue value) {
	if (value.kind == meValue_ConstantValue) {
		return value.constant->value.kind == ExactValue_Invalid;
	}
	return false;
}


meValue me_use(meValue const &value) {
	switch (value.kind) {
	case meValue_Instruction:    value.instr->uses  += 1; break;
	case meValue_Procedure:      value.proc->uses   += 1; break;
	case meValue_GlobalVariable: value.global->uses += 1; break;
	case meValue_Parameter:      value.param->uses  += 1; break;
	}
	return value;
}

i32 me_uses(meValue const &value) {
	switch (value.kind) {
	case meValue_Instruction:    return value.instr->uses;
	case meValue_Procedure:      return value.proc->uses;
	case meValue_GlobalVariable: return value.global->uses;
	case meValue_Parameter:      return value.param->uses;
	}
	GB_PANIC("invalid value to call on uses");
	return 0;
}

void me_remove_use(meValue const &value) {
	switch (value.kind) {
	case meValue_Instruction:    GB_ASSERT(value.instr->uses  > 0); value.instr->uses  -= 1; break;
	case meValue_Procedure:      GB_ASSERT(value.proc->uses   > 0); value.proc->uses   -= 1; break;
	case meValue_GlobalVariable: GB_ASSERT(value.global->uses > 0); value.global->uses -= 1; break;
	case meValue_Parameter:      GB_ASSERT(value.param->uses  > 0); value.param->uses  -= 1; break;
	}
}


meAddr me_addr(meValue value) {
	meAddr addr = {};
	addr.kind = meAddr_Default;
	addr.addr = value;
	return addr;
}

Type *me_type(meValue value) {
	switch (value.kind) {
	case meValue_Invalid:
		return nullptr;
	case meValue_Instruction:
		return value.instr->type;
	case meValue_ConstantValue:
		return value.constant->type;
	case meValue_Block:
		return nullptr;
	case meValue_Procedure:
		return value.proc->type;
	case meValue_GlobalVariable:
		return value.global->type;
	case meValue_Parameter:
		return value.param->entity->type;
	}
	return nullptr;
}

meModule *me_pkg_module(AstPackage *pkg) {
	if (pkg != nullptr) {
		auto *found = map_get(&me_gen.modules, pkg);
		if (found) {
			return *found;
		}
	}
	return &me_gen.default_module;
}


void me_add_entity(meModule *m, Entity *e, meValue val) {
	if (e != nullptr) {
		map_set(&m->values, e, val);
	}
}
void me_add_member(meModule *m, String const &name, meValue val) {
	if (name.len > 0) {
		string_map_set(&m->members, name, val);
	}
}
void me_add_member(meModule *m, StringHashKey const &key, meValue val) {
	string_map_set(&m->members, key, val);
}
void me_add_procedure_value(meModule *m, meProcedure *p) {
	if (p->entity != nullptr) {
		map_set(&m->procedure_values, p, p->entity);
	}
	string_map_set(&m->procedures, p->name, p);
}


void me_add_foreign_library_path(meModule *m, Entity *e) {
	if (e == nullptr) {
		return;
	}
	GB_ASSERT(e->kind == Entity_LibraryName);
	GB_ASSERT(e->flags & EntityFlag_Used);

	for_array(i, e->LibraryName.paths) {
		String library_path = e->LibraryName.paths[i];
		if (library_path.len == 0) {
			continue;
		}

		bool ok = true;
		for_array(path_index, m->foreign_library_paths) {
			String path = m->foreign_library_paths[path_index];
	#if defined(GB_SYSTEM_WINDOWS)
			if (str_eq_ignore_case(path, library_path)) {
	#else
			if (str_eq(path, library_path)) {
	#endif
				ok = false;
				break;
			}
		}

		if (ok) {
			array_add(&m->foreign_library_paths, library_path);
		}
	}
}


String me_mangle_name(meModule *m, Entity *e) {
	String name = e->token.string;

	AstPackage *pkg = e->pkg;
	GB_ASSERT_MSG(pkg != nullptr, "Missing package for '%.*s'", LIT(name));
	String pkgn = pkg->name;
	GB_ASSERT(!rune_is_digit(pkgn[0]));
	if (pkgn == "llvm") {
		pkgn = str_lit("llvm$");
	}

	isize max_len = pkgn.len + 1 + name.len + 1;
	bool require_suffix_id = is_type_polymorphic(e->type, true);

	if ((e->scope->flags & (ScopeFlag_File | ScopeFlag_Pkg)) == 0) {
		require_suffix_id = true;
	} else if (is_blank_ident(e->token)) {
		require_suffix_id = true;
	}if (e->flags & EntityFlag_NotExported) {
		require_suffix_id = true;
	}

	if (require_suffix_id) {
		max_len += 21;
	}

	char *new_name = gb_alloc_array(permanent_allocator(), char, max_len);
	isize new_name_len = gb_snprintf(
		new_name, max_len,
		"%.*s.%.*s", LIT(pkgn), LIT(name)
	);
	if (require_suffix_id) {
		char *str = new_name + new_name_len-1;
		isize len = max_len-new_name_len;
		isize extra = gb_snprintf(str, len, "-%llu", cast(unsigned long long)e->id);
		new_name_len += extra-1;
	}

	String mangled_name = make_string((u8 const *)new_name, new_name_len-1);
	return mangled_name;
}

String me_set_nested_type_name_ir_mangled_name(Entity *e, meProcedure *p) {
	// NOTE(bill, 2020-03-08): A polymorphic procedure may take a nested type declaration
	// and as a result, the declaration does not have time to determine what it should be

	GB_ASSERT(e != nullptr && e->kind == Entity_TypeName);
	if (e->TypeName.ir_mangled_name.len != 0)  {
		return e->TypeName.ir_mangled_name;
	}
	GB_ASSERT((e->scope->flags & ScopeFlag_File) == 0);

	if (p == nullptr) {
		Entity *proc = nullptr;
		if (e->parent_proc_decl != nullptr) {
			proc = e->parent_proc_decl->entity;
		} else {
			Scope *scope = e->scope;
			while (scope != nullptr && (scope->flags & ScopeFlag_Proc) == 0) {
				scope = scope->parent;
			}
			GB_ASSERT(scope != nullptr);
			GB_ASSERT(scope->flags & ScopeFlag_Proc);
			proc = scope->procedure_entity;
		}
		GB_ASSERT(proc->kind == Entity_Procedure);
		if (proc->me_procedure != nullptr) {
			p = proc->me_procedure;
		}
	}

	// NOTE(bill): Generate a new name
	// parent_proc.name-guid
	String ts_name = e->token.string;

	if (p != nullptr) {
		isize name_len = p->name.len + 1 + ts_name.len + 1 + 10 + 1;
		char *name_text = gb_alloc_array(permanent_allocator(), char, name_len);
		u32 guid = ++p->module->nested_type_name_guid;
		name_len = gb_snprintf(name_text, name_len, "%.*s.%.*s-%u", LIT(p->name), LIT(ts_name), guid);

		String name = make_string(cast(u8 *)name_text, name_len-1);
		e->TypeName.ir_mangled_name = name;
		return name;
	} else {
		// NOTE(bill): a nested type be required before its parameter procedure exists. Just give it a temp name for now
		isize name_len = 9 + 1 + ts_name.len + 1 + 10 + 1;
		char *name_text = gb_alloc_array(permanent_allocator(), char, name_len);
		static u32 guid = 0;
		guid += 1;
		name_len = gb_snprintf(name_text, name_len, "_internal.%.*s-%u", LIT(ts_name), guid);

		String name = make_string(cast(u8 *)name_text, name_len-1);
		e->TypeName.ir_mangled_name = name;
		return name;
	}
}


String me_get_entity_name(meModule *m, Entity *e, String default_name) {
	if (e != nullptr && e->kind == Entity_TypeName && e->TypeName.ir_mangled_name.len != 0) {
		return e->TypeName.ir_mangled_name;
	}
	GB_ASSERT(e != nullptr);

	if (e->pkg == nullptr) {
		return e->token.string;
	}

	if (e->kind == Entity_TypeName && (e->scope->flags & ScopeFlag_File) == 0) {
		return me_set_nested_type_name_ir_mangled_name(e, nullptr);
	}

	String name = {};

	bool no_name_mangle = false;

	if (e->kind == Entity_Variable) {
		bool is_foreign = e->Variable.is_foreign;
		bool is_export  = e->Variable.is_export;
		no_name_mangle = e->Variable.link_name.len > 0 || is_foreign || is_export;
		if (e->Variable.link_name.len > 0) {
			return e->Variable.link_name;
		}
	} else if (e->kind == Entity_Procedure && e->Procedure.link_name.len > 0) {
		return e->Procedure.link_name;
	} else if (e->kind == Entity_Procedure && e->Procedure.is_export) {
		no_name_mangle = true;
	}

	if (!no_name_mangle) {
		name = me_mangle_name(m, e);
	}
	if (name.len == 0) {
		name = e->token.string;
	}

	if (e->kind == Entity_TypeName) {
		e->TypeName.ir_mangled_name = name;
	} else if (e->kind == Entity_Procedure) {
		e->Procedure.link_name = name;
	}

	return name;
}

meInstruction *me_last_instruction(meBlock *block) {
	if (block && block->instructions.count > 0) {
		return block->instructions[block->instructions.count-1];
	}
	return nullptr;
}

bool me_is_instruction_terminator(meOpKind op) {
	switch (op) {
	case meOp_Unreachable:
	case meOp_Return:
	case meOp_Jump:
	case meOp_CondJump:
	case meOp_Switch:
		return true;
	}
	return false;
}


bool me_is_last_instruction_terminator(meBlock *b) {
	meInstruction *instr = me_last_instruction(b);
	return instr != nullptr && me_is_instruction_terminator(instr->op);
}

meBlock *me_block_create(meProcedure *p, char const *name) {
	auto *b = me_new(meBlock);
	b->scope = p->curr_scope;
	b->scope_index = p->scope_index;

	b->preds.allocator = heap_allocator();
	b->succs.allocator = heap_allocator();

	array_add(&p->blocks, b);

	return b;
}

void me_block_add_edge(meBlock *from, meBlock *to) {
	if (!me_is_last_instruction_terminator(from)) {
		array_add(&from->succs, to);
		array_add(&to->preds,   from);
	}
}


void me_block_start(meProcedure *p, meBlock *b) {
	p->curr_block = b;
}


meContextData *me_push_context_onto_stack_from_implicit_parameter(meProcedure *p) {
	// TODO(bill): me_push_context_onto_stack_from_implicit_parameter
	return nullptr;
}



meInstruction *me_create_instruction(meProcedure *p, meOpKind op) {
	meInstruction *instr = me_new(meInstruction);
	instr->op = op;

	GB_ASSERT(p->curr_block != nullptr);

	if (!me_is_last_instruction_terminator(p->curr_block)) {
		if (instr->parent != nullptr) {
			GB_ASSERT(instr->parent == p);
		} else {
			instr->parent = p;
		}
		array_add(&p->curr_block->instructions, instr);
	}

	return instr;
}

void me_emit_unreachable(meProcedure *p) {
	me_create_instruction(p, meOp_Unreachable);
}

void me_emit_return_empty(meProcedure *p) {
	GB_ASSERT(p->type->Proc.result_count == 0);

	me_create_instruction(p, meOp_Return);
}
void me_emit_return(meProcedure *p, meValue value) {
	auto *instr = me_create_instruction(p, meOp_Return);
	if (value.kind != meValue_Invalid) {
		instr->ops[0] = me_use(value);
		instr->op_count = 1;
	}
}

void me_emit_jump(meProcedure *p, meBlock *block) {
	auto *jump = me_create_instruction(p, meOp_Jump);
	jump->ops[0] = me_use(me_value(block));
	jump->op_count = 1;

	me_block_add_edge(p->curr_block, block);
}

void me_emit_cond_jump(meProcedure *p, meValue cond, meBlock *true_block, meBlock *false_block) {
	if (p->curr_block == nullptr) {
		return;
	}

	if (cond.kind == meValue_ConstantValue) {
		GB_ASSERT(cond.constant->value.kind == ExactValue_Bool);
		if (cond.constant->value.value_bool) {
			me_emit_jump(p, true_block);
		} else {
			me_emit_jump(p, false_block);
		}
		return;
	}

	auto *jump = me_create_instruction(p, meOp_CondJump);
	jump->ops[0] = me_use(cond);
	jump->ops[1] = me_use(me_value(true_block));
	jump->ops[2] = me_use(me_value(false_block));
	jump->op_count = 3;

	me_block_add_edge(p->curr_block, true_block);
	me_block_add_edge(p->curr_block, false_block);
}


meValue me_emit_neg(meProcedure *p, meValue value) {
	Type *type = me_type(value);
	GB_ASSERT(type != nullptr);
	type = base_type(core_array_type(type));
	GB_ASSERT(is_type_numeric(type));

	auto *n = me_create_instruction(p, meOp_Neg);
	n->type = me_type(value);
	n->ops[0] = me_use(value);
	n->op_count = 1;

	return me_value(n);
}

meValue me_emit_logical_not(meProcedure *p, meValue value) {
	Type *type = me_type(value);
	GB_ASSERT(type != nullptr);
	type = base_type(core_array_type(type));
	GB_ASSERT(is_type_boolean(type));

	auto *n = me_create_instruction(p, meOp_LogicalNot);
	n->type = me_type(value);
	n->ops[0] = me_use(value);
	n->op_count = 1;

	return me_value(n);
}

meValue me_emit_bitwise_not(meProcedure *p, meValue value) {
	Type *type = me_type(value);
	GB_ASSERT(type != nullptr);
	type = base_type(core_array_type(type));
	GB_ASSERT(is_type_integer(type) || is_type_boolean(type) || is_type_bit_set(type));

	auto *n = me_create_instruction(p, meOp_BitwiseNot);
	n->type = me_type(value);
	n->ops[0] = me_use(value);
	n->op_count = 1;

	return me_value(n);
}


meValue me_emit_binary_op(meProcedure *p, meOpKind op, meValue left, meValue right, Type *type) {
	GB_ASSERT(type != nullptr);

	switch (op) {
	case meOp_Add:
	case meOp_Sub:
	case meOp_Mul:
	case meOp_Div:
	case meOp_Rem:
	case meOp_Shl:
	case meOp_LShr:
	case meOp_AShr:
	case meOp_And:
	case meOp_Or:
	case meOp_Xor:
	case meOp_Eq:
	case meOp_NotEq:
	case meOp_Lt:
	case meOp_LtEq:
	case meOp_Gt:
	case meOp_GtEq:
	case meOp_Min:
	case meOp_Max:
		break;
	default:
		GB_PANIC("Unsupported binary op");
	}

	auto *b = me_create_instruction(p, op);
	b->type = type;
	b->ops[0] = me_use(left);
	b->ops[1] = me_use(right);
	b->op_count = 2;

	return me_value(b);
}


meAddr me_add_local(meProcedure *p, Type *type, Entity *e, bool zero_init) {
	meInstruction *var = nullptr;
	meBlock *curr_block = p->curr_block;
	p->curr_block = p->decl_block;
	var = me_create_instruction(p, meOp_Alloca);
	p->curr_block = curr_block;

	var->type = alloc_type_pointer(type);

	u16 alignment = cast(u16)type_align_of(type);
	if (is_type_matrix(type)) {
		alignment *= 2; // NOTE(bill): Just in case
	}
	var->alignment = alignment;

	// TODO(bill): ZERO me_add_local

	return me_addr(me_value(var));
}


meValue me_emit_inline_alloca(meProcedure *p, Type *type, u16 alignment) {
	meInstruction *var = me_create_instruction(p, meOp_Alloca);
	var->type = alloc_type_pointer(type);
	var->alignment = alignment;
	return me_value(var);
}

meValue me_emit_load_with_alignment_hint(meProcedure *p, meValue const &value, u16 alignment) {
	GB_ASSERT(alignment == 0 || gb_is_power_of_two(alignment));
	Type *type = me_type(value);
	GB_ASSERT(type != nullptr);
	GB_ASSERT(is_type_pointer(type));

	meInstruction *v = me_create_instruction(p, meOp_Load);
	v->type = type;
	v->ops[0] = me_use(value);
	v->op_count = 1;
	v->alignment = alignment;

	return me_value(v);
}

meValue me_emit_load(meProcedure *p, meValue const &value) {
	return me_emit_load_with_alignment_hint(p, value, 0);
}

meValue me_emit_unaligned_load_with_alignment_hint(meProcedure *p, meValue const &value, u16 alignment) {
	GB_ASSERT(alignment == 0 || gb_is_power_of_two(alignment));
	Type *type = me_type(value);
	GB_ASSERT(type != nullptr);
	GB_ASSERT(is_type_pointer(type));

	meInstruction *v = me_create_instruction(p, meOp_UnalignedLoad);
	v->type = type;
	v->ops[0] = me_use(value);
	v->op_count = 1;
	v->alignment = alignment;

	return me_value(v);
}

meValue me_emit_unaligned_load(meProcedure *p, meValue const &value) {
	return me_emit_unaligned_load_with_alignment_hint(p, value, 0);
}

void me_emit_store(meProcedure *p, meValue dst, meValue src) {
	Type *dst_type = me_type(dst);
	GB_ASSERT(is_type_pointer(dst_type));
	src = me_emit_conv(p, src, type_deref(dst_type));

	meInstruction *v = me_create_instruction(p, meOp_Store);
	v->ops[0] = me_use(dst);
	v->ops[1] = me_use(src);
	v->op_count = 2;
}

void me_emit_unaligned_store(meProcedure *p, meValue dst, meValue src) {
	Type *dst_type = me_type(dst);
	GB_ASSERT(is_type_pointer(dst_type));
	src = me_emit_conv(p, src, type_deref(dst_type));

	meInstruction *v = me_create_instruction(p, meOp_UnalignedStore);
	v->ops[0] = me_use(dst);
	v->ops[1] = me_use(src);
	v->op_count = 2;
}


meValue me_const_int(i64 value, Type *type) {
	meConstant *constant = me_new(meConstant);
	constant->value = exact_value_i64(value);
	constant->type = type;
	return me_value(constant);
}

meValue me_emit_gep(meProcedure *p, meValue value, isize index) {
	Type *ptr_type = me_type(value);
	GB_ASSERT(is_type_pointer(ptr_type));
	Type *t = base_type(type_deref(ptr_type));
	gb_unused(t);
	GB_ASSERT(index >= 0);

	Type *type = nullptr; // TODO(bill): type determination
	meInstruction *v = me_create_instruction(p, meOp_GetElementPtr);
	v->type = type;
	v->ops[0] = me_use(value);
	v->ops[1] = me_use(me_const_int(cast(i64)index, t_int));
	v->op_count = 2;

	return me_value(v);
}

meValue me_emit_ev(meProcedure *p, meValue value, isize index) {
	Type *value_type = me_type(value);
	GB_ASSERT(!is_type_pointer(value_type));
	Type *t = base_type(value_type);
	gb_unused(t);
	GB_ASSERT(index >= 0);

	Type *type = nullptr; // TODO(bill): type determination
	meInstruction *v = me_create_instruction(p, meOp_ExtractValue);
	v->type = type;
	v->ops[0] = me_use(value);
	v->ops[1] = me_use(me_const_int(cast(i64)index, t_int));
	v->op_count = 2;

	return me_value(v);
}


meValue me_emit_ptr_offset(meProcedure *p, meValue value, meValue offset) {
	Type *ptr_type = me_type(value);
	GB_ASSERT(is_type_pointer(ptr_type));

	meInstruction *v = me_create_instruction(p, meOp_PtrOffset);
	v->type = ptr_type;
	v->ops[0] = me_use(value);
	v->ops[1] = me_use(offset);
	v->op_count = 2;

	return me_value(v);
}

meValue me_emit_ptr_sub(meProcedure *p, meValue ptr0, meValue ptr1) {
	Type *p0 = me_type(ptr0);
	Type *p1 = me_type(ptr1);
	GB_ASSERT(is_type_pointer(p0));
	GB_ASSERT(is_type_pointer(p1));
	GB_ASSERT(are_types_identical(p0, p1));

	meInstruction *v = me_create_instruction(p, meOp_PtrSub);
	v->type = t_int;
	v->ops[0] = me_use(ptr0);
	v->ops[1] = me_use(ptr1);
	v->op_count = 2;

	return me_value(v);
}

meValue me_emit_conv(meProcedure *p, meValue value, Type *dst_type) {
	Type *src_type = me_type(value);
	GB_ASSERT(src_type != nullptr);
	GB_ASSERT(dst_type != nullptr);

	if (are_types_identical(src_type, dst_type)) {
		return value;
	}
	GB_ASSERT(internal_check_is_castable_to(src_type, dst_type));


	meInstruction *v = me_create_instruction(p, meOp_Cast);
	v->type = dst_type;
	v->ops[0] = me_use(value);
	v->op_count = 1;

	return me_value(v);
}

meValue me_emit_transmute(meProcedure *p, meValue value, Type *dst_type) {
	Type *src_type = me_type(value);
	GB_ASSERT(src_type != nullptr);
	GB_ASSERT(dst_type != nullptr);

	if (are_types_identical(src_type, dst_type)) {
		return value;
	}
	i64 src_sz = type_size_of(src_type);
	i64 dst_sz = type_size_of(dst_type);
	GB_ASSERT_MSG(src_sz == dst_sz, "%lld != %lld", cast(long long)src_sz, cast(long long)dst_sz);

	meInstruction *v = me_create_instruction(p, meOp_Transmute);
	v->type = dst_type;
	v->ops[0] = me_use(value);
	v->op_count = 1;

	return me_value(v);
}

meValue me_emit_comp_against_nil(meProcedure *p, meOpKind op, meValue value) {
	switch (op) {
	case meOp_Eq:
	case meOp_NotEq:
		break;
	default:
		GB_PANIC("Invalid comparison against nil op");
	}

	// TODO(bill): me_emit_comp_against_nil
	meInstruction *v = me_create_instruction(p, op);
	v->type = t_untyped_bool;
	v->ops[0] = me_use(value);
	v->op_count = 1;

	return me_value(v);
}


meValue me_emit_comp(meProcedure *p, meOpKind op, meValue left, meValue right) {
	switch (op) {
	case meOp_Eq:
	case meOp_NotEq:
	case meOp_Lt:
	case meOp_LtEq:
	case meOp_Gt:
	case meOp_GtEq:
		break;
	default:
		GB_PANIC("Invalid comparison op");
	}

	Type *lt = me_type(left);
	Type *rt = me_type(right);

	Type *a = core_type(lt);
	Type *b = core_type(rt);

	meValue nil_check = {};
	if (is_type_untyped_nil(lt)) {
		nil_check = me_emit_comp_against_nil(p, op, right);
	} else if (is_type_untyped_nil(rt)) {
		nil_check = me_emit_comp_against_nil(p, op, left);
	}
	if (nil_check.kind != meValue_Invalid) {
		return nil_check;
	}


	if (are_types_identical(a, b)) {
		// NOTE(bill): No need for a conversion
	} else if (me_is_const(left) || me_is_const_nil(left)) {
		left = me_emit_conv(p, left, rt);
	} else if (me_is_const(right) || me_is_const_nil(right)) {
		right = me_emit_conv(p, right, lt);
	} else {
		i64 ls = type_size_of(lt);
		i64 rs = type_size_of(rt);

		// NOTE(bill): Quick heuristic, larger types are usually the target type
		if (ls < rs) {
			left = me_emit_conv(p, left, rt);
		} else if (ls > rs) {
			right = me_emit_conv(p, right, lt);
		} else {
			if (is_type_union(rt)) {
				left = me_emit_conv(p, left, rt);
			} else {
				right = me_emit_conv(p, right, lt);
			}
		}
	}

	// TODO(bill): me_emit_comp

	meInstruction *v = me_create_instruction(p, op);
	v->type = t_untyped_bool;
	v->ops[0] = me_use(left);
	v->ops[1] = me_use(right);
	v->op_count = 2;

	return me_value(v);
}



meValue me_emit_min(meProcedure *p, meValue left, meValue right) {
	Type *lt = me_type(left);
	Type *rt = me_type(right);
	GB_ASSERT(are_types_identical(lt, rt));
	Type *type = lt;
	GB_ASSERT(is_type_ordered(type) && (is_type_numeric(type) || is_type_string(type)));

	// TODO(bill): optimization
	meInstruction *v = me_create_instruction(p, meOp_Min);
	v->type = type;
	v->ops[0] = me_use(left);
	v->ops[1] = me_use(right);
	v->op_count = 2;

	return me_value(v);
}

meValue me_emit_max(meProcedure *p, meValue left, meValue right) {
	Type *lt = me_type(left);
	Type *rt = me_type(right);
	GB_ASSERT(are_types_identical(lt, rt));
	Type *type = lt;
	GB_ASSERT(is_type_ordered(type) && (is_type_numeric(type) || is_type_string(type)));

	// TODO(bill): optimization
	meInstruction *v = me_create_instruction(p, meOp_Max);
	v->type = type;
	v->ops[0] = me_use(left);
	v->ops[1] = me_use(right);
	v->op_count = 2;

	return me_value(v);
}

meValue me_emit_select(meProcedure *p, meValue cond, meValue left, meValue right) {
	GB_ASSERT(is_type_boolean(me_type(cond)));
	GB_ASSERT(are_types_identical(me_type(left), me_type(right)));

	// TODO(bill): optimization
	meInstruction *v = me_create_instruction(p, meOp_Select);
	v->type = me_type(left);
	v->ops[0] = me_use(cond);
	v->ops[1] = me_use(left);
	v->ops[2] = me_use(right);
	v->op_count = 3;

	return me_value(v);
}

meValue me_emit_call(meProcedure *p, meValue proc, Slice<meValue> const &arguments, u16 instruction_flags = 0) {
	GB_PANIC("TODO");
	return {};
}
meValue me_emit_built_call(meProcedure *p, BuiltinProcId id, Slice<meValue> const &arguments) {
	GB_PANIC("TODO");
	return {};
}

meValue me_emit_swizzle(meProcedure *p, meValue value, Slice<i32> const &arguments) {
	GB_PANIC("TODO");
	return {};
}


meValue me_emit_fence(meProcedure *p, meAtomicOrderingKind atomic_ordering) {
	GB_PANIC("TODO");
	return {};
}

meValue me_emit_atomic_exchange(meProcedure *p, meValue left, meValue right, meAtomicOrderingKind atomic_ordering) {
	GB_PANIC("TODO");
	return {};
}


meValue me_emit_atomic_compare_exchange(meProcedure *p, meValue ptr, meValue left, meValue right, meAtomicOrderingKind atomic_ordering) {
	GB_PANIC("TODO");
	return {};
}


meValue me_emit_alias(meProcedure *p, meValue value) {
	if (value.kind == meValue_Instruction && value.instr->op == meOp_Alias) {
		return me_emit_alias(p, value.instr->ops[0]);
	}
	meInstruction *v = me_create_instruction(p, meOp_Alias);
	v->type = me_type(value);
	v->ops[0] = me_use(value);
	v->op_count = 1;
	return me_value(v);
}
