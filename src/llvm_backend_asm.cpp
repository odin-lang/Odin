#define LLVM_ASM_DEBUG_PRINT false

struct lbAsmGenerate {
	Entity *                      tmpl_entity;
	AstAsmTemplate *              tmpl_node;
	Array<AsmTemplateEntityDecl> *ops;

	enum WriteOperandFlags : u32 {
		WriteOperandFlag_PrintPrefixes = 1<<0,
		WriteOperandFlag_IsScale       = 1<<1,
		WriteOperandFlag_IsScaleLog2   = 1<<2,

		WriteOperandFlag_Negate        = 1<<3,


		WriteOperandFlag_NONE = 0,
		WriteOperandFlag_DEFAULT = WriteOperandFlag_PrintPrefixes,
	};

	void init(Entity *entity) {
		this->tmpl_entity = entity;
		GB_ASSERT(this->tmpl_entity != nullptr);
		GB_ASSERT(this->tmpl_entity->kind == Entity_AsmTemplate);
		this->ops = &this->tmpl_entity->AsmTemplate.decls;
		GB_ASSERT(this->tmpl_entity->AsmTemplate.node->kind == Ast_AsmTemplate);
		this->tmpl_node = &this->tmpl_entity->AsmTemplate.node->AsmTemplate;
	}

	gbString write_label(gbString asm_string, AstIdent *label_ident) {
		String name = label_ident->token.string;
		asm_string = gb_string_appendc(asm_string, ".L_");
		asm_string = gb_string_append_length(asm_string, tmpl_entity->token.string.text, tmpl_entity->token.string.len);
		asm_string = gb_string_appendc(asm_string, "_");
		asm_string = gb_string_append_length(asm_string, name.text, name.len);
		// ${:uid} expands to a per-instantiation unique integer, so repeated
		// inlining of the same template can't collide on the label symbol.
		asm_string = gb_string_appendc(asm_string, "${:uid}");
		return asm_string;
	}

	AsmTemplateEntityDecl *entity_op(Entity *parameter) {
		for (AsmTemplateEntityDecl &op : *ops) {
			if (op.entity == parameter) {
				return &op;
			}
		}
		GB_PANIC("Could not find asm entity %.*s", LIT(parameter->token.string));
		return nullptr;
	}

	gbString write_constant_operand(gbString asm_string, Ast *op, u32 flags) {
		GB_ASSERT(op->tav.mode == Addressing_Constant);

		op->tav.value = exact_value_to_integer(op->tav.value);
		ExactValue ev = op->tav.value;
		GB_ASSERT(ev.kind != ExactValue_Invalid);
		switch (ev.kind) {
		case ExactValue_Integer: {
			i64 val = exact_value_to_i64(ev);
			if (flags & WriteOperandFlag_IsScale) {
				switch (val) {
				case 1: case 2: case 4: case 8:
					// okay
					break;
				default:
					error(op, "A scale must be a constant integer or an immediate with the value 1, 2, 4, or 8, got %lld", cast(long long)val);
					break;
				}
			} else if (flags & WriteOperandFlag_IsScaleLog2) {
				switch (val) {
				case 0: case 1: case 2: case 3:
					// NOTE(bill): AMD64 only supports full scales
					val = (cast(i64)1)<<val;
					break;
				default:
					error(op, "A shifting scale must be a constant integer or an immediate with the value 0, 1, 2, or 3, got %lld", cast(long long)val);
					break;
				}
			}

			if (flags & WriteOperandFlag_PrintPrefixes) {
				asm_string = gb_string_appendc(asm_string, "$$");
			}

			if (flags & WriteOperandFlag_Negate) {
				val = -val;
			}

			asm_string = gb_string_append_fmt(asm_string, "%d", cast(int)val);
			break;
		}
		case ExactValue_Float:
			error(op, "Floating-point literals that cannot be represented as an integer are not supported within asm operands");
			break;
		default:
			GB_PANIC("Unsupported asm immediate literal %s", expr_to_string(op));
			break;
		}

		return asm_string;
	}


	gbString write_operand(gbString asm_string, Slice<i32> const &op_number, Ast *op, u32 flags) {
		if (op->tav.mode == Addressing_Constant) {
			return write_constant_operand(asm_string, op, flags);
		}

		if (flags & WriteOperandFlag_Negate) {
			flags &= ~WriteOperandFlag_Negate;
			asm_string = gb_string_appendc(asm_string, "-");
		}

		switch (op->kind) {
		case_ast_node(i, Ident, op);
			Entity *e = entity_of_node(op);
			auto *ed = entity_op(e);

			if (ed->view_of >= 0) {
				// Width-view of another operand (e.g. `p0b: u8 = p0`): emit the SOURCE
				// operand's number with an LLVM width modifier, so both names share the
				// one register the allocator chose, viewed at the requested width.
				i32 idx = op_number[ed->view_of];
				GB_ASSERT(idx >= 0);
				char mod = 0;
				switch (ed->view_bits) {
				case 8:  mod = 'b'; break; // low 8-bit  (al/r11b/...)
				case 16: mod = 'w'; break; // 16-bit     (ax/r11w/...)
				case 32: mod = 'k'; break; // 32-bit     (eax/r11d/...)
				case 64: mod = 'q'; break; // 64-bit     (rax/r11/...)
				default: GB_PANIC("asm: invalid width-view size %d", ed->view_bits); break;
				}
				asm_string = gb_string_append_fmt(asm_string, "${%d:%c}", idx, mod);
			} else {
				i32 idx = op_number[ed->total_index];
				GB_ASSERT(idx >= 0);
				asm_string = gb_string_append_fmt(asm_string, "$%d", idx);
			}
		case_end;
		case_ast_node(mem_op, AsmMemoryOperand, op);
			asm_string = this->write_memory_operand(asm_string, op_number, mem_op, flags&~WriteOperandFlag_PrintPrefixes);
		case_end;

		case_ast_node(bl, BasicLit, op);
			GB_PANIC("NOTE(bill): this should have been handled above");
		case_end;

		case_ast_node(label, AsmLabelDecl, op);
			asm_string = write_label(asm_string, &label->name->Ident);
		case_end;

		case_ast_node(reg, AsmRegister, op);
			asm_string = gb_string_appendc(asm_string, "%");
			asm_string = gb_string_append_length(asm_string, reg->name.string.text, reg->name.string.len);
		case_end;
		default:
			GB_PANIC("TODO(bill): write_operand for '%s'", expr_to_string(op));
			break;
		}
		return asm_string;
	}

	char const *class_letter(AsmRegClass rc) {
		switch (rc) {
		case AsmRegClass_Integer: return "r";
		case AsmRegClass_Float:   return "x";   // TODO(bill): target-dependent
		case AsmRegClass_Vector:  return "x";   // TODO(bill): target-dependent
		case AsmRegClass_Mask:    return "^Yk"; // AVX-512 k-regs
		default: GB_PANIC("asm: unknown reg class"); return "r";
		}
	};


	// LLVM type of a returned register output, taken from the proc signature's results.
	LLVMTypeRef output_llvm_type(lbModule *m, AsmTemplateEntityDecl const &e) {
		Type *pt = base_type(tmpl_entity->type);
		Type *rt = pt->Proc.results->Tuple.variables[e.result_index]->type;
		return lb_type(m, rt);
	};

	// The declared Odin result type for an output entity.
	Type *result_type_of(AsmTemplateEntityDecl const &e) {
		Type *pt = base_type(tmpl_entity->type);
		return pt->Proc.results->Tuple.variables[e.result_index]->type;
	}

	virtual char     instruction_size_suffix(AstAsmInstruction *instr) = 0;
	virtual char     size_suffix_for_operand(Ast *op) = 0;
	virtual gbString write_memory_operand(gbString asm_string, Slice<i32> const &op_number, AstAsmMemoryOperand *mem_op, u32 flags) = 0;
	virtual lbValue  emit_call(lbProcedure *p, Array<lbValue> const &args) = 0;
	virtual String   flag_output_cc_suffix(String const &pin_flag) = 0;

};

struct lbAsmGenerate_amd64 : lbAsmGenerate {
	// AT&T operand-size suffix ('b','w','l','q') for an annotated memory operand,
	// or 0 if there is no size annotation to apply. Vector/other widths return 0,
	// since those forms take no b/w/l/q suffix (the register operand fixes the size).
	char size_suffix_for_operand(Ast *op) override {
		if (op->kind != Ast_AsmMemoryOperand) {
			return 0;
		}
		AstAsmMemoryOperand *mem_op = &op->AsmMemoryOperand;
		if (mem_op->type == nullptr) {
			return 0; // unsized: rely on a register operand to fix the width
		}
		// The frontend stored the access type as a pointer on the node's tav: [p]:u8 -> ^u8.
		Type *ptr = mem_op->type->tav.type;
		if (ptr == nullptr) {
			return 0;
		}
		Type *access = type_deref(ptr); // ^u8 -> u8
		i64 sz = type_size_of(base_type(access));
		switch (sz) {
		case 1: return 'b';
		case 2: return 'w';
		case 4: return 'l';
		case 8: return 'q';
		}
		return 0;
	}


	// Some AT&T mnemonics encode BOTH operand widths and so cannot be spelled as a name plus one
	// suffix: `movsx` from i8 to i32 is `movsbl`. Returns the complete mnemonic, or {} when the
	// name-plus-suffix spelling is the right one
	//
	// The sign/zero-extend family is the only one whose two operands differ in width. Its AT&T
	// mnemonic names both: `movsx` i8 -> i32 is `movsbl`, never `movsx` plus a suffix. `movsxd` is
	// the same rule, movs + l + q
	String instruction_att_mnemonic(AstAsmInstruction *instr) {
		bool sign_extend;
		switch (instr->mnemonic) {
		case Asm_amd64::M_MOVSX:
		case Asm_amd64::M_MOVSXD:
			sign_extend = true;
			break;
		case Asm_amd64::M_MOVZX:
			sign_extend = false;
			break;
		default:
			return {};
		}

		auto forms = g_asm_amd64.encoding_forms(instr->mnemonic);
		if (instr->valid_form_index < 0 || instr->valid_form_index >= forms.count) {
			return {};
		}
		auto const &form = forms[instr->valid_form_index];

		// Intel operand order: dst first
		i32 dst = g_asm_amd64.operand_type_bit_width(form.ops[0]);
		i32 src = g_asm_amd64.operand_type_bit_width(form.ops[1]);

		if (sign_extend) {
			if (src ==  8 && dst == 16) { return str_lit("movsbw"); }
			if (src ==  8 && dst == 32) { return str_lit("movsbl"); }
			if (src ==  8 && dst == 64) { return str_lit("movsbq"); }
			if (src == 16 && dst == 32) { return str_lit("movswl"); }
			if (src == 16 && dst == 64) { return str_lit("movswq"); }
			if (src == 32 && dst == 64) { return str_lit("movslq"); }
		} else {
			if (src ==  8 && dst == 16) { return str_lit("movzbw"); }
			if (src ==  8 && dst == 32) { return str_lit("movzbl"); }
			if (src ==  8 && dst == 64) { return str_lit("movzbq"); }
			if (src == 16 && dst == 32) { return str_lit("movzwl"); }
			if (src == 16 && dst == 64) { return str_lit("movzwq"); }
		}
		return {};
	}

	// Scan an instruction's operands for an annotated memory operand and return its
	// size suffix, or 0 if none. The checker has already verified the annotation
	// agrees with the matched encoding form, so a suffix here can never conflict.
	char instruction_size_suffix(AstAsmInstruction *instr) override {
		for (Ast *operand : instr->operands) {
			char s = this->size_suffix_for_operand(operand);
			if (s != 0) {
				return s;
			}
		}
		GB_ASSERT(instr->mnemonic != 0);
		GB_ASSERT(instr->valid_form_index >= 0);

		auto forms = g_asm_amd64.encoding_forms(instr->mnemonic);
		if (forms.count <= 1) {
			return 0;
		}
		auto const &form = forms[instr->valid_form_index];

		i32 width = 0;
		for (auto ot : form.ops) {
			if (ot == g_asm_amd64.OP_NONE) {
				break;
			}
			if (g_asm_amd64.operand_type_is_implicit(ot)) {
				continue;
			}
			AsmRegClass cls = g_asm_amd64.operand_type_reg_class(ot);
			if (cls == AsmRegClass_Vector || cls == AsmRegClass_Mask) {
				// xmm/ymm/zmm/k forms take no b/w/l/q suffix
				return 0;
			}

			// Only register and memory operands contribute an operand-size suffix.
			// Relative branch targets (OP_REL8/REL32), immediates (OP_IMM*), and
			// labels are NOT operand sizes -- jl/jmp/call/setcc must never get a
			// b/w/l/q suffix from their displacement/immediate.
			AsmOperandKind kind = g_asm_amd64.kind_from_operand_type(ot);
			if (kind != AsmOperand_Register &&
			    kind != AsmOperand_Memory &&
			    kind != AsmOperand_Register_Or_Memory) {
				continue;
			}

			i32 w = g_asm_amd64.operand_type_bit_width(ot);
			if (w == 8 || w == 16 || w == 32 || w == 64) {
				width = gb_max(width, w); // GP/memory width
			}
		}

		switch (width) {
		case 8:  return 'b';
		case 16: return 'w';
		case 32: return 'l';
		case 64: return 'q';
		}
		// vector op, or nothing that needs a GP-width suffix
		return 0;
	}

	// Map an EFLAGS flag name to its LLVM `=@cc<suffix>` setcc condition, or {} if
	// the flag has no single-flag setcc form (af/df/if/... can't be a flag output).
	String flag_output_cc_suffix(String const &pin_flag) override {
		if (pin_flag == "c") return str_lit("c"); // carry
		if (pin_flag == "p") return str_lit("p"); // parity (even)
		if (pin_flag == "z") return str_lit("z"); // zero
		if (pin_flag == "s") return str_lit("s"); // sign
		if (pin_flag == "o") return str_lit("o"); // overflow
		return {};
	}


	gbString write_memory_operand(gbString asm_string, Slice<i32> const &op_number, AstAsmMemoryOperand *mem_op, u32 flags) override {
		if (mem_op->segment_override != nullptr) {
			asm_string = this->write_operand(asm_string, op_number, mem_op->segment_override, flags);
			asm_string = gb_string_appendc(asm_string, ":");
		}

		if (mem_op->disp) {
			u32 disp_flags = flags;
			disp_flags &= ~WriteOperandFlag_PrintPrefixes;
			if (mem_op->disp_op.kind == Token_Sub) {
				disp_flags |= WriteOperandFlag_Negate;
			}

			asm_string = this->write_operand(asm_string, op_number, mem_op->disp, disp_flags);
		}
		if (mem_op->base == nullptr && mem_op->index == nullptr) {
			GB_ASSERT(mem_op->scale == nullptr);
			return asm_string;
		}
		asm_string = gb_string_appendc(asm_string, "(");
		if (mem_op->base != nullptr) {
			asm_string = this->write_operand(asm_string, op_number, mem_op->base, flags);
		}
		if (mem_op->index) {
			u32 index_flags = flags;
			if (mem_op->index_op.kind == Token_Sub) {
				index_flags |= WriteOperandFlag_Negate;
			}
			asm_string = gb_string_appendc(asm_string, ",");
			asm_string = this->write_operand(asm_string, op_number, mem_op->index, index_flags);

			if (mem_op->scale) {
				asm_string = gb_string_appendc(asm_string, ",");
				switch (mem_op->scale_op.kind) {
				case Token_Mul:
					asm_string = this->write_operand(asm_string, op_number, mem_op->scale, (flags|WriteOperandFlag_IsScale)&~WriteOperandFlag_PrintPrefixes);
					break;
				case Token_Shl:
				case Token_Shr:
					asm_string = this->write_operand(asm_string, op_number, mem_op->scale, (flags|WriteOperandFlag_IsScaleLog2)&~WriteOperandFlag_PrintPrefixes);
					break;
				}
			}
		}
		asm_string = gb_string_appendc(asm_string, ")");
		return asm_string;
	}

	lbValue emit_call(lbProcedure *p, Array<lbValue> const &args) override {
		lbModule *m = p->module;
		LLVMContextRef ctx = m->ctx;

		gbString asm_string  = gb_string_make_reserve(heap_allocator(), 256);
		gbString constraints = gb_string_make_reserve(heap_allocator(), 64);
		defer ({
			gb_string_free(constraints);
			gb_string_free(asm_string);
		});

		TEMPORARY_ALLOCATOR_GUARD();

		auto param_types = array_make<LLVMTypeRef> (temporary_allocator(), 0, ops->count);
		auto call_args   = array_make<LLVMValueRef>(temporary_allocator(), 0, ops->count);
		auto ret_types   = array_make<LLVMTypeRef> (temporary_allocator(), 0, ops->count);

		// Per-operand bookkeeping, indexed the same as `ops` (via total_index).
		auto op_number = slice_make<i32>(temporary_allocator(), ops->count); // $N, or -1 for clobbers/views
		auto ret_slot  = slice_make<i32>(temporary_allocator(), ops->count); // return-struct index, or -1
		for_array(i, *ops) {
			op_number[i] = -1;
			ret_slot [i] = -1;
		}

		// elementtype() attrs to attach after the call is built (indirect/memory operands).
		struct ElemAttr {
			unsigned arg_pos;
			LLVMTypeRef elem;
		};
		auto elem_attrs = array_make<ElemAttr>(temporary_allocator(), 0, ops->count);


		auto sep = [&]() {
			if (gb_string_length(constraints) != 0) {
				constraints = gb_string_appendc(constraints, ",");
			}
		};
		auto raw = [&](char const *s) {
			constraints = gb_string_appendc(constraints, s);
		};
		auto clobber = [&](char const *start, String mid, char const *end) {
			constraints = gb_string_appendc(constraints, start);
			constraints = gb_string_append_length(constraints, mid.text, mid.len);
			constraints = gb_string_appendc(constraints, end);
		};

		auto add_input_value = [](Array<LLVMTypeRef> *param_types, Array<LLVMValueRef> *call_args, LLVMValueRef v) {
			array_add(param_types, LLVMTypeOf(v));
			array_add(call_args, v);
		};


		i32 next_op = 0; // running $N counter (outputs first, then inputs)

		// Pass 1: outputs
		// Real outputs plus *unpinned* register scratch (modeled as discarded
		// early-clobber outputs, since a clobber can only name a fixed register).
		for_array(i, *ops) {
			AsmTemplateEntityDecl const &e = (*ops)[i];

			if (e.view_of >= 0) {
				continue; // width-view: resolved to its source's operand, owns no slot
			}

			// Flag output: an output pinned to a condition flag (e.g. `= %flags.zf`).
			// Lowers to LLVM's `=@cc<suffix>`, which yields an i1 (0/1). It takes a
			// return-struct slot but is NEVER referenced in the body (the instruction
			// sets the flag as a side effect), so it gets no $N operand number.
			if (e.param_group == AsmTemplateEntityDeclParamGroup_Output && e.pin_flag.len != 0) {
				GB_ASSERT(e.pin == "flags");
				String suffix = this->flag_output_cc_suffix(e.pin_flag);
				GB_ASSERT_MSG(suffix.len != 0, "asm: flag '%.*s' has no setcc condition form", LIT(e.pin_flag));

				sep();
				clobber("={@cc", suffix, "}");

				ret_slot[i] = cast(i32)ret_types.count;
				array_add(&ret_types, LLVMInt8TypeInContext(ctx));

				// Counted in $N even though never referenced in the body.
				op_number[i] = next_op++;
				continue;
			}

			bool is_output        = e.param_group == AsmTemplateEntityDeclParamGroup_Output;
			bool is_alloc_scratch = e.param_group == AsmTemplateEntityDeclParamGroup_Scratch
			                     && e.kind == AsmTemplateEntityDecl_Register;
			if (!is_output && !is_alloc_scratch) {
				continue;
			}

			sep();

			// Register output: '=' ['&'] ( '{pin}' | class-letter )
			raw("=");
			// early-clobber: keep scratch, and any output a later instruction could read past,
			// off an input's register. One instruction reads before it writes, so it is safe
			if (is_alloc_scratch || tmpl_node->instructions.count > 1) {
				raw("&");
			}
			if (e.pin.len != 0) {
				clobber("{", e.pin, "}");
			} else {
				raw(this->class_letter(e.reg_class));
			}

			// Use the entity's real declared type so the return-struct slot matches
			// the constraint's width/class (e.g. <4 x float> for a #simd[4]f32 scratch).
			LLVMTypeRef ty = is_alloc_scratch ? lb_type(m, e.entity->type) : this->output_llvm_type(m, e);

			ret_slot[i] = cast(i32)ret_types.count;
			array_add(&ret_types, ty);
			op_number[i] = next_op++;
		}

		// Pass 2: inputs
		for_array(i, *ops) {
			AsmTemplateEntityDecl const &e = (*ops)[i];

			if (e.view_of >= 0) {
				continue; // width-view: not its own input
			}
			if (e.param_group != AsmTemplateEntityDeclParamGroup_Input) {
				continue;
			}

			sep();
			lbValue v = args[e.param_index];

			if (e.tie >= 0) {
				// Tied read-write input: a matching constraint referencing the tied
				// output's operand number (e.g. "0").
				i32 n = op_number[e.tie];
				GB_ASSERT(n >= 0);
				constraints = gb_string_append_fmt(constraints, "%d", n);
				add_input_value(&param_types, &call_args, v.value);
			} else {
				switch (e.kind) {
				case AsmTemplateEntityDecl_Register:
				case AsmTemplateEntityDecl_Memory:
					if (e.pin.len != 0) {
						clobber("{", e.pin, "}");
					} else {
						raw(this->class_letter(e.reg_class));
					}
					add_input_value(&param_types, &call_args, v.value);
					break;
				case AsmTemplateEntityDecl_Immediate:
					raw("i"); // TODO: "n" if a known-constant integer is required
					add_input_value(&param_types, &call_args, v.value);
					break;
				default:
					GB_PANIC("asm: invalid input operand kind");
				}
			}
			op_number[i] = next_op++;
		}

		// Build the template text
		for_array(i, tmpl_node->instructions) {
			if (i > 0) {
				asm_string = gb_string_appendc(asm_string, "\n");
			}
			Ast *instr_ = tmpl_node->instructions[i];
			switch (instr_->kind) {
			case_ast_node(instr, AsmInstruction, instr_);
				asm_string = gb_string_appendc(asm_string, "\t");
				String name = instr->name->Ident.token.string;
				String att = this->instruction_att_mnemonic(instr);
				if (att.len != 0) {
					name = att;
				}
				asm_string = gb_string_append_length(asm_string, name.text, name.len);

				// If a memory operand carries an explicit size annotation ([p]:u8) and
				// no register operand pins the width, the AT&T assembler needs the size
				// encoded as a mnemonic suffix (crc32 -> crc32b). The checker has already
				// verified the annotation agrees with the matched form, so an emitted
				// suffix can never conflict with a register operand's implied width.
				if (att.len == 0) {
					if (char suffix = this->instruction_size_suffix(instr)) {
						asm_string = gb_string_append_length(asm_string, &suffix, 1);
					}
				}

				asm_string = gb_string_appendc(asm_string, " ");
				// Intel-source operand order reversed to AT&T (src, ..., dst).
				for (isize j = instr->operands.count-1; j >= 0; j -= 1) {
					Ast *op = instr->operands[j];
					if (j < instr->operands.count-1) {
						asm_string = gb_string_appendc(asm_string, ", ");
					}
					asm_string = this->write_operand(asm_string, op_number, op, WriteOperandFlag_DEFAULT);
				}
			case_end;
			case_ast_node(label, AsmLabelDecl, instr_);
				asm_string = this->write_label(asm_string, &label->name->Ident);
				asm_string = gb_string_appendc(asm_string, ":");
			case_end;
			case_ast_node(dir, AsmDirective, instr_);
				String name = dir->name.string;
				if (name == "byte") {
					asm_string = gb_string_appendc(asm_string, ".byte ");
					isize op_index = 0;
					for (auto const &op : dir->operands) {
						if (op_index > 0) {
							asm_string = gb_string_appendc(asm_string, ", ");
						}
						ExactValue ev = exact_value_to_integer(op->tav.value);
						GB_ASSERT(ev.kind == ExactValue_Integer);
						i64 i = exact_value_to_i64(ev);
						asm_string = gb_string_append_fmt(asm_string, "%d", cast(int)i);
						op_index += 1;
					}
				} else if (name == "align") {
					GB_ASSERT(dir->operands.count == 1);
					auto const &op = dir->operands[0];
					ExactValue ev = exact_value_to_integer(op->tav.value);
					GB_ASSERT(ev.kind == ExactValue_Integer);
					u64 i = exact_value_to_u64(ev);
					u64 i_log2 = floor_log2(i);
					asm_string = gb_string_appendc(asm_string, ".p2align ");
					asm_string = gb_string_append_fmt(asm_string, "%llu", cast(unsigned long long)i_log2);
				} else if (name == "skip") {
					GB_ASSERT(dir->operands.count == 1);
					auto const &op = dir->operands[0];
					ExactValue ev = exact_value_to_integer(op->tav.value);
					GB_ASSERT(ev.kind == ExactValue_Integer);
					u64 i = exact_value_to_u64(ev);
					asm_string = gb_string_appendc(asm_string, ".skip ");
					asm_string = gb_string_append_fmt(asm_string, "%llu", cast(unsigned long long)i);
				} else if (name == "nop") {
					GB_ASSERT(dir->operands.count == 1);
					auto const &op = dir->operands[0];
					ExactValue ev = exact_value_to_integer(op->tav.value);
					GB_ASSERT(ev.kind == ExactValue_Integer);
					u64 i = exact_value_to_u64(ev);
					asm_string = gb_string_appendc(asm_string, ".nops ");
					asm_string = gb_string_append_fmt(asm_string, "%llu", cast(unsigned long long)i);
				} else {
					GB_PANIC("Invalid asm directive: %.*s", LIT(name));
				}
			case_end;
			default:
				GB_PANIC("Invalid asm instruction");
				break;
			}
		}

		bool memory_clobbered_already = false;
		// Pass 3: clobbers
		// Only the Scratch group. Unpinned register scratch was already emitted as an
		// output in Pass 1, so it is skipped here.
		StringSet emitted_reg_clobbers = {};
		string_set_init(&emitted_reg_clobbers);
		defer (string_set_destroy(&emitted_reg_clobbers));

		for_array(i, *ops) {
			AsmTemplateEntityDecl const &e = (*ops)[i];

			if (e.view_of >= 0) {
				continue; // width-view carries no clobber; its source owns the register
			}
			if (e.param_group != AsmTemplateEntityDeclParamGroup_Scratch) {
				continue;
			}
			if (e.kind == AsmTemplateEntityDecl_Register && e.pin.len == 0) {
				continue;
			}

			sep();
			switch (e.kind) {
			case AsmTemplateEntityDecl_Register: // pinned -> real clobber
				GB_ASSERT(e.pin.len != 0);
				clobber("~{", e.pin, "}");
				string_set_update(&emitted_reg_clobbers, e.pin);
				break;
			case AsmTemplateEntityDecl_Memory:   // general memory clobber
				raw("~{memory}");
				memory_clobbered_already = true;
				break;
			default:
				GB_PANIC("asm: invalid scratch operand kind");
			}
		}

		// Explicit register clobbers from #clobber <reg>, deduped against the pinned
		// scratch clobbers already emitted above.
		for (String const &reg : tmpl_entity->AsmTemplate.clobber_registers_set) {
			if (string_set_exists(&emitted_reg_clobbers, reg)) {
				continue; // already clobbered as a pinned scratch; don't double-emit
			}
			sep();
			clobber("~{", reg, "}");
			string_set_update(&emitted_reg_clobbers, reg);
		}

		// Template-level clobbers derived from #clobber flags / #clobber memory.
		if (tmpl_entity->AsmTemplate.clobber_flags) {
			sep();
			if (build_context.metrics.arch == TargetArch_amd64) {
				// clang's canonical x86 flags clobber
				raw("~{dirflag}"); sep();
				raw("~{fpsr}");    sep();
				raw("~{flags}");
			} else {
				raw("~{cc}");    // AArch64 uses ~{cc}
			}
		}
		if (tmpl_entity->AsmTemplate.clobber_memory && !memory_clobbered_already) {
			sep();
			raw("~{memory}");
		}

		// Build the callee type
		// NOTE(bill): Even though the user has given a signature, this might not actually match what
		// LLVM requires it to be due to the scratch parameters and more, so many of the results might
		// need to be completely ignored to match the user's given signature.
		LLVMTypeRef ret_ty = nullptr;
		if (ret_types.count == 0) {
			ret_ty = LLVMVoidTypeInContext(ctx);
		} else if (ret_types.count == 1) {
			ret_ty = ret_types[0];
		} else {
			ret_ty = LLVMStructTypeInContext(ctx, ret_types.data, cast(unsigned)ret_types.count, /*packed*/false);
		}

		LLVMTypeRef fn_ty = LLVMFunctionType(ret_ty, param_types.data, cast(unsigned)param_types.count, /*vararg*/false);

		LLVMValueRef ia = LLVMGetInlineAsm(
			fn_ty,
			asm_string,  cast(size_t)gb_string_length(asm_string),
			constraints, cast(size_t)gb_string_length(constraints),
			/*HasSideEffects*/ tmpl_entity->AsmTemplate.is_volatile,
			/*IsAlignStack*/   tmpl_entity->AsmTemplate.is_align_stack,
			LLVMInlineAsmDialectATT,
			/*CanThrow*/       false);

		LLVMValueRef call = LLVMBuildCall2(p->builder, fn_ty, ia, call_args.data, cast(unsigned)call_args.count, "");

		if (LLVM_ASM_DEBUG_PRINT) {
			// DEBUG PRINT!!!
			// DEBUG PRINT!!!
			// DEBUG PRINT!!!
			gb_printf_err("%s\n", asm_string);
			char *ir = LLVMPrintValueToString(call);
			gb_printf_err("%s\n\n", ir);
			LLVMDisposeMessage(ir);
		}

		// Attach elementtype() to every indirect operand's pointer arg (opaque-pointer requirement).
		unsigned et_kind = LLVMGetEnumAttributeKindForName("elementtype", 11);
		for (auto const &elem_attr : elem_attrs) {
			LLVMAttributeRef attr = LLVMCreateTypeAttribute(ctx, et_kind, elem_attr.elem);
			LLVMAddCallSiteAttribute(call, cast(LLVMAttributeIndex)(elem_attr.arg_pos + 1), attr);
		}

		// Repackage results in Odin result order
		Type *pt = base_type(tmpl_entity->type);
		isize result_count = 0;
		if (pt->Proc.results != nullptr) {
			result_count = pt->Proc.results->Tuple.variables.count;
		}
		if (result_count == 0) {
			return lbValue{}; // void asm (memory outputs already wrote through their pointers)
		}

		// The LLVM return struct is ordered by operand and includes scratch slots;
		// pull out only the real register outputs and index them by result_index.
		auto result_vals = slice_make<LLVMValueRef>(temporary_allocator(), result_count);

		for_array(i, *ops) {
			AsmTemplateEntityDecl const &e = (*ops)[i];
			if (e.view_of >= 0) {
				continue; // width-view: never a returned value
			}
			if (e.param_group != AsmTemplateEntityDeclParamGroup_Output) {
				continue;
			}
			if (e.result_index < 0) {
				continue; // memory output: not a returned value
			}
			GB_ASSERT(ret_slot[i] >= 0);

			LLVMValueRef v = call;
			if (ret_types.count != 1) {
				// Not a single-element return but a struct
				v = LLVMBuildExtractValue(p->builder, call, cast(unsigned)ret_slot[i], "");
			}

			// A flag output is delivered as i8; coerce it to the declared result type
			// (e.g. i1, or a wider bool). zext when widening, trunc when narrowing.
			// zext (not sext) is correct: a flag output is 0 or 1.
			if (e.pin_flag.len != 0) {
				Type *rt = this->result_type_of(e);
				LLVMTypeRef want = lb_type(m, rt);
				LLVMTypeRef got  = LLVMTypeOf(v);
				if (want != got) {
					unsigned want_w = LLVMGetIntTypeWidth(want);
					unsigned got_w  = LLVMGetIntTypeWidth(got);
					if (want_w < got_w) {
						v = LLVMBuildTrunc(p->builder, v, want, "");
					} else if (want_w > got_w) {
						v = LLVMBuildZExt(p->builder, v, want, "");
					}
					// want_w == got_w with differing type identity: same width, no-op.
				}
			}

			result_vals[e.result_index] = v;
		}

		if (result_count == 1) {
			Type *rt = pt->Proc.results->Tuple.variables[0]->type;
			return lbValue{result_vals[0], rt};
		}

		// Multiple results -> assemble Odin's result aggregate in result order.
		Type *results_type = pt->Proc.results;
		LLVMValueRef agg = LLVMGetUndef(lb_type(m, results_type));
		for_array(i, result_vals) {
			GB_ASSERT(result_vals[i] != nullptr);
			agg = LLVMBuildInsertValue(p->builder, agg, result_vals[i], cast(unsigned)i, "");
		}

		return lbValue{agg, results_type};
	}
};

struct lbAsmGenerate_riscv64 : lbAsmGenerate {
	// RISC-V has no AT&T-style operand-size suffixes; precision lives in the mnemonic
	// (flw vs fld, .s vs .d), so nothing here ever contributes a b/w/l/q suffix.
	char size_suffix_for_operand(Ast *op) override {
		return 0;
	}
	char instruction_size_suffix(AstAsmInstruction *instr) override {
		return 0;
	}

	// RISC-V has no architectural condition-flags register, so no output can be pinned
	// to a flag / lowered to `=@cc<suffix>`.
	String flag_output_cc_suffix(String const &pin_flag) override {
		return {};
	}

	// LLVM inline-asm constraint class letters for RISC-V.
	char const *class_letter(AsmRegClass rc) {
		switch (rc) {
		case AsmRegClass_Integer: return "r";  // GPR  (x-registers)
		case AsmRegClass_Float:   return "f";  // FPR  (single/double share the FLEN file)
		case AsmRegClass_Vector:  return "vr"; // RVV vector register (V extension)
		case AsmRegClass_Mask:    return "vm"; // RVV mask register (v0)
		default:
			GB_PANIC("asm: unknown reg class");
			return "r";
		}
	}

	// RISC-V immediates are bare integers (no '$' prefix).
	gbString write_constant_operand(gbString asm_string, Ast *op, u32 flags) {
		GB_ASSERT(op->tav.mode == Addressing_Constant);
		op->tav.value = exact_value_to_integer(op->tav.value);
		ExactValue ev = op->tav.value;
		GB_ASSERT(ev.kind != ExactValue_Invalid);
		switch (ev.kind) {
		case ExactValue_Integer: {
			GB_ASSERT((flags & (WriteOperandFlag_IsScale|WriteOperandFlag_IsScaleLog2)) == 0);
			i64 val = exact_value_to_i64(ev);
			if (flags & WriteOperandFlag_Negate) {
				val = -val;
			}
			asm_string = gb_string_append_fmt(asm_string, "%lld", cast(long long)val);
			break;
		}
		case ExactValue_Float:
			error(op, "Floating-point literals that cannot be represented as an integer are not supported within asm operands");
			break;
		default:
			GB_PANIC("Unsupported asm immediate literal %s", expr_to_string(op));
			break;
		}
		return asm_string;
	}

	// RISC-V operand syntax: bare registers (no '%'), bare immediates (no '$$'), and
	// no x86 sub-register width modifiers.
	gbString write_operand(gbString asm_string, Slice<i32> const &op_number, Ast *op, u32 flags) {
		if (op->tav.mode == Addressing_Constant) {
			return this->write_constant_operand(asm_string, op, flags);
		}

		if (flags & WriteOperandFlag_Negate) {
			flags &= ~WriteOperandFlag_Negate;
			asm_string = gb_string_appendc(asm_string, "-");
		}

		switch (op->kind) {
		case_ast_node(i, Ident, op);
			Entity *e = entity_of_node(op);
			auto *ed = entity_op(e);
			// A width-view resolves to its source's operand. RISC-V x-registers are
			// always XLEN-wide with no named sub-registers, so a view is simply the
			// same register: emit the source operand number, no width modifier.
			i32 idx = (ed->view_of >= 0) ? op_number[ed->view_of] : op_number[ed->total_index];
			GB_ASSERT(idx >= 0);
			asm_string = gb_string_append_fmt(asm_string, "$%d", idx);
		case_end;
		case_ast_node(mem_op, AsmMemoryOperand, op);
			asm_string = this->write_memory_operand(asm_string, op_number, mem_op, flags&~WriteOperandFlag_PrintPrefixes);
		case_end;
		case_ast_node(bl, BasicLit, op);
			GB_PANIC("NOTE(bill): this should have been handled above");
		case_end;
		case_ast_node(label, AsmLabelDecl, op);
			asm_string = write_label(asm_string, &label->name->Ident);
		case_end;
		case_ast_node(reg, AsmRegister, op);
			// RISC-V names registers bare (zero, a0, fa0); no '%' prefix.
			asm_string = gb_string_append_length(asm_string, reg->name.string.text, reg->name.string.len);
		case_end;
		default:
			GB_PANIC("TODO(bill): write_operand for '%s'", expr_to_string(op));
			break;
		}
		return asm_string;
	}

	// RISC-V addressing is `offset(base)`: a signed 12-bit displacement plus one base
	// register. No index register, scale factor, or segment override exists.
	gbString write_memory_operand(gbString asm_string, Slice<i32> const &op_number, AstAsmMemoryOperand *mem_op, u32 flags) override {
		GB_ASSERT_MSG(mem_op->segment_override == nullptr, "asm: RISC-V has no segment overrides");
		GB_ASSERT_MSG(mem_op->index == nullptr && mem_op->scale == nullptr, "asm: RISC-V memory operands have no index/scale");

		if (mem_op->disp) {
			u32 disp_flags = flags & ~WriteOperandFlag_PrintPrefixes;
			if (mem_op->disp_op.kind == Token_Sub) {
				disp_flags |= WriteOperandFlag_Negate;
			}
			asm_string = this->write_operand(asm_string, op_number, mem_op->disp, disp_flags);
		}
		asm_string = gb_string_appendc(asm_string, "(");
		if (mem_op->base != nullptr) {
			asm_string = this->write_operand(asm_string, op_number, mem_op->base, flags&~WriteOperandFlag_PrintPrefixes);
		}
		asm_string = gb_string_appendc(asm_string, ")");
		return asm_string;
	}

	// RISC-V mnemonics are spelled with '.' (fmadd.s, fmv.w.x, lr.w). Odin identifiers
	// cannot contain '.', so they are written with '_' and translated back here. No
	// real RISC-V mnemonic contains an underscore, so this mapping is unambiguous.
	gbString append_riscv_mnemonic(gbString s, String name) {
		for (isize i = 0; i < name.len; i++) {
			char c = cast(char)name.text[i];
			if (c == '_') {
				c = '.';
			}
			s = gb_string_append_length(s, &c, 1);
		}
		return s;
	}

	lbValue emit_call(lbProcedure *p, Array<lbValue> const &args) override {
		lbModule *m = p->module;
		LLVMContextRef ctx = m->ctx;

		gbString asm_string  = gb_string_make_reserve(heap_allocator(), 256);
		gbString constraints = gb_string_make_reserve(heap_allocator(), 64);
		defer ({
			gb_string_free(constraints);
			gb_string_free(asm_string);
		});

		TEMPORARY_ALLOCATOR_GUARD();

		auto param_types = array_make<LLVMTypeRef> (temporary_allocator(), 0, ops->count);
		auto call_args   = array_make<LLVMValueRef>(temporary_allocator(), 0, ops->count);
		auto ret_types   = array_make<LLVMTypeRef> (temporary_allocator(), 0, ops->count);

		auto op_number = slice_make<i32>(temporary_allocator(), ops->count); // $N, or -1 for clobbers/views
		auto ret_slot  = slice_make<i32>(temporary_allocator(), ops->count); // return-struct index, or -1
		for_array(i, *ops) {
			op_number[i] = -1;
			ret_slot [i] = -1;
		}

		struct ElemAttr {
			unsigned arg_pos;
			LLVMTypeRef elem;
		};
		auto elem_attrs = array_make<ElemAttr>(temporary_allocator(), 0, ops->count);

		auto sep = [&]() {
			if (gb_string_length(constraints) != 0) {
				constraints = gb_string_appendc(constraints, ",");
			}
		};
		auto raw = [&](char const *s) {
			constraints = gb_string_appendc(constraints, s);
		};
		auto clobber = [&](char const *start, String mid, char const *end) {
			constraints = gb_string_appendc(constraints, start);
			constraints = gb_string_append_length(constraints, mid.text, mid.len);
			constraints = gb_string_appendc(constraints, end);
		};

		auto add_input_value = [](Array<LLVMTypeRef> *param_types, Array<LLVMValueRef> *call_args, LLVMValueRef v) {
			array_add(param_types, LLVMTypeOf(v));
			array_add(call_args, v);
		};

		i32 next_op = 0; // running $N counter (outputs first, then inputs)

		// Pass 1: outputs (real outputs + unpinned register scratch modeled as
		// discarded early-clobber outputs).
		for_array(i, *ops) {
			AsmTemplateEntityDecl const &e = (*ops)[i];

			if (e.view_of >= 0) {
				continue; // width-view: resolved to its source's operand, owns no slot
			}

			// A flag output cannot occur on RISC-V (no condition-flags register), but
			// keep the branch for structural parity; flag_output_cc_suffix returns {}
			// so it is never actually taken.
			if (e.param_group == AsmTemplateEntityDeclParamGroup_Output && e.pin_flag.len != 0) {
				GB_ASSERT_MSG(false, "asm: RISC-V has no flag outputs");
			}

			bool is_output        = e.param_group == AsmTemplateEntityDeclParamGroup_Output;
			bool is_alloc_scratch = e.param_group == AsmTemplateEntityDeclParamGroup_Scratch
			                     && e.kind == AsmTemplateEntityDecl_Register;
			if (!is_output && !is_alloc_scratch) {
				continue;
			}

			sep();

			raw("=");
			if (is_alloc_scratch || tmpl_node->instructions.count > 1) {
				raw("&");
			}
			if (e.pin.len != 0) {
				clobber("{", e.pin, "}");
			} else {
				raw(this->class_letter(e.reg_class));
			}

			LLVMTypeRef ty = is_alloc_scratch ? lb_type(m, e.entity->type) : this->output_llvm_type(m, e);

			ret_slot[i] = cast(i32)ret_types.count;
			array_add(&ret_types, ty);
			op_number[i] = next_op++;
		}

		// Pass 2: inputs
		for_array(i, *ops) {
			AsmTemplateEntityDecl const &e = (*ops)[i];

			if (e.view_of >= 0) {
				continue; // width-view: not its own input
			}
			if (e.param_group != AsmTemplateEntityDeclParamGroup_Input) {
				continue;
			}

			sep();
			lbValue v = args[e.param_index];

			if (e.tie >= 0) {
				i32 n = op_number[e.tie];
				GB_ASSERT(n >= 0);
				constraints = gb_string_append_fmt(constraints, "%d", n);
				add_input_value(&param_types, &call_args, v.value);
			} else {
				switch (e.kind) {
				case AsmTemplateEntityDecl_Register:
				case AsmTemplateEntityDecl_Memory:
					if (e.pin.len != 0) {
						clobber("{", e.pin, "}");
					} else {
						raw(this->class_letter(e.reg_class));
					}
					add_input_value(&param_types, &call_args, v.value);
					break;
				case AsmTemplateEntityDecl_Immediate:
					raw("i");
					add_input_value(&param_types, &call_args, v.value);
					break;
				default:
					GB_PANIC("asm: invalid input operand kind");
				}
			}
			op_number[i] = next_op++;
		}

		// Build the template text
		for_array(i, tmpl_node->instructions) {
			if (i > 0) {
				asm_string = gb_string_appendc(asm_string, "\n");
			}
			Ast *instr_ = tmpl_node->instructions[i];
			switch (instr_->kind) {
			case_ast_node(instr, AsmInstruction, instr_);
				asm_string = gb_string_appendc(asm_string, "\t");
				String name = instr->name->Ident.token.string;
				asm_string = this->append_riscv_mnemonic(asm_string, name);

				asm_string = gb_string_appendc(asm_string, " ");
				// RISC-V is destination-first natively; emit operands in written order.
				for (isize j = 0; j < instr->operands.count; j += 1) {
					Ast *op = instr->operands[j];
					if (j > 0) {
						asm_string = gb_string_appendc(asm_string, ", ");
					}
					asm_string = this->write_operand(asm_string, op_number, op, WriteOperandFlag_NONE);
				}
			case_end;
			case_ast_node(label, AsmLabelDecl, instr_);
				asm_string = this->write_label(asm_string, &label->name->Ident);
				asm_string = gb_string_appendc(asm_string, ":");
			case_end;
			case_ast_node(dir, AsmDirective, instr_);
				String name = dir->name.string;
				if (name == "byte") {
					asm_string = gb_string_appendc(asm_string, ".byte ");
					isize op_index = 0;
					for (auto const &op : dir->operands) {
						if (op_index > 0) {
							asm_string = gb_string_appendc(asm_string, ", ");
						}
						ExactValue ev = exact_value_to_integer(op->tav.value);
						GB_ASSERT(ev.kind == ExactValue_Integer);
						i64 v = exact_value_to_i64(ev);
						asm_string = gb_string_append_fmt(asm_string, "%d", cast(int)v);
						op_index += 1;
					}
				} else if (name == "align") {
					GB_ASSERT(dir->operands.count == 1);
					auto const &op = dir->operands[0];
					ExactValue ev = exact_value_to_integer(op->tav.value);
					GB_ASSERT(ev.kind == ExactValue_Integer);
					u64 v = exact_value_to_u64(ev);
					u64 v_log2 = floor_log2(v);
					asm_string = gb_string_append_fmt(asm_string, ".p2align %llu", cast(unsigned long long)v_log2);
				} else if (name == "skip") {
					GB_ASSERT(dir->operands.count == 1);
					auto const &op = dir->operands[0];
					ExactValue ev = exact_value_to_integer(op->tav.value);
					GB_ASSERT(ev.kind == ExactValue_Integer);
					u64 v = exact_value_to_u64(ev);
					asm_string = gb_string_append_fmt(asm_string, ".skip %llu", cast(unsigned long long)v);
				} else if (name == "nop") {
					GB_ASSERT(dir->operands.count == 1);
					auto const &op = dir->operands[0];
					ExactValue ev = exact_value_to_integer(op->tav.value);
					GB_ASSERT(ev.kind == ExactValue_Integer);
					u64 v = exact_value_to_u64(ev);
					asm_string = gb_string_append_fmt(asm_string, ".nops %llu", cast(unsigned long long)v);
				} else {
					GB_PANIC("Invalid asm directive: %.*s", LIT(name));
				}
			case_end;
			default:
				GB_PANIC("Invalid asm instruction");
				break;
			}
		}

		bool memory_clobbered_already = false;
		// Pass 3: clobbers (Scratch group only; unpinned register scratch already
		// emitted as an output in Pass 1).
		StringSet emitted_reg_clobbers = {};
		string_set_init(&emitted_reg_clobbers);
		defer (string_set_destroy(&emitted_reg_clobbers));

		for_array(i, *ops) {
			AsmTemplateEntityDecl const &e = (*ops)[i];

			if (e.view_of >= 0) {
				continue; // width-view carries no clobber; its source owns the register
			}
			if (e.param_group != AsmTemplateEntityDeclParamGroup_Scratch) {
				continue;
			}
			if (e.kind == AsmTemplateEntityDecl_Register && e.pin.len == 0) {
				continue;
			}

			sep();
			switch (e.kind) {
			case AsmTemplateEntityDecl_Register:
				GB_ASSERT(e.pin.len != 0);
				clobber("~{", e.pin, "}");
				string_set_update(&emitted_reg_clobbers, e.pin);
				break;
			case AsmTemplateEntityDecl_Memory:
				raw("~{memory}");
				memory_clobbered_already = true;
				break;
			default:
				GB_PANIC("asm: invalid scratch operand kind");
			}
		}

		for (String const &reg : tmpl_entity->AsmTemplate.clobber_registers_set) {
			if (string_set_exists(&emitted_reg_clobbers, reg)) {
				continue;
			}
			sep();
			clobber("~{", reg, "}");
			string_set_update(&emitted_reg_clobbers, reg);
		}

		// RISC-V has no condition-flags/cc register, so #clobber flags maps to nothing.
		// (clobber_flags being set here is effectively a no-op.)

		if (tmpl_entity->AsmTemplate.clobber_memory && !memory_clobbered_already) {
			sep();
			raw("~{memory}");
		}

		// Build the callee type
		LLVMTypeRef ret_ty = nullptr;
		if (ret_types.count == 0) {
			ret_ty = LLVMVoidTypeInContext(ctx);
		} else if (ret_types.count == 1) {
			ret_ty = ret_types[0];
		} else {
			ret_ty = LLVMStructTypeInContext(ctx, ret_types.data, cast(unsigned)ret_types.count, /*packed*/false);
		}

		LLVMTypeRef fn_ty = LLVMFunctionType(ret_ty, param_types.data, cast(unsigned)param_types.count, /*vararg*/false);

		LLVMValueRef ia = LLVMGetInlineAsm(
			fn_ty,
			asm_string,  cast(size_t)gb_string_length(asm_string),
			constraints, cast(size_t)gb_string_length(constraints),
			/*HasSideEffects*/ tmpl_entity->AsmTemplate.is_volatile,
			/*IsAlignStack*/   tmpl_entity->AsmTemplate.is_align_stack,
			LLVMInlineAsmDialectATT,
			/*CanThrow*/       false);

		LLVMValueRef call = LLVMBuildCall2(p->builder, fn_ty, ia, call_args.data, cast(unsigned)call_args.count, "");

		if (LLVM_ASM_DEBUG_PRINT) {
			gb_printf_err("%s\n", asm_string);
			char *ir = LLVMPrintValueToString(call);
			gb_printf_err("%s\n\n", ir);
			LLVMDisposeMessage(ir);
		}

		unsigned et_kind = LLVMGetEnumAttributeKindForName("elementtype", 11);
		for (auto const &elem_attr : elem_attrs) {
			LLVMAttributeRef attr = LLVMCreateTypeAttribute(ctx, et_kind, elem_attr.elem);
			LLVMAddCallSiteAttribute(call, cast(LLVMAttributeIndex)(elem_attr.arg_pos + 1), attr);
		}

		// Repackage results in Odin result order
		Type *pt = base_type(tmpl_entity->type);
		isize result_count = 0;
		if (pt->Proc.results != nullptr) {
			result_count = pt->Proc.results->Tuple.variables.count;
		}
		if (result_count == 0) {
			return lbValue{};
		}

		auto result_vals = slice_make<LLVMValueRef>(temporary_allocator(), result_count);

		for_array(i, *ops) {
			AsmTemplateEntityDecl const &e = (*ops)[i];
			if (e.view_of >= 0) {
				continue;
			}
			if (e.param_group != AsmTemplateEntityDeclParamGroup_Output) {
				continue;
			}
			if (e.result_index < 0) {
				continue; // memory output: not a returned value
			}
			GB_ASSERT(ret_slot[i] >= 0);

			LLVMValueRef v = call;
			if (ret_types.count != 1) {
				v = LLVMBuildExtractValue(p->builder, call, cast(unsigned)ret_slot[i], "");
			}
			result_vals[e.result_index] = v;
		}

		if (result_count == 1) {
			Type *rt = pt->Proc.results->Tuple.variables[0]->type;
			return lbValue{result_vals[0], rt};
		}

		Type *results_type = pt->Proc.results;
		LLVMValueRef agg = LLVMGetUndef(lb_type(m, results_type));
		for_array(i, result_vals) {
			GB_ASSERT(result_vals[i] != nullptr);
			agg = LLVMBuildInsertValue(p->builder, agg, result_vals[i], cast(unsigned)i, "");
		}

		return lbValue{agg, results_type};
	}
};


gb_internal lbValue lb_emit_asm_template_call(lbProcedure *p, Entity *entity, Array<lbValue> const &args) {
	lbAsmGenerate_amd64   generator_amd64   = {};
	lbAsmGenerate_riscv64 generator_riscv64 = {};
	lbAsmGenerate *generator = nullptr;
	if (build_context.metrics.arch == TargetArch_amd64) {
		generator = &generator_amd64;
	} else if (build_context.metrics.arch == TargetArch_riscv64) {
		generator = &generator_riscv64;
	} else {
		compiler_error("Architecture does not support asm templates, yet");
	}
	GB_ASSERT(generator != nullptr);
	generator->init(entity);
	return generator->emit_call(p, args);
}