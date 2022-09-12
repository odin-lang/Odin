#include "entity.cpp"
#include "types.cpp"

void check_expr(CheckerContext *c, Operand *operand, Ast *expression);
void check_expr_or_type(CheckerContext *c, Operand *operand, Ast *expression, Type *type_hint=nullptr);
void add_comparison_procedures_for_fields(CheckerContext *c, Type *t);
Type *check_type(CheckerContext *ctx, Ast *e);

bool is_operand_value(Operand o) {
	switch (o.mode) {
	case Addressing_Value:
	case Addressing_Context:
	case Addressing_Variable:
	case Addressing_Constant:
	case Addressing_MapIndex:
	case Addressing_OptionalOk:
	case Addressing_OptionalOkPtr:
	case Addressing_SoaVariable:
	case Addressing_SwizzleValue:
	case Addressing_SwizzleVariable:
		return true;
	}
	return false;
}
bool is_operand_nil(Operand o) {
	return o.mode == Addressing_Value && o.type == t_untyped_nil;
}
bool is_operand_undef(Operand o) {
	return o.mode == Addressing_Value && o.type == t_untyped_undef;
}

bool check_rtti_type_disallowed(Token const &token, Type *type, char const *format) {
	if (build_context.disallow_rtti && type) {
		if (is_type_any(type)) {
			gbString t = type_to_string(type);
			error(token, format, t);
			gb_string_free(t);
			return true;
		}
	}
	return false;
}

bool check_rtti_type_disallowed(Ast *expr, Type *type, char const *format) {
	GB_ASSERT(expr != nullptr);
	return check_rtti_type_disallowed(ast_token(expr), type, format);
}

void scope_reset(Scope *scope) {
	if (scope == nullptr) return;

	scope->head_child.store(nullptr, std::memory_order_relaxed);
	string_map_clear(&scope->elements);
	ptr_set_clear(&scope->imported);
}

void scope_reserve(Scope *scope, isize capacity) {
	isize cap = 2*capacity;
	if (cap > scope->elements.hashes.count) {
		string_map_rehash(&scope->elements, capacity);
	}
}

i32 is_scope_an_ancestor(Scope *parent, Scope *child) {
	i32 i = 0;
	while (child != nullptr) {
		if (parent == child) {
			return i;
		}
		child = child->parent;
		i++;
	}
	return -1;
}

void entity_graph_node_set_destroy(EntityGraphNodeSet *s) {
	if (s->hashes.data != nullptr) {
		ptr_set_destroy(s);
	}
}

void entity_graph_node_set_add(EntityGraphNodeSet *s, EntityGraphNode *n) {
	if (s->hashes.data == nullptr) {
		ptr_set_init(s, heap_allocator());
	}
	ptr_set_add(s, n);
}

bool entity_graph_node_set_exists(EntityGraphNodeSet *s, EntityGraphNode *n) {
	return ptr_set_exists(s, n);
}

void entity_graph_node_set_remove(EntityGraphNodeSet *s, EntityGraphNode *n) {
	ptr_set_remove(s, n);
}

void entity_graph_node_destroy(EntityGraphNode *n, gbAllocator a) {
	entity_graph_node_set_destroy(&n->pred);
	entity_graph_node_set_destroy(&n->succ);
	gb_free(a, n);
}


int entity_graph_node_cmp(EntityGraphNode **data, isize i, isize j) {
	EntityGraphNode *x = data[i];
	EntityGraphNode *y = data[j];
	u64 a = x->entity->order_in_src;
	u64 b = y->entity->order_in_src;
	if (x->dep_count < y->dep_count) {
		return -1;
	}
	if (x->dep_count == y->dep_count) {
		return a < b ? -1 : b > a;
	}
	return +1;
}

void entity_graph_node_swap(EntityGraphNode **data, isize i, isize j) {
	EntityGraphNode *x = data[i];
	EntityGraphNode *y = data[j];
	data[i] = y;
	data[j] = x;
	x->index = j;
	y->index = i;
}



void import_graph_node_set_destroy(ImportGraphNodeSet *s) {
	if (s->hashes.data != nullptr) {
		ptr_set_destroy(s);
	}
}

void import_graph_node_set_add(ImportGraphNodeSet *s, ImportGraphNode *n) {
	if (s->hashes.data == nullptr) {
		ptr_set_init(s, heap_allocator());
	}
	ptr_set_add(s, n);
}

bool import_graph_node_set_exists(ImportGraphNodeSet *s, ImportGraphNode *n) {
	return ptr_set_exists(s, n);
}

void import_graph_node_set_remove(ImportGraphNodeSet *s, ImportGraphNode *n) {
	ptr_set_remove(s, n);
}

ImportGraphNode *import_graph_node_create(gbAllocator a, AstPackage *pkg) {
	ImportGraphNode *n = gb_alloc_item(a, ImportGraphNode);
	n->pkg = pkg;
	n->scope = pkg->scope;
	return n;
}

void import_graph_node_destroy(ImportGraphNode *n, gbAllocator a) {
	import_graph_node_set_destroy(&n->pred);
	import_graph_node_set_destroy(&n->succ);
	gb_free(a, n);
}


int import_graph_node_cmp(ImportGraphNode **data, isize i, isize j) {
	ImportGraphNode *x = data[i];
	ImportGraphNode *y = data[j];
	GB_ASSERT(x != y);

	GB_ASSERT(x->scope != y->scope);

	bool xg = (x->scope->flags&ScopeFlag_Global) != 0;
	bool yg = (y->scope->flags&ScopeFlag_Global) != 0;
	if (xg != yg) return xg ? -1 : +1;
	if (xg && yg) return x->pkg->id < y->pkg->id ? +1 : -1;
	if (x->dep_count < y->dep_count) return -1;
	if (x->dep_count > y->dep_count) return +1;
	return 0;
}

void import_graph_node_swap(ImportGraphNode **data, isize i, isize j) {
	ImportGraphNode *x = data[i];
	ImportGraphNode *y = data[j];
	data[i] = y;
	data[j] = x;
	x->index = j;
	y->index = i;
}

GB_COMPARE_PROC(ast_node_cmp) {
	Ast *x = *cast(Ast **)a;
	Ast *y = *cast(Ast **)b;
	Token i = ast_token(x);
	Token j = ast_token(y);
	return token_pos_cmp(i.pos, j.pos);
}






void init_decl_info(DeclInfo *d, Scope *scope, DeclInfo *parent) {
	d->parent = parent;
	d->scope  = scope;
	ptr_set_init(&d->deps,           heap_allocator());
	ptr_set_init(&d->type_info_deps, heap_allocator());
	array_init  (&d->labels,         heap_allocator());
}

DeclInfo *make_decl_info(Scope *scope, DeclInfo *parent) {
	DeclInfo *d = gb_alloc_item(permanent_allocator(), DeclInfo);
	init_decl_info(d, scope, parent);
	return d;
}

void destroy_declaration_info(DeclInfo *d) {
	ptr_set_destroy(&d->deps);
	array_free(&d->labels);
}

bool decl_info_has_init(DeclInfo *d) {
	if (d->init_expr != nullptr) {
		return true;
	}
	if (d->proc_lit != nullptr) {
		switch (d->proc_lit->kind) {
		case_ast_node(pl, ProcLit, d->proc_lit);
			if (pl->body != nullptr) {
				return true;
			}
		case_end;
		}
	}

	return false;
}





Scope *create_scope(CheckerInfo *info, Scope *parent, isize init_elements_capacity=DEFAULT_SCOPE_CAPACITY) {
	Scope *s = gb_alloc_item(permanent_allocator(), Scope);
	s->parent = parent;
	string_map_init(&s->elements, heap_allocator(), init_elements_capacity);
	ptr_set_init(&s->imported, heap_allocator(), 0);
	mutex_init(&s->mutex);

	if (parent != nullptr && parent != builtin_pkg->scope) {
		Scope *prev_head_child = parent->head_child.exchange(s, std::memory_order_acq_rel);
		if (prev_head_child) {
			prev_head_child->next.store(s, std::memory_order_release);
		}
	}

	if (parent != nullptr && parent->flags & ScopeFlag_ContextDefined) {
		s->flags |= ScopeFlag_ContextDefined;
	}

	return s;
}

Scope *create_scope_from_file(CheckerInfo *info, AstFile *f) {
	GB_ASSERT(f != nullptr);
	GB_ASSERT(f->pkg != nullptr);
	GB_ASSERT(f->pkg->scope != nullptr);

	isize init_elements_capacity = gb_max(DEFAULT_SCOPE_CAPACITY, 2*f->total_file_decl_count);
	Scope *s = create_scope(info, f->pkg->scope, init_elements_capacity);


	s->flags |= ScopeFlag_File;
	s->file = f;
	f->scope = s;

	return s;
}

Scope *create_scope_from_package(CheckerContext *c, AstPackage *pkg) {
	GB_ASSERT(pkg != nullptr);

	isize total_pkg_decl_count = 0;
	for_array(j, pkg->files) {
		total_pkg_decl_count += pkg->files.data[j]->total_file_decl_count;
	}

	isize init_elements_capacity = gb_max(DEFAULT_SCOPE_CAPACITY, 2*total_pkg_decl_count);
	Scope *s = create_scope(c->info, builtin_pkg->scope, init_elements_capacity);

	s->flags |= ScopeFlag_Pkg;
	s->pkg = pkg;
	pkg->scope = s;

	if (pkg->fullpath == c->checker->parser->init_fullpath || pkg->kind == Package_Init) {
		s->flags |= ScopeFlag_Init;
	}

	if (pkg->kind == Package_Runtime) {
		s->flags |= ScopeFlag_Global;
	}

	if (s->flags & (ScopeFlag_Init|ScopeFlag_Global)) {
		s->flags |= ScopeFlag_HasBeenImported;
	}
	s->flags |= ScopeFlag_ContextDefined;

	return s;
}

void destroy_scope(Scope *scope) {
	for_array(i, scope->elements.entries) {
		Entity *e =scope->elements.entries[i].value;
		if (e->kind == Entity_Variable) {
			if (!(e->flags & EntityFlag_Used)) {
#if 0
				warning(e->token, "Unused variable '%.*s'", LIT(e->token.string));
#endif
			}
		}
	}

	for (Scope *child = scope->head_child; child != nullptr; child = child->next) {
		destroy_scope(child);
	}

	string_map_destroy(&scope->elements);
	ptr_set_destroy(&scope->imported);
	mutex_destroy(&scope->mutex);

	// NOTE(bill): No need to free scope as it "should" be allocated in an arena (except for the global scope)
}


void add_scope(CheckerContext *c, Ast *node, Scope *scope) {
	GB_ASSERT(node != nullptr);
	GB_ASSERT(scope != nullptr);
	scope->node = node;
	switch (node->kind) {
	case Ast_BlockStmt:       node->BlockStmt.scope       = scope; break;
	case Ast_IfStmt:          node->IfStmt.scope          = scope; break;
	case Ast_ForStmt:         node->ForStmt.scope         = scope; break;
	case Ast_RangeStmt:       node->RangeStmt.scope       = scope; break;
	case Ast_UnrollRangeStmt: node->UnrollRangeStmt.scope = scope; break;
	case Ast_CaseClause:      node->CaseClause.scope      = scope; break;
	case Ast_SwitchStmt:      node->SwitchStmt.scope      = scope; break;
	case Ast_TypeSwitchStmt:  node->TypeSwitchStmt.scope  = scope; break;
	case Ast_ProcType:        node->ProcType.scope        = scope; break;
	case Ast_StructType:      node->StructType.scope      = scope; break;
	case Ast_UnionType:       node->UnionType.scope       = scope; break;
	case Ast_EnumType:        node->EnumType.scope        = scope; break;
	default: GB_PANIC("Invalid node for add_scope: %.*s", LIT(ast_strings[node->kind]));
	}
}

Scope *scope_of_node(Ast *node) {
	if (node == nullptr) {
		return nullptr;
	}
	switch (node->kind) {
	case Ast_BlockStmt:       return node->BlockStmt.scope;
	case Ast_IfStmt:          return node->IfStmt.scope;
	case Ast_ForStmt:         return node->ForStmt.scope;
	case Ast_RangeStmt:       return node->RangeStmt.scope;
	case Ast_UnrollRangeStmt: return node->UnrollRangeStmt.scope;
	case Ast_CaseClause:      return node->CaseClause.scope;
	case Ast_SwitchStmt:      return node->SwitchStmt.scope;
	case Ast_TypeSwitchStmt:  return node->TypeSwitchStmt.scope;
	case Ast_ProcType:        return node->ProcType.scope;
	case Ast_StructType:      return node->StructType.scope;
	case Ast_UnionType:       return node->UnionType.scope;
	case Ast_EnumType:        return node->EnumType.scope;
	}
	GB_PANIC("Invalid node for add_scope: %.*s", LIT(ast_strings[node->kind]));
	return nullptr;
}


void check_open_scope(CheckerContext *c, Ast *node) {
	node = unparen_expr(node);
	GB_ASSERT(node->kind == Ast_Invalid ||
	          is_ast_stmt(node) ||
	          is_ast_type(node));
	Scope *scope = create_scope(c->info, c->scope);
	add_scope(c, node, scope);
	switch (node->kind) {
	case Ast_ProcType:
		scope->flags |= ScopeFlag_Proc;
		break;
	case Ast_StructType:
	case Ast_EnumType:
	case Ast_UnionType:
	case Ast_BitSetType:
		scope->flags |= ScopeFlag_Type;
		break;
	}
	c->scope = scope;
	c->state_flags |= StateFlag_bounds_check;
}

void check_close_scope(CheckerContext *c) {
	c->scope = c->scope->parent;
}


Entity *scope_lookup_current(Scope *s, String const &name) {
	Entity **found = string_map_get(&s->elements, name);
	if (found) {
		return *found;
	}
	return nullptr;
}

void scope_lookup_parent(Scope *scope, String const &name, Scope **scope_, Entity **entity_) {
	if (scope != nullptr) {
		bool gone_thru_proc = false;
		bool gone_thru_package = false;
		StringHashKey key = string_hash_string(name);
		for (Scope *s = scope; s != nullptr; s = s->parent) {
			Entity **found = nullptr;
			mutex_lock(&s->mutex);
			found = string_map_get(&s->elements, key);
			mutex_unlock(&s->mutex);
			if (found) {
				Entity *e = *found;
				if (gone_thru_proc) {
					// IMPORTANT TODO(bill): Is this correct?!
					if (e->kind == Entity_Label) {
						continue;
					}
					if (e->kind == Entity_Variable) {
						if (e->scope->flags&ScopeFlag_File) {
							// Global variables are file to access
						} else if (e->flags&EntityFlag_Static) {
							// Allow static/thread_local variables to be referenced
						} else {
							continue;
						}
					}
				}

				if (entity_) *entity_ = e;
				if (scope_) *scope_ = s;
				return;
			}

			if (s->flags&ScopeFlag_Proc) {
				gone_thru_proc = true;
			}
			if (s->flags&ScopeFlag_Pkg) {
				gone_thru_package = true;
			}
		}
	}
	if (entity_) *entity_ = nullptr;
	if (scope_) *scope_ = nullptr;
}

Entity *scope_lookup(Scope *s, String const &name) {
	Entity *entity = nullptr;
	scope_lookup_parent(s, name, nullptr, &entity);
	return entity;
}



Entity *scope_insert_with_name(Scope *s, String const &name, Entity *entity, bool use_mutex=true) {
	if (name == "") {
		return nullptr;
	}
	StringHashKey key = string_hash_string(name);
	Entity **found = nullptr;
	Entity *result = nullptr;

	if (use_mutex) mutex_lock(&s->mutex);
	defer (if (use_mutex) mutex_unlock(&s->mutex));
	
	found = string_map_get(&s->elements, key);

	if (found) {
		if (entity != *found) {
			result = *found;
		}
		goto end;
	}
	if (s->parent != nullptr && (s->parent->flags & ScopeFlag_Proc) != 0) {
		found = string_map_get(&s->parent->elements, key);
		if (found) {
			if ((*found)->flags & EntityFlag_Result) {
				if (entity != *found) {
					result = *found;
				}
				goto end;
			}
		}
	}

	string_map_set(&s->elements, key, entity);
	if (entity->scope == nullptr) {
		entity->scope = s;
	}
end:;
	return result;
}

Entity *scope_insert(Scope *s, Entity *entity, bool use_mutex) {
	String name = entity->token.string;
	return scope_insert_with_name(s, name, entity, use_mutex);
}


GB_COMPARE_PROC(entity_variable_pos_cmp) {
	Entity *x = *cast(Entity **)a;
	Entity *y = *cast(Entity **)b;

	return token_pos_cmp(x->token.pos, y->token.pos);
}


enum VettedEntityKind {
	VettedEntity_Invalid,

	VettedEntity_Unused,
	VettedEntity_Shadowed,
	VettedEntity_Shadowed_And_Unused,
};
struct VettedEntity {
	VettedEntityKind kind;
	Entity *entity;
	Entity *other;
};
void init_vetted_entity(VettedEntity *ve, VettedEntityKind kind, Entity *entity, Entity *other=nullptr)  {
	ve->kind = kind;
	ve->entity = entity;
	ve->other = other;
}


GB_COMPARE_PROC(vetted_entity_variable_pos_cmp) {
	Entity *x = (cast(VettedEntity *)a)->entity;
	Entity *y = (cast(VettedEntity *)b)->entity;
	GB_ASSERT(x != nullptr);
	GB_ASSERT(y != nullptr);

	return token_pos_cmp(x->token.pos, y->token.pos);
}

bool check_vet_shadowing_assignment(Checker *c, Entity *shadowed, Ast *expr) {
	Ast *init = unparen_expr(expr);
	if (init == nullptr) {
		return false;
	}
	if (init->kind == Ast_Ident) {
		// TODO(bill): Which logic is better? Same name or same entity
		// bool ignore = init->Ident.token.string == name;
		bool ignore = init->Ident.entity == shadowed;
		if (ignore) {
			return true;
		}
	} else if (init->kind == Ast_TernaryIfExpr) {
		bool x = check_vet_shadowing_assignment(c, shadowed, init->TernaryIfExpr.x);
		bool y = check_vet_shadowing_assignment(c, shadowed, init->TernaryIfExpr.y);
		if (x || y) {
			return true;
		}
	}

	return false;
}


bool check_vet_shadowing(Checker *c, Entity *e, VettedEntity *ve) {
	if (e->kind != Entity_Variable) {
		return false;
	}
	String name = e->token.string;
	if (name == "_") {
		return false;
	}
	if (e->flags & EntityFlag_Param) {
		return false;
	}

	if (e->scope->flags & (ScopeFlag_Global|ScopeFlag_File|ScopeFlag_Proc)) {
		return false;
	}

	Scope *parent = e->scope->parent;
	if (parent->flags & (ScopeFlag_Global|ScopeFlag_File)) {
		return false;
	}

	Entity *shadowed = scope_lookup(parent, name);
	if (shadowed == nullptr) {
		return false;
	}
	if (shadowed->kind != Entity_Variable) {
		return false;
	}

	if (shadowed->scope->flags & (ScopeFlag_Global|ScopeFlag_File)) {
		// return false;
	}

	// NOTE(bill): The entities must be in the same file
	if (e->token.pos.file_id != shadowed->token.pos.file_id) {
		return false;
	}
	// NOTE(bill): The shaded identifier must appear before this one to be an
	// instance of shadowing
	if (token_pos_cmp(shadowed->token.pos, e->token.pos) > 0) {
		return false;
	}
	// NOTE(bill): If the types differ, don't complain
	if (!are_types_identical(e->type, shadowed->type)) {
		return false;
	}

	// NOTE(bill): Ignore intentional redeclaration
	// x := x
	// Suggested in issue #637 (2020-05-11)
	// Also allow the following
	// x := x if cond else y
	// x := z if cond else x
	if ((e->flags & EntityFlag_Using) == 0 && e->kind == Entity_Variable) {
		if (check_vet_shadowing_assignment(c, shadowed, e->Variable.init_expr)) {
			return false;
		}
	}

	zero_item(ve);
	ve->kind = VettedEntity_Shadowed;
	ve->entity = e;
	ve->other = shadowed;
	return true;
}

bool check_vet_unused(Checker *c, Entity *e, VettedEntity *ve) {
	if ((e->flags&EntityFlag_Used) == 0) {
		switch (e->kind) {
		case Entity_Variable:
			if (e->scope->flags & (ScopeFlag_Global|ScopeFlag_Type|ScopeFlag_File)) {
				return false;
			}
		case Entity_ImportName:
		case Entity_LibraryName:
			zero_item(ve);
			ve->kind = VettedEntity_Unused;
			ve->entity = e;
			return true;
		}
	}
	return false;
}

void check_scope_usage(Checker *c, Scope *scope) {
	bool vet_unused = true;
	bool vet_shadowing = true;

	Array<VettedEntity> vetted_entities = {};
	array_init(&vetted_entities, heap_allocator());

	MUTEX_GUARD_BLOCK(scope->mutex) for_array(i, scope->elements.entries) {
		Entity *e = scope->elements.entries[i].value;
		if (e == nullptr) continue;
		VettedEntity ve_unused = {};
		VettedEntity ve_shadowed = {};
		bool is_unused = vet_unused && check_vet_unused(c, e, &ve_unused);
		bool is_shadowed = vet_shadowing && check_vet_shadowing(c, e, &ve_shadowed);
		if (is_unused && is_shadowed) {
			VettedEntity ve_both = ve_shadowed;
			ve_both.kind = VettedEntity_Shadowed_And_Unused;
			array_add(&vetted_entities, ve_both);
		} else if (is_unused) {
			array_add(&vetted_entities, ve_unused);
		} else if (is_shadowed) {
			array_add(&vetted_entities, ve_shadowed);
		}
	}

	gb_sort(vetted_entities.data, vetted_entities.count, gb_size_of(VettedEntity), vetted_entity_variable_pos_cmp);

	for_array(i, vetted_entities) {
		auto ve = vetted_entities[i];
		Entity *e = ve.entity;
		Entity *other = ve.other;
		String name = e->token.string;

		if (ve.kind == VettedEntity_Shadowed_And_Unused) {
			error(e->token, "'%.*s' declared but not used, possibly shadows declaration at line %d", LIT(name), other->token.pos.line);
		} else if (build_context.vet) {
			switch (ve.kind) {
			case VettedEntity_Unused:
				error(e->token, "'%.*s' declared but not used", LIT(name));
				break;
			case VettedEntity_Shadowed:
				if (e->flags&EntityFlag_Using) {
					error(e->token, "Declaration of '%.*s' from 'using' shadows declaration at line %d", LIT(name), other->token.pos.line);
				} else {
					error(e->token, "Declaration of '%.*s' shadows declaration at line %d", LIT(name), other->token.pos.line);
				}
				break;
			default:
				break;
			}
		}

		if (e->kind == Entity_Variable && (e->flags & (EntityFlag_Param|EntityFlag_Using)) == 0) {
			i64 sz = type_size_of(e->type);
			// TODO(bill): When is a good size warn?
			// Is 128 KiB good enough?
			if (sz >= 1ll<<17) {
				gbString type_str = type_to_string(e->type);
				warning(e->token, "Declaration of '%.*s' may cause a stack overflow due to its type '%s' having a size of %lld bytes", LIT(name), type_str, cast(long long)sz);
				gb_string_free(type_str);
			}
		}
	}

	array_free(&vetted_entities);

	for (Scope *child = scope->head_child; child != nullptr; child = child->next) {
		if (child->flags & (ScopeFlag_Proc|ScopeFlag_Type|ScopeFlag_File)) {
			// Ignore these
		} else {
			check_scope_usage(c, child);
		}
	}
}


void add_dependency(CheckerInfo *info, DeclInfo *d, Entity *e) {
	mutex_lock(&info->deps_mutex);
	ptr_set_add(&d->deps, e);
	mutex_unlock(&info->deps_mutex);
}
void add_type_info_dependency(CheckerInfo *info, DeclInfo *d, Type *type, bool require_mutex) {
	if (d == nullptr) {
		return;
	}
	if (require_mutex) {
		mutex_lock(&info->deps_mutex);
	}
	ptr_set_add(&d->type_info_deps, type);
	if (require_mutex) {
		mutex_unlock(&info->deps_mutex);
	}
}

AstPackage *get_core_package(CheckerInfo *info, String name) {
	gbAllocator a = heap_allocator();
	String path = get_fullpath_core(a, name);
	defer (gb_free(a, path.text));
	auto found = string_map_get(&info->packages, path);
	if (found == nullptr) {
		gb_printf_err("Name: %.*s\n", LIT(name));
		gb_printf_err("Fullpath: %.*s\n", LIT(path));
		
		for_array(i, info->packages.entries) {
			auto *entry = &info->packages.entries[i];
			gb_printf_err("%.*s\n", LIT(entry->key.string));
		}
		GB_ASSERT_MSG(found != nullptr, "Missing core package %.*s", LIT(name));
	}
	return *found;
}


void add_package_dependency(CheckerContext *c, char const *package_name, char const *name) {
	String n = make_string_c(name);
	AstPackage *p = get_core_package(&c->checker->info, make_string_c(package_name));
	Entity *e = scope_lookup(p->scope, n);
	GB_ASSERT_MSG(e != nullptr, "%s", name);
	GB_ASSERT(c->decl != nullptr);
	e->flags |= EntityFlag_Used;
	add_dependency(c->info, c->decl, e);
}

void try_to_add_package_dependency(CheckerContext *c, char const *package_name, char const *name) {
	String n = make_string_c(name);
	AstPackage *p = get_core_package(&c->checker->info, make_string_c(package_name));
	Entity *e = scope_lookup(p->scope, n);
	if (e == nullptr) {
		return;
	}
	GB_ASSERT(c->decl != nullptr);
	e->flags |= EntityFlag_Used;
	add_dependency(c->info, c->decl, e);
}


void add_declaration_dependency(CheckerContext *c, Entity *e) {
	if (e == nullptr) {
		return;
	}
	if (c->decl != nullptr) {
		add_dependency(c->info, c->decl, e);
	}
}


Entity *add_global_entity(Entity *entity, Scope *scope=builtin_pkg->scope) {
	String name = entity->token.string;
	defer (entity->state = EntityState_Resolved);

	if (gb_memchr(name.text, ' ', name.len)) {
		return entity; // NOTE(bill): Usually an 'untyped thing'
	}
	if (scope_insert(scope, entity)) {
		compiler_error("double declaration");
	}
	return entity;
}

void add_global_constant(char const *name, Type *type, ExactValue value) {
	Entity *entity = alloc_entity(Entity_Constant, nullptr, make_token_ident(name), type);
	entity->Constant.value = value;
	add_global_entity(entity);
}


void add_global_string_constant(char const *name, String const &value) {
	add_global_constant(name, t_untyped_string, exact_value_string(value));
}

void add_global_bool_constant(char const *name, bool value) {
	add_global_constant(name, t_untyped_bool, exact_value_bool(value));
}

void add_global_type_entity(String name, Type *type) {
	add_global_entity(alloc_entity_type_name(nullptr, make_token_ident(name), type));
}


AstPackage *create_builtin_package(char const *name) {
	gbAllocator a = permanent_allocator();
	AstPackage *pkg = gb_alloc_item(a, AstPackage);
	pkg->name = make_string_c(name);
	pkg->kind = Package_Normal;

	pkg->scope = create_scope(nullptr, nullptr);
	pkg->scope->flags |= ScopeFlag_Pkg | ScopeFlag_Global | ScopeFlag_Builtin;
	pkg->scope->pkg = pkg;
	return pkg;
}

struct GlobalEnumValue {
	char const *name;
	i64 value;
};

Slice<Entity *> add_global_enum_type(String const &type_name, GlobalEnumValue *values, isize value_count, Type **enum_type_ = nullptr) {
	Scope *scope = create_scope(nullptr, builtin_pkg->scope);
	Entity *entity = alloc_entity_type_name(scope, make_token_ident(type_name), nullptr, EntityState_Resolved);

	Type *enum_type = alloc_type_enum();
	Type *named_type = alloc_type_named(type_name, enum_type, entity);
	set_base_type(named_type, enum_type);
	enum_type->Enum.base_type = t_int;
	enum_type->Enum.scope = scope;
	entity->type = named_type;

	auto fields = array_make<Entity *>(permanent_allocator(), value_count);
	for (isize i = 0; i < value_count; i++) {
		i64 value = values[i].value;
		Entity *e = alloc_entity_constant(scope, make_token_ident(values[i].name), named_type, exact_value_i64(value));
		e->flags |= EntityFlag_Visited;
		e->state = EntityState_Resolved;
		fields[i] = e;

		Entity *ie = scope_insert(scope, e);
		GB_ASSERT(ie == nullptr);
	}


	enum_type->Enum.fields = fields;
	enum_type->Enum.min_value_index = 0;
	enum_type->Enum.max_value_index = value_count-1;
	enum_type->Enum.min_value = &enum_type->Enum.fields[enum_type->Enum.min_value_index]->Constant.value;
	enum_type->Enum.max_value = &enum_type->Enum.fields[enum_type->Enum.max_value_index]->Constant.value;


	if (enum_type_) *enum_type_ = named_type;

	return slice_from_array(fields);
}
void add_global_enum_constant(Slice<Entity *> const &fields, char const *name, i64 value) {
	for (Entity *field : fields) {
		GB_ASSERT(field->kind == Entity_Constant);
		if (value == exact_value_to_i64(field->Constant.value)) {
			add_global_constant(name, field->type, field->Constant.value);
			return;
		}
	}
	GB_PANIC("Unfound enum value for global constant: %s %lld", name, cast(long long)value);
}

Type *add_global_type_name(Scope *scope, String const &type_name, Type *backing_type) {
	Entity *e = alloc_entity_type_name(scope, make_token_ident(type_name), nullptr, EntityState_Resolved);
	Type *named_type = alloc_type_named(type_name, backing_type, e);
	e->type = named_type;
	set_base_type(named_type, backing_type);
	if (scope_insert(scope, e)) {
		compiler_error("double declaration of %.*s", LIT(e->token.string));
	}
	return named_type;
}


void init_universal(void) {
	BuildContext *bc = &build_context;

	builtin_pkg    = create_builtin_package("builtin");
	intrinsics_pkg = create_builtin_package("intrinsics");
	config_pkg     = create_builtin_package("config");

// Types
	for (isize i = 0; i < gb_count_of(basic_types); i++) {
		String const &name = basic_types[i].Basic.name;
		add_global_type_entity(name, &basic_types[i]);
	}
	add_global_type_entity(str_lit("byte"), &basic_types[Basic_u8]);

	{
		Type *equal_args[2] = {t_rawptr, t_rawptr};
		t_equal_proc = alloc_type_proc_from_types(equal_args, 2, t_bool, false, ProcCC_Contextless);

		Type *hasher_args[2] = {t_rawptr, t_uintptr};
		t_hasher_proc = alloc_type_proc_from_types(hasher_args, 2, t_uintptr, false, ProcCC_Contextless);
	}

// Constants
	add_global_entity(alloc_entity_nil(str_lit("nil"), t_untyped_nil));

	add_global_bool_constant("true",  true);
	add_global_bool_constant("false", false);

	// TODO(bill): Set through flags in the compiler
	add_global_string_constant("ODIN_VENDOR",  bc->ODIN_VENDOR);
	add_global_string_constant("ODIN_VERSION", bc->ODIN_VERSION);
	add_global_string_constant("ODIN_ROOT",    bc->ODIN_ROOT);
	add_global_string_constant("ODIN_BUILD_PROJECT_NAME", bc->ODIN_BUILD_PROJECT_NAME);

	{
		GlobalEnumValue values[TargetOs_COUNT] = {
			{"Unknown",      TargetOs_Invalid},
			{"Windows",      TargetOs_windows},
			{"Darwin",       TargetOs_darwin},
			{"Linux",        TargetOs_linux},
			{"Essence",      TargetOs_essence},
			{"FreeBSD",      TargetOs_freebsd},
			{"OpenBSD",      TargetOs_openbsd},
			{"WASI",         TargetOs_wasi},
			{"JS",           TargetOs_js},
			{"Freestanding", TargetOs_freestanding},
		};

		auto fields = add_global_enum_type(str_lit("Odin_OS_Type"), values, gb_count_of(values));
		add_global_enum_constant(fields, "ODIN_OS", bc->metrics.os);
		add_global_string_constant("ODIN_OS_STRING", target_os_names[bc->metrics.os]);
	}

	{
		GlobalEnumValue values[TargetArch_COUNT] = {
			{"Unknown", TargetArch_Invalid},
			{"amd64",   TargetArch_amd64},
			{"i386",    TargetArch_i386},
			{"arm32",   TargetArch_arm32},
			{"arm64",   TargetArch_arm64},
			{"wasm32",  TargetArch_wasm32},
			{"wasm64",  TargetArch_wasm64},
		};

		auto fields = add_global_enum_type(str_lit("Odin_Arch_Type"), values, gb_count_of(values));
		add_global_enum_constant(fields, "ODIN_ARCH", bc->metrics.arch);
		add_global_string_constant("ODIN_ARCH_STRING", target_arch_names[bc->metrics.arch]);
	}
	
	{
		GlobalEnumValue values[BuildMode_COUNT] = {
			{"Executable", BuildMode_Executable},
			{"Dynamic",    BuildMode_DynamicLibrary},
			{"Object",     BuildMode_Object},
			{"Assembly",   BuildMode_Assembly},
			{"LLVM_IR",    BuildMode_LLVM_IR},
		};

		auto fields = add_global_enum_type(str_lit("Odin_Build_Mode_Type"), values, gb_count_of(values));
		add_global_enum_constant(fields, "ODIN_BUILD_MODE", bc->build_mode);
	}

	{
		GlobalEnumValue values[TargetEndian_COUNT] = {
			{"Unknown", TargetEndian_Invalid},

			{"Little",  TargetEndian_Little},
			{"Big",     TargetEndian_Big},
		};

		auto fields = add_global_enum_type(str_lit("Odin_Endian_Type"), values, gb_count_of(values));
		add_global_enum_constant(fields, "ODIN_ENDIAN", target_endians[bc->metrics.arch]);
		add_global_string_constant("ODIN_ENDIAN_STRING", target_endian_names[target_endians[bc->metrics.arch]]);
	}

	{
		GlobalEnumValue values[ErrorPosStyle_COUNT] = {
			{"Default", ErrorPosStyle_Default},
			{"Unix",    ErrorPosStyle_Unix},
		};

		auto fields = add_global_enum_type(str_lit("Odin_Error_Pos_Style_Type"), values, gb_count_of(values));
		add_global_enum_constant(fields, "ODIN_ERROR_POS_STYLE", build_context.ODIN_ERROR_POS_STYLE);
	}

	{
		GlobalEnumValue values[OdinAtomicMemoryOrder_COUNT] = {
			{OdinAtomicMemoryOrder_strings[OdinAtomicMemoryOrder_relaxed], OdinAtomicMemoryOrder_relaxed},
			{OdinAtomicMemoryOrder_strings[OdinAtomicMemoryOrder_consume], OdinAtomicMemoryOrder_consume},
			{OdinAtomicMemoryOrder_strings[OdinAtomicMemoryOrder_acquire], OdinAtomicMemoryOrder_acquire},
			{OdinAtomicMemoryOrder_strings[OdinAtomicMemoryOrder_release], OdinAtomicMemoryOrder_release},
			{OdinAtomicMemoryOrder_strings[OdinAtomicMemoryOrder_acq_rel], OdinAtomicMemoryOrder_acq_rel},
			{OdinAtomicMemoryOrder_strings[OdinAtomicMemoryOrder_seq_cst], OdinAtomicMemoryOrder_seq_cst},
		};

		add_global_enum_type(str_lit("Atomic_Memory_Order"), values, gb_count_of(values), &t_atomic_memory_order);
		GB_ASSERT(t_atomic_memory_order->kind == Type_Named);
		scope_insert(intrinsics_pkg->scope, t_atomic_memory_order->Named.type_name);
	}


	add_global_bool_constant("ODIN_DEBUG",                    bc->ODIN_DEBUG);
	add_global_bool_constant("ODIN_DISABLE_ASSERT",           bc->ODIN_DISABLE_ASSERT);
	add_global_bool_constant("ODIN_DEFAULT_TO_NIL_ALLOCATOR", bc->ODIN_DEFAULT_TO_NIL_ALLOCATOR);
	add_global_bool_constant("ODIN_NO_DYNAMIC_LITERALS",      bc->no_dynamic_literals);
	add_global_bool_constant("ODIN_NO_CRT",                   bc->no_crt);
	add_global_bool_constant("ODIN_USE_SEPARATE_MODULES",     bc->use_separate_modules);
	add_global_bool_constant("ODIN_TEST",                     bc->command_kind == Command_test);
	add_global_bool_constant("ODIN_NO_ENTRY_POINT",           bc->no_entry_point);
	add_global_bool_constant("ODIN_FOREIGN_ERROR_PROCEDURES", bc->ODIN_FOREIGN_ERROR_PROCEDURES);
	add_global_bool_constant("ODIN_DISALLOW_RTTI",            bc->disallow_rtti);

	add_global_bool_constant("ODIN_VALGRIND_SUPPORT",         bc->ODIN_VALGRIND_SUPPORT);



// Builtin Procedures
	for (isize i = 0; i < gb_count_of(builtin_procs); i++) {
		BuiltinProcId id = cast(BuiltinProcId)i;
		String name = builtin_procs[i].name;
		if (name != "") {
			Entity *entity = alloc_entity(Entity_Builtin, nullptr, make_token_ident(name), t_invalid);
			entity->Builtin.id = id;
			switch (builtin_procs[i].pkg) {
			case BuiltinProcPkg_builtin:
				add_global_entity(entity, builtin_pkg->scope);
				break;
			case BuiltinProcPkg_intrinsics:
				add_global_entity(entity, intrinsics_pkg->scope);
				GB_ASSERT(scope_lookup_current(intrinsics_pkg->scope, name) != nullptr);
				break;
			}
		}
	}

	bool defined_values_double_declaration = false;
	for_array(i, bc->defined_values.entries) {
		char const *name = bc->defined_values.entries[i].key;
		ExactValue value = bc->defined_values.entries[i].value;
		GB_ASSERT(value.kind != ExactValue_Invalid);

		Type *type = nullptr;
		switch (value.kind) {
		case ExactValue_Bool:
			type = t_untyped_bool;
			break;
		case ExactValue_String:
			type = t_untyped_string;
			break;
		case ExactValue_Integer:
			type = t_untyped_integer;
			break;
		case ExactValue_Float:
			type = t_untyped_float;
			break;
		}
		GB_ASSERT(type != nullptr);

		Entity *entity = alloc_entity_constant(nullptr, make_token_ident(name), type, value);
		entity->state = EntityState_Resolved;
		if (scope_insert(config_pkg->scope, entity)) {
			error(entity->token, "'%s' defined as an argument is already declared at the global scope", name);
			defined_values_double_declaration = true;
			// NOTE(bill): Just exit early before anything, even though the compiler will do that anyway
		}
	}

	if (defined_values_double_declaration) {
		gb_exit(1);
	}


	t_u8_ptr       = alloc_type_pointer(t_u8);
	t_int_ptr      = alloc_type_pointer(t_int);
	t_i64_ptr      = alloc_type_pointer(t_i64);
	t_f64_ptr      = alloc_type_pointer(t_f64);
	t_u8_slice     = alloc_type_slice(t_u8);
	t_string_slice = alloc_type_slice(t_string);

	// intrinsics types for objective-c stuff
	{
		t_objc_object   = add_global_type_name(intrinsics_pkg->scope, str_lit("objc_object"),   alloc_type_struct());
		t_objc_selector = add_global_type_name(intrinsics_pkg->scope, str_lit("objc_selector"), alloc_type_struct());
		t_objc_class    = add_global_type_name(intrinsics_pkg->scope, str_lit("objc_class"),    alloc_type_struct());

		t_objc_id       = alloc_type_pointer(t_objc_object);
		t_objc_SEL      = alloc_type_pointer(t_objc_selector);
		t_objc_Class    = alloc_type_pointer(t_objc_class);
	}
}




void init_checker_info(CheckerInfo *i) {
	gbAllocator a = heap_allocator();

	TIME_SECTION("checker info: general");

	array_init(&i->definitions,   a);
	array_init(&i->entities,      a);
	map_init(&i->global_untyped, a);
	string_map_init(&i->foreigns, a);
	map_init(&i->gen_procs,       a);
	map_init(&i->gen_types,       a);
	array_init(&i->type_info_types, a);
	map_init(&i->type_info_map,   a);
	string_map_init(&i->files,    a);
	string_map_init(&i->packages, a);
	array_init(&i->variable_init_order, a);
	array_init(&i->testing_procedures, a, 0, 0);
	array_init(&i->init_procedures, a, 0, 0);
	array_init(&i->required_foreign_imports_through_force, a, 0, 0);



	i->allow_identifier_uses = build_context.query_data_set_settings.kind == QueryDataSet_GoToDefinitions;
	if (i->allow_identifier_uses) {
		array_init(&i->identifier_uses, a);
	}


	TIME_SECTION("checker info: mpmc queues");

	mpmc_init(&i->entity_queue, a, 1<<20);
	mpmc_init(&i->definition_queue, a, 1<<20);
	mpmc_init(&i->required_global_variable_queue, a, 1<<10);
	mpmc_init(&i->required_foreign_imports_through_force_queue, a, 1<<10);

	TIME_SECTION("checker info: mutexes");

	mutex_init(&i->gen_procs_mutex);
	mutex_init(&i->gen_types_mutex);
	mutex_init(&i->lazy_mutex);
	mutex_init(&i->builtin_mutex);
	mutex_init(&i->global_untyped_mutex);
	mutex_init(&i->type_info_mutex);
	mutex_init(&i->deps_mutex);
	mutex_init(&i->type_and_value_mutex);
	mutex_init(&i->identifier_uses_mutex);
	mutex_init(&i->foreign_mutex);

	semaphore_init(&i->collect_semaphore);

	mpmc_init(&i->intrinsics_entry_point_usage, a, 1<<10); // just waste some memory here, even if it probably never used

	mutex_init(&i->objc_types_mutex);
	map_init(&i->objc_msgSend_types, a);
	mutex_init(&i->load_file_mutex);
	string_map_init(&i->load_file_cache, a);
}

void destroy_checker_info(CheckerInfo *i) {
	array_free(&i->definitions);
	array_free(&i->entities);
	map_destroy(&i->global_untyped);
	string_map_destroy(&i->foreigns);
	map_destroy(&i->gen_procs);
	map_destroy(&i->gen_types);
	array_free(&i->type_info_types);
	map_destroy(&i->type_info_map);
	string_map_destroy(&i->files);
	string_map_destroy(&i->packages);
	array_free(&i->variable_init_order);
	array_free(&i->identifier_uses);
	array_free(&i->required_foreign_imports_through_force);

	mpmc_destroy(&i->entity_queue);
	mpmc_destroy(&i->definition_queue);
	mpmc_destroy(&i->required_global_variable_queue);
	mpmc_destroy(&i->required_foreign_imports_through_force_queue);

	mutex_destroy(&i->gen_procs_mutex);
	mutex_destroy(&i->gen_types_mutex);
	mutex_destroy(&i->lazy_mutex);
	mutex_destroy(&i->builtin_mutex);
	mutex_destroy(&i->global_untyped_mutex);
	mutex_destroy(&i->type_info_mutex);
	mutex_destroy(&i->deps_mutex);
	mutex_destroy(&i->type_and_value_mutex);
	mutex_destroy(&i->identifier_uses_mutex);
	mutex_destroy(&i->foreign_mutex);

	mutex_destroy(&i->objc_types_mutex);
	map_destroy(&i->objc_msgSend_types);
	mutex_init(&i->load_file_mutex);
	string_map_destroy(&i->load_file_cache);
}

CheckerContext make_checker_context(Checker *c) {
	CheckerContext ctx = {};
	ctx.checker   = c;
	ctx.info      = &c->info;
	ctx.scope     = builtin_pkg->scope;
	ctx.pkg       = builtin_pkg;

	ctx.type_path = new_checker_type_path();
	ctx.type_level = 0;
	ctx.poly_path = new_checker_poly_path();
	ctx.poly_level = 0;
	return ctx;
}
void destroy_checker_context(CheckerContext *ctx) {
	destroy_checker_type_path(ctx->type_path);
	destroy_checker_poly_path(ctx->poly_path);
}

void add_curr_ast_file(CheckerContext *ctx, AstFile *file) {
	if (file != nullptr) {
		ctx->file  = file;
		ctx->decl  = file->pkg->decl_info;
		ctx->scope = file->scope;
		ctx->pkg   = file->pkg;
	}
}
void reset_checker_context(CheckerContext *ctx, AstFile *file, UntypedExprInfoMap *untyped) {
	if (ctx == nullptr) {
		return;
	}
	destroy_checker_context(ctx);
	auto *queue = ctx->procs_to_check_queue;
	*ctx = make_checker_context(ctx->checker);
	add_curr_ast_file(ctx, file);
	ctx->procs_to_check_queue = queue;
	ctx->untyped = untyped;
}




void init_checker(Checker *c) {
	gbAllocator a = heap_allocator();

	TIME_SECTION("init checker info");
	init_checker_info(&c->info);

	c->info.checker = c;

	TIME_SECTION("init proc queues");
	mpmc_init(&c->procs_with_deferred_to_check, a, 1<<10);

	// NOTE(bill): 1 Mi elements should be enough on average
	mpmc_init(&c->procs_to_check_queue, heap_allocator(), 1<<20);
	semaphore_init(&c->procs_to_check_semaphore);

	mpmc_init(&c->global_untyped_queue, a, 1<<20);

	c->builtin_ctx = make_checker_context(c);
}

void destroy_checker(Checker *c) {
	destroy_checker_info(&c->info);

	destroy_checker_context(&c->builtin_ctx);

	mpmc_destroy(&c->procs_to_check_queue);
	semaphore_destroy(&c->procs_to_check_semaphore);

	mpmc_destroy(&c->global_untyped_queue);
}


TypeAndValue type_and_value_of_expr(Ast *expr) {
	TypeAndValue tav = {};
	if (expr != nullptr) {
		tav = expr->tav;
	}
	return tav;
}

Type *type_of_expr(Ast *expr) {
	TypeAndValue tav = expr->tav;
	if (tav.mode != Addressing_Invalid) {
		return tav.type;
	}
	{
		Entity *entity = entity_of_node(expr);
		if (entity) {
			return entity->type;
		}
	}

	return nullptr;
}

Entity *implicit_entity_of_node(Ast *clause) {
	if (clause != nullptr && clause->kind == Ast_CaseClause) {
		return clause->CaseClause.implicit_entity;
	}
	return nullptr;
}

Entity *entity_of_node(Ast *expr) {
	expr = unparen_expr(expr);
	switch (expr->kind) {
	case_ast_node(ident, Ident, expr);
		Entity *e = ident->entity;
		if (e && e->flags & EntityFlag_Overridden) {
			// GB_PANIC("use of an overriden entity: %.*s", LIT(e->token.string));
		}
		return e;
	case_end;
	case_ast_node(se, SelectorExpr, expr);
		Ast *s = unselector_expr(se->selector);
		return entity_of_node(s);
	case_end;
	case_ast_node(cc, CaseClause, expr);
		return cc->implicit_entity;
	case_end;
	}
	return nullptr;
}

DeclInfo *decl_info_of_entity(Entity *e) {
	if (e != nullptr) {
		return e->decl_info;
	}
	return nullptr;
}

DeclInfo *decl_info_of_ident(Ast *ident) {
	return decl_info_of_entity(entity_of_node(ident));
}

AstFile *ast_file_of_filename(CheckerInfo *i, String filename) {
	AstFile **found = string_map_get(&i->files, filename);
	if (found != nullptr) {
		return *found;
	}
	return nullptr;
}
ExprInfo *check_get_expr_info(CheckerContext *c, Ast *expr) {
	if (c->untyped != nullptr) {
		ExprInfo **found = map_get(c->untyped, expr);
		if (found) {
			return *found;
		}
		return nullptr;
	} else {
		mutex_lock(&c->info->global_untyped_mutex);
		defer (mutex_unlock(&c->info->global_untyped_mutex));
		ExprInfo **found = map_get(&c->info->global_untyped, expr);
		if (found) {
			return *found;
		}
		return nullptr;
	}
}

void check_set_expr_info(CheckerContext *c, Ast *expr, AddressingMode mode, Type *type, ExactValue value) {
	if (c->untyped != nullptr) {
		map_set(c->untyped, expr, make_expr_info(mode, type, value, false));
	} else {
		mutex_lock(&c->info->global_untyped_mutex);
		map_set(&c->info->global_untyped, expr, make_expr_info(mode, type, value, false));
		mutex_unlock(&c->info->global_untyped_mutex);
	}
}

void check_remove_expr_info(CheckerContext *c, Ast *e) {
	if (c->untyped != nullptr) {
		map_remove(c->untyped, e);
		GB_ASSERT(map_get(c->untyped, e) == nullptr);
	} else {
		auto *untyped = &c->info->global_untyped;
		mutex_lock(&c->info->global_untyped_mutex);
		map_remove(untyped, e);
		GB_ASSERT(map_get(untyped, e) == nullptr);
		mutex_unlock(&c->info->global_untyped_mutex);
	}
}


isize type_info_index(CheckerInfo *info, Type *type, bool error_on_failure) {
	type = default_type(type);
	if (type == t_llvm_bool) {
		type = t_bool;
	}

	mutex_lock(&info->type_info_mutex);

	isize entry_index = -1;
	isize *found_entry_index = map_get(&info->type_info_map, type);
	if (found_entry_index) {
		entry_index = *found_entry_index;
	}
	if (entry_index < 0) {
		// NOTE(bill): Do manual search
		// TODO(bill): This is O(n) and can be very slow
		for_array(i, info->type_info_map.entries){
			auto *e = &info->type_info_map.entries[i];
			if (are_types_identical_unique_tuples(e->key, type)) {
				entry_index = e->value;
				// NOTE(bill): Add it to the search map
				map_set(&info->type_info_map, type, entry_index);
				break;
			}
		}
	}

	mutex_unlock(&info->type_info_mutex);

	if (error_on_failure && entry_index < 0) {
		compiler_error("Type_Info for '%s' could not be found", type_to_string(type));
	}
	return entry_index;
}


void add_untyped(CheckerContext *c, Ast *expr, AddressingMode mode, Type *type, ExactValue value) {
	if (expr == nullptr) {
		return;
	}
	if (mode == Addressing_Invalid) {
		return;
	}

	if (mode == Addressing_Constant && type == t_invalid) {
		compiler_error("add_untyped - invalid type: %s", type_to_string(type));
	}
	if (!is_type_untyped(type)) {
		return;
	}
	check_set_expr_info(c, expr, mode, type, value);
}

void add_type_and_value(CheckerInfo *i, Ast *expr, AddressingMode mode, Type *type, ExactValue value) {
	if (expr == nullptr) {
		return;
	}
	if (mode == Addressing_Invalid) {
		return;
	}
	if (mode == Addressing_Constant && type == t_invalid) {
		return;
	}

	mutex_lock(&i->type_and_value_mutex);
	Ast *prev_expr = nullptr;
	while (prev_expr != expr) {
		prev_expr = expr;
		expr->tav.mode = mode;
		if (type != nullptr && expr->tav.type != nullptr &&
		    is_type_any(type) && is_type_untyped(expr->tav.type)) {
			// ignore
		} else {
			expr->tav.type = type;
		}

		if (mode == Addressing_Constant || mode == Addressing_Invalid) {
			expr->tav.value = value;
		} else if (mode == Addressing_Value && is_type_typeid(type)) {
			expr->tav.value = value;
		} else if (mode == Addressing_Value && is_type_proc(type)) {
			expr->tav.value = value;
		}

		expr = unparen_expr(expr);
	}
	mutex_unlock(&i->type_and_value_mutex);
}

void add_entity_definition(CheckerInfo *i, Ast *identifier, Entity *entity) {
	GB_ASSERT(identifier != nullptr);
	GB_ASSERT(identifier->kind == Ast_Ident);
	// if (is_blank_ident(identifier)) {
		// return;
	// }
	if (identifier->Ident.entity != nullptr) {
		// NOTE(bill): Identifier has already been handled
		return;
	}
	GB_ASSERT(entity != nullptr);
	identifier->Ident.entity = entity;
	entity->identifier = identifier;
	mpmc_enqueue(&i->definition_queue, entity);
}

bool redeclaration_error(String name, Entity *prev, Entity *found) {
	TokenPos pos = found->token.pos;
	Entity *up = found->using_parent;
	if (up != nullptr) {
		if (pos == up->token.pos) {
			// NOTE(bill): Error should have been handled already
			return false;
		}
		if (found->flags & EntityFlag_Result) {
			error(prev->token,
			      "Direct shadowing of the named return value '%.*s' in this scope through 'using'\n"
			      "\tat %s",
			      LIT(name),
			      token_pos_to_string(up->token.pos));
		} else {
			error(prev->token,
			      "Redeclaration of '%.*s' in this scope through 'using'\n"
			      "\tat %s",
			      LIT(name),
			      token_pos_to_string(up->token.pos));
		}
	} else {
		if (pos == prev->token.pos) {
			// NOTE(bill): Error should have been handled already
			return false;
		}
		if (found->flags & EntityFlag_Result) {
			error(prev->token,
			      "Direct shadowing of the named return value '%.*s' in this scope\n"
			      "\tat %s",
			      LIT(name),
			      token_pos_to_string(pos));
		} else {
			error(prev->token,
			      "Redeclaration of '%.*s' in this scope\n"
			      "\tat %s",
			      LIT(name),
			      token_pos_to_string(pos));
		}
	}
	return false;
}

void add_entity_flags_from_file(CheckerContext *c, Entity *e, Scope *scope) {
	if (c->file != nullptr && (c->file->flags & AstFile_IsLazy) != 0 && scope->flags & ScopeFlag_File) {
		AstPackage *pkg = c->file->pkg;
		if (pkg->kind == Package_Init && e->kind == Entity_Procedure && e->token.string == "main") {
			// Do nothing
		} else if (e->flags & (EntityFlag_Test|EntityFlag_Init)) {
			// Do nothing
		} else {
			e->flags |= EntityFlag_Lazy;
		}
	}
}

bool add_entity_with_name(CheckerContext *c, Scope *scope, Ast *identifier, Entity *entity, String name) {
	if (scope == nullptr) {
		return false;
	}


	if (!is_blank_ident(name)) {
		Entity *ie = scope_insert(scope, entity);
		if (ie != nullptr) {
			return redeclaration_error(name, entity, ie);
		}
	}
	if (identifier != nullptr) {
		if (entity->file == nullptr) {
			entity->file = c->file;
		}
		add_entity_definition(c->info, identifier, entity);
	}
	return true;
}
bool add_entity(CheckerContext *c, Scope *scope, Ast *identifier, Entity *entity) {
	return add_entity_with_name(c, scope, identifier, entity, entity->token.string);
}

void add_entity_use(CheckerContext *c, Ast *identifier, Entity *entity) {
	if (entity == nullptr) {
		return;
	}
	if (identifier != nullptr) {
		if (identifier->kind != Ast_Ident) {
			return;
		}
		Ast *empty_ident = nullptr;
		entity->identifier.compare_exchange_strong(empty_ident, identifier);

		identifier->Ident.entity = entity;

		if (c->info->allow_identifier_uses) {
			mutex_lock(&c->info->identifier_uses_mutex);
			array_add(&c->info->identifier_uses, identifier);
			mutex_unlock(&c->info->identifier_uses_mutex);
		}

		String dmsg = entity->deprecated_message;
		if (dmsg.len > 0) {
			warning(identifier, "%.*s is deprecated: %.*s", LIT(entity->token.string), LIT(dmsg));
		}
		String wmsg = entity->warning_message;
		if (wmsg.len > 0) {
			warning(identifier, "%.*s: %.*s", LIT(entity->token.string), LIT(wmsg));
		}
	}
	entity->flags |= EntityFlag_Used;
	add_declaration_dependency(c, entity);
	if (entity_has_deferred_procedure(entity)) {
		Entity *deferred = entity->Procedure.deferred_procedure.entity;
		add_entity_use(c, nullptr, deferred);
	}
}


bool could_entity_be_lazy(Entity *e, DeclInfo *d) {
	if ((e->flags & EntityFlag_Lazy) == 0) {
		return false;
	}

	if (e->flags & (EntityFlag_Test|EntityFlag_Init)) {
		return false;
	} else if (e->kind == Entity_Variable && e->Variable.is_export) {
		return false;
	} else if (e->kind == Entity_Procedure && e->Procedure.is_export) {
		return false;
	}

	for_array(i, d->attributes) {
		Ast *attr = d->attributes[i];
		if (attr->kind != Ast_Attribute) continue;
		for_array(j, attr->Attribute.elems) {
			Ast *elem = attr->Attribute.elems[j];
			String name = {};

			switch (elem->kind) {
			case_ast_node(i, Ident, elem);
				name = i->token.string;
			case_end;
			case_ast_node(i, Implicit, elem);
				name = i->string;
			case_end;
			case_ast_node(fv, FieldValue, elem);
				if (fv->field->kind == Ast_Ident) {
					name = fv->field->Ident.token.string;
				}
			case_end;
			}

			if (name.len != 0) {
				if (name == "test") {
					return false;
				} else if (name == "export") {
					return false;
				} else if (name == "init") {
					return false;
				} else if (name == "linkage") {
					return false;
				}
			}
		}
	}

	return true;
}

void add_entity_and_decl_info(CheckerContext *c, Ast *identifier, Entity *e, DeclInfo *d, bool is_exported) {
	GB_ASSERT(identifier->kind == Ast_Ident);
	GB_ASSERT(e != nullptr && d != nullptr);
	GB_ASSERT(identifier->Ident.token.string == e->token.string);

	if (!could_entity_be_lazy(e, d)) {
		e->flags &= ~EntityFlag_Lazy;
	}

	if (e->scope != nullptr) {
		Scope *scope = e->scope;

		if (scope->flags & ScopeFlag_File && is_entity_kind_exported(e->kind) && is_exported) {
			AstPackage *pkg = scope->file->pkg;
			GB_ASSERT(pkg->scope == scope->parent);
			GB_ASSERT(c->pkg == pkg);

			// NOTE(bill): as multiple threads could be accessing this, it needs to be wrapped
			// The current hash map for scopes is not thread safe
			AstPackageExportedEntity ee = {identifier, e};
			mpmc_enqueue(&pkg->exported_entity_queue, ee);

			// mutex_lock(&c->info->scope_mutex);
			// add_entity(c, pkg->scope, identifier, e);
			// mutex_unlock(&c->info->scope_mutex);
		} else {
			add_entity(c, scope, identifier, e);
		}
	}

	CheckerInfo *info = c->info;
	add_entity_definition(info, identifier, e);
	GB_ASSERT(e->decl_info == nullptr);
	e->decl_info = d;
	d->entity = e;
	e->pkg = c->pkg;

	isize queue_count = -1;
	bool is_lazy = false;

	is_lazy = (e->flags & EntityFlag_Lazy) == EntityFlag_Lazy;
	if (!is_lazy) {
		queue_count = mpmc_enqueue(&info->entity_queue, e);
	}

	if (e->token.pos.file_id != 0) {
		e->order_in_src = cast(u64)(e->token.pos.file_id)<<32 | u32(e->token.pos.offset);
	} else {
		GB_ASSERT(!is_lazy);
		e->order_in_src = cast(u64)(1+queue_count);
	}
}


void add_implicit_entity(CheckerContext *c, Ast *clause, Entity *e) {
	GB_ASSERT(clause != nullptr);
	GB_ASSERT(e != nullptr);
	GB_ASSERT(clause->kind == Ast_CaseClause);
	clause->CaseClause.implicit_entity = e;
}

void add_type_info_type(CheckerContext *c, Type *t) {
	void add_type_info_type_internal(CheckerContext *c, Type *t);

	if (build_context.disallow_rtti) {
		return;
	}

	mutex_lock(&c->info->type_info_mutex);
	add_type_info_type_internal(c, t);
	mutex_unlock(&c->info->type_info_mutex);
}

void add_type_info_type_internal(CheckerContext *c, Type *t) {
	if (t == nullptr) {
		return;
	}
	t = default_type(t);
	if (is_type_untyped(t)) {
		return; // Could be nil
	}
	if (is_type_polymorphic(base_type(t))) {
		return;
	}

	add_type_info_dependency(c->info, c->decl, t, false);

	auto found = map_get(&c->info->type_info_map, t);
	if (found != nullptr) {
		// Types have already been added
		return;
	}

	bool prev = false;
	isize ti_index = -1;
	for_array(i, c->info->type_info_map.entries) {
		auto *e = &c->info->type_info_map.entries[i];
		if (are_types_identical_unique_tuples(t, e->key)) {
			// Duplicate entry
			ti_index = e->value;
			prev = true;
			break;
		}
	}
	if (ti_index < 0) {
		// Unique entry
		// NOTE(bill): map entries grow linearly and in order
		ti_index = c->info->type_info_types.count;
		array_add(&c->info->type_info_types, t);
	}
	map_set(&c->checker->info.type_info_map, t, ti_index);

	if (prev) {
		// NOTE(bill): If a previous one exists already, no need to continue
		return;
	}

	// Add nested types

	if (t->kind == Type_Named) {
		// NOTE(bill): Just in case
		add_type_info_type_internal(c, t->Named.base);
		return;
	}

	Type *bt = base_type(t);
	add_type_info_type_internal(c, bt);

	switch (bt->kind) {
	case Type_Invalid:
		break;
	case Type_Basic:
		switch (bt->Basic.kind) {
		case Basic_cstring:
			add_type_info_type_internal(c, t_u8_ptr);
			break;
		case Basic_string:
			add_type_info_type_internal(c, t_u8_ptr);
			add_type_info_type_internal(c, t_int);
			break;
		case Basic_any:
			add_type_info_type_internal(c, t_type_info_ptr);
			add_type_info_type_internal(c, t_rawptr);
			break;
		case Basic_typeid:
			break;

		case Basic_complex64:
			add_type_info_type_internal(c, t_type_info_float);
			add_type_info_type_internal(c, t_f32);
			break;
		case Basic_complex128:
			add_type_info_type_internal(c, t_type_info_float);
			add_type_info_type_internal(c, t_f64);
			break;
		case Basic_quaternion128:
			add_type_info_type_internal(c, t_type_info_float);
			add_type_info_type_internal(c, t_f32);
			break;
		case Basic_quaternion256:
			add_type_info_type_internal(c, t_type_info_float);
			add_type_info_type_internal(c, t_f64);
			break;
		}
		break;

	case Type_BitSet:
		add_type_info_type_internal(c, bt->BitSet.elem);
		add_type_info_type_internal(c, bt->BitSet.underlying);
		break;

	case Type_Pointer:
		add_type_info_type_internal(c, bt->Pointer.elem);
		break;

	case Type_MultiPointer:
		add_type_info_type_internal(c, bt->MultiPointer.elem);
		break;

	case Type_Array:
		add_type_info_type_internal(c, bt->Array.elem);
		add_type_info_type_internal(c, alloc_type_pointer(bt->Array.elem));
		add_type_info_type_internal(c, t_int);
		break;

	case Type_EnumeratedArray:
		add_type_info_type_internal(c, bt->EnumeratedArray.index);
		add_type_info_type_internal(c, t_int);
		add_type_info_type_internal(c, bt->EnumeratedArray.elem);
		add_type_info_type_internal(c, alloc_type_pointer(bt->EnumeratedArray.elem));
		break;

	case Type_DynamicArray:
		add_type_info_type_internal(c, bt->DynamicArray.elem);
		add_type_info_type_internal(c, alloc_type_pointer(bt->DynamicArray.elem));
		add_type_info_type_internal(c, t_int);
		add_type_info_type_internal(c, t_allocator);
		break;
	case Type_Slice:
		add_type_info_type_internal(c, bt->Slice.elem);
		add_type_info_type_internal(c, alloc_type_pointer(bt->Slice.elem));
		add_type_info_type_internal(c, t_int);
		break;

	case Type_Enum:
		add_type_info_type_internal(c, bt->Enum.base_type);
		break;

	case Type_Union:
		if (union_tag_size(t) > 0) {
			add_type_info_type_internal(c, union_tag_type(t));
		} else {
			add_type_info_type_internal(c, t_type_info_ptr);
		}
		add_type_info_type_internal(c, bt->Union.polymorphic_params);
		for_array(i, bt->Union.variants) {
			add_type_info_type_internal(c, bt->Union.variants[i]);
		}
		break;

	case Type_Struct:
		if (bt->Struct.scope != nullptr) {
			for_array(i, bt->Struct.scope->elements.entries) {
				Entity *e = bt->Struct.scope->elements.entries[i].value;
				switch (bt->Struct.soa_kind) {
				case StructSoa_Dynamic:
					add_type_info_type_internal(c, t_allocator);
					/*fallthrough*/
				case StructSoa_Slice:
				case StructSoa_Fixed:
					add_type_info_type_internal(c, alloc_type_pointer(e->type));
					break;
				default:
					add_type_info_type_internal(c, e->type);
					break;
				}
			}
		}
		add_type_info_type_internal(c, bt->Struct.polymorphic_params);
		for_array(i, bt->Struct.fields) {
			Entity *f = bt->Struct.fields[i];
			add_type_info_type_internal(c, f->type);
		}
		add_comparison_procedures_for_fields(c, bt);
		break;

	case Type_Map:
		init_map_internal_types(bt);
		add_type_info_type_internal(c, bt->Map.key);
		add_type_info_type_internal(c, bt->Map.value);
		add_type_info_type_internal(c, bt->Map.generated_struct_type);
		break;

	case Type_Tuple:
		for_array(i, bt->Tuple.variables) {
			Entity *var = bt->Tuple.variables[i];
			add_type_info_type_internal(c, var->type);
		}
		break;

	case Type_Proc:
		add_type_info_type_internal(c, bt->Proc.params);
		add_type_info_type_internal(c, bt->Proc.results);
		break;

	case Type_SimdVector:
		add_type_info_type_internal(c, bt->SimdVector.elem);
		break;

	case Type_RelativePointer:
		add_type_info_type_internal(c, bt->RelativePointer.pointer_type);
		add_type_info_type_internal(c, bt->RelativePointer.base_integer);
		break;

	case Type_RelativeSlice:
		add_type_info_type_internal(c, bt->RelativeSlice.slice_type);
		add_type_info_type_internal(c, bt->RelativeSlice.base_integer);
		break;

	case Type_Matrix:
		add_type_info_type_internal(c, bt->Matrix.elem);
		break;

	case Type_SoaPointer:
		add_type_info_type_internal(c, bt->SoaPointer.elem);
		break;


	default:
		GB_PANIC("Unhandled type: %*.s %d", LIT(type_strings[bt->kind]), bt->kind);
		break;
	}
}



gb_global bool global_procedure_body_in_worker_queue = false;

void check_procedure_later(CheckerContext *c, ProcInfo *info) {
	GB_ASSERT(info != nullptr);
	GB_ASSERT(info->decl != nullptr);

	if (build_context.threaded_checker && global_procedure_body_in_worker_queue) {
		GB_ASSERT(c->procs_to_check_queue != nullptr);
	}

	auto *queue = c->procs_to_check_queue ? c->procs_to_check_queue : &c->checker->procs_to_check_queue;
	mpmc_enqueue(queue, info);
}

void check_procedure_later(CheckerContext *c, AstFile *file, Token token, DeclInfo *decl, Type *type, Ast *body, u64 tags) {
	ProcInfo *info = gb_alloc_item(permanent_allocator(), ProcInfo);
	info->file  = file;
	info->token = token;
	info->decl  = decl;
	info->type  = type;
	info->body  = body;
	info->tags  = tags;
	check_procedure_later(c, info);
}


void add_min_dep_type_info(Checker *c, Type *t) {
	if (t == nullptr) {
		return;
	}
	t = default_type(t);
	if (is_type_untyped(t)) {
		return; // Could be nil
	}
	if (is_type_polymorphic(base_type(t))) {
		return;
	}

	auto *set = &c->info.minimum_dependency_type_info_set;

	isize ti_index = type_info_index(&c->info, t, false);
	if (ti_index < 0) {
		add_type_info_type(&c->builtin_ctx, t); // Missing the type information
		ti_index = type_info_index(&c->info, t, false);
	}
	GB_ASSERT(ti_index >= 0);
	if (ptr_set_update(set, ti_index)) {
		// Type Already exists
		return;
	}

	// Add nested types
	if (t->kind == Type_Named) {
		// NOTE(bill): Just in case
		add_min_dep_type_info(c, t->Named.base);
		return;
	}

	Type *bt = base_type(t);
	add_min_dep_type_info(c, bt);

	switch (bt->kind) {
	case Type_Invalid:
		break;
	case Type_Basic:
		switch (bt->Basic.kind) {
		case Basic_string:
			add_min_dep_type_info(c, t_u8_ptr);
			add_min_dep_type_info(c, t_int);
			break;
		case Basic_any:
			add_min_dep_type_info(c, t_rawptr);
			add_min_dep_type_info(c, t_typeid);
			break;

		case Basic_complex64:
			add_min_dep_type_info(c, t_type_info_float);
			add_min_dep_type_info(c, t_f32);
			break;
		case Basic_complex128:
			add_min_dep_type_info(c, t_type_info_float);
			add_min_dep_type_info(c, t_f64);
			break;
		case Basic_quaternion128:
			add_min_dep_type_info(c, t_type_info_float);
			add_min_dep_type_info(c, t_f32);
			break;
		case Basic_quaternion256:
			add_min_dep_type_info(c, t_type_info_float);
			add_min_dep_type_info(c, t_f64);
			break;
		}
		break;

	case Type_BitSet:
		add_min_dep_type_info(c, bt->BitSet.elem);
		add_min_dep_type_info(c, bt->BitSet.underlying);
		break;

	case Type_Pointer:
		add_min_dep_type_info(c, bt->Pointer.elem);
		break;

	case Type_MultiPointer:
		add_min_dep_type_info(c, bt->MultiPointer.elem);
		break;

	case Type_Array:
		add_min_dep_type_info(c, bt->Array.elem);
		add_min_dep_type_info(c, alloc_type_pointer(bt->Array.elem));
		add_min_dep_type_info(c, t_int);
		break;
	case Type_EnumeratedArray:
		add_min_dep_type_info(c, bt->EnumeratedArray.index);
		add_min_dep_type_info(c, t_int);
		add_min_dep_type_info(c, bt->EnumeratedArray.elem);
		add_min_dep_type_info(c, alloc_type_pointer(bt->EnumeratedArray.elem));
		break;

	case Type_DynamicArray:
		add_min_dep_type_info(c, bt->DynamicArray.elem);
		add_min_dep_type_info(c, alloc_type_pointer(bt->DynamicArray.elem));
		add_min_dep_type_info(c, t_int);
		add_min_dep_type_info(c, t_allocator);
		break;
	case Type_Slice:
		add_min_dep_type_info(c, bt->Slice.elem);
		add_min_dep_type_info(c, alloc_type_pointer(bt->Slice.elem));
		add_min_dep_type_info(c, t_int);
		break;

	case Type_Enum:
		add_min_dep_type_info(c, bt->Enum.base_type);
		break;

	case Type_Union:
		if (union_tag_size(t) > 0) {
			add_min_dep_type_info(c, union_tag_type(t));
		} else {
			add_min_dep_type_info(c, t_type_info_ptr);
		}
		add_min_dep_type_info(c, bt->Union.polymorphic_params);
		for_array(i, bt->Union.variants) {
			add_min_dep_type_info(c, bt->Union.variants[i]);
		}
		break;

	case Type_Struct:
		if (bt->Struct.scope != nullptr) {
			for_array(i, bt->Struct.scope->elements.entries) {
				Entity *e = bt->Struct.scope->elements.entries[i].value;
				switch (bt->Struct.soa_kind) {
				case StructSoa_Dynamic:
					add_min_dep_type_info(c, t_allocator);
					/*fallthrough*/
				case StructSoa_Slice:
				case StructSoa_Fixed:
					add_min_dep_type_info(c, alloc_type_pointer(e->type));
					break;
				default:
					add_min_dep_type_info(c, e->type);
					break;
				}
			}
		}
		add_min_dep_type_info(c, bt->Struct.polymorphic_params);
		for_array(i, bt->Struct.fields) {
			Entity *f = bt->Struct.fields[i];
			add_min_dep_type_info(c, f->type);
		}
		break;

	case Type_Map:
		init_map_internal_types(bt);
		add_min_dep_type_info(c, bt->Map.key);
		add_min_dep_type_info(c, bt->Map.value);
		add_min_dep_type_info(c, bt->Map.generated_struct_type);
		break;

	case Type_Tuple:
		for_array(i, bt->Tuple.variables) {
			Entity *var = bt->Tuple.variables[i];
			add_min_dep_type_info(c, var->type);
		}
		break;

	case Type_Proc:
		add_min_dep_type_info(c, bt->Proc.params);
		add_min_dep_type_info(c, bt->Proc.results);
		break;

	case Type_SimdVector:
		add_min_dep_type_info(c, bt->SimdVector.elem);
		break;

	case Type_RelativePointer:
		add_min_dep_type_info(c, bt->RelativePointer.pointer_type);
		add_min_dep_type_info(c, bt->RelativePointer.base_integer);
		break;

	case Type_RelativeSlice:
		add_min_dep_type_info(c, bt->RelativeSlice.slice_type);
		add_min_dep_type_info(c, bt->RelativeSlice.base_integer);
		break;

	case Type_Matrix:
		add_min_dep_type_info(c, bt->Matrix.elem);
		break;

	case Type_SoaPointer:
		add_min_dep_type_info(c, bt->SoaPointer.elem);
		break;

	default:
		GB_PANIC("Unhandled type: %*.s", LIT(type_strings[bt->kind]));
		break;
	}
}


void add_dependency_to_set(Checker *c, Entity *entity) {
	if (entity == nullptr) {
		return;
	}

	CheckerInfo *info = &c->info;
	auto *set = &info->minimum_dependency_set;

	if (entity->type != nullptr &&
	    is_type_polymorphic(entity->type)) {

		DeclInfo *decl = decl_info_of_entity(entity);
		if (decl != nullptr && decl->gen_proc_type == nullptr) {
			return;
		}
	}

	if (ptr_set_update(set, entity)) {
		return;
	}

	DeclInfo *decl = decl_info_of_entity(entity);
	if (decl == nullptr) {
		return;
	}

	for_array(i, decl->type_info_deps.entries) {
		Type *type = decl->type_info_deps.entries[i].ptr;
		add_min_dep_type_info(c, type);
	}

	for_array(i, decl->deps.entries) {
		Entity *e = decl->deps.entries[i].ptr;
		add_dependency_to_set(c, e);
		if (e->kind == Entity_Procedure && e->Procedure.is_foreign) {
			Entity *fl = e->Procedure.foreign_library;
			if (fl != nullptr) {
				GB_ASSERT_MSG(fl->kind == Entity_LibraryName &&
				              (fl->flags&EntityFlag_Used),
				              "%.*s", LIT(entity->token.string));
				add_dependency_to_set(c, fl);
			}
		} else if (e->kind == Entity_Variable && e->Variable.is_foreign) {
			Entity *fl = e->Variable.foreign_library;
			if (fl != nullptr) {
				GB_ASSERT_MSG(fl->kind == Entity_LibraryName &&
				              (fl->flags&EntityFlag_Used),
				              "%.*s", LIT(entity->token.string));
				add_dependency_to_set(c, fl);
			}
		}
	}
}

void force_add_dependency_entity(Checker *c, Scope *scope, String const &name) {
	Entity *e = scope_lookup(scope, name);
	if (e == nullptr) {
		return;
	}
	GB_ASSERT_MSG(e != nullptr, "unable to find %.*s", LIT(name));
	e->flags |= EntityFlag_Used;
	add_dependency_to_set(c, e);
}



void generate_minimum_dependency_set(Checker *c, Entity *start) {
	isize entity_count = c->info.entities.count;
	isize min_dep_set_cap = next_pow2_isize(entity_count*4); // empirically determined factor

	ptr_set_init(&c->info.minimum_dependency_set, heap_allocator(), min_dep_set_cap);
	ptr_set_init(&c->info.minimum_dependency_type_info_set, heap_allocator());

#define FORCE_ADD_RUNTIME_ENTITIES(condition, ...) do {                                              \
	if (condition) {                                                                             \
		String entities[] = {__VA_ARGS__};                                                   \
		for (isize i = 0; i < gb_count_of(entities); i++) {                                  \
			force_add_dependency_entity(c, c->info.runtime_package->scope, entities[i]); \
		}                                                                                    \
	}                                                                                            \
} while (0)

	// required runtime entities
	FORCE_ADD_RUNTIME_ENTITIES(true,
		// Odin types
		str_lit("Source_Code_Location"),
		str_lit("Context"),
		str_lit("Allocator"),
		str_lit("Logger"),

		// Odin internal procedures
		str_lit("__init_context"),
		str_lit("cstring_to_string"),
		str_lit("_cleanup_runtime"),

		// Pseudo-CRT required procedures
		str_lit("memset"),
		str_lit("memcpy"),
		str_lit("memmove"),

		// Utility procedures
		str_lit("memory_equal"),
		str_lit("memory_compare"),
		str_lit("memory_compare_zero"),

		// Extended data type internal procedures
		str_lit("umodti3"),
		str_lit("udivti3"),
		str_lit("modti3"),
		str_lit("divti3"),
		str_lit("fixdfti"),
		str_lit("fixunsdfti"),
		str_lit("fixunsdfdi"),
		str_lit("floattidf"),
		str_lit("floattidf_unsigned"),
		str_lit("truncsfhf2"),
		str_lit("truncdfhf2"),
		str_lit("gnu_h2f_ieee"),
		str_lit("gnu_f2h_ieee"),
		str_lit("extendhfsf2"),

		// WASM Specific
		str_lit("__ashlti3"),
		str_lit("__multi3"),
	);

	FORCE_ADD_RUNTIME_ENTITIES(!build_context.disallow_rtti,
		// Odin types
		str_lit("Type_Info"),

		// Global variables
		str_lit("type_table"),
		str_lit("__type_info_of"),
	);

	FORCE_ADD_RUNTIME_ENTITIES(!build_context.no_entry_point,
		// Global variables
		str_lit("args__"),
	);

	FORCE_ADD_RUNTIME_ENTITIES((build_context.no_crt && !is_arch_wasm()),
		// NOTE(bill): Only if these exist
		str_lit("_tls_index"),
		str_lit("_fltused"),
	);

	FORCE_ADD_RUNTIME_ENTITIES(!build_context.no_bounds_check,
		// Bounds checking related procedures
		str_lit("bounds_check_error"),
		str_lit("matrix_bounds_check_error"),
		str_lit("slice_expr_error_hi"),
		str_lit("slice_expr_error_lo_hi"),
		str_lit("multi_pointer_slice_expr_error"),
	);

	for_array(i, c->info.definitions) {
		Entity *e = c->info.definitions[i];
		if (e->scope == builtin_pkg->scope) { // TODO(bill): is the check enough?
			if (e->type == nullptr) {
				add_dependency_to_set(c, e);
			}
		} else if (e->kind == Entity_Procedure && e->Procedure.is_export) {
			add_dependency_to_set(c, e);
		} else if (e->kind == Entity_Variable && e->Variable.is_export) {
			add_dependency_to_set(c, e);
		}
	}

	for (Entity *e; mpmc_dequeue(&c->info.required_foreign_imports_through_force_queue, &e); /**/) {
		array_add(&c->info.required_foreign_imports_through_force, e);
		add_dependency_to_set(c, e);
	}

	for (Entity *e; mpmc_dequeue(&c->info.required_global_variable_queue, &e); /**/) {
		e->flags |= EntityFlag_Used;
		add_dependency_to_set(c, e);
	}

	for_array(i, c->info.entities) {
		Entity *e = c->info.entities[i];
		switch (e->kind) {
		case Entity_Variable:
			if (e->Variable.is_export) {
				add_dependency_to_set(c, e);
			} else if (e->flags & EntityFlag_Require) {
				add_dependency_to_set(c, e);
			}
			break;
		case Entity_Procedure:
			if (e->Procedure.is_export) {
				add_dependency_to_set(c, e);
			} else if (e->flags & EntityFlag_Require) {
				add_dependency_to_set(c, e);
			}
			if (e->flags & EntityFlag_Init) {
				Type *t = base_type(e->type);
				GB_ASSERT(t->kind == Type_Proc);

				bool is_init = true;

				if (t->Proc.param_count != 0 || t->Proc.result_count != 0) {
					gbString str = type_to_string(t);
					error(e->token, "@(init) procedures must have a signature type with no parameters nor results, got %s", str);
					gb_string_free(str);
					is_init = false;
				}

				if ((e->scope->flags & (ScopeFlag_File|ScopeFlag_Pkg)) == 0) {
					error(e->token, "@(init) procedures must be declared at the file scope");
					is_init = false;
				}

				if (is_init) {
					add_dependency_to_set(c, e);
					array_add(&c->info.init_procedures, e);
				}
			}
			break;
		}
	}

	if (build_context.command_kind == Command_test) {
		AstPackage *testing_package = get_core_package(&c->info, str_lit("testing"));
		Scope *testing_scope = testing_package->scope;

		// Add all of testing library as a dependency
		for_array(i, testing_scope->elements.entries) {
			Entity *e = testing_scope->elements.entries[i].value;
			if (e != nullptr) {
				e->flags |= EntityFlag_Used;
				add_dependency_to_set(c, e);
			}
		}


		Entity *test_signature = scope_lookup_current(testing_scope, str_lit("Test_Signature"));


		AstPackage *pkg = c->info.init_package;
		Scope *s = pkg->scope;

		for_array(i, s->elements.entries) {
			Entity *e = s->elements.entries[i].value;
			if (e->kind != Entity_Procedure) {
				continue;
			}

			if ((e->flags & EntityFlag_Test) == 0) {
				continue;
			}

			String name = e->token.string;

			bool is_tester = true;

			Type *t = base_type(e->type);
			GB_ASSERT(t->kind == Type_Proc);
			if (are_types_identical(t, base_type(test_signature->type))) {
				// Good
			} else {
				gbString str = type_to_string(t);
				error(e->token, "Testing procedures must have a signature type of proc(^testing.T), got %s", str);
				gb_string_free(str);
				is_tester = false;
			}

			if (is_tester) {
				add_dependency_to_set(c, e);
				array_add(&c->info.testing_procedures, e);
			}
		}
	} else if (start != nullptr) {
		start->flags |= EntityFlag_Used;
		add_dependency_to_set(c, start);
	}

#undef FORCE_ADD_RUNTIME_ENTITIES
}

bool is_entity_a_dependency(Entity *e) {
	if (e == nullptr) return false;
	switch (e->kind) {
	case Entity_Procedure:
		return true;
	case Entity_Constant:
	case Entity_Variable:
		return e->pkg != nullptr;
	case Entity_TypeName:
		return false;
	}
	return false;
}

Array<EntityGraphNode *> generate_entity_dependency_graph(CheckerInfo *info, gbAllocator allocator) {
	PtrMap<Entity *, EntityGraphNode *> M = {};
	map_init(&M, allocator, info->entities.count);
	defer (map_destroy(&M));
	for_array(i, info->entities) {
		Entity *e = info->entities[i];
		if (is_entity_a_dependency(e)) {
			EntityGraphNode *n = gb_alloc_item(allocator, EntityGraphNode);
			n->entity = e;
			map_set(&M, e, n);
		}
	}

	TIME_SECTION("generate_entity_dependency_graph: Calculate edges for graph M - Part 1");
	// Calculate edges for graph M
	for_array(i, M.entries) {
		EntityGraphNode *n = M.entries[i].value;
		Entity *e = n->entity;

		DeclInfo *decl = decl_info_of_entity(e);
		GB_ASSERT(decl != nullptr);

		for_array(j, decl->deps.entries) {
			Entity *dep = decl->deps.entries[j].ptr;
			if (dep->flags & EntityFlag_Field) {
				continue;
			}
			GB_ASSERT(dep != nullptr);
			if (is_entity_a_dependency(dep)) {
				EntityGraphNode *m = map_must_get(&M, dep);
				entity_graph_node_set_add(&n->succ, m);
				entity_graph_node_set_add(&m->pred, n);
			}
		}
	}

	// TODO(bill): This could be multithreaded to improve performance
	// This means that the entity graph node set will have to be thread safe

	TIME_SECTION("generate_entity_dependency_graph: Calculate edges for graph M - Part 2");
	auto G = array_make<EntityGraphNode *>(allocator, 0, M.entries.count);

	for_array(i, M.entries) {
		auto *entry = &M.entries[i];
		auto *e = entry->key;
		EntityGraphNode *n = entry->value;

		if (e->kind == Entity_Procedure) {
			// Connect each pred 'p' of 'n' with each succ 's' and from
			// the procedure node
			for_array(j, n->pred.entries) {
				EntityGraphNode *p = n->pred.entries[j].ptr;

				// Ignore self-cycles
				if (p != n) {
					// Each succ 's' of 'n' becomes a succ of 'p', and
					// each pred 'p' of 'n' becomes a pred of 's'
					for_array(k, n->succ.entries) {
						EntityGraphNode *s = n->succ.entries[k].ptr;
						// Ignore self-cycles
						if (s != n) {
							if (p->entity->kind == Entity_Procedure &&
							    s->entity->kind == Entity_Procedure) {
							    	// NOTE(bill, 2020-11-15): Only care about variable initialization ordering
							    	// TODO(bill): This is probably wrong!!!!
								continue;
							}
							// IMPORTANT NOTE/TODO(bill, 2020-11-15): These three calls take the majority of the
							// the time to process

							entity_graph_node_set_add(&p->succ, s);
							entity_graph_node_set_add(&s->pred, p);
							// Remove edge to 'n'
							entity_graph_node_set_remove(&s->pred, n);
						}
					}

					// Remove edge to 'n'
					entity_graph_node_set_remove(&p->succ, n);
				}
			}
		} else if (e->kind == Entity_Variable) {
			array_add(&G, n);
		}
	}

	TIME_SECTION("generate_entity_dependency_graph: Dependency Count Checker");
	for_array(i, G) {
		EntityGraphNode *n = G[i];
		n->index = i;
		n->dep_count = n->succ.entries.count;
		GB_ASSERT(n->dep_count >= 0);
	}

	// f64 succ_count = 0.0;
	// f64 pred_count = 0.0;
	// f64 succ_capacity = 0.0;
	// f64 pred_capacity = 0.0;
	// f64 succ_max = 0.0;
	// f64 pred_max = 0.0;
	// for_array(i, G) {
	// 	EntityGraphNode *n = G[i];
	// 	succ_count += n->succ.entries.count;
	// 	pred_count += n->pred.entries.count;
	// 	succ_capacity += n->succ.entries.capacity;
	// 	pred_capacity += n->pred.entries.capacity;

	// 	succ_max = gb_max(succ_max, n->succ.entries.capacity);
	// 	pred_max = gb_max(pred_max, n->pred.entries.capacity);

	// }
	// f64 count = cast(f64)G.count;
	// gb_printf_err(">>>count    pred: %f succ: %f\n", pred_count/count, succ_count/count);
	// gb_printf_err(">>>capacity pred: %f succ: %f\n", pred_capacity/count, succ_capacity/count);
	// gb_printf_err(">>>max      pred: %f succ: %f\n", pred_max, succ_max);

	return G;
}


void check_single_global_entity(Checker *c, Entity *e, DeclInfo *d);


Entity *find_core_entity(Checker *c, String name) {
	Entity *e = scope_lookup_current(c->info.runtime_package->scope, name);
	if (e == nullptr) {
		compiler_error("Could not find type declaration for '%.*s'\n"
, LIT(name));
		// NOTE(bill): This will exit the program as it's cannot continue without it!
	}
	return e;
}

Type *find_core_type(Checker *c, String name) {
	Entity *e = scope_lookup_current(c->info.runtime_package->scope, name);
	if (e == nullptr) {
		compiler_error("Could not find type declaration for '%.*s'\n"
, LIT(name));
		// NOTE(bill): This will exit the program as it's cannot continue without it!
	}
	if (e->type == nullptr) {
		check_single_global_entity(c, e, e->decl_info);
	}
	GB_ASSERT(e->type != nullptr);
	return e->type;
}


Entity *find_entity_in_pkg(CheckerInfo *info, String const &pkg, String const &name) {
	AstPackage *package = get_core_package(info, pkg);
	Entity *e = scope_lookup_current(package->scope, name);
	if (e == nullptr) {
		compiler_error("Could not find type declaration for '%.*s.%.*s'\n", LIT(pkg), LIT(name));
		// NOTE(bill): This will exit the program as it's cannot continue without it!
	}
	return e;
}

Type *find_type_in_pkg(CheckerInfo *info, String const &pkg, String const &name) {
	AstPackage *package = get_core_package(info, pkg);
	Entity *e = scope_lookup_current(package->scope, name);
	if (e == nullptr) {
		compiler_error("Could not find type declaration for '%.*s.%.*s'\n", LIT(pkg), LIT(name));
		// NOTE(bill): This will exit the program as it's cannot continue without it!
	}
	GB_ASSERT(e->type != nullptr);
	return e->type;
}

CheckerTypePath *new_checker_type_path() {
	gbAllocator a = heap_allocator();
	auto *tp = gb_alloc_item(a, CheckerTypePath);
	array_init(tp, a, 0, 16);
	return tp;
}

void destroy_checker_type_path(CheckerTypePath *tp) {
	array_free(tp);
	gb_free(heap_allocator(), tp);
}


void check_type_path_push(CheckerContext *c, Entity *e) {
	GB_ASSERT(c->type_path != nullptr);
	GB_ASSERT(e != nullptr);
	array_add(c->type_path, e);
}
Entity *check_type_path_pop(CheckerContext *c) {
	GB_ASSERT(c->type_path != nullptr);
	return array_pop(c->type_path);
}


CheckerPolyPath *new_checker_poly_path(void) {
	gbAllocator a = heap_allocator();
	auto *pp = gb_alloc_item(a, CheckerPolyPath);
	array_init(pp, a, 0, 16);
	return pp;
}

void destroy_checker_poly_path(CheckerPolyPath *pp) {
	array_free(pp);
	gb_free(heap_allocator(), pp);
}


void check_poly_path_push(CheckerContext *c, Type *t) {
	GB_ASSERT(c->poly_path != nullptr);
	GB_ASSERT(t != nullptr);
	GB_ASSERT(is_type_polymorphic(t));
	array_add(c->poly_path, t);
}

Type *check_poly_path_pop(CheckerContext *c) {
	GB_ASSERT(c->poly_path != nullptr);
	return array_pop(c->poly_path);
}



Array<Entity *> proc_group_entities(CheckerContext *c, Operand o) {
	Array<Entity *> procs = {};
	if (o.mode == Addressing_ProcGroup) {
		GB_ASSERT(o.proc_group != nullptr);
		if (o.proc_group->kind == Entity_ProcGroup) {
			check_entity_decl(c, o.proc_group, nullptr, nullptr);
			return o.proc_group->ProcGroup.entities;
		}
	}
	return procs;
}

Array<Entity *> proc_group_entities_cloned(CheckerContext *c, Operand o) {
	auto entities = proc_group_entities(c, o);
	if (entities.count == 0) {
		return {};
	}
	return array_clone(permanent_allocator(), entities);
}




void init_core_type_info(Checker *c) {
	if (t_type_info != nullptr) {
		return;
	}
	Entity *type_info_entity = find_core_entity(c, str_lit("Type_Info"));

	t_type_info = type_info_entity->type;
	t_type_info_ptr = alloc_type_pointer(t_type_info);
	GB_ASSERT(is_type_struct(type_info_entity->type));
	TypeStruct *tis = &base_type(type_info_entity->type)->Struct;

	Entity *type_info_enum_value = find_core_entity(c, str_lit("Type_Info_Enum_Value"));

	t_type_info_enum_value = type_info_enum_value->type;
	t_type_info_enum_value_ptr = alloc_type_pointer(t_type_info_enum_value);

	GB_ASSERT(tis->fields.count == 5);

	Entity *type_info_variant = tis->fields[4];
	Type *tiv_type = type_info_variant->type;
	GB_ASSERT(is_type_union(tiv_type));

	t_type_info_named            = find_core_type(c, str_lit("Type_Info_Named"));
	t_type_info_integer          = find_core_type(c, str_lit("Type_Info_Integer"));
	t_type_info_rune             = find_core_type(c, str_lit("Type_Info_Rune"));
	t_type_info_float            = find_core_type(c, str_lit("Type_Info_Float"));
	t_type_info_quaternion       = find_core_type(c, str_lit("Type_Info_Quaternion"));
	t_type_info_complex          = find_core_type(c, str_lit("Type_Info_Complex"));
	t_type_info_string           = find_core_type(c, str_lit("Type_Info_String"));
	t_type_info_boolean          = find_core_type(c, str_lit("Type_Info_Boolean"));
	t_type_info_any              = find_core_type(c, str_lit("Type_Info_Any"));
	t_type_info_typeid           = find_core_type(c, str_lit("Type_Info_Type_Id"));
	t_type_info_pointer          = find_core_type(c, str_lit("Type_Info_Pointer"));
	t_type_info_multi_pointer    = find_core_type(c, str_lit("Type_Info_Multi_Pointer"));
	t_type_info_procedure        = find_core_type(c, str_lit("Type_Info_Procedure"));
	t_type_info_array            = find_core_type(c, str_lit("Type_Info_Array"));
	t_type_info_enumerated_array = find_core_type(c, str_lit("Type_Info_Enumerated_Array"));
	t_type_info_dynamic_array    = find_core_type(c, str_lit("Type_Info_Dynamic_Array"));
	t_type_info_slice            = find_core_type(c, str_lit("Type_Info_Slice"));
	t_type_info_tuple            = find_core_type(c, str_lit("Type_Info_Tuple"));
	t_type_info_struct           = find_core_type(c, str_lit("Type_Info_Struct"));
	t_type_info_union            = find_core_type(c, str_lit("Type_Info_Union"));
	t_type_info_enum             = find_core_type(c, str_lit("Type_Info_Enum"));
	t_type_info_map              = find_core_type(c, str_lit("Type_Info_Map"));
	t_type_info_bit_set          = find_core_type(c, str_lit("Type_Info_Bit_Set"));
	t_type_info_simd_vector      = find_core_type(c, str_lit("Type_Info_Simd_Vector"));
	t_type_info_relative_pointer = find_core_type(c, str_lit("Type_Info_Relative_Pointer"));
	t_type_info_relative_slice   = find_core_type(c, str_lit("Type_Info_Relative_Slice"));
	t_type_info_matrix           = find_core_type(c, str_lit("Type_Info_Matrix"));
	t_type_info_soa_pointer      = find_core_type(c, str_lit("Type_Info_Soa_Pointer"));

	t_type_info_named_ptr            = alloc_type_pointer(t_type_info_named);
	t_type_info_integer_ptr          = alloc_type_pointer(t_type_info_integer);
	t_type_info_rune_ptr             = alloc_type_pointer(t_type_info_rune);
	t_type_info_float_ptr            = alloc_type_pointer(t_type_info_float);
	t_type_info_quaternion_ptr       = alloc_type_pointer(t_type_info_quaternion);
	t_type_info_complex_ptr          = alloc_type_pointer(t_type_info_complex);
	t_type_info_string_ptr           = alloc_type_pointer(t_type_info_string);
	t_type_info_boolean_ptr          = alloc_type_pointer(t_type_info_boolean);
	t_type_info_any_ptr              = alloc_type_pointer(t_type_info_any);
	t_type_info_typeid_ptr           = alloc_type_pointer(t_type_info_typeid);
	t_type_info_pointer_ptr          = alloc_type_pointer(t_type_info_pointer);
	t_type_info_multi_pointer_ptr    = alloc_type_pointer(t_type_info_multi_pointer);
	t_type_info_procedure_ptr        = alloc_type_pointer(t_type_info_procedure);
	t_type_info_array_ptr            = alloc_type_pointer(t_type_info_array);
	t_type_info_enumerated_array_ptr = alloc_type_pointer(t_type_info_enumerated_array);
	t_type_info_dynamic_array_ptr    = alloc_type_pointer(t_type_info_dynamic_array);
	t_type_info_slice_ptr            = alloc_type_pointer(t_type_info_slice);
	t_type_info_tuple_ptr            = alloc_type_pointer(t_type_info_tuple);
	t_type_info_struct_ptr           = alloc_type_pointer(t_type_info_struct);
	t_type_info_union_ptr            = alloc_type_pointer(t_type_info_union);
	t_type_info_enum_ptr             = alloc_type_pointer(t_type_info_enum);
	t_type_info_map_ptr              = alloc_type_pointer(t_type_info_map);
	t_type_info_bit_set_ptr          = alloc_type_pointer(t_type_info_bit_set);
	t_type_info_simd_vector_ptr      = alloc_type_pointer(t_type_info_simd_vector);
	t_type_info_relative_pointer_ptr = alloc_type_pointer(t_type_info_relative_pointer);
	t_type_info_relative_slice_ptr   = alloc_type_pointer(t_type_info_relative_slice);
	t_type_info_matrix_ptr           = alloc_type_pointer(t_type_info_matrix);
	t_type_info_soa_pointer_ptr      = alloc_type_pointer(t_type_info_soa_pointer);
}

void init_mem_allocator(Checker *c) {
	if (t_allocator != nullptr) {
		return;
	}
	t_allocator = find_core_type(c, str_lit("Allocator"));
	t_allocator_ptr = alloc_type_pointer(t_allocator);
	t_allocator_error = find_core_type(c, str_lit("Allocator_Error"));
}

void init_core_context(Checker *c) {
	if (t_context != nullptr) {
		return;
	}
	t_context = find_core_type(c, str_lit("Context"));
	t_context_ptr = alloc_type_pointer(t_context);
}

void init_core_source_code_location(Checker *c) {
	if (t_source_code_location != nullptr) {
		return;
	}
	t_source_code_location = find_core_type(c, str_lit("Source_Code_Location"));
	t_source_code_location_ptr = alloc_type_pointer(t_allocator);
}

void init_core_map_type(Checker *c) {
	if (t_map_hash == nullptr) {
		Entity *e = find_core_entity(c, str_lit("Map_Hash"));
		if (e->state == EntityState_Unresolved) {
			check_entity_decl(&c->builtin_ctx, e, nullptr, nullptr);
		}
		t_map_hash = e->type;
		GB_ASSERT(t_map_hash != nullptr);
	}

	if (t_map_header == nullptr) {
		Entity *e = find_core_entity(c, str_lit("Map_Header"));
		if (e->state == EntityState_Unresolved) {
			check_entity_decl(&c->builtin_ctx, e, nullptr, nullptr);
		}
		t_map_header = e->type;
		GB_ASSERT(t_map_header != nullptr);
	}
}

void init_preload(Checker *c) {
	init_core_type_info(c);
	init_mem_allocator(c);
	init_core_context(c);
	init_core_source_code_location(c);
	init_core_map_type(c);
}

ExactValue check_decl_attribute_value(CheckerContext *c, Ast *value) {
	ExactValue ev = {};
	if (value != nullptr) {
		Operand op = {};
		check_expr(c, &op, value);
		if (op.mode) {
			if (op.mode == Addressing_Constant) {
				ev = op.value;
			} else {
				error(value, "Expected a constant attribute element");
			}
		}
	}
	return ev;
}

Type *check_decl_attribute_type(CheckerContext *c, Ast *value) {
	if (value != nullptr) {
		return check_type(c, value);
	}
	return nullptr;
}


#define ATTRIBUTE_USER_TAG_NAME "tag"


DECL_ATTRIBUTE_PROC(foreign_block_decl_attribute) {
	ExactValue ev = check_decl_attribute_value(c, value);

	if (name == ATTRIBUTE_USER_TAG_NAME) {
		if (ev.kind != ExactValue_String) {
			error(elem, "Expected a string value for '%.*s'", LIT(name));
		}
		return true;
	} else if (name == "default_calling_convention") {
		if (ev.kind == ExactValue_String) {
			auto cc = string_to_calling_convention(ev.value_string);
			if (cc == ProcCC_Invalid) {
				error(elem, "Unknown procedure calling convention: '%.*s'", LIT(ev.value_string));
			} else {
				c->foreign_context.default_cc = cc;
			}
		} else {
			error(elem, "Expected a string value for '%.*s'", LIT(name));
		}
		return true;
	} else if (name == "link_prefix") {
		if (ev.kind == ExactValue_String) {
			String link_prefix = ev.value_string;
			if (!is_foreign_name_valid(link_prefix)) {
				error(elem, "Invalid link prefix: '%.*s'", LIT(link_prefix));
			} else {
				c->foreign_context.link_prefix = link_prefix;
			}
		} else {
			error(elem, "Expected a string value for '%.*s'", LIT(name));
		}
		return true;
	} else if (name == "private") {
		EntityVisiblityKind kind = EntityVisiblity_PrivateToPackage;
		if (ev.kind == ExactValue_Invalid) {
			// Okay
		} else if (ev.kind == ExactValue_String) {
			String v = ev.value_string;
			if (v == "file") {
				kind = EntityVisiblity_PrivateToFile;
			} else if (v == "package") {
				kind = EntityVisiblity_PrivateToPackage;
			} else {
				error(value, "'%.*s'  expects no parameter, or a string literal containing \"file\" or \"package\"", LIT(name));
			}
		} else {
			error(value, "'%.*s'  expects no parameter, or a string literal containing \"file\" or \"package\"", LIT(name));
		}
		c->foreign_context.visibility_kind = kind;
		return true;
	}

	return false;
}

DECL_ATTRIBUTE_PROC(proc_decl_attribute) {
	if (name == ATTRIBUTE_USER_TAG_NAME) {
		ExactValue ev = check_decl_attribute_value(c, value);
		if (ev.kind != ExactValue_String) {
			error(elem, "Expected a string value for '%.*s'", LIT(name));
		}
		return true;
	} else if (name == "test") {
		if (value != nullptr) {
			error(value, "'%.*s' expects no parameter, or a string literal containing \"file\" or \"package\"", LIT(name));
		}
		ac->test = true;
		return true;
	} else if (name == "export") {
		ExactValue ev = check_decl_attribute_value(c, value);
		if (ev.kind == ExactValue_Invalid) {
			ac->is_export = true;
		} else if (ev.kind == ExactValue_Bool) {
			ac->is_export = ev.value_bool;
		} else {
			error(value, "Expected either a boolean or no parameter for 'export'");
			return false;
		}
		return true;
	} else if (name == "linkage") {
		ExactValue ev = check_decl_attribute_value(c, value);
		if (ev.kind != ExactValue_String) {
			error(value, "Expected either a string 'linkage'");
			return false;
		}
		String linkage = ev.value_string;
		if (linkage == "internal" ||
		    linkage == "strong" ||
		    linkage == "weak" ||
		    linkage == "link_once") {
			ac->linkage = linkage;
		} else {
			error(elem, "Invalid linkage '%.*s'. Valid kinds:", LIT(linkage));
			error_line("\tinternal\n");
			error_line("\tstrong\n");
			error_line("\tweak\n");
			error_line("\tlink_once\n");
		}
		return true;
	} else if (name == "require") {
		ExactValue ev = check_decl_attribute_value(c, value);
		if (ev.kind == ExactValue_Invalid) {
			ac->require_declaration = true;
		} else if (ev.kind == ExactValue_Bool) {
			ac->require_declaration = ev.value_bool;
		} else {
			error(value, "Expected either a boolean or no parameter for 'require'");
		}
		return true;
	} else if (name == "init") {
		if (value != nullptr) {
			error(value, "'%.*s' expects no parameter, or a string literal containing \"file\" or \"package\"", LIT(name));
		}
		ac->init = true;
		return true;
	} else if (name == "deferred") {
		if (value != nullptr) {
			Operand o = {};
			check_expr(c, &o, value);
			Entity *e = entity_of_node(o.expr);
			if (e != nullptr && e->kind == Entity_Procedure) {
				warning(elem, "'%.*s' is deprecated, please use one of the following instead: 'deferred_none', 'deferred_in', 'deferred_out'", LIT(name));
				if (ac->deferred_procedure.entity != nullptr) {
					error(elem, "Previous usage of a 'deferred_*' attribute");
				}
				ac->deferred_procedure.kind = DeferredProcedure_out;
				ac->deferred_procedure.entity = e;
				return true;
			}
		}
		error(elem, "Expected a procedure entity for '%.*s'", LIT(name));
		return false;
	} else if (name == "deferred_none") {
		if (value != nullptr) {
			Operand o = {};
			check_expr(c, &o, value);
			Entity *e = entity_of_node(o.expr);
			if (e != nullptr && e->kind == Entity_Procedure) {
				ac->deferred_procedure.kind = DeferredProcedure_none;
				ac->deferred_procedure.entity = e;
				return true;
			}
		}
		error(elem, "Expected a procedure entity for '%.*s'", LIT(name));
		return false;
	} else if (name == "deferred_in") {
		if (value != nullptr) {
			Operand o = {};
			check_expr(c, &o, value);
			Entity *e = entity_of_node(o.expr);
			if (e != nullptr && e->kind == Entity_Procedure) {
				if (ac->deferred_procedure.entity != nullptr) {
					error(elem, "Previous usage of a 'deferred_*' attribute");
				}
				ac->deferred_procedure.kind = DeferredProcedure_in;
				ac->deferred_procedure.entity = e;
				return true;
			}
		}
		error(elem, "Expected a procedure entity for '%.*s'", LIT(name));
		return false;
	} else if (name == "deferred_out") {
		if (value != nullptr) {
			Operand o = {};
			check_expr(c, &o, value);
			Entity *e = entity_of_node(o.expr);
			if (e != nullptr && e->kind == Entity_Procedure) {
				if (ac->deferred_procedure.entity != nullptr) {
					error(elem, "Previous usage of a 'deferred_*' attribute");
				}
				ac->deferred_procedure.kind = DeferredProcedure_out;
				ac->deferred_procedure.entity = e;
				return true;
			}
		}
		error(elem, "Expected a procedure entity for '%.*s'", LIT(name));
		return false;
	} else if (name == "deferred_in_out") {
		if (value != nullptr) {
			Operand o = {};
			check_expr(c, &o, value);
			Entity *e = entity_of_node(o.expr);
			if (e != nullptr && e->kind == Entity_Procedure) {
				if (ac->deferred_procedure.entity != nullptr) {
					error(elem, "Previous usage of a 'deferred_*' attribute");
				}
				ac->deferred_procedure.kind = DeferredProcedure_in_out;
				ac->deferred_procedure.entity = e;
				return true;
			}
		}
		error(elem, "Expected a procedure entity for '%.*s'", LIT(name));
		return false;
	} else if (name == "link_name") {
		ExactValue ev = check_decl_attribute_value(c, value);

		if (ev.kind == ExactValue_String) {
			ac->link_name = ev.value_string;
			if (!is_foreign_name_valid(ac->link_name)) {
				error(elem, "Invalid link name: %.*s", LIT(ac->link_name));
			}
		} else {
			error(elem, "Expected a string value for '%.*s'", LIT(name));
		}
		return true;
	} else if (name == "link_prefix") {
		ExactValue ev = check_decl_attribute_value(c, value);

		if (ev.kind == ExactValue_String) {
			ac->link_prefix = ev.value_string;
			if (!is_foreign_name_valid(ac->link_prefix)) {
				error(elem, "Invalid link prefix: %.*s", LIT(ac->link_prefix));
			}
		} else {
			error(elem, "Expected a string value for '%.*s'", LIT(name));
		}
		return true;
	} else if (name == "deprecated") {
		ExactValue ev = check_decl_attribute_value(c, value);

		if (ev.kind == ExactValue_String) {
			String msg = ev.value_string;
			if (msg.len == 0) {
				error(elem, "Deprecation message cannot be an empty string");
			} else {
				ac->deprecated_message = msg;
			}
		} else {
			error(elem, "Expected a string value for '%.*s'", LIT(name));
		}
		return true;
	} else if (name == "warning") {
		ExactValue ev = check_decl_attribute_value(c, value);

		if (ev.kind == ExactValue_String) {
			String msg = ev.value_string;
			if (msg.len == 0) {
				error(elem, "Warning message cannot be an empty string");
			} else {
				ac->warning_message = msg;
			}
		} else {
			error(elem, "Expected a string value for '%.*s'", LIT(name));
		}
		return true;
	} else if (name == "require_results") {
		if (value != nullptr) {
			error(elem, "Expected no value for '%.*s'", LIT(name));
		}
		ac->require_results = true;
		return true;
	} else if (name == "disabled") {
		ExactValue ev = check_decl_attribute_value(c, value);

		if (ev.kind == ExactValue_Bool) {
			ac->has_disabled_proc = true;
			ac->disabled_proc = ev.value_bool;
		} else {
			error(elem, "Expected a boolean value for '%.*s'", LIT(name));
		}
		return true;
	} else if (name == "cold") {
		if (value == nullptr) {
			ac->set_cold = true;
		} else {
			ExactValue ev = check_decl_attribute_value(c, value);
			if (ev.kind == ExactValue_Bool) {
				ac->set_cold = ev.value_bool;
			} else {
				error(elem, "Expected a boolean value for '%.*s' or no value whatsoever", LIT(name));
			}
		}
		return true;
	} else if (name == "optimization_mode") {
		ExactValue ev = check_decl_attribute_value(c, value);
		if (ev.kind == ExactValue_String) {
			String mode = ev.value_string;
			if (mode == "none") {
				ac->optimization_mode = ProcedureOptimizationMode_None;
			} else if (mode == "minimal") {
				ac->optimization_mode = ProcedureOptimizationMode_Minimal;
			} else if (mode == "size") {
				ac->optimization_mode = ProcedureOptimizationMode_Size;
			} else if (mode == "speed") {
				ac->optimization_mode = ProcedureOptimizationMode_Speed;
			} else {
				error(elem, "Invalid optimization_mode for '%.*s'. Valid modes:", LIT(name));
				error_line("\tnone\n");
				error_line("\tminimal\n");
				error_line("\tsize\n");
				error_line("\tspeed\n");
			}
		} else {
			error(elem, "Expected a string for '%.*s'", LIT(name));
		}
		return true;
	} else if (name == "objc_name") {
		ExactValue ev = check_decl_attribute_value(c, value);
		if (ev.kind == ExactValue_String) {
			if (string_is_valid_identifier(ev.value_string)) {
				ac->objc_name = ev.value_string;
			} else {
				error(elem, "Invalid identifier for '%.*s', got '%.*s'", LIT(name), LIT(ev.value_string));
			}
		} else {
			error(elem, "Expected a string value for '%.*s'", LIT(name));
		}
		return true;
	} else if (name == "objc_is_class_method") {
		ExactValue ev = check_decl_attribute_value(c, value);
		if (ev.kind == ExactValue_Bool) {
			ac->objc_is_class_method = ev.value_bool;
		} else {
			error(elem, "Expected a boolean value for '%.*s'", LIT(name));
		}
		return true;
	} else if (name == "objc_type") {
		if (value == nullptr) {
			error(elem, "Expected a type for '%.*s'", LIT(name));
		} else {
			Type *objc_type = check_type(c, value);
			if (objc_type != nullptr) {
				if (!has_type_got_objc_class_attribute(objc_type)) {
					gbString t = type_to_string(objc_type);
					error(value, "'%.*s' expected a named type with the attribute @(obj_class=<string>), got type %s", LIT(name), t);
					gb_string_free(t);
				} else {
					ac->objc_type = objc_type;
				}
			}
		}
		return true;
	} else if (name == "require_target_feature") {
		ExactValue ev = check_decl_attribute_value(c, value);
		if (ev.kind == ExactValue_String) {
			ac->require_target_feature = ev.value_string;
		} else {
			error(elem, "Expected a string value for '%.*s'", LIT(name));
		}
		return true;
	} else if (name == "enable_target_feature") {
		ExactValue ev = check_decl_attribute_value(c, value);
		if (ev.kind == ExactValue_String) {
			ac->enable_target_feature = ev.value_string;
		} else {
			error(elem, "Expected a string value for '%.*s'", LIT(name));
		}
		return true;
	}
	return false;
}

DECL_ATTRIBUTE_PROC(var_decl_attribute) {
	ExactValue ev = check_decl_attribute_value(c, value);

	if (name == ATTRIBUTE_USER_TAG_NAME) {
		if (ev.kind != ExactValue_String) {
			error(elem, "Expected a string value for '%.*s'", LIT(name));
		}
		return true;
	} else if (name == "static") {
		if (value != nullptr) {
			error(elem, "'static' does not have any parameters");
		}
		ac->is_static = true;
		return true;
	} else if (name == "thread_local") {
		if (ac->init_expr_list_count > 0) {
			error(elem, "A thread local variable declaration cannot have initialization values");
		} else if (c->foreign_context.curr_library) {
			error(elem, "A foreign block variable cannot be thread local");
		} else if (ac->is_export) {
			error(elem, "An exported variable cannot be thread local");
		} else if (ev.kind == ExactValue_Invalid) {
			ac->thread_local_model = str_lit("default");
		} else if (ev.kind == ExactValue_String) {
			String model = ev.value_string;
			if (model == "default" ||
			    model == "localdynamic" ||
			    model == "initialexec" ||
			    model == "localexec") {
				ac->thread_local_model = model;
			} else {
				error(elem, "Invalid thread local model '%.*s'. Valid models:", LIT(model));
				error_line("\tdefault\n");
				error_line("\tlocaldynamic\n");
				error_line("\tinitialexec\n");
				error_line("\tlocalexec\n");
			}
		} else {
			error(elem, "Expected either no value or a string for '%.*s'", LIT(name));
		}
		return true;
	}

	if (c->curr_proc_decl != nullptr) {
		error(elem, "Only a variable at file scope can have a '%.*s'", LIT(name));
		return true;
	}

	if (name == "require") {
		if (value != nullptr) {
			error(elem, "'require' does not have any parameters");
		}
		ac->require_declaration = true;
		return true;
	} else if (name == "export") {
		ExactValue ev = check_decl_attribute_value(c, value);
		if (ev.kind == ExactValue_Invalid) {
			ac->is_export = true;
		} else if (ev.kind == ExactValue_Bool) {
			ac->is_export = ev.value_bool;
		} else {
			error(value, "Expected either a boolean or no parameter for 'export'");
			return false;
		}
		if (ac->thread_local_model != "") {
			error(elem, "An exported variable cannot be thread local");
		}
		return true;
	} else if (name == "linkage") {
		ExactValue ev = check_decl_attribute_value(c, value);
		if (ev.kind != ExactValue_String) {
			error(value, "Expected either a string 'linkage'");
			return false;
		}
		String linkage = ev.value_string;
		if (linkage == "internal" ||
		    linkage == "strong" ||
		    linkage == "weak" ||
		    linkage == "link_once") {
			ac->linkage = linkage;
		} else {
			error(elem, "Invalid linkage '%.*s'. Valid kinds:", LIT(linkage));
			error_line("\tinternal\n");
			error_line("\tstrong\n");
			error_line("\tweak\n");
			error_line("\tlink_once\n");
		}
		return true;
	} else if (name == "link_name") {
		if (ev.kind == ExactValue_String) {
			ac->link_name = ev.value_string;
			if (!is_foreign_name_valid(ac->link_name)) {
				error(elem, "Invalid link name: %.*s", LIT(ac->link_name));
			}
		} else {
			error(elem, "Expected a string value for '%.*s'", LIT(name));
		}
		return true;
	} else if (name == "link_prefix") {
		if (ev.kind == ExactValue_String) {
			ac->link_prefix = ev.value_string;
			if (!is_foreign_name_valid(ac->link_prefix)) {
				error(elem, "Invalid link prefix: %.*s", LIT(ac->link_prefix));
			}
		} else {
			error(elem, "Expected a string value for '%.*s'", LIT(name));
		}
		return true;
	} else if (name == "link_section") {
		if (ev.kind == ExactValue_String) {
			ac->link_section = ev.value_string;
			if (!is_foreign_name_valid(ac->link_section)) {
				error(elem, "Invalid link section: %.*s", LIT(ac->link_section));
			}
		} else {
			error(elem, "Expected a string value for '%.*s'", LIT(name));
		}
		return true;
	}
	return false;
}

DECL_ATTRIBUTE_PROC(const_decl_attribute) {
	if (name == ATTRIBUTE_USER_TAG_NAME) {
		ExactValue ev = check_decl_attribute_value(c, value);
		if (ev.kind != ExactValue_String) {
			error(elem, "Expected a string value for '%.*s'", LIT(name));
		}
		return true;
	} else if (name == "private") {
		// NOTE(bill): Handled elsewhere `check_collect_value_decl`
		return true;
	}
	return false;
}

DECL_ATTRIBUTE_PROC(type_decl_attribute) {
	if (name == ATTRIBUTE_USER_TAG_NAME) {
		ExactValue ev = check_decl_attribute_value(c, value);
		if (ev.kind != ExactValue_String) {
			error(elem, "Expected a string value for '%.*s'", LIT(name));
		}
		return true;
	} else if (name == "private") {
		// NOTE(bill): Handled elsewhere `check_collect_value_decl`
		return true;
	} else if (name == "objc_class") {
		ExactValue ev = check_decl_attribute_value(c, value);
		if (ev.kind != ExactValue_String || ev.value_string == "") {
			error(elem, "Expected a non-empty string value for '%.*s'", LIT(name));
		} else {
			ac->objc_class = ev.value_string;
		}
		return true;
	}
	return false;
}


#include "check_expr.cpp"
#include "check_builtin.cpp"
#include "check_type.cpp"
#include "check_decl.cpp"
#include "check_stmt.cpp"



void check_decl_attributes(CheckerContext *c, Array<Ast *> const &attributes, DeclAttributeProc *proc, AttributeContext *ac) {
	if (attributes.count == 0) return;

	String original_link_prefix = {};
	if (ac) {
		original_link_prefix = ac->link_prefix;
	}

	StringSet set = {};
	string_set_init(&set, heap_allocator());
	defer (string_set_destroy(&set));

	for_array(i, attributes) {
		Ast *attr = attributes[i];
		if (attr->kind != Ast_Attribute) continue;
		for_array(j, attr->Attribute.elems) {
			Ast *elem = attr->Attribute.elems[j];
			String name = {};
			Ast *value = nullptr;

			switch (elem->kind) {
			case_ast_node(i, Ident, elem);
				name = i->token.string;
			case_end;
			case_ast_node(i, Implicit, elem);
				name = i->string;
			case_end;
			case_ast_node(fv, FieldValue, elem);
				if (fv->field->kind == Ast_Ident) {
					name = fv->field->Ident.token.string;
				} else if (fv->field->kind == Ast_Implicit) {
					name = fv->field->Implicit.string;
				} else {
					GB_PANIC("Unknown Field Value name");
				}
				value = fv->value;
			case_end;
			default:
				error(elem, "Invalid attribute element");
				continue;
			}

			if (string_set_exists(&set, name)) {
				error(elem, "Previous declaration of '%.*s'", LIT(name));
				continue;
			} else {
				string_set_add(&set, name);
			}

			if (!proc(c, elem, name, value, ac)) {
				if (!build_context.ignore_unknown_attributes) {
					error(elem, "Unknown attribute element name '%.*s'", LIT(name));
				}
			}
		}
	}

	if (ac) {
		if (ac->link_prefix.text == original_link_prefix.text) {
			if (ac->link_name.len > 0) {
				ac->link_prefix.text = nullptr;
				ac->link_prefix.len  = 0;
			}
		}
	}
}


isize get_total_value_count(Slice<Ast *> const &values) {
	isize count = 0;
	for_array(i, values) {
		Type *t = type_of_expr(values[i]);
		if (t == nullptr) {
			count += 1;
			continue;
		}
		t = core_type(t);
		if (t->kind == Type_Tuple) {
			count += t->Tuple.variables.count;
		} else {
			count += 1;
		}
	}
	return count;
}

bool check_arity_match(CheckerContext *c, AstValueDecl *vd, bool is_global) {
	isize lhs = vd->names.count;
	isize rhs = 0;
	if (is_global) {
		// NOTE(bill): Disallow global variables to be multi-valued for a few reasons
		rhs = vd->values.count;
	} else {
		rhs = get_total_value_count(vd->values);
	}

	if (rhs == 0) {
		if (vd->type == nullptr) {
			error(vd->names[0], "Missing type or initial expression");
			return false;
		}
	} else if (lhs < rhs) {
		if (lhs < vd->values.count) {
			Ast *n = vd->values[lhs];
			gbString str = expr_to_string(n);
			error(n, "Extra initial expression '%s'", str);
			gb_string_free(str);
		} else {
			error(vd->names[0], "Extra initial expression");
		}
		return false;
	} else if (lhs > rhs) {
		if (!is_global && rhs != 1) {
			Ast *n = vd->names[rhs];
			gbString str = expr_to_string(n);
			error(n, "Missing expression for '%s'", str);
			gb_string_free(str);
			return false;
		} else if (is_global) {
			Ast *n = vd->values[rhs-1];
			error(n, "Expected %td expressions on the right hand side, got %td", lhs, rhs);
			error_line("Note: Global declarations do not allow for multi-valued expressions");
			return false;
		}
	}

	return true;
}

void check_collect_entities_from_when_stmt(CheckerContext *c, AstWhenStmt *ws) {
	Operand operand = {Addressing_Invalid};
	if (!ws->is_cond_determined) {
		check_expr(c, &operand, ws->cond);
		if (operand.mode != Addressing_Invalid && !is_type_boolean(operand.type)) {
			error(ws->cond, "Non-boolean condition in 'when' statement");
		}
		if (operand.mode != Addressing_Constant) {
			error(ws->cond, "Non-constant condition in 'when' statement");
		}

		ws->is_cond_determined = true;
		ws->determined_cond = operand.value.kind == ExactValue_Bool && operand.value.value_bool;
	}

	if (ws->body == nullptr || ws->body->kind != Ast_BlockStmt) {
		error(ws->cond, "Invalid body for 'when' statement");
	} else {
		if (ws->determined_cond) {
			check_collect_entities(c, ws->body->BlockStmt.stmts);
		} else if (ws->else_stmt) {
			switch (ws->else_stmt->kind) {
			case Ast_BlockStmt:
				check_collect_entities(c, ws->else_stmt->BlockStmt.stmts);
				break;
			case Ast_WhenStmt:
				check_collect_entities_from_when_stmt(c, &ws->else_stmt->WhenStmt);
				break;
			default:
				error(ws->else_stmt, "Invalid 'else' statement in 'when' statement");
				break;
			}
		}
	}
}

void check_builtin_attributes(CheckerContext *ctx, Entity *e, Array<Ast *> *attributes) {
	switch (e->kind) {
	case Entity_ProcGroup:
	case Entity_Procedure:
	case Entity_TypeName:
		// Okay
		break;
	default:
		return;
	}
	if (!((ctx->scope->flags&ScopeFlag_File) && ctx->scope->file->pkg->kind == Package_Runtime)) {
		return;
	}

	for_array(j, *attributes) {
		Ast *attr = (*attributes)[j];
		if (attr->kind != Ast_Attribute) continue;
		for (isize k = 0; k < attr->Attribute.elems.count; k++) {
			Ast *elem = attr->Attribute.elems[k];
			String name = {};
			Ast *value = nullptr;

			switch (elem->kind) {
			case_ast_node(i, Ident, elem);
				name = i->token.string;
			case_end;
			case_ast_node(fv, FieldValue, elem);
				GB_ASSERT(fv->field->kind == Ast_Ident);
				name = fv->field->Ident.token.string;
				value = fv->value;
			case_end;
			default:
				continue;
			}

			if (name == "builtin") {
				mutex_lock(&ctx->info->builtin_mutex);
				add_entity(ctx, builtin_pkg->scope, nullptr, e);
				GB_ASSERT(scope_lookup(builtin_pkg->scope, e->token.string) != nullptr);
				if (value != nullptr) {
					error(value, "'builtin' cannot have a field value");
				}
				// Remove the builtin tag
				attr->Attribute.elems[k] = attr->Attribute.elems[attr->Attribute.elems.count-1];
				attr->Attribute.elems.count -= 1;
				k--;

				mutex_unlock(&ctx->info->builtin_mutex);
			}
		}
	}

	for (isize i = 0; i < attributes->count; i++) {
		Ast *attr = (*attributes)[i];
		if (attr->kind != Ast_Attribute) continue;
		if (attr->Attribute.elems.count == 0) {
			(*attributes)[i] = (*attributes)[attributes->count-1];
			attributes->count--;
			i--;
		}
	}
}

void check_collect_value_decl(CheckerContext *c, Ast *decl) {
	if (decl->state_flags & StateFlag_BeenHandled) return;
	decl->state_flags |= StateFlag_BeenHandled;

	ast_node(vd, ValueDecl, decl);

	EntityVisiblityKind entity_visibility_kind = c->foreign_context.visibility_kind;
	bool is_test = false;
	bool is_init = false;

	for_array(i, vd->attributes) {
		Ast *attr = vd->attributes[i];
		if (attr->kind != Ast_Attribute) continue;
		auto *elems = &attr->Attribute.elems;
		for (isize j = 0; j < elems->count; j++) {
			Ast *elem = (*elems)[j];
			String name = {};
			Ast *value = nullptr;
			switch (elem->kind) {
			case_ast_node(i, Ident, elem);
				name = i->token.string;
			case_end;
			case_ast_node(fv, FieldValue, elem);
				GB_ASSERT(fv->field->kind == Ast_Ident);
				name = fv->field->Ident.token.string;
				value = fv->value;
			case_end;
			default:
				continue;
			}

			if (name == "private") {
				EntityVisiblityKind kind = EntityVisiblity_PrivateToPackage;
				bool success = false;
				if (value != nullptr) {
					if (value->kind == Ast_BasicLit && value->BasicLit.token.kind == Token_String) {
						String v = {};
						if (value->tav.value.kind == ExactValue_String) {
							v = value->tav.value.value_string;
						}
						if (v == "file") {
							kind = EntityVisiblity_PrivateToFile;
							success = true;
						} else if (v == "package") {
							kind = EntityVisiblity_PrivateToPackage;
							success = true;
						}
					}
				} else {
					success = true;
				}
				if (!success) {
					error(value, "'%.*s' expects no parameter, or a string literal containing \"file\" or \"package\"", LIT(name));
				}



				if (entity_visibility_kind >= kind) {
					error(elem, "Previous declaration of '%.*s'", LIT(name));
				} else {
					entity_visibility_kind = kind;
				}
				slice_unordered_remove(elems, j);
				j -= 1;
			} else if (name == "test") {
				is_test = true;
			} else if (name == "init") {
				is_init = true;
			}
		}
	}

	if (entity_visibility_kind == EntityVisiblity_Public &&
	    (c->scope->flags&ScopeFlag_File) &&
	    c->scope->file) {
	    	if (c->scope->file->flags & AstFile_IsPrivateFile) {
			entity_visibility_kind = EntityVisiblity_PrivateToFile;
		} else if (c->scope->file->flags & AstFile_IsPrivatePkg) {
			entity_visibility_kind = EntityVisiblity_PrivateToPackage;
	    	}
	}

	if (entity_visibility_kind != EntityVisiblity_Public && !(c->scope->flags&ScopeFlag_File)) {
		error(decl, "Attribute 'private' is not allowed on a non file scope entity");
	}


	if (vd->is_mutable) {
		if (!(c->scope->flags&ScopeFlag_File)) {
			// NOTE(bill): local scope -> handle later and in order
			return;
		}

		for_array(i, vd->names) {
			Ast *name = vd->names[i];
			Ast *value = nullptr;
			if (i < vd->values.count) {
				value = vd->values[i];
			}
			if (name->kind != Ast_Ident) {
				error(name, "A declaration's name must be an identifier, got %.*s", LIT(ast_strings[name->kind]));
				continue;
			}
			Entity *e = alloc_entity_variable(c->scope, name->Ident.token, nullptr);
			e->identifier = name;
			e->file = c->file;

			if (entity_visibility_kind != EntityVisiblity_Public) {
				e->flags |= EntityFlag_NotExported;
			}

			if (vd->is_using) {
				vd->is_using = false; // NOTE(bill): This error will be only caught once
				error(name, "'using' is not allowed at the file scope");
			}

			Ast *fl = c->foreign_context.curr_library;
			if (fl != nullptr) {
				GB_ASSERT(fl->kind == Ast_Ident);
				e->Variable.is_foreign = true;
				e->Variable.foreign_library_ident = fl;

				e->Variable.link_prefix = c->foreign_context.link_prefix;
			}

			Ast *init_expr = value;
			DeclInfo *d = make_decl_info(c->scope, c->decl);
			d->decl_node = decl;
			d->comment = vd->comment;
			d->docs    = vd->docs;
			d->entity    = e;
			d->type_expr = vd->type;
			d->init_expr = init_expr;
			d->attributes = vd->attributes;

			bool is_exported = entity_visibility_kind != EntityVisiblity_PrivateToFile;
			add_entity_and_decl_info(c, name, e, d, is_exported);
		}

		check_arity_match(c, vd, true);
	} else {
		for_array(i, vd->names) {
			Ast *name = vd->names[i];
			if (name->kind != Ast_Ident) {
				error(name, "A declaration's name must be an identifier, got %.*s", LIT(ast_strings[name->kind]));
				continue;
			}

			Ast *init = unparen_expr(vd->values[i]);
			if (init == nullptr) {
				error(name, "Expected a value for this constant value declaration");
				continue;
			}

			Token token = name->Ident.token;

			Ast *fl = c->foreign_context.curr_library;
			Entity *e = nullptr;
			DeclInfo *d = make_decl_info(c->scope, c->decl);

			d->decl_node = decl;
			d->comment = vd->comment;
			d->docs    = vd->docs;
			d->attributes = vd->attributes;
			d->type_expr = vd->type;
			d->init_expr = init;


			if (is_ast_type(init)) {
				e = alloc_entity_type_name(d->scope, token, nullptr);
			} else if (init->kind == Ast_ProcLit) {
				if (c->scope->flags&ScopeFlag_Type) {
					error(name, "Procedure declarations are not allowed within a struct");
					continue;
				}
				ast_node(pl, ProcLit, init);
				e = alloc_entity_procedure(d->scope, token, nullptr, pl->tags);
				if (fl != nullptr) {
					GB_ASSERT(fl->kind == Ast_Ident);
					e->Procedure.foreign_library_ident = fl;
					e->Procedure.is_foreign = true;

					GB_ASSERT(pl->type->kind == Ast_ProcType);
					auto cc = pl->type->ProcType.calling_convention;
					if (cc == ProcCC_ForeignBlockDefault) {
						cc = ProcCC_CDecl;
						if (c->foreign_context.default_cc > 0) {
							cc = c->foreign_context.default_cc;
						}
					}
					e->Procedure.link_prefix = c->foreign_context.link_prefix;

					GB_ASSERT(cc != ProcCC_Invalid);
					pl->type->ProcType.calling_convention = cc;
				}
				d->proc_lit = init;
				d->init_expr = init;

				if (is_test) {
					e->flags |= EntityFlag_Test;
				}
				if (is_init) {
					e->flags |= EntityFlag_Init;
				}
			} else if (init->kind == Ast_ProcGroup) {
				ast_node(pg, ProcGroup, init);
				e = alloc_entity_proc_group(d->scope, token, nullptr);
				if (fl != nullptr) {
					error(name, "Procedure groups are not allowed within a foreign block");
				}
			} else {
				e = alloc_entity_constant(d->scope, token, nullptr, empty_exact_value);
			}
			e->identifier = name;

			if (entity_visibility_kind != EntityVisiblity_Public) {
				e->flags |= EntityFlag_NotExported;
			}
			add_entity_flags_from_file(c, e, c->scope);

			if (vd->is_using) {
				if (e->kind == Entity_TypeName && init->kind == Ast_EnumType) {
					d->is_using = true;
				} else {
					error(name, "'using' is not allowed on this constant value declaration");
				}
			}

			if (e->kind != Entity_Procedure) {
				if (fl != nullptr) {
					begin_error_block();
					defer (end_error_block());

					AstKind kind = init->kind;
					error(name, "Only procedures and variables are allowed to be in a foreign block, got %.*s", LIT(ast_strings[kind]));
					if (kind == Ast_ProcType) {
						error_line("\tDid you forget to append '---' to the procedure?\n");
					}
				}
			}

			check_builtin_attributes(c, e, &d->attributes);

			bool is_exported = entity_visibility_kind != EntityVisiblity_PrivateToFile;
			add_entity_and_decl_info(c, name, e, d, is_exported);
		}

		check_arity_match(c, vd, true);
	}
}

void check_add_foreign_block_decl(CheckerContext *ctx, Ast *decl) {
	if (decl->state_flags & StateFlag_BeenHandled) return;
	decl->state_flags |= StateFlag_BeenHandled;

	ast_node(fb, ForeignBlockDecl, decl);
	Ast *foreign_library = fb->foreign_library;

	CheckerContext c = *ctx;
	if (foreign_library->kind == Ast_Ident) {
		c.foreign_context.curr_library = foreign_library;
	} else {
		error(foreign_library, "Foreign block name must be an identifier or 'export'");
		c.foreign_context.curr_library = nullptr;
	}

	check_decl_attributes(&c, fb->attributes, foreign_block_decl_attribute, nullptr);

	ast_node(block, BlockStmt, fb->body);
	check_collect_entities(&c, block->stmts);
}

bool correct_single_type_alias(CheckerContext *c, Entity *e) {
	if (e->kind == Entity_Constant) {
		DeclInfo *d = e->decl_info;
		if (d != nullptr && d->init_expr != nullptr) {
			Ast *init = d->init_expr;
			Entity *alias_of = check_entity_from_ident_or_selector(c, init, true);
			if (alias_of != nullptr && alias_of->kind == Entity_TypeName) {
				e->kind = Entity_TypeName;
				return true;
			}
		}
	}
	return false;
}

bool correct_type_alias_in_scope_backwards(CheckerContext *c, Scope *s) {
	isize n = s->elements.entries.count;
	bool correction = false;
	for (isize i = n-1; i >= 0; i--) {
		correction |= correct_single_type_alias(c, s->elements.entries[i].value);
	}
	return correction;
}
bool correct_type_alias_in_scope_forwards(CheckerContext *c, Scope *s) {
	isize n = s->elements.entries.count;
	bool correction = false;
	for (isize i = 0; i < n; i++) {
		correction |= correct_single_type_alias(c, s->elements.entries[i].value);
	}
	return correction;
}


void correct_type_aliases_in_scope(CheckerContext *c, Scope *s) {
	// NOTE(bill, 2022-02-04): This is used to solve the problem caused by type aliases
	// of type aliases being "confused" as constants
	//
	//         A :: C
	//         B :: A
	//         C :: struct {b: ^B}
	//
	// See @TypeAliasingProblem for more information
	for (;;) {
		bool corrections = false;
		corrections |= correct_type_alias_in_scope_backwards(c, s);
		corrections |= correct_type_alias_in_scope_forwards(c, s);
		if (!corrections) {
			return;
		}
	}
}


// NOTE(bill): If file_scopes == nullptr, this will act like a local scope
void check_collect_entities(CheckerContext *c, Slice<Ast *> const &nodes) {
	AstFile *curr_file = nullptr;
	if ((c->scope->flags&ScopeFlag_File) != 0) {
		curr_file = c->scope->file;
		GB_ASSERT(curr_file != nullptr);
	}


	for_array(decl_index, nodes) {
		Ast *decl = nodes[decl_index];
		if (!is_ast_decl(decl) && !is_ast_when_stmt(decl)) {
			if (curr_file && decl->kind == Ast_ExprStmt) {
				Ast *expr = decl->ExprStmt.expr;
				if (expr->kind == Ast_CallExpr && expr->CallExpr.proc->kind == Ast_BasicDirective) {
					if (c->collect_delayed_decls) {
						if (decl->state_flags & StateFlag_BeenHandled) return;
						decl->state_flags |= StateFlag_BeenHandled;
						mpmc_enqueue(&curr_file->delayed_decls_queues[AstDelayQueue_Expr], expr);
					}
					continue;
				}
			}
			continue;
		}

		switch (decl->kind) {
		case_ast_node(bd, BadDecl, decl);
		case_end;

		case_ast_node(ws, WhenStmt, decl);
			// Will be handled later
		case_end;

		case_ast_node(vd, ValueDecl, decl);
			check_collect_value_decl(c, decl);
		case_end;

		case_ast_node(id, ImportDecl, decl);
			if (curr_file == nullptr) {
				error(decl, "import declarations are only allowed in the file scope");
				// NOTE(bill): _Should_ be caught by the parser
				// TODO(bill): Better error handling if it isn't
				continue;
			}
			// Will be handled later
			mpmc_enqueue(&curr_file->delayed_decls_queues[AstDelayQueue_Import], decl);
		case_end;

		case_ast_node(fl, ForeignImportDecl, decl);
			if ((c->scope->flags&ScopeFlag_File) == 0) {
				error(decl, "%.*s declarations are only allowed in the file scope", LIT(fl->token.string));
				// NOTE(bill): _Should_ be caught by the parser
				// TODO(bill): Better error handling if it isn't
				continue;
			}
			check_add_foreign_import_decl(c, decl);
		case_end;

		case_ast_node(fb, ForeignBlockDecl, decl);
			check_add_foreign_block_decl(c, decl);
		case_end;

		default:
			if (c->scope->flags&ScopeFlag_File) {
				error(decl, "Only declarations are allowed at file scope");
			}
			break;
		}
	}

	// correct_type_aliases(c);

	// NOTE(bill): 'when' stmts need to be handled after the other as the condition may refer to something
	// declared after this stmt in source
	if (curr_file == nullptr) {
		for_array(decl_index, nodes) {
			Ast *decl = nodes[decl_index];
			if (decl->kind == Ast_WhenStmt) {
				check_collect_entities_from_when_stmt(c, &decl->WhenStmt);
			}
		}
	}
}

CheckerContext *create_checker_context(Checker *c) {
	CheckerContext *ctx = gb_alloc_item(permanent_allocator(), CheckerContext);
	*ctx = make_checker_context(c);
	return ctx;
}

void check_single_global_entity(Checker *c, Entity *e, DeclInfo *d) {
	GB_ASSERT(e != nullptr);
	GB_ASSERT(d != nullptr);

	if (d->scope != e->scope) {
		return;
	}
	if (e->state == EntityState_Resolved)  {
		return;
	}

	CheckerContext *ctx = create_checker_context(c);

	GB_ASSERT(d->scope->flags&ScopeFlag_File);
	AstFile *file = d->scope->file;
	add_curr_ast_file(ctx, file);
	AstPackage *pkg = file->pkg;

	GB_ASSERT(ctx->pkg != nullptr);
	GB_ASSERT(e->pkg != nullptr);
	ctx->decl = d;
	ctx->scope = d->scope;

	if (pkg->kind == Package_Init) {
		if (e->kind != Entity_Procedure && e->token.string == "main") {
			error(e->token, "'main' is reserved as the entry point procedure in the initial scope");
			return;
		}
	}

	check_entity_decl(ctx, e, d, nullptr);
}

void check_all_global_entities(Checker *c) {
	// NOTE(bill): This must be single threaded
	// Don't bother trying
	for_array(i, c->info.entities) {
		Entity *e = c->info.entities[i];
		if (e->flags & EntityFlag_Lazy) {
			continue;
		}
		DeclInfo *d = e->decl_info;
		check_single_global_entity(c, e, d);
		if (e->type != nullptr && is_type_typed(e->type)) {
			(void)type_size_of(e->type);
			(void)type_align_of(e->type);
		}
	}
}


bool is_string_an_identifier(String s) {
	isize offset = 0;
	if (s.len < 1) {
		return false;
	}
	while (offset < s.len) {
		bool ok = false;
		Rune r = -1;
		isize size = utf8_decode(s.text+offset, s.len-offset, &r);
		if (offset == 0) {
			ok = rune_is_letter(r);
		} else {
			ok = rune_is_letter(r) || rune_is_digit(r);
		}

		if (!ok) {
			return false;
		}
		offset += size;
	}

	return offset == s.len;
}

String path_to_entity_name(String name, String fullpath, bool strip_extension=true) {
	if (name.len != 0) {
		return name;
	}
	// NOTE(bill): use file name (without extension) as the identifier
	// If it is a valid identifier
	String filename = fullpath;
	isize slash = 0;
	isize dot = 0;
	for (isize i = filename.len-1; i >= 0; i--) {
		u8 c = filename[i];
		if (c == '/' || c == '\\') {
			break;
		}
		slash = i;
	}

	filename = substring(filename, slash, filename.len);

	if (strip_extension) {
		dot = filename.len;
		while (dot --> 0) {
			u8 c = filename[dot];
			if (c == '.') {
				break;
			}
		}

		if (dot > 0) {
			filename = substring(filename, 0, dot);
		}
	}

	if (is_string_an_identifier(filename)) {
		return filename;
	} else {
		return str_lit("_");
	}
}





#if 1

void add_import_dependency_node(Checker *c, Ast *decl, PtrMap<AstPackage *, ImportGraphNode *> *M) {
	AstPackage *parent_pkg = decl->file()->pkg;

	switch (decl->kind) {
	case_ast_node(id, ImportDecl, decl);
		String path = id->fullpath;
		if (is_package_name_reserved(path)) {
			return;
		}
		AstPackage **found = string_map_get(&c->info.packages, path);
		if (found == nullptr) {
			Token token = ast_token(decl);
			error(token, "Unable to find package: %.*s", LIT(path));
			gb_exit(1);
		}
		AstPackage *pkg = *found;
		GB_ASSERT(pkg->scope != nullptr);

		id->package = pkg;

		ImportGraphNode **found_node = nullptr;
		ImportGraphNode *m = nullptr;
		ImportGraphNode *n = nullptr;

		found_node = map_get(M, pkg);
		GB_ASSERT(found_node != nullptr);
		m = *found_node;

		found_node = map_get(M, parent_pkg);
		GB_ASSERT(found_node != nullptr);
		n = *found_node;

		// TODO(bill): How should the edges be attached for 'import'?
		import_graph_node_set_add(&n->succ, m);
		import_graph_node_set_add(&m->pred, n);
		ptr_set_add(&m->scope->imported, n->scope);
	case_end;

	case_ast_node(ws, WhenStmt, decl);
		if (ws->body != nullptr) {
			auto stmts = ws->body->BlockStmt.stmts;
			for_array(i, stmts) {
				add_import_dependency_node(c, stmts[i], M);
			}
		}

		if (ws->else_stmt != nullptr) {
			switch (ws->else_stmt->kind) {
			case Ast_BlockStmt: {
				auto stmts = ws->else_stmt->BlockStmt.stmts;
				for_array(i, stmts) {
					add_import_dependency_node(c, stmts[i], M);
				}

				break;
			}
			case Ast_WhenStmt:
				add_import_dependency_node(c, ws->else_stmt, M);
				break;
			}
		}
	case_end;
	}
}

Array<ImportGraphNode *> generate_import_dependency_graph(Checker *c) {
	PtrMap<AstPackage *, ImportGraphNode *> M = {};
	map_init(&M, heap_allocator(), 2*c->parser->packages.count);
	defer (map_destroy(&M));

	for_array(i, c->parser->packages) {
		AstPackage *pkg = c->parser->packages[i];
		ImportGraphNode *n = import_graph_node_create(heap_allocator(), pkg);
		map_set(&M, pkg, n);
	}

	// Calculate edges for graph M
	for_array(i, c->parser->packages) {
		AstPackage *p = c->parser->packages[i];
		for_array(j, p->files) {
			AstFile *f = p->files[j];
			for_array(k, f->decls) {
				Ast *decl = f->decls[k];
				add_import_dependency_node(c, decl, &M);
			}
		}
	}

	Array<ImportGraphNode *> G = {};
	array_init(&G, heap_allocator(), 0, M.entries.count);

	for_array(i, M.entries) {
		auto n = M.entries[i].value;
		n->index = i;
		n->dep_count = n->succ.entries.count;
		GB_ASSERT(n->dep_count >= 0);
		array_add(&G, n);
	}

	return G;
}

struct ImportPathItem {
	AstPackage *pkg;
	Ast *   decl;
};

Array<ImportPathItem> find_import_path(Checker *c, AstPackage *start, AstPackage *end, PtrSet<AstPackage *> *visited) {
	Array<ImportPathItem> empty_path = {};

	if (ptr_set_update(visited, start)) {
		return empty_path;
	}

	String path = start->fullpath;
	AstPackage **found = string_map_get(&c->info.packages, path);
	if (found) {
		AstPackage *pkg = *found;
		GB_ASSERT(pkg != nullptr);

		for_array(i, pkg->files) {
			AstFile *f = pkg->files[i];
			for_array(j, f->imports) {
				AstPackage *pkg = nullptr;
				Ast *decl = f->imports[j];
				if (decl->kind == Ast_ImportDecl) {
					pkg = decl->ImportDecl.package;
				} else {
					continue;
				}
				if (pkg == nullptr || pkg->scope == nullptr) {
					continue;
				}

				if (pkg->kind == Package_Runtime) {
					// NOTE(bill): Allow cyclic imports within the runtime package for the time being
					continue;
				}

				ImportPathItem item = {pkg, decl};
				if (pkg == end) {
					auto path = array_make<ImportPathItem>(heap_allocator());
					array_add(&path, item);
					return path;
				}
				auto next_path = find_import_path(c, pkg, end, visited);
				if (next_path.count > 0) {
					array_add(&next_path, item);
					return next_path;
				}
			}
		}
	}
	return empty_path;
}
#endif

String get_invalid_import_name(String input) {
	isize slash = 0;
	for (isize i = input.len-1; i >= 0; i--) {
		if (input[i] == '/' || input[i] == '\\') {
			break;
		}
		slash = i;
	}
	input = substring(input, slash, input.len);
	return input;
}

void check_add_import_decl(CheckerContext *ctx, Ast *decl) {
	if (decl->state_flags & StateFlag_BeenHandled) return;
	decl->state_flags |= StateFlag_BeenHandled;

	ast_node(id, ImportDecl, decl);
	Token token = id->relpath;

	Scope *parent_scope = ctx->scope;
	GB_ASSERT(parent_scope->flags&ScopeFlag_File);

	auto *pkgs = &ctx->checker->info.packages;

	Scope *scope = nullptr;

	bool force_use = false;

	if (id->fullpath == "builtin") {
		scope = builtin_pkg->scope;
		force_use = true;
	} else if (id->fullpath == "intrinsics") {
		scope = intrinsics_pkg->scope;
		force_use = true;
	} else {
		AstPackage **found = string_map_get(pkgs, id->fullpath);
		if (found == nullptr) {
			for_array(pkg_index, pkgs->entries) {
				AstPackage *pkg = pkgs->entries[pkg_index].value;
				gb_printf_err("%.*s\n", LIT(pkg->fullpath));
			}
			gb_printf_err("%s\n", token_pos_to_string(token.pos));
			GB_PANIC("Unable to find scope for package: %.*s", LIT(id->fullpath));
		} else {
			AstPackage *pkg = *found;
			scope = pkg->scope;
		}
	}
	GB_ASSERT(scope->flags&ScopeFlag_Pkg);


	if (ptr_set_update(&parent_scope->imported, scope)) {
		// error(token, "Multiple import of the same file within this scope");
	}

	String import_name = path_to_entity_name(id->import_name.string, id->fullpath, false);
	if (is_blank_ident(import_name)) {
		force_use = true;
	}

	// NOTE(bill, 2019-05-19): If the directory path is not a valid entity name, force the user to assign a custom one
	// if (import_name.len == 0 || import_name == "_") {
	// 	import_name = scope->pkg->name;
	// }

	if (import_name.len == 0) {
		String invalid_name = id->fullpath;
		invalid_name = get_invalid_import_name(invalid_name);

		error(id->token, "Import name %.*s, is not a valid identifier. Perhaps you want to reference the package by a different name like this: import <new_name> \"%.*s\" ", LIT(invalid_name), LIT(invalid_name));
		error(token, "Import name, %.*s, cannot be use as an import name as it is not a valid identifier", LIT(id->import_name.string));
	} else {
		GB_ASSERT(id->import_name.pos.line != 0);
		id->import_name.string = import_name;
		Entity *e = alloc_entity_import_name(parent_scope, id->import_name, t_invalid,
		                                     id->fullpath, id->import_name.string,
		                                     scope);

		add_entity(ctx, parent_scope, nullptr, e);
		if (force_use) {
			add_entity_use(ctx, nullptr, e);
		}
	}

	scope->flags |= ScopeFlag_HasBeenImported;
}

DECL_ATTRIBUTE_PROC(foreign_import_decl_attribute) {
	if (name == ATTRIBUTE_USER_TAG_NAME) {
		ExactValue ev = check_decl_attribute_value(c, value);
		if (ev.kind != ExactValue_String) {
			error(elem, "Expected a string value for '%.*s'", LIT(name));
		}
		return true;
	} else if (name == "force" || name == "require") {
		if (value != nullptr) {
			error(elem, "Expected no parameter for '%.*s'", LIT(name));
		} else if (name == "force") {
			warning(elem, "'force' is deprecated and is identical to 'require'");
		}
		ac->require_declaration = true;
		return true;
	} else if (name == "priority_index") {
		ExactValue ev = check_decl_attribute_value(c, value);
		if (ev.kind != ExactValue_Integer) {
			error(elem, "Expected an integer value for '%.*s'", LIT(name));
		} else {
			ac->foreign_import_priority_index = exact_value_to_i64(ev);
		}
		return true;
	}
	return false;
}

void check_add_foreign_import_decl(CheckerContext *ctx, Ast *decl) {
	if (decl->state_flags & StateFlag_BeenHandled) return;
	decl->state_flags |= StateFlag_BeenHandled;

	ast_node(fl, ForeignImportDecl, decl);

	Scope *parent_scope = ctx->scope;
	GB_ASSERT(parent_scope->flags&ScopeFlag_File);

	GB_ASSERT(fl->fullpaths.count > 0);
	String fullpath = fl->fullpaths[0];
	String library_name = path_to_entity_name(fl->library_name.string, fullpath);
	if (is_blank_ident(library_name)) {
		error(fl->token, "File name, %.*s, cannot be as a library name as it is not a valid identifier", LIT(fl->library_name.string));
		return;
	}

	// if (fl->collection_name != "system") {
	// 	char *c_str = gb_alloc_array(heap_allocator(), char, fullpath.len+1);
	// 	defer (gb_free(heap_allocator(), c_str));
	// 	gb_memmove(c_str, fullpath.text, fullpath.len);
	// 	c_str[fullpath.len] = '\0';

	// 	gbFile f = {};
	// 	gbFileError file_err = gb_file_open(&f, c_str);
	// 	defer (gb_file_close(&f));

	// 	switch (file_err) {
	// 	case gbFileError_Invalid:
	// 		error(decl, "Invalid file or cannot be found ('%.*s')", LIT(fullpath));
	// 		return;
	// 	case gbFileError_NotExists:
	// 		error(decl, "File cannot be found ('%.*s')", LIT(fullpath));
	// 		return;
	// 	}
	// }

	GB_ASSERT(fl->library_name.pos.line != 0);
	fl->library_name.string = library_name;

	Entity *e = alloc_entity_library_name(parent_scope, fl->library_name, t_invalid,
	                                      fl->fullpaths, library_name);
	add_entity_flags_from_file(ctx, e, parent_scope);
	add_entity(ctx, parent_scope, nullptr, e);


	AttributeContext ac = {};
	check_decl_attributes(ctx, fl->attributes, foreign_import_decl_attribute, &ac);
	if (ac.require_declaration) {
		mpmc_enqueue(&ctx->info->required_foreign_imports_through_force_queue, e);
		add_entity_use(ctx, nullptr, e);
	}
	if (ac.foreign_import_priority_index != 0) {
		e->LibraryName.priority_index = ac.foreign_import_priority_index;
	}

	if (has_asm_extension(fullpath)) {
		if (build_context.metrics.arch != TargetArch_amd64 ||
		    build_context.metrics.os   != TargetOs_windows) {
			error(decl, "Assembly files are not yet supported on this platform: %.*s_%.*s",
			      LIT(target_os_names[build_context.metrics.os]), LIT(target_arch_names[build_context.metrics.arch]));
		}
	}
}

// Returns true if a new package is present
bool collect_file_decls(CheckerContext *ctx, Slice<Ast *> const &decls);
bool collect_file_decls_from_when_stmt(CheckerContext *ctx, AstWhenStmt *ws);

bool collect_when_stmt_from_file(CheckerContext *ctx, AstWhenStmt *ws) {
	Operand operand = {Addressing_Invalid};
	if (!ws->is_cond_determined) {
		check_expr(ctx, &operand, ws->cond);
		if (operand.mode != Addressing_Invalid && !is_type_boolean(operand.type)) {
			error(ws->cond, "Non-boolean condition in 'when' statement");
		}
		if (operand.mode != Addressing_Constant) {
			error(ws->cond, "Non-constant condition in 'when' statement");
		}

		ws->is_cond_determined = true;
		ws->determined_cond = operand.value.kind == ExactValue_Bool && operand.value.value_bool;
	}

	if (ws->body == nullptr || ws->body->kind != Ast_BlockStmt) {
		error(ws->cond, "Invalid body for 'when' statement");
	} else {
		if (ws->determined_cond) {
			check_collect_entities(ctx, ws->body->BlockStmt.stmts);
			return true;
		} else if (ws->else_stmt) {
			switch (ws->else_stmt->kind) {
			case Ast_BlockStmt:
				check_collect_entities(ctx, ws->else_stmt->BlockStmt.stmts);
				return true;
			case Ast_WhenStmt:
				collect_when_stmt_from_file(ctx, &ws->else_stmt->WhenStmt);
				return true;
			default:
				error(ws->else_stmt, "Invalid 'else' statement in 'when' statement");
				break;
			}
		}
	}

	return false;
}

bool collect_file_decls_from_when_stmt(CheckerContext *ctx, AstWhenStmt *ws) {
	Operand operand = {Addressing_Invalid};
	if (!ws->is_cond_determined) {
		check_expr(ctx, &operand, ws->cond);
		if (operand.mode != Addressing_Invalid && !is_type_boolean(operand.type)) {
			error(ws->cond, "Non-boolean condition in 'when' statement");
		}
		if (operand.mode != Addressing_Constant) {
			error(ws->cond, "Non-constant condition in 'when' statement");
		}

		ws->is_cond_determined = true;
		ws->determined_cond = operand.value.kind == ExactValue_Bool && operand.value.value_bool;
	}

	if (ws->body == nullptr || ws->body->kind != Ast_BlockStmt) {
		error(ws->cond, "Invalid body for 'when' statement");
	} else {
		if (ws->determined_cond) {
			return collect_file_decls(ctx, ws->body->BlockStmt.stmts);
		} else if (ws->else_stmt) {
			switch (ws->else_stmt->kind) {
			case Ast_BlockStmt:
				return collect_file_decls(ctx, ws->else_stmt->BlockStmt.stmts);
			case Ast_WhenStmt:
				return collect_file_decls_from_when_stmt(ctx, &ws->else_stmt->WhenStmt);
			default:
				error(ws->else_stmt, "Invalid 'else' statement in 'when' statement");
				break;
			}
		}
	}

	return false;
}


bool collect_file_decl(CheckerContext *ctx, Ast *decl) {
	GB_ASSERT(ctx->scope->flags&ScopeFlag_File);

	AstFile *curr_file = ctx->scope->file;
	GB_ASSERT(curr_file != nullptr);

	if (decl->state_flags & StateFlag_BeenHandled) {
		return false;
	}

	switch (decl->kind) {
	case_ast_node(vd, ValueDecl, decl);
		check_collect_value_decl(ctx, decl);
	case_end;

	case_ast_node(id, ImportDecl, decl);
		check_add_import_decl(ctx, decl);
	case_end;

	case_ast_node(fl, ForeignImportDecl, decl);
		check_add_foreign_import_decl(ctx, decl);
	case_end;

	case_ast_node(fb, ForeignBlockDecl, decl);
		check_add_foreign_block_decl(ctx, decl);
	case_end;

	case_ast_node(ws, WhenStmt, decl);
		if (!ws->is_cond_determined) {
			if (collect_when_stmt_from_file(ctx, ws)) {
				return true;
			}

			CheckerContext nctx = *ctx;
			nctx.collect_delayed_decls = true;

			if (collect_file_decls_from_when_stmt(&nctx, ws)) {
				return true;
			}
		} else {
			CheckerContext nctx = *ctx;
			nctx.collect_delayed_decls = true;

			if (collect_file_decls_from_when_stmt(&nctx, ws)) {
				return true;
			}
		}
	case_end;

	case_ast_node(es, ExprStmt, decl);
		GB_ASSERT(ctx->collect_delayed_decls);
		decl->state_flags |= StateFlag_BeenHandled;
		if (es->expr->kind == Ast_CallExpr) {
			ast_node(ce, CallExpr, es->expr);
			if (ce->proc->kind == Ast_BasicDirective) {
				mpmc_enqueue(&curr_file->delayed_decls_queues[AstDelayQueue_Expr], es->expr);
			}
		}
	case_end;
	}

	return false;
}

bool collect_file_decls(CheckerContext *ctx, Slice<Ast *> const &decls) {
	GB_ASSERT(ctx->scope->flags&ScopeFlag_File);

	for_array(i, decls) {
		if (collect_file_decl(ctx, decls[i])) {
			correct_type_aliases_in_scope(ctx, ctx->scope);
			return true;
		}
	}
	correct_type_aliases_in_scope(ctx, ctx->scope);
	return false;
}

GB_COMPARE_PROC(sort_file_by_name) {
	AstFile const *x = *cast(AstFile const **)a;
	AstFile const *y = *cast(AstFile const **)b;
	String x_name = filename_from_path(x->fullpath);
	String y_name = filename_from_path(y->fullpath);
	return string_compare(x_name, y_name);
}

void check_create_file_scopes(Checker *c) {
	for_array(i, c->parser->packages) {
		AstPackage *pkg = c->parser->packages[i];
		isize total_pkg_decl_count = 0;

		gb_sort_array(pkg->files.data, pkg->files.count, sort_file_by_name);

		for_array(j, pkg->files) {
			AstFile *f = pkg->files[j];
			string_map_set(&c->info.files, f->fullpath, f);

			create_scope_from_file(nullptr, f);
			total_pkg_decl_count += f->total_file_decl_count;
		}

		mpmc_init(&pkg->exported_entity_queue, heap_allocator(), total_pkg_decl_count);
	}
}

struct ThreadProcCheckerSection {
	Checker *checker;
	isize offset;
	isize count;
};


void check_with_workers(Checker *c, WorkerTaskProc *proc, isize total_count) {
	isize thread_count = gb_max(build_context.thread_count, 1);
	isize worker_count = thread_count-1; // NOTE(bill): The main thread will also be used for work
	if (!build_context.threaded_checker) {
		worker_count = 0;
	}

	semaphore_post(&c->info.collect_semaphore, cast(i32)thread_count);
	if (worker_count == 0) {
		ThreadProcCheckerSection section_all = {};
		section_all.checker = c;
		section_all.offset = 0;
		section_all.count = total_count;
		proc(&section_all);
		return;
	}

	isize file_load_count = (total_count+thread_count-1)/thread_count;
	isize remaining_count = total_count;

	ThreadProcCheckerSection *thread_data = gb_alloc_array(permanent_allocator(), ThreadProcCheckerSection, thread_count);
	for (isize i = 0; i < thread_count; i++) {
		ThreadProcCheckerSection *data = thread_data + i;
		data->checker = c;
		data->offset = total_count-remaining_count;
		data->count = file_load_count;
		remaining_count -= file_load_count;
	}
	GB_ASSERT(remaining_count <= 0);


	for (isize i = 0; i < thread_count; i++) {
		global_thread_pool_add_task(proc, thread_data+i);
	}
	global_thread_pool_wait();
	semaphore_wait(&c->info.collect_semaphore);
}


WORKER_TASK_PROC(thread_proc_collect_entities) {
	auto *cs = cast(ThreadProcCheckerSection *)data;
	Checker *c = cs->checker;
	CheckerContext collect_entity_ctx = make_checker_context(c);
	defer (destroy_checker_context(&collect_entity_ctx));

	CheckerContext *ctx = &collect_entity_ctx;

	UntypedExprInfoMap untyped = {};
	map_init(&untyped, heap_allocator());

	isize offset = cs->offset;
	isize file_end = gb_min(offset+cs->count, c->info.files.entries.count);

	for (isize i = offset; i < file_end; i++) {
		AstFile *f = c->info.files.entries[i].value;
		reset_checker_context(ctx, f, &untyped);

		check_collect_entities(ctx, f->decls);
		GB_ASSERT(ctx->collect_delayed_decls == false);

		add_untyped_expressions(&c->info, ctx->untyped);
	}

	map_destroy(&untyped);

	semaphore_release(&c->info.collect_semaphore);
	return 0;
}


void check_collect_entities_all(Checker *c) {
	check_with_workers(c, thread_proc_collect_entities, c->info.files.entries.count);
}

void check_export_entities_in_pkg(CheckerContext *ctx, AstPackage *pkg, UntypedExprInfoMap *untyped) {
	if (pkg->files.count != 0) {
		AstPackageExportedEntity item = {};
		while (mpmc_dequeue(&pkg->exported_entity_queue, &item)) {
			AstFile *f = item.entity->file;
			if (ctx->file != f) {
				reset_checker_context(ctx, f, untyped);
			}
			add_entity(ctx, pkg->scope, item.identifier, item.entity);
			add_untyped_expressions(ctx->info, untyped);
		}
	}
}

WORKER_TASK_PROC(thread_proc_check_export_entities) {
	auto cs = cast(ThreadProcCheckerSection *)data;
	Checker *c = cs->checker;

	CheckerContext ctx = make_checker_context(c);
	defer (destroy_checker_context(&ctx));

	UntypedExprInfoMap untyped = {};
	map_init(&untyped, heap_allocator());

	isize end = gb_min(cs->offset + cs->count, c->info.packages.entries.count);
	for (isize i = cs->offset; i < end; i++) {
		AstPackage *pkg = c->info.packages.entries[i].value;
		check_export_entities_in_pkg(&ctx, pkg, &untyped);
	}

	map_destroy(&untyped);

	semaphore_release(&c->info.collect_semaphore);
	return 0;
}

void check_export_entities(Checker *c) {
	check_with_workers(c, thread_proc_check_export_entities, c->info.packages.entries.count);
}

void check_import_entities(Checker *c) {
	Array<ImportGraphNode *> dep_graph = generate_import_dependency_graph(c);
	defer ({
		for_array(i, dep_graph) {
			import_graph_node_destroy(dep_graph[i], heap_allocator());
		}
		array_free(&dep_graph);
	});


	TIME_SECTION("check_import_entities - sort packages");
	// NOTE(bill): Priority queue
	auto pq = priority_queue_create(dep_graph, import_graph_node_cmp, import_graph_node_swap);

	PtrSet<AstPackage *> emitted = {};
	ptr_set_init(&emitted, heap_allocator());
	defer (ptr_set_destroy(&emitted));

	Array<ImportGraphNode *> package_order = {};
	array_init(&package_order, heap_allocator(), 0, c->parser->packages.count);
	defer (array_free(&package_order));

	while (pq.queue.count > 0) {
		ImportGraphNode *n = priority_queue_pop(&pq);

		AstPackage *pkg = n->pkg;

		if (n->dep_count > 0) {
			PtrSet<AstPackage *> visited = {};
			ptr_set_init(&visited, heap_allocator());
			defer (ptr_set_destroy(&visited));

			auto path = find_import_path(c, pkg, pkg, &visited);
			defer (array_free(&path));

			if (path.count > 1) {
				ImportPathItem item = path[path.count-1];
				String pkg_name = item.pkg->name;
				error(item.decl, "Cyclic importation of '%.*s'", LIT(pkg_name));
				for (isize i = 0; i < path.count; i++) {
					error(item.decl, "'%.*s' refers to", LIT(pkg_name));
					item = path[i];
					pkg_name = item.pkg->name;
				}
				error(item.decl, "'%.*s'", LIT(pkg_name));
			}
		}

		for_array(i, n->pred.entries) {
			ImportGraphNode *p = n->pred.entries[i].ptr;
			p->dep_count = gb_max(p->dep_count-1, 0);
			priority_queue_fix(&pq, p->index);
		}

		if (pkg == nullptr) {
			continue;
		}
		if (ptr_set_update(&emitted, pkg)) {
			continue;
		}

		array_add(&package_order, n);
	}

	TIME_SECTION("check_import_entities - collect file decls");
	CheckerContext ctx = make_checker_context(c);

	UntypedExprInfoMap untyped = {};
	map_init(&untyped, heap_allocator());
	defer (map_destroy(&untyped));

	isize min_pkg_index = 0;
	for (isize pkg_index = 0; pkg_index < package_order.count; pkg_index++) {
		ImportGraphNode *node = package_order[pkg_index];
		AstPackage *pkg = node->pkg;
		pkg->order = 1+pkg_index;

		for_array(i, pkg->files) {
			AstFile *f = pkg->files[i];

			reset_checker_context(&ctx, f, &untyped);
			ctx.collect_delayed_decls = true;

			// Check import declarations first to simplify things
			for (Ast *id = nullptr; mpmc_dequeue(&f->delayed_decls_queues[AstDelayQueue_Import], &id); /**/) {
				check_add_import_decl(&ctx, id);
			}

			if (collect_file_decls(&ctx, f->decls)) {
				check_export_entities_in_pkg(&ctx, pkg, &untyped);
				pkg_index = min_pkg_index-1;
				break;
			}

			add_untyped_expressions(ctx.info, &untyped);
		}
		if (pkg_index < 0) {
			continue;
		}
		min_pkg_index = pkg_index;
	}

	TIME_SECTION("check_import_entities - check delayed entities");
	for_array(i, package_order) {
		ImportGraphNode *node = package_order[i];
		GB_ASSERT(node->scope->flags&ScopeFlag_Pkg);
		AstPackage *pkg = node->scope->pkg;

		for_array(i, pkg->files) {
			AstFile *f = pkg->files[i];
			reset_checker_context(&ctx, f, &untyped);

			auto *q = &f->delayed_decls_queues[AstDelayQueue_Import];
			for (Ast *decl = nullptr; mpmc_dequeue(q, &decl); /**/) {
				check_add_import_decl(&ctx, decl);
			}
			add_untyped_expressions(ctx.info, &untyped);
		}

		for_array(i, pkg->files) {
			AstFile *f = pkg->files[i];
			reset_checker_context(&ctx, f, &untyped);
			ctx.collect_delayed_decls = false;

			correct_type_aliases_in_scope(&ctx, pkg->scope);
		}

		for_array(i, pkg->files) {
			AstFile *f = pkg->files[i];
			reset_checker_context(&ctx, f, &untyped);

			auto *q = &f->delayed_decls_queues[AstDelayQueue_Expr];
			for (Ast *expr = nullptr; mpmc_dequeue(q, &expr); /**/) {
				Operand o = {};
				check_expr(&ctx, &o, expr);
			}
			add_untyped_expressions(ctx.info, &untyped);
		}
	}
}


Array<Entity *> find_entity_path(Entity *start, Entity *end, PtrSet<Entity *> *visited = nullptr);

bool find_entity_path_tuple(Type *tuple, Entity *end, PtrSet<Entity *> *visited, Array<Entity *> *path_) {
	GB_ASSERT(path_ != nullptr);
	if (tuple == nullptr) {
		return false;
	}
	GB_ASSERT(tuple->kind == Type_Tuple);
	for_array(i, tuple->Tuple.variables) {
		Entity *var = tuple->Tuple.variables[i];
		DeclInfo *var_decl = var->decl_info;
		if (var_decl == nullptr) {
			continue;
		}
		for_array(i, var_decl->deps.entries) {
			Entity *dep = var_decl->deps.entries[i].ptr;
			if (dep == end) {
				auto path = array_make<Entity *>(heap_allocator());
				array_add(&path, dep);
				*path_ = path;
				return true;
			}
			auto next_path = find_entity_path(dep, end, visited);
			if (next_path.count > 0) {
				array_add(&next_path, dep);
				*path_ = next_path;
				return true;
			}
		}
	}

	return false;
}

Array<Entity *> find_entity_path(Entity *start, Entity *end, PtrSet<Entity *> *visited) {
	PtrSet<Entity *> visited_ = {};
	bool made_visited = false;
	if (visited == nullptr) {
		made_visited = true;
		ptr_set_init(&visited_, heap_allocator());
		visited = &visited_;
	}
	defer (if (made_visited) {
		ptr_set_destroy(&visited_);
	});

	Array<Entity *> empty_path = {};

	if (ptr_set_exists(visited, start)) {
		return empty_path;
	}
	ptr_set_add(visited, start);

	DeclInfo *decl = start->decl_info;
	if (decl) {
		if (start->kind == Entity_Procedure) {
			Type *t = base_type(start->type);
			GB_ASSERT(t->kind == Type_Proc);

			Array<Entity *> path = {};
			if (find_entity_path_tuple(t->Proc.params, end, visited, &path)) {
				return path;
			}
			if (find_entity_path_tuple(t->Proc.results, end, visited, &path)) {
				return path;
			}
		} else {
			for_array(i, decl->deps.entries) {
				Entity *dep = decl->deps.entries[i].ptr;
				if (dep == end) {
					auto path = array_make<Entity *>(heap_allocator());
					array_add(&path, dep);
					return path;
				}
				auto next_path = find_entity_path(dep, end, visited);
				if (next_path.count > 0) {
					array_add(&next_path, dep);
					return next_path;
				}
			}
		}
	}
	return empty_path;
}


void calculate_global_init_order(Checker *c) {
	CheckerInfo *info = &c->info;

	TIME_SECTION("calculate_global_init_order: generate entity dependency graph");
	Array<EntityGraphNode *> dep_graph = generate_entity_dependency_graph(info, heap_allocator());
	defer ({
		for_array(i, dep_graph) {
			entity_graph_node_destroy(dep_graph[i], heap_allocator());
		}
		array_free(&dep_graph);
	});

	TIME_SECTION("calculate_global_init_order: priority queue create");
	// NOTE(bill): Priority queue
	auto pq = priority_queue_create(dep_graph, entity_graph_node_cmp, entity_graph_node_swap);

	PtrSet<DeclInfo *> emitted = {};
	ptr_set_init(&emitted, heap_allocator());
	defer (ptr_set_destroy(&emitted));

	TIME_SECTION("calculate_global_init_order: queue sort");
	while (pq.queue.count > 0) {
		EntityGraphNode *n = priority_queue_pop(&pq);
		Entity *e = n->entity;

		if (n->dep_count > 0) {
			auto path = find_entity_path(e, e);
			defer (array_free(&path));

			if (path.count > 0) {
				Entity *e = path[0];
				error(e->token, "Cyclic initialization of '%.*s'", LIT(e->token.string));
				for (isize i = path.count-1; i >= 0; i--) {
					error(e->token, "\t'%.*s' refers to", LIT(e->token.string));
					e = path[i];
				}
				error(e->token, "\t'%.*s'", LIT(e->token.string));
			}
		}

		for_array(i, n->pred.entries) {
			EntityGraphNode *p = n->pred.entries[i].ptr;
			p->dep_count -= 1;
			p->dep_count = gb_max(p->dep_count, 0);
			priority_queue_fix(&pq, p->index);
		}

		DeclInfo *d = decl_info_of_entity(e);
		if (e->kind != Entity_Variable) {
			continue;
		}
		// IMPORTANT NOTE(bill, 2019-08-29): Just add it regardless of the ordering
		// because it does not need any initialization other than zero
		// if (!decl_info_has_init(d)) {
		// 	continue;
		// }
		if (ptr_set_update(&emitted, d)) {
			continue;
		}

		array_add(&info->variable_init_order, d);
	}

	if (false) {
		gb_printf("Variable Initialization Order:\n");
		for_array(i, info->variable_init_order) {
			DeclInfo *d = info->variable_init_order[i];
			Entity *e = d->entity;
			gb_printf("\t'%.*s' %llu\n", LIT(e->token.string), cast(unsigned long long)e->order_in_src);
		}
		gb_printf("\n");
	}
}


bool check_proc_info(Checker *c, ProcInfo *pi, UntypedExprInfoMap *untyped, ProcBodyQueue *procs_to_check_queue) {
	if (pi == nullptr) {
		return false;
	}
	if (pi->type == nullptr) {
		return false;
	}
	Entity *e = pi->decl->entity;
	if (pi->decl->proc_checked) {
		if (e != nullptr) {
			GB_ASSERT(e->flags & EntityFlag_ProcBodyChecked);
		}
		return true;
	}

	CheckerContext ctx = make_checker_context(c);
	defer (destroy_checker_context(&ctx));
	reset_checker_context(&ctx, pi->file, untyped);
	ctx.decl = pi->decl;
	ctx.procs_to_check_queue = procs_to_check_queue;
	GB_ASSERT(procs_to_check_queue != nullptr);

	GB_ASSERT(pi->type->kind == Type_Proc);
	TypeProc *pt = &pi->type->Proc;
	String name = pi->token.string;

	if (pt->is_polymorphic && !pt->is_poly_specialized) {
		Token token = pi->token;
		if (pi->poly_def_node != nullptr) {
			token = ast_token(pi->poly_def_node);
		}
		error(token, "Unspecialized polymorphic procedure '%.*s'", LIT(name));
		return false;
	}

	if (pt->is_polymorphic && pt->is_poly_specialized) {
		if ((e->flags & EntityFlag_Used) == 0) {
			// NOTE(bill, 2019-08-31): It was never used, don't check
			return false;
		}
	}

	bool bounds_check    = (pi->tags & ProcTag_bounds_check)    != 0;
	bool no_bounds_check = (pi->tags & ProcTag_no_bounds_check) != 0;

	bool type_assert    = (pi->tags & ProcTag_type_assert)    != 0;
	bool no_type_assert = (pi->tags & ProcTag_no_type_assert) != 0;

	if (bounds_check) {
		ctx.state_flags |= StateFlag_bounds_check;
		ctx.state_flags &= ~StateFlag_no_bounds_check;
	} else if (no_bounds_check) {
		ctx.state_flags |= StateFlag_no_bounds_check;
		ctx.state_flags &= ~StateFlag_bounds_check;
	}

	if (type_assert) {
		ctx.state_flags |= StateFlag_type_assert;
		ctx.state_flags &= ~StateFlag_no_type_assert;
	} else if (no_type_assert) {
		ctx.state_flags |= StateFlag_no_type_assert;
		ctx.state_flags &= ~StateFlag_type_assert;
	}

	if (pi->body != nullptr && e != nullptr) {
		GB_ASSERT((e->flags & EntityFlag_ProcBodyChecked) == 0);
	}

	check_proc_body(&ctx, pi->token, pi->decl, pi->type, pi->body);
	if (e != nullptr) {
		e->flags |= EntityFlag_ProcBodyChecked;
	}
	pi->decl->proc_checked = true;
	add_untyped_expressions(&c->info, ctx.untyped);
	return true;
}

GB_STATIC_ASSERT(sizeof(isize) == sizeof(void *));

bool consume_proc_info_queue(Checker *c, ProcInfo *pi, ProcBodyQueue *q, UntypedExprInfoMap *untyped);

void check_unchecked_bodies(Checker *c) {
	// NOTE(2021-02-26, bill): Sanity checker
	// This is a partial hack to make sure all procedure bodies have been checked
	// even ones which should not exist, due to the multithreaded nature of the parser
	// HACK TODO(2021-02-26, bill): Actually fix this race condition

	UntypedExprInfoMap untyped = {};
	map_init(&untyped, heap_allocator());
	defer (map_destroy(&untyped));

	for_array(i, c->info.minimum_dependency_set.entries) {
		Entity *e = c->info.minimum_dependency_set.entries[i].ptr;
		if (e == nullptr || e->kind != Entity_Procedure) {
			continue;
		}
		if (e->Procedure.is_foreign) {
			continue;
		}
		if ((e->flags & EntityFlag_ProcBodyChecked) == 0) {
			GB_ASSERT(e->decl_info != nullptr);

			ProcInfo *pi = gb_alloc_item(permanent_allocator(), ProcInfo);
			pi->file  = e->file;
			pi->token = e->token;
			pi->decl  = e->decl_info;
			pi->type  = e->type;

			Ast *pl = e->decl_info->proc_lit;
			GB_ASSERT(pl != nullptr);
			pi->body  = pl->ProcLit.body;
			pi->tags  = pl->ProcLit.tags;
			if (pi->body == nullptr) {
				continue;
			}

			debugf("unchecked: %.*s\n", LIT(e->token.string));
			mpmc_enqueue(&c->procs_to_check_queue, pi);
		}
	}

	auto *q = &c->procs_to_check_queue;
	ProcInfo *pi = nullptr;
	while (mpmc_dequeue(q, &pi)) {
		Entity *e = pi->decl->entity;
		if (consume_proc_info_queue(c, pi, q, &untyped)) {
			add_dependency_to_set(c, e);
			GB_ASSERT(e->flags & EntityFlag_ProcBodyChecked);
		}
	}

}

void check_test_procedures(Checker *c) {
	if (build_context.test_names.entries.count == 0) {
		return;
	}

	AstPackage *pkg = c->info.init_package;
	Scope *s = pkg->scope;

	for_array(i, build_context.test_names.entries) {
		String name = build_context.test_names.entries[i].value;
		Entity *e = scope_lookup(s, name);
		if (e == nullptr) {
			Token tok = {};
			if (pkg->files.count != 0) {
				tok = pkg->files[0]->tokens[0];
			}
			error(tok, "Unable to find the test '%.*s' in 'package %.*s' ", LIT(name), LIT(pkg->name));
		}
	}

	for (isize i = 0; i < c->info.testing_procedures.count; /**/) {
		Entity *e = c->info.testing_procedures[i];
		String name = e->token.string;
		if (!string_set_exists(&build_context.test_names, name)) {
			array_ordered_remove(&c->info.testing_procedures, i);
		} else {
			i += 1;
		}
	}

}


gb_global std::atomic<isize> total_bodies_checked;

bool consume_proc_info_queue(Checker *c, ProcInfo *pi, ProcBodyQueue *q, UntypedExprInfoMap *untyped) {
	GB_ASSERT(pi->decl != nullptr);
	if (pi->decl->parent && pi->decl->parent->entity) {
		Entity *parent = pi->decl->parent->entity;
		// NOTE(bill): Only check a nested procedure if its parent's body has been checked first
		// This is prevent any possible race conditions in evaluation when multithreaded
		// NOTE(bill): In single threaded mode, this should never happen
		if (parent->kind == Entity_Procedure && (parent->flags & EntityFlag_ProcBodyChecked) == 0) {
			mpmc_enqueue(q, pi);
			return false;
		}
	}
	if (untyped) {
		map_clear(untyped);
	}
	bool ok = check_proc_info(c, pi, untyped, q);
	total_bodies_checked.fetch_add(1, std::memory_order_relaxed);
	return ok;
}

struct ThreadProcBodyData {
	Checker *checker;
	ProcBodyQueue *queue;
	u32 thread_index;
	u32 thread_count;
	ThreadProcBodyData *all_data;
};

WORKER_TASK_PROC(thread_proc_body) {
	ThreadProcBodyData *bd = cast(ThreadProcBodyData *)data;
	Checker *c = bd->checker;
	GB_ASSERT(c != nullptr);
	ProcBodyQueue *this_queue = bd->queue;

	UntypedExprInfoMap untyped = {};
	map_init(&untyped, heap_allocator());

	for (ProcInfo *pi; mpmc_dequeue(this_queue, &pi); /**/) {
		consume_proc_info_queue(c, pi, this_queue, &untyped);
	}

	map_destroy(&untyped);

	semaphore_release(&c->procs_to_check_semaphore);

	return 0;
}

void check_procedure_bodies(Checker *c) {
	GB_ASSERT(c != nullptr);

	u32 thread_count = cast(u32)gb_max(build_context.thread_count, 1);
	u32 worker_count = thread_count-1; // NOTE(bill): The main thread will also be used for work
	if (!build_context.threaded_checker) {
		worker_count = 0;
	}
	if (worker_count == 0) {
		auto *this_queue = &c->procs_to_check_queue;

		UntypedExprInfoMap untyped = {};
		map_init(&untyped, heap_allocator());

		for (ProcInfo *pi = nullptr; mpmc_dequeue(this_queue, &pi); /**/) {
			consume_proc_info_queue(c, pi, this_queue, &untyped);
		}

		map_destroy(&untyped);

		debugf("Total Procedure Bodies Checked: %td\n", total_bodies_checked.load(std::memory_order_relaxed));
		return;
	}

	global_procedure_body_in_worker_queue = true;

	isize original_queue_count = c->procs_to_check_queue.count.load(std::memory_order_relaxed);
	isize load_count = (original_queue_count+thread_count-1)/thread_count;

	ThreadProcBodyData *thread_data = gb_alloc_array(permanent_allocator(), ThreadProcBodyData, thread_count);
	for (u32 i = 0; i < thread_count; i++) {
		ThreadProcBodyData *data = thread_data + i;
		data->checker = c;
		data->queue = gb_alloc_item(permanent_allocator(), ProcBodyQueue);
		data->thread_index = i;
		data->thread_count = thread_count;
		data->all_data = thread_data;
		// NOTE(bill) 2x the amount assumes on average only 1 nested procedure
		// TODO(bill): Determine a good heuristic
		mpmc_init(data->queue, heap_allocator(), next_pow2_isize(load_count*2));
	}

	// Distibute the work load into multiple queues
	for (isize j = 0; j < load_count; j++) {
		for (isize i = 0; i < thread_count; i++) {
			ProcBodyQueue *queue = thread_data[i].queue;
			ProcInfo *pi = nullptr;
			if (!mpmc_dequeue(&c->procs_to_check_queue, &pi)) {
				break;
			}
			mpmc_enqueue(queue, pi);
		}
	}
	isize total_queued = 0;
	for (isize i = 0; i < thread_count; i++) {
		ProcBodyQueue *queue = thread_data[i].queue;
		total_queued += queue->count.load();
	}
	GB_ASSERT(total_queued == original_queue_count);

	semaphore_post(&c->procs_to_check_semaphore, cast(i32)thread_count);

	for (isize i = 0; i < thread_count; i++) {
		global_thread_pool_add_task(thread_proc_body, thread_data+i);
	}
	global_thread_pool_wait();
	semaphore_wait(&c->procs_to_check_semaphore);

	isize global_remaining = c->procs_to_check_queue.count.load(std::memory_order_relaxed);
	GB_ASSERT(global_remaining == 0);

	debugf("Total Procedure Bodies Checked: %td\n", total_bodies_checked.load(std::memory_order_relaxed));


	global_procedure_body_in_worker_queue = false;
}
void add_untyped_expressions(CheckerInfo *cinfo, UntypedExprInfoMap *untyped) {
	if (untyped == nullptr) {
		return;
	}
	for_array(i, untyped->entries) {
		Ast *expr = untyped->entries[i].key;
		ExprInfo *info = untyped->entries[i].value;
		if (expr != nullptr && info != nullptr) {
			mpmc_enqueue(&cinfo->checker->global_untyped_queue, UntypedExprInfo{expr, info});
		}
	}
	map_clear(untyped);
}

void check_deferred_procedures(Checker *c) {
	for (Entity *src = nullptr; mpmc_dequeue(&c->procs_with_deferred_to_check, &src); /**/) {
		GB_ASSERT(src->kind == Entity_Procedure);

		DeferredProcedureKind dst_kind = src->Procedure.deferred_procedure.kind;
		Entity *dst = src->Procedure.deferred_procedure.entity;
		GB_ASSERT(dst != nullptr);
		GB_ASSERT(dst->kind == Entity_Procedure);

		char const *attribute = "deferred_none";
		switch (dst_kind) {
		case DeferredProcedure_none:
			attribute = "deferred_none";
			break;
		case DeferredProcedure_in:
			attribute = "deferred_in";
			break;
		case DeferredProcedure_out:
			attribute = "deferred_out";
			break;
		case DeferredProcedure_in_out:
			attribute = "deferred_in_out";
			break;
		}

		if (is_type_polymorphic(src->type) || is_type_polymorphic(dst->type)) {
			error(src->token, "'%s' cannot be used with a polymorphic procedure", attribute);
			continue;
		}

		GB_ASSERT(is_type_proc(src->type));
		GB_ASSERT(is_type_proc(dst->type));
		Type *src_params = base_type(src->type)->Proc.params;
		Type *src_results = base_type(src->type)->Proc.results;
		Type *dst_params = base_type(dst->type)->Proc.params;

		if (dst_kind == DeferredProcedure_none) {
			if (dst_params == nullptr) {
				// Okay
				continue;
			}

			error(src->token, "Deferred procedure '%.*s' must have no input parameters", LIT(dst->token.string));
		} else if (dst_kind == DeferredProcedure_in) {
			if (src_params == nullptr && dst_params == nullptr) {
				// Okay
				continue;
			}
			if ((src_params == nullptr && dst_params != nullptr) ||
			    (src_params != nullptr && dst_params == nullptr)) {
				error(src->token, "Deferred procedure '%.*s' parameters do not match the inputs of initial procedure '%.*s'", LIT(src->token.string), LIT(dst->token.string));
				continue;
			}

			GB_ASSERT(src_params->kind == Type_Tuple);
			GB_ASSERT(dst_params->kind == Type_Tuple);

			if (are_types_identical(src_params, dst_params)) {
				// Okay!
			} else {
				gbString s = type_to_string(src_params);
				gbString d = type_to_string(dst_params);
				error(src->token, "Deferred procedure '%.*s' parameters do not match the inputs of initial procedure '%.*s':\n\t(%s) =/= (%s)",
				      LIT(src->token.string), LIT(dst->token.string),
				      s, d
				);
				gb_string_free(d);
				gb_string_free(s);
				continue;
			}

		} else if (dst_kind == DeferredProcedure_out) {
			if (src_results == nullptr && dst_params == nullptr) {
				// Okay
				continue;
			}
			if ((src_results == nullptr && dst_params != nullptr) ||
			    (src_results != nullptr && dst_params == nullptr)) {
				error(src->token, "Deferred procedure '%.*s' parameters do not match the results of initial procedure '%.*s'", LIT(src->token.string), LIT(dst->token.string));
				continue;
			}

			GB_ASSERT(src_results->kind == Type_Tuple);
			GB_ASSERT(dst_params->kind == Type_Tuple);

			if (are_types_identical(src_results, dst_params)) {
				// Okay!
			} else {
				gbString s = type_to_string(src_results);
				gbString d = type_to_string(dst_params);
				error(src->token, "Deferred procedure '%.*s' parameters do not match the results of initial procedure '%.*s':\n\t(%s) =/= (%s)",
				      LIT(src->token.string), LIT(dst->token.string),
				      s, d
				);
				gb_string_free(d);
				gb_string_free(s);
				continue;
			}
		} else if (dst_kind == DeferredProcedure_in_out) {
			if (src_params == nullptr && src_results == nullptr && dst_params == nullptr) {
				// Okay
				continue;
			}

			GB_ASSERT(dst_params->kind == Type_Tuple);

			Type *tsrc = alloc_type_tuple();
			auto &sv = tsrc->Tuple.variables;
			auto const &dv = dst_params->Tuple.variables;
			gb_unused(dv);

			isize len = 0;
			if (src_params != nullptr) {
				GB_ASSERT(src_params->kind == Type_Tuple);
				len += src_params->Tuple.variables.count;
			}
			if (src_results != nullptr) {
				GB_ASSERT(src_results->kind == Type_Tuple);
				len += src_results->Tuple.variables.count;
			}
			slice_init(&sv, heap_allocator(), len);
			isize offset = 0;
			if (src_params != nullptr) {
				for_array(i, src_params->Tuple.variables) {
					sv[offset++] = src_params->Tuple.variables[i];
				}
			}
			if (src_results != nullptr) {
				for_array(i, src_results->Tuple.variables) {
					sv[offset++] = src_results->Tuple.variables[i];
				}
			}
			GB_ASSERT(offset == len);


			if (are_types_identical(tsrc, dst_params)) {
				// Okay!
			} else {
				gbString s = type_to_string(tsrc);
				gbString d = type_to_string(dst_params);
				error(src->token, "Deferred procedure '%.*s' parameters do not match the results of initial procedure '%.*s':\n\t(%s) =/= (%s)",
				      LIT(src->token.string), LIT(dst->token.string),
				      s, d
				);
				gb_string_free(d);
				gb_string_free(s);
				continue;
			}
		}
	}

}

void check_unique_package_names(Checker *c) {
	StringMap<AstPackage *> pkgs = {}; // Key: package name
	string_map_init(&pkgs, heap_allocator(), 2*c->info.packages.entries.count);
	defer (string_map_destroy(&pkgs));

	for_array(i, c->info.packages.entries) {
		AstPackage *pkg = c->info.packages.entries[i].value;
		if (pkg->files.count == 0) {
			continue; // Sanity check
		}

		String name = pkg->name;
		auto key = string_hash_string(name);
		auto *found = string_map_get(&pkgs, key);
		if (found == nullptr) {
			string_map_set(&pkgs, key, pkg);
			continue;
		}
		auto *curr = pkg->files[0]->pkg_decl;
		auto *prev = (*found)->files[0]->pkg_decl;
		if (curr == prev) {
			// NOTE(bill): A false positive was found, ignore it
			continue;
		}

		error(curr, "Duplicate declaration of 'package %.*s'", LIT(name));
		error_line("\tA package name must be unique\n"
		           "\tThere is no relation between a package name and the directory that contains it, so they can be completely different\n"
		           "\tA package name is required for link name prefixing to have a consistent ABI\n");
		error(prev, "found at previous location");
	}
}

void check_add_entities_from_queues(Checker *c) {
	isize cap = c->info.entities.count + c->info.entity_queue.count.load(std::memory_order_relaxed);
	array_reserve(&c->info.entities, cap);
	for (Entity *e; mpmc_dequeue(&c->info.entity_queue, &e); /**/) {
		array_add(&c->info.entities, e);
	}
}

void check_add_definitions_from_queues(Checker *c) {
	isize cap = c->info.definitions.count + c->info.definition_queue.count.load(std::memory_order_relaxed);
	array_reserve(&c->info.definitions, cap);
	for (Entity *e; mpmc_dequeue(&c->info.definition_queue, &e); /**/) {
		array_add(&c->info.definitions, e);
	}
}

void check_merge_queues_into_arrays(Checker *c) {
	check_add_entities_from_queues(c);
	check_add_definitions_from_queues(c);
}

GB_COMPARE_PROC(init_procedures_cmp) {
	int cmp = 0;
	Entity *x = *(Entity **)a;
	Entity *y = *(Entity **)b;
	if (x == y) {
		cmp = 0;
		return cmp;
	}

	if (x->pkg != y->pkg) {
		isize order_x = x->pkg ? x->pkg->order : 0;
		isize order_y = y->pkg ? y->pkg->order : 0;
		cmp = isize_cmp(order_x, order_y);
		if (cmp) {
			return cmp;
		}
	}
	if (x->file != y->file) {
		String fullpath_x = x->file ? x->file->fullpath : (String{});
		String fullpath_y = y->file ? y->file->fullpath : (String{});
		String file_x = filename_from_path(fullpath_x);
		String file_y = filename_from_path(fullpath_y);

		cmp = string_compare(file_x, file_y);
		if (cmp) {
			return cmp;
		}
	}


	cmp = u64_cmp(x->order_in_src, y->order_in_src);
	if (cmp) {
		return cmp;
	}
	return i32_cmp(x->token.pos.offset, y->token.pos.offset);
}


void check_sort_init_procedures(Checker *c) {
	gb_sort_array(c->info.init_procedures.data, c->info.init_procedures.count, init_procedures_cmp);
}

void add_type_info_for_type_definitions(Checker *c) {
	for_array(i, c->info.definitions) {
		Entity *e = c->info.definitions[i];
		if (e->kind == Entity_TypeName && e->type != nullptr) {
			i64 align = type_align_of(e->type);
			if (align > 0 && ptr_set_exists(&c->info.minimum_dependency_set, e)) {
				add_type_info_type(&c->builtin_ctx, e->type);
			}
		}
	}
}

void check_parsed_files(Checker *c) {
	TIME_SECTION("map full filepaths to scope");
	add_type_info_type(&c->builtin_ctx, t_invalid);

	// Map full filepaths to Scopes
	for_array(i, c->parser->packages) {
		AstPackage *p = c->parser->packages[i];
		Scope *scope = create_scope_from_package(&c->builtin_ctx, p);
		p->decl_info = make_decl_info(scope, c->builtin_ctx.decl);
		string_map_set(&c->info.packages, p->fullpath, p);

		if (scope->flags&ScopeFlag_Init) {
			c->info.init_package = p;
			c->info.init_scope = scope;
		}
		if (p->kind == Package_Runtime) {
			GB_ASSERT(c->info.runtime_package == nullptr);
			c->info.runtime_package = p;
		}
	}

	TIME_SECTION("create file scopes");
	check_create_file_scopes(c);

	TIME_SECTION("collect entities");
	check_collect_entities_all(c);

	TIME_SECTION("export entities - pre");
	check_export_entities(c);

	// NOTE: Timing Section handled internally
	check_import_entities(c);

	TIME_SECTION("export entities - post");
	check_export_entities(c);

	TIME_SECTION("add entities from packages");
	check_merge_queues_into_arrays(c);

	TIME_SECTION("check all global entities");
	check_all_global_entities(c);

	TIME_SECTION("init preload");
	init_preload(c);

	TIME_SECTION("add global untyped expression to queue");
	add_untyped_expressions(&c->info, &c->info.global_untyped);

	CheckerContext prev_context = c->builtin_ctx;
	defer (c->builtin_ctx = prev_context);
	c->builtin_ctx.decl = make_decl_info(nullptr, nullptr);

	TIME_SECTION("check procedure bodies");
	check_procedure_bodies(c);

	TIME_SECTION("add entities from procedure bodies");
	check_merge_queues_into_arrays(c);

	TIME_SECTION("check scope usage");
	for_array(i, c->info.files.entries) {
		AstFile *f = c->info.files.entries[i].value;
		check_scope_usage(c, f->scope);
	}

	TIME_SECTION("add untyped expression values");
	// Add untyped expression values
	for (UntypedExprInfo u = {}; mpmc_dequeue(&c->global_untyped_queue, &u); /**/) {
		GB_ASSERT(u.expr != nullptr && u.info != nullptr);
		if (is_type_typed(u.info->type)) {
			compiler_error("%s (type %s) is typed!", expr_to_string(u.expr), type_to_string(u.info->type));
		}
		add_type_and_value(&c->info, u.expr, u.info->mode, u.info->type, u.info->value);
	}


	TIME_SECTION("add basic type information");
	// Add "Basic" type information
	for (isize i = 0; i < Basic_COUNT; i++) {
		Type *t = &basic_types[i];
		if (t->Basic.size > 0 &&
		    (t->Basic.flags & BasicFlag_LLVM) == 0) {
			add_type_info_type(&c->builtin_ctx, t);
		}
	}
	check_merge_queues_into_arrays(c);

	TIME_SECTION("check for type cycles and inline cycles");
	// NOTE(bill): Check for illegal cyclic type declarations
	for_array(i, c->info.definitions) {
		Entity *e = c->info.definitions[i];
		if (e->kind == Entity_TypeName && e->type != nullptr) {
			(void)type_align_of(e->type);
		} else if (e->kind == Entity_Procedure) {
			DeclInfo *decl = e->decl_info;
			ast_node(pl, ProcLit, decl->proc_lit);
			if (pl->inlining == ProcInlining_inline) {
				for_array(j, decl->deps.entries) {
					Entity *dep = decl->deps.entries[j].ptr;
					if (dep == e) {
						error(e->token, "Cannot inline recursive procedure '%.*s'", LIT(e->token.string));
						break;
					}
				}
			}
		}
	}

	TIME_SECTION("check deferred procedures");
	check_deferred_procedures(c);

	TIME_SECTION("calculate global init order");
	calculate_global_init_order(c);

	TIME_SECTION("check test procedures");
	check_test_procedures(c);

	TIME_SECTION("check bodies have all been checked");
	check_unchecked_bodies(c);

	TIME_SECTION("add type info for type definitions");
	add_type_info_for_type_definitions(c);
	check_merge_queues_into_arrays(c);

	TIME_SECTION("generate minimum dependency set");
	generate_minimum_dependency_set(c, c->info.entry_point);

	TIME_SECTION("check entry point");
	if (build_context.build_mode == BuildMode_Executable && !build_context.no_entry_point && build_context.command_kind != Command_test) {
		Scope *s = c->info.init_scope;
		GB_ASSERT(s != nullptr);
		GB_ASSERT(s->flags&ScopeFlag_Init);
		Entity *e = scope_lookup_current(s, str_lit("main"));
		if (e == nullptr) {
			Token token = {};
			token.pos.file_id = 0;
			token.pos.line    = 1;
			token.pos.column  = 1;
			if (s->pkg->files.count > 0) {
				AstFile *f = s->pkg->files[0];
				if (f->tokens.count > 0) {
					token = f->tokens[0];
				}
			}

			error(token, "Undefined entry point procedure 'main'");
		}
	}

	TIME_SECTION("check unique package names");
	check_unique_package_names(c);


	TIME_SECTION("sanity checks");
	GB_ASSERT(c->info.entity_queue.count.load(std::memory_order_relaxed) == 0);
	GB_ASSERT(c->info.definition_queue.count.load(std::memory_order_relaxed) == 0);

	TIME_SECTION("sort init procedures");
	check_sort_init_procedures(c);

	if (c->info.intrinsics_entry_point_usage.count > 0) {
		TIME_SECTION("check intrinsics.__entry_point usage");
		Ast *node = nullptr;
		while (mpmc_dequeue(&c->info.intrinsics_entry_point_usage, &node)) {
			if (c->info.entry_point == nullptr && node != nullptr) {
				if (node->file()->pkg->kind != Package_Runtime) {
					warning(node, "usage of intrinsics.__entry_point will be a no-op");
				}
			}
		}
	}

	TIME_SECTION("type check finish");
}
