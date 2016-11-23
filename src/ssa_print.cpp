typedef struct ssaFileBuffer {
	gbVirtualMemory vm;
	isize           offset;
	gbFile *        output;
} ssaFileBuffer;

void ssa_file_buffer_init(ssaFileBuffer *f, gbFile *output) {
	isize size = 8*gb_virtual_memory_page_size(NULL);
	f->vm = gb_vm_alloc(NULL, size);
	f->offset = 0;
	f->output = output;
}

void ssa_file_buffer_destroy(ssaFileBuffer *f) {
	if (f->offset > 0) {
		// NOTE(bill): finish writing buffered data
		gb_file_write(f->output, f->vm.data, f->offset);
	}

	gb_vm_free(f->vm);
}

void ssa_file_buffer_write(ssaFileBuffer *f, void *data, isize len) {
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


void ssa_fprintf(ssaFileBuffer *f, char *fmt, ...) {
	va_list va;
	va_start(va, fmt);
	char buf[4096] = {0};
	isize len = gb_snprintf_va(buf, gb_size_of(buf), fmt, va);
	ssa_file_buffer_write(f, buf, len-1);
	va_end(va);
}


void ssa_file_write(ssaFileBuffer *f, void *data, isize len) {
	ssa_file_buffer_write(f, data, len);
}


bool ssa_valid_char(u8 c) {
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

void ssa_print_escape_string(ssaFileBuffer *f, String name, bool print_quotes) {
	isize extra = 0;
	for (isize i = 0; i < name.len; i++) {
		u8 c = name.text[i];
		if (!ssa_valid_char(c)) {
			extra += 2;
		}
	}

	if (extra == 0) {
		ssa_fprintf(f, "%.*s", LIT(name));
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
		if (ssa_valid_char(c)) {
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

	ssa_file_write(f, buf, j);

	gb_temp_arena_memory_end(tmp);
}



void ssa_print_encoded_local(ssaFileBuffer *f, String name) {
	ssa_fprintf(f, "%%");
	ssa_print_escape_string(f, name, true);
}

void ssa_print_encoded_global(ssaFileBuffer *f, String name, bool global_scope) {
	ssa_fprintf(f, "@");
	if (!global_scope && str_ne(name, str_lit("main"))) {
		ssa_fprintf(f, ".");
	}
	ssa_print_escape_string(f, name, true);
}


void ssa_print_type(ssaFileBuffer *f, ssaModule *m, Type *t) {
	BaseTypeSizes s = m->sizes;
	i64 word_bits = 8*s.word_size;
	GB_ASSERT_NOT_NULL(t);
	t = default_type(t);

	switch (t->kind) {
	case Type_Basic:
		switch (t->Basic.kind) {
		case Basic_bool:   ssa_fprintf(f, "i1");                      break;
		case Basic_i8:     ssa_fprintf(f, "i8");                      break;
		case Basic_u8:     ssa_fprintf(f, "i8");                      break;
		case Basic_i16:    ssa_fprintf(f, "i16");                     break;
		case Basic_u16:    ssa_fprintf(f, "i16");                     break;
		case Basic_i32:    ssa_fprintf(f, "i32");                     break;
		case Basic_u32:    ssa_fprintf(f, "i32");                     break;
		case Basic_i64:    ssa_fprintf(f, "i64");                     break;
		case Basic_u64:    ssa_fprintf(f, "i64");                     break;
		case Basic_i128:   ssa_fprintf(f, "i128");                    break;
		case Basic_u128:   ssa_fprintf(f, "i128");                    break;
		// case Basic_f16:    ssa_fprintf(f, "half");                    break;
		case Basic_f32:    ssa_fprintf(f, "float");                   break;
		case Basic_f64:    ssa_fprintf(f, "double");                  break;
		// case Basic_f128:   ssa_fprintf(f, "fp128");                   break;
		case Basic_rawptr: ssa_fprintf(f, "%%..rawptr");              break;
		case Basic_string: ssa_fprintf(f, "%%..string");              break;
		case Basic_uint:   ssa_fprintf(f, "i%lld", word_bits);        break;
		case Basic_int:    ssa_fprintf(f, "i%lld", word_bits);        break;
		case Basic_any:    ssa_fprintf(f, "%%..any");                 break;
		}
		break;
	case Type_Pointer:
		ssa_print_type(f, m, t->Pointer.elem);
		ssa_fprintf(f, "*");
		break;
	case Type_Maybe:
		ssa_fprintf(f, "{");
		ssa_print_type(f, m, t->Maybe.elem);
		ssa_fprintf(f, ", ");
		ssa_print_type(f, m, t_bool);
		ssa_fprintf(f, "}");
		break;
	case Type_Array:
		ssa_fprintf(f, "[%lld x ", t->Array.count);
		ssa_print_type(f, m, t->Array.elem);
		ssa_fprintf(f, "]");
		break;
	case Type_Vector:
		ssa_fprintf(f, "<%lld x ", t->Vector.count);
		ssa_print_type(f, m, t->Vector.elem);
		ssa_fprintf(f, ">");
		break;
	case Type_Slice:
		ssa_fprintf(f, "{");
		ssa_print_type(f, m, t->Slice.elem);
		ssa_fprintf(f, "*, i%lld, i%lld}", word_bits, word_bits);
		break;
	case Type_Record: {
		switch (t->Record.kind) {
		case TypeRecord_Struct:
			if (t->Record.struct_is_packed) {
				ssa_fprintf(f, "<");
			}
			ssa_fprintf(f, "{");
			for (isize i = 0; i < t->Record.field_count; i++) {
				if (i > 0) {
					ssa_fprintf(f, ", ");
				}
				Type *ft = t->Record.fields[i]->type;
				Type *bft = base_type(ft);
				if (!is_type_struct(bft)) {
					ft = bft;
				}
				ssa_print_type(f, m, ft);
			}
			ssa_fprintf(f, "}");
			if (t->Record.struct_is_packed) {
				ssa_fprintf(f, ">");
			}
			break;
		case TypeRecord_Union: {
			// NOTE(bill): The zero size array is used to fix the alignment used in a structure as
			// LLVM takes the first element's alignment as the entire alignment (like C)
			i64 size_of_union  = type_size_of(s, heap_allocator(), t) - s.word_size;
			i64 align_of_union = type_align_of(s, heap_allocator(), t);
			ssa_fprintf(f, "{[0 x <%lld x i8>], [%lld x i8], i%lld}", align_of_union, size_of_union, word_bits);
		} break;
		case TypeRecord_RawUnion: {
			// NOTE(bill): The zero size array is used to fix the alignment used in a structure as
			// LLVM takes the first element's alignment as the entire alignment (like C)
			i64 size_of_union  = type_size_of(s, heap_allocator(), t);
			i64 align_of_union = type_align_of(s, heap_allocator(), t);
			ssa_fprintf(f, "{[0 x <%lld x i8>], [%lld x i8]}", align_of_union, size_of_union);
		} break;
		case TypeRecord_Enum:
			ssa_print_type(f, m, t->Record.enum_base);
			break;
		}
	} break;


	case Type_Named:
		if (is_type_struct(t) || is_type_union(t)) {
			String *name = map_string_get(&m->type_names, hash_pointer(t));
			GB_ASSERT_MSG(name != NULL, "%.*s", LIT(t->Named.name));
			ssa_print_encoded_local(f, *name);
			// ssa_print_encoded_local(f, t->Named.name);
		} else {
			ssa_print_type(f, m, base_type(t));
		}
		break;
	case Type_Tuple:
		if (t->Tuple.variable_count == 1) {
			ssa_print_type(f, m, t->Tuple.variables[0]->type);
		} else {
			ssa_fprintf(f, "{");
			for (isize i = 0; i < t->Tuple.variable_count; i++) {
				if (i > 0) {
					ssa_fprintf(f, ", ");
				}
				ssa_print_type(f, m, t->Tuple.variables[i]->type);
			}
			ssa_fprintf(f, "}");
		}
		break;
	case Type_Proc: {
		if (t->Proc.result_count == 0) {
			ssa_fprintf(f, "void");
		} else {
			ssa_print_type(f, m, t->Proc.results);
		}
		ssa_fprintf(f, " (");
		TypeTuple *params = &t->Proc.params->Tuple;
		for (isize i = 0; i < t->Proc.param_count; i++) {
			if (i > 0) {
				ssa_fprintf(f, ", ");
			}
			ssa_print_type(f, m, params->variables[i]->type);
		}
		ssa_fprintf(f, ")*");
	} break;
	}
}

void ssa_print_exact_value(ssaFileBuffer *f, ssaModule *m, ExactValue value, Type *type);

void ssa_print_compound_element(ssaFileBuffer *f, ssaModule *m, ExactValue v, Type *elem_type) {
	ssa_print_type(f, m, elem_type);
	ssa_fprintf(f, " ");

	if (v.kind != ExactValue_Invalid && is_type_maybe(elem_type)) {
		Type *t = base_type(elem_type)->Maybe.elem;
		ssa_fprintf(f, "{");
		ssa_print_type(f, m, t);
		ssa_fprintf(f, " ");
	}

	if (v.kind == ExactValue_Invalid || base_type(elem_type) == t_any) {
		ssa_fprintf(f, "zeroinitializer");
	} else {
		ssa_print_exact_value(f, m, v, elem_type);
	}

	if (v.kind != ExactValue_Invalid && is_type_maybe(elem_type)) {
		ssa_fprintf(f, ", ");
		ssa_print_type(f, m, t_bool);
		ssa_fprintf(f, " ");
		ssa_fprintf(f, "true}");
	}
}

void ssa_print_exact_value(ssaFileBuffer *f, ssaModule *m, ExactValue value, Type *type) {
	type = base_type(type);
	if (is_type_float(type)) {
		value = exact_value_to_float(value);
	} else if (is_type_integer(type)) {
		value = exact_value_to_integer(value);
	} else if (is_type_pointer(type)) {
		value = exact_value_to_integer(value);
	}

	switch (value.kind) {
	case ExactValue_Bool:
		ssa_fprintf(f, "%s", (value.value_bool ? "true" : "false"));
		break;
	case ExactValue_String: {
		String str = value.value_string;
		if (str.len == 0) {
			ssa_fprintf(f, "zeroinitializer");
			break;
		}
		if (!is_type_string(type)) {
			GB_ASSERT(is_type_array(type));
			ssa_fprintf(f, "c\"");
			ssa_print_escape_string(f, str, false);
			ssa_fprintf(f, "\"");
		} else {
			// HACK NOTE(bill): This is a hack but it works because strings are created at the very end
			// of the .ll file
			ssaValue *str_array = ssa_add_global_string_array(m, str);

			ssa_fprintf(f, "{i8* getelementptr inbounds (");
			ssa_print_type(f, m, str_array->Global.entity->type);
			ssa_fprintf(f, ", ");
			ssa_print_type(f, m, str_array->Global.entity->type);
			ssa_fprintf(f, "* ");
			ssa_print_encoded_global(f, str_array->Global.entity->token.string, false);
			ssa_fprintf(f, ", ");
			ssa_print_type(f, m, t_int);
			ssa_fprintf(f, " 0, i32 0), ");
			ssa_print_type(f, m, t_int);
			ssa_fprintf(f, " %lld}", cast(i64)str.len);
		}
	} break;
	case ExactValue_Integer: {
		if (is_type_pointer(type)) {
			if (value.value_integer == 0) {
				ssa_fprintf(f, "null");
			} else {
				ssa_fprintf(f, "inttoptr (");
				ssa_print_type(f, m, t_int);
				ssa_fprintf(f, " %llu to ", value.value_integer);
				ssa_print_type(f, m, t_rawptr);
				ssa_fprintf(f, ")");
			}
		} else {
			ssa_fprintf(f, "%lld", value.value_integer);
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
			// 64 bit mantissa: 52 bits
			// 32 bit mantissa: 23 bits
			// 29 == 52-23
			u >>= 29;
			u <<= 29;
			break;
		}

		switch (type->Basic.kind) {
		case 0: break;
#if 0
		case Basic_f16:
			ssa_fprintf(f, "bitcast (");
			ssa_print_type(f, m, t_u16);
			ssa_fprintf(f, " %u to ", cast(u16)f32_to_f16(cast(f32)value.value_float));
			ssa_print_type(f, m, t_f16);
			ssa_fprintf(f, ")");
			break;
		case Basic_f128:
			ssa_fprintf(f, "bitcast (");
			ssa_fprintf(f, "i128");
			// TODO(bill): Actually support f128
			ssa_fprintf(f, " %llu to ", u);
			ssa_print_type(f, m, t_f128);
			ssa_fprintf(f, ")");
			break;
#endif
		default:
			ssa_fprintf(f, "0x%016llx", u);
			break;
		}
	} break;
	case ExactValue_Pointer:
		if (value.value_pointer == 0) {
			ssa_fprintf(f, "null");
		} else {
			ssa_fprintf(f, "inttoptr (");
			ssa_print_type(f, m, t_int);
			ssa_fprintf(f, " %llu to ", cast(u64)cast(uintptr)value.value_pointer);
			ssa_print_type(f, m, t_rawptr);
			ssa_fprintf(f, ")");
		}
		break;

	case ExactValue_Compound: {
		type = base_type(type);
		if (is_type_array(type)) {
			ast_node(cl, CompoundLit, value.value_compound);
			isize elem_count = cl->elems.count;
			if (elem_count == 0) {
				ssa_fprintf(f, "zeroinitializer");
				break;
			}

			ssa_fprintf(f, "[");
			Type *elem_type = type->Array.elem;

			for (isize i = 0; i < elem_count; i++) {
				if (i > 0) {
					ssa_fprintf(f, ", ");
				}
				TypeAndValue *tav = type_and_value_of_expression(m->info, cl->elems.e[i]);
				GB_ASSERT(tav != NULL);
				ssa_print_compound_element(f, m, tav->value, elem_type);
			}
			for (isize i = elem_count; i < type->Array.count; i++) {
				if (i >= elem_count) {
					ssa_fprintf(f, ", ");
				}
				ssa_print_type(f, m, elem_type);
				ssa_fprintf(f, " zeroinitializer");
			}

			ssa_fprintf(f, "]");
		} else if (is_type_vector(type)) {
			ast_node(cl, CompoundLit, value.value_compound);
			isize elem_count = cl->elems.count;
			if (elem_count == 0) {
				ssa_fprintf(f, "zeroinitializer");
				break;
			}

			ssa_fprintf(f, "<");
			Type *elem_type = type->Vector.elem;

			if (elem_count == 1 && type->Vector.count > 1) {
				TypeAndValue *tav = type_and_value_of_expression(m->info, cl->elems.e[0]);
				GB_ASSERT(tav != NULL);

				for (isize i = 0; i < type->Vector.count; i++) {
					if (i > 0) {
						ssa_fprintf(f, ", ");
					}
					ssa_print_compound_element(f, m, tav->value, elem_type);
				}
			} else {
				for (isize i = 0; i < elem_count; i++) {
					if (i > 0) {
						ssa_fprintf(f, ", ");
					}
					TypeAndValue *tav = type_and_value_of_expression(m->info, cl->elems.e[i]);
					GB_ASSERT(tav != NULL);
					ssa_print_compound_element(f, m, tav->value, elem_type);
				}
			}

			ssa_fprintf(f, ">");
		} else if (is_type_struct(type)) {
			gbTempArenaMemory tmp = gb_temp_arena_memory_begin(&m->tmp_arena);

			ast_node(cl, CompoundLit, value.value_compound);

			if (cl->elems.count == 0) {
				ssa_fprintf(f, "zeroinitializer");
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
				ssa_fprintf(f, "<");
			}
			ssa_fprintf(f, "{");


			for (isize i = 0; i < value_count; i++) {
				if (i > 0) {
					ssa_fprintf(f, ", ");
				}
				Type *elem_type = type->Record.fields[i]->type;

				ssa_print_compound_element(f, m, values[i], elem_type);
			}


			ssa_fprintf(f, "}");
			if (type->Record.struct_is_packed) {
				ssa_fprintf(f, ">");
			}

			gb_temp_arena_memory_end(tmp);
		} else {
			ssa_fprintf(f, "zeroinitializer");
		}

	} break;

	default:
		ssa_fprintf(f, "zeroinitializer");
		// GB_PANIC("Invalid ExactValue: %d", value.kind);
		break;
	}
}

void ssa_print_block_name(ssaFileBuffer *f, ssaBlock *b) {
	if (b != NULL) {
		ssa_print_escape_string(f, b->label, false);
		ssa_fprintf(f, "-%td", b->index);
	} else {
		ssa_fprintf(f, "<INVALID-BLOCK>");
	}
}

void ssa_print_value(ssaFileBuffer *f, ssaModule *m, ssaValue *value, Type *type_hint) {
	if (value == NULL) {
		ssa_fprintf(f, "!!!NULL_VALUE");
		return;
	}
	switch (value->kind) {
	default: GB_PANIC("Unknown ssaValue kind"); break;

	case ssaValue_Constant:
		ssa_print_exact_value(f, m, value->Constant.value, type_hint);
		break;

	case ssaValue_ConstantSlice: {
		ssaValueConstantSlice *cs = &value->ConstantSlice;
		if (cs->backing_array == NULL || cs->count == 0) {
			ssa_fprintf(f, "zeroinitializer");
		} else {
			Type *at = base_type(type_deref(ssa_type(cs->backing_array)));
			Type *et = at->Array.elem;
			ssa_fprintf(f, "{");
			ssa_print_type(f, m, et);
			ssa_fprintf(f, "* getelementptr inbounds (");
			ssa_print_type(f, m, at);
			ssa_fprintf(f, ", ");
			ssa_print_type(f, m, at);
			ssa_fprintf(f, "* ");
			ssa_print_value(f, m, cs->backing_array, at);
			ssa_fprintf(f, ", ");
			ssa_print_type(f, m, t_int);
			ssa_fprintf(f, " 0, i32 0), ");
			ssa_print_type(f, m, t_int);
			ssa_fprintf(f, " %lld, ", cs->count);
			ssa_print_type(f, m, t_int);
			ssa_fprintf(f, " %lld}", cs->count);
		}
	} break;

	case ssaValue_Nil:
		ssa_fprintf(f, "zeroinitializer");
		break;

	case ssaValue_TypeName:
		ssa_print_encoded_local(f, value->TypeName.name);
		break;
	case ssaValue_Global: {
		Scope *scope = value->Global.entity->scope;
		bool in_global_scope = false;
		if (scope != NULL) {
			in_global_scope = scope->is_global || scope->is_init;
		}
		ssa_print_encoded_global(f, value->Global.entity->token.string, in_global_scope);
	} break;
	case ssaValue_Param:
		ssa_print_encoded_local(f, value->Param.entity->token.string);
		break;
	case ssaValue_Proc:
		ssa_print_encoded_global(f, value->Proc.name, (value->Proc.tags & (ProcTag_foreign|ProcTag_link_name)) != 0);
		break;
	case ssaValue_Instr:
		ssa_fprintf(f, "%%%d", value->index);
		break;
	}
}

void ssa_print_instr(ssaFileBuffer *f, ssaModule *m, ssaValue *value) {
	GB_ASSERT(value->kind == ssaValue_Instr);
	ssaInstr *instr = &value->Instr;

	ssa_fprintf(f, "\t");

	switch (instr->kind) {
	case ssaInstr_StartupRuntime: {
		ssa_fprintf(f, "call void ");
		ssa_print_encoded_global(f, str_lit(SSA_STARTUP_RUNTIME_PROC_NAME), false);
		ssa_fprintf(f, "()\n");
	} break;

	case ssaInstr_Comment:
		ssa_fprintf(f, "; %.*s\n", LIT(instr->Comment.text));
		break;

	case ssaInstr_Local: {
		Type *type = instr->Local.entity->type;
		ssa_fprintf(f, "%%%d = alloca ", value->index);
		ssa_print_type(f, m, type);
		ssa_fprintf(f, ", align %lld\n", type_align_of(m->sizes, m->allocator, type));
	} break;

	case ssaInstr_ZeroInit: {
		Type *type = type_deref(ssa_type(instr->ZeroInit.address));
		ssa_fprintf(f, "store ");
		ssa_print_type(f, m, type);
		ssa_fprintf(f, " zeroinitializer, ");
		ssa_print_type(f, m, type);
		ssa_fprintf(f, "* %%%d\n", instr->ZeroInit.address->index);
	} break;

	case ssaInstr_Store: {
		Type *type = ssa_type(instr->Store.value);
		ssa_fprintf(f, "store ");
		ssa_print_type(f, m, type);
		ssa_fprintf(f, " ");
		ssa_print_value(f, m, instr->Store.value, type);
		ssa_fprintf(f, ", ");
		ssa_print_type(f, m, type);
		ssa_fprintf(f, "* ");
		ssa_print_value(f, m, instr->Store.address, type);
		ssa_fprintf(f, "\n");
	} break;

	case ssaInstr_Load: {
		Type *type = instr->Load.type;
		ssa_fprintf(f, "%%%d = load ", value->index);
		ssa_print_type(f, m, type);
		ssa_fprintf(f, ", ");
		ssa_print_type(f, m, type);
		ssa_fprintf(f, "* ");
		ssa_print_value(f, m, instr->Load.address, type);
		ssa_fprintf(f, ", align %lld\n", type_align_of(m->sizes, m->allocator, type));
	} break;

	case ssaInstr_ArrayElementPtr: {
		Type *et = ssa_type(instr->ArrayElementPtr.address);
		ssa_fprintf(f, "%%%d = getelementptr inbounds ", value->index);

		ssa_print_type(f, m, type_deref(et));
		ssa_fprintf(f, ", ");
		ssa_print_type(f, m, et);
		ssa_fprintf(f, " ");
		ssa_print_value(f, m, instr->ArrayElementPtr.address, et);
		ssa_fprintf(f, ", ");
		ssa_print_type(f, m, t_int);
		ssa_fprintf(f, " 0, ");

		ssaValue *index =instr->ArrayElementPtr.elem_index;
		Type *t = ssa_type(index);
		ssa_print_type(f, m, t);
		ssa_fprintf(f, " ");
		ssa_print_value(f, m, index, t);
		ssa_fprintf(f, "\n");
	} break;

	case ssaInstr_StructElementPtr: {
		Type *et = ssa_type(instr->StructElementPtr.address);
		ssa_fprintf(f, "%%%d = getelementptr inbounds ", value->index);

		ssa_print_type(f, m, type_deref(et));
		ssa_fprintf(f, ", ");
		ssa_print_type(f, m, et);
		ssa_fprintf(f, " ");
		ssa_print_value(f, m, instr->StructElementPtr.address, et);
		ssa_fprintf(f, ", ");
		ssa_print_type(f, m, t_int);
		ssa_fprintf(f, " 0, ");
		ssa_print_type(f, m, t_i32);
		ssa_fprintf(f, " %d", instr->StructElementPtr.elem_index);
		ssa_fprintf(f, "\n");
	} break;

	case ssaInstr_PtrOffset: {
		Type *pt = ssa_type(instr->PtrOffset.address);
		ssa_fprintf(f, "%%%d = getelementptr inbounds ", value->index);
		ssa_print_type(f, m, type_deref(pt));
		ssa_fprintf(f, ", ");
		ssa_print_type(f, m, pt);
		ssa_fprintf(f, " ");
		ssa_print_value(f, m, instr->PtrOffset.address, pt);

		ssaValue *offset = instr->PtrOffset.offset;
		Type *t = ssa_type(offset);
		ssa_fprintf(f, ", ");
		ssa_print_type(f, m, t);
		ssa_fprintf(f, " ");
		ssa_print_value(f, m, offset, t);
		ssa_fprintf(f, "\n");
	} break;

	case ssaInstr_Phi: {
		ssa_fprintf(f, "%%%d = phi ", value->index);
		ssa_print_type(f, m, instr->Phi.type);
		ssa_fprintf(f, " ", value->index);

		for (isize i = 0; i < instr->Phi.edges.count; i++) {
			if (i > 0) {
				ssa_fprintf(f, ", ");
			}

			ssaValue *edge = instr->Phi.edges.e[i];
			ssaBlock *block = NULL;
			if (instr->parent != NULL &&
			    i < instr->parent->preds.count) {
				block = instr->parent->preds.e[i];
			}

			ssa_fprintf(f, "[ ");
			ssa_print_value(f, m, edge, instr->Phi.type);
			ssa_fprintf(f, ", %%");
			ssa_print_block_name(f, block);
			ssa_fprintf(f, " ]");
		}
		ssa_fprintf(f, "\n");
	} break;

	case ssaInstr_ArrayExtractValue: {
		Type *et = ssa_type(instr->ArrayExtractValue.address);
		ssa_fprintf(f, "%%%d = extractvalue ", value->index);

		ssa_print_type(f, m, et);
		ssa_fprintf(f, " ");
		ssa_print_value(f, m, instr->ArrayExtractValue.address, et);
		ssa_fprintf(f, ", %d\n", instr->ArrayExtractValue.index);
	} break;

	case ssaInstr_StructExtractValue: {
		Type *et = ssa_type(instr->StructExtractValue.address);
		ssa_fprintf(f, "%%%d = extractvalue ", value->index);

		ssa_print_type(f, m, et);
		ssa_fprintf(f, " ");
		ssa_print_value(f, m, instr->StructExtractValue.address, et);
		ssa_fprintf(f, ", %d\n", instr->StructExtractValue.index);
	} break;

	case ssaInstr_UnionTagPtr: {
		Type *et = ssa_type(instr->UnionTagPtr.address);
		ssa_fprintf(f, "%%%d = getelementptr inbounds ", value->index);

		ssa_print_type(f, m, type_deref(et));
		ssa_fprintf(f, ", ");
		ssa_print_type(f, m, et);
		ssa_fprintf(f, " ");
		ssa_print_value(f, m, instr->UnionTagPtr.address, et);
		ssa_fprintf(f, ", ");
		ssa_print_type(f, m, t_int);
		ssa_fprintf(f, " 0, ");
		ssa_print_type(f, m, t_i32);
		ssa_fprintf(f, " %d", 2);
		ssa_fprintf(f, "\n");
	} break;

	case ssaInstr_UnionTagValue: {
		Type *et = ssa_type(instr->UnionTagValue.address);
		ssa_fprintf(f, "%%%d = extractvalue ", value->index);

		ssa_print_type(f, m, et);
		ssa_fprintf(f, " ");
		ssa_print_value(f, m, instr->UnionTagValue.address, et);
		ssa_fprintf(f, ", %d\n", 2);
	} break;

	case ssaInstr_Jump: {;
		ssa_fprintf(f, "br label %%");
		ssa_print_block_name(f, instr->Jump.block);
		ssa_fprintf(f, "\n");
	} break;

	case ssaInstr_If: {;
		ssa_fprintf(f, "br ");
		ssa_print_type(f, m, t_bool);
		ssa_fprintf(f, " ");
		ssa_print_value(f, m, instr->If.cond, t_bool);
		ssa_fprintf(f, ", ", instr->If.cond->index);
		ssa_fprintf(f, "label %%");   ssa_print_block_name(f, instr->If.true_block);
		ssa_fprintf(f, ", label %%"); ssa_print_block_name(f, instr->If.false_block);
		ssa_fprintf(f, "\n");
	} break;

	case ssaInstr_Return: {
		ssaInstrReturn *ret = &instr->Return;
		ssa_fprintf(f, "ret ");
		if (ret->value == NULL) {
			ssa_fprintf(f, "void");
		} else {
			Type *t = ssa_type(ret->value);
			ssa_print_type(f, m, t);
			ssa_fprintf(f, " ");
			ssa_print_value(f, m, ret->value, t);
		}

		ssa_fprintf(f, "\n");

	} break;

	case ssaInstr_Conv: {
		ssaInstrConv *c = &instr->Conv;
		ssa_fprintf(f, "%%%d = %.*s ", value->index, LIT(ssa_conv_strings[c->kind]));
		ssa_print_type(f, m, c->from);
		ssa_fprintf(f, " ");
		ssa_print_value(f, m, c->value, c->from);
		ssa_fprintf(f, " to ");
		ssa_print_type(f, m, c->to);
		ssa_fprintf(f, "\n");

	} break;

	case ssaInstr_Unreachable: {
		ssa_fprintf(f, "unreachable\n");
	} break;

	case ssaInstr_BinaryOp: {
		ssaInstrBinaryOp *bo = &value->Instr.BinaryOp;
		Type *type = base_type(ssa_type(bo->left));
		Type *elem_type = type;
		while (elem_type->kind == Type_Vector) {
			elem_type = base_type(elem_type->Vector.elem);
		}

		ssa_fprintf(f, "%%%d = ", value->index);

		if (gb_is_between(bo->op, Token__ComparisonBegin+1, Token__ComparisonEnd-1)) {
			if (is_type_string(elem_type)) {
				ssa_fprintf(f, "call ");
				ssa_print_type(f, m, t_bool);
				char *runtime_proc = "";
				switch (bo->op) {
				case Token_CmpEq: runtime_proc = "__string_eq"; break;
				case Token_NotEq: runtime_proc = "__string_ne"; break;
				case Token_Lt:    runtime_proc = "__string_lt"; break;
				case Token_Gt:    runtime_proc = "__string_gt"; break;
				case Token_LtEq:  runtime_proc = "__string_le"; break;
				case Token_GtEq:  runtime_proc = "__string_gt"; break;
				}

				ssa_fprintf(f, " ");
				ssa_print_encoded_global(f, make_string_c(runtime_proc), false);
				ssa_fprintf(f, "(");
				ssa_print_type(f, m, type);
				ssa_fprintf(f, " ");
				ssa_print_value(f, m, bo->left, type);
				ssa_fprintf(f, ", ");
				ssa_print_type(f, m, type);
				ssa_fprintf(f, " ");
				ssa_print_value(f, m, bo->right, type);
				ssa_fprintf(f, ")\n");
				return;

			} else if (is_type_float(elem_type)) {
				ssa_fprintf(f, "fcmp ");
				switch (bo->op) {
				case Token_CmpEq: ssa_fprintf(f, "oeq"); break;
				case Token_NotEq: ssa_fprintf(f, "one"); break;
				case Token_Lt:    ssa_fprintf(f, "olt"); break;
				case Token_Gt:    ssa_fprintf(f, "ogt"); break;
				case Token_LtEq:  ssa_fprintf(f, "ole"); break;
				case Token_GtEq:  ssa_fprintf(f, "oge"); break;
				}
			} else {
				ssa_fprintf(f, "icmp ");
				if (bo->op != Token_CmpEq &&
				    bo->op != Token_NotEq) {
					if (is_type_unsigned(elem_type)) {
						ssa_fprintf(f, "u");
					} else {
						ssa_fprintf(f, "s");
					}
				}
				switch (bo->op) {
				case Token_CmpEq: ssa_fprintf(f, "eq"); break;
				case Token_NotEq: ssa_fprintf(f, "ne"); break;
				case Token_Lt:    ssa_fprintf(f, "lt"); break;
				case Token_Gt:    ssa_fprintf(f, "gt"); break;
				case Token_LtEq:  ssa_fprintf(f, "le"); break;
				case Token_GtEq:  ssa_fprintf(f, "ge"); break;
				}
			}
		} else {
			if (is_type_float(elem_type)) {
				ssa_fprintf(f, "f");
			}

			switch (bo->op) {
			case Token_Add:    ssa_fprintf(f, "add");  break;
			case Token_Sub:    ssa_fprintf(f, "sub");  break;
			case Token_And:    ssa_fprintf(f, "and");  break;
			case Token_Or:     ssa_fprintf(f, "or");   break;
			case Token_Xor:    ssa_fprintf(f, "xor");  break;
			case Token_Shl:    ssa_fprintf(f, "shl");  break;
			case Token_Shr:    ssa_fprintf(f, "lshr"); break;
			case Token_Mul:    ssa_fprintf(f, "mul");  break;
			case Token_Not:    ssa_fprintf(f, "xor");  break;

			case Token_AndNot: GB_PANIC("Token_AndNot Should never be called");

			default: {
				if (!is_type_float(elem_type)) {
					if (is_type_unsigned(elem_type)) ssa_fprintf(f, "u");
					else                             ssa_fprintf(f, "s");
				}

				switch (bo->op) {
				case Token_Quo: ssa_fprintf(f, "div"); break;
				case Token_Mod: ssa_fprintf(f, "rem"); break;
				}
			} break;
			}
		}

		ssa_fprintf(f, " ");
		ssa_print_type(f, m, type);
		ssa_fprintf(f, " ");
		ssa_print_value(f, m, bo->left, type);
		ssa_fprintf(f, ", ");
		ssa_print_value(f, m, bo->right, type);
		ssa_fprintf(f, "\n");

	} break;

	case ssaInstr_Call: {
		ssaInstrCall *call = &instr->Call;
		Type *result_type = call->type;
		if (result_type) {
			ssa_fprintf(f, "%%%d = ", value->index);
		}
		ssa_fprintf(f, "call ");
		if (result_type) {
			ssa_print_type(f, m, result_type);
		} else {
			ssa_fprintf(f, "void");
		}
		ssa_fprintf(f, " ");
		ssa_print_value(f, m, call->value, call->type);


		ssa_fprintf(f, "(");
		if (call->arg_count > 0) {
			Type *proc_type = base_type(ssa_type(call->value));
			GB_ASSERT(proc_type->kind == Type_Proc);
			TypeTuple *params = &proc_type->Proc.params->Tuple;
			for (isize i = 0; i < call->arg_count; i++) {
				Entity *e = params->variables[i];
				GB_ASSERT(e != NULL);
				Type *t = e->type;
				if (i > 0) {
					ssa_fprintf(f, ", ");
				}
				ssa_print_type(f, m, t);
				ssa_fprintf(f, " ");
				ssaValue *arg = call->args[i];
				ssa_print_value(f, m, arg, t);
			}
		}
		ssa_fprintf(f, ")\n");

	} break;

	case ssaInstr_Select: {
		ssa_fprintf(f, "%%%d = select i1 ", value->index);
		ssa_print_value(f, m, instr->Select.cond, t_bool);
		ssa_fprintf(f, ", ");
		ssa_print_type(f, m, ssa_type(instr->Select.true_value));
		ssa_fprintf(f, " ");
		ssa_print_value(f, m, instr->Select.true_value, ssa_type(instr->Select.true_value));
		ssa_fprintf(f, ", ");
		ssa_print_type(f, m, ssa_type(instr->Select.false_value));
		ssa_fprintf(f, " ");
		ssa_print_value(f, m, instr->Select.false_value, ssa_type(instr->Select.false_value));
		ssa_fprintf(f, "\n");
	} break;

	case ssaInstr_VectorExtractElement: {
		Type *vt = ssa_type(instr->VectorExtractElement.vector);
		Type *it = ssa_type(instr->VectorExtractElement.index);
		ssa_fprintf(f, "%%%d = extractelement ", value->index);

		ssa_print_type(f, m, vt);
		ssa_fprintf(f, " ");
		ssa_print_value(f, m, instr->VectorExtractElement.vector, vt);
		ssa_fprintf(f, ", ");
		ssa_print_type(f, m, it);
		ssa_fprintf(f, " ");
		ssa_print_value(f, m, instr->VectorExtractElement.index, it);
		ssa_fprintf(f, "\n");
	} break;

	case ssaInstr_VectorInsertElement: {
		ssaInstrVectorInsertElement *ie = &instr->VectorInsertElement;
		Type *vt = ssa_type(ie->vector);
		ssa_fprintf(f, "%%%d = insertelement ", value->index);

		ssa_print_type(f, m, vt);
		ssa_fprintf(f, " ");
		ssa_print_value(f, m, ie->vector, vt);
		ssa_fprintf(f, ", ");

		ssa_print_type(f, m, ssa_type(ie->elem));
		ssa_fprintf(f, " ");
		ssa_print_value(f, m, ie->elem, ssa_type(ie->elem));
		ssa_fprintf(f, ", ");

		ssa_print_type(f, m, ssa_type(ie->index));
		ssa_fprintf(f, " ");
		ssa_print_value(f, m, ie->index, ssa_type(ie->index));

		ssa_fprintf(f, "\n");
	} break;

	case ssaInstr_VectorShuffle: {
		ssaInstrVectorShuffle *sv = &instr->VectorShuffle;
		Type *vt = ssa_type(sv->vector);
		ssa_fprintf(f, "%%%d = shufflevector ", value->index);

		ssa_print_type(f, m, vt);
		ssa_fprintf(f, " ");
		ssa_print_value(f, m, sv->vector, vt);
		ssa_fprintf(f, ", ");

		ssa_print_type(f, m, vt);
		ssa_fprintf(f, " ");
		ssa_print_value(f, m, sv->vector, vt);
		ssa_fprintf(f, ", ");

		ssa_fprintf(f, "<%td x i32> <", sv->index_count);
		for (isize i = 0; i < sv->index_count; i++) {
			if (i > 0) {
				ssa_fprintf(f, ", ");
			}
			ssa_fprintf(f, "i32 %d", sv->indices[i]);
		}
		ssa_fprintf(f, ">");
		ssa_fprintf(f, "\n");
	} break;

	case ssaInstr_BoundsCheck: {
		ssaInstrBoundsCheck *bc = &instr->BoundsCheck;
		ssa_fprintf(f, "call void ");
		ssa_print_encoded_global(f, str_lit("__bounds_check_error"), false);
		ssa_fprintf(f, "(");
		ssa_print_compound_element(f, m, make_exact_value_string(bc->pos.file), t_string);
		ssa_fprintf(f, ", ");

		ssa_print_type(f, m, t_int);
		ssa_fprintf(f, " ");
		ssa_print_exact_value(f, m, make_exact_value_integer(bc->pos.line), t_int);
		ssa_fprintf(f, ", ");

		ssa_print_type(f, m, t_int);
		ssa_fprintf(f, " ");
		ssa_print_exact_value(f, m, make_exact_value_integer(bc->pos.column), t_int);
		ssa_fprintf(f, ", ");

		ssa_print_type(f, m, t_int);
		ssa_fprintf(f, " ");
		ssa_print_value(f, m, bc->index, t_int);
		ssa_fprintf(f, ", ");

		ssa_print_type(f, m, t_int);
		ssa_fprintf(f, " ");
		ssa_print_value(f, m, bc->len, t_int);

		ssa_fprintf(f, ")\n");
	} break;

	case ssaInstr_SliceBoundsCheck: {
		ssaInstrSliceBoundsCheck *bc = &instr->SliceBoundsCheck;
		ssa_fprintf(f, "call void ");
		if (bc->is_substring) {
			ssa_print_encoded_global(f, str_lit("__substring_expr_error"), false);
		} else {
			ssa_print_encoded_global(f, str_lit("__slice_expr_error"), false);
		}

		ssa_fprintf(f, "(");
		ssa_print_compound_element(f, m, make_exact_value_string(bc->pos.file), t_string);
		ssa_fprintf(f, ", ");

		ssa_print_type(f, m, t_int);
		ssa_fprintf(f, " ");
		ssa_print_exact_value(f, m, make_exact_value_integer(bc->pos.line), t_int);
		ssa_fprintf(f, ", ");

		ssa_print_type(f, m, t_int);
		ssa_fprintf(f, " ");
		ssa_print_exact_value(f, m, make_exact_value_integer(bc->pos.column), t_int);
		ssa_fprintf(f, ", ");

		ssa_print_type(f, m, t_int);
		ssa_fprintf(f, " ");
		ssa_print_value(f, m, bc->low, t_int);
		ssa_fprintf(f, ", ");

		ssa_print_type(f, m, t_int);
		ssa_fprintf(f, " ");
		ssa_print_value(f, m, bc->high, t_int);

		if (!bc->is_substring) {
			ssa_fprintf(f, ", ");
			ssa_print_type(f, m, t_int);
			ssa_fprintf(f, " ");
			ssa_print_value(f, m, bc->max, t_int);
		}

		ssa_fprintf(f, ")\n");
	} break;


	default: {
		GB_PANIC("<unknown instr> %d\n", instr->kind);
		ssa_fprintf(f, "; <unknown instr> %d\n", instr->kind);
	} break;
	}
}

void ssa_print_proc(ssaFileBuffer *f, ssaModule *m, ssaProcedure *proc) {
	if (proc->body == NULL) {
		ssa_fprintf(f, "declare ");
		if (proc->tags & ProcTag_dll_import) {
			ssa_fprintf(f, "dllimport ");
		}
		if (proc->tags & ProcTag_dll_export) {
			ssa_fprintf(f, "dllexport ");
		}
	} else {
		ssa_fprintf(f, "\ndefine ");
	}

	if (proc->tags & ProcTag_stdcall) {
		ssa_fprintf(f, "cc 64 ");
	} else if (proc->tags & ProcTag_fastcall) {
		ssa_fprintf(f, "cc 65 ");
	}

	TypeProc *proc_type = &proc->type->Proc;

	if (proc_type->result_count == 0) {
		ssa_fprintf(f, "void");
	} else {
		ssa_print_type(f, m, proc_type->results);
	}

	ssa_fprintf(f, " ");
	ssa_print_encoded_global(f, proc->name, (proc->tags & (ProcTag_foreign|ProcTag_link_name)) != 0);
	ssa_fprintf(f, "(");

	if (proc_type->param_count > 0) {
		TypeTuple *params = &proc_type->params->Tuple;
		for (isize i = 0; i < params->variable_count; i++) {
			Entity *e = params->variables[i];
			if (i > 0) {
				ssa_fprintf(f, ", ");
			}
			ssa_print_type(f, m, e->type);
			if (proc->body != NULL) {
				ssa_fprintf(f, " %%%.*s", LIT(e->token.string));
			}
		}
	}

	ssa_fprintf(f, ") ");

	if (proc->tags & ProcTag_inline) {
		ssa_fprintf(f, "alwaysinline ");
	}
	if (proc->tags & ProcTag_no_inline) {
		ssa_fprintf(f, "noinline ");
	}


	if (proc->module->generate_debug_info && proc->entity != NULL) {
		if (proc->body != NULL) {
			ssaDebugInfo *di = *map_ssa_debug_info_get(&proc->module->debug_info, hash_pointer(proc->entity));
			GB_ASSERT(di->kind == ssaDebugInfo_Proc);
			ssa_fprintf(f, "!dbg !%d ", di->id);
		}
	}


	if (proc->body != NULL) {
		// ssa_fprintf(f, "nounwind uwtable {\n");

		ssa_fprintf(f, "{\n");
		for_array(i, proc->blocks) {
			ssaBlock *block = proc->blocks.e[i];

			if (i > 0) ssa_fprintf(f, "\n");
			ssa_print_block_name(f, block);
			ssa_fprintf(f, ":\n");

			for_array(j, block->instrs) {
				ssaValue *value = block->instrs.e[j];
				ssa_print_instr(f, m, value);
			}
		}
		ssa_fprintf(f, "}\n");
	} else {
		ssa_fprintf(f, "\n");
	}

	for_array(i, proc->children) {
		ssa_print_proc(f, m, proc->children.e[i]);
	}
}

void ssa_print_type_name(ssaFileBuffer *f, ssaModule *m, ssaValue *v) {
	GB_ASSERT(v->kind == ssaValue_TypeName);
	Type *bt = base_type(ssa_type(v));
	if (!is_type_struct(bt) && !is_type_union(bt)) {
		return;
	}
	ssa_print_encoded_local(f, v->TypeName.name);
	ssa_fprintf(f, " = type ");
	ssa_print_type(f, m, base_type(v->TypeName.type));
	ssa_fprintf(f, "\n");
}

void ssa_print_llvm_ir(ssaGen *ssa) {
	ssaModule *m = &ssa->module;
	ssaFileBuffer buf = {0}, *f = &buf;
	ssa_file_buffer_init(f, &ssa->output_file);

	if (m->layout.len > 0) {
		ssa_fprintf(f, "target datalayout = \"%.*s\"\n", LIT(m->layout));
	}

	ssa_print_encoded_local(f, str_lit("..string"));
	ssa_fprintf(f, " = type {i8*, ");
	ssa_print_type(f, m, t_int);
	ssa_fprintf(f, "} ; Basic_string\n");
	ssa_print_encoded_local(f, str_lit("..rawptr"));
	ssa_fprintf(f, " = type i8* ; Basic_rawptr\n");

	ssa_print_encoded_local(f, str_lit("..any"));
	ssa_fprintf(f, " = type {");
	ssa_print_type(f, m, t_type_info_ptr);
	ssa_fprintf(f, ", ");
	ssa_print_type(f, m, t_rawptr);
	ssa_fprintf(f, "} ; Basic_any\n");


	for_array(member_index, m->members.entries) {
		MapSsaValueEntry *entry = &m->members.entries.e[member_index];
		ssaValue *v = entry->value;
		if (v->kind != ssaValue_TypeName) {
			continue;
		}
		ssa_print_type_name(f, m, v);
	}

	ssa_fprintf(f, "\n");

	for_array(member_index, m->members.entries) {
		MapSsaValueEntry *entry = &m->members.entries.e[member_index];
		ssaValue *v = entry->value;
		if (v->kind != ssaValue_Proc) {
			continue;
		}
		if (v->Proc.body == NULL) {
			ssa_print_proc(f, m, &v->Proc);
		}
	}

	for_array(member_index, m->members.entries) {
		MapSsaValueEntry *entry = &m->members.entries.e[member_index];
		ssaValue *v = entry->value;
		if (v->kind != ssaValue_Proc) {
			continue;
		}
		if (v->Proc.body != NULL) {
			ssa_print_proc(f, m, &v->Proc);
		}
	}


	for_array(member_index, m->members.entries) {
		MapSsaValueEntry *entry = &m->members.entries.e[member_index];
		ssaValue *v = entry->value;
		if (v->kind != ssaValue_Global) {
			continue;
		}
		ssaValueGlobal *g = &v->Global;
		Scope *scope = g->entity->scope;
		bool in_global_scope = false;
		if (scope != NULL) {
			in_global_scope = scope->is_global || scope->is_init;
		}
		ssa_print_encoded_global(f, g->entity->token.string, in_global_scope);
		ssa_fprintf(f, " = ");
		if (g->is_thread_local) {
			ssa_fprintf(f, "thread_local ");
		}

		if (g->is_private) {
			ssa_fprintf(f, "private ");
		}
		if (g->is_constant) {
			if (g->is_unnamed_addr) {
				ssa_fprintf(f, "unnamed_addr ");
			}
			ssa_fprintf(f, "constant ");
		} else {
			ssa_fprintf(f, "global ");
		}


		ssa_print_type(f, m, g->entity->type);
		ssa_fprintf(f, " ");
		if (g->value != NULL) {
			ssa_print_value(f, m, g->value, g->entity->type);
		} else {
			ssa_fprintf(f, "zeroinitializer");
		}
		ssa_fprintf(f, "\n");
	}


#if 0
	if (m->generate_debug_info) {
		ssa_fprintf(f, "\n");
		ssa_fprintf(f, "!llvm.dbg.cu = !{!0}\n");

		for_array(di_index, m->debug_info.entries) {
			MapSsaDebugInfoEntry *entry = &m->debug_info.entries.e[di_index];
			ssaDebugInfo *di = entry->value;
			ssa_fprintf(f, "!%d = ", di->id);

			switch (di->kind) {
			case ssaDebugInfo_CompileUnit: {
				auto *cu = &di->CompileUnit;
				ssaDebugInfo *file = *map_ssa_debug_info_get(&m->debug_info, hash_pointer(cu->file));
				ssa_fprintf(f,
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
			case ssaDebugInfo_File:
				ssa_fprintf(f, "!DIFile(filename: \"");
				ssa_print_escape_string(f, di->File.filename, false);
				ssa_fprintf(f, "\", directory: \"");
				ssa_print_escape_string(f, di->File.directory, false);
				ssa_fprintf(f, "\")");
				break;
			case ssaDebugInfo_Proc:
				ssa_fprintf(f, "distinct !DISubprogram("
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

			case ssaDebugInfo_AllProcs:
				ssa_fprintf(f, "!{");
				for_array(proc_index, di->AllProcs.procs) {
					ssaDebugInfo *p = di->AllProcs.procs.e[proc_index];
					if (proc_index > 0) {ssa_fprintf(f, ",");}
					ssa_fprintf(f, "!%d", p->id);
				}
				ssa_fprintf(f, "}");
				break;
			}

			ssa_fprintf(f, "\n");
		}
	}
#endif
	ssa_file_buffer_destroy(f);
}
