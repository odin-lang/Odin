// The analysis of atomic memory orderings, after every procedure body is checked. Each atomic operation on `&x` is
// on a location: a global, a static, or a field for every value of its struct, as which value it is cannot be known.
// What is written with release ordering but only loaded with relaxed ordering, or read with acquire ordering but only
// stored with relaxed ordering, orders nothing, and is warned about, unless the address of the location is taken
// elsewhere, as it may then be accessed through it. Only loads and stores are what it would pair with, as a
// read-modify-write asking for an ordering which nothing pairs with, e.g. to count, is harmless.
// With -vet-atomic-access, a plain read of a location accessed atomically is an error, unless a lock is taken.

struct AtomicUses {
	Ast *first;        // the first atomic operation of each, by position
	Ast *load;
	Ast *store;
	Ast *asks_acquire; // explicitly, in a file with the analysis
	Ast *asks_release;
	bool acquires;     // by any read, including with seq_cst ordering or a fence
	bool releases;
	bool escaped;
};

struct AtomicFences {
	bool acquire;
	bool release;
};

struct AtomicReport {
	Ast *site;  // what asks for an ordering which nothing pairs with
	Ast *other; // what would pair with it, with that ordering
	bool release;
};

struct AtomicScan {
	Array<Ast *> reads; // plain reads of what is accessed atomically
	bool         locks;
};

gb_global PtrMap<Entity *, AtomicUses> atomic_uses;


// what an atomic operation on `&expr` is on, if anything
gb_internal Entity *check_atomic_location(Ast *expr) {
	for (;;) {
		expr = unparen_expr(expr);
		switch (expr->kind) {
		case_ast_node(i, Ident, expr);
			Entity *e = entity_of_node(expr);
			if (e == nullptr || e->kind != Entity_Variable) {
				return nullptr;
			}
			if (e->using_parent != nullptr) {
				Type *t = base_type(type_deref(e->using_parent->type));
				if (t == nullptr || t->kind != Type_Struct) {
					return nullptr;
				}
				for (Entity *f : t->Struct.fields) {
					if (f->token.string == e->token.string) {
						return f;
					}
				}
				return nullptr;
			}
			if (!e->Variable.is_global && (e->flags & EntityFlag_Static) == 0) {
				return nullptr;
			}
			if (e->Variable.thread_local_model.len != 0) {
				return nullptr;
			}
			return e;
		case_end;

		case_ast_node(se, SelectorExpr, expr);
			if (se->swizzle_count > 0 || se->is_bit_field) {
				return nullptr;
			}
			Entity *pkg = entity_of_node(se->expr);
			if (pkg != nullptr && pkg->kind == Entity_ImportName) {
				expr = se->selector;
				continue;
			}
			Entity *f = entity_of_node(se->selector);
			if (f == nullptr || f->kind != Entity_Variable || (f->flags & EntityFlag_Field) == 0) {
				return nullptr;
			}
			return f;
		case_end;

		case_ast_node(ie, IndexExpr, expr);
			// an element of an array is within it, but not one of a slice, as it may be reached through any copy of it
			Type *t = base_type(ie->expr->tav.type);
			if (t == nullptr || (t->kind != Type_Array && t->kind != Type_EnumeratedArray && t->kind != Type_FixedCapacityDynamicArray)) {
				return nullptr;
			}
			expr = ie->expr;
		case_end;

		default:
			return nullptr;
		}
	}
}

gb_internal void check_atomic_first(Ast **site, Ast *call) {
	if (*site == nullptr || token_pos_cmp(ast_token(call).pos, ast_token(*site).pos) < 0) {
		*site = call;
	}
}

gb_internal OdinAtomicMemoryOrder check_atomic_order_of(Ast *expr) {
	return cast(OdinAtomicMemoryOrder)exact_value_to_i64(expr->tav.value);
}

gb_internal bool check_atomic_order_acquires(OdinAtomicMemoryOrder order) {
	switch (order) {
	case OdinAtomicMemoryOrder_consume:
	case OdinAtomicMemoryOrder_acquire:
	case OdinAtomicMemoryOrder_acq_rel:
	case OdinAtomicMemoryOrder_seq_cst:
		return true;
	}
	return false;
}

gb_internal bool check_atomic_order_releases(OdinAtomicMemoryOrder order) {
	switch (order) {
	case OdinAtomicMemoryOrder_release:
	case OdinAtomicMemoryOrder_acq_rel:
	case OdinAtomicMemoryOrder_seq_cst:
		return true;
	}
	return false;
}

gb_internal int check_atomic_report_cmp(void const *a, void const *b) {
	AtomicReport const *x = cast(AtomicReport const *)a;
	AtomicReport const *y = cast(AtomicReport const *)b;
	return token_pos_cmp(ast_token(x->site).pos, ast_token(y->site).pos);
}

// the plain reads within a statement or an expression, of which only the address is used when `addr`
gb_internal void check_atomic_scan(AtomicScan *s, Ast *node, bool addr) {
	if (node == nullptr || node->tav.mode == Addressing_Constant || node->tav.mode == Addressing_Type) {
		return;
	}
	switch (node->kind) {
	case Ast_Ident:
	case Ast_SelectorExpr:
	case Ast_IndexExpr:
		if (!addr) {
			Entity *e = check_atomic_location(node);
			if (e != nullptr && map_get(&atomic_uses, e) != nullptr) {
				array_add(&s->reads, node);
			}
		}
		break;
	}

	switch (node->kind) {
	case_ast_node(pe, ParenExpr, node);
		check_atomic_scan(s, pe->expr, addr);
	case_end;

	case_ast_node(ue, UnaryExpr, node);
		check_atomic_scan(s, ue->expr, ue->op.kind == Token_And);
	case_end;

	case_ast_node(be, BinaryExpr, node);
		check_atomic_scan(s, be->left,  false);
		check_atomic_scan(s, be->right, false);
	case_end;

	case_ast_node(se, SelectorExpr, node);
		Entity *pkg = entity_of_node(se->expr);
		if (pkg != nullptr && pkg->kind == Entity_ImportName) {
			break;
		}
		// reading a field reads only it, of what it is within
		if (is_type_pointer(se->expr->tav.type)) {
			check_atomic_scan(s, se->expr, false);
		} else {
			check_atomic_scan(s, se->expr, addr || se->swizzle_count == 0);
		}
	case_end;

	case_ast_node(ie, IndexExpr, node);
		Type *t = base_type(ie->expr->tav.type);
		if (t != nullptr && (t->kind == Type_Array || t->kind == Type_EnumeratedArray || t->kind == Type_FixedCapacityDynamicArray || t->kind == Type_Matrix || t->kind == Type_Struct)) {
			check_atomic_scan(s, ie->expr, true);
		} else {
			check_atomic_scan(s, ie->expr, false);
		}
		check_atomic_scan(s, ie->index, false);
	case_end;

	case_ast_node(mie, MatrixIndexExpr, node);
		check_atomic_scan(s, mie->expr, true);
		check_atomic_scan(s, mie->row_index, false);
		check_atomic_scan(s, mie->column_index, false);
	case_end;

	case_ast_node(de, DerefExpr, node);
		check_atomic_scan(s, de->expr, false);
	case_end;

	case_ast_node(se, SliceExpr, node);
		check_atomic_scan(s, se->expr, is_type_array_like(se->expr->tav.type));
		check_atomic_scan(s, se->low,  false);
		check_atomic_scan(s, se->high, false);
	case_end;

	case_ast_node(ce, CallExpr, node);
		Ast *proc = unparen_expr(ce->proc);
		if (proc->tav.mode != Addressing_Type && proc->tav.mode != Addressing_Builtin) {
			Entity *e = nullptr;
			if (proc->kind == Ast_Ident || proc->kind == Ast_SelectorExpr) {
				e = entity_of_node(proc);
			}
			// e.g. `sync.mutex_lock` or `sync.guard`, after which plain reads are assumed to be under the lock
			if (e != nullptr && e->kind == Entity_Procedure && e->pkg != nullptr && e->pkg->name == "sync" &&
			    (string_contains_string(e->token.string, str_lit("lock")) || string_contains_string(e->token.string, str_lit("guard")))) {
				s->locks = true;
			}
			check_atomic_scan(s, proc, false);
		}
		for (Ast *arg : ce->args) {
			check_atomic_scan(s, arg, false);
		}
	case_end;

	case_ast_node(sce, SelectorCallExpr, node);
		check_atomic_scan(s, sce->call, false);
	case_end;

	case_ast_node(cl, CompoundLit, node);
		for (Ast *elem : cl->elems) {
			check_atomic_scan(s, elem, false);
		}
	case_end;

	case_ast_node(fv, FieldValue, node);
		check_atomic_scan(s, fv->value, false);
	case_end;

	case_ast_node(te, TernaryIfExpr, node);
		check_atomic_scan(s, te->cond, false);
		check_atomic_scan(s, te->x, false);
		check_atomic_scan(s, te->y, false);
	case_end;

	case_ast_node(te, TernaryWhenExpr, node);
		if (te->cond != nullptr && te->cond->tav.value.kind == ExactValue_Bool) {
			if (te->cond->tav.value.value_bool) {
				check_atomic_scan(s, te->x, false);
			} else {
				check_atomic_scan(s, te->y, false);
			}
		}
	case_end;

	case_ast_node(oe, OrElseExpr, node);
		check_atomic_scan(s, oe->x, false);
		check_atomic_scan(s, oe->y, false);
	case_end;

	case_ast_node(re, OrReturnExpr, node);
		check_atomic_scan(s, re->expr, false);
	case_end;

	case_ast_node(be, OrBranchExpr, node);
		check_atomic_scan(s, be->expr, false);
	case_end;

	case_ast_node(ta, TypeAssertion, node);
		check_atomic_scan(s, ta->expr, false);
	case_end;

	case_ast_node(tc, TypeCast, node);
		check_atomic_scan(s, tc->expr, false);
	case_end;

	case_ast_node(ac, AutoCast, node);
		check_atomic_scan(s, ac->expr, false);
	case_end;

	case_ast_node(te, TagExpr, node);
		check_atomic_scan(s, te->expr, false);
	case_end;

	case_ast_node(es, ExprStmt, node);
		check_atomic_scan(s, es->expr, false);
	case_end;

	case_ast_node(vd, ValueDecl, node);
		if (vd->is_mutable) {
			for (Ast *value : vd->values) {
				check_atomic_scan(s, value, false);
			}
		}
	case_end;

	case_ast_node(as, AssignStmt, node);
		for (Ast *rhs : as->rhs) {
			check_atomic_scan(s, rhs, false);
		}
		for (Ast *lhs : as->lhs) {
			check_atomic_scan(s, lhs, as->op.kind == Token_Eq);
		}
	case_end;

	case_ast_node(bs, BlockStmt, node);
		for (Ast *stmt : bs->stmts) {
			check_atomic_scan(s, stmt, false);
		}
	case_end;

	case_ast_node(is, IfStmt, node);
		check_atomic_scan(s, is->init, false);
		check_atomic_scan(s, is->cond, false);
		check_atomic_scan(s, is->body, false);
		check_atomic_scan(s, is->else_stmt, false);
	case_end;

	case_ast_node(ws, WhenStmt, node);
		if (ws->is_cond_determined) {
			if (ws->determined_cond) {
				check_atomic_scan(s, ws->body, false);
			} else {
				check_atomic_scan(s, ws->else_stmt, false);
			}
		}
	case_end;

	case_ast_node(rs, ReturnStmt, node);
		for (Ast *result : rs->results) {
			check_atomic_scan(s, result, false);
		}
	case_end;

	case_ast_node(fs, ForStmt, node);
		check_atomic_scan(s, fs->init, false);
		check_atomic_scan(s, fs->cond, false);
		check_atomic_scan(s, fs->post, false);
		check_atomic_scan(s, fs->body, false);
	case_end;

	case_ast_node(rs, RangeStmt, node);
		bool by_ref = false;
		for (Ast *val : rs->vals) {
			by_ref |= val->kind == Ast_UnaryExpr && val->UnaryExpr.op.kind == Token_And;
		}
		check_atomic_scan(s, rs->expr, by_ref && is_type_array_like(rs->expr->tav.type));
		check_atomic_scan(s, rs->body, false);
	case_end;

	case_ast_node(rs, UnrollRangeStmt, node);
		bool by_ref = false;
		Ast *vals[2] = {rs->val0, rs->val1};
		for (Ast *val : vals) {
			by_ref |= val != nullptr && val->kind == Ast_UnaryExpr && val->UnaryExpr.op.kind == Token_And;
		}
		check_atomic_scan(s, rs->init, false);
		check_atomic_scan(s, rs->expr, by_ref && is_type_array_like(rs->expr->tav.type));
		check_atomic_scan(s, rs->body, false);
	case_end;

	case_ast_node(ss, SwitchStmt, node);
		check_atomic_scan(s, ss->init, false);
		check_atomic_scan(s, ss->tag, false);
		check_atomic_scan(s, ss->body, false);
	case_end;

	case_ast_node(ss, TypeSwitchStmt, node);
		if (ss->tag != nullptr && ss->tag->kind == Ast_AssignStmt) {
			for (Ast *rhs : ss->tag->AssignStmt.rhs) {
				check_atomic_scan(s, rhs, false);
			}
		}
		check_atomic_scan(s, ss->body, false);
	case_end;

	case_ast_node(cc, CaseClause, node);
		for (Ast *expr : cc->list) {
			check_atomic_scan(s, expr, false);
		}
		for (Ast *stmt : cc->stmts) {
			check_atomic_scan(s, stmt, false);
		}
	case_end;

	case_ast_node(ds, DeferStmt, node);
		check_atomic_scan(s, ds->stmt, false);
	case_end;
	}
}

gb_internal void check_atomic_bodies(ProcInfo **procs, isize count) {
	TEMPORARY_ALLOCATOR_GUARD();
	for (isize i = 0; i < count; i++) {
		ProcInfo *pi = procs[i];
		Ast *body = pi->body;
		if (body == nullptr || !ast_file_analysis(body->file(), AnalysisFlag_Atomic) || (ast_file_vet_flags(body->file()) & VetFlag_AtomicAccess) == 0) {
			continue;
		}
		AtomicScan s = {};
		s.reads = array_make<Ast *>(temporary_allocator(), 0, 0);
		check_atomic_scan(&s, body, false);
		if (s.locks || s.reads.count == 0) {
			continue;
		}

		ErrorInstantiations prev_instantiations = global_error_context.instantiations;
		global_error_context.instantiations = {pi->generated_from_polymorphic ? pi : pi->poly_parent, nullptr};
		for (Ast *read : s.reads) {
			AtomicUses *uses = map_get(&atomic_uses, check_atomic_location(read));
			ERROR_BLOCK();
			gbString str = expr_to_string(read);
			error(read, "'%s' is read plainly, but it is accessed atomically, e.g. at %s", str, token_pos_to_string(ast_token(uses->first).pos));
			error_line("\tSuggestion: Read it with 'atomic_load_explicit(&%s, .Relaxed)', or take a lock around it\n", str);
			gb_string_free(str);
		}
		global_error_context.instantiations = prev_instantiations;
	}
}

gb_internal void check_atomics(Checker *c) {
	TEMPORARY_ALLOCATOR_GUARD();

	auto atomics = array_make<CheckedAtomic>(heap_allocator());
	auto addresses = array_make<CheckedAddress>(heap_allocator());
	defer (array_free(&atomics));
	defer (array_free(&addresses));
	per_thread_array_gather(&c->info.checked_atomics_queue, &atomics);
	per_thread_array_gather(&c->info.checked_addresses_queue, &addresses);

	map_init(&atomic_uses, 0);
	defer ({
		map_destroy(&atomic_uses);
		atomic_uses = {};
	});

	PtrMap<DeclInfo *, AtomicFences> fences = {};
	map_init(&fences, 0);
	defer (map_destroy(&fences));
	for (CheckedAtomic const &a : atomics) {
		if (a.id != BuiltinProc_atomic_thread_fence || a.decl == nullptr) {
			continue;
		}
		OdinAtomicMemoryOrder order = check_atomic_order_of(a.call->CallExpr.args[0]);
		AtomicFences f = {};
		if (AtomicFences *found = map_get(&fences, a.decl)) {
			f = *found;
		}
		f.acquire |= check_atomic_order_acquires(order);
		f.release |= check_atomic_order_releases(order);
		map_set(&fences, a.decl, f);
	}

	PtrSet<Ast *> operated = {};
	ptr_set_init(&operated, atomics.count);
	defer (ptr_set_destroy(&operated));

	for (CheckedAtomic const &a : atomics) {
		if (a.id == BuiltinProc_atomic_thread_fence || a.id == BuiltinProc_atomic_signal_fence) {
			continue;
		}
		Ast *call = a.call;
		Ast *ptr = check_atomic_address_of(call->CallExpr.args[0]);
		if (ptr == nullptr) {
			continue;
		}
		ptr_set_add(&operated, ptr);
		Entity *e = check_atomic_location(ptr->UnaryExpr.expr);
		if (e == nullptr) {
			continue;
		}

		// what the operation does, with the orderings it has, explicitly or by default
		bool explicit_order = true;
		OdinAtomicMemoryOrder order = OdinAtomicMemoryOrder_seq_cst;
		OdinAtomicMemoryOrder failure = OdinAtomicMemoryOrder_relaxed;
		bool reads  = true;
		bool writes = true;
		switch (a.id) {
		case BuiltinProc_atomic_store:
			explicit_order = false;
			reads = false;
			break;
		case BuiltinProc_atomic_store_explicit:
			order = check_atomic_order_of(call->CallExpr.args[2]);
			reads = false;
			break;
		case BuiltinProc_atomic_load:
			explicit_order = false;
			writes = false;
			break;
		case BuiltinProc_atomic_load_explicit:
			order = check_atomic_order_of(call->CallExpr.args[1]);
			writes = false;
			break;
		case BuiltinProc_atomic_add_explicit:
		case BuiltinProc_atomic_sub_explicit:
		case BuiltinProc_atomic_and_explicit:
		case BuiltinProc_atomic_nand_explicit:
		case BuiltinProc_atomic_or_explicit:
		case BuiltinProc_atomic_xor_explicit:
		case BuiltinProc_atomic_exchange_explicit:
			order = check_atomic_order_of(call->CallExpr.args[2]);
			break;
		case BuiltinProc_atomic_compare_exchange_strong_explicit:
		case BuiltinProc_atomic_compare_exchange_weak_explicit:
			order   = check_atomic_order_of(call->CallExpr.args[3]);
			failure = check_atomic_order_of(call->CallExpr.args[4]);
			break;
		default:
			explicit_order = false;
			break;
		}

		AtomicFences f = {};
		if (a.decl != nullptr) {
			if (AtomicFences *found = map_get(&fences, a.decl)) {
				f = *found;
			}
		}

		AtomicUses uses = {};
		if (AtomicUses *found = map_get(&atomic_uses, e)) {
			uses = *found;
		} else {
			// what is foreign or exported may be accessed by what is not checked
			uses.escaped = e->Variable.is_foreign || e->Variable.is_export;
		}
		// seq_cst, by default or not, is not asked for as acquire or release ordering is, so it is never reported
		bool reported = explicit_order && order != OdinAtomicMemoryOrder_seq_cst && ast_file_analysis(call->file(), AnalysisFlag_Atomic);
		check_atomic_first(&uses.first, call);
		if (reads && !writes) {
			check_atomic_first(&uses.load, call);
		}
		if (writes && !reads) {
			check_atomic_first(&uses.store, call);
		}
		if (reads) {
			uses.acquires |= check_atomic_order_acquires(order) || check_atomic_order_acquires(failure) || f.acquire;
			if (reported && check_atomic_order_acquires(order)) {
				check_atomic_first(&uses.asks_acquire, call);
			}
		}
		if (writes) {
			uses.releases |= check_atomic_order_releases(order) || f.release;
			if (reported && check_atomic_order_releases(order)) {
				check_atomic_first(&uses.asks_release, call);
			}
		}
		map_set(&atomic_uses, e, uses);
	}
	if (atomic_uses.count == 0) {
		return;
	}

	for (CheckedAddress const &a : addresses) {
		if (ptr_set_exists(&operated, a.node)) {
			continue;
		}
		if (AtomicUses *uses = map_get(&atomic_uses, a.location)) {
			uses->escaped = true;
		}
	}

	if (!global_ignore_warnings()) {
		auto reports = array_make<AtomicReport>(temporary_allocator(), 0, 0);
		for (auto const &entry : atomic_uses) {
			AtomicUses const &uses = entry.value;
			if (uses.escaped) {
				continue;
			}
			// asking for acquire ordering acquires, so at most one of these
			if (uses.asks_release != nullptr && uses.load != nullptr && !uses.acquires) {
				array_add(&reports, AtomicReport{uses.asks_release, uses.load, true});
			} else if (uses.asks_acquire != nullptr && uses.store != nullptr && !uses.releases) {
				array_add(&reports, AtomicReport{uses.asks_acquire, uses.store, false});
			}
		}
		// in order, and once for what is at the same place in each instantiation of a polymorphic procedure
		array_sort(reports, check_atomic_report_cmp);
		TokenPos last = {};
		for (AtomicReport const &r : reports) {
			TokenPos pos = ast_token(r.site).pos;
			if (pos == last) {
				continue;
			}
			last = pos;

			ERROR_BLOCK();
			gbString str = expr_to_string(check_atomic_address_of(r.site->CallExpr.args[0])->UnaryExpr.expr);
			char const *other = token_pos_to_string(ast_token(r.other).pos);
			if (r.release) {
				warning(r.site, "'%s' is written with release ordering, but it is only loaded with relaxed ordering, so the release orders nothing", str);
				error_line("\tSuggestion: Load it with .Acquire, e.g. at %s, or write it with .Relaxed\n", other);
			} else {
				warning(r.site, "'%s' is read with acquire ordering, but it is only stored with relaxed ordering, so the acquire orders nothing", str);
				error_line("\tSuggestion: Store it with .Release, e.g. at %s, or read it with .Relaxed\n", other);
			}
			gb_string_free(str);
		}
	}

	// only when a file has -vet-atomic-access
	bool vetted = (build_context.vet_flags & VetFlag_AtomicAccess) != 0;
	for (auto const &entry : c->info.files) {
		AstFile *f = entry.value;
		vetted |= f->vet_flags_set && (f->vet_flags & VetFlag_AtomicAccess) != 0;
	}
	if (!vetted) {
		return;
	}

	auto procs = array_make<ProcInfo *>(heap_allocator());
	defer (array_free(&procs));
	for (PerThreadArraySlot<ProcInfo *> &slot : c->info.checked_bodies_queue.slots) {
		array_add_elems(&procs, slot.array.data, slot.array.count);
	}
	if (!build_context.no_threaded_checker && build_context.thread_count > 1) {
		thread_pool_for_chunks(procs.data, procs.count, 1024, check_atomic_bodies);
	} else {
		check_atomic_bodies(procs.data, procs.count);
	}
}
