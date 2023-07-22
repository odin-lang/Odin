gb_internal TB_FunctionPrototype *cg_procedure_type_as_prototype(cgModule *m, Type *type) {
	GB_ASSERT(is_type_proc(type));
	mutex_lock(&m->proc_proto_mutex);
	defer (mutex_unlock(&m->proc_proto_mutex));

	if (type->kind == Type_Named) {
		type = base_type(type);
	}
	TB_FunctionPrototype **found = map_get(&m->proc_proto_map, type);
	if (found) {
		return *found;
	}

	TB_DebugType *dbg = cg_debug_type_for_proc(m, type);
	TB_FunctionPrototype *proto = tb_prototype_from_dbg(m->mod, dbg);

	map_set(&m->proc_proto_map, type, proto);
	return proto;
}

gb_internal cgProcedure *cg_procedure_create(cgModule *m, Entity *entity, bool ignore_body=false) {
	GB_ASSERT(entity != nullptr);
	GB_ASSERT(entity->kind == Entity_Procedure);
	if (!entity->Procedure.is_foreign) {
		if ((entity->flags & EntityFlag_ProcBodyChecked) == 0) {
			GB_PANIC("%.*s :: %s (was parapoly: %d %d)", LIT(entity->token.string), type_to_string(entity->type), is_type_polymorphic(entity->type, true), is_type_polymorphic(entity->type, false));
		}
	}

	String link_name = cg_get_entity_name(m, entity);

	cgProcedure *p = nullptr;
	{
		StringHashKey key = string_hash_string(link_name);
		cgValue *found = string_map_get(&m->members, key);
		if (found) {
			cg_add_entity(m, entity, *found);
			p = string_map_must_get(&m->procedures, key);
			if (!ignore_body && p->func != nullptr) {
				return nullptr;
			}
		}
	}

	if (p == nullptr) {
		p = gb_alloc_item(permanent_allocator(), cgProcedure);
	}

	p->module = m;
	p->entity = entity;
	p->name = link_name;

	DeclInfo *decl = entity->decl_info;

	ast_node(pl, ProcLit, decl->proc_lit);
	Type *pt = base_type(entity->type);
	GB_ASSERT(pt->kind == Type_Proc);

	p->type           = entity->type;
	p->type_expr      = decl->type_expr;
	p->body           = pl->body;
	p->inlining       = pl->inlining;
	p->is_foreign     = entity->Procedure.is_foreign;
	p->is_export      = entity->Procedure.is_export;
	p->is_entry_point = false;

	gbAllocator a = heap_allocator();
	p->children.allocator      = a;

	p->defer_stack.allocator   = a;
	p->scope_stack.allocator   = a;
	p->context_stack.allocator = a;

	p->control_regions.allocator = a;
	p->branch_regions.allocator = a;

	map_init(&p->variable_map);

	TB_Linkage linkage = TB_LINKAGE_PRIVATE;
	if (p->is_export) {
		linkage = TB_LINKAGE_PUBLIC;
	} else if (p->is_foreign || ignore_body) {
		if (ignore_body) {
			linkage = TB_LINKAGE_PUBLIC;
		}
		p->symbol = cast(TB_Symbol *)tb_extern_create(m->mod, link_name.len, cast(char const *)link_name.text, TB_EXTERNAL_SO_LOCAL);
	}

	if (p->symbol == nullptr)  {
		p->func = tb_function_create(m->mod, link_name.len, cast(char const *)link_name.text, linkage, TB_COMDAT_NONE);

		size_t out_param_count = 0;
		p->debug_type = cg_debug_type_for_proc(m, p->type);
		TB_Node **params = tb_function_set_prototype_from_dbg(p->func, p->debug_type, cg_arena(), &out_param_count);
		p->param_nodes = {params, cast(isize)out_param_count};
		p->proto = tb_function_get_prototype(p->func);

		p->symbol = cast(TB_Symbol *)p->func;
	}

	cgValue proc_value = cg_value(p->symbol, p->type);
	cg_add_entity(m, entity, proc_value);
	cg_add_member(m, p->name, proc_value);
	cg_add_procedure_value(m, p);


	return p;
}

gb_internal cgProcedure *cg_procedure_create_dummy(cgModule *m, String const &link_name, Type *type) {
	auto *prev_found = string_map_get(&m->members, link_name);
	GB_ASSERT_MSG(prev_found == nullptr, "failed to create dummy procedure for: %.*s", LIT(link_name));

	cgProcedure *p = gb_alloc_item(permanent_allocator(), cgProcedure);

	p->module = m;
	p->name = link_name;

	p->type           = type;
	p->type_expr      = nullptr;
	p->body           = nullptr;
	p->tags           = 0;
	p->inlining       = ProcInlining_none;
	p->is_foreign     = false;
	p->is_export      = false;
	p->is_entry_point = false;

	gbAllocator a = heap_allocator();
	p->children.allocator      = a;

	p->defer_stack.allocator   = a;
	p->scope_stack.allocator   = a;
	p->context_stack.allocator = a;

	p->control_regions.allocator = a;
	p->branch_regions.allocator = a;

	map_init(&p->variable_map);


	TB_Linkage linkage = TB_LINKAGE_PRIVATE;

	p->func = tb_function_create(m->mod, link_name.len, cast(char const *)link_name.text, linkage, TB_COMDAT_NONE);

	size_t out_param_count = 0;
	p->debug_type = cg_debug_type_for_proc(m, p->type);
	TB_Node **params = tb_function_set_prototype_from_dbg(p->func, p->debug_type, cg_arena(), &out_param_count);
	p->param_nodes = {params, cast(isize)out_param_count};
	p->proto = tb_function_get_prototype(p->func);


	p->symbol = cast(TB_Symbol *)p->func;

	cgValue proc_value = cg_value(p->symbol, p->type);
	cg_add_member(m, p->name, proc_value);
	cg_add_procedure_value(m, p);

	return p;
}

gb_internal void cg_procedure_begin(cgProcedure *p) {
	if (p == nullptr || p->func == nullptr) {
		return;
	}

	if (p->body == nullptr) {
		return;
	}


	DeclInfo *decl = decl_info_of_entity(p->entity);
	if (decl != nullptr) {
		for_array(i, decl->labels) {
			BlockLabel bl = decl->labels[i];
			cgBranchRegions bb = {bl.label, nullptr, nullptr};
			array_add(&p->branch_regions, bb);
		}
	}

	GB_ASSERT(p->type->kind == Type_Proc);
	TypeProc *pt = &p->type->Proc;
	int param_index = 0;
	if (pt->params != nullptr) for (Entity *e : pt->params->Tuple.variables) {
		if (e->kind != Entity_Variable) {
			continue;
		}

		if (param_index >= p->param_nodes.count) {
			break;
		}

		TB_Node *param = p->param_nodes[param_index++];
		cgValue local = cg_value(param, alloc_type_pointer(e->type));

		if (e != nullptr && e->token.string.len > 0 && e->token.string != "_") {
			// NOTE(bill): for debugging purposes only
			String name = e->token.string;
			TB_DebugType *debug_type = cg_debug_type(p->module, e->type);
			tb_node_append_attrib(param, tb_function_attrib_variable(p->func, name.len, cast(char const *)name.text, debug_type));

		}
		cgAddr addr = cg_addr(local);
		if (e) {
			map_set(&p->variable_map, e, addr);
		}

		// if (arg_type->kind == lbArg_Ignore) {
		// 	continue;
		// } else if (arg_type->kind == lbArg_Direct) {
		// 	if (e->token.string.len != 0 && !is_blank_ident(e->token.string)) {
		// 		LLVMTypeRef param_type = lb_type(p->module, e->type);
		// 		LLVMValueRef original_value = LLVMGetParam(p->value, param_offset+param_index);
		// 		LLVMValueRef value = OdinLLVMBuildTransmute(p, original_value, param_type);

		// 		lbValue param = {};
		// 		param.value = value;
		// 		param.type = e->type;

		// 		map_set(&p->direct_parameters, e, param);

		// 		lbValue ptr = lb_address_from_load_or_generate_local(p, param);
		// 		GB_ASSERT(LLVMIsAAllocaInst(ptr.value));
		// 		lb_add_entity(p->module, e, ptr);

		// 		lbBlock *block = p->decl_block;
		// 		if (original_value != value) {
		// 			block = p->curr_block;
		// 		}
		// 		LLVMValueRef debug_storage_value = value;
		// 		if (original_value != value && LLVMIsALoadInst(value)) {
		// 			debug_storage_value = LLVMGetOperand(value, 0);
		// 		}
		// 		lb_add_debug_param_variable(p, debug_storage_value, e->type, e->token, param_index+1, block, arg_type->kind);
		// 	}
		// } else if (arg_type->kind == lbArg_Indirect) {
		// 	if (e->token.string.len != 0 && !is_blank_ident(e->token.string)) {
		// 		lbValue ptr = {};
		// 		ptr.value = LLVMGetParam(p->value, param_offset+param_index);
		// 		ptr.type = alloc_type_pointer(e->type);
		// 		lb_add_entity(p->module, e, ptr);
		// 		lb_add_debug_param_variable(p, ptr.value, e->type, e->token, param_index+1, p->decl_block, arg_type->kind);
		// 	}
		// }
	}

	if (p->type->Proc.calling_convention == ProcCC_Odin) {
		// NOTE(bill): Push context on to stack from implicit parameter

		String name = str_lit("__.context_ptr");

		Entity *e = alloc_entity_param(nullptr, make_token_ident(name), t_context_ptr, false, false);
		e->flags |= EntityFlag_NoAlias;

		TB_Node *param = p->param_nodes[p->param_nodes.count-1];
		param = tb_inst_load(p->func, TB_TYPE_PTR, param, cast(TB_CharUnits)build_context.ptr_size, false);

		cgValue local = cg_value(param, t_context_ptr);
		cgAddr addr = cg_addr(local);
		map_set(&p->variable_map, e, addr);


		cgContextData *cd = array_add_and_get(&p->context_stack);
		cd->ctx = addr;
		cd->scope_index = -1;
		cd->uses = +1; // make sure it has been used already
	}
}

gb_internal void cg_procedure_end(cgProcedure *p) {
	if (p == nullptr || p->func == nullptr) {
		return;
	}
	if (tb_inst_get_control(p->func)) {
		tb_inst_ret(p->func, 0, nullptr);
	}
	bool emit_asm = false;
	// if (p->name == "main") {
	if (
	    p->name == "bug" ABI_PKG_NAME_SEPARATOR "main" ||
	    // p->name == "main" ||
	    false
	) {
		TB_Arena *arena = tb_default_arena();
		defer (arena->free(arena));
		TB_FuncOpt *opt = tb_funcopt_enter(p->func, arena);
		defer (tb_funcopt_exit(opt));
		tb_funcopt_print(opt);

		// emit_asm = true;

		// GraphViz printing
		// tb_function_print(p->func, tb_default_print_callback, stdout);
	}
	TB_FunctionOutput *output = tb_module_compile_function(p->module->mod, p->func, TB_ISEL_FAST, emit_asm);
	if (emit_asm) {
		TB_Assembly *assembly = tb_output_get_asm(output);
		for (TB_Assembly *node = assembly; node != nullptr; node = node->next) {
			gb_printf_err("%.*s", cast(int)node->length, node->data);
		}
		gb_printf_err("\n");
	}
}

gb_internal void cg_procedure_generate(cgProcedure *p) {
	if (p->body == nullptr) {
		return;
	}
	cg_procedure_begin(p);
	defer (cg_procedure_end(p));

	if (p->name != "bug" ABI_PKG_NAME_SEPARATOR "main" &&
	    p->name != "main") {
		return;
	}
	cg_build_stmt(p, p->body);
}



gb_internal cgValue cg_find_procedure_value_from_entity(cgModule *m, Entity *e) {
	GB_ASSERT(is_type_proc(e->type));
	e = strip_entity_wrapping(e);
	GB_ASSERT(e != nullptr);
	GB_ASSERT(e->kind == Entity_Procedure);

	cgValue *found = nullptr;
	rw_mutex_shared_lock(&m->values_mutex);
	found = map_get(&m->values, e);
	rw_mutex_shared_unlock(&m->values_mutex);
	if (found) {
		return *found;
	}

	GB_PANIC("Error in: %s, missing procedure %.*s\n", token_pos_to_string(e->token.pos), LIT(e->token.string));
	return {};
}



gb_internal cgValue cg_build_call_expr_internal(cgProcedure *p, Ast *expr);
gb_internal cgValue cg_build_call_expr(cgProcedure *p, Ast *expr) {
	expr = unparen_expr(expr);
	ast_node(ce, CallExpr, expr);

	cgValue res = cg_build_call_expr_internal(p, expr);

	if (ce->optional_ok_one) { // TODO(bill): Minor hack for #optional_ok procedures
		GB_ASSERT(res.kind == cgValue_Multi);
		GB_ASSERT(res.multi->values.count == 2);
		return res.multi->values[0];
		// GB_ASSERT(is_type_tuple(res.type));
		// GB_ASSERT(res.type->Tuple.variables.count == 2);
		// return cg_emit_struct_ev(p, res, 0);
	}
	return res;
}

gb_internal cgValue cg_emit_call(cgProcedure * p, cgValue value, Slice<cgValue> args) {
	if (value.kind == cgValue_Symbol) {
		value = cg_value(tb_inst_get_symbol_address(p->func, value.symbol), value.type);
	}
	GB_ASSERT(value.kind == cgValue_Value);
	TEMPORARY_ALLOCATOR_GUARD();

	TB_Module *m = p->module->mod;


	Type *type = base_type(value.type);
	GB_ASSERT(type->kind == Type_Proc);
	TypeProc *pt = &type->Proc;
	gb_unused(pt);

	TB_FunctionPrototype *proto = cg_procedure_type_as_prototype(p->module, type);
	TB_Node *target = value.node;
	auto params = slice_make<TB_Node *>(temporary_allocator(), proto->param_count);


	GB_ASSERT(build_context.metrics.os == TargetOs_windows);
	// TODO(bill): Support more than Win64 ABI

	bool is_odin_like_cc = is_calling_convention_odin(pt->calling_convention);

	bool return_is_indirect = false;

	Slice<Entity *> result_entities = {};
	Slice<Entity *> param_entities  = {};
	if (pt->results) {
		result_entities = pt->results->Tuple.variables;
	}
	if (pt->params) {
		param_entities = pt->params->Tuple.variables;
	}

	isize param_index = 0;
	if (pt->result_count != 0) {
		Type *return_type = nullptr;
		if (is_odin_like_cc) {
			return_type = result_entities[result_entities.count-1]->type;
		} else {
			return_type = pt->results;
		}
		TB_DebugType *dbg = cg_debug_type(p->module, return_type);
		TB_PassingRule rule = tb_get_passing_rule_from_dbg(m, dbg, true);
		if (rule == TB_PASSING_INDIRECT) {
			return_is_indirect = true;
			TB_CharUnits size = cast(TB_CharUnits)type_size_of(return_type);
			TB_CharUnits align = cast(TB_CharUnits)gb_max(type_align_of(return_type), 16);
			TB_Node *local = tb_inst_local(p->func, size, align);
			tb_inst_memzero(p->func, local, tb_inst_uint(p->func, TB_TYPE_INT, size), align, false);
			params[param_index++] = local;
		}
	}
	for (cgValue arg : args) {
		Type *param_type = param_entities[param_index]->type;
		arg = cg_emit_conv(p, arg, param_type);
		arg = cg_flatten_value(p, arg);

		TB_Node *param = nullptr;

		TB_DebugType *dbg = cg_debug_type(p->module, param_type);
		TB_PassingRule rule = tb_get_passing_rule_from_dbg(m, dbg, false);
		switch (rule) {
		case TB_PASSING_DIRECT:
			GB_ASSERT(arg.kind == cgValue_Value);
			param = arg.node;
			break;
		case TB_PASSING_INDIRECT:
			{
				cgValue arg_ptr = {};
				// indirect
				if (is_odin_like_cc) {
					arg_ptr = cg_address_from_load_or_generate_local(p, arg);
				} else {
					arg_ptr = cg_copy_value_to_ptr(p, arg, param_type, 16);
				}
				GB_ASSERT(arg_ptr.kind == cgValue_Value);
				param = arg_ptr.node;
			}
			break;
		case TB_PASSING_IGNORE:
			continue;
		}

		params[param_index++] = param;
	}

	// Split returns
	isize split_offset = -1;
	if (is_odin_like_cc) {
		split_offset = param_index;
		for (isize i = 0; i < pt->result_count-1; i++) {
			Type *result = result_entities[i]->type;
			TB_CharUnits size = cast(TB_CharUnits)type_size_of(result);
			TB_CharUnits align = cast(TB_CharUnits)gb_max(type_align_of(result), 16);
			TB_Node *local = tb_inst_local(p->func, size, align);
			// TODO(bill): Should this need to be zeroed any way?
			tb_inst_memzero(p->func, local, tb_inst_uint(p->func, TB_TYPE_INT, size), align, false);
			params[param_index++] = local;
		}
	}

	if (pt->calling_convention == ProcCC_Odin) {
		cgValue ctx_ptr = cg_find_or_generate_context_ptr(p).addr;
		GB_ASSERT(ctx_ptr.kind == cgValue_Value);
		params[param_index++] = ctx_ptr.node;
	}
	GB_ASSERT_MSG(param_index == params.count, "%td vs %td\n %s %u %u",
	              param_index, params.count,
	              type_to_string(type),
	              proto->return_count,
	              proto->param_count);

	for (TB_Node *param : params) {
		GB_ASSERT(param != nullptr);
	}

	GB_ASSERT(target != nullptr);
	TB_MultiOutput multi_output = tb_inst_call(p->func, proto, target, params.count, params.data);
	gb_unused(multi_output);

	switch (pt->result_count) {
	case 0:
		return {};
	case 1:
		if (return_is_indirect) {
			return cg_lvalue_addr(params[0], pt->results->Tuple.variables[0]->type);
		}
		GB_ASSERT(multi_output.count == 1);
		return cg_value(multi_output.single, pt->results->Tuple.variables[0]->type);
	}

	cgValueMulti *multi = gb_alloc_item(permanent_allocator(), cgValueMulti);
	multi->values = slice_make<cgValue>(permanent_allocator(), pt->result_count);

	if (is_odin_like_cc) {
		GB_ASSERT(split_offset >= 0);
		for (isize i = 0; i < pt->result_count-1; i++) {
			multi->values[i] = cg_lvalue_addr(params[split_offset+i], result_entities[i]->type);
		}

		Type *end_type = result_entities[pt->result_count-1]->type;
		if (return_is_indirect) {
			multi->values[pt->result_count-1] = cg_lvalue_addr(params[0], end_type);
		} else {
			GB_ASSERT(multi_output.count == 1);
			TB_DataType dt = cg_data_type(end_type);
			TB_Node *res = multi_output.single;
			if (res->dt.raw != dt.raw) {
				// struct-like returns passed in registers
				TB_CharUnits size  = cast(TB_CharUnits)type_size_of(end_type);
				TB_CharUnits align = cast(TB_CharUnits)type_align_of(end_type);
				TB_Node *addr = tb_inst_local(p->func, size, align);
				tb_inst_store(p->func, res->dt, addr, res, align, false);
				multi->values[pt->result_count-1] = cg_lvalue_addr(addr, end_type);
			} else {
				multi->values[pt->result_count-1] = cg_value(res, end_type);
			}
		}
	} else {
		TB_Node *the_tuple = {};
		if (return_is_indirect) {
			the_tuple = params[0];
		} else {
			GB_ASSERT(multi_output.count == 1);
			TB_Node *res = multi_output.single;

			// struct-like returns passed in registers
			TB_CharUnits size  = cast(TB_CharUnits)type_size_of(pt->results);
			TB_CharUnits align = cast(TB_CharUnits)type_align_of(pt->results);
			the_tuple = tb_inst_local(p->func, size, align);
			tb_inst_store(p->func, res->dt, the_tuple, res, align, false);
		}
		for (isize i = 0; i < pt->result_count; i++) {
			i64 offset = type_offset_of(pt->results, i, nullptr);
			TB_Node *ptr = tb_inst_member_access(p->func, the_tuple, offset);
			multi->values[i] = cg_lvalue_addr(ptr, result_entities[i]->type);
		}
	}

	return cg_value_multi(multi, pt->results);
}

gb_internal cgValue cg_build_call_expr_internal(cgProcedure *p, Ast *expr) {
	ast_node(ce, CallExpr, expr);

	TypeAndValue tv = type_and_value_of_expr(expr);

	TypeAndValue proc_tv = type_and_value_of_expr(ce->proc);
	AddressingMode proc_mode = proc_tv.mode;
	if (proc_mode == Addressing_Type) {
		GB_ASSERT(ce->args.count == 1);
		cgValue x = cg_build_expr(p, ce->args[0]);
		return cg_emit_conv(p, x, tv.type);
	}

	Ast *proc_expr = unparen_expr(ce->proc);
	if (proc_mode == Addressing_Builtin) {
		Entity *e = entity_of_node(proc_expr);
		BuiltinProcId id = BuiltinProc_Invalid;
		if (e != nullptr) {
			id = cast(BuiltinProcId)e->Builtin.id;
		} else {
			id = BuiltinProc_DIRECTIVE;
		}
		if (id == BuiltinProc___entry_point) {
			if (p->module->info->entry_point) {
				cgValue entry_point = cg_find_procedure_value_from_entity(p->module, p->module->info->entry_point);
				GB_ASSERT(entry_point.node != nullptr);
				cg_emit_call(p, entry_point, {});
			}
			return {};
		}
		GB_PANIC("TODO(bill): builtin procs %d %.*s", id, LIT(builtin_procs[id].name));
	}

	// NOTE(bill): Regular call
	cgValue value = {};

	Entity *proc_entity = entity_of_node(proc_expr);
	if (proc_entity != nullptr) {
		if (proc_entity->flags & EntityFlag_Disabled) {
			GB_ASSERT(tv.type == nullptr);
			return {};
		}
	}

	if (proc_expr->tav.mode == Addressing_Constant) {
		ExactValue v = proc_expr->tav.value;
		switch (v.kind) {
		case ExactValue_Integer:
			{
				u64 u = big_int_to_u64(&v.value_integer);
				cgValue x = cg_value(tb_inst_uint(p->func, TB_TYPE_PTR, u), t_rawptr);
				value = cg_emit_conv(p, x, proc_expr->tav.type);
				break;
			}
		case ExactValue_Pointer:
			{
				u64 u = cast(u64)v.value_pointer;
				cgValue x = cg_value(tb_inst_uint(p->func, TB_TYPE_PTR, u), t_rawptr);
				value = cg_emit_conv(p, x, proc_expr->tav.type);
				break;
			}
		}
	}

	if (value.node == nullptr) {
		value = cg_build_expr(p, proc_expr);
	}
	if (value.kind == cgValue_Addr) {
		value = cg_emit_load(p, value);
	}
	GB_ASSERT(value.kind == cgValue_Value);
	GB_ASSERT(is_type_proc(value.type));

	return cg_emit_call(p, value, {});
}
