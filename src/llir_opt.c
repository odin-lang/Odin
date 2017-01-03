// Optimizations for the LLIR code

void llir_opt_add_operands(llirValueArray *ops, llirInstr *i) {
	switch (i->kind) {
	case llirInstr_Comment:
		break;
	case llirInstr_Local:
		break;
	case llirInstr_ZeroInit:
		array_add(ops, i->ZeroInit.address);
		break;
	case llirInstr_Store:
		array_add(ops, i->Store.address);
		array_add(ops, i->Store.value);
		break;
	case llirInstr_Load:
		array_add(ops, i->Load.address);
		break;
	case llirInstr_ArrayElementPtr:
		array_add(ops, i->ArrayElementPtr.address);
		array_add(ops, i->ArrayElementPtr.elem_index);
		break;
	case llirInstr_StructElementPtr:
		array_add(ops, i->StructElementPtr.address);
		break;
	case llirInstr_PtrOffset:
		array_add(ops, i->PtrOffset.address);
		array_add(ops, i->PtrOffset.offset);
		break;
	case llirInstr_ArrayExtractValue:
		array_add(ops, i->ArrayExtractValue.address);
		break;
	case llirInstr_StructExtractValue:
		array_add(ops, i->StructExtractValue.address);
		break;
	case llirInstr_Conv:
		array_add(ops, i->Conv.value);
		break;
	case llirInstr_Jump:
		break;
	case llirInstr_If:
		array_add(ops, i->If.cond);
		break;
	case llirInstr_Return:
		if (i->Return.value != NULL) {
			array_add(ops, i->Return.value);
		}
		break;
	case llirInstr_Select:
		array_add(ops, i->Select.cond);
		break;
	case llirInstr_Phi:
		for_array(j, i->Phi.edges) {
			array_add(ops, i->Phi.edges.e[j]);
		}
		break;
	case llirInstr_Unreachable:
		break;
	case llirInstr_UnaryOp:
		array_add(ops, i->UnaryOp.expr);
		break;
	case llirInstr_BinaryOp:
		array_add(ops, i->BinaryOp.left);
		array_add(ops, i->BinaryOp.right);
		break;
	case llirInstr_Call:
		array_add(ops, i->Call.value);
		for (isize j = 0; j < i->Call.arg_count; j++) {
			array_add(ops, i->Call.args[j]);
		}
		break;
	case llirInstr_VectorExtractElement:
		array_add(ops, i->VectorExtractElement.vector);
		array_add(ops, i->VectorExtractElement.index);
		break;
	case llirInstr_VectorInsertElement:
		array_add(ops, i->VectorInsertElement.vector);
		array_add(ops, i->VectorInsertElement.elem);
		array_add(ops, i->VectorInsertElement.index);
		break;
	case llirInstr_VectorShuffle:
		array_add(ops, i->VectorShuffle.vector);
		break;
	case llirInstr_StartupRuntime:
		break;
	case llirInstr_BoundsCheck:
		array_add(ops, i->BoundsCheck.index);
		array_add(ops, i->BoundsCheck.len);
		break;
	case llirInstr_SliceBoundsCheck:
		array_add(ops, i->SliceBoundsCheck.low);
		array_add(ops, i->SliceBoundsCheck.high);
		break;
	}
}





void llir_opt_block_replace_pred(llirBlock *b, llirBlock *from, llirBlock *to) {
	for_array(i, b->preds) {
		llirBlock *pred = b->preds.e[i];
		if (pred == from) {
			b->preds.e[i] = to;
		}
	}
}

void llir_opt_block_replace_succ(llirBlock *b, llirBlock *from, llirBlock *to) {
	for_array(i, b->succs) {
		llirBlock *succ = b->succs.e[i];
		if (succ == from) {
			b->succs.e[i] = to;
		}
	}
}

bool llir_opt_block_has_phi(llirBlock *b) {
	return b->instrs.e[0]->Instr.kind == llirInstr_Phi;
}










llirValueArray llir_get_block_phi_nodes(llirBlock *b) {
	llirValueArray phis = {0};
	for_array(i, b->instrs) {
		llirInstr *instr = &b->instrs.e[i]->Instr;
		if (instr->kind != llirInstr_Phi) {
			phis = b->instrs;
			phis.count = i;
			return phis;
		}
	}
	return phis;
}

void llir_remove_pred(llirBlock *b, llirBlock *p) {
	llirValueArray phis = llir_get_block_phi_nodes(b);
	isize i = 0;
	for_array(j, b->preds) {
		llirBlock *pred = b->preds.e[j];
		if (pred != p) {
			b->preds.e[i] = b->preds.e[j];
			for_array(k, phis) {
				llirInstrPhi *phi = &phis.e[k]->Instr.Phi;
				phi->edges.e[i] = phi->edges.e[j];
			}
			i++;
		}
	}
	b->preds.count = i;
	for_array(k, phis) {
		llirInstrPhi *phi = &phis.e[k]->Instr.Phi;
		phi->edges.count = i;
	}

}

void llir_remove_dead_blocks(llirProcedure *proc) {
	isize j = 0;
	for_array(i, proc->blocks) {
		llirBlock *b = proc->blocks.e[i];
		if (b == NULL) {
			continue;
		}
		// NOTE(bill): Swap order
		b->index = j;
		proc->blocks.e[j++] = b;
	}
	proc->blocks.count = j;
}

void llir_mark_reachable(llirBlock *b) {
	isize const WHITE =  0;
	isize const BLACK = -1;
	b->index = BLACK;
	for_array(i, b->succs) {
		llirBlock *succ = b->succs.e[i];
		if (succ->index == WHITE) {
			llir_mark_reachable(succ);
		}
	}
}

void llir_remove_unreachable_blocks(llirProcedure *proc) {
	isize const WHITE =  0;
	isize const BLACK = -1;
	for_array(i, proc->blocks) {
		proc->blocks.e[i]->index = WHITE;
	}

	llir_mark_reachable(proc->blocks.e[0]);

	for_array(i, proc->blocks) {
		llirBlock *b = proc->blocks.e[i];
		if (b->index == WHITE) {
			for_array(j, b->succs) {
				llirBlock *c = b->succs.e[j];
				if (c->index == BLACK) {
					llir_remove_pred(c, b);
				}
			}
			// NOTE(bill): Mark as empty but don't actually free it
			// As it's been allocated with an arena
			proc->blocks.e[i] = NULL;
		}
	}
	llir_remove_dead_blocks(proc);
}

bool llir_opt_block_fusion(llirProcedure *proc, llirBlock *a) {
	if (a->succs.count != 1) {
		return false;
	}
	llirBlock *b = a->succs.e[0];
	if (b->preds.count != 1) {
		return false;
	}

	if (llir_opt_block_has_phi(b)) {
		return false;
	}

	array_pop(&a->instrs); // Remove branch at end
	for_array(i, b->instrs) {
		array_add(&a->instrs, b->instrs.e[i]);
		llir_set_instr_parent(b->instrs.e[i], a);
	}

	array_clear(&a->succs);
	for_array(i, b->succs) {
		array_add(&a->succs, b->succs.e[i]);
	}

	// Fix preds links
	for_array(i, b->succs) {
		llir_opt_block_replace_pred(b->succs.e[i], b, a);
	}

	proc->blocks.e[b->index] = NULL;
	return true;
}

void llir_opt_blocks(llirProcedure *proc) {
	llir_remove_unreachable_blocks(proc);

#if 1
	bool changed = true;
	while (changed) {
		changed = false;
		for_array(i, proc->blocks) {
			llirBlock *b = proc->blocks.e[i];
			if (b == NULL) {
				continue;
			}
			GB_ASSERT(b->index == i);

			if (llir_opt_block_fusion(proc, b)) {
				changed = true;
			}
			// TODO(bill): other simple block optimizations
		}
	}
#endif

	llir_remove_dead_blocks(proc);
}
void llir_opt_build_referrers(llirProcedure *proc) {
	gbTempArenaMemory tmp = gb_temp_arena_memory_begin(&proc->module->tmp_arena);

	llirValueArray ops = {0}; // NOTE(bill): Act as a buffer
	array_init_reserve(&ops, proc->module->tmp_allocator, 64); // HACK(bill): This _could_ overflow the temp arena
	for_array(i, proc->blocks) {
		llirBlock *b = proc->blocks.e[i];
		for_array(j, b->instrs) {
			llirValue *instr = b->instrs.e[j];
			array_clear(&ops);
			llir_opt_add_operands(&ops, &instr->Instr);
			for_array(k, ops) {
				llirValue *op = ops.e[k];
				if (op == NULL) {
					continue;
				}
				llirValueArray *refs = llir_value_referrers(op);
				if (refs != NULL) {
					array_add(refs, instr);
				}
			}
		}
	}

	gb_temp_arena_memory_end(tmp);
}







// State of Lengauer-Tarjan algorithm
// Based on this paper: http://jgaa.info/accepted/2006/GeorgiadisTarjanWerneck2006.10.1.pdf
typedef struct llirLTState {
	isize count;
	// NOTE(bill): These are arrays
	llirBlock **sdom;     // Semidominator
	llirBlock **parent;   // Parent in DFS traversal of CFG
	llirBlock **ancestor;
} llirLTState;

// §2.2 - bottom of page
void llir_lt_link(llirLTState *lt, llirBlock *p, llirBlock *q) {
	lt->ancestor[q->index] = p;
}

i32 llir_lt_depth_first_search(llirLTState *lt, llirBlock *p, i32 i, llirBlock **preorder) {
	preorder[i] = p;
	p->dom.pre = i++;
	lt->sdom[p->index] = p;
	llir_lt_link(lt, NULL, p);
	for_array(index, p->succs) {
		llirBlock *q = p->succs.e[index];
		if (lt->sdom[q->index] == NULL) {
			lt->parent[q->index] = p;
			i = llir_lt_depth_first_search(lt, q, i, preorder);
		}
	}
	return i;
}

llirBlock *llir_lt_eval(llirLTState *lt, llirBlock *v) {
	llirBlock *u = v;
	for (;
	     lt->ancestor[v->index] != NULL;
	     v = lt->ancestor[v->index]) {
		if (lt->sdom[v->index]->dom.pre < lt->sdom[u->index]->dom.pre) {
			u = v;
		}
	}
	return u;
}

typedef struct llirDomPrePost {
	i32 pre, post;
} llirDomPrePost;

llirDomPrePost llir_opt_number_dom_tree(llirBlock *v, i32 pre, i32 post) {
	llirDomPrePost result = {pre, post};

	v->dom.pre = pre++;
	for_array(i, v->dom.children) {
		result = llir_opt_number_dom_tree(v->dom.children.e[i], result.pre, result.post);
	}
	v->dom.post = post++;

	result.pre  = pre;
	result.post = post;
	return result;
}


// NOTE(bill): Requires `llir_opt_blocks` to be called before this
void llir_opt_build_dom_tree(llirProcedure *proc) {
	// Based on this paper: http://jgaa.info/accepted/2006/GeorgiadisTarjanWerneck2006.10.1.pdf

	gbTempArenaMemory tmp = gb_temp_arena_memory_begin(&proc->module->tmp_arena);

	isize n = proc->blocks.count;
	llirBlock **buf = gb_alloc_array(proc->module->tmp_allocator, llirBlock *, 5*n);

	llirLTState lt = {0};
	lt.count    = n;
	lt.sdom     = &buf[0*n];
	lt.parent   = &buf[1*n];
	lt.ancestor = &buf[2*n];

	llirBlock **preorder = &buf[3*n];
	llirBlock **buckets  = &buf[4*n];
	llirBlock *root = proc->blocks.e[0];

	// Step 1 - number vertices
	i32 pre_num = llir_lt_depth_first_search(&lt, root, 0, preorder);
	gb_memmove(buckets, preorder, n*gb_size_of(preorder[0]));

	for (i32 i = n-1; i > 0; i--) {
		llirBlock *w = preorder[i];

		// Step 3 - Implicitly define idom for nodes
		for (llirBlock *v = buckets[i]; v != w; v = buckets[v->dom.pre]) {
			llirBlock *u = llir_lt_eval(&lt, v);
			if (lt.sdom[u->index]->dom.pre < i) {
				v->dom.idom = u;
			} else {
				v->dom.idom = w;
			}
		}

		// Step 2 - Compute all sdoms
		lt.sdom[w->index] = lt.parent[w->index];
		for_array(pred_index, w->preds) {
			llirBlock *v = w->preds.e[pred_index];
			llirBlock *u = llir_lt_eval(&lt, v);
			if (lt.sdom[u->index]->dom.pre < lt.sdom[w->index]->dom.pre) {
				lt.sdom[w->index] = lt.sdom[u->index];
			}
		}

		llir_lt_link(&lt, lt.parent[w->index], w);

		if (lt.parent[w->index] == lt.sdom[w->index]) {
			w->dom.idom = lt.parent[w->index];
		} else {
			buckets[i] = buckets[lt.sdom[w->index]->dom.pre];
			buckets[lt.sdom[w->index]->dom.pre] = w;
		}
	}

	// The rest of Step 3
	for (llirBlock *v = buckets[0]; v != root; v = buckets[v->dom.pre]) {
		v->dom.idom = root;
	}

	// Step 4 - Explicitly define idom for nodes (in preorder)
	for (isize i = 1; i < n; i++) {
		llirBlock *w = preorder[i];
		if (w == root) {
			w->dom.idom = NULL;
		} else {
			// Weird tree relationships here!

			if (w->dom.idom != lt.sdom[w->index]) {
				w->dom.idom = w->dom.idom->dom.idom;
			}

			// Calculate children relation as inverse of idom
			if (w->dom.idom->dom.children.e == NULL) {
				// TODO(bill): Is this good enough for memory allocations?
				array_init(&w->dom.idom->dom.children, heap_allocator());
			}
			array_add(&w->dom.idom->dom.children, w);
		}
	}

	llir_opt_number_dom_tree(root, 0, 0);

	gb_temp_arena_memory_end(tmp);
}

void llir_opt_mem2reg(llirProcedure *proc) {
	// TODO(bill): llir_opt_mem2reg
}



void llir_opt_tree(llirGen *s) {
	s->opt_called = true;

	for_array(member_index, s->module.procs) {
		llirProcedure *proc = s->module.procs.e[member_index];
		if (proc->blocks.count == 0) { // Prototype/external procedure
			continue;
		}

		llir_opt_blocks(proc);
	#if 1
		llir_opt_build_referrers(proc);
		llir_opt_build_dom_tree(proc);

		// TODO(bill): llir optimization
		// [ ] cse (common-subexpression) elim
		// [ ] copy elim
		// [ ] dead code elim
		// [ ] dead store/load elim
		// [ ] phi elim
		// [ ] short circuit elim
		// [ ] bounds check elim
		// [ ] lift/mem2reg
		// [ ] lift/mem2reg

		llir_opt_mem2reg(proc);
	#endif

		GB_ASSERT(proc->blocks.count > 0);
		llir_number_proc_registers(proc);
	}
}
