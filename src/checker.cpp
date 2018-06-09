#include "entity.cpp"
#include "types.cpp"

void check_expr(CheckerContext *c, Operand *operand, AstNode *expression);


bool is_operand_value(Operand o) {
	switch (o.mode) {
	case Addressing_Value:
	case Addressing_Variable:
	case Addressing_Immutable:
	case Addressing_Constant:
	case Addressing_MapIndex:
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



gb_global Scope *universal_scope = nullptr;

void scope_reset(Scope *scope) {
	if (scope == nullptr) return;

	scope->first_child = nullptr;
	scope->last_child  = nullptr;
	map_clear    (&scope->elements);
	ptr_set_clear(&scope->implicit);
	ptr_set_clear(&scope->imported);
}

void scope_reserve(Scope *scope, isize capacity) {
	isize cap = 2*capacity;
	if (cap > scope->elements.hashes.capacity) {
		map_rehash(&scope->elements, capacity);
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
	isize a = x->entity->order_in_src;
	isize b = y->entity->order_in_src;
	if (x->dep_count < y->dep_count) return -1;
	if (x->dep_count > y->dep_count) return +1;
	return a < b ? -1 : b > a;
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

	bool xg = x->scope->is_global;
	bool yg = y->scope->is_global;
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
	AstNode *x = *cast(AstNode **)a;
	AstNode *y = *cast(AstNode **)b;
	Token i = ast_node_token(x);
	Token j = ast_node_token(y);
	return token_pos_cmp(i.pos, j.pos);
}






void init_decl_info(DeclInfo *d, Scope *scope, DeclInfo *parent) {
	d->parent = parent;
	d->scope  = scope;
	ptr_set_init(&d->deps,           heap_allocator());
	ptr_set_init(&d->type_info_deps, heap_allocator());
	array_init  (&d->labels,         heap_allocator());
}

DeclInfo *make_decl_info(gbAllocator a, Scope *scope, DeclInfo *parent) {
	DeclInfo *d = gb_alloc_item(a, DeclInfo);
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





Scope *create_scope(Scope *parent, gbAllocator allocator, isize init_elements_capacity=16) {
	Scope *s = gb_alloc_item(allocator, Scope);
	s->parent = parent;
	map_init(&s->elements, heap_allocator(), init_elements_capacity);
	ptr_set_init(&s->implicit, heap_allocator(), 0);
	ptr_set_init(&s->imported, heap_allocator(), 0);

	s->delayed_imports.allocator = heap_allocator();
	s->delayed_directives.allocator = heap_allocator();

	if (parent != nullptr && parent != universal_scope) {
		DLIST_APPEND(parent->first_child, parent->last_child, s);
	}
	return s;
}

Scope *create_scope_from_file(CheckerContext *c, AstFile *f) {
	GB_ASSERT(f != nullptr);
	GB_ASSERT(f->pkg != nullptr);
	GB_ASSERT(f->pkg->scope != nullptr);

	Scope *s = create_scope(f->pkg->scope, c->allocator);

	array_reserve(&s->delayed_imports, f->imports.count);
	array_reserve(&s->delayed_directives, f->directive_count);

	s->is_file = true;
	s->file = f;
	f->scope = s;

	return s;
}

Scope *create_scope_from_package(CheckerContext *c, AstPackage *p) {
	GB_ASSERT(p != nullptr);

	isize decl_count = 0;
	for_array(i, p->files) {
		decl_count += p->files[i]->decls.count;
	}
	isize init_elements_capacity = 2*decl_count;
	Scope *s = create_scope(universal_scope, c->allocator, init_elements_capacity);

	s->is_package = true;
	s->package = p;
	p->scope = s;

	if (p->fullpath == c->checker->parser->init_fullpath) {
		s->is_init = true;
	} else {
		s->is_init = p->kind == Package_Init;
	}

	if (p->kind == Package_Runtime) {
		s->is_global = true;
	}

	if (s->is_init || s->is_global) {
		s->has_been_imported = true;
	}

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

	for (Scope *child = scope->first_child; child != nullptr; child = child->next) {
		destroy_scope(child);
	}

	map_destroy(&scope->elements);
	array_free(&scope->delayed_imports);
	array_free(&scope->delayed_directives);
	ptr_set_destroy(&scope->implicit);
	ptr_set_destroy(&scope->imported);

	// NOTE(bill): No need to free scope as it "should" be allocated in an arena (except for the global scope)
}


void add_scope(CheckerContext *c, AstNode *node, Scope *scope) {
	GB_ASSERT(node != nullptr);
	GB_ASSERT(scope != nullptr);
	scope->node = node;
	node->scope = scope;
}


void check_open_scope(CheckerContext *c, AstNode *node) {
	node = unparen_expr(node);
	GB_ASSERT(node->kind == AstNode_Invalid ||
	          is_ast_node_stmt(node) ||
	          is_ast_node_type(node));
	Scope *scope = create_scope(c->scope, c->allocator);
	add_scope(c, node, scope);
	switch (node->kind) {
	case AstNode_ProcType:
		scope->is_proc = true;
		break;
	case AstNode_StructType:
	case AstNode_EnumType:
	case AstNode_UnionType:
		scope->is_struct = true;
		break;
	}
	c->scope = scope;
	c->stmt_state_flags |= StmtStateFlag_bounds_check;
}

void check_close_scope(CheckerContext *c) {
	c->scope = c->scope->parent;
}


Entity *scope_lookup_current(Scope *s, String name) {
	HashKey key = hash_string(name);
	Entity **found = map_get(&s->elements, key);
	if (found) {
		return *found;
	}
	return nullptr;
}

void scope_lookup_parent(Scope *scope, String name, Scope **scope_, Entity **entity_) {
	bool gone_thru_proc = false;
	bool gone_thru_package = false;
	HashKey key = hash_string(name);
	for (Scope *s = scope; s != nullptr; s = s->parent) {
		Entity **found = map_get(&s->elements, key);
		if (found) {
			Entity *e = *found;
			if (gone_thru_proc) {
				// IMPORTANT TODO(bill): Is this correct?!
				if (e->kind == Entity_Label) {
					continue;
				}
				if (e->kind == Entity_Variable &&
				    !e->scope->is_file) {
					continue;
				}
			}

			if (entity_) *entity_ = e;
			if (scope_) *scope_ = s;
			return;
		}

		if (s->is_proc) {
			gone_thru_proc = true;
		}
		if (s->is_package) {
			gone_thru_package = true;
		}
	}


	if (entity_) *entity_ = nullptr;
	if (scope_) *scope_ = nullptr;
}

Entity *scope_lookup(Scope *s, String name) {
	Entity *entity = nullptr;
	scope_lookup_parent(s, name, nullptr, &entity);
	return entity;
}



Entity *scope_insert(Scope *s, Entity *entity) {
	String name = entity->token.string;
	if (name == "") {
		return nullptr;
	}
	HashKey key = hash_string(name);
	Entity **found = map_get(&s->elements, key);

	if (found) {
		return *found;
	}
	map_set(&s->elements, key, entity);
	if (entity->scope == nullptr) {
		entity->scope = s;
	}
	return nullptr;
}


GB_COMPARE_PROC(entity_variable_pos_cmp) {
	Entity *x = *cast(Entity **)a;
	Entity *y = *cast(Entity **)b;

	return token_pos_cmp(x->token.pos, y->token.pos);
}


void check_scope_usage(Checker *c, Scope *scope) {
	// TODO(bill): Use this?
#if 0
	Array<Entity *> unused = {};
	array_init(&unused, heap_allocator());
	defer (array_free(&unused));

	for_array(i, scope->elements.entries) {
		Entity *e = scope->elements.entries[i].value;
		if (e != nullptr && (e->flags&EntityFlag_Used) == 0) {
			switch (e->kind) {
			case Entity_Variable:
			case Entity_ImportName:
			case Entity_LibraryName:
				array_add(&unused, e);
				break;
			}
		}
	}

	gb_sort_array(unused.data, unused.count, entity_variable_pos_cmp);

	for_array(i, unused) {
		Entity *e = unused[i];
		error(e->token, "'%.*s' declared but not used", LIT(e->token.string));
	}

	for (Scope *child = scope->first_child;
	     child != nullptr;
	     child = child->next) {
		if (!child->is_proc && !child->is_struct && !child->is_file) {
			check_scope_usage(c, child);
		}
	}
#endif
}


void add_dependency(DeclInfo *d, Entity *e) {
	ptr_set_add(&d->deps, e);
}
void add_type_info_dependency(DeclInfo *d, Type *type) {
	if (d == nullptr) {
		// GB_ASSERT(type == t_invalid);
		return;
	}
	ptr_set_add(&d->type_info_deps, type);
}

AstPackage *get_core_package(CheckerInfo *info, String name) {
	gbAllocator a = heap_allocator();
	String path = get_fullpath_core(a, name);
	defer (gb_free(a, path.text));
	HashKey key = hash_string(path);
	auto found = map_get(&info->packages, key);
	GB_ASSERT_MSG(found != nullptr, "Missing core package %.*s", LIT(name));
	return *found;
}


void add_package_dependency(CheckerContext *c, char *package_name, char *name) {
	String n = make_string_c(name);
	AstPackage *p = get_core_package(&c->checker->info, make_string_c(package_name));
	Entity *e = scope_lookup(p->scope, n);
	GB_ASSERT_MSG(e != nullptr, "%s", name);
	ptr_set_add(&c->decl->deps, e);
	// add_type_info_type(c, e->type);
}

void add_declaration_dependency(CheckerContext *c, Entity *e) {
	if (e == nullptr) {
		return;
	}
	if (c->decl != nullptr) {
		add_dependency(c->decl, e);
	}
}


Entity *add_global_entity(Entity *entity) {
	String name = entity->token.string;
	if (gb_memchr(name.text, ' ', name.len)) {
		return entity; // NOTE(bill): 'untyped thing'
	}
	if (scope_insert(universal_scope, entity)) {
		compiler_error("double declaration");
	}
	entity->state = EntityState_Resolved;
	return entity;
}

void add_global_constant(String name, Type *type, ExactValue value) {
	Entity *entity = alloc_entity(Entity_Constant, nullptr, make_token_ident(name), type);
	entity->Constant.value = value;
	add_global_entity(entity);
}


void add_global_string_constant(String name, String value) {
	add_global_constant(name, t_untyped_string, exact_value_string(value));
}


void add_global_type_entity(String name, Type *type) {
	add_global_entity(alloc_entity_type_name(nullptr, make_token_ident(name), type));
}



void init_universal_scope(void) {
	BuildContext *bc = &build_context;
	// NOTE(bill): No need to free these
	gbAllocator a = heap_allocator();
	universal_scope = create_scope(nullptr, a);
	universal_scope->is_package = true;

// Types
	for (isize i = 0; i < gb_count_of(basic_types); i++) {
		add_global_type_entity(basic_types[i].Basic.name, &basic_types[i]);
	}
	add_global_type_entity(str_lit("byte"), &basic_types[Basic_u8]);

// Constants
	add_global_constant(str_lit("true"),  t_untyped_bool, exact_value_bool(true));
	add_global_constant(str_lit("false"), t_untyped_bool, exact_value_bool(false));

	add_global_entity(alloc_entity_nil(str_lit("nil"), t_untyped_nil));
	// add_global_entity(alloc_entity_library_name(universal_scope,
	//                                             make_token_ident(str_lit("__llvm_core")), t_invalid,
	//                                             str_lit(""), str_lit("__llvm_core")));

	// TODO(bill): Set through flags in the compiler
	add_global_string_constant(str_lit("ODIN_VENDOR"),  bc->ODIN_VENDOR);
	add_global_string_constant(str_lit("ODIN_VERSION"), bc->ODIN_VERSION);
	add_global_string_constant(str_lit("ODIN_ROOT"),    bc->ODIN_ROOT);
	add_global_constant(str_lit("ODIN_DEBUG"), t_untyped_bool, exact_value_bool(bc->ODIN_DEBUG));


// Builtin Procedures
	for (isize i = 0; i < gb_count_of(builtin_procs); i++) {
		BuiltinProcId id = cast(BuiltinProcId)i;
		String name = builtin_procs[i].name;
		if (name != "") {
			Entity *entity = alloc_entity(Entity_Builtin, nullptr, make_token_ident(name), t_invalid);
			entity->Builtin.id = id;
			add_global_entity(entity);
		}
	}


	t_u8_ptr       = alloc_type_pointer(t_u8);
	t_int_ptr      = alloc_type_pointer(t_int);
	t_i64_ptr      = alloc_type_pointer(t_i64);
	t_f64_ptr      = alloc_type_pointer(t_f64);
	t_u8_slice     = alloc_type_slice(t_u8);
	t_string_slice = alloc_type_slice(t_string);
}




void init_checker_info(CheckerInfo *i) {
	gbAllocator a = heap_allocator();
	map_init(&i->types,           a);
	array_init(&i->definitions,   a);
	array_init(&i->entities,      a);
	map_init(&i->untyped,         a);
	map_init(&i->foreigns,        a);
	map_init(&i->gen_procs,       a);
	map_init(&i->gen_types,       a);
	array_init(&i->type_info_types, a);
	map_init(&i->type_info_map,   a);
	map_init(&i->files,           a);
	map_init(&i->packages,        a);
	array_init(&i->variable_init_order, a);
}

void destroy_checker_info(CheckerInfo *i) {
	map_destroy(&i->types);
	array_free(&i->definitions);
	array_free(&i->entities);
	map_destroy(&i->untyped);
	map_destroy(&i->foreigns);
	map_destroy(&i->gen_procs);
	map_destroy(&i->gen_types);
	array_free(&i->type_info_types);
	map_destroy(&i->type_info_map);
	map_destroy(&i->files);
	map_destroy(&i->packages);
	array_free(&i->variable_init_order);
}

CheckerContext make_checker_context(Checker *c) {
	CheckerContext ctx = c->init_ctx;
	ctx.checker   = c;
	ctx.info      = &c->info;
	ctx.allocator = c->allocator;
	ctx.scope     = universal_scope;

	ctx.type_path = new_checker_type_path();
	ctx.type_level = 0;
	return ctx;
}

void destroy_checker_context(CheckerContext *ctx) {
	destroy_checker_type_path(ctx->type_path);
}

void init_checker(Checker *c, Parser *parser) {
	if (global_error_collector.count > 0) {
		gb_exit(1);
	}
	gbAllocator a = heap_allocator();

	c->parser = parser;
	init_checker_info(&c->info);

	array_init(&c->procs_to_check, a);
	ptr_set_init(&c->checked_packages, a);

	// NOTE(bill): Is this big enough or too small?
	isize item_size = gb_max3(gb_size_of(Entity), gb_size_of(Type), gb_size_of(Scope));
	isize total_token_count = c->parser->total_token_count;
	isize arena_size = 2 * item_size * total_token_count;

	c->allocator = heap_allocator();

	c->init_ctx = make_checker_context(c);
}

void destroy_checker(Checker *c) {
	destroy_checker_info(&c->info);

	array_free(&c->procs_to_check);
	ptr_set_destroy(&c->checked_packages);

	destroy_checker_context(&c->init_ctx);
}


Entity *entity_of_ident(AstNode *identifier) {
	if (identifier->kind == AstNode_Ident) {
		return identifier->Ident.entity;
	}
	return nullptr;
}

TypeAndValue type_and_value_of_expr(CheckerInfo *i, AstNode *expr) {
	TypeAndValue result = {};
	TypeAndValue *found = map_get(&i->types, hash_node(expr));
	if (found) result = *found;
	return result;
}

Type *type_of_expr(CheckerInfo *i, AstNode *expr) {
	TypeAndValue tav = type_and_value_of_expr(i, expr);
	if (tav.mode != Addressing_Invalid) {
		return tav.type;
	}
	if (expr->kind == AstNode_Ident) {
		Entity *entity = entity_of_ident(expr);
		if (entity) {
			return entity->type;
		}
	}

	return nullptr;
}

Entity *implicit_entity_of_node(CheckerInfo *i, AstNode *clause) {
	// Entity **found = map_get(&i->implicits, hash_node(clause));
	// if (found != nullptr) {
		// return *found;
	// }
	if (clause->kind == AstNode_CaseClause) {
		return clause->CaseClause.implicit_entity;
	}
	return nullptr;
}
bool is_entity_implicitly_imported(Entity *import_name, Entity *e) {
	GB_ASSERT(import_name->kind == Entity_ImportName);
	return ptr_set_exists(&import_name->ImportName.scope->implicit, e);
}

// Will return nullptr if not found
Entity *entity_of_node(CheckerInfo *i, AstNode *expr) {
	expr = unparen_expr(expr);
	switch (expr->kind) {
	case_ast_node(ident, Ident, expr);
		return entity_of_ident(expr);
	case_end;
	case_ast_node(se, SelectorExpr, expr);
		AstNode *s = unselector_expr(se->selector);
		if (s->kind == AstNode_Ident) {
			return entity_of_ident(s);
		}
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

DeclInfo *decl_info_of_ident(AstNode *ident) {
	return decl_info_of_entity(entity_of_ident(ident));
}

AstFile *ast_file_of_filename(CheckerInfo *i, String filename) {
	AstFile **found = map_get(&i->files, hash_string(filename));
	if (found != nullptr) {
		return *found;
	}
	return nullptr;
}
Scope *scope_of_node(AstNode *node) {
	return node->scope;
}
ExprInfo *check_get_expr_info(CheckerInfo *i, AstNode *expr) {
	return map_get(&i->untyped, hash_node(expr));
}
void check_set_expr_info(CheckerInfo *i, AstNode *expr, ExprInfo info) {
	map_set(&i->untyped, hash_node(expr), info);
}
void check_remove_expr_info(CheckerInfo *i, AstNode *expr) {
	map_remove(&i->untyped, hash_node(expr));
}



isize type_info_index(CheckerInfo *info, Type *type, bool error_on_failure) {
	type = default_type(type);
	if (type == t_llvm_bool) {
		type = t_bool;
	}

	isize entry_index = -1;
	HashKey key = hash_type(type);
	isize *found_entry_index = map_get(&info->type_info_map, key);
	if (found_entry_index) {
		entry_index = *found_entry_index;
	}
	if (entry_index < 0) {
		// NOTE(bill): Do manual search
		// TODO(bill): This is O(n) and can be very slow
		for_array(i, info->type_info_map.entries){
			auto *e = &info->type_info_map.entries[i];
			Type *prev_type = cast(Type *)e->key.ptr;
			if (are_types_identical(prev_type, type)) {
				entry_index = e->value;
				// NOTE(bill): Add it to the search map
				map_set(&info->type_info_map, key, entry_index);
				break;
			}
		}
	}

	if (error_on_failure && entry_index < 0) {
		compiler_error("Type_Info for '%s' could not be found", type_to_string(type));
	}
	return entry_index;
}


void add_untyped(CheckerInfo *i, AstNode *expression, bool lhs, AddressingMode mode, Type *type, ExactValue value) {
	if (expression == nullptr) {
		return;
	}
	if (mode == Addressing_Invalid) {
		return;
	}
	if (mode == Addressing_Constant && type == t_invalid) {
		compiler_error("add_untyped - invalid type: %s", type_to_string(type));
	}
	map_set(&i->untyped, hash_node(expression), make_expr_info(mode, type, value, lhs));
}

void add_type_and_value(CheckerInfo *i, AstNode *expression, AddressingMode mode, Type *type, ExactValue value) {
	if (expression == nullptr) {
		return;
	}
	if (mode == Addressing_Invalid) {
		return;
	}
	if (mode == Addressing_Constant && type == t_invalid) {
		return;
	}

	TypeAndValue tv = {};
	tv.type  = type;
	tv.value = value;
	tv.mode  = mode;
	map_set(&i->types, hash_node(expression), tv);
}

void add_entity_definition(CheckerInfo *i, AstNode *identifier, Entity *entity) {
	GB_ASSERT(identifier != nullptr);
	GB_ASSERT(identifier->kind == AstNode_Ident);
	if (is_blank_ident(identifier)) {
		return;
	}
	if (identifier->Ident.entity != nullptr) {
		// NOTE(bill): Identifier has already been handled
		return;
	}
	GB_ASSERT(entity != nullptr);

	identifier->Ident.entity = entity;
	entity->identifier = identifier;
	array_add(&i->definitions, entity);
}

bool add_entity(Checker *c, Scope *scope, AstNode *identifier, Entity *entity) {
	if (scope == nullptr) {
		return false;
	}
	String name = entity->token.string;
	if (!is_blank_ident(name)) {
		Entity *ie = scope_insert(scope, entity);
		if (ie != nullptr) {
			TokenPos pos = ie->token.pos;
			Entity *up = ie->using_parent;
			if (up != nullptr) {
				if (pos == up->token.pos) {
					// NOTE(bill): Error should have been handled already
					return false;
				}
				error(entity->token,
				      "Redeclaration of '%.*s' in this scope through 'using'\n"
				      "\tat %.*s(%td:%td)",
				      LIT(name),
				      LIT(up->token.pos.file), up->token.pos.line, up->token.pos.column);
				return false;
			} else {
				if (pos == entity->token.pos) {
					// NOTE(bill): Error should have been handled already
					return false;
				}
				error(entity->token,
				      "Redeclaration of '%.*s' in this scope\n"
				      "\tat %.*s(%td:%td)",
				      LIT(name),
				      LIT(pos.file), pos.line, pos.column);
				return false;
			}
		}
	}
	if (identifier != nullptr) {
		add_entity_definition(&c->info, identifier, entity);
	}
	return true;
}

void add_entity_use(CheckerContext *c, AstNode *identifier, Entity *entity) {
	if (entity == nullptr) {
		return;
	}
	if (identifier != nullptr) {
		if (identifier->kind != AstNode_Ident) {
			return;
		}
		if (entity->identifier == nullptr) {
			entity->identifier = identifier;
		}
		identifier->Ident.entity = entity;

		String dmsg = entity->deprecated_message;
		if (dmsg.len > 0) {
			warning(identifier, "%.*s is deprecated: %.*s", LIT(entity->token.string), LIT(dmsg));
		}
	}
	entity->flags |= EntityFlag_Used;
	add_declaration_dependency(c, entity);
}


void add_entity_and_decl_info(CheckerContext *c, AstNode *identifier, Entity *e, DeclInfo *d) {
	GB_ASSERT(identifier->kind == AstNode_Ident);
	GB_ASSERT(e != nullptr && d != nullptr);
	GB_ASSERT(identifier->Ident.token.string == e->token.string);

	if (e->scope != nullptr) {
		Scope *scope = e->scope;
		if (scope->is_file && is_entity_kind_exported(e->kind)) {
			AstPackage *pkg = scope->file->pkg;
			GB_ASSERT(pkg->scope == scope->parent);
			GB_ASSERT(c->pkg == pkg);
			scope = pkg->scope;
		}
		add_entity(c->checker, scope, identifier, e);
	}

	add_entity_definition(&c->checker->info, identifier, e);
	GB_ASSERT(e->decl_info == nullptr);
	e->decl_info = d;
	array_add(&c->checker->info.entities, e);
	e->order_in_src = c->checker->info.entities.count;
	e->pkg = c->pkg;
}


void add_implicit_entity(CheckerContext *c, AstNode *clause, Entity *e) {
	GB_ASSERT(clause != nullptr);
	GB_ASSERT(e != nullptr);
	GB_ASSERT(clause->kind == AstNode_CaseClause);
	clause->CaseClause.implicit_entity = e;
}





void add_type_info_type(CheckerContext *c, Type *t) {
	if (t == nullptr) {
		return;
	}
	t = default_type(t);
	if (is_type_bit_field_value(t)) {
		t = default_bit_field_value_type(t);
	}
	if (is_type_untyped(t)) {
		return; // Could be nil
	}
	if (is_type_polymorphic(base_type(t))) {
		return;
	}

	add_type_info_dependency(c->decl, t);

	auto found = map_get(&c->info->type_info_map, hash_type(t));
	if (found != nullptr) {
		// Types have already been added
		return;
	}

	bool prev = false;
	isize ti_index = -1;
	for_array(i, c->info->type_info_map.entries) {
		auto *e = &c->info->type_info_map.entries[i];
		Type *prev_type = cast(Type *)e->key.ptr;
		if (are_types_identical(t, prev_type)) {
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
	map_set(&c->checker->info.type_info_map, hash_type(t), ti_index);

	if (prev) {
		// NOTE(bill): If a previous one exists already, no need to continue
		return;
	}

	// Add nested types

	if (t->kind == Type_Named) {
		// NOTE(bill): Just in case
		add_type_info_type(c, t->Named.base);
		return;
	}

	Type *bt = base_type(t);
	add_type_info_type(c, bt);

	switch (bt->kind) {
	case Type_Basic:
		switch (bt->Basic.kind) {
		case Basic_string:
			add_type_info_type(c, t_u8_ptr);
			add_type_info_type(c, t_int);
			break;
		case Basic_any:
			add_type_info_type(c, t_type_info_ptr);
			add_type_info_type(c, t_rawptr);
			break;
		case Basic_typeid:
			break;

		case Basic_complex64:
			add_type_info_type(c, t_type_info_float);
			add_type_info_type(c, t_f32);
			break;
		case Basic_complex128:
			add_type_info_type(c, t_type_info_float);
			add_type_info_type(c, t_f64);
			break;
		}
		break;

	case Type_Pointer:
		add_type_info_type(c, bt->Pointer.elem);
		break;

	case Type_Array:
		add_type_info_type(c, bt->Array.elem);
		add_type_info_type(c, alloc_type_pointer(bt->Array.elem));
		add_type_info_type(c, t_int);
		break;
	case Type_DynamicArray:
		add_type_info_type(c, bt->DynamicArray.elem);
		add_type_info_type(c, alloc_type_pointer(bt->DynamicArray.elem));
		add_type_info_type(c, t_int);
		add_type_info_type(c, t_allocator);
		break;
	case Type_Slice:
		add_type_info_type(c, bt->Slice.elem);
		add_type_info_type(c, alloc_type_pointer(bt->Slice.elem));
		add_type_info_type(c, t_int);
		break;

	case Type_Enum:
		add_type_info_type(c, bt->Enum.base_type);
		break;

	case Type_Union:
		add_type_info_type(c, t_int);
		add_type_info_type(c, t_type_info_ptr);
		for_array(i, bt->Union.variants) {
			add_type_info_type(c, bt->Union.variants[i]);
		}
		break;

	case Type_Struct:
		if (bt->Struct.scope != nullptr) {
			for_array(i, bt->Struct.scope->elements.entries) {
				Entity *e = bt->Struct.scope->elements.entries[i].value;
				add_type_info_type(c, e->type);
			}
		}
		for_array(i, bt->Struct.fields) {
			Entity *f = bt->Struct.fields[i];
			add_type_info_type(c, f->type);
		}
		break;

	case Type_Map:
		init_map_internal_types(bt);
		add_type_info_type(c, bt->Map.key);
		add_type_info_type(c, bt->Map.value);
		add_type_info_type(c, bt->Map.generated_struct_type);
		break;

	case Type_Tuple:
		for_array(i, bt->Tuple.variables) {
			Entity *var = bt->Tuple.variables[i];
			add_type_info_type(c, var->type);
		}
		break;

	case Type_Proc:
		add_type_info_type(c, bt->Proc.params);
		add_type_info_type(c, bt->Proc.results);
		break;
	}
}

void check_procedure_later(Checker *c, ProcedureInfo info) {
	GB_ASSERT(info.decl != nullptr);
	array_add(&c->procs_to_check, info);
}

void check_procedure_later(Checker *c, AstFile *file, Token token, DeclInfo *decl, Type *type, AstNode *body, u64 tags) {
	ProcedureInfo info = {};
	info.file  = file;
	info.token = token;
	info.decl  = decl;
	info.type  = type;
	info.body  = body;
	info.tags  = tags;
	check_procedure_later(c, info);
}

void add_curr_ast_file(CheckerContext *ctx, AstFile *file) {
	if (file != nullptr) {
		TokenPos zero_pos = {};
		global_error_collector.prev = zero_pos;
		ctx->file  = file;
		ctx->decl  = file->pkg->decl_info;
		ctx->scope = file->scope;
		ctx->pkg   = file->pkg;
	}
}

void add_min_dep_type_info(Checker *c, Type *t) {
	if (t == nullptr) {
		return;
	}
	t = default_type(t);
	if (is_type_bit_field_value(t)) {
		t = default_bit_field_value_type(t);
	}
	if (is_type_untyped(t)) {
		return; // Could be nil
	}
	if (is_type_polymorphic(base_type(t))) {
		return;
	}

	auto *set = &c->info.minimum_dependency_type_info_set;

	isize ti_index = type_info_index(&c->info, t);
	if (ptr_set_exists(set, ti_index)) {
		// Type Already exists
		return;
	}
	ptr_set_add(set, ti_index);

	// Add nested types
	if (t->kind == Type_Named) {
		// NOTE(bill): Just in case
		add_min_dep_type_info(c, t->Named.base);
		return;
	}

	Type *bt = base_type(t);
	add_min_dep_type_info(c, bt);

	switch (bt->kind) {
	case Type_Basic:
		switch (bt->Basic.kind) {
		case Basic_string:
			add_min_dep_type_info(c, t_u8_ptr);
			add_min_dep_type_info(c, t_int);
			break;
		case Basic_any:
			add_min_dep_type_info(c, t_type_info_ptr);
			add_min_dep_type_info(c, t_rawptr);
			break;

		case Basic_complex64:
			add_min_dep_type_info(c, t_type_info_float);
			add_min_dep_type_info(c, t_f32);
			break;
		case Basic_complex128:
			add_min_dep_type_info(c, t_type_info_float);
			add_min_dep_type_info(c, t_f64);
			break;
		}
		break;

	case Type_Pointer:
		add_min_dep_type_info(c, bt->Pointer.elem);
		break;

	case Type_Array:
		add_min_dep_type_info(c, bt->Array.elem);
		add_min_dep_type_info(c, alloc_type_pointer(bt->Array.elem));
		add_min_dep_type_info(c, t_int);
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
		add_min_dep_type_info(c, t_int);
		add_min_dep_type_info(c, t_type_info_ptr);
		for_array(i, bt->Union.variants) {
			add_min_dep_type_info(c, bt->Union.variants[i]);
		}
		break;

	case Type_Struct:
		if (bt->Struct.scope != nullptr) {
			for_array(i, bt->Struct.scope->elements.entries) {
				Entity *e = bt->Struct.scope->elements.entries[i].value;
				add_min_dep_type_info(c, e->type);
			}
		}
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
	}
}


void add_dependency_to_set(Checker *c, Entity *entity) {
	if (entity == nullptr) {
		return;
	}

	CheckerInfo *info = &c->info;
	auto *set = &info->minimum_dependency_set;

	String name = entity->token.string;

	if (entity->type != nullptr &&
	    is_type_polymorphic(entity->type)) {

		DeclInfo *decl = decl_info_of_entity(entity);
		if (decl != nullptr && decl->gen_proc_type == nullptr) {
			return;
		}
	}

	if (ptr_set_exists(set, entity)) {
		return;
	}


	ptr_set_add(set, entity);
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
				              "%.*s", LIT(name));
				add_dependency_to_set(c, fl);
			}
		}
		if (e->kind == Entity_Variable && e->Variable.is_foreign) {
			Entity *fl = e->Variable.foreign_library;
			if (fl != nullptr) {
				GB_ASSERT_MSG(fl->kind == Entity_LibraryName &&
				              (fl->flags&EntityFlag_Used),
				              "%.*s", LIT(name));
				add_dependency_to_set(c, fl);
			}
		}
	}
}


void generate_minimum_dependency_set(Checker *c, Entity *start) {
	ptr_set_init(&c->info.minimum_dependency_set, heap_allocator());
	ptr_set_init(&c->info.minimum_dependency_type_info_set, heap_allocator());

	String required_builtin_entities[] = {
		str_lit("__init_context"),

		str_lit("args__"),
		str_lit("type_table"),

		str_lit("Type_Info"),
		str_lit("Source_Code_Location"),
		str_lit("Context"),
	};
	for (isize i = 0; i < gb_count_of(required_builtin_entities); i++) {
		add_dependency_to_set(c, scope_lookup(c->info.runtime_package->scope, required_builtin_entities[i]));
	}

	AstPackage *mem = get_core_package(&c->info, str_lit("mem"));
	String required_mem_entities[] = {
		str_lit("zero"),
		str_lit("Allocator"),
	};
	for (isize i = 0; i < gb_count_of(required_mem_entities); i++) {
		add_dependency_to_set(c, scope_lookup(mem->scope, required_mem_entities[i]));
	}

	AstPackage *os = get_core_package(&c->info, str_lit("os"));
	String required_os_entities[] = {
		str_lit("heap_allocator"),
	};
	for (isize i = 0; i < gb_count_of(required_os_entities); i++) {
		add_dependency_to_set(c, scope_lookup(os->scope, required_mem_entities[i]));
	}


	if (!build_context.no_bounds_check) {
		String bounds_check_entities[] = {
			str_lit("bounds_check_error"),
			str_lit("slice_expr_error"),
			str_lit("dynamic_array_expr_error"),
		};
		for (isize i = 0; i < gb_count_of(bounds_check_entities); i++) {
			add_dependency_to_set(c, scope_lookup(c->info.runtime_package->scope, bounds_check_entities[i]));
		}
	}

	for_array(i, c->info.definitions) {
		Entity *e = c->info.definitions[i];
		// if (e->scope->is_global && !is_type_poly_proc(e->type)) { // TODO(bill): is the check enough?
		if (e->scope == universal_scope) { // TODO(bill): is the check enough?
			if (e->type == nullptr) {
				add_dependency_to_set(c, e);
			}
		} else if (e->kind == Entity_Procedure && e->Procedure.is_export) {
			add_dependency_to_set(c, e);
		} else if (e->kind == Entity_Variable && e->Procedure.is_export) {
			add_dependency_to_set(c, e);
		}
	}

	add_dependency_to_set(c, start);
}

bool is_entity_a_dependency(Entity *e) {
	if (e == nullptr) return false;
	switch (e->kind) {
	case Entity_Procedure:
	case Entity_Variable:
	case Entity_Constant:
		return true;
	}
	return false;
}

Array<EntityGraphNode *> generate_entity_dependency_graph(CheckerInfo *info) {
	gbAllocator a = heap_allocator();

	Map<EntityGraphNode *> M = {}; // Key: Entity *
	map_init(&M, a, info->entities.count);
	defer (map_destroy(&M));
	for_array(i, info->entities) {
		Entity *e = info->entities[i];
		DeclInfo *d = e->decl_info;
		if (is_entity_a_dependency(e)) {
			EntityGraphNode *n = gb_alloc_item(a, EntityGraphNode);
			n->entity = e;
			map_set(&M, hash_pointer(e), n);
		}
	}

	// Calculate edges for graph M
	for_array(i, M.entries) {
		Entity *   e = cast(Entity *)M.entries[i].key.ptr;
		EntityGraphNode *n = M.entries[i].value;

		DeclInfo *decl = decl_info_of_entity(e);
		if (decl != nullptr) {
			for_array(j, decl->deps.entries) {
				auto entry = decl->deps.entries[j];
				Entity *dep = entry.ptr;
				if (dep && is_entity_a_dependency(dep)) {
					EntityGraphNode **m_ = map_get(&M, hash_pointer(dep));
					if (m_ != nullptr) {
						EntityGraphNode *m = *m_;
						entity_graph_node_set_add(&n->succ, m);
						entity_graph_node_set_add(&m->pred, n);
					}
				}
			}
		}
	}

	auto G = array_make<EntityGraphNode *>(a, 0, M.entries.count);

	for_array(i, M.entries) {
		auto *entry = &M.entries[i];
		auto *e = cast(Entity *)entry->key.ptr;
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
		} else {
			array_add(&G, n);
		}
	}

	for_array(i, G) {
		EntityGraphNode *n = G[i];
		n->index = i;
		n->dep_count = n->succ.entries.count;
		GB_ASSERT(n->dep_count >= 0);
	}

	return G;
}




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




void check_entity_decl(CheckerContext *c, Entity *e, DeclInfo *d, Type *named_type);

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

	GB_ASSERT(tis->fields.count == 4);

	Entity *type_info_variant = tis->fields[3];
	Type *tiv_type = type_info_variant->type;
	GB_ASSERT(is_type_union(tiv_type));

	t_type_info_named         = find_core_type(c, str_lit("Type_Info_Named"));
	t_type_info_integer       = find_core_type(c, str_lit("Type_Info_Integer"));
	t_type_info_rune          = find_core_type(c, str_lit("Type_Info_Rune"));
	t_type_info_float         = find_core_type(c, str_lit("Type_Info_Float"));
	t_type_info_complex       = find_core_type(c, str_lit("Type_Info_Complex"));
	t_type_info_string        = find_core_type(c, str_lit("Type_Info_String"));
	t_type_info_boolean       = find_core_type(c, str_lit("Type_Info_Boolean"));
	t_type_info_any           = find_core_type(c, str_lit("Type_Info_Any"));
	t_type_info_typeid        = find_core_type(c, str_lit("Type_Info_Type_Id"));
	t_type_info_pointer       = find_core_type(c, str_lit("Type_Info_Pointer"));
	t_type_info_procedure     = find_core_type(c, str_lit("Type_Info_Procedure"));
	t_type_info_array         = find_core_type(c, str_lit("Type_Info_Array"));
	t_type_info_dynamic_array = find_core_type(c, str_lit("Type_Info_Dynamic_Array"));
	t_type_info_slice         = find_core_type(c, str_lit("Type_Info_Slice"));
	t_type_info_tuple         = find_core_type(c, str_lit("Type_Info_Tuple"));
	t_type_info_struct        = find_core_type(c, str_lit("Type_Info_Struct"));
	t_type_info_union         = find_core_type(c, str_lit("Type_Info_Union"));
	t_type_info_enum          = find_core_type(c, str_lit("Type_Info_Enum"));
	t_type_info_map           = find_core_type(c, str_lit("Type_Info_Map"));
	t_type_info_bit_field     = find_core_type(c, str_lit("Type_Info_Bit_Field"));

	t_type_info_named_ptr         = alloc_type_pointer(t_type_info_named);
	t_type_info_integer_ptr       = alloc_type_pointer(t_type_info_integer);
	t_type_info_rune_ptr          = alloc_type_pointer(t_type_info_rune);
	t_type_info_float_ptr         = alloc_type_pointer(t_type_info_float);
	t_type_info_complex_ptr       = alloc_type_pointer(t_type_info_complex);
	t_type_info_string_ptr        = alloc_type_pointer(t_type_info_string);
	t_type_info_boolean_ptr       = alloc_type_pointer(t_type_info_boolean);
	t_type_info_any_ptr           = alloc_type_pointer(t_type_info_any);
	t_type_info_typeid_ptr        = alloc_type_pointer(t_type_info_typeid);
	t_type_info_pointer_ptr       = alloc_type_pointer(t_type_info_pointer);
	t_type_info_procedure_ptr     = alloc_type_pointer(t_type_info_procedure);
	t_type_info_array_ptr         = alloc_type_pointer(t_type_info_array);
	t_type_info_dynamic_array_ptr = alloc_type_pointer(t_type_info_dynamic_array);
	t_type_info_slice_ptr         = alloc_type_pointer(t_type_info_slice);
	t_type_info_tuple_ptr         = alloc_type_pointer(t_type_info_tuple);
	t_type_info_struct_ptr        = alloc_type_pointer(t_type_info_struct);
	t_type_info_union_ptr         = alloc_type_pointer(t_type_info_union);
	t_type_info_enum_ptr          = alloc_type_pointer(t_type_info_enum);
	t_type_info_map_ptr           = alloc_type_pointer(t_type_info_map);
	t_type_info_bit_field_ptr     = alloc_type_pointer(t_type_info_bit_field);
}

void init_core_allocator(Checker *c) {
	if (t_allocator != nullptr) {
		return;
	}
	AstPackage *pkg = get_core_package(&c->info, str_lit("mem"));

	String name = str_lit("Allocator");
	Entity *e = scope_lookup_current(pkg->scope, name);
	if (e == nullptr) {
		compiler_error("Could not find type declaration for '%.*s'\n", LIT(name));
		// NOTE(bill): This will exit the program as it's cannot continue without it!
	}

	t_allocator = e->type;
	t_allocator_ptr = alloc_type_pointer(t_allocator);
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
	if (t_map_key == nullptr) {
		t_map_key = find_core_type(c, str_lit("Map_Key"));
	}

	if (t_map_header == nullptr) {
		t_map_header = find_core_type(c, str_lit("Map_Header"));
	}
}

void init_preload(Checker *c) {
	init_core_type_info(c);
	init_core_allocator(c);
	init_core_context(c);
	init_core_source_code_location(c);
	init_core_map_type(c);
}




DECL_ATTRIBUTE_PROC(foreign_block_decl_attribute) {
	if (name == "default_calling_convention") {
		if (value.kind == ExactValue_String) {
			auto cc = string_to_calling_convention(value.value_string);
			if (cc == ProcCC_Invalid) {
				error(elem, "Unknown procedure calling convention: '%.*s'\n", LIT(value.value_string));
			} else {
				c->foreign_context.default_cc = cc;
			}
		} else {
			error(elem, "Expected a string value for '%.*s'", LIT(name));
		}
		return true;
	} else if (name == "link_prefix") {
		if (value.kind == ExactValue_String) {
			String link_prefix = value.value_string;
			if (!is_foreign_name_valid(link_prefix)) {
				error(elem, "Invalid link prefix: '%.*s'\n", LIT(link_prefix));
			} else {
				c->foreign_context.link_prefix = link_prefix;
			}
		} else {
			error(elem, "Expected a string value for '%.*s'", LIT(name));
		}
		return true;
	}

	return false;
}

DECL_ATTRIBUTE_PROC(proc_decl_attribute) {
	if (name == "link_name") {
		if (value.kind == ExactValue_String) {
			ac->link_name = value.value_string;
			if (!is_foreign_name_valid(ac->link_name)) {
				error(elem, "Invalid link name: %.*s", LIT(ac->link_name));
			}
		} else {
			error(elem, "Expected a string value for '%.*s'", LIT(name));
		}
		return true;
	} else if (name == "link_prefix") {
		if (value.kind == ExactValue_String) {
			ac->link_prefix = value.value_string;
			if (!is_foreign_name_valid(ac->link_prefix)) {
				error(elem, "Invalid link prefix: %.*s", LIT(ac->link_prefix));
			}
		} else {
			error(elem, "Expected a string value for '%.*s'", LIT(name));
		}
		return true;
	} else if (name == "deprecated") {
		if (value.kind == ExactValue_String) {
			String msg = value.value_string;
			if (msg.len == 0) {
				error(elem, "Deprecation message cannot be an empty string");
			} else {
				ac->deprecated_message = msg;
			}
		} else {
			error(elem, "Expected a string value for '%.*s'", LIT(name));
		}
		return true;
	}
	return false;
}

DECL_ATTRIBUTE_PROC(var_decl_attribute) {
	if (c->curr_proc_decl != nullptr) {
		error(elem, "Only a variable at file scope can have a '%.*s'", LIT(name));
		return true;
	}

	if (name == "link_name") {
		if (value.kind == ExactValue_String) {
			ac->link_name = value.value_string;
			if (!is_foreign_name_valid(ac->link_name)) {
				error(elem, "Invalid link name: %.*s", LIT(ac->link_name));
			}
		} else {
			error(elem, "Expected a string value for '%.*s'", LIT(name));
		}
		return true;
	} else if (name == "link_prefix") {
		if (value.kind == ExactValue_String) {
			ac->link_prefix = value.value_string;
			if (!is_foreign_name_valid(ac->link_prefix)) {
				error(elem, "Invalid link prefix: %.*s", LIT(ac->link_prefix));
			}
		} else {
			error(elem, "Expected a string value for '%.*s'", LIT(name));
		}
		return true;
	} else if (name == "thread_local") {
		if (ac->init_expr_list_count > 0) {
			error(elem, "A thread local variable declaration cannot have initialization values");
		} else if (c->foreign_context.curr_library || c->foreign_context.in_export) {
			error(elem, "A foreign block variable cannot be thread local");
		} else if (value.kind == ExactValue_Invalid) {
			ac->thread_local_model = str_lit("default");
		} else if (value.kind == ExactValue_String) {
			String model = value.value_string;
			if (model == "default" ||
			    model == "localdynamic" ||
			    model == "initialexec" ||
			    model == "localexec") {
				ac->thread_local_model = model;
			} else {
				error(elem, "Invalid thread local model '%.*s'", LIT(model));
			}
		} else {
			error(elem, "Expected either no value or a string for '%.*s'", LIT(name));
		}
		return true;
	}
	return false;
}




#include "check_expr.cpp"
#include "check_type.cpp"
#include "check_decl.cpp"
#include "check_stmt.cpp"



void check_decl_attributes(CheckerContext *c, Array<AstNode *> const &attributes, DeclAttributeProc *proc, AttributeContext *ac) {
	if (attributes.count == 0) return;

	String original_link_prefix = {};
	if (ac) {
		original_link_prefix = ac->link_prefix;
	}

	StringSet set = {};
	string_set_init(&set, heap_allocator());
	defer (string_set_destroy(&set));

	for_array(i, attributes) {
		AstNode *attr = attributes[i];
		if (attr->kind != AstNode_Attribute) continue;
		for_array(j, attr->Attribute.elems) {
			AstNode *elem = attr->Attribute.elems[j];
			String name = {};
			AstNode *value = nullptr;

			switch (elem->kind) {
			case_ast_node(i, Ident, elem);
				name = i->token.string;
			case_end;
			case_ast_node(fv, FieldValue, elem);
				GB_ASSERT(fv->field->kind == AstNode_Ident);
				name = fv->field->Ident.token.string;
				value = fv->value;
			case_end;
			default:
				error(elem, "Invalid attribute element");
				continue;
			}

			ExactValue ev = {};
			if (value != nullptr) {
				Operand op = {};
				check_expr(c, &op, value);
				if (op.mode) {
					if (op.mode != Addressing_Constant) {
						error(value, "An attribute element must be constant");
					} else {
						ev = op.value;
					}
				}
			}

			if (string_set_exists(&set, name)) {
				error(elem, "Previous declaration of '%.*s'", LIT(name));
				continue;
			} else {
				string_set_add(&set, name);
			}

			if (!proc(c, elem, name, ev, ac)) {
				error(elem, "Unknown attribute element name '%.*s'", LIT(name));
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


bool check_arity_match(CheckerContext *c, AstNodeValueDecl *vd, bool is_global) {
	isize lhs = vd->names.count;
	isize rhs = vd->values.count;

	if (rhs == 0) {
		if (vd->type == nullptr) {
			error(vd->names[0], "Missing type or initial expression");
			return false;
		}
	} else if (lhs < rhs) {
		if (lhs < vd->values.count) {
			AstNode *n = vd->values[lhs];
			gbString str = expr_to_string(n);
			error(n, "Extra initial expression '%s'", str);
			gb_string_free(str);
		} else {
			error(vd->names[0], "Extra initial expression");
		}
		return false;
	} else if (lhs > rhs) {
		if (!is_global && rhs != 1) {
			AstNode *n = vd->names[rhs];
			gbString str = expr_to_string(n);
			error(n, "Missing expression for '%s'", str);
			gb_string_free(str);
			return false;
		} else if (is_global) {
			AstNode *n = vd->values[rhs-1];
			error(n, "Expected %td expressions on the right hand side, got %td", lhs, rhs);
			return false;
		}
	}

	return true;
}

void check_collect_entities_from_when_stmt(CheckerContext *c, AstNodeWhenStmt *ws) {
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

	if (ws->body == nullptr || ws->body->kind != AstNode_BlockStmt) {
		error(ws->cond, "Invalid body for 'when' statement");
	} else {
		if (ws->determined_cond) {
			check_collect_entities(c, ws->body->BlockStmt.stmts);
		} else if (ws->else_stmt) {
			switch (ws->else_stmt->kind) {
			case AstNode_BlockStmt:
				check_collect_entities(c, ws->else_stmt->BlockStmt.stmts);
				break;
			case AstNode_WhenStmt:
				check_collect_entities_from_when_stmt(c, &ws->else_stmt->WhenStmt);
				break;
			default:
				error(ws->else_stmt, "Invalid 'else' statement in 'when' statement");
				break;
			}
		}
	}
}

void check_builtin_attributes(CheckerContext *ctx, Entity *e, Array<AstNode *> *attributes) {
	switch (e->kind) {
	case Entity_ProcGroup:
	case Entity_Procedure:
	case Entity_TypeName:
		// Okay
		break;
	default:
		return;
	}
	if (!(ctx->scope->is_file && ctx->scope->file->pkg->kind == Package_Runtime)) {
		return;
	}

	for_array(j, *attributes) {
		AstNode *attr = (*attributes)[j];
		if (attr->kind != AstNode_Attribute) continue;
		for (isize k = 0; k < attr->Attribute.elems.count; k++) {
			AstNode *elem = attr->Attribute.elems[k];
			String name = {};
			AstNode *value = nullptr;

			switch (elem->kind) {
			case_ast_node(i, Ident, elem);
				name = i->token.string;
			case_end;
			case_ast_node(fv, FieldValue, elem);
				GB_ASSERT(fv->field->kind == AstNode_Ident);
				name = fv->field->Ident.token.string;
				value = fv->value;
			case_end;
			default:
				continue;
			}

			if (name == "builtin") {
				add_entity(ctx->checker, universal_scope, nullptr, e);
				GB_ASSERT(scope_lookup(universal_scope, e->token.string) != nullptr);
				if (value != nullptr) {
					error(value, "'builtin' cannot have a field value");
				}
				// Remove the builtin tag
				attr->Attribute.elems[k] = attr->Attribute.elems[attr->Attribute.elems.count-1];
				attr->Attribute.elems.count -= 1;
				k--;
			}
		}
	}

	for (isize i = 0; i < attributes->count; i++) {
		AstNode *attr = (*attributes)[i];
		if (attr->kind != AstNode_Attribute) continue;
		if (attr->Attribute.elems.count == 0) {
			(*attributes)[i] = (*attributes)[attributes->count-1];
			attributes->count--;
			i--;
		}
	}
}

void check_collect_value_decl(CheckerContext *c, AstNode *decl) {
	ast_node(vd, ValueDecl, decl);

	if (vd->been_handled) return;
	vd->been_handled = true;

	if (vd->is_mutable) {
		if (!c->scope->is_file) {
			// NOTE(bill): local scope -> handle later and in order
			return;
		}

		// NOTE(bill): You need to store the entity information here unline a constant declaration
		isize entity_cap = vd->names.count;
		isize entity_count = 0;
		Entity **entities = gb_alloc_array(c->allocator, Entity *, entity_cap);
		DeclInfo *di = nullptr;
		if (vd->values.count > 0) {
			di = make_decl_info(heap_allocator(), c->scope, c->decl);
			di->entities = entities;
			di->type_expr = vd->type;
			di->init_expr = vd->values[0];
			di->init_expr_list = vd->values;
		}

		for_array(i, vd->names) {
			AstNode *name = vd->names[i];
			AstNode *value = nullptr;
			if (i < vd->values.count) {
				value = vd->values[i];
			}
			if (name->kind != AstNode_Ident) {
				error(name, "A declaration's name must be an identifier, got %.*s", LIT(ast_node_strings[name->kind]));
				continue;
			}
			Entity *e = alloc_entity_variable(c->scope, name->Ident.token, nullptr, false);
			e->identifier = name;

			if (vd->is_using) {
				vd->is_using = false; // NOTE(bill): This error will be only caught once
				error(name, "'using' is not allowed at the file scope");
			}

			AstNode *fl = c->foreign_context.curr_library;
			if (fl != nullptr) {
				GB_ASSERT(fl->kind == AstNode_Ident);
				e->Variable.is_foreign = true;
				e->Variable.foreign_library_ident = fl;

				e->Variable.link_prefix = c->foreign_context.link_prefix;

			} else if (c->foreign_context.in_export) {
				e->Variable.is_export = true;
			}

			entities[entity_count++] = e;

			DeclInfo *d = di;
			if (d == nullptr || i > 0) {
				AstNode *init_expr = value;
				d = make_decl_info(heap_allocator(), e->scope, c->decl);
				d->type_expr = vd->type;
				d->init_expr = init_expr;
			}
			d->attributes = vd->attributes;

			add_entity_and_decl_info(c, name, e, d);
		}

		if (di != nullptr) {
			di->entity_count = entity_count;
		}

		check_arity_match(c, vd, true);
	} else {
		for_array(i, vd->names) {
			AstNode *name = vd->names[i];
			if (name->kind != AstNode_Ident) {
				error(name, "A declaration's name must be an identifier, got %.*s", LIT(ast_node_strings[name->kind]));
				continue;
			}

			AstNode *init = unparen_expr(vd->values[i]);
			if (init == nullptr) {
				error(name, "Expected a value for this constant value declaration");
				continue;
			}

			Token token = name->Ident.token;

			AstNode *fl = c->foreign_context.curr_library;
			DeclInfo *d = make_decl_info(c->allocator, c->scope, c->decl);
			Entity *e = nullptr;

			d->attributes = vd->attributes;

			if (is_ast_node_type(init) ||
				(vd->type != nullptr && vd->type->kind == AstNode_TypeType)) {
				e = alloc_entity_type_name(d->scope, token, nullptr);
				if (vd->type != nullptr) {
					error(name, "A type declaration cannot have an type parameter");
				}
				d->type_expr = init;
				d->init_expr = init;
			} else if (init->kind == AstNode_ProcLit) {
				if (c->scope->is_struct) {
					error(name, "Procedure declarations are not allowed within a struct");
					continue;
				}
				ast_node(pl, ProcLit, init);
				e = alloc_entity_procedure(d->scope, token, nullptr, pl->tags);
				if (fl != nullptr) {
					GB_ASSERT(fl->kind == AstNode_Ident);
					e->Procedure.foreign_library_ident = fl;
					e->Procedure.is_foreign = true;

					GB_ASSERT(pl->type->kind == AstNode_ProcType);
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

				} else if (c->foreign_context.in_export) {
					e->Procedure.is_export = true;
				}
				d->proc_lit = init;
				d->type_expr = pl->type;
			} else if (init->kind == AstNode_ProcGroup) {
				ast_node(pg, ProcGroup, init);
				e = alloc_entity_proc_group(d->scope, token, nullptr);
				if (fl != nullptr) {
					error(name, "Procedure groups are not allowed within a foreign block");
				}
				d->init_expr = init;
			} else {
				e = alloc_entity_constant(d->scope, token, nullptr, empty_exact_value);
				d->type_expr = vd->type;
				d->init_expr = init;
			}
			e->identifier = name;

			if (e->kind != Entity_Procedure) {
				if (fl != nullptr || c->foreign_context.in_export) {
					AstNodeKind kind = init->kind;
					error(name, "Only procedures and variables are allowed to be in a foreign block, got %.*s", LIT(ast_node_strings[kind]));
					if (kind == AstNode_ProcType) {
						gb_printf_err("\tDid you forget to append '---' to the procedure?\n");
					}
				}
			}

			check_builtin_attributes(c, e, &d->attributes);

			add_entity_and_decl_info(c, name, e, d);
		}

		check_arity_match(c, vd, true);
	}
}

void check_add_foreign_block_decl(CheckerContext *ctx, AstNode *decl) {
	ast_node(fb, ForeignBlockDecl, decl);

	if (fb->been_handled) return;
	fb->been_handled = true;

	AstNode *foreign_library = fb->foreign_library;

	CheckerContext c = *ctx;
	if (foreign_library->kind == AstNode_Ident) {
		c.foreign_context.curr_library = foreign_library;
	} else if (foreign_library->kind == AstNode_Implicit && foreign_library->Implicit.kind == Token_export) {
		c.foreign_context.in_export = true;
	} else {
		error(foreign_library, "Foreign block name must be an identifier or 'export'");
		c.foreign_context.curr_library = nullptr;
	}

	check_decl_attributes(&c, fb->attributes, foreign_block_decl_attribute, nullptr);

	c.collect_delayed_decls = true;
	check_collect_entities(&c, fb->decls);
}

// NOTE(bill): If file_scopes == nullptr, this will act like a local scope
void check_collect_entities(CheckerContext *c, Array<AstNode *> const &nodes) {
	for_array(decl_index, nodes) {
		AstNode *decl = nodes[decl_index];
		if (!is_ast_node_decl(decl) && !is_ast_node_when_stmt(decl)) {
			if (c->scope->is_file && decl->kind == AstNode_ExprStmt) {
				AstNode *expr = decl->ExprStmt.expr;
				if (expr->kind == AstNode_CallExpr && expr->CallExpr.proc->kind == AstNode_BasicDirective) {
					if (c->collect_delayed_decls) {
						array_add(&c->scope->delayed_directives, expr);
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
			if (!c->scope->is_file) {
				error(decl, "import declarations are only allowed in the file scope");
				// NOTE(bill): _Should_ be caught by the parser
				// TODO(bill): Better error handling if it isn't
				continue;
			}
			if (c->collect_delayed_decls) {
				array_add(&c->scope->delayed_imports, decl);
			}
		case_end;

		case_ast_node(fl, ForeignImportDecl, decl);
			if (!c->scope->is_file) {
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
			if (c->scope->is_file) {
				error(decl, "Only declarations are allowed at file scope");
			}
			break;
		}
	}

	// NOTE(bill): 'when' stmts need to be handled after the other as the condition may refer to something
	// declared after this stmt in source
	if (!c->scope->is_file || c->collect_delayed_decls) {
		for_array(i, nodes) {
			AstNode *node = nodes[i];
			switch (node->kind) {
			case_ast_node(ws, WhenStmt, node);
				check_collect_entities_from_when_stmt(c, ws);
			case_end;
			}
		}
	}
}


void check_all_global_entities(Checker *c) {
	Scope *prev_file = nullptr;

	for_array(i, c->info.entities) {
		Entity *e = c->info.entities[i];
		DeclInfo *d = e->decl_info;

		if (d->scope != e->scope) {
			continue;
		}

		CheckerContext ctx = c->init_ctx;

		GB_ASSERT(d->scope->is_file);
		AstFile *file = d->scope->file;
		add_curr_ast_file(&ctx, file);
		AstPackage *pkg = file->pkg;

		GB_ASSERT(ctx.pkg != nullptr);
		GB_ASSERT(e->pkg != nullptr);

		if (pkg->kind == Package_Init) {
			if (e->kind != Entity_Procedure && e->token.string == "main") {
				error(e->token, "'main' is reserved as the entry point procedure in the initial scope");
				continue;
			}
		} else if (pkg->kind == Package_Runtime) {
			if (e->token.string == "main") {
				error(e->token, "'main' is reserved as the entry point procedure in the initial scope");
				continue;
			}
		}

		ctx.decl = d;
		ctx.scope = d->scope;
		check_entity_decl(&ctx, e, d, nullptr);
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
		isize size = gb_utf8_decode(s.text+offset, s.len-offset, &r);
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

String path_to_entity_name(String name, String fullpath) {
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

	if (is_string_an_identifier(filename)) {
		return filename;
	} else {
		return str_lit("_");
	}
}





#if 1

void add_import_dependency_node(Checker *c, AstNode *decl, Map<ImportGraphNode *> *M) {
	AstPackage *parent_pkg = decl->file->pkg;

	switch (decl->kind) {
	case_ast_node(id, ImportDecl, decl);
		String path = id->fullpath;
		HashKey key = hash_string(path);
		AstPackage **found = map_get(&c->info.packages, key);
		if (found == nullptr) {
			for_array(pkg_index, c->info.packages.entries) {
				AstPackage *pkg = c->info.packages.entries[pkg_index].value;
				gb_printf_err("%.*s\n", LIT(pkg->fullpath));
			}
			Token token = ast_node_token(decl);
			gb_printf_err("%.*s(%td:%td)\n", LIT(token.pos.file), token.pos.line, token.pos.column);
			GB_PANIC("Unable to find package: %.*s", LIT(path));
		}
		AstPackage *pkg = *found;
		GB_ASSERT(pkg->scope != nullptr);

		id->package = pkg;

		ImportGraphNode **found_node = nullptr;
		ImportGraphNode *m = nullptr;
		ImportGraphNode *n = nullptr;

		found_node = map_get(M, hash_pointer(pkg));
		GB_ASSERT(found_node != nullptr);
		m = *found_node;

		found_node = map_get(M, hash_pointer(parent_pkg));
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
			case AstNode_BlockStmt: {
				auto stmts = ws->else_stmt->BlockStmt.stmts;
				for_array(i, stmts) {
					add_import_dependency_node(c, stmts[i], M);
				}

				break;
			}
			case AstNode_WhenStmt:
				add_import_dependency_node(c, ws->else_stmt, M);
				break;
			}
		}
	case_end;
	}
}

Array<ImportGraphNode *> generate_import_dependency_graph(Checker *c) {
	Map<ImportGraphNode *> M = {}; // Key: AstPackage *
	map_init(&M, heap_allocator(), 2*c->parser->packages.count);
	defer (map_destroy(&M));

	for_array(i, c->parser->packages) {
		AstPackage *pkg = c->parser->packages[i];
		ImportGraphNode *n = import_graph_node_create(heap_allocator(), pkg);
		map_set(&M, hash_pointer(pkg), n);
	}

	// Calculate edges for graph M
	for_array(i, c->parser->packages) {
		AstPackage *p = c->parser->packages[i];
		for_array(j, p->files) {
			AstFile *f = p->files[j];
			for_array(k, f->decls) {
				AstNode *decl = f->decls[k];
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
	AstNode *   decl;
};

Array<ImportPathItem> find_import_path(Checker *c, AstPackage *start, AstPackage *end, PtrSet<AstPackage *> *visited) {
	Array<ImportPathItem> empty_path = {};

	if (ptr_set_exists(visited, start)) {
		return empty_path;
	}
	ptr_set_add(visited, start);


	String path = start->fullpath;
	HashKey key = hash_string(path);
	AstPackage **found = map_get(&c->info.packages, key);
	if (found) {
		AstPackage *pkg = *found;
		GB_ASSERT(pkg != nullptr);

		for_array(i, pkg->files) {
			AstFile *f = pkg->files[i];
			for_array(j, f->imports) {
				AstPackage *pkg = nullptr;
				AstNode *decl = f->imports[j];
				if (decl->kind == AstNode_ImportDecl) {
					pkg = decl->ImportDecl.package;
				} else {
					continue;
				}
				GB_ASSERT(pkg != nullptr && pkg->scope != nullptr);

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
void check_add_import_decl(CheckerContext *ctx, AstNodeImportDecl *id) {
	if (id->been_handled) return;
	id->been_handled = true;

	Scope *parent_scope = ctx->scope;
	GB_ASSERT(parent_scope->is_file);

	auto *pkgs = &ctx->checker->info.packages;

	Token token = id->relpath;
	HashKey key = hash_string(id->fullpath);
	AstPackage **found = map_get(pkgs, key);
	if (found == nullptr) {
		for_array(pkg_index, pkgs->entries) {
			AstPackage *pkg = pkgs->entries[pkg_index].value;
			gb_printf_err("%.*s\n", LIT(pkg->fullpath));
		}
		gb_printf_err("%.*s(%td:%td)\n", LIT(token.pos.file), token.pos.line, token.pos.column);
		GB_PANIC("Unable to find scope for package: %.*s", LIT(id->fullpath));
	}
	AstPackage *pkg = *found;
	Scope *scope = pkg->scope;
	GB_ASSERT(scope->is_package);

	// TODO(bill): Should this be allowed or not?
	// if (scope->is_global) {
	// 	error(token, "Importing a runtime package is disallowed and unnecessary");
	// 	return;
	// }

	if (ptr_set_exists(&parent_scope->imported, scope)) {
		// error(token, "Multiple import of the same file within this scope");
	} else {
		ptr_set_add(&parent_scope->imported, scope);
	}


	if (id->using_in_list.count == 0) {
		String import_name = id->import_name.string;
		if (import_name.len == 0) {
			import_name = scope->package->name;
		}
		if (is_blank_ident(import_name)) {
			if (id->is_using) {
				// TODO(bill): Should this be a warning?
			} else {
				error(token, "Import name, %.*s, cannot be use as an import name as it is not a valid identifier", LIT(id->import_name.string));
			}
		} else {
			GB_ASSERT(id->import_name.pos.line != 0);
			id->import_name.string = import_name;
			Entity *e = alloc_entity_import_name(parent_scope, id->import_name, t_invalid,
			                                     id->fullpath, id->import_name.string,
			                                     scope);

			add_entity(ctx->checker, parent_scope, nullptr, e);
			if (id->is_using) {
				add_entity_use(ctx, nullptr, e);
			}
		}
	}

	if (id->is_using) {
		if (parent_scope->is_global) {
			error(id->import_name, "'builtin' package imports cannot use using");
			return;
		}

		// NOTE(bill): Add imported entities to this file's scope
		if (id->using_in_list.count > 0) {

			for_array(list_index, id->using_in_list) {
				AstNode *node = id->using_in_list[list_index];
				ast_node(ident, Ident, node);
				String name = ident->token.string;

				Entity *e = scope_lookup(scope, name);
				if (e == nullptr) {
					if (is_blank_ident(name)) {
						error(node, "'_' cannot be used as a value");
					} else {
						error(node, "Undeclared name in this importation: '%.*s'", LIT(name));
					}
					continue;
				}
				if (e->scope == parent_scope) {
					continue;
				}

				bool implicit_is_found = ptr_set_exists(&scope->implicit, e);
				if (is_entity_exported(e) && !implicit_is_found) {
					add_entity_use(ctx, node, e);
					bool ok = add_entity(ctx->checker, parent_scope, e->identifier, e);
					if (ok) ptr_set_add(&parent_scope->implicit, e);
				} else {
					error(node, "'%.*s' is exported from this scope", LIT(name));
					continue;
				}
			}
		} else {
			for_array(elem_index, scope->elements.entries) {
				Entity *e = scope->elements.entries[elem_index].value;
				if (e->scope == parent_scope) continue;

				bool implicit_is_found = ptr_set_exists(&scope->implicit, e);
				if (is_entity_exported(e) && !implicit_is_found) {
					Entity *prev = scope_lookup(parent_scope, e->token.string);
					bool ok = add_entity(ctx->checker, parent_scope, e->identifier, e);
					if (ok) ptr_set_add(&parent_scope->implicit, e);
				}
			}
		}
	}

	ptr_set_add(&ctx->checker->checked_packages, pkg);
	scope->has_been_imported = true;
}


void check_add_foreign_import_decl(CheckerContext *ctx, AstNode *decl) {
	ast_node(fl, ForeignImportDecl, decl);

	if (fl->been_handled) return;
	fl->been_handled = true;

	Scope *parent_scope = ctx->scope;
	GB_ASSERT(parent_scope->is_file);

	String fullpath = fl->fullpath;
	String library_name = path_to_entity_name(fl->library_name.string, fullpath);
	if (is_blank_ident(library_name)) {
		error(fl->token, "File name, %.*s, cannot be as a library name as it is not a valid identifier", LIT(fl->library_name.string));
		return;
	}

	if (fl->collection_name != "system") {
		char *c_str = gb_alloc_array(heap_allocator(), char, fullpath.len+1);
		defer (gb_free(heap_allocator(), c_str));
		gb_memmove(c_str, fullpath.text, fullpath.len);
		c_str[fullpath.len] = '\0';

		gbFile f = {};
		gbFileError file_err = gb_file_open(&f, c_str);
		defer (gb_file_close(&f));

		switch (file_err) {
		case gbFileError_Invalid:
			error(decl, "Invalid file or cannot be found ('%.*s')", LIT(fullpath));
			return;
		case gbFileError_NotExists:
			error(decl, "File cannot be found ('%.*s')", LIT(fullpath));
			return;
		}
	}

	GB_ASSERT(fl->library_name.pos.line != 0);
	fl->library_name.string = library_name;
	Entity *e = alloc_entity_library_name(parent_scope, fl->library_name, t_invalid,
	                                      fl->fullpath, library_name);
	add_entity(ctx->checker, parent_scope, nullptr, e);
}

bool collect_checked_packages_from_decl_list(Checker *c, Array<AstNode *> const &decls) {
	bool new_files = false;
	for_array(i, decls) {
		AstNode *decl = decls[i];
		switch (decl->kind) {
		case_ast_node(id, ImportDecl, decl);
			HashKey key = hash_string(id->fullpath);
			AstPackage **found = map_get(&c->info.packages, key);
			if (found == nullptr) {
				continue;
			}
			AstPackage *pkg = *found;
			if (!ptr_set_exists(&c->checked_packages, pkg)) {
				new_files = true;
				ptr_set_add(&c->checked_packages, pkg);
			}
		case_end;
		}
	}
	return new_files;
}

// Returns true if a new package is present
bool collect_file_decls(CheckerContext *ctx, Array<AstNode *> const &decls);
bool collect_file_decls_from_when_stmt(CheckerContext *ctx, AstNodeWhenStmt *ws);

bool collect_when_stmt_from_file(CheckerContext *ctx, AstNodeWhenStmt *ws) {
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

	if (ws->body == nullptr || ws->body->kind != AstNode_BlockStmt) {
		error(ws->cond, "Invalid body for 'when' statement");
	} else {
		if (ws->determined_cond) {
			return collect_checked_packages_from_decl_list(ctx->checker, ws->body->BlockStmt.stmts);
		} else if (ws->else_stmt) {
			switch (ws->else_stmt->kind) {
			case AstNode_BlockStmt:
				return collect_checked_packages_from_decl_list(ctx->checker, ws->else_stmt->BlockStmt.stmts);
			case AstNode_WhenStmt:
				return collect_when_stmt_from_file(ctx, &ws->else_stmt->WhenStmt);
			default:
				error(ws->else_stmt, "Invalid 'else' statement in 'when' statement");
				break;
			}
		}
	}

	return false;
}

bool collect_file_decls_from_when_stmt(CheckerContext *ctx, AstNodeWhenStmt *ws) {
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

	if (ws->body == nullptr || ws->body->kind != AstNode_BlockStmt) {
		error(ws->cond, "Invalid body for 'when' statement");
	} else {
		if (ws->determined_cond) {
			return collect_file_decls(ctx, ws->body->BlockStmt.stmts);
		} else if (ws->else_stmt) {
			switch (ws->else_stmt->kind) {
			case AstNode_BlockStmt:
				return collect_file_decls(ctx, ws->else_stmt->BlockStmt.stmts);
			case AstNode_WhenStmt:
				return collect_file_decls_from_when_stmt(ctx, &ws->else_stmt->WhenStmt);
			default:
				error(ws->else_stmt, "Invalid 'else' statement in 'when' statement");
				break;
			}
		}
	}

	return false;
}

bool collect_file_decls(CheckerContext *ctx, Array<AstNode *> const &decls) {
	GB_ASSERT(ctx->scope->is_file);

	if (collect_checked_packages_from_decl_list(ctx->checker, decls)) {
		return true;
	}

	for_array(i, decls) {
		AstNode *decl = decls[i];
		switch (decl->kind) {
		case_ast_node(vd, ValueDecl, decl);
			check_collect_value_decl(ctx, decl);
		case_end;

		case_ast_node(id, ImportDecl, decl);
			check_add_import_decl(ctx, id);
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

		case_ast_node(ce, CallExpr, decl);
			if (ce->proc->kind == AstNode_BasicDirective) {
				Operand o = {};
				check_expr(ctx, &o, decl);
			}
		case_end;
		}
	}

	return false;
}

void check_import_entities(Checker *c) {
	Array<ImportGraphNode *> dep_graph = generate_import_dependency_graph(c);
	defer ({
		for_array(i, dep_graph) {
			import_graph_node_destroy(dep_graph[i], heap_allocator());
		}
		array_free(&dep_graph);
	});

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

			// TODO(bill): This needs better TokenPos finding
			auto const fn = [](ImportPathItem item) -> String {
				return item.pkg->name;
			};

		#if 1
			if (path.count == 1) {
				// TODO(bill): Should this be allowed or disabled?
			#if 0
				ImportPathItem item = path[0];
				String filename = fn(item);
				error(item.decl, "Self importation of '%.*s'", LIT(filename));
			#endif
			} else if (path.count > 0) {
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
		#endif
		}

		for_array(i, n->pred.entries) {
			ImportGraphNode *p = n->pred.entries[i].ptr;
			p->dep_count = gb_max(p->dep_count-1, 0);
			priority_queue_fix(&pq, p->index);
		}

		if (pkg == nullptr) {
			continue;
		}
		if (ptr_set_exists(&emitted, pkg)) {
			continue;
		}
		ptr_set_add(&emitted, pkg);

		array_add(&package_order, n);
	}

	for_array(i, c->parser->packages) {
		AstPackage *pkg = c->parser->packages[i];
		switch (pkg->kind) {
		case Package_Init:
		case Package_Runtime:
			ptr_set_add(&c->checked_packages, pkg);
			break;
		}
	}

	for (isize loop_count = 0; ; loop_count++) {
		bool new_files = false;
		for_array(i, package_order) {
			ImportGraphNode *node = package_order[i];
			GB_ASSERT(node->scope->is_package);
			AstPackage *pkg = node->scope->package;
			if (!ptr_set_exists(&c->checked_packages, pkg)) {
				continue;
			}

			for_array(i, pkg->files) {
				AstFile *f = pkg->files[i];
				CheckerContext ctx = c->init_ctx;
				add_curr_ast_file(&ctx, f);
				new_files |= collect_checked_packages_from_decl_list(c, f->decls);
			}
		}

		if (!new_files) {
			break;
		}
	}

	for (isize pkg_index = 0; pkg_index < package_order.count; pkg_index++) {
		ImportGraphNode *node = package_order[pkg_index];
		AstPackage *pkg = node->pkg;

		if (!ptr_set_exists(&c->checked_packages, pkg)) {
			continue;
		}

		bool new_packages = false;

		for_array(i, pkg->files) {
			AstFile *f = pkg->files[i];

			CheckerContext ctx = c->init_ctx;
			ctx.collect_delayed_decls = true;
			add_curr_ast_file(&ctx, f);

			if (collect_file_decls(&ctx, f->decls)) {
				new_packages = true;
				break;
			}
		}

		if (new_packages) {
			pkg_index = -1;
			continue;
		}
	}

	for_array(i, package_order) {
		ImportGraphNode *node = package_order[i];
		GB_ASSERT(node->scope->is_package);
		AstPackage *pkg = node->scope->package;

		for_array(i, pkg->files) {
			AstFile *f = pkg->files[i];
			CheckerContext ctx = c->init_ctx;

			add_curr_ast_file(&ctx, f);
			for_array(j, f->scope->delayed_imports) {
				AstNode *decl = f->scope->delayed_imports[j];
				ast_node(id, ImportDecl, decl);
				check_add_import_decl(&ctx, id);
			}
			for_array(j, f->scope->delayed_directives) {
				AstNode *expr = f->scope->delayed_directives[j];
				Operand o = {};
				check_expr(&ctx, &o, expr);
			}
		}
	}
}

Array<Entity *> find_entity_path(Entity *start, Entity *end, Map<Entity *> *visited = nullptr) {
	Map<Entity *> visited_ = {};
	bool made_visited = false;
	if (visited == nullptr) {
		made_visited = true;
		map_init(&visited_, heap_allocator());
		visited = &visited_;
	}
	defer (if (made_visited) {
		map_destroy(&visited_);
	});

	Array<Entity *> empty_path = {};

	HashKey key = hash_pointer(start);

	if (map_get(visited, key) != nullptr) {
		return empty_path;
	}
	map_set(visited, key, start);

	DeclInfo *decl = start->decl_info;
	if (decl) {
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
	return empty_path;
}


void calculate_global_init_order(Checker *c) {
#if 0
	Timings timings = {};
	timings_init(&timings, str_lit("calculate_global_init_order"), 16);
	defer ({
		timings_print_all(&timings);
		timings_destroy(&timings);
	});
#define TIME_SECTION(str) timings_start_section(&timings, str_lit(str))
#else
#define TIME_SECTION(str)
#endif


	CheckerInfo *info = &c->info;

	TIME_SECTION("generate entity dependency graph");
	Array<EntityGraphNode *> dep_graph = generate_entity_dependency_graph(info);
	defer ({
		for_array(i, dep_graph) {
			entity_graph_node_destroy(dep_graph[i], heap_allocator());
		}
		array_free(&dep_graph);
	});

	TIME_SECTION("priority queue create");
	// NOTE(bill): Priority queue
	auto pq = priority_queue_create(dep_graph, entity_graph_node_cmp, entity_graph_node_swap);

	PtrSet<DeclInfo *> emitted = {};
	ptr_set_init(&emitted, heap_allocator());
	defer (ptr_set_destroy(&emitted));

	TIME_SECTION("queue sort");
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
			p->dep_count -= gb_max(p->dep_count-1, 0);
			priority_queue_fix(&pq, p->index);
		}

		if (e == nullptr || e->kind != Entity_Variable) {
			continue;
		}
		DeclInfo *d = decl_info_of_entity(e);

		if (ptr_set_exists(&emitted, d)) {
			continue;
		}
		ptr_set_add(&emitted, d);

		if (d->entities == nullptr) {
			d->entities = gb_alloc_array(c->allocator, Entity *, 1);
			d->entities[0] = e;
			d->entity_count = 1;
		}
		array_add(&info->variable_init_order, d);
	}

	if (false) {
		gb_printf("Variable Initialization Order:\n");
		for_array(i, info->variable_init_order) {
			DeclInfo *d = info->variable_init_order[i];
			for (isize j = 0; j < d->entity_count; j++) {
				Entity *e = d->entities[j];
				if (j == 0) gb_printf("\t");
				if (j > 0) gb_printf(", ");
				gb_printf("'%.*s' %td", LIT(e->token.string), e->order_in_src);
			}
			gb_printf("\n");
		}
		gb_printf("\n");
	}

#undef TIME_SECTION
}


void check_proc_info(Checker *c, ProcedureInfo pi) {
	if (pi.type == nullptr) {
		return;
	}

	CheckerContext ctx = make_checker_context(c);
	defer (destroy_checker_context(&ctx));
	add_curr_ast_file(&ctx, pi.file);
	ctx.decl = pi.decl;

	TypeProc *pt = &pi.type->Proc;
	String name = pi.token.string;
	if (pt->is_polymorphic) {
		GB_ASSERT_MSG(pt->is_poly_specialized, "%.*s", LIT(name));
	}

	bool bounds_check    = (pi.tags & ProcTag_bounds_check)    != 0;
	bool no_bounds_check = (pi.tags & ProcTag_no_bounds_check) != 0;

	if (bounds_check) {
		ctx.stmt_state_flags |= StmtStateFlag_bounds_check;
		ctx.stmt_state_flags &= ~StmtStateFlag_no_bounds_check;
	} else if (no_bounds_check) {
		ctx.stmt_state_flags |= StmtStateFlag_no_bounds_check;
		ctx.stmt_state_flags &= ~StmtStateFlag_bounds_check;
	}

	check_proc_body(&ctx, pi.token, pi.decl, pi.type, pi.body);
}

GB_THREAD_PROC(check_proc_info_worker_proc) {
	if (thread == nullptr) return 0;
	auto *c = cast(Checker *)thread->user_data;
	isize index = thread->user_index;
	check_proc_info(c, c->procs_to_check[index]);
	return 0;
}


void check_parsed_files(Checker *c) {
#if 0
	Timings timings = {};
	timings_init(&timings, str_lit("check_parsed_files"), 16);
	defer ({
		timings_print_all(&timings);
		timings_destroy(&timings);
	});
#define TIME_SECTION(str) timings_start_section(&timings, str_lit(str))
#else
#define TIME_SECTION(str)
#endif

	TIME_SECTION("map full filepaths to scope");
	add_type_info_type(&c->init_ctx, t_invalid);

	// Map full filepaths to Scopes
	for_array(i, c->parser->packages) {
		AstPackage *p = c->parser->packages[i];
		Scope *scope = create_scope_from_package(&c->init_ctx, p);
		p->decl_info = make_decl_info(c->allocator, scope, c->init_ctx.decl);
		HashKey key = hash_string(p->fullpath);
		map_set(&c->info.packages, key, p);

		if (scope->is_init) {
			c->info.init_scope = scope;
		}
		if (p->kind == Package_Runtime) {
			GB_ASSERT(c->info.runtime_package == nullptr);
			c->info.runtime_package = p;
		}
	}

	TIME_SECTION("collect entities");
	// Collect Entities
	for_array(i, c->parser->packages) {
		AstPackage *p = c->parser->packages[i];

		CheckerContext ctx = make_checker_context(c);
		defer (destroy_checker_context(&ctx));
		ctx.pkg = p;
		ctx.collect_delayed_decls = false;

		for_array(j, p->files) {
			AstFile *f = p->files[j];
			create_scope_from_file(&ctx, f);
			HashKey key = hash_string(f->fullpath);
			map_set(&c->info.files, key, f);

			add_curr_ast_file(&ctx, f);
			check_collect_entities(&ctx, f->decls);
		}
	}

	TIME_SECTION("import entities");
	check_import_entities(c);

	TIME_SECTION("check all global entities");
	check_all_global_entities(c);

	TIME_SECTION("init preload");
	init_preload(c);

	CheckerContext prev_context = c->init_ctx;
	defer (c->init_ctx = prev_context);

	TIME_SECTION("check procedure bodies");
	// NOTE(bill): Nested procedures bodies will be added to this "queue"
	for_array(i, c->procs_to_check) {
		ProcedureInfo pi = c->procs_to_check[i];
		check_proc_info(c, pi);
	}

	for_array(i, c->info.files.entries) {
		AstFile *f = c->info.files.entries[i].value;
		check_scope_usage(c, f->scope);
	}

	TIME_SECTION("generate minimum dependency set");
	generate_minimum_dependency_set(c, c->info.entry_point);


	TIME_SECTION("calculate global init order");
	// Calculate initialization order of global variables
	calculate_global_init_order(c);


	TIME_SECTION("add untyped expression values");
	// Add untyped expression values
	for_array(i, c->info.untyped.entries) {
		auto *entry = &c->info.untyped.entries[i];
		HashKey key = entry->key;
		AstNode *expr = cast(AstNode *)key.ptr;
		ExprInfo *info = &entry->value;
		if (info != nullptr && expr != nullptr) {
			if (is_type_typed(info->type)) {
				compiler_error("%s (type %s) is typed!", expr_to_string(expr), type_to_string(info->type));
			}
			add_type_and_value(&c->info, expr, info->mode, info->type, info->value);
		}
	}

	// TODO(bill): Check for unused imports (and remove) or even warn/err
	// TODO(bill): Any other checks?


	TIME_SECTION("add type information");
	// Add "Basic" type information
	for (isize i = 0; i < Basic_COUNT; i++) {
		Type *t = &basic_types[i];
		if (t->Basic.size > 0 &&
		    (t->Basic.flags & BasicFlag_LLVM) == 0) {
			add_type_info_type(&c->init_ctx, t);
		}
	}

	TIME_SECTION("check for type cycles");
	// NOTE(bill): Check for illegal cyclic type declarations
	for_array(i, c->info.definitions) {
		Entity *e = c->info.definitions[i];
		if (e->kind == Entity_TypeName && e->type != nullptr) {
			// i64 size  = type_size_of(c->allocator, e->type);
			i64 align = type_align_of(e->type);
			if (align > 0 && ptr_set_exists(&c->info.minimum_dependency_set, e)) {
				add_type_info_type(&c->init_ctx, e->type);
			}
		}
	}

	TIME_SECTION("check entry point");
	if (!build_context.is_dll) {
		Scope *s = c->info.init_scope;
		GB_ASSERT(s != nullptr);
		GB_ASSERT(s->is_init);
		Entity *e = scope_lookup_current(s, str_lit("main"));
		if (e == nullptr) {
			Token token = {};
			token.pos.file   = s->package->fullpath;
			token.pos.line   = 1;
			token.pos.column = 1;
			if (s->package->files.count > 0) {
				AstFile *f = s->package->files[0];
				if (f->tokens.count > 0) {
					token = f->tokens[0];
				}
			}

			error(token, "Undefined entry point procedure 'main'");
		}
	}

#undef TIME_SECTION
}
