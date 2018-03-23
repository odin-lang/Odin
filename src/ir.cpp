struct irProcedure;
struct irBlock;
struct irValue;
struct irDebugInfo;



struct irModule {
	CheckerInfo * info;
	gbArena       arena;
	gbArena       tmp_arena;
	gbAllocator   allocator;
	gbAllocator   tmp_allocator;
	bool generate_debug_info;

	u64 stmt_state_flags;

	// String source_filename;
	String layout;
	// String triple;

	PtrSet<Entity *>      min_dep_set;
	Map<irValue *>        values;              // Key: Entity *
	Map<irValue *>        members;             // Key: String
	Map<String>           entity_names;        // Key: Entity * of the typename
	Map<irDebugInfo *>    debug_info;          // Key: Unique pointer
	Map<irValue *>        anonymous_proc_lits; // Key: AstNode *

	irDebugInfo *         debug_compile_unit;


	i32                   global_string_index;
	i32                   global_array_index; // For ConstantSlice
	i32                   global_generated_index;

	irValue *             global_default_context;

	// NOTE(bill): To prevent strings from being copied a lot
	// Mainly used for file names
	Map<irValue *>        const_strings; // Key: String


	Entity *              entry_point_entity;

	Array<irProcedure *>  procs;             // NOTE(bill): All procedures with bodies
	Array<irValue *>      procs_to_generate; // NOTE(bill): Procedures to generate

	Array<String>         foreign_library_paths; // Only the ones that were used
};

// NOTE(bill): For more info, see https://en.wikipedia.org/wiki/Dominator_(graph_theory)
struct irDomNode {
	irBlock *        idom; // Parent (Immediate Dominator)
	Array<irBlock *> children;
	i32              pre, post; // Ordering in tree
};


struct irBlock {
	i32          index;
	String       label;
	irProcedure *proc;
	AstNode *    node; // Can be nullptr
	Scope *      scope;
	isize        scope_index;
	irDomNode    dom;
	i32          gaps;

	Array<irValue *> instrs;
	Array<irValue *> locals;

	Array<irBlock *> preds;
	Array<irBlock *> succs;
};

struct irTargetList {
	irTargetList *prev;
	irBlock *     break_;
	irBlock *     continue_;
	irBlock *     fallthrough_;
};

enum irDeferExitKind {
	irDeferExit_Default,
	irDeferExit_Return,
	irDeferExit_Branch,
};
enum irDeferKind {
	irDefer_Node,
	irDefer_Instr,
};

struct irDefer {
	irDeferKind kind;
	isize       scope_index;
	irBlock *   block;
	union {
		AstNode *stmt;
		// NOTE(bill): 'instr' will be copied every time to create a new one
		irValue *instr;
	};
};


struct irBranchBlocks {
	AstNode *label;
	irBlock *break_;
	irBlock *continue_;
};


struct irDebugLocation {
	TokenPos     pos;
	irDebugInfo *debug_scope;
};

struct irProcedure {
	irProcedure *         parent;
	Array<irProcedure *>  children;

	Entity *              entity;
	irModule *            module;
	String                name;
	Type *                type;
	AstNode *             type_expr;
	AstNode *             body;
	u64                   tags;
	ProcInlining          inlining;
	bool                  is_foreign;
	bool                  is_export;
	bool                  is_entry_point;

	irDebugInfo *         debug_scope;

	irValue *             return_ptr;
	Array<irValue *>      params;
	Array<irDefer>        defer_stmts;
	Array<irBlock *>      blocks;
	i32                   scope_index;
	irBlock *             decl_block;
	irBlock *             entry_block;
	irBlock *             curr_block;
	irTargetList *        target_list;
	Array<irValue *>      referrers;

	Array<irValue *>      context_stack;


	Array<irBranchBlocks> branch_blocks;

	i32                   local_count;
	i32                   instr_count;
	i32                   block_count;
};




#define IR_STARTUP_RUNTIME_PROC_NAME "__$startup_runtime"
#define IR_TYPE_INFO_DATA_NAME       "__$type_info_data"
#define IR_TYPE_INFO_TYPES_NAME      "__$type_info_types_data"
#define IR_TYPE_INFO_NAMES_NAME      "__$type_info_names_data"
#define IR_TYPE_INFO_OFFSETS_NAME    "__$type_info_offsets_data"
#define IR_TYPE_INFO_USINGS_NAME     "__$type_info_usings_data"


#define IR_INSTR_KINDS \
	IR_INSTR_KIND(Comment, struct { String text; })                   \
	IR_INSTR_KIND(Local,   struct {                                   \
		Entity *     entity;                                          \
		Type *       type;                                            \
		bool         zero_initialized;                                \
		Array<irValue *> referrers;                                   \
		i64          alignment;                                       \
	})                                                                \
	IR_INSTR_KIND(ZeroInit, struct { irValue *address; })             \
	IR_INSTR_KIND(Store,    struct {                                  \
		irValue *address, *value; bool atomic;                        \
	})                                                                \
	IR_INSTR_KIND(Load,     struct { Type *type; irValue *address; }) \
	IR_INSTR_KIND(PtrOffset, struct {                                 \
		irValue *address;                                             \
		irValue *offset;                                              \
	})                                                                \
	IR_INSTR_KIND(ArrayElementPtr, struct {                           \
		irValue *address;                                             \
		Type *   result_type;                                         \
		irValue *elem_index;                                          \
	})                                                                \
	IR_INSTR_KIND(StructElementPtr, struct {                          \
		irValue *address;                                             \
		Type *    result_type;                                        \
		i32       elem_index;                                         \
	})                                                                \
	IR_INSTR_KIND(StructExtractValue, struct {                        \
		irValue *address;                                             \
		Type *    result_type;                                        \
		i32       index;                                              \
	})                                                                \
	IR_INSTR_KIND(UnionTagPtr, struct {                               \
		irValue *address;                                             \
		Type     *type; /* ^int */                                    \
	})                                                                \
	IR_INSTR_KIND(UnionTagValue, struct {                             \
		irValue *address;                                             \
		Type     *type; /* int */                                     \
	})                                                                \
	IR_INSTR_KIND(Conv, struct {                                      \
		irConvKind kind;                                              \
		irValue *value;                                               \
		Type *from, *to;                                              \
	})                                                                \
	IR_INSTR_KIND(Jump, struct { irBlock *block; })                   \
	IR_INSTR_KIND(If, struct {                                        \
		irValue *cond;                                                \
		irBlock *true_block;                                          \
		irBlock *false_block;                                         \
	})                                                                \
	IR_INSTR_KIND(Return, struct { irValue *value; })                 \
	IR_INSTR_KIND(Select, struct {                                    \
		irValue *cond;                                                \
		irValue *true_value;                                          \
		irValue *false_value;                                         \
	})                                                                \
	IR_INSTR_KIND(Phi, struct { Array<irValue *> edges; Type *type; })\
	IR_INSTR_KIND(Unreachable, i32)                                   \
	IR_INSTR_KIND(UnaryOp, struct {                                   \
		Type *    type;                                               \
		TokenKind op;                                                 \
		irValue * expr;                                               \
	})                                                                \
	IR_INSTR_KIND(BinaryOp, struct {                                  \
		Type *    type;                                               \
		TokenKind op;                                                 \
		irValue * left, *right;                                       \
	})                                                                \
	IR_INSTR_KIND(Call, struct {                                      \
		Type *    type; /* return type */                             \
		irValue * value;                                              \
		irValue * return_ptr;                                         \
		Array<irValue *> args;                                        \
		irValue * context_ptr;                                        \
	})                                                                \
	IR_INSTR_KIND(StartupRuntime, i32)                                \
	IR_INSTR_KIND(DebugDeclare, struct {                              \
		irDebugInfo *scope;                                           \
		AstNode *    expr;                                            \
		Entity *     entity;                                          \
		bool         is_addr;                                         \
		irValue *    value;                                           \
	})                                                                \

// 	IR_INSTR_KIND(BoundsCheck, struct {                               \
// 		TokenPos pos;                                                 \
// 		irValue *index;                                               \
// 		irValue *len;                                                 \
// 	})                                                                \
// 	IR_INSTR_KIND(SliceBoundsCheck, struct {                          \
// 		TokenPos pos;                                                 \
// 		irValue *low;                                                 \
// 		irValue *high;                                                \
// 		irValue *max;                                                 \
// 		bool     is_substring;                                        \
// 	})                                                                \


#define IR_CONV_KINDS \
	IR_CONV_KIND(trunc) \
	IR_CONV_KIND(zext) \
	IR_CONV_KIND(sext) \
	IR_CONV_KIND(fptrunc) \
	IR_CONV_KIND(fpext) \
	IR_CONV_KIND(fptoui) \
	IR_CONV_KIND(fptosi) \
	IR_CONV_KIND(uitofp) \
	IR_CONV_KIND(sitofp) \
	IR_CONV_KIND(ptrtoint) \
	IR_CONV_KIND(inttoptr) \
	IR_CONV_KIND(bitcast)

enum irInstrKind {
	irInstr_Invalid,
#define IR_INSTR_KIND(x, ...) GB_JOIN2(irInstr_, x),
	IR_INSTR_KINDS
#undef IR_INSTR_KIND
};

String const ir_instr_strings[] = {
	{cast(u8 *)"Invalid", gb_size_of("Invalid")-1},
#define IR_INSTR_KIND(x, ...) {cast(u8 *)#x, gb_size_of(#x)-1},
	IR_INSTR_KINDS
#undef IR_INSTR_KIND
};

enum irConvKind {
	irConv_Invalid,
#define IR_CONV_KIND(x) GB_JOIN2(irConv_, x),
	IR_CONV_KINDS
#undef IR_CONV_KIND
};

String const ir_conv_strings[] = {
	{cast(u8 *)"Invalid", gb_size_of("Invalid")-1},
#define IR_CONV_KIND(x) {cast(u8 *)#x, gb_size_of(#x)-1},
	IR_CONV_KINDS
#undef IR_CONV_KIND
};

#define IR_INSTR_KIND(k, ...) typedef __VA_ARGS__ GB_JOIN2(irInstr, k);
	IR_INSTR_KINDS
#undef IR_INSTR_KIND

struct irInstr {
	irInstrKind kind;

	irBlock *block;
	Type *type;

	union {
#define IR_INSTR_KIND(k, ...) GB_JOIN2(irInstr, k) k;
	IR_INSTR_KINDS
#undef IR_INSTR_KIND
	};
};


enum irValueKind {
	irValue_Invalid,

	irValue_Constant,
	irValue_ConstantSlice,
	irValue_Nil,
	irValue_Undef,
	irValue_TypeName,
	irValue_Global,
	irValue_Param,

	irValue_Proc,
	irValue_Block,
	irValue_Instr,

	irValue_Count,
};

struct irValueConstant {
	Type *     type;
	ExactValue value;
};

struct irValueConstantSlice {
	Type *    type;
	irValue *backing_array;
	i64       count;
};

struct irValueNil {
	Type *type;
};

struct irValueUndef {
	Type *type;
};

struct irValueTypeName {
	Type * type;
	String name;
};

struct irValueGlobal {
	String        name;
	Entity *      entity;
	Type *        type;
	irValue *     value;
	Array<irValue *>  referrers;
	bool          is_constant;
	bool          is_export;
	bool          is_private;
	String        thread_local_model;
	bool          is_foreign;
	bool          is_unnamed_addr;
};


enum irParamPasskind {
	irParamPass_Value,    // Pass by value
	irParamPass_Pointer,  // Pass as a pointer rather than by value
	irParamPass_Integer,  // Pass as an integer of the same size
	irParamPass_ConstRef, // Pass as a pointer but the value is immutable
};

struct irValueParam {
	irParamPasskind  kind;
	irProcedure *    parent;
	Entity *         entity;
	Type *           type;
	Type *           original_type;
	Array<irValue *> referrers;
};


struct irValue {
	irValueKind     kind;
	i32             index;
	bool            index_set;
	irDebugLocation loc;
	union {
		irValueConstant      Constant;
		irValueConstantSlice ConstantSlice;
		irValueNil           Nil;
		irValueUndef         Undef;
		irValueTypeName      TypeName;
		irValueGlobal        Global;
		irValueParam         Param;
		irProcedure          Proc;
		irBlock              Block;
		irInstr              Instr;
	};
};

gb_global irValue *v_zero    = nullptr;
gb_global irValue *v_one     = nullptr;
gb_global irValue *v_zero32  = nullptr;
gb_global irValue *v_one32   = nullptr;
gb_global irValue *v_two32   = nullptr;
gb_global irValue *v_false   = nullptr;
gb_global irValue *v_true    = nullptr;
gb_global irValue *v_raw_nil = nullptr;

enum irAddrKind {
	irAddr_Default,
	irAddr_Map,
	irAddr_BitField,
};

struct irAddr {
	irAddrKind kind;
	irValue *  addr;
	union {
		struct {
			irValue *map_key;
			Type *   map_type;
			Type *   map_result;
		};
		struct {
			i32      bit_field_value_index;
		};
	};
};

irAddr ir_addr(irValue *addr) {
	irAddr v = {irAddr_Default, addr};
	return v;
}

irAddr ir_addr_map(irValue *addr, irValue *map_key, Type *map_type, Type *map_result) {
	irAddr v = {irAddr_Map, addr};
	v.map_key    = map_key;
	v.map_type   = map_type;
	v.map_result = map_result;
	return v;
}

irAddr ir_addr_bit_field(irValue *addr, i32 bit_field_value_index) {
	irAddr v = {irAddr_BitField, addr};
	v.bit_field_value_index = bit_field_value_index;
	return v;
}

enum irDebugEncoding {
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

};

enum irDebugInfoKind {
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
};

struct irDebugInfo {
	irDebugInfoKind kind;
	i32 id;

	union {
		struct {
			AstFile *    file;
			String       producer;
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
			TokenPos     pos;
			Scope *      scope; // Actual scope
		} Scope;
		struct {
			Entity *     entity;
			String       name;
			irDebugInfo *file;
			TokenPos     pos;
		} Proc;
		struct {
			Array<irDebugInfo *> procs;
		} AllProcs;

		struct {
			String          name;
			i32             size;
			i32             align;
			irDebugEncoding encoding;
		} BasicType;
		struct {
			irDebugInfo *        return_type;
			Array<irDebugInfo *> param_types;
		} ProcType;
		struct {
			irDebugInfo *   base_type;
			irDebugEncoding encoding;
		} DerivedType;
		struct {
			irDebugEncoding      encoding;
			String               name;
			String               identifier;
			irDebugInfo *        file;
			TokenPos             pos;
			i32                  size;
			i32                  align;
			Array<irDebugInfo *> elements;
		} CompositeType;
		struct {
			String name;
			i64    value;
		} Enumerator;
		struct {
			String       name;
			String       linkage_name;
			irDebugInfo *scope;
			irDebugInfo *file;
			TokenPos     pos;
			irValue     *variable;
			irDebugInfo *declaration;
		} GlobalVariable;
		struct {
			String       name;
			irDebugInfo *scope;
			irDebugInfo *file;
			TokenPos     pos;
			i32          arg; // Non-zero if proc parameter
			irDebugInfo *type;
		} LocalVariable;
	};
};


struct irGen {
	irModule module;
	gbFile   output_file;
	bool     opt_called;
	String   output_base;
	String   output_name;
};




gb_inline bool ir_min_dep_entity(irModule *m, Entity *e) {
	return ptr_set_exists(&m->min_dep_set, e);
}

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
		if (pt != nullptr) {
			if (pt->kind == Type_Tuple && pt->Tuple.variables.count == 1) {
				return pt->Tuple.variables[0]->type;
			}
			return pt;
		}
		return nullptr;
	}
	}
	return nullptr;
}

Type *ir_type(irValue *value) {
	switch (value->kind) {
	case irValue_Constant:
		return value->Constant.type;
	case irValue_ConstantSlice:
		return value->ConstantSlice.type;
	case irValue_Nil:
		return value->Nil.type;
	case irValue_Undef:
		return value->Undef.type;
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
	return nullptr;
}


bool ir_type_has_default_values(Type *t) {
	switch (t->kind) {
	case Type_Named:
		return ir_type_has_default_values(t->Named.base);

	case Type_Array:
		return ir_type_has_default_values(t->Array.elem);

	case Type_Struct:
		if (t->Struct.is_raw_union) return false;
		for_array(i, t->Struct.fields) {
			Entity *f = t->Struct.fields[i];
			if (f->kind != Entity_Variable) continue;
			if (f->Variable.default_is_nil) {
				// NOTE(bill): This is technically zero
				continue;
			} else if (f->Variable.default_value.kind != ExactValue_Invalid) {
				return true;
			} else if (f->Variable.default_is_undef) {
				return true;
			}
			bool sub = ir_type_has_default_values(f->type);
			if (sub) return true;
		}
		break;
	}

	return false;
}


irInstr *ir_get_last_instr(irBlock *block) {
	if (block != nullptr) {
		isize len = block->instrs.count;
		if (len > 0) {
			irValue *v = block->instrs[len-1];
			GB_ASSERT(v->kind == irValue_Instr);
			return &v->Instr;
		}
	}
	return nullptr;

}

bool ir_is_instr_terminating(irInstr *i) {
	if (i != nullptr) {
		switch (i->kind) {
		case irInstr_Return:
		case irInstr_Unreachable:
			return true;
		}
	}

	return false;
}


void ir_add_edge(irBlock *from, irBlock *to) {
	GB_ASSERT(from->instrs.count > 0);
	if (!ir_is_instr_terminating(ir_get_last_instr(from))) {
		array_add(&from->succs, to);
		array_add(&to->preds, from);
	}
}

void ir_set_instr_block(irValue *instr, irBlock *block) {
	if (instr->kind == irValue_Instr) {
		instr->Instr.block = block;
	}
}

Array<irValue *> *ir_value_referrers(irValue *v) {
	switch (v->kind) {
	case irValue_Global:
		return &v->Global.referrers;
	case irValue_Param:
		return &v->Param.referrers;
	case irValue_Proc: {
		if (v->Proc.parent != nullptr) {
			return &v->Proc.referrers;
		}
		return nullptr;
	}
	case irValue_Instr: {
		irInstr *i = &v->Instr;
		switch (i->kind) {
		case irInstr_Local:
			return &i->Local.referrers;
		}
		break;
	}
	}

	return nullptr;
}



////////////////////////////////////////////////////////////////
//
// @Make
//
////////////////////////////////////////////////////////////////

void     ir_module_add_value    (irModule *m, Entity *e, irValue *v);
void     ir_emit_zero_init      (irProcedure *p, irValue *address, AstNode *expr);
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
irValue *ir_get_type_info_ptr   (irProcedure *proc, Type *type);




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




irValue *ir_value_type_name(gbAllocator a, String name, Type *type) {
	irValue *v = ir_alloc_value(a, irValue_TypeName);
	v->TypeName.name = name;
	v->TypeName.type = type;
	return v;
}

irValue *ir_value_global(gbAllocator a, Entity *e, irValue *value) {
	irValue *v = ir_alloc_value(a, irValue_Global);
	v->Global.entity = e;
	v->Global.type = alloc_type_pointer(e->type);
	v->Global.value = value;
	array_init(&v->Global.referrers, heap_allocator()); // TODO(bill): Replace heap allocator here
	return v;
}
irValue *ir_value_param(gbAllocator a, irProcedure *parent, Entity *e, Type *abi_type) {
	irValue *v = ir_alloc_value(a, irValue_Param);
	v->Param.kind          = irParamPass_Value;
	v->Param.parent        = parent;
	v->Param.entity        = e;
	v->Param.original_type = e->type;
	v->Param.type          = abi_type;

	if (abi_type != e->type) {
		if (is_type_pointer(abi_type)) {
			GB_ASSERT(e->kind == Entity_Variable);
			v->Param.kind = irParamPass_Pointer;
			if (e->flags&EntityFlag_Value) {
				v->Param.kind = irParamPass_ConstRef;
			}
		} else if (is_type_integer(abi_type)) {
			v->Param.kind = irParamPass_Integer;
		} else if (abi_type == t_llvm_bool) {
			v->Param.kind = irParamPass_Value;
		} else {
			GB_PANIC("Invalid abi type pass kind");
		}
	}
	array_init(&v->Param.referrers, heap_allocator()); // TODO(bill): Replace heap allocator here
	return v;
}
irValue *ir_value_nil(gbAllocator a, Type *type) {
	irValue *v = ir_alloc_value(a, irValue_Nil);
	v->Nil.type = type;
	return v;
}

irValue *ir_value_undef(gbAllocator a, Type *type) {
	irValue *v = ir_alloc_value(a, irValue_Undef);
	v->Undef.type = type;
	return v;
}


String ir_get_global_name(irModule *m, irValue *v) {
	if (v->kind != irValue_Global) {
		return str_lit("");
	}
	irValueGlobal *g = &v->Global;
	Entity *e = g->entity;
	String name = e->token.string;
	String *found = map_get(&m->entity_names, hash_entity(e));
	if (found != nullptr) {
		name = *found;
	} else {
		GB_ASSERT(name.len > 0);
	}
	return name;
}

void ir_add_entity_name(irModule *m, Entity *e, String name) {
	GB_ASSERT(name.len > 0);
	if (e != nullptr && e->kind == Entity_TypeName) {
		e->TypeName.ir_mangled_name = name;
	}
	map_set(&m->entity_names, hash_entity(e), name);
}





irValue *ir_instr_local(irProcedure *p, Entity *e, bool zero_initialized) {
	irValue *v = ir_alloc_instr(p, irInstr_Local);
	irInstr *i = &v->Instr;
	i->Local.entity = e;
	i->Local.type = alloc_type_pointer(e->type);
	i->Local.zero_initialized = zero_initialized;
	// i->Local.alignment = type_align_of(p->module->allocator, e->type);
	// TODO(bill): determine the correct alignment
	i->Local.alignment = gb_max(16, type_align_of(e->type));
	array_init(&i->Local.referrers, heap_allocator()); // TODO(bill): Replace heap allocator here
	ir_module_add_value(p->module, e, v);
	return v;
}

irValue *ir_instr_zero_init(irProcedure *p, irValue *address) {
	irValue *v = ir_alloc_instr(p, irInstr_ZeroInit);
	irInstr *i = &v->Instr;
	i->ZeroInit.address = address;
	return v;
}

irValue *ir_instr_store(irProcedure *p, irValue *address, irValue *value, bool atomic) {
	irValue *v = ir_alloc_instr(p, irInstr_Store);
	irInstr *i = &v->Instr;
	i->Store.address = address;
	i->Store.value = value;
	i->Store.atomic = atomic;
	return v;
}

irValue *ir_instr_load(irProcedure *p, irValue *address) {
	irValue *v = ir_alloc_instr(p, irInstr_Load);
	irInstr *i = &v->Instr;
	i->Load.address = address;
	i->Load.type = type_deref(ir_type(address));
	return v;
}

irValue *ir_instr_array_element_ptr(irProcedure *p, irValue *address, irValue *elem_index) {
	irValue *v = ir_alloc_instr(p, irInstr_ArrayElementPtr);
	irInstr *i = &v->Instr;
	Type *t = ir_type(address);
	GB_ASSERT_MSG(is_type_pointer(t), "%s", type_to_string(t));
	t = base_type(type_deref(t));
	GB_ASSERT(is_type_array(t));

	Type *result_type = alloc_type_pointer(t->Array.elem);

	i->ArrayElementPtr.address = address;
	i->ArrayElementPtr.elem_index = elem_index;
	i->ArrayElementPtr.result_type = result_type;

	GB_ASSERT_MSG(is_type_pointer(ir_type(address)),
	              "%s", type_to_string(ir_type(address)));
	return v;
}
irValue *ir_instr_struct_element_ptr(irProcedure *p, irValue *address, i32 elem_index, Type *result_type) {
	irValue *v = ir_alloc_instr(p, irInstr_StructElementPtr);
	irInstr *i = &v->Instr;
	i->StructElementPtr.address     = address;
	i->StructElementPtr.elem_index  = elem_index;
	i->StructElementPtr.result_type = result_type;

	GB_ASSERT_MSG(is_type_pointer(ir_type(address)),
	              "%s", type_to_string(ir_type(address)));
	return v;
}
irValue *ir_instr_ptr_offset(irProcedure *p, irValue *address, irValue *offset) {
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



irValue *ir_instr_struct_extract_value(irProcedure *p, irValue *address, i32 index, Type *result_type) {
	irValue *v = ir_alloc_instr(p, irInstr_StructExtractValue);
	irInstr *i = &v->Instr;
	i->StructExtractValue.address = address;
	i->StructExtractValue.index = index;
	i->StructExtractValue.result_type = result_type;
	return v;
}

irValue *ir_instr_union_tag_ptr(irProcedure *p, irValue *address) {
	irValue *v = ir_alloc_instr(p, irInstr_UnionTagPtr);
	irInstr *i = &v->Instr;
	i->UnionTagPtr.address = address;
	// i->UnionTagPtr.type = alloc_type_pointer(t_type_info_ptr);
	Type *u = type_deref(ir_type(address));
	i->UnionTagPtr.type = alloc_type_pointer(union_tag_type(u));
	return v;
}

irValue *ir_instr_union_tag_value(irProcedure *p, irValue *address) {
	irValue *v = ir_alloc_instr(p, irInstr_UnionTagValue);
	irInstr *i = &v->Instr;
	i->UnionTagValue.address = address;
	// i->UnionTagValue.type = t_type_info_ptr;
	// i->UnionTagValue.type = t_int;
	Type *u = type_deref(ir_type(address));
	i->UnionTagPtr.type = union_tag_type(u);
	return v;
}

irValue *ir_instr_unary_op(irProcedure *p, TokenKind op, irValue *expr, Type *type) {
	irValue *v = ir_alloc_instr(p, irInstr_UnaryOp);
	irInstr *i = &v->Instr;
	i->UnaryOp.op = op;
	i->UnaryOp.expr = expr;
	i->UnaryOp.type = type;
	return v;
}


irValue *ir_instr_binary_op(irProcedure *p, TokenKind op, irValue *left, irValue *right, Type *type) {
	irValue *v = ir_alloc_instr(p, irInstr_BinaryOp);
	irInstr *i = &v->Instr;
	i->BinaryOp.op = op;
	i->BinaryOp.left = left;
	i->BinaryOp.right = right;
	i->BinaryOp.type = type;
	return v;
}

irValue *ir_instr_jump(irProcedure *p, irBlock *block) {
	irValue *v = ir_alloc_instr(p, irInstr_Jump);
	irInstr *i = &v->Instr;
	i->Jump.block = block;
	return v;
}
irValue *ir_instr_if(irProcedure *p, irValue *cond, irBlock *true_block, irBlock *false_block) {
	irValue *v = ir_alloc_instr(p, irInstr_If);
	irInstr *i = &v->Instr;
	i->If.cond = ir_emit_conv(p, cond, t_llvm_bool);
	i->If.true_block = true_block;
	i->If.false_block = false_block;
	return v;
}


irValue *ir_instr_phi(irProcedure *p, Array<irValue *> edges, Type *type) {
	irValue *v = ir_alloc_instr(p, irInstr_Phi);
	irInstr *i = &v->Instr;
	i->Phi.edges = edges;
	i->Phi.type = type;
	return v;
}

irValue *ir_instr_unreachable(irProcedure *p) {
	irValue *v = ir_alloc_instr(p, irInstr_Unreachable);
	return v;
}

irValue *ir_instr_return(irProcedure *p, irValue *value) {
	irValue *v = ir_alloc_instr(p, irInstr_Return);
	v->Instr.Return.value = value;
	return v;
}

irValue *ir_instr_select(irProcedure *p, irValue *cond, irValue *t, irValue *f) {
	irValue *v = ir_alloc_instr(p, irInstr_Select);
	v->Instr.Select.cond = cond;
	v->Instr.Select.true_value = t;
	v->Instr.Select.false_value = f;
	return v;
}

irValue *ir_instr_call(irProcedure *p, irValue *value, irValue *return_ptr, Array<irValue *> args, Type *result_type, irValue *context_ptr) {
	irValue *v = ir_alloc_instr(p, irInstr_Call);
	v->Instr.Call.value       = value;
	v->Instr.Call.return_ptr  = return_ptr;
	v->Instr.Call.args        = args;
	v->Instr.Call.type        = result_type;
	v->Instr.Call.context_ptr = context_ptr;
	return v;
}

irValue *ir_instr_conv(irProcedure *p, irConvKind kind, irValue *value, Type *from, Type *to) {
	irValue *v = ir_alloc_instr(p, irInstr_Conv);
	v->Instr.Conv.kind  = kind;
	v->Instr.Conv.value = value;
	v->Instr.Conv.from  = from;
	v->Instr.Conv.to    = to;
	return v;
}

irValue *ir_instr_comment(irProcedure *p, String text) {
	irValue *v = ir_alloc_instr(p, irInstr_Comment);
	v->Instr.Comment.text = text;
	return v;
}

irValue *ir_instr_debug_declare(irProcedure *p, irDebugInfo *scope, AstNode *expr, Entity *entity, bool is_addr, irValue *value) {
	irValue *v = ir_alloc_instr(p, irInstr_DebugDeclare);
	v->Instr.DebugDeclare.scope      = scope;
	v->Instr.DebugDeclare.expr       = expr;
	v->Instr.DebugDeclare.entity     = entity;
	v->Instr.DebugDeclare.is_addr    = is_addr;
	v->Instr.DebugDeclare.value      = value;
	return v;

}



irValue *ir_value_constant(gbAllocator a, Type *type, ExactValue value) {
	irValue *v = ir_alloc_value(a, irValue_Constant);
	v->Constant.type  = type;
	v->Constant.value = value;
	return v;
}


irValue *ir_value_constant_slice(gbAllocator a, Type *type, irValue *backing_array, i64 count) {
	irValue *v = ir_alloc_value(a, irValue_ConstantSlice);
	v->ConstantSlice.type = type;
	v->ConstantSlice.backing_array = backing_array;
	v->ConstantSlice.count = count;
	return v;
}


irValue *ir_emit(irProcedure *proc, irValue *instr) {
	GB_ASSERT(instr->kind == irValue_Instr);
	irBlock *b = proc->curr_block;
	instr->Instr.block = b;
	if (b != nullptr) {
		irInstr *i = ir_get_last_instr(b);
		if (!ir_is_instr_terminating(i)) {
			array_add(&b->instrs, instr);
		}
	} else if (instr->Instr.kind != irInstr_Unreachable) {
		GB_PANIC("ir_emit: Instruction missing parent block");
	}
	return instr;
}



irValue *ir_const_int(gbAllocator a, i64 i) {
	return ir_value_constant(a, t_int, exact_value_i64(i));
}
irValue *ir_const_uintptr(gbAllocator a, u64 i) {
	return ir_value_constant(a, t_uintptr, exact_value_i64(i));
}
irValue *ir_const_i32(gbAllocator a, i32 i) {
	return ir_value_constant(a, t_i32, exact_value_i64(i));
}
irValue *ir_const_u32(gbAllocator a, u32 i) {
	return ir_value_constant(a, t_u32, exact_value_i64(i));
}
irValue *ir_const_i64(gbAllocator a, i64 i) {
	return ir_value_constant(a, t_i64, exact_value_i64(i));
}
irValue *ir_const_u64(gbAllocator a, u64 i) {
	return ir_value_constant(a, t_u64, exact_value_i64(i));
}
irValue *ir_const_f32(gbAllocator a, f32 f) {
	return ir_value_constant(a, t_f32, exact_value_float(f));
}
irValue *ir_const_f64(gbAllocator a, f64 f) {
	return ir_value_constant(a, t_f64, exact_value_float(f));
}
irValue *ir_const_bool(gbAllocator a, bool b) {
	return ir_value_constant(a, t_bool, exact_value_bool(b != 0));
}
irValue *ir_const_string(gbAllocator a, String s) {
	return ir_value_constant(a, t_string, exact_value_string(s));
}

irValue *ir_value_procedure(gbAllocator a, irModule *m, Entity *entity, Type *type, AstNode *type_expr, AstNode *body, String name) {
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
	array_init(&v->Proc.params, heap_allocator(), 0, t->Proc.param_count);

	return v;
}


irValue *ir_generate_array(irModule *m, Type *elem_type, i64 count, String prefix, i64 id) {
	gbAllocator a = m->allocator;
	Token token = {Token_Ident};
	isize name_len = prefix.len + 10;

	char *text = gb_alloc_array(a, char, name_len);
	gb_snprintf(text, name_len,
	            "%.*s-%llx", LIT(prefix), cast(unsigned long long)id);

	String s = make_string_c(text);

	Entity *e = alloc_entity_variable(nullptr, make_token_ident(s), alloc_type_array(elem_type, count), false);
	irValue *value = ir_value_global(a, e, nullptr);
	value->Global.is_private = true;
	ir_module_add_value(m, e, value);
	map_set(&m->members, hash_string(s), value);
	return value;
}

irBlock *ir_new_block(irProcedure *proc, AstNode *node, char *label) {
	Scope *scope = nullptr;
	if (node != nullptr) {
		scope = scope_of_node(proc->module->info, node);
		GB_ASSERT_MSG(scope != nullptr, "Block scope not found for %.*s", LIT(ast_node_strings[node->kind]));
	}

	irValue *v = ir_alloc_value(proc->module->allocator, irValue_Block);
	v->Block.label  = make_string_c(label);
	v->Block.node   = node;
	v->Block.scope  = scope;
	v->Block.proc   = proc;
	// TODO(bill): Is this correct or even needed?
	v->Block.scope_index = proc->scope_index;

	array_init(&v->Block.instrs, heap_allocator());
	array_init(&v->Block.locals, heap_allocator());

	array_init(&v->Block.preds,  heap_allocator());
	array_init(&v->Block.succs,  heap_allocator());

	irBlock *block = &v->Block;
	return block;
}

void ir_add_block_to_proc(irProcedure *proc, irBlock *b) {
	for_array(i, proc->blocks) {
		if (proc->blocks[i] == b) {
			return;
		}
	}
	array_add(&proc->blocks, b);
	b->index = proc->block_count++;
}

void ir_start_block(irProcedure *proc, irBlock *block) {
	proc->curr_block = block;
	if (block != nullptr) {
		ir_add_block_to_proc(proc, block);
	}
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

	if (is_type_slice(type)) {
		ast_node(cl, CompoundLit, value.value_compound);

		isize count = cl->elems.count;
		if (count == 0) {
			return ir_value_nil(a, type);
		}
		Type *elem = base_type(type)->Slice.elem;
		Type *t = alloc_type_array(elem, count);
		irValue *backing_array = ir_add_module_constant(m, t, value);


		isize max_len = 7+8+1;
		u8 *str = cast(u8 *)gb_alloc_array(a, u8, max_len);
		isize len = gb_snprintf(cast(char *)str, max_len, "__csba$%x", m->global_array_index);
		m->global_array_index++;

		String name = make_string(str, len-1);

		Entity *e = alloc_entity_constant(nullptr, make_token_ident(name), t, value);
		irValue *g = ir_value_global(a, e, backing_array);
		ir_module_add_value(m, e, g);
		map_set(&m->members, hash_string(name), g);

		return ir_value_constant_slice(a, type, g, count);
	}

	return ir_value_constant(a, type, value);
}

irValue *ir_add_global_string_array(irModule *m, String string) {
	// TODO(bill): Should this use the arena allocator or the heap allocator?
	// Strings could be huge!
	// gbAllocator a = m->allocator;
	gbAllocator a = heap_allocator();

	isize max_len = 6+8+1;
	u8 *str = cast(u8 *)gb_alloc_array(a, u8, max_len);
	isize len = gb_snprintf(cast(char *)str, max_len, "__str$%x", m->global_string_index);
	m->global_string_index++;

	String name = make_string(str, len-1);
	Token token = {Token_String};
	token.string = name;
	Type *type = alloc_type_array(t_u8, string.len+1);
	ExactValue ev = exact_value_string(string);
	Entity *entity = alloc_entity_constant(nullptr, token, type, ev);
	irValue *g = ir_value_global(a, entity, ir_add_module_constant(m, type, ev));
	g->Global.is_private      = true;
	g->Global.is_unnamed_addr = true;
	// g->Global.is_constant = true;

	ir_module_add_value(m, entity, g);
	map_set(&m->members, hash_string(name), g);

	return g;
}

void ir_add_foreign_library_path(irModule *m, Entity *e) {
	GB_ASSERT(e != nullptr);
	GB_ASSERT(e->kind == Entity_LibraryName);
	GB_ASSERT(e->LibraryName.used);

	String library_path = e->LibraryName.path;
	if (library_path.len == 0) {
		return;
	}

	for_array(path_index, m->foreign_library_paths) {
		String path = m->foreign_library_paths[path_index];
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





irValue *ir_add_local(irProcedure *proc, Entity *e, AstNode *expr, bool zero_initialized) {
	irBlock *b = proc->decl_block; // all variables must be in the first block
	irValue *instr = ir_instr_local(proc, e, true);
	instr->Instr.block = b;
	array_add(&b->instrs, instr);
	array_add(&b->locals, instr);
	proc->local_count++;

	if (zero_initialized) {
		ir_emit_zero_init(proc, instr, expr);
	}

	if (expr != nullptr && proc->entity != nullptr) {
		irDebugInfo *di = *map_get(&proc->module->debug_info, hash_entity(proc->entity));
		ir_emit(proc, ir_instr_debug_declare(proc, di, expr, e, true, instr));
	}

	return instr;
}

irValue *ir_add_local_for_identifier(irProcedure *proc, AstNode *ident, bool zero_initialized) {
	Entity *e = entity_of_ident(proc->module->info, ident);
	if (e != nullptr) {
		String name = e->token.string;
		ir_emit_comment(proc, name);
		if (e->kind == Entity_Variable &&
		    e->Variable.is_foreign) {
			HashKey key = hash_string(name);
			irValue **prev_value = map_get(&proc->module->members, key);
			if (prev_value == nullptr) {
				ir_add_foreign_library_path(proc->module, e->Variable.foreign_library);
				// NOTE(bill): Don't do mutliple declarations in the IR
				irValue *g = ir_value_global(proc->module->allocator, e, nullptr);
				g->Global.name = name;
				g->Global.is_foreign = true;
				ir_module_add_value(proc->module, e, g);
				map_set(&proc->module->members, key, g);
				return g;
			} else {
				return *prev_value;
			}
		}
		return ir_add_local(proc, e, ident, zero_initialized);
	}
	return nullptr;
}

irValue *ir_add_local_generated(irProcedure *proc, Type *type, bool zero_initialized = true) {
	GB_ASSERT(type != nullptr);
	type = default_type(type);

	Scope *scope = nullptr;
	if (proc->curr_block) {
		scope = proc->curr_block->scope;
	}
	Entity *e = alloc_entity_variable(scope, empty_token, type, false);
	return ir_add_local(proc, e, nullptr, zero_initialized);
}


irValue *ir_add_global_generated(irModule *m, Type *type, irValue *value) {
	GB_ASSERT(type != nullptr);
	type = default_type(type);

	gbAllocator a = m->allocator;

	isize max_len = 7+8+1;
	u8 *str = cast(u8 *)gb_alloc_array(a, u8, max_len);
	isize len = gb_snprintf(cast(char *)str, max_len, "__ggv$%x", m->global_generated_index);
	m->global_generated_index++;
	String name = make_string(str, len-1);

	Scope *scope = nullptr;
	Entity *e = alloc_entity_variable(scope, make_token_ident(name), type, false);
	irValue *g = ir_value_global(a, e, value);
	ir_module_add_value(m, e, g);
	map_set(&m->members, hash_string(name), g);
	return g;
}


irValue *ir_add_param(irProcedure *proc, Entity *e, AstNode *expr, Type *abi_type) {
	irValue *v = ir_value_param(proc->module->allocator, proc, e, abi_type);
	irValueParam *p = &v->Param;

	switch (p->kind) {
	case irParamPass_Value: {
		irValue *l = ir_add_local(proc, e, expr, false);
		irValue *x = v;
		if (abi_type == t_llvm_bool) {
			x = ir_emit_conv(proc, x, t_bool);
		}
		ir_emit_store(proc, l, x);
		return x;
	}
	case irParamPass_Pointer:
		ir_module_add_value(proc->module, e, v);
		return ir_emit_load(proc, v);

	case irParamPass_Integer: {
		irValue *l = ir_add_local(proc, e, expr, false);
		irValue *iptr = ir_emit_conv(proc, l, alloc_type_pointer(p->type));
		ir_emit_store(proc, iptr, v);
		return ir_emit_load(proc, l);
	}

	case irParamPass_ConstRef:
		ir_module_add_value(proc->module, e, v);
		return ir_emit_load(proc, v);
	}

	GB_PANIC("Unreachable");
	return nullptr;
}



////////////////////////////////////////////////////////////////
//
// @Debug
//
////////////////////////////////////////////////////////////////

irDebugInfo *ir_add_debug_info_file(irProcedure *proc, AstFile *file) {
	// if (!proc->module->generate_debug_info) {
	// 	return nullptr;
	// }

	GB_ASSERT(file != nullptr);
	irDebugInfo *di = ir_alloc_debug_info(proc->module->allocator, irDebugInfo_File);
	di->File.file = file;

	String filename = file->tokenizer.fullpath;
	String directory = filename;
	isize slash_index = 0;
	for (isize i = filename.len-1; i >= 0; i--) {
		if (filename[i] == '\\' ||
		    filename[i] == '/') {
			break;
		}
		slash_index = i;
	}
	directory.len = slash_index-1;
	filename.text = filename.text + slash_index;
	filename.len -= slash_index;


	di->File.filename = filename;
	di->File.directory = directory;

	map_set(&proc->module->debug_info, hash_ast_file(file), di);
	return di;
}


irDebugInfo *ir_add_debug_info_proc(irProcedure *proc, Entity *entity, String name, irDebugInfo *file) {
	// if (!proc->module->generate_debug_info) {
	// 	return nullptr;
	// }

	GB_ASSERT(entity != nullptr);
	irDebugInfo *di = ir_alloc_debug_info(proc->module->allocator, irDebugInfo_Proc);
	di->Proc.entity = entity;
	di->Proc.name = name;
	di->Proc.file = file;
	di->Proc.pos = entity->token.pos;

	proc->debug_scope = di;

	map_set(&proc->module->debug_info, hash_entity(entity), di);
	return di;
}

////////////////////////////////////////////////////////////////
//
// @Emit
//
////////////////////////////////////////////////////////////////

irValue *ir_emit_global_call(irProcedure *proc, char const *name_, Array<irValue *> args, AstNode *expr = nullptr);

irValue *ir_emit_store(irProcedure *p, irValue *address, irValue *value) {
	Type *a = type_deref(ir_type(address));

	if (is_type_boolean(a)) {
		// NOTE(bill): There are multiple sized booleans, thus force a conversion (if necessarily)
		value = ir_emit_conv(p, value, a);
	}

	Type *b = ir_type(value);
	if (!is_type_untyped(b)) {
		GB_ASSERT_MSG(are_types_identical(core_type(a), core_type(b)), "%s %s", type_to_string(a), type_to_string(b));
	}
	return ir_emit(p, ir_instr_store(p, address, value, false));
}
irValue *ir_emit_load(irProcedure *p, irValue *address) {
	GB_ASSERT(address != nullptr);
	Type *t = type_deref(ir_type(address));
	// if (is_type_boolean(t)) {
		// return ir_emit(p, ir_instr_load_bool(p, address));
	// }
	return ir_emit(p, ir_instr_load(p, address));
}
irValue *ir_emit_select(irProcedure *p, irValue *cond, irValue *t, irValue *f) {
	return ir_emit(p, ir_instr_select(p, cond, t, f));
}

void ir_add_debug_location_to_value(irProcedure *proc, irValue *v, AstNode *e) {
	if (v != nullptr && e != nullptr) {
		v->loc.debug_scope = proc->debug_scope;
		v->loc.pos = ast_node_token(e).pos;
	}
}

void ir_emit_zero_init(irProcedure *p, irValue *address, AstNode *expr) {
	gbAllocator a = p->module->allocator;
	Type *t = type_deref(ir_type(address));
	auto args = array_make<irValue *>(a, 2);
	args[0] = ir_emit_conv(p, address, t_rawptr);
	args[1] = ir_const_int(a, type_size_of(t));
	if (p->entity->token.string != "__mem_zero") {
		ir_emit_global_call(p, "__mem_zero", args, expr);
	}
	ir_emit(p, ir_instr_zero_init(p, address));
}

irValue *ir_emit_comment(irProcedure *p, String text) {
	return ir_emit(p, ir_instr_comment(p, text));
}

void ir_emit_init_context(irProcedure *proc, irValue *c = nullptr) {
	irModule *m = proc->module;
	gbAllocator a = m->allocator;
	auto args = array_make<irValue *>(a, 1);
	args[0] = c ? c : m->global_default_context;
	ir_emit_global_call(proc, "__init_context", args);
}






irValue *ir_copy_value_to_ptr(irProcedure *proc, irValue *val, Type *new_type, i64 alignment) {
	i64 type_alignment = type_align_of(new_type);
	if (alignment < type_alignment) {
		alignment = type_alignment;
	}
	irValue *ptr = ir_add_local_generated(proc, new_type);
	ptr->Instr.Local.alignment = alignment;
	ir_emit_store(proc, ptr, val);
	return ptr;
}

irValue *ir_emit_bitcast(irProcedure *proc, irValue *data, Type *type) {
	return ir_emit(proc, ir_instr_conv(proc, irConv_bitcast, data, ir_type(data), type));
}

irValue *ir_emit_transmute(irProcedure *proc, irValue *value, Type *t);
irValue *ir_address_from_load_or_generate_local(irProcedure *proc, irValue *val);
irValue *ir_emit_struct_ep(irProcedure *proc, irValue *s, i32 index);


irValue *ir_find_or_generate_context_ptr(irProcedure *proc) {
	if (proc->context_stack.count > 0) {
		return proc->context_stack[proc->context_stack.count-1];
	}

	irBlock *tmp_block = proc->curr_block;
	proc->curr_block = proc->blocks[0];

	defer (proc->curr_block = tmp_block);

	irValue *c = ir_add_local_generated(proc, t_context);
	array_add(&proc->context_stack, c);
	ir_emit_store(proc, c, ir_emit_load(proc, proc->module->global_default_context));

	irValue *ep = ir_emit_struct_ep(proc, c, 0);
	Array<irValue *> args = {};
	irValue *v = ir_emit_global_call(proc, "default_allocator", args);
	ir_emit_store(proc, ep, v);

	return c;
}


irValue *ir_emit_call(irProcedure *p, irValue *value, Array<irValue *> args) {
	Type *pt = base_type(ir_type(value));
	GB_ASSERT(pt->kind == Type_Proc);
	Type *results = pt->Proc.results;

	irValue *context_ptr = nullptr;
	if (pt->Proc.calling_convention == ProcCC_Odin) {
		context_ptr = ir_find_or_generate_context_ptr(p);
	}

	bool is_c_vararg = pt->Proc.c_vararg;
	isize param_count = pt->Proc.param_count;
	if (is_c_vararg) {
		GB_ASSERT(param_count-1 <= args.count);
		param_count -= 1;
	} else {
		GB_ASSERT_MSG(param_count == args.count, "%td == %td", param_count, args.count);
	}
	for (isize i = 0; i < param_count; i++) {
		Entity *e = pt->Proc.params->Tuple.variables[i];
		if (e->kind != Entity_Variable) {
			continue;
		}
		GB_ASSERT(e->flags & EntityFlag_Param);

		Type *original_type = e->type;
		Type *new_type = pt->Proc.abi_compat_params[i];
		if (original_type != new_type) {
			if (is_type_pointer(new_type)) {
				if (e->flags&EntityFlag_Value) {
					args[i] = ir_address_from_load_or_generate_local(p, args[i]);
				} else {
					args[i] = ir_copy_value_to_ptr(p, args[i], original_type, 16);
				}
			} else if (is_type_integer(new_type)) {
				args[i] = ir_emit_transmute(p, args[i], new_type);
			} else if (new_type == t_llvm_bool) {
				args[i] = ir_emit_conv(p, args[i], new_type);
			}
		}
	}

	Type *abi_rt = pt->Proc.abi_compat_result_type;
	Type *rt = reduce_tuple_to_single_type(results);
	if (pt->Proc.return_by_pointer) {
		irValue *return_ptr = ir_add_local_generated(p, rt);
		GB_ASSERT(is_type_pointer(ir_type(return_ptr)));
		ir_emit(p, ir_instr_call(p, value, return_ptr, args, nullptr, context_ptr));
		return ir_emit_load(p, return_ptr);
	}

	irValue *result = ir_emit(p, ir_instr_call(p, value, nullptr, args, abi_rt, context_ptr));
	if (abi_rt != results) {
		result = ir_emit_transmute(p, result, rt);
	}
	return result;
}

irValue *ir_emit_global_call(irProcedure *proc, char const *name_, Array<irValue *> args, AstNode *expr) {
	String name = make_string_c(cast(char *)name_);
	irValue **found = map_get(&proc->module->members, hash_string(name));
	GB_ASSERT_MSG(found != nullptr, "%.*s", LIT(name));
	irValue *gp = *found;
	irValue *call = ir_emit_call(proc, gp, args);
	ir_add_debug_location_to_value(proc, call, expr);
	return call;
}



void ir_emit_defer_stmts(irProcedure *proc, irDeferExitKind kind, irBlock *block) {
	isize count = proc->defer_stmts.count;
	isize i = count;
	while (i --> 0) {
		irDefer d = proc->defer_stmts[i];
		if (kind == irDeferExit_Default) {
			if (proc->scope_index == d.scope_index &&
			    d.scope_index > 0) { // TODO(bill): Which is correct: > 0 or > 1?
				ir_build_defer_stmt(proc, d);
				array_pop(&proc->defer_stmts);
				continue;
			} else {
				break;
			}
		} else if (kind == irDeferExit_Return) {
			ir_build_defer_stmt(proc, d);
		} else if (kind == irDeferExit_Branch) {
			GB_ASSERT(block != nullptr);
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
	ir_emit(proc, ir_instr_unreachable(proc));
}

void ir_emit_return(irProcedure *proc, irValue *v) {
	ir_emit_defer_stmts(proc, irDeferExit_Return, nullptr);

	if (proc->type->Proc.return_by_pointer) {
		ir_emit_store(proc, proc->return_ptr, v);
		ir_emit(proc, ir_instr_return(proc, nullptr));
	} else {
		Type *abi_rt = proc->type->Proc.abi_compat_result_type;
		if (abi_rt != proc->type->Proc.results) {
			v = ir_emit_transmute(proc, v, abi_rt);
		}

		ir_emit(proc, ir_instr_return(proc, v));
	}
}

void ir_emit_jump(irProcedure *proc, irBlock *target_block) {
	irBlock *b = proc->curr_block;
	if (b == nullptr) {
		return;
	}
	ir_emit(proc, ir_instr_jump(proc, target_block));
	ir_add_edge(b, target_block);
	ir_start_block(proc, nullptr);
}

void ir_emit_if(irProcedure *proc, irValue *cond, irBlock *true_block, irBlock *false_block) {
	irBlock *b = proc->curr_block;
	if (b == nullptr) {
		return;
	}
	ir_emit(proc, ir_instr_if(proc, cond, true_block, false_block));
	ir_add_edge(b, true_block);
	ir_add_edge(b, false_block);
	ir_start_block(proc, nullptr);
}




irValue *ir_emit_comp(irProcedure *proc, TokenKind op_kind, irValue *left, irValue *right);

irValue *ir_gen_map_header(irProcedure *proc, irValue *map_val_ptr, Type *map_type) {
	GB_ASSERT_MSG(is_type_pointer(ir_type(map_val_ptr)), "%s", type_to_string(ir_type(map_val_ptr)));
	gbAllocator a = proc->module->allocator;
	irValue *h = ir_add_local_generated(proc, t_map_header);
	map_type = base_type(map_type);

	Type *key_type = map_type->Map.key;
	Type *val_type = map_type->Map.value;

	// NOTE(bill): Removes unnecessary allocation if split gep
	irValue *gep0 = ir_emit_struct_ep(proc, h, 0);
	irValue *m = ir_emit_conv(proc, map_val_ptr, type_deref(ir_type(gep0)));
	ir_emit_store(proc, gep0, m);

	if (is_type_string(key_type)) {
		ir_emit_store(proc, ir_emit_struct_ep(proc, h, 1), v_true);
	}

	i64 entry_size   = type_size_of  (map_type->Map.entry_type);
	i64 entry_align  = type_align_of (map_type->Map.entry_type);
	i64 value_offset = type_offset_of(map_type->Map.entry_type, 2);
	i64 value_size   = type_size_of  (map_type->Map.value);

	ir_emit_store(proc, ir_emit_struct_ep(proc, h, 2), ir_const_int(a, entry_size));
	ir_emit_store(proc, ir_emit_struct_ep(proc, h, 3), ir_const_int(a, entry_align));
	ir_emit_store(proc, ir_emit_struct_ep(proc, h, 4), ir_const_uintptr(a, value_offset));
	ir_emit_store(proc, ir_emit_struct_ep(proc, h, 5), ir_const_int(a, value_size));


	return ir_emit_load(proc, h);
}

irValue *ir_gen_map_key(irProcedure *proc, irValue *key, Type *key_type) {
	Type *hash_type = t_u64;
	irValue *v = ir_add_local_generated(proc, t_map_key);
	Type *t = base_type(ir_type(key));
	key = ir_emit_conv(proc, key, key_type);
	if (is_type_integer(t)) {
		ir_emit_store(proc, ir_emit_struct_ep(proc, v, 0), ir_emit_conv(proc, key, hash_type));
	} else if (is_type_pointer(t)) {
		irValue *p = ir_emit_conv(proc, key, t_uintptr);
		ir_emit_store(proc, ir_emit_struct_ep(proc, v, 0), ir_emit_conv(proc, p, hash_type));
	} else if (is_type_float(t)) {
		irValue *bits = nullptr;
		i64 size = type_size_of(t);
		switch (8*size) {
		case 32:  bits = ir_emit_transmute(proc, key, t_u32); break;
		case 64:  bits = ir_emit_transmute(proc, key, t_u64);  break;
		default: GB_PANIC("Unhandled float size: %lld bits", size); break;
		}

		ir_emit_store(proc, ir_emit_struct_ep(proc, v, 0), ir_emit_conv(proc, bits, hash_type));
	} else if (is_type_string(t)) {
		irValue *str = ir_emit_conv(proc, key, t_string);
		irValue *hashed_str = nullptr;

		if (str->kind == irValue_Constant) {
			ExactValue ev = str->Constant.value;
			GB_ASSERT(ev.kind == ExactValue_String);
			u64 hs = fnv64a(ev.value_string.text, ev.value_string.len);
			hashed_str = ir_value_constant(proc->module->allocator, t_u64, exact_value_u64(hs));
		} else {
			auto args = array_make<irValue *>(proc->module->allocator, 1);
			args[0] = str;
			hashed_str = ir_emit_global_call(proc, "__default_hash_string", args);
		}
		ir_emit_store(proc, ir_emit_struct_ep(proc, v, 0), hashed_str);
		ir_emit_store(proc, ir_emit_struct_ep(proc, v, 1), str);
	} else {
		GB_PANIC("Unhandled map key type");
	}

	return ir_emit_load(proc, v);
}

// NOTE(bill): Returns nullptr if not possible
irValue *ir_address_from_load_or_generate_local(irProcedure *proc, irValue *val) {
	if (val->kind == irValue_Instr) {
		if (val->Instr.kind == irInstr_Load) {
			return val->Instr.Load.address;
		}
	}
	Type *type = ir_type(val);
	irValue *local = ir_add_local_generated(proc, type);
	ir_emit_store(proc, local, val);
	return local;
}


Type *ir_addr_type(irAddr addr) {
	if (addr.addr == nullptr) {
		return nullptr;
	}

	if (addr.kind == irAddr_Map) {
		Type *t = base_type(addr.map_type);
		GB_ASSERT(is_type_map(t));
		return t->Map.value;
	}

	Type *t = ir_type(addr.addr);
	GB_ASSERT(is_type_pointer(t));
	return type_deref(t);
}

irValue *ir_emit_source_code_location(irProcedure *proc, String procedure, TokenPos pos);
irValue *ir_emit_source_code_location(irProcedure *proc, AstNode *node);
irValue *ir_emit_ptr_offset(irProcedure *proc, irValue *ptr, irValue *offset);
irValue *ir_emit_arith(irProcedure *proc, TokenKind op, irValue *left, irValue *right, Type *type);

irValue *ir_insert_dynamic_map_key_and_value(irProcedure *proc, irValue *addr, Type *map_type,
                                             irValue *map_key, irValue *map_value) {
	map_type = base_type(map_type);

	irValue *h = ir_gen_map_header(proc, addr, map_type);
	irValue *key = ir_gen_map_key(proc, map_key, map_type->Map.key);
	irValue *v = ir_emit_conv(proc, map_value, map_type->Map.value);

	irValue *ptr = ir_add_local_generated(proc, ir_type(v));
	ir_emit_store(proc, ptr, v);

	auto args = array_make<irValue *>(proc->module->allocator, 4);
	args[0] = h;
	args[1] = key;
	args[2] = ir_emit_conv(proc, ptr, t_rawptr);
	args[3] = ir_emit_source_code_location(proc, nullptr);
	return ir_emit_global_call(proc, "__dynamic_map_set", args);
}



irValue *ir_addr_store(irProcedure *proc, irAddr addr, irValue *value) {
	if (addr.addr == nullptr) {
		return nullptr;
	}
	if (addr.kind == irAddr_Map) {
		return ir_insert_dynamic_map_key_and_value(proc, addr.addr, addr.map_type, addr.map_key, value);
	} else if (addr.kind == irAddr_BitField) {
		gbAllocator a = proc->module->allocator;

		Type *bft = base_type(type_deref(ir_type(addr.addr)));
		GB_ASSERT(is_type_bit_field(bft));
		i32 value_index = addr.bit_field_value_index;
		i32 offset = bft->BitField.offsets[value_index];
		i32 size_in_bits = bft->BitField.fields[value_index]->type->BitFieldValue.bits;

		i32 byte_index = offset / 8;
		i32 bit_inset = offset % 8;

		i32 size_in_bytes = next_pow2((size_in_bits+7)/8);
		if (size_in_bytes == 0) {
			GB_ASSERT(size_in_bits == 0);
			return nullptr;
		}

		Type *int_type = nullptr;
		switch (size_in_bytes) {
		case 1:  int_type = t_u8;   break;
		case 2:  int_type = t_u16;  break;
		case 4:  int_type = t_u32;  break;
		case 8:  int_type = t_u64;  break;
		}
		GB_ASSERT(int_type != nullptr);

		value = ir_emit_conv(proc, value, int_type);

		irValue *bytes = ir_emit_conv(proc, addr.addr, t_u8_ptr);
		bytes = ir_emit_ptr_offset(proc, bytes, ir_const_int(a, byte_index));


		if (bit_inset == 0) {
			irValue *v = value;
			i32 sa = 8*size_in_bytes - size_in_bits;
			if (sa > 0) {
				irValue *shift_amount = ir_const_int(a, sa);
				v = ir_emit_arith(proc, Token_Shl, v, shift_amount, int_type);
				v = ir_emit_arith(proc, Token_Shr, v, shift_amount, int_type);
			}
			irValue *ptr = ir_emit_conv(proc, bytes, alloc_type_pointer(int_type));
			v = ir_emit_arith(proc, Token_Or, ir_emit_load(proc, ptr), v, int_type);
			return ir_emit_store(proc, ptr, v);
		}


		// First byte
		{
			i32 sa = 8 - bit_inset;
			irValue *shift_amount = ir_const_int(a, sa);
			irValue *v = ir_emit_conv(proc, value, t_u8);
			v = ir_emit_arith(proc, Token_Shl, v, shift_amount, int_type);
			v = ir_emit_arith(proc, Token_Or, ir_emit_load(proc, bytes), v, int_type);
			ir_emit_store(proc, bytes, v);

		}

		// Remaining bytes
		{
			irValue *shift_amount = ir_const_int(a, bit_inset);
			irValue *ptr = ir_emit_conv(proc, ir_emit_ptr_offset(proc, bytes, v_one), alloc_type_pointer(int_type));
			irValue *v = ir_emit_arith(proc, Token_Shr, value, shift_amount, int_type);
			v = ir_emit_arith(proc, Token_Or, ir_emit_load(proc, ptr), v, int_type);
			return ir_emit_store(proc, ptr, v);
		}
	}

	irValue *v = ir_emit_conv(proc, value, ir_addr_type(addr));
	return ir_emit_store(proc, addr.addr, v);
}

irValue *ir_addr_load(irProcedure *proc, irAddr addr) {
	if (addr.addr == nullptr) {
		GB_PANIC("Illegal addr load");
		return nullptr;
	}

	if (addr.kind == irAddr_Map) {
		// TODO(bill): map lookup
		Type *map_type = base_type(addr.map_type);
		irValue *v = ir_add_local_generated(proc, map_type->Map.lookup_result_type);
		irValue *h = ir_gen_map_header(proc, addr.addr, map_type);
		irValue *key = ir_gen_map_key(proc, addr.map_key, map_type->Map.key);

		auto args = array_make<irValue *>(proc->module->allocator, 2);
		args[0] = h;
		args[1] = key;

		irValue *ptr = ir_emit_global_call(proc, "__dynamic_map_get", args);
		irValue *ok = ir_emit_conv(proc, ir_emit_comp(proc, Token_NotEq, ptr, v_raw_nil), t_bool);
		ir_emit_store(proc, ir_emit_struct_ep(proc, v, 1), ok);

		irBlock *then = ir_new_block(proc, nullptr, "map.get.then");
		irBlock *done = ir_new_block(proc, nullptr, "map.get.done");
		ir_emit_if(proc, ok, then, done);
		ir_start_block(proc, then);
		{
			// TODO(bill): mem copy it instead?
			irValue *gep0 = ir_emit_struct_ep(proc, v, 0);
			irValue *value = ir_emit_conv(proc, ptr, ir_type(gep0));
			ir_emit_store(proc, gep0, ir_emit_load(proc, value));
		}
		ir_emit_jump(proc, done);
		ir_start_block(proc, done);


		if (is_type_tuple(addr.map_result)) {
			return ir_emit_load(proc, v);
		} else {
			irValue *single = ir_emit_struct_ep(proc, v, 0);
			return ir_emit_load(proc, single);
		}
	} else if (addr.kind == irAddr_BitField) {
		gbAllocator a = proc->module->allocator;


		Type *bft = base_type(type_deref(ir_type(addr.addr)));
		GB_ASSERT(is_type_bit_field(bft));
		i32 value_index = addr.bit_field_value_index;
		i32 offset = bft->BitField.offsets[value_index];
		i32 size_in_bits = bft->BitField.fields[value_index]->type->BitFieldValue.bits;

		i32 byte_index = offset / 8;
		i32 bit_inset = offset % 8;

		i32 size_in_bytes = next_pow2((size_in_bits+7)/8);
		if (size_in_bytes == 0) {
			GB_ASSERT(size_in_bits == 0);
			return ir_const_i32(a, 0);
		}

		Type *int_type = nullptr;
		switch (size_in_bytes) {
		case 1:  int_type = t_u8;   break;
		case 2:  int_type = t_u16;  break;
		case 4:  int_type = t_u32;  break;
		case 8:  int_type = t_u64;  break;
		}
		GB_ASSERT(int_type != nullptr);


		irValue *bytes = ir_emit_conv(proc, addr.addr, t_u8_ptr);
		bytes = ir_emit_ptr_offset(proc, bytes, ir_const_int(a, byte_index));

		Type *int_ptr = alloc_type_pointer(int_type);

		if (bit_inset == 0) {
			irValue *v = ir_emit_load(proc, ir_emit_conv(proc, bytes, int_ptr));
			i32 sa = 8*size_in_bytes - size_in_bits;
			if (sa > 0) {
				irValue *shift_amount = ir_const_int(a, sa);
				v = ir_emit_arith(proc, Token_Shl, v, shift_amount, int_type);
				v = ir_emit_arith(proc, Token_Shr, v, shift_amount, int_type);
			}
			return v;
		}

		GB_ASSERT(8 > bit_inset);

		irValue *shift_amount = ir_value_constant(a, int_type, exact_value_i64(bit_inset));
		irValue *first_byte = ir_emit_load(proc, bytes);
		irValue *res = ir_emit_arith(proc, Token_Shr, first_byte, shift_amount, int_type);

		irValue *remaining_bytes = ir_emit_load(proc, ir_emit_conv(proc, ir_emit_ptr_offset(proc, bytes, v_one), int_ptr));
		remaining_bytes = ir_emit_arith(proc, Token_Shl, remaining_bytes, shift_amount, int_type);
		return ir_emit_arith(proc, Token_Or, res, remaining_bytes, int_type);

	}

	Type *t = base_type(ir_type(addr.addr));
	if (t->kind == Type_Proc) {
		// NOTE(bill): Imported procedures don't require a load as they are pointers
		return addr.addr;
	}
	return ir_emit_load(proc, addr.addr);
}

irValue *ir_addr_get_ptr(irProcedure *proc, irAddr addr) {
	if (addr.addr == nullptr) {
		GB_PANIC("Illegal addr -> nullptr");
		return nullptr;
	}

	switch (addr.kind) {
	case irAddr_Map:
	case irAddr_BitField: {
		irValue *v = ir_addr_load(proc, addr);
		return ir_address_from_load_or_generate_local(proc, v);
	}
	}

	return addr.addr;
}

irValue *ir_build_addr_ptr(irProcedure *proc, AstNode *expr) {
	irAddr addr = ir_build_addr(proc, expr);
	return ir_addr_get_ptr(proc, addr);
}


irValue *ir_dynamic_array_len(irProcedure *proc, irValue *da);
irValue *ir_dynamic_array_cap(irProcedure *proc, irValue *da);


irValue *ir_map_entries(irProcedure *proc, irValue *value) {
	gbAllocator a = proc->module->allocator;
	Type *t = base_type(ir_type(value));
	GB_ASSERT_MSG(t->kind == Type_Map, "%s", type_to_string(t));
	init_map_internal_types(t);
	Type *gst = t->Map.generated_struct_type;
	isize index = 1;
	irValue *entries = ir_emit(proc, ir_instr_struct_extract_value(proc, value, index, gst->Struct.fields[index]->type));
	return entries;
}

irValue *ir_map_entries_ptr(irProcedure *proc, irValue *value) {
	gbAllocator a = proc->module->allocator;
	Type *t = base_type(type_deref(ir_type(value)));
	GB_ASSERT_MSG(t->kind == Type_Map, "%s", type_to_string(t));
	init_map_internal_types(t);
	Type *gst = t->Map.generated_struct_type;
	isize index = 1;
	Type *ptr_t = alloc_type_pointer(gst->Struct.fields[index]->type);
	irValue *entries = ir_emit(proc, ir_instr_struct_element_ptr(proc, value, index, ptr_t));
	return entries;
}

irValue *ir_map_len(irProcedure *proc, irValue *value) {
	irValue *entries = ir_map_entries(proc, value);
	return ir_dynamic_array_len(proc, entries);
}

irValue *ir_map_cap(irProcedure *proc, irValue *value) {
	irValue *entries = ir_map_entries(proc, value);
	return ir_dynamic_array_cap(proc, entries);
}



irValue *ir_emit_array_epi(irProcedure *proc, irValue *s, i32 index);
irValue *ir_emit_struct_ev(irProcedure *proc, irValue *s, i32 index);

irValue *ir_emit_ptr_offset(irProcedure *proc, irValue *ptr, irValue *offset) {
	offset = ir_emit_conv(proc, offset, t_int);
	return ir_emit(proc, ir_instr_ptr_offset(proc, ptr, offset));
}

irValue *ir_emit_unary_arith(irProcedure *proc, TokenKind op, irValue *x, Type *type) {
	switch (op) {
	case Token_Add:
		return x;
	case Token_Not: // Boolean not
	case Token_Xor: // Bitwise not
	case Token_Sub: // Bitwise Not
		break;
	case Token_Pointer:
		GB_PANIC("This should be handled elsewhere");
		break;
	}

	if (is_type_array(ir_type(x))) {
		ir_emit_comment(proc, str_lit("array.arith.begin"));
		// IMPORTANT TODO(bill): This is very wasteful with regards to stack memory
		Type *tl = base_type(ir_type(x));
		irValue *val = ir_address_from_load_or_generate_local(proc, x);
		GB_ASSERT(is_type_array(type));
		Type *elem_type = base_array_type(type);

		irValue *res = ir_add_local_generated(proc, type);
		for (i32 i = 0; i < tl->Array.count; i++) {
			irValue *e = ir_emit_load(proc, ir_emit_array_epi(proc, val, i));
			irValue *z = ir_emit_unary_arith(proc, op, e, elem_type);
			ir_emit_store(proc, ir_emit_array_epi(proc, res, i), z);
		}
		ir_emit_comment(proc, str_lit("array.arith.end"));
		return ir_emit_load(proc, res);

	}

	return ir_emit(proc, ir_instr_unary_op(proc, op, x, type));
}



irValue *ir_emit_arith(irProcedure *proc, TokenKind op, irValue *left, irValue *right, Type *type) {
	Type *t_left = ir_type(left);
	Type *t_right = ir_type(right);

	if (is_type_array(t_left) || is_type_array(t_right)) {
		ir_emit_comment(proc, str_lit("array.arith.begin"));
		// IMPORTANT TODO(bill): This is very wasteful with regards to stack memory
		left  = ir_emit_conv(proc, left, type);
		right = ir_emit_conv(proc, right, type);
		irValue *lhs = ir_address_from_load_or_generate_local(proc, left);
		irValue *rhs = ir_address_from_load_or_generate_local(proc, right);
		GB_ASSERT(is_type_array(type));
		Type *elem_type = base_array_type(type);

		irValue *res = ir_add_local_generated(proc, type);
		i64 count = base_type(type)->Array.count;
		for (i32 i = 0; i < count; i++) {
			irValue *x = ir_emit_load(proc, ir_emit_array_epi(proc, lhs, i));
			irValue *y = ir_emit_load(proc, ir_emit_array_epi(proc, rhs, i));
			irValue *z = ir_emit_arith(proc, op, x, y, elem_type);
			ir_emit_store(proc, ir_emit_array_epi(proc, res, i), z);
		}
		ir_emit_comment(proc, str_lit("array.arith.end"));
		return ir_emit_load(proc, res);
	}

	if (is_type_complex(t_left)) {
		ir_emit_comment(proc, str_lit("complex.arith.begin"));
		Type *ft = base_complex_elem_type(t_left);

		irValue *res = ir_add_local_generated(proc, type);
		irValue *a = ir_emit_struct_ev(proc, left,  0);
		irValue *b = ir_emit_struct_ev(proc, left,  1);
		irValue *c = ir_emit_struct_ev(proc, right, 0);
		irValue *d = ir_emit_struct_ev(proc, right, 1);

		irValue *real = nullptr;
		irValue *imag = nullptr;

		switch (op) {
		case Token_Add:
			real = ir_emit_arith(proc, Token_Add, a, c, ft);
			imag = ir_emit_arith(proc, Token_Add, b, d, ft);
			break;
		case Token_Sub:
			real = ir_emit_arith(proc, Token_Sub, a, c, ft);
			imag = ir_emit_arith(proc, Token_Sub, b, d, ft);
			break;
		case Token_Mul: {
			irValue *x = ir_emit_arith(proc, Token_Mul, a, c, ft);
			irValue *y = ir_emit_arith(proc, Token_Mul, b, d, ft);
			real = ir_emit_arith(proc, Token_Sub, x, y, ft);
			irValue *z = ir_emit_arith(proc, Token_Mul, b, c, ft);
			irValue *w = ir_emit_arith(proc, Token_Mul, a, d, ft);
			imag = ir_emit_arith(proc, Token_Add, z, w, ft);
			break;
		}
		case Token_Quo: {
			irValue *s1 = ir_emit_arith(proc, Token_Mul, c, c, ft);
			irValue *s2 = ir_emit_arith(proc, Token_Mul, d, d, ft);
			irValue *s  = ir_emit_arith(proc, Token_Add, s1, s2, ft);

			irValue *x = ir_emit_arith(proc, Token_Mul, a, c, ft);
			irValue *y = ir_emit_arith(proc, Token_Mul, b, d, ft);
			real = ir_emit_arith(proc, Token_Add, x, y, ft);
			real = ir_emit_arith(proc, Token_Quo, real, s, ft);

			irValue *z = ir_emit_arith(proc, Token_Mul, b, c, ft);
			irValue *w = ir_emit_arith(proc, Token_Mul, a, d, ft);
			imag = ir_emit_arith(proc, Token_Sub, z, w, ft);
			imag = ir_emit_arith(proc, Token_Quo, imag, s, ft);
			break;
		}
		}

		ir_emit_store(proc, ir_emit_struct_ep(proc, res, 0), real);
		ir_emit_store(proc, ir_emit_struct_ep(proc, res, 1), imag);

		ir_emit_comment(proc, str_lit("complex.end.begin"));
		return ir_emit_load(proc, res);
	}


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
			irValue *offset = ir_emit_unary_arith(proc, Token_Sub, right, t_int);
			return ir_emit_ptr_offset(proc, ptr, offset);
		} else if (is_type_pointer(t_left) && is_type_pointer(t_right)) {
			GB_ASSERT(is_type_integer(type));
			irModule *m = proc->module;
			Type *ptr_type = base_type(t_left);
			GB_ASSERT(!is_type_rawptr(ptr_type));
			irValue *elem_size = ir_const_int(m->allocator, type_size_of(ptr_type->Pointer.elem));
			irValue *x = ir_emit_conv(proc, ir_emit_conv(proc, left, t_uintptr), type);
			irValue *y = ir_emit_conv(proc, ir_emit_conv(proc, right, t_uintptr), type);
			irValue *diff = ir_emit_arith(proc, op, x, y, type);
			return ir_emit_arith(proc, Token_Quo, diff, elem_size, type);
		}
	}


	switch (op) {
	case Token_Shl:
	case Token_Shr:
		left = ir_emit_conv(proc, left, type);
		right = ir_emit_conv(proc, right, type);

		break;

	case Token_AndNot: {
		// NOTE(bill): x &~ y == x & (~y) == x & (y ~ -1)
		// NOTE(bill): "not" 'x' == 'x' "xor" '-1'
		irValue *neg = ir_add_module_constant(proc->module, type, exact_value_i64(-1));
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
	case Token_ModMod:
	case Token_And:
	case Token_Or:
	case Token_Xor:
		left  = ir_emit_conv(proc, left, type);
		right = ir_emit_conv(proc, right, type);
		break;
	}

	if (op == Token_ModMod) {
		irValue *n = left;
		irValue *m = right;
		if (is_type_unsigned(type)) {
			return ir_emit_arith(proc, Token_Mod, n, m, type);
		}
		irValue *a = ir_emit_arith(proc, Token_Mod, n, m, type);
		irValue *b = ir_emit_arith(proc, Token_Add, a, m, type);
		return ir_emit_arith(proc, Token_Mod, b, m, type);
	}

	return ir_emit(proc, ir_instr_binary_op(proc, op, left, right, type));
}

irValue *ir_emit_union_tag_ptr(irProcedure *proc, irValue *u) {
	Type *t = ir_type(u);
	GB_ASSERT_MSG(is_type_pointer(t) &&
	              is_type_union(type_deref(t)), "%s", type_to_string(t));
	irValue *tag_ptr = ir_emit(proc, ir_instr_union_tag_ptr(proc, u));
	return tag_ptr;
}

irValue *ir_emit_union_tag_value(irProcedure *proc, irValue *u) {
	Type *t = ir_type(u);
	GB_ASSERT(is_type_union(t));
	GB_ASSERT(are_types_identical(t, ir_type(u)));
	return ir_emit(proc, ir_instr_union_tag_value(proc, u));
}


irValue *ir_emit_comp_against_nil(irProcedure *proc, TokenKind op_kind, irValue *x) {
	Type *t = ir_type(x);
	if (is_type_cstring(t)) {
		irValue *ptr = ir_emit_conv(proc, x, t_u8_ptr);
		return ir_emit_comp(proc, op_kind, ptr, v_raw_nil);
	} else if (is_type_any(t)) {
		irValue *data = ir_emit_struct_ev(proc, x, 0);
		irValue *ti   = ir_emit_struct_ev(proc, x, 1);
		if (op_kind == Token_CmpEq) {
			irValue *a = ir_emit_comp(proc, Token_CmpEq, data, v_raw_nil);
			irValue *b = ir_emit_comp(proc, Token_CmpEq, ti, v_raw_nil);
			return ir_emit_arith(proc, Token_Or, a, b, t_bool);
		} else if (op_kind == Token_NotEq) {
			irValue *a = ir_emit_comp(proc, Token_NotEq, data, v_raw_nil);
			irValue *b = ir_emit_comp(proc, Token_NotEq, ti, v_raw_nil);
			return ir_emit_arith(proc, Token_And, a, b, t_bool);
		}
	} else if (is_type_slice(t)) {
		irValue *data = ir_emit_struct_ev(proc, x, 0);
		irValue *cap  = ir_emit_struct_ev(proc, x, 1);
		if (op_kind == Token_CmpEq) {
			irValue *a = ir_emit_comp(proc, Token_CmpEq, data, v_raw_nil);
			irValue *b = ir_emit_comp(proc, Token_CmpEq, cap, v_zero);
			return ir_emit_arith(proc, Token_Or, a, b, t_bool);
		} else if (op_kind == Token_NotEq) {
			irValue *a = ir_emit_comp(proc, Token_NotEq, data, v_raw_nil);
			irValue *b = ir_emit_comp(proc, Token_NotEq, cap, v_zero);
			return ir_emit_arith(proc, Token_And, a, b, t_bool);
		}
	} else if (is_type_dynamic_array(t)) {
		irValue *data = ir_emit_struct_ev(proc, x, 0);
		irValue *cap  = ir_emit_struct_ev(proc, x, 2);
		if (op_kind == Token_CmpEq) {
			irValue *a = ir_emit_comp(proc, Token_CmpEq, data, v_raw_nil);
			irValue *b = ir_emit_comp(proc, Token_CmpEq, cap, v_zero);
			return ir_emit_arith(proc, Token_Or, a, b, t_bool);
		} else if (op_kind == Token_NotEq) {
			irValue *a = ir_emit_comp(proc, Token_NotEq, data, v_raw_nil);
			irValue *b = ir_emit_comp(proc, Token_NotEq, cap, v_zero);
			return ir_emit_arith(proc, Token_And, a, b, t_bool);
		}
	} else if (is_type_map(t)) {
		irValue *len = ir_map_len(proc, x);
		return ir_emit_comp(proc, op_kind, len, v_zero);
	} else if (is_type_union(t)) {
		irValue *tag = ir_emit_union_tag_value(proc, x);
		return ir_emit_comp(proc, op_kind, tag, v_zero);
	}
	return nullptr;
}

irValue *ir_emit_comp(irProcedure *proc, TokenKind op_kind, irValue *left, irValue *right) {
	Type *a = base_type(ir_type(left));
	Type *b = base_type(ir_type(right));

	GB_ASSERT(gb_is_between(op_kind, Token__ComparisonBegin+1, Token__ComparisonEnd-1));

	irValue *nil_check = nullptr;
	if (left->kind == irValue_Nil) {
		nil_check = ir_emit_comp_against_nil(proc, op_kind, right);
	} else if (right->kind == irValue_Nil) {
		nil_check = ir_emit_comp_against_nil(proc, op_kind, left);
	}
	if (nil_check != nullptr) {
		return nil_check;
	}

	if (are_types_identical(a, b)) {
		// NOTE(bill): No need for a conversion
	} else if (left->kind == irValue_Constant || left->kind == irValue_Nil) {
		left = ir_emit_conv(proc, left, ir_type(right));
	} else if (right->kind == irValue_Constant || right->kind == irValue_Nil) {
		right = ir_emit_conv(proc, right, ir_type(left));
	} else {
		gbAllocator a = proc->module->allocator;
		i64 ls = type_size_of(ir_type(left));
		i64 rs = type_size_of(ir_type(right));
		if (ls < rs) {
			left = ir_emit_conv(proc, left, ir_type(right));
		} else if (ls > rs) {
			right = ir_emit_conv(proc, right, ir_type(left));
		} else {
			right = ir_emit_conv(proc, right, ir_type(left));
		}
	}

	if (is_type_array(a)) {
		ir_emit_comment(proc, str_lit("array.comp.begin"));
		defer (ir_emit_comment(proc, str_lit("array.comp.end")));

		Type *tl = base_type(a);
		irValue *lhs = ir_address_from_load_or_generate_local(proc, left);
		irValue *rhs = ir_address_from_load_or_generate_local(proc, right);


		TokenKind cmp_op = Token_And;
		irValue *res = v_true;
		if (op_kind == Token_NotEq) {
			res = v_false;
			cmp_op = Token_Or;
		}

		// IMPORTANT TODO(bill): Make this much more efficient
		for (i32 i = 0; i < tl->Array.count; i++) {
			irValue *x = ir_emit_load(proc, ir_emit_array_epi(proc, lhs, i));
			irValue *y = ir_emit_load(proc, ir_emit_array_epi(proc, rhs, i));
			irValue *cmp = ir_emit_comp(proc, op_kind, x, y);
			res = ir_emit_arith(proc, cmp_op, res, cmp, t_bool);
		}

		return ir_emit_conv(proc, res, t_bool);
	}

	if (is_type_string(a)) {
		char *runtime_proc = nullptr;
		switch (op_kind) {
		case Token_CmpEq: runtime_proc = "__string_eq"; break;
		case Token_NotEq: runtime_proc = "__string_ne"; break;
		case Token_Lt:    runtime_proc = "__string_lt"; break;
		case Token_Gt:    runtime_proc = "__string_gt"; break;
		case Token_LtEq:  runtime_proc = "__string_le"; break;
		case Token_GtEq:  runtime_proc = "__string_gt"; break;
		}
		GB_ASSERT(runtime_proc != nullptr);

		auto args = array_make<irValue *>(proc->module->allocator, 2);
		args[0] = left;
		args[1] = right;
		return ir_emit_global_call(proc, runtime_proc, args);
	}

	if (is_type_complex(a)) {
		char *runtime_proc = "";
		i64 sz = 8*type_size_of(a);
		switch (sz) {
		case 64:
			switch (op_kind) {
			case Token_CmpEq: runtime_proc = "__complex64_eq"; break;
			case Token_NotEq: runtime_proc = "__complex64_ne"; break;
			}
			break;
		case 128:
			switch (op_kind) {
			case Token_CmpEq: runtime_proc = "__complex128_eq"; break;
			case Token_NotEq: runtime_proc = "__complex128_ne"; break;
			}
			break;
		}
		GB_ASSERT(runtime_proc != nullptr);

		auto args = array_make<irValue *>(proc->module->allocator, 2);
		args[0] = left;
		args[1] = right;
		return ir_emit_global_call(proc, runtime_proc, args);
	}


	return ir_emit(proc, ir_instr_binary_op(proc, op_kind, left, right, t_llvm_bool));
}

irValue *ir_emit_array_ep(irProcedure *proc, irValue *s, irValue *index) {
	GB_ASSERT(index != nullptr);
	Type *t = ir_type(s);
	GB_ASSERT(is_type_pointer(t));
	Type *st = base_type(type_deref(t));
	GB_ASSERT_MSG(is_type_array(st), "%s", type_to_string(st));

	// NOTE(bill): For some weird legacy reason in LLVM, structure elements must be accessed as an i32
	index = ir_emit_conv(proc, index, t_i32);
	return ir_emit(proc, ir_instr_array_element_ptr(proc, s, index));
}

irValue *ir_emit_array_epi(irProcedure *proc, irValue *s, i32 index) {
	return ir_emit_array_ep(proc, s, ir_const_i32(proc->module->allocator, index));
}



irValue *ir_emit_struct_ep(irProcedure *proc, irValue *s, i32 index) {
	gbAllocator a = proc->module->allocator;
	Type *t = base_type(type_deref(ir_type(s)));
	Type *result_type = nullptr;

	if (is_type_struct(t)) {
		result_type = alloc_type_pointer(t->Struct.fields[index]->type);
	} else if (is_type_union(t)) {
		GB_ASSERT(index == -1);
		return ir_emit_union_tag_ptr(proc, s);
	} else if (is_type_tuple(t)) {
		GB_ASSERT(t->Tuple.variables.count > 0);
		result_type = alloc_type_pointer(t->Tuple.variables[index]->type);
	} else if (is_type_complex(t)) {
		Type *ft = base_complex_elem_type(t);
		switch (index) {
		case 0: result_type = alloc_type_pointer(ft); break;
		case 1: result_type = alloc_type_pointer(ft); break;
		}
	} else if (is_type_slice(t)) {
		switch (index) {
		case 0: result_type = alloc_type_pointer(alloc_type_pointer(t->Slice.elem)); break;
		case 1: result_type = alloc_type_pointer(t_int); break;
		case 2: result_type = alloc_type_pointer(t_int); break;
		}
	} else if (is_type_string(t)) {
		switch (index) {
		case 0: result_type = alloc_type_pointer(t_u8_ptr); break;
		case 1: result_type = alloc_type_pointer(t_int);    break;
		}
	} else if (is_type_any(t)) {
		switch (index) {
		case 0: result_type = alloc_type_pointer(t_rawptr);        break;
		case 1: result_type = alloc_type_pointer(t_type_info_ptr); break;
		}
	} else if (is_type_dynamic_array(t)) {
		switch (index) {
		case 0: result_type = alloc_type_pointer(alloc_type_pointer(t->DynamicArray.elem)); break;
		case 1: result_type = t_int_ptr;                                      break;
		case 2: result_type = t_int_ptr;                                      break;
		case 3: result_type = t_allocator_ptr;                                break;
		}
	} /* else if (is_type_map(t)) {
		init_map_internal_types(t);
		Type *itp = alloc_type_pointer(t->Map.internal_type);
		s = ir_emit_load(proc, ir_emit_transmute(proc, s, itp));

		Type *gst = t->Map.generated_struct_type;
		GB_ASSERT(gst->kind == Type_Struct);
		switch (index) {
		case 0: result_type = alloc_type_pointer(gst->Struct.fields[0]->type); break;
		case 1: result_type = alloc_type_pointer(gst->Struct.fields[1]->type); break;
		}
	} */else {
		GB_PANIC("TODO(bill): struct_gep type: %s, %d", type_to_string(ir_type(s)), index);
	}

	GB_ASSERT(result_type != nullptr);

	return ir_emit(proc, ir_instr_struct_element_ptr(proc, s, index, result_type));
}


irValue *ir_emit_struct_ev(irProcedure *proc, irValue *s, i32 index) {
	// NOTE(bill): For some weird legacy reason in LLVM, structure elements must be accessed as an i32

	gbAllocator a = proc->module->allocator;
	Type *t = base_type(ir_type(s));
	Type *result_type = nullptr;

	switch (t->kind) {
	case Type_Basic:
		switch (t->Basic.kind) {
		case Basic_string:
			switch (index) {
			case 0: result_type = t_u8_ptr; break;
			case 1: result_type = t_int;    break;
			}
			break;
		case Basic_any:
			switch (index) {
			case 0: result_type = t_rawptr;        break;
			case 1: result_type = t_type_info_ptr; break;
			}
			break;
		case Basic_complex64: case Basic_complex128:
		{
			Type *ft = base_complex_elem_type(t);
			switch (index) {
			case 0: result_type = ft; break;
			case 1: result_type = ft; break;
			}
			break;
		}
		}
		break;
	case Type_Struct:
		result_type = t->Struct.fields[index]->type;
		break;
	case Type_Union:
		GB_ASSERT(index == -1);
		return ir_emit_union_tag_value(proc, s);
	case Type_Tuple:
		GB_ASSERT(t->Tuple.variables.count > 0);
		result_type = t->Tuple.variables[index]->type;
		break;
	case Type_Slice:
		switch (index) {
		case 0: result_type = alloc_type_pointer(t->Slice.elem); break;
		case 1: result_type = t_int; break;
		}
		break;
	case Type_DynamicArray:
		switch (index) {
		case 0: result_type = alloc_type_pointer(t->DynamicArray.elem); break;
		case 1: result_type = t_int;                                      break;
		case 2: result_type = t_int;                                      break;
		case 3: result_type = t_allocator;                                break;
		}
		break;

	// case Type_Map: {
	// 	init_map_internal_types(t);
	// 	Type *gst = t->Map.generated_struct_type;
	// 	switch (index) {
	// 	case 0: result_type = gst->Struct.fields[0]->type; break;
	// 	case 1: result_type = gst->Struct.fields[1]->type; break;
	// 	}
	// 	break;
	// }

	default:
		GB_PANIC("TODO(bill): struct_ev type: %s, %d", type_to_string(ir_type(s)), index);
		break;
	}

	GB_ASSERT_MSG(result_type != nullptr, "%s, %d", type_to_string(ir_type(s)), index);

	return ir_emit(proc, ir_instr_struct_extract_value(proc, s, index, result_type));
}


irValue *ir_emit_deep_field_gep(irProcedure *proc, irValue *e, Selection sel) {
	GB_ASSERT(sel.index.count > 0);
	Type *type = type_deref(ir_type(e));
	gbAllocator a = proc->module->allocator;

	for_array(i, sel.index) {
		i32 index = cast(i32)sel.index[i];
		if (is_type_pointer(type)) {
			type = type_deref(type);
			e = ir_emit_load(proc, e);
			e = ir_emit_ptr_offset(proc, e, v_zero); // TODO(bill): Do I need these copies?
		}
		type = core_type(type);

		if (is_type_raw_union(type)) {
			type = type->Struct.fields[index]->type;
			e = ir_emit_conv(proc, e, alloc_type_pointer(type));
		} else if (is_type_struct(type)) {
			type = type->Struct.fields[index]->type;
			e = ir_emit_struct_ep(proc, e, index);
		} else if (type->kind == Type_Union) {
			GB_ASSERT(index == -1);
			type = t_type_info_ptr;
			e = ir_emit_struct_ep(proc, e, index);
		} else if (type->kind == Type_Tuple) {
			type = type->Tuple.variables[index]->type;
			e = ir_emit_struct_ep(proc, e, index);
		} else if (type->kind == Type_Basic) {
			switch (type->Basic.kind) {
			case Basic_any: {
				if (index == 0) {
					type = t_rawptr;
				} else if (index == 1) {
					type = t_type_info_ptr;
				}
				e = ir_emit_struct_ep(proc, e, index);
				break;
			}

			case Basic_string:
				e = ir_emit_struct_ep(proc, e, index);
				break;

			default:
				GB_PANIC("un-gep-able type");
				break;
			}
		} else if (type->kind == Type_Slice) {
			e = ir_emit_struct_ep(proc, e, index);
		} else if (type->kind == Type_DynamicArray) {
			e = ir_emit_struct_ep(proc, e, index);
		} else if (type->kind == Type_Array) {
			e = ir_emit_array_epi(proc, e, index);
		} else if (type->kind == Type_Map) {
			e = ir_emit_struct_ep(proc, e, 1);
			switch (index) {
			case 0: e = ir_emit_struct_ep(proc, e, 1); break; // count
			case 1: e = ir_emit_struct_ep(proc, e, 2); break; // capacity
			case 2: e = ir_emit_struct_ep(proc, e, 3); break; // allocator
			}
		} else {
			GB_PANIC("un-gep-able type %s", type_to_string(type));
		}
	}

	return e;
}


irValue *ir_emit_deep_field_ev(irProcedure *proc, irValue *e, Selection sel) {
	GB_ASSERT(sel.index.count > 0);
	Type *type = ir_type(e);

	for_array(i, sel.index) {
		i32 index = cast(i32)sel.index[i];
		if (is_type_pointer(type)) {
			type = type_deref(type);
			e = ir_emit_load(proc, e);
			e = ir_emit_ptr_offset(proc, e, v_zero); // TODO(bill): Do I need these copies?
		}
		type = base_type(type);


		if (is_type_raw_union(type)) {
			GB_PANIC("TODO(bill): IS THIS EVEN CORRECT?");
			type = type->Struct.fields[index]->type;
			e = ir_emit_conv(proc, e, type);
		} else if (type->kind == Type_Map) {
			e = ir_emit_struct_ev(proc, e, 1);
			switch (index) {
			case 0: e = ir_emit_struct_ev(proc, e, 1); break; // count
			case 1: e = ir_emit_struct_ev(proc, e, 2); break; // capacity
			case 2: e = ir_emit_struct_ev(proc, e, 3); break; // allocator
			}
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
	return ir_const_int(proc->module->allocator, t->Array.count);
}


irValue *ir_slice_elem(irProcedure *proc, irValue *slice) {
	GB_ASSERT(is_type_slice(ir_type(slice)));
	return ir_emit_struct_ev(proc, slice, 0);
}
irValue *ir_slice_len(irProcedure *proc, irValue *slice) {
	GB_ASSERT(is_type_slice(ir_type(slice)));
	return ir_emit_struct_ev(proc, slice, 1);
}
irValue *ir_dynamic_array_elem(irProcedure *proc, irValue *da) {
	GB_ASSERT(is_type_dynamic_array(ir_type(da)));
	return ir_emit_struct_ev(proc, da, 0);
}
irValue *ir_dynamic_array_len(irProcedure *proc, irValue *da) {
	GB_ASSERT(is_type_dynamic_array(ir_type(da)));
	return ir_emit_struct_ev(proc, da, 1);
}
irValue *ir_dynamic_array_cap(irProcedure *proc, irValue *da) {
	GB_ASSERT(is_type_dynamic_array(ir_type(da)));
	return ir_emit_struct_ev(proc, da, 2);
}
irValue *ir_dynamic_array_allocator(irProcedure *proc, irValue *da) {
	GB_ASSERT(is_type_dynamic_array(ir_type(da)));
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

irValue *ir_cstring_len(irProcedure *proc, irValue *value) {
	GB_ASSERT(is_type_cstring(ir_type(value)));
	auto args = array_make<irValue *>(proc->module->allocator, 1);
	args[0] = ir_emit_conv(proc, value, t_cstring);
	return ir_emit_global_call(proc, "__cstring_len", args);
}



void ir_fill_slice(irProcedure *proc, irValue *slice_ptr, irValue *data, irValue *len) {
	Type *t = ir_type(slice_ptr);
	GB_ASSERT(is_type_pointer(t));
	t = type_deref(t);
	GB_ASSERT(is_type_slice(t));
	ir_emit_store(proc, ir_emit_struct_ep(proc, slice_ptr, 0), data);
	ir_emit_store(proc, ir_emit_struct_ep(proc, slice_ptr, 1), len);
}
void ir_fill_string(irProcedure *proc, irValue *string_ptr, irValue *data, irValue *len) {
	Type *t = ir_type(string_ptr);
	GB_ASSERT(is_type_pointer(t));
	t = type_deref(t);
	GB_ASSERT(is_type_string(t));
	ir_emit_store(proc, ir_emit_struct_ep(proc, string_ptr, 0), data);
	ir_emit_store(proc, ir_emit_struct_ep(proc, string_ptr, 1), len);
}

irValue *ir_emit_string(irProcedure *proc, irValue *elem, irValue *len) {
	irValue *str = ir_add_local_generated(proc, t_string);
	ir_fill_string(proc, str, elem, len);
	return ir_emit_load(proc, str);
}


irValue *ir_add_local_slice(irProcedure *proc, Type *slice_type, irValue *base, irValue *low, irValue *high) {
	// TODO(bill): array bounds checking for slice creation
	// TODO(bill): check that low < high <= max
	gbAllocator a = proc->module->allocator;
	Type *bt = base_type(ir_type(base));

	if (low == nullptr) {
		low = v_zero;
	}
	if (high == nullptr) {
		switch (bt->kind) {
		case Type_Array:   high = ir_array_len(proc, base); break;
		case Type_Slice:   high = ir_slice_len(proc, base); break;
		case Type_Pointer: high = v_one;                     break;
		}
	}

	irValue *len = ir_emit_arith(proc, Token_Sub, high, low, t_int);

	irValue *elem = nullptr;
	switch (bt->kind) {
	case Type_Array:   elem = ir_array_elem(proc, base); break;
	case Type_Slice:   elem = ir_slice_elem(proc, base); break;
	case Type_Pointer: elem = ir_emit_load(proc, base);  break;
	}

	elem = ir_emit_ptr_offset(proc, elem, low);

	irValue *slice = ir_add_local_generated(proc, slice_type);
	ir_fill_slice(proc, slice, elem, len);
	return slice;
}



irValue *ir_find_or_add_entity_string(irModule *m, String str) {
	irValue **found = map_get(&m->const_strings, hash_string(str));
	if (found != nullptr) {
		return *found;
	}
	irValue *v = ir_const_string(m->allocator, str);
	map_set(&m->const_strings, hash_string(str), v);
	return v;

}


irValue *ir_const_union_tag(gbAllocator a, Type *u, Type *v) {
	return ir_value_constant(a, union_tag_type(u), exact_value_i64(union_variant_index(u, v)));
}


String ir_lookup_subtype_polymorphic_field(CheckerInfo *info, Type *dst, Type *src) {
	Type *prev_src = src;
	// Type *prev_dst = dst;
	src = base_type(type_deref(src));
	// dst = base_type(type_deref(dst));
	bool src_is_ptr = src != prev_src;
	// bool dst_is_ptr = dst != prev_dst;

	GB_ASSERT(is_type_struct(src) || is_type_union(src));
	for_array(i, src->Struct.fields) {
		Entity *f = src->Struct.fields[i];
		if (f->kind == Entity_Variable && f->flags & EntityFlag_Using) {
			if (are_types_identical(dst, f->type)) {
				return f->token.string;
			}
			if (src_is_ptr && is_type_pointer(dst)) {
				if (are_types_identical(type_deref(dst), f->type)) {
					return f->token.string;
				}
			}
			if (is_type_struct(f->type)) {
				String name = ir_lookup_subtype_polymorphic_field(info, dst, f->type);
				if (name.len > 0) {
					return name;
				}
			}
		}
	}
	return str_lit("");
}


irValue *ir_emit_ptr_to_uintptr(irProcedure *proc, irValue *value, Type *t, bool allow_type_type = false) {
	Type *vt = core_type(ir_type(value));
	GB_ASSERT(is_type_pointer(vt));
	if (allow_type_type) {
		GB_ASSERT(is_type_uintptr(core_type(t)));
	} else {
		GB_ASSERT(is_type_uintptr(core_type(t)));
	}
	return ir_emit(proc, ir_instr_conv(proc, irConv_ptrtoint, value, vt, t));
}
irValue *ir_emit_uintptr_to_ptr(irProcedure *proc, irValue *value, Type *t) {
	Type *vt = core_type(ir_type(value));
	GB_ASSERT(is_type_uintptr(vt));
	GB_ASSERT(is_type_pointer(core_type(t)));
	return ir_emit(proc, ir_instr_conv(proc, irConv_inttoptr, value, vt, t));
}


void ir_emit_store_union_variant(irProcedure *proc, irValue *parent, irValue *variant, Type *variant_type) {
	gbAllocator a = proc->module->allocator;
	irValue *underlying = ir_emit_conv(proc, parent, alloc_type_pointer(variant_type));

	irValue *v = variant;
	ir_emit_store(proc, underlying, variant);

	Type *t = type_deref(ir_type(parent));

	irValue *tag_ptr = ir_emit_union_tag_ptr(proc, parent);
	ir_emit_store(proc, tag_ptr, ir_const_union_tag(a, t, variant_type));
}

irValue *ir_emit_conv(irProcedure *proc, irValue *value, Type *t) {
	Type *src_type = ir_type(value);
	if (are_types_identical(t, src_type)) {
		return value;
	}

	Type *src = core_type(src_type);
	Type *dst = core_type(t);


	// if (is_type_untyped_nil(src) && type_has_nil(dst)) {
	if (is_type_untyped_nil(src)) {
		return ir_value_nil(proc->module->allocator, t);
	}
	if (is_type_untyped_undef(src)) {
		return ir_value_undef(proc->module->allocator, t);
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
			} else if (is_type_complex(dst)) {
				ev = exact_value_to_complex(ev);
			} else if (is_type_string(dst)) {
				// Handled elsewhere
				GB_ASSERT_MSG(ev.kind == ExactValue_String, "%d", ev.kind);
			} else if (is_type_integer(dst)) {
				ev = exact_value_to_integer(ev);
			} else if (is_type_pointer(dst)) {
				// IMPORTANT NOTE(bill): LLVM doesn't support pointer constants expect 'null'
				irValue *i = ir_add_module_constant(proc->module, t_uintptr, ev);
				return ir_emit(proc, ir_instr_conv(proc, irConv_inttoptr, i, t_uintptr, dst));
			}
			return ir_add_module_constant(proc->module, t, ev);
		}
	}

	if (are_types_identical(src, dst)) {
		if (!are_types_identical(src_type, t)) {
			return ir_emit_transmute(proc, value, t);
		}
		return value;
	}


	// bool <-> llvm bool
	if (is_type_boolean(src) && dst == t_llvm_bool) {
		return ir_emit(proc, ir_instr_conv(proc, irConv_trunc, value, src_type, t));
	}
	if (src == t_llvm_bool && is_type_boolean(dst)) {
		return ir_emit(proc, ir_instr_conv(proc, irConv_zext, value, src_type, t));
	}

	// integer -> integer
	if (is_type_integer(src) && is_type_integer(dst)) {
		GB_ASSERT(src->kind == Type_Basic &&
		          dst->kind == Type_Basic);
		i64 sz = type_size_of(default_type(src));
		i64 dz = type_size_of(default_type(dst));
		irConvKind kind = irConv_trunc;

		if (dz < sz) {
			kind = irConv_trunc;
		} else if (dz == sz) {
			// NOTE(bill): In LLVM, all integers are signed and rely upon 2's compliment
			// NOTE(bill): Copy the value just for type correctness
			kind = irConv_bitcast;
		} else if (dz > sz) {
			if (is_type_unsigned(src)) {
				kind = irConv_zext; // zero extent
			} else {
				kind = irConv_sext; // sign extent
			}
		}

		return ir_emit(proc, ir_instr_conv(proc, kind, value, src_type, t));
	}

	// boolean -> boolean/integer
	if (is_type_boolean(src) && (is_type_boolean(dst) || is_type_integer(dst))) {
		GB_ASSERT(src != t_llvm_bool);

		irValue *b = ir_emit(proc, ir_instr_binary_op(proc, Token_NotEq, value, v_zero, t_llvm_bool));
		return ir_emit(proc, ir_instr_conv(proc, irConv_zext, b, t_llvm_bool, t));
	}

	if (is_type_cstring(src) && is_type_u8_ptr(dst)) {
		return ir_emit_bitcast(proc, value, dst);
	}
	if (is_type_u8_ptr(src) && is_type_cstring(dst)) {
		return ir_emit_bitcast(proc, value, dst);
	}

	if (src == t_cstring && dst == t_string) {
		irValue *c = ir_emit_conv(proc, value, t_cstring);
		auto args = array_make<irValue *>(proc->module->allocator, 1);
		args[0] = c;
		irValue *s = ir_emit_global_call(proc, "__cstring_to_string", args);
		return ir_emit_conv(proc, s, dst);
	}


	// integer -> boolean
	if (is_type_integer(src) && is_type_boolean(dst)) {
		return ir_emit_comp(proc, Token_NotEq, value, v_zero);
	}

	// float -> float
	if (is_type_float(src) && is_type_float(dst)) {
		gbAllocator a = proc->module->allocator;
		i64 sz = type_size_of(src);
		i64 dz = type_size_of(dst);
		if (sz == 2) {
			switch (dz) {
			case 2: return value;
			case 4: {
				auto args = array_make<irValue *>(proc->module->allocator, 1);
				args[0] = value;
				return ir_emit_global_call(proc, "__gnu_h2f_ieee", args);
				break;
			}
			case 8: {
				auto args = array_make<irValue *>(proc->module->allocator, 1);
				args[0] = value;
				return ir_emit_global_call(proc, "__f16_to_f64", args);
				break;
			}
			}
		} else if (dz == 2) {
			switch (sz) {
			case 2: return value;
			case 4: {
				auto args = array_make<irValue *>(proc->module->allocator, 1);
				args[0] = value;
				return ir_emit_global_call(proc, "__gnu_f2h_ieee", args);
				break;
			}
			case 8: {
				auto args = array_make<irValue *>(proc->module->allocator, 1);
				args[0] = value;
				return ir_emit_global_call(proc, "__truncdfhf2", args);
				break;
			}
			}
		}

		irConvKind kind = irConv_fptrunc;
		if (dz >= sz) {
			kind = irConv_fpext;
		}
		return ir_emit(proc, ir_instr_conv(proc, kind, value, src_type, t));
	}

	if (is_type_complex(src) && is_type_complex(dst)) {
		Type *ft = base_complex_elem_type(dst);
		irValue *gen = ir_add_local_generated(proc, dst);
		irValue *real = ir_emit_conv(proc, ir_emit_struct_ev(proc, value, 0), ft);
		irValue *imag = ir_emit_conv(proc, ir_emit_struct_ev(proc, value, 1), ft);
		ir_emit_store(proc, ir_emit_struct_ep(proc, gen, 0), real);
		ir_emit_store(proc, ir_emit_struct_ep(proc, gen, 1), imag);
		return ir_emit_load(proc, gen);
	}

	// float <-> integer
	if (is_type_float(src) && is_type_integer(dst)) {
		irConvKind kind = irConv_fptosi;
		if (is_type_unsigned(dst)) {
			kind = irConv_fptoui;
		}
		return ir_emit(proc, ir_instr_conv(proc, kind, value, src_type, t));
	}
	if (is_type_integer(src) && is_type_float(dst)) {
		irConvKind kind = irConv_sitofp;
		if (is_type_unsigned(src)) {
			kind = irConv_uitofp;
		}
		return ir_emit(proc, ir_instr_conv(proc, kind, value, src_type, t));
	}

	// Pointer <-> uintptr
	if (is_type_pointer(src) && is_type_uintptr(dst)) {
		return ir_emit_ptr_to_uintptr(proc, value, t);
	}
	if (is_type_uintptr(src) && is_type_pointer(dst)) {
		return ir_emit_uintptr_to_ptr(proc, value, t);
	}

	if (is_type_union(dst)) {
		for_array(i, dst->Union.variants) {
			Type *vt = dst->Union.variants[i];
			if (are_types_identical(vt, src_type)) {
				ir_emit_comment(proc, str_lit("union - child to parent"));
				gbAllocator a = proc->module->allocator;
				irValue *parent = ir_add_local_generated(proc, t);
				ir_emit_store_union_variant(proc, parent, value, vt);
				return ir_emit_load(proc, parent);
			}
		}
	}

	// NOTE(bill): This has to be done before 'Pointer <-> Pointer' as it's
	// subtype polymorphism casting
	if (check_is_assignable_to_using_subtype(src_type, t)) {
		Type *st = type_deref(src_type);
		Type *pst = st;
		st = type_deref(st);

		bool st_is_ptr = st != pst;
		st = base_type(st);

		Type *dt = t;
		bool dt_is_ptr = is_type_pointer(dt);

		GB_ASSERT(is_type_struct(st) || is_type_union(st));
		String field_name = ir_lookup_subtype_polymorphic_field(proc->module->info, t, st);
		// gb_printf("field_name: %.*s\n", LIT(field_name));
		if (field_name.len > 0) {
			// NOTE(bill): It can be casted
			Selection sel = lookup_field(st, field_name, false);
			if (sel.entity != nullptr) {
				ir_emit_comment(proc, str_lit("cast - polymorphism"));
				if (st_is_ptr) {
					irValue *res = ir_emit_deep_field_gep(proc, value, sel);
					if (!dt_is_ptr) {
						res = ir_emit_load(proc, res);
					}
					return res;
				} else {
					if (is_type_pointer(ir_type(value))) {
						if (!dt_is_ptr) {
							value = ir_emit_load(proc, value);
						} else {
							value = ir_emit_deep_field_gep(proc, value, sel);
							return ir_emit_load(proc, value);
						}
					}

					return ir_emit_deep_field_ev(proc, value, sel);

				}
			}
		}
	}



	// Pointer <-> Pointer
	if (is_type_pointer(src) && is_type_pointer(dst)) {
		return ir_emit_bitcast(proc, value, t);
	}



	// proc <-> proc
	if (is_type_proc(src) && is_type_proc(dst)) {
		return ir_emit_bitcast(proc, value, t);
	}

	// pointer -> proc
	if (is_type_pointer(src) && is_type_proc(dst)) {
		return ir_emit_bitcast(proc, value, t);
	}
	// proc -> pointer
	if (is_type_proc(src) && is_type_pointer(dst)) {
		return ir_emit_bitcast(proc, value, t);
	}



	// []byte/[]u8 <-> string
	if (is_type_u8_slice(src) && is_type_string(dst)) {
		irValue *elem = ir_slice_elem(proc, value);
		irValue *len  = ir_slice_len(proc, value);
		return ir_emit_string(proc, elem, len);
	}
	if (is_type_string(src) && is_type_u8_slice(dst)) {
		irValue *elem = ir_string_elem(proc, value);
		irValue *elem_ptr = ir_add_local_generated(proc, ir_type(elem));
		ir_emit_store(proc, elem_ptr, elem);

		irValue *len  = ir_string_len(proc, value);
		irValue *slice = ir_add_local_slice(proc, t, elem_ptr, v_zero, len);
		return ir_emit_load(proc, slice);
	}

	if (is_type_array(dst)) {
		Type *elem = dst->Array.elem;
		irValue *e = ir_emit_conv(proc, value, elem);
		irValue *v = ir_add_local_generated(proc, t);
		isize index_count = dst->Array.count;

		for (i32 i = 0; i < index_count; i++) {
			irValue *elem = ir_emit_array_epi(proc, v, i);
			ir_emit_store(proc, elem, e);
		}
		return ir_emit_load(proc, v);
	}

	if (is_type_any(dst)) {
		irValue *result = ir_add_local_generated(proc, t_any);

		if (is_type_untyped_nil(src)) {
			return ir_emit_load(proc, result);
		}

		Type *st = default_type(src_type);

		irValue *data = ir_address_from_load_or_generate_local(proc, value);
		GB_ASSERT_MSG(is_type_pointer(ir_type(data)), type_to_string(ir_type(data)));
		GB_ASSERT_MSG(is_type_typed(st), "%s", type_to_string(st));
		data = ir_emit_conv(proc, data, t_rawptr);


		irValue *ti = ir_type_info(proc, st);

		ir_emit_store(proc, ir_emit_struct_ep(proc, result, 0), data);
		ir_emit_store(proc, ir_emit_struct_ep(proc, result, 1), ti);

		return ir_emit_load(proc, result);
	}



	gb_printf_err("ir_emit_conv: src -> dst\n");
	gb_printf_err("Not Identical %s != %s\n", type_to_string(src_type), type_to_string(t));
	gb_printf_err("Not Identical %s != %s\n", type_to_string(src), type_to_string(dst));


	GB_PANIC("Invalid type conversion: '%s' to '%s' for procedure '%.*s'",
	         type_to_string(src_type), type_to_string(t),
	         LIT(proc->name));

	return nullptr;
}

bool ir_is_type_aggregate(Type *t) {
	t = base_type(t);
	switch (t->kind) {
	case Type_Basic:
		switch (t->Basic.kind) {
		case Basic_string:
		case Basic_any:
			return true;

		// case Basic_complex32:
		case Basic_complex64:
		case Basic_complex128:
			return true;
		}
		break;

	case Type_Pointer:
		return false;

	case Type_Array:
	case Type_Slice:
	case Type_Struct:
	case Type_Union:
	case Type_Tuple:
	case Type_DynamicArray:
	case Type_Map:
	case Type_BitField:
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

	irModule *m = proc->module;

	i64 sz = type_size_of(src);
	i64 dz = type_size_of(dst);

	GB_ASSERT_MSG(sz == dz, "Invalid transmute conversion: '%s' to '%s'", type_to_string(src_type), type_to_string(t));

	// NOTE(bill): Casting between an integer and a pointer cannot be done through a bitcast
	if (is_type_uintptr(src) && is_type_pointer(dst)) {
		return ir_emit_uintptr_to_ptr(proc, value, t);
	}
	if (is_type_pointer(src) && is_type_uintptr(dst)) {
		return ir_emit_ptr_to_uintptr(proc, value, t);
	}

	if (ir_is_type_aggregate(src) || ir_is_type_aggregate(dst)) {
		irValue *s = ir_address_from_load_or_generate_local(proc, value);
		irValue *d = ir_emit_bitcast(proc, s, alloc_type_pointer(t));
		return ir_emit_load(proc, d);
	}

	// TODO(bill): Actually figure out what the conversion needs to be correctly 'cause LLVM
	return ir_emit_bitcast(proc, value, dst);
}



irValue *ir_emit_union_cast(irProcedure *proc, irValue *value, Type *type, TokenPos pos, bool do_conversion_check=true) {
	gbAllocator a = proc->module->allocator;

	Type *src_type = ir_type(value);
	bool is_ptr = is_type_pointer(src_type);

	bool is_tuple = true;
	Type *tuple = type;
	if (type->kind != Type_Tuple) {
		is_tuple = false;
		tuple = make_optional_ok_type(type);
	}

	irValue *v = ir_add_local_generated(proc, tuple);

	if (is_ptr) {
		value = ir_emit_load(proc, value);
	}
	Type *src = base_type(type_deref(src_type));
	GB_ASSERT_MSG(is_type_union(src), "%s", type_to_string(src_type));
	Type *dst = tuple->Tuple.variables[0]->type;


	irValue *value_  = ir_address_from_load_or_generate_local(proc, value);
	irValue *tag     = ir_emit_load(proc, ir_emit_union_tag_ptr(proc, value_));
	irValue *dst_tag = ir_const_union_tag(a, src, dst);


	irBlock *ok_block = ir_new_block(proc, nullptr, "union_cast.ok");
	irBlock *end_block = ir_new_block(proc, nullptr, "union_cast.end");
	irValue *cond = ir_emit_comp(proc, Token_CmpEq, tag, dst_tag);
	ir_emit_if(proc, cond, ok_block, end_block);
	ir_start_block(proc, ok_block);

	irValue *gep0 = ir_emit_struct_ep(proc, v, 0);
	irValue *gep1 = ir_emit_struct_ep(proc, v, 1);

	irValue *data = ir_emit_load(proc, ir_emit_conv(proc, value_, ir_type(gep0)));
	ir_emit_store(proc, gep0, data);
	ir_emit_store(proc, gep1, v_true);

	ir_emit_jump(proc, end_block);
	ir_start_block(proc, end_block);

	if (!is_tuple) {
		if (do_conversion_check) {
			// NOTE(bill): Panic on invalid conversion
			Type *dst_type = tuple->Tuple.variables[0]->type;

			irValue *ok = ir_emit_load(proc, ir_emit_struct_ep(proc, v, 1));
			auto args = array_make<irValue *>(proc->module->allocator, 6);
			args[0] = ok;

			args[1] = ir_find_or_add_entity_string(proc->module, pos.file);
			args[2] = ir_const_int(a, pos.line);
			args[3] = ir_const_int(a, pos.column);

			args[4] = ir_type_info(proc, src_type);
			args[5] = ir_type_info(proc, dst_type);
			ir_emit_global_call(proc, "__type_assertion_check", args);
		}

		return ir_emit_load(proc, ir_emit_struct_ep(proc, v, 0));
	}
	return ir_emit_load(proc, v);
}

irAddr ir_emit_any_cast_addr(irProcedure *proc, irValue *value, Type *type, TokenPos pos) {
	gbAllocator a = proc->module->allocator;
	Type *src_type = ir_type(value);

	if (is_type_pointer(src_type)) {
		value = ir_emit_load(proc, value);
	}

	bool is_tuple = true;
	Type *tuple = type;
	if (type->kind != Type_Tuple) {
		is_tuple = false;
		tuple = make_optional_ok_type(type);
	}
	Type *dst_type = tuple->Tuple.variables[0]->type;

	irValue *v = ir_add_local_generated(proc, tuple);

	irValue *ti_ptr = ir_type_info(proc, dst_type);
	irValue *any_ti = ir_emit_struct_ev(proc, value, 1);


	irBlock *ok_block = ir_new_block(proc, nullptr, "any_cast.ok");
	irBlock *end_block = ir_new_block(proc, nullptr, "any_cast.end");
	irValue *cond = ir_emit_comp(proc, Token_CmpEq, any_ti, ti_ptr);
	ir_emit_if(proc, cond, ok_block, end_block);
	ir_start_block(proc, ok_block);

	irValue *gep0 = ir_emit_struct_ep(proc, v, 0);
	irValue *gep1 = ir_emit_struct_ep(proc, v, 1);

	irValue *any_data = ir_emit_struct_ev(proc, value, 0);
	irValue *ptr = ir_emit_conv(proc, any_data, alloc_type_pointer(dst_type));
	ir_emit_store(proc, gep0, ir_emit_load(proc, ptr));
	ir_emit_store(proc, gep1, v_true);

	ir_emit_jump(proc, end_block);
	ir_start_block(proc, end_block);

	if (!is_tuple) {
		// NOTE(bill): Panic on invalid conversion

		irValue *ok = ir_emit_load(proc, ir_emit_struct_ep(proc, v, 1));
		auto args = array_make<irValue *>(proc->module->allocator, 6);
		args[0] = ok;

		args[1] = ir_find_or_add_entity_string(proc->module, pos.file);
		args[2] = ir_const_int(a, pos.line);
		args[3] = ir_const_int(a, pos.column);

		args[4] = any_ti;
		args[5] = ti_ptr;
		ir_emit_global_call(proc, "__type_assertion_check", args);

		return ir_addr(ir_emit_struct_ep(proc, v, 0));
	}
	return ir_addr(v);
}
irValue *ir_emit_any_cast(irProcedure *proc, irValue *value, Type *type, TokenPos pos) {
	return ir_addr_load(proc, ir_emit_any_cast_addr(proc, value, type, pos));
}

// TODO(bill): Try and make a lot of this constant aggregate literals in LLVM IR
gb_global irValue *ir_global_type_info_data           = nullptr;
gb_global irValue *ir_global_type_info_member_types   = nullptr;
gb_global irValue *ir_global_type_info_member_names   = nullptr;
gb_global irValue *ir_global_type_info_member_offsets = nullptr;
gb_global irValue *ir_global_type_info_member_usings  = nullptr;

gb_global i32      ir_global_type_info_data_index           = 0;
gb_global i32      ir_global_type_info_member_types_index   = 0;
gb_global i32      ir_global_type_info_member_names_index   = 0;
gb_global i32      ir_global_type_info_member_offsets_index = 0;
gb_global i32      ir_global_type_info_member_usings_index  = 0;


irValue *ir_type_info(irProcedure *proc, Type *type) {
	CheckerInfo *info = proc->module->info;

	type = default_type(type);

	i32 entry_index = cast(i32)type_info_index(info, type);
	GB_ASSERT(entry_index >= 0);

	// gb_printf_err("%d %s\n", entry_index, type_to_string(type));

	return ir_emit_array_ep(proc, ir_global_type_info_data, ir_const_i32(proc->module->allocator, entry_index));
}

irValue *ir_emit_logical_binary_expr(irProcedure *proc, TokenKind op, AstNode *left, AstNode *right, Type *type) {
	irBlock *rhs  = ir_new_block(proc, nullptr, "logical.cmp.rhs");
	irBlock *done = ir_new_block(proc, nullptr, "logical.cmp.done");

	type = default_type(type);

	irValue *short_circuit = nullptr;
	if (op == Token_CmpAnd) {
		ir_build_cond(proc, left, rhs, done);
		short_circuit = v_false;
	} else if (op == Token_CmpOr) {
		ir_build_cond(proc, left, done, rhs);
		short_circuit = v_true;
	}

	if (rhs->preds.count == 0) {
		ir_start_block(proc, done);
		return short_circuit;
	}

	if (done->preds.count == 0) {
		ir_start_block(proc, rhs);
		return ir_build_expr(proc, right);
	}

	auto edges = array_make<irValue *>(proc->module->allocator, 0, done->preds.count+1);
	for_array(i, done->preds) {
		array_add(&edges, short_circuit);
	}

	ir_start_block(proc, rhs);
	array_add(&edges, ir_build_expr(proc, right));
	ir_emit_jump(proc, done);
	ir_start_block(proc, done);

	return ir_emit(proc, ir_instr_phi(proc, edges, type));
}

irValue *ir_emit_logical_binary_expr(irProcedure *proc, AstNode *expr) {
	ast_node(be, BinaryExpr, expr);
	irBlock *rhs  = ir_new_block(proc, nullptr, "logical.cmp.rhs");
	irBlock *done = ir_new_block(proc, nullptr, "logical.cmp.done");

	Type *type = type_of_expr(proc->module->info, expr);
	type = default_type(type);

	return ir_emit_logical_binary_expr(proc, be->op.kind, be->left, be->right, type);
}


void ir_emit_bounds_check(irProcedure *proc, Token token, irValue *index, irValue *len) {
	if (build_context.no_bounds_check) {
		return;
	}
	if ((proc->module->stmt_state_flags & StmtStateFlag_no_bounds_check) != 0) {
		return;
	}

	index = ir_emit_conv(proc, index, t_int);
	len = ir_emit_conv(proc, len, t_int);

	gbAllocator a = proc->module->allocator;
	irValue *file = ir_find_or_add_entity_string(proc->module, token.pos.file);
	irValue *line = ir_const_int(a, token.pos.line);
	irValue *column = ir_const_int(a, token.pos.column);


	auto args = array_make<irValue *>(proc->module->allocator, 5);
	args[0] = file;
	args[1] = line;
	args[2] = column;
	args[3] = index;
	args[4] = len;

	ir_emit_global_call(proc, "__bounds_check_error", args);
}

void ir_emit_slice_bounds_check(irProcedure *proc, Token token, irValue *low, irValue *high, irValue *len, bool is_substring) {
	if (build_context.no_bounds_check) {
		return;
	}
	if ((proc->module->stmt_state_flags & StmtStateFlag_no_bounds_check) != 0) {
		return;
	}

	gbAllocator a = proc->module->allocator;
	irValue *file = ir_find_or_add_entity_string(proc->module, token.pos.file);
	irValue *line = ir_const_int(a, token.pos.line);
	irValue *column = ir_const_int(a, token.pos.column);
	low  = ir_emit_conv(proc, low,  t_int);
	high = ir_emit_conv(proc, high, t_int);

	auto args = array_make<irValue *>(proc->module->allocator, 6);
	args[0] = file;
	args[1] = line;
	args[2] = column;
	args[3] = low;
	args[4] = high;
	args[5] = len;

	ir_emit_global_call(proc, "__slice_expr_error", args);
}

void ir_emit_dynamic_array_bounds_check(irProcedure *proc, Token token, irValue *low, irValue *high, irValue *max) {
	if (build_context.no_bounds_check) {
		return;
	}
	if ((proc->module->stmt_state_flags & StmtStateFlag_no_bounds_check) != 0) {
		return;
	}

	gbAllocator a = proc->module->allocator;
	irValue *file = ir_find_or_add_entity_string(proc->module, token.pos.file);
	irValue *line = ir_const_int(a, token.pos.line);
	irValue *column = ir_const_int(a, token.pos.column);
	low  = ir_emit_conv(proc, low,  t_int);
	high = ir_emit_conv(proc, high, t_int);

	auto args = array_make<irValue *>(proc->module->allocator, 6);
	args[0] = file;
	args[1] = line;
	args[2] = column;
	args[3] = low;
	args[4] = high;
	args[5] = max;

	ir_emit_global_call(proc, "__dynamic_array_expr_error", args);
}



////////////////////////////////////////////////////////////////
//
// @Build
//
////////////////////////////////////////////////////////////////

String ir_mangle_name(irGen *s, String path, Entity *e) {
	// NOTE(bill): prefix names not in the init scope
	// TODO(bill): make robust and not just rely on the file's name
	String name = e->token.string;
	irModule *m = &s->module;
	CheckerInfo *info = m->info;
	gbAllocator a = m->allocator;
	AstFile *file = ast_file_of_filename(info, path);

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

	isize max_len = base_len + 1 + 1 + 10 + 1 + name.len;
	bool require_suffix_id = is_type_polymorphic(e->type);
	if (require_suffix_id) {
		max_len += 21;
	}

	u8 *new_name = gb_alloc_array(a, u8, max_len);
	isize new_name_len = 0;
	if ((base_len > 0 && gb_char_is_digit(base[0])) ||
	    base_len == 0) {
		new_name_len = gb_snprintf(
			cast(char *)new_name, max_len,
			"_%.*s-%u.%.*s",
			cast(int)base_len, base,
			cast(u32)file->id,
			LIT(name));
	} else {
		new_name_len = gb_snprintf(
			cast(char *)new_name, max_len,
			"%.*s-%u.%.*s",
			cast(int)base_len, base,
			cast(u32)file->id,
			LIT(name));
	}
	if (require_suffix_id) {
		char *str = cast(char *)new_name + new_name_len-1;
		isize len = max_len-new_name_len;
		isize extra = gb_snprintf(str, len, "-%llu", cast(unsigned long long)e->id);
		new_name_len += extra-1;
	}

	return make_string(new_name, new_name_len-1);
}


void ir_mangle_add_sub_type_name(irModule *m, Entity *field, String parent) {
	if (field->kind != Entity_TypeName) {
		return;
	}

	String cn = field->token.string;
	isize len = parent.len + 1 + 16 + 1 + cn.len;
	u8 *text = gb_alloc_array(m->allocator, u8, len);
	isize new_name_len = gb_snprintf(cast(char *)text, len,
	                                 "%.*s.%.*s", LIT(parent), LIT(cn));

	String child = {text, new_name_len-1};
	GB_ASSERT(child.len > 0);
	ir_add_entity_name(m, field, child);
	ir_gen_global_type_name(m, field, child);
}


irBranchBlocks ir_lookup_branch_blocks(irProcedure *proc, AstNode *ident) {
	GB_ASSERT(ident->kind == AstNode_Ident);
	Entity *e = entity_of_ident(proc->module->info, ident);
	GB_ASSERT(e->kind == Entity_Label);
	for_array(i, proc->branch_blocks) {
		irBranchBlocks *b = &proc->branch_blocks[i];
		if (b->label == e->Label.node) {
			return *b;
		}
	}

	GB_PANIC("Unreachable");
	irBranchBlocks empty = {};
	return empty;
}


void ir_push_target_list(irProcedure *proc, AstNode *label, irBlock *break_, irBlock *continue_, irBlock *fallthrough_) {
	irTargetList *tl = gb_alloc_item(proc->module->allocator, irTargetList);
	tl->prev          = proc->target_list;
	tl->break_        = break_;
	tl->continue_     = continue_;
	tl->fallthrough_  = fallthrough_;
	proc->target_list = tl;

	if (label != nullptr) { // Set label blocks
		GB_ASSERT(label->kind == AstNode_Label);

		for_array(i, proc->branch_blocks) {
			irBranchBlocks *b = &proc->branch_blocks[i];
			GB_ASSERT(b->label != nullptr && label != nullptr);
			GB_ASSERT(b->label->kind == AstNode_Label);
			if (b->label == label) {
				b->break_    = break_;
				b->continue_ = continue_;
				return;
			}
		}

		GB_PANIC("ir_set_label_blocks: Unreachable");
	}
}

void ir_pop_target_list(irProcedure *proc) {
	proc->target_list = proc->target_list->prev;
}



irValue *ir_gen_anonymous_proc_lit(irModule *m, String prefix_name, AstNode *expr, irProcedure *proc = nullptr) {
	ast_node(pl, ProcLit, expr);

	// NOTE(bill): Generate a new name
	// parent$count
	isize name_len = prefix_name.len + 1 + 8 + 1;
	u8 *name_text = gb_alloc_array(m->allocator, u8, name_len);
	i32 name_id = cast(i32)m->anonymous_proc_lits.entries.count;

	name_len = gb_snprintf(cast(char *)name_text, name_len, "%.*s$anon-%d", LIT(prefix_name), name_id);
	String name = make_string(name_text, name_len-1);

	Type *type = type_of_expr(m->info, expr);
	irValue *value = ir_value_procedure(m->allocator,
	                                    m, nullptr, type, pl->type, pl->body, name);

	value->Proc.tags = pl->tags;
	value->Proc.inlining = pl->inlining;
	value->Proc.parent = proc;

	array_add(&m->procs_to_generate, value);
	if (proc != nullptr) {
		array_add(&proc->children, &value->Proc);
	} else {
		map_set(&m->members, hash_string(name), value);
	}

	map_set(&m->anonymous_proc_lits, hash_pointer(expr), value);

	return value;
}

void ir_check_type_and_gen_for_proc_lit(irProcedure *proc, Type *t) {
	if (t == nullptr) return;
	if (t->kind == Type_Struct && t->Struct.has_proc_default_values) {
		for_array(i, t->Struct.fields) {
			Entity *f = t->Struct.fields[i];
			if (f->kind == Entity_Variable && f->Variable.default_value.kind == ExactValue_Procedure) {
				AstNode *expr = f->Variable.default_value.value_procedure;
				GB_ASSERT(expr != nullptr);
				if (expr->kind == AstNode_ProcLit) {
					ir_gen_anonymous_proc_lit(proc->module, proc->name, expr, proc);
				}
			}
		}
	}
}

void ir_check_type_and_gen_for_proc_lit(irModule *m, String prefix_name, Type *t) {
	if (t == nullptr) return;
	if (t->kind == Type_Struct && t->Struct.has_proc_default_values) {
		for_array(i, t->Struct.fields) {
			Entity *f = t->Struct.fields[i];
			if (f->kind == Entity_Variable && f->Variable.default_value.kind == ExactValue_Procedure) {
				AstNode *expr = f->Variable.default_value.value_procedure;
				GB_ASSERT(expr != nullptr);
				if (expr->kind == AstNode_ProcLit) {
					ir_gen_anonymous_proc_lit(m, prefix_name, expr);
				}
			}
		}
	}
}


void ir_gen_global_type_name(irModule *m, Entity *e, String name) {
	if (e->type == nullptr) return;

	if (e->kind == Entity_TypeName && e->type->kind == Type_Named) {
		if (e != e->type->Named.type_name) {
			// NOTE(bill): Is alias
			return;
		}
	}

	Type *bt = base_type(e->type);

	bool is_poly = is_type_polymorphic(bt);
	if (!is_poly) {
		if (bt->kind == Type_Struct &&
		    bt->Struct.is_polymorphic &&
		    !bt->Struct.is_poly_specialized) {
			is_poly = true;
		}
	}
	if (is_poly) {
		auto found = map_get(&m->info->gen_types, hash_pointer(e->type));
		if (found != nullptr) {
			for_array(i, *found) {
				Entity *sub = (*found)[i];
				// gb_printf_err("--> %.*s\n", LIT(sub->token.string));
				if (ir_min_dep_entity(m, sub)) {
					ir_mangle_add_sub_type_name(m, sub, name);
				}
			}
		}
		return;
	}

	if (!ir_min_dep_entity(m, e)) {
		return;
	}
	irValue *t = ir_value_type_name(m->allocator, name, e->type);
	ir_module_add_value(m, e, t);
	map_set(&m->members, hash_string(name), t);

	#if 0
	if (is_type_union(e->type)) {
		Type *bt = base_type(e->type);
		// NOTE(bill): Zeroth entry is null (for 'match type' stmts)
		for (isize j = 1; j < bt->Struct.variant_count; j++) {
			ir_mangle_add_sub_type_name(m, bt->Struct.variants[j], name);
		}
	}
	#endif

	// if (bt->kind == Type_Struct) {
	// 	Scope *s = bt->Struct.scope;
	// 	if (s != nullptr) {
	// 		for_array(i, s->elements.entries) {
	// 			Entity *e = s->elements.entries[i].value;
	// 			if (e->kind == Entity_TypeName) {
	// 				ir_mangle_add_sub_type_name(m, e, name);
	// 			}
	// 		}
	// 	}
	// }

	ir_check_type_and_gen_for_proc_lit(m, e->token.string, bt);
}




void ir_build_defer_stmt(irProcedure *proc, irDefer d) {
	irBlock *b = ir_new_block(proc, nullptr, "defer");
	// NOTE(bill): The prev block may defer injection before it's terminator
	irInstr *last_instr = ir_get_last_instr(proc->curr_block);
	if (last_instr == nullptr || !ir_is_instr_terminating(last_instr)) {
		ir_emit_jump(proc, b);
	}
	ir_start_block(proc, b);
	ir_emit_comment(proc, str_lit("defer"));
	if (d.kind == irDefer_Node) {
		ir_build_stmt(proc, d.stmt);
	} else if (d.kind == irDefer_Instr) {
		// NOTE(bill): Need to make a new copy
		irValue *instr = cast(irValue *)gb_alloc_copy(proc->module->allocator, d.instr, gb_size_of(irValue));
		ir_emit(proc, instr);
	}
}

irValue *ir_emit_min(irProcedure *proc, Type *t, irValue *x, irValue *y) {
	x = ir_emit_conv(proc, x, t);
	y = ir_emit_conv(proc, y, t);

	if (is_type_float(t)) {
		gbAllocator a = proc->module->allocator;
		i64 sz = 8*type_size_of(t);
		auto args = array_make<irValue *>(proc->module->allocator, 2);
		args[0] = x;
		args[1] = y;
		switch (sz) {
		case 32: return ir_emit_global_call(proc, "__min_f32", args);
		case 64: return ir_emit_global_call(proc, "__min_f64", args);
		}
		GB_PANIC("Unknown float type");
	}
	return ir_emit_select(proc, ir_emit_comp(proc, Token_Lt, x, y), x, y);
}
irValue *ir_emit_max(irProcedure *proc, Type *t, irValue *x, irValue *y) {
	x = ir_emit_conv(proc, x, t);
	y = ir_emit_conv(proc, y, t);

	if (is_type_float(t)) {
		gbAllocator a = proc->module->allocator;
		i64 sz = 8*type_size_of(t);
		auto args = array_make<irValue *>(proc->module->allocator, 2);
		args[0] = x;
		args[1] = y;
		switch (sz) {
		case 32: return ir_emit_global_call(proc, "__max_f32", args);
		case 64: return ir_emit_global_call(proc, "__max_f64", args);
		}
		GB_PANIC("Unknown float type");
	}
	return ir_emit_select(proc, ir_emit_comp(proc, Token_Gt, x, y), x, y);
}


irValue *ir_emit_clamp(irProcedure *proc, Type *t, irValue *x, irValue *min, irValue *max) {
	ir_emit_comment(proc, str_lit("clamp"));
	irValue *z = nullptr;
	z = ir_emit_max(proc, t, x, min);
	z = ir_emit_min(proc, t, z, max);
	return z;
}


irValue *ir_find_global_variable(irProcedure *proc, String name) {
	irValue **value = map_get(&proc->module->members, hash_string(name));
	GB_ASSERT_MSG(value != nullptr, "Unable to find global variable '%.*s'", LIT(name));
	return *value;
}

void ir_build_stmt_list(irProcedure *proc, Array<AstNode *> stmts);


bool is_double_pointer(Type *t) {
	if (!is_type_pointer(t)) {
		return false;
	}
	Type *td = type_deref(t);
	if (td == nullptr || td == t) {
		return false;
	}
	return is_type_pointer(td);
}


irValue *ir_emit_source_code_location(irProcedure *proc, String procedure, TokenPos pos) {
	gbAllocator a = proc->module->allocator;
	auto args = array_make<irValue *>(proc->module->allocator, 4);
	args[0] = ir_find_or_add_entity_string(proc->module, pos.file);
	args[1] = ir_const_int(a, pos.line);
	args[2] = ir_const_int(a, pos.column);
	args[3] = ir_find_or_add_entity_string(proc->module, procedure);
	return ir_emit_global_call(proc, "make_source_code_location", args);
}


irValue *ir_emit_source_code_location(irProcedure *proc, AstNode *node) {
	String proc_name = {};
	if (proc->entity) {
		proc_name = proc->entity->token.string;
	}
	TokenPos pos = {};
	if (node) {
		pos = ast_node_token(node).pos;
	}
	return ir_emit_source_code_location(proc, proc_name, pos);
}

void ir_emit_increment(irProcedure *proc, irValue *addr) {
	GB_ASSERT(is_type_pointer(ir_type(addr)));
	Type *type = type_deref(ir_type(addr));
	ir_emit_store(proc, addr, ir_emit_arith(proc, Token_Add, ir_emit_load(proc, addr), v_one, type));

}

void ir_init_data_with_defaults(irProcedure *proc, irValue *ptr, irValue *count, AstNode *expr) {
	Type *elem_type = type_deref(ir_type(ptr));
	GB_ASSERT(is_type_struct(elem_type) || is_type_array(elem_type));

	irValue *index = ir_add_local_generated(proc, t_int);
	ir_emit_store(proc, index, ir_const_int(proc->module->allocator, 0));

	irBlock *loop = nullptr;
	irBlock *done = nullptr;
	irBlock *body = nullptr;

	loop = ir_new_block(proc, nullptr, "make.init.loop");
	ir_emit_jump(proc, loop);
	ir_start_block(proc, loop);

	body = ir_new_block(proc, nullptr, "make.init.body");
	done = ir_new_block(proc, nullptr, "make.init.done");

	irValue *cond = ir_emit_comp(proc, Token_Lt, ir_emit_load(proc, index), count);
	ir_emit_if(proc, cond, body, done);
	ir_start_block(proc, body);

	irValue *offset_ptr = ir_emit_ptr_offset(proc, ptr, ir_emit_load(proc, index));
	ir_emit_zero_init(proc, offset_ptr, expr);

	ir_emit_increment(proc, index);

	ir_emit_jump(proc, loop);
	ir_start_block(proc, done);
}


irValue *ir_build_builtin_proc(irProcedure *proc, AstNode *expr, TypeAndValue tv, BuiltinProcId id) {
	ast_node(ce, CallExpr, expr);

	switch (id) {
	case BuiltinProc_DIRECTIVE: {
		ast_node(bd, BasicDirective, ce->proc);
		String name = bd->name;
		GB_ASSERT(name == "location");
		String procedure = proc->entity->token.string;
		TokenPos pos = ast_node_token(ce->proc).pos;
		if (ce->args.count > 0) {
			AstNode *ident = unselector_expr(ce->args[0]);
			GB_ASSERT(ident->kind == AstNode_Ident);
			Entity *e = entity_of_ident(proc->module->info, ident);
			GB_ASSERT(e != nullptr);

			if (e->parent_proc_decl != nullptr && e->parent_proc_decl->entity_count > 0) {
				procedure = e->parent_proc_decl->entities[0]->token.string;
			} else {
				procedure = str_lit("");
			}
			pos = e->token.pos;

		}
		return ir_emit_source_code_location(proc, procedure, pos);
	}

	case BuiltinProc_type_info_of: {
		Type *t = default_type(type_of_expr(proc->module->info, ce->args[0]));
		return ir_type_info(proc, t);
		break;
	}

	case BuiltinProc_len: {
		irValue *v = ir_build_expr(proc, ce->args[0]);
		Type *t = base_type(ir_type(v));
		if (is_type_pointer(t)) {
			// IMPORTANT TODO(bill): Should there be a nil pointer check?
			v = ir_emit_load(proc, v);
			t = type_deref(t);
		}
		if (is_type_cstring(t)) {
			return ir_cstring_len(proc, v);
		} else if (is_type_string(t)) {
			return ir_string_len(proc, v);
		} else if (is_type_array(t)) {
			GB_PANIC("Array lengths are constant");
		} else if (is_type_slice(t)) {
			return ir_slice_len(proc, v);
		} else if (is_type_dynamic_array(t)) {
			return ir_dynamic_array_len(proc, v);
		} else if (is_type_map(t)) {
			return ir_map_len(proc, v);
		}

		GB_PANIC("Unreachable");
		break;
	}

	case BuiltinProc_cap: {
		irValue *v = ir_build_expr(proc, ce->args[0]);
		Type *t = base_type(ir_type(v));
		if (is_type_pointer(t)) {
			// IMPORTANT TODO(bill): Should there be a nil pointer check?
			v = ir_emit_load(proc, v);
			t = type_deref(t);
		}
		if (is_type_string(t)) {
			GB_PANIC("Unreachable");
		} else if (is_type_array(t)) {
			GB_PANIC("Array lengths are constant");
		} else if (is_type_slice(t)) {
			return ir_slice_len(proc, v);
		} else if (is_type_dynamic_array(t)) {
			return ir_dynamic_array_cap(proc, v);
		} else if (is_type_map(t)) {
			return ir_map_cap(proc, v);
		}

		GB_PANIC("Unreachable");

		break;
	}

	#if 0
	case BuiltinProc_new: {
		ir_emit_comment(proc, str_lit("new"));
		// proc new(Type) -> ^Type
		gbAllocator a = proc->module->allocator;

		Type *type = type_of_expr(proc->module->info, ce->args[0]);
		Type *allocation_type = type;
		i32 variant_index = 0;
		if (is_type_struct(type)) {
			Type *st = base_type(type);
			if (st->Struct.variant_parent != nullptr) {
				allocation_type = st->Struct.variant_parent;
				variant_index = st->Struct.variant_index;
				GB_ASSERT(allocation_type != nullptr);
			}
		}
		Type *ptr_type = alloc_type_pointer(type);

		i64 size  = type_size_of(allocation_type);
		i64 align = type_align_of(allocation_type);

		irValue **args = gb_alloc_array(a, irValue *, 2);
		args[0] = ir_const_int(a, size);
		args[1] = ir_const_int(a, align);
		irValue *call = ir_emit_global_call(proc, "alloc", args, 2);
		irValue *v = ir_emit_conv(proc, call, ptr_type);
		if (type != allocation_type) {
			Type *u = base_type(allocation_type);
			Type *uptr_type = alloc_type_pointer(u);
			irValue *parent = ir_emit_conv(proc, call, uptr_type);
			irValue *tag_ptr = ir_emit_union_tag_ptr(proc, parent);
			ir_emit_store(proc, tag_ptr, ir_const_int(a, variant_index));
		}
		return v;
		break;
	}
	#endif

	case BuiltinProc_make: {
		ir_emit_comment(proc, str_lit("make"));
		gbAllocator a = proc->module->allocator;
		Type *type = type_of_expr(proc->module->info, ce->args[0]);

		String proc_name = {};
		if (proc->entity != nullptr) {
			proc_name = proc->entity->token.string;
		}

		if (is_type_slice(type)) {
			Type *elem_type = core_type(type)->Slice.elem;
			Type *elem_ptr_type = alloc_type_pointer(elem_type);

			i64 esz = type_size_of(elem_type);
			i64 eal = type_align_of(elem_type);

			irValue *elem_size  = ir_const_int(a, esz);
			irValue *elem_align = ir_const_int(a, eal);

			irValue *len = ir_emit_conv(proc, ir_build_expr(proc, ce->args[1]), t_int);

			ir_emit_slice_bounds_check(proc, ast_node_token(ce->args[1]), v_zero, len, len, false);

			irValue *slice_size = len;
			if (esz != 1) {
				slice_size = ir_emit_arith(proc, Token_Mul, elem_size, len, t_int);
			}

			TokenPos pos = ast_node_token(ce->args[0]).pos;

			auto args = array_make<irValue *>(proc->module->allocator, 3);
			args[0] = slice_size;
			args[1] = elem_align;
			args[2] = ir_emit_source_code_location(proc, proc_name, pos);
			irValue *call = ir_emit_global_call(proc, "alloc", args);

			irValue *ptr = ir_emit_conv(proc, call, elem_ptr_type);

			if (ir_type_has_default_values(elem_type)) {
				ir_init_data_with_defaults(proc, ptr, len, expr);
			}

			irValue *slice = ir_add_local_generated(proc, type);
			ir_fill_slice(proc, slice, ptr, len);
			return ir_emit_load(proc, slice);
		} else if (is_type_map(type)) {
			irValue *int_16 = ir_const_int(a, 16);
			irValue *cap = int_16;
			if (ce->args.count == 2) {
				cap = ir_emit_conv(proc, ir_build_expr(proc, ce->args[1]), t_int);
			}

			irValue *cond = ir_emit_comp(proc, Token_Gt, cap, v_zero);
			cap = ir_emit_select(proc, cond, cap, int_16);

			irValue *map = ir_add_local_generated(proc, type);
			irValue *header = ir_gen_map_header(proc, map, base_type(type));

			auto args = array_make<irValue *>(proc->module->allocator, 3);
			args[0] = header;
			args[1] = cap;
			args[2] = ir_emit_source_code_location(proc, ce->args[0]);
			ir_emit_global_call(proc, "__dynamic_map_reserve", args);

			return ir_emit_load(proc, map);
		} else if (is_type_dynamic_array(type)) {
			Type *elem_type = base_type(type)->DynamicArray.elem;
			irValue *len = v_zero;
			if (ce->args.count > 1) {
				len = ir_emit_conv(proc, ir_build_expr(proc, ce->args[1]), t_int);
			}
			irValue *cap = len;
			if (ce->args.count > 2) {
				cap = ir_emit_conv(proc, ir_build_expr(proc, ce->args[2]), t_int);
			}

			ir_emit_dynamic_array_bounds_check(proc, ast_node_token(ce->args[0]), v_zero, len, cap);

			irValue *array = ir_add_local_generated(proc, type);

			auto args = array_make<irValue *>(proc->module->allocator, 6);
			args[0] = ir_emit_conv(proc, array, t_rawptr);
			args[1] = ir_const_int(a, type_size_of(elem_type));
			args[2] = ir_const_int(a, type_align_of(elem_type));
			args[3] = len;
			args[4] = cap;
			args[5] = ir_emit_source_code_location(proc, ce->args[0]);
			ir_emit_global_call(proc, "__dynamic_array_make", args);

			if (ir_type_has_default_values(elem_type)) {
				ir_init_data_with_defaults(proc, ir_dynamic_array_elem(proc, ir_emit_load(proc, array)), len, expr);
			}

			return ir_emit_load(proc, array);
		}
		break;
	}

	#if 0
	case BuiltinProc_free: {
		ir_emit_comment(proc, str_lit("free"));

		gbAllocator a = proc->module->allocator;

		AstNode *node = ce->args[0];
		TypeAndValue tav = type_and_value_of_expr(proc->module->info, node);
		Type *type = base_type(tav.type);

		if (is_type_dynamic_array(type)) {
			irValue *val = ir_build_expr(proc, node);
			irValue *da_allocator = ir_emit_struct_ev(proc, val, 3);

			irValue *ptr = ir_emit_struct_ev(proc, val, 0);
			ptr = ir_emit_conv(proc, ptr, t_rawptr);

			irValue **args = gb_alloc_array(a, irValue *, 1);
			args[0] = da_allocator;
			args[1] = ptr;
			return ir_emit_global_call(proc, "free_ptr_with_allocator", args, 2);
		} else if (is_type_map(type)) {
			irValue *map = ir_build_expr(proc, node);
			irValue *map_ptr = ir_address_from_load_or_generate_local(proc, map);

			{
				irValue *array = ir_emit_struct_ep(proc, map_ptr, 0);

				irValue *da_allocator = ir_emit_load(proc, ir_emit_struct_ep(proc, array, 3));
				irValue *da_ptr = ir_emit_load(proc, ir_emit_struct_ep(proc, array, 0));
				da_ptr = ir_emit_conv(proc, da_ptr, t_rawptr);

				irValue **args = gb_alloc_array(a, irValue *, 1);
				args[0] = da_allocator;
				args[1] = da_ptr;
				ir_emit_global_call(proc, "free_ptr_with_allocator", args, 2);
			}
			{
				irValue *array = ir_emit_struct_ep(proc, map_ptr, 1);

				irValue *da_allocator = ir_emit_load(proc, ir_emit_struct_ep(proc, array, 3));
				irValue *da_ptr = ir_emit_load(proc, ir_emit_struct_ep(proc, array, 0));
				da_ptr = ir_emit_conv(proc, da_ptr, t_rawptr);

				irValue **args = gb_alloc_array(a, irValue *, 1);
				args[0] = da_allocator;
				args[1] = da_ptr;
				ir_emit_global_call(proc, "free_ptr_with_allocator", args, 2);
			}
			return nullptr;
		}

		irValue *val = ir_build_expr(proc, node);
		irValue *ptr = nullptr;
		if (is_type_pointer(type)) {
			ptr = val;
		} else if (is_type_slice(type)) {
			ptr = ir_slice_elem(proc, val);
		} else if (is_type_string(type)) {
			ptr = ir_string_elem(proc, val);
		} else {
			GB_PANIC("Invalid type to 'free'");
		}

		if (ptr == nullptr) {
			return nullptr;
		}

		ptr = ir_emit_conv(proc, ptr, t_rawptr);

		irValue **args = gb_alloc_array(a, irValue *, 1);
		args[0] = ptr;
		return ir_emit_global_call(proc, "free_ptr", args, 1);
		break;
	}
	#endif
	#if 0
	case BuiltinProc_reserve: {
		ir_emit_comment(proc, str_lit("reserve"));
		gbAllocator a = proc->module->allocator;

		irValue *ptr = ir_build_addr_ptr(proc, ce->args[0]);
		Type *type = ir_type(ptr);
		GB_ASSERT(is_type_pointer(type));
		type = base_type(type_deref(type));

		irValue *capacity = ir_emit_conv(proc, ir_build_expr(proc, ce->args[1]), t_int);

		if (is_type_dynamic_array(type)) {
			Type *elem = type->DynamicArray.elem;

			irValue *elem_size  = ir_const_int(a, type_size_of(elem));
			irValue *elem_align = ir_const_int(a, type_align_of(elem));

			ptr = ir_emit_conv(proc, ptr, t_rawptr);

			irValue **args = gb_alloc_array(a, irValue *, 4);
			args[0] = ptr;
			args[1] = elem_size;
			args[2] = elem_align;
			args[3] = capacity;
			return ir_emit_global_call(proc, "__dynamic_array_reserve", args, 4);
		} else if (is_type_map(type)) {
			irValue **args = gb_alloc_array(a, irValue *, 2);
			args[0] = ir_gen_map_header(proc, ptr, type);
			args[1] = capacity;
			return ir_emit_global_call(proc, "__dynamic_map_reserve", args, 2);
		} else {
			GB_PANIC("Unknown type for 'reserve'");
		}
		break;
	}
	#endif
	#if 0
	case BuiltinProc_clear: {
		ir_emit_comment(proc, str_lit("clear"));
		Type *original_type = type_of_expr(proc->module->info, ce->args[0]);
		irAddr addr = ir_build_addr(proc, ce->args[0]);
		irValue *ptr = addr.addr;
		if (is_double_pointer(ir_type(ptr))) {
			ptr = ir_addr_load(proc, addr);
		}
		Type *t = base_type(type_deref(original_type));
		if (is_type_dynamic_array(t)) {
			irValue *count_ptr = ir_emit_struct_ep(proc, ptr, 1);
			ir_emit_store(proc, count_ptr, v_zero);
		} else if (is_type_map(t)) {
			irValue *ha = ir_emit_struct_ep(proc, ptr, 0);
			irValue *ea = ir_emit_struct_ep(proc, ptr, 1);
			ir_emit_store(proc, ir_emit_struct_ep(proc, ha, 1), v_zero);
			ir_emit_store(proc, ir_emit_struct_ep(proc, ea, 1), v_zero);
		} else if (is_type_slice(t)) {
			irValue *count_ptr = ir_emit_struct_ep(proc, ptr, 1);
			ir_emit_store(proc, count_ptr, v_zero);
		} else {
			GB_PANIC("TODO(bill): ir clear for '%s'", type_to_string(t));
		}
		return nullptr;
		break;
	}
	#endif
	#if 0
	case BuiltinProc_append: {
		ir_emit_comment(proc, str_lit("append"));
		gbAllocator a = proc->module->allocator;

		Type *value_type = type_of_expr(proc->module->info, ce->args[0]);
		irAddr array_addr = ir_build_addr(proc, ce->args[0]);
		irValue *array_ptr = array_addr.addr;
		if (is_double_pointer(ir_type(array_ptr))) {
			array_ptr = ir_addr_load(proc, array_addr);
		}
		Type *type = ir_type(array_ptr);
		{
			TokenPos pos = ast_node_token(ce->args[0]).pos;
			GB_ASSERT_MSG(is_type_pointer(type), "%.*s(%td) %s",
			              LIT(pos.file), pos.line,
			              type_to_string(type));
		}
		type = base_type(type_deref(type));
		Type *elem_type = nullptr;
		bool is_slice = false;
		if (is_type_dynamic_array(type)) {
			elem_type = type->DynamicArray.elem;
		} else if (is_type_slice(type)) {
			is_slice = true;
			elem_type = type->Slice.elem;
		} else {
			GB_PANIC("Invalid type to append");
		}

		irValue *elem_size  = ir_const_int(a, type_size_of(elem_type));
		irValue *elem_align = ir_const_int(a, type_align_of(elem_type));

		array_ptr = ir_emit_conv(proc, array_ptr, t_rawptr);

		isize arg_index = 0;
		isize arg_count = 0;
		for_array(i, ce->args) {
			AstNode *a = ce->args[i];
			Type *at = base_type(type_of_expr(proc->module->info, a));
			if (at->kind == Type_Tuple) {
				arg_count += at->Tuple.variable_count;
			} else {
				arg_count++;
			}
		}

		irValue **args = gb_alloc_array(proc->module->allocator, irValue *, arg_count);
		bool vari_expand = ce->ellipsis.pos.line != 0;

		for_array(i, ce->args) {
			irValue *a = ir_build_expr(proc, ce->args[i]);
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

		if (!vari_expand) {
			for (isize i = 1; i < arg_count; i++) {
				args[i] = ir_emit_conv(proc, args[i], elem_type);
			}
		}

		if (!vari_expand) {
			ir_emit_comment(proc, str_lit("variadic call argument generation"));
			Type *slice_type = alloc_type_slice(elem_type);
			irValue *slice = ir_add_local_generated(proc, slice_type);
			isize slice_len = arg_count-1;

			if (slice_len > 0) {
				irValue *base_array = ir_add_local_generated(proc, alloc_type_array(elem_type, slice_len));

				for (isize i = 1; i < arg_count; i++) {
					irValue *addr = ir_emit_array_epi(proc, base_array, i-1);
					ir_emit_store(proc, addr, args[i]);
				}

				irValue *base_elem  = ir_emit_array_epi(proc, base_array, 0);
				irValue *len = ir_const_int(a, slice_len);
				ir_fill_slice(proc, slice, base_elem, len, len);
			}

			arg_count = 2;
			args[arg_count-1] = ir_emit_load(proc, slice);
		}

		irValue *item_slice = args[1];
		irValue *items = ir_slice_elem(proc, item_slice);
		irValue *item_count = ir_slice_len(proc, item_slice);

		irValue **daa_args = gb_alloc_array(a, irValue *, 5);
		daa_args[0] = array_ptr;
		daa_args[1] = elem_size;
		daa_args[2] = elem_align;
		daa_args[3] = ir_emit_conv(proc, items, t_rawptr);
		daa_args[4] = ir_emit_conv(proc, item_count, t_int);

		if (is_slice) {
		return ir_emit_global_call(proc, "__slice_append", daa_args, 5);
		}
		return ir_emit_global_call(proc, "__dynamic_array_append", daa_args, 5);
		break;
	}
	#endif
	#if 0
	case BuiltinProc_delete: {
		ir_emit_comment(proc, str_lit("delete"));
		irValue *map = ir_build_expr(proc, ce->args[0]);
		irValue *key = ir_build_expr(proc, ce->args[1]);
		Type *map_type = ir_type(map);
		GB_ASSERT(is_type_map(map_type));
		Type *key_type = base_type(map_type)->Map.key;

		irValue *addr = ir_address_from_load_or_generate_local(proc, map);

		gbAllocator a = proc->module->allocator;
		irValue **args = gb_alloc_array(a, irValue *, 2);
		args[0] = ir_gen_map_header(proc, addr, map_type);
		args[1] = ir_gen_map_key(proc, key, key_type);
		return ir_emit_global_call(proc, "__dynamic_map_delete", args, 2);
		break;
	}
	#endif

	case BuiltinProc_swizzle: {
		ir_emit_comment(proc, str_lit("swizzle.begin"));
		irAddr addr = ir_build_addr(proc, ce->args[0]);
		isize index_count = ce->args.count-1;
		if (index_count == 0) {
			return ir_addr_load(proc, addr);
		}
		irValue *src = ir_addr_get_ptr(proc, addr);
		irValue *dst = ir_add_local_generated(proc, tv.type);

		for (i32 i = 1; i < ce->args.count; i++) {
			TypeAndValue tv = type_and_value_of_expr(proc->module->info, ce->args[i]);
			GB_ASSERT(is_type_integer(tv.type));
			GB_ASSERT(tv.value.kind == ExactValue_Integer);

			i32 src_index = cast(i32)tv.value.value_integer;
			i32 dst_index = i-1;

			irValue *src_elem = ir_emit_array_epi(proc, src, src_index);
			irValue *dst_elem = ir_emit_array_epi(proc, dst, dst_index);

			ir_emit_store(proc, dst_elem, ir_emit_load(proc, src_elem));
		}
		ir_emit_comment(proc, str_lit("swizzle.end"));
		return ir_emit_load(proc, dst);
	}

	case BuiltinProc_complex: {
		ir_emit_comment(proc, str_lit("complex"));
		irValue *real = ir_build_expr(proc, ce->args[0]);
		irValue *imag = ir_build_expr(proc, ce->args[1]);
		irValue *dst = ir_add_local_generated(proc, tv.type);

		Type *ft = base_complex_elem_type(tv.type);
		real = ir_emit_conv(proc, real, ft);
		imag = ir_emit_conv(proc, imag, ft);
		ir_emit_store(proc, ir_emit_struct_ep(proc, dst, 0), real);
		ir_emit_store(proc, ir_emit_struct_ep(proc, dst, 1), imag);

		return ir_emit_load(proc, dst);
		break;
	}

	case BuiltinProc_real: {
		ir_emit_comment(proc, str_lit("real"));
		irValue *val = ir_build_expr(proc, ce->args[0]);
		irValue *real = ir_emit_struct_ev(proc, val, 0);
		return ir_emit_conv(proc, real, tv.type);
		break;
	}
	case BuiltinProc_imag: {
		ir_emit_comment(proc, str_lit("imag"));
		irValue *val = ir_build_expr(proc, ce->args[0]);
		irValue *imag = ir_emit_struct_ev(proc, val, 1);
		return ir_emit_conv(proc, imag, tv.type);
		break;
	}

	case BuiltinProc_conj: {
		ir_emit_comment(proc, str_lit("conj"));
		irValue *val = ir_build_expr(proc, ce->args[0]);
		irValue *res = nullptr;
		Type *t = ir_type(val);
		if (is_type_complex(t)) {
			res = ir_add_local_generated(proc, tv.type);
			irValue *real = ir_emit_struct_ev(proc, val, 0);
			irValue *imag = ir_emit_struct_ev(proc, val, 1);
			imag = ir_emit_unary_arith(proc, Token_Sub, imag, ir_type(imag));
			ir_emit_store(proc, ir_emit_struct_ep(proc, res, 0), real);
			ir_emit_store(proc, ir_emit_struct_ep(proc, res, 1), imag);
		}
		return ir_emit_load(proc, res);
		break;
	}

	case BuiltinProc_expand_to_tuple: {
		ir_emit_comment(proc, str_lit("expand_to_tuple"));
		irValue *s = ir_build_expr(proc, ce->args[0]);
		Type *t = base_type(ir_type(s));

		GB_ASSERT(t->kind == Type_Struct);
		GB_ASSERT(is_type_tuple(tv.type));

		irValue *tuple = ir_add_local_generated(proc, tv.type);
		for_array(src_index, t->Struct.fields) {
			Entity *field = t->Struct.fields[src_index];
			i32 field_index = field->Variable.field_index;
			irValue *f = ir_emit_struct_ev(proc, s, field_index);
			irValue *ep = ir_emit_struct_ep(proc, tuple, cast(i32)src_index);
			ir_emit_store(proc, ep, f);
		}
		return ir_emit_load(proc, tuple);
	}

	case BuiltinProc_min: {
		ir_emit_comment(proc, str_lit("min"));
		Type *t = type_of_expr(proc->module->info, expr);
		return ir_emit_min(proc, t, ir_build_expr(proc, ce->args[0]), ir_build_expr(proc, ce->args[1]));
	}

	case BuiltinProc_max: {
		ir_emit_comment(proc, str_lit("max"));
		Type *t = type_of_expr(proc->module->info, expr);
		return ir_emit_max(proc, t, ir_build_expr(proc, ce->args[0]), ir_build_expr(proc, ce->args[1]));
	}

	case BuiltinProc_abs: {
		ir_emit_comment(proc, str_lit("abs"));
		gbAllocator a = proc->module->allocator;
		irValue *x = ir_build_expr(proc, ce->args[0]);
		Type *t = ir_type(x);
		if (is_type_complex(t)) {
			i64 sz = 8*type_size_of(t);
			auto args = array_make<irValue *>(proc->module->allocator, 1);
			args[0] = x;
			switch (sz) {
			case 64:  return ir_emit_global_call(proc, "__abs_complex64",  args);
			case 128: return ir_emit_global_call(proc, "__abs_complex128", args);
			}
			GB_PANIC("Unknown complex type");
		} else if (is_type_float(t)) {
			i64 sz = 8*type_size_of(t);
			auto args = array_make<irValue *>(proc->module->allocator, 1);
			args[0] = x;
			switch (sz) {
			case 32: return ir_emit_global_call(proc, "__abs_f32", args);
			case 64: return ir_emit_global_call(proc, "__abs_f64", args);
			}
			GB_PANIC("Unknown float type");
		}
		irValue *zero = ir_emit_conv(proc, v_zero, t);
		irValue *cond = ir_emit_comp(proc, Token_Lt, x, zero);
		irValue *neg = ir_emit(proc, ir_instr_unary_op(proc, Token_Sub, x, t));
		return ir_emit_select(proc, cond, neg, x);
	}

	case BuiltinProc_clamp: {
		ir_emit_comment(proc, str_lit("clamp"));
		Type *t = type_of_expr(proc->module->info, expr);
		return ir_emit_clamp(proc, t,
		                     ir_build_expr(proc, ce->args[0]),
		                     ir_build_expr(proc, ce->args[1]),
		                     ir_build_expr(proc, ce->args[2]));
	}
	}

	GB_PANIC("Unhandled built-in procedure");
	return nullptr;
}

irValue *ir_build_expr_internal(irProcedure *proc, AstNode *expr);

irValue *ir_build_expr(irProcedure *proc, AstNode *expr) {
	irValue *v = ir_build_expr_internal(proc, expr);
	ir_add_debug_location_to_value(proc, v, expr);
	return v;
}

irValue *ir_build_expr_internal(irProcedure *proc, AstNode *expr) {
	expr = unparen_expr(expr);

	TypeAndValue tv = type_and_value_of_expr(proc->module->info, expr);
	GB_ASSERT(tv.mode != Addressing_Invalid);
	GB_ASSERT(tv.mode != Addressing_Type);

	#if 0
	if (tv.mode == Addressing_Type) {
		// // TODO(bill): Handle this correctly
		#if 0
		i32 entry_index = type_info_index(proc->module->info, tv.type, false);
		if (entry_index >= 0) {
			return ir_get_type_info_ptr(proc, tv.type);
			// i32 id = entry_index+1;
			// return ir_value_constant(proc->module->allocator, t_int, exact_value_i64(id));
		}
		#endif
		// return v_raw_nil;
		return ir_value_nil(proc->module->allocator, tv.type);
	}
	#endif

	if (tv.value.kind != ExactValue_Invalid) {
		// NOTE(bill): Edge case
		if (tv.value.kind != ExactValue_Compound &&
		    is_type_array(tv.type)) {
			Type *elem = core_array_type(tv.type);
			ExactValue value = convert_exact_value_for_type(tv.value, elem);
			irValue *x = ir_add_module_constant(proc->module, elem, value);
			return ir_emit_conv(proc, x, tv.type);
		}

		return ir_add_module_constant(proc->module, tv.type, tv.value);
	}

	if (tv.mode == Addressing_Variable) {
		return ir_addr_load(proc, ir_build_addr(proc, expr));
	}

	switch (expr->kind) {
	case_ast_node(bl, BasicLit, expr);
		TokenPos pos = bl->token.pos;
		GB_PANIC("Non-constant basic literal %.*s(%td:%td) - %.*s", LIT(pos.file), pos.line, pos.column, LIT(token_strings[bl->token.kind]));
	case_end;

	case_ast_node(bd, BasicDirective, expr);
		TokenPos pos = bd->token.pos;
		GB_PANIC("Non-constant basic literal %.*s(%td:%td) - %.*s", LIT(pos.file), pos.line, pos.column, LIT(bd->name));
	case_end;

	case_ast_node(i, Implicit, expr);
		return ir_addr_load(proc, ir_build_addr(proc, expr));
	case_end;

	case_ast_node(u, Undef, expr);
		return ir_value_undef(proc->module->allocator, tv.type);
	case_end;

	case_ast_node(i, Ident, expr);
		Entity *e = entity_of_ident(proc->module->info, expr);
		GB_ASSERT_MSG(e != nullptr, "%s", expr_to_string(expr));
		if (e->kind == Entity_Builtin) {
			Token token = ast_node_token(expr);
			GB_PANIC("TODO(bill): ir_build_expr Entity_Builtin '%.*s'\n"
			         "\t at %.*s(%td:%td)", LIT(builtin_procs[e->Builtin.id].name),
			         LIT(token.pos.file), token.pos.line, token.pos.column);
			return nullptr;
		} else if (e->kind == Entity_Nil) {
			return ir_value_nil(proc->module->allocator, tv.type);
		}

		irValue **found = map_get(&proc->module->values, hash_entity(e));
		if (found) {
			irValue *v = *found;
			if (v->kind == irValue_Proc) {
				return v;
			}
			// if (e->kind == Entity_Variable && e->Variable.param) {
				// return v;
			// }
			return ir_emit_load(proc, v);
		} else if (e != nullptr && e->kind == Entity_Variable) {
			return ir_addr_load(proc, ir_build_addr(proc, expr));
		}
		GB_PANIC("nullptr value for expression from identifier: %.*s : %s @ %p", LIT(i->token.string), type_to_string(e->type), expr);
		return nullptr;
	case_end;

	case_ast_node(re, RunExpr, expr);
		// TODO(bill): Run Expression
		return ir_build_expr(proc, re->expr);
	case_end;

	case_ast_node(de, DerefExpr, expr);
		return ir_addr_load(proc, ir_build_addr(proc, expr));
	case_end;

	case_ast_node(se, SelectorExpr, expr);
		TypeAndValue tav = type_and_value_of_expr(proc->module->info, expr);
		GB_ASSERT(tav.mode != Addressing_Invalid);
		return ir_addr_load(proc, ir_build_addr(proc, expr));
	case_end;

	case_ast_node(te, TernaryExpr, expr);
		ir_emit_comment(proc, str_lit("TernaryExpr"));

		auto edges = array_make<irValue *>(proc->module->allocator, 0, 2);

		GB_ASSERT(te->y != nullptr);
		irBlock *then  = ir_new_block(proc, nullptr, "if.then");
		irBlock *done  = ir_new_block(proc, nullptr, "if.done"); // NOTE(bill): Append later
		irBlock *else_ = ir_new_block(proc, nullptr, "if.else");

		irValue *cond = ir_build_cond(proc, te->cond, then, else_);
		ir_start_block(proc, then);

		Type *type = type_of_expr(proc->module->info, expr);

		ir_open_scope(proc);
		array_add(&edges, ir_emit_conv(proc, ir_build_expr(proc, te->x), type));
		ir_close_scope(proc, irDeferExit_Default, nullptr);

		ir_emit_jump(proc, done);
		ir_start_block(proc, else_);

		ir_open_scope(proc);
		array_add(&edges, ir_emit_conv(proc, ir_build_expr(proc, te->y), type));
		ir_close_scope(proc, irDeferExit_Default, nullptr);

		ir_emit_jump(proc, done);
		ir_start_block(proc, done);

		return ir_emit(proc, ir_instr_phi(proc, edges, type));
	case_end;

	case_ast_node(ta, TypeAssertion, expr);
		TokenPos pos = ast_node_token(expr).pos;
		Type *type = tv.type;
		irValue *e = ir_build_expr(proc, ta->expr);
		Type *t = type_deref(ir_type(e));
		if (is_type_union(t)) {
			ir_emit_comment(proc, str_lit("cast - union_cast"));
			return ir_emit_union_cast(proc, e, type, pos);
		} else if (is_type_any(t)) {
			ir_emit_comment(proc, str_lit("cast - any_cast"));
			return ir_emit_any_cast(proc, e, type, pos);
		} else {
			GB_PANIC("TODO(bill): type assertion %s", type_to_string(ir_type(e)));
		}
	case_end;

	case_ast_node(tc, TypeCast, expr);
		irValue *e = ir_build_expr(proc, tc->expr);
		switch (tc->token.kind) {
		case Token_cast:
			return ir_emit_conv(proc, e, tv.type);
		case Token_transmute:
			return ir_emit_transmute(proc, e, tv.type);
		}
		GB_PANIC("Invalid AST TypeCast");
	case_end;

	case_ast_node(ac, AutoCast, expr);
		return ir_build_expr(proc, ac->expr);
	case_end;

	case_ast_node(ue, UnaryExpr, expr);
		switch (ue->op.kind) {
		case Token_And: {
			AstNode *ue_expr = unparen_expr(ue->expr);
			if (ue_expr->kind == AstNode_TypeAssertion) {
				gbAllocator a = proc->module->allocator;


				GB_ASSERT(is_type_pointer(tv.type));

				ast_node(ta, TypeAssertion, ue_expr);
				TokenPos pos = ast_node_token(expr).pos;
				Type *type = type_of_expr(proc->module->info, ue_expr);
				GB_ASSERT(!is_type_tuple(type));

				irValue *e = ir_build_expr(proc, ta->expr);
				Type *t = type_deref(ir_type(e));
				if (is_type_union(t)) {
					irValue *v = e;
					if (!is_type_pointer(ir_type(v))) {
						v = ir_address_from_load_or_generate_local(proc, v);
					}
					Type *src_type = type_deref(ir_type(v));
					Type *dst_type = type;

					irValue *src_tag = ir_emit_load(proc, ir_emit_union_tag_ptr(proc, v));
					irValue *dst_tag = ir_const_union_tag(a, src_type, dst_type);

					irValue *ok = ir_emit_comp(proc, Token_CmpEq, src_tag, dst_tag);
					auto args = array_make<irValue *>(proc->module->allocator, 6);
					args[0] = ok;

					args[1] = ir_find_or_add_entity_string(proc->module, pos.file);
					args[2] = ir_const_int(a, pos.line);
					args[3] = ir_const_int(a, pos.column);

					args[4] = ir_type_info(proc, src_type);
					args[5] = ir_type_info(proc, dst_type);
					ir_emit_global_call(proc, "__type_assertion_check", args);

					irValue *data_ptr = v;
					return ir_emit_conv(proc, data_ptr, tv.type);
				} else if (is_type_any(t)) {
					irValue *v = e;
					if (is_type_pointer(ir_type(v))) {
						v = ir_emit_load(proc, v);
					}

					irValue *data_ptr = ir_emit_struct_ev(proc, v, 0);
					irValue *any_ti = ir_emit_struct_ev(proc, v, 1);
					irValue *ti_ptr = ir_type_info(proc, type);


					irValue *ok = ir_emit_comp(proc, Token_CmpEq, any_ti, ti_ptr);
					auto args = array_make<irValue *>(proc->module->allocator, 6);
					args[0] = ok;

					args[1] = ir_find_or_add_entity_string(proc->module, pos.file);
					args[2] = ir_const_int(a, pos.line);
					args[3] = ir_const_int(a, pos.column);

					args[4] = any_ti;
					args[5] = ti_ptr;
					ir_emit_global_call(proc, "__type_assertion_check", args);

					return ir_emit_conv(proc, data_ptr, tv.type);
				} else {
					GB_PANIC("TODO(bill): type assertion %s", type_to_string(type));
				}

			}

			return ir_emit_ptr_offset(proc, ir_build_addr_ptr(proc, ue->expr), v_zero); // Make a copy of the pointer
		}
		default:
			return ir_emit_unary_arith(proc, ue->op.kind, ir_build_expr(proc, ue->expr), tv.type);
		}
	case_end;

	case_ast_node(be, BinaryExpr, expr);
		irValue *left = ir_build_expr(proc, be->left);
		Type *type = default_type(tv.type);

		switch (be->op.kind) {
		case Token_Add:
		case Token_Sub:
		case Token_Mul:
		case Token_Quo:
		case Token_Mod:
		case Token_ModMod:
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
			break;
		}

		case Token_CmpAnd:
		case Token_CmpOr:
			return ir_emit_logical_binary_expr(proc, expr);

		default:
			GB_PANIC("Invalid binary expression");
			break;
		}
	case_end;

	case_ast_node(pl, ProcLit, expr);
		return ir_gen_anonymous_proc_lit(proc->module, proc->name, expr, proc);
	case_end;


	case_ast_node(cl, CompoundLit, expr);
		return ir_addr_load(proc, ir_build_addr(proc, expr));
	case_end;


	case_ast_node(ce, CallExpr, expr);
		TypeAndValue proc_tv = type_and_value_of_expr(proc->module->info, ce->proc);
		AddressingMode proc_mode = proc_tv.mode;
		if (proc_mode == Addressing_Type) {
			GB_ASSERT(ce->args.count == 1);
			irValue *x = ir_build_expr(proc, ce->args[0]);
			irValue *y = ir_emit_conv(proc, x, tv.type);
			return y;
		}

		AstNode *p = unparen_expr(ce->proc);
		if (proc_mode == Addressing_Builtin) {
			Entity *e = entity_of_ident(proc->module->info, p);
			BuiltinProcId id = BuiltinProc_Invalid;
			if (e != nullptr) {
				id = cast(BuiltinProcId)e->Builtin.id;
			} else {
				id = BuiltinProc_DIRECTIVE;
				if (ce->proc->kind == AstNode_Implicit) {
					ast_node(i, Implicit, ce->proc);
					GB_ASSERT(i->kind == Token_type_info_of);
					id = BuiltinProc_type_info_of;
				}
			}
			return ir_build_builtin_proc(proc, expr, tv, id);
		}

		// NOTE(bill): Regular call
		irValue *value = ir_build_expr(proc, ce->proc);
		GB_ASSERT(value != nullptr);
		Type *proc_type_ = base_type(ir_type(value));
		GB_ASSERT(proc_type_->kind == Type_Proc);
		TypeProc *pt = &proc_type_->Proc;

		if (is_call_expr_field_value(ce)) {
			auto args = array_make<irValue *>(proc->module->allocator, pt->param_count);

			for_array(arg_index, ce->args) {
				AstNode *arg = ce->args[arg_index];
				ast_node(fv, FieldValue, arg);
				GB_ASSERT(fv->field->kind == AstNode_Ident);
				String name = fv->field->Ident.token.string;
				isize index = lookup_procedure_parameter(pt, name);
				GB_ASSERT(index >= 0);
				TypeAndValue tav = type_and_value_of_expr(proc->module->info, fv->value);
				if (tav.mode == Addressing_Type) {
					args[index] = ir_value_nil(proc->module->allocator, tav.type);
				} else {
					args[index] = ir_build_expr(proc, fv->value);
				}
			}
			TypeTuple *params = &pt->params->Tuple;
			for (isize i = 0; i < args.count; i++) {
				Entity *e = params->variables[i];
				if (e->kind == Entity_TypeName) {
					args[i] = ir_value_nil(proc->module->allocator, e->type);
				} else if (e->kind == Entity_Constant) {
					continue;
				} else {
					GB_ASSERT(e->kind == Entity_Variable);
					if (args[i] == nullptr) {
						if (e->Variable.default_value.kind != ExactValue_Invalid) {
							args[i] = ir_value_constant(proc->module->allocator, e->type, e->Variable.default_value);
						} else {
							args[i] = ir_value_nil(proc->module->allocator, e->type);
						}
					} else {
						args[i] = ir_emit_conv(proc, args[i], e->type);
					}
				}
			}
			return ir_emit_call(proc, value, args);
		}

		isize arg_index = 0;

		isize arg_count = 0;
		for_array(i, ce->args) {
			AstNode *arg = ce->args[i];
			TypeAndValue tav = type_and_value_of_expr(proc->module->info, arg);
			GB_ASSERT_MSG(tav.mode != Addressing_Invalid, "%s", expr_to_string(arg));
			GB_ASSERT_MSG(tav.mode != Addressing_ProcGroup, "%s", expr_to_string(arg));
			Type *at = tav.type;
			if (at->kind == Type_Tuple) {
				arg_count += at->Tuple.variables.count;
			} else {
				arg_count++;
			}
		}

		i64 param_count = 0;
		if (pt->params) {
			GB_ASSERT(pt->params->kind == Type_Tuple);
			param_count = pt->params->Tuple.variables.count;
		}

		auto args = array_make<irValue *>(proc->module->allocator, gb_max(param_count, arg_count));
		isize variadic_index = pt->variadic_index;
		bool variadic = pt->variadic && variadic_index >= 0;
		bool vari_expand = ce->ellipsis.pos.line != 0;
		bool is_c_vararg = pt->c_vararg;

		String proc_name = {};
		if (proc->entity != nullptr) {
			proc_name = proc->entity->token.string;
		}
		TokenPos pos = ast_node_token(ce->proc).pos;

		TypeTuple *param_tuple = nullptr;
		if (pt->params) {
			GB_ASSERT(pt->params->kind == Type_Tuple);
			param_tuple = &pt->params->Tuple;
		}

		for_array(i, ce->args) {
			AstNode *arg = ce->args[i];
			TypeAndValue arg_tv = type_and_value_of_expr(proc->module->info, arg);
			if (arg_tv.mode == Addressing_Type) {
				args[arg_index++] = ir_value_nil(proc->module->allocator, arg_tv.type);
			} else {
				irValue *a = ir_build_expr(proc, arg);
				Type *at = ir_type(a);
				if (at->kind == Type_Tuple) {
					for_array(i, at->Tuple.variables) {
						Entity *e = at->Tuple.variables[i];
						irValue *v = ir_emit_struct_ev(proc, a, cast(i32)i);
						args[arg_index++] = v;
					}
				} else {
					args[arg_index++] = a;
				}
			}
		}


		if (param_count > 0) {
			GB_ASSERT_MSG(pt->params != nullptr, "%s %td", expr_to_string(expr), pt->param_count);
			GB_ASSERT(param_count < 1000000);

			if (arg_count < param_count) {
				isize end = param_count;
				if (variadic) {
					end = variadic_index;
				}
				while (arg_index < end) {
					Entity *e = param_tuple->variables[arg_index];
					GB_ASSERT(e->kind == Entity_Variable);
					if (e->Variable.default_value.kind != ExactValue_Invalid) {
						args[arg_index++] = ir_value_constant(proc->module->allocator, e->type, e->Variable.default_value);
					} else if (e->Variable.default_is_location) {
						args[arg_index++] = ir_emit_source_code_location(proc, proc_name, pos);
					} else {
						args[arg_index++] = ir_value_nil(proc->module->allocator, e->type);
					}
				}
			}

			if (is_c_vararg) {
				GB_ASSERT(variadic);
				GB_ASSERT(!vari_expand);
				isize i = 0;
				for (; i < variadic_index; i++) {
					Entity *e = param_tuple->variables[i];
					if (e->kind == Entity_Variable) {
						args[i] = ir_emit_conv(proc, args[i], e->type);
					}
				}
				Type *variadic_type = param_tuple->variables[i]->type;
				GB_ASSERT(is_type_slice(variadic_type));
				variadic_type = base_type(variadic_type)->Slice.elem;
				if (!is_type_any(variadic_type)) {
					for (; i < arg_count; i++) {
						args[i] = ir_emit_conv(proc, args[i], variadic_type);
					}
				} else {
					for (; i < arg_count; i++) {
						args[i] = ir_emit_conv(proc, args[i], default_type(ir_type(args[i])));
					}
				}
			} else if (variadic) {
				isize i = 0;
				for (; i < variadic_index; i++) {
					Entity *e = param_tuple->variables[i];
					if (e->kind == Entity_Variable) {
						args[i] = ir_emit_conv(proc, args[i], e->type);
					}
				}
				if (!vari_expand) {
					Type *variadic_type = param_tuple->variables[i]->type;
					GB_ASSERT(is_type_slice(variadic_type));
					variadic_type = base_type(variadic_type)->Slice.elem;
					for (; i < arg_count; i++) {
						args[i] = ir_emit_conv(proc, args[i], variadic_type);
					}
				}
			} else {
				for (i64 i = 0; i < param_count; i++) {
					Entity *e = param_tuple->variables[i];
					if (e->kind == Entity_Variable) {
						GB_ASSERT(args[i] != nullptr);
						args[i] = ir_emit_conv(proc, args[i], e->type);
					}
				}
			}

			if (variadic && !vari_expand && !is_c_vararg) {
				ir_emit_comment(proc, str_lit("variadic call argument generation"));
				gbAllocator allocator = proc->module->allocator;
				Type *slice_type = param_tuple->variables[variadic_index]->type;
				Type *elem_type  = base_type(slice_type)->Slice.elem;
				irValue *slice = ir_add_local_generated(proc, slice_type);
				isize slice_len = arg_count+1 - (variadic_index+1);

				if (slice_len > 0) {
					irValue *base_array = ir_add_local_generated(proc, alloc_type_array(elem_type, slice_len));

					for (isize i = variadic_index, j = 0; i < arg_count; i++, j++) {
						irValue *addr = ir_emit_array_epi(proc, base_array, cast(i32)j);
						ir_emit_store(proc, addr, args[i]);
					}

					irValue *base_elem = ir_emit_array_epi(proc, base_array, 0);
					irValue *len = ir_const_int(allocator, slice_len);
					ir_fill_slice(proc, slice, base_elem, len);
				}

				arg_count = param_count;
				args[variadic_index] = ir_emit_load(proc, slice);
			}
		}

		if (variadic && variadic_index+1 < param_count) {
			for (isize i = variadic_index+1; i < param_count; i++) {
				Entity *e = param_tuple->variables[i];
				if (e->Variable.default_value.kind != ExactValue_Invalid) {
					args[i] = ir_value_constant(proc->module->allocator, e->type, e->Variable.default_value);
				} else if (e->Variable.default_is_location) {
					args[i] = ir_emit_source_code_location(proc, proc_name, pos);
				} else {
					args[i] = ir_value_nil(proc->module->allocator, e->type);
				}
			}
		}

		i64 final_count = param_count;
		if (is_c_vararg) {
			final_count = arg_count;
		}

		auto call_args = array_slice(args, 0, final_count);
		return ir_emit_call(proc, value, call_args);
	case_end;

	case_ast_node(se, SliceExpr, expr);
		return ir_addr_load(proc, ir_build_addr(proc, expr));
	case_end;

	case_ast_node(ie, IndexExpr, expr);
		return ir_addr_load(proc, ir_build_addr(proc, expr));
	case_end;
	}

	GB_PANIC("Unexpected expression: %.*s", LIT(ast_node_strings[expr->kind]));
	return nullptr;
}

irValue *ir_get_using_variable(irProcedure *proc, Entity *e) {
	GB_ASSERT(e->kind == Entity_Variable && e->flags & EntityFlag_Using);
	String name = e->token.string;
	Entity *parent = e->using_parent;
	Selection sel = lookup_field(parent->type, name, false);
	GB_ASSERT(sel.entity != nullptr);
	irValue **pv = map_get(&proc->module->values, hash_entity(parent));
	irValue *v = nullptr;
	if (pv != nullptr) {
		v = *pv;
	} else {
		GB_ASSERT_MSG(e->using_expr != nullptr, "%.*s", LIT(name));
		v = ir_build_addr_ptr(proc, e->using_expr);
	}
	GB_ASSERT(v != nullptr);
	GB_ASSERT(parent->type == type_deref(ir_type(v)));
	return ir_emit_deep_field_gep(proc, v, sel);
}

bool ir_is_elem_const(irModule *m, AstNode *elem, Type *elem_type) {
	if (!elem_type_can_be_constant(elem_type)) {
		return false;
	}
	if (elem->kind == AstNode_FieldValue) {
		elem = elem->FieldValue.value;
	}
	TypeAndValue tav = type_and_value_of_expr(m->info, elem);
	GB_ASSERT_MSG(tav.mode != Addressing_Invalid, "%s %s", expr_to_string(elem), type_to_string(tav.type));
	return tav.value.kind != ExactValue_Invalid;
}

irAddr ir_build_addr_from_entity(irProcedure *proc, Entity *e, AstNode *expr) {
	GB_ASSERT(e != nullptr);
	GB_ASSERT(e->kind != Entity_Constant);

	irValue *v = nullptr;
	irValue **found = map_get(&proc->module->values, hash_entity(e));
	if (found) {
		v = *found;
	} else if (e->kind == Entity_Variable && e->flags & EntityFlag_Using) {
		// NOTE(bill): Calculate the using variable every time
		v = ir_get_using_variable(proc, e);
	}

	if (v == nullptr) {
		error(expr, "%.*s Unknown value: %.*s, entity: %p %.*s",
		      LIT(proc->name),
		      LIT(e->token.string), e, LIT(entity_strings[e->kind]));
		GB_PANIC("Unknown value");
	}

	return ir_addr(v);
}

irAddr ir_build_addr(irProcedure *proc, AstNode *expr) {
	switch (expr->kind) {
	case_ast_node(i, Implicit, expr);
		irValue *v = nullptr;
		switch (i->kind) {
		case Token_context:
			v = ir_find_or_generate_context_ptr(proc);
			break;
		}

		GB_ASSERT(v != nullptr);
		return ir_addr(v);
	case_end;

	case_ast_node(i, Ident, expr);
		if (is_blank_ident(expr)) {
			irAddr val = {};
			return val;
		}
		String name = i->token.string;
		Entity *e = entity_of_ident(proc->module->info, expr);
		// GB_ASSERT(name == e->token.string);
		return ir_build_addr_from_entity(proc, e, expr);
	case_end;

	case_ast_node(pe, ParenExpr, expr);
		return ir_build_addr(proc, unparen_expr(expr));
	case_end;

	case_ast_node(se, SelectorExpr, expr);
		ir_emit_comment(proc, str_lit("SelectorExpr"));
		AstNode *sel = unparen_expr(se->selector);
		if (sel->kind == AstNode_Ident) {
			String selector = sel->Ident.token.string;
			TypeAndValue tav = type_and_value_of_expr(proc->module->info, se->expr);

			if (tav.mode == Addressing_Invalid) {
				// NOTE(bill): Imports
				Entity *imp = entity_of_ident(proc->module->info, se->expr);
				if (imp != nullptr) {
					GB_ASSERT(imp->kind == Entity_ImportName);
				}
				return ir_build_addr(proc, unparen_expr(se->selector));
			}


			Type *type = base_type(tav.type);
			if (tav.mode == Addressing_Type) { // Addressing_Type
				Selection sel = lookup_field(type, selector, true);
				Entity *e = sel.entity;
				GB_ASSERT(e->kind == Entity_Variable);
				GB_ASSERT(e->flags & EntityFlag_TypeField);
				String name = e->token.string;
				if (name == "names") {
					irValue *ti_ptr = ir_type_info(proc, type);
					irValue *variant = ir_emit_struct_ep(proc, ti_ptr, 2);

					irValue *names_ptr = nullptr;

					if (is_type_enum(type)) {
						irValue *enum_info = ir_emit_conv(proc, variant, t_type_info_enum_ptr);
						names_ptr = ir_emit_struct_ep(proc, enum_info, 1);
					} else if (type->kind == Type_Struct) {
						irValue *struct_info = ir_emit_conv(proc, variant, t_type_info_struct_ptr);
						names_ptr = ir_emit_struct_ep(proc, struct_info, 1);
					}
					return ir_addr(names_ptr);
				} else {
					GB_PANIC("Unhandled TypeField %.*s", LIT(name));
				}
				GB_PANIC("Unreachable");
			}

			Selection sel = lookup_field(type, selector, false);
			GB_ASSERT(sel.entity != nullptr);


			if (sel.entity->type->kind == Type_BitFieldValue) {
				irAddr addr = ir_build_addr(proc, se->expr);
				Type *bft = type_deref(ir_addr_type(addr));
				if (sel.index.count == 1) {
					GB_ASSERT(is_type_bit_field(bft));
					i32 index = sel.index[0];
					return ir_addr_bit_field(ir_addr_get_ptr(proc, addr), index);
				} else {
					Selection s = sel;
					s.index.count--;
					i32 index = s.index[s.index.count-1];
					irValue *a = ir_addr_get_ptr(proc, addr);
					a = ir_emit_deep_field_gep(proc, a, s);
					return ir_addr_bit_field(a, index);
				}
			} else {
				irValue *a = ir_build_addr_ptr(proc, se->expr);
				a = ir_emit_deep_field_gep(proc, a, sel);
				return ir_addr(a);
			}
		} else {
			// NOTE(bill): x.0
			Type *type = type_deref(type_of_expr(proc->module->info, se->expr));
			Type *selector_type = base_type(type_of_expr(proc->module->info, se->selector));
			GB_ASSERT_MSG(is_type_integer(selector_type), "%s", type_to_string(selector_type));
			ExactValue val = type_and_value_of_expr(proc->module->info, sel).value;
			i64 index = val.value_integer;

			Selection sel = lookup_field_from_index(type, index);
			GB_ASSERT(sel.entity != nullptr);

			irValue *a = ir_build_addr_ptr(proc, se->expr);
			a = ir_emit_deep_field_gep(proc, a, sel);
			return ir_addr(a);
		}
	case_end;

	case_ast_node(ta, TypeAssertion, expr);
		gbAllocator a = proc->module->allocator;
		TokenPos pos = ast_node_token(expr).pos;
		irValue *e = ir_build_expr(proc, ta->expr);
		Type *t = type_deref(ir_type(e));
		if (is_type_union(t)) {
			Type *type = type_of_expr(proc->module->info, expr);
			irValue *v = ir_add_local_generated(proc, type);
			ir_emit_comment(proc, str_lit("cast - union_cast"));
			ir_emit_store(proc, v, ir_emit_union_cast(proc, ir_build_expr(proc, ta->expr), type, pos));
			return ir_addr(v);
		} else if (is_type_any(t)) {
			ir_emit_comment(proc, str_lit("cast - any_cast"));
			Type *type = type_of_expr(proc->module->info, expr);
			return ir_emit_any_cast_addr(proc, ir_build_expr(proc, ta->expr), type, pos);
		} else {
			GB_PANIC("TODO(bill): type assertion %s", type_to_string(ir_type(e)));
		}
	case_end;

	case_ast_node(ue, UnaryExpr, expr);
		switch (ue->op.kind) {
		case Token_And: {
			return ir_build_addr(proc, ue->expr);
		}
		default:
			GB_PANIC("Invalid unary expression for ir_build_addr");
		}
	case_end;

	case_ast_node(be, BinaryExpr, expr);
		irValue *v = ir_build_expr(proc, expr);
		Type *t = ir_type(v);
		GB_ASSERT(is_type_pointer(t));
		return ir_addr(v);
	case_end;

	case_ast_node(ie, IndexExpr, expr);
		ir_emit_comment(proc, str_lit("IndexExpr"));
		Type *t = base_type(type_of_expr(proc->module->info, ie->expr));
		gbAllocator a = proc->module->allocator;

		bool deref = is_type_pointer(t);
		t = base_type(type_deref(t));
		GB_ASSERT_MSG(is_type_indexable(t), "%s %s", type_to_string(t), expr_to_string(expr));

		if (is_type_map(t)) {
			irValue *map_val = ir_build_addr_ptr(proc, ie->expr);
			if (deref) {
				map_val = ir_emit_load(proc, map_val);
			}

			irValue *key = ir_build_expr(proc, ie->index);
			key = ir_emit_conv(proc, key, t->Map.key);

			Type *result_type = type_of_expr(proc->module->info, expr);
			return ir_addr_map(map_val, key, t, result_type);
		}

		irValue *using_addr = nullptr;

		switch (t->kind) {
		case Type_Array: {
			irValue *array = nullptr;
			if (using_addr != nullptr) {
				array = using_addr;
			} else {
				array = ir_build_addr_ptr(proc, ie->expr);
				if (deref) {
					array = ir_emit_load(proc, array);
				}
			}
			irValue *index = ir_emit_conv(proc, ir_build_expr(proc, ie->index), t_int);
			irValue *elem = ir_emit_array_ep(proc, array, index);

			auto index_tv = type_and_value_of_expr(proc->module->info, ie->index);
			if (index_tv.mode != Addressing_Constant) {
				irValue *len = ir_const_int(a, t->Array.count);
				ir_emit_bounds_check(proc, ast_node_token(ie->index), index, len);
			}
			return ir_addr(elem);
			break;
		}

		case Type_Slice: {
			irValue *slice = nullptr;
			if (using_addr != nullptr) {
				slice = ir_emit_load(proc, using_addr);
			} else {
				slice = ir_build_expr(proc, ie->expr);
				if (deref) {
					slice = ir_emit_load(proc, slice);
				}
			}
			irValue *elem = ir_slice_elem(proc, slice);
			irValue *index = ir_emit_conv(proc, ir_build_expr(proc, ie->index), t_int);
			irValue *len = ir_slice_len(proc, slice);
			ir_emit_bounds_check(proc, ast_node_token(ie->index), index, len);
			irValue *v = ir_emit_ptr_offset(proc, elem, index);
			return ir_addr(v);
			break;
		}

		case Type_DynamicArray: {
			irValue *dynamic_array = nullptr;
			if (using_addr != nullptr) {
				dynamic_array = ir_emit_load(proc, using_addr);
			} else {
				dynamic_array = ir_build_expr(proc, ie->expr);
				if (deref) {
					dynamic_array = ir_emit_load(proc, dynamic_array);
				}
			}
			irValue *elem = ir_dynamic_array_elem(proc, dynamic_array);
			irValue *len = ir_dynamic_array_len(proc, dynamic_array);
			irValue *index = ir_emit_conv(proc, ir_build_expr(proc, ie->index), t_int);
			ir_emit_bounds_check(proc, ast_node_token(ie->index), index, len);
			irValue *v = ir_emit_ptr_offset(proc, elem, index);
			return ir_addr(v);
			break;
		}


		case Type_Basic: { // Basic_string
			irValue *str;
			irValue *elem;
			irValue *len;
			irValue *index;

			if (using_addr != nullptr) {
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

			return ir_addr(ir_emit_ptr_offset(proc, elem, index));
			break;
		}
		}
	case_end;

	case_ast_node(se, SliceExpr, expr);
		ir_emit_comment(proc, str_lit("SliceExpr"));
		gbAllocator a = proc->module->allocator;
		irValue *low  = v_zero;
		irValue *high = nullptr;

		if (se->low  != nullptr) low  = ir_build_expr(proc, se->low);
		if (se->high != nullptr) high = ir_build_expr(proc, se->high);

		if (high != nullptr && se->interval.kind == Token_Ellipsis) {
			high = ir_emit_arith(proc, Token_Add, high, v_one, t_int);
		}

		irValue *addr = ir_build_addr_ptr(proc, se->expr);
		irValue *base = ir_emit_load(proc, addr);
		Type *type = base_type(ir_type(base));

		if (is_type_pointer(type)) {
			type = base_type(type_deref(type));
			addr = base;
			base = ir_emit_load(proc, base);
		}
		// TODO(bill): Cleanup like mad!

		switch (type->kind) {
		case Type_Slice: {
			Type *slice_type = type;
			irValue *len = ir_slice_len(proc, base);
			if (high == nullptr) high = len;

			ir_emit_slice_bounds_check(proc, se->open, low, high, len, false);

			irValue *elem   = ir_emit_ptr_offset(proc, ir_slice_elem(proc, base), low);
			irValue *new_len = ir_emit_arith(proc, Token_Sub, high, low, t_int);

			irValue *slice = ir_add_local_generated(proc, slice_type);
			ir_fill_slice(proc, slice, elem, new_len);
			return ir_addr(slice);
		}

		case Type_DynamicArray: {
			Type *elem_type = type->DynamicArray.elem;
			Type *slice_type = alloc_type_slice(elem_type);

			irValue *len = ir_dynamic_array_len(proc, base);
			if (high == nullptr) high = len;

			ir_emit_slice_bounds_check(proc, se->open, low, high, len, false);

			irValue *elem    = ir_emit_ptr_offset(proc, ir_dynamic_array_elem(proc, base), low);
			irValue *new_len = ir_emit_arith(proc, Token_Sub, high, low, t_int);

			irValue *slice = ir_add_local_generated(proc, slice_type);
			ir_fill_slice(proc, slice, elem, new_len);
			return ir_addr(slice);
		}


		case Type_Array: {
			Type *slice_type = alloc_type_slice(type->Array.elem);
			irValue *len = ir_array_len(proc, base);

			if (high == nullptr) high = len;

			bool low_const  = type_and_value_of_expr(proc->module->info, se->low).mode  == Addressing_Constant;
			bool high_const = type_and_value_of_expr(proc->module->info, se->high).mode == Addressing_Constant;

			if (!low_const || !high_const) {
				ir_emit_slice_bounds_check(proc, se->open, low, high, len, false);
			}
			irValue *elem    = ir_emit_ptr_offset(proc, ir_array_elem(proc, addr), low);
			irValue *new_len = ir_emit_arith(proc, Token_Sub, high, low, t_int);

			irValue *slice = ir_add_local_generated(proc, slice_type);
			ir_fill_slice(proc, slice, elem, new_len);
			return ir_addr(slice);
		}

		case Type_Basic: {
			GB_ASSERT(type == t_string);
			irValue *len = ir_string_len(proc, base);
			if (high == nullptr) high = len;
			// if (max == nullptr)  max = ir_string_len(proc, base);

			ir_emit_slice_bounds_check(proc, se->open, low, high, len, true);

			irValue *elem    = ir_emit_ptr_offset(proc, ir_string_elem(proc, base), low);
			irValue *new_len = ir_emit_arith(proc, Token_Sub, high, low, t_int);

			irValue *str = ir_add_local_generated(proc, t_string);
			ir_fill_string(proc, str, elem, new_len);
			return ir_addr(str);
		}
		}

		GB_PANIC("Unknown slicable type");
	case_end;

	case_ast_node(de, DerefExpr, expr);
		// TODO(bill): Is a ptr copy needed?
		irValue *addr = ir_build_expr(proc, de->expr);
		addr = ir_emit_ptr_offset(proc, addr, v_zero);
		return ir_addr(addr);
	case_end;

	case_ast_node(ce, CallExpr, expr);
		// NOTE(bill): This is make sure you never need to have an 'array_ev'
		irValue *e = ir_build_expr(proc, expr);
		irValue *v = ir_add_local_generated(proc, ir_type(e));
		ir_emit_store(proc, v, e);
		return ir_addr(v);
	case_end;

	case_ast_node(cl, CompoundLit, expr);
		ir_emit_comment(proc, str_lit("CompoundLit"));
		Type *type = type_of_expr(proc->module->info, expr);
		Type *bt = base_type(type);

		irValue *v = ir_add_local_generated(proc, type, true);

		Type *et = nullptr;
		switch (bt->kind) {
		case Type_Array:  et = bt->Array.elem;  break;
		case Type_Slice:  et = bt->Slice.elem;  break;
		}

		String proc_name = {};
		if (proc->entity) {
			proc_name = proc->entity->token.string;
		}
		TokenPos pos = ast_node_token(expr).pos;

		switch (bt->kind) {
		default: GB_PANIC("Unknown CompoundLit type: %s", type_to_string(type)); break;

		case Type_Struct: {

			// TODO(bill): "constant" '#raw_union's are not initialized constantly at the moment.
			// NOTE(bill): This is due to the layout of the unions when printed to LLVM-IR
			bool is_raw_union = is_type_raw_union(bt);
			GB_ASSERT(is_type_struct(bt) || is_raw_union);
			TypeStruct *st = &bt->Struct;
			if (cl->elems.count > 0) {
				ir_emit_store(proc, v, ir_add_module_constant(proc->module, type, exact_value_compound(expr)));
				for_array(field_index, cl->elems) {
					AstNode *elem = cl->elems[field_index];

					irValue *field_expr = nullptr;
					Entity *field = nullptr;
					isize index = field_index;

					if (elem->kind == AstNode_FieldValue) {
						ast_node(fv, FieldValue, elem);
						String name = fv->field->Ident.token.string;
						Selection sel = lookup_field(bt, name, false);
						index = sel.index[0];
						elem = fv->value;
					} else {
						TypeAndValue tav = type_and_value_of_expr(proc->module->info, elem);
						Selection sel = lookup_field_from_index(bt, st->fields[field_index]->Variable.field_src_index);
						index = sel.index[0];
					}

					field = st->fields[index];
					Type *ft = field->type;
					if (!is_raw_union && ir_is_elem_const(proc->module, elem, ft)) {
						continue;
					}

					field_expr = ir_build_expr(proc, elem);

					GB_ASSERT(ir_type(field_expr)->kind != Type_Tuple);

					irValue *fv = ir_emit_conv(proc, field_expr, ft);
					irValue *gep = ir_emit_struct_ep(proc, v, cast(i32)index);
					ir_emit_store(proc, gep, fv);
				}
			}
			break;
		}

		case Type_Map: {
			if (cl->elems.count == 0) {
				break;
			}
			gbAllocator a = proc->module->allocator;
			{
				auto args = array_make<irValue *>(a, 3);
				args[0] = ir_gen_map_header(proc, v, type);
				args[1] = ir_const_int(a, 2*cl->elems.count);
				args[2] = ir_emit_source_code_location(proc, proc_name, pos);
				ir_emit_global_call(proc, "__dynamic_map_reserve", args);
			}
			for_array(field_index, cl->elems) {
				AstNode *elem = cl->elems[field_index];
				ast_node(fv, FieldValue, elem);

				irValue *key   = ir_build_expr(proc, fv->field);
				irValue *value = ir_build_expr(proc, fv->value);
				ir_insert_dynamic_map_key_and_value(proc, v, type, key, value);
			}
			break;
		}

		case Type_DynamicArray: {
			if (cl->elems.count == 0) {
				break;
			}
			Type *elem = bt->DynamicArray.elem;
			gbAllocator a = proc->module->allocator;
			irValue *size  = ir_const_int(a, type_size_of(elem));
			irValue *align = ir_const_int(a, type_align_of(elem));
			{
				auto args = array_make<irValue *>(a, 5);
				args[0] = ir_emit_conv(proc, v, t_rawptr);
				args[1] = size;
				args[2] = align;
				args[3] = ir_const_int(a, 2*cl->elems.count);
				args[4] = ir_emit_source_code_location(proc, proc_name, pos);
				ir_emit_global_call(proc, "__dynamic_array_reserve", args);
			}

			i64 item_count = cl->elems.count;
			irValue *items = ir_generate_array(proc->module, elem, item_count, str_lit("__dacl$"), cast(i64)cast(intptr)expr);

			for_array(field_index, cl->elems) {
				AstNode *f = cl->elems[field_index];
				irValue *value = ir_emit_conv(proc, ir_build_expr(proc, f), elem);
				irValue *ep = ir_emit_array_epi(proc, items, cast(i32)field_index);
				ir_emit_store(proc, ep, value);
			}

			{
				auto args = array_make<irValue *>(a, 6);
				args[0] = ir_emit_conv(proc, v, t_rawptr);
				args[1] = size;
				args[2] = align;
				args[3] = ir_emit_conv(proc, items, t_rawptr);
				args[4] = ir_const_int(a, item_count);
				args[5] = ir_emit_source_code_location(proc, proc_name, pos);
				ir_emit_global_call(proc, "__dynamic_array_append", args);
			}
			break;
		}

		case Type_Array: {
			if (cl->elems.count > 0) {
				ir_emit_store(proc, v, ir_add_module_constant(proc->module, type, exact_value_compound(expr)));
				for_array(i, cl->elems) {
					AstNode *elem = cl->elems[i];
					if (ir_is_elem_const(proc->module, elem, et)) {
						continue;
					}
					irValue *field_expr = ir_build_expr(proc, elem);
					Type *t = ir_type(field_expr);
					GB_ASSERT(t->kind != Type_Tuple);
					irValue *ev = ir_emit_conv(proc, field_expr, et);
					irValue *gep = ir_emit_array_epi(proc, v, cast(i32)i);
					ir_emit_store(proc, gep, ev);
				}
			}
			break;
		}
		case Type_Slice: {
			if (cl->elems.count > 0) {
				Type *elem_type = bt->Slice.elem;
				Type *elem_ptr_type = alloc_type_pointer(elem_type);
				Type *elem_ptr_ptr_type = alloc_type_pointer(elem_ptr_type);
				irValue *slice = ir_add_module_constant(proc->module, type, exact_value_compound(expr));
				GB_ASSERT(slice->kind == irValue_ConstantSlice);

				irValue *data = ir_emit_array_ep(proc, slice->ConstantSlice.backing_array, v_zero32);

				for_array(i, cl->elems) {
					AstNode *elem = cl->elems[i];
					if (ir_is_elem_const(proc->module, elem, et)) {
						continue;
					}

					irValue *field_expr = ir_build_expr(proc, elem);
					Type *t = ir_type(field_expr);
					GB_ASSERT(t->kind != Type_Tuple);
					irValue *ev = ir_emit_conv(proc, field_expr, elem_type);
					irValue *offset = ir_emit_ptr_offset(proc, data, ir_const_int(proc->module->allocator, i));
					ir_emit_store(proc, offset, ev);
				}

				irValue *count = ir_const_int(proc->module->allocator, slice->ConstantSlice.count);
				ir_fill_slice(proc, v, data, count);
			}
			break;
		}

		case Type_Basic: {
			GB_ASSERT(is_type_any(bt));
			if (cl->elems.count > 0) {
				ir_emit_store(proc, v, ir_add_module_constant(proc->module, type, exact_value_compound(expr)));
				String field_names[2] = {
					str_lit("data"),
					str_lit("type_info"),
				};
				Type *field_types[2] = {
					t_rawptr,
					t_type_info_ptr,
				};

				for_array(field_index, cl->elems) {
					AstNode *elem = cl->elems[field_index];

					irValue *field_expr = nullptr;
					isize index = field_index;

					if (elem->kind == AstNode_FieldValue) {
						ast_node(fv, FieldValue, elem);
						Selection sel = lookup_field(bt, fv->field->Ident.token.string, false);
						index = sel.index[0];
						elem = fv->value;
					} else {
						TypeAndValue tav = type_and_value_of_expr(proc->module->info, elem);
						Selection sel = lookup_field(bt, field_names[field_index], false);
						index = sel.index[0];
					}

					field_expr = ir_build_expr(proc, elem);

					GB_ASSERT(ir_type(field_expr)->kind != Type_Tuple);

					Type *ft = field_types[index];
					irValue *fv = ir_emit_conv(proc, field_expr, ft);
					irValue *gep = ir_emit_struct_ep(proc, v, cast(i32)index);
					ir_emit_store(proc, gep, fv);
				}
			}
		}
		}

		return ir_addr(v);
	case_end;

	case_ast_node(tc, TypeCast, expr);
		Type *type = type_of_expr(proc->module->info, expr);
		irValue *x = ir_build_expr(proc, tc->expr);
		irValue *e = nullptr;
		switch (tc->token.kind) {
		case Token_cast:
			e = ir_emit_conv(proc, x, type);
			break;
		case Token_transmute:
			e = ir_emit_transmute(proc, x, type);
			break;
		default:
			GB_PANIC("Invalid AST TypeCast");
		}
		irValue *v = ir_add_local_generated(proc, type);
		ir_emit_store(proc, v, e);
		return ir_addr(v);
	case_end;

	case_ast_node(ac, AutoCast, expr);
		return ir_build_addr(proc, ac->expr);
	case_end;
	}

	TokenPos token_pos = ast_node_token(expr).pos;
	GB_PANIC("Unexpected address expression\n"
	         "\tAstNode: %.*s @ "
	         "%.*s(%td:%td)\n",
	         LIT(ast_node_strings[expr->kind]),
	         LIT(token_pos.file), token_pos.line, token_pos.column);


	return ir_addr(nullptr);
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
			irBlock *block = ir_new_block(proc, nullptr, "cmp.and");
			ir_build_cond(proc, be->left, block, false_block);
			ir_start_block(proc, block);
			return ir_build_cond(proc, be->right, true_block, false_block);
		} else if (be->op.kind == Token_CmpOr) {
			irBlock *block = ir_new_block(proc, nullptr, "cmp.or");
			ir_build_cond(proc, be->left, true_block, block);
			ir_start_block(proc, block);
			return ir_build_cond(proc, be->right, true_block, false_block);
		}
	case_end;
	}

	irValue *v = ir_build_expr(proc, cond);
	v = ir_emit_conv(proc, v, t_bool);
	ir_emit_if(proc, v, true_block, false_block);
	return v;
}

void ir_build_poly_proc(irProcedure *proc, AstNodeProcLit *pd, Entity *e) {
	GB_ASSERT(pd->body != nullptr);

	if (ir_min_dep_entity(proc->module, e) == false) {
		// NOTE(bill): Nothing depends upon it so doesn't need to be built
		return;
	}

	// NOTE(bill): Generate a new name
	// parent.name-guid
	String original_name = e->token.string;
	String pd_name = original_name;
	if (e->Procedure.link_name.len > 0) {
		pd_name = e->Procedure.link_name;
	}

	isize name_len = proc->name.len + 1 + pd_name.len + 1 + 10 + 1;
	u8 *name_text = gb_alloc_array(proc->module->allocator, u8, name_len);
	i32 guid = cast(i32)proc->children.count;
	name_len = gb_snprintf(cast(char *)name_text, name_len, "%.*s.%.*s-%d", LIT(proc->name), LIT(pd_name), guid);
	String name = make_string(name_text, name_len-1);


	irValue *value = ir_value_procedure(proc->module->allocator,
	                                    proc->module, e, e->type, pd->type, pd->body, name);

	value->Proc.tags = pd->tags;
	value->Proc.inlining = pd->inlining;
	value->Proc.parent = proc;

	ir_module_add_value(proc->module, e, value);
	array_add(&proc->children, &value->Proc);
	array_add(&proc->module->procs_to_generate, value);
}


void ir_build_constant_value_decl(irProcedure *proc, AstNodeValueDecl *vd) {
	if (vd == nullptr || vd->is_mutable) {
		return;
	}

	for_array(i, vd->names) {
		AstNode *ident = vd->names[i];
		GB_ASSERT(ident->kind == AstNode_Ident);
		Entity *e = entity_of_ident(proc->module->info, ident);
		GB_ASSERT(e != nullptr);
		switch (e->kind) {
		case Entity_TypeName:
		case Entity_Procedure:
			break;
		default:
			continue;
		}

		if (e->kind == Entity_TypeName) {
			bool polymorphic_struct = false;
			if (e->type != nullptr && e->kind == Entity_TypeName) {
				Type *bt = base_type(e->type);
				if (bt->kind == Type_Struct) {
					polymorphic_struct = bt->Struct.is_polymorphic;
				}
			}

			if (!polymorphic_struct && !ir_min_dep_entity(proc->module, e)) {
				continue;
			}

			// NOTE(bill): Generate a new name
			// parent_proc.name-guid
			String ts_name = e->token.string;

			irModule *m = proc->module;
			isize name_len = proc->name.len + 1 + ts_name.len + 1 + 10 + 1;
			u8 *name_text = gb_alloc_array(m->allocator, u8, name_len);
			i32 guid = cast(i32)m->members.entries.count;
			name_len = gb_snprintf(cast(char *)name_text, name_len, "%.*s.%.*s-%d", LIT(proc->name), LIT(ts_name), guid);
			String name = make_string(name_text, name_len-1);

			irValue *value = ir_value_type_name(m->allocator, name, e->type);
			ir_add_entity_name(m, e, name);
			ir_gen_global_type_name(m, e, name);
		} else if (e->kind == Entity_Procedure) {
			CheckerInfo *info = proc->module->info;
			DeclInfo *decl = decl_info_of_entity(info, e);
			ast_node(pl, ProcLit, decl->proc_lit);
			if (pl->body != nullptr) {
				auto *found = map_get(&info->gen_procs, hash_pointer(ident));
				if (found) {
					auto procs = *found;
					for_array(i, procs) {
						Entity *e = procs[i];
						if (!ir_min_dep_entity(proc->module, e)) {
							continue;
						}
						DeclInfo *d = decl_info_of_entity(info, e);
						ir_build_poly_proc(proc, &d->proc_lit->ProcLit, e);
					}
				} else {
					ir_build_poly_proc(proc, pl, e);
				}
			} else {

				// FFI - Foreign function interace
				String original_name = e->token.string;
				String name = original_name;

				if (e->Procedure.is_foreign) {
					ir_add_foreign_library_path(proc->module, e->Procedure.foreign_library);
				}

				if (e->Procedure.link_name.len > 0) {
					name = e->Procedure.link_name;
				}

				irValue *value = ir_value_procedure(proc->module->allocator,
				                                    proc->module, e, e->type, pl->type, pl->body, name);

				value->Proc.tags = pl->tags;
				value->Proc.inlining = pl->inlining;

				ir_module_add_value(proc->module, e, value);
				ir_build_proc(value, proc);

				if (value->Proc.is_foreign || value->Proc.is_export) {
					HashKey key = hash_string(name);
					irValue **prev_value = map_get(&proc->module->members, key);
					if (prev_value == nullptr) {
						// NOTE(bill): Don't do mutliple declarations in the IR
						map_set(&proc->module->members, key, value);
					}
				} else {
					array_add(&proc->children, &value->Proc);
				}
			}
		}
	}
}

void ir_build_stmt_list(irProcedure *proc, Array<AstNode *> stmts) {
	// NOTE(bill): Precollect constant entities
	for_array(i, stmts) {
		AstNode *stmt = stmts[i];
		switch (stmt->kind) {
		case_ast_node(vd, ValueDecl, stmt);
			ir_build_constant_value_decl(proc, vd);
		case_end;
		case_ast_node(fb, ForeignBlockDecl, stmt);
			ir_build_stmt_list(proc, fb->decls);
		case_end;
		}
	}
	for_array(i, stmts) {
		ir_build_stmt(proc, stmts[i]);
	}
}

void ir_build_stmt_internal(irProcedure *proc, AstNode *node);
void ir_build_stmt(irProcedure *proc, AstNode *node) {
	u64 prev_stmt_state_flags = proc->module->stmt_state_flags;

	if (node->stmt_state_flags != 0) {
		u64 in = node->stmt_state_flags;
		u64 out = proc->module->stmt_state_flags;

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
			GB_PANIC("Invalid 'else' statement in 'when' statement");
			break;
		}
	}
}



void ir_build_range_indexed(irProcedure *proc, irValue *expr, Type *val_type, irValue *count_ptr,
                            irValue **val_, irValue **idx_, irBlock **loop_, irBlock **done_) {
	irValue *count = nullptr;
	Type *expr_type = base_type(type_deref(ir_type(expr)));
	switch (expr_type->kind) {
	case Type_Array:
		count = ir_const_int(proc->module->allocator, expr_type->Array.count);
		break;
	}

	irValue *val = nullptr;
	irValue *idx = nullptr;
	irBlock *loop = nullptr;
	irBlock *done = nullptr;
	irBlock *body = nullptr;


	irValue *index = ir_add_local_generated(proc, t_int);
	ir_emit_store(proc, index, ir_const_int(proc->module->allocator, -1));

	loop = ir_new_block(proc, nullptr, "for.index.loop");
	ir_emit_jump(proc, loop);
	ir_start_block(proc, loop);

	irValue *incr = ir_emit_arith(proc, Token_Add, ir_emit_load(proc, index), v_one, t_int);
	ir_emit_store(proc, index, incr);

	body = ir_new_block(proc, nullptr, "for.index.body");
	done = ir_new_block(proc, nullptr, "for.index.done");
	if (count == nullptr) {
		GB_ASSERT(count_ptr != nullptr);
		count = ir_emit_load(proc, count_ptr);
	}
	irValue *cond = ir_emit_comp(proc, Token_Lt, incr, count);
	ir_emit_if(proc, cond, body, done);
	ir_start_block(proc, body);

	idx = ir_emit_load(proc, index);
	switch (expr_type->kind) {
	case Type_Array: {
		if (val_type != nullptr) {
			val = ir_emit_load(proc, ir_emit_array_ep(proc, expr, idx));
		}
		break;
	}
	case Type_Slice: {
		if (val_type != nullptr) {
			irValue *elem = ir_slice_elem(proc, expr);
			val = ir_emit_load(proc, ir_emit_ptr_offset(proc, elem, idx));
		}
		break;
	}
	case Type_DynamicArray: {
		if (val_type != nullptr) {
			irValue *elem = ir_emit_struct_ep(proc, expr, 0);
			elem = ir_emit_load(proc, elem);
			val = ir_emit_load(proc, ir_emit_ptr_offset(proc, elem, idx));
		}
		break;
	}
	case Type_Map: {
		irValue *key = ir_add_local_generated(proc, expr_type->Map.key);

		irValue *entries = ir_map_entries_ptr(proc, expr);
		irValue *elem = ir_emit_struct_ep(proc, entries, 0);
		elem = ir_emit_load(proc, elem);

		irValue *entry = ir_emit_ptr_offset(proc, elem, idx);
		val = ir_emit_load(proc, ir_emit_struct_ep(proc, entry, 2));

		irValue *hash = ir_emit_struct_ep(proc, entry, 0);
		if (is_type_string(expr_type->Map.key)) {
			irValue *str = ir_emit_struct_ep(proc, hash, 1);
			ir_emit_store(proc, key, ir_emit_load(proc, str));
		} else {
			irValue *hash_ptr = ir_emit_struct_ep(proc, hash, 0);
			hash_ptr = ir_emit_conv(proc, hash_ptr, ir_type(key));
			ir_emit_store(proc, key, ir_emit_load(proc, hash_ptr));
		}

		idx = ir_emit_load(proc, key);

		break;
	}
	default:
		GB_PANIC("Cannot do range_indexed of %s", type_to_string(expr_type));
		break;
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

	irValue *val = nullptr;
	irValue *idx = nullptr;
	irBlock *loop = nullptr;
	irBlock *done = nullptr;
	irBlock *body = nullptr;


	irValue *offset_ = ir_add_local_generated(proc, t_int);
	ir_emit_store(proc, offset_, v_zero);

	loop = ir_new_block(proc, nullptr, "for.string.loop");
	ir_emit_jump(proc, loop);
	ir_start_block(proc, loop);



	body = ir_new_block(proc, nullptr, "for.string.body");
	done = ir_new_block(proc, nullptr, "for.string.done");

	irValue *offset = ir_emit_load(proc, offset_);
	irValue *cond = ir_emit_comp(proc, Token_Lt, offset, count);
	ir_emit_if(proc, cond, body, done);
	ir_start_block(proc, body);


	irValue *str_elem = ir_emit_ptr_offset(proc, ir_string_elem(proc, expr), offset);
	irValue *str_len  = ir_emit_arith(proc, Token_Sub, count, offset, t_int);
	auto args = array_make<irValue *>(proc->module->allocator, 1);
	args[0] = ir_emit_string(proc, str_elem, str_len);
	irValue *rune_and_len = ir_emit_global_call(proc, "__string_decode_rune", args);
	irValue *len  = ir_emit_struct_ev(proc, rune_and_len, 1);
	ir_emit_store(proc, offset_, ir_emit_arith(proc, Token_Add, offset, len, t_int));


	idx = offset;
	if (val_type != nullptr) {
		val = ir_emit_struct_ev(proc, rune_and_len, 0);
	}

	if (val_)  *val_  = val;
	if (idx_)  *idx_  = idx;
	if (loop_) *loop_ = loop;
	if (done_) *done_ = done;
}

void ir_build_range_interval(irProcedure *proc, AstNodeBinaryExpr *node, Type *val_type,
                              irValue **val_, irValue **idx_, irBlock **loop_, irBlock **done_) {
	// TODO(bill): How should the behaviour work for lower and upper bounds checking for iteration?
	// If 'lower' is changed, should 'val' do so or is that not typical behaviour?

	irValue *lower = ir_build_expr(proc, node->left);
	irValue *upper = nullptr;

	irValue *val = nullptr;
	irValue *idx = nullptr;
	irBlock *loop = nullptr;
	irBlock *done = nullptr;
	irBlock *body = nullptr;

	if (val_type == nullptr) {
		val_type = ir_type(lower);
	}
	irValue *value = ir_add_local_generated(proc, val_type);
	ir_emit_store(proc, value, lower);

	irValue *index = ir_add_local_generated(proc, t_int);
	ir_emit_store(proc, index, ir_const_int(proc->module->allocator, 0));

	loop = ir_new_block(proc, nullptr, "for.interval.loop");
	ir_emit_jump(proc, loop);
	ir_start_block(proc, loop);

	body = ir_new_block(proc, nullptr, "for.interval.body");
	done = ir_new_block(proc, nullptr, "for.interval.done");


	TokenKind op = Token_Lt;
	switch (node->op.kind) {
	case Token_Ellipsis:   op = Token_LtEq; break;
	case Token_HalfClosed: op = Token_Lt;   break;
	default: GB_PANIC("Invalid interval operator"); break;
	}

	upper = ir_build_expr(proc, node->right);

	irValue *cond = ir_emit_comp(proc, op, ir_emit_load(proc, value), upper);
	ir_emit_if(proc, cond, body, done);
	ir_start_block(proc, body);

	if (value != nullptr) {
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

void ir_store_type_case_implicit(irProcedure *proc, AstNode *clause, irValue *value) {
	Entity *e = implicit_entity_of_node(proc->module->info, clause);
	GB_ASSERT(e != nullptr);
	irValue *x = ir_add_local(proc, e, nullptr, false);
	ir_emit_store(proc, x, value);
}

void ir_type_case_body(irProcedure *proc, AstNode *label, AstNode *clause, irBlock *body, irBlock *done) {
	ast_node(cc, CaseClause, clause);

	ir_push_target_list(proc, label, done, nullptr, nullptr);
	ir_open_scope(proc);
	ir_build_stmt_list(proc, cc->stmts);
	ir_close_scope(proc, irDeferExit_Default, body);
	ir_pop_target_list(proc);

	ir_emit_jump(proc, done);
}

void ir_build_stmt_internal(irProcedure *proc, AstNode *node) {
	switch (node->kind) {
	case_ast_node(bs, EmptyStmt, node);
	case_end;

	// case_ast_node(fb, ForeignBlockDecl, node);
	// 	ir_build_stmt_list(proc, fb->decls);
	// case_end;

	case_ast_node(us, UsingStmt, node);
		for_array(i, us->list) {
			AstNode *decl = unparen_expr(us->list[i]);
			// if (decl->kind == AstNode_GenDecl) {
				// ir_build_stmt(proc, decl);
			// }
		}
	case_end;

	case_ast_node(ws, WhenStmt, node);
		ir_build_when_stmt(proc, ws);
	case_end;

	#if 0
	case_ast_node(s, IncDecStmt, node);
		TokenKind op = Token_Add;
		if (s->op.kind == Token_Dec) {
			op = Token_Sub;
		}
		irAddr addr = ir_build_addr(proc, s->expr);
		ir_build_assign_op(proc, addr, v_one, op);
	case_end;
	#endif

	case_ast_node(vd, ValueDecl, node);
		if (vd->is_mutable) {
			irModule *m = proc->module;
			gbTempArenaMemory tmp = gb_temp_arena_memory_begin(&m->tmp_arena);
			defer (gb_temp_arena_memory_end(tmp));

			if (vd->values.count == 0) { // declared and zero-initialized
				for_array(i, vd->names) {
					AstNode *name = vd->names[i];
					if (!is_blank_ident(name)) {
						ir_add_local_for_identifier(proc, name, true);
					}
				}
			} else { // Tuple(s)
				auto lvals = array_make<irAddr>(m->tmp_allocator, 0, vd->names.count);
				auto inits = array_make<irValue *>(m->tmp_allocator, 0, vd->names.count);

				for_array(i, vd->names) {
					AstNode *name = vd->names[i];
					irAddr lval = ir_addr(nullptr);
					if (!is_blank_ident(name)) {
						ir_add_local_for_identifier(proc, name, false);
						lval = ir_build_addr(proc, name);
					}
					array_add(&lvals, lval);

					ir_check_type_and_gen_for_proc_lit(proc, ir_addr_type(lval));
				}

				for_array(i, vd->values) {
					irValue *init = ir_build_expr(proc, vd->values[i]);
					Type *t = ir_type(init);
					if (t->kind == Type_Tuple) {
						for_array(i, t->Tuple.variables) {
							Entity *e = t->Tuple.variables[i];
							irValue *v = ir_emit_struct_ev(proc, init, cast(i32)i);
							array_add(&inits, v);
						}
					} else {
						array_add(&inits, init);
					}
				}


				for_array(i, inits) {
					ir_addr_store(proc, lvals[i], inits[i]);
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
			auto lvals = array_make<irAddr>(m->tmp_allocator);

			for_array(i, as->lhs) {
				AstNode *lhs = as->lhs[i];
				irAddr lval = {};
				if (!is_blank_ident(lhs)) {
					lval = ir_build_addr(proc, lhs);
				}
				array_add(&lvals, lval);
			}

			if (as->lhs.count == as->rhs.count) {
				if (as->lhs.count == 1) {
					AstNode *rhs = as->rhs[0];
					irValue *init = ir_build_expr(proc, rhs);
					ir_addr_store(proc, lvals[0], init);
				} else {
					auto inits = array_make<irValue *>(m->tmp_allocator, 0, lvals.count);

					for_array(i, as->rhs) {
						irValue *init = ir_build_expr(proc, as->rhs[i]);
						array_add(&inits, init);
					}

					for_array(i, inits) {
						ir_addr_store(proc, lvals[i], inits[i]);
					}
				}
			} else {
				auto inits = array_make<irValue *>(m->tmp_allocator, 0, lvals.count);

				for_array(i, as->rhs) {
					irValue *init = ir_build_expr(proc, as->rhs[i]);
					Type *t = ir_type(init);
					// TODO(bill): refactor for code reuse as this is repeated a bit
					if (t->kind == Type_Tuple) {
						for_array(i, t->Tuple.variables) {
							Entity *e = t->Tuple.variables[i];
							irValue *v = ir_emit_struct_ev(proc, init, cast(i32)i);
							array_add(&inits, v);
						}
					} else {
						array_add(&inits, init);
					}
				}

				for_array(i, inits) {
					ir_addr_store(proc, lvals[i], inits[i]);
				}
			}

			break;
		}

		default: {
			// NOTE(bill): Only 1 += 1 is allowed, no tuples
			// +=, -=, etc
			i32 op = cast(i32)as->op.kind;
			op += Token_Add - Token_AddEq; // Convert += to +
			irAddr lhs = ir_build_addr(proc, as->lhs[0]);
			irValue *value = ir_build_expr(proc, as->rhs[0]);
			ir_build_assign_op(proc, lhs, value, cast(TokenKind)op);
			break;
		}
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
		ir_close_scope(proc, irDeferExit_Default, nullptr);
	case_end;

	case_ast_node(ds, DeferStmt, node);
		ir_emit_comment(proc, str_lit("DeferStmt"));
		isize scope_index = proc->scope_index;
		// TODO(bill): What was the original rationale behind this line?
		// if (ds->stmt->kind == AstNode_BlockStmt) scope_index--;
		ir_add_defer_node(proc, scope_index, ds->stmt);
	case_end;

	case_ast_node(rs, ReturnStmt, node);
		ir_emit_comment(proc, str_lit("ReturnStmt"));
		irValue *v = nullptr;
		TypeTuple *tuple  = &proc->type->Proc.results->Tuple;
		isize return_count = proc->type->Proc.result_count;
		isize res_count = rs->results.count;

		if (return_count == 0) {
			// No return values
		} else if (return_count == 1) {
			Entity *e = tuple->variables[0];
			if (res_count == 0) {
				irValue **found = map_get(&proc->module->values, hash_entity(e));
				GB_ASSERT(found);
				v = ir_emit_load(proc, *found);
			} else {
				v = ir_build_expr(proc, rs->results[0]);
				v = ir_emit_conv(proc, v, e->type);
			}
		} else {
			gbTempArenaMemory tmp = gb_temp_arena_memory_begin(&proc->module->tmp_arena);
			defer (gb_temp_arena_memory_end(tmp));

			auto results = array_make<irValue *>(proc->module->tmp_allocator, 0, return_count);

			if (res_count != 0) {
				for (isize res_index = 0; res_index < res_count; res_index++) {
					irValue *res = ir_build_expr(proc, rs->results[res_index]);
					Type *t = ir_type(res);
					if (t->kind == Type_Tuple) {
						for_array(i, t->Tuple.variables) {
							Entity *e = t->Tuple.variables[i];
							irValue *v = ir_emit_struct_ev(proc, res, cast(i32)i);
							array_add(&results, v);
						}
					} else {
						array_add(&results, res);
					}
				}
			} else {
				for (isize res_index = 0; res_index < return_count; res_index++) {
					Entity *e = tuple->variables[res_index];
					irValue **found = map_get(&proc->module->values, hash_entity(e));
					GB_ASSERT(found);
					irValue *res = ir_emit_load(proc, *found);
					array_add(&results, res);
				}
			}

			GB_ASSERT(results.count == return_count);

			Type *ret_type = proc->type->Proc.results;
			v = ir_add_local_generated(proc, ret_type);
			for_array(i, results) {
				Entity *e = tuple->variables[i];
				irValue *res = ir_emit_conv(proc, results[i], e->type);
				irValue *field = ir_emit_struct_ep(proc, v, cast(i32)i);
				ir_emit_store(proc, field, res);
			}

			v = ir_emit_load(proc, v);
		}

		ir_emit_return(proc, v);

	case_end;

	case_ast_node(is, IfStmt, node);
		ir_emit_comment(proc, str_lit("IfStmt"));
		if (is->init != nullptr) {
			irBlock *init = ir_new_block(proc, node, "if.init");
			ir_emit_jump(proc, init);
			ir_start_block(proc, init);
			ir_build_stmt(proc, is->init);
		}
		irBlock *then = ir_new_block(proc, node, "if.then");
		irBlock *done = ir_new_block(proc, node, "if.done");
		irBlock *else_ = done;
		if (is->else_stmt != nullptr) {
			else_ = ir_new_block(proc, is->else_stmt, "if.else");
		}

		ir_build_cond(proc, is->cond, then, else_);
		ir_start_block(proc, then);

		ir_open_scope(proc);
		ir_build_stmt(proc, is->body);
		ir_close_scope(proc, irDeferExit_Default, nullptr);

		ir_emit_jump(proc, done);

		if (is->else_stmt != nullptr) {
			ir_start_block(proc, else_);

			ir_open_scope(proc);
			ir_build_stmt(proc, is->else_stmt);
			ir_close_scope(proc, irDeferExit_Default, nullptr);

			ir_emit_jump(proc, done);
		}

		ir_start_block(proc, done);
	case_end;

	case_ast_node(fs, ForStmt, node);
		ir_emit_comment(proc, str_lit("ForStmt"));

		if (fs->init != nullptr) {
			irBlock *init = ir_new_block(proc, node, "for.init");
			ir_emit_jump(proc, init);
			ir_start_block(proc, init);
			ir_build_stmt(proc, fs->init);
		}
		irBlock *body = ir_new_block(proc, node, "for.body");
		irBlock *done = ir_new_block(proc, node, "for.done"); // NOTE(bill): Append later
		irBlock *loop = body;
		if (fs->cond != nullptr) {
			loop = ir_new_block(proc, node, "for.loop");
		}
		irBlock *post = loop;
		if (fs->post != nullptr) {
			post = ir_new_block(proc, node, "for.post");
		}


		ir_emit_jump(proc, loop);
		ir_start_block(proc, loop);

		if (loop != body) {
			ir_build_cond(proc, fs->cond, body, done);
			ir_start_block(proc, body);
		}

		ir_push_target_list(proc, fs->label, done, post, nullptr);

		ir_open_scope(proc);
		ir_build_stmt(proc, fs->body);
		ir_close_scope(proc, irDeferExit_Default, nullptr);

		ir_pop_target_list(proc);

		ir_emit_jump(proc, post);

		if (fs->post != nullptr) {
			ir_start_block(proc, post);
			ir_build_stmt(proc, fs->post);
			ir_emit_jump(proc, loop);
		}

		ir_start_block(proc, done);
	case_end;


	case_ast_node(rs, RangeStmt, node);
		ir_emit_comment(proc, str_lit("RangeStmt"));

		Type *val0_type = nullptr;
		Type *val1_type = nullptr;
		if (rs->val0 != nullptr && !is_blank_ident(rs->val0)) {
			val0_type = type_of_expr(proc->module->info, rs->val0);
		}
		if (rs->val1 != nullptr && !is_blank_ident(rs->val1)) {
			val1_type = type_of_expr(proc->module->info, rs->val1);
		}

		if (val0_type != nullptr) {
			ir_add_local_for_identifier(proc, rs->val0, true);
		}
		if (val1_type != nullptr) {
			ir_add_local_for_identifier(proc, rs->val1, true);
		}

		irValue *val = nullptr;
		irValue *key = nullptr;
		irBlock *loop = nullptr;
		irBlock *done = nullptr;
		AstNode *expr = unparen_expr(rs->expr);
		bool is_map = false;

		TypeAndValue tav = type_and_value_of_expr(proc->module->info, expr);

		if (is_ast_node_a_range(expr)) {
			ir_build_range_interval(proc, &expr->BinaryExpr, val0_type, &val, &key, &loop, &done);
		} else if (tav.mode == Addressing_Type) {
			TokenPos pos = ast_node_token(expr).pos;
			gbAllocator a = proc->module->allocator;
			Type *t = tav.type;
			GB_ASSERT(is_type_enum(t));
			Type *enum_ptr = alloc_type_pointer(t);
			t = base_type(t);
			Type *core_elem = core_type(t);
			i64 enum_count = t->Enum.fields.count;
			irValue *max_count = ir_const_int(a, enum_count);

			irValue *ti          = ir_type_info(proc, t);
			irValue *variant     = ir_emit_struct_ep(proc, ti, 2);
			irValue *eti_ptr     = ir_emit_conv(proc, variant, t_type_info_enum_ptr);
			irValue *values      = ir_emit_load(proc, ir_emit_struct_ep(proc, eti_ptr, 2));
			irValue *values_data = ir_slice_elem(proc, values);

			irValue *offset_ = ir_add_local_generated(proc, t_int);
			ir_emit_store(proc, offset_, v_zero);

			loop = ir_new_block(proc, nullptr, "for.enum.loop");
			ir_emit_jump(proc, loop);
			ir_start_block(proc, loop);

			irBlock *body = ir_new_block(proc, nullptr, "for.enum.body");
			done = ir_new_block(proc, nullptr, "for.enum.done");

			irValue *offset = ir_emit_load(proc, offset_);
			irValue *cond = ir_emit_comp(proc, Token_Lt, offset, max_count);
			ir_emit_if(proc, cond, body, done);
			ir_start_block(proc, body);

			irValue *val_ptr = ir_emit_ptr_offset(proc, values_data, offset);
			ir_emit_increment(proc, offset_);

			key = offset;
			if (val0_type != nullptr) {
				if (is_type_float(core_elem)) {
					irValue *f = ir_emit_load(proc, ir_emit_conv(proc, val_ptr, t_f64_ptr));
					val = ir_emit_conv(proc, f, t);
				} else if (is_type_integer(core_elem)) {
					irValue *i = ir_emit_load(proc, ir_emit_conv(proc, val_ptr, t_i64_ptr));
					val = ir_emit_conv(proc, i, t);
				} else {
					GB_PANIC("TODO(bill): enum core type %s", type_to_string(core_elem));
				}
			}
		} else {
			Type *expr_type = type_of_expr(proc->module->info, rs->expr);
			Type *et = base_type(type_deref(expr_type));
			switch (et->kind) {
			case Type_Map: {
				is_map = true;
				gbAllocator a = proc->module->allocator;
				irAddr addr = ir_build_addr(proc, rs->expr);
				irValue *map = ir_addr_get_ptr(proc, addr);
				if (is_type_pointer(type_deref(ir_addr_type(addr)))) {
					map = ir_addr_load(proc, addr);
				}
				irValue *entries_ptr = ir_map_entries_ptr(proc, map);
				irValue *count_ptr = ir_emit_struct_ep(proc, entries_ptr, 1);
				ir_build_range_indexed(proc, map, val1_type, count_ptr, &val, &key, &loop, &done);
				break;
			}
			case Type_Array: {
				irValue *count_ptr = nullptr;
				irValue *array = ir_build_addr_ptr(proc, rs->expr);
				if (is_type_pointer(type_deref(ir_type(array)))) {
					array = ir_emit_load(proc, array);
				}
				count_ptr = ir_add_local_generated(proc, t_int);
				ir_emit_store(proc, count_ptr, ir_const_int(proc->module->allocator, et->Array.count));
				ir_build_range_indexed(proc, array, val0_type, count_ptr, &val, &key, &loop, &done);
				break;
			}
			case Type_DynamicArray: {
				irValue *count_ptr = nullptr;
				irValue *array = ir_build_addr_ptr(proc, rs->expr);
				if (is_type_pointer(type_deref(ir_type(array)))) {
					array = ir_emit_load(proc, array);
				}
				count_ptr = ir_emit_struct_ep(proc, array, 1);
				ir_build_range_indexed(proc, array, val0_type, count_ptr, &val, &key, &loop, &done);
				break;
			}
			case Type_Slice: {
				irValue *count_ptr = nullptr;
				irValue *slice = ir_build_expr(proc, rs->expr);
				if (is_type_pointer(ir_type(slice))) {
					count_ptr = ir_emit_struct_ep(proc, slice, 1);
					slice = ir_emit_load(proc, slice);
				} else {
					count_ptr = ir_add_local_generated(proc, t_int);
					ir_emit_store(proc, count_ptr, ir_slice_len(proc, slice));
				}
				ir_build_range_indexed(proc, slice, val0_type, count_ptr, &val, &key, &loop, &done);
				break;
			}
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
				ir_build_range_string(proc, string, val0_type, &val, &key, &loop, &done);
				break;
			}
			default:
				GB_PANIC("Cannot range over %s", type_to_string(expr_type));
				break;
			}
		}


		irAddr val0_addr = {};
		irAddr val1_addr = {};
		if (val0_type) val0_addr = ir_build_addr(proc, rs->val0);
		if (val1_type) val1_addr = ir_build_addr(proc, rs->val1);

		if (is_map) {
			if (val0_type) ir_addr_store(proc, val0_addr, key);
			if (val1_type) ir_addr_store(proc, val1_addr, val);
		} else {
			if (val0_type) ir_addr_store(proc, val0_addr, val);
			if (val1_type) ir_addr_store(proc, val1_addr, key);
		}

		ir_push_target_list(proc, rs->label, done, loop, nullptr);

		ir_open_scope(proc);
		ir_build_stmt(proc, rs->body);
		ir_close_scope(proc, irDeferExit_Default, nullptr);

		ir_pop_target_list(proc);
		ir_emit_jump(proc, loop);
		ir_start_block(proc, done);
	case_end;

	case_ast_node(ss, SwitchStmt, node);
		ir_emit_comment(proc, str_lit("SwitchStmt"));
		if (ss->init != nullptr) {
			ir_build_stmt(proc, ss->init);
		}
		irValue *tag = v_true;
		if (ss->tag != nullptr) {
			tag = ir_build_expr(proc, ss->tag);
		}
		irBlock *done = ir_new_block(proc, node, "switch.done"); // NOTE(bill): Append later

		ast_node(body, BlockStmt, ss->body);

		Array<AstNode *> default_stmts = {};
		irBlock *default_fall = nullptr;
		irBlock *default_block = nullptr;

		irBlock *fall = nullptr;
		bool append_fall = false;

		isize case_count = body->stmts.count;
		for_array(i, body->stmts) {
			AstNode *clause = body->stmts[i];
			irBlock *body = fall;

			ast_node(cc, CaseClause, clause);

			if (body == nullptr) {
				if (cc->list.count == 0) {
					body = ir_new_block(proc, clause, "switch.dflt.body");
				} else {
					body = ir_new_block(proc, clause, "switch.case.body");
				}
			}
			if (append_fall && body == fall) {
				append_fall = false;
			}

			fall = done;
			if (i+1 < case_count) {
				append_fall = true;
				fall = ir_new_block(proc, clause, "switch.fall.body");
			}

			if (cc->list.count == 0) {
				// default case
				default_stmts = cc->stmts;
				default_fall  = fall;
				default_block = body;
				continue;
			}

			irBlock *next_cond = nullptr;
			for_array(j, cc->list) {
				AstNode *expr = unparen_expr(cc->list[j]);
				next_cond = ir_new_block(proc, clause, "switch.case.next");
				irValue *cond = v_false;
				if (is_ast_node_a_range(expr)) {
					ast_node(ie, BinaryExpr, expr);
					TokenKind op = Token_Invalid;
					switch (ie->op.kind) {
					case Token_Ellipsis:   op = Token_LtEq; break;
					case Token_HalfClosed: op = Token_Lt;   break;
					default: GB_PANIC("Invalid interval operator"); break;
					}
					irValue *lhs = ir_build_expr(proc, ie->left);
					irValue *rhs = ir_build_expr(proc, ie->right);
					// TODO(bill): do short circuit here
					irValue *cond_lhs = ir_emit_comp(proc, Token_LtEq, lhs, tag);
					irValue *cond_rhs = ir_emit_comp(proc, op, tag, rhs);
					cond = ir_emit_arith(proc, Token_And, cond_lhs, cond_rhs, t_bool);
				} else {
					cond = ir_emit_comp(proc, Token_CmpEq, tag, ir_build_expr(proc, expr));
				}
				ir_emit_if(proc, cond, body, next_cond);
				ir_start_block(proc, next_cond);
			}
			ir_start_block(proc, body);

			ir_push_target_list(proc, ss->label, done, nullptr, fall);
			ir_open_scope(proc);
			ir_build_stmt_list(proc, cc->stmts);
			ir_close_scope(proc, irDeferExit_Default, body);
			ir_pop_target_list(proc);

			ir_emit_jump(proc, done);
			proc->curr_block = next_cond;
			// ir_start_block(proc, next_cond);
		}

		if (default_block != nullptr) {
			ir_emit_jump(proc, default_block);
			ir_start_block(proc, default_block);

			ir_push_target_list(proc, ss->label, done, nullptr, default_fall);
			ir_open_scope(proc);
			ir_build_stmt_list(proc, default_stmts);
			ir_close_scope(proc, irDeferExit_Default, default_block);
			ir_pop_target_list(proc);
		}

		ir_emit_jump(proc, done);
		ir_start_block(proc, done);
	case_end;


	case_ast_node(ss, TypeSwitchStmt, node);
		ir_emit_comment(proc, str_lit("TypeSwitchStmt"));
		gbAllocator allocator = proc->module->allocator;

		ast_node(as, AssignStmt, ss->tag);
		GB_ASSERT(as->lhs.count == 1);
		GB_ASSERT(as->rhs.count == 1);

		irValue *parent = ir_build_expr(proc, as->rhs[0]);
		Type *parent_type = ir_type(parent);
		bool is_parent_ptr = is_type_pointer(ir_type(parent));

		TypeSwitchKind switch_kind = check_valid_type_switch_type(ir_type(parent));
		GB_ASSERT(switch_kind != TypeSwitch_Invalid);

		irValue *parent_value = parent;

		irValue *parent_ptr = parent;
		if (!is_parent_ptr) {
			parent_ptr = ir_address_from_load_or_generate_local(proc, parent_ptr);
		}

		irValue *tag_index = nullptr;
		irValue *union_data = nullptr;
		if (switch_kind == TypeSwitch_Union) {
			ir_emit_comment(proc, str_lit("get union's tag"));
			tag_index = ir_emit_load(proc, ir_emit_union_tag_ptr(proc, parent_ptr));
			union_data = ir_emit_conv(proc, parent_ptr, t_rawptr);
		}

		irBlock *start_block = ir_new_block(proc, node, "typeswitch.case.first");
		ir_emit_jump(proc, start_block);
		ir_start_block(proc, start_block);

		// NOTE(bill): Append this later
		irBlock *done = ir_new_block(proc, node, "typeswitch.done");
		AstNode *default_ = nullptr;

		ast_node(body, BlockStmt, ss->body);

		gb_local_persist i32 weird_count = 0;

		for_array(i, body->stmts) {
			AstNode *clause = body->stmts[i];
			ast_node(cc, CaseClause, clause);
			if (cc->list.count == 0) {
				default_ = clause;
				continue;
			}

			irBlock *body = ir_new_block(proc, clause, "typeswitch.body");
			irBlock *next = nullptr;
			Type *case_type = nullptr;
			for_array(type_index, cc->list) {
				next = ir_new_block(proc, nullptr, "typeswitch.next");
				case_type = type_of_expr(proc->module->info, cc->list[type_index]);
				irValue *cond = nullptr;
				if (switch_kind == TypeSwitch_Union) {
					Type *ut = base_type(type_deref(parent_type));
					irValue *variant_tag = ir_const_union_tag(proc->module->allocator, ut, case_type);
					cond = ir_emit_comp(proc, Token_CmpEq, tag_index, variant_tag);
				} else if (switch_kind == TypeSwitch_Any) {
					irValue *any_ti  = ir_emit_load(proc, ir_emit_struct_ep(proc, parent_ptr, 1));
					irValue *case_ti = ir_type_info(proc, case_type);
					cond = ir_emit_comp(proc, Token_CmpEq, any_ti, case_ti);
				}
				GB_ASSERT(cond != nullptr);

				ir_emit_if(proc, cond, body, next);
				ir_start_block(proc, next);
			}

			Entity *case_entity = implicit_entity_of_node(proc->module->info, clause);

			irValue *value = parent_value;

			ir_start_block(proc, body);

			if (cc->list.count == 1) {
				bool any_or_not_ptr = is_type_any(type_deref(parent_type)) || !is_parent_ptr;

				Type *ct = case_entity->type;
				if (any_or_not_ptr) {
					ct = alloc_type_pointer(ct);
				}
				GB_ASSERT_MSG(is_type_pointer(ct), "%s", type_to_string(ct));
				irValue *data = nullptr;
				if (switch_kind == TypeSwitch_Union) {
					data = union_data;
				} else if (switch_kind == TypeSwitch_Any) {
					irValue *any_data = ir_emit_load(proc, ir_emit_struct_ep(proc, parent_ptr, 0));
					data = any_data;
				}
				value = ir_emit_conv(proc, data, ct);
				if (any_or_not_ptr) {
					value = ir_emit_load(proc, value);
				}
			}

			ir_store_type_case_implicit(proc, clause, value);
			ir_type_case_body(proc, ss->label, clause, body, done);
			ir_start_block(proc, next);
		}

		if (default_ != nullptr) {
			ir_store_type_case_implicit(proc, default_, parent_value);
			ir_type_case_body(proc, ss->label, default_, proc->curr_block, done);
		} else {
			ir_emit_jump(proc, done);
		}
		ir_start_block(proc, done);
	case_end;

	case_ast_node(bs, BranchStmt, node);
		irBlock *block = nullptr;

		if (bs->label != nullptr) {
			irBranchBlocks bb = ir_lookup_branch_blocks(proc, bs->label);
			switch (bs->token.kind) {
			case Token_break:    block = bb.break_;    break;
			case Token_continue: block = bb.continue_; break;
			case Token_fallthrough:
				GB_PANIC("fallthrough cannot have a label");
				break;
			}
		} else {
			for (irTargetList *t = proc->target_list; t != nullptr && block == nullptr; t = t->prev) {
				switch (bs->token.kind) {
				case Token_break:       block = t->break_;       break;
				case Token_continue:    block = t->continue_;    break;
				case Token_fallthrough: block = t->fallthrough_; break;
				}
			}
		}
		if (block != nullptr) {
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


	case_ast_node(pc, PushContext, node);
		ir_emit_comment(proc, str_lit("push_context"));
		irValue *new_context = ir_build_expr(proc, pc->expr);

		ir_open_scope(proc);

		irValue *prev = ir_find_or_generate_context_ptr(proc);
		irValue *next = ir_add_local_generated(proc, t_context);
		ir_emit_store(proc, next, new_context);

		Selection sel = lookup_field(t_context, str_lit("parent"), false);
		GB_ASSERT(sel.entity != nullptr);
		irValue *parent_ptr = ir_emit_deep_field_gep(proc, next, sel);
		ir_emit_store(proc, parent_ptr, prev);

		array_add(&proc->context_stack, next);
		defer (array_pop(&proc->context_stack));

		ir_build_stmt(proc, pc->body);

		ir_close_scope(proc, irDeferExit_Default, nullptr);
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
		irBlock *b = proc->blocks[i];
		b->index = cast(i32)i;
		for_array(j, b->instrs) {
			irValue *value = b->instrs[j];
			GB_ASSERT_MSG(value->kind == irValue_Instr, "%.*s", LIT(proc->name));
			irInstr *instr = &value->Instr;
			if (ir_instr_type(instr) == nullptr) { // NOTE(bill): Ignore non-returning instructions
				value->index = -1;
				continue;
			}
			value->index = reg_index;
			value->index_set = true;
			reg_index++;
		}
	}
}

void ir_begin_procedure_body(irProcedure *proc) {
	gbAllocator a = proc->module->allocator;
	array_add(&proc->module->procs, proc);

	array_init(&proc->blocks,           heap_allocator());
	array_init(&proc->defer_stmts,      heap_allocator());
	array_init(&proc->children,         heap_allocator());
	array_init(&proc->branch_blocks,    heap_allocator());
	array_init(&proc->context_stack,    heap_allocator());

	DeclInfo *decl = decl_info_of_entity(proc->module->info, proc->entity);
	if (decl != nullptr) {
		for_array(i, decl->labels) {
			BlockLabel bl = decl->labels[i];
			irBranchBlocks bb = {bl.label, nullptr, nullptr};
			array_add(&proc->branch_blocks, bb);
		}
	}

	proc->decl_block  = ir_new_block(proc, proc->type_expr, "decls");
	ir_start_block(proc, proc->decl_block);
	proc->entry_block = ir_new_block(proc, proc->type_expr, "entry");
	ir_start_block(proc, proc->entry_block);

	if (proc->type->Proc.return_by_pointer) {
		// NOTE(bill): this must be the first parameter stored
		Type *ptr_type = alloc_type_pointer(reduce_tuple_to_single_type(proc->type->Proc.results));
		Entity *e = alloc_entity_param(nullptr, make_token_ident(str_lit("agg.result")), ptr_type, false, false);
		e->flags |= EntityFlag_Sret | EntityFlag_NoAlias;

		irValue *param = ir_value_param(a, proc, e, ptr_type);
		param->Param.kind = irParamPass_Pointer;

		ir_module_add_value(proc->module, e, param);
		proc->return_ptr = param;
	}

	GB_ASSERT(proc->type != nullptr);

	if (proc->type->Proc.params != nullptr) {
		TypeTuple *params = &proc->type->Proc.params->Tuple;
		if (proc->type_expr != nullptr) {
			ast_node(pt, ProcType, proc->type_expr);
			isize param_index = 0;
			isize q_index = 0;

			for_array(i, params->variables) {
				ast_node(fl, FieldList, pt->params);
				GB_ASSERT(fl->list.count > 0);
				GB_ASSERT(fl->list[0]->kind == AstNode_Field);
				if (q_index == fl->list[param_index]->Field.names.count) {
					q_index = 0;
					param_index++;
				}
				ast_node(field, Field, fl->list[param_index]);
				AstNode *name = field->names[q_index++];

				Entity *e = params->variables[i];
				if (e->kind != Entity_Variable) {
					continue;
				}

				Type *abi_type = proc->type->Proc.abi_compat_params[i];
				if (e->token.string != "" && !is_blank_ident(e->token)) {
					irValue *param = ir_add_param(proc, e, name, abi_type);
					array_add(&proc->params, param);
				}
			}
		} else {
			auto abi_types = proc->type->Proc.abi_compat_params;

			for_array(i, params->variables) {
				Entity *e = params->variables[i];
				if (e->kind != Entity_Variable) {
					continue;
				}
				Type *abi_type = e->type;
				if (abi_types.count > 0) {
					abi_type = abi_types[i];
				}
				if (e->token.string != "" && !is_blank_ident(e->token)) {
					irValue *param = ir_add_param(proc, e, nullptr, abi_type);
					array_add(&proc->params, param);
				}
			}
		}
	}

	if (proc->type->Proc.has_named_results) {
		GB_ASSERT(proc->type->Proc.result_count > 0);
		TypeTuple *results = &proc->type->Proc.results->Tuple;
		for_array(i, results->variables) {
			Entity *e = results->variables[i];
			if (e->kind != Entity_Variable) {
				continue;
			}

			if (e->token.string != "") {
				GB_ASSERT(!is_blank_ident(e->token));
				irValue *res = ir_add_local(proc, e, e->identifier, true);
				if (e->Variable.default_value.kind != ExactValue_Invalid) {
					irValue *c = ir_value_constant(a, e->type, e->Variable.default_value);
					ir_emit_store(proc, res, c);
				}
			}
		}
	}


	if (proc->type->Proc.calling_convention == ProcCC_Odin) {
		Entity *e = alloc_entity_param(nullptr, make_token_ident(str_lit("__.context_ptr")), t_context_ptr, false, false);
		e->flags |= EntityFlag_NoAlias;
		irValue *param = ir_value_param(a, proc, e, e->type);
		ir_module_add_value(proc->module, e, param);
		array_add(&proc->context_stack, param);
	}
}


void ir_end_procedure_body(irProcedure *proc) {
	if (proc->type->Proc.result_count == 0) {
		ir_emit_return(proc, nullptr);
	}

	if (proc->curr_block->instrs.count == 0) {
		ir_emit_unreachable(proc);
	}

	proc->curr_block = proc->decl_block;
	ir_emit_jump(proc, proc->entry_block);
	proc->curr_block = nullptr;

	ir_number_proc_registers(proc);
}


void ir_insert_code_before_proc(irProcedure* proc, irProcedure *parent) {
	// if (parent == nullptr) {
		// if (proc->name == "main") {
			// ir_emit_startup_runtime(proc);
		// }
	// }
}

void ir_build_proc(irValue *value, irProcedure *parent) {
	irProcedure *proc = &value->Proc;

	proc->parent = parent;

	if (proc->entity != nullptr) {
		irModule *m = proc->module;
		CheckerInfo *info = m->info;
		Entity *e = proc->entity;
		String filename = e->token.pos.file;
		AstFile *f = ast_file_of_filename(info, filename);

		proc->is_export = e->Procedure.is_export;
		proc->is_foreign = e->Procedure.is_foreign;

		irDebugInfo *di_file = nullptr;

		irDebugInfo **di_file_found = map_get(&m->debug_info, hash_ast_file(f));
		if (di_file_found) {
			di_file = *di_file_found;
			GB_ASSERT(di_file->kind == irDebugInfo_File);
		} else {
			di_file = ir_add_debug_info_file(proc, f);
		}

		ir_add_debug_info_proc(proc, e, proc->name, di_file);
	}

	if (proc->body != nullptr) {
		u64 prev_stmt_state_flags = proc->module->stmt_state_flags;

		if (proc->tags != 0) {
			u64 in = proc->tags;
			u64 out = proc->module->stmt_state_flags;
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


	if (proc->type->Proc.has_proc_default_values) {
		auto *p = &proc->type->Proc;
		for_array(i, p->params->Tuple.variables) {
			Entity *f = p->params->Tuple.variables[i];
			if (f->kind == Entity_Variable) {
				if (f->Variable.default_value.kind == ExactValue_Procedure) {
					AstNode *expr = f->Variable.default_value.value_procedure;
					GB_ASSERT(expr != nullptr);
					if (expr->kind == AstNode_ProcLit) {
						ir_gen_anonymous_proc_lit(proc->module, proc->name, expr, proc);
					}
				} else {
					ir_check_type_and_gen_for_proc_lit(proc, f->type);
				}
			}
		}
	}

}







////////////////////////////////////////////////////////////////
//
// @Module
//
////////////////////////////////////////////////////////////////



void ir_module_add_value(irModule *m, Entity *e, irValue *v) {
	map_set(&m->values, hash_entity(e), v);
}

void ir_init_module(irModule *m, Checker *c) {
	// TODO(bill): Determine a decent size for the arena
	isize token_count = c->parser->total_token_count;
	isize arena_size = 4 * token_count * gb_size_of(irValue);
	gb_arena_init_from_allocator(&m->arena,     heap_allocator(), arena_size);
	gb_arena_init_from_allocator(&m->tmp_arena, heap_allocator(), arena_size);
	// m->allocator     = gb_arena_allocator(&m->arena);
	m->allocator     = heap_allocator();
	m->tmp_allocator = gb_arena_allocator(&m->tmp_arena);
	m->info = &c->info;

	m->generate_debug_info = false;
	if (build_context.ODIN_DEBUG) {
		m->generate_debug_info = build_context.ODIN_OS == "windows" && build_context.word_size == 8;
	}

	map_init(&m->values,                  heap_allocator());
	map_init(&m->members,                 heap_allocator());
	map_init(&m->debug_info,              heap_allocator());
	map_init(&m->entity_names,            heap_allocator());
	map_init(&m->anonymous_proc_lits,     heap_allocator());
	array_init(&m->procs,                 heap_allocator());
	array_init(&m->procs_to_generate,     heap_allocator());
	array_init(&m->foreign_library_paths, heap_allocator());
	map_init(&m->const_strings,           heap_allocator());

	// Default states
	m->stmt_state_flags = 0;
	m->stmt_state_flags |= StmtStateFlag_bounds_check;

	{
		// Add type info data
		{
			isize max_type_info_count = m->info->type_info_types.count;

			String name = str_lit(IR_TYPE_INFO_DATA_NAME);
			Entity *e = alloc_entity_variable(nullptr, make_token_ident(name), alloc_type_array(t_type_info, max_type_info_count), false);
			irValue *g = ir_value_global(m->allocator, e, nullptr);
			g->Global.is_private = true;
			ir_module_add_value(m, e, g);
			map_set(&m->members, hash_string(name), g);
			ir_global_type_info_data = g;
		}

		// Type info member buffer
		{
			// NOTE(bill): Removes need for heap allocation by making it global memory
			isize count = 0;

			for_array(entry_index, m->info->type_info_types) {
				Type *t = m->info->type_info_types[entry_index];

				switch (t->kind) {
				case Type_Union:
					count += t->Union.variants.count;
					break;
				case Type_Struct:
					count += t->Struct.fields.count;
					break;
				case Type_Tuple:
					count += t->Tuple.variables.count;
					break;
				}
			}

			{
				String name = str_lit(IR_TYPE_INFO_TYPES_NAME);
				Entity *e = alloc_entity_variable(nullptr, make_token_ident(name),
				                                  alloc_type_array(t_type_info_ptr, count), false);
				irValue *g = ir_value_global(m->allocator, e, nullptr);
				ir_module_add_value(m, e, g);
				map_set(&m->members, hash_string(name), g);
				ir_global_type_info_member_types = g;
			}
			{
				String name = str_lit(IR_TYPE_INFO_NAMES_NAME);
				Entity *e = alloc_entity_variable(nullptr, make_token_ident(name),
				                                  alloc_type_array(t_string, count), false);
				irValue *g = ir_value_global(m->allocator, e, nullptr);
				ir_module_add_value(m, e, g);
				map_set(&m->members, hash_string(name), g);
				ir_global_type_info_member_names = g;
			}
			{
				String name = str_lit(IR_TYPE_INFO_OFFSETS_NAME);
				Entity *e = alloc_entity_variable(nullptr, make_token_ident(name),
				                                  alloc_type_array(t_uintptr, count), false);
				irValue *g = ir_value_global(m->allocator, e, nullptr);
				ir_module_add_value(m, e, g);
				map_set(&m->members, hash_string(name), g);
				ir_global_type_info_member_offsets = g;
			}

			{
				String name = str_lit(IR_TYPE_INFO_USINGS_NAME);
				Entity *e = alloc_entity_variable(nullptr, make_token_ident(name),
				                                  alloc_type_array(t_bool, count), false);
				irValue *g = ir_value_global(m->allocator, e, nullptr);
				ir_module_add_value(m, e, g);
				map_set(&m->members, hash_string(name), g);
				ir_global_type_info_member_usings = g;
			}
		}
	}

	{
		irDebugInfo *di = ir_alloc_debug_info(m->allocator, irDebugInfo_CompileUnit);
		di->CompileUnit.file = m->info->files.entries[0].value; // Zeroth is the init file
		di->CompileUnit.producer = str_lit("odin");

		map_set(&m->debug_info, hash_pointer(m), di);

		m->debug_compile_unit = di;
	}
}

void ir_destroy_module(irModule *m) {
	map_destroy(&m->values);
	map_destroy(&m->members);
	map_destroy(&m->entity_names);
	map_destroy(&m->anonymous_proc_lits);
	map_destroy(&m->debug_info);
	map_destroy(&m->const_strings);
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


bool ir_gen_init(irGen *s, Checker *c) {
	if (global_error_collector.count != 0) {
		return false;
	}

	isize tc = c->parser->total_token_count;
	if (tc < 2) {
		return false;
	}

	ir_init_module(&s->module, c);
	// s->module.generate_debug_info = false;

	String init_fullpath = c->parser->init_fullpath;

	if (build_context.out_filepath.len == 0) {
		s->output_name = filename_from_path(init_fullpath);
		s->output_base = s->output_name;
	} else {
		s->output_name = build_context.out_filepath;
		isize pos = string_extension_position(s->output_name);
		if (pos < 0) {
			s->output_base = s->output_name;
		} else {
			s->output_base = substring(s->output_name, 0, pos);
		}
	}
	gbAllocator ha = heap_allocator();
	s->output_base = path_to_full_path(ha, s->output_base);

	gbString output_file_path = gb_string_make_length(ha, s->output_base.text, s->output_base.len);
	output_file_path = gb_string_appendc(output_file_path, ".ll");
	defer (gb_string_free(output_file_path));

	gbFileError err = gb_file_create(&s->output_file, output_file_path);
	if (err != gbFileError_None) {
		gb_printf_err("Failed to create file %s\n", output_file_path);
		return false;
	}

	return true;
}

void ir_gen_destroy(irGen *s) {
	ir_destroy_module(&s->module);
	gb_file_close(&s->output_file);
}



//
// Type Info stuff
//
irValue *ir_get_type_info_ptr(irProcedure *proc, Type *type) {
	i32 index = cast(i32)type_info_index(proc->module->info, type);
	// gb_printf_err("%d %s\n", index, type_to_string(type));
	irValue *ptr = ir_emit_array_epi(proc, ir_global_type_info_data, index);
	return ir_emit_bitcast(proc, ptr, t_type_info_ptr);
}

irValue *ir_type_info_member_types_offset(irProcedure *proc, isize count) {
	irValue *offset = ir_emit_array_epi(proc, ir_global_type_info_member_types, ir_global_type_info_member_types_index);
	ir_global_type_info_member_types_index += cast(i32)count;
	return offset;
}
irValue *ir_type_info_member_names_offset(irProcedure *proc, isize count) {
	irValue *offset = ir_emit_array_epi(proc, ir_global_type_info_member_names, ir_global_type_info_member_names_index);
	ir_global_type_info_member_names_index += cast(i32)count;
	return offset;
}
irValue *ir_type_info_member_offsets_offset(irProcedure *proc, isize count) {
	irValue *offset = ir_emit_array_epi(proc, ir_global_type_info_member_offsets, ir_global_type_info_member_offsets_index);
	ir_global_type_info_member_offsets_index += cast(i32)count;
	return offset;
}
irValue *ir_type_info_member_usings_offset(irProcedure *proc, isize count) {
	irValue *offset = ir_emit_array_epi(proc, ir_global_type_info_member_usings, ir_global_type_info_member_usings_index);
	ir_global_type_info_member_usings_index += cast(i32)count;
	return offset;
}






void ir_setup_type_info_data(irProcedure *proc) { // NOTE(bill): Setup type_info data
	irModule *m = proc->module;
	gbAllocator a = m->allocator;
	CheckerInfo *info = m->info;

	if (true) {
		irValue *global_type_table = ir_find_global_variable(proc, str_lit("__type_table"));
		Type *type = base_type(type_deref(ir_type(ir_global_type_info_data)));
		GB_ASSERT(is_type_array(type));
		irValue *len = ir_const_int(proc->module->allocator, type->Array.count);
		ir_fill_slice(proc, global_type_table,
		              ir_emit_array_epi(proc, ir_global_type_info_data, 0),
		              len);
	}


	// Useful types
	Type *t_i64_slice_ptr    = alloc_type_pointer(alloc_type_slice(t_i64));
	Type *t_string_slice_ptr = alloc_type_pointer(alloc_type_slice(t_string));

	i32 type_info_member_types_index = 0;
	i32 type_info_member_names_index = 0;
	i32 type_info_member_offsets_index = 0;

	for_array(type_info_type_index, info->type_info_types) {
		Type *t = info->type_info_types[type_info_type_index];
		t = default_type(t);
		if (t == t_invalid) {
			continue;
		}

		isize entry_index = type_info_index(info, t);

		irValue *tag = nullptr;
		irValue *ti_ptr = ir_emit_array_epi(proc, ir_global_type_info_data, cast(i32)entry_index);
		irValue *variant_ptr = ir_emit_struct_ep(proc, ti_ptr, 2);

		ir_emit_store(proc, ir_emit_struct_ep(proc, ti_ptr, 0), ir_const_int(a, type_size_of(t)));
		ir_emit_store(proc, ir_emit_struct_ep(proc, ti_ptr, 1), ir_const_int(a, type_align_of(t)));


		switch (t->kind) {
		case Type_Named: {
			ir_emit_comment(proc, str_lit("Type_Info_Named"));
			tag = ir_emit_conv(proc, variant_ptr, t_type_info_named_ptr);

			// TODO(bill): Which is better? The mangled name or actual name?
			irValue *name = ir_const_string(a, t->Named.type_name->token.string);
			irValue *gtip = ir_get_type_info_ptr(proc, t->Named.base);

			ir_emit_store(proc, ir_emit_struct_ep(proc, tag, 0), name);
			ir_emit_store(proc, ir_emit_struct_ep(proc, tag, 1), gtip);
			break;
		}

		case Type_Basic:
			ir_emit_comment(proc, str_lit("Type_Info_Basic"));
			switch (t->Basic.kind) {
			case Basic_bool:
			case Basic_b8:
			case Basic_b16:
			case Basic_b32:
			case Basic_b64:
				tag = ir_emit_conv(proc, variant_ptr, t_type_info_boolean_ptr);
				break;

			case Basic_i8:
			case Basic_u8:
			case Basic_i16:
			case Basic_u16:
			case Basic_i32:
			case Basic_u32:
			case Basic_i64:
			case Basic_u64:
			case Basic_int:
			case Basic_uint:
			case Basic_uintptr: {
				tag = ir_emit_conv(proc, variant_ptr, t_type_info_integer_ptr);
				irValue *is_signed = ir_const_bool(a, (t->Basic.flags & BasicFlag_Unsigned) == 0);
				ir_emit_store(proc, ir_emit_struct_ep(proc, tag, 0), is_signed);
				break;
			}

			case Basic_rune:
				tag = ir_emit_conv(proc, variant_ptr, t_type_info_rune_ptr);
				break;

			// case Basic_f16:
			case Basic_f32:
			case Basic_f64:
				tag = ir_emit_conv(proc, variant_ptr, t_type_info_float_ptr);
				break;

			// case Basic_complex32:
			case Basic_complex64:
			case Basic_complex128:
				tag = ir_emit_conv(proc, variant_ptr, t_type_info_complex_ptr);
				break;

			case Basic_rawptr:
				tag = ir_emit_conv(proc, variant_ptr, t_type_info_pointer_ptr);
				break;

			case Basic_string:
				tag = ir_emit_conv(proc, variant_ptr, t_type_info_string_ptr);
				break;

			case Basic_cstring:
				tag = ir_emit_conv(proc, variant_ptr, t_type_info_string_ptr);
				ir_emit_store(proc, ir_emit_struct_ep(proc, tag, 0), v_true); // is_cstring
				break;

			case Basic_any:
				tag = ir_emit_conv(proc, variant_ptr, t_type_info_any_ptr);
				break;
			}
			break;

		case Type_Pointer: {
			ir_emit_comment(proc, str_lit("Type_Info_Pointer"));
			tag = ir_emit_conv(proc, variant_ptr, t_type_info_pointer_ptr);
			irValue *gep = ir_get_type_info_ptr(proc, t->Pointer.elem);
			ir_emit_store(proc, ir_emit_struct_ep(proc, tag, 0), gep);
			break;
		}
		case Type_Array: {
			ir_emit_comment(proc, str_lit("Type_Info_Array"));
			tag = ir_emit_conv(proc, variant_ptr, t_type_info_array_ptr);
			irValue *gep = ir_get_type_info_ptr(proc, t->Array.elem);
			ir_emit_store(proc, ir_emit_struct_ep(proc, tag, 0), gep);

			isize ez = type_size_of(t->Array.elem);
			irValue *elem_size = ir_emit_struct_ep(proc, tag, 1);
			ir_emit_store(proc, elem_size, ir_const_int(a, ez));

			irValue *count = ir_emit_struct_ep(proc, tag, 2);
			ir_emit_store(proc, count, ir_const_int(a, t->Array.count));

			break;
		}
		case Type_DynamicArray: {
			ir_emit_comment(proc, str_lit("Type_Info_Dynamic_Array"));
			tag = ir_emit_conv(proc, variant_ptr, t_type_info_dynamic_array_ptr);
			irValue *gep = ir_get_type_info_ptr(proc, t->DynamicArray.elem);
			ir_emit_store(proc, ir_emit_struct_ep(proc, tag, 0), gep);

			isize ez = type_size_of(t->DynamicArray.elem);
			irValue *elem_size = ir_emit_struct_ep(proc, tag, 1);
			ir_emit_store(proc, elem_size, ir_const_int(a, ez));
			break;
		}
		case Type_Slice: {
			ir_emit_comment(proc, str_lit("Type_Info_Slice"));
			tag = ir_emit_conv(proc, variant_ptr, t_type_info_slice_ptr);
			irValue *gep = ir_get_type_info_ptr(proc, t->Slice.elem);
			ir_emit_store(proc, ir_emit_struct_ep(proc, tag, 0), gep);

			isize ez = type_size_of(t->Slice.elem);
			irValue *elem_size = ir_emit_struct_ep(proc, tag, 1);
			ir_emit_store(proc, elem_size, ir_const_int(a, ez));
			break;
		}
		case Type_Proc: {
			ir_emit_comment(proc, str_lit("Type_Info_Proc"));
			tag = ir_emit_conv(proc, variant_ptr, t_type_info_procedure_ptr);

			irValue *params     = ir_emit_struct_ep(proc, tag, 0);
			irValue *results    = ir_emit_struct_ep(proc, tag, 1);
			irValue *variadic   = ir_emit_struct_ep(proc, tag, 2);
			irValue *convention = ir_emit_struct_ep(proc, tag, 3);

			if (t->Proc.params != nullptr) {
				ir_emit_store(proc, params, ir_get_type_info_ptr(proc, t->Proc.params));
			}
			if (t->Proc.results != nullptr) {
				ir_emit_store(proc, results, ir_get_type_info_ptr(proc, t->Proc.results));
			}
			ir_emit_store(proc, variadic, ir_const_bool(a, t->Proc.variadic));
			ir_emit_store(proc, convention, ir_const_int(a, t->Proc.calling_convention));

			// TODO(bill): TypeInfo for procedures
			break;
		}
		case Type_Tuple: {
			ir_emit_comment(proc, str_lit("Type_Info_Tuple"));
			tag = ir_emit_conv(proc, variant_ptr, t_type_info_tuple_ptr);

			irValue *memory_types = ir_type_info_member_types_offset(proc, t->Tuple.variables.count);
			irValue *memory_names = ir_type_info_member_names_offset(proc, t->Tuple.variables.count);

			for_array(i, t->Tuple.variables) {
				// NOTE(bill): offset is not used for tuples
				Entity *f = t->Tuple.variables[i];

				irValue *index     = ir_const_int(a, i);
				irValue *type_info = ir_emit_ptr_offset(proc, memory_types, index);

				ir_emit_store(proc, type_info, ir_type_info(proc, f->type));
				if (f->token.string.len > 0) {
					irValue *name = ir_emit_ptr_offset(proc, memory_names, index);
					ir_emit_store(proc, name, ir_const_string(a, f->token.string));
				}
			}

			irValue *count = ir_const_int(a, t->Tuple.variables.count);
			ir_fill_slice(proc, ir_emit_struct_ep(proc, tag, 0), memory_types, count);
			ir_fill_slice(proc, ir_emit_struct_ep(proc, tag, 1), memory_names, count);
			break;
		}
		case Type_Enum:
			ir_emit_comment(proc, str_lit("Type_Info_Enum"));
			tag = ir_emit_conv(proc, variant_ptr, t_type_info_enum_ptr);
			{
				GB_ASSERT(t->Enum.base_type != nullptr);
				irValue *base = ir_type_info(proc, t->Enum.base_type);
				ir_emit_store(proc, ir_emit_struct_ep(proc, tag, 0), base);

				// is_export
				ir_emit_store(proc, ir_emit_struct_ep(proc, tag, 3), ir_const_bool(a, t->Enum.is_export));

				if (t->Enum.fields.count > 0) {
					auto fields = t->Enum.fields;
					irValue *name_array  = ir_generate_array(m, t_string, fields.count,
					                                         str_lit("__$enum_names"), cast(i64)entry_index);
					irValue *value_array = ir_generate_array(m, t_type_info_enum_value, fields.count,
					                                         str_lit("__$enum_values"), cast(i64)entry_index);

					bool is_value_int = is_type_integer(t->Enum.base_type);
					if (!is_value_int) {
						GB_ASSERT(is_type_float(t->Enum.base_type));
					}

					for_array(i, fields) {
						irValue *name_ep  = ir_emit_array_epi(proc, name_array, cast(i32)i);
						irValue *value_ep = ir_emit_array_epi(proc, value_array, cast(i32)i);

						ExactValue value = fields[i]->Constant.value;
						irValue *v = ir_value_constant(a, t->Enum.base_type, value);

						ir_emit_store_union_variant(proc, value_ep, v, ir_type(v));
						ir_emit_store(proc, name_ep, ir_const_string(a, fields[i]->token.string));
					}

					irValue *v_count = ir_const_int(a, fields.count);

					irValue *names = ir_emit_struct_ep(proc, tag, 1);
					irValue *name_array_elem = ir_array_elem(proc, name_array);
					ir_fill_slice(proc, names, name_array_elem, v_count);

					irValue *values = ir_emit_struct_ep(proc, tag, 2);
					irValue *value_array_elem = ir_array_elem(proc, value_array);
					ir_fill_slice(proc, values, value_array_elem, v_count);
				}
			}
			break;

		case Type_Union: {
			ir_emit_comment(proc, str_lit("Type_Info_Union"));
			tag = ir_emit_conv(proc, variant_ptr, t_type_info_union_ptr);

			{
				irValue *variant_types  = ir_emit_struct_ep(proc, tag, 0);
				irValue *tag_offset_ptr = ir_emit_struct_ep(proc, tag, 1);
				irValue *tag_type_ptr   = ir_emit_struct_ep(proc, tag, 2);

				isize variant_count = gb_max(0, t->Union.variants.count);
				irValue *memory_types = ir_type_info_member_types_offset(proc, variant_count);

				// NOTE(bill): Zeroth is nil so ignore it
				for (isize variant_index = 0; variant_index < variant_count; variant_index++) {
					Type *vt = t->Union.variants[variant_index];
					irValue *tip = ir_get_type_info_ptr(proc, vt);

					irValue *index     = ir_const_int(a, variant_index);
					irValue *type_info = ir_emit_ptr_offset(proc, memory_types, index);
					ir_emit_store(proc, type_info, ir_type_info(proc, vt));
				}

				irValue *count = ir_const_int(a, variant_count);
				ir_fill_slice(proc, variant_types, memory_types, count);

				i64 tag_size   = union_tag_size(t);
				i64 tag_offset = align_formula(t->Union.variant_block_size, tag_size);

				if (tag_size > 0) {
					ir_emit_store(proc, tag_offset_ptr, ir_const_uintptr(a, tag_offset));
					ir_emit_store(proc, tag_type_ptr,   ir_type_info(proc, union_tag_type(t)));
				}
			}

			break;
		}

		case Type_Struct: {
			ir_emit_comment(proc, str_lit("Type_Info_Struct"));
			tag = ir_emit_conv(proc, variant_ptr, t_type_info_struct_ptr);

			{
				irValue *is_packed       = ir_const_bool(a, t->Struct.is_packed);
				irValue *is_raw_union    = ir_const_bool(a, t->Struct.is_raw_union);
				irValue *is_custom_align = ir_const_bool(a, t->Struct.custom_align != 0);
				ir_emit_store(proc, ir_emit_struct_ep(proc, tag, 4), is_packed);
				ir_emit_store(proc, ir_emit_struct_ep(proc, tag, 5), is_raw_union);
				ir_emit_store(proc, ir_emit_struct_ep(proc, tag, 6), is_custom_align);
			}

			isize count = t->Struct.fields.count;

			irValue *memory_types   = ir_type_info_member_types_offset  (proc, count);
			irValue *memory_names   = ir_type_info_member_names_offset  (proc, count);
			irValue *memory_offsets = ir_type_info_member_offsets_offset(proc, count);
			irValue *memory_usings  = ir_type_info_member_usings_offset (proc, count);

			type_set_offsets(t); // NOTE(bill): Just incase the offsets have not been set yet
			for (isize source_index = 0; source_index < count; source_index++) {
				// TODO(bill): Order fields in source order not layout order
				Entity *f = t->Struct.fields[source_index];
				irValue *tip = ir_get_type_info_ptr(proc, f->type);
				i64 foffset = 0;
				if (!t->Struct.is_raw_union) {
					foffset = t->Struct.offsets[f->Variable.field_index];
				}
				GB_ASSERT(f->kind == Entity_Variable && f->flags & EntityFlag_Field);

				irValue *index     = ir_const_int(a, source_index);
				irValue *type_info = ir_emit_ptr_offset(proc, memory_types,   index);
				irValue *offset    = ir_emit_ptr_offset(proc, memory_offsets, index);
				irValue *is_using  = ir_emit_ptr_offset(proc, memory_usings, index);

				ir_emit_store(proc, type_info, ir_type_info(proc, f->type));
				if (f->token.string.len > 0) {
					irValue *name = ir_emit_ptr_offset(proc, memory_names,   index);
					ir_emit_store(proc, name, ir_const_string(a, f->token.string));
				}
				ir_emit_store(proc, offset, ir_const_uintptr(a, foffset));
				ir_emit_store(proc, is_using, ir_const_bool(a, (f->flags&EntityFlag_Using) != 0));
			}

			irValue *cv = ir_const_int(a, count);
			ir_fill_slice(proc, ir_emit_struct_ep(proc, tag, 0), memory_types,   cv);
			ir_fill_slice(proc, ir_emit_struct_ep(proc, tag, 1), memory_names,   cv);
			ir_fill_slice(proc, ir_emit_struct_ep(proc, tag, 2), memory_offsets, cv);
			ir_fill_slice(proc, ir_emit_struct_ep(proc, tag, 3), memory_usings,  cv);
			break;
		}
		case Type_Map: {
			ir_emit_comment(proc, str_lit("Type_Info_Map"));
			tag = ir_emit_conv(proc, variant_ptr, t_type_info_map_ptr);
			init_map_internal_types(t);

			irValue *key              = ir_emit_struct_ep(proc, tag, 0);
			irValue *value            = ir_emit_struct_ep(proc, tag, 1);
			irValue *generated_struct = ir_emit_struct_ep(proc, tag, 2);

			ir_emit_store(proc, key,              ir_get_type_info_ptr(proc, t->Map.key));
			ir_emit_store(proc, value,            ir_get_type_info_ptr(proc, t->Map.value));
			ir_emit_store(proc, generated_struct, ir_get_type_info_ptr(proc, t->Map.generated_struct_type));
			break;
		}

		case Type_BitField: {
			ir_emit_comment(proc, str_lit("Type_Info_Bit_Field"));
			tag = ir_emit_conv(proc, variant_ptr, t_type_info_bit_field_ptr);
			// names:   []string;
			// bits:    []u32;
			// offsets: []u32;
			isize count = t->BitField.fields.count;
			if (count > 0) {
				auto fields = t->BitField.fields;
				irValue *name_array   = ir_generate_array(m, t_string, count, str_lit("__$bit_field_names"),   cast(i64)entry_index);
				irValue *bit_array    = ir_generate_array(m, t_i32,    count, str_lit("__$bit_field_bits"),    cast(i64)entry_index);
				irValue *offset_array = ir_generate_array(m, t_i32,    count, str_lit("__$bit_field_offsets"), cast(i64)entry_index);

				for (isize i = 0; i < count; i++) {
					Entity *f = fields[i];
					GB_ASSERT(f->type != nullptr);
					GB_ASSERT(f->type->kind == Type_BitFieldValue);
					irValue *name_ep   = ir_emit_array_epi(proc, name_array,   cast(i32)i);
					irValue *bit_ep    = ir_emit_array_epi(proc, bit_array,    cast(i32)i);
					irValue *offset_ep = ir_emit_array_epi(proc, offset_array, cast(i32)i);

					ir_emit_store(proc, name_ep, ir_const_string(a, f->token.string));
					ir_emit_store(proc, bit_ep, ir_const_i32(a, f->type->BitFieldValue.bits));
					ir_emit_store(proc, offset_ep, ir_const_i32(a, t->BitField.offsets[i]));

				}

				irValue *v_count = ir_const_int(a, count);

				irValue *names = ir_emit_struct_ep(proc, tag, 0);
				irValue *name_array_elem = ir_array_elem(proc, name_array);
				ir_fill_slice(proc, names, name_array_elem, v_count);

				irValue *bits = ir_emit_struct_ep(proc, tag, 1);
				irValue *bit_array_elem = ir_array_elem(proc, bit_array);
				ir_fill_slice(proc, bits, bit_array_elem, v_count);

				irValue *offsets = ir_emit_struct_ep(proc, tag, 2);
				irValue *offset_array_elem = ir_array_elem(proc, offset_array);
				ir_fill_slice(proc, offsets, offset_array_elem, v_count);
			}
			break;
		}
		}


		if (tag != nullptr) {
			Type *tag_type = type_deref(ir_type(tag));
			GB_ASSERT(is_type_named(tag_type));
			ir_emit_store_union_variant(proc, variant_ptr, ir_emit_load(proc, tag), tag_type);
		} else {
			if (t != t_llvm_bool) {
				GB_PANIC("Unhandled Type_Info variant: %s", type_to_string(t));
			}
		}
	}
}

void ir_gen_tree(irGen *s) {
	irModule *m = &s->module;
	CheckerInfo *info = m->info;
	gbAllocator a = m->allocator;

	if (v_zero == nullptr) {
		v_zero    = ir_const_int (m->allocator, 0);
		v_one     = ir_const_int (m->allocator, 1);
		v_zero32  = ir_const_i32 (m->allocator, 0);
		v_one32   = ir_const_i32 (m->allocator, 1);
		v_two32   = ir_const_i32 (m->allocator, 2);
		v_false   = ir_const_bool(m->allocator, false);
		v_true    = ir_const_bool(m->allocator, true);
		v_raw_nil = ir_value_constant(m->allocator, t_rawptr, exact_value_pointer(0));
	}

	isize global_variable_max_count = 0;
	Entity *entry_point = info->entry_point;
	bool has_dll_main = false;
	bool has_win_main = false;

	for_array(i, info->entities) {
		Entity *e = info->entities[i];
		String name = e->token.string;
		if (e->kind == Entity_Variable) {
			global_variable_max_count++;
		} else if (e->kind == Entity_Procedure && !e->scope->is_global) {
			if (e->scope->is_init && name == "main") {
				GB_ASSERT(e == entry_point);
				// entry_point = e;
			}
			if (e->Procedure.is_export ||
			    (e->Procedure.link_name.len > 0) ||
			    (e->scope->is_file && e->Procedure.link_name.len > 0)) {
				if (!has_dll_main && name == "DllMain") {
					has_dll_main = true;
				} else if (!has_win_main && name == "WinMain") {
					has_win_main = true;
				}
			}
		}
	}

	// Add global default context
	m->global_default_context = ir_add_global_generated(m, t_context, nullptr);

	struct irGlobalVariable {
		irValue *var, *init;
		DeclInfo *decl;
	};
	auto global_variables = array_make<irGlobalVariable>(m->tmp_allocator, 0, global_variable_max_count);

	m->entry_point_entity = entry_point;
	m->min_dep_set = info->minimum_dependency_set;

	for_array(i, info->variable_init_order) {
		DeclInfo *d = info->variable_init_order[i];

		for (isize j = 0; j < d->entity_count; j++) {
			Entity *e = d->entities[j];

			if (!e->scope->is_file) {
				continue;
			}

			if (!ir_min_dep_entity(m, e)) {
				continue;
			}
			DeclInfo *decl = decl_info_of_entity(info, e);
			if (decl == nullptr) {
				continue;
			}
			GB_ASSERT(e->kind == Entity_Variable);


			bool is_foreign = e->Variable.is_foreign;
			bool is_export  = e->Variable.is_export;
			bool no_name_mangle = e->scope->is_global || e->Variable.link_name.len > 0 || is_foreign || is_export;

			String name = e->token.string;
			if (!no_name_mangle) {
				name = ir_mangle_name(s, e->token.pos.file, e);
			}
			ir_add_entity_name(m, e, name);

			irValue *g = ir_value_global(a, e, nullptr);
			g->Global.name = name;
			g->Global.thread_local_model = e->Variable.thread_local_model;
			g->Global.is_foreign = is_foreign;
			g->Global.is_export  = is_export;

			irGlobalVariable var = {};
			var.var = g;
			var.decl = decl;


			if (e->type->kind == Type_Struct && e->type->Struct.has_proc_default_values) {
				for_array(i, e->type->Struct.fields) {
					Entity *f = e->type->Struct.fields[i];
					if (f->kind == Entity_Variable && f->Variable.default_value.kind == ExactValue_Procedure) {
						AstNode *expr = f->Variable.default_value.value_procedure;
						GB_ASSERT(expr != nullptr);
						if (expr->kind == AstNode_ProcLit) {
							ir_gen_anonymous_proc_lit(m, e->token.string, expr);
						}
					}
				}
			}

			if (decl->init_expr != nullptr && !is_type_any(e->type)) {
				TypeAndValue tav = type_and_value_of_expr(info, decl->init_expr);
				if (tav.mode != Addressing_Invalid) {
					if (tav.value.kind != ExactValue_Invalid) {
						ExactValue v = tav.value;
						g->Global.value = ir_add_module_constant(m, tav.type, v);
					}
				}
			}

			array_add(&global_variables, var);

			ir_module_add_value(m, e, g);
			map_set(&m->members, hash_string(name), g);
		}
	}

	for_array(i, info->entities) {
		Entity *  e     = info->entities[i];
		String    name  = e->token.string;
		DeclInfo *decl  = e->decl_info;
		Scope *   scope = e->scope;

		if (!scope->is_file) {
			continue;
		}

		switch (e->kind) {
		case Entity_Variable:
			// NOTE(bill): Handled above as it requires a specific load order
			continue;
		case Entity_ProcGroup:
			continue;
		}

		bool polymorphic_struct = false;
		if (e->type != nullptr && e->kind == Entity_TypeName) {
			Type *bt = base_type(e->type);
			if (bt->kind == Type_Struct) {
				polymorphic_struct = is_type_polymorphic(bt);
			}
		}

		if (!polymorphic_struct && !ir_min_dep_entity(m, e)) {
			// NOTE(bill): Nothing depends upon it so doesn't need to be built
			continue;
		}

		String original_name = name;

		if (!scope->is_global || polymorphic_struct || is_type_polymorphic(e->type)) {
			if (e->kind == Entity_Procedure && e->Procedure.is_export) {
			} else if (e->kind == Entity_Procedure && e->Procedure.link_name.len > 0) {
				// Handle later
			} else {
				name = ir_mangle_name(s, e->token.pos.file, e);
			}
		}
		ir_add_entity_name(m, e, name);

		switch (e->kind) {
		case Entity_TypeName:
			ir_gen_global_type_name(m, e, name);
			break;

		case Entity_Procedure: {
			ast_node(pl, ProcLit, decl->proc_lit);
			String original_name = name;
			AstNode *body = pl->body;

			if (e->Procedure.is_foreign) {
				name = e->token.string; // NOTE(bill): Don't use the mangled name
				ir_add_foreign_library_path(m, e->Procedure.foreign_library);
			}
			if (e->Procedure.link_name.len > 0) {
				name = e->Procedure.link_name;
			}

			AstNode *type_expr = pl->type;

			irValue *p = ir_value_procedure(a, m, e, e->type, type_expr, body, name);
			p->Proc.tags = pl->tags;
			p->Proc.inlining = pl->inlining;

			ir_module_add_value(m, e, p);
			HashKey hash_name = hash_string(name);
			if (map_get(&m->members, hash_name) == nullptr) {
				map_set(&m->members, hash_name, p);
			}
			break;
		}
		}
	}

	for_array(i, m->members.entries) {
		auto *entry = &m->members.entries[i];
		irValue *v = entry->value;
		if (v->kind == irValue_Proc) {
			ir_build_proc(v, nullptr);
		}
	}

	irDebugInfo *compile_unit = m->debug_info.entries[0].value;
	GB_ASSERT(compile_unit->kind == irDebugInfo_CompileUnit);
	irDebugInfo *all_procs = ir_alloc_debug_info(m->allocator, irDebugInfo_AllProcs);

	isize all_proc_max_count = 0;
	for_array(i, m->debug_info.entries) {
		irDebugInfo *di = m->debug_info.entries[i].value;
		if (di->kind == irDebugInfo_Proc) {
			all_proc_max_count++;
		}
	}

	array_init(&all_procs->AllProcs.procs, m->allocator, 0, all_proc_max_count);
	map_set(&m->debug_info, hash_pointer(all_procs), all_procs); // NOTE(bill): This doesn't need to be mapped
	compile_unit->CompileUnit.all_procs = all_procs;


	for_array(i, m->debug_info.entries) {
		irDebugInfo *di = m->debug_info.entries[i].value;
		if (di->kind == irDebugInfo_Proc) {
			array_add(&all_procs->AllProcs.procs, di);
		}
	}


#if defined(GB_SYSTEM_WINDOWS)
	if (build_context.is_dll && !has_dll_main) {
		// DllMain :: proc(inst: rawptr, reason: u32, reserved: rawptr) -> i32
		String name = str_lit("DllMain");
		Type *proc_params = alloc_type_tuple();
		Type *proc_results = alloc_type_tuple();

		Scope *proc_scope = gb_alloc_item(a, Scope);

		array_init(&proc_params->Tuple.variables, a, 3);
		array_init(&proc_results->Tuple.variables, a, 1);

		proc_params->Tuple.variables[0] = alloc_entity_param(proc_scope, blank_token, t_rawptr, false, false);
		proc_params->Tuple.variables[1] = alloc_entity_param(proc_scope, make_token_ident(str_lit("reason")), t_i32, false, false);
		proc_params->Tuple.variables[2] = alloc_entity_param(proc_scope, blank_token, t_rawptr, false, false);


		proc_results->Tuple.variables[0] = alloc_entity_param(proc_scope, empty_token, t_i32, false, false);


		Type *proc_type = alloc_type_proc(proc_scope,
		                                  proc_params, 3,
		                                  proc_results, 1, false, ProcCC_StdCall);

		// TODO(bill): make this more robust
		proc_type->Proc.abi_compat_params = array_make<Type *>(a, proc_params->Tuple.variables.count);
		for_array(i, proc_params->Tuple.variables) {
			proc_type->Proc.abi_compat_params[i] = proc_params->Tuple.variables[i]->type;
		}
		proc_type->Proc.abi_compat_result_type = proc_results->Tuple.variables[0]->type;

		AstNode *body = gb_alloc_item(a, AstNode);
		Entity *e = alloc_entity_procedure(nullptr, make_token_ident(name), proc_type, 0);
		irValue *p = ir_value_procedure(a, m, e, proc_type, nullptr, body, name);

		map_set(&m->values, hash_entity(e), p);
		map_set(&m->members, hash_string(name), p);

		irProcedure *proc = &p->Proc;
		proc->inlining = ProcInlining_no_inline; // TODO(bill): is no_inline a good idea?
		proc->is_entry_point = true;
		e->Procedure.link_name = name;

		ir_begin_procedure_body(proc);
		defer (ir_end_procedure_body(proc));

		// NOTE(bill): https://msdn.microsoft.com/en-us/library/windows/desktop/ms682583(v=vs.85).aspx
		// DLL_PROCESS_ATTACH == 1

		irAddr reason_addr = ir_build_addr_from_entity(proc, proc_params->Tuple.variables[1], nullptr);
		irValue *cond = ir_emit_comp(proc, Token_CmpEq, ir_addr_load(proc, reason_addr), v_one32);
		irBlock *then = ir_new_block(proc, nullptr, "if.then");
		irBlock *done = ir_new_block(proc, nullptr, "if.done"); // NOTE(bill): Append later
		ir_emit_if(proc, cond, then, done);
		ir_start_block(proc, then);

		{
			irValue **found = map_get(&m->values, hash_entity(entry_point));
			ir_emit(proc, ir_alloc_instr(proc, irInstr_StartupRuntime));
			if (found != nullptr) {
				Array<irValue *> args = {};
				ir_emit_call(proc, *found, args);
			}
		}

		ir_emit_jump(proc, done);
		ir_start_block(proc, done);

		ir_emit_return(proc, v_one32);
	}
#endif
	if (!(build_context.is_dll && !has_dll_main)) {
		// main :: proc(argc: i32, argv: ^^u8) -> i32
		String name = str_lit("main");

		if (str_eq_ignore_case(cross_compile_target, str_lit("Essence"))) {
			// This is a bit hacky,
			// because this makes this function the first function run in the executable
			// so it won't actually have the argc/argv arguments.
			name = str_lit("ProgramEntry");
		}

		Type *proc_params = alloc_type_tuple();
		Type *proc_results = alloc_type_tuple();

		Scope *proc_scope = gb_alloc_item(a, Scope);

		array_init(&proc_params->Tuple.variables, a, 2);
		array_init(&proc_results->Tuple.variables, a, 1);

		Type *cstring_ptr = alloc_type_pointer(t_cstring);
		proc_params->Tuple.variables[0] = alloc_entity_param(proc_scope, make_token_ident(str_lit("argc")), t_i32, false, false);
		proc_params->Tuple.variables[1] = alloc_entity_param(proc_scope, make_token_ident(str_lit("argv")), cstring_ptr, false, false);


		proc_results->Tuple.variables[0] = alloc_entity_param(proc_scope, empty_token, t_i32, false, false);


		Type *proc_type = alloc_type_proc(proc_scope,
		                                  proc_params, 2,
		                                  proc_results, 1, false, ProcCC_CDecl);

		// TODO(bill): make this more robust
		proc_type->Proc.abi_compat_params = array_make<Type *>(a, proc_params->Tuple.variables.count);
		for_array(i, proc_params->Tuple.variables) {
			proc_type->Proc.abi_compat_params[i] = proc_params->Tuple.variables[i]->type;
		}
		proc_type->Proc.abi_compat_result_type = proc_results->Tuple.variables[0]->type;

		AstNode *body = gb_alloc_item(a, AstNode);
		Entity *e     = alloc_entity_procedure(nullptr, make_token_ident(name), proc_type, 0);
		irValue *p    = ir_value_procedure(a, m, e, proc_type, nullptr, body, name);

		map_set(&m->values, hash_entity(e), p);
		map_set(&m->members, hash_string(name), p);

		irProcedure *proc = &p->Proc;
		proc->inlining = ProcInlining_no_inline; // TODO(bill): is no_inline a good idea?
		proc->is_entry_point = true;
		e->Procedure.link_name = name;

		ir_begin_procedure_body(proc);
		defer (ir_end_procedure_body(proc));

		// NOTE(bill): https://msdn.microsoft.com/en-us/library/windows/desktop/ms682583(v=vs.85).aspx
		// DLL_PROCESS_ATTACH == 1

		irValue *argc = ir_emit_load(proc, *map_get(&proc->module->values, hash_entity(proc_params->Tuple.variables[0])));
		irValue *argv = ir_emit_load(proc, *map_get(&proc->module->values, hash_entity(proc_params->Tuple.variables[1])));

		irValue *global_args = ir_find_global_variable(proc, str_lit("__args__"));

		ir_fill_slice(proc, global_args, argv, ir_emit_conv(proc, argc, t_int));

		ir_emit(proc, ir_alloc_instr(proc, irInstr_StartupRuntime));
		{
			irValue **found = map_get(&proc->module->values, hash_entity(entry_point));
			if (found != nullptr) {
				Array<irValue *> args = {};
				ir_emit_call(proc, *found, args);
			}
		}

		ir_emit_return(proc, v_zero32);
	}

#if 0 && defined(GB_SYSTEM_WINDOWS)
	if (!m->build_context->is_dll && !has_win_main) {
		// proc WinMain(inst, prev: rawptr, cmd_line: ^byte, cmd_show: i32) -> i32
		String name = str_lit("WinMain");
		Type *proc_params = alloc_type_tuple();
		Type *proc_results = alloc_type_tuple();

		Scope *proc_scope = gb_alloc_item(a, Scope);

		proc_params->Tuple.variables = gb_alloc_array(a, Entity *, 4);
		proc_params->Tuple.variable_count = 4;

		proc_results->Tuple.variables = gb_alloc_array(a, Entity *, 1);
		proc_results->Tuple.variable_count = 1;

		proc_params->Tuple.variables[0] = alloc_entity_param(proc_scope, blank_token, t_rawptr, false);
		proc_params->Tuple.variables[1] = alloc_entity_param(proc_scope, blank_token, t_rawptr, false);
		proc_params->Tuple.variables[2] = alloc_entity_param(proc_scope, blank_token, t_u8_ptr, false);
		proc_params->Tuple.variables[3] = alloc_entity_param(proc_scope, blank_token, t_i32,    false);

		proc_results->Tuple.variables[0] = alloc_entity_param(proc_scope, empty_token, t_i32, false);


		Type *proc_type = alloc_type_proc(a, proc_scope,
		                                 proc_params, 4,
		                                 proc_results, 1, false, ProcCC_Std);

		AstNode *body = gb_alloc_item(a, AstNode);
		Entity *e = alloc_entity_procedure(a, nullptr, make_token_ident(name), proc_type, 0);
		irValue *p = ir_value_procedure(a, m, e, proc_type, nullptr, body, name);

		m->entry_point_entity = e;

		map_set(&m->values, hash_entity(e), p);
		map_set(&m->members, hash_string(name), p);

		irProcedure *proc = &p->Proc;
		proc->tags = ProcTag_no_inline; // TODO(bill): is no_inline a good idea?
		e->Procedure.link_name = name;

		ir_begin_procedure_body(proc);
		ir_emit_global_call(proc, "main", nullptr, 0);
		ir_emit_return(proc, v_one32);
		ir_end_procedure_body(proc);
	}
#endif
	{ // Startup Runtime
		// Cleanup(bill): probably better way of doing code insertion
		String name = str_lit(IR_STARTUP_RUNTIME_PROC_NAME);
		Type *proc_type = alloc_type_proc(gb_alloc_item(a, Scope),
		                                  nullptr, 0,
		                                  nullptr, 0, false,
		                                  ProcCC_Contextless);
		AstNode *body = gb_alloc_item(a, AstNode);
		Entity *e = alloc_entity_procedure(nullptr, make_token_ident(name), proc_type, 0);
		irValue *p = ir_value_procedure(a, m, e, proc_type, nullptr, body, name);

		map_set(&m->values, hash_entity(e), p);
		map_set(&m->members, hash_string(name), p);


		irProcedure *proc = &p->Proc;
		proc->inlining = ProcInlining_no_inline; // TODO(bill): is no_inline a good idea?

		ir_begin_procedure_body(proc);
		defer (ir_end_procedure_body(proc));

		ir_emit_init_context(proc);

		ir_setup_type_info_data(proc);


		for_array(i, global_variables) {
			irGlobalVariable *var = &global_variables[i];
			if (var->decl->init_expr != nullptr)  {
				var->init = ir_build_expr(proc, var->decl->init_expr);
			}

			Entity *e = var->var->Global.entity;
			GB_ASSERT(e->kind == Entity_Variable);

			if (e->Variable.is_foreign) {
				Entity *fl = e->Procedure.foreign_library;
				ir_add_foreign_library_path(m, fl);
			}

			if (var->init != nullptr) {
				Type *t = type_deref(ir_type(var->var));

				if (is_type_any(t)) {
					// NOTE(bill): Edge case for 'any' type
					Type *var_type = default_type(ir_type(var->init));
					irValue *g = ir_add_global_generated(proc->module, var_type, var->init);
					ir_emit_store(proc, g, var->init);

					irValue *data = ir_emit_struct_ep(proc, var->var, 0);
					irValue *ti   = ir_emit_struct_ep(proc, var->var, 1);
					ir_emit_store(proc, data, ir_emit_conv(proc, g, t_rawptr));
					ir_emit_store(proc, ti,   ir_type_info(proc, var_type));
				} else {
					ir_emit_store(proc, var->var, ir_emit_conv(proc, var->init, t));
				}
			}
		}

	}

	for_array(i, m->procs_to_generate) {
		irValue *p = m->procs_to_generate[i];
		ir_build_proc(p, p->Proc.parent);
	}

	// Number debug info
	for_array(i, m->debug_info.entries) {
		auto *entry = &m->debug_info.entries[i];
		irDebugInfo *di = entry->value;
		di->id = cast(i32)(i+1);
	}


	// m->layout = str_lit("e-p:64:64:64-i1:8:8-i8:8:8-i16:16:16-i32:32:32-i64:64:64-f32:32:32-f64:64:64-v64:64:64-v128:128:128-a0:0:64-s0:64:64-f80:128:128-n8:16:32:64");
}

