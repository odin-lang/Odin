#include "../exact_value.cpp"
#include "entity.cpp"
#include "type.cpp"

enum AddressingMode {
	Addressing_Invalid,

	Addressing_NoValue,
	Addressing_Value,
	Addressing_Variable,
	Addressing_Constant,
	Addressing_Type,
	Addressing_Builtin,

	Addressing_Count,
};

struct Operand {
	AddressingMode mode;
	Type *type;
	ExactValue value;
	AstNode *expr;
	BuiltinProcId builtin_id;
};

struct TypeAndValue {
	AddressingMode mode;
	Type *type;
	ExactValue value;
};

struct DeclInfo {
	Scope *scope;

	Entity **entities;
	isize entity_count;

	AstNode *type_expr;
	AstNode *init_expr;
	AstNode *proc_decl; // AstNode_ProcedureDeclaration

	Map<b32> deps; // Key: Entity *
	i32 mark;
};


void init_declaration_info(DeclInfo *d, Scope *scope) {
	d->scope = scope;
	map_init(&d->deps, gb_heap_allocator());
}

DeclInfo *make_declaration_info(gbAllocator a, Scope *scope) {
	DeclInfo *d = gb_alloc_item(a, DeclInfo);
	init_declaration_info(d, scope);
	return d;
}

void destroy_declaration_info(DeclInfo *d) {
	map_destroy(&d->deps);
}

b32 has_init(DeclInfo *d) {
	if (d->init_expr != NULL)
		return true;
	if (d->proc_decl != NULL) {
		ast_node(pd, ProcDecl, d->proc_decl);
		if (pd->body != NULL)
			return true;
	}

	return false;
}


struct ExpressionInfo {
	b32 is_lhs; // Debug info
	AddressingMode mode;
	Type *type; // Type_Basic
	ExactValue value;
};

ExpressionInfo make_expression_info(b32 is_lhs, AddressingMode mode, Type *type, ExactValue value) {
	ExpressionInfo ei = {};
	ei.is_lhs = is_lhs;
	ei.mode   = mode;
	ei.type   = type;
	ei.value  = value;
	return ei;
}

struct ProcedureInfo {
	AstFile *file;
	Token            token;
	DeclInfo *decl;
	Type *           type; // Type_Procedure
	AstNode *        body; // AstNode_BlockStatement
};

struct Scope {
	Scope *parent;
	Scope *prev, *next;
	Scope *first_child, *last_child;
	Map<Entity *> elements; // Key: String
	gbArray(AstNode *) deferred_stmts;
};

enum ExpressionKind {
	Expression_Expression,
	Expression_Conversion,
	Expression_Statement,
};

enum BuiltinProcId {
	BuiltinProc_Invalid,

	BuiltinProc_size_of,
	BuiltinProc_size_of_val,
	BuiltinProc_align_of,
	BuiltinProc_align_of_val,
	BuiltinProc_offset_of,
	BuiltinProc_offset_of_val,
	BuiltinProc_static_assert,
	BuiltinProc_len,
	BuiltinProc_cap,
	BuiltinProc_copy,
	BuiltinProc_append,
	BuiltinProc_print,
	BuiltinProc_println,

	BuiltinProc_Count,
};
struct BuiltinProc {
	String name;
	isize arg_count;
	b32 variadic;
	ExpressionKind kind;
};
gb_global BuiltinProc builtin_procs[BuiltinProc_Count] = {
	{STR_LIT(""),                 0, false, Expression_Statement},

	{STR_LIT("size_of"),          1, false, Expression_Expression},
	{STR_LIT("size_of_val"),      1, false, Expression_Expression},
	{STR_LIT("align_of"),         1, false, Expression_Expression},
	{STR_LIT("align_of_val"),     1, false, Expression_Expression},
	{STR_LIT("offset_of"),        2, false, Expression_Expression},
	{STR_LIT("offset_of_val"),    1, false, Expression_Expression},
	{STR_LIT("static_assert"),    1, false, Expression_Statement},

	{STR_LIT("len"),              1, false, Expression_Expression},
	{STR_LIT("cap"),              1, false, Expression_Expression},
	{STR_LIT("copy"),             2, false, Expression_Expression},
	{STR_LIT("append"),           2, false, Expression_Expression},
	{STR_LIT("print"),            1, true,  Expression_Statement},
	{STR_LIT("println"),          1, true,  Expression_Statement},
};

struct CheckerContext {
	Scope *scope;
	DeclInfo *decl;
};

// NOTE(bill): Symbol tables
struct CheckerInfo {
	Map<TypeAndValue>      types;       // Key: AstNode * | Expression -> Type (and value)
	Map<Entity *>          definitions; // Key: AstNode * | Identifier -> Entity
	Map<Entity *>          uses;        // Key: AstNode * | Identifier -> Entity
	Map<Scope *>           scopes;      // Key: AstNode * | Node       -> Scope
	Map<ExpressionInfo>    untyped;     // Key: AstNode * | Expression -> ExpressionInfo
	Map<DeclInfo *>        entities;    // Key: Entity *
};

struct Checker {
	Parser *    parser;
	CheckerInfo info;

	AstFile *              curr_ast_file;
	BaseTypeSizes          sizes;
	Scope *                global_scope;
	gbArray(ProcedureInfo) procs; // NOTE(bill): Procedures to check

	gbArena     arena;
	gbAllocator allocator;

	CheckerContext context;

	gbArray(Type *) proc_stack;
	b32 in_defer; // TODO(bill): Actually handle correctly

	ErrorCollector error_collector;
};

gb_global Scope *universal_scope = NULL;


Scope *make_scope(Scope *parent, gbAllocator allocator) {
	Scope *s = gb_alloc_item(allocator, Scope);
	s->parent = parent;
	map_init(&s->elements, gb_heap_allocator());
	gb_array_init(s->deferred_stmts, gb_heap_allocator());
	if (parent != NULL && parent != universal_scope) {
		DLIST_APPEND(parent->first_child, parent->last_child, s);
	}
	return s;
}

void destroy_scope(Scope *scope) {
	gb_for_array(i, scope->elements.entries) {
		Entity *e =scope->elements.entries[i].value;
		if (e->kind == Entity_Variable) {
			if (!e->variable.used) {
#if 0
				warning(e->token, "Unused variable `%.*s`", LIT(e->token.string));
#endif
			}
		}
	}

	for (Scope *child = scope->first_child; child != NULL; child = child->next) {
		destroy_scope(child);
	}

	map_destroy(&scope->elements);
	// NOTE(bill): No need to free scope as it "should" be allocated in an arena (except for the global scope)
}

void add_scope(Checker *c, AstNode *node, Scope *scope) {
	GB_ASSERT(node != NULL);
	GB_ASSERT(scope != NULL);
	map_set(&c->info.scopes, hash_pointer(node), scope);
}


void check_open_scope(Checker *c, AstNode *stmt) {
	GB_ASSERT(is_ast_node_stmt(stmt) || stmt->kind == AstNode_ProcType);
	Scope *scope = make_scope(c->context.scope, c->allocator);
	add_scope(c, stmt, scope);
	c->context.scope = scope;
}

void check_close_scope(Checker *c) {
	c->context.scope = c->context.scope->parent;
}

void scope_lookup_parent_entity(Scope *s, String name, Scope **scope, Entity **entity) {
	u64 key = hash_string(name);
	for (; s != NULL; s = s->parent) {
		Entity **found = map_get(&s->elements, key);
		if (found) {
			if (entity) *entity = *found;
			if (scope) *scope = s;
			return;
		}
	}
	if (entity) *entity = NULL;
	if (scope) *scope = NULL;
}

Entity *scope_lookup_entity(Scope *s, String name) {
	Entity *entity = NULL;
	scope_lookup_parent_entity(s, name, NULL, &entity);
	return entity;
}

Entity *current_scope_lookup_entity(Scope *s, String name) {
	u64 key = hash_string(name);
	Entity **found = map_get(&s->elements, key);
	if (found)
		return *found;
	return NULL;
}



Entity *scope_insert_entity(Scope *s, Entity *entity) {
	String name = entity->token.string;
	u64 key = hash_string(name);
	Entity **found = map_get(&s->elements, key);
	if (found)
		return *found;
	map_set(&s->elements, key, entity);
	if (entity->parent == NULL)
		entity->parent = s;
	return NULL;
}

void add_dependency(DeclInfo *d, Entity *e) {
	map_set(&d->deps, hash_pointer(e), cast(b32)true);
}

void add_declaration_dependency(Checker *c, Entity *e) {
	if (c->context.decl) {
		auto found = map_get(&c->info.entities, hash_pointer(e));
		if (found) {
			add_dependency(c->context.decl, e);
		}
	}
}


void add_global_entity(Entity *entity) {
	String name = entity->token.string;
	if (gb_memchr(name.text, ' ', name.len)) {
		return; // NOTE(bill): `untyped thing`
	}
	if (scope_insert_entity(universal_scope, entity)) {
		GB_PANIC("Compiler error: double declaration");
	}
}

void add_global_constant(gbAllocator a, String name, Type *type, ExactValue value) {
	Token token = {Token_Identifier};
	token.string = name;
	Entity *entity = alloc_entity(a, Entity_Constant, NULL, token, type);
	entity->constant.value = value;
	add_global_entity(entity);
}

void init_universal_scope(void) {
	// NOTE(bill): No need to free these
	gbAllocator a = gb_heap_allocator();
	universal_scope = make_scope(NULL, a);

// Types
	for (isize i = 0; i < gb_count_of(basic_types); i++) {
		Token token = {Token_Identifier};
		token.string = basic_types[i].basic.name;
		add_global_entity(make_entity_type_name(a, NULL, token, &basic_types[i]));
	}
	for (isize i = 0; i < gb_count_of(basic_type_aliases); i++) {
		Token token = {Token_Identifier};
		token.string = basic_type_aliases[i].basic.name;
		add_global_entity(make_entity_type_name(a, NULL, token, &basic_type_aliases[i]));
	}

// Constants
	add_global_constant(a, make_string("true"),  t_untyped_bool,    make_exact_value_bool(true));
	add_global_constant(a, make_string("false"), t_untyped_bool,    make_exact_value_bool(false));
	add_global_constant(a, make_string("null"),  t_untyped_pointer, make_exact_value_pointer(NULL));

// Builtin Procedures
	for (isize i = 0; i < gb_count_of(builtin_procs); i++) {
		BuiltinProcId id = cast(BuiltinProcId)i;
		Token token = {Token_Identifier};
		token.string = builtin_procs[i].name;
		Entity *entity = alloc_entity(a, Entity_Builtin, NULL, token, t_invalid);
		entity->builtin.id = id;
		add_global_entity(entity);
	}
}




void init_checker_info(CheckerInfo *i) {
	gbAllocator a = gb_heap_allocator();
	map_init(&i->types,       a);
	map_init(&i->definitions, a);
	map_init(&i->uses,        a);
	map_init(&i->scopes,      a);
	map_init(&i->entities,    a);
	map_init(&i->untyped,     a);

}

void destroy_checker_info(CheckerInfo *i) {
	map_destroy(&i->types);
	map_destroy(&i->definitions);
	map_destroy(&i->uses);
	map_destroy(&i->scopes);
	map_destroy(&i->entities);
	map_destroy(&i->untyped);
}


void init_checker(Checker *c, Parser *parser) {
	gbAllocator a = gb_heap_allocator();

	c->parser = parser;
	init_checker_info(&c->info);
	c->sizes.word_size = 8;
	c->sizes.max_align = 8;

	gb_array_init(c->proc_stack, a);
	gb_array_init(c->procs, a);

	// NOTE(bill): Is this big enough or too small?
	isize item_size = gb_max(gb_max(gb_size_of(Entity), gb_size_of(Type)), gb_size_of(Scope));
	isize total_token_count = 0;
	gb_for_array(i, c->parser->files) {
		AstFile *f = &c->parser->files[i];
		total_token_count += gb_array_count(f->tokens);
	}
	isize arena_size = 2 * item_size * total_token_count;
	gb_arena_init_from_allocator(&c->arena, a, arena_size);
	c->allocator = gb_arena_allocator(&c->arena);

	c->global_scope = make_scope(universal_scope, c->allocator);
	c->context.scope = c->global_scope;
}

void destroy_checker(Checker *c) {
	destroy_checker_info(&c->info);
	destroy_scope(c->global_scope);
	gb_array_free(c->proc_stack);
	gb_array_free(c->procs);

	gb_arena_free(&c->arena);
}


TypeAndValue *type_and_value_of_expression(CheckerInfo *i, AstNode *expression) {
	TypeAndValue *found = map_get(&i->types, hash_pointer(expression));
	return found;
}


Entity *entity_of_ident(CheckerInfo *i, AstNode *identifier) {
	GB_ASSERT(identifier->kind == AstNode_Ident);
	Entity **found = map_get(&i->definitions, hash_pointer(identifier));
	if (found)
		return *found;

	found = map_get(&i->uses, hash_pointer(identifier));
	if (found)
		return *found;
	return NULL;
}

Type *type_of_expr(CheckerInfo *i, AstNode *expression) {
	TypeAndValue *found = type_and_value_of_expression(i, expression);
	if (found)
		return found->type;
	if (expression->kind == AstNode_Ident) {
		Entity *entity = entity_of_ident(i, expression);
		if (entity)
			return entity->type;
	}

	return NULL;
}


void add_untyped(CheckerInfo *i, AstNode *expression, b32 lhs, AddressingMode mode, Type *basic_type, ExactValue value) {
	map_set(&i->untyped, hash_pointer(expression), make_expression_info(lhs, mode, basic_type, value));
}


void add_type_and_value(CheckerInfo *i, AstNode *expression, AddressingMode mode, Type *type, ExactValue value) {
	GB_ASSERT(expression != NULL);
	if (mode == Addressing_Invalid)
		return;

	if (mode == Addressing_Constant) {
		GB_ASSERT(value.kind != ExactValue_Invalid);
		GB_ASSERT(type == t_invalid || is_type_constant_type(type));
	}

	TypeAndValue tv = {};
	tv.type  = type;
	tv.value = value;
	tv.mode  = mode;
	map_set(&i->types, hash_pointer(expression), tv);
}

void add_entity_definition(CheckerInfo *i, AstNode *identifier, Entity *entity) {
	GB_ASSERT(identifier != NULL);
	GB_ASSERT(identifier->kind == AstNode_Ident);
	u64 key = hash_pointer(identifier);
	map_set(&i->definitions, key, entity);
}

void add_entity(Checker *c, Scope *scope, AstNode *identifier, Entity *entity) {
	if (!are_strings_equal(entity->token.string, make_string("_"))) {
		Entity *insert_entity = scope_insert_entity(scope, entity);
		if (insert_entity) {
			error(&c->error_collector, entity->token, "Redeclared entity in this scope: %.*s", LIT(entity->token.string));
			return;
		}
	}
	if (identifier != NULL)
		add_entity_definition(&c->info, identifier, entity);
}

void add_entity_use(CheckerInfo *i, AstNode *identifier, Entity *entity) {
	GB_ASSERT(identifier != NULL);
	GB_ASSERT(identifier->kind == AstNode_Ident);
	u64 key = hash_pointer(identifier);
	map_set(&i->uses, key, entity);
}


void add_file_entity(Checker *c, AstNode *identifier, Entity *e, DeclInfo *d) {
	GB_ASSERT(are_strings_equal(identifier->Ident.token.string, e->token.string));

	add_entity(c, c->global_scope, identifier, e);
	map_set(&c->info.entities, hash_pointer(e), d);
	e->order = gb_array_count(c->info.entities.entries);
}


void check_procedure_later(Checker *c, AstFile *file, Token token, DeclInfo *decl, Type *type, AstNode *body) {
	ProcedureInfo info = {};
	info.file = file;
	info.token = token;
	info.decl  = decl;
	info.type  = type;
	info.body  = body;
	gb_array_append(c->procs, info);
}

void check_add_deferred_stmt(Checker *c, AstNode *stmt) {
	GB_ASSERT(stmt != NULL);
	GB_ASSERT(is_ast_node_stmt(stmt));
	gb_array_append(c->context.scope->deferred_stmts, stmt);
}

void push_procedure(Checker *c, Type *type) {
	gb_array_append(c->proc_stack, type);
}

void pop_procedure(Checker *c) {
	gb_array_pop(c->proc_stack);
}

void add_curr_ast_file(Checker *c, AstFile *file) {
	TokenPos zero_pos = {};
	c->error_collector.prev = zero_pos;
	c->curr_ast_file = file;
}





#include "expr.cpp"
#include "stmt.cpp"




void check_parsed_files(Checker *c) {
	// Collect Entities
	gb_for_array(i, c->parser->files) {
		AstFile *f = &c->parser->files[i];
		add_curr_ast_file(c, f);
		for (AstNode *decl = f->decls; decl != NULL; decl = decl->next) {
			if (!is_ast_node_decl(decl))
				continue;

			switch (decl->kind) {
			case_ast_node(bd, BadDecl, decl);
			case_end;

			case_ast_node(vd, VarDecl, decl);
				switch (vd->kind) {
				case Declaration_Immutable: {
					for (AstNode *name = vd->name_list, *value = vd->value_list;
					     name != NULL && value != NULL;
					     name = name->next, value = value->next) {
						ast_node(n, Ident, name);
						ExactValue v = {ExactValue_Invalid};
						Entity *e = make_entity_constant(c->allocator, c->context.scope, n->token, NULL, v);
						DeclInfo *di = make_declaration_info(c->allocator, c->global_scope);
						di->type_expr = vd->type;
						di->init_expr = value;
						add_file_entity(c, name, e, di);
					}

					isize lhs_count = vd->name_count;
					isize rhs_count = vd->value_count;

					if (rhs_count == 0 && vd->type == NULL) {
						error(&c->error_collector, ast_node_token(decl), "Missing type or initial expression");
					} else if (lhs_count < rhs_count) {
						error(&c->error_collector, ast_node_token(decl), "Extra initial expression");
					}
				} break;

				case Declaration_Mutable: {
					isize entity_count = vd->name_count;
					isize entity_index = 0;
					Entity **entities = gb_alloc_array(c->allocator, Entity *, entity_count);
					DeclInfo *di = NULL;
					if (vd->value_count == 1) {
						di = make_declaration_info(gb_heap_allocator(), c->global_scope);
						di->entities = entities;
						di->entity_count = entity_count;
						di->type_expr = vd->type;
						di->init_expr = vd->value_list;
					}

					AstNode *value = vd->value_list;
					for (AstNode *name = vd->name_list; name != NULL; name = name->next) {
						ast_node(n, Ident, name);
						Entity *e = make_entity_variable(c->allocator, c->global_scope, n->token, NULL);
						entities[entity_index++] = e;

						DeclInfo *d = di;
						if (d == NULL) {
							AstNode *init_expr = value;
							d = make_declaration_info(gb_heap_allocator(), c->global_scope);
							d->type_expr = vd->type;
							d->init_expr = init_expr;
						}

						add_file_entity(c, name, e, d);

						if (value != NULL)
							value = value->next;
					}
				} break;
				}
			case_end;

			case_ast_node(td, TypeDecl, decl);
				ast_node(n, Ident, td->name);
				Entity *e = make_entity_type_name(c->allocator, c->global_scope, n->token, NULL);
				DeclInfo *d = make_declaration_info(c->allocator, e->parent);
				d->type_expr = td->type;
				add_file_entity(c, td->name, e, d);
			case_end;

			case_ast_node(ad, AliasDecl, decl);
				ast_node(n, Ident, ad->name);
				Entity *e = make_entity_alias_name(c->allocator, c->global_scope, n->token, NULL);
				DeclInfo *d = make_declaration_info(c->allocator, e->parent);
				d->type_expr = ad->type;
				add_file_entity(c, ad->name, e, d);
			case_end;

			case_ast_node(pd, ProcDecl, decl);
				ast_node(n, Ident, pd->name);
				Token token = n->token;
				Entity *e = make_entity_procedure(c->allocator, c->global_scope, token, NULL);
				add_entity(c, c->global_scope, pd->name, e);
				DeclInfo *d = make_declaration_info(c->allocator, e->parent);
				d->proc_decl = decl;
				map_set(&c->info.entities, hash_pointer(e), d);
				e->order = gb_array_count(c->info.entities.entries);

			case_end;

			case_ast_node(id, ImportDecl, decl);
				// NOTE(bill): ignore
			case_end;

			default:
				error(&c->error_collector, ast_node_token(decl), "Only declarations are allowed at file scope");
				break;
			}
		}
	}


	gb_for_array(i, c->info.entities.entries) {
		auto *entry = &c->info.entities.entries[i];
		Entity *e = cast(Entity *)cast(uintptr)entry->key;
		DeclInfo *d = entry->value;
		check_entity_decl(c, e, d, NULL);
	}


	// Check procedure bodies
	gb_for_array(i, c->procs) {
		ProcedureInfo *pi = &c->procs[i];
		add_curr_ast_file(c, pi->file);
		check_proc_body(c, pi->token, pi->decl, pi->type, pi->body);
	}


	// Add untyped expression values
	gb_for_array(i, c->info.untyped.entries) {
		auto *entry = c->info.untyped.entries + i;
		u64 key = entry->key;
		AstNode *expr = cast(AstNode *)cast(uintptr)key;
		ExpressionInfo *info = &entry->value;
		if (info != NULL && expr != NULL) {
			if (is_type_typed(info->type)) {
				GB_PANIC("%s (type %s) is typed!", expr_to_string(expr), info->type);
			}
			add_type_and_value(&c->info, expr, info->mode, info->type, info->value);
		}
	}
}



