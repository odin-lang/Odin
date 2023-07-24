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
			rw_mutex_lock(&m->values_mutex);
			p = string_map_must_get(&m->procedures, key);
			rw_mutex_unlock(&m->values_mutex);
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
	p->split_returns_index = -1;

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
	if (p->name == "main") {
		// TODO(bill): figure out when this should be public or not
		linkage = TB_LINKAGE_PUBLIC;
	}

	if (p->symbol == nullptr)  {
		p->func = tb_function_create(m->mod, link_name.len, cast(char const *)link_name.text, linkage, TB_COMDAT_NONE);

		p->debug_type = cg_debug_type_for_proc(m, p->type);
		p->proto = tb_prototype_from_dbg(m->mod, p->debug_type);

		p->symbol = cast(TB_Symbol *)p->func;
	}

	p->value = cg_value(p->symbol, p->type);

	cg_add_symbol(m, entity, p->symbol);
	cg_add_entity(m, entity, p->value);
	cg_add_member(m, p->name, p->value);
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
	p->split_returns_index = -1;

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

	p->debug_type = cg_debug_type_for_proc(m, p->type);
	p->proto = tb_prototype_from_dbg(m->mod, p->debug_type);

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

	tb_function_set_prototype(p->func, p->proto, cg_arena());

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
	bool is_odin_like_cc = is_calling_convention_odin(pt->calling_convention);
	int param_index = 0;
	int param_count = p->proto->param_count;

	if (pt->results) {
		Type *result_type = nullptr;
		if (is_odin_like_cc) {
			result_type = pt->results->Tuple.variables[pt->results->Tuple.variables.count-1]->type;
		} else {
			result_type = pt->results;
		}
		TB_DebugType *debug_type = cg_debug_type(p->module, result_type);
		TB_PassingRule rule = tb_get_passing_rule_from_dbg(p->module->mod, debug_type, true);
		if (rule == TB_PASSING_INDIRECT) {
			p->return_by_ptr = true;
			param_index++;
		}
	}

	if (pt->params != nullptr) for (Entity *e : pt->params->Tuple.variables) {
		if (e->kind != Entity_Variable) {
			continue;
		}

		GB_ASSERT_MSG(param_index < param_count, "%d < %d %.*s :: %s", param_index, param_count, LIT(p->name), type_to_string(p->type));

		TB_Node *param_ptr = nullptr;

		TB_CharUnits size  = cast(TB_CharUnits)type_size_of(e->type);
		TB_CharUnits align = cast(TB_CharUnits)type_align_of(e->type);
		TB_DebugType *debug_type = cg_debug_type(p->module, e->type);
		TB_PassingRule rule = tb_get_passing_rule_from_dbg(p->module->mod, debug_type, false);
		switch (rule) {
		case TB_PASSING_DIRECT: {
			TB_Node *param = tb_inst_param(p->func, param_index++);
			param_ptr = tb_inst_local(p->func, size, align);
			tb_inst_store(p->func, param->dt, param_ptr, param, align, false);
		} break;
		case TB_PASSING_INDIRECT:
			// TODO(bill): does this need a copy? for non-odin calling convention stuff?
			param_ptr = tb_inst_param(p->func, param_index++);
			break;
		case TB_PASSING_IGNORE:
			continue;
		}

		GB_ASSERT(param_ptr->dt.type == TB_PTR);

		cgValue local = cg_value(param_ptr, alloc_type_pointer(e->type));

		if (e != nullptr && e->token.string.len > 0 && e->token.string != "_") {
			// NOTE(bill): for debugging purposes only
			String name = e->token.string;
			TB_DebugType *param_debug_type = debug_type;
			TB_Node *     param_ptr_to_use = param_ptr;
			if (rule == TB_PASSING_INDIRECT) {
				// HACK TODO(bill): this is just to get the debug information
				TB_CharUnits ptr_size = cast(TB_CharUnits)build_context.ptr_size;
				TB_Node *dummy_param = tb_inst_local(p->func, ptr_size, ptr_size);
				tb_inst_store(p->func, TB_TYPE_PTR, dummy_param, param_ptr, ptr_size, false);
				param_ptr_to_use = dummy_param;
				param_debug_type = tb_debug_create_ptr(p->module->mod, param_debug_type);
			}
			tb_node_append_attrib(
				param_ptr_to_use,
				tb_function_attrib_variable(
					p->func,
					name.len, cast(char const *)name.text,
					param_debug_type
				)
			);
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

	if (is_odin_like_cc) {
		p->split_returns_index = param_index;
	}

	if (pt->calling_convention == ProcCC_Odin) {
		// NOTE(bill): Push context on to stack from implicit parameter

		String name = str_lit("__.context_ptr");

		Entity *e = alloc_entity_param(nullptr, make_token_ident(name), t_context_ptr, false, false);
		e->flags |= EntityFlag_NoAlias;

		TB_Node *param_ptr = tb_inst_param(p->func, param_count-1);
		cgValue local = cg_value(param_ptr, t_context_ptr);
		cgAddr addr = cg_addr(local);
		map_set(&p->variable_map, e, addr);


		cgContextData *cd = array_add_and_get(&p->context_stack);
		cd->ctx = addr;
		cd->scope_index = -1;
		cd->uses = +1; // make sure it has been used already
	}

	if (pt->has_named_results) {
		auto const &results = pt->results->Tuple.variables;
		for_array(i, results) {
			Entity *e = results[i];
			GB_ASSERT(e->kind == Entity_Variable);

			if (e->token.string == "") {
				continue;
			}
			GB_ASSERT(!is_blank_ident(e->token));

			cgAddr res = cg_add_local(p, e->type, e, true);

			if (e->Variable.param_value.kind != ParameterValue_Invalid) {
				cgValue c = cg_handle_param_value(p, e->type, e->Variable.param_value, e->token.pos);
				cg_addr_store(p, res, c);
			}
		}
	}
}


gb_internal WORKER_TASK_PROC(cg_procedure_compile_worker_proc) {
	cgProcedure *p = cast(cgProcedure *)data;

	bool emit_asm = false;

	if (
	    // string_starts_with(p->name, str_lit("bug@main")) ||
	    false
	) {
		emit_asm = true;
	}

	TB_FunctionOutput *output = tb_module_compile_function(p->module->mod, p->func, TB_ISEL_FAST, emit_asm);
	if (emit_asm) {
		TB_Assembly *assembly = tb_output_get_asm(output);
		for (TB_Assembly *node = assembly; node != nullptr; node = node->next) {
			fprintf(stdout, "%.*s", cast(int)node->length, node->data);
		}
		fprintf(stdout, "\n");
	}

	return 0;
}

gb_internal void cg_procedure_end(cgProcedure *p) {
	if (p == nullptr || p->func == nullptr) {
		return;
	}
	if (tb_inst_get_control(p->func)) {
		GB_ASSERT(p->type->Proc.result_count == 0);
		tb_inst_ret(p->func, 0, nullptr);
	}

	if (p->module->do_threading) {
		thread_pool_add_task(cg_procedure_compile_worker_proc, p);
	} else {
		cg_procedure_compile_worker_proc(p);
	}
}

gb_internal void cg_procedure_generate(cgProcedure *p) {
	if (p->body == nullptr) {
		return;
	}


	cg_procedure_begin(p);
	cg_build_stmt(p, p->body);
	cg_procedure_end(p);


	if (
	    // string_starts_with(p->name, str_lit("bug@main")) ||
	    false
	) { // IR Printing
		TB_Arena *arena = tb_default_arena();
		defer (arena->free(arena));
		TB_FuncOpt *opt = tb_funcopt_enter(p->func, arena);
		defer (tb_funcopt_exit(opt));
		tb_funcopt_print(opt);
		fprintf(stdout, "\n");
	}
	if (false) { // GraphViz printing
		tb_function_print(p->func, tb_default_print_callback, stdout);
	}
}

gb_internal void cg_build_nested_proc(cgProcedure *p, AstProcLit *pd, Entity *e) {
	GB_ASSERT(pd->body != nullptr);
	cgModule *m = p->module;
	auto *min_dep_set = &m->info->minimum_dependency_set;

	if (ptr_set_exists(min_dep_set, e) == false) {
		// NOTE(bill): Nothing depends upon it so doesn't need to be built
		return;
	}

	// NOTE(bill): Generate a new name
	// parent.name-guid
	String original_name = e->token.string;
	String pd_name = original_name;
	if (e->Procedure.link_name.len > 0) {
		pd_name = e->Procedure.link_name;
	}


	isize name_len = p->name.len + 1 + pd_name.len + 1 + 10 + 1;
	char *name_text = gb_alloc_array(permanent_allocator(), char, name_len);

	i32 guid = cast(i32)p->children.count;
	name_len = gb_snprintf(name_text, name_len, "%.*s" ABI_PKG_NAME_SEPARATOR "%.*s-%d", LIT(p->name), LIT(pd_name), guid);
	String name = make_string(cast(u8 *)name_text, name_len-1);

	e->Procedure.link_name = name;

	cgProcedure *nested_proc = cg_procedure_create(p->module, e);
	e->cg_procedure = nested_proc;

	cgValue value = nested_proc->value;

	cg_add_entity(m, e, value);
	array_add(&p->children, nested_proc);
	cg_add_procedure_to_queue(nested_proc);
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
		GB_ASSERT(found->node != nullptr);
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
	}
	return res;
}

gb_internal cgValue cg_emit_call(cgProcedure * p, cgValue value, Slice<cgValue> const &args) {
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
	for_array(i, args) {
		Type *param_type = param_entities[i]->type;
		cgValue arg = args[i];
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
		} else {
			GB_ASSERT(multi_output.count == 1);
			TB_Node *node = multi_output.single;
			return cg_value(node, pt->results->Tuple.variables[0]->type);
		}
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

gb_internal cgValue cg_emit_runtime_call(cgProcedure *p, char const *name, Slice<cgValue> const &args) {
	AstPackage *pkg = p->module->info->runtime_package;
	Entity *e = scope_lookup_current(pkg->scope, make_string_c(name));
	cgValue value = cg_find_procedure_value_from_entity(p->module, e);
	return cg_emit_call(p, value, args);
}

gb_internal cgValue cg_handle_param_value(cgProcedure *p, Type *parameter_type, ParameterValue const &param_value, TokenPos const &pos) {
	switch (param_value.kind) {
	case ParameterValue_Constant:
		if (is_type_constant_type(parameter_type)) {
			auto res = cg_const_value(p, parameter_type, param_value.value);
			return res;
		} else {
			ExactValue ev = param_value.value;
			cgValue arg = {};
			Type *type = type_of_expr(param_value.original_ast_expr);
			if (type != nullptr) {
				arg = cg_const_value(p, type, ev);
			} else {
				arg = cg_const_value(p, parameter_type, param_value.value);
			}
			return cg_emit_conv(p, arg, parameter_type);
		}

	case ParameterValue_Nil:
		return cg_const_nil(p, parameter_type);
	case ParameterValue_Location:
		{
			String proc_name = {};
			if (p->entity != nullptr) {
				proc_name = p->entity->token.string;
			}
			return cg_emit_source_code_location_as_global(p, proc_name, pos);
		}
	case ParameterValue_Value:
		return cg_build_expr(p, param_value.ast_value);
	}
	return cg_const_nil(p, parameter_type);
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

		return cg_build_builtin(p, id, expr);
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
	GB_ASSERT(value.node != nullptr);
	GB_ASSERT(is_type_proc(value.type));

	TEMPORARY_ALLOCATOR_GUARD();

	Type *proc_type_ = base_type(value.type);
	GB_ASSERT(proc_type_->kind == Type_Proc);
	TypeProc *pt = &proc_type_->Proc;

	GB_ASSERT(ce->split_args != nullptr);

	auto args = array_make<cgValue>(temporary_allocator(), 0, pt->param_count);

	bool vari_expand = (ce->ellipsis.pos.line != 0);
	bool is_c_vararg = pt->c_vararg;

	for_array(i, ce->split_args->positional) {
		Entity *e = pt->params->Tuple.variables[i];
		if (e->kind == Entity_TypeName) {
			continue;
		} else if (e->kind == Entity_Constant) {
			continue;
		}

		GB_ASSERT(e->kind == Entity_Variable);

		if (pt->variadic && pt->variadic_index == i) {
			cgValue variadic_args = cg_const_nil(p, e->type);
			auto variadic = slice(ce->split_args->positional, pt->variadic_index, ce->split_args->positional.count);
			if (variadic.count != 0) {
				// variadic call argument generation
				Type *slice_type = e->type;
				GB_ASSERT(slice_type->kind == Type_Slice);

				if (is_c_vararg) {
					GB_ASSERT(!vari_expand);

					Type *elem_type = slice_type->Slice.elem;

					for (Ast *var_arg : variadic) {
						cgValue arg = cg_build_expr(p, var_arg);
						if (is_type_any(elem_type)) {
							array_add(&args, cg_emit_conv(p, arg, default_type(arg.type)));
						} else {
							array_add(&args, cg_emit_conv(p, arg, elem_type));
						}
					}
					break;
				} else if (vari_expand) {
					GB_ASSERT(variadic.count == 1);
					variadic_args = cg_build_expr(p, variadic[0]);
					variadic_args = cg_emit_conv(p, variadic_args, slice_type);
				} else {
					Type *elem_type = slice_type->Slice.elem;

					auto var_args = array_make<cgValue>(temporary_allocator(), 0, variadic.count);
					for (Ast *var_arg : variadic) {
						cgValue v = cg_build_expr(p, var_arg);
						cg_append_tuple_values(p, &var_args, v);
					}
					isize slice_len = var_args.count;
					if (slice_len > 0) {
						cgAddr slice = cg_add_local(p, slice_type, nullptr, true);
						cgAddr base_array = cg_add_local(p, alloc_type_array(elem_type, slice_len), nullptr, true);

						for (isize i = 0; i < var_args.count; i++) {
							cgValue addr = cg_emit_array_epi(p, base_array.addr, cast(i32)i);
							cgValue var_arg = var_args[i];
							var_arg = cg_emit_conv(p, var_arg, elem_type);
							cg_emit_store(p, addr, var_arg);
						}

						cgValue base_elem = cg_emit_array_epi(p, base_array.addr, 0);
						cgValue len = cg_const_int(p, t_int, slice_len);
						cg_fill_slice(p, slice, base_elem, len);

						variadic_args = cg_addr_load(p, slice);
					}
				}
			}
			array_add(&args, variadic_args);

			break;
		} else {
			cgValue value = cg_build_expr(p, ce->split_args->positional[i]);
			cg_append_tuple_values(p, &args, value);
		}
	}

	if (!is_c_vararg) {
		array_resize(&args, pt->param_count);
	}

	for (Ast *arg : ce->split_args->named) {
		ast_node(fv, FieldValue, arg);
		GB_ASSERT(fv->field->kind == Ast_Ident);
		String name = fv->field->Ident.token.string;
		gb_unused(name);
		isize param_index = lookup_procedure_parameter(pt, name);
		GB_ASSERT(param_index >= 0);

		cgValue value = cg_build_expr(p, fv->value);
		GB_ASSERT(!is_type_tuple(value.type));
		args[param_index] = value;
	}

	TokenPos pos = ast_token(ce->proc).pos;


	if (pt->params != nullptr)  {
		isize min_count = pt->params->Tuple.variables.count;
		if (is_c_vararg) {
			min_count -= 1;
		}
		GB_ASSERT(args.count >= min_count);
		for_array(arg_index, pt->params->Tuple.variables) {
			Entity *e = pt->params->Tuple.variables[arg_index];
			if (pt->variadic && arg_index == pt->variadic_index) {
				if (!is_c_vararg && args[arg_index].node == nullptr) {
					args[arg_index] = cg_const_nil(p, e->type);
				}
				continue;
			}

			cgValue arg = args[arg_index];
			if (arg.node == nullptr) {
				switch (e->kind) {
				case Entity_TypeName:
				case Entity_Constant:
					break;
				case Entity_Variable:
					args[arg_index] = cg_handle_param_value(p, e->type, e->Variable.param_value, pos);
					break;
				default:
					GB_PANIC("Unknown entity kind %.*s\n", LIT(entity_strings[e->kind]));
				}
			} else {
				args[arg_index] = cg_emit_conv(p, arg, e->type);
			}
		}
	}

	isize final_count = is_c_vararg ? args.count : pt->param_count;
	auto call_args = slice(args, 0, final_count);

	return cg_emit_call(p, value, call_args);
}
