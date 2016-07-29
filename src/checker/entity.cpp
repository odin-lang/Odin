struct Scope;
struct Checker;
enum BuiltinProcedureId;

#define ENTITY_KINDS \
	ENTITY_KIND(Invalid), \
	ENTITY_KIND(Constant), \
	ENTITY_KIND(Variable), \
	ENTITY_KIND(TypeName), \
	ENTITY_KIND(AliasName), \
	ENTITY_KIND(Procedure), \
	ENTITY_KIND(Builtin), \
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


typedef i64 EntityGuid;

struct Entity {
	EntityKind kind;
	EntityGuid guid;

	Scope *parent;
	Token token;
	Type *type;
	isize order;

	union {
		struct { ExactValue value; } constant;
		struct {
			b8 visited;
			b8 is_field;
			b8 used;
		} variable;
		struct {} type_name;
		struct {} alias_name;
		struct {} procedure;
		struct { BuiltinProcedureId id; } builtin;
	};
};

gb_global gbAtomic64 entity_guid_counter = {0};

EntityGuid next_entity_guid(void) {
	return cast(EntityGuid)gb_atomic64_fetch_add(&entity_guid_counter, 1);
}

Entity *alloc_entity(gbAllocator a, EntityKind kind, Scope *parent, Token token, Type *type) {
	Entity *entity = gb_alloc_item(a, Entity);
	entity->kind   = kind;
	entity->guid   = next_entity_guid();
	entity->parent = parent;
	entity->token  = token;
	entity->type   = type;
	return entity;
}

Entity *make_entity_variable(gbAllocator a, Scope *parent, Token token, Type *type) {
	Entity *entity = alloc_entity(a, Entity_Variable, parent, token, type);
	return entity;
}

Entity *make_entity_constant(gbAllocator a, Scope *parent, Token token, Type *type, ExactValue value) {
	Entity *entity = alloc_entity(a, Entity_Constant, parent, token, type);
	entity->constant.value = value;
	return entity;
}

Entity *make_entity_type_name(gbAllocator a, Scope *parent, Token token, Type *type) {
	Entity *entity = alloc_entity(a, Entity_TypeName, parent, token, type);
	return entity;
}

Entity *make_entity_alias_name(gbAllocator a, Scope *parent, Token token, Type *type) {
	Entity *entity = alloc_entity(a, Entity_AliasName, parent, token, type);
	return entity;
}

Entity *make_entity_param(gbAllocator a, Scope *parent, Token token, Type *type) {
	Entity *entity = make_entity_variable(a, parent, token, type);
	entity->variable.used = true;
	return entity;
}

Entity *make_entity_field(gbAllocator a, Scope *parent, Token token, Type *type) {
	Entity *entity = make_entity_variable(a, parent, token, type);
	entity->variable.is_field  = true;
	return entity;
}

Entity *make_entity_procedure(gbAllocator a, Scope *parent, Token token, Type *signature_type) {
	Entity *entity = alloc_entity(a, Entity_Procedure, parent, token, signature_type);
	return entity;
}

Entity *make_entity_builtin(gbAllocator a, Scope *parent, Token token, Type *type, BuiltinProcedureId id) {
	Entity *entity = alloc_entity(a, Entity_Builtin, parent, token, type);
	entity->builtin.id = id;
	return entity;
}

Entity *make_entity_dummy_variable(gbAllocator a, Scope *file_scope, Token token) {
	token.string = make_string("_");
	return make_entity_variable(a, file_scope, token, NULL);
}

