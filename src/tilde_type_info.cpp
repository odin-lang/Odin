gb_internal void cg_setup_type_info_data(cgModule *m) {
	if (build_context.no_rtti) {
		return;
	}
	CheckerInfo *info = m->info;
	gb_unused(info);


	// i64 global_type_info_data_entity_count = 0;
	// {
	// 	// NOTE(bill): Set the type_table slice with the global backing array
	// 	cgValue global_type_table = cg_find_runtime_value(m, str_lit("type_table"));
	// 	Type *type = base_type(cg_global_type_info_data_entity->type);
	// 	GB_ASSERT(is_type_array(type));
	// 	global_type_info_data_entity_count = type->Array.count;

	// 	LLVMValueRef indices[2] = {llvm_zero(m), llvm_zero(m)};
	// 	LLVMValueRef data = LLVMConstInBoundsGEP2(cg_type(m, cg_global_type_info_data_entity->type), cg_global_type_info_data_ptr(m).value, indices, gb_count_of(indices));
	// 	LLVMValueRef len = LLVMConstInt(cg_type(m, t_int), type->Array.count, true);
	// 	Type *t = type_deref(global_type_table.type);
	// 	GB_ASSERT(is_type_slice(t));
	// 	LLVMValueRef slice = llvm_const_slice_internal(m, data, len);

	// 	LLVMSetInitializer(global_type_table.value, slice);
	// }

}