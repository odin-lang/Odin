#include "../exact_value.cpp"
#include "entity.cpp"
#include "type.cpp"

#define ADDRESSING_KINDS \
	ADDRESSING_MODE(Invalid), \
	ADDRESSING_MODE(NoValue), \
	ADDRESSING_MODE(Value), \
	ADDRESSING_MODE(Variable), \
	ADDRESSING_MODE(Constant), \
	ADDRESSING_MODE(Type), \
	ADDRESSING_MODE(Builtin), \
	ADDRESSING_MODE(Count), \

enum AddressingMode {
#define ADDRESSING_MODE(x) GB_JOIN2(Addressing_, x)
	ADDRESSING_KINDS
#undef ADDRESSING_MODE
};

String const addressing_mode_strings[] = {
#define ADDRESSING_MODE(x) {cast(u8 *)#x, gb_size_of(#x)-1}
	ADDRESSING_KINDS
#undef ADDRESSING_MODE
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
	AstNode *proc_decl; // AstNode_ProcDecl
	u32 var_decl_tags;

	Map<b32> deps; // Key: Entity *
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
	AstFile * file;
	Token     token;
	DeclInfo *decl;
	Type *    type; // Type_Procedure
	AstNode * body; // AstNode_BlockStatement
};

struct Scope {
	b32 is_proc;
	Scope *parent;
	Scope *prev, *next;
	Scope *first_child, *last_child;
	Map<Entity *> elements; // Key: String
};

enum ExprKind {
	Expr_Expr,
	Expr_Stmt,
};

enum BuiltinProcId {
	BuiltinProc_Invalid,

	BuiltinProc_new,
	BuiltinProc_new_slice,
	BuiltinProc_delete,

	BuiltinProc_size_of,
	BuiltinProc_size_of_val,
	BuiltinProc_align_of,
	BuiltinProc_align_of_val,
	BuiltinProc_offset_of,
	BuiltinProc_offset_of_val,
	BuiltinProc_type_of_val,
	BuiltinProc_assert,

	BuiltinProc_len,
	BuiltinProc_cap,
	BuiltinProc_copy,
	BuiltinProc_append,

	BuiltinProc_swizzle,

	BuiltinProc_ptr_offset,
	BuiltinProc_ptr_sub,
	BuiltinProc_slice_ptr,

	BuiltinProc_min,
	BuiltinProc_max,
	BuiltinProc_abs,

	BuiltinProc_Count,
};
struct BuiltinProc {
	String name;
	isize arg_count;
	b32 variadic;
	ExprKind kind;
};
gb_global BuiltinProc builtin_procs[BuiltinProc_Count] = {
	{STR_LIT(""),                 0, false, Expr_Stmt},

	{STR_LIT("new"),              1, false, Expr_Expr},
	{STR_LIT("new_slice"),        2, true,  Expr_Expr},
	{STR_LIT("delete"),           1, false, Expr_Stmt},

	{STR_LIT("size_of"),          1, false, Expr_Expr},
	{STR_LIT("size_of_val"),      1, false, Expr_Expr},
	{STR_LIT("align_of"),         1, false, Expr_Expr},
	{STR_LIT("align_of_val"),     1, false, Expr_Expr},
	{STR_LIT("offset_of"),        2, false, Expr_Expr},
	{STR_LIT("offset_of_val"),    1, false, Expr_Expr},
	{STR_LIT("type_of_val"),      1, false, Expr_Expr},
	{STR_LIT("assert"),           1, false, Expr_Stmt},

	{STR_LIT("len"),              1, false, Expr_Expr},
	{STR_LIT("cap"),              1, false, Expr_Expr},
	{STR_LIT("copy"),             2, false, Expr_Expr},
	{STR_LIT("append"),           2, false, Expr_Expr},

	{STR_LIT("swizzle"),          1, true,  Expr_Expr},

	{STR_LIT("ptr_offset"),       2, false, Expr_Expr},
	{STR_LIT("ptr_sub"),          2, false, Expr_Expr},
	{STR_LIT("slice_ptr"),        2, true,  Expr_Expr},

	{STR_LIT("min"),              2, false, Expr_Expr},
	{STR_LIT("max"),              2, false, Expr_Expr},
	{STR_LIT("abs"),              1, false, Expr_Expr},
};

struct CheckerContext {
	Scope *scope;
	DeclInfo *decl;
};

// NOTE(bill): Symbol tables
struct CheckerInfo {
	Map<TypeAndValue>      types;         // Key: AstNode * | Expression -> Type (and value)
	Map<Entity *>          definitions;   // Key: AstNode * | Identifier -> Entity
	Map<Entity *>          uses;          // Key: AstNode * | Identifier -> Entity
	Map<Scope *>           scopes;        // Key: AstNode * | Node       -> Scope
	Map<ExpressionInfo>    untyped;       // Key: AstNode * | Expression -> ExpressionInfo
	Map<DeclInfo *>        entities;      // Key: Entity *
	Map<Entity *>          foreign_procs; // Key: String
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

struct CycleChecker {
	gbArray(Entity *) path; // Entity_TypeName
};

CycleChecker *cycle_checker_add(CycleChecker *cc, Entity *e) {
	GB_ASSERT(cc != NULL);
	if (cc->path == NULL) {
		gb_array_init(cc->path, gb_heap_allocator());
	}
	GB_ASSERT(e != NULL && e->kind == Entity_TypeName);
	gb_array_append(cc->path, e);
	return cc;
}



Scope *make_scope(Scope *parent, gbAllocator allocator) {
	Scope *s = gb_alloc_item(allocator, Scope);
	s->parent = parent;
	map_init(&s->elements, gb_heap_allocator());
	if (parent != NULL && parent != universal_scope) {
		DLIST_APPEND(parent->first_child, parent->last_child, s);
	}
	return s;
}

void destroy_scope(Scope *scope) {
	gb_for_array(i, scope->elements.entries) {
		Entity *e =scope->elements.entries[i].value;
		if (e->kind == Entity_Variable) {
			if (!e->Variable.used) {
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
	GB_ASSERT(is_ast_node_stmt(stmt) || is_ast_node_type(stmt));
	Scope *scope = make_scope(c->context.scope, c->allocator);
	add_scope(c, stmt, scope);
	if (stmt->kind == AstNode_ProcType) {
		scope->is_proc = true;
	}
	c->context.scope = scope;
}

void check_close_scope(Checker *c) {
	c->context.scope = c->context.scope->parent;
}

void scope_lookup_parent_entity(Checker *c, Scope *s, String name, Scope **scope, Entity **entity) {
	b32 gone_thru_proc = false;
	HashKey key = hash_string(name);
	for (; s != NULL; s = s->parent) {

		Entity **found = map_get(&s->elements, key);
		if (found) {
			Entity *e = *found;
			if (gone_thru_proc) {
				if (e->kind == Entity_Variable && e->scope != c->global_scope) {
					continue;
				}
			}

			if (entity) *entity = e;
			if (scope) *scope = s;
			return;
		}

		if (s->is_proc) {
			gone_thru_proc = true;
		}
	}
	if (entity) *entity = NULL;
	if (scope) *scope = NULL;
}

Entity *scope_lookup_entity(Checker *c, Scope *s, String name) {
	Entity *entity = NULL;
	scope_lookup_parent_entity(c, s, name, NULL, &entity);
	return entity;
}

Entity *current_scope_lookup_entity(Scope *s, String name) {
	HashKey key = hash_string(name);
	Entity **found = map_get(&s->elements, key);
	if (found)
		return *found;
	return NULL;
}



Entity *scope_insert_entity(Scope *s, Entity *entity) {
	String name = entity->token.string;
	HashKey key = hash_string(name);
	Entity **found = map_get(&s->elements, key);
	if (found)
		return *found;
	map_set(&s->elements, key, entity);
	if (entity->scope == NULL)
		entity->scope = s;
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
	entity->Constant.value = value;
	add_global_entity(entity);
}

void init_universal_scope(void) {
	// NOTE(bill): No need to free these
	gbAllocator a = gb_heap_allocator();
	universal_scope = make_scope(NULL, a);

// Types
	for (isize i = 0; i < gb_count_of(basic_types); i++) {
		Token token = {Token_Identifier};
		token.string = basic_types[i].Basic.name;
		add_global_entity(make_entity_type_name(a, NULL, token, &basic_types[i]));
	}
	for (isize i = 0; i < gb_count_of(basic_type_aliases); i++) {
		Token token = {Token_Identifier};
		token.string = basic_type_aliases[i].Basic.name;
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
		entity->Builtin.id = id;
		add_global_entity(entity);
	}

// Custom Runtime Types
	{
	}
}




void init_checker_info(CheckerInfo *i) {
	gbAllocator a = gb_heap_allocator();
	map_init(&i->types,         a);
	map_init(&i->definitions,   a);
	map_init(&i->uses,          a);
	map_init(&i->scopes,        a);
	map_init(&i->entities,      a);
	map_init(&i->untyped,       a);
	map_init(&i->foreign_procs, a);

}

void destroy_checker_info(CheckerInfo *i) {
	map_destroy(&i->types);
	map_destroy(&i->definitions);
	map_destroy(&i->uses);
	map_destroy(&i->scopes);
	map_destroy(&i->entities);
	map_destroy(&i->untyped);
	map_destroy(&i->foreign_procs);
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
		GB_ASSERT_MSG(type != t_invalid || is_type_constant_type(type),
		              "type: %s", type_to_string(type));
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
	HashKey key = hash_pointer(identifier);
	map_set(&i->definitions, key, entity);
}

b32 add_entity(Checker *c, Scope *scope, AstNode *identifier, Entity *entity) {
	if (!are_strings_equal(entity->token.string, make_string("_"))) {
		Entity *insert_entity = scope_insert_entity(scope, entity);
		if (insert_entity) {
			Entity *up = insert_entity->using_parent;
			if (up != NULL) {
				error(&c->error_collector, entity->token,
				      "Redeclararation of `%.*s` in this scope through `using`\n"
				      "\tat %.*s(%td:%td)",
				      LIT(entity->token.string),
				      LIT(up->token.pos.file), up->token.pos.line, up->token.pos.column);
				return false;
			} else {
				gb_printf_err("!!Here\n");
				error(&c->error_collector, entity->token,
				      "Redeclararation of `%.*s` in this scope\n"
				      "\tat %.*s(%td:%td)",
				      LIT(entity->token.string),
				      LIT(entity->token.pos.file), entity->token.pos.line, entity->token.pos.column);
				return false;
			}
		}
	}
	if (identifier != NULL)
		add_entity_definition(&c->info, identifier, entity);
	return true;
}


/*
b32 add_proc_entity(Checker *c, Scope *scope, AstNode *identifier, Entity *entity) {
	GB_ASSERT(entity->kind == Entity_Procedure);

	auto error_proc_redecl = [](Checker *c, Token token, Entity *other_entity, char *extra_msg) {
		error(&c->error_collector, token,
		      "Redeclararation of `%.*s` in this scope %s\n"
		      "\tat %.*s(%td:%td)",
		      LIT(other_entity->token.string),
		      extra_msg,
		      LIT(other_entity->token.pos.file), other_entity->token.pos.line, other_entity->token.pos.column);
	};

	String name = entity->token.string;
	HashKey key = hash_string(name);

	b32 insert_overload = false;

	if (!are_strings_equal(name, make_string("_"))) {
		Entity *insert_entity = scope_insert_entity(scope, entity);
		if (insert_entity != NULL) {
			if (insert_entity != entity) {
				isize count = multi_map_count(&scope->elements, key);
				GB_ASSERT(count > 0);
				Entity **entities = gb_alloc_array(gb_heap_allocator(), Entity *, count);
				defer (gb_free(gb_heap_allocator(), entities));
				multi_map_get_all(&scope->elements, key, entities);

				for (isize i = 0; i < count; i++) {
					Entity *e = entities[i];
					if (e == entity) {
						continue;
					}
					if (e->kind == Entity_Procedure) {
						Type *proc_type = entity->type;
						Type *other_proc_type = e->type;
						// gb_printf_err("%s == %s\n", type_to_string(proc_type), type_to_string(other_proc_type));
						if (are_types_identical(proc_type, other_proc_type)) {
							error_proc_redecl(c, entity->token, e, "with identical types");
							return false;
						}

						if (proc_type != NULL && other_proc_type != NULL) {
							Type *params = proc_type->Proc.params;
							Type *other_params = other_proc_type->Proc.params;

							if (are_types_identical(params, other_params)) {
								error_proc_redecl(c, entity->token, e, "with 2identical parameters");
								return false;
							}
						}
					} else {
						error_proc_redecl(c, entity->token, e, "");
						return false;
					}
				}
				insert_overload = true;
			}
		}
	}

	if (insert_overload) {
		multi_map_insert(&scope->elements, key, entity);
	}

	if (identifier != NULL)
		add_entity_definition(&c->info, identifier, entity);
	return true;
}
*/

void add_entity_use(CheckerInfo *i, AstNode *identifier, Entity *entity) {
	GB_ASSERT(identifier != NULL);
	GB_ASSERT(identifier->kind == AstNode_Ident);
	HashKey key = hash_pointer(identifier);
	map_set(&i->uses, key, entity);
}


void add_file_entity(Checker *c, AstNode *identifier, Entity *e, DeclInfo *d) {
	GB_ASSERT(are_strings_equal(identifier->Ident.string, e->token.string));

	add_entity(c, c->global_scope, identifier, e);
	map_set(&c->info.entities, hash_pointer(e), d);
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

void push_procedure(Checker *c, Type *type) {
	gb_array_append(c->proc_stack, type);
}

void pop_procedure(Checker *c) {
	gb_array_pop(c->proc_stack);
}

Type *const curr_procedure(Checker *c) {
	isize count = gb_array_count(c->proc_stack);
	if (count > 0) {
		return c->proc_stack[count-1];
	}
	return NULL;
}

void add_curr_ast_file(Checker *c, AstFile *file) {
	TokenPos zero_pos = {};
	c->error_collector.prev = zero_pos;
	c->curr_ast_file = file;
}




#include "expr.cpp"
#include "stmt.cpp"



struct CycleCheck {
	gbArray(Entity *) path; // HACK(bill): Memory Leak
};

void cycle_check_add(CycleCheck *cc, Entity *entity) {
	if (cc == NULL)
		return;
	if (cc->path == NULL) {
		gb_array_init(cc->path, gb_heap_allocator());
	}
	GB_ASSERT(entity->kind == Entity_TypeName);
	gb_array_append(cc->path, entity);
}

void check_type_name_cycles(Checker *c, CycleCheck *cc, Entity *e) {
	GB_ASSERT(e->kind == Entity_TypeName);
	Type *t = e->type;
	// if (t->kind == Type_Named) {
	// 	if (t->Named.type_name == e) {
	// 		gb_printf("Illegal cycle %.*s!!!\n", LIT(e->token.string));
	// 	}
	// }
}


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
						ExactValue v = {ExactValue_Invalid};
						Entity *e = make_entity_constant(c->allocator, c->context.scope, name->Ident, NULL, v);
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
					if (vd->value_count > 0) {
						di = make_declaration_info(gb_heap_allocator(), c->global_scope);
						di->entities = entities;
						di->entity_count = entity_count;
						di->type_expr = vd->type;
						di->init_expr = vd->value_list;
					}

					AstNode *value = vd->value_list;
					for (AstNode *name = vd->name_list; name != NULL; name = name->next) {
						Entity *e = make_entity_variable(c->allocator, c->global_scope, name->Ident, NULL);
						entities[entity_index++] = e;

						DeclInfo *d = di;
						if (d == NULL) {
							AstNode *init_expr = value;
							d = make_declaration_info(gb_heap_allocator(), c->global_scope);
							d->type_expr = vd->type;
							d->init_expr = init_expr;
							d->var_decl_tags = vd->tags;
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
				Entity *e = make_entity_type_name(c->allocator, c->global_scope, *n, NULL);
				DeclInfo *d = make_declaration_info(c->allocator, e->scope);
				d->type_expr = td->type;
				add_file_entity(c, td->name, e, d);
			case_end;

			case_ast_node(pd, ProcDecl, decl);
				ast_node(n, Ident, pd->name);
				Token token = *n;
				Entity *e = make_entity_procedure(c->allocator, c->global_scope, token, NULL);
				DeclInfo *d = make_declaration_info(c->allocator, e->scope);
				d->proc_decl = decl;
				map_set(&c->info.entities, hash_pointer(e), d);
			case_end;

			case_ast_node(ld, LoadDecl, decl);
				// NOTE(bill): ignore
			case_end;
			case_ast_node(fsl, ForeignSystemLibrary, decl);
				// NOTE(bill): ignore
			case_end;


			default:
				error(&c->error_collector, ast_node_token(decl), "Only declarations are allowed at file scope");
				break;
			}
		}
	}

	auto check_global_entity = [](Checker *c, EntityKind kind) {
		gb_for_array(i, c->info.entities.entries) {
			auto *entry = &c->info.entities.entries[i];
			Entity *e = cast(Entity *)cast(uintptr)entry->key.key;
			if (e->kind == kind) {
				DeclInfo *d = entry->value;
				check_entity_decl(c, e, d, NULL);
			}
		}
	};

	check_global_entity(c, Entity_TypeName);
	check_global_entity(c, Entity_Constant);
	check_global_entity(c, Entity_Procedure);
	check_global_entity(c, Entity_Variable);

	// Check procedure bodies
	gb_for_array(i, c->procs) {
		ProcedureInfo *pi = &c->procs[i];
		add_curr_ast_file(c, pi->file);
		check_proc_body(c, pi->token, pi->decl, pi->type, pi->body);
	}


	// Add untyped expression values
	gb_for_array(i, c->info.untyped.entries) {
		auto *entry = c->info.untyped.entries + i;
		HashKey key = entry->key;
		AstNode *expr = cast(AstNode *)cast(uintptr)key.key;
		ExpressionInfo *info = &entry->value;
		if (info != NULL && expr != NULL) {
			if (is_type_typed(info->type)) {
				GB_PANIC("%s (type %s) is typed!", expr_to_string(expr), info->type);
			}
			add_type_and_value(&c->info, expr, info->mode, info->type, info->value);
		}
	}
}



