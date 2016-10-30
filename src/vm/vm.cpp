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
		Array<vmValue> val_comp; // NOTE(bill): Will be freed through stack
	};
};

vmValue vm_make_value_ptr(void *ptr) {
	vmValue v = {};
	v.val_ptr = ptr;
	return v;
}


struct vmFrame {
	VirtualMachine *  vm;
	vmFrame *         caller;
	ssaProcedure *    curr_proc;
	ssaBlock *        curr_block;
	isize             instr_index;

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
	Map<vmValue>        globals;    // Key: ssaValue *
	vmValue             exit_value;
};

void vm_exec_instr(VirtualMachine *vm, ssaValue *value);

vmFrame *vm_back_frame(VirtualMachine *vm) {
	if (vm->frame_stack.count > 0) {
		return &vm->frame_stack[vm->frame_stack.count-1];
	}
	return NULL;
}



void vm_init(VirtualMachine *vm, ssaModule *module) {
	gb_arena_init_from_allocator(&vm->stack_arena, heap_allocator(), gb_megabytes(64));

	vm->module = module;
	vm->stack_allocator = gb_arena_allocator(&vm->stack_arena);
	vm->heap_allocator = heap_allocator();
	array_init(&vm->frame_stack, vm->heap_allocator);
	map_init(&vm->globals, vm->heap_allocator);
}
void vm_destroy(VirtualMachine *vm) {
	array_free(&vm->frame_stack);
	map_destroy(&vm->globals);
	gb_arena_free(&vm->stack_arena);
}





i64 vm_type_size_of(VirtualMachine *vm, Type *type) {
	return type_size_of(vm->module->sizes, vm->heap_allocator, type);
}
i64 vm_type_align_of(VirtualMachine *vm, Type *type) {
	return type_align_of(vm->module->sizes, vm->heap_allocator, type);
}
i64 vm_type_offset_of(VirtualMachine *vm, Type *type, i64 offset) {
	return type_offset_of(vm->module->sizes, vm->heap_allocator, type, offset);
}

void vm_set_value(vmFrame *f, ssaValue *v, vmValue val) {
	map_set(&f->values, hash_pointer(v), val);
}



vmFrame *vm_push_frame(VirtualMachine *vm, ssaProcedure *proc) {
	vmFrame frame = {};

	frame.vm          = vm;
	frame.curr_proc   = proc;
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

vmValue vm_call_procedure(VirtualMachine *vm, ssaProcedure *proc, Array<vmValue> values) {
	GB_ASSERT_MSG(proc->params.count == values.count,
	              "Incorrect number of arguments passed into procedure call!");


	vmValue result = {};

	if (proc->body == NULL) {
		GB_PANIC("TODO(bill): external procedure");
		return result;
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

	if (base_type(proc->type)->Proc.result_count > 0) {
		result = f->result;
	}
	vm_pop_frame(vm);
	return result;
}


vmValue vm_operand_value(VirtualMachine *vm, ssaValue *value) {
	vmFrame *f = vm_back_frame(vm);
	vmValue v = {};
	switch (value->kind) {
	case ssaValue_Constant: {
		auto *c = &value->Constant;
		Type *t = base_type(c->type);
		// i64 size = vm_type_size_of(vm, t);
		if (is_type_boolean(t)) {
			v.val_int = c->value.value_bool != 0;
		} else if (is_type_integer(t)) {
			v.val_int = c->value.value_integer;
		} else if (is_type_float(t)) {
			if (t->Basic.kind == Basic_f32) {
				v.val_f32 = cast(f32)c->value.value_float;
			} else if (t->Basic.kind == Basic_f64) {
				v.val_f64 = cast(f64)c->value.value_float;
			}
		} else if (is_type_pointer(t)) {
			v.val_ptr = cast(void *)cast(intptr)c->value.value_pointer;
		} else if (is_type_string(t)) {
			array_init(&v.val_comp, vm->heap_allocator, 2);

			String str = c->value.value_string;
			i64 len = str.len;
			u8 *text = gb_alloc_array(vm->heap_allocator, u8, len);
			gb_memcopy(text, str.text, len);

			vmValue data = {};
			vmValue count = {};
			data.val_ptr = text;
			count.val_int = len;
			array_add(&v.val_comp, data);
			array_add(&v.val_comp, count);
		} else {
			GB_PANIC("TODO(bill): Other constant types: %s", type_to_string(c->type));
		}
	} break;
	case ssaValue_ConstantSlice: {
		array_init(&v.val_comp, vm->heap_allocator, 3);

		auto *cs = &value->ConstantSlice;
		vmValue data = {};
		vmValue count = {};
		data = vm_operand_value(vm, cs->backing_array);
		count.val_int = cs->count;
		array_add(&v.val_comp, data);
		array_add(&v.val_comp, count);
		array_add(&v.val_comp, count);
	} break;
	case ssaValue_Nil:
		GB_PANIC("TODO(bill): ssaValue_Nil");
		break;
	case ssaValue_TypeName:
		GB_PANIC("TODO(bill): ssaValue_TypeName");
		break;
	case ssaValue_Global:
		v = *map_get(&vm->globals, hash_pointer(value));
		break;
	case ssaValue_Param:
		v = *map_get(&f->values, hash_pointer(value));
		break;
	case ssaValue_Proc: {
		v.val_proc.proc = &value->Proc;
		// GB_PANIC("TODO(bill): ssaValue_Proc");
	} break;
	case ssaValue_Block:
		GB_PANIC("TODO(bill): ssaValue_Block");
		break;
	case ssaValue_Instr: {
		vmValue *found = map_get(&f->values, hash_pointer(value));
		if (found) {
			v = *found;
		}
	} break;
	}

	return v;
}

void vm_store_integer(VirtualMachine *vm, vmValue *dst, vmValue val, i64 store_bytes) {
	// TODO(bill): I assume little endian here
	GB_ASSERT(dst != NULL);
	gb_memcopy(&dst->val_int, &val.val_int, store_bytes);

}

void vm_store(VirtualMachine *vm, vmValue *dst, vmValue val, Type *type) {
	i64 size = vm_type_size_of(vm, type);
	type = base_type(type);

	// TODO(bill): I assume little endian here

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
			vm_store_integer(vm, dst, val, size);
			break;
		case Basic_f32:
			dst->val_f32 = val.val_f32;
			break;
		case Basic_f64:
			dst->val_f64 = val.val_f64;
			break;
		case Basic_rawptr:
			dst->val_ptr = val.val_ptr;
			break;
		default:
			GB_PANIC("TODO(bill): other basic types for `vm_store`");
			break;
		}
		break;

	default:
		GB_PANIC("TODO(bill): other types for `vm_store`");
		break;
	}
}

vmValue vm_load_integer(VirtualMachine *vm, vmValue *ptr, i64 store_bytes) {
	// TODO(bill): I assume little endian here
	vmValue v = {};
	// NOTE(bill): Only load the needed amount
	gb_memcopy(&v.val_int, ptr->val_ptr, store_bytes);
	return v;
}

vmValue vm_load(VirtualMachine *vm, vmValue *ptr, Type *type) {
	i64 size = vm_type_size_of(vm, type);
	type = base_type(type);

	vmValue v = {};

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
			v = vm_load_integer(vm, ptr, size);
			break;
		case Basic_f32:
			v.val_f32 = *cast(f32 *)ptr;
			break;
		case Basic_f64:
			v.val_f64 = *cast(f64 *)ptr;
			break;
		case Basic_rawptr:
			v.val_ptr = *cast(void **)ptr;
			break;
		default:
			GB_PANIC("TODO(bill): other basic types for `vm_load`");
			break;
		}
		break;

	default:
		GB_PANIC("TODO(bill): other types for `vm_load`");
		break;
	}

	return v;
}


void vm_exec_instr(VirtualMachine *vm, ssaValue *value) {
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
#if 0
		ssaValue *v = ssa_lookup_member(vm->module, make_string(SSA_STARTUP_RUNTIME_PROC_NAME));
		GB_ASSERT(v->kind == ssaValue_Proc);
		ssaProcedure *proc = &v->Proc;
		Array<vmValue> args = {}; // Empty
		vm_call_procedure(vm, proc, args); // NOTE(bill): No return value
#endif
	} break;

	case ssaInstr_Comment:
		break;

	case ssaInstr_Local: {
		Type *type = ssa_type(value);
		isize size  = gb_max(1, vm_type_size_of(vm, type));
		isize align = gb_max(1, vm_type_align_of(vm, type));
		void *memory = gb_alloc_align(vm->stack_allocator, size, align);
		GB_ASSERT(memory != NULL);
		vmValue v = vm_make_value_ptr(memory);
		vm_set_value(f, value, v);
		array_add(&f->locals, memory);
	} break;

	case ssaInstr_ZeroInit: {

	} break;

	case ssaInstr_Store: {
		vmValue addr = vm_operand_value(vm, instr->Store.address);
		vmValue val = vm_operand_value(vm, instr->Store.value);
		vmValue *address = cast(vmValue *)addr.val_ptr;
		Type *t = ssa_type(instr->Store.value);
		vm_store(vm, address, val, t);
	} break;

	case ssaInstr_Load: {
		vmValue addr = vm_operand_value(vm, instr->Load.address);
		vmValue v = vm_load(vm, &addr, ssa_type(value));
		vm_set_value(f, value, v);
	} break;

	case ssaInstr_ArrayElementPtr: {
		vmValue address    = vm_operand_value(vm, instr->ArrayElementPtr.address);
		vmValue elem_index = vm_operand_value(vm, instr->ArrayElementPtr.elem_index);

		Type *t = ssa_type(instr->ArrayElementPtr.address);
		i64 elem_size = vm_type_size_of(vm, type_deref(t));
		void *ptr = cast(u8 *)address.val_ptr + elem_index.val_int*elem_size;
		vm_set_value(f, value, vm_make_value_ptr(ptr));
	} break;

	case ssaInstr_StructElementPtr: {
		vmValue address    = vm_operand_value(vm, instr->StructElementPtr.address);
		i32 elem_index = instr->StructElementPtr.elem_index;

		Type *t = ssa_type(instr->StructElementPtr.address);
		i64 offset_in_bytes = vm_type_offset_of(vm, type_deref(t), elem_index);
		void *ptr = cast(u8 *)address.val_ptr + offset_in_bytes;
		vm_set_value(f, value, vm_make_value_ptr(ptr));
	} break;

	case ssaInstr_PtrOffset: {
		Type *t = ssa_type(instr->PtrOffset.address);
		i64 elem_size = vm_type_size_of(vm, type_deref(t));
		vmValue address = vm_operand_value(vm, instr->PtrOffset.address);
		vmValue offset  = vm_operand_value(vm, instr->PtrOffset.offset);

		void *ptr = cast(u8 *)address.val_ptr + offset.val_int*elem_size;
		vm_set_value(f, value, vm_make_value_ptr(ptr));
	} break;

	case ssaInstr_Phi: {

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
		f->curr_block = instr->Jump.block;
		f->instr_index = 0;
	} break;

	case ssaInstr_If: {;
		vmValue cond = vm_operand_value(vm, instr->If.cond);
		if (cond.val_int != 0) {
			f->curr_block = instr->If.true_block;
		} else {
			f->curr_block = instr->If.false_block;
		}
		f->instr_index = 0;
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
		return;
	} break;

	case ssaInstr_Conv: {

	} break;

	case ssaInstr_Unreachable: {
		GB_PANIC("Unreachable");
	} break;

	case ssaInstr_BinaryOp: {
		auto *bo = &instr->BinaryOp;
		Type *t = base_type(ssa_type(bo->left));
		Type *et = t;
		while (et->kind == Type_Vector) {
			et = base_type(et->Vector.elem);
		}

		if (gb_is_between(bo->op, Token__ComparisonBegin+1, Token__ComparisonEnd-1)) {
			GB_PANIC("TODO(bill): Comparison operations");
		} else {
			vmValue v = {};
			vmValue l = vm_operand_value(vm, bo->left);
			vmValue r = vm_operand_value(vm, bo->right);

			if (is_type_integer(t)) {
				switch (bo->op) {
				case Token_Add: v.val_int = l.val_int + r.val_int; break;
				case Token_Sub: v.val_int = l.val_int - r.val_int; break;
				case Token_And: v.val_int = l.val_int & r.val_int; break;
				case Token_Or:  v.val_int = l.val_int | r.val_int; break;
				case Token_Xor: v.val_int = l.val_int ^ r.val_int; break;
				case Token_Shl: v.val_int = l.val_int << r.val_int; break;
				case Token_Shr: v.val_int = l.val_int >> r.val_int; break;
				case Token_Mul: v.val_int = l.val_int * r.val_int; break;
				case Token_Not: v.val_int = l.val_int ^ r.val_int; break;

				case Token_AndNot: v.val_int = l.val_int & (~r.val_int); break;

				case Token_Quo: GB_PANIC("TODO(bill): BinaryOp Integer Token_Quo"); break;
				case Token_Mod: GB_PANIC("TODO(bill): BinaryOp Integer Token_Mod"); break;

				}
			} else if (is_type_float(t)) {
				GB_PANIC("TODO(bill): Float BinaryOp");
			} else {
				GB_PANIC("TODO(bill): Vector BinaryOp");
			}

			vm_set_value(f, value, v);
		}
	} break;

	case ssaInstr_Call: {
		Array<vmValue> args = {};
		array_init(&args, f->stack_allocator, instr->Call.arg_count);
		for (isize i = 0; i < instr->Call.arg_count; i++) {
			array_add(&args, vm_operand_value(vm, instr->Call.args[i]));
		}
		vmValue proc = vm_operand_value(vm, instr->Call.value);
		if (proc.val_proc.proc != NULL) {
			vmValue result = vm_call_procedure(vm, proc.val_proc.proc, args);
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

	} break;

	case ssaInstr_VectorInsertElement: {

	} break;

	case ssaInstr_VectorShuffle: {

	} break;

	case ssaInstr_BoundsCheck: {

	} break;

	case ssaInstr_SliceBoundsCheck: {

	} break;


	default: {
		GB_PANIC("<unknown instr> %d\n", instr->kind);
	} break;
	}
}
