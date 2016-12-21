typedef struct ssaProcedure ssaProcedure;
typedef struct ssaBlock ssaBlock;
typedef struct ssaValue ssaValue;
typedef struct ssaDebugInfo ssaDebugInfo;

typedef Array(ssaValue *) ssaValueArray;

#define MAP_TYPE ssaValue *
#define MAP_PROC map_ssa_value_
#define MAP_NAME MapSsaValue
#include "map.c"

#define MAP_TYPE ssaDebugInfo *
#define MAP_PROC map_ssa_debug_info_
#define MAP_NAME MapSsaDebugInfo
#include "map.c"

typedef struct ssaModule {
	CheckerInfo * info;
	BuildContext *build_context;
	BaseTypeSizes sizes;
	gbArena       arena;
	gbArena       tmp_arena;
	gbAllocator   allocator;
	gbAllocator   tmp_allocator;
	bool generate_debug_info;

	u32 stmt_state_flags;

	// String source_filename;
	String layout;
	// String triple;

	MapEntity       min_dep_map; // Key: Entity *
	MapSsaValue     values;      // Key: Entity *
	MapSsaValue     members;     // Key: String
	MapString       type_names;  // Key: Type *
	MapSsaDebugInfo debug_info;  // Key: Unique pointer
	i32             global_string_index;
	i32             global_array_index; // For ConstantSlice

	Entity *        entry_point_entity;

	Array(ssaProcedure *) procs;             // NOTE(bill): All procedures with bodies
	ssaValueArray         procs_to_generate; // NOTE(bill): Procedures to generate
} ssaModule;

// NOTE(bill): For more info, see https://en.wikipedia.org/wiki/Dominator_(graph_theory)
typedef struct ssaDomNode {
	ssaBlock *        idom; // Parent (Immediate Dominator)
	Array(ssaBlock *) children;
	i32               pre, post; // Ordering in tree
} ssaDomNode;


typedef struct ssaBlock {
	i32           index;
	String        label;
	ssaProcedure *parent;
	AstNode *     node; // Can be NULL
	Scope *       scope;
	isize         scope_index;
	ssaDomNode    dom;
	i32           gaps;

	ssaValueArray instrs;
	ssaValueArray locals;

	Array(ssaBlock *) preds;
	Array(ssaBlock *) succs;
} ssaBlock;

typedef struct ssaTargetList ssaTargetList;
struct ssaTargetList {
	ssaTargetList *prev;
	ssaBlock *     break_;
	ssaBlock *     continue_;
	ssaBlock *     fallthrough_;
};

typedef enum ssaDeferExitKind {
	ssaDeferExit_Default,
	ssaDeferExit_Return,
	ssaDeferExit_Branch,
} ssaDeferExitKind;
typedef enum ssaDeferKind {
	ssaDefer_Node,
	ssaDefer_Instr,
} ssaDeferKind;

typedef struct ssaDefer {
	ssaDeferKind kind;
	isize        scope_index;
	ssaBlock *   block;
	union {
		AstNode *stmt;
		// NOTE(bill): `instr` will be copied every time to create a new one
		ssaValue *instr;
	};
} ssaDefer;

struct ssaProcedure {
	ssaProcedure *        parent;
	Array(ssaProcedure *) children;

	Entity *              entity;
	ssaModule *           module;
	String                name;
	Type *                type;
	AstNode *             type_expr;
	AstNode *             body;
	u64                   tags;

	ssaValueArray         params;
	Array(ssaDefer)       defer_stmts;
	Array(ssaBlock *)     blocks;
	i32                   scope_index;
	ssaBlock *            decl_block;
	ssaBlock *            entry_block;
	ssaBlock *            curr_block;
	ssaTargetList *       target_list;
	ssaValueArray         referrers;

	i32                   local_count;
	i32                   instr_count;
	i32                   block_count;
};

#define SSA_STARTUP_RUNTIME_PROC_NAME  "__$startup_runtime"
#define SSA_TYPE_INFO_DATA_NAME        "__$type_info_data"
#define SSA_TYPE_INFO_DATA_MEMBER_NAME "__$type_info_data_member"


#define SSA_INSTR_KINDS \
	SSA_INSTR_KIND(Comment, struct { String text; }) \
	SSA_INSTR_KIND(Local,   struct { \
		Entity *      entity; \
		Type *        type; \
		bool          zero_initialized; \
		ssaValueArray referrers; \
	}) \
	SSA_INSTR_KIND(ZeroInit, struct { ssaValue *address; }) \
	SSA_INSTR_KIND(Store,    struct { ssaValue *address, *value; }) \
	SSA_INSTR_KIND(Load,     struct { Type *type; ssaValue *address; }) \
	SSA_INSTR_KIND(PtrOffset, struct { \
		ssaValue *address; \
		ssaValue *offset; \
	}) \
	SSA_INSTR_KIND(ArrayElementPtr, struct { \
		ssaValue *address; \
		Type *    result_type; \
		ssaValue *elem_index; \
	}) \
	SSA_INSTR_KIND(StructElementPtr, struct {  \
		ssaValue *address; \
		Type *    result_type; \
		i32       elem_index; \
	}) \
	SSA_INSTR_KIND(ArrayExtractValue, struct { \
		ssaValue *address; \
		Type *    result_type; \
		i32       index; \
	}) \
	SSA_INSTR_KIND(StructExtractValue, struct { \
		ssaValue *address; \
		Type *    result_type; \
		i32       index; \
	}) \
	SSA_INSTR_KIND(UnionTagPtr, struct { \
		ssaValue *address; \
		Type     *type; /* ^int */  \
	}) \
	SSA_INSTR_KIND(UnionTagValue, struct { \
		ssaValue *address; \
		Type     *type; /* int */ \
	}) \
	SSA_INSTR_KIND(Conv, struct { \
		ssaConvKind kind; \
		ssaValue *value; \
		Type *from, *to; \
	}) \
	SSA_INSTR_KIND(Jump, struct { ssaBlock *block; }) \
	SSA_INSTR_KIND(If, struct { \
		ssaValue *cond; \
		ssaBlock *true_block; \
		ssaBlock *false_block; \
	}) \
	SSA_INSTR_KIND(Return, struct { ssaValue *value; }) \
	SSA_INSTR_KIND(Select, struct { \
		ssaValue *cond; \
		ssaValue *true_value; \
		ssaValue *false_value; \
	}) \
	SSA_INSTR_KIND(Phi, struct { ssaValueArray edges; Type *type; }) \
	SSA_INSTR_KIND(Unreachable, i32) \
	SSA_INSTR_KIND(UnaryOp, struct { \
		Type *    type; \
		TokenKind op; \
		ssaValue *expr; \
	}) \
	SSA_INSTR_KIND(BinaryOp, struct { \
		Type *    type; \
		TokenKind op; \
		ssaValue *left, *right; \
	}) \
	SSA_INSTR_KIND(Call, struct { \
		Type *    type; /* return type */  \
		ssaValue *value; \
		ssaValue **args; \
		isize      arg_count; \
	}) \
	SSA_INSTR_KIND(VectorExtractElement, struct { \
		ssaValue *vector; \
		ssaValue *index; \
	}) \
	SSA_INSTR_KIND(VectorInsertElement, struct { \
		ssaValue *vector; \
		ssaValue *elem; \
		ssaValue *index; \
	}) \
	SSA_INSTR_KIND(VectorShuffle, struct { \
		ssaValue *vector; \
		i32 *     indices; \
		i32       index_count; \
		Type *    type; \
	}) \
	SSA_INSTR_KIND(StartupRuntime, i32) \
	SSA_INSTR_KIND(BoundsCheck, struct { \
		TokenPos  pos; \
		ssaValue *index; \
		ssaValue *len; \
	}) \
	SSA_INSTR_KIND(SliceBoundsCheck, struct { \
		TokenPos  pos; \
		ssaValue *low; \
		ssaValue *high; \
		ssaValue *max; \
		bool      is_substring; \
	})

#define SSA_CONV_KINDS \
	SSA_CONV_KIND(trunc) \
	SSA_CONV_KIND(zext) \
	SSA_CONV_KIND(fptrunc) \
	SSA_CONV_KIND(fpext) \
	SSA_CONV_KIND(fptoui) \
	SSA_CONV_KIND(fptosi) \
	SSA_CONV_KIND(uitofp) \
	SSA_CONV_KIND(sitofp) \
	SSA_CONV_KIND(ptrtoint) \
	SSA_CONV_KIND(inttoptr) \
	SSA_CONV_KIND(bitcast)

typedef enum ssaInstrKind {
	ssaInstr_Invalid,
#define SSA_INSTR_KIND(x, ...) GB_JOIN2(ssaInstr_, x),
	SSA_INSTR_KINDS
#undef SSA_INSTR_KIND
} ssaInstrKind;

String const ssa_instr_strings[] = {
	{cast(u8 *)"Invalid", gb_size_of("Invalid")-1},
#define SSA_INSTR_KIND(x, ...) {cast(u8 *)#x, gb_size_of(#x)-1},
	SSA_INSTR_KINDS
#undef SSA_INSTR_KIND
};

typedef enum ssaConvKind {
	ssaConv_Invalid,
#define SSA_CONV_KIND(x) GB_JOIN2(ssaConv_, x),
	SSA_CONV_KINDS
#undef SSA_CONV_KIND
} ssaConvKind;

String const ssa_conv_strings[] = {
	{cast(u8 *)"Invalid", gb_size_of("Invalid")-1},
#define SSA_CONV_KIND(x) {cast(u8 *)#x, gb_size_of(#x)-1},
	SSA_CONV_KINDS
#undef SSA_CONV_KIND
};

#define SSA_INSTR_KIND(k, ...) typedef __VA_ARGS__ GB_JOIN2(ssaInstr, k);
	SSA_INSTR_KINDS
#undef SSA_INSTR_KIND

typedef struct ssaInstr ssaInstr;
struct ssaInstr {
	ssaInstrKind kind;

	ssaBlock *parent;
	Type *type;

	union {
#define SSA_INSTR_KIND(k, ...) GB_JOIN2(ssaInstr, k) k;
	SSA_INSTR_KINDS
#undef SSA_INSTR_KIND
	};
};


typedef enum ssaValueKind {
	ssaValue_Invalid,

	ssaValue_Constant,
	ssaValue_ConstantSlice,
	ssaValue_Nil,
	ssaValue_TypeName,
	ssaValue_Global,
	ssaValue_Param,

	ssaValue_Proc,
	ssaValue_Block,
	ssaValue_Instr,

	ssaValue_Count,
} ssaValueKind;

typedef struct ssaValueConstant {
	Type *     type;
	ExactValue value;
} ssaValueConstant;

typedef struct ssaValueConstantSlice {
	Type *    type;
	ssaValue *backing_array;
	i64       count;
} ssaValueConstantSlice;

typedef struct ssaValueNil {
	Type *type;
} ssaValueNil;

typedef struct ssaValueTypeName {
	Type * type;
	String name;
} ssaValueTypeName;

typedef struct ssaValueGlobal {
	Entity *      entity;
	Type *        type;
	ssaValue *    value;
	ssaValueArray referrers;
	bool          is_constant;
	bool          is_private;
	bool          is_thread_local;
	bool          is_unnamed_addr;
} ssaValueGlobal;

typedef struct ssaValueParam {
	ssaProcedure *parent;
	Entity *      entity;
	Type *        type;
	ssaValueArray referrers;
} ssaValueParam;

typedef struct ssaValue {
	ssaValueKind kind;
	i32 index;
	union {
		ssaValueConstant      Constant;
		ssaValueConstantSlice ConstantSlice;
		ssaValueNil           Nil;
		ssaValueTypeName      TypeName;
		ssaValueGlobal        Global;
		ssaValueParam         Param;
		ssaProcedure          Proc;
		ssaBlock              Block;
		ssaInstr              Instr;
	};
} ssaValue;

gb_global ssaValue *v_zero    = NULL;
gb_global ssaValue *v_one     = NULL;
gb_global ssaValue *v_zero32  = NULL;
gb_global ssaValue *v_one32   = NULL;
gb_global ssaValue *v_two32   = NULL;
gb_global ssaValue *v_false   = NULL;
gb_global ssaValue *v_true    = NULL;

typedef enum ssaAddrKind {
	ssaAddr_Default,
	ssaAddr_Vector,
} ssaAddrKind;

typedef struct ssaAddr {
	ssaValue *  addr;
	AstNode *   expr; // NOTE(bill): Just for testing - probably remove later
	ssaAddrKind kind;
	union {
		struct { ssaValue *index; } Vector;
	};
} ssaAddr;

ssaAddr ssa_make_addr(ssaValue *addr, AstNode *expr) {
	ssaAddr v = {addr, expr};
	return v;
}
ssaAddr ssa_make_addr_vector(ssaValue *addr, ssaValue *index, AstNode *expr) {
	ssaAddr v = ssa_make_addr(addr, expr);
	v.kind = ssaAddr_Vector;
	v.Vector.index = index;
	return v;
}



typedef enum ssaDebugEncoding {
	ssaDebugBasicEncoding_Invalid       = 0,

	ssaDebugBasicEncoding_address       = 1,
	ssaDebugBasicEncoding_boolean       = 2,
	ssaDebugBasicEncoding_float         = 3,
	ssaDebugBasicEncoding_signed        = 4,
	ssaDebugBasicEncoding_signed_char   = 5,
	ssaDebugBasicEncoding_unsigned      = 6,
	ssaDebugBasicEncoding_unsigned_char = 7,

	ssaDebugBasicEncoding_member       = 13,
	ssaDebugBasicEncoding_pointer_type = 15,
	ssaDebugBasicEncoding_typedef      = 22,

	ssaDebugBasicEncoding_array_type       = 1,
	ssaDebugBasicEncoding_enumeration_type = 4,
	ssaDebugBasicEncoding_structure_type   = 19,
	ssaDebugBasicEncoding_union_type       = 23,

} ssaDebugEncoding;

typedef enum ssaDebugInfoKind {
	ssaDebugInfo_Invalid,

	ssaDebugInfo_CompileUnit,
	ssaDebugInfo_File,
	ssaDebugInfo_Scope,
	ssaDebugInfo_Proc,
	ssaDebugInfo_AllProcs,

	ssaDebugInfo_BasicType,      // basic types
	ssaDebugInfo_ProcType,
	ssaDebugInfo_DerivedType,    // pointer, typedef
	ssaDebugInfo_CompositeType,  // array, struct, enum, (raw_)union
	ssaDebugInfo_Enumerator,     // For ssaDebugInfo_CompositeType if enum
	ssaDebugInfo_GlobalVariable,
	ssaDebugInfo_LocalVariable,


	ssaDebugInfo_Count,
} ssaDebugInfoKind;

typedef struct ssaDebugInfo ssaDebugInfo;
struct ssaDebugInfo {
	ssaDebugInfoKind kind;
	i32 id;

	union {
		struct {
			AstFile *     file;
			String        producer;
			ssaDebugInfo *all_procs;
		} CompileUnit;
		struct {
			AstFile *file;
			String   filename;
			String   directory;
		} File;
		struct {
			ssaDebugInfo *parent;
			ssaDebugInfo *file;
			TokenPos      pos;
			Scope *       scope; // Actual scope
		} Scope;
		struct {
			Entity *      entity;
			String        name;
			ssaDebugInfo *file;
			TokenPos      pos;
		} Proc;
		struct {
			Array(ssaDebugInfo *) procs;
		} AllProcs;


		struct {
			String           name;
			i32              size;
			i32              align;
			ssaDebugEncoding encoding;
		} BasicType;
		struct {
			ssaDebugInfo *        return_type;
			Array(ssaDebugInfo *) param_types;
		} ProcType;
		struct {
			ssaDebugInfo *   base_type;
			ssaDebugEncoding encoding;
		} DerivedType;
		struct {
			ssaDebugEncoding      encoding;
			String                name;
			String                identifier;
			ssaDebugInfo *        file;
			TokenPos              pos;
			i32                   size;
			i32                   align;
			Array(ssaDebugInfo *) elements;
		} CompositeType;
		struct {
			String name;
			i64    value;
		} Enumerator;
		struct {
			String        name;
			String        linkage_name;
			ssaDebugInfo *scope;
			ssaDebugInfo *file;
			TokenPos      pos;
			ssaValue     *variable;
			ssaDebugInfo *declaration;
		} GlobalVariable;
		struct {
			String        name;
			ssaDebugInfo *scope;
			ssaDebugInfo *file;
			TokenPos      pos;
			i32           arg; // Non-zero if proc parameter
			ssaDebugInfo *type;
		} LocalVariable;
	};
};

typedef struct ssaGen {
	ssaModule module;
	gbFile    output_file;
	bool       opt_called;
} ssaGen;

ssaValue *ssa_lookup_member(ssaModule *m, String name) {
	ssaValue **v = map_ssa_value_get(&m->members, hash_string(name));
	if (v != NULL) {
		return *v;
	}
	return NULL;
}


Type *ssa_type(ssaValue *value);
Type *ssa_instr_type(ssaInstr *instr) {
	switch (instr->kind) {
	case ssaInstr_Local:
		return instr->Local.type;
	case ssaInstr_Load:
		return instr->Load.type;
	case ssaInstr_StructElementPtr:
		return instr->StructElementPtr.result_type;
	case ssaInstr_ArrayElementPtr:
		return instr->ArrayElementPtr.result_type;
	case ssaInstr_PtrOffset:
		return ssa_type(instr->PtrOffset.address);
	case ssaInstr_Phi:
		return instr->Phi.type;
	case ssaInstr_ArrayExtractValue:
		return instr->ArrayExtractValue.result_type;
	case ssaInstr_StructExtractValue:
		return instr->StructExtractValue.result_type;
	case ssaInstr_UnionTagPtr:
		return instr->UnionTagPtr.type;
	case ssaInstr_UnionTagValue:
		return instr->UnionTagValue.type;
	case ssaInstr_UnaryOp:
		return instr->UnaryOp.type;
	case ssaInstr_BinaryOp:
		return instr->BinaryOp.type;
	case ssaInstr_Conv:
		return instr->Conv.to;
	case ssaInstr_Select:
		return ssa_type(instr->Select.true_value);
	case ssaInstr_Call: {
		Type *pt = base_type(instr->Call.type);
		if (pt != NULL) {
			if (pt->kind == Type_Tuple && pt->Tuple.variable_count == 1) {
				return pt->Tuple.variables[0]->type;
			}
			return pt;
		}
		return NULL;
	} break;
	case ssaInstr_VectorExtractElement: {
		Type *vt = ssa_type(instr->VectorExtractElement.vector);
		Type *bt = base_vector_type(vt);
		GB_ASSERT(!is_type_vector(bt));
		return bt;
	} break;
	case ssaInstr_VectorInsertElement:
		return ssa_type(instr->VectorInsertElement.vector);
	case ssaInstr_VectorShuffle:
		return instr->VectorShuffle.type;
	}
	return NULL;
}

Type *ssa_type(ssaValue *value) {
	switch (value->kind) {
	case ssaValue_Constant:
		return value->Constant.type;
	case ssaValue_ConstantSlice:
		return value->ConstantSlice.type;
	case ssaValue_Nil:
		return value->Nil.type;
	case ssaValue_TypeName:
		return value->TypeName.type;
	case ssaValue_Global:
		return value->Global.type;
	case ssaValue_Param:
		return value->Param.type;
	case ssaValue_Proc:
		return value->Proc.type;
	case ssaValue_Instr:
		return ssa_instr_type(&value->Instr);
	}
	return NULL;
}

Type *ssa_addr_type(ssaAddr lval) {
	if (lval.addr != NULL) {
		Type *t = ssa_type(lval.addr);
		GB_ASSERT(is_type_pointer(t));
		return type_deref(t);
	}
	return NULL;
}



bool ssa_is_blank_ident(AstNode *node) {
	if (node->kind == AstNode_Ident) {
		ast_node(i, Ident, node);
		return is_blank_ident(i->string);
	}
	return false;
}


ssaInstr *ssa_get_last_instr(ssaBlock *block) {
	if (block != NULL) {
		isize len = block->instrs.count;
		if (len > 0) {
			ssaValue *v = block->instrs.e[len-1];
			GB_ASSERT(v->kind == ssaValue_Instr);
			return &v->Instr;
		}
	}
	return NULL;

}

bool ssa_is_instr_terminating(ssaInstr *i) {
	if (i != NULL) {
		switch (i->kind) {
		case ssaInstr_Return:
		case ssaInstr_Unreachable:
			return true;
		}
	}

	return false;
}


void ssa_add_edge(ssaBlock *from, ssaBlock *to) {
	array_add(&from->succs, to);
	array_add(&to->preds, from);
}

void ssa_set_instr_parent(ssaValue *instr, ssaBlock *parent) {
	if (instr->kind == ssaValue_Instr) {
		instr->Instr.parent = parent;
	}
}

ssaValueArray *ssa_value_referrers(ssaValue *v) {
	switch (v->kind) {
	case ssaValue_Global:
		return &v->Global.referrers;
	case ssaValue_Param:
		return &v->Param.referrers;
	case ssaValue_Proc: {
		if (v->Proc.parent != NULL) {
			return &v->Proc.referrers;
		}
		return NULL;
	}
	case ssaValue_Instr: {
		ssaInstr *i = &v->Instr;
		switch (i->kind) {
		case ssaInstr_Local:
			return &i->Local.referrers;
		}
	} break;
	}

	return NULL;
}



////////////////////////////////////////////////////////////////
//
// @Make
//
////////////////////////////////////////////////////////////////

void      ssa_module_add_value    (ssaModule *m, Entity *e, ssaValue *v);
ssaValue *ssa_emit_zero_init      (ssaProcedure *p, ssaValue *address);
ssaValue *ssa_emit_comment        (ssaProcedure *p, String text);
ssaValue *ssa_emit_store          (ssaProcedure *p, ssaValue *address, ssaValue *value);
ssaValue *ssa_emit_load           (ssaProcedure *p, ssaValue *address);
void      ssa_emit_jump           (ssaProcedure *proc, ssaBlock *block);
ssaValue *ssa_emit_conv           (ssaProcedure *proc, ssaValue *value, Type *t);
ssaValue *ssa_type_info           (ssaProcedure *proc, Type *type);
ssaValue *ssa_build_expr          (ssaProcedure *proc, AstNode *expr);
void      ssa_build_stmt          (ssaProcedure *proc, AstNode *node);
void      ssa_build_cond          (ssaProcedure *proc, AstNode *cond, ssaBlock *true_block, ssaBlock *false_block);
void      ssa_build_defer_stmt    (ssaProcedure *proc, ssaDefer d);
ssaAddr   ssa_build_addr          (ssaProcedure *proc, AstNode *expr);
void      ssa_build_proc          (ssaValue *value, ssaProcedure *parent);
void      ssa_gen_global_type_name(ssaModule *m, Entity *e, String name);




ssaValue *ssa_alloc_value(gbAllocator a, ssaValueKind kind) {
	ssaValue *v = gb_alloc_item(a, ssaValue);
	v->kind = kind;
	return v;
}
ssaValue *ssa_alloc_instr(ssaProcedure *proc, ssaInstrKind kind) {
	ssaValue *v = ssa_alloc_value(proc->module->allocator, ssaValue_Instr);
	v->Instr.kind = kind;
	proc->instr_count++;
	return v;
}
ssaDebugInfo *ssa_alloc_debug_info(gbAllocator a, ssaDebugInfoKind kind) {
	ssaDebugInfo *di = gb_alloc_item(a, ssaDebugInfo);
	di->kind = kind;
	return di;
}




ssaValue *ssa_make_value_type_name(gbAllocator a, String name, Type *type) {
	ssaValue *v = ssa_alloc_value(a, ssaValue_TypeName);
	v->TypeName.name = name;
	v->TypeName.type = type;
	return v;
}

ssaValue *ssa_make_value_global(gbAllocator a, Entity *e, ssaValue *value) {
	ssaValue *v = ssa_alloc_value(a, ssaValue_Global);
	v->Global.entity = e;
	v->Global.type = make_type_pointer(a, e->type);
	v->Global.value = value;
	array_init(&v->Global.referrers, heap_allocator()); // TODO(bill): Replace heap allocator here
	return v;
}
ssaValue *ssa_make_value_param(gbAllocator a, ssaProcedure *parent, Entity *e) {
	ssaValue *v = ssa_alloc_value(a, ssaValue_Param);
	v->Param.parent = parent;
	v->Param.entity = e;
	v->Param.type   = e->type;
	array_init(&v->Param.referrers, heap_allocator()); // TODO(bill): Replace heap allocator here
	return v;
}
ssaValue *ssa_make_value_nil(gbAllocator a, Type *type) {
	ssaValue *v = ssa_alloc_value(a, ssaValue_Nil);
	v->Nil.type = type;
	return v;
}



ssaValue *ssa_make_instr_local(ssaProcedure *p, Entity *e, bool zero_initialized) {
	ssaValue *v = ssa_alloc_instr(p, ssaInstr_Local);
	ssaInstr *i = &v->Instr;
	i->Local.entity = e;
	i->Local.type = make_type_pointer(p->module->allocator, e->type);
	i->Local.zero_initialized = zero_initialized;
	array_init(&i->Local.referrers, heap_allocator()); // TODO(bill): Replace heap allocator here
	ssa_module_add_value(p->module, e, v);
	return v;
}


ssaValue *ssa_make_instr_store(ssaProcedure *p, ssaValue *address, ssaValue *value) {
	ssaValue *v = ssa_alloc_instr(p, ssaInstr_Store);
	ssaInstr *i = &v->Instr;
	i->Store.address = address;
	i->Store.value = value;
	return v;
}

ssaValue *ssa_make_instr_zero_init(ssaProcedure *p, ssaValue *address) {
	ssaValue *v = ssa_alloc_instr(p, ssaInstr_ZeroInit);
	ssaInstr *i = &v->Instr;
	i->ZeroInit.address = address;
	return v;
}

ssaValue *ssa_make_instr_load(ssaProcedure *p, ssaValue *address) {
	ssaValue *v = ssa_alloc_instr(p, ssaInstr_Load);
	ssaInstr *i = &v->Instr;
	i->Load.address = address;
	i->Load.type = type_deref(ssa_type(address));
	return v;
}

ssaValue *ssa_make_instr_array_element_ptr(ssaProcedure *p, ssaValue *address, ssaValue *elem_index) {
	ssaValue *v = ssa_alloc_instr(p, ssaInstr_ArrayElementPtr);
	ssaInstr *i = &v->Instr;
	Type *t = ssa_type(address);
	GB_ASSERT(is_type_pointer(t));
	t = base_type(type_deref(t));
	GB_ASSERT(is_type_array(t) || is_type_vector(t));

	Type *result_type = make_type_pointer(p->module->allocator, t->Array.elem);

	i->ArrayElementPtr.address = address;
	i->ArrayElementPtr.elem_index = elem_index;
	i->ArrayElementPtr.result_type = result_type;

	GB_ASSERT_MSG(is_type_pointer(ssa_type(address)),
	              "%s", type_to_string(ssa_type(address)));
	return v;
}
ssaValue *ssa_make_instr_struct_element_ptr(ssaProcedure *p, ssaValue *address, i32 elem_index, Type *result_type) {
	ssaValue *v = ssa_alloc_instr(p, ssaInstr_StructElementPtr);
	ssaInstr *i = &v->Instr;
	i->StructElementPtr.address     = address;
	i->StructElementPtr.elem_index  = elem_index;
	i->StructElementPtr.result_type = result_type;

	GB_ASSERT_MSG(is_type_pointer(ssa_type(address)),
	              "%s", type_to_string(ssa_type(address)));
	return v;
}
ssaValue *ssa_make_instr_ptr_offset(ssaProcedure *p, ssaValue *address, ssaValue *offset) {
	ssaValue *v = ssa_alloc_instr(p, ssaInstr_PtrOffset);
	ssaInstr *i = &v->Instr;
	i->PtrOffset.address = address;
	i->PtrOffset.offset  = offset;

	GB_ASSERT_MSG(is_type_pointer(ssa_type(address)),
	              "%s", type_to_string(ssa_type(address)));
	GB_ASSERT_MSG(is_type_integer(ssa_type(offset)),
	              "%s", type_to_string(ssa_type(address)));

	return v;
}



ssaValue *ssa_make_instr_array_extract_value(ssaProcedure *p, ssaValue *address, i32 index) {
	ssaValue *v = ssa_alloc_instr(p, ssaInstr_ArrayExtractValue);
	ssaInstr *i = &v->Instr;
	i->ArrayExtractValue.address = address;
	i->ArrayExtractValue.index = index;
	Type *t = base_type(ssa_type(address));
	GB_ASSERT(is_type_array(t));
	i->ArrayExtractValue.result_type = t->Array.elem;
	return v;
}

ssaValue *ssa_make_instr_struct_extract_value(ssaProcedure *p, ssaValue *address, i32 index, Type *result_type) {
	ssaValue *v = ssa_alloc_instr(p, ssaInstr_StructExtractValue);
	ssaInstr *i = &v->Instr;
	i->StructExtractValue.address = address;
	i->StructExtractValue.index = index;
	i->StructExtractValue.result_type = result_type;
	return v;
}

ssaValue *ssa_make_instr_union_tag_ptr(ssaProcedure *p, ssaValue *address) {
	ssaValue *v = ssa_alloc_instr(p, ssaInstr_UnionTagPtr);
	ssaInstr *i = &v->Instr;
	i->UnionTagPtr.address = address;
	i->UnionTagPtr.type = t_int_ptr;
	return v;
}

ssaValue *ssa_make_instr_union_tag_value(ssaProcedure *p, ssaValue *address) {
	ssaValue *v = ssa_alloc_instr(p, ssaInstr_UnionTagValue);
	ssaInstr *i = &v->Instr;
	i->UnionTagValue.address = address;
	i->UnionTagValue.type = t_int_ptr;
	return v;
}

ssaValue *ssa_make_instr_unary_op(ssaProcedure *p, TokenKind op, ssaValue *expr, Type *type) {
	ssaValue *v = ssa_alloc_instr(p, ssaInstr_UnaryOp);
	ssaInstr *i = &v->Instr;
	i->UnaryOp.op = op;
	i->UnaryOp.expr = expr;
	i->UnaryOp.type = type;
	return v;
}


ssaValue *ssa_make_instr_binary_op(ssaProcedure *p, TokenKind op, ssaValue *left, ssaValue *right, Type *type) {
	ssaValue *v = ssa_alloc_instr(p, ssaInstr_BinaryOp);
	ssaInstr *i = &v->Instr;
	i->BinaryOp.op = op;
	i->BinaryOp.left = left;
	i->BinaryOp.right = right;
	i->BinaryOp.type = type;
	return v;
}

ssaValue *ssa_make_instr_jump(ssaProcedure *p, ssaBlock *block) {
	ssaValue *v = ssa_alloc_instr(p, ssaInstr_Jump);
	ssaInstr *i = &v->Instr;
	i->Jump.block = block;
	return v;
}
ssaValue *ssa_make_instr_if(ssaProcedure *p, ssaValue *cond, ssaBlock *true_block, ssaBlock *false_block) {
	ssaValue *v = ssa_alloc_instr(p, ssaInstr_If);
	ssaInstr *i = &v->Instr;
	i->If.cond = cond;
	i->If.true_block = true_block;
	i->If.false_block = false_block;
	return v;
}


ssaValue *ssa_make_instr_phi(ssaProcedure *p, ssaValueArray edges, Type *type) {
	ssaValue *v = ssa_alloc_instr(p, ssaInstr_Phi);
	ssaInstr *i = &v->Instr;
	i->Phi.edges = edges;
	i->Phi.type = type;
	return v;
}

ssaValue *ssa_make_instr_unreachable(ssaProcedure *p) {
	ssaValue *v = ssa_alloc_instr(p, ssaInstr_Unreachable);
	return v;
}

ssaValue *ssa_make_instr_return(ssaProcedure *p, ssaValue *value) {
	ssaValue *v = ssa_alloc_instr(p, ssaInstr_Return);
	v->Instr.Return.value = value;
	return v;
}

ssaValue *ssa_make_instr_select(ssaProcedure *p, ssaValue *cond, ssaValue *t, ssaValue *f) {
	ssaValue *v = ssa_alloc_instr(p, ssaInstr_Select);
	v->Instr.Select.cond = cond;
	v->Instr.Select.true_value = t;
	v->Instr.Select.false_value = f;
	return v;
}

ssaValue *ssa_make_instr_call(ssaProcedure *p, ssaValue *value, ssaValue **args, isize arg_count, Type *result_type) {
	ssaValue *v = ssa_alloc_instr(p, ssaInstr_Call);
	v->Instr.Call.value = value;
	v->Instr.Call.args = args;
	v->Instr.Call.arg_count = arg_count;
	v->Instr.Call.type = result_type;
	return v;
}

ssaValue *ssa_make_instr_conv(ssaProcedure *p, ssaConvKind kind, ssaValue *value, Type *from, Type *to) {
	ssaValue *v = ssa_alloc_instr(p, ssaInstr_Conv);
	v->Instr.Conv.kind = kind;
	v->Instr.Conv.value = value;
	v->Instr.Conv.from = from;
	v->Instr.Conv.to = to;
	return v;
}

ssaValue *ssa_make_instr_extract_element(ssaProcedure *p, ssaValue *vector, ssaValue *index) {
	ssaValue *v = ssa_alloc_instr(p, ssaInstr_VectorExtractElement);
	v->Instr.VectorExtractElement.vector = vector;
	v->Instr.VectorExtractElement.index = index;
	return v;
}

ssaValue *ssa_make_instr_insert_element(ssaProcedure *p, ssaValue *vector, ssaValue *elem, ssaValue *index) {
	ssaValue *v = ssa_alloc_instr(p, ssaInstr_VectorInsertElement);
	v->Instr.VectorInsertElement.vector = vector;
	v->Instr.VectorInsertElement.elem   = elem;
	v->Instr.VectorInsertElement.index  = index;
	return v;
}

ssaValue *ssa_make_instr_vector_shuffle(ssaProcedure *p, ssaValue *vector, i32 *indices, isize index_count) {
	ssaValue *v = ssa_alloc_instr(p, ssaInstr_VectorShuffle);
	v->Instr.VectorShuffle.vector      = vector;
	v->Instr.VectorShuffle.indices     = indices;
	v->Instr.VectorShuffle.index_count = index_count;

	Type *vt = base_type(ssa_type(vector));
	v->Instr.VectorShuffle.type = make_type_vector(p->module->allocator, vt->Vector.elem, index_count);

	return v;
}

ssaValue *ssa_make_instr_comment(ssaProcedure *p, String text) {
	ssaValue *v = ssa_alloc_instr(p, ssaInstr_Comment);
	v->Instr.Comment.text = text;
	return v;
}

ssaValue *ssa_make_instr_bounds_check(ssaProcedure *p, TokenPos pos, ssaValue *index, ssaValue *len) {
	ssaValue *v = ssa_alloc_instr(p, ssaInstr_BoundsCheck);
	v->Instr.BoundsCheck.pos   = pos;
	v->Instr.BoundsCheck.index = index;
	v->Instr.BoundsCheck.len   = len;
	return v;
}
ssaValue *ssa_make_instr_slice_bounds_check(ssaProcedure *p, TokenPos pos, ssaValue *low, ssaValue *high, ssaValue *max, bool is_substring) {
	ssaValue *v = ssa_alloc_instr(p, ssaInstr_SliceBoundsCheck);
	v->Instr.SliceBoundsCheck.pos  = pos;
	v->Instr.SliceBoundsCheck.low  = low;
	v->Instr.SliceBoundsCheck.high = high;
	v->Instr.SliceBoundsCheck.max  = max;
	v->Instr.SliceBoundsCheck.is_substring = is_substring;
	return v;
}



ssaValue *ssa_make_value_constant(gbAllocator a, Type *type, ExactValue value) {
	ssaValue *v = ssa_alloc_value(a, ssaValue_Constant);
	v->Constant.type  = type;
	v->Constant.value = value;
	return v;
}


ssaValue *ssa_make_value_constant_slice(gbAllocator a, Type *type, ssaValue *backing_array, i64 count) {
	ssaValue *v = ssa_alloc_value(a, ssaValue_ConstantSlice);
	v->ConstantSlice.type = type;
	v->ConstantSlice.backing_array = backing_array;
	v->ConstantSlice.count = count;
	return v;
}

ssaValue *ssa_make_const_int(gbAllocator a, i64 i) {
	return ssa_make_value_constant(a, t_int, make_exact_value_integer(i));
}
ssaValue *ssa_make_const_i32(gbAllocator a, i64 i) {
	return ssa_make_value_constant(a, t_i32, make_exact_value_integer(i));
}
ssaValue *ssa_make_const_i64(gbAllocator a, i64 i) {
	return ssa_make_value_constant(a, t_i64, make_exact_value_integer(i));
}
ssaValue *ssa_make_const_bool(gbAllocator a, bool b) {
	return ssa_make_value_constant(a, t_bool, make_exact_value_bool(b != 0));
}
ssaValue *ssa_make_const_string(gbAllocator a, String s) {
	return ssa_make_value_constant(a, t_string, make_exact_value_string(s));
}

ssaValue *ssa_make_value_procedure(gbAllocator a, ssaModule *m, Entity *entity, Type *type, AstNode *type_expr, AstNode *body, String name) {
	ssaValue *v = ssa_alloc_value(a, ssaValue_Proc);
	v->Proc.module = m;
	v->Proc.entity = entity;
	v->Proc.type   = type;
	v->Proc.type_expr = type_expr;
	v->Proc.body   = body;
	v->Proc.name   = name;
	array_init(&v->Proc.referrers, heap_allocator()); // TODO(bill): replace heap allocator

	Type *t = base_type(type);
	GB_ASSERT(is_type_proc(t));
	array_init_reserve(&v->Proc.params, heap_allocator(), t->Proc.param_count);

	return v;
}

ssaBlock *ssa_add_block(ssaProcedure *proc, AstNode *node, char *label) {
	Scope *scope = NULL;
	if (node != NULL) {
		Scope **found = map_scope_get(&proc->module->info->scopes, hash_pointer(node));
		if (found) {
			scope = *found;
		} else {
			GB_PANIC("Block scope not found for %.*s", LIT(ast_node_strings[node->kind]));
		}
	}

	ssaValue *v = ssa_alloc_value(proc->module->allocator, ssaValue_Block);
	v->Block.label  = make_string_c(label);
	v->Block.node   = node;
	v->Block.scope  = scope;
	v->Block.parent = proc;

	array_init(&v->Block.instrs, heap_allocator());
	array_init(&v->Block.locals, heap_allocator());

	array_init(&v->Block.preds,  heap_allocator());
	array_init(&v->Block.succs,  heap_allocator());

	ssaBlock *block = &v->Block;

	array_add(&proc->blocks, block);
	proc->block_count++;

	return block;
}





ssaDefer ssa_add_defer_node(ssaProcedure *proc, isize scope_index, AstNode *stmt) {
	ssaDefer d = {ssaDefer_Node};
	d.scope_index = scope_index;
	d.block = proc->curr_block;
	d.stmt = stmt;
	array_add(&proc->defer_stmts, d);
	return d;
}


ssaDefer ssa_add_defer_instr(ssaProcedure *proc, isize scope_index, ssaValue *instr) {
	ssaDefer d = {ssaDefer_Instr};
	d.scope_index = proc->scope_index;
	d.block = proc->curr_block;
	d.instr = instr; // NOTE(bill): It will make a copy everytime it is called
	array_add(&proc->defer_stmts, d);
	return d;
}



ssaValue *ssa_add_module_constant(ssaModule *m, Type *type, ExactValue value) {
	gbAllocator a = m->allocator;
	// gbAllocator a = gb_heap_allocator();

	if (is_type_slice(type)) {
		ast_node(cl, CompoundLit, value.value_compound);

		isize count = cl->elems.count;
		if (count == 0) {
			return ssa_make_value_nil(a, type);
		}
		Type *elem = base_type(type)->Slice.elem;
		Type *t = make_type_array(a, elem, count);
		ssaValue *backing_array = ssa_add_module_constant(m, t, value);


		isize max_len = 7+8+1;
		u8 *str = cast(u8 *)gb_alloc_array(a, u8, max_len);
		isize len = gb_snprintf(cast(char *)str, max_len, "__csba$%x", m->global_array_index);
		m->global_array_index++;

		String name = make_string(str, len-1);

		Entity *e = make_entity_constant(a, NULL, make_token_ident(name), t, value);
		ssaValue *g = ssa_make_value_global(a, e, backing_array);
		ssa_module_add_value(m, e, g);
		map_ssa_value_set(&m->members, hash_string(name), g);

		return ssa_make_value_constant_slice(a, type, g, count);
	}

	return ssa_make_value_constant(a, type, value);
}

ssaValue *ssa_add_global_string_array(ssaModule *m, String string) {
	// TODO(bill): Should this use the arena allocator or the heap allocator?
	// Strings could be huge!
	gbAllocator a = m->allocator;
	// gbAllocator a = gb_heap_allocator();

	isize max_len = 6+8+1;
	u8 *str = cast(u8 *)gb_alloc_array(a, u8, max_len);
	isize len = gb_snprintf(cast(char *)str, max_len, "__str$%x", m->global_string_index);
	m->global_string_index++;

	String name = make_string(str, len-1);
	Token token = {Token_String};
	token.string = name;
	Type *type = make_type_array(a, t_u8, string.len);
	ExactValue ev = make_exact_value_string(string);
	Entity *entity = make_entity_constant(a, NULL, token, type, ev);
	ssaValue *g = ssa_make_value_global(a, entity, ssa_add_module_constant(m, type, ev));
	g->Global.is_private      = true;
	// g->Global.is_unnamed_addr = true;
	// g->Global.is_constant = true;

	ssa_module_add_value(m, entity, g);
	map_ssa_value_set(&m->members, hash_string(name), g);

	return g;
}




ssaValue *ssa_add_local(ssaProcedure *proc, Entity *e) {
	ssaBlock *b = proc->decl_block; // all variables must be in the first block
	ssaValue *instr = ssa_make_instr_local(proc, e, true);
	instr->Instr.parent = b;
	array_add(&b->instrs, instr);
	array_add(&b->locals, instr);
	proc->local_count++;

	// if (zero_initialized) {
		ssa_emit_zero_init(proc, instr);
	// }

	return instr;
}

ssaValue *ssa_add_local_for_identifier(ssaProcedure *proc, AstNode *name, bool zero_initialized) {
	Entity **found = map_entity_get(&proc->module->info->definitions, hash_pointer(name));
	if (found) {
		Entity *e = *found;
		ssa_emit_comment(proc, e->token.string);
		return ssa_add_local(proc, e);
	}
	return NULL;
}

ssaValue *ssa_add_local_generated(ssaProcedure *proc, Type *type) {
	GB_ASSERT(type != NULL);

	Scope *scope = NULL;
	if (proc->curr_block) {
		scope = proc->curr_block->scope;
	}
	Entity *e = make_entity_variable(proc->module->allocator,
	                                 scope,
	                                 empty_token,
	                                 type,
	                                 false);
	return ssa_add_local(proc, e);
}

ssaValue *ssa_add_param(ssaProcedure *proc, Entity *e) {
	ssaValue *v = ssa_make_value_param(proc->module->allocator, proc, e);
#if 1
	ssaValue *l = ssa_add_local(proc, e);
	ssa_emit_store(proc, l, v);
#else
	ssa_module_add_value(proc->module, e, v);
#endif
	return v;
}



////////////////////////////////////////////////////////////////
//
// @Debug
//
////////////////////////////////////////////////////////////////

ssaDebugInfo *ssa_add_debug_info_file(ssaProcedure *proc, AstFile *file) {
	if (!proc->module->generate_debug_info) {
		return NULL;
	}

	GB_ASSERT(file != NULL);
	ssaDebugInfo *di = ssa_alloc_debug_info(proc->module->allocator, ssaDebugInfo_File);
	di->File.file = file;

	String filename = file->tokenizer.fullpath;
	String directory = filename;
	isize slash_index = 0;
	for (isize i = filename.len-1; i >= 0; i--) {
		if (filename.text[i] == '\\' ||
		    filename.text[i] == '/') {
			break;
		}
		slash_index = i;
	}
	directory.len = slash_index-1;
	filename.text = filename.text + slash_index;
	filename.len -= slash_index;


	di->File.filename = filename;
	di->File.directory = directory;

	map_ssa_debug_info_set(&proc->module->debug_info, hash_pointer(file), di);
	return di;
}


ssaDebugInfo *ssa_add_debug_info_proc(ssaProcedure *proc, Entity *entity, String name, ssaDebugInfo *file) {
	if (!proc->module->generate_debug_info) {
		return NULL;
	}

	GB_ASSERT(entity != NULL);
	ssaDebugInfo *di = ssa_alloc_debug_info(proc->module->allocator, ssaDebugInfo_Proc);
	di->Proc.entity = entity;
	di->Proc.name = name;
	di->Proc.file = file;
	di->Proc.pos = entity->token.pos;

	map_ssa_debug_info_set(&proc->module->debug_info, hash_pointer(entity), di);
	return di;
}

////////////////////////////////////////////////////////////////
//
// @Emit
//
////////////////////////////////////////////////////////////////


ssaValue *ssa_emit(ssaProcedure *proc, ssaValue *instr) {
	GB_ASSERT(instr->kind == ssaValue_Instr);
	ssaBlock *b = proc->curr_block;
	instr->Instr.parent = b;
	if (b != NULL) {
		ssaInstr *i = ssa_get_last_instr(b);
		if (!ssa_is_instr_terminating(i)) {
			array_add(&b->instrs, instr);
		}
	}
	return instr;
}
ssaValue *ssa_emit_store(ssaProcedure *p, ssaValue *address, ssaValue *value) {
	return ssa_emit(p, ssa_make_instr_store(p, address, value));
}
ssaValue *ssa_emit_load(ssaProcedure *p, ssaValue *address) {
	return ssa_emit(p, ssa_make_instr_load(p, address));
}
ssaValue *ssa_emit_select(ssaProcedure *p, ssaValue *cond, ssaValue *t, ssaValue *f) {
	return ssa_emit(p, ssa_make_instr_select(p, cond, t, f));
}

ssaValue *ssa_emit_zero_init(ssaProcedure *p, ssaValue *address)  {
	return ssa_emit(p, ssa_make_instr_zero_init(p, address));
}

ssaValue *ssa_emit_comment(ssaProcedure *p, String text) {
	return ssa_emit(p, ssa_make_instr_comment(p, text));
}


ssaValue *ssa_emit_call(ssaProcedure *p, ssaValue *value, ssaValue **args, isize arg_count) {
	Type *pt = base_type(ssa_type(value));
	GB_ASSERT(pt->kind == Type_Proc);
	Type *results = pt->Proc.results;
	return ssa_emit(p, ssa_make_instr_call(p, value, args, arg_count, results));
}

ssaValue *ssa_emit_global_call(ssaProcedure *proc, char *name_, ssaValue **args, isize arg_count) {
	String name = make_string_c(name_);
	ssaValue **found = map_ssa_value_get(&proc->module->members, hash_string(name));
	GB_ASSERT_MSG(found != NULL, "%.*s", LIT(name));
	ssaValue *gp = *found;
	return ssa_emit_call(proc, gp, args, arg_count);
}



void ssa_emit_defer_stmts(ssaProcedure *proc, ssaDeferExitKind kind, ssaBlock *block) {
	isize count = proc->defer_stmts.count;
	isize i = count;
	while (i --> 0) {
		ssaDefer d = proc->defer_stmts.e[i];
		if (kind == ssaDeferExit_Default) {
			if (proc->scope_index == d.scope_index &&
			    d.scope_index > 1) {
				ssa_build_defer_stmt(proc, d);
				array_pop(&proc->defer_stmts);
				continue;
			} else {
				break;
			}
		} else if (kind == ssaDeferExit_Return) {
			ssa_build_defer_stmt(proc, d);
		} else if (kind == ssaDeferExit_Branch) {
			GB_ASSERT(block != NULL);
			isize lower_limit = block->scope_index+1;
			if (lower_limit < d.scope_index) {
				ssa_build_defer_stmt(proc, d);
			}
		}
	}
}


void ssa_open_scope(ssaProcedure *proc) {
	proc->scope_index++;
}

void ssa_close_scope(ssaProcedure *proc, ssaDeferExitKind kind, ssaBlock *block) {
	ssa_emit_defer_stmts(proc, kind, block);
	GB_ASSERT(proc->scope_index > 0);
	proc->scope_index--;
}



void ssa_emit_unreachable(ssaProcedure *proc) {
	ssa_emit(proc, ssa_make_instr_unreachable(proc));
}

void ssa_emit_return(ssaProcedure *proc, ssaValue *v) {
	ssa_emit_defer_stmts(proc, ssaDeferExit_Return, NULL);
	ssa_emit(proc, ssa_make_instr_return(proc, v));
}

void ssa_emit_jump(ssaProcedure *proc, ssaBlock *target_block) {
	ssaBlock *b = proc->curr_block;
	if (b == NULL) {
		return;
	}
	ssa_emit(proc, ssa_make_instr_jump(proc, target_block));
	ssa_add_edge(b, target_block);
	proc->curr_block = NULL;
}

void ssa_emit_if(ssaProcedure *proc, ssaValue *cond, ssaBlock *true_block, ssaBlock *false_block) {
	ssaBlock *b = proc->curr_block;
	if (b == NULL) {
		return;
	}
	ssa_emit(proc, ssa_make_instr_if(proc, cond, true_block, false_block));
	ssa_add_edge(b, true_block);
	ssa_add_edge(b, false_block);
	proc->curr_block = NULL;
}

void ssa_emit_startup_runtime(ssaProcedure *proc) {
	GB_ASSERT(proc->parent == NULL && str_eq(proc->name, str_lit("main")));
	ssa_emit(proc, ssa_alloc_instr(proc, ssaInstr_StartupRuntime));
}




ssaValue *ssa_addr_store(ssaProcedure *proc, ssaAddr addr, ssaValue *value) {
	if (addr.addr == NULL) {
		return NULL;
	}

	if (addr.kind == ssaAddr_Vector) {
		ssaValue *v = ssa_emit_load(proc, addr.addr);
		Type *elem_type = base_type(ssa_type(v))->Vector.elem;
		ssaValue *elem = ssa_emit_conv(proc, value, elem_type);
		ssaValue *out = ssa_emit(proc, ssa_make_instr_insert_element(proc, v, elem, addr.Vector.index));
		return ssa_emit_store(proc, addr.addr, out);
	} else {
		ssaValue *v = ssa_emit_conv(proc, value, ssa_addr_type(addr));
		return ssa_emit_store(proc, addr.addr, v);
	}
}
ssaValue *ssa_addr_load(ssaProcedure *proc, ssaAddr addr) {
	if (addr.addr == NULL) {
		GB_PANIC("Illegal addr load");
		return NULL;
	}

	if (addr.kind == ssaAddr_Vector) {
		ssaValue *v = ssa_emit_load(proc, addr.addr);
		return ssa_emit(proc, ssa_make_instr_extract_element(proc, v, addr.Vector.index));
	}
	Type *t = base_type(ssa_type(addr.addr));
	if (t->kind == Type_Proc) {
		// NOTE(bill): Imported procedures don't require a load as they are pointers
		return addr.addr;
	}
	return ssa_emit_load(proc, addr.addr);
}




ssaValue *ssa_emit_ptr_offset(ssaProcedure *proc, ssaValue *ptr, ssaValue *offset) {
	offset = ssa_emit_conv(proc, offset, t_int);
	return ssa_emit(proc, ssa_make_instr_ptr_offset(proc, ptr, offset));
}

ssaValue *ssa_emit_arith(ssaProcedure *proc, TokenKind op, ssaValue *left, ssaValue *right, Type *type) {
	Type *t_left = ssa_type(left);
	Type *t_right = ssa_type(right);

	if (op == Token_Add) {
		if (is_type_pointer(t_left)) {
			ssaValue *ptr = ssa_emit_conv(proc, left, type);
			ssaValue *offset = right;
			return ssa_emit_ptr_offset(proc, ptr, offset);
		} else if (is_type_pointer(ssa_type(right))) {
			ssaValue *ptr = ssa_emit_conv(proc, right, type);
			ssaValue *offset = left;
			return ssa_emit_ptr_offset(proc, ptr, offset);
		}
	} else if (op == Token_Sub) {
		if (is_type_pointer(t_left) && is_type_integer(t_right)) {
			// ptr - int
			ssaValue *ptr = ssa_emit_conv(proc, left, type);
			ssaValue *offset = right;
			return ssa_emit_ptr_offset(proc, ptr, offset);
		} else if (is_type_pointer(t_left) && is_type_pointer(t_right)) {
			GB_ASSERT(is_type_integer(type));
			Type *ptr_type = t_left;
			ssaModule *m = proc->module;
			ssaValue *x = ssa_emit_conv(proc, left, type);
			ssaValue *y = ssa_emit_conv(proc, right, type);
			ssaValue *diff = ssa_emit_arith(proc, op, x, y, type);
			ssaValue *elem_size = ssa_make_const_int(m->allocator, type_size_of(m->sizes, m->allocator, ptr_type));
			return ssa_emit_arith(proc, Token_Quo, diff, elem_size, type);
		}
	}


	switch (op) {
	case Token_AndNot: {
		// NOTE(bill): x &~ y == x & (~y) == x & (y ~ -1)
		// NOTE(bill): "not" `x` == `x` "xor" `-1`
		ssaValue *neg = ssa_add_module_constant(proc->module, type, make_exact_value_integer(-1));
		op = Token_Xor;
		right = ssa_emit_arith(proc, op, right, neg, type);
		GB_ASSERT(right->Instr.kind == ssaInstr_BinaryOp);
		right->Instr.BinaryOp.type = type;
		op = Token_And;
	} /* fallthrough */
	case Token_Add:
	case Token_Sub:
	case Token_Mul:
	case Token_Quo:
	case Token_Mod:
	case Token_And:
	case Token_Or:
	case Token_Xor:
	case Token_Shl:
	case Token_Shr:
		left  = ssa_emit_conv(proc, left, type);
		right = ssa_emit_conv(proc, right, type);
		break;
	}

	return ssa_emit(proc, ssa_make_instr_binary_op(proc, op, left, right, type));
}

ssaValue *ssa_emit_comp(ssaProcedure *proc, TokenKind op_kind, ssaValue *left, ssaValue *right) {
	Type *a = base_type(ssa_type(left));
	Type *b = base_type(ssa_type(right));

	GB_ASSERT(gb_is_between(op_kind, Token__ComparisonBegin+1, Token__ComparisonEnd-1));

	if (are_types_identical(a, b)) {
		// NOTE(bill): No need for a conversion
	} else if (left->kind == ssaValue_Constant || left->kind == ssaValue_Nil) {
		left = ssa_emit_conv(proc, left, ssa_type(right));
	} else if (right->kind == ssaValue_Constant || right->kind == ssaValue_Nil) {
		right = ssa_emit_conv(proc, right, ssa_type(left));
	}

	Type *result = t_bool;
	if (is_type_vector(a)) {
		result = make_type_vector(proc->module->allocator, t_bool, a->Vector.count);
	}
	return ssa_emit(proc, ssa_make_instr_binary_op(proc, op_kind, left, right, result));
}

ssaValue *ssa_emit_array_ep(ssaProcedure *proc, ssaValue *s, ssaValue *index) {
	GB_ASSERT(index != NULL);
	Type *st = base_type(type_deref(ssa_type(s)));
	GB_ASSERT(is_type_array(st) || is_type_vector(st));

	// NOTE(bill): For some weird legacy reason in LLVM, structure elements must be accessed as an i32
	index = ssa_emit_conv(proc, index, t_i32);
	return ssa_emit(proc, ssa_make_instr_array_element_ptr(proc, s, index));
}

ssaValue *ssa_emit_array_epi(ssaProcedure *proc, ssaValue *s, i32 index) {
	return ssa_emit_array_ep(proc, s, ssa_make_const_i32(proc->module->allocator, index));
}

ssaValue *ssa_emit_union_tag_ptr(ssaProcedure *proc, ssaValue *u) {
	Type *t = ssa_type(u);
	GB_ASSERT(is_type_pointer(t) &&
	          is_type_union(type_deref(t)));
	GB_ASSERT(are_types_identical(t, ssa_type(u)));
	return ssa_emit(proc, ssa_make_instr_union_tag_ptr(proc, u));
}

ssaValue *ssa_emit_union_tag_value(ssaProcedure *proc, ssaValue *u) {
	Type *t = ssa_type(u);
	GB_ASSERT(is_type_union(t));
	GB_ASSERT(are_types_identical(t, ssa_type(u)));
	return ssa_emit(proc, ssa_make_instr_union_tag_value(proc, u));
}



ssaValue *ssa_emit_struct_ep(ssaProcedure *proc, ssaValue *s, i32 index) {
	gbAllocator a = proc->module->allocator;
	Type *t = base_type(type_deref(ssa_type(s)));
	Type *result_type = NULL;
	ssaValue *gep = NULL;

	if (is_type_struct(t)) {
		GB_ASSERT(t->Record.field_count > 0);
		GB_ASSERT(gb_is_between(index, 0, t->Record.field_count-1));
		result_type = make_type_pointer(a, t->Record.fields[index]->type);
	} else if (is_type_tuple(t)) {
		GB_ASSERT(t->Tuple.variable_count > 0);
		GB_ASSERT(gb_is_between(index, 0, t->Tuple.variable_count-1));
		result_type = make_type_pointer(a, t->Tuple.variables[index]->type);
	} else if (is_type_slice(t)) {
		switch (index) {
		case 0: result_type = make_type_pointer(a, make_type_pointer(a, t->Slice.elem)); break;
		case 1: result_type = make_type_pointer(a, t_int); break;
		case 2: result_type = make_type_pointer(a, t_int); break;
		}
	} else if (is_type_string(t)) {
		switch (index) {
		case 0: result_type = make_type_pointer(a, t_u8_ptr); break;
		case 1: result_type = make_type_pointer(a, t_int);    break;
		}
	} else if (is_type_any(t)) {
		switch (index) {
		case 0: result_type = make_type_pointer(a, t_type_info_ptr); break;
		case 1: result_type = make_type_pointer(a, t_rawptr);        break;
		}
	} else if (is_type_maybe(t)) {
		switch (index) {
		case 0: result_type = make_type_pointer(a, t->Maybe.elem); break;
		case 1: result_type = make_type_pointer(a, t_bool);        break;
		}
	} else {
		GB_PANIC("TODO(bill): struct_gep type: %s, %d", type_to_string(ssa_type(s)), index);
	}

	GB_ASSERT(result_type != NULL);

	gep = ssa_make_instr_struct_element_ptr(proc, s, index, result_type);
	return ssa_emit(proc, gep);
}



ssaValue *ssa_emit_array_ev(ssaProcedure *proc, ssaValue *s, i32 index) {
	Type *st = base_type(ssa_type(s));
	GB_ASSERT(is_type_array(st));
	return ssa_emit(proc, ssa_make_instr_array_extract_value(proc, s, index));
}

ssaValue *ssa_emit_struct_ev(ssaProcedure *proc, ssaValue *s, i32 index) {
	// NOTE(bill): For some weird legacy reason in LLVM, structure elements must be accessed as an i32

	gbAllocator a = proc->module->allocator;
	Type *t = base_type(ssa_type(s));
	Type *result_type = NULL;

	if (is_type_struct(t)) {
		GB_ASSERT(t->Record.field_count > 0);
		GB_ASSERT(gb_is_between(index, 0, t->Record.field_count-1));
		result_type = t->Record.fields[index]->type;
	} else if (is_type_tuple(t)) {
		GB_ASSERT(t->Tuple.variable_count > 0);
		GB_ASSERT(gb_is_between(index, 0, t->Tuple.variable_count-1));
		result_type = t->Tuple.variables[index]->type;
	} else if (is_type_slice(t)) {
		switch (index) {
		case 0: result_type = make_type_pointer(a, t->Slice.elem); break;
		case 1: result_type = t_int; break;
		case 2: result_type = t_int; break;
		}
	} else if (is_type_string(t)) {
		switch (index) {
		case 0: result_type = t_u8_ptr; break;
		case 1: result_type = t_int;    break;
		}
	} else if (is_type_any(t)) {
		switch (index) {
		case 0: result_type = t_type_info_ptr; break;
		case 1: result_type = t_rawptr;        break;
		}
	} else if (is_type_maybe(t)) {
		switch (index) {
		case 0: result_type = t->Maybe.elem; break;
		case 1: result_type = t_bool;        break;
		}
	} else {
		GB_PANIC("TODO(bill): struct_ev type: %s, %d", type_to_string(ssa_type(s)), index);
	}

	GB_ASSERT(result_type != NULL);

	return ssa_emit(proc, ssa_make_instr_struct_extract_value(proc, s, index, result_type));
}


ssaValue *ssa_emit_deep_field_gep(ssaProcedure *proc, Type *type, ssaValue *e, Selection sel) {
	GB_ASSERT(sel.index.count > 0);

	for_array(i, sel.index) {
		i32 index = cast(i32)sel.index.e[i];
		if (is_type_pointer(type)) {
			type = type_deref(type);
			e = ssa_emit_load(proc, e);
			e = ssa_emit_ptr_offset(proc, e, v_zero); // TODO(bill): Do I need these copies?
		}
		type = base_type(type);


		if (is_type_raw_union(type)) {
			type = type->Record.fields[index]->type;
			e = ssa_emit_conv(proc, e, make_type_pointer(proc->module->allocator, type));
		} else if (type->kind == Type_Record) {
			type = type->Record.fields[index]->type;
			e = ssa_emit_struct_ep(proc, e, index);
		} else if (type->kind == Type_Basic) {
			switch (type->Basic.kind) {
			case Basic_any: {
				if (index == 0) {
					type = t_type_info_ptr;
				} else if (index == 1) {
					type = t_rawptr;
				}
				e = ssa_emit_struct_ep(proc, e, index);
			} break;

			case Basic_string:
				e = ssa_emit_struct_ep(proc, e, index);
				break;

			default:
				GB_PANIC("un-gep-able type");
				break;
			}
		} else if (type->kind == Type_Slice) {
			e = ssa_emit_struct_ep(proc, e, index);
		} else if (type->kind == Type_Vector) {
			e = ssa_emit_array_epi(proc, e, index);
		} else if (type->kind == Type_Array) {
			e = ssa_emit_array_epi(proc, e, index);
		} else {
			GB_PANIC("un-gep-able type");
		}
	}

	return e;
}


ssaValue *ssa_emit_deep_field_ev(ssaProcedure *proc, Type *type, ssaValue *e, Selection sel) {
	GB_ASSERT(sel.index.count > 0);

	for_array(i, sel.index) {
		i32 index = cast(i32)sel.index.e[i];
		if (is_type_pointer(type)) {
			type = type_deref(type);
			e = ssa_emit_load(proc, e);
			e = ssa_emit_ptr_offset(proc, e, v_zero); // TODO(bill): Do I need these copies?
		}
		type = base_type(type);


		if (is_type_raw_union(type)) {
			GB_PANIC("TODO(bill): IS THIS EVEN CORRECT?");
			type = type->Record.fields[index]->type;
			e = ssa_emit_conv(proc, e, type);
		} else {
			e = ssa_emit_struct_ev(proc, e, index);
		}
	}

	return e;
}




ssaValue *ssa_array_elem(ssaProcedure *proc, ssaValue *array) {
	return ssa_emit_array_ep(proc, array, v_zero32);
}
ssaValue *ssa_array_len(ssaProcedure *proc, ssaValue *array) {
	Type *t = ssa_type(array);
	GB_ASSERT(t->kind == Type_Array);
	return ssa_make_const_int(proc->module->allocator, t->Array.count);
}
ssaValue *ssa_array_cap(ssaProcedure *proc, ssaValue *array) {
	return ssa_array_len(proc, array);
}

ssaValue *ssa_slice_elem(ssaProcedure *proc, ssaValue *slice) {
	Type *t = ssa_type(slice);
	GB_ASSERT(t->kind == Type_Slice);
	return ssa_emit_struct_ev(proc, slice, 0);
}
ssaValue *ssa_slice_len(ssaProcedure *proc, ssaValue *slice) {
	Type *t = ssa_type(slice);
	GB_ASSERT(t->kind == Type_Slice);
	return ssa_emit_struct_ev(proc, slice, 1);
}
ssaValue *ssa_slice_cap(ssaProcedure *proc, ssaValue *slice) {
	Type *t = ssa_type(slice);
	GB_ASSERT(t->kind == Type_Slice);
	return ssa_emit_struct_ev(proc, slice, 2);
}

ssaValue *ssa_string_elem(ssaProcedure *proc, ssaValue *string) {
	Type *t = ssa_type(string);
	GB_ASSERT(t->kind == Type_Basic && t->Basic.kind == Basic_string);
	return ssa_emit_struct_ev(proc, string, 0);
}
ssaValue *ssa_string_len(ssaProcedure *proc, ssaValue *string) {
	Type *t = ssa_type(string);
	GB_ASSERT(t->kind == Type_Basic && t->Basic.kind == Basic_string);
	return ssa_emit_struct_ev(proc, string, 1);
}



ssaValue *ssa_add_local_slice(ssaProcedure *proc, Type *slice_type, ssaValue *base, ssaValue *low, ssaValue *high, ssaValue *max) {
	// TODO(bill): array bounds checking for slice creation
	// TODO(bill): check that low < high <= max
	gbAllocator a = proc->module->allocator;
	Type *bt = base_type(ssa_type(base));

	if (low == NULL) {
		low = v_zero;
	}
	if (high == NULL) {
		switch (bt->kind) {
		case Type_Array:   high = ssa_array_len(proc, base); break;
		case Type_Slice:   high = ssa_slice_len(proc, base); break;
		case Type_Pointer: high = v_one;                     break;
		}
	}
	if (max == NULL) {
		switch (bt->kind) {
		case Type_Array:   max = ssa_array_cap(proc, base); break;
		case Type_Slice:   max = ssa_slice_cap(proc, base); break;
		case Type_Pointer: max = high;                      break;
		}
	}
	GB_ASSERT(max != NULL);

	ssaValue *len = ssa_emit_arith(proc, Token_Sub, high, low, t_int);
	ssaValue *cap = ssa_emit_arith(proc, Token_Sub, max,  low, t_int);

	ssaValue *elem = NULL;
	switch (bt->kind) {
	case Type_Array:   elem = ssa_array_elem(proc, base); break;
	case Type_Slice:   elem = ssa_slice_elem(proc, base); break;
	case Type_Pointer: elem = ssa_emit_load(proc, base);  break;
	}

	elem = ssa_emit_ptr_offset(proc, elem, low);

	ssaValue *slice = ssa_add_local_generated(proc, slice_type);

	ssaValue *gep = NULL;
	gep = ssa_emit_struct_ep(proc, slice, 0);
	ssa_emit_store(proc, gep, elem);

	gep = ssa_emit_struct_ep(proc, slice, 1);
	ssa_emit_store(proc, gep, len);

	gep = ssa_emit_struct_ep(proc, slice, 2);
	ssa_emit_store(proc, gep, cap);

	return slice;
}

ssaValue *ssa_emit_string(ssaProcedure *proc, ssaValue *elem, ssaValue *len) {
	ssaValue *str = ssa_add_local_generated(proc, t_string);
	ssaValue *str_elem = ssa_emit_struct_ep(proc, str, 0);
	ssaValue *str_len = ssa_emit_struct_ep(proc, str, 1);
	ssa_emit_store(proc, str_elem, elem);
	ssa_emit_store(proc, str_len, len);
	return ssa_emit_load(proc, str);
}




String lookup_polymorphic_field(CheckerInfo *info, Type *dst, Type *src) {
	Type *prev_src = src;
	// Type *prev_dst = dst;
	src = base_type(type_deref(src));
	// dst = base_type(type_deref(dst));
	bool src_is_ptr = src != prev_src;
	// bool dst_is_ptr = dst != prev_dst;

	GB_ASSERT(is_type_struct(src));
	for (isize i = 0; i < src->Record.field_count; i++) {
		Entity *f = src->Record.fields[i];
		if (f->kind == Entity_Variable && f->flags & EntityFlag_Anonymous) {
			if (are_types_identical(dst, f->type)) {
				return f->token.string;
			}
			if (src_is_ptr && is_type_pointer(dst)) {
				if (are_types_identical(type_deref(dst), f->type)) {
					return f->token.string;
				}
			}
			if (is_type_struct(f->type)) {
				String name = lookup_polymorphic_field(info, dst, f->type);
				if (name.len > 0) {
					return name;
				}
			}
		}
	}
	return str_lit("");
}

ssaValue *ssa_emit_bitcast(ssaProcedure *proc, ssaValue *data, Type *type) {
	return ssa_emit(proc, ssa_make_instr_conv(proc, ssaConv_bitcast, data, ssa_type(data), type));
}


ssaValue *ssa_emit_conv(ssaProcedure *proc, ssaValue *value, Type *t) {
	Type *src_type = ssa_type(value);
	if (are_types_identical(t, src_type)) {
		return value;
	}

	Type *src = base_type(src_type);
	Type *dst = base_type(t);

	if (value->kind == ssaValue_Constant) {
		if (is_type_any(dst)) {
			ssaValue *default_value = ssa_add_local_generated(proc, default_type(src_type));
			ssa_emit_store(proc, default_value, value);
			return ssa_emit_conv(proc, ssa_emit_load(proc, default_value), t_any);
		} else if (dst->kind == Type_Basic) {
			ExactValue ev = value->Constant.value;
			if (is_type_float(dst)) {
				ev = exact_value_to_float(ev);
			} else if (is_type_string(dst)) {
				// Handled elsewhere
				GB_ASSERT(ev.kind == ExactValue_String);
			} else if (is_type_integer(dst)) {
				ev = exact_value_to_integer(ev);
			} else if (is_type_pointer(dst)) {
				// IMPORTANT NOTE(bill): LLVM doesn't support pointer constants expect `null`
				ssaValue *i = ssa_add_module_constant(proc->module, t_uint, ev);
				return ssa_emit(proc, ssa_make_instr_conv(proc, ssaConv_inttoptr, i, t_uint, dst));
			}
			return ssa_add_module_constant(proc->module, t, ev);
		}
	}

	if (are_types_identical(src, dst)) {
		return value;
	}

	if (is_type_maybe(dst)) {
		ssaValue *maybe = ssa_add_local_generated(proc, dst);
		ssaValue *val = ssa_emit_struct_ep(proc, maybe, 0);
		ssaValue *set = ssa_emit_struct_ep(proc, maybe, 1);
		ssa_emit_store(proc, val, value);
		ssa_emit_store(proc, set, v_true);
		return ssa_emit_load(proc, maybe);
	}

	// integer -> integer
	if (is_type_integer(src) && is_type_integer(dst)) {
		GB_ASSERT(src->kind == Type_Basic &&
		          dst->kind == Type_Basic);
		i64 sz = type_size_of(proc->module->sizes, proc->module->allocator, src);
		i64 dz = type_size_of(proc->module->sizes, proc->module->allocator, dst);
		if (sz == dz) {
			// NOTE(bill): In LLVM, all integers are signed and rely upon 2's compliment
			return value;
		}

		ssaConvKind kind = ssaConv_trunc;
		if (dz >= sz) {
			kind = ssaConv_zext;
		}
		return ssa_emit(proc, ssa_make_instr_conv(proc, kind, value, src, dst));
	}

	// boolean -> integer
	if (is_type_boolean(src) && is_type_integer(dst)) {
		return ssa_emit(proc, ssa_make_instr_conv(proc, ssaConv_zext, value, src, dst));
	}

	// integer -> boolean
	if (is_type_integer(src) && is_type_boolean(dst)) {
		return ssa_emit_comp(proc, Token_NotEq, value, v_zero);
	}


	// float -> float
	if (is_type_float(src) && is_type_float(dst)) {
		i64 sz = type_size_of(proc->module->sizes, proc->module->allocator, src);
		i64 dz = type_size_of(proc->module->sizes, proc->module->allocator, dst);
		ssaConvKind kind = ssaConv_fptrunc;
		if (dz >= sz) {
			kind = ssaConv_fpext;
		}
		return ssa_emit(proc, ssa_make_instr_conv(proc, kind, value, src, dst));
	}

	// float <-> integer
	if (is_type_float(src) && is_type_integer(dst)) {
		ssaConvKind kind = ssaConv_fptosi;
		if (is_type_unsigned(dst)) {
			kind = ssaConv_fptoui;
		}
		return ssa_emit(proc, ssa_make_instr_conv(proc, kind, value, src, dst));
	}
	if (is_type_integer(src) && is_type_float(dst)) {
		ssaConvKind kind = ssaConv_sitofp;
		if (is_type_unsigned(src)) {
			kind = ssaConv_uitofp;
		}
		return ssa_emit(proc, ssa_make_instr_conv(proc, kind, value, src, dst));
	}

	// Pointer <-> int
	if (is_type_pointer(src) && is_type_int_or_uint(dst)) {
		return ssa_emit(proc, ssa_make_instr_conv(proc, ssaConv_ptrtoint, value, src, dst));
	}
	if (is_type_int_or_uint(src) && is_type_pointer(dst)) {
		return ssa_emit(proc, ssa_make_instr_conv(proc, ssaConv_inttoptr, value, src, dst));
	}

	if (is_type_union(dst)) {
		for (isize i = 0; i < dst->Record.field_count; i++) {
			Entity *f = dst->Record.fields[i];
			if (are_types_identical(f->type, src_type)) {
				ssa_emit_comment(proc, str_lit("union - child to parent"));
				gbAllocator allocator = proc->module->allocator;
				ssaValue *parent = ssa_add_local_generated(proc, t);
				ssaValue *tag = ssa_make_const_int(allocator, i);
				ssa_emit_store(proc, ssa_emit_union_tag_ptr(proc, parent), tag);

				ssaValue *data = ssa_emit_conv(proc, parent, t_rawptr);

				Type *tag_type = src_type;
				Type *tag_type_ptr = make_type_pointer(allocator, tag_type);
				ssaValue *underlying = ssa_emit_bitcast(proc, data, tag_type_ptr);
				ssa_emit_store(proc, underlying, value);

				return ssa_emit_load(proc, parent);
			}
		}
	}

	// NOTE(bill): This has to be done beofre `Pointer <-> Pointer` as it's
	// subtype polymorphism casting
	{
		Type *sb = base_type(type_deref(src));
		bool src_is_ptr = src != sb;
		if (is_type_struct(sb)) {
			String field_name = lookup_polymorphic_field(proc->module->info, t, src);
			// gb_printf("field_name: %.*s\n", LIT(field_name));
			if (field_name.len > 0) {
				// NOTE(bill): It can be casted
				Selection sel = lookup_field(proc->module->allocator, sb, field_name, false);
				if (sel.entity != NULL) {
					ssa_emit_comment(proc, str_lit("cast - polymorphism"));
					if (src_is_ptr) {
						value = ssa_emit_load(proc, value);
					}
					return ssa_emit_deep_field_ev(proc, sb, value, sel);
				}
			}
		}
	}



	// Pointer <-> Pointer
	if (is_type_pointer(src) && is_type_pointer(dst)) {
		return ssa_emit_bitcast(proc, value, dst);
	}



	// proc <-> proc
	if (is_type_proc(src) && is_type_proc(dst)) {
		return ssa_emit_bitcast(proc, value, dst);
	}

	// pointer -> proc
	if (is_type_pointer(src) && is_type_proc(dst)) {
		return ssa_emit_bitcast(proc, value, dst);
	}
	// proc -> pointer
	if (is_type_proc(src) && is_type_pointer(dst)) {
		return ssa_emit_bitcast(proc, value, dst);
	}



	// []byte/[]u8 <-> string
	if (is_type_u8_slice(src) && is_type_string(dst)) {
		ssaValue *elem = ssa_slice_elem(proc, value);
		ssaValue *len  = ssa_slice_len(proc, value);
		return ssa_emit_string(proc, elem, len);
	}
	if (is_type_string(src) && is_type_u8_slice(dst)) {
		ssaValue *elem = ssa_string_elem(proc, value);
		ssaValue *elem_ptr = ssa_add_local_generated(proc, ssa_type(elem));
		ssa_emit_store(proc, elem_ptr, elem);

		ssaValue *len  = ssa_string_len(proc, value);
		ssaValue *slice = ssa_add_local_slice(proc, dst, elem_ptr, v_zero, len, len);
		return ssa_emit_load(proc, slice);
	}

	if (is_type_vector(dst)) {
		Type *dst_elem = dst->Vector.elem;
		value = ssa_emit_conv(proc, value, dst_elem);
		ssaValue *v = ssa_add_local_generated(proc, t);
		v = ssa_emit_load(proc, v);
		v = ssa_emit(proc, ssa_make_instr_insert_element(proc, v, value, v_zero32));
		// NOTE(bill): Broadcast lowest value to all values
		isize index_count = dst->Vector.count;
		i32 *indices = gb_alloc_array(proc->module->allocator, i32, index_count);
		for (isize i = 0; i < index_count; i++) {
			indices[i] = 0;
		}

		v = ssa_emit(proc, ssa_make_instr_vector_shuffle(proc, v, indices, index_count));
		return v;
	}

	if (is_type_any(dst)) {
		ssaValue *result = ssa_add_local_generated(proc, t_any);

		if (is_type_untyped_nil(src)) {
			return ssa_emit_load(proc, result);
		}

		ssaValue *data = NULL;
		if (value->kind == ssaValue_Instr &&
		    value->Instr.kind == ssaInstr_Load) {
			// NOTE(bill): Addressable value
			data = value->Instr.Load.address;
		} else {
			// NOTE(bill): Non-addressable value
			data = ssa_add_local_generated(proc, src_type);
			ssa_emit_store(proc, data, value);
		}
		GB_ASSERT(is_type_pointer(ssa_type(data)));
		GB_ASSERT(is_type_typed(src_type));
		data = ssa_emit_conv(proc, data, t_rawptr);


		ssaValue *ti = ssa_type_info(proc, src_type);

		ssaValue *gep0 = ssa_emit_struct_ep(proc, result, 0);
		ssaValue *gep1 = ssa_emit_struct_ep(proc, result, 1);
		ssa_emit_store(proc, gep0, ti);
		ssa_emit_store(proc, gep1, data);

		return ssa_emit_load(proc, result);
	}

	if (is_type_untyped_nil(src) && type_has_nil(dst)) {
		return ssa_make_value_nil(proc->module->allocator, t);
	}


	gb_printf_err("ssa_emit_conv: src -> dst\n");
	gb_printf_err("Not Identical %s != %s\n", type_to_string(src_type), type_to_string(t));
	gb_printf_err("Not Identical %s != %s\n", type_to_string(src), type_to_string(dst));


	GB_PANIC("Invalid type conversion: `%s` to `%s`", type_to_string(src_type), type_to_string(t));

	return NULL;
}

bool ssa_is_type_aggregate(Type *t) {
	t = base_type(t);
	switch (t->kind) {
	case Type_Basic:
		switch (t->Basic.kind) {
		case Basic_string:
		case Basic_any:
			return true;
		}
		break;

	case Type_Pointer:
	case Type_Vector:
		return false;

	case Type_Array:
	case Type_Slice:
	case Type_Maybe:
	case Type_Record:
	case Type_Tuple:
		return true;

	case Type_Named:
		return ssa_is_type_aggregate(t->Named.base);
	}

	return false;
}

ssaValue *ssa_emit_transmute(ssaProcedure *proc, ssaValue *value, Type *t) {
	Type *src_type = ssa_type(value);
	if (are_types_identical(t, src_type)) {
		return value;
	}

	Type *src = base_type(src_type);
	Type *dst = base_type(t);
	if (are_types_identical(t, src_type)) {
		return value;
	}

	ssaModule *m = proc->module;

	i64 sz = type_size_of(m->sizes, m->allocator, src);
	i64 dz = type_size_of(m->sizes, m->allocator, dst);

	GB_ASSERT_MSG(sz == dz, "Invalid transmute conversion: `%s` to `%s`", type_to_string(src_type), type_to_string(t));

	if (ssa_is_type_aggregate(src) || ssa_is_type_aggregate(dst)) {
		ssaValue *s = ssa_add_local_generated(proc, src);
		ssa_emit_store(proc, s, value);

		ssaValue *d = ssa_emit_bitcast(proc, s, make_type_pointer(m->allocator, dst));
		return ssa_emit_load(proc, d);
	}

	// TODO(bill): Actually figure out what the conversion needs to be correctly 'cause LLVM

	return ssa_emit_bitcast(proc, value, dst);
}

ssaValue *ssa_emit_down_cast(ssaProcedure *proc, ssaValue *value, Type *t) {
	GB_ASSERT(is_type_pointer(ssa_type(value)));
	gbAllocator allocator = proc->module->allocator;

	String field_name = check_down_cast_name(t, type_deref(ssa_type(value)));
	GB_ASSERT(field_name.len > 0);
	Selection sel = lookup_field(proc->module->allocator, t, field_name, false);
	ssaValue *bytes = ssa_emit_conv(proc, value, t_u8_ptr);

	i64 offset_ = type_offset_of_from_selection(proc->module->sizes, allocator, type_deref(t), sel);
	ssaValue *offset = ssa_make_const_int(allocator, -offset_);
	ssaValue *head = ssa_emit_ptr_offset(proc, bytes, offset);
	return ssa_emit_conv(proc, head, t);
}

ssaValue *ssa_emit_union_cast(ssaProcedure *proc, ssaValue *value, Type *tuple) {
	GB_ASSERT(tuple->kind == Type_Tuple);
	gbAllocator a = proc->module->allocator;

	Type *src_type = ssa_type(value);
	bool is_ptr = is_type_pointer(src_type);

	ssaValue *v = ssa_add_local_generated(proc, tuple);

	if (is_ptr) {
		Type *src = base_type(type_deref(src_type));
		Type *src_ptr = src_type;
		GB_ASSERT(is_type_union(src));
		Type *dst_ptr = tuple->Tuple.variables[0]->type;
		Type *dst = type_deref(dst_ptr);

		ssaValue *tag = ssa_emit_load(proc, ssa_emit_union_tag_ptr(proc, value));
		ssaValue *dst_tag = NULL;
		for (isize i = 1; i < src->Record.field_count; i++) {
			Entity *f = src->Record.fields[i];
			if (are_types_identical(f->type, dst)) {
				dst_tag = ssa_make_const_int(a, i);
				break;
			}
		}
		GB_ASSERT(dst_tag != NULL);

		ssaBlock *ok_block = ssa_add_block(proc, NULL, "union_cast.ok");
		ssaBlock *end_block = ssa_add_block(proc, NULL, "union_cast.end");
		ssaValue *cond = ssa_emit_comp(proc, Token_CmpEq, tag, dst_tag);
		ssa_emit_if(proc, cond, ok_block, end_block);
		proc->curr_block = ok_block;

		ssaValue *gep0 = ssa_emit_struct_ep(proc, v, 0);
		ssaValue *gep1 = ssa_emit_struct_ep(proc, v, 1);

		ssaValue *data = ssa_emit_conv(proc, value, dst_ptr);
		ssa_emit_store(proc, gep0, data);
		ssa_emit_store(proc, gep1, v_true);

		ssa_emit_jump(proc, end_block);
		proc->curr_block = end_block;

	} else {
		Type *src = base_type(src_type);
		GB_ASSERT(is_type_union(src));
		Type *dst = tuple->Tuple.variables[0]->type;
		Type *dst_ptr = make_type_pointer(a, dst);

		ssaValue *tag = ssa_emit_union_tag_value(proc, value);
		ssaValue *dst_tag = NULL;
		for (isize i = 1; i < src->Record.field_count; i++) {
			Entity *f = src->Record.fields[i];
			if (are_types_identical(f->type, dst)) {
				dst_tag = ssa_make_const_int(a, i);
				break;
			}
		}
		GB_ASSERT(dst_tag != NULL);

		// HACK(bill): This is probably not very efficient
		ssaValue *union_copy = ssa_add_local_generated(proc, src_type);
		ssa_emit_store(proc, union_copy, value);

		ssaBlock *ok_block = ssa_add_block(proc, NULL, "union_cast.ok");
		ssaBlock *end_block = ssa_add_block(proc, NULL, "union_cast.end");
		ssaValue *cond = ssa_emit_comp(proc, Token_CmpEq, tag, dst_tag);
		ssa_emit_if(proc, cond, ok_block, end_block);
		proc->curr_block = ok_block;

		ssaValue *gep0 = ssa_emit_struct_ep(proc, v, 0);
		ssaValue *gep1 = ssa_emit_struct_ep(proc, v, 1);

		ssaValue *data = ssa_emit_load(proc, ssa_emit_conv(proc, union_copy, dst_ptr));
		ssa_emit_store(proc, gep0, data);
		ssa_emit_store(proc, gep1, v_true);

		ssa_emit_jump(proc, end_block);
		proc->curr_block = end_block;

	}
	return ssa_emit_load(proc, v);
}


isize ssa_type_info_index(CheckerInfo *info, Type *type) {
	type = default_type(type);

	isize entry_index = -1;
	HashKey key = hash_pointer(type);
	isize *found_entry_index = map_isize_get(&info->type_info_map, key);
	if (found_entry_index) {
		entry_index = *found_entry_index;
	}
	if (entry_index < 0) {
		// NOTE(bill): Do manual search
		// TODO(bill): This is O(n) and can be very slow
		for_array(i, info->type_info_map.entries){
			MapIsizeEntry *e = &info->type_info_map.entries.e[i];
			Type *prev_type = cast(Type *)e->key.ptr;
			if (are_types_identical(prev_type, type)) {
				entry_index = e->value;
				// NOTE(bill): Add it to the search map
				map_isize_set(&info->type_info_map, key, entry_index);
				break;
			}
		}
	}

	if (entry_index < 0) {
		compiler_error("Type_Info for `%s` could not be found", type_to_string(type));
	}
	return entry_index;
}

ssaValue *ssa_type_info(ssaProcedure *proc, Type *type) {
	ssaValue **found = map_ssa_value_get(&proc->module->members, hash_string(str_lit(SSA_TYPE_INFO_DATA_NAME)));
	GB_ASSERT(found != NULL);
	ssaValue *type_info_data = *found;
	CheckerInfo *info = proc->module->info;

	type = default_type(type);

	i32 entry_index = ssa_type_info_index(info, type);

	// gb_printf_err("%d %s\n", entry_index, type_to_string(type));

	return ssa_emit_array_ep(proc, type_info_data, ssa_make_const_i32(proc->module->allocator, entry_index));
}



ssaValue *ssa_emit_logical_binary_expr(ssaProcedure *proc, AstNode *expr) {
	ast_node(be, BinaryExpr, expr);
#if 0
	ssaBlock *true_   = ssa_add_block(proc, NULL, "logical.cmp.true");
	ssaBlock *false_  = ssa_add_block(proc, NULL, "logical.cmp.false");
	ssaBlock *done  = ssa_add_block(proc, NULL, "logical.cmp.done");

	ssaValue *result = ssa_add_local_generated(proc, t_bool);
	ssa_build_cond(proc, expr, true_, false_);

	proc->curr_block = true_;
	ssa_emit_store(proc, result, v_true);
	ssa_emit_jump(proc, done);

	proc->curr_block = false_;
	ssa_emit_store(proc, result, v_false);
	ssa_emit_jump(proc, done);

	proc->curr_block = done;

	return ssa_emit_load(proc, result);
#else
	ssaBlock *rhs = ssa_add_block(proc, NULL, "logical.cmp.rhs");
	ssaBlock *done = ssa_add_block(proc, NULL, "logical.cmp.done");

	Type *type = type_of_expr(proc->module->info, expr);
	type = default_type(type);

	ssaValue *short_circuit = NULL;
	if (be->op.kind == Token_CmpAnd) {
		ssa_build_cond(proc, be->left, rhs, done);
		short_circuit = v_false;
	} else if (be->op.kind == Token_CmpOr) {
		ssa_build_cond(proc, be->left, done, rhs);
		short_circuit = v_true;
	}

	if (rhs->preds.count == 0) {
		proc->curr_block = done;
		return short_circuit;
	}

	if (done->preds.count == 0) {
		proc->curr_block = rhs;
		return ssa_build_expr(proc, be->right);
	}

	ssaValueArray edges = {0};
	array_init_reserve(&edges, proc->module->allocator, done->preds.count+1);
	for_array(i, done->preds) {
		array_add(&edges, short_circuit);
	}

	proc->curr_block = rhs;
	array_add(&edges, ssa_build_expr(proc, be->right));
	ssa_emit_jump(proc, done);
	proc->curr_block = done;

	return ssa_emit(proc, ssa_make_instr_phi(proc, edges, type));
#endif
}


void ssa_emit_bounds_check(ssaProcedure *proc, Token token, ssaValue *index, ssaValue *len) {
	if ((proc->module->stmt_state_flags & StmtStateFlag_no_bounds_check) != 0) {
		return;
	}

	index = ssa_emit_conv(proc, index, t_int);
	len = ssa_emit_conv(proc, len, t_int);

	ssa_emit(proc, ssa_make_instr_bounds_check(proc, token.pos, index, len));

	// gbAllocator a = proc->module->allocator;
	// ssaValue **args = gb_alloc_array(a, ssaValue *, 5);
	// args[0] = ssa_emit_global_string(proc, token.pos.file);
	// args[1] = ssa_make_const_int(a, token.pos.line);
	// args[2] = ssa_make_const_int(a, token.pos.column);
	// args[3] = ssa_emit_conv(proc, index, t_int);
	// args[4] = ssa_emit_conv(proc, len, t_int);

	// ssa_emit_global_call(proc, "__bounds_check_error", args, 5);
}

void ssa_emit_slice_bounds_check(ssaProcedure *proc, Token token, ssaValue *low, ssaValue *high, ssaValue *max, bool is_substring) {
	if ((proc->module->stmt_state_flags & StmtStateFlag_no_bounds_check) != 0) {
		return;
	}

	low  = ssa_emit_conv(proc, low,  t_int);
	high = ssa_emit_conv(proc, high, t_int);
	max  = ssa_emit_conv(proc, max,  t_int);

	ssa_emit(proc, ssa_make_instr_slice_bounds_check(proc, token.pos, low, high, max, is_substring));
}


////////////////////////////////////////////////////////////////
//
// @Build
//
////////////////////////////////////////////////////////////////


void ssa_push_target_list(ssaProcedure *proc, ssaBlock *break_, ssaBlock *continue_, ssaBlock *fallthrough_) {
	ssaTargetList *tl = gb_alloc_item(proc->module->allocator, ssaTargetList);
	tl->prev          = proc->target_list;
	tl->break_        = break_;
	tl->continue_     = continue_;
	tl->fallthrough_  = fallthrough_;
	proc->target_list = tl;
}

void ssa_pop_target_list(ssaProcedure *proc) {
	proc->target_list = proc->target_list->prev;
}


void ssa_mangle_sub_type_name(ssaModule *m, Entity *field, String parent) {
	if (field->kind != Entity_TypeName) {
		return;
	}
	String cn = field->token.string;

	isize len = parent.len + 1 + cn.len;
	String child = {NULL, len};
	child.text = gb_alloc_array(m->allocator, u8, len);

	isize i = 0;
	gb_memmove(child.text+i, parent.text, parent.len);
	i += parent.len;
	child.text[i++] = '.';
	gb_memmove(child.text+i, cn.text, cn.len);

	map_string_set(&m->type_names, hash_pointer(field->type), child);
	ssa_gen_global_type_name(m, field, child);
}

void ssa_gen_global_type_name(ssaModule *m, Entity *e, String name) {
	ssaValue *t = ssa_make_value_type_name(m->allocator, name, e->type);
	ssa_module_add_value(m, e, t);
	map_ssa_value_set(&m->members, hash_string(name), t);

	if (is_type_union(e->type)) {
		Type *bt = base_type(e->type);
		TypeRecord *s = &bt->Record;
		// NOTE(bill): Zeroth entry is null (for `match type` stmts)
		for (isize j = 1; j < s->field_count; j++) {
			ssa_mangle_sub_type_name(m, s->fields[j], name);
		}
	}
}




void ssa_build_defer_stmt(ssaProcedure *proc, ssaDefer d) {
	ssaBlock *b = ssa_add_block(proc, NULL, "defer");
	// NOTE(bill): The prev block may defer injection before it's terminator
	ssaInstr *last_instr = ssa_get_last_instr(proc->curr_block);
	if (last_instr == NULL || !ssa_is_instr_terminating(last_instr)) {
		ssa_emit_jump(proc, b);
	}
	proc->curr_block = b;
	ssa_emit_comment(proc, str_lit("defer"));
	if (d.kind == ssaDefer_Node) {
		ssa_build_stmt(proc, d.stmt);
	} else if (d.kind == ssaDefer_Instr) {
		// NOTE(bill): Need to make a new copy
		ssaValue *instr = cast(ssaValue *)gb_alloc_copy(proc->module->allocator, d.instr, gb_size_of(ssaValue));
		ssa_emit(proc, instr);
	}
}



ssaValue *ssa_find_global_variable(ssaProcedure *proc, String name) {
	ssaValue **value = map_ssa_value_get(&proc->module->members, hash_string(name));
	GB_ASSERT_MSG(value != NULL, "Unable to find global variable `%.*s`", LIT(name));
	return *value;
}

ssaValue *ssa_find_implicit_value_backing(ssaProcedure *proc, ImplicitValueId id) {
	Entity *e = proc->module->info->implicit_values[id];
	GB_ASSERT(e->kind == Entity_ImplicitValue);
	Entity *backing = e->ImplicitValue.backing;
	ssaValue **value = map_ssa_value_get(&proc->module->values, hash_pointer(backing));
	GB_ASSERT_MSG(value != NULL, "Unable to find implicit value backing `%.*s`", LIT(backing->token.string));
	return *value;
}



ssaValue *ssa_build_single_expr(ssaProcedure *proc, AstNode *expr, TypeAndValue *tv) {
	expr = unparen_expr(expr);
	switch (expr->kind) {
	case_ast_node(bl, BasicLit, expr);
		GB_PANIC("Non-constant basic literal");
	case_end;

	case_ast_node(i, Ident, expr);
		Entity *e = *map_entity_get(&proc->module->info->uses, hash_pointer(expr));
		if (e->kind == Entity_Builtin) {
			Token token = ast_node_token(expr);
			GB_PANIC("TODO(bill): ssa_build_single_expr Entity_Builtin `%.*s`\n"
			         "\t at %.*s(%td:%td)", LIT(builtin_procs[e->Builtin.id].name),
			         LIT(token.pos.file), token.pos.line, token.pos.column);
			return NULL;
		} else if (e->kind == Entity_Nil) {
			return ssa_make_value_nil(proc->module->allocator, tv->type);
		} else if (e->kind == Entity_ImplicitValue) {
			return ssa_emit_load(proc, ssa_find_implicit_value_backing(proc, e->ImplicitValue.id));
		}

		ssaValue **found = map_ssa_value_get(&proc->module->values, hash_pointer(e));
		if (found) {
			ssaValue *v = *found;
			if (v->kind == ssaValue_Proc) {
				return v;
			}
			// if (e->kind == Entity_Variable && e->Variable.param) {
				// return v;
			// }
			return ssa_emit_load(proc, v);
		} else if (e != NULL && e->kind == Entity_Variable) {
			return ssa_addr_load(proc, ssa_build_addr(proc, expr));
		}
		GB_PANIC("nil value for expression from identifier: %.*s", LIT(i->string));
		return NULL;
	case_end;

	case_ast_node(re, RunExpr, expr);
		// TODO(bill): Run Expression
		return ssa_build_single_expr(proc, re->expr, tv);
	case_end;

	case_ast_node(de, DerefExpr, expr);
		return ssa_addr_load(proc, ssa_build_addr(proc, expr));
	case_end;

	case_ast_node(se, SelectorExpr, expr);
		TypeAndValue *tav = map_tav_get(&proc->module->info->types, hash_pointer(expr));
		GB_ASSERT(tav != NULL);
		return ssa_addr_load(proc, ssa_build_addr(proc, expr));
	case_end;

	case_ast_node(ue, UnaryExpr, expr);
		switch (ue->op.kind) {
		case Token_Pointer:
			return ssa_emit_ptr_offset(proc, ssa_build_addr(proc, ue->expr).addr, v_zero); // Make a copy of the pointer

		case Token_Maybe:
			return ssa_emit_conv(proc, ssa_build_expr(proc, ue->expr), type_of_expr(proc->module->info, expr));

		case Token_Add:
			return ssa_build_expr(proc, ue->expr);

		case Token_Not: // Boolean not
		case Token_Xor: // Bitwise not
		case Token_Sub: // Bitwise not
			return ssa_emit(proc, ssa_make_instr_unary_op(proc, ue->op.kind, ssa_build_expr(proc, ue->expr), tv->type));
		}
	case_end;

	case_ast_node(be, BinaryExpr, expr);
		ssaValue *left = ssa_build_expr(proc, be->left);
		Type *type = default_type(tv->type);

		switch (be->op.kind) {
		case Token_Add:
		case Token_Sub:
		case Token_Mul:
		case Token_Quo:
		case Token_Mod:
		case Token_And:
		case Token_Or:
		case Token_Xor:
		case Token_AndNot:
		case Token_Shl:
		case Token_Shr: {
			ssaValue *right = ssa_build_expr(proc, be->right);
			return ssa_emit_arith(proc, be->op.kind, left, right, type);
		}


		case Token_CmpEq:
		case Token_NotEq:
		case Token_Lt:
		case Token_LtEq:
		case Token_Gt:
		case Token_GtEq: {
			ssaValue *right = ssa_build_expr(proc, be->right);
			ssaValue *cmp = ssa_emit_comp(proc, be->op.kind, left, right);
			return ssa_emit_conv(proc, cmp, type);
		} break;

		case Token_CmpAnd:
		case Token_CmpOr:
			return ssa_emit_logical_binary_expr(proc, expr);

		case Token_as:
			ssa_emit_comment(proc, str_lit("cast - as"));
			return ssa_emit_conv(proc, left, type);

		case Token_transmute:
			ssa_emit_comment(proc, str_lit("cast - transmute"));
			return ssa_emit_transmute(proc, left, type);

		case Token_down_cast:
			ssa_emit_comment(proc, str_lit("cast - down_cast"));
			return ssa_emit_down_cast(proc, left, type);

		case Token_union_cast:
			ssa_emit_comment(proc, str_lit("cast - union_cast"));
			return ssa_emit_union_cast(proc, left, type);

		default:
			GB_PANIC("Invalid binary expression");
			break;
		}
	case_end;

	case_ast_node(pl, ProcLit, expr);
		// NOTE(bill): Generate a new name
		// parent$count
		isize name_len = proc->name.len + 1 + 8 + 1;
		u8 *name_text = gb_alloc_array(proc->module->allocator, u8, name_len);
		name_len = gb_snprintf(cast(char *)name_text, name_len, "%.*s$%d", LIT(proc->name), cast(i32)proc->children.count);
		String name = make_string(name_text, name_len-1);

		Type *type = type_of_expr(proc->module->info, expr);
		ssaValue *value = ssa_make_value_procedure(proc->module->allocator,
		                                           proc->module, NULL, type, pl->type, pl->body, name);

		value->Proc.tags = pl->tags;
		value->Proc.parent = proc;

		array_add(&proc->children, &value->Proc);
		array_add(&proc->module->procs_to_generate, value);

		return value;
	case_end;


	case_ast_node(cl, CompoundLit, expr);
		return ssa_emit_load(proc, ssa_build_addr(proc, expr).addr);
	case_end;


	case_ast_node(ce, CallExpr, expr);
		AstNode *p = unparen_expr(ce->proc);
		if (p->kind == AstNode_Ident) {
			Entity **found = map_entity_get(&proc->module->info->uses, hash_pointer(p));
			if (found && (*found)->kind == Entity_Builtin) {
				Entity *e = *found;
				switch (e->Builtin.id) {
				case BuiltinProc_type_info: {
					Type *t = default_type(type_of_expr(proc->module->info, ce->args.e[0]));
					return ssa_type_info(proc, t);
				} break;
				case BuiltinProc_type_info_of_val: {
					Type *t = default_type(type_of_expr(proc->module->info, ce->args.e[0]));
					return ssa_type_info(proc, t);
				} break;

				case BuiltinProc_new: {
					ssa_emit_comment(proc, str_lit("new"));
					// new :: proc(Type) -> ^Type
					gbAllocator allocator = proc->module->allocator;

					Type *type = type_of_expr(proc->module->info, ce->args.e[0]);
					Type *ptr_type = make_type_pointer(allocator, type);

					i64 s = type_size_of(proc->module->sizes, allocator, type);
					i64 a = type_align_of(proc->module->sizes, allocator, type);

					ssaValue **args = gb_alloc_array(allocator, ssaValue *, 2);
					args[0] = ssa_make_const_int(allocator, s);
					args[1] = ssa_make_const_int(allocator, a);
					ssaValue *call = ssa_emit_global_call(proc, "alloc_align", args, 2);
					ssaValue *v = ssa_emit_conv(proc, call, ptr_type);
					return v;
				} break;

				case BuiltinProc_new_slice: {
					ssa_emit_comment(proc, str_lit("new_slice"));
					// new_slice :: proc(Type, len: int[, cap: int]) -> ^Type
					gbAllocator allocator = proc->module->allocator;

					Type *type = type_of_expr(proc->module->info, ce->args.e[0]);
					Type *ptr_type = make_type_pointer(allocator, type);
					Type *slice_type = make_type_slice(allocator, type);

					i64 s = type_size_of(proc->module->sizes, allocator, type);
					i64 a = type_align_of(proc->module->sizes, allocator, type);

					ssaValue *elem_size  = ssa_make_const_int(allocator, s);
					ssaValue *elem_align = ssa_make_const_int(allocator, a);

					ssaValue *len = ssa_emit_conv(proc, ssa_build_expr(proc, ce->args.e[1]), t_int);
					ssaValue *cap = len;
					if (ce->args.count == 3) {
						cap = ssa_emit_conv(proc, ssa_build_expr(proc, ce->args.e[2]), t_int);
					}

					ssa_emit_slice_bounds_check(proc, ast_node_token(ce->args.e[1]), v_zero, len, cap, false);

					ssaValue *slice_size = ssa_emit_arith(proc, Token_Mul, elem_size, cap, t_int);

					ssaValue **args = gb_alloc_array(allocator, ssaValue *, 2);
					args[0] = slice_size;
					args[1] = elem_align;
					ssaValue *call = ssa_emit_global_call(proc, "alloc_align", args, 2);

					ssaValue *ptr = ssa_emit_conv(proc, call, ptr_type);
					ssaValue *slice = ssa_add_local_generated(proc, slice_type);

					ssaValue *gep0 = ssa_emit_struct_ep(proc, slice, 0);
					ssaValue *gep1 = ssa_emit_struct_ep(proc, slice, 1);
					ssaValue *gep2 = ssa_emit_struct_ep(proc, slice, 2);
					ssa_emit_store(proc, gep0, ptr);
					ssa_emit_store(proc, gep1, len);
					ssa_emit_store(proc, gep2, cap);
					return ssa_emit_load(proc, slice);
				} break;

				case BuiltinProc_assert: {
					ssa_emit_comment(proc, str_lit("assert"));
					ssaValue *cond = ssa_build_expr(proc, ce->args.e[0]);
					GB_ASSERT(is_type_boolean(ssa_type(cond)));

					cond = ssa_emit_comp(proc, Token_CmpEq, cond, v_false);
					ssaBlock *err  = ssa_add_block(proc, NULL, "builtin.assert.err");
					ssaBlock *done = ssa_add_block(proc, NULL, "builtin.assert.done");

					ssa_emit_if(proc, cond, err, done);
					proc->curr_block = err;

					// TODO(bill): Cleanup allocations here
					Token token = ast_node_token(ce->args.e[0]);
					TokenPos pos = token.pos;
					gbString expr = expr_to_string(ce->args.e[0]);
					isize expr_len = gb_string_length(expr);
					String expr_str = {0};
					expr_str.text = cast(u8 *)gb_alloc_copy_align(proc->module->allocator, expr, expr_len, 1);
					expr_str.len = expr_len;
					gb_string_free(expr);


					ssaValue **args = gb_alloc_array(proc->module->allocator, ssaValue *, 4);
					args[0] = ssa_make_const_string(proc->module->allocator, pos.file);
					args[1] = ssa_make_const_int(proc->module->allocator, pos.line);
					args[2] = ssa_make_const_int(proc->module->allocator, pos.column);
					args[3] = ssa_make_const_string(proc->module->allocator, expr_str);
					ssa_emit_global_call(proc, "__assert", args, 4);

					ssa_emit_jump(proc, done);
					proc->curr_block = done;

					return NULL;
				} break;

				case BuiltinProc_panic: {
					ssa_emit_comment(proc, str_lit("panic"));
					ssaValue *msg = ssa_build_expr(proc, ce->args.e[0]);
					GB_ASSERT(is_type_string(ssa_type(msg)));

					Token token = ast_node_token(ce->args.e[0]);
					TokenPos pos = token.pos;

					ssaValue **args = gb_alloc_array(proc->module->allocator, ssaValue *, 4);
					args[0] = ssa_make_const_string(proc->module->allocator, pos.file);
					args[1] = ssa_make_const_int(proc->module->allocator, pos.line);
					args[2] = ssa_make_const_int(proc->module->allocator, pos.column);
					args[3] = msg;
					ssa_emit_global_call(proc, "__assert", args, 4);

					return NULL;
				} break;


				case BuiltinProc_copy: {
					ssa_emit_comment(proc, str_lit("copy"));
					// copy :: proc(dst, src: []Type) -> int
					AstNode *dst_node = ce->args.e[0];
					AstNode *src_node = ce->args.e[1];
					ssaValue *dst_slice = ssa_build_expr(proc, dst_node);
					ssaValue *src_slice = ssa_build_expr(proc, src_node);
					Type *slice_type = base_type(ssa_type(dst_slice));
					GB_ASSERT(slice_type->kind == Type_Slice);
					Type *elem_type = slice_type->Slice.elem;
					i64 size_of_elem = type_size_of(proc->module->sizes, proc->module->allocator, elem_type);

					ssaValue *dst = ssa_emit_conv(proc, ssa_slice_elem(proc, dst_slice), t_rawptr);
					ssaValue *src = ssa_emit_conv(proc, ssa_slice_elem(proc, src_slice), t_rawptr);

					ssaValue *len_dst = ssa_slice_len(proc, dst_slice);
					ssaValue *len_src = ssa_slice_len(proc, src_slice);

					ssaValue *cond = ssa_emit_comp(proc, Token_Lt, len_dst, len_src);
					ssaValue *len = ssa_emit_select(proc, cond, len_dst, len_src);

					ssaValue *elem_size = ssa_make_const_int(proc->module->allocator, size_of_elem);
					ssaValue *byte_count = ssa_emit_arith(proc, Token_Mul, len, elem_size, t_int);

					ssaValue **args = gb_alloc_array(proc->module->allocator, ssaValue *, 3);
					args[0] = dst;
					args[1] = src;
					args[2] = byte_count;

					ssa_emit_global_call(proc, "__mem_copy", args, 3);

					return len;
				} break;
				case BuiltinProc_append: {
					ssa_emit_comment(proc, str_lit("append"));
					// append :: proc(s: ^[]Type, item: Type) -> bool
					AstNode *sptr_node = ce->args.e[0];
					AstNode *item_node = ce->args.e[1];
					ssaValue *slice_ptr = ssa_build_expr(proc, sptr_node);
					ssaValue *slice = ssa_emit_load(proc, slice_ptr);

					ssaValue *elem = ssa_slice_elem(proc, slice);
					ssaValue *len  = ssa_slice_len(proc,  slice);
					ssaValue *cap  = ssa_slice_cap(proc,  slice);

					Type *elem_type = type_deref(ssa_type(elem));

					ssaValue *item_value = ssa_build_expr(proc, item_node);
					item_value = ssa_emit_conv(proc, item_value, elem_type);

					ssaValue *item = ssa_add_local_generated(proc, elem_type);
					ssa_emit_store(proc, item, item_value);


					// NOTE(bill): Check if can append is possible
					ssaValue *cond = ssa_emit_comp(proc, Token_Lt, len, cap);
					ssaBlock *able = ssa_add_block(proc, NULL, "builtin.append.able");
					ssaBlock *done = ssa_add_block(proc, NULL, "builtin.append.done");

					ssa_emit_if(proc, cond, able, done);
					proc->curr_block = able;

					// Add new slice item
					i64 item_size = type_size_of(proc->module->sizes, proc->module->allocator, elem_type);
					ssaValue *byte_count = ssa_make_const_int(proc->module->allocator, item_size);

					ssaValue *offset = ssa_emit_ptr_offset(proc, elem, len);
					offset = ssa_emit_conv(proc, offset, t_rawptr);

					item = ssa_emit_ptr_offset(proc, item, v_zero);
					item = ssa_emit_conv(proc, item, t_rawptr);

					ssaValue **args = gb_alloc_array(proc->module->allocator, ssaValue *, 3);
					args[0] = offset;
					args[1] = item;
					args[2] = byte_count;

					ssa_emit_global_call(proc, "__mem_copy", args, 3);

					// Increment slice length
					ssaValue *new_len = ssa_emit_arith(proc, Token_Add, len, v_one, t_int);
					ssaValue *gep = ssa_emit_struct_ep(proc, slice_ptr, 1);
					ssa_emit_store(proc, gep, new_len);

					ssa_emit_jump(proc, done);
					proc->curr_block = done;

					return ssa_emit_conv(proc, cond, t_bool);
				} break;

				case BuiltinProc_swizzle: {
					ssa_emit_comment(proc, str_lit("swizzle"));
					ssaValue *vector = ssa_build_expr(proc, ce->args.e[0]);
					isize index_count = ce->args.count-1;
					if (index_count == 0) {
						return vector;
					}

					i32 *indices = gb_alloc_array(proc->module->allocator, i32, index_count);
					isize index = 0;
					for_array(i, ce->args) {
						if (i == 0) continue;
						TypeAndValue *tv = type_and_value_of_expression(proc->module->info, ce->args.e[i]);
						GB_ASSERT(is_type_integer(tv->type));
						GB_ASSERT(tv->value.kind == ExactValue_Integer);
						indices[index++] = cast(i32)tv->value.value_integer;
					}

					return ssa_emit(proc, ssa_make_instr_vector_shuffle(proc, vector, indices, index_count));

				} break;

				case BuiltinProc_slice_ptr: {
					ssa_emit_comment(proc, str_lit("slice_ptr"));
					ssaValue *ptr = ssa_build_expr(proc, ce->args.e[0]);
					ssaValue *len = ssa_build_expr(proc, ce->args.e[1]);
					ssaValue *cap = len;

					len = ssa_emit_conv(proc, len, t_int);

					if (ce->args.count == 3) {
						cap = ssa_build_expr(proc, ce->args.e[2]);
						cap = ssa_emit_conv(proc, cap, t_int);
					}


					Type *slice_type = make_type_slice(proc->module->allocator, type_deref(ssa_type(ptr)));
					ssaValue *slice = ssa_add_local_generated(proc, slice_type);
					ssa_emit_store(proc, ssa_emit_struct_ep(proc, slice, 0), ptr);
					ssa_emit_store(proc, ssa_emit_struct_ep(proc, slice, 1), len);
					ssa_emit_store(proc, ssa_emit_struct_ep(proc, slice, 2), cap);
					return ssa_emit_load(proc, slice);
				} break;

				case BuiltinProc_min: {
					ssa_emit_comment(proc, str_lit("min"));
					Type *t = type_of_expr(proc->module->info, expr);
					ssaValue *x = ssa_emit_conv(proc, ssa_build_expr(proc, ce->args.e[0]), t);
					ssaValue *y = ssa_emit_conv(proc, ssa_build_expr(proc, ce->args.e[1]), t);
					ssaValue *cond = ssa_emit_comp(proc, Token_Lt, x, y);
					return ssa_emit_select(proc, cond, x, y);
				} break;

				case BuiltinProc_max: {
					ssa_emit_comment(proc, str_lit("max"));
					Type *t = type_of_expr(proc->module->info, expr);
					ssaValue *x = ssa_emit_conv(proc, ssa_build_expr(proc, ce->args.e[0]), t);
					ssaValue *y = ssa_emit_conv(proc, ssa_build_expr(proc, ce->args.e[1]), t);
					ssaValue *cond = ssa_emit_comp(proc, Token_Gt, x, y);
					return ssa_emit_select(proc, cond, x, y);
				} break;

				case BuiltinProc_abs: {
					ssa_emit_comment(proc, str_lit("abs"));
					gbAllocator a = proc->module->allocator;

					ssaValue *x = ssa_build_expr(proc, ce->args.e[0]);
					Type *original_type = ssa_type(x);
					Type *t = original_type;
					i64 sz = type_size_of(proc->module->sizes, a, t);
					GB_ASSERT(is_type_integer(t) || is_type_float(t));
					if (is_type_float(t)) {
						if (sz == 4) {
							t = t_i32;
						} else if (sz == 8) {
							t = t_i64;
						} else {
							GB_PANIC("unknown float type for `abs`");
						}

						x = ssa_emit_bitcast(proc, x, t);
					}

					/*
						NOTE(bill): See Hacker's Delight, section 2-4.
						m := x >> (int_size-1)
						b := x ^ m
						return b - m
					*/

					ssaValue *m = ssa_emit_arith(proc, Token_Shr,
					                             x,
					                             ssa_make_value_constant(a, t, make_exact_value_integer(sz-1)),
					                             t);
					ssaValue *b = ssa_emit_arith(proc, Token_Xor, x, m, t);
					ssaValue *v = ssa_emit_arith(proc, Token_Sub, b, m, t);

					if (is_type_float(t)) {
						v = ssa_emit_bitcast(proc, v, original_type);
					}
					return v;
				} break;

				case BuiltinProc_clamp: {
					ssa_emit_comment(proc, str_lit("clamp"));
					Type *t = type_of_expr(proc->module->info, expr);
					ssaValue *x   = ssa_emit_conv(proc, ssa_build_expr(proc, ce->args.e[0]), t);
					ssaValue *min = ssa_emit_conv(proc, ssa_build_expr(proc, ce->args.e[1]), t);
					ssaValue *max = ssa_emit_conv(proc, ssa_build_expr(proc, ce->args.e[2]), t);
					ssaValue *cond;
					cond = ssa_emit_comp(proc, Token_Gt, min, x);
					x    = ssa_emit_select(proc, cond,   min, x);
					cond = ssa_emit_comp(proc, Token_Lt, max, x);
					x    = ssa_emit_select(proc, cond,   max, x);
					return x;
				} break;
				}
			}
		}

		// NOTE(bill): Regular call
		ssaValue *value = ssa_build_expr(proc, ce->proc);
		GB_ASSERT(value != NULL);
		Type *proc_type_ = base_type(ssa_type(value));
		GB_ASSERT(proc_type_->kind == Type_Proc);
		TypeProc *type = &proc_type_->Proc;

		isize arg_index = 0;

		isize arg_count = 0;
		for_array(i, ce->args) {
			AstNode *a = ce->args.e[i];
			Type *at = base_type(type_of_expr(proc->module->info, a));
			if (at->kind == Type_Tuple) {
				arg_count += at->Tuple.variable_count;
			} else {
				arg_count++;
			}
		}
		ssaValue **args = gb_alloc_array(proc->module->allocator, ssaValue *, arg_count);
		bool variadic = proc_type_->Proc.variadic;
		bool vari_expand = ce->ellipsis.pos.line != 0;

		for_array(i, ce->args) {
			ssaValue *a = ssa_build_expr(proc, ce->args.e[i]);
			Type *at = ssa_type(a);
			if (at->kind == Type_Tuple) {
				for (isize i = 0; i < at->Tuple.variable_count; i++) {
					Entity *e = at->Tuple.variables[i];
					ssaValue *v = ssa_emit_struct_ev(proc, a, i);
					args[arg_index++] = v;
				}
			} else {
				args[arg_index++] = a;
			}
		}

		TypeTuple *pt = &type->params->Tuple;

		if (variadic) {
			isize i = 0;
			for (; i < type->param_count-1; i++) {
				args[i] = ssa_emit_conv(proc, args[i], pt->variables[i]->type);
			}
			if (!vari_expand) {
				Type *variadic_type = pt->variables[i]->type;
				GB_ASSERT(is_type_slice(variadic_type));
				variadic_type = base_type(variadic_type)->Slice.elem;
				for (; i < arg_count; i++) {
					args[i] = ssa_emit_conv(proc, args[i], variadic_type);
				}
			}
		} else {
			for (isize i = 0; i < arg_count; i++) {
				args[i] = ssa_emit_conv(proc, args[i], pt->variables[i]->type);
			}
		}

		if (variadic && !vari_expand) {
			ssa_emit_comment(proc, str_lit("variadic call argument generation"));
			gbAllocator allocator = proc->module->allocator;
			Type *slice_type = pt->variables[type->param_count-1]->type;
			Type *elem_type  = base_type(slice_type)->Slice.elem;
			ssaValue *slice = ssa_add_local_generated(proc, slice_type);
			isize slice_len = arg_count+1 - type->param_count;

			if (slice_len > 0) {
				ssaValue *base_array = ssa_add_local_generated(proc, make_type_array(allocator, elem_type, slice_len));

				for (isize i = type->param_count-1, j = 0; i < arg_count; i++, j++) {
					ssaValue *addr = ssa_emit_array_epi(proc, base_array, j);
					ssa_emit_store(proc, addr, args[i]);
				}

				ssaValue *base_elem  = ssa_emit_array_epi(proc, base_array, 0);
				ssaValue *slice_elem = ssa_emit_struct_ep(proc, slice,      0);
				ssa_emit_store(proc, slice_elem, base_elem);
				ssaValue *len = ssa_make_const_int(allocator, slice_len);
				ssa_emit_store(proc, ssa_emit_struct_ep(proc, slice, 1), len);
				ssa_emit_store(proc, ssa_emit_struct_ep(proc, slice, 2), len);
			}

			arg_count = type->param_count;
			args[arg_count-1] = ssa_emit_load(proc, slice);
		}

		return ssa_emit_call(proc, value, args, arg_count);
	case_end;

	case_ast_node(de, DemaybeExpr, expr);
		return ssa_emit_load(proc, ssa_build_addr(proc, expr).addr);
	case_end;

	case_ast_node(se, SliceExpr, expr);
		return ssa_emit_load(proc, ssa_build_addr(proc, expr).addr);
	case_end;

	case_ast_node(ie, IndexExpr, expr);
		return ssa_emit_load(proc, ssa_build_addr(proc, expr).addr);
	case_end;
	}

	GB_PANIC("Unexpected expression: %.*s", LIT(ast_node_strings[expr->kind]));
	return NULL;
}


ssaValue *ssa_build_expr(ssaProcedure *proc, AstNode *expr) {
	expr = unparen_expr(expr);

	TypeAndValue *tv = map_tav_get(&proc->module->info->types, hash_pointer(expr));
	GB_ASSERT_NOT_NULL(tv);

	if (tv->value.kind != ExactValue_Invalid) {
		return ssa_add_module_constant(proc->module, tv->type, tv->value);
	}

	ssaValue *value = NULL;
	if (tv->mode == Addressing_Variable) {
		value = ssa_addr_load(proc, ssa_build_addr(proc, expr));
	} else {
		value = ssa_build_single_expr(proc, expr, tv);
	}

	return value;
}

ssaValue *ssa_add_using_variable(ssaProcedure *proc, Entity *e) {
	GB_ASSERT(e->kind == Entity_Variable && e->flags & EntityFlag_Anonymous);
	String name = e->token.string;
	Entity *parent = e->using_parent;
	Selection sel = lookup_field(proc->module->allocator, parent->type, name, false);
	GB_ASSERT(sel.entity != NULL);
	ssaValue **pv = map_ssa_value_get(&proc->module->values, hash_pointer(parent));
	ssaValue *v = NULL;
	if (pv != NULL) {
		v = *pv;
	} else {
		v = ssa_build_addr(proc, e->using_expr).addr;
	}
	GB_ASSERT(v != NULL);
	ssaValue *var = ssa_emit_deep_field_gep(proc, parent->type, v, sel);
	map_ssa_value_set(&proc->module->values, hash_pointer(e), var);
	return var;
}

bool ssa_is_elem_const(ssaModule *m, AstNode *elem, Type *elem_type) {
	if (base_type(elem_type) == t_any) {
		return false;
	}
	if (elem->kind == AstNode_FieldValue) {
		elem = elem->FieldValue.value;
	}
	TypeAndValue *tav = type_and_value_of_expression(m->info, elem);
	GB_ASSERT(tav != NULL);
	return tav->value.kind != ExactValue_Invalid;
}

ssaAddr ssa_build_addr_from_entity(ssaProcedure *proc, Entity *e, AstNode *expr) {
	GB_ASSERT(e != NULL);
	GB_ASSERT(e->kind != Entity_Constant);

	ssaValue *v = NULL;
	ssaValue **found = map_ssa_value_get(&proc->module->values, hash_pointer(e));
	if (found) {
		v = *found;
	} else if (e->kind == Entity_Variable && e->flags & EntityFlag_Anonymous) {
		v = ssa_add_using_variable(proc, e);
	} else if (e->kind == Entity_ImplicitValue) {
		// TODO(bill): Should a copy be made?
		v = ssa_find_implicit_value_backing(proc, e->ImplicitValue.id);
	}

	if (v == NULL) {
		GB_PANIC("Unknown value: %.*s, entity: %p %.*s\n", LIT(e->token.string), e, LIT(entity_strings[e->kind]));
	}

	return ssa_make_addr(v, expr);
}

ssaAddr ssa_build_addr(ssaProcedure *proc, AstNode *expr) {
	switch (expr->kind) {
	case_ast_node(i, Ident, expr);
		if (ssa_is_blank_ident(expr)) {
			ssaAddr val = {0};
			return val;
		}

		Entity *e = entity_of_ident(proc->module->info, expr);
		return ssa_build_addr_from_entity(proc, e, expr);
	case_end;

	case_ast_node(pe, ParenExpr, expr);
		return ssa_build_addr(proc, unparen_expr(expr));
	case_end;

	case_ast_node(se, SelectorExpr, expr);
		ssa_emit_comment(proc, str_lit("SelectorExpr"));
		AstNode *sel = unparen_expr(se->selector);
		GB_ASSERT(sel->kind == AstNode_Ident);
		String selector = sel->Ident.string;
		Type *type = base_type(type_of_expr(proc->module->info, se->expr));

		if (type == t_invalid) {
			// NOTE(bill): Imports
			Entity *imp = entity_of_ident(proc->module->info, se->expr);
			if (imp != NULL) {
				GB_ASSERT(imp->kind == Entity_ImportName);
			}
			return ssa_build_addr(proc, unparen_expr(se->selector));
		} else {
			Selection sel = lookup_field(proc->module->allocator, type, selector, false);
			GB_ASSERT(sel.entity != NULL);

			ssaValue *a = ssa_build_addr(proc, se->expr).addr;
			a = ssa_emit_deep_field_gep(proc, type, a, sel);
			return ssa_make_addr(a, expr);
		}
	case_end;

	case_ast_node(ue, UnaryExpr, expr);
		switch (ue->op.kind) {
		case Token_Pointer: {
			return ssa_build_addr(proc, ue->expr);
		}
		default:
			GB_PANIC("Invalid unary expression for ssa_build_addr");
		}
	case_end;

	case_ast_node(be, BinaryExpr, expr);
		switch (be->op.kind) {
		case Token_as: {
			ssa_emit_comment(proc, str_lit("Cast - as"));
			// NOTE(bill): Needed for dereference of pointer conversion
			Type *type = type_of_expr(proc->module->info, expr);
			ssaValue *v = ssa_add_local_generated(proc, type);
			ssa_emit_store(proc, v, ssa_emit_conv(proc, ssa_build_expr(proc, be->left), type));
			return ssa_make_addr(v, expr);
		}
		case Token_transmute: {
			ssa_emit_comment(proc, str_lit("Cast - transmute"));
			// NOTE(bill): Needed for dereference of pointer conversion
			Type *type = type_of_expr(proc->module->info, expr);
			ssaValue *v = ssa_add_local_generated(proc, type);
			ssa_emit_store(proc, v, ssa_emit_transmute(proc, ssa_build_expr(proc, be->left), type));
			return ssa_make_addr(v, expr);
		}
		default:
			GB_PANIC("Invalid binary expression for ssa_build_addr: %.*s\n", LIT(be->op.string));
			break;
		}
	case_end;

	case_ast_node(ie, IndexExpr, expr);
		ssa_emit_comment(proc, str_lit("IndexExpr"));
		Type *t = base_type(type_of_expr(proc->module->info, ie->expr));
		gbAllocator a = proc->module->allocator;


		bool deref = is_type_pointer(t);
		t = type_deref(t);

		ssaValue *using_addr = NULL;
		if (!is_type_indexable(t)) {
			// Using index expression
			Entity *using_field = find_using_index_expr(t);
			if (using_field != NULL) {
				Selection sel = lookup_field(a, t, using_field->token.string, false);
				ssaValue *e = ssa_build_addr(proc, ie->expr).addr;
				using_addr = ssa_emit_deep_field_gep(proc, t, e, sel);

				t = using_field->type;
			}
		}


		switch (t->kind) {
		case Type_Vector: {
			ssaValue *vector = NULL;
			if (using_addr != NULL) {
				vector = using_addr;
			} else {
				vector = ssa_build_addr(proc, ie->expr).addr;
				if (deref) {
					vector = ssa_emit_load(proc, vector);
				}
			}
			ssaValue *index = ssa_emit_conv(proc, ssa_build_expr(proc, ie->index), t_int);
			ssaValue *len = ssa_make_const_int(a, t->Vector.count);
			ssa_emit_bounds_check(proc, ast_node_token(ie->index), index, len);
			return ssa_make_addr_vector(vector, index, expr);
		} break;

		case Type_Array: {
			ssaValue *array = NULL;
			if (using_addr != NULL) {
				array = using_addr;
			} else {
				array = ssa_build_addr(proc, ie->expr).addr;
				if (deref) {
					array = ssa_emit_load(proc, array);
				}
			}
			ssaValue *index = ssa_emit_conv(proc, ssa_build_expr(proc, ie->index), t_int);
			ssaValue *elem = ssa_emit_array_ep(proc, array, index);
			ssaValue *len = ssa_make_const_int(a, t->Vector.count);
			ssa_emit_bounds_check(proc, ast_node_token(ie->index), index, len);
			return ssa_make_addr(elem, expr);
		} break;

		case Type_Slice: {
			ssaValue *slice = NULL;
			if (using_addr != NULL) {
				slice = ssa_emit_load(proc, using_addr);
			} else {
				slice = ssa_build_expr(proc, ie->expr);
				if (deref) {
					slice = ssa_emit_load(proc, slice);
				}
			}
			ssaValue *elem = ssa_slice_elem(proc, slice);
			ssaValue *len = ssa_slice_len(proc, slice);
			ssaValue *index = ssa_emit_conv(proc, ssa_build_expr(proc, ie->index), t_int);
			ssa_emit_bounds_check(proc, ast_node_token(ie->index), index, len);
			ssaValue *v = ssa_emit_ptr_offset(proc, elem, index);
			return ssa_make_addr(v, expr);

		} break;

		case Type_Basic: { // Basic_string
			TypeAndValue *tv = map_tav_get(&proc->module->info->types, hash_pointer(ie->expr));
			ssaValue *str;
			ssaValue *elem;
			ssaValue *len;
			ssaValue *index;

			if (using_addr != NULL) {
				str = ssa_emit_load(proc, using_addr);
			} else {
				str = ssa_build_expr(proc, ie->expr);
				if (deref) {
					str = ssa_emit_load(proc, str);
				}
			}
			elem = ssa_string_elem(proc, str);
			len = ssa_string_len(proc, str);

			index = ssa_emit_conv(proc, ssa_build_expr(proc, ie->index), t_int);
			ssa_emit_bounds_check(proc, ast_node_token(ie->index), index, len);

			return ssa_make_addr(ssa_emit_ptr_offset(proc, elem, index), expr);
		} break;
		}
	case_end;

	case_ast_node(se, SliceExpr, expr);
		ssa_emit_comment(proc, str_lit("SliceExpr"));
		gbAllocator a = proc->module->allocator;
		ssaValue *low  = v_zero;
		ssaValue *high = NULL;
		ssaValue *max  = NULL;

		if (se->low  != NULL)    low  = ssa_build_expr(proc, se->low);
		if (se->high != NULL)    high = ssa_build_expr(proc, se->high);
		if (se->triple_indexed)  max  = ssa_build_expr(proc, se->max);
		ssaValue *addr = ssa_build_addr(proc, se->expr).addr;
		ssaValue *base = ssa_emit_load(proc, addr);
		Type *type = base_type(ssa_type(base));

		if (is_type_pointer(type)) {
			type = type_deref(type);
			addr = base;
			base = ssa_emit_load(proc, base);
		}

		// TODO(bill): Cleanup like mad!

		switch (type->kind) {
		case Type_Slice: {
			Type *slice_type = type;

			if (high == NULL) high = ssa_slice_len(proc, base);
			if (max == NULL)  max  = ssa_slice_cap(proc, base);
			GB_ASSERT(max != NULL);

			ssa_emit_slice_bounds_check(proc, se->open, low, high, max, false);

			ssaValue *elem  = ssa_emit_ptr_offset(proc, ssa_slice_elem(proc, base), low);
			ssaValue *len   = ssa_emit_arith(proc, Token_Sub, high, low, t_int);
			ssaValue *cap   = ssa_emit_arith(proc, Token_Sub, max,  low, t_int);
			ssaValue *slice = ssa_add_local_generated(proc, slice_type);

			ssaValue *gep0 = ssa_emit_struct_ep(proc, slice, 0);
			ssaValue *gep1 = ssa_emit_struct_ep(proc, slice, 1);
			ssaValue *gep2 = ssa_emit_struct_ep(proc, slice, 2);
			ssa_emit_store(proc, gep0, elem);
			ssa_emit_store(proc, gep1, len);
			ssa_emit_store(proc, gep2, cap);

			return ssa_make_addr(slice, expr);
		}

		case Type_Array: {
			Type *slice_type = make_type_slice(a, type->Array.elem);

			if (high == NULL) high = ssa_array_len(proc, base);
			if (max == NULL)  max  = ssa_array_cap(proc, base);
			GB_ASSERT(max != NULL);

			ssa_emit_slice_bounds_check(proc, se->open, low, high, max, false);

			ssaValue *elem = ssa_emit_ptr_offset(proc, ssa_array_elem(proc, addr), low);
			ssaValue *len  = ssa_emit_arith(proc, Token_Sub, high, low, t_int);
			ssaValue *cap  = ssa_emit_arith(proc, Token_Sub, max,  low, t_int);
			ssaValue *slice = ssa_add_local_generated(proc, slice_type);

			ssaValue *gep0 = ssa_emit_struct_ep(proc, slice, 0);
			ssaValue *gep1 = ssa_emit_struct_ep(proc, slice, 1);
			ssaValue *gep2 = ssa_emit_struct_ep(proc, slice, 2);
			ssa_emit_store(proc, gep0, elem);
			ssa_emit_store(proc, gep1, len);
			ssa_emit_store(proc, gep2, cap);

			return ssa_make_addr(slice, expr);
		}

		case Type_Basic: {
			GB_ASSERT(type == t_string);
			if (high == NULL) {
				high = ssa_string_len(proc, base);
			}

			ssa_emit_slice_bounds_check(proc, se->open, low, high, high, true);

			ssaValue *elem, *len;
			len = ssa_emit_arith(proc, Token_Sub, high, low, t_int);

			elem = ssa_string_elem(proc, base);
			elem = ssa_emit_ptr_offset(proc, elem, low);

			ssaValue *str = ssa_add_local_generated(proc, t_string);
			ssaValue *gep0 = ssa_emit_struct_ep(proc, str, 0);
			ssaValue *gep1 = ssa_emit_struct_ep(proc, str, 1);
			ssa_emit_store(proc, gep0, elem);
			ssa_emit_store(proc, gep1, len);

			return ssa_make_addr(str, expr);
		} break;
		}

		GB_PANIC("Unknown slicable type");
	case_end;

	case_ast_node(de, DerefExpr, expr);
		// TODO(bill): Is a ptr copy needed?
		ssaValue *addr = ssa_build_expr(proc, de->expr);
		addr = ssa_emit_ptr_offset(proc, addr, v_zero);
		return ssa_make_addr(addr, expr);
	case_end;

	case_ast_node(de, DemaybeExpr, expr);
		ssa_emit_comment(proc, str_lit("DemaybeExpr"));
		ssaValue *maybe = ssa_build_expr(proc, de->expr);
		Type *t = default_type(type_of_expr(proc->module->info, expr));
		GB_ASSERT(is_type_tuple(t));

		ssaValue *result = ssa_add_local_generated(proc, t);
		ssa_emit_store(proc, result, maybe);

		return ssa_make_addr(result, expr);
	case_end;

	case_ast_node(ce, CallExpr, expr);
		ssaValue *e = ssa_build_expr(proc, expr);
		ssaValue *v = ssa_add_local_generated(proc, ssa_type(e));
		ssa_emit_store(proc, v, e);
		return ssa_make_addr(v, expr);
	case_end;


	case_ast_node(cl, CompoundLit, expr);
		ssa_emit_comment(proc, str_lit("CompoundLit"));
		Type *type = type_of_expr(proc->module->info, expr);
		Type *bt = base_type(type);
		ssaValue *v = ssa_add_local_generated(proc, type);

		Type *et = NULL;
		switch (bt->kind) {
		case Type_Vector: et = bt->Vector.elem; break;
		case Type_Array:  et = bt->Array.elem;  break;
		case Type_Slice:  et = bt->Slice.elem;  break;
		}

		switch (bt->kind) {
		default: GB_PANIC("Unknown CompoundLit type: %s", type_to_string(type)); break;

		case Type_Vector: {
			ssaValue *result = ssa_add_module_constant(proc->module, type, make_exact_value_compound(expr));
			for_array(index, cl->elems) {
				AstNode *elem = cl->elems.e[index];
				if (ssa_is_elem_const(proc->module, elem, et)) {
					continue;
				}
				ssaValue *field_elem = ssa_build_expr(proc, elem);
				Type *t = ssa_type(field_elem);
				GB_ASSERT(t->kind != Type_Tuple);
				ssaValue *ev = ssa_emit_conv(proc, field_elem, et);
				ssaValue *i = ssa_make_const_int(proc->module->allocator, index);
				result = ssa_emit(proc, ssa_make_instr_insert_element(proc, result, ev, i));
			}

			if (cl->elems.count == 1 && bt->Vector.count > 1) {
				isize index_count = bt->Vector.count;
				i32 *indices = gb_alloc_array(proc->module->allocator, i32, index_count);
				for (isize i = 0; i < index_count; i++) {
					indices[i] = 0;
				}
				ssaValue *sv = ssa_emit(proc, ssa_make_instr_vector_shuffle(proc, result, indices, index_count));
				ssa_emit_store(proc, v, sv);
				return ssa_make_addr(v, expr);
			}
			ssa_emit_store(proc, v, result);
		} break;

		case Type_Record: {
			GB_ASSERT(is_type_struct(bt));
			TypeRecord *st = &bt->Record;
			if (cl->elems.count > 0) {
				ssa_emit_store(proc, v, ssa_add_module_constant(proc->module, type, make_exact_value_compound(expr)));
				for_array(field_index, cl->elems) {
					AstNode *elem = cl->elems.e[field_index];

					ssaValue *field_expr = NULL;
					Entity *field = NULL;
					isize index = field_index;

					if (elem->kind == AstNode_FieldValue) {
						ast_node(fv, FieldValue, elem);
						Selection sel = lookup_field(proc->module->allocator, bt, fv->field->Ident.string, false);
						index = sel.index.e[0];
						elem = fv->value;
					} else {
						TypeAndValue *tav = type_and_value_of_expression(proc->module->info, elem);
						Selection sel = lookup_field(proc->module->allocator, bt, st->fields_in_src_order[field_index]->token.string, false);
						index = sel.index.e[0];
					}

					field = st->fields[index];
					if (ssa_is_elem_const(proc->module, elem, field->type)) {
						continue;
					}

					field_expr = ssa_build_expr(proc, elem);

					GB_ASSERT(ssa_type(field_expr)->kind != Type_Tuple);

					Type *ft = field->type;
					ssaValue *fv = ssa_emit_conv(proc, field_expr, ft);
					ssaValue *gep = ssa_emit_struct_ep(proc, v, index);
					ssa_emit_store(proc, gep, fv);
				}
			}
		} break;
		case Type_Array: {
			if (cl->elems.count > 0) {
				ssa_emit_store(proc, v, ssa_add_module_constant(proc->module, type, make_exact_value_compound(expr)));
				for_array(i, cl->elems) {
					AstNode *elem = cl->elems.e[i];
					if (ssa_is_elem_const(proc->module, elem, et)) {
						continue;
					}
					ssaValue *field_expr = ssa_build_expr(proc, elem);
					Type *t = ssa_type(field_expr);
					GB_ASSERT(t->kind != Type_Tuple);
					ssaValue *ev = ssa_emit_conv(proc, field_expr, et);
					ssaValue *gep = ssa_emit_array_epi(proc, v, i);
					ssa_emit_store(proc, gep, ev);
				}
			}
		} break;
		case Type_Slice: {
			if (cl->elems.count > 0) {
				Type *elem_type = bt->Slice.elem;
				Type *elem_ptr_type = make_type_pointer(proc->module->allocator, elem_type);
				Type *elem_ptr_ptr_type = make_type_pointer(proc->module->allocator, elem_ptr_type);
				ssaValue *slice = ssa_add_module_constant(proc->module, type, make_exact_value_compound(expr));
				GB_ASSERT(slice->kind == ssaValue_ConstantSlice);

				ssaValue *data = ssa_emit_array_ep(proc, slice->ConstantSlice.backing_array, v_zero32);

				for_array(i, cl->elems) {
					AstNode *elem = cl->elems.e[i];
					if (ssa_is_elem_const(proc->module, elem, et)) {
						continue;
					}

					ssaValue *field_expr = ssa_build_expr(proc, elem);
					Type *t = ssa_type(field_expr);
					GB_ASSERT(t->kind != Type_Tuple);
					ssaValue *ev = ssa_emit_conv(proc, field_expr, elem_type);
					ssaValue *offset = ssa_emit_ptr_offset(proc, data, ssa_make_const_int(proc->module->allocator, i));
					ssa_emit_store(proc, offset, ev);
				}

				ssaValue *gep0 = ssa_emit_struct_ep(proc, v, 0);
				ssaValue *gep1 = ssa_emit_struct_ep(proc, v, 1);
				ssaValue *gep2 = ssa_emit_struct_ep(proc, v, 1);

				ssa_emit_store(proc, gep0, data);
				ssa_emit_store(proc, gep1, ssa_make_const_int(proc->module->allocator, slice->ConstantSlice.count));
				ssa_emit_store(proc, gep2, ssa_make_const_int(proc->module->allocator, slice->ConstantSlice.count));
			}
		} break;
		}

		return ssa_make_addr(v, expr);
	case_end;


	}

	TokenPos token_pos = ast_node_token(expr).pos;
	GB_PANIC("Unexpected address expression\n"
	         "\tAstNode: %.*s @ "
	         "%.*s(%td:%td)\n",
	         LIT(ast_node_strings[expr->kind]),
	         LIT(token_pos.file), token_pos.line, token_pos.column);


	return ssa_make_addr(NULL, NULL);
}

void ssa_build_assign_op(ssaProcedure *proc, ssaAddr lhs, ssaValue *value, TokenKind op) {
	ssaValue *old_value = ssa_addr_load(proc, lhs);
	Type *type = ssa_type(old_value);

	ssaValue *change = value;
	if (is_type_pointer(type) && is_type_integer(ssa_type(value))) {
		change = ssa_emit_conv(proc, value, default_type(ssa_type(value)));
	} else {
		change = ssa_emit_conv(proc, value, type);
	}
	ssaValue *new_value = ssa_emit_arith(proc, op, old_value, change, type);
	ssa_addr_store(proc, lhs, new_value);
}

void ssa_build_cond(ssaProcedure *proc, AstNode *cond, ssaBlock *true_block, ssaBlock *false_block) {
	switch (cond->kind) {
	case_ast_node(pe, ParenExpr, cond);
		ssa_build_cond(proc, pe->expr, true_block, false_block);
		return;
	case_end;

	case_ast_node(ue, UnaryExpr, cond);
		if (ue->op.kind == Token_Not) {
			ssa_build_cond(proc, ue->expr, false_block, true_block);
			return;
		}
	case_end;

	case_ast_node(be, BinaryExpr, cond);
		if (be->op.kind == Token_CmpAnd) {
			ssaBlock *block = ssa_add_block(proc, NULL, "cmp.and");
			ssa_build_cond(proc, be->left, block, false_block);
			proc->curr_block = block;
			ssa_build_cond(proc, be->right, true_block, false_block);
			return;
		} else if (be->op.kind == Token_CmpOr) {
			ssaBlock *block = ssa_add_block(proc, NULL, "cmp.or");
			ssa_build_cond(proc, be->left, true_block, block);
			proc->curr_block = block;
			ssa_build_cond(proc, be->right, true_block, false_block);
			return;
		}
	case_end;
	}

	ssaValue *expr = ssa_build_expr(proc, cond);
	expr = ssa_emit_conv(proc, expr, t_bool);
	ssa_emit_if(proc, expr, true_block, false_block);
}




void ssa_build_stmt_list(ssaProcedure *proc, AstNodeArray stmts) {
	for_array(i, stmts) {
		ssa_build_stmt(proc, stmts.e[i]);
	}
}

void ssa_build_stmt_internal(ssaProcedure *proc, AstNode *node);
void ssa_build_stmt(ssaProcedure *proc, AstNode *node) {
	u32 prev_stmt_state_flags = proc->module->stmt_state_flags;

	if (node->stmt_state_flags != 0) {
		u32 in = node->stmt_state_flags;
		u32 out = proc->module->stmt_state_flags;

		if (in & StmtStateFlag_bounds_check) {
			out |= StmtStateFlag_bounds_check;
			out &= ~StmtStateFlag_no_bounds_check;
		} else if (in & StmtStateFlag_no_bounds_check) {
			out |= StmtStateFlag_no_bounds_check;
			out &= ~StmtStateFlag_bounds_check;
		}

		proc->module->stmt_state_flags = out;
	}

	ssa_build_stmt_internal(proc, node);

	proc->module->stmt_state_flags = prev_stmt_state_flags;
}

void ssa_build_when_stmt(ssaProcedure *proc, AstNodeWhenStmt *ws) {
	ssaValue *cond = ssa_build_expr(proc, ws->cond);
	GB_ASSERT(cond->kind == ssaValue_Constant &&
	          is_type_boolean(ssa_type(cond)));

	GB_ASSERT(cond->Constant.value.kind == ExactValue_Bool);
	if (cond->Constant.value.value_bool) {
		ssa_build_stmt_list(proc, ws->body->BlockStmt.stmts);
	} else if (ws->else_stmt) {
		switch (ws->else_stmt->kind) {
		case AstNode_BlockStmt:
			ssa_build_stmt_list(proc, ws->else_stmt->BlockStmt.stmts);
			break;
		case AstNode_WhenStmt:
			ssa_build_when_stmt(proc, &ws->else_stmt->WhenStmt);
			break;
		default:
			GB_PANIC("Invalid `else` statement in `when` statement");
			break;
		}
	}
}

void ssa_build_stmt_internal(ssaProcedure *proc, AstNode *node) {
	switch (node->kind) {
	case_ast_node(bs, EmptyStmt, node);
	case_end;

	case_ast_node(us, UsingStmt, node);
		AstNode *decl = unparen_expr(us->node);
		if (decl->kind == AstNode_GenericDecl) {
			ssa_build_stmt(proc, decl);
		}
	case_end;

	case_ast_node(ws, WhenStmt, node);
		ssa_build_when_stmt(proc, ws);
	case_end;


	case_ast_node(gd, GenericDecl, node);
		for_array(spec_index, gd->specs) {
			AstNode *spec = gd->specs.e[spec_index];
			switch (spec->kind) {
			case_ast_node(vs, ValueSpec, spec);
				switch (vs->keyword) {
				case Token_const:
					break;
				case Token_let:
				case Token_var: {
					ssaModule *m = proc->module;
					gbTempArenaMemory tmp = gb_temp_arena_memory_begin(&m->tmp_arena);

					if (vs->values.count == 0) { // declared and zero-initialized
						for_array(i, vs->names) {
							AstNode *name = vs->names.e[i];
							if (!ssa_is_blank_ident(name)) {
								ssa_add_local_for_identifier(proc, name, true);
							}
						}
					} else { // Tuple(s)
						Array(ssaAddr) lvals;
						ssaValueArray  inits;
						array_init_reserve(&lvals, m->tmp_allocator, vs->names.count);
						array_init_reserve(&inits, m->tmp_allocator, vs->names.count);

						for_array(i, vs->names) {
							AstNode *name = vs->names.e[i];
							ssaAddr lval = ssa_make_addr(NULL, NULL);
							if (!ssa_is_blank_ident(name)) {
								ssa_add_local_for_identifier(proc, name, false);
								lval = ssa_build_addr(proc, name);
							}

							array_add(&lvals, lval);
						}

						for_array(i, vs->values) {
							ssaValue *init = ssa_build_expr(proc, vs->values.e[i]);
							Type *t = ssa_type(init);
							if (t->kind == Type_Tuple) {
								for (isize i = 0; i < t->Tuple.variable_count; i++) {
									Entity *e = t->Tuple.variables[i];
									ssaValue *v = ssa_emit_struct_ev(proc, init, i);
									array_add(&inits, v);
								}
							} else {
								array_add(&inits, init);
							}
						}


						for_array(i, inits) {
							if (lvals.e[i].addr == NULL) {
								continue;
							}
							ssaValue *v = ssa_emit_conv(proc, inits.e[i], ssa_addr_type(lvals.e[i]));
							ssa_addr_store(proc, lvals.e[i], v);
						}
					}

					gb_temp_arena_memory_end(tmp);
				} break;
				}
			case_end;
			case_ast_node(ts, TypeSpec, spec);
				// NOTE(bill): Generate a new name
				// parent_proc.name-guid
				String ts_name = ts->name->Ident.string;
				isize name_len = proc->name.len + 1 + ts_name.len + 1 + 10 + 1;
				u8 *name_text = gb_alloc_array(proc->module->allocator, u8, name_len);
				i32 guid = cast(i32)proc->module->members.entries.count;
				name_len = gb_snprintf(cast(char *)name_text, name_len, "%.*s.%.*s-%d", LIT(proc->name), LIT(ts_name), guid);
				String name = make_string(name_text, name_len-1);

				Entity **found = map_entity_get(&proc->module->info->definitions, hash_pointer(ts->name));
				GB_ASSERT(found != NULL);
				Entity *e = *found;
				ssaValue *value = ssa_make_value_type_name(proc->module->allocator,
				                                           name, e->type);
				map_string_set(&proc->module->type_names, hash_pointer(e->type), name);
				ssa_gen_global_type_name(proc->module, e, name);
			case_end;
			}
		}
	case_end;

	case_ast_node(pd, ProcDecl, node);
		if (pd->body != NULL) {
			CheckerInfo *info = proc->module->info;

			Entity **found = map_entity_get(&info->definitions, hash_pointer(pd->name));
			GB_ASSERT_MSG(found != NULL, "Unable to find: %.*s", LIT(pd->name->Ident.string));
			Entity *e = *found;


			if (map_entity_get(&proc->module->min_dep_map, hash_pointer(e)) == NULL) {
				// NOTE(bill): Nothing depends upon it so doesn't need to be built
				break;
			}

			// NOTE(bill): Generate a new name
			// parent.name-guid
			String original_name = pd->name->Ident.string;
			String pd_name = original_name;
			if (pd->link_name.len > 0) {
				pd_name = pd->link_name;
			}

			isize name_len = proc->name.len + 1 + pd_name.len + 1 + 10 + 1;
			u8 *name_text = gb_alloc_array(proc->module->allocator, u8, name_len);
			i32 guid = cast(i32)proc->children.count;
			name_len = gb_snprintf(cast(char *)name_text, name_len, "%.*s.%.*s-%d", LIT(proc->name), LIT(pd_name), guid);
			String name = make_string(name_text, name_len-1);


			ssaValue *value = ssa_make_value_procedure(proc->module->allocator,
			                                           proc->module, e, e->type, pd->type, pd->body, name);

			value->Proc.tags = pd->tags;
			value->Proc.parent = proc;

			ssa_module_add_value(proc->module, e, value);
			array_add(&proc->children, &value->Proc);
			array_add(&proc->module->procs_to_generate, value);
		} else {
			CheckerInfo *info = proc->module->info;

			Entity **found = map_entity_get(&info->definitions, hash_pointer(pd->name));
			GB_ASSERT_MSG(found != NULL, "Unable to find: %.*s", LIT(pd->name->Ident.string));
			Entity *e = *found;

			// FFI - Foreign function interace
			String original_name = pd->name->Ident.string;
			String name = original_name;
			if (pd->foreign_name.len > 0) {
				name = pd->foreign_name;
			}

			ssaValue *value = ssa_make_value_procedure(proc->module->allocator,
			                                           proc->module, e, e->type, pd->type, pd->body, name);

			value->Proc.tags = pd->tags;

			ssa_module_add_value(proc->module, e, value);
			ssa_build_proc(value, proc);

			if (value->Proc.tags & ProcTag_foreign) {
				HashKey key = hash_string(name);
				ssaValue **prev_value = map_ssa_value_get(&proc->module->members, key);
				if (prev_value == NULL) {
					// NOTE(bill): Don't do mutliple declarations in the IR
					map_ssa_value_set(&proc->module->members, key, value);
				}
			} else {
				array_add(&proc->children, &value->Proc);
			}
		}
	case_end;

	case_ast_node(ids, IncDecStmt, node);
		ssa_emit_comment(proc, str_lit("IncDecStmt"));
		TokenKind op = ids->op.kind;
		if (op == Token_Increment) {
			op = Token_Add;
		} else if (op == Token_Decrement) {
			op = Token_Sub;
		}
		ssaAddr lval = ssa_build_addr(proc, ids->expr);
		ssaValue *one = ssa_emit_conv(proc, v_one, ssa_addr_type(lval));
		ssa_build_assign_op(proc, lval, one, op);

	case_end;

	case_ast_node(as, AssignStmt, node);
		ssa_emit_comment(proc, str_lit("AssignStmt"));

		ssaModule *m = proc->module;
		gbTempArenaMemory tmp = gb_temp_arena_memory_begin(&m->tmp_arena);

		switch (as->op.kind) {
		case Token_Eq: {
			Array(ssaAddr) lvals;
			array_init(&lvals, m->tmp_allocator);

			for_array(i, as->lhs) {
				AstNode *lhs = as->lhs.e[i];
				ssaAddr lval = {0};
				if (!ssa_is_blank_ident(lhs)) {
					lval = ssa_build_addr(proc, lhs);
				}
				array_add(&lvals, lval);
			}

			if (as->lhs.count == as->rhs.count) {
				if (as->lhs.count == 1) {
					AstNode *rhs = as->rhs.e[0];
					ssaValue *init = ssa_build_expr(proc, rhs);
					ssa_addr_store(proc, lvals.e[0], init);
				} else {
					ssaValueArray inits;
					array_init_reserve(&inits, m->tmp_allocator, lvals.count);

					for_array(i, as->rhs) {
						ssaValue *init = ssa_build_expr(proc, as->rhs.e[i]);
						array_add(&inits, init);
					}

					for_array(i, inits) {
						ssa_addr_store(proc, lvals.e[i], inits.e[i]);
					}
				}
			} else {
				ssaValueArray inits;
				array_init_reserve(&inits, m->tmp_allocator, lvals.count);

				for_array(i, as->rhs) {
					ssaValue *init = ssa_build_expr(proc, as->rhs.e[i]);
					Type *t = ssa_type(init);
					// TODO(bill): refactor for code reuse as this is repeated a bit
					if (t->kind == Type_Tuple) {
						for (isize i = 0; i < t->Tuple.variable_count; i++) {
							Entity *e = t->Tuple.variables[i];
							ssaValue *v = ssa_emit_struct_ev(proc, init, i);
							array_add(&inits, v);
						}
					} else {
						array_add(&inits, init);
					}
				}

				for_array(i, inits) {
					ssa_addr_store(proc, lvals.e[i], inits.e[i]);
				}
			}

		} break;

		default: {
			// NOTE(bill): Only 1 += 1 is allowed, no tuples
			// +=, -=, etc
			i32 op = cast(i32)as->op.kind;
			op += Token_Add - Token_AddEq; // Convert += to +
			ssaAddr lhs = ssa_build_addr(proc, as->lhs.e[0]);
			ssaValue *value = ssa_build_expr(proc, as->rhs.e[0]);
			ssa_build_assign_op(proc, lhs, value, cast(TokenKind)op);
		} break;
		}

		gb_temp_arena_memory_end(tmp);
	case_end;

	case_ast_node(es, ExprStmt, node);
		// NOTE(bill): No need to use return value
		ssa_build_expr(proc, es->expr);
	case_end;

	case_ast_node(bs, BlockStmt, node);
		ssa_open_scope(proc);
		ssa_build_stmt_list(proc, bs->stmts);
		ssa_close_scope(proc, ssaDeferExit_Default, NULL);
	case_end;

	case_ast_node(ds, DeferStmt, node);
		ssa_emit_comment(proc, str_lit("DeferStmt"));
		isize scope_index = proc->scope_index;
		if (ds->stmt->kind == AstNode_BlockStmt) {
			scope_index--;
		}
		ssa_add_defer_node(proc, scope_index, ds->stmt);
	case_end;

	case_ast_node(rs, ReturnStmt, node);
		ssa_emit_comment(proc, str_lit("ReturnStmt"));
		ssaValue *v = NULL;
		TypeTuple *return_type_tuple  = &proc->type->Proc.results->Tuple;
		isize return_count = proc->type->Proc.result_count;
		if (return_count == 0) {
			// No return values
		} else if (return_count == 1) {
			Entity *e = return_type_tuple->variables[0];
			v = ssa_emit_conv(proc, ssa_build_expr(proc, rs->results.e[0]), e->type);
		} else {
			gbTempArenaMemory tmp = gb_temp_arena_memory_begin(&proc->module->tmp_arena);

			ssaValueArray results;
			array_init_reserve(&results, proc->module->tmp_allocator, return_count);

			for_array(res_index, rs->results) {
				ssaValue *res = ssa_build_expr(proc, rs->results.e[res_index]);
				Type *t = ssa_type(res);
				if (t->kind == Type_Tuple) {
					for (isize i = 0; i < t->Tuple.variable_count; i++) {
						Entity *e = t->Tuple.variables[i];
						ssaValue *v = ssa_emit_struct_ev(proc, res, i);
						array_add(&results, v);
					}
				} else {
					array_add(&results, res);
				}
			}

			Type *ret_type = proc->type->Proc.results;
			v = ssa_add_local_generated(proc, ret_type);
			for_array(i, results) {
				Entity *e = return_type_tuple->variables[i];
				ssaValue *res = ssa_emit_conv(proc, results.e[i], e->type);
				ssaValue *field = ssa_emit_struct_ep(proc, v, i);
				ssa_emit_store(proc, field, res);
			}

			v = ssa_emit_load(proc, v);

			gb_temp_arena_memory_end(tmp);
		}
		ssa_emit_return(proc, v);

	case_end;

	case_ast_node(is, IfStmt, node);
		ssa_emit_comment(proc, str_lit("IfStmt"));
		if (is->init != NULL) {
			ssaBlock *init = ssa_add_block(proc, node, "if.init");
			ssa_emit_jump(proc, init);
			proc->curr_block = init;
			ssa_build_stmt(proc, is->init);
		}
		ssaBlock *then = ssa_add_block(proc, node, "if.then");
		ssaBlock *done = ssa_add_block(proc, node, "if.done"); // NOTE(bill): Append later
		ssaBlock *else_ = done;
		if (is->else_stmt != NULL) {
			else_ = ssa_add_block(proc, is->else_stmt, "if.else");
		}

		ssa_build_cond(proc, is->cond, then, else_);
		proc->curr_block = then;

		ssa_open_scope(proc);
		ssa_build_stmt(proc, is->body);
		ssa_close_scope(proc, ssaDeferExit_Default, NULL);

		ssa_emit_jump(proc, done);

		if (is->else_stmt != NULL) {
			proc->curr_block = else_;

			ssa_open_scope(proc);
			ssa_build_stmt(proc, is->else_stmt);
			ssa_close_scope(proc, ssaDeferExit_Default, NULL);

			ssa_emit_jump(proc, done);
		}
		proc->curr_block = done;
	case_end;

	case_ast_node(fs, ForStmt, node);
		ssa_emit_comment(proc, str_lit("ForStmt"));
		if (fs->init != NULL) {
			ssaBlock *init = ssa_add_block(proc, node, "for.init");
			ssa_emit_jump(proc, init);
			proc->curr_block = init;
			ssa_build_stmt(proc, fs->init);
		}
		ssaBlock *body = ssa_add_block(proc, node, "for.body");
		ssaBlock *done = ssa_add_block(proc, node, "for.done"); // NOTE(bill): Append later

		ssaBlock *loop = body;

		if (fs->cond != NULL) {
			loop = ssa_add_block(proc, node, "for.loop");
		}
		ssaBlock *cont = loop;
		if (fs->post != NULL) {
			cont = ssa_add_block(proc, node, "for.post");

		}
		ssa_emit_jump(proc, loop);
		proc->curr_block = loop;
		if (loop != body) {
			ssa_build_cond(proc, fs->cond, body, done);
			proc->curr_block = body;
		}

		ssa_push_target_list(proc, done, cont, NULL);

		ssa_open_scope(proc);
		ssa_build_stmt(proc, fs->body);
		ssa_close_scope(proc, ssaDeferExit_Default, NULL);

		ssa_pop_target_list(proc);
		ssa_emit_jump(proc, cont);

		if (fs->post != NULL) {
			proc->curr_block = cont;
			ssa_build_stmt(proc, fs->post);
			ssa_emit_jump(proc, loop);
		}


		proc->curr_block = done;

	case_end;

	case_ast_node(ms, MatchStmt, node);
		ssa_emit_comment(proc, str_lit("MatchStmt"));
		if (ms->init != NULL) {
			ssa_build_stmt(proc, ms->init);
		}
		ssaValue *tag = v_true;
		if (ms->tag != NULL) {
			tag = ssa_build_expr(proc, ms->tag);
		}
		ssaBlock *done = ssa_add_block(proc, node, "match.done"); // NOTE(bill): Append later

		ast_node(body, BlockStmt, ms->body);

		AstNodeArray default_stmts = {0};
		ssaBlock *default_fall = NULL;
		ssaBlock *default_block = NULL;

		ssaBlock *fall = NULL;
		bool append_fall = false;

		isize case_count = body->stmts.count;
		for_array(i, body->stmts) {
			AstNode *clause = body->stmts.e[i];
			ssaBlock *body = fall;

			ast_node(cc, CaseClause, clause);

			if (body == NULL) {
				if (cc->list.count == 0) {
					body = ssa_add_block(proc, clause, "match.dflt.body");
				} else {
					body = ssa_add_block(proc, clause, "match.case.body");
				}
			}
			if (append_fall && body == fall) {
				append_fall = false;
			}

			fall = done;
			if (i+1 < case_count) {
				append_fall = true;
				fall = ssa_add_block(proc, clause, "match.fall.body");
			}

			if (cc->list.count == 0) {
				// default case
				default_stmts = cc->stmts;
				default_fall  = fall;
				default_block = body;
				continue;
			}

			ssaBlock *next_cond = NULL;
			for_array(j, cc->list) {
				AstNode *expr = cc->list.e[j];
				next_cond = ssa_add_block(proc, clause, "match.case.next");

				ssaValue *cond = ssa_emit_comp(proc, Token_CmpEq, tag, ssa_build_expr(proc, expr));
				ssa_emit_if(proc, cond, body, next_cond);
				proc->curr_block = next_cond;
			}
			proc->curr_block = body;

			ssa_push_target_list(proc, done, NULL, fall);
			ssa_open_scope(proc);
			ssa_build_stmt_list(proc, cc->stmts);
			ssa_close_scope(proc, ssaDeferExit_Default, body);
			ssa_pop_target_list(proc);

			ssa_emit_jump(proc, done);
			proc->curr_block = next_cond;
		}

		if (default_block != NULL) {
			ssa_emit_jump(proc, default_block);
			proc->curr_block = default_block;

			ssa_push_target_list(proc, done, NULL, default_fall);
			ssa_open_scope(proc);
			ssa_build_stmt_list(proc, default_stmts);
			ssa_close_scope(proc, ssaDeferExit_Default, default_block);
			ssa_pop_target_list(proc);
		}

		ssa_emit_jump(proc, done);
		proc->curr_block = done;
	case_end;


	case_ast_node(ms, TypeMatchStmt, node);
		ssa_emit_comment(proc, str_lit("TypeMatchStmt"));
		gbAllocator allocator = proc->module->allocator;

		ssaValue *parent = ssa_build_expr(proc, ms->tag);
		bool is_union_ptr = false;
		bool is_any = false;
		GB_ASSERT(check_valid_type_match_type(ssa_type(parent), &is_union_ptr, &is_any));

		ssaValue *tag_index = NULL;
		ssaValue *union_data = NULL;
		if (is_union_ptr) {
			ssa_emit_comment(proc, str_lit("get union's tag"));
			tag_index = ssa_emit_load(proc, ssa_emit_union_tag_ptr(proc, parent));
			union_data = ssa_emit_conv(proc, parent, t_rawptr);
		}

		ssaBlock *start_block = ssa_add_block(proc, node, "type-match.case.first");
		ssa_emit_jump(proc, start_block);
		proc->curr_block = start_block;

		ssaBlock *done = ssa_add_block(proc, node, "type-match.done"); // NOTE(bill): Append later

		ast_node(body, BlockStmt, ms->body);

		String tag_var_name = ms->var->Ident.string;

		AstNodeArray default_stmts = {0};
		ssaBlock *default_block = NULL;


		isize case_count = body->stmts.count;
		for_array(i, body->stmts) {
			AstNode *clause = body->stmts.e[i];
			ast_node(cc, CaseClause, clause);

			if (cc->list.count == 0) {
				// default case
				default_stmts = cc->stmts;
				default_block = ssa_add_block(proc, clause, "type-match.dflt.body");
				continue;
			}


			ssaBlock *body = ssa_add_block(proc, clause, "type-match.case.body");

			Scope *scope = *map_scope_get(&proc->module->info->scopes, hash_pointer(clause));
			Entity *tag_var_entity = current_scope_lookup_entity(scope, tag_var_name);
			GB_ASSERT_MSG(tag_var_entity != NULL, "%.*s", LIT(tag_var_name));

			ssaBlock *next_cond = NULL;
			ssaValue *cond = NULL;

			if (is_union_ptr) {
				Type *bt = type_deref(tag_var_entity->type);
				ssaValue *index = NULL;
				Type *ut = base_type(type_deref(ssa_type(parent)));
				GB_ASSERT(ut->Record.kind == TypeRecord_Union);
				for (isize field_index = 1; field_index < ut->Record.field_count; field_index++) {
					Entity *f = ut->Record.fields[field_index];
					if (are_types_identical(f->type, bt)) {
						index = ssa_make_const_int(allocator, field_index);
						break;
					}
				}
				GB_ASSERT(index != NULL);

				ssaValue *tag_var = ssa_add_local(proc, tag_var_entity);
				ssaValue *data_ptr = ssa_emit_conv(proc, union_data, tag_var_entity->type);
				ssa_emit_store(proc, tag_var, data_ptr);

				cond = ssa_emit_comp(proc, Token_CmpEq, tag_index, index);
			} else if (is_any) {
				Type *type = tag_var_entity->type;
				ssaValue *any_data = ssa_emit_struct_ev(proc, parent, 1);
				ssaValue *data = ssa_emit_conv(proc, any_data, make_type_pointer(proc->module->allocator, type));
				ssa_module_add_value(proc->module, tag_var_entity, data);

				ssaValue *any_ti  = ssa_emit_struct_ev(proc, parent, 0);
				ssaValue *case_ti = ssa_type_info(proc, type);
				cond = ssa_emit_comp(proc, Token_CmpEq, any_ti, case_ti);
			} else {
				GB_PANIC("Invalid type for type match statement");
			}

			next_cond = ssa_add_block(proc, clause, "type-match.case.next");
			ssa_emit_if(proc, cond, body, next_cond);
			proc->curr_block = next_cond;

			proc->curr_block = body;

			ssa_push_target_list(proc, done, NULL, NULL);
			ssa_open_scope(proc);
			ssa_build_stmt_list(proc, cc->stmts);
			ssa_close_scope(proc, ssaDeferExit_Default, body);
			ssa_pop_target_list(proc);

			ssa_emit_jump(proc, done);
			proc->curr_block = next_cond;
		}

		if (default_block != NULL) {
			ssa_emit_jump(proc, default_block);
			proc->curr_block = default_block;

			ssa_push_target_list(proc, done, NULL, NULL);
			ssa_open_scope(proc);
			ssa_build_stmt_list(proc, default_stmts);
			ssa_close_scope(proc, ssaDeferExit_Default, default_block);
			ssa_pop_target_list(proc);
		}

		ssa_emit_jump(proc, done);
		proc->curr_block = done;
	case_end;

	case_ast_node(bs, BranchStmt, node);
		ssaBlock *block = NULL;
		switch (bs->token.kind) {
		case Token_break:
			for (ssaTargetList *t = proc->target_list; t != NULL && block == NULL; t = t->prev) {
				block = t->break_;
			}
			break;
		case Token_continue:
			for (ssaTargetList *t = proc->target_list; t != NULL && block == NULL; t = t->prev) {
				block = t->continue_;
			}
			break;
		case Token_fallthrough:
			for (ssaTargetList *t = proc->target_list; t != NULL && block == NULL; t = t->prev) {
				block = t->fallthrough_;
			}
			break;
		}
		if (block != NULL) {
			ssa_emit_defer_stmts(proc, ssaDeferExit_Branch, block);
		}
		switch (bs->token.kind) {
		case Token_break:       ssa_emit_comment(proc, str_lit("break"));       break;
		case Token_continue:    ssa_emit_comment(proc, str_lit("continue"));    break;
		case Token_fallthrough: ssa_emit_comment(proc, str_lit("fallthrough")); break;
		}
		ssa_emit_jump(proc, block);
		ssa_emit_unreachable(proc);
	case_end;



	case_ast_node(pa, PushAllocator, node);
		ssa_emit_comment(proc, str_lit("PushAllocator"));
		ssa_open_scope(proc);

		ssaValue *context_ptr = ssa_find_implicit_value_backing(proc, ImplicitValue_context);
		ssaValue *prev_context = ssa_add_local_generated(proc, t_context);
		ssa_emit_store(proc, prev_context, ssa_emit_load(proc, context_ptr));

		ssa_add_defer_instr(proc, proc->scope_index, ssa_make_instr_store(proc, context_ptr, ssa_emit_load(proc, prev_context)));

		ssaValue *gep = ssa_emit_struct_ep(proc, context_ptr, 1);
		ssa_emit_store(proc, gep, ssa_build_expr(proc, pa->expr));

		ssa_build_stmt(proc, pa->body);

		ssa_close_scope(proc, ssaDeferExit_Default, NULL);
	case_end;


	case_ast_node(pa, PushContext, node);
		ssa_emit_comment(proc, str_lit("PushContext"));
		ssa_open_scope(proc);

		ssaValue *context_ptr = ssa_find_implicit_value_backing(proc, ImplicitValue_context);
		ssaValue *prev_context = ssa_add_local_generated(proc, t_context);
		ssa_emit_store(proc, prev_context, ssa_emit_load(proc, context_ptr));

		ssa_add_defer_instr(proc, proc->scope_index, ssa_make_instr_store(proc, context_ptr, ssa_emit_load(proc, prev_context)));

		ssa_emit_store(proc, context_ptr, ssa_build_expr(proc, pa->expr));

		ssa_build_stmt(proc, pa->body);

		ssa_close_scope(proc, ssaDeferExit_Default, NULL);
	case_end;


	}
}







////////////////////////////////////////////////////////////////
//
// @Procedure
//
////////////////////////////////////////////////////////////////

void ssa_number_proc_registers(ssaProcedure *proc) {
	i32 reg_index = 0;
	for_array(i, proc->blocks) {
		ssaBlock *b = proc->blocks.e[i];
		b->index = i;
		for_array(j, b->instrs) {
			ssaValue *value = b->instrs.e[j];
			GB_ASSERT(value->kind == ssaValue_Instr);
			ssaInstr *instr = &value->Instr;
			if (ssa_instr_type(instr) == NULL) { // NOTE(bill): Ignore non-returning instructions
				continue;
			}
			value->index = reg_index;
			reg_index++;
		}
	}
}

void ssa_begin_procedure_body(ssaProcedure *proc) {
	array_add(&proc->module->procs, proc);

	array_init(&proc->blocks,      heap_allocator());
	array_init(&proc->defer_stmts, heap_allocator());
	array_init(&proc->children,    heap_allocator());

	proc->decl_block  = ssa_add_block(proc, proc->type_expr, "decls");
	proc->entry_block = ssa_add_block(proc, proc->type_expr, "entry");
	proc->curr_block  = proc->entry_block;

	if (proc->type->Proc.params != NULL) {
		TypeTuple *params = &proc->type->Proc.params->Tuple;
		for (isize i = 0; i < params->variable_count; i++) {
			Entity *e = params->variables[i];
			if (!str_eq(e->token.string, str_lit("")) &&
			    !str_eq(e->token.string, str_lit("_"))) {
				ssaValue *param = ssa_add_param(proc, e);
				array_add(&proc->params, param);
			}
		}
	}
}


void ssa_end_procedure_body(ssaProcedure *proc) {
	if (proc->type->Proc.result_count == 0) {
		ssa_emit_return(proc, NULL);
	}

	if (proc->curr_block->instrs.count == 0) {
		ssa_emit_unreachable(proc);
	}

	proc->curr_block = proc->decl_block;
	ssa_emit_jump(proc, proc->entry_block);

	ssa_number_proc_registers(proc);
}


void ssa_insert_code_before_proc(ssaProcedure* proc, ssaProcedure *parent) {
	if (parent == NULL) {
		if (str_eq(proc->name, str_lit("main"))) {
			ssa_emit_startup_runtime(proc);
		}
	}
}

void ssa_build_proc(ssaValue *value, ssaProcedure *parent) {
	ssaProcedure *proc = &value->Proc;

	proc->parent = parent;

	if (proc->entity != NULL) {
		ssaModule *m = proc->module;
		CheckerInfo *info = m->info;
		Entity *e = proc->entity;
		String filename = e->token.pos.file;
		AstFile **found = map_ast_file_get(&info->files, hash_string(filename));
		GB_ASSERT(found != NULL);
		AstFile *f = *found;
		ssaDebugInfo *di_file = NULL;

		ssaDebugInfo **di_file_found = map_ssa_debug_info_get(&m->debug_info, hash_pointer(f));
		if (di_file_found) {
			di_file = *di_file_found;
			GB_ASSERT(di_file->kind == ssaDebugInfo_File);
		} else {
			di_file = ssa_add_debug_info_file(proc, f);
		}

		ssa_add_debug_info_proc(proc, e, proc->name, di_file);
	}

	if (proc->body != NULL) {
		u32 prev_stmt_state_flags = proc->module->stmt_state_flags;

		if (proc->tags != 0) {
			u32 in = proc->tags;
			u32 out = proc->module->stmt_state_flags;
			if (in & ProcTag_bounds_check) {
				out |= StmtStateFlag_bounds_check;
				out &= ~StmtStateFlag_no_bounds_check;
			} else if (in & ProcTag_no_bounds_check) {
				out |= StmtStateFlag_no_bounds_check;
				out &= ~StmtStateFlag_bounds_check;
			}
			proc->module->stmt_state_flags = out;
		}


		ssa_begin_procedure_body(proc);
		ssa_insert_code_before_proc(proc, parent);
		ssa_build_stmt(proc, proc->body);
		ssa_end_procedure_body(proc);

		proc->module->stmt_state_flags = prev_stmt_state_flags;
	}
}







////////////////////////////////////////////////////////////////
//
// @Module
//
////////////////////////////////////////////////////////////////



void ssa_module_add_value(ssaModule *m, Entity *e, ssaValue *v) {
	map_ssa_value_set(&m->values, hash_pointer(e), v);
}

void ssa_init_module(ssaModule *m, Checker *c, BuildContext *build_context) {
	// TODO(bill): Determine a decent size for the arena
	isize token_count = c->parser->total_token_count;
	isize arena_size = 4 * token_count * gb_size_of(ssaValue);
	gb_arena_init_from_allocator(&m->arena, heap_allocator(), arena_size);
	gb_arena_init_from_allocator(&m->tmp_arena, heap_allocator(), arena_size);
	m->allocator     = gb_arena_allocator(&m->arena);
	m->tmp_allocator = gb_arena_allocator(&m->tmp_arena);
	m->info = &c->info;
	m->sizes = c->sizes;
	m->build_context = build_context;

	map_ssa_value_init(&m->values,  heap_allocator());
	map_ssa_value_init(&m->members, heap_allocator());
	map_ssa_debug_info_init(&m->debug_info, heap_allocator());
	map_string_init(&m->type_names, heap_allocator());
	array_init(&m->procs,    heap_allocator());
	array_init(&m->procs_to_generate, heap_allocator());

	// Default states
	m->stmt_state_flags = 0;
	m->stmt_state_flags |= StmtStateFlag_bounds_check;

	{
		// Add type info data
		{
			String name = str_lit(SSA_TYPE_INFO_DATA_NAME);
			isize count = c->info.type_info_map.entries.count;
			Entity *e = make_entity_variable(m->allocator, NULL, make_token_ident(name), make_type_array(m->allocator, t_type_info, count), false);
			ssaValue *g = ssa_make_value_global(m->allocator, e, NULL);
			g->Global.is_private  = true;
			ssa_module_add_value(m, e, g);
			map_ssa_value_set(&m->members, hash_string(name), g);
		}

		// Type info member buffer
		{
			// NOTE(bill): Removes need for heap allocation by making it global memory
			isize count = 0;

			for_array(entry_index, m->info->type_info_map.entries) {
				MapIsizeEntry *entry = &m->info->type_info_map.entries.e[entry_index];
				Type *t = cast(Type *)cast(uintptr)entry->key.key;

				switch (t->kind) {
				case Type_Record:
					switch (t->Record.kind) {
					case TypeRecord_Struct:
					case TypeRecord_RawUnion:
						count += t->Record.field_count;
					}
					break;
				case Type_Tuple:
					count += t->Tuple.variable_count;
					break;
				}
			}

			String name = str_lit(SSA_TYPE_INFO_DATA_MEMBER_NAME);
			Entity *e = make_entity_variable(m->allocator, NULL, make_token_ident(name),
			                                 make_type_array(m->allocator, t_type_info_member, count), false);
			ssaValue *g = ssa_make_value_global(m->allocator, e, NULL);
			ssa_module_add_value(m, e, g);
			map_ssa_value_set(&m->members, hash_string(name), g);
		}
	}

	{
		ssaDebugInfo *di = ssa_alloc_debug_info(m->allocator, ssaDebugInfo_CompileUnit);
		di->CompileUnit.file = m->info->files.entries.e[0].value; // Zeroth is the init file
		di->CompileUnit.producer = str_lit("odin");

		map_ssa_debug_info_set(&m->debug_info, hash_pointer(m), di);
	}
}

void ssa_destroy_module(ssaModule *m) {
	map_ssa_value_destroy(&m->values);
	map_ssa_value_destroy(&m->members);
	map_string_destroy(&m->type_names);
	map_ssa_debug_info_destroy(&m->debug_info);
	array_free(&m->procs_to_generate);
	gb_arena_free(&m->arena);
}



////////////////////////////////////////////////////////////////
//
// @Code Generation
//
////////////////////////////////////////////////////////////////


bool ssa_gen_init(ssaGen *s, Checker *c, BuildContext *build_context) {
	if (global_error_collector.count != 0) {
		return false;
	}

	isize tc = c->parser->total_token_count;
	if (tc < 2) {
		return false;
	}

	ssa_init_module(&s->module, c, build_context);
	s->module.generate_debug_info = false;

	// TODO(bill): generate appropriate output name
	int pos = cast(int)string_extension_position(c->parser->init_fullpath);
	gbFileError err = gb_file_create(&s->output_file, gb_bprintf("%.*s.ll", pos, c->parser->init_fullpath.text));
	if (err != gbFileError_None) {
		return false;
	}

	return true;
}

void ssa_gen_destroy(ssaGen *s) {
	ssa_destroy_module(&s->module);
	gb_file_close(&s->output_file);
}

String ssa_mangle_name(ssaGen *s, String path, String name) {
	// NOTE(bill): prefix names not in the init scope
	// TODO(bill): make robust and not just rely on the file's name

	ssaModule *m = &s->module;
	CheckerInfo *info = m->info;
	gbAllocator a = m->allocator;
	AstFile *file = *map_ast_file_get(&info->files, hash_string(path));

	char *str = gb_alloc_array(a, char, path.len+1);
	gb_memmove(str, path.text, path.len);
	str[path.len] = 0;
	for (isize i = 0; i < path.len; i++) {
		if (str[i] == '\\') {
			str[i] = '/';
		}
	}

	char const *base = gb_path_base_name(str);
	char const *ext = gb_path_extension(base);
	isize base_len = ext-1-base;

	isize max_len = base_len + 1 + 10 + 1 + name.len;
	u8 *new_name = gb_alloc_array(a, u8, max_len);
	isize new_name_len = gb_snprintf(
		cast(char *)new_name, max_len,
		"%.*s-%u.%.*s",
		cast(int)base_len, base,
		file->id,
		LIT(name));

	return make_string(new_name, new_name_len-1);
}

ssaValue *ssa_get_type_info_ptr(ssaProcedure *proc, ssaValue *type_info_data, Type *type) {
	i32 index = cast(i32)ssa_type_info_index(proc->module->info, type);
	// gb_printf_err("%d %s\n", index, type_to_string(type));
	ssaValue *ptr = ssa_emit_array_epi(proc, type_info_data, index);
	return ssa_emit_bitcast(proc, ptr, t_type_info_ptr);
}

ssaValue *ssa_type_info_member_offset(ssaProcedure *proc, ssaValue *data, isize count, i32 *index) {
	ssaValue *offset = ssa_emit_array_epi(proc, data, *index);
	*index += count;
	return offset;
}

void ssa_gen_tree(ssaGen *s) {
	ssaModule *m = &s->module;
	CheckerInfo *info = m->info;
	gbAllocator a = m->allocator;

	if (v_zero == NULL) {
		v_zero   = ssa_make_const_int (m->allocator, 0);
		v_one    = ssa_make_const_int (m->allocator, 1);
		v_zero32 = ssa_make_const_i32 (m->allocator, 0);
		v_one32  = ssa_make_const_i32 (m->allocator, 1);
		v_two32  = ssa_make_const_i32 (m->allocator, 2);
		v_false  = ssa_make_const_bool(m->allocator, false);
		v_true   = ssa_make_const_bool(m->allocator, true);
	}

	isize global_variable_max_count = 0;
	Entity *entry_point = NULL;
	bool has_dll_main = false;
	bool has_win_main = false;

	for_array(i, info->entities.entries) {
		MapDeclInfoEntry *entry = &info->entities.entries.e[i];
		Entity *e = cast(Entity *)cast(uintptr)entry->key.key;
		String name = e->token.string;
		if (e->kind == Entity_Variable) {
			global_variable_max_count++;
		} else if (e->kind == Entity_Procedure && !e->scope->is_global) {
			if (e->scope->is_init && str_eq(name, str_lit("main"))) {
				entry_point = e;
			}
			if ((e->Procedure.tags & ProcTag_export) != 0 ||
			    (e->Procedure.link_name.len > 0) ||
			    (e->scope->is_file && e->Procedure.link_name.len > 0)) {
				if (!has_dll_main && str_eq(name, str_lit("DllMain"))) {
					has_dll_main = true;
				} else if (!has_win_main && str_eq(name, str_lit("WinMain"))) {
					has_win_main = true;
				}
			}
		}
	}

	typedef struct ssaGlobalVariable {
		ssaValue *var, *init;
		DeclInfo *decl;
	} ssaGlobalVariable;
	Array(ssaGlobalVariable) global_variables;
	array_init_reserve(&global_variables, m->tmp_allocator, global_variable_max_count);

	m->entry_point_entity = entry_point;
	m->min_dep_map = generate_minimum_dependency_map(info, entry_point);

	for_array(i, info->entities.entries) {
		MapDeclInfoEntry *entry = &info->entities.entries.e[i];
		Entity *e = cast(Entity *)entry->key.ptr;
		String name = e->token.string;
		DeclInfo *decl = entry->value;
		Scope *scope = e->scope;

		if (!scope->is_file) {
			continue;
		}

		if (map_entity_get(&m->min_dep_map, hash_pointer(e)) == NULL) {
			// NOTE(bill): Nothing depends upon it so doesn't need to be built
			continue;
		}

		if (!scope->is_global) {
			if (e->kind == Entity_Procedure && (e->Procedure.tags & ProcTag_export) != 0) {
			} else if (e->kind == Entity_Procedure && e->Procedure.link_name.len > 0) {
			} else if (scope->is_init && e->kind == Entity_Procedure && str_eq(name, str_lit("main"))) {
			} else {
				name = ssa_mangle_name(s, e->token.pos.file, name);
			}
		}


		switch (e->kind) {
		case Entity_TypeName:
			GB_ASSERT(e->type->kind == Type_Named);
			map_string_set(&m->type_names, hash_pointer(e->type), name);
			ssa_gen_global_type_name(m, e, name);
			break;

		case Entity_Variable: {
			ssaValue *g = ssa_make_value_global(a, e, NULL);
			if (decl->var_decl_tags & VarDeclTag_thread_local) {
				g->Global.is_thread_local = true;
			}
			ssaGlobalVariable var = {0};
			var.var = g;
			var.decl = decl;

			if (decl->init_expr != NULL) {
				TypeAndValue *tav = map_tav_get(&info->types, hash_pointer(decl->init_expr));
				if (tav != NULL) {
					if (tav->value.kind != ExactValue_Invalid) {
						ExactValue v = tav->value;
						// if (v.kind != ExactValue_String) {
							g->Global.value = ssa_add_module_constant(m, tav->type, v);
						// }
					}
				}
			}

			if (g->Global.value == NULL) {
				array_add(&global_variables, var);
			}

			ssa_module_add_value(m, e, g);
			map_ssa_value_set(&m->members, hash_string(name), g);
		} break;

		case Entity_Procedure: {
			AstNodeProcDecl *pd = &decl->proc_decl->ProcDecl;
			String original_name = name;
			AstNode *body = pd->body;
			if (e->Procedure.is_foreign) {
				name = e->token.string; // NOTE(bill): Don't use the mangled name
			}
			if (pd->foreign_name.len > 0) {
				name = pd->foreign_name;
			} else if (pd->link_name.len > 0) {
				name = pd->link_name;
			}

			ssaValue *p = ssa_make_value_procedure(a, m, e, e->type, decl->type_expr, body, name);
			p->Proc.tags = pd->tags;

			ssa_module_add_value(m, e, p);
			HashKey hash_name = hash_string(name);
			if (map_ssa_value_get(&m->members, hash_name) == NULL) {
				map_ssa_value_set(&m->members, hash_name, p);
			}
		} break;
		}
	}

	for_array(i, m->members.entries) {
		MapSsaValueEntry *entry = &m->members.entries.e[i];
		ssaValue *v = entry->value;
		if (v->kind == ssaValue_Proc) {
			ssa_build_proc(v, NULL);
		}
	}

	ssaDebugInfo *compile_unit = m->debug_info.entries.e[0].value;
	GB_ASSERT(compile_unit->kind == ssaDebugInfo_CompileUnit);
	ssaDebugInfo *all_procs = ssa_alloc_debug_info(m->allocator, ssaDebugInfo_AllProcs);

	isize all_proc_max_count = 0;
	for_array(i, m->debug_info.entries) {
		MapSsaDebugInfoEntry *entry = &m->debug_info.entries.e[i];
		ssaDebugInfo *di = entry->value;
		di->id = i;
		if (di->kind == ssaDebugInfo_Proc) {
			all_proc_max_count++;
		}
	}

	array_init_reserve(&all_procs->AllProcs.procs, m->allocator, all_proc_max_count);
	map_ssa_debug_info_set(&m->debug_info, hash_pointer(all_procs), all_procs); // NOTE(bill): This doesn't need to be mapped
	compile_unit->CompileUnit.all_procs = all_procs;


	for_array(i, m->debug_info.entries) {
		MapSsaDebugInfoEntry *entry = &m->debug_info.entries.e[i];
		ssaDebugInfo *di = entry->value;
		di->id = i;
		if (di->kind == ssaDebugInfo_Proc) {
			array_add(&all_procs->AllProcs.procs, di);
		}
	}

#if defined(GB_SYSTEM_WINDOWS)
	if (m->build_context->is_dll && !has_dll_main) {
		// DllMain :: proc(inst: rawptr, reason: u32, reserved: rawptr) -> i32
		String name = str_lit("DllMain");
		Type *proc_params = make_type_tuple(a);
		Type *proc_results = make_type_tuple(a);

		Scope *proc_scope = gb_alloc_item(a, Scope);

		proc_params->Tuple.variables = gb_alloc_array(a, Entity *, 3);
		proc_params->Tuple.variable_count = 3;

		proc_results->Tuple.variables = gb_alloc_array(a, Entity *, 1);
		proc_results->Tuple.variable_count = 1;

		proc_params->Tuple.variables[0] = make_entity_param(a, proc_scope, blank_token, t_rawptr, false);
		proc_params->Tuple.variables[1] = make_entity_param(a, proc_scope, make_token_ident(str_lit("reason")), t_i32, false);
		proc_params->Tuple.variables[2] = make_entity_param(a, proc_scope, blank_token, t_rawptr, false);

		proc_results->Tuple.variables[0] = make_entity_param(a, proc_scope, empty_token, t_i32, false);


		Type *proc_type = make_type_proc(a, proc_scope,
		                                 proc_params, 3,
		                                 proc_results, 1, false);

		AstNode *body = gb_alloc_item(a, AstNode);
		Entity *e = make_entity_procedure(a, NULL, make_token_ident(name), proc_type, 0);
		ssaValue *p = ssa_make_value_procedure(a, m, e, proc_type, NULL, body, name);

		map_ssa_value_set(&m->values, hash_pointer(e), p);
		map_ssa_value_set(&m->members, hash_string(name), p);

		ssaProcedure *proc = &p->Proc;
		proc->tags = ProcTag_no_inline | ProcTag_stdcall; // TODO(bill): is no_inline a good idea?
		e->Procedure.link_name = name;

		ssa_begin_procedure_body(proc);

		// NOTE(bill): https://msdn.microsoft.com/en-us/library/windows/desktop/ms682583(v=vs.85).aspx
		// DLL_PROCESS_ATTACH == 1

		ssaAddr reason_addr = ssa_build_addr_from_entity(proc, proc_params->Tuple.variables[1], NULL);
		ssaValue *cond = ssa_emit_comp(proc, Token_CmpEq, ssa_addr_load(proc, reason_addr), v_one32);
		ssaBlock *then = ssa_add_block(proc, NULL, "if.then");
		ssaBlock *done = ssa_add_block(proc, NULL, "if.done"); // NOTE(bill): Append later
		ssa_emit_if(proc, cond, then, done);
		proc->curr_block = then;
		ssa_emit_global_call(proc, "main", NULL, 0);
		ssa_emit_jump(proc, done);
		proc->curr_block = done;

		ssa_emit_return(proc, v_one32);


		ssa_end_procedure_body(proc);
	}
#endif
#if defined(GB_SYSTEM_WINDOWS)
	if (!m->build_context->is_dll && !has_win_main) {
		// WinMain :: proc(inst, prev: rawptr, cmd_line: ^byte, cmd_show: i32) -> i32
		String name = str_lit("WinMain");
		Type *proc_params = make_type_tuple(a);
		Type *proc_results = make_type_tuple(a);

		Scope *proc_scope = gb_alloc_item(a, Scope);

		proc_params->Tuple.variables = gb_alloc_array(a, Entity *, 4);
		proc_params->Tuple.variable_count = 4;

		proc_results->Tuple.variables = gb_alloc_array(a, Entity *, 1);
		proc_results->Tuple.variable_count = 1;

		proc_params->Tuple.variables[0] = make_entity_param(a, proc_scope, blank_token, t_rawptr, false);
		proc_params->Tuple.variables[1] = make_entity_param(a, proc_scope, blank_token, t_rawptr, false);
		proc_params->Tuple.variables[2] = make_entity_param(a, proc_scope, blank_token, t_u8_ptr, false);
		proc_params->Tuple.variables[3] = make_entity_param(a, proc_scope, blank_token, t_i32,    false);

		proc_results->Tuple.variables[0] = make_entity_param(a, proc_scope, empty_token, t_i32, false);


		Type *proc_type = make_type_proc(a, proc_scope,
		                                 proc_params, 4,
		                                 proc_results, 1, false);

		AstNode *body = gb_alloc_item(a, AstNode);
		Entity *e = make_entity_procedure(a, NULL, make_token_ident(name), proc_type, 0);
		ssaValue *p = ssa_make_value_procedure(a, m, e, proc_type, NULL, body, name);

		map_ssa_value_set(&m->values, hash_pointer(e), p);
		map_ssa_value_set(&m->members, hash_string(name), p);

		ssaProcedure *proc = &p->Proc;
		proc->tags = ProcTag_no_inline | ProcTag_stdcall; // TODO(bill): is no_inline a good idea?
		e->Procedure.link_name = name;

		ssa_begin_procedure_body(proc);
		ssa_emit_global_call(proc, "main", NULL, 0);
		ssa_emit_return(proc, v_one32);
		ssa_end_procedure_body(proc);
	}
#endif
	{ // Startup Runtime
		// Cleanup(bill): probably better way of doing code insertion
		String name = str_lit(SSA_STARTUP_RUNTIME_PROC_NAME);
		Type *proc_type = make_type_proc(a, gb_alloc_item(a, Scope),
		                                 NULL, 0,
		                                 NULL, 0, false);
		AstNode *body = gb_alloc_item(a, AstNode);
		Entity *e = make_entity_procedure(a, NULL, make_token_ident(name), proc_type, 0);
		ssaValue *p = ssa_make_value_procedure(a, m, e, proc_type, NULL, body, name);

		map_ssa_value_set(&m->values, hash_pointer(e), p);
		map_ssa_value_set(&m->members, hash_string(name), p);

		ssaProcedure *proc = &p->Proc;
		proc->tags = ProcTag_no_inline; // TODO(bill): is no_inline a good idea?

		ssa_begin_procedure_body(proc);

		// TODO(bill): Should do a dependency graph do check which order to initialize them in?
		for_array(i, global_variables) {
			ssaGlobalVariable *var = &global_variables.e[i];
			if (var->decl->init_expr != NULL) {
				var->init = ssa_build_expr(proc, var->decl->init_expr);
			}
		}

		// NOTE(bill): Initialize constants first
		for_array(i, global_variables) {
			ssaGlobalVariable *var = &global_variables.e[i];
			if (var->init != NULL) {
				if (var->init->kind == ssaValue_Constant) {
					ssa_emit_store(proc, var->var, var->init);
				}
			}
		}

		for_array(i, global_variables) {
			ssaGlobalVariable *var = &global_variables.e[i];
			if (var->init != NULL) {
				if (var->init->kind != ssaValue_Constant) {
					ssa_emit_store(proc, var->var, var->init);
				}
			}
		}

		{ // NOTE(bill): Setup type_info data
			// TODO(bill): Try and make a lot of this constant aggregate literals in LLVM IR
			ssaValue *type_info_data = NULL;
			ssaValue *type_info_member_data = NULL;

			ssaValue **found = NULL;
			found = map_ssa_value_get(&proc->module->members, hash_string(str_lit(SSA_TYPE_INFO_DATA_NAME)));
			GB_ASSERT(found != NULL);
			type_info_data = *found;

			found = map_ssa_value_get(&proc->module->members, hash_string(str_lit(SSA_TYPE_INFO_DATA_MEMBER_NAME)));
			GB_ASSERT(found != NULL);
			type_info_member_data = *found;

			CheckerInfo *info = proc->module->info;

			// Useful types
			Type *t_i64_slice_ptr    = make_type_pointer(a, make_type_slice(a, t_i64));
			Type *t_string_slice_ptr = make_type_pointer(a, make_type_slice(a, t_string));

			i32 type_info_member_index = 0;

			for_array(type_info_map_index, info->type_info_map.entries) {
				MapIsizeEntry *entry = &info->type_info_map.entries.e[type_info_map_index];
				Type *t = cast(Type *)cast(uintptr)entry->key.key;
				t = default_type(t);
				isize entry_index = entry->value;

				ssaValue *tag = NULL;

				switch (t->kind) {
				case Type_Named: {
					tag = ssa_add_local_generated(proc, t_type_info_named);

					// TODO(bill): Which is better? The mangled name or actual name?
					ssaValue *name = ssa_make_const_string(a, t->Named.type_name->token.string);
					ssaValue *gtip = ssa_get_type_info_ptr(proc, type_info_data, t->Named.base);

					ssa_emit_store(proc, ssa_emit_struct_ep(proc, tag, 0), name);
					ssa_emit_store(proc, ssa_emit_struct_ep(proc, tag, 1), gtip);
				} break;

				case Type_Basic:
					switch (t->Basic.kind) {
					case Basic_bool:
						tag = ssa_add_local_generated(proc, t_type_info_boolean);
						break;
					case Basic_i8:
					case Basic_u8:
					case Basic_i16:
					case Basic_u16:
					case Basic_i32:
					case Basic_u32:
					case Basic_i64:
					case Basic_u64:
					// case Basic_i128:
					// case Basic_u128:
					case Basic_int:
					case Basic_uint: {
						tag = ssa_add_local_generated(proc, t_type_info_integer);
						bool is_unsigned = (t->Basic.flags & BasicFlag_Unsigned) != 0;
						ssaValue *bits = ssa_make_const_int(a, type_size_of(m->sizes, a, t));
						ssaValue *is_signed = ssa_make_const_bool(a, !is_unsigned);
						ssa_emit_store(proc, ssa_emit_struct_ep(proc, tag, 0), bits);
						ssa_emit_store(proc, ssa_emit_struct_ep(proc, tag, 1), is_signed);
					} break;

					// case Basic_f16:
					case Basic_f32:
					case Basic_f64:
					// case Basic_f128:
					{
						tag = ssa_add_local_generated(proc, t_type_info_float);
						ssaValue *bits = ssa_make_const_int(a, type_size_of(m->sizes, a, t));
						ssa_emit_store(proc, ssa_emit_struct_ep(proc, tag, 0), bits);
					} break;

					case Basic_rawptr:
						tag = ssa_add_local_generated(proc, t_type_info_pointer);
						break;

					case Basic_string:
						tag = ssa_add_local_generated(proc, t_type_info_string);
						break;

					case Basic_any:
						tag = ssa_add_local_generated(proc, t_type_info_any);
						break;
					}
					break;

				case Type_Pointer: {
					tag = ssa_add_local_generated(proc, t_type_info_pointer);
					ssaValue *gep = ssa_get_type_info_ptr(proc, type_info_data, t->Pointer.elem);
					ssa_emit_store(proc, ssa_emit_struct_ep(proc, tag, 0), gep);
				} break;
				case Type_Maybe: {
					tag = ssa_add_local_generated(proc, t_type_info_maybe);
					ssaValue *gep = ssa_get_type_info_ptr(proc, type_info_data, t->Maybe.elem);
					ssa_emit_store(proc, ssa_emit_struct_ep(proc, tag, 0), gep);
				} break;
				case Type_Array: {
					tag = ssa_add_local_generated(proc, t_type_info_array);
					ssaValue *gep = ssa_get_type_info_ptr(proc, type_info_data, t->Array.elem);
					ssa_emit_store(proc, ssa_emit_struct_ep(proc, tag, 0), gep);

					isize ez = type_size_of(m->sizes, a, t->Array.elem);
					ssaValue *elem_size = ssa_emit_struct_ep(proc, tag, 1);
					ssa_emit_store(proc, elem_size, ssa_make_const_int(a, ez));

					ssaValue *count = ssa_emit_struct_ep(proc, tag, 2);
					ssa_emit_store(proc, count, ssa_make_const_int(a, t->Array.count));

				} break;
				case Type_Slice: {
					tag = ssa_add_local_generated(proc, t_type_info_slice);
					ssaValue *gep = ssa_get_type_info_ptr(proc, type_info_data, t->Slice.elem);
					ssa_emit_store(proc, ssa_emit_struct_ep(proc, tag, 0), gep);

					isize ez = type_size_of(m->sizes, a, t->Slice.elem);
					ssaValue *elem_size = ssa_emit_struct_ep(proc, tag, 1);
					ssa_emit_store(proc, elem_size, ssa_make_const_int(a, ez));

				} break;
				case Type_Vector: {
					tag = ssa_add_local_generated(proc, t_type_info_vector);
					ssaValue *gep = ssa_get_type_info_ptr(proc, type_info_data, t->Vector.elem);
					ssa_emit_store(proc, ssa_emit_struct_ep(proc, tag, 0), gep);

					isize ez = type_size_of(m->sizes, a, t->Vector.elem);
					ssa_emit_store(proc, ssa_emit_struct_ep(proc, tag, 1), ssa_make_const_int(a, ez));
					ssa_emit_store(proc, ssa_emit_struct_ep(proc, tag, 2), ssa_make_const_int(a, t->Vector.count));
					ssa_emit_store(proc, ssa_emit_struct_ep(proc, tag, 3), ssa_make_const_int(a, type_align_of(m->sizes, a, t)));

				} break;
				case Type_Record: {
					switch (t->Record.kind) {
					case TypeRecord_Struct: {
						tag = ssa_add_local_generated(proc, t_type_info_struct);

						{
							ssaValue *packed  = ssa_make_const_bool(a, t->Record.struct_is_packed);
							ssaValue *ordered = ssa_make_const_bool(a, t->Record.struct_is_ordered);
							ssaValue *size    = ssa_make_const_int(a, type_size_of(m->sizes, a, t));
							ssaValue *align   = ssa_make_const_int(a, type_align_of(m->sizes, a, t));
							ssa_emit_store(proc, ssa_emit_struct_ep(proc, tag, 1), size);
							ssa_emit_store(proc, ssa_emit_struct_ep(proc, tag, 2), align);
							ssa_emit_store(proc, ssa_emit_struct_ep(proc, tag, 3), packed);
							ssa_emit_store(proc, ssa_emit_struct_ep(proc, tag, 4), ordered);
						}

						ssaValue *memory = ssa_type_info_member_offset(proc, type_info_member_data, t->Record.field_count, &type_info_member_index);

						type_set_offsets(m->sizes, a, t); // NOTE(bill): Just incase the offsets have not been set yet
						for (isize source_index = 0; source_index < t->Record.field_count; source_index++) {
							// TODO(bill): Order fields in source order not layout order
							Entity *f = t->Record.fields_in_src_order[source_index];
							ssaValue *tip = ssa_get_type_info_ptr(proc, type_info_data, f->type);
							i64 foffset = t->Record.struct_offsets[f->Variable.field_index];
							GB_ASSERT(f->kind == Entity_Variable && f->flags & EntityFlag_Field);

							ssaValue *field     = ssa_emit_ptr_offset(proc, memory, ssa_make_const_int(a, source_index));
							ssaValue *name      = ssa_emit_struct_ep(proc, field, 0);
							ssaValue *type_info = ssa_emit_struct_ep(proc, field, 1);
							ssaValue *offset    = ssa_emit_struct_ep(proc, field, 2);

							if (f->token.string.len > 0) {
								ssa_emit_store(proc, name, ssa_make_const_string(a, f->token.string));
							}
							ssa_emit_store(proc, type_info, tip);
							ssa_emit_store(proc, offset, ssa_make_const_int(a, foffset));
						}

						Type *slice_type = make_type_slice(a, t_type_info_member);
						Type *slice_type_ptr = make_type_pointer(a, slice_type);
						ssaValue *slice = ssa_emit_struct_ep(proc, tag, 0);
						ssaValue *field_count = ssa_make_const_int(a, t->Record.field_count);

						ssaValue *elem = ssa_emit_struct_ep(proc, slice, 0);
						ssaValue *len  = ssa_emit_struct_ep(proc, slice, 1);
						ssaValue *cap  = ssa_emit_struct_ep(proc, slice, 2);

						ssa_emit_store(proc, elem, memory);
						ssa_emit_store(proc, len, field_count);
						ssa_emit_store(proc, cap, field_count);
					} break;
					case TypeRecord_Union:
						tag = ssa_add_local_generated(proc, t_type_info_union);
						{
							ssaValue *size    = ssa_make_const_int(a, type_size_of(m->sizes, a, t));
							ssaValue *align   = ssa_make_const_int(a, type_align_of(m->sizes, a, t));
							ssa_emit_store(proc, ssa_emit_struct_ep(proc, tag, 1),  size);
							ssa_emit_store(proc, ssa_emit_struct_ep(proc, tag, 2),  align);
						}
						break;
					case TypeRecord_RawUnion: {
						tag = ssa_add_local_generated(proc, t_type_info_raw_union);
						{
							ssaValue *size    = ssa_make_const_int(a, type_size_of(m->sizes, a, t));
							ssaValue *align   = ssa_make_const_int(a, type_align_of(m->sizes, a, t));
							ssa_emit_store(proc, ssa_emit_struct_ep(proc, tag, 1),  size);
							ssa_emit_store(proc, ssa_emit_struct_ep(proc, tag, 2),  align);
						}

						ssaValue *memory = ssa_type_info_member_offset(proc, type_info_member_data, t->Record.field_count, &type_info_member_index);

						for (isize i = 0; i < t->Record.field_count; i++) {
							ssaValue *field     = ssa_emit_ptr_offset(proc, memory, ssa_make_const_int(a, i));
							ssaValue *name      = ssa_emit_struct_ep(proc, field, 0);
							ssaValue *type_info = ssa_emit_struct_ep(proc, field, 1);
							ssaValue *offset    = ssa_emit_struct_ep(proc, field, 2);

							Entity *f = t->Record.fields[i];
							ssaValue *tip = ssa_get_type_info_ptr(proc, type_info_data, f->type);

							if (f->token.string.len > 0) {
								ssa_emit_store(proc, name, ssa_make_const_string(a, f->token.string));
							}
							ssa_emit_store(proc, type_info, tip);
							ssa_emit_store(proc, offset, ssa_make_const_int(a, 0));
						}

						Type *slice_type = make_type_slice(a, t_type_info_member);
						Type *slice_type_ptr = make_type_pointer(a, slice_type);
						ssaValue *slice = ssa_emit_struct_ep(proc, tag, 0);
						ssaValue *field_count = ssa_make_const_int(a, t->Record.field_count);

						ssaValue *elem = ssa_emit_struct_ep(proc, slice, 0);
						ssaValue *len  = ssa_emit_struct_ep(proc, slice, 1);
						ssaValue *cap  = ssa_emit_struct_ep(proc, slice, 2);

						ssa_emit_store(proc, elem, memory);
						ssa_emit_store(proc, len, field_count);
						ssa_emit_store(proc, cap, field_count);
					} break;
					}
				} break;

				case Type_Tuple: {
					tag = ssa_add_local_generated(proc, t_type_info_tuple);

					{
						ssaValue *align = ssa_make_const_int(a, type_align_of(m->sizes, a, t));
						ssa_emit_store(proc, ssa_emit_struct_ep(proc, tag, 2), align);
					}

					ssaValue *memory = ssa_type_info_member_offset(proc, type_info_member_data, t->Tuple.variable_count, &type_info_member_index);

					for (isize i = 0; i < t->Tuple.variable_count; i++) {
						ssaValue *field     = ssa_emit_ptr_offset(proc, memory, ssa_make_const_int(a, i));
						ssaValue *name      = ssa_emit_struct_ep(proc, field, 0);
						ssaValue *type_info = ssa_emit_struct_ep(proc, field, 1);
						// NOTE(bill): offset is not used for tuples

						Entity *f = t->Tuple.variables[i];
						ssaValue *tip = ssa_get_type_info_ptr(proc, type_info_data, f->type);

						if (f->token.string.len > 0) {
							ssa_emit_store(proc, name, ssa_make_const_string(a, f->token.string));
						}
						ssa_emit_store(proc, type_info, tip);
					}

					Type *slice_type = make_type_slice(a, t_type_info_member);
					Type *slice_type_ptr = make_type_pointer(a, slice_type);
					ssaValue *slice = ssa_emit_struct_ep(proc, tag, 0);
					ssaValue *variable_count = ssa_make_const_int(a, t->Tuple.variable_count);

					ssaValue *elem = ssa_emit_struct_ep(proc, slice, 0);
					ssaValue *len  = ssa_emit_struct_ep(proc, slice, 1);
					ssaValue *cap  = ssa_emit_struct_ep(proc, slice, 2);

					ssa_emit_store(proc, elem, memory);
					ssa_emit_store(proc, len, variable_count);
					ssa_emit_store(proc, cap, variable_count);
				} break;

				case Type_Proc: {
					tag = ssa_add_local_generated(proc, t_type_info_procedure);

					ssaValue *params   = ssa_emit_struct_ep(proc, tag, 0);
					ssaValue *results  = ssa_emit_struct_ep(proc, tag, 1);
					ssaValue *variadic = ssa_emit_struct_ep(proc, tag, 2);

					if (t->Proc.params) {
						ssa_emit_store(proc, params, ssa_get_type_info_ptr(proc, type_info_data, t->Proc.params));
					}
					if (t->Proc.results) {
						ssa_emit_store(proc, results, ssa_get_type_info_ptr(proc, type_info_data, t->Proc.results));
					}
					ssa_emit_store(proc, variadic, ssa_make_const_bool(a, t->Proc.variadic));

					// TODO(bill): Type_Info for procedures
				} break;
				}

				if (tag != NULL) {
					ssaValue *gep = ssa_emit_array_epi(proc, type_info_data, entry_index);
					ssaValue *val = ssa_emit_conv(proc, ssa_emit_load(proc, tag), t_type_info);
					ssa_emit_store(proc, gep, val);
				}
			}
		}

		ssa_end_procedure_body(proc);
	}

	for_array(i, m->procs_to_generate) {
		ssa_build_proc(m->procs_to_generate.e[i], m->procs_to_generate.e[i]->Proc.parent);
	}


	// m->layout = str_lit("e-p:64:64:64-i1:8:8-i8:8:8-i16:16:16-i32:32:32-i64:64:64-f32:32:32-f64:64:64-v64:64:64-v128:128:128-a0:0:64-s0:64:64-f80:128:128-n8:16:32:64");
}

