#define MULTITHREAD_OBJECT_GENERATION 1

#ifndef USE_SEPARATE_MODULES
#define USE_SEPARATE_MODULES build_context.use_separate_modules
#endif

#ifndef MULTITHREAD_OBJECT_GENERATION
#define MULTITHREAD_OBJECT_GENERATION 0
#endif


#include "llvm_backend.hpp"
#include "llvm_abi.cpp"
#include "llvm_backend_opt.cpp"
#include "llvm_backend_general.cpp"
#include "llvm_backend_debug.cpp"
#include "llvm_backend_const.cpp"
#include "llvm_backend_type.cpp"
#include "llvm_backend_utility.cpp"
#include "llvm_backend_expr.cpp"
#include "llvm_backend_stmt.cpp"
#include "llvm_backend_proc.cpp"


gb_internal void lb_add_foreign_library_path(lbModule *m, Entity *e) {
	if (e == nullptr) {
		return;
	}
	GB_ASSERT(e->kind == Entity_LibraryName);
	GB_ASSERT(e->flags & EntityFlag_Used);

	mutex_lock(&m->gen->foreign_mutex);
	if (!ptr_set_update(&m->gen->foreign_libraries_set, e)) {
		array_add(&m->gen->foreign_libraries, e);
	}
	mutex_unlock(&m->gen->foreign_mutex);
}

gb_internal GB_COMPARE_PROC(foreign_library_cmp) {
	int cmp = 0;
	Entity *x = *(Entity **)a;
	Entity *y = *(Entity **)b;
	if (x == y) {
		return 0;
	}
	GB_ASSERT(x->kind == Entity_LibraryName);
	GB_ASSERT(y->kind == Entity_LibraryName);

	cmp = i64_cmp(x->LibraryName.priority_index, y->LibraryName.priority_index);
	if (cmp) {
		return cmp;
	}

	if (x->pkg != y->pkg) {
		isize order_x = x->pkg ? x->pkg->order : 0;
		isize order_y = y->pkg ? y->pkg->order : 0;
		cmp = isize_cmp(order_x, order_y);
		if (cmp) {
			return cmp;
		}
	}
	if (x->file != y->file) {
		String fullpath_x = x->file ? x->file->fullpath : (String{});
		String fullpath_y = y->file ? y->file->fullpath : (String{});
		String file_x = filename_from_path(fullpath_x);
		String file_y = filename_from_path(fullpath_y);

		cmp = string_compare(file_x, file_y);
		if (cmp) {
			return cmp;
		}
	}

	cmp = u64_cmp(x->order_in_src, y->order_in_src);
	if (cmp) {
		return cmp;
	}
	return i32_cmp(x->token.pos.offset, y->token.pos.offset);
}

gb_internal void lb_set_entity_from_other_modules_linkage_correctly(lbModule *other_module, Entity *e, String const &name) {
	if (other_module == nullptr) {
		return;
	}
	char const *cname = alloc_cstring(temporary_allocator(), name);

	LLVMValueRef other_global = nullptr;
	if (e->kind == Entity_Variable) {
		other_global = LLVMGetNamedGlobal(other_module->mod, cname);
	} else if (e->kind == Entity_Procedure) {
		other_global = LLVMGetNamedFunction(other_module->mod, cname);
	}
	if (other_global) {
		LLVMSetLinkage(other_global, LLVMExternalLinkage);
	}
}

gb_internal void lb_emit_init_context(lbProcedure *p, lbAddr addr) {
	GB_ASSERT(addr.kind == lbAddr_Context);
	GB_ASSERT(addr.ctx.sel.index.count == 0);

	auto args = array_make<lbValue>(permanent_allocator(), 1);
	args[0] = addr.addr;
	lb_emit_runtime_call(p, "__init_context", args);
}

gb_internal lbContextData *lb_push_context_onto_stack_from_implicit_parameter(lbProcedure *p) {
	Type *pt = base_type(p->type);
	GB_ASSERT(pt->kind == Type_Proc);
	GB_ASSERT(pt->Proc.calling_convention == ProcCC_Odin);

	String name = str_lit("__.context_ptr");

	Entity *e = alloc_entity_param(nullptr, make_token_ident(name), t_context_ptr, false, false);
	e->flags |= EntityFlag_NoAlias;

	LLVMValueRef context_ptr = LLVMGetParam(p->value, LLVMCountParams(p->value)-1);
	LLVMSetValueName2(context_ptr, cast(char const *)name.text, name.len);
	context_ptr = LLVMBuildPointerCast(p->builder, context_ptr, lb_type(p->module, e->type), "");

	lbValue param = {context_ptr, e->type};
	lb_add_entity(p->module, e, param);
	lbAddr ctx_addr = {};
	ctx_addr.kind = lbAddr_Context;
	ctx_addr.addr = param;

	lbContextData *cd = array_add_and_get(&p->context_stack);
	cd->ctx = ctx_addr;
	cd->scope_index = -1;
	cd->uses = +1; // make sure it has been used already
	return cd;
}

gb_internal lbContextData *lb_push_context_onto_stack(lbProcedure *p, lbAddr ctx) {
	ctx.kind = lbAddr_Context;
	lbContextData *cd = array_add_and_get(&p->context_stack);
	cd->ctx = ctx;
	cd->scope_index = p->scope_index;
	return cd;
}


gb_internal lbValue lb_equal_proc_for_type(lbModule *m, Type *type) {
	type = base_type(type);
	GB_ASSERT(is_type_comparable(type));

	Type *pt = alloc_type_pointer(type);
	LLVMTypeRef ptr_type = lb_type(m, pt);

	lbProcedure **found = map_get(&m->equal_procs, type);
	lbProcedure *compare_proc = nullptr;
	if (found) {
		compare_proc = *found;
		GB_ASSERT(compare_proc != nullptr);
		return {compare_proc->value, compare_proc->type};
	}

	static u32 proc_index = 0;

	char buf[32] = {};
	isize n = gb_snprintf(buf, 32, "__$equal%u", ++proc_index);
	char *str = gb_alloc_str_len(permanent_allocator(), buf, n-1);
	String proc_name = make_string_c(str);

	lbProcedure *p = lb_create_dummy_procedure(m, proc_name, t_equal_proc);
	map_set(&m->equal_procs, type, p);
	lb_begin_procedure_body(p);

	lb_add_attribute_to_proc(m, p->value, "readonly");
	lb_add_attribute_to_proc(m, p->value, "nounwind");

	LLVMValueRef x = LLVMGetParam(p->value, 0);
	LLVMValueRef y = LLVMGetParam(p->value, 1);
	x = LLVMBuildPointerCast(p->builder, x, ptr_type, "");
	y = LLVMBuildPointerCast(p->builder, y, ptr_type, "");
	lbValue lhs = {x, pt};
	lbValue rhs = {y, pt};

	lb_add_proc_attribute_at_index(p, 1+0, "nonnull");
	lb_add_proc_attribute_at_index(p, 1+1, "nonnull");

	lbBlock *block_same_ptr = lb_create_block(p, "same_ptr");
	lbBlock *block_diff_ptr = lb_create_block(p, "diff_ptr");

	lbValue same_ptr = lb_emit_comp(p, Token_CmpEq, lhs, rhs);
	lb_emit_if(p, same_ptr, block_same_ptr, block_diff_ptr);
	lb_start_block(p, block_same_ptr);
	LLVMBuildRet(p->builder, LLVMConstInt(lb_type(m, t_bool), 1, false));

	lb_start_block(p, block_diff_ptr);

	if (type->kind == Type_Struct) {
		type_set_offsets(type);

		lbBlock *block_false = lb_create_block(p, "bfalse");
		lbValue res = lb_const_bool(m, t_bool, true);

		for_array(i, type->Struct.fields) {
			lbBlock *next_block = lb_create_block(p, "btrue");

			lbValue pleft  = lb_emit_struct_ep(p, lhs, cast(i32)i);
			lbValue pright = lb_emit_struct_ep(p, rhs, cast(i32)i);
			lbValue left = lb_emit_load(p, pleft);
			lbValue right = lb_emit_load(p, pright);
			lbValue ok = lb_emit_comp(p, Token_CmpEq, left, right);

			lb_emit_if(p, ok, next_block, block_false);

			lb_emit_jump(p, next_block);
			lb_start_block(p, next_block);
		}

		LLVMBuildRet(p->builder, LLVMConstInt(lb_type(m, t_bool), 1, false));

		lb_start_block(p, block_false);

		LLVMBuildRet(p->builder, LLVMConstInt(lb_type(m, t_bool), 0, false));
	} else if (type->kind == Type_Union) {
		if (is_type_union_maybe_pointer(type)) {
			Type *v = type->Union.variants[0];
			Type *pv = alloc_type_pointer(v);

			lbValue left = lb_emit_load(p, lb_emit_conv(p, lhs, pv));
			lbValue right = lb_emit_load(p, lb_emit_conv(p, rhs, pv));

			lbValue ok = lb_emit_comp(p, Token_CmpEq, left, right);
			ok = lb_emit_conv(p, ok, t_bool);
			LLVMBuildRet(p->builder, ok.value);
		} else {
			lbBlock *block_false = lb_create_block(p, "bfalse");
			lbBlock *block_switch = lb_create_block(p, "bswitch");

			lbValue left_tag  = lb_emit_load(p, lb_emit_union_tag_ptr(p, lhs));
			lbValue right_tag = lb_emit_load(p, lb_emit_union_tag_ptr(p, rhs));

			lbValue tag_eq = lb_emit_comp(p, Token_CmpEq, left_tag, right_tag);
			lb_emit_if(p, tag_eq, block_switch, block_false);

			lb_start_block(p, block_switch);
			LLVMValueRef v_switch = LLVMBuildSwitch(p->builder, left_tag.value, block_false->block, cast(unsigned)type->Union.variants.count);


			for (Type *v : type->Union.variants) {
				lbBlock *case_block = lb_create_block(p, "bcase");
				lb_start_block(p, case_block);

				lbValue case_tag = lb_const_union_tag(p->module, type, v);

				Type *vp = alloc_type_pointer(v);

				lbValue left  = lb_emit_load(p, lb_emit_conv(p, lhs, vp));
				lbValue right = lb_emit_load(p, lb_emit_conv(p, rhs, vp));
				lbValue ok = lb_emit_comp(p, Token_CmpEq, left, right);
				ok = lb_emit_conv(p, ok, t_bool);

				LLVMBuildRet(p->builder, ok.value);


				LLVMAddCase(v_switch, case_tag.value, case_block->block);
			}

			lb_start_block(p, block_false);

			LLVMBuildRet(p->builder, LLVMConstInt(lb_type(m, t_bool), 0, false));
		}

	} else {
		lbValue left = lb_emit_load(p, lhs);
		lbValue right = lb_emit_load(p, rhs);
		lbValue ok = lb_emit_comp(p, Token_CmpEq, left, right);
		ok = lb_emit_conv(p, ok, t_bool);
		LLVMBuildRet(p->builder, ok.value);
	}

	lb_end_procedure_body(p);

	compare_proc = p;
	return {compare_proc->value, compare_proc->type};
}

gb_internal lbValue lb_simple_compare_hash(lbProcedure *p, Type *type, lbValue data, lbValue seed) {
	GB_ASSERT_MSG(is_type_simple_compare(type), "%s", type_to_string(type));

	auto args = array_make<lbValue>(permanent_allocator(), 3);
	args[0] = data;
	args[1] = seed;
	args[2] = lb_const_int(p->module, t_int, type_size_of(type));
	return lb_emit_runtime_call(p, "default_hasher", args);
}

gb_internal void lb_add_callsite_force_inline(lbProcedure *p, lbValue ret_value) {
	LLVMAddCallSiteAttribute(ret_value.value, LLVMAttributeIndex_FunctionIndex, lb_create_enum_attribute(p->module->ctx, "alwaysinline"));
}

gb_internal lbValue lb_hasher_proc_for_type(lbModule *m, Type *type) {
	type = core_type(type);
	GB_ASSERT_MSG(is_type_valid_for_keys(type), "%s", type_to_string(type));

	Type *pt = alloc_type_pointer(type);

	lbProcedure **found = map_get(&m->hasher_procs, type);
	if (found) {
		GB_ASSERT(*found != nullptr);
		return {(*found)->value, (*found)->type};
	}

	static std::atomic<u32> proc_index;

	char buf[32] = {};
	isize n = gb_snprintf(buf, 32, "__$hasher%u", 1+proc_index.fetch_add(1));
	char *str = gb_alloc_str_len(permanent_allocator(), buf, n-1);
	String proc_name = make_string_c(str);

	lbProcedure *p = lb_create_dummy_procedure(m, proc_name, t_hasher_proc);
	map_set(&m->hasher_procs, type, p);
	lb_begin_procedure_body(p);
	defer (lb_end_procedure_body(p));

	lb_add_attribute_to_proc(m, p->value, "readonly");
	lb_add_attribute_to_proc(m, p->value, "nounwind");

	LLVMValueRef x = LLVMGetParam(p->value, 0);
	LLVMValueRef y = LLVMGetParam(p->value, 1);
	lbValue data = {x, t_rawptr};
	lbValue seed = {y, t_uintptr};

	lb_add_proc_attribute_at_index(p, 1+0, "nonnull");
	lb_add_proc_attribute_at_index(p, 1+0, "readonly");

	if (is_type_simple_compare(type)) {
		lbValue res = lb_simple_compare_hash(p, type, data, seed);
		lb_add_callsite_force_inline(p, res);
		LLVMBuildRet(p->builder, res.value);
		return {p->value, p->type};
	}

	if (type->kind == Type_Struct)  {
		type_set_offsets(type);
		data = lb_emit_conv(p, data, t_u8_ptr);

		auto args = array_make<lbValue>(permanent_allocator(), 2);
		for_array(i, type->Struct.fields) {
			GB_ASSERT(type->Struct.offsets != nullptr);
			i64 offset = type->Struct.offsets[i];
			Entity *field = type->Struct.fields[i];
			lbValue field_hasher = lb_hasher_proc_for_type(m, field->type);
			lbValue ptr = lb_emit_ptr_offset(p, data, lb_const_int(m, t_uintptr, offset));

			args[0] = ptr;
			args[1] = seed;
			seed = lb_emit_call(p, field_hasher, args);
		}
		LLVMBuildRet(p->builder, seed.value);
	} else if (type->kind == Type_Union)  {
		auto args = array_make<lbValue>(permanent_allocator(), 2);

		if (is_type_union_maybe_pointer(type)) {
			Type *v = type->Union.variants[0];
			lbValue variant_hasher = lb_hasher_proc_for_type(m, v);

			args[0] = data;
			args[1] = seed;
			lbValue res = lb_emit_call(p, variant_hasher, args);
			lb_add_callsite_force_inline(p, res);
			LLVMBuildRet(p->builder, res.value);
		}

		lbBlock *end_block = lb_create_block(p, "bend");
		data = lb_emit_conv(p, data, pt);

		lbValue tag_ptr = lb_emit_union_tag_ptr(p, data);
		lbValue tag = lb_emit_load(p, tag_ptr);

		LLVMValueRef v_switch = LLVMBuildSwitch(p->builder, tag.value, end_block->block, cast(unsigned)type->Union.variants.count);

		for (Type *v : type->Union.variants) {
			lbBlock *case_block = lb_create_block(p, "bcase");
			lb_start_block(p, case_block);

			lbValue case_tag = lb_const_union_tag(p->module, type, v);

			lbValue variant_hasher = lb_hasher_proc_for_type(m, v);

			args[0] = data;
			args[1] = seed;
			lbValue res = lb_emit_call(p, variant_hasher, args);
			LLVMBuildRet(p->builder, res.value);

			LLVMAddCase(v_switch, case_tag.value, case_block->block);
		}

		lb_start_block(p, end_block);
		LLVMBuildRet(p->builder, seed.value);

	} else if (type->kind == Type_Array) {
		lbAddr pres = lb_add_local_generated(p, t_uintptr, false);
		lb_addr_store(p, pres, seed);

		auto args = array_make<lbValue>(permanent_allocator(), 2);
		lbValue elem_hasher = lb_hasher_proc_for_type(m, type->Array.elem);

		auto loop_data = lb_loop_start(p, cast(isize)type->Array.count, t_i32);

		data = lb_emit_conv(p, data, pt);

		lbValue ptr = lb_emit_array_ep(p, data, loop_data.idx);
		args[0] = ptr;
		args[1] = lb_addr_load(p, pres);
		lbValue new_seed = lb_emit_call(p, elem_hasher, args);
		lb_addr_store(p, pres, new_seed);

		lb_loop_end(p, loop_data);

		lbValue res = lb_addr_load(p, pres);
		LLVMBuildRet(p->builder, res.value);
	} else if (type->kind == Type_EnumeratedArray) {
		lbAddr res = lb_add_local_generated(p, t_uintptr, false);
		lb_addr_store(p, res, seed);

		auto args = array_make<lbValue>(permanent_allocator(), 2);
		lbValue elem_hasher = lb_hasher_proc_for_type(m, type->EnumeratedArray.elem);

		auto loop_data = lb_loop_start(p, cast(isize)type->EnumeratedArray.count, t_i32);

		data = lb_emit_conv(p, data, pt);

		lbValue ptr = lb_emit_array_ep(p, data, loop_data.idx);
		args[0] = ptr;
		args[1] = lb_addr_load(p, res);
		lbValue new_seed = lb_emit_call(p, elem_hasher, args);
		lb_addr_store(p, res, new_seed);

		lb_loop_end(p, loop_data);

		lbValue vres = lb_addr_load(p, res);
		LLVMBuildRet(p->builder, vres.value);
	} else if (is_type_cstring(type)) {
		auto args = array_make<lbValue>(permanent_allocator(), 2);
		args[0] = data;
		args[1] = seed;
		lbValue res = lb_emit_runtime_call(p, "default_hasher_cstring", args);
		lb_add_callsite_force_inline(p, res);
		LLVMBuildRet(p->builder, res.value);
	} else if (is_type_string(type)) {
		auto args = array_make<lbValue>(permanent_allocator(), 2);
		args[0] = data;
		args[1] = seed;
		lbValue res = lb_emit_runtime_call(p, "default_hasher_string", args);
		lb_add_callsite_force_inline(p, res);
		LLVMBuildRet(p->builder, res.value);
	} else {
		GB_PANIC("Unhandled type for hasher: %s", type_to_string(type));
	}

	return {p->value, p->type};
}


gb_internal lbValue lb_map_get_proc_for_type(lbModule *m, Type *type) {
	GB_ASSERT(!build_context.dynamic_map_calls);
	type = base_type(type);
	GB_ASSERT(type->kind == Type_Map);


	lbProcedure **found = map_get(&m->map_get_procs, type);
	if (found) {
		GB_ASSERT(*found != nullptr);
		return {(*found)->value, (*found)->type};
	}
	static std::atomic<u32> proc_index;

	char buf[32] = {};
	isize n = gb_snprintf(buf, 32, "__$map_get-%u", 1+proc_index.fetch_add(1));
	char *str = gb_alloc_str_len(permanent_allocator(), buf, n-1);
	String proc_name = make_string_c(str);

	lbProcedure *p = lb_create_dummy_procedure(m, proc_name, t_map_get_proc);
	map_set(&m->map_get_procs, type, p);
	lb_begin_procedure_body(p);
	defer (lb_end_procedure_body(p));

	LLVMSetLinkage(p->value, LLVMInternalLinkage);
	// lb_add_attribute_to_proc(m, p->value, "readonly");
	lb_add_attribute_to_proc(m, p->value, "nounwind");
	// if (build_context.ODIN_DEBUG) {
		lb_add_attribute_to_proc(m, p->value, "noinline");
	// }

	LLVMValueRef x = LLVMGetParam(p->value, 0);
	LLVMValueRef y = LLVMGetParam(p->value, 1);
	LLVMValueRef z = LLVMGetParam(p->value, 2);
	lbValue map_ptr = {x, t_rawptr};
	lbValue h       = {y, t_uintptr};
	lbValue key_ptr = {z, t_rawptr};

	lb_add_proc_attribute_at_index(p, 1+0, "nonnull");
	lb_add_proc_attribute_at_index(p, 1+0, "noalias");
	lb_add_proc_attribute_at_index(p, 1+0, "readonly");

	lb_add_proc_attribute_at_index(p, 1+2, "nonnull");
	lb_add_proc_attribute_at_index(p, 1+2, "noalias");
	lb_add_proc_attribute_at_index(p, 1+2, "readonly");

	lbBlock *loop_block = lb_create_block(p, "loop");
	lbBlock *hash_block = lb_create_block(p, "hash");
	lbBlock *probe_block = lb_create_block(p, "probe");
	lbBlock *increment_block = lb_create_block(p, "increment");
	lbBlock *hash_compare_block = lb_create_block(p, "hash_compare");
	lbBlock *key_compare_block = lb_create_block(p, "key_compare");
	lbBlock *value_block = lb_create_block(p, "value");
	lbBlock *nil_block = lb_create_block(p, "nil");

	map_ptr = lb_emit_conv(p, map_ptr, t_raw_map_ptr);
	lbValue map = lb_emit_load(p, map_ptr);

	lbValue length = lb_map_len(p, map);

	lb_emit_if(p, lb_emit_comp(p, Token_CmpEq, length, lb_const_nil(m, t_int)), nil_block, hash_block);
	lb_start_block(p, hash_block);

	key_ptr = lb_emit_conv(p, key_ptr, alloc_type_pointer(type->Map.key));
	lbValue key = lb_emit_load(p, key_ptr);

	lbAddr pos = lb_add_local_generated(p, t_uintptr, false);
	lbAddr distance = lb_add_local_generated(p, t_uintptr, true);
	lbValue capacity = lb_map_cap(p, map);
	lbValue mask = lb_emit_conv(p, lb_emit_arith(p, Token_Sub, capacity, lb_const_int(m, t_int, 1), t_int), t_uintptr);

	{
		auto args = array_make<lbValue>(heap_allocator(), 2);
		args[0] = map;
		args[1] = h;
		lb_addr_store(p, pos, lb_emit_runtime_call(p, "map_desired_position", args));
	}
	lbValue zero_uintptr = lb_const_int(m, t_uintptr, 0);
	lbValue one_uintptr = lb_const_int(m, t_uintptr, 1);

	lbValue ks = lb_map_data_uintptr(p, map);
	lbValue vs = lb_map_cell_index_static(p, type->Map.key, ks, capacity);
	lbValue hs = lb_map_cell_index_static(p, type->Map.value, vs, capacity);

	ks = lb_emit_conv(p, ks, alloc_type_pointer(type->Map.key));
	vs = lb_emit_conv(p, vs, alloc_type_pointer(type->Map.value));
	hs = lb_emit_conv(p, hs, alloc_type_pointer(t_uintptr));

	lb_emit_jump(p, loop_block);
	lb_start_block(p, loop_block);

	lbValue element_hash = lb_emit_load(p, lb_emit_ptr_offset(p, hs, lb_addr_load(p, pos)));
	{
		// if element_hash == 0 { return nil }
		lb_emit_if(p, lb_emit_comp(p, Token_CmpEq, element_hash, zero_uintptr), nil_block, probe_block);
	}

	lb_start_block(p, probe_block);
	{
		auto args = array_make<lbValue>(heap_allocator(), 3);
		args[0] = map;
		args[1] = element_hash;
		args[2] = lb_addr_load(p, pos);
		lbValue probe_distance = lb_emit_runtime_call(p, "map_probe_distance", args);
		lbValue cond = lb_emit_comp(p, Token_Gt, lb_addr_load(p, distance), probe_distance);
		lb_emit_if(p, cond, nil_block, hash_compare_block);
	}

	lb_start_block(p, hash_compare_block);
	{
		lb_emit_if(p, lb_emit_comp(p, Token_CmpEq, element_hash, h), key_compare_block, increment_block);
	}

	lb_start_block(p, key_compare_block);
	{
		lbValue element_key = lb_map_cell_index_static(p, type->Map.key, ks, lb_addr_load(p, pos));
		element_key = lb_emit_conv(p, element_key, ks.type);
		lbValue cond = lb_emit_comp(p, Token_CmpEq, lb_emit_load(p, element_key), key);
		lb_emit_if(p, cond, value_block, increment_block);
	}

	lb_start_block(p, value_block);
	{
		lbValue element_value = lb_map_cell_index_static(p, type->Map.value, vs, lb_addr_load(p, pos));
		element_value = lb_emit_conv(p, element_value, t_rawptr);
		LLVMBuildRet(p->builder, element_value.value);
	}

	lb_start_block(p, increment_block);
	{
		lbValue pp = lb_addr_load(p, pos);
		pp = lb_emit_arith(p, Token_Add, pp, one_uintptr, t_uintptr);
		pp = lb_emit_arith(p, Token_And, pp, mask, t_uintptr);
		lb_addr_store(p, pos, pp);
		lb_emit_increment(p, distance.addr);
	}
	lb_emit_jump(p, loop_block);

	lb_start_block(p, nil_block);
	{
		lbValue res = lb_const_nil(m, t_rawptr);
		LLVMBuildRet(p->builder, res.value);
	}

	gb_printf_err("%s\n", LLVMPrintValueToString(p->value));


	return {p->value, p->type};
}

// gb_internal void lb_debug_print(lbProcedure *p, String const &str) {
// 	auto args = array_make<lbValue>(heap_allocator(), 1);
// 	args[0] = lb_const_string(p->module, str);
// 	lb_emit_runtime_call(p, "print_string", args);
// }

gb_internal lbValue lb_map_set_proc_for_type(lbModule *m, Type *type) {
	GB_ASSERT(!build_context.dynamic_map_calls);
	type = base_type(type);
	GB_ASSERT(type->kind == Type_Map);


	lbProcedure **found = map_get(&m->map_set_procs, type);
	if (found) {
		GB_ASSERT(*found != nullptr);
		return {(*found)->value, (*found)->type};
	}
	static u32 proc_index = 0;

	char buf[32] = {};
	isize n = gb_snprintf(buf, 32, "__$map_set-%u", ++proc_index);
	char *str = gb_alloc_str_len(permanent_allocator(), buf, n-1);
	String proc_name = make_string_c(str);

	lbProcedure *p = lb_create_dummy_procedure(m, proc_name, t_map_set_proc);
	map_set(&m->map_set_procs, type, p);
	lb_begin_procedure_body(p);
	defer (lb_end_procedure_body(p));

	LLVMSetLinkage(p->value, LLVMInternalLinkage);
	lb_add_attribute_to_proc(m, p->value, "nounwind");
	if (build_context.ODIN_DEBUG) {
		lb_add_attribute_to_proc(m, p->value, "noinline");
	}

	lbValue map_ptr      = {LLVMGetParam(p->value, 0), t_rawptr};
	lbValue hash         = {LLVMGetParam(p->value, 1), t_uintptr};
	lbValue key_ptr      = {LLVMGetParam(p->value, 2), t_rawptr};
	lbValue value_ptr    = {LLVMGetParam(p->value, 3), t_rawptr};
	lbValue location_ptr = {LLVMGetParam(p->value, 4), t_source_code_location_ptr};

	map_ptr = lb_emit_conv(p, map_ptr, alloc_type_pointer(type));
	key_ptr = lb_emit_conv(p, key_ptr, alloc_type_pointer(type->Map.key));

	lb_add_proc_attribute_at_index(p, 1+0, "nonnull");
	lb_add_proc_attribute_at_index(p, 1+0, "noalias");

	lb_add_proc_attribute_at_index(p, 1+2, "nonnull");
	if (!are_types_identical(type->Map.key, type->Map.value)) {
		lb_add_proc_attribute_at_index(p, 1+2, "noalias");
	}
	lb_add_proc_attribute_at_index(p, 1+2, "readonly");

	lb_add_proc_attribute_at_index(p, 1+3, "nonnull");
	if (!are_types_identical(type->Map.key, type->Map.value)) {
		lb_add_proc_attribute_at_index(p, 1+3, "noalias");
	}
	lb_add_proc_attribute_at_index(p, 1+3, "readonly");

	lb_add_proc_attribute_at_index(p, 1+4, "nonnull");
	lb_add_proc_attribute_at_index(p, 1+4, "noalias");
	lb_add_proc_attribute_at_index(p, 1+4, "readonly");

	////
	lbValue found_ptr = {};
	{
		lbValue map_get_proc = lb_map_get_proc_for_type(m, type);

		auto args = array_make<lbValue>(permanent_allocator(), 3);
		args[0] = lb_emit_conv(p, map_ptr, t_rawptr);
		args[1] = hash;
		args[2] = key_ptr;

		found_ptr = lb_emit_call(p, map_get_proc, args);
	}


	lbBlock *found_block      = lb_create_block(p, "found");
	lbBlock *check_grow_block = lb_create_block(p, "check-grow");
	lbBlock *grow_fail_block  = lb_create_block(p, "grow-fail");
	lbBlock *insert_block     = lb_create_block(p, "insert");

	lb_emit_if(p, lb_emit_comp_against_nil(p, Token_NotEq, found_ptr), found_block, check_grow_block);
	lb_start_block(p, found_block);
	{
		lb_mem_copy_non_overlapping(p, found_ptr, value_ptr, lb_const_int(m, t_int, type_size_of(type->Map.value)));
		LLVMBuildRet(p->builder, lb_emit_conv(p, found_ptr, t_rawptr).value);
	}
	lb_start_block(p, check_grow_block);


	lbValue map_info = lb_gen_map_info_ptr(p->module, type);

	{
		auto args = array_make<lbValue>(permanent_allocator(), 3);
		args[0] = lb_emit_conv(p, map_ptr, t_rawptr);
		args[1] = map_info;
		args[2] = lb_emit_load(p, location_ptr);
		lbValue grow_err = lb_emit_runtime_call(p, "__dynamic_map_check_grow", args);

		lb_emit_if(p, lb_emit_comp_against_nil(p, Token_NotEq, grow_err), grow_fail_block, insert_block);

		lb_start_block(p, grow_fail_block);
		LLVMBuildRet(p->builder, LLVMConstNull(lb_type(m, t_rawptr)));
	}

	lb_start_block(p, insert_block);
	{
		auto args = array_make<lbValue>(permanent_allocator(), 5);
		args[0] = lb_emit_conv(p, map_ptr, t_rawptr);
		args[1] = map_info;
		args[2] = hash;
		args[3] = lb_emit_conv(p, key_ptr,   t_uintptr);
		args[4] = lb_emit_conv(p, value_ptr, t_uintptr);

		lbValue result = lb_emit_runtime_call(p, "map_insert_hash_dynamic", args);

		lb_emit_increment(p, lb_map_len_ptr(p, map_ptr));

		LLVMBuildRet(p->builder, lb_emit_conv(p, result, t_rawptr).value);
	}

	return {p->value, p->type};
}


gb_internal lbValue lb_generate_anonymous_proc_lit(lbModule *m, String const &prefix_name, Ast *expr, lbProcedure *parent) {
	MUTEX_GUARD(&m->gen->anonymous_proc_lits_mutex);

	lbProcedure **found = map_get(&m->gen->anonymous_proc_lits, expr);
	if (found) {
		return lb_find_procedure_value_from_entity(m, (*found)->entity);
	}

	ast_node(pl, ProcLit, expr);

	// NOTE(bill): Generate a new name
	// parent$count
	isize name_len = prefix_name.len + 1 + 8 + 1;
	char *name_text = gb_alloc_array(permanent_allocator(), char, name_len);
	i32 name_id = cast(i32)m->gen->anonymous_proc_lits.count;

	name_len = gb_snprintf(name_text, name_len, "%.*s$anon-%d", LIT(prefix_name), name_id);
	String name = make_string((u8 *)name_text, name_len-1);

	Type *type = type_of_expr(expr);

	Token token = {};
	token.pos = ast_token(expr).pos;
	token.kind = Token_Ident;
	token.string = name;
	Entity *e = alloc_entity_procedure(nullptr, token, type, pl->tags);
	e->file = expr->file();
	e->decl_info = pl->decl;
	e->code_gen_module = m;
	e->flags |= EntityFlag_ProcBodyChecked;
	lbProcedure *p = lb_create_procedure(m, e);

	lbValue value = {};
	value.value = p->value;
	value.type = p->type;

	array_add(&m->procedures_to_generate, p);
	if (parent != nullptr) {
		array_add(&parent->children, p);
	} else {
		string_map_set(&m->members, name, value);
	}

	map_set(&m->gen->anonymous_proc_lits, expr, p);

	return value;
}


gb_internal lbValue lb_gen_map_cell_info_ptr(lbModule *m, Type *type) {
	lbAddr *found = map_get(&m->map_cell_info_map, type);
	if (found) {
		return found->addr;
	}

	i64 size = 0, len = 0;
	map_cell_size_and_len(type, &size, &len);

	LLVMValueRef const_values[4] = {};
	const_values[0] = lb_const_int(m, t_uintptr, type_size_of(type)).value;
	const_values[1] = lb_const_int(m, t_uintptr, type_align_of(type)).value;
	const_values[2] = lb_const_int(m, t_uintptr, size).value;
	const_values[3] = lb_const_int(m, t_uintptr, len).value;
	LLVMValueRef llvm_res =  llvm_const_named_struct(m, t_map_cell_info, const_values, gb_count_of(const_values));
	lbValue res = {llvm_res, t_map_cell_info};

	lbAddr addr = lb_add_global_generated(m, t_map_cell_info, res, nullptr);
	lb_make_global_private_const(addr);

	map_set(&m->map_cell_info_map, type, addr);

	return addr.addr;
}
gb_internal lbValue lb_gen_map_info_ptr(lbModule *m, Type *map_type) {
	map_type = base_type(map_type);
	GB_ASSERT(map_type->kind == Type_Map);

	lbAddr *found = map_get(&m->map_info_map, map_type);
	if (found) {
		return found->addr;
	}

	GB_ASSERT(t_map_info != nullptr);
	GB_ASSERT(t_map_cell_info != nullptr);

	LLVMValueRef key_cell_info   = lb_gen_map_cell_info_ptr(m, map_type->Map.key).value;
	LLVMValueRef value_cell_info = lb_gen_map_cell_info_ptr(m, map_type->Map.value).value;

	LLVMValueRef const_values[4] = {};
	const_values[0] = key_cell_info;
	const_values[1] = value_cell_info;
	const_values[2] = lb_hasher_proc_for_type(m, map_type->Map.key).value;
	const_values[3] = lb_equal_proc_for_type(m, map_type->Map.key).value;

	LLVMValueRef llvm_res = llvm_const_named_struct(m, t_map_info, const_values, gb_count_of(const_values));
	lbValue res = {llvm_res, t_map_info};

	lbAddr addr = lb_add_global_generated(m, t_map_info, res, nullptr);
	lb_make_global_private_const(addr);

	map_set(&m->map_info_map, map_type, addr);
	return addr.addr;
}

gb_internal lbValue lb_const_hash(lbModule *m, lbValue key, Type *key_type) {
	if (true) {
		return {};
	}

	lbValue hashed_key = {};

#if 0
	if (lb_is_const(key)) {
		u64 hash = 0xcbf29ce484222325;
		if (is_type_cstring(key_type)) {
			size_t length = 0;
			char const *text = LLVMGetAsString(key.value, &length);
			hash = fnv64a(text, cast(isize)length);
		} else if (is_type_string(key_type)) {
			unsigned data_indices[] = {0};
			unsigned len_indices[] = {1};
			LLVMValueRef data = LLVMConstExtractValue(key.value, data_indices, gb_count_of(data_indices));
			LLVMValueRef len  = LLVMConstExtractValue(key.value, len_indices,  gb_count_of(len_indices));
			i64 length = LLVMConstIntGetSExtValue(len);
			char const *text = nullptr;
			if (false && length != 0) {
			if (LLVMGetConstOpcode(data) != LLVMGetElementPtr) {
					return {};
				}
				// TODO(bill): THIS IS BROKEN! THIS NEEDS FIXING :P

				size_t ulength = 0;
				text = LLVMGetAsString(data, &ulength);
				gb_printf_err("%lld %llu %s\n", length, ulength, text);
				length = gb_min(length, cast(i64)ulength);
			}
			hash = fnv64a(text, cast(isize)length);
		} else {
			return {};
		}
		// TODO(bill): other const hash types

		if (build_context.word_size == 4) {
			hash &= 0xffffffffull;
		}
		hashed_key = lb_const_int(m, t_uintptr, hash);
	}
#endif
	return hashed_key;
}

gb_internal lbValue lb_gen_map_key_hash(lbProcedure *p, lbValue key, Type *key_type, lbValue *key_ptr_) {
	lbValue key_ptr = lb_address_from_load_or_generate_local(p, key);
	key_ptr = lb_emit_conv(p, key_ptr, t_rawptr);

	if (key_ptr_) *key_ptr_ = key_ptr;

	lbValue hashed_key = lb_const_hash(p->module, key, key_type);
	if (hashed_key.value == nullptr) {
		lbValue hasher = lb_hasher_proc_for_type(p->module, key_type);

		auto args = array_make<lbValue>(permanent_allocator(), 2);
		args[0] = key_ptr;
		args[1] = lb_const_int(p->module, t_uintptr, 0);
		hashed_key = lb_emit_call(p, hasher, args);
	}

	return hashed_key;
}

gb_internal lbValue lb_internal_dynamic_map_get_ptr(lbProcedure *p, lbValue const &map_ptr, lbValue const &key) {
	Type *map_type = base_type(type_deref(map_ptr.type));
	GB_ASSERT(map_type->kind == Type_Map);

	lbValue ptr = {};
	lbValue key_ptr = {};
	lbValue hash = lb_gen_map_key_hash(p, key, map_type->Map.key, &key_ptr);

	if (build_context.dynamic_map_calls) {
		auto args = array_make<lbValue>(permanent_allocator(), 4);
		args[0] = lb_emit_transmute(p, map_ptr, t_raw_map_ptr);
		args[1] = lb_gen_map_info_ptr(p->module, map_type);
		args[2] = hash;
		args[3] = key_ptr;

		ptr = lb_emit_runtime_call(p, "__dynamic_map_get", args);
	} else {
		lbValue map_get_proc = lb_map_get_proc_for_type(p->module, map_type);

		auto args = array_make<lbValue>(permanent_allocator(), 3);
		args[0] = lb_emit_conv(p, map_ptr, t_rawptr);
		args[1] = hash;
		args[2] = key_ptr;

		ptr = lb_emit_call(p, map_get_proc, args);
	}
	return lb_emit_conv(p, ptr, alloc_type_pointer(map_type->Map.value));
}

gb_internal void lb_internal_dynamic_map_set(lbProcedure *p, lbValue const &map_ptr, Type *map_type,
                                             lbValue const &map_key, lbValue const &map_value, Ast *node) {
	map_type = base_type(map_type);
	GB_ASSERT(map_type->kind == Type_Map);

	lbValue key_ptr = {};
	lbValue hash = lb_gen_map_key_hash(p, map_key, map_type->Map.key, &key_ptr);

	lbValue v = lb_emit_conv(p, map_value, map_type->Map.value);
	lbValue value_ptr = lb_address_from_load_or_generate_local(p, v);

	if (build_context.dynamic_map_calls) {
		auto args = array_make<lbValue>(permanent_allocator(), 6);
		args[0] = lb_emit_conv(p, map_ptr, t_raw_map_ptr);
		args[1] = lb_gen_map_info_ptr(p->module, map_type);
		args[2] = hash;
		args[3] = lb_emit_conv(p, key_ptr, t_rawptr);
		args[4] = lb_emit_conv(p, value_ptr, t_rawptr);
		args[5] = lb_emit_source_code_location_as_global(p, node);
		lb_emit_runtime_call(p, "__dynamic_map_set", args);
	} else {
		lbValue map_set_proc = lb_map_set_proc_for_type(p->module, map_type);

		auto args = array_make<lbValue>(permanent_allocator(), 5);
		args[0] = lb_emit_conv(p, map_ptr, t_rawptr);
		args[1] = hash;
		args[2] = lb_emit_conv(p, key_ptr, t_rawptr);
		args[3] = lb_emit_conv(p, value_ptr, t_rawptr);
		args[4] = lb_emit_source_code_location_as_global(p, node);

		lb_emit_call(p, map_set_proc, args);
	}
}

gb_internal lbValue lb_dynamic_map_reserve(lbProcedure *p, lbValue const &map_ptr, isize const capacity, TokenPos const &pos) {
	GB_ASSERT(!build_context.no_dynamic_literals);

	String proc_name = {};
	if (p->entity) {
		proc_name = p->entity->token.string;
	}

	auto args = array_make<lbValue>(permanent_allocator(), 4);
	args[0] = lb_emit_conv(p, map_ptr, t_rawptr);
	args[1] = lb_gen_map_info_ptr(p->module, type_deref(map_ptr.type));
	args[2] = lb_const_int(p->module, t_uint, capacity);
	args[3] = lb_emit_source_code_location_as_global(p, proc_name, pos);
	return lb_emit_runtime_call(p, "__dynamic_map_reserve", args);
}


struct lbGlobalVariable {
	lbValue var;
	lbValue init;
	DeclInfo *decl;
	bool is_initialized;
};

gb_internal lbProcedure *lb_create_startup_type_info(lbModule *m) {
	if (build_context.disallow_rtti) {
		return nullptr;
	}
	Type *proc_type = alloc_type_proc(nullptr, nullptr, 0, nullptr, 0, false, ProcCC_CDecl);

	lbProcedure *p = lb_create_dummy_procedure(m, str_lit(LB_STARTUP_TYPE_INFO_PROC_NAME), proc_type);
	p->is_startup = true;
	LLVMSetLinkage(p->value, LLVMInternalLinkage);

	lb_add_attribute_to_proc(m, p->value, "nounwind");

	lb_begin_procedure_body(p);

	lb_setup_type_info_data(p);

	lb_end_procedure_body(p);

	if (!m->debug_builder && LLVMVerifyFunction(p->value, LLVMReturnStatusAction)) {
		gb_printf_err("LLVM CODE GEN FAILED FOR PROCEDURE: %s\n", "main");
		LLVMDumpValue(p->value);
		gb_printf_err("\n\n\n\n");
		LLVMVerifyFunction(p->value, LLVMAbortProcessAction);
	}
	return p;
}

gb_internal lbProcedure *lb_create_objc_names(lbModule *main_module) {
	if (build_context.metrics.os != TargetOs_darwin) {
		return nullptr;
	}
	Type *proc_type = alloc_type_proc(nullptr, nullptr, 0, nullptr, 0, false, ProcCC_CDecl);
	lbProcedure *p = lb_create_dummy_procedure(main_module, str_lit("__$init_objc_names"), proc_type);
	lb_add_attribute_to_proc(p->module, p->value, "nounwind");
	p->is_startup = true;
	return p;
}

gb_internal void lb_finalize_objc_names(lbProcedure *p) {
	if (p == nullptr) {
		return;
	}
	lbModule *m = p->module;

	auto args = array_make<lbValue>(permanent_allocator(), 1);

	LLVMSetLinkage(p->value, LLVMInternalLinkage);
	lb_begin_procedure_body(p);
	for (auto const &entry : m->objc_classes) {
		String name = entry.key;
		args[0] = lb_const_value(m, t_cstring, exact_value_string(name));
		lbValue ptr = lb_emit_runtime_call(p, "objc_lookUpClass", args);
		lb_addr_store(p, entry.value, ptr);
	}

	for (auto const &entry : m->objc_selectors) {
		String name = entry.key;
		args[0] = lb_const_value(m, t_cstring, exact_value_string(name));
		lbValue ptr = lb_emit_runtime_call(p, "sel_registerName", args);
		lb_addr_store(p, entry.value, ptr);
	}

	lb_end_procedure_body(p);
}

gb_internal lbProcedure *lb_create_startup_runtime(lbModule *main_module, lbProcedure *startup_type_info, lbProcedure *objc_names, Array<lbGlobalVariable> &global_variables) { // Startup Runtime
	Type *proc_type = alloc_type_proc(nullptr, nullptr, 0, nullptr, 0, false, ProcCC_Odin);

	lbProcedure *p = lb_create_dummy_procedure(main_module, str_lit(LB_STARTUP_RUNTIME_PROC_NAME), proc_type);
	p->is_startup = true;

	lb_begin_procedure_body(p);

	if (startup_type_info) {
		LLVMBuildCall2(p->builder, lb_type_internal_for_procedures_raw(main_module, startup_type_info->type), startup_type_info->value, nullptr, 0, "");
	}

	if (objc_names) {
		LLVMBuildCall2(p->builder, lb_type_internal_for_procedures_raw(main_module, objc_names->type), objc_names->value, nullptr, 0, "");
	}

	for (auto &var : global_variables) {
		if (var.is_initialized) {
			continue;
		}

		lbModule *entity_module = main_module;

		Entity *e = var.decl->entity;
		GB_ASSERT(e->kind == Entity_Variable);
		e->code_gen_module = entity_module;

		Ast *init_expr = var.decl->init_expr;
		if (init_expr != nullptr)  {
			lbValue init = lb_build_expr(p, init_expr);
			if (init.value == nullptr) {
				LLVMTypeRef global_type = llvm_addr_type(p->module, var.var);
				if (is_type_untyped_undef(init.type)) {
					// LLVMSetInitializer(var.var.value, LLVMGetUndef(global_type));
					LLVMSetInitializer(var.var.value, LLVMConstNull(global_type));
					var.is_initialized = true;
					continue;
				} else if (is_type_untyped_nil(init.type)) {
					LLVMSetInitializer(var.var.value, LLVMConstNull(global_type));
					var.is_initialized = true;
					continue;
				}
				GB_PANIC("Invalid init value, got %s", expr_to_string(init_expr));
			}

			if (is_type_any(e->type) || is_type_union(e->type)) {
				var.init = init;
			} else if (lb_is_const_or_global(init)) {
				if (!var.is_initialized) {
					if (is_type_proc(init.type)) {
						init.value = LLVMConstPointerCast(init.value, lb_type(p->module, init.type));
					}
					LLVMSetInitializer(var.var.value, init.value);
					var.is_initialized = true;
					continue;
				}
			} else {
				var.init = init;
			}
		}

		if (var.init.value != nullptr) {
			GB_ASSERT(!var.is_initialized);
			Type *t = type_deref(var.var.type);

			if (is_type_any(t)) {
				// NOTE(bill): Edge case for 'any' type
				Type *var_type = default_type(var.init.type);
				lbAddr g = lb_add_global_generated(main_module, var_type, var.init);
				lb_addr_store(p, g, var.init);
				lbValue gp = lb_addr_get_ptr(p, g);

				lbValue data = lb_emit_struct_ep(p, var.var, 0);
				lbValue ti   = lb_emit_struct_ep(p, var.var, 1);
				lb_emit_store(p, data, lb_emit_conv(p, gp, t_rawptr));
				lb_emit_store(p, ti,   lb_type_info(main_module, var_type));
			} else {
				LLVMTypeRef vt = llvm_addr_type(p->module, var.var);
				lbValue src0 = lb_emit_conv(p, var.init, t);
				LLVMValueRef src = OdinLLVMBuildTransmute(p, src0.value, vt);
				LLVMValueRef dst = var.var.value;
				LLVMBuildStore(p->builder, src, dst);
			}

			var.is_initialized = true;
		}
	}
	
	CheckerInfo *info = main_module->gen->info;
	
	for (Entity *e : info->init_procedures) {
		lbValue value = lb_find_procedure_value_from_entity(main_module, e);
		lb_emit_call(p, value, {}, ProcInlining_none);
	}


	lb_end_procedure_body(p);

	if (!main_module->debug_builder && LLVMVerifyFunction(p->value, LLVMReturnStatusAction)) {
		gb_printf_err("LLVM CODE GEN FAILED FOR PROCEDURE: %s\n", "main");
		LLVMDumpValue(p->value);
		gb_printf_err("\n\n\n\n");
		LLVMVerifyFunction(p->value, LLVMAbortProcessAction);
	}

	return p;
}

gb_internal lbProcedure *lb_create_cleanup_runtime(lbModule *main_module) { // Cleanup Runtime
	Type *proc_type = alloc_type_proc(nullptr, nullptr, 0, nullptr, 0, false, ProcCC_Odin);

	lbProcedure *p = lb_create_dummy_procedure(main_module, str_lit(LB_CLEANUP_RUNTIME_PROC_NAME), proc_type);
	p->is_startup = true;

	lb_begin_procedure_body(p);

	CheckerInfo *info = main_module->gen->info;

	for (Entity *e : info->fini_procedures) {
		lbValue value = lb_find_procedure_value_from_entity(main_module, e);
		lb_emit_call(p, value, {}, ProcInlining_none);
	}

	lb_end_procedure_body(p);

	if (!main_module->debug_builder && LLVMVerifyFunction(p->value, LLVMReturnStatusAction)) {
		gb_printf_err("LLVM CODE GEN FAILED FOR PROCEDURE: %s\n", "main");
		LLVMDumpValue(p->value);
		gb_printf_err("\n\n\n\n");
		LLVMVerifyFunction(p->value, LLVMAbortProcessAction);
	}

	return p;
}


gb_internal WORKER_TASK_PROC(lb_generate_procedures_and_types_per_module) {
	lbModule *m = cast(lbModule *)data;
	for (Entity *e : m->global_procedures_and_types_to_create) {
		String mangled_name = lb_get_entity_name(m, e);

		switch (e->kind) {
		case Entity_TypeName:
			lb_type(m, e->type);
			break;
		case Entity_Procedure:
			array_add(&m->procedures_to_generate, lb_create_procedure(m, e));
			break;
		}
	}
	return 0;
}

gb_internal void lb_create_global_procedures_and_types(lbGenerator *gen, CheckerInfo *info, bool do_threading) {
	auto *min_dep_set = &info->minimum_dependency_set;

	for (Entity *e : info->entities) {
		String  name  = e->token.string;
		Scope * scope = e->scope;

		if ((scope->flags & ScopeFlag_File) == 0) {
			continue;
		}

		Scope *package_scope = scope->parent;
		GB_ASSERT(package_scope->flags & ScopeFlag_Pkg);

		switch (e->kind) {
		case Entity_Variable:
			// NOTE(bill): Handled above as it requires a specific load order
			continue;
		case Entity_ProcGroup:
			continue;

		case Entity_TypeName:
		case Entity_Procedure:
			break;
		case Entity_Constant:
			if (build_context.ODIN_DEBUG) {
				add_debug_info_for_global_constant_from_entity(gen, e);
			}
			break;
		}

		bool polymorphic_struct = false;
		if (e->type != nullptr && e->kind == Entity_TypeName) {
			Type *bt = base_type(e->type);
			if (bt->kind == Type_Struct) {
				polymorphic_struct = is_type_polymorphic(bt);
			}
		}

		if (!polymorphic_struct && !ptr_set_exists(min_dep_set, e)) {
			// NOTE(bill): Nothing depends upon it so doesn't need to be built
			continue;
		}

		lbModule *m = &gen->default_module;
		if (USE_SEPARATE_MODULES) {
			m = lb_module_of_entity(gen, e);
		}

		array_add(&m->global_procedures_and_types_to_create, e);
	}

	for (auto const &entry : gen->modules) {
		lbModule *m = entry.value;
		if (do_threading) {
			thread_pool_add_task(lb_generate_procedures_and_types_per_module, m);
		} else {
			lb_generate_procedures_and_types_per_module(m);
		}
	}

	thread_pool_wait();
}

gb_internal void lb_generate_procedure(lbModule *m, lbProcedure *p);


gb_internal bool lb_is_module_empty(lbModule *m) {
	if (LLVMGetFirstFunction(m->mod) == nullptr &&
	    LLVMGetFirstGlobal(m->mod) == nullptr) {
		return true;
	}
	for (auto fn = LLVMGetFirstFunction(m->mod); fn != nullptr; fn = LLVMGetNextFunction(fn)) {
		if (LLVMGetFirstBasicBlock(fn) != nullptr) {
			return false;
		}
	}

	for (auto g = LLVMGetFirstGlobal(m->mod); g != nullptr; g = LLVMGetNextGlobal(g)) {
		if (LLVMGetLinkage(g) == LLVMExternalLinkage) {
			continue;
		}
		if (!LLVMIsExternallyInitialized(g)) {
			return false;
		}
	}
	return true;
}

struct lbLLVMEmitWorker {
	LLVMTargetMachineRef target_machine;
	LLVMCodeGenFileType code_gen_file_type;
	String filepath_obj;
	lbModule *m;
};

gb_internal WORKER_TASK_PROC(lb_llvm_emit_worker_proc) {
	GB_ASSERT(MULTITHREAD_OBJECT_GENERATION);

	char *llvm_error = nullptr;

	auto wd = cast(lbLLVMEmitWorker *)data;

	if (LLVMTargetMachineEmitToFile(wd->target_machine, wd->m->mod, cast(char *)wd->filepath_obj.text, wd->code_gen_file_type, &llvm_error)) {
		gb_printf_err("LLVM Error: %s\n", llvm_error);
		gb_exit(1);
	}
	debugf("Generated File: %.*s\n", LIT(wd->filepath_obj));
	return 0;
}


gb_internal void lb_llvm_function_pass_per_function_internal(lbModule *module, lbProcedure *p, lbFunctionPassManagerKind pass_manager_kind = lbFunctionPassManager_default) {
	LLVMPassManagerRef pass_manager = module->function_pass_managers[pass_manager_kind];
	lb_run_function_pass_manager(pass_manager, p);
}

gb_internal WORKER_TASK_PROC(lb_llvm_function_pass_per_module) {
	lbModule *m = cast(lbModule *)data;
	{
		GB_ASSERT(m->function_pass_managers[lbFunctionPassManager_default] == nullptr);

		m->function_pass_managers[lbFunctionPassManager_default]                = LLVMCreateFunctionPassManagerForModule(m->mod);
		m->function_pass_managers[lbFunctionPassManager_default_without_memcpy] = LLVMCreateFunctionPassManagerForModule(m->mod);
		m->function_pass_managers[lbFunctionPassManager_minimal]                = LLVMCreateFunctionPassManagerForModule(m->mod);
		m->function_pass_managers[lbFunctionPassManager_size]                   = LLVMCreateFunctionPassManagerForModule(m->mod);
		m->function_pass_managers[lbFunctionPassManager_speed]                  = LLVMCreateFunctionPassManagerForModule(m->mod);

		LLVMInitializeFunctionPassManager(m->function_pass_managers[lbFunctionPassManager_default]);
		LLVMInitializeFunctionPassManager(m->function_pass_managers[lbFunctionPassManager_default_without_memcpy]);
		LLVMInitializeFunctionPassManager(m->function_pass_managers[lbFunctionPassManager_minimal]);
		LLVMInitializeFunctionPassManager(m->function_pass_managers[lbFunctionPassManager_size]);
		LLVMInitializeFunctionPassManager(m->function_pass_managers[lbFunctionPassManager_speed]);

		lb_populate_function_pass_manager(m, m->function_pass_managers[lbFunctionPassManager_default],                false, build_context.optimization_level);
		lb_populate_function_pass_manager(m, m->function_pass_managers[lbFunctionPassManager_default_without_memcpy], true,  build_context.optimization_level);
		lb_populate_function_pass_manager_specific(m, m->function_pass_managers[lbFunctionPassManager_minimal], 0);
		lb_populate_function_pass_manager_specific(m, m->function_pass_managers[lbFunctionPassManager_size],    1);
		lb_populate_function_pass_manager_specific(m, m->function_pass_managers[lbFunctionPassManager_speed],   2);

		LLVMFinalizeFunctionPassManager(m->function_pass_managers[lbFunctionPassManager_default]);
		LLVMFinalizeFunctionPassManager(m->function_pass_managers[lbFunctionPassManager_default_without_memcpy]);
		LLVMFinalizeFunctionPassManager(m->function_pass_managers[lbFunctionPassManager_minimal]);
		LLVMFinalizeFunctionPassManager(m->function_pass_managers[lbFunctionPassManager_size]);
		LLVMFinalizeFunctionPassManager(m->function_pass_managers[lbFunctionPassManager_speed]);
	}

	if (m == &m->gen->default_module) {
		lb_llvm_function_pass_per_function_internal(m, m->gen->startup_type_info);
		lb_llvm_function_pass_per_function_internal(m, m->gen->startup_runtime);
		lb_llvm_function_pass_per_function_internal(m, m->gen->cleanup_runtime);
		lb_llvm_function_pass_per_function_internal(m, m->gen->objc_names);
	}

	for (lbProcedure *p : m->procedures_to_generate) {
		if (p->body != nullptr) { // Build Procedure
			lbFunctionPassManagerKind pass_manager_kind = lbFunctionPassManager_default;
			if (p->flags & lbProcedureFlag_WithoutMemcpyPass) {
				pass_manager_kind = lbFunctionPassManager_default_without_memcpy;
			} else {
				if (p->entity && p->entity->kind == Entity_Procedure) {
					switch (p->entity->Procedure.optimization_mode) {
					case ProcedureOptimizationMode_None:
					case ProcedureOptimizationMode_Minimal:
						pass_manager_kind = lbFunctionPassManager_minimal;
						break;
					case ProcedureOptimizationMode_Size:
						pass_manager_kind = lbFunctionPassManager_size;
						break;
					case ProcedureOptimizationMode_Speed:
						pass_manager_kind = lbFunctionPassManager_speed;
						break;
					}
				}
			}

			lb_llvm_function_pass_per_function_internal(m, p, pass_manager_kind);
		}
	}

	for (auto const &entry : m->equal_procs) {
		lbProcedure *p = entry.value;
		lb_llvm_function_pass_per_function_internal(m, p);
	}
	for (auto const &entry : m->hasher_procs) {
		lbProcedure *p = entry.value;
		lb_llvm_function_pass_per_function_internal(m, p);
	}
	for (auto const &entry : m->map_get_procs) {
		lbProcedure *p = entry.value;
		lb_llvm_function_pass_per_function_internal(m, p);
	}
	for (auto const &entry : m->map_set_procs) {
		lbProcedure *p = entry.value;
		lb_llvm_function_pass_per_function_internal(m, p);
	}

	return 0;
}


struct lbLLVMModulePassWorkerData {
	lbModule *m;
	LLVMTargetMachineRef target_machine;
};

gb_internal WORKER_TASK_PROC(lb_llvm_module_pass_worker_proc) {
	auto wd = cast(lbLLVMModulePassWorkerData *)data;

	lb_run_remove_unused_function_pass(wd->m);
	lb_run_remove_unused_globals_pass(wd->m);

	LLVMPassManagerRef module_pass_manager = LLVMCreatePassManager();
	lb_populate_module_pass_manager(wd->target_machine, module_pass_manager, build_context.optimization_level);
	LLVMRunPassManager(module_pass_manager, wd->m->mod);
	return 0;
}



gb_internal WORKER_TASK_PROC(lb_generate_procedures_worker_proc) {
	lbModule *m = cast(lbModule *)data;
	for (isize i = 0; i < m->procedures_to_generate.count; i++) {
		lbProcedure *p = m->procedures_to_generate[i];
		lb_generate_procedure(p->module, p);
	}
	return 0;
}

gb_internal void lb_generate_procedures(lbGenerator *gen, bool do_threading) {
	for (auto const &entry : gen->modules) {
		lbModule *m = entry.value;
		if (do_threading) {
			thread_pool_add_task(lb_generate_procedures_worker_proc, m);
		} else {
			lb_generate_procedures_worker_proc(m);
		}
	}

	thread_pool_wait();
}

gb_internal WORKER_TASK_PROC(lb_generate_missing_procedures_to_check_worker_proc) {
	lbModule *m = cast(lbModule *)data;
	for (isize i = 0; i < m->missing_procedures_to_check.count; i++) {
		lbProcedure *p = m->missing_procedures_to_check[i];
		debugf("Generate missing procedure: %.*s\n", LIT(p->name));
		lb_generate_procedure(m, p);
	}
	return 0;
}

gb_internal void lb_generate_missing_procedures(lbGenerator *gen, bool do_threading) {
	for (auto const &entry : gen->modules) {
		lbModule *m = entry.value;
		// NOTE(bill): procedures may be added during generation
		if (do_threading) {
			thread_pool_add_task(lb_generate_missing_procedures_to_check_worker_proc, m);
		} else {
			lb_generate_missing_procedures_to_check_worker_proc(m);
		}
	}

	thread_pool_wait();
}

gb_internal void lb_debug_info_complete_types_and_finalize(lbGenerator *gen) {
	for (auto const &entry : gen->modules) {
		lbModule *m = entry.value;
		if (m->debug_builder != nullptr) {
			lb_debug_complete_types(m);
		}
	}
	for (auto const &entry : gen->modules) {
		lbModule *m = entry.value;
		if (m->debug_builder != nullptr) {
			LLVMDIBuilderFinalize(m->debug_builder);
		}
	}
}

gb_internal void lb_llvm_function_passes(lbGenerator *gen, bool do_threading) {
	for (auto const &entry : gen->modules) {
		lbModule *m = entry.value;
		if (do_threading) {
			thread_pool_add_task(lb_llvm_function_pass_per_module, m);
		} else {
			lb_llvm_function_pass_per_module(m);
		}
	}
	thread_pool_wait();
}


gb_internal void lb_llvm_module_passes(lbGenerator *gen, bool do_threading) {
	for (auto const &entry : gen->modules) {
		lbModule *m = entry.value;
		auto wd = gb_alloc_item(permanent_allocator(), lbLLVMModulePassWorkerData);
		wd->m = m;
		wd->target_machine = m->target_machine;

		if (do_threading) {
			thread_pool_add_task(lb_llvm_module_pass_worker_proc, wd);
		} else {
			lb_llvm_module_pass_worker_proc(wd);
		}
	}
	thread_pool_wait();
}


gb_internal String lb_filepath_ll_for_module(lbModule *m) {
	String path = concatenate3_strings(permanent_allocator(),
		build_context.build_paths[BuildPath_Output].basename,
		STR_LIT("/"),
		build_context.build_paths[BuildPath_Output].name
	);

	if (m->file) {
		char buf[32] = {};
		isize n = gb_snprintf(buf, gb_size_of(buf), "-%u", m->file->id);
		String suffix = make_string((u8 *)buf, n-1);
		path = concatenate_strings(permanent_allocator(), path, suffix);
	} else if (m->pkg) {
		path = concatenate3_strings(permanent_allocator(), path, STR_LIT("-"), m->pkg->name);
	} else if (USE_SEPARATE_MODULES) {
		path = concatenate_strings(permanent_allocator(), path, STR_LIT("-builtin"));
	}
	path = concatenate_strings(permanent_allocator(), path, STR_LIT(".ll"));

	return path;
}
gb_internal String lb_filepath_obj_for_module(lbModule *m) {
	String path = concatenate3_strings(permanent_allocator(),
		build_context.build_paths[BuildPath_Output].basename,
		STR_LIT("/"),
		build_context.build_paths[BuildPath_Output].name
	);

	if (m->file) {
		char buf[32] = {};
		isize n = gb_snprintf(buf, gb_size_of(buf), "-%u", m->file->id);
		String suffix = make_string((u8 *)buf, n-1);
		path = concatenate_strings(permanent_allocator(), path, suffix);
	} else if (m->pkg) {
		path = concatenate3_strings(permanent_allocator(), path, STR_LIT("-"), m->pkg->name);
	}

	String ext = {};

	if (build_context.build_mode == BuildMode_Assembly) {
		ext = STR_LIT(".S");
	} else {
		if (is_arch_wasm()) {
			ext = STR_LIT(".wasm.o");
		} else {
			switch (build_context.metrics.os) {
			case TargetOs_windows:
				ext = STR_LIT(".obj");
				break;
			default:
			case TargetOs_darwin:
			case TargetOs_linux:
			case TargetOs_essence:
				ext = STR_LIT(".o");
				break;

			case TargetOs_freestanding:
				switch (build_context.metrics.abi) {
				default:
				case TargetABI_Default:
				case TargetABI_SysV:
					ext = STR_LIT(".o");
					break;
				case TargetABI_Win64:
					ext = STR_LIT(".obj");
					break;
				}
				break;
			}
		}
	}

	return concatenate_strings(permanent_allocator(), path, ext);
}

gb_internal WORKER_TASK_PROC(lb_llvm_module_verification_worker_proc) {
	char *llvm_error = nullptr;
	defer (LLVMDisposeMessage(llvm_error));
	lbModule *m = cast(lbModule *)data;
	if (LLVMVerifyModule(m->mod, LLVMReturnStatusAction, &llvm_error)) {
		gb_printf_err("LLVM Error:\n%s\n", llvm_error);
		if (build_context.keep_temp_files) {
			TIME_SECTION("LLVM Print Module to File");
			String filepath_ll = lb_filepath_ll_for_module(m);
			if (LLVMPrintModuleToFile(m->mod, cast(char const *)filepath_ll.text, &llvm_error)) {
				gb_printf_err("LLVM Error: %s\n", llvm_error);
				gb_exit(1);
				return false;
			}
		}
		gb_exit(1);
		return 1;
	}
	return 0;
}


gb_internal bool lb_llvm_module_verification(lbGenerator *gen, bool do_threading) {
	for (auto const &entry : gen->modules) {
		lbModule *m = entry.value;
		if (do_threading) {
			thread_pool_add_task(lb_llvm_module_verification_worker_proc, m);
		} else {
			if (lb_llvm_module_verification_worker_proc(m)) {
				return false;
			}
		}
	}
	thread_pool_wait();

	return true;
}

gb_internal void lb_add_foreign_library_paths(lbGenerator *gen) {
	for (auto const &entry : gen->modules) {
		lbModule *m = entry.value;
		for (Entity *e : m->info->required_foreign_imports_through_force) {
			lb_add_foreign_library_path(m, e);
		}

		if (lb_is_module_empty(m)) {
			continue;
		}
	}
}

gb_internal bool lb_llvm_object_generation(lbGenerator *gen, bool do_threading) {
	LLVMCodeGenFileType code_gen_file_type = LLVMObjectFile;
	if (build_context.build_mode == BuildMode_Assembly) {
		code_gen_file_type = LLVMAssemblyFile;
	}

	char *llvm_error = nullptr;
	defer (LLVMDisposeMessage(llvm_error));

	if (do_threading) {
		for (auto const &entry : gen->modules) {
			lbModule *m = entry.value;
			if (lb_is_module_empty(m)) {
				continue;
			}

			String filepath_ll = lb_filepath_ll_for_module(m);
			String filepath_obj = lb_filepath_obj_for_module(m);
			// gb_printf_err("%.*s\n", LIT(filepath_obj));
			array_add(&gen->output_object_paths, filepath_obj);
			array_add(&gen->output_temp_paths, filepath_ll);

			auto *wd = gb_alloc_item(permanent_allocator(), lbLLVMEmitWorker);
			wd->target_machine = m->target_machine;
			wd->code_gen_file_type = code_gen_file_type;
			wd->filepath_obj = filepath_obj;
			wd->m = m;
			thread_pool_add_task(lb_llvm_emit_worker_proc, wd);
		}

		thread_pool_wait(&global_thread_pool);
	} else {
		for (auto const &entry : gen->modules) {
			lbModule *m = entry.value;
			if (lb_is_module_empty(m)) {
				continue;
			}

			String filepath_obj = lb_filepath_obj_for_module(m);
			array_add(&gen->output_object_paths, filepath_obj);

			String short_name = remove_directory_from_path(filepath_obj);
			gbString section_name = gb_string_make(permanent_allocator(), "LLVM Generate Object: ");
			section_name = gb_string_append_length(section_name, short_name.text, short_name.len);

			TIME_SECTION_WITH_LEN(section_name, gb_string_length(section_name));

			if (LLVMTargetMachineEmitToFile(m->target_machine, m->mod, cast(char *)filepath_obj.text, code_gen_file_type, &llvm_error)) {
				gb_printf_err("LLVM Error: %s\n", llvm_error);
				gb_exit(1);
				return false;
			}
			debugf("Generated File: %.*s\n", LIT(filepath_obj));
		}
	}
	return true;
}



gb_internal lbProcedure *lb_create_main_procedure(lbModule *m, lbProcedure *startup_runtime, lbProcedure *cleanup_runtime) {
	LLVMPassManagerRef default_function_pass_manager = LLVMCreateFunctionPassManagerForModule(m->mod);
	lb_populate_function_pass_manager(m, default_function_pass_manager, false, build_context.optimization_level);
	LLVMFinalizeFunctionPassManager(default_function_pass_manager);

	Type *params  = alloc_type_tuple();
	Type *results = alloc_type_tuple();

	Type *t_ptr_cstring = alloc_type_pointer(t_cstring);

	bool call_cleanup = true;

	bool has_args = false;
	bool is_dll_main = false;
	String name = str_lit("main");
	if (build_context.metrics.os == TargetOs_windows && build_context.build_mode == BuildMode_DynamicLibrary) {
		is_dll_main = true;
		name = str_lit("DllMain");
		slice_init(&params->Tuple.variables, permanent_allocator(), 3);
		params->Tuple.variables[0] = alloc_entity_param(nullptr, make_token_ident("hinstDLL"),   t_rawptr, false, true);
		params->Tuple.variables[1] = alloc_entity_param(nullptr, make_token_ident("fdwReason"),  t_u32,    false, true);
		params->Tuple.variables[2] = alloc_entity_param(nullptr, make_token_ident("lpReserved"), t_rawptr, false, true);
		call_cleanup = false;
	} else if (build_context.metrics.os == TargetOs_windows && (build_context.metrics.arch == TargetArch_i386 || build_context.no_crt)) {
		name = str_lit("mainCRTStartup");
	} else if (is_arch_wasm()) {
		name = str_lit("_start");
		call_cleanup = false;
	} else {
		has_args = true;
		slice_init(&params->Tuple.variables, permanent_allocator(), 2);
		params->Tuple.variables[0] = alloc_entity_param(nullptr, make_token_ident("argc"), t_i32, false, true);
		params->Tuple.variables[1] = alloc_entity_param(nullptr, make_token_ident("argv"), t_ptr_cstring, false, true);
	}

	slice_init(&results->Tuple.variables, permanent_allocator(), 1);
	results->Tuple.variables[0] = alloc_entity_param(nullptr, blank_token, t_i32, false, true);

	Type *proc_type = alloc_type_proc(nullptr,
		params, params->Tuple.variables.count,
		results, results->Tuple.variables.count, false, ProcCC_CDecl);


	lbProcedure *p = lb_create_dummy_procedure(m, name, proc_type);
	p->is_startup = true;

	lb_begin_procedure_body(p);

	if (has_args) { // initialize `runtime.args__`
		lbValue argc = {LLVMGetParam(p->value, 0), t_i32};
		lbValue argv = {LLVMGetParam(p->value, 1), t_ptr_cstring};
		LLVMSetValueName2(argc.value, "argc", 4);
		LLVMSetValueName2(argv.value, "argv", 4);
		argc = lb_emit_conv(p, argc, t_int);
		lbAddr args = lb_addr(lb_find_runtime_value(p->module, str_lit("args__")));
		lb_fill_slice(p, args, argv, argc);
	}

	lbValue startup_runtime_value = {startup_runtime->value, startup_runtime->type};
	lb_emit_call(p, startup_runtime_value, {}, ProcInlining_none);

	if (build_context.command_kind == Command_test) {
		Type *t_Internal_Test = find_type_in_pkg(m->info, str_lit("testing"), str_lit("Internal_Test"));
		Type *array_type = alloc_type_array(t_Internal_Test, m->info->testing_procedures.count);
		Type *slice_type = alloc_type_slice(t_Internal_Test);
		lbAddr all_tests_array_addr = lb_add_global_generated(p->module, array_type, {});
		lbValue all_tests_array = lb_addr_get_ptr(p, all_tests_array_addr);

		LLVMValueRef indices[2] = {};
		indices[0] = LLVMConstInt(lb_type(m, t_i32), 0, false);

		isize testing_proc_index = 0;
		for (Entity *testing_proc : m->info->testing_procedures) {
			String name = testing_proc->token.string;

			String pkg_name = {};
			if (testing_proc->pkg != nullptr) {
				pkg_name = testing_proc->pkg->name;
			}
			lbValue v_pkg  = lb_find_or_add_entity_string(m, pkg_name);
			lbValue v_name = lb_find_or_add_entity_string(m, name);
			lbValue v_proc = lb_find_procedure_value_from_entity(m, testing_proc);

			indices[1] = LLVMConstInt(lb_type(m, t_int), testing_proc_index++, false);

			LLVMValueRef vals[3] = {};
			vals[0] = v_pkg.value;
			vals[1] = v_name.value;
			vals[2] = v_proc.value;
			GB_ASSERT(LLVMIsConstant(vals[0]));
			GB_ASSERT(LLVMIsConstant(vals[1]));
			GB_ASSERT(LLVMIsConstant(vals[2]));

			LLVMValueRef dst = LLVMConstInBoundsGEP2(llvm_addr_type(m, all_tests_array), all_tests_array.value, indices, gb_count_of(indices));
			LLVMValueRef src = llvm_const_named_struct(m, t_Internal_Test, vals, gb_count_of(vals));

			LLVMBuildStore(p->builder, src, dst);
		}

		lbAddr all_tests_slice = lb_add_local_generated(p, slice_type, true);
		lb_fill_slice(p, all_tests_slice,
		              lb_array_elem(p, all_tests_array),
		              lb_const_int(m, t_int, m->info->testing_procedures.count));


		lbValue runner = lb_find_package_value(m, str_lit("testing"), str_lit("runner"));

		auto args = array_make<lbValue>(permanent_allocator(), 1);
		args[0] = lb_addr_load(p, all_tests_slice);
		lb_emit_call(p, runner, args);
	} else {
		if (m->info->entry_point != nullptr) {
			lbValue entry_point = lb_find_procedure_value_from_entity(m, m->info->entry_point);
			lb_emit_call(p, entry_point, {}, ProcInlining_no_inline);
		}
	}


	if (call_cleanup) {
		lbValue cleanup_runtime_value = {cleanup_runtime->value, cleanup_runtime->type};
		lb_emit_call(p, cleanup_runtime_value, {}, ProcInlining_none);
	}


	if (is_dll_main) {
		LLVMBuildRet(p->builder, LLVMConstInt(lb_type(m, t_i32), 1, false));
	} else {
		LLVMBuildRet(p->builder, LLVMConstInt(lb_type(m, t_i32), 0, false));
	}

	lb_end_procedure_body(p);


	LLVMSetLinkage(p->value, LLVMExternalLinkage);
	if (is_arch_wasm()) {
		lb_set_wasm_export_attributes(p->value, p->name);
	}


	if (!m->debug_builder && LLVMVerifyFunction(p->value, LLVMReturnStatusAction)) {
		gb_printf_err("LLVM CODE GEN FAILED FOR PROCEDURE: %s\n", "main");
		LLVMDumpValue(p->value);
		gb_printf_err("\n\n\n\n");
		LLVMVerifyFunction(p->value, LLVMAbortProcessAction);
	}

	lb_run_function_pass_manager(default_function_pass_manager, p);
	return p;
}

gb_internal void lb_generate_procedure(lbModule *m, lbProcedure *p) {
	if (p->is_done) {
		return;
	}
	if (p->body != nullptr) { // Build Procedure
		m->curr_procedure = p;
		lb_begin_procedure_body(p);
		lb_build_stmt(p, p->body);
		lb_end_procedure_body(p);
		p->is_done = true;
		m->curr_procedure = nullptr;
	}
	lb_end_procedure(p);

	// Add Flags
	if (p->body != nullptr) {
		if (p->name == "memcpy" || p->name == "memmove" ||
		    p->name == "runtime.mem_copy" || p->name == "mem_copy_non_overlapping" ||
		    string_starts_with(p->name, str_lit("llvm.memcpy")) ||
		    string_starts_with(p->name, str_lit("llvm.memmove"))) {
			p->flags |= lbProcedureFlag_WithoutMemcpyPass;
		}
	}

	if (!m->debug_builder && LLVMVerifyFunction(p->value, LLVMReturnStatusAction)) {
		char *llvm_error = nullptr;

		gb_printf_err("LLVM CODE GEN FAILED FOR PROCEDURE: %.*s\n", LIT(p->name));
		LLVMDumpValue(p->value);
		gb_printf_err("\n\n\n\n");
		String filepath_ll = lb_filepath_ll_for_module(m);
		if (LLVMPrintModuleToFile(m->mod, cast(char const *)filepath_ll.text, &llvm_error)) {
			gb_printf_err("LLVM Error: %s\n", llvm_error);
		}
		LLVMVerifyFunction(p->value, LLVMPrintMessageAction);
		gb_exit(1);
	}
}


gb_internal bool lb_generate_code(lbGenerator *gen) {
	TIME_SECTION("LLVM Initializtion");

	isize thread_count = gb_max(build_context.thread_count, 1);
	isize worker_count = thread_count-1;

	bool do_threading = !!(LLVMIsMultithreaded() && USE_SEPARATE_MODULES && MULTITHREAD_OBJECT_GENERATION && worker_count > 0);

	lbModule *default_module = &gen->default_module;
	CheckerInfo *info = gen->info;

	auto *min_dep_set = &info->minimum_dependency_set;

	switch (build_context.metrics.arch) {
	case TargetArch_amd64: 
	case TargetArch_i386:
		LLVMInitializeX86TargetInfo();
		LLVMInitializeX86Target();
		LLVMInitializeX86TargetMC();
		LLVMInitializeX86AsmPrinter();
		LLVMInitializeX86AsmParser();
		LLVMInitializeX86Disassembler();
		break;
	case TargetArch_arm64:
		LLVMInitializeAArch64TargetInfo();
		LLVMInitializeAArch64Target();
		LLVMInitializeAArch64TargetMC();
		LLVMInitializeAArch64AsmPrinter();
		LLVMInitializeAArch64AsmParser();
		LLVMInitializeAArch64Disassembler();
		break;
	case TargetArch_wasm32:
	case TargetArch_wasm64:
		LLVMInitializeWebAssemblyTargetInfo();
		LLVMInitializeWebAssemblyTarget();
		LLVMInitializeWebAssemblyTargetMC();
		LLVMInitializeWebAssemblyAsmPrinter();
		LLVMInitializeWebAssemblyAsmParser();
		LLVMInitializeWebAssemblyDisassembler();
		break;
	default:
		LLVMInitializeAllTargetInfos();
		LLVMInitializeAllTargets();
		LLVMInitializeAllTargetMCs();
		LLVMInitializeAllAsmPrinters();
		LLVMInitializeAllAsmParsers();
		LLVMInitializeAllDisassemblers();
		break;
	}

	
	if (build_context.microarch == "native") {
		LLVMInitializeNativeTarget();
	}

	char const *target_triple = alloc_cstring(permanent_allocator(), build_context.metrics.target_triplet);
	for (auto const &entry : gen->modules) {
		LLVMSetTarget(entry.value->mod, target_triple);
	}

	LLVMTargetRef target = {};
	char *llvm_error = nullptr;
	LLVMGetTargetFromTriple(target_triple, &target, &llvm_error);
	GB_ASSERT(target != nullptr);



	TIME_SECTION("LLVM Create Target Machine");

	LLVMCodeModel code_mode = LLVMCodeModelDefault;
	if (is_arch_wasm()) {
		code_mode = LLVMCodeModelJITDefault;
	} else if (build_context.metrics.os == TargetOs_freestanding) {
		code_mode = LLVMCodeModelKernel;
	}

	char const *host_cpu_name = LLVMGetHostCPUName();
	char const *llvm_cpu = "generic";
	char const *llvm_features = "";
	if (build_context.microarch.len != 0) {
		if (build_context.microarch == "native") {
			llvm_cpu = host_cpu_name;
		} else {
			llvm_cpu = alloc_cstring(permanent_allocator(), build_context.microarch);
		}
		if (gb_strcmp(llvm_cpu, host_cpu_name) == 0) {
			llvm_features = LLVMGetHostCPUFeatures();
		}
	} else if (build_context.metrics.arch == TargetArch_amd64) {
		// NOTE(bill): x86-64-v2 is more than enough for everyone
		//
		// x86-64: CMOV, CMPXCHG8B, FPU, FXSR, MMX, FXSR, SCE, SSE, SSE2
		// x86-64-v2: (close to Nehalem) CMPXCHG16B, LAHF-SAHF, POPCNT, SSE3, SSE4.1, SSE4.2, SSSE3
		// x86-64-v3: (close to Haswell) AVX, AVX2, BMI1, BMI2, F16C, FMA, LZCNT, MOVBE, XSAVE
		// x86-64-v4: AVX512F, AVX512BW, AVX512CD, AVX512DQ, AVX512VL
		if (ODIN_LLVM_MINIMUM_VERSION_12) {
			if (build_context.metrics.os == TargetOs_freestanding) {
				llvm_cpu = "x86-64";
			} else {
				llvm_cpu = "x86-64-v2";
			}
		}
	}

	if (build_context.target_features_set.entries.count != 0) {
		llvm_features = target_features_set_to_cstring(permanent_allocator(), false);
	}

	// GB_ASSERT_MSG(LLVMTargetHasAsmBackend(target));

	LLVMCodeGenOptLevel code_gen_level = LLVMCodeGenLevelNone;
	switch (build_context.optimization_level) {
	case 0: code_gen_level = LLVMCodeGenLevelNone;    break;
	case 1: code_gen_level = LLVMCodeGenLevelLess;    break;
	case 2: code_gen_level = LLVMCodeGenLevelDefault; break;
	case 3: code_gen_level = LLVMCodeGenLevelDefault; break; // NOTE(bill): force -opt:3 to be the same as -opt:2
	// case 3: code_gen_level = LLVMCodeGenLevelAggressive; break;
	}

	// NOTE(bill): Target Machine Creation
	// NOTE(bill, 2021-05-04): Target machines must be unique to each module because they are not thread safe
	auto target_machines = array_make<LLVMTargetMachineRef>(permanent_allocator(), 0, gen->modules.count);

	// NOTE(dweiler): Dynamic libraries require position-independent code.
	LLVMRelocMode reloc_mode = LLVMRelocDefault;
	if (build_context.build_mode == BuildMode_DynamicLibrary) {
		reloc_mode = LLVMRelocPIC;
	}

	switch (build_context.reloc_mode) {
	case RelocMode_Default:
		if (build_context.metrics.os == TargetOs_openbsd) {
			// Always use PIC for OpenBSD: it defaults to PIE
			reloc_mode = LLVMRelocPIC;
		}
		break;
	case RelocMode_Static:
		reloc_mode = LLVMRelocStatic;
		break;
	case RelocMode_PIC:
		reloc_mode = LLVMRelocPIC;
		break;
	case RelocMode_DynamicNoPIC:
		reloc_mode = LLVMRelocDynamicNoPic;
		break;
	}

	for (auto const &entry : gen->modules) {
		LLVMTargetMachineRef target_machine = LLVMCreateTargetMachine(
			target, target_triple, llvm_cpu,
			llvm_features,
			code_gen_level,
			reloc_mode,
			code_mode);
		lbModule *m = entry.value;
		m->target_machine = target_machine;
		LLVMSetModuleDataLayout(m->mod, LLVMCreateTargetDataLayout(target_machine));
		array_add(&target_machines, target_machine);
	}

	for (auto const &entry : gen->modules) {
		lbModule *m = entry.value;
		if (m->debug_builder) { // Debug Info
			for (auto const &file_entry : info->files) {
				AstFile *f = file_entry.value;
				LLVMMetadataRef res = LLVMDIBuilderCreateFile(m->debug_builder,
					cast(char const *)f->filename.text, f->filename.len,
					cast(char const *)f->directory.text, f->directory.len);
				lb_set_llvm_metadata(m, f, res);
			}

			TEMPORARY_ALLOCATOR_GUARD();

			gbString producer = gb_string_make(temporary_allocator(), "odin");
			// producer = gb_string_append_fmt(producer, " version %.*s", LIT(ODIN_VERSION));
			// #ifdef NIGHTLY
			// producer = gb_string_appendc(producer, "-nightly");
			// #endif
			// #ifdef GIT_SHA
			// producer = gb_string_append_fmt(producer, "-%s", GIT_SHA);
			// #endif

			gbString split_name = gb_string_make(temporary_allocator(), "");

			LLVMBool is_optimized = build_context.optimization_level > 0;
			AstFile *init_file = m->info->init_package->files[0];

			if (Entity *entry_point = m->info->entry_point) {
				if (Ast *ident = entry_point->identifier.load()) {
					if (ident->file_id) {
						init_file = ident->file();
					}
				}
			}

			LLVMBool split_debug_inlining = build_context.build_mode == BuildMode_Assembly;
			LLVMBool debug_info_for_profiling = false;

			m->debug_compile_unit = LLVMDIBuilderCreateCompileUnit(m->debug_builder, LLVMDWARFSourceLanguageC99,
				lb_get_llvm_metadata(m, init_file),
				producer, gb_string_length(producer),
				is_optimized, "", 0,
				1, split_name, gb_string_length(split_name),
				LLVMDWARFEmissionFull,
				0, split_debug_inlining,
				debug_info_for_profiling,
				"", 0, // sys_root
				"", 0  // SDK
			);
			GB_ASSERT(m->debug_compile_unit != nullptr);
		}
	}

	TIME_SECTION("LLVM Global Variables");

	if (!build_context.disallow_rtti) {
		lbModule *m = default_module;

		{ // Add type info data
			isize max_type_info_count = info->minimum_dependency_type_info_set.count+1;
			// gb_printf_err("max_type_info_count: %td\n", max_type_info_count);
			Type *t = alloc_type_array(t_type_info, max_type_info_count);
			LLVMValueRef g = LLVMAddGlobal(m->mod, lb_type(m, t), LB_TYPE_INFO_DATA_NAME);
			LLVMSetInitializer(g, LLVMConstNull(lb_type(m, t)));
			LLVMSetLinkage(g, USE_SEPARATE_MODULES ? LLVMExternalLinkage : LLVMInternalLinkage);

			lbValue value = {};
			value.value = g;
			value.type = alloc_type_pointer(t);

			lb_global_type_info_data_entity = alloc_entity_variable(nullptr, make_token_ident(LB_TYPE_INFO_DATA_NAME), t, EntityState_Resolved);
			lb_add_entity(m, lb_global_type_info_data_entity, value);
		}
		{ // Type info member buffer
			// NOTE(bill): Removes need for heap allocation by making it global memory
			isize count = 0;

			for (Type *t : m->info->type_info_types) {
				isize index = lb_type_info_index(m->info, t, false);
				if (index < 0) {
					continue;
				}

				switch (t->kind) {
				case Type_Union:
					count += t->Union.variants.count;
					break;
				case Type_Struct:
					count += t->Struct.fields.count;
					break;
				case Type_Tuple:
					count += t->Tuple.variables.count;
					break;
				}
			}

			if (count > 0) {
				{
					char const *name = LB_TYPE_INFO_TYPES_NAME;
					Type *t = alloc_type_array(t_type_info_ptr, count);
					LLVMValueRef g = LLVMAddGlobal(m->mod, lb_type(m, t), name);
					LLVMSetInitializer(g, LLVMConstNull(lb_type(m, t)));
					LLVMSetLinkage(g, LLVMInternalLinkage);
					lb_global_type_info_member_types = lb_addr({g, alloc_type_pointer(t)});

				}
				{
					char const *name = LB_TYPE_INFO_NAMES_NAME;
					Type *t = alloc_type_array(t_string, count);
					LLVMValueRef g = LLVMAddGlobal(m->mod, lb_type(m, t), name);
					LLVMSetInitializer(g, LLVMConstNull(lb_type(m, t)));
					LLVMSetLinkage(g, LLVMInternalLinkage);
					lb_global_type_info_member_names = lb_addr({g, alloc_type_pointer(t)});
				}
				{
					char const *name = LB_TYPE_INFO_OFFSETS_NAME;
					Type *t = alloc_type_array(t_uintptr, count);
					LLVMValueRef g = LLVMAddGlobal(m->mod, lb_type(m, t), name);
					LLVMSetInitializer(g, LLVMConstNull(lb_type(m, t)));
					LLVMSetLinkage(g, LLVMInternalLinkage);
					lb_global_type_info_member_offsets = lb_addr({g, alloc_type_pointer(t)});
				}

				{
					char const *name = LB_TYPE_INFO_USINGS_NAME;
					Type *t = alloc_type_array(t_bool, count);
					LLVMValueRef g = LLVMAddGlobal(m->mod, lb_type(m, t), name);
					LLVMSetInitializer(g, LLVMConstNull(lb_type(m, t)));
					LLVMSetLinkage(g, LLVMInternalLinkage);
					lb_global_type_info_member_usings = lb_addr({g, alloc_type_pointer(t)});
				}

				{
					char const *name = LB_TYPE_INFO_TAGS_NAME;
					Type *t = alloc_type_array(t_string, count);
					LLVMValueRef g = LLVMAddGlobal(m->mod, lb_type(m, t), name);
					LLVMSetInitializer(g, LLVMConstNull(lb_type(m, t)));
					LLVMSetLinkage(g, LLVMInternalLinkage);
					lb_global_type_info_member_tags = lb_addr({g, alloc_type_pointer(t)});
				}
			}
		}
	}


	isize global_variable_max_count = 0;
	bool already_has_entry_point = false;

	for (Entity *e : info->entities) {
		String name = e->token.string;

		if (e->kind == Entity_Variable) {
			global_variable_max_count++;
		} else if (e->kind == Entity_Procedure) {
			if ((e->scope->flags&ScopeFlag_Init) && name == "main") {
				GB_ASSERT(e == info->entry_point);
			}
			if (build_context.command_kind == Command_test &&
			    (e->Procedure.is_export || e->Procedure.link_name.len > 0)) {
				String link_name = e->Procedure.link_name;
				if (e->pkg->kind == Package_Runtime) {
					if (link_name == "main"           ||
					    link_name == "DllMain"        ||
					    link_name == "WinMain"        ||
					    link_name == "wWinMain"       ||
					    link_name == "mainCRTStartup" ||
					    link_name == "_start") {
						already_has_entry_point = true;
					}
				}
			}
		}
	}


	auto global_variables = array_make<lbGlobalVariable>(permanent_allocator(), 0, global_variable_max_count);

	for (DeclInfo *d : info->variable_init_order) {
		Entity *e = d->entity;

		if ((e->scope->flags & ScopeFlag_File) == 0) {
			continue;
		}

		if (!ptr_set_exists(min_dep_set, e)) {
			continue;
		}

		DeclInfo *decl = decl_info_of_entity(e);
		if (decl == nullptr) {
			continue;
		}
		GB_ASSERT(e->kind == Entity_Variable);

		bool is_foreign = e->Variable.is_foreign;
		bool is_export  = e->Variable.is_export;


		lbModule *m = &gen->default_module;
		String name = lb_get_entity_name(m, e);

		lbValue g = {};
		g.value = LLVMAddGlobal(m->mod, lb_type(m, e->type), alloc_cstring(permanent_allocator(), name));
		g.type = alloc_type_pointer(e->type);
		if (e->Variable.thread_local_model != "") {
			LLVMSetThreadLocal(g.value, true);

			String m = e->Variable.thread_local_model;
			LLVMThreadLocalMode mode = LLVMGeneralDynamicTLSModel;
			if (m == "default") {
				mode = LLVMGeneralDynamicTLSModel;
			} else if (m == "localdynamic") {
				mode = LLVMLocalDynamicTLSModel;
			} else if (m == "initialexec") {
				mode = LLVMInitialExecTLSModel;
			} else if (m == "localexec") {
				mode = LLVMLocalExecTLSModel;
			} else {
				GB_PANIC("Unhandled thread local mode %.*s", LIT(m));
			}
			LLVMSetThreadLocalMode(g.value, mode);
		}
		if (is_foreign) {
			LLVMSetLinkage(g.value, LLVMExternalLinkage);
			LLVMSetDLLStorageClass(g.value, LLVMDLLImportStorageClass);
			LLVMSetExternallyInitialized(g.value, true);
			lb_add_foreign_library_path(m, e->Variable.foreign_library);
			
			lb_set_wasm_import_attributes(g.value, e, name);
		} else {
			LLVMSetInitializer(g.value, LLVMConstNull(lb_type(m, e->type)));
		}
		if (is_export) {
			LLVMSetLinkage(g.value, LLVMDLLExportLinkage);
			LLVMSetDLLStorageClass(g.value, LLVMDLLExportStorageClass);
		} else if (!is_foreign) {
			LLVMSetLinkage(g.value, USE_SEPARATE_MODULES ? LLVMExternalLinkage : LLVMInternalLinkage);
		}
		lb_set_linkage_from_entity_flags(m, g.value, e->flags);
		
		if (e->Variable.link_section.len > 0) {
			LLVMSetSection(g.value, alloc_cstring(permanent_allocator(), e->Variable.link_section));
		}

		lbGlobalVariable var = {};
		var.var = g;
		var.decl = decl;

		if (decl->init_expr != nullptr) {
			TypeAndValue tav = type_and_value_of_expr(decl->init_expr);
			if (!is_type_any(e->type) && !is_type_union(e->type)) {
				if (tav.mode != Addressing_Invalid) {
					if (tav.value.kind != ExactValue_Invalid) {
						ExactValue v = tav.value;
						lbValue init = lb_const_value(m, tav.type, v);
						LLVMSetInitializer(g.value, init.value);
						var.is_initialized = true;
					}
				}
			}
			if (!var.is_initialized &&
			    (is_type_untyped_nil(tav.type) || is_type_untyped_undef(tav.type))) {
				var.is_initialized = true;
			}
		}

		array_add(&global_variables, var);

		lb_add_entity(m, e, g);
		lb_add_member(m, name, g);


		if (m->debug_builder) {
			String global_name = e->token.string;
			if (global_name.len != 0 && global_name != "_") {
				LLVMMetadataRef llvm_file = lb_get_llvm_metadata(m, e->file);
				LLVMMetadataRef llvm_scope = llvm_file;

				LLVMBool local_to_unit = LLVMGetLinkage(g.value) == LLVMInternalLinkage;

				LLVMMetadataRef llvm_expr = LLVMDIBuilderCreateExpression(m->debug_builder, nullptr, 0);
				LLVMMetadataRef llvm_decl = nullptr;

				u32 align_in_bits = cast(u32)(8*type_align_of(e->type));

				LLVMMetadataRef global_variable_metadata = LLVMDIBuilderCreateGlobalVariableExpression(
					m->debug_builder, llvm_scope,
					cast(char const *)global_name.text, global_name.len,
					"", 0, // linkage
					llvm_file, e->token.pos.line,
					lb_debug_type(m, e->type),
					local_to_unit,
					llvm_expr,
					llvm_decl,
					align_in_bits
				);
				lb_set_llvm_metadata(m, g.value, global_variable_metadata);
				LLVMGlobalSetMetadata(g.value, 0, global_variable_metadata);
			}
		}
	}

	TIME_SECTION("LLVM Runtime Type Information Creation");
	gen->startup_type_info = lb_create_startup_type_info(default_module);
	gen->objc_names = lb_create_objc_names(default_module);

	TIME_SECTION("LLVM Runtime Startup Creation (Global Variables & @(init))");
	gen->startup_runtime = lb_create_startup_runtime(default_module, gen->startup_type_info, gen->objc_names, global_variables);

	TIME_SECTION("LLVM Runtime Cleanup Creation & @(fini)");
	gen->cleanup_runtime = lb_create_cleanup_runtime(default_module);


	if (build_context.ODIN_DEBUG) {
		for (auto const &entry : builtin_pkg->scope->elements) {
			Entity *e = entry.value;
			add_debug_info_for_global_constant_from_entity(gen, e);
		}
	}

	if (gen->modules.count <= 1) {
		do_threading = false;
	}

	TIME_SECTION("LLVM Global Procedures and Types");
	lb_create_global_procedures_and_types(gen, info, do_threading);

	TIME_SECTION("LLVM Procedure Generation");
	lb_generate_procedures(gen, do_threading);

	if (build_context.command_kind == Command_test && !already_has_entry_point) {
		TIME_SECTION("LLVM main");
		lb_create_main_procedure(default_module, gen->startup_runtime, gen->cleanup_runtime);
	}

	TIME_SECTION("LLVM Procedure Generation (missing)");
	lb_generate_missing_procedures(gen, do_threading);

	if (gen->objc_names) {
		TIME_SECTION("Finalize objc names");
		lb_finalize_objc_names(gen->objc_names);
	}

	if (build_context.ODIN_DEBUG) {
		TIME_SECTION("LLVM Debug Info Complete Types and Finalize");
		lb_debug_info_complete_types_and_finalize(gen);
	}

	if (do_threading) {
		isize non_empty_module_count = 0;
		for (auto const &entry : gen->modules) {
			lbModule *m = entry.value;
			if (!lb_is_module_empty(m)) {
				non_empty_module_count += 1;
			}
		}
		if (non_empty_module_count <= 1) {
			do_threading = false;
		}
	}


	TIME_SECTION("LLVM Function Pass");
	lb_llvm_function_passes(gen, do_threading && !build_context.ODIN_DEBUG);

	TIME_SECTION("LLVM Module Pass");
	lb_llvm_module_passes(gen, do_threading);


	TIME_SECTION("LLVM Module Verification");


	if (!lb_llvm_module_verification(gen, do_threading)) {
		return false;
	}

	llvm_error = nullptr;
	defer (LLVMDisposeMessage(llvm_error));

	if (build_context.keep_temp_files ||
	    build_context.build_mode == BuildMode_LLVM_IR) {
		TIME_SECTION("LLVM Print Module to File");

		for (auto const &entry : gen->modules) {
			lbModule *m = entry.value;
			if (lb_is_module_empty(m)) {
				continue;
			}
			String filepath_ll = lb_filepath_ll_for_module(m);
			if (LLVMPrintModuleToFile(m->mod, cast(char const *)filepath_ll.text, &llvm_error)) {
				gb_printf_err("LLVM Error: %s\n", llvm_error);
				gb_exit(1);
				return false;
			}
			array_add(&gen->output_temp_paths, filepath_ll);

		}
		if (build_context.build_mode == BuildMode_LLVM_IR) {
			return true;
		}
	}

	TIME_SECTION("LLVM Add Foreign Library Paths");
	lb_add_foreign_library_paths(gen);

	TIME_SECTION("LLVM Object Generation");
	
	if (build_context.ignore_llvm_build) {
		gb_printf_err("LLVM object generation has been ignored!\n");
		return false;
	}
	if (!lb_llvm_object_generation(gen, do_threading)) {
		return false;
	}

	gb_sort_array(gen->foreign_libraries.data, gen->foreign_libraries.count, foreign_library_cmp);

	return true;
}
