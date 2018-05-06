enum CallArgumentError {
	CallArgumentError_None,
	CallArgumentError_NoneProcedureType,
	CallArgumentError_WrongTypes,
	CallArgumentError_NonVariadicExpand,
	CallArgumentError_VariadicTuple,
	CallArgumentError_MultipleVariadicExpand,
	CallArgumentError_ArgumentCount,
	CallArgumentError_TooFewArguments,
	CallArgumentError_TooManyArguments,
	CallArgumentError_InvalidFieldValue,
	CallArgumentError_ParameterNotFound,
	CallArgumentError_ParameterMissing,
	CallArgumentError_DuplicateParameter,
	CallArgumentError_NoneConstantParameter,
};

enum CallArgumentErrorMode {
	CallArgumentMode_NoErrors,
	CallArgumentMode_ShowErrors,
};

struct CallArgumentData {
	Entity *gen_entity;
	i64     score;
	Type *  result_type;
};

struct PolyProcData {
	Entity *      gen_entity;
	ProcedureInfo proc_info;
};

struct ValidIndexAndScore {
	isize index;
	i64   score;
};

int valid_index_and_score_cmp(void const *a, void const *b) {
	i64 si = (cast(ValidIndexAndScore const *)a)->score;
	i64 sj = (cast(ValidIndexAndScore const *)b)->score;
	return sj < si ? -1 : sj > si;
}




#define CALL_ARGUMENT_CHECKER(name) CallArgumentError name(Checker *c, AstNode *call, Type *proc_type, Entity *entity, Array<Operand> operands, CallArgumentErrorMode show_error_mode, CallArgumentData *data)
typedef CALL_ARGUMENT_CHECKER(CallArgumentCheckerType);



void     check_expr                     (Checker *c, Operand *operand, AstNode *expression);
void     check_multi_expr               (Checker *c, Operand *operand, AstNode *expression);
void     check_expr_or_type             (Checker *c, Operand *operand, AstNode *expression, Type *type_hint = nullptr);
ExprKind check_expr_base                (Checker *c, Operand *operand, AstNode *expression, Type *type_hint);
void     check_expr_with_type_hint      (Checker *c, Operand *o, AstNode *e, Type *t);
Type *   check_type                     (Checker *c, AstNode *expression);
Type *   check_type_expr                (Checker *c, AstNode *expression, Type *named_type);
Type *   make_optional_ok_type          (Type *value);
void     check_type_decl                (Checker *c, Entity *e, AstNode *type_expr, Type *def);
Entity * check_selector                 (Checker *c, Operand *operand, AstNode *node, Type *type_hint);
Entity * check_ident                    (Checker *c, Operand *o, AstNode *n, Type *named_type, Type *type_hint, bool allow_import_name);
Entity * find_polymorphic_struct_entity (Checker *c, Type *original_type, isize param_count, Array<Operand> ordered_operands);
void     check_not_tuple                (Checker *c, Operand *operand);
void     convert_to_typed               (Checker *c, Operand *operand, Type *target_type);
gbString expr_to_string                 (AstNode *expression);
void     check_entity_decl              (Checker *c, Entity *e, DeclInfo *decl, Type *named_type);
void     check_const_decl               (Checker *c, Entity *e, AstNode *type_expr, AstNode *init_expr, Type *named_type);
void     check_proc_body                (Checker *c, Token token, DeclInfo *decl, Type *type, AstNode *body);
void     update_expr_type               (Checker *c, AstNode *e, Type *type, bool final);
bool     check_is_terminating           (AstNode *node);
bool     check_has_break                (AstNode *stmt, bool implicit);
void     check_stmt                     (Checker *c, AstNode *node, u32 flags);
void     check_stmt_list                (Checker *c, Array<AstNode *> stmts, u32 flags);
void     check_init_constant            (Checker *c, Entity *e, Operand *operand);
bool     check_representable_as_constant(Checker *c, ExactValue in_value, Type *type, ExactValue *out_value);
bool     check_procedure_type           (Checker *c, Type *type, AstNode *proc_type_node, Array<Operand> *operands = nullptr);
void     check_struct_type              (Checker *c, Type *struct_type, AstNode *node, Array<Operand> *poly_operands,
                                         Type *named_type = nullptr, Type *original_type_for_poly = nullptr);
CallArgumentData check_call_arguments   (Checker *c, Operand *operand, Type *proc_type, AstNode *call);
Type *           check_init_variable    (Checker *c, Entity *e, Operand *operand, String context_name);



void error_operand_not_expression(Operand *o) {
	if (o->mode == Addressing_Type) {
		gbString err = expr_to_string(o->expr);
		error(o->expr, "'%s' is not an expression but a type", err);
		gb_string_free(err);
		o->mode = Addressing_Invalid;
	}
}

void error_operand_no_value(Operand *o) {
	if (o->mode == Addressing_NoValue) {
		gbString err = expr_to_string(o->expr);
		AstNode *x = unparen_expr(o->expr);
		if (x->kind == AstNode_CallExpr) {
			error(o->expr, "'%s' call does not return a value and cannot be used as a value", err);
		} else {
			error(o->expr, "'%s' used as a value", err);
		}
		gb_string_free(err);
		o->mode = Addressing_Invalid;
	}
}


void check_scope_decls(Checker *c, Array<AstNode *> nodes, isize reserve_size) {
	Scope *s = c->context.scope;
	GB_ASSERT(s->file == nullptr);

	check_collect_entities(c, nodes);

	for_array(i, s->elements.entries) {
		Entity *e = s->elements.entries[i].value;
		switch (e->kind) {
		case Entity_Constant:
		case Entity_TypeName:
		case Entity_Procedure:
			break;
		default:
			continue;
		}
		DeclInfo *d = decl_info_of_entity(&c->info, e);
		if (d != nullptr) {
			check_entity_decl(c, e, d, nullptr);
		}
	}
}


bool check_is_assignable_to_using_subtype(Type *src, Type *dst) {
	bool src_is_ptr = false;
	Type *prev_src = src;
	src = type_deref(src);
	src_is_ptr = src != prev_src;
	src = base_type(src);

	if (!is_type_struct(src)) {
		return false;
	}

	for_array(i, src->Struct.fields) {
		Entity *f = src->Struct.fields[i];
		if (f->kind != Entity_Variable || (f->flags&EntityFlag_Using) == 0) {
			continue;
		}

		if (are_types_identical(f->type, dst)) {
			return true;
		}
		if (src_is_ptr && is_type_pointer(dst)) {
			if (are_types_identical(f->type, type_deref(dst))) {
				return true;
			}
		}
		bool ok = check_is_assignable_to_using_subtype(f->type, dst);
		if (ok) {
			return true;
		}
	}

	return false;
}

bool find_or_generate_polymorphic_procedure(Checker *c, Entity *base_entity, Type *type,
                                            Array<Operand> *param_operands, PolyProcData *poly_proc_data) {
	///////////////////////////////////////////////////////////////////////////////
	//                                                                           //
	// TODO CLEANUP(bill): This procedure is very messy and hacky. Clean this!!! //
	//                                                                           //
	///////////////////////////////////////////////////////////////////////////////


	if (base_entity == nullptr) {
		return false;
	}

	if (!is_type_proc(base_entity->type)) {
		return false;
	}
	String name = base_entity->token.string;

	Type *src = base_type(base_entity->type);
	Type *dst = nullptr;
	if (type != nullptr) dst = base_type(type);

	if (param_operands == nullptr) {
		GB_ASSERT(dst != nullptr);
	}
	if (param_operands != nullptr) {
		GB_ASSERT(dst == nullptr);
	}


	if (!src->Proc.is_polymorphic || src->Proc.is_poly_specialized) {
		return false;
	}

	if (dst != nullptr) {
		if (dst->Proc.is_polymorphic) {
			return false;
		}

		if (dst->Proc.param_count  != src->Proc.param_count ||
		    dst->Proc.result_count != src->Proc.result_count) {
		    return false;
		}
	}


	DeclInfo *old_decl = decl_info_of_entity(&c->info, base_entity);
	if (old_decl == nullptr) {
		return false;
	}



	gbAllocator a = heap_allocator();

	Array<Operand> operands = {};
	if (param_operands) {
		operands = *param_operands;
	} else {
		operands = array_make<Operand>(a, 0, dst->Proc.param_count);
		for (isize i = 0; i < dst->Proc.param_count; i++) {
			Entity *param = dst->Proc.params->Tuple.variables[i];
			Operand o = {Addressing_Value};
			o.type = param->type;
			array_add(&operands, o);
		}
	}

	defer (if (param_operands == nullptr) {
		array_free(&operands);
	});



	CheckerContext prev_context = c->context;
	defer (c->context = prev_context);

	Scope *scope = create_scope(base_entity->scope, a);
	scope->is_proc = true;
	c->context.scope = scope;
	c->context.allow_polymorphic_types = true;
	if (c->context.polymorphic_scope == nullptr) {
		c->context.polymorphic_scope = scope;
	}
	if (param_operands == nullptr) {
		// c->context.no_polymorphic_errors = false;
	}


	bool generate_type_again = c->context.no_polymorphic_errors;

	auto *pt = &src->Proc;

	// NOTE(bill): This is slightly memory leaking if the type already exists
	// Maybe it's better to check with the previous types first?
	Type *final_proc_type = alloc_type_proc(scope, nullptr, 0, nullptr, 0, false, pt->calling_convention);
	bool success = check_procedure_type(c, final_proc_type, pt->node, &operands);

	if (!success) {
		return false;
	}


	gb_mutex_lock(&c->mutex);
	defer (gb_mutex_unlock(&c->mutex));

	auto *found_gen_procs = map_get(&c->info.gen_procs, hash_pointer(base_entity->identifier));
	if (found_gen_procs) {
		auto procs = *found_gen_procs;
		for_array(i, procs) {
			Entity *other = procs[i];
			Type *pt = base_type(other->type);
			if (are_types_identical(pt, final_proc_type)) {
				if (poly_proc_data) {
					poly_proc_data->gen_entity = other;
				}
				return true;
			}
		}
	}


	if (generate_type_again) {
		// LEAK TODO(bill): This is technically a memory leak as it has to generate the type twice
		bool prev_no_polymorphic_errors = c->context.no_polymorphic_errors;
		defer (c->context.no_polymorphic_errors = prev_no_polymorphic_errors);
		c->context.no_polymorphic_errors = false;

		// NOTE(bill): Reset scope from the failed procedure type
		scope_reset(scope);

		success = check_procedure_type(c, final_proc_type, pt->node, &operands);

		if (!success) {
			return false;
		}


		if (found_gen_procs) {
			auto procs = *found_gen_procs;
			for_array(i, procs) {
				Entity *other = procs[i];
				Type *pt = base_type(other->type);
				if (are_types_identical(pt, final_proc_type)) {
					if (poly_proc_data) {
						poly_proc_data->gen_entity = other;
					}
					return true;
				}
			}
		}
	}


	AstNode *proc_lit = clone_ast_node(a, old_decl->proc_lit);
	ast_node(pl, ProcLit, proc_lit);
	// NOTE(bill): Associate the scope declared above withinth this procedure declaration's type
	add_scope(c, pl->type, final_proc_type->Proc.scope);
	final_proc_type->Proc.is_poly_specialized = true;
	final_proc_type->Proc.is_polymorphic = true;

	u64 tags = base_entity->Procedure.tags;
	AstNode *ident = clone_ast_node(a, base_entity->identifier);
	Token token = ident->Ident.token;
	DeclInfo *d = make_declaration_info(c->allocator, scope, old_decl->parent);
	d->gen_proc_type = final_proc_type;
	d->type_expr = pl->type;
	d->proc_lit = proc_lit;


	Entity *entity = alloc_entity_procedure(nullptr, token, final_proc_type, tags);
	entity->identifier = ident;

	add_entity_and_decl_info(c, ident, entity, d);
	// NOTE(bill): Set the scope afterwards as this is not real overloading
	entity->scope = scope->parent;

	AstFile *file = nullptr;
	{
		Scope *s = entity->scope;
		while (s != nullptr && s->file == nullptr) {
			s = s->parent;
		}
		file = s->file;
	}

	ProcedureInfo proc_info = {};
	proc_info.file  = file;
	proc_info.token = token;
	proc_info.decl  = d;
	proc_info.type  = final_proc_type;
	proc_info.body  = pl->body;
	proc_info.tags  = tags;
	proc_info.generated_from_polymorphic = true;

	if (found_gen_procs) {
		array_add(found_gen_procs, entity);
	} else {
		auto array = array_make<Entity *>(heap_allocator());
		array_add(&array, entity);
		map_set(&c->info.gen_procs, hash_pointer(base_entity->identifier), array);
	}

	GB_ASSERT(entity != nullptr);

	if (poly_proc_data) {
		poly_proc_data->gen_entity = entity;
		poly_proc_data->proc_info  = proc_info;
	}

	// NOTE(bill): Check the newly generated procedure body
	check_procedure_later(c, proc_info);

	return true;
}

bool check_polymorphic_procedure_assignment(Checker *c, Operand *operand, Type *type, PolyProcData *poly_proc_data) {
	if (operand->expr == nullptr) return false;
	Entity *base_entity = entity_of_ident(&c->info, operand->expr);
	if (base_entity == nullptr) return false;
	return find_or_generate_polymorphic_procedure(c, base_entity, type, nullptr, poly_proc_data);
}

bool find_or_generate_polymorphic_procedure_from_parameters(Checker *c, Entity *base_entity, Array<Operand> *operands, PolyProcData *poly_proc_data) {
	return find_or_generate_polymorphic_procedure(c, base_entity, nullptr, operands, poly_proc_data);
}

bool check_type_specialization_to(Checker *c, Type *specialization, Type *type, bool compound, bool modify_type);
bool is_polymorphic_type_assignable(Checker *c, Type *poly, Type *source, bool compound, bool modify_type);
bool check_cast_internal(Checker *c, Operand *x, Type *type);

i64 check_distance_between_types(Checker *c, Operand *operand, Type *type) {
	if (operand->mode == Addressing_Invalid ||
	    type == t_invalid) {
		return -1;
	}

	if (operand->mode == Addressing_Builtin) {
		return -1;
	}

	if (operand->mode == Addressing_Type) {
		return -1;
	}

	Type *s = operand->type;

	if (are_types_identical(s, type)) {
		return 0;
	}

	Type *src = base_type(s);
	Type *dst = base_type(type);

	if (is_type_untyped_undef(src)) {
		if (type_has_undef(dst)) {
			return 1;
		}
		return -1;
	}

	if (is_type_untyped_nil(src)) {
		if (type_has_nil(dst)) {
			return 1;
		}
		return -1;
	}
	if (is_type_untyped(src)) {
		if (is_type_any(dst)) {
			// NOTE(bill): Anything can cast to 'Any'
			add_type_info_type(c, s);
			return 10;
		}
		if (dst->kind == Type_Basic) {
			if (operand->mode == Addressing_Constant) {
				if (check_representable_as_constant(c, operand->value, dst, nullptr)) {
					if (is_type_typed(dst) && src->kind == Type_Basic) {
						switch (src->Basic.kind) {
						case Basic_UntypedRune:
							if (is_type_integer(dst) || is_type_rune(dst)) {
								return 1;
							}
							break;
						case Basic_UntypedInteger:
							if (is_type_integer(dst) || is_type_rune(dst)) {
								return 1;
							}
							break;
						case Basic_UntypedFloat:
							if (is_type_float(dst)) {
								return 1;
							}
							break;
						case Basic_UntypedComplex:
							if (is_type_complex(dst)) {
								return 1;
							}
							break;
						}
					}
					return 2;
				}
				return -1;
			}
			if (src->kind == Type_Basic && src->Basic.kind == Basic_UntypedRune) {
				if (is_type_integer(dst) || is_type_rune(dst)) {
					if (is_type_typed(type)) {
						return 2;
					}
					return 1;
				}
				return -1;
			}
			if (src->kind == Type_Basic && src->Basic.kind == Basic_UntypedBool) {
				if (is_type_boolean(dst)) {
					if (is_type_typed(type)) {
						return 2;
					}
					return 1;
				}
				return -1;
			}
		}
	}

#if 0
	if (are_types_identical(dst, src) && (!is_type_named(dst) || !is_type_named(src))) {
		return 1;
	}
#endif

	if (is_type_bit_field_value(operand->type) && is_type_integer(type)) {
		Type *bfv = base_type(operand->type);
		i32 bits = bfv->BitFieldValue.bits;
		i32 size = next_pow2((bits+7)/8);
		i32 dst_size = cast(i32)type_size_of(type);
		i32 diff = gb_abs(dst_size - size);
		// TODO(bill): figure out a decent rule here
		return 1;
	}


	if (check_is_assignable_to_using_subtype(operand->type, type)) {
		return 4;
	}

	// ^T <- rawptr
#if 0
	// TODO(bill): Should C-style (not C++) pointer cast be allowed?
	if (is_type_pointer(dst) && is_type_rawptr(src)) {
	    return true;
	}
#endif
#if 1


	// TODO(bill): Should I allow this implicit conversion at all?!
	// rawptr <- ^T
	if (are_types_identical(type, t_rawptr) && is_type_pointer(src)) {
	    return 5;
	}
#endif

	if (is_type_polymorphic(dst) && !is_type_polymorphic(src)) {
		bool modify_type = !c->context.no_polymorphic_errors;
		if (is_polymorphic_type_assignable(c, type, s, false, modify_type)) {
			return 2;
		}
	}

	if (is_type_union(dst)) {
		for_array(i, dst->Union.variants) {
			Type *vt = dst->Union.variants[i];
			if (are_types_identical(vt, s)) {
				return 1;
			}
		}
	}

	if (is_type_proc(dst)) {
		if (are_types_identical(src, dst)) {
			return 3;
		}
		PolyProcData poly_proc_data = {};
		if (check_polymorphic_procedure_assignment(c, operand, type, &poly_proc_data)) {
			add_entity_use(c, operand->expr, poly_proc_data.gen_entity);
			return 4;
		}
	}

	if (is_type_array(dst)) {
		Type *elem = base_array_type(dst);
		i64 distance = check_distance_between_types(c, operand, elem);
		if (distance >= 0) {
			return distance + 6;
		}
	}

	if (is_type_any(dst)) {
		if (!is_type_polymorphic(src)) {
			if (operand->mode == Addressing_Immutable && operand->type == t_context) {
				return -1;
			} else {
				// NOTE(bill): Anything can cast to 'Any'
				add_type_info_type(c, s);
				return 10;
			}
		}
	}

	AstNode *expr = unparen_expr(operand->expr);
	if (expr != nullptr && expr->kind == AstNode_AutoCast) {
		Operand x = *operand;
		x.expr = expr->AutoCast.expr;
		bool ok = check_cast_internal(c, &x, type);
		if (ok) {
			return 10;
		}
	}

	return -1;
}


i64 assign_score_function(i64 distance) {
	// TODO(bill): A decent score function
	return gb_max(1000000 - distance*distance, 0);
}


bool check_is_assignable_to_with_score(Checker *c, Operand *operand, Type *type, i64 *score_) {
	i64 score = 0;
	i64 distance = check_distance_between_types(c, operand, type);
	bool ok = distance >= 0;
	if (ok) {
		score = assign_score_function(distance);
	}
	if (score_) *score_ = score;
	return ok;
}


bool check_is_assignable_to(Checker *c, Operand *operand, Type *type) {
	i64 score = 0;
	return check_is_assignable_to_with_score(c, operand, type, &score);
}


// NOTE(bill): 'content_name' is for debugging and error messages
void check_assignment(Checker *c, Operand *operand, Type *type, String context_name) {
	check_not_tuple(c, operand);
	if (operand->mode == Addressing_Invalid) {
		return;
	}

	#if 0
	if (operand->mode == Addressing_Type) {
		Type *t = base_type(type);
		if (t->kind == Type_Pointer &&
		    t->Pointer.elem == t_type_info) {
			add_type_info_type(c, type);
			return;
		}
	}
	#endif

	if (is_type_untyped(operand->type)) {
		Type *target_type = type;
		if (type == nullptr || is_type_any(type)) {
			if (type == nullptr && is_type_untyped_nil(operand->type)) {
				error(operand->expr, "Use of untyped nil in %.*s", LIT(context_name));
				operand->mode = Addressing_Invalid;
				return;
			}
			if (type == nullptr && is_type_untyped_undef(operand->type)) {
				error(operand->expr, "Use of --- in %.*s", LIT(context_name));
				operand->mode = Addressing_Invalid;
				return;
			}
			target_type = default_type(operand->type);
			if (type != nullptr && !is_type_any(type)) {
				GB_ASSERT_MSG(is_type_typed(target_type), "%s", type_to_string(type));
			}
			add_type_info_type(c, type);
			add_type_info_type(c, target_type);
		}

		convert_to_typed(c, operand, target_type);
		if (operand->mode == Addressing_Invalid) {
			return;
		}
	}


	if (type == nullptr) {
		return;
	}

	if (operand->mode == Addressing_ProcGroup) {
		// GB_PANIC("HERE!\n");

		gbTempArenaMemory tmp = gb_temp_arena_memory_begin(&c->tmp_arena);
		defer (gb_temp_arena_memory_end(tmp));

		Array<Entity *> procs = proc_group_entities(c, *operand);
		bool good = false;
		// NOTE(bill): These should be done
		for_array(i, procs) {
			Type *t = base_type(procs[i]->type);
			if (t == t_invalid) {
				continue;
			}
			Operand x = {};
			x.mode = Addressing_Value;
			x.type = t;
			if (check_is_assignable_to(c, &x, type)) {
				Entity *e = procs[i];
				add_entity_use(c, operand->expr, e);
				good = true;
				break;
			}
		}

		if (!good) {
			gbString expr_str    = expr_to_string(operand->expr);
			gbString op_type_str = type_to_string(operand->type);
			gbString type_str    = type_to_string(type);

			defer (gb_string_free(type_str));
			defer (gb_string_free(op_type_str));
			defer (gb_string_free(expr_str));

			// TODO(bill): is this a good enough error message?
			error(operand->expr,
			      "Cannot assign overloaded procedure '%s' to '%s' in %.*s",
			      expr_str,
			      op_type_str,
			      LIT(context_name));
			operand->mode = Addressing_Invalid;
		}
		return;
	}

	if (!check_is_assignable_to(c, operand, type)) {
		gbString expr_str    = expr_to_string(operand->expr);
		gbString op_type_str = type_to_string(operand->type);
		gbString type_str    = type_to_string(type);

		defer (gb_string_free(type_str));
		defer (gb_string_free(op_type_str));
		defer (gb_string_free(expr_str));

		switch (operand->mode) {
		case Addressing_Builtin:
			// TODO(bill): Actually allow built in procedures to be passed around and thus be created on use
			error(operand->expr,
			      "Cannot assign built-in procedure '%s' in %.*s",
			      expr_str,
			      LIT(context_name));
			break;
		case Addressing_Type:
			error(operand->expr,
			      "Cannot assign '%s' which is a type in %.*s",
			      op_type_str,
			      LIT(context_name));
			break;
		default:
			// TODO(bill): is this a good enough error message?
			error(operand->expr,
			      "Cannot assign value '%s' of type '%s' to '%s' in %.*s",
			      expr_str,
			      op_type_str,
			      type_str,
			      LIT(context_name));
			break;
		}
		operand->mode = Addressing_Invalid;

		return;
	}
}

bool is_polymorphic_type_assignable(Checker *c, Type *poly, Type *source, bool compound, bool modify_type) {
	Operand o = {Addressing_Value};
	o.type = source;
	switch (poly->kind) {
	case Type_Basic:
		if (compound) return are_types_identical(poly, source);
		return check_is_assignable_to(c, &o, poly);

	case Type_Named: {
		if (check_type_specialization_to(c, poly, source, compound, modify_type)) {
			return true;
		}
		if (compound || !is_type_generic(poly)) {
			return are_types_identical(poly, source);
		}
		return check_is_assignable_to(c, &o, poly);
	}

	case Type_Generic: {
		if (poly->Generic.specialized != nullptr) {
			Type *s = poly->Generic.specialized;
			if (!check_type_specialization_to(c, s, source, compound, modify_type)) {
				return false;
			}
		}
		if (modify_type) {
			Type *ds = default_type(source);
			gb_memmove(poly, ds, gb_size_of(Type));
		}
		return true;
	}
	case Type_Pointer:
		if (source->kind == Type_Pointer) {
			return is_polymorphic_type_assignable(c, poly->Pointer.elem, source->Pointer.elem, true, modify_type);
		}
		return false;
	case Type_Array:
		if (source->kind == Type_Array) {

			// IMPORTANT TODO(bill): Which is correct?
			// if (poly->Array.generic_count != nullptr && modify_type) {
			if (poly->Array.generic_count != nullptr) {
				Type *gt = poly->Array.generic_count;
				GB_ASSERT(gt->kind == Type_Generic);
				Entity *e = scope_lookup_entity(gt->Generic.scope, gt->Generic.name);
				GB_ASSERT(e != nullptr);
				if (e->kind == Entity_TypeName) {
					poly->Array.generic_count = nullptr;
					poly->Array.count = source->Array.count;

					e->kind = Entity_Constant;
					e->Constant.value = exact_value_i64(source->Array.count);
					e->type = t_untyped_integer;
				} else if (e->kind == Entity_Constant) {
					poly->Array.generic_count = nullptr;
					if (e->Constant.value.kind != ExactValue_Integer) {
						return false;
					}
					i64 count = e->Constant.value.value_integer;
					if (count != source->Array.count) {
						return false;
					}
					poly->Array.count = source->Array.count;
				} else {
					return false;
				}
			}
			if (poly->Array.count == source->Array.count) {
				return is_polymorphic_type_assignable(c, poly->Array.elem, source->Array.elem, true, modify_type);
			}
		}
		return false;
	case Type_DynamicArray:
		if (source->kind == Type_DynamicArray) {
			return is_polymorphic_type_assignable(c, poly->DynamicArray.elem, source->DynamicArray.elem, true, modify_type);
		}
		return false;
	case Type_Slice:
		if (source->kind == Type_Slice) {
			return is_polymorphic_type_assignable(c, poly->Slice.elem, source->Slice.elem, true, modify_type);
		}
		return false;

	case Type_Enum:
		return false;

	case Type_Union:
		if (source->kind == Type_Union) {
			TypeUnion *x = &poly->Union;
			TypeUnion *y = &source->Union;
			if (x->variants.count != y->variants.count) {
				return false;
			}
			for_array(i, x->variants) {
				Type *a = x->variants[i];
				Type *b = y->variants[i];
				bool ok = is_polymorphic_type_assignable(c, a, b, false, modify_type);
				if (!ok) return false;
			}
			return true;
		}
		return false;

	case Type_Struct:
		if (source->kind == Type_Struct) {
			// return check_is_assignable_to(c, &o, poly);
		}
		return false;
	case Type_Tuple:
		GB_PANIC("This should never happen");
		return false;
	case Type_Proc:
		if (source->kind == Type_Proc) {
			// return check_is_assignable_to(c, &o, poly);
			// TODO(bill): Polymorphic type assignment
			#if 1
			TypeProc *x = &poly->Proc;
			TypeProc *y = &source->Proc;
			if (x->calling_convention != y->calling_convention) {
				return false;
			}
			if (x->c_vararg != y->c_vararg) {
				return false;
			}
			if (x->variadic != y->variadic) {
				return false;
			}
			if (x->param_count != y->param_count) {
				return false;
			}
			if (x->result_count != y->result_count) {
				return false;
			}
			for (isize i = 0; i < x->param_count; i++) {
				Entity *a = x->params->Tuple.variables[i];
				Entity *b = y->params->Tuple.variables[i];
				bool ok = is_polymorphic_type_assignable(c, a->type, b->type, false, modify_type);
				if (!ok) return false;
			}
			for (isize i = 0; i < x->result_count; i++) {
				Entity *a = x->results->Tuple.variables[i];
				Entity *b = y->results->Tuple.variables[i];
				bool ok = is_polymorphic_type_assignable(c, a->type, b->type, false, modify_type);
				if (!ok) return false;
			}
			// TODO(bill): Polymorphic type assignment
			return true;
			#endif
		}
		return false;
	case Type_Map:
		if (source->kind == Type_Map) {
			bool key   = is_polymorphic_type_assignable(c, poly->Map.key, source->Map.key, true, modify_type);
			bool value = is_polymorphic_type_assignable(c, poly->Map.value, source->Map.value, true, modify_type);
			return key || value;
		}
		return false;
	}
	return false;
}

bool check_cycle(Checker *c, Entity *curr, bool report) {
	if (curr->state != EntityState_InProgress) {
		return false;
	}
	for_array(i, *c->context.type_path) {
		Entity *prev = (*c->context.type_path)[i];
		if (prev == curr) {
			if (report) {
				error(curr->token, "Illegal declaration cycle of `%.*s`", LIT(curr->token.string));
				for (isize j = i; j < c->context.type_path->count; j++) {
					Entity *curr = (*c->context.type_path)[j];
					error(curr->token, "\t%.*s refers to", LIT(curr->token.string));
				}
				error(curr->token, "\t%.*s", LIT(curr->token.string));
			}
			return true;
		}
	}
	return false;
}


Entity *check_ident(Checker *c, Operand *o, AstNode *n, Type *named_type, Type *type_hint, bool allow_import_name) {
	GB_ASSERT(n->kind == AstNode_Ident);
	o->mode = Addressing_Invalid;
	o->expr = n;
	String name = n->Ident.token.string;

	Entity *e = scope_lookup_entity(c->context.scope, name);
	if (e == nullptr) {
		if (is_blank_ident(name)) {
			error(n, "'_' cannot be used as a value type");
		} else {
			error(n, "Undeclared name: %.*s", LIT(name));
		}
		o->type = t_invalid;
		o->mode = Addressing_Invalid;
		if (named_type != nullptr) {
			set_base_type(named_type, t_invalid);
		}
		return nullptr;
	}
	if (e->parent_proc_decl != nullptr &&
	    e->parent_proc_decl != c->context.curr_proc_decl) {
		if (e->kind == Entity_Variable) {
			error(n, "Nested procedures do not capture its parent's variables: %.*s", LIT(name));
			return nullptr;
		} else if (e->kind == Entity_Label) {
			error(n, "Nested procedures do not capture its parent's labels: %.*s", LIT(name));
			return nullptr;
		}
	}
	bool is_alias = false;
	while (e->kind == Entity_Alias) {
		GB_ASSERT(e->Alias.base != nullptr);
		e = e->Alias.base;
		is_alias = true;
	}

	HashKey key = hash_string(e->token.string);

	if (e->kind == Entity_ProcGroup) {
		auto *pge = &e->ProcGroup;

		DeclInfo *d = decl_info_of_entity(&c->info, e);
		check_entity_decl(c, e, d, nullptr);


		Array<Entity *> procs = pge->entities;
		bool skip = false;

		if (type_hint != nullptr) {
			gbTempArenaMemory tmp = gb_temp_arena_memory_begin(&c->tmp_arena);
			defer (gb_temp_arena_memory_end(tmp));

			// NOTE(bill): These should be done
			for_array(i, procs) {
				Type *t = base_type(procs[i]->type);
				if (t == t_invalid) {
					continue;
				}
				Operand x = {};
				x.mode = Addressing_Value;
				x.type = t;
				if (check_is_assignable_to(c, &x, type_hint)) {
					e = procs[i];
					add_entity_use(c, n, e);
					skip = true;
					break;
				}
			}
		}

		if (!skip) {
			o->mode       = Addressing_ProcGroup;
			o->type       = t_invalid;
			o->proc_group = e;
			return nullptr;
		}
	}

	add_entity_use(c, n, e);
	if (e->state == EntityState_Unresolved) {
		check_entity_decl(c, e, nullptr, named_type);
	}


	if (e->type == nullptr) {
		// TODO(bill): Which is correct? return or compiler_error?
		// compiler_error("How did this happen? type: %s; identifier: %.*s\n", type_to_string(e->type), LIT(name));
		return nullptr;
	}

	e->flags |= EntityFlag_Used;

	Type *type = e->type;
	switch (e->kind) {
	case Entity_Constant:
		if (type == t_invalid) {
			o->type = t_invalid;
			return e;
		}
		o->value = e->Constant.value;
		if (o->value.kind == ExactValue_Invalid) {
			return e;
		}
		o->mode = Addressing_Constant;
		break;

	case Entity_Variable:
		e->flags |= EntityFlag_Used;
		if (type == t_invalid) {
			o->type = t_invalid;
			return e;
		}
		o->mode = Addressing_Variable;
		if (e->flags & EntityFlag_Value) {
			o->mode = Addressing_Value;
		}
		if (e->Variable.is_immutable) {
			o->mode = Addressing_Immutable;
		}
		break;

	case Entity_Procedure:
		o->mode = Addressing_Value;
		break;

	case Entity_Builtin:
		o->builtin_id = cast(BuiltinProcId)e->Builtin.id;
		o->mode = Addressing_Builtin;
		break;

	case Entity_TypeName:
		o->mode = Addressing_Type;
		if (check_cycle(c, e, true)) {
			type = t_invalid;
		}
		break;

	case Entity_ImportName:
		if (!allow_import_name) {
			error(n, "Use of import '%.*s' not in selector", LIT(name));
		}
		return e;
	case Entity_LibraryName:
		error(n, "Use of library '%.*s' not in foreign block", LIT(name));
		return e;

	case Entity_Label:
		o->mode = Addressing_NoValue;
		break;

	case Entity_Nil:
		o->mode = Addressing_Value;
		break;

	default:
		compiler_error("Unknown EntityKind %.*s", LIT(entity_strings[e->kind]));
		break;
	}

	o->type = type;
	return e;
}


bool check_unary_op(Checker *c, Operand *o, Token op) {
	if (o->type == nullptr) {
		gbString str = expr_to_string(o->expr);
		error(o->expr, "Expression has no value '%s'", str);
		gb_string_free(str);
		return false;
	}
	// TODO(bill): Handle errors correctly
	Type *type = base_type(core_array_type(o->type));
	gbString str = nullptr;
	switch (op.kind) {
	case Token_Add:
	case Token_Sub:
		if (!is_type_numeric(type)) {
			str = expr_to_string(o->expr);
			error(op, "Operator '%.*s' is not allowed with '%s'", LIT(op.string), str);
			gb_string_free(str);
		}
		break;

	case Token_Xor:
		if (!is_type_integer(type) && !is_type_boolean(type)) {
			error(op, "Operator '%.*s' is only allowed with integers or booleans", LIT(op.string));
		}
		break;

	case Token_Not:
		if (!is_type_boolean(type)) {
			str = expr_to_string(o->expr);
			error(op, "Operator '%.*s' is only allowed on boolean expression", LIT(op.string));
			gb_string_free(str);
		}
		break;

	default:
		error(op, "Unknown operator '%.*s'", LIT(op.string));
		return false;
	}

	return true;
}

bool check_binary_op(Checker *c, Operand *o, Token op) {
	// TODO(bill): Handle errors correctly
	Type *type = base_type(core_array_type(o->type));
	switch (op.kind) {
	case Token_Sub:
	case Token_SubEq:
		if (!is_type_numeric(type) && !is_type_pointer(type)) {
			error(op, "Operator '%.*s' is only allowed with numeric or pointer expressions", LIT(op.string));
			return false;
		}
#if defined(NO_POINTER_ARITHMETIC)
		if (is_type_pointer(type)) {
			error(o->expr, "Pointer arithmetic is not supported");
			return false;
		}
#else
		if (is_type_pointer(type)) {
			o->type = t_int;
		}
		if (base_type(type) == t_rawptr) {
			gbString str = type_to_string(type);
			error(o->expr, "Invalid pointer type for pointer arithmetic: '%s'", str);
			gb_string_free(str);
			return false;
		}
		break;
#endif

	case Token_Mul:
	case Token_Quo:
	case Token_AddEq:
	case Token_MulEq:
	case Token_QuoEq:
		if (!is_type_numeric(type)) {
			error(op, "Operator '%.*s' is only allowed with numeric expressions", LIT(op.string));
			return false;
		}
		break;

	case Token_Add:
		if (is_type_string(type)) {
			if (o->mode == Addressing_Constant) {
				return true;
			}
			error(op, "String concatenation is only allowed with constant strings");
			return false;
		} else if (!is_type_numeric(type)) {
			error(op, "Operator '%.*s' is only allowed with numeric expressions", LIT(op.string));
			return false;
		}
		break;

	case Token_And:
	case Token_Or:
	case Token_AndEq:
	case Token_OrEq:
	case Token_Xor:
	case Token_XorEq:
		if (!is_type_integer(type) && !is_type_boolean(type)) {
			error(op, "Operator '%.*s' is only allowed with integers or booleans", LIT(op.string));
			return false;
		}
		break;

	case Token_Mod:
	case Token_ModMod:
	case Token_AndNot:
	case Token_ModEq:
	case Token_ModModEq:
	case Token_AndNotEq:
		if (!is_type_integer(type)) {
			error(op, "Operator '%.*s' is only allowed with integers", LIT(op.string));
			return false;
		}
		break;

	case Token_CmpAnd:
	case Token_CmpOr:
	case Token_CmpAndEq:
	case Token_CmpOrEq:
		if (!is_type_boolean(type)) {
			error(op, "Operator '%.*s' is only allowed with boolean expressions", LIT(op.string));
			return false;
		}
		break;

	default:
		error(op, "Unknown operator '%.*s'", LIT(op.string));
		return false;
	}

	return true;

}

bool check_representable_as_constant(Checker *c, ExactValue in_value, Type *type, ExactValue *out_value) {
	if (in_value.kind == ExactValue_Invalid) {
		// NOTE(bill): There's already been an error
		return true;
	}

	type = core_type(type);
	if (type == t_invalid) {
		return false;
	} else if (is_type_boolean(type)) {
		return in_value.kind == ExactValue_Bool;
	} else if (is_type_string(type)) {
		return in_value.kind == ExactValue_String;
	} else if (is_type_integer(type) || is_type_rune(type)) {
		ExactValue v = exact_value_to_integer(in_value);
		if (v.kind != ExactValue_Integer) {
			return false;
		}
		if (out_value) *out_value = v;


		if (is_type_untyped(type)) {
			return true;
		}

		i64 i = v.value_integer;
		u64 u = bit_cast<u64>(i);
		i64 s = 8*type_size_of(type);
		u64 umax = ~cast(u64)0ull;
		if (s < 64) {
			umax = (1ull << cast(u64)s) - 1ull;
		} else {
			// IMPORTANT TODO(bill): I NEED A PROPER BIG NUMBER LIBRARY THAT CAN SUPPORT 128 bit floats
			s = 64;
		}
		i64 imin = -1ll << (s-1ll);
		i64 imax = (1ll << (s-1ll))-1ll;

		switch (type->Basic.kind) {
		case Basic_rune:
		case Basic_i8:
		case Basic_i16:
		case Basic_i32:
		case Basic_int:
			return imin <= i && i <= imax;

		case Basic_u8:
		case Basic_u16:
		case Basic_u32:
		case Basic_uint:
		case Basic_uintptr:
			return !(u < 0ull || u > umax);

		case Basic_u64:
			return 0ull <= i;

		case Basic_i64:
			return true;
		case Basic_UntypedInteger:
			return true;

		default: GB_PANIC("Compiler error: Unknown integer type!"); break;
		}
	} else if (is_type_float(type)) {
		ExactValue v = exact_value_to_float(in_value);
		if (v.kind != ExactValue_Float) {
			return false;
		}
		if (out_value) *out_value = v;

		switch (type->Basic.kind) {
		// case Basic_f16:
		case Basic_f32:
		case Basic_f64:
			return true;

		case Basic_UntypedFloat:
			return true;

		default: GB_PANIC("Compiler error: Unknown float type!"); break;
		}
	} else if (is_type_complex(type)) {
		ExactValue v = exact_value_to_complex(in_value);
		if (v.kind != ExactValue_Complex) {
			return false;
		}

		switch (type->Basic.kind) {
		case Basic_complex64:
		case Basic_complex128: {
			ExactValue real = exact_value_real(v);
			ExactValue imag = exact_value_imag(v);
			if (real.kind != ExactValue_Invalid &&
			    imag.kind != ExactValue_Invalid) {
				if (out_value) *out_value = exact_binary_operator_value(Token_Add, real, exact_value_make_imag(imag));
				return true;
			}
			break;
		}
		case Basic_UntypedComplex:
			return true;

		default: GB_PANIC("Compiler error: Unknown complex type!"); break;
		}

		return false;
	} else if (is_type_pointer(type)) {
		if (in_value.kind == ExactValue_Pointer) {
			return true;
		}
		if (in_value.kind == ExactValue_Integer) {
			return false;
			// return true;
		}
		if (out_value) *out_value = in_value;
	}


	return false;
}

void check_is_expressible(Checker *c, Operand *o, Type *type) {
	GB_ASSERT(is_type_constant_type(type));
	GB_ASSERT(o->mode == Addressing_Constant);
	if (!check_representable_as_constant(c, o->value, type, &o->value)) {
		gbString a = expr_to_string(o->expr);
		gbString b = type_to_string(type);
		if (is_type_numeric(o->type) && is_type_numeric(type)) {
			if (!is_type_integer(o->type) && is_type_integer(type)) {
				error(o->expr, "'%s' truncated to '%s'", a, b);
			} else {
				char buf[127] = {};
				String str = {};
				i64 i = o->value.value_integer;
				if (is_type_unsigned(o->type)) {
					str = u64_to_string(bit_cast<u64>(i), buf, gb_size_of(buf));
				} else {
					str = i64_to_string(i, buf, gb_size_of(buf));
				}
				error(o->expr, "'%s = %.*s' overflows '%s'", a, LIT(str), b);
			}
		} else {
			error(o->expr, "Cannot convert '%s' to '%s'", a, b);
		}

		gb_string_free(b);
		gb_string_free(a);
		o->mode = Addressing_Invalid;
	}
}

bool check_is_not_addressable(Checker *c, Operand *o) {
	if (o->mode == Addressing_OptionalOk) {
		AstNode *expr = unselector_expr(o->expr);
		if (expr->kind != AstNode_TypeAssertion) {
			return true;
		}
		ast_node(ta, TypeAssertion, expr);
		TypeAndValue tv = type_and_value_of_expr(&c->info, ta->expr);
		if (is_type_pointer(tv.type)) {
			return false;
		}
		if (is_type_union(tv.type) && tv.mode == Addressing_Variable) {
			return false;
		}
		if (is_type_any(tv.type)) {
			return false;
		}
		return true;

	}
	if (o->mode != Addressing_Variable) {
		return true;
	}
	if (is_type_bit_field_value(o->type)) {
		return true;
	}

	return false;
}

void check_unary_expr(Checker *c, Operand *o, Token op, AstNode *node) {
	switch (op.kind) {
	case Token_And: { // Pointer address
		if (check_is_not_addressable(c, o)) {
			if (ast_node_expect(node, AstNode_UnaryExpr)) {
				ast_node(ue, UnaryExpr, node);
				gbString str = expr_to_string(ue->expr);
				error(op, "Cannot take the pointer address of '%s'", str);
				gb_string_free(str);
			}
			o->mode = Addressing_Invalid;
			return;
		}
		o->mode = Addressing_Value;
		o->type = alloc_type_pointer(o->type);
		return;
	}
	}

	if (!check_unary_op(c, o, op)) {
		o->mode = Addressing_Invalid;
		return;
	}

	if (o->mode == Addressing_Constant) {
		Type *type = base_type(o->type);
		if (!is_type_constant_type(o->type)) {
			gbString xt = type_to_string(o->type);
			gbString err_str = expr_to_string(node);
			error(op, "Invalid type, '%s', for constant unary expression '%s'", xt, err_str);
			gb_string_free(err_str);
			gb_string_free(xt);
			o->mode = Addressing_Invalid;
			return;
		}


		i32 precision = 0;
		if (is_type_unsigned(type)) {
			precision = cast(i32)(8 * type_size_of(type));
		}
		if (op.kind == Token_Xor && is_type_untyped(type)) {
			gbString err_str = expr_to_string(node);
			error(op, "Bitwise not cannot be applied to untyped constants '%s'", err_str);
			gb_string_free(err_str);
			o->mode = Addressing_Invalid;
			return;
		}
		if (op.kind == Token_Sub && is_type_unsigned(type)) {
			gbString err_str = expr_to_string(node);
			error(op, "A unsigned constant cannot be negated '%s'", err_str);
			gb_string_free(err_str);
			o->mode = Addressing_Invalid;
			return;
		}

		o->value = exact_unary_operator_value(op.kind, o->value, precision);

		if (is_type_typed(type)) {
			if (node != nullptr) {
				o->expr = node;
			}
			check_is_expressible(c, o, type);
		}
		return;
	}

	o->mode = Addressing_Value;
}


void check_comparison(Checker *c, Operand *x, Operand *y, TokenKind op) {
	if (x->mode == Addressing_Type && y->mode == Addressing_Type) {
		bool comp = are_types_identical(x->type, y->type);
		switch (op) {
		case Token_CmpEq: comp = comp;  break;
		case Token_NotEq: comp = !comp; break;
		}
		x->mode  = Addressing_Constant;
		x->type  = t_untyped_bool;
		x->value = exact_value_bool(comp);
		return;
	}

	gbString err_str = nullptr;

	defer (if (err_str != nullptr) {
		gb_string_free(err_str);
	});
	gbTempArenaMemory tmp = gb_temp_arena_memory_begin(&c->tmp_arena);
	defer (gb_temp_arena_memory_end(tmp));

	if (check_is_assignable_to(c, x, y->type) ||
	    check_is_assignable_to(c, y, x->type)) {
		Type *err_type = x->type;
		bool defined = false;
		switch (op) {
		case Token_CmpEq:
		case Token_NotEq:
			defined = is_type_comparable(x->type) ||
			          (is_operand_nil(*x) && type_has_nil(y->type)) ||
			          (is_operand_nil(*y) && type_has_nil(x->type));
			break;
		case Token_Lt:
		case Token_Gt:
		case Token_LtEq:
		case Token_GtEq:
			defined = is_type_ordered(x->type);
			break;
		}

		if (!defined) {
			if (x->type == err_type && is_operand_nil(*x)) {
				err_type = y->type;
			}
			gbString type_string = type_to_string(err_type);
			defer (gb_string_free(type_string));
			err_str = gb_string_make(c->tmp_allocator,
			                         gb_bprintf("operator '%.*s' not defined for type '%s'", LIT(token_strings[op]), type_string));
		}
	} else {
		gbString xt, yt;
		if (x->mode == Addressing_ProcGroup) {
			xt = gb_string_make(heap_allocator(), "procedure group");
		} else {
			xt = type_to_string(x->type);
		}
		if (y->mode == Addressing_ProcGroup) {
			yt = gb_string_make(heap_allocator(), "procedure group");
		} else {
			yt = type_to_string(y->type);
		}
		err_str = gb_string_make(c->tmp_allocator,
		                         gb_bprintf("mismatched types '%s' and '%s'", xt, yt));
		gb_string_free(yt);
		gb_string_free(xt);
	}

	if (err_str != nullptr) {
		error(x->expr, "Cannot compare expression, %s", err_str);
		x->type = t_untyped_bool;
	} else {
		if (x->mode == Addressing_Constant &&
		    y->mode == Addressing_Constant) {
			x->value = exact_value_bool(compare_exact_values(op, x->value, y->value));
		} else {
			x->mode = Addressing_Value;


			update_expr_type(c, x->expr, default_type(x->type), true);
			update_expr_type(c, y->expr, default_type(y->type), true);
		}

		x->type = t_untyped_bool;
	}

}

void check_shift(Checker *c, Operand *x, Operand *y, AstNode *node) {
	GB_ASSERT(node->kind == AstNode_BinaryExpr);
	ast_node(be, BinaryExpr, node);

	ExactValue x_val = {};
	if (x->mode == Addressing_Constant) {
		x_val = exact_value_to_integer(x->value);
	}

	bool x_is_untyped = is_type_untyped(x->type);
	if (!(is_type_integer(x->type) || (x_is_untyped && x_val.kind == ExactValue_Integer))) {
		gbString err_str = expr_to_string(x->expr);
		error(node, "Shifted operand '%s' must be an integer", err_str);
		gb_string_free(err_str);
		x->mode = Addressing_Invalid;
		return;
	}

	if (is_type_unsigned(y->type)) {

	} else if (is_type_untyped(y->type)) {
		convert_to_typed(c, y, t_untyped_integer);
		if (y->mode == Addressing_Invalid) {
			x->mode = Addressing_Invalid;
			return;
		}
	} else {
		gbString err_str = expr_to_string(y->expr);
		error(node, "Shift amount '%s' must be an unsigned integer", err_str);
		gb_string_free(err_str);
		x->mode = Addressing_Invalid;
		return;
	}


	if (x->mode == Addressing_Constant) {
		if (y->mode == Addressing_Constant) {
			ExactValue y_val = exact_value_to_integer(y->value);
			if (y_val.kind != ExactValue_Integer) {
				gbString err_str = expr_to_string(y->expr);
				error(node, "Shift amount '%s' must be an unsigned integer", err_str);
				gb_string_free(err_str);
				x->mode = Addressing_Invalid;
				return;
			}

			i64 amount = y_val.value_integer;
			if (amount > 128) {
				gbString err_str = expr_to_string(y->expr);
				error(node, "Shift amount too large: '%s'", err_str);
				gb_string_free(err_str);
				x->mode = Addressing_Invalid;
				return;
			}

			if (!is_type_integer(x->type)) {
				// NOTE(bill): It could be an untyped float but still representable
				// as an integer
				x->type = t_untyped_integer;
			}

			x->value = exact_value_shift(be->op.kind, x_val, exact_value_i64(amount));

			if (is_type_typed(x->type)) {
				check_is_expressible(c, x, base_type(x->type));
			}
			return;
		}

		TokenPos pos = ast_node_token(x->expr).pos;
		if (x_is_untyped) {
			ExprInfo *info = check_get_expr_info(&c->info, x->expr);
			if (info != nullptr) {
				info->is_lhs = true;
			}
			x->mode = Addressing_Value;
			// x->value = x_val;
			return;
		}
	}

	if (y->mode == Addressing_Constant && y->value.value_integer < 0) {
		gbString err_str = expr_to_string(y->expr);
		error(node, "Shift amount cannot be negative: '%s'", err_str);
		gb_string_free(err_str);
	}

	if (!is_type_integer(x->type)) {
		gbString err_str = expr_to_string(y->expr);
		error(node, "Shift operand '%s' must be an integer", err_str);
		gb_string_free(err_str);
		x->mode = Addressing_Invalid;
		return;
	}

	x->mode = Addressing_Value;
}


Operand check_ptr_addition(Checker *c, TokenKind op, Operand *ptr, Operand *offset, AstNode *node) {
	GB_ASSERT(node->kind == AstNode_BinaryExpr);
	ast_node(be, BinaryExpr, node);
	GB_ASSERT(is_type_pointer(ptr->type));
	GB_ASSERT(is_type_integer(offset->type));
	GB_ASSERT(op == Token_Add || op == Token_Sub);

	Operand operand = {};
	operand.mode = Addressing_Value;
	operand.type = ptr->type;
	operand.expr = node;

	if (base_type(ptr->type) == t_rawptr) {
		gbString str = type_to_string(ptr->type);
		error(node, "Invalid pointer type for pointer arithmetic: '%s'", str);
		gb_string_free(str);
		operand.mode = Addressing_Invalid;
		return operand;
	}

#if defined(NO_POINTER_ARITHMETIC)
	operand.mode = Addressing_Invalid;
	error(operand.expr, "Pointer arithmetic is not supported");
	return operand;
#else

	Type *base_ptr = base_type(ptr->type); GB_ASSERT(base_ptr->kind == Type_Pointer);
	Type *elem = base_ptr->Pointer.elem;
	i64 elem_size = type_size_of(elem);

	if (elem_size <= 0) {
		gbString str = type_to_string(elem);
		error(node, "Size of pointer's element type '%s' is zero and cannot be used for pointer arithmetic", str);
		gb_string_free(str);
		operand.mode = Addressing_Invalid;
		return operand;
	}

	if (ptr->mode == Addressing_Constant && offset->mode == Addressing_Constant) {
		i64 ptr_val = ptr->value.value_pointer;
		i64 offset_val = exact_value_to_integer(offset->value).value_integer;
		i64 new_ptr_val = ptr_val;
		if (op == Token_Add) {
			new_ptr_val += elem_size*offset_val;
		} else {
			new_ptr_val -= elem_size*offset_val;
		}
		operand.mode = Addressing_Constant;
		operand.value = exact_value_pointer(new_ptr_val);
	}

	return operand;
#endif
}



bool check_is_castable_to(Checker *c, Operand *operand, Type *y) {
	if (check_is_assignable_to(c, operand, y)) {
		return true;
	}

	Type *x = operand->type;
	Type *src = core_type(x);
	Type *dst = core_type(y);
	if (are_types_identical(src, dst)) {
		return true;
	}


	if (dst->kind == Type_Array && src->kind == Type_Array) {
		if (are_types_identical(dst->Array.elem, src->Array.elem)) {
			return dst->Array.count == src->Array.count;
		}
	}

	if (dst->kind == Type_Slice && src->kind == Type_Slice) {
		return are_types_identical(dst->Slice.elem, src->Slice.elem);
	}

	// Cast between booleans and integers
	if (is_type_boolean(src) || is_type_integer(src)) {
		if (is_type_boolean(dst) || is_type_integer(dst)) {
			return true;
		}
	}

	// Cast between numbers
	if (is_type_integer(src) || is_type_float(src)) {
		if (is_type_integer(dst) || is_type_float(dst)) {
			return true;
		}
	}

	if (is_type_integer(src) && is_type_rune(dst)) {
		return true;
	}
	if (is_type_rune(src) && is_type_integer(dst)) {
		return true;
	}

	if (is_type_complex(src) && is_type_complex(dst)) {
		return true;
	}

	if (is_type_bit_field_value(src) && is_type_integer(dst)) {
		return true;
	}

	if (is_type_bit_field_value(src) && is_type_boolean(dst)) {
		return src->BitFieldValue.bits == 1;
	}

	// Cast between pointers
	if (is_type_pointer(src) && is_type_pointer(dst)) {
		#if 0
		Type *s = base_type(type_deref(src));
		if (is_type_union(s)) {
			// NOTE(bill): Should the error be here?!
			// NOTE(bill): This error should suppress the next casting error as it's at the same position
			gbString xs = type_to_string(x);
			gbString ys = type_to_string(y);
			error(operand->expr, "Cannot cast from a union pointer '%s' to '%s', try using 'union_cast' or cast to a 'rawptr'", xs, ys);
			gb_string_free(ys);
			gb_string_free(xs);
			return false;
		}
		#endif
		return true;
	}

	// (u)int <-> pointer
	if (is_type_uintptr(src) && is_type_pointer(dst)) {
		return true;
	}
	if (is_type_pointer(src) && is_type_uintptr(dst)) {
		return true;
	}

	// []byte/[]u8 <-> string
	if (is_type_u8_slice(src) && is_type_string(dst)) {
		return true;
	}
	if (is_type_string(src) && is_type_u8_slice(dst)) {
		// if (is_type_typed(src)) {
			return true;
		// }
	}
	// cstring -> string
	if (src == t_cstring && dst == t_string) {
		return true;
	}
	// cstring -> ^u8
	if (src == t_cstring && is_type_u8_ptr(dst)) {
		return true;
	}

	// ^u8 -> cstring
	if (is_type_u8_ptr(src) && dst == t_cstring) {
		return true;
	}
	// proc <-> proc
	if (is_type_proc(src) && is_type_proc(dst)) {
		return true;
	}

	// proc -> rawptr
	if (is_type_proc(src) && is_type_rawptr(dst)) {
		return true;
	}
	// rawptr -> proc
	if (is_type_rawptr(src) && is_type_proc(dst)) {
		return true;
	}

	return false;
}

bool check_cast_internal(Checker *c, Operand *x, Type *type) {
	bool is_const_expr = x->mode == Addressing_Constant;
	bool can_convert = false;

	Type *bt = base_type(type);
	if (is_const_expr && is_type_constant_type(bt)) {
		if (core_type(bt)->kind == Type_Basic) {
			if (check_representable_as_constant(c, x->value, bt, &x->value)) {
				return true;
			} else if (is_type_pointer(type) && check_is_castable_to(c, x, type)) {
				return true;
			}
		}
	} else if (check_is_castable_to(c, x, type)) {
		if (x->mode != Addressing_Constant) {
			x->mode = Addressing_Value;
		} else if (is_type_slice(type) && is_type_string(x->type)) {
			x->mode = Addressing_Value;
		}
		return true;
	}
	return false;

}

void check_cast(Checker *c, Operand *x, Type *type) {
	if (!is_operand_value(*x)) {
		error(x->expr, "Only values can be casted");
		x->mode = Addressing_Invalid;
		return;
	}

	bool is_const_expr = x->mode == Addressing_Constant;
	bool can_convert = check_cast_internal(c, x, type);

	if (!can_convert) {
		gbString expr_str = expr_to_string(x->expr);
		gbString to_type  = type_to_string(type);
		gbString from_type = type_to_string(x->type);
		error(x->expr, "Cannot cast '%s' as '%s' from '%s'", expr_str, to_type, from_type);
		gb_string_free(from_type);
		gb_string_free(to_type);
		gb_string_free(expr_str);

		x->mode = Addressing_Invalid;
		return;
	}

	if (is_type_untyped(x->type)) {
		Type *final_type = type;
		if (is_const_expr && !is_type_constant_type(type)) {
			final_type = default_type(x->type);
		}
		update_expr_type(c, x->expr, final_type, true);
	}

	x->type = type;
}

bool check_transmute(Checker *c, AstNode *node, Operand *o, Type *t) {
	if (!is_operand_value(*o)) {
		error(o->expr, "'transmute' can only be applied to values");
		o->mode = Addressing_Invalid;
		return false;
	}

	if (o->mode == Addressing_Constant) {
		gbString expr_str = expr_to_string(o->expr);
		error(o->expr, "Cannot transmute a constant expression: '%s'", expr_str);
		gb_string_free(expr_str);
		o->mode = Addressing_Invalid;
		o->expr = node;
		return false;
	}

	if (is_type_untyped(o->type)) {
		gbString expr_str = expr_to_string(o->expr);
		error(o->expr, "Cannot transmute untyped expression: '%s'", expr_str);
		gb_string_free(expr_str);
		o->mode = Addressing_Invalid;
		o->expr = node;
		return false;
	}

	i64 srcz = type_size_of(o->type);
	i64 dstz = type_size_of(t);
	if (srcz != dstz) {
		gbString expr_str = expr_to_string(o->expr);
		gbString type_str = type_to_string(t);
		error(o->expr, "Cannot transmute '%s' to '%s', %lld vs %lld bytes", expr_str, type_str, srcz, dstz);
		gb_string_free(type_str);
		gb_string_free(expr_str);
		o->mode = Addressing_Invalid;
		o->expr = node;
		return false;
	}

	o->mode = Addressing_Value;
	o->type = t;
	return true;
}

bool check_binary_array_expr(Checker *c, Token op, Operand *x, Operand *y) {
	if (is_type_array(x->type) && !is_type_array(y->type)) {
		if (check_is_assignable_to(c, y, x->type)) {
			if (check_binary_op(c, x, op)) {
				return true;
			}
		}
	}
	return false;
}


void check_binary_expr(Checker *c, Operand *x, AstNode *node) {
	GB_ASSERT(node->kind == AstNode_BinaryExpr);
	Operand y_ = {}, *y = &y_;

	ast_node(be, BinaryExpr, node);

	Token op = be->op;
	switch (op.kind) {
	case Token_CmpEq:
	case Token_NotEq: {
		// NOTE(bill): Allow comparisons between types
		check_expr_or_type(c, x, be->left);
		check_expr_or_type(c, y, be->right);
		bool xt = x->mode == Addressing_Type;
		bool yt = y->mode == Addressing_Type;
		// If only one is a type, this is an error
		if (xt ^ yt) {
			GB_ASSERT(xt != yt);
			if (xt) error_operand_not_expression(x);
			if (yt) error_operand_not_expression(y);
		}

		break;
	}

	default:
		check_expr(c, x, be->left);
		check_expr(c, y, be->right);
		break;
	}
	if (x->mode == Addressing_Invalid) {
		return;
	}
	if (y->mode == Addressing_Invalid) {
		x->mode = Addressing_Invalid;
		x->expr = y->expr;
		return;
	}

	if (token_is_shift(op.kind)) {
		check_shift(c, x, y, node);
		return;
	}

	if (op.kind == Token_Add || op.kind == Token_Sub) {
		if (is_type_pointer(x->type) && is_type_integer(y->type)) {
			*x = check_ptr_addition(c, op.kind, x, y, node);
			return;
		} else if (is_type_integer(x->type) && is_type_pointer(y->type)) {
			if (op.kind == Token_Sub) {
				gbString lhs = expr_to_string(x->expr);
				gbString rhs = expr_to_string(y->expr);
				error(node, "Invalid pointer arithmetic, did you mean '%s %.*s %s'?", rhs, LIT(op.string), lhs);
				gb_string_free(rhs);
				gb_string_free(lhs);
				x->mode = Addressing_Invalid;
				return;
			}
			*x = check_ptr_addition(c, op.kind, y, x, node);
			return;
		}
	}

	convert_to_typed(c, x, y->type);
	if (x->mode == Addressing_Invalid) {
		return;
	}
	convert_to_typed(c, y, x->type);
	if (y->mode == Addressing_Invalid) {
		x->mode = Addressing_Invalid;
		return;
	}



	if (token_is_comparison(op.kind)) {
		check_comparison(c, x, y, op.kind);
		return;
	}

	if (check_binary_array_expr(c, op, x, y)) {
		x->mode = Addressing_Value;
		x->type = x->type;
		return;
	}
	if (check_binary_array_expr(c, op, y, x)) {
		x->mode = Addressing_Value;
		x->type = y->type;
		return;
	}
	if (!are_types_identical(x->type, y->type)) {
		if (x->type != t_invalid &&
		    y->type != t_invalid) {
			gbString xt = type_to_string(x->type);
			gbString yt = type_to_string(y->type);
			gbString expr_str = expr_to_string(x->expr);
			error(op, "Mismatched types in binary expression '%s' : '%s' vs '%s'", expr_str, xt, yt);
			gb_string_free(expr_str);
			gb_string_free(yt);
			gb_string_free(xt);
		}
		x->mode = Addressing_Invalid;
		return;
	}

	if (!check_binary_op(c, x, op)) {
		x->mode = Addressing_Invalid;
		return;
	}

	switch (op.kind) {
	case Token_Quo:
	case Token_Mod:
	case Token_ModMod:
	case Token_QuoEq:
	case Token_ModEq:
	case Token_ModModEq:
		if ((x->mode == Addressing_Constant || is_type_integer(x->type)) &&
		    y->mode == Addressing_Constant) {
			bool fail = false;
			switch (y->value.kind) {
			case ExactValue_Integer:
				if (y->value.value_integer == 0 ) {
					fail = true;
				}
				break;
			case ExactValue_Float:
				if (y->value.value_float == 0.0) {
					fail = true;
				}
				break;
			}

			if (fail) {
				error(y->expr, "Division by zero not allowed");
				x->mode = Addressing_Invalid;
				return;
			}
		}
	}

	if (x->mode == Addressing_Constant &&
	    y->mode == Addressing_Constant) {
		ExactValue a = x->value;
		ExactValue b = y->value;

		Type *type = base_type(x->type);
		if (is_type_pointer(type)) {
			GB_ASSERT(op.kind == Token_Sub);
			i64 bytes = a.value_pointer - b.value_pointer;
			i64 diff = bytes/type_size_of(type);
			x->value = exact_value_pointer(diff);
			return;
		}

		if (!is_type_constant_type(type)) {
			gbString xt = type_to_string(x->type);
			gbString err_str = expr_to_string(node);
			error(op, "Invalid type, '%s', for constant binary expression '%s'", xt, err_str);
			gb_string_free(err_str);
			gb_string_free(xt);
			x->mode = Addressing_Invalid;
			return;
		}

		if (op.kind == Token_Quo && is_type_integer(type)) {
			op.kind = Token_QuoEq; // NOTE(bill): Hack to get division of integers
		}

		x->value = exact_binary_operator_value(op.kind, a, b);

		if (is_type_typed(type)) {
			if (node != nullptr) {
				x->expr = node;
			}
			check_is_expressible(c, x, type);
		}
		return;
	} else if (is_type_string(x->type)) {
		error(node, "String concatenation is only allowed with constant strings");
		x->mode = Addressing_Invalid;
		return;
	}

	x->mode = Addressing_Value;
}


void update_expr_type(Checker *c, AstNode *e, Type *type, bool final) {
	ExprInfo *found = check_get_expr_info(&c->info, e);
	if (found == nullptr) {
		return;
	}
	ExprInfo old = *found;

	switch (e->kind) {
	case_ast_node(ue, UnaryExpr, e);
		if (old.value.kind != ExactValue_Invalid) {
			// NOTE(bill): if 'e' is constant, the operands will be constant too.
			// They don't need to be updated as they will be updated later and
			// checked at the end of general checking stage.
			break;
		}
		update_expr_type(c, ue->expr, type, final);
	case_end;

	case_ast_node(be, BinaryExpr, e);
		if (old.value.kind != ExactValue_Invalid) {
			// See above note in UnaryExpr case
			break;
		}
		if (token_is_comparison(be->op.kind)) {
			// NOTE(bill): Do nothing as the types are fine
		} else if (token_is_shift(be->op.kind)) {
			update_expr_type(c, be->left,  type, final);
		} else {
			update_expr_type(c, be->left,  type, final);
			update_expr_type(c, be->right, type, final);
		}
	case_end;

	case_ast_node(pe, ParenExpr, e);
		update_expr_type(c, pe->expr, type, final);
	case_end;
	}

	if (!final && is_type_untyped(type)) {
		old.type = base_type(type);
		check_set_expr_info(&c->info, e, old);
		return;
	}

	// We need to remove it and then give it a new one
	check_remove_expr_info(&c->info, e);

	if (old.is_lhs && !is_type_integer(type)) {
		gbString expr_str = expr_to_string(e);
		gbString type_str = type_to_string(type);
		error(e, "Shifted operand %s must be an integer, got %s", expr_str, type_str);
		gb_string_free(type_str);
		gb_string_free(expr_str);
		return;
	}

	add_type_and_value(&c->info, e, old.mode, type, old.value);
}

void update_expr_value(Checker *c, AstNode *e, ExactValue value) {
	ExprInfo *found = check_get_expr_info(&c->info, e);
	if (found) {
		found->value = value;
	}
}

void convert_untyped_error(Checker *c, Operand *operand, Type *target_type) {
	gbString expr_str = expr_to_string(operand->expr);
	gbString type_str = type_to_string(target_type);
	char *extra_text = "";

	if (operand->mode == Addressing_Constant) {
		if (operand->value.value_integer == 0) {
			if (make_string_c(expr_str) != "nil") { // HACK NOTE(bill): Just in case
				// NOTE(bill): Doesn't matter what the type is as it's still zero in the union
				extra_text = " - Did you want 'nil'?";
			}
		}
	}
	error(operand->expr, "Cannot convert '%s' to '%s'%s", expr_str, type_str, extra_text);

	gb_string_free(type_str);
	gb_string_free(expr_str);
	operand->mode = Addressing_Invalid;
}

ExactValue convert_exact_value_for_type(ExactValue v, Type *type) {
	Type *t = core_type(type);
	if (is_type_boolean(t)) {
		// v = exact_value_to_boolean(v);
	} else if (is_type_float(t)) {
		v = exact_value_to_float(v);
	} else if (is_type_integer(t)) {
		v = exact_value_to_integer(v);
	} else if (is_type_pointer(t)) {
		v = exact_value_to_integer(v);
	} else if (is_type_complex(t)) {
		v = exact_value_to_complex(v);
	}
	return v;
}

void convert_to_typed(Checker *c, Operand *operand, Type *target_type) {
	GB_ASSERT_NOT_NULL(target_type);
	if (operand->mode == Addressing_Invalid ||
	    operand->mode == Addressing_Type ||
	    is_type_typed(operand->type) ||
	    target_type == t_invalid) {
		return;
	}

	if (is_type_untyped(target_type)) {
		GB_ASSERT(operand->type->kind == Type_Basic);
		GB_ASSERT(target_type->kind == Type_Basic);
		BasicKind x_kind = operand->type->Basic.kind;
		BasicKind y_kind = target_type->Basic.kind;
		if (is_type_numeric(operand->type) && is_type_numeric(target_type)) {
			if (x_kind < y_kind) {
				operand->type = target_type;
				update_expr_type(c, operand->expr, target_type, false);
			}
		} else if (x_kind != y_kind) {
			operand->mode = Addressing_Invalid;
			convert_untyped_error(c, operand, target_type);
			return;
		}
		return;
	}

	Type *t = core_type(target_type);
	switch (t->kind) {
	case Type_Basic:
		if (operand->mode == Addressing_Constant) {
			check_is_expressible(c, operand, t);
			if (operand->mode == Addressing_Invalid) {
				return;
			}
			update_expr_value(c, operand->expr, operand->value);
		} else {
			switch (operand->type->Basic.kind) {
			case Basic_UntypedBool:
				if (!is_type_boolean(target_type)) {
					operand->mode = Addressing_Invalid;
					convert_untyped_error(c, operand, target_type);
					return;
				}
				break;
			case Basic_UntypedInteger:
			case Basic_UntypedFloat:
			case Basic_UntypedComplex:
			case Basic_UntypedRune:
				if (!is_type_numeric(target_type)) {
					operand->mode = Addressing_Invalid;
					convert_untyped_error(c, operand, target_type);
					return;
				}
				break;

			case Basic_UntypedNil:
				if (is_type_any(target_type)) {
					target_type = t_untyped_nil;
				} else if (is_type_cstring(target_type)) {
					target_type = t_untyped_nil;
				} else if (!type_has_nil(target_type)) {
					operand->mode = Addressing_Invalid;
					convert_untyped_error(c, operand, target_type);
					return;
				}
				break;
			}
		}
		break;

	case Type_Array: {
		Type *elem = base_array_type(t);
		if (check_is_assignable_to(c, operand, elem)) {
			operand->mode = Addressing_Value;
		} else {
			operand->mode = Addressing_Invalid;
			convert_untyped_error(c, operand, target_type);
			return;
		}

		break;
	}

	case Type_Union:
		if (!is_operand_nil(*operand) && !is_operand_undef(*operand)) {
			gbTempArenaMemory tmp = gb_temp_arena_memory_begin(&c->tmp_arena);
			defer (gb_temp_arena_memory_end(tmp));
			isize count = t->Union.variants.count;
			ValidIndexAndScore *valids = gb_alloc_array(c->tmp_allocator, ValidIndexAndScore, count);
			isize valid_count = 0;
			isize first_success_index = -1;
			for_array(i, t->Union.variants) {
				Type *vt = t->Union.variants[i];
				i64 score = 0;
				if (check_is_assignable_to_with_score(c, operand, vt, &score)) {
					valids[valid_count].index = i;
					valids[valid_count].score = score;
					valid_count += 1;
					if (first_success_index < 0) {
						first_success_index = i;
					}
				}
			}

			if (valid_count > 1) {
				gb_sort_array(valids, valid_count, valid_index_and_score_cmp);
				i64 best_score = valids[0].score;
				Type *best_type = t->Union.variants[valids[0].index];
				for (isize i = 1; i < valid_count; i++) {
					auto v = valids[i];
					Type *vt = t->Union.variants[v.index];
					if (best_score > v.score) {
						valid_count = i;
						break;
					}
					best_score = v.score;
				}
				first_success_index = valids[0].index;
			}

			gbString type_str = type_to_string(target_type);
			defer (gb_string_free(type_str));

			if (valid_count == 1) {
				operand->mode = Addressing_Value;
				operand->type = t->Union.variants[first_success_index];
				target_type = t->Union.variants[first_success_index];
				break;
			} else if (valid_count > 1) {
				GB_ASSERT(first_success_index >= 0);
				operand->mode = Addressing_Invalid;
				convert_untyped_error(c, operand, target_type);

				gb_printf_err("Ambiguous type conversion to '%s', which variant did you mean:\n\t", type_str);
				i32 j = 0;
				for (i32 i = 0; i < valid_count; i++) {
					ValidIndexAndScore valid = valids[i];
					if (j > 0 && valid_count > 2) gb_printf_err(", ");
					if (j == valid_count-1) {
						if (valid_count == 2) gb_printf_err(" ");
						gb_printf_err("or ");
					}
					gbString str = type_to_string(t->Union.variants[valid.index]);
					gb_printf_err("'%s'", str);
					gb_string_free(str);
					j++;
				}
				gb_printf_err("\n\n");

				return;
			} else if (is_type_untyped_undef(operand->type) && type_has_undef(target_type)) {
				target_type = t_untyped_undef;
			} else if (!is_type_untyped_nil(operand->type) || !type_has_nil(target_type)) {
				operand->mode = Addressing_Invalid;
				convert_untyped_error(c, operand, target_type);
				if (count > 0) {
					gb_printf_err("'%s' is a union which only excepts the following types:\n", type_str);
					gb_printf_err("\t");
					for (i32 i = 0; i < count; i++) {
						Type *v = t->Union.variants[i];
						if (i > 0 && count > 2) gb_printf_err(", ");
						if (i == count-1) {
							if (count == 2) gb_printf_err(" ");
							gb_printf_err("or ");
						}
						gbString str = type_to_string(v);
						gb_printf_err("'%s'", str);
						gb_string_free(str);
					}
					gb_printf_err("\n\n");

				}
				return;
			}
		}
		/* fallthrough */


	default:
		if (is_type_untyped_undef(operand->type) && type_has_undef(target_type)) {
			target_type = t_untyped_undef;
		} else if (is_type_untyped_nil(operand->type) && type_has_nil(target_type)) {
			target_type = t_untyped_nil;
		} else {
			operand->mode = Addressing_Invalid;
			convert_untyped_error(c, operand, target_type);
			return;
		}
		break;
	}

	operand->type = target_type;
	update_expr_type(c, operand->expr, target_type, true);
}

bool check_index_value(Checker *c, bool open_range, AstNode *index_value, i64 max_count, i64 *value) {
	Operand operand = {Addressing_Invalid};
	check_expr(c, &operand, index_value);
	if (operand.mode == Addressing_Invalid) {
		if (value) *value = 0;
		return false;
	}

	convert_to_typed(c, &operand, t_int);
	if (operand.mode == Addressing_Invalid) {
		if (value) *value = 0;
		return false;
	}

	if (!is_type_integer(operand.type)) {
		gbString expr_str = expr_to_string(operand.expr);
		error(operand.expr, "Index '%s' must be an integer", expr_str);
		gb_string_free(expr_str);
		if (value) *value = 0;
		return false;
	}

	if (operand.mode == Addressing_Constant &&
	    (c->context.stmt_state_flags & StmtStateFlag_no_bounds_check) == 0) {
		i64 i = exact_value_to_integer(operand.value).value_integer;
		if (i < 0) {
			gbString expr_str = expr_to_string(operand.expr);
			error(operand.expr, "Index '%s' cannot be a negative value", expr_str);
			gb_string_free(expr_str);
			if (value) *value = 0;
			return false;
		}

		if (max_count >= 0) { // NOTE(bill): Do array bound checking
			if (value) *value = i;
			bool out_of_bounds = false;
			if (open_range) {
				out_of_bounds = i >= max_count;
			} else {
				out_of_bounds = i > max_count;
			}
			if (out_of_bounds) {
				gbString expr_str = expr_to_string(operand.expr);
				error(operand.expr, "Index '%s' is out of bounds range 0..<%lld", expr_str, max_count);
				gb_string_free(expr_str);
				return false;
			}


			return true;
		}
	}

	// NOTE(bill): It's alright :D
	if (value) *value = -1;
	return true;
}

Entity *check_selector(Checker *c, Operand *operand, AstNode *node, Type *type_hint) {
	ast_node(se, SelectorExpr, node);

	bool check_op_expr = true;
	Entity *expr_entity = nullptr;
	Entity *entity = nullptr;
	Selection sel = {}; // NOTE(bill): Not used if it's an import name

	operand->expr = node;

	AstNode *op_expr  = se->expr;
	AstNode *selector = unparen_expr(se->selector);
	if (selector == nullptr) {
		operand->mode = Addressing_Invalid;
		operand->expr = node;
		return nullptr;
	}

	if (selector->kind != AstNode_Ident && selector->kind != AstNode_BasicLit) {
	// if (selector->kind != AstNode_Ident) {
		error(selector, "Illegal selector kind: '%.*s'", LIT(ast_node_strings[selector->kind]));
		operand->mode = Addressing_Invalid;
		operand->expr = node;
		return nullptr;
	}

	if (op_expr->kind == AstNode_Ident) {
		String op_name = op_expr->Ident.token.string;
		Entity *e = scope_lookup_entity(c->context.scope, op_name);

		bool is_alias = false;
		while (e != nullptr && e->kind == Entity_Alias) {
			GB_ASSERT(e->Alias.base != nullptr);
			e = e->Alias.base;
			is_alias = true;
		}

		add_entity_use(c, op_expr, e);
		expr_entity = e;

		Entity *original_e = e;
		if (e != nullptr && e->kind == Entity_ImportName && selector->kind == AstNode_Ident) {
			// IMPORTANT NOTE(bill): This is very sloppy code but it's also very fragile
			// It pretty much needs to be in this order and this way
			// If you can clean this up, please do but be really careful
			String import_name = op_name;
			Scope *import_scope = e->ImportName.scope;
			String entity_name = selector->Ident.token.string;

			check_op_expr = false;
			entity = scope_lookup_entity(import_scope, entity_name);
			bool is_declared = entity != nullptr;
			if (is_declared) {
				if (entity->kind == Entity_Builtin) {
					// NOTE(bill): Builtin's are in the universal scope which is part of every scopes hierarchy
					// This means that we should just ignore the found result through it
					is_declared = false;
				} else if (entity->scope->is_global && !import_scope->is_global) {
					is_declared = false;
				}
			}
			if (!is_declared) {
				error(op_expr, "'%.*s' is not declared by '%.*s'", LIT(entity_name), LIT(import_name));
				operand->mode = Addressing_Invalid;
				operand->expr = node;
				return nullptr;
			}


			bool is_alias = false;
			while (entity->kind == Entity_Alias) {
				GB_ASSERT(e->Alias.base != nullptr);
				entity = entity->Alias.base;
				is_alias = true;
			}

			check_entity_decl(c, entity, nullptr, nullptr);
			GB_ASSERT(entity->type != nullptr);


			if (is_alias) {
				// TODO(bill): Which scope do you search for for an alias?
				// import_scope = entity->scope;
				entity_name = entity->token.string;
			}


			bool implicit_is_found = is_entity_implicitly_imported(e, entity);
			bool is_not_exported = !is_entity_exported(entity);
			if (entity->kind == Entity_ImportName) {
				is_not_exported = true;
			} else if (implicit_is_found) {
				is_not_exported = true;
			}



			if (is_not_exported) {
				gbString sel_str = expr_to_string(selector);
				error(op_expr, "'%s' is not exported by '%.*s'", sel_str, LIT(import_name));
				gb_string_free(sel_str);
				operand->mode = Addressing_Invalid;
				operand->expr = node;
				return nullptr;
			}

			if (entity->kind == Entity_ProcGroup) {
				Array<Entity *> procs = entity->ProcGroup.entities;
				bool skip = false;
				for_array(i, procs) {
					Entity *p = procs[i];
					Type *t = base_type(p->type);
					if (t == t_invalid) {
						continue;
					}

					Operand x = {};
					x.mode = Addressing_Value;
					x.type = t;
					if (type_hint != nullptr) {
						if (check_is_assignable_to(c, &x, type_hint)) {
							entity = p;
							skip = true;
							break;
						}
					}
				}

				if (!skip) {
					GB_ASSERT(entity != nullptr);
					operand->mode       = Addressing_ProcGroup;
					operand->type       = t_invalid;
					operand->expr       = node;
					operand->proc_group = entity;
					return entity;
				}
			}
		}
	}

	if (check_op_expr) {
		check_expr_base(c, operand, op_expr, nullptr);
		if (operand->mode == Addressing_Invalid) {
			operand->mode = Addressing_Invalid;
			operand->expr = node;
			return nullptr;
		}
	}


	if (entity == nullptr && selector->kind == AstNode_Ident) {
		String field_name = selector->Ident.token.string;
		sel = lookup_field(operand->type, field_name, operand->mode == Addressing_Type);
		entity = sel.entity;

		// NOTE(bill): Add type info needed for fields like 'names'
		if (entity != nullptr && (entity->flags&EntityFlag_TypeField)) {
			add_type_info_type(c, operand->type);
		}
		if (is_type_enum(operand->type)) {
			add_type_info_type(c, operand->type);
		}
	}
	if (entity == nullptr && selector->kind == AstNode_BasicLit) {
		if (is_type_struct(operand->type) || is_type_tuple(operand->type)) {
			Type *type = base_type(operand->type);
			Operand o = {};
			check_expr(c, &o, selector);
			if (o.mode != Addressing_Constant ||
			    !is_type_integer(o.type)) {
				error(op_expr, "Indexed based selectors must be a constant integer %s");
				operand->mode = Addressing_Invalid;
				operand->expr = node;
				return nullptr;
			}
			i64 index = o.value.value_integer;
			if (index < 0) {
				error(o.expr, "Index %lld cannot be a negative value", index);
				operand->mode = Addressing_Invalid;
				operand->expr = node;
				return nullptr;
			}

			i64 max_count = 0;
			switch (type->kind) {
			case Type_Struct: max_count = type->Struct.fields.count;   break;
			case Type_Tuple:  max_count = type->Tuple.variables.count; break;
			}

			if (index >= max_count) {
				error(o.expr, "Index %lld is out of bounds range 0..<%lld", index, max_count);
				operand->mode = Addressing_Invalid;
				operand->expr = node;
				return nullptr;
			}

			sel = lookup_field_from_index(type, index);
			entity = sel.entity;

			GB_ASSERT(entity != nullptr);

		} else {
			error(op_expr, "Indexed based selectors may only be used on structs or tuples");
			operand->mode = Addressing_Invalid;
			operand->expr = node;
			return nullptr;
		}
	}

	if (entity == nullptr &&
	    operand->type != nullptr && is_type_untyped(operand->type) && is_type_string(operand->type)) {
		String s = operand->value.value_string;
		operand->mode = Addressing_Constant;
		operand->value = exact_value_i64(s.len);
		operand->type = t_untyped_integer;
		return nullptr;
	}

	if (entity == nullptr) {
		gbString op_str   = expr_to_string(op_expr);
		gbString type_str = type_to_string(operand->type);
		gbString sel_str  = expr_to_string(selector);
		error(op_expr, "'%s' of type '%s' has no field '%s'", op_str, type_str, sel_str);
		gb_string_free(sel_str);
		gb_string_free(type_str);
		gb_string_free(op_str);
		operand->mode = Addressing_Invalid;
		operand->expr = node;
		return nullptr;
	}

	if (expr_entity != nullptr && expr_entity->kind == Entity_Constant && entity->kind != Entity_Constant) {
		gbString op_str   = expr_to_string(op_expr);
		gbString type_str = type_to_string(operand->type);
		gbString sel_str  = expr_to_string(selector);
		error(op_expr, "Cannot access non-constant field '%s' from '%s'", sel_str, op_str);
		gb_string_free(sel_str);
		gb_string_free(type_str);
		gb_string_free(op_str);
		operand->mode = Addressing_Invalid;
		operand->expr = node;
		return nullptr;
	}



	add_entity_use(c, selector, entity);

	switch (entity->kind) {
	case Entity_Constant:
		operand->mode = Addressing_Constant;
		operand->value = entity->Constant.value;
		break;
	case Entity_Variable:
		// TODO(bill): Is this the rule I need?
		if (operand->mode == Addressing_Immutable) {
			// Okay
		} else if (sel.indirect || operand->mode != Addressing_Value) {
			operand->mode = Addressing_Variable;
		} else {
			operand->mode = Addressing_Value;
		}
		break;
	case Entity_TypeName:
		operand->mode = Addressing_Type;
		break;
	case Entity_Procedure:
		operand->mode = Addressing_Value;
		break;
	case Entity_Builtin:
		operand->mode = Addressing_Builtin;
		operand->builtin_id = cast(BuiltinProcId)entity->Builtin.id;
		break;

	case Entity_ProcGroup:
		operand->mode = Addressing_ProcGroup;
		operand->proc_group = entity;
		break;

	// NOTE(bill): These cases should never be hit but are here for sanity reasons
	case Entity_Nil:
		operand->mode = Addressing_Value;
		break;
	}

	operand->type = entity->type;
	operand->expr = node;

	return entity;
}

bool check_builtin_procedure(Checker *c, Operand *operand, AstNode *call, i32 id) {
	GB_ASSERT(call->kind == AstNode_CallExpr);
	ast_node(ce, CallExpr, call);
	BuiltinProc *bp = &builtin_procs[id];
	{
		char *err = nullptr;
		if (ce->args.count < bp->arg_count) {
			err = "Too few";
		} else if (ce->args.count > bp->arg_count && !bp->variadic) {
			err = "Too many";
		}

		if (err != nullptr) {
			gbString expr = expr_to_string(ce->proc);
			error(ce->close, "%s arguments for '%s', expected %td, got %td",
			      err, expr,
			      bp->arg_count, ce->args.count);
			gb_string_free(expr);
			return false;
		}
	}

	if (ce->args.count > 0) {
		if (ce->args[0]->kind == AstNode_FieldValue) {
			error(call, "'field = value' calling is not allowed on built-in procedures");
			return false;
		}
	}


	bool vari_expand = (ce->ellipsis.pos.line != 0);
	// if (vari_expand && id != BuiltinProc_append) {
		// error(ce->ellipsis, "Invalid use of '...' with built-in procedure 'append'");
		// return false;
	// }


	switch (id) {
	// case BuiltinProc_new:
	case BuiltinProc_make:
	case BuiltinProc_size_of:
	case BuiltinProc_align_of:
	case BuiltinProc_offset_of:
	case BuiltinProc_type_info_of:
		// NOTE(bill): The first arg may be a Type, this will be checked case by case
		break;
	default:
		if (ce->args.count > 0) {
			check_multi_expr(c, operand, ce->args[0]);
		}
		break;
	}

	switch (id) {
	default:
		GB_PANIC("Implement built-in procedure: %.*s", LIT(builtin_procs[id].name));
		break;

	case BuiltinProc_DIRECTIVE: {
		ast_node(bd, BasicDirective, ce->proc);
		String name = bd->name;
		if (name == "location") {
			if (ce->args.count > 1) {
				error(ce->args[0], "'#location' expects either 0 or 1 arguments, got %td", ce->args.count);
			}
			if (ce->args.count > 0) {
				AstNode *arg = ce->args[0];
				Entity *e = nullptr;
				Operand o = {};
				if (arg->kind == AstNode_Ident) {
					e = check_ident(c, &o, arg, nullptr, nullptr, true);
				} else if (arg->kind == AstNode_SelectorExpr) {
					e = check_selector(c, &o, arg, nullptr);
				}
				if (e == nullptr) {
					error(ce->args[0], "'#location' expected a valid entity name");
				}
			}

			operand->type = t_source_code_location;
			operand->mode = Addressing_Value;
		} else if (name == "assert") {
			if (ce->args.count != 1) {
				error(call, "'#assert' expects at 1 argument, got %td", ce->args.count);
				return false;
			}
			if (!is_type_boolean(operand->type) && operand->mode != Addressing_Constant) {
				gbString str = expr_to_string(ce->args[0]);
				error(call, "'%s' is not a constant boolean", str);
				gb_string_free(str);
				return false;
			}
			if (!operand->value.value_bool) {
				gbString arg = expr_to_string(ce->args[0]);
				error(call, "Compile time assertion: %s", arg);
				gb_string_free(arg);
			}

			operand->type = t_untyped_bool;
			operand->mode = Addressing_Constant;
		} else {
			GB_PANIC("Unhandled #%.*s", LIT(name));
		}

		break;
	}

	case BuiltinProc_len:
	case BuiltinProc_cap: {
		// proc len(Type) -> int
		// proc cap(Type) -> int
		Type *op_type = type_deref(operand->type);
		Type *type = t_int;
		AddressingMode mode = Addressing_Invalid;
		ExactValue value = {};
		if (is_type_string(op_type) && id == BuiltinProc_len) {
			if (operand->mode == Addressing_Constant) {
				mode = Addressing_Constant;
				String str = operand->value.value_string;
				value = exact_value_i64(str.len);
				type = t_untyped_integer;
			} else {
				mode = Addressing_Value;
			}
		} else if (is_type_array(op_type)) {
			Type *at = core_type(op_type);
			mode = Addressing_Constant;
			value = exact_value_i64(at->Array.count);
			type = t_untyped_integer;
		} else if (is_type_slice(op_type) && id == BuiltinProc_len) {
			mode = Addressing_Value;
		} else if (is_type_dynamic_array(op_type)) {
			mode = Addressing_Value;
		} else if (is_type_map(op_type)) {
			mode = Addressing_Value;
		}

		if (mode == Addressing_Invalid) {
			String name = builtin_procs[id].name;
			gbString t = type_to_string(operand->type);
			error(call, "'%.*s' is not supported for '%s'", LIT(name), t);
			return false;
		}

		operand->mode  = mode;
		operand->value = value;
		operand->type  = type;

		break;
	}

	#if 0
	case BuiltinProc_new: {
		// proc new(Type) -> ^Type
		Operand op = {};
		check_expr_or_type(c, &op, ce->args[0]);
		Type *type = op.type;
		if ((op.mode != Addressing_Type && type == nullptr) || type == t_invalid) {
			error(ce->args[0], "Expected a type for 'new'");
			return false;
		}
		operand->mode = Addressing_Value;
		operand->type = alloc_type_pointer(type);

		break;
	}
	#endif
	#if 0
	case BuiltinProc_new_slice: {
		// proc new_slice(Type, len: int) -> []Type
		// proc new_slice(Type, len, cap: int) -> []Type
		Operand op = {};
		check_expr_or_type(c, &op, ce->args[0]);
		Type *type = op.type;
		if ((op.mode != Addressing_Type && type == nullptr) || type == t_invalid) {
			error(ce->args[0], "Expected a type for 'new_slice'");
			return false;
		}

		isize arg_count = ce->args.count;
		if (arg_count < 2 || 3 < arg_count) {
			error(ce->args[0], "'new_slice' expects 2 or 3 arguments, found %td", arg_count);
			// NOTE(bill): Return the correct type to reduce errors
		} else {
			// If any are constant
			i64 sizes[2] = {};
			isize size_count = 0;
			for (isize i = 1; i < arg_count; i++) {
				i64 val = 0;
				bool ok = check_index_value(c, ce->args[i], -1, &val);
				if (ok && val >= 0) {
					GB_ASSERT(size_count < gb_count_of(sizes));
					sizes[size_count++] = val;
				}
			}

			if (size_count == 2 && sizes[0] > sizes[1]) {
				error(ce->args[1], "'new_slice' count and capacity are swapped");
				// No need quit
			}
		}

		operand->mode = Addressing_Value;
		operand->type = alloc_type_slice(type);

		break;
	}
	#endif
	case BuiltinProc_make: {
		// proc make(Type, len: int) -> Type
		// proc make(Type, len, cap: int) -> Type
		Operand op = {};
		check_expr_or_type(c, &op, ce->args[0]);
		Type *type = op.type;
		if ((op.mode != Addressing_Type && type == nullptr) || type == t_invalid) {
			error(ce->args[0], "Expected a type for 'make'");
			return false;
		}

		isize min_args = 0;
		isize max_args = 1;
		if (is_type_slice(type)) {
			min_args = 2;
			max_args = 2;
		} else if (is_type_map(type)) {
			min_args = 1;
			max_args = 2;
		} else if (is_type_dynamic_array(type)) {
			min_args = 1;
			max_args = 3;
		} else {
			gbString str = type_to_string(type);
			error(call, "Cannot 'make' %s; type must be a slice, map, or dynamic array", str);
			gb_string_free(str);
			return false;
		}

		isize arg_count = ce->args.count;
		if (arg_count < min_args || max_args < arg_count) {
			error(ce->args[0], "'make' expects %td or %d argument, found %td", min_args, max_args, arg_count);
			return false;
		}

		// If any are constant
		i64 sizes[4] = {};
		isize size_count = 0;
		for (isize i = 1; i < arg_count; i++) {
			i64 val = 0;
			bool ok = check_index_value(c, false, ce->args[i], -1, &val);
			if (ok && val >= 0) {
				GB_ASSERT(size_count < gb_count_of(sizes));
				sizes[size_count++] = val;
			}
		}

		if (size_count == 2 && sizes[0] > sizes[1]) {
			error(ce->args[1], "'make' count and capacity are swapped");
			// No need quit
		}

		operand->mode = Addressing_Value;
		operand->type = type;

		break;
	}

	#if 0
	case BuiltinProc_free: {
		// proc free(^Type)
		// proc free([]Type)
		// proc free(string)
		// proc free(map[K]T)
		Type *type = operand->type;
		bool ok = false;
		if (is_type_pointer(type)) {
			ok = true;
		} else if (is_type_slice(type)) {
			ok = true;
		} else if (is_type_string(type)) {
			ok = true;
		} else if (is_type_dynamic_array(type)) {
			ok = true;
		} else if (is_type_dynamic_map(type)) {
			ok = true;
		}

		if (!ok) {
			gbString type_str = type_to_string(type);
			error(operand->expr, "Invalid type for 'free', got '%s'", type_str);
			gb_string_free(type_str);
			return false;
		}


		operand->mode = Addressing_NoValue;

		break;
	}
	#endif


	#if 0
	case BuiltinProc_reserve: {
		// proc reserve([dynamic]Type, count: int) {
		// proc reserve(map[Key]Type, count: int) {
		Type *type = operand->type;
		if (!is_type_dynamic_array(type) && !is_type_dynamic_map(type)) {
			gbString str = type_to_string(type);
			error(operand->expr, "Expected a dynamic array or dynamic map, got '%s'", str);
			gb_string_free(str);
			return false;
		}

		AstNode *capacity = ce->args[1];
		Operand op = {};
		check_expr(c, &op, capacity);
		if (op.mode == Addressing_Invalid) {
			return false;
		}
		Type *arg_type = base_type(op.type);
		if (!is_type_integer(arg_type)) {
			error(operand->expr, "'reserve' capacities must be an integer");
			return false;
		}

		operand->type = nullptr;
		operand->mode = Addressing_NoValue;

		break;
	}
	#endif
	#if 0
	case BuiltinProc_clear: {
		Type *type = operand->type;
		bool is_pointer = is_type_pointer(type);
		type = base_type(type_deref(type));
		if (!is_type_dynamic_array(type) && !is_type_map(type) && !is_type_slice(type)) {
			gbString str = type_to_string(type);
			error(operand->expr, "Invalid type for 'clear', got '%s'", str);
			gb_string_free(str);
			return false;
		}

		operand->type = nullptr;
		operand->mode = Addressing_NoValue;

		break;
	}
	#endif
	#if 0
	case BuiltinProc_append: {
		// proc append([dynamic]Type, item: ..Type)
		// proc append([]Type, item: ..Type)
		Operand prev_operand = *operand;

		Type *type = operand->type;
		bool is_pointer = is_type_pointer(type);
		type = base_type(type_deref(type));
		if (!is_type_dynamic_array(type) && !is_type_slice(type)) {
			gbString str = type_to_string(type);
			error(operand->expr, "Expected a slice or dynamic array, got '%s'", str);
			gb_string_free(str);
			return false;
		}

		bool is_addressable = operand->mode == Addressing_Variable;
		if (is_pointer) {
			is_addressable = true;
		}
		if (!is_addressable) {
			error(operand->expr, "'append' can only operate on addressable values");
			return false;
		}

		Type *elem = nullptr;
		if (is_type_dynamic_array(type)) {
			elem = type->DynamicArray.elem;
		} else {
			elem = type->Slice.elem;
		}
		Type *slice_elem = alloc_type_slice(elem);

		Type *proc_type_params = alloc_type_tuple(c->allocator);
		proc_type_params->Tuple.variables = gb_alloc_array(c->allocator, Entity *, 2);
		proc_type_params->Tuple.variable_count = 2;
		proc_type_params->Tuple.variables[0] = alloc_entity_param(c->allocator, nullptr, blank_token, operand->type, false, false);
		proc_type_params->Tuple.variables[1] = alloc_entity_param(c->allocator, nullptr, blank_token, slice_elem, false, false);
		Type *proc_type = alloc_type_proc(nullptr, proc_type_params, 2, nullptr, false, true, ProcCC_Odin);

		check_call_arguments(c, &prev_operand, proc_type, call);

		if (prev_operand.mode == Addressing_Invalid) {
			return false;
		}
		operand->mode = Addressing_Value;
		operand->type = t_int;

		break;
	}
	#endif
	#if 0
	case BuiltinProc_delete: {
		// proc delete(map[Key]Value, key: Key)
		Type *type = operand->type;
		if (!is_type_map(type)) {
			gbString str = type_to_string(type);
			error(operand->expr, "Expected a map, got '%s'", str);
			gb_string_free(str);
			return false;
		}

		Type *key = base_type(type)->Map.key;
		Operand x = {Addressing_Invalid};
		AstNode *key_node = ce->args[1];
		Operand op = {};
		check_expr(c, &op, key_node);
		if (op.mode == Addressing_Invalid) {
			return false;
		}

		if (!check_is_assignable_to(c, &op, key)) {
			gbString kt = type_to_string(key);
			gbString ot = type_to_string(op.type);
			error(operand->expr, "Expected a key of type '%s', got '%s'", key, ot);
			gb_string_free(ot);
			gb_string_free(kt);
			return false;
		}

		operand->mode = Addressing_NoValue;

		break;
	}
	#endif


	case BuiltinProc_size_of: {
		// proc size_of(Type or expr) -> untyped int
		Operand o = {};
		check_expr_or_type(c, &o, ce->args[0]);
		if (o.mode == Addressing_Invalid) {
			return false;
		}
		Type *t = o.type;
		if (t == nullptr || t == t_invalid) {
			error(ce->args[0], "Invalid argument for 'size_of'");
			return false;
		}
		t = default_type(t);

		operand->mode = Addressing_Constant;
		operand->value = exact_value_i64(type_size_of(t));
		operand->type = t_untyped_integer;

		break;
	}

	case BuiltinProc_align_of: {
		// proc align_of(Type or expr) -> untyped int
		Operand o = {};
		check_expr_or_type(c, &o, ce->args[0]);
		if (o.mode == Addressing_Invalid) {
			return false;
		}
		Type *t = o.type;
		if (t == nullptr || t == t_invalid) {
			error(ce->args[0], "Invalid argument for 'align_of'");
			return false;
		}
		t = default_type(t);

		operand->mode = Addressing_Constant;
		operand->value = exact_value_i64(type_align_of(t));
		operand->type = t_untyped_integer;

		break;
	}


	case BuiltinProc_offset_of: {
		// proc offset_of(Type, field) -> uintptr
		Operand op = {};
		Type *bt = check_type(c, ce->args[0]);
		Type *type = base_type(bt);
		if (type == nullptr || type == t_invalid) {
			error(ce->args[0], "Expected a type for 'offset_of'");
			return false;
		}

		AstNode *field_arg = unparen_expr(ce->args[1]);
		if (field_arg == nullptr ||
		    field_arg->kind != AstNode_Ident) {
			error(field_arg, "Expected an identifier for field argument");
			return false;
		}
		if (is_type_array(type)) {
			error(field_arg, "Invalid type for 'offset_of'");
			return false;
		}


		ast_node(arg, Ident, field_arg);
		Selection sel = lookup_field(type, arg->token.string, operand->mode == Addressing_Type);
		if (sel.entity == nullptr) {
			gbString type_str = type_to_string(bt);
			error(ce->args[0],
			      "'%s' has no field named '%.*s'", type_str, LIT(arg->token.string));
			gb_string_free(type_str);
			return false;
		}
		if (sel.indirect) {
			gbString type_str = type_to_string(bt);
			error(ce->args[0],
			      "Field '%.*s' is embedded via a pointer in '%s'", LIT(arg->token.string), type_str);
			gb_string_free(type_str);
			return false;
		}

		operand->mode = Addressing_Constant;
		operand->value = exact_value_i64(type_offset_of_from_selection(type, sel));
		operand->type  = t_uintptr;

		break;
	}


	case BuiltinProc_type_of: {
		// proc type_of(val: Type) -> type(Type)
		AstNode *expr = ce->args[0];
		Operand o = {};
		check_expr_or_type(c, &o, expr);

		// check_assignment(c, operand, nullptr, str_lit("argument of 'type_of'"));
		if (o.mode == Addressing_Invalid || o.mode == Addressing_Builtin) {
			return false;
		}
		if (o.type == nullptr || o.type == t_invalid) {
			error(o.expr, "Invalid argument to 'type_of'");
			return false;
		}
		if (o.type == nullptr || o.type == t_invalid) {
			error(o.expr, "Invalid argument to 'type_of'");
			return false;
		}
		// NOTE(bill): Prevent type cycles for procedure declarations
		if (c->context.curr_proc_sig == o.type) {
			gbString s = expr_to_string(o.expr);
			error(o.expr, "Invalid cyclic type usage from 'type_of', got '%s'", s);
			gb_string_free(s);
			return false;
		}

		if (is_type_polymorphic(o.type)) {
			error(o.expr, "'type_of' of polymorphic type cannot be determined");
			return false;
		}
		operand->mode = Addressing_Type;
		operand->type = o.type;
		break;
	}

	case BuiltinProc_type_info_of: {
		// proc type_info_of(Type) -> ^Type_Info
		if (c->context.scope->is_global) {
			compiler_error("'type_info_of' Cannot be declared within a #shared_global_scope due to how the internals of the compiler works");
		}

		// NOTE(bill): The type information may not be setup yet
		init_preload(c);
		AstNode *expr = ce->args[0];
		Operand o = {};
		check_expr_or_type(c, &o, expr);
		if (o.mode == Addressing_Invalid) {
			return false;
		}
		Type *t = o.type;
		if (t == nullptr || t == t_invalid || is_type_polymorphic(operand->type)) {
			error(ce->args[0], "Invalid argument for 'type_info_of'");
			return false;
		}
		t = default_type(t);

		add_type_info_type(c, t);

		operand->mode = Addressing_Value;
		operand->type = t_type_info_ptr;

		break;
	}

	case BuiltinProc_swizzle: {
		// proc swizzle(v: [N]T, ...int) -> [M]T
		Type *type = base_type(operand->type);
		if (!is_type_array(type)) {
			gbString type_str = type_to_string(operand->type);
			error(call,
			      "You can only 'swizzle' an array, got '%s'",
			      type_str);
			gb_string_free(type_str);
			return false;
		}

		i64 max_count = type->Array.count;
		Type *elem_type = type->Array.elem;

		i64 arg_count = 0;
		for_array(i, ce->args) {
			if (i == 0) {
				continue;
			}
			AstNode *arg = ce->args[i];
			Operand op = {};
			check_expr(c, &op, arg);
			if (op.mode == Addressing_Invalid) {
				return false;
			}
			Type *arg_type = base_type(op.type);
			if (!is_type_integer(arg_type) || op.mode != Addressing_Constant) {
				error(op.expr, "Indices to 'swizzle' must be constant integers");
				return false;
			}

			if (op.value.value_integer < 0) {
				error(op.expr, "Negative 'swizzle' index");
				return false;
			}

			if (max_count <= op.value.value_integer) {
				error(op.expr, "'swizzle' index exceeds length");
				return false;
			}

			arg_count++;
		}

		if (arg_count > max_count) {
			error(call, "Too many 'swizzle' indices, %td > %td", arg_count, max_count);
			return false;
		}

		if (arg_count < max_count) {
			operand->type = alloc_type_array(elem_type, arg_count);
		}
		operand->mode = Addressing_Value;

		break;
	}

	case BuiltinProc_complex: {
		// proc complex(real, imag: float_type) -> complex_type
		Operand x = *operand;
		Operand y = {};

		// NOTE(bill): Invalid will be the default till fixed
		operand->type = t_invalid;
		operand->mode = Addressing_Invalid;

		check_expr(c, &y, ce->args[1]);
		if (y.mode == Addressing_Invalid) {
			return false;
		}

		convert_to_typed(c, &x, y.type); if (x.mode == Addressing_Invalid) return false;
		convert_to_typed(c, &y, x.type); if (y.mode == Addressing_Invalid) return false;
		if (x.mode == Addressing_Constant &&
		    y.mode == Addressing_Constant) {
			if (is_type_numeric(x.type) && exact_value_imag(x.value).value_float == 0) {
				x.type = t_untyped_float;
			}
			if (is_type_numeric(y.type) && exact_value_imag(y.value).value_float == 0) {
				y.type = t_untyped_float;
			}
		}

		if (!are_types_identical(x.type, y.type)) {
			gbString tx = type_to_string(x.type);
			gbString ty = type_to_string(y.type);
			error(call, "Mismatched types to 'complex', '%s' vs '%s'", tx, ty);
			gb_string_free(ty);
			gb_string_free(tx);
			return false;
		}

		if (!is_type_float(x.type)) {
			gbString s = type_to_string(x.type);
			error(call, "Arguments have type '%s', expected a floating point", s);
			gb_string_free(s);
			return false;
		}

		if (x.mode == Addressing_Constant && y.mode == Addressing_Constant) {
			operand->value = exact_binary_operator_value(Token_Add, x.value, y.value);
			operand->mode = Addressing_Constant;
		} else {
			operand->mode = Addressing_Value;
		}

		BasicKind kind = core_type(x.type)->Basic.kind;
		switch (kind) {
		// case Basic_f16:          operand->type = t_complex32;       break;
		case Basic_f32:          operand->type = t_complex64;       break;
		case Basic_f64:          operand->type = t_complex128;      break;
		case Basic_UntypedFloat: operand->type = t_untyped_complex; break;
		default: GB_PANIC("Invalid type"); break;
		}

		break;
	}

	case BuiltinProc_real:
	case BuiltinProc_imag: {
		// proc real(x: type) -> float_type
		// proc imag(x: type) -> float_type

		Operand *x = operand;
		if (is_type_untyped(x->type)) {
			if (x->mode == Addressing_Constant) {
				if (is_type_numeric(x->type)) {
					x->type = t_untyped_complex;
				}
			} else {
				convert_to_typed(c, x, t_complex128);
				if (x->mode == Addressing_Invalid) {
					return false;
				}
			}
		}

		if (!is_type_complex(x->type)) {
			gbString s = type_to_string(x->type);
			error(call, "Argument has type '%s', expected a complex type", s);
			gb_string_free(s);
			return false;
		}

		if (x->mode == Addressing_Constant) {
			switch (id) {
			case BuiltinProc_real: x->value = exact_value_real(x->value); break;
			case BuiltinProc_imag: x->value = exact_value_imag(x->value); break;
			}
		} else {
			x->mode = Addressing_Value;
		}

		BasicKind kind = core_type(x->type)->Basic.kind;
		switch (kind) {
		case Basic_complex64:         x->type = t_f32;           break;
		case Basic_complex128:        x->type = t_f64;           break;
		case Basic_UntypedComplex:    x->type = t_untyped_float; break;
		default: GB_PANIC("Invalid type"); break;
		}

		break;
	}

	case BuiltinProc_conj: {
		// proc conj(x: type) -> type
		Operand *x = operand;
		if (is_type_complex(x->type)) {
			if (x->mode == Addressing_Constant) {
				ExactValue v = exact_value_to_complex(x->value);
				f64 r = v.value_complex.real;
				f64 i = v.value_complex.imag;
				x->value = exact_value_complex(r, i);
				x->mode = Addressing_Constant;
			} else {
				x->mode = Addressing_Value;
			}
		} else {
			gbString s = type_to_string(x->type);
			error(call, "Expected a complex or quaternion, got '%s'", s);
			gb_string_free(s);
			return false;
		}


break;
	}

	#if 0
	case BuiltinProc_slice_ptr: {
		// proc slice_ptr(a: ^T, len: int) -> []T
		// proc slice_ptr(a: ^T, len, cap: int) -> []T
		// ^T cannot be rawptr
		Type *ptr_type = base_type(operand->type);
		if (!is_type_pointer(ptr_type)) {
			gbString type_str = type_to_string(operand->type);
			error(call, "Expected a pointer to 'slice_ptr', got '%s'", type_str);
			gb_string_free(type_str);
			return false;
		}

		if (ptr_type == t_rawptr) {
			error(call, "'rawptr' cannot have pointer arithmetic");
			return false;
		}

		isize arg_count = ce->args.count;
		if (arg_count < 2 || 3 < arg_count) {
			error(ce->args[0], "'slice_ptr' expects 2 or 3 arguments, found %td", arg_count);
			// NOTE(bill): Return the correct type to reduce errors
		} else {
			// If any are constant
			i64 sizes[2] = {};
			isize size_count = 0;
			for (isize i = 1; i < arg_count; i++) {
				i64 val = 0;
				bool ok = check_index_value(c, false, ce->args[i], -1, &val);
				if (ok && val >= 0) {
					GB_ASSERT(size_count < gb_count_of(sizes));
					sizes[size_count++] = val;
				}
			}

			if (size_count == 2 && sizes[0] > sizes[1]) {
				error(ce->args[1], "'slice_ptr' count and capacity are swapped");
				// No need quit
			}
		}
		operand->type = alloc_type_slice(ptr_type->Pointer.elem);
		operand->mode = Addressing_Value;

		break;
	}

	case BuiltinProc_slice_to_bytes: {
		// proc slice_to_bytes(a: []T) -> []u8
		Type *slice_type = base_type(operand->type);
		if (!is_type_slice(slice_type)) {
			gbString type_str = type_to_string(operand->type);
			error(call, "Expected a slice type, got '%s'", type_str);
			gb_string_free(type_str);
			return false;
		}

		operand->type = t_u8_slice;
		operand->mode = Addressing_Value;

		break;
	}
	#endif
	case BuiltinProc_expand_to_tuple: {
		Type *type = base_type(operand->type);
		if (!is_type_struct(type) &
		    !is_type_union(type)) {
			gbString type_str = type_to_string(operand->type);
			error(call, "Expected a struct or union type, got '%s'", type_str);
			gb_string_free(type_str);
			return false;
		}
		gbAllocator a = c->allocator;

		Type *tuple = alloc_type_tuple();
		isize variable_count = type->Struct.fields.count;
		array_init(&tuple->Tuple.variables, a, variable_count);
		// TODO(bill): Should I copy each of the entities or is this good enough?
		gb_memcopy_array(tuple->Tuple.variables.data, type->Struct.fields.data, variable_count);

		operand->type = tuple;
		operand->mode = Addressing_Value;

		break;
	}

	case BuiltinProc_min: {
		// proc min(a, b: ordered) -> ordered
		Type *type = base_type(operand->type);
		if (!is_type_ordered(type) || !(is_type_numeric(type) || is_type_string(type))) {
			gbString type_str = type_to_string(operand->type);
			error(call, "Expected a ordered numeric type to 'min', got '%s'", type_str);
			gb_string_free(type_str);
			return false;
		}

		AstNode *other_arg = ce->args[1];
		Operand a = *operand;
		Operand b = {};
		check_expr(c, &b, other_arg);
		if (b.mode == Addressing_Invalid) {
			return false;
		}
		if (!is_type_ordered(b.type) || !(is_type_numeric(b.type) || is_type_string(b.type))) {
			gbString type_str = type_to_string(b.type);
			error(call,
			      "Expected a ordered numeric type to 'min', got '%s'",
			      type_str);
			gb_string_free(type_str);
			return false;
		}

		if (a.mode == Addressing_Constant &&
		    b.mode == Addressing_Constant) {
			ExactValue x = a.value;
			ExactValue y = b.value;

			operand->mode = Addressing_Constant;
			if (compare_exact_values(Token_Lt, x, y)) {
				operand->value = x;
				operand->type = a.type;
			} else {
				operand->value = y;
				operand->type = b.type;
			}
		} else {
			operand->mode = Addressing_Value;
			operand->type = type;

			convert_to_typed(c, &a, b.type);
			if (a.mode == Addressing_Invalid) {
				return false;
			}
			convert_to_typed(c, &b, a.type);
			if (b.mode == Addressing_Invalid) {
				return false;
			}

			if (!are_types_identical(a.type, b.type)) {
				gbString type_a = type_to_string(a.type);
				gbString type_b = type_to_string(b.type);
				error(call,
				      "Mismatched types to 'min', '%s' vs '%s'",
				      type_a, type_b);
				gb_string_free(type_b);
				gb_string_free(type_a);
				return false;
			}
		}


break;
	}

	case BuiltinProc_max: {
		// proc min(a, b: ordered) -> ordered
		Type *type = base_type(operand->type);
		if (!is_type_ordered(type) || !(is_type_numeric(type) || is_type_string(type))) {
			gbString type_str = type_to_string(operand->type);
			error(call,
			      "Expected a ordered numeric or string type to 'max', got '%s'",
			      type_str);
			gb_string_free(type_str);
			return false;
		}

		AstNode *other_arg = ce->args[1];
		Operand a = *operand;
		Operand b = {};
		check_expr(c, &b, other_arg);
		if (b.mode == Addressing_Invalid) {
			return false;
		}
		if (!is_type_ordered(b.type) || !(is_type_numeric(b.type) || is_type_string(b.type))) {
			gbString type_str = type_to_string(b.type);
			error(call,
			      "Expected a ordered numeric or string type to 'max', got '%s'",
			      type_str);
			gb_string_free(type_str);
			return false;
		}

		if (a.mode == Addressing_Constant &&
		    b.mode == Addressing_Constant) {
			ExactValue x = a.value;
			ExactValue y = b.value;

			operand->mode = Addressing_Constant;
			if (compare_exact_values(Token_Gt, x, y)) {
				operand->value = x;
				operand->type = a.type;
			} else {
				operand->value = y;
				operand->type = b.type;
			}
		} else {
			operand->mode = Addressing_Value;
			operand->type = type;

			convert_to_typed(c, &a, b.type);
			if (a.mode == Addressing_Invalid) {
				return false;
			}
			convert_to_typed(c, &b, a.type);
			if (b.mode == Addressing_Invalid) {
				return false;
			}

			if (!are_types_identical(a.type, b.type)) {
				gbString type_a = type_to_string(a.type);
				gbString type_b = type_to_string(b.type);
				error(call,
				      "Mismatched types to 'max', '%s' vs '%s'",
				      type_a, type_b);
				gb_string_free(type_b);
				gb_string_free(type_a);
				return false;
			}
		}


break;
	}

	case BuiltinProc_abs: {
		// proc abs(n: numeric) -> numeric
		if (!is_type_numeric(operand->type)) {
			gbString type_str = type_to_string(operand->type);
			error(call, "Expected a numeric type to 'abs', got '%s'", type_str);
			gb_string_free(type_str);
			return false;
		}

		if (operand->mode == Addressing_Constant) {
			switch (operand->value.kind) {
			case ExactValue_Integer:
				operand->value.value_integer = gb_abs(operand->value.value_integer);
				break;
			case ExactValue_Float:
				operand->value.value_float = gb_abs(operand->value.value_float);
				break;
			case ExactValue_Complex: {
				f64 r = operand->value.value_complex.real;
				f64 i = operand->value.value_complex.imag;
				operand->value = exact_value_float(gb_sqrt(r*r + i*i));

				break;
			}
			default:
				GB_PANIC("Invalid numeric constant");
				break;
			}
		} else {
			operand->mode = Addressing_Value;
		}

		if (is_type_complex(operand->type)) {
			operand->type = base_complex_elem_type(operand->type);
		}
		GB_ASSERT(!is_type_complex(operand->type));

		break;
	}

	case BuiltinProc_clamp: {
		// proc clamp(a, min, max: ordered) -> ordered
		Type *type = base_type(operand->type);
		if (!is_type_ordered(type) || !(is_type_numeric(type) || is_type_string(type))) {
			gbString type_str = type_to_string(operand->type);
			error(call, "Expected a ordered numeric or string type to 'clamp', got '%s'", type_str);
			gb_string_free(type_str);
			return false;
		}

		AstNode *min_arg = ce->args[1];
		AstNode *max_arg = ce->args[2];
		Operand x = *operand;
		Operand y = {};
		Operand z = {};

		check_expr(c, &y, min_arg);
		if (y.mode == Addressing_Invalid) {
			return false;
		}
		if (!is_type_ordered(y.type) || !(is_type_numeric(y.type) || is_type_string(y.type))) {
			gbString type_str = type_to_string(y.type);
			error(call, "Expected a ordered numeric or string type to 'clamp', got '%s'", type_str);
			gb_string_free(type_str);
			return false;
		}

		check_expr(c, &z, max_arg);
		if (z.mode == Addressing_Invalid) {
			return false;
		}
		if (!is_type_ordered(z.type) || !(is_type_numeric(z.type) || is_type_string(z.type))) {
			gbString type_str = type_to_string(z.type);
			error(call, "Expected a ordered numeric or string type to 'clamp', got '%s'", type_str);
			gb_string_free(type_str);
			return false;
		}

		if (x.mode == Addressing_Constant &&
		    y.mode == Addressing_Constant &&
		    z.mode == Addressing_Constant) {
			ExactValue a = x.value;
			ExactValue b = y.value;
			ExactValue c = z.value;

			operand->mode = Addressing_Constant;
			if (compare_exact_values(Token_Lt, a, b)) {
				operand->value = b;
				operand->type = y.type;
			} else if (compare_exact_values(Token_Gt, a, c)) {
				operand->value = c;
				operand->type = z.type;
			} else {
				operand->value = a;
				operand->type = x.type;
			}
		} else {
			operand->mode = Addressing_Value;
			operand->type = type;

			convert_to_typed(c, &x, y.type);
			if (x.mode == Addressing_Invalid) { return false; }
			convert_to_typed(c, &y, x.type);
			if (y.mode == Addressing_Invalid) { return false; }
			convert_to_typed(c, &x, z.type);
			if (x.mode == Addressing_Invalid) { return false; }
			convert_to_typed(c, &z, x.type);
			if (z.mode == Addressing_Invalid) { return false; }
			convert_to_typed(c, &y, z.type);
			if (y.mode == Addressing_Invalid) { return false; }
			convert_to_typed(c, &z, y.type);
			if (z.mode == Addressing_Invalid) { return false; }

			if (!are_types_identical(x.type, y.type) || !are_types_identical(x.type, z.type)) {
				gbString type_x = type_to_string(x.type);
				gbString type_y = type_to_string(y.type);
				gbString type_z = type_to_string(z.type);
				error(call,
				      "Mismatched types to 'clamp', '%s', '%s', '%s'",
				      type_x, type_y, type_z);
				gb_string_free(type_z);
				gb_string_free(type_y);
				gb_string_free(type_x);
				return false;
			}
		}

		break;
	}

	#if 0
	case BuiltinProc_transmute: {
		Operand op = {};
		check_expr_or_type(c, &op, ce->args[0]);
		Type *t = op.type;
		if ((op.mode != Addressing_Type && t == nullptr) || t == t_invalid) {
			error(ce->args[0], "Expected a type for 'transmute'");
			return false;
		}
		AstNode *expr = ce->args[1];
		Operand *o = operand;
		check_expr(c, o, expr);
		if (o->mode == Addressing_Invalid) {
			return false;
		}

		if (o->mode == Addressing_Constant) {
			gbString expr_str = expr_to_string(o->expr);
			error(o->expr, "Cannot transmute a constant expression: '%s'", expr_str);
			gb_string_free(expr_str);
			o->mode = Addressing_Invalid;
			o->expr = expr;
			return false;
		}

		if (is_type_untyped(o->type)) {
			gbString expr_str = expr_to_string(o->expr);
			error(o->expr, "Cannot transmute untyped expression: '%s'", expr_str);
			gb_string_free(expr_str);
			o->mode = Addressing_Invalid;
			o->expr = expr;
			return false;
		}

		i64 srcz = type_size_of(o->type);
		i64 dstz = type_size_of(t);
		if (srcz != dstz) {
			gbString expr_str = expr_to_string(o->expr);
			gbString type_str = type_to_string(t);
			error(o->expr, "Cannot transmute '%s' to '%s', %lld vs %lld bytes", expr_str, type_str, srcz, dstz);
			gb_string_free(type_str);
			gb_string_free(expr_str);
			o->mode = Addressing_Invalid;
			o->expr = expr;
			return false;
		}

		o->mode = Addressing_Value;
		o->type = t;

		break;
	}
	#endif
	}

	return true;
}


isize add_dependencies_from_unpacking(Checker *c, Entity **lhs, isize lhs_count, isize tuple_index, isize tuple_count) {
	if (lhs != nullptr) {
		for (isize j = 0; (tuple_index + j) < lhs_count && j < tuple_count; j++) {
			Entity *e = lhs[tuple_index + j];
			DeclInfo *decl = decl_info_of_entity(&c->info, e);
			if (decl != nullptr) {
				c->context.decl = decl; // will be reset by the 'defer' any way
				for_array(k, decl->deps.entries) {
					Entity *dep = decl->deps.entries[k].ptr;
					add_declaration_dependency(c, dep); // TODO(bill): Should this be here?
				}
			}
		}
	}
	return tuple_count;
}


void check_unpack_arguments(Checker *c, Entity **lhs, isize lhs_count, Array<Operand> *operands, Array<AstNode *> rhs, bool allow_ok, bool *optional_ok_ = nullptr) {
	bool optional_ok = false;
	isize tuple_index = 0;
	for_array(i, rhs) {
		CheckerContext prev_context = c->context;
		defer (c->context = prev_context);

		Operand o = {};

		Type *type_hint = nullptr;

		if (lhs != nullptr && tuple_index < lhs_count) {
			// NOTE(bill): override DeclInfo for dependency
			Entity *e = lhs[tuple_index];
			DeclInfo *decl = decl_info_of_entity(&c->info, e);
			if (decl) c->context.decl = decl;
			type_hint = e->type;
		}

		check_expr_base(c, &o, rhs[i], type_hint);
		if (o.mode == Addressing_NoValue) {
			error_operand_no_value(&o);
			o.mode = Addressing_Invalid;
		}


		if (o.type == nullptr || o.type->kind != Type_Tuple) {
			if (allow_ok && lhs_count == 2 && rhs.count == 1 &&
			    (o.mode == Addressing_MapIndex || o.mode == Addressing_OptionalOk)) {
				Type *tuple = make_optional_ok_type(o.type);
				add_type_and_value(&c->info, o.expr, o.mode, tuple, o.value);

				Operand val = o;
				Operand ok = o;
				val.mode = Addressing_Value;
				ok.mode  = Addressing_Value;
				ok.type  = t_bool;
				array_add(operands, val);
				array_add(operands, ok);

				optional_ok = true;
				tuple_index += add_dependencies_from_unpacking(c, lhs, lhs_count, tuple_index, 2);
			} else {
				array_add(operands, o);
				tuple_index += 1;
			}
		} else {
			TypeTuple *tuple = &o.type->Tuple;
			for_array(j, tuple->variables) {
				o.type = tuple->variables[j]->type;
				array_add(operands, o);
			}

			isize count = tuple->variables.count;
			tuple_index += add_dependencies_from_unpacking(c, lhs, lhs_count, tuple_index, count);
		}
	}

	if (optional_ok_) *optional_ok_ = optional_ok;
}



CALL_ARGUMENT_CHECKER(check_call_arguments_internal) {
	ast_node(ce, CallExpr, call);
	GB_ASSERT(is_type_proc(proc_type));
	proc_type = base_type(proc_type);
	TypeProc *pt = &proc_type->Proc;

	isize param_count = 0;
	isize param_count_excluding_defaults = 0;
	bool variadic = pt->variadic;
	bool vari_expand = (ce->ellipsis.pos.line != 0);
	i64 score = 0;
	bool show_error = show_error_mode == CallArgumentMode_ShowErrors;


	TypeTuple *param_tuple = nullptr;

	if (pt->params != nullptr) {
		param_tuple = &pt->params->Tuple;

		param_count = param_tuple->variables.count;
		if (variadic) {
			for (isize i = param_count-1; i >= 0; i--) {
				Entity *e = param_tuple->variables[i];
				if (e->kind == Entity_TypeName) {
					break;
				}

				if (e->kind == Entity_Variable) {
					if (e->Variable.default_value.kind != ExactValue_Invalid ||
					    e->Variable.default_is_nil ||
					    e->Variable.default_is_location) {
						param_count--;
						continue;
					}
				}
				break;
			}
			param_count--;
		}
	}

	param_count_excluding_defaults = param_count;
	if (param_tuple != nullptr) {
		for (isize i = param_count-1; i >= 0; i--) {
			Entity *e = param_tuple->variables[i];
			if (e->kind == Entity_TypeName) {
				break;
			}

			if (e->kind == Entity_Variable) {
				if (e->Variable.default_value.kind != ExactValue_Invalid ||
				    e->Variable.default_is_nil ||
				    e->Variable.default_is_location) {
					param_count_excluding_defaults--;
					continue;
				}
			}
			break;
		}
	}

	CallArgumentError err = CallArgumentError_None;
	Type *final_proc_type = proc_type;
	Entity *gen_entity = nullptr;

	if (vari_expand && !variadic) {
		if (show_error) {
			error(ce->ellipsis,
			      "Cannot use '...' in call to a non-variadic procedure: '%.*s'",
			      LIT(ce->proc->Ident.token.string));
		}
		err = CallArgumentError_NonVariadicExpand;
	} else if (vari_expand && pt->c_vararg) {
		if (show_error) {
			error(ce->ellipsis,
			      "Cannot use '...' in call to a '#c_vararg' variadic procedure: '%.*s'",
			      LIT(ce->proc->Ident.token.string));
		}
		err = CallArgumentError_NonVariadicExpand;
	} else if (operands.count == 0 && param_count_excluding_defaults == 0) {
		err = CallArgumentError_None;
	} else {
		i32 error_code = 0;
		if (operands.count < param_count_excluding_defaults) {
			error_code = -1;
		} else if (!variadic && operands.count > param_count) {
			error_code = +1;
		}
		if (error_code != 0) {
			err = CallArgumentError_TooManyArguments;
			char *err_fmt = "Too many arguments for '%s', expected %td arguments";
			if (error_code < 0) {
				err = CallArgumentError_TooFewArguments;
				err_fmt = "Too few arguments for '%s', expected %td arguments";
			}

			if (show_error) {
				gbString proc_str = expr_to_string(ce->proc);
				error(call, err_fmt, proc_str, param_count_excluding_defaults);
				gb_string_free(proc_str);
			}
		} else {
			// NOTE(bill): Generate the procedure type for this generic instance
			PolyProcData poly_proc_data = {};

			if (pt->is_polymorphic && !pt->is_poly_specialized) {
				if (find_or_generate_polymorphic_procedure_from_parameters(c, entity, &operands, &poly_proc_data)) {
					gen_entity = poly_proc_data.gen_entity;
					GB_ASSERT(is_type_proc(gen_entity->type));
					final_proc_type = gen_entity->type;
				}
			}

			GB_ASSERT(is_type_proc(final_proc_type));
			TypeProc *pt = &final_proc_type->Proc;

			GB_ASSERT(pt->params != nullptr);
			auto sig_params = pt->params->Tuple.variables;
			isize operand_index = 0;
			isize max_operand_count = gb_min(param_count, operands.count);
			for (; operand_index < max_operand_count; operand_index++) {
				Entity *e = sig_params[operand_index];
				Type *t = e->type;
				Operand o = operands[operand_index];
				if (e->kind == Entity_TypeName) {
					// GB_ASSERT(!variadic);
					if (o.mode == Addressing_Invalid) {
						continue;
					} else if (o.mode != Addressing_Type) {
						if (show_error) {
							error(o.expr, "Expected a type for the argument '%.*s'", LIT(e->token.string));
						}
						err = CallArgumentError_WrongTypes;
					}

					if (are_types_identical(e->type, o.type)) {
						score += assign_score_function(1);
					} else {
						score += assign_score_function(10);
					}

					continue;
				}


				i64 s = 0;
				if (!check_is_assignable_to_with_score(c, &o, t, &s)) {
					if (show_error) {
						check_assignment(c, &o, t, str_lit("argument"));
					}
					err = CallArgumentError_WrongTypes;
				}
				score += s;
			}

			if (variadic) {
				bool variadic_expand = false;
				Type *slice = sig_params[param_count]->type;
				GB_ASSERT(is_type_slice(slice));
				Type *elem = base_type(slice)->Slice.elem;
				Type *t = elem;
				for (; operand_index < operands.count; operand_index++) {
					Operand o = operands[operand_index];
					if (vari_expand) {
						variadic_expand = true;
						t = slice;
						if (operand_index != param_count) {
							if (show_error) {
								error(o.expr, "'...' in a variadic procedure can only have one variadic argument at the end");
							}
							if (data) {
								data->score = score;
								data->result_type = final_proc_type->Proc.results;
								data->gen_entity = gen_entity;
							}
							return CallArgumentError_MultipleVariadicExpand;
						}
					}
					i64 s = 0;
					if (!check_is_assignable_to_with_score(c, &o, t, &s)) {
						if (show_error) {
							check_assignment(c, &o, t, str_lit("argument"));
						}
						err = CallArgumentError_WrongTypes;
					}
					score += s;
				}
			}
		}
	}

	if (data) {
		data->score = score;
		data->result_type = final_proc_type->Proc.results;
		data->gen_entity = gen_entity;
	}

	return err;
}

bool is_call_expr_field_value(AstNodeCallExpr *ce) {
	GB_ASSERT(ce != nullptr);

	if (ce->args.count == 0) {
		return false;
	}
	return ce->args[0]->kind == AstNode_FieldValue;
}

isize lookup_procedure_parameter(TypeProc *pt, String parameter_name) {
	isize param_count = pt->param_count;
	for (isize i = 0; i < param_count; i++) {
		Entity *e = pt->params->Tuple.variables[i];
		String name = e->token.string;
		if (is_blank_ident(name)) {
			continue;
		}
		if (name == parameter_name) {
			return i;
		}
	}
	return -1;
}
isize lookup_procedure_result(TypeProc *pt, String result_name) {
	isize result_count = pt->result_count;
	for (isize i = 0; i < result_count; i++) {
		Entity *e = pt->results->Tuple.variables[i];
		String name = e->token.string;
		if (is_blank_ident(name)) {
			continue;
		}
		if (name == result_name) {
			return i;
		}
	}
	return -1;
}

CALL_ARGUMENT_CHECKER(check_named_call_arguments) {
	ast_node(ce, CallExpr, call);
	GB_ASSERT(is_type_proc(proc_type));
	TypeProc *pt = &base_type(proc_type)->Proc;

	i64 score = 0;
	bool show_error = show_error_mode == CallArgumentMode_ShowErrors;
	CallArgumentError err = CallArgumentError_None;

	gbTempArenaMemory tmp = gb_temp_arena_memory_begin(&c->tmp_arena);
	defer (gb_temp_arena_memory_end(tmp));

	isize param_count = pt->param_count;
	bool *visited = gb_alloc_array(c->tmp_allocator, bool, param_count);

	auto ordered_operands = array_make<Operand>(c->tmp_allocator, param_count);

	for_array(i, ce->args) {
		AstNode *arg = ce->args[i];
		ast_node(fv, FieldValue, arg);
		if (fv->field->kind != AstNode_Ident) {
			if (show_error) {
				gbString expr_str = expr_to_string(fv->field);
				error(arg, "Invalid parameter name '%s' in procedure call", expr_str);
				gb_string_free(expr_str);
			}
			err = CallArgumentError_InvalidFieldValue;
			continue;
		}
		String name = fv->field->Ident.token.string;
		isize index = lookup_procedure_parameter(pt, name);
		if (index < 0) {
			if (show_error) {
				error(arg, "No parameter named '%.*s' for this procedure type", LIT(name));
			}
			err = CallArgumentError_ParameterNotFound;
			continue;
		}
		if (visited[index]) {
			if (show_error) {
				error(arg, "Duplicate parameter '%.*s' in procedure call", LIT(name));
			}
			err = CallArgumentError_DuplicateParameter;
			continue;
		}

		visited[index] = true;
		ordered_operands[index] = operands[i];
	}

	// NOTE(bill): Check for default values and missing parameters
	isize param_count_to_check = param_count;
	if (pt->variadic) {
		param_count_to_check--;
	}
	for (isize i = 0; i < param_count_to_check; i++) {
		if (!visited[i]) {
			Entity *e = pt->params->Tuple.variables[i];
			if (is_blank_ident(e->token)) {
				continue;
			}
			if (e->kind == Entity_Variable) {
				if (e->Variable.default_value.kind != ExactValue_Invalid) {
					score += assign_score_function(1);
					continue;
				} else if (e->Variable.default_is_nil) {
					score += assign_score_function(1);
					continue;
				}
			}

			if (show_error) {
				if (e->kind == Entity_TypeName) {
					error(call, "Type parameter '%.*s' is missing in procedure call",
					      LIT(e->token.string));
				} else if (e->kind == Entity_Constant && e->Constant.value.kind != ExactValue_Invalid) {
					// Ignore
				} else {
					gbString str = type_to_string(e->type);
					error(call, "Parameter '%.*s' of type '%s' is missing in procedure call",
					      LIT(e->token.string), str);
					gb_string_free(str);
				}
			}
			err = CallArgumentError_ParameterMissing;
		}
	}

	Entity *gen_entity = nullptr;
	if (pt->is_polymorphic && !pt->is_poly_specialized && err == CallArgumentError_None) {
		PolyProcData poly_proc_data = {};
		if (find_or_generate_polymorphic_procedure_from_parameters(c, entity, &ordered_operands, &poly_proc_data)) {
			gen_entity = poly_proc_data.gen_entity;
			Type *gept = base_type(gen_entity->type);
			GB_ASSERT(is_type_proc(gept));
			pt = &gept->Proc;
		}
	}


	for (isize i = 0; i < param_count; i++) {
		Operand *o = &ordered_operands[i];
		if (o->mode == Addressing_Invalid) {
			continue;
		}
		Entity *e = pt->params->Tuple.variables[i];

		if (e->kind == Entity_TypeName) {
			GB_ASSERT(pt->is_polymorphic);
			if (o->mode != Addressing_Type) {
				if (show_error) {
					error(o->expr, "Expected a type for the argument '%.*s'", LIT(e->token.string));
				}
				err = CallArgumentError_WrongTypes;
			}
			if (are_types_identical(e->type, o->type)) {
				score += assign_score_function(1);
			} else {
				score += assign_score_function(10);
			}
		} else {
			i64 s = 0;
			if (!check_is_assignable_to_with_score(c, o, e->type, &s)) {
				if (show_error) {
					check_assignment(c, o, e->type, str_lit("procedure argument"));
				}
				err = CallArgumentError_WrongTypes;
			}
			score += s;
		}
	}

	if (data) {
		data->score = score;
		data->result_type = pt->results;
		data->gen_entity = gen_entity;
	}

	return err;
}

CallArgumentData check_call_arguments(Checker *c, Operand *operand, Type *proc_type, AstNode *call) {
	ast_node(ce, CallExpr, call);

	CallArgumentCheckerType *call_checker = check_call_arguments_internal;
	Array<Operand> operands = {};
	defer (array_free(&operands));

	Type *result_type = t_invalid;

	if (is_call_expr_field_value(ce)) {
		call_checker = check_named_call_arguments;

		operands = array_make<Operand>(heap_allocator(), ce->args.count);
		for_array(i, ce->args) {
			AstNode *arg = ce->args[i];
			ast_node(fv, FieldValue, arg);
			check_expr_or_type(c, &operands[i], fv->value);
		}

		bool vari_expand = (ce->ellipsis.pos.line != 0);
		if (vari_expand) {
			// error(ce->ellipsis, "Invalid use of '...' with 'field = value' call'");
		}

	} else {
		operands = array_make<Operand>(heap_allocator(), 0, 2*ce->args.count);
		check_unpack_arguments(c, nullptr, -1, &operands, ce->args, false);
	}

	if (operand->mode == Addressing_ProcGroup) {
		check_entity_decl(c, operand->proc_group, nullptr, nullptr);

		Array<Entity *> procs = proc_group_entities(c, *operand);

		ValidIndexAndScore *valids         = gb_alloc_array(heap_allocator(), ValidIndexAndScore, procs.count);
		isize               valid_count    = 0;
		defer (gb_free(heap_allocator(), valids));

		gbString expr_name = expr_to_string(operand->expr);
		defer (gb_string_free(expr_name));

		for_array(i, procs) {
			Entity *p = procs[i];
			check_entity_decl(c, p, nullptr, nullptr);
			Type *pt = base_type(p->type);
			if (pt != nullptr && is_type_proc(pt)) {
				CallArgumentError err = CallArgumentError_None;
				CallArgumentData data = {};
				CheckerContext prev_context = c->context;
				defer (c->context = prev_context);
				c->context.no_polymorphic_errors = true;
				c->context.allow_polymorphic_types = is_type_polymorphic(pt);

				err = call_checker(c, call, pt, p, operands, CallArgumentMode_NoErrors, &data);

				if (err == CallArgumentError_None) {
					valids[valid_count].index = i;
					valids[valid_count].score = data.score;
					valid_count++;
				}
			}
		}

		if (valid_count > 1) {
			gb_sort_array(valids, valid_count, valid_index_and_score_cmp);
			i64 best_score = valids[0].score;
			Entity *best_entity = procs[valids[0].index];
			for (isize i = 1; i < valid_count; i++) {
				if (best_score > valids[i].score) {
					valid_count = i;
					break;
				}
				if (best_entity == procs[valids[i].index]) {
					valid_count = i;
					break;
				}
				best_score = valids[i].score;
			}
		}


		if (valid_count == 0) {
			error(operand->expr, "No procedures or ambiguous call for procedure group '%s' that match with the given arguments", expr_name);
			gb_printf_err("\tGiven argument types: (");
			for_array(i, operands) {
				Operand o = operands[i];
				if (i > 0) gb_printf_err(", ");
				gbString type = type_to_string(o.type);
				defer (gb_string_free(type));
				gb_printf_err("%s", type);
			}
			gb_printf_err(")\n");

			if (procs.count > 0) {
				gb_printf_err("Did you mean to use one of the following:\n");
			}
			for_array(i, procs) {
				Entity *proc = procs[i];
				TokenPos pos = proc->token.pos;
				Type *t = base_type(proc->type);
				if (t == t_invalid) continue;
				GB_ASSERT(t->kind == Type_Proc);
				gbString pt;
				defer (gb_string_free(pt));
				if (t->Proc.node != nullptr) {
					pt = expr_to_string(t->Proc.node);
				} else {
					pt = type_to_string(t);
				}
				String name = proc->token.string;

				char const *sep = "::";
				if (proc->kind == Entity_Variable) {
					sep = ":=";
				}
				// gb_printf_err("\t%.*s %s %s at %.*s(%td:%td) with score %lld\n", LIT(name), sep, pt, LIT(pos.file), pos.line, pos.column, cast(long long)valids[i].score);
				gb_printf_err("\t%.*s %s %s at %.*s(%td:%td)\n", LIT(name), sep, pt, LIT(pos.file), pos.line, pos.column);
			}
			if (procs.count > 0) {
				gb_printf_err("\n");
			}
			result_type = t_invalid;
		} else if (valid_count > 1) {
			error(operand->expr, "Ambiguous procedure group call '%s' that match with the given arguments", expr_name);
			gb_printf_err("\tGiven argument types: (");
			for_array(i, operands) {
				Operand o = operands[i];
				if (i > 0) gb_printf_err(", ");
				gbString type = type_to_string(o.type);
				defer (gb_string_free(type));
				gb_printf_err("%s", type);
			}
			gb_printf_err(")\n");

			for (isize i = 0; i < valid_count; i++) {
				Entity *proc = procs[valids[i].index];
				TokenPos pos = proc->token.pos;
				Type *t = base_type(proc->type); GB_ASSERT(t->kind == Type_Proc);
				gbString pt;
				defer (gb_string_free(pt));
				if (t->Proc.node != nullptr) {
					pt = expr_to_string(t->Proc.node);
				} else {
					pt = type_to_string(t);
				}
				String name = proc->token.string;
				char const *sep = "::";
				if (proc->kind == Entity_Variable) {
					sep = ":=";
				}
				gb_printf_err("\t%.*s %s %s at %.*s(%td:%td)\n", LIT(name), sep, pt, LIT(pos.file), pos.line, pos.column);
			}
			result_type = t_invalid;
		} else {
			AstNode *ident = operand->expr;
			while (ident->kind == AstNode_SelectorExpr) {
				AstNode *s = ident->SelectorExpr.selector;
				ident = s;
			}

			Entity *e = procs[valids[0].index];

			proc_type = e->type;
			CallArgumentData data = {};
			CallArgumentError err = call_checker(c, call, proc_type, e, operands, CallArgumentMode_ShowErrors, &data);
			Entity *entity_to_use = data.gen_entity != nullptr ? data.gen_entity : e;
			add_entity_use(c, ident, entity_to_use);
			return data;
		}
	} else {
		AstNode *ident = operand->expr;
		while (ident->kind == AstNode_SelectorExpr) {
			AstNode *s = ident->SelectorExpr.selector;
			ident = s;
		}

		Entity *e = entity_of_ident(&c->info, ident);
		CallArgumentData data = {};
		CallArgumentError err = call_checker(c, call, proc_type, e, operands, CallArgumentMode_ShowErrors, &data);
		Entity *entity_to_use = data.gen_entity != nullptr ? data.gen_entity : e;
		add_entity_use(c, ident, entity_to_use);
		return data;
	}

	CallArgumentData data = {};
	data.result_type = t_invalid;
	return data;
}


isize lookup_polymorphic_struct_parameter(TypeStruct *st, String parameter_name) {
	if (!st->is_polymorphic) return -1;

	TypeTuple *params = &st->polymorphic_params->Tuple;
	for_array(i, params->variables) {
		Entity *e = params->variables[i];
		String name = e->token.string;
		if (is_blank_ident(name)) {
			continue;
		}
		if (name == parameter_name) {
			return i;
		}
	}
	return -1;
}


CallArgumentError check_polymorphic_struct_type(Checker *c, Operand *operand, AstNode *call) {
	ast_node(ce, CallExpr, call);

	Type *original_type = operand->type;
	Type *struct_type = base_type(operand->type);
	GB_ASSERT(struct_type->kind == Type_Struct);
	TypeStruct *st = &struct_type->Struct;
	GB_ASSERT(st->is_polymorphic);

	bool show_error = true;

	Array<Operand> operands = {};
	defer (array_free(&operands));

	bool named_fields = false;

	if (is_call_expr_field_value(ce)) {
		named_fields = true;
		operands = array_make<Operand>(heap_allocator(), ce->args.count);
		for_array(i, ce->args) {
			AstNode *arg = ce->args[i];
			ast_node(fv, FieldValue, arg);
			check_expr_or_type(c, &operands[i], fv->value);
		}

		bool vari_expand = (ce->ellipsis.pos.line != 0);
		if (vari_expand) {
			error(ce->ellipsis, "Invalid use of '...' in a polymorphic type call'");
		}

	} else {
		operands = array_make<Operand>(heap_allocator(), 0, 2*ce->args.count);
		check_unpack_arguments(c, nullptr, -1, &operands, ce->args, false);
	}

	CallArgumentError err = CallArgumentError_None;

	TypeTuple *tuple = &st->polymorphic_params->Tuple;
	isize param_count = tuple->variables.count;

	Array<Operand> ordered_operands = operands;
	if (named_fields) {
		bool *visited = gb_alloc_array(c->allocator, bool, param_count);

		ordered_operands = array_make<Operand>(c->tmp_allocator, param_count);

		for_array(i, ce->args) {
			AstNode *arg = ce->args[i];
			ast_node(fv, FieldValue, arg);
			if (fv->field->kind != AstNode_Ident) {
				if (show_error) {
					gbString expr_str = expr_to_string(fv->field);
					error(arg, "Invalid parameter name '%s' in polymorphic type call", expr_str);
					gb_string_free(expr_str);
				}
				err = CallArgumentError_InvalidFieldValue;
				continue;
			}
			String name = fv->field->Ident.token.string;
			isize index = lookup_polymorphic_struct_parameter(st, name);
			if (index < 0) {
				if (show_error) {
					error(arg, "No parameter named '%.*s' for this polymorphic type", LIT(name));
				}
				err = CallArgumentError_ParameterNotFound;
				continue;
			}
			if (visited[index]) {
				if (show_error) {
					error(arg, "Duplicate parameter '%.*s' in polymorphic type", LIT(name));
				}
				err = CallArgumentError_DuplicateParameter;
				continue;
			}

			visited[index] = true;
			ordered_operands[index] = operands[i];
		}

		for (isize i = 0; i < param_count; i++) {
			if (!visited[i]) {
				Entity *e = tuple->variables[i];
				if (is_blank_ident(e->token)) {
					continue;
				}

				if (show_error) {
					if (e->kind == Entity_TypeName) {
						error(call, "Type parameter '%.*s' is missing in polymorphic type call",
						      LIT(e->token.string));
					} else {
						gbString str = type_to_string(e->type);
						error(call, "Parameter '%.*s' of type '%s' is missing in polymorphic type call",
						      LIT(e->token.string), str);
						gb_string_free(str);
					}
				}
				err = CallArgumentError_ParameterMissing;
			}
		}
	}

	if (err != 0) {
		operand->mode = Addressing_Invalid;
		return err;
	}

	i64 score = 0;
	for (isize i = 0; i < param_count; i++) {
		Operand *o = &ordered_operands[i];
		if (o->mode == Addressing_Invalid) {
			continue;
		}
		Entity *e = tuple->variables[i];

		if (e->kind == Entity_TypeName) {
			if (o->mode != Addressing_Type) {
				if (show_error) {
					error(o->expr, "Expected a type for the argument '%.*s'", LIT(e->token.string));
				}
				err = CallArgumentError_WrongTypes;
			}
			if (are_types_identical(e->type, o->type)) {
				score += assign_score_function(1);
			} else {
				score += assign_score_function(10);
			}
		} else {
			i64 s = 0;
			if (!check_is_assignable_to_with_score(c, o, e->type, &s)) {
				if (show_error) {
					check_assignment(c, o, e->type, str_lit("polymorphic type argument"));
				}
				err = CallArgumentError_WrongTypes;
			}
			o->type = e->type;
			if (o->mode != Addressing_Constant) {
				if (show_error) {
					error(o->expr, "Expected a constant value for this polymorphic type argument");
				}
				err = CallArgumentError_NoneConstantParameter;
			}
			score += s;
		}
	}

	if (param_count < ordered_operands.count) {
		error(call, "Too many polymorphic type arguments, expected %td, got %td", param_count, ordered_operands.count);
		err = CallArgumentError_TooManyArguments;
	} else if (param_count > ordered_operands.count) {
		error(call, "Too few polymorphic type arguments, expected %td, got %td", param_count, ordered_operands.count);
		err = CallArgumentError_TooFewArguments;
	}

	if (err != 0) {
		return err;
	}

	{
		// TODO(bill): Check for previous types
		gbAllocator a = c->allocator;

		Entity *found_entity = find_polymorphic_struct_entity(c, original_type, param_count, ordered_operands);
		if (found_entity) {
			operand->mode = Addressing_Type;
			operand->type = found_entity->type;
			return err;
		}

		String generated_name = make_string_c(expr_to_string(call));

		Type *named_type = alloc_type_named(generated_name, nullptr, nullptr);
		AstNode *node = clone_ast_node(a, st->node);
		Type *struct_type = alloc_type_struct();
		struct_type->Struct.node = node;
		struct_type->Struct.polymorphic_parent = original_type;
		set_base_type(named_type, struct_type);

		check_open_scope(c, node);
		check_struct_type(c, struct_type, node, &ordered_operands, named_type, original_type);
		check_close_scope(c);

		operand->mode = Addressing_Type;
		operand->type = named_type;
	}
	return err;
}


ExprKind check_call_expr(Checker *c, Operand *operand, AstNode *call) {
	ast_node(ce, CallExpr, call);
	if (ce->proc != nullptr &&
	    ce->proc->kind == AstNode_BasicDirective) {
		ast_node(bd, BasicDirective, ce->proc);
		String name = bd->name;
		if (name == "location" || name == "assert") {
			operand->mode = Addressing_Builtin;
			operand->builtin_id = BuiltinProc_DIRECTIVE;
			operand->expr = ce->proc;
			operand->type = t_invalid;
			add_type_and_value(&c->info, ce->proc, operand->mode, operand->type, operand->value);
		} else {
			GB_PANIC("Unhandled #%.*s", LIT(name));
		}
	} else {
		check_expr_or_type(c, operand, ce->proc);
	}

	if (ce->args.count > 0) {
		bool fail = false;
		bool first_is_field_value = (ce->args[0]->kind == AstNode_FieldValue);
		for_array(i, ce->args) {
			AstNode *arg = ce->args[i];
			bool mix = false;
			if (first_is_field_value) {
				mix = arg->kind != AstNode_FieldValue;
			} else {
				mix = arg->kind == AstNode_FieldValue;
			}
			if (mix) {
				error(arg, "Mixture of 'field = value' and value elements in a procedure all is not allowed");
				fail = true;
			}
		}

		if (fail) {
			operand->mode = Addressing_Invalid;
			operand->expr = call;
			return Expr_Stmt;
		}
	}

	if (operand->mode == Addressing_Invalid) {
		for_array(i, ce->args) {
			AstNode *arg = ce->args[i];
			if (arg->kind == AstNode_FieldValue) {
				arg = arg->FieldValue.value;
			}
			check_expr_base(c, operand, arg, nullptr);
		}
		operand->mode = Addressing_Invalid;
		operand->expr = call;
		return Expr_Stmt;
	}

	if (operand->mode == Addressing_Type) {
		Type *t = operand->type;
		if (is_type_polymorphic_struct(t)) {
			auto err = check_polymorphic_struct_type(c, operand, call);
			if (err == 0) {
				AstNode *ident = operand->expr;
				while (ident->kind == AstNode_SelectorExpr) {
					AstNode *s = ident->SelectorExpr.selector;
					ident = s;
				}
				Type *ot = operand->type; GB_ASSERT(ot->kind == Type_Named);
				Entity *e = ot->Named.type_name;
				add_entity_use(c, ident, e);
				add_type_and_value(&c->info, call, Addressing_Type, ot, empty_exact_value);
			} else {
				operand->mode = Addressing_Invalid;
				operand->type = t_invalid;
			}
		} else {
			gbString str = type_to_string(t);
			defer (gb_string_free(str));

			operand->mode = Addressing_Invalid;
			isize arg_count = ce->args.count;
			switch (arg_count) {
			case 0:  error(call, "Missing argument in conversion to '%s'", str);   break;
			default: error(call, "Too many arguments in conversion to '%s'", str); break;
			case 1: {
				AstNode *arg = ce->args[0];
				if (arg->kind == AstNode_FieldValue) {
					error(call, "'field = value' cannot be used in a type conversion");
					arg = arg->FieldValue.value;
					// NOTE(bill): Carry on the cast regardless
				}
				check_expr(c, operand, arg);
				if (operand->mode != Addressing_Invalid) {
					check_cast(c, operand, t);
				}

				break;
			}
			}
		}
		return Expr_Expr;
	}

	if (operand->mode == Addressing_Builtin) {
		i32 id = operand->builtin_id;
		if (!check_builtin_procedure(c, operand, call, id)) {
			operand->mode = Addressing_Invalid;
		}
		operand->expr = call;
		return builtin_procs[id].kind;
	}

	Type *proc_type = base_type(operand->type);
	if (operand->mode != Addressing_ProcGroup) {
		bool valid_type = (proc_type != nullptr) && is_type_proc(proc_type);
		bool valid_mode = is_operand_value(*operand);
		if (!valid_type || !valid_mode) {
			AstNode *e = operand->expr;
			gbString str = expr_to_string(e);
			gbString type_str = type_to_string(operand->type);
			error(e, "Cannot call a non-procedure: '%s' of type '%s'", str, type_str);
			gb_string_free(type_str);
			gb_string_free(str);

			operand->mode = Addressing_Invalid;
			operand->expr = call;

			return Expr_Stmt;
		}
	}

	// NOTE(bill): Should this be here or on the `add_entity_use`?
	// if (ce->proc != nullptr) {
	// 	Entity *e = entity_of_node(&c->info, ce->proc);
	// 	if (e != nullptr && e->kind == Entity_Procedure) {
	// 		String msg = e->Procedure.deprecated_message;
	// 		if (msg.len > 0) {
	// 			warning(call, "%.*s is deprecated: %.*s", LIT(e->token.string), LIT(msg));
	// 		}
	// 	}
	// }

	CallArgumentData data = check_call_arguments(c, operand, proc_type, call);
	Type *result_type = data.result_type;
	gb_zero_item(operand);
	operand->expr = call;

	if (result_type == t_invalid) {
		operand->mode = Addressing_Invalid;
		operand->type = t_invalid;
		return Expr_Stmt;
	}

	Type *pt = base_type(proc_type);
	if (result_type == nullptr) {
		operand->mode = Addressing_NoValue;
	} else {
		GB_ASSERT(is_type_tuple(result_type));
		switch (result_type->Tuple.variables.count) {
		case 0:
			operand->mode = Addressing_NoValue;
			break;
		case 1:
			operand->mode = Addressing_Value;
			operand->type = result_type->Tuple.variables[0]->type;
			break;
		default:
			operand->mode = Addressing_Value;
			operand->type = result_type;
			break;
		}
	}

	operand->expr = call;
	return Expr_Expr;
}


void check_expr_with_type_hint(Checker *c, Operand *o, AstNode *e, Type *t) {
	check_expr_base(c, o, e, t);
	check_not_tuple(c, o);
	char *err_str = nullptr;
	switch (o->mode) {
	case Addressing_NoValue:
		err_str = "used as a value";
		break;
	case Addressing_Type:
		err_str = "is not an expression";
		break;
	case Addressing_Builtin:
		err_str = "must be called";
		break;
	}
	if (err_str != nullptr) {
		gbString str = expr_to_string(e);
		error(e, "'%s' %s", str, err_str);
		gb_string_free(str);
		o->mode = Addressing_Invalid;
	}
}

void check_set_mode_with_indirection(Operand *o, bool indirection) {
	if (o->mode != Addressing_Immutable) {
		if (indirection) {
			o->mode = Addressing_Variable;
		} else if (o->mode != Addressing_Variable &&
		           o->mode != Addressing_Constant) {
			o->mode = Addressing_Value;
		}
	}
}

bool check_set_index_data(Operand *o, Type *type, bool indirection, i64 *max_count) {
	Type *t = base_type(type_deref(type));

	switch (t->kind) {
	case Type_Basic:
		if (t->Basic.kind == Basic_string) {
			if (o->mode == Addressing_Constant) {
				*max_count = o->value.value_string.len;
			}
			check_set_mode_with_indirection(o, indirection);
			o->type = t_u8;
			return true;
		}
		break;

	case Type_Array:
		*max_count = t->Array.count;
		check_set_mode_with_indirection(o, indirection);
		o->type = t->Array.elem;
		return true;

	case Type_Slice:
		o->type = t->Slice.elem;
		if (o->mode != Addressing_Immutable) {
			o->mode = Addressing_Variable;
		}
		return true;

	case Type_DynamicArray:
		o->type = t->DynamicArray.elem;
		check_set_mode_with_indirection(o, indirection);
		return true;
	}

	return false;
}

bool ternary_compare_types(Type *x, Type *y) {
	if (is_type_untyped_undef(x) && type_has_undef(y)) {
		return true;
	} else if (is_type_untyped_nil(x) && type_has_nil(y)) {
		return true;
	} else if (is_type_untyped_undef(y) && type_has_undef(x)) {
		return true;
	} else if (is_type_untyped_nil(y) && type_has_nil(x)) {
		return true;
	}
	return are_types_identical(x, y);
}

ExprKind check_expr_base_internal(Checker *c, Operand *o, AstNode *node, Type *type_hint) {
	ExprKind kind = Expr_Stmt;

	o->mode = Addressing_Invalid;
	o->type = t_invalid;

	switch (node->kind) {
	default:
		return kind;

	case_ast_node(be, BadExpr, node)
		return kind;
	case_end;

	case_ast_node(i, Implicit, node)
		switch (i->kind) {
		case Token_context:
			if (c->context.proc_name.len == 0) {
				error(node, "'context' is only allowed within procedures");
				return kind;
			}

			init_preload(c);
			o->mode = Addressing_Immutable;
			o->type = t_context;
			break;

		case Token_size_of:
			o->mode       = Addressing_Builtin;
			o->builtin_id = BuiltinProc_size_of;
			break;
		case Token_align_of:
			o->mode       = Addressing_Builtin;
			o->builtin_id = BuiltinProc_align_of;
			break;
		case Token_offset_of:
			o->mode       = Addressing_Builtin;
			o->builtin_id = BuiltinProc_offset_of;
			break;
		case Token_type_of:
			o->mode       = Addressing_Builtin;
			o->builtin_id = BuiltinProc_type_of;
			break;
		case Token_type_info_of:
			o->mode       = Addressing_Builtin;
			o->builtin_id = BuiltinProc_type_info_of;
			break;

		default:
			error(node, "Illegal implicit name '%.*s'", LIT(i->string));
			return kind;
		}
	case_end;

	case_ast_node(i, Ident, node);
		check_ident(c, o, node, nullptr, type_hint, false);
	case_end;

	case_ast_node(u, Undef, node);
		o->mode = Addressing_Value;
		o->type = t_untyped_undef;
	case_end;


	case_ast_node(bl, BasicLit, node);
		Type *t = t_invalid;
		switch (bl->token.kind) {
		case Token_Integer: t = t_untyped_integer; break;
		case Token_Float:   t = t_untyped_float;   break;
		case Token_String:  t = t_untyped_string;  break;
		case Token_Rune:    t = t_untyped_rune;    break;
		case Token_Imag: {
			String s = bl->token.string;
			Rune r = s[s.len-1];
			switch (r) {
			case 'i': t = t_untyped_complex; break;
			}

			break;
		}
		default:            GB_PANIC("Unknown literal"); break;
		}
		o->mode  = Addressing_Constant;
		o->type  = t;
		o->value = exact_value_from_basic_literal(bl->token);
	case_end;

	case_ast_node(bd, BasicDirective, node);
		if (bd->name == "file") {
			o->type = t_untyped_string;
			o->value = exact_value_string(bd->token.pos.file);
		} else if (bd->name == "line") {
			o->type = t_untyped_integer;
			o->value = exact_value_i64(bd->token.pos.line);
		} else if (bd->name == "procedure") {
			if (c->proc_stack.count == 0) {
				error(node, "#procedure may only be used within procedures");
				o->type = t_untyped_string;
				o->value = exact_value_string(str_lit(""));
			} else {
				o->type = t_untyped_string;
				o->value = exact_value_string(c->context.proc_name);
			}
		} else if (bd->name == "caller_location") {
			init_preload(c);
			error(node, "#caller_location may only be used as a default argument parameter");
			o->type = t_source_code_location;
			o->mode = Addressing_Value;
		} else {
			GB_PANIC("Unknown basic directive");
		}
		o->mode = Addressing_Constant;
	case_end;

	case_ast_node(pg, ProcGroup, node);
		error(node, "Illegal use of a procedure group");
		o->mode = Addressing_Invalid;
	case_end;

	case_ast_node(pl, ProcLit, node);
		CheckerContext prev_context = c->context;
		DeclInfo *decl = nullptr;
		Type *type = alloc_type(Type_Proc);
		check_open_scope(c, pl->type);
		{
			decl = make_declaration_info(c->allocator, c->context.scope, c->context.decl);
			decl->proc_lit  = node;
			c->context.decl = decl;

			if (pl->tags != 0) {
				error(node, "A procedure literal cannot have tags");
				pl->tags = 0; // TODO(bill): Should I zero this?!
			}

			check_procedure_type(c, type, pl->type);
			if (!is_type_proc(type)) {
				gbString str = expr_to_string(node);
				error(node, "Invalid procedure literal '%s'", str);
				gb_string_free(str);
				check_close_scope(c);
				return kind;
			}

			if (pl->body == nullptr) {
				error(node, "A procedure literal must have a body");
				return kind;
			}

			check_procedure_later(c, c->curr_ast_file, empty_token, decl, type, pl->body, pl->tags);
		}
		check_close_scope(c);

		c->context = prev_context;

		o->mode = Addressing_Value;
		o->type = type;
	case_end;

	case_ast_node(te, TernaryExpr, node);
		Operand cond = {Addressing_Invalid};
		check_expr(c, &cond, te->cond);
		if (cond.mode != Addressing_Invalid && !is_type_boolean(cond.type)) {
			error(te->cond, "Non-boolean condition in if expression");
		}

		Operand x = {Addressing_Invalid};
		Operand y = {Addressing_Invalid};
		check_expr_or_type(c, &x, te->x, type_hint);

		if (te->y != nullptr) {
			check_expr_or_type(c, &y, te->y, type_hint);
		} else {
			error(node, "A ternary expression must have an else clause");
			return kind;
		}

		if (x.type == nullptr || x.type == t_invalid ||
		    y.type == nullptr || y.type == t_invalid) {
			return kind;
		}

		if (x.mode == Addressing_Type && y.mode == Addressing_Type &&
		    cond.mode == Addressing_Constant && is_type_boolean(cond.type)) {
			o->mode = Addressing_Type;
			if (cond.value.value_bool) {
				o->type = x.type;
				o->expr = x.expr;
			} else {
				o->type = y.type;
				o->expr = y.expr;
			}
			return Expr_Expr;
		}

		convert_to_typed(c, &x, y.type);
		if (x.mode == Addressing_Invalid) {
			return kind;
		}
		convert_to_typed(c, &y, x.type);
		if (y.mode == Addressing_Invalid) {
			x.mode = Addressing_Invalid;
			return kind;
		}

		if (!ternary_compare_types(x.type, y.type)) {
			gbString its = type_to_string(x.type);
			gbString ets = type_to_string(y.type);
			error(node, "Mismatched types in ternary expression, %s vs %s", its, ets);
			gb_string_free(ets);
			gb_string_free(its);
			return kind;
		}

		Type *type = x.type;
		if (is_type_untyped_nil(type) || is_type_untyped_undef(type)) {
			type = y.type;
		}

		o->type = type;
		o->mode = Addressing_Value;

		if (cond.mode == Addressing_Constant && is_type_boolean(cond.type) &&
		    x.mode == Addressing_Constant &&
		    y.mode == Addressing_Constant) {

			o->mode = Addressing_Constant;

			if (cond.value.value_bool) {
				o->value = x.value;
			} else {
				o->value = y.value;
			}
		}

	case_end;

	case_ast_node(cl, CompoundLit, node);
		Type *type = type_hint;
		bool is_to_be_determined_array_count = false;
		bool is_constant = true;
		if (cl->type != nullptr) {
			type = nullptr;

			// [?]Type
			if (cl->type->kind == AstNode_ArrayType && cl->type->ArrayType.count != nullptr) {
				AstNode *count = cl->type->ArrayType.count;
				if (count->kind == AstNode_UnaryExpr &&
				    count->UnaryExpr.op.kind == Token_Question) {
					type = alloc_type_array(check_type(c, cl->type->ArrayType.elem), -1);
					is_to_be_determined_array_count = true;
				}
			}

			if (type == nullptr) {
				type = check_type(c, cl->type);
			}
		}

		if (type == nullptr) {
			error(node, "Missing type in compound literal");
			return kind;
		}


		Type *t = base_type(type);
		if (is_type_polymorphic(t)) {
			gbString str = type_to_string(type);
			error(node, "Cannot use a polymorphic type for a compound literal, got '%s'", str);
			o->expr = node;
			o->type = type;
			gb_string_free(str);
			return kind;
		}


		switch (t->kind) {
		case Type_Struct: {
			if (is_type_union(t)) {
				is_constant = false;
			}
			if (cl->elems.count == 0) {
				break; // NOTE(bill): No need to init
			}
			if (!is_type_struct(t)) {
				if (cl->elems.count != 0) {
					gbString type_str = type_to_string(type);
					error(node, "Illegal compound literal type '%s'", type_str);
					gb_string_free(type_str);
				}
				break;
			}

			{ // Checker values
				isize field_count = t->Struct.fields.count;
				isize min_field_count = t->Struct.fields.count;
				for (isize i = min_field_count-1; i >= 0; i--) {
					Entity *e = t->Struct.fields[i];
					GB_ASSERT(e->kind == Entity_Variable);
					if (e->Variable.default_is_nil) {
						min_field_count--;
					} else if (e->Variable.default_is_undef) {
						min_field_count--;
					} else if (e->Variable.default_value.kind != ExactValue_Invalid) {
						min_field_count--;
					} else {
						break;
					}
				}

				if (cl->elems[0]->kind == AstNode_FieldValue) {
					bool *fields_visited = gb_alloc_array(c->allocator, bool, field_count);

					for_array(i, cl->elems) {
						AstNode *elem = cl->elems[i];
						if (elem->kind != AstNode_FieldValue) {
							error(elem, "Mixture of 'field = value' and value elements in a literal is not allowed");
							continue;
						}
						ast_node(fv, FieldValue, elem);
						if (fv->field->kind != AstNode_Ident) {
							gbString expr_str = expr_to_string(fv->field);
							error(elem, "Invalid field name '%s' in structure literal", expr_str);
							gb_string_free(expr_str);
							continue;
						}
						String name = fv->field->Ident.token.string;

						Selection sel = lookup_field(type, name, o->mode == Addressing_Type);
						bool is_unknown = sel.entity == nullptr;
						if (is_unknown) {
							error(elem, "Unknown field '%.*s' in structure literal", LIT(name));
							continue;
						}

						if (sel.index.count > 1) {
							error(elem, "Cannot assign to an anonymous field '%.*s' in a structure literal (at the moment)", LIT(name));
							continue;
						}

						Entity *field = t->Struct.fields[sel.index[0]];
						add_entity_use(c, fv->field, field);

						if (fields_visited[sel.index[0]]) {
							error(elem, "Duplicate field '%.*s' in structure literal", LIT(name));
							continue;
						}

						fields_visited[sel.index[0]] = true;
						check_expr_with_type_hint(c, o, fv->value, field->type);

						if (is_type_any(field->type) || is_type_union(field->type) || is_type_raw_union(field->type)) {
							is_constant = false;
						}
						if (is_constant) {
							is_constant = o->mode == Addressing_Constant;
						}


						check_assignment(c, o, field->type, str_lit("structure literal"));
					}
				} else {
					bool seen_field_value = false;

					for_array(index, cl->elems) {
						Entity *field = nullptr;
						AstNode *elem = cl->elems[index];
						if (elem->kind == AstNode_FieldValue) {
							seen_field_value = true;
							// error(elem, "Mixture of 'field = value' and value elements in a literal is not allowed");
							// continue;
						} else if (seen_field_value) {
							error(elem, "Value elements cannot be used after a 'field = value'");
							continue;
						}
						if (index >= field_count) {
							error(o->expr, "Too many values in structure literal, expected %td, got %td", field_count, cl->elems.count);
							break;
						}

						if (field == nullptr) {
							field = t->Struct.fields[index];
						}

						check_expr_with_type_hint(c, o, elem, field->type);

						if (is_type_any(field->type) || is_type_union(field->type) || is_type_raw_union(field->type)) {
							is_constant = false;
						}
						if (is_constant) {
							is_constant = o->mode == Addressing_Constant;
						}

						check_assignment(c, o, field->type, str_lit("structure literal"));
					}
					if (cl->elems.count < field_count) {
						if (min_field_count < field_count) {
						    if (cl->elems.count < min_field_count) {
								error(cl->close, "Too few values in structure literal, expected at least %td, got %td", min_field_count, cl->elems.count);
						    }
						} else {
							error(cl->close, "Too few values in structure literal, expected %td, got %td", field_count, cl->elems.count);
						}
					}
				}
			}
			break;
		}

		case Type_Slice:
		case Type_Array:
		case Type_DynamicArray:
		{
			Type *elem_type = nullptr;
			String context_name = {};
			i64 max_type_count = -1;
			if (t->kind == Type_Slice) {
				elem_type = t->Slice.elem;
				context_name = str_lit("slice literal");
			} else if (t->kind == Type_Array) {
				elem_type = t->Array.elem;
				context_name = str_lit("array literal");
				if (!is_to_be_determined_array_count) {
					max_type_count = t->Array.count;
				}
			} else if (t->kind == Type_DynamicArray) {
				elem_type = t->DynamicArray.elem;
				context_name = str_lit("dynamic array literal");
				is_constant = false;
			} else {
				GB_PANIC("unreachable");
			}


			i64 max = 0;
			isize index = 0;

			Type *bet = base_type(elem_type);
			if (!elem_type_can_be_constant(bet)) {
				is_constant = false;
			}

			if (bet == t_invalid) {
				break;
			}

			for (; index < cl->elems.count; index++) {
				AstNode *e = cl->elems[index];
				if (e == nullptr) {
					error(node, "Invalid literal element");
					continue;
				}

				if (e->kind == AstNode_FieldValue) {
					error(e, "'field = value' is only allowed in struct literals");
					continue;
				}

				if (0 <= max_type_count && max_type_count <= index) {
					error(e, "Index %lld is out of bounds (>= %lld) for %.*s", index, max_type_count, LIT(context_name));
				}

				Operand operand = {};
				check_expr_with_type_hint(c, &operand, e, elem_type);
				check_assignment(c, &operand, elem_type, context_name);

				is_constant = is_constant && operand.mode == Addressing_Constant;
			}
			if (max < index) {
				max = index;
			}

			if (t->kind == Type_Array) {
				if (is_to_be_determined_array_count) {
					t->Array.count = max;
				} else if (0 < max && max < t->Array.count) {
					error(node, "Expected %lld values for this array literal, got %lld", cast(long long)t->Array.count, cast(long long)max);
				}
			}
			break;
		}

		case Type_Basic: {
			if (!is_type_any(t)) {
				if (cl->elems.count != 0) {
					error(node, "Illegal compound literal");
				}
				break;
			}
			if (cl->elems.count == 0) {
				break; // NOTE(bill): No need to init
			}
			{ // Checker values
				Type *field_types[2] = {t_rawptr, t_type_info_ptr};
				isize field_count = 2;
				if (cl->elems[0]->kind == AstNode_FieldValue) {
					bool fields_visited[2] = {};

					for_array(i, cl->elems) {
						AstNode *elem = cl->elems[i];
						if (elem->kind != AstNode_FieldValue) {
							error(elem, "Mixture of 'field = value' and value elements in a 'any' literal is not allowed");
							continue;
						}
						ast_node(fv, FieldValue, elem);
						if (fv->field->kind != AstNode_Ident) {
							gbString expr_str = expr_to_string(fv->field);
							error(elem, "Invalid field name '%s' in 'any' literal", expr_str);
							gb_string_free(expr_str);
							continue;
						}
						String name = fv->field->Ident.token.string;

						Selection sel = lookup_field(type, name, o->mode == Addressing_Type);
						if (sel.entity == nullptr) {
							error(elem, "Unknown field '%.*s' in 'any' literal", LIT(name));
							continue;
						}

						isize index = sel.index[0];

						if (fields_visited[index]) {
							error(elem, "Duplicate field '%.*s' in 'any' literal", LIT(name));
							continue;
						}

						fields_visited[index] = true;
						check_expr(c, o, fv->value);

						// NOTE(bill): 'any' literals can never be constant
						is_constant = false;

						check_assignment(c, o, field_types[index], str_lit("'any' literal"));
					}
				} else {
					for_array(index, cl->elems) {
						AstNode *elem = cl->elems[index];
						if (elem->kind == AstNode_FieldValue) {
							error(elem, "Mixture of 'field = value' and value elements in a 'any' literal is not allowed");
							continue;
						}


						check_expr(c, o, elem);
						if (index >= field_count) {
							error(o->expr, "Too many values in 'any' literal, expected %td", field_count);
							break;
						}

						// NOTE(bill): 'any' literals can never be constant
						is_constant = false;

						check_assignment(c, o, field_types[index], str_lit("'any' literal"));
					}
					if (cl->elems.count < field_count) {
						error(cl->close, "Too few values in 'any' literal, expected %td, got %td", field_count, cl->elems.count);
					}
				}
			}

			break;
		}

		case Type_Map: {
			if (cl->elems.count == 0) {
				break;
			}
			is_constant = false;
			{ // Checker values
				for_array(i, cl->elems) {
					AstNode *elem = cl->elems[i];
					if (elem->kind != AstNode_FieldValue) {
						error(elem, "Only 'field = value' elements are allowed in a map literal");
						continue;
					}
					ast_node(fv, FieldValue, elem);
					check_expr_with_type_hint(c, o, fv->field, t->Map.key);
					check_assignment(c, o, t->Map.key, str_lit("map literal"));
					if (o->mode == Addressing_Invalid) {
						continue;
					}

					check_expr_with_type_hint(c, o, fv->value, t->Map.value);
					check_assignment(c, o, t->Map.value, str_lit("map literal"));
				}
			}

			break;
		}

		default: {
			if (cl->elems.count == 0) {
				break; // NOTE(bill): No need to init
			}

			gbString str = type_to_string(type);
			error(node, "Invalid compound literal type '%s'", str);
			gb_string_free(str);
			return kind;
		}
		}

		if (is_constant) {
			o->mode = Addressing_Constant;
			o->value = exact_value_compound(node);
		} else {
			o->mode = Addressing_Value;
		}
		o->type = type;
	case_end;

	case_ast_node(pe, ParenExpr, node);
		kind = check_expr_base(c, o, pe->expr, type_hint);
		o->expr = node;
	case_end;

	case_ast_node(te, TagExpr, node);
		String name = te->name.string;
		error(node, "Unknown tag expression, #%.*s", LIT(name));
		if (te->expr) {
			kind = check_expr_base(c, o, te->expr, type_hint);
		}
		o->expr = node;
	case_end;

	case_ast_node(re, RunExpr, node);
		// TODO(bill): Tag expressions
		kind = check_expr_base(c, o, re->expr, type_hint);
		o->expr = node;
	case_end;

	case_ast_node(ta, TypeAssertion, node);
		check_expr(c, o, ta->expr);
		if (o->mode == Addressing_Invalid) {
			o->expr = node;
			return kind;
		}
		Type *t = check_type(c, ta->type);

		if (o->mode == Addressing_Constant) {
			gbString expr_str = expr_to_string(o->expr);
			error(o->expr, "A type assertion cannot be applied to a constant expression: '%s'", expr_str);
			gb_string_free(expr_str);
			o->mode = Addressing_Invalid;
			o->expr = node;
			return kind;
		}

		if (is_type_untyped(o->type)) {
			gbString expr_str = expr_to_string(o->expr);
			error(o->expr, "A type assertion cannot be applied to an untyped expression: '%s'", expr_str);
			gb_string_free(expr_str);
			o->mode = Addressing_Invalid;
			o->expr = node;
			return kind;
		}

		bool src_is_ptr = is_type_pointer(o->type);
		Type *src = type_deref(o->type);
		Type *dst = t;
		Type *bsrc = base_type(src);
		Type *bdst = base_type(dst);


		if (is_type_union(src)) {
			bool ok = false;
			for_array(i, bsrc->Union.variants) {
				Type *vt = bsrc->Union.variants[i];
				if (are_types_identical(vt, dst)) {
					ok = true;
					break;
				}
			}

			if (!ok) {
				gbString expr_str = expr_to_string(o->expr);
				gbString dst_type_str = type_to_string(t);
				defer (gb_string_free(expr_str));
				defer (gb_string_free(dst_type_str));
				if (bsrc->Union.variants.count == 0) {
					error(o->expr, "Cannot type assert '%s' to '%s' as this is an empty union", expr_str, dst_type_str);
				} else {
					error(o->expr, "Cannot type assert '%s' to '%s' as it is not a variant of that union", expr_str, dst_type_str);
				}
				o->mode = Addressing_Invalid;
				o->expr = node;
				return kind;
			}

			add_type_info_type(c, o->type);
			add_type_info_type(c, t);

			o->type = t;
			o->mode = Addressing_OptionalOk;
		} else if (is_type_any(src)) {
			o->type = t;
			o->mode = Addressing_OptionalOk;

			add_type_info_type(c, o->type);
			add_type_info_type(c, t);
		} else {
			gbString str = type_to_string(o->type);
			error(o->expr, "Type assertions can only operate on unions and 'any', got %s", str);
			gb_string_free(str);
			o->mode = Addressing_Invalid;
			o->expr = node;
			return kind;
		}
	case_end;

	case_ast_node(tc, TypeCast, node);
		check_expr_or_type(c, o, tc->type);
		if (o->mode != Addressing_Type) {
			gbString str = expr_to_string(tc->type);
			error(tc->type, "Expected a type, got %s", str);
			gb_string_free(str);
			o->mode = Addressing_Invalid;
		}
		if (o->mode == Addressing_Invalid) {
			o->expr = node;
			return kind;
		}
		Type *type = o->type;
		check_expr_base(c, o, tc->expr, type);
		if (o->mode != Addressing_Invalid) {
			switch (tc->token.kind) {
			case Token_transmute:
				check_transmute(c, node, o, type);
				break;
			case Token_cast:
				check_cast(c, o, type);
				break;
			default:
				error(node, "Invalid AST: Invalid casting expression");
				o->mode = Addressing_Invalid;
				break;
			}
		}
		return Expr_Expr;
	case_end;

	case_ast_node(ac, AutoCast, node);
		check_expr_base(c, o, ac->expr, type_hint);
		if (o->mode == Addressing_Invalid) {
			o->expr = node;
			return kind;
		}
		if (type_hint) {
			check_cast(c, o, type_hint);
		}
		o->expr = node;
		return Expr_Expr;
	case_end;

	case_ast_node(ue, UnaryExpr, node);
		check_expr_base(c, o, ue->expr, type_hint);
		if (o->mode == Addressing_Invalid) {
			o->expr = node;
			return kind;
		}
		check_unary_expr(c, o, ue->op, node);
		if (o->mode == Addressing_Invalid) {
			o->expr = node;
			return kind;
		}
	case_end;


	case_ast_node(be, BinaryExpr, node);
		check_binary_expr(c, o, node);
		if (o->mode == Addressing_Invalid) {
			o->expr = node;
			return kind;
		}
	case_end;



	case_ast_node(se, SelectorExpr, node);
		check_selector(c, o, node, type_hint);
	case_end;


	case_ast_node(ie, IndexExpr, node);
		check_expr(c, o, ie->expr);
		if (o->mode == Addressing_Invalid) {
			o->expr = node;
			return kind;
		}

		Type *t = base_type(type_deref(o->type));
		bool is_ptr = is_type_pointer(o->type);
		bool is_const = o->mode == Addressing_Constant;

		if (is_type_map(t)) {
			Operand key = {};
			check_expr(c, &key, ie->index);
			check_assignment(c, &key, t->Map.key, str_lit("map index"));
			if (key.mode == Addressing_Invalid) {
				o->mode = Addressing_Invalid;
				o->expr = node;
				return kind;
			}
			o->mode = Addressing_MapIndex;
			o->type = t->Map.value;
			o->expr = node;
			return Expr_Expr;
		}

		i64 max_count = -1;
		bool valid = check_set_index_data(o, t, is_ptr, &max_count);

		if (is_const) {
			valid = false;
		}

		if (!valid) {
			gbString str = expr_to_string(o->expr);
			gbString type_str = type_to_string(o->type);
			defer (gb_string_free(str));
			defer (gb_string_free(type_str));
			if (is_const) {
				error(o->expr, "Cannot index a constant '%s'", str);
			} else {
				error(o->expr, "Cannot index '%s' of type '%s'", str, type_str);
			}
			o->mode = Addressing_Invalid;
			o->expr = node;
			return kind;
		}

		if (ie->index == nullptr) {
			gbString str = expr_to_string(o->expr);
			error(o->expr, "Missing index for '%s'", str);
			gb_string_free(str);
			o->mode = Addressing_Invalid;
			o->expr = node;
			return kind;
		}

		i64 index = 0;
		bool ok = check_index_value(c, false, ie->index, max_count, &index);

	case_end;



	case_ast_node(se, SliceExpr, node);
		check_expr(c, o, se->expr);
		if (o->mode == Addressing_Invalid) {
			o->mode = Addressing_Invalid;
			o->expr = node;
			return kind;
		}

		bool valid = false;
		i64 max_count = -1;
		Type *t = base_type(type_deref(o->type));
		switch (t->kind) {
		case Type_Basic:
			if (t->Basic.kind == Basic_string) {
				valid = true;
				if (o->mode == Addressing_Constant) {
					max_count = o->value.value_string.len;
				}
				o->type = t_string;
			}
			break;

		case Type_Array:
			valid = true;
			max_count = t->Array.count;
			if (o->mode != Addressing_Variable) {
				gbString str = expr_to_string(node);
				error(node, "Cannot slice array '%s', value is not addressable", str);
				gb_string_free(str);
				o->mode = Addressing_Invalid;
				o->expr = node;
				return kind;
			}
			o->type = alloc_type_slice(t->Array.elem);
			break;

		case Type_Slice:
			valid = true;
			o->type = type_deref(o->type);
			break;

		case Type_DynamicArray:
			valid = true;
			o->type = alloc_type_slice(t->DynamicArray.elem);
			break;
		}

		if (!valid) {
			gbString str = expr_to_string(o->expr);
			error(o->expr, "Cannot slice '%s'", str);
			gb_string_free(str);
			o->mode = Addressing_Invalid;
			o->expr = node;
			return kind;
		}

		if (o->mode != Addressing_Immutable) {
			o->mode = Addressing_Value;
		}

		if (se->low == nullptr && se->high != nullptr) {
			// error(se->interval0, "1st index is required if a 2nd index is specified");
			// It is okay to continue as it will assume the 1st index is zero
		}

		TokenKind interval_kind = se->interval.kind;

		i64 indices[2] = {};
		AstNode *nodes[2] = {se->low, se->high};
		for (isize i = 0; i < gb_count_of(nodes); i++) {
			i64 index = max_count;
			if (nodes[i] != nullptr) {
				i64 capacity = -1;
				if (max_count >= 0) {
					capacity = max_count;
				}
				i64 j = 0;
				if (check_index_value(c, interval_kind == Token_Ellipsis, nodes[i], capacity, &j)) {
					index = j;
				}
			} else if (i == 0) {
				index = 0;
			}
			indices[i] = index;
		}

		for (isize i = 0; i < gb_count_of(indices); i++) {
			i64 a = indices[i];
			for (isize j = i+1; j < gb_count_of(indices); j++) {
				i64 b = indices[j];
				if (a > b && b >= 0) {
					error(se->close, "Invalid slice indices: [%td > %td]", a, b);
				}
			}
		}

	case_end;


	case_ast_node(ce, CallExpr, node);
		return check_call_expr(c, o, node);
	case_end;

	case_ast_node(de, DerefExpr, node);
		check_expr_or_type(c, o, de->expr);
		if (o->mode == Addressing_Invalid) {
			o->mode = Addressing_Invalid;
			o->expr = node;
			return kind;
		} else {
			Type *t = base_type(o->type);
			if (t->kind == Type_Pointer && !is_type_empty_union(t->Pointer.elem)) {
				if (o->mode != Addressing_Immutable) {
					o->mode = Addressing_Variable;
				}
				o->type = t->Pointer.elem;
 			} else {
 				gbString str = expr_to_string(o->expr);
 				gbString typ = type_to_string(o->type);
 				error(o->expr, "Cannot dereference '%s' of type '%s'", str, typ);
 				gb_string_free(typ);
 				gb_string_free(str);
 				o->mode = Addressing_Invalid;
 				o->expr = node;
 				return kind;
 			}
		}
	case_end;

	case AstNode_TypeType:
	case AstNode_PolyType:
	case AstNode_ProcType:
	case AstNode_PointerType:
	case AstNode_ArrayType:
	case AstNode_DynamicArrayType:
	case AstNode_StructType:
	case AstNode_UnionType:
	// case AstNode_RawUnionType:
	case AstNode_EnumType:
	case AstNode_MapType:
		o->mode = Addressing_Type;
		o->type = check_type(c, node);
		break;
	}

	kind = Expr_Expr;
	o->expr = node;
	return kind;
}

ExprKind check_expr_base(Checker *c, Operand *o, AstNode *node, Type *type_hint) {
	ExprKind kind = check_expr_base_internal(c, o, node, type_hint);
	Type *type = nullptr;
	ExactValue value = {ExactValue_Invalid};
	switch (o->mode) {
	case Addressing_Invalid:
		type = t_invalid;
		break;
	case Addressing_NoValue:
		type = nullptr;
		break;
	case Addressing_Constant:
		type = o->type;
		value = o->value;
		break;
	default:
		type = o->type;
		break;
	}

	if (type != nullptr && is_type_untyped(type)) {
		add_untyped(&c->info, node, false, o->mode, type, value);
	} else {
		add_type_and_value(&c->info, node, o->mode, type, value);
	}
	return kind;
}



void check_multi_expr(Checker *c, Operand *o, AstNode *e) {
	check_expr_base(c, o, e, nullptr);
	switch (o->mode) {
	default:
		return; // NOTE(bill): Valid
	case Addressing_NoValue:
		error_operand_no_value(o);
		break;
	case Addressing_Type:
		error_operand_not_expression(o);
		break;
	}
	o->mode = Addressing_Invalid;
}

void check_not_tuple(Checker *c, Operand *o) {
	if (o->mode == Addressing_Value) {
		// NOTE(bill): Tuples are not first class thus never named
		if (o->type->kind == Type_Tuple) {
			isize count = o->type->Tuple.variables.count;
			GB_ASSERT(count != 1);
			error(o->expr,
			      "%td-valued tuple found where single value expected", count);
			o->mode = Addressing_Invalid;
		}
	}
}

void check_expr(Checker *c, Operand *o, AstNode *e) {
	check_multi_expr(c, o, e);
	check_not_tuple(c, o);
}


void check_expr_or_type(Checker *c, Operand *o, AstNode *e, Type *type_hint) {
	check_expr_base(c, o, e, type_hint);
	check_not_tuple(c, o);
	error_operand_no_value(o);
}


gbString write_expr_to_string(gbString str, AstNode *node);

gbString write_struct_fields_to_string(gbString str, Array<AstNode *> params) {
	for_array(i, params) {
		if (i > 0) {
			str = gb_string_appendc(str, ", ");
		}
		str = write_expr_to_string(str, params[i]);
	}
	return str;
}

gbString string_append_string(gbString str, String string) {
	if (string.len > 0) {
		return gb_string_append_length(str, &string[0], string.len);
	}
	return str;
}


gbString string_append_token(gbString str, Token token) {
	return string_append_string(str, token.string);
}


gbString write_expr_to_string(gbString str, AstNode *node) {
	if (node == nullptr)
		return str;

	if (is_ast_node_stmt(node)) {
		GB_ASSERT("stmt passed to write_expr_to_string");
	}

	switch (node->kind) {
	default:
		str = gb_string_appendc(str, "(BadExpr)");
		break;

	case_ast_node(i, Ident, node);
		str = string_append_token(str, i->token);
	case_end;

	case_ast_node(i, Implicit, node);
		str = string_append_token(str, *i);
	case_end;

	case_ast_node(bl, BasicLit, node);
		str = string_append_token(str, bl->token);
	case_end;

	case_ast_node(bd, BasicDirective, node);
		str = gb_string_append_rune(str, '#');
		str = string_append_string(str, bd->name);
	case_end;

	case_ast_node(ud, Undef, node);
		str = gb_string_appendc(str, "---");
	case_end;

	case_ast_node(pg, ProcGroup, node);
		str = gb_string_appendc(str, "proc[");
		for_array(i, pg->args) {
			if (i > 0) str = gb_string_appendc(str, ", ");
			str = write_expr_to_string(str, pg->args[i]);
		}
		str = gb_string_append_rune(str, ']');
	case_end;

	case_ast_node(pl, ProcLit, node);
		str = write_expr_to_string(str, pl->type);
	case_end;

	case_ast_node(cl, CompoundLit, node);
		str = write_expr_to_string(str, cl->type);
		str = gb_string_append_rune(str, '{');
		for_array(i, cl->elems) {
			if (i > 0) str = gb_string_appendc(str, ", ");
			str = write_expr_to_string(str, cl->elems[i]);
		}
		str = gb_string_append_rune(str, '}');
	case_end;


	case_ast_node(te, TagExpr, node);
		str = gb_string_append_rune(str, '#');
		str = string_append_token(str, te->name);
		str = write_expr_to_string(str, te->expr);
	case_end;

	case_ast_node(ue, UnaryExpr, node);
		str = string_append_token(str, ue->op);
		str = write_expr_to_string(str, ue->expr);
	case_end;

	case_ast_node(de, DerefExpr, node);
		str = write_expr_to_string(str, de->expr);
		str = gb_string_append_rune(str, '^');
	case_end;

	case_ast_node(be, BinaryExpr, node);
		str = write_expr_to_string(str, be->left);
		str = gb_string_append_rune(str, ' ');
		str = string_append_token(str, be->op);
		str = gb_string_append_rune(str, ' ');
		str = write_expr_to_string(str, be->right);
	case_end;

	case_ast_node(te, TernaryExpr, node);
		str = write_expr_to_string(str, te->cond);
		str = gb_string_appendc(str, " ? ");
		str = write_expr_to_string(str, te->x);
		str = gb_string_appendc(str, " : ");
		str = write_expr_to_string(str, te->y);
	case_end;


	case_ast_node(pe, ParenExpr, node);
		str = gb_string_append_rune(str, '(');
		str = write_expr_to_string(str, pe->expr);
		str = gb_string_append_rune(str, ')');
	case_end;

	case_ast_node(se, SelectorExpr, node);
		str = write_expr_to_string(str, se->expr);
		str = gb_string_append_rune(str, '.');
		str = write_expr_to_string(str, se->selector);
	case_end;

	case_ast_node(ta, TypeAssertion, node);
		str = write_expr_to_string(str, ta->expr);
		str = gb_string_appendc(str, ".(");
		str = write_expr_to_string(str, ta->type);
		str = gb_string_append_rune(str, ')');
	case_end;

	case_ast_node(tc, TypeCast, node);
		str = string_append_token(str, tc->token);
		str = gb_string_append_rune(str, '(');
		str = write_expr_to_string(str, tc->type);
		str = gb_string_append_rune(str, ')');
		str = write_expr_to_string(str, tc->expr);
	case_end;

	case_ast_node(ac, AutoCast, node);
		str = string_append_token(str, ac->token);
		str = gb_string_append_rune(str, ' ');
		str = write_expr_to_string(str, ac->expr);
	case_end;

	case_ast_node(ie, IndexExpr, node);
		str = write_expr_to_string(str, ie->expr);
		str = gb_string_append_rune(str, '[');
		str = write_expr_to_string(str, ie->index);
		str = gb_string_append_rune(str, ']');
	case_end;

	case_ast_node(se, SliceExpr, node);
		str = write_expr_to_string(str, se->expr);
		str = gb_string_append_rune(str, '[');
		str = write_expr_to_string(str, se->low);
		str = string_append_token(str, se->interval);
		str = write_expr_to_string(str, se->high);
		str = gb_string_append_rune(str, ']');
	case_end;

	case_ast_node(e, Ellipsis, node);
		str = gb_string_appendc(str, "...");
		str = write_expr_to_string(str, e->expr);
	case_end;

	case_ast_node(fv, FieldValue, node);
		str = write_expr_to_string(str, fv->field);
		str = gb_string_appendc(str, " = ");
		str = write_expr_to_string(str, fv->value);
	case_end;

	case_ast_node(ht, HelperType, node);
		str = gb_string_appendc(str, "#type ");
		str = write_expr_to_string(str, ht->type);
	case_end;

	case_ast_node(ht, DistinctType, node);
		str = gb_string_appendc(str, "distinct ");
		str = write_expr_to_string(str, ht->type);
	case_end;

	case_ast_node(pt, PolyType, node);
		str = gb_string_append_rune(str, '$');
		str = write_expr_to_string(str, pt->type);
		if (pt->specialization != nullptr) {
			str = gb_string_append_rune(str, '/');
			str = write_expr_to_string(str, pt->specialization);
		}
	case_end;

	case_ast_node(pt, PointerType, node);
		str = gb_string_append_rune(str, '^');
		str = write_expr_to_string(str, pt->type);
	case_end;

	case_ast_node(at, ArrayType, node);
		str = gb_string_append_rune(str, '[');
		if (at->count != nullptr &&
		    at->count->kind == AstNode_UnaryExpr &&
		    at->count->UnaryExpr.op.kind == Token_Question) {
			str = gb_string_appendc(str, "?");
		} else {
			str = write_expr_to_string(str, at->count);
		}
		str = gb_string_append_rune(str, ']');
		str = write_expr_to_string(str, at->elem);
	case_end;

	case_ast_node(at, DynamicArrayType, node);
		str = gb_string_appendc(str, "[dynamic]");
		str = write_expr_to_string(str, at->elem);
	case_end;

	case_ast_node(mt, MapType, node);
		str = gb_string_appendc(str, "map[");
		str = write_expr_to_string(str, mt->key);
		str = gb_string_append_rune(str, ']');
		str = write_expr_to_string(str, mt->value);
	case_end;

	case_ast_node(f, Field, node);
		if (f->flags&FieldFlag_using) {
			str = gb_string_appendc(str, "using ");
		}
		if (f->flags&FieldFlag_no_alias) {
			str = gb_string_appendc(str, "#no_alias ");
		}
		if (f->flags&FieldFlag_c_vararg) {
			str = gb_string_appendc(str, "#c_vararg ");
		}

		for_array(i, f->names) {
			AstNode *name = f->names[i];
			if (i > 0) str = gb_string_appendc(str, ", ");
			str = write_expr_to_string(str, name);
		}
		if (f->names.count > 0) {
			if (f->type == nullptr && f->default_value != nullptr) {
				str = gb_string_append_rune(str, ' ');
			}
			str = gb_string_appendc(str, ":");
		}
		if (f->type != nullptr) {
			str = gb_string_append_rune(str, ' ');
			str = write_expr_to_string(str, f->type);
		}
		if (f->default_value != nullptr) {
			if (f->type != nullptr) {
				str = gb_string_append_rune(str, ' ');
			}
			str = gb_string_appendc(str, "= ");
			str = write_expr_to_string(str, f->default_value);
		}

	case_end;

	case_ast_node(f, FieldList, node);
		bool has_name = false;
		for_array(i, f->list) {
			ast_node(field, Field, f->list[i]);
			if (field->names.count > 1) {
				has_name = true;
				break;
			}

			if (field->names.count == 0) {
				continue;
			}
			if (!is_blank_ident(field->names[0])) {
				has_name = true;
				break;
			}
		}

		for_array(i, f->list) {
			if (i > 0) str = gb_string_appendc(str, ", ");
			if (has_name) {
				str = write_expr_to_string(str, f->list[i]);
			} else {
				ast_node(field, Field, f->list[i]);

				if (field->flags&FieldFlag_using) {
					str = gb_string_appendc(str, "using ");
				}
				if (field->flags&FieldFlag_no_alias) {
					str = gb_string_appendc(str, "#no_alias ");
				}
				if (field->flags&FieldFlag_c_vararg) {
					str = gb_string_appendc(str, "#c_vararg ");
				}

				str = write_expr_to_string(str, field->type);
			}
		}
	case_end;

	case_ast_node(f, UnionField, node);
		str = write_expr_to_string(str, f->name);
		str = gb_string_append_rune(str, '{');
		str = write_expr_to_string(str, f->list);
		str = gb_string_append_rune(str, '}');
	case_end;

	case_ast_node(ce, CallExpr, node);
		str = write_expr_to_string(str, ce->proc);
		str = gb_string_appendc(str, "(");

		for_array(i, ce->args) {
			AstNode *arg = ce->args[i];
			if (i > 0) {
				str = gb_string_appendc(str, ", ");
			}
			str = write_expr_to_string(str, arg);
		}
		str = gb_string_appendc(str, ")");
	case_end;

	case_ast_node(tt, TypeType, node);
		str = gb_string_appendc(str, "type");
		if (tt->specialization) {
			str = gb_string_appendc(str, "/");
			str = write_expr_to_string(str, tt->specialization);
		}
	case_end;

	case_ast_node(pt, ProcType, node);
		str = gb_string_appendc(str, "proc(");
		str = write_expr_to_string(str, pt->params);
		str = gb_string_appendc(str, ")");
		if (pt->results != nullptr) {
			str = gb_string_appendc(str, " -> ");
			str = write_expr_to_string(str, pt->results);
		}

	case_end;

	case_ast_node(st, StructType, node);
		str = gb_string_appendc(str, "struct ");
		if (st->is_packed)    str = gb_string_appendc(str, "#packed ");
		if (st->is_raw_union) str = gb_string_appendc(str, "#raw_union ");
		str = gb_string_append_rune(str, '{');
		str = write_struct_fields_to_string(str, st->fields);
		str = gb_string_append_rune(str, '}');
	case_end;


	case_ast_node(st, UnionType, node);
		str = gb_string_appendc(str, "union ");
		str = gb_string_append_rune(str, '{');
		str = write_struct_fields_to_string(str, st->variants);
		str = gb_string_append_rune(str, '}');
	case_end;

	case_ast_node(et, EnumType, node);
		str = gb_string_appendc(str, "enum ");
		if (et->base_type != nullptr) {
			str = write_expr_to_string(str, et->base_type);
			str = gb_string_append_rune(str, ' ');
		}
		str = gb_string_append_rune(str, '{');
		for_array(i, et->fields) {
			if (i > 0) {
				str = gb_string_appendc(str, ", ");
			}
			str = write_expr_to_string(str, et->fields[i]);
		}
		str = gb_string_append_rune(str, '}');
	case_end;
	}

	return str;
}

gbString expr_to_string(AstNode *expression) {
	return write_expr_to_string(gb_string_make(heap_allocator(), ""), expression);
}
