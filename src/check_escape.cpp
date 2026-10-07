// Whatever is unknown, e.g. the result of a call through a procedure value, is assumed to not point into the stack frame
// An explicit conversion to 'rawptr' or 'uintptr', or a 'transmute', opts out
// A call uses a summary of what of its arguments may reach its results, analysing the callee first if it must

enum EscapeStepKind : u8 {
	EscapeStep_Invalid,
	EscapeStep_Field,
	EscapeStep_AnyElement,
	EscapeStep_Deref, // only in the location of an outer store
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
	EscapeOrigin_Outer,
	EscapeOrigin_Local,
	EscapeOrigin_Temp,
	EscapeOrigin_Owned,     // the buffer of a local dynamic array or map, tracked as its contents
	EscapeOrigin_Variadic,
	EscapeOrigin_Param,     // what the pointers a parameter holds at its path point to, which is the caller's
	EscapeOrigin_ParamLoad, // what the pointers loaded once through them point to
	EscapeOrigin_ParamDeep, // what is reached by loading through them more than once
};

// where the buffer of a dynamic array or map is loaded through it
enum EscapeFlowKind : u8 {
	EscapeFlow_Invalid,
	EscapeFlow_Value, // the pointers of the argument, or offsets of them
	EscapeFlow_Load,  // the pointers loaded once through them
	EscapeFlow_Deep,  // the pointers loaded more than once through them
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
};

struct EscapeOrigin {
	EscapeOriginKind kind;
	EscapeObject     obj;
	EscapePath       path;
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

struct EscapeOuterStore {
	Entity *     root;
	EscapePath   path;
	bool         exact;
	Ast *        node;   // the left hand side, or a call storing into memory it was given, unless what is stored is the caller's
	EscapeOrigin dest;   // what it is stored through
	EscapeOrigin origin; // of what is stored
};

struct EscapeState {
	bool                    reachable;
	Array<EscapeFact>       facts;
	Array<EscapeOuterStore> outers;
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
};

struct EscapeReport {
	EscapeReportKind kind;
	Ast *            node;
	String           expr_str;
	EscapeOrigin     origin;
};

struct EscapeAlias {
	Entity *     e;
	EscapeOrigin origin;
};

struct EscapeAnalysis {
	TypeProc *           pt;
	Entity *             variadic;
	EscapeState          state;
	EscapeState          fallthrough;
	Array<Array<Ast *> > defers;
	Array<EscapeTarget>  targets;
	Array<EscapeAlias>   aliases;
	Array<Ast *>         reported;
	Array<EscapeFlow>    flows;
	struct EscapeGraph * graph;
	i32                  group;   // of the procedures being analysed together, see `EscapeGraph`
	Array<EscapeReport> *reports; // kept rather than reported, while what flows through the group may still change
	bool                 muted;   // the entry point of an executable, which only returns as the program ends
};


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

gb_internal bool escape_path_has(EscapePath const &p, EscapeStepKind kind) {
	for (EscapeStep const &step : p) {
		if (step.kind == kind) {
			return true;
		}
	}
	return false;
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

gb_internal bool escape_object_eq(EscapeObject const &a, EscapeObject const &b) {
	return a.entity == b.entity &&
	       a.temp   == b.temp;
}

gb_internal bool escape_origin_eq(EscapeOrigin const &a, EscapeOrigin const &b) {
	return a.kind == b.kind               &&
	       escape_object_eq(a.obj, b.obj) &&
	       escape_path_eq(a.path, b.path);
}

gb_internal bool escape_outer_eq(EscapeOuterStore const &a, EscapeOuterStore const &b) {
	return a.root == b.root               &&
	       escape_path_eq(a.path, b.path) &&
	       a.exact == b.exact             &&
	       a.node  == b.node              &&
	       escape_origin_eq(a.dest,   b.dest) &&
	       escape_origin_eq(a.origin, b.origin);
}

gb_internal EscapeValue escape_value(void) {
	// NOTE(bill): most values are empty so allocate on the fly when needed
	return array_make<EscapeValueFact>(temporary_allocator(), 0, 0);
}

gb_internal void escape_value_add(EscapeValue *v, EscapePath const &path, EscapeOrigin const &o, bool definite=false) {
	for (EscapeValueFact &f : *v) {
		if (escape_path_eq(f.path, path) && escape_origin_eq(f.origin, o)) {
			f.definite |= definite;
			return;
		}
	}
	array_add(v, EscapeValueFact{path, o, definite});
}

// either of two values, so neither is definite
gb_internal void escape_value_merge(EscapeValue *v, EscapeValue const &w) {
	for (EscapeValueFact &f : *v) {
		f.definite = false;
	}
	for (EscapeValueFact const &f : w) {
		escape_value_add(v, f.path, f.origin);
	}
}

gb_internal EscapeValue escape_value_of(EscapeOriginKind kind, EscapeObject const &obj, EscapePath const &path) {
	EscapeValue v = escape_value();
	// the stack memory is made by the expression itself
	bool definite = kind == EscapeOrigin_Local || kind == EscapeOrigin_Temp;
	escape_value_add(&v, {}, EscapeOrigin{kind, obj, path}, definite);
	return v;
}

gb_internal isize escape_path_deref_index(EscapePath const &p) {
	for_array(i, p) {
		if (p[i].kind == EscapeStep_Deref) {
			return i;
		}
	}
	return p.count;
}


gb_internal EscapeValue escape_pointer_offset(EscapeValue const &v, EscapePath const &extra) {
	EscapeValue w = escape_value();
	for (EscapeValueFact const &f : v) {
		EscapeOrigin o = f.origin;
		switch (o.kind) {
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
		}
		escape_value_add(&w, {}, o, f.definite);
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
	s.facts  = array_make<EscapeFact>(temporary_allocator(), 0, 0);
	s.outers = array_make<EscapeOuterStore>(temporary_allocator(), 0, 0);
	return s;
}

gb_internal EscapeState escape_state_clone(EscapeState const &s) {
	EscapeState c = {};
	c.reachable = s.reachable;
	c.facts  = array_clone(temporary_allocator(), s.facts);
	c.outers = array_clone(temporary_allocator(), s.outers);
	return c;
}

gb_internal void escape_add_fact(Array<EscapeFact> *facts, EscapeFact const &f) {
	for (EscapeFact const &g : *facts) {
		if (escape_object_eq(f.obj, g.obj)   &&
		    escape_path_eq(f.path, g.path) &&
		    escape_origin_eq(f.origin, g.origin)) {
			return;
		}
	}
	array_add(facts, f);
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
		isize count = dst->facts.count;
		escape_add_fact(&dst->facts, f);
		changed |= dst->facts.count != count;
	}

	for (EscapeOuterStore const &o : src.outers) {
		bool found = false;
		for (EscapeOuterStore const &p : dst->outers) {
			if (escape_outer_eq(o, p)) {
				found = true;
				break;
			}
		}
		if (!found) {
			array_add(&dst->outers, o);
			changed = true;
		}
	}
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

gb_internal bool escape_is_using_field(Entity *e) {
	return e->using_parent != nullptr &&
	       e->using_expr   == nullptr;
}


gb_internal EscapeValue escape_obj_value(EscapeAnalysis *ea, EscapeObject const &obj, EscapePath const &path) {
	EscapeValue v = escape_value();
	for (EscapeFact const &f : ea->state.facts) {
		if (escape_object_eq(f.obj, obj)) {
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
		if (step.kind == EscapeStep_Field) {
			if (bt->kind != Type_Struct) {
				return nullptr;
			}
			bool is_own_field = false;
			for (Entity *field : bt->Struct.fields) {
				is_own_field |= field == step.field;
			}
			if (!is_own_field) {
				return nullptr;
			}
			t = step.field->type;
			continue;
		}
		switch (bt->kind) {
		case Type_Array:                     t = bt->Array.elem;                     break;
		case Type_EnumeratedArray:           t = bt->EnumeratedArray.elem;           break;
		case Type_FixedCapacityDynamicArray: t = bt->FixedCapacityDynamicArray.elem; break;
		case Type_Slice:                     t = bt->Slice.elem;                     break;
		case Type_DynamicArray:              t = bt->DynamicArray.elem;              break;
		case Type_Map:                       t = bt->Map.value;                      break;
		case Type_Matrix:                    t = bt->Matrix.elem;                    break;
		default:
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

// whether what a value of the type points to cannot hold pointers, e.g. the bytes of a `[]u8`
gb_internal bool escape_points_to_plain(Type *t) {
	Type *pointee = escape_pointee_type(t);
	return pointee != nullptr && !escape_type_has_pointers(pointee);
}

// a store to a field overwrites only that part of a fact for more of the value, so it is kept for the other fields
gb_internal bool escape_split_fact(EscapeFact const &f, Type *type, EscapePath const &path, Array<EscapeFact> *pieces) {
	auto split = array_make<EscapeFact>(temporary_allocator(), 0, 0);
	Type *t = type;
	for_array(i, path) {
		EscapeStep const &step = path[i];
		Type *bt = base_type(t);
		if (step.kind != EscapeStep_Field || bt == nullptr || bt->kind != Type_Struct) {
			return false;
		}
		bool is_own_field = false;
		for (Entity *field : bt->Struct.fields) {
			is_own_field |= field == step.field;
		}
		if (!is_own_field) {
			// e.g. a field reached through 'using'
			return false;
		}

		if (i >= f.path.count) {
			for (Entity *field : bt->Struct.fields) {
				if (field == step.field || !escape_type_has_pointers(field->type)) {
					continue;
				}
				EscapePath piece = escape_path_concat(slice(path, 0, i), escape_path_of(EscapeStep_Field, field));
				array_add(&split, EscapeFact{f.obj, piece, escape_origin_within(f.origin, piece, f.path.count)});
			}
		}
		t = step.field->type;
	}
	array_add_elems(pieces, split.data, split.count);
	return true;
}

gb_internal void escape_store_obj(EscapeAnalysis *ea, EscapeObject const &obj, EscapePath const &path, EscapeValue const &v, EscapeUpdateKind update) {
	if (update == EscapeUpdate_Replace && !escape_path_has(path, EscapeStep_AnyElement)) {
		Type *type = escape_type_at(obj, {});
		auto pieces = array_make<EscapeFact>(temporary_allocator(), 0, 0);
		for (isize i = ea->state.facts.count-1; i >= 0; i--) {
			EscapeFact const &f = ea->state.facts[i];
			if (!escape_object_eq(f.obj, obj)) {
				continue;
			}
			if (escape_path_has_prefix(f.path, path)) {
				array_unordered_remove(&ea->state.facts, i);
			} else if (escape_path_has_prefix(path, f.path) && escape_split_fact(f, type, path, &pieces)) {
				array_unordered_remove(&ea->state.facts, i);
			}
		}
		for (EscapeFact const &p : pieces) {
			escape_add_fact(&ea->state.facts, p);
		}
	}
	for (EscapeValueFact const &vf : v) {
		escape_add_fact(&ea->state.facts, EscapeFact{obj, escape_path_concat(path, vf.path), vf.origin});
	}
}

// what loading through a pointer of the caller's memory gives
gb_internal EscapeOrigin escape_param_loaded(EscapeOrigin o) {
	switch (o.kind) {
	case EscapeOrigin_Param:     o.kind = EscapeOrigin_ParamLoad; break;
	case EscapeOrigin_ParamLoad: o.kind = EscapeOrigin_ParamDeep; break;
	}
	return o;
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
			escape_value_add(&v, {}, o);
			break;

		case EscapeOrigin_Variadic: {
			// NOTE(bill): its 'any' elements are boxed in the caller's stack frame too
			Type *elem = base_type(o.obj.entity->type);
			if (elem->kind == Type_Slice && is_type_any(elem->Slice.elem)) {
				escape_value_add(&v, {}, o);
			} else {
				// its elements are the caller's arguments
				escape_value_add(&v, {}, EscapeOrigin{EscapeOrigin_ParamLoad, o.obj, o.path});
			}
			break;
		}
		case EscapeOrigin_Local:
			if (escape_is_param(o.obj.entity)) {
				// what a parameter holds is the caller's
				escape_value_add(&v, {}, EscapeOrigin{EscapeOrigin_Param, o.obj, o.path});
				break;
			}
			/*fallthrough*/
		case EscapeOrigin_Temp:
		case EscapeOrigin_Owned:
			for (EscapeFact const &f : ea->state.facts) {
				if (escape_object_eq(f.obj, o.obj)) {
					escape_project_into(&v, EscapeValueFact{f.path, f.origin}, o.path);
				}
			}
			break;

		case EscapeOrigin_Param:
		case EscapeOrigin_ParamLoad:
		case EscapeOrigin_ParamDeep:
			escape_value_add(&v, {}, escape_param_loaded(o));
			break;

		case EscapeOrigin_Invalid:
			break;
		}
	}
	return v;
}

gb_internal EscapeValue escape_expr(EscapeAnalysis *ea, Ast *expr);
gb_internal EscapeValue escape_addr(EscapeAnalysis *ea, Ast *expr);

gb_internal Array<EscapeValue> escape_call(EscapeAnalysis *ea, Ast *call);
gb_internal Ast *escape_call_of(Ast *expr);
gb_internal void escape_store_through(EscapeAnalysis *ea, Ast *node, EscapeValue const &ptr, EscapeValue const &v, EscapeUpdateKind update);

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
		for (EscapeValueFact const &f : addr) {
			EscapeOrigin o = f.origin;
			switch (o.kind) {
			case EscapeOrigin_Local:
				if (escape_is_param(o.obj.entity)) {
					// the buffer of a parameter is the caller's
					escape_value_add(&ptr, {}, EscapeOrigin{EscapeOrigin_Param, o.obj, o.path});
					break;
				}
				/*fallthrough*/
			case EscapeOrigin_Temp:
			case EscapeOrigin_Owned:
				o.kind = EscapeOrigin_Owned;
				o.path = escape_path_concat(o.path, escape_path_of(EscapeStep_AnyElement));
				escape_value_add(&ptr, {}, o, f.definite);
				break;
			case EscapeOrigin_Outer:
				escape_value_add(&ptr, {}, o);
				break;
			case EscapeOrigin_Param:
			case EscapeOrigin_ParamLoad:
			case EscapeOrigin_ParamDeep:
				escape_value_add(&ptr, {}, escape_param_loaded(o));
				break;
			}
		}
		return ptr;
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

gb_internal void escape_stmt  (EscapeAnalysis *ea, Ast *node);
gb_internal void escape_branch(EscapeAnalysis *ea, Ast *label, TokenKind kind);
gb_internal void escape_exit  (EscapeAnalysis *ea, Ast *node,  Slice<Ast *> const &results, Array<EscapeValue> const &values);

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

gb_internal EscapeValue escape_ident_value(EscapeAnalysis *ea, Entity *e);

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
		Entity *parent = e->using_parent;
		Type *t = base_type(type_deref(parent->type));
		Entity *field = nullptr;
		if (t != nullptr && t->kind == Type_Struct) {
			for (Entity *f : t->Struct.fields) {
				if (f->token.string == e->token.string) {
					field = f;
					break;
				}
			}
		}
		if (field == nullptr) {
			return escape_value();
		}

		EscapeValue base = {};
		if (is_type_pointer(parent->type)) {
			base = escape_ident_value(ea, parent);
		} else {
			base = escape_ident_addr(ea, parent);
		}
		return escape_pointer_offset(base, escape_path_of(EscapeStep_Field, field));
	}

	if (!escape_is_local(e)) {
		return escape_value_of(EscapeOrigin_Outer, {}, {});
	}
	return escape_value_of(EscapeOrigin_Local, {e}, {});
}

gb_internal EscapeValue escape_ident_value(EscapeAnalysis *ea, Entity *e) {
	if (e == nullptr || e->kind != Entity_Variable) {
		return escape_value();
	}

	if (escape_is_reference(e) || escape_is_using_field(e)) {
		return escape_load(ea, escape_ident_addr(ea, e), e->type);
	}

	if (!escape_is_local(e)) {
		if (escape_type_has_pointers(e->type)) {
			return escape_value_of(EscapeOrigin_Outer, {}, {});
		}
		return escape_value();
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


gb_internal bool escape_is_explicit_unsafe_conversion(Type *t) {
	return t != nullptr && (is_type_rawptr(t) || is_type_uintptr(t));
}

gb_internal Slice<EscapeFlow> escape_flows_of(EscapeAnalysis *ea, Entity *e);

// loading through the pointers once, as the callee does, where a dynamic array or map holds the pointer to its buffer
gb_internal EscapeValue escape_load_once(EscapeAnalysis *ea, EscapeValue const &ptr) {
	EscapeValue v = escape_value();
	for (EscapeValueFact const &f : ptr) {
		EscapeOrigin o = f.origin;
		switch (o.kind) {
		case EscapeOrigin_Local:
		case EscapeOrigin_Temp:
		case EscapeOrigin_Owned: {
			Type *t = base_type(escape_type_at(o.obj, o.path));

			bool holds_buffer = t != nullptr && (t->kind == Type_DynamicArray || t->kind == Type_Map);

			if (holds_buffer && !(o.kind == EscapeOrigin_Local && escape_is_param(o.obj.entity))) {
				o.kind = EscapeOrigin_Owned;
				o.path = escape_path_concat(o.path, escape_path_of(EscapeStep_AnyElement));
				escape_value_add(&v, {}, o);
				continue;
			}
			break;
		}
		}

		EscapeValue single = escape_value();
		escape_value_add(&single, {}, o);
		for (EscapeValueFact const &g : escape_load(ea, single, nullptr)) {
			escape_value_add(&v, g.path, g.origin);
		}
	}
	return v;
}

// what is loaded through the pointers of a value, at any depth
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

// the path of a parameter's origin is where in its value the pointer is, then a deref and the offset into what it points to
gb_internal EscapeValue escape_arg_pointers(EscapeValue const &arg, Type *type, EscapePath const &path, Type **pointee) {
	isize deref = escape_path_deref_index(path);
	EscapePath value_path = slice(path, 0, deref);
	EscapePath offset = {};
	if (deref < path.count) {
		offset = slice(path, deref+1, path.count);
	}
	*pointee = escape_type_within(escape_pointee_type(escape_type_within(type, value_path)), offset);
	if (*pointee == nullptr) {
		// e.g. the offset was made through a cast in the callee
		offset = {};
	}
	return escape_pointer_offset(escape_as_pointer(escape_value_project(arg, value_path)), offset);
}

gb_internal bool escape_param_index_of_arg(TypeProc *pt, Ast *arg, isize position, isize *index) {
	if (arg->kind != Ast_FieldValue) {
		*index = position;
		if (pt->variadic && position > pt->variadic_index) {
			*index = pt->variadic_index;
		}
		return *index < pt->param_count;
	}
	Ast *name = arg->FieldValue.field;
	if (name->kind != Ast_Ident || pt->params == nullptr) {
		return false;
	}
	for_array(i, pt->params->Tuple.variables) {
		if (pt->params->Tuple.variables[i]->token.string == name->Ident.token.string) {
			*index = i;
			return true;
		}
	}
	return false;
}

gb_internal Array<EscapeValue> escape_call(EscapeAnalysis *ea, Ast *call) {
	ast_node(ce, CallExpr, call);
	escape_visit_exits(ea, ce->proc);

	Entity *e = nullptr;
	Ast *proc = unparen_expr(ce->proc);
	if (proc->kind == Ast_Ident || proc->kind == Ast_SelectorExpr) {
		e = entity_of_node(proc);
	}

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
				if (!escape_points_to_plain(ce->args[1]->tav.type)) {
					escape_store_through(ea, call, dst, escape_load(ea, src, nullptr), EscapeUpdate_Add);
				}
				return results;
			}
			break;
		}
	}

	TypeProc *pt = nullptr;
	Slice<EscapeFlow> flows = {};
	if (ce->args.count > 0 && e != nullptr && e->kind == Entity_Procedure) {
		// with the constant parameters of a specialization, as its arguments and summary have them
		Type *t = base_type(proc_entity_full_type(e));
		if (t != nullptr && t->kind == Type_Proc) {
			pt = &t->Proc;
			flows = escape_flows_of(ea, e);
		}
	}
	if (flows.count == 0) {
		for (Ast *arg : ce->args) {
			if (arg->kind == Ast_FieldValue) {
				arg = arg->FieldValue.value;
			}
			escape_visit_exits(ea, arg);
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
	for_array(i, args) {
		args[i]  = escape_value();
		types[i] = nullptr;
		given[i] = false;
	}

	bool packs_variadic = pt->variadic && !pt->c_vararg && ce->ellipsis.pos.line == 0;
	for_array(i, ce->args) {
		Ast *arg = ce->args[i];
		Ast *value = arg;
		if (arg->kind == Ast_FieldValue) {
			value = arg->FieldValue.value;
		}

		isize index = 0;
		bool involved = false;
		if (escape_param_index_of_arg(pt, arg, i, &index)) {
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
		if (!given[flow.param]) {
			continue;
		}
		EscapeValue v = {};
		if (flow.kind == EscapeFlow_Value && escape_path_deref_index(flow.param_path) == flow.param_path.count) {
			v = escape_value_project(args[flow.param], flow.param_path);
		} else {
			Type *pointee = nullptr;
			v = escape_arg_pointers(args[flow.param], types[flow.param], flow.param_path, &pointee);
			if (flow.kind != EscapeFlow_Value) {
				if (pointee != nullptr && !escape_type_has_pointers(pointee)) {
					continue;
				}
				v = escape_load_once(ea, v);
			}
			if (flow.kind == EscapeFlow_Deep) {
				v = escape_reachable(ea, v);
			}
		}

		switch (flow.target) {
		case EscapeFlowTarget_Result:
			for (EscapeValueFact const &f : v) {
				escape_value_add(&results[flow.target_index], escape_path_concat(flow.target_path, f.path), f.origin);
			}
			break;

		case EscapeFlowTarget_Pointee:
		case EscapeFlowTarget_Loaded:
		case EscapeFlowTarget_Deep:
			if (given[flow.target_index]) {
				Type *pointee = nullptr;
				EscapeValue ptr = escape_arg_pointers(args[flow.target_index], types[flow.target_index], flow.target_path, &pointee);
				if (flow.target != EscapeFlowTarget_Pointee) {
					ptr = escape_as_pointer(escape_load_once(ea, ptr));
				}
				if (flow.target == EscapeFlowTarget_Deep) {
					ptr = escape_reachable(ea, ptr);
				}
				escape_store_through(ea, call, ptr, v, EscapeUpdate_Add);
			}
			break;

		case EscapeFlowTarget_Outer:
			escape_store_through(ea, call, escape_value_of(EscapeOrigin_Outer, {}, {}), v, EscapeUpdate_Add);
			break;
		}
	}
	return results;
}

// the call of an expression of several values, e.g. `x, ok := f()`
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

gb_internal EscapeValue escape_expr(EscapeAnalysis *ea, Ast *expr) {
	if (expr == nullptr) {
		return escape_value();
	}

	TypeAndValue const &tav = expr->tav;
	if (tav.mode == Addressing_Constant) {
		if (tav.type == nullptr || !is_type_slice(tav.type) || is_load_directive_call(expr)) {
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

			switch (t->kind) {
			case Type_Struct: {
				Entity *f = nullptr;
				if (elem->kind == Ast_FieldValue) {
					Ast *field = elem->FieldValue.field;
					if (field->kind == Ast_Ident) {
						for (Entity *g : t->Struct.fields) {
							if (g->token.string == field->Ident.token.string) {
								f = g;
								break;
							}
						}
					}
				} else if (i < t->Struct.fields.count) {
					f = t->Struct.fields[i];
				}
				if (f != nullptr && !t->Struct.is_raw_union) {
					path = escape_path_of(EscapeStep_Field, f);
				} else {
					path = EscapePath{};
				}

				if (f != nullptr) {
					elem_type = f->type;
				}
				break;
			}

			case Type_Array:                     elem_type = t->Array.elem;                     break;
			case Type_EnumeratedArray:           elem_type = t->EnumeratedArray.elem;           break;
			case Type_FixedCapacityDynamicArray: elem_type = t->FixedCapacityDynamicArray.elem; break;
			case Type_Slice:                     elem_type = t->Slice.elem;                     break;
			case Type_DynamicArray:              elem_type = t->DynamicArray.elem;              break;
			case Type_Map:                       elem_type = t->Map.value;                      break;

			default:
				path = {};
				break;
			}
			if (elem_type != nullptr && escape_type_is_plain(elem_type)) {
				escape_visit_exits(ea, value);
				continue;
			}
			EscapeValue ev = escape_convert(ea, escape_expr(ea, value), value, elem_type);
			for (EscapeValueFact const &f : ev) {
				escape_value_add(&v, escape_path_concat(path, f.path), f.origin, f.definite);
			}
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
		escape_visit_exits(ea, ue->expr);
		return escape_value();
	case_end;

	case_ast_node(be, BinaryExpr, expr);
		escape_visit_exits(ea, be->left);
		escape_visit_exits(ea, be->right);
		return escape_value();
	case_end;

	case_ast_node(se, SelectorExpr, expr);
		if (Entity *g = escape_package_selector(expr)) {
			return escape_ident_value(ea, g);
		}
		EscapePath path = {};
		if (!escape_selector_path(expr, &path)) {
			escape_visit_exits(ea, se->expr);
			return escape_value();
		}
		if (is_type_pointer(se->expr->tav.type)) {
			return escape_load(ea, escape_pointer_offset(escape_expr(ea, se->expr), path), tav.type);
		}
		return escape_value_project(escape_expr(ea, se->expr), path);
	case_end;

	case_ast_node(ie, IndexExpr, expr);
		Type *t = base_type(ie->expr->tav.type);
		if (t == nullptr) {
			escape_visit_exits(ea, ie->index);
			return escape_value();
		}
		switch (t->kind) {
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
		escape_visit_exits(ea, ie->expr);
		escape_visit_exits(ea, ie->index);
		return escape_value();
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
		if (te->cond == nullptr || te->cond->tav.value.kind != ExactValue_Bool) {
			return escape_value();
		}
		if (te->cond->tav.value.value_bool) {
			return escape_expr(ea, te->x);
		}
		return escape_expr(ea, te->y);
	case_end;

	case_ast_node(oe, OrElseExpr, expr);
		EscapeValue v = escape_expr(ea, oe->x);
		escape_value_merge(&v, escape_expr(ea, oe->y));
		return v;
	case_end;

	case_ast_node(re, OrReturnExpr, expr);
		EscapeValue v = escape_expr(ea, re->expr);
		EscapeState state = escape_state_clone(ea->state);
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

		EscapeValue w = escape_value();
		for (EscapeValueFact const &f : escape_expr(ea, ta->expr)) {
			escape_value_add(&w, {}, f.origin, f.definite);
		}
		return w;
	case_end;

	case_ast_node(te, TagExpr, expr);
		return escape_expr(ea, te->expr);
	case_end;

	case_ast_node(fv, FieldValue, expr);
		return escape_expr(ea, fv->value);
	case_end;
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

gb_internal bool escape_find_stack_origin(EscapeAnalysis *ea, EscapeValue const &v, EscapeOrigin *found, bool *definite=nullptr) {
	for (EscapeValueFact const &f : v) {
		if (f.definite && escape_is_stack(f.origin)) {
			*found = f.origin;
			if (definite) {
				*definite = true;
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
			return true;
		}
		if (o.kind != EscapeOrigin_Owned) {
			continue;
		}

		for (EscapeFact const &f : ea->state.facts) {
			if (!escape_object_eq(f.obj, o.obj)) {
				continue;
			}
			if (!escape_path_has_prefix(f.path, o.path) && !escape_path_has_prefix(o.path, f.path)) {
				continue;
			}

			bool seen = false;
			for (EscapeOrigin const &w : work) {
				if (escape_origin_eq(w, f.origin)) {
					seen = true;
					break;
				}
			}
			if (!seen) {
				array_add(&work, f.origin);
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

gb_internal void escape_report_emit(EscapeReport const &r) {
	Ast *node = r.node;
	String expr_str = r.expr_str;
	EscapeOrigin const &o = r.origin;
	EscapeReportKind kind = r.kind;

	gbString origin = gb_string_make(heap_allocator(), "");
	defer (gb_string_free(origin));
	switch (o.kind) {
	case EscapeOrigin_Local: {
		char const *description = "local variable";
		if (o.obj.entity->flags & EntityFlag_Param) {
			description = "parameter";
		}
		origin = gb_string_append_fmt(origin, "the stack memory of the %s '%.*s'", description, LIT(o.obj.entity->token.string));
		break;
	}
	case EscapeOrigin_Temp: {
		char const *description = "a temporary value";
		if (o.obj.temp->kind == Ast_CompoundLit) {
			description = "a compound literal";
		}
		origin = gb_string_append_fmt(origin, "the stack memory of %s", description);
		break;
	}
	case EscapeOrigin_Variadic:
		origin = gb_string_append_fmt(origin, "the variadic parameter '%.*s', which only lives for the duration of the call", LIT(o.obj.entity->token.string));
		break;
	}

	ERROR_BLOCK();
	switch (kind) {
	case EscapeReport_Return:
		error(ast_token(node), "It is unsafe to return '%.*s' from a procedure, as it refers to %s", LIT(expr_str), origin);
		break;
	case EscapeReport_MayReturn:
		warning(ast_token(node), "It is unsafe to return '%.*s' from a procedure, as it may refer to %s", LIT(expr_str), origin);
		break;
	case EscapeReport_Store:
		warning(ast_token(node), "'%.*s' may still refer to %s after the procedure returns", LIT(expr_str), origin);
		break;
	case EscapeReport_CallStore:
		warning(ast_token(node), "'%.*s' may keep a reference to %s after the procedure returns", LIT(expr_str), origin);
		break;
	default:
		GB_PANIC("Unhandled EscapeReportKind");
		break;
	}

	if (kind == EscapeReport_Store) {
		error_line("\tSuggestion: Clear it before the procedure returns, e.g. 'defer %.*s = %s'\n", LIT(expr_str), type_zero_value_string(node->tav.type));
	} else {
		error_line("\tSuggestion: If this is intended, make it explicit with a conversion to 'rawptr' or 'uintptr', or a 'transmute'\n");
	}
}

gb_internal void escape_report(EscapeAnalysis *ea, Ast *node, String expr_str, EscapeOrigin const &o, EscapeReportKind kind) {
	if (ea->muted || (kind != EscapeReport_Return && global_ignore_warnings())) {
		return;
	}
	for (Ast *r : ea->reported) {
		if (r == node) {
			return;
		}
	}
	array_add(&ea->reported, node);

	EscapeReport r = {kind, node, expr_str, o};
	if (ea->reports == nullptr) {
		escape_report_emit(r);
		return;
	}
	// kept beyond this analysis and its temporary memory
	r.expr_str    = copy_string(permanent_allocator(), expr_str);
	r.origin.path = {};
	array_add(ea->reports, r);
}

gb_internal void escape_report_value(EscapeAnalysis *ea, Ast *node, Ast *expr, String name, EscapeValue const &v) {
	EscapeOrigin o = {};
	bool definite = false;
	if (!escape_find_stack_origin(ea, v, &o, &definite)) {
		return;
	}

	EscapeReportKind kind = EscapeReport_MayReturn;
	if (definite) {
		kind = EscapeReport_Return;
	}

	if (expr != nullptr) {
		gbString s = escape_expr_to_string(expr);
		escape_report(ea, node, make_string_c(s), o, kind);
		gb_string_free(s);
	} else {
		escape_report(ea, node, name, o, kind);
	}
}

gb_internal void escape_run_defers(EscapeAnalysis *ea, isize depth) {
	for (isize i = ea->defers.count-1; i >= depth; i--) {
		Array<Ast *> defers = array_clone(temporary_allocator(), ea->defers[i]);
		for (isize j = defers.count-1; j >= 0; j--) {
			escape_stmt(ea, defers[j]);
		}
	}
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

// a flow from the parameter whose memory the origin is
gb_internal bool escape_flow_from(TypeProc *pt, EscapeOrigin const &o, EscapeFlow *flow) {
	switch (o.kind) {
	case EscapeOrigin_Param:     flow->kind = EscapeFlow_Value; break;
	case EscapeOrigin_ParamLoad: flow->kind = EscapeFlow_Load;  break;
	case EscapeOrigin_ParamDeep: flow->kind = EscapeFlow_Deep;  break;
	default:
		return false;
	}
	flow->param_path = o.path;
	return escape_param_index(pt, o.obj.entity, &flow->param);
}

gb_internal bool escape_flow_eq(EscapeFlow const &a, EscapeFlow const &b) {
	return a.kind         == b.kind         &&
	       a.param        == b.param        &&
	       a.target       == b.target       &&
	       a.target_index == b.target_index &&
	       escape_path_eq(a.param_path,  b.param_path) &&
	       escape_path_eq(a.target_path, b.target_path);
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
	for (EscapeFlow const &g : ea->flows) {
		if (escape_flow_eq(g, flow)) {
			return;
		}
	}
	array_add(&ea->flows, flow);
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

gb_internal void escape_add_store_flow(EscapeAnalysis *ea, EscapeOuterStore const &s) {
	EscapeFlow flow = {};
	if (!escape_flow_from(ea->pt, s.origin, &flow)) {
		return;
	}
	switch (s.dest.kind) {
	case EscapeOrigin_Outer:     flow.target = EscapeFlowTarget_Outer;   break;
	case EscapeOrigin_Param:     flow.target = EscapeFlowTarget_Pointee; break;
	case EscapeOrigin_ParamLoad: flow.target = EscapeFlowTarget_Loaded;  break;
	case EscapeOrigin_ParamDeep: flow.target = EscapeFlowTarget_Deep;    break;
	default:
		return;
	}
	if (flow.target != EscapeFlowTarget_Outer) {
		flow.target_path = s.dest.path;
		if (!escape_param_index(ea->pt, s.dest.obj.entity, &flow.target_index)) {
			return;
		}
	}
	if (flow.target == EscapeFlowTarget_Pointee &&
	    flow.target_index == flow.param &&
	    escape_path_eq(flow.target_path, flow.param_path)) {
		// storing it back into the memory it came from cannot make anything outlive it
		return;
	}
	escape_add_flow(ea, flow);
}

gb_internal void escape_exit(EscapeAnalysis *ea, Ast *node, Slice<Ast *> const &results, Array<EscapeValue> const &values) {
	TypeProc *pt = ea->pt;
	isize result_count = 0;
	if (pt->results != nullptr) {
		result_count = pt->results->Tuple.variables.count;
	}

	// what is returned is fixed before the defers run
	if (values.count == result_count) {
		for (isize i = 0; i < result_count; i++) {
			Ast *result = results[0]; // the single call of several results
			if (results.count == values.count) {
				result = results[i];
			}
			escape_report_value(ea, result, result, {}, values[i]);
			escape_add_result_flows(ea, i, values[i]);
		}
	} else if (pt->has_named_results) {
		for_array(i, pt->results->Tuple.variables) {
			Entity *e = pt->results->Tuple.variables[i];
			EscapeValue v = escape_obj_value(ea, {e}, {});
			escape_report_value(ea, node, nullptr, e->token.string, v);
			escape_add_result_flows(ea, i, v);
		}
	}

	escape_run_defers(ea, 0);

	for (EscapeOuterStore const &s : ea->state.outers) {
		escape_add_store_flow(ea, s);

		EscapeValue v = escape_value();
		escape_value_add(&v, {}, s.origin);
		EscapeOrigin o = {};
		if (escape_find_stack_origin(ea, v, &o) && o.kind != EscapeOrigin_Variadic) {
			EscapeReportKind kind = EscapeReport_Store;
			if (s.node->kind == Ast_CallExpr) {
				kind = EscapeReport_CallStore;
			}
			gbString str = escape_expr_to_string(s.node);
			escape_report(ea, s.node, make_string_c(str), o, kind);
			gb_string_free(str);
		}
	}
	ea->state.reachable = false;
}

// returns whether the location is exact, so that a later store to it replaces this one
gb_internal bool escape_outer_location(Ast *lhs, Entity **root, EscapePath *path) {
	lhs = unparen_expr(lhs);
	*root = nullptr;
	*path = {};
	switch (lhs->kind) {
	case_ast_node(i, Ident, lhs);
		*root = entity_of_node(lhs);
		return *root != nullptr;
	case_end;
	case_ast_node(se, SelectorExpr, lhs);
		if (Entity *g = escape_package_selector(lhs)) {
			*root = g;
			return true;
		}

		EscapePath field = {};
		if (!escape_selector_path(lhs, &field)) {
			return false;
		}

		bool exact = escape_outer_location(se->expr, root, path);
		if (is_type_pointer(se->expr->tav.type)) {
			*path = escape_path_concat(*path, escape_path_of(EscapeStep_Deref));
		}
		*path = escape_path_concat(*path, field);
		return exact;
	case_end;
	case_ast_node(ie, IndexExpr, lhs);
		escape_outer_location(ie->expr, root, path);
		*path = escape_path_concat(*path, escape_path_of(EscapeStep_AnyElement));
		return false;
	case_end;
	case_ast_node(de, DerefExpr, lhs);
		bool exact = escape_outer_location(de->expr, root, path);
		*path = escape_path_concat(*path, escape_path_of(EscapeStep_Deref));
		return exact;
	case_end;
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
		if (escape_is_local(e) && e->using_parent == nullptr && !escape_is_reference(e)) {
			escape_store_obj(ea, {e}, {}, v, EscapeUpdate_Replace);
			return;
		}
	}

	EscapeValue ptr = escape_addr(ea, lhs);
	// with only one place it may store to, the store replaces what that held
	EscapeUpdateKind update = EscapeUpdate_Add;
	if (ptr.count == 1) {
		update = EscapeUpdate_Replace;
	}
	escape_store_through(ea, lhs, ptr, v, update);
}

// `node` is the left hand side, or a call storing into memory it was given
gb_internal void escape_store_through(EscapeAnalysis *ea, Ast *node, EscapeValue const &ptr, EscapeValue const &v, EscapeUpdateKind update) {
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
			s.node  = node;
			s.dest  = o;
			s.exact = escape_outer_location(node, &s.root, &s.path);
			if (s.exact) {
				for (isize i = ea->state.outers.count-1; i >= 0; i--) {
					EscapeOuterStore const &p = ea->state.outers[i];
					if (p.root == s.root && escape_path_eq(p.path, s.path)) {
						array_unordered_remove(&ea->state.outers, i);
					}
				}
			}

			for (EscapeValueFact const &vf : v) {
				s.node   = node;
				s.origin = vf.origin;
				switch (vf.origin.kind) {
				case EscapeOrigin_Outer:
					continue;
				case EscapeOrigin_Param:
				case EscapeOrigin_ParamLoad:
				case EscapeOrigin_ParamDeep:
					// never reported, only made into a flow, so where it is stored does not need telling apart
					s.node = nullptr;
					break;
				}
				bool found = false;
				for (EscapeOuterStore const &p : ea->state.outers) {
					if (escape_outer_eq(p, s)) {
						found = true;
						break;
					}
				}
				if (!found) {
					array_add(&ea->state.outers, s);
				}
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


gb_internal void escape_loop(EscapeAnalysis *ea, Ast *stmt, Ast *cond, Ast *post, Ast *body, Ast *val0, Ast *val1, Ast *range) {
	isize target_index = escape_push_target(ea, stmt, EscapeTarget_Loop);
	isize alias_count  = ea->aliases.count;

	EscapeState head = escape_state_clone(ea->state);
	EscapeState exit = escape_state_unreachable();

	enum : isize { MAX_ITERATION_COUNT = 16 };

	for (isize iteration = 0; iteration < MAX_ITERATION_COUNT; iteration++) {
		ea->state = escape_state_clone(head);
		escape_visit_exits(ea, cond);

		bool may_exit = range != nullptr;
		if (cond != nullptr) {
			may_exit = true;
			if (cond->tav.mode == Addressing_Constant &&
			    cond->tav.value.kind == ExactValue_Bool &&
			    cond->tav.value.value_bool) {
				may_exit = false;
			}
		}
		if (may_exit) {
			escape_state_join(&exit, ea->state);
		}

		if (range != nullptr) {
			Ast *x = unparen_expr(range);
			Type *t = base_type(x->tav.type);
			Type *container = t;
			if (t != nullptr && t->kind == Type_Pointer) {
				container = base_type(t->Pointer.elem);
			}
			TypeKind container_kind = Type_Invalid;
			if (container != nullptr) {
				container_kind = container->kind;
			}

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
				bool by_ref = false;
				if (name != nullptr && name->kind == Ast_UnaryExpr && name->UnaryExpr.op.kind == Token_And) {
					name = name->UnaryExpr.expr;
					by_ref = true;
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
		}

		escape_stmt(ea, body);
		escape_state_join(&ea->state, ea->targets[target_index].continues);
		if (ea->state.reachable && post != nullptr) {
			escape_stmt(ea, post);
		}

		ea->aliases.count = alias_count;

		Ast *vals[2] = {val0, val1};
		for (Ast *val : vals) {
			if (val != nullptr && val->kind == Ast_UnaryExpr) {
				val = val->UnaryExpr.expr;
			}
			if (val != nullptr && val->kind == Ast_Ident) {
				escape_forget_entity(ea, entity_of_node(val));
			}
		}
		if (!escape_state_join(&head, ea->state)) {
			break;
		}
	}
	escape_state_join(&exit, ea->targets[target_index].breaks);
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
		for (Ast *e : cc->list) {
			escape_visit_exits(ea, e);
		}
		isize alias_count = ea->aliases.count;
		if (cc->implicit_entity != nullptr) {
			Entity *e = cc->implicit_entity;
			if (e->flags & EntityFlag_Value) {
				EscapeValue v = escape_value();
				if (tag_by_ptr) {
					v = escape_load(ea, tag_ptr, e->type);
				} else {
					for (EscapeValueFact const &f : tag) {
						escape_value_add(&v, {}, f.origin);
					}
				}
				escape_store_obj(ea, {e}, {}, v, EscapeUpdate_Replace);
			} else {
				for (EscapeValueFact const &f : tag_ptr) {
					array_add(&ea->aliases, EscapeAlias{e, f.origin});
				}
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
	array_pop(&ea->targets);
	ea->state = exit;
}

gb_internal void escape_stmt(EscapeAnalysis *ea, Ast *node) {
	if (node == nullptr || !ea->state.reachable) {
		return;
	}
	switch (node->kind) {
	case_ast_node(es, ExprStmt, node);
		escape_visit_exits(ea, es->expr);
		if (is_diverging_stmt(node)) {
			ea->state.reachable = false;
		}
	case_end;

	case_ast_node(vd, ValueDecl, node);
		if (!vd->is_mutable) {
			break;
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
			Array<EscapeValue> results = {};
			Ast *call = nullptr;
			if (vd->values.count == 1) {
				call = escape_call_of(vd->values[0]);
			}
			if (call != nullptr) {
				results = escape_call(ea, call);
			} else {
				for (Ast *value : vd->values) {
					escape_visit_exits(ea, value);
				}
			}
			for_array(i, vd->names) {
				Entity *e = entity_of_node(vd->names[i]);
				if (!escape_is_local(e)) {
					continue;
				}
				EscapeValue v = escape_value();
				if (i < results.count) {
					v = results[i];
				}
				escape_store_obj(ea, {e}, {}, v, EscapeUpdate_Replace);
			}
		}
	case_end;

	case_ast_node(as, AssignStmt, node);
		if (as->op.kind != Token_Eq) {
			for (Ast *lhs : as->lhs) {
				escape_visit_exits(ea, lhs);
			}
			for (Ast *rhs : as->rhs) {
				escape_visit_exits(ea, rhs);
			}
			break;
		}
		if (as->lhs.count == as->rhs.count) {
			// every value is evaluated before any is stored, as in `a, b = b, a`
			auto values = array_make<EscapeValue>(temporary_allocator(), as->rhs.count);
			auto stored = array_make<bool>(temporary_allocator(), as->lhs.count);
			for_array(i, as->rhs) {
				Ast *lhs = unparen_expr(as->lhs[i]);
				stored[i] = !escape_type_is_plain(lhs->tav.type);
				if (lhs->kind == Ast_SelectorExpr && is_type_raw_union(type_deref(lhs->SelectorExpr.expr->tav.type))) {
					// a plain value stored into a raw union still overwrites its pointers
					stored[i] = true;
				}
				if (stored[i]) {
					values[i] = escape_convert(ea, escape_expr(ea, as->rhs[i]), as->rhs[i], lhs->tav.type);
				} else {
					escape_visit_exits(ea, as->rhs[i]);
				}
			}
			for_array(i, as->lhs) {
				if (stored[i]) {
					escape_store(ea, as->lhs[i], values[i]);
				}
			}
		} else {
			Array<EscapeValue> results = {};
			Ast *call = nullptr;
			if (as->rhs.count == 1) {
				call = escape_call_of(as->rhs[0]);
			}
			if (call != nullptr) {
				results = escape_call(ea, call);
			} else {
				for (Ast *rhs : as->rhs) {
					escape_visit_exits(ea, rhs);
				}
			}
			for_array(i, as->lhs) {
				EscapeValue v = escape_value();
				if (i < results.count) {
					v = results[i];
				}
				escape_store(ea, as->lhs[i], v);
			}
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
		escape_visit_exits(ea, is->cond);

		EscapeState other = escape_state_clone(ea->state);
		escape_stmt(ea, is->body);

		EscapeState then = ea->state;
		ea->state = other;
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
		isize result_count = 0;
		if (ea->pt->results != nullptr) {
			result_count = ea->pt->results->Tuple.variables.count;
		}
		auto values = array_make<EscapeValue>(temporary_allocator(), 0, result_count);

		if (rs->results.count != result_count) {
			// a bare return of named results, or the results of a single call
			Ast *call = nullptr;
			if (rs->results.count == 1) {
				call = escape_call_of(rs->results[0]);
			}
			if (call == nullptr) {
				for (Ast *expr : rs->results) {
					escape_visit_exits(ea, expr);
				}
				escape_exit(ea, node, {}, values);
				break;
			}

			Array<EscapeValue> results = escape_call(ea, call);
			for (isize i = 0; i < result_count; i++) {
				EscapeValue v = escape_value();
				if (i < results.count) {
					v = results[i];
				}
				array_add(&values, v);
			}
			escape_exit(ea, node, rs->results, values);
			break;
		}

		for_array(i, rs->results) {
			Ast *expr = rs->results[i];
			Entity *e = ea->pt->results->Tuple.variables[i];
			if (escape_type_is_plain(e->type)) {
				escape_visit_exits(ea, expr);
				array_add(&values, escape_value());
				continue;
			}
			EscapeValue v = escape_expr(ea, expr);
			array_add(&values, escape_convert(ea, v, expr, e->type));
		}

		escape_exit(ea, node, rs->results, values);
	case_end;

	case_ast_node(fs, ForStmt, node);
		escape_stmt(ea, fs->init);
		escape_loop(ea, node, fs->cond, fs->post, fs->body, nullptr, nullptr, nullptr);
		escape_forget(ea, fs->init);
	case_end;

	case_ast_node(rs, RangeStmt, node);
		Ast *val0 = nullptr;
		Ast *val1 = nullptr;
		if (rs->vals.count > 0) {
			val0 = rs->vals[0];
		}
		if (rs->vals.count > 1) {
			val1 = rs->vals[1];
		}
		escape_loop(ea, node, nullptr, nullptr, rs->body, val0, val1, rs->expr);
	case_end;

	case_ast_node(rs, UnrollRangeStmt, node);
		escape_loop(ea, node, nullptr, nullptr, rs->body, rs->val0, rs->val1, rs->expr);
	case_end;

	case_ast_node(ss, SwitchStmt, node);
		escape_stmt(ea, ss->init);
		escape_visit_exits(ea, ss->tag);
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


// The procedures are analysed in the strongly connected components of what they may call, callees first,
// and those calling each other until what flows through them settles, so what is found never depends on the threads

gb_internal i32  global_graph_scc(i32 node_count, Array<i32> const &offsets, Array<i32> const &targets, Array<i32> *comp_of_);
gb_internal void global_graph_csr(i32 node_count, Array<i32> const &edge_from, Array<i32> const &edge_to, Array<i32> *offsets, Array<i32> *targets);

struct EscapeGraph {
	Array<ProcInfo *>  procs;          // a procedure's index is kept on its decl, see `DeclInfo::escape_index`
	Array<i32>         offsets;        // procedure -> the procedures it may call, as `targets[offsets[v]..<offsets[v+1]]`
	Array<i32>         targets;
	Array<i32>         group_of;
	Array<i32>         group_offsets;  // group -> its procedures, as `members[group_offsets[gi]..<group_offsets[gi+1]]`
	Array<i32>         members;        // every group a group may call has a lower index
	Array<i32>         caller_offsets; // group -> the groups which may call it, as `callers[caller_offsets[gi]..<caller_offsets[gi+1]]`
	Array<i32>         callers;
	std::atomic<i32> * pending;        // per group the groups it may call which are not analysed yet
	std::atomic<i32> * cursors;        // per procedure while `targets` is filled
	bool               threaded;
};

gb_global EscapeGraph escape_graph;

gb_internal ErrorInstantiations escape_instantiations_of(ProcInfo *pi) {
	return {pi->generated_from_polymorphic ? pi : pi->poly_parent, nullptr};
}

// `reports` keeps what it reports rather than reporting it, when not null
gb_internal Slice<EscapeFlow> escape_analyse(EscapeGraph *g, i32 v, Array<EscapeReport> *reports) {
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
	ea.flows    = array_make<EscapeFlow>(temporary_allocator(), 0, 0);
	ea.graph    = g;
	ea.group    = g->group_of[v];
	ea.reports  = reports;

	if (ea.pt->variadic &&
	    !ea.pt->c_vararg &&
	    ea.pt->params != nullptr &&
	    ea.pt->variadic_index < ea.pt->params->Tuple.variables.count) {
		ea.variadic = ea.pt->params->Tuple.variables[ea.pt->variadic_index];
	}

	if (build_context.build_mode == BuildMode_Executable &&
	    !build_context.no_entry_point &&
	    build_context.command_kind != Command_test) {
		Entity *e = pi->decl->entity.load();
		ea.muted = e != nullptr && e == global_checker_ptr.load(std::memory_order_relaxed)->info.entry_point;
	}

	ErrorInstantiations prev_instantiations = global_error_context.instantiations;
	global_error_context.instantiations = escape_instantiations_of(pi);
	escape_stmt(&ea, body);
	if (ea.state.reachable) {
		escape_exit(&ea, body, {}, {});
	}
	global_error_context.instantiations = prev_instantiations;

	// the callers read it once this analysis and its temporary memory are gone
	auto flows = permanent_slice_make<EscapeFlow>(ea.flows.count);
	for_array(i, ea.flows) {
		flows[i] = ea.flows[i];
		flows[i].target_path = slice_clone(permanent_allocator(), ea.flows[i].target_path);
		flows[i].param_path  = slice_clone(permanent_allocator(), ea.flows[i].param_path);
	}
	return flows;
}

gb_internal bool escape_flows_eq(Slice<EscapeFlow> const &a, Slice<EscapeFlow> const &b) {
	if (a.count != b.count) {
		return false;
	}
	for (EscapeFlow const &f : a) {
		bool found = false;
		for (EscapeFlow const &g : b) {
			if (escape_flow_eq(f, g)) {
				found = true;
				break;
			}
		}
		if (!found) {
			return false;
		}
	}
	return true;
}

struct EscapeMemberTask {
	EscapeGraph *       graph;
	i32                 v;
	bool                stale;   // as the flows of one it calls changed
	Slice<EscapeFlow>   flows;
	Array<EscapeReport> reports; // of its latest analysis
	Array<i32>          callees; // the members of the group it calls, by their index
	Array<i32>          callers;
};

gb_internal WORKER_TASK_PROC(escape_member_worker) {
	EscapeMemberTask *t = cast(EscapeMemberTask *)data;
	array_clear(&t->reports);
	t->flows = escape_analyse(t->graph, t->v, &t->reports);
	return 0;
}

// each stale one is analysed with the flows the others had before, so the order they are analysed in does not matter
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
	if (escape_flows_eq(t.flows, d->escape_flows)) {
		return;
	}
	d->escape_flows = t.flows;
	for (i32 caller : t.callers) {
		tasks[caller].stale = true;
	}
}

gb_internal void escape_analyse_group(EscapeGraph *g, i32 gi) {
	enum : isize { MAX_ITERATION_COUNT = 16 };

	i32 start = g->group_offsets[gi];
	i32 end   = g->group_offsets[gi+1];

	i32 first = g->members[start];
	bool recursive = end - start > 1;
	for (i32 i = g->offsets[first]; i < g->offsets[first+1]; i++) {
		recursive |= g->targets[i] == first;
	}
	if (!recursive) {
		DeclInfo *d = g->procs[first]->decl;
		d->escape_flows = escape_analyse(g, first, nullptr);
		d->escapes_analysed.store(true);
		return;
	}

	auto tasks = slice_make<EscapeMemberTask>(heap_allocator(), end - start);
	defer (slice_free(&tasks, heap_allocator()));
	for (i32 k = start; k < end; k++) {
		EscapeMemberTask &t = tasks[k - start];
		t = {g, g->members[k]};
		t.stale = true;
		array_init(&t.reports, heap_allocator(), 0, 0);
		array_init(&t.callees, heap_allocator(), 0, 0);
		array_init(&t.callers, heap_allocator(), 0, 0);
	}
	for_array(k, tasks) {
		for (i32 i = g->offsets[tasks[k].v]; i < g->offsets[tasks[k].v+1]; i++) {
			for_array(j, tasks) {
				if (tasks[j].v == g->targets[i]) {
					array_add(&tasks[k].callees, cast(i32)j);
					array_add(&tasks[j].callers, cast(i32)k);
				}
			}
		}
	}

	// callees before their callers, unless they call each other
	auto order = array_make<i32>(heap_allocator(), 0, tasks.count);
	defer (array_free(&order));
	{
		struct Frame {
			i32   k;
			isize next;
		};
		auto frames  = array_make<Frame>(heap_allocator(), 0, tasks.count);
		auto visited = array_make<bool>(heap_allocator(), tasks.count);
		defer (array_free(&frames));
		defer (array_free(&visited));
		for (bool &v : visited) {
			v = false;
		}
		for_array(root, tasks) {
			if (visited[root]) {
				continue;
			}
			visited[root] = true;
			array_add(&frames, Frame{cast(i32)root, 0});
			while (frames.count > 0) {
				Frame &top = frames[frames.count-1];
				Array<i32> const &callees = tasks[top.k].callees;
				if (top.next < callees.count) {
					i32 callee = callees[top.next++];
					if (!visited[callee]) {
						visited[callee] = true;
						array_add(&frames, Frame{callee, 0});
					}
					continue;
				}
				array_add(&order, top.k);
				array_pop(&frames);
			}
		}
	}

	// what each may return or store depends on the others, so they start from nothing until that settles:
	// all at once at first, then one at a time with what the others have so far, only those calling one whose
	// flows changed, so the latest analysis of each was with what settled
	escape_analyse_members(g, tasks);
	for (EscapeMemberTask &t : tasks) {
		t.stale = false;
	}
	for_array(k, tasks) {
		escape_update_member(g, tasks, k);
	}

	bool settled = false;
	for (isize budget = MAX_ITERATION_COUNT*tasks.count; !settled && budget > 0; /**/) {
		settled = true;
		for (i32 k : order) {
			if (!tasks[k].stale) {
				continue;
			}
			settled = false;
			budget -= 1;
			tasks[k].stale = false;
			escape_member_worker(&tasks[k]);
			escape_update_member(g, tasks, k);
		}
	}
	if (!settled) {
		for (EscapeMemberTask &t : tasks) {
			t.stale = true;
		}
		escape_analyse_members(g, tasks);
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
		array_free(&t.callees);
		array_free(&t.callers);

		pi->decl->escape_flows = t.flows;
		pi->decl->escapes_analysed.store(true);
	}
}

gb_internal Slice<EscapeFlow> escape_flows_of(EscapeAnalysis *ea, Entity *e) {
	DeclInfo *d = e->decl_info;
	if (d == nullptr || d->proc_info == nullptr) {
		// foreign, or its body was not checked
		return {};
	}
	if (!d->escapes_analysed.load() && ea->graph->group_of[d->escape_index] != ea->group) {
		// not a call the checker recorded, which should not happen
		return {};
	}
	return d->escape_flows;
}

gb_internal bool escape_call_edge(CheckedCall const &call, i32 *caller, i32 *callee) {
	DeclInfo *d = call.callee->decl_info;
	if (call.caller->proc_info == nullptr || d == nullptr || d->proc_info == nullptr) {
		// e.g. in a body which failed to check, or to a foreign procedure
		return false;
	}
	*caller = call.caller->escape_index;
	*callee = d->escape_index;
	return true;
}

gb_internal void escape_graph_count_calls(CheckedCall *calls, isize count) {
	EscapeGraph *g = &escape_graph;
	for (isize i = 0; i < count; i++) {
		i32 caller = 0;
		i32 callee = 0;
		if (escape_call_edge(calls[i], &caller, &callee)) {
			g->cursors[caller].fetch_add(1, std::memory_order_relaxed);
		}
	}
}

gb_internal void escape_graph_place_calls(CheckedCall *calls, isize count) {
	EscapeGraph *g = &escape_graph;
	for (isize i = 0; i < count; i++) {
		i32 caller = 0;
		i32 callee = 0;
		if (escape_call_edge(calls[i], &caller, &callee)) {
			g->targets[g->cursors[caller].fetch_add(1, std::memory_order_relaxed)] = callee;
		}
	}
}

gb_internal WORKER_TASK_PROC(escape_group_worker) {
	EscapeGraph *g = &escape_graph;
	i32 gi = cast(i32)cast(intptr)data;
	for (;;) {
		escape_analyse_group(g, gi);

		// carries on with one of the groups this releases, rather than queueing every one of them
		bool carry_on = false;
		i32 next_gi = 0;
		for (i32 i = g->caller_offsets[gi]; i < g->caller_offsets[gi+1]; i++) {
			i32 next = g->callers[i];
			if (g->pending[next].fetch_sub(1) != 1) {
				continue;
			}
			if (carry_on) {
				thread_pool_add_task(escape_group_worker, cast(void *)cast(intptr)next);
			} else {
				carry_on = true;
				next_gi = next;
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
	EscapeGraph *g = &escape_graph;
	defer ({
		array_free(&g->procs);
		array_free(&g->offsets);
		array_free(&g->targets);
		array_free(&g->group_of);
		array_free(&g->group_offsets);
		array_free(&g->members);
		array_free(&g->caller_offsets);
		array_free(&g->callers);
		gb_free(heap_allocator(), g->pending);
		g->pending = nullptr;
	});
	array_init(&g->procs, heap_allocator());
	per_thread_array_gather(&c->info.checked_bodies_queue, &g->procs);
	i32 count = cast(i32)g->procs.count;
	if (count == 0) {
		return;
	}
	for (i32 v = 0; v < count; v++) {
		g->procs[v]->decl->escape_index = v;
	}

	g->threaded = !build_context.no_threaded_checker && build_context.thread_count > 1;

	{
		auto calls = array_make<CheckedCall>(heap_allocator());
		defer (array_free(&calls));
		per_thread_array_gather(&c->info.checked_calls_queue, &calls);

		// the calls of each procedure are counted, and then placed after those of the procedures before it
		g->cursors = gb_alloc_array(heap_allocator(), std::atomic<i32>, count);
		defer (gb_free(heap_allocator(), g->cursors));
		for (i32 v = 0; v < count; v++) {
			g->cursors[v].store(0, std::memory_order_relaxed);
		}
		if (g->threaded) {
			thread_pool_for_chunks(calls.data, calls.count, 4096, escape_graph_count_calls);
		} else {
			escape_graph_count_calls(calls.data, calls.count);
		}

		array_init(&g->offsets, heap_allocator(), count+1);
		g->offsets[0] = 0;
		for (i32 v = 0; v < count; v++) {
			g->offsets[v+1] = g->offsets[v] + g->cursors[v].load(std::memory_order_relaxed);
			g->cursors[v].store(g->offsets[v], std::memory_order_relaxed);
		}

		array_init(&g->targets, heap_allocator(), g->offsets[count]);
		if (g->threaded) {
			thread_pool_for_chunks(calls.data, calls.count, 4096, escape_graph_place_calls);
		} else {
			escape_graph_place_calls(calls.data, calls.count);
		}
	}

	array_init(&g->group_of, heap_allocator(), count);
	i32 group_count = global_graph_scc(count, g->offsets, g->targets, &g->group_of);
	{
		auto procs = array_make<i32>(heap_allocator(), count);
		defer (array_free(&procs));
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

	{
		auto edge_from = array_make<i32>(heap_allocator(), 0, group_count);
		auto edge_to   = array_make<i32>(heap_allocator(), 0, group_count);
		auto seen      = array_make<i32>(heap_allocator(), group_count);
		defer (array_free(&edge_from));
		defer (array_free(&edge_to));
		defer (array_free(&seen));

		g->pending = gb_alloc_array(heap_allocator(), std::atomic<i32>, group_count);
		for (i32 gi = 0; gi < group_count; gi++) {
			seen[gi] = -1;
			g->pending[gi].store(0);
		}
		for (i32 gi = 0; gi < group_count; gi++) {
			for (i32 k = g->group_offsets[gi]; k < g->group_offsets[gi+1]; k++) {
				i32 v = g->members[k];
				for (i32 i = g->offsets[v]; i < g->offsets[v+1]; i++) {
					i32 callee = g->group_of[g->targets[i]];
					if (callee != gi && seen[callee] != gi) {
						seen[callee] = gi;
						array_add(&edge_from, callee);
						array_add(&edge_to, gi);
						g->pending[gi].fetch_add(1);
					}
				}
			}
		}
		global_graph_csr(group_count, edge_from, edge_to, &g->caller_offsets, &g->callers);
	}

	// all found before any is analysed, as analysing one releases others
	auto ready = array_make<i32>(heap_allocator(), 0, group_count);
	defer (array_free(&ready));
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
