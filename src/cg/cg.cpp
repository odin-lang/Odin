#include "cg.hpp"
#include "cg_worklist.cpp"


gb_internal void cg_opt(cgProcedure *p, cgWorklist *worklist, bool preserve_types) {
	if (worklist == nullptr) {
		return;
	}
}

gb_internal gb_inline cgNode *cg_peep(cgGraphBuilder *b, cgNode *n) {
	if (n == nullptr) {
		return nullptr;
	}
	return b->peep_callback(b->p, n);
}

gb_internal bool cg_can_gvn(cgNode *n) {
	if (n->kind == cgNode_Local) {
		return false;
	}

	switch (n->kind) {
	case cgNode_Local:
		return false;
	case cgNode_Region:
	case cgNode_If:
	case cgNode_DebugBreak:
	case cgNode_Trap:
	case cgNode_Unreachable:
	case cgNode_Call:
	case cgNode_Tailcall:
	case cgNode_Syscall:
	case cgNode_DebugLocation:
		return false;

	case cgNode_Blackhole:
		return false;
	}

	return true;
}

gb_internal CG_PEEP_PROC(cg_opt_gvn_node) {
	if (!cg_can_gvn(n)) {
		return n;
	}

	return n;
}

template <typename T>
gb_internal T *cg_alloc_node(cgProcedure *p, cgType type, isize input_count, isize input_capacity, Type *odin_type) {
	GB_ASSERT(input_count >= 0);
	GB_ASSERT(input_count < UINT16_MAX);
	if (input_capacity <= 0) {
		input_capacity = input_count;
	}
	GB_ASSERT(input_count <= input_capacity);
	GB_ASSERT(input_capacity <= UINT16_MAX);

	void *mem = arena_alloc(&p->arena, gb_size_of(T), gb_align_of(T));
	new(mem) T{};
	T *n = cast(T *)n;
	n->input_count = cast(u16)input_count;
	n->input_capacity = cast(u16)input_capacity;
	n->type = type;
	n->gvn = ++p->node_count;
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

template <typename T>
gb_internal T *cg_alloc_node_with_kind(cgProcedure *p, cgNodeKind kind, cgType type, isize input_count, isize input_capacity, Type *odin_type) {
	GB_ASSERT(input_count >= 0);
	GB_ASSERT(input_count < UINT16_MAX);
	if (input_capacity <= 0) {
		input_capacity = input_count;
	}
	GB_ASSERT(input_count <= input_capacity);
	GB_ASSERT(input_capacity <= UINT16_MAX);

	void *mem = arena_alloc(&p->arena, gb_size_of(T), gb_align_of(T));
	new(mem) T{kind};
	T *n = cast(T *)n;
	n->input_count = cast(u16)input_count;
	n->input_capacity = cast(u16)input_capacity;
	n->type = type;
	n->gvn = ++p->node_count;
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


gb_internal void cg_add_user(cgProcedure *p, cgNode *n, cgNode *in, u16 slot) {
	if (in->user_count >= in->user_capacity) { // resize
		isize new_capacity = 2 * cast(isize)in->user_capacity;
		if (new_capacity >= UINT16_MAX) {
			GB_ASSERT("TOO MANY USERS to one cgNode");
		}

		cgUser *users = arena_alloc_array<cgUser>(&p->arena, new_capacity);
		gb_memcopy(users, in->users, in->user_count * gb_size_of(cgUser));

		in->user_capacity = cast(u16)new_capacity;
		in->users = users;
	}

	in->users[in->user_count].node = n;
	in->users[in->user_count].slot = slot;

	in->user_count += 1;
}
gb_internal void cg_remove_user(cgProcedure *p, cgNode *n, u16 slot) {
	if (n->inputs[slot] == nullptr) {
		return;
	}

	cgNode *old = n->inputs[slot];
	cgUser *old_use = old->users;

	for (u16 i = 0; i < old->user_count; i++) {
		if (old_use[i].node == n && old_use[i].slot == slot) {
			old->user_count -= 1;
			old_use[i] = old_use[old->user_count];

			if (old->user_count == 0 && p->worklist) {
				cg_worklist_push(p->worklist, old);
			}

			return;
		}
	}

	GB_PANIC("failed to remove non-existent user %p from %p (slot %u)", old, n, slot);
}


gb_internal void cg_set_input(cgProcedure *p, cgNode *n, cgNode *in, u16 slot) {
	GB_ASSERT(slot < n->input_count);
	cg_remove_user(p, n, slot);
	n->inputs[slot] = in;
	if (in != nullptr) {
		cg_add_user(p, n, in, slot);
	}
}


gb_internal u32 cg_type_bit_size(cgModule *m, cgTypeKind kind) {
	switch (kind) {
	case cgType_void: return 0;
	case cgType_bool: return 1;
	case cgType_i8:   return 8;
	case cgType_i16:  return 16;
	case cgType_i32:  return 32;
	case cgType_i64:  return 64;
	case cgType_ptr:
		return cast(u32)build_context.metrics.ptr_size;

	case cgType_f16: return 16;
	case cgType_f32: return 32;
	case cgType_f64: return 64;

	case cgType_v64:  return 64;
	case cgType_v128: return 128;
	case cgType_v256: return 256;
	case cgType_v512: return 512;

	case cgType_control:
	case cgType_memory:
	case cgType_tuple:
		GB_ASSERT("Unknown bit size");
		return 0;
	}
}

gb_internal void cg_kill_node(cgProcedure *p, cgNode *n) {
	for (u16 i = 0; i < n->input_count; i++) {
		cg_remove_user(p, n, i);
		n->inputs[i] = nullptr;
	}
	n->input_count = 0;
	n->kind = cgNode_NULL;
}

gb_internal void cg_kill_violently(cgProcedure *p, cgNode *n) {
	// NOTE(bill): kill this node violently. It's not murder, luckily.

	for (u16 i = 0; i < n->input_count; i++) {
		cg_remove_user(p, n, i);
		n->inputs[i] = nullptr;
	}

	GB_ASSERT(n->user_count == 0);
	n->user_count    = 0;
	n->user_capacity = 0;
	n->users = nullptr;

	n->input_count = 0;
	n->kind = cgNode_NULL;
}



gb_internal cgGraphBuilder *cg_builder_enter(cgProcedure *p, Type *odin_signature, cgWorklist *wl) {
	p->worklist = wl;

	auto *b = arena_alloc_item<cgGraphBuilder>(&p->arena);
	b->p = p;
	b->arena = &p->temp_arena;

	b->peep_callback = cg_opt_gvn_node;

	return b;
}
gb_internal void cg_builder_exit(cgGraphBuilder *b) {
	if (b->curr) {
		cgNode *n = b->curr;
		b->curr = nullptr;
		cg_builder_label_kill(b, n);
	}

	if (b->start_symbol_table != b->curr) {
		cg_builder_label_kill(b, b->start_symbol_table);
	}

	cgProcedure *p = b->p;
	cgNode *ret = p->root_node->inputs[1];
	if (ret->kind == cgNode_Return &&
	    ret->inputs[0]->kind == cgNode_Region &&
	    ret->inputs[0]->input_count == 0) {
		cg_kill_node(p, ret->inputs[0]);

		GB_ASSERT(p->root_node->input_count > 0);
		u16 last = p->root_node->input_count-1;
		GB_ASSERT(last != 1);
		cgNode *last_n = p->root_node->inputs[last];

		cg_set_input(p, p->root_node, nullptr, last);
		cg_set_input(p, p->root_node, last_n, 1);
		p->root_node->input_count -= 1;

		cg_kill_node(p, ret);
	}

	arena_free_all(b->arena);

	if (p->worklist != nullptr) {
		cg_worklist_clear(p->worklist);
		cg_opt(p, p->worklist, false);
	}
}



gb_internal cgNode *cg_builder_bool(cgGraphBuilder *b, bool x) {
	auto *n = cg_alloc_node<cgNodeInt>(b->p, CG_TYPE_BOOL, 1);
	cg_set_input(b->p, n, b->p->root_node, 0);
	n->val = cast(u64)x;
	return cg_peep(b, n);
}
gb_internal cgNode *cg_builder_uint(cgGraphBuilder *b, cgType type, u64 x) {
	GB_ASSERT(type.is_int_or_ptr());

	u32 bits = cg_type_bit_size(b->p->module, type.kind);
	if (bits < 64) {
		u64 mask = (~cast(u64)0ull) >> (64 - bits);
		x &= mask;
	}

	auto *n = cg_alloc_node<cgNodeInt>(b->p, type, 1);
	cg_set_input(b->p, n, b->p->root_node, 0);
	n->val = cast(u64)x;
	return cg_peep(b, n);
}
gb_internal cgNode *cg_builder_int(cgGraphBuilder *b, cgType type, i64 x) {
	GB_ASSERT(type.is_int_or_ptr());
	auto *n = cg_alloc_node<cgNodeInt>(b->p, type, 1);
	cg_set_input(b->p, n, b->p->root_node, 0);
	n->val = cast(u64)x;
	return cg_peep(b, n);
}
gb_internal cgNode *cg_builder_f16(cgGraphBuilder *b, u16 x) {
	auto *n = cg_alloc_node<cgNodeF16>(b->p, CG_TYPE_F16, 1);
	cg_set_input(b->p, n, b->p->root_node, 0);
	n->val = x;
	return cg_peep(b, n);
}
gb_internal cgNode *cg_builder_f32(cgGraphBuilder *b, f32 x) {
	auto *n = cg_alloc_node<cgNodeF32>(b->p, CG_TYPE_F32, 1);
	cg_set_input(b->p, n, b->p->root_node, 0);
	n->val = x;
	return cg_peep(b, n);
}
gb_internal cgNode *cg_builder_f64(cgGraphBuilder *b, f64 x) {
	auto *n = cg_alloc_node<cgNodeF64>(b->p, CG_TYPE_F64, 1);
	cg_set_input(b->p, n, b->p->root_node, 0);
	n->val = x;
	return cg_peep(b, n);
}
gb_internal cgNode *cg_builder_symbol(cgGraphBuilder *b, cgSymbol *s) {
	auto *n = cg_alloc_node<cgNodeSymbol>(b->p, CG_TYPE_PTR, 1);
	cg_set_input(b->p, n, b->p->root_node, 0);
	n->symbol = s;
	return cg_peep(b, n);
}
gb_internal cgNode *cg_builder_string_ptr(cgGraphBuilder *b, String str) {
	GB_ASSERT(str.len >= 0);
	GB_PANIC("TODO(bill): cg_builder_string_ptr");
	return nullptr;
}

gb_internal u64 cg_const_sign_ext(cgModule *m, cgType type, u64 src) {
	u32 src_bits = cg_type_bit_size(m, type);
	u32 dst_bits = 64;
	if (src_bits == dst_bits) {
		return src;
	}

	u64 mask = ((u64)1ull)<<(src_bits-1);
	return (src ^ mask) - mask;
}


gb_internal cgNode *cg_builder_binary_op_int(cgGraphBuilder *b, cgNodeKind op, cgNode *x, cgNode *y) {
	return nullptr;
}
gb_internal cgNode *cg_builder_binary_op_float(cgGraphBuilder *b, cgNodeKind op, cgNode *x, cgNode *y) {
	return nullptr;
}

gb_internal cgNode *cg_builder_select(cgGraphBuilder *b, cgNode *cond, cgNode *x, cgNode *y) {
	GB_ASSERT(x->type == y->type);

	auto *n = cg_alloc_node<cgNodeSelect>(b->p, x->type, 4);
	cg_set_input(b->p, n, cond, 1);
	cg_set_input(b->p, n, x,    2);
	cg_set_input(b->p, n, y,    3);
	return cg_peep(b, n);
}
gb_internal cgNode *cg_builder_cast(cgGraphBuilder *b, cgType type, cgNodeKind op, cgNode *src) {
	GB_ASSERT(cgNode_Bitcast <= op && op <= cgNode_FloatToUint);

	if (src->kind == cgNode_Int) {
		auto *iconst = src->downcast<cgNodeInt>();
		if (op == cgNode_ZeroExt) {
			u32 bits = cg_type_bit_size(b->p->module, src->type.kind);
			u64 val = iconst->val;
			return cg_builder_uint(b, src->type, val & (~cast(u64)0) >> (64 - bits));
		} else if (op == cgNode_SignExt) {
			u64 val = iconst->val;
			val = cg_const_sign_ext(b->p->module, src->type, val);
			return cg_builder_uint(b, src->type, val);
		}
	}
	auto *n = cg_alloc_node_with_kind<cgNodeCast>(b->p, op, src->type, 2);
	cg_set_input(b->p, n, src, 1);
	return cg_peep(b, n);
}

gb_internal cgNode *cg_builder_unary(cgGraphBuilder *b, cgNodeKind op, cgNode *src) {
	GB_ASSERT(op == cgNode_FNeg);
	auto *n = cg_alloc_node_with_kind<cgNodeUnary>(b->p, op, src->type, 2);
	cg_set_input(b->p, n, src, 1);
	return cg_peep(b, n);
}
gb_internal cgNode *cg_builder_neg(cgGraphBuilder *b, cgNode *src) {
	if (src->type.is_float()) {
		return cg_builder_unary(b, cgNode_FNeg, src);
	} else {
		return cg_builder_binary_op_int(b, cgNode_Sub, cg_builder_int(b, src->type, 0), src);
	}
}
gb_internal cgNode *cg_builder_not(cgGraphBuilder *b, cgNode *src) {
	return cg_builder_binary_op_int(b, cgNode_Xor, src, cg_builder_int(b, src->type, -1));
}

gb_internal cgNode *cg_builder_cmp(cgGraphBuilder *b, cgNodeKind op, cgNode *x, cgNode *y) {
	GB_ASSERT(x->type == y->type);
	GB_ASSERT(cgNode_Cmp_EQ <= op && op <= cgNode_Cmp_FLE);


	return nullptr;
}

// base + index*stride
gb_internal cgNode *cg_builder_ptr_array(cgGraphBuilder *b, cgNode *base, cgNode *index, u64 stride) {
	GB_ASSERT(base->type.is_ptr());
	GB_ASSERT(index->type.is_int());
	if (stride == 0) {
		return base;
	}

	cgNode *selection = index;

	if (index->kind == cgNode_Int) {
		u64 offset = index->downcast<cgNodeInt>()->val * stride;
		if (base->kind == cgNode_PtrOffset && base->inputs[2]->kind == cgNode_Int) {
			offset += base->inputs[2]->downcast<cgNodeInt>()->val;
			base = base->inputs[1];
		}

		selection = cg_builder_uint(b, index->type, offset);
	} else if (stride != 1) {
		cgNode *s = cg_builder_int(b, CG_TYPE_I64, stride);
		selection = cg_builder_binary_op_int(b, cgNode_Mul, index, s);
	}

	auto *n = cg_alloc_node_with_kind<cgNode>(b->p, cgNode_PtrOffset, base->type, 3);
	cg_set_input(b->p, n, base,      1);
	cg_set_input(b->p, n, selection, 2);
	return cg_peep(b, n);
}
// base + offset
gb_internal cgNode *cg_builder_ptr_member(cgGraphBuilder *b, cgNode *base, i64 offset) {
	if (offset = 0) {
		return base;
	}
	if (base->kind == cgNode_PtrOffset && base->inputs[2]->kind == cgNode_Int) {
		offset += base->inputs[2]->downcast<cgNodeInt>()->val;
		base = base->inputs[1];
	}

	auto *selection = cg_builder_int(b, CG_TYPE_I64, offset);
	auto *n = cg_alloc_node_with_kind<cgNode>(b->p, cgNode_PtrOffset, base->type, 3);
	cg_set_input(b->p, n, base,      1);
	cg_set_input(b->p, n, selection, 1);
	return cg_peep(b, n);
}

gb_internal cgNode *cg_peek_mem(cgGraphBuilder *b, int mem_var) {
	return b->curr->inputs[2 + mem_var];
}

gb_internal cgNode *cg_transfer_mem(cgGraphBuilder *b, cgNode *n, int mem_var) {
	cgNode *old = b->curr->inputs[2 + mem_var];
	GB_ASSERT(old->type.kind == cgType_memory);
	cg_set_input(b->p, b->curr, n, cast(u16)(2 + mem_var));
	return old;
}

gb_internal cgNode *cg_transfer_ctrl(cgGraphBuilder *b, cgNode *n) {
	cgNode *old = b->curr->inputs[0];
	cg_set_input(b->p, b->curr, n, 0);
	return old;
}

gb_internal cgNode *cg_internal_make_proj(cgProcedure *p, cgType type, cgNode *src, i32 index) {
	GB_ASSERT(src->type.kind == cgType_tuple);
	auto *proj = cg_alloc_node<cgNodeProj>(p, type, 1);
	cg_set_input(p, proj, src, 0);
	proj->index = index;
	return proj;
}



gb_internal cgNode *cg_builder_load(cgGraphBuilder *b, int mem_var, bool ctrl_dep, cgType type, cgNode *addr, u32 align, bool is_volatile) {
	GB_ASSERT(addr->type.is_ptr());

	auto *n = cg_alloc_node_with_kind<cgNodeMemAccess>(b->p, cgNode_Load, type, 3);
	n->align = gb_max(align, 1);

	if (ctrl_dep) {
		cg_set_input(b->p, n, b->curr->inputs[0], 0);
	}
	cg_set_input(b->p, n, cg_peek_mem(b, mem_var), 1);
	cg_set_input(b->p, n, addr, 2);

	n = cg_peep(b, n)->downcast<cgNodeMemAccess>();

	if (is_volatile) {
		auto *barrier = cg_alloc_node_with_kind<cgNodeMemAccess>(b->p, cgNode_VolatileBarrier, CG_TYPE_MEMORY, 3);
		cg_set_input(b->p, barrier, b->curr->inputs[0],                   0);
		cg_set_input(b->p, barrier, cg_transfer_mem(b, barrier, mem_var), 1);
		cg_set_input(b->p, barrier, n,                                    2);
	}

	return n;
}
gb_internal cgNode *cg_builder_store(cgGraphBuilder *b, int mem_var, bool ctrl_dep, cgType type, cgNode *addr, cgNode *val, u32 align, bool is_volatile) {
	GB_ASSERT(addr->type.is_ptr());

	auto *n = cg_alloc_node_with_kind<cgNodeMemAccess>(b->p, cgNode_Store, CG_TYPE_MEMORY, 3);
	n->align = gb_max(align, 1);

	cg_set_input(b->p, n, b->curr->inputs[0], 0);
	cg_set_input(b->p, n, cg_transfer_mem(b, n, mem_var), 1);
	cg_set_input(b->p, n, addr, 2);
	cg_set_input(b->p, n, val, 3);

	if (is_volatile) {
		auto *barrier = cg_alloc_node_with_kind<cgNodeMemAccess>(b->p, cgNode_VolatileBarrier, CG_TYPE_MEMORY, 2);
		cg_set_input(b->p, barrier, b->curr->inputs[0],                   0);
		cg_set_input(b->p, barrier, cg_transfer_mem(b, barrier, mem_var), 1);
	}
	return n;
}
gb_internal cgNode *cg_builder_memcpy(cgGraphBuilder *b, int mem_var, bool ctrl_dep, cgType type, cgNode *dst, cgNode *src, cgNode *size, u32 align, bool is_volatile) {
	GB_ASSERT(dst->type.is_ptr());
	GB_ASSERT(src->type.is_ptr());

	auto *n = cg_alloc_node_with_kind<cgNodeMemAccess>(b->p, cgNode_Memcpy, CG_TYPE_MEMORY, 5);
	n->align = align;
	cg_set_input(b->p, n, b->curr->inputs[0],             0);
	cg_set_input(b->p, n, cg_transfer_mem(b, n, mem_var), 1);
	cg_set_input(b->p, n, dst,                            2);
	cg_set_input(b->p, n, src,                            3);
	cg_set_input(b->p, n, size,                           4);
	return n;
}
gb_internal cgNode *cg_builder_memmove(cgGraphBuilder *b, int mem_var, bool ctrl_dep, cgType type, cgNode *dst, cgNode *src, cgNode *size, u32 align, bool is_volatile) {
	GB_ASSERT(dst->type.is_ptr());
	GB_ASSERT(src->type.is_ptr());

	auto *n = cg_alloc_node_with_kind<cgNodeMemAccess>(b->p, cgNode_Memmove, CG_TYPE_MEMORY, 5);
	n->align = align;
	cg_set_input(b->p, n, b->curr->inputs[0],             0);
	cg_set_input(b->p, n, cg_transfer_mem(b, n, mem_var), 1);
	cg_set_input(b->p, n, dst,                            2);
	cg_set_input(b->p, n, src,                            3);
	cg_set_input(b->p, n, size,                           4);
	return n;
}
gb_internal cgNode *cg_builder_memzero(cgGraphBuilder *b, int mem_var, bool ctrl_dep, cgType type, cgNode *dst, cgNode *size, u32 align, bool is_volatile) {
	GB_ASSERT(dst->type.is_ptr());

	auto *n = cg_alloc_node_with_kind<cgNodeMemAccess>(b->p, cgNode_Memzero, CG_TYPE_MEMORY, 4);
	n->align = align;
	cg_set_input(b->p, n, b->curr->inputs[0],             0);
	cg_set_input(b->p, n, cg_transfer_mem(b, n, mem_var), 1);
	cg_set_input(b->p, n, dst,                            2);
	cg_set_input(b->p, n, size,                           3);
	return n;
}


gb_internal cgNode *cg_builder_local(cgGraphBuilder *b, u32 size, u32 align) {
	GB_ASSERT(align > 0);

	auto *n = cg_alloc_node<cgNodeLocal>(b->p, CG_TYPE_PTR, 1);
	n->size  = size;
	n->align = align;

	return n;
}
gb_internal cgNode *cg_builder_local_debug(cgGraphBuilder *b, String name, Type *odin_type) {
	GB_ASSERT(odin_type != nullptr);
	i64 size  = type_size_of(odin_type);
	i64 align = type_align_of(odin_type);
	GB_ASSERT(size  <= UINT32_MAX);
	GB_ASSERT(align <= UINT32_MAX);

	auto *n = cg_alloc_node<cgNodeLocal>(b->p, CG_TYPE_PTR, 1);
	n->size      = cast(u32)size;
	n->align     = cast(u32)align;
	n->name      = string_interner_insert(name);
	n->odin_type = alloc_type_pointer(odin_type);

	return n;
}

gb_internal cgNode *cg_builder_frame_ptr(cgGraphBuilder *b) {
	auto *n = cg_alloc_node_with_kind<cgNode>(b->p, cgNode_FramePtr, CG_TYPE_PTR, 1);
	cg_set_input(b->p, n, b->p->root_node, 0);
	return cg_peep(b, n);
}


gb_internal cgNode *cg_builder_label(cgGraphBuilder *b, cgNode *label, bool allow_backward_jumps) {
	if (label == nullptr) {
		GB_ASSERT(allow_backward_jumps == false);

		auto *r  = cg_alloc_node<cgNodeRegion>     (b->p, CG_TYPE_CONTROL, 0, 2);
		auto *st = cg_alloc_node<cgNodeSymbolTable>(b->p, CG_TYPE_VOID, b->curr->input_count);
		cg_set_input(b->p, st, r, 0);
		cg_set_input(b->p, st, r, 1);
		return st;
	}

	auto *r  = cg_alloc_node<cgNodeRegion>     (b->p, CG_TYPE_CONTROL, 0, 2);
	auto *st = cg_alloc_node<cgNodeSymbolTable>(b->p, CG_TYPE_VOID, label->input_count);
	cg_set_input(b->p, st, r, 0);
	cg_set_input(b->p, st, r, 1);

	if (allow_backward_jumps) {
		for (u16 i = 2; i < label->input_count; i++) {
			auto *n = cg_alloc_node<cgNodePhi>(b->p, label->inputs[i]->type, 1, 3);
			cg_set_input(b->p, n, r, 0);
			cg_set_input(b->p, st, n, i);
		}
		st->complete = true;
	}
	return st;
}

gb_internal cgNode *cg_phi_identity(cgProcedure *p, cgNode *n) {
	GB_PANIC("TODO(bill): cg_phi_identity");
	return nullptr;
}

gb_internal cgNode *cg_subsume_node(cgProcedure *p, cgNode *old_n, cgNode *new_n) {
	GB_PANIC("TODO(bill): cg_subsume_node");
	return nullptr;
}

gb_internal void cg_builder_label_complete(cgGraphBuilder *b, cgNode *label) {
	cgProcedure *p = b->p;
	GB_ASSERT(label->kind == cgNode_SymbolTable);
	auto *st = label->downcast<cgNodeSymbolTable>();
	if (st->complete) {
		return;
	}

	st->complete = true;

	cgNode *top_ctrl = label->inputs[1];

	if (top_ctrl->kind == cgNode_Region) {
		for (u16 i = 0; i < top_ctrl->user_count; i++) {
			cgUser *u = &top_ctrl->users[i];
			if (u->node->kind == cgNode_Phi) {
				GB_ASSERT(u->slot == 0);
				cgNode *k = cg_phi_identity(p, u->node);
				if (k != u->node) {
					cg_subsume_node(p, u->node, k);
				}
			}
		}
	}

	if (top_ctrl->input_count != 0) {
		for (u16 i = 2; i < label->input_count; i++) {
			cg_peep(b, label->inputs[i]); // nullptr will be skipped
		}
	}
}


gb_internal void cg_builder_label_kill(cgGraphBuilder *b, cgNode *label) {
	if (label->kind != cgNode_NULL) {
		GB_ASSERT(label->kind == cgNode_SymbolTable);
		GB_ASSERT_MSG(label != b->curr, "Cannot kill the label that is being currently used");
		cg_kill_violently(b->p, label);
	}
}

gb_internal cgNode *cg_builder_if(cgGraphBuilder *b, cgNode *cond, cgNode *paths[2]) {
	cgProcedure *p = b->p;
	auto *n = cg_alloc_node<cgNodeIf>(p, CG_TYPE_TUPLE, 2);
	n->prob = 0.5f;
	cg_set_input(p, n, cg_transfer_ctrl(b, n), 0);
	cg_set_input(p, n, cond, 1);

	cgNode *cproj[2];
	cproj[0] = cg_internal_make_proj(p, CG_TYPE_CONTROL, n, 0);
	cproj[1] = cg_internal_make_proj(p, CG_TYPE_CONTROL, n, 1);

	cgNode *curr = b->curr;
	b->curr = nullptr;

	for (isize i = 0; i < 2; i++) {
		auto *st = cg_alloc_node<cgNodeSymbolTable>(p, CG_TYPE_VOID, curr->input_count);
		cg_set_input(p, st, cproj[i], 0);
		cg_set_input(p, st, cproj[i], 1);
		st->complete = true;

		for (u16 j = 2; j < curr->input_count; j++) {
			cg_set_input(p, st, curr->inputs[j], j);
		}

		paths[i] = st;
	}
	return n;
}
gb_internal void cg_builder_jump(cgGraphBuilder *b, cgNode *target) {
	auto *st = b->curr->downcast<cgNodeSymbolTable>();
	if (st == nullptr) {
		return;
	}
	GB_PANIC("TODO(bill): cg_builder_jump");

	return;
}
gb_internal cgNode *cg_builder_loop(cgGraphBuilder *b) {
	GB_PANIC("TODO(bill): cg_builder_loop");
	return nullptr;
}
gb_internal cgNode *cg_builder_phi(cgGraphBuilder *b, Slice<cgNode *> vals) {
	GB_PANIC("TODO(bill): cg_builder_phi");
	return nullptr;
}

gb_internal cgNode *cg_builder_switch(cgGraphBuilder *b, cgNode *cond) {
	GB_PANIC("TODO(bill): cg_builder_switch");
	return nullptr;
}
gb_internal cgNode *cg_builder_case_default(cgGraphBuilder *b, cgNode *br_syms) {
	GB_PANIC("TODO(bill): cg_builder_case_default");
	return nullptr;
}
gb_internal cgNode *cg_builder_case_key(cgGraphBuilder *b, cgNode *br_syms, u64 key) {
	GB_PANIC("TODO(bill): cg_builder_case_key");
	return nullptr;
}

gb_internal void cg_add_input_late(cgProcedure *p, cgNode *n, cgNode *in) {
	GB_PANIC("TODO(bill): cg_add_input_late");
}


gb_internal void cg_builder_ret(cgGraphBuilder *b, int mem_var, Slice<cgNode *> args) {
	GB_PANIC("TODO(bill): cg_builder_ret");
	return;
}
gb_internal void cg_builder_unreachable(cgGraphBuilder *b, int mem_var) {
	auto *n = cg_alloc_node_with_kind<cgNode>(b->p, cgNode_Unreachable, CG_TYPE_CONTROL, 2);
	cg_set_input(b->p, n, cg_transfer_ctrl(b, n), 0);
	cg_set_input(b->p, n, cg_peek_mem(b, mem_var), 1);
	cg_add_input_late(b->p, b->p->root_node, n);
	b->curr = nullptr;
}
gb_internal void cg_builder_trap(cgGraphBuilder *b, int mem_var) {
	auto *n = cg_alloc_node_with_kind<cgNode>(b->p, cgNode_Trap, CG_TYPE_CONTROL, 2);
	cg_set_input(b->p, n, cg_transfer_ctrl(b, n), 0);
	cg_set_input(b->p, n, cg_peek_mem(b, mem_var), 1);
	cg_add_input_late(b->p, b->p->root_node, n);
	b->curr = nullptr;
}
gb_internal void cg_builder_debug_break(cgGraphBuilder *b, int mem_var) {
	auto *n = cg_alloc_node_with_kind<cgNode>(b->p, cgNode_DebugBreak, CG_TYPE_CONTROL, 2);
	cg_set_input(b->p, n, cg_transfer_ctrl(b, n), 0);
	cg_set_input(b->p, n, cg_peek_mem(b, mem_var), 1);
}

gb_internal void cg_builder_black_hole(cgGraphBuilder *b, Slice<cgNode *> args) {
	GB_PANIC("TODO(bill): cg_builder_black_hole");
	return;
}

gb_internal cgNode *cg_builder_call(cgGraphBuilder *b, Type *odin_signature, int mem_var, cgNode *target, Slice<cgNode *> args) {
	GB_PANIC("TODO(bill): cg_builder_call");
	return nullptr;
}
gb_internal cgNode *cg_builder_syscall(cgGraphBuilder *b, cgType dt, int mem_var, cgNode *target, Slice<cgNode *> args) {
	GB_PANIC("TODO(bill): cg_builder_syscall");
	return nullptr;
}

gb_internal cgNode *cg_builder_atomic_rmw(cgGraphBuilder *b, int mem_var, int op, cgNode *addr, cgNode *val, cgMemoryOrder order) {
	GB_PANIC("TODO(bill): cg_builder_atomic_rmw");
	return nullptr;
}
gb_internal cgNode *cg_builder_atomic_load(cgGraphBuilder *b, int mem_var, cgType type, cgNode *addr, cgMemoryOrder order) {
	GB_PANIC("TODO(bill): cg_builder_atomic_load");
	return nullptr;
}

gb_internal bool cg_node_is_constant_zero(cgGraphBuilder *b, cgNode *n) {
	GB_PANIC("TODO(bill): cg_node_is_constant_zero");
	return nullptr;
}
