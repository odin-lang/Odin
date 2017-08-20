struct Scope;
struct Checker;
struct Type;
struct DeclInfo;
// typedef enum BuiltinProcId BuiltinProcId;


#define ENTITY_KINDS \
	ENTITY_KIND(Invalid) \
	ENTITY_KIND(Constant) \
	ENTITY_KIND(Variable) \
	ENTITY_KIND(TypeName) \
	ENTITY_KIND(Procedure) \
	ENTITY_KIND(Builtin) \
	ENTITY_KIND(Alias) \
	ENTITY_KIND(ImportName) \
	ENTITY_KIND(LibraryName) \
	ENTITY_KIND(Nil) \
	ENTITY_KIND(Label)

enum EntityKind {
#define ENTITY_KIND(k) GB_JOIN2(Entity_, k),
	ENTITY_KINDS
#undef ENTITY_KIND
	Entity_Count,
};

String const entity_strings[] = {
#define ENTITY_KIND(k) {cast(u8 *)#k, gb_size_of(#k)-1},
	ENTITY_KINDS
#undef ENTITY_KIND
};

enum EntityFlag {
	EntityFlag_Visited       = 1<<0,
	EntityFlag_Used          = 1<<1,
	EntityFlag_Using         = 1<<2,
	EntityFlag_Field         = 1<<3,
	EntityFlag_Param         = 1<<4,
	EntityFlag_VectorElem    = 1<<5,
	EntityFlag_Ellipsis      = 1<<6,
	EntityFlag_NoAlias       = 1<<7,
	EntityFlag_TypeField     = 1<<8,
	EntityFlag_Value         = 1<<9,
	EntityFlag_Sret          = 1<<10,
	EntityFlag_BitFieldValue = 1<<11,

	EntityFlag_CVarArg       = 1<<20,

};

// Zero value means the overloading process is not yet done
enum OverloadKind {
	Overload_Unknown,
	Overload_No,
	Overload_Yes,
};

enum EntityAliasKind {
	EntityAlias_Invalid,
	EntityAlias_Type,
	EntityAlias_Entity,
};


// An Entity is a named "thing" in the language
struct Entity {
	EntityKind kind;
	u64        id;
	u32        flags;
	Token      token;
	Scope *    scope;
	Type *     type;
	AstNode *  identifier; // Can be nullptr
	DeclInfo * parent_proc_decl; // nullptr if in file/global scope

	// TODO(bill): Cleanup how `using` works for entities
	Entity *   using_parent;
	AstNode *  using_expr;

	isize      order_in_src;

	union {
		struct {
			ExactValue value;
		} Constant;
		struct {
			i32        field_index;
			i32        field_src_index;
			ExactValue default_value;
			bool       default_is_nil;
			bool       default_is_undef;
			bool       default_is_location;
			bool       is_immutable;
			bool       is_thread_local;
			bool       is_foreign;
			Entity *   foreign_library;
			AstNode *  foreign_library_ident;
			String     link_name;
		} Variable;
		struct {
			bool is_type_alias;
			Type *type_parameter_specialization;
		} TypeName;
		struct {
			OverloadKind overload_kind;
			String       link_name;
			u64          tags;
			bool         is_foreign;
			Entity *     foreign_library;
			AstNode *    foreign_library_ident;
		} Procedure;
		struct {
			i32 id;
		} Builtin;
		struct {
			Entity *base;
		} Alias;
		struct {
			String path;
			String name;
			Scope *scope;
			bool   used;
		} ImportName;
		struct {
			String path;
			String name;
			bool   used;
		} LibraryName;
		i32 Nil;
		struct {
			String name;
			AstNode *node;
		} Label;
	};
};

gb_global Entity *e_context = nullptr;

bool is_entity_kind_exported(EntityKind kind) {
	switch (kind) {
	case Entity_Builtin:
	case Entity_ImportName:
	case Entity_LibraryName:
	case Entity_Nil:
		return false;
	}
	return true;
}

bool is_entity_exported(Entity *e) {
	// TODO(bill): Determine the actual exportation rules for imports of entities
	GB_ASSERT(e != nullptr);
	if (!is_entity_kind_exported(e->kind)) {
		return false;
	}

	String name = e->token.string;
	if (name.len == 0) {
		return false;
	}
	return name[0] != '_';
}

gb_global u64 global_entity_id = 0;

Entity *alloc_entity(gbAllocator a, EntityKind kind, Scope *scope, Token token, Type *type) {
	Entity *entity = gb_alloc_item(a, Entity);
	entity->kind   = kind;
	entity->scope  = scope;
	entity->token  = token;
	entity->type   = type;
	entity->id     = ++global_entity_id;
	return entity;
}

Entity *make_entity_variable(gbAllocator a, Scope *scope, Token token, Type *type, bool is_immutable) {
	Entity *entity = alloc_entity(a, Entity_Variable, scope, token, type);
	entity->Variable.is_immutable = is_immutable;
	return entity;
}

Entity *make_entity_using_variable(gbAllocator a, Entity *parent, Token token, Type *type) {
	GB_ASSERT(parent != nullptr);
	token.pos = parent->token.pos;
	Entity *entity = alloc_entity(a, Entity_Variable, parent->scope, token, type);
	entity->using_parent = parent;
	entity->parent_proc_decl = parent->parent_proc_decl;
	entity->flags |= EntityFlag_Using;
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

Entity *make_entity_param(gbAllocator a, Scope *scope, Token token, Type *type, bool is_using, bool is_immutable) {
	Entity *entity = make_entity_variable(a, scope, token, type, is_immutable);
	entity->flags |= EntityFlag_Used;
	if (is_using) entity->flags |= EntityFlag_Using;
	entity->flags |= EntityFlag_Param;
	return entity;
}

Entity *make_entity_field(gbAllocator a, Scope *scope, Token token, Type *type, bool is_using, i32 field_src_index) {
	Entity *entity = make_entity_variable(a, scope, token, type, false);
	entity->Variable.field_src_index = field_src_index;
	entity->Variable.field_index = field_src_index;
	if (is_using) entity->flags |= EntityFlag_Using;
	entity->flags |= EntityFlag_Field;
	return entity;
}

Entity *make_entity_vector_elem(gbAllocator a, Scope *scope, Token token, Type *type, i32 field_src_index) {
	Entity *entity = make_entity_variable(a, scope, token, type, false);
	entity->Variable.field_src_index = field_src_index;
	entity->Variable.field_index = field_src_index;
	entity->flags |= EntityFlag_Field;
	entity->flags |= EntityFlag_VectorElem;
	return entity;
}

Entity *make_entity_procedure(gbAllocator a, Scope *scope, Token token, Type *signature_type, u64 tags) {
	Entity *entity = alloc_entity(a, Entity_Procedure, scope, token, signature_type);
	entity->Procedure.tags = tags;
	return entity;
}

Entity *make_entity_builtin(gbAllocator a, Scope *scope, Token token, Type *type, i32 id) {
	Entity *entity = alloc_entity(a, Entity_Builtin, scope, token, type);
	entity->Builtin.id = id;
	return entity;
}

Entity *make_entity_alias(gbAllocator a, Scope *scope, Token token, Type *type, Entity *base) {
	Entity *entity = alloc_entity(a, Entity_Alias, scope, token, type);
	entity->Alias.base = base;
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

Entity *make_entity_library_name(gbAllocator a, Scope *scope, Token token, Type *type,
                                 String path, String name) {
	Entity *entity = alloc_entity(a, Entity_LibraryName, scope, token, type);
	entity->LibraryName.path = path;
	entity->LibraryName.name = name;
	return entity;
}





Entity *make_entity_nil(gbAllocator a, String name, Type *type) {
	Token token = make_token_ident(name);
	Entity *entity = alloc_entity(a, Entity_Nil, nullptr, token, type);
	return entity;
}

Entity *make_entity_label(gbAllocator a, Scope *scope, Token token, Type *type,
                          AstNode *node) {
	Entity *entity = alloc_entity(a, Entity_Label, scope, token, type);
	entity->Label.node = node;
	return entity;
}



Entity *make_entity_dummy_variable(gbAllocator a, Scope *scope, Token token) {
	token.string = str_lit("_");
	return make_entity_variable(a, scope, token, nullptr, false);
}

