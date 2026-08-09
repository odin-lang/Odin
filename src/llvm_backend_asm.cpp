gb_internal lbValue lb_emit_asm_template_call(lbProcedure *p, Entity *entity, Array<lbValue> const &args) {
	GB_ASSERT(entity->kind == Entity_AsmTemplate);

	// GB_PANIC("TODO(bill): lb_emit_asm_template_call");
	gbString asm_string  = gb_string_make(heap_allocator(), "");
	gbString constraints = gb_string_make(heap_allocator(), "");

	auto *ate = &entity->AsmTemplate;
	GB_ASSERT(ate->node->kind == Ast_AsmTemplate);
	auto *node = &ate->node->AsmTemplate;

	for_array(i, node->instructions) {
		auto *instruction = node->instructions[i];
		gb_unused(instruction);
	}
	// asm_string = gb_string_appendc(asm_string, "lock cmpxchg16b $3");
	// asm_string = gb_string_appendc(asm_string, "\\0A\\09");
	// asm_string = gb_string_appendc(asm_string, "setz $2");

	// constraints = gb_string_appendc(constraints, "*m,={ax},={dx},=r,{ax},{dx},{bx},{cx},~{cc},~{memory}");

	Type *proc_type = base_type(entity->type);
	GB_ASSERT(proc_type->kind == Type_Proc);

	LLVMTypeRef llvm_type = lb_type_internal_for_procedures_raw(p->module, proc_type);
	gb_printf_err("%s\n", LLVMPrintTypeToString(llvm_type));

	LLVMValueRef fn = LLVMGetInlineAsm(llvm_type, asm_string, gb_string_length(asm_string),
	                                   constraints, gb_string_length(constraints),
	                                   entity->AsmTemplate.has_side_effects,
	                                   entity->AsmTemplate.is_align_stack,
	                                   LLVMInlineAsmDialectATT, /*CanThrow*/false);

	LLVMValueRef *llvm_args = gb_alloc_array(heap_allocator(), LLVMValueRef, args.count);
	for_array(i, args) {
		llvm_args[i] = args[i].value;
	}
	LLVMValueRef result = LLVMBuildCall2(p->builder, llvm_type, fn, llvm_args, cast(unsigned)args.count, "");
	Type *result_type = reduce_tuple_to_single_type(proc_type->Proc.results);

	gb_printf_err("%s\n", LLVMPrintValueToString(result));
	return {result, result_type};
}