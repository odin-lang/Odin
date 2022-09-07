
LLVMValueRef lb_call_intrinsic(lbProcedure *p, const char *name, LLVMValueRef* args, unsigned arg_count, LLVMTypeRef* types, unsigned type_count)
{
	unsigned id = LLVMLookupIntrinsicID(name, gb_strlen(name));
	GB_ASSERT_MSG(id != 0, "Unable to find %s", name);
	LLVMValueRef ip = LLVMGetIntrinsicDeclaration(p->module->mod, id, types, type_count);
	LLVMTypeRef call_type = LLVMIntrinsicGetType(p->module->ctx, id, types, type_count);
	return LLVMBuildCall2(p->builder, call_type, ip, args, arg_count, "");
}

void lb_mem_copy_overlapping(lbProcedure *p, lbValue dst, lbValue src, lbValue len, bool is_volatile) {
	dst = lb_emit_conv(p, dst, t_rawptr);
	src = lb_emit_conv(p, src, t_rawptr);
	len = lb_emit_conv(p, len, t_int);
	
	char const *name = "llvm.memmove";
	if (LLVMIsConstant(len.value)) {
		i64 const_len = cast(i64)LLVMConstIntGetSExtValue(len.value);
		if (const_len <= 4*build_context.word_size) {
			name = "llvm.memmove.inline";
		}
	}
	LLVMTypeRef types[3] = {
		lb_type(p->module, t_rawptr),
		lb_type(p->module, t_rawptr),
		lb_type(p->module, t_int)
	};
	LLVMValueRef args[4] = {
		dst.value,
		src.value,
		len.value,
		LLVMConstInt(LLVMInt1TypeInContext(p->module->ctx), 0, is_volatile)
	};

	lb_call_intrinsic(p, name, args, gb_count_of(args), types, gb_count_of(types));
}



void lb_mem_copy_non_overlapping(lbProcedure *p, lbValue dst, lbValue src, lbValue len, bool is_volatile) {
	dst = lb_emit_conv(p, dst, t_rawptr);
	src = lb_emit_conv(p, src, t_rawptr);
	len = lb_emit_conv(p, len, t_int);
	
	char const *name = "llvm.memcpy";
	if (LLVMIsConstant(len.value)) {
		i64 const_len = cast(i64)LLVMConstIntGetSExtValue(len.value);
		if (const_len <= 4*build_context.word_size) {
			name = "llvm.memcpy.inline";
		}
	}

	LLVMTypeRef types[3] = {
		lb_type(p->module, t_rawptr),
		lb_type(p->module, t_rawptr),
		lb_type(p->module, t_int)
	};

	LLVMValueRef args[4] = {
			dst.value,
			src.value,
			len.value,
			LLVMConstInt(LLVMInt1TypeInContext(p->module->ctx), 0, is_volatile) };

	lb_call_intrinsic(p, name, args, gb_count_of(args), types, gb_count_of(types));
}


lbProcedure *lb_create_procedure(lbModule *m, Entity *entity, bool ignore_body) {
	GB_ASSERT(entity != nullptr);
	GB_ASSERT(entity->kind == Entity_Procedure);
	if (!entity->Procedure.is_foreign) {
		GB_ASSERT_MSG(entity->flags & EntityFlag_ProcBodyChecked, "%.*s :: %s", LIT(entity->token.string), type_to_string(entity->type));
	}

	String link_name = {};

	if (ignore_body) {
		lbModule *other_module = lb_pkg_module(m->gen, entity->pkg);
		link_name = lb_get_entity_name(other_module, entity);
	} else {
		link_name = lb_get_entity_name(m, entity);
	}

	{
		StringHashKey key = string_hash_string(link_name);
		lbValue *found = string_map_get(&m->members, key);
		if (found) {
			lb_add_entity(m, entity, *found);
			return string_map_must_get(&m->procedures, key);
		}
	}


	lbProcedure *p = gb_alloc_item(permanent_allocator(), lbProcedure);

	p->module = m;
	entity->code_gen_module = m;
	entity->code_gen_procedure = p;
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
	p->defer_stmts.allocator   = a;
	p->blocks.allocator        = a;
	p->branch_blocks.allocator = a;
	p->context_stack.allocator = a;
	p->scope_stack.allocator   = a;
	map_init(&p->selector_values, a, 0);
	map_init(&p->selector_addr,   a, 0);

	if (p->is_foreign) {
		lb_add_foreign_library_path(p->module, entity->Procedure.foreign_library);
	}

	char *c_link_name = alloc_cstring(permanent_allocator(), p->name);
	LLVMTypeRef func_type = lb_get_procedure_raw_type(m, p->type);

	p->value = LLVMAddFunction(m->mod, c_link_name, func_type);

	lb_ensure_abi_function_type(m, p);
	lb_add_function_type_attributes(p->value, p->abi_function_type, p->abi_function_type->calling_convention);
	
	if (pt->Proc.diverging) {
		lb_add_attribute_to_proc(m, p->value, "noreturn");
	}

	if (pt->Proc.calling_convention == ProcCC_Naked) {
		lb_add_attribute_to_proc(m, p->value, "naked");
	}

	if (!entity->Procedure.is_foreign && build_context.disable_red_zone) {
		lb_add_attribute_to_proc(m, p->value, "noredzone");
	}


	switch (p->inlining) {
	case ProcInlining_inline:
		lb_add_attribute_to_proc(m, p->value, "alwaysinline");
		break;
	case ProcInlining_no_inline:
		lb_add_attribute_to_proc(m, p->value, "noinline");
		break;
	}

	switch (entity->Procedure.optimization_mode) {
	case ProcedureOptimizationMode_None:
		lb_add_attribute_to_proc(m, p->value, "optnone");
		break;
	case ProcedureOptimizationMode_Minimal:
		lb_add_attribute_to_proc(m, p->value, "optnone");
		break;
	case ProcedureOptimizationMode_Size:
		lb_add_attribute_to_proc(m, p->value, "optsize");
		break;
	case ProcedureOptimizationMode_Speed:
		// TODO(bill): handle this correctly
		lb_add_attribute_to_proc(m, p->value, "optsize");
		break;
	}

	if (!entity->Procedure.target_feature_disabled &&
	    entity->Procedure.target_feature.len != 0) {
	    	auto features = split_by_comma(entity->Procedure.target_feature);
		for_array(i, features) {
			String feature = features[i];
			LLVMAttributeRef ref = LLVMCreateStringAttribute(
				m->ctx,
				cast(char const *)feature.text, cast(unsigned)feature.len,
				"", 0);
			LLVMAddAttributeAtIndex(p->value, LLVMAttributeIndex_FunctionIndex, ref);
		}
	}

	if (entity->flags & EntityFlag_Cold) {
		lb_add_attribute_to_proc(m, p->value, "cold");
	}

	lbValue proc_value = {p->value, p->type};
	lb_add_entity(m, entity,  proc_value);
	lb_add_member(m, p->name, proc_value);
	lb_add_procedure_value(m, p);

	if (p->is_export) {
		LLVMSetLinkage(p->value, LLVMDLLExportLinkage);
		LLVMSetDLLStorageClass(p->value, LLVMDLLExportStorageClass);
		LLVMSetVisibility(p->value, LLVMDefaultVisibility);

		lb_set_wasm_export_attributes(p->value, p->name);
	} else if (!p->is_foreign) {
		if (!USE_SEPARATE_MODULES) {
			LLVMSetLinkage(p->value, LLVMInternalLinkage);

			// NOTE(bill): if a procedure is defined in package runtime and uses a custom link name,
			// then it is very likely it is required by LLVM and thus cannot have internal linkage
			if (entity->pkg != nullptr && entity->pkg->kind == Package_Runtime && p->body != nullptr) {
				GB_ASSERT(entity->kind == Entity_Procedure);
				String link_name = entity->Procedure.link_name;
				if (entity->flags & EntityFlag_CustomLinkName && 
					link_name != "") {
					if (string_starts_with(link_name, str_lit("__"))) {
						LLVMSetLinkage(p->value, LLVMExternalLinkage);
					} else {
						LLVMSetLinkage(p->value, LLVMInternalLinkage);
					}
				}
			}
		}
	}
	lb_set_linkage_from_entity_flags(p->module, p->value, entity->flags);


	if (p->is_foreign) {
		lb_set_wasm_import_attributes(p->value, entity, p->name);
	}


	// NOTE(bill): offset==0 is the return value
	isize offset = 1;
	if (pt->Proc.return_by_pointer) {
		offset = 2;
	}

	isize parameter_index = 0;
	if (pt->Proc.param_count) {
		TypeTuple *params = &pt->Proc.params->Tuple;
		for (isize i = 0; i < pt->Proc.param_count; i++) {
			Entity *e = params->variables[i];
			if (e->kind != Entity_Variable) {
				continue;
			}

			if (i+1 == params->variables.count && pt->Proc.c_vararg) {
				continue;
			}

			if (e->flags&EntityFlag_NoAlias) {
				lb_add_proc_attribute_at_index(p, offset+parameter_index, "noalias");
			}
			parameter_index += 1;
		}
	}

	if (ignore_body) {
		p->body = nullptr;
		LLVMSetLinkage(p->value, LLVMExternalLinkage);
	}


	if (m->debug_builder) { // Debug Information
		Type *bt = base_type(p->type);

		unsigned line = cast(unsigned)entity->token.pos.line;

		LLVMMetadataRef scope = nullptr;
		LLVMMetadataRef file = nullptr;
		LLVMMetadataRef type = nullptr;
		scope = p->module->debug_compile_unit;
		type = lb_debug_type_internal_proc(m, bt);

		Ast *ident = entity->identifier.load();
		if (entity->file != nullptr) {
			file = lb_get_llvm_metadata(m, entity->file);
			scope = file;
		} else if (ident != nullptr && ident->file_id != 0) {
			file = lb_get_llvm_metadata(m, ident->file());
			scope = file;
		} else if (entity->scope != nullptr) {
			file = lb_get_llvm_metadata(m, entity->scope->file);
			scope = file;
		}
		GB_ASSERT_MSG(file != nullptr, "%.*s", LIT(entity->token.string));

		// LLVMBool is_local_to_unit = !entity->Procedure.is_export;
		LLVMBool is_local_to_unit = false;
		LLVMBool is_definition = p->body != nullptr;
		unsigned scope_line = line;
		u32 flags = LLVMDIFlagStaticMember;
		LLVMBool is_optimized = false;
		if (bt->Proc.diverging) {
			flags |= LLVMDIFlagNoReturn;
		}
		if (p->body == nullptr) {
			flags |= LLVMDIFlagPrototyped;
			is_optimized = false;
		}

		if (p->body != nullptr) {
			// String debug_name = entity->token.string.text;
			String debug_name = p->name;

			p->debug_info = LLVMDIBuilderCreateFunction(m->debug_builder, scope,
				cast(char const *)debug_name.text, debug_name.len,
				cast(char const *)p->name.text, p->name.len,
				file, line, type,
				is_local_to_unit, is_definition,
				scope_line, cast(LLVMDIFlags)flags, is_optimized
			);
			GB_ASSERT(p->debug_info != nullptr);
			LLVMSetSubprogram(p->value, p->debug_info);
			lb_set_llvm_metadata(m, p, p->debug_info);
		}
	}

	return p;
}

lbProcedure *lb_create_dummy_procedure(lbModule *m, String link_name, Type *type) {
	{
		lbValue *found = string_map_get(&m->members, link_name);
		GB_ASSERT_MSG(found == nullptr, "failed to create dummy procedure for: %.*s", LIT(link_name));
	}

	lbProcedure *p = gb_alloc_item(permanent_allocator(), lbProcedure);

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

	gbAllocator a = permanent_allocator();
	p->children.allocator      = a;
	p->defer_stmts.allocator   = a;
	p->blocks.allocator        = a;
	p->branch_blocks.allocator = a;
	p->context_stack.allocator = a;


	char *c_link_name = alloc_cstring(permanent_allocator(), p->name);
	LLVMTypeRef func_type = lb_get_procedure_raw_type(m, p->type);

	p->value = LLVMAddFunction(m->mod, c_link_name, func_type);

	Type *pt = p->type;
	lbCallingConventionKind cc_kind = lbCallingConvention_C;
	// TODO(bill): Clean up this logic
	if (!is_arch_wasm()) {
		cc_kind = lb_calling_convention_map[pt->Proc.calling_convention];
	}
	LLVMSetFunctionCallConv(p->value, cc_kind);
	lbValue proc_value = {p->value, p->type};
	lb_add_member(m, p->name, proc_value);
	lb_add_procedure_value(m, p);


	// NOTE(bill): offset==0 is the return value
	isize offset = 1;
	if (pt->Proc.return_by_pointer) {
		lb_add_proc_attribute_at_index(p, 1, "sret");
		lb_add_proc_attribute_at_index(p, 1, "noalias");
		offset = 2;
	}

	isize parameter_index = 0;
	if (pt->Proc.calling_convention == ProcCC_Odin) {
		lb_add_proc_attribute_at_index(p, offset+parameter_index, "noalias");
		lb_add_proc_attribute_at_index(p, offset+parameter_index, "nonnull");
		lb_add_proc_attribute_at_index(p, offset+parameter_index, "nocapture");
	}

	return p;
}


lbValue lb_value_param(lbProcedure *p, Entity *e, Type *abi_type, i32 index, lbParamPasskind *kind_) {
	lbParamPasskind kind = lbParamPass_Value;

	if (e != nullptr && !are_types_identical(abi_type, e->type)) {
		if (is_type_pointer(abi_type)) {
			GB_ASSERT(e->kind == Entity_Variable);
			Type *av = core_type(type_deref(abi_type));
			if (are_types_identical(av, core_type(e->type))) {
				kind = lbParamPass_Pointer;
				if (e->flags&EntityFlag_Value) {
					kind = lbParamPass_ConstRef;
				}
			} else {
				kind = lbParamPass_BitCast;
			}
		} else if (is_type_integer(abi_type)) {
			kind = lbParamPass_Integer;
		} else if (abi_type == t_llvm_bool) {
			kind = lbParamPass_Value;
		} else if (is_type_boolean(abi_type)) {
			kind = lbParamPass_Integer;
		} else if (is_type_simd_vector(abi_type)) {
			kind = lbParamPass_BitCast;
		} else if (is_type_float(abi_type)) {
			kind = lbParamPass_BitCast;
		} else if (is_type_tuple(abi_type)) {
			kind = lbParamPass_Tuple;
		} else if (is_type_proc(abi_type)) {
			kind = lbParamPass_Value;
		} else {
			GB_PANIC("Invalid abi type pass kind %s", type_to_string(abi_type));
		}
	}

	if (kind_) *kind_ = kind;
	lbValue res = {};
	res.value = LLVMGetParam(p->value, cast(unsigned)index);
	res.type = abi_type;
	return res;
}



void lb_start_block(lbProcedure *p, lbBlock *b) {
	GB_ASSERT(b != nullptr);
	if (!b->appended) {
		b->appended = true;
		LLVMAppendExistingBasicBlock(p->value, b->block);
	}
	LLVMPositionBuilderAtEnd(p->builder, b->block);
	p->curr_block = b;
}

void lb_set_debug_position_to_procedure_begin(lbProcedure *p) {
	if (p->debug_info == nullptr) {
		return;
	}
	TokenPos pos = {};
	if (p->body != nullptr) {
		pos = ast_token(p->body).pos;
	} else if (p->type_expr != nullptr) {
		pos = ast_token(p->type_expr).pos;
	} else if (p->entity != nullptr) {
		pos = p->entity->token.pos;
	}
	if (pos.file_id != 0) {
		LLVMSetCurrentDebugLocation2(p->builder, lb_debug_location_from_token_pos(p, pos));
	}
}

void lb_set_debug_position_to_procedure_end(lbProcedure *p) {
	if (p->debug_info == nullptr) {
		return;
	}
	TokenPos pos = {};
	if (p->body != nullptr) {
		pos = ast_end_token(p->body).pos;
	} else if (p->type_expr != nullptr) {
		pos = ast_end_token(p->type_expr).pos;
	} else if (p->entity != nullptr) {
		pos = p->entity->token.pos;
	}
	if (pos.file_id != 0) {
		LLVMSetCurrentDebugLocation2(p->builder, lb_debug_location_from_token_pos(p, pos));
	}
}

void lb_begin_procedure_body(lbProcedure *p) {
	DeclInfo *decl = decl_info_of_entity(p->entity);
	if (decl != nullptr) {
		for_array(i, decl->labels) {
			BlockLabel bl = decl->labels[i];
			lbBranchBlocks bb = {bl.label, nullptr, nullptr};
			array_add(&p->branch_blocks, bb);
		}
	}

	p->builder = LLVMCreateBuilderInContext(p->module->ctx);

	p->decl_block  = lb_create_block(p, "decls", true);
	p->entry_block = lb_create_block(p, "entry", true);
	lb_start_block(p, p->entry_block);

	GB_ASSERT(p->type != nullptr);

	lb_ensure_abi_function_type(p->module, p);
	{
		lbFunctionType *ft = p->abi_function_type;

		unsigned param_offset = 0;

		lbValue return_ptr_value = {};
		if (ft->ret.kind == lbArg_Indirect) {
			// NOTE(bill): this must be parameter 0

			String name = str_lit("agg.result");

			Type *ptr_type = alloc_type_pointer(reduce_tuple_to_single_type(p->type->Proc.results));
			Entity *e = alloc_entity_param(nullptr, make_token_ident(name), ptr_type, false, false);
			e->flags |= EntityFlag_NoAlias;

			return_ptr_value.value = LLVMGetParam(p->value, 0);
			LLVMSetValueName2(return_ptr_value.value, cast(char const *)name.text, name.len);
			return_ptr_value.type = ptr_type;
			p->return_ptr = lb_addr(return_ptr_value);

			lb_add_entity(p->module, e, return_ptr_value);

			param_offset += 1;
		}

		if (p->type->Proc.params != nullptr) {
			TypeTuple *params = &p->type->Proc.params->Tuple;

			unsigned param_index = 0;
			for_array(i, params->variables) {
				Entity *e = params->variables[i];
				if (e->kind != Entity_Variable) {
					continue;
				}

				lbArgType *arg_type = &ft->args[param_index];
				defer (param_index += 1);

				if (arg_type->kind == lbArg_Ignore) {
					continue;
				} else if (arg_type->kind == lbArg_Direct) {
					if (e->token.string.len != 0 && !is_blank_ident(e->token.string)) {
						LLVMTypeRef param_type = lb_type(p->module, e->type);
						LLVMValueRef original_value = LLVMGetParam(p->value, param_offset+param_index);
						LLVMValueRef value = OdinLLVMBuildTransmute(p, original_value, param_type);

						lbValue param = {};
						param.value = value;
						param.type = e->type;

						lbValue ptr = lb_address_from_load_or_generate_local(p, param);
						GB_ASSERT(LLVMIsAAllocaInst(ptr.value));
						lb_add_entity(p->module, e, ptr);

						lbBlock *block = p->decl_block;
						if (original_value != value) {
							block = p->curr_block;
						}
						LLVMValueRef debug_storage_value = value;
						if (original_value != value && LLVMIsALoadInst(value)) {
							debug_storage_value = LLVMGetOperand(value, 0);
						}
						lb_add_debug_param_variable(p, debug_storage_value, e->type, e->token, param_index+1, block);
					}
				} else if (arg_type->kind == lbArg_Indirect) {
					if (e->token.string.len != 0 && !is_blank_ident(e->token.string)) {
						lbValue ptr = {};
						ptr.value = LLVMGetParam(p->value, param_offset+param_index);
						ptr.type = alloc_type_pointer(e->type);
						lb_add_entity(p->module, e, ptr);
						lb_add_debug_param_variable(p, ptr.value, e->type, e->token, param_index+1, p->decl_block);
					}
				}
			}
		}

		if (p->type->Proc.has_named_results) {
			GB_ASSERT(p->type->Proc.result_count > 0);
			TypeTuple *results = &p->type->Proc.results->Tuple;

			for_array(i, results->variables) {
				Entity *e = results->variables[i];
				GB_ASSERT(e->kind == Entity_Variable);

				if (e->token.string != "") {
					GB_ASSERT(!is_blank_ident(e->token));

					lbAddr res = {};
					if (return_ptr_value.value) {
						lbValue ptr = return_ptr_value;
						if (results->variables.count != 1) {
							ptr = lb_emit_struct_ep(p, ptr, cast(i32)i);
						}

						res = lb_addr(ptr);
						lb_add_entity(p->module, e, ptr);
					} else {
						res = lb_add_local(p, e->type, e);
					}

					if (e->Variable.param_value.kind != ParameterValue_Invalid) {
						lbValue c = lb_handle_param_value(p, e->type, e->Variable.param_value, e->token.pos);
						lb_addr_store(p, res, c);
					}
				}
			}
		}
	}
	if (p->type->Proc.calling_convention == ProcCC_Odin) {
		lb_push_context_onto_stack_from_implicit_parameter(p);
	}

	lb_set_debug_position_to_procedure_begin(p);
	if (p->debug_info != nullptr) {
		if (p->context_stack.count != 0) {
			p->curr_block = p->decl_block;
			lb_add_debug_context_variable(p, lb_find_or_generate_context_ptr(p));
		}

	}

	lb_start_block(p, p->entry_block);
}

void lb_end_procedure_body(lbProcedure *p) {
	lb_set_debug_position_to_procedure_begin(p);

	LLVMPositionBuilderAtEnd(p->builder, p->decl_block->block);
	LLVMBuildBr(p->builder, p->entry_block->block);
	LLVMPositionBuilderAtEnd(p->builder, p->curr_block->block);

	LLVMValueRef instr = nullptr;

	// Make sure there is a "ret void" at the end of a procedure with no return type
	if (p->type->Proc.result_count == 0) {
		instr = LLVMGetLastInstruction(p->curr_block->block);
		if (!lb_is_instr_terminating(instr)) {
			lb_emit_defer_stmts(p, lbDeferExit_Return, nullptr);
			lb_set_debug_position_to_procedure_end(p);
			LLVMBuildRetVoid(p->builder);
		}
	}

	LLVMBasicBlockRef first_block = LLVMGetFirstBasicBlock(p->value);
	LLVMBasicBlockRef block = nullptr;

	// Make sure every block terminates, and if not, make it unreachable
	for (block = first_block; block != nullptr; block = LLVMGetNextBasicBlock(block)) {
		instr = LLVMGetLastInstruction(block);
		if (instr == nullptr || !lb_is_instr_terminating(instr)) {
			LLVMPositionBuilderAtEnd(p->builder, block);
			LLVMBuildUnreachable(p->builder);
		}
	}

	p->curr_block = nullptr;
	p->state_flags = 0;
}
void lb_end_procedure(lbProcedure *p) {
	LLVMDisposeBuilder(p->builder);
}

void lb_build_nested_proc(lbProcedure *p, AstProcLit *pd, Entity *e) {
	GB_ASSERT(pd->body != nullptr);
	lbModule *m = p->module;
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
	name_len = gb_snprintf(name_text, name_len, "%.*s.%.*s-%d", LIT(p->name), LIT(pd_name), guid);
	String name = make_string(cast(u8 *)name_text, name_len-1);

	e->Procedure.link_name = name;

	lbProcedure *nested_proc = lb_create_procedure(p->module, e);
	e->code_gen_procedure = nested_proc;

	lbValue value = {};
	value.value = nested_proc->value;
	value.type = nested_proc->type;

	lb_add_entity(m, e, value);
	array_add(&p->children, nested_proc);
	array_add(&m->procedures_to_generate, nested_proc);
}



Array<lbValue> lb_value_to_array(lbProcedure *p, lbValue value) {
	Array<lbValue> array = {};
	Type *t = base_type(value.type);
	if (t == nullptr) {
		// Do nothing
	} else if (is_type_tuple(t)) {
		GB_ASSERT(t->kind == Type_Tuple);
		auto *rt = &t->Tuple;
		if (rt->variables.count > 0) {
			array = array_make<lbValue>(permanent_allocator(), rt->variables.count);
			for_array(i, rt->variables) {
				lbValue elem = lb_emit_struct_ev(p, value, cast(i32)i);
				array[i] = elem;
			}
		}
	} else {
		array = array_make<lbValue>(permanent_allocator(), 1);
		array[0] = value;
	}
	return array;
}



lbValue lb_emit_call_internal(lbProcedure *p, lbValue value, lbValue return_ptr, Array<lbValue> const &processed_args, Type *abi_rt, lbAddr context_ptr, ProcInlining inlining) {
	GB_ASSERT(p->module->ctx == LLVMGetTypeContext(LLVMTypeOf(value.value)));

	unsigned arg_count = cast(unsigned)processed_args.count;
	if (return_ptr.value != nullptr) {
		arg_count += 1;
	}
	if (context_ptr.addr.value != nullptr) {
		arg_count += 1;
	}

	LLVMValueRef *args = gb_alloc_array(permanent_allocator(), LLVMValueRef, arg_count);
	isize arg_index = 0;
	if (return_ptr.value != nullptr) {
		args[arg_index++] = return_ptr.value;
	}
	for_array(i, processed_args) {
		lbValue arg = processed_args[i];
		if (is_type_proc(arg.type)) {
			arg.value = LLVMBuildPointerCast(p->builder, arg.value, lb_type(p->module, arg.type), "");
		}
		args[arg_index++] = arg.value;
	}
	if (context_ptr.addr.value != nullptr) {
		LLVMValueRef cp = context_ptr.addr.value;
		cp = LLVMBuildPointerCast(p->builder, cp, lb_type(p->module, t_rawptr), "");
		args[arg_index++] = cp;
	}
	LLVMBasicBlockRef curr_block = LLVMGetInsertBlock(p->builder);
	GB_ASSERT(curr_block != p->decl_block->block);

	{
		LLVMTypeRef fnp = lb_type_internal_for_procedures_raw(p->module, value.type);
		LLVMTypeRef ftp = LLVMPointerType(fnp, 0);
		LLVMValueRef fn = value.value;
		if (!lb_is_type_kind(LLVMTypeOf(value.value), LLVMFunctionTypeKind)) {
			fn = LLVMBuildPointerCast(p->builder, fn, ftp, "");
		}
		GB_ASSERT_MSG(lb_is_type_kind(fnp, LLVMFunctionTypeKind), "%s", LLVMPrintTypeToString(fnp));

		{
			unsigned param_count = LLVMCountParamTypes(fnp);
			GB_ASSERT(arg_count >= param_count);

			LLVMTypeRef *param_types = gb_alloc_array(temporary_allocator(), LLVMTypeRef, param_count);
			LLVMGetParamTypes(fnp, param_types);
			for (unsigned i = 0; i < param_count; i++) {
				LLVMTypeRef param_type = param_types[i];
				LLVMTypeRef arg_type = LLVMTypeOf(args[i]);
				// LLVMTypeKind param_kind = LLVMGetTypeKind(param_type);
				// LLVMTypeKind arg_kind = LLVMGetTypeKind(arg_type);
				GB_ASSERT_MSG(
					arg_type == param_type,
					"Parameter types do not match: %s != %s, argument: %s",
					LLVMPrintTypeToString(arg_type),
					LLVMPrintTypeToString(param_type),
					LLVMPrintValueToString(args[i])
				);
			}
		}

		LLVMValueRef ret = LLVMBuildCall2(p->builder, fnp, fn, args, arg_count, "");

		if (return_ptr.value != nullptr) {
			LLVMAddCallSiteAttribute(ret, 1, lb_create_enum_attribute_with_type(p->module->ctx, "sret", LLVMTypeOf(args[0])));
		}

		switch (inlining) {
		case ProcInlining_none:
			break;
		case ProcInlining_inline:
			LLVMAddCallSiteAttribute(ret, LLVMAttributeIndex_FunctionIndex, lb_create_enum_attribute(p->module->ctx, "alwaysinline"));
			break;
		case ProcInlining_no_inline:
			LLVMAddCallSiteAttribute(ret, LLVMAttributeIndex_FunctionIndex, lb_create_enum_attribute(p->module->ctx, "noinline"));
			break;
		}

		lbValue res = {};
		res.value = ret;
		res.type = abi_rt;
		return res;
	}
}


lbValue lb_lookup_runtime_procedure(lbModule *m, String const &name) {
	AstPackage *pkg = m->info->runtime_package;
	Entity *e = scope_lookup_current(pkg->scope, name);
	return lb_find_procedure_value_from_entity(m, e);
}


lbValue lb_emit_runtime_call(lbProcedure *p, char const *c_name, Array<lbValue> const &args) {
	String name = make_string_c(c_name);
	lbValue proc = lb_lookup_runtime_procedure(p->module, name);
	return lb_emit_call(p, proc, args);
}

lbValue lb_emit_conjugate(lbProcedure *p, lbValue val, Type *type) {
	lbValue res = {};
	Type *t = val.type;
	if (is_type_complex(t)) {
		res = lb_addr_get_ptr(p, lb_add_local_generated(p, type, false));
		lbValue real = lb_emit_struct_ev(p, val, 0);
		lbValue imag = lb_emit_struct_ev(p, val, 1);
		imag = lb_emit_unary_arith(p, Token_Sub, imag, imag.type);
		lb_emit_store(p, lb_emit_struct_ep(p, res, 0), real);
		lb_emit_store(p, lb_emit_struct_ep(p, res, 1), imag);
	} else if (is_type_quaternion(t)) {
		// @QuaternionLayout
		res = lb_addr_get_ptr(p, lb_add_local_generated(p, type, false));
		lbValue real = lb_emit_struct_ev(p, val, 3);
		lbValue imag = lb_emit_struct_ev(p, val, 0);
		lbValue jmag = lb_emit_struct_ev(p, val, 1);
		lbValue kmag = lb_emit_struct_ev(p, val, 2);
		imag = lb_emit_unary_arith(p, Token_Sub, imag, imag.type);
		jmag = lb_emit_unary_arith(p, Token_Sub, jmag, jmag.type);
		kmag = lb_emit_unary_arith(p, Token_Sub, kmag, kmag.type);
		lb_emit_store(p, lb_emit_struct_ep(p, res, 3), real);
		lb_emit_store(p, lb_emit_struct_ep(p, res, 0), imag);
		lb_emit_store(p, lb_emit_struct_ep(p, res, 1), jmag);
		lb_emit_store(p, lb_emit_struct_ep(p, res, 2), kmag);
	} else if (is_type_array_like(t)) {
		res = lb_addr_get_ptr(p, lb_add_local_generated(p, type, true));
		Type *elem_type = base_array_type(t);
		i64 count = get_array_type_count(t);
		for (i64 i = 0; i < count; i++) {
			lbValue dst = lb_emit_array_epi(p, res, i);
			lbValue elem = lb_emit_struct_ev(p, val, cast(i32)i);
			elem = lb_emit_conjugate(p, elem, elem_type);
			lb_emit_store(p, dst, elem);
		}
	} else if (is_type_matrix(t)) {
		Type *mt = base_type(t);
		GB_ASSERT(mt->kind == Type_Matrix);
		Type *elem_type = mt->Matrix.elem;
		res = lb_addr_get_ptr(p, lb_add_local_generated(p, type, true));
		for (i64 j = 0; j < mt->Matrix.column_count; j++) {
			for (i64 i = 0; i < mt->Matrix.row_count; i++) {
				lbValue dst = lb_emit_matrix_epi(p, res, i, j);
				lbValue elem = lb_emit_matrix_ev(p, val, i, j);
				elem = lb_emit_conjugate(p, elem, elem_type);
				lb_emit_store(p, dst, elem);
			}
		}
	}
	return lb_emit_load(p, res);
}

lbValue lb_emit_call(lbProcedure *p, lbValue value, Array<lbValue> const &args, ProcInlining inlining, bool use_copy_elision_hint) {
	lbModule *m = p->module;

	Type *pt = base_type(value.type);
	GB_ASSERT(pt->kind == Type_Proc);
	Type *results = pt->Proc.results;

	lbAddr context_ptr = {};
	if (pt->Proc.calling_convention == ProcCC_Odin) {
		context_ptr = lb_find_or_generate_context_ptr(p);
	}

	defer (if (pt->Proc.diverging) {
		LLVMBuildUnreachable(p->builder);
	});

	bool is_c_vararg = pt->Proc.c_vararg;
	isize param_count = pt->Proc.param_count;
	if (is_c_vararg) {
		GB_ASSERT(param_count-1 <= args.count);
		param_count -= 1;
	} else {
		GB_ASSERT_MSG(param_count == args.count, "%td == %td", param_count, args.count);
	}

	lbValue result = {};

	auto processed_args = array_make<lbValue>(permanent_allocator(), 0, args.count);

	{
		lbFunctionType *ft = lb_get_function_type(m, p, pt);
		bool return_by_pointer = ft->ret.kind == lbArg_Indirect;

		unsigned param_index = 0;
		for (isize i = 0; i < param_count; i++) {
			Entity *e = pt->Proc.params->Tuple.variables[i];
			if (e->kind != Entity_Variable) {
				continue;
			}
			GB_ASSERT(e->flags & EntityFlag_Param);

			Type *original_type = e->type;
			lbArgType *arg = &ft->args[param_index];
			if (arg->kind == lbArg_Ignore) {
				continue;
			}

			lbValue x = lb_emit_conv(p, args[i], original_type);
			LLVMTypeRef xt = lb_type(p->module, x.type);

			if (arg->kind == lbArg_Direct) {
				LLVMTypeRef abi_type = arg->cast_type;
				if (!abi_type) {
					abi_type = arg->type;
				}
				if (xt == abi_type) {
					array_add(&processed_args, x);
				} else {
					x.value = OdinLLVMBuildTransmute(p, x.value, abi_type);
					array_add(&processed_args, x);
				}

			} else if (arg->kind == lbArg_Indirect) {
				lbValue ptr = {};
				if (arg->is_byval) {
					ptr = lb_copy_value_to_ptr(p, x, original_type, arg->byval_alignment);
				} else if (is_calling_convention_odin(pt->Proc.calling_convention)) {
					// NOTE(bill): Odin parameters are immutable so the original value can be passed if possible
					// i.e. `T const &` in C++
					ptr = lb_address_from_load_or_generate_local(p, x);
				} else {
					ptr = lb_copy_value_to_ptr(p, x, original_type, 16);
				}
				array_add(&processed_args, ptr);
			}

			param_index += 1;
		}

		if (is_c_vararg) {
			for (isize i = processed_args.count; i < args.count; i++) {
				array_add(&processed_args, args[i]);
			}
		}

		if (inlining == ProcInlining_none) {
			inlining = p->inlining;
		}

		Type *rt = reduce_tuple_to_single_type(results);
		if (return_by_pointer) {
			lbValue return_ptr = {};
			if (use_copy_elision_hint && p->copy_elision_hint.ptr.value != nullptr) {
				if (are_types_identical(type_deref(p->copy_elision_hint.ptr.type), rt)) {
					return_ptr = lb_consume_copy_elision_hint(p);
				}
			}
			if (return_ptr.value == nullptr) {
				lbAddr r = lb_add_local_generated(p, rt, true);
				return_ptr = r.addr;
			}
			GB_ASSERT(is_type_pointer(return_ptr.type));
			lb_emit_call_internal(p, value, return_ptr, processed_args, nullptr, context_ptr, inlining);
			result = lb_emit_load(p, return_ptr);
		} else if (rt != nullptr) {
			result = lb_emit_call_internal(p, value, {}, processed_args, rt, context_ptr, inlining);
			if (ft->ret.cast_type) {
				result.value = OdinLLVMBuildTransmute(p, result.value, ft->ret.cast_type);
			}
			result.value = OdinLLVMBuildTransmute(p, result.value, ft->ret.type);
			result.type = rt;
			if (LLVMTypeOf(result.value) == LLVMInt1TypeInContext(p->module->ctx)) {
				result.type = t_llvm_bool;
			}
			if (!is_type_tuple(rt)) {
				result = lb_emit_conv(p, result, rt);
			}
		} else {
			lb_emit_call_internal(p, value, {}, processed_args, nullptr, context_ptr, inlining);
		}

	}

	Entity **found = map_get(&p->module->procedure_values, value.value);
	if (found != nullptr) {
		Entity *e = *found;
		if (e != nullptr && entity_has_deferred_procedure(e)) {
			DeferredProcedureKind kind = e->Procedure.deferred_procedure.kind;
			Entity *deferred_entity = e->Procedure.deferred_procedure.entity;
			lbValue deferred = lb_find_procedure_value_from_entity(p->module, deferred_entity);


			auto in_args = args;
			Array<lbValue> result_as_args = {};
			switch (kind) {
			case DeferredProcedure_none:
				break;
			case DeferredProcedure_in:
				result_as_args = in_args;
				break;
			case DeferredProcedure_out:
				result_as_args = lb_value_to_array(p, result);
				break;
			case DeferredProcedure_in_out:
				{
					auto out_args = lb_value_to_array(p, result);
					array_init(&result_as_args, permanent_allocator(), in_args.count + out_args.count);
					array_copy(&result_as_args, in_args, 0);
					array_copy(&result_as_args, out_args, in_args.count);
				}
				break;
			}

			lb_add_defer_proc(p, p->scope_index, deferred, result_as_args);
		}
	}

	return result;
}

LLVMValueRef llvm_splat_float(i64 count, LLVMTypeRef type, f64 value) {
	LLVMValueRef v = LLVMConstReal(type, value);
	LLVMValueRef *values = gb_alloc_array(temporary_allocator(), LLVMValueRef, count);
	for (i64 i = 0; i < count; i++) {
		values[i] = v;
	}
	return LLVMConstVector(values, cast(unsigned)count);
}
LLVMValueRef llvm_splat_int(i64 count, LLVMTypeRef type, i64 value, bool is_signed=false) {
	LLVMValueRef v = LLVMConstInt(type, value, is_signed);
	LLVMValueRef *values = gb_alloc_array(temporary_allocator(), LLVMValueRef, count);
	for (i64 i = 0; i < count; i++) {
		values[i] = v;
	}
	return LLVMConstVector(values, cast(unsigned)count);
}


lbValue lb_build_builtin_simd_proc(lbProcedure *p, Ast *expr, TypeAndValue const &tv, BuiltinProcId builtin_id) {
	ast_node(ce, CallExpr, expr);

	lbModule *m = p->module;

	lbValue res = {};
	res.type = tv.type;

	lbValue arg0 = {}; if (ce->args.count > 0) arg0 = lb_build_expr(p, ce->args[0]);
	lbValue arg1 = {}; if (ce->args.count > 1) arg1 = lb_build_expr(p, ce->args[1]);
	lbValue arg2 = {}; if (ce->args.count > 2) arg2 = lb_build_expr(p, ce->args[2]);

	Type *elem = base_array_type(arg0.type);

	bool is_float = is_type_float(elem);
	bool is_signed = !is_type_unsigned(elem);

	LLVMOpcode op_code = cast(LLVMOpcode)0;

	switch (builtin_id) {
	case BuiltinProc_simd_add:
	case BuiltinProc_simd_sub:
	case BuiltinProc_simd_mul:
	case BuiltinProc_simd_div:
	case BuiltinProc_simd_rem:
		if (is_float) {
			switch (builtin_id) {
			case BuiltinProc_simd_add: op_code = LLVMFAdd; break;
			case BuiltinProc_simd_sub: op_code = LLVMFSub; break;
			case BuiltinProc_simd_mul: op_code = LLVMFMul; break;
			case BuiltinProc_simd_div: op_code = LLVMFDiv; break;
			}
		} else {
			switch (builtin_id) {
			case BuiltinProc_simd_add: op_code = LLVMAdd; break;
			case BuiltinProc_simd_sub: op_code = LLVMSub; break;
			case BuiltinProc_simd_mul: op_code = LLVMMul; break;
			case BuiltinProc_simd_div:
				if (is_signed) {
					op_code = LLVMSDiv;
				} else {
					op_code = LLVMUDiv;
				}
				break;
			case BuiltinProc_simd_rem:
				if (is_signed) {
					op_code = LLVMSRem;
				} else {
					op_code = LLVMURem;
				}
				break;
			}
		}
		if (op_code) {
			res.value = LLVMBuildBinOp(p->builder, op_code, arg0.value, arg1.value, "");
			return res;
		}
		break;
	case BuiltinProc_simd_shl: // Odin logic
	case BuiltinProc_simd_shr: // Odin logic
	case BuiltinProc_simd_shl_masked: // C logic
	case BuiltinProc_simd_shr_masked: // C logic
		{
			i64 sz = type_size_of(elem);
			GB_ASSERT(arg0.type->kind == Type_SimdVector);

			i64 count = arg0.type->SimdVector.count;
			Type *elem1 = base_array_type(arg1.type);

			bool is_masked = false;
			switch (builtin_id) {
			case BuiltinProc_simd_shl:        op_code = LLVMShl;                         is_masked = false; break;
			case BuiltinProc_simd_shr:        op_code = is_signed ? LLVMAShr : LLVMLShr; is_masked = false; break;
			case BuiltinProc_simd_shl_masked: op_code = LLVMShl;                         is_masked = true;  break;
			case BuiltinProc_simd_shr_masked: op_code = is_signed ? LLVMAShr : LLVMLShr; is_masked = true;  break;
			}
			if (op_code) {
				LLVMValueRef bits = llvm_splat_int(count, lb_type(m, elem1), sz*8 - 1);
				if (is_masked) {
					// C logic
					LLVMValueRef shift = LLVMBuildAnd(p->builder, arg1.value, bits, "");
					res.value = LLVMBuildBinOp(p->builder, op_code, arg0.value, shift, "");
				} else {
					// Odin logic
					LLVMValueRef zero = lb_const_nil(m, arg1.type).value;
					LLVMValueRef mask = LLVMBuildICmp(p->builder, LLVMIntULE, arg1.value, bits, "");
					LLVMValueRef shift = LLVMBuildBinOp(p->builder, op_code, arg0.value, arg1.value, "");
					res.value = LLVMBuildSelect(p->builder, mask, shift, zero, "");
				}
				return res;
			}
		}
		break;
	case BuiltinProc_simd_and:
	case BuiltinProc_simd_or:
	case BuiltinProc_simd_xor:
	case BuiltinProc_simd_and_not:
		switch (builtin_id) {
		case BuiltinProc_simd_and: op_code = LLVMAnd; break;
		case BuiltinProc_simd_or:  op_code = LLVMOr;  break;
		case BuiltinProc_simd_xor: op_code = LLVMXor; break;
		case BuiltinProc_simd_and_not:
			op_code = LLVMAnd;
			arg1.value = LLVMBuildNot(p->builder, arg1.value, "");
			break;
		}
		if (op_code) {
			res.value = LLVMBuildBinOp(p->builder, op_code, arg0.value, arg1.value, "");
			return res;
		}
		break;
	case BuiltinProc_simd_neg:
		if (is_float) {
			res.value = LLVMBuildFNeg(p->builder, arg0.value, "");
		} else {
			res.value = LLVMBuildNeg(p->builder, arg0.value, "");
		}
		return res;
	case BuiltinProc_simd_abs:
		if (is_float) {
			LLVMValueRef pos = arg0.value;
			LLVMValueRef neg = LLVMBuildFNeg(p->builder, pos, "");
			LLVMValueRef cond = LLVMBuildFCmp(p->builder, LLVMRealOGT, pos, neg, "");
			res.value = LLVMBuildSelect(p->builder, cond, pos, neg, "");
		} else {
			LLVMValueRef pos = arg0.value;
			LLVMValueRef neg = LLVMBuildNeg(p->builder, pos, "");
			LLVMValueRef cond = LLVMBuildICmp(p->builder, is_signed ? LLVMIntSGT : LLVMIntUGT, pos, neg, "");
			res.value = LLVMBuildSelect(p->builder, cond, pos, neg, "");
		}
		return res;
	case BuiltinProc_simd_min:
		if (is_float) {
			LLVMValueRef cond = LLVMBuildFCmp(p->builder, LLVMRealOLT, arg0.value, arg1.value, "");
			res.value = LLVMBuildSelect(p->builder, cond, arg0.value, arg1.value, "");
		} else {
			LLVMValueRef cond = LLVMBuildICmp(p->builder, is_signed ? LLVMIntSLT : LLVMIntULT, arg0.value, arg1.value, "");
			res.value = LLVMBuildSelect(p->builder, cond, arg0.value, arg1.value, "");
		}
		return res;
	case BuiltinProc_simd_max:
		if (is_float) {
			LLVMValueRef cond = LLVMBuildFCmp(p->builder, LLVMRealOGT, arg0.value, arg1.value, "");
			res.value = LLVMBuildSelect(p->builder, cond, arg0.value, arg1.value, "");
		} else {
			LLVMValueRef cond = LLVMBuildICmp(p->builder, is_signed ? LLVMIntSGT : LLVMIntUGT, arg0.value, arg1.value, "");
			res.value = LLVMBuildSelect(p->builder, cond, arg0.value, arg1.value, "");
		}
		return res;
	case BuiltinProc_simd_lanes_eq:
	case BuiltinProc_simd_lanes_ne:
	case BuiltinProc_simd_lanes_lt:
	case BuiltinProc_simd_lanes_le:
	case BuiltinProc_simd_lanes_gt:
	case BuiltinProc_simd_lanes_ge:
		if (is_float) {
			LLVMRealPredicate pred = cast(LLVMRealPredicate)0;
			switch (builtin_id) {
			case BuiltinProc_simd_lanes_eq: pred = LLVMRealOEQ; break;
			case BuiltinProc_simd_lanes_ne: pred = LLVMRealONE; break;
			case BuiltinProc_simd_lanes_lt: pred = LLVMRealOLT; break;
			case BuiltinProc_simd_lanes_le: pred = LLVMRealOLE; break;
			case BuiltinProc_simd_lanes_gt: pred = LLVMRealOGT; break;
			case BuiltinProc_simd_lanes_ge: pred = LLVMRealOGE; break;
			}
			if (pred) {
				res.value = LLVMBuildFCmp(p->builder, pred, arg0.value, arg1.value, "");
				res.value = LLVMBuildSExtOrBitCast(p->builder, res.value, lb_type(m, tv.type), "");
				return res;
			}
		} else {
			LLVMIntPredicate pred = cast(LLVMIntPredicate)0;
			switch (builtin_id) {
			case BuiltinProc_simd_lanes_eq: pred = LLVMIntEQ; break;
			case BuiltinProc_simd_lanes_ne: pred = LLVMIntNE; break;
			case BuiltinProc_simd_lanes_lt: pred = is_signed ? LLVMIntSLT :LLVMIntULT; break;
			case BuiltinProc_simd_lanes_le: pred = is_signed ? LLVMIntSLE :LLVMIntULE; break;
			case BuiltinProc_simd_lanes_gt: pred = is_signed ? LLVMIntSGT :LLVMIntUGT; break;
			case BuiltinProc_simd_lanes_ge: pred = is_signed ? LLVMIntSGE :LLVMIntUGE; break;
			}
			if (pred) {
				res.value = LLVMBuildICmp(p->builder, pred, arg0.value, arg1.value, "");
				res.value = LLVMBuildSExtOrBitCast(p->builder, res.value, lb_type(m, tv.type), "");
				return res;
			}
		}
		break;

	case BuiltinProc_simd_extract:
		res.value = LLVMBuildExtractElement(p->builder, arg0.value, arg1.value, "");
		return res;
	case BuiltinProc_simd_replace:
		res.value = LLVMBuildInsertElement(p->builder, arg0.value, arg2.value, arg1.value, "");
		return res;

	case BuiltinProc_simd_reduce_add_ordered:
	case BuiltinProc_simd_reduce_mul_ordered:
		{
			LLVMTypeRef llvm_elem = lb_type(m, elem);
			LLVMValueRef args[2] = {};
			isize args_count = 0;

			char const *name = nullptr;
			switch (builtin_id) {
			case BuiltinProc_simd_reduce_add_ordered:
				if (is_float) {
					name = "llvm.vector.reduce.fadd";
					args[args_count++] = LLVMConstReal(llvm_elem, 0.0);
				} else {
					name = "llvm.vector.reduce.add";
				}
				break;
			case BuiltinProc_simd_reduce_mul_ordered:
				if (is_float) {
					name = "llvm.vector.reduce.fmul";
					args[args_count++] = LLVMConstReal(llvm_elem, 1.0);
				} else {
					name = "llvm.vector.reduce.mul";
				}
				break;
			}
			args[args_count++] = arg0.value;

			LLVMTypeRef types[1] = {lb_type(p->module, arg0.type)};
			res.value = lb_call_intrinsic(p, name, args, cast(unsigned)args_count, types, gb_count_of(types));
			return res;
		}
	case BuiltinProc_simd_reduce_min:
	case BuiltinProc_simd_reduce_max:
	case BuiltinProc_simd_reduce_and:
	case BuiltinProc_simd_reduce_or:
	case BuiltinProc_simd_reduce_xor:
		{
			char const *name = nullptr;
			switch (builtin_id) {
			case BuiltinProc_simd_reduce_min:
				if (is_float) {
					name = "llvm.vector.reduce.fmin";
				} else if (is_signed) {
					name = "llvm.vector.reduce.smin";
				} else {
					name = "llvm.vector.reduce.umin";
				}
				break;
			case BuiltinProc_simd_reduce_max:
				if (is_float) {
					name = "llvm.vector.reduce.fmax";
				} else if (is_signed) {
					name = "llvm.vector.reduce.smax";
				} else {
					name = "llvm.vector.reduce.umax";
				}
				break;
			case BuiltinProc_simd_reduce_and: name = "llvm.vector.reduce.and"; break;
			case BuiltinProc_simd_reduce_or:  name = "llvm.vector.reduce.or";  break;
			case BuiltinProc_simd_reduce_xor: name = "llvm.vector.reduce.xor"; break;
			}

			LLVMTypeRef types[1] = { lb_type(p->module, arg0.type) };
			LLVMValueRef args[1] = { arg0.value };

			res.value = lb_call_intrinsic(p, name, args, gb_count_of(args), types, gb_count_of(types));
			return res;
		}

	case BuiltinProc_simd_shuffle:
		{
			Type *vt = arg0.type;
			GB_ASSERT(vt->kind == Type_SimdVector);

			i64 indices_count = ce->args.count-2;
			i64 max_count = vt->SimdVector.count*2;
			GB_ASSERT(indices_count <= max_count);

			LLVMValueRef *values = gb_alloc_array(temporary_allocator(), LLVMValueRef, indices_count);
			for (isize i = 0; i < indices_count; i++) {
				lbValue idx = lb_build_expr(p, ce->args[i+2]);
				GB_ASSERT(LLVMIsConstant(idx.value));
				values[i] = idx.value;
			}
			LLVMValueRef indices = LLVMConstVector(values, cast(unsigned)indices_count);

			res.value = LLVMBuildShuffleVector(p->builder, arg0.value, arg1.value, indices, "");
			return res;
		}

	case BuiltinProc_simd_select:
		{
			LLVMValueRef cond = arg0.value;
			LLVMValueRef x = lb_build_expr(p, ce->args[1]).value;
			LLVMValueRef y = lb_build_expr(p, ce->args[2]).value;

			cond = LLVMBuildICmp(p->builder, LLVMIntNE, cond, LLVMConstNull(LLVMTypeOf(cond)), "");
			res.value = LLVMBuildSelect(p->builder, cond, x, y, "");
			return res;
		}

	case BuiltinProc_simd_ceil:
	case BuiltinProc_simd_floor:
	case BuiltinProc_simd_trunc:
	case BuiltinProc_simd_nearest:
		{
			char const *name = nullptr;
			switch (builtin_id) {
			case BuiltinProc_simd_ceil:    name = "llvm.ceil"; break;
			case BuiltinProc_simd_floor:   name = "llvm.floor"; break;
			case BuiltinProc_simd_trunc:   name = "llvm.trunc"; break;
			case BuiltinProc_simd_nearest: name = "llvm.nearbyint"; break;
			}

			LLVMTypeRef types[1] = { lb_type(p->module, arg0.type) };
			LLVMValueRef args[1] = { arg0.value };

			res.value = lb_call_intrinsic(p, name, args, gb_count_of(args), types, gb_count_of(types));
			return res;
		}

	case BuiltinProc_simd_lanes_reverse:
		{
			i64 count = get_array_type_count(arg0.type);
			LLVMValueRef *values = gb_alloc_array(temporary_allocator(), LLVMValueRef, count);
			LLVMTypeRef llvm_u32 = lb_type(m, t_u32);
			for (i64 i = 0; i < count; i++) {
				values[i] = LLVMConstInt(llvm_u32, count-1-i, false);
			}
			LLVMValueRef mask = LLVMConstVector(values, cast(unsigned)count);

			LLVMValueRef v = arg0.value;
			res.value = LLVMBuildShuffleVector(p->builder, v, v, mask, "");
			return res;
		}

	case BuiltinProc_simd_lanes_rotate_left:
	case BuiltinProc_simd_lanes_rotate_right:
		{

			i64 count = get_array_type_count(arg0.type);
			GB_ASSERT(is_power_of_two(count));
			BigInt bi_count = {};
			big_int_from_i64(&bi_count, count);

			TypeAndValue const &tv = ce->args[1]->tav;
			ExactValue val = exact_value_to_integer(tv.value);
			GB_ASSERT(val.kind == ExactValue_Integer);
			BigInt *bi = &val.value_integer;
			if (builtin_id == BuiltinProc_simd_lanes_rotate_right) {
				big_int_neg(bi, bi);
			}
			big_int_rem(bi, bi, &bi_count);
			big_int_dealloc(&bi_count);

			i64 left = big_int_to_i64(bi);

			LLVMValueRef *values = gb_alloc_array(temporary_allocator(), LLVMValueRef, count);
			LLVMTypeRef llvm_u32 = lb_type(m, t_u32);
			for (i64 i = 0; i < count; i++) {
				u64 idx = cast(u64)(i+left) & cast(u64)(count-1);
				values[i] = LLVMConstInt(llvm_u32, idx, false);
			}
			LLVMValueRef mask = LLVMConstVector(values, cast(unsigned)count);

			LLVMValueRef v = arg0.value;
			res.value = LLVMBuildShuffleVector(p->builder, v, v, mask, "");
			return res;
		}


	case BuiltinProc_simd_add_sat:
	case BuiltinProc_simd_sub_sat:
		{
			char const *name = nullptr;
			switch (builtin_id) {
			case BuiltinProc_simd_add_sat: name = is_signed ? "llvm.sadd.sat" : "llvm.uadd.sat"; break;
			case BuiltinProc_simd_sub_sat: name = is_signed ? "llvm.ssub.sat" : "llvm.usub.sat"; break;
			}

			LLVMTypeRef types[1] = {lb_type(p->module, arg0.type)};

			LLVMValueRef args[2] = { arg0.value, arg1.value };

			res.value = lb_call_intrinsic(p, name, args, gb_count_of(args), types, gb_count_of(types));
			return res;
		}

	case BuiltinProc_simd_clamp:
		{
			LLVMValueRef v = arg0.value;
			LLVMValueRef min = arg1.value;
			LLVMValueRef max = arg2.value;

			if (is_float) {
				v = LLVMBuildSelect(p->builder, LLVMBuildFCmp(p->builder, LLVMRealOLT, v, min, ""), min, v, "");
				res.value = LLVMBuildSelect(p->builder, LLVMBuildFCmp(p->builder, LLVMRealOGT, v, max, ""), max, v, "");
			} else if (is_signed) {
				v = LLVMBuildSelect(p->builder, LLVMBuildICmp(p->builder, LLVMIntSLT, v, min, ""), min, v, "");
				res.value = LLVMBuildSelect(p->builder, LLVMBuildICmp(p->builder, LLVMIntSGT, v, max, ""), max, v, "");
			} else {
				v = LLVMBuildSelect(p->builder, LLVMBuildICmp(p->builder, LLVMIntULT, v, min, ""), min, v, "");
				res.value = LLVMBuildSelect(p->builder, LLVMBuildICmp(p->builder, LLVMIntUGT, v, max, ""), max, v, "");
			}
			return res;
		}

	case BuiltinProc_simd_to_bits:
		{
			res.value = LLVMBuildBitCast(p->builder, arg0.value, lb_type(m, tv.type), "");
			return res;
		}

	}
	GB_PANIC("Unhandled simd intrinsic: '%.*s'", LIT(builtin_procs[builtin_id].name));

	return {};
}


lbValue lb_build_builtin_proc(lbProcedure *p, Ast *expr, TypeAndValue const &tv, BuiltinProcId id) {
	ast_node(ce, CallExpr, expr);

	if (BuiltinProc__simd_begin < id && id < BuiltinProc__simd_end) {
		return lb_build_builtin_simd_proc(p, expr, tv, id);
	}

	switch (id) {
	case BuiltinProc_DIRECTIVE: {
		ast_node(bd, BasicDirective, ce->proc);
		String name = bd->name.string;
		GB_ASSERT(name == "location");
		String procedure = p->entity->token.string;
		TokenPos pos = ast_token(ce->proc).pos;
		if (ce->args.count > 0) {
			Ast *ident = unselector_expr(ce->args[0]);
			GB_ASSERT(ident->kind == Ast_Ident);
			Entity *e = entity_of_node(ident);
			GB_ASSERT(e != nullptr);

			if (e->parent_proc_decl != nullptr && e->parent_proc_decl->entity != nullptr) {
				procedure = e->parent_proc_decl->entity->token.string;
			} else {
				procedure = str_lit("");
			}
			pos = e->token.pos;

		}
		return lb_emit_source_code_location(p, procedure, pos);
	}

	case BuiltinProc_type_info_of: {
		Ast *arg = ce->args[0];
		TypeAndValue tav = type_and_value_of_expr(arg);
		if (tav.mode == Addressing_Type) {
			Type *t = default_type(type_of_expr(arg));
			return lb_type_info(p->module, t);
		}
		GB_ASSERT(is_type_typeid(tav.type));

		auto args = array_make<lbValue>(permanent_allocator(), 1);
		args[0] = lb_build_expr(p, arg);
		return lb_emit_runtime_call(p, "__type_info_of", args);
	}

	case BuiltinProc_typeid_of: {
		Ast *arg = ce->args[0];
		TypeAndValue tav = type_and_value_of_expr(arg);
		GB_ASSERT(tav.mode == Addressing_Type);
		Type *t = default_type(type_of_expr(arg));
		return lb_typeid(p->module, t);
	}

	case BuiltinProc_len: {
		lbValue v = lb_build_expr(p, ce->args[0]);
		Type *t = base_type(v.type);
		if (is_type_pointer(t)) {
			// IMPORTANT TODO(bill): Should there be a nil pointer check?
			v = lb_emit_load(p, v);
			t = type_deref(t);
		}
		if (is_type_cstring(t)) {
			return lb_cstring_len(p, v);
		} else if (is_type_string(t)) {
			return lb_string_len(p, v);
		} else if (is_type_array(t)) {
			GB_PANIC("Array lengths are constant");
		} else if (is_type_slice(t) || is_type_relative_slice(t)) {
			return lb_slice_len(p, v);
		} else if (is_type_dynamic_array(t)) {
			return lb_dynamic_array_len(p, v);
		} else if (is_type_map(t)) {
			return lb_map_len(p, v);
		} else if (is_type_soa_struct(t)) {
			return lb_soa_struct_len(p, v);
		}

		GB_PANIC("Unreachable");
		break;
	}

	case BuiltinProc_cap: {
		lbValue v = lb_build_expr(p, ce->args[0]);
		Type *t = base_type(v.type);
		if (is_type_pointer(t)) {
			// IMPORTANT TODO(bill): Should there be a nil pointer check?
			v = lb_emit_load(p, v);
			t = type_deref(t);
		}
		if (is_type_string(t)) {
			GB_PANIC("Unreachable");
		} else if (is_type_array(t)) {
			GB_PANIC("Array lengths are constant");
		} else if (is_type_slice(t) || is_type_relative_slice(t)) {
			return lb_slice_len(p, v);
		} else if (is_type_dynamic_array(t)) {
			return lb_dynamic_array_cap(p, v);
		} else if (is_type_map(t)) {
			return lb_map_cap(p, v);
		} else if (is_type_soa_struct(t)) {
			return lb_soa_struct_cap(p, v);
		}

		GB_PANIC("Unreachable");

		break;
	}

	case BuiltinProc_swizzle: {
		isize index_count = ce->args.count-1;
		if (is_type_simd_vector(tv.type)) {
			lbValue vec = lb_build_expr(p, ce->args[0]);
			if (index_count == 0) {
				return vec;
			}

			unsigned mask_len = cast(unsigned)index_count;
			LLVMValueRef *mask_elems = gb_alloc_array(permanent_allocator(), LLVMValueRef, index_count);
			for (isize i = 1; i < ce->args.count; i++) {
				TypeAndValue tv = type_and_value_of_expr(ce->args[i]);
				GB_ASSERT(is_type_integer(tv.type));
				GB_ASSERT(tv.value.kind == ExactValue_Integer);

				u32 index = cast(u32)big_int_to_i64(&tv.value.value_integer);
				mask_elems[i-1] = LLVMConstInt(lb_type(p->module, t_u32), index, false);
			}

			LLVMValueRef mask = LLVMConstVector(mask_elems, mask_len);

			LLVMValueRef v1 = vec.value;
			LLVMValueRef v2 = vec.value;

			lbValue res = {};
			res.type = tv.type;
			res.value = LLVMBuildShuffleVector(p->builder, v1, v2, mask, "");
			return res;
		}

		lbAddr addr = lb_build_array_swizzle_addr(p, ce, tv);
		return lb_addr_load(p, addr);
	}

	case BuiltinProc_complex: {
		lbValue real = lb_build_expr(p, ce->args[0]);
		lbValue imag = lb_build_expr(p, ce->args[1]);
		lbAddr dst_addr = lb_add_local_generated(p, tv.type, false);
		lbValue dst = lb_addr_get_ptr(p, dst_addr);

		Type *ft = base_complex_elem_type(tv.type);
		real = lb_emit_conv(p, real, ft);
		imag = lb_emit_conv(p, imag, ft);
		lb_emit_store(p, lb_emit_struct_ep(p, dst, 0), real);
		lb_emit_store(p, lb_emit_struct_ep(p, dst, 1), imag);

		return lb_emit_load(p, dst);
	}

	case BuiltinProc_quaternion: {
		lbValue real = lb_build_expr(p, ce->args[0]);
		lbValue imag = lb_build_expr(p, ce->args[1]);
		lbValue jmag = lb_build_expr(p, ce->args[2]);
		lbValue kmag = lb_build_expr(p, ce->args[3]);

		// @QuaternionLayout
		lbAddr dst_addr = lb_add_local_generated(p, tv.type, false);
		lbValue dst = lb_addr_get_ptr(p, dst_addr);

		Type *ft = base_complex_elem_type(tv.type);
		real = lb_emit_conv(p, real, ft);
		imag = lb_emit_conv(p, imag, ft);
		jmag = lb_emit_conv(p, jmag, ft);
		kmag = lb_emit_conv(p, kmag, ft);
		lb_emit_store(p, lb_emit_struct_ep(p, dst, 3), real);
		lb_emit_store(p, lb_emit_struct_ep(p, dst, 0), imag);
		lb_emit_store(p, lb_emit_struct_ep(p, dst, 1), jmag);
		lb_emit_store(p, lb_emit_struct_ep(p, dst, 2), kmag);

		return lb_emit_load(p, dst);
	}

	case BuiltinProc_real: {
		lbValue val = lb_build_expr(p, ce->args[0]);
		if (is_type_complex(val.type)) {
			lbValue real = lb_emit_struct_ev(p, val, 0);
			return lb_emit_conv(p, real, tv.type);
		} else if (is_type_quaternion(val.type)) {
			// @QuaternionLayout
			lbValue real = lb_emit_struct_ev(p, val, 3);
			return lb_emit_conv(p, real, tv.type);
		}
		GB_PANIC("invalid type for real");
		return {};
	}
	case BuiltinProc_imag: {
		lbValue val = lb_build_expr(p, ce->args[0]);
		if (is_type_complex(val.type)) {
			lbValue imag = lb_emit_struct_ev(p, val, 1);
			return lb_emit_conv(p, imag, tv.type);
		} else if (is_type_quaternion(val.type)) {
			// @QuaternionLayout
			lbValue imag = lb_emit_struct_ev(p, val, 0);
			return lb_emit_conv(p, imag, tv.type);
		}
		GB_PANIC("invalid type for imag");
		return {};
	}
	case BuiltinProc_jmag: {
		lbValue val = lb_build_expr(p, ce->args[0]);
		if (is_type_quaternion(val.type)) {
			// @QuaternionLayout
			lbValue imag = lb_emit_struct_ev(p, val, 1);
			return lb_emit_conv(p, imag, tv.type);
		}
		GB_PANIC("invalid type for jmag");
		return {};
	}
	case BuiltinProc_kmag: {
		lbValue val = lb_build_expr(p, ce->args[0]);
		if (is_type_quaternion(val.type)) {
			// @QuaternionLayout
			lbValue imag = lb_emit_struct_ev(p, val, 2);
			return lb_emit_conv(p, imag, tv.type);
		}
		GB_PANIC("invalid type for kmag");
		return {};
	}

	case BuiltinProc_conj: {
		lbValue val = lb_build_expr(p, ce->args[0]);
		return lb_emit_conjugate(p, val, tv.type);
	}

	case BuiltinProc_expand_to_tuple: {
		lbValue val = lb_build_expr(p, ce->args[0]);
		Type *t = base_type(val.type);

		if (!is_type_tuple(tv.type)) {
			if (t->kind == Type_Struct) {
				GB_ASSERT(t->Struct.fields.count == 1);
				return lb_emit_struct_ev(p, val, 0);
			} else if (t->kind == Type_Array) {
				GB_ASSERT(t->Array.count == 1);
				return lb_emit_array_epi(p, val, 0);
			} else {
				GB_PANIC("Unknown type of expand_to_tuple");
			}

		}

		GB_ASSERT(is_type_tuple(tv.type));
		// NOTE(bill): Doesn't need to be zero because it will be initialized in the loops
		lbValue tuple = lb_addr_get_ptr(p, lb_add_local_generated(p, tv.type, false));
		if (t->kind == Type_Struct) {
			for_array(src_index, t->Struct.fields) {
				Entity *field = t->Struct.fields[src_index];
				i32 field_index = field->Variable.field_index;
				lbValue f = lb_emit_struct_ev(p, val, field_index);
				lbValue ep = lb_emit_struct_ep(p, tuple, cast(i32)src_index);
				lb_emit_store(p, ep, f);
			}
		} else if (is_type_array_like(t)) {
			// TODO(bill): Clean-up this code
			lbValue ap = lb_address_from_load_or_generate_local(p, val);
			i32 n = cast(i32)get_array_type_count(t);
			for (i32 i = 0; i < n; i++) {
				lbValue f = lb_emit_load(p, lb_emit_array_epi(p, ap, i));
				lbValue ep = lb_emit_struct_ep(p, tuple, i);
				lb_emit_store(p, ep, f);
			}
		} else {
			GB_PANIC("Unknown type of expand_to_tuple");
		}
		return lb_emit_load(p, tuple);
	}

	case BuiltinProc_min: {
		Type *t = type_of_expr(expr);
		if (ce->args.count == 2) {
			return lb_emit_min(p, t, lb_build_expr(p, ce->args[0]), lb_build_expr(p, ce->args[1]));
		} else {
			lbValue x = lb_build_expr(p, ce->args[0]);
			for (isize i = 1; i < ce->args.count; i++) {
				x = lb_emit_min(p, t, x, lb_build_expr(p, ce->args[i]));
			}
			return x;
		}
	}

	case BuiltinProc_max: {
		Type *t = type_of_expr(expr);
		if (ce->args.count == 2) {
			return lb_emit_max(p, t, lb_build_expr(p, ce->args[0]), lb_build_expr(p, ce->args[1]));
		} else {
			lbValue x = lb_build_expr(p, ce->args[0]);
			for (isize i = 1; i < ce->args.count; i++) {
				x = lb_emit_max(p, t, x, lb_build_expr(p, ce->args[i]));
			}
			return x;
		}
	}

	case BuiltinProc_abs: {
		lbValue x = lb_build_expr(p, ce->args[0]);
		Type *t = x.type;
		if (is_type_unsigned(t)) {
			return x;
		}
		if (is_type_quaternion(t)) {
			i64 sz = 8*type_size_of(t);
			auto args = array_make<lbValue>(permanent_allocator(), 1);
			args[0] = x;
			switch (sz) {
			case 64:  return lb_emit_runtime_call(p, "abs_quaternion64", args);
			case 128: return lb_emit_runtime_call(p, "abs_quaternion128", args);
			case 256: return lb_emit_runtime_call(p, "abs_quaternion256", args);
			}
			GB_PANIC("Unknown complex type");
		} else if (is_type_complex(t)) {
			i64 sz = 8*type_size_of(t);
			auto args = array_make<lbValue>(permanent_allocator(), 1);
			args[0] = x;
			switch (sz) {
			case 32:  return lb_emit_runtime_call(p, "abs_complex32",  args);
			case 64:  return lb_emit_runtime_call(p, "abs_complex64",  args);
			case 128: return lb_emit_runtime_call(p, "abs_complex128", args);
			}
			GB_PANIC("Unknown complex type");
		}
		lbValue zero = lb_const_nil(p->module, t);
		lbValue cond = lb_emit_comp(p, Token_Lt, x, zero);
		lbValue neg = lb_emit_unary_arith(p, Token_Sub, x, t);
		return lb_emit_select(p, cond, neg, x);
	}

	case BuiltinProc_clamp:
		return lb_emit_clamp(p, type_of_expr(expr),
							 lb_build_expr(p, ce->args[0]),
							 lb_build_expr(p, ce->args[1]),
							 lb_build_expr(p, ce->args[2]));


	case BuiltinProc_soa_zip:
		return lb_soa_zip(p, ce, tv);
	case BuiltinProc_soa_unzip:
		return lb_soa_unzip(p, ce, tv);

	case BuiltinProc_transpose:
		{
			lbValue m = lb_build_expr(p, ce->args[0]);
			return lb_emit_matrix_tranpose(p, m, tv.type);
		}

	case BuiltinProc_outer_product:
		{
			lbValue a = lb_build_expr(p, ce->args[0]);
			lbValue b = lb_build_expr(p, ce->args[1]);
			return lb_emit_outer_product(p, a, b, tv.type);
		}
	case BuiltinProc_hadamard_product:
		{
			lbValue a = lb_build_expr(p, ce->args[0]);
			lbValue b = lb_build_expr(p, ce->args[1]);
			if (is_type_array(tv.type)) {
				return lb_emit_arith(p, Token_Mul, a, b, tv.type);
			}
			GB_ASSERT(is_type_matrix(tv.type));
			return lb_emit_arith_matrix(p, Token_Mul, a, b, tv.type, true);
		}

	case BuiltinProc_matrix_flatten:
		{
			lbValue m = lb_build_expr(p, ce->args[0]);
			return lb_emit_matrix_flatten(p, m, tv.type);
		}

	case BuiltinProc_unreachable:
		lb_emit_unreachable(p);
		return {};


	// "Intrinsics"

	case BuiltinProc_alloca:
		{
			lbValue sz = lb_build_expr(p, ce->args[0]);
			i64 al = exact_value_to_i64(type_and_value_of_expr(ce->args[1]).value);

			lbValue res = {};
			res.type = t_u8_ptr;
			res.value = LLVMBuildArrayAlloca(p->builder, lb_type(p->module, t_u8), sz.value, "");
			LLVMSetAlignment(res.value, cast(unsigned)al);
			return res;
		}

	case BuiltinProc_cpu_relax:
		if (build_context.metrics.arch == TargetArch_i386 ||
			build_context.metrics.arch == TargetArch_amd64) {
			LLVMTypeRef func_type = LLVMFunctionType(LLVMVoidTypeInContext(p->module->ctx), nullptr, 0, false);
			LLVMValueRef the_asm = llvm_get_inline_asm(func_type, str_lit("pause"), {}, true);
			GB_ASSERT(the_asm != nullptr);
			LLVMBuildCall2(p->builder, func_type, the_asm, nullptr, 0, "");
		} else if (build_context.metrics.arch == TargetArch_arm64) {
			LLVMTypeRef func_type = LLVMFunctionType(LLVMVoidTypeInContext(p->module->ctx), nullptr, 0, false);
			// NOTE(bill, 2022-03-30): `isb` appears to a better option that `yield`
			// See: https://bugs.java.com/bugdatabase/view_bug.do?bug_id=8258604
			LLVMValueRef the_asm = llvm_get_inline_asm(func_type, str_lit("isb"), {}, true);
			GB_ASSERT(the_asm != nullptr);
			LLVMBuildCall2(p->builder, func_type, the_asm, nullptr, 0, "");
		} else {
			// NOTE: default to something to prevent optimization
			LLVMTypeRef func_type = LLVMFunctionType(LLVMVoidTypeInContext(p->module->ctx), nullptr, 0, false);
			LLVMValueRef the_asm = llvm_get_inline_asm(func_type, str_lit(""), {}, true);
			GB_ASSERT(the_asm != nullptr);
			LLVMBuildCall2(p->builder, func_type, the_asm, nullptr, 0, "");
		}
		return {};


	case BuiltinProc_debug_trap:
	case BuiltinProc_trap:
		{
			char const *name = nullptr;
			switch (id) {
			case BuiltinProc_debug_trap: name = "llvm.debugtrap"; break;
			case BuiltinProc_trap:       name = "llvm.trap";      break;
			}

			lb_call_intrinsic(p, name, nullptr, 0, nullptr, 0);
			if (id == BuiltinProc_trap) {
				LLVMBuildUnreachable(p->builder);
			}
			return {};
		}

	case BuiltinProc_read_cycle_counter:
		{
			lbValue res = {};
			res.type = tv.type;

			if (build_context.metrics.arch == TargetArch_arm64) {
				LLVMTypeRef func_type = LLVMFunctionType(LLVMInt64TypeInContext(p->module->ctx), nullptr, 0, false);
				bool has_side_effects = false;
				LLVMValueRef the_asm = llvm_get_inline_asm(func_type, str_lit("mrs x9, cntvct_el0"), str_lit("=r"), has_side_effects);
				GB_ASSERT(the_asm != nullptr);
				res.value = LLVMBuildCall2(p->builder, func_type, the_asm, nullptr, 0, "");
			} else {
				char const *name = "llvm.readcyclecounter";
				res.value = lb_call_intrinsic(p, name, nullptr, 0, nullptr, 0);
			}
			return res;
		}

	case BuiltinProc_count_trailing_zeros:
		return lb_emit_count_trailing_zeros(p, lb_build_expr(p, ce->args[0]), tv.type);
	case BuiltinProc_count_leading_zeros:
		return lb_emit_count_leading_zeros(p, lb_build_expr(p, ce->args[0]), tv.type);

	case BuiltinProc_count_ones:
		return lb_emit_count_ones(p, lb_build_expr(p, ce->args[0]), tv.type);
	case BuiltinProc_count_zeros:
		return lb_emit_count_zeros(p, lb_build_expr(p, ce->args[0]), tv.type);

	case BuiltinProc_reverse_bits:
		return lb_emit_reverse_bits(p, lb_build_expr(p, ce->args[0]), tv.type);

	case BuiltinProc_byte_swap:
		{
			lbValue x = lb_build_expr(p, ce->args[0]);
			x = lb_emit_conv(p, x, tv.type);
			return lb_emit_byte_swap(p, x, tv.type);
		}

	case BuiltinProc_overflow_add:
	case BuiltinProc_overflow_sub:
	case BuiltinProc_overflow_mul:
		{
			Type *main_type = tv.type;
			Type *type = main_type;
			if (is_type_tuple(main_type)) {
				type = main_type->Tuple.variables[0]->type;
			}

			lbValue x = lb_build_expr(p, ce->args[0]);
			lbValue y = lb_build_expr(p, ce->args[1]);
			x = lb_emit_conv(p, x, type);
			y = lb_emit_conv(p, y, type);

			char const *name = nullptr;
			if (is_type_unsigned(type)) {
				switch (id) {
				case BuiltinProc_overflow_add: name = "llvm.uadd.with.overflow"; break;
				case BuiltinProc_overflow_sub: name = "llvm.usub.with.overflow"; break;
				case BuiltinProc_overflow_mul: name = "llvm.umul.with.overflow"; break;
				}
			} else {
				switch (id) {
				case BuiltinProc_overflow_add: name = "llvm.sadd.with.overflow"; break;
				case BuiltinProc_overflow_sub: name = "llvm.ssub.with.overflow"; break;
				case BuiltinProc_overflow_mul: name = "llvm.smul.with.overflow"; break;
				}
			}
			LLVMTypeRef types[1] = {lb_type(p->module, type)};

			LLVMValueRef args[2] = { x.value, y.value };

			lbValue res = {};
			res.value = lb_call_intrinsic(p, name, args, gb_count_of(args), types, gb_count_of(types));

			if (is_type_tuple(main_type)) {
				Type *res_type = nullptr;
				gbAllocator a = permanent_allocator();
				res_type = alloc_type_tuple();
				slice_init(&res_type->Tuple.variables, a, 2);
				res_type->Tuple.variables[0] = alloc_entity_field(nullptr, blank_token, type,        false, 0);
				res_type->Tuple.variables[1] = alloc_entity_field(nullptr, blank_token, t_llvm_bool, false, 1);

				res.type = res_type;
			} else {
				res.value = LLVMBuildExtractValue(p->builder, res.value, 0, "");
				res.type = type;
			}
			return res;
		}

	case BuiltinProc_sqrt:
		{
			Type *type = tv.type;

			lbValue x = lb_build_expr(p, ce->args[0]);
			x = lb_emit_conv(p, x, type);

			char const *name = "llvm.sqrt";
			LLVMTypeRef types[1] = {lb_type(p->module, type)};

			LLVMValueRef args[1] = { x.value };

			lbValue res = {};
			res.value = lb_call_intrinsic(p, name, args, gb_count_of(args), types, gb_count_of(types));
			res.type = type;
			return res;
		}

	case BuiltinProc_fused_mul_add:
		{
			Type *type = tv.type;
			lbValue x = lb_emit_conv(p, lb_build_expr(p, ce->args[0]), type);
			lbValue y = lb_emit_conv(p, lb_build_expr(p, ce->args[1]), type);
			lbValue z = lb_emit_conv(p, lb_build_expr(p, ce->args[2]), type);


			char const *name = "llvm.fma";
			LLVMTypeRef types[1] = {lb_type(p->module, type)};

			LLVMValueRef args[3] = { x.value, y.value, z.value };

			lbValue res = {};
			res.value = lb_call_intrinsic(p, name, args, gb_count_of(args), types, gb_count_of(types));
			res.type = type;
			return res;
		}

	case BuiltinProc_mem_copy:
		{
			lbValue dst = lb_build_expr(p, ce->args[0]);
			lbValue src = lb_build_expr(p, ce->args[1]);
			lbValue len = lb_build_expr(p, ce->args[2]);

			lb_mem_copy_overlapping(p, dst, src, len, false);
			return {};
		}
	case BuiltinProc_mem_copy_non_overlapping:
		{
			lbValue dst = lb_build_expr(p, ce->args[0]);
			lbValue src = lb_build_expr(p, ce->args[1]);
			lbValue len = lb_build_expr(p, ce->args[2]);

			lb_mem_copy_non_overlapping(p, dst, src, len, false);
			return {};
		}

	case BuiltinProc_mem_zero:
		{
			lbValue ptr = lb_build_expr(p, ce->args[0]);
			lbValue len = lb_build_expr(p, ce->args[1]);
			ptr = lb_emit_conv(p, ptr, t_rawptr);
			len = lb_emit_conv(p, len, t_int);

			unsigned alignment = 1;
			lb_mem_zero_ptr_internal(p, ptr.value, len.value, alignment, false);
			return {};
		}
	case BuiltinProc_mem_zero_volatile:
		{
			lbValue ptr = lb_build_expr(p, ce->args[0]);
			lbValue len = lb_build_expr(p, ce->args[1]);
			ptr = lb_emit_conv(p, ptr, t_rawptr);
			len = lb_emit_conv(p, len, t_int);

			unsigned alignment = 1;
			lb_mem_zero_ptr_internal(p, ptr.value, len.value, alignment, true);
			return {};
		}

	case BuiltinProc_ptr_offset:
		{
			lbValue ptr = lb_build_expr(p, ce->args[0]);
			lbValue len = lb_build_expr(p, ce->args[1]);
			len = lb_emit_conv(p, len, t_int);
			return lb_emit_ptr_offset(p, ptr, len);
		}
	case BuiltinProc_ptr_sub:
		{
			lbValue ptr0 = lb_build_expr(p, ce->args[0]);
			lbValue ptr1 = lb_build_expr(p, ce->args[1]);

			LLVMTypeRef type_int = lb_type(p->module, t_int);
			LLVMValueRef diff = LLVMBuildPtrDiff2(p->builder, lb_type(p->module, ptr0.type), ptr0.value, ptr1.value, "");
			diff = LLVMBuildIntCast2(p->builder, diff, type_int, /*signed*/true, "");

			lbValue res = {};
			res.type = t_int;
			res.value = diff;
			return res;
		}


	// TODO(bill): Which is correct?
	case BuiltinProc_atomic_thread_fence:
		LLVMBuildFence(p->builder, llvm_atomic_ordering_from_odin(ce->args[0]), false, "");
		return {};
	case BuiltinProc_atomic_signal_fence:
		LLVMBuildFence(p->builder, llvm_atomic_ordering_from_odin(ce->args[0]), true, "");
		return {};

	case BuiltinProc_volatile_store:
	case BuiltinProc_non_temporal_store:
	case BuiltinProc_atomic_store:
	case BuiltinProc_atomic_store_explicit: {
		lbValue dst = lb_build_expr(p, ce->args[0]);
		lbValue val = lb_build_expr(p, ce->args[1]);
		val = lb_emit_conv(p, val, type_deref(dst.type));

		LLVMValueRef instr = LLVMBuildStore(p->builder, val.value, dst.value);
		switch (id) {
		case BuiltinProc_non_temporal_store:
			{
				unsigned kind_id = LLVMGetMDKindIDInContext(p->module->ctx, "nontemporal", 11);
				LLVMMetadataRef node = LLVMValueAsMetadata(LLVMConstInt(lb_type(p->module, t_u32), 1, false));
				LLVMSetMetadata(instr, kind_id, LLVMMetadataAsValue(p->module->ctx, node));
			}
			break;
		case BuiltinProc_volatile_store:        LLVMSetVolatile(instr, true);                                        break;
		case BuiltinProc_atomic_store:          LLVMSetOrdering(instr, LLVMAtomicOrderingSequentiallyConsistent);    break;
		case BuiltinProc_atomic_store_explicit: LLVMSetOrdering(instr, llvm_atomic_ordering_from_odin(ce->args[2])); break;
		}

		LLVMSetAlignment(instr, cast(unsigned)type_align_of(type_deref(dst.type)));

		return {};
	}

	case BuiltinProc_volatile_load:
	case BuiltinProc_non_temporal_load:
	case BuiltinProc_atomic_load:
	case BuiltinProc_atomic_load_explicit: {
		lbValue dst = lb_build_expr(p, ce->args[0]);

		LLVMValueRef instr = LLVMBuildLoad2(p->builder,  lb_type(p->module, type_deref(dst.type)), dst.value, "");
		switch (id) {
		case BuiltinProc_non_temporal_load:
			{
				unsigned kind_id = LLVMGetMDKindIDInContext(p->module->ctx, "nontemporal", 11);
				LLVMMetadataRef node = LLVMValueAsMetadata(LLVMConstInt(lb_type(p->module, t_u32), 1, false));
				LLVMSetMetadata(instr, kind_id, LLVMMetadataAsValue(p->module->ctx, node));
			}
			break;
			break;
		case BuiltinProc_volatile_load:        LLVMSetVolatile(instr, true);                                        break;
		case BuiltinProc_atomic_load:          LLVMSetOrdering(instr, LLVMAtomicOrderingSequentiallyConsistent);    break;
		case BuiltinProc_atomic_load_explicit: LLVMSetOrdering(instr, llvm_atomic_ordering_from_odin(ce->args[1])); break;
		}
		LLVMSetAlignment(instr, cast(unsigned)type_align_of(type_deref(dst.type)));

		lbValue res = {};
		res.value = instr;
		res.type = type_deref(dst.type);
		return res;
	}

	case BuiltinProc_unaligned_store:
		{
			lbValue dst = lb_build_expr(p, ce->args[0]);
			lbValue src = lb_build_expr(p, ce->args[1]);
			src = lb_address_from_load_or_generate_local(p, src);
			Type *t = type_deref(dst.type);
			lb_mem_copy_non_overlapping(p, dst, src, lb_const_int(p->module, t_int, type_size_of(t)), false);
			return {};
		}

	case BuiltinProc_unaligned_load:
		{
			lbValue src = lb_build_expr(p, ce->args[0]);
			Type *t = type_deref(src.type);
			lbAddr dst = lb_add_local_generated(p, t, false);
			lb_mem_copy_non_overlapping(p, dst.addr, src, lb_const_int(p->module, t_int, type_size_of(t)), false);
			return lb_addr_load(p, dst);
		}

	case BuiltinProc_atomic_add:
	case BuiltinProc_atomic_sub:
	case BuiltinProc_atomic_and:
	case BuiltinProc_atomic_nand:
	case BuiltinProc_atomic_or:
	case BuiltinProc_atomic_xor:
	case BuiltinProc_atomic_exchange:
	case BuiltinProc_atomic_add_explicit:
	case BuiltinProc_atomic_sub_explicit:
	case BuiltinProc_atomic_and_explicit:
	case BuiltinProc_atomic_nand_explicit:
	case BuiltinProc_atomic_or_explicit:
	case BuiltinProc_atomic_xor_explicit:
	case BuiltinProc_atomic_exchange_explicit: {
		lbValue dst = lb_build_expr(p, ce->args[0]);
		lbValue val = lb_build_expr(p, ce->args[1]);
		val = lb_emit_conv(p, val, type_deref(dst.type));

		LLVMAtomicRMWBinOp op = {};
		LLVMAtomicOrdering ordering = {};

		switch (id) {
		case BuiltinProc_atomic_add:               op = LLVMAtomicRMWBinOpAdd;  ordering = LLVMAtomicOrderingSequentiallyConsistent;    break;
		case BuiltinProc_atomic_sub:               op = LLVMAtomicRMWBinOpSub;  ordering = LLVMAtomicOrderingSequentiallyConsistent;    break;
		case BuiltinProc_atomic_and:               op = LLVMAtomicRMWBinOpAnd;  ordering = LLVMAtomicOrderingSequentiallyConsistent;    break;
		case BuiltinProc_atomic_nand:              op = LLVMAtomicRMWBinOpNand; ordering = LLVMAtomicOrderingSequentiallyConsistent;    break;
		case BuiltinProc_atomic_or:                op = LLVMAtomicRMWBinOpOr;   ordering = LLVMAtomicOrderingSequentiallyConsistent;    break;
		case BuiltinProc_atomic_xor:               op = LLVMAtomicRMWBinOpXor;  ordering = LLVMAtomicOrderingSequentiallyConsistent;    break;
		case BuiltinProc_atomic_exchange:          op = LLVMAtomicRMWBinOpXchg; ordering = LLVMAtomicOrderingSequentiallyConsistent;    break;
		case BuiltinProc_atomic_add_explicit:      op = LLVMAtomicRMWBinOpAdd;  ordering = llvm_atomic_ordering_from_odin(ce->args[2]); break;
		case BuiltinProc_atomic_sub_explicit:      op = LLVMAtomicRMWBinOpSub;  ordering = llvm_atomic_ordering_from_odin(ce->args[2]); break;
		case BuiltinProc_atomic_and_explicit:      op = LLVMAtomicRMWBinOpAnd;  ordering = llvm_atomic_ordering_from_odin(ce->args[2]); break;
		case BuiltinProc_atomic_nand_explicit:     op = LLVMAtomicRMWBinOpNand; ordering = llvm_atomic_ordering_from_odin(ce->args[2]); break;
		case BuiltinProc_atomic_or_explicit:       op = LLVMAtomicRMWBinOpOr;   ordering = llvm_atomic_ordering_from_odin(ce->args[2]); break;
		case BuiltinProc_atomic_xor_explicit:      op = LLVMAtomicRMWBinOpXor;  ordering = llvm_atomic_ordering_from_odin(ce->args[2]); break;
		case BuiltinProc_atomic_exchange_explicit: op = LLVMAtomicRMWBinOpXchg; ordering = llvm_atomic_ordering_from_odin(ce->args[2]); break;
		}

		lbValue res = {};
		res.value = LLVMBuildAtomicRMW(p->builder, op, dst.value, val.value, ordering, false);
		res.type = tv.type;
		return res;
	}

	case BuiltinProc_atomic_compare_exchange_strong:
	case BuiltinProc_atomic_compare_exchange_weak:
	case BuiltinProc_atomic_compare_exchange_strong_explicit:
	case BuiltinProc_atomic_compare_exchange_weak_explicit: {
		lbValue address = lb_build_expr(p, ce->args[0]);
		Type *elem = type_deref(address.type);
		lbValue old_value = lb_build_expr(p, ce->args[1]);
		lbValue new_value = lb_build_expr(p, ce->args[2]);
		old_value = lb_emit_conv(p, old_value, elem);
		new_value = lb_emit_conv(p, new_value, elem);

		LLVMAtomicOrdering success_ordering = {};
		LLVMAtomicOrdering failure_ordering = {};
		LLVMBool weak = false;

		switch (id) {
		case BuiltinProc_atomic_compare_exchange_strong:          success_ordering = LLVMAtomicOrderingSequentiallyConsistent;    failure_ordering = LLVMAtomicOrderingSequentiallyConsistent;    weak = false; break;
		case BuiltinProc_atomic_compare_exchange_weak:            success_ordering = LLVMAtomicOrderingSequentiallyConsistent;    failure_ordering = LLVMAtomicOrderingSequentiallyConsistent;    weak = true;  break;
		case BuiltinProc_atomic_compare_exchange_strong_explicit: success_ordering = llvm_atomic_ordering_from_odin(ce->args[3]); failure_ordering = llvm_atomic_ordering_from_odin(ce->args[4]); weak = false; break;
		case BuiltinProc_atomic_compare_exchange_weak_explicit:   success_ordering = llvm_atomic_ordering_from_odin(ce->args[3]); failure_ordering = llvm_atomic_ordering_from_odin(ce->args[4]); weak = true;  break;
		}

		// TODO(bill): Figure out how to make it weak
		LLVMBool single_threaded = false;

		LLVMValueRef value = LLVMBuildAtomicCmpXchg(
			p->builder, address.value,
			old_value.value, new_value.value,
			success_ordering,
			failure_ordering,
			single_threaded
		);
		LLVMSetWeak(value, weak);

		if (tv.type->kind == Type_Tuple) {
			Type *fix_typed = alloc_type_tuple();
			slice_init(&fix_typed->Tuple.variables, permanent_allocator(), 2);
			fix_typed->Tuple.variables[0] = tv.type->Tuple.variables[0];
			fix_typed->Tuple.variables[1] = alloc_entity_field(nullptr, blank_token, t_llvm_bool, false, 1);

			lbValue res = {};
			res.value = value;
			res.type = fix_typed;
			return res;
		} else {
			lbValue res = {};
			res.value = LLVMBuildExtractValue(p->builder, value, 0, "");
			res.type = tv.type;
			return res;
		}
	}


	case BuiltinProc_type_equal_proc:
		return lb_get_equal_proc_for_type(p->module, ce->args[0]->tav.type);

	case BuiltinProc_type_hasher_proc:
		return lb_get_hasher_proc_for_type(p->module, ce->args[0]->tav.type);

	case BuiltinProc_fixed_point_mul:
	case BuiltinProc_fixed_point_div:
	case BuiltinProc_fixed_point_mul_sat:
	case BuiltinProc_fixed_point_div_sat:
		{
			Type *platform_type = integer_endian_type_to_platform_type(tv.type);

			lbValue x     = lb_emit_conv(p, lb_build_expr(p, ce->args[0]), platform_type);
			lbValue y     = lb_emit_conv(p, lb_build_expr(p, ce->args[1]), platform_type);
			lbValue scale = lb_emit_conv(p, lb_build_expr(p, ce->args[2]), t_i32);

			char const *name = nullptr;
			if (is_type_unsigned(tv.type)) {
				switch (id) {
				case BuiltinProc_fixed_point_mul:     name = "llvm.umul.fix";     break;
				case BuiltinProc_fixed_point_div:     name = "llvm.udiv.fix";     break;
				case BuiltinProc_fixed_point_mul_sat: name = "llvm.umul.fix.sat"; break;
				case BuiltinProc_fixed_point_div_sat: name = "llvm.udiv.fix.sat"; break;
				}
			} else {
				switch (id) {
				case BuiltinProc_fixed_point_mul:     name = "llvm.smul.fix";     break;
				case BuiltinProc_fixed_point_div:     name = "llvm.sdiv.fix";     break;
				case BuiltinProc_fixed_point_mul_sat: name = "llvm.smul.fix.sat"; break;
				case BuiltinProc_fixed_point_div_sat: name = "llvm.sdiv.fix.sat"; break;
				}
			}
			GB_ASSERT(name != nullptr);

			LLVMTypeRef types[1] = {lb_type(p->module, platform_type)};
			lbValue res = {};

			LLVMValueRef args[3] = {
					x.value,
					y.value,
					scale.value };

			res.value = lb_call_intrinsic(p, name, args, gb_count_of(args), types, gb_count_of(types));
			res.type = platform_type;
			return lb_emit_conv(p, res, tv.type);
		}

	case BuiltinProc_expect:
		{
			Type *t = default_type(tv.type);
			lbValue x = lb_emit_conv(p, lb_build_expr(p, ce->args[0]), t);
			lbValue y = lb_emit_conv(p, lb_build_expr(p, ce->args[1]), t);

			char const *name = "llvm.expect";

			LLVMTypeRef types[1] = {lb_type(p->module, t)};
			lbValue res = {};
			LLVMValueRef args[2] = { x.value, y.value };

			res.value = lb_call_intrinsic(p, name, args, gb_count_of(args), types, gb_count_of(types));
			res.type = t;
			return lb_emit_conv(p, res, t);
		}

	case BuiltinProc_prefetch_read_instruction:
	case BuiltinProc_prefetch_read_data:
	case BuiltinProc_prefetch_write_instruction:
	case BuiltinProc_prefetch_write_data:
		{
			lbValue ptr = lb_emit_conv(p, lb_build_expr(p, ce->args[0]), t_rawptr);
			unsigned long long locality = cast(unsigned long long)exact_value_to_i64(ce->args[1]->tav.value);
			unsigned long long rw = 0;
			unsigned long long cache = 0;
			switch (id) {
			case BuiltinProc_prefetch_read_instruction:
				rw = 0;
				cache = 0;
				break;
			case BuiltinProc_prefetch_read_data:
				rw = 0;
				cache = 1;
				break;
			case BuiltinProc_prefetch_write_instruction:
				rw = 1;
				cache = 0;
				break;
			case BuiltinProc_prefetch_write_data:
				rw = 1;
				cache = 1;
				break;
			}

			char const *name = "llvm.prefetch";

			LLVMTypeRef types[1] = {lb_type(p->module, t_rawptr)};

			LLVMTypeRef llvm_i32 = lb_type(p->module, t_i32);
			LLVMValueRef args[4] = {};
			args[0] = ptr.value;
			args[1] = LLVMConstInt(llvm_i32, rw, false);
			args[2] = LLVMConstInt(llvm_i32, locality, false);
			args[3] = LLVMConstInt(llvm_i32, cache, false);

			lbValue res = {};
			res.value = lb_call_intrinsic(p, name, args, gb_count_of(args), types, gb_count_of(types));
			res.type = nullptr;
			return res;
		}

	case BuiltinProc___entry_point:
		if (p->module->info->entry_point) {
			lbValue entry_point = lb_find_procedure_value_from_entity(p->module, p->module->info->entry_point);
			GB_ASSERT(entry_point.value != nullptr);
			lb_emit_call(p, entry_point, {});
		}
		return {};

	case BuiltinProc_syscall:
		{
			unsigned arg_count = cast(unsigned)ce->args.count;
			LLVMValueRef *args = gb_alloc_array(permanent_allocator(), LLVMValueRef, arg_count);
			for_array(i, ce->args) {
				lbValue arg = lb_build_expr(p, ce->args[i]);
				arg = lb_emit_conv(p, arg, t_uintptr);
				args[i] = arg.value;
			}

			LLVMTypeRef llvm_uintptr = lb_type(p->module, t_uintptr);
			LLVMTypeRef *llvm_arg_types = gb_alloc_array(permanent_allocator(), LLVMTypeRef, arg_count);
			for (unsigned i = 0; i < arg_count; i++) {
				llvm_arg_types[i] = llvm_uintptr;
			}

			LLVMTypeRef func_type = LLVMFunctionType(llvm_uintptr, llvm_arg_types, arg_count, false);

			LLVMValueRef inline_asm = nullptr;

			switch (build_context.metrics.arch) {
			case TargetArch_amd64:
				{
					GB_ASSERT(arg_count <= 7);

					char asm_string[] = "syscall";
					gbString constraints = gb_string_make(heap_allocator(), "={rax}");
					for (unsigned i = 0; i < arg_count; i++) {
						constraints = gb_string_appendc(constraints, ",{");
						static char const *regs[] = {
							"rax",
							"rdi",
							"rsi",
							"rdx",
							"r10",
							"r8",
							"r9"
						};
						constraints = gb_string_appendc(constraints, regs[i]);
						constraints = gb_string_appendc(constraints, "}");
					}

					// The SYSCALL instruction stores the address of the
					// following instruction into RCX, and RFLAGS in R11.
					//
					// RSP is not saved, but at least on Linux it appears
					// that the kernel system-call handler does the right
					// thing.
					//
					// Some but not all system calls will additionally
					// clobber memory.
					//
					// TODO: FreeBSD is different and will also clobber
					// R8, R9, and R10.  Additionally CF is used to
					// indicate an error instead of -errno.
					constraints = gb_string_appendc(constraints, ",~{rcx},~{r11},~{memory}");

					inline_asm = llvm_get_inline_asm(func_type, make_string_c(asm_string), make_string_c(constraints));
				}
				break;
			case TargetArch_i386:
				{
					GB_ASSERT(arg_count <= 7);

					char asm_string_default[] = "int $0x80";
					char *asm_string = asm_string_default;
					gbString constraints = gb_string_make(heap_allocator(), "={eax}");

					for (unsigned i = 0; i < gb_min(arg_count, 6); i++) {
						constraints = gb_string_appendc(constraints, ",{");
						static char const *regs[] = {
							"eax",
							"ebx",
							"ecx",
							"edx",
							"esi",
							"edi",
						};
						constraints = gb_string_appendc(constraints, regs[i]);
						constraints = gb_string_appendc(constraints, "}");
					}
					if (arg_count == 7) {
						char asm_string7[] = "push %[arg6]\npush %%ebp\nmov 4(%%esp), %%ebp\nint $0x80\npop %%ebp\nadd $4, %%esp";
						asm_string = asm_string7;

						constraints = gb_string_appendc(constraints, ",rm");
					}

					inline_asm = llvm_get_inline_asm(func_type, make_string_c(asm_string), make_string_c(constraints));
				}
				break;
			case TargetArch_arm64:
				{
					GB_ASSERT(arg_count <= 7);

					if(build_context.metrics.os == TargetOs_darwin) {
						char asm_string[] = "svc #0x80";
						gbString constraints = gb_string_make(heap_allocator(), "={x0}");
						for (unsigned i = 0; i < arg_count; i++) {
							constraints = gb_string_appendc(constraints, ",{");
							static char const *regs[] = {
								"x16",
								"x0",
								"x1",
								"x2",
								"x3",
								"x4",
								"x5",
							};
							constraints = gb_string_appendc(constraints, regs[i]);
							constraints = gb_string_appendc(constraints, "}");
						}

						inline_asm = llvm_get_inline_asm(func_type, make_string_c(asm_string), make_string_c(constraints));
					} else {
						char asm_string[] = "svc #0";
						gbString constraints = gb_string_make(heap_allocator(), "={x0}");
						for (unsigned i = 0; i < arg_count; i++) {
							constraints = gb_string_appendc(constraints, ",{");
							static char const *regs[] = {
								"x8",
								"x0",
								"x1",
								"x2",
								"x3",
								"x4",
								"x5",
							};
							constraints = gb_string_appendc(constraints, regs[i]);
							constraints = gb_string_appendc(constraints, "}");
						}

						inline_asm = llvm_get_inline_asm(func_type, make_string_c(asm_string), make_string_c(constraints));
					}
				}
				break;
			case TargetArch_arm32:
				{
					// TODO(bill): Check this is correct
					GB_ASSERT(arg_count <= 7);

					char asm_string[] = "svc #0";
					gbString constraints = gb_string_make(heap_allocator(), "={r0}");
					for (unsigned i = 0; i < arg_count; i++) {
						constraints = gb_string_appendc(constraints, ",{");
						static char const *regs[] = {
							"r8",
							"r0",
							"r1",
							"r2",
							"r3",
							"r4",
							"r5",
						};
						constraints = gb_string_appendc(constraints, regs[i]);
						constraints = gb_string_appendc(constraints, "}");
					}

					inline_asm = llvm_get_inline_asm(func_type, make_string_c(asm_string), make_string_c(constraints));
				}
				break;
			default:
				GB_PANIC("Unsupported platform");
			}
			
			lbValue res = {};
			res.value = LLVMBuildCall2(p->builder, func_type, inline_asm, args, arg_count, "");
			res.type = t_uintptr;
			return res;
		}

	case BuiltinProc_objc_send:
		return lb_handle_objc_send(p, expr);

	case BuiltinProc_objc_find_selector:     return lb_handle_objc_find_selector(p, expr);
	case BuiltinProc_objc_find_class:        return lb_handle_objc_find_class(p, expr);
	case BuiltinProc_objc_register_selector: return lb_handle_objc_register_selector(p, expr);
	case BuiltinProc_objc_register_class:    return lb_handle_objc_register_class(p, expr);


	case BuiltinProc_constant_utf16_cstring:
		{
			auto const encode_surrogate_pair = [](Rune r, u16 *r1, u16 *r2) {
				if (r < 0x10000 || r > 0x10ffff) {
					*r1 = 0xfffd;
					*r2 = 0xfffd;
				} else {
					r -= 0x10000;
					*r1 = 0xd800 + ((r>>10)&0x3ff);
					*r2 = 0xdc00 + (r&0x3ff);
				}
			};

			lbModule *m = p->module;

			auto tav = type_and_value_of_expr(ce->args[0]);
			GB_ASSERT(tav.value.kind == ExactValue_String);
			String value = tav.value.value_string;

			LLVMTypeRef llvm_u16 = lb_type(m, t_u16);

			isize max_len = value.len*2 + 1;
			LLVMValueRef *buffer = gb_alloc_array(temporary_allocator(), LLVMValueRef, max_len);
			isize n = 0;
			while (value.len > 0) {
				Rune r = 0;
				isize w = gb_utf8_decode(value.text, value.len, &r);
				value.text += w;
				value.len  -= w;
				if ((0 <= r && r < 0xd800) || (0xe000 <= r && r < 0x10000)) {
					buffer[n++] = LLVMConstInt(llvm_u16, cast(u16)r, false);
				} else if (0x10000 <= r && r <= 0x10ffff) {
					u16 r1, r2;
					encode_surrogate_pair(r, &r1, &r2);
					buffer[n++] = LLVMConstInt(llvm_u16, r1, false);
					buffer[n++] = LLVMConstInt(llvm_u16, r2, false);
				} else {
					buffer[n++] = LLVMConstInt(llvm_u16, 0xfffd, false);
				}
			}

			buffer[n++] = LLVMConstInt(llvm_u16, 0, false);

			LLVMValueRef array = LLVMConstArray(llvm_u16, buffer, cast(unsigned int)n);

			char *name = nullptr;
			{
				isize max_len = 7+8+1;
				name = gb_alloc_array(permanent_allocator(), char, max_len);
				u32 id = m->gen->global_array_index.fetch_add(1);
				isize len = gb_snprintf(name, max_len, "csbs$%x", id);
				len -= 1;
			}
			LLVMTypeRef type = LLVMTypeOf(array);
			LLVMValueRef global_data = LLVMAddGlobal(m->mod, type, name);
			LLVMSetInitializer(global_data, array);
			LLVMSetLinkage(global_data, LLVMInternalLinkage);



			LLVMValueRef indices[] = {
				LLVMConstInt(lb_type(m, t_u32), 0, false),
				LLVMConstInt(lb_type(m, t_u32), 0, false),
			};
			lbValue res = {};
			res.type = tv.type;
			res.value = LLVMBuildInBoundsGEP2(p->builder, type, global_data, indices, gb_count_of(indices), "");
			return res;

		}

	case BuiltinProc_wasm_memory_grow:
		{
			char const *name = "llvm.wasm.memory.grow";
			LLVMTypeRef types[1] = {
				lb_type(p->module, t_uintptr),
			};

			LLVMValueRef args[2] = {};
			args[0] = lb_emit_conv(p, lb_build_expr(p, ce->args[0]), t_uintptr).value;
			args[1] = lb_emit_conv(p, lb_build_expr(p, ce->args[1]), t_uintptr).value;

			lbValue res = {};
			res.type = tv.type;
			res.value = lb_call_intrinsic(p, name, args, gb_count_of(args), types, gb_count_of(types));
			return res;
		}
	case BuiltinProc_wasm_memory_size:
		{
			char const *name = "llvm.wasm.memory.size";
			LLVMTypeRef types[1] = {
				lb_type(p->module, t_uintptr),
			};

			LLVMValueRef args[1] = {};
			args[0] = lb_emit_conv(p, lb_build_expr(p, ce->args[0]), t_uintptr).value;

			lbValue res = {};
			res.type = tv.type;
			res.value = lb_call_intrinsic(p, name, args, gb_count_of(args), types, gb_count_of(types));
			return res;
		}

	case BuiltinProc_wasm_memory_atomic_wait32:
		{
			char const *name = "llvm.wasm.memory.atomic.wait32";
			LLVMTypeRef types[1] = {
				lb_type(p->module, t_u32),
			};

			Type *t_u32_ptr = alloc_type_pointer(t_u32);

			LLVMValueRef args[3] = {};
			args[0] = lb_emit_conv(p, lb_build_expr(p, ce->args[0]), t_u32_ptr).value;
			args[1] = lb_emit_conv(p, lb_build_expr(p, ce->args[1]), t_u32).value;
			args[2] = lb_emit_conv(p, lb_build_expr(p, ce->args[2]), t_i64).value;

			lbValue res = {};
			res.type = tv.type;
			res.value = lb_call_intrinsic(p, name, args, gb_count_of(args), types, gb_count_of(types));
			return res;
		}

	case BuiltinProc_wasm_memory_atomic_notify32:
		{
			char const *name = "llvm.wasm.memory.atomic.notify";
			LLVMTypeRef types[1] = {
				lb_type(p->module, t_u32),
			};

			Type *t_u32_ptr = alloc_type_pointer(t_u32);

			LLVMValueRef args[2] = {
					lb_emit_conv(p, lb_build_expr(p, ce->args[0]), t_u32_ptr).value,
					lb_emit_conv(p, lb_build_expr(p, ce->args[1]), t_u32).value };

			lbValue res = {};
			res.type = tv.type;
			res.value = lb_call_intrinsic(p, name, args, gb_count_of(args), types, gb_count_of(types));
			return res;
		}


	case BuiltinProc_x86_cpuid:
		{
			Type *param_types[2] = {t_u32, t_u32};
			Type *type = alloc_type_proc_from_types(param_types, gb_count_of(param_types), tv.type, false, ProcCC_None);
			LLVMTypeRef func_type = lb_get_procedure_raw_type(p->module, type);
			LLVMValueRef the_asm = llvm_get_inline_asm(
				func_type,
				str_lit("cpuid"),
				str_lit("={ax},={bx},={cx},={dx},{ax},{cx}"),
				true
			);
			GB_ASSERT(the_asm != nullptr);

			LLVMValueRef args[2] = {};
			args[0] = lb_emit_conv(p, lb_build_expr(p, ce->args[0]), t_u32).value;
			args[1] = lb_emit_conv(p, lb_build_expr(p, ce->args[1]), t_u32).value;
			lbValue res = {};
			res.type = tv.type;
			res.value = LLVMBuildCall2(p->builder, func_type, the_asm, args, gb_count_of(args), "");
			return res;
		}
	case BuiltinProc_x86_xgetbv:
		{
			Type *type = alloc_type_proc_from_types(&t_u32, 1, tv.type, false, ProcCC_None);
			LLVMTypeRef func_type = lb_get_procedure_raw_type(p->module, type);
			LLVMValueRef the_asm = llvm_get_inline_asm(
				func_type,
				str_lit("xgetbv"),
				str_lit("={ax},={dx},{cx}"),
				true
			);
			GB_ASSERT(the_asm != nullptr);

			LLVMValueRef args[1] = {};
			args[0] = lb_emit_conv(p, lb_build_expr(p, ce->args[0]), t_u32).value;
			lbValue res = {};
			res.type = tv.type;
			res.value = LLVMBuildCall2(p->builder, func_type, the_asm, args, gb_count_of(args), "");
			return res;
		}

	case BuiltinProc_valgrind_client_request:
		{
			lbValue args[7] = {};
			for (isize i = 0; i < 7; i++) {
				args[i] = lb_emit_conv(p, lb_build_expr(p, ce->args[i]), t_uintptr);
			}
			if (!build_context.ODIN_VALGRIND_SUPPORT) {
				return args[0];
			}
			lbValue array = lb_generate_local_array(p, t_uintptr, 6, false);
			for (isize i = 0; i < 6; i++) {
				lbValue gep = lb_emit_array_epi(p, array, i);
				lb_emit_store(p, gep, args[i+1]);
			}

			switch (build_context.metrics.arch) {
			case TargetArch_amd64:
				{
					Type *param_types[2] = {};
					param_types[0] = t_uintptr;
					param_types[1] = array.type;

					Type *type = alloc_type_proc_from_types(param_types, gb_count_of(param_types), t_uintptr, false, ProcCC_None);
					LLVMTypeRef func_type = lb_get_procedure_raw_type(p->module, type);
					LLVMValueRef the_asm = llvm_get_inline_asm(
						func_type,
						str_lit("rolq $3, %rdi; rolq $13, %rdi\n rolq $61, %rdi; rolq $51, %rdi\n xchgq %rbx, %rbx"),
						str_lit("={rdx},{rdx},{rax},cc,memory"),
						true
					);

					LLVMValueRef asm_args[2] = {};
					asm_args[0] = args[0].value;
					asm_args[1] = array.value;

					lbValue res = {};
					res.type = t_uintptr;
					res.value = LLVMBuildCall2(p->builder, func_type, the_asm, asm_args, gb_count_of(asm_args), "");
					return res;
				}
				break;
			default:
				GB_PANIC("Unsupported architecture: %.*s", LIT(target_arch_names[build_context.metrics.arch]));
				break;
			}

		}

	}

	GB_PANIC("Unhandled built-in procedure %.*s", LIT(builtin_procs[id].name));
	return {};
}


lbValue lb_handle_param_value(lbProcedure *p, Type *parameter_type, ParameterValue const &param_value, TokenPos const &pos) {
	switch (param_value.kind) {
	case ParameterValue_Constant:
		if (is_type_constant_type(parameter_type)) {
			auto res = lb_const_value(p->module, parameter_type, param_value.value);
			return res;
		} else {
			ExactValue ev = param_value.value;
			lbValue arg = {};
			Type *type = type_of_expr(param_value.original_ast_expr);
			if (type != nullptr) {
				arg = lb_const_value(p->module, type, ev);
			} else {
				arg = lb_const_value(p->module, parameter_type, param_value.value);
			}
			return lb_emit_conv(p, arg, parameter_type);
		}

	case ParameterValue_Nil:
		return lb_const_nil(p->module, parameter_type);
	case ParameterValue_Location:
		{
			String proc_name = {};
			if (p->entity != nullptr) {
				proc_name = p->entity->token.string;
			}
			return lb_emit_source_code_location(p, proc_name, pos);
		}
	case ParameterValue_Value:
		return lb_build_expr(p, param_value.ast_value);
	}
	return lb_const_nil(p->module, parameter_type);
}


lbValue lb_build_call_expr_internal(lbProcedure *p, Ast *expr);

lbValue lb_build_call_expr(lbProcedure *p, Ast *expr) {
	expr = unparen_expr(expr);
	ast_node(ce, CallExpr, expr);

	lbValue res = lb_build_call_expr_internal(p, expr);

	if (ce->optional_ok_one) { // TODO(bill): Minor hack for #optional_ok procedures
		GB_ASSERT(is_type_tuple(res.type));
		GB_ASSERT(res.type->Tuple.variables.count == 2);
		return lb_emit_struct_ev(p, res, 0);
	}
	return res;
}
lbValue lb_build_call_expr_internal(lbProcedure *p, Ast *expr) {
	lbModule *m = p->module;

	TypeAndValue tv = type_and_value_of_expr(expr);

	ast_node(ce, CallExpr, expr);

	TypeAndValue proc_tv = type_and_value_of_expr(ce->proc);
	AddressingMode proc_mode = proc_tv.mode;
	if (proc_mode == Addressing_Type) {
		GB_ASSERT(ce->args.count == 1);
		lbValue x = lb_build_expr(p, ce->args[0]);
		lbValue y = lb_emit_conv(p, x, tv.type);
		return y;
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
		return lb_build_builtin_proc(p, expr, tv, id);
	}

	// NOTE(bill): Regular call
	lbValue value = {};

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
				lbValue x = {};
				x.value = LLVMConstInt(lb_type(m, t_uintptr), u, false);
				x.type = t_uintptr;
				x = lb_emit_conv(p, x, t_rawptr);
				value = lb_emit_conv(p, x, proc_expr->tav.type);
				break;
			}
		case ExactValue_Pointer:
			{
				u64 u = cast(u64)v.value_pointer;
				lbValue x = {};
				x.value = LLVMConstInt(lb_type(m, t_uintptr), u, false);
				x.type = t_uintptr;
				x = lb_emit_conv(p, x, t_rawptr);
				value = lb_emit_conv(p, x, proc_expr->tav.type);
				break;
			}
		}
	}

	if (value.value == nullptr) {
		value = lb_build_expr(p, proc_expr);
	}

	GB_ASSERT(value.value != nullptr);
	Type *proc_type_ = base_type(value.type);
	GB_ASSERT(proc_type_->kind == Type_Proc);
	TypeProc *pt = &proc_type_->Proc;

	if (is_call_expr_field_value(ce)) {
		auto args = array_make<lbValue>(permanent_allocator(), pt->param_count);

		for_array(arg_index, ce->args) {
			Ast *arg = ce->args[arg_index];
			ast_node(fv, FieldValue, arg);
			GB_ASSERT(fv->field->kind == Ast_Ident);
			String name = fv->field->Ident.token.string;
			isize index = lookup_procedure_parameter(pt, name);
			GB_ASSERT(index >= 0);
			TypeAndValue tav = type_and_value_of_expr(fv->value);
			if (tav.mode == Addressing_Type) {
				args[index] = lb_const_nil(m, tav.type);
			} else {
				args[index] = lb_build_expr(p, fv->value);
			}
		}
		TypeTuple *params = &pt->params->Tuple;
		for (isize i = 0; i < args.count; i++) {
			Entity *e = params->variables[i];
			if (e->kind == Entity_TypeName) {
				args[i] = lb_const_nil(m, e->type);
			} else if (e->kind == Entity_Constant) {
				continue;
			} else {
				GB_ASSERT(e->kind == Entity_Variable);
				if (args[i].value == nullptr) {
					args[i] = lb_handle_param_value(p, e->type, e->Variable.param_value, ast_token(expr).pos);
				} else {
					args[i] = lb_emit_conv(p, args[i], e->type);
				}
			}
		}

		for (isize i = 0; i < args.count; i++) {
			Entity *e = params->variables[i];
			if (args[i].type == nullptr) {
				continue;
			} else if (is_type_untyped_nil(args[i].type)) {
				args[i] = lb_const_nil(m, e->type);
			} else if (is_type_untyped_undef(args[i].type)) {
				args[i] = lb_const_undef(m, e->type);
			}
		}

		return lb_emit_call(p, value, args, ce->inlining, p->copy_elision_hint.ast == expr);
	}

	isize arg_index = 0;

	isize arg_count = 0;
	for_array(i, ce->args) {
		Ast *arg = ce->args[i];
		TypeAndValue tav = type_and_value_of_expr(arg);
		GB_ASSERT_MSG(tav.mode != Addressing_Invalid, "%s %s %d", expr_to_string(arg), expr_to_string(expr), tav.mode);
		GB_ASSERT_MSG(tav.mode != Addressing_ProcGroup, "%s", expr_to_string(arg));
		Type *at = tav.type;
		if (at->kind == Type_Tuple) {
			arg_count += at->Tuple.variables.count;
		} else {
			arg_count++;
		}
	}

	isize param_count = 0;
	if (pt->params) {
		GB_ASSERT(pt->params->kind == Type_Tuple);
		param_count = pt->params->Tuple.variables.count;
	}

	auto args = array_make<lbValue>(permanent_allocator(), cast(isize)gb_max(param_count, arg_count));
	isize variadic_index = pt->variadic_index;
	bool variadic = pt->variadic && variadic_index >= 0;
	bool vari_expand = ce->ellipsis.pos.line != 0;
	bool is_c_vararg = pt->c_vararg;

	String proc_name = {};
	if (p->entity != nullptr) {
		proc_name = p->entity->token.string;
	}
	TokenPos pos = ast_token(ce->proc).pos;

	TypeTuple *param_tuple = nullptr;
	if (pt->params) {
		GB_ASSERT(pt->params->kind == Type_Tuple);
		param_tuple = &pt->params->Tuple;
	}

	for_array(i, ce->args) {
		Ast *arg = ce->args[i];
		TypeAndValue arg_tv = type_and_value_of_expr(arg);
		if (arg_tv.mode == Addressing_Type) {
			args[arg_index++] = lb_const_nil(m, arg_tv.type);
		} else {
			lbValue a = lb_build_expr(p, arg);
			Type *at = a.type;
			if (at->kind == Type_Tuple) {
				for_array(i, at->Tuple.variables) {
					lbValue v = lb_emit_struct_ev(p, a, cast(i32)i);
					args[arg_index++] = v;
				}
			} else {
				args[arg_index++] = a;
			}
		}
	}


	if (param_count > 0) {
		GB_ASSERT_MSG(pt->params != nullptr, "%s %td", expr_to_string(expr), pt->param_count);
		GB_ASSERT(param_count < 1000000);

		if (arg_count < param_count) {
			isize end = cast(isize)param_count;
			if (variadic) {
				end = variadic_index;
			}
			while (arg_index < end) {
				Entity *e = param_tuple->variables[arg_index];
				GB_ASSERT(e->kind == Entity_Variable);
				args[arg_index++] = lb_handle_param_value(p, e->type, e->Variable.param_value, ast_token(expr).pos);
			}
		}

		if (is_c_vararg) {
			GB_ASSERT(variadic);
			GB_ASSERT(!vari_expand);
			isize i = 0;
			for (; i < variadic_index; i++) {
				Entity *e = param_tuple->variables[i];
				if (e->kind == Entity_Variable) {
					args[i] = lb_emit_conv(p, args[i], e->type);
				}
			}
			Type *variadic_type = param_tuple->variables[i]->type;
			GB_ASSERT(is_type_slice(variadic_type));
			variadic_type = base_type(variadic_type)->Slice.elem;
			if (!is_type_any(variadic_type)) {
				for (; i < arg_count; i++) {
					args[i] = lb_emit_conv(p, args[i], variadic_type);
				}
			} else {
				for (; i < arg_count; i++) {
					args[i] = lb_emit_conv(p, args[i], default_type(args[i].type));
				}
			}
		} else if (variadic) {
			isize i = 0;
			for (; i < variadic_index; i++) {
				Entity *e = param_tuple->variables[i];
				if (e->kind == Entity_Variable) {
					args[i] = lb_emit_conv(p, args[i], e->type);
				}
			}
			if (!vari_expand) {
				Type *variadic_type = param_tuple->variables[i]->type;
				GB_ASSERT(is_type_slice(variadic_type));
				variadic_type = base_type(variadic_type)->Slice.elem;
				for (; i < arg_count; i++) {
					args[i] = lb_emit_conv(p, args[i], variadic_type);
				}
			}
		} else {
			for (isize i = 0; i < param_count; i++) {
				Entity *e = param_tuple->variables[i];
				if (e->kind == Entity_Variable) {
					if (args[i].value == nullptr) {
						continue;
					}
					GB_ASSERT_MSG(args[i].value != nullptr, "%.*s", LIT(e->token.string));
					args[i] = lb_emit_conv(p, args[i], e->type);
				}
			}
		}

		if (variadic && !vari_expand && !is_c_vararg) {
			// variadic call argument generation
			Type *slice_type = param_tuple->variables[variadic_index]->type;
			Type *elem_type  = base_type(slice_type)->Slice.elem;
			lbAddr slice = lb_add_local_generated(p, slice_type, true);
			isize slice_len = arg_count+1 - (variadic_index+1);

			if (slice_len > 0) {
				lbAddr base_array = lb_add_local_generated(p, alloc_type_array(elem_type, slice_len), true);

				for (isize i = variadic_index, j = 0; i < arg_count; i++, j++) {
					lbValue addr = lb_emit_array_epi(p, base_array.addr, cast(i32)j);
					lb_emit_store(p, addr, args[i]);
				}

				lbValue base_elem = lb_emit_array_epi(p, base_array.addr, 0);
				lbValue len = lb_const_int(m, t_int, slice_len);
				lb_fill_slice(p, slice, base_elem, len);
			}

			arg_count = param_count;
			args[variadic_index] = lb_addr_load(p, slice);
		}
	}

	if (variadic && variadic_index+1 < param_count) {
		for (isize i = variadic_index+1; i < param_count; i++) {
			Entity *e = param_tuple->variables[i];
			args[i] = lb_handle_param_value(p, e->type, e->Variable.param_value, ast_token(expr).pos);
		}
	}

	isize final_count = param_count;
	if (is_c_vararg) {
		final_count = arg_count;
	}

	if (param_tuple != nullptr) {
		for (isize i = 0; i < gb_min(args.count, param_tuple->variables.count); i++) {
			Entity *e = param_tuple->variables[i];
			if (args[i].type == nullptr) {
				continue;
			} else if (is_type_untyped_nil(args[i].type)) {
				args[i] = lb_const_nil(m, e->type);
			} else if (is_type_untyped_undef(args[i].type)) {
				args[i] = lb_const_undef(m, e->type);
			}
		}
	}

	auto call_args = array_slice(args, 0, final_count);
	return lb_emit_call(p, value, call_args, ce->inlining, p->copy_elision_hint.ast == expr);
}

