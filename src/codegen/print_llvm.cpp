struct ssaFileBuffer {
	gbVirtualMemory vm;
	isize offset;
	gbFile *output;
};

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
	gb_memcopy(cursor, data, len);
	f->offset += len;
}


void ssa_fprintf(ssaFileBuffer *f, char *fmt, ...) {
	va_list va;
	va_start(va, fmt);
	char buf[4096] = {};
	isize len = gb_snprintf_va(buf, gb_size_of(buf), fmt, va);
	ssa_file_buffer_write(f, buf, len-1);
	va_end(va);
}


void ssa_file_write(ssaFileBuffer *f, void *data, isize len) {
	ssa_file_buffer_write(f, data, len);
}

b32 ssa_valid_char(u8 c) {
	if (c >= 0x80)
		return false;

	if (gb_char_is_alphanumeric(c))
		return true;

	switch (c) {
	case '$':
	case '-':
	case '.':
	case '_':
		return true;
	}

	return false;
}

void ssa_print_escape_string(ssaFileBuffer *f, String name, b32 print_quotes) {
	isize extra = 0;
	for (isize i = 0; i < name.len; i++) {
		u8 c = name.text[i];
		if (!ssa_valid_char(c))
			extra += 2;
	}

	if (extra == 0) {
		ssa_fprintf(f, "%.*s", LIT(name));
		return;
	}


	char hex_table[] = "0123456789ABCDEF";
	isize buf_len = name.len + extra + 2;

	gbTempArenaMemory tmp = gb_temp_arena_memory_begin(&string_buffer_arena);
	defer (gb_temp_arena_memory_end(tmp));

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
}



void ssa_print_encoded_local(ssaFileBuffer *f, String name) {
	ssa_fprintf(f, "%%");
	ssa_print_escape_string(f, name, true);
}

void ssa_print_encoded_global(ssaFileBuffer *f, String name, b32 global_scope) {
	ssa_fprintf(f, "@");
	if (!global_scope && name != make_string("main")) {
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
		case Basic_i16:    ssa_fprintf(f, "i16");                     break;
		case Basic_i32:    ssa_fprintf(f, "i32");                     break;
		case Basic_i64:    ssa_fprintf(f, "i64");                     break;
		// case Basic_i128:   ssa_fprintf(f, "i128");                    break;
		case Basic_u8:     ssa_fprintf(f, "i8");                      break;
		case Basic_u16:    ssa_fprintf(f, "i16");                     break;
		case Basic_u32:    ssa_fprintf(f, "i32");                     break;
		case Basic_u64:    ssa_fprintf(f, "i64");                     break;
		// case Basic_u128:   ssa_fprintf(f, "i128");                    break;
		case Basic_f32:    ssa_fprintf(f, "float");                   break;
		case Basic_f64:    ssa_fprintf(f, "double");                  break;
		case Basic_rawptr: ssa_fprintf(f, "%%..rawptr");              break;
		case Basic_string: ssa_fprintf(f, "%%..string");              break;
		case Basic_uint:   ssa_fprintf(f, "i%lld", word_bits);        break;
		case Basic_int:    ssa_fprintf(f, "i%lld", word_bits);        break;
		case Basic_any:
			ssa_fprintf(f, "{");
			ssa_print_type(f, m, t_type_info_ptr);
			ssa_fprintf(f, ", ");
			ssa_print_type(f, m, t_rawptr);
			ssa_fprintf(f, "}");
			break;
		}
		break;
	case Type_Array:
		ssa_fprintf(f, "[%lld x ", t->Array.count);
		ssa_print_type(f, m, t->Array.elem);
		ssa_fprintf(f, "]");
		break;
	case Type_Vector: {
		// TODO(bill): actually do correctly
		ssa_fprintf(f, "<%lld x ", t->Vector.count);
		ssa_print_type(f, m, t->Vector.elem);
		ssa_fprintf(f, ">");
	} break;
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
			i64 size_of_union = type_size_of(s, gb_heap_allocator(), t) - s.word_size;
			ssa_fprintf(f, "{[%lld x i8], i%lld}", size_of_union, word_bits);
		} break;
		case TypeRecord_RawUnion:
			ssa_fprintf(f, "[%lld x i8]", type_size_of(s, gb_heap_allocator(), t));
			break;
		case TypeRecord_Enum:
			ssa_print_type(f, m, t->Record.enum_base);
			break;
		}
	} break;

	case Type_Pointer:
		ssa_print_type(f, m, t->Pointer.elem);
		ssa_fprintf(f, "*");
		break;
	case Type_Named:
		if (is_type_struct(t) || is_type_union(t)) {
			String *name = map_get(&m->type_names, hash_pointer(t));
			GB_ASSERT(name != NULL);
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
				if (i > 0) ssa_fprintf(f, ", ");
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
		auto *params = &t->Proc.params->Tuple;
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
		ssa_fprintf(f, "c\"");
		ssa_print_escape_string(f, value.value_string, false);
		ssa_fprintf(f, "\"");
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
		u64 u = *cast(u64*)&value.value_float;
		if (is_type_float(type) && type->Basic.kind == Basic_f32) {
			// IMPORTANT NOTE(bill): LLVM requires all floating point constants to be
			// a 64 bit number if bits_of(float type) <= 64.
			// For some bizarre reason, you need to clear the bottom 29 bits
			// https://groups.google.com/forum/#!topic/llvm-dev/IlqV3TbSk6M
			u >>= 29;
			u <<= 29;
		}
		ssa_fprintf(f, "0x%016llx", u);
	} break;
	case ExactValue_Pointer:
		if (value.value_pointer == NULL) {
			ssa_fprintf(f, "null");
		} else {
			ssa_fprintf(f, "inttoptr (");
			ssa_print_type(f, m, t_int);
			ssa_fprintf(f, " %llu to ", cast(u64)cast(uintptr)value.value_pointer);
			ssa_print_type(f, m, t_rawptr);
			ssa_fprintf(f, ")");
		}
		break;
	default:
		GB_PANIC("Invalid ExactValue: %d", value.kind);
		break;
	}
}

void ssa_print_block_name(ssaFileBuffer *f, ssaBlock *b) {
	ssa_print_escape_string(f, b->label, false);
	ssa_fprintf(f, "-%d", b->id);
}

void ssa_print_value(ssaFileBuffer *f, ssaModule *m, ssaValue *value, Type *type_hint) {
	if (value == NULL) {
		ssa_fprintf(f, "!!!NULL_VALUE");
		return;
	}
	switch (value->kind) {
	case ssaValue_Constant:
		ssa_print_exact_value(f, m, value->Constant.value, type_hint);
		break;
	case ssaValue_TypeName:
		ssa_print_encoded_local(f, value->TypeName.name);
		break;
	case ssaValue_Global: {
		Scope *scope = value->Global.entity->scope;
		b32 in_global_scope = false;
		if (scope != NULL) {
			in_global_scope = scope->is_global || scope->is_init;
		}
		// if (type_hint != NULL && is_type_string(type_hint)) {
		// 	ssa_fprintf(f, "{i8* getelementptr inbounds (");
		// 	ssa_print_type(f, m, value->Global.entity->type);
		// 	ssa_fprintf(f, ", ");
		// 	ssa_print_type(f, m, value->Global.entity->type);
		// 	ssa_fprintf(f, "* ");
		// 	ssa_print_encoded_global(f, value->Global.entity->token.string, in_global_scope);
		// 	ssa_fprintf(f, ", ");
		// 	ssa_print_type(f, m, t_int);
		// 	ssa_fprintf(f, " 0, i32 0), ");
		// 	ssa_print_type(f, m, t_int);
		// 	ssa_fprintf(f, " %lld}", 0);
		// } else {
			ssa_print_encoded_global(f, value->Global.entity->token.string, in_global_scope);
		// }
	} break;
	case ssaValue_Param:
		ssa_print_encoded_local(f, value->Param.entity->token.string);
		break;
	case ssaValue_Proc:
		ssa_print_encoded_global(f, value->Proc.name, (value->Proc.tags & (ProcTag_foreign|ProcTag_link_name)) != 0);
		break;
	case ssaValue_Instr:
		ssa_fprintf(f, "%%%d", value->id);
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
		ssa_print_encoded_global(f, make_string(SSA_STARTUP_RUNTIME_PROC_NAME), false);
		ssa_fprintf(f, "()\n");
	} break;

	case ssaInstr_Comment:
		ssa_fprintf(f, "; %.*s\n", LIT(instr->Comment.text));
		break;

	case ssaInstr_Local: {
		Type *type = instr->Local.entity->type;
		ssa_fprintf(f, "%%%d = alloca ", value->id);
		ssa_print_type(f, m, type);
		ssa_fprintf(f, ", align %lld\n", type_align_of(m->sizes, m->allocator, type));
	} break;

	case ssaInstr_ZeroInit: {
		Type *type = type_deref(ssa_type(instr->ZeroInit.address));
		ssa_fprintf(f, "store ");
		ssa_print_type(f, m, type);
		ssa_fprintf(f, " zeroinitializer, ");
		ssa_print_type(f, m, type);
		ssa_fprintf(f, "* %%%d\n", instr->ZeroInit.address->id);
	} break;

	case ssaInstr_Store: {
		Type *type = ssa_type(instr);
		ssa_fprintf(f, "store ");
		if ((type->flags & TypeFlag_volatile) != 0) {
			ssa_fprintf(f, "volatile ");
		}
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
		ssa_fprintf(f, "%%%d = load ", value->id);
		if ((type->flags & TypeFlag_volatile) != 0) {
			ssa_fprintf(f, "volatile ");
		}
		ssa_print_type(f, m, type);
		ssa_fprintf(f, ", ");
		ssa_print_type(f, m, type);
		ssa_fprintf(f, "* ");
		ssa_print_value(f, m, instr->Load.address, type);
		ssa_fprintf(f, ", align %lld\n", type_align_of(m->sizes, m->allocator, type));
	} break;

	case ssaInstr_GetElementPtr: {
		Type *et = instr->GetElementPtr.elem_type;
		ssa_fprintf(f, "%%%d = getelementptr ", value->id);
		if (instr->GetElementPtr.inbounds) {
			ssa_fprintf(f, "inbounds ");
		}

		ssa_print_type(f, m, type_deref(et));
		ssa_fprintf(f, ", ");
		ssa_print_type(f, m, et);
		ssa_fprintf(f, " ");
		ssa_print_value(f, m, instr->GetElementPtr.address, et);
		for (isize i = 0; i < instr->GetElementPtr.index_count; i++) {
			ssaValue *index = instr->GetElementPtr.indices[i];
			Type *t = ssa_type(index);
			ssa_fprintf(f, ", ");
			ssa_print_type(f, m, t);
			ssa_fprintf(f, " ");
			ssa_print_value(f, m, index, t);
		}
		ssa_fprintf(f, "\n");
	} break;

	case ssaInstr_ExtractValue: {
		Type *et = instr->ExtractValue.elem_type;
		ssa_fprintf(f, "%%%d = extractvalue ", value->id);

		ssa_print_type(f, m, et);
		ssa_fprintf(f, " ");
		ssa_print_value(f, m, instr->ExtractValue.address, et);
		ssa_fprintf(f, ", %d\n", instr->ExtractValue.index);
	} break;

	case ssaInstr_NoOp: {;
		ssa_fprintf(f, "%%%d = add i32 0, 0\n", value->id);
	} break;

	case ssaInstr_Br: {;
		ssa_fprintf(f, "br ");
		if (instr->Br.cond != NULL) {
			ssa_print_type(f, m, t_bool);
			ssa_fprintf(f, " ");
			ssa_print_value(f, m, instr->Br.cond, t_bool);
			ssa_fprintf(f, ", ", instr->Br.cond->id);
		}
		ssa_fprintf(f, "label ");
		ssa_fprintf(f, "%%"); ssa_print_block_name(f, instr->Br.true_block);
		if (instr->Br.false_block != NULL) {
			ssa_fprintf(f, ", label ");
			ssa_fprintf(f, "%%"); ssa_print_block_name(f, instr->Br.false_block);
		}
		ssa_fprintf(f, "\n");
	} break;

	case ssaInstr_Ret: {
		auto *ret = &instr->Ret;
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
		auto *c = &instr->Conv;
		ssa_fprintf(f, "%%%d = %.*s ", value->id, LIT(ssa_conv_strings[c->kind]));
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
		auto *bo = &value->Instr.BinaryOp;
		Type *type = base_type(ssa_type(bo->left));
		Type *elem_type = type;
		while (elem_type->kind == Type_Vector) {
			elem_type = base_type(elem_type->Vector.elem);
		}

		ssa_fprintf(f, "%%%d = ", value->id);

		if (gb_is_between(bo->op.kind, Token__ComparisonBegin+1, Token__ComparisonEnd-1)) {
			if (is_type_string(elem_type)) {
				ssa_fprintf(f, "call ");
				ssa_print_type(f, m, t_bool);
				char *runtime_proc = "";
				switch (bo->op.kind) {
				case Token_CmpEq: runtime_proc = "__string_eq"; break;
				case Token_NotEq: runtime_proc = "__string_ne"; break;
				case Token_Lt:    runtime_proc = "__string_lt"; break;
				case Token_Gt:    runtime_proc = "__string_gt"; break;
				case Token_LtEq:  runtime_proc = "__string_le"; break;
				case Token_GtEq:  runtime_proc = "__string_gt"; break;
				}

				ssa_fprintf(f, " ");
				ssa_print_encoded_global(f, make_string(runtime_proc), false);
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
				switch (bo->op.kind) {
				case Token_CmpEq: ssa_fprintf(f, "oeq"); break;
				case Token_NotEq: ssa_fprintf(f, "one"); break;
				case Token_Lt:    ssa_fprintf(f, "olt"); break;
				case Token_Gt:    ssa_fprintf(f, "ogt"); break;
				case Token_LtEq:  ssa_fprintf(f, "ole"); break;
				case Token_GtEq:  ssa_fprintf(f, "oge"); break;
				}
			} else {
				ssa_fprintf(f, "icmp ");
				if (bo->op.kind != Token_CmpEq &&
				    bo->op.kind != Token_NotEq) {
					if (is_type_unsigned(elem_type)) {
						ssa_fprintf(f, "u");
					} else {
						ssa_fprintf(f, "s");
					}
				}
				switch (bo->op.kind) {
				case Token_CmpEq: ssa_fprintf(f, "eq"); break;
				case Token_NotEq: ssa_fprintf(f, "ne"); break;
				case Token_Lt:    ssa_fprintf(f, "lt"); break;
				case Token_Gt:    ssa_fprintf(f, "gt"); break;
				case Token_LtEq:  ssa_fprintf(f, "le"); break;
				case Token_GtEq:  ssa_fprintf(f, "ge"); break;
				}
			}
		} else {
			if (is_type_float(elem_type))
				ssa_fprintf(f, "f");

			switch (bo->op.kind) {
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

				switch (bo->op.kind) {
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
		auto *call = &instr->Call;
		Type *result_type = call->type;
		if (result_type) {
			ssa_fprintf(f, "%%%d = ", value->id);
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
			auto *params = &proc_type->Proc.params->Tuple;
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
		ssa_fprintf(f, "%%%d = select i1 ", value->id);
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

	case ssaInstr_ExtractElement: {
		Type *vt = ssa_type(instr->ExtractElement.vector);
		ssa_fprintf(f, "%%%d = extractelement ", value->id);

		ssa_print_type(f, m, vt);
		ssa_fprintf(f, " ");
		ssa_print_value(f, m, instr->ExtractElement.vector, vt);
		ssa_fprintf(f, ", ");
		Type *it = ssa_type(instr->ExtractElement.index);
		ssa_print_type(f, m, it);
		ssa_fprintf(f, " ");
		ssa_print_value(f, m, instr->ExtractElement.index, it);
		ssa_fprintf(f, "\n");
	} break;

	case ssaInstr_InsertElement: {
		auto *ie = &instr->InsertElement;
		Type *vt = ssa_type(ie->vector);
		ssa_fprintf(f, "%%%d = insertelement ", value->id);

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

	case ssaInstr_ShuffleVector: {
		auto *sv = &instr->ShuffleVector;
		Type *vt = ssa_type(sv->vector);
		ssa_fprintf(f, "%%%d = shufflevector ", value->id);

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

	auto *proc_type = &proc->type->Proc;

	if (proc_type->result_count == 0) {
		ssa_fprintf(f, "void");
	} else {
		ssa_print_type(f, m, proc_type->results);
	}

	ssa_fprintf(f, " ");
	ssa_print_encoded_global(f, proc->name, (proc->tags & (ProcTag_foreign|ProcTag_link_name)) != 0);
	ssa_fprintf(f, "(");

	if (proc_type->param_count > 0) {
		auto *params = &proc_type->params->Tuple;
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
			ssaDebugInfo *di = *map_get(&proc->module->debug_info, hash_pointer(proc->entity));
			GB_ASSERT(di->kind == ssaDebugInfo_Proc);
			ssa_fprintf(f, "!dbg !%d ", di->id);
		}
	}


	if (proc->body != NULL) {
		// ssa_fprintf(f, "nounwind uwtable {\n");

		ssa_fprintf(f, "{\n");
		gb_for_array(i, proc->blocks) {
			ssaBlock *block = proc->blocks[i];

			if (i > 0) ssa_fprintf(f, "\n");
			ssa_print_block_name(f, block);
			ssa_fprintf(f, ":\n");

			gb_for_array(j, block->instrs) {
				ssaValue *value = block->instrs[j];
				ssa_print_instr(f, m, value);
			}
		}
		ssa_fprintf(f, "}\n");
	} else {
		ssa_fprintf(f, "\n");
	}

	gb_for_array(i, proc->children) {
		ssa_print_proc(f, m, proc->children[i]);
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

void ssa_print_llvm_ir(ssaFileBuffer *f, ssaModule *m) {
	if (m->layout.len > 0) {
		ssa_fprintf(f, "target datalayout = \"%.*s\"\n", LIT(m->layout));
	}

	ssa_print_encoded_local(f, make_string("..string"));
	ssa_fprintf(f, " = type {i8*, ");
	ssa_print_type(f, m, t_int);
	ssa_fprintf(f, "} ; Basic_string\n");

	ssa_print_encoded_local(f, make_string("..rawptr"));
	ssa_fprintf(f, " = type i8* ; Basic_rawptr\n\n");

	gb_for_array(member_index, m->members.entries) {
		auto *entry = &m->members.entries[member_index];
		ssaValue *v = entry->value;
		if (v->kind != ssaValue_TypeName) {
			continue;
		}
		ssa_print_type_name(f, m, v);
	}

	gb_for_array(member_index, m->members.entries) {
		auto *entry = &m->members.entries[member_index];
		ssaValue *v = entry->value;
		if (v->kind != ssaValue_Proc) {
			continue;
		}
		if (v->Proc.body == NULL) {
			ssa_print_proc(f, m, &v->Proc);
		}
	}

	gb_for_array(member_index, m->members.entries) {
		auto *entry = &m->members.entries[member_index];
		ssaValue *v = entry->value;
		if (v->kind != ssaValue_Proc) {
			continue;
		}
		if (v->Proc.body != NULL) {
			ssa_print_proc(f, m, &v->Proc);
		}
	}


	gb_for_array(member_index, m->members.entries) {
		auto *entry = &m->members.entries[member_index];
		ssaValue *v = entry->value;
		if (v->kind != ssaValue_Global) {
			continue;
		}
		auto *g = &v->Global;
		Scope *scope = g->entity->scope;
		b32 in_global_scope = false;
		if (scope != NULL) {
			in_global_scope = scope->is_global || scope->is_init;
		}
		ssa_print_encoded_global(f, g->entity->token.string, in_global_scope);
		ssa_fprintf(f, " = ");
		if (g->is_thread_local) {
			ssa_fprintf(f, "thread_local ");
		}
		if (g->is_constant) {
			if (g->is_private) {
				ssa_fprintf(f, "private ");
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


	if (m->generate_debug_info) {
		ssa_fprintf(f, "\n");
		ssa_fprintf(f, "!llvm.dbg.cu = !{!0}\n");

		gb_for_array(di_index, m->debug_info.entries) {
			auto *entry = &m->debug_info.entries[di_index];
			ssaDebugInfo *di = entry->value;
			ssa_fprintf(f, "!%d = ", di->id);
			defer (ssa_fprintf(f, "\n"));

			switch (di->kind) {
			case ssaDebugInfo_CompileUnit: {
				auto *cu = &di->CompileUnit;
				ssaDebugInfo *file = *map_get(&m->debug_info, hash_pointer(cu->file));
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
				gb_for_array(proc_index, di->AllProcs.procs) {
					ssaDebugInfo *p = di->AllProcs.procs[proc_index];
					if (proc_index > 0) {ssa_fprintf(f, ",");}
					ssa_fprintf(f, "!%d", p->id);
				}
				ssa_fprintf(f, "}");
				break;
			}
		}
	}
}
