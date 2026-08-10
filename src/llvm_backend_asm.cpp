gb_internal AsmTemplateEntityDecl *lb_asm_entity_decl(Array<AsmTemplateEntityDecl> *decls, Entity *e) {
	for (AsmTemplateEntityDecl &op : *decls) {
		if (op.entity == e) {
			return &op;
		}
	}
	GB_PANIC("Could not find asm entity %s", LIT(e->token.string));
	return nullptr;
}

gb_internal gbString lb_asm_write_label_name(gbString asm_string, AstIdent *label_ident) {
	String name = label_ident->token.string;
	asm_string = gb_string_appendc(asm_string, ".L");
	asm_string = gb_string_append_length(asm_string, name.text, name.len);
	// ${:uid} expands to a per-instantiation unique integer, so repeated
	// inlining of the same template can't collide on the label symbol.
	asm_string = gb_string_appendc(asm_string, "${:uid}");
	return asm_string;
}

gb_internal gbString lb_asm_write_operand(gbString asm_string, Array<i32> op_number, Array<AsmTemplateEntityDecl> *decls, Ast *op, bool print_prefixes=true) {
	switch (op->kind) {
	case_ast_node(i, Ident, op);
		Entity *e = entity_of_node(op);
		auto *ed = lb_asm_entity_decl(decls, e);

		i32 idx = op_number[ed->total_index];
		GB_ASSERT(idx >= 0);
		asm_string = gb_string_append_fmt(asm_string, "$%d", idx);
	case_end;
	case_ast_node(mem_op, AsmMemoryOperand, op);
		if (mem_op->disp) {
			asm_string = lb_asm_write_operand(asm_string, op_number, decls, mem_op->disp, /*print_prefixes*/false);
		}
		asm_string = gb_string_appendc(asm_string, "(");
		GB_ASSERT(mem_op->base != nullptr);
		asm_string = lb_asm_write_operand(asm_string, op_number, decls, mem_op->base);
		if (mem_op->index) {
			asm_string = gb_string_appendc(asm_string, ",");
			asm_string = lb_asm_write_operand(asm_string, op_number, decls, mem_op->index);
			if (mem_op->scale) {
				asm_string = gb_string_appendc(asm_string, ",");
				asm_string = lb_asm_write_operand(asm_string, op_number, decls, mem_op->scale, /*print_prefixes*/false);
			}
		}
		asm_string = gb_string_appendc(asm_string, ")");
	case_end;

	case_ast_node(bl, BasicLit, op);
		ExactValue ev = op->tav.value;
		GB_ASSERT(ev.kind != ExactValue_Invalid);
		switch (ev.kind) {
		case ExactValue_Integer: {
			String s = big_int_to_string(heap_allocator(), &ev.value_integer, 10);
			if (print_prefixes) {
				asm_string = gb_string_appendc(asm_string, "$$");
			}
			asm_string = gb_string_append_length(asm_string, s.text, s.len);
			gb_free(heap_allocator(), s.text);
			break;
		}
		default:
			GB_PANIC("Unsupported asm immediate literal %s", expr_to_string(op));
			break;
		}
	case_end;

	case_ast_node(label, AsmLabelDecl, op);
		asm_string = lb_asm_write_label_name(asm_string, &label->name->Ident);
	case_end;
	default:
		GB_PANIC("TODO %s", expr_to_string(op));
		break;
	}
	return asm_string;
}


gb_internal lbValue lb_emit_asm_template_call(lbProcedure *p, Entity *entity, Array<lbValue> const &args) {
	GB_ASSERT(entity != nullptr);
	lbModule *m = p->module;
	LLVMContextRef ctx = m->ctx;

	// Assumed frontend accessor: template string, flags, dialect, and the operand table.
	auto &tmpl = entity->AsmTemplate;
	Array<AsmTemplateEntityDecl> &ops = tmpl.decls;

	TEMPORARY_ALLOCATOR_GUARD();

	gbString asm_string  = gb_string_make_reserve(temporary_allocator(), 64);
	gbString constraints = gb_string_make_reserve(temporary_allocator(), 64);

	auto param_types = array_make<LLVMTypeRef>(temporary_allocator(),  0, ops.count);
	auto call_args   = array_make<LLVMValueRef>(temporary_allocator(), 0, ops.count);
	auto ret_types   = array_make<LLVMTypeRef>(temporary_allocator(),  0, ops.count);

	// Per-operand bookkeeping, indexed the same as `ops` (via total_index).
	auto op_number = array_make<i32>(temporary_allocator(), ops.count, ops.count); // $N, or -1 for clobbers
	auto ret_slot  = array_make<i32>(temporary_allocator(), ops.count, ops.count); // return-struct index, or -1
	for_array(i, ops) {
		op_number[i] = -1;
		ret_slot[i]  = -1;
	}

	// elementtype() attrs to attach after the call is built (indirect/memory operands).
	struct ElemAttr {
		unsigned arg_pos;
		LLVMTypeRef elem;
	};
	auto elem_attrs = array_make<ElemAttr>(temporary_allocator(), 0, ops.count);

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

	auto class_letter = [&](AsmRegClass rc) -> char const * {
		switch (rc) {
		case AsmRegClass_Integer: return "r";
		case AsmRegClass_Float:   return "x";   // TODO(bill): target-dependent
		case AsmRegClass_Vector:  return "x";   // TODO(bill): target-dependent
		case AsmRegClass_Mask:    return "^Yk"; // AVX-512 k-regs
		default: GB_PANIC("asm: unknown reg class"); return "r";
		}
	};

	// LLVM type of a returned register output, taken from the proc signature's results.
	auto output_llvm_type = [&](AsmTemplateEntityDecl const &e) -> LLVMTypeRef {
		Type *pt = base_type(entity->type);
		Type *rt = pt->Proc.results->Tuple.variables[e.result_index]->type;
		return lb_type(m, rt);
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
	for_array(i, ops) {
		AsmTemplateEntityDecl const &e = ops[i];

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
			raw(class_letter(e.reg_class));
		}

		// Use the entity's real declared type so the return-struct slot matches
		// the constraint's width/class (e.g. <4 x float> for a #simd[4]f32 scratch).
		LLVMTypeRef ty = is_alloc_scratch ? lb_type(m, e.entity->type) : output_llvm_type(e);

		ret_slot[i] = cast(i32)ret_types.count;
		array_add(&ret_types, ty);
		op_number[i] = next_op++;
	}

	// Pass 2: inputs
	for (isize i = 0; i < ops.count; i++) {
		AsmTemplateEntityDecl const &e = ops[i];
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
					raw(class_letter(e.reg_class));
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
	GB_ASSERT(tmpl.node->kind == Ast_AsmTemplate);
	auto *node = &tmpl.node->AsmTemplate;
	for_array(i, node->instructions) {
		if (i > 0) {
			asm_string = gb_string_appendc(asm_string, "\n");
		}
		Ast *instr_ = node->instructions[i];
		switch (instr_->kind) {
		case_ast_node(instr, AsmInstruction, instr_);
			asm_string = gb_string_appendc(asm_string, "\t");
			String name = instr->name->Ident.token.string;
			asm_string = gb_string_append_length(asm_string, name.text, name.len);
			asm_string = gb_string_appendc(asm_string, " ");
			// Intel-source operand order reversed to AT&T (src, ..., dst).
			for (isize j = instr->operands.count-1; j >= 0; j -= 1) {
				Ast *op = instr->operands[j];
				if (j < instr->operands.count-1) {
					asm_string = gb_string_appendc(asm_string, ", ");
				}
				asm_string = lb_asm_write_operand(asm_string, op_number, &ops, op);
			}
		case_end;
		case_ast_node(label, AsmLabelDecl, instr_);
			asm_string = lb_asm_write_label_name(asm_string, &label->name->Ident);
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
	for (isize i = 0; i < ops.count; i++) {
		AsmTemplateEntityDecl const &e = ops[i];
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
	bool has_side_effects = tmpl.has_side_effects;

	LLVMValueRef ia = LLVMGetInlineAsm(
		fn_ty,
		asm_string,  cast(size_t)gb_string_length(asm_string),
		constraints, cast(size_t)gb_string_length(constraints),
		/*HasSideEffects*/ has_side_effects,
		/*IsAlignStack*/   tmpl.is_align_stack,
		LLVMInlineAsmDialectATT,
		/*CanThrow*/       false);

	LLVMValueRef call = LLVMBuildCall2(p->builder, fn_ty, ia, call_args.data, cast(unsigned)call_args.count, "");

	{	// DEBUG PRINT!!!
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
	Type *pt = base_type(entity->type);
	isize result_count = (pt->Proc.results != nullptr) ? pt->Proc.results->Tuple.variables.count : 0;
	if (result_count == 0) {
		return lbValue{}; // void asm (memory outputs already wrote through their pointers)
	}

	// The LLVM return struct is ordered by operand and includes scratch slots;
	// pull out only the real register outputs and index them by result_index.
	auto result_vals = array_make<LLVMValueRef>(temporary_allocator(), result_count, result_count);
	for (isize i = 0; i < result_count; i++) result_vals[i] = nullptr;

	for (isize i = 0; i < ops.count; i++) {
		AsmTemplateEntityDecl const &e = ops[i];
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