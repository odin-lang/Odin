struct Scope;
struct Checker;
enum BuiltinProcId;

#define ENTITY_KINDS \
	ENTITY_KIND(Invalid), \
	ENTITY_KIND(Constant), \
	ENTITY_KIND(Variable), \
	ENTITY_KIND(TypeName), \
	ENTITY_KIND(Procedure), \
	ENTITY_KIND(Builtin), \
	ENTITY_KIND(ImportName), \
	ENTITY_KIND(Count),


enum EntityKind {
#define ENTITY_KIND(k) GB_JOIN2(Entity_, k)
	ENTITY_KINDS
#undef ENTITY_KIND
};

String const entity_strings[] = {
#define ENTITY_KIND(k) {cast(u8 *)#k, gb_size_of(#k)-1}
	ENTITY_KINDS
#undef ENTITY_KIND
};


typedef struct Type Type;

struct Entity {
	EntityKind kind;

	Scope *    scope;
	Token      token;
	Type *     type;
	Entity *   using_parent;
	AstNode *  using_expr;

	union {
		struct {
			ExactValue value;
		} Constant;
		struct {
			b8  visited;     // Cycle detection
			b8  used;        // Variable is used
			b8  anonymous;   // Variable is an anonymous
			b8  is_using;    // `using` variable

			i32 field_index; // Order in source
			b8  is_field;    // Is struct field
		} Variable;
		struct {
		} TypeName;
		struct {
		} Procedure;
		struct {
			BuiltinProcId id;
		} Builtin;
		struct {
			String path;
			String name;
			Scope *scope;
			b32 used;
		} ImportName;
	};
};

b32 is_entity_exported(Entity *e) {
	if (e->kind == Entity_ImportName) {
		return false;
	}
	// TODO(bill): Do I really want non-exported entities?
	// if (e->token.string.len >= 1 &&
	    // e->token.string.text[0] == '_') {
		// return false;
	// }
	return true;
}


Entity *alloc_entity(gbAllocator a, EntityKind kind, Scope *scope, Token token, Type *type) {
	Entity *entity = gb_alloc_item(a, Entity);
	entity->kind   = kind;
	entity->scope  = scope;
	entity->token  = token;
	entity->type   = type;
	return entity;
}

Entity *make_entity_variable(gbAllocator a, Scope *scope, Token token, Type *type) {
	Entity *entity = alloc_entity(a, Entity_Variable, scope, token, type);
	return entity;
}

Entity *make_entity_using_variable(gbAllocator a, Entity *parent, Token token, Type *type) {
	GB_ASSERT(parent != NULL);
	Entity *entity = alloc_entity(a, Entity_Variable, parent->scope, token, type);
	entity->using_parent = parent;
	entity->Variable.is_using = true;
	return entity;
}


Entity *make_entity_constant(gbAllocator a, Scope *scope, Token token, Type *type, ExactValue value) {
	Entity *entity = alloc_entity(a, Entity_Constant, scope, token, type);
	entity->Constant.value = value;
	return entity;
}

Entity *make_entity_type_name(gbAllocator a, Scope *scope, Token token, Type *type) {
	Entity *entity = alloc_entity(a, Entity_TypeName, scope, token, type);
	return entity;
}

Entity *make_entity_param(gbAllocator a, Scope *scope, Token token, Type *type, b32 is_anonymous) {
	Entity *entity = make_entity_variable(a, scope, token, type);
	entity->Variable.used = true;
	entity->Variable.anonymous = cast(b8)is_anonymous;
	return entity;
}

Entity *make_entity_field(gbAllocator a, Scope *scope, Token token, Type *type, b32 is_anonymous, i32 field_index) {
	Entity *entity = make_entity_variable(a, scope, token, type);
	entity->Variable.field_index = field_index;
	entity->Variable.is_field  = true;
	entity->Variable.anonymous = cast(b8)is_anonymous;
	return entity;
}

Entity *make_entity_procedure(gbAllocator a, Scope *scope, Token token, Type *signature_type) {
	Entity *entity = alloc_entity(a, Entity_Procedure, scope, token, signature_type);
	return entity;
}

Entity *make_entity_builtin(gbAllocator a, Scope *scope, Token token, Type *type, BuiltinProcId id) {
	Entity *entity = alloc_entity(a, Entity_Builtin, scope, token, type);
	entity->Builtin.id = id;
	return entity;
}

Entity *make_entity_import_name(gbAllocator a, Scope *scope, Token token, Type *type,
                                String path, String name, Scope *import_scope) {
	Entity *entity = alloc_entity(a, Entity_ImportName, scope, token, type);
	entity->ImportName.path = path;
	entity->ImportName.name = name;
	entity->ImportName.scope = import_scope;
	return entity;
}

Entity *make_entity_dummy_variable(gbAllocator a, Scope *file_scope, Token token) {
	token.string = make_string("_");
	return make_entity_variable(a, file_scope, token, NULL);
}

