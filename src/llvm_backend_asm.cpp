#define LLVM_ASM_DEBUG_PRINT false

struct lbAsmGenerate {
	Entity *                      tmpl_entity;
	AstAsmTemplate *              tmpl_node;
	Array<AsmTemplateEntityDecl> *ops;

	gbString asm_string;
	gbString constraints;

	// Stable per-template numbering for internal labels (assigned on first sight).
	PtrMap<Entity *, i32> label_numbers;
	i32                   next_label_number;
	PtrMap<Entity *, i32> label_def_pos;

	AstAsmInstruction *   curr_instr;
	isize                 curr_operand_index;
	i32                   curr_instr_pos;
	Array<lbValue> const *curr_args;

	enum WriteOperandFlags : u32 {
		WriteOperandFlag_PrintPrefixes  = 1<<0,
		WriteOperandFlag_IsScale        = 1<<1,
		WriteOperandFlag_IsScaleLog2    = 1<<2,

		WriteOperandFlag_Negate         = 1<<3,

		WriteOperandFlag_IndirectBranch = 1<<4,

		WriteOperandFlag_MemoryDisp     = 1<<5,

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

		this->asm_string  = gb_string_make_reserve(heap_allocator(), 256);
		this->constraints = gb_string_make_reserve(heap_allocator(), 64);
		map_init(&this->label_numbers);
	}

	void destroy() {
		gb_string_free(this->asm_string);
		gb_string_free(this->constraints);
		map_destroy(&this->label_numbers);
		map_destroy(&this->label_def_pos);
	}

	void write_cstr(char const *cstr) { asm_string = gb_string_appendc      (asm_string, cstr);                                }
	void write_char(char c)           { asm_string = gb_string_append_length(asm_string, &c, 1);                               }
	void write_string(String str)     { asm_string = gb_string_append_length(asm_string, str.text, str.len);                   }
	void write_int(int val)           { asm_string = gb_string_append_fmt   (asm_string, "%d",   cast(int)val);                }
	void write_u64(u64 val)           { asm_string = gb_string_append_fmt   (asm_string, "%llu", cast(unsigned long long)val); }
	void write_i64(i64 val)           { asm_string = gb_string_append_fmt   (asm_string, "%lld", cast(long long)val);          }

	// AArch64's assembler requires conditional-branch targets to be assembler-local.
	// Named .L symbols are treated as external within an inline-asm string, so use
	// numeric locals: each label entity gets a small integer, a definition prints
	// `N:`, and a reference prints `Nf` (forward) or `Nb` (backward). For targets
	// that don't need this (amd64), the named form is still fine; this base method
	// is overridden per target.
	virtual void write_label_def(AstIdent *label_ident) {
		String name = label_ident->token.string;
		write_cstr(".L_");
		write_string(tmpl_entity->token.string);
		write_cstr("_");
		write_string(name);
		write_cstr("${:uid}");
	}
	virtual void write_label_ref(AstIdent *label_ident) {
		this->write_label_def(label_ident); // default: same spelling for def and ref
	}

	void write_label(AstIdent *label_ident) {
		this->write_label_ref(label_ident);
	}

	virtual void prescan_label_positions() {
		// do nothing by default
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



	// LLVM type of a returned register output, taken from the proc signature's results.
	LLVMTypeRef output_llvm_type(lbModule *m, AsmTemplateEntityDecl const &e) {
		Type *pt = base_type(tmpl_entity->type);
		Type *rt = pt->Proc.results->Tuple.variables[e.result_index]->type;
		return lb_type(m, rt);
	}

	// The declared Odin result type for an output entity.
	Type *result_type_of(AsmTemplateEntityDecl const &e) {
		Type *pt = base_type(tmpl_entity->type);
		return pt->Proc.results->Tuple.variables[e.result_index]->type;
	}

	void sep() {
		if (gb_string_length(this->constraints) != 0) {
			this->constraints = gb_string_appendc(this->constraints, ",");
		}
	}
	void raw(char const *s) {
		this->constraints = gb_string_appendc(this->constraints, s);
	}
	void clobber(char const *start, String mid, char const *end) {
		this->constraints = gb_string_appendc      (this->constraints, start);
		this->constraints = gb_string_append_length(this->constraints, mid.text, mid.len);
		this->constraints = gb_string_appendc      (this->constraints, end);
	}
	void add_input_value(Array<LLVMTypeRef> *param_types, Array<LLVMValueRef> *call_args, LLVMValueRef v) {
		array_add(param_types, LLVMTypeOf(v));
		array_add(call_args, v);
	}

	lbValue emit_call(lbProcedure *p, Array<lbValue> const &args) {
		lbModule *m = p->module;
		LLVMContextRef ctx = m->ctx;

		gb_string_clear(this->asm_string);
		gb_string_clear(this->constraints);

		this->curr_args = &args;

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
			// Lowers to LLVM's `=@cc<suffix>` (i1). Takes a return-struct slot but is
			// never referenced in the body. On targets with no flags register,
			// flag_output_cc_suffix returns {} and the assert below fires (unreachable
			// in practice: the frontend cannot form a valid flag pin there).
			if (e.param_group == AsmTemplateEntityDeclParamGroup_Output && e.pin_flag.len != 0) {
				GB_ASSERT(e.pin == "flags");
				String suffix = this->flag_output_cc_suffix(e.pin_flag);
				GB_ASSERT_MSG(suffix.len != 0, "asm: flag '%.*s' has no setcc condition form", LIT(e.pin_flag));

				sep();
				clobber("={@cc", suffix, "}");

				ret_slot[i] = cast(i32)ret_types.count;
				array_add(&ret_types, LLVMInt8TypeInContext(ctx));

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
			// off an input's register. One instruction reads before it writes, so it is safe.
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
				case AsmTemplateEntityDecl_Immediate: {
					Type *ct = core_type(v.type);
					LLVMValueRef imm = v.value;
					if (is_type_float(ct)) {
						// NOTE(bill): No float-immediate constraint exists;
						// reinterpret the float's bits as an integer of the same width so
						// the 'i' (integer immediate) constraint applies. The bitcast of a
						// constant folds to a ConstantInt.
						Type *int_type = t_u32;
						switch (type_size_of(ct)) {
						case 2: int_type = t_u16; break;
						case 4: int_type = t_u32; break;
						case 8: int_type = t_u64; break;
						}
						imm = LLVMBuildBitCast(p->module->const_dummy_builder, v.value, lb_type(m, int_type), "");
					} else if (!is_type_integer(ct) && !is_type_pointer(ct) && !is_type_boolean(ct)) {
						error(e.entity->token, "asm immediate operand '%.*s' must be an integer-typed constant, got %s",
						      LIT(e.entity->token.string), type_to_string(v.type));
					}
					raw("i");
					add_input_value(&param_types, &call_args, imm);
					break;
				}
				default:
					GB_PANIC("asm: invalid input operand kind");
					break;
				}
			}
			op_number[i] = next_op++;
		}

		// AArch64 uses numeric local labels for internal branches; resolve each label's
		// definition position up front so references can pick f/b correctly.
		this->prescan_label_positions();

		// Build the template text
		u32 op_flags = this->default_operand_write_flags();
		bool reverse = this->reverse_operand_order();
		for_array(i, tmpl_node->instructions) {
			this->curr_instr_pos = cast(i32)i;

			if (i > 0) {
				write_cstr("\n");
			}
			Ast *instr_ = tmpl_node->instructions[i];
			switch (instr_->kind) {
			case_ast_node(instr, AsmInstruction, instr_);
				write_cstr("\t");
				this->write_instruction_mnemonic(instr);
				write_cstr(" ");

				bool indirect = this->is_indirect_control_transfer(instr); // call/jmp with reg|mem target slot

				isize n = instr->operands.count;
				for (isize k = 0; k < n; k += 1) {
					isize j = reverse ? (n-1-k) : k;
					if (k > 0) { write_cstr(", "); }
					u32 f = op_flags;
					if (indirect) f |= WriteOperandFlag_IndirectBranch;
					this->curr_instr = instr;
					this->curr_operand_index = j;
					this->write_operand(op_number, instr->operands[j], f);
				}
			case_end;
			case_ast_node(label, AsmLabelDecl, instr_);
				this->write_label_def(&label->name->Ident);
			case_end;
			case_ast_node(dir, AsmDirective, instr_);
				String name = dir->name.string;
				if (name == "byte") {
					write_cstr(".byte ");
					isize op_index = 0;
					for (auto const &op : dir->operands) {
						if (op_index > 0) {
							write_cstr(", ");
						}
						ExactValue ev = exact_value_to_integer(op->tav.value);
						GB_ASSERT(ev.kind == ExactValue_Integer);
						i64 v = exact_value_to_i64(ev);
						write_int(cast(int)v);
						op_index += 1;
					}
				} else if (name == "align") {
					GB_ASSERT(dir->operands.count == 1);
					auto const &op = dir->operands[0];
					ExactValue ev = exact_value_to_integer(op->tav.value);
					GB_ASSERT(ev.kind == ExactValue_Integer);
					u64 v = exact_value_to_u64(ev);
					write_cstr(".p2align ");
					write_u64(floor_log2(v));
				} else if (name == "skip") {
					GB_ASSERT(dir->operands.count == 1);
					auto const &op = dir->operands[0];
					ExactValue ev = exact_value_to_integer(op->tav.value);
					GB_ASSERT(ev.kind == ExactValue_Integer);
					write_cstr(".skip ");
					write_u64(exact_value_to_u64(ev));
				} else if (name == "nop") {
					GB_ASSERT(dir->operands.count == 1);
					auto const &op = dir->operands[0];
					ExactValue ev = exact_value_to_integer(op->tav.value);
					GB_ASSERT(ev.kind == ExactValue_Integer);
					write_cstr(".nops ");
					write_u64(exact_value_to_u64(ev));
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
				continue;
			}
			sep();
			clobber("~{", reg, "}");
			string_set_update(&emitted_reg_clobbers, reg);
		}

		// Template-level clobbers derived from #clobber flags / #clobber memory.
		if (tmpl_entity->AsmTemplate.clobber_flags) {
			this->emit_flags_clobber();
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
			gb_printf_err("%s\n", asm_string);
			char *ir = LLVMPrintValueToString(call);
			gb_printf_err("%s\n\n", ir);
			LLVMDisposeMessage(ir);
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
				v = LLVMBuildExtractValue(p->builder, call, cast(unsigned)ret_slot[i], "");
			}

			// A flag output is delivered as i8; coerce it to the declared result type.
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
				}
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


	// Operand-write flags for the template body. amd64 wants prefixes ('$$', '%');
	// riscv64 wants none. Kept explicit rather than relying on the riscv overrides
	// happening to ignore the prefix bit.
	virtual u32 default_operand_write_flags() {
		return WriteOperandFlag_DEFAULT;
	}

	// #clobber flags -> target constraint fragment. Default: nothing (RISC-V has no
	// architectural condition-code register). amd64 overrides with the x86 triple.
	virtual void emit_flags_clobber() {
		// empty
	}


	virtual bool        is_indirect_control_transfer(AstAsmInstruction *instr)                                            = 0;
	virtual char const *class_letter                (AsmRegClass rc)                                                      = 0;
	virtual void        write_constant_operand      (Ast *op, u32 flags)                                                  = 0;
	virtual void        write_operand               (Slice<i32> const &op_number, Ast *op, u32 flags)                     = 0;
	virtual bool        reverse_operand_order       ()                                                                    = 0; // Intel dst-first -> AT&T src-first?
	virtual void        write_instruction_mnemonic  (AstAsmInstruction *instr)                                            = 0; // name (+ any suffix / spelling fixup)
	virtual void        write_memory_operand        (Slice<i32> const &op_number, AstAsmMemoryOperand *mem_op, u32 flags) = 0;
	virtual String      flag_output_cc_suffix       (String const &pin_flag)                                              = 0;

};

struct lbAsmGenerate_amd64 : lbAsmGenerate {
	bool reverse_operand_order() override {
		return true;
	}

	u32 default_operand_write_flags() override {
		return WriteOperandFlag_DEFAULT;
	}

	void emit_flags_clobber() override {
		// NOTE(bill): clang's canonical x86 flags clobber
		sep(); raw("~{dirflag}");
		sep(); raw("~{fpsr}");
		sep(); raw("~{flags}");
	}


	char const *class_letter(AsmRegClass rc) override {
		switch (rc) {
		case AsmRegClass_Integer: return "r";
		case AsmRegClass_Float:   return "x";   // x86 XMM
		case AsmRegClass_Vector:  return "x";
		case AsmRegClass_Mask:    return "^Yk"; // AVX-512 k-regs
		default:
			GB_PANIC("asm: unknown reg class");
			return "r";
		}
	}

	bool is_indirect_control_transfer(AstAsmInstruction *instr) override {
		switch (instr->mnemonic) {
			case Asm_amd64::M_CALL:
			case Asm_amd64::M_JMP:
				break;
			default:
			return false;
		}
		auto forms = g_asm_amd64.encoding_forms(instr->mnemonic);
		if (0 <= instr->valid_form_index && instr->valid_form_index < forms.count) {
			auto const &form = forms[instr->valid_form_index];
			// call/jmp take a single explicit target operand.
			AsmOperandKind k = g_asm_amd64.kind_from_operand_type(form.ops[0]);
			switch (k) {
			case AsmOperand_Register:
			case AsmOperand_Memory:
			case AsmOperand_Register_Or_Memory:
				return true;
			}
		}
		return false;
	}

	void write_instruction_mnemonic(AstAsmInstruction *instr) override {
		String name = instr->name->Ident.token.string;
		String att = this->instruction_att_mnemonic(instr);
		if (att.len != 0) {
			write_string(att);
			return;
		}
		write_string(name);
		if (char suffix = this->instruction_size_suffix(instr)) {
			write_char(suffix);
		}
	}

	void write_constant_operand(Ast *op, u32 flags) override {
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
				write_cstr("$$");
			}
			if (flags & WriteOperandFlag_Negate) {
				val = -val;
			}
			write_int(cast(int)val);
			break;
		}
		case ExactValue_Float:
			error(op, "Floating-point literals that cannot be represented as an integer are not supported within asm operands");
			break;
		default:
			GB_PANIC("Unsupported asm immediate literal %s", expr_to_string(op));
			break;
		}
	}

	void write_memory_operand(Slice<i32> const &op_number, AstAsmMemoryOperand *mem_op, u32 flags) override {
		if (mem_op->segment_override != nullptr) {
			this->write_operand(op_number, mem_op->segment_override, flags);
			write_cstr(":");
		}

		if (mem_op->disp) {
			u32 disp_flags = (flags & ~WriteOperandFlag_PrintPrefixes) | WriteOperandFlag_MemoryDisp;
			if (mem_op->disp_op.kind == Token_Sub) {
				disp_flags |= WriteOperandFlag_Negate;
			}
			this->write_operand(op_number, mem_op->disp, disp_flags);
		}
		if (mem_op->base == nullptr && mem_op->index == nullptr) {
			GB_ASSERT(mem_op->scale == nullptr);
			return;
		}
		write_cstr("(");
		if (mem_op->base != nullptr) {
			this->write_operand(op_number, mem_op->base, flags);
		}
		if (mem_op->index) {
			u32 index_flags = flags;
			if (mem_op->index_op.kind == Token_Sub) {
				index_flags |= WriteOperandFlag_Negate;
			}
			write_cstr(",");
			this->write_operand(op_number, mem_op->index, index_flags);

			if (mem_op->scale) {
				write_cstr(",");
				switch (mem_op->scale_op.kind) {
				case Token_Mul:
					this->write_operand(op_number, mem_op->scale, (flags|WriteOperandFlag_IsScale)&~WriteOperandFlag_PrintPrefixes);
					break;
				case Token_Shl:
				case Token_Shr:
					this->write_operand(op_number, mem_op->scale, (flags|WriteOperandFlag_IsScaleLog2)&~WriteOperandFlag_PrintPrefixes);
					break;
				}
			}
		}
		write_cstr(")");
	}

	void write_operand(Slice<i32> const &op_number, Ast *op, u32 flags) override {
		if (op->tav.mode == Addressing_Constant) {
			this->write_constant_operand(op, flags);
			return;
		}

		if (flags & WriteOperandFlag_IndirectBranch) {
			flags &= ~WriteOperandFlag_IndirectBranch;
			write_cstr("*");
		}

		if (flags & WriteOperandFlag_Negate) {
			flags &= ~WriteOperandFlag_Negate;
			write_cstr("-");
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
				case 8:  mod = 'b'; break;
				case 16: mod = 'w'; break;
				case 32: mod = 'k'; break;
				case 64: mod = 'q'; break;
				default: GB_PANIC("asm: invalid width-view size %d", ed->view_bits); break;
				}
				asm_string = gb_string_append_fmt(asm_string, "${%d:%c}", idx, mod);
			} else {
				i32 idx = op_number[ed->total_index];
				GB_ASSERT(idx >= 0);
				if (flags & WriteOperandFlag_MemoryDisp) {
					GB_ASSERT(ed->kind == AsmTemplateEntityDecl_Immediate);
					asm_string = gb_string_append_fmt(asm_string, "${%d:c}", idx);
				} else {
					asm_string = gb_string_append_fmt(asm_string, "$%d", idx);
				}
			}
		case_end;
		case_ast_node(mem_op, AsmMemoryOperand, op);
			this->write_memory_operand(op_number, mem_op, flags&~WriteOperandFlag_PrintPrefixes);
		case_end;
		case_ast_node(bl, BasicLit, op);
			GB_PANIC("NOTE(bill): this should have been handled above");
		case_end;
		case_ast_node(label, AsmLabelDecl, op);
			this->write_label(&label->name->Ident);
		case_end;
		case_ast_node(reg, AsmRegister, op);
			write_cstr("%");
			write_string(reg->name.string);
		case_end;
		default:
			GB_PANIC("TODO(bill): write_operand for '%s'", expr_to_string(op));
			break;
		}
	}

	String flag_output_cc_suffix(String const &pin_flag) override {
		if (pin_flag == "c") return str_lit("c");
		if (pin_flag == "p") return str_lit("p");
		if (pin_flag == "z") return str_lit("z");
		if (pin_flag == "s") return str_lit("s");
		if (pin_flag == "o") return str_lit("o");
		return {};
	}

	char size_suffix_for_operand(Ast *op) {
		if (op->kind != Ast_AsmMemoryOperand) {
			return 0;
		}
		AstAsmMemoryOperand *mem_op = &op->AsmMemoryOperand;
		if (mem_op->type == nullptr) {
			return 0;
		}
		Type *ptr = mem_op->type->tav.type;
		if (ptr == nullptr) {
			return 0;
		}
		Type *access = type_deref(ptr);
		i64 sz = type_size_of(base_type(access));
		switch (sz) {
		case 1: return 'b';
		case 2: return 'w';
		case 4: return 'l';
		case 8: return 'q';
		}
		return 0;
	}

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
		if (0 <= instr->valid_form_index && instr->valid_form_index < forms.count) {
			auto const &form = forms[instr->valid_form_index];

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
		}
		return {};
	}

	char instruction_size_suffix(AstAsmInstruction *instr) {
		for (Ast *operand : instr->operands) {
			char s = this->size_suffix_for_operand(operand);
			if (s != 0) {
				return s;
			}
		}
		if (instr->mnemonic == 0) {
			// Ignore bare prefix lines
			return 0;
		}
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
				return 0;
			}
			AsmOperandKind kind = g_asm_amd64.kind_from_operand_type(ot);
			if (kind != AsmOperand_Register &&
			    kind != AsmOperand_Memory &&
			    kind != AsmOperand_Register_Or_Memory) {
				continue;
			}
			i32 w = g_asm_amd64.operand_type_bit_width(ot);
			if (w == 8 || w == 16 || w == 32 || w == 64) {
				width = gb_max(width, w);
			}
		}

		switch (width) {
		case 8:  return 'b';
		case 16: return 'w';
		case 32: return 'l';
		case 64: return 'q';
		}
		return 0;
	}
};

struct lbAsmGenerate_riscv64 : lbAsmGenerate {
	bool reverse_operand_order() override {
		return false;
	}

	u32 default_operand_write_flags() override {
		return WriteOperandFlag_NONE;
	}

	// LLVM inline-asm constraint class letters for RISC-V.
	char const *class_letter(AsmRegClass rc) override {
		switch (rc) {
		case AsmRegClass_Integer: return "r";  // GPR
		case AsmRegClass_Float:   return "f";  // FPR (single/double share the FLEN file)
		case AsmRegClass_Vector:  return "vr"; // RVV vector register
		case AsmRegClass_Mask:    return "vm"; // RVV mask register (v0)
		default:
			GB_PANIC("asm: unknown reg class");
			return "r";
		}
	}

	bool is_indirect_control_transfer(AstAsmInstruction *instr) override {
		return false;
	}

	// RISC-V immediates are bare integers (no '$' prefix); no scale/log2 forms exist.
	void write_constant_operand(Ast *op, u32 flags) override {
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
			this->write_i64(val);
			break;
		}
		case ExactValue_Float:
			error(op, "Floating-point literals that cannot be represented as an integer are not supported within asm operands");
			break;
		default:
			GB_PANIC("Unsupported asm immediate literal %s", expr_to_string(op));
			break;
		}
	}

	// Bare registers, bare immediates, no sub-register width modifiers.
	void write_operand(Slice<i32> const &op_number, Ast *op, u32 flags) override {
		if (op->tav.mode == Addressing_Constant) {
			this->write_constant_operand(op, flags);
			return;
		}
		if (flags & WriteOperandFlag_Negate) {
			flags &= ~WriteOperandFlag_Negate;
			write_cstr("-");
		}
		switch (op->kind) {
		case_ast_node(i, Ident, op);
			Entity *e = entity_of_node(op);
			auto *ed = entity_op(e);
			// x-registers are always XLEN-wide with no named sub-registers, so a
			// width-view is just the same register: emit the source operand number.
			i32 idx = (ed->view_of >= 0) ? op_number[ed->view_of] : op_number[ed->total_index];
			GB_ASSERT(idx >= 0);
			asm_string = gb_string_append_fmt(asm_string, "$%d", idx);
		case_end;
		case_ast_node(mem_op, AsmMemoryOperand, op);
			this->write_memory_operand(op_number, mem_op, flags&~WriteOperandFlag_PrintPrefixes);
		case_end;
		case_ast_node(bl, BasicLit, op);
			GB_PANIC("NOTE(bill): this should have been handled above");
		case_end;
		case_ast_node(label, AsmLabelDecl, op);
			this->write_label(&label->name->Ident);
		case_end;
		case_ast_node(reg, AsmRegister, op);
			this->write_string(reg->name.string); // bare (zero, a0, fa0)
		case_end;
		default:
			GB_PANIC("TODO(bill): write_operand for '%s'", expr_to_string(op));
			break;
		}
	}

	// RISC-V addressing is `offset(base)`: signed 12-bit displacement + one base reg.
	void write_memory_operand(Slice<i32> const &op_number, AstAsmMemoryOperand *mem_op, u32 flags) override {
		GB_ASSERT_MSG(mem_op->segment_override == nullptr, "asm: RISC-V has no segment overrides");
		GB_ASSERT_MSG(mem_op->index == nullptr && mem_op->scale == nullptr, "asm: RISC-V memory operands have no index/scale");

		if (mem_op->disp) {
			u32 disp_flags = flags & ~WriteOperandFlag_PrintPrefixes;
			if (mem_op->disp_op.kind == Token_Sub) {
				disp_flags |= WriteOperandFlag_Negate;
			}
			this->write_operand(op_number, mem_op->disp, disp_flags);
		}
		write_cstr("(");
		if (mem_op->base != nullptr) {
			this->write_operand(op_number, mem_op->base, flags&~WriteOperandFlag_PrintPrefixes);
		}
		write_cstr(")");
	}

	// No condition-flags register, so no flag output can exist.
	String flag_output_cc_suffix(String const &pin_flag) override {
		return {};
	}

	// Mnemonics are spelled with '.' (fmadd.s, fmv.w.x); Odin identifiers use '_'.
	void write_instruction_mnemonic(AstAsmInstruction *instr) override {
		String name = instr->name->Ident.token.string;
		for (isize i = 0; i < name.len; i++) {
			char c = cast(char)name.text[i];
			write_char(c == '_' ? '.' : c);
		}
	}
};

struct lbAsmGenerate_arm64 : lbAsmGenerate {
	void prescan_label_positions() override {
		map_init(&label_def_pos);
		i32 pos = 0;
		for (Ast *node : tmpl_node->instructions) {
			if (node->kind == Ast_AsmLabelDecl) {
				Entity *le = node->AsmLabelDecl.name->Ident.entity;
				if (le != nullptr) {
					map_set(&label_def_pos, le, pos);
				}
			}
			pos += 1; // count every node so refs can compare positions consistently
		}
	}

	i32 arm64_label_number(AstIdent *label_ident) {
		Entity *le = label_ident->entity;
		GB_ASSERT(le != nullptr);
		if (i32 *n = map_get(&label_numbers, le)) {
			return *n;
		}
		if (next_label_number == 0) {
			map_init(&label_numbers);
		}
		i32 n = ++next_label_number; // 1-based; 0 reserved as "unassigned"
		map_set(&label_numbers, le, n);
		return n;
	}

	void write_label_def(AstIdent *label_ident) override {
		// Numeric local definition: `N:` — never an f/b suffix.
		asm_string = gb_string_append_fmt(asm_string, "%d:", this->arm64_label_number(label_ident));
	}
	void write_label_ref(AstIdent *label_ident) override {
		Entity *le = label_ident->entity;
		i32 n = this->arm64_label_number(label_ident);
		i32 def_pos = -1;
		if (i32 *p = map_get(&label_def_pos, le)) {
			def_pos = *p;
		}
		// Forward if the definition comes at or after the referencing instruction.
		// (A self/loop-top reference at the same position is backward once emitted;
		//  a branch to a label defined later is forward.)
		bool forward = def_pos > this->curr_instr_pos;
		asm_string = gb_string_append_fmt(asm_string, "%d%c", n, forward ? 'f' : 'b');
	}

	// ARM64 condition-code encodings -> mnemonic. csel/cset/ccmp/b.<cc> take the
	// bare mnemonic, NOT '#<n>'; the frontend resolves the cond to its 0..15 encoding.
	static char const *arm64_cond_name(i64 e) {
		static char const *n[16] = {
			"eq","ne","hs","lo","mi","pl","vs","vc",
			"hi","ls","ge","lt","gt","le","al","nv",
		};
		return (0 <= e && e < 16) ? n[e] : nullptr;
	}

	// Is user-operand `i` of this instruction the condition-code slot?
	bool arm64_is_cond_slot(AstAsmInstruction *instr, isize i) {
		if (instr->mnemonic == 0 || instr->valid_form_index < 0) {
			return false;
		}
		auto forms = g_asm_arm64.encoding_forms(instr->mnemonic);
		if (instr->valid_form_index >= forms.count) {
			return false;
		}
		auto const &form = forms[instr->valid_form_index];
		int slot = this->reverse_operand_order() ? cast(int)i : cast(int)i; // A64: no flip
		if (slot < 0 || slot >= cast(int)gb_count_of(form.ops)) {
			return false;
		}
		return g_asm_arm64.operand_type_is_cond_code(form.ops[slot]);
	}

	// The register-name modifier this *form slot* mandates, independent of the
	// operand's Odin type. ldrb/strb want W even for an i64 param; a 128-bit vector
	// load wants the Q name; scalar FP wants s/d. Returns 0 when bare $N is correct.
	char arm64_slot_reg_modifier(AstAsmInstruction *instr, isize i) {
		if (instr->mnemonic == 0 || instr->valid_form_index < 0) {
			return 0;
		}
		auto forms = g_asm_arm64.encoding_forms(instr->mnemonic);
		if (instr->valid_form_index >= forms.count) {
			return 0;
		}
		auto const &form = forms[instr->valid_form_index];
		if (i < 0 || i >= cast(isize)gb_count_of(form.ops)) {
			return 0;
		}
		auto slot = form.ops[i];
		AsmOperandKind k = g_asm_arm64.kind_from_operand_type(slot);
		if (k != AsmOperand_Register && k != AsmOperand_Register_Or_Memory) {
			return 0;
		}
		AsmRegClass cls = g_asm_arm64.operand_type_reg_class(slot);
		i32         w   = g_asm_arm64.operand_type_bit_width(slot);
		if (cls == AsmRegClass_Integer) {
			return (w == 32) ? 'w' : (w == 64) ? 'x' : 0;
		}
		if (cls == AsmRegClass_Float || cls == AsmRegClass_Vector) {
			switch (w) {
			case 8:   return 'b';
			case 16:  return 'h';
			case 32:  return 's';
			case 64:  return 'd';
			case 128: return 'q';
			}
		}
		return 0;
	}

	// NEON arrangement suffix (".4s", ".2d", ...) for a #simd operand in a slot that
	// wants a vector arrangement rather than a scalar name. Empty when not applicable.
	String arm64_arrangement_suffix(AstAsmInstruction *instr, isize i, Type *operand_type) {
		if (instr->mnemonic == 0 || instr->valid_form_index < 0) {
			return {};
		}
		auto forms = g_asm_arm64.encoding_forms(instr->mnemonic);
		if (instr->valid_form_index >= forms.count) {
			return {};
		}
		auto const &form = forms[instr->valid_form_index];
		if (i < 0 || i >= cast(isize)gb_count_of(form.ops)) {
			return {};
		}
		if (!g_asm_arm64.operand_type_wants_arrangement(form.ops[i])) {
			return {};
		}
		Type *bt = base_type(operand_type);
		if (bt->kind != Type_SimdVector) {
			return {};
		}
		i64 lanes = bt->SimdVector.count;
		i64 esz   = type_size_of(base_type(bt->SimdVector.elem));
		switch (esz) {
		case 1: return (lanes == 8)  ? str_lit(".8b")  : (lanes == 16) ? str_lit(".16b") : String{};
		case 2: return (lanes == 4)  ? str_lit(".4h")  : (lanes == 8)  ? str_lit(".8h")  : String{};
		case 4: return (lanes == 2)  ? str_lit(".2s")  : (lanes == 4)  ? str_lit(".4s")  : String{};
		case 8: return (lanes == 1)  ? str_lit(".1d")  : (lanes == 2)  ? str_lit(".2d")  : String{};
		}
		return {};
	}

	bool reverse_operand_order() override {
		return false;
	}

	// ARM64 immediates carry their own '#'; registers are bare. No AT&T-style
	// prefixes, so the generic PrintPrefixes bit is unused here.
	u32 default_operand_write_flags() override {
		return WriteOperandFlag_NONE;
	}

	// #clobber flags -> the ARM64 condition-code clobber (NZCV).
	void emit_flags_clobber() override {
		sep(); raw("~{cc}");
	}

	// LLVM inline-asm constraint class letters for ARM64.
	char const *class_letter(AsmRegClass rc) override {
		switch (rc) {
		case AsmRegClass_Integer: return "r";    // GPR (x/w)
		case AsmRegClass_Float:   return "w";    // FP/SIMD scalar (v/q/d/s/h/b)
		case AsmRegClass_Vector:  return "w";    // Advanced SIMD / SVE data vector
		case AsmRegClass_Mask:    return "^Upl"; // SVE governing predicate (p0-p7); use ^Upa for p0-p15
		default:
			GB_PANIC("asm: unknown reg class");
			return "r";
		}
	}

	// BR/BLR/RET take a bare register operand; there is no AT&T '*' indirection to
	// emit, so nothing needs the IndirectBranch marker.
	bool is_indirect_control_transfer(AstAsmInstruction *instr) override {
		return false;
	}

	// ARM64 immediates are written '#<value>'; no scale/log2 addressing forms.
	void write_constant_operand(Ast *op, u32 flags) override {
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
			write_cstr("#");
			this->write_i64(val);
			break;
		}
		case ExactValue_Float:
			error(op, "Floating-point literals that cannot be represented as an integer are not supported within asm operands");
			break;
		default:
			GB_PANIC("Unsupported asm immediate literal %s", expr_to_string(op));
			break;
		}
	}

	// ARM64 lane element qualifier for `vN.<T>[i]`, from the operand's element type.
	char arm64_lane_qualifier_for_type(Type *t) {
		Type *bt = base_type(t);
		Type *elem = bt;
		if (bt->kind == Type_SimdVector) {
			elem = bt->SimdVector.elem;
		} else if (bt->kind == Type_Array) {
			elem = bt->Array.elem;
		}
		switch (type_size_of(base_type(elem))) {
		case 1: return 'b';
		case 2: return 'h';
		case 4: return 's';
		case 8: return 'd';
		}
		return 0;
	}

	void write_operand(Slice<i32> const &op_number, Ast *op, u32 flags) override {
		AstAsmInstruction *instr = this->curr_instr;
		isize              opi   = this->curr_operand_index;

		if (op->tav.mode == Addressing_Constant) {
			// A condition-code slot is a constant in the frontend but must print as a
			// mnemonic (gt/lt/...), never '#<n>'.
			if (instr != nullptr && this->arm64_is_cond_slot(instr, opi)) {
				i64 e = exact_value_to_i64(exact_value_to_integer(op->tav.value));
				char const *cc = arm64_cond_name(e);
				GB_ASSERT_MSG(cc != nullptr, "asm: bad ARM64 condition encoding %lld", cast(long long)e);
				write_cstr(cc);
				return;
			}
			this->write_constant_operand(op, flags);
			return;
		}

		// No '*' indirection on ARM64; the register prints normally.
		flags &= ~WriteOperandFlag_IndirectBranch;

		bool negate = (flags & WriteOperandFlag_Negate) != 0;
		flags &= ~WriteOperandFlag_Negate;

		switch (op->kind) {
		case_ast_node(i, Ident, op);
			Entity *e = entity_of_node(op);
			auto *ed = entity_op(e);

			if (ed->view_of >= 0) {
				// Width-view (e.g. `p0w: u32 = p0`): the allocator picks one register;
				// print it at the requested width via LLVM's w/x operand modifier so both
				// names share it. ARM64 GPRs only expose 32-bit (w) and 64-bit (x)
				// names; sub-word views still use the w register.
				i32 idx = op_number[ed->view_of];
				GB_ASSERT(idx >= 0);
				char mod = 0;
				switch (ed->view_bits) {
				case 8: case 16: case 32: mod = 'w'; break;
				case 64:                  mod = 'x'; break;
				default: GB_PANIC("asm: invalid ARM64 width-view size %d", ed->view_bits); break;
				}
				asm_string = gb_string_append_fmt(asm_string, "${%d:%c}", idx, mod);
			} else {
				i32 idx = op_number[ed->total_index];
				GB_ASSERT(idx >= 0);
				if (ed->kind == AsmTemplateEntityDecl_Immediate) {
					// Immediate parameter: '#' prefix, then LLVM substitutes the bare value.
					if (negate) {
						asm_string = gb_string_append_fmt(asm_string, "#-$%d", idx);
					} else {
						asm_string = gb_string_append_fmt(asm_string, "#$%d", idx);
					}
				} else {
					GB_ASSERT(!negate); // only immediates/displacements negate
					// An arrangement operand prints `vN.<T>` — bare $N (which lowers to
					// the full vN) plus the ".4s"/".2d"/... suffix. It must NOT also take
					// a register-name modifier: ${N:q} + .4s yields the invalid `q1.4s`.
					// Only non-arrangement slots take the w/x/q/d/s modifier.
					String arr = {};
					if (instr != nullptr) {
						arr = this->arm64_arrangement_suffix(instr, opi, ed->entity->type);
					}
					if (arr.len != 0) {
						asm_string = gb_string_append_fmt(asm_string, "$%d", idx);
						write_string(arr);
					} else {
						char mod = (instr != nullptr) ? this->arm64_slot_reg_modifier(instr, opi) : 0;
						if (mod != 0) {
							asm_string = gb_string_append_fmt(asm_string, "${%d:%c}", idx, mod);
						} else {
							asm_string = gb_string_append_fmt(asm_string, "$%d", idx);
						}
					}
				}
			}
		case_end;
		case_ast_node(mem_op, AsmMemoryOperand, op);
			this->write_memory_operand(op_number, mem_op, flags&~WriteOperandFlag_PrintPrefixes);
		case_end;
		case_ast_node(bl, BasicLit, op);
			GB_PANIC("NOTE(bill): this should have been handled above");
		case_end;
		case_ast_node(label, AsmLabelDecl, op);
			this->write_label(&label->name->Ident);
		case_end;
		case_ast_node(reg, AsmRegister, op);
			this->write_string(reg->name.string); // bare: x0, w0, sp, xzr, v0, ...
		case_end;
		case_ast_node(ie, IndexExpr, op);
			// Vector-lane access: `acc[0]` -> `$N.d[0]` (i.e. v<N>.d[0]). The base names
			// the SIMD operand; the index is a constant lane encoded in the instruction.
			Ast *base_op = ie->expr;
			Ast *index   = ie->index;

			// Resolve the lane to a concrete i64. Two spellings reach here:
			//   v[0]     — literal lane, folded onto the index node's tav
			//   v[idx]   — $-immediate parameter; its value is the operand argument,
			//              looked up via the decl exactly like any other immediate.
			i64  lane      = -1;
			bool have_lane = false;

			if (index->kind == Ast_Ident) {
				// Immediate-parameter lane: find its decl, confirm it's an immediate, read value.
				Entity *ie_ = entity_of_node(index);
				if (ie_ != nullptr) {
					auto *ed = entity_op(ie_); // the AsmTemplateEntityDecl for this parameter
					if (ed != nullptr && ed->kind == AsmTemplateEntityDecl_Immediate) {
						GB_ASSERT(ed->param_index >= 0);
						lbValue v = (*this->curr_args)[ed->param_index];
						GB_ASSERT_MSG(LLVMIsAConstantInt(v.value),
						              "asm: lane immediate '%.*s' is not a constant",
						              LIT(ed->entity->token.string));
						lane      = cast(i64)LLVMConstIntGetSExtValue(v.value);
						have_lane = true;
					}
				}
			}

			if (!have_lane) {
				// Literal lane: value folded onto the index node by the checker.
				GB_ASSERT_MSG(index->tav.mode == Addressing_Constant,
				              "asm: AArch64 lane index reached lowering unfolded");
				ExactValue ev = exact_value_to_integer(index->tav.value);
				GB_ASSERT(ev.kind == ExactValue_Integer);
				lane      = exact_value_to_i64(ev);
				have_lane = true;
			}

			GB_ASSERT(lane >= 0);

			switch (base_op->kind) {
			case_ast_node(reg, AsmRegister, base_op);
				// Explicit register: the arrangement (`.d`, `.2d`, `.4s`) is part of the
				// spelling, so print the name verbatim and append the lane. If it was
				// written bare (`v0`), there is no element size to index by.
				String rname = reg->name.string;
				bool has_arrangement = false;
				for (isize i = 0; i < rname.len; i++) {
					if (rname.text[i] == '.') {
						has_arrangement = true;
						break;
					}
				}
				GB_ASSERT_MSG(has_arrangement,
				              "asm: ARM64 lane access on register '%.*s' needs an element qualifier "
				              "(e.g. '%.*s.d[%lld]')",
				              LIT(rname), LIT(rname), cast(long long)lane);
				this->write_string(rname);
				asm_string = gb_string_append_fmt(asm_string, "[%lld]", cast(long long)lane);
			case_end;

			case_ast_node(id, Ident, base_op);
				Entity *e  = entity_of_node(base_op);
				auto   *ed = entity_op(e);

				// Lane form needs the v-register, so index the source operand directly with no
				// width modifier (a width-view would force a scalar d/s name that can't take a lane).
				i32 idx = (ed->view_of >= 0) ? op_number[ed->view_of] : op_number[ed->total_index];
				GB_ASSERT(idx >= 0);

				char q = this->arm64_lane_qualifier_for_type(ed->entity->type);
				GB_ASSERT_MSG(q != 0, "asm: cannot determine ARM64 lane element size for '%.*s'",
				              LIT(e->token.string));

				// fmov is the ONE exception: it has no `vN.<T>[i]` lane form for S/D
				// elements — lane i of an S/D element aliases the scalar view, so emit
				// the scalar name (${N:s}/${N:d}) with no lane suffix. (The `.d[1]`
				// high-half form is the only real fmov lane form.)
				// mov/dup DO have the general `.<T>[i]` lane form, so they take the
				// normal path below and emit e.g. `mov s0, v0.s[2]` — with the scalar
				// destination coming from the matched form's S_REG/D_REG slot (Fix 1).
				bool is_fmov = instr != nullptr && instr->mnemonic == Asm_arm64::M_FMOV;
				if (is_fmov && (q == 's' || q == 'd')) {
					GB_ASSERT_MSG(lane == 0 || (q == 'd' && lane == 1),
					              "asm: fmov has no lane form for %c[%lld]; only s[0]/d[0] (scalar) and d[1] exist",
					              q, cast(long long)lane);
					if (q == 'd' && lane == 1) {
						// the one genuine fmov lane form: fmov Xd, Vn.d[1]
						asm_string = gb_string_append_fmt(asm_string, "$%d.d[1]", idx);
					} else {
						asm_string = gb_string_append_fmt(asm_string, "${%d:%c}", idx, q);
					}
				} else {
					asm_string = gb_string_append_fmt(asm_string, "$%d.%c[%lld]", idx, q, cast(long long)lane);
				}
			case_end;

			default:
				GB_PANIC("asm: ARM64 lane base must be an operand or explicit register, got '%s'",
				         expr_to_string(base_op));
				break;
			}
		case_end;
		default:
			GB_PANIC("TODO(bill): write_operand for '%s'", expr_to_string(op));
			break;
		}
	}

		// Resolve a memory scale to an ARM64 `LSL #n` shift amount. The frontend
	// encodes scale either as a multiply (index * {1,2,4,8,16}) or as an explicit
	// shift (index << n); ARM64 register-offset addressing always wants the shift.
	i64 arm64_scale_shift_amount(AstAsmMemoryOperand *mem_op) {
		Ast *scale = mem_op->scale;
		GB_ASSERT(scale != nullptr);
		GB_ASSERT_MSG(scale->tav.mode == Addressing_Constant,
		              "asm: ARM64 memory scale must be a constant shift amount");
		ExactValue ev = exact_value_to_integer(scale->tav.value);
		GB_ASSERT(ev.kind == ExactValue_Integer);
		i64 v = exact_value_to_i64(ev);

		switch (mem_op->scale_op.kind) {
		case Token_Mul:
			switch (v) {
			case 1:  return 0;
			case 2:  return 1;
			case 4:  return 2;
			case 8:  return 3;
			case 16: return 4; // 128-bit (Q) transfers
			default:
				error(scale, "asm: ARM64 memory scale must be 1, 2, 4, 8, or 16, got %lld", cast(long long)v);
				return 0;
			}
		case Token_Shl:
		case Token_Shr:
			if (v < 0 || v > 4) {
				error(scale, "asm: ARM64 memory shift amount must be between 0 and 4, got %lld", cast(long long)v);
				return 0;
			}
			return v;
		default:
			GB_PANIC("asm: invalid ARM64 memory scale operator");
			return 0;
		}
	}

	char const *arm64_index_extend(AstAsmMemoryOperand *mem_op) {
		Ast *idx = mem_op->index;
		if (idx == nullptr) {
			return "lsl";
		}
		// Resolve the index operand's type: explicit reg -> its reg width; a param ->
		// its Odin type.
		Type *ty = idx->tav.type;
		if (ty == nullptr) {
			return "lsl";
		}
		i32 w = check_asm_operand_bit_width(ty);
		if (w == 64) {
			return "lsl";
		}
		// 32-bit index: pick zero/sign extend from the type's signedness.
		Type *bt = base_type(ty);
		bool is_signed = is_type_integer(bt) && !is_type_unsigned(bt);
		return is_signed ? "sxtw" : "uxtw";
	}

	// ARM64 addressing: `[base]`, `[base, #disp]`, `[base, Xindex]`, or
	// `[base, Xindex, LSL #n]`. Base+index and base+disp are mutually exclusive
	// addressing modes, so an index precludes a displacement.
	void write_memory_operand(Slice<i32> const &op_number, AstAsmMemoryOperand *mem_op, u32 flags) override {
		GB_ASSERT_MSG(mem_op->segment_override == nullptr, "asm: ARM64 has no segment overrides");
		GB_ASSERT_MSG(mem_op->scale == nullptr || mem_op->index != nullptr,
		              "asm: ARM64 memory scale requires an index register");

		write_cstr("[");
		if (mem_op->base != nullptr) {
			this->write_operand(op_number, mem_op->base, flags&~WriteOperandFlag_PrintPrefixes);
		}
		if (mem_op->index != nullptr) {
			write_cstr(", ");
			this->write_operand(op_number, mem_op->index, flags&~WriteOperandFlag_PrintPrefixes);
			if (mem_op->scale != nullptr) {
				// A 32-bit index needs an extend specifier (uxtw/sxtw); a 64-bit index
				// uses lsl. The extend for a w-index is mandatory even at shift 0.
				char const *extend = this->arm64_index_extend(mem_op); // "lsl", "uxtw", or "sxtw"
				i64 shift = (mem_op->scale != nullptr) ? this->arm64_scale_shift_amount(mem_op) : 0;
				bool is_lsl = (extend[0] == 'l');
				if (!is_lsl) {
					// w-index: always print the extend; shift optional.
					if (shift != 0) {
						asm_string = gb_string_append_fmt(asm_string, ", %s #%lld", extend, cast(long long)shift);
					} else {
						asm_string = gb_string_append_fmt(asm_string, ", %s", extend);
					}
				} else if (shift != 0) {
					asm_string = gb_string_append_fmt(asm_string, ", lsl #%lld", cast(long long)shift);
				}
			}
		} else if (mem_op->disp) {
			write_cstr(", ");
			u32 disp_flags = flags;
			if (mem_op->disp_op.kind == Token_Sub) {
				disp_flags |= WriteOperandFlag_Negate;
			}
			this->write_operand(op_number, mem_op->disp, disp_flags);
		}
		write_cstr("]");
	}

	// A flag output '= %flags.<n|z|c|v>' lowers to '=@cc<cond>', where the condition
	// is true exactly when that NZCV bit is set. (cs is an accepted alias of hs.)
	String flag_output_cc_suffix(String const &pin_flag) override {
		if (pin_flag == "n") return str_lit("mi"); // N == 1
		if (pin_flag == "z") return str_lit("eq"); // Z == 1
		if (pin_flag == "c") return str_lit("hs"); // C == 1
		if (pin_flag == "v") return str_lit("vs"); // V == 1
		return {};
	}

	// A64 spells conditional branches (and a few others) with '.', e.g. b.eq, which
	// an Odin identifier can't contain; accept '_' and translate (b_eq -> b.eq).
	void write_instruction_mnemonic(AstAsmInstruction *instr) override {
		String name = instr->name->Ident.token.string;
		for (isize i = 0; i < name.len; i++) {
			char c = cast(char)name.text[i];
			write_char(c == '_' ? '.' : c);
		}
	}
};

gb_internal lbValue lb_emit_asm_template_call(lbProcedure *p, Entity *entity, Array<lbValue> const &args) {
	lbAsmGenerate_amd64   generator_amd64   = {};
	lbAsmGenerate_arm64   generator_arm64 = {};
	lbAsmGenerate_riscv64 generator_riscv64 = {};
	lbAsmGenerate *generator = nullptr;
	if (build_context.metrics.arch == TargetArch_amd64) {
		generator = &generator_amd64;
	} else if (build_context.metrics.arch == TargetArch_arm64) {
		generator = &generator_arm64;
	} else if (build_context.metrics.arch == TargetArch_riscv64) {
		generator = &generator_riscv64;
	} else {
		compiler_error("Architecture does not support asm templates, yet");
	}
	GB_ASSERT(generator != nullptr);
	generator->init(entity);
	defer (generator->destroy());
	return generator->emit_call(p, args);
}