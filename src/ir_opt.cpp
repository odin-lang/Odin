// Optimizations for the IR code

void ir_opt_add_operands(Array<irValue *> *ops, irInstr *i) {
	switch (i->kind) {
	case irInstr_Comment:
		break;
	case irInstr_Local:
		break;
	case irInstr_ZeroInit:
		array_add(ops, i->ZeroInit.address);
		break;
	case irInstr_Store:
		array_add(ops, i->Store.address);
		array_add(ops, i->Store.value);
		break;
	case irInstr_Load:
		array_add(ops, i->Load.address);
		break;
	case irInstr_ArrayElementPtr:
		array_add(ops, i->ArrayElementPtr.address);
		array_add(ops, i->ArrayElementPtr.elem_index);
		break;
	case irInstr_StructElementPtr:
		array_add(ops, i->StructElementPtr.address);
		break;
	case irInstr_PtrOffset:
		array_add(ops, i->PtrOffset.address);
		array_add(ops, i->PtrOffset.offset);
		break;
	case irInstr_StructExtractValue:
		array_add(ops, i->StructExtractValue.address);
		break;
	case irInstr_Conv:
		array_add(ops, i->Conv.value);
		break;
	case irInstr_Jump:
		break;
	case irInstr_If:
		array_add(ops, i->If.cond);
		break;
	case irInstr_Return:
		if (i->Return.value != nullptr) {
			array_add(ops, i->Return.value);
		}
		break;
	case irInstr_Select:
		array_add(ops, i->Select.cond);
		break;
	case irInstr_Phi:
		for_array(j, i->Phi.edges) {
			array_add(ops, i->Phi.edges[j]);
		}
		break;
	case irInstr_Unreachable:
		break;
	case irInstr_UnaryOp:
		array_add(ops, i->UnaryOp.expr);
		break;
	case irInstr_BinaryOp:
		array_add(ops, i->BinaryOp.left);
		array_add(ops, i->BinaryOp.right);
		break;
	case irInstr_Call:
		array_add(ops, i->Call.value);
		for_array(j, i->Call.args) {
			array_add(ops, i->Call.args[j]);
		}
		break;
	// case irInstr_VectorExtractElement:
		// array_add(ops, i->VectorExtractElement.vector);
		// array_add(ops, i->VectorExtractElement.index);
		// break;
	// case irInstr_VectorInsertElement:
		// array_add(ops, i->VectorInsertElement.vector);
		// array_add(ops, i->VectorInsertElement.elem);
		// array_add(ops, i->VectorInsertElement.index);
		// break;
	// case irInstr_VectorShuffle:
		// array_add(ops, i->VectorShuffle.vector);
		// break;
	case irInstr_StartupRuntime:
		break;

	#if 0
	case irInstr_BoundsCheck:
		array_add(ops, i->BoundsCheck.index);
		array_add(ops, i->BoundsCheck.len);
		break;
	case irInstr_SliceBoundsCheck:
		array_add(ops, i->SliceBoundsCheck.low);
		array_add(ops, i->SliceBoundsCheck.high);
		break;
	#endif
	}
}





void ir_opt_block_replace_pred(irBlock *b, irBlock *from, irBlock *to) {
	for_array(i, b->preds) {
		irBlock *pred = b->preds[i];
		if (pred == from) {
			b->preds[i] = to;
		}
	}
}

void ir_opt_block_replace_succ(irBlock *b, irBlock *from, irBlock *to) {
	for_array(i, b->succs) {
		irBlock *succ = b->succs[i];
		if (succ == from) {
			b->succs[i] = to;
		}
	}
}

bool ir_opt_block_has_phi(irBlock *b) {
	return b->instrs[0]->Instr.kind == irInstr_Phi;
}










Array<irValue *> ir_get_block_phi_nodes(irBlock *b) {
	Array<irValue *> phis = {0};
	for_array(i, b->instrs) {
		irInstr *instr = &b->instrs[i]->Instr;
		if (instr->kind != irInstr_Phi) {
			phis = b->instrs;
			phis.count = i;
			return phis;
		}
	}
	return phis;
}

void ir_remove_pred(irBlock *b, irBlock *p) {
	Array<irValue *> phis = ir_get_block_phi_nodes(b);
	isize i = 0;
	for_array(j, b->preds) {
		irBlock *pred = b->preds[j];
		if (pred != p) {
			b->preds[i] = b->preds[j];
			for_array(k, phis) {
				irInstrPhi *phi = &phis[k]->Instr.Phi;
				phi->edges[i] = phi->edges[j];
			}
			i++;
		}
	}
	b->preds.count = i;
	for_array(k, phis) {
		irInstrPhi *phi = &phis[k]->Instr.Phi;
		phi->edges.count = i;
	}

}

void ir_remove_dead_blocks(irProcedure *proc) {
	isize j = 0;
	for_array(i, proc->blocks) {
		irBlock *b = proc->blocks[i];
		if (b == nullptr) {
			continue;
		}
		// NOTE(bill): Swap order
		b->index = cast(i32)j;
		proc->blocks[j++] = b;
	}
	proc->blocks.count = j;
}

void ir_mark_reachable(irBlock *b) {
	isize const WHITE =  0;
	isize const BLACK = -1;
	b->index = BLACK;
	for_array(i, b->succs) {
		irBlock *succ = b->succs[i];
		if (succ->index == WHITE) {
			ir_mark_reachable(succ);
		}
	}
}

void ir_remove_unreachable_blocks(irProcedure *proc) {
	isize const WHITE =  0;
	isize const BLACK = -1;
	for_array(i, proc->blocks) {
		proc->blocks[i]->index = WHITE;
	}

	ir_mark_reachable(proc->blocks[0]);

	for_array(i, proc->blocks) {
		irBlock *b = proc->blocks[i];
		if (b->index == WHITE) {
			for_array(j, b->succs) {
				irBlock *c = b->succs[j];
				if (c->index == BLACK) {
					ir_remove_pred(c, b);
				}
			}
			// NOTE(bill): Mark as empty but don't actually free it
			// As it's been allocated with an arena
			proc->blocks[i] = nullptr;
		}
	}
	ir_remove_dead_blocks(proc);
}

bool ir_opt_block_fusion(irProcedure *proc, irBlock *a) {
	if (a->succs.count != 1) {
		return false;
	}
	irBlock *b = a->succs[0];
	if (b->preds.count != 1) {
		return false;
	}

	if (ir_opt_block_has_phi(b)) {
		return false;
	}

	array_pop(&a->instrs); // Remove branch at end
	for_array(i, b->instrs) {
		array_add(&a->instrs, b->instrs[i]);
		ir_set_instr_block(b->instrs[i], a);
	}

	array_clear(&a->succs);
	for_array(i, b->succs) {
		array_add(&a->succs, b->succs[i]);
	}

	// Fix preds links
	for_array(i, b->succs) {
		ir_opt_block_replace_pred(b->succs[i], b, a);
	}

	proc->blocks[b->index] = nullptr;
	return true;
}

void ir_opt_blocks(irProcedure *proc) {
	ir_remove_unreachable_blocks(proc);

#if 1
	bool changed = true;
	while (changed) {
		changed = false;
		for_array(i, proc->blocks) {
			irBlock *b = proc->blocks[i];
			if (b == nullptr) {
				continue;
			}
			GB_ASSERT_MSG(b->index == i, "%d, %td", b->index, i);

			if (ir_opt_block_fusion(proc, b)) {
				changed = true;
			}
			// TODO(bill): other simple block optimizations
		}
	}
#endif

	ir_remove_dead_blocks(proc);
}
void ir_opt_build_referrers(irProcedure *proc) {
	gbTempArenaMemory tmp = gb_temp_arena_memory_begin(&proc->module->tmp_arena);

	// NOTE(bill): Acta as a buffer
	auto ops = array_make<irValue *>(proc->module->tmp_allocator, 0, 64); // TODO HACK(bill): This _could_ overflow the temp arena
	for_array(i, proc->blocks) {
		irBlock *b = proc->blocks[i];
		for_array(j, b->instrs) {
			irValue *instr = b->instrs[j];
			array_clear(&ops);
			ir_opt_add_operands(&ops, &instr->Instr);

			for_array(k, ops) {
				irValue *op = ops[k];
				if (op == nullptr) {
					continue;
				}
				Array<irValue *> *refs = ir_value_referrers(op);
				if (refs != nullptr) {
					array_add(refs, instr);
				}
			}
		}
	}

	gb_temp_arena_memory_end(tmp);
}







// State of Lengauer-Tarjan algorithm
// Based on this paper: http://jgaa.info/accepted/2006/GeorgiadisTarjanWerneck2006.10.1.pdf
typedef struct irLTState {
	isize count;
	// NOTE(bill): These are arrays
	irBlock **sdom;     // Semidominator
	irBlock **parent;   // Parent in DFS traversal of CFG
	irBlock **ancestor;
} irLTState;

// §2.2 - bottom of page
void ir_lt_link(irLTState *lt, irBlock *p, irBlock *q) {
	lt->ancestor[q->index] = p;
}

i32 ir_lt_depth_first_search(irLTState *lt, irBlock *p, i32 i, irBlock **preorder) {
	preorder[i] = p;
	p->dom.pre = i++;
	lt->sdom[p->index] = p;
	ir_lt_link(lt, nullptr, p);
	for_array(index, p->succs) {
		irBlock *q = p->succs[index];
		if (lt->sdom[q->index] == nullptr) {
			lt->parent[q->index] = p;
			i = ir_lt_depth_first_search(lt, q, i, preorder);
		}
	}
	return i;
}

irBlock *ir_lt_eval(irLTState *lt, irBlock *v) {
	irBlock *u = v;
	for (;
	     lt->ancestor[v->index] != nullptr;
	     v = lt->ancestor[v->index]) {
		if (lt->sdom[v->index]->dom.pre < lt->sdom[u->index]->dom.pre) {
			u = v;
		}
	}
	return u;
}

typedef struct irDomPrePost {
	i32 pre, post;
} irDomPrePost;

irDomPrePost ir_opt_number_dom_tree(irBlock *v, i32 pre, i32 post) {
	irDomPrePost result = {pre, post};

	v->dom.pre = pre++;
	for_array(i, v->dom.children) {
		result = ir_opt_number_dom_tree(v->dom.children[i], result.pre, result.post);
	}
	v->dom.post = post++;

	result.pre  = pre;
	result.post = post;
	return result;
}


// NOTE(bill): Requires `ir_opt_blocks` to be called before this
void ir_opt_build_dom_tree(irProcedure *proc) {
	// Based on this paper: http://jgaa.info/accepted/2006/GeorgiadisTarjanWerneck2006.10.1.pdf

	gbTempArenaMemory tmp = gb_temp_arena_memory_begin(&proc->module->tmp_arena);

	i32 n = cast(i32)proc->blocks.count;
	irBlock **buf = gb_alloc_array(proc->module->tmp_allocator, irBlock *, 5*n);

	irLTState lt = {0};
	lt.count    = n;
	lt.sdom     = &buf[0*n];
	lt.parent   = &buf[1*n];
	lt.ancestor = &buf[2*n];

	irBlock **preorder = &buf[3*n];
	irBlock **buckets  = &buf[4*n];
	irBlock *root = proc->blocks[0];

	// Step 1 - number vertices
	i32 pre_num = ir_lt_depth_first_search(&lt, root, 0, preorder);
	gb_memmove(buckets, preorder, n*gb_size_of(preorder[0]));

	for (i32 i = n-1; i > 0; i--) {
		irBlock *w = preorder[i];

		// Step 3 - Implicitly define idom for nodes
		for (irBlock *v = buckets[i]; v != w; v = buckets[v->dom.pre]) {
			irBlock *u = ir_lt_eval(&lt, v);
			if (lt.sdom[u->index]->dom.pre < i) {
				v->dom.idom = u;
			} else {
				v->dom.idom = w;
			}
		}

		// Step 2 - Compute all sdoms
		lt.sdom[w->index] = lt.parent[w->index];
		for_array(pred_index, w->preds) {
			irBlock *v = w->preds[pred_index];
			irBlock *u = ir_lt_eval(&lt, v);
			if (lt.sdom[u->index]->dom.pre < lt.sdom[w->index]->dom.pre) {
				lt.sdom[w->index] = lt.sdom[u->index];
			}
		}

		ir_lt_link(&lt, lt.parent[w->index], w);

		if (lt.parent[w->index] == lt.sdom[w->index]) {
			w->dom.idom = lt.parent[w->index];
		} else {
			buckets[i] = buckets[lt.sdom[w->index]->dom.pre];
			buckets[lt.sdom[w->index]->dom.pre] = w;
		}
	}

	// The rest of Step 3
	for (irBlock *v = buckets[0]; v != root; v = buckets[v->dom.pre]) {
		v->dom.idom = root;
	}

	// Step 4 - Explicitly define idom for nodes (in preorder)
	for (isize i = 1; i < n; i++) {
		irBlock *w = preorder[i];
		if (w == root) {
			w->dom.idom = nullptr;
		} else {
			// Weird tree relationships here!

			if (w->dom.idom != lt.sdom[w->index]) {
				w->dom.idom = w->dom.idom->dom.idom;
			}

			// Calculate children relation as inverse of idom
			if (w->dom.idom->dom.children.data == nullptr) {
				// TODO(bill): Is this good enough for memory allocations?
				array_init(&w->dom.idom->dom.children, heap_allocator());
			}
			array_add(&w->dom.idom->dom.children, w);
		}
	}

	ir_opt_number_dom_tree(root, 0, 0);

	gb_temp_arena_memory_end(tmp);
}

void ir_opt_mem2reg(irProcedure *proc) {
	// TODO(bill): ir_opt_mem2reg
}



void ir_opt_tree(irGen *s) {
	s->opt_called = true;

	for_array(member_index, s->module.procs) {
		irProcedure *proc = s->module.procs[member_index];
		if (proc->blocks.count == 0) { // Prototype/external procedure
			continue;
		}

		ir_opt_blocks(proc);
	#if 0
		ir_opt_build_referrers(proc);
		ir_opt_build_dom_tree(proc);

		// TODO(bill): ir optimization
		// [ ] cse (common-subexpression) elim
		// [ ] copy elim
		// [ ] dead code elim
		// [ ] dead store/load elim
		// [ ] phi elim
		// [ ] short circuit elim
		// [ ] bounds check elim
		// [ ] lift/mem2reg
		// [ ] lift/mem2reg

		ir_opt_mem2reg(proc);
	#endif

		GB_ASSERT(proc->blocks.count > 0);
		ir_number_proc_registers(proc);
	}
}
