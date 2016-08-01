void ssa_fprintf(gbFile *f, char *fmt, ...) {
	va_list va;
	va_start(va, fmt);
	gb_fprintf_va(f, fmt, va);
#if 1
	gb_printf_va(fmt, va);
#endif
	va_end(va);
}


b32 ssa_valid_char(u8 c) {
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

void ssa_print_escape_string(gbFile *f, String name) {
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
	isize buf_len = name.len + extra;
	u8 *buf = gb_alloc_array(gb_heap_allocator(), u8, buf_len);
	defer (gb_free(gb_heap_allocator(), buf));

	isize j = 0;
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

	gb_file_write(f, buf, buf_len);
}



void ssa_print_encoded_local(gbFile *f, String name) {
	ssa_fprintf(f, "%%");
	ssa_print_escape_string(f, name);
}

void ssa_print_encoded_global(gbFile *f, String name) {
	ssa_fprintf(f, "@");
	ssa_print_escape_string(f, name);
}


void ssa_print_type(gbFile *f, BaseTypeSizes s, Type *t) {
	i64 word_bits = 8*s.word_size;
	GB_ASSERT_NOT_NULL(t);
	t = default_type(t);

	switch (t->kind) {
	case Type_Basic:
		switch (t->basic.kind) {
		case Basic_bool:   ssa_fprintf(f, "i1");                      break;
		case Basic_i8:     ssa_fprintf(f, "i8");                      break;
		case Basic_i16:    ssa_fprintf(f, "i16");                     break;
		case Basic_i32:    ssa_fprintf(f, "i32");                     break;
		case Basic_i64:    ssa_fprintf(f, "i64");                     break;
		case Basic_u8:     ssa_fprintf(f, "i8");                      break;
		case Basic_u16:    ssa_fprintf(f, "i16");                     break;
		case Basic_u32:    ssa_fprintf(f, "i32");                     break;
		case Basic_u64:    ssa_fprintf(f, "i64");                     break;
		case Basic_f32:    ssa_fprintf(f, "float");                   break;
		case Basic_f64:    ssa_fprintf(f, "double");                  break;
		case Basic_rawptr: ssa_fprintf(f, "void*");                   break;
		case Basic_string: ssa_fprintf(f, "{i8*, i%lld}", word_bits); break;
		case Basic_int:    ssa_fprintf(f, "i%lld", word_bits);        break;
		case Basic_uint:   ssa_fprintf(f, "i%lld", word_bits);        break;
		}
		break;
	case Type_Array:
		ssa_fprintf(f, "[%lld x ", t->array.count);
		ssa_print_type(f, s, t->array.element);
		ssa_fprintf(f, "]");
		break;
	case Type_Slice:
		ssa_fprintf(f, "{");
		ssa_print_type(f, s, t->slice.element);
		ssa_fprintf(f, "*, %lld, %lld}", word_bits, word_bits);
		break;
	case Type_Structure:
		ssa_fprintf(f, "{");
		for (isize i = 0; i < t->structure.field_count; i++) {
			if (i > 0) ssa_fprintf(f, ", ");
			ssa_print_type(f, s, t->structure.fields[i]->type);
		}
		ssa_fprintf(f, "}");
		break;
	case Type_Pointer:
		ssa_print_type(f, s, t->pointer.element);
		ssa_fprintf(f, "*");
		break;
	case Type_Named:
		ssa_print_encoded_local(f, t->named.name);
		break;
	case Type_Alias:
		ssa_print_type(f, s, t->alias.base);
		break;
	case Type_Tuple:
		if (t->tuple.variable_count == 1) {
			ssa_print_type(f, s, t->tuple.variables[0]->type);
		} else {
			ssa_fprintf(f, "{");
			for (isize i = 0; i < t->tuple.variable_count; i++) {
				if (i > 0) ssa_fprintf(f, ", ");
				ssa_print_type(f, s, t->tuple.variables[i]->type);
			}
			ssa_fprintf(f, "}");
		}
		break;
	case Type_Procedure:
		if (t->procedure.result_count == 0)
			ssa_fprintf(f, "void");
		else
			ssa_print_type(f, s, t->procedure.results);
		ssa_fprintf(f, " (");
		for (isize i = 0; i < t->procedure.param_count; i++) {
			if (i > 0) ssa_fprintf(f, ", ");
			ssa_print_type(f, s, &t->procedure.params[i]);
		}
		ssa_fprintf(f, ") ");
		break;
	}
}

void ssa_print_exact_value(gbFile *f, ssaModule *m, ExactValue value, Type *type) {
	switch (value.kind) {
	case ExactValue_Bool:
		ssa_fprintf(f, (value.value_bool ? "true" : "false"));
		break;
	case ExactValue_String: {
		ssa_fprintf(f, "{");
		ssa_print_type(f, m->sizes, &basic_types[Basic_i8]);
		ssa_fprintf(f, "* c\"");
		// TODO(bill): Make unquote string function
		String unquoted = value.value_string;
		unquoted.text++;
		unquoted.len -= 2;
		ssa_print_escape_string(f, unquoted);
		ssa_fprintf(f, "\", ");
		ssa_print_type(f, m->sizes, &basic_types[Basic_int]);
		ssa_fprintf(f, " %td}", value.value_string.len);
	} break;
	case ExactValue_Integer:
		ssa_fprintf(f, "%lld", value.value_integer);
		break;
	case ExactValue_Float: {
		u64 u = 0;
		if (is_type_float(type) && type->basic.kind == Basic_f32) {
			// IMPORTANT NOTE(bill): LLVM requires all floating point constants to be
			// a 64 bit number if bits_of(float type) <= 64.
			// To overcome this problem, fill the "bottom" 32 bits with zeros
			// https://groups.google.com/forum/#!topic/llvm-dev/IlqV3TbSk6M
			f32 fp = cast(f32)value.value_float;
			u = *cast(u32 *)&fp;
			u <<= 32;

		} else {
			u = *cast(u64 *)&value.value_float;
		}
		ssa_fprintf(f, "0x%llx", u);
	} break;
	case ExactValue_Pointer:
		if (value.value_float == NULL) {
			ssa_fprintf(f, "null");
		} else {
			GB_PANIC("TODO(bill): ExactValue_Pointer");
		}
		break;
	default:
		GB_PANIC("Invalid ExactValue");
		break;
	}
}


void ssa_print_value(gbFile *f, ssaModule *m, ssaValue *value, Type *type_hint) {
	if (value == NULL) {
		ssa_fprintf(f, "!!!NULL_VALUE");
		return;
	}
	switch (value->kind) {
	case ssaValue_TypeName:
		ssa_print_encoded_local(f, value->type_name.entity->token.string);
		break;
	case ssaValue_Global:
		ssa_print_encoded_global(f, value->global.entity->token.string);
		break;
	case ssaValue_Procedure:
		ssa_print_encoded_global(f, value->procedure.entity->token.string);
		break;
	case ssaValue_Constant: {
		ssa_print_exact_value(f, m, value->constant.value, type_hint);
	} break;
	case ssaValue_Instruction:
		ssa_fprintf(f, "%%%d", value->id);
		break;
	}
}

void ssa_print_instruction(gbFile *f, ssaModule *m, ssaValue *value) {
	GB_ASSERT(value->kind == ssaValue_Instruction);
	ssaInstruction *instr = &value->instruction;

	ssa_fprintf(f, "\t");
	switch (instr->kind) {
	case ssaInstruction_Local: {
		Type *type = instr->local.entity->type;
		ssa_fprintf(f, "%%%d = alloca ", value->id);
		ssa_print_type(f, m->sizes, type);
		ssa_fprintf(f, ", align %lld ", type_align_of(m->sizes, gb_heap_allocator(), type));
		ssa_fprintf(f, "; %.*s", LIT(instr->local.entity->token.string));
		ssa_fprintf(f, "\n");
		ssa_fprintf(f, "\tstore ");
		ssa_print_type(f, m->sizes, type);
		ssa_fprintf(f, " zeroinitializer, ");
		ssa_print_type(f, m->sizes, type);
		ssa_fprintf(f, "* %%%d\n", value->id);
	} break;

	case ssaInstruction_Store: {
		Type *type = ssa_value_type(instr->store.address);
		ssa_fprintf(f, "store ");
		ssa_print_type(f, m->sizes, type);
		ssa_fprintf(f, " ");
		ssa_print_value(f, m, instr->store.value, type);
		ssa_fprintf(f, ", ");
		ssa_print_type(f, m->sizes, type);
		ssa_fprintf(f, "* ");
		ssa_print_value(f, m, instr->store.address, type);
		ssa_fprintf(f, "\n");
	} break;

	case ssaInstruction_Load: {
		Type *type = instr->load.type;
		ssa_fprintf(f, "%%%d = load ", value->id);
		ssa_print_type(f, m->sizes, type);
		ssa_fprintf(f, ", ");
		ssa_print_type(f, m->sizes, type);
		ssa_fprintf(f, "* ");
		ssa_print_value(f, m, instr->load.address, type);
		ssa_fprintf(f, "\n");
	} break;

	case ssaInstruction_GetElementPtr: {
		Type *rt = instr->get_element_ptr.result_type;
		Type *et = instr->get_element_ptr.element_type;
		Type *t_int = &basic_types[Basic_int];
		ssa_fprintf(f, "%%%d = getelementptr ", value->id);
		if (instr->get_element_ptr.inbounds)
		ssa_fprintf(f, "inbounds ");

		ssa_print_type(f, m->sizes, et);
		ssa_fprintf(f, ", ");
		ssa_print_type(f, m->sizes, et);
		ssa_fprintf(f, "* ");
		ssa_print_value(f, m, instr->get_element_ptr.address, et);
		ssa_fprintf(f, ", ");
		ssa_print_type(f, m->sizes, t_int);
		ssa_fprintf(f, " ");
		ssa_print_value(f, m, instr->get_element_ptr.indices[0], t_int);
		if (instr->get_element_ptr.index_count == 2) {
			ssa_fprintf(f, ", ");
			ssa_print_type(f, m->sizes, t_int);
			ssa_fprintf(f, " ");
			ssa_print_value(f, m, instr->get_element_ptr.indices[1], t_int);
		}
		ssa_fprintf(f, "\n");
	} break;


	case ssaInstruction_BinaryOp: {
		auto *bo = &value->instruction.binary_op;
		Type *type = ssa_value_type(bo->left);

		ssa_fprintf(f, "%%%d = ", value->id);

		if (gb_is_between(bo->op.kind, Token__ComparisonBegin+1, Token__ComparisonEnd-1)) {
			if (is_type_float(type)) {
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
					if (is_type_unsigned(type)) {
						ssa_fprintf(f, "s");
					} else {
						ssa_fprintf(f, "u");
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
			if (is_type_float(type))
				ssa_fprintf(f, "f");

			switch (bo->op.kind) {
			case Token_Add:    ssa_fprintf(f, "add"); break;
			case Token_Sub:    ssa_fprintf(f, "sub"); break;
			case Token_And:    ssa_fprintf(f, "and"); break;
			case Token_Or:     ssa_fprintf(f, "or"); break;
			case Token_Xor:    ssa_fprintf(f, "xor"); break;

			case Token_AndNot: GB_PANIC("Token_AndNot Should never be called");

			case Token_Mul:    ssa_fprintf(f, "mul"); break;

			default: {
				if (!is_type_float(type)) {
					if (is_type_unsigned(type)) ssa_fprintf(f, "u");
					else                        ssa_fprintf(f, "s");
				}

				switch (bo->op.kind) {
				case Token_Quo: ssa_fprintf(f, "div"); break;
				case Token_Mod: ssa_fprintf(f, "rem"); break;
				}
			} break;
			}
		}

		ssa_fprintf(f, " ");
		ssa_print_type(f, m->sizes, type);
		ssa_fprintf(f, " ");
		ssa_print_value(f, m, bo->left, type);
		ssa_fprintf(f, ", ");
		ssa_print_value(f, m, bo->right, type);
		ssa_fprintf(f, "\n");

	} break;

	default:
		ssa_fprintf(f, "; <unknown instr> %d\n", instr->kind);
		break;
	}
}

void ssa_print_llvm_ir(gbFile *f, ssaModule *m) {
	gb_for_array(member_index, m->members.entries) {
		auto *entry = &m->members.entries[member_index];
		ssaValue *v = entry->value;
		switch (v->kind) {
		case ssaValue_TypeName: {
			ssa_print_encoded_local(f, v->type_name.entity->token.string);
			ssa_fprintf(f, " = type ");
			ssa_print_type(f, m->sizes, get_base_type(v->type_name.type));
			ssa_fprintf(f, "\n");
		} break;

		case ssaValue_Global: {
			auto *g = &v->global;
			ssa_print_encoded_global(f, g->entity->token.string);
			ssa_fprintf(f, " = global ");
			ssa_print_type(f, m->sizes, get_base_type(g->entity->type));
			ssa_fprintf(f, " ");
			ssa_print_value(f, m, g->value, g->entity->type);
			ssa_fprintf(f, ", align %td\n", type_align_of(m->sizes, gb_heap_allocator(), g->entity->type));
		} break;

		case ssaValue_Procedure: {
			ssaProcedure *proc = &v->procedure;
			if (proc->body == NULL) {
				ssa_fprintf(f, "declare ");
			} else {
				ssa_fprintf(f, "define ");
			}

			auto *proc_type = &proc->entity->type->procedure;

			if (proc_type->result_count == 0) {
				ssa_fprintf(f, "void");
			} else {
				ssa_print_type(f, m->sizes, proc_type->results);
			}

			ssa_fprintf(f, " ");

			ssa_print_encoded_global(f, proc->name);
			ssa_fprintf(f, "(");

			if (proc_type->param_count > 0) {
				auto *params = &proc_type->params->tuple;
				for (isize i = 0; i < params->variable_count; i++) {
					Entity *e = params->variables[i];
					if (i > 0)
						ssa_fprintf(f, ", ");
					ssa_print_type(f, m->sizes, e->type);
					ssa_fprintf(f, " %%%.*s", LIT(e->token.string));
				}
			}

			ssa_fprintf(f, ") ");

 			if (proc->body == NULL) {
				ssa_fprintf(f, "\n");
 			} else {
 				ssa_fprintf(f, "{\n");
 				gb_for_array(i, proc->blocks) {
 					ssaBlock *block = &proc->blocks[i]->block;
 					ssa_fprintf(f, "%.*s:\n", LIT(block->label));
 					gb_for_array(j, block->instructions) {
 						ssaValue *value = block->instructions[j];
 						ssa_print_instruction(f, m, value);
 					}
 				}

 				if (proc_type->result_count == 0) {
 					ssa_fprintf(f, "\tret void\n");
 				}
 				ssa_fprintf(f, "}\n");
 			}

		} break;
		}
	}
}
