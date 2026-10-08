// The analysis of atomic memory orderings, after every procedure body is checked. Each atomic operation on `&x` is
// on a location: a global, a static, or a field for every value of its struct, as which value it is cannot be known.
// What is written with release ordering but only loaded with relaxed ordering, or read with acquire ordering but only
// stored with relaxed ordering, orders nothing, and is warned about, unless the address of the location is taken
// elsewhere, as it may then be accessed through it. Only loads and stores are what it would pair with, as a
// read-modify-write asking for an ordering which nothing pairs with, e.g. to count, is harmless.
// A call to a procedure with `@(futex=.Wait)` is a relaxed load of what it waits on, as the OS only compares it, and
// one with `@(futex=.Wake)` accesses nothing; neither is taking its address elsewhere.
// A relaxed read acquires when an acquire fence may be reached after it: later in its procedure, in the same loop, in
// a `defer`, in what its procedure calls after it, directly or not, or in a procedure which calls its own before the
// fence. A relaxed write releases, likewise, when a release fence may be reached before it.
// Also warned about: a weak compare-exchange whose second result is not used, as it may fail even when the value
// matches; a futex woken before the procedure waking it writes it, as what waits on it may sleep again; and with an
// unpaired ordering, an `atomic_signal_fence` where an `atomic_thread_fence` would pair, as it only orders against a
// signal handler on the same thread.
// Atomics on a local whose address is only taken by them are warned about too, as nothing else can access it, so they
// order nothing; `volatile_*` is probably what is meant, to keep the accesses, or it is a copy of what is shared.
// A location accessed with `volatile_*` and atomically is warned about, as a volatile access is not atomic.
// Atomics on a @(thread_local) whose address is not taken are warned about, as only its own thread can access it.
// A store followed by a load of something else, with the reverse elsewhere, as in Dekker's algorithm, is warned about
// unless .Seq_Cst orders each, as acquire and release ordering lets both loads read what was there before.
// The same location accessed atomically with different sizes is warned about, as C11 leaves it undefined.
// With -vet-atomic-access, a plain read or write of a location accessed atomically is an error, unless a call before it
// to a procedure with `@(synchronizes=...)` acquires something which no call since releases, as within a lock, or for
// a write, a call after it releases something which no call since acquires, as starting a thread does. Only calls in
// branches which enclose it count, and deferred ones do not, and a call on what is not known, e.g. a lock without
// arguments, may release anything. `@(synchronizes_shared=...)`, as on a shared lock, only synchronizes reads. What a procedure without either synchronizes is inferred from what it calls: what it releases
// before it acquires it, as unlocking does, and what it acquires but does not release by some return, as locking does.

struct AtomicUses {
	Ast *first;        // the first atomic operation of each, by position
	Ast *load;
	Ast *store;
	Ast *asks_acquire; // explicitly, in a file with the analysis
	Ast *asks_release;
	Ast *smallest;     // the first of the smallest size, and of the largest
	Ast *largest;
	bool acquires;     // by any read, including with seq_cst ordering or a fence
	bool releases;
	bool escaped;
};

// one arm of a branch, of which only one runs
struct AtomicArm {
	Ast *branch;
	i32  arm;
};

struct AtomicPlace {
	Ast *            loop;     // the outermost loop it is within
	Slice<AtomicArm> arms;     // the branches it is within, outermost first
	bool             deferred;
	bool             discards; // its second result, as a statement or into `_`
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
	AtomicReport_ThreadLocal, // atomics on a @(thread_local) which only its own thread can access
	AtomicReport_StoreLoad,   // a store followed by a load of something else, and the reverse elsewhere
	AtomicReport_MixedSize,   // accessed atomically with different sizes
};

struct AtomicReport {
	AtomicReportKind kind;
	Ast *            site;
	Ast *            other; // what would pair with it, the write after the wake, or the reverse store
};

struct AtomicAccess {
	Entity *  location;
	Ast *     call;
	DeclInfo *decl;
	bool      store;
	bool      seq_cst;
};

struct AtomicStoreLoad {
	AtomicAccess const *store;
	AtomicAccess const *load;
};

// where something is, within the branches of its procedure
struct AtomicAt {
	Ast *            node;
	Slice<AtomicArm> arms;
};

struct AtomicObject {
	Entity *root; // NULL when not known, e.g. without arguments
	String  path;
};

struct AtomicSync {
	Ast *                 call;
	Slice<AtomicArm>      arms;
	AtomicObject          object;
	OdinAtomicMemoryOrder order;
	bool                  shared; // only reads
	bool                  deferred;
};

struct AtomicExit {
	isize            syncs;
	Slice<AtomicArm> arms;
};

struct AtomicEffect {
	i32                   param;  // the parameter `object.path` is within, or -1 for a global `object`
	AtomicObject          object;
	OdinAtomicMemoryOrder order;
	bool                  shared;
};

struct AtomicScan {
	Array<AtomicAt>   reads;  // plain reads and writes of what is accessed atomically
	Array<AtomicAt>   writes;
	Array<AtomicSync> syncs;

	PtrMap<Ast *, AtomicPlace> *places; // NULL when not used
	AtomicPlace                 place;
	Array<AtomicArm>            arms;

	PtrMap<Entity *, AtomicLocal> *locals; // NULL when not used

	Array<AtomicExit>  *exits;     // NULL when not used
	PtrSet<DeclInfo *> *inferring; // what may reach a call which synchronizes, NULL when not used
};

struct AtomicCallers {
	Checker *                              c;
	bool                                   found;
	PtrMap<DeclInfo *, Array<DeclInfo *> > map;
};

gb_global PtrMap<Entity *, AtomicUses> atomic_uses;
gb_global PtrMap<DeclInfo *, Slice<AtomicEffect> > atomic_effects; // with -vet-atomic-access


gb_internal void check_atomic_scan        (AtomicScan *s, Ast *node, bool addr);
gb_internal void check_atomic_scan_arm    (AtomicScan *s, Ast *branch, i32 arm, Ast *node);
gb_internal void check_atomic_scan_clauses(AtomicScan *s, Ast *node, Ast *body);
gb_internal void check_atomic_infer       (PtrSet<DeclInfo *> *inferring, DeclInfo *decl);

gb_internal Entity *check_atomic_field(Type *t, String const &name) {
	t = base_type(type_deref(t));
	if (t == nullptr || t->kind != Type_Struct) {
		return nullptr;
	}
	for (Entity *f : t->Struct.fields) {
		if (f->token.string == name) {
			return f;
		}
	}
	for (Entity *f : t->Struct.fields) {
		if ((f->flags & EntityFlag_Using) == 0) {
			continue;
		}
		if (Entity *found = check_atomic_field(f->type, name)) {
			return found;
		}
	}
	return nullptr;
}

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
				return check_atomic_field(e->using_parent->type, e->token.string);
			}
			if (!e->Variable.is_global && (e->flags & EntityFlag_Static) == 0) {
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

gb_internal Ast *check_atomic_call_argument(Ast *call, Entity *proc, isize index) {
	ast_node(ce, CallExpr, call);
	Type *pt = base_type(proc->type);
	if (pt->kind != Type_Proc || pt->Proc.params == nullptr || index >= pt->Proc.params->Tuple.variables.count) {
		return nullptr;
	}
	String name = pt->Proc.params->Tuple.variables[index]->token.string;
	for (Ast *a : ce->args) {
		if (a->kind == Ast_FieldValue && a->FieldValue.field->kind == Ast_Ident && a->FieldValue.field->Ident.token.string == name) {
			return a->FieldValue.value;
		}
	}
	if (index < ce->args.count && ce->args[index]->kind != Ast_FieldValue) {
		return ce->args[index];
	}
	return nullptr;
}

gb_internal Ast *check_atomic_call_pointer(Ast *call) {
	ast_node(ce, CallExpr, call);
	Entity *e = entity_of_node(ce->proc);
	if (e != nullptr && e->kind == Entity_Procedure && e->Procedure.futex != ProcedureFutex_None) {
		return check_atomic_call_argument(call, e, e->Procedure.futex_parameter);
	}
	if (ce->args.count > 0) {
		return ce->args[0];
	}
	return nullptr;
}

gb_internal AtomicObject check_atomic_object(Ast *expr) {
	expr = unparen_expr(expr);
	switch (expr->kind) {
	case_ast_node(ue, UnaryExpr, expr);
		if (ue->op.kind == Token_And) {
			return check_atomic_object(ue->expr);
		}
	case_end;

	case_ast_node(de, DerefExpr, expr);
		return check_atomic_object(de->expr);
	case_end;

	case_ast_node(i, Ident, expr);
		Entity *e = entity_of_node(expr);
		if (e == nullptr || e->kind != Entity_Variable) {
			break;
		}
		if (e->using_parent != nullptr) {
			return AtomicObject{e->using_parent, concatenate_strings(temporary_allocator(), str_lit("."), e->token.string)};
		}
		return AtomicObject{e, {}};
	case_end;

	case_ast_node(se, SelectorExpr, expr);
		Entity *pkg = entity_of_node(se->expr);
		if (pkg != nullptr && pkg->kind == Entity_ImportName) {
			return check_atomic_object(se->selector);
		}
		AtomicObject o = check_atomic_object(se->expr);
		if (o.root != nullptr && se->selector->kind == Ast_Ident) {
			o.path = concatenate3_strings(temporary_allocator(), o.path, str_lit("."), se->selector->Ident.token.string);
			return o;
		}
	case_end;

	case_ast_node(ie, IndexExpr, expr);
		AtomicObject o = check_atomic_object(ie->expr);
		if (o.root != nullptr) {
			gbString index = expr_to_string(ie->index);
			o.path = concatenate3_strings(temporary_allocator(), o.path, str_lit("["), make_string_c(index));
			o.path = concatenate_strings(temporary_allocator(), o.path, str_lit("]"));
			gb_string_free(index);
			return o;
		}
	case_end;
	}
	return {};
}

gb_internal bool check_atomic_same_object(AtomicObject const &a, AtomicObject const &b) {
	if (a.root == nullptr || b.root == nullptr) {
		return a.root == b.root;
	}
	if (a.root != b.root) {
		return false;
	}
	String outer = a.path;
	String inner = b.path;
	if (outer.len > inner.len) {
		gb_swap(String, outer, inner);
	}
	if (!string_starts_with(inner, outer)) {
		return false;
	}
	return inner.len == outer.len || inner[outer.len] == '.' || inner[outer.len] == '[';
}

gb_internal bool check_atomic_may_be_same_object(AtomicObject const &a, AtomicObject const &b) {
	return a.root == nullptr || b.root == nullptr || check_atomic_same_object(a, b);
}

gb_internal Ast *check_atomic_call_address(Ast *call) {
	Ast *arg = check_atomic_call_pointer(call);
	if (arg == nullptr) {
		return nullptr;
	}
	return check_atomic_address_of(arg);
}

gb_internal i64 check_atomic_call_size(Ast *call) {
	return type_size_of(type_deref(check_atomic_call_pointer(call)->tav.type));
}

gb_internal void check_atomic_sized(Ast **site, Ast *call, bool largest) {
	if (*site == nullptr) {
		*site = call;
		return;
	}
	i64 size = check_atomic_call_size(call);
	i64 other = check_atomic_call_size(*site);
	if ((largest && size > other) || (!largest && size < other) || (size == other && token_pos_cmp(ast_token(call).pos, ast_token(*site).pos) < 0)) {
		*site = call;
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

	isize n = gb_min(pa->arms.count, pb->arms.count);
	for (isize i = 0; i < n; i++) {
		if (pa->arms[i].branch != pb->arms[i].branch) {
			break;
		}
		if (pa->arms[i].arm != pb->arms[i].arm) {
			return false;
		}
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

gb_internal AtomicProcedure *check_atomic_procedure(PtrMap<DeclInfo *, AtomicProcedure> *procedures, DeclInfo *decl) {
	if (AtomicProcedure *p = map_get(procedures, decl)) {
		return p;
	}
	AtomicProcedure p = {};
	p.acquires        = array_make<Ast *>(temporary_allocator(), 0, 0);
	p.releases        = array_make<Ast *>(temporary_allocator(), 0, 0);
	p.signal_acquires = array_make<Ast *>(temporary_allocator(), 0, 0);
	p.signal_releases = array_make<Ast *>(temporary_allocator(), 0, 0);

	if (decl->proc_info != nullptr) {
		AtomicScan s = {};
		s.reads  = array_make<AtomicAt>  (temporary_allocator(), 0, 0);
		s.writes = array_make<AtomicAt>  (temporary_allocator(), 0, 0);
		s.syncs  = array_make<AtomicSync>(temporary_allocator(), 0, 0);
		s.arms   = array_make<AtomicArm> (temporary_allocator(), 0, 0);
		s.places = &p.places;
		check_atomic_scan(&s, decl->proc_info->body, false);
	}

	map_set(procedures, decl, p);

	return map_get(procedures, decl);
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

gb_internal bool check_atomic_reaches_fence(PtrMap<DeclInfo *, AtomicProcedure> *procedures, DeclInfo *decl, bool acquire) {
	PtrSet<DeclInfo *> reached = {};
	check_atomic_cover(&reached, decl);
	bool fenced = false;
	for (auto const &entry : *procedures) {
		bool has_fence = (acquire && entry.value.acquires.count > 0) || (!acquire && entry.value.releases.count > 0);
		fenced |= has_fence && ptr_set_exists(&reached, entry.key);
	}
	ptr_set_destroy(&reached);
	return fenced;
}

gb_internal bool check_atomic_fence_around(PtrMap<DeclInfo *, AtomicProcedure> *procedures, AtomicProcedure *p, Ast *call, bool acquire) {
	for (auto const &place : p->places) {
		Entity *e = entity_of_node(place.key->CallExpr.proc);
		if (e == nullptr || e->kind != Entity_Procedure || e->decl_info == nullptr) {
			continue;
		}
		if ((acquire && !check_atomic_may_precede(p, call, place.key)) || (!acquire && !check_atomic_may_precede(p, place.key, call))) {
			continue;
		}
		if (check_atomic_reaches_fence(procedures, e->decl_info, acquire)) {
			return true;
		}
	}
	return false;
}

gb_internal PtrMap<DeclInfo *, Array<DeclInfo *> > *check_atomic_callers(AtomicCallers *callers) {
	if (!callers->found) {
		callers->found = true;
		for (PerThreadArraySlot<ProcInfo *> &slot : callers->c->info.checked_bodies_queue.slots) {
			for (ProcInfo *pi : slot.array) {
				if (pi->decl == nullptr) {
					continue;
				}
				FOR_PTR_SET(e, pi->decl->deps) {
					if (e->kind != Entity_Procedure || e->decl_info == nullptr) {
						continue;
					}
					Array<DeclInfo *> *found = map_get(&callers->map, e->decl_info);
					if (found == nullptr) {
						map_set(&callers->map, e->decl_info, array_make<DeclInfo *>(temporary_allocator(), 0, 4));
						found = map_get(&callers->map, e->decl_info);
					}
					array_add(found, pi->decl);
				}
			}
		}
	}
	return &callers->map;
}

gb_internal bool check_atomic_fence_called_by(PtrMap<DeclInfo *, AtomicProcedure> *procedures, AtomicCallers *callers, DeclInfo *decl, bool acquire) {
	PtrMap<DeclInfo *, Array<DeclInfo *> > *map = check_atomic_callers(callers);
	auto queue = array_make<DeclInfo *>(temporary_allocator(), 0, 16);
	PtrSet<DeclInfo *> visited = {};
	array_add(&queue, decl);
	ptr_set_add(&visited, decl);
	bool fenced = false;
	for (isize i = 0; i < queue.count && !fenced; i++) {
		DeclInfo *callee = queue[i];
		Array<DeclInfo *> *found = map_get(map, callee);
		if (found == nullptr) {
			continue;
		}
		for (DeclInfo *caller : *found) {
			AtomicProcedure *p = check_atomic_procedure(procedures, caller);
			for (auto const &place : p->places) {
				Entity *e = entity_of_node(place.key->CallExpr.proc);
				if (e != nullptr && e->kind == Entity_Procedure && e->decl_info == callee && check_atomic_fence_around(procedures, p, place.key, acquire)) {
					fenced = true;
				}
			}
			if (!ptr_set_update(&visited, caller)) {
				array_add(&queue, caller);
			}
		}
	}
	ptr_set_destroy(&visited);
	return fenced;
}

gb_internal bool check_atomic_fence_called(PtrMap<DeclInfo *, AtomicProcedure> *procedures, AtomicCallers *callers, Array<AtomicSite> const &sites, Entity *location, bool acquire) {
	for (AtomicSite const &site : sites) {
		if (site.location != location) {
			continue;
		}
		AtomicProcedure *p = check_atomic_procedure(procedures, site.decl);
		if (check_atomic_fence_around(procedures, p, site.call, acquire) || check_atomic_fence_called_by(procedures, callers, site.decl, acquire)) {
			return true;
		}
	}
	return false;
}

gb_internal bool check_atomic_has_seq_cst_fence(AtomicProcedure const &p) {
	for (Ast *fence : p.acquires) {
		if (check_atomic_order_of(fence->CallExpr.args[0]) == OdinAtomicMemoryOrder_seq_cst) {
			return true;
		}
	}
	return false;
}

gb_internal bool check_atomic_seq_cst_ordered(PtrMap<DeclInfo *, AtomicProcedure> *procedures, AtomicStoreLoad const &sl) {
	if (sl.store->seq_cst && sl.load->seq_cst) {
		return true;
	}
	TokenPos from = ast_token(sl.store->call).pos;
	TokenPos to   = ast_token(sl.load->call).pos;
	AtomicProcedure *p = check_atomic_procedure(procedures, sl.store->decl);
	for (auto const &place : p->places) {
		Ast *call = place.key;
		TokenPos pos = ast_token(call).pos;
		if (token_pos_cmp(from, pos) >= 0 || token_pos_cmp(pos, to) >= 0) {
			continue;
		}
		for (Ast *fence : p->acquires) {
			if (fence == call && check_atomic_order_of(fence->CallExpr.args[0]) == OdinAtomicMemoryOrder_seq_cst) {
				return true;
			}
		}
		Entity *e = entity_of_node(call->CallExpr.proc);
		if (e == nullptr || e->kind != Entity_Procedure || e->decl_info == nullptr) {
			continue;
		}
		PtrSet<DeclInfo *> reached = {};
		check_atomic_cover(&reached, e->decl_info);
		bool fenced = false;
		for (auto const &entry : *procedures) {
			fenced |= check_atomic_has_seq_cst_fence(entry.value) && ptr_set_exists(&reached, entry.key);
		}
		ptr_set_destroy(&reached);
		if (fenced) {
			return true;
		}
	}
	return false;
}

gb_internal int check_atomic_access_cmp(void const *a, void const *b) {
	AtomicAccess const *x = cast(AtomicAccess const *)a;
	AtomicAccess const *y = cast(AtomicAccess const *)b;
	if (x->decl != y->decl) {
		if (cast(uintptr)x->decl < cast(uintptr)y->decl) {
			return -1;
		}
		return +1;
	}
	return token_pos_cmp(ast_token(x->call).pos, ast_token(y->call).pos);
}

gb_internal int check_atomic_store_load_cmp(void const *a, void const *b) {
	AtomicStoreLoad const *x = cast(AtomicStoreLoad const *)a;
	AtomicStoreLoad const *y = cast(AtomicStoreLoad const *)b;
	uintptr xs = cast(uintptr)x->store->location;
	uintptr ys = cast(uintptr)y->store->location;
	if (xs != ys) {
		if (xs < ys) {
			return -1;
		}
		return +1;
	}
	uintptr xl = cast(uintptr)x->load->location;
	uintptr yl = cast(uintptr)y->load->location;
	if (xl != yl) {
		if (xl < yl) {
			return -1;
		}
		return +1;
	}
	return 0;
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

gb_internal void check_atomic_add_syncs(AtomicScan *s, Ast *call, Entity *callee, Entity *proc, bool deferred) {
	AtomicSync sync = {};
	sync.call     = call;
	sync.deferred = deferred;
	if (proc->Procedure.synchronizes != OdinAtomicMemoryOrder_relaxed) {
		sync.arms   = slice_from_array(array_clone(temporary_allocator(), s->arms));
		sync.order  = cast(OdinAtomicMemoryOrder)proc->Procedure.synchronizes;
		sync.shared = proc->Procedure.synchronizes_shared;
		if (Ast *arg = check_atomic_call_argument(call, callee, 0)) {
			sync.object = check_atomic_object(arg);
		}
		array_add(&s->syncs, sync);
		return;
	}
	if (proc->decl_info == nullptr) {
		return;
	}
	if (s->inferring != nullptr && ptr_set_exists(s->inferring, proc->decl_info)) {
		check_atomic_infer(s->inferring, proc->decl_info);
	}
	Slice<AtomicEffect> *effects = map_get(&atomic_effects, proc->decl_info);
	if (effects == nullptr) {
		return;
	}
	for (AtomicEffect const &effect : *effects) {
		sync.arms   = slice_from_array(array_clone(temporary_allocator(), s->arms));
		sync.order  = effect.order;
		sync.shared = effect.shared;
		sync.object = effect.object;
		if (effect.param >= 0) {
			sync.object = {};
			if (Ast *arg = check_atomic_call_argument(call, callee, effect.param)) {
				AtomicObject o = check_atomic_object(arg);
				if (o.root != nullptr) {
					sync.object = AtomicObject{o.root, concatenate_strings(temporary_allocator(), o.path, effect.object.path)};
				}
			}
		}
		array_add(&s->syncs, sync);
	}
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
				array_add(&s->reads, AtomicAt{node, slice_from_array(array_clone(temporary_allocator(), s->arms))});
			}
		}
		break;
	case Ast_CallExpr:
		if (s->places != nullptr) {
			AtomicPlace call_place = s->place;
			call_place.arms = slice_from_array(array_clone(temporary_allocator(), s->arms));
			map_set(s->places, node, call_place);
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
			if (e != nullptr && e->kind == Entity_Procedure) {
				check_atomic_add_syncs(s, node, e, e, s->place.deferred);

				DeferredProcedure dp = e->Procedure.deferred_procedure;
				switch (dp.kind) {
				case DeferredProcedure_in:
				case DeferredProcedure_in_out:
				case DeferredProcedure_in_by_ptr:
				case DeferredProcedure_in_out_by_ptr:
					if (dp.entity != nullptr && dp.entity->kind == Entity_Procedure) {
						check_atomic_add_syncs(s, node, e, dp.entity, true);
					}
					break;
				}
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
		check_atomic_scan_arm(s, node, 0, te->x);
		check_atomic_scan_arm(s, node, 1, te->y);
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
		if (s->exits != nullptr) {
			array_add(s->exits, AtomicExit{s->syncs.count, slice_from_array(array_clone(temporary_allocator(), s->arms))});
		}
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
			if (as->op.kind != Token_Eq) {
				continue;
			}

			Entity *e = check_atomic_location(lhs);
			if (e != nullptr && map_get(&atomic_uses, e) != nullptr) {
				array_add(&s->writes, AtomicAt{lhs, slice_from_array(array_clone(temporary_allocator(), s->arms))});
			}
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
		check_atomic_scan_arm(s, node, 0, is->body);
		check_atomic_scan_arm(s, node, 1, is->else_stmt);
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
		if (s->exits != nullptr) {
			array_add(s->exits, AtomicExit{s->syncs.count, slice_from_array(array_clone(temporary_allocator(), s->arms))});
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
		check_atomic_scan_clauses(s, node, ss->body);
	case_end;

	case_ast_node(ss, TypeSwitchStmt, node);
		if (ss->tag != nullptr && ss->tag->kind == Ast_AssignStmt) {
			for (Ast *rhs : ss->tag->AssignStmt.rhs) {
				check_atomic_scan(s, rhs, false);
			}
		}
		check_atomic_scan_clauses(s, node, ss->body);
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

gb_internal void check_atomic_scan_arm(AtomicScan *s, Ast *branch, i32 arm, Ast *node) {
	array_add(&s->arms, AtomicArm{branch, arm});
	check_atomic_scan(s, node, false);
	array_pop(&s->arms);
}

gb_internal void check_atomic_scan_clauses(AtomicScan *s, Ast *node, Ast *body) {
	if (body == nullptr || body->kind != Ast_BlockStmt) {
		check_atomic_scan(s, body, false);
		return;
	}
	Slice<Ast *> const &clauses = body->BlockStmt.stmts;
	bool falls = false;
	for (Ast *clause : clauses) {
		if (clause->kind != Ast_CaseClause || clause->CaseClause.stmts.count == 0) {
			continue;
		}
		Ast *last = clause->CaseClause.stmts[clause->CaseClause.stmts.count-1];
		falls |= last->kind == Ast_BranchStmt && last->BranchStmt.token.kind == Token_fallthrough;
	}
	for_array(i, clauses) {
		if (falls) {
			check_atomic_scan(s, clauses[i], false);
		} else {
			check_atomic_scan_arm(s, node, cast(i32)i, clauses[i]);
		}
	}
}

gb_internal bool check_atomic_encloses(Slice<AtomicArm> const &outer, Slice<AtomicArm> const &inner) {
	if (outer.count > inner.count) {
		return false;
	}
	for_array(i, outer) {
		if (outer[i].branch != inner[i].branch || outer[i].arm != inner[i].arm) {
			return false;
		}
	}
	return true;
}

gb_internal bool check_atomic_synchronized(Array<AtomicSync> const &syncs, AtomicAt const &access, bool write) {
	TokenPos pos = ast_token(access.node).pos;
	for (AtomicSync const &a : syncs) {
		if (a.deferred || (write && a.shared) || !check_atomic_encloses(a.arms, access.arms)) {
			continue;
		}
		TokenPos at = ast_token(a.call).pos;
		bool undone = false;
		if (token_pos_cmp(at, pos) < 0 && check_atomic_order_acquires(a.order)) {
			// unlocked since
			for (AtomicSync const &r : syncs) {
				TokenPos rt = ast_token(r.call).pos;
				undone |= !r.deferred && check_atomic_encloses(r.arms, access.arms) &&
				          token_pos_cmp(at, rt) < 0 && token_pos_cmp(rt, pos) < 0 &&
				          check_atomic_order_releases(r.order) && check_atomic_may_be_same_object(a.object, r.object);
			}
		} else if (write && token_pos_cmp(pos, at) < 0 && check_atomic_order_releases(a.order)) {
			// the unlock of a lock taken since
			for (AtomicSync const &l : syncs) {
				TokenPos lt = ast_token(l.call).pos;
				undone |= !l.deferred && token_pos_cmp(pos, lt) < 0 && token_pos_cmp(lt, at) < 0 &&
				          check_atomic_order_acquires(l.order) && check_atomic_may_be_same_object(a.object, l.object);
			}
		} else {
			continue;
		}
		if (!undone) {
			return true;
		}
	}
	return false;
}

gb_internal void check_atomic_infer(PtrSet<DeclInfo *> *inferring, DeclInfo *decl) {
	Entity *pe = decl->entity;
	if (map_get(&atomic_effects, decl) != nullptr || decl->proc_info == nullptr || decl->proc_info->body == nullptr ||
	    (pe != nullptr && pe->kind == Entity_Procedure && pe->Procedure.synchronizes != OdinAtomicMemoryOrder_relaxed)) {
		return;
	}
	// nothing, while within itself
	map_set(&atomic_effects, decl, Slice<AtomicEffect>{});

	ProcInfo *pi = decl->proc_info;
	auto exits = array_make<AtomicExit>(temporary_allocator(), 0, 0);
	AtomicScan s = {};
	s.reads     = array_make<AtomicAt>  (temporary_allocator(), 0, 0);
	s.writes    = array_make<AtomicAt>  (temporary_allocator(), 0, 0);
	s.syncs     = array_make<AtomicSync>(temporary_allocator(), 0, 0);
	s.arms      = array_make<AtomicArm> (temporary_allocator(), 0, 0);
	s.exits     = &exits;
	s.inferring = inferring;
	check_atomic_scan(&s, pi->body, false);
	Slice<Ast *> const &stmts = pi->body->BlockStmt.stmts;
	if (stmts.count == 0 || stmts[stmts.count-1]->kind != Ast_ReturnStmt) {
		array_add(&exits, AtomicExit{s.syncs.count, {}});
	}

	Type *pt = base_type(pi->type);
	auto effects = array_make<AtomicEffect>(temporary_allocator(), 0, 0);
	for_array(i, s.syncs) {
		AtomicObject const &object = s.syncs[i].object;
		bool seen = false;
		for (isize j = 0; j < i; j++) {
			seen |= check_atomic_same_object(s.syncs[j].object, object);
		}
		if (seen) {
			continue;
		}

		AtomicEffect effect = {-1, object, OdinAtomicMemoryOrder_relaxed, true};
		bool releases = false;
		bool acquired = false;
		for (isize j = i; j < s.syncs.count; j++) {
			AtomicSync const &r = s.syncs[j];
			if (!check_atomic_same_object(r.object, object)) {
				continue;
			}
			if (!acquired && check_atomic_order_releases(r.order)) {
				releases = true;
				effect.shared &= r.shared;
			}
			acquired |= !r.deferred && check_atomic_order_acquires(r.order);
		}
		bool acquires = false;
		for (AtomicExit const &exit : exits) {
			for (isize j = 0; j < exit.syncs; j++) {
				AtomicSync const &a = s.syncs[j];
				if (a.deferred || !check_atomic_order_acquires(a.order) || !check_atomic_same_object(a.object, object) || !check_atomic_encloses(a.arms, exit.arms)) {
					continue;
				}
				bool released = false;
				for (isize k = 0; k < exit.syncs; k++) {
					AtomicSync const &r = s.syncs[k];
					released |= (r.deferred || (k > j && check_atomic_encloses(r.arms, exit.arms))) &&
					            check_atomic_order_releases(r.order) && check_atomic_may_be_same_object(r.object, object);
				}
				if (!released) {
					acquires = true;
					effect.shared &= a.shared;
				}
			}
		}
		if (acquires && releases) {
			effect.order = OdinAtomicMemoryOrder_acq_rel;
		} else if (acquires) {
			effect.order = OdinAtomicMemoryOrder_acquire;
		} else if (releases) {
			effect.order = OdinAtomicMemoryOrder_release;
		} else {
			continue;
		}

		Entity *root = object.root;
		if (root == nullptr) {
			// NOTE(bill): not known to what calls it either
		} else if ((root->flags & EntityFlag_Param) != 0) {
			for (isize k = 0; pt->kind == Type_Proc && pt->Proc.params != nullptr && k < pt->Proc.params->Tuple.variables.count; k++) {
				if (pt->Proc.params->Tuple.variables[k] == root) {
					effect.param = cast(i32)k;
				}
			}
			if (effect.param < 0) {
				continue;
			}
		} else if (!root->Variable.is_global && (root->flags & EntityFlag_Static) == 0) {
			continue;
		}
		array_add(&effects, effect);
	}
	map_set(&atomic_effects, decl, slice_from_array(effects));
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
		s.reads  = array_make<AtomicAt>  (temporary_allocator(), 0, 0);
		s.writes = array_make<AtomicAt>  (temporary_allocator(), 0, 0);
		s.syncs  = array_make<AtomicSync>(temporary_allocator(), 0, 0);
		s.arms   = array_make<AtomicArm> (temporary_allocator(), 0, 0);
		check_atomic_scan(&s, body, false);
		if (s.reads.count == 0 && s.writes.count == 0) {
			continue;
		}

		ErrorInstantiations prev_instantiations = global_error_context.instantiations;
		global_error_context.instantiations = {pi->generated_from_polymorphic ? pi : pi->poly_parent, nullptr};
		for (AtomicAt const &at : s.writes) {
			if (check_atomic_synchronized(s.syncs, at, true)) {
				continue;
			}
			Ast *write = at.node;
			AtomicUses *uses = map_get(&atomic_uses, check_atomic_location(write));
			ERROR_BLOCK();
			gbString str = expr_to_string(write);
			error(write, "'%s' is written plainly, but it is accessed atomically, e.g. at %s", str, token_pos_to_string(ast_token(uses->first).pos));
			error_line("\tSuggestion: Write it with 'atomic_store_explicit(&%s, ..., .Relaxed)', or take a lock around it\n", str);
			gb_string_free(str);
		}
		for (AtomicAt const &at : s.reads) {
			if (check_atomic_synchronized(s.syncs, at, false)) {
				continue;
			}
			Ast *read = at.node;
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

	AtomicCallers callers = {};
	callers.c = c;
	defer (map_destroy(&callers.map));
	for (CheckedAtomic const &a : atomics) {
		bool fence = a.id == BuiltinProc_atomic_thread_fence || a.id == BuiltinProc_atomic_signal_fence;
		bool weak  = a.id == BuiltinProc_atomic_compare_exchange_weak || a.id == BuiltinProc_atomic_compare_exchange_weak_explicit;
		if (a.decl == nullptr || !(fence || weak || a.futex == ProcedureFutex_Wake)) {
			continue;
		}
		AtomicProcedure *p = check_atomic_procedure(&procedures, a.decl);
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
		AtomicProcedure *p = &entry.value;
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

	auto write_sites    = array_make<AtomicSite>  (temporary_allocator(), 0, 0);
	auto wake_sites     = array_make<AtomicSite>  (temporary_allocator(), 0, 0);
	auto relaxed_reads  = array_make<AtomicSite>  (temporary_allocator(), 0, 0); // which nothing acquires for, yet
	auto relaxed_writes = array_make<AtomicSite>  (temporary_allocator(), 0, 0);
	auto accesses       = array_make<AtomicAccess>(temporary_allocator(), 0, 0);

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
			Ast *ptr = check_atomic_call_address(a.call);
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
		Ast *ptr = check_atomic_call_address(call);
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
		if (a.futex == ProcedureFutex_None && a.decl != nullptr && reads != writes) {
			array_add(&accesses, AtomicAccess{e, call, a.decl, writes, order == OdinAtomicMemoryOrder_seq_cst});
		}

		check_atomic_first(&uses.first, call);
		check_atomic_sized(&uses.smallest, call, false);
		check_atomic_sized(&uses.largest, call, true);

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
			if (!acquires && a.decl != nullptr) {
				array_add(&relaxed_reads, AtomicSite{e, call, a.decl});
			}
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
			if (!releases && a.decl != nullptr) {
				array_add(&relaxed_writes, AtomicSite{e, call, a.decl});
			}
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
			if (check_atomic_call_size(uses.smallest) != check_atomic_call_size(uses.largest) && ast_file_analysis(uses.largest->file(), AnalysisFlag_Atomic)) {
				array_add(&reports, AtomicReport{AtomicReport_MixedSize, uses.largest, uses.smallest});
			}
			if (uses.escaped) {
				continue;
			}

			if (entry.key->Variable.thread_local_model.len != 0) {
				if (ast_file_analysis(uses.first->file(), AnalysisFlag_Atomic)) {
					array_add(&reports, AtomicReport{AtomicReport_ThreadLocal, uses.first, nullptr});
				}
				continue;
			}

			// asking for acquire ordering acquires, so at most one of these
			// a fence within what is called is only looked for here, as finding what each call may reach is not cheap
			if (uses.asks_release != nullptr && uses.load != nullptr && !uses.acquires && !check_atomic_fence_called(&procedures, &callers, relaxed_reads, entry.key, true)) {
				array_add(&reports, AtomicReport{AtomicReport_Release, uses.asks_release, uses.load});
			} else if (uses.asks_acquire != nullptr && uses.store != nullptr && !uses.releases && !check_atomic_fence_called(&procedures, &callers, relaxed_writes, entry.key, false)) {
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
				} else if (check_atomic_may_precede(p, wake.call, w.call)) {
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
			s.reads  = array_make<AtomicAt>  (temporary_allocator(), 0, 0);
			s.writes = array_make<AtomicAt>  (temporary_allocator(), 0, 0);
			s.syncs  = array_make<AtomicSync>(temporary_allocator(), 0, 0);
			s.arms   = array_make<AtomicArm> (temporary_allocator(), 0, 0);
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

		// each store followed by a load of something else within a procedure, which a reverse pair, in another, makes
		// a problem unless both are ordered by .Seq_Cst
		array_sort(accesses, check_atomic_access_cmp);
		auto store_loads = array_make<AtomicStoreLoad>(temporary_allocator(), 0, 0);
		for_array(i, accesses) {
			AtomicAccess const &store = accesses[i];
			if (!store.store) {
				continue;
			}
			for (isize j = i+1; j < accesses.count && accesses[j].decl == store.decl; j++) {
				AtomicAccess const &load = accesses[j];
				if (!load.store && load.location != store.location) {
					array_add(&store_loads, AtomicStoreLoad{&store, &load});
				}
			}
		}
		array_sort(store_loads, check_atomic_store_load_cmp);
		for (isize i = 0; i < store_loads.count; /**/) {
			isize start = i;
			while (i < store_loads.count && check_atomic_store_load_cmp(&store_loads[i], &store_loads[start]) == 0) {
				i += 1;
			}
			AtomicStoreLoad const &x = store_loads[start];

			if (cast(uintptr)x.store->location > cast(uintptr)x.load->location) {
				continue;
			}

			AtomicAccess reverse_store = {};
			AtomicAccess reverse_load  = {};
			reverse_store.location = x.load->location;
			reverse_load.location  = x.store->location;

			AtomicStoreLoad reverse = {&reverse_store, &reverse_load};

			isize lo = 0;
			isize hi = store_loads.count;

			while (lo < hi) {
				isize mid = lo + (hi-lo)/2;
				if (check_atomic_store_load_cmp(&store_loads[mid], &reverse) < 0) {
					lo = mid+1;
				} else {
					hi = mid;
				}
			}
			isize end = lo;
			while (end < store_loads.count && check_atomic_store_load_cmp(&store_loads[end], &reverse) == 0) {
				end += 1;
			}
			if (lo == end) {
				continue;
			}

			// NOTE(bill): the first store which .Seq_Cst does not order on either side, and the first store of the other side
			Ast *x_unordered = nullptr;
			Ast *y_unordered = nullptr;
			Ast *x_first = nullptr;
			Ast *y_first = nullptr;
			for (isize k = start; k < i; k++) {
				AtomicStoreLoad const &sl = store_loads[k];
				if (!check_atomic_may_precede(check_atomic_procedure(&procedures, sl.store->decl), sl.store->call, sl.load->call)) {
					continue;
				}
				check_atomic_first(&x_first, sl.store->call);
				if (!check_atomic_seq_cst_ordered(&procedures, sl)) {
					check_atomic_first(&x_unordered, sl.store->call);
				}
			}
			for (isize k = lo; k < end; k++) {
				AtomicStoreLoad const &sl = store_loads[k];
				if (!check_atomic_may_precede(check_atomic_procedure(&procedures, sl.store->decl), sl.store->call, sl.load->call)) {
					continue;
				}
				check_atomic_first(&y_first, sl.store->call);
				if (!check_atomic_seq_cst_ordered(&procedures, sl)) {
					check_atomic_first(&y_unordered, sl.store->call);
				}
			}
			if (x_first == nullptr || y_first == nullptr) {
				continue;
			}
			Ast *site = x_unordered;
			Ast *other = y_first;
			if (site == nullptr || (y_unordered != nullptr && token_pos_cmp(ast_token(y_unordered).pos, ast_token(site).pos) < 0)) {
				site = y_unordered;
				other = x_first;
			}
			if (site != nullptr && ast_file_analysis(site->file(), AnalysisFlag_Atomic)) {
				array_add(&reports, AtomicReport{AtomicReport_StoreLoad, site, other});
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
			if (r.kind == AtomicReport_ThreadLocal) {
				Entity *e = check_atomic_location(check_atomic_call_address(r.site)->UnaryExpr.expr);
				warning(r.site, "'%.*s' is @(thread_local) and its address is not taken, so only its own thread can access it, and the atomics on it order nothing", LIT(e->token.string));
				error_line("\tSuggestion: If it is meant to be shared between threads, it cannot be @(thread_local)\n");
				continue;
			}
			if (r.kind == AtomicReport_Local) {
				Entity *l = check_atomic_local(check_atomic_call_address(r.site)->UnaryExpr.expr);
				warning(r.site, "The address of '%.*s' is only taken by atomic operations, so nothing else can access it, and they order nothing", LIT(l->token.string));
				error_line("\tSuggestion: To keep its accesses from being optimized away, use 'volatile_load' and 'volatile_store', which order nothing between threads\n");
				error_line("\t            If it is meant to be shared, it may be a copy of what is\n");
				continue;
			}

			gbString str = expr_to_string(check_atomic_call_address(r.site)->UnaryExpr.expr);
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
			case AtomicReport_MixedSize:
				warning(check_atomic_call_pointer(r.site), "'%s' is accessed atomically as %lld bytes, but as %lld bytes at %s, which C11 leaves undefined", str, cast(long long)check_atomic_call_size(r.site), cast(long long)check_atomic_call_size(r.other), other);
				error_line("\tSuggestion: Access it atomically with one size everywhere\n");
				break;
			case AtomicReport_StoreLoad: {
				gbString other_str = expr_to_string(check_atomic_call_address(r.other)->UnaryExpr.expr);
				warning(check_atomic_call_address(r.site), "'%s' is stored and then '%s' loaded, while the reverse is done at %s, so both loads may read what was there before", str, other_str, other);
				error_line("\tSuggestion: Use .Seq_Cst for these stores and loads, or 'atomic_thread_fence(.Seq_Cst)' between each store and the load after it\n");
				gb_string_free(other_str);
				break;
			}
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

	bool vetted = (build_context.vet_flags & VetFlag_AtomicAccess) != 0;
	for (auto const &entry : c->info.files) {
		AstFile *f = entry.value;
		vetted |= f->vet_flags_set && (f->vet_flags & VetFlag_AtomicAccess) != 0;
	}
	if (!vetted || atomic_uses.count == 0) {
		return;
	}

	map_init(&atomic_effects, 0);
	defer ({
		map_destroy(&atomic_effects);
		atomic_effects = {};
	});
	PtrSet<DeclInfo *> inferring = {};
	defer (ptr_set_destroy(&inferring));
	PtrMap<DeclInfo *, Array<DeclInfo *> > *callers_of = check_atomic_callers(&callers);
	auto queue = array_make<DeclInfo *>(temporary_allocator(), 0, 16);
	for (auto const &entry : *callers_of) {
		Entity *e = entry.key->entity;
		if (e == nullptr || e->kind != Entity_Procedure || e->Procedure.synchronizes == OdinAtomicMemoryOrder_relaxed) {
			continue;
		}
		for (DeclInfo *caller : entry.value) {
			if (!ptr_set_update(&inferring, caller)) {
				array_add(&queue, caller);
			}
		}
	}
	for (isize i = 0; i < queue.count; i++) {
		Array<DeclInfo *> *found = map_get(callers_of, queue[i]);
		for (isize j = 0; found != nullptr && j < found->count; j++) {
			if (!ptr_set_update(&inferring, (*found)[j])) {
				array_add(&queue, (*found)[j]);
			}
		}
	}
	FOR_PTR_SET(decl, inferring) {
		check_atomic_infer(&inferring, decl);
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
