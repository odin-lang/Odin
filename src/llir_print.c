typedef struct llirFileBuffer {
	gbVirtualMemory vm;
	isize           offset;
	gbFile *        output;
} llirFileBuffer;

void llir_file_buffer_init(llirFileBuffer *f, gbFile *output) {
	isize size = 8*gb_virtual_memory_page_size(NULL);
	f->vm = gb_vm_alloc(NULL, size);
	f->offset = 0;
	f->output = output;
}

void llir_file_buffer_destroy(llirFileBuffer *f) {
	if (f->offset > 0) {
		// NOTE(bill): finish writing buffered data
		gb_file_write(f->output, f->vm.data, f->offset);
	}

	gb_vm_free(f->vm);
}

void llir_file_buffer_write(llirFileBuffer *f, void *data, isize len) {
	if (len > f->vm.size) {
		gb_file_write(f->output, data, len);
		return;
	}

	if ((f->vm.size - f->offset) < len) {
		gb_file_write(f->output, f->vm.data, f->offset);
		f->offset = 0;
	}
	u8 *cursor = cast(u8 *)f->vm.data + f->offset;
	gb_memmove(cursor, data, len);
	f->offset += len;
}


void llir_fprintf(llirFileBuffer *f, char *fmt, ...) {
	va_list va;
	va_start(va, fmt);
	char buf[4096] = {0};
	isize len = gb_snprintf_va(buf, gb_size_of(buf), fmt, va);
	llir_file_buffer_write(f, buf, len-1);
	va_end(va);
}


void llir_file_write(llirFileBuffer *f, void *data, isize len) {
	llir_file_buffer_write(f, data, len);
}


bool llir_valid_char(u8 c) {
	if (c >= 0x80) {
		return false;
	}

	if (gb_char_is_alphanumeric(c)) {
		return true;
	}

	switch (c) {
	case '$':
	case '-':
	case '.':
	case '_':
		return true;
	}

	return false;
}

void llir_print_escape_string(llirFileBuffer *f, String name, bool print_quotes) {
	isize extra = 0;
	for (isize i = 0; i < name.len; i++) {
		u8 c = name.text[i];
		if (!llir_valid_char(c)) {
			extra += 2;
		}
	}

	if (extra == 0) {
		llir_fprintf(f, "%.*s", LIT(name));
		return;
	}


	char hex_table[] = "0123456789ABCDEF";
	isize buf_len = name.len + extra + 2;

	gbTempArenaMemory tmp = gb_temp_arena_memory_begin(&string_buffer_arena);

	u8 *buf = gb_alloc_array(string_buffer_allocator, u8, buf_len);

	isize j = 0;

	if (print_quotes) {
		buf[j++] = '"';
	}

	for (isize i = 0; i < name.len; i++) {
		u8 c = name.text[i];
		if (llir_valid_char(c)) {
			buf[j++] = c;
		} else {
			buf[j] = '\\';
			buf[j+1] = hex_table[c >> 4];
			buf[j+2] = hex_table[c & 0x0f];
			j += 3;
		}
	}

	if (print_quotes) {
		buf[j++] = '"';
	}

	llir_file_write(f, buf, j);

	gb_temp_arena_memory_end(tmp);
}



void llir_print_encoded_local(llirFileBuffer *f, String name) {
	llir_fprintf(f, "%%");
	llir_print_escape_string(f, name, true);
}

void llir_print_encoded_global(llirFileBuffer *f, String name, bool remove_prefix) {
	llir_fprintf(f, "@");
	if (!remove_prefix) {
		llir_fprintf(f, ".");
	}
	llir_print_escape_string(f, name, true);
}


void llir_print_type(llirFileBuffer *f, llirModule *m, Type *t) {
	BaseTypeSizes s = m->sizes;
	i64 word_bits = 8*s.word_size;
	GB_ASSERT_NOT_NULL(t);
	t = default_type(t);

	switch (t->kind) {
	case Type_Basic:
		switch (t->Basic.kind) {
		case Basic_bool:   llir_fprintf(f, "i1");                      break;
		case Basic_i8:     llir_fprintf(f, "i8");                      break;
		case Basic_u8:     llir_fprintf(f, "i8");                      break;
		case Basic_i16:    llir_fprintf(f, "i16");                     break;
		case Basic_u16:    llir_fprintf(f, "i16");                     break;
		case Basic_i32:    llir_fprintf(f, "i32");                     break;
		case Basic_u32:    llir_fprintf(f, "i32");                     break;
		case Basic_i64:    llir_fprintf(f, "i64");                     break;
		case Basic_u64:    llir_fprintf(f, "i64");                     break;
		// case Basic_i128:   llir_fprintf(f, "i128");                    break;
		// case Basic_u128:   llir_fprintf(f, "i128");                    break;
		// case Basic_f16:    llir_fprintf(f, "half");                    break;
		case Basic_f32:    llir_fprintf(f, "float");                   break;
		case Basic_f64:    llir_fprintf(f, "double");                  break;
		// case Basic_f128:   llir_fprintf(f, "fp128");                   break;
		case Basic_rawptr: llir_fprintf(f, "%%..rawptr");              break;
		case Basic_string: llir_fprintf(f, "%%..string");              break;
		case Basic_uint:   llir_fprintf(f, "i%lld", word_bits);        break;
		case Basic_int:    llir_fprintf(f, "i%lld", word_bits);        break;
		case Basic_any:    llir_fprintf(f, "%%..any");                 break;
		}
		break;
	case Type_Pointer:
		llir_print_type(f, m, t->Pointer.elem);
		llir_fprintf(f, "*");
		break;
	case Type_Maybe:
		llir_fprintf(f, "{");
		llir_print_type(f, m, t->Maybe.elem);
		llir_fprintf(f, ", ");
		llir_print_type(f, m, t_bool);
		llir_fprintf(f, "}");
		break;
	case Type_Array:
		llir_fprintf(f, "[%lld x ", t->Array.count);
		llir_print_type(f, m, t->Array.elem);
		llir_fprintf(f, "]");
		break;
	case Type_Vector:
		llir_fprintf(f, "<%lld x ", t->Vector.count);
		llir_print_type(f, m, t->Vector.elem);
		llir_fprintf(f, ">");
		break;
	case Type_Slice:
		llir_fprintf(f, "{");
		llir_print_type(f, m, t->Slice.elem);
		llir_fprintf(f, "*, i%lld, i%lld}", word_bits, word_bits);
		break;
	case Type_Record: {
		switch (t->Record.kind) {
		case TypeRecord_Struct:
			if (t->Record.struct_is_packed) {
				llir_fprintf(f, "<");
			}
			llir_fprintf(f, "{");
			for (isize i = 0; i < t->Record.field_count; i++) {
				if (i > 0) {
					llir_fprintf(f, ", ");
				}
				llir_print_type(f, m, t->Record.fields[i]->type);
			}
			llir_fprintf(f, "}");
			if (t->Record.struct_is_packed) {
				llir_fprintf(f, ">");
			}
			break;
		case TypeRecord_Union: {
			// NOTE(bill): The zero size array is used to fix the alignment used in a structure as
			// LLVM takes the first element's alignment as the entire alignment (like C)
			i64 size_of_union  = type_size_of(s, heap_allocator(), t) - s.word_size;
			i64 align_of_union = type_align_of(s, heap_allocator(), t);
			llir_fprintf(f, "{[0 x <%lld x i8>], [%lld x i8], i%lld}", align_of_union, size_of_union, word_bits);
		} break;
		case TypeRecord_RawUnion: {
			// NOTE(bill): The zero size array is used to fix the alignment used in a structure as
			// LLVM takes the first element's alignment as the entire alignment (like C)
			i64 size_of_union  = type_size_of(s, heap_allocator(), t);
			i64 align_of_union = type_align_of(s, heap_allocator(), t);
			llir_fprintf(f, "{[0 x <%lld x i8>], [%lld x i8]}", align_of_union, size_of_union);
		} break;
		case TypeRecord_Enum:
			llir_print_type(f, m, base_enum_type(t));
			break;
		}
	} break;


	case Type_Named:
		if (is_type_struct(t) || is_type_union(t)) {
			String *name = map_string_get(&m->type_names, hash_pointer(t));
			GB_ASSERT_MSG(name != NULL, "%.*s", LIT(t->Named.name));
			llir_print_encoded_local(f, *name);
		} else {
			llir_print_type(f, m, base_type(t));
		}
		break;
	case Type_Tuple:
		if (t->Tuple.variable_count == 1) {
			llir_print_type(f, m, t->Tuple.variables[0]->type);
		} else {
			llir_fprintf(f, "{");
			for (isize i = 0; i < t->Tuple.variable_count; i++) {
				if (i > 0) {
					llir_fprintf(f, ", ");
				}
				llir_print_type(f, m, t->Tuple.variables[i]->type);
			}
			llir_fprintf(f, "}");
		}
		break;
	case Type_Proc: {
		if (t->Proc.result_count == 0) {
			llir_fprintf(f, "void");
		} else {
			llir_print_type(f, m, t->Proc.results);
		}
		llir_fprintf(f, " (");
		TypeTuple *params = &t->Proc.params->Tuple;
		for (isize i = 0; i < t->Proc.param_count; i++) {
			if (i > 0) {
				llir_fprintf(f, ", ");
			}
			llir_print_type(f, m, params->variables[i]->type);
		}
		llir_fprintf(f, ")*");
	} break;
	}
}

void llir_print_exact_value(llirFileBuffer *f, llirModule *m, ExactValue value, Type *type);

void llir_print_compound_element(llirFileBuffer *f, llirModule *m, ExactValue v, Type *elem_type) {
	llir_print_type(f, m, elem_type);
	llir_fprintf(f, " ");

	if (v.kind != ExactValue_Invalid && is_type_maybe(elem_type)) {
		Type *t = base_type(elem_type)->Maybe.elem;
		llir_fprintf(f, "{");
		llir_print_type(f, m, t);
		llir_fprintf(f, " ");
	}

	if (v.kind == ExactValue_Invalid || base_type(elem_type) == t_any) {
		llir_fprintf(f, "zeroinitializer");
	} else {
		llir_print_exact_value(f, m, v, elem_type);
	}

	if (v.kind != ExactValue_Invalid && is_type_maybe(elem_type)) {
		llir_fprintf(f, ", ");
		llir_print_type(f, m, t_bool);
		llir_fprintf(f, " ");
		llir_fprintf(f, "true}");
	}
}

void llir_print_exact_value(llirFileBuffer *f, llirModule *m, ExactValue value, Type *type) {
	type = base_type(base_enum_type(type));
	if (is_type_float(type)) {
		value = exact_value_to_float(value);
	} else if (is_type_integer(type)) {
		value = exact_value_to_integer(value);
	} else if (is_type_pointer(type)) {
		value = exact_value_to_integer(value);
	}

	switch (value.kind) {
	case ExactValue_Bool:
		llir_fprintf(f, "%s", (value.value_bool ? "true" : "false"));
		break;
	case ExactValue_String: {
		String str = value.value_string;
		if (str.len == 0) {
			llir_fprintf(f, "zeroinitializer");
			break;
		}
		if (!is_type_string(type)) {
			GB_ASSERT(is_type_array(type));
			llir_fprintf(f, "c\"");
			llir_print_escape_string(f, str, false);
			llir_fprintf(f, "\"");
		} else {
			// HACK NOTE(bill): This is a hack but it works because strings are created at the very end
			// of the .ll file
			llirValue *str_array = llir_add_global_string_array(m, str);

			llir_fprintf(f, "{i8* getelementptr inbounds (");
			llir_print_type(f, m, str_array->Global.entity->type);
			llir_fprintf(f, ", ");
			llir_print_type(f, m, str_array->Global.entity->type);
			llir_fprintf(f, "* ");
			llir_print_encoded_global(f, str_array->Global.entity->token.string, false);
			llir_fprintf(f, ", ");
			llir_print_type(f, m, t_int);
			llir_fprintf(f, " 0, i32 0), ");
			llir_print_type(f, m, t_int);
			llir_fprintf(f, " %lld}", cast(i64)str.len);
		}
	} break;
	case ExactValue_Integer: {
		if (is_type_pointer(type)) {
			if (value.value_integer == 0) {
				llir_fprintf(f, "null");
			} else {
				llir_fprintf(f, "inttoptr (");
				llir_print_type(f, m, t_int);
				llir_fprintf(f, " %llu to ", value.value_integer);
				llir_print_type(f, m, t_rawptr);
				llir_fprintf(f, ")");
			}
		} else {
			llir_fprintf(f, "%lld", value.value_integer);
		}
	} break;
	case ExactValue_Float: {
		GB_ASSERT(is_type_float(type));
		type = base_type(type);
		u64 u = *cast(u64*)&value.value_float;
		switch (type->Basic.kind) {
		case Basic_f32:
			// IMPORTANT NOTE(bill): LLVM requires all floating point constants to be
			// a 64 bit number if bits_of(float type) <= 64.
			// https://groups.google.com/forum/#!topic/llvm-dev/IlqV3TbSk6M
			// 64 bit mantillir: 52 bits
			// 32 bit mantillir: 23 bits
			// 29 == 52-23
			u >>= 29;
			u <<= 29;
			break;
		}

		switch (type->Basic.kind) {
		case 0: break;
#if 0
		case Basic_f16:
			llir_fprintf(f, "bitcast (");
			llir_print_type(f, m, t_u16);
			llir_fprintf(f, " %u to ", cast(u16)f32_to_f16(cast(f32)value.value_float));
			llir_print_type(f, m, t_f16);
			llir_fprintf(f, ")");
			break;
		case Basic_f128:
			llir_fprintf(f, "bitcast (");
			llir_fprintf(f, "i128");
			// TODO(bill): Actually support f128
			llir_fprintf(f, " %llu to ", u);
			llir_print_type(f, m, t_f128);
			llir_fprintf(f, ")");
			break;
#endif
		default:
			llir_fprintf(f, "0x%016llx", u);
			break;
		}
	} break;
	case ExactValue_Pointer:
		if (value.value_pointer == 0) {
			llir_fprintf(f, "null");
		} else {
			llir_fprintf(f, "inttoptr (");
			llir_print_type(f, m, t_int);
			llir_fprintf(f, " %llu to ", cast(u64)cast(uintptr)value.value_pointer);
			llir_print_type(f, m, t_rawptr);
			llir_fprintf(f, ")");
		}
		break;

	case ExactValue_Compound: {
		type = base_type(type);
		if (is_type_array(type)) {
			ast_node(cl, CompoundLit, value.value_compound);
			isize elem_count = cl->elems.count;
			if (elem_count == 0) {
				llir_fprintf(f, "zeroinitializer");
				break;
			}

			llir_fprintf(f, "[");
			Type *elem_type = type->Array.elem;

			for (isize i = 0; i < elem_count; i++) {
				if (i > 0) {
					llir_fprintf(f, ", ");
				}
				TypeAndValue *tav = type_and_value_of_expression(m->info, cl->elems.e[i]);
				GB_ASSERT(tav != NULL);
				llir_print_compound_element(f, m, tav->value, elem_type);
			}
			for (isize i = elem_count; i < type->Array.count; i++) {
				if (i >= elem_count) {
					llir_fprintf(f, ", ");
				}
				llir_print_type(f, m, elem_type);
				llir_fprintf(f, " zeroinitializer");
			}

			llir_fprintf(f, "]");
		} else if (is_type_vector(type)) {
			ast_node(cl, CompoundLit, value.value_compound);
			isize elem_count = cl->elems.count;
			if (elem_count == 0) {
				llir_fprintf(f, "zeroinitializer");
				break;
			}

			llir_fprintf(f, "<");
			Type *elem_type = type->Vector.elem;

			if (elem_count == 1 && type->Vector.count > 1) {
				TypeAndValue *tav = type_and_value_of_expression(m->info, cl->elems.e[0]);
				GB_ASSERT(tav != NULL);

				for (isize i = 0; i < type->Vector.count; i++) {
					if (i > 0) {
						llir_fprintf(f, ", ");
					}
					llir_print_compound_element(f, m, tav->value, elem_type);
				}
			} else {
				for (isize i = 0; i < elem_count; i++) {
					if (i > 0) {
						llir_fprintf(f, ", ");
					}
					TypeAndValue *tav = type_and_value_of_expression(m->info, cl->elems.e[i]);
					GB_ASSERT(tav != NULL);
					llir_print_compound_element(f, m, tav->value, elem_type);
				}
			}

			llir_fprintf(f, ">");
		} else if (is_type_struct(type)) {
			gbTempArenaMemory tmp = gb_temp_arena_memory_begin(&m->tmp_arena);

			ast_node(cl, CompoundLit, value.value_compound);

			if (cl->elems.count == 0) {
				llir_fprintf(f, "zeroinitializer");
				break;
			}


			isize value_count = type->Record.field_count;
			ExactValue *values = gb_alloc_array(m->tmp_allocator, ExactValue, value_count);


			if (cl->elems.e[0]->kind == AstNode_FieldValue) {
				isize elem_count = cl->elems.count;
				for (isize i = 0; i < elem_count; i++) {
					ast_node(fv, FieldValue, cl->elems.e[i]);
					String name = fv->field->Ident.string;

					TypeAndValue *tav = type_and_value_of_expression(m->info, fv->value);
					GB_ASSERT(tav != NULL);

					Selection sel = lookup_field(m->allocator, type, name, false);
					Entity *f = type->Record.fields[sel.index.e[0]];

					values[f->Variable.field_index] = tav->value;
				}
			} else {
				for (isize i = 0; i < value_count; i++) {
					TypeAndValue *tav = type_and_value_of_expression(m->info, cl->elems.e[i]);
					GB_ASSERT(tav != NULL);

					Entity *f = type->Record.fields_in_src_order[i];

					values[f->Variable.field_index] = tav->value;
				}
			}



			if (type->Record.struct_is_packed) {
				llir_fprintf(f, "<");
			}
			llir_fprintf(f, "{");


			for (isize i = 0; i < value_count; i++) {
				if (i > 0) {
					llir_fprintf(f, ", ");
				}
				Type *elem_type = type->Record.fields[i]->type;

				llir_print_compound_element(f, m, values[i], elem_type);
			}


			llir_fprintf(f, "}");
			if (type->Record.struct_is_packed) {
				llir_fprintf(f, ">");
			}

			gb_temp_arena_memory_end(tmp);
		} else {
			llir_fprintf(f, "zeroinitializer");
		}

	} break;

	default:
		llir_fprintf(f, "zeroinitializer");
		// GB_PANIC("Invalid ExactValue: %d", value.kind);
		break;
	}
}

void llir_print_block_name(llirFileBuffer *f, llirBlock *b) {
	if (b != NULL) {
		llir_print_escape_string(f, b->label, false);
		llir_fprintf(f, "-%td", b->index);
	} else {
		llir_fprintf(f, "<INVALID-BLOCK>");
	}
}

bool llir_print_is_proc_global(llirModule *m, llirProcedure *proc) {
	if (proc->entity != NULL &&
	    proc->entity->kind == Entity_Procedure) {
		if (m->entry_point_entity == proc->entity) {
			// TODO(bill): This may not be needed during windows
			return true;
		}
		if (proc->entity->Procedure.link_name.len > 0) {
		    return true;
		}
	}
	return (proc->tags & (ProcTag_foreign|ProcTag_export)) != 0;
}

void llir_print_value(llirFileBuffer *f, llirModule *m, llirValue *value, Type *type_hint) {
	if (value == NULL) {
		llir_fprintf(f, "!!!NULL_VALUE");
		return;
	}
	switch (value->kind) {
	default: GB_PANIC("Unknown llirValue kind"); break;

	case llirValue_Constant:
		llir_print_exact_value(f, m, value->Constant.value, type_hint);
		break;

	case llirValue_ConstantSlice: {
		llirValueConstantSlice *cs = &value->ConstantSlice;
		if (cs->backing_array == NULL || cs->count == 0) {
			llir_fprintf(f, "zeroinitializer");
		} else {
			Type *at = base_type(type_deref(llir_type(cs->backing_array)));
			Type *et = at->Array.elem;
			llir_fprintf(f, "{");
			llir_print_type(f, m, et);
			llir_fprintf(f, "* getelementptr inbounds (");
			llir_print_type(f, m, at);
			llir_fprintf(f, ", ");
			llir_print_type(f, m, at);
			llir_fprintf(f, "* ");
			llir_print_value(f, m, cs->backing_array, at);
			llir_fprintf(f, ", ");
			llir_print_type(f, m, t_int);
			llir_fprintf(f, " 0, i32 0), ");
			llir_print_type(f, m, t_int);
			llir_fprintf(f, " %lld, ", cs->count);
			llir_print_type(f, m, t_int);
			llir_fprintf(f, " %lld}", cs->count);
		}
	} break;

	case llirValue_Nil:
		llir_fprintf(f, "zeroinitializer");
		break;

	case llirValue_TypeName:
		llir_print_encoded_local(f, value->TypeName.name);
		break;
	case llirValue_Global: {
		Scope *scope = value->Global.entity->scope;
		bool in_global_scope = false;
		if (scope != NULL) {
			in_global_scope = scope->is_global || scope->is_init;
		}
		llir_print_encoded_global(f, value->Global.entity->token.string, in_global_scope);
	} break;
	case llirValue_Param:
		llir_print_encoded_local(f, value->Param.entity->token.string);
		break;
	case llirValue_Proc:
		llir_print_encoded_global(f, value->Proc.name, llir_print_is_proc_global(m, &value->Proc));
		break;
	case llirValue_Instr:
		llir_fprintf(f, "%%%d", value->index);
		break;
	}
}

void llir_print_calling_convention(llirFileBuffer *f, llirModule *m, ProcCallingConvention cc) {
	switch (cc) {
	case ProcCC_Odin: llir_fprintf(f, "");       break;
	case ProcCC_C:    llir_fprintf(f, "ccc ");   break;
	case ProcCC_Std:  llir_fprintf(f, "cc 64 "); break;
	case ProcCC_Fast: llir_fprintf(f, "cc 65 "); break;
	default: GB_PANIC("unknown calling convention: %d", cc);
	}
}

void llir_print_instr(llirFileBuffer *f, llirModule *m, llirValue *value) {
	GB_ASSERT(value->kind == llirValue_Instr);
	llirInstr *instr = &value->Instr;

	llir_fprintf(f, "\t");

	switch (instr->kind) {
	case llirInstr_StartupRuntime: {
		llir_fprintf(f, "call void ");
		llir_print_encoded_global(f, str_lit(LLIR_STARTUP_RUNTIME_PROC_NAME), false);
		llir_fprintf(f, "()\n");
	} break;

	case llirInstr_Comment:
		llir_fprintf(f, "; %.*s\n", LIT(instr->Comment.text));
		break;

	case llirInstr_Local: {
		Type *type = instr->Local.entity->type;
		llir_fprintf(f, "%%%d = alloca ", value->index);
		llir_print_type(f, m, type);
		llir_fprintf(f, ", align %lld\n", type_align_of(m->sizes, m->allocator, type));
	} break;

	case llirInstr_ZeroInit: {
		Type *type = type_deref(llir_type(instr->ZeroInit.address));
		llir_fprintf(f, "store ");
		llir_print_type(f, m, type);
		llir_fprintf(f, " zeroinitializer, ");
		llir_print_type(f, m, type);
		llir_fprintf(f, "* %%%d\n", instr->ZeroInit.address->index);
	} break;

	case llirInstr_Store: {
		Type *type = llir_type(instr->Store.value);
		llir_fprintf(f, "store ");
		llir_print_type(f, m, type);
		llir_fprintf(f, " ");
		llir_print_value(f, m, instr->Store.value, type);
		llir_fprintf(f, ", ");
		llir_print_type(f, m, type);
		llir_fprintf(f, "* ");
		llir_print_value(f, m, instr->Store.address, type);
		llir_fprintf(f, "\n");
	} break;

	case llirInstr_Load: {
		Type *type = instr->Load.type;
		llir_fprintf(f, "%%%d = load ", value->index);
		llir_print_type(f, m, type);
		llir_fprintf(f, ", ");
		llir_print_type(f, m, type);
		llir_fprintf(f, "* ");
		llir_print_value(f, m, instr->Load.address, type);
		llir_fprintf(f, ", align %lld\n", type_align_of(m->sizes, m->allocator, type));
	} break;

	case llirInstr_ArrayElementPtr: {
		Type *et = llir_type(instr->ArrayElementPtr.address);
		llir_fprintf(f, "%%%d = getelementptr inbounds ", value->index);

		llir_print_type(f, m, type_deref(et));
		llir_fprintf(f, ", ");
		llir_print_type(f, m, et);
		llir_fprintf(f, " ");
		llir_print_value(f, m, instr->ArrayElementPtr.address, et);
		llir_fprintf(f, ", ");
		llir_print_type(f, m, t_int);
		llir_fprintf(f, " 0, ");

		llirValue *index =instr->ArrayElementPtr.elem_index;
		Type *t = llir_type(index);
		llir_print_type(f, m, t);
		llir_fprintf(f, " ");
		llir_print_value(f, m, index, t);
		llir_fprintf(f, "\n");
	} break;

	case llirInstr_StructElementPtr: {
		Type *et = llir_type(instr->StructElementPtr.address);
		llir_fprintf(f, "%%%d = getelementptr inbounds ", value->index);

		llir_print_type(f, m, type_deref(et));
		llir_fprintf(f, ", ");
		llir_print_type(f, m, et);
		llir_fprintf(f, " ");
		llir_print_value(f, m, instr->StructElementPtr.address, et);
		llir_fprintf(f, ", ");
		llir_print_type(f, m, t_int);
		llir_fprintf(f, " 0, ");
		llir_print_type(f, m, t_i32);
		llir_fprintf(f, " %d", instr->StructElementPtr.elem_index);
		llir_fprintf(f, "\n");
	} break;

	case llirInstr_PtrOffset: {
		Type *pt = llir_type(instr->PtrOffset.address);
		llir_fprintf(f, "%%%d = getelementptr inbounds ", value->index);
		llir_print_type(f, m, type_deref(pt));
		llir_fprintf(f, ", ");
		llir_print_type(f, m, pt);
		llir_fprintf(f, " ");
		llir_print_value(f, m, instr->PtrOffset.address, pt);

		llirValue *offset = instr->PtrOffset.offset;
		Type *t = llir_type(offset);
		llir_fprintf(f, ", ");
		llir_print_type(f, m, t);
		llir_fprintf(f, " ");
		llir_print_value(f, m, offset, t);
		llir_fprintf(f, "\n");
	} break;

	case llirInstr_Phi: {
		llir_fprintf(f, "%%%d = phi ", value->index);
		llir_print_type(f, m, instr->Phi.type);
		llir_fprintf(f, " ", value->index);

		for (isize i = 0; i < instr->Phi.edges.count; i++) {
			if (i > 0) {
				llir_fprintf(f, ", ");
			}

			llirValue *edge = instr->Phi.edges.e[i];
			llirBlock *block = NULL;
			if (instr->parent != NULL &&
			    i < instr->parent->preds.count) {
				block = instr->parent->preds.e[i];
			}

			llir_fprintf(f, "[ ");
			llir_print_value(f, m, edge, instr->Phi.type);
			llir_fprintf(f, ", %%");
			llir_print_block_name(f, block);
			llir_fprintf(f, " ]");
		}
		llir_fprintf(f, "\n");
	} break;

	case llirInstr_ArrayExtractValue: {
		Type *et = llir_type(instr->ArrayExtractValue.address);
		llir_fprintf(f, "%%%d = extractvalue ", value->index);

		llir_print_type(f, m, et);
		llir_fprintf(f, " ");
		llir_print_value(f, m, instr->ArrayExtractValue.address, et);
		llir_fprintf(f, ", %d\n", instr->ArrayExtractValue.index);
	} break;

	case llirInstr_StructExtractValue: {
		Type *et = llir_type(instr->StructExtractValue.address);
		llir_fprintf(f, "%%%d = extractvalue ", value->index);

		llir_print_type(f, m, et);
		llir_fprintf(f, " ");
		llir_print_value(f, m, instr->StructExtractValue.address, et);
		llir_fprintf(f, ", %d\n", instr->StructExtractValue.index);
	} break;

	case llirInstr_UnionTagPtr: {
		Type *et = llir_type(instr->UnionTagPtr.address);
		llir_fprintf(f, "%%%d = getelementptr inbounds ", value->index);

		llir_print_type(f, m, type_deref(et));
		llir_fprintf(f, ", ");
		llir_print_type(f, m, et);
		llir_fprintf(f, " ");
		llir_print_value(f, m, instr->UnionTagPtr.address, et);
		llir_fprintf(f, ", ");
		llir_print_type(f, m, t_int);
		llir_fprintf(f, " 0, ");
		llir_print_type(f, m, t_i32);
		llir_fprintf(f, " %d", 2);
		llir_fprintf(f, "\n");
	} break;

	case llirInstr_UnionTagValue: {
		Type *et = llir_type(instr->UnionTagValue.address);
		llir_fprintf(f, "%%%d = extractvalue ", value->index);

		llir_print_type(f, m, et);
		llir_fprintf(f, " ");
		llir_print_value(f, m, instr->UnionTagValue.address, et);
		llir_fprintf(f, ", %d\n", 2);
	} break;

	case llirInstr_Jump: {;
		llir_fprintf(f, "br label %%");
		llir_print_block_name(f, instr->Jump.block);
		llir_fprintf(f, "\n");
	} break;

	case llirInstr_If: {;
		llir_fprintf(f, "br ");
		llir_print_type(f, m, t_bool);
		llir_fprintf(f, " ");
		llir_print_value(f, m, instr->If.cond, t_bool);
		llir_fprintf(f, ", ", instr->If.cond->index);
		llir_fprintf(f, "label %%");   llir_print_block_name(f, instr->If.true_block);
		llir_fprintf(f, ", label %%"); llir_print_block_name(f, instr->If.false_block);
		llir_fprintf(f, "\n");
	} break;

	case llirInstr_Return: {
		llirInstrReturn *ret = &instr->Return;
		llir_fprintf(f, "ret ");
		if (ret->value == NULL) {
			llir_fprintf(f, "void");
		} else {
			Type *t = llir_type(ret->value);
			llir_print_type(f, m, t);
			llir_fprintf(f, " ");
			llir_print_value(f, m, ret->value, t);
		}

		llir_fprintf(f, "\n");

	} break;

	case llirInstr_Conv: {
		llirInstrConv *c = &instr->Conv;
		llir_fprintf(f, "%%%d = %.*s ", value->index, LIT(llir_conv_strings[c->kind]));
		llir_print_type(f, m, c->from);
		llir_fprintf(f, " ");
		llir_print_value(f, m, c->value, c->from);
		llir_fprintf(f, " to ");
		llir_print_type(f, m, c->to);
		llir_fprintf(f, "\n");

	} break;

	case llirInstr_Unreachable: {
		llir_fprintf(f, "unreachable\n");
	} break;

	case llirInstr_UnaryOp: {
		llirInstrUnaryOp *uo = &value->Instr.UnaryOp;
		Type *type = base_type(llir_type(uo->expr));
		Type *elem_type = type;
		while (elem_type->kind == Type_Vector) {
			elem_type = base_type(elem_type->Vector.elem);
		}

		llir_fprintf(f, "%%%d = ", value->index);
		switch (uo->op) {
		case Token_Sub:
			if (is_type_float(elem_type)) {
				llir_fprintf(f, "fsub");
			} else {
				llir_fprintf(f, "sub");
			}
			break;
		case Token_Xor:
		case Token_Not:
			GB_ASSERT(is_type_integer(type) || is_type_boolean(type));
			llir_fprintf(f, "xor");
			break;
		default:
			GB_PANIC("Unknown unary operator");
			break;
		}

		llir_fprintf(f, " ");
		llir_print_type(f, m, type);
		llir_fprintf(f, " ");
		switch (uo->op) {
		case Token_Sub:
			if (is_type_float(elem_type)) {
				llir_print_exact_value(f, m, make_exact_value_float(0), type);
			} else {
				llir_fprintf(f, "0");
			}
			break;
		case Token_Xor:
		case Token_Not:
			GB_ASSERT(is_type_integer(type) || is_type_boolean(type));
			llir_fprintf(f, "-1");
			break;
		}
		llir_fprintf(f, ", ");
		llir_print_value(f, m, uo->expr, type);
		llir_fprintf(f, "\n");
	} break;

	case llirInstr_BinaryOp: {
		llirInstrBinaryOp *bo = &value->Instr.BinaryOp;
		Type *type = base_type(llir_type(bo->left));
		Type *elem_type = type;
		while (elem_type->kind == Type_Vector) {
			elem_type = base_type(elem_type->Vector.elem);
		}

		llir_fprintf(f, "%%%d = ", value->index);

		if (gb_is_between(bo->op, Token__ComparisonBegin+1, Token__ComparisonEnd-1)) {
			if (is_type_string(elem_type)) {
				llir_fprintf(f, "call ");
				llir_print_calling_convention(f, m, ProcCC_Odin);
				llir_print_type(f, m, t_bool);
				char *runtime_proc = "";
				switch (bo->op) {
				case Token_CmpEq: runtime_proc = "__string_eq"; break;
				case Token_NotEq: runtime_proc = "__string_ne"; break;
				case Token_Lt:    runtime_proc = "__string_lt"; break;
				case Token_Gt:    runtime_proc = "__string_gt"; break;
				case Token_LtEq:  runtime_proc = "__string_le"; break;
				case Token_GtEq:  runtime_proc = "__string_gt"; break;
				}

				llir_fprintf(f, " ");
				llir_print_encoded_global(f, make_string_c(runtime_proc), false);
				llir_fprintf(f, "(");
				llir_print_type(f, m, type);
				llir_fprintf(f, " ");
				llir_print_value(f, m, bo->left, type);
				llir_fprintf(f, ", ");
				llir_print_type(f, m, type);
				llir_fprintf(f, " ");
				llir_print_value(f, m, bo->right, type);
				llir_fprintf(f, ")\n");
				return;

			} else if (is_type_float(elem_type)) {
				llir_fprintf(f, "fcmp ");
				switch (bo->op) {
				case Token_CmpEq: llir_fprintf(f, "oeq"); break;
				case Token_NotEq: llir_fprintf(f, "one"); break;
				case Token_Lt:    llir_fprintf(f, "olt"); break;
				case Token_Gt:    llir_fprintf(f, "ogt"); break;
				case Token_LtEq:  llir_fprintf(f, "ole"); break;
				case Token_GtEq:  llir_fprintf(f, "oge"); break;
				}
			} else {
				llir_fprintf(f, "icmp ");
				if (bo->op != Token_CmpEq &&
				    bo->op != Token_NotEq) {
					if (is_type_unsigned(elem_type)) {
						llir_fprintf(f, "u");
					} else {
						llir_fprintf(f, "s");
					}
				}
				switch (bo->op) {
				case Token_CmpEq: llir_fprintf(f, "eq"); break;
				case Token_NotEq: llir_fprintf(f, "ne"); break;
				case Token_Lt:    llir_fprintf(f, "lt"); break;
				case Token_Gt:    llir_fprintf(f, "gt"); break;
				case Token_LtEq:  llir_fprintf(f, "le"); break;
				case Token_GtEq:  llir_fprintf(f, "ge"); break;
				default: GB_PANIC("invalid comparison");break;
				}
			}
		} else {
			if (is_type_float(elem_type)) {
				llir_fprintf(f, "f");
			}

			switch (bo->op) {
			case Token_Add:    llir_fprintf(f, "add");  break;
			case Token_Sub:    llir_fprintf(f, "sub");  break;
			case Token_And:    llir_fprintf(f, "and");  break;
			case Token_Or:     llir_fprintf(f, "or");   break;
			case Token_Xor:    llir_fprintf(f, "xor");  break;
			case Token_Shl:    llir_fprintf(f, "shl");  break;
			case Token_Shr:    llir_fprintf(f, "lshr"); break;
			case Token_Mul:    llir_fprintf(f, "mul");  break;
			case Token_Not:    llir_fprintf(f, "xor");  break;

			case Token_AndNot: GB_PANIC("Token_AndNot Should never be called");

			default: {
				if (!is_type_float(elem_type)) {
					if (is_type_unsigned(elem_type)) {
						llir_fprintf(f, "u");
					} else {
						llir_fprintf(f, "s");
					}
				}

				switch (bo->op) {
				case Token_Quo: llir_fprintf(f, "div"); break;
				case Token_Mod: llir_fprintf(f, "rem"); break;
				}
			} break;
			}
		}

		llir_fprintf(f, " ");
		llir_print_type(f, m, type);
		llir_fprintf(f, " ");
		llir_print_value(f, m, bo->left, type);
		llir_fprintf(f, ", ");
		llir_print_value(f, m, bo->right, type);
		llir_fprintf(f, "\n");
	} break;

	case llirInstr_Call: {
		llirInstrCall *call = &instr->Call;
		Type *proc_type = base_type(llir_type(call->value));
		GB_ASSERT(is_type_proc(proc_type));
		Type *result_type = call->type;
		if (result_type) {
			llir_fprintf(f, "%%%d = ", value->index);
		}
		llir_fprintf(f, "call ");
		llir_print_calling_convention(f, m, proc_type->Proc.calling_convention);
		if (result_type) {
			llir_print_type(f, m, result_type);
		} else {
			llir_fprintf(f, "void");
		}
		llir_fprintf(f, " ");
		llir_print_value(f, m, call->value, call->type);


		llir_fprintf(f, "(");
		if (call->arg_count > 0) {
			Type *proc_type = base_type(llir_type(call->value));
			GB_ASSERT(proc_type->kind == Type_Proc);
			TypeTuple *params = &proc_type->Proc.params->Tuple;
			for (isize i = 0; i < call->arg_count; i++) {
				Entity *e = params->variables[i];
				GB_ASSERT(e != NULL);
				Type *t = e->type;
				if (i > 0) {
					llir_fprintf(f, ", ");
				}
				llir_print_type(f, m, t);
				llir_fprintf(f, " ");
				llirValue *arg = call->args[i];
				llir_print_value(f, m, arg, t);
			}
		}
		llir_fprintf(f, ")\n");

	} break;

	case llirInstr_Select: {
		llir_fprintf(f, "%%%d = select i1 ", value->index);
		llir_print_value(f, m, instr->Select.cond, t_bool);
		llir_fprintf(f, ", ");
		llir_print_type(f, m, llir_type(instr->Select.true_value));
		llir_fprintf(f, " ");
		llir_print_value(f, m, instr->Select.true_value, llir_type(instr->Select.true_value));
		llir_fprintf(f, ", ");
		llir_print_type(f, m, llir_type(instr->Select.false_value));
		llir_fprintf(f, " ");
		llir_print_value(f, m, instr->Select.false_value, llir_type(instr->Select.false_value));
		llir_fprintf(f, "\n");
	} break;

	case llirInstr_VectorExtractElement: {
		Type *vt = llir_type(instr->VectorExtractElement.vector);
		Type *it = llir_type(instr->VectorExtractElement.index);
		llir_fprintf(f, "%%%d = extractelement ", value->index);

		llir_print_type(f, m, vt);
		llir_fprintf(f, " ");
		llir_print_value(f, m, instr->VectorExtractElement.vector, vt);
		llir_fprintf(f, ", ");
		llir_print_type(f, m, it);
		llir_fprintf(f, " ");
		llir_print_value(f, m, instr->VectorExtractElement.index, it);
		llir_fprintf(f, "\n");
	} break;

	case llirInstr_VectorInsertElement: {
		llirInstrVectorInsertElement *ie = &instr->VectorInsertElement;
		Type *vt = llir_type(ie->vector);
		llir_fprintf(f, "%%%d = insertelement ", value->index);

		llir_print_type(f, m, vt);
		llir_fprintf(f, " ");
		llir_print_value(f, m, ie->vector, vt);
		llir_fprintf(f, ", ");

		llir_print_type(f, m, llir_type(ie->elem));
		llir_fprintf(f, " ");
		llir_print_value(f, m, ie->elem, llir_type(ie->elem));
		llir_fprintf(f, ", ");

		llir_print_type(f, m, llir_type(ie->index));
		llir_fprintf(f, " ");
		llir_print_value(f, m, ie->index, llir_type(ie->index));

		llir_fprintf(f, "\n");
	} break;

	case llirInstr_VectorShuffle: {
		llirInstrVectorShuffle *sv = &instr->VectorShuffle;
		Type *vt = llir_type(sv->vector);
		llir_fprintf(f, "%%%d = shufflevector ", value->index);

		llir_print_type(f, m, vt);
		llir_fprintf(f, " ");
		llir_print_value(f, m, sv->vector, vt);
		llir_fprintf(f, ", ");

		llir_print_type(f, m, vt);
		llir_fprintf(f, " ");
		llir_print_value(f, m, sv->vector, vt);
		llir_fprintf(f, ", ");

		llir_fprintf(f, "<%td x i32> <", sv->index_count);
		for (isize i = 0; i < sv->index_count; i++) {
			if (i > 0) {
				llir_fprintf(f, ", ");
			}
			llir_fprintf(f, "i32 %d", sv->indices[i]);
		}
		llir_fprintf(f, ">");
		llir_fprintf(f, "\n");
	} break;

	case llirInstr_BoundsCheck: {
		llirInstrBoundsCheck *bc = &instr->BoundsCheck;
		llir_fprintf(f, "call void ");
		llir_print_encoded_global(f, str_lit("__bounds_check_error"), false);
		llir_fprintf(f, "(");
		llir_print_compound_element(f, m, make_exact_value_string(bc->pos.file), t_string);
		llir_fprintf(f, ", ");

		llir_print_type(f, m, t_int);
		llir_fprintf(f, " ");
		llir_print_exact_value(f, m, make_exact_value_integer(bc->pos.line), t_int);
		llir_fprintf(f, ", ");

		llir_print_type(f, m, t_int);
		llir_fprintf(f, " ");
		llir_print_exact_value(f, m, make_exact_value_integer(bc->pos.column), t_int);
		llir_fprintf(f, ", ");

		llir_print_type(f, m, t_int);
		llir_fprintf(f, " ");
		llir_print_value(f, m, bc->index, t_int);
		llir_fprintf(f, ", ");

		llir_print_type(f, m, t_int);
		llir_fprintf(f, " ");
		llir_print_value(f, m, bc->len, t_int);

		llir_fprintf(f, ")\n");
	} break;

	case llirInstr_SliceBoundsCheck: {
		llirInstrSliceBoundsCheck *bc = &instr->SliceBoundsCheck;
		llir_fprintf(f, "call void ");
		if (bc->is_substring) {
			llir_print_encoded_global(f, str_lit("__substring_expr_error"), false);
		} else {
			llir_print_encoded_global(f, str_lit("__slice_expr_error"), false);
		}

		llir_fprintf(f, "(");
		llir_print_compound_element(f, m, make_exact_value_string(bc->pos.file), t_string);
		llir_fprintf(f, ", ");

		llir_print_type(f, m, t_int);
		llir_fprintf(f, " ");
		llir_print_exact_value(f, m, make_exact_value_integer(bc->pos.line), t_int);
		llir_fprintf(f, ", ");

		llir_print_type(f, m, t_int);
		llir_fprintf(f, " ");
		llir_print_exact_value(f, m, make_exact_value_integer(bc->pos.column), t_int);
		llir_fprintf(f, ", ");

		llir_print_type(f, m, t_int);
		llir_fprintf(f, " ");
		llir_print_value(f, m, bc->low, t_int);
		llir_fprintf(f, ", ");

		llir_print_type(f, m, t_int);
		llir_fprintf(f, " ");
		llir_print_value(f, m, bc->high, t_int);

		llir_fprintf(f, ")\n");
	} break;


	default: {
		GB_PANIC("<unknown instr> %d\n", instr->kind);
		llir_fprintf(f, "; <unknown instr> %d\n", instr->kind);
	} break;
	}
}


void llir_print_proc(llirFileBuffer *f, llirModule *m, llirProcedure *proc) {
	if (proc->body == NULL) {
		llir_fprintf(f, "declare ");
		if (proc->tags & ProcTag_dll_import) {
			llir_fprintf(f, "dllimport ");
		}
	} else {
		llir_fprintf(f, "\n");
		llir_fprintf(f, "define ");
		if (m->build_context->is_dll) {
			// if (proc->tags & (ProcTag_export|ProcTag_dll_export)) {
			if (proc->tags & (ProcTag_export)) {
				llir_fprintf(f, "dllexport ");
			}
		}
	}

	TypeProc *proc_type = &proc->type->Proc;

	llir_print_calling_convention(f, m, proc_type->calling_convention);

	if (proc_type->result_count == 0) {
		llir_fprintf(f, "void");
	} else {
		llir_print_type(f, m, proc_type->results);
	}

	llir_fprintf(f, " ");
	llir_print_encoded_global(f, proc->name, llir_print_is_proc_global(m, proc));
	llir_fprintf(f, "(");

	if (proc_type->param_count > 0) {
		TypeTuple *params = &proc_type->params->Tuple;
		for (isize i = 0; i < params->variable_count; i++) {
			Entity *e = params->variables[i];
			if (i > 0) {
				llir_fprintf(f, ", ");
			}
			llir_print_type(f, m, e->type);
			if (proc->body != NULL) {
				if (!str_eq(e->token.string, str_lit("")) &&
				    !str_eq(e->token.string, str_lit("_"))) {
					llir_fprintf(f, " %%%.*s", LIT(e->token.string));
				} else {
					llir_fprintf(f, " %%_.param_%td", i);
				}
			}
		}
	}

	llir_fprintf(f, ") ");

	if (proc->tags & ProcTag_inline) {
		llir_fprintf(f, "alwaysinline ");
	}
	if (proc->tags & ProcTag_no_inline) {
		llir_fprintf(f, "noinline ");
	}


	if (proc->module->generate_debug_info && proc->entity != NULL) {
		if (proc->body != NULL) {
			llirDebugInfo *di = *map_llir_debug_info_get(&proc->module->debug_info, hash_pointer(proc->entity));
			GB_ASSERT(di->kind == llirDebugInfo_Proc);
			llir_fprintf(f, "!dbg !%d ", di->id);
		}
	}


	if (proc->body != NULL) {
		// llir_fprintf(f, "nounwind uwtable {\n");

		llir_fprintf(f, "{\n");
		for_array(i, proc->blocks) {
			llirBlock *block = proc->blocks.e[i];

			if (i > 0) llir_fprintf(f, "\n");
			llir_print_block_name(f, block);
			llir_fprintf(f, ":\n");

			for_array(j, block->instrs) {
				llirValue *value = block->instrs.e[j];
				llir_print_instr(f, m, value);
			}
		}
		llir_fprintf(f, "}\n");
	} else {
		llir_fprintf(f, "\n");
	}

	for_array(i, proc->children) {
		llir_print_proc(f, m, proc->children.e[i]);
	}
}

void llir_print_type_name(llirFileBuffer *f, llirModule *m, llirValue *v) {
	GB_ASSERT(v->kind == llirValue_TypeName);
	Type *bt = base_type(llir_type(v));
	if (!is_type_struct(bt) && !is_type_union(bt)) {
		return;
	}
	llir_print_encoded_local(f, v->TypeName.name);
	llir_fprintf(f, " = type ");
	llir_print_type(f, m, base_type(v->TypeName.type));
	llir_fprintf(f, "\n");
}

void print_llvm_ir(llirGen *llir) {
	llirModule *m = &llir->module;
	llirFileBuffer buf = {0}, *f = &buf;
	llir_file_buffer_init(f, &llir->output_file);

	if (m->layout.len > 0) {
		llir_fprintf(f, "target datalayout = \"%.*s\"\n", LIT(m->layout));
	}

	llir_print_encoded_local(f, str_lit("..string"));
	llir_fprintf(f, " = type {i8*, ");
	llir_print_type(f, m, t_int);
	llir_fprintf(f, "} ; Basic_string\n");
	llir_print_encoded_local(f, str_lit("..rawptr"));
	llir_fprintf(f, " = type i8* ; Basic_rawptr\n");

	llir_print_encoded_local(f, str_lit("..any"));
	llir_fprintf(f, " = type {");
	llir_print_type(f, m, t_type_info_ptr);
	llir_fprintf(f, ", ");
	llir_print_type(f, m, t_rawptr);
	llir_fprintf(f, "} ; Basic_any\n");


	for_array(member_index, m->members.entries) {
		MapSsaValueEntry *entry = &m->members.entries.e[member_index];
		llirValue *v = entry->value;
		if (v->kind != llirValue_TypeName) {
			continue;
		}
		llir_print_type_name(f, m, v);
	}

	llir_fprintf(f, "\n");

	bool dll_main_found = false;

	for_array(member_index, m->members.entries) {
		MapSsaValueEntry *entry = &m->members.entries.e[member_index];
		llirValue *v = entry->value;
		if (v->kind != llirValue_Proc) {
			continue;
		}

		if (v->Proc.body == NULL) {
			llir_print_proc(f, m, &v->Proc);
		}
	}

	for_array(member_index, m->members.entries) {
		MapSsaValueEntry *entry = &m->members.entries.e[member_index];
		llirValue *v = entry->value;
		if (v->kind != llirValue_Proc) {
			continue;
		}

		if (v->Proc.body != NULL) {
			llir_print_proc(f, m, &v->Proc);
		}
	}

	for_array(member_index, m->members.entries) {
		MapSsaValueEntry *entry = &m->members.entries.e[member_index];
		llirValue *v = entry->value;
		if (v->kind != llirValue_Global) {
			continue;
		}
		llirValueGlobal *g = &v->Global;
		Scope *scope = g->entity->scope;
		bool in_global_scope = false;
		if (scope != NULL) {
			in_global_scope = scope->is_global || scope->is_init;
		}
		llir_print_encoded_global(f, g->entity->token.string, in_global_scope);
		llir_fprintf(f, " = ");
		if (g->is_thread_local) {
			llir_fprintf(f, "thread_local ");
		}

		if (g->is_private) {
			llir_fprintf(f, "private ");
		}
		if (g->is_constant) {
			if (g->is_unnamed_addr) {
				llir_fprintf(f, "unnamed_addr ");
			}
			llir_fprintf(f, "constant ");
		} else {
			llir_fprintf(f, "global ");
		}


		llir_print_type(f, m, g->entity->type);
		llir_fprintf(f, " ");
		if (g->value != NULL) {
			llir_print_value(f, m, g->value, g->entity->type);
		} else {
			llir_fprintf(f, "zeroinitializer");
		}
		llir_fprintf(f, "\n");
	}


#if 0
	if (m->generate_debug_info) {
		llir_fprintf(f, "\n");
		llir_fprintf(f, "!llvm.dbg.cu = !{!0}\n");

		for_array(di_index, m->debug_info.entries) {
			MapSsaDebugInfoEntry *entry = &m->debug_info.entries.e[di_index];
			llirDebugInfo *di = entry->value;
			llir_fprintf(f, "!%d = ", di->id);

			switch (di->kind) {
			case llirDebugInfo_CompileUnit: {
				auto *cu = &di->CompileUnit;
				llirDebugInfo *file = *map_llir_debug_info_get(&m->debug_info, hash_pointer(cu->file));
				llir_fprintf(f,
				            "distinct !DICompileUnit("
				            "language: DW_LANG_Go, " // Is this good enough?
				            "file: !%d, "
				            "producer: \"%.*s\", "
				            "flags: \"\", "
				            "runtimeVersion: 0, "
				            "isOptimized: false, "
				            "emissionKind: FullDebug"
				            ")",
				            file->id, LIT(cu->producer));

			} break;
			case llirDebugInfo_File:
				llir_fprintf(f, "!DIFile(filename: \"");
				llir_print_escape_string(f, di->File.filename, false);
				llir_fprintf(f, "\", directory: \"");
				llir_print_escape_string(f, di->File.directory, false);
				llir_fprintf(f, "\")");
				break;
			case llirDebugInfo_Proc:
				llir_fprintf(f, "distinct !DISubprogram("
				            "name: \"%.*s\", "
				            // "linkageName: \"\", "
				            "file: !%d, "
				            "line: %td, "
				            "isDefinition: true, "
				            "isLocal: false, "
				            "unit: !0"
				            ")",
				            LIT(di->Proc.name),
				            di->Proc.file->id,
				            di->Proc.pos.line);
				break;

			case llirDebugInfo_AllProcs:
				llir_fprintf(f, "!{");
				for_array(proc_index, di->AllProcs.procs) {
					llirDebugInfo *p = di->AllProcs.procs.e[proc_index];
					if (proc_index > 0) {llir_fprintf(f, ",");}
					llir_fprintf(f, "!%d", p->id);
				}
				llir_fprintf(f, "}");
				break;
			}

			llir_fprintf(f, "\n");
		}
	}
#endif
	llir_file_buffer_destroy(f);
}
