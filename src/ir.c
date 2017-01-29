typedef struct irProcedure irProcedure;
typedef struct irBlock irBlock;
typedef struct irValue irValue;
typedef struct irDebugInfo irDebugInfo;

typedef Array(irValue *) irValueArray;

#define MAP_TYPE irValue *
#define MAP_PROC map_ir_value_
#define MAP_NAME MapIrValue
#include "map.c"

#define MAP_TYPE irDebugInfo *
#define MAP_PROC map_ir_debug_info_
#define MAP_NAME MapIrDebugInfo
#include "map.c"

typedef struct irModule {
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
	MapIrValue      values;      // Key: Entity *
	MapIrValue      members;     // Key: String
	MapString       type_names;  // Key: Type *
	MapIrDebugInfo  debug_info;  // Key: Unique pointer
	i32             global_string_index;
	i32             global_array_index; // For ConstantSlice

	Entity *        entry_point_entity;

	Array(irProcedure *) procs;             // NOTE(bill): All procedures with bodies
	irValueArray         procs_to_generate; // NOTE(bill): Procedures to generate

	Array(String) foreign_library_paths; // Only the ones that were used
} irModule;

// NOTE(bill): For more info, see https://en.wikipedia.org/wiki/Dominator_(graph_theory)
typedef struct irDomNode {
	irBlock *        idom; // Parent (Immediate Dominator)
	Array(irBlock *) children;
	i32              pre, post; // Ordering in tree
} irDomNode;


typedef struct irBlock {
	i32          index;
	String       label;
	irProcedure *parent;
	AstNode *    node; // Can be NULL
	Scope *      scope;
	isize        scope_index;
	irDomNode    dom;
	i32          gaps;

	irValueArray instrs;
	irValueArray locals;

	Array(irBlock *) preds;
	Array(irBlock *) succs;
} irBlock;

typedef struct irTargetList irTargetList;
struct irTargetList {
	irTargetList *prev;
	irBlock *     break_;
	irBlock *     continue_;
	irBlock *     fallthrough_;
};

typedef enum irDeferExitKind {
	irDeferExit_Default,
	irDeferExit_Return,
	irDeferExit_Branch,
} irDeferExitKind;
typedef enum irDeferKind {
	irDefer_Node,
	irDefer_Instr,
} irDeferKind;

typedef struct irDefer {
	irDeferKind kind;
	isize         scope_index;
	irBlock *   block;
	union {
		AstNode *stmt;
		// NOTE(bill): `instr` will be copied every time to create a new one
		irValue *instr;
	};
} irDefer;

struct irProcedure {
	irProcedure *        parent;
	Array(irProcedure *) children;

	Entity *             entity;
	irModule *           module;
	String               name;
	Type *               type;
	AstNode *            type_expr;
	AstNode *            body;
	u64                  tags;

	irValueArray         params;
	Array(irDefer)       defer_stmts;
	Array(irBlock *)     blocks;
	i32                  scope_index;
	irBlock *            decl_block;
	irBlock *            entry_block;
	irBlock *            curr_block;
	irTargetList *       target_list;
	irValueArray         referrers;

	i32                  local_count;
	i32                  instr_count;
	i32                  block_count;
};

#define IR_STARTUP_RUNTIME_PROC_NAME  "__$startup_runtime"
#define IR_TYPE_INFO_DATA_NAME        "__$type_info_data"
#define IR_TYPE_INFO_DATA_MEMBER_NAME "__$type_info_data_member"


#define IR_INSTR_KINDS \
	IR_INSTR_KIND(Comment, struct { String text; }) \
	IR_INSTR_KIND(Local,   struct { \
		Entity *      entity; \
		Type *        type; \
		bool          zero_initialized; \
		irValueArray referrers; \
	}) \
	IR_INSTR_KIND(ZeroInit, struct { irValue *address; }) \
	IR_INSTR_KIND(Store,    struct { irValue *address, *value; }) \
	IR_INSTR_KIND(Load,     struct { Type *type; irValue *address; }) \
	IR_INSTR_KIND(PtrOffset, struct { \
		irValue *address; \
		irValue *offset; \
	}) \
	IR_INSTR_KIND(ArrayElementPtr, struct { \
		irValue *address; \
		Type *    result_type; \
		irValue *elem_index; \
	}) \
	IR_INSTR_KIND(StructElementPtr, struct {  \
		irValue *address; \
		Type *    result_type; \
		i32       elem_index; \
	}) \
	IR_INSTR_KIND(StructExtractValue, struct { \
		irValue *address; \
		Type *    result_type; \
		i32       index; \
	}) \
	IR_INSTR_KIND(UnionTagPtr, struct { \
		irValue *address; \
		Type     *type; /* ^int */  \
	}) \
	IR_INSTR_KIND(UnionTagValue, struct { \
		irValue *address; \
		Type     *type; /* int */ \
	}) \
	IR_INSTR_KIND(Conv, struct { \
		irConvKind kind; \
		irValue *value; \
		Type *from, *to; \
	}) \
	IR_INSTR_KIND(Jump, struct { irBlock *block; }) \
	IR_INSTR_KIND(If, struct { \
		irValue *cond; \
		irBlock *true_block; \
		irBlock *false_block; \
	}) \
	IR_INSTR_KIND(Return, struct { irValue *value; }) \
	IR_INSTR_KIND(Select, struct { \
		irValue *cond; \
		irValue *true_value; \
		irValue *false_value; \
	}) \
	IR_INSTR_KIND(Phi, struct { irValueArray edges; Type *type; }) \
	IR_INSTR_KIND(Unreachable, i32) \
	IR_INSTR_KIND(UnaryOp, struct { \
		Type *    type; \
		TokenKind op; \
		irValue *expr; \
	}) \
	IR_INSTR_KIND(BinaryOp, struct { \
		Type *    type; \
		TokenKind op; \
		irValue *left, *right; \
	}) \
	IR_INSTR_KIND(Call, struct { \
		Type *    type; /* return type */  \
		irValue *value; \
		irValue **args; \
		isize      arg_count; \
	}) \
	IR_INSTR_KIND(VectorExtractElement, struct { \
		irValue *vector; \
		irValue *index; \
	}) \
	IR_INSTR_KIND(VectorInsertElement, struct { \
		irValue *vector; \
		irValue *elem; \
		irValue *index; \
	}) \
	IR_INSTR_KIND(VectorShuffle, struct { \
		irValue *vector; \
		i32 *     indices; \
		i32       index_count; \
		Type *    type; \
	}) \
	IR_INSTR_KIND(StartupRuntime, i32) \
	IR_INSTR_KIND(BoundsCheck, struct { \
		TokenPos  pos; \
		irValue *index; \
		irValue *len; \
	}) \
	IR_INSTR_KIND(SliceBoundsCheck, struct { \
		TokenPos  pos; \
		irValue *low; \
		irValue *high; \
		bool      is_substring; \
	})

#define IR_CONV_KINDS \
	IR_CONV_KIND(trunc) \
	IR_CONV_KIND(zext) \
	IR_CONV_KIND(fptrunc) \
	IR_CONV_KIND(fpext) \
	IR_CONV_KIND(fptoui) \
	IR_CONV_KIND(fptosi) \
	IR_CONV_KIND(uitofp) \
	IR_CONV_KIND(sitofp) \
	IR_CONV_KIND(ptrtoint) \
	IR_CONV_KIND(inttoptr) \
	IR_CONV_KIND(bitcast)

typedef enum irInstrKind {
	irInstr_Invalid,
#define IR_INSTR_KIND(x, ...) GB_JOIN2(irInstr_, x),
	IR_INSTR_KINDS
#undef IR_INSTR_KIND
} irInstrKind;

String const ir_instr_strings[] = {
	{cast(u8 *)"Invalid", gb_size_of("Invalid")-1},
#define IR_INSTR_KIND(x, ...) {cast(u8 *)#x, gb_size_of(#x)-1},
	IR_INSTR_KINDS
#undef IR_INSTR_KIND
};

typedef enum irConvKind {
	irConv_Invalid,
#define IR_CONV_KIND(x) GB_JOIN2(irConv_, x),
	IR_CONV_KINDS
#undef IR_CONV_KIND
} irConvKind;

String const ir_conv_strings[] = {
	{cast(u8 *)"Invalid", gb_size_of("Invalid")-1},
#define IR_CONV_KIND(x) {cast(u8 *)#x, gb_size_of(#x)-1},
	IR_CONV_KINDS
#undef IR_CONV_KIND
};

#define IR_INSTR_KIND(k, ...) typedef __VA_ARGS__ GB_JOIN2(irInstr, k);
	IR_INSTR_KINDS
#undef IR_INSTR_KIND

typedef struct irInstr irInstr;
struct irInstr {
	irInstrKind kind;

	irBlock *parent;
	Type *type;

	union {
#define IR_INSTR_KIND(k, ...) GB_JOIN2(irInstr, k) k;
	IR_INSTR_KINDS
#undef IR_INSTR_KIND
	};
};


typedef enum irValueKind {
	irValue_Invalid,

	irValue_Constant,
	irValue_ConstantSlice,
	irValue_Nil,
	irValue_TypeName,
	irValue_Global,
	irValue_Param,

	irValue_Proc,
	irValue_Block,
	irValue_Instr,

	irValue_Count,
} irValueKind;

typedef struct irValueConstant {
	Type *     type;
	ExactValue value;
} irValueConstant;

typedef struct irValueConstantSlice {
	Type *    type;
	irValue *backing_array;
	i64       count;
} irValueConstantSlice;

typedef struct irValueNil {
	Type *type;
} irValueNil;

typedef struct irValueTypeName {
	Type * type;
	String name;
} irValueTypeName;

typedef struct irValueGlobal {
	Entity *      entity;
	Type *        type;
	irValue *    value;
	irValueArray referrers;
	bool          is_constant;
	bool          is_private;
	bool          is_thread_local;
	bool          is_unnamed_addr;
} irValueGlobal;

typedef struct irValueParam {
	irProcedure *parent;
	Entity *      entity;
	Type *        type;
	irValueArray referrers;
} irValueParam;

typedef struct irValue {
	irValueKind kind;
	i32 index;
	union {
		irValueConstant      Constant;
		irValueConstantSlice ConstantSlice;
		irValueNil           Nil;
		irValueTypeName      TypeName;
		irValueGlobal        Global;
		irValueParam         Param;
		irProcedure          Proc;
		irBlock              Block;
		irInstr              Instr;
	};
} irValue;

gb_global irValue *v_zero    = NULL;
gb_global irValue *v_one     = NULL;
gb_global irValue *v_zero32  = NULL;
gb_global irValue *v_one32   = NULL;
gb_global irValue *v_two32   = NULL;
gb_global irValue *v_false   = NULL;
gb_global irValue *v_true    = NULL;

typedef enum irAddrKind {
	irAddr_Default,
	irAddr_Vector,
} irAddrKind;

typedef struct irAddr {
	irValue *  addr;
	AstNode *    expr; // NOTE(bill): Just for testing - probably remove later
	irAddrKind kind;
	union {
		struct { irValue *index; } Vector;
	};
} irAddr;

irAddr ir_make_addr(irValue *addr, AstNode *expr) {
	irAddr v = {addr, expr};
	return v;
}
irAddr ir_make_addr_vector(irValue *addr, irValue *index, AstNode *expr) {
	irAddr v = ir_make_addr(addr, expr);
	v.kind = irAddr_Vector;
	v.Vector.index = index;
	return v;
}



typedef enum irDebugEncoding {
	irDebugBasicEncoding_Invalid       = 0,

	irDebugBasicEncoding_address       = 1,
	irDebugBasicEncoding_boolean       = 2,
	irDebugBasicEncoding_float         = 3,
	irDebugBasicEncoding_signed        = 4,
	irDebugBasicEncoding_signed_char   = 5,
	irDebugBasicEncoding_unsigned      = 6,
	irDebugBasicEncoding_unsigned_char = 7,

	irDebugBasicEncoding_member       = 13,
	irDebugBasicEncoding_pointer_type = 15,
	irDebugBasicEncoding_typedef      = 22,

	irDebugBasicEncoding_array_type       = 1,
	irDebugBasicEncoding_enumeration_type = 4,
	irDebugBasicEncoding_structure_type   = 19,
	irDebugBasicEncoding_union_type       = 23,

} irDebugEncoding;

typedef enum irDebugInfoKind {
	irDebugInfo_Invalid,

	irDebugInfo_CompileUnit,
	irDebugInfo_File,
	irDebugInfo_Scope,
	irDebugInfo_Proc,
	irDebugInfo_AllProcs,

	irDebugInfo_BasicType,      // basic types
	irDebugInfo_ProcType,
	irDebugInfo_DerivedType,    // pointer, typedef
	irDebugInfo_CompositeType,  // array, struct, enum, (raw_)union
	irDebugInfo_Enumerator,     // For irDebugInfo_CompositeType if enum
	irDebugInfo_GlobalVariable,
	irDebugInfo_LocalVariable,


	irDebugInfo_Count,
} irDebugInfoKind;

typedef struct irDebugInfo irDebugInfo;
struct irDebugInfo {
	irDebugInfoKind kind;
	i32 id;

	union {
		struct {
			AstFile *     file;
			String        producer;
			irDebugInfo *all_procs;
		} CompileUnit;
		struct {
			AstFile *file;
			String   filename;
			String   directory;
		} File;
		struct {
			irDebugInfo *parent;
			irDebugInfo *file;
			TokenPos      pos;
			Scope *       scope; // Actual scope
		} Scope;
		struct {
			Entity *      entity;
			String        name;
			irDebugInfo *file;
			TokenPos      pos;
		} Proc;
		struct {
			Array(irDebugInfo *) procs;
		} AllProcs;


		struct {
			String           name;
			i32              size;
			i32              align;
			irDebugEncoding encoding;
		} BasicType;
		struct {
			irDebugInfo *        return_type;
			Array(irDebugInfo *) param_types;
		} ProcType;
		struct {
			irDebugInfo *   base_type;
			irDebugEncoding encoding;
		} DerivedType;
		struct {
			irDebugEncoding      encoding;
			String                name;
			String                identifier;
			irDebugInfo *        file;
			TokenPos              pos;
			i32                   size;
			i32                   align;
			Array(irDebugInfo *) elements;
		} CompositeType;
		struct {
			String name;
			i64    value;
		} Enumerator;
		struct {
			String        name;
			String        linkage_name;
			irDebugInfo *scope;
			irDebugInfo *file;
			TokenPos      pos;
			irValue     *variable;
			irDebugInfo *declaration;
		} GlobalVariable;
		struct {
			String        name;
			irDebugInfo *scope;
			irDebugInfo *file;
			TokenPos      pos;
			i32           arg; // Non-zero if proc parameter
			irDebugInfo *type;
		} LocalVariable;
	};
};

typedef struct irGen {
	irModule module;
	gbFile    output_file;
	bool       opt_called;
} irGen;



Type *ir_type(irValue *value);
Type *ir_instr_type(irInstr *instr) {
	switch (instr->kind) {
	case irInstr_Local:
		return instr->Local.type;
	case irInstr_Load:
		return instr->Load.type;
	case irInstr_StructElementPtr:
		return instr->StructElementPtr.result_type;
	case irInstr_ArrayElementPtr:
		return instr->ArrayElementPtr.result_type;
	case irInstr_PtrOffset:
		return ir_type(instr->PtrOffset.address);
	case irInstr_Phi:
		return instr->Phi.type;
	case irInstr_StructExtractValue:
		return instr->StructExtractValue.result_type;
	case irInstr_UnionTagPtr:
		return instr->UnionTagPtr.type;
	case irInstr_UnionTagValue:
		return instr->UnionTagValue.type;
	case irInstr_UnaryOp:
		return instr->UnaryOp.type;
	case irInstr_BinaryOp:
		return instr->BinaryOp.type;
	case irInstr_Conv:
		return instr->Conv.to;
	case irInstr_Select:
		return ir_type(instr->Select.true_value);
	case irInstr_Call: {
		Type *pt = base_type(instr->Call.type);
		if (pt != NULL) {
			if (pt->kind == Type_Tuple && pt->Tuple.variable_count == 1) {
				return pt->Tuple.variables[0]->type;
			}
			return pt;
		}
		return NULL;
	} break;
	case irInstr_VectorExtractElement: {
		Type *vt = ir_type(instr->VectorExtractElement.vector);
		Type *bt = base_vector_type(vt);
		GB_ASSERT(!is_type_vector(bt));
		return bt;
	} break;
	case irInstr_VectorInsertElement:
		return ir_type(instr->VectorInsertElement.vector);
	case irInstr_VectorShuffle:
		return instr->VectorShuffle.type;
	}
	return NULL;
}

Type *ir_type(irValue *value) {
	switch (value->kind) {
	case irValue_Constant:
		return value->Constant.type;
	case irValue_ConstantSlice:
		return value->ConstantSlice.type;
	case irValue_Nil:
		return value->Nil.type;
	case irValue_TypeName:
		return value->TypeName.type;
	case irValue_Global:
		return value->Global.type;
	case irValue_Param:
		return value->Param.type;
	case irValue_Proc:
		return value->Proc.type;
	case irValue_Instr:
		return ir_instr_type(&value->Instr);
	}
	return NULL;
}

Type *ir_addr_type(irAddr lval) {
	if (lval.addr != NULL) {
		Type *t = ir_type(lval.addr);
		GB_ASSERT(is_type_pointer(t));
		return type_deref(t);
	}
	return NULL;
}



bool ir_is_blank_ident(AstNode *node) {
	if (node->kind == AstNode_Ident) {
		ast_node(i, Ident, node);
		return is_blank_ident(i->string);
	}
	return false;
}


irInstr *ir_get_last_instr(irBlock *block) {
	if (block != NULL) {
		isize len = block->instrs.count;
		if (len > 0) {
			irValue *v = block->instrs.e[len-1];
			GB_ASSERT(v->kind == irValue_Instr);
			return &v->Instr;
		}
	}
	return NULL;

}

bool ir_is_instr_terminating(irInstr *i) {
	if (i != NULL) {
		switch (i->kind) {
		case irInstr_Return:
		case irInstr_Unreachable:
			return true;
		}
	}

	return false;
}


void ir_add_edge(irBlock *from, irBlock *to) {
	array_add(&from->succs, to);
	array_add(&to->preds, from);
}

void ir_set_instr_parent(irValue *instr, irBlock *parent) {
	if (instr->kind == irValue_Instr) {
		instr->Instr.parent = parent;
	}
}

irValueArray *ir_value_referrers(irValue *v) {
	switch (v->kind) {
	case irValue_Global:
		return &v->Global.referrers;
	case irValue_Param:
		return &v->Param.referrers;
	case irValue_Proc: {
		if (v->Proc.parent != NULL) {
			return &v->Proc.referrers;
		}
		return NULL;
	}
	case irValue_Instr: {
		irInstr *i = &v->Instr;
		switch (i->kind) {
		case irInstr_Local:
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

void     ir_module_add_value    (irModule *m, Entity *e, irValue *v);
irValue *ir_emit_zero_init      (irProcedure *p, irValue *address);
irValue *ir_emit_comment        (irProcedure *p, String text);
irValue *ir_emit_store          (irProcedure *p, irValue *address, irValue *value);
irValue *ir_emit_load           (irProcedure *p, irValue *address);
void     ir_emit_jump           (irProcedure *proc, irBlock *block);
irValue *ir_emit_conv           (irProcedure *proc, irValue *value, Type *t);
irValue *ir_type_info           (irProcedure *proc, Type *type);
irValue *ir_build_expr          (irProcedure *proc, AstNode *expr);
void     ir_build_stmt          (irProcedure *proc, AstNode *node);
irValue *ir_build_cond          (irProcedure *proc, AstNode *cond, irBlock *true_block, irBlock *false_block);
void     ir_build_defer_stmt    (irProcedure *proc, irDefer d);
irAddr   ir_build_addr          (irProcedure *proc, AstNode *expr);
void     ir_build_proc          (irValue *value, irProcedure *parent);
void     ir_gen_global_type_name(irModule *m, Entity *e, String name);




irValue *ir_alloc_value(gbAllocator a, irValueKind kind) {
	irValue *v = gb_alloc_item(a, irValue);
	v->kind = kind;
	return v;
}
irValue *ir_alloc_instr(irProcedure *proc, irInstrKind kind) {
	irValue *v = ir_alloc_value(proc->module->allocator, irValue_Instr);
	v->Instr.kind = kind;
	proc->instr_count++;
	return v;
}
irDebugInfo *ir_alloc_debug_info(gbAllocator a, irDebugInfoKind kind) {
	irDebugInfo *di = gb_alloc_item(a, irDebugInfo);
	di->kind = kind;
	return di;
}




irValue *ir_make_value_type_name(gbAllocator a, String name, Type *type) {
	irValue *v = ir_alloc_value(a, irValue_TypeName);
	v->TypeName.name = name;
	v->TypeName.type = type;
	return v;
}

irValue *ir_make_value_global(gbAllocator a, Entity *e, irValue *value) {
	irValue *v = ir_alloc_value(a, irValue_Global);
	v->Global.entity = e;
	v->Global.type = make_type_pointer(a, e->type);
	v->Global.value = value;
	array_init(&v->Global.referrers, heap_allocator()); // TODO(bill): Replace heap allocator here
	return v;
}
irValue *ir_make_value_param(gbAllocator a, irProcedure *parent, Entity *e) {
	irValue *v = ir_alloc_value(a, irValue_Param);
	v->Param.parent = parent;
	v->Param.entity = e;
	v->Param.type   = e->type;
	array_init(&v->Param.referrers, heap_allocator()); // TODO(bill): Replace heap allocator here
	return v;
}
irValue *ir_make_value_nil(gbAllocator a, Type *type) {
	irValue *v = ir_alloc_value(a, irValue_Nil);
	v->Nil.type = type;
	return v;
}



irValue *ir_make_instr_local(irProcedure *p, Entity *e, bool zero_initialized) {
	irValue *v = ir_alloc_instr(p, irInstr_Local);
	irInstr *i = &v->Instr;
	i->Local.entity = e;
	i->Local.type = make_type_pointer(p->module->allocator, e->type);
	i->Local.zero_initialized = zero_initialized;
	array_init(&i->Local.referrers, heap_allocator()); // TODO(bill): Replace heap allocator here
	ir_module_add_value(p->module, e, v);
	return v;
}


irValue *ir_make_instr_store(irProcedure *p, irValue *address, irValue *value) {
	irValue *v = ir_alloc_instr(p, irInstr_Store);
	irInstr *i = &v->Instr;
	i->Store.address = address;
	i->Store.value = value;
	return v;
}

irValue *ir_make_instr_zero_init(irProcedure *p, irValue *address) {
	irValue *v = ir_alloc_instr(p, irInstr_ZeroInit);
	irInstr *i = &v->Instr;
	i->ZeroInit.address = address;
	return v;
}

irValue *ir_make_instr_load(irProcedure *p, irValue *address) {
	irValue *v = ir_alloc_instr(p, irInstr_Load);
	irInstr *i = &v->Instr;
	i->Load.address = address;
	i->Load.type = type_deref(ir_type(address));
	return v;
}

irValue *ir_make_instr_array_element_ptr(irProcedure *p, irValue *address, irValue *elem_index) {
	irValue *v = ir_alloc_instr(p, irInstr_ArrayElementPtr);
	irInstr *i = &v->Instr;
	Type *t = ir_type(address);
	GB_ASSERT_MSG(is_type_pointer(t), "%s", type_to_string(t));
	t = base_type(type_deref(t));
	GB_ASSERT(is_type_array(t) || is_type_vector(t));

	Type *result_type = make_type_pointer(p->module->allocator, t->Array.elem);

	i->ArrayElementPtr.address = address;
	i->ArrayElementPtr.elem_index = elem_index;
	i->ArrayElementPtr.result_type = result_type;

	GB_ASSERT_MSG(is_type_pointer(ir_type(address)),
	              "%s", type_to_string(ir_type(address)));
	return v;
}
irValue *ir_make_instr_struct_element_ptr(irProcedure *p, irValue *address, i32 elem_index, Type *result_type) {
	irValue *v = ir_alloc_instr(p, irInstr_StructElementPtr);
	irInstr *i = &v->Instr;
	i->StructElementPtr.address     = address;
	i->StructElementPtr.elem_index  = elem_index;
	i->StructElementPtr.result_type = result_type;

	GB_ASSERT_MSG(is_type_pointer(ir_type(address)),
	              "%s", type_to_string(ir_type(address)));
	return v;
}
irValue *ir_make_instr_ptr_offset(irProcedure *p, irValue *address, irValue *offset) {
	irValue *v = ir_alloc_instr(p, irInstr_PtrOffset);
	irInstr *i = &v->Instr;
	i->PtrOffset.address = address;
	i->PtrOffset.offset  = offset;

	GB_ASSERT_MSG(is_type_pointer(ir_type(address)),
	              "%s", type_to_string(ir_type(address)));
	GB_ASSERT_MSG(is_type_integer(ir_type(offset)),
	              "%s", type_to_string(ir_type(address)));

	return v;
}



irValue *ir_make_instr_struct_extract_value(irProcedure *p, irValue *address, i32 index, Type *result_type) {
	irValue *v = ir_alloc_instr(p, irInstr_StructExtractValue);
	irInstr *i = &v->Instr;
	i->StructExtractValue.address = address;
	i->StructExtractValue.index = index;
	i->StructExtractValue.result_type = result_type;
	return v;
}

irValue *ir_make_instr_union_tag_ptr(irProcedure *p, irValue *address) {
	irValue *v = ir_alloc_instr(p, irInstr_UnionTagPtr);
	irInstr *i = &v->Instr;
	i->UnionTagPtr.address = address;
	i->UnionTagPtr.type = t_int_ptr;
	return v;
}

irValue *ir_make_instr_union_tag_value(irProcedure *p, irValue *address) {
	irValue *v = ir_alloc_instr(p, irInstr_UnionTagValue);
	irInstr *i = &v->Instr;
	i->UnionTagValue.address = address;
	i->UnionTagValue.type = t_int_ptr;
	return v;
}

irValue *ir_make_instr_unary_op(irProcedure *p, TokenKind op, irValue *expr, Type *type) {
	irValue *v = ir_alloc_instr(p, irInstr_UnaryOp);
	irInstr *i = &v->Instr;
	i->UnaryOp.op = op;
	i->UnaryOp.expr = expr;
	i->UnaryOp.type = type;
	return v;
}


irValue *ir_make_instr_binary_op(irProcedure *p, TokenKind op, irValue *left, irValue *right, Type *type) {
	irValue *v = ir_alloc_instr(p, irInstr_BinaryOp);
	irInstr *i = &v->Instr;
	i->BinaryOp.op = op;
	i->BinaryOp.left = left;
	i->BinaryOp.right = right;
	i->BinaryOp.type = type;
	return v;
}

irValue *ir_make_instr_jump(irProcedure *p, irBlock *block) {
	irValue *v = ir_alloc_instr(p, irInstr_Jump);
	irInstr *i = &v->Instr;
	i->Jump.block = block;
	return v;
}
irValue *ir_make_instr_if(irProcedure *p, irValue *cond, irBlock *true_block, irBlock *false_block) {
	irValue *v = ir_alloc_instr(p, irInstr_If);
	irInstr *i = &v->Instr;
	i->If.cond = cond;
	i->If.true_block = true_block;
	i->If.false_block = false_block;
	return v;
}


irValue *ir_make_instr_phi(irProcedure *p, irValueArray edges, Type *type) {
	irValue *v = ir_alloc_instr(p, irInstr_Phi);
	irInstr *i = &v->Instr;
	i->Phi.edges = edges;
	i->Phi.type = type;
	return v;
}

irValue *ir_make_instr_unreachable(irProcedure *p) {
	irValue *v = ir_alloc_instr(p, irInstr_Unreachable);
	return v;
}

irValue *ir_make_instr_return(irProcedure *p, irValue *value) {
	irValue *v = ir_alloc_instr(p, irInstr_Return);
	v->Instr.Return.value = value;
	return v;
}

irValue *ir_make_instr_select(irProcedure *p, irValue *cond, irValue *t, irValue *f) {
	irValue *v = ir_alloc_instr(p, irInstr_Select);
	v->Instr.Select.cond = cond;
	v->Instr.Select.true_value = t;
	v->Instr.Select.false_value = f;
	return v;
}

irValue *ir_make_instr_call(irProcedure *p, irValue *value, irValue **args, isize arg_count, Type *result_type) {
	irValue *v = ir_alloc_instr(p, irInstr_Call);
	v->Instr.Call.value = value;
	v->Instr.Call.args = args;
	v->Instr.Call.arg_count = arg_count;
	v->Instr.Call.type = result_type;
	return v;
}

irValue *ir_make_instr_conv(irProcedure *p, irConvKind kind, irValue *value, Type *from, Type *to) {
	irValue *v = ir_alloc_instr(p, irInstr_Conv);
	v->Instr.Conv.kind = kind;
	v->Instr.Conv.value = value;
	v->Instr.Conv.from = from;
	v->Instr.Conv.to = to;
	return v;
}

irValue *ir_make_instr_extract_element(irProcedure *p, irValue *vector, irValue *index) {
	irValue *v = ir_alloc_instr(p, irInstr_VectorExtractElement);
	v->Instr.VectorExtractElement.vector = vector;
	v->Instr.VectorExtractElement.index = index;
	return v;
}

irValue *ir_make_instr_insert_element(irProcedure *p, irValue *vector, irValue *elem, irValue *index) {
	irValue *v = ir_alloc_instr(p, irInstr_VectorInsertElement);
	v->Instr.VectorInsertElement.vector = vector;
	v->Instr.VectorInsertElement.elem   = elem;
	v->Instr.VectorInsertElement.index  = index;
	return v;
}

irValue *ir_make_instr_vector_shuffle(irProcedure *p, irValue *vector, i32 *indices, isize index_count) {
	irValue *v = ir_alloc_instr(p, irInstr_VectorShuffle);
	v->Instr.VectorShuffle.vector      = vector;
	v->Instr.VectorShuffle.indices     = indices;
	v->Instr.VectorShuffle.index_count = index_count;

	Type *vt = base_type(ir_type(vector));
	v->Instr.VectorShuffle.type = make_type_vector(p->module->allocator, vt->Vector.elem, index_count);

	return v;
}

irValue *ir_make_instr_comment(irProcedure *p, String text) {
	irValue *v = ir_alloc_instr(p, irInstr_Comment);
	v->Instr.Comment.text = text;
	return v;
}

irValue *ir_make_instr_bounds_check(irProcedure *p, TokenPos pos, irValue *index, irValue *len) {
	irValue *v = ir_alloc_instr(p, irInstr_BoundsCheck);
	v->Instr.BoundsCheck.pos   = pos;
	v->Instr.BoundsCheck.index = index;
	v->Instr.BoundsCheck.len   = len;
	return v;
}
irValue *ir_make_instr_slice_bounds_check(irProcedure *p, TokenPos pos, irValue *low, irValue *high, bool is_substring) {
	irValue *v = ir_alloc_instr(p, irInstr_SliceBoundsCheck);
	v->Instr.SliceBoundsCheck.pos  = pos;
	v->Instr.SliceBoundsCheck.low  = low;
	v->Instr.SliceBoundsCheck.high = high;
	v->Instr.SliceBoundsCheck.is_substring = is_substring;
	return v;
}



irValue *ir_make_value_constant(gbAllocator a, Type *type, ExactValue value) {
	irValue *v = ir_alloc_value(a, irValue_Constant);
	v->Constant.type  = type;
	v->Constant.value = value;
	return v;
}


irValue *ir_make_value_constant_slice(gbAllocator a, Type *type, irValue *backing_array, i64 count) {
	irValue *v = ir_alloc_value(a, irValue_ConstantSlice);
	v->ConstantSlice.type = type;
	v->ConstantSlice.backing_array = backing_array;
	v->ConstantSlice.count = count;
	return v;
}

irValue *ir_make_const_int(gbAllocator a, i64 i) {
	return ir_make_value_constant(a, t_int, make_exact_value_integer(i));
}
irValue *ir_make_const_i32(gbAllocator a, i64 i) {
	return ir_make_value_constant(a, t_i32, make_exact_value_integer(i));
}
irValue *ir_make_const_i64(gbAllocator a, i64 i) {
	return ir_make_value_constant(a, t_i64, make_exact_value_integer(i));
}
irValue *ir_make_const_f32(gbAllocator a, f32 f) {
	return ir_make_value_constant(a, t_f32, make_exact_value_float(f));
}
irValue *ir_make_const_f64(gbAllocator a, f64 f) {
	return ir_make_value_constant(a, t_f64, make_exact_value_float(f));
}
irValue *ir_make_const_bool(gbAllocator a, bool b) {
	return ir_make_value_constant(a, t_bool, make_exact_value_bool(b != 0));
}
irValue *ir_make_const_string(gbAllocator a, String s) {
	return ir_make_value_constant(a, t_string, make_exact_value_string(s));
}

irValue *ir_make_value_procedure(gbAllocator a, irModule *m, Entity *entity, Type *type, AstNode *type_expr, AstNode *body, String name) {
	irValue *v = ir_alloc_value(a, irValue_Proc);
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

irBlock *ir_add_block(irProcedure *proc, AstNode *node, char *label) {
	Scope *scope = NULL;
	if (node != NULL) {
		Scope **found = map_scope_get(&proc->module->info->scopes, hash_pointer(node));
		if (found) {
			scope = *found;
		} else {
			GB_PANIC("Block scope not found for %.*s", LIT(ast_node_strings[node->kind]));
		}
	}

	irValue *v = ir_alloc_value(proc->module->allocator, irValue_Block);
	v->Block.label  = make_string_c(label);
	v->Block.node   = node;
	v->Block.scope  = scope;
	v->Block.parent = proc;

	array_init(&v->Block.instrs, heap_allocator());
	array_init(&v->Block.locals, heap_allocator());

	array_init(&v->Block.preds,  heap_allocator());
	array_init(&v->Block.succs,  heap_allocator());

	irBlock *block = &v->Block;

	array_add(&proc->blocks, block);
	proc->block_count++;

	return block;
}





irDefer ir_add_defer_node(irProcedure *proc, isize scope_index, AstNode *stmt) {
	irDefer d = {irDefer_Node};
	d.scope_index = scope_index;
	d.block = proc->curr_block;
	d.stmt = stmt;
	array_add(&proc->defer_stmts, d);
	return d;
}


irDefer ir_add_defer_instr(irProcedure *proc, isize scope_index, irValue *instr) {
	irDefer d = {irDefer_Instr};
	d.scope_index = proc->scope_index;
	d.block = proc->curr_block;
	d.instr = instr; // NOTE(bill): It will make a copy everytime it is called
	array_add(&proc->defer_stmts, d);
	return d;
}



irValue *ir_add_module_constant(irModule *m, Type *type, ExactValue value) {
	gbAllocator a = m->allocator;
	// gbAllocator a = gb_heap_allocator();

	if (is_type_slice(type)) {
		ast_node(cl, CompoundLit, value.value_compound);

		isize count = cl->elems.count;
		if (count == 0) {
			return ir_make_value_nil(a, type);
		}
		Type *elem = base_type(type)->Slice.elem;
		Type *t = make_type_array(a, elem, count);
		irValue *backing_array = ir_add_module_constant(m, t, value);


		isize max_len = 7+8+1;
		u8 *str = cast(u8 *)gb_alloc_array(a, u8, max_len);
		isize len = gb_snprintf(cast(char *)str, max_len, "__csba$%x", m->global_array_index);
		m->global_array_index++;

		String name = make_string(str, len-1);

		Entity *e = make_entity_constant(a, NULL, make_token_ident(name), t, value);
		irValue *g = ir_make_value_global(a, e, backing_array);
		ir_module_add_value(m, e, g);
		map_ir_value_set(&m->members, hash_string(name), g);

		return ir_make_value_constant_slice(a, type, g, count);
	}

	return ir_make_value_constant(a, type, value);
}

irValue *ir_add_global_string_array(irModule *m, String string) {
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
	irValue *g = ir_make_value_global(a, entity, ir_add_module_constant(m, type, ev));
	g->Global.is_private      = true;
	// g->Global.is_unnamed_addr = true;
	// g->Global.is_constant = true;

	ir_module_add_value(m, entity, g);
	map_ir_value_set(&m->members, hash_string(name), g);

	return g;
}




irValue *ir_add_local(irProcedure *proc, Entity *e) {
	irBlock *b = proc->decl_block; // all variables must be in the first block
	irValue *instr = ir_make_instr_local(proc, e, true);
	instr->Instr.parent = b;
	array_add(&b->instrs, instr);
	array_add(&b->locals, instr);
	proc->local_count++;

	// if (zero_initialized) {
		ir_emit_zero_init(proc, instr);
	// }

	return instr;
}

irValue *ir_add_local_for_identifier(irProcedure *proc, AstNode *name, bool zero_initialized) {
	Entity **found = map_entity_get(&proc->module->info->definitions, hash_pointer(name));
	if (found) {
		Entity *e = *found;
		ir_emit_comment(proc, e->token.string);
		return ir_add_local(proc, e);
	}
	return NULL;
}

irValue *ir_add_local_generated(irProcedure *proc, Type *type) {
	GB_ASSERT(type != NULL);

	Scope *scope = NULL;
	if (proc->curr_block) {
		scope = proc->curr_block->scope;
	}
	Entity *e = make_entity_variable(proc->module->allocator,
	                                 scope,
	                                 empty_token,
	                                 type, false);
	return ir_add_local(proc, e);
}

irValue *ir_add_param(irProcedure *proc, Entity *e) {
	irValue *v = ir_make_value_param(proc->module->allocator, proc, e);
#if 1
	irValue *l = ir_add_local(proc, e);
	ir_emit_store(proc, l, v);
#else
	ir_module_add_value(proc->module, e, v);
#endif
	return v;
}



////////////////////////////////////////////////////////////////
//
// @Debug
//
////////////////////////////////////////////////////////////////

irDebugInfo *ir_add_debug_info_file(irProcedure *proc, AstFile *file) {
	if (!proc->module->generate_debug_info) {
		return NULL;
	}

	GB_ASSERT(file != NULL);
	irDebugInfo *di = ir_alloc_debug_info(proc->module->allocator, irDebugInfo_File);
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

	map_ir_debug_info_set(&proc->module->debug_info, hash_pointer(file), di);
	return di;
}


irDebugInfo *ir_add_debug_info_proc(irProcedure *proc, Entity *entity, String name, irDebugInfo *file) {
	if (!proc->module->generate_debug_info) {
		return NULL;
	}

	GB_ASSERT(entity != NULL);
	irDebugInfo *di = ir_alloc_debug_info(proc->module->allocator, irDebugInfo_Proc);
	di->Proc.entity = entity;
	di->Proc.name = name;
	di->Proc.file = file;
	di->Proc.pos = entity->token.pos;

	map_ir_debug_info_set(&proc->module->debug_info, hash_pointer(entity), di);
	return di;
}

////////////////////////////////////////////////////////////////
//
// @Emit
//
////////////////////////////////////////////////////////////////


irValue *ir_emit(irProcedure *proc, irValue *instr) {
	GB_ASSERT(instr->kind == irValue_Instr);
	irBlock *b = proc->curr_block;
	instr->Instr.parent = b;
	if (b != NULL) {
		irInstr *i = ir_get_last_instr(b);
		if (!ir_is_instr_terminating(i)) {
			array_add(&b->instrs, instr);
		}
	}
	return instr;
}
irValue *ir_emit_store(irProcedure *p, irValue *address, irValue *value) {
	return ir_emit(p, ir_make_instr_store(p, address, value));
}
irValue *ir_emit_load(irProcedure *p, irValue *address) {
	return ir_emit(p, ir_make_instr_load(p, address));
}
irValue *ir_emit_select(irProcedure *p, irValue *cond, irValue *t, irValue *f) {
	return ir_emit(p, ir_make_instr_select(p, cond, t, f));
}

irValue *ir_emit_zero_init(irProcedure *p, irValue *address)  {
	return ir_emit(p, ir_make_instr_zero_init(p, address));
}

irValue *ir_emit_comment(irProcedure *p, String text) {
	return ir_emit(p, ir_make_instr_comment(p, text));
}


irValue *ir_emit_call(irProcedure *p, irValue *value, irValue **args, isize arg_count) {
	Type *pt = base_type(ir_type(value));
	GB_ASSERT(pt->kind == Type_Proc);
	Type *results = pt->Proc.results;
	return ir_emit(p, ir_make_instr_call(p, value, args, arg_count, results));
}

irValue *ir_emit_global_call(irProcedure *proc, char *name_, irValue **args, isize arg_count) {
	String name = make_string_c(name_);
	irValue **found = map_ir_value_get(&proc->module->members, hash_string(name));
	GB_ASSERT_MSG(found != NULL, "%.*s", LIT(name));
	irValue *gp = *found;
	return ir_emit_call(proc, gp, args, arg_count);
}



void ir_emit_defer_stmts(irProcedure *proc, irDeferExitKind kind, irBlock *block) {
	isize count = proc->defer_stmts.count;
	isize i = count;
	while (i --> 0) {
		irDefer d = proc->defer_stmts.e[i];
		if (kind == irDeferExit_Default) {
			if (proc->scope_index == d.scope_index &&
			    d.scope_index > 1) {
				ir_build_defer_stmt(proc, d);
				array_pop(&proc->defer_stmts);
				continue;
			} else {
				break;
			}
		} else if (kind == irDeferExit_Return) {
			ir_build_defer_stmt(proc, d);
		} else if (kind == irDeferExit_Branch) {
			GB_ASSERT(block != NULL);
			isize lower_limit = block->scope_index+1;
			if (lower_limit < d.scope_index) {
				ir_build_defer_stmt(proc, d);
			}
		}
	}
}


void ir_open_scope(irProcedure *proc) {
	proc->scope_index++;
}

void ir_close_scope(irProcedure *proc, irDeferExitKind kind, irBlock *block) {
	ir_emit_defer_stmts(proc, kind, block);
	GB_ASSERT(proc->scope_index > 0);
	proc->scope_index--;
}



void ir_emit_unreachable(irProcedure *proc) {
	ir_emit(proc, ir_make_instr_unreachable(proc));
}

void ir_emit_return(irProcedure *proc, irValue *v) {
	ir_emit_defer_stmts(proc, irDeferExit_Return, NULL);
	ir_emit(proc, ir_make_instr_return(proc, v));
}

void ir_emit_jump(irProcedure *proc, irBlock *target_block) {
	irBlock *b = proc->curr_block;
	if (b == NULL) {
		return;
	}
	ir_emit(proc, ir_make_instr_jump(proc, target_block));
	ir_add_edge(b, target_block);
	proc->curr_block = NULL;
}

void ir_emit_if(irProcedure *proc, irValue *cond, irBlock *true_block, irBlock *false_block) {
	irBlock *b = proc->curr_block;
	if (b == NULL) {
		return;
	}
	ir_emit(proc, ir_make_instr_if(proc, cond, true_block, false_block));
	ir_add_edge(b, true_block);
	ir_add_edge(b, false_block);
	proc->curr_block = NULL;
}

void ir_emit_startup_runtime(irProcedure *proc) {
	GB_ASSERT(proc->parent == NULL && str_eq(proc->name, str_lit("main")));
	ir_emit(proc, ir_alloc_instr(proc, irInstr_StartupRuntime));
}




irValue *ir_addr_store(irProcedure *proc, irAddr addr, irValue *value) {
	if (addr.addr == NULL) {
		return NULL;
	}

	if (addr.kind == irAddr_Vector) {
		irValue *v = ir_emit_load(proc, addr.addr);
		Type *elem_type = base_type(ir_type(v))->Vector.elem;
		irValue *elem = ir_emit_conv(proc, value, elem_type);
		irValue *out = ir_emit(proc, ir_make_instr_insert_element(proc, v, elem, addr.Vector.index));
		return ir_emit_store(proc, addr.addr, out);
	} else {
		irValue *v = ir_emit_conv(proc, value, ir_addr_type(addr));
		return ir_emit_store(proc, addr.addr, v);
	}
}
irValue *ir_addr_load(irProcedure *proc, irAddr addr) {
	if (addr.addr == NULL) {
		GB_PANIC("Illegal addr load");
		return NULL;
	}

	if (addr.kind == irAddr_Vector) {
		irValue *v = ir_emit_load(proc, addr.addr);
		return ir_emit(proc, ir_make_instr_extract_element(proc, v, addr.Vector.index));
	}
	Type *t = base_type(ir_type(addr.addr));
	if (t->kind == Type_Proc) {
		// NOTE(bill): Imported procedures don't require a load as they are pointers
		return addr.addr;
	}
	return ir_emit_load(proc, addr.addr);
}




irValue *ir_emit_ptr_offset(irProcedure *proc, irValue *ptr, irValue *offset) {
	offset = ir_emit_conv(proc, offset, t_int);
	return ir_emit(proc, ir_make_instr_ptr_offset(proc, ptr, offset));
}

irValue *ir_emit_arith(irProcedure *proc, TokenKind op, irValue *left, irValue *right, Type *type) {
	Type *t_left = ir_type(left);
	Type *t_right = ir_type(right);

	if (op == Token_Add) {
		if (is_type_pointer(t_left)) {
			irValue *ptr = ir_emit_conv(proc, left, type);
			irValue *offset = right;
			return ir_emit_ptr_offset(proc, ptr, offset);
		} else if (is_type_pointer(ir_type(right))) {
			irValue *ptr = ir_emit_conv(proc, right, type);
			irValue *offset = left;
			return ir_emit_ptr_offset(proc, ptr, offset);
		}
	} else if (op == Token_Sub) {
		if (is_type_pointer(t_left) && is_type_integer(t_right)) {
			// ptr - int
			irValue *ptr = ir_emit_conv(proc, left, type);
			irValue *offset = right;
			return ir_emit_ptr_offset(proc, ptr, offset);
		} else if (is_type_pointer(t_left) && is_type_pointer(t_right)) {
			GB_ASSERT(is_type_integer(type));
			irModule *m = proc->module;
			Type *ptr_type = base_type(t_left);
			GB_ASSERT(!is_type_rawptr(ptr_type));
			irValue *elem_size = ir_make_const_int(m->allocator, type_size_of(m->sizes, m->allocator, ptr_type->Pointer.elem));
			irValue *x = ir_emit_conv(proc, left, type);
			irValue *y = ir_emit_conv(proc, right, type);
			irValue *diff = ir_emit_arith(proc, op, x, y, type);
			return ir_emit_arith(proc, Token_Quo, diff, elem_size, type);
		}
	}


	switch (op) {
	case Token_Shl:
	case Token_Shr:
		left = ir_emit_conv(proc, left, type);
		if (!is_type_unsigned(ir_type(right))) {
			Type *t = t_u64;
			if (proc->module->sizes.word_size == 32) {
				t = t_u32;
			}
			right = ir_emit_conv(proc, right, t);
		}
		break;

	case Token_AndNot: {
		// NOTE(bill): x &~ y == x & (~y) == x & (y ~ -1)
		// NOTE(bill): "not" `x` == `x` "xor" `-1`
		irValue *neg = ir_add_module_constant(proc->module, type, make_exact_value_integer(-1));
		op = Token_Xor;
		right = ir_emit_arith(proc, op, right, neg, type);
		GB_ASSERT(right->Instr.kind == irInstr_BinaryOp);
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
		left  = ir_emit_conv(proc, left, type);
		right = ir_emit_conv(proc, right, type);
		break;
	}

	return ir_emit(proc, ir_make_instr_binary_op(proc, op, left, right, type));
}

irValue *ir_emit_comp(irProcedure *proc, TokenKind op_kind, irValue *left, irValue *right) {
	Type *a = base_type(ir_type(left));
	Type *b = base_type(ir_type(right));

	GB_ASSERT(gb_is_between(op_kind, Token__ComparisonBegin+1, Token__ComparisonEnd-1));

	if (are_types_identical(a, b)) {
		// NOTE(bill): No need for a conversion
	} else if (left->kind == irValue_Constant || left->kind == irValue_Nil) {
		left = ir_emit_conv(proc, left, ir_type(right));
	} else if (right->kind == irValue_Constant || right->kind == irValue_Nil) {
		right = ir_emit_conv(proc, right, ir_type(left));
	}

	Type *result = t_bool;
	if (is_type_vector(a)) {
		result = make_type_vector(proc->module->allocator, t_bool, a->Vector.count);
	}
	return ir_emit(proc, ir_make_instr_binary_op(proc, op_kind, left, right, result));
}

irValue *ir_emit_array_ep(irProcedure *proc, irValue *s, irValue *index) {
	GB_ASSERT(index != NULL);
	Type *t = ir_type(s);
	GB_ASSERT(is_type_pointer(t));
	Type *st = base_type(type_deref(t));
	GB_ASSERT(is_type_array(st) || is_type_vector(st));

	// NOTE(bill): For some weird legacy reason in LLVM, structure elements must be accessed as an i32
	index = ir_emit_conv(proc, index, t_i32);
	return ir_emit(proc, ir_make_instr_array_element_ptr(proc, s, index));
}

irValue *ir_emit_array_epi(irProcedure *proc, irValue *s, i32 index) {
	return ir_emit_array_ep(proc, s, ir_make_const_i32(proc->module->allocator, index));
}

irValue *ir_emit_union_tag_ptr(irProcedure *proc, irValue *u) {
	Type *t = ir_type(u);
	GB_ASSERT(is_type_pointer(t) &&
	          is_type_union(type_deref(t)));
	GB_ASSERT(are_types_identical(t, ir_type(u)));
	return ir_emit(proc, ir_make_instr_union_tag_ptr(proc, u));
}

irValue *ir_emit_union_tag_value(irProcedure *proc, irValue *u) {
	Type *t = ir_type(u);
	GB_ASSERT(is_type_union(t));
	GB_ASSERT(are_types_identical(t, ir_type(u)));
	return ir_emit(proc, ir_make_instr_union_tag_value(proc, u));
}



irValue *ir_emit_struct_ep(irProcedure *proc, irValue *s, i32 index) {
	gbAllocator a = proc->module->allocator;
	Type *t = base_type(type_deref(ir_type(s)));
	Type *result_type = NULL;
	irValue *gep = NULL;

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
	} else if (is_type_dynamic_array(t)) {
		switch (index) {
		case 0: result_type = make_type_pointer(a, make_type_pointer(a, t->DynamicArray.elem)); break;
		case 1: result_type = t_int_ptr;                                      break;
		case 2: result_type = t_int_ptr;                                      break;
		case 3: result_type = t_allocator_ptr;                                break;
		}
	} else {
		GB_PANIC("TODO(bill): struct_gep type: %s, %d", type_to_string(ir_type(s)), index);
	}

	GB_ASSERT(result_type != NULL);

	gep = ir_make_instr_struct_element_ptr(proc, s, index, result_type);
	return ir_emit(proc, gep);
}


irValue *ir_emit_struct_ev(irProcedure *proc, irValue *s, i32 index) {
	// NOTE(bill): For some weird legacy reason in LLVM, structure elements must be accessed as an i32

	gbAllocator a = proc->module->allocator;
	Type *t = base_type(ir_type(s));
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
	} else if (is_type_dynamic_array(t)) {
		switch (index) {
		case 0: result_type = make_type_pointer(a, t->DynamicArray.elem); break;
		case 1: result_type = t_int;                                      break;
		case 2: result_type = t_int;                                      break;
		case 3: result_type = t_allocator;                                break;
		}
	} else {
		GB_PANIC("TODO(bill): struct_ev type: %s, %d", type_to_string(ir_type(s)), index);
	}

	GB_ASSERT(result_type != NULL);

	return ir_emit(proc, ir_make_instr_struct_extract_value(proc, s, index, result_type));
}


irValue *ir_emit_deep_field_gep(irProcedure *proc, Type *type, irValue *e, Selection sel) {
	GB_ASSERT(sel.index.count > 0);

	for_array(i, sel.index) {
		i32 index = cast(i32)sel.index.e[i];
		if (is_type_pointer(type)) {
			type = type_deref(type);
			e = ir_emit_load(proc, e);
			e = ir_emit_ptr_offset(proc, e, v_zero); // TODO(bill): Do I need these copies?
		}
		type = base_type(type);


		if (is_type_raw_union(type)) {
			type = type->Record.fields[index]->type;
			e = ir_emit_conv(proc, e, make_type_pointer(proc->module->allocator, type));
		} else if (type->kind == Type_Record) {
			type = type->Record.fields[index]->type;
			e = ir_emit_struct_ep(proc, e, index);
		} else if (type->kind == Type_Tuple) {
			type = type->Tuple.variables[index]->type;
			e = ir_emit_struct_ep(proc, e, index);
		}else if (type->kind == Type_Basic) {
			switch (type->Basic.kind) {
			case Basic_any: {
				if (index == 0) {
					type = t_type_info_ptr;
				} else if (index == 1) {
					type = t_rawptr;
				}
				e = ir_emit_struct_ep(proc, e, index);
			} break;

			case Basic_string:
				e = ir_emit_struct_ep(proc, e, index);
				break;

			default:
				GB_PANIC("un-gep-able type");
				break;
			}
		} else if (type->kind == Type_Slice) {
			e = ir_emit_struct_ep(proc, e, index);
		} else if (type->kind == Type_Vector) {
			e = ir_emit_array_epi(proc, e, index);
		} else if (type->kind == Type_Array) {
			e = ir_emit_array_epi(proc, e, index);
		} else {
			GB_PANIC("un-gep-able type");
		}
	}

	return e;
}


irValue *ir_emit_deep_field_ev(irProcedure *proc, Type *type, irValue *e, Selection sel) {
	GB_ASSERT(sel.index.count > 0);

	for_array(i, sel.index) {
		i32 index = cast(i32)sel.index.e[i];
		if (is_type_pointer(type)) {
			type = type_deref(type);
			e = ir_emit_load(proc, e);
			e = ir_emit_ptr_offset(proc, e, v_zero); // TODO(bill): Do I need these copies?
		}
		type = base_type(type);


		if (is_type_raw_union(type)) {
			GB_PANIC("TODO(bill): IS THIS EVEN CORRECT?");
			type = type->Record.fields[index]->type;
			e = ir_emit_conv(proc, e, type);
		} else {
			e = ir_emit_struct_ev(proc, e, index);
		}
	}

	return e;
}




irValue *ir_array_elem(irProcedure *proc, irValue *array) {
	return ir_emit_array_ep(proc, array, v_zero32);
}
irValue *ir_array_len(irProcedure *proc, irValue *array) {
	Type *t = base_type(ir_type(array));
	GB_ASSERT(t->kind == Type_Array);
	return ir_make_const_int(proc->module->allocator, t->Array.count);
}

irValue *ir_slice_elem(irProcedure *proc, irValue *slice) {
	Type *t = base_type(ir_type(slice));
	GB_ASSERT(t->kind == Type_Slice);
	return ir_emit_struct_ev(proc, slice, 0);
}
irValue *ir_slice_count(irProcedure *proc, irValue *slice) {
	Type *t = base_type(ir_type(slice));
	GB_ASSERT(t->kind == Type_Slice);
	return ir_emit_struct_ev(proc, slice, 1);
}

irValue *ir_dynamic_array_elem(irProcedure *proc, irValue *da) {
	Type *t = ir_type(da);
	GB_ASSERT(t->kind == Type_DynamicArray);
	return ir_emit_struct_ev(proc, da, 0);
}
irValue *ir_dynamic_array_count(irProcedure *proc, irValue *da) {
	Type *t = base_type(ir_type(da));
	GB_ASSERT_MSG(t->kind == Type_DynamicArray, "%s", type_to_string(t));
	return ir_emit_struct_ev(proc, da, 1);
}
irValue *ir_dynamic_array_capacity(irProcedure *proc, irValue *da) {
	Type *t = base_type(ir_type(da));
	GB_ASSERT(t->kind == Type_DynamicArray);
	return ir_emit_struct_ev(proc, da, 2);
}
irValue *ir_dynamic_array_allocator(irProcedure *proc, irValue *da) {
	Type *t = base_type(ir_type(da));
	GB_ASSERT(t->kind == Type_DynamicArray);
	return ir_emit_struct_ev(proc, da, 3);
}



irValue *ir_string_elem(irProcedure *proc, irValue *string) {
	Type *t = base_type(ir_type(string));
	GB_ASSERT(t->kind == Type_Basic && t->Basic.kind == Basic_string);
	return ir_emit_struct_ev(proc, string, 0);
}
irValue *ir_string_len(irProcedure *proc, irValue *string) {
	Type *t = base_type(ir_type(string));
	GB_ASSERT_MSG(t->kind == Type_Basic && t->Basic.kind == Basic_string, "%s", type_to_string(t));
	return ir_emit_struct_ev(proc, string, 1);
}



irValue *ir_add_local_slice(irProcedure *proc, Type *slice_type, irValue *base, irValue *low, irValue *high) {
	// TODO(bill): array bounds checking for slice creation
	// TODO(bill): check that low < high <= max
	gbAllocator a = proc->module->allocator;
	Type *bt = base_type(ir_type(base));

	if (low == NULL) {
		low = v_zero;
	}
	if (high == NULL) {
		switch (bt->kind) {
		case Type_Array:   high = ir_array_len(proc, base); break;
		case Type_Slice:   high = ir_slice_count(proc, base); break;
		case Type_Pointer: high = v_one;                     break;
		}
	}

	irValue *len = ir_emit_arith(proc, Token_Sub, high, low, t_int);

	irValue *elem = NULL;
	switch (bt->kind) {
	case Type_Array:   elem = ir_array_elem(proc, base); break;
	case Type_Slice:   elem = ir_slice_elem(proc, base); break;
	case Type_Pointer: elem = ir_emit_load(proc, base);  break;
	}

	elem = ir_emit_ptr_offset(proc, elem, low);

	irValue *slice = ir_add_local_generated(proc, slice_type);

	irValue *gep = NULL;
	gep = ir_emit_struct_ep(proc, slice, 0);
	ir_emit_store(proc, gep, elem);

	gep = ir_emit_struct_ep(proc, slice, 1);
	ir_emit_store(proc, gep, len);

	return slice;
}

irValue *ir_emit_string(irProcedure *proc, irValue *elem, irValue *len) {
	irValue *str = ir_add_local_generated(proc, t_string);
	irValue *str_elem = ir_emit_struct_ep(proc, str, 0);
	irValue *str_len = ir_emit_struct_ep(proc, str, 1);
	ir_emit_store(proc, str_elem, elem);
	ir_emit_store(proc, str_len, len);
	return ir_emit_load(proc, str);
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

irValue *ir_emit_bitcast(irProcedure *proc, irValue *data, Type *type) {
	return ir_emit(proc, ir_make_instr_conv(proc, irConv_bitcast, data, ir_type(data), type));
}


irValue *ir_emit_conv(irProcedure *proc, irValue *value, Type *t) {
	Type *src_type = ir_type(value);
	if (are_types_identical(t, src_type)) {
		return value;
	}

	Type *src = base_type(base_enum_type(src_type));
	Type *dst = base_type(base_enum_type(t));


	// if (is_type_untyped_nil(src) && type_has_nil(dst)) {
	if (is_type_untyped_nil(src)) {
		return ir_make_value_nil(proc->module->allocator, t);
	}

	if (value->kind == irValue_Constant) {
		if (is_type_any(dst)) {
			irValue *default_value = ir_add_local_generated(proc, default_type(src_type));
			ir_emit_store(proc, default_value, value);
			return ir_emit_conv(proc, ir_emit_load(proc, default_value), t_any);
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
				irValue *i = ir_add_module_constant(proc->module, t_uint, ev);
				return ir_emit(proc, ir_make_instr_conv(proc, irConv_inttoptr, i, t_uint, dst));
			}
			return ir_add_module_constant(proc->module, t, ev);
		}
	}

	if (are_types_identical(src, dst)) {
		return value;
	}

	if (is_type_maybe(dst)) {
		irValue *maybe = ir_add_local_generated(proc, dst);
		irValue *val = ir_emit_struct_ep(proc, maybe, 0);
		irValue *set = ir_emit_struct_ep(proc, maybe, 1);
		ir_emit_store(proc, val, value);
		ir_emit_store(proc, set, v_true);
		return ir_emit_load(proc, maybe);
	}

	// integer -> integer
	if (is_type_integer(src) && is_type_integer(dst)) {
		GB_ASSERT(src->kind == Type_Basic &&
		          dst->kind == Type_Basic);
		i64 sz = type_size_of(proc->module->sizes, proc->module->allocator, src);
		i64 dz = type_size_of(proc->module->sizes, proc->module->allocator, dst);
		irConvKind kind = irConv_trunc;
		if (sz == dz) {
			// NOTE(bill): In LLVM, all integers are signed and rely upon 2's compliment
			// NOTE(bill): Copy the value just for type correctness
			kind = irConv_bitcast;
		} else if (dz > sz) {
			kind = irConv_zext;
		}

		return ir_emit(proc, ir_make_instr_conv(proc, kind, value, src, dst));
	}

	// boolean -> integer
	if (is_type_boolean(src) && is_type_integer(dst)) {
		return ir_emit(proc, ir_make_instr_conv(proc, irConv_zext, value, src, dst));
	}

	// integer -> boolean
	if (is_type_integer(src) && is_type_boolean(dst)) {
		return ir_emit_comp(proc, Token_NotEq, value, v_zero);
	}


	// float -> float
	if (is_type_float(src) && is_type_float(dst)) {
		i64 sz = type_size_of(proc->module->sizes, proc->module->allocator, src);
		i64 dz = type_size_of(proc->module->sizes, proc->module->allocator, dst);
		irConvKind kind = irConv_fptrunc;
		if (dz >= sz) {
			kind = irConv_fpext;
		}
		return ir_emit(proc, ir_make_instr_conv(proc, kind, value, src, dst));
	}

	// float <-> integer
	if (is_type_float(src) && is_type_integer(dst)) {
		irConvKind kind = irConv_fptosi;
		if (is_type_unsigned(dst)) {
			kind = irConv_fptoui;
		}
		return ir_emit(proc, ir_make_instr_conv(proc, kind, value, src, dst));
	}
	if (is_type_integer(src) && is_type_float(dst)) {
		irConvKind kind = irConv_sitofp;
		if (is_type_unsigned(src)) {
			kind = irConv_uitofp;
		}
		return ir_emit(proc, ir_make_instr_conv(proc, kind, value, src, dst));
	}

	// Pointer <-> int
	if (is_type_pointer(src) && is_type_int_or_uint(dst)) {
		return ir_emit(proc, ir_make_instr_conv(proc, irConv_ptrtoint, value, src, dst));
	}
	if (is_type_int_or_uint(src) && is_type_pointer(dst)) {
		return ir_emit(proc, ir_make_instr_conv(proc, irConv_inttoptr, value, src, dst));
	}

	if (is_type_union(dst)) {
		for (isize i = 0; i < dst->Record.field_count; i++) {
			Entity *f = dst->Record.fields[i];
			if (are_types_identical(f->type, src_type)) {
				ir_emit_comment(proc, str_lit("union - child to parent"));
				gbAllocator allocator = proc->module->allocator;
				irValue *parent = ir_add_local_generated(proc, t);
				irValue *tag = ir_make_const_int(allocator, i);
				ir_emit_store(proc, ir_emit_union_tag_ptr(proc, parent), tag);

				irValue *data = ir_emit_conv(proc, parent, t_rawptr);

				Type *tag_type = src_type;
				Type *tag_type_ptr = make_type_pointer(allocator, tag_type);
				irValue *underlying = ir_emit_bitcast(proc, data, tag_type_ptr);
				ir_emit_store(proc, underlying, value);

				return ir_emit_load(proc, parent);
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
					ir_emit_comment(proc, str_lit("cast - polymorphism"));
					if (src_is_ptr) {
						value = ir_emit_load(proc, value);
					}
					return ir_emit_deep_field_ev(proc, sb, value, sel);
				}
			}
		}
	}



	// Pointer <-> Pointer
	if (is_type_pointer(src) && is_type_pointer(dst)) {
		return ir_emit_bitcast(proc, value, dst);
	}



	// proc <-> proc
	if (is_type_proc(src) && is_type_proc(dst)) {
		return ir_emit_bitcast(proc, value, dst);
	}

	// pointer -> proc
	if (is_type_pointer(src) && is_type_proc(dst)) {
		return ir_emit_bitcast(proc, value, dst);
	}
	// proc -> pointer
	if (is_type_proc(src) && is_type_pointer(dst)) {
		return ir_emit_bitcast(proc, value, dst);
	}



	// []byte/[]u8 <-> string
	if (is_type_u8_slice(src) && is_type_string(dst)) {
		irValue *elem = ir_slice_elem(proc, value);
		irValue *len  = ir_slice_count(proc, value);
		return ir_emit_string(proc, elem, len);
	}
	if (is_type_string(src) && is_type_u8_slice(dst)) {
		irValue *elem = ir_string_elem(proc, value);
		irValue *elem_ptr = ir_add_local_generated(proc, ir_type(elem));
		ir_emit_store(proc, elem_ptr, elem);

		irValue *len  = ir_string_len(proc, value);
		irValue *slice = ir_add_local_slice(proc, dst, elem_ptr, v_zero, len);
		return ir_emit_load(proc, slice);
	}

	if (is_type_vector(dst)) {
		Type *dst_elem = dst->Vector.elem;
		value = ir_emit_conv(proc, value, dst_elem);
		irValue *v = ir_add_local_generated(proc, t);
		v = ir_emit_load(proc, v);
		v = ir_emit(proc, ir_make_instr_insert_element(proc, v, value, v_zero32));
		// NOTE(bill): Broadcast lowest value to all values
		isize index_count = dst->Vector.count;
		i32 *indices = gb_alloc_array(proc->module->allocator, i32, index_count);
		for (isize i = 0; i < index_count; i++) {
			indices[i] = 0;
		}

		v = ir_emit(proc, ir_make_instr_vector_shuffle(proc, v, indices, index_count));
		return v;
	}

	if (is_type_any(dst)) {
		irValue *result = ir_add_local_generated(proc, t_any);

		if (is_type_untyped_nil(src)) {
			return ir_emit_load(proc, result);
		}

		irValue *data = NULL;
		if (value->kind == irValue_Instr &&
		    value->Instr.kind == irInstr_Load) {
			// NOTE(bill): Addreirble value
			data = value->Instr.Load.address;
		} else {
			// NOTE(bill): Non-addreirble value
			data = ir_add_local_generated(proc, src_type);
			ir_emit_store(proc, data, value);
		}
		GB_ASSERT(is_type_pointer(ir_type(data)));
		GB_ASSERT(is_type_typed(src_type));
		data = ir_emit_conv(proc, data, t_rawptr);


		irValue *ti = ir_type_info(proc, src_type);

		irValue *gep0 = ir_emit_struct_ep(proc, result, 0);
		irValue *gep1 = ir_emit_struct_ep(proc, result, 1);
		ir_emit_store(proc, gep0, ti);
		ir_emit_store(proc, gep1, data);

		return ir_emit_load(proc, result);
	}


	gb_printf_err("ir_emit_conv: src -> dst\n");
	gb_printf_err("Not Identical %s != %s\n", type_to_string(src_type), type_to_string(t));
	gb_printf_err("Not Identical %s != %s\n", type_to_string(src), type_to_string(dst));


	GB_PANIC("Invalid type conversion: `%s` to `%s`", type_to_string(src_type), type_to_string(t));

	return NULL;
}

bool ir_is_type_aggregate(Type *t) {
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
		return ir_is_type_aggregate(t->Named.base);
	}

	return false;
}

irValue *ir_emit_transmute(irProcedure *proc, irValue *value, Type *t) {
	Type *src_type = ir_type(value);
	if (are_types_identical(t, src_type)) {
		return value;
	}

	Type *src = base_type(src_type);
	Type *dst = base_type(t);
	if (are_types_identical(t, src_type)) {
		return value;
	}

	irModule *m = proc->module;

	i64 sz = type_size_of(m->sizes, m->allocator, src);
	i64 dz = type_size_of(m->sizes, m->allocator, dst);

	GB_ASSERT_MSG(sz == dz, "Invalid transmute conversion: `%s` to `%s`", type_to_string(src_type), type_to_string(t));

	if (ir_is_type_aggregate(src) || ir_is_type_aggregate(dst)) {
		irValue *s = ir_add_local_generated(proc, src);
		ir_emit_store(proc, s, value);

		irValue *d = ir_emit_bitcast(proc, s, make_type_pointer(m->allocator, dst));
		return ir_emit_load(proc, d);
	}

	// TODO(bill): Actually figure out what the conversion needs to be correctly 'cause LLVM

	return ir_emit_bitcast(proc, value, dst);
}

irValue *ir_emit_down_cast(irProcedure *proc, irValue *value, Type *t) {
	GB_ASSERT(is_type_pointer(ir_type(value)));
	gbAllocator allocator = proc->module->allocator;

	String field_name = check_down_cast_name(t, type_deref(ir_type(value)));
	GB_ASSERT(field_name.len > 0);
	Selection sel = lookup_field(proc->module->allocator, t, field_name, false);
	irValue *bytes = ir_emit_conv(proc, value, t_u8_ptr);

	i64 offset_ = type_offset_of_from_selection(proc->module->sizes, allocator, type_deref(t), sel);
	irValue *offset = ir_make_const_int(allocator, -offset_);
	irValue *head = ir_emit_ptr_offset(proc, bytes, offset);
	return ir_emit_conv(proc, head, t);
}

irValue *ir_emit_union_cast(irProcedure *proc, irValue *value, Type *tuple) {
	GB_ASSERT(tuple->kind == Type_Tuple);
	gbAllocator a = proc->module->allocator;

	Type *src_type = ir_type(value);
	bool is_ptr = is_type_pointer(src_type);

	irValue *v = ir_add_local_generated(proc, tuple);

	if (is_ptr) {
		Type *src = base_type(type_deref(src_type));
		Type *src_ptr = src_type;
		GB_ASSERT(is_type_union(src));
		Type *dst_ptr = tuple->Tuple.variables[0]->type;
		Type *dst = type_deref(dst_ptr);

		irValue *tag = ir_emit_load(proc, ir_emit_union_tag_ptr(proc, value));
		irValue *dst_tag = NULL;
		for (isize i = 1; i < src->Record.field_count; i++) {
			Entity *f = src->Record.fields[i];
			if (are_types_identical(f->type, dst)) {
				dst_tag = ir_make_const_int(a, i);
				break;
			}
		}
		GB_ASSERT(dst_tag != NULL);

		irBlock *ok_block = ir_add_block(proc, NULL, "union_cast.ok");
		irBlock *end_block = ir_add_block(proc, NULL, "union_cast.end");
		irValue *cond = ir_emit_comp(proc, Token_CmpEq, tag, dst_tag);
		ir_emit_if(proc, cond, ok_block, end_block);
		proc->curr_block = ok_block;

		irValue *gep0 = ir_emit_struct_ep(proc, v, 0);
		irValue *gep1 = ir_emit_struct_ep(proc, v, 1);

		irValue *data = ir_emit_conv(proc, value, dst_ptr);
		ir_emit_store(proc, gep0, data);
		ir_emit_store(proc, gep1, v_true);

		ir_emit_jump(proc, end_block);
		proc->curr_block = end_block;

	} else {
		Type *src = base_type(src_type);
		GB_ASSERT(is_type_union(src));
		Type *dst = tuple->Tuple.variables[0]->type;
		Type *dst_ptr = make_type_pointer(a, dst);

		irValue *tag = ir_emit_union_tag_value(proc, value);
		irValue *dst_tag = NULL;
		for (isize i = 1; i < src->Record.field_count; i++) {
			Entity *f = src->Record.fields[i];
			if (are_types_identical(f->type, dst)) {
				dst_tag = ir_make_const_int(a, i);
				break;
			}
		}
		GB_ASSERT(dst_tag != NULL);

		// HACK(bill): This is probably not very efficient
		irValue *union_copy = ir_add_local_generated(proc, src_type);
		ir_emit_store(proc, union_copy, value);

		irBlock *ok_block = ir_add_block(proc, NULL, "union_cast.ok");
		irBlock *end_block = ir_add_block(proc, NULL, "union_cast.end");
		irValue *cond = ir_emit_comp(proc, Token_CmpEq, tag, dst_tag);
		ir_emit_if(proc, cond, ok_block, end_block);
		proc->curr_block = ok_block;

		irValue *gep0 = ir_emit_struct_ep(proc, v, 0);
		irValue *gep1 = ir_emit_struct_ep(proc, v, 1);

		irValue *data = ir_emit_load(proc, ir_emit_conv(proc, union_copy, dst_ptr));
		ir_emit_store(proc, gep0, data);
		ir_emit_store(proc, gep1, v_true);

		ir_emit_jump(proc, end_block);
		proc->curr_block = end_block;

	}
	return ir_emit_load(proc, v);
}


isize ir_type_info_index(CheckerInfo *info, Type *type) {
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

irValue *ir_type_info(irProcedure *proc, Type *type) {
	irValue **found = map_ir_value_get(&proc->module->members, hash_string(str_lit(IR_TYPE_INFO_DATA_NAME)));
	GB_ASSERT(found != NULL);
	irValue *type_info_data = *found;
	CheckerInfo *info = proc->module->info;

	type = default_type(type);

	i32 entry_index = ir_type_info_index(info, type);

	// gb_printf_err("%d %s\n", entry_index, type_to_string(type));

	return ir_emit_array_ep(proc, type_info_data, ir_make_const_i32(proc->module->allocator, entry_index));
}



irValue *ir_emit_logical_binary_expr(irProcedure *proc, AstNode *expr) {
	ast_node(be, BinaryExpr, expr);
#if 0
	irBlock *true_   = ir_add_block(proc, NULL, "logical.cmp.true");
	irBlock *false_  = ir_add_block(proc, NULL, "logical.cmp.false");
	irBlock *done  = ir_add_block(proc, NULL, "logical.cmp.done");

	irValue *result = ir_add_local_generated(proc, t_bool);
	ir_build_cond(proc, expr, true_, false_);

	proc->curr_block = true_;
	ir_emit_store(proc, result, v_true);
	ir_emit_jump(proc, done);

	proc->curr_block = false_;
	ir_emit_store(proc, result, v_false);
	ir_emit_jump(proc, done);

	proc->curr_block = done;

	return ir_emit_load(proc, result);
#else
	irBlock *rhs = ir_add_block(proc, NULL, "logical.cmp.rhs");
	irBlock *done = ir_add_block(proc, NULL, "logical.cmp.done");

	Type *type = type_of_expr(proc->module->info, expr);
	type = default_type(type);

	irValue *short_circuit = NULL;
	if (be->op.kind == Token_CmpAnd) {
		ir_build_cond(proc, be->left, rhs, done);
		short_circuit = v_false;
	} else if (be->op.kind == Token_CmpOr) {
		ir_build_cond(proc, be->left, done, rhs);
		short_circuit = v_true;
	}

	if (rhs->preds.count == 0) {
		proc->curr_block = done;
		return short_circuit;
	}

	if (done->preds.count == 0) {
		proc->curr_block = rhs;
		return ir_build_expr(proc, be->right);
	}

	irValueArray edges = {0};
	array_init_reserve(&edges, proc->module->allocator, done->preds.count+1);
	for_array(i, done->preds) {
		array_add(&edges, short_circuit);
	}

	proc->curr_block = rhs;
	array_add(&edges, ir_build_expr(proc, be->right));
	ir_emit_jump(proc, done);
	proc->curr_block = done;

	return ir_emit(proc, ir_make_instr_phi(proc, edges, type));
#endif
}


void ir_emit_bounds_check(irProcedure *proc, Token token, irValue *index, irValue *len) {
	if ((proc->module->stmt_state_flags & StmtStateFlag_no_bounds_check) != 0) {
		return;
	}

	index = ir_emit_conv(proc, index, t_int);
	len = ir_emit_conv(proc, len, t_int);

	ir_emit(proc, ir_make_instr_bounds_check(proc, token.pos, index, len));

	// gbAllocator a = proc->module->allocator;
	// irValue **args = gb_alloc_array(a, irValue *, 5);
	// args[0] = ir_emit_global_string(proc, token.pos.file);
	// args[1] = ir_make_const_int(a, token.pos.line);
	// args[2] = ir_make_const_int(a, token.pos.column);
	// args[3] = ir_emit_conv(proc, index, t_int);
	// args[4] = ir_emit_conv(proc, len, t_int);

	// ir_emit_global_call(proc, "__bounds_check_error", args, 5);
}

void ir_emit_slice_bounds_check(irProcedure *proc, Token token, irValue *low, irValue *high, bool is_substring) {
	if ((proc->module->stmt_state_flags & StmtStateFlag_no_bounds_check) != 0) {
		return;
	}

	low  = ir_emit_conv(proc, low,  t_int);
	high = ir_emit_conv(proc, high, t_int);

	ir_emit(proc, ir_make_instr_slice_bounds_check(proc, token.pos, low, high, is_substring));
}


////////////////////////////////////////////////////////////////
//
// @Build
//
////////////////////////////////////////////////////////////////


void ir_push_target_list(irProcedure *proc, irBlock *break_, irBlock *continue_, irBlock *fallthrough_) {
	irTargetList *tl = gb_alloc_item(proc->module->allocator, irTargetList);
	tl->prev          = proc->target_list;
	tl->break_        = break_;
	tl->continue_     = continue_;
	tl->fallthrough_  = fallthrough_;
	proc->target_list = tl;
}

void ir_pop_target_list(irProcedure *proc) {
	proc->target_list = proc->target_list->prev;
}


void ir_mangle_sub_type_name(irModule *m, Entity *field, String parent) {
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
	ir_gen_global_type_name(m, field, child);
}

void ir_gen_global_type_name(irModule *m, Entity *e, String name) {
	irValue *t = ir_make_value_type_name(m->allocator, name, e->type);
	ir_module_add_value(m, e, t);
	map_ir_value_set(&m->members, hash_string(name), t);

	if (is_type_union(e->type)) {
		Type *bt = base_type(e->type);
		TypeRecord *s = &bt->Record;
		// NOTE(bill): Zeroth entry is null (for `match type` stmts)
		for (isize j = 1; j < s->field_count; j++) {
			ir_mangle_sub_type_name(m, s->fields[j], name);
		}
	}
}




void ir_build_defer_stmt(irProcedure *proc, irDefer d) {
	irBlock *b = ir_add_block(proc, NULL, "defer");
	// NOTE(bill): The prev block may defer injection before it's terminator
	irInstr *last_instr = ir_get_last_instr(proc->curr_block);
	if (last_instr == NULL || !ir_is_instr_terminating(last_instr)) {
		ir_emit_jump(proc, b);
	}
	proc->curr_block = b;
	ir_emit_comment(proc, str_lit("defer"));
	if (d.kind == irDefer_Node) {
		ir_build_stmt(proc, d.stmt);
	} else if (d.kind == irDefer_Instr) {
		// NOTE(bill): Need to make a new copy
		irValue *instr = cast(irValue *)gb_alloc_copy(proc->module->allocator, d.instr, gb_size_of(irValue));
		ir_emit(proc, instr);
	}
}



irValue *ir_find_global_variable(irProcedure *proc, String name) {
	irValue **value = map_ir_value_get(&proc->module->members, hash_string(name));
	GB_ASSERT_MSG(value != NULL, "Unable to find global variable `%.*s`", LIT(name));
	return *value;
}

irValue *ir_find_implicit_value_backing(irProcedure *proc, ImplicitValueId id) {
	Entity *e = proc->module->info->implicit_values[id];
	GB_ASSERT(e->kind == Entity_ImplicitValue);
	Entity *backing = e->ImplicitValue.backing;
	irValue **value = map_ir_value_get(&proc->module->values, hash_pointer(backing));
	GB_ASSERT_MSG(value != NULL, "Unable to find implicit value backing `%.*s`", LIT(backing->token.string));
	return *value;
}

void ir_build_stmt_list(irProcedure *proc, AstNodeArray stmts);

irValue *ir_build_single_expr(irProcedure *proc, AstNode *expr, TypeAndValue *tv) {
	expr = unparen_expr(expr);
	switch (expr->kind) {
	case_ast_node(bl, BasicLit, expr);
		TokenPos pos = bl->pos;
		GB_PANIC("Non-constant basic literal %.*s(%td:%td) - %.*s", LIT(pos.file), pos.line, pos.column, LIT(token_strings[bl->kind]));
	case_end;

	case_ast_node(bd, BasicDirective, expr);
		TokenPos pos = bd->token.pos;
		GB_PANIC("Non-constant basic literal %.*s(%td:%td) - %.*s", LIT(pos.file), pos.line, pos.column, LIT(bd->name));
	case_end;

	case_ast_node(i, Ident, expr);
		Entity *e = *map_entity_get(&proc->module->info->uses, hash_pointer(expr));
		if (e->kind == Entity_Builtin) {
			Token token = ast_node_token(expr);
			GB_PANIC("TODO(bill): ir_build_single_expr Entity_Builtin `%.*s`\n"
			         "\t at %.*s(%td:%td)", LIT(builtin_procs[e->Builtin.id].name),
			         LIT(token.pos.file), token.pos.line, token.pos.column);
			return NULL;
		} else if (e->kind == Entity_Nil) {
			return ir_make_value_nil(proc->module->allocator, tv->type);
		} else if (e->kind == Entity_ImplicitValue) {
			return ir_emit_load(proc, ir_find_implicit_value_backing(proc, e->ImplicitValue.id));
		}

		irValue **found = map_ir_value_get(&proc->module->values, hash_pointer(e));
		if (found) {
			irValue *v = *found;
			if (v->kind == irValue_Proc) {
				return v;
			}
			// if (e->kind == Entity_Variable && e->Variable.param) {
				// return v;
			// }
			return ir_emit_load(proc, v);
		} else if (e != NULL && e->kind == Entity_Variable) {
			return ir_addr_load(proc, ir_build_addr(proc, expr));
		}
		GB_PANIC("NULL value for expression from identifier: %.*s", LIT(i->string));
		return NULL;
	case_end;

	case_ast_node(re, RunExpr, expr);
		// TODO(bill): Run Expression
		return ir_build_expr(proc, re->expr);
	case_end;

	case_ast_node(de, DerefExpr, expr);
		return ir_addr_load(proc, ir_build_addr(proc, expr));
	case_end;

	case_ast_node(se, SelectorExpr, expr);
		TypeAndValue *tav = map_tav_get(&proc->module->info->types, hash_pointer(expr));
		GB_ASSERT(tav != NULL);
		return ir_addr_load(proc, ir_build_addr(proc, expr));
	case_end;

	case_ast_node(be, BlockExpr, expr);
		ir_emit_comment(proc, str_lit("BlockExpr"));
		ir_open_scope(proc);

		AstNodeArray stmts = be->stmts;
		stmts.count--;
		ir_build_stmt_list(proc, stmts);

		AstNode *give_stmt = be->stmts.e[be->stmts.count-1];
		GB_ASSERT(give_stmt->kind == AstNode_ExprStmt);
		AstNode *give_expr = give_stmt->ExprStmt.expr;
		GB_ASSERT(give_expr->kind == AstNode_GiveExpr);
		irValue *value = ir_build_expr(proc, give_expr);

		ir_close_scope(proc, irDeferExit_Default, NULL);

		return value;
	case_end;

	case_ast_node(ie, IfExpr, expr);
		ir_emit_comment(proc, str_lit("IfExpr"));
		if (ie->init != NULL) {
			irBlock *init = ir_add_block(proc, expr, "if.init");
			ir_emit_jump(proc, init);
			proc->curr_block = init;
			ir_build_stmt(proc, ie->init);
		}

		irValueArray edges = {0};
		array_init_reserve(&edges, proc->module->allocator, 2);

		GB_ASSERT(ie->else_expr != NULL);
		irBlock *then  = ir_add_block(proc, expr, "if.then");
		irBlock *done  = ir_add_block(proc, expr, "if.done"); // NOTE(bill): Append later
		irBlock *else_ = ir_add_block(proc, ie->else_expr, "if.else");

		irValue *cond = ir_build_cond(proc, ie->cond, then, else_);
		proc->curr_block = then;

		ir_open_scope(proc);
		array_add(&edges, ir_build_expr(proc, ie->body));
		ir_close_scope(proc, irDeferExit_Default, NULL);

		ir_emit_jump(proc, done);
		proc->curr_block = else_;

		ir_open_scope(proc);
		array_add(&edges, ir_build_expr(proc, ie->else_expr));
		ir_close_scope(proc, irDeferExit_Default, NULL);

		ir_emit_jump(proc, done);
		proc->curr_block = done;

		Type *type = type_of_expr(proc->module->info, expr);

		return ir_emit(proc, ir_make_instr_phi(proc, edges, type));
	case_end;

	case_ast_node(ge, GiveExpr, expr);
		ir_emit_comment(proc, str_lit("GiveExpr"));

		irValue *v = NULL;
		Type *give_type = type_of_expr(proc->module->info, expr);
		GB_ASSERT(give_type != NULL);
		if (give_type->kind != Type_Tuple) {
			v = ir_emit_conv(proc, ir_build_expr(proc, ge->results.e[0]), give_type);
		} else {
			TypeTuple *tuple = &give_type->Tuple;
			gbTempArenaMemory tmp = gb_temp_arena_memory_begin(&proc->module->tmp_arena);

			irValueArray results;
			array_init_reserve(&results, proc->module->tmp_allocator, tuple->variable_count);

			for_array(res_index, ge->results) {
				irValue *res = ir_build_expr(proc, ge->results.e[res_index]);
				Type *t = ir_type(res);
				if (t->kind == Type_Tuple) {
					for (isize i = 0; i < t->Tuple.variable_count; i++) {
						Entity *e = t->Tuple.variables[i];
						irValue *v = ir_emit_struct_ev(proc, res, i);
						array_add(&results, v);
					}
				} else {
					array_add(&results, res);
				}
			}

			v = ir_add_local_generated(proc, give_type);
			for_array(i, results) {
				Entity *e = tuple->variables[i];
				irValue *res = ir_emit_conv(proc, results.e[i], e->type);
				irValue *field = ir_emit_struct_ep(proc, v, i);
				ir_emit_store(proc, field, res);
			}
			v = ir_emit_load(proc, v);

			gb_temp_arena_memory_end(tmp);
		}

		return v;
	case_end;

	case_ast_node(ce, CastExpr, expr);
		Type *type = tv->type;
		irValue *expr = ir_build_expr(proc, ce->expr);
		switch (ce->token.kind) {
		case Token_cast:
			ir_emit_comment(proc, str_lit("cast - cast"));
			return ir_emit_conv(proc, expr, type);

		case Token_transmute:
			ir_emit_comment(proc, str_lit("cast - transmute"));
			return ir_emit_transmute(proc, expr, type);

		case Token_down_cast:
			ir_emit_comment(proc, str_lit("cast - down_cast"));
			return ir_emit_down_cast(proc, expr, type);

		case Token_union_cast:
			ir_emit_comment(proc, str_lit("cast - union_cast"));
			return ir_emit_union_cast(proc, expr, type);

		default:
			GB_PANIC("Unknown cast expression");
		}
	case_end;

	case_ast_node(ue, UnaryExpr, expr);
		switch (ue->op.kind) {
		case Token_Pointer:
			return ir_emit_ptr_offset(proc, ir_build_addr(proc, ue->expr).addr, v_zero); // Make a copy of the pointer

		// case Token_Maybe:
			// return ir_emit_conv(proc, ir_build_expr(proc, ue->expr), type_of_expr(proc->module->info, expr));

		case Token_Add:
			return ir_build_expr(proc, ue->expr);

		case Token_Not: // Boolean not
		case Token_Xor: // Bitwise not
		case Token_Sub: // Bitwise not
			return ir_emit(proc, ir_make_instr_unary_op(proc, ue->op.kind, ir_build_expr(proc, ue->expr), tv->type));
		}
	case_end;

	case_ast_node(be, BinaryExpr, expr);
		irValue *left = ir_build_expr(proc, be->left);
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
			irValue *right = ir_build_expr(proc, be->right);
			return ir_emit_arith(proc, be->op.kind, left, right, type);
		}


		case Token_CmpEq:
		case Token_NotEq:
		case Token_Lt:
		case Token_LtEq:
		case Token_Gt:
		case Token_GtEq: {
			irValue *right = ir_build_expr(proc, be->right);
			irValue *cmp = ir_emit_comp(proc, be->op.kind, left, right);
			return ir_emit_conv(proc, cmp, type);
		} break;

		case Token_CmpAnd:
		case Token_CmpOr:
			return ir_emit_logical_binary_expr(proc, expr);

		// case Token_as:
		// 	ir_emit_comment(proc, str_lit("cast - as"));
		// 	return ir_emit_conv(proc, left, type);

		// case Token_transmute:
		// 	ir_emit_comment(proc, str_lit("cast - transmute"));
		// 	return ir_emit_transmute(proc, left, type);

		// case Token_down_cast:
		// 	ir_emit_comment(proc, str_lit("cast - down_cast"));
		// 	return ir_emit_down_cast(proc, left, type);

		// case Token_union_cast:
		// 	ir_emit_comment(proc, str_lit("cast - union_cast"));
		// 	return ir_emit_union_cast(proc, left, type);

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
		irValue *value = ir_make_value_procedure(proc->module->allocator,
		                                           proc->module, NULL, type, pl->type, pl->body, name);

		value->Proc.tags = pl->tags;
		value->Proc.parent = proc;

		array_add(&proc->children, &value->Proc);
		array_add(&proc->module->procs_to_generate, value);

		return value;
	case_end;


	case_ast_node(cl, CompoundLit, expr);
		return ir_emit_load(proc, ir_build_addr(proc, expr).addr);
	case_end;


	case_ast_node(ce, CallExpr, expr);
		if (map_tav_get(&proc->module->info->types, hash_pointer(ce->proc))->mode == Addressing_Type) {
			GB_ASSERT(ce->args.count == 1);
			irValue *x = ir_build_expr(proc, ce->args.e[0]);
			irValue *y = ir_emit_conv(proc, x, tv->type);
			return y;
		}

		AstNode *p = unparen_expr(ce->proc);
		if (p->kind == AstNode_Ident) {
			Entity **found = map_entity_get(&proc->module->info->uses, hash_pointer(p));
			if (found && (*found)->kind == Entity_Builtin) {
				Entity *e = *found;
				switch (e->Builtin.id) {
				case BuiltinProc_type_info: {
					Type *t = default_type(type_of_expr(proc->module->info, ce->args.e[0]));
					return ir_type_info(proc, t);
				} break;
				case BuiltinProc_type_info_of_val: {
					Type *t = default_type(type_of_expr(proc->module->info, ce->args.e[0]));
					return ir_type_info(proc, t);
				} break;

				case BuiltinProc_new: {
					ir_emit_comment(proc, str_lit("new"));
					// new :: proc(Type) -> ^Type
					gbAllocator allocator = proc->module->allocator;

					Type *type = type_of_expr(proc->module->info, ce->args.e[0]);
					Type *ptr_type = make_type_pointer(allocator, type);

					i64 s = type_size_of(proc->module->sizes, allocator, type);
					i64 a = type_align_of(proc->module->sizes, allocator, type);

					irValue **args = gb_alloc_array(allocator, irValue *, 2);
					args[0] = ir_make_const_int(allocator, s);
					args[1] = ir_make_const_int(allocator, a);
					irValue *call = ir_emit_global_call(proc, "alloc_align", args, 2);
					irValue *v = ir_emit_conv(proc, call, ptr_type);
					return v;
				} break;

				case BuiltinProc_new_slice: {
					ir_emit_comment(proc, str_lit("new_slice"));
					// new_slice :: proc(Type, len: int) -> ^Type
					gbAllocator allocator = proc->module->allocator;

					Type *type = type_of_expr(proc->module->info, ce->args.e[0]);
					Type *ptr_type = make_type_pointer(allocator, type);
					Type *slice_type = make_type_slice(allocator, type);

					i64 s = type_size_of(proc->module->sizes, allocator, type);
					i64 a = type_align_of(proc->module->sizes, allocator, type);

					irValue *elem_size  = ir_make_const_int(allocator, s);
					irValue *elem_align = ir_make_const_int(allocator, a);

					irValue *count = ir_emit_conv(proc, ir_build_expr(proc, ce->args.e[1]), t_int);

					ir_emit_slice_bounds_check(proc, ast_node_token(ce->args.e[1]), v_zero, count, false);

					irValue *slice_size = ir_emit_arith(proc, Token_Mul, elem_size, count, t_int);

					irValue **args = gb_alloc_array(allocator, irValue *, 2);
					args[0] = slice_size;
					args[1] = elem_align;
					irValue *call = ir_emit_global_call(proc, "alloc_align", args, 2);

					irValue *ptr = ir_emit_conv(proc, call, ptr_type);
					irValue *slice = ir_add_local_generated(proc, slice_type);

					irValue *gep0 = ir_emit_struct_ep(proc, slice, 0);
					irValue *gep1 = ir_emit_struct_ep(proc, slice, 1);
					ir_emit_store(proc, gep0, ptr);
					ir_emit_store(proc, gep1, count);
					return ir_emit_load(proc, slice);
				} break;

				case BuiltinProc_free: {
					ir_emit_comment(proc, str_lit("free"));

					gbAllocator a = proc->module->allocator;

					AstNode *node = ce->args.e[0];
					TypeAndValue tav = *type_and_value_of_expression(proc->module->info, node);
					Type *type = base_type(tav.type);
					irValue *val = ir_build_expr(proc, node);

					if (is_type_dynamic_array(type)) {
						irValue *da_allocator = ir_emit_struct_ev(proc, val, 3);

						irValue *ptr = ir_emit_struct_ev(proc, val, 0);
						ptr = ir_emit_conv(proc, ptr, t_rawptr);

						irValue **args = gb_alloc_array(a, irValue *, 1);
						args[0] = da_allocator;
						args[1] = ptr;
						return ir_emit_global_call(proc, "free_ptr_with_allocator", args, 2);
					}

					irValue *ptr = NULL;
					if (is_type_pointer(type)) {
						ptr = val;
					} else if (is_type_slice(type)) {
						ptr = ir_slice_elem(proc, val);
					} else if (is_type_string(type)) {
						ptr = ir_string_elem(proc, val);
					} else {
						GB_PANIC("Invalid type to `free`");
					}

					if (ptr == NULL) {
						return NULL;
					}

					ptr = ir_emit_conv(proc, ptr, t_rawptr);

					irValue **args = gb_alloc_array(a, irValue *, 1);
					args[0] = ptr;
					return ir_emit_global_call(proc, "free_ptr", args, 1);
				} break;

				case BuiltinProc_reserve: {
					ir_emit_comment(proc, str_lit("reserve"));
					gbAllocator a = proc->module->allocator;

					irValue *array_ptr = ir_build_expr(proc, ce->args.e[0]);
					Type *type = ir_type(array_ptr);
					GB_ASSERT(is_type_pointer(type));
					type = base_type(type_deref(type));
					GB_ASSERT(is_type_dynamic_array(type));
					Type *elem = type->DynamicArray.elem;

					irValue *elem_size  = ir_make_const_int(a, type_size_of(proc->module->sizes, a, elem));
					irValue *elem_align = ir_make_const_int(a, type_align_of(proc->module->sizes, a, elem));

					array_ptr = ir_emit_conv(proc, array_ptr, t_rawptr);

					irValue *capacity = ir_emit_conv(proc, ir_build_expr(proc, ce->args.e[1]), t_int);

					irValue **args = gb_alloc_array(a, irValue *, 4);
					args[0] = array_ptr;
					args[1] = elem_size;
					args[2] = elem_align;
					args[3] = capacity;
					return ir_emit_global_call(proc, "__dynamic_array_reserve", args, 4);
				} break;

				case BuiltinProc_append: {
					ir_emit_comment(proc, str_lit("append"));
					gbAllocator a = proc->module->allocator;

					irValue *array_ptr = ir_build_expr(proc, ce->args.e[0]);
					Type *type = ir_type(array_ptr);
					GB_ASSERT(is_type_pointer(type));
					type = base_type(type_deref(type));
					GB_ASSERT(is_type_dynamic_array(type));
					Type *elem = type->DynamicArray.elem;

					irValue *elem_size  = ir_make_const_int(a, type_size_of(proc->module->sizes, a, elem));
					irValue *elem_align = ir_make_const_int(a, type_align_of(proc->module->sizes, a, elem));

					array_ptr = ir_emit_conv(proc, array_ptr, t_rawptr);

					irValue *item_ptr = ir_add_local_generated(proc, elem);
					irValue *item = ir_build_expr(proc, ce->args.e[1]);
					ir_emit_store(proc, item_ptr, item);

					irValue **args = gb_alloc_array(a, irValue *, 4);
					args[0] = array_ptr;
					args[1] = elem_size;
					args[2] = elem_align;
					args[3] = ir_emit_conv(proc, item_ptr, t_rawptr);
					return ir_emit_global_call(proc, "__dynamic_array_append", args, 4);
				} break;


				case BuiltinProc_assert: {
					ir_emit_comment(proc, str_lit("assert"));
					irValue *cond = ir_build_expr(proc, ce->args.e[0]);
					GB_ASSERT(is_type_boolean(ir_type(cond)));

					cond = ir_emit_comp(proc, Token_CmpEq, cond, v_false);
					irBlock *err  = ir_add_block(proc, NULL, "builtin.assert.err");
					irBlock *done = ir_add_block(proc, NULL, "builtin.assert.done");

					ir_emit_if(proc, cond, err, done);
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


					irValue **args = gb_alloc_array(proc->module->allocator, irValue *, 4);
					args[0] = ir_make_const_string(proc->module->allocator, pos.file);
					args[1] = ir_make_const_int(proc->module->allocator, pos.line);
					args[2] = ir_make_const_int(proc->module->allocator, pos.column);
					args[3] = ir_make_const_string(proc->module->allocator, expr_str);
					ir_emit_global_call(proc, "__assert", args, 4);

					ir_emit_jump(proc, done);
					proc->curr_block = done;

					return NULL;
				} break;

				case BuiltinProc_panic: {
					ir_emit_comment(proc, str_lit("panic"));
					irValue *msg = ir_build_expr(proc, ce->args.e[0]);
					GB_ASSERT(is_type_string(ir_type(msg)));

					Token token = ast_node_token(ce->args.e[0]);
					TokenPos pos = token.pos;

					irValue **args = gb_alloc_array(proc->module->allocator, irValue *, 4);
					args[0] = ir_make_const_string(proc->module->allocator, pos.file);
					args[1] = ir_make_const_int(proc->module->allocator, pos.line);
					args[2] = ir_make_const_int(proc->module->allocator, pos.column);
					args[3] = msg;
					ir_emit_global_call(proc, "__assert", args, 4);

					return NULL;
				} break;


				case BuiltinProc_copy: {
					ir_emit_comment(proc, str_lit("copy"));
					// copy :: proc(dst, src: []Type) -> int
					AstNode *dst_node = ce->args.e[0];
					AstNode *src_node = ce->args.e[1];
					irValue *dst_slice = ir_build_expr(proc, dst_node);
					irValue *src_slice = ir_build_expr(proc, src_node);
					Type *slice_type = base_type(ir_type(dst_slice));
					GB_ASSERT(slice_type->kind == Type_Slice);
					Type *elem_type = slice_type->Slice.elem;
					i64 size_of_elem = type_size_of(proc->module->sizes, proc->module->allocator, elem_type);

					irValue *dst = ir_emit_conv(proc, ir_slice_elem(proc, dst_slice), t_rawptr);
					irValue *src = ir_emit_conv(proc, ir_slice_elem(proc, src_slice), t_rawptr);

					irValue *len_dst = ir_slice_count(proc, dst_slice);
					irValue *len_src = ir_slice_count(proc, src_slice);

					irValue *cond = ir_emit_comp(proc, Token_Lt, len_dst, len_src);
					irValue *len = ir_emit_select(proc, cond, len_dst, len_src);

					irValue *elem_size = ir_make_const_int(proc->module->allocator, size_of_elem);
					irValue *byte_count = ir_emit_arith(proc, Token_Mul, len, elem_size, t_int);

					irValue **args = gb_alloc_array(proc->module->allocator, irValue *, 3);
					args[0] = dst;
					args[1] = src;
					args[2] = byte_count;

					ir_emit_global_call(proc, "__mem_copy", args, 3);

					return len;
				} break;
				#if 0
				case BuiltinProc_append: {
					ir_emit_comment(proc, str_lit("append"));
					// append :: proc(s: ^[]Type, item: Type) -> bool
					AstNode *sptr_node = ce->args.e[0];
					AstNode *item_node = ce->args.e[1];
					irValue *slice_ptr = ir_build_expr(proc, sptr_node);
					irValue *slice = ir_emit_load(proc, slice_ptr);

					irValue *elem = ir_slice_elem(proc, slice);
					irValue *len  = ir_slice_count(proc,  slice);
					irValue *cap  = ir_slice_cap(proc,  slice);

					Type *elem_type = type_deref(ir_type(elem));

					irValue *item_value = ir_build_expr(proc, item_node);
					item_value = ir_emit_conv(proc, item_value, elem_type);

					irValue *item = ir_add_local_generated(proc, elem_type);
					ir_emit_store(proc, item, item_value);


					// NOTE(bill): Check if can append is possible
					irValue *cond = ir_emit_comp(proc, Token_Lt, len, cap);
					irBlock *able = ir_add_block(proc, NULL, "builtin.append.able");
					irBlock *done = ir_add_block(proc, NULL, "builtin.append.done");

					ir_emit_if(proc, cond, able, done);
					proc->curr_block = able;

					// Add new slice item
					i64 item_size = type_size_of(proc->module->sizes, proc->module->allocator, elem_type);
					irValue *byte_count = ir_make_const_int(proc->module->allocator, item_size);

					irValue *offset = ir_emit_ptr_offset(proc, elem, len);
					offset = ir_emit_conv(proc, offset, t_rawptr);

					item = ir_emit_ptr_offset(proc, item, v_zero);
					item = ir_emit_conv(proc, item, t_rawptr);

					irValue **args = gb_alloc_array(proc->module->allocator, irValue *, 3);
					args[0] = offset;
					args[1] = item;
					args[2] = byte_count;

					ir_emit_global_call(proc, "__mem_copy", args, 3);

					// Increment slice length
					irValue *new_len = ir_emit_arith(proc, Token_Add, len, v_one, t_int);
					irValue *gep = ir_emit_struct_ep(proc, slice_ptr, 1);
					ir_emit_store(proc, gep, new_len);

					ir_emit_jump(proc, done);
					proc->curr_block = done;

					return ir_emit_conv(proc, cond, t_bool);
				} break;
				#endif

				case BuiltinProc_swizzle: {
					ir_emit_comment(proc, str_lit("swizzle"));
					irValue *vector = ir_build_expr(proc, ce->args.e[0]);
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

					return ir_emit(proc, ir_make_instr_vector_shuffle(proc, vector, indices, index_count));

				} break;

				case BuiltinProc_slice_ptr: {
					ir_emit_comment(proc, str_lit("slice_ptr"));
					irValue *ptr = ir_build_expr(proc, ce->args.e[0]);
					irValue *count = ir_build_expr(proc, ce->args.e[1]);
					count = ir_emit_conv(proc, count, t_int);

					Type *slice_type = make_type_slice(proc->module->allocator, type_deref(ir_type(ptr)));
					irValue *slice = ir_add_local_generated(proc, slice_type);
					ir_emit_store(proc, ir_emit_struct_ep(proc, slice, 0), ptr);
					ir_emit_store(proc, ir_emit_struct_ep(proc, slice, 1), count);
					return ir_emit_load(proc, slice);
				} break;

				case BuiltinProc_min: {
					ir_emit_comment(proc, str_lit("min"));
					Type *t = type_of_expr(proc->module->info, expr);
					irValue *x = ir_emit_conv(proc, ir_build_expr(proc, ce->args.e[0]), t);
					irValue *y = ir_emit_conv(proc, ir_build_expr(proc, ce->args.e[1]), t);
					irValue *cond = ir_emit_comp(proc, Token_Lt, x, y);
					return ir_emit_select(proc, cond, x, y);
				} break;

				case BuiltinProc_max: {
					ir_emit_comment(proc, str_lit("max"));
					Type *t = type_of_expr(proc->module->info, expr);
					irValue *x = ir_emit_conv(proc, ir_build_expr(proc, ce->args.e[0]), t);
					irValue *y = ir_emit_conv(proc, ir_build_expr(proc, ce->args.e[1]), t);
					irValue *cond = ir_emit_comp(proc, Token_Gt, x, y);
					return ir_emit_select(proc, cond, x, y);
				} break;

				case BuiltinProc_abs: {
					ir_emit_comment(proc, str_lit("abs"));
					irValue *x = ir_build_expr(proc, ce->args.e[0]);
					Type *t = ir_type(x);
					irValue *zero = ir_emit_conv(proc, v_zero, t);
					irValue *cond = ir_emit_comp(proc, Token_Lt, x, zero);
					irValue *neg = ir_emit(proc, ir_make_instr_unary_op(proc, Token_Sub, x, t));
					return ir_emit_select(proc, cond, neg, x);
				} break;

				case BuiltinProc_clamp: {
					ir_emit_comment(proc, str_lit("clamp"));
					Type *t = type_of_expr(proc->module->info, expr);
					irValue *x   = ir_emit_conv(proc, ir_build_expr(proc, ce->args.e[0]), t);
					irValue *min = ir_emit_conv(proc, ir_build_expr(proc, ce->args.e[1]), t);
					irValue *max = ir_emit_conv(proc, ir_build_expr(proc, ce->args.e[2]), t);
					irValue *cond;
					cond = ir_emit_comp(proc, Token_Gt, min, x);
					x    = ir_emit_select(proc, cond,   min, x);
					cond = ir_emit_comp(proc, Token_Lt, max, x);
					x    = ir_emit_select(proc, cond,   max, x);
					return x;
				} break;
				}
			}
		}

		// NOTE(bill): Regular call
		irValue *value = ir_build_expr(proc, ce->proc);
		GB_ASSERT(value != NULL);
		Type *proc_type_ = base_type(ir_type(value));
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
		irValue **args = gb_alloc_array(proc->module->allocator, irValue *, arg_count);
		bool variadic = proc_type_->Proc.variadic;
		bool vari_expand = ce->ellipsis.pos.line != 0;

		for_array(i, ce->args) {
			irValue *a = ir_build_expr(proc, ce->args.e[i]);
			Type *at = ir_type(a);
			if (at->kind == Type_Tuple) {
				for (isize i = 0; i < at->Tuple.variable_count; i++) {
					Entity *e = at->Tuple.variables[i];
					irValue *v = ir_emit_struct_ev(proc, a, i);
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
				args[i] = ir_emit_conv(proc, args[i], pt->variables[i]->type);
			}
			if (!vari_expand) {
				Type *variadic_type = pt->variables[i]->type;
				GB_ASSERT(is_type_slice(variadic_type));
				variadic_type = base_type(variadic_type)->Slice.elem;
				for (; i < arg_count; i++) {
					args[i] = ir_emit_conv(proc, args[i], variadic_type);
				}
			}
		} else {
			for (isize i = 0; i < arg_count; i++) {
				args[i] = ir_emit_conv(proc, args[i], pt->variables[i]->type);
			}
		}

		if (variadic && !vari_expand) {
			ir_emit_comment(proc, str_lit("variadic call argument generation"));
			gbAllocator allocator = proc->module->allocator;
			Type *slice_type = pt->variables[type->param_count-1]->type;
			Type *elem_type  = base_type(slice_type)->Slice.elem;
			irValue *slice = ir_add_local_generated(proc, slice_type);
			isize slice_len = arg_count+1 - type->param_count;

			if (slice_len > 0) {
				irValue *base_array = ir_add_local_generated(proc, make_type_array(allocator, elem_type, slice_len));

				for (isize i = type->param_count-1, j = 0; i < arg_count; i++, j++) {
					irValue *addr = ir_emit_array_epi(proc, base_array, j);
					ir_emit_store(proc, addr, args[i]);
				}

				irValue *base_elem  = ir_emit_array_epi(proc, base_array, 0);
				irValue *slice_elem = ir_emit_struct_ep(proc, slice,      0);
				ir_emit_store(proc, slice_elem, base_elem);
				irValue *len = ir_make_const_int(allocator, slice_len);
				ir_emit_store(proc, ir_emit_struct_ep(proc, slice, 1), len);
			}

			arg_count = type->param_count;
			args[arg_count-1] = ir_emit_load(proc, slice);
		}

		return ir_emit_call(proc, value, args, arg_count);
	case_end;

	case_ast_node(de, DemaybeExpr, expr);
		return ir_emit_load(proc, ir_build_addr(proc, expr).addr);
	case_end;

	case_ast_node(se, SliceExpr, expr);
		return ir_emit_load(proc, ir_build_addr(proc, expr).addr);
	case_end;

	case_ast_node(ie, IndexExpr, expr);
		return ir_emit_load(proc, ir_build_addr(proc, expr).addr);
	case_end;
	}

	GB_PANIC("Unexpected expression: %.*s", LIT(ast_node_strings[expr->kind]));
	return NULL;
}


irValue *ir_build_expr(irProcedure *proc, AstNode *expr) {
	expr = unparen_expr(expr);

	TypeAndValue *tv = map_tav_get(&proc->module->info->types, hash_pointer(expr));
	GB_ASSERT_NOT_NULL(tv);

	if (tv->value.kind != ExactValue_Invalid) {
		return ir_add_module_constant(proc->module, tv->type, tv->value);
	}

	irValue *value = NULL;
	if (tv->mode == Addressing_Variable) {
		value = ir_addr_load(proc, ir_build_addr(proc, expr));
	} else {
		value = ir_build_single_expr(proc, expr, tv);
	}

	return value;
}

irValue *ir_add_using_variable(irProcedure *proc, Entity *e) {
	GB_ASSERT(e->kind == Entity_Variable && e->flags & EntityFlag_Anonymous);
	String name = e->token.string;
	Entity *parent = e->using_parent;
	Selection sel = lookup_field(proc->module->allocator, parent->type, name, false);
	GB_ASSERT(sel.entity != NULL);
	irValue **pv = map_ir_value_get(&proc->module->values, hash_pointer(parent));
	irValue *v = NULL;
	if (pv != NULL) {
		v = *pv;
	} else {
		v = ir_build_addr(proc, e->using_expr).addr;
	}
	GB_ASSERT(v != NULL);
	irValue *var = ir_emit_deep_field_gep(proc, parent->type, v, sel);
	map_ir_value_set(&proc->module->values, hash_pointer(e), var);
	return var;
}

bool ir_is_elem_const(irModule *m, AstNode *elem, Type *elem_type) {
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

irAddr ir_build_addr_from_entity(irProcedure *proc, Entity *e, AstNode *expr) {
	GB_ASSERT(e != NULL);
	GB_ASSERT(e->kind != Entity_Constant);

	irValue *v = NULL;
	irValue **found = map_ir_value_get(&proc->module->values, hash_pointer(e));
	if (found) {
		v = *found;
	} else if (e->kind == Entity_Variable && e->flags & EntityFlag_Anonymous) {
		v = ir_add_using_variable(proc, e);
	} else if (e->kind == Entity_ImplicitValue) {
		// TODO(bill): Should a copy be made?
		v = ir_find_implicit_value_backing(proc, e->ImplicitValue.id);
	}

	if (v == NULL) {
		GB_PANIC("Unknown value: %.*s, entity: %p %.*s\n", LIT(e->token.string), e, LIT(entity_strings[e->kind]));
	}

	return ir_make_addr(v, expr);
}

irAddr ir_build_addr(irProcedure *proc, AstNode *expr) {
	switch (expr->kind) {
	case_ast_node(i, Ident, expr);
		if (ir_is_blank_ident(expr)) {
			irAddr val = {0};
			return val;
		}
		Entity *e = entity_of_ident(proc->module->info, expr);
		return ir_build_addr_from_entity(proc, e, expr);
	case_end;

	case_ast_node(pe, ParenExpr, expr);
		return ir_build_addr(proc, unparen_expr(expr));
	case_end;

	case_ast_node(se, SelectorExpr, expr);
		ir_emit_comment(proc, str_lit("SelectorExpr"));
		AstNode *sel = unparen_expr(se->selector);
		if (sel->kind == AstNode_Ident) {
			String selector = sel->Ident.string;
			Type *type = base_type(type_of_expr(proc->module->info, se->expr));

			if (type == t_invalid) {
				// NOTE(bill): Imports
				Entity *imp = entity_of_ident(proc->module->info, se->expr);
				if (imp != NULL) {
					GB_ASSERT(imp->kind == Entity_ImportName);
				}
				return ir_build_addr(proc, unparen_expr(se->selector));
			} else {
				Selection sel = lookup_field(proc->module->allocator, type, selector, false);
				GB_ASSERT(sel.entity != NULL);

				irValue *a = ir_build_addr(proc, se->expr).addr;
				a = ir_emit_deep_field_gep(proc, type, a, sel);
				return ir_make_addr(a, expr);
			}
		} else {
			Type *type = base_type(type_of_expr(proc->module->info, se->expr));
			ExactValue val = type_and_value_of_expression(proc->module->info, sel)->value;
			i64 index = val.value_integer;

			Selection sel = lookup_field_from_index(proc->module->allocator, type, index);
			GB_ASSERT(sel.entity != NULL);

			irValue *a = ir_build_addr(proc, se->expr).addr;
			a = ir_emit_deep_field_gep(proc, type, a, sel);
			return ir_make_addr(a, expr);
		}
	case_end;

	case_ast_node(ce, CastExpr, expr);
		switch (ce->token.kind) {
		case Token_cast: {
			ir_emit_comment(proc, str_lit("Cast - cast"));
			// NOTE(bill): Needed for dereference of pointer conversion
			Type *type = type_of_expr(proc->module->info, expr);
			irValue *v = ir_add_local_generated(proc, type);
			ir_emit_store(proc, v, ir_emit_conv(proc, ir_build_expr(proc, ce->expr), type));
			return ir_make_addr(v, expr);
		}
		case Token_transmute: {
			ir_emit_comment(proc, str_lit("Cast - transmute"));
			// NOTE(bill): Needed for dereference of pointer conversion
			Type *type = type_of_expr(proc->module->info, expr);
			irValue *v = ir_add_local_generated(proc, type);
			ir_emit_store(proc, v, ir_emit_transmute(proc, ir_build_expr(proc, ce->expr), type));
			return ir_make_addr(v, expr);
		}
		default:
			GB_PANIC("Unknown cast expression");
		}
	case_end;

	case_ast_node(ue, UnaryExpr, expr);
		switch (ue->op.kind) {
		case Token_Pointer: {
			return ir_build_addr(proc, ue->expr);
		}
		default:
			GB_PANIC("Invalid unary expression for ir_build_addr");
		}
	case_end;

	case_ast_node(be, BinaryExpr, expr);
		switch (be->op.kind) {
		// case Token_as: {
		// 	ir_emit_comment(proc, str_lit("Cast - as"));
		// 	// NOTE(bill): Needed for dereference of pointer conversion
		// 	Type *type = type_of_expr(proc->module->info, expr);
		// 	irValue *v = ir_add_local_generated(proc, type);
		// 	ir_emit_store(proc, v, ir_emit_conv(proc, ir_build_expr(proc, be->left), type));
		// 	return ir_make_addr(v, expr);
		// }
		// case Token_transmute: {
		// 	ir_emit_comment(proc, str_lit("Cast - transmute"));
		// 	// NOTE(bill): Needed for dereference of pointer conversion
		// 	Type *type = type_of_expr(proc->module->info, expr);
		// 	irValue *v = ir_add_local_generated(proc, type);
		// 	ir_emit_store(proc, v, ir_emit_transmute(proc, ir_build_expr(proc, be->left), type));
		// 	return ir_make_addr(v, expr);
		// }
		default:
			GB_PANIC("Invalid binary expression for ir_build_addr: %.*s\n", LIT(be->op.string));
			break;
		}
	case_end;

	case_ast_node(ie, IndexExpr, expr);
		ir_emit_comment(proc, str_lit("IndexExpr"));
		Type *t = base_type(type_of_expr(proc->module->info, ie->expr));
		gbAllocator a = proc->module->allocator;


		bool deref = is_type_pointer(t);
		t = type_deref(t);

		irValue *using_addr = NULL;
		if (!is_type_indexable(t)) {
			// Using index expression
			Entity *using_field = find_using_index_expr(t);
			if (using_field != NULL) {
				Selection sel = lookup_field(a, t, using_field->token.string, false);
				irValue *e = ir_build_addr(proc, ie->expr).addr;
				using_addr = ir_emit_deep_field_gep(proc, t, e, sel);

				t = using_field->type;
			}
		}


		switch (t->kind) {
		case Type_Vector: {
			irValue *vector = NULL;
			if (using_addr != NULL) {
				vector = using_addr;
			} else {
				vector = ir_build_addr(proc, ie->expr).addr;
				if (deref) {
					vector = ir_emit_load(proc, vector);
				}
			}
			irValue *index = ir_emit_conv(proc, ir_build_expr(proc, ie->index), t_int);
			irValue *len = ir_make_const_int(a, t->Vector.count);
			ir_emit_bounds_check(proc, ast_node_token(ie->index), index, len);
			return ir_make_addr_vector(vector, index, expr);
		} break;

		case Type_Array: {
			irValue *array = NULL;
			if (using_addr != NULL) {
				array = using_addr;
			} else {
				array = ir_build_addr(proc, ie->expr).addr;
				if (deref) {
					array = ir_emit_load(proc, array);
				}
			}
			irValue *index = ir_emit_conv(proc, ir_build_expr(proc, ie->index), t_int);
			irValue *elem = ir_emit_array_ep(proc, array, index);
			irValue *len = ir_make_const_int(a, t->Vector.count);
			ir_emit_bounds_check(proc, ast_node_token(ie->index), index, len);
			return ir_make_addr(elem, expr);
		} break;

		case Type_Slice: {
			irValue *slice = NULL;
			if (using_addr != NULL) {
				slice = ir_emit_load(proc, using_addr);
			} else {
				slice = ir_build_expr(proc, ie->expr);
				if (deref) {
					slice = ir_emit_load(proc, slice);
				}
			}
			irValue *elem = ir_slice_elem(proc, slice);
			irValue *len = ir_slice_count(proc, slice);
			irValue *index = ir_emit_conv(proc, ir_build_expr(proc, ie->index), t_int);
			ir_emit_bounds_check(proc, ast_node_token(ie->index), index, len);
			irValue *v = ir_emit_ptr_offset(proc, elem, index);
			return ir_make_addr(v, expr);
		} break;

		case Type_DynamicArray: {
			irValue *dynamic_array = NULL;
			if (using_addr != NULL) {
				dynamic_array = ir_emit_load(proc, using_addr);
			} else {
				dynamic_array = ir_build_expr(proc, ie->expr);
				if (deref) {
					dynamic_array = ir_emit_load(proc, dynamic_array);
				}
			}
			irValue *elem = ir_dynamic_array_elem(proc, dynamic_array);
			irValue *len = ir_dynamic_array_count(proc, dynamic_array);
			irValue *index = ir_emit_conv(proc, ir_build_expr(proc, ie->index), t_int);
			ir_emit_bounds_check(proc, ast_node_token(ie->index), index, len);
			irValue *v = ir_emit_ptr_offset(proc, elem, index);
			return ir_make_addr(v, expr);
		} break;


		case Type_Basic: { // Basic_string
			TypeAndValue *tv = map_tav_get(&proc->module->info->types, hash_pointer(ie->expr));
			irValue *str;
			irValue *elem;
			irValue *len;
			irValue *index;

			if (using_addr != NULL) {
				str = ir_emit_load(proc, using_addr);
			} else {
				str = ir_build_expr(proc, ie->expr);
				if (deref) {
					str = ir_emit_load(proc, str);
				}
			}
			elem = ir_string_elem(proc, str);
			len = ir_string_len(proc, str);

			index = ir_emit_conv(proc, ir_build_expr(proc, ie->index), t_int);
			ir_emit_bounds_check(proc, ast_node_token(ie->index), index, len);

			return ir_make_addr(ir_emit_ptr_offset(proc, elem, index), expr);
		} break;
		}
	case_end;

	case_ast_node(se, SliceExpr, expr);
		ir_emit_comment(proc, str_lit("SliceExpr"));
		gbAllocator a = proc->module->allocator;
		irValue *low  = v_zero;
		irValue *high = NULL;

		if (se->low  != NULL)    low  = ir_build_expr(proc, se->low);
		if (se->high != NULL)    high = ir_build_expr(proc, se->high);
		irValue *addr = ir_build_addr(proc, se->expr).addr;
		irValue *base = ir_emit_load(proc, addr);
		Type *type = base_type(ir_type(base));

		if (is_type_pointer(type)) {
			type = type_deref(type);
			addr = base;
			base = ir_emit_load(proc, base);
		}

		// TODO(bill): Cleanup like mad!

		switch (type->kind) {
		case Type_Slice: {
			Type *slice_type = type;

			if (high == NULL) high = ir_slice_count(proc, base);

			ir_emit_slice_bounds_check(proc, se->open, low, high, false);

			irValue *elem  = ir_emit_ptr_offset(proc, ir_slice_elem(proc, base), low);
			irValue *len   = ir_emit_arith(proc, Token_Sub, high, low, t_int);
			irValue *slice = ir_add_local_generated(proc, slice_type);

			ir_emit_store(proc, ir_emit_struct_ep(proc, slice, 0), elem);
			ir_emit_store(proc, ir_emit_struct_ep(proc, slice, 1), len);

			return ir_make_addr(slice, expr);
		}

		case Type_DynamicArray: {
			Type *dynamic_array = type;

			if (high == NULL) high = ir_dynamic_array_count(proc, base);

			ir_emit_slice_bounds_check(proc, se->open, low, high, false);

			irValue *elem  = ir_emit_ptr_offset(proc, ir_dynamic_array_elem(proc, base), low);
			irValue *len   = ir_emit_arith(proc, Token_Sub, high, low, t_int);
			irValue *slice = ir_add_local_generated(proc, dynamic_array);

			ir_emit_store(proc, ir_emit_struct_ep(proc, slice, 0), elem);
			ir_emit_store(proc, ir_emit_struct_ep(proc, slice, 1), len);

			return ir_make_addr(slice, expr);
		}


		case Type_Array: {
			Type *slice_type = make_type_slice(a, type->Array.elem);

			if (high == NULL) high = ir_array_len(proc, base);

			ir_emit_slice_bounds_check(proc, se->open, low, high, false);

			irValue *elem = ir_emit_ptr_offset(proc, ir_array_elem(proc, addr), low);
			irValue *len  = ir_emit_arith(proc, Token_Sub, high, low, t_int);
			irValue *slice = ir_add_local_generated(proc, slice_type);

			ir_emit_store(proc, ir_emit_struct_ep(proc, slice, 0), elem);
			ir_emit_store(proc, ir_emit_struct_ep(proc, slice, 1), len);

			return ir_make_addr(slice, expr);
		}

		case Type_Basic: {
			GB_ASSERT(type == t_string);
			if (high == NULL) {
				high = ir_string_len(proc, base);
			}

			ir_emit_slice_bounds_check(proc, se->open, low, high, true);

			irValue *elem, *len;
			len = ir_emit_arith(proc, Token_Sub, high, low, t_int);

			elem = ir_string_elem(proc, base);
			elem = ir_emit_ptr_offset(proc, elem, low);

			irValue *str = ir_add_local_generated(proc, t_string);
			irValue *gep0 = ir_emit_struct_ep(proc, str, 0);
			irValue *gep1 = ir_emit_struct_ep(proc, str, 1);
			ir_emit_store(proc, gep0, elem);
			ir_emit_store(proc, gep1, len);

			return ir_make_addr(str, expr);
		} break;
		}

		GB_PANIC("Unknown slicable type");
	case_end;

	case_ast_node(de, DerefExpr, expr);
		// TODO(bill): Is a ptr copy needed?
		irValue *addr = ir_build_expr(proc, de->expr);
		addr = ir_emit_ptr_offset(proc, addr, v_zero);
		return ir_make_addr(addr, expr);
	case_end;

	case_ast_node(de, DemaybeExpr, expr);
		ir_emit_comment(proc, str_lit("DemaybeExpr"));
		irValue *maybe = ir_build_expr(proc, de->expr);
		Type *t = default_type(type_of_expr(proc->module->info, expr));
		GB_ASSERT(is_type_tuple(t));

		irValue *result = ir_add_local_generated(proc, t);
		ir_emit_store(proc, result, maybe);

		return ir_make_addr(result, expr);
	case_end;

	case_ast_node(ce, CallExpr, expr);
		irValue *e = ir_build_expr(proc, expr);
		irValue *v = ir_add_local_generated(proc, ir_type(e));
		ir_emit_store(proc, v, e);
		return ir_make_addr(v, expr);
	case_end;


	case_ast_node(cl, CompoundLit, expr);
		ir_emit_comment(proc, str_lit("CompoundLit"));
		Type *type = type_of_expr(proc->module->info, expr);
		Type *bt = base_type(type);
		irValue *v = ir_add_local_generated(proc, type);

		Type *et = NULL;
		switch (bt->kind) {
		case Type_Vector: et = bt->Vector.elem; break;
		case Type_Array:  et = bt->Array.elem;  break;
		case Type_Slice:  et = bt->Slice.elem;  break;
		}

		switch (bt->kind) {
		default: GB_PANIC("Unknown CompoundLit type: %s", type_to_string(type)); break;

		case Type_Vector: {
			irValue *result = ir_add_module_constant(proc->module, type, make_exact_value_compound(expr));
			for_array(index, cl->elems) {
				AstNode *elem = cl->elems.e[index];
				if (ir_is_elem_const(proc->module, elem, et)) {
					continue;
				}
				irValue *field_elem = ir_build_expr(proc, elem);
				Type *t = ir_type(field_elem);
				GB_ASSERT(t->kind != Type_Tuple);
				irValue *ev = ir_emit_conv(proc, field_elem, et);
				irValue *i = ir_make_const_int(proc->module->allocator, index);
				result = ir_emit(proc, ir_make_instr_insert_element(proc, result, ev, i));
			}

			if (cl->elems.count == 1 && bt->Vector.count > 1) {
				isize index_count = bt->Vector.count;
				i32 *indices = gb_alloc_array(proc->module->allocator, i32, index_count);
				for (isize i = 0; i < index_count; i++) {
					indices[i] = 0;
				}
				irValue *sv = ir_emit(proc, ir_make_instr_vector_shuffle(proc, result, indices, index_count));
				ir_emit_store(proc, v, sv);
				return ir_make_addr(v, expr);
			}
			ir_emit_store(proc, v, result);
		} break;

		case Type_Record: {
			GB_ASSERT(is_type_struct(bt));
			TypeRecord *st = &bt->Record;
			if (cl->elems.count > 0) {
				ir_emit_store(proc, v, ir_add_module_constant(proc->module, type, make_exact_value_compound(expr)));
				for_array(field_index, cl->elems) {
					AstNode *elem = cl->elems.e[field_index];

					irValue *field_expr = NULL;
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
					if (ir_is_elem_const(proc->module, elem, field->type)) {
						continue;
					}

					field_expr = ir_build_expr(proc, elem);

					GB_ASSERT(ir_type(field_expr)->kind != Type_Tuple);

					Type *ft = field->type;
					irValue *fv = ir_emit_conv(proc, field_expr, ft);
					irValue *gep = ir_emit_struct_ep(proc, v, index);
					ir_emit_store(proc, gep, fv);
				}
			}
		} break;
		case Type_Array: {
			if (cl->elems.count > 0) {
				ir_emit_store(proc, v, ir_add_module_constant(proc->module, type, make_exact_value_compound(expr)));
				for_array(i, cl->elems) {
					AstNode *elem = cl->elems.e[i];
					if (ir_is_elem_const(proc->module, elem, et)) {
						continue;
					}
					irValue *field_expr = ir_build_expr(proc, elem);
					Type *t = ir_type(field_expr);
					GB_ASSERT(t->kind != Type_Tuple);
					irValue *ev = ir_emit_conv(proc, field_expr, et);
					irValue *gep = ir_emit_array_epi(proc, v, i);
					ir_emit_store(proc, gep, ev);
				}
			}
		} break;
		case Type_Slice: {
			if (cl->elems.count > 0) {
				Type *elem_type = bt->Slice.elem;
				Type *elem_ptr_type = make_type_pointer(proc->module->allocator, elem_type);
				Type *elem_ptr_ptr_type = make_type_pointer(proc->module->allocator, elem_ptr_type);
				irValue *slice = ir_add_module_constant(proc->module, type, make_exact_value_compound(expr));
				GB_ASSERT(slice->kind == irValue_ConstantSlice);

				irValue *data = ir_emit_array_ep(proc, slice->ConstantSlice.backing_array, v_zero32);

				for_array(i, cl->elems) {
					AstNode *elem = cl->elems.e[i];
					if (ir_is_elem_const(proc->module, elem, et)) {
						continue;
					}

					irValue *field_expr = ir_build_expr(proc, elem);
					Type *t = ir_type(field_expr);
					GB_ASSERT(t->kind != Type_Tuple);
					irValue *ev = ir_emit_conv(proc, field_expr, elem_type);
					irValue *offset = ir_emit_ptr_offset(proc, data, ir_make_const_int(proc->module->allocator, i));
					ir_emit_store(proc, offset, ev);
				}

				irValue *gep0 = ir_emit_struct_ep(proc, v, 0);
				irValue *gep1 = ir_emit_struct_ep(proc, v, 1);
				irValue *gep2 = ir_emit_struct_ep(proc, v, 1);

				ir_emit_store(proc, gep0, data);
				ir_emit_store(proc, gep1, ir_make_const_int(proc->module->allocator, slice->ConstantSlice.count));
				ir_emit_store(proc, gep2, ir_make_const_int(proc->module->allocator, slice->ConstantSlice.count));
			}
		} break;

		case Type_Basic: {
			GB_ASSERT(is_type_any(bt));
			if (cl->elems.count > 0) {
				ir_emit_store(proc, v, ir_add_module_constant(proc->module, type, make_exact_value_compound(expr)));
				String field_names[2] = {
					str_lit("type_info"),
					str_lit("data"),
				};
				Type *field_types[2] = {
					t_type_info_ptr,
					t_rawptr,
				};

				for_array(field_index, cl->elems) {
					AstNode *elem = cl->elems.e[field_index];

					irValue *field_expr = NULL;
					isize index = field_index;

					if (elem->kind == AstNode_FieldValue) {
						ast_node(fv, FieldValue, elem);
						Selection sel = lookup_field(proc->module->allocator, bt, fv->field->Ident.string, false);
						index = sel.index.e[0];
						elem = fv->value;
					} else {
						TypeAndValue *tav = type_and_value_of_expression(proc->module->info, elem);
						Selection sel = lookup_field(proc->module->allocator, bt, field_names[field_index], false);
						index = sel.index.e[0];
					}

					field_expr = ir_build_expr(proc, elem);

					GB_ASSERT(ir_type(field_expr)->kind != Type_Tuple);

					Type *ft = field_types[index];
					irValue *fv = ir_emit_conv(proc, field_expr, ft);
					irValue *gep = ir_emit_struct_ep(proc, v, index);
					ir_emit_store(proc, gep, fv);
				}
			}
		}
		}

		return ir_make_addr(v, expr);
	case_end;


	}

	TokenPos token_pos = ast_node_token(expr).pos;
	GB_PANIC("Unexpected address expression\n"
	         "\tAstNode: %.*s @ "
	         "%.*s(%td:%td)\n",
	         LIT(ast_node_strings[expr->kind]),
	         LIT(token_pos.file), token_pos.line, token_pos.column);


	return ir_make_addr(NULL, NULL);
}

void ir_build_assign_op(irProcedure *proc, irAddr lhs, irValue *value, TokenKind op) {
	irValue *old_value = ir_addr_load(proc, lhs);
	Type *type = ir_type(old_value);

	irValue *change = value;
	if (is_type_pointer(type) && is_type_integer(ir_type(value))) {
		change = ir_emit_conv(proc, value, default_type(ir_type(value)));
	} else {
		change = ir_emit_conv(proc, value, type);
	}
	irValue *new_value = ir_emit_arith(proc, op, old_value, change, type);
	ir_addr_store(proc, lhs, new_value);
}

irValue *ir_build_cond(irProcedure *proc, AstNode *cond, irBlock *true_block, irBlock *false_block) {
	switch (cond->kind) {
	case_ast_node(pe, ParenExpr, cond);
		return ir_build_cond(proc, pe->expr, true_block, false_block);
	case_end;

	case_ast_node(ue, UnaryExpr, cond);
		if (ue->op.kind == Token_Not) {
			return ir_build_cond(proc, ue->expr, false_block, true_block);
		}
	case_end;

	case_ast_node(be, BinaryExpr, cond);
		if (be->op.kind == Token_CmpAnd) {
			irBlock *block = ir_add_block(proc, NULL, "cmp.and");
			ir_build_cond(proc, be->left, block, false_block);
			proc->curr_block = block;
			return ir_build_cond(proc, be->right, true_block, false_block);
		} else if (be->op.kind == Token_CmpOr) {
			irBlock *block = ir_add_block(proc, NULL, "cmp.or");
			ir_build_cond(proc, be->left, true_block, block);
			proc->curr_block = block;
			return ir_build_cond(proc, be->right, true_block, false_block);
		}
	case_end;
	}

	irValue *v = ir_build_expr(proc, cond);
	v = ir_emit_conv(proc, v, t_bool);
	ir_emit_if(proc, v, true_block, false_block);
	return v;
}




void ir_build_stmt_list(irProcedure *proc, AstNodeArray stmts) {
	for_array(i, stmts) {
		ir_build_stmt(proc, stmts.e[i]);
	}
}

void ir_build_stmt_internal(irProcedure *proc, AstNode *node);
void ir_build_stmt(irProcedure *proc, AstNode *node) {
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

	ir_build_stmt_internal(proc, node);

	proc->module->stmt_state_flags = prev_stmt_state_flags;
}

void ir_build_when_stmt(irProcedure *proc, AstNodeWhenStmt *ws) {
	irValue *cond = ir_build_expr(proc, ws->cond);
	GB_ASSERT(cond->kind == irValue_Constant &&
	          is_type_boolean(ir_type(cond)));

	GB_ASSERT(cond->Constant.value.kind == ExactValue_Bool);
	if (cond->Constant.value.value_bool) {
		ir_build_stmt_list(proc, ws->body->BlockStmt.stmts);
	} else if (ws->else_stmt) {
		switch (ws->else_stmt->kind) {
		case AstNode_BlockStmt:
			ir_build_stmt_list(proc, ws->else_stmt->BlockStmt.stmts);
			break;
		case AstNode_WhenStmt:
			ir_build_when_stmt(proc, &ws->else_stmt->WhenStmt);
			break;
		default:
			GB_PANIC("Invalid `else` statement in `when` statement");
			break;
		}
	}
}

void ir_emit_increment(irProcedure *proc, irValue *addr) {
	GB_ASSERT(is_type_pointer(ir_type(addr)));
	Type *type = type_deref(ir_type(addr));
	ir_emit_store(proc, addr, ir_emit_arith(proc, Token_Add, ir_emit_load(proc, addr), v_one, type));

}

void ir_build_range_indexed(irProcedure *proc, irValue *expr, Type *val_type, irValue *count_ptr,
                            irValue **val_, irValue **idx_, irBlock **loop_, irBlock **done_) {
	irValue *count = NULL;
	Type *expr_type = base_type(type_deref(ir_type(expr)));
	switch (expr_type->kind) {
	case Type_Array:
		count = ir_make_const_int(proc->module->allocator, expr_type->Array.count);
		break;
	}

	irValue *val = NULL;
	irValue *idx = NULL;
	irBlock *loop = NULL;
	irBlock *done = NULL;
	irBlock *body = NULL;

	irValue *index = ir_add_local_generated(proc, t_int);
	ir_emit_store(proc, index, ir_make_const_int(proc->module->allocator, -1));

	loop = ir_add_block(proc, NULL, "for.index.loop");
	ir_emit_jump(proc, loop);
	proc->curr_block = loop;

	irValue *incr = ir_emit_arith(proc, Token_Add, ir_emit_load(proc, index), v_one, t_int);
	ir_emit_store(proc, index, incr);

	body = ir_add_block(proc, NULL, "for.index.body");
	done = ir_add_block(proc, NULL, "for.index.done");
	if (count == NULL) {
		count = ir_emit_load(proc, count_ptr);
	}
	irValue *cond = ir_emit_comp(proc, Token_Lt, incr, count);
	ir_emit_if(proc, cond, body, done);
	proc->curr_block = body;

	idx = ir_emit_load(proc, index);
	if (val_type != NULL) {
		switch (expr_type->kind) {
		case Type_Array: {
			// val = ir_emit_array_ep(proc, expr, idx);
			val = ir_emit_load(proc, ir_emit_array_ep(proc, expr, idx));
		} break;
		case Type_Slice: {
			irValue *elem = ir_slice_elem(proc, expr);
			val = ir_emit_load(proc, ir_emit_ptr_offset(proc, elem, idx));
		} break;
		case Type_DynamicArray: {
			irValue *elem = ir_dynamic_array_elem(proc, expr);
			val = ir_emit_load(proc, ir_emit_ptr_offset(proc, elem, idx));
		} break;
		default:
			GB_PANIC("Cannot do range_indexed of %s", type_to_string(expr_type));
			break;
		}
	}

	if (val_)  *val_  = val;
	if (idx_)  *idx_  = idx;
	if (loop_) *loop_ = loop;
	if (done_) *done_ = done;
}


void ir_build_range_string(irProcedure *proc, irValue *expr, Type *val_type,
                            irValue **val_, irValue **idx_, irBlock **loop_, irBlock **done_) {
	irValue *count = v_zero;
	Type *expr_type = base_type(ir_type(expr));
	switch (expr_type->kind) {
	case Type_Basic:
		count = ir_string_len(proc, expr);
		break;
	default:
		GB_PANIC("Cannot do range_string of %s", type_to_string(expr_type));
		break;
	}

	irValue *val = NULL;
	irValue *idx = NULL;
	irBlock *loop = NULL;
	irBlock *done = NULL;
	irBlock *body = NULL;

	irValue *index = ir_add_local_generated(proc, t_int);
	ir_emit_store(proc, index, v_zero);

	irValue *offset_ = ir_add_local_generated(proc, t_int);
	ir_emit_store(proc, index, v_zero);

	loop = ir_add_block(proc, NULL, "for.string.loop");
	ir_emit_jump(proc, loop);
	proc->curr_block = loop;



	body = ir_add_block(proc, NULL, "for.string.body");
	done = ir_add_block(proc, NULL, "for.string.done");

	irValue *offset = ir_emit_load(proc, offset_);

	irValue *cond = ir_emit_comp(proc, Token_Lt, offset, count);
	ir_emit_if(proc, cond, body, done);
	proc->curr_block = body;


	irValue *str_elem = ir_emit_ptr_offset(proc, ir_string_elem(proc, expr), offset);
	irValue *str_len  = ir_emit_arith(proc, Token_Sub, count, offset, t_int);
	irValue **args    = gb_alloc_array(proc->module->allocator, irValue *, 1);
	args[0] = ir_emit_string(proc, str_elem, str_len);
	irValue *rune_and_len = ir_emit_global_call(proc, "__string_decode_rune", args, 1);
	irValue *len  = ir_emit_struct_ev(proc, rune_and_len, 1);
	ir_emit_store(proc, offset_, ir_emit_arith(proc, Token_Add, offset, len, t_int));


	idx = ir_emit_load(proc, index);
	if (val_type != NULL) {
		val = ir_emit_struct_ev(proc, rune_and_len, 0);
	}
	ir_emit_increment(proc, index);

	if (val_)  *val_  = val;
	if (idx_)  *idx_  = idx;
	if (loop_) *loop_ = loop;
	if (done_) *done_ = done;
}

void ir_build_range_interval(irProcedure *proc, AstNodeIntervalExpr *node, Type *val_type,
                              irValue **val_, irValue **idx_, irBlock **loop_, irBlock **done_) {
	// TODO(bill): How should the behaviour work for lower and upper bounds checking for iteration?
	// If `lower` is changed, should `val` do so or is that not typical behaviour?

	irValue *lower = ir_build_expr(proc, node->left);
	irValue *upper = NULL;

	irValue *val = NULL;
	irValue *idx = NULL;
	irBlock *loop = NULL;
	irBlock *done = NULL;
	irBlock *body = NULL;

	if (val_type == NULL) {
		val_type = ir_type(lower);
	}
	irValue *value = ir_add_local_generated(proc, val_type);
	ir_emit_store(proc, value, lower);

	irValue *index = ir_add_local_generated(proc, t_int);
	ir_emit_store(proc, index, ir_make_const_int(proc->module->allocator, 0));

	loop = ir_add_block(proc, NULL, "for.interval.loop");
	ir_emit_jump(proc, loop);
	proc->curr_block = loop;

	body = ir_add_block(proc, NULL, "for.interval.body");
	done = ir_add_block(proc, NULL, "for.interval.done");

	upper = ir_build_expr(proc, node->right);

	TokenKind op = Token_Lt;
	switch (node->op.kind) {
	case Token_HalfOpenRange: op = Token_Lt;   break;
	case Token_Ellipsis:      op = Token_LtEq; break;
	default: GB_PANIC("Invalid interval operator"); break;
	}
	irValue *cond = ir_emit_comp(proc, op, ir_emit_load(proc, value), upper);
	ir_emit_if(proc, cond, body, done);
	proc->curr_block = body;

	if (value != NULL) {
		val = ir_emit_load(proc, value);
	}
	idx = ir_emit_load(proc, index);

	ir_emit_increment(proc, value);
	ir_emit_increment(proc, index);

	if (val_)  *val_  = val;
	if (idx_)  *idx_  = idx;
	if (loop_) *loop_ = loop;
	if (done_) *done_ = done;
}


void ir_build_stmt_internal(irProcedure *proc, AstNode *node) {
	switch (node->kind) {
	case_ast_node(bs, EmptyStmt, node);
	case_end;

	case_ast_node(us, UsingStmt, node);
		AstNode *decl = unparen_expr(us->node);
		if (decl->kind == AstNode_ValueDecl) {
			ir_build_stmt(proc, decl);
		}
	case_end;

	case_ast_node(ws, WhenStmt, node);
		ir_build_when_stmt(proc, ws);
	case_end;

	case_ast_node(vd, ValueDecl, node);
		if (vd->is_var) {
			irModule *m = proc->module;
			gbTempArenaMemory tmp = gb_temp_arena_memory_begin(&m->tmp_arena);

			if (vd->values.count == 0) { // declared and zero-initialized
				for_array(i, vd->names) {
					AstNode *name = vd->names.e[i];
					if (!ir_is_blank_ident(name)) {
						ir_add_local_for_identifier(proc, name, true);
					}
				}
			} else { // Tuple(s)
				Array(irAddr) lvals;
				irValueArray  inits;
				array_init_reserve(&lvals, m->tmp_allocator, vd->names.count);
				array_init_reserve(&inits, m->tmp_allocator, vd->names.count);

				for_array(i, vd->names) {
					AstNode *name = vd->names.e[i];
					irAddr lval = ir_make_addr(NULL, NULL);
					if (!ir_is_blank_ident(name)) {
						ir_add_local_for_identifier(proc, name, false);
						lval = ir_build_addr(proc, name);
					}

					array_add(&lvals, lval);
				}

				for_array(i, vd->values) {
					irValue *init = ir_build_expr(proc, vd->values.e[i]);
					Type *t = ir_type(init);
					if (t->kind == Type_Tuple) {
						for (isize i = 0; i < t->Tuple.variable_count; i++) {
							Entity *e = t->Tuple.variables[i];
							irValue *v = ir_emit_struct_ev(proc, init, i);
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
					irValue *v = ir_emit_conv(proc, inits.e[i], ir_addr_type(lvals.e[i]));
					ir_addr_store(proc, lvals.e[i], v);
				}
			}

			gb_temp_arena_memory_end(tmp);
		} else {
			for_array(i, vd->names) {
				AstNode *ident = vd->names.e[i];
				GB_ASSERT(ident->kind == AstNode_Ident);
				Entity *e = entity_of_ident(proc->module->info, ident);
				GB_ASSERT(e != NULL);
				switch (e->kind) {
				case Entity_TypeName: {
					// NOTE(bill): Generate a new name
					// parent_proc.name-guid
					String ts_name = e->token.string;
					isize name_len = proc->name.len + 1 + ts_name.len + 1 + 10 + 1;
					u8 *name_text = gb_alloc_array(proc->module->allocator, u8, name_len);
					i32 guid = cast(i32)proc->module->members.entries.count;
					name_len = gb_snprintf(cast(char *)name_text, name_len, "%.*s.%.*s-%d", LIT(proc->name), LIT(ts_name), guid);
					String name = make_string(name_text, name_len-1);

					irValue *value = ir_make_value_type_name(proc->module->allocator,
					                                           name, e->type);
					map_string_set(&proc->module->type_names, hash_pointer(e->type), name);
					ir_gen_global_type_name(proc->module, e, name);
				} break;
				case Entity_Procedure: {
					DeclInfo **decl_info = map_decl_info_get(&proc->module->info->entities, hash_pointer(e));
					GB_ASSERT(decl_info != NULL);
					DeclInfo *dl = *decl_info;
					ast_node(pd, ProcLit, dl->proc_lit);
					if (pd->body != NULL) {
						CheckerInfo *info = proc->module->info;

						if (map_entity_get(&proc->module->min_dep_map, hash_pointer(e)) == NULL) {
							// NOTE(bill): Nothing depends upon it so doesn't need to be built
							break;
						}

						// NOTE(bill): Generate a new name
						// parent.name-guid
						String original_name = e->token.string;
						String pd_name = original_name;
						if (pd->link_name.len > 0) {
							pd_name = pd->link_name;
						}

						isize name_len = proc->name.len + 1 + pd_name.len + 1 + 10 + 1;
						u8 *name_text = gb_alloc_array(proc->module->allocator, u8, name_len);
						i32 guid = cast(i32)proc->children.count;
						name_len = gb_snprintf(cast(char *)name_text, name_len, "%.*s.%.*s-%d", LIT(proc->name), LIT(pd_name), guid);
						String name = make_string(name_text, name_len-1);


						irValue *value = ir_make_value_procedure(proc->module->allocator,
						                                           proc->module, e, e->type, pd->type, pd->body, name);

						value->Proc.tags = pd->tags;
						value->Proc.parent = proc;

						ir_module_add_value(proc->module, e, value);
						array_add(&proc->children, &value->Proc);
						array_add(&proc->module->procs_to_generate, value);
					} else {
						CheckerInfo *info = proc->module->info;

						// FFI - Foreign function interace
						String original_name = e->token.string;
						String name = original_name;
						if (pd->foreign_name.len > 0) {
							name = pd->foreign_name;
						}

						irValue *value = ir_make_value_procedure(proc->module->allocator,
						                                           proc->module, e, e->type, pd->type, pd->body, name);

						value->Proc.tags = pd->tags;

						ir_module_add_value(proc->module, e, value);
						ir_build_proc(value, proc);

						if (value->Proc.tags & ProcTag_foreign) {
							HashKey key = hash_string(name);
							irValue **prev_value = map_ir_value_get(&proc->module->members, key);
							if (prev_value == NULL) {
								// NOTE(bill): Don't do mutliple declarations in the IR
								map_ir_value_set(&proc->module->members, key, value);
							}
						} else {
							array_add(&proc->children, &value->Proc);
						}
					}
				} break;
				}
			}
		}
	case_end;

	case_ast_node(as, AssignStmt, node);
		ir_emit_comment(proc, str_lit("AssignStmt"));

		irModule *m = proc->module;
		gbTempArenaMemory tmp = gb_temp_arena_memory_begin(&m->tmp_arena);

		switch (as->op.kind) {
		case Token_Eq: {
			Array(irAddr) lvals;
			array_init(&lvals, m->tmp_allocator);

			for_array(i, as->lhs) {
				AstNode *lhs = as->lhs.e[i];
				irAddr lval = {0};
				if (!ir_is_blank_ident(lhs)) {
					lval = ir_build_addr(proc, lhs);
				}
				array_add(&lvals, lval);
			}

			if (as->lhs.count == as->rhs.count) {
				if (as->lhs.count == 1) {
					AstNode *rhs = as->rhs.e[0];
					irValue *init = ir_build_expr(proc, rhs);
					ir_addr_store(proc, lvals.e[0], init);
				} else {
					irValueArray inits;
					array_init_reserve(&inits, m->tmp_allocator, lvals.count);

					for_array(i, as->rhs) {
						irValue *init = ir_build_expr(proc, as->rhs.e[i]);
						array_add(&inits, init);
					}

					for_array(i, inits) {
						ir_addr_store(proc, lvals.e[i], inits.e[i]);
					}
				}
			} else {
				irValueArray inits;
				array_init_reserve(&inits, m->tmp_allocator, lvals.count);

				for_array(i, as->rhs) {
					irValue *init = ir_build_expr(proc, as->rhs.e[i]);
					Type *t = ir_type(init);
					// TODO(bill): refactor for code reuse as this is repeated a bit
					if (t->kind == Type_Tuple) {
						for (isize i = 0; i < t->Tuple.variable_count; i++) {
							Entity *e = t->Tuple.variables[i];
							irValue *v = ir_emit_struct_ev(proc, init, i);
							array_add(&inits, v);
						}
					} else {
						array_add(&inits, init);
					}
				}

				for_array(i, inits) {
					ir_addr_store(proc, lvals.e[i], inits.e[i]);
				}
			}

		} break;

		default: {
			// NOTE(bill): Only 1 += 1 is allowed, no tuples
			// +=, -=, etc
			i32 op = cast(i32)as->op.kind;
			op += Token_Add - Token_AddEq; // Convert += to +
			irAddr lhs = ir_build_addr(proc, as->lhs.e[0]);
			irValue *value = ir_build_expr(proc, as->rhs.e[0]);
			ir_build_assign_op(proc, lhs, value, cast(TokenKind)op);
		} break;
		}

		gb_temp_arena_memory_end(tmp);
	case_end;

	case_ast_node(es, ExprStmt, node);
		// NOTE(bill): No need to use return value
		ir_build_expr(proc, es->expr);
	case_end;

	case_ast_node(bs, BlockStmt, node);
		ir_open_scope(proc);
		ir_build_stmt_list(proc, bs->stmts);
		ir_close_scope(proc, irDeferExit_Default, NULL);
	case_end;

	case_ast_node(ds, DeferStmt, node);
		ir_emit_comment(proc, str_lit("DeferStmt"));
		isize scope_index = proc->scope_index;
		if (ds->stmt->kind == AstNode_BlockStmt) {
			scope_index--;
		}
		ir_add_defer_node(proc, scope_index, ds->stmt);
	case_end;

	case_ast_node(rs, ReturnStmt, node);
		ir_emit_comment(proc, str_lit("ReturnStmt"));
		irValue *v = NULL;
		TypeTuple *return_type_tuple  = &proc->type->Proc.results->Tuple;
		isize return_count = proc->type->Proc.result_count;
		if (return_count == 0) {
			// No return values
		} else if (return_count == 1) {
			Entity *e = return_type_tuple->variables[0];
			v = ir_build_expr(proc, rs->results.e[0]);
			v = ir_emit_conv(proc, v, e->type);
		} else {
			gbTempArenaMemory tmp = gb_temp_arena_memory_begin(&proc->module->tmp_arena);

			irValueArray results;
			array_init_reserve(&results, proc->module->tmp_allocator, return_count);

			for_array(res_index, rs->results) {
				irValue *res = ir_build_expr(proc, rs->results.e[res_index]);
				Type *t = ir_type(res);
				if (t->kind == Type_Tuple) {
					for (isize i = 0; i < t->Tuple.variable_count; i++) {
						Entity *e = t->Tuple.variables[i];
						irValue *v = ir_emit_struct_ev(proc, res, i);
						array_add(&results, v);
					}
				} else {
					array_add(&results, res);
				}
			}

			Type *ret_type = proc->type->Proc.results;
			v = ir_add_local_generated(proc, ret_type);
			for_array(i, results) {
				Entity *e = return_type_tuple->variables[i];
				irValue *res = ir_emit_conv(proc, results.e[i], e->type);
				irValue *field = ir_emit_struct_ep(proc, v, i);
				ir_emit_store(proc, field, res);
			}

			v = ir_emit_load(proc, v);

			gb_temp_arena_memory_end(tmp);
		}
		ir_emit_return(proc, v);

	case_end;

	case_ast_node(is, IfStmt, node);
		ir_emit_comment(proc, str_lit("IfStmt"));
		if (is->init != NULL) {
			irBlock *init = ir_add_block(proc, node, "if.init");
			ir_emit_jump(proc, init);
			proc->curr_block = init;
			ir_build_stmt(proc, is->init);
		}
		irBlock *then = ir_add_block(proc, node, "if.then");
		irBlock *done = ir_add_block(proc, node, "if.done"); // NOTE(bill): Append later
		irBlock *else_ = done;
		if (is->else_stmt != NULL) {
			else_ = ir_add_block(proc, is->else_stmt, "if.else");
		}

		ir_build_cond(proc, is->cond, then, else_);
		proc->curr_block = then;

		ir_open_scope(proc);
		ir_build_stmt(proc, is->body);
		ir_close_scope(proc, irDeferExit_Default, NULL);

		ir_emit_jump(proc, done);

		if (is->else_stmt != NULL) {
			proc->curr_block = else_;

			ir_open_scope(proc);
			ir_build_stmt(proc, is->else_stmt);
			ir_close_scope(proc, irDeferExit_Default, NULL);

			ir_emit_jump(proc, done);
		}
		proc->curr_block = done;
	case_end;

	case_ast_node(fs, ForStmt, node);
		ir_emit_comment(proc, str_lit("ForStmt"));
		if (fs->init != NULL) {
			irBlock *init = ir_add_block(proc, node, "for.init");
			ir_emit_jump(proc, init);
			proc->curr_block = init;
			ir_build_stmt(proc, fs->init);
		}
		irBlock *body = ir_add_block(proc, node, "for.body");
		irBlock *done = ir_add_block(proc, node, "for.done"); // NOTE(bill): Append later
		irBlock *loop = body;
		if (fs->cond != NULL) {
			loop = ir_add_block(proc, node, "for.loop");
		}
		irBlock *cont = loop;
		if (fs->post != NULL) {
			cont = ir_add_block(proc, node, "for.post");
		}
		ir_emit_jump(proc, loop);
		proc->curr_block = loop;

		if (loop != body) {
			ir_build_cond(proc, fs->cond, body, done);
			proc->curr_block = body;
		}

		ir_push_target_list(proc, done, cont, NULL);

		ir_open_scope(proc);
		ir_build_stmt(proc, fs->body);
		ir_close_scope(proc, irDeferExit_Default, NULL);

		ir_pop_target_list(proc);

		ir_emit_jump(proc, cont);

		if (fs->post != NULL) {
			proc->curr_block = cont;
			ir_build_stmt(proc, fs->post);
			ir_emit_jump(proc, loop);
		}

		proc->curr_block = done;
	case_end;


	case_ast_node(rs, RangeStmt, node);
		ir_emit_comment(proc, str_lit("RangeStmt"));

		Type *val_type = NULL;
		Type *idx_type = NULL;
		if (rs->value != NULL && !ir_is_blank_ident(rs->value)) {
			val_type = type_of_expr(proc->module->info, rs->value);
		}
		if (rs->index != NULL && !ir_is_blank_ident(rs->index)) {
			idx_type = type_of_expr(proc->module->info, rs->index);
		}

		if (val_type != NULL) {
			ir_add_local_for_identifier(proc, rs->value, true);
		}
		if (idx_type != NULL) {
			ir_add_local_for_identifier(proc, rs->index, true);
		}

		irValue *val = NULL;
		irValue *index = NULL;
		irBlock *loop = NULL;
		irBlock *done = NULL;

		if (rs->expr->kind == AstNode_IntervalExpr) {
			ir_build_range_interval(proc, &rs->expr->IntervalExpr, val_type, &val, &index, &loop, &done);
		} else {
			Type *expr_type = type_of_expr(proc->module->info, rs->expr);
			Type *et = base_type(type_deref(expr_type));
			switch (et->kind) {
			case Type_Array: {
				irValue *count_ptr = NULL;
				irValue *array = ir_build_addr(proc, rs->expr).addr;
				if (is_type_pointer(type_deref(ir_type(array)))) {
					array = ir_emit_load(proc, array);
				}
				count_ptr = ir_add_local_generated(proc, t_int);
				ir_emit_store(proc, count_ptr, ir_make_const_int(proc->module->allocator, et->Array.count));
				ir_build_range_indexed(proc, array, val_type, count_ptr, &val, &index, &loop, &done);
			} break;
			case Type_DynamicArray: {
				irValue *count_ptr = NULL;
				irValue *array = ir_build_expr(proc, rs->expr);
				if (is_type_pointer(type_deref(ir_type(array)))) {
					count_ptr = ir_emit_struct_ep(proc, array, 1);
					array = ir_emit_load(proc, array);
				}  else {
					count_ptr = ir_add_local_generated(proc, t_int);
					ir_emit_store(proc, count_ptr, ir_dynamic_array_count(proc, array));
				}
				ir_build_range_indexed(proc, array, val_type, count_ptr, &val, &index, &loop, &done);
			} break;
			case Type_Slice: {
				irValue *count_ptr = NULL;
				irValue *slice = ir_build_expr(proc, rs->expr);
				if (is_type_pointer(ir_type(slice))) {
					count_ptr = ir_emit_struct_ep(proc, slice, 1);
					slice = ir_emit_load(proc, slice);
				} else {
					count_ptr = ir_add_local_generated(proc, t_int);
					ir_emit_store(proc, count_ptr, ir_slice_count(proc, slice));
				}
				ir_build_range_indexed(proc, slice, val_type, count_ptr, &val, &index, &loop, &done);
			} break;
			case Type_Basic: {
				irValue *string = ir_build_expr(proc, rs->expr);
				if (is_type_pointer(ir_type(string))) {
					string = ir_emit_load(proc, string);
				}
				if (is_type_untyped(expr_type)) {
					irValue *s = ir_add_local_generated(proc, t_string);
					ir_emit_store(proc, s, string);
					string = ir_emit_load(proc, s);
				}
				ir_build_range_string(proc, string, val_type, &val, &index, &loop, &done);
			} break;
			default:
				GB_PANIC("Cannot range over %s", type_to_string(expr_type));
				break;
			}
		}

		irAddr val_addr = {0};
		irAddr idx_addr = {0};
		if (val_type != NULL) {
			val_addr = ir_build_addr(proc, rs->value);
		}
		if (idx_type != NULL) {
			idx_addr = ir_build_addr(proc, rs->index);
		}
		if (val_type != NULL) {
			ir_addr_store(proc, val_addr, val);
		}
		if (idx_type != NULL) {
			ir_addr_store(proc, idx_addr, index);
		}

		ir_push_target_list(proc, done, loop, NULL);

		ir_open_scope(proc);
		ir_build_stmt(proc, rs->body);
		ir_close_scope(proc, irDeferExit_Default, NULL);

		ir_pop_target_list(proc);
		ir_emit_jump(proc, loop);
		proc->curr_block = done;
	case_end;

	case_ast_node(ms, MatchStmt, node);
		ir_emit_comment(proc, str_lit("MatchStmt"));
		if (ms->init != NULL) {
			ir_build_stmt(proc, ms->init);
		}
		irValue *tag = v_true;
		if (ms->tag != NULL) {
			tag = ir_build_expr(proc, ms->tag);
		}
		irBlock *done = ir_add_block(proc, node, "match.done"); // NOTE(bill): Append later

		ast_node(body, BlockStmt, ms->body);

		AstNodeArray default_stmts = {0};
		irBlock *default_fall = NULL;
		irBlock *default_block = NULL;

		irBlock *fall = NULL;
		bool append_fall = false;

		isize case_count = body->stmts.count;
		for_array(i, body->stmts) {
			AstNode *clause = body->stmts.e[i];
			irBlock *body = fall;

			ast_node(cc, CaseClause, clause);

			if (body == NULL) {
				if (cc->list.count == 0) {
					body = ir_add_block(proc, clause, "match.dflt.body");
				} else {
					body = ir_add_block(proc, clause, "match.case.body");
				}
			}
			if (append_fall && body == fall) {
				append_fall = false;
			}

			fall = done;
			if (i+1 < case_count) {
				append_fall = true;
				fall = ir_add_block(proc, clause, "match.fall.body");
			}

			if (cc->list.count == 0) {
				// default case
				default_stmts = cc->stmts;
				default_fall  = fall;
				default_block = body;
				continue;
			}

			irBlock *next_cond = NULL;
			for_array(j, cc->list) {
				AstNode *expr = cc->list.e[j];
				next_cond = ir_add_block(proc, clause, "match.case.next");

				irValue *cond = ir_emit_comp(proc, Token_CmpEq, tag, ir_build_expr(proc, expr));
				ir_emit_if(proc, cond, body, next_cond);
				proc->curr_block = next_cond;
			}
			proc->curr_block = body;

			ir_push_target_list(proc, done, NULL, fall);
			ir_open_scope(proc);
			ir_build_stmt_list(proc, cc->stmts);
			ir_close_scope(proc, irDeferExit_Default, body);
			ir_pop_target_list(proc);

			ir_emit_jump(proc, done);
			proc->curr_block = next_cond;
		}

		if (default_block != NULL) {
			ir_emit_jump(proc, default_block);
			proc->curr_block = default_block;

			ir_push_target_list(proc, done, NULL, default_fall);
			ir_open_scope(proc);
			ir_build_stmt_list(proc, default_stmts);
			ir_close_scope(proc, irDeferExit_Default, default_block);
			ir_pop_target_list(proc);
		}

		ir_emit_jump(proc, done);
		proc->curr_block = done;
	case_end;


	case_ast_node(ms, TypeMatchStmt, node);
		ir_emit_comment(proc, str_lit("TypeMatchStmt"));
		gbAllocator allocator = proc->module->allocator;

		irValue *parent = ir_build_expr(proc, ms->tag);
		bool is_union_ptr = false;
		bool is_any = false;
		GB_ASSERT(check_valid_type_match_type(ir_type(parent), &is_union_ptr, &is_any));

		irValue *tag_index = NULL;
		irValue *union_data = NULL;
		if (is_union_ptr) {
			ir_emit_comment(proc, str_lit("get union's tag"));
			tag_index = ir_emit_load(proc, ir_emit_union_tag_ptr(proc, parent));
			union_data = ir_emit_conv(proc, parent, t_rawptr);
		}

		irBlock *start_block = ir_add_block(proc, node, "type-match.case.first");
		ir_emit_jump(proc, start_block);
		proc->curr_block = start_block;

		irBlock *done = ir_add_block(proc, node, "type-match.done"); // NOTE(bill): Append later

		ast_node(body, BlockStmt, ms->body);

		String tag_var_name = ms->var->Ident.string;

		AstNodeArray default_stmts = {0};
		irBlock *default_block = NULL;


		isize case_count = body->stmts.count;
		for_array(i, body->stmts) {
			AstNode *clause = body->stmts.e[i];
			ast_node(cc, CaseClause, clause);

			if (cc->list.count == 0) {
				// default case
				default_stmts = cc->stmts;
				default_block = ir_add_block(proc, clause, "type-match.dflt.body");
				continue;
			}


			irBlock *body = ir_add_block(proc, clause, "type-match.case.body");

			Scope *scope = *map_scope_get(&proc->module->info->scopes, hash_pointer(clause));
			Entity *tag_var_entity = current_scope_lookup_entity(scope, tag_var_name);
			GB_ASSERT_MSG(tag_var_entity != NULL, "%.*s", LIT(tag_var_name));

			irBlock *next_cond = NULL;
			irValue *cond = NULL;

			if (is_union_ptr) {
				Type *bt = type_deref(tag_var_entity->type);
				irValue *index = NULL;
				Type *ut = base_type(type_deref(ir_type(parent)));
				GB_ASSERT(ut->Record.kind == TypeRecord_Union);
				for (isize field_index = 1; field_index < ut->Record.field_count; field_index++) {
					Entity *f = ut->Record.fields[field_index];
					if (are_types_identical(f->type, bt)) {
						index = ir_make_const_int(allocator, field_index);
						break;
					}
				}
				GB_ASSERT(index != NULL);

				irValue *tag_var = ir_add_local(proc, tag_var_entity);
				irValue *data_ptr = ir_emit_conv(proc, union_data, tag_var_entity->type);
				ir_emit_store(proc, tag_var, data_ptr);

				cond = ir_emit_comp(proc, Token_CmpEq, tag_index, index);
			} else if (is_any) {
				Type *type = tag_var_entity->type;
				irValue *any_data = ir_emit_struct_ev(proc, parent, 1);
				irValue *data = ir_emit_conv(proc, any_data, make_type_pointer(proc->module->allocator, type));
				ir_module_add_value(proc->module, tag_var_entity, data);

				irValue *any_ti  = ir_emit_struct_ev(proc, parent, 0);
				irValue *case_ti = ir_type_info(proc, type);
				cond = ir_emit_comp(proc, Token_CmpEq, any_ti, case_ti);
			} else {
				GB_PANIC("Invalid type for type match statement");
			}

			next_cond = ir_add_block(proc, clause, "type-match.case.next");
			ir_emit_if(proc, cond, body, next_cond);
			proc->curr_block = next_cond;

			proc->curr_block = body;

			ir_push_target_list(proc, done, NULL, NULL);
			ir_open_scope(proc);
			ir_build_stmt_list(proc, cc->stmts);
			ir_close_scope(proc, irDeferExit_Default, body);
			ir_pop_target_list(proc);

			ir_emit_jump(proc, done);
			proc->curr_block = next_cond;
		}

		if (default_block != NULL) {
			ir_emit_jump(proc, default_block);
			proc->curr_block = default_block;

			ir_push_target_list(proc, done, NULL, NULL);
			ir_open_scope(proc);
			ir_build_stmt_list(proc, default_stmts);
			ir_close_scope(proc, irDeferExit_Default, default_block);
			ir_pop_target_list(proc);
		}

		ir_emit_jump(proc, done);
		proc->curr_block = done;
	case_end;

	case_ast_node(bs, BranchStmt, node);
		irBlock *block = NULL;
		switch (bs->token.kind) {
		case Token_break:
			for (irTargetList *t = proc->target_list; t != NULL && block == NULL; t = t->prev) {
				block = t->break_;
			}
			break;
		case Token_continue:
			for (irTargetList *t = proc->target_list; t != NULL && block == NULL; t = t->prev) {
				block = t->continue_;
			}
			break;
		case Token_fallthrough:
			for (irTargetList *t = proc->target_list; t != NULL && block == NULL; t = t->prev) {
				block = t->fallthrough_;
			}
			break;
		}
		if (block != NULL) {
			ir_emit_defer_stmts(proc, irDeferExit_Branch, block);
		}
		switch (bs->token.kind) {
		case Token_break:       ir_emit_comment(proc, str_lit("break"));       break;
		case Token_continue:    ir_emit_comment(proc, str_lit("continue"));    break;
		case Token_fallthrough: ir_emit_comment(proc, str_lit("fallthrough")); break;
		}
		ir_emit_jump(proc, block);
		ir_emit_unreachable(proc);
	case_end;



	case_ast_node(pa, PushAllocator, node);
		ir_emit_comment(proc, str_lit("PushAllocator"));
		ir_open_scope(proc);

		irValue *context_ptr = ir_find_implicit_value_backing(proc, ImplicitValue_context);
		irValue *prev_context = ir_add_local_generated(proc, t_context);
		ir_emit_store(proc, prev_context, ir_emit_load(proc, context_ptr));

		ir_add_defer_instr(proc, proc->scope_index, ir_make_instr_store(proc, context_ptr, ir_emit_load(proc, prev_context)));

		irValue *gep = ir_emit_struct_ep(proc, context_ptr, 1);
		ir_emit_store(proc, gep, ir_build_expr(proc, pa->expr));

		ir_build_stmt(proc, pa->body);

		ir_close_scope(proc, irDeferExit_Default, NULL);
	case_end;


	case_ast_node(pa, PushContext, node);
		ir_emit_comment(proc, str_lit("PushContext"));
		ir_open_scope(proc);

		irValue *context_ptr = ir_find_implicit_value_backing(proc, ImplicitValue_context);
		irValue *prev_context = ir_add_local_generated(proc, t_context);
		ir_emit_store(proc, prev_context, ir_emit_load(proc, context_ptr));

		ir_add_defer_instr(proc, proc->scope_index, ir_make_instr_store(proc, context_ptr, ir_emit_load(proc, prev_context)));

		ir_emit_store(proc, context_ptr, ir_build_expr(proc, pa->expr));

		ir_build_stmt(proc, pa->body);

		ir_close_scope(proc, irDeferExit_Default, NULL);
	case_end;


	}
}







////////////////////////////////////////////////////////////////
//
// @Procedure
//
////////////////////////////////////////////////////////////////

void ir_number_proc_registers(irProcedure *proc) {
	i32 reg_index = 0;
	for_array(i, proc->blocks) {
		irBlock *b = proc->blocks.e[i];
		b->index = i;
		for_array(j, b->instrs) {
			irValue *value = b->instrs.e[j];
			GB_ASSERT(value->kind == irValue_Instr);
			irInstr *instr = &value->Instr;
			if (ir_instr_type(instr) == NULL) { // NOTE(bill): Ignore non-returning instructions
				continue;
			}
			value->index = reg_index;
			reg_index++;
		}
	}
}

void ir_begin_procedure_body(irProcedure *proc) {
	array_add(&proc->module->procs, proc);

	array_init(&proc->blocks,      heap_allocator());
	array_init(&proc->defer_stmts, heap_allocator());
	array_init(&proc->children,    heap_allocator());

	proc->decl_block  = ir_add_block(proc, proc->type_expr, "decls");
	proc->entry_block = ir_add_block(proc, proc->type_expr, "entry");
	proc->curr_block  = proc->entry_block;

	if (proc->type->Proc.params != NULL) {
		TypeTuple *params = &proc->type->Proc.params->Tuple;
		for (isize i = 0; i < params->variable_count; i++) {
			Entity *e = params->variables[i];
			if (!str_eq(e->token.string, str_lit("")) &&
			    !str_eq(e->token.string, str_lit("_"))) {
				irValue *param = ir_add_param(proc, e);
				array_add(&proc->params, param);
			}
		}
	}
}


void ir_end_procedure_body(irProcedure *proc) {
	if (proc->type->Proc.result_count == 0) {
		ir_emit_return(proc, NULL);
	}

	if (proc->curr_block->instrs.count == 0) {
		ir_emit_unreachable(proc);
	}

	proc->curr_block = proc->decl_block;
	ir_emit_jump(proc, proc->entry_block);

	ir_number_proc_registers(proc);
}


void ir_insert_code_before_proc(irProcedure* proc, irProcedure *parent) {
	if (parent == NULL) {
		if (str_eq(proc->name, str_lit("main"))) {
			ir_emit_startup_runtime(proc);
		}
	}
}

void ir_build_proc(irValue *value, irProcedure *parent) {
	irProcedure *proc = &value->Proc;

	proc->parent = parent;

	if (proc->entity != NULL) {
		irModule *m = proc->module;
		CheckerInfo *info = m->info;
		Entity *e = proc->entity;
		String filename = e->token.pos.file;
		AstFile **found = map_ast_file_get(&info->files, hash_string(filename));
		GB_ASSERT(found != NULL);
		AstFile *f = *found;
		irDebugInfo *di_file = NULL;

		irDebugInfo **di_file_found = map_ir_debug_info_get(&m->debug_info, hash_pointer(f));
		if (di_file_found) {
			di_file = *di_file_found;
			GB_ASSERT(di_file->kind == irDebugInfo_File);
		} else {
			di_file = ir_add_debug_info_file(proc, f);
		}

		ir_add_debug_info_proc(proc, e, proc->name, di_file);
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


		ir_begin_procedure_body(proc);
		ir_insert_code_before_proc(proc, parent);
		ir_build_stmt(proc, proc->body);
		ir_end_procedure_body(proc);

		proc->module->stmt_state_flags = prev_stmt_state_flags;
	}
}







////////////////////////////////////////////////////////////////
//
// @Module
//
////////////////////////////////////////////////////////////////



void ir_module_add_value(irModule *m, Entity *e, irValue *v) {
	map_ir_value_set(&m->values, hash_pointer(e), v);
}

void ir_init_module(irModule *m, Checker *c, BuildContext *build_context) {
	// TODO(bill): Determine a decent size for the arena
	isize token_count = c->parser->total_token_count;
	isize arena_size = 4 * token_count * gb_size_of(irValue);
	gb_arena_init_from_allocator(&m->arena, heap_allocator(), arena_size);
	gb_arena_init_from_allocator(&m->tmp_arena, heap_allocator(), arena_size);
	m->allocator     = gb_arena_allocator(&m->arena);
	m->tmp_allocator = gb_arena_allocator(&m->tmp_arena);
	m->info = &c->info;
	m->sizes = c->sizes;
	m->build_context = build_context;

	map_ir_value_init(&m->values,  heap_allocator());
	map_ir_value_init(&m->members, heap_allocator());
	map_ir_debug_info_init(&m->debug_info, heap_allocator());
	map_string_init(&m->type_names, heap_allocator());
	array_init(&m->procs,    heap_allocator());
	array_init(&m->procs_to_generate, heap_allocator());
	array_init(&m->foreign_library_paths, heap_allocator());

	// Default states
	m->stmt_state_flags = 0;
	m->stmt_state_flags |= StmtStateFlag_bounds_check;

	{
		// Add type info data
		{
			String name = str_lit(IR_TYPE_INFO_DATA_NAME);
			isize count = c->info.type_info_map.entries.count;
			Entity *e = make_entity_variable(m->allocator, NULL, make_token_ident(name), make_type_array(m->allocator, t_type_info, count), false);
			irValue *g = ir_make_value_global(m->allocator, e, NULL);
			g->Global.is_private  = true;
			ir_module_add_value(m, e, g);
			map_ir_value_set(&m->members, hash_string(name), g);
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

			String name = str_lit(IR_TYPE_INFO_DATA_MEMBER_NAME);
			Entity *e = make_entity_variable(m->allocator, NULL, make_token_ident(name),
			                                 make_type_array(m->allocator, t_type_info_member, count), false);
			irValue *g = ir_make_value_global(m->allocator, e, NULL);
			ir_module_add_value(m, e, g);
			map_ir_value_set(&m->members, hash_string(name), g);
		}
	}

	{
		irDebugInfo *di = ir_alloc_debug_info(m->allocator, irDebugInfo_CompileUnit);
		di->CompileUnit.file = m->info->files.entries.e[0].value; // Zeroth is the init file
		di->CompileUnit.producer = str_lit("odin");

		map_ir_debug_info_set(&m->debug_info, hash_pointer(m), di);
	}
}

void ir_destroy_module(irModule *m) {
	map_ir_value_destroy(&m->values);
	map_ir_value_destroy(&m->members);
	map_string_destroy(&m->type_names);
	map_ir_debug_info_destroy(&m->debug_info);
	array_free(&m->procs);
	array_free(&m->procs_to_generate);
	array_free(&m->foreign_library_paths);
	gb_arena_free(&m->arena);
}



////////////////////////////////////////////////////////////////
//
// @Code Generation
//
////////////////////////////////////////////////////////////////


bool ir_gen_init(irGen *s, Checker *c, BuildContext *build_context) {
	if (global_error_collector.count != 0) {
		return false;
	}

	isize tc = c->parser->total_token_count;
	if (tc < 2) {
		return false;
	}

	ir_init_module(&s->module, c, build_context);
	s->module.generate_debug_info = false;

	// TODO(bill): generate appropriate output name
	int pos = cast(int)string_extension_position(c->parser->init_fullpath);
	gbFileError err = gb_file_create(&s->output_file, gb_bprintf("%.*s.ll", pos, c->parser->init_fullpath.text));
	if (err != gbFileError_None) {
		return false;
	}

	return true;
}

void ir_gen_destroy(irGen *s) {
	ir_destroy_module(&s->module);
	gb_file_close(&s->output_file);
}

String ir_mangle_name(irGen *s, String path, Entity *e) {
	// NOTE(bill): prefix names not in the init scope
	// TODO(bill): make robust and not just rely on the file's name
	String name = e->token.string;
	irModule *m = &s->module;
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
	bool is_overloaded = check_is_entity_overloaded(e);
	if (is_overloaded) {
		max_len += 21;
	}

	u8 *new_name = gb_alloc_array(a, u8, max_len);
	isize new_name_len = gb_snprintf(
		cast(char *)new_name, max_len,
		"%.*s-%u.%.*s",
		cast(int)base_len, base,
		file->id,
		LIT(name));
	if (is_overloaded) {
		char *str = cast(char *)new_name + new_name_len-1;
		isize len = max_len-new_name_len;
		isize extra = gb_snprintf(str, len, "-%tu", cast(usize)cast(uintptr)e);
		new_name_len += extra-1;
	}

	return make_string(new_name, new_name_len-1);
}

irValue *ir_get_type_info_ptr(irProcedure *proc, irValue *type_info_data, Type *type) {
	i32 index = cast(i32)ir_type_info_index(proc->module->info, type);
	// gb_printf_err("%d %s\n", index, type_to_string(type));
	irValue *ptr = ir_emit_array_epi(proc, type_info_data, index);
	return ir_emit_bitcast(proc, ptr, t_type_info_ptr);
}

irValue *ir_type_info_member_offset(irProcedure *proc, irValue *data, isize count, i32 *index) {
	irValue *offset = ir_emit_array_epi(proc, data, *index);
	*index += count;
	return offset;
}

void ir_add_foreign_library_path(irModule *m, Entity *e) {
	GB_ASSERT(e != NULL);
	String library_path = e->LibraryName.path;
	if (library_path.len == 0) {
		return;
	}

	for_array(path_index, m->foreign_library_paths) {
		String path = m->foreign_library_paths.e[path_index];
#if defined(GB_SYSTEM_WINDOWS)
		if (str_eq_ignore_case(path, library_path)) {
#else
		if (str_eq(path, library_path)) {
#endif
			return;
		}
	}
	array_add(&m->foreign_library_paths, library_path);
}

void ir_gen_tree(irGen *s) {
	irModule *m = &s->module;
	CheckerInfo *info = m->info;
	gbAllocator a = m->allocator;

	if (v_zero == NULL) {
		v_zero   = ir_make_const_int (m->allocator, 0);
		v_one    = ir_make_const_int (m->allocator, 1);
		v_zero32 = ir_make_const_i32 (m->allocator, 0);
		v_one32  = ir_make_const_i32 (m->allocator, 1);
		v_two32  = ir_make_const_i32 (m->allocator, 2);
		v_false  = ir_make_const_bool(m->allocator, false);
		v_true   = ir_make_const_bool(m->allocator, true);
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

	typedef struct irGlobalVariable {
		irValue *var, *init;
		DeclInfo *decl;
	} irGlobalVariable;
	Array(irGlobalVariable) global_variables;
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
				name = ir_mangle_name(s, e->token.pos.file, e);
			}
		}


		switch (e->kind) {
		case Entity_TypeName:
			GB_ASSERT(e->type->kind == Type_Named);
			map_string_set(&m->type_names, hash_pointer(e->type), name);
			ir_gen_global_type_name(m, e, name);
			break;

		case Entity_Variable: {
			irValue *g = ir_make_value_global(a, e, NULL);
			g->Global.is_thread_local = e->Variable.is_thread_local;

			irGlobalVariable var = {0};
			var.var = g;
			var.decl = decl;

			if (decl->init_expr != NULL) {
				TypeAndValue *tav = map_tav_get(&info->types, hash_pointer(decl->init_expr));
				if (tav != NULL) {
					if (tav->value.kind != ExactValue_Invalid) {
						ExactValue v = tav->value;
						// if (v.kind != ExactValue_String) {
							g->Global.value = ir_add_module_constant(m, tav->type, v);
						// }
					}
				}
			}

			if (g->Global.value == NULL) {
				array_add(&global_variables, var);
			}

			ir_module_add_value(m, e, g);
			map_ir_value_set(&m->members, hash_string(name), g);
		} break;

		case Entity_Procedure: {
			ast_node(pd, ProcLit, decl->proc_lit);
			String original_name = name;
			AstNode *body = pd->body;
			if (e->Procedure.is_foreign) {
				name = e->token.string; // NOTE(bill): Don't use the mangled name
				ir_add_foreign_library_path(m, e->Procedure.foreign_library);
			}
			if (pd->foreign_name.len > 0) {
				name = pd->foreign_name;
			} else if (pd->link_name.len > 0) {
				name = pd->link_name;
			}

			irValue *p = ir_make_value_procedure(a, m, e, e->type, decl->type_expr, body, name);
			p->Proc.tags = pd->tags;

			ir_module_add_value(m, e, p);
			HashKey hash_name = hash_string(name);
			if (map_ir_value_get(&m->members, hash_name) == NULL) {
				map_ir_value_multi_insert(&m->members, hash_name, p);
			}
		} break;
		}
	}

	for_array(i, m->members.entries) {
		MapIrValueEntry *entry = &m->members.entries.e[i];
		irValue *v = entry->value;
		if (v->kind == irValue_Proc) {
			ir_build_proc(v, NULL);
		}
	}

	irDebugInfo *compile_unit = m->debug_info.entries.e[0].value;
	GB_ASSERT(compile_unit->kind == irDebugInfo_CompileUnit);
	irDebugInfo *all_procs = ir_alloc_debug_info(m->allocator, irDebugInfo_AllProcs);

	isize all_proc_max_count = 0;
	for_array(i, m->debug_info.entries) {
		MapIrDebugInfoEntry *entry = &m->debug_info.entries.e[i];
		irDebugInfo *di = entry->value;
		di->id = i;
		if (di->kind == irDebugInfo_Proc) {
			all_proc_max_count++;
		}
	}

	array_init_reserve(&all_procs->AllProcs.procs, m->allocator, all_proc_max_count);
	map_ir_debug_info_set(&m->debug_info, hash_pointer(all_procs), all_procs); // NOTE(bill): This doesn't need to be mapped
	compile_unit->CompileUnit.all_procs = all_procs;


	for_array(i, m->debug_info.entries) {
		MapIrDebugInfoEntry *entry = &m->debug_info.entries.e[i];
		irDebugInfo *di = entry->value;
		di->id = i;
		if (di->kind == irDebugInfo_Proc) {
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

		proc_params->Tuple.variables[0] = make_entity_param(a, proc_scope, blank_token, t_rawptr, false, false);
		proc_params->Tuple.variables[1] = make_entity_param(a, proc_scope, make_token_ident(str_lit("reason")), t_i32, false, false);
		proc_params->Tuple.variables[2] = make_entity_param(a, proc_scope, blank_token, t_rawptr, false, false);

		proc_results->Tuple.variables[0] = make_entity_param(a, proc_scope, empty_token, t_i32, false, false);


		Type *proc_type = make_type_proc(a, proc_scope,
		                                 proc_params, 3,
		                                 proc_results, 1, false, ProcCC_Std);

		AstNode *body = gb_alloc_item(a, AstNode);
		Entity *e = make_entity_procedure(a, NULL, make_token_ident(name), proc_type, 0);
		irValue *p = ir_make_value_procedure(a, m, e, proc_type, NULL, body, name);

		map_ir_value_set(&m->values, hash_pointer(e), p);
		map_ir_value_set(&m->members, hash_string(name), p);

		irProcedure *proc = &p->Proc;
		proc->tags = ProcTag_no_inline; // TODO(bill): is no_inline a good idea?
		e->Procedure.link_name = name;

		ir_begin_procedure_body(proc);

		// NOTE(bill): https://msdn.microsoft.com/en-us/library/windows/desktop/ms682583(v=vs.85).aspx
		// DLL_PROCESS_ATTACH == 1

		irAddr reason_addr = ir_build_addr_from_entity(proc, proc_params->Tuple.variables[1], NULL);
		irValue *cond = ir_emit_comp(proc, Token_CmpEq, ir_addr_load(proc, reason_addr), v_one32);
		irBlock *then = ir_add_block(proc, NULL, "if.then");
		irBlock *done = ir_add_block(proc, NULL, "if.done"); // NOTE(bill): Append later
		ir_emit_if(proc, cond, then, done);
		proc->curr_block = then;
		ir_emit_global_call(proc, "main", NULL, 0);
		ir_emit_jump(proc, done);
		proc->curr_block = done;

		ir_emit_return(proc, v_one32);


		ir_end_procedure_body(proc);
	}
#endif
#if 0 && defined(GB_SYSTEM_WINDOWS)
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
		                                 proc_results, 1, false, ProcCC_Std);

		AstNode *body = gb_alloc_item(a, AstNode);
		Entity *e = make_entity_procedure(a, NULL, make_token_ident(name), proc_type, 0);
		irValue *p = ir_make_value_procedure(a, m, e, proc_type, NULL, body, name);

		m->entry_point_entity = e;

		map_ir_value_set(&m->values, hash_pointer(e), p);
		map_ir_value_set(&m->members, hash_string(name), p);

		irProcedure *proc = &p->Proc;
		proc->tags = ProcTag_no_inline; // TODO(bill): is no_inline a good idea?
		e->Procedure.link_name = name;

		ir_begin_procedure_body(proc);
		ir_emit_global_call(proc, "main", NULL, 0);
		ir_emit_return(proc, v_one32);
		ir_end_procedure_body(proc);
	}
#endif
	{ // Startup Runtime
		// Cleanup(bill): probably better way of doing code insertion
		String name = str_lit(IR_STARTUP_RUNTIME_PROC_NAME);
		Type *proc_type = make_type_proc(a, gb_alloc_item(a, Scope),
		                                 NULL, 0,
		                                 NULL, 0, false, ProcCC_Odin);
		AstNode *body = gb_alloc_item(a, AstNode);
		Entity *e = make_entity_procedure(a, NULL, make_token_ident(name), proc_type, 0);
		irValue *p = ir_make_value_procedure(a, m, e, proc_type, NULL, body, name);

		map_ir_value_set(&m->values, hash_pointer(e), p);
		map_ir_value_set(&m->members, hash_string(name), p);


		irProcedure *proc = &p->Proc;
		proc->tags = ProcTag_no_inline; // TODO(bill): is no_inline a good idea?

		ir_begin_procedure_body(proc);

		// TODO(bill): Should do a dependency graph do check which order to initialize them in?
		for_array(i, global_variables) {
			irGlobalVariable *var = &global_variables.e[i];
			if (var->decl->init_expr != NULL) {
				var->init = ir_build_expr(proc, var->decl->init_expr);
			}
		}

		// NOTE(bill): Initialize constants first
		for_array(i, global_variables) {
			irGlobalVariable *var = &global_variables.e[i];
			if (var->init != NULL) {
				if (var->init->kind == irValue_Constant) {
					ir_emit_store(proc, var->var, var->init);
				}
			}
		}

		for_array(i, global_variables) {
			irGlobalVariable *var = &global_variables.e[i];
			if (var->init != NULL) {
				if (var->init->kind != irValue_Constant) {
					ir_emit_store(proc, var->var, var->init);
				}
			}
		}

		{ // NOTE(bill): Setup type_info data
			// TODO(bill): Try and make a lot of this constant aggregate literals in LLVM IR
			irValue *type_info_data = NULL;
			irValue *type_info_member_data = NULL;

			irValue **found = NULL;
			found = map_ir_value_get(&proc->module->members, hash_string(str_lit(IR_TYPE_INFO_DATA_NAME)));
			GB_ASSERT(found != NULL);
			type_info_data = *found;

			found = map_ir_value_get(&proc->module->members, hash_string(str_lit(IR_TYPE_INFO_DATA_MEMBER_NAME)));
			GB_ASSERT(found != NULL);
			type_info_member_data = *found;

			CheckerInfo *info = proc->module->info;

			if (false) {
				irValue *global_type_infos = ir_find_global_variable(proc, str_lit("__type_infos"));
				Type *type = base_type(type_deref(ir_type(type_info_data)));
				GB_ASSERT(is_type_array(type));
				irValue *array_data  = ir_emit_array_epi(proc, type_info_data, 0);
				irValue *array_count = ir_make_const_int(proc->module->allocator, type->Array.count);

				ir_emit_store(proc, ir_emit_struct_ep(proc, global_type_infos, 0), array_data);
				ir_emit_store(proc, ir_emit_struct_ep(proc, global_type_infos, 1), array_count);
			}


			// Useful types
			Type *t_i64_slice_ptr    = make_type_pointer(a, make_type_slice(a, t_i64));
			Type *t_string_slice_ptr = make_type_pointer(a, make_type_slice(a, t_string));

			i32 type_info_member_index = 0;

			for_array(type_info_map_index, info->type_info_map.entries) {
				MapIsizeEntry *entry = &info->type_info_map.entries.e[type_info_map_index];
				Type *t = cast(Type *)cast(uintptr)entry->key.key;
				t = default_type(t);
				isize entry_index = entry->value;

				irValue *tag = NULL;
				irValue *ti_ptr = ir_emit_array_epi(proc, type_info_data, entry_index);

				switch (t->kind) {
				case Type_Named: {
					tag = ir_emit_conv(proc, ti_ptr, t_type_info_named_ptr);

					// TODO(bill): Which is better? The mangled name or actual name?
					irValue *name = ir_make_const_string(a, t->Named.type_name->token.string);
					irValue *gtip = ir_get_type_info_ptr(proc, type_info_data, t->Named.base);

					ir_emit_store(proc, ir_emit_struct_ep(proc, tag, 0), name);
					ir_emit_store(proc, ir_emit_struct_ep(proc, tag, 1), gtip);
				} break;

				case Type_Basic:
					switch (t->Basic.kind) {
					case Basic_bool:
						tag = ir_emit_conv(proc, ti_ptr, t_type_info_boolean_ptr);
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
						tag = ir_emit_conv(proc, ti_ptr, t_type_info_integer_ptr);
						bool is_unsigned = (t->Basic.flags & BasicFlag_Unsigned) != 0;
						irValue *bits = ir_make_const_int(a, type_size_of(m->sizes, a, t));
						irValue *is_signed = ir_make_const_bool(a, !is_unsigned);
						ir_emit_store(proc, ir_emit_struct_ep(proc, tag, 0), bits);
						ir_emit_store(proc, ir_emit_struct_ep(proc, tag, 1), is_signed);
					} break;

					// case Basic_f16:
					case Basic_f32:
					case Basic_f64:
					// case Basic_f128:
					{
						tag = ir_emit_conv(proc, ti_ptr, t_type_info_float_ptr);
						irValue *bits = ir_make_const_int(a, type_size_of(m->sizes, a, t));
						ir_emit_store(proc, ir_emit_struct_ep(proc, tag, 0), bits);
					} break;

					case Basic_rawptr:
						tag = ir_emit_conv(proc, ti_ptr, t_type_info_pointer_ptr);
						break;

					case Basic_string:
						tag = ir_emit_conv(proc, ti_ptr, t_type_info_string_ptr);
						break;

					case Basic_any:
						tag = ir_emit_conv(proc, ti_ptr, t_type_info_any_ptr);
						break;
					}
					break;

				case Type_Pointer: {
					tag = ir_emit_conv(proc, ti_ptr, t_type_info_pointer_ptr);
					irValue *gep = ir_get_type_info_ptr(proc, type_info_data, t->Pointer.elem);
					ir_emit_store(proc, ir_emit_struct_ep(proc, tag, 0), gep);
				} break;
				case Type_Maybe: {
					tag = ir_emit_conv(proc, ti_ptr, t_type_info_maybe_ptr);
					irValue *gep = ir_get_type_info_ptr(proc, type_info_data, t->Maybe.elem);
					ir_emit_store(proc, ir_emit_struct_ep(proc, tag, 0), gep);
				} break;
				case Type_Array: {
					tag = ir_emit_conv(proc, ti_ptr, t_type_info_array_ptr);
					irValue *gep = ir_get_type_info_ptr(proc, type_info_data, t->Array.elem);
					ir_emit_store(proc, ir_emit_struct_ep(proc, tag, 0), gep);

					isize ez = type_size_of(m->sizes, a, t->Array.elem);
					irValue *elem_size = ir_emit_struct_ep(proc, tag, 1);
					ir_emit_store(proc, elem_size, ir_make_const_int(a, ez));

					irValue *count = ir_emit_struct_ep(proc, tag, 2);
					ir_emit_store(proc, count, ir_make_const_int(a, t->Array.count));

				} break;
				case Type_Slice: {
					tag = ir_emit_conv(proc, ti_ptr, t_type_info_slice_ptr);
					irValue *gep = ir_get_type_info_ptr(proc, type_info_data, t->Slice.elem);
					ir_emit_store(proc, ir_emit_struct_ep(proc, tag, 0), gep);

					isize ez = type_size_of(m->sizes, a, t->Slice.elem);
					irValue *elem_size = ir_emit_struct_ep(proc, tag, 1);
					ir_emit_store(proc, elem_size, ir_make_const_int(a, ez));

				} break;
				case Type_Vector: {
					tag = ir_emit_conv(proc, ti_ptr, t_type_info_vector_ptr);
					irValue *gep = ir_get_type_info_ptr(proc, type_info_data, t->Vector.elem);
					ir_emit_store(proc, ir_emit_struct_ep(proc, tag, 0), gep);

					isize ez = type_size_of(m->sizes, a, t->Vector.elem);
					ir_emit_store(proc, ir_emit_struct_ep(proc, tag, 1), ir_make_const_int(a, ez));
					ir_emit_store(proc, ir_emit_struct_ep(proc, tag, 2), ir_make_const_int(a, t->Vector.count));
					ir_emit_store(proc, ir_emit_struct_ep(proc, tag, 3), ir_make_const_int(a, type_align_of(m->sizes, a, t)));

				} break;
				case Type_Record: {
					switch (t->Record.kind) {
					case TypeRecord_Struct: {
						tag = ir_emit_conv(proc, ti_ptr, t_type_info_struct_ptr);

						{
							irValue *packed  = ir_make_const_bool(a, t->Record.struct_is_packed);
							irValue *ordered = ir_make_const_bool(a, t->Record.struct_is_ordered);
							irValue *size    = ir_make_const_int(a, type_size_of(m->sizes, a, t));
							irValue *align   = ir_make_const_int(a, type_align_of(m->sizes, a, t));
							ir_emit_store(proc, ir_emit_struct_ep(proc, tag, 1), size);
							ir_emit_store(proc, ir_emit_struct_ep(proc, tag, 2), align);
							ir_emit_store(proc, ir_emit_struct_ep(proc, tag, 3), packed);
							ir_emit_store(proc, ir_emit_struct_ep(proc, tag, 4), ordered);
						}

						irValue *memory = ir_type_info_member_offset(proc, type_info_member_data, t->Record.field_count, &type_info_member_index);

						type_set_offsets(m->sizes, a, t); // NOTE(bill): Just incase the offsets have not been set yet
						for (isize source_index = 0; source_index < t->Record.field_count; source_index++) {
							// TODO(bill): Order fields in source order not layout order
							Entity *f = t->Record.fields_in_src_order[source_index];
							irValue *tip = ir_get_type_info_ptr(proc, type_info_data, f->type);
							i64 foffset = t->Record.struct_offsets[f->Variable.field_index];
							GB_ASSERT(f->kind == Entity_Variable && f->flags & EntityFlag_Field);

							irValue *field     = ir_emit_ptr_offset(proc, memory, ir_make_const_int(a, source_index));
							irValue *name      = ir_emit_struct_ep(proc, field, 0);
							irValue *type_info = ir_emit_struct_ep(proc, field, 1);
							irValue *offset    = ir_emit_struct_ep(proc, field, 2);

							if (f->token.string.len > 0) {
								ir_emit_store(proc, name, ir_make_const_string(a, f->token.string));
							}
							ir_emit_store(proc, type_info, tip);
							ir_emit_store(proc, offset, ir_make_const_int(a, foffset));
						}

						Type *slice_type = make_type_slice(a, t_type_info_member);
						Type *slice_type_ptr = make_type_pointer(a, slice_type);
						irValue *slice = ir_emit_struct_ep(proc, tag, 0);
						irValue *field_count = ir_make_const_int(a, t->Record.field_count);

						irValue *elem = ir_emit_struct_ep(proc, slice, 0);
						irValue *len  = ir_emit_struct_ep(proc, slice, 1);

						ir_emit_store(proc, elem, memory);
						ir_emit_store(proc, len, field_count);
					} break;
					case TypeRecord_Union:
						tag = ir_emit_conv(proc, ti_ptr, t_type_info_union_ptr);
						{
							irValue *size    = ir_make_const_int(a, type_size_of(m->sizes, a, t));
							irValue *align   = ir_make_const_int(a, type_align_of(m->sizes, a, t));
							ir_emit_store(proc, ir_emit_struct_ep(proc, tag, 1),  size);
							ir_emit_store(proc, ir_emit_struct_ep(proc, tag, 2),  align);
						}
						break;
					case TypeRecord_RawUnion: {
						tag = ir_emit_conv(proc, ti_ptr, t_type_info_raw_union_ptr);
						{
							irValue *size    = ir_make_const_int(a, type_size_of(m->sizes, a, t));
							irValue *align   = ir_make_const_int(a, type_align_of(m->sizes, a, t));
							ir_emit_store(proc, ir_emit_struct_ep(proc, tag, 1),  size);
							ir_emit_store(proc, ir_emit_struct_ep(proc, tag, 2),  align);
						}

						irValue *memory = ir_type_info_member_offset(proc, type_info_member_data, t->Record.field_count, &type_info_member_index);

						for (isize i = 0; i < t->Record.field_count; i++) {
							irValue *field     = ir_emit_ptr_offset(proc, memory, ir_make_const_int(a, i));
							irValue *name      = ir_emit_struct_ep(proc, field, 0);
							irValue *type_info = ir_emit_struct_ep(proc, field, 1);
							irValue *offset    = ir_emit_struct_ep(proc, field, 2);

							Entity *f = t->Record.fields[i];
							irValue *tip = ir_get_type_info_ptr(proc, type_info_data, f->type);

							if (f->token.string.len > 0) {
								ir_emit_store(proc, name, ir_make_const_string(a, f->token.string));
							}
							ir_emit_store(proc, type_info, tip);
							ir_emit_store(proc, offset, ir_make_const_int(a, 0));
						}

						Type *slice_type = make_type_slice(a, t_type_info_member);
						Type *slice_type_ptr = make_type_pointer(a, slice_type);
						irValue *slice = ir_emit_struct_ep(proc, tag, 0);
						irValue *field_count = ir_make_const_int(a, t->Record.field_count);

						irValue *elem = ir_emit_struct_ep(proc, slice, 0);
						irValue *len  = ir_emit_struct_ep(proc, slice, 1);

						ir_emit_store(proc, elem, memory);
						ir_emit_store(proc, len, field_count);
					} break;
					case TypeRecord_Enum:
						tag = ir_emit_conv(proc, ti_ptr, t_type_info_enum_ptr);
						{
							GB_ASSERT(t->Record.enum_base_type != NULL);
							irValue *base = ir_type_info(proc, t->Record.enum_base_type);
							ir_emit_store(proc, ir_emit_struct_ep(proc, tag, 0), base);

							if (t->Record.field_count > 0) {
								Entity **fields = t->Record.fields;
								isize count = t->Record.field_count;
								irValue *name_array = NULL;
								irValue *value_array = NULL;

								{
									Token token = {Token_Ident};
									i32 id = cast(i32)entry_index;
									char name_base[] = "__$enum_names";
									isize name_len = gb_size_of(name_base) + 10;
									token.string.text = gb_alloc_array(a, u8, name_len);
									token.string.len = gb_snprintf(cast(char *)token.string.text, name_len,
									                               "%s-%d", name_base, id)-1;
									Entity *e = make_entity_variable(a, NULL, token, make_type_array(a, t_string, count), false);
									name_array = ir_make_value_global(a, e, NULL);
									name_array->Global.is_private = true;
									ir_module_add_value(m, e, name_array);
									map_ir_value_set(&m->members, hash_string(token.string), name_array);
								}

								{
									Token token = {Token_Ident};
									i32 id = cast(i32)entry_index;
									char name_base[] = "__$enum_values";
									isize name_len = gb_size_of(name_base) + 10;
									token.string.text = gb_alloc_array(a, u8, name_len);
									token.string.len = gb_snprintf(cast(char *)token.string.text, name_len,
									                               "%s-%d", name_base, id)-1;
									Entity *e = make_entity_variable(a, NULL, token, make_type_array(a, t_type_info_enum_value, count), false);
									value_array = ir_make_value_global(a, e, NULL);
									value_array->Global.is_private = true;
									ir_module_add_value(m, e, value_array);
									map_ir_value_set(&m->members, hash_string(token.string), value_array);
								}

								bool is_value_int = is_type_integer(t->Record.enum_base_type);

								for (isize i = 0; i < count; i++) {
									irValue *name_ep  = ir_emit_array_epi(proc, name_array, i);
									irValue *value_ep = ir_emit_array_epi(proc, value_array, i);

									ExactValue value = fields[i]->Constant.value;

									if (is_value_int) {
										i64 i = value.value_integer;
										value_ep = ir_emit_conv(proc, value_ep, t_i64_ptr);
										ir_emit_store(proc, value_ep, ir_make_const_i64(a, i));
									} else {
										GB_ASSERT(is_type_float(t->Record.enum_base_type));
										f64 f = value.value_float;
										value_ep = ir_emit_conv(proc, value_ep, t_f64_ptr);
										ir_emit_store(proc, value_ep, ir_make_const_f64(a, f));
									}

									ir_emit_store(proc, name_ep, ir_make_const_string(a, fields[i]->token.string));
								}

								irValue *v_count = ir_make_const_int(a, count);

								irValue *names = ir_emit_struct_ep(proc, tag, 1);
								irValue *name_array_elem = ir_array_elem(proc, name_array);

								ir_emit_store(proc, ir_emit_struct_ep(proc, names, 0), name_array_elem);
								ir_emit_store(proc, ir_emit_struct_ep(proc, names, 1), v_count);

								irValue *values = ir_emit_struct_ep(proc, tag, 2);
								irValue *value_array_elem = ir_array_elem(proc, value_array);

								ir_emit_store(proc, ir_emit_struct_ep(proc, values, 0), value_array_elem);
								ir_emit_store(proc, ir_emit_struct_ep(proc, values, 1), v_count);
							}
						}
						break;
					}
				} break;

				case Type_Tuple: {
					tag = ir_emit_conv(proc, ti_ptr, t_type_info_tuple_ptr);

					{
						irValue *align = ir_make_const_int(a, type_align_of(m->sizes, a, t));
						ir_emit_store(proc, ir_emit_struct_ep(proc, tag, 2), align);
					}

					irValue *memory = ir_type_info_member_offset(proc, type_info_member_data, t->Tuple.variable_count, &type_info_member_index);

					for (isize i = 0; i < t->Tuple.variable_count; i++) {
						irValue *field     = ir_emit_ptr_offset(proc, memory, ir_make_const_int(a, i));
						irValue *name      = ir_emit_struct_ep(proc, field, 0);
						irValue *type_info = ir_emit_struct_ep(proc, field, 1);
						// NOTE(bill): offset is not used for tuples

						Entity *f = t->Tuple.variables[i];
						irValue *tip = ir_get_type_info_ptr(proc, type_info_data, f->type);

						if (f->token.string.len > 0) {
							ir_emit_store(proc, name, ir_make_const_string(a, f->token.string));
						}
						ir_emit_store(proc, type_info, tip);
					}

					Type *slice_type = make_type_slice(a, t_type_info_member);
					Type *slice_type_ptr = make_type_pointer(a, slice_type);
					irValue *slice = ir_emit_struct_ep(proc, tag, 0);
					irValue *variable_count = ir_make_const_int(a, t->Tuple.variable_count);

					irValue *elem = ir_emit_struct_ep(proc, slice, 0);
					irValue *len  = ir_emit_struct_ep(proc, slice, 1);

					ir_emit_store(proc, elem, memory);
					ir_emit_store(proc, len, variable_count);
				} break;

				case Type_Proc: {
					tag = ir_emit_conv(proc, ti_ptr, t_type_info_procedure_ptr);

					irValue *params     = ir_emit_struct_ep(proc, tag, 0);
					irValue *results    = ir_emit_struct_ep(proc, tag, 1);
					irValue *variadic   = ir_emit_struct_ep(proc, tag, 2);
					irValue *convention = ir_emit_struct_ep(proc, tag, 3);

					if (t->Proc.params) {
						ir_emit_store(proc, params, ir_get_type_info_ptr(proc, type_info_data, t->Proc.params));
					}
					if (t->Proc.results) {
						ir_emit_store(proc, results, ir_get_type_info_ptr(proc, type_info_data, t->Proc.results));
					}
					ir_emit_store(proc, variadic, ir_make_const_bool(a, t->Proc.variadic));
					ir_emit_store(proc, convention, ir_make_const_int(a, t->Proc.calling_convention));

					// TODO(bill): Type_Info for procedures
				} break;
				}

				if (tag != NULL) {
					Type *tag_type = type_deref(ir_type(tag));
					Type *ti = base_type(t_type_info);
					bool found = false;
					for (isize i = 1; i < ti->Record.field_count; i++) {
						Entity *f = ti->Record.fields[i];
						if (are_types_identical(f->type, tag_type)) {
							found = true;
							irValue *tag = ir_make_const_int(proc->module->allocator, i);
							ir_emit_store(proc, ir_emit_union_tag_ptr(proc, ti_ptr), tag);
							break;
						}
					}
					GB_ASSERT(found);
				}
			}
		}

		ir_end_procedure_body(proc);
	}

	for_array(i, m->procs_to_generate) {
		ir_build_proc(m->procs_to_generate.e[i], m->procs_to_generate.e[i]->Proc.parent);
	}


	// m->layout = str_lit("e-p:64:64:64-i1:8:8-i8:8:8-i16:16:16-i32:32:32-i64:64:64-f32:32:32-f64:64:64-v64:64:64-v128:128:128-a0:0:64-s0:64:64-f80:128:128-n8:16:32:64");
}

