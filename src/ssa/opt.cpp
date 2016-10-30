// Optimizations for the SSA code

void ssa_opt_add_operands(Array<ssaValue *> *ops, ssaInstr *i) {
	switch (i->kind) {
	case ssaInstr_Comment:
		break;
	case ssaInstr_Local:
		break;
	case ssaInstr_ZeroInit:
		array_add(ops, i->ZeroInit.address);
		break;
	case ssaInstr_Store:
		array_add(ops, i->Store.address);
		array_add(ops, i->Store.value);
		break;
	case ssaInstr_Load:
		array_add(ops, i->Load.address);
		break;
	case ssaInstr_ArrayElementPtr:
		array_add(ops, i->ArrayElementPtr.address);
		array_add(ops, i->ArrayElementPtr.elem_index);
		break;
	case ssaInstr_StructElementPtr:
		array_add(ops, i->StructElementPtr.address);
		break;
	case ssaInstr_PtrOffset:
		array_add(ops, i->PtrOffset.address);
		array_add(ops, i->PtrOffset.offset);
		break;
	case ssaInstr_ArrayExtractValue:
		array_add(ops, i->ArrayExtractValue.address);
		break;
	case ssaInstr_StructExtractValue:
		array_add(ops, i->StructExtractValue.address);
		break;
	case ssaInstr_Conv:
		array_add(ops, i->Conv.value);
		break;
	case ssaInstr_Jump:
		break;
	case ssaInstr_If:
		array_add(ops, i->If.cond);
		break;
	case ssaInstr_Return:
		if (i->Return.value != NULL) {
			array_add(ops, i->Return.value);
		}
		break;
	case ssaInstr_Select:
		array_add(ops, i->Select.cond);
		break;
	case ssaInstr_Phi:
		for_array(j, i->Phi.edges) {
			array_add(ops, i->Phi.edges[j]);
		}
		break;
	case ssaInstr_Unreachable: break;
	case ssaInstr_BinaryOp:
		array_add(ops, i->BinaryOp.left);
		array_add(ops, i->BinaryOp.right);
		break;
	case ssaInstr_Call:
		array_add(ops, i->Call.value);
		for (isize j = 0; j < i->Call.arg_count; j++) {
			array_add(ops, i->Call.args[j]);
		}
		break;
	case ssaInstr_VectorExtractElement:
		array_add(ops, i->VectorExtractElement.vector);
		array_add(ops, i->VectorExtractElement.index);
		break;
	case ssaInstr_VectorInsertElement:
		array_add(ops, i->VectorInsertElement.vector);
		array_add(ops, i->VectorInsertElement.elem);
		array_add(ops, i->VectorInsertElement.index);
		break;
	case ssaInstr_VectorShuffle:
		array_add(ops, i->VectorShuffle.vector);
		break;
	case ssaInstr_StartupRuntime:
		break;
	}
}





void ssa_block_replace_pred(ssaBlock *b, ssaBlock *from, ssaBlock *to) {
	for_array(i, b->preds) {
		ssaBlock *pred = b->preds[i];
		if (pred == from) {
			b->preds[i] = to;
		}
	}
}

void ssa_block_replace_succ(ssaBlock *b, ssaBlock *from, ssaBlock *to) {
	for_array(i, b->succs) {
		ssaBlock *succ = b->succs[i];
		if (succ == from) {
			b->succs[i] = to;
		}
	}
}

b32 ssa_block_has_phi(ssaBlock *b) {
	return b->instrs[0]->Instr.kind == ssaInstr_Phi;
}










Array<ssaValue *> ssa_get_block_phi_nodes(ssaBlock *b) {
	Array<ssaValue *> phis = {};
	for_array(i, b->instrs) {
		ssaInstr *instr = &b->instrs[i]->Instr;
		if (instr->kind != ssaInstr_Phi) {
			phis = b->instrs;
			phis.count = i;
			return phis;
		}
	}
	return phis;
}

void ssa_remove_pred(ssaBlock *b, ssaBlock *p) {
	auto phis = ssa_get_block_phi_nodes(b);
	isize i = 0;
	for_array(j, b->preds) {
		ssaBlock *pred = b->preds[j];
		if (pred != p) {
			b->preds[i] = b->preds[j];
			for_array(k, phis) {
				auto *phi = &phis[k]->Instr.Phi;
				phi->edges[i] = phi->edges[j];
			}
			i++;
		}
	}
	b->preds.count = i;
	for_array(k, phis) {
		auto *phi = &phis[k]->Instr.Phi;
		phi->edges.count = i;
	}

}

void ssa_remove_dead_blocks(ssaProcedure *proc) {
	isize j = 0;
	for_array(i, proc->blocks) {
		ssaBlock *b = proc->blocks[i];
		if (b == NULL) {
			continue;
		}
		// NOTE(bill): Swap order
		b->index = j;
		proc->blocks[j++] = b;
	}
	proc->blocks.count = j;
}

void ssa_mark_reachable(ssaBlock *b) {
	isize const WHITE =  0;
	isize const BLACK = -1;
	b->index = BLACK;
	for_array(i, b->succs) {
		ssaBlock *succ = b->succs[i];
		if (succ->index == WHITE) {
			ssa_mark_reachable(succ);
		}
	}
}

void ssa_remove_unreachable_blocks(ssaProcedure *proc) {
	isize const WHITE =  0;
	isize const BLACK = -1;
	for_array(i, proc->blocks) {
		proc->blocks[i]->index = WHITE;
	}

	ssa_mark_reachable(proc->blocks[0]);

	for_array(i, proc->blocks) {
		ssaBlock *b = proc->blocks[i];
		if (b->index == WHITE) {
			for_array(j, b->succs) {
				ssaBlock *c = b->succs[j];
				if (c->index == BLACK) {
					ssa_remove_pred(c, b);
				}
			}
			// NOTE(bill): Mark as empty but don't actually free it
			// As it's been allocated with an arena
			proc->blocks[i] = NULL;
		}
	}
	ssa_remove_dead_blocks(proc);
}

b32 ssa_opt_block_fusion(ssaProcedure *proc, ssaBlock *a) {
	if (a->succs.count != 1) {
		return false;
	}
	ssaBlock *b = a->succs[0];
	if (b->preds.count != 1) {
		return false;
	}

	if (ssa_block_has_phi(b)) {
		return false;
	}

	array_pop(&a->instrs); // Remove branch at end
	for_array(i, b->instrs) {
		array_add(&a->instrs, b->instrs[i]);
		ssa_set_instr_parent(b->instrs[i], a);
	}

	array_clear(&a->succs);
	for_array(i, b->succs) {
		array_add(&a->succs, b->succs[i]);
	}

	// Fix preds links
	for_array(i, b->succs) {
		ssa_block_replace_pred(b->succs[i], b, a);
	}

	proc->blocks[b->index] = NULL;
	return true;
}

void ssa_opt_blocks(ssaProcedure *proc) {
	ssa_remove_unreachable_blocks(proc);

#if 1
	b32 changed = true;
	while (changed) {
		changed = false;
		for_array(i, proc->blocks) {
			ssaBlock *b = proc->blocks[i];
			if (b == NULL) {
				continue;
			}
			GB_ASSERT(b->index == i);

			if (ssa_opt_block_fusion(proc, b)) {
				changed = true;
			}
			// TODO(bill): other simple block optimizations
		}
	}
#endif

	ssa_remove_dead_blocks(proc);
}
void ssa_opt_build_referrers(ssaProcedure *proc) {
	gbTempArenaMemory tmp = gb_temp_arena_memory_begin(&proc->module->tmp_arena);
	defer (gb_temp_arena_memory_end(tmp));

	Array<ssaValue *> ops = {}; // NOTE(bill): Act as a buffer
	array_init(&ops, proc->module->tmp_allocator, 64); // HACK(bill): This _could_ overflow the temp arena
	for_array(i, proc->blocks) {
		ssaBlock *b = proc->blocks[i];
		for_array(j, b->instrs) {
			ssaValue *instr = b->instrs[j];
			array_clear(&ops);
			ssa_opt_add_operands(&ops, &instr->Instr);
			for_array(k, ops) {
				ssaValue *op = ops[k];
				if (op == NULL) {
					continue;
				}
				auto *refs = ssa_value_referrers(op);
				if (refs != NULL) {
					array_add(refs, instr);
				}
			}
		}
	}
}







// State of Lengauer-Tarjan algorithm
// Based on this paper: http://jgaa.info/accepted/2006/GeorgiadisTarjanWerneck2006.10.1.pdf
struct ssaLTState {
	isize count;
	// NOTE(bill): These are arrays
	ssaBlock **sdom;     // Semidominator
	ssaBlock **parent;   // Parent in DFS traversal of CFG
	ssaBlock **ancestor;
};

// §2.2 - bottom of page
void ssa_lt_link(ssaLTState *lt, ssaBlock *p, ssaBlock *q) {
	lt->ancestor[q->index] = p;
}

i32 ssa_lt_depth_first_search(ssaLTState *lt, ssaBlock *p, i32 i, ssaBlock **preorder) {
	preorder[i] = p;
	p->dom.pre = i++;
	lt->sdom[p->index] = p;
	ssa_lt_link(lt, NULL, p);
	for_array(index, p->succs) {
		ssaBlock *q = p->succs[index];
		if (lt->sdom[q->index] == NULL) {
			lt->parent[q->index] = p;
			i = ssa_lt_depth_first_search(lt, q, i, preorder);
		}
	}
	return i;
}

ssaBlock *ssa_lt_eval(ssaLTState *lt, ssaBlock *v) {
	ssaBlock *u = v;
	for (;
	     lt->ancestor[v->index] != NULL;
	     v = lt->ancestor[v->index]) {
		if (lt->sdom[v->index]->dom.pre < lt->sdom[u->index]->dom.pre) {
			u = v;
		}
	}
	return u;
}

void ssa_number_dom_tree(ssaBlock *v, i32 pre, i32 post, i32 *pre_out, i32 *post_out) {
	v->dom.pre = pre++;
	for_array(i, v->dom.children) {
		ssaBlock *child = v->dom.children[i];
		i32 new_pre = 0, new_post = 0;
		ssa_number_dom_tree(child, pre, post, &new_pre, &new_post);
		pre = new_pre;
		post = new_post;
	}
	v->dom.post = post++;
	*pre_out  = pre;
	*post_out = post;
}


// NOTE(bill): Requires `ssa_opt_blocks` to be called before this
void ssa_opt_build_dom_tree(ssaProcedure *proc) {
	// Based on this paper: http://jgaa.info/accepted/2006/GeorgiadisTarjanWerneck2006.10.1.pdf

	gbTempArenaMemory tmp = gb_temp_arena_memory_begin(&proc->module->tmp_arena);
	defer (gb_temp_arena_memory_end(tmp));

	isize n = proc->blocks.count;
	ssaBlock **buf = gb_alloc_array(proc->module->tmp_allocator, ssaBlock *, 5*n);

	ssaLTState lt = {};
	lt.count    = n;
	lt.sdom     = &buf[0*n];
	lt.parent   = &buf[1*n];
	lt.ancestor = &buf[2*n];

	ssaBlock **preorder = &buf[3*n];
	ssaBlock **buckets  = &buf[4*n];
	ssaBlock *root = proc->blocks[0];

	// Step 1 - number vertices
	i32 pre_num = ssa_lt_depth_first_search(&lt, root, 0, preorder);
	gb_memmove(buckets, preorder, n*gb_size_of(preorder[0]));

	for (i32 i = n-1; i > 0; i--) {
		ssaBlock *w = preorder[i];

		// Step 3 - Implicitly define idom for nodes
		for (ssaBlock *v = buckets[i]; v != w; v = buckets[v->dom.pre]) {
			ssaBlock *u = ssa_lt_eval(&lt, v);
			if (lt.sdom[u->index]->dom.pre < i) {
				v->dom.idom = u;
			} else {
				v->dom.idom = w;
			}
		}

		// Step 2 - Compute all sdoms
		lt.sdom[w->index] = lt.parent[w->index];
		for_array(pred_index, w->preds) {
			ssaBlock *v = w->preds[pred_index];
			ssaBlock *u = ssa_lt_eval(&lt, v);
			if (lt.sdom[u->index]->dom.pre < lt.sdom[w->index]->dom.pre) {
				lt.sdom[w->index] = lt.sdom[u->index];
			}
		}

		ssa_lt_link(&lt, lt.parent[w->index], w);

		if (lt.parent[w->index] == lt.sdom[w->index]) {
			w->dom.idom = lt.parent[w->index];
		} else {
			buckets[i] = buckets[lt.sdom[w->index]->dom.pre];
			buckets[lt.sdom[w->index]->dom.pre] = w;
		}
	}

	// The rest of Step 3
	for (ssaBlock *v = buckets[0]; v != root; v = buckets[v->dom.pre]) {
		v->dom.idom = root;
	}

	// Step 4 - Explicitly define idom for nodes (in preorder)
	for (isize i = 1; i < n; i++) {
		ssaBlock *w = preorder[i];
		if (w == root) {
			w->dom.idom = NULL;
		} else {
			// Weird tree relationships here!

			if (w->dom.idom != lt.sdom[w->index]) {
				w->dom.idom = w->dom.idom->dom.idom;
			}

			// Calculate children relation as inverse of idom
			auto *children = &w->dom.idom->dom.children;
			if (children->data == NULL) {
				// TODO(bill): Is this good enough for memory allocations?
				array_init(children, heap_allocator());
			}
			array_add(children, w);
		}
	}

	i32 pre = 0;
	i32 pos = 0;
	ssa_number_dom_tree(root, 0, 0, &pre, &pos);
}

void ssa_opt_mem2reg(ssaProcedure *proc) {
	// TODO(bill): ssa_opt_mem2reg
}


void ssa_opt_proc(ssaProcedure *proc) {
	ssa_opt_blocks(proc);
#if 1
	ssa_opt_build_referrers(proc);
	ssa_opt_build_dom_tree(proc);

	// TODO(bill): ssa optimization
	// [ ] cse (common-subexpression) elim
	// [ ] copy elim
	// [ ] dead code elim
	// [ ] dead store/load elim
	// [ ] phi elim
	// [ ] short circuit elim
	// [ ] bounds check elim
	// [ ] lift/mem2reg
	// [ ] lift/mem2reg

	ssa_opt_mem2reg(proc);
#endif
}
