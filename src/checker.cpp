#include "entity.cpp"
#include "types.cpp"


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
	array_clear  (&scope->shared);
	ptr_set_clear(&scope->implicit);
	ptr_set_clear(&scope->imported);
	ptr_set_clear(&scope->exported);
}

i32 is_scope_an_ancestor(Scope *parent, Scope *child) {
	isize i = 0;
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

ImportGraphNode *import_graph_node_create(gbAllocator a, Scope *scope) {
	ImportGraphNode *n = gb_alloc_item(a, ImportGraphNode);
	n->scope   = scope;
	n->path    = scope->file->tokenizer.fullpath;
	n->file_id = scope->file->id;
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
	if (xg && yg) return x->file_id < y->file_id ? +1 : -1;
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






void init_declaration_info(DeclInfo *d, Scope *scope, DeclInfo *parent) {
	d->parent = parent;
	d->scope  = scope;
	ptr_set_init(&d->deps,                heap_allocator());
	array_init  (&d->labels,              heap_allocator());
}

DeclInfo *make_declaration_info(gbAllocator a, Scope *scope, DeclInfo *parent) {
	DeclInfo *d = gb_alloc_item(a, DeclInfo);
	init_declaration_info(d, scope, parent);
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





Scope *create_scope(Scope *parent, gbAllocator allocator) {
	Scope *s = gb_alloc_item(allocator, Scope);
	s->parent = parent;
	map_init(&s->elements,     heap_allocator());
	array_init(&s->shared,     heap_allocator());
	ptr_set_init(&s->implicit, heap_allocator());
	ptr_set_init(&s->imported, heap_allocator());
	ptr_set_init(&s->exported, heap_allocator());

	if (parent != nullptr && parent != universal_scope) {
		DLIST_APPEND(parent->first_child, parent->last_child, s);
	}
	return s;
}

Scope *create_scope_from_file(Checker *c, AstFile *f) {
	GB_ASSERT(f != nullptr);

	Scope *s = create_scope(c->global_scope, c->allocator);

	array_init(&s->delayed_file_decls, heap_allocator());

	s->file = f;
	f->scope = s;
	s->is_file   = true;

	if (f->tokenizer.fullpath == c->parser->init_fullpath) {
		s->is_init = true;
	} else {
		s->is_init = f->file_kind == ImportedFile_Init;
	}

	s->is_global = f->is_global_scope;
	if (s->is_global) array_add(&c->global_scope->shared, s);


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
	array_free(&scope->shared);
	array_free(&scope->delayed_file_decls);
	ptr_set_destroy(&scope->implicit);
	ptr_set_destroy(&scope->imported);
	ptr_set_destroy(&scope->exported);

	// NOTE(bill): No need to free scope as it "should" be allocated in an arena (except for the global scope)
}


void add_scope(Checker *c, AstNode *node, Scope *scope) {
	GB_ASSERT(node != nullptr);
	GB_ASSERT(scope != nullptr);
	scope->node = node;
	node->scope = scope;
}


void check_open_scope(Checker *c, AstNode *node) {
	node = unparen_expr(node);
	GB_ASSERT(node->kind == AstNode_Invalid ||
	          is_ast_node_stmt(node) ||
	          is_ast_node_type(node));
	Scope *scope = create_scope(c->context.scope, c->allocator);
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
	c->context.scope = scope;
	c->context.stmt_state_flags |= StmtStateFlag_bounds_check;
}

void check_close_scope(Checker *c) {
	c->context.scope = c->context.scope->parent;
}


Entity *current_scope_lookup_entity(Scope *s, String name) {
	HashKey key = hash_string(name);
	Entity **found = map_get(&s->elements, key);
	if (found) {
		return *found;
	}
	for_array(i, s->shared) {
		Scope *shared = s->shared[i];
		Entity **found = map_get(&shared->elements, key);
		if (found) {
			Entity *e = *found;
			if (e->kind == Entity_Variable &&
			    !e->scope->is_file &&
			    !e->scope->is_global) {
				continue;
			}

			if (e->scope != shared) {
				// Do not return imported entities even #include ones
				continue;
			}

			return e;
		}
	}
	return nullptr;
}

void scope_lookup_parent_entity(Scope *scope, String name, Scope **scope_, Entity **entity_) {
	bool gone_thru_proc = false;
	bool gone_thru_file = false;
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
				    !e->scope->is_file &&
				    !e->scope->is_global) {
					continue;
				}
			}

			if (entity_) *entity_ = e;
			if (scope_) *scope_ = s;
			return;
		}

		if (s->is_proc) {
			gone_thru_proc = true;
		} else {
			// Check shared scopes - i.e. other files @ global scope
			for_array(i, s->shared) {
				Scope *shared = s->shared[i];
				Entity **found = map_get(&shared->elements, key);
				if (found) {
					Entity *e = *found;
					if (e->kind == Entity_Variable &&
					    !e->scope->is_file &&
					    !e->scope->is_global) {
						continue;
					}

					if (e->scope != shared) {
						// Do not return imported entities even #include ones
						continue;
					}

					if ((e->kind == Entity_ImportName ||
					     e->kind == Entity_LibraryName)
					     && gone_thru_file) {
						continue;
					}

					if (entity_) *entity_ = e;
					if (scope_) *scope_ = shared;
					return;
				}
			}
		}

		if (s->is_file) {
			gone_thru_file = true;
		}
	}


	if (entity_) *entity_ = nullptr;
	if (scope_) *scope_ = nullptr;
}

Entity *scope_lookup_entity(Scope *s, String name) {
	Entity *entity = nullptr;
	scope_lookup_parent_entity(s, name, nullptr, &entity);
	return entity;
}



Entity *scope_insert_entity(Scope *s, Entity *entity) {
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
		if (e != nullptr && e->kind == Entity_Variable && (e->flags&EntityFlag_Used) == 0) {
			array_add(&unused, e);
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

void add_declaration_dependency(Checker *c, Entity *e) {
	if (e == nullptr) {
		return;
	}
	if (c->context.decl != nullptr) {
		// DeclInfo *decl = decl_info_of_entity(&c->info, e);
		add_dependency(c->context.decl, e);
	}
}


Entity *add_global_entity(Entity *entity) {
	String name = entity->token.string;
	if (gb_memchr(name.text, ' ', name.len)) {
		return entity; // NOTE(bill): 'untyped thing'
	}
	if (scope_insert_entity(universal_scope, entity)) {
		compiler_error("double declaration");
	}
	return entity;
}

void add_global_constant(gbAllocator a, String name, Type *type, ExactValue value) {
	Entity *entity = alloc_entity(a, Entity_Constant, nullptr, make_token_ident(name), type);
	entity->Constant.value = value;
	add_global_entity(entity);
}


void add_global_string_constant(gbAllocator a, String name, String value) {
	add_global_constant(a, name, t_untyped_string, exact_value_string(value));
}


void add_global_type_entity(gbAllocator a, String name, Type *type) {
	add_global_entity(make_entity_type_name(a, nullptr, make_token_ident(name), type));
}



void init_universal_scope(void) {
	BuildContext *bc = &build_context;
	// NOTE(bill): No need to free these
	gbAllocator a = heap_allocator();
	universal_scope = create_scope(nullptr, a);

// Types
	for (isize i = 0; i < gb_count_of(basic_types); i++) {
		add_global_type_entity(a, basic_types[i].Basic.name, &basic_types[i]);
	}
	add_global_type_entity(a, str_lit("byte"), &basic_types[Basic_u8]);

// Constants
	add_global_constant(a, str_lit("true"),  t_untyped_bool, exact_value_bool(true));
	add_global_constant(a, str_lit("false"), t_untyped_bool, exact_value_bool(false));

	add_global_entity(make_entity_nil(a, str_lit("nil"), t_untyped_nil));
	add_global_entity(make_entity_library_name(a,  universal_scope,
	                                           make_token_ident(str_lit("__llvm_core")), t_invalid,
	                                           str_lit(""), str_lit("__llvm_core")));

	// TODO(bill): Set through flags in the compiler
	add_global_string_constant(a, str_lit("ODIN_OS"),      bc->ODIN_OS);
	add_global_string_constant(a, str_lit("ODIN_ARCH"),    bc->ODIN_ARCH);
	add_global_string_constant(a, str_lit("ODIN_ENDIAN"),  bc->ODIN_ENDIAN);
	add_global_string_constant(a, str_lit("ODIN_VENDOR"),  bc->ODIN_VENDOR);
	add_global_string_constant(a, str_lit("ODIN_VERSION"), bc->ODIN_VERSION);
	add_global_string_constant(a, str_lit("ODIN_ROOT"),    bc->ODIN_ROOT);


// Builtin Procedures
	for (isize i = 0; i < gb_count_of(builtin_procs); i++) {
		BuiltinProcId id = cast(BuiltinProcId)i;
		String name = builtin_procs[i].name;
		if (name != "") {
			Entity *entity = alloc_entity(a, Entity_Builtin, nullptr, make_token_ident(name), t_invalid);
			entity->Builtin.id = id;
			add_global_entity(entity);
		}
	}


	t_u8_ptr       = make_type_pointer(a, t_u8);
	t_int_ptr      = make_type_pointer(a, t_int);
	t_i64_ptr      = make_type_pointer(a, t_i64);
	t_f64_ptr      = make_type_pointer(a, t_f64);
	t_u8_slice     = make_type_slice(a, t_u8);
	t_string_slice = make_type_slice(a, t_string);
}




void init_checker_info(CheckerInfo *i) {
	gbAllocator a = heap_allocator();
	map_init(&i->types,         a);
	array_init(&i->definitions, a);
	array_init(&i->entities,    a);
	map_init(&i->untyped,       a);
	map_init(&i->foreigns,      a);
	map_init(&i->gen_procs,     a);
	map_init(&i->gen_types,     a);
	map_init(&i->type_info_map, a);
	map_init(&i->files,         a);
	array_init(&i->variable_init_order, a);

	i->type_info_count = 0;
}

void destroy_checker_info(CheckerInfo *i) {
	map_destroy(&i->types);
	array_free(&i->definitions);
	array_free(&i->entities);
	map_destroy(&i->untyped);
	map_destroy(&i->foreigns);
	map_destroy(&i->gen_procs);
	map_destroy(&i->gen_types);
	map_destroy(&i->type_info_map);
	map_destroy(&i->files);
	array_free(&i->variable_init_order);
}


void init_checker(Checker *c, Parser *parser) {
	if (global_error_collector.count > 0) {
		gb_exit(1);
	}
	BuildContext *bc = &build_context;

	gbAllocator a = heap_allocator();

	c->parser = parser;
	init_checker_info(&c->info);
	gb_mutex_init(&c->mutex);

	array_init(&c->proc_stack, a);
	array_init(&c->procs, a);

	// NOTE(bill): Is this big enough or too small?
	isize item_size = gb_max3(gb_size_of(Entity), gb_size_of(Type), gb_size_of(Scope));
	isize total_token_count = 0;
	for_array(i, c->parser->files) {
		AstFile *f = c->parser->files[i];
		total_token_count += f->tokens.count;
	}
	isize arena_size = 2 * item_size * total_token_count;
	gb_arena_init_from_allocator(&c->tmp_arena, a, arena_size);
	gb_arena_init_from_allocator(&c->arena, a, arena_size);

	// c->allocator = pool_allocator(&c->pool);
	c->allocator = heap_allocator();
	// c->allocator     = gb_arena_allocator(&c->arena);
	c->tmp_allocator = gb_arena_allocator(&c->tmp_arena);

	c->global_scope = create_scope(universal_scope, c->allocator);
	c->context.scope = c->global_scope;

	map_init(&c->file_scopes, heap_allocator());
	ptr_set_init(&c->checked_files, heap_allocator());

	array_init(&c->file_order, heap_allocator(), c->parser->files.count);
}

void destroy_checker(Checker *c) {
	destroy_checker_info(&c->info);
	gb_mutex_destroy(&c->mutex);

	destroy_scope(c->global_scope);
	array_free(&c->proc_stack);
	array_free(&c->procs);

	gb_arena_free(&c->tmp_arena);

	map_destroy(&c->file_scopes);
	ptr_set_destroy(&c->checked_files);
	array_free(&c->file_order);
}


Entity *entity_of_ident(CheckerInfo *i, AstNode *identifier) {
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
		Entity *entity = entity_of_ident(i, expr);
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


DeclInfo *decl_info_of_entity(CheckerInfo *i, Entity *e) {
	if (e != nullptr) {
		return e->decl_info;
	}
	return nullptr;
}

DeclInfo *decl_info_of_ident(CheckerInfo *i, AstNode *ident) {
	return decl_info_of_entity(i, entity_of_ident(i, ident));
}

AstFile *ast_file_of_filename(CheckerInfo *i, String filename) {
	AstFile **found = map_get(&i->files, hash_string(filename));
	if (found != nullptr) {
		return *found;
	}
	return nullptr;
}
Scope *scope_of_node(CheckerInfo *i, AstNode *node) {
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
		compiler_error("TypeInfo for '%s' could not be found", type_to_string(type));
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
	map_set(&i->untyped, hash_node(expression), make_expr_info(lhs, mode, type, value));
}

void add_type_and_value(CheckerInfo *i, AstNode *expression, AddressingMode mode, Type *type, ExactValue value) {
	if (expression == nullptr) {
		return;
	}
	if (mode == Addressing_Invalid) {
		return;
	}
	if (mode == Addressing_Constant && type == t_invalid) {
		compiler_error("add_type_and_value - invalid type: %s", type_to_string(type));
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
		Entity *ie = scope_insert_entity(scope, entity);
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

void add_entity_use(Checker *c, AstNode *identifier, Entity *entity) {
	GB_ASSERT(identifier != nullptr);
	if (identifier->kind != AstNode_Ident) {
		return;
	}
	if (entity == nullptr) {
		return;
	}
	if (entity->identifier == nullptr) {
		entity->identifier = identifier;
	}
	identifier->Ident.entity = entity;
	add_declaration_dependency(c, entity); // TODO(bill): Should this be here?
}


void add_entity_and_decl_info(Checker *c, AstNode *identifier, Entity *e, DeclInfo *d) {
	GB_ASSERT(identifier->kind == AstNode_Ident);
	GB_ASSERT(e != nullptr && d != nullptr);
	GB_ASSERT(identifier->Ident.token.string == e->token.string);
	if (e->scope != nullptr) add_entity(c, e->scope, identifier, e);
	add_entity_definition(&c->info, identifier, e);
	GB_ASSERT(e->decl_info == nullptr);
	e->decl_info = d;
	array_add(&c->info.entities, e);
	e->order_in_src = c->info.entities.count;
	// map_set(&c->info.entities, hash_entity(e), d);
	// e->order_in_src = c->info.entities.entries.count;
}


void add_implicit_entity(Checker *c, AstNode *clause, Entity *e) {
	GB_ASSERT(clause != nullptr);
	GB_ASSERT(e != nullptr);
	GB_ASSERT(clause->kind == AstNode_CaseClause);
	clause->CaseClause.implicit_entity = e;
}





void add_type_info_type(Checker *c, Type *t) {
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

	if (map_get(&c->info.type_info_map, hash_type(t)) != nullptr) {
		// Types have already been added
		return;
	}

	isize ti_index = -1;
	for_array(i, c->info.type_info_map.entries) {
		auto *e = &c->info.type_info_map.entries[i];
		Type *prev_type = cast(Type *)e->key.ptr;
		if (are_types_identical(t, prev_type)) {
			// Duplicate entry
			ti_index = e->value;
			break;
		}
	}
	if (ti_index < 0) {
		// Unique entry
		// NOTE(bill): map entries grow linearly and in order
		ti_index = c->info.type_info_count;
		c->info.type_info_count++;
	}
	map_set(&c->info.type_info_map, hash_type(t), ti_index);




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
		add_type_info_type(c, make_type_pointer(c->allocator, bt->Array.elem));
		add_type_info_type(c, t_int);
		break;
	case Type_DynamicArray:
		add_type_info_type(c, bt->DynamicArray.elem);
		add_type_info_type(c, make_type_pointer(c->allocator, bt->DynamicArray.elem));
		add_type_info_type(c, t_int);
		add_type_info_type(c, t_allocator);
		break;
	case Type_Slice:
		add_type_info_type(c, bt->Slice.elem);
		add_type_info_type(c, make_type_pointer(c->allocator, bt->Slice.elem));
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
		generate_map_internal_types(c->allocator, bt);
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
	array_add(&c->procs, info);
}

void check_procedure_later(Checker *c, AstFile *file, Token token, DeclInfo *decl, Type *type, AstNode *body, u64 tags) {
	ProcedureInfo info = {};
	info.file = file;
	info.token = token;
	info.decl  = decl;
	info.type  = type;
	info.body  = body;
	info.tags  = tags;
	check_procedure_later(c, info);
}

void push_procedure(Checker *c, Type *type) {
	array_add(&c->proc_stack, type);
}

void pop_procedure(Checker *c) {
	array_pop(&c->proc_stack);
}

Type *const curr_procedure_type(Checker *c) {
	isize count = c->proc_stack.count;
	if (count > 0) {
		return c->proc_stack[count-1];
	}
	return nullptr;
}

void add_curr_ast_file(Checker *c, AstFile *file) {
	if (file != nullptr) {
		TokenPos zero_pos = {};
		global_error_collector.prev = zero_pos;
		c->curr_ast_file = file;
		c->context.decl  = file->decl_info;
		c->context.scope = file->scope;
		c->context.file_scope = file->scope;
	}
}


void add_dependency_to_map(PtrSet<Entity *> *map, CheckerInfo *info, Entity *entity) {
	if (entity == nullptr) {
		return;
	}

	String name = entity->token.string;

	if (entity->type != nullptr &&
	    is_type_polymorphic(entity->type)) {

		DeclInfo *decl = decl_info_of_entity(info, entity);
		if (decl != nullptr && decl->gen_proc_type == nullptr) {
			return;
		}
	}

	if (ptr_set_exists(map, entity)) {
		return;
	}


	ptr_set_add(map, entity);
	DeclInfo *decl = decl_info_of_entity(info, entity);
	if (decl != nullptr) {
		for_array(i, decl->deps.entries) {
			Entity *e = decl->deps.entries[i].ptr;
			add_dependency_to_map(map, info, e);
		}
	}
}

PtrSet<Entity *> generate_minimum_dependency_set(CheckerInfo *info, Entity *start) {
	PtrSet<Entity *> map = {}; // Key: Entity *
	ptr_set_init(&map, heap_allocator());

	for_array(i, info->definitions) {
		Entity *e = info->definitions[i];
		// if (e->scope->is_global && !is_type_poly_proc(e->type)) { // TODO(bill): is the check enough?
		if (e->scope->is_global) { // TODO(bill): is the check enough?
			if (e->type == nullptr || !is_type_poly_proc(e->type))  {
				// NOTE(bill): Require runtime stuff
				add_dependency_to_map(&map, info, e);
			}
		} else if (e->kind == Entity_Procedure) {
			if (e->Procedure.is_export) {
				add_dependency_to_map(&map, info, e);
			}
			if (e->Procedure.is_foreign) {
				add_dependency_to_map(&map, info, e->Procedure.foreign_library);
			}
		} else if (e->kind == Entity_Variable) {
			if (e->Variable.is_export) {
				add_dependency_to_map(&map, info, e);
			}
		}
	}

	add_dependency_to_map(&map, info, start);

	return map;
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

		DeclInfo *decl = decl_info_of_entity(info, e);
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

	Array<EntityGraphNode *> G = {};
	array_init(&G, a, M.entries.count);

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
	Entity *e = current_scope_lookup_entity(c->global_scope, name);
	if (e == nullptr) {
		compiler_error("Could not find type declaration for '%.*s'\n"
		               "Is '_preload.odin' missing from the 'core' directory relative to odin.exe?", LIT(name));
		// NOTE(bill): This will exit the program as it's cannot continue without it!
	}
	return e;
}

Type *find_core_type(Checker *c, String name) {
	Entity *e = current_scope_lookup_entity(c->global_scope, name);
	if (e == nullptr) {
		compiler_error("Could not find type declaration for '%.*s'\n"
		               "Is '_preload.odin' missing from the 'core' directory relative to odin.exe?", LIT(name));
		// NOTE(bill): This will exit the program as it's cannot continue without it!
	}
	return e->type;
}


void check_entity_decl(Checker *c, Entity *e, DeclInfo *d, Type *named_type);

Array<Entity *> proc_group_entities(Checker *c, Operand o) {
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

void init_preload(Checker *c) {
	if (t_type_info == nullptr) {
		Entity *type_info_entity = find_core_entity(c, str_lit("Type_Info"));

		t_type_info = type_info_entity->type;
		t_type_info_ptr = make_type_pointer(c->allocator, t_type_info);
		GB_ASSERT(is_type_struct(type_info_entity->type));
		TypeStruct *tis = &base_type(type_info_entity->type)->Struct;

		Entity *type_info_enum_value = find_core_entity(c, str_lit("Type_Info_Enum_Value"));

		t_type_info_enum_value = type_info_enum_value->type;
		t_type_info_enum_value_ptr = make_type_pointer(c->allocator, t_type_info_enum_value);

		GB_ASSERT(tis->fields.count == 3);

		Entity *type_info_variant = tis->fields_in_src_order[2];
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

		t_type_info_named_ptr         = make_type_pointer(c->allocator, t_type_info_named);
		t_type_info_integer_ptr       = make_type_pointer(c->allocator, t_type_info_integer);
		t_type_info_rune_ptr          = make_type_pointer(c->allocator, t_type_info_rune);
		t_type_info_float_ptr         = make_type_pointer(c->allocator, t_type_info_float);
		t_type_info_complex_ptr       = make_type_pointer(c->allocator, t_type_info_complex);
		t_type_info_string_ptr        = make_type_pointer(c->allocator, t_type_info_string);
		t_type_info_boolean_ptr       = make_type_pointer(c->allocator, t_type_info_boolean);
		t_type_info_any_ptr           = make_type_pointer(c->allocator, t_type_info_any);
		t_type_info_pointer_ptr       = make_type_pointer(c->allocator, t_type_info_pointer);
		t_type_info_procedure_ptr     = make_type_pointer(c->allocator, t_type_info_procedure);
		t_type_info_array_ptr         = make_type_pointer(c->allocator, t_type_info_array);
		t_type_info_dynamic_array_ptr = make_type_pointer(c->allocator, t_type_info_dynamic_array);
		t_type_info_slice_ptr         = make_type_pointer(c->allocator, t_type_info_slice);
		t_type_info_tuple_ptr         = make_type_pointer(c->allocator, t_type_info_tuple);
		t_type_info_struct_ptr        = make_type_pointer(c->allocator, t_type_info_struct);
		t_type_info_union_ptr         = make_type_pointer(c->allocator, t_type_info_union);
		t_type_info_enum_ptr          = make_type_pointer(c->allocator, t_type_info_enum);
		t_type_info_map_ptr           = make_type_pointer(c->allocator, t_type_info_map);
		t_type_info_bit_field_ptr     = make_type_pointer(c->allocator, t_type_info_bit_field);
	}

	if (t_allocator == nullptr) {
		Entity *e = find_core_entity(c, str_lit("Allocator"));
		t_allocator = e->type;
		t_allocator_ptr = make_type_pointer(c->allocator, t_allocator);
	}

	if (t_context == nullptr) {
		Entity *e = find_core_entity(c, str_lit("Context"));
		e_context = e;
		t_context = e->type;
		t_context_ptr = make_type_pointer(c->allocator, t_context);
	}

	if (t_source_code_location == nullptr) {
		Entity *e = find_core_entity(c, str_lit("Source_Code_Location"));
		t_source_code_location = e->type;
		t_source_code_location_ptr = make_type_pointer(c->allocator, t_allocator);
	}

	if (t_map_key == nullptr) {
		Entity *e = find_core_entity(c, str_lit("__Map_Key"));
		t_map_key = e->type;
	}

	if (t_map_header == nullptr) {
		Entity *e = find_core_entity(c, str_lit("__Map_Header"));
		t_map_header = e->type;
	}


	{
		String _global = str_lit("_global");

		Entity *type_info_entity = find_core_entity(c, str_lit("Type_Info"));
		Scope *preload_scope = type_info_entity->scope;

		Entity *e = make_entity_import_name(c->allocator, preload_scope, make_token_ident(_global), t_invalid,
		                                    str_lit(""), _global,
		                                    preload_scope);

		add_entity(c, universal_scope, nullptr, e);
	}

	c->done_preload = true;

}




DECL_ATTRIBUTE_PROC(foreign_block_decl_attribute) {
	if (name == "default_calling_convention") {
		if (value.kind == ExactValue_String) {
			auto cc = string_to_calling_convention(value.value_string);
			if (cc == ProcCC_Invalid) {
				error(elem, "Unknown procedure calling convention: '%.*s'\n", LIT(value.value_string));
			} else {
				c->context.foreign_context.default_cc = cc;
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
				c->context.foreign_context.link_prefix = link_prefix;
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
	}
	return false;
}

DECL_ATTRIBUTE_PROC(var_decl_attribute) {
	if (c->context.curr_proc_decl != nullptr) {
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
		} else if (c->context.foreign_context.curr_library || c->context.foreign_context.in_export) {
			error(elem, "A foreign block variable cannot be thread local");
		} else if (value.kind == ExactValue_Invalid) {
			ac->thread_local_model = str_lit("default");
		} else if (value.kind == ExactValue_String) {
			String model = value.value_string;
			if (model == "localdynamic" ||
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



void check_decl_attributes(Checker *c, Array<AstNode *> attributes, DeclAttributeProc *proc, AttributeContext *ac) {
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
				if (op.mode != Addressing_Constant) {
					error(value, "An attribute element must be constant");
				} else {
					ev = op.value;
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


bool check_arity_match(Checker *c, AstNodeValueDecl *vd, bool is_global) {
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

void check_collect_entities_from_when_stmt(Checker *c, AstNodeWhenStmt *ws) {
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

void check_collect_value_decl(Checker *c, AstNode *decl) {
	ast_node(vd, ValueDecl, decl);

	if (vd->been_handled) return;
	vd->been_handled = true;

	if (vd->is_mutable) {
		if (!c->context.scope->is_file) {
			// NOTE(bill): local scope -> handle later and in order
			return;
		}

		// NOTE(bill): You need to store the entity information here unline a constant declaration
		isize entity_cap = vd->names.count;
		isize entity_count = 0;
		Entity **entities = gb_alloc_array(c->allocator, Entity *, entity_cap);
		DeclInfo *di = nullptr;
		if (vd->values.count > 0) {
			di = make_declaration_info(heap_allocator(), c->context.scope, c->context.decl);
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
			Entity *e = make_entity_variable(c->allocator, c->context.scope, name->Ident.token, nullptr, false);
			e->identifier = name;

			if (vd->is_using) {
				vd->is_using = false; // NOTE(bill): This error will be only caught once
				error(name, "'using' is not allowed at the file scope");
			}

			AstNode *fl = c->context.foreign_context.curr_library;
			if (fl != nullptr) {
				GB_ASSERT(fl->kind == AstNode_Ident);
				e->Variable.is_foreign = true;
				e->Variable.foreign_library_ident = fl;

				e->Variable.link_prefix = c->context.foreign_context.link_prefix;

			} else if (c->context.foreign_context.in_export) {
				e->Variable.is_export = true;
			}

			entities[entity_count++] = e;

			DeclInfo *d = di;
			if (d == nullptr || i > 0) {
				AstNode *init_expr = value;
				d = make_declaration_info(heap_allocator(), e->scope, c->context.decl);
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

			AstNode *fl = c->context.foreign_context.curr_library;
			DeclInfo *d = make_declaration_info(c->allocator, c->context.scope, c->context.decl);
			Entity *e = nullptr;

			d->attributes = vd->attributes;

			if (is_ast_node_type(init) ||
				(vd->type != nullptr && vd->type->kind == AstNode_TypeType)) {
				e = make_entity_type_name(c->allocator, d->scope, token, nullptr);
				if (vd->type != nullptr) {
					error(name, "A type declaration cannot have an type parameter");
				}
				d->type_expr = init;
				d->init_expr = init;
			} else if (init->kind == AstNode_ProcLit) {
				if (c->context.scope->is_struct) {
					error(name, "Procedure declarations are not allowed within a struct");
					continue;
				}
				ast_node(pl, ProcLit, init);
				e = make_entity_procedure(c->allocator, d->scope, token, nullptr, pl->tags);
				if (fl != nullptr) {
					GB_ASSERT(fl->kind == AstNode_Ident);
					e->Procedure.foreign_library_ident = fl;
					e->Procedure.is_foreign = true;

					GB_ASSERT(pl->type->kind == AstNode_ProcType);
					auto cc = pl->type->ProcType.calling_convention;
					if (cc == ProcCC_ForeignBlockDefault) {
						cc = ProcCC_CDecl;
						if (c->context.foreign_context.default_cc > 0) {
							cc = c->context.foreign_context.default_cc;
						}
					}
					e->Procedure.link_prefix = c->context.foreign_context.link_prefix;

					GB_ASSERT(cc != ProcCC_Invalid);
					pl->type->ProcType.calling_convention = cc;

				} else if (c->context.foreign_context.in_export) {
					e->Procedure.is_export = true;
				}
				d->proc_lit = init;
				d->type_expr = pl->type;
			} else if (init->kind == AstNode_ProcGroup) {
				ast_node(pg, ProcGroup, init);
				e = make_entity_proc_group(c->allocator, d->scope, token, nullptr);
				if (fl != nullptr) {
					error(name, "Procedure groups are not allowed within a foreign block");
				}
				d->init_expr = init;
			} else {
				e = make_entity_constant(c->allocator, d->scope, token, nullptr, empty_exact_value);
				d->type_expr = vd->type;
				d->init_expr = init;
			}
			e->identifier = name;

			if (e->kind != Entity_Procedure) {
				if (fl != nullptr || c->context.foreign_context.in_export) {
					AstNodeKind kind = init->kind;
					error(name, "Only procedures and variables are allowed to be in a foreign block, got %.*s", LIT(ast_node_strings[kind]));
					if (kind == AstNode_ProcType) {
						gb_printf_err("\tDid you forget to append '---' to the procedure?\n");
					}
				}
			}


			add_entity_and_decl_info(c, name, e, d);
		}

		check_arity_match(c, vd, true);
	}
}

void check_add_foreign_block_decl(Checker *c, AstNode *decl) {
	ast_node(fb, ForeignBlockDecl, decl);

	if (fb->been_handled) return;
	fb->been_handled = true;

	AstNode *foreign_library = fb->foreign_library;

	CheckerContext prev_context = c->context;
	if (foreign_library->kind == AstNode_Ident) {
		c->context.foreign_context.curr_library = foreign_library;
	} else if (foreign_library->kind == AstNode_Implicit && foreign_library->Implicit.kind == Token_export) {
		c->context.foreign_context.in_export = true;
	} else {
		error(foreign_library, "Foreign block name must be an identifier or 'export'");
		c->context.foreign_context.curr_library = nullptr;
	}

	check_decl_attributes(c, fb->attributes, foreign_block_decl_attribute, nullptr);

	c->context.collect_delayed_decls = true;
	check_collect_entities(c, fb->decls);
	c->context = prev_context;
}

// NOTE(bill): If file_scopes == nullptr, this will act like a local scope
void check_collect_entities(Checker *c, Array<AstNode *> nodes) {
	for_array(decl_index, nodes) {
		AstNode *decl = nodes[decl_index];
		if (!is_ast_node_decl(decl) && !is_ast_node_when_stmt(decl)) {
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
			if (!c->context.scope->is_file) {
				error(decl, "import declarations are only allowed in the file scope");
				// NOTE(bill): _Should_ be caught by the parser
				// TODO(bill): Better error handling if it isn't
				continue;
			}
			if (c->context.collect_delayed_decls) {
				check_add_import_decl(c, id);
			}
		case_end;

		case_ast_node(ed, ExportDecl, decl);
			if (!c->context.scope->is_file) {
				error(decl, "export declarations are only allowed in the file scope");
				// NOTE(bill): _Should_ be caught by the parser
				// TODO(bill): Better error handling if it isn't
				continue;
			}
			if (c->context.collect_delayed_decls) {
				check_add_export_decl(c, ed);
			}
		case_end;

		case_ast_node(fl, ForeignImportDecl, decl);
			if (!c->context.scope->is_file) {
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
			if (c->context.scope->is_file) {
				error(decl, "Only declarations are allowed at file scope");
			}
			break;
		}
	}

	// NOTE(bill): 'when' stmts need to be handled after the other as the condition may refer to something
	// declared after this stmt in source
	if (!c->context.scope->is_file || c->context.collect_delayed_decls) {
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

	bool processing_preload = true;
	for_array(i, c->info.entities) {
		Entity *e = c->info.entities[i];
		DeclInfo *d = e->decl_info;

		if (d->scope != e->scope) {
			continue;
		}

		if (!d->scope->has_been_imported) {
			// NOTE(bill): All of these unchecked entities could mean a lot of unused allocations
			// TODO(bill): Should this be worried about?
			continue;
		}


		AstFile *file = d->scope->file;
		add_curr_ast_file(c, file);

		if (e->token.string == "main") {
			if (e->kind != Entity_Procedure) {
				if (e->scope->is_init) {
					error(e->token, "'main' is reserved as the entry point procedure in the initial scope");
					continue;
				}
			} else if (e->scope->is_global) {
				error(e->token, "'main' is reserved as the entry point procedure in the initial scope");
				continue;
			}
		}

		CheckerContext prev_context = c->context;
		c->context.decl = d;
		c->context.scope = d->scope;
		check_entity_decl(c, e, d, nullptr);
		c->context = prev_context;


		if (!d->scope->is_global) {
			processing_preload = false;
		}

		if (!processing_preload) {
			init_preload(c);
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

	filename.text += slash;
	filename.len -= slash;

	dot = filename.len;
	while (dot --> 0) {
		u8 c = filename[dot];
		if (c == '.') {
			break;
		}
	}

	filename.len = dot;

	if (is_string_an_identifier(filename)) {
		return filename;
	} else {
		return str_lit("_");
	}
}






void add_import_dependency_node(Checker *c, AstNode *decl, Map<ImportGraphNode *> *M) {
	Scope *parent_file_scope = decl->file->scope;

	switch (decl->kind) {
	case_ast_node(id, ImportDecl, decl);
		String path = id->fullpath;
		HashKey key = hash_string(path);
		Scope **found = map_get(&c->file_scopes, key);
		if (found == nullptr) {
			for_array(scope_index, c->file_scopes.entries) {
				Scope *scope = c->file_scopes.entries[scope_index].value;
				gb_printf_err("%.*s\n", LIT(scope->file->tokenizer.fullpath));
			}
			Token token = ast_node_token(decl);
			gb_printf_err("%.*s(%td:%td)\n", LIT(token.pos.file), token.pos.line, token.pos.column);
			GB_PANIC("Unable to find scope for file: %.*s", LIT(path));
		}
		Scope *scope = *found;
		GB_ASSERT(scope != nullptr);

		id->file = scope->file;

		ImportGraphNode **found_node = nullptr;
		ImportGraphNode *m = nullptr;
		ImportGraphNode *n = nullptr;

		found_node = map_get(M, hash_pointer(scope));
		GB_ASSERT(found_node != nullptr);
		m = *found_node;

		found_node = map_get(M, hash_pointer(parent_file_scope));
		GB_ASSERT(found_node != nullptr);
		n = *found_node;

		// TODO(bill): How should the edges be attched for 'import'?
		import_graph_node_set_add(&n->succ, m);
		import_graph_node_set_add(&m->pred, n);
		ptr_set_add(&m->scope->imported, n->scope);
		if (id->is_using) {
			ptr_set_add(&m->scope->exported, n->scope);
		}
	case_end;


	case_ast_node(ed, ExportDecl, decl);
		String path = ed->fullpath;
		HashKey key = hash_string(path);
		Scope **found = map_get(&c->file_scopes, key);
		if (found == nullptr) {
			for_array(scope_index, c->file_scopes.entries) {
				Scope *scope = c->file_scopes.entries[scope_index].value;
				gb_printf_err("%.*s\n", LIT(scope->file->tokenizer.fullpath));
			}
			Token token = ast_node_token(decl);
			gb_printf_err("%.*s(%td:%td)\n", LIT(token.pos.file), token.pos.line, token.pos.column);
			GB_PANIC("Unable to find scope for file: %.*s", LIT(path));
		}
		Scope *scope = *found;
		GB_ASSERT(scope != nullptr);
		ed->file = scope->file;

		ImportGraphNode **found_node = nullptr;
		ImportGraphNode *m = nullptr;
		ImportGraphNode *n = nullptr;

		found_node = map_get(M, hash_pointer(scope));
		GB_ASSERT(found_node != nullptr);
		m = *found_node;

		found_node = map_get(M, hash_pointer(parent_file_scope));
		GB_ASSERT(found_node != nullptr);
		n = *found_node;

		import_graph_node_set_add(&n->succ, m);
		import_graph_node_set_add(&m->pred, n);
		ptr_set_add(&m->scope->exported, n->scope);
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
	gbAllocator a = heap_allocator();

	Map<ImportGraphNode *> M = {}; // Key: Scope *
	map_init(&M, a);
	defer (map_destroy(&M));

	for_array(i, c->parser->files) {
		Scope *scope = c->parser->files[i]->scope;

		ImportGraphNode *n = import_graph_node_create(heap_allocator(), scope);
		map_set(&M, hash_pointer(scope), n);
	}

	// Calculate edges for graph M
	for_array(i, c->parser->files) {
		AstFile *f = c->parser->files[i];
		for_array(j, f->decls) {
			AstNode *decl = f->decls[j];
			add_import_dependency_node(c, decl, &M);
		}
	}

	Array<ImportGraphNode *> G = {};
	array_init(&G, a);

	for_array(i, M.entries) {
		array_add(&G, M.entries[i].value);
	}

	for_array(i, G) {
		ImportGraphNode *n = G[i];
		n->index = i;
		n->dep_count = n->succ.entries.count;
		GB_ASSERT(n->dep_count >= 0);
	}

	return G;
}

struct ImportPathItem {
	Scope *  scope;
	AstNode *decl;
};

Array<ImportPathItem> find_import_path(Checker *c, Scope *start, Scope *end, PtrSet<Scope *> *visited) {
	Array<ImportPathItem> empty_path = {};

	if (ptr_set_exists(visited, start)) {
		return empty_path;
	}
	ptr_set_add(visited, start);


	String path = start->file->tokenizer.fullpath;
	HashKey key = hash_string(path);
	Scope **found = map_get(&c->file_scopes, key);
	if (found) {
		AstFile *f = (*found)->file;
		GB_ASSERT(f != nullptr);

		for_array(i, f->imports_and_exports) {
			Scope *s = nullptr;
			AstNode *decl = f->imports_and_exports[i];
			if (decl->kind == AstNode_ExportDecl) {
				s = decl->ExportDecl.file->scope;
			} else if (decl->kind == AstNode_ImportDecl) {
				if (!decl->ImportDecl.is_using) {
					// continue;
				}
				s = decl->ImportDecl.file->scope;
			} else {
				continue;
			}
			GB_ASSERT(s != nullptr);

			ImportPathItem item = {s, decl};
			if (s == end) {
				Array<ImportPathItem> path = {};
				array_init(&path, heap_allocator());
				array_add(&path, item);
				return path;
			}
			Array<ImportPathItem> next_path = find_import_path(c, s, end, visited);
			if (next_path.count > 0) {
				array_add(&next_path, item);
				return next_path;
			}
		}
	}
	return empty_path;
}

void check_add_import_decl(Checker *c, AstNodeImportDecl *id) {
	if (id->been_handled) return;
	id->been_handled = true;

	Scope *parent_scope = c->context.scope;
	GB_ASSERT(parent_scope->is_file);

	Token token = id->relpath;
	HashKey key = hash_string(id->fullpath);
	Scope **found = map_get(&c->file_scopes, key);
	if (found == nullptr) {
		for_array(scope_index, c->file_scopes.entries) {
			Scope *scope = c->file_scopes.entries[scope_index].value;
			gb_printf_err("%.*s\n", LIT(scope->file->tokenizer.fullpath));
		}
		gb_printf_err("%.*s(%td:%td)\n", LIT(token.pos.file), token.pos.line, token.pos.column);
		GB_PANIC("Unable to find scope for file: %.*s", LIT(id->fullpath));
	}
	Scope *scope = *found;

	if (scope->is_global) {
		error(token, "Importing a #shared_global_scope is disallowed and unnecessary");
		return;
	}

	if (ptr_set_exists(&parent_scope->imported, scope)) {
		// error(token, "Multiple import of the same file within this scope");
	} else {
		ptr_set_add(&parent_scope->imported, scope);
	}


	if (id->using_in_list.count == 0) {
		String import_name = path_to_entity_name(id->import_name.string, id->fullpath);
		if (is_blank_ident(import_name)) {
			if (id->is_using) {
				// TODO(bill): Should this be a warning?
			} else {
				error(token, "File name, %.*s, cannot be use as an import name as it is not a valid identifier", LIT(id->import_name.string));
			}
		} else {
			GB_ASSERT(id->import_name.pos.line != 0);
			id->import_name.string = import_name;
			Entity *e = make_entity_import_name(c->allocator, parent_scope, id->import_name, t_invalid,
			                                    id->fullpath, id->import_name.string,
			                                    scope);

			add_entity(c, parent_scope, nullptr, e);
		}
	}

	if (id->is_using) {
		if (parent_scope->is_global) {
			error(id->import_name, "#shared_global_scope imports cannot use using");
			return;
		}

		// NOTE(bill): Add imported entities to this file's scope
		if (id->using_in_list.count > 0) {
			for_array(list_index, id->using_in_list) {
				AstNode *node = id->using_in_list[list_index];
				ast_node(ident, Ident, node);
				String name = ident->token.string;

				Entity *e = scope_lookup_entity(scope, name);
				if (e == nullptr) {
					if (is_blank_ident(name)) {
						error(node, "'_' cannot be used as a value");
					} else {
						error(node, "Undeclared name in this importation: '%.*s'", LIT(name));
					}
					continue;
				}
				if (e->scope == parent_scope) continue;

				bool implicit_is_found = ptr_set_exists(&scope->implicit, e);
				if (is_entity_exported(e) && !implicit_is_found) {
					add_entity_use(c, node, e);
					bool ok = add_entity(c, parent_scope, e->identifier, e);
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
					Entity *prev = scope_lookup_entity(parent_scope, e->token.string);
					// if (prev) gb_printf_err("%.*s\n", LIT(prev->token.string));
					bool ok = add_entity(c, parent_scope, e->identifier, e);
					if (ok) ptr_set_add(&parent_scope->implicit, e);
				}
			}
		}
	}
	ptr_set_add(&c->checked_files, scope->file);
	scope->has_been_imported = true;
}

void check_add_export_decl(Checker *c, AstNodeExportDecl *ed) {
	if (ed->been_handled) return;
	ed->been_handled = true;

	Scope *parent_scope = c->context.scope;
	GB_ASSERT(parent_scope->is_file);

	Token token = ed->relpath;
	HashKey key = hash_string(ed->fullpath);
	Scope **found = map_get(&c->file_scopes, key);
	if (found == nullptr) {
		for_array(scope_index, c->file_scopes.entries) {
			Scope *scope = c->file_scopes.entries[scope_index].value;
			gb_printf_err("%.*s\n", LIT(scope->file->tokenizer.fullpath));
		}
		gb_printf_err("%.*s(%td:%td)\n", LIT(token.pos.file), token.pos.line, token.pos.column);
		GB_PANIC("Unable to find scope for file: %.*s", LIT(ed->fullpath));
	}
	Scope *scope = *found;

	if (scope->is_global) {
		error(token, "Exporting a #shared_global_scope is disallowed and unnecessary");
		return;
	}

	if (parent_scope->is_global) {
		error(ed->token, "'export' cannot be used on #shared_global_scope");
		return;
	}

	if (ptr_set_exists(&parent_scope->imported, scope)) {
		// error(token, "Multiple import of the same file within this scope");
	} else {
		ptr_set_add(&parent_scope->imported, scope);
	}

	if (ed->using_in_list.count > 0) {
		for_array(list_index, ed->using_in_list) {
			AstNode *node = ed->using_in_list[list_index];
			ast_node(ident, Ident, node);
			String name = ident->token.string;

			Entity *e = scope_lookup_entity(scope, name);
			if (e == nullptr) {
				if (is_blank_ident(name)) {
					error(node, "'_' cannot be used as a value");
				} else {
					error(node, "Undeclared name in this importation: '%.*s'", LIT(name));
				}
				continue;
			}
			if (e->scope == parent_scope) continue;

			if (is_entity_exported(e)) {
				add_entity(c, parent_scope, e->identifier, e);
			} else {
				error(node, "'%.*s' is exported from this scope", LIT(name));
				continue;
			}
		}
	} else {
		// NOTE(bill): Add imported entities to this file's scope
		for_array(elem_index, scope->elements.entries) {
			Entity *e = scope->elements.entries[elem_index].value;
			if (e->scope == parent_scope) continue;

			if (is_entity_kind_exported(e->kind)) {
				add_entity(c, parent_scope, e->identifier, e);
			}
		}
	}

	ptr_set_add(&c->checked_files, scope->file);
	scope->has_been_imported = true;
}

void check_add_foreign_import_decl(Checker *c, AstNode *decl) {
	ast_node(fl, ForeignImportDecl, decl);

	if (fl->been_handled) return;
	fl->been_handled = true;

	Scope *parent_scope = c->context.scope;
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
		gb_memcopy(c_str, fullpath.text, fullpath.len);
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
	Entity *e = make_entity_library_name(c->allocator, parent_scope, fl->library_name, t_invalid,
	                                     fl->fullpath, library_name);
	add_entity(c, parent_scope, nullptr, e);
}


bool collect_checked_files_from_import_decl_list(Checker *c, Array<AstNode *> decls) {
	bool new_files = false;
	for_array(i, decls) {
		AstNode *decl = decls[i];
		switch (decl->kind) {
		case_ast_node(id, ImportDecl, decl);
			HashKey key = hash_string(id->fullpath);
			Scope **found = map_get(&c->file_scopes, key);
			if (found == nullptr) continue;
			Scope *s = *found;
			if (!ptr_set_exists(&c->checked_files, s->file)) {
				new_files = true;
				ptr_set_add(&c->checked_files, s->file);
			}
		case_end;

		case_ast_node(ed, ExportDecl, decl);
			HashKey key = hash_string(ed->fullpath);
			Scope **found = map_get(&c->file_scopes, key);
			if (found == nullptr) continue;
			Scope *s = *found;
			if (!ptr_set_exists(&c->checked_files, s->file)) {
				new_files = true;
				ptr_set_add(&c->checked_files, s->file);
			}
		case_end;
		}
	}
	return new_files;
}


bool collect_checked_files_from_when_stmt(Checker *c, AstNodeWhenStmt *ws) {
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
			return collect_checked_files_from_import_decl_list(c, ws->body->BlockStmt.stmts);
		} else if (ws->else_stmt) {
			switch (ws->else_stmt->kind) {
			case AstNode_BlockStmt:
				return collect_checked_files_from_import_decl_list(c, ws->else_stmt->BlockStmt.stmts);
			case AstNode_WhenStmt:
				return collect_checked_files_from_when_stmt(c, &ws->else_stmt->WhenStmt);
			default:
				error(ws->else_stmt, "Invalid 'else' statement in 'when' statement");
				break;
			}
		}
	}

	return false;
}

void check_delayed_file_import_entity(Checker *c, AstNode *decl) {
	Scope *parent_scope = c->context.scope;
	GB_ASSERT(parent_scope->is_file);

	switch (decl->kind) {
	case_ast_node(ws, WhenStmt, decl);
		check_collect_entities_from_when_stmt(c, ws);
	case_end;

	case_ast_node(id, ImportDecl, decl);
		check_add_import_decl(c, id);
	case_end;

	case_ast_node(ed, ExportDecl, decl);
		check_add_export_decl(c, ed);
	case_end;

	case_ast_node(fl, ForeignImportDecl, decl);
		check_add_foreign_import_decl(c, decl);
	case_end;
	}
}


// NOTE(bill): Returns true if a new file is present
bool collect_file_decls(Checker *c, Array<AstNode *> decls);
bool collect_file_decls_from_when_stmt(Checker *c, AstNodeWhenStmt *ws);

bool collect_file_decls_from_when_stmt(Checker *c, AstNodeWhenStmt *ws) {
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
			return collect_file_decls(c, ws->body->BlockStmt.stmts);
		} else if (ws->else_stmt) {
			switch (ws->else_stmt->kind) {
			case AstNode_BlockStmt:
				return collect_file_decls(c, ws->else_stmt->BlockStmt.stmts);
			case AstNode_WhenStmt:
				return collect_file_decls_from_when_stmt(c, &ws->else_stmt->WhenStmt);
			default:
				error(ws->else_stmt, "Invalid 'else' statement in 'when' statement");
				break;
			}
		}
	}

	return false;
}

bool collect_file_decls(Checker *c, Array<AstNode *> decls) {
	Scope *parent_scope = c->context.scope;
	GB_ASSERT(parent_scope->is_file);

	if (collect_checked_files_from_import_decl_list(c, decls)) {
		return true;
	}

	for_array(i, decls) {
		AstNode *decl = decls[i];
		switch (decl->kind) {
		case_ast_node(vd, ValueDecl, decl);
			check_collect_value_decl(c, decl);
		case_end;

		case_ast_node(id, ImportDecl, decl);
			check_add_import_decl(c, id);
		case_end;

		case_ast_node(ed, ExportDecl, decl);
			check_add_export_decl(c, ed);
		case_end;

		case_ast_node(fl, ForeignImportDecl, decl);
			check_add_foreign_import_decl(c, decl);
		case_end;

		case_ast_node(fb, ForeignBlockDecl, decl);
			check_add_foreign_block_decl(c, decl);
		case_end;

		case_ast_node(ws, WhenStmt, decl);
			if (!ws->is_cond_determined) {
				if (collect_checked_files_from_when_stmt(c, ws)) {
					return true;
				}

				CheckerContext prev_context = c->context;
				defer (c->context = prev_context);
				c->context.collect_delayed_decls = true;

				if (collect_file_decls_from_when_stmt(c, ws)) {
					return true;
				}
			} else {

				CheckerContext prev_context = c->context;
				defer (c->context = prev_context);
				c->context.collect_delayed_decls = true;

				if (collect_file_decls_from_when_stmt(c, ws)) {
					return true;
				}
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

	PtrSet<Scope *> emitted = {};
	ptr_set_init(&emitted, heap_allocator());
	defer (ptr_set_destroy(&emitted));

	while (pq.queue.count > 0) {
		ImportGraphNode *n = priority_queue_pop(&pq);

		Scope *s = n->scope;

		if (n->dep_count > 0) {
			PtrSet<Scope *> visited = {};
			ptr_set_init(&visited, heap_allocator());
			defer (ptr_set_destroy(&visited));

			auto path = find_import_path(c, s, s, &visited);
			defer (array_free(&path));

			// TODO(bill): This needs better TokenPos finding
			auto const fn = [](ImportPathItem item) -> String {
				Scope *s = item.scope;
				return remove_directory_from_path(s->file->tokenizer.fullpath);
			};

			if (path.count == 1) {
				// TODO(bill): Should this be allowed or disabled?
			#if 0
				ImportPathItem item = path[0];
				String filename = fn(item);
				error(item.decl, "Self importation of '%.*s'", LIT(filename));
			#endif
			} else if (path.count > 0) {
				ImportPathItem item = path[path.count-1];
				String filename = fn(item);
				error(item.decl, "Cyclic importation of '%.*s'", LIT(filename));
				for (isize i = 0; i < path.count; i++) {
					error(item.decl, "'%.*s' refers to", LIT(filename));
					item = path[i];
					filename = fn(item);
				}
				error(item.decl, "'%.*s'", LIT(filename));
			}
		}

		for_array(i, n->pred.entries) {
			ImportGraphNode *p = n->pred.entries[i].ptr;
			p->dep_count = gb_max(p->dep_count-1, 0);
			// p->dep_count -= 1;
			priority_queue_fix(&pq, p->index);
		}

		if (s == nullptr) {
			continue;
		}
		if (ptr_set_exists(&emitted, s)) {
			continue;
		}
		ptr_set_add(&emitted, s);

		array_add(&c->file_order, n);
	}

	for_array(file_index, c->parser->files) {
		AstFile *f = c->parser->files[file_index];
		Scope *s = f->scope;
		if (s->is_init || s->is_global) {
			ptr_set_add(&c->checked_files, f);
		}
	}

	// for_array(file_index, c->file_order) {
	// 	ImportGraphNode *node = c->file_order[file_index];
	// 	AstFile *f = node->scope->file;
	// 	gb_printf_err("---   %.*s -> %td\n", LIT(f->fullpath), node->succ.entries.count);
	// }

	for (;;) {
		bool new_files = false;
		for_array(file_index, c->file_order) {
			ImportGraphNode *node = c->file_order[file_index];
			AstFile *f = node->scope->file;

			if (!ptr_set_exists(&c->checked_files, f)) {
				continue;
			}

			CheckerContext prev_context = c->context;
			defer (c->context = prev_context);
			add_curr_ast_file(c, f);

			new_files |= collect_checked_files_from_import_decl_list(c, f->decls);
		}
		if (new_files) break;
	}

	for (isize file_index = 0; file_index < c->file_order.count; file_index += 1) {
		ImportGraphNode *node = c->file_order[file_index];
		AstFile *f = node->scope->file;

		if (!ptr_set_exists(&c->checked_files, f)) {
			continue;
		}

		CheckerContext prev_context = c->context;
		defer (c->context = prev_context);
		c->context.collect_delayed_decls = true;
		add_curr_ast_file(c, f);

		bool new_files = collect_file_decls(c, f->decls);
		if (new_files) {
			// TODO(bill): Only start from the lowest new file
			file_index = -1;
			continue;
		}
	}

	// gb_printf_err("End here!\n");
	// gb_exit(1);
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
				Array<Entity *> path = {};
				array_init(&path, heap_allocator());
				array_add(&path, dep);
				return path;
			}
			Array<Entity *> next_path = find_entity_path(dep, end, visited);
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
			p->dep_count -= 1;
			priority_queue_fix(&pq, p->index);
		}

		if (e == nullptr || e->kind != Entity_Variable) {
			continue;
		}
		DeclInfo *d = decl_info_of_entity(info, e);

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

	add_type_info_type(c, t_invalid);

	// Map full filepaths to Scopes
	for_array(i, c->parser->files) {
		AstFile *f = c->parser->files[i];
		Scope *scope = create_scope_from_file(c, f);
		f->decl_info = make_declaration_info(c->allocator, f->scope, c->context.decl);
		HashKey key = hash_string(f->tokenizer.fullpath);
		map_set(&c->file_scopes, key, scope);
		map_set(&c->info.files, key, f);

		if (scope->is_init) {
			c->info.init_scope = scope;
		}
	}

	TIME_SECTION("collect entities");
	// Collect Entities
	for_array(i, c->parser->files) {
		AstFile *f = c->parser->files[i];
		CheckerContext prev_context = c->context;
		add_curr_ast_file(c, f);
		check_collect_entities(c, f->decls);
		c->context = prev_context;
	}

	TIME_SECTION("import entities");
	check_import_entities(c);

	TIME_SECTION("check all global entities");
	check_all_global_entities(c);

	TIME_SECTION("init preload");
	init_preload(c); // NOTE(bill): This could be setup previously through the use of 'type_info_of'

	TIME_SECTION("check procedure bodies");
	// Check procedure bodies
	// NOTE(bill): Nested procedures bodies will be added to this "queue"
	for_array(i, c->procs) {
		ProcedureInfo *pi = &c->procs[i];
		if (pi->type == nullptr) {
			continue;
		}
		CheckerContext prev_context = c->context;
		defer (c->context = prev_context);

		TypeProc *pt = &pi->type->Proc;
		String name = pi->token.string;
		if (pt->is_polymorphic) {
			GB_ASSERT_MSG(pt->is_poly_specialized, "%.*s", LIT(name));
		}

		add_curr_ast_file(c, pi->file);

		bool bounds_check    = (pi->tags & ProcTag_bounds_check)    != 0;
		bool no_bounds_check = (pi->tags & ProcTag_no_bounds_check) != 0;

		if (bounds_check) {
			c->context.stmt_state_flags |= StmtStateFlag_bounds_check;
			c->context.stmt_state_flags &= ~StmtStateFlag_no_bounds_check;
		} else if (no_bounds_check) {
			c->context.stmt_state_flags |= StmtStateFlag_no_bounds_check;
			c->context.stmt_state_flags &= ~StmtStateFlag_bounds_check;
		}

		check_proc_body(c, pi->token, pi->decl, pi->type, pi->body);
	}

	TIME_SECTION("generate minimum dependency set");
	c->info.minimum_dependency_set = generate_minimum_dependency_set(&c->info, c->info.entry_point);


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
	for (isize i = 0; i < gb_count_of(basic_types)-1; i++) {
		Type *t = &basic_types[i];
		if (t->Basic.size > 0 && t->Basic.kind != Basic_llvm_bool)  {
			add_type_info_type(c, t);
		}
	}

	// NOTE(bill): Check for illegal cyclic type declarations
	for_array(i, c->info.definitions) {
		Entity *e = c->info.definitions[i];
		if (e->kind == Entity_TypeName && e->type != nullptr) {
			// i64 size  = type_size_of(c->allocator, e->type);
			i64 align = type_align_of(c->allocator, e->type);
			if (align > 0) {
				add_type_info_type(c, e->type);
			}
		}
	}

	TIME_SECTION("check entry poiny");
	if (!build_context.is_dll) {
		Scope *s = c->info.init_scope;
		GB_ASSERT(s != nullptr);
		GB_ASSERT(s->is_init);
		Entity *e = current_scope_lookup_entity(s, str_lit("main"));
		if (e == nullptr) {
			Token token = {};
			if (s->file->tokens.count > 0) {
				token = s->file->tokens[0];
			} else {
				token.pos.file   = s->file->tokenizer.fullpath;
				token.pos.line   = 1;
				token.pos.column = 1;
			}

			error(token, "Undefined entry point procedure 'main'");
		}
	}

#undef TIME_SECTION
}
