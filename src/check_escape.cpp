// Whatever is unknown, e.g. the result of a call through a procedure value, is assumed to not point into the stack frame
// An explicit conversion to 'rawptr' or 'uintptr', or a 'transmute', opts out
// A call uses a summary of what of its arguments may reach its results, analysing the callee first if it must

enum EscapeStepKind : u8 {
	EscapeStep_Invalid,
	EscapeStep_Field,
	EscapeStep_AnyElement,
	EscapeStep_Deref, // into what the pointer at the path so far points to
};

struct EscapeStep {
	EscapeStepKind kind;
	Entity *       field;
};

// immutable once made, so paths share their steps
typedef Slice<EscapeStep> EscapePath;

struct EscapeObject {
	Entity *entity;
	Ast *   temp;
};

enum EscapeOriginKind : u8 {
	EscapeOrigin_Invalid,
	EscapeOrigin_Outer,     // e.g. a global, named by `obj` and `path` when known
	EscapeOrigin_Local,
	EscapeOrigin_Temp,
	EscapeOrigin_Owned,     // the buffer of a local dynamic array or map, tracked as its contents
	EscapeOrigin_Variadic,
	EscapeOrigin_Param,     // what the pointers a parameter holds at its path point to, which is the caller's
	EscapeOrigin_ParamLoad, // what the pointers loaded once through them point to
	EscapeOrigin_ParamDeep, // what is reached by loading through them more than once
};

// what of an argument flows, e.g. what it loads through a dynamic array or map is its buffer
enum EscapeFlowKind : u8 {
	EscapeFlow_Invalid,
	EscapeFlow_Value, // the pointers of the argument, or offsets of them
	EscapeFlow_Load,  // the pointers loaded once through them
	EscapeFlow_Write, // of no argument: the callers take what it may write over as cleared
};

enum EscapeFlowTargetKind : u8 {
	EscapeFlowTarget_Invalid,
	EscapeFlowTarget_Result,
	EscapeFlowTarget_Pointee, // what an argument points to
	EscapeFlowTarget_Loaded,  // what a pointer loaded once through an argument points to
	EscapeFlowTarget_Deep,    // what is reached by loading through an argument more than once
	EscapeFlowTarget_Outer,   // e.g. a global
};

// what an argument holds at a path may reach a result of the call, or be stored where it outlives the call
struct EscapeFlow {
	EscapeFlowKind       kind;
	isize                param;
	EscapePath           param_path;
	EscapeFlowTargetKind target;
	isize                target_index; // of the result, or of the argument it is stored through
	EscapePath           target_path;  // within the result, or of the pointer within that argument
	EscapePath           value_path;   // within what is stored through a loaded pointer, where the argument's pointers are
	Entity *             global;       // of an outer target when known: the target and value paths are then within it
};

struct EscapeOrigin {
	EscapeOriginKind kind;
	bool             offset_lost; // an offset into the memory of a 'ParamLoad' or 'ParamDeep' was dropped
	EscapeObject     obj;
	EscapePath       path;
	Ast *            site;        // where the address of a 'Local' was taken, not part of its identity
};

struct EscapeValueFact {
	EscapePath   path;
	EscapeOrigin origin;
	bool         definite; // straight from the expression itself, not read back from a variable or through a pointer
};
typedef Array<EscapeValueFact> EscapeValue;

struct EscapeFact {
	EscapeObject obj;
	EscapePath   path;
	EscapeOrigin origin;
};

// a place within a variable, which is exact when a store to it replaces all it holds, e.g. not any element of an array
struct EscapeLocation {
	Entity *   root;
	EscapePath path;
	bool       exact;
};

struct EscapeOuterStore {
	EscapeLocation location;
	Ast *          node;       // the left hand side, or a call storing into memory it was given, unless what is stored is the caller's
	EscapeOrigin   dest;       // what it is stored through
	EscapeOrigin   origin;     // of what is stored
	EscapePath     value_path; // where in what is stored the pointer of that origin is
};

// what is at the path within a local is nil on every path reaching here, as is all of it, with -vet-nil-deref; or,
// with -vet-uninitialized, has had nothing stored in it since it was declared with `---`
struct EscapeNil {
	Entity *   e;
	EscapePath path;
	bool       uninit;
};

enum EscapeAtomKind : u8 {
	EscapeAtom_Zero,
	EscapeAtom_Local, // an integer local `escape_bounds_entity` allows
	EscapeAtom_Len,   // the length of such a local slice, string or dynamic array
	EscapeAtom_End,   // the length of the slice or string a range statement goes over, as it began

	EscapeAtom_NonZero, // only as the `b` of a limit, which is then that its `a` is not zero
};

struct EscapeAtom {
	EscapeAtomKind kind;
	Entity *       e;
	Ast *          stmt;
	Ast *          field; // of `e`, e.g. `e.a.b`
};

struct EscapeLimit {
	enum : i64 { MAX_K = 1ll<<42 };

	EscapeAtom a; // holds minus what `b` holds
	EscapeAtom b;
	i64        k; // at most `k`, itself within `MAX_K` of zero

	// NOTE(bill): as integers of no size meaning nothing wraps
};

struct EscapeState {
	bool                    reachable;
	Array<EscapeFact>       facts;
	Array<EscapeOuterStore> outers;
	Array<EscapeOuterStore> cleared; // from `outers` on a path reaching here: dropped from the other paths it joins
	Array<EscapeNil>        nils;
	Array<Ast *>            checks; // index and slice expressions whose bounds checks passed on every path reaching here, with what they read unchanged since
	Array<EscapeLimit>      limits; // known on every path reaching here, of what was not assigned since
};

struct EscapeRefine {
	Ast *cond;
	bool truth;
};

// what `escape_scan` looks at in an expression before it is evaluated
enum EscapeScanFlag : u8 {
	EscapeScan_Nil    = 1<<0, // its dereferences of what is nil, and reads of what is unset
	EscapeScan_Bounds = 1<<1, // its bounds checks
	EscapeScan_Fact   = 1<<2, // evaluated whenever its statement is, so its checks pass once the statement is done
	EscapeScan_Addr   = 1<<3, // only its address is taken, which reads nothing but what it is reached through

	EscapeScan_Stmt = EscapeScan_Nil|EscapeScan_Bounds|EscapeScan_Fact,
};

struct EscapeBoundsCheck {
	Ast *               node;
	bool                fact;    // evaluated whenever its statement is, so its check passed once the statement is done
	Slice<EscapeRefine> context; // what holds where it is evaluated, past what held before its statement
};

enum EscapeTargetKind : u8 {
	EscapeTarget_Invalid,
	EscapeTarget_Labelled, // a block or if statement, which only a labelled break exits
	EscapeTarget_Loop,
	EscapeTarget_Switch,
};

struct EscapeTarget {
	EscapeTargetKind kind;
	Ast *            stmt;
	isize            defer_depth;
	EscapeState      breaks;
	EscapeState      continues;
};

enum EscapeUpdateKind : u8 {
	EscapeUpdate_Invalid,
	EscapeUpdate_Replace,
	EscapeUpdate_Add,
};

enum EscapeReportKind : u8 {
	EscapeReport_Invalid,
	EscapeReport_Return, // definitely, so an error
	EscapeReport_MayReturn,
	EscapeReport_Store,
	EscapeReport_CallStore,
	EscapeReport_NilDeref,
	EscapeReport_NilCall,
	EscapeReport_UninitRead,
};

struct EscapeReport {
	EscapeReportKind kind;
	Ast *            node;
	String           expr_str;
	EscapeOrigin     origin;
	String           held;     // where the pointer is within what is returned, e.g. `'x.a.b'`, or empty for all of it
	String           target;   // where the pointer points within a local, e.g. `x.c`, or empty for all of it
	bool             self_ref; // what is returned is the local it points into
};

struct EscapeAlias {
	Entity *     e;
	EscapeOrigin origin;
};

// a dereference, or a call through a procedure value, and whether what it goes through is nil there; a read, and
// whether nothing has been stored in what it reads; or a bounds check, and whether it is proven to pass there. Each is
// reported, or left out, only when that holds every time it is reached, e.g. in a defer run at several exits
struct EscapeUse {
	Ast *            node;
	EscapeReportKind kind; // invalid for a bounds check
	bool             holds;
};

struct EscapeGraph {
	Array<ProcInfo *>         procs;          // a procedure's index is kept on its decl, see `DeclInfo::escape_index`
	Array<i32>                offsets;        // procedure -> the procedures it may call, as `targets[offsets[v]..<offsets[v+1]]`
	Array<i32>                targets;
	Array<i32>                caller_offsets; // procedure -> the procedures which may call it, as `callers[caller_offsets[v]..<caller_offsets[v+1]]`, when threaded
	Array<i32>                callers;
	Array<i32>                group_of;
	Array<i32>                group_offsets;  // group -> its procedures, as `members[group_offsets[gi]..<group_offsets[gi+1]]`
	Array<i32>                members;        // every group a group may call has a lower index
	Array<bool>               skipped;        // per procedure, neither in a file with the escape analysis nor called from one
	Slice<std::atomic<i32> >  pending;        // per group its calls to procedures of other groups which are not analysed yet
	Slice<std::atomic<i32> >  cursors;        // per procedure while `targets` is filled
	bool                      threaded;
};

struct EscapeMemberTask {
	EscapeGraph *       graph;
	i32                 v;
	bool                stale;   // as the flows of one it calls changed
	Slice<EscapeFlow>   flows;
	Array<EscapeReport> reports; // of its latest analysis
	Array<i32>          callers; // the members of the group calling it, by their index
};

struct EscapeAnalysis {
	TypeProc *           pt;
	Entity *             variadic;
	EscapeState          state;
	EscapeState          fallthrough;
	Array<Array<Ast *> > defers;
	isize                defers_floor; // the levels of `defers` below it are running
	Array<EscapeTarget>  targets;
	Array<EscapeAlias>   aliases;
	Array<Ast *>         reported;
	Array<EscapeUse>     uses;
	Array<EscapeFlow>    flows;
	EscapeGraph *        graph;
	i32                  group;       // of the procedures being analysed together, see `EscapeGraph`
	Array<EscapeReport> *reports;     // kept rather than reported until it is done, see `escape_analyse`
	bool                 muted;       // the entry point of an executable, which only returns as the program ends
	isize                stmt_visits;
	bool                 too_large;   // see `escape_too_large` and `escape_analyse`
	bool                 calls_unknown; // what the calls do, after growing too large with it
	Ast *                addr_site;   // the outermost expression whose address is being taken

	bool                 nil_deref;    // -vet-nil-deref
	bool                 uninit;       // -vet-uninitialized
	Array<Entity *>      nil_escaped;  // locals whose address was taken, which anything may change from then on
	Array<Entity *>      uninit_decls; // locals declared with `---`, whose reads are kept

	// bounds checks made again on what passed one before are left out
	bool                     bounds;
	bool                     bounds_off;     // within `#no_bounds_check`
	bool                     bounds_exits;   // the statement may leave part way, e.g. with `or_return`
	Array<EscapeBoundsCheck> bounds_found;   // of the statement being analysed
	Array<Entity *>          bounds_escaped; // locals whose address was taken
	Array<EscapeRefine>      bounds_context; // of the part of the expression being scanned
};

gb_global EscapeGraph escape_graph;

gb_internal Slice<i32> escape_callees(EscapeGraph *g, i32 v) {
	return slice(g->targets, g->offsets[v], g->offsets[v+1]);
}

gb_internal Slice<i32> escape_callers(EscapeGraph *g, i32 v) {
	return slice(g->callers, g->caller_offsets[v], g->caller_offsets[v+1]);
}


gb_internal EscapeValue        escape_expr         (EscapeAnalysis *ea, Ast *expr);
gb_internal EscapeValue        escape_addr         (EscapeAnalysis *ea, Ast *expr);
gb_internal EscapeValue        escape_ident_value  (EscapeAnalysis *ea, Entity *e);
gb_internal Array<EscapeValue> escape_call         (EscapeAnalysis *ea, Ast *call);
gb_internal void               escape_store_through(EscapeAnalysis *ea, Ast *node, EscapeValue const &ptr, EscapeValue const &v, EscapeUpdateKind update);
gb_internal void               escape_scan         (EscapeAnalysis *ea, Ast *expr, u8 flags);
gb_internal void               escape_stmt         (EscapeAnalysis *ea, Ast *node);
gb_internal void               escape_branch       (EscapeAnalysis *ea, Ast *label, TokenKind kind);
gb_internal void               escape_exit         (EscapeAnalysis *ea, Ast *node, Slice<Ast *> const &results, Array<EscapeValue> const &values);

// see checker_global.cpp
gb_internal i32  global_graph_scc(i32 node_count, Array<i32> const &offsets,   Array<i32> const &targets, Array<i32> *comp_of_);
gb_internal void global_graph_csr(i32 node_count, Array<i32> const &edge_from, Array<i32> const &edge_to, Array<i32> *offsets, Array<i32> *targets);


gb_internal bool escape_path_has_prefix(EscapePath const &p, EscapePath const &prefix) {
	if (prefix.count > p.count) {
		return false;
	}
	for_array(i, prefix) {
		if (p[i].kind  != prefix[i].kind ||
		    p[i].field != prefix[i].field) {
			return false;
		}
	}
	return true;
}

gb_internal bool escape_path_eq(EscapePath const &a, EscapePath const &b) {
	return a.count == b.count && escape_path_has_prefix(a, b);
}

// one is within the other
gb_internal bool escape_paths_overlap(EscapePath const &a, EscapePath const &b) {
	return escape_path_has_prefix(a, b) || escape_path_has_prefix(b, a);
}

gb_internal EscapePath escape_path_of(EscapeStepKind kind, Entity *field=nullptr) {
	auto p = slice_make<EscapeStep>(temporary_allocator(), 1);
	p[0] = {kind, field};
	return p;
}

gb_internal EscapePath escape_path_concat(EscapePath const &p, EscapePath const &q) {
	if (q.count == 0) {
		return p;
	}
	if (p.count == 0) {
		return q;
	}
	auto r = slice_make<EscapeStep>(temporary_allocator(), p.count+q.count);
	slice_copy(&r, p);
	slice_copy(&r, q, p.count);
	return r;
}

gb_internal bool escape_eq(EscapeObject const &a, EscapeObject const &b) {
	return a.entity == b.entity &&
	       a.temp   == b.temp;
}

gb_internal bool escape_eq(EscapeOrigin const &a, EscapeOrigin const &b) {
	return a.kind == b.kind               &&
	       a.offset_lost == b.offset_lost &&
	       escape_eq(a.obj, b.obj)        &&
	       escape_path_eq(a.path, b.path);
}

gb_internal bool escape_eq(EscapeOuterStore const &a, EscapeOuterStore const &b) {
	return a.location.root == b.location.root               &&
	       a.node          == b.node                        &&
	       escape_path_eq(a.location.path, b.location.path) &&
	       escape_path_eq(a.value_path,    b.value_path)    &&
	       escape_eq(a.dest,   b.dest)                      &&
	       escape_eq(a.origin, b.origin);
}

gb_internal EscapeValue escape_value(void) {
	// NOTE(bill): most values are empty so allocate on the fly when needed
	return array_make<EscapeValueFact>(temporary_allocator(), 0, 0);
}

gb_internal void escape_value_add(EscapeValue *v, EscapePath const &path, EscapeOrigin const &o, bool definite=false) {
	for (EscapeValueFact &f : *v) {
		if (escape_path_eq(f.path, path) && escape_eq(f.origin, o)) {
			f.definite |= definite;
			return;
		}
	}
	array_add(v, EscapeValueFact{path, o, definite});
}

gb_internal EscapeValue escape_value_one(EscapePath const &path, EscapeOrigin const &o, bool definite=false) {
	EscapeValue v = escape_value();
	escape_value_add(&v, path, o, definite);
	return v;
}

gb_internal void escape_value_add_all(EscapeValue *v, EscapeValue const &w) {
	for (EscapeValueFact const &f : w) {
		escape_value_add(v, f.path, f.origin);
	}
}

gb_internal void escape_value_add_at(EscapeValue *v, EscapePath const &path, EscapeValue const &w) {
	for (EscapeValueFact const &f : w) {
		escape_value_add(v, escape_path_concat(path, f.path), f.origin, f.definite);
	}
}

// either of two values, so neither is definite
gb_internal void escape_value_merge(EscapeValue *v, EscapeValue const &w) {
	for (EscapeValueFact &f : *v) {
		f.definite = false;
	}
	escape_value_add_all(v, w);
}

gb_internal EscapeValue escape_value_of(EscapeOriginKind kind, EscapeObject const &obj, EscapePath const &path, Ast *site=nullptr) {
	bool definite = kind == EscapeOrigin_Local || kind == EscapeOrigin_Temp;
	return escape_value_one({}, EscapeOrigin{kind, false, obj, path, site}, definite);
}

gb_internal isize escape_path_deref_index(EscapePath const &p) {
	for_array(i, p) {
		if (p[i].kind == EscapeStep_Deref) {
			return i;
		}
	}
	return p.count;
}


gb_internal EscapeOrigin escape_origin_offset(EscapeOrigin o, EscapePath const &extra) {
	switch (o.kind) {
	case EscapeOrigin_Outer:
		if (o.obj.entity != nullptr) {
			o.path = escape_path_concat(o.path, extra);
		}
		break;
	case EscapeOrigin_Local:
	case EscapeOrigin_Temp:
	case EscapeOrigin_Owned:
		o.path = escape_path_concat(o.path, extra);
		break;
	case EscapeOrigin_Param:
		if (extra.count > 0 && escape_path_deref_index(o.path) == o.path.count) {
			o.path = escape_path_concat(o.path, escape_path_of(EscapeStep_Deref));
		}
		o.path = escape_path_concat(o.path, extra);
		break;
	case EscapeOrigin_ParamLoad:
	case EscapeOrigin_ParamDeep:
		o.offset_lost |= extra.count > 0;
		break;
	}
	return o;
}

gb_internal EscapeValue escape_pointer_offset(EscapeValue const &v, EscapePath const &extra) {
	EscapeValue w = escape_value();
	for (EscapeValueFact const &f : v) {
		escape_value_add(&w, {}, escape_origin_offset(f.origin, extra), f.definite);
	}
	return w;
}

gb_internal EscapeValue escape_as_pointer(EscapeValue const &v) {
	return escape_pointer_offset(v, {});
}

// what a parameter holds at a path within what it holds at another
gb_internal EscapeOrigin escape_origin_within(EscapeOrigin o, EscapePath const &path, isize from) {
	if (o.kind == EscapeOrigin_Param && escape_path_deref_index(o.path) == o.path.count) {
		o.path = escape_path_concat(o.path, slice(path, from, path.count));
	}
	return o;
}

gb_internal void escape_project_into(EscapeValue *out, EscapeValueFact const &f, EscapePath const &path) {
	if (escape_path_has_prefix(f.path, path)) {
		escape_value_add(out, slice(f.path, path.count, f.path.count), f.origin, f.definite);
	} else if (escape_path_has_prefix(path, f.path)) {
		escape_value_add(out, {}, escape_origin_within(f.origin, path, f.path.count), f.definite);
	}
}

gb_internal EscapeValue escape_value_project(EscapeValue const &v, EscapePath const &path) {
	EscapeValue w = escape_value();
	for (EscapeValueFact const &f : v) {
		escape_project_into(&w, f, path);
	}
	return w;
}

gb_internal EscapeState escape_state_unreachable(void) {
	EscapeState s = {};
	s.facts   = array_make<EscapeFact>      (temporary_allocator(), 0, 0);
	s.outers  = array_make<EscapeOuterStore>(temporary_allocator(), 0, 0);
	s.cleared = array_make<EscapeOuterStore>(temporary_allocator(), 0, 0);
	s.nils    = array_make<EscapeNil>       (temporary_allocator(), 0, 0);
	s.checks  = array_make<Ast *>           (temporary_allocator(), 0, 0);
	s.limits  = array_make<EscapeLimit>     (temporary_allocator(), 0, 0);
	return s;
}

gb_internal EscapeState escape_state_clone(EscapeState const &s) {
	EscapeState c = {};
	c.reachable = s.reachable;
	c.facts   = array_clone(temporary_allocator(), s.facts);
	c.outers  = array_clone(temporary_allocator(), s.outers);
	c.cleared = array_clone(temporary_allocator(), s.cleared);
	c.nils    = array_clone(temporary_allocator(), s.nils);
	c.checks  = array_clone(temporary_allocator(), s.checks);
	c.limits  = array_clone(temporary_allocator(), s.limits);
	return c;
}

gb_internal bool escape_nil_covered(Array<EscapeNil> const &nils, Entity *e, EscapePath const &path, bool uninit) {
	for (EscapeNil const &n : nils) {
		if (n.e == e && n.uninit == uninit && escape_path_has_prefix(path, n.path)) {
			return true;
		}
	}
	return false;
}

gb_internal bool escape_eq(EscapeFact const &a, EscapeFact const &b) {
	return escape_eq(a.obj, b.obj)        &&
	       escape_path_eq(a.path, b.path) &&
	       escape_eq(a.origin, b.origin);
}

template <typename T>
gb_internal bool escape_eq(T *a, T *b) {
	return a == b;
}

template <typename T>
gb_internal bool escape_contains(Array<T> const &array, T const &x) {
	for (T const &y : array) {
		if (escape_eq(x, y)) {
			return true;
		}
	}
	return false;
}

template <typename T>
gb_internal bool escape_add_unique(Array<T> *array, T const &x) {
	if (escape_contains(*array, x)) {
		return false;
	}
	array_add(array, x);
	return true;
}

// whether two integer expressions reading only unchanged locals and constants have the same value; as integers wrap,
// this is only ever equality, never e.g. `i < i+1`
gb_internal bool escape_bounds_term_eq(Ast *a, Ast *b) {
	a = unparen_expr(a);
	b = unparen_expr(b);
	if (a == nullptr || b == nullptr) {
		return a == b;
	}
	if (!are_types_identical(a->tav.type, b->tav.type)) {
		return false;
	}
	if (a->tav.mode == Addressing_Constant || b->tav.mode == Addressing_Constant) {
		return a->tav.mode == b->tav.mode && compare_exact_values(Token_CmpEq, a->tav.value(), b->tav.value());
	}
	if (a->kind != b->kind) {
		return false;
	}
	switch (a->kind) {
	case Ast_Ident:
		return entity_of_node(a) == entity_of_node(b);
	case Ast_SelectorExpr:
		return entity_of_node(a->SelectorExpr.selector) == entity_of_node(b->SelectorExpr.selector) &&
		       escape_bounds_term_eq(a->SelectorExpr.expr, b->SelectorExpr.expr);
	case Ast_UnaryExpr:
		return a->UnaryExpr.op.kind == b->UnaryExpr.op.kind && escape_bounds_term_eq(a->UnaryExpr.expr, b->UnaryExpr.expr);
	case Ast_BinaryExpr:
		return a->BinaryExpr.op.kind == b->BinaryExpr.op.kind &&
		       escape_bounds_term_eq(a->BinaryExpr.left,  b->BinaryExpr.left) &&
		       escape_bounds_term_eq(a->BinaryExpr.right, b->BinaryExpr.right);
	case Ast_CallExpr: {
		Ast *p = unparen_expr(a->CallExpr.proc);
		Ast *q = unparen_expr(b->CallExpr.proc);
		if (p->tav.mode != q->tav.mode || (p->tav.mode == Addressing_Builtin && entity_of_node(p) != entity_of_node(q))) {
			return false;
		}
		return escape_bounds_term_eq(a->CallExpr.args[0], b->CallExpr.args[0]);
	}
	case Ast_TypeCast:
		return a->TypeCast.token.kind == b->TypeCast.token.kind && escape_bounds_term_eq(a->TypeCast.expr, b->TypeCast.expr);
	case Ast_AutoCast:
		return escape_bounds_term_eq(a->AutoCast.expr, b->AutoCast.expr);
	}
	return false;
}

gb_internal bool escape_bounds_length_eq(Ast *a, Ast *b) {
	Type *x = base_type(type_deref(a->tav.type));
	Type *y = base_type(type_deref(b->tav.type));
	if (x->kind != y->kind) {
		return false;
	}
	switch (x->kind) {
	case Type_Array:           return x->Array.count == y->Array.count;
	case Type_EnumeratedArray: return are_types_identical(x, y);
	case Type_MultiPointer:    return true;
	}
	return escape_bounds_term_eq(a, b);
}

gb_internal bool escape_bounds_check_eq(Ast *a, Ast *b) {
	if (a->kind != b->kind) {
		return false;
	}
	if (a->kind == Ast_IndexExpr) {
		return escape_bounds_length_eq(a->IndexExpr.expr, b->IndexExpr.expr) &&
		       escape_bounds_term_eq(a->IndexExpr.index, b->IndexExpr.index);
	}
	return escape_bounds_length_eq(a->SliceExpr.expr, b->SliceExpr.expr) &&
	       escape_bounds_term_eq(a->SliceExpr.low,  b->SliceExpr.low) &&
	       escape_bounds_term_eq(a->SliceExpr.high, b->SliceExpr.high);
}

gb_internal bool escape_bounds_passed(Array<Ast *> const &checks, Ast *node) {
	for (Ast *c : checks) {
		if (escape_bounds_check_eq(c, node)) {
			return true;
		}
	}
	return false;
}

gb_internal bool escape_eq(EscapeAtom const &x, EscapeAtom const &y) {
	if (x.kind != y.kind || x.e != y.e) {
		return false;
	}
	if (x.stmt != y.stmt) {
		return false;
	}
	return escape_bounds_term_eq(x.field, y.field);
}

gb_internal bool escape_limits_join(Array<EscapeLimit> *dst, Array<EscapeLimit> const &src) {
	if (dst->count == 0) {
		return false;
	}
	bool changed = false;
	auto limits = array_make<EscapeLimit>(temporary_allocator(), 0, dst->count);
	for (EscapeLimit const &l : *dst) {
		for (EscapeLimit const &m : src) {
			if (escape_eq(l.a, m.a) && escape_eq(l.b, m.b)) {
				array_add(&limits, EscapeLimit{l.a, l.b, gb_max(l.k, m.k)});
				changed |= m.k > l.k;
				break;
			}
		}
	}
	changed |= limits.count != dst->count;
	*dst = limits;
	return changed;
}

gb_internal bool escape_state_join(EscapeState *dst, EscapeState const &src) {
	if (!src.reachable) {
		return false;
	}

	if (!dst->reachable) {
		*dst = escape_state_clone(src);
		return true;
	}

	bool changed = false;
	for (EscapeFact const &f : src.facts) {
		changed |= escape_add_unique(&dst->facts, f);
	}
	for (isize i = dst->outers.count-1; i >= 0; i--) {
		if (escape_contains(src.cleared, dst->outers[i])) {
			array_unordered_remove(&dst->outers, i);
			changed = true;
		}
	}
	for (EscapeOuterStore const &o : src.outers) {
		if (!escape_contains(dst->cleared, o)) {
			changed |= escape_add_unique(&dst->outers, o);
		}
	}
	for (EscapeOuterStore const &o : src.cleared) {
		changed |= escape_add_unique(&dst->cleared, o);
	}

	// nil only where it is on both
	if (dst->nils.count > 0) {
		auto nils = array_make<EscapeNil>(temporary_allocator(), 0, dst->nils.count);
		for (EscapeNil const &n : dst->nils) {
			if (escape_nil_covered(src.nils, n.e, n.path, n.uninit)) {
				array_add(&nils, n);
			}
		}
		changed |= nils.count != dst->nils.count;
		for (EscapeNil const &n : src.nils) {
			if (escape_nil_covered(dst->nils, n.e, n.path, n.uninit) && !escape_nil_covered(nils, n.e, n.path, n.uninit)) {
				array_add(&nils, n);
				changed = true;
			}
		}
		dst->nils = nils;
	}

	// passed only where it did on both
	if (dst->checks.count > 0) {
		auto checks = array_make<Ast *>(temporary_allocator(), 0, dst->checks.count);
		for (Ast *c : dst->checks) {
			if (escape_bounds_passed(src.checks, c)) {
				array_add(&checks, c);
			}
		}
		changed |= checks.count != dst->checks.count;
		dst->checks = checks;
	}

	changed |= escape_limits_join(&dst->limits, src.limits);
	return changed;
}


gb_internal bool escape_type_has_pointers(Type *t) {
	t = base_type(t);
	if (t == nullptr) {
		return false;
	}
	switch (t->kind) {
	case Type_Basic:
		switch (t->Basic.kind) {
		case Basic_rawptr:
		case Basic_string:
		case Basic_cstring:
		case Basic_string16:
		case Basic_cstring16:
		case Basic_any:
			return true;
		}
		return false;

	case Type_Pointer:
	case Type_MultiPointer:
	case Type_Slice:
	case Type_DynamicArray:
	case Type_Map:
	case Type_SoaPointer:
		return true;

	case Type_Array:                     return escape_type_has_pointers(t->Array.elem);
	case Type_EnumeratedArray:           return escape_type_has_pointers(t->EnumeratedArray.elem);
	case Type_FixedCapacityDynamicArray: return escape_type_has_pointers(t->FixedCapacityDynamicArray.elem);
	case Type_SimdVector:                return escape_type_has_pointers(t->SimdVector.elem);

	case Type_Struct:
		for (Entity *f : t->Struct.fields) {
			if (escape_type_has_pointers(f->type)) {
				return true;
			}
		}
		return false;
	case Type_Union:
		for (Type *v : t->Union.variants) {
			if (escape_type_has_pointers(v)) {
				return true;
			}
		}
		return false;
	case Type_Tuple:
		for (Entity *v : t->Tuple.variables) {
			if (escape_type_has_pointers(v->type)) {
				return true;
			}
		}
		return false;
	}
	return false;
}

gb_internal bool escape_type_is_plain(Type *t) {
	t = base_type(t);
	if (t == nullptr) {
		return true;
	}
	switch (t->kind) {
	case Type_Basic:
	case Type_SimdVector:
		return !escape_type_has_pointers(t);

	case Type_Enum:
	case Type_BitSet:
	case Type_BitField:
	case Type_Matrix:
	case Type_Proc:
		return true;
	}
	return false;
}

gb_internal bool escape_is_explicit_unsafe_conversion(Type *t) {
	return t != nullptr && (is_type_rawptr(t) || is_type_uintptr(t));
}

// one of the struct's own fields, e.g. not one reached through 'using'
gb_internal bool escape_struct_has_field(Type *bt, Entity *field) {
	if (bt == nullptr || bt->kind != Type_Struct) {
		return false;
	}
	i32 index = field->Variable.field_index;
	return 0 <= index && index < bt->Struct.fields.count && bt->Struct.fields[index] == field;
}

// the type of the elements of a container, e.g. the values of a map
gb_internal Type *escape_elem_type(Type *bt) {
	switch (bt->kind) {
	case Type_Array:                     return bt->Array.elem;
	case Type_EnumeratedArray:           return bt->EnumeratedArray.elem;
	case Type_FixedCapacityDynamicArray: return bt->FixedCapacityDynamicArray.elem;
	case Type_Slice:                     return bt->Slice.elem;
	case Type_DynamicArray:              return bt->DynamicArray.elem;
	case Type_Map:                       return bt->Map.value;
	case Type_Matrix:                    return bt->Matrix.elem;
	}
	return nullptr;
}

// an array whose elements are within it, unlike those of a slice
gb_internal bool escape_is_inline_array(Type *bt) {
	return bt != nullptr && (bt->kind == Type_Array || bt->kind == Type_EnumeratedArray || bt->kind == Type_FixedCapacityDynamicArray);
}

// a string with a length, unlike a cstring
gb_internal bool escape_is_sized_string(Type *bt) {
	return bt->kind == Type_Basic && (bt->Basic.kind == Basic_string || bt->Basic.kind == Basic_string16);
}

gb_internal bool escape_is_local(Entity *e) {
	return e != nullptr                  &&
	       e->kind == Entity_Variable    &&
	       !e->Variable.is_global        &&
	       !e->Variable.is_foreign       &&
	       (e->flags & EntityFlag_Static) == 0;
}

gb_internal bool escape_is_param(Entity *e) {
	return (e->flags & (EntityFlag_Param|EntityFlag_Result)) == EntityFlag_Param;
}

gb_internal bool escape_is_reference(Entity *e) {
	return (e->flags & (EntityFlag_ForValue|EntityFlag_SwitchValue)) != 0 &&
	       (e->flags & EntityFlag_Value) == 0;
}

// a field brought in by 'using', of a parameter, a variable, or `x.y` for `using x.y`
gb_internal bool escape_is_using_field(Entity *e) {
	return e->using_parent != nullptr;
}

// the path of a field brought in by 'using' within what it was applied to, unless it is reached through another
gb_internal bool escape_using_path(Entity *e, EscapePath *path) {
	Type *t = base_type(type_deref(e->using_parent->type));
	if (t == nullptr || t->kind != Type_Struct) {
		return false;
	}
	for (Entity *f : t->Struct.fields) {
		if (f->token.string == e->token.string) {
			// the fields of a raw union share its storage
			*path = {};
			if (!t->Struct.is_raw_union) {
				*path = escape_path_of(EscapeStep_Field, f);
			}
			return true;
		}
	}
	return false;
}


gb_internal EscapeValue escape_obj_value(EscapeAnalysis *ea, EscapeObject const &obj, EscapePath const &path) {
	EscapeValue v = escape_value();
	for (EscapeFact const &f : ea->state.facts) {
		if (escape_eq(f.obj, obj)) {
			escape_project_into(&v, EscapeValueFact{f.path, f.origin}, path);
		}
	}
	return v;
}

// the type of what is at a path within a value of a type, if known, e.g. not when the path was made through a cast
gb_internal Type *escape_type_within(Type *t, EscapePath const &path) {
	for (EscapeStep const &step : path) {
		Type *bt = base_type(t);
		if (bt == nullptr) {
			return nullptr;
		}
		if (step.kind != EscapeStep_Field) {
			t = escape_elem_type(bt);
		} else if (escape_struct_has_field(bt, step.field)) {
			t = step.field->type;
		} else {
			return nullptr;
		}
	}
	return t;
}

gb_internal Type *escape_type_at(EscapeObject const &obj, EscapePath const &path) {
	if (obj.entity != nullptr) {
		return escape_type_within(obj.entity->type, path);
	}
	if (obj.temp != nullptr) {
		return escape_type_within(obj.temp->tav.type, path);
	}
	return nullptr;
}

// what a value of the type points to, e.g. the elements of a slice
gb_internal Type *escape_pointee_type(Type *t) {
	t = base_type(t);
	if (t == nullptr) {
		return nullptr;
	}
	switch (t->kind) {
	case Type_Pointer:      return t->Pointer.elem;
	case Type_MultiPointer: return t->MultiPointer.elem;
	case Type_Slice:        return t->Slice.elem;
	case Type_DynamicArray: return t->DynamicArray.elem;
	case Type_Basic:
		switch (t->Basic.kind) {
		case Basic_string:
		case Basic_cstring:
		case Basic_string16:
		case Basic_cstring16:
			return t_u8;
		}
		return nullptr;
	}
	return nullptr;
}

// the other fields of each struct a path goes through from `from` on, within a value of the type at `path[:from]`;
// whether it goes through only the structs' own fields
gb_internal bool escape_sibling_fields(Type *t, EscapePath const &path, isize from, Array<EscapePath> *siblings) {
	for (isize j = from; j < path.count; j++) {
		Type *bt = base_type(t);
		if (path[j].kind != EscapeStep_Field || !escape_struct_has_field(bt, path[j].field)) {
			return false;
		}
		for (Entity *f : bt->Struct.fields) {
			if (f != path[j].field) {
				array_add(siblings, escape_path_concat(slice(path, 0, j), escape_path_of(EscapeStep_Field, f)));
			}
		}
		t = path[j].field->type;
	}
	return true;
}

gb_internal bool escape_too_large(EscapeAnalysis *ea) {
	enum : isize {
		MAX_FACT_COUNT  = 1<<13,
		MAX_STMT_VISITS = 1<<20,
	};
	ea->too_large |= ea->state.facts.count + ea->state.outers.count > MAX_FACT_COUNT ||
	                 ea->stmt_visits > MAX_STMT_VISITS;
	return ea->too_large;
}

gb_internal void escape_store_obj(EscapeAnalysis *ea, EscapeObject const &obj, EscapePath const &path, EscapeValue const &v, EscapeUpdateKind update) {
	if (escape_too_large(ea)) {
		return;
	}
	// a store to an element of an array is taken to replace all of them (it may be any one)
	if (update == EscapeUpdate_Replace) {
		Type *type = escape_type_at(obj, {});
		auto pieces = array_make<EscapeFact>(temporary_allocator(), 0, 0);
		for (isize i = ea->state.facts.count-1; i >= 0; i--) {
			EscapeFact const &f = ea->state.facts[i];
			if (!escape_eq(f.obj, obj)) {
				continue;
			}
			if (escape_path_has_prefix(f.path, path)) {
				array_unordered_remove(&ea->state.facts, i);
				continue;
			}
			if (!escape_path_has_prefix(path, f.path)) {
				continue;
			}

			// a store to a field overwrites only that part of a fact for more of the value, so it is kept for the other fields
			auto siblings = array_make<EscapePath>(temporary_allocator(), 0, 0);
			Type *t = escape_type_within(type, f.path);
			if (!escape_sibling_fields(t, path, f.path.count, &siblings)) {
				continue;
			}
			for (EscapePath const &piece : siblings) {
				if (escape_type_has_pointers(piece[piece.count-1].field->type)) {
					array_add(&pieces, EscapeFact{f.obj, piece, escape_origin_within(f.origin, piece, f.path.count)});
				}
			}
			array_unordered_remove(&ea->state.facts, i);
		}
		for (EscapeFact const &p : pieces) {
			escape_add_unique(&ea->state.facts, p);
		}
	}
	for (EscapeValueFact const &vf : v) {
		escape_add_unique(&ea->state.facts, EscapeFact{obj, escape_path_concat(path, vf.path), vf.origin});
	}
}

gb_internal EscapeValue escape_load(EscapeAnalysis *ea, EscapeValue const &ptr, Type *type) {
	EscapeValue v = escape_value();
	if (type != nullptr && !escape_type_has_pointers(type)) {
		return v;
	}
	for (EscapeValueFact const &pf : ptr) {
		EscapeOrigin const &o = pf.origin;
		switch (o.kind) {
		case EscapeOrigin_Outer:
			// what a global points to is named by it, one level deep
			if (o.obj.entity != nullptr && escape_path_deref_index(o.path) == o.path.count) {
				escape_value_add(&v, {}, EscapeOrigin{EscapeOrigin_Outer, false, o.obj, escape_path_concat(o.path, escape_path_of(EscapeStep_Deref))});
			} else {
				escape_value_add(&v, {}, EscapeOrigin{EscapeOrigin_Outer});
			}
			break;

		case EscapeOrigin_Variadic: {
			// NOTE(bill): its 'any' elements are boxed in the caller's stack frame too
			Type *elem = base_type(o.obj.entity->type);
			if (elem->kind == Type_Slice && is_type_any(elem->Slice.elem)) {
				escape_value_add(&v, {}, o);
			} else {
				// its elements are the caller's arguments
				escape_value_add(&v, {}, EscapeOrigin{EscapeOrigin_ParamLoad, false, o.obj, o.path});
			}
			break;
		}
		case EscapeOrigin_Local:
			if (escape_is_param(o.obj.entity)) {
				// what a parameter holds is the caller's
				escape_value_add(&v, {}, EscapeOrigin{EscapeOrigin_Param, false, o.obj, o.path});
				break;
			}
			/*fallthrough*/
		case EscapeOrigin_Temp:
		case EscapeOrigin_Owned:
			escape_value_add_all(&v, escape_obj_value(ea, o.obj, o.path));
			break;

		case EscapeOrigin_Param:
		case EscapeOrigin_ParamLoad:
		case EscapeOrigin_ParamDeep: {
			// the caller's memory, loaded through once more
			EscapeOrigin loaded = {o.kind == EscapeOrigin_Param ? EscapeOrigin_ParamLoad : EscapeOrigin_ParamDeep, false, o.obj, o.path};
			escape_value_add(&v, {}, loaded);
			break;
		}

		case EscapeOrigin_Invalid:
			break;
		}
	}
	return v;
}

gb_internal EscapeValue escape_load_once(EscapeAnalysis *ea, EscapeValue const &ptr, Type *type=nullptr) {
	EscapeValue v = escape_value();
	for (EscapeValueFact const &f : ptr) {
		EscapeOrigin const &o = f.origin;
		bool own = o.kind == EscapeOrigin_Temp || o.kind == EscapeOrigin_Owned ||
		           (o.kind == EscapeOrigin_Local && !escape_is_param(o.obj.entity));
		Type *t = type;
		if (own && t == nullptr) {
			t = base_type(escape_type_at(o.obj, o.path));
		}
		if (own && t != nullptr && (t->kind == Type_DynamicArray || t->kind == Type_Map)) {
			EscapeOrigin buffer = {EscapeOrigin_Owned, false, o.obj, escape_path_concat(o.path, escape_path_of(EscapeStep_AnyElement))};
			escape_value_add(&v, {}, buffer, f.definite);
			continue;
		}

		escape_value_add_all(&v, escape_load(ea, escape_value_one({}, o), nullptr));
	}
	return v;
}

// the branch of a `when` ternary which is compiled in
gb_internal Ast *escape_when_branch(Ast *expr) {
	ast_node(te, TernaryWhenExpr, expr);
	if (te->cond == nullptr || te->cond->tav.value().kind != ExactValue_Bool) {
		return nullptr;
	}
	if (te->cond->tav.value().value_bool) {
		return te->x;
	}
	return te->y;
}

gb_internal Slice<Ast *> escape_parts(Ast *parts[3], Ast *a, Ast *b=nullptr, Ast *c=nullptr) {
	parts[0] = a;
	parts[1] = b;
	parts[2] = c;
	return {parts, 3};
}

// the parts an expression evaluates, in order, any of which may be missing, e.g. the low of `s[:n]`; of a `when` only
// the branch compiled in, and of a call only its arguments
gb_internal Slice<Ast *> escape_operands(Ast *x, Ast *parts[3]) {
	switch (x->kind) {
	case Ast_CompoundLit:      return x->CompoundLit.elems;
	case Ast_CallExpr:         return x->CallExpr.args;
	case Ast_ParenExpr:        return escape_parts(parts, x->ParenExpr.expr);
	case Ast_UnaryExpr:        return escape_parts(parts, x->UnaryExpr.expr);
	case Ast_SelectorExpr:     return escape_parts(parts, x->SelectorExpr.expr);
	case Ast_SelectorCallExpr: return escape_parts(parts, x->SelectorCallExpr.call);
	case Ast_DerefExpr:        return escape_parts(parts, x->DerefExpr.expr);
	case Ast_FieldValue:       return escape_parts(parts, x->FieldValue.value);
	case Ast_Ellipsis:         return escape_parts(parts, x->Ellipsis.expr);
	case Ast_TernaryWhenExpr:  return escape_parts(parts, escape_when_branch(x));
	case Ast_OrReturnExpr:     return escape_parts(parts, x->OrReturnExpr.expr);
	case Ast_OrBranchExpr:     return escape_parts(parts, x->OrBranchExpr.expr);
	case Ast_TypeAssertion:    return escape_parts(parts, x->TypeAssertion.expr);
	case Ast_TypeCast:         return escape_parts(parts, x->TypeCast.expr);
	case Ast_AutoCast:         return escape_parts(parts, x->AutoCast.expr);
	case Ast_TagExpr:          return escape_parts(parts, x->TagExpr.expr);
	case Ast_BinaryExpr:       return escape_parts(parts, x->BinaryExpr.left, x->BinaryExpr.right);
	case Ast_OrElseExpr:       return escape_parts(parts, x->OrElseExpr.x, x->OrElseExpr.y);
	case Ast_IndexExpr:        return escape_parts(parts, x->IndexExpr.expr, x->IndexExpr.index);
	case Ast_MatrixIndexExpr:  return escape_parts(parts, x->MatrixIndexExpr.expr, x->MatrixIndexExpr.row_index, x->MatrixIndexExpr.column_index);
	case Ast_SliceExpr:        return escape_parts(parts, x->SliceExpr.expr, x->SliceExpr.low, x->SliceExpr.high);
	case Ast_TernaryIfExpr:    return escape_parts(parts, x->TernaryIfExpr.cond, x->TernaryIfExpr.x, x->TernaryIfExpr.y);
	}
	return {};
}

gb_internal Ast *escape_call_of(Ast *expr) {
	expr = unparen_expr(expr);
	if (expr->kind == Ast_SelectorCallExpr) {
		expr = expr->SelectorCallExpr.call;
	}
	if (expr->kind == Ast_CallExpr) {
		return expr;
	}
	return nullptr;
}

gb_internal void escape_visit_exits(EscapeAnalysis *ea, Ast *expr) {
	if (expr == nullptr) {
		return;
	}
	if ((expr->viral_state_flags & (ViralStateFlag_ContainsOrReturn|ViralStateFlag_ContainsOrBreak)) != 0) {
		escape_expr(ea, expr);
		return;
	}
	if (Ast *call = escape_call_of(expr)) {
		escape_call(ea, call);
		return;
	}

	expr = unparen_expr(expr);
	if (expr->tav.mode == Addressing_Constant || expr->tav.mode == Addressing_Type) {
		return;
	}
	Ast *parts[3];
	for (Ast *part : escape_operands(expr, parts)) {
		escape_visit_exits(ea, part);
	}
}

gb_internal void escape_nil_forget(EscapeAnalysis *ea, Entity *e) {
	for (isize i = ea->state.nils.count-1; i >= 0; i--) {
		if (ea->state.nils[i].e == e) {
			array_unordered_remove(&ea->state.nils, i);
		}
	}
}

gb_internal bool escape_bounds_mentions(Ast *x, Entity *e) {
	if (x == nullptr) {
		return false;
	}
	if (x->kind == Ast_Ident) {
		return entity_of_node(x) == e;
	}
	Ast *parts[3];
	for (Ast *part : escape_operands(x, parts)) {
		if (escape_bounds_mentions(part, e)) {
			return true;
		}
	}
	return false;
}

gb_internal void escape_bounds_forget(EscapeAnalysis *ea, Entity *e, bool keep_limits=false) {
	if (e == nullptr) {
		return;
	}
	for (isize i = ea->state.checks.count-1; i >= 0; i--) {
		if (escape_bounds_mentions(ea->state.checks[i], e)) {
			array_unordered_remove(&ea->state.checks, i);
		}
	}
	for (isize i = ea->state.limits.count-1; i >= 0 && !keep_limits; i--) {
		if (ea->state.limits[i].a.e == e || ea->state.limits[i].b.e == e) {
			array_unordered_remove(&ea->state.limits, i);
		}
	}
}

gb_internal void escape_forget_entity(EscapeAnalysis *ea, Entity *e) {
	if (e == nullptr) {
		return;
	}
	for (isize i = ea->state.facts.count-1; i >= 0; i--) {
		if (ea->state.facts[i].obj.entity == e) {
			array_unordered_remove(&ea->state.facts, i);
		}
	}
	escape_nil_forget(ea, e);
	escape_bounds_forget(ea, e);
}

gb_internal void escape_forget(EscapeAnalysis *ea, Ast *decl) {
	if (decl != nullptr && decl->kind == Ast_ValueDecl && decl->ValueDecl.is_mutable) {
		for (Ast *name : decl->ValueDecl.names) {
			escape_forget_entity(ea, entity_of_node(name));
		}
	}
}

gb_internal EscapeValue escape_elems_at(EscapeAnalysis *ea, EscapeValue const &addr, Type *t) {
	EscapeValue ptr = escape_value();
	t = base_type(t);
	if (t == nullptr) {
		return ptr;
	}
	switch (t->kind) {
	case Type_Array:
	case Type_EnumeratedArray:
	case Type_FixedCapacityDynamicArray:
	case Type_Matrix:
		return escape_pointer_offset(addr, escape_path_of(EscapeStep_AnyElement));
	case Type_Slice:
	case Type_MultiPointer:
	case Type_Basic:
		return escape_as_pointer(escape_load(ea, addr, t));
	case Type_DynamicArray:
	case Type_Map:
		return escape_load_once(ea, addr, t);
	}
	return ptr;
}

gb_internal EscapeValue escape_elems_of(EscapeAnalysis *ea, Ast *x) {
	Type *t = base_type(x->tav.type);
	if (t == nullptr) {
		escape_expr(ea, x);
		return escape_value();
	}
	switch (t->kind) {
	case Type_Pointer:
		return escape_elems_at(ea, escape_as_pointer(escape_expr(ea, x)), t->Pointer.elem);

	case Type_Slice:
	case Type_MultiPointer:
	case Type_Basic:
		return escape_as_pointer(escape_expr(ea, x));
	}
	return escape_elems_at(ea, escape_addr(ea, x), t);
}

gb_internal bool escape_selector_path(Ast *se_node, EscapePath *path) {
	ast_node(se, SelectorExpr, se_node);
	if (se->swizzle_count > 0 || se->is_bit_field) {
		return false;
	}

	Entity *f = entity_of_node(se->selector);
	if (f == nullptr || f->kind != Entity_Variable) {
		return false;
	}

	// the fields of a raw union share its storage
	*path = {};
	if (!is_type_raw_union(type_deref(se->expr->tav.type))) {
		*path = escape_path_of(EscapeStep_Field, f);
	}
	return true;
}

gb_internal Entity *escape_package_selector(Ast *se_node) {
	ast_node(se, SelectorExpr, se_node);
	Entity *pkg = entity_of_node(se->expr);
	if (pkg == nullptr || pkg->kind != Entity_ImportName) {
		return nullptr;
	}
	return entity_of_node(se->selector);
}

// the index of the field or parameter a field value names, e.g. `x` of `x = 1`
gb_internal isize escape_field_index(Slice<Entity *> const &fields, Ast *name) {
	if (name->kind != Ast_Ident) {
		return -1;
	}
	for_array(i, fields) {
		if (fields[i]->token.string == name->Ident.token.string) {
			return i;
		}
	}
	return -1;
}

// the procedure a call names, e.g. not the one a call it makes first returns
gb_internal Entity *escape_proc_entity(Ast *proc) {
	proc = unparen_expr(proc);
	if (proc->kind != Ast_Ident && proc->kind != Ast_SelectorExpr) {
		return nullptr;
	}
	return entity_of_node(proc);
}

gb_internal BuiltinProcId escape_builtin_of(Ast *call) {
	Ast *proc = unparen_expr(call->CallExpr.proc);
	Entity *b = entity_of_node(proc);
	if (proc->tav.mode != Addressing_Builtin || b == nullptr || b->kind != Entity_Builtin) {
		return BuiltinProc_Invalid;
	}
	return cast(BuiltinProcId)b->Builtin.id;
}


// With -vet-nil-deref, what within the locals is nil on every path reaching each point is kept too: from their zero
// values, `nil`, and the conditions comparing them to it. A dereference of what is nil there is reported, never one
// of what only may be. Taking the address of a local, which anything may then change it through, forgets it

gb_internal bool escape_type_has_nilable(Type *t) {
	t = base_type(t);
	if (t == nullptr) {
		return false;
	}
	switch (t->kind) {
	case Type_Basic:
		return t->Basic.kind == Basic_rawptr;

	case Type_Pointer:
	case Type_MultiPointer:
	case Type_Proc:
		return true;

	case Type_Array:                     return escape_type_has_nilable(t->Array.elem);
	case Type_EnumeratedArray:           return escape_type_has_nilable(t->EnumeratedArray.elem);
	case Type_FixedCapacityDynamicArray: return escape_type_has_nilable(t->FixedCapacityDynamicArray.elem);

	case Type_Struct:
		for (Entity *f : t->Struct.fields) {
			if (escape_type_has_nilable(f->type)) {
				return true;
			}
		}
		return false;
	}
	return false;
}

gb_internal bool escape_is_nil_literal(Ast *expr) {
	expr = unparen_expr(expr);
	if (expr == nullptr || expr->kind != Ast_Ident) {
		return false;
	}
	Entity *e = entity_of_node(expr);
	return e != nullptr && e->kind == Entity_Nil;
}

// the local an expression is within, without going through a pointer
gb_internal bool escape_nil_location(Ast *expr, EscapeLocation *loc) {
	expr = unparen_expr(expr);
	if (expr == nullptr) {
		return false;
	}
	switch (expr->kind) {
	case_ast_node(i, Ident, expr);
		Entity *e = entity_of_node(expr);
		if (!escape_is_local(e) || escape_is_using_field(e) || (e->flags & (EntityFlag_ForValue|EntityFlag_SwitchValue)) != 0) {
			return false;
		}
		*loc = {e, {}, true};
		return true;
	case_end;

	case_ast_node(se, SelectorExpr, expr);
		if (escape_package_selector(expr) != nullptr || is_type_pointer(se->expr->tav.type)) {
			return false;
		}
		if (!escape_nil_location(se->expr, loc)) {
			return false;
		}
		EscapePath field = {};
		if (!escape_selector_path(expr, &field) || field.count == 0) {
			// e.g. a field of a raw union, which shares its storage with the others
			loc->exact = false;
			return true;
		}
		loc->path = escape_path_concat(loc->path, field);
		return true;
	case_end;

	case_ast_node(ie, IndexExpr, expr);
		if (!escape_is_inline_array(base_type(ie->expr->tav.type)) || !escape_nil_location(ie->expr, loc)) {
			return false;
		}
		loc->path  = escape_path_concat(loc->path, escape_path_of(EscapeStep_AnyElement));
		loc->exact = false;
		return true;
	case_end;
	}
	return false;
}

// the local an expression is part of, unless it is reached through a pointer or is in the buffer of a slice and such
gb_internal Entity *escape_nil_root(Ast *expr) {
	expr = unparen_expr(expr);
	if (expr == nullptr) {
		return nullptr;
	}
	Ast *base = nullptr;
	switch (expr->kind) {
	case_ast_node(i, Ident, expr);
		Entity *e = entity_of_node(expr);
		if (e != nullptr && escape_is_using_field(e)) {
			// a field brought in by 'using' is part of what it was applied to
			if (is_type_pointer(e->using_parent->type) || is_type_soa_pointer(e->using_parent->type)) {
				return nullptr;
			}
			if (e->using_expr != nullptr) {
				return escape_nil_root(e->using_expr);
			}
			e = e->using_parent;
		}
		if (escape_is_local(e)) {
			return e;
		}
		return nullptr;
	case_end;

	case_ast_node(se, SelectorExpr, expr);
		if (escape_package_selector(expr) != nullptr || is_type_pointer(se->expr->tav.type)) {
			return nullptr;
		}
		return escape_nil_root(se->expr);
	case_end;

	case_ast_node(mie, MatrixIndexExpr, expr);
		return escape_nil_root(mie->expr);
	case_end;

	case_ast_node(ie, IndexExpr, expr);
		base = ie->expr;
	case_end;

	case_ast_node(se, SliceExpr, expr);
		base = se->expr;
	case_end;
	}

	// e.g. the elements of an array, or of a #soa one
	if (base == nullptr) {
		return nullptr;
	}
	Type *t = base_type(base->tav.type);
	if (escape_is_inline_array(t) || (t != nullptr && t->kind == Type_Struct)) {
		return escape_nil_root(base);
	}
	return nullptr;
}

gb_internal void escape_nil_add(EscapeAnalysis *ea, Entity *e, EscapePath const &path, bool uninit) {
	if (escape_contains(ea->nil_escaped, e) || escape_nil_covered(ea->state.nils, e, path, uninit)) {
		return;
	}
	array_add(&ea->state.nils, EscapeNil{e, path, uninit});
}

// what is at the path may no longer be nil, while the rest of what a fact says is nil stays so
gb_internal void escape_nil_kill(EscapeAnalysis *ea, Entity *e, EscapePath const &path) {
	auto pieces = array_make<EscapeNil>(temporary_allocator(), 0, 0);
	for (isize i = ea->state.nils.count-1; i >= 0; i--) {
		EscapeNil const n = ea->state.nils[i];
		if (n.e != e || !escape_paths_overlap(n.path, path)) {
			continue;
		}
		array_unordered_remove(&ea->state.nils, i);

		// the other fields of each struct the path goes through, until it goes through something else
		auto siblings = array_make<EscapePath>(temporary_allocator(), 0, 0);
		escape_sibling_fields(escape_type_within(e->type, n.path), path, n.path.count, &siblings);
		for (EscapePath const &p : siblings) {
			if (n.uninit || escape_type_has_nilable(p[p.count-1].field->type)) {
				array_add(&pieces, EscapeNil{e, p, n.uninit});
			}
		}
	}
	for (EscapeNil const &p : pieces) {
		escape_nil_add(ea, p.e, p.path, p.uninit);
	}
}

// taking the address of a local, or of a part of it, lets anything change it later through what it was given
gb_internal void escape_nil_escape(EscapeAnalysis *ea, Ast *expr) {
	if (!ea->nil_deref && !ea->uninit) {
		return;
	}
	Entity *root = escape_nil_root(expr);
	if (root != nullptr && escape_add_unique(&ea->nil_escaped, root)) {
		escape_nil_forget(ea, root);
	}
}

// the paths within the value of an expression which are nil on every path reaching here
gb_internal Array<EscapePath> escape_nil_paths(EscapeAnalysis *ea, Ast *expr) {
	auto paths = array_make<EscapePath>(temporary_allocator(), 0, 0);
	expr = unparen_expr(expr);
	if (expr == nullptr) {
		return paths;
	}
	if (escape_is_nil_literal(expr)) {
		array_add(&paths, EscapePath{});
		return paths;
	}

	switch (expr->kind) {
	case_ast_node(cl, CompoundLit, expr);
		// what it does not give a value is zero
		Type *t = base_type(expr->tav.type);
		if (!escape_type_has_nilable(t)) {
			return paths;
		}
		if (cl->elems.count == 0) {
			array_add(&paths, EscapePath{});
			return paths;
		}
		if (t->kind != Type_Struct || t->Struct.is_raw_union) {
			return paths;
		}
		auto values = array_make<Ast *>(temporary_allocator(), t->Struct.fields.count);
		for_array(i, cl->elems) {
			Ast *elem = cl->elems[i];
			isize index = i;
			if (elem->kind == Ast_FieldValue) {
				index = escape_field_index(t->Struct.fields, elem->FieldValue.field);
				elem  = elem->FieldValue.value;
			}
			if (index < 0 || index >= values.count) {
				// e.g. a field reached through 'using'
				return paths;
			}
			values[index] = elem;
		}
		for_array(j, t->Struct.fields) {
			Entity *f = t->Struct.fields[j];
			if (!escape_type_has_nilable(f->type)) {
				continue;
			}
			EscapePath field = escape_path_of(EscapeStep_Field, f);
			if (values[j] == nullptr) {
				array_add(&paths, field);
				continue;
			}
			for (EscapePath const &p : escape_nil_paths(ea, values[j])) {
				array_add(&paths, escape_path_concat(field, p));
			}
		}
		return paths;
	case_end;

	case_ast_node(ce, CallExpr, expr);
		if (ce->proc->tav.mode == Addressing_Type && ce->args.count == 1 && !escape_is_explicit_unsafe_conversion(expr->tav.type)) {
			return escape_nil_paths(ea, ce->args[0]);
		}
		return paths;
	case_end;

	case_ast_node(tc, TypeCast, expr);
		if (tc->token.kind == Token_transmute || escape_is_explicit_unsafe_conversion(expr->tav.type)) {
			return paths;
		}
		return escape_nil_paths(ea, tc->expr);
	case_end;

	case_ast_node(ac, AutoCast, expr);
		return escape_nil_paths(ea, ac->expr);
	case_end;
	}

	EscapeLocation loc = {};
	if (!escape_nil_location(expr, &loc)) {
		return paths;
	}
	for (EscapeNil const &n : ea->state.nils) {
		if (n.e != loc.root || n.uninit) {
			continue;
		}
		if (escape_path_has_prefix(loc.path, n.path)) {
			array_add(&paths, EscapePath{});
		} else if (escape_path_has_prefix(n.path, loc.path)) {
			array_add(&paths, slice(n.path, loc.path.count, n.path.count));
		}
	}
	return paths;
}

// a store of a value which is nil at `paths`, taken before its statement stored anything, unless it is unknown
gb_internal void escape_nil_store(EscapeAnalysis *ea, Ast *lhs, Array<EscapePath> const *paths) {
	if (!ea->nil_deref && !ea->uninit) {
		return;
	}
	EscapeLocation loc = {};
	if (!escape_nil_location(lhs, &loc)) {
		// e.g. into an element of a #soa array
		Entity *root = escape_nil_root(lhs);
		if (root != nullptr) {
			escape_nil_forget(ea, root);
		}
		return;
	}
	escape_nil_kill(ea, loc.root, loc.path);
	if (loc.exact && paths != nullptr) {
		for (EscapePath const &p : *paths) {
			escape_nil_add(ea, loc.root, escape_path_concat(loc.path, p), false);
		}
	}
}

// the named results are set when returning with values, before the defers run
gb_internal void escape_nil_forget_results(EscapeAnalysis *ea) {
	if (!ea->nil_deref || ea->pt->results == nullptr || !ea->pt->has_named_results) {
		return;
	}
	for (Entity *e : ea->pt->results->Tuple.variables) {
		escape_nil_forget(ea, e);
	}
}

// the comparisons a condition being `truth` makes hold, e.g. both of `a && b` when it is true
gb_internal void escape_cond_facts(Ast *cond, bool truth, Array<EscapeRefine> *facts) {
	cond = unparen_expr(cond);
	if (cond == nullptr) {
		return;
	}
	if (cond->kind == Ast_UnaryExpr && cond->UnaryExpr.op.kind == Token_Not) {
		escape_cond_facts(cond->UnaryExpr.expr, !truth, facts);
		return;
	}
	if (cond->kind != Ast_BinaryExpr) {
		return;
	}

	TokenKind op = cond->BinaryExpr.op.kind;
	if (op != Token_CmpAnd && op != Token_CmpOr) {
		array_add(facts, EscapeRefine{cond, truth});
	} else if (truth == (op == Token_CmpAnd)) {
		escape_cond_facts(cond->BinaryExpr.left,  truth, facts);
		escape_cond_facts(cond->BinaryExpr.right, truth, facts);
	}
}

gb_internal void escape_nil_refine(EscapeAnalysis *ea, Ast *cond, bool truth, bool narrow=false) {
	if (!ea->nil_deref && !narrow) {
		return;
	}
	auto facts = array_make<EscapeRefine>(temporary_allocator(), 0, 0);
	escape_cond_facts(cond, truth, &facts);
	for (EscapeRefine const &f : facts) {
		ast_node(be, BinaryExpr, f.cond);
		if (be->op.kind != Token_CmpEq && be->op.kind != Token_NotEq) {
			continue;
		}
		Ast *x = be->left;
		if (escape_is_nil_literal(x)) {
			x = be->right;
		} else if (!escape_is_nil_literal(be->right)) {
			continue;
		}
		EscapeLocation loc = {};
		if (!escape_nil_location(x, &loc)) {
			continue;
		}
		bool is_nil = (be->op.kind == Token_CmpEq) == f.truth;
		if (narrow && is_nil && loc.exact) {
			// as if it were set to nil
			escape_store_obj(ea, {loc.root}, loc.path, {}, EscapeUpdate_Replace);
		}
		if (!ea->nil_deref) {
			continue;
		}
		if (!is_nil) {
			escape_nil_kill(ea, loc.root, loc.path);
		} else if (loc.exact && escape_type_has_nilable(x->tav.type)) {
			escape_nil_add(ea, loc.root, loc.path, false);
		}
	}
}

gb_internal void escape_nil_use(EscapeAnalysis *ea, Ast *ptr, EscapeReportKind kind) {
	if (!ea->nil_deref) {
		return;
	}
	bool nil = false;
	for (EscapePath const &p : escape_nil_paths(ea, ptr)) {
		nil |= p.count == 0;
	}
	array_add(&ea->uses, EscapeUse{ptr, kind, nil});
}

// a read of what is within a local, kept when that was declared with `---`; whether it is within a local, as then
// what it is within is not read as a whole
gb_internal bool escape_uninit_read(EscapeAnalysis *ea, Ast *expr) {
	if (ea->uninit_decls.count == 0) {
		// nothing declared with `---` to read yet, and scanning what it is within finds the same dereferences
		return false;
	}
	EscapeLocation loc = {};
	if (!escape_nil_location(expr, &loc)) {
		return false;
	}
	if (escape_contains(ea->uninit_decls, loc.root)) {
		array_add(&ea->uses, EscapeUse{expr, EscapeReport_UninitRead, escape_nil_covered(ea->state.nils, loc.root, loc.path, true)});
	}
	return true;
}

gb_internal int escape_use_cmp(void const *a, void const *b) {
	EscapeUse const *x = cast(EscapeUse const *)a;
	EscapeUse const *y = cast(EscapeUse const *)b;
	if (x->node != y->node) {
		return cast(uintptr)x->node < cast(uintptr)y->node ? -1 : +1;
	}
	return cast(int)x->kind - cast(int)y->kind;
}

// a local only an assignment changes, as its address was not taken and it is not the caller's memory
gb_internal bool escape_bounds_entity(EscapeAnalysis *ea, Entity *e) {
	if (!escape_is_local(e) || escape_is_using_field(e) || escape_is_reference(e) ||
	    e->Variable.thread_local_model.len != 0 || escape_contains(ea->bounds_escaped, e)) {
		return false;
	}
	// a larger parameter, or one passed `#by_ptr`, is the caller's own value
	return !escape_is_param(e) || ((e->flags & EntityFlag_ByPtr) == 0 && type_size_of(e->type) <= 16);
}

gb_internal Entity *escape_bounds_local(EscapeAnalysis *ea, Ast *x) {
	x = unparen_expr(x);
	switch (x->kind) {
	case_ast_node(i, Ident, x);
		Entity *e = entity_of_node(x);
		if (escape_bounds_entity(ea, e)) {
			return e;
		}
	case_end;

	case_ast_node(se, SelectorExpr, x);
		// a field of a struct whose fields have storage of their own
		Entity *f = entity_of_node(se->selector);
		Type *  t = base_type(se->expr->tav.type);
		if (f == nullptr || f->kind != Entity_Variable || !escape_struct_has_field(t, f) ||
		    t->Struct.is_raw_union || t->Struct.soa_kind != StructSoa_None) {
			return nullptr;
		}
		return escape_bounds_local(ea, se->expr);
	case_end;
	}
	return nullptr;
}

gb_internal bool escape_bounds_atom(EscapeAnalysis *ea, EscapeAtomKind kind, Ast *x, EscapeAtom *out) {
	x = unparen_expr(x);
	Entity *e = escape_bounds_local(ea, x);
	if (e == nullptr) {
		return false;
	}
	*out = EscapeAtom{kind, e};
	if (x->kind == Ast_SelectorExpr) {
		out->field = x;
	}
	return true;
}

gb_internal Ast *escape_bounds_len_of(EscapeAnalysis *ea, Ast *x) {
	x = unparen_expr(x);
	if (x->kind != Ast_CallExpr || x->CallExpr.args.count != 1 || escape_builtin_of(x) != BuiltinProc_len) {
		return nullptr;
	}
	Ast *arg = unparen_expr(x->CallExpr.args[0]);
	Type *t = base_type(arg->tav.type);
	if (t == nullptr || escape_bounds_local(ea, arg) == nullptr) {
		return nullptr;
	}
	if (t->kind == Type_Slice || t->kind == Type_DynamicArray || escape_is_sized_string(t)) {
		return arg;
	}
	return nullptr;
}

gb_internal bool escape_bounds_term(EscapeAnalysis *ea, Ast *x) {
	x = unparen_expr(x);
	if (x == nullptr || !(is_type_integer(x->tav.type) || is_type_enum(x->tav.type))) {
		return false;
	}
	if (x->tav.mode == Addressing_Constant) {
		return true;
	}
	switch (x->kind) {
	case Ast_Ident:
	case Ast_SelectorExpr:
		return escape_bounds_local(ea, x) != nullptr;

	case_ast_node(ue, UnaryExpr, x);
		switch (ue->op.kind) {
		case Token_Add:
		case Token_Sub:
		case Token_Xor:
			return escape_bounds_term(ea, ue->expr);
		}
		return false;
	case_end;

	case_ast_node(be, BinaryExpr, x);
		switch (be->op.kind) {
		case Token_Add:
		case Token_Sub:
		case Token_Mul:
		case Token_Quo:
		case Token_Mod:
		case Token_ModMod:
		case Token_And:
		case Token_Or:
		case Token_Xor:
		case Token_AndNot:
		case Token_Shl:
		case Token_Shr:
			return escape_bounds_term(ea, be->left) && escape_bounds_term(ea, be->right);
		}
		return false;
	case_end;

	case_ast_node(ce, CallExpr, x);
		if (escape_bounds_len_of(ea, x) != nullptr) {
			return true;
		}
		return ce->proc->tav.mode == Addressing_Type && ce->args.count == 1 && escape_bounds_term(ea, ce->args[0]);
	case_end;

	case_ast_node(tc, TypeCast, x);
		return escape_bounds_term(ea, tc->expr);
	case_end;

	case_ast_node(ac, AutoCast, x);
		return escape_bounds_term(ea, ac->expr);
	case_end;
	}
	return false;
}

// whether the expression makes a bounds check which passes again whenever it passed before with nothing it reads
// assigned since
gb_internal bool escape_bounds_checkable(EscapeAnalysis *ea, Ast *node) {
	Ast *container = nullptr;
	switch (node->kind) {
	case_ast_node(ie, IndexExpr, node);
		if (!escape_bounds_term(ea, ie->index)) {
			return false;
		}
		container = ie->expr;
	case_end;

	case_ast_node(se, SliceExpr, node);
		if ((se->low  != nullptr && !escape_bounds_term(ea, se->low)) ||
		    (se->high != nullptr && !escape_bounds_term(ea, se->high))) {
			return false;
		}
		container = se->expr;
	case_end;
	}

	Type *t = base_type(container->tav.type);
	if (t == nullptr) {
		return false;
	}
	bool deref = is_type_pointer(t);
	t = base_type(type_deref(t));

	bool is_local = !deref && escape_bounds_local(ea, container) != nullptr;

	switch (t->kind) {
	case Type_Array:
	case Type_EnumeratedArray:
		return node->kind == Ast_SliceExpr || node->IndexExpr.index->tav.mode != Addressing_Constant;
	case Type_MultiPointer:
		return node->kind == Ast_SliceExpr && node->SliceExpr.high != nullptr;
	case Type_Slice:
	case Type_DynamicArray:
		return is_local;
	case Type_Basic:
		return is_local && escape_is_sized_string(t);
	}
	return false;
}

// the least and most an integer type holds; those of 64 bits are `BIG` and beyond, far past any sum of the limits and
// offsets here: each is within `EscapeLimit::MAX_K` of zero, and a sum takes at most `MAX_STEPS` passes over
// `MAX_LIMIT_COUNT` of them
struct EscapeIntRange {
	i64 min;
	i64 max;
};

gb_internal bool escape_int_range(Type *t, EscapeIntRange *r) {
	enum : i64 { BIG = 1ll<<61 };
	t = base_type(t);
	if (t != nullptr && t->kind == Type_Enum) {
		t = base_type(t->Enum.base_type);
	}
	if (t == nullptr || !is_type_integer(t) || is_type_untyped(t)) {
		return false;
	}
	i64 bits = 8*type_size_of(t);
	if (bits > 32 && bits != 64) {
		return false;
	}
	bool is_unsigned = is_type_unsigned(t);
	if (bits == 64) {
		*r = is_unsigned ? EscapeIntRange{0, 2*BIG} : EscapeIntRange{-BIG, BIG};
	} else {
		*r = is_unsigned ? EscapeIntRange{0, (1ll<<bits) - 1} : EscapeIntRange{-(1ll<<(bits-1)), (1ll<<(bits-1)) - 1};
	}
	return true;
}

gb_internal bool escape_atom_range(EscapeAtom const &atom, EscapeIntRange *r) {
	switch (atom.kind) {
	case EscapeAtom_Zero:
		*r = {};
		return true;
	case EscapeAtom_Local: {
		Type *t = atom.e->type;
		if (atom.field != nullptr) {
			t = atom.field->tav.type;
		}
		return escape_int_range(t, r);
	}
	}
	return escape_int_range(t_int, r);
}

struct EscapeReach {
	EscapeAtom atom;
	i64        dist;
};

// with `up`, the atoms what `from` holds is known to be at most, plus `dist`; otherwise at least, less `dist`
gb_internal Array<EscapeReach> escape_limits_reach(Array<EscapeLimit> const &limits, EscapeAtom const &from, bool up) {
	enum : isize { MAX_STEPS = 4 };
	auto reach = array_make<EscapeReach>(temporary_allocator(), 0, 8);
	array_add(&reach, EscapeReach{from, 0});
	for (isize step = 0; step < MAX_STEPS; step++) {
		bool changed = false;
		for (EscapeLimit const &l : limits) {
			if (l.b.kind == EscapeAtom_NonZero) {
				continue;
			}
			// `from <= a+d` and `a-b <= k` give `from <= b+d+k`; `b-from <= d` gives `a-from <= d+k`
			EscapeAtom src = l.b;
			EscapeAtom dst = l.a;
			if (up) {
				src = l.a;
				dst = l.b;
			}
			bool found = false;
			i64 dist = 0;
			for (EscapeReach const &r : reach) {
				if (escape_eq(r.atom, src)) {
					found = true;
					dist  = r.dist + l.k;
				}
			}
			if (!found) {
				continue;
			}
			bool known = false;
			for (EscapeReach &r : reach) {
				if (escape_eq(r.atom, dst)) {
					known = true;
					if (dist < r.dist) {
						r.dist  = dist;
						changed = true;
					}
				}
			}
			if (!known) {
				array_add(&reach, EscapeReach{dst, dist});
				changed = true;
			}
		}
		if (!changed) {
			break;
		}
	}
	return reach;
}

// whether an atom plus `c` is within what a type holds, from the ranges of what it is known to be between
gb_internal bool escape_limits_fit(Array<EscapeLimit> const &limits, EscapeAtom const &atom, i64 c, EscapeIntRange const &t) {
	bool below = false;
	for (EscapeReach const &r : escape_limits_reach(limits, atom, true)) {
		EscapeIntRange y = {};
		below |= escape_atom_range(r.atom, &y) && y.max + r.dist + c <= t.max;
	}
	if (!below) {
		return false;
	}
	for (EscapeReach const &r : escape_limits_reach(limits, atom, false)) {
		EscapeIntRange y = {};
		if (escape_atom_range(r.atom, &y) && y.min - r.dist + c >= t.min) {
			return true;
		}
	}
	return false;
}

// an integer whose value, as an integer of no size, is an atom's plus `c`, as nothing in it wraps
struct EscapeLinear {
	EscapeAtom atom;
	i64        c;
};

gb_internal bool escape_bounds_linear(EscapeAnalysis *ea, Array<EscapeLimit> const &limits, Ast *x, EscapeLinear *out) {
	enum : i64 { MAX_OFFSET = 1ll<<40 };
	x = unparen_expr(x);
	*out = {};
	if (x == nullptr) {
		return false;
	}
	if (x->tav.mode == Addressing_Constant) {
		ExactValue v = x->tav.value();
		if (v.kind != ExactValue_Integer || mp_count_bits(&v.value_integer) > 40) {
			return false;
		}
		out->c = big_int_to_i64(&v.value_integer);
		return true;
	}
	EscapeIntRange t = {};
	if (!escape_int_range(x->tav.type, &t)) {
		return false;
	}

	Ast *converted = nullptr;
	switch (x->kind) {
	case Ast_Ident:
	case Ast_SelectorExpr:
		return escape_bounds_atom(ea, EscapeAtom_Local, x, &out->atom);

	case_ast_node(ce, CallExpr, x);
		Ast *of = escape_bounds_len_of(ea, x);
		if (of != nullptr) {
			return escape_bounds_atom(ea, EscapeAtom_Len, of, &out->atom);
		}

		if (ce->proc->tav.mode == Addressing_Type && ce->args.count == 1) {
			converted = ce->args[0];
		}
	case_end;

	case_ast_node(tc, TypeCast, x);
		converted = tc->expr;
	case_end;

	case_ast_node(ac, AutoCast, x);
		converted = ac->expr;
	case_end;

	case_ast_node(be, BinaryExpr, x);
		EscapeLinear l = {};
		EscapeLinear r = {};
		if ((be->op.kind != Token_Add && be->op.kind != Token_Sub) ||
		    !escape_bounds_linear(ea, limits, be->left, &l) ||
		    !escape_bounds_linear(ea, limits, be->right, &r)) {
			return false;
		}
		// only an atom plus or minus a constant
		if (be->op.kind == Token_Sub) {
			if (r.atom.kind != EscapeAtom_Zero) {
				return false;
			}
			r.c = -r.c;
		}
		if (r.atom.kind != EscapeAtom_Zero) {
			gb_swap(EscapeLinear, l, r);
		}
		if (r.atom.kind != EscapeAtom_Zero) {
			return false;
		}
		out->atom = l.atom;
		out->c    = l.c + r.c;
		// the sum unless it wraps
		return out->c <= MAX_OFFSET && out->c >= -MAX_OFFSET && escape_limits_fit(limits, out->atom, out->c, t);
	case_end;
	}

	// a conversion keeps the value when it fits
	return converted != nullptr && escape_bounds_linear(ea, limits, converted, out) && escape_limits_fit(limits, out->atom, out->c, t);
}

// whether `p - q <= k` is known
gb_internal bool escape_limits_le(Array<EscapeLimit> const &limits, EscapeLinear const &p, EscapeLinear const &q, i64 k) {
	i64 bound = k - p.c + q.c; // of `p.atom - q.atom`
	EscapeIntRange y = {};
	if (p.atom.kind == EscapeAtom_Zero && q.atom.kind != EscapeAtom_Zero) {
		// at least what it is known to be above, at least the least of that
		for (EscapeReach const &r : escape_limits_reach(limits, q.atom, false)) {
			if (escape_atom_range(r.atom, &y) && y.min - r.dist >= -bound) {
				return true;
			}
		}
		return false;
	}
	// at most `q`, or for a zero `q`, at most what it is known to be below, at most the most of that
	for (EscapeReach const &r : escape_limits_reach(limits, p.atom, true)) {
		if (q.atom.kind == EscapeAtom_Zero ? escape_atom_range(r.atom, &y) && y.max + r.dist <= bound
		                                  : escape_eq(r.atom, q.atom) && r.dist <= bound) {
			return true;
		}
	}
	return false;
}

// that `p - q <= k`
gb_internal void escape_limit_add(Array<EscapeLimit> *limits, EscapeLinear const &p, EscapeLinear const &q, i64 k) {
	enum : isize { MAX_LIMIT_COUNT = 1<<8 };
	k = k - p.c + q.c;
	if (escape_eq(p.atom, q.atom) || k > EscapeLimit::MAX_K || k < -EscapeLimit::MAX_K) {
		return;
	}
	for (EscapeLimit &l : *limits) {
		if (escape_eq(l.a, p.atom) && escape_eq(l.b, q.atom)) {
			l.k = gb_min(l.k, k);
			return;
		}
	}
	if (limits->count < MAX_LIMIT_COUNT) {
		array_add(limits, EscapeLimit{p.atom, q.atom, k});
	}
}

// what a condition being `truth` tells of the integers it compares
gb_internal void escape_limits_refine(EscapeAnalysis *ea, Array<EscapeLimit> *limits, Ast *cond, bool truth) {
	if (!ea->bounds) {
		return;
	}
	auto facts = array_make<EscapeRefine>(temporary_allocator(), 0, 0);
	escape_cond_facts(cond, truth, &facts);
	for (EscapeRefine const &f : facts) {
		ast_node(be, BinaryExpr, f.cond);
		TokenKind op = be->op.kind;
		EscapeLinear l = {};
		EscapeLinear r = {};
		if (!token_is_comparison(op) ||
		    !escape_bounds_linear(ea, *limits, be->left, &l) || !escape_bounds_linear(ea, *limits, be->right, &r)) {
			continue;
		}
		// as `l < r` or `l <= r`
		if (op == Token_Gt || op == Token_GtEq) {
			gb_swap(EscapeLinear, l, r);
			op = op == Token_Gt ? Token_Lt : Token_LtEq;
		}
		i64 strict = op == Token_Lt ? -1 : 0;
		if (op == Token_Lt || op == Token_LtEq) {
			if (f.truth) {
				escape_limit_add(limits, l, r, strict);
			} else {
				escape_limit_add(limits, r, l, -1 - strict);
			}
			continue;
		}
		if ((op == Token_CmpEq) == f.truth) {
			escape_limit_add(limits, l, r, 0);
			escape_limit_add(limits, r, l, 0);
			continue;
		}

		// not equal: not zero where the other is, and above the other where known to be at least it
		EscapeAtom nonzero = {};
		if (r.atom.kind == EscapeAtom_Zero && r.c == l.c) {
			nonzero = l.atom;
		} else if (l.atom.kind == EscapeAtom_Zero && l.c == r.c) {
			nonzero = r.atom;
		}
		if (nonzero.kind != EscapeAtom_Zero) {
			escape_limit_add(limits, EscapeLinear{nonzero}, EscapeLinear{EscapeAtom{EscapeAtom_NonZero}}, 0);
		}
		if (escape_limits_le(*limits, r, l, 0)) {
			escape_limit_add(limits, r, l, -1);
		} else if (escape_limits_le(*limits, l, r, 0)) {
			escape_limit_add(limits, l, r, -1);
		}
	}
}

// what the index of a checkable index or slice expression is compared with
gb_internal bool escape_limits_length(EscapeAnalysis *ea, Ast *node, EscapeLinear *len) {
	enum : i64 { MAX_LENGTH = 1ll<<40 };
	Ast *container = nullptr;
	if (node->kind == Ast_IndexExpr) {
		container = node->IndexExpr.expr;
	} else {
		container = node->SliceExpr.expr;
	}
	Type *t = base_type(type_deref(container->tav.type));
	*len = {};
	switch (t->kind) {
	case Type_Array:
		len->c = t->Array.count;
		return len->c <= MAX_LENGTH;
	case Type_EnumeratedArray:
		// its index less the least of its enum, which is only known as itself when that is zero
		len->c = t->EnumeratedArray.count;
		return len->c <= MAX_LENGTH && compare_exact_values(Token_CmpEq, *t->EnumeratedArray.min_value, exact_value_i64(0));
	case Type_MultiPointer:
		return true;
	}
	return escape_bounds_atom(ea, EscapeAtom_Len, container, &len->atom);
}

// `p - q <= k`
struct EscapeRelation {
	EscapeLinear p;
	EscapeLinear q;
	i64          k;
};

// what the bounds check of a checkable slice expression compares
gb_internal bool escape_limits_slice(EscapeAnalysis *ea, Array<EscapeLimit> const &limits, Ast *node, Array<EscapeRelation> *out) {
	ast_node(se, SliceExpr, node);
	EscapeLinear zero = {};
	EscapeLinear len  = {};
	if (!escape_limits_length(ea, node, &len)) {
		return false;
	}
	EscapeLinear lo = zero;
	EscapeLinear hi = len;
	if ((se->low  != nullptr && !escape_bounds_linear(ea, limits, se->low,  &lo)) ||
	    (se->high != nullptr && !escape_bounds_linear(ea, limits, se->high, &hi))) {
		return false;
	}
	if (base_type(type_deref(se->expr->tav.type))->kind == Type_MultiPointer) {
		// compared as `int`s, which an unsigned past the most `int` is not, as nothing else bounds them
		EscapeIntRange r = {};
		escape_int_range(t_int, &r);
		if (!escape_limits_fit(limits, lo.atom, lo.c, r) || !escape_limits_fit(limits, hi.atom, hi.c, r)) {
			return false;
		}
		array_add(out, EscapeRelation{lo, hi, 0});
		return true;
	}
	if (se->low == nullptr) {
		array_add(out, EscapeRelation{zero, hi, 0});
		array_add(out, EscapeRelation{hi, len, 0});
		return true;
	}
	array_add(out, EscapeRelation{zero, lo, 0});
	array_add(out, EscapeRelation{lo, len, 0});
	array_add(out, EscapeRelation{lo, hi, 0});
	array_add(out, EscapeRelation{hi, len, 0});
	return true;
}

// whether the bounds check of a checkable index or slice expression passes, from what is known of what it compares
gb_internal bool escape_limits_prove(EscapeAnalysis *ea, Array<EscapeLimit> const &limits, Array<Ast *> const &checks, Ast *node) {
	EscapeLinear zero = {};
	if (node->kind == Ast_SliceExpr) {
		auto relations = array_make<EscapeRelation>(temporary_allocator(), 0, 4);
		if (!escape_limits_slice(ea, limits, node, &relations)) {
			return false;
		}
		for (EscapeRelation const &r : relations) {
			if (!escape_limits_le(limits, r.p, r.q, r.k)) {
				return false;
			}
		}
		return true;
	}

	// NOTE(bill): With unsigned, so `0 <= j` and `j < len`, or `0 <= j <= i` with `i` an index which passed the same check,
	// or with `len` not zero, `j` zero or `len - 1` wrapping as `int`s do
	ast_node(ie, IndexExpr, node);
	EscapeLinear len = {};
	EscapeLinear j   = {};
	if (!escape_limits_length(ea, node, &len)) {
		return false;
	}
	bool exact = escape_bounds_linear(ea, limits, ie->index, &j);
	bool above = exact && escape_limits_le(limits, zero, j, 0);
	if (above) {
		if (escape_limits_le(limits, j, len, -1)) {
			return true;
		}
		for (Ast *c : checks) {
			EscapeLinear i = {};
			if (c->kind == Ast_IndexExpr && escape_bounds_length_eq(c->IndexExpr.expr, ie->expr) &&
			    escape_bounds_linear(ea, limits, c->IndexExpr.index, &i) && escape_limits_le(limits, j, i, 0)) {
				return true;
			}
		}
	}

	bool nonzero = escape_limits_le(limits, zero, len, -1) || escape_limits_le(limits, len, zero, -1);
	for (EscapeLimit const &l : limits) {
		EscapeLinear a = {l.a};
		nonzero = nonzero || (l.b.kind == EscapeAtom_NonZero && escape_limits_le(limits, a, len, 0) && escape_limits_le(limits, len, a, 0));
	}
	if (!nonzero) {
		return false;
	}
	if (above && escape_limits_le(limits, j, zero, 0)) {
		return true;
	}

	Ast *index = unparen_expr(ie->index);
	EscapeLinear x   = {};
	EscapeLinear one = {};
	return index->kind == Ast_BinaryExpr && index->BinaryExpr.op.kind == Token_Sub &&
	       type_size_of(index->tav.type) >= type_size_of(t_int) &&
	       escape_bounds_linear(ea, limits, index->BinaryExpr.left, &x) && escape_bounds_linear(ea, limits, index->BinaryExpr.right, &one) &&
	       one.atom.kind == EscapeAtom_Zero && one.c == 1 && escape_limits_le(limits, x, len, 0) && escape_limits_le(limits, len, x, 0);
}

// what a local of an integer holds once set to a value
gb_internal void escape_limits_assign(EscapeAnalysis *ea, Entity *e, Ast *value) {
	EscapeIntRange r = {};
	if (value == nullptr || !escape_bounds_entity(ea, e) || !escape_int_range(e->type, &r)) {
		return;
	}
	EscapeLinear x = {};
	x.atom = EscapeAtom{EscapeAtom_Local, e};
	EscapeLinear v = {};
	if (escape_bounds_linear(ea, ea->state.limits, value, &v)) {
		escape_limit_add(&ea->state.limits, x, v, 0);
		escape_limit_add(&ea->state.limits, v, x, 0);
		return;
	}
	// at most each of `min`, or at least each of `max`
	value = unparen_expr(value);
	if (value->kind != Ast_CallExpr) {
		return;
	}
	BuiltinProcId id = escape_builtin_of(value);
	if (id != BuiltinProc_min && id != BuiltinProc_max) {
		return;
	}
	for (Ast *arg : value->CallExpr.args) {
		if (!escape_bounds_linear(ea, ea->state.limits, arg, &v)) {
			continue;
		}
		if (id == BuiltinProc_min) {
			escape_limit_add(&ea->state.limits, x, v, 0);
		} else {
			escape_limit_add(&ea->state.limits, v, x, 0);
		}
	}
}

gb_internal bool escape_limits_loop_var(EscapeAnalysis *ea, Ast *val, EscapeLinear *out) {
	*out = {};
	EscapeIntRange r = {};
	if (val == nullptr || val->kind != Ast_Ident) {
		return false;
	}
	Entity *e = entity_of_node(val);
	if (!escape_bounds_entity(ea, e) || !escape_int_range(e->type, &r)) {
		return false;
	}
	escape_bounds_forget(ea, e);
	out->atom = EscapeAtom{EscapeAtom_Local, e};
	return true;
}

gb_internal void escape_limits_range(EscapeAnalysis *ea, Ast *stmt, Ast *range, Ast *val0, Ast *val1) {
	range = unparen_expr(range);
	EscapeLinear zero  = {};
	EscapeLinear index = {};
	if (is_ast_range(range)) {
		ast_node(be, BinaryExpr, range);
		EscapeLinear lo = {};
		EscapeLinear hi = {};
		if (escape_limits_loop_var(ea, val0, &index)) {
			// from a constant start, as the start is evaluated once only
			if (escape_bounds_linear(ea, ea->state.limits, be->left, &lo) && lo.atom.kind == EscapeAtom_Zero) {
				escape_limit_add(&ea->state.limits, lo, index, 0);
			}
			if (escape_bounds_linear(ea, ea->state.limits, be->right, &hi)) {
				i64 k = 0;
				if (be->op.kind == Token_RangeHalf) {
					k = -1;
				}
				escape_limit_add(&ea->state.limits, index, hi, k);
			}
		}
		if (escape_limits_loop_var(ea, val1, &index)) {
			escape_limit_add(&ea->state.limits, zero, index, 0);
		}
		return;
	}
	if (range->tav.mode == Addressing_Type || !escape_limits_loop_var(ea, val1, &index)) {
		return;
	}

	// what the index is below: the count taken as the loop began, or read each iteration for a dynamic array
	Type *t = base_type(type_deref(range->tav.type));
	bool by_ptr = is_type_pointer(range->tav.type);
	EscapeLinear len = {};
	switch (t->kind) {
	case Type_Array:
		len.c = t->Array.count;
		break;
	case Type_Slice:
		if (by_ptr) {
			escape_limit_add(&ea->state.limits, zero, index, 0);
			return;
		}
		len.atom = EscapeAtom{EscapeAtom_End, nullptr, stmt};
		break;
	case Type_Basic:
		if (!escape_is_sized_string(t)) {
			return;
		}
		len.atom = EscapeAtom{EscapeAtom_End, nullptr, stmt};
		break;
	case Type_DynamicArray:
		escape_limit_add(&ea->state.limits, zero, index, 0);
		if (by_ptr || !escape_bounds_atom(ea, EscapeAtom_Len, range, &len.atom)) {
			return;
		}
		break;
	default:
		return;
	}
	escape_limit_add(&ea->state.limits, zero, index, 0);
	escape_limit_add(&ea->state.limits, index, len, -1);
}

gb_internal void escape_limits_shift(Array<EscapeLimit> *limits, Entity *e, i64 c) {
	for (isize i = limits->count-1; i >= 0; i--) {
		EscapeLimit &l = (*limits)[i];
		if (l.b.kind == EscapeAtom_NonZero) {
			if (l.a.kind == EscapeAtom_Local && l.a.e == e) {
				array_unordered_remove(limits, i);
			}
			continue;
		}

		if (l.a.kind == EscapeAtom_Local && l.a.e == e) {
			l.k += c;
		}
		if (l.b.kind == EscapeAtom_Local && l.b.e == e) {
			l.k -= c;
		}
		if (l.k > EscapeLimit::MAX_K || l.k < -EscapeLimit::MAX_K) {
			array_unordered_remove(limits, i);
		}
	}
}

gb_internal void escape_bounds_find(EscapeAnalysis *ea, Ast *node, bool fact) {
	if (ea->bounds_off) {
		return;
	}
	EscapeBoundsCheck c = {node, fact};
	if (ea->bounds_context.count > 0) {
		c.context = slice_clone(temporary_allocator(), slice_from_array(ea->bounds_context));
	}
	array_add(&ea->bounds_found, c);
}

// what is evaluated only where a condition is `truth`, e.g. the right of `&&`, whose checks are then not known to pass
gb_internal void escape_scan_where(EscapeAnalysis *ea, Ast *cond, bool truth, Ast *expr, u8 flags) {
	bool nil = (flags & EscapeScan_Nil) != 0;
	Array<EscapeNil> nils = {};
	if (nil) {
		nils = array_clone(temporary_allocator(), ea->state.nils);
		escape_nil_refine(ea, cond, truth);
	}
	array_add(&ea->bounds_context, EscapeRefine{cond, truth});
	escape_scan(ea, expr, flags & ~EscapeScan_Fact);
	array_pop(&ea->bounds_context);
	if (nil) {
		// back to what was nil before, except for what has had its address taken since
		ea->state.nils = nils;
		for (Entity *e : ea->nil_escaped) {
			escape_nil_forget(ea, e);
		}
	}
}

// before an expression is evaluated: its dereferences and reads against what is nil, or unset, before its statement,
// as nothing it does can make a local nil, nor change one whose address was not taken; and the bounds checks it makes,
// once the addresses it takes count, as the backend may evaluate its parts in another order
gb_internal void escape_scan(EscapeAnalysis *ea, Ast *expr, u8 flags) {
	if (!ea->bounds) {
		flags &= ~EscapeScan_Bounds;
	}
	if (!ea->nil_deref && ea->uninit_decls.count == 0) {
		// reads only once something is declared with `---`
		flags &= ~EscapeScan_Nil;
	}
	if ((flags & (EscapeScan_Nil|EscapeScan_Bounds)) == 0 || expr == nullptr ||
	    expr->tav.mode == Addressing_Constant || expr->tav.mode == Addressing_Type) {
		return;
	}

	// the backend keeps an expression's own `#bounds_check` only where it is not an address
	bool bounds_off = ea->bounds_off;
	defer (ea->bounds_off = bounds_off);
	if (expr->state_flags & StateFlag_no_bounds_check) {
		ea->bounds_off = true;
	}

	bool nil    = (flags & EscapeScan_Nil)    != 0;
	bool bounds = (flags & EscapeScan_Bounds) != 0;
	bool fact   = (flags & EscapeScan_Fact)   != 0;
	bool addr   = (flags & EscapeScan_Addr)   != 0;
	u8   value  = flags & ~EscapeScan_Addr;
	u8   first  = value; // of its first part, e.g. what an index expression indexes; the others have `value`

	switch (expr->kind) {
	case_ast_node(i, Ident, expr);
		if (nil && !addr) {
			escape_uninit_read(ea, expr);
		}
	case_end;

	case Ast_ParenExpr:
	case Ast_MatrixIndexExpr:
		// its address is that of its first part, or within it
		first = flags;
		break;

	case_ast_node(ue, UnaryExpr, expr);
		if (ue->op.kind == Token_And) {
			if (nil) {
				escape_nil_escape(ea, ue->expr);
			}
			Entity *root = escape_nil_root(ue->expr);
			if (bounds && root != nullptr && escape_add_unique(&ea->bounds_escaped, root)) {
				escape_bounds_forget(ea, root);
			}
			first |= EscapeScan_Addr;
		}
	case_end;

	case_ast_node(be, BinaryExpr, expr);
		if (be->op.kind == Token_CmpAnd || be->op.kind == Token_CmpOr) {
			escape_scan(ea, be->left, value);
			// NOTE(bill): evaluated only where the left is true for `&&`, or false for `||`
			escape_scan_where(ea, be->left, be->op.kind == Token_CmpAnd, be->right, value);
			return;
		}
	case_end;

	case_ast_node(se, SelectorExpr, expr);
		if (escape_package_selector(expr) != nullptr) {
			return;
		}
		if (is_type_pointer(se->expr->tav.type)) {
			if (nil && !addr) {
				escape_nil_use(ea, se->expr, EscapeReport_NilDeref);
			}
		} else if (addr || (nil && escape_uninit_read(ea, expr))) {
			first |= EscapeScan_Addr;
		}
	case_end;

	case_ast_node(ie, IndexExpr, expr);
		Type *t = base_type(ie->expr->tav.type);
		if (addr) {
			// the elements of an array, or of a #soa one, are within it
			if (escape_is_inline_array(t) || (t != nullptr && t->kind == Type_Struct)) {
				first |= EscapeScan_Addr;
			}
		} else if (nil) {
			if (t != nullptr && (t->kind == Type_Pointer || t->kind == Type_MultiPointer)) {
				escape_nil_use(ea, ie->expr, EscapeReport_NilDeref);
			}
			if (escape_uninit_read(ea, expr)) {
				first |= EscapeScan_Addr;
			}
		}
	case_end;

	case_ast_node(se, SliceExpr, expr);
		if (nil && escape_is_inline_array(base_type(se->expr->tav.type))) {
			escape_nil_escape(ea, se->expr);
			first |= EscapeScan_Addr;
		}
	case_end;

	case_ast_node(de, DerefExpr, expr);
		if (nil && !addr) {
			escape_nil_use(ea, de->expr, EscapeReport_NilDeref);
		}
	case_end;

	case_ast_node(ta, TypeAssertion, expr);
		if (nil && is_type_pointer(ta->expr->tav.type)) {
			escape_nil_use(ea, ta->expr, EscapeReport_NilDeref);
		}
	case_end;

	case_ast_node(ce, CallExpr, expr);
		Ast *proc = unparen_expr(ce->proc);
		if (proc->tav.mode == Addressing_Builtin) {
			// which arguments a builtin evaluates depends on the builtin
			value &= ~EscapeScan_Fact;
		}
		if (proc->tav.mode != Addressing_Type) {
			Entity *e = escape_proc_entity(proc);
			if (nil && is_type_proc(proc->tav.type) && (e == nullptr || e->kind == Entity_Variable)) {
				escape_nil_use(ea, proc, EscapeReport_NilCall);
			}
			// nothing of a call to a disabled procedure is evaluated
			if (e != nullptr && (e->flags & EntityFlag_Disabled) != 0) {
				value &= ~EscapeScan_Fact;
			}
			escape_scan(ea, ce->proc, value);
		}
		first = value;
	case_end;

	case_ast_node(e, Ellipsis, expr);
		first &= ~EscapeScan_Nil;
	case_end;

	case_ast_node(te, TernaryIfExpr, expr);
		escape_scan(ea, te->cond, value);
		escape_scan_where(ea, te->cond, true,  te->x, value);
		escape_scan_where(ea, te->cond, false, te->y, value);
		return;
	case_end;

	case_ast_node(oe, OrElseExpr, expr);
		escape_scan(ea, oe->x, value);
		escape_scan(ea, oe->y, value & ~EscapeScan_Fact);
		return;
	case_end;

	case Ast_OrReturnExpr:
	case Ast_OrBranchExpr:
		ea->bounds_exits |= bounds;
		break;
	}

	Ast *parts[3];
	Slice<Ast *> operands = escape_operands(expr, parts);
	for_array(i, operands) {
		escape_scan(ea, operands[i], i == 0 ? first : value);
	}
	if (bounds && (expr->kind == Ast_IndexExpr || expr->kind == Ast_SliceExpr)) {
		escape_bounds_find(ea, expr, fact);
	}
}

// the checks of a statement, against what passed before it, as nothing it evaluates changes a local whose address
// it does not take; then what passed once it is done, unless it may leave part way, where what runs then, e.g. a
// defer, would see them
gb_internal void escape_bounds_flush(EscapeAnalysis *ea) {
	enum : isize { MAX_CHECK_COUNT = 1<<10 };

	for (EscapeBoundsCheck &c : ea->bounds_found) {
		if (!escape_bounds_checkable(ea, c.node)) {
			c.fact = false;
			continue;
		}
		bool proven = escape_bounds_passed(ea->state.checks, c.node);
		if (!proven) {
			Array<EscapeLimit> limits = ea->state.limits;
			if (c.context.count > 0) {
				limits = array_clone(temporary_allocator(), ea->state.limits);
				for (EscapeRefine const &r : c.context) {
					escape_limits_refine(ea, &limits, r.cond, r.truth);
				}
			}
			proven = escape_limits_prove(ea, limits, ea->state.checks, c.node);
		}
		array_add(&ea->uses, EscapeUse{c.node, EscapeReport_Invalid, proven});
	}
	if (!ea->bounds_exits) {
		// what the slice expressions which passed compare, each read before any is added
		auto relations = array_make<EscapeRelation>(temporary_allocator(), 0, 0);
		for (EscapeBoundsCheck const &c : ea->bounds_found) {
			if (c.fact && c.node->kind == Ast_SliceExpr) {
				escape_limits_slice(ea, ea->state.limits, c.node, &relations);
			}
		}
		for (EscapeBoundsCheck const &c : ea->bounds_found) {
			if (c.fact && ea->state.checks.count < MAX_CHECK_COUNT && !escape_bounds_passed(ea->state.checks, c.node)) {
				array_add(&ea->state.checks, c.node);
			}
		}
		for (EscapeRelation const &r : relations) {
			escape_limit_add(&ea->state.limits, r.p, r.q, r.k);
		}
	}
	array_clear(&ea->bounds_found);
	ea->bounds_exits = false;
}


gb_internal EscapeValue escape_convert(EscapeAnalysis *ea, EscapeValue const &v, Ast *expr, Type *type) {
	if (type == nullptr || expr == nullptr || !is_type_any(type)) {
		return v;
	}

	Type *src = expr->tav.type;
	if (src == nullptr || is_type_any(src) || is_type_untyped_nil(src) || is_type_untyped_uninit(src)) {
		return v;
	}

	// the backend boxes an addressable value by its address, and anything else in a stack temporary
	if (expr->tav.mode == Addressing_Variable) {
		return escape_addr(ea, expr);
	}
	escape_store_obj(ea, {nullptr, expr}, {}, v, EscapeUpdate_Replace);
	return escape_value_of(EscapeOrigin_Temp, {nullptr, expr}, {});
}

gb_internal EscapeValue escape_ident_addr(EscapeAnalysis *ea, Entity *e) {
	if (e == nullptr || e->kind != Entity_Variable) {
		return escape_value();
	}

	if (escape_is_reference(e)) {
		EscapeValue ptr = escape_value();
		for (EscapeAlias const &a : ea->aliases) {
			if (a.e == e) {
				escape_value_add(&ptr, {}, a.origin);
			}
		}
		return ptr;
	}

	if ((e->flags & (EntityFlag_ForValue|EntityFlag_SwitchValue)) != 0) {
		return escape_value();
	}

	if (escape_is_using_field(e)) {
		EscapePath path = {};
		if (!escape_using_path(e, &path)) {
			return escape_value();
		}

		// through what it was applied to, which only a parameter has no expression for
		Entity *parent = e->using_parent;
		EscapeValue base = {};
		if (e->using_expr != nullptr && is_type_pointer(parent->type)) {
			base = escape_expr(ea, e->using_expr);
		} else if (e->using_expr != nullptr) {
			base = escape_addr(ea, e->using_expr);
		} else if (is_type_pointer(parent->type)) {
			base = escape_ident_value(ea, parent);
		} else {
			base = escape_ident_addr(ea, parent);
		}
		return escape_pointer_offset(base, path);
	}

	if (!escape_is_local(e)) {
		return escape_value_of(EscapeOrigin_Outer, {e}, {});
	}
	return escape_value_of(EscapeOrigin_Local, {e}, {}, ea->addr_site);
}

gb_internal EscapeValue escape_ident_value(EscapeAnalysis *ea, Entity *e) {
	if (e == nullptr || e->kind != Entity_Variable) {
		return escape_value();
	}

	if (escape_is_reference(e) || escape_is_using_field(e) || !escape_is_local(e)) {
		return escape_load(ea, escape_ident_addr(ea, e), e->type);
	}

	if (escape_is_param(e)) {
		// a parameter cannot be assigned to
		if (escape_type_is_plain(e->type)) {
			return escape_value();
		}
		if (e == ea->variadic) {
			return escape_value_of(EscapeOrigin_Variadic, {e}, {});
		}
		return escape_value_of(EscapeOrigin_Param, {e}, {});
	}
	return escape_obj_value(ea, {e}, {});
}

gb_internal EscapeValue escape_variant_addr(EscapeAnalysis *ea, Ast *x) {
	Type *t = x->tav.type;
	if (is_type_any(t) || is_type_pointer(t)) {
		return escape_as_pointer(escape_expr(ea, x));
	}
	return escape_addr(ea, x);
}

gb_internal EscapeValue escape_addr(EscapeAnalysis *ea, Ast *expr) {
	if (expr == nullptr) {
		return escape_value();
	}

	Ast *addr_site = ea->addr_site;
	if (addr_site == nullptr) {
		ea->addr_site = expr;
	}
	defer (ea->addr_site = addr_site);

	switch (expr->kind) {
	case_ast_node(pe, ParenExpr, expr);
		return escape_addr(ea, pe->expr);
	case_end;

	case_ast_node(i, Ident, expr);
		return escape_ident_addr(ea, entity_of_node(expr));
	case_end;

	case_ast_node(se, SelectorExpr, expr);
		if (Entity *g = escape_package_selector(expr)) {
			return escape_ident_addr(ea, g);
		}
		EscapePath path = {};
		if (!escape_selector_path(expr, &path)) {
			escape_visit_exits(ea, se->expr);
			return escape_value();
		}
		if (is_type_pointer(se->expr->tav.type)) {
			return escape_pointer_offset(escape_expr(ea, se->expr), path);
		}
		return escape_pointer_offset(escape_addr(ea, se->expr), path);
	case_end;

	case_ast_node(ie, IndexExpr, expr);
		escape_visit_exits(ea, ie->index);
		return escape_elems_of(ea, ie->expr);
	case_end;

	case_ast_node(de, DerefExpr, expr);
		return escape_as_pointer(escape_expr(ea, de->expr));
	case_end;

	case_ast_node(cl, CompoundLit, expr);
		EscapeValue v = escape_expr(ea, expr);
		escape_store_obj(ea, {nullptr, expr}, {}, v, EscapeUpdate_Replace);
		return escape_value_of(EscapeOrigin_Temp, {nullptr, expr}, {});
	case_end;

	case_ast_node(ta, TypeAssertion, expr);
		return escape_variant_addr(ea, ta->expr);
	case_end;

	case_ast_node(mie, MatrixIndexExpr, expr);
		escape_visit_exits(ea, mie->row_index);
		escape_visit_exits(ea, mie->column_index);
		return escape_pointer_offset(escape_addr(ea, mie->expr), escape_path_of(EscapeStep_AnyElement));
	case_end;
	}
	escape_visit_exits(ea, expr);
	return escape_value();
}


gb_internal EscapeValue escape_reachable(EscapeAnalysis *ea, EscapeValue const &v) {
	EscapeValue reached  = escape_value();
	EscapeValue frontier = escape_as_pointer(v);
	while (frontier.count > 0) {
		EscapeValue next = escape_value();
		for (EscapeValueFact const &f : escape_load_once(ea, frontier)) {
			isize count = reached.count;
			escape_value_add(&reached, {}, f.origin);
			if (reached.count != count) {
				escape_value_add(&next, {}, f.origin);
			}
		}
		frontier = next;
	}
	return reached;
}

gb_internal Type *escape_pointee_type_at(Type *type, EscapePath const &path) {
	isize deref = escape_path_deref_index(path);
	Type *pointee = escape_pointee_type(escape_type_within(type, slice(path, 0, deref)));
	if (deref == path.count) {
		return pointee;
	}
	return escape_type_within(pointee, slice(path, deref+1, path.count));
}

gb_internal EscapeValue escape_arg_pointers(EscapeValue const &arg, Type *type, EscapePath const &path, Type **pointee) {
	isize deref = escape_path_deref_index(path);
	EscapePath value_path = slice(path, 0, deref);
	EscapePath offset = {};
	if (deref < path.count) {
		offset = slice(path, deref+1, path.count);
	}
	*pointee = escape_pointee_type_at(type, path);
	if (*pointee == nullptr) {
		// e.g. the offset was made through a cast in the callee
		offset = {};
	}
	return escape_pointer_offset(escape_as_pointer(escape_value_project(arg, value_path)), offset);
}

// NOTE(bill): What a callee stores through the pointers it loads, with the argument's pointers at a path within what it stores,
// unless that path is not one within the memory a local pointer points to
// e.g. through a cast, where it is all of it as before
gb_internal void escape_store_loaded(EscapeAnalysis *ea, Ast *call, EscapeValue const &ptr, EscapeValue const &v, EscapePath const &value_path) {
	EscapeValue within = escape_value();
	escape_value_add_at(&within, value_path, v);
	for (EscapeValueFact const &pf : ptr) {
		bool fits = true;
		switch (pf.origin.kind) {
		case EscapeOrigin_Local:
		case EscapeOrigin_Temp:
		case EscapeOrigin_Owned:
			fits = escape_type_within(escape_type_at(pf.origin.obj, pf.origin.path), value_path) != nullptr;
			break;
		}
		escape_store_through(ea, call, escape_value_one(pf.path, pf.origin, pf.definite), fits ? within : v, EscapeUpdate_Add);
	}
}

gb_internal bool escape_write_matters(EscapeAnalysis *ea, EscapeValue const &arg) {
	for (EscapeValueFact const &a : arg) {
		EscapeOrigin const &o = a.origin;
		switch (o.kind) {
		case EscapeOrigin_Param:
			return true;
		case EscapeOrigin_Outer:
			if (o.obj.entity != nullptr) {
				return true;
			}
			break;
		case EscapeOrigin_Local:
		case EscapeOrigin_Temp:
		case EscapeOrigin_Owned:
			for (EscapeFact const &f : ea->state.facts) {
				if (escape_eq(f.obj, o.obj)) {
					return true;
				}
			}
			break;
		}
	}
	return false;
}

gb_internal Array<EscapeValue> escape_call(EscapeAnalysis *ea, Ast *call) {
	ast_node(ce, CallExpr, call);

	Ast *addr_site = ea->addr_site;
	ea->addr_site = nullptr;
	defer (ea->addr_site = addr_site);

	escape_visit_exits(ea, ce->proc);

	Entity *e = escape_proc_entity(ce->proc);
	Array<EscapeValue> results = {};
	if (e != nullptr && e->kind == Entity_Builtin) {
		results = array_make<EscapeValue>(temporary_allocator(), 0, 1);
		switch (e->Builtin.id) {
		case BuiltinProc_ptr_offset:
			if (ce->args.count == 2) {
				array_add(&results, escape_expr(ea, ce->args[0]));
				escape_visit_exits(ea, ce->args[1]);
				return results;
			}
			break;
		case BuiltinProc_raw_data:
			if (ce->args.count == 1) {
				array_add(&results, escape_elems_of(ea, ce->args[0]));
				return results;
			}
			break;
		case BuiltinProc_mem_copy:
		case BuiltinProc_mem_copy_non_overlapping:
			if (ce->args.count == 3) {
				EscapeValue dst = escape_as_pointer(escape_expr(ea, ce->args[0]));
				EscapeValue src = escape_as_pointer(escape_expr(ea, ce->args[1]));
				escape_visit_exits(ea, ce->args[2]);

				EscapeValue v = escape_value();
				Type *pointee = escape_pointee_type(ce->args[1]->tav.type);
				if (pointee == nullptr || escape_type_has_pointers(pointee)) {
					v = escape_load(ea, src, nullptr);
				}
				escape_store_through(ea, call, dst, v, EscapeUpdate_Replace);
				return results;
			}
			break;
		case BuiltinProc_mem_zero:
		case BuiltinProc_mem_zero_volatile:
			if (ce->args.count == 2) {
				EscapeValue dst = escape_as_pointer(escape_expr(ea, ce->args[0]));
				escape_visit_exits(ea, ce->args[1]);
				escape_store_through(ea, call, dst, escape_value(), EscapeUpdate_Replace);
				return results;
			}
			break;
		}
	}

	TypeProc *pt = nullptr;
	Slice<EscapeFlow> flows = {};

	bool unknown = ce->proc->tav.mode != Addressing_Type && (e == nullptr || e->kind == Entity_Variable || e->kind == Entity_Procedure);

	if (e != nullptr && e->kind == Entity_Procedure) {
		// with the constant parameters of a specialization, as its arguments and summary have them
		Type *t = base_type(proc_entity_full_type(e));
		if (t != nullptr && t->kind == Type_Proc) {
			pt = &t->Proc;

			// none for a foreign procedure or one whose body was not checked, and what it has so far while its group settles
			DeclInfo *d = e->decl_info;
			bool known = d != nullptr && d->proc->proc_info != nullptr;
			if (known && !d->proc->escapes_analysed.load()) {
				// otherwise a call the checker did not record, which should not happen
				known = ea->graph->group_of[d->proc->escape_index] == ea->group;
			}
			if (known && !ea->calls_unknown) {
				flows   = d->proc->escape_flows;
				unknown = d->proc->proc_info->body == nullptr;
			}
		}
	}
	if (flows.count == 0) {
		for (Ast *arg : ce->args) {
			if (arg->kind == Ast_FieldValue) {
				arg = arg->FieldValue.value;
			}
			Type *pointee = escape_pointee_type(arg->tav.type);
			if (unknown && escape_type_has_pointers(pointee != nullptr ? pointee : arg->tav.type)) {
				// what it is given a pointer to may be written over
				escape_store_through(ea, call, escape_as_pointer(escape_expr(ea, arg)), escape_value(), EscapeUpdate_Replace);
			} else {
				escape_visit_exits(ea, arg);
			}
		}
		return {};
	}

	results = array_make<EscapeValue>(temporary_allocator(), pt->result_count);
	for (EscapeValue &r : results) {
		r = escape_value();
	}

	// the value of each argument which a flow involves
	auto args  = array_make<EscapeValue>(temporary_allocator(), pt->param_count);
	auto types = array_make<Type *>(temporary_allocator(), pt->param_count);
	auto given = array_make<bool>(temporary_allocator(), pt->param_count);
	for (EscapeValue &arg : args) {
		arg = escape_value();
	}

	bool packs_variadic = pt->variadic && !pt->c_vararg && ce->ellipsis.pos.line == 0;
	for_array(i, ce->args) {
		Ast *arg = ce->args[i];
		Ast *value = arg;
		if (arg->kind == Ast_FieldValue) {
			value = arg->FieldValue.value;
		}

		// the parameter it is passed to
		isize index = i;
		bool has_param = false;
		if (arg->kind != Ast_FieldValue) {
			if (pt->variadic && i > pt->variadic_index) {
				index = pt->variadic_index;
			}
			has_param = index < pt->param_count;
		} else if (pt->params != nullptr) {
			index     = escape_field_index(pt->params->Tuple.variables, arg->FieldValue.field);
			has_param = index >= 0;
		}

		bool involved = false;
		if (has_param) {
			for (EscapeFlow const &flow : flows) {
				involved |= flow.param == index;
				switch (flow.target) {
				case EscapeFlowTarget_Pointee:
				case EscapeFlowTarget_Loaded:
				case EscapeFlowTarget_Deep:
					involved |= flow.target_index == index;
					break;
				}
			}
		}
		if (!involved) {
			escape_visit_exits(ea, value);
			continue;
		}

		Type *type = pt->params->Tuple.variables[index]->type;
		given[index] = true;
		types[index] = value->tav.type;
		if (packs_variadic && index == pt->variadic_index && arg->kind != Ast_FieldValue) {
			types[index] = type;
			// these are passed in a slice in the stack frame of this procedure
			Type *slice = base_type(type);
			Type *elem = nullptr;
			if (slice->kind == Type_Slice) {
				elem = slice->Slice.elem;
			}
			EscapeValue v = escape_convert(ea, escape_expr(ea, value), value, elem);
			escape_store_obj(ea, {nullptr, call}, escape_path_of(EscapeStep_AnyElement), v, EscapeUpdate_Add);
			args[index] = escape_value_of(EscapeOrigin_Temp, {nullptr, call}, escape_path_of(EscapeStep_AnyElement));
			continue;
		}
		args[index] = escape_convert(ea, escape_expr(ea, value), value, type);
	}

	for (EscapeFlow const &flow : flows) {
		if (flow.kind != EscapeFlow_Write) {
			continue;
		}
		if (flow.target == EscapeFlowTarget_Outer) {
			escape_store_through(ea, call, escape_value_of(EscapeOrigin_Outer, {flow.global}, flow.target_path), escape_value(), EscapeUpdate_Replace);
		} else if (given[flow.target_index] && escape_write_matters(ea, args[flow.target_index])) {
			Type *pointee = nullptr;
			EscapeValue ptr = escape_arg_pointers(args[flow.target_index], types[flow.target_index], flow.target_path, &pointee);
			escape_store_through(ea, call, ptr, escape_value(), EscapeUpdate_Replace);
		}
	}

	for (EscapeFlow const &flow : flows) {
		if (flow.kind == EscapeFlow_Write || !given[flow.param]) {
			continue;
		}
		EscapeValue v = {};
		Type *v_type = nullptr;
		if (flow.kind == EscapeFlow_Value && escape_path_deref_index(flow.param_path) == flow.param_path.count) {
			v = escape_value_project(args[flow.param], flow.param_path);
			v_type = escape_type_within(types[flow.param], flow.param_path);
		} else {
			Type *pointee = nullptr;
			v = escape_arg_pointers(args[flow.param], types[flow.param], flow.param_path, &pointee);
			if (flow.kind != EscapeFlow_Value) {
				if (pointee != nullptr && !escape_type_has_pointers(pointee)) {
					continue;
				}
				v = escape_load_once(ea, v);
				v_type = pointee;
				if (pointee == nullptr) {
					// NOTE(bill): the paths of what is loaded are of another type, which could otherwise nest without end in a loop
					v = escape_as_pointer(v);
				}
			}
		}

		// NOTE(bill): likewise when it goes somewhere of another type, e.g. all of `p^` loaded into `p.name`
		switch (flow.target) {
		case EscapeFlowTarget_Result: {
			Type *t = escape_type_within(pt->results->Tuple.variables[flow.target_index]->type, flow.target_path);
			if (v_type != nullptr && t != nullptr && !are_types_identical(v_type, t)) {
				v = escape_as_pointer(v);
			}
			for (EscapeValueFact const &f : v) {
				escape_value_add(&results[flow.target_index], escape_path_concat(flow.target_path, f.path), f.origin);
			}
			break;
		}

		case EscapeFlowTarget_Pointee:
		case EscapeFlowTarget_Loaded:
		case EscapeFlowTarget_Deep:
			if (given[flow.target_index]) {
				Type *pointee = nullptr;
				EscapeValue ptr = escape_arg_pointers(args[flow.target_index], types[flow.target_index], flow.target_path, &pointee);
				if (flow.target != EscapeFlowTarget_Pointee) {
					ptr = escape_as_pointer(escape_load_once(ea, ptr));
				} else if (v_type != nullptr && pointee != nullptr && !are_types_identical(v_type, pointee)) {
					v = escape_as_pointer(v);
				}
				if (flow.target == EscapeFlowTarget_Deep) {
					ptr = escape_reachable(ea, ptr);
				}
				if (flow.value_path.count > 0) {
					escape_store_loaded(ea, call, ptr, v, flow.value_path);
				} else {
					escape_store_through(ea, call, ptr, v, EscapeUpdate_Add);
				}
			}
			break;

		case EscapeFlowTarget_Outer: {
			EscapeValue within = escape_value();
			escape_value_add_at(&within, flow.value_path, v);
			escape_store_through(ea, call, escape_value_of(EscapeOrigin_Outer, {flow.global}, flow.target_path), within, EscapeUpdate_Add);
			break;
		}
		}
	}
	return results;
}

gb_internal EscapeValue escape_expr(EscapeAnalysis *ea, Ast *expr) {
	if (expr == nullptr) {
		return escape_value();
	}

	// an address taken within another has its own site, e.g. `&b` in `&a[f(&b)]`
	Ast *addr_site = ea->addr_site;
	ea->addr_site = nullptr;
	defer (ea->addr_site = addr_site);

	AstTypeAndValue const &tav = expr->tav;
	if (tav.mode == Addressing_Constant) {
		ExactValueKind value_kind = tav.value().kind;
		// String constants are loaded into read-only memory, they do not use the memory of the stack frame.
		if (tav.type == nullptr || !is_type_slice(tav.type) || value_kind == ExactValue_String || value_kind == ExactValue_String16) {
			return escape_value();
		}
		if (expr->kind == Ast_CompoundLit && expr->CompoundLit.elems.count == 0) {
			return escape_value();
		}
		// a constant slice uses the memory of the stack frame
		return escape_value_of(EscapeOrigin_Temp, {nullptr, expr}, escape_path_of(EscapeStep_AnyElement));
	}

	if (tav.type != nullptr && escape_type_is_plain(tav.type) &&
	    (expr->viral_state_flags & (ViralStateFlag_ContainsOrReturn|ViralStateFlag_ContainsOrBreak)) == 0) {
		escape_visit_exits(ea, expr);
		return escape_value();
	}

	switch (expr->kind) {
	case_ast_node(pe, ParenExpr, expr);
		return escape_expr(ea, pe->expr);
	case_end;

	case_ast_node(i, Ident, expr);
		return escape_ident_value(ea, entity_of_node(expr));
	case_end;

	case_ast_node(cl, CompoundLit, expr);
		EscapeValue v = escape_value();
		Type *t = base_type(expr->tav.type);
		if (t == nullptr) {
			return v;
		}
		for_array(i, cl->elems) {
			Ast *elem = cl->elems[i];
			Ast *value = elem;
			EscapePath path = escape_path_of(EscapeStep_AnyElement);
			Type *elem_type = nullptr;
			if (elem->kind == Ast_FieldValue) {
				value = elem->FieldValue.value;
			}

			if (t->kind == Type_Struct) {
				isize index = i;
				if (elem->kind == Ast_FieldValue) {
					index = escape_field_index(t->Struct.fields, elem->FieldValue.field);
				}
				path = {};
				if (0 <= index && index < t->Struct.fields.count) {
					Entity *f = t->Struct.fields[index];
					elem_type = f->type;
					if (!t->Struct.is_raw_union) {
						path = escape_path_of(EscapeStep_Field, f);
					}
				}
			} else {
				elem_type = escape_elem_type(t);
				if (elem_type == nullptr) {
					path = {};
				}
			}
			if (elem_type != nullptr && escape_type_is_plain(elem_type)) {
				escape_visit_exits(ea, value);
				continue;
			}
			escape_value_add_at(&v, path, escape_convert(ea, escape_expr(ea, value), value, elem_type));
		}

		if (t->kind == Type_Slice) {
			if (cl->elems.count == 0) {
				return escape_value();
			}
			escape_store_obj(ea, {nullptr, expr}, {}, v, EscapeUpdate_Add);
			return escape_value_of(EscapeOrigin_Temp, {nullptr, expr}, escape_path_of(EscapeStep_AnyElement));
		}
		return v;
	case_end;

	case_ast_node(ue, UnaryExpr, expr);
		if (ue->op.kind == Token_And) {
			return escape_addr(ea, unparen_expr(ue->expr));
		}
	case_end;

	case_ast_node(se, SelectorExpr, expr);
		if (Entity *g = escape_package_selector(expr)) {
			return escape_ident_value(ea, g);
		}
		EscapePath path = {};
		if (!escape_selector_path(expr, &path)) {
			break;
		}
		if (is_type_pointer(se->expr->tav.type)) {
			return escape_load(ea, escape_pointer_offset(escape_expr(ea, se->expr), path), tav.type);
		}
		return escape_value_project(escape_expr(ea, se->expr), path);
	case_end;

	case_ast_node(ie, IndexExpr, expr);
		Type *t = base_type(ie->expr->tav.type);
		switch (t != nullptr ? t->kind : Type_Invalid) {
		case Type_Array:
		case Type_EnumeratedArray:
		case Type_FixedCapacityDynamicArray:
		case Type_DynamicArray:
		case Type_Map: {
			EscapeValue v = escape_value_project(escape_expr(ea, ie->expr), escape_path_of(EscapeStep_AnyElement));
			escape_visit_exits(ea, ie->index);
			return v;
		}
		case Type_Pointer:
		case Type_Slice:
		case Type_MultiPointer: {
			EscapeValue ptr = escape_elems_of(ea, ie->expr);
			escape_visit_exits(ea, ie->index);
			return escape_load(ea, ptr, tav.type);
		}
		}
	case_end;

	case_ast_node(de, DerefExpr, expr);
		return escape_load(ea, escape_expr(ea, de->expr), tav.type);
	case_end;

	case_ast_node(se, SliceExpr, expr);
		escape_visit_exits(ea, se->low);
		escape_visit_exits(ea, se->high);
		return escape_elems_of(ea, se->expr);
	case_end;

	case_ast_node(ce, CallExpr, expr);
		if (ce->proc->tav.mode == Addressing_Type) {
			if (ce->args.count != 1) {
				return escape_value();
			}
			Ast *arg = ce->args[0];
			EscapeValue v = escape_expr(ea, arg);
			if (escape_is_explicit_unsafe_conversion(tav.type)) {
				return escape_value();
			}
			return escape_convert(ea, v, arg, tav.type);
		}
		Array<EscapeValue> results = escape_call(ea, expr);
		if (results.count > 0) {
			return results[0];
		}
		return escape_value();
	case_end;

	case_ast_node(sce, SelectorCallExpr, expr);
		return escape_expr(ea, sce->call);
	case_end;

	case_ast_node(tc, TypeCast, expr);
		EscapeValue v = escape_expr(ea, tc->expr);
		if (tc->token.kind == Token_transmute ||
		    escape_is_explicit_unsafe_conversion(tav.type)) {
			return escape_value();
		}
		return escape_convert(ea, v, tc->expr, tav.type);
	case_end;

	case_ast_node(ac, AutoCast, expr);
		return escape_convert(ea, escape_expr(ea, ac->expr), ac->expr, tav.type);
	case_end;

	case_ast_node(te, TernaryIfExpr, expr);
		escape_visit_exits(ea, te->cond);
		EscapeValue v = escape_expr(ea, te->x);
		escape_value_merge(&v, escape_expr(ea, te->y));
		return v;
	case_end;

	case_ast_node(te, TernaryWhenExpr, expr);
		return escape_expr(ea, escape_when_branch(expr));
	case_end;

	case_ast_node(oe, OrElseExpr, expr);
		EscapeValue v = escape_expr(ea, oe->x);
		escape_value_merge(&v, escape_expr(ea, oe->y));
		return v;
	case_end;

	case_ast_node(re, OrReturnExpr, expr);
		EscapeValue v = escape_expr(ea, re->expr);
		EscapeState state = escape_state_clone(ea->state);
		escape_nil_forget_results(ea);
		escape_exit(ea, expr, {}, {});
		ea->state = state;
		return v;
	case_end;

	case_ast_node(be, OrBranchExpr, expr);
		EscapeValue v = escape_expr(ea, be->expr);
		EscapeState state = escape_state_clone(ea->state);
		switch (be->token.kind) {
		case Token_or_break:    escape_branch(ea, be->label, Token_break);    break;
		case Token_or_continue: escape_branch(ea, be->label, Token_continue); break;
		default: GB_PANIC("Unhandled OrBranchExpr"); break;
		}
		ea->state = state;
		return v;
	case_end;

	case_ast_node(ta, TypeAssertion, expr);
		Type *t = ta->expr->tav.type;
		if (is_type_any(t) || is_type_pointer(t)) {
			return escape_load(ea, escape_variant_addr(ea, ta->expr), tav.type);
		}
		return escape_as_pointer(escape_expr(ea, ta->expr));
	case_end;

	case_ast_node(te, TagExpr, expr);
		return escape_expr(ea, te->expr);
	case_end;

	case_ast_node(fv, FieldValue, expr);
		return escape_expr(ea, fv->value);
	case_end;
	}
	// what is left of its value is not kept, e.g. a binary expression's
	Ast *parts[3];
	for (Ast *part : escape_operands(expr, parts)) {
		escape_visit_exits(ea, part);
	}
	return escape_value();
}



gb_internal bool escape_is_stack(EscapeOrigin const &o) {
	switch (o.kind) {
	case EscapeOrigin_Local:
	case EscapeOrigin_Temp:
	case EscapeOrigin_Variadic:
		return true;
	}
	return false;
}

// `held` is where the pointer is within the value, unless it was found through the buffer of a local dynamic array or map
gb_internal bool escape_find_stack_origin(EscapeAnalysis *ea, EscapeValue const &v, EscapeOrigin *found, bool *definite=nullptr, EscapePath *held=nullptr) {
	for (EscapeValueFact const &f : v) {
		if (f.definite && escape_is_stack(f.origin)) {
			*found = f.origin;
			if (definite) {
				*definite = true;
			}
			if (held) {
				*held = f.path;
			}
			return true;
		}
	}

	auto work = array_make<EscapeOrigin>(temporary_allocator(), 0, 0);
	for (EscapeValueFact const &f : v) {
		array_add(&work, f.origin);
	}
	for (isize i = 0; i < work.count; i++) {
		EscapeOrigin o = work[i];
		if (escape_is_stack(o)) {
			*found = o;
			if (held && i < v.count) {
				*held = v[i].path;
			}
			return true;
		}
		if (o.kind != EscapeOrigin_Owned) {
			continue;
		}

		for (EscapeFact const &f : ea->state.facts) {
			if (escape_eq(f.obj, o.obj) && escape_paths_overlap(f.path, o.path)) {
				escape_add_unique(&work, f.origin);
			}
		}
	}
	return false;
}

// a long expression, e.g. a large compound literal, is abbreviated
gb_internal gbString escape_expr_to_string(Ast *expr) {
	gbString s = expr_to_string(expr);
	if (gb_string_length(s) > 80) {
		gb_string_free(s);
		s = expr_to_string_shorthand(expr);
	}
	return s;
}

// the fields a path goes through within a value of the type, e.g. `.a.b` of `.a.b[_]`
gb_internal gbString escape_append_fields(gbString s, Type *t, EscapePath const &path) {
	for (EscapeStep const &step : path) {
		if (step.kind != EscapeStep_Field || !escape_struct_has_field(base_type(t), step.field)) {
			break;
		}
		if (step.field->token.string.len == 0 || is_blank_ident(step.field->token)) {
			break;
		}
		s = gb_string_append_fmt(s, ".%.*s", LIT(step.field->token.string));
		t = step.field->type;
	}
	return s;
}

// on the line shown with the report of the node, or within the node
gb_internal bool escape_site_shown(Ast *node, Ast *site) {
	TokenPos pos   = ast_token(site).pos;
	TokenPos start = ast_token(node).pos;
	if (pos.file_id != start.file_id) {
		return false;
	}
	if (pos.line == start.line) {
		return true;
	}
	if (!is_ast_expr(node)) {
		return false;
	}

	TokenPos end = ast_end_token(node).pos;
	return start.offset <= pos.offset && pos.offset <= end.offset;
}

gb_internal void escape_report_emit(EscapeReport const &r) {
	Ast *node = r.node;
	String expr_str = r.expr_str;
	EscapeOrigin const &o = r.origin;
	EscapeReportKind kind = r.kind;

	TEMPORARY_ALLOCATOR_GUARD();
	gbString origin = gb_string_make(temporary_allocator(), "");
	if (r.target.len > 0) {
		origin = gb_string_append_fmt(origin, "'%.*s' in ", LIT(r.target));
	}
	char const *temp_description = "temporary value";
	switch (o.kind) {
	case EscapeOrigin_Local: {
		char const *description = "local variable";
		if (o.obj.entity->flags & EntityFlag_Result) {
			description = "named result";
		} else if (o.obj.entity->flags & EntityFlag_Param) {
			description = "parameter";
		}
		origin = gb_string_append_fmt(origin, "the stack memory of the %s '%.*s'", description, LIT(o.obj.entity->token.string));
		break;
	}
	case EscapeOrigin_Temp: {
		if (o.obj.temp->kind == Ast_CompoundLit) {
			temp_description = "compound literal";
		}
		origin = gb_string_append_fmt(origin, "the stack memory of a %s", temp_description);
		break;
	}
	case EscapeOrigin_Variadic:
		origin = gb_string_append_fmt(origin, "the variadic parameter '%.*s', which only lives for the duration of the call", LIT(o.obj.entity->token.string));
		break;
	}

	String held = r.held;
	if (held.len == 0) {
		held = str_lit("it");
	}

	ERROR_BLOCK();
	switch (kind) {
	case EscapeReport_Return:
		error(ast_token(node), "It is unsafe to return '%.*s' from a procedure, as %.*s refers to %s", LIT(expr_str), LIT(held), origin);
		break;
	case EscapeReport_MayReturn:
		warning(ast_token(node), "It is unsafe to return '%.*s' from a procedure, as %.*s may refer to %s", LIT(expr_str), LIT(held), origin);
		break;
	case EscapeReport_Store:
		warning(ast_token(node), "'%.*s' may still refer to %s after the procedure returns", LIT(expr_str), origin);
		break;
	case EscapeReport_CallStore:
		warning(ast_token(node), "'%.*s' may keep a reference to %s after the procedure returns", LIT(expr_str), origin);
		break;
	case EscapeReport_NilDeref:
		error(ast_token(node), "Dereferencing '%.*s', which is always nil here", LIT(expr_str));
		return;
	case EscapeReport_NilCall:
		error(ast_token(node), "Calling '%.*s', which is always nil here", LIT(expr_str));
		return;
	case EscapeReport_UninitRead:
		error(ast_token(node), "Reading '%.*s' before anything is stored in it", LIT(expr_str));
		return;
	default:
		GB_PANIC("Unhandled EscapeReportKind");
		break;
	}

	if (o.kind == EscapeOrigin_Local && o.site != nullptr && !escape_site_shown(node, o.site)) {
		gbString site = escape_expr_to_string(o.site);
		error_line("\tThe address of '%s' is taken at %s\n", site, token_pos_to_string(ast_token(o.site).pos));
		gb_string_free(site);
	} else if (o.kind == EscapeOrigin_Temp && !escape_site_shown(node, o.obj.temp)) {
		error_line("\tThe %s is made at %s\n", temp_description, token_pos_to_string(ast_token(o.obj.temp).pos));
	}

	if (r.self_ref) {
		String   name = o.obj.entity->token.string;
		gbString type = type_to_string(o.obj.entity->type);
		error_line("\tNote: '%.*s' holds a pointer into itself. A returned copy would still point into the original in this procedure's stack frame\n", LIT(name));
		error_line("\tSuggestion: Initialize '%.*s' in place through a pointer parameter instead, e.g. '%.*s: ^%s'\n", LIT(name), LIT(name), type);
		gb_string_free(type);
	} else if (kind == EscapeReport_Store) {
		error_line("\tSuggestion: Clear it before the procedure returns, e.g. 'defer %.*s = %s'\n", LIT(expr_str), type_zero_value_string(node->tav.type));
	} else {
		error_line("\tSuggestion: If this is intended, make it explicit with a conversion to 'rawptr' or 'uintptr', or a 'transmute'\n");
	}
}

gb_internal void escape_report(EscapeAnalysis *ea, Ast *node, String expr_str, EscapeOrigin const &o, EscapeReportKind kind, String held={}, bool self_ref=false) {
	if (ea->muted || (kind != EscapeReport_Return && global_ignore_warnings())) {
		return;
	}
	if (!escape_add_unique(&ea->reported, node)) {
		return;
	}

	EscapeReport r = {kind, node, expr_str, o};
	r.expr_str = copy_string(permanent_allocator(), expr_str);
	r.held     = copy_string(permanent_allocator(), held);
	r.self_ref = self_ref;

	// the paths are gone with the analysis' temporary memory by the time it is emitted
	if (o.kind == EscapeOrigin_Local) {
		String   name   = o.obj.entity->token.string;
		gbString target = gb_string_make_length(temporary_allocator(), name.text, name.len);
		target = escape_append_fields(target, o.obj.entity->type, o.path);
		if (gb_string_length(target) > name.len) {
			r.target = copy_string(permanent_allocator(), make_string_c(target));
		}
	}
	r.origin.path = {};
	array_add(ea->reports, r);
}

// `v` is returned as `result` by `expr`, which is null for a bare return of the named results
gb_internal void escape_report_value(EscapeAnalysis *ea, Ast *node, Ast *expr, Entity *result, EscapeValue const &v) {
	EscapeOrigin o = {};
	bool definite = false;
	EscapePath held_path = {};
	if (!escape_find_stack_origin(ea, v, &o, &definite, &held_path)) {
		return;
	}

	EscapeReportKind kind = EscapeReport_MayReturn;
	if (definite) {
		kind = EscapeReport_Return;
	}

	Ast *    x        = unparen_expr(expr);
	String   expr_str = result->token.string;
	gbString expr_s   = nullptr;
	Entity * returned = result;
	if (x != nullptr) {
		expr_s   = escape_expr_to_string(expr);
		expr_str = make_string_c(expr_s);
		returned = nullptr;
		if (x->kind == Ast_Ident) {
			returned = entity_of_node(x);
		}
	}

	// the fields of what is returned, which may be another anonymous struct of the same layout as the result
	Type *type = result->type;
	if (x != nullptr && x->tav.type != nullptr && !is_type_tuple(x->tav.type)) {
		type = x->tav.type;
	}

	gbString fields = escape_append_fields(gb_string_make(temporary_allocator(), ""), type, held_path);
	gbString held   = gb_string_make(temporary_allocator(), "");
	if (gb_string_length(fields) > 0) {
		if (x == nullptr || x->kind == Ast_Ident || x->kind == Ast_SelectorExpr) {
			held = gb_string_append_fmt(held, "'%.*s%s'", LIT(expr_str), fields);
		} else {
			held = gb_string_append_fmt(held, "its field '%s'", fields+1);
		}
	}

	bool self_ref = o.kind == EscapeOrigin_Local && returned != nullptr && o.obj.entity == returned;
	escape_report(ea, node, expr_str, o, kind, make_string_c(held), self_ref);
	if (expr_s != nullptr) {
		gb_string_free(expr_s);
	}
}

gb_internal void escape_run_defers(EscapeAnalysis *ea, isize depth) {
	// an exit within a running defer (`return`, `or_return` or a branch out of it, which the checker reports)
	// runs only the defers of the blocks within it: running the others again would never end (#8074)
	depth = gb_max(depth, ea->defers_floor);
	isize floor = ea->defers_floor;
	ea->defers_floor = ea->defers.count;
	for (isize i = ea->defers.count-1; i >= depth; i--) {
		Array<Ast *> defers = array_clone(temporary_allocator(), ea->defers[i]);
		for (isize j = defers.count-1; j >= 0; j--) {
			escape_stmt(ea, defers[j]);
		}
	}
	ea->defers_floor = floor;
}

gb_internal bool escape_param_index(TypeProc *pt, Entity *e, isize *index) {
	if (pt->params == nullptr) {
		return false;
	}
	for_array(i, pt->params->Tuple.variables) {
		if (pt->params->Tuple.variables[i] == e) {
			*index = i;
			return true;
		}
	}
	// e.g. 'context'
	return false;
}

gb_internal bool escape_flow_from(TypeProc *pt, EscapeOrigin const &o, EscapeFlow *flow) {
	switch (o.kind) {
	case EscapeOrigin_Param:     flow->kind = EscapeFlow_Value; break;
	case EscapeOrigin_ParamLoad: flow->kind = EscapeFlow_Load;  break;
	default:
		return false;
	}
	flow->param_path = o.path;
	return escape_param_index(pt, o.obj.entity, &flow->param);
}

gb_internal bool escape_eq(EscapeFlow const &a, EscapeFlow const &b) {
	return a.kind         == b.kind         &&
	       a.param        == b.param        &&
	       a.target       == b.target       &&
	       a.target_index == b.target_index &&
	       a.global       == b.global       &&
	       escape_path_eq(a.param_path,  b.param_path) &&
	       escape_path_eq(a.target_path, b.target_path) &&
	       escape_path_eq(a.value_path,  b.value_path);
}

// a path is cut before a step repeating an earlier one, as otherwise a recursive procedure could make its flows
// grow without end, e.g. when the elements of the dynamic array it returns hold what its calls return
gb_internal EscapePath escape_path_widen(EscapePath const &p) {
	isize segment = 0;
	for_array(i, p) {
		if (p[i].kind == EscapeStep_Deref) {
			segment = i+1;
			continue;
		}
		for (isize j = segment; j < i; j++) {
			if (p[j].kind == p[i].kind && p[j].field == p[i].field) {
				return slice(p, 0, i);
			}
		}
	}
	return p;
}

gb_internal void escape_add_flow(EscapeAnalysis *ea, EscapeFlow flow) {
	flow.param_path  = escape_path_widen(flow.param_path);
	flow.target_path = escape_path_widen(flow.target_path);
	flow.value_path  = escape_path_widen(flow.value_path);
	escape_add_unique(&ea->flows, flow);
}

gb_internal void escape_add_result_flows(EscapeAnalysis *ea, isize result_index, EscapeValue const &v) {
	for (EscapeValueFact const &f : v) {
		EscapeFlow flow = {};
		if (escape_flow_from(ea->pt, f.origin, &flow)) {
			flow.target       = EscapeFlowTarget_Result;
			flow.target_index = result_index;
			flow.target_path  = f.path;
			escape_add_flow(ea, flow);
		}
	}
}

gb_internal void escape_exit(EscapeAnalysis *ea, Ast *node, Slice<Ast *> const &results, Array<EscapeValue> const &values) {
	TypeProc *pt = ea->pt;
	if (pt->results != nullptr) {
		// a return, or `or_return`, may set the named results
		for (Entity *e : pt->results->Tuple.variables) {
			escape_bounds_forget(ea, e);
		}
	}

	// what is returned is fixed before the defers run, and is what the named results hold for them
	if (values.count == pt->result_count) {
		escape_nil_forget_results(ea);
		for (isize i = 0; i < pt->result_count; i++) {
			Ast *result = results[0]; // the single call of several results
			if (results.count == values.count) {
				result = results[i];
			}
			escape_report_value(ea, result, result, pt->results->Tuple.variables[i], values[i]);
			escape_add_result_flows(ea, i, values[i]);
		}
	} else if (pt->has_named_results) {
		for_array(i, pt->results->Tuple.variables) {
			Entity *e = pt->results->Tuple.variables[i];
			EscapeValue v = escape_obj_value(ea, {e}, {});
			escape_report_value(ea, node, nullptr, e, v);
			escape_add_result_flows(ea, i, v);
		}
	}

	escape_run_defers(ea, 0);

	for (EscapeOuterStore const &s : ea->state.outers) {
		EscapeOrigin o = {};
		if (escape_find_stack_origin(ea, escape_value_one({}, s.origin), &o) && o.kind != EscapeOrigin_Variadic) {
			EscapeReportKind kind = EscapeReport_Store;
			if (s.node->kind == Ast_CallExpr) {
				kind = EscapeReport_CallStore;
			}
			gbString str = escape_expr_to_string(s.node);
			escape_report(ea, s.node, make_string_c(str), o, kind);
			gb_string_free(str);
		}

		// what of the caller's memory it stores, and where, for the callers
		EscapeFlow flow = {};
		if (!escape_flow_from(ea->pt, s.origin, &flow)) {
			continue;
		}
		switch (s.dest.kind) {
		case EscapeOrigin_Outer:     flow.target = EscapeFlowTarget_Outer;   break;
		case EscapeOrigin_Param:     flow.target = EscapeFlowTarget_Pointee; break;
		case EscapeOrigin_ParamLoad: flow.target = EscapeFlowTarget_Loaded;  break;
		case EscapeOrigin_ParamDeep: flow.target = EscapeFlowTarget_Deep;    break;
		default:
			continue;
		}
		if (flow.target == EscapeFlowTarget_Outer) {
			if (s.location.root != nullptr && !escape_is_local(s.location.root)) {
				flow.global      = s.location.root;
				flow.target_path = s.location.path;
				flow.value_path  = s.value_path;
			}
		} else {
			// NOTE(bill): where in what is stored its pointer is, which for memory loaded through the argument is only known without an offset into it
			flow.target_path = s.dest.path;
			if (flow.target == EscapeFlowTarget_Pointee) {
				flow.target_path = escape_origin_offset(s.dest, s.value_path).path;
			} else if (!s.dest.offset_lost) {
				flow.value_path = s.value_path;
			}
			if (!escape_param_index(ea->pt, s.dest.obj.entity, &flow.target_index)) {
				continue;
			}
			if (flow.target_index == flow.param && (flow.kind == EscapeFlow_Load ||
			    (flow.target == EscapeFlowTarget_Pointee && escape_path_eq(flow.target_path, flow.param_path)))) {
				continue;
			}
		}
		escape_add_flow(ea, flow);
	}
	ea->state.reachable = false;
}

// where a store goes, through the pointers it loads
gb_internal void escape_outer_location(Ast *lhs, EscapeLocation *loc) {
	lhs = unparen_expr(lhs);
	*loc = {};
	switch (lhs->kind) {
	case_ast_node(i, Ident, lhs);
		Entity *e = entity_of_node(lhs);
		EscapePath field = {};
		if (e == nullptr || !escape_is_using_field(e) || !escape_using_path(e, &field)) {
			*loc = {e};
			return;
		}

		// the same as the selector through what it was applied to
		if (e->using_expr != nullptr) {
			escape_outer_location(e->using_expr, loc);
		} else {
			*loc = {e->using_parent};
		}
		if (is_type_pointer(e->using_parent->type)) {
			loc->path = escape_path_concat(loc->path, escape_path_of(EscapeStep_Deref));
		}
		loc->path = escape_path_concat(loc->path, field);
	case_end;

	case_ast_node(se, SelectorExpr, lhs);
		if (Entity *g = escape_package_selector(lhs)) {
			*loc = {g};
			return;
		}

		EscapePath field = {};
		if (!escape_selector_path(lhs, &field)) {
			return;
		}

		escape_outer_location(se->expr, loc);
		if (is_type_pointer(se->expr->tav.type)) {
			loc->path = escape_path_concat(loc->path, escape_path_of(EscapeStep_Deref));
		}
		loc->path = escape_path_concat(loc->path, field);
	case_end;

	case_ast_node(ie, IndexExpr, lhs);
		escape_outer_location(ie->expr, loc);
		// the elements of a slice and such are in the memory it points to
		Type *bt = base_type(ie->expr->tav.type);
		bool inline_elems = escape_is_inline_array(bt) || (bt != nullptr && bt->kind == Type_Struct && bt->Struct.soa_kind == StructSoa_Fixed);
		if (!inline_elems) {
			loc->path = escape_path_concat(loc->path, escape_path_of(EscapeStep_Deref));
		}
		loc->path = escape_path_concat(loc->path, escape_path_of(EscapeStep_AnyElement));
	case_end;

	case_ast_node(de, DerefExpr, lhs);
		escape_outer_location(de->expr, loc);
		loc->path = escape_path_concat(loc->path, escape_path_of(EscapeStep_Deref));
	case_end;
	}
}

gb_internal bool escape_plain_store_writes(Ast *lhs) {
	lhs = unparen_expr(lhs);
	switch (lhs->kind) {
	case Ast_DerefExpr:
		return true;
	case Ast_SelectorExpr:
		// a plain value stored into a raw union still overwrites its pointers
		return is_type_raw_union(type_deref(lhs->SelectorExpr.expr->tav.type));
	case Ast_IndexExpr: {
		Type *bt = base_type(lhs->IndexExpr.expr->tav.type);
		return bt != nullptr && (bt->kind == Type_MultiPointer || bt->kind == Type_Pointer || bt->kind == Type_Slice);
	}
	}
	return false;
}

gb_internal void escape_store(EscapeAnalysis *ea, Ast *lhs, EscapeValue const &v) {
	lhs = unparen_expr(lhs);
	if (lhs == nullptr || is_blank_ident(lhs)) {
		return;
	}
	if (lhs->kind == Ast_Ident) {
		Entity *e = entity_of_node(lhs);
		if (escape_is_local(e) && !escape_is_using_field(e) && !escape_is_reference(e)) {
			escape_store_obj(ea, {e}, {}, v, EscapeUpdate_Replace);
			return;
		}
	}

	// it is taken to replace what each place it may store to held
	escape_store_through(ea, lhs, escape_addr(ea, lhs), v, EscapeUpdate_Replace);
}

// whether a store to the location replaces an earlier one: one within where it stores, not in memory reached through
// a pointer in there
gb_internal bool escape_outer_replaces(EscapeLocation const &loc, EscapeOuterStore const &s) {
	EscapePath const &path = loc.path;
	EscapePath const &held = s.location.path;
	if (loc.root == nullptr || s.location.root != loc.root) {
		return false;
	}
	if (path.count <= held.count) {
		EscapePath rest = slice(held, path.count, held.count);
		return escape_path_has_prefix(held, path) && escape_path_deref_index(rest) == rest.count;
	}
	// what is stored has no dereference within it
	return escape_path_has_prefix(path, held) && escape_path_has_prefix(s.value_path, slice(path, held.count, path.count));
}

gb_internal bool escape_dest_location(EscapeOrigin const &o, EscapeLocation *loc) {
	if (o.kind != EscapeOrigin_Param && (o.kind != EscapeOrigin_Outer || o.obj.entity == nullptr)) {
		return false;
	}
	*loc = {o.obj.entity, o.path};
	// as `escape_outer_location` names it, e.g. `p^` for `p: ^T`
	if (o.kind == EscapeOrigin_Param && escape_path_deref_index(o.path) == o.path.count) {
		loc->path = escape_path_concat(o.path, escape_path_of(EscapeStep_Deref));
	}
	return true;
}

gb_internal void escape_overwrite(EscapeAnalysis *ea, EscapeLocation const &loc, EscapeOrigin const *dest) {
	for (isize i = ea->state.outers.count-1; i >= 0; i--) {
		if (escape_outer_replaces(loc, ea->state.outers[i])) {
			escape_add_unique(&ea->state.cleared, ea->state.outers[i]);
			array_unordered_remove(&ea->state.outers, i);
		}
	}

	EscapeFlow flow = {EscapeFlow_Write, -1};
	Type *written = nullptr;
	if (dest != nullptr && dest->kind == EscapeOrigin_Param) {
		flow.target      = EscapeFlowTarget_Pointee;
		flow.target_path = dest->path;
		written = escape_pointee_type_at(dest->obj.entity->type, dest->path);
		if (!escape_param_index(ea->pt, dest->obj.entity, &flow.target_index)) {
			return;
		}
	} else if (loc.root != nullptr && !escape_is_local(loc.root)) {
		flow.target      = EscapeFlowTarget_Outer;
		flow.global      = loc.root;
		flow.target_path = loc.path;
		if (escape_path_deref_index(loc.path) == loc.path.count) {
			written = escape_type_within(loc.root->type, loc.path);
		}
	} else {
		return;
	}
	// e.g. bytes written into a `[]byte`: there is no pointer to clear
	if (written != nullptr && !escape_type_has_pointers(written)) {
		return;
	}
	escape_add_flow(ea, flow);
}

// `node` is the left hand side, or a call storing into memory it was given
gb_internal void escape_store_through(EscapeAnalysis *ea, Ast *node, EscapeValue const &ptr, EscapeValue const &v, EscapeUpdateKind update) {
	EscapeLocation location = {};
	escape_outer_location(node, &location);
	if (update == EscapeUpdate_Replace) {
		escape_overwrite(ea, location, nullptr);
		for (EscapeValueFact const &f : ptr) {
			EscapeLocation dest = {};
			if (escape_dest_location(f.origin, &dest)) {
				escape_overwrite(ea, dest, &f.origin);
			}
		}
	}

	for (EscapeValueFact const &f : ptr) {
		EscapeOrigin const &o = f.origin;
		switch (o.kind) {
		case EscapeOrigin_Local:
		case EscapeOrigin_Temp:
		case EscapeOrigin_Owned:
			escape_store_obj(ea, o.obj, o.path, v, update);
			break;

		case EscapeOrigin_Outer:
		case EscapeOrigin_Param:
		case EscapeOrigin_ParamLoad:
		case EscapeOrigin_ParamDeep: {
			EscapeOuterStore s = {};
			s.dest     = o;
			s.location = location;
			escape_dest_location(o, &s.location);

			for (EscapeValueFact const &vf : v) {
				s.node       = node;
				s.origin     = vf.origin;
				s.value_path = vf.path;
				switch (vf.origin.kind) {
				case EscapeOrigin_Outer:
					continue;
				case EscapeOrigin_Param:
				case EscapeOrigin_ParamLoad:
				case EscapeOrigin_ParamDeep:
					// never reported, only made into a flow meaning where it is stored does not need telling apart
					s.node = nullptr;
					break;
				}
				for (isize i = ea->state.cleared.count-1; i >= 0; i--) {
					if (escape_eq(ea->state.cleared[i], s)) {
						array_unordered_remove(&ea->state.cleared, i);
					}
				}
				escape_add_unique(&ea->state.outers, s);
			}
			break;
		}
		}
	}
}


gb_internal isize escape_push_target(EscapeAnalysis *ea, Ast *stmt, EscapeTargetKind kind) {
	EscapeTarget t = {};
	t.kind        = kind;
	t.stmt        = stmt;
	t.defer_depth = ea->defers.count;
	t.breaks      = escape_state_unreachable();
	t.continues   = escape_state_unreachable();
	array_add(&ea->targets, t);
	return ea->targets.count-1;
}

gb_internal void escape_branch(EscapeAnalysis *ea, Ast *label, TokenKind kind) {
	Ast *labelled = nullptr;
	if (label != nullptr) {
		Entity *e = entity_of_node(label);
		if (e == nullptr || e->kind != Entity_Label) {
			ea->state.reachable = false;
			return;
		}
		labelled = e->Label.parent;
	}

	for (isize i = ea->targets.count-1; i >= 0; i--) {
		EscapeTarget const &target = ea->targets[i];
		if (labelled != nullptr) {
			if (target.stmt != labelled) {
				continue;
			}
		} else if (kind == Token_continue) {
			if (target.kind != EscapeTarget_Loop) {
				continue;
			}
		} else if (target.kind != EscapeTarget_Loop && target.kind != EscapeTarget_Switch) {
			continue;
		}

		escape_run_defers(ea, target.defer_depth);
		// the defers may have added targets, which can move them
		if (kind == Token_continue) {
			escape_state_join(&ea->targets[i].continues, ea->state);
		} else {
			escape_state_join(&ea->targets[i].breaks, ea->state);
		}
		break;
	}

	ea->state.reachable = false;
}

gb_internal void escape_block(EscapeAnalysis *ea, Slice<Ast *> const &stmts) {
	array_add(&ea->defers, array_make<Ast *>(temporary_allocator(), 0, 0));
	for (Ast *stmt : stmts) {
		if (!ea->state.reachable) {
			break;
		}
		escape_stmt(ea, stmt);
	}

	if (ea->state.reachable) {
		escape_run_defers(ea, ea->defers.count-1);
	}
	array_pop(&ea->defers);

	for (Ast *stmt : stmts) {
		escape_forget(ea, stmt);
	}
}


// a value of a range statement taken by reference, e.g. `&x` of `for &x in xs`
gb_internal bool escape_is_by_ref(Ast *val) {
	return val != nullptr && val->kind == Ast_UnaryExpr && val->UnaryExpr.op.kind == Token_And;
}

gb_internal void escape_loop(EscapeAnalysis *ea, Ast *stmt, Ast *cond, Ast *post, Ast *body, Ast *val0, Ast *val1, Ast *range, Ast *each) {
	isize target_index = escape_push_target(ea, stmt, EscapeTarget_Loop);
	isize alias_count  = ea->aliases.count;

	// the length a range statement over a local slice or string takes as it begins
	if (range != nullptr) {
		for (isize i = ea->state.limits.count-1; i >= 0; i--) {
			if (ea->state.limits[i].a.stmt == stmt || ea->state.limits[i].b.stmt == stmt) {
				array_unordered_remove(&ea->state.limits, i);
			}
		}
		Ast *x = unparen_expr(range);
		Type *t = base_type(x->tav.type);

		bool sized = t != nullptr && (t->kind == Type_Slice || escape_is_sized_string(t));

		EscapeLinear end = {};
		EscapeLinear len = {};

		if (sized && escape_bounds_atom(ea, EscapeAtom_Len, x, &len.atom)) {
			end.atom = EscapeAtom{EscapeAtom_End, nullptr, stmt};
			escape_limit_add(&ea->state.limits, end, len, 0);
			escape_limit_add(&ea->state.limits, len, end, 0);
		}
	}

	EscapeState head = escape_state_clone(ea->state);
	EscapeState exit = escape_state_unreachable();

	enum : isize { MAX_ITERATION_COUNT = 16 };

	// what is nil, or passed, only shrinks to what holds for every iteration meaning only the uses of the last round are kept
	isize use_count = ea->uses.count;
	bool settled = false;
	for (isize iteration = 0; iteration < MAX_ITERATION_COUNT; iteration++) {
		ea->uses.count = use_count;

		ea->state = escape_state_clone(head);

		escape_scan(ea, cond, EscapeScan_Stmt);
		escape_scan(ea, each, EscapeScan_Bounds|EscapeScan_Fact);
		escape_bounds_flush(ea);
		escape_visit_exits(ea, cond);

		bool forever = cond != nullptr && cond->tav.mode == Addressing_Constant &&
		               cond->tav.value().kind == ExactValue_Bool && cond->tav.value().value_bool;
		if ((cond != nullptr || range != nullptr) && !forever) {
			// what the condition being false tells where the loop leaves
			auto nils   = array_clone(temporary_allocator(), ea->state.nils);
			auto limits = array_clone(temporary_allocator(), ea->state.limits);
			escape_nil_refine(ea, cond, false);
			escape_limits_refine(ea, &ea->state.limits, cond, false);
			escape_state_join(&exit, ea->state);
			ea->state.nils   = nils;
			ea->state.limits = limits;
		}
		escape_nil_refine(ea, cond, true);
		escape_limits_refine(ea, &ea->state.limits, cond, true);

		if (range != nullptr) {
			Ast *x = unparen_expr(range);
			Type *t = base_type(x->tav.type);
			Type *container = base_type(type_deref(t));
			TypeKind container_kind = container != nullptr ? container->kind : Type_Invalid;

			switch (container_kind) {
			case Type_Array:
			case Type_EnumeratedArray:
			case Type_FixedCapacityDynamicArray:
			case Type_Slice:
			case Type_DynamicArray:
			case Type_Map: {
				EscapeValue ptr = escape_elems_of(ea, x);
				EscapeValue v = escape_load(ea, ptr, nullptr);
				if (t->kind != Type_Pointer && t->kind != Type_Slice) {
					// the container may not be addressable, e.g. the result of a call
					escape_value_merge(&v, escape_value_project(escape_expr(ea, x), escape_path_of(EscapeStep_AnyElement)));
				}

				Ast *name = val0;
				if (container_kind == Type_Map) {
					name = val1;
				}
				bool by_ref = escape_is_by_ref(name);
				if (by_ref) {
					name = name->UnaryExpr.expr;
				}

				Entity *e = nullptr;
				if (name != nullptr) {
					e = entity_of_node(name);
				}
				if (e == nullptr) {
					break;
				}

				if (by_ref) {
					for (EscapeValueFact const &f : ptr) {
						array_add(&ea->aliases, EscapeAlias{e, f.origin});
					}
				} else {
					escape_store_obj(ea, {e}, {}, v, EscapeUpdate_Replace);
				}
				break;
			}
			default:
				escape_visit_exits(ea, x);
				break;
			}
			escape_limits_range(ea, stmt, range, val0, val1);
		}

		escape_stmt(ea, body);
		escape_state_join(&ea->state, ea->targets[target_index].continues);
		if (ea->state.reachable && post != nullptr) {
			escape_stmt(ea, post);
		}

		ea->aliases.count = alias_count;

		Ast *vals[2] = {val0, val1};
		for (Ast *val : vals) {
			if (escape_is_by_ref(val)) {
				val = val->UnaryExpr.expr;
			}
			if (val != nullptr && val->kind == Ast_Ident) {
				escape_forget_entity(ea, entity_of_node(val));
			}
		}
		// a limit which became weaker is let go, so the loop settles
		bool widened = false;
		if (ea->state.reachable) {
			for (isize i = head.limits.count-1; i >= 0; i--) {
				EscapeLimit const &l = head.limits[i];
				bool kept = false;
				for (EscapeLimit const &m : ea->state.limits) {
					kept |= escape_eq(l.a, m.a) && escape_eq(l.b, m.b) && m.k <= l.k;
				}
				if (!kept) {
					array_unordered_remove(&head.limits, i);
					widened = true;
				}
			}
		}
		if (!escape_state_join(&head, ea->state) && !widened) {
			settled = true;
			break;
		}
	}
	escape_state_join(&exit, ea->targets[target_index].breaks);
	if (!settled) {
		ea->uses.count = use_count;
		array_clear(&exit.nils);
		// what passed in its later iterations may have reached labelled targets and exits meaning no check is left out
		ea->bounds = false;
	}
	array_pop(&ea->targets);
	ea->state = exit;
}

gb_internal void escape_switch(EscapeAnalysis *ea, Ast *stmt, Ast *body, Ast *type_switch_rhs, bool exhaustive) {
	if (body == nullptr || body->kind != Ast_BlockStmt) {
		return;
	}

	isize target_index = escape_push_target(ea, stmt, EscapeTarget_Switch);

	EscapeValue tag     = escape_value();
	EscapeValue tag_ptr = escape_value();
	bool tag_by_ptr = false;
	if (type_switch_rhs != nullptr) {
		Type *t = type_switch_rhs->tav.type;

		tag_by_ptr = is_type_any(t) || is_type_pointer(t);
		tag        = escape_expr(ea, type_switch_rhs);
		tag_ptr    = escape_variant_addr(ea, type_switch_rhs);
	}

	EscapeState entry = escape_state_clone(ea->state);
	EscapeState exit  = escape_state_unreachable();

	bool has_default = false;
	ea->fallthrough = escape_state_unreachable();

	ast_node(bs, BlockStmt, body);
	for (Ast *clause : bs->stmts) {
		if (clause->kind != Ast_CaseClause) {
			continue;
		}
		ast_node(cc, CaseClause, clause);
		if (cc->list.count == 0) {
			has_default = true;
		}
		ea->state = escape_state_clone(entry);
		escape_state_join(&ea->state, ea->fallthrough);
		ea->fallthrough = escape_state_unreachable();
		// only those up to the one matching are evaluated
		for (Ast *e : cc->list) {
			escape_scan(ea, e, EscapeScan_Nil|EscapeScan_Bounds);
		}
		escape_bounds_flush(ea);
		for (Ast *e : cc->list) {
			escape_visit_exits(ea, e);
		}
		isize alias_count = ea->aliases.count;
		if (cc->implicit_entity != nullptr) {
			Entity *e = cc->implicit_entity;
			if (e->flags & EntityFlag_Value) {
				EscapeValue v = tag_by_ptr ? escape_load(ea, tag_ptr, e->type) : escape_as_pointer(tag);
				escape_store_obj(ea, {e}, {}, v, EscapeUpdate_Replace);
			} else {
				for (EscapeValueFact const &f : tag_ptr) {
					array_add(&ea->aliases, EscapeAlias{e, f.origin});
				}
				escape_nil_escape(ea, type_switch_rhs);
			}
		}
		escape_block(ea, cc->stmts);
		ea->aliases.count = alias_count;
		escape_forget_entity(ea, cc->implicit_entity);
		escape_state_join(&exit, ea->state);
	}
	if (!has_default && !exhaustive) {
		escape_state_join(&exit, entry);
	}
	escape_state_join(&exit, ea->targets[target_index].breaks);
	if (!has_default && exhaustive) {
		// a value no case names, e.g. `Side(99)`, or a nil union, matches none meaning what passed must have before it
		if (!exit.reachable) {
			// nor is what runs after it then analysed
			ea->bounds = false;
		}
		for (isize i = exit.checks.count-1; i >= 0; i--) {
			if (!escape_bounds_passed(entry.checks, exit.checks[i])) {
				array_unordered_remove(&exit.checks, i);
			}
		}
		escape_limits_join(&exit.limits, entry.limits);
	}
	array_pop(&ea->targets);
	ea->state = exit;
}

// an expression a statement evaluates without keeping its value, e.g. the condition of an if statement
gb_internal void escape_stmt_expr(EscapeAnalysis *ea, Ast *expr) {
	escape_scan(ea, expr, EscapeScan_Stmt);
	escape_bounds_flush(ea);
	escape_visit_exits(ea, expr);
}

// the values of the call of several results a list is, e.g. `x, ok := f()`, else nothing for each after visiting it
gb_internal Array<EscapeValue> escape_call_results(EscapeAnalysis *ea, Slice<Ast *> const &exprs, isize count) {
	Ast *call = nullptr;
	if (exprs.count == 1) {
		call = escape_call_of(exprs[0]);
	}
	Array<EscapeValue> results = {};
	if (call != nullptr) {
		results = escape_call(ea, call);
	} else {
		for (Ast *expr : exprs) {
			escape_visit_exits(ea, expr);
		}
	}

	auto values = array_make<EscapeValue>(temporary_allocator(), count);
	for (isize i = 0; i < count; i++) {
		values[i] = escape_value();
		if (i < results.count) {
			values[i] = results[i];
		}
	}
	return values;
}

// what a range statement goes over, whose address it takes for a value by reference
gb_internal void escape_scan_range(EscapeAnalysis *ea, Ast *expr, bool by_ref, u8 flags) {
	if (by_ref && escape_nil_root(expr) != nullptr) {
		escape_nil_escape(ea, expr);
		flags |= EscapeScan_Addr;
	}
	escape_scan(ea, expr, flags);
}

gb_internal void escape_stmt(EscapeAnalysis *ea, Ast *node) {
	if (node == nullptr || !ea->state.reachable) {
		return;
	}
	ea->stmt_visits += 1;
	if (escape_too_large(ea)) {
		return;
	}

	// as the backend meaning a defer has those of where it runs
	bool bounds_off = ea->bounds_off;
	defer (ea->bounds_off = bounds_off);
	if (node->state_flags & StateFlag_bounds_check) {
		ea->bounds_off = false;
	} else if (node->state_flags & StateFlag_no_bounds_check) {
		ea->bounds_off = true;
	}

	switch (node->kind) {
	case_ast_node(es, ExprStmt, node);
		escape_stmt_expr(ea, es->expr);
		if (is_diverging_stmt(node)) {
			ea->state.reachable = false;
		}

		// where it carries on, a condition it leaves or stops at unless true, e.g. `ok or_return` or `assert(ok)`
		Ast *expr  = unparen_expr(es->expr);
		Ast *guard = nullptr;
		switch (expr->kind) {
		case Ast_OrReturnExpr:
			guard = expr->OrReturnExpr.expr;
			break;
		case Ast_OrBranchExpr:
			guard = expr->OrBranchExpr.expr;
			break;
		case Ast_CallExpr: {
			Entity *e = entity_of_node(unparen_expr(expr->CallExpr.proc));
			if (e != nullptr && e->kind == Entity_Procedure && (e->flags & EntityFlag_Disabled) == 0 &&
			    e->pkg != nullptr && e->pkg->kind == Package_Runtime && expr->CallExpr.args.count > 0) {
				String name = e->token.string;
				if (name == "assert" || name == "ensure" || name == "assert_contextless" || name == "ensure_contextless") {
					guard = expr->CallExpr.args[0];
				}
			}
			break;
		}
		}
		if (guard != nullptr && is_type_boolean(guard->tav.type)) {
			escape_limits_refine(ea, &ea->state.limits, guard, true);
		}
	case_end;

	case_ast_node(vd, ValueDecl, node);
		if (!vd->is_mutable) {
			break;
		}
		for (Ast *value : vd->values) {
			escape_scan(ea, value, EscapeScan_Stmt);
		}
		escape_bounds_flush(ea);
		for (Ast *name : vd->names) {
			escape_bounds_forget(ea, entity_of_node(name));
		}
		auto nil_paths = array_make<Array<EscapePath> >(temporary_allocator(), 0, 0);
		if (vd->values.count == vd->names.count) {
			for_array(i, vd->names) {
				escape_limits_assign(ea, entity_of_node(vd->names[i]), vd->values[i]);
				if (ea->nil_deref) {
					array_add(&nil_paths, escape_nil_paths(ea, vd->values[i]));
				}
			}
		}

		if (vd->values.count == vd->names.count) {
			for_array(i, vd->names) {
				Entity *e = entity_of_node(vd->names[i]);
				if (!escape_is_local(e) || escape_type_is_plain(e->type)) {
					escape_visit_exits(ea, vd->values[i]);
					continue;
				}
				EscapeValue v = escape_expr(ea, vd->values[i]);
				escape_store_obj(ea, {e}, {}, escape_convert(ea, v, vd->values[i], e->type), EscapeUpdate_Replace);
			}
		} else {
			Array<EscapeValue> results = escape_call_results(ea, vd->values, vd->names.count);
			for_array(i, vd->names) {
				Entity *e = entity_of_node(vd->names[i]);
				if (escape_is_local(e)) {
					escape_store_obj(ea, {e}, {}, results[i], EscapeUpdate_Replace);
				}
			}
		}

		if (ea->nil_deref || ea->uninit) {
			for_array(i, vd->names) {
				Entity *e = entity_of_node(vd->names[i]);
				if (!escape_is_local(e)) {
					continue;
				}
				escape_nil_forget(ea, e);
				if (ea->nil_deref && vd->values.count == 0 && escape_type_has_nilable(e->type)) {
					escape_nil_add(ea, e, {}, false);
				}
				if (i < nil_paths.count) {
					for (EscapePath const &p : nil_paths[i]) {
						escape_nil_add(ea, e, p, false);
					}
				}
				if (ea->uninit && i < vd->values.count && unparen_expr(vd->values[i])->kind == Ast_Uninit) {
					escape_add_unique(&ea->uninit_decls, e);
					escape_nil_add(ea, e, {}, true);
				}
			}
		}
	case_end;

	case_ast_node(as, AssignStmt, node);
		for (Ast *rhs : as->rhs) {
			escape_scan(ea, rhs, EscapeScan_Stmt);
		}
		for (Ast *lhs : as->lhs) {
			// a store into a local does not read it, unless the operator does
			u8 flags = EscapeScan_Stmt;
			if (as->op.kind == Token_Eq && escape_nil_root(lhs) != nullptr) {
				flags |= EscapeScan_Addr;
			}
			escape_scan(ea, lhs, flags);
		}
		escape_bounds_flush(ea);
		{
			// a local integer set to itself plus a constant keeps what is known of it, moved by that
			Entity *set   = nullptr;
			bool    shift = false;
			i64     by    = 0;
			Ast *target = unparen_expr(as->lhs[0]);
			if (as->lhs.count == 1 && as->rhs.count == 1 && target->kind == Ast_Ident) {
				set = entity_of_node(target);
				EscapeLinear v = {};
				EscapeIntRange r = {};
				if (escape_bounds_entity(ea, set) && escape_int_range(set->type, &r) &&
				    escape_bounds_linear(ea, ea->state.limits, as->rhs[0], &v)) {
					EscapeAtom self = {EscapeAtom_Local, set};
					switch (as->op.kind) {
					case Token_Eq:
						shift = escape_eq(v.atom, self);
						by    = v.c;
						break;
					case Token_AddEq:
					case Token_SubEq:
						by    = as->op.kind == Token_SubEq ? -v.c : v.c;
						shift = v.atom.kind == EscapeAtom_Zero && escape_limits_fit(ea->state.limits, self, by, r);
						break;
					}
				}
			}
			for (Ast *lhs : as->lhs) {
				escape_bounds_forget(ea, escape_nil_root(lhs), shift);
			}
			if (shift) {
				escape_limits_shift(&ea->state.limits, set, by);
			} else if (as->op.kind == Token_Eq && set != nullptr) {
				escape_limits_assign(ea, set, as->rhs[0]);
			}
		}

		if (as->op.kind != Token_Eq) {
			// one target, given no pointers
			escape_nil_store(ea, as->lhs[0], nullptr);
			escape_visit_exits(ea, as->lhs[0]);
			escape_visit_exits(ea, as->rhs[0]);
			break;
		}
		auto nil_paths = array_make<Array<EscapePath> >(temporary_allocator(), 0, 0);
		if (ea->nil_deref && as->lhs.count == as->rhs.count) {
			for (Ast *rhs : as->rhs) {
				array_add(&nil_paths, escape_nil_paths(ea, rhs));
			}
		}
		if (as->lhs.count == as->rhs.count) {
			// every value is evaluated before any is stored, as in `a, b = b, a`
			auto values = array_make<EscapeValue>(temporary_allocator(), as->rhs.count);
			auto stored = array_make<bool>(temporary_allocator(), as->lhs.count);
			for_array(i, as->rhs) {
				Ast *lhs = unparen_expr(as->lhs[i]);
				stored[i] = !escape_type_is_plain(lhs->tav.type) || escape_plain_store_writes(lhs);
				if (stored[i]) {
					values[i] = escape_convert(ea, escape_expr(ea, as->rhs[i]), as->rhs[i], lhs->tav.type);
				} else {
					escape_visit_exits(ea, as->rhs[i]);
				}
			}
			for_array(i, as->lhs) {
				if (stored[i]) {
					escape_store(ea, as->lhs[i], values[i]);
				} else {
					escape_visit_exits(ea, as->lhs[i]);
				}
			}
		} else {
			Array<EscapeValue> results = escape_call_results(ea, as->rhs, as->lhs.count);
			for_array(i, as->lhs) {
				escape_store(ea, as->lhs[i], results[i]);
			}
		}

		for_array(i, as->lhs) {
			Array<EscapePath> const *paths = nullptr;
			if (i < nil_paths.count) {
				paths = &nil_paths[i];
			}
			escape_nil_store(ea, as->lhs[i], paths);
		}
	case_end;

	case_ast_node(bs, BlockStmt, node);
		if (bs->label != nullptr) {
			isize target_index = escape_push_target(ea, node, EscapeTarget_Labelled);
			escape_block(ea, bs->stmts);
			escape_state_join(&ea->state, ea->targets[target_index].breaks);
			array_pop(&ea->targets);
		} else {
			escape_block(ea, bs->stmts);
		}
	case_end;

	case_ast_node(is, IfStmt, node);
		isize target_index = -1;
		if (is->label != nullptr) {
			target_index = escape_push_target(ea, node, EscapeTarget_Labelled);
		}

		escape_stmt(ea, is->init);
		escape_stmt_expr(ea, is->cond);

		EscapeState other = escape_state_clone(ea->state);
		escape_nil_refine(ea, is->cond, true, true);
		escape_limits_refine(ea, &ea->state.limits, is->cond, true);
		escape_stmt(ea, is->body);

		EscapeState then = ea->state;
		ea->state = other;
		escape_nil_refine(ea, is->cond, false, true);
		escape_limits_refine(ea, &ea->state.limits, is->cond, false);
		escape_stmt(ea, is->else_stmt);

		escape_state_join(&ea->state, then);

		if (target_index >= 0) {
			escape_state_join(&ea->state, ea->targets[target_index].breaks);
			array_pop(&ea->targets);
		}

		escape_forget(ea, is->init);
	case_end;

	case_ast_node(ws, WhenStmt, node);
		if (!ws->is_cond_determined) {
			break;
		}
		if (ws->determined_cond) {
			escape_stmt(ea, ws->body);
		} else {
			escape_stmt(ea, ws->else_stmt);
		}
	case_end;

	case_ast_node(rs, ReturnStmt, node);
		for (Ast *expr : rs->results) {
			escape_scan(ea, expr, EscapeScan_Stmt);
		}
		escape_bounds_flush(ea);
		isize result_count = ea->pt->result_count;
		auto values = array_make<EscapeValue>(temporary_allocator(), 0, result_count);

		if (rs->results.count != result_count) {
			// the results of a single call, or a bare return of named results
			if (rs->results.count == 1 && escape_call_of(rs->results[0]) != nullptr) {
				escape_exit(ea, node, rs->results, escape_call_results(ea, rs->results, result_count));
			} else {
				for (Ast *expr : rs->results) {
					escape_visit_exits(ea, expr);
				}
				escape_exit(ea, node, {}, values);
			}
			break;
		}

		for_array(i, rs->results) {
			Ast *expr = rs->results[i];
			array_add(&values, escape_convert(ea, escape_expr(ea, expr), expr, ea->pt->results->Tuple.variables[i]->type));
		}

		escape_exit(ea, node, rs->results, values);
	case_end;

	case_ast_node(fs, ForStmt, node);
		escape_stmt(ea, fs->init);
		escape_loop(ea, node, fs->cond, fs->post, fs->body, nullptr, nullptr, nullptr, nullptr);
		escape_forget(ea, fs->init);
	case_end;

	case_ast_node(rs, RangeStmt, node);
		escape_stmt(ea, rs->init);
		Ast *val0 = rs->vals.count > 0 ? rs->vals[0] : nullptr;
		Ast *val1 = rs->vals.count > 1 ? rs->vals[1] : nullptr;
		bool by_ref = false;
		for (Ast *val : rs->vals) {
			by_ref |= escape_is_by_ref(val);
		}

		Ast *range = unparen_expr(rs->expr);
		Type *range_type = base_type(type_deref(range->tav.type));
		Ast *each = nullptr;
		if (is_ast_range(range)) {
			escape_scan(ea, range->BinaryExpr.left, EscapeScan_Bounds|EscapeScan_Fact);
			each = range->BinaryExpr.right;
		} else if (range->tav.mode != Addressing_Type && range_type != nullptr && range_type->kind == Type_Tuple) {
			each = range;
		} else {
			escape_scan(ea, range, EscapeScan_Bounds|EscapeScan_Fact);
		}
		escape_scan_range(ea, rs->expr, by_ref, EscapeScan_Nil);
		escape_bounds_flush(ea);
		escape_loop(ea, node, nullptr, nullptr, rs->body, val0, val1, rs->expr, each);
		escape_forget(ea, rs->init);
	case_end;

	case_ast_node(rs, UnrollRangeStmt, node);
		escape_stmt(ea, rs->init);
		escape_scan_range(ea, rs->expr, escape_is_by_ref(rs->val0) || escape_is_by_ref(rs->val1), EscapeScan_Stmt);
		escape_bounds_flush(ea);
		escape_loop(ea, node, nullptr, nullptr, rs->body, rs->val0, rs->val1, rs->expr, nullptr);
		escape_forget(ea, rs->init);
	case_end;

	case_ast_node(ss, SwitchStmt, node);
		escape_stmt(ea, ss->init);
		escape_stmt_expr(ea, ss->tag);
		bool exhaustive = false;
		if (!ss->partial && ss->tag != nullptr) {
			// a switch on an enum must handle every value
			exhaustive = is_type_enum(ss->tag->tav.type);
		}
		escape_switch(ea, node, ss->body, nullptr, exhaustive);
		escape_forget(ea, ss->init);
	case_end;

	case_ast_node(ss, TypeSwitchStmt, node);
		Ast *rhs = nullptr;
		if (ss->tag != nullptr && ss->tag->kind == Ast_AssignStmt && ss->tag->AssignStmt.rhs.count == 1) {
			rhs = ss->tag->AssignStmt.rhs[0];
		}
		if (rhs == nullptr) {
			break;
		}
		escape_scan(ea, rhs, EscapeScan_Stmt);
		escape_bounds_flush(ea);
		escape_switch(ea, node, ss->body, rhs, !ss->partial);
	case_end;

	case_ast_node(ds, DeferStmt, node);
		if (ea->defers.count > 0) {
			array_add(&ea->defers[ea->defers.count-1], ds->stmt);
		}
	case_end;

	case_ast_node(bs, BranchStmt, node);
		if (bs->token.kind == Token_fallthrough) {
			ea->fallthrough = escape_state_clone(ea->state);
			ea->state.reachable = false;
		} else {
			escape_branch(ea, bs->label, bs->token.kind);
		}
	case_end;
	}
}


gb_internal ErrorInstantiations escape_instantiations_of(ProcInfo *pi) {
	return {pi->generated_from_polymorphic ? pi : pi->poly_parent, nullptr};
}

gb_internal Slice<EscapeFlow> escape_analyse(EscapeGraph *g, i32 v, Array<EscapeReport> *reports, bool calls_unknown=false) {
	ProcInfo *pi = g->procs[v];
	Type *type = pi->type;
	Ast *body = pi->body;
	if (type == nullptr || type->kind != Type_Proc || body == nullptr || body->kind != Ast_BlockStmt) {
		return {};
	}
	TEMPORARY_ALLOCATOR_GUARD();

	EscapeAnalysis ea = {};
	ea.pt       = &type->Proc;
	ea.state    = escape_state_unreachable();
	ea.state.reachable = true;

	ea.defers   = array_make<Array<Ast *> >(temporary_allocator());
	ea.targets  = array_make<EscapeTarget>(temporary_allocator());
	ea.aliases  = array_make<EscapeAlias>(temporary_allocator());
	ea.reported = array_make<Ast *>(temporary_allocator());
	ea.uses     = array_make<EscapeUse>(temporary_allocator(), 0, 0);
	ea.flows    = array_make<EscapeFlow>(temporary_allocator(), 0, 0);
	ea.graph    = g;
	ea.group    = g->group_of[v];
	ea.reports  = reports;
	ea.calls_unknown = calls_unknown;

	Array<EscapeReport> own_reports = {};
	if (ea.reports == nullptr) {
		own_reports = array_make<EscapeReport>(temporary_allocator(), 0, 0);
		ea.reports = &own_reports;
	}
	isize report_count = ea.reports->count;

	bool enabled = ast_file_analysis(body->file(), AnalysisFlag_Escape);
	ea.muted = !enabled;

	u64 vet_flags = ast_file_vet_flags(body->file());

	ea.nil_deref    = enabled && (vet_flags & VetFlag_NilDeref) != 0;
	ea.uninit       = enabled && (vet_flags & VetFlag_Uninitialized) != 0;

	ea.nil_escaped  = array_make<Entity *>(temporary_allocator(), 0, 0);
	ea.uninit_decls = array_make<Entity *>(temporary_allocator(), 0, 0);

	ea.bounds         = !build_context.no_bounds_check;
	ea.bounds_found   = array_make<EscapeBoundsCheck>(temporary_allocator(), 0, 0);
	ea.bounds_escaped = array_make<Entity *>         (temporary_allocator(), 0, 0);
	ea.bounds_context = array_make<EscapeRefine>     (temporary_allocator(), 0, 0);

	if (ea.pt->variadic && !ea.pt->c_vararg && ea.pt->variadic_index < ea.pt->param_count) {
		ea.variadic = ea.pt->params->Tuple.variables[ea.pt->variadic_index];
	}

	if (build_context.build_mode == BuildMode_Executable &&
	    !build_context.no_entry_point &&
	    build_context.command_kind != Command_test) {
		Entity *e = pi->decl->entity.load();
		ea.muted |= e != nullptr && e == global_checker_ptr.load(std::memory_order_relaxed)->info.entry_point;
	}

	ErrorInstantiations prev_instantiations = global_error_context.instantiations;
	global_error_context.instantiations = escape_instantiations_of(pi);
	escape_stmt(&ea, body);
	if (ea.too_large && !calls_unknown) {
		global_error_context.instantiations = prev_instantiations;
		ea.reports->count = report_count;
		return escape_analyse(g, v, reports, true);
	}
	if (ea.state.reachable && !ea.too_large) {
		escape_exit(&ea, body, {}, {});
	}

	// each use over every time it is reached
	array_sort(ea.uses, escape_use_cmp);
	for (isize i = 0, j = 0; i < ea.uses.count && !ea.too_large; i = j) {
		EscapeUse const &use = ea.uses[i];
		bool holds = true;
		for (j = i; j < ea.uses.count && ea.uses[j].node == use.node && ea.uses[j].kind == use.kind; j++) {
			holds &= ea.uses[j].holds;
		}
		if (!holds) {
			continue;
		}
		if (use.kind == EscapeReport_Invalid) {
			if (ea.bounds) {
				use.node->state_flags |= StateFlag_bounds_check_proven;
			}
			continue;
		}
		gbString str = escape_expr_to_string(use.node);
		array_add(ea.reports, EscapeReport{use.kind, use.node, copy_string(permanent_allocator(), make_string_c(str))});
		gb_string_free(str);
	}

	if (reports == nullptr) {
		for (EscapeReport const &r : own_reports) {
			escape_report_emit(r);
		}
	}
	global_error_context.instantiations = prev_instantiations;

	// the callers read it once this analysis and its temporary memory are gone
	auto flows = permanent_slice_make<EscapeFlow>(ea.flows.count);
	for_array(i, ea.flows) {
		flows[i] = ea.flows[i];
		flows[i].target_path = slice_clone(permanent_allocator(), ea.flows[i].target_path);
		flows[i].param_path  = slice_clone(permanent_allocator(), ea.flows[i].param_path);
		flows[i].value_path  = slice_clone(permanent_allocator(), ea.flows[i].value_path);
	}
	return flows;
}

gb_internal WORKER_TASK_PROC(escape_member_worker) {
	EscapeMemberTask *t = cast(EscapeMemberTask *)data;
	array_clear(&t->reports);
	t->flows = escape_analyse(t->graph, t->v, &t->reports);
	return 0;
}

// each stale one is analysed with the flows the others had before meaning the order they are analysed in does not matter
gb_internal void escape_analyse_members(EscapeGraph *g, Slice<EscapeMemberTask> tasks) {
	TaskGroup group = {};
	for (EscapeMemberTask &t : tasks) {
		if (!t.stale) {
			continue;
		}
		if (g->threaded) {
			thread_pool_add_task(&group, escape_member_worker, &t);
		} else {
			escape_member_worker(&t);
		}
	}
	thread_pool_wait(&group);
}

// keeps what an analysis of a member found, and when that changed, those calling it need analysing again
gb_internal void escape_update_member(EscapeGraph *g, Slice<EscapeMemberTask> tasks, isize k) {
	EscapeMemberTask &t = tasks[k];
	DeclInfo *d = g->procs[t.v]->decl;

	// the same flows, in any order
	bool same = t.flows.count == d->proc->escape_flows.count;
	for (isize i = 0; same && i < t.flows.count; i++) {
		same = false;
		for (EscapeFlow const &other : d->proc->escape_flows) {
			same |= escape_eq(t.flows[i], other);
		}
	}
	if (same) {
		return;
	}
	d->proc->escape_flows = t.flows;
	for (i32 caller : t.callers) {
		tasks[caller].stale = true;
	}
}

gb_internal void escape_analyse_group(EscapeGraph *g, i32 gi) {
	enum : isize { ROUND_COUNT = 3 };

	i32 start = g->group_offsets[gi];
	i32 end   = g->group_offsets[gi+1];

	i32 first = g->members[start];
	if (g->skipped[first]) {
		if (!build_context.no_bounds_check) {
			// only for the bounds checks it may leave out, which do not need what its calls do
			for (i32 k = start; k < end; k++) {
				escape_analyse(g, g->members[k], nullptr, true);
			}
		}
		return;
	}
	bool recursive = end - start > 1;
	for (i32 w : escape_callees(g, first)) {
		recursive |= w == first;
	}
	if (!recursive) {
		DeclInfo *d = g->procs[first]->decl;
		d->proc->escape_flows = escape_analyse(g, first, nullptr);
		d->proc->escapes_analysed.store(true);
		return;
	}

	TEMPORARY_ALLOCATOR_GUARD();
	auto tasks = slice_make<EscapeMemberTask>(temporary_allocator(), end - start);
	for (i32 k = start; k < end; k++) {
		EscapeMemberTask &t = tasks[k - start];
		t = {g, g->members[k]};
		t.stale = true;
		// filled in by analyses on other threads, which free their own temporary memory
		array_init(&t.reports, heap_allocator(), 0, 0);
		array_init(&t.callers, temporary_allocator(), 0, 0);
	}
	for_array(k, tasks) {
		for (i32 w : escape_callees(g, tasks[k].v)) {
			for (EscapeMemberTask &t : tasks) {
				if (t.v == w) {
					array_add(&t.callers, cast(i32)k);
				}
			}
		}
	}

	for (isize round = 0; round < ROUND_COUNT; round++) {
		escape_analyse_members(g, tasks);
		for (EscapeMemberTask &t : tasks) {
			t.stale = false;
		}
		for_array(k, tasks) {
			escape_update_member(g, tasks, k);
		}
		bool settled = true;
		for (EscapeMemberTask const &t : tasks) {
			settled &= !t.stale;
		}
		if (settled) {
			break;
		}
	}

	for (EscapeMemberTask &t : tasks) {
		ProcInfo *pi = g->procs[t.v];
		ErrorInstantiations prev_instantiations = global_error_context.instantiations;
		global_error_context.instantiations = escape_instantiations_of(pi);
		for (EscapeReport const &r : t.reports) {
			escape_report_emit(r);
		}
		global_error_context.instantiations = prev_instantiations;
		array_free(&t.reports);

		pi->decl->proc->escape_flows = t.flows;
		pi->decl->proc->escapes_analysed.store(true);
	}
}

gb_internal bool escape_call_edge(CheckedCall const &call, i32 *caller, i32 *callee) {
	DeclInfo *d = call.callee->decl_info;
	if (call.caller->proc->proc_info == nullptr || d == nullptr || d->proc->proc_info == nullptr) {
		// e.g. in a body which failed to check, or to a foreign procedure
		return false;
	}
	*caller = call.caller->proc->escape_index;
	*callee = d->proc->escape_index;
	return true;
}

// each call takes the next slot of its caller; before `targets` is made, that only counts them
gb_internal void escape_graph_place_calls(CheckedCall *calls, isize count) {
	EscapeGraph *g = &escape_graph;
	for (isize i = 0; i < count; i++) {
		i32 caller = 0;
		i32 callee = 0;
		if (!escape_call_edge(calls[i], &caller, &callee)) {
			continue;
		}
		i32 slot = g->cursors[caller].fetch_add(1, std::memory_order_relaxed);
		if (g->targets.data != nullptr) {
			g->targets[slot] = callee;
		}
	}
}

gb_internal void escape_graph_number_procs(ProcInfo **procs, isize count) {
	EscapeGraph *g = &escape_graph;
	i32 first = cast(i32)(procs - g->procs.data);
	for (isize k = 0; k < count; k++) {
		procs[k]->decl->proc->escape_index = first + cast(i32)k;
	}
}

// per group, its calls to procedures of other groups, as each of those finishing releases one
gb_internal void escape_graph_count_pending(ProcInfo **procs, isize count) {
	EscapeGraph *g = &escape_graph;
	i32 first = cast(i32)(procs - g->procs.data);
	for (isize k = 0; k < count; k++) {
		i32 v = first + cast(i32)k;
		i32 gv = g->group_of[v];
		i32 calls = 0;
		for (i32 w : escape_callees(g, v)) {
			calls += g->group_of[w] != gv;
		}
		if (calls > 0) {
			g->pending[gv].fetch_add(calls, std::memory_order_relaxed);
		}
	}
}

gb_internal void escape_for_procs(EscapeGraph *g, void (*proc)(ProcInfo **procs, isize count)) {
	if (g->threaded) {
		thread_pool_for_chunks(g->procs.data, g->procs.count, 1024, proc);
	} else {
		proc(g->procs.data, g->procs.count);
	}
}

// over the calls recorded by each thread where they are
gb_internal void escape_for_calls(EscapeGraph *g, PerThreadArray<CheckedCall> *calls, void (*proc)(CheckedCall *calls, isize count)) {
	enum : isize { CHUNK_SIZE = 4096 };
	if (!g->threaded) {
		for (PerThreadArraySlot<CheckedCall> &slot : calls->slots) {
			proc(slot.array.data, slot.array.count);
		}
		return;
	}

	TEMPORARY_ALLOCATOR_GUARD();
	auto chunks = array_make<ThreadPoolChunk<CheckedCall> >(temporary_allocator(), 0, calls->slots.count);
	for (PerThreadArraySlot<CheckedCall> &slot : calls->slots) {
		for (isize i = 0; i < slot.array.count; i += CHUNK_SIZE) {
			array_add(&chunks, ThreadPoolChunk<CheckedCall>{slot.array.data + i, gb_min(CHUNK_SIZE, slot.array.count - i), proc});
		}
	}
	TaskGroup group = {};
	for (ThreadPoolChunk<CheckedCall> &chunk : chunks) {
		thread_pool_add_task(&group, thread_pool_chunk_worker_proc<CheckedCall>, &chunk);
	}
	thread_pool_wait(&group);
}

gb_internal WORKER_TASK_PROC(escape_graph_find_callers) {
	EscapeGraph *g = cast(EscapeGraph *)data;
	i32 count = cast(i32)g->procs.count;
	array_init(&g->caller_offsets, heap_allocator(), count+1);
	for (i32 callee : g->targets) {
		g->caller_offsets[callee+1] += 1;
	}
	for (i32 v = 0; v < count; v++) {
		g->caller_offsets[v+1] += g->caller_offsets[v];
	}

	TEMPORARY_ALLOCATOR_GUARD();
	auto next = array_clone(temporary_allocator(), g->caller_offsets);
	array_init(&g->callers, heap_allocator(), g->targets.count);
	for (i32 v = 0; v < count; v++) {
		for (i32 w : escape_callees(g, v)) {
			g->callers[next[w]++] = v;
		}
	}
	return 0;
}

gb_internal WORKER_TASK_PROC(escape_group_worker) {
	EscapeGraph *g = &escape_graph;
	i32 gi = cast(i32)cast(intptr)data;
	for (;;) {
		escape_analyse_group(g, gi);

		// carries on with one of the groups this releases, rather than queueing every one of them
		bool carry_on = false;
		i32 next_gi = 0;
		for (i32 k = g->group_offsets[gi]; k < g->group_offsets[gi+1]; k++) {
			for (i32 caller : escape_callers(g, g->members[k])) {
				i32 next = g->group_of[caller];
				if (next == gi || g->pending[next].fetch_sub(1) != 1) {
					continue;
				}
				if (carry_on) {
					thread_pool_add_task(escape_group_worker, cast(void *)cast(intptr)next);
				} else {
					carry_on = true;
					next_gi = next;
				}
			}
		}
		if (!carry_on) {
			return 0;
		}
		gi = next_gi;
	}
}

// once every body is checked, as a call needs to know what its procedure does
gb_internal void check_escapes(Checker *c) {
	TEMPORARY_ALLOCATOR_GUARD();

	EscapeGraph *g = &escape_graph;
	defer ({
		array_free(&g->procs);
		array_free(&g->offsets);
		array_free(&g->targets);
		array_free(&g->caller_offsets);
		array_free(&g->callers);
		array_free(&g->group_of);
		array_free(&g->group_offsets);
		array_free(&g->members);
		array_free(&g->skipped);
		slice_free(&g->pending, heap_allocator());
		slice_free(&g->cursors, heap_allocator());
		*g = {};
	});
	array_init(&g->procs, heap_allocator());
	per_thread_array_gather(&c->info.checked_bodies_queue, &g->procs);
	i32 count = cast(i32)g->procs.count;
	if (count == 0) {
		return;
	}
	g->threaded = !build_context.no_threaded_checker && build_context.thread_count > 1;
	escape_for_procs(g, escape_graph_number_procs);

	// the calls of each procedure are counted, and then placed after those of the procedures before it
	g->cursors = slice_make<std::atomic<i32> >(heap_allocator(), count);
	escape_for_calls(g, &c->info.checked_calls_queue, escape_graph_place_calls);

	array_init(&g->offsets, heap_allocator(), count+1);

	for (i32 v = 0; v < count; v++) {
		g->offsets[v+1] = g->offsets[v] + g->cursors[v].load(std::memory_order_relaxed);
		g->cursors[v].store(g->offsets[v], std::memory_order_relaxed);
	}

	array_init(&g->targets, heap_allocator(), g->offsets[count]);

	escape_for_calls(g, &c->info.checked_calls_queue, escape_graph_place_calls);

	for (PerThreadArraySlot<CheckedCall> &slot : c->info.checked_calls_queue.slots) {
		array_clear(&slot.array);
	}

	// when it is disabled but for some files, only their procedures and what those may call are analysed
	array_init(&g->skipped, heap_allocator(), count);
	if ((build_context.no_analysis_flags & AnalysisFlag_Escape) != 0) {
		auto stack = array_make<i32>(temporary_allocator(), 0, count);
		for (i32 v = 0; v < count; v++) {
			Ast *body = g->procs[v]->body;
			g->skipped[v] = body == nullptr || !ast_file_analysis(body->file(), AnalysisFlag_Escape);
			if (!g->skipped[v]) {
				array_add(&stack, v);
			}
		}
		while (stack.count > 0) {
			i32 v = array_pop(&stack);
			for (i32 w : escape_callees(g, v)) {
				if (g->skipped[w]) {
					g->skipped[w] = false;
					array_add(&stack, w);
				}
			}
		}
	}

	// only needed to release the groups when threaded, and found meanwhile
	TaskGroup callers = {};
	if (g->threaded) {
		thread_pool_add_task(&callers, escape_graph_find_callers, g);
	}

	array_init(&g->group_of, heap_allocator(), count);
	i32 group_count = global_graph_scc(count, g->offsets, g->targets, &g->group_of);
	{
		auto procs = array_make<i32>(temporary_allocator(), count);
		for (i32 v = 0; v < count; v++) {
			procs[v] = v;
		}
		global_graph_csr(group_count, g->group_of, procs, &g->group_offsets, &g->members);
	}

	if (!g->threaded) {
		for (i32 gi = 0; gi < group_count; gi++) {
			escape_analyse_group(g, gi);
		}
		return;
	}

	thread_pool_wait(&callers);
	g->pending = slice_make<std::atomic<i32> >(heap_allocator(), group_count);
	escape_for_procs(g, escape_graph_count_pending);

	// all found before any is analysed, as analysing one releases others
	auto ready = array_make<i32>(temporary_allocator(), 0, group_count);
	for (i32 gi = 0; gi < group_count; gi++) {
		if (g->pending[gi].load() == 0) {
			array_add(&ready, gi);
		}
	}
	for (i32 gi : ready) {
		thread_pool_add_task(escape_group_worker, cast(void *)cast(intptr)gi);
	}
	thread_pool_wait();
}
