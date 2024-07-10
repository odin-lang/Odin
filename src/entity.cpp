struct Scope;
struct Checker;
struct Type;
struct DeclInfo;


#define ENTITY_KINDS \
	ENTITY_KIND(Invalid) \
	ENTITY_KIND(Constant) \
	ENTITY_KIND(Variable) \
	ENTITY_KIND(TypeName) \
	ENTITY_KIND(Procedure) \
	ENTITY_KIND(ProcGroup) \
	ENTITY_KIND(Builtin) \
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

gb_global String const entity_strings[] = {
#define ENTITY_KIND(k) {cast(u8 *)#k, gb_size_of(#k)-1},
	ENTITY_KINDS
#undef ENTITY_KIND
};

enum EntityFlag : u64 {
	EntityFlag_Visited       = 1ull<<0,
	EntityFlag_Used          = 1ull<<1,
	EntityFlag_Using         = 1ull<<2,
	EntityFlag_Field         = 1ull<<3,
	EntityFlag_Param         = 1ull<<4,
	EntityFlag_Result        = 1ull<<5,
	EntityFlag_ArrayElem     = 1ull<<6,
	EntityFlag_ArraySwizzle  = 1ull<<7,
	EntityFlag_Ellipsis      = 1ull<<8,
	EntityFlag_NoAlias       = 1ull<<9,
	EntityFlag_TypeField     = 1ull<<10,
	EntityFlag_Value         = 1ull<<11,
	EntityFlag_BitFieldField = 1ull<<12,



	EntityFlag_PolyConst     = 1ull<<15,
	EntityFlag_NotExported   = 1ull<<16,
	EntityFlag_ConstInput    = 1ull<<17,

	EntityFlag_Static        = 1ull<<18,

	EntityFlag_ImplicitReference = 1ull<<19, // NOTE(bill): equivalent to `const &` in C++

	EntityFlag_SoaPtrField   = 1ull<<20, // to allow s.x[0] where `s.x` is a pointer rather than a slice

	EntityFlag_ProcBodyChecked = 1ull<<21,

	EntityFlag_CVarArg       = 1ull<<22,
	EntityFlag_NoBroadcast   = 1ull<<23,
	EntityFlag_AnyInt        = 1ull<<24,

	EntityFlag_Disabled      = 1ull<<25,
	EntityFlag_Cold          = 1ull<<26, // procedure is rarely called

	EntityFlag_Lazy          = 1ull<<27, // Lazily type checked

	EntityFlag_ForValue      = 1ull<<28,
	EntityFlag_SwitchValue   = 1ull<<29,

	EntityFlag_Test          = 1ull<<30,
	EntityFlag_Init          = 1ull<<31,
	EntityFlag_Subtype       = 1ull<<32,
	EntityFlag_Fini          = 1ull<<33,
	
	EntityFlag_CustomLinkName = 1ull<<40,
	EntityFlag_CustomLinkage_Internal = 1ull<<41,
	EntityFlag_CustomLinkage_Strong   = 1ull<<42,
	EntityFlag_CustomLinkage_Weak     = 1ull<<43,
	EntityFlag_CustomLinkage_LinkOnce = 1ull<<44,
	
	EntityFlag_Require = 1ull<<50,
	EntityFlag_ByPtr   = 1ull<<51, // enforce parameter is passed by pointer

	EntityFlag_Overridden    = 1ull<<63,
};

enum : u64 {
	EntityFlags_IsSubtype = EntityFlag_Using|EntityFlag_Subtype,
};

enum EntityState : u32 {
	EntityState_Unresolved = 0,
	EntityState_InProgress = 1,
	EntityState_Resolved   = 2,
};


enum ParameterValueKind {
	ParameterValue_Invalid,
	ParameterValue_Constant,
	ParameterValue_Nil,
	ParameterValue_Location,
	ParameterValue_Value,
};

struct ParameterValue {
	ParameterValueKind kind;
	Ast *original_ast_expr;
	union {
		ExactValue value;
		Ast *ast_value;
	};
};

gb_internal gb_inline bool has_parameter_value(ParameterValue const &param_value) {
	if (param_value.kind != ParameterValue_Invalid) {
		return true;
	}
	if (param_value.original_ast_expr != nullptr) {
		return true;
	}
	return false;
}

enum EntityConstantFlags : u32 {
	EntityConstantFlag_ImplicitEnumValue = 1<<0,
};

enum ProcedureOptimizationMode : u8 {
	ProcedureOptimizationMode_Default,
	ProcedureOptimizationMode_None,
	ProcedureOptimizationMode_FavorSize,
};


BlockingMutex global_type_name_objc_metadata_mutex;

struct TypeNameObjCMetadataEntry {
	String name;
	Entity *entity;
};
struct TypeNameObjCMetadata {
	BlockingMutex *mutex;
	Array<TypeNameObjCMetadataEntry> type_entries;
	Array<TypeNameObjCMetadataEntry> value_entries;
};

gb_internal TypeNameObjCMetadata *create_type_name_obj_c_metadata() {
	TypeNameObjCMetadata *md = gb_alloc_item(permanent_allocator(), TypeNameObjCMetadata);
	md->mutex = gb_alloc_item(permanent_allocator(), BlockingMutex);
	array_init(&md->type_entries,  heap_allocator());
	array_init(&md->value_entries, heap_allocator());
	return md;
}

// An Entity is a named "thing" in the language
struct Entity {
	EntityKind  kind;
	u64         id;
	std::atomic<u64>         flags;
	std::atomic<EntityState> state;
	Token       token;
	Scope *     scope;
	Type *      type;
	std::atomic<Ast *> identifier; // Can be nullptr
	DeclInfo *  decl_info;
	DeclInfo *  parent_proc_decl; // nullptr if in file/global scope
	AstFile *   file;
	AstPackage *pkg;

	// TODO(bill): Cleanup how `using` works for entities
	Entity *    using_parent;
	Ast *       using_expr;

	Entity *    aliased_of;

	union {
		struct lbModule *code_gen_module;
		struct cgModule *cg_module;
	};
	union {
		struct lbProcedure *code_gen_procedure;
		struct cgProcedure *cg_procedure;
	};

	u64         order_in_src;
	String      deprecated_message;
	String      warning_message;

	// IMPORTANT NOTE(bill): This must be a discriminated union because of patching
	// later entity kinds
	union {
		struct {
			u8 start;
		} Dummy;
		struct {
			ExactValue value;
			ParameterValue param_value;
			u32 flags;
			i32 field_group_index;
			CommentGroup *docs;
			CommentGroup *comment;
		} Constant;
		struct {
			Ast *type_expr; // only used for some variables within procedure bodies
			Ast *init_expr; // only used for some variables within procedure bodies
			i32  field_index;
			i32  field_group_index;
			u8   bit_field_bit_size;

			ParameterValue param_value;

			Type *for_loop_parent_type;

			String     thread_local_model;
			Entity *   foreign_library;
			Ast *      foreign_library_ident;
			String     link_name;
			String     link_prefix;
			String     link_suffix;
			String     link_section;
			CommentGroup *docs;
			CommentGroup *comment;
			bool       is_foreign;
			bool       is_export;
			bool       is_global;
			bool       is_rodata;
		} Variable;
		struct {
			Type * type_parameter_specialization;
			String ir_mangled_name;
			bool   is_type_alias;
			String objc_class_name;
			TypeNameObjCMetadata *objc_metadata;
		} TypeName;
		struct {
			u64     tags;
			Entity *foreign_library;
			Ast *   foreign_library_ident;
			String  link_name;
			String  link_prefix;
			String  link_suffix;
			DeferredProcedure deferred_procedure;

			struct GenProcsData *gen_procs;
			BlockingMutex gen_procs_mutex;
			ProcedureOptimizationMode optimization_mode;
			bool    is_foreign                 : 1;
			bool    is_export                  : 1;
			bool    generated_from_polymorphic : 1;
			bool    entry_point_only           : 1;
			bool    has_instrumentation        : 1;
			bool    is_memcpy_like             : 1;
		} Procedure;
		struct {
			Array<Entity *> entities;
		} ProcGroup;
		struct {
			i32 id;
		} Builtin;
		struct {
			String path;
			String name;
			Scope *scope;
		} ImportName;
		struct {
			Ast *decl;
			Slice<String> paths;
			String name;
			i64 priority_index;
			String extra_linker_flags;
		} LibraryName;
		i32 Nil;
		struct {
			String name;
			Ast *node;
			Ast *parent;
		} Label;
	};
};

gb_internal bool is_entity_kind_exported(EntityKind kind, bool allow_builtin = false) {
	switch (kind) {
	case Entity_Builtin:
		return allow_builtin;
	case Entity_ImportName:
	case Entity_LibraryName:
	case Entity_Nil:
		return false;
	}
	return true;
}

gb_internal bool is_entity_exported(Entity *e, bool allow_builtin = false) {
	GB_ASSERT(e != nullptr);
	if (!is_entity_kind_exported(e->kind, allow_builtin)) {
		return false;
	}

	if (e->flags & EntityFlag_NotExported) {
		return false;
	}
	if (e->file != nullptr && (e->file->flags & (AstFile_IsPrivatePkg|AstFile_IsPrivateFile)) != 0) {
		return false;
	}

	String name = e->token.string;
	switch (name.len) {
	case 0: return false;
	case 1: return name[0] != '_';
	}
	return true;
}

gb_internal bool entity_has_deferred_procedure(Entity *e) {
	GB_ASSERT(e != nullptr);
	if (e->kind == Entity_Procedure) {
		return e->Procedure.deferred_procedure.entity != nullptr;
	}
	return false;
}


gb_global std::atomic<u64> global_entity_id;

gb_internal Entity *alloc_entity(EntityKind kind, Scope *scope, Token token, Type *type) {
	gbAllocator a = permanent_allocator();
	Entity *entity = gb_alloc_item(a, Entity);
	entity->kind   = kind;
	entity->state  = EntityState_Unresolved;
	entity->scope  = scope;
	entity->token  = token;
	entity->type   = type;
	entity->id     = 1 + global_entity_id.fetch_add(1);
	if (token.pos.file_id) {
		entity->file = thread_safe_get_ast_file_from_id(token.pos.file_id);
	}
	return entity;
}

gb_internal Entity *alloc_entity_variable(Scope *scope, Token token, Type *type, EntityState state = EntityState_Unresolved) {
	Entity *entity = alloc_entity(Entity_Variable, scope, token, type);
	entity->state = state;
	return entity;
}

gb_internal Entity *alloc_entity_using_variable(Entity *parent, Token token, Type *type, Ast *using_expr) {
	GB_ASSERT(parent != nullptr);
	token.pos = parent->token.pos;
	Entity *entity = alloc_entity(Entity_Variable, parent->scope, token, type);
	entity->using_parent = parent;
	entity->parent_proc_decl = parent->parent_proc_decl;
	entity->using_expr = using_expr;
	entity->flags |= EntityFlag_Using;
	entity->flags |= EntityFlag_Used;
	entity->state = EntityState_Resolved;
	return entity;
}


gb_internal Entity *alloc_entity_constant(Scope *scope, Token token, Type *type, ExactValue value) {
	Entity *entity = alloc_entity(Entity_Constant, scope, token, type);
	entity->Constant.value = value;
	return entity;
}

gb_internal Entity *alloc_entity_type_name(Scope *scope, Token token, Type *type, EntityState state = EntityState_Unresolved) {
	Entity *entity = alloc_entity(Entity_TypeName, scope, token, type);
	entity->state = state;
	return entity;
}

gb_internal Entity *alloc_entity_param(Scope *scope, Token token, Type *type, bool is_using, bool is_value) {
	Entity *entity = alloc_entity_variable(scope, token, type);
	entity->flags |= EntityFlag_Used;
	entity->flags |= EntityFlag_Param;
	entity->state = EntityState_Resolved;
	if (is_using) entity->flags |= EntityFlag_Using;
	if (is_value) entity->flags |= EntityFlag_Value;
	return entity;
}


gb_internal Entity *alloc_entity_const_param(Scope *scope, Token token, Type *type, ExactValue value, bool poly_const) {
	Entity *entity = alloc_entity_constant(scope, token, type, value);
	entity->flags |= EntityFlag_Used;
	if (poly_const) entity->flags |= EntityFlag_PolyConst;
	entity->flags |= EntityFlag_Param;
	return entity;
}


gb_internal Entity *alloc_entity_field(Scope *scope, Token token, Type *type, bool is_using, i32 field_index, EntityState state = EntityState_Unresolved) {
	Entity *entity = alloc_entity_variable(scope, token, type);
	entity->Variable.field_index = field_index;
	if (is_using) entity->flags |= EntityFlag_Using;
	entity->flags |= EntityFlag_Field;
	entity->state = state;
	return entity;
}

gb_internal Entity *alloc_entity_array_elem(Scope *scope, Token token, Type *type, i32 field_index) {
	Entity *entity = alloc_entity_variable(scope, token, type);
	entity->Variable.field_index = field_index;
	entity->flags |= EntityFlag_Field;
	entity->flags |= EntityFlag_ArrayElem;
	entity->state = EntityState_Resolved;
	return entity;
}

gb_internal Entity *alloc_entity_procedure(Scope *scope, Token token, Type *signature_type, u64 tags=0) {
	Entity *entity = alloc_entity(Entity_Procedure, scope, token, signature_type);
	entity->Procedure.tags = tags;
	return entity;
}

gb_internal Entity *alloc_entity_proc_group(Scope *scope, Token token, Type *type) {
	Entity *entity = alloc_entity(Entity_ProcGroup, scope, token, type);
	return entity;
}

gb_internal Entity *alloc_entity_import_name(Scope *scope, Token token, Type *type,
                                 String path, String name, Scope *import_scope) {
	Entity *entity = alloc_entity(Entity_ImportName, scope, token, type);
	entity->ImportName.path = path;
	entity->ImportName.name = name;
	entity->ImportName.scope = import_scope;
	entity->state = EntityState_Resolved;
	return entity;
}

gb_internal Entity *alloc_entity_library_name(Scope *scope, Token token, Type *type,
                                  Slice<String> paths, String name) {
	Entity *entity = alloc_entity(Entity_LibraryName, scope, token, type);
	entity->LibraryName.paths = paths;
	entity->LibraryName.name = name;
	entity->state = EntityState_Resolved;
	return entity;
}





gb_internal Entity *alloc_entity_nil(String name, Type *type) {
	Entity *entity = alloc_entity(Entity_Nil, nullptr, make_token_ident(name), type);
	return entity;
}

gb_internal Entity *alloc_entity_label(Scope *scope, Token token, Type *type, Ast *node, Ast *parent) {
	Entity *entity = alloc_entity(Entity_Label, scope, token, type);
	entity->Label.node = node;
	entity->Label.parent = parent;
	entity->state = EntityState_Resolved;
	return entity;
}

gb_internal Entity *alloc_entity_dummy_variable(Scope *scope, Token token) {
	token.string = str_lit("_");
	return alloc_entity_variable(scope, token, nullptr);
}


gb_internal Entity *entity_from_expr(Ast *expr);

gb_internal Entity *strip_entity_wrapping(Entity *e) {
	if (e == nullptr) {
		return nullptr;
	}
	if (e->kind != Entity_Constant) {
		return e;
	}
	if (e->Constant.value.kind == ExactValue_Procedure) {
		return strip_entity_wrapping(e->Constant.value.value_procedure);
	}
	return e;
}

gb_internal Entity *strip_entity_wrapping(Ast *expr) {
	Entity *e = entity_from_expr(expr);
	return strip_entity_wrapping(e);
}


gb_internal bool is_entity_local_variable(Entity *e) {
	if (e == nullptr) {
		return false;
	}
	if (e->kind != Entity_Variable) {
		return false;
	}
	if (e->Variable.is_global) {
		return false;
	}
	if (e->scope == nullptr) {
		return true;
	}
	if (e->flags & (EntityFlag_ForValue|EntityFlag_SwitchValue|EntityFlag_Static)) {
		return false;
	}

	return ((e->scope->flags &~ ScopeFlag_ContextDefined) == 0) ||
	       (e->scope->flags & ScopeFlag_Proc) != 0;
}
