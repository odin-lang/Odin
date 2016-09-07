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
			#if 0
				Scope *scope = *map_get(&info->scopes, hash_pointer(pd->type));
				isize count = multi_map_count(&scope->elements, hash_string(original_name));
				if (count > 1) {
					gb_printf("%.*s\n", LIT(name));
					isize name_len = name.len + 1 + 10 + 1;
					u8 *name_text = gb_alloc_array(m->allocator, u8, name_len);
					name_len = gb_snprintf(cast(char *)name_text, name_len, "%.*s$%d", LIT(name), e->guid);
					name = make_string(name_text, name_len-1);
				}
			#endif
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

		{ // NOTE(bill): Setup type_info data
			ssaValue **found = map_get(&proc->module->members, hash_string(make_string("__type_info_data")));
			GB_ASSERT(found != NULL);
			ssaValue *type_info_data = *found;
			CheckerInfo *info = proc->module->info;


			Type *t_int_ptr           = make_type_pointer(a, t_int);
			Type *t_bool_ptr          = make_type_pointer(a, t_bool);
			Type *t_string_ptr        = make_type_pointer(a, t_string);
			Type *t_type_info_ptr_ptr = make_type_pointer(a, t_type_info_ptr);

			auto get_type_info_ptr = [](ssaProcedure *proc, ssaValue *type_info_data, Type *type) -> ssaValue * {
				auto *info = proc->module->info;
				MapFindResult fr = map__find(&info->type_info_types, hash_pointer(type));
				GB_ASSERT(fr.entry_index >= 0);
				return ssa_emit_struct_gep(proc, type_info_data, fr.entry_index, t_type_info_ptr);
			};


			gb_for_array(entry_index, info->type_info_types.entries) {
				auto *entry = &info->type_info_types.entries[entry_index];
				Type *t = entry->value;

				ssaValue *tag = NULL;

				switch (t->kind) {
				case Type_Named: {
					tag = ssa_add_local_generated(proc, t_type_info_named);

					ssaValue *gsa  = ssa_add_global_string_array(proc, make_exact_value_string(t->Named.name));
					ssaValue *elem = ssa_array_elem(proc, gsa);
					ssaValue *len  = ssa_array_len(proc, ssa_emit_load(proc, gsa));
					ssaValue *name = ssa_emit_string(proc, elem, len);

					ssaValue *gep  = get_type_info_ptr(proc, type_info_data, t->Named.base);

					ssa_emit_store(proc, ssa_emit_struct_gep(proc, tag, v_zero,  t_string_ptr), name);
					ssa_emit_store(proc, ssa_emit_struct_gep(proc, tag, v_one32, t_type_info_ptr), gep);
				} break;

				case Type_Basic:
					switch (t->Basic.kind) {
					case Basic_bool:
						tag = ssa_add_local_generated(proc, t_type_info_boolean);
						break;
					case Basic_i8:
					case Basic_i16:
					case Basic_i32:
					case Basic_i64:
					case Basic_i128:
					case Basic_u8:
					case Basic_u16:
					case Basic_u32:
					case Basic_u64:
					case Basic_u128:
					case Basic_int:
					case Basic_uint: {
						tag = ssa_add_local_generated(proc, t_type_info_integer);
						b32 is_unsigned = (basic_types[t->Basic.kind].flags & BasicFlag_Unsigned) != 0;
						ssaValue *bits      = ssa_make_value_constant(a, t_int, make_exact_value_integer(type_size_of(m->sizes, a, t)));
						ssaValue *is_signed = ssa_make_value_constant(a, t_bool, make_exact_value_bool(!is_unsigned));
						ssa_emit_store(proc, ssa_emit_struct_gep(proc, tag, v_zero32, t_int_ptr),  bits);
						ssa_emit_store(proc, ssa_emit_struct_gep(proc, tag, v_one32,  t_bool_ptr), is_signed);
					} break;

					case Basic_f32:
					case Basic_f64: {
						tag = ssa_add_local_generated(proc, t_type_info_float);
						ssaValue *bits = ssa_make_value_constant(a, t_int, make_exact_value_integer(type_size_of(m->sizes, a, t)));
						ssa_emit_store(proc, ssa_emit_struct_gep(proc, tag, v_zero32, t_int_ptr), bits);
					} break;

					case Basic_rawptr:
						tag = ssa_add_local_generated(proc, t_type_info_pointer);
						break;

					case Basic_string:
						tag = ssa_add_local_generated(proc, t_type_info_string);
						break;
					}
					break;

				case Type_Pointer: {
					tag = ssa_add_local_generated(proc, t_type_info_pointer);
					ssaValue *gep = get_type_info_ptr(proc, type_info_data, t->Pointer.elem);
					ssa_emit_store(proc, ssa_emit_struct_gep(proc, tag, v_zero32, t_type_info_ptr_ptr), gep);
				} break;
				case Type_Array: {
					tag = ssa_add_local_generated(proc, t_type_info_array);
					ssaValue *gep = get_type_info_ptr(proc, type_info_data, t->Array.elem);
					ssa_emit_store(proc, ssa_emit_struct_gep(proc, tag, v_zero32, t_type_info_ptr_ptr), gep);
				} break;
				case Type_Slice: {
					tag = ssa_add_local_generated(proc, t_type_info_slice);
					ssaValue *gep = get_type_info_ptr(proc, type_info_data, t->Slice.elem);
					ssa_emit_store(proc, ssa_emit_struct_gep(proc, tag, v_zero32, t_type_info_ptr_ptr), gep);
				} break;
				case Type_Vector: {
					tag = ssa_add_local_generated(proc, t_type_info_vector);
					ssaValue *gep = get_type_info_ptr(proc, type_info_data, t->Vector.elem);
					ssa_emit_store(proc, ssa_emit_struct_gep(proc, tag, v_zero32, t_type_info_ptr_ptr), gep);
				} break;
				case Type_Record: {
					switch (t->Record.kind) {
					// TODO(bill): Record members for `Type_Info`
					case TypeRecord_Struct:
						tag = ssa_add_local_generated(proc, t_type_info_struct);
						break;
					case TypeRecord_Union:
						tag = ssa_add_local_generated(proc, t_type_info_union);
						break;
					case TypeRecord_RawUnion:
						tag = ssa_add_local_generated(proc, t_type_info_raw_union);
						break;
					case TypeRecord_Enum: {
						tag = ssa_add_local_generated(proc, t_type_info_enum);
						Type *enum_base = t->Record.enum_base;
						if (enum_base == NULL) {
							enum_base = t_int;
						}
						ssaValue *gep = get_type_info_ptr(proc, type_info_data, enum_base);
						ssa_emit_store(proc, ssa_emit_struct_gep(proc, tag, v_zero32, t_type_info_ptr_ptr), gep);
					} break;
					}
				} break;

				case Type_Tuple:
					// TODO(bill): Type_Info for tuples
					break;
				case Type_Proc:
					// TODO(bill): Type_Info for procedures
					break;
				}

				if (tag != NULL) {
					ssaValue *gep = ssa_emit_struct_gep(proc, type_info_data, entry_index, t_type_info_ptr);
					ssaValue *val = ssa_emit_conv(proc, ssa_emit_load(proc, tag), t_type_info);
					ssa_emit_store(proc, gep, val);
				}
			}
		}

		ssa_end_procedure_body(proc);
	}


	// m->layout = make_string("e-p:64:64:64-i1:8:8-i8:8:8-i16:16:16-i32:32:32-i64:64:64-f32:32:32-f64:64:64-v64:64:64-v128:128:128-a0:0:64-s0:64:64-f80:128:128-n8:16:32:64");


}


void ssa_gen_ir(ssaGen *s) {
	ssaFileBuffer buf = {};
	ssa_file_buffer_init(&buf, &s->output_file);
	defer (ssa_file_buffer_destroy(&buf));

	ssa_print_llvm_ir(&buf, &s->module);
}
