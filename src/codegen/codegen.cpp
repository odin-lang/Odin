#include "ssa.cpp"
#include "print_llvm.cpp"

struct ssaGen {
	ssaModule module;
	gbFile output_file;
};

b32 ssa_gen_init(ssaGen *s, Checker *c) {
	if (c->error_collector.count != 0)
		return false;

	gb_for_array(i, c->parser->files) {
		AstFile *f = &c->parser->files[i];
		if (f->error_collector.count != 0)
			return false;
		if (f->tokenizer.error_count != 0)
			return false;
	}

	isize tc = c->parser->total_token_count;
	if (tc < 2) {
		return false;
	}

	ssa_module_init(&s->module, c);

	// TODO(bill): generate appropriate output name
	isize pos = string_extension_position(c->parser->init_fullpath);
	gbFileError err = gb_file_create(&s->output_file, gb_bprintf("%.*s.ll", pos, c->parser->init_fullpath.text));
	if (err != gbFileError_None)
		return false;

#if 0
	Map<i32> type_map; // Key: Type *
	map_init(&type_map, gb_heap_allocator());
	i32 index = 0;
	gb_for_array(i, c->info.types.entries) {
		TypeAndValue tav = c->info.types.entries[i].value;
		Type *type = tav.type;
		HashKey key = hash_pointer(type);
		auto found = map_get(&type_map, key);
		if (!found) {
			map_set(&type_map, key, index);
			index++;
		}
	}
	gb_for_array(i, type_map.entries) {
		auto *e = &type_map.entries[i];
		Type *t = cast(Type *)cast(uintptr)e->key.key;
		gb_printf("%s\n", type_to_string(t));
	}
#endif

	return true;
}

void ssa_gen_destroy(ssaGen *s) {
	ssa_module_destroy(&s->module);
	gb_file_close(&s->output_file);
}

struct ssaGlobalVariable {
	ssaValue *var, *init;
	DeclInfo *decl;
};

void ssa_gen_tree(ssaGen *s) {
	if (v_zero == NULL) {
		v_zero   = ssa_make_value_constant(gb_heap_allocator(), t_int,  make_exact_value_integer(0));
		v_one    = ssa_make_value_constant(gb_heap_allocator(), t_int,  make_exact_value_integer(1));
		v_zero32 = ssa_make_value_constant(gb_heap_allocator(), t_i32,  make_exact_value_integer(0));
		v_one32  = ssa_make_value_constant(gb_heap_allocator(), t_i32,  make_exact_value_integer(1));
		v_two32  = ssa_make_value_constant(gb_heap_allocator(), t_i32,  make_exact_value_integer(2));
		v_false  = ssa_make_value_constant(gb_heap_allocator(), t_bool, make_exact_value_bool(false));
		v_true   = ssa_make_value_constant(gb_heap_allocator(), t_bool, make_exact_value_bool(true));
	}

	ssaModule *m = &s->module;
	CheckerInfo *info = m->info;
	gbAllocator a = m->allocator;
	gbArray(ssaGlobalVariable) global_variables;
	gb_array_init(global_variables, gb_heap_allocator());
	defer (gb_array_free(global_variables));

	gb_for_array(i, info->entities.entries) {
		auto *entry = &info->entities.entries[i];
		Entity *e = cast(Entity *)cast(uintptr)entry->key.key;
		DeclInfo *decl = entry->value;

		String name = e->token.string;

		switch (e->kind) {
		case Entity_TypeName:
			ssa_gen_global_type_name(m, e, name);
			break;

		case Entity_Variable: {
			ssaValue *g = ssa_make_value_global(a, e, NULL);
			if (decl->var_decl_tags & VarDeclTag_thread_local) {
				g->Global.is_thread_local = true;
			}
			ssaGlobalVariable var = {};
			var.var = g;
			var.decl = decl;
			gb_array_append(global_variables, var);
			map_set(&m->values, hash_pointer(e), g);
			map_set(&m->members, hash_string(name), g);
		} break;

		case Entity_Procedure: {
			auto *pd = &decl->proc_decl->ProcDecl;
			String original_name = e->token.string;
			String name = original_name;
			AstNode *body = pd->body;
			if (pd->foreign_name.len > 0) {
				name = pd->foreign_name;
			}

			if (are_strings_equal(name, original_name)) {
				Scope *scope = *map_get(&info->scopes, hash_pointer(pd->type));
				isize count = multi_map_count(&scope->elements, hash_string(original_name));
				if (count > 1) {
					gb_printf("%.*s\n", LIT(name));
					isize name_len = name.len + 1 + 10 + 1;
					u8 *name_text = gb_alloc_array(m->allocator, u8, name_len);
					name_len = gb_snprintf(cast(char *)name_text, name_len, "%.*s$%d", LIT(name), e->guid);
					name = make_string(name_text, name_len-1);
				}
			}

			ssaValue *p = ssa_make_value_procedure(a, m, e->type, decl->type_expr, body, name);
			p->Proc.tags = pd->tags;

			map_set(&m->values, hash_pointer(e), p);
			HashKey hash_name = hash_string(name);
			if (map_get(&m->members, hash_name) == NULL) {
				map_set(&m->members, hash_name, p);
			}
		} break;
		}
	}

	gb_for_array(i, m->members.entries) {
		auto *entry = &m->members.entries[i];
		ssaValue *v = entry->value;
		if (v->kind == ssaValue_Proc)
			ssa_build_proc(v, NULL);
	}



	{ // Startup Runtime
		// Cleanup(bill): probably better way of doing code insertion
		String name = make_string(SSA_STARTUP_RUNTIME_PROC_NAME);
		Type *proc_type = make_type_proc(a, gb_alloc_item(a, Scope),
		                                 NULL, 0,
		                                 NULL, 0, false);
		AstNode *body = gb_alloc_item(a, AstNode);
		ssaValue *p = ssa_make_value_procedure(a, m, proc_type, NULL, body, name);
		Token token = {};
		token.string = name;
		Entity *e = make_entity_procedure(a, NULL, token, proc_type);

		map_set(&m->values, hash_pointer(e), p);
		map_set(&m->members, hash_string(name), p);

		ssaProcedure *proc = &p->Proc;
		proc->tags = ProcTag_no_inline; // TODO(bill): is no_inline a good idea?

		ssa_begin_procedure_body(proc);

		// TODO(bill): Should do a dependency graph do check which order to initialize them in?
		gb_for_array(i, global_variables) {
			ssaGlobalVariable *var = &global_variables[i];
			if (var->decl->init_expr != NULL) {
				var->init = ssa_build_expr(proc, var->decl->init_expr);
			}
		}

		// NOTE(bill): Initialize constants first
		gb_for_array(i, global_variables) {
			ssaGlobalVariable *var = &global_variables[i];
			if (var->init != NULL) {
				if (var->init->kind == ssaValue_Constant) {
					ssa_emit_store(proc, var->var, var->init);
				}
			}
		}

		gb_for_array(i, global_variables) {
			ssaGlobalVariable *var = &global_variables[i];
			if (var->init != NULL) {
				if (var->init->kind != ssaValue_Constant) {
					ssa_emit_store(proc, var->var, var->init);
				}
			}
		}

		ssa_end_procedure_body(proc);
	}


	// m->layout = make_string("e-p:64:64:64-i1:8:8-i8:8:8-i16:16:16-i32:32:32-i64:64:64-f32:32:32-f64:64:64-v64:64:64-v128:128:128-a0:0:64-s0:64:64-f80:128:128-n8:16:32:64");


}


void ssa_gen_ir(ssaGen *s) {
	ssa_print_llvm_ir(&s->output_file, &s->module);
}
