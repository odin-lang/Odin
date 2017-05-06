typedef struct irFileBuffer {
	gbVirtualMemory vm;
	isize           offset;
	gbFile *        output;
} irFileBuffer;

void ir_file_buffer_init(irFileBuffer *f, gbFile *output) {
	isize size = 8*gb_virtual_memory_page_size(NULL);
	f->vm = gb_vm_alloc(NULL, size);
	f->offset = 0;
	f->output = output;
}

void ir_file_buffer_destroy(irFileBuffer *f) {
	if (f->offset > 0) {
		// NOTE(bill): finish writing buffered data
		gb_file_write(f->output, f->vm.data, f->offset);
	}

	gb_vm_free(f->vm);
}

void ir_file_buffer_write(irFileBuffer *f, void *data, isize len) {
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


void ir_fprintf(irFileBuffer *f, char *fmt, ...) {
	va_list va;
	va_start(va, fmt);
	char buf[4096] = {0};
	isize len = gb_snprintf_va(buf, gb_size_of(buf), fmt, va);
	ir_file_buffer_write(f, buf, len-1);
	va_end(va);
}


void ir_file_write(irFileBuffer *f, void *data, isize len) {
	ir_file_buffer_write(f, data, len);
}


bool ir_valid_char(u8 c) {
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

void ir_print_escape_string(irFileBuffer *f, String name, bool print_quotes, bool prefix_with_dot) {
	isize extra = 0;
	for (isize i = 0; i < name.len; i++) {
		u8 c = name.text[i];
		if (!ir_valid_char(c)) {
			extra += 2;
		}
	}

	if (extra == 0) {
		ir_fprintf(f, "%.*s", LIT(name));
		return;
	}


	char hex_table[] = "0123456789ABCDEF";
	isize buf_len = name.len + extra + 2 + 1;

	gbTempArenaMemory tmp = gb_temp_arena_memory_begin(&string_buffer_arena);

	u8 *buf = gb_alloc_array(string_buffer_allocator, u8, buf_len);

	isize j = 0;

	if (print_quotes) {
		buf[j++] = '"';
	}

	if (prefix_with_dot) {
		buf[j++] = '.';
	}

	for (isize i = 0; i < name.len; i++) {
		u8 c = name.text[i];
		if (ir_valid_char(c)) {
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

	ir_file_write(f, buf, j);

	gb_temp_arena_memory_end(tmp);
}



void ir_print_encoded_local(irFileBuffer *f, String name) {
	ir_fprintf(f, "%%");
	ir_print_escape_string(f, name, true, false);
}

void ir_print_encoded_global(irFileBuffer *f, String name, bool remove_prefix) {
	ir_fprintf(f, "@");
	ir_print_escape_string(f, name, true, !remove_prefix);
}

void ir_print_type(irFileBuffer *f, irModule *m, Type *t);

void ir_print_proc_results(irFileBuffer *f, irModule *m, Type *t) {
	GB_ASSERT(is_type_proc(t));
	t = base_type(t);
	isize result_count = t->Proc.result_count;
	if (result_count == 0) {
		ir_fprintf(f, "void");
	} else if (result_count == 1) {
		ir_print_type(f, m, t->Proc.abi_compat_results[0]);
	} else {
		ir_fprintf(f, "{");
		for (isize i = 0; i < result_count; i++) {
			if (i > 0) {
				ir_fprintf(f, ", ");
			}
			ir_print_type(f, m, t->Proc.abi_compat_results[i]);
		}
		ir_fprintf(f, "}");
	}
}


void ir_print_type(irFileBuffer *f, irModule *m, Type *t) {
	i64 word_bits = 8*build_context.word_size;
	GB_ASSERT_NOT_NULL(t);
	t = default_type(t);
	GB_ASSERT(is_type_typed(t));

	switch (t->kind) {
	case Type_Basic:
		switch (t->Basic.kind) {
		case Basic_bool:   ir_fprintf(f, "i1");                       return;
		case Basic_i8:     ir_fprintf(f, "i8");                       return;
		case Basic_u8:     ir_fprintf(f, "i8");                       return;
		case Basic_i16:    ir_fprintf(f, "i16");                      return;
		case Basic_u16:    ir_fprintf(f, "i16");                      return;
		case Basic_i32:    ir_fprintf(f, "i32");                      return;
		case Basic_u32:    ir_fprintf(f, "i32");                      return;
		case Basic_i64:    ir_fprintf(f, "i64");                      return;
		case Basic_u64:    ir_fprintf(f, "i64");                      return;

		case Basic_f32:    ir_fprintf(f, "float");                    return;
		case Basic_f64:    ir_fprintf(f, "double");                   return;

		case Basic_complex64:  ir_fprintf(f, "%%..complex64");        return;
		case Basic_complex128: ir_fprintf(f, "%%..complex128");       return;

		case Basic_quaternion128: ir_fprintf(f, "%%..quaternion128"); return;
		case Basic_quaternion256: ir_fprintf(f, "%%..quaternion256"); return;

		case Basic_rawptr: ir_fprintf(f, "%%..rawptr");               return;
		case Basic_string: ir_fprintf(f, "%%..string");               return;
		case Basic_uint:   ir_fprintf(f, "i%lld", word_bits);         return;
		case Basic_int:    ir_fprintf(f, "i%lld", word_bits);         return;
		case Basic_any:    ir_fprintf(f, "%%..any");                  return;
		}
		break;
	case Type_Pointer:
		ir_print_type(f, m, t->Pointer.elem);
		ir_fprintf(f, "*");
		return;
	case Type_Atomic:
		ir_print_type(f, m, t->Atomic.elem);
		return;
	case Type_Array:
		ir_fprintf(f, "[%lld x ", t->Array.count);
		ir_print_type(f, m, t->Array.elem);
		ir_fprintf(f, "]");
		return;
	case Type_Vector: {
		i64 align = type_align_of(heap_allocator(), t);
		i64 count = t->Vector.count;
		ir_fprintf(f, "{[0 x <%lld x i8>], [%lld x ", align, count);
		ir_print_type(f, m, t->Vector.elem);
		ir_fprintf(f, "]}");
		return;
	}
/* 		ir_fprintf(f, "<%lld x ", t->Vector.count);
		ir_print_type(f, m, t->Vector.elem);
		ir_fprintf(f, ">");
		return; */
	case Type_Slice:
		ir_fprintf(f, "{");
		ir_print_type(f, m, t->Slice.elem);
		ir_fprintf(f, "*, i%lld, i%lld}", word_bits, word_bits);
		return;
	case Type_DynamicArray:
		ir_fprintf(f, "{");
		ir_print_type(f, m, t->DynamicArray.elem);
		ir_fprintf(f, "*, i%lld, i%lld,", word_bits, word_bits);
		ir_print_type(f, m, t_allocator);
		ir_fprintf(f, "}");
		return;
	case Type_Record: {
		switch (t->Record.kind) {
		case TypeRecord_Struct:
			if (t->Record.is_packed) {
				ir_fprintf(f, "<");
			}
			ir_fprintf(f, "{");
			if (t->Record.custom_align > 0) {
				ir_fprintf(f, "[0 x <%lld x i8>]", t->Record.custom_align);
				if (t->Record.field_count > 0) {
					ir_fprintf(f, ", ");
				}
			}
			for (isize i = 0; i < t->Record.field_count; i++) {
				if (i > 0) {
					ir_fprintf(f, ", ");
				}
				ir_print_type(f, m, t->Record.fields[i]->type);
			}
			ir_fprintf(f, "}");
			if (t->Record.is_packed) {
				ir_fprintf(f, ">");
			}
			return;
		case TypeRecord_Union: {
			// NOTE(bill): The zero size array is used to fix the alignment used in a structure as
			// LLVM takes the first element's alignment as the entire alignment (like C)
			i64 align = type_align_of(heap_allocator(), t);
			i64 total_size = type_size_of(heap_allocator(), t);
		#if 1
			i64 block_size =  t->Record.variant_block_size;

			ir_fprintf(f, "{[0 x <%lld x i8>], ", align);
			for (isize i = 0; i < t->Record.field_count; i++) {
				ir_print_type(f, m, t->Record.fields[i]->type);
				ir_fprintf(f, ", ");
			}
			ir_fprintf(f, "[%lld x i8], ", block_size);
			ir_fprintf(f, "i%lld}", word_bits);
		#else
			i64 block_size = total_size - build_context.word_size;
			ir_fprintf(f, "{[0 x <%lld x i8>], [%lld x i8], i%lld}", align, block_size, word_bits);
		#endif
		} return;
		case TypeRecord_RawUnion: {
			// NOTE(bill): The zero size array is used to fix the alignment used in a structure as
			// LLVM takes the first element's alignment as the entire alignment (like C)
			i64 size_of_union  = type_size_of(heap_allocator(), t);
			i64 align_of_union = type_align_of(heap_allocator(), t);
			ir_fprintf(f, "{[0 x <%lld x i8>], [%lld x i8]}", align_of_union, size_of_union);
		} return;
		case TypeRecord_Enum:
			ir_print_type(f, m, base_enum_type(t));
			return;
		}
	} break;


	case Type_Named:
		if (is_type_struct(t) || is_type_union(t)) {
			String *name = map_string_get(&m->entity_names, hash_pointer(t->Named.type_name));
			GB_ASSERT_MSG(name != NULL, "%.*s", LIT(t->Named.name));
			ir_print_encoded_local(f, *name);
		} else {
			ir_print_type(f, m, base_type(t));
		}
		return;
	case Type_Tuple:
		if (t->Tuple.variable_count == 1) {
			ir_print_type(f, m, t->Tuple.variables[0]->type);
		} else {
			ir_fprintf(f, "{");
			for (isize i = 0; i < t->Tuple.variable_count; i++) {
				if (i > 0) {
					ir_fprintf(f, ", ");
				}
				ir_print_type(f, m, t->Tuple.variables[i]->type);
			}
			ir_fprintf(f, "}");
		}
		return;
	case Type_Proc: {
		isize param_count = t->Proc.param_count;
		isize result_count = t->Proc.result_count;
		ir_print_proc_results(f, m, t);
		ir_fprintf(f, " (");
		for (isize i = 0; i < param_count; i++) {
			if (i > 0) {
				ir_fprintf(f, ", ");
			}
			ir_print_type(f, m, t->Proc.abi_compat_params[i]);
		}
		ir_fprintf(f, ")*");
	} return;

	case Type_Map: {
		GB_ASSERT(t->Map.generated_struct_type != NULL);
		ir_print_type(f, m, t->Map.generated_struct_type);
	} break;
	}
}

void ir_print_exact_value(irFileBuffer *f, irModule *m, ExactValue value, Type *type);

void ir_print_compound_element(irFileBuffer *f, irModule *m, ExactValue v, Type *elem_type) {
	ir_print_type(f, m, elem_type);
	ir_fprintf(f, " ");

	if (v.kind == ExactValue_Invalid || base_type(elem_type) == t_any) {
		ir_fprintf(f, "zeroinitializer");
	} else {
		ir_print_exact_value(f, m, v, elem_type);
	}
}

void ir_print_exact_value(irFileBuffer *f, irModule *m, ExactValue value, Type *type) {
	type = core_type(type);
	value = convert_exact_value_for_type(value, type);

	switch (value.kind) {
	case ExactValue_Bool:
		ir_fprintf(f, "%s", (value.value_bool ? "true" : "false"));
		break;
	case ExactValue_String: {
		String str = value.value_string;
		if (str.len == 0) {
			ir_fprintf(f, "zeroinitializer");
			break;
		}
		if (!is_type_string(type)) {
			GB_ASSERT(is_type_array(type));
			ir_fprintf(f, "c\"");
			ir_print_escape_string(f, str, false, false);
			ir_fprintf(f, "\"");
		} else {
			// HACK NOTE(bill): This is a hack but it works because strings are created at the very end
			// of the .ll file
			irValue *str_array = ir_add_global_string_array(m, str);
			ir_fprintf(f, "{i8* getelementptr inbounds (");
			ir_print_type(f, m, str_array->Global.entity->type);
			ir_fprintf(f, ", ");
			ir_print_type(f, m, str_array->Global.entity->type);
			ir_fprintf(f, "* ");
			ir_print_encoded_global(f, str_array->Global.entity->token.string, false);
			ir_fprintf(f, ", ");
			ir_print_type(f, m, t_int);
			ir_fprintf(f, " 0, i32 0), ");
			ir_print_type(f, m, t_int);
			ir_fprintf(f, " %lld}", cast(i64)str.len);
		}
	} break;
	case ExactValue_Integer: {
		if (is_type_pointer(type)) {
			if (value.value_integer == 0) {
				ir_fprintf(f, "null");
			} else {
				ir_fprintf(f, "inttoptr (");
				ir_print_type(f, m, t_int);
				ir_fprintf(f, " %llu to ", value.value_integer);
				ir_print_type(f, m, t_rawptr);
				ir_fprintf(f, ")");
			}
		} else {
			ir_fprintf(f, "%lld", value.value_integer);
		}
	} break;
	case ExactValue_Float: {
		GB_ASSERT_MSG(is_type_float(type), "%s", type_to_string(type));
		type = core_type(type);
		u64 u = *cast(u64*)&value.value_float;
		switch (type->Basic.kind) {
		case Basic_f32:
			// IMPORTANT NOTE(bill): LLVM requires all floating point constants to be
			// a 64 bit number if bits_of(float type) <= 64.
			// https://groups.google.com/forum/#!topic/llvm-dev/IlqV3TbSk6M
			// 64 bit mantiir: 52 bits
			// 32 bit mantiir: 23 bits
			// 29 == 52-23
			u >>= 29;
			u <<= 29;
			break;
		}

		switch (type->Basic.kind) {
		case 0: break;
		default:
			ir_fprintf(f, "0x%016llx", u);
			break;
		}
	} break;

	case ExactValue_Complex: {
		type = core_type(type);
		if (is_type_quaternion(type)) {
			Type *ft = base_quaternion_elem_type(type);
			ir_fprintf(f, " {"); ir_print_type(f, m, ft); ir_fprintf(f, " ");
			ir_print_exact_value(f, m, exact_value_float(value.value_complex.real), ft);
			ir_fprintf(f, ", "); ir_print_type(f, m, ft); ir_fprintf(f, " ");
			ir_print_exact_value(f, m, exact_value_float(value.value_complex.imag), ft);
			ir_fprintf(f, ", "); ir_print_type(f, m, ft); ir_fprintf(f, " ");
			ir_print_exact_value(f, m, exact_value_float(0), ft);
			ir_fprintf(f, ", "); ir_print_type(f, m, ft); ir_fprintf(f, " ");
			ir_print_exact_value(f, m, exact_value_float(0), ft);
			ir_fprintf(f, "}");

		} else {
			GB_ASSERT_MSG(is_type_complex(type), "%s", type_to_string(type));
			Type *ft = base_complex_elem_type(type);
			ir_fprintf(f, " {"); ir_print_type(f, m, ft); ir_fprintf(f, " ");
			ir_print_exact_value(f, m, exact_value_float(value.value_complex.real), ft);
			ir_fprintf(f, ", "); ir_print_type(f, m, ft); ir_fprintf(f, " ");
			ir_print_exact_value(f, m, exact_value_float(value.value_complex.imag), ft);
			ir_fprintf(f, "}");
		}
	} break;

	case ExactValue_Quaternion: {
		GB_ASSERT_MSG(is_type_quaternion(type), "%s", type_to_string(type));
		type = core_type(type);
		Type *ft = base_quaternion_elem_type(type);
		ir_fprintf(f, " {"); ir_print_type(f, m, ft); ir_fprintf(f, " ");
		ir_print_exact_value(f, m, exact_value_float(value.value_quaternion.real), ft);
		ir_fprintf(f, ", "); ir_print_type(f, m, ft); ir_fprintf(f, " ");
		ir_print_exact_value(f, m, exact_value_float(value.value_quaternion.imag), ft);
		ir_fprintf(f, ", "); ir_print_type(f, m, ft); ir_fprintf(f, " ");
		ir_print_exact_value(f, m, exact_value_float(value.value_quaternion.jmag), ft);
		ir_fprintf(f, ", "); ir_print_type(f, m, ft); ir_fprintf(f, " ");
		ir_print_exact_value(f, m, exact_value_float(value.value_quaternion.kmag), ft);
		ir_fprintf(f, "}");
	} break;

	case ExactValue_Pointer:
		if (value.value_pointer == 0) {
			ir_fprintf(f, "null");
		} else {
			ir_fprintf(f, "inttoptr (");
			ir_print_type(f, m, t_int);
			ir_fprintf(f, " %llu to ", cast(u64)cast(uintptr)value.value_pointer);
			ir_print_type(f, m, t_rawptr);
			ir_fprintf(f, ")");
		}
		break;

	case ExactValue_Compound: {
		type = base_type(type);
		if (is_type_array(type)) {
			ast_node(cl, CompoundLit, value.value_compound);
			isize elem_count = cl->elems.count;
			if (elem_count == 0) {
				ir_fprintf(f, "zeroinitializer");
				break;
			}

			ir_fprintf(f, "[");
			Type *elem_type = type->Array.elem;

			for (isize i = 0; i < elem_count; i++) {
				if (i > 0) {
					ir_fprintf(f, ", ");
				}
				TypeAndValue *tav = type_and_value_of_expression(m->info, cl->elems.e[i]);
				GB_ASSERT(tav != NULL);
				ir_print_compound_element(f, m, tav->value, elem_type);
			}
			for (isize i = elem_count; i < type->Array.count; i++) {
				if (i >= elem_count) {
					ir_fprintf(f, ", ");
				}
				ir_print_type(f, m, elem_type);
				ir_fprintf(f, " zeroinitializer");
			}

			ir_fprintf(f, "]");
		} else if (is_type_vector(type)) {
			ast_node(cl, CompoundLit, value.value_compound);
			isize elem_count = cl->elems.count;
			if (elem_count == 0) {
				ir_fprintf(f, "zeroinitializer");
				break;
			}

			i64 align = type_align_of(m->allocator, type);
			i64 count = type->Vector.count;
			Type *elem_type = type->Vector.elem;

			ir_fprintf(f, "{[0 x <%lld x i8>] zeroinitializer, [%lld x ", align, count);
			ir_print_type(f, m, elem_type);
			ir_fprintf(f, "][");

			if (elem_count == 1 && type->Vector.count > 1) {
				TypeAndValue *tav = type_and_value_of_expression(m->info, cl->elems.e[0]);
				GB_ASSERT(tav != NULL);

				for (isize i = 0; i < type->Vector.count; i++) {
					if (i > 0) {
						ir_fprintf(f, ", ");
					}
					ir_print_compound_element(f, m, tav->value, elem_type);
				}
			} else {
				for (isize i = 0; i < elem_count; i++) {
					if (i > 0) {
						ir_fprintf(f, ", ");
					}
					TypeAndValue *tav = type_and_value_of_expression(m->info, cl->elems.e[i]);
					GB_ASSERT(tav != NULL);
					ir_print_compound_element(f, m, tav->value, elem_type);
				}
			}

			ir_fprintf(f, "]}");
		} else if (is_type_struct(type)) {
			gbTempArenaMemory tmp = gb_temp_arena_memory_begin(&m->tmp_arena);

			ast_node(cl, CompoundLit, value.value_compound);

			if (cl->elems.count == 0) {
				ir_fprintf(f, "zeroinitializer");
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
					Entity *f = type->Record.fields_in_src_order[i];

					if (str_eq(f->token.string, str_lit("_"))) {
						values[f->Variable.field_index] = (ExactValue){0};
					} else {
						TypeAndValue *tav = type_and_value_of_expression(m->info, cl->elems.e[i]);
						GB_ASSERT(tav != NULL);
						values[f->Variable.field_index] = tav->value;
					}
				}
			}



			if (type->Record.is_packed) {
				ir_fprintf(f, "<");
			}
			ir_fprintf(f, "{");


			for (isize i = 0; i < value_count; i++) {
				if (i > 0) {
					ir_fprintf(f, ", ");
				}
				Type *elem_type = type->Record.fields[i]->type;

				ir_print_compound_element(f, m, values[i], elem_type);
			}


			ir_fprintf(f, "}");
			if (type->Record.is_packed) {
				ir_fprintf(f, ">");
			}

			gb_temp_arena_memory_end(tmp);
		} else {
			ir_fprintf(f, "zeroinitializer");
		}

	} break;

	default:
		ir_fprintf(f, "zeroinitializer");
		// GB_PANIC("Invalid ExactValue: %d", value.kind);
		break;
	}
}

void ir_print_block_name(irFileBuffer *f, irBlock *b) {
	if (b != NULL) {
		ir_print_escape_string(f, b->label, false, false);
		ir_fprintf(f, "-%td", b->index);
	} else {
		ir_fprintf(f, "<INVALID-BLOCK>");
	}
}

bool ir_print_is_proc_global(irModule *m, irProcedure *proc) {
	if (proc->entity != NULL &&
	    proc->entity->kind == Entity_Procedure) {
		if (m->entry_point_entity == proc->entity) {
			// gb_printf("%.*s\n", LIT(proc->entity->token.string));
			// TODO(bill): This may not be needed during windows
			return true;
		}
		if (proc->entity->Procedure.link_name.len > 0) {
		    return true;
		}
	}
	return (proc->tags & (ProcTag_foreign|ProcTag_export)) != 0;
}

void ir_print_value(irFileBuffer *f, irModule *m, irValue *value, Type *type_hint) {
	if (value == NULL) {
		ir_fprintf(f, "!!!NULL_VALUE");
		return;
	}
	switch (value->kind) {
	default: GB_PANIC("Unknown irValue kind"); break;

	case irValue_Constant:
		ir_print_exact_value(f, m, value->Constant.value, type_hint);
		break;

	case irValue_ConstantSlice: {
		irValueConstantSlice *cs = &value->ConstantSlice;
		if (cs->backing_array == NULL || cs->count == 0) {
			ir_fprintf(f, "zeroinitializer");
		} else {
			Type *at = base_type(type_deref(ir_type(cs->backing_array)));
			Type *et = at->Array.elem;
			ir_fprintf(f, "{");
			ir_print_type(f, m, et);
			ir_fprintf(f, "* getelementptr inbounds (");
			ir_print_type(f, m, at);
			ir_fprintf(f, ", ");
			ir_print_type(f, m, at);
			ir_fprintf(f, "* ");
			ir_print_value(f, m, cs->backing_array, at);
			ir_fprintf(f, ", ");
			ir_print_type(f, m, t_int);
			ir_fprintf(f, " 0, i32 0), ");
			ir_print_type(f, m, t_int);
			ir_fprintf(f, " %lld, ", cs->count);
			ir_print_type(f, m, t_int);
			ir_fprintf(f, " %lld}", cs->count);
		}
	} break;

	case irValue_Nil:
		ir_fprintf(f, "zeroinitializer");
		break;

	case irValue_TypeName:
		ir_print_encoded_local(f, value->TypeName.name);
		break;
	case irValue_Global: {
		Scope *scope = value->Global.entity->scope;
		bool in_global_scope = false;
		if (scope != NULL) {
			// TODO(bill): Fix this rule. What should it be?
			in_global_scope = scope->is_global || scope->is_init;
		}
		ir_print_encoded_global(f, ir_get_global_name(m, value), in_global_scope);
	} break;
	case irValue_Param:
		ir_print_encoded_local(f, value->Param.entity->token.string);
		break;
	case irValue_Proc:
		ir_print_encoded_global(f, value->Proc.name, ir_print_is_proc_global(m, &value->Proc));
		break;
	case irValue_Instr:
		ir_fprintf(f, "%%%d", value->index);
		break;
	}
}

void ir_print_calling_convention(irFileBuffer *f, irModule *m, ProcCallingConvention cc) {
	switch (cc) {
	case ProcCC_Odin: ir_fprintf(f, "");       break;
	case ProcCC_C:    ir_fprintf(f, "ccc ");   break;
	case ProcCC_Std:  ir_fprintf(f, "cc 64 "); break;
	case ProcCC_Fast: ir_fprintf(f, "cc 65 "); break;
	default: GB_PANIC("unknown calling convention: %d", cc);
	}
}

void ir_print_instr(irFileBuffer *f, irModule *m, irValue *value) {
	GB_ASSERT(value->kind == irValue_Instr);
	irInstr *instr = &value->Instr;

	ir_fprintf(f, "\t");

	switch (instr->kind) {
	default: {
		GB_PANIC("<unknown instr> %d\n", instr->kind);
		ir_fprintf(f, "; <unknown instr> %d\n", instr->kind);
	} break;

	case irInstr_StartupRuntime: {
		ir_fprintf(f, "call void ");
		ir_print_encoded_global(f, str_lit(IR_STARTUP_RUNTIME_PROC_NAME), false);
		ir_fprintf(f, "()\n");
	} break;

	case irInstr_Comment:
		ir_fprintf(f, "; %.*s\n", LIT(instr->Comment.text));
		break;

	case irInstr_Local: {
		Type *type = instr->Local.entity->type;
		i64 align = instr->Local.alignment;
		if (align <= 0) {
			align = type_align_of(m->allocator, type);
		}
		ir_fprintf(f, "%%%d = alloca ", value->index);
		ir_print_type(f, m, type);
		ir_fprintf(f, ", align %lld\n", align);
	} break;

	case irInstr_ZeroInit: {
		Type *type = type_deref(ir_type(instr->ZeroInit.address));
		ir_fprintf(f, "store ");
		ir_print_type(f, m, type);
		ir_fprintf(f, " zeroinitializer, ");
		ir_print_type(f, m, type);
		ir_fprintf(f, "* %%%d\n", instr->ZeroInit.address->index);
	} break;

	case irInstr_Store: {
		Type *type = type_deref(ir_type(instr->Store.address));
		ir_fprintf(f, "store ");
		if (instr->Store.atomic) {
			ir_fprintf(f, "atomic ");
		}
		ir_print_type(f, m, type);
		ir_fprintf(f, " ");
		ir_print_value(f, m, instr->Store.value, type);
		ir_fprintf(f, ", ");
		ir_print_type(f, m, type);
		ir_fprintf(f, "* ");
		ir_print_value(f, m, instr->Store.address, type);
		if (is_type_atomic(type)) {
			// TODO(bill): Do ordering
			ir_fprintf(f, " unordered");
			ir_fprintf(f, ", align %lld\n", type_align_of(m->allocator, type));
		}
		ir_fprintf(f, "\n");
	} break;

	case irInstr_Load: {
		Type *type = instr->Load.type;
		ir_fprintf(f, "%%%d = load ", value->index);
		if (is_type_atomic(type)) {
			ir_fprintf(f, "atomic ");
		}
		ir_print_type(f, m, type);
		ir_fprintf(f, ", ");
		ir_print_type(f, m, type);
		ir_fprintf(f, "* ");
		ir_print_value(f, m, instr->Load.address, type);
		if (is_type_atomic(type)) {
			// TODO(bill): Do ordering
			ir_fprintf(f, " unordered");
		}
		ir_fprintf(f, ", align %lld\n", type_align_of(m->allocator, type));
	} break;

	case irInstr_ArrayElementPtr: {
		Type *et = ir_type(instr->ArrayElementPtr.address);
		ir_fprintf(f, "%%%d = getelementptr inbounds ", value->index);

		ir_print_type(f, m, type_deref(et));
		ir_fprintf(f, ", ");
		ir_print_type(f, m, et);
		ir_fprintf(f, " ");
		ir_print_value(f, m, instr->ArrayElementPtr.address, et);
		ir_fprintf(f, ", ");
		ir_print_type(f, m, t_int);
		ir_fprintf(f, " 0, ");
		if (is_type_vector(type_deref(et))) {
			ir_print_type(f, m, t_i32);
			ir_fprintf(f, " 1, ");
		}

		irValue *index =instr->ArrayElementPtr.elem_index;
		Type *t = ir_type(index);
		ir_print_type(f, m, t);
		ir_fprintf(f, " ");
		ir_print_value(f, m, index, t);
		ir_fprintf(f, "\n");
	} break;

	case irInstr_StructElementPtr: {
		Type *et = ir_type(instr->StructElementPtr.address);
		ir_fprintf(f, "%%%d = getelementptr inbounds ", value->index);
		i32 index = instr->StructElementPtr.elem_index;
		Type *st = base_type(type_deref(et));
		if (is_type_struct(st)) {
			if (st->Record.custom_align > 0) {
				index += 1;
			}
		} else if (is_type_union(st)) {
			index += 1;
		}

		ir_print_type(f, m, type_deref(et));
		ir_fprintf(f, ", ");
		ir_print_type(f, m, et);
		ir_fprintf(f, " ");
		ir_print_value(f, m, instr->StructElementPtr.address, et);
		ir_fprintf(f, ", ");
		ir_print_type(f, m, t_int);
		ir_fprintf(f, " 0, ");
		ir_print_type(f, m, t_i32);
		ir_fprintf(f, " %d", index);
		ir_fprintf(f, "\n");
	} break;

	case irInstr_PtrOffset: {
		Type *pt = ir_type(instr->PtrOffset.address);
		ir_fprintf(f, "%%%d = getelementptr inbounds ", value->index);
		ir_print_type(f, m, type_deref(pt));
		ir_fprintf(f, ", ");
		ir_print_type(f, m, pt);
		ir_fprintf(f, " ");
		ir_print_value(f, m, instr->PtrOffset.address, pt);

		irValue *offset = instr->PtrOffset.offset;
		Type *t = ir_type(offset);
		ir_fprintf(f, ", ");
		ir_print_type(f, m, t);
		ir_fprintf(f, " ");
		ir_print_value(f, m, offset, t);
		ir_fprintf(f, "\n");
	} break;

	case irInstr_Phi: {
		ir_fprintf(f, "%%%d = phi ", value->index);
		ir_print_type(f, m, instr->Phi.type);
		ir_fprintf(f, " ", value->index);

		for (isize i = 0; i < instr->Phi.edges.count; i++) {
			if (i > 0) {
				ir_fprintf(f, ", ");
			}

			irValue *edge = instr->Phi.edges.e[i];
			irBlock *block = NULL;
			if (instr->parent != NULL &&
			    i < instr->parent->preds.count) {
				block = instr->parent->preds.e[i];
			}

			ir_fprintf(f, "[ ");
			ir_print_value(f, m, edge, instr->Phi.type);
			ir_fprintf(f, ", %%");
			ir_print_block_name(f, block);
			ir_fprintf(f, " ]");
		}
		ir_fprintf(f, "\n");
	} break;

	case irInstr_StructExtractValue: {
		Type *et = ir_type(instr->StructExtractValue.address);
		ir_fprintf(f, "%%%d = extractvalue ", value->index);
		i32 index = instr->StructExtractValue.index;
		Type *st = base_type(et);
		if (is_type_struct(st)) {
			if (st->Record.custom_align > 0) {
				index += 1;
			}
		} else if (is_type_union(st)) {
			index += 1;
		}


		ir_print_type(f, m, et);
		ir_fprintf(f, " ");
		ir_print_value(f, m, instr->StructExtractValue.address, et);
		ir_fprintf(f, ", %d\n", index);
	} break;

	case irInstr_UnionTagPtr: {
		Type *et = ir_type(instr->UnionTagPtr.address);
		ir_fprintf(f, "%%%d = getelementptr inbounds ", value->index);
		Type *t = base_type(type_deref(et));
		GB_ASSERT(is_type_union(t));

		ir_print_type(f, m, type_deref(et));
		ir_fprintf(f, ", ");
		ir_print_type(f, m, et);
		ir_fprintf(f, " ");
		ir_print_value(f, m, instr->UnionTagPtr.address, et);
		ir_fprintf(f, ", ");
		ir_print_type(f, m, t_int);
		ir_fprintf(f, " 0, ");
		ir_print_type(f, m, t_i32);
	#if 1
		ir_fprintf(f, " %d", 2 + t->Record.field_count);
	#else
		ir_fprintf(f, " %d", 2);
	#endif
		ir_fprintf(f, " ; UnionTagPtr");
		ir_fprintf(f, "\n");
	} break;

	case irInstr_UnionTagValue: {
		Type *et = ir_type(instr->UnionTagValue.address);
		ir_fprintf(f, "%%%d = extractvalue ", value->index);
		Type *t = base_type(et);
		GB_ASSERT(is_type_union(t));

		ir_print_type(f, m, et);
		ir_fprintf(f, " ");
		ir_print_value(f, m, instr->UnionTagValue.address, et);
		ir_fprintf(f, ",");
	#if 1
		ir_fprintf(f, " %d", 2 + t->Record.field_count);
	#else
		ir_fprintf(f, " %d", 2);
	#endif
		ir_fprintf(f, ", %d", 2 + t->Record.field_count);
		ir_fprintf(f, " ; UnionTagValue");
		ir_fprintf(f, "\n");
	} break;

	case irInstr_Jump: {;
		ir_fprintf(f, "br label %%");
		ir_print_block_name(f, instr->Jump.block);
		ir_fprintf(f, "\n");
	} break;

	case irInstr_If: {;
		ir_fprintf(f, "br ");
		ir_print_type(f, m, t_bool);
		ir_fprintf(f, " ");
		ir_print_value(f, m, instr->If.cond, t_bool);
		ir_fprintf(f, ", ", instr->If.cond->index);
		ir_fprintf(f, "label %%");   ir_print_block_name(f, instr->If.true_block);
		ir_fprintf(f, ", label %%"); ir_print_block_name(f, instr->If.false_block);
		ir_fprintf(f, "\n");
	} break;

	case irInstr_Return: {
		irInstrReturn *ret = &instr->Return;
		ir_fprintf(f, "ret ");
		if (ret->value == NULL) {
			ir_fprintf(f, "void");
		} else {
			Type *t = ir_type(ret->value);
			ir_print_type(f, m, t);
			ir_fprintf(f, " ");
			ir_print_value(f, m, ret->value, t);
		}

		ir_fprintf(f, "\n");

	} break;

	case irInstr_Conv: {
		irInstrConv *c = &instr->Conv;
		ir_fprintf(f, "%%%d = %.*s ", value->index, LIT(ir_conv_strings[c->kind]));
		ir_print_type(f, m, c->from);
		ir_fprintf(f, " ");
		ir_print_value(f, m, c->value, c->from);
		ir_fprintf(f, " to ");
		ir_print_type(f, m, c->to);
		ir_fprintf(f, "\n");

	} break;

	case irInstr_Unreachable: {
		ir_fprintf(f, "unreachable\n");
	} break;

	case irInstr_UnaryOp: {
		irInstrUnaryOp *uo = &value->Instr.UnaryOp;
		Type *type = base_type(ir_type(uo->expr));
		Type *elem_type = type;
		while (elem_type->kind == Type_Vector) {
			elem_type = base_type(elem_type->Vector.elem);
		}

		ir_fprintf(f, "%%%d = ", value->index);
		switch (uo->op) {
		case Token_Sub:
			if (is_type_float(elem_type)) {
				ir_fprintf(f, "fsub");
			} else {
				ir_fprintf(f, "sub");
			}
			break;
		case Token_Xor:
		case Token_Not:
			GB_ASSERT(is_type_integer(type) || is_type_boolean(type));
			ir_fprintf(f, "xor");
			break;
		default:
			GB_PANIC("Unknown unary operator");
			break;
		}

		ir_fprintf(f, " ");
		ir_print_type(f, m, type);
		ir_fprintf(f, " ");
		switch (uo->op) {
		case Token_Sub:
			if (is_type_float(elem_type)) {
				ir_print_exact_value(f, m, exact_value_float(0), elem_type);
			} else {
				ir_fprintf(f, "0");
			}
			break;
		case Token_Xor:
		case Token_Not:
			GB_ASSERT(is_type_integer(type) || is_type_boolean(type));
			ir_fprintf(f, "-1");
			break;
		}
		ir_fprintf(f, ", ");
		ir_print_value(f, m, uo->expr, type);
		ir_fprintf(f, "\n");
	} break;

	case irInstr_BinaryOp: {
		irInstrBinaryOp *bo = &value->Instr.BinaryOp;
		Type *type = base_type(ir_type(bo->left));
		Type *elem_type = type;
		GB_ASSERT(!is_type_vector(elem_type));

		ir_fprintf(f, "%%%d = ", value->index);

		if (gb_is_between(bo->op, Token__ComparisonBegin+1, Token__ComparisonEnd-1)) {
			if (is_type_string(elem_type)) {
				ir_fprintf(f, "call ");
				ir_print_calling_convention(f, m, ProcCC_Odin);
				ir_print_type(f, m, t_bool);
				char *runtime_proc = "";
				switch (bo->op) {
				case Token_CmpEq: runtime_proc = "__string_eq"; break;
				case Token_NotEq: runtime_proc = "__string_ne"; break;
				case Token_Lt:    runtime_proc = "__string_lt"; break;
				case Token_Gt:    runtime_proc = "__string_gt"; break;
				case Token_LtEq:  runtime_proc = "__string_le"; break;
				case Token_GtEq:  runtime_proc = "__string_gt"; break;
				}

				ir_fprintf(f, " ");
				ir_print_encoded_global(f, make_string_c(runtime_proc), false);
				ir_fprintf(f, "(");
				ir_print_type(f, m, type);
				ir_fprintf(f, " ");
				ir_print_value(f, m, bo->left, type);
				ir_fprintf(f, ", ");
				ir_print_type(f, m, type);
				ir_fprintf(f, " ");
				ir_print_value(f, m, bo->right, type);
				ir_fprintf(f, ")\n");
				return;

			} else if (is_type_float(elem_type)) {
				ir_fprintf(f, "fcmp ");
				switch (bo->op) {
				case Token_CmpEq: ir_fprintf(f, "oeq"); break;
				case Token_NotEq: ir_fprintf(f, "one"); break;
				case Token_Lt:    ir_fprintf(f, "olt"); break;
				case Token_Gt:    ir_fprintf(f, "ogt"); break;
				case Token_LtEq:  ir_fprintf(f, "ole"); break;
				case Token_GtEq:  ir_fprintf(f, "oge"); break;
				}
			} else if (is_type_complex(elem_type)) {
				ir_fprintf(f, "call ");
				ir_print_calling_convention(f, m, ProcCC_Odin);
				ir_print_type(f, m, t_bool);
				char *runtime_proc = "";
				i64 sz = 8*type_size_of(m->allocator, elem_type);
				switch (sz) {
				case 64:
					switch (bo->op) {
					case Token_CmpEq: runtime_proc = "__complex64_eq"; break;
					case Token_NotEq: runtime_proc = "__complex64_ne"; break;
					}
					break;
				case 128:
					switch (bo->op) {
					case Token_CmpEq: runtime_proc = "__complex128_eq"; break;
					case Token_NotEq: runtime_proc = "__complex128_ne"; break;
					}
					break;
				}

				ir_fprintf(f, " ");
				ir_print_encoded_global(f, make_string_c(runtime_proc), false);
				ir_fprintf(f, "(");
				ir_print_type(f, m, type);
				ir_fprintf(f, " ");
				ir_print_value(f, m, bo->left, type);
				ir_fprintf(f, ", ");
				ir_print_type(f, m, type);
				ir_fprintf(f, " ");
				ir_print_value(f, m, bo->right, type);
				ir_fprintf(f, ")\n");
				return;
			} else if (is_type_quaternion(elem_type)) {
				ir_fprintf(f, "call ");
				ir_print_calling_convention(f, m, ProcCC_Odin);
				ir_print_type(f, m, t_bool);
				char *runtime_proc = "";
				i64 sz = 8*type_size_of(m->allocator, elem_type);
				switch (sz) {
				case 128:
					switch (bo->op) {
					case Token_CmpEq: runtime_proc = "__quaternion128_eq"; break;
					case Token_NotEq: runtime_proc = "__quaternion128_ne"; break;
					}
					break;
				case 256:
					switch (bo->op) {
					case Token_CmpEq: runtime_proc = "__quaternion256_eq"; break;
					case Token_NotEq: runtime_proc = "__quaternion256_ne"; break;
					}
					break;
				}

				ir_fprintf(f, " ");
				ir_print_encoded_global(f, make_string_c(runtime_proc), false);
				ir_fprintf(f, "(");
				ir_print_type(f, m, type);
				ir_fprintf(f, " ");
				ir_print_value(f, m, bo->left, type);
				ir_fprintf(f, ", ");
				ir_print_type(f, m, type);
				ir_fprintf(f, " ");
				ir_print_value(f, m, bo->right, type);
				ir_fprintf(f, ")\n");
				return;
			} else {
				ir_fprintf(f, "icmp ");
				if (bo->op != Token_CmpEq &&
				    bo->op != Token_NotEq) {
					if (is_type_unsigned(elem_type)) {
						ir_fprintf(f, "u");
					} else {
						ir_fprintf(f, "s");
					}
				}
				switch (bo->op) {
				case Token_CmpEq: ir_fprintf(f, "eq"); break;
				case Token_NotEq: ir_fprintf(f, "ne"); break;
				case Token_Lt:    ir_fprintf(f, "lt"); break;
				case Token_Gt:    ir_fprintf(f, "gt"); break;
				case Token_LtEq:  ir_fprintf(f, "le"); break;
				case Token_GtEq:  ir_fprintf(f, "ge"); break;
				default: GB_PANIC("invalid comparison");break;
				}
			}
		} else {
			if (is_type_float(elem_type)) {
				ir_fprintf(f, "f");
			}

			switch (bo->op) {
			case Token_Add:    ir_fprintf(f, "add");  break;
			case Token_Sub:    ir_fprintf(f, "sub");  break;
			case Token_And:    ir_fprintf(f, "and");  break;
			case Token_Or:     ir_fprintf(f, "or");   break;
			case Token_Xor:    ir_fprintf(f, "xor");  break;
			case Token_Shl:    ir_fprintf(f, "shl");  break;
			case Token_Shr:    ir_fprintf(f, "lshr"); break;
			case Token_Mul:    ir_fprintf(f, "mul");  break;
			case Token_Not:    ir_fprintf(f, "xor");  break;

			case Token_AndNot: GB_PANIC("Token_AndNot Should never be called");

			default: {
				if (!is_type_float(elem_type)) {
					if (is_type_unsigned(elem_type)) {
						ir_fprintf(f, "u");
					} else {
						ir_fprintf(f, "s");
					}
				}

				switch (bo->op) {
				case Token_Quo: ir_fprintf(f, "div"); break;
				case Token_Mod: ir_fprintf(f, "rem"); break;
				}
			} break;
			}
		}

		ir_fprintf(f, " ");
		ir_print_type(f, m, type);
		ir_fprintf(f, " ");
		ir_print_value(f, m, bo->left, type);
		ir_fprintf(f, ", ");
		ir_print_value(f, m, bo->right, type);
		ir_fprintf(f, "\n");
	} break;

	case irInstr_Call: {
		irInstrCall *call = &instr->Call;
		Type *proc_type = base_type(ir_type(call->value));
		GB_ASSERT(is_type_proc(proc_type));
		Type *result_type = call->type;
		if (result_type) {
			ir_fprintf(f, "%%%d = ", value->index);
		}
		ir_fprintf(f, "call ");
		ir_print_calling_convention(f, m, proc_type->Proc.calling_convention);
		if (result_type) {
			ir_print_proc_results(f, m, proc_type);
		} else {
			ir_fprintf(f, "void");
		}
		ir_fprintf(f, " ");
		ir_print_value(f, m, call->value, call->type);


		ir_fprintf(f, "(");
		if (call->arg_count > 0) {
			Type *proc_type = base_type(ir_type(call->value));
			GB_ASSERT(proc_type->kind == Type_Proc);
			TypeTuple *params = &proc_type->Proc.params->Tuple;
			for (isize i = 0; i < call->arg_count; i++) {
				Entity *e = params->variables[i];
				GB_ASSERT(e != NULL);
				Type *t = proc_type->Proc.abi_compat_params[i];
				if (i > 0) {
					ir_fprintf(f, ", ");
				}
				ir_print_type(f, m, t);
				if (e->flags&EntityFlag_NoAlias) {
					ir_fprintf(f, " noalias");
				}
				ir_fprintf(f, " ");
				irValue *arg = call->args[i];
				ir_print_value(f, m, arg, t);
			}
		}
		ir_fprintf(f, ")\n");

	} break;

	case irInstr_Select: {
		ir_fprintf(f, "%%%d = select i1 ", value->index);
		ir_print_value(f, m, instr->Select.cond, t_bool);
		ir_fprintf(f, ", ");
		ir_print_type(f, m, ir_type(instr->Select.true_value));
		ir_fprintf(f, " ");
		ir_print_value(f, m, instr->Select.true_value, ir_type(instr->Select.true_value));
		ir_fprintf(f, ", ");
		ir_print_type(f, m, ir_type(instr->Select.false_value));
		ir_fprintf(f, " ");
		ir_print_value(f, m, instr->Select.false_value, ir_type(instr->Select.false_value));
		ir_fprintf(f, "\n");
	} break;

	// case irInstr_VectorExtractElement: {
		// Type *vt = ir_type(instr->VectorExtractElement.vector);
		// Type *it = ir_type(instr->VectorExtractElement.index);
		// ir_fprintf(f, "%%%d = extractelement ", value->index);

		// ir_print_type(f, m, vt);
		// ir_fprintf(f, " ");
		// ir_print_value(f, m, instr->VectorExtractElement.vector, vt);
		// ir_fprintf(f, ", ");
		// ir_print_type(f, m, it);
		// ir_fprintf(f, " ");
		// ir_print_value(f, m, instr->VectorExtractElement.index, it);
		// ir_fprintf(f, "\n");
	// } break;

	// case irInstr_VectorInsertElement: {
	// 	irInstrVectorInsertElement *ie = &instr->VectorInsertElement;
	// 	Type *vt = ir_type(ie->vector);
	// 	ir_fprintf(f, "%%%d = insertelement ", value->index);

	// 	ir_print_type(f, m, vt);
	// 	ir_fprintf(f, " ");
	// 	ir_print_value(f, m, ie->vector, vt);
	// 	ir_fprintf(f, ", ");

	// 	ir_print_type(f, m, ir_type(ie->elem));
	// 	ir_fprintf(f, " ");
	// 	ir_print_value(f, m, ie->elem, ir_type(ie->elem));
	// 	ir_fprintf(f, ", ");

	// 	ir_print_type(f, m, ir_type(ie->index));
	// 	ir_fprintf(f, " ");
	// 	ir_print_value(f, m, ie->index, ir_type(ie->index));

	// 	ir_fprintf(f, "\n");
	// } break;

	// case irInstr_VectorShuffle: {
	// 	irInstrVectorShuffle *sv = &instr->VectorShuffle;
	// 	Type *vt = ir_type(sv->vector);
	// 	ir_fprintf(f, "%%%d = shufflevector ", value->index);

	// 	ir_print_type(f, m, vt);
	// 	ir_fprintf(f, " ");
	// 	ir_print_value(f, m, sv->vector, vt);
	// 	ir_fprintf(f, ", ");

	// 	ir_print_type(f, m, vt);
	// 	ir_fprintf(f, " ");
	// 	ir_print_value(f, m, sv->vector, vt);
	// 	ir_fprintf(f, ", ");

	// 	ir_fprintf(f, "<%td x i32> <", sv->index_count);
	// 	for (isize i = 0; i < sv->index_count; i++) {
	// 		if (i > 0) {
	// 			ir_fprintf(f, ", ");
	// 		}
	// 		ir_fprintf(f, "i32 %d", sv->indices[i]);
	// 	}
	// 	ir_fprintf(f, ">");
	// 	ir_fprintf(f, "\n");
	// } break;

	case irInstr_BoundsCheck: {
		irInstrBoundsCheck *bc = &instr->BoundsCheck;
		ir_fprintf(f, "call void ");
		ir_print_encoded_global(f, str_lit("__bounds_check_error"), false);
		ir_fprintf(f, "(");
		ir_print_compound_element(f, m, exact_value_string(bc->pos.file), t_string);
		ir_fprintf(f, ", ");

		ir_print_type(f, m, t_int);
		ir_fprintf(f, " ");
		ir_print_exact_value(f, m, exact_value_integer(bc->pos.line), t_int);
		ir_fprintf(f, ", ");

		ir_print_type(f, m, t_int);
		ir_fprintf(f, " ");
		ir_print_exact_value(f, m, exact_value_integer(bc->pos.column), t_int);
		ir_fprintf(f, ", ");

		ir_print_type(f, m, t_int);
		ir_fprintf(f, " ");
		ir_print_value(f, m, bc->index, t_int);
		ir_fprintf(f, ", ");

		ir_print_type(f, m, t_int);
		ir_fprintf(f, " ");
		ir_print_value(f, m, bc->len, t_int);

		ir_fprintf(f, ")\n");
	} break;

	case irInstr_SliceBoundsCheck: {
		irInstrSliceBoundsCheck *bc = &instr->SliceBoundsCheck;
		ir_fprintf(f, "call void ");
		if (bc->is_substring) {
			ir_print_encoded_global(f, str_lit("__substring_expr_error"), false);
		} else {
			ir_print_encoded_global(f, str_lit("__slice_expr_error"), false);
		}

		ir_fprintf(f, "(");
		ir_print_compound_element(f, m, exact_value_string(bc->pos.file), t_string);
		ir_fprintf(f, ", ");

		ir_print_type(f, m, t_int);
		ir_fprintf(f, " ");
		ir_print_exact_value(f, m, exact_value_integer(bc->pos.line), t_int);
		ir_fprintf(f, ", ");

		ir_print_type(f, m, t_int);
		ir_fprintf(f, " ");
		ir_print_exact_value(f, m, exact_value_integer(bc->pos.column), t_int);
		ir_fprintf(f, ", ");

		ir_print_type(f, m, t_int);
		ir_fprintf(f, " ");
		ir_print_value(f, m, bc->low, t_int);
		ir_fprintf(f, ", ");

		ir_print_type(f, m, t_int);
		ir_fprintf(f, " ");
		ir_print_value(f, m, bc->high, t_int);

		if (!bc->is_substring) {
			ir_fprintf(f, ", ");
			ir_print_type(f, m, t_int);
			ir_fprintf(f, " ");
			ir_print_value(f, m, bc->max, t_int);
		}

		ir_fprintf(f, ")\n");
	} break;

	case irInstr_DebugDeclare: {
		/* irInstrDebugDeclare *dd = &instr->DebugDeclare;
		Type *vt = ir_type(dd->value);
		irDebugInfo *di = dd->debug_info;
		Entity *e = dd->entity;
		String name = e->token.string;
		TokenPos pos = e->token.pos;
		// gb_printf("debug_declare %.*s\n", LIT(dd->entity->token.string));
		ir_fprintf(f, "call void @llvm.dbg.declare(");
		ir_fprintf(f, "metadata ");
		ir_print_type(f, m, vt);
		ir_fprintf(f, " ");
		ir_print_value(f, m, dd->value, vt);
		ir_fprintf(f, ", metadata !DILocalVariable(name: \"");
		ir_print_escape_string(f, name, false);
		ir_fprintf(f, "\", scope: !%d, line: %td)", di->id, pos.line);
		ir_fprintf(f, ", metadata !DIExpression()");
		ir_fprintf(f, ")");
		ir_fprintf(f, ", !dbg !DILocation(line: %td, column: %td, scope: !%d)", pos.line, pos.column, di->id);

		ir_fprintf(f, "\n"); */
	} break;
	}
}


void ir_print_proc(irFileBuffer *f, irModule *m, irProcedure *proc) {
	if (proc->body == NULL) {
		ir_fprintf(f, "declare ");
		// if (proc->tags & ProcTag_dll_import) {
			// ir_fprintf(f, "dllimport ");
		// }
	} else {
		ir_fprintf(f, "\n");
		ir_fprintf(f, "define ");
		if (build_context.is_dll) {
			// if (proc->tags & (ProcTag_export|ProcTag_dll_export)) {
			if (proc->tags & (ProcTag_export)) {
				ir_fprintf(f, "dllexport ");
			}
		}
	}

	TypeProc *proc_type = &proc->type->Proc;

	ir_print_calling_convention(f, m, proc_type->calling_convention);

	isize param_count = proc_type->param_count;
	isize result_count = proc_type->result_count;
	ir_print_proc_results(f, m, proc->type);
	ir_fprintf(f, " ");

// #ifndef GB_SYSTEM_WINDOWS
#if 0
	if(uses_args)
		ir_fprintf(f, "@.nix_argpatch_main");
	else
#endif
	ir_print_encoded_global(f, proc->name, ir_print_is_proc_global(m, proc));

	ir_fprintf(f, "(");

	if (param_count > 0) {
		TypeTuple *params = &proc_type->params->Tuple;
		for (isize i = 0; i < params->variable_count; i++) {
			Entity *e = params->variables[i];
			Type *original_type = e->type;
			Type *abi_type = proc_type->abi_compat_params[i];
			if (i > 0) {
				ir_fprintf(f, ", ");
			}
			ir_print_type(f, m, abi_type);
			if (e->flags&EntityFlag_NoAlias) {
				ir_fprintf(f, " noalias");
			}
			if (proc->body != NULL) {
				if (!str_eq(e->token.string, str_lit("")) &&
				    !str_eq(e->token.string, str_lit("_"))) {
					ir_fprintf(f, " ");
					ir_print_encoded_local(f, e->token.string);
				} else {
					ir_fprintf(f, " %%_.param_%td", i);
				}
			}
		}
	}

	ir_fprintf(f, ") ");

	if (proc->tags & ProcTag_inline) {
		ir_fprintf(f, "alwaysinline ");
	}
	if (proc->tags & ProcTag_no_inline) {
		ir_fprintf(f, "noinline ");
	}


	if (proc->entity != NULL) {
		if (proc->body != NULL) {
			irDebugInfo **di_ = map_ir_debug_info_get(&proc->module->debug_info, hash_pointer(proc->entity));
			if (di_ != NULL) {
				irDebugInfo *di = *di_;
				GB_ASSERT(di->kind == irDebugInfo_Proc);
				// ir_fprintf(f, "!dbg !%d ", di->id);
			}
		}
	}


	if (proc->body != NULL) {
		// ir_fprintf(f, "nounwind uwtable {\n");

		ir_fprintf(f, "{\n");
		for_array(i, proc->blocks) {
			irBlock *block = proc->blocks.e[i];

			if (i > 0) ir_fprintf(f, "\n");
			ir_print_block_name(f, block);
			ir_fprintf(f, ":\n");

			for_array(j, block->instrs) {
				irValue *value = block->instrs.e[j];
				ir_print_instr(f, m, value);
			}
		}
		ir_fprintf(f, "}\n");
	} else {
		ir_fprintf(f, "\n");
	}

	for_array(i, proc->children) {
		ir_print_proc(f, m, proc->children.e[i]);
	}
}

void ir_print_type_name(irFileBuffer *f, irModule *m, irValue *v) {
	GB_ASSERT(v->kind == irValue_TypeName);
	Type *bt = base_type(ir_type(v));
	if (!is_type_struct(bt) && !is_type_union(bt)) {
		return;
	}
	ir_print_encoded_local(f, v->TypeName.name);
	ir_fprintf(f, " = type ");
	ir_print_type(f, m, base_type(v->TypeName.type));
	ir_fprintf(f, "\n");
}

void print_llvm_ir(irGen *ir) {
	irModule *m = &ir->module;
	irFileBuffer buf = {0}, *f = &buf;
	ir_file_buffer_init(f, &ir->output_file);

	ir_print_encoded_local(f, str_lit("..string"));
	ir_fprintf(f, " = type {i8*, ");
	ir_print_type(f, m, t_int);
	ir_fprintf(f, "} ; Basic_string\n");
	ir_print_encoded_local(f, str_lit("..rawptr"));
	ir_fprintf(f, " = type i8* ; Basic_rawptr\n");

	ir_print_encoded_local(f, str_lit("..complex64"));
	ir_fprintf(f, " = type {float, float} ; Basic_complex64\n");
	ir_print_encoded_local(f, str_lit("..complex128"));
	ir_fprintf(f, " = type {double, double} ; Basic_complex128\n");
	ir_print_encoded_local(f, str_lit("..quaternion128"));
	ir_fprintf(f, " = type {float, float, float, float} ; Basic_quaternion128\n");
	ir_print_encoded_local(f, str_lit("..quaternion256"));
	ir_fprintf(f, " = type {double, double, double, double} ; Basic_quaternion256\n");


	ir_print_encoded_local(f, str_lit("..any"));
	ir_fprintf(f, " = type {");
	ir_print_type(f, m, t_rawptr);
	ir_fprintf(f, ", ");
	ir_print_type(f, m, t_type_info_ptr);
	ir_fprintf(f, "} ; Basic_any\n");

	ir_fprintf(f, "declare void @llvm.dbg.declare(metadata, metadata, metadata) nounwind readnone \n");


	for_array(member_index, m->members.entries) {
		MapIrValueEntry *entry = &m->members.entries.e[member_index];
		irValue *v = entry->value;
		if (v->kind != irValue_TypeName) {
			continue;
		}
		ir_print_type_name(f, m, v);
	}

	ir_fprintf(f, "\n");

	bool dll_main_found = false;

	for_array(member_index, m->members.entries) {
		MapIrValueEntry *entry = &m->members.entries.e[member_index];
		irValue *v = entry->value;
		if (v->kind != irValue_Proc) {
			continue;
		}

		if (v->Proc.body == NULL) {
			ir_print_proc(f, m, &v->Proc);
		}
	}

	for_array(member_index, m->members.entries) {
		MapIrValueEntry *entry = &m->members.entries.e[member_index];
		irValue *v = entry->value;
		if (v->kind != irValue_Proc) {
			continue;
		}

		if (v->Proc.body != NULL) {
			ir_print_proc(f, m, &v->Proc);
		}
	}

	for_array(member_index, m->members.entries) {
		MapIrValueEntry *entry = &m->members.entries.e[member_index];
		irValue *v = entry->value;
		if (v->kind != irValue_Global) {
			continue;
		}
		irValueGlobal *g = &v->Global;
		Scope *scope = g->entity->scope;
		bool in_global_scope = false;
		if (scope != NULL) {
			// TODO(bill): Fix this rule. What should it be?
			in_global_scope = scope->is_global || scope->is_init;
			// in_global_scope = value->Global.name_is_not_mangled;
		}

		ir_print_encoded_global(f, ir_get_global_name(m, v), in_global_scope);
		ir_fprintf(f, " = ");
		if (g->is_foreign) {
			ir_fprintf(f, "external ");
		}
		if (g->is_thread_local) {
			ir_fprintf(f, "thread_local ");
		}

		if (g->is_private) {
			ir_fprintf(f, "private ");
		}
		if (g->is_constant) {
			if (g->is_unnamed_addr) {
				ir_fprintf(f, "unnamed_addr ");
			}
			ir_fprintf(f, "constant ");
		} else {
			ir_fprintf(f, "global ");
		}


		ir_print_type(f, m, g->entity->type);
		ir_fprintf(f, " ");
		if (!g->is_foreign) {
			if (g->value != NULL) {
				ir_print_value(f, m, g->value, g->entity->type);
			} else {
				ir_fprintf(f, "zeroinitializer");
			}
		}
		ir_fprintf(f, "\n");
	}


#if 0
	// if (m->generate_debug_info) {
	{
		ir_fprintf(f, "\n");

		i32 diec = m->debug_info.entries.count;

		ir_fprintf(f, "!llvm.dbg.cu = !{!0}\n");
		ir_fprintf(f, "!llvm.ident = !{!%d}\n", diec+3);
		ir_fprintf(f, "!%d = !{i32 2, !\"Dwarf Version\", i32 4}\n", diec+0);
		ir_fprintf(f, "!%d = !{i32 2, !\"Debug Info Version\", i32 3}\n", diec+1);
		ir_fprintf(f, "!%d = !{i32 1, !\"PIC Level\", i32 2}\n", diec+2);
		ir_fprintf(f, "!%d = !{!\"clang version 3.9.0 (branches/release_39)\"}\n", diec+3);

		for_array(di_index, m->debug_info.entries) {
			MapIrDebugInfoEntry *entry = &m->debug_info.entries.e[di_index];
			irDebugInfo *di = entry->value;
			ir_fprintf(f, "!%d = ", di->id);

			switch (di->kind) {
			case irDebugInfo_CompileUnit: {
				irDebugInfo *file = *map_ir_debug_info_get(&m->debug_info, hash_pointer(di->CompileUnit.file));
				ir_fprintf(f,
				            "distinct !DICompileUnit("
				            "language: DW_LANG_Go, " // Is this good enough?
				            "file: !%d, "
				            "producer: \"clang version 3.9.0 (branches/release_39)\", "
				            "flags: \"\", "
				            "runtimeVersion: 0, "
				            "isOptimized: false, "
				            "emissionKind: FullDebug"
				            ")",
				            file->id);

			} break;
			case irDebugInfo_File:
				ir_fprintf(f, "!DIFile(filename: \"");
				ir_print_escape_string(f, di->File.filename, false);
				ir_fprintf(f, "\", directory: \"");
				ir_print_escape_string(f, di->File.directory, false);
				ir_fprintf(f, "\")");
				break;
			case irDebugInfo_Proc:
				ir_fprintf(f, "distinct !DISubprogram("
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

			case irDebugInfo_AllProcs:
				ir_fprintf(f, "!{");
				for_array(proc_index, di->AllProcs.procs) {
					irDebugInfo *p = di->AllProcs.procs.e[proc_index];
					if (proc_index > 0) {ir_fprintf(f, ",");}
					ir_fprintf(f, "!%d", p->id);
				}
				ir_fprintf(f, "}");
				break;
			}

			ir_fprintf(f, "\n");
		}
	}
#endif
	ir_file_buffer_destroy(f);
}
