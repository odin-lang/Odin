// The analysis of atomic memory orderings, after every procedure body is checked. Each atomic operation on `&x` is
// on a location: a global, a static, or a field for every value of its struct, as which value it is cannot be known.
// What is written with release ordering but only loaded with relaxed ordering, or read with acquire ordering but only
// stored with relaxed ordering, orders nothing, and is warned about, unless the address of the location is taken
// elsewhere, as it may then be accessed through it. Only loads and stores are what it would pair with, as a
// read-modify-write asking for an ordering which nothing pairs with, e.g. to count, is harmless.
// A call to a procedure with `@(futex=.Wait)` is a relaxed load of what its first argument points to, as the OS only
// compares it, and one with `@(futex=.Wake)` accesses nothing; neither is taking its address elsewhere.
// A relaxed read acquires when an acquire fence may be reached after it: later in its procedure, in the same loop, in
// a `defer`, or in a procedure which calls its own, directly or not, before the fence. A relaxed write releases,
// likewise, when a release fence may be reached before it.
// Also warned about: a weak compare-exchange whose second result is not used, as it may fail even when the value
// matches; a futex woken before the procedure waking it writes it, as what waits on it may sleep again; and with an
// unpaired ordering, an `atomic_signal_fence` where an `atomic_thread_fence` would pair, as it only orders against a
// signal handler on the same thread.
// Atomics on a local whose address is only taken by them are warned about too, as nothing else can access it, so they
// order nothing; `volatile_*` is probably what is meant, to keep the accesses, or it is a copy of what is shared.
// A location accessed with `volatile_*` and atomically is warned about, as a volatile access is not atomic.
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

struct AtomicPlace {
	Ast *loop;     // the outermost loop it is within
	bool deferred;
	bool discards; // its second result, as a statement or into `_`
};

struct AtomicProcedure {
	Array<Ast *>               acquires;        // its fences with acquire ordering
	Array<Ast *>               releases;        // and with release ordering
	Array<Ast *>               signal_acquires; // likewise, its signal fences
	Array<Ast *>               signal_releases;
	PtrMap<Ast *, AtomicPlace> places;          // of each call within it
};

struct AtomicLocal {
	DeclInfo *decl;
	i32       count;
	i32       addressed;
	Ast *     first;
};

struct AtomicSite {
	Entity *  location;
	Ast *     call;
	DeclInfo *decl;
};

enum AtomicReportKind : u8 {
	AtomicReport_Invalid,
	AtomicReport_Release,     // written with release ordering, which nothing acquires
	AtomicReport_Acquire,     // read with acquire ordering, which nothing releases
	AtomicReport_WeakIgnored, // a weak compare-exchange whose second result is not used
	AtomicReport_WakeEarly,   // a futex woken before it is written
	AtomicReport_Local,       // atomics on a local which nothing else can access
	AtomicReport_Volatile,    // a volatile access of what is accessed atomically
};

struct AtomicReport {
	AtomicReportKind kind;
	Ast *            site;
	Ast *            other; // what would pair with it, or the write after the wake
};

struct AtomicScan {
	Array<Ast *> reads; // plain reads of what is accessed atomically
	bool         locks;

	PtrMap<Ast *, AtomicPlace> *places; // NULL when not used
	AtomicPlace                 place;

	PtrMap<Entity *, AtomicLocal> *locals; // NULL when not used
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

gb_internal Entity *check_atomic_local(Ast *expr) {
	for (;;) {
		expr = unparen_expr(expr);
		switch (expr->kind) {
		case_ast_node(i, Ident, expr);
			Entity *e = entity_of_node(expr);
			if (e == nullptr || e->kind != Entity_Variable) {
				return nullptr;
			}
			if (e->using_parent != nullptr) {
				// a field brought in by `using`, within what it was applied to, unless that is a pointer
				if (is_type_pointer(e->using_parent->type)) {
					return nullptr;
				}
				e = e->using_parent;
			}
			if ((e->flags & EntityFlag_Param) != 0 || !is_entity_local_variable(e)) {
				return nullptr;
			}
			return e;
		case_end;

		case_ast_node(se, SelectorExpr, expr);
			if (is_type_pointer(se->expr->tav.type)) {
				return nullptr;
			}
			expr = se->expr;
		case_end;

		case_ast_node(ie, IndexExpr, expr);
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

gb_internal void check_atomic_address_taken(AtomicScan *s, Ast *expr) {
	// by `&`, slicing, or iterating by reference
	// which a call like `x->f()` is too, as `&x` is its first argument
	if (s->locals == nullptr) {
		return;
	}
	if (Entity *l = check_atomic_local(expr)) {
		if (AtomicLocal *local = map_get(s->locals, l)) {
			local->addressed += 1;
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

gb_internal bool check_atomic_may_precede(AtomicProcedure *p, Ast *a, Ast *b) {
	// NOTE(bill) Check to see whether both (within a procedure) `a` may run before `b`

	AtomicPlace *pa = map_get(&p->places, a);
	AtomicPlace *pb = map_get(&p->places, b);
	if (pa == nullptr || pb == nullptr || pa->deferred || pb->deferred) {
		return true;
	}
	if (pa->loop != nullptr && pa->loop == pb->loop) {
		return true;
	}
	return token_pos_cmp(ast_token(a).pos, ast_token(b).pos) < 0;
}

gb_internal bool check_atomic_fenced(AtomicProcedure *p, Array<Ast *> const &fences, Ast *call, bool acquire) {
	// Whether an acquire fence may run after a call or a release fence before it
	for (Ast *fence : fences) {
		if (acquire && check_atomic_may_precede(p, call, fence)) {
			return true;
		}
		if (!acquire && check_atomic_may_precede(p, fence, call)) {
			return true;
		}
	}
	return false;
}

gb_internal void check_atomic_discard(AtomicScan *s, Ast *expr) {
	expr = unparen_expr(expr);
	if (s->places == nullptr || expr->kind != Ast_CallExpr) {
		return;
	}
	if (AtomicPlace *place = map_get(s->places, expr)) {
		place->discards = true;
	}
}

gb_internal void check_atomic_cover(PtrSet<DeclInfo *> *covered, DeclInfo *decl) {
	if (ptr_set_update(covered, decl)) {
		return;
	}
	auto stack = array_make<DeclInfo *>(temporary_allocator(), 0, 16);
	array_add(&stack, decl);
	while (stack.count > 0) {
		DeclInfo *d = array_pop(&stack);
		FOR_PTR_SET(e, d->deps) {
			if (e->kind == Entity_Procedure && e->decl_info != nullptr && !ptr_set_update(covered, e->decl_info)) {
				array_add(&stack, e->decl_info);
			}
		}
	}
}

gb_internal int check_atomic_report_cmp(void const *a, void const *b) {
	AtomicReport const *x = cast(AtomicReport const *)a;
	AtomicReport const *y = cast(AtomicReport const *)b;
	i32 cmp = token_pos_cmp(ast_token(x->site).pos, ast_token(y->site).pos);
	if (cmp != 0) {
		return cmp;
	}
	return cast(int)x->kind - cast(int)y->kind;
}

// the plain reads within a statement or an expression, of which only the address is used when `addr`
gb_internal void check_atomic_scan(AtomicScan *s, Ast *node, bool addr) {
	if (node == nullptr || node->tav.mode == Addressing_Constant || node->tav.mode == Addressing_Type) {
		return;
	}
	AtomicPlace place = s->place;
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
	case Ast_CallExpr:
		if (s->places != nullptr) {
			map_set(s->places, node, s->place);
		}
		break;
	case Ast_ForStmt:
	case Ast_RangeStmt:
	case Ast_UnrollRangeStmt:
		if (s->place.loop == nullptr) {
			s->place.loop = node;
		}
		break;
	case Ast_DeferStmt:
		s->place.deferred = true;
		break;
	}

	switch (node->kind) {
	case_ast_node(pe, ParenExpr, node);
		check_atomic_scan(s, pe->expr, addr);
	case_end;

	case_ast_node(ue, UnaryExpr, node);
		if (ue->op.kind == Token_And) {
			check_atomic_address_taken(s, ue->expr);
		}
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
		if (is_type_array_like(se->expr->tav.type)) {
			check_atomic_address_taken(s, se->expr);
		}
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

	case_ast_node(el, Ellipsis, node);
		check_atomic_scan(s, el->expr, false);
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
		check_atomic_discard(s, es->expr);
	case_end;

	case_ast_node(vd, ValueDecl, node);
		if (vd->is_mutable) {
			for (Ast *value : vd->values) {
				check_atomic_scan(s, value, false);
			}
			if (vd->values.count == 1 && vd->names.count == 2 && is_blank_ident(vd->names[1])) {
				check_atomic_discard(s, vd->values[0]);
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
		if (as->op.kind == Token_Eq && as->rhs.count == 1 && as->lhs.count == 2 && is_blank_ident(as->lhs[1])) {
			check_atomic_discard(s, as->rhs[0]);
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
		if (by_ref && is_type_array_like(rs->expr->tav.type)) {
			check_atomic_address_taken(s, rs->expr);
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
		if (by_ref && is_type_array_like(rs->expr->tav.type)) {
			check_atomic_address_taken(s, rs->expr);
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
	s->place = place;
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

	PtrMap<DeclInfo *, AtomicProcedure> procedures = {};
	map_init(&procedures, 0);
	defer ({
		for (auto &entry : procedures) {
			map_destroy(&entry.value.places);
		}
		map_destroy(&procedures);
	});
	for (CheckedAtomic const &a : atomics) {
		bool fence = a.id == BuiltinProc_atomic_thread_fence || a.id == BuiltinProc_atomic_signal_fence;
		bool weak  = a.id == BuiltinProc_atomic_compare_exchange_weak || a.id == BuiltinProc_atomic_compare_exchange_weak_explicit;
		if (a.decl == nullptr || !(fence || weak || a.futex == ProcedureFutex_Wake)) {
			continue;
		}
		AtomicProcedure *p = map_get(&procedures, a.decl);
		if (p == nullptr) {
			map_set(&procedures, a.decl, AtomicProcedure{});
			p = map_get(&procedures, a.decl);
			p->acquires        = array_make<Ast *>(temporary_allocator(), 0, 0);
			p->releases        = array_make<Ast *>(temporary_allocator(), 0, 0);
			p->signal_acquires = array_make<Ast *>(temporary_allocator(), 0, 0);
			p->signal_releases = array_make<Ast *>(temporary_allocator(), 0, 0);
		}
		if (!fence) {
			continue;
		}
		Array<Ast *> *acquires = &p->acquires;
		Array<Ast *> *releases = &p->releases;
		if (a.id == BuiltinProc_atomic_signal_fence) {
			acquires = &p->signal_acquires;
			releases = &p->signal_releases;
		}
		OdinAtomicMemoryOrder order = check_atomic_order_of(a.call->CallExpr.args[0]);
		if (check_atomic_order_acquires(order)) {
			array_add(acquires, a.call);
		}
		if (check_atomic_order_releases(order)) {
			array_add(releases, a.call);
		}
	}

	PtrSet<DeclInfo *> covered_acquire = {};
	PtrSet<DeclInfo *> covered_release = {};
	defer (ptr_set_destroy(&covered_acquire));
	defer (ptr_set_destroy(&covered_release));
	for (auto &entry : procedures) {
		DeclInfo *decl = entry.key;
		AtomicProcedure *p = &entry.value;
		if (decl->proc_info == nullptr) {
			continue;
		}
		AtomicScan s = {};
		s.reads = array_make<Ast *>(temporary_allocator(), 0, 0);
		s.places = &p->places;
		check_atomic_scan(&s, decl->proc_info->body, false);

		for (auto const &place : p->places) {
			Entity *e = entity_of_node(place.key->CallExpr.proc);
			if (e == nullptr || e->kind != Entity_Procedure || e->decl_info == nullptr) {
				continue;
			}
			if (check_atomic_fenced(p, p->acquires, place.key, true)) {
				check_atomic_cover(&covered_acquire, e->decl_info);
			}
			if (check_atomic_fenced(p, p->releases, place.key, false)) {
				check_atomic_cover(&covered_release, e->decl_info);
			}
		}
	}

	auto write_sites = array_make<AtomicSite>(temporary_allocator(), 0, 0);
	auto wake_sites  = array_make<AtomicSite>(temporary_allocator(), 0, 0);

	PtrSet<Ast *> operated = {};
	ptr_set_init(&operated, atomics.count);
	defer (ptr_set_destroy(&operated));

	PtrMap<Entity *, AtomicLocal> locals = {};
	map_init(&locals, 0);
	defer (map_destroy(&locals));

	PtrMap<Entity *, Ast *> volatiles = {};
	map_init(&volatiles, 0);
	defer (map_destroy(&volatiles));

	for (CheckedAtomic const &a : atomics) {
		if (a.id == BuiltinProc_atomic_thread_fence || a.id == BuiltinProc_atomic_signal_fence) {
			continue;
		}
		if (a.id == BuiltinProc_volatile_load || a.id == BuiltinProc_volatile_store) {
			// NOTE(bill): the access is not atomic nor taking its address elsewhere
			Ast *ptr = check_atomic_address_of(a.call->CallExpr.args[0]);
			if (ptr == nullptr) {
				continue;
			}
			ptr_set_add(&operated, ptr);
			if (Entity *e = check_atomic_location(ptr->UnaryExpr.expr)) {
				Ast *site = nullptr;
				if (Ast **found = map_get(&volatiles, e)) {
					site = *found;
				}
				check_atomic_first(&site, a.call);
				map_set(&volatiles, e, site);
			}
			continue;
		}
		Ast *call = a.call;
		Ast *ptr = check_atomic_address_of(call->CallExpr.args[0]);
		if (ptr == nullptr) {
			continue;
		}
		ptr_set_add(&operated, ptr);

		// NOTE(bill): this means it not a "true" futex
		// as waiting with a timeout on what nothing wakes is deliberate
		Entity *l = nullptr;
		if (a.futex == ProcedureFutex_None) {
			l = check_atomic_local(ptr->UnaryExpr.expr);
		}
		if (l != nullptr && a.decl != nullptr) {
			AtomicLocal local = {};
			local.decl = a.decl;
			if (AtomicLocal *found = map_get(&locals, l)) {
				local = *found;
			}
			local.count += 1;
			check_atomic_first(&local.first, call);
			map_set(&locals, l, local);
		}
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
		switch (a.futex) {
		case ProcedureFutex_None:
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
			break;
		case ProcedureFutex_Wait:
			explicit_order = false;
			order = OdinAtomicMemoryOrder_relaxed;
			writes = false;
			break;
		case ProcedureFutex_Wake:
			if (a.decl != nullptr) {
				array_add(&wake_sites, AtomicSite{e, call, a.decl});
			}
			continue;
		}

		AtomicProcedure *p = nullptr;
		if (a.decl != nullptr) {
			p = map_get(&procedures, a.decl);
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
			bool acquires = check_atomic_order_acquires(order) || check_atomic_order_acquires(failure);
			if (!acquires && p != nullptr) {
				acquires = check_atomic_fenced(p, p->acquires, call, true);
			}
			if (!acquires && a.decl != nullptr) {
				acquires = ptr_set_exists(&covered_acquire, a.decl);
			}
			uses.acquires |= acquires;
			if (reported && check_atomic_order_acquires(order)) {
				check_atomic_first(&uses.asks_acquire, call);
			}
		}
		if (writes) {
			if (a.decl != nullptr) {
				array_add(&write_sites, AtomicSite{e, call, a.decl});
			}
			bool releases = check_atomic_order_releases(order);
			if (!releases && p != nullptr) {
				releases = check_atomic_fenced(p, p->releases, call, false);
			}
			if (!releases && a.decl != nullptr) {
				releases = ptr_set_exists(&covered_release, a.decl);
			}
			uses.releases |= releases;
			if (reported && check_atomic_order_releases(order)) {
				check_atomic_first(&uses.asks_release, call);
			}
		}
		map_set(&atomic_uses, e, uses);
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
				array_add(&reports, AtomicReport{AtomicReport_Release, uses.asks_release, uses.load});
			} else if (uses.asks_acquire != nullptr && uses.store != nullptr && !uses.releases) {
				array_add(&reports, AtomicReport{AtomicReport_Acquire, uses.asks_acquire, uses.store});
			}
		}

		for (CheckedAtomic const &a : atomics) {
			if (a.id != BuiltinProc_atomic_compare_exchange_weak && a.id != BuiltinProc_atomic_compare_exchange_weak_explicit) {
				continue;
			}
			if (a.decl == nullptr || !ast_file_analysis(a.call->file(), AnalysisFlag_Atomic)) {
				continue;
			}

			bool discards = a.call->CallExpr.optional_ok_one || !is_type_tuple(a.call->tav.type);
			AtomicProcedure *p = map_get(&procedures, a.decl);
			if (!discards && p != nullptr) {
				AtomicPlace *place = map_get(&p->places, a.call);
				discards = place != nullptr && place->discards;
			}
			if (discards) {
				array_add(&reports, AtomicReport{AtomicReport_WeakIgnored, a.call, nullptr});
			}
		}

		// NOTE(bill): A wake is early when the procedure only writes what it wakes after it and calls nothing before it which does
		for (AtomicSite const &wake : wake_sites) {
			AtomicProcedure *p = map_get(&procedures, wake.decl);
			if (p == nullptr || !ast_file_analysis(wake.call->file(), AnalysisFlag_Atomic)) {
				continue;
			}
			bool written = false;
			Ast *after = nullptr;
			for (AtomicSite const &w : write_sites) {
				if (w.location != wake.location || w.decl != wake.decl) {
					continue;
				}
				if (check_atomic_may_precede(p, w.call, wake.call)) {
					written = true;
				} else {
					check_atomic_first(&after, w.call);
				}
			}
			if (written || after == nullptr) {
				continue;
			}
			PtrSet<DeclInfo *> reached = {};
			for (auto const &place : p->places) {
				Entity *e = entity_of_node(place.key->CallExpr.proc);
				if (e != nullptr && e->kind == Entity_Procedure && e->decl_info != nullptr && check_atomic_may_precede(p, place.key, wake.call)) {
					check_atomic_cover(&reached, e->decl_info);
				}
			}
			for (AtomicSite const &w : write_sites) {
				written |= w.location == wake.location && ptr_set_exists(&reached, w.decl);
			}
			ptr_set_destroy(&reached);
			if (!written) {
				array_add(&reports, AtomicReport{AtomicReport_WakeEarly, wake.call, after});
			}
		}

		PtrSet<DeclInfo *> walked = {};
		for (auto const &entry : locals) {
			DeclInfo *decl = entry.value.decl;
			if (decl->proc_info == nullptr || ptr_set_update(&walked, decl)) {
				continue;
			}
			AtomicScan s = {};
			s.reads = array_make<Ast *>(temporary_allocator(), 0, 0);
			s.locals = &locals;
			check_atomic_scan(&s, decl->proc_info->body, false);
		}
		ptr_set_destroy(&walked);
		for (auto const &entry : locals) {
			if (entry.value.addressed == entry.value.count && ast_file_analysis(entry.value.first->file(), AnalysisFlag_Atomic)) {
				array_add(&reports, AtomicReport{AtomicReport_Local, entry.value.first, nullptr});
			}
		}

		for (auto const &entry : volatiles) {
			AtomicUses *uses = map_get(&atomic_uses, entry.key);
			if (uses != nullptr && ast_file_analysis(entry.value->file(), AnalysisFlag_Atomic)) {
				array_add(&reports, AtomicReport{AtomicReport_Volatile, entry.value, uses->first});
			}
		}

		// NOTE(bill): In order and once for what is at the same place in each instantiation of a polymorphic procedure
		array_sort(reports, check_atomic_report_cmp);
		for_array(i, reports) {
			AtomicReport const &r = reports[i];
			if (i > 0 && reports[i-1].kind == r.kind && ast_token(reports[i-1].site).pos == ast_token(r.site).pos) {
				continue;
			}

			ERROR_BLOCK();
			if (r.kind == AtomicReport_WeakIgnored) {
				gbString name = expr_to_string(r.site->CallExpr.proc);
				warning(r.site, "'%s' may fail even when the value matches, so only its second result says whether it stored", name);
				error_line("\tSuggestion: Use its second result, or the strong form when it is not retried\n");
				gb_string_free(name);
				continue;
			}
			if (r.kind == AtomicReport_Local) {
				Entity *l = check_atomic_local(check_atomic_address_of(r.site->CallExpr.args[0])->UnaryExpr.expr);
				warning(r.site, "The address of '%.*s' is only taken by atomic operations, so nothing else can access it, and they order nothing", LIT(l->token.string));
				error_line("\tSuggestion: To keep its accesses from being optimized away, use 'volatile_load' and 'volatile_store', which order nothing between threads\n");
				error_line("\t            If it is meant to be shared, it may be a copy of what is\n");
				continue;
			}

			gbString str = expr_to_string(check_atomic_address_of(r.site->CallExpr.args[0])->UnaryExpr.expr);
			char const *other = token_pos_to_string(ast_token(r.other).pos);

			AtomicProcedure *p = nullptr;
			for (auto &entry : procedures) {
				if (map_get(&entry.value.places, r.other) != nullptr) {
					p = &entry.value;
					break;
				}
			}

			switch (r.kind) {
			case AtomicReport_Release: {
				warning(r.site, "'%s' is written with release ordering, but it is only loaded with relaxed ordering, so the release orders nothing", str);
				Entity *e = entity_of_node(r.other->CallExpr.proc);
				if (e != nullptr && e->kind == Entity_Procedure && e->Procedure.futex == ProcedureFutex_Wait) {
					error_line("\tSuggestion: A futex wait does not acquire, so load it with .Acquire after the wait at %s, or write it with .Relaxed\n", other);
				} else {
					error_line("\tSuggestion: Load it with .Acquire, e.g. at %s, or write it with .Relaxed\n", other);
				}
				if (p != nullptr && check_atomic_fenced(p, p->signal_acquires, r.other, true)) {
					error_line("\t            'atomic_signal_fence' only orders against a signal handler on the same thread, unlike 'atomic_thread_fence'\n");
				}
				break;
			}
			case AtomicReport_Acquire:
				warning(r.site, "'%s' is read with acquire ordering, but it is only stored with relaxed ordering, so the acquire orders nothing", str);
				error_line("\tSuggestion: Store it with .Release, e.g. at %s, or read it with .Relaxed\n", other);
				if (p != nullptr && check_atomic_fenced(p, p->signal_releases, r.other, false)) {
					error_line("\t            'atomic_signal_fence' only orders against a signal handler on the same thread, unlike 'atomic_thread_fence'\n");
				}
				break;
			case AtomicReport_WakeEarly:
				warning(r.site, "'%s' is woken before it is written, so what waits on it may see it unchanged and sleep again", str);
				error_line("\tSuggestion: Wake it after the write at %s\n", other);
				break;
			case AtomicReport_Volatile: {
				gbString name = expr_to_string(r.site->CallExpr.proc);
				warning(r.site, "'%s' is accessed with '%s', which is not atomic, but it is accessed atomically, e.g. at %s", str, name, other);
				if (r.site->CallExpr.args.count == 1) {
					error_line("\tSuggestion: Use 'atomic_load_explicit' instead, with .Relaxed ordering or stronger\n");
				} else {
					error_line("\tSuggestion: Use 'atomic_store_explicit' instead, with .Relaxed ordering or stronger\n");
				}
				gb_string_free(name);
				break;
			}
			default:
				// what is reported above, or nothing
				GB_PANIC("Unhandled AtomicReportKind");
				break;
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
	if (!vetted || atomic_uses.count == 0) {
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
