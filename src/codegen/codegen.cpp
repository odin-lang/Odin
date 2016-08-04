#include "ssa.cpp"
#include "print_llvm.cpp"

struct ssaGen {
	ssaModule module;
	gbFile output_file;
};

b32 ssa_gen_init(ssaGen *s, Checker *c) {
	if (c->error_collector.count > 0)
		return false;

	gb_for_array(i, c->parser->files) {
		AstFile *f = &c->parser->files[i];
		if (f->error_collector.count > 0)
			return false;
		if (f->tokenizer.error_count > 0)
			return false;
	}

	ssa_module_init(&s->module, c);

	gbFileError err = gb_file_create(&s->output_file, "../examples/test.ll");
	if (err != gbFileError_None)
		return false;

	return true;
}

void ssa_gen_destroy(ssaGen *s) {
	ssa_module_destroy(&s->module);
	gb_file_close(&s->output_file);
}

void ssa_gen_code(ssaGen *s) {
	if (v_zero == NULL) {
		v_zero   = ssa_make_value_constant(gb_heap_allocator(), t_int, make_exact_value_integer(0));
		v_one    = ssa_make_value_constant(gb_heap_allocator(), t_int, make_exact_value_integer(1));
		v_zero32 = ssa_make_value_constant(gb_heap_allocator(), t_i32, make_exact_value_integer(0));
		v_one32  = ssa_make_value_constant(gb_heap_allocator(), t_i32, make_exact_value_integer(1));
		v_two32  = ssa_make_value_constant(gb_heap_allocator(), t_i32, make_exact_value_integer(2));
	}

	ssaModule *m = &s->module;
	CheckerInfo *info = m->info;
	gbAllocator a = m->allocator;

	gb_for_array(i, info->entities.entries) {
		auto *entry = &info->entities.entries[i];
		Entity *e = cast(Entity *)cast(uintptr)entry->key;
		DeclInfo *decl = entry->value;

		String name = e->token.string;

		switch (e->kind) {
		case Entity_TypeName: {
			ssaValue *t = ssa_make_value_type_name(a, e);
			map_set(&m->members, hash_string(name), t);
		} break;

		case Entity_Variable: {
			ssaValue *g = ssa_make_value_global(a, e, NULL);
			map_set(&m->values, hash_pointer(e), g);
			map_set(&m->members, hash_string(name), g);
		} break;

		case Entity_Procedure: {
			ssaValue *p = ssa_make_value_procedure(a, e, decl, m);
			map_set(&m->values, hash_pointer(e), p);
			map_set(&m->members, hash_string(name), p);
		} break;
		}
	}

	gb_for_array(i, m->members.entries) {
		auto *entry = &m->members.entries[i];
		ssaValue *v = entry->value;
		if (v->kind == ssaValue_Proc)
			ssa_build_proc(v);
	}

	ssa_print_llvm_ir(&s->output_file, &s->module);
}





#if 0
#include "type.cpp"
#include "ir.cpp"

struct Codegen {
	Checker *checker;
	gbFile file;
	gbAllocator allocator;

	irModule module;

	ErrorCollector error_collector;
};

b32 init_codegen(Codegen *c, Checker *checker) {
	c->checker = checker;

	if (c->error_collector.count != 0)
		return false;
	for (isize i = 0; i < gb_array_count(checker->parser->files); i++) {
		AstFile *f = &checker->parser->files[i];
		if (f->error_collector.count != 0)
			return false;
		if (f->tokenizer.error_count != 0)
			return false;
	}

	c->allocator = gb_heap_allocator();

	ir_module_init(&c->module, c->checker);

	return true;
}

void destroy_codegen(Codegen *c) {
	ir_module_destroy(&c->module);
}

b32 is_blank_identifier(AstNode *identifier) {
	if (identifier->kind == AstNode_Identifier) {
		return are_strings_equal(identifier->identifier.token.string, make_string("_"));
	}
	return false;
}


irValue *ir_add_basic_block(gbAllocator a, irValue *p, String label) {
	irValue *b = ir_make_value_basic_block(a, gb_array_count(p->procedure.blocks), label, p);
	gb_array_append(p->procedure.blocks, b);
	return b;
}

irValue *ir_emit_from_block(irValue *b, irInstruction *i) {
	GB_ASSERT(b->kind == irValue_BasicBlock);
	i->block = b;
	gb_array_append(b->basic_block.instructions, i);
	return ir_make_value_instruction(gb_heap_allocator(), i);
}


irValue *ir_emit(irValue *p, irInstruction *i) {
	GB_ASSERT(p->kind == irValue_Procedure);
	return ir_emit_from_block(p->procedure.curr_block, i);
}


irInstruction *ir_add_local(irValue *p, Type *type, TokenPos pos) {
	irInstruction *i = ir_alloc_instruction(gb_heap_allocator(), irInstruction_Alloca);
	i->reg.type = type;
	i->reg.pos = pos;
	gb_array_append(p->procedure.locals, ir_emit(p, i));
	return i;
}

irInstruction *ir_add_named_local(irValue *p, Entity *e) {
	irInstruction *i = ir_add_local(p, e->type, e->token.pos);
	i->alloca.label = e->token.string;
	// map_set(&p->procedure.variables, hash_pointer(e), );
	return i;
}

irInstruction *ir_add_local_for_identifier(irValue *p, AstNode *i) {
	GB_ASSERT(p->kind == irValue_Procedure);
	GB_ASSERT(i->kind == AstNode_Identifier);
	auto *found = map_get(&p->procedure.module->checker->definitions, hash_pointer(i));
	return ir_add_named_local(p, *found);
}


void ir_build_variable_declaration(irValue *p, AstNode *d) {
	GB_ASSERT(p->kind == irValue_Procedure);
	auto *vd = &d->variable_declaration;

	if (vd->name_count == vd->value_count) {
		AstNode *name = vd->name_list;
		AstNode *value = vd->value_list;
		for (;
		     name != NULL && value != NULL;
		     name = name->next, value = value->next) {
			if (!is_blank_identifier(name)) {
				ir_add_local_for_identifier(p, name);
			}
			// auto lvalue = build_address(p, name, false);
			// build_assignment(p, lvalue, value, true, NULL);
		}
	} else if (vd->value_count == 0) {
		AstNode *name = vd->name_list;
		for (;
		     name != NULL;
		     name = name->next) {
			if (!is_blank_identifier(name)) {

			}

			// build_assignment(p, )
		}
	} else {
		// TODO(bill): Tuple
	}

}


void ir_build_expression(irValue *p, AstNode *e) {
	GB_ASSERT(p->kind == irValue_Procedure);

}


void ir_build_statement(irValue *p, AstNode *s);

void ir_build_statement_list(irValue *p, AstNode *list) {
	GB_ASSERT(p->kind == irValue_Procedure);
	for (AstNode *item = list; item != NULL; item = item->next) {
		ir_build_statement(p, item);
	}
}

void ir_build_statement(irValue *p, AstNode *s) {
	GB_ASSERT(p->kind == irValue_Procedure);

	switch (s->kind) {
	case AstNode_EmptyStatement:
		break;

	case AstNode_VariableDeclaration: {
		auto *vd = &s->variable_declaration;
		if (vd->kind == Declaration_Mutable) {
			ir_build_variable_declaration(p, s);
		}
	} break;


	case AstNode_ExpressionStatement:
		ir_build_expression(p, s->expression_statement.expression);
		break;

	case AstNode_BlockStatement:
		ir_build_statement_list(p, s->block_statement.list);
		break;
	}

}





void ir_begin_procedure_body(irValue *p) {
	gbAllocator a = gb_heap_allocator();
	p->procedure.curr_block = ir_add_basic_block(a, p, make_string("entry"));
	map_init(&p->procedure.variables, a);
}

void ir_end_procedure_body(irValue *p) {
	p->procedure.curr_block = NULL;
	map_destroy(&p->procedure.variables);
}


void ir_build_procedure(irModule *m, irValue *p) {
	if (p->procedure.blocks != NULL)
		return;
	AstNode *proc_type = NULL;
	AstNode *body = NULL;
	switch (p->procedure.node->kind) {
	case AstNode_ProcedureDeclaration:
		proc_type = p->procedure.node->procedure_declaration.procedure_type;
		body = p->procedure.node->procedure_declaration.body;
		break;
	case AstNode_ProcedureLiteral:
		proc_type = p->procedure.node->procedure_literal.type;
		body = p->procedure.node->procedure_literal.body;
		break;
	default:
		return;
	}

	if (body == NULL) {
		// NOTE(bill): External procedure
		return;
	}

	defer (gb_printf("build procedure %.*s\n", LIT(p->procedure.token.string)));


	ir_begin_procedure_body(p);
	ir_build_statement(p, body);
	ir_end_procedure_body(p);
}

void ir_build_proc_decl(irModule *m, AstNode *decl) {
	GB_ASSERT(decl != NULL);
	auto *pd = &decl->procedure_declaration;
	if (is_blank_identifier(pd->name))
		return;

	Entity *e = entity_of_identifier(m->checker, pd->name);
	irValue *p = *map_get(&m->values, hash_pointer(e));
	ir_build_procedure(m, p);
}



void generate_code(Codegen *c) {
	gbAllocator a = gb_heap_allocator();

	ir_module_create(&c->module);

	for (isize i = 0; i < gb_array_count(c->module.values.entries); i++) {
		irValue *v = c->module.values.entries[i].value;
		switch (v->kind) {
		case irValue_Procedure:
			ir_build_proc_decl(&c->module, v->procedure.node);
			break;
		}
	}
}
#endif
