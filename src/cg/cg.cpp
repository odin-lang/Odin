#include "cg.hpp"


template <typename T>
gb_internal T *cg_alloc_node(cgProcedure *p, cgType type, isize input_count, isize input_capacity, Type *odin_type) {
	GB_ASSERT(input_count >= 0);
	GB_ASSERT(input_count < UINT16_MAX);
	GB_ASSERT(input_count <= input_capacity);
	void *mem = arena_alloc(&p->arena, gb_size_of(T), gb_align_of(T));
	new(mem) T{};
	T *n = cast(T *)n;
	n->input_count = input_count;
	n->input_capacity = input_capacity;
	n->type = type;
	n->gvn = p->node_count++;
	n->odin_type = odin_type;

	if (n->input_capacity > 0) {
		n->inputs = arena_alloc_array<cgNode *>(&p->arena, n->input_capacity);
	} else {
		n->inputs = nullptr;
	}

	n->user_count    = 0;
	n->user_capacity = 4;
	n->users = arena_alloc_array<cgUser>(&p->arena, n->user_capacity);

	return n;
}


gb_internal cgGraphBuilder *cg_builder_enter(cgProcedure *p, Type *odin_signature) {
	return nullptr;
}
gb_internal void cg_builder_exit(cgGraphBuilder *b) {
	return;
}


gb_internal cgNode *cg_builder_bool(cgGraphBuilder *b, bool x) {
	return nullptr;
}
gb_internal cgNode *cg_builder_uint(cgGraphBuilder *b, cgType type, u64 x) {
	return nullptr;
}
gb_internal cgNode *cg_builder_int (cgGraphBuilder *b, cgType type, i64 x) {
	return nullptr;
}
gb_internal cgNode *cg_builder_f16(cgGraphBuilder *b, u16 x) {
	return nullptr;
}
gb_internal cgNode *cg_builder_f32(cgGraphBuilder *b, f32 x) {
	return nullptr;
}
gb_internal cgNode *cg_builder_f64(cgGraphBuilder *b, f64 x) {
	return nullptr;
}
gb_internal cgNode *cg_builder_symbol(cgGraphBuilder *b, cgSymbol *s) {
	return nullptr;
}
gb_internal cgNode *cg_builder_string_ptr(cgGraphBuilder *b, String str) {
	return nullptr;
}


gb_internal cgNode *cg_builder_binary_op_int(cgGraphBuilder *b, cgBinaryOpInt op, cgNode *x, cgNode *y) {
	return nullptr;
}
gb_internal cgNode *cg_builder_binary_op_float(cgGraphBuilder *b, cgBinaryOpInt op, cgNode *x, cgNode *y) {
	return nullptr;
}

gb_internal cgNode *cg_builder_select(cgGraphBuilder *b, cgNode *cond, cgNode *x, cgNode *y) {
	return nullptr;
}
gb_internal cgNode *cg_builder_cast(cgGraphBuilder *b, cgType type, cgCastOp op, cgNode *src) {
	return nullptr;
}

gb_internal cgNode *cg_builder_unary(cgGraphBuilder *b, cgUnaryOp op, cgNode *src) {
	return nullptr;
}
gb_internal cgNode *cg_builder_neg(cgGraphBuilder *b, cgNode *src) {
	return nullptr;
}
gb_internal cgNode *cg_builder_not(cgGraphBuilder *b, cgNode *src) {
	return nullptr;
}

gb_internal cgNode *cg_builder_cmp(cgGraphBuilder *b, cgCompareOp op, cgNode *x, cgNode *y) {
	return nullptr;
}

// base + index*stride
gb_internal cgNode *cg_builder_ptr_array(cgGraphBuilder *b, cgNode *base, cgNode *index, i64 stride) {
	return nullptr;
}
// base + offset
gb_internal cgNode *cg_builder_ptr_member(cgGraphBuilder *b, cgNode *base, i64 offset) {
	return nullptr;
}


gb_internal cgNode *cg_builder_load(cgGraphBuilder *b, int mem_var, bool ctrl_dep, cgType type, cgNode *addr, u32 align, bool is_volatile) {
	return nullptr;
}
gb_internal cgNode *cg_builder_store(cgGraphBuilder *b, int mem_var, bool ctrl_dep, cgType type, cgNode *addr, cgNode *val, u32 align, bool is_volatile) {
	return nullptr;
}
gb_internal cgNode *cg_builder_memcpy(cgGraphBuilder *b, int mem_var, bool ctrl_dep, cgType type, cgNode *dst, cgNode *src, cgNode *size, u32 align, bool is_volatile) {
	return nullptr;
}
gb_internal cgNode *cg_builder_memmove(cgGraphBuilder *b, int mem_var, bool ctrl_dep, cgType type, cgNode *dst, cgNode *src, cgNode *size, u32 align, bool is_volatile) {
	return nullptr;
}
gb_internal cgNode *cg_builder_memzero(cgGraphBuilder *b, int mem_var, bool ctrl_dep, cgType type, cgNode *dst, cgNode *size, u32 align, bool is_volatile) {
	return nullptr;
}


gb_internal cgNode *cg_builder_local(cgGraphBuilder *b, u32 size, u32 align) {
	return nullptr;
}
gb_internal cgNode *cg_builder_local_debug(cgGraphBuilder *b, cgNode *n, String name, Type *odin_type) {
	return nullptr;
}

gb_internal cgNode *cg_builder_frame_ptr(cgGraphBuilder *b) {
	return nullptr;
}


gb_internal cgNode *cg_builder_label(cgGraphBuilder *b, cgNode *label, bool allow_backward_jumps) {
	return nullptr;
}
gb_internal cgNode *cg_builder_label_complete(cgGraphBuilder *b, cgNode *label) {
	return nullptr;
}

gb_internal void cg_builder_label_kill(cgGraphBuilder *b, cgNode *label) {
	return;
}

gb_internal cgNode *cg_builder_if(cgGraphBuilder *b, cgNode *cond, cgNode *x, cgNode *y) {
	return nullptr;
}
gb_internal void cg_builder_jump(cgGraphBuilder *b, cgNode *target) {
	return;
}
gb_internal cgNode *cg_builder_loop(cgGraphBuilder *b) {
	return nullptr;
}
gb_internal cgNode *cg_builder_phi(cgGraphBuilder *b, Slice<cgNode *> vals) {
	return nullptr;
}

gb_internal cgNode *cg_builder_switch(cgGraphBuilder *b, cgNode *cond) {
	return nullptr;
}
gb_internal cgNode *cg_builder_case_default(cgGraphBuilder *b, cgNode *br_syms) {
	return nullptr;
}
gb_internal cgNode *cg_builder_case_key(cgGraphBuilder *b, cgNode *br_syms, u64 key) {
	return nullptr;
}


gb_internal void cg_builder_ret(cgGraphBuilder *b, int mem_var, Slice<cgNode *> args) {
	return;
}
gb_internal void cg_builder_unreachable(cgGraphBuilder *b, int mem_var) {
	return;
}
gb_internal void cg_builder_trap(cgGraphBuilder *b, int mem_var) {
	return;
}
gb_internal void cg_builder_debug_trap(cgGraphBuilder *b, int mem_var) {
	return;
}
gb_internal void cg_builder_black_hole(cgGraphBuilder *b, Slice<cgNode *> args) {
	return;
}

gb_internal cgNode *cg_builder_call(cgGraphBuilder *b, Type *odin_signature, int mem_var, cgNode *target, Slice<cgNode *> args) {
	return nullptr;
}
gb_internal cgNode *cg_builder_syscall(cgGraphBuilder *b, cgType dt, int mem_var, cgNode *target, Slice<cgNode *> args) {
	return nullptr;
}

gb_internal cgNode *cg_builder_atomic_rmw(cgGraphBuilder *b, int mem_var, int op, cgNode *addr, cgNode *val, cgMemoryOrder order) {
	return nullptr;
}
gb_internal cgNode *cg_builder_atomic_load(cgGraphBuilder *b, int mem_var, cgType type, cgNode *addr, cgMemoryOrder order) {
	return nullptr;
}

gb_internal bool cg_node_is_constant_zero(cgGraphBuilder *b, cgNode *n) {
	return nullptr;
}
