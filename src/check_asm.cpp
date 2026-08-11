
gb_internal bool is_valid_asm_parameter_type(Type *type) {
	if (is_type_integer(type)) {
		return true;
	}
	if (is_type_float(type)) {
		return true;
	}
	if (is_type_boolean(type)) {
		return true;
	}
	if (is_type_pointer(type) || is_type_multi_pointer(type)) {
		return true;
	}
	if (is_type_simd_vector(type)) {
		return true;
	}
	return false;
}

gb_internal AsmRegClass check_asm_reg_class_from_type(Type *type) {
	if (is_type_integer(type)) {
		return AsmRegClass_Integer;
	}
	if (is_type_float(type)) {
		return AsmRegClass_Float;
	}
	if (is_type_boolean(type)) {
		return AsmRegClass_Integer;
	}
	if (is_type_pointer(type) || is_type_multi_pointer(type)) {
		return AsmRegClass_Integer;
	}
	if (is_type_simd_vector(type)) {
		return AsmRegClass_Vector;
	}
	return AsmRegClass_Unknown;
}

gb_internal Type *check_asm_template_signature_params(CheckerContext *ctx, Scope *scope, Ast *_params, bool input_parameters, Array<AsmTemplateEntityDecl> *asm_template_entity_decls) {
	Type *tuple = alloc_type_tuple();
	if (_params == nullptr) {
		return tuple;
	}
	ast_node(field_list, FieldList, _params);
	Slice<Ast *> params = field_list->list;

	Array<Entity *> variables = {};
	variables.allocator = heap_allocator();

	i32 param_index = 0;
	for (Ast *param : params) {
		ast_node(field, Field, param);

		bool prev = ctx->allow_polymorphic_types;
		ctx->allow_polymorphic_types = false;
		Type *type = check_type(ctx, field->type);
		ctx->allow_polymorphic_types = prev;

		if (!is_valid_asm_parameter_type(type)) {
			gbString s = type_to_string(type);
			error(field->type, "Invalid type for an asm template. It must be an integer, float, boolean, pointer, multi-pointer, or #simd vector, got '%s'", s);
			gb_string_free(s);
			continue;
		}

		for_array(j, field->names) {
			Ast *name = field->names[j];

			bool is_poly_name = false;

			switch (name->kind) {
			case Ast_Ident:
				break;
			case Ast_PolyType:
				GB_ASSERT(name->PolyType.specialization == nullptr);
				is_poly_name = true;
				name = name->PolyType.type;
				break;
			}

			if (!ast_node_expect(name, Ast_Ident)) {
				continue;
			}

			if (is_blank_ident(name)) {
				error(name, "All parameters must have a name in an asm template");
				continue;
			}
			Token name_token = name->Ident.token;

			Entity *entity = alloc_entity_param(scope, name_token, type, false, /*is_value*/true);
			entity->flags |= EntityFlag_Used;
			if (is_poly_name) {
				entity->flags |= EntityFlag_PolyConst;
				if (is_type_internally_pointer_like(type)) {
					error(name, "Parameters with a pointer-like type cannot be used as $ immediates");
				}
			}

			Entity *found = scope_insert(scope, entity);
			if (found == nullptr) {
				array_add(&variables, entity);

				AsmTemplateEntityDecl ed = asm_template_entity_decl_default(entity);
				if (is_poly_name) {
					ed.kind = AsmTemplateEntityDecl_Immediate;
				}
				if (input_parameters) {
					ed.param_group = AsmTemplateEntityDeclParamGroup_Input;
					ed.param_index = param_index++;
					ed.result_index = -1;
				} else {
					ed.param_group = AsmTemplateEntityDeclParamGroup_Output;
					ed.param_index  = -1;
					ed.result_index = param_index++;
				}

				ed.total_index = cast(i32)asm_template_entity_decls->count;
				array_add(asm_template_entity_decls, ed);
			} else {
				TokenPos pos = found->token.pos;
				error(name_token,
				      "Redeclaration of '%.*s' in this scope\n"
				      "\tat %s",
				      LIT(name_token.string), token_pos_to_string(pos));
				entity = found;
			}
		}
	}

	tuple->Tuple.variables = slice_from_array(variables);

	return tuple;
}

gb_internal AsmTemplateEntityDeclParamGroup check_asm_find_group(Entity *entity, Array<AsmTemplateEntityDecl> const &asm_template_entity_decls, i32 *index_) {
	for_array(i, asm_template_entity_decls) {
		auto const &ed = asm_template_entity_decls[i];
		if (ed.entity == entity) {
			if (index_) *index_ = cast(i32)i;
			return ed.param_group;
		}
	}
	if (index_) *index_ = -1;
	return AsmTemplateEntityDeclParamGroup_Unknown;
};

gb_internal AsmTemplateEntityDeclKind check_asm_find_kind(Entity *entity, Array<AsmTemplateEntityDecl> const &asm_template_entity_decls) {
	for (auto const &ed : asm_template_entity_decls) {
		if (ed.entity == entity) {
			return ed.kind;
		}
	}
	return AsmTemplateEntityDecl_Invalid;
};


gb_internal void check_asm_specs(CheckerContext *ctx, Scope *scope, Slice<Ast *> const &specs, Array<AsmTemplateEntityDecl> *asm_template_entity_decls) {
	StringSet pin_set = {};
	string_set_init(&pin_set, specs.count);
	defer (string_set_destroy(&pin_set));

	for (Ast *spec_ : specs) {
		if (spec_->kind != Ast_AsmSpec) {
			continue;
		}
		ast_node(spec, AsmSpec, spec_);

		GB_ASSERT(spec->name->kind == Ast_Ident);

		Entity *input = scope_lookup(scope, spec->name->Ident.interned, spec->name->Ident.hash);

		String pin = {};
		if (spec->value != nullptr) {
			if (spec->value->kind != Ast_AsmRegister) {
				gbString s = expr_to_string(spec->value);
				error(spec->value, "Expected an asm register, got %s", s);
				gb_string_free(s);
				continue;
			}

			ast_node(reg, AsmRegister, spec->value);
			pin = reg->name.string;
			if (pin == "any") {
				pin = {};
			}
			if (pin.len != 0) {
				if (string_set_update(&pin_set, pin)) {
					error(spec->value, "Pinned register %%%.*s has already been assigned", LIT(pin));
				}
			}
		}

		if (spec->tied_name == nullptr) {
			if (spec->type != nullptr) {
				Type *type = check_type(ctx, spec->type);
				if (!is_valid_asm_parameter_type(type)) {
					gbString s = type_to_string(type);
					error(spec->type, "Invalid type for an asm template. It must be an integer, float, boolean, pointer, multi-pointer, or #simd vector, got '%s'", type);
					gb_string_free(s);
					continue;
				}

				Token name_token = spec->name->Ident.token;

				Entity *entity = alloc_entity_param(scope, name_token, type, false, /*is_value*/true);
				entity->flags |= EntityFlag_Used;

				Entity *found = scope_insert(scope, entity);
				if (found == nullptr) {
					AsmTemplateEntityDecl ed = asm_template_entity_decl_default(entity);
					ed.param_group = AsmTemplateEntityDeclParamGroup_Scratch;
					ed.total_index = cast(i32)asm_template_entity_decls->count;
					ed.pin = pin;
					array_add(asm_template_entity_decls, ed);
				} else {
					TokenPos pos = found->token.pos;
					error(name_token,
					      "Redeclaration of '%.*s' in this scope\n"
					      "\tat %s",
					      LIT(name_token.string), token_pos_to_string(pos));
					entity = found;
					continue;
				}
			} else if (input == nullptr) {
				error(spec->name, "Undefined parameter declaration '%.*s'", LIT(spec->name->Ident.token.string));
				continue;
			} else {
				i32 index = -1;
				auto group = check_asm_find_group(input, *asm_template_entity_decls, &index);
				gb_unused(group);
				GB_ASSERT(index >= 0);
				auto *i = &(*asm_template_entity_decls)[index];
				if (i->pin.len == 0) {
					i->pin = pin;
				} else {
					error(spec_, "Asm register has already been pinned");
				}
			}

		} else {
			GB_ASSERT(spec->tied_name->kind == Ast_Ident);

			if (spec->type != nullptr) {
				error(spec->type, "Tied register definitions cannot have a defined type since the values are already defined");
			}

			if (input == nullptr) {
				error(spec->name, "Undefined parameter declaration '%.*s'", LIT(spec->name->Ident.token.string));
				continue;
			}
			Entity *output = scope_lookup(scope, spec->tied_name->Ident.interned, spec->tied_name->Ident.hash);
			if (output == nullptr) {
				error(spec->name, "Undefined parameter declaration '%.*s'", LIT(spec->name->Ident.token.string));
				continue;
			}

			i32 input_index  = -1;
			i32 output_index = -1;

			auto input_group  = check_asm_find_group(input,  *asm_template_entity_decls, &input_index);
			auto output_group = check_asm_find_group(output, *asm_template_entity_decls, &output_index);
			if (input_group != AsmTemplateEntityDeclParamGroup_Input) {
				error(input->token, "Parameter tied with '%.*s' must be an input parameter", LIT(output->token.string));
				continue;
			}
			if (output_group != AsmTemplateEntityDeclParamGroup_Output) {
				error(output->token, "Parameter tied with '%.*s' must be an output parameter", LIT(input->token.string));
				continue;
			}

			GB_ASSERT(input_index >= 0);
			GB_ASSERT(output_index >= 0);

			auto *i = &(*asm_template_entity_decls)[input_index];
			auto *o = &(*asm_template_entity_decls)[output_index];

			i->tie = output_index;
			o->tie = input_index;

			i->pin = pin;
			o->pin = pin;
		}
	}
}

gb_internal bool check_register(AstAsmRegister *asm_reg) {
	String name = asm_reg->name.string;
	auto r = g_asm_amd64.register_lookup(name);
	if (r) {
		return true;
	}
	error(asm_reg->name, "Unknown register for this target platform: %%%.*s", LIT(name));
	return false;
}

enum CheckMnemomicResult {
	CheckMnemomic_Invalid,
	CheckMnemomic_Mnemonic,
	CheckMnemomic_Prefix,
};

gb_internal CheckMnemomicResult check_mnemonic_name(AstAsmInstruction *instr, u16 *mnemonic_) {
	String name = instr->name->Ident.token.string;
	auto m = g_asm_amd64.mnemonic_lookup(name);
	if (m) {
		if (mnemonic_) *mnemonic_ = cast(u16)m;
		return CheckMnemomic_Mnemonic;
	}
	auto p = g_asm_amd64.prefix_lookup(name);
	if (p) {
		if (mnemonic_) *mnemonic_ = cast(u16)p;
		return CheckMnemomic_Prefix;
	}

	ERROR_BLOCK();
	if (instr->operands.count == 0) {
		error(instr->name, "Unknown mnemonic/prefix for this target platform: %.*s", LIT(name));
	} else {
		error(instr->name, "Unknown mnemonic for this target platform: %.*s", LIT(name));

	}
	auto dym = did_you_mean_make(heap_allocator(), g_asm_amd64.MNEMONIC_COUNT, name);
	defer (did_you_mean_destroy(&dym));
	for (u16 i = g_asm_amd64.M_INVALID+1; i < g_asm_amd64.MNEMONIC_COUNT; i++) {
		String str = g_asm_amd64.mnemonic_strings[i];
		did_you_mean_append(&dym, str);
	}
	if (instr->operands.count == 0) {
		for (u16 i = g_asm_amd64.PREFIX_INVALID+1; i < g_asm_amd64.PREFIX_COUNT; i++) {
			String str = g_asm_amd64.prefix_strings[i];
			did_you_mean_append(&dym, str);
		}
	}
	check_did_you_mean_print(&dym);
	return CheckMnemomic_Invalid;
}

gb_internal AsmOperandKind determine_asm_operand_kind(Operand const *operand) {
	if (operand->mode == Addressing_Constant) {
		return AsmOperand_Immediate;
	}
	Ast *expr = operand->expr;
	switch (expr->kind) {
	case_ast_node(label, AsmLabelDecl, expr);
		return AsmOperand_Label;
	case_end;
	case_ast_node(reg, AsmRegister, expr);
		return AsmOperand_Register;
	case_end;
	case_ast_node(reg, AsmMemoryOperand, expr);
		return AsmOperand_Memory;
	case_end;
	case_ast_node(ident, Ident, expr);
		// TODO(bill): Is this correct?
		if (expr->tav.mode == Addressing_Constant) {
			return AsmOperand_Immediate;
		}
		Entity *e = entity_of_node(expr);
		if (e != nullptr && e->kind == Entity_Variable && (e->flags & EntityFlag_PolyConst) != 0) {
			return AsmOperand_Immediate;
		}
		return AsmOperand_Register;
	case_end;
	}
	return AsmOperand_Invalid;
}


gb_internal void check_mnemonic(CheckerContext *ctx, AstAsmInstruction *instr, u16 mnemonic, Slice<Operand> const &operands, u8 previous_prefix) {
	GB_ASSERT(mnemonic > 0);
	auto forms = g_asm_amd64.encoding_forms(mnemonic);
	String name = g_asm_amd64.mnemonic_strings[mnemonic];

	int min_count = I32_MAX;
	int max_count = -1;

	for (auto form : forms) {
		int explicit_count = cast(int)form.explicit_count();
		min_count = gb_min(min_count, explicit_count);
		max_count = gb_max(max_count, explicit_count);
	}
	min_count = gb_max(min_count, 0);
	max_count = gb_max(max_count, 0);


	auto valid_spots = slice_make<bool>(heap_allocator(), max_count);
	defer (slice_free(&valid_spots, heap_allocator()));

	auto possible_kinds = slice_make<AsmOperandKind>(heap_allocator(), max_count);
	defer (slice_free(&possible_kinds, heap_allocator()));

	bool matched = false;
	isize valid_form_index = -1;
	isize best_form = -1;
	int   best_score = -1;

	for_array(form_index, forms) {
		auto &form = forms[form_index];
		if (operands.count != cast(int)form.explicit_count()) {
			continue;
		}

		int score = 0;
		for_array(i, operands) {
			auto type = form.ops[i];
			Operand const *operand = &operands[i];
			AsmOperandKind dst = g_asm_amd64.kind_from_operand_type(type);
			AsmOperandKind src = determine_asm_operand_kind(operand);

			bool spot_ok = (dst == src) ||
			               (dst == AsmOperand_Register_Or_Memory && (src == AsmOperand_Register || src == AsmOperand_Memory));

			if (spot_ok) {
				score += 1;
				valid_spots[i] = true;
			}
		}
		if (score == operands.count) {
			// the result has been found to be correct
			matched = true;
			valid_form_index = form_index;
			break;
		}
		if (score > best_score) {
			best_score = score;
			best_form = form_index;
		}
	}

	if (operands.count < min_count || operands.count > max_count) {
		if (min_count == max_count) {
			error(instr->name, "The asm instruction '%.*s' expects %d operands, got %td", LIT(name), max_count, operands.count);
		} else {
			error(instr->name, "The asm instruction '%.*s' expects %d..=%d operands, got %td", LIT(name), min_count, max_count, operands.count);
		}
		return;
	}
	if (matched) {
		if (valid_form_index >= 0 && previous_prefix > 0) {
			// TODO(bill): validate the prefix for the selected form
		}

		return;
	}

	// failure path
	if (best_form >= 0) {
		auto &form = forms[best_form];
		for_array(i, operands) {
			AsmOperandKind dst = g_asm_amd64.kind_from_operand_type(form.ops[i]);
			AsmOperandKind src = determine_asm_operand_kind(&operands[i]);
			possible_kinds[i] = dst;
			valid_spots[i] = (dst == src) ||
			                 (dst == AsmOperand_Register_Or_Memory && (src == AsmOperand_Register || src == AsmOperand_Memory));
		}
	}

	{
		error(instr->name, "The operands to '%.*s' matched none of the expected encoding forms", LIT(name));
		for_array(i, valid_spots) {
			if (!valid_spots[i] && i < operands.count) {
				auto kind = possible_kinds[i];
				if (kind) {
					error(operands[i].expr, "Invalid operand kind for the asm instruction '%.*s', expected %.*s operand", LIT(name), LIT(asm_operand_kind_expected_strings[kind]));
				} else {
					error(operands[i].expr, "Invalid operand kind for the asm instruction '%.*s'", LIT(name));
				}
			}
		}
	}
}



gb_internal void check_asm_instruction_operand(CheckerContext *ctx, Entity *entity, Operand *operand, Ast *expr, bool allow_memory_operands) {
	if (expr == nullptr) {
		return;
	}

	operand->expr = expr;
	operand->mode = Addressing_Invalid;
	operand->type = t_invalid;

	GB_ASSERT(entity->kind == Entity_AsmTemplate);
	auto *ate = &entity->AsmTemplate;

	Scope *param_scope = ate->param_scope;
	Scope *label_scope = ate->label_scope;
	gb_unused(param_scope);
	gb_unused(label_scope);

	switch (expr->kind) {
	case_ast_node(i, Ident, expr);
		Entity *found = scope_lookup(param_scope, i->interned, i->hash);
		if (found == nullptr) {
			error(expr, "Undeclared asm parameter '%.*s'", LIT(i->token.string));
			return;
		}
		i->entity = found;
		operand->mode = Addressing_Value;
		operand->type = found->type;
		return;
	case_end;
	case_ast_node(bl, BasicLit, expr);
		check_expr(ctx, operand, expr);
		return;
	case_end;
	case_ast_node(asm_reg, AsmRegister, expr);
		check_register(asm_reg);
		return;
	case_end;
	case_ast_node(mem_op, AsmMemoryOperand, expr);
		if (!allow_memory_operands) {
			break;
		}
		Operand base  = {};
		Operand index = {};
		Operand scale = {};
		Operand disp  = {};
		check_asm_instruction_operand(ctx, entity, &base,  mem_op->base,  false);
		check_asm_instruction_operand(ctx, entity, &index, mem_op->index, false);
		check_asm_instruction_operand(ctx, entity, &scale, mem_op->scale, false);
		check_asm_instruction_operand(ctx, entity, &disp,  mem_op->disp,  false);

		for (int i = 0; base.expr && i == 0; i++) {
			if (base.expr->kind == Ast_AsmRegister) {
				check_register(&base.expr->AsmRegister);
			} else {
				Entity *param_entity = entity_of_node(base.expr);
				if (param_entity == nullptr || param_entity->kind != Entity_Variable) {
					gbString s = expr_to_string(base.expr);
					error(base.expr, "A base value must be a memory parameter, got %s", s);
					gb_string_free(s);
					break;
				}
				auto kind = check_asm_find_kind(param_entity, ate->decls);
				if (kind != AsmTemplateEntityDecl_Memory) {
					gbString s = expr_to_string(base.expr);
					error(base.expr, "A base value must be a memory parameter, got %s", s);
					gb_string_free(s);
					break;
				}
			}
		}

		for (int i = 0; index.expr && i == 0; i++) {
			if (index.expr->kind == Ast_AsmRegister) {
				check_register(&index.expr->AsmRegister);
			} else {
				Entity *param_entity = entity_of_node(index.expr);
				if (param_entity == nullptr || param_entity->kind != Entity_Variable) {
					gbString s = expr_to_string(index.expr);
					error(index.expr, "An index value must an integer, got %s", s);
					gb_string_free(s);
					break;
				}
				auto kind = check_asm_find_kind(param_entity, ate->decls);
				switch (kind) {
				case AsmTemplateEntityDecl_Register:
				case AsmTemplateEntityDecl_Immediate:
					// okay:
					break;
				default:
					{
						gbString s = expr_to_string(index.expr);
						error(index.expr, "An index must be an integer value, got %s", s);
						gb_string_free(s);
					}
					break;
				}
			}
		}

		for (int i = 0; scale.expr && i == 0; i++) {
			if (!is_type_integer(scale.type)) {
				gbString s = expr_to_string(scale.expr);
				error(scale.expr, "A scale must be a constant integer or an immediate, got %s", s);
				gb_string_free(s);
				break;
			}
			if (scale.mode == Addressing_Constant) {
				if (scale.value.kind != ExactValue_Integer) {
					gbString s = exact_value_to_string(scale.value);
					error(scale.expr, "A scale must be a constant integer or an immediate, got %s", s);
					gb_string_free(s);
					break;
				}
			} else {
				Entity *param_entity = entity_of_node(scale.expr);
				if (param_entity == nullptr || param_entity->kind != Entity_Variable) {
					gbString s = expr_to_string(scale.expr);
					error(scale.expr, "A scale must be a constant integer or an immediate, got %s", s);
					gb_string_free(s);
					break;
				}
				auto kind = check_asm_find_kind(param_entity, ate->decls);
				if (kind != AsmTemplateEntityDecl_Immediate) {
					gbString s = expr_to_string(scale.expr);
					error(scale.expr, "A scale must be a constant integer or an immediate, got %s", s);
					gb_string_free(s);
					break;
				}
			}
		}

		for (int i = 0; disp.expr && i == 0; i++) {
			if (disp.expr->kind == Ast_AsmRegister) {
				check_register(&disp.expr->AsmRegister);
			} else {
				Entity *param_entity = entity_of_node(disp.expr);
				if (disp.mode == Addressing_Constant) {
					if (is_type_integer(disp.type)) {
						break;
					}
				}
				if (param_entity == nullptr) {
					gbString s = expr_to_string(disp.expr);
					error(disp.expr, "An displacement value must an integer, got %s", s);
					gb_string_free(s);
					break;
				}
				auto kind = check_asm_find_kind(param_entity, ate->decls);
				switch (kind) {
				case AsmTemplateEntityDecl_Register:
				case AsmTemplateEntityDecl_Immediate:
					if (is_type_integer(disp.type)) {
						break;
					}
					/*fallthrough*/
				default:
					{
						gbString s = expr_to_string(disp.expr);
						gbString t = type_to_string(disp.type);
						error(disp.expr, "An displacement must be an integer value, got %s of type %s", s, t);
						gb_string_free(t);
						gb_string_free(s);
					}
					break;
				}
			}
		}

		return;
	case_end;
	case_ast_node(label, AsmLabelDecl, expr);
		ast_node(name, Ident, label->name);
		Entity *found = scope_lookup(label_scope, name->interned, name->hash);
		if (found == nullptr) {
			error(expr, "Undeclared asm label '.%.*s'", LIT(name->token.string));
		}
		name->entity = found;
		return;
	case_end;
	}

	{
		gbString s = expr_to_string(expr);
		error(expr, "Invalid asm operand, got %s", s);
		gb_string_free(s);
	}
	return;
}


gb_internal void check_asm_template(CheckerContext *ctx, Entity *entity, DeclInfo *d) {
	GB_ASSERT(entity->kind == Entity_AsmTemplate);
	auto *ate = &entity->AsmTemplate;

	String asm_template_name = entity->token.string;
	gb_unused(asm_template_name);

	ast_node(at, AsmTemplate, d->init_expr);

	GB_ASSERT(at->signature != nullptr);
	if (at->signature->kind != Ast_ProcType) {
		error(at->signature, "Expected a valid signature, got %.*s", LIT(ast_strings[at->signature->kind]));
		return;
	}
	AstProcType *pt = &at->signature->ProcType;

	ate->param_scope = create_scope(nullptr, nullptr);
	ate->label_scope = create_scope(nullptr, nullptr);

	ate->decls.allocator = heap_allocator();

	Type *params  = check_asm_template_signature_params(ctx, ate->param_scope, pt->params,  true,  &ate->decls);
	Type *results = check_asm_template_signature_params(ctx, ate->param_scope, pt->results, false, &ate->decls);

	Type *type = alloc_type_proc(ate->param_scope, params, params->Tuple.variables.count, results, results->Tuple.variables.count, false, pt->calling_convention);
	type->Proc.diverging = pt->diverging;

	entity->type = type;

	check_asm_specs(ctx, ate->param_scope, at->specs, &ate->decls);
	{ // check clobbers
		StringSet reg_set = {};
		string_set_init(&reg_set, 16);
		defer (string_set_destroy(&reg_set));

		bool clobber_cc     = false;
		bool clobber_memory = false;

		for (Ast *clobber_ : at->clobbers) {
			ast_node(clobber, AsmClobber, clobber_);
			switch (clobber->value->kind) {
			case_ast_node(asm_reg, AsmRegister, clobber->value)
				String reg = asm_reg->name.string;
				if (check_register(asm_reg)) {
					if (string_set_update(&reg_set, reg)) {
						error(clobber->value, "#clobber %%%.*s has already been defined", LIT(reg));
					}
				}
			case_end;
			case_ast_node(ident, Ident, clobber->value);
				String str = ident->token.string;
				if (str == "cc") {
					if (clobber_cc) {
						error(clobber->value, "#clobber cc has already been defined");
					}
					clobber_cc = true;
				} else if (str == "memory") {
					if (clobber_memory) {
						error(clobber->value, "#clobber memory has already been defined");
					}
					clobber_memory = true;
				} else {
					error(clobber->value, "Expected either a register, 'cc', or 'memory' for a '#clobber' specification, got '%.*s'", LIT(str));
				}
			case_end;
			default:
				error(clobber->value, "Expected either a register, 'cc', or 'memory' for a '#clobber' specification");
				break;
			}
		}
	}

	// collect label decls
	for (Ast *instruction_ : at->instructions) {
		switch (instruction_->kind) {
		case_ast_node(label, AsmLabelDecl, instruction_);
			GB_ASSERT(label->name->kind == Ast_Ident);
			Ast *name = label->name;
			if (is_blank_ident(name)) {
				error(name, "Asm label definition cannot be '_'");
				continue;
			}
			Entity *label_entity = alloc_entity_label(ate->label_scope, name->Ident.token, nullptr, instruction_, nullptr);
			Entity *found = scope_insert(ate->label_scope, label_entity);
			if (found != nullptr) {
				TokenPos pos = found->token.pos;
				error(name,
				      "Redeclaration of the label '%.*s' in this scope\n"
				      "\tat %s",
				      LIT(name->Ident.token.string), token_pos_to_string(pos));
				continue;
			}
			name->Ident.entity = label_entity;
		case_end;
		}
	}


	Array<Operand> operands = {};
	operands.allocator = heap_allocator();
	array_reserve(&operands, 16);
	defer (array_free(&operands));

	for (Ast *instruction_ : at->instructions) {
		u8 previous_prefix = 0;

		switch (instruction_->kind) {
		case_ast_node(instr, AsmInstruction, instruction_);
			GB_ASSERT(instr->name->kind == Ast_Ident);

			u16 mnemonic = 0;
			CheckMnemomicResult res = check_mnemonic_name(instr, &mnemonic);


			array_clear(&operands);

			for (Ast *expr : instr->operands) {
				Operand operand = {};
				check_asm_instruction_operand(ctx, entity, &operand, expr, /*allow_memory_operands*/true);
				array_add(&operands, operand);
			}
			if (res == CheckMnemomic_Prefix) {
				if (instr->operands.count != 0) {
					error(instr->name, "A prefix must not have any operands, and be separate from the instruction it is prefixing");
				}
				previous_prefix = cast(u8)mnemonic;
			} else if (res == CheckMnemomic_Mnemonic) {
				check_mnemonic(ctx, instr, mnemonic, slice_from_array(operands), previous_prefix);
			}

		case_end;
		case_ast_node(label, AsmLabelDecl, instruction_);
			// already done
		case_end;
		default:
			error(instruction_, "Unexpected instruction in asm template");
			break;
		}
	}
}