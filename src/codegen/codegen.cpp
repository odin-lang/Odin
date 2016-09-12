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

	ssa_init_module(&s->module, c);

	// TODO(bill): generate appropriate output name
	isize pos = string_extension_position(c->parser->init_fullpath);
	gbFileError err = gb_file_create(&s->output_file, gb_bprintf("%.*s.ll", pos, c->parser->init_fullpath.text));
	if (err != gbFileError_None)
		return false;

	return true;
}

void ssa_gen_destroy(ssaGen *s) {
	ssa_destroy_module(&s->module);
	gb_file_close(&s->output_file);
}


void ssa_gen_tree(ssaGen *s) {
	if (v_zero == NULL) {
		v_zero   = ssa_make_const_int (gb_heap_allocator(), 0);
		v_one    = ssa_make_const_int (gb_heap_allocator(), 1);
		v_zero32 = ssa_make_const_i32 (gb_heap_allocator(), 0);
		v_one32  = ssa_make_const_i32 (gb_heap_allocator(), 1);
		v_two32  = ssa_make_const_i32 (gb_heap_allocator(), 2);
		v_false  = ssa_make_const_bool(gb_heap_allocator(), false);
		v_true   = ssa_make_const_bool(gb_heap_allocator(), true);
	}

	struct ssaGlobalVariable {
		ssaValue *var, *init;
		DeclInfo *decl;
	};

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

			if (decl->init_expr != NULL) {
				TypeAndValue *tav = map_get(&info->types, hash_pointer(decl->init_expr));
				if (tav != NULL && tav->value.kind != ExactValue_Invalid) {
					ExactValue v = tav->value;
					if (v.kind == ExactValue_String) {
						// NOTE(bill): The printer will fix the value correctly
						g->Global.value = ssa_add_global_string_array(m, v.value_string);
					} else {
						g->Global.value = ssa_make_value_constant(a, tav->type, v);
					}
				}
			}

			if (g->Global.value == NULL) {
				gb_array_append(global_variables, var);
			}

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
			ssaValue *type_info_data = NULL;
			ssaValue *type_info_member_data = NULL;

			ssaValue **found = NULL;
			found = map_get(&proc->module->members, hash_string(make_string(SSA_TYPE_INFO_DATA_NAME)));
			GB_ASSERT(found != NULL);
			type_info_data = *found;

			found = map_get(&proc->module->members, hash_string(make_string(SSA_TYPE_INFO_DATA_MEMBER_NAME)));
			GB_ASSERT(found != NULL);
			type_info_member_data = *found;

			CheckerInfo *info = proc->module->info;

			// Useful types
			Type *t_int_ptr              = make_type_pointer(a, t_int);
			Type *t_bool_ptr             = make_type_pointer(a, t_bool);
			Type *t_string_ptr           = make_type_pointer(a, t_string);
			Type *t_type_info_ptr_ptr    = make_type_pointer(a, t_type_info_ptr);


			auto get_type_info_ptr = [](ssaProcedure *proc, ssaValue *type_info_data, Type *type) -> ssaValue * {
				return ssa_emit_struct_gep(proc, type_info_data,
				                           ssa_type_info_index(proc->module->info, type),
				                           t_type_info_ptr);
			};

			isize type_info_member_index = 0;

			auto type_info_member_offset = [](ssaProcedure *proc, ssaValue *data, isize count, isize *index) -> ssaValue * {
				ssaValue *offset = ssa_emit_struct_gep(proc, data, *index, t_type_info_member_ptr);
				*index += count;
				return offset;
			};


			gb_for_array(entry_index, info->type_info_map.entries) {
				auto *entry = &info->type_info_map.entries[entry_index];
				Type *t = cast(Type *)cast(uintptr)entry->key.key;

				ssaValue *tag = NULL;

				switch (t->kind) {
				case Type_Named: {
					tag = ssa_add_local_generated(proc, t_type_info_named);

					// TODO(bill): Which is better? The mangled name or actual name?
					// ssaValue *gsa  = ssa_add_global_string_array(proc, make_exact_value_string(t->Named.name));
					ssaValue *gsa  = ssa_add_global_string_array(m, t->Named.type_name->token.string);
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
						ssaValue *bits      = ssa_make_const_int(a, type_size_of(m->sizes, a, t));
						ssaValue *is_signed = ssa_make_const_bool(a, !is_unsigned);
						ssa_emit_store(proc, ssa_emit_struct_gep(proc, tag, v_zero32, t_int_ptr),  bits);
						ssa_emit_store(proc, ssa_emit_struct_gep(proc, tag, v_one32,  t_bool_ptr), is_signed);
					} break;

					case Basic_f32:
					case Basic_f64: {
						tag = ssa_add_local_generated(proc, t_type_info_float);
						ssaValue *bits = ssa_make_const_int(a, type_size_of(m->sizes, a, t));
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

					isize ez = type_size_of(m->sizes, a, t->Array.elem);
					ssaValue *elem_size = ssa_emit_struct_gep(proc, tag, v_one32, t_int_ptr);
					ssa_emit_store(proc, elem_size, ssa_make_const_int(a, ez));

					ssaValue *count = ssa_emit_struct_gep(proc, tag, v_two32, t_int_ptr);
					ssa_emit_store(proc, count, ssa_make_const_int(a, t->Array.count));

				} break;
				case Type_Slice: {
					tag = ssa_add_local_generated(proc, t_type_info_slice);
					ssaValue *gep = get_type_info_ptr(proc, type_info_data, t->Slice.elem);
					ssa_emit_store(proc, ssa_emit_struct_gep(proc, tag, v_zero32, t_type_info_ptr_ptr), gep);

					isize ez = type_size_of(m->sizes, a, t->Slice.elem);
					ssaValue *elem_size = ssa_emit_struct_gep(proc, tag, v_one32, t_int_ptr);
					ssa_emit_store(proc, elem_size, ssa_make_const_int(a, ez));

				} break;
				case Type_Vector: {
					tag = ssa_add_local_generated(proc, t_type_info_vector);
					ssaValue *gep = get_type_info_ptr(proc, type_info_data, t->Vector.elem);
					ssa_emit_store(proc, ssa_emit_struct_gep(proc, tag, v_zero32, t_type_info_ptr_ptr), gep);

					isize ez = type_size_of(m->sizes, a, t->Vector.elem);
					ssaValue *elem_size = ssa_emit_struct_gep(proc, tag, v_one32, t_int_ptr);
					ssa_emit_store(proc, elem_size, ssa_make_const_int(a, ez));

					ssaValue *count = ssa_emit_struct_gep(proc, tag, v_two32, t_int_ptr);
					ssa_emit_store(proc, count, ssa_make_const_int(a, t->Vector.count));

				} break;
				case Type_Record: {
					switch (t->Record.kind) {
					case TypeRecord_Struct: {
						tag = ssa_add_local_generated(proc, t_type_info_struct);

						ssaValue *memory = type_info_member_offset(proc, type_info_member_data, t->Record.field_count, &type_info_member_index);

						type_set_offsets(m->sizes, a, t); // NOTE(bill): Just incase the offsets have not been set yet
						for (isize i = 0; i < t->Record.field_count; i++) {
							// NOTE(bill): Order fields in source order not layout order
							Entity *f = t->Record.fields[i];
							ssaValue *tip = get_type_info_ptr(proc, type_info_data, f->type);
							i64 foffset = t->Record.struct_offsets[i];
							GB_ASSERT(f->kind == Entity_Variable && f->Variable.is_field);
							isize source_index = f->Variable.field_index;

							ssaValue *field     = ssa_emit_ptr_offset(proc, memory, ssa_make_const_int(a, source_index));
							ssaValue *name      = ssa_emit_struct_gep(proc, field, v_zero32, t_string_ptr);
							ssaValue *type_info = ssa_emit_struct_gep(proc, field, v_one32, t_type_info_ptr_ptr);
							ssaValue *offset    = ssa_emit_struct_gep(proc, field, v_two32, t_int_ptr);

							if (f->token.string.len > 0) {
								ssa_emit_store(proc, name, ssa_emit_global_string(proc, f->token.string));
							}
							ssa_emit_store(proc, type_info, tip);
							ssa_emit_store(proc, offset, ssa_make_const_int(a, foffset));
						}

						Type *slice_type = make_type_slice(a, t_type_info_member);
						Type *slice_type_ptr = make_type_pointer(a, slice_type);
						ssaValue *slice = ssa_emit_struct_gep(proc, tag, v_zero32, slice_type_ptr);
						ssaValue *field_count = ssa_make_const_int(a, t->Record.field_count);

						ssaValue *elem = ssa_emit_struct_gep(proc, slice, v_zero32, make_type_pointer(a, t_type_info_member_ptr));
						ssaValue *len  = ssa_emit_struct_gep(proc, slice, v_one32,  make_type_pointer(a, t_int_ptr));
						ssaValue *cap  = ssa_emit_struct_gep(proc, slice, v_two32,  make_type_pointer(a, t_int_ptr));

						ssa_emit_store(proc, elem, memory);
						ssa_emit_store(proc, len, field_count);
						ssa_emit_store(proc, cap, field_count);
					} break;
					case TypeRecord_Union:
						tag = ssa_add_local_generated(proc, t_type_info_union);
						break;
					case TypeRecord_RawUnion: {
						tag = ssa_add_local_generated(proc, t_type_info_raw_union);

						ssaValue *memory = type_info_member_offset(proc, type_info_member_data, t->Record.field_count, &type_info_member_index);

						for (isize i = 0; i < t->Record.field_count; i++) {
							ssaValue *field     = ssa_emit_ptr_offset(proc, memory, ssa_make_const_int(a, i));
							ssaValue *name      = ssa_emit_struct_gep(proc, field, v_zero32, t_string_ptr);
							ssaValue *type_info = ssa_emit_struct_gep(proc, field, v_one32, t_type_info_ptr_ptr);
							ssaValue *offset    = ssa_emit_struct_gep(proc, field, v_two32, t_int_ptr);

							Entity *f = t->Record.fields[i];
							ssaValue *tip = get_type_info_ptr(proc, type_info_data, f->type);

							if (f->token.string.len > 0) {
								ssa_emit_store(proc, name, ssa_emit_global_string(proc, f->token.string));
							}
							ssa_emit_store(proc, type_info, tip);
							ssa_emit_store(proc, offset, ssa_make_const_int(a, 0));
						}

						Type *slice_type = make_type_slice(a, t_type_info_member);
						Type *slice_type_ptr = make_type_pointer(a, slice_type);
						ssaValue *slice = ssa_emit_struct_gep(proc, tag, v_zero32, slice_type_ptr);
						ssaValue *field_count = ssa_make_const_int(a, t->Record.field_count);

						ssaValue *elem = ssa_emit_struct_gep(proc, slice, v_zero32, make_type_pointer(a, t_type_info_member_ptr));
						ssaValue *len  = ssa_emit_struct_gep(proc, slice, v_one32,  make_type_pointer(a, t_int_ptr));
						ssaValue *cap  = ssa_emit_struct_gep(proc, slice, v_two32,  make_type_pointer(a, t_int_ptr));

						ssa_emit_store(proc, elem, memory);
						ssa_emit_store(proc, len, field_count);
						ssa_emit_store(proc, cap, field_count);
					} break;
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

				case Type_Tuple: {
					tag = ssa_add_local_generated(proc, t_type_info_tuple);

					ssaValue *memory = type_info_member_offset(proc, type_info_member_data, t->Tuple.variable_count, &type_info_member_index);

					for (isize i = 0; i < t->Tuple.variable_count; i++) {
						ssaValue *field     = ssa_emit_ptr_offset(proc, memory, ssa_make_const_int(a, i));
						ssaValue *name      = ssa_emit_struct_gep(proc, field, v_zero32, t_string_ptr);
						ssaValue *type_info = ssa_emit_struct_gep(proc, field, v_one32, t_type_info_ptr_ptr);
						// NOTE(bill): offset is not used for tuples

						Entity *f = t->Tuple.variables[i];
						ssaValue *tip = get_type_info_ptr(proc, type_info_data, f->type);

						if (f->token.string.len > 0) {
							ssa_emit_store(proc, name, ssa_emit_global_string(proc, f->token.string));
						}
						ssa_emit_store(proc, type_info, tip);
					}

					Type *slice_type = make_type_slice(a, t_type_info_member);
					Type *slice_type_ptr = make_type_pointer(a, slice_type);
					ssaValue *slice = ssa_emit_struct_gep(proc, tag, v_zero32, slice_type_ptr);
					ssaValue *variable_count = ssa_make_const_int(a, t->Tuple.variable_count);

					ssaValue *elem = ssa_emit_struct_gep(proc, slice, v_zero32, make_type_pointer(a, t_type_info_member_ptr));
					ssaValue *len  = ssa_emit_struct_gep(proc, slice, v_one32,  make_type_pointer(a, t_int_ptr));
					ssaValue *cap  = ssa_emit_struct_gep(proc, slice, v_two32,  make_type_pointer(a, t_int_ptr));

					ssa_emit_store(proc, elem, memory);
					ssa_emit_store(proc, len, variable_count);
					ssa_emit_store(proc, cap, variable_count);
				} break;

				case Type_Proc: {
					tag = ssa_add_local_generated(proc, t_type_info_procedure);

					ssaValue *params   = ssa_emit_struct_gep(proc, tag, v_zero32, t_type_info_ptr_ptr);
					ssaValue *results  = ssa_emit_struct_gep(proc, tag, v_one32,  t_type_info_ptr_ptr);
					ssaValue *variadic = ssa_emit_struct_gep(proc, tag, v_two32,  t_bool_ptr);


					ssa_emit_store(proc, params,   get_type_info_ptr(proc, type_info_data, t->Proc.params));
					ssa_emit_store(proc, results,  get_type_info_ptr(proc, type_info_data, t->Proc.results));
					ssa_emit_store(proc, variadic, ssa_make_const_bool(a, t->Proc.variadic));

					// TODO(bill): Type_Info for procedures
				} break;
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
