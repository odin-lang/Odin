struct lbAsmGenerate {
	Entity *                      tmpl_entity;
	AstAsmTemplate *              tmpl_node;
	Array<AsmTemplateEntityDecl> *ops;

	enum WriteOperandFlags : u32 {
		WriteOperandFlag_PrintPrefixes = 1<<0,
		WriteOperandFlag_IsScale       = 1<<1,
		WriteOperandFlag_IsScaleLog2   = 1<<2,

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
		GB_PANIC("Could not find asm entity %s", LIT(parameter->token.string));
		return nullptr;
	}

	gbString write_operand(gbString asm_string, Array<i32> op_number, Ast *op, u32 flags) {
		switch (op->kind) {
		case_ast_node(i, Ident, op);
			Entity *e = entity_of_node(op);
			auto *ed = entity_op(e);

			i32 idx = op_number[ed->total_index];
			GB_ASSERT(idx >= 0);
			asm_string = gb_string_append_fmt(asm_string, "$%d", idx);
		case_end;
		case_ast_node(mem_op, AsmMemoryOperand, op);
			asm_string = this->write_memory_operand(asm_string, op_number, mem_op, flags&~WriteOperandFlag_PrintPrefixes);
		case_end;

		case_ast_node(bl, BasicLit, op);
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
		case_end;

		case_ast_node(label, AsmLabelDecl, op);
			asm_string = write_label(asm_string, &label->name->Ident);
		case_end;
		default:
			GB_PANIC("TODO %s", expr_to_string(op));
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

	// AT&T operand-size suffix ('b','w','l','q') for an annotated memory operand,
	// or 0 if there is no size annotation to apply. Vector/other widths return 0,
	// since those forms take no b/w/l/q suffix (the register operand fixes the size).
	char size_suffix_for_operand(Ast *op) {
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

	// Scan an instruction's operands for an annotated memory operand and return its
	// AT&T size suffix, or 0 if none. The checker has already verified the annotation
	// agrees with the matched encoding form, so a suffix here can never conflict.
	char instruction_size_suffix(AstAsmInstruction *instr) {
		char suffix = 0;
		for (Ast *operand : instr->operands) {
			char s = this->size_suffix_for_operand(operand);
			if (s != 0) {
				suffix = s;
			}
		}
		return suffix;
	}


	// LLVM type of a returned register output, taken from the proc signature's results.
	LLVMTypeRef output_llvm_type(lbModule *m, AsmTemplateEntityDecl const &e) {
		Type *pt = base_type(tmpl_entity->type);
		Type *rt = pt->Proc.results->Tuple.variables[e.result_index]->type;
		return lb_type(m, rt);
	};


	virtual gbString write_memory_operand(gbString asm_string, Array<i32> const &op_number, AstAsmMemoryOperand *mem_op, u32 flags) = 0;
	virtual lbValue  emit_call(lbProcedure *p, Array<lbValue> const &args) = 0;
};

struct lbAsmGenerate_amd64 : lbAsmGenerate {
	gbString write_memory_operand(gbString asm_string, Array<i32> const &op_number, AstAsmMemoryOperand *mem_op, u32 flags) override {
		if (mem_op->disp) {
			asm_string = this->write_operand(asm_string, op_number, mem_op->disp, flags&~WriteOperandFlag_PrintPrefixes);
		}
		asm_string = gb_string_appendc(asm_string, "(");
		GB_ASSERT(mem_op->base != nullptr);
		asm_string = this->write_operand(asm_string, op_number, mem_op->base, flags);
		if (mem_op->index) {
			asm_string = gb_string_appendc(asm_string, ",");
			asm_string = this->write_operand(asm_string, op_number, mem_op->index, flags);
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

		// Assumed frontend accessor: template string, flags, dialect, and the operand table.
		TEMPORARY_ALLOCATOR_GUARD();

		gbString asm_string  = gb_string_make_reserve(temporary_allocator(), 64);
		gbString constraints = gb_string_make_reserve(temporary_allocator(), 64);

		auto param_types = array_make<LLVMTypeRef>(temporary_allocator(),  0, ops->count);
		auto call_args   = array_make<LLVMValueRef>(temporary_allocator(), 0, ops->count);
		auto ret_types   = array_make<LLVMTypeRef>(temporary_allocator(),  0, ops->count);

		// Per-operand bookkeeping, indexed the same as `ops` (via total_index).
		auto op_number = array_make<i32>(temporary_allocator(), ops->count, ops->count); // $N, or -1 for clobbers
		auto ret_slot  = array_make<i32>(temporary_allocator(), ops->count, ops->count); // return-struct index, or -1
		for_array(i, *ops) {
			op_number[i] = -1;
			ret_slot[i]  = -1;
		}

		// elementtype() attrs to attach after the call is built (indirect/memory operands).
		struct ElemAttr {
			unsigned arg_pos;
			LLVMTypeRef elem;
		};
		auto elem_attrs = array_make<ElemAttr>(temporary_allocator(), 0, ops->count);

		i32 next_op = 0; // running $N counter (outputs first, then inputs)

		auto sep = [&]() {
			if (gb_string_length(constraints) != 0) {
				constraints = gb_string_appendc(constraints, ",");
			}
		};
		auto raw = [&](char const *s) {
			constraints = gb_string_appendc(constraints, s);
		};
		auto put = [&](String s) {
			constraints = gb_string_append_length(constraints, s.text, s.len);
		};

		auto add_arg = [&](LLVMValueRef v) -> unsigned {
			unsigned pos = cast(unsigned)call_args.count;
			array_add(&param_types, LLVMTypeOf(v));
			array_add(&call_args, v);
			return pos;
		};

		// Pass 1: outputs
		// Real outputs plus *unpinned* register scratch (modeled as discarded
		// early-clobber outputs, since a clobber can only name a fixed register).
		for_array(i, *ops) {
			AsmTemplateEntityDecl const &e = (*ops)[i];

			bool is_output        = e.param_group == AsmTemplateEntityDeclParamGroup_Output;
			bool is_alloc_scratch = e.param_group == AsmTemplateEntityDeclParamGroup_Scratch
			                     && e.kind == AsmTemplateEntityDecl_Register
			                     && e.pin.len == 0;
			if (!is_output && !is_alloc_scratch) {
				continue;
			}

			sep();

			// Register output: '=' ['&'] ( '{pin}' | class-letter )
			raw("=");
			if (is_alloc_scratch) { // early-clobber: keep scratch off any input reg
				raw("&");
			}
			if (e.pin.len != 0) {
				raw("{"); put(e.pin); raw("}");
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
		for (isize i = 0; i < ops->count; i++) {
			AsmTemplateEntityDecl const &e = (*ops)[i];
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
				add_arg(v.value);
			} else {
				switch (e.kind) {
				case AsmTemplateEntityDecl_Register:
				case AsmTemplateEntityDecl_Memory:
					if (e.pin.len != 0) {
						raw("{"); put(e.pin); raw("}");
					} else {
						raw(this->class_letter(e.reg_class));
					}
					add_arg(v.value);
					break;
				// case AsmTemplateEntityDecl_Memory: {
				// 	raw("*m"); // indirect
				// 	unsigned pos = add_arg(v.value);
				// 	array_add(&elem_attrs, ElemAttr{pos, lb_type(m, type_deref(v.type))});
				// 	break;
				// }
				case AsmTemplateEntityDecl_Immediate:
					raw("i"); // TODO: "n" if a known-constant integer is required
					add_arg(v.value);
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
				asm_string = gb_string_append_length(asm_string, name.text, name.len);

				// If a memory operand carries an explicit size annotation ([p]:u8) and
				// no register operand pins the width, the AT&T assembler needs the size
				// encoded as a mnemonic suffix (crc32 -> crc32b). The checker has already
				// verified the annotation agrees with the matched form, so an emitted
				// suffix can never conflict with a register operand's implied width.
				{
					char suffix = this->instruction_size_suffix(instr);
					if (suffix != 0) {
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
			default:
				GB_PANIC("Invalid asm instruction");
				break;
			}
		}

		// Pass 3: clobbers
		// Only the Scratch group. Unpinned register scratch was already emitted as an
		// output in Pass 1, so it is skipped here.
		for (isize i = 0; i < ops->count; i++) {
			AsmTemplateEntityDecl const &e = (*ops)[i];
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
				raw("~{"); put(e.pin); raw("}");
				break;
			case AsmTemplateEntityDecl_Memory:   // general memory clobber
				raw("~{memory}");
				break;
			default:
				GB_PANIC("asm: invalid scratch operand kind");
			}
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

		// TODO(bill): determine all the cases when side-effects happen
		bool has_side_effects = tmpl_node->has_side_effects;

		LLVMValueRef ia = LLVMGetInlineAsm(
			fn_ty,
			asm_string,  cast(size_t)gb_string_length(asm_string),
			constraints, cast(size_t)gb_string_length(constraints),
			/*HasSideEffects*/ has_side_effects,
			/*IsAlignStack*/   tmpl_node->is_align_stack,
			LLVMInlineAsmDialectATT,
			/*CanThrow*/       false);

		LLVMValueRef call = LLVMBuildCall2(p->builder, fn_ty, ia, call_args.data, cast(unsigned)call_args.count, "");

		if (false) {
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
		for (isize k = 0; k < elem_attrs.count; k++) {
			LLVMAttributeRef attr = LLVMCreateTypeAttribute(ctx, et_kind, elem_attrs[k].elem);
			LLVMAddCallSiteAttribute(call, cast(LLVMAttributeIndex)(elem_attrs[k].arg_pos + 1), attr);
		}

		// Repackage results in Odin result order
		Type *pt = base_type(tmpl_entity->type);
		isize result_count = (pt->Proc.results != nullptr) ? pt->Proc.results->Tuple.variables.count : 0;
		if (result_count == 0) {
			return lbValue{}; // void asm (memory outputs already wrote through their pointers)
		}

		// The LLVM return struct is ordered by operand and includes scratch slots;
		// pull out only the real register outputs and index them by result_index.
		auto result_vals = array_make<LLVMValueRef>(temporary_allocator(), result_count, result_count);
		for (isize i = 0; i < result_count; i++) {
			result_vals[i] = nullptr;
		}

		for (isize i = 0; i < ops->count; i++) {
			AsmTemplateEntityDecl const &e = (*ops)[i];
			if (e.param_group != AsmTemplateEntityDeclParamGroup_Output) {
				continue;
			}
			if (e.result_index < 0) {
				continue; // memory output: not a returned value
			}
			GB_ASSERT(ret_slot[i] >= 0);

			LLVMValueRef v = (ret_types.count == 1)
				? call // single-element return is not a struct
				: LLVMBuildExtractValue(p->builder, call, cast(unsigned)ret_slot[i], "");
			result_vals[e.result_index] = v;
		}

		if (result_count == 1) {
			Type *rt = pt->Proc.results->Tuple.variables[0]->type;
			return lbValue{result_vals[0], rt};
		}

		// Multiple results -> assemble Odin's result aggregate in result order.
		Type *results_type = pt->Proc.results;
		LLVMValueRef agg = LLVMGetUndef(lb_type(m, results_type));
		for (isize i = 0; i < result_count; i++) {
			GB_ASSERT(result_vals[i] != nullptr);
			agg = LLVMBuildInsertValue(p->builder, agg, result_vals[i], cast(unsigned)i, "");
		}

		return lbValue{agg, results_type};
	}
};


gb_internal lbValue lb_emit_asm_template_call(lbProcedure *p, Entity *entity, Array<lbValue> const &args) {
	lbAsmGenerate_amd64 generator = {};
	generator.init(entity);
	return generator.emit_call(p, args);
}