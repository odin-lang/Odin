#if 0
// TODO(bill): COMPLETELY REWORK THIS ENTIRE INTERPRETER
#include "dyncall/include/dyncall.h"

struct vmInterpreter;

/*
Types:
boolean
integer
float
pointer
string
any
array
vector
slice
maybe
struct
union
raw_union
enum
tuple
proc
*/

struct vmProcedure {
	Type * type;
	String name;
	b32    is_external;
};

struct vmValue {
	void *data;
	i32   id;
	Type *type;
	union {
		i64            v_int;
		f32            v_f32;
		f64            v_f64;
		vmProcedure *  v_proc;
	};
};

Array<vmValue> vm_empty_args = {};

struct vmFrame {
	vmInterpreter *i;
	vmFrame *      caller;
	ssaProcedure * proc;
	ssaBlock *     block;
	ssaBlock *     prev_block;
	isize          instr_index; // For the current block

	Array<void *>  env; // Index == instr id
	vmValue        result;
};

struct vmInterpreter {
	ssaModule *    module;
	BaseTypeSizes  sizes;
	gbArena        stack_arena;
	gbAllocator    stack_allocator;
	gbAllocator    heap_allocator;

	Array<vmFrame> frame_stack;
	Map<vmValue>   globals;
};

enum vmContinuation {
	vmContinuation_Next,
	vmContinuation_Return,
	vmContinuation_Branch,
};




i64 vm_size_of(vmInterpreter *i, Type *type) {
	return type_size_of(i->sizes, i->heap_allocator, type);
}
i64 vm_align_of(vmInterpreter *i, Type *type) {
	return type_align_of(i->sizes, i->heap_allocator, type);
}
i64 vm_offset_of(vmInterpreter *i, Type *type, i64 index) {
	return type_offset_of(i->sizes, i->heap_allocator, type, index);
}






Array<vmValue> vm_prepare_call(vmFrame *f, ssaInstr *instr, vmValue *proc) {
	GB_ASSERT(instr->kind == ssaInstr_Call);

	*proc = vm_get_value(f, instr->Call.value);

	Array<vmValue> args = {};
	array_init_count(&args, f->i->stack_allocator, instr->Call.arg_count);

	for (isize i = 0; i < instr->Call.arg_count; i++) {
		args[i] = vm_get_value(f, instr->Call.args[i]);
	}

	return args;
}


vmContinuation vm_visit_instr(vmFrame *f, ssaValue *value) {
	ssaInstr *instr = &value->Instr;
#if 1
	if (instr->kind != ssaInstr_Comment) {
		gb_printf("instr: %.*s\n", LIT(ssa_instr_strings[instr->kind]));
	}
#endif
	switch (instr->kind) {
	case ssaInstr_StartupRuntime: {

	} break;

	case ssaInstr_Comment: break;

	case ssaInstr_Local: {
		Type *type = ssa_type(value);
		GB_ASSERT(is_type_pointer(type));
		i64 size  = gb_max(1, vm_size_of(f->i, type));
		i64 align = gb_max(1, vm_align_of(f->i, type));
		void *mem = gb_alloc_align(f->i->stack_allocator, size, align);

		array_add(&f->locals, mem);
	} break;

	case ssaInstr_ZeroInit: {
		Type *pt = ssa_type(instr->ZeroInit.address);
		GB_ASSERT(is_type_pointer(pt));
		vmValue addr = vm_get_value(f, instr->ZeroInit.address);
		GB_ASSERT(are_types_identical(addr.type, ptr));
		i64 size = vm_size_of(vm, type_deref(pt));
		gb_zero(addr.v_ptr, size);
	} break;

	case ssaInstr_Store: {
		ssaValue *addr = instr->Store.Address;
		ssaValue *value = instr->Store.Value;
	} break;

	case ssaInstr_Load: {
		ssaValue *addr = instr->Load.Address;
	} break;

	case ssaInstr_ArrayElementPtr: {

	} break;

	case ssaInstr_StructElementPtr: {

	} break;

	case ssaInstr_PtrOffset: {

	} break;

	case ssaInstr_Phi:
		for_array(i, f->block->preds) {
			ssaBlock *pred = f->block->preds[i];
			if (f->prev_block == pred) {
				vmValue edge = vm_get_value(f, instr->Phi.edges[i]);
				// vm_set_value(f, value, edge);
				break;
			}
		}
		break;

	case ssaInstr_ArrayExtractValue: {

	} break;

	case ssaInstr_StructExtractValue: {

	} break;

	case ssaInstr_Jump:
		f->prev_block = f->block;
		f->block = instr->Jump.block;
		return vmContinuation_Branch;

	case ssaInstr_If:
		f->prev_block = f->block;
		if (vm_get_value(f, instr->If.cond).v_int != 0) {
			f->block = instr->If.true_block;
		} else {
			f->block = instr->If.false_block;
		}
		return vmContinuation_Branch;

	case ssaInstr_Return:
		if (instr->Return.value != NULL) {
			Type *type = base_type(ssa_type(instr->Return.value));
			GB_ASSERT(is_type_tuple(type));
			f->result = vm_get_value(f, instr->Return.value);
			if (type->Tuple.variable_count == 1) {
				f->result.type = type->Tuple.variables[0]->type;
			}
		}
		f->block = NULL;
		return vmContinuation_Return;

	case ssaInstr_Conv: {

	} break;

	case ssaInstr_Unreachable: {
		GB_PANIC("Unreachable");
	} break;

	case ssaInstr_BinaryOp: {

	} break;

	case ssaInstr_Call: {

	} break;

	case ssaInstr_Select: {

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

	return vmContinuation_Next;
}


void vm_run_frame(vmFrame *f) {
	for (;;) {
		for_array(i, f->block->instrs) {
			ssaValue *v = f->block->instrs[i];
			GB_ASSERT(v->kind == ssaValue_Instr);
			switch (vm_visit_instr(f, v)) {
			case vmContinuation_Return:
				return;
			case vmContinuation_Next:
				// Do nothing
				break;
			case vmContinuation_Branch:
				goto end;
			}
		}
	end:
		;
	}
}

ssaProcedure *vm_lookup_proc(vmInterpreter *i, String name) {
	ssaValue **found = map_get(&i->module->members, hash_string(name));
	if (found == NULL) {
		return NULL;
	}
	ssaValue *v = *found;
	if (v->kind != ssaValue_Proc) {
		return NULL;
	}

	return &v->Proc;
}

vmValue vm_ext(vmFrame *caller, Array<vmValue> args) {
	GB_PANIC("TODO(bill): vm_ext");
	vmValue v = {};
	return v;
}

vmValue vm_call(vmInterpreter *i, vmFrame *caller, ssaProcedure *proc, Array<vmValue> args) {
	if (proc == NULL) {
		GB_PANIC("Call to NULL procedure");
	}

	gb_printf("Call: %.*s", LIT(proc->name));

	vmFrame f = {};
	f.i = i;
	f.caller = caller;
	f.proc = proc;
	if (proc->body == NULL) {
		return vm_ext(&f, args);
	}
	f.block = proc->blocks[0];

	map_init_with_reserve(&f.env, i->heap_allocator, 1.5*proc->instr_count);
	defer (map_destroy(&f.env));

	array_init_count(&f.locals, i->heap_allocator, proc->local_count);
	defer (array_free(&f.locals));

	for_array(i, proc->params) {
		map_set(&f.env, hash_pointer(proc->params[i]), args[i]);
	}

	while (f.block != NULL) {
		vm_run_frame(&f);
	}

	return f.result;
}

i32 vm_interpret(ssaModule *m) {
	i32 exit_code = 2;

	vmInterpreter i = {};

	i.module = m;
	i.sizes = m->sizes;

	gb_arena_init_from_allocator(&i.stack_arena, heap_allocator(), gb_megabytes(64));
	defer (gb_arena_free(&i.stack_arena));

	i.stack_allocator = gb_arena_allocator(&i.stack_arena);
	i.heap_allocator  = heap_allocator();

	ssaProcedure *main_proc = vm_lookup_proc(&i, make_string("main"));
	if (main_proc != NULL) {
		vm_call(&i, NULL, main_proc, vm_empty_args);
		exit_code = 0;
	} else {
		gb_printf_err("No main procedure.");
		exit_code = 1;
	}

	return exit_code;
}

#endif
