// TODO(bill): COMPLETELY REWORK THIS ENTIRE INTERPRETER
#include "dyncall/include/dyncall.h"

struct VirtualMachine;

struct vmValueProc {
	ssaProcedure *proc; // If `NULL`, use `ptr` instead and call external procedure
	void *        ptr;
};


struct vmValue {
	// NOTE(bill): Shouldn't need to store type here as the type checking
	// has already been handled in the SSA
	union {
		f32            val_f32;
		f64            val_f64;
		void *         val_ptr;
		i64            val_int;
		vmValueProc    val_proc;
	};
	Array<vmValue> val_comp; // NOTE(bill): Will be freed through "stack"
	Type *type;
};

vmValue vm_make_value_ptr(Type *type, void *ptr) {
	GB_ASSERT(is_type_pointer(type));
	vmValue v = {};
	v.type = default_type(type);
	v.val_ptr = ptr;
	return v;
}
vmValue vm_make_value_int(Type *type, i64 i) {
	GB_ASSERT(is_type_integer(type) ||
	          is_type_boolean(type) ||
	          is_type_enum(type));
	vmValue v = {};
	v.type = default_type(type);
	v.val_int = i;
	return v;
}
vmValue vm_make_value_f32(Type *type, f32 f) {
	GB_ASSERT(is_type_f32(type));
	vmValue v = {};
	v.type = default_type(type);
	v.val_f32 = f;
	return v;
}
vmValue vm_make_value_f64(Type *type, f64 f) {
	GB_ASSERT(is_type_f64(type));
	vmValue v = {};
	v.type = default_type(type);
	v.val_f64 = f;
	return v;
}
vmValue vm_make_value_comp(Type *type, gbAllocator allocator, isize count) {
	GB_ASSERT(is_type_string(type)    ||
	          is_type_any   (type)    ||
	          is_type_array (type)    ||
	          is_type_vector(type)    ||
	          is_type_slice (type)    ||
	          is_type_maybe (type)    ||
	          is_type_struct(type)    ||
	          is_type_union(type)     ||
	          is_type_raw_union(type) ||
	          is_type_tuple (type)    ||
	          is_type_proc  (type));
	vmValue v = {};
	v.type = default_type(type);
	array_init_count(&v.val_comp, allocator, count);
	return v;
}






struct vmFrame {
	VirtualMachine *  vm;
	vmFrame *         caller;
	ssaProcedure *    curr_proc;
	ssaBlock *        prev_block;
	ssaBlock *        curr_block;
	i32               instr_index; // For the current block

	Map<vmValue>      values; // Key: ssaValue *
	gbTempArenaMemory temp_arena_memory;
	gbAllocator       stack_allocator;
	Array<void *>     locals; // Memory to locals
	vmValue           result;
};

struct VirtualMachine {
	ssaModule *         module;
	gbArena             stack_arena;
	gbAllocator         stack_allocator;
	gbAllocator         heap_allocator;
	Array<vmFrame>      frame_stack;
	Map<vmValue>        globals;             // Key: ssaValue *
	Map<vmValue>        const_compound_lits; // Key: ssaValue *
	vmValue             exit_value;
};

void    vm_exec_instr   (VirtualMachine *vm, ssaValue *value);
vmValue vm_operand_value(VirtualMachine *vm, ssaValue *value);
void    vm_store        (VirtualMachine *vm, void *dst, vmValue val, Type *type);
vmValue vm_load         (VirtualMachine *vm, void *ptr, Type *type);
void    vm_print_value  (vmValue value, Type *type);

void vm_jump_block(vmFrame *f, ssaBlock *target) {
	f->prev_block = f->curr_block;
	f->curr_block = target;
	f->instr_index = 0;
}


vmFrame *vm_back_frame(VirtualMachine *vm) {
	if (vm->frame_stack.count > 0) {
		return &vm->frame_stack[vm->frame_stack.count-1];
	}
	return NULL;
}

i64 vm_type_size_of(VirtualMachine *vm, Type *type) {
	return type_size_of(vm->module->sizes, vm->heap_allocator, type);
}
i64 vm_type_align_of(VirtualMachine *vm, Type *type) {
	return type_align_of(vm->module->sizes, vm->heap_allocator, type);
}
i64 vm_type_offset_of(VirtualMachine *vm, Type *type, i64 index) {
	return type_offset_of(vm->module->sizes, vm->heap_allocator, type, index);
}


void vm_init(VirtualMachine *vm, ssaModule *module) {
	gb_arena_init_from_allocator(&vm->stack_arena, heap_allocator(), gb_megabytes(64));

	vm->module = module;
	vm->stack_allocator = gb_arena_allocator(&vm->stack_arena);
	vm->heap_allocator = heap_allocator();
	array_init(&vm->frame_stack, vm->heap_allocator);
	map_init(&vm->globals, vm->heap_allocator);
	map_init(&vm->const_compound_lits, vm->heap_allocator);

	for_array(i, vm->module->values.entries) {
		ssaValue *v = vm->module->values.entries[i].value;
		switch (v->kind) {
		case ssaValue_Global: {
			Type *t = ssa_type(v);
			GB_ASSERT(is_type_pointer(t));
			i64 size  = vm_type_size_of(vm, t);
			i64 align = vm_type_align_of(vm, t);
			void *mem = gb_alloc_align(vm->heap_allocator, size, align);
			if (v->Global.value != NULL && v->Global.value->kind == ssaValue_Constant) {
				vm_store(vm, mem, vm_operand_value(vm, v->Global.value), type_deref(t));
			}
			map_set(&vm->globals, hash_pointer(v), vm_make_value_ptr(t, mem));
		} break;
		}
	}

}
void vm_destroy(VirtualMachine *vm) {
	array_free(&vm->frame_stack);
	map_destroy(&vm->globals);
	map_destroy(&vm->const_compound_lits);
	gb_arena_free(&vm->stack_arena);
}






void vm_set_value(vmFrame *f, ssaValue *v, vmValue val) {
	if (v != NULL) {
		GB_ASSERT(ssa_type(v) != NULL);
		map_set(&f->values, hash_pointer(v), val);
	}
}



vmFrame *vm_push_frame(VirtualMachine *vm, ssaProcedure *proc) {
	vmFrame frame = {};

	frame.vm          = vm;
	frame.curr_proc   = proc;
	frame.prev_block  = proc->blocks[0];
	frame.curr_block  = proc->blocks[0];
	frame.instr_index = 0;
	frame.caller      = vm_back_frame(vm);
	frame.stack_allocator   = vm->stack_allocator;
	frame.temp_arena_memory = gb_temp_arena_memory_begin(&vm->stack_arena);

	map_init(&frame.values, vm->heap_allocator);
	array_init(&frame.locals, vm->heap_allocator, proc->local_count);
	array_add(&vm->frame_stack, frame);
	return vm_back_frame(vm);
}

void vm_pop_frame(VirtualMachine *vm) {
	vmFrame *f = vm_back_frame(vm);

	gb_temp_arena_memory_end(f->temp_arena_memory);
	array_free(&f->locals);
	map_destroy(&f->values);

	array_pop(&vm->frame_stack);
}


vmValue vm_call_proc(VirtualMachine *vm, ssaProcedure *proc, Array<vmValue> values) {
	Type *type = base_type(proc->type);
	GB_ASSERT_MSG(type->Proc.param_count == values.count,
	              "Incorrect number of arguments passed into procedure call!\n"
	              "%.*s -> %td vs %td",
	              LIT(proc->name),
	              type->Proc.param_count, values.count);
	Type *result_type = type->Proc.results;
	if (result_type != NULL &&
	    result_type->Tuple.variable_count == 1) {
		result_type = result_type->Tuple.variables[0]->type;
	}

	if (proc->body == NULL) {
		// GB_PANIC("TODO(bill): external procedure");
		gb_printf_err("TODO(bill): external procedure: %.*s\n", LIT(proc->name));
		vmValue result = {};
		result.type = result_type;
		return result;
	}

	void *result_mem = NULL;
	if (result_type != NULL) {
		result_mem = gb_alloc_align(vm->stack_allocator,
		                            vm_type_size_of(vm, result_type),
		                            vm_type_align_of(vm, result_type));
	}

	gb_printf("call: %.*s\n", LIT(proc->name));

	vmFrame *f = vm_push_frame(vm, proc);
	for_array(i, proc->params) {
		vm_set_value(f, proc->params[i], values[i]);
	}

	while (f->curr_block != NULL) {
		ssaValue *curr_instr = f->curr_block->instrs[f->instr_index++];
		vm_exec_instr(vm, curr_instr);
	}




	if (type->Proc.result_count > 0) {
		vmValue r = f->result;

		gb_printf("%.*s -> ", LIT(proc->name));
		vm_print_value(r, result_type);
		gb_printf("\n");

		vm_store(vm, result_mem, r, result_type);
	}

	vm_pop_frame(vm);
	if (result_mem != NULL) {
		return vm_load(vm, result_mem, result_type);
	}

	vmValue void_result = {};
	return void_result;
}


ssaProcedure *vm_lookup_procedure(VirtualMachine *vm, String name) {
	ssaValue *v = ssa_lookup_member(vm->module, name);
	GB_ASSERT(v->kind == ssaValue_Proc);
	return &v->Proc;
}

vmValue vm_call_proc_by_name(VirtualMachine *vm, String name, Array<vmValue> args) {
	return vm_call_proc(vm, vm_lookup_procedure(vm, name), args);
}

vmValue vm_exact_value(VirtualMachine *vm, ssaValue *ptr, ExactValue value, Type *t) {
	Type *original_type = t;
	t = base_type(get_enum_base_type(t));
	// i64 size = vm_type_size_of(vm, t);
	if (is_type_boolean(t)) {
		return vm_make_value_int(original_type, value.value_bool);
	} else if (is_type_integer(t)) {
		return vm_make_value_int(original_type, value.value_integer);
	} else if (is_type_float(t)) {
		if (t->Basic.kind == Basic_f32) {
			return vm_make_value_f32(original_type, cast(f32)value.value_float);
		} else if (t->Basic.kind == Basic_f64) {
			return vm_make_value_f64(original_type, cast(f64)value.value_float);
		}
	} else if (is_type_pointer(t)) {
		return vm_make_value_ptr(original_type, cast(void *)cast(intptr)value.value_pointer);
	} else if (is_type_string(t)) {
		vmValue result = vm_make_value_comp(original_type, vm->stack_allocator, 2);

		String str = value.value_string;
		i64 len = str.len;
		u8 *text = gb_alloc_array(vm->heap_allocator, u8, len);
		gb_memcopy(text, str.text, len);

		result.val_comp[0] = vm_make_value_ptr(t_u8_ptr, text);
		result.val_comp[1] = vm_make_value_int(t_int, len);

		return result;
	} else if (value.kind == ExactValue_Compound) {
		if (ptr != NULL) {
			vmValue *found = map_get(&vm->const_compound_lits, hash_pointer(ptr));
			if (found != NULL)  {
				return *found;
			}
		}

		ast_node(cl, CompoundLit, value.value_compound);

		if (is_type_array(t)) {
			vmValue result = {};

			isize elem_count = cl->elems.count;
			if (elem_count == 0) {
				if (ptr != NULL) {
					map_set(&vm->const_compound_lits, hash_pointer(ptr), result);
				}
				return result;
			}

			Type *type = base_type(t);
			result = vm_make_value_comp(t, vm->heap_allocator, type->Array.count);
			for (isize i = 0; i < elem_count; i++) {
				TypeAndValue *tav = type_and_value_of_expression(vm->module->info, cl->elems[i]);
				vmValue elem = vm_exact_value(vm, NULL, tav->value, tav->type);
				result.val_comp[i] = elem;
			}

			if (ptr != NULL) {
				map_set(&vm->const_compound_lits, hash_pointer(ptr), result);
			}

			return result;
		} else if (is_type_vector(t)) {
			vmValue result = {};

			isize elem_count = cl->elems.count;
			if (elem_count == 0) {
				if (ptr != NULL) {
					map_set(&vm->const_compound_lits, hash_pointer(ptr), result);
				}
				return result;
			}

			Type *type = base_type(t);
			result = vm_make_value_comp(t, vm->heap_allocator, type->Array.count);
			for (isize i = 0; i < elem_count; i++) {
				TypeAndValue *tav = type_and_value_of_expression(vm->module->info, cl->elems[i]);
				vmValue elem = vm_exact_value(vm, NULL, tav->value, tav->type);
				result.val_comp[i] = elem;
			}

			if (ptr != NULL) {
				map_set(&vm->const_compound_lits, hash_pointer(ptr), result);
			}

			return result;
		} else if (is_type_struct(t)) {
			ast_node(cl, CompoundLit, value.value_compound);

			isize value_count = t->Record.field_count;
			vmValue result = vm_make_value_comp(t, vm->heap_allocator, value_count);

			if (cl->elems.count == 0) {
				return result;
			}

			if (cl->elems[0]->kind == AstNode_FieldValue) {
				isize elem_count = cl->elems.count;
				for (isize i = 0; i < elem_count; i++) {
					ast_node(fv, FieldValue, cl->elems[i]);
					String name = fv->field->Ident.string;

					TypeAndValue *tav = type_and_value_of_expression(vm->module->info, fv->value);
					GB_ASSERT(tav != NULL);

					Selection sel = lookup_field(vm->heap_allocator, t, name, false);
					Entity *f = t->Record.fields[sel.index[0]];

					result.val_comp[f->Variable.field_index] = vm_exact_value(vm, NULL, tav->value, f->type);
				}
			} else {
				for (isize i = 0; i < value_count; i++) {
					TypeAndValue *tav = type_and_value_of_expression(vm->module->info, cl->elems[i]);
					GB_ASSERT(tav != NULL);
					Entity *f = t->Record.fields_in_src_order[i];
					result.val_comp[f->Variable.field_index] = vm_exact_value(vm, NULL, tav->value, f->type);
				}
			}

			return result;
		} else {
			GB_PANIC("TODO(bill): Other compound types\n");
		}

	} else if (value.kind == ExactValue_Invalid) {
		vmValue zero_result = {};
		zero_result.type = t;
		return zero_result;
	} else {
		gb_printf_err("TODO(bill): Other constant types: %s\n", type_to_string(original_type));
	}

	GB_ASSERT_MSG(t == NULL, "%s - %d", type_to_string(t), value.kind);
	vmValue void_result = {};
	return void_result;
}


vmValue vm_operand_value(VirtualMachine *vm, ssaValue *value) {
	vmFrame *f = vm_back_frame(vm);
	vmValue v = {};
	switch (value->kind) {
	case ssaValue_Constant: {
		v = vm_exact_value(vm, value, value->Constant.value, value->Constant.type);
	} break;
	case ssaValue_ConstantSlice: {
		ssaValueConstant *cs = &value->ConstantSlice;
		v = vm_make_value_comp(ssa_type(value), vm->stack_allocator, 3);
		v.val_comp[0] = vm_operand_value(vm, cs->backing_array);
		v.val_comp[1] = vm_make_value_int(t_int, cs->count);
		v.val_comp[2] = vm_make_value_int(t_int, cs->count);
	} break;
	case ssaValue_Nil:
		GB_PANIC("TODO(bill): ssaValue_Nil");
		break;
	case ssaValue_TypeName:
		GB_PANIC("ssaValue_TypeName has no operand value");
		break;
	case ssaValue_Global:
		v = *map_get(&vm->globals, hash_pointer(value));
		break;
	case ssaValue_Param:
		v = *map_get(&f->values, hash_pointer(value));
		break;
	case ssaValue_Proc: {
		v.type = ssa_type(value);
		v.val_proc.proc = &value->Proc;
		// GB_PANIC("TODO(bill): ssaValue_Proc");
	} break;
	case ssaValue_Block:
		GB_PANIC("ssaValue_Block has no operand value");
		break;
	case ssaValue_Instr: {
		vmValue *found = map_get(&f->values, hash_pointer(value));
		if (found) {
			v = *found;
		} else {
			GB_PANIC("Invalid instruction");
		}
	} break;
	}

	return v;
}

void vm_store_integer(VirtualMachine *vm, void *dst, vmValue val) {
	// TODO(bill): I assume little endian here
	GB_ASSERT(dst != NULL);
	Type *type = val.type;
	GB_ASSERT_MSG(is_type_integer(type) || is_type_boolean(type),
	              "\nExpected integer/boolean, got %s (%s)",
	              type_to_string(type),
	              type_to_string(base_type(type)));
	i64 size = vm_type_size_of(vm, type);
	gb_memcopy(dst, &val.val_int, size);
}

void vm_store_pointer(VirtualMachine *vm, void *dst, vmValue val) {
	// TODO(bill): I assume little endian here
	GB_ASSERT(dst != NULL);
	GB_ASSERT(is_type_pointer(val.type));
	gb_memcopy(dst, &val.val_ptr, vm_type_size_of(vm, t_rawptr));
}


void vm_store(VirtualMachine *vm, void *dst, vmValue val, Type *type) {
	i64 size = vm_type_size_of(vm, type);
	Type *original_type = type;
	// NOTE(bill): enums are pretty much integers
	type = base_type(get_enum_base_type(type));

	switch (type->kind) {
	case Type_Basic:
		switch (type->Basic.kind) {
		case Basic_bool:
		case Basic_i8:
		case Basic_u8:
		case Basic_i16:
		case Basic_u16:
		case Basic_i32:
		case Basic_u32:
		case Basic_i64:
		case Basic_u64:
		case Basic_int:
		case Basic_uint:
			vm_store_integer(vm, dst, val);
			break;
		case Basic_f32:
			*cast(f32 *)dst = val.val_f32;
			break;
		case Basic_f64:
			*cast(f64 *)dst = val.val_f64;
			break;
		case Basic_rawptr:
			vm_store_pointer(vm, dst, val); // NOTE(bill): A pointer can be treated as an integer
			break;
		case Basic_string: {
			i64 word_size = vm_type_size_of(vm, t_int);

			u8 *mem = cast(u8 *)dst;
			vm_store_pointer(vm, mem+0*word_size, val.val_comp[0]);
			vm_store_integer(vm, mem+1*word_size, val.val_comp[1]);
		} break;
		case Basic_any: {
			i64 word_size = vm_type_size_of(vm, t_int);

			u8 *mem = cast(u8 *)dst;
			vm_store_pointer(vm, mem+0*word_size, val.val_comp[0]);
			vm_store_pointer(vm, mem+1*word_size, val.val_comp[1]);
		} break;
		default:
			gb_printf_err("TODO(bill): other basic types for `vm_store` %s\n", type_to_string(type));
			break;
		}
		break;

	case Type_Pointer:
		vm_store_pointer(vm, dst, val);
		break;

	case Type_Record: {
		u8 *mem = cast(u8 *)dst;
		gb_zero_size(mem, size);

		if (is_type_struct(type)) {
			GB_ASSERT_MSG(type->Record.field_count >= val.val_comp.count,
			              "%td vs %td",
			              type->Record.field_count, val.val_comp.count);

			isize field_count = gb_min(val.val_comp.count, type->Record.field_count);

			for (isize i = 0; i < field_count; i++) {
				Entity *f = type->Record.fields[i];
				i64 offset = vm_type_offset_of(vm, type, i);
				vm_store(vm, mem+offset, val.val_comp[i], f->type);
			}
		} else if (is_type_union(type)) {
			GB_ASSERT(val.val_comp.count == 2);
			i64 word_size = vm_type_size_of(vm, t_int);
			i64 size_of_union = vm_type_size_of(vm, type) - word_size;
			for (isize i = 0; i < size_of_union; i++) {
				mem[i] = cast(u8)val.val_comp[0].val_comp[i].val_int;
			}
			vm_store_integer(vm, mem + size_of_union, val.val_comp[1]);

		} else if (is_type_raw_union(type)) {
			GB_ASSERT(val.val_comp.count == 1);
			i64 word_size = vm_type_size_of(vm, t_int);
			i64 size_of_union = vm_type_size_of(vm, type) - word_size;
			for (isize i = 0; i < size_of_union; i++) {
				mem[i] = cast(u8)val.val_comp[0].val_comp[i].val_int;
			}
		} else {
			GB_PANIC("Unknown record type: %s", type_to_string(type));
		}
	} break;

	case Type_Tuple: {
		u8 *mem = cast(u8 *)dst;

		GB_ASSERT_MSG(type->Tuple.variable_count >= val.val_comp.count,
		              "%td vs %td",
		              type->Tuple.variable_count, val.val_comp.count);

		isize variable_count = gb_min(val.val_comp.count, type->Tuple.variable_count);

		for (isize i = 0; i < variable_count; i++) {
			Entity *f = type->Tuple.variables[i];
			void *ptr = mem + vm_type_offset_of(vm, type, i);
			vm_store(vm, ptr, val.val_comp[i], f->type);
		}
	} break;

	case Type_Array: {
		Type *elem_type = type->Array.elem;
		u8 *mem = cast(u8 *)dst;
		i64 elem_size = vm_type_size_of(vm, elem_type);
		i64 elem_count = gb_min(val.val_comp.count, type->Array.count);

		for (i64 i = 0; i < elem_count; i++) {
			vm_store(vm, mem + i*elem_size, val.val_comp[i], elem_type);
		}
	} break;

	case Type_Vector: {
		Type *elem_type = type->Array.elem;
		GB_ASSERT_MSG(!is_type_boolean(elem_type), "TODO(bill): Booleans of vectors");
		u8 *mem = cast(u8 *)dst;
		i64 elem_size = vm_type_size_of(vm, elem_type);
		i64 elem_count = gb_min(val.val_comp.count, type->Array.count);

		for (i64 i = 0; i < elem_count; i++) {
			vm_store(vm, mem + i*elem_size, val.val_comp[i], elem_type);
		}
	} break;

	case Type_Slice: {
		i64 word_size = vm_type_size_of(vm, t_int);

		u8 *mem = cast(u8 *)dst;
		vm_store_pointer(vm, mem+0*word_size, val.val_comp[0]);
		vm_store_integer(vm, mem+1*word_size, val.val_comp[1]);
		vm_store_integer(vm, mem+2*word_size, val.val_comp[2]);
	} break;

	default:
		gb_printf_err("TODO(bill): other types for `vm_store` %s\n", type_to_string(type));
		break;
	}
}

vmValue vm_load_integer(VirtualMachine *vm, void *ptr, Type *type) {
	// TODO(bill): I assume little endian here
	vmValue v = {};
	v.type = type;
	GB_ASSERT(is_type_integer(type) || is_type_boolean(type));
	// NOTE(bill): Only load the needed amount
	gb_memcopy(&v.val_int, ptr, vm_type_size_of(vm, type));
	return v;
}

vmValue vm_load_pointer(VirtualMachine *vm, void *ptr, Type *type) {
	// TODO(bill): I assume little endian here
	vmValue v = {};
	v.type = type;
	GB_ASSERT(is_type_pointer(type));
	// NOTE(bill): Only load the needed amount
	gb_memcopy(&v.val_int, ptr, vm_type_size_of(vm, type));
	return v;
}


vmValue vm_load(VirtualMachine *vm, void *ptr, Type *type) {
	i64 size = vm_type_size_of(vm, type);
	Type *original_type = type;
	type = base_type(get_enum_base_type(type));

	switch (type->kind) {
	case Type_Basic:
		switch (type->Basic.kind) {
		case Basic_bool:
		case Basic_i8:
		case Basic_u8:
		case Basic_i16:
		case Basic_u16:
		case Basic_i32:
		case Basic_u32:
		case Basic_i64:
		case Basic_u64:
		case Basic_int:
		case Basic_uint:
			return vm_load_integer(vm, ptr, original_type);
		case Basic_f32:
			return vm_make_value_f32(original_type, *cast(f32 *)ptr);
		case Basic_f64:
			return vm_make_value_f64(original_type, *cast(f64 *)ptr);
		case Basic_rawptr:
			return vm_load_pointer(vm, ptr, original_type);


		case Basic_string: {
			u8 *mem = cast(u8 *)ptr;
			i64 word_size = vm_type_size_of(vm, t_int);
			vmValue result = vm_make_value_comp(type, vm->stack_allocator, 2);
			result.val_comp[0] = vm_load_pointer(vm, mem+0*word_size, t_u8_ptr);
			result.val_comp[1] = vm_load_integer(vm, mem+1*word_size, t_int);
			return result;
		} break;

		default:
			GB_PANIC("TODO(bill): other basic types for `vm_load` %s", type_to_string(type));
			break;
		}
		break;

	case Type_Pointer:
		return vm_load_pointer(vm, ptr, original_type);

	case Type_Array: {
		i64 count = type->Array.count;
		Type *elem_type = type->Array.elem;
		i64 elem_size = vm_type_size_of(vm, elem_type);

		vmValue result = vm_make_value_comp(type, vm->stack_allocator, count);

		u8 *mem = cast(u8 *)ptr;
		for (isize i = 0; i < count; i++) {
			i64 offset = elem_size*i;
			vmValue val = vm_load(vm, mem+offset, elem_type);
			result.val_comp[i] = val;
		}

		return result;
	} break;

	case Type_Slice: {
		Type *elem_type = type->Slice.elem;
		i64 elem_size = vm_type_size_of(vm, elem_type);
		i64 word_size = vm_type_size_of(vm, t_int);

		vmValue result = vm_make_value_comp(type, vm->stack_allocator, 3);

		u8 *mem = cast(u8 *)ptr;
		result.val_comp[0] = vm_load(vm, mem+0*word_size, t_rawptr); // data
		result.val_comp[1] = vm_load(vm, mem+1*word_size, t_int);    // count
		result.val_comp[2] = vm_load(vm, mem+2*word_size, t_int);    // capacity
		return result;
	} break;

	case Type_Record: {
		if (is_type_struct(type)) {
			isize field_count = type->Record.field_count;

			vmValue result = vm_make_value_comp(type, vm->stack_allocator, field_count);

			u8 *mem = cast(u8 *)ptr;
			for (isize i = 0; i < field_count; i++) {
				Entity *f = type->Record.fields[i];
				i64 offset = vm_type_offset_of(vm, type, i);
				result.val_comp[i] = vm_load(vm, mem+offset, f->type);
			}

			return result;
		} else if (is_type_union(type)) {
			i64 word_size = vm_type_size_of(vm, t_int);
			i64 size_of_union = vm_type_size_of(vm, type) - word_size;
			u8 *mem = cast(u8 *)ptr;

			vmValue result = vm_make_value_comp(type, vm->stack_allocator, 2);
			result.val_comp[0] = vm_load(vm, mem, make_type_array(vm->stack_allocator, t_u8, size_of_union));
			result.val_comp[1] = vm_load(vm, mem+size_of_union, t_int);
			return result;
		} else if (is_type_raw_union(type)) {
			gb_printf_err("TODO(bill): load raw_union\n");
		} else {
			gb_printf_err("TODO(bill): load other records\n");
		}
	} break;

	case Type_Tuple: {
		isize count = type->Tuple.variable_count;

		vmValue result = vm_make_value_comp(type, vm->stack_allocator, count);

		u8 *mem = cast(u8 *)ptr;
		for (isize i = 0; i < count; i++) {
			Entity *f = type->Tuple.variables[i];
			i64 offset = vm_type_offset_of(vm, type, i);
			result.val_comp[i] = vm_load(vm, mem+offset, f->type);
		}
		return result;
	} break;

	default:
		GB_PANIC("TODO(bill): other types for `vm_load` %s", type_to_string(type));
		break;
	}

	GB_ASSERT(type == NULL);
	vmValue void_result = {};
	return void_result;
}

vmValue vm_exec_binary_op(VirtualMachine *vm, Type *type, vmValue lhs, vmValue rhs, TokenKind op) {
	vmValue result = {};

	type = base_type(type);
	if (is_type_vector(type)) {
		Type *elem = type->Vector.elem;
		i64 count = type->Vector.count;

		result = vm_make_value_comp(type, vm->stack_allocator, count);

		for (i64 i = 0; i < count; i++) {
			result.val_comp[i] = vm_exec_binary_op(vm, elem, lhs.val_comp[i], rhs.val_comp[i], op);
		}

		return result;
	}

	if (gb_is_between(op, Token__ComparisonBegin+1, Token__ComparisonEnd-1)) {
		if (is_type_integer(type) || is_type_boolean(type)) {
			// TODO(bill): Do I need to take into account the size of the integer?
			switch (op) {
			case Token_CmpEq: result.val_int = lhs.val_int == rhs.val_int; break;
			case Token_NotEq: result.val_int = lhs.val_int != rhs.val_int; break;
			case Token_Lt:    result.val_int = lhs.val_int <  rhs.val_int; break;
			case Token_Gt:    result.val_int = lhs.val_int >  rhs.val_int; break;
			case Token_LtEq:  result.val_int = lhs.val_int <= rhs.val_int; break;
			case Token_GtEq:  result.val_int = lhs.val_int >= rhs.val_int; break;
			}
		} else if (type == t_f32) {
			switch (op) {
			case Token_CmpEq: result.val_f32 = lhs.val_f32 == rhs.val_f32; break;
			case Token_NotEq: result.val_f32 = lhs.val_f32 != rhs.val_f32; break;
			case Token_Lt:    result.val_f32 = lhs.val_f32 <  rhs.val_f32; break;
			case Token_Gt:    result.val_f32 = lhs.val_f32 >  rhs.val_f32; break;
			case Token_LtEq:  result.val_f32 = lhs.val_f32 <= rhs.val_f32; break;
			case Token_GtEq:  result.val_f32 = lhs.val_f32 >= rhs.val_f32; break;
			}
		} else if (type == t_f64) {
			switch (op) {
			case Token_CmpEq: result.val_f64 = lhs.val_f64 == rhs.val_f64; break;
			case Token_NotEq: result.val_f64 = lhs.val_f64 != rhs.val_f64; break;
			case Token_Lt:    result.val_f64 = lhs.val_f64 <  rhs.val_f64; break;
			case Token_Gt:    result.val_f64 = lhs.val_f64 >  rhs.val_f64; break;
			case Token_LtEq:  result.val_f64 = lhs.val_f64 <= rhs.val_f64; break;
			case Token_GtEq:  result.val_f64 = lhs.val_f64 >= rhs.val_f64; break;
			}
		} else if (is_type_string(type)) {
			Array<vmValue> args = {};
			array_init_count(&args, vm->stack_allocator, 2);
			args[0] = lhs;
			args[1] = rhs;
			switch (op) {
			case Token_CmpEq: result = vm_call_proc_by_name(vm, make_string("__string_eq"), args); break;
			case Token_NotEq: result = vm_call_proc_by_name(vm, make_string("__string_ne"), args); break;
			case Token_Lt:    result = vm_call_proc_by_name(vm, make_string("__string_lt"), args); break;
			case Token_Gt:    result = vm_call_proc_by_name(vm, make_string("__string_gt"), args); break;
			case Token_LtEq:  result = vm_call_proc_by_name(vm, make_string("__string_le"), args); break;
			case Token_GtEq:  result = vm_call_proc_by_name(vm, make_string("__string_ge"), args); break;
			}
		} else {
			GB_PANIC("TODO(bill): Vector BinaryOp");
		}
	} else {
		if (is_type_integer(type) || is_type_boolean(type)) {
			switch (op) {
			case Token_Add: result.val_int = lhs.val_int + rhs.val_int;  break;
			case Token_Sub: result.val_int = lhs.val_int - rhs.val_int;  break;
			case Token_And: result.val_int = lhs.val_int & rhs.val_int;  break;
			case Token_Or:  result.val_int = lhs.val_int | rhs.val_int;  break;
			case Token_Xor: result.val_int = lhs.val_int ^ rhs.val_int;  break;
			case Token_Shl: result.val_int = lhs.val_int << rhs.val_int; break;
			case Token_Shr: result.val_int = lhs.val_int >> rhs.val_int; break;
			case Token_Mul: result.val_int = lhs.val_int * rhs.val_int;  break;
			case Token_Not: result.val_int = lhs.val_int ^ rhs.val_int;  break;

			case Token_AndNot: result.val_int = lhs.val_int & (~rhs.val_int); break;

			// TODO(bill): Take into account size of integer and signedness
			case Token_Quo: GB_PANIC("TODO(bill): BinaryOp Integer Token_Quo"); break;
			case Token_Mod: GB_PANIC("TODO(bill): BinaryOp Integer Token_Mod"); break;

			}
		} else if (is_type_float(type)) {
			if (type == t_f32) {
				switch (op) {
				case Token_Add: result.val_f32 = lhs.val_f32 + rhs.val_f32;  break;
				case Token_Sub: result.val_f32 = lhs.val_f32 - rhs.val_f32;  break;
				case Token_Mul: result.val_f32 = lhs.val_f32 * rhs.val_f32;  break;
				case Token_Quo: result.val_f32 = lhs.val_f32 / rhs.val_f32;  break;

				case Token_Mod: GB_PANIC("TODO(bill): BinaryOp f32 Token_Mod"); break;
				}
			} else if (type == t_f64) {
				switch (op) {
				case Token_Add: result.val_f64 = lhs.val_f64 + rhs.val_f64;  break;
				case Token_Sub: result.val_f64 = lhs.val_f64 - rhs.val_f64;  break;
				case Token_Mul: result.val_f64 = lhs.val_f64 * rhs.val_f64;  break;
				case Token_Quo: result.val_f64 = lhs.val_f64 / rhs.val_f64;  break;

				case Token_Mod: GB_PANIC("TODO(bill): BinaryOp f64 Token_Mod"); break;
				}
			}
		} else {
			GB_PANIC("Invalid binary op type");
		}
	}

	return result;
}

void vm_exec_instr(VirtualMachine *vm, ssaValue *value) {
	GB_ASSERT(value != NULL);
	GB_ASSERT(value->kind == ssaValue_Instr);
	ssaInstr *instr = &value->Instr;
	vmFrame *f = vm_back_frame(vm);

#if 0
	if (instr->kind != ssaInstr_Comment) {
		gb_printf("exec_instr: %.*s\n", LIT(ssa_instr_strings[instr->kind]));
	}
#endif

	switch (instr->kind) {
	case ssaInstr_StartupRuntime: {
#if 1
		Array<vmValue> args = {}; // Empty
		vm_call_proc_by_name(vm, make_string(SSA_STARTUP_RUNTIME_PROC_NAME), args); // NOTE(bill): No return value
#endif
	} break;

	case ssaInstr_Comment:
		break;

	case ssaInstr_Local: {
		Type *type = ssa_type(value);
		GB_ASSERT(is_type_pointer(type));
		isize size  = gb_max(1, vm_type_size_of(vm, type));
		isize align = gb_max(1, vm_type_align_of(vm, type));
		void *memory = gb_alloc_align(vm->stack_allocator, size, align);
		GB_ASSERT(memory != NULL);
		vm_set_value(f, value, vm_make_value_ptr(type, memory));
		array_add(&f->locals, memory);
	} break;

	case ssaInstr_ZeroInit: {
		Type *t = type_deref(ssa_type(instr->ZeroInit.address));
		vmValue addr = vm_operand_value(vm, instr->ZeroInit.address);
		void *data = addr.val_ptr;
		i64 size = vm_type_size_of(vm, t);
		gb_zero_size(data, size);
	} break;

	case ssaInstr_Store: {
		vmValue addr = vm_operand_value(vm, instr->Store.address);
		vmValue val = vm_operand_value(vm, instr->Store.value);
		GB_ASSERT(val.type != NULL);
		Type *t = type_deref(ssa_type(instr->Store.address));
		vm_store(vm, addr.val_ptr, val, t);
	} break;

	case ssaInstr_Load: {
		vmValue addr = vm_operand_value(vm, instr->Load.address);
		Type *t = ssa_type(value);
		vmValue v = vm_load(vm, addr.val_ptr, t);
		vm_set_value(f, value, v);
	} break;

	case ssaInstr_ArrayElementPtr: {
		vmValue address    = vm_operand_value(vm, instr->ArrayElementPtr.address);
		vmValue elem_index = vm_operand_value(vm, instr->ArrayElementPtr.elem_index);

		Type *t = ssa_type(instr->ArrayElementPtr.address);
		GB_ASSERT(is_type_pointer(t));
		i64 elem_size = vm_type_size_of(vm, type_deref(t));
		void *ptr = cast(u8 *)address.val_ptr + elem_index.val_int*elem_size;
		vm_set_value(f, value, vm_make_value_ptr(t, ptr));
	} break;

	case ssaInstr_StructElementPtr: {
		vmValue address = vm_operand_value(vm, instr->StructElementPtr.address);
		i32 elem_index  = instr->StructElementPtr.elem_index;

		Type *t = ssa_type(instr->StructElementPtr.address);
		GB_ASSERT(is_type_pointer(t));
		i64 offset = vm_type_offset_of(vm, type_deref(t), elem_index);
		void *ptr = cast(u8 *)address.val_ptr + offset;
		vm_set_value(f, value, vm_make_value_ptr(t, ptr));
	} break;

	case ssaInstr_PtrOffset: {
		Type *t = ssa_type(instr->PtrOffset.address);
		GB_ASSERT(is_type_pointer(t));
		i64 elem_size = vm_type_size_of(vm, type_deref(t));
		vmValue address = vm_operand_value(vm, instr->PtrOffset.address);
		vmValue offset  = vm_operand_value(vm, instr->PtrOffset.offset);

		void *ptr = cast(u8 *)address.val_ptr + offset.val_int*elem_size;
		vm_set_value(f, value, vm_make_value_ptr(t, ptr));
	} break;

	case ssaInstr_Phi: {
		for_array(i, f->curr_block->preds) {
			ssaBlock *pred = f->curr_block->preds[i];
			if (f->prev_block == pred) {
				vmValue edge = vm_operand_value(vm, instr->Phi.edges[i]);
				vm_set_value(f, value, edge);
				break;
			}
		}
	} break;

	case ssaInstr_ArrayExtractValue: {
		vmValue s = vm_operand_value(vm, instr->ArrayExtractValue.address);
		vmValue v = s.val_comp[instr->ArrayExtractValue.index];
		vm_set_value(f, value, v);
	} break;

	case ssaInstr_StructExtractValue: {
		vmValue s = vm_operand_value(vm, instr->StructExtractValue.address);
		vmValue v = s.val_comp[instr->StructExtractValue.index];
		vm_set_value(f, value, v);
	} break;

	case ssaInstr_Jump: {
		vm_jump_block(f, instr->Jump.block);
	} break;

	case ssaInstr_If: {
		vmValue cond = vm_operand_value(vm, instr->If.cond);
		if (cond.val_int != 0) {
			vm_jump_block(f, instr->If.true_block);
		} else {
			vm_jump_block(f, instr->If.false_block);
		}
	} break;

	case ssaInstr_Return: {
		Type *return_type = NULL;
		vmValue result = {};

		if (instr->Return.value != NULL) {
			return_type = ssa_type(instr->Return.value);
			result = vm_operand_value(vm, instr->Return.value);
		}

		f->result = result;
		f->curr_block = NULL;
		f->instr_index = 0;
		return;
	} break;

	case ssaInstr_Conv: {
		// TODO(bill): Assuming little endian
		vmValue dst = {};
		vmValue src = vm_operand_value(vm, instr->Conv.value);
		i64 from_size = vm_type_size_of(vm, instr->Conv.from);
		i64 to_size   = vm_type_size_of(vm, instr->Conv.to);
		switch (instr->Conv.kind) {
		case ssaConv_trunc:
			gb_memcopy(&dst, &src, to_size);
			break;
		case ssaConv_zext:
			gb_memcopy(&dst, &src, from_size);
			break;
		case ssaConv_fptrunc: {
			GB_ASSERT(from_size > to_size);
			GB_ASSERT(base_type(instr->Conv.from) == t_f64);
			GB_ASSERT(base_type(instr->Conv.to) == t_f32);
			dst.val_f32 = cast(f32)src.val_f64;
		} break;
		case ssaConv_fpext: {
			GB_ASSERT(from_size < to_size);
			GB_ASSERT(base_type(instr->Conv.from) == t_f32);
			GB_ASSERT(base_type(instr->Conv.to) == t_f64);
			dst.val_f64 = cast(f64)src.val_f32;
		} break;
		case ssaConv_fptoui: {
			Type *from = base_type(instr->Conv.from);
			if (from == t_f64) {
				u64 u = cast(u64)src.val_f64;
				vm_store_integer(vm, &dst, vm_make_value_int(instr->Conv.to, u));
			} else {
				u64 u = cast(u64)src.val_f32;
				vm_store_integer(vm, &dst, vm_make_value_int(instr->Conv.to, u));
			}
		} break;
		case ssaConv_fptosi: {
			Type *from = base_type(instr->Conv.from);
			if (from == t_f64) {
				i64 i = cast(i64)src.val_f64;
				vm_store_integer(vm, &dst, vm_make_value_int(instr->Conv.to, i));
			} else {
				i64 i = cast(i64)src.val_f32;
				vm_store_integer(vm, &dst, vm_make_value_int(instr->Conv.to, i));
			}
		} break;
		case ssaConv_uitofp: {
			Type *to = base_type(instr->Conv.to);
			if (to == t_f64) {
				dst = vm_make_value_f64(instr->Conv.to, cast(f64)cast(u64)src.val_int);
			} else {
				dst = vm_make_value_f32(instr->Conv.to, cast(f32)cast(u64)src.val_int);
			}
		} break;
		case ssaConv_sitofp: {
			Type *to = base_type(instr->Conv.to);
			if (to == t_f64) {
				dst = vm_make_value_f64(instr->Conv.to, cast(f64)cast(i64)src.val_int);
			} else {
				dst = vm_make_value_f32(instr->Conv.to, cast(f32)cast(i64)src.val_int);
			}
		} break;

		case ssaConv_ptrtoint:
			dst = vm_make_value_int(instr->Conv.to, cast(i64)src.val_ptr);
			break;
		case ssaConv_inttoptr:
			dst = vm_make_value_ptr(instr->Conv.to, cast(void *)src.val_int);
			break;
		case ssaConv_bitcast:
			dst = src;
			dst.type = instr->Conv.to;
			break;
		}

		vm_set_value(f, value, dst);
	} break;

	case ssaInstr_Unreachable: {
		GB_PANIC("Unreachable");
	} break;

	case ssaInstr_BinaryOp: {
		ssaInstrBinaryOp *bo = &instr->BinaryOp;
		Type *type = ssa_type(bo->left);
		vmValue lhs = vm_operand_value(vm, bo->left);
		vmValue rhs = vm_operand_value(vm, bo->right);
		vmValue v = vm_exec_binary_op(vm, type, lhs, rhs, bo->op);
		vm_set_value(f, value, v);
	} break;

	case ssaInstr_Call: {
		Array<vmValue> args = {};
		array_init(&args, f->stack_allocator, instr->Call.arg_count);
		for (isize i = 0; i < instr->Call.arg_count; i++) {
			array_add(&args, vm_operand_value(vm, instr->Call.args[i]));
		}
		vmValue proc = vm_operand_value(vm, instr->Call.value);
		if (proc.val_proc.proc != NULL) {
			vmValue result = vm_call_proc(vm, proc.val_proc.proc, args);
			vm_set_value(f, value, result);
		} else {
			GB_PANIC("TODO(bill): external procedure calls");
		}

	} break;

	case ssaInstr_Select: {
		vmValue v = {};
		vmValue cond = vm_operand_value(vm, instr->Select.cond);
		if (cond.val_int != 0) {
			v = vm_operand_value(vm, instr->Select.true_value);
		} else {
			v = vm_operand_value(vm, instr->Select.false_value);
		}

		vm_set_value(f, value, v);
	} break;

	case ssaInstr_VectorExtractElement: {
		vmValue vector = vm_operand_value(vm, instr->VectorExtractElement.vector);
		vmValue index  = vm_operand_value(vm, instr->VectorExtractElement.index);
		vmValue v = vector.val_comp[index.val_int];
		vm_set_value(f, value, v);
	} break;

	case ssaInstr_VectorInsertElement: {
		vmValue vector = vm_operand_value(vm, instr->VectorInsertElement.vector);
		vmValue elem   = vm_operand_value(vm, instr->VectorInsertElement.elem);
		vmValue index  = vm_operand_value(vm, instr->VectorInsertElement.index);
		vector.val_comp[index.val_int] = elem;
	} break;

	case ssaInstr_VectorShuffle: {
		ssaValueVectorShuffle *vs = &instr->VectorShuffle;
		vmValue old_vector = vm_operand_value(vm, instr->VectorShuffle.vector);
		vmValue new_vector = vm_make_value_comp(ssa_type(value), vm->stack_allocator, vs->index_count);

		for (i32 i = 0; i < vs->index_count; i++) {
			new_vector.val_comp[i] = old_vector.val_comp[vs->indices[i]];
		}

		vm_set_value(f, value, new_vector);
	} break;

	case ssaInstr_BoundsCheck: {
		ssaInstrBoundsCheck *bc = &instr->BoundsCheck;
		Array<vmValue> args = {};
		array_init(&args, vm->stack_allocator, 5);
		array_add(&args, vm_exact_value(vm, NULL, make_exact_value_string(bc->pos.file), t_string));
		array_add(&args, vm_exact_value(vm, NULL, make_exact_value_integer(bc->pos.line), t_int));
		array_add(&args, vm_exact_value(vm, NULL, make_exact_value_integer(bc->pos.column), t_int));
		array_add(&args, vm_operand_value(vm, bc->index));
		array_add(&args, vm_operand_value(vm, bc->len));

		vm_call_proc_by_name(vm, make_string("__bounds_check_error"), args);
	} break;

	case ssaInstr_SliceBoundsCheck: {
		ssaInstrSliceBoundsCheck *bc = &instr->SliceBoundsCheck;
		Array<vmValue> args = {};

		array_init(&args, vm->stack_allocator, 7);
		array_add(&args, vm_exact_value(vm, NULL, make_exact_value_string(bc->pos.file), t_string));
		array_add(&args, vm_exact_value(vm, NULL, make_exact_value_integer(bc->pos.line), t_int));
		array_add(&args, vm_exact_value(vm, NULL, make_exact_value_integer(bc->pos.column), t_int));
		array_add(&args, vm_operand_value(vm, bc->low));
		array_add(&args, vm_operand_value(vm, bc->high));
		if (!bc->is_substring) {
			array_add(&args, vm_operand_value(vm, bc->max));
			vm_call_proc_by_name(vm, make_string("__slice_expr_error"), args);
		} else {
			vm_call_proc_by_name(vm, make_string("__substring_expr_error"), args);
		}
	} break;

	default: {
		GB_PANIC("<unknown instr> %d\n", instr->kind);
	} break;
	}
}



void vm_print_value(vmValue value, Type *type) {
	type = base_type(type);
	if (is_type_string(type)) {
		vmValue data  = value.val_comp[0];
		vmValue count = value.val_comp[1];
		gb_printf("`%.*s`", cast(int)count.val_int, cast(u8 *)data.val_ptr);
	} else if (is_type_boolean(type)) {
		if (value.val_int != 0) {
			gb_printf("true");
		} else {
			gb_printf("false");
		}
	} else if (is_type_integer(type)) {
		gb_printf("%lld", cast(i64)value.val_int);
	} else if (type == t_f32) {
		gb_printf("%f", value.val_f32);
	} else if (type == t_f64) {
		gb_printf("%f", value.val_f64);
	} else if (is_type_pointer(type)) {
		gb_printf("0x%08x", value.val_ptr);
	} else if (is_type_array(type)) {
		gb_printf("[");
		for_array(i, value.val_comp) {
			if (i > 0) {
				gb_printf(", ");
			}
			vm_print_value(value.val_comp[i], type->Array.elem);
		}
		gb_printf("]");
	} else if (is_type_vector(type)) {
		gb_printf("<");
		for_array(i, value.val_comp) {
			if (i > 0) {
				gb_printf(", ");
			}
			vm_print_value(value.val_comp[i], type->Vector.elem);
		}
		gb_printf(">");
	} else if (is_type_slice(type)) {
		gb_printf("[");
		for_array(i, value.val_comp) {
			if (i > 0) {
				gb_printf(", ");
			}
			vm_print_value(value.val_comp[i], type->Slice.elem);
		}
		gb_printf("]");
	} else if (is_type_maybe(type)) {
		if (value.val_comp[1].val_int != 0) {
			gb_printf("?");
			vm_print_value(value.val_comp[0], type->Maybe.elem);
		} else {
			gb_printf("nil");
		}
	} else if (is_type_struct(type)) {
		if (value.val_comp.count == 0) {
			gb_printf("nil");
		} else {
			gb_printf("{");
			for_array(i, value.val_comp) {
				if (i > 0) {
					gb_printf(", ");
				}
				vm_print_value(value.val_comp[i], type->Record.fields[i]->type);
			}
			gb_printf("}");
		}
	} else if (is_type_tuple(type)) {
		if (value.val_comp.count != 1) {
			gb_printf("(");
		}
		for_array(i, value.val_comp) {
			if (i > 0) {
				gb_printf(", ");
			}
			vm_print_value(value.val_comp[i], type->Tuple.variables[i]->type);
		}
		if (value.val_comp.count != 1) {
			gb_printf(")");
		}
	}
}
