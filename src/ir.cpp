struct irProcedure;
struct irBlock;
struct irValue;
struct irDebugInfo;



struct irModule {
	CheckerInfo * info;
	gbArena       tmp_arena;
	// gbAllocator   allocator;
	gbAllocator   tmp_allocator;
	bool generate_debug_info;

	u64 state_flags;

	// String source_filename;
	String layout;
	// String triple;

	PtrSet<Entity *>      min_dep_set;
	Map<irValue *>        values;              // Key: Entity *
	Map<irValue *>        members;             // Key: String
	Map<String>           entity_names;        // Key: Entity * of the typename
	Map<irDebugInfo *>    debug_info;          // Key: Unique pointer
	Map<irValue *>        anonymous_proc_lits; // Key: Ast *

	irDebugInfo *         debug_compile_unit;
	Array<irDebugInfo *>  debug_location_stack;


	i32                   global_string_index;
	i32                   global_array_index; // For ConstantSlice
	i32                   global_generated_index;

	irValue *             global_default_context;

	// NOTE(bill): To prevent strings from being copied a lot
	// Mainly used for file names
	Map<irValue *>        const_strings; // Key: String
	Map<irValue *>        const_string_byte_slices; // Key: String
	Map<irValue *>        constant_value_to_global; // Key: irValue *


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
	Ast *    node; // Can be nullptr
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
	bool          is_block;
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
	irDefer_Proc,
};

struct irDefer {
	irDeferKind kind;
	isize       scope_index;
	isize       context_stack_count;
	irBlock *   block;
	union {
		Ast *stmt;
		// NOTE(bill): 'instr' will be copied every time to create a new one
		irValue *instr;
		struct {
			irValue *deferred;
			Array<irValue *> result_as_args;
		} proc;
	};
};


struct irBranchBlocks {
	Ast *label;
	irBlock *break_;
	irBlock *continue_;
};


struct irContextData {
	irValue *value;
	isize scope_index;
};

struct irProcedure {
	irProcedure *         parent;
	Array<irProcedure *>  children;

	Entity *              entity;
	irModule *            module;
	String                name;
	Type *                type;
	Ast *                 type_expr;
	Ast *                 body;
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

	Array<irContextData>  context_stack;

	i32      parameter_count;

	irValue *return_ptr_hint_value;
	Ast *    return_ptr_hint_ast;
	bool     return_ptr_hint_used;


	Array<irBranchBlocks> branch_blocks;

	i32                   local_count;
	i32                   instr_count;
	i32                   block_count;
};


gb_global Arena global_ir_arena = {};
gbAllocator ir_allocator(void) {
	Arena *arena = &global_ir_arena;
	return arena_allocator(arena);
}


#define IR_STARTUP_RUNTIME_PROC_NAME "__$startup_runtime"
#define IR_TYPE_INFO_DATA_NAME       "__$type_info_data"
#define IR_TYPE_INFO_TYPES_NAME      "__$type_info_types_data"
#define IR_TYPE_INFO_NAMES_NAME      "__$type_info_names_data"
#define IR_TYPE_INFO_OFFSETS_NAME    "__$type_info_offsets_data"
#define IR_TYPE_INFO_USINGS_NAME     "__$type_info_usings_data"
#define IR_TYPE_INFO_TAGS_NAME       "__$type_info_tags_data"


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
	IR_INSTR_KIND(Store,    struct { irValue *address, *value; bool is_volatile; }) \
	IR_INSTR_KIND(Load,     struct { Type *type; irValue *address; i64 custom_align; }) \
	IR_INSTR_KIND(AtomicFence, struct { BuiltinProcId id; })          \
	IR_INSTR_KIND(AtomicStore, struct {                               \
		irValue *address, *value;                                     \
		BuiltinProcId id;                                             \
	})                                                                \
	IR_INSTR_KIND(AtomicLoad, struct {                                \
		Type *type; irValue *address;                                 \
		BuiltinProcId id;                                             \
	})                                                                \
	IR_INSTR_KIND(AtomicRmw, struct {                                 \
		Type *type; irValue *address;                                 \
		irValue *value;                                               \
		BuiltinProcId id;                                             \
	})                                                                \
	IR_INSTR_KIND(AtomicCxchg, struct {                               \
		Type *type; irValue *address;                                 \
		irValue *old_value; irValue *new_value;                       \
		BuiltinProcId id;                                             \
	})                                                                \
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
		ProcInlining inlining;                                        \
	})                                                                \
	IR_INSTR_KIND(StartupRuntime, i32)                                \
	IR_INSTR_KIND(DebugDeclare, struct {                              \
		Ast *        expr;                                            \
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
	IR_CONV_KIND(bitcast) \
	IR_CONV_KIND(byteswap)
/*
	Odin specifc conversion
	byteswap - swap bytes for endian change
*/


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
	irValue_SourceCodeLocation,

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
	bool          is_internal;
	String        thread_local_model;
	bool          is_foreign;
	bool          is_unnamed_addr;
};


enum irParamPasskind {
	irParamPass_Value,    // Pass by value
	irParamPass_Pointer,  // Pass as a pointer rather than by value
	irParamPass_Integer,  // Pass as an integer of the same size
	irParamPass_ConstRef, // Pass as a pointer but the value is immutable
	irParamPass_BitCast,  // Pass by value and bit cast to the correct type
	irParamPass_Tuple,    // Pass across multiple parameters (System V AMD64, up to 2)
};

struct irValueParam {
	irParamPasskind  kind;
	irProcedure *    parent;
	Entity *         entity;
	Type *           type;
	Type *           original_type;
	i32              index;
	Array<irValue *> referrers;
};

struct irValueSourceCodeLocation {
	irValue *file;
	irValue *line;
	irValue *column;
	irValue *procedure;
	u64      hash;
};


struct irValue {
	irValueKind     kind;
	i32             index;
	bool            index_set;
	irDebugInfo *   loc;
	isize           uses;
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
		irValueSourceCodeLocation SourceCodeLocation;
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
	irAddr_Context,
	irAddr_SoaVariable,
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
		struct {
			Selection sel;
		} ctx;
		struct {
			irValue *index;
			Ast *index_expr;
		} soa;
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


irAddr ir_addr_context(irValue *addr, Selection sel = empty_selection) {
	irAddr v = {irAddr_Context, addr};
	v.ctx.sel = sel;
	return v;
}


irAddr ir_addr_bit_field(irValue *addr, i32 bit_field_value_index) {
	irAddr v = {irAddr_BitField, addr};
	v.bit_field_value_index = bit_field_value_index;
	return v;
}

irAddr ir_addr_soa_variable(irValue *addr, irValue *index, Ast *index_expr) {
	irAddr v = {irAddr_SoaVariable, addr};
	v.soa.index = index;
	v.soa.index_expr = index_expr;
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

	// TODO(lachsinc): Should the following be renamed from basic -> tag to mirror their DW_TAG_*
	// counterparts? Perhaps separate out if they truly have different meaning.

	irDebugBasicEncoding_member       = 13,
	irDebugBasicEncoding_pointer_type = 15,
	irDebugBasicEncoding_typedef      = 22,

	irDebugBasicEncoding_array_type       = 1,
	irDebugBasicEncoding_enumeration_type = 4,
	irDebugBasicEncoding_structure_type   = 19,
	irDebugBasicEncoding_union_type       = 23,
};

enum irDebugInfoFlags {
	irDebugInfoFlag_Bitfield = (1 << 19),
};

enum irDebugInfoKind {
	irDebugInfo_Invalid,

	irDebugInfo_CompileUnit,
	irDebugInfo_File,
	irDebugInfo_Proc,
	irDebugInfo_ProcType,
	irDebugInfo_Location,
	irDebugInfo_LexicalBlock,
	irDebugInfo_AllProcs,

	irDebugInfo_BasicType,      // primitive types
	irDebugInfo_DerivedType,    // pointer, distinct etc.
	irDebugInfo_CompositeType,  // array, struct, enum, union etc.
	irDebugInfo_Enumerator,     // For irDebugInfo_CompositeType if enum
	irDebugInfo_GlobalVariableExpression, // used to describe if global is const or not
	irDebugInfo_GlobalVariable,
	irDebugInfo_LocalVariable,

	irDebugInfo_DebugInfoArray, // array of irDebugInfo *'s

	irDebugInfo_Count,
};

struct irDebugInfo {
	irDebugInfoKind kind;
	i32 id;

	union {
		struct {
			AstFile *    file;
			String       producer;
			irDebugInfo *enums;   // DebugInfoArray
			irDebugInfo *globals; // DebugInfoArray
		} CompileUnit;
		struct {
			AstFile *file;
			String   filename;
			String   directory;
		} File;
		struct {
			Entity *      entity;
			String        name;
			irDebugInfo * file;
			TokenPos      pos;
			irDebugInfo * type;
			// TODO(lachsinc): variables / retainedNodes ?
		} Proc;
		struct {
			irDebugInfo * types; // !{return, return, param, param, param.. etc.}
		} ProcType;
		struct {
			TokenPos     pos;
			irDebugInfo *scope;
		} Location;
		struct {
			TokenPos     pos;
			irDebugInfo *file;
			irDebugInfo *scope;
		} LexicalBlock;

		struct {
			Type *          type;
			String          name;
			i32             size;
			i32             align;
			irDebugEncoding encoding;
		} BasicType;
		struct {
			Type *           type;
			irDebugEncoding  tag;
			irDebugInfo *    base_type;
			String           name;
			irDebugInfo *    scope;
			irDebugInfo *    file;
			TokenPos         pos;
			i32              size;
			i32              align;
			i32              offset;
			irDebugInfoFlags flags; // Used only for DIFlagBitField.
		} DerivedType;
		struct {
			irDebugEncoding tag;
			String          name;
			irDebugInfo *   scope;
			irDebugInfo *   file;
			TokenPos        pos;
			irDebugInfo *   base_type; // optional, used for enumeration_type.
			i32             size;
			i32             align;
			irDebugInfo *   elements;
			i32             array_count; // for DISubrange
		} CompositeType;
		struct {
			String name;
			i64    value;
		} Enumerator;
		struct {
			irDebugInfo *var;
		} GlobalVariableExpression;
		struct {
			String       name;
			String       linkage_name;
			irDebugInfo *scope;
			irDebugInfo *file;
			TokenPos     pos;
			irDebugInfo *type;
			irValue     *variable;
		} GlobalVariable;
		struct {
			String       name;
			irDebugInfo *scope;
			irDebugInfo *file;
			TokenPos     pos;
			i32          arg; // Non-zero if proc parameter
			irDebugInfo *type;
		} LocalVariable;
		struct {
			Array<irDebugInfo *> elements; // TODO(lachsinc): Leak?
		} DebugInfoArray;
	};
};

static irDebugInfo IR_DEBUG_INFO_EMPTY = {};


struct irGen {
	irModule module;
	gbFile   output_file;
	bool     opt_called;
	String   output_base;
	String   output_name;
	bool     print_chkstk;
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
	case irInstr_AtomicLoad:
		return instr->AtomicLoad.type;
	case irInstr_AtomicRmw:
		return instr->AtomicRmw.type;
	case irInstr_AtomicCxchg:
		return instr->AtomicCxchg.type;
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
	case irValue_SourceCodeLocation:
		return t_source_code_location;
	case irValue_Proc:
		return value->Proc.type;
	case irValue_Instr:
		return ir_instr_type(&value->Instr);
	}
	return nullptr;
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
void     ir_emit_zero_init      (irProcedure *p, irValue *address, Ast *expr);
irValue *ir_emit_comment        (irProcedure *p, String text);
irValue *ir_emit_store          (irProcedure *p, irValue *address, irValue *value, bool is_volatile=false);
irValue *ir_emit_load           (irProcedure *p, irValue *address, i64 custom_align=0);
void     ir_emit_jump           (irProcedure *proc, irBlock *block);
irValue *ir_emit_conv           (irProcedure *proc, irValue *value, Type *t);
irValue *ir_type_info           (irProcedure *proc, Type *type);
irValue *ir_typeid              (irModule *m, Type *type);
irValue *ir_build_expr          (irProcedure *proc, Ast *expr);
void     ir_build_stmt          (irProcedure *proc, Ast *node);
irValue *ir_build_cond          (irProcedure *proc, Ast *cond, irBlock *true_block, irBlock *false_block);
void     ir_build_defer_stmt    (irProcedure *proc, irDefer d);
irAddr   ir_build_addr          (irProcedure *proc, Ast *expr);
void     ir_build_proc          (irValue *value, irProcedure *parent);
void     ir_gen_global_type_name(irModule *m, Entity *e, String name);
irValue *ir_get_type_info_ptr   (irProcedure *proc, Type *type);
void     ir_value_set_debug_location(irProcedure *proc, irValue *v);
void     ir_push_debug_location (irModule *m, Ast *node, irDebugInfo *scope, Entity *e=nullptr);
void     ir_pop_debug_location  (irModule *m);
irDebugInfo *ir_add_debug_info_local(irProcedure *proc, Entity *e, i32 arg_id);
irDebugInfo *ir_add_debug_info_file(irModule *module, AstFile *file);
irDebugInfo *ir_add_debug_info_proc(irProcedure *proc);
void ir_emit_increment(irProcedure *proc, irValue *addr);
irValue *ir_emit_array_ep(irProcedure *proc, irValue *s, irValue *index);
irValue *ir_emit_array_epi(irProcedure *proc, irValue *s, i32 index);
irValue *ir_emit_struct_ev(irProcedure *proc, irValue *s, i32 index);
irValue *ir_emit_bitcast(irProcedure *proc, irValue *data, Type *type);
irValue *ir_emit_byte_swap(irProcedure *proc, irValue *value, Type *t);
irValue *ir_find_or_add_entity_string(irModule *m, String str);
irValue *ir_find_or_add_entity_string_byte_slice(irModule *m, String str);



irValue *ir_alloc_value(irValueKind kind) {
	irValue *v = gb_alloc_item(ir_allocator(), irValue);
	v->kind = kind;
	return v;
}
irValue *ir_alloc_instr(irProcedure *proc, irInstrKind kind) {
	irValue *v = ir_alloc_value(irValue_Instr);
	v->Instr.kind = kind;
	proc->instr_count++;
	return v;
}
irDebugInfo *ir_alloc_debug_info(irDebugInfoKind kind) {
	irDebugInfo *di = gb_alloc_item(ir_allocator(), irDebugInfo);
	di->kind = kind;
	return di;
}




irValue *ir_value_type_name(String name, Type *type) {
	irValue *v = ir_alloc_value(irValue_TypeName);
	v->TypeName.name = name;
	v->TypeName.type = type;
	return v;
}

irValue *ir_value_global(Entity *e, irValue *value) {
	irValue *v = ir_alloc_value(irValue_Global);
	v->Global.entity = e;
	v->Global.type = alloc_type_pointer(e->type);
	v->Global.value = value;
	array_init(&v->Global.referrers, ir_allocator()); // TODO(bill): Replace heap allocator here

	if (value) value->uses += 1;
	return v;
}
irValue *ir_value_param(irProcedure *parent, Entity *e, Type *abi_type, i32 index) {
	irValue *v = ir_alloc_value(irValue_Param);
	v->Param.kind          = irParamPass_Value;
	v->Param.parent        = parent;
	if (e != nullptr) {
		v->Param.entity        = e;
		v->Param.original_type = e->type;
	}
	v->Param.type          = abi_type;
	v->Param.index         = index;

	if (e != nullptr && abi_type != e->type) {
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
		} else if (is_type_simd_vector(abi_type)) {
			v->Param.kind = irParamPass_BitCast;
		} else if (is_type_float(abi_type)) {
			v->Param.kind = irParamPass_BitCast;
		} else if (is_type_tuple(abi_type)) {
			v->Param.kind = irParamPass_Tuple;
		} else {
			GB_PANIC("Invalid abi type pass kind %s", type_to_string(abi_type));
		}
	}
	array_init(&v->Param.referrers, heap_allocator()); // TODO(bill): Replace heap allocator here
	return v;
}
irValue *ir_value_nil(Type *type) {
	irValue *v = ir_alloc_value(irValue_Nil);
	v->Nil.type = type;
	return v;
}

irValue *ir_value_undef(Type *type) {
	irValue *v = ir_alloc_value(irValue_Undef);
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

	if (address) address->uses += 1;
	return v;
}

irValue *ir_instr_store(irProcedure *p, irValue *address, irValue *value, bool is_volatile) {
	irValue *v = ir_alloc_instr(p, irInstr_Store);
	irInstr *i = &v->Instr;
	i->Store.address = address;
	i->Store.value = value;
	i->Store.is_volatile = is_volatile;

	if (address) address->uses += 1;
	if (value) value->uses += 1;
	return v;
}

irValue *ir_instr_load(irProcedure *p, irValue *address) {
	irValue *v = ir_alloc_instr(p, irInstr_Load);
	irInstr *i = &v->Instr;
	i->Load.address = address;
	i->Load.type = type_deref(ir_type(address));

	if (address) address->uses += 1;

	return v;
}

irValue *ir_instr_atomic_fence(irProcedure *p, BuiltinProcId id) {
	irValue *v = ir_alloc_instr(p, irInstr_AtomicFence);
	irInstr *i = &v->Instr;
	i->AtomicFence.id = id;
	return v;
}

irValue *ir_instr_atomic_store(irProcedure *p, irValue *address, irValue *value, BuiltinProcId id) {
	irValue *v = ir_alloc_instr(p, irInstr_AtomicStore);
	irInstr *i = &v->Instr;
	i->AtomicStore.address = address;
	i->AtomicStore.value = value;
	i->AtomicStore.id = id;

	if (address) address->uses += 1;
	if (value) value->uses += 1;

	return v;
}

irValue *ir_instr_atomic_load(irProcedure *p, irValue *address, BuiltinProcId id) {
	irValue *v = ir_alloc_instr(p, irInstr_AtomicLoad);
	irInstr *i = &v->Instr;
	i->AtomicLoad.address = address;
	i->AtomicLoad.type = type_deref(ir_type(address));
	i->AtomicLoad.id = id;

	if (address) address->uses += 1;

	return v;
}

irValue *ir_instr_atomic_rmw(irProcedure *p, irValue *address, irValue *value, BuiltinProcId id) {
	irValue *v = ir_alloc_instr(p, irInstr_AtomicRmw);
	irInstr *i = &v->Instr;
	i->AtomicRmw.type = type_deref(ir_type(address));
	i->AtomicRmw.address = address;
	i->AtomicRmw.value = value;
	i->AtomicRmw.id = id;

	if (address) address->uses += 1;
	if (value) value->uses += 1;

	return v;
}


irValue *ir_instr_atomic_cxchg(irProcedure *p, Type *type, irValue *address, irValue *old_value, irValue *new_value, BuiltinProcId id) {
	irValue *v = ir_alloc_instr(p, irInstr_AtomicCxchg);
	irInstr *i = &v->Instr;


	if (type->kind == Type_Tuple) {
		GB_ASSERT(type->Tuple.variables.count == 2);
		Type *elem = type->Tuple.variables[0]->type;
		// LEAK TODO(bill): LLVM returns {T, i1} whilst Odin does {T, bool}, fix this mapping hack
		gbAllocator a = heap_allocator();
		Type *llvm_type = alloc_type_tuple();
		array_init(&llvm_type->Tuple.variables, a, 0, 2);
		array_add (&llvm_type->Tuple.variables, alloc_entity_field(nullptr, blank_token, elem, false, 0));
		array_add (&llvm_type->Tuple.variables, alloc_entity_field(nullptr, blank_token, t_llvm_bool, false, 1));

		type = llvm_type;
	}
	i->AtomicCxchg.type = type;

	i->AtomicCxchg.address = address;
	i->AtomicCxchg.old_value = old_value;
	i->AtomicCxchg.new_value = new_value;
	i->AtomicCxchg.id = id;


	if (address) address->uses += 1;
	if (old_value) old_value->uses += 1;
	if (new_value) new_value->uses += 1;

	return v;
}

irValue *ir_instr_array_element_ptr(irProcedure *p, irValue *address, irValue *elem_index) {
	irValue *v = ir_alloc_instr(p, irInstr_ArrayElementPtr);
	irInstr *i = &v->Instr;
	Type *t = ir_type(address);
	GB_ASSERT_MSG(is_type_pointer(t), "%s", type_to_string(t));
	t = base_type(type_deref(t));
	GB_ASSERT(is_type_array(t) || is_type_enumerated_array(t));

	Type *result_type = nullptr;
	if (t->kind == Type_Array) {
		result_type = alloc_type_pointer(t->Array.elem);
	} else if (t->kind == Type_EnumeratedArray) {
		result_type = alloc_type_pointer(t->EnumeratedArray.elem);
	}

	i->ArrayElementPtr.address = address;
	i->ArrayElementPtr.elem_index = elem_index;
	i->ArrayElementPtr.result_type = result_type;

	if (address) address->uses += 1;
	if (elem_index) elem_index->uses += 1;

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

	if (address) address->uses += 1;

	GB_ASSERT_MSG(is_type_pointer(ir_type(address)),
	              "%s", type_to_string(ir_type(address)));
	return v;
}
irValue *ir_instr_ptr_offset(irProcedure *p, irValue *address, irValue *offset) {
	irValue *v = ir_alloc_instr(p, irInstr_PtrOffset);
	irInstr *i = &v->Instr;
	i->PtrOffset.address = address;
	i->PtrOffset.offset  = offset;

	if (address) address->uses += 1;
	if (offset) offset->uses += 1;


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

	if (address) address->uses += 1;

	return v;
}

irValue *ir_instr_union_tag_ptr(irProcedure *p, irValue *address) {
	irValue *v = ir_alloc_instr(p, irInstr_UnionTagPtr);
	irInstr *i = &v->Instr;
	i->UnionTagPtr.address = address;

	if (address) address->uses += 1;

	// i->UnionTagPtr.type = alloc_type_pointer(t_type_info_ptr);
	Type *u = type_deref(ir_type(address));
	if (is_type_union_maybe_pointer(u)) {
		GB_PANIC("union #maybe UnionTagPtr");
	}
	i->UnionTagPtr.type = alloc_type_pointer(union_tag_type(u));

	return v;
}

irValue *ir_instr_union_tag_value(irProcedure *p, irValue *address) {
	irValue *v = ir_alloc_instr(p, irInstr_UnionTagValue);
	irInstr *i = &v->Instr;
	i->UnionTagValue.address = address;

	if (address) address->uses += 1;

	Type *u = type_deref(ir_type(address));
	if (is_type_union_maybe_pointer(u)) {
		GB_PANIC("union #maybe UnionTagValue");
	}
	i->UnionTagPtr.type = union_tag_type(u);
	return v;
}

irValue *ir_instr_unary_op(irProcedure *p, TokenKind op, irValue *expr, Type *type) {
	irValue *v = ir_alloc_instr(p, irInstr_UnaryOp);
	irInstr *i = &v->Instr;
	i->UnaryOp.op = op;
	i->UnaryOp.expr = expr;
	i->UnaryOp.type = type;

	if (expr) expr->uses += 1;
	return v;
}


irValue *ir_instr_binary_op(irProcedure *p, TokenKind op, irValue *left, irValue *right, Type *type) {
	irValue *v = ir_alloc_instr(p, irInstr_BinaryOp);
	irInstr *i = &v->Instr;
	i->BinaryOp.op = op;
	i->BinaryOp.left = left;
	i->BinaryOp.right = right;
	i->BinaryOp.type = type;

	if (left) left->uses += 1;
	if (right) right->uses += 1;

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

	for_array(j, edges) {
		if (edges[j]) edges[j]->uses += 1;
	}
	return v;
}

irValue *ir_instr_unreachable(irProcedure *p) {
	irValue *v = ir_alloc_instr(p, irInstr_Unreachable);
	return v;
}

irValue *ir_instr_return(irProcedure *p, irValue *value) {
	irValue *v = ir_alloc_instr(p, irInstr_Return);
	v->Instr.Return.value = value;

	if (value) value->uses += 1;

	return v;
}

irValue *ir_instr_select(irProcedure *p, irValue *cond, irValue *t, irValue *f) {
	irValue *v = ir_alloc_instr(p, irInstr_Select);
	v->Instr.Select.cond = cond;
	v->Instr.Select.true_value = t;
	v->Instr.Select.false_value = f;

	if (cond) cond->uses += 1;
	if (t) t->uses += 1;
	if (f) f->uses += 1;

	return v;
}

irValue *ir_instr_call(irProcedure *p, irValue *value, irValue *return_ptr, Array<irValue *> args, Type *result_type, irValue *context_ptr, ProcInlining inlining) {
	irValue *v = ir_alloc_instr(p, irInstr_Call);
	v->Instr.Call.value       = value;
	v->Instr.Call.return_ptr  = return_ptr;
	v->Instr.Call.args        = args;
	v->Instr.Call.type        = result_type;
	v->Instr.Call.context_ptr = context_ptr;
	v->Instr.Call.inlining    = inlining;

	if (value) value->uses += 1;
	if (return_ptr) return_ptr->uses += 1;
	for_array(i, args) {
		if (args[i]) args[i]->uses += 1;
	}
	if (context_ptr) context_ptr->uses += 1;

	return v;
}

irValue *ir_instr_conv(irProcedure *p, irConvKind kind, irValue *value, Type *from, Type *to) {
	irValue *v = ir_alloc_instr(p, irInstr_Conv);
	v->Instr.Conv.kind  = kind;
	v->Instr.Conv.value = value;
	v->Instr.Conv.from  = from;
	v->Instr.Conv.to    = to;

	if (value) value->uses += 1;

	return v;
}

irValue *ir_instr_comment(irProcedure *p, String text) {
	irValue *v = ir_alloc_instr(p, irInstr_Comment);
	v->Instr.Comment.text = text;
	return v;
}

irValue *ir_instr_debug_declare(irProcedure *p, Ast *expr, Entity *entity, bool is_addr, irValue *value) {
	irValue *v = ir_alloc_instr(p, irInstr_DebugDeclare);
	v->Instr.DebugDeclare.expr       = expr;
	v->Instr.DebugDeclare.entity     = entity;
	v->Instr.DebugDeclare.is_addr    = is_addr;
	v->Instr.DebugDeclare.value      = value;

	if (value) value->uses += 1;

	return v;
}



irValue *ir_value_constant(Type *type, ExactValue value) {
	irValue *v = ir_alloc_value(irValue_Constant);
	v->Constant.type  = type;
	v->Constant.value = value;
	return v;
}


irValue *ir_value_constant_slice(Type *type, irValue *backing_array, i64 count) {
	irValue *v = ir_alloc_value(irValue_ConstantSlice);
	v->ConstantSlice.type = type;
	v->ConstantSlice.backing_array = backing_array;
	v->ConstantSlice.count = count;

	if (backing_array) backing_array->uses += 1;

	return v;
}


irValue *ir_emit(irProcedure *proc, irValue *instr) {
	GB_ASSERT(instr->kind == irValue_Instr);
	irModule *m = proc->module;
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
	if (m->generate_debug_info) {
		ir_value_set_debug_location(proc, instr);
	}
	return instr;
}

irValue *ir_de_emit(irProcedure *proc, irValue *instr) {
	GB_ASSERT(instr->kind == irValue_Instr);
	irModule *m = proc->module;
	irBlock *b = proc->curr_block;
	GB_ASSERT(b != nullptr);
	irInstr *i = ir_get_last_instr(b);
	GB_ASSERT(i == &instr->Instr);
	array_pop(&b->instrs);
	return instr;
}

irValue *ir_const_int(i64 i) {
	return ir_value_constant(t_int, exact_value_i64(i));
}
irValue *ir_const_uintptr(u64 i) {
	return ir_value_constant(t_uintptr, exact_value_i64(i));
}
irValue *ir_const_u8(u32 i) {
	return ir_value_constant(t_u8, exact_value_i64(i));
}
irValue *ir_const_i32(i32 i) {
	return ir_value_constant(t_i32, exact_value_i64(i));
}
irValue *ir_const_u32(u32 i) {
	return ir_value_constant(t_u32, exact_value_i64(i));
}
irValue *ir_const_i64(i64 i) {
	return ir_value_constant(t_i64, exact_value_i64(i));
}
irValue *ir_const_u64(u64 i) {
	return ir_value_constant(t_u64, exact_value_i64(i));
}
irValue *ir_const_f32(f32 f) {
	return ir_value_constant(t_f32, exact_value_float(f));
}
irValue *ir_const_f64(f64 f) {
	return ir_value_constant(t_f64, exact_value_float(f));
}
irValue *ir_const_bool(bool b) {
	return ir_value_constant(t_bool, exact_value_bool(b != 0));
}
irValue *ir_const_string(irModule *m, String s) {
	return ir_find_or_add_entity_string(m, s);
	// return ir_value_constant(t_string, exact_value_string(s));
}

irValue *ir_value_procedure(irModule *m, Entity *entity, Type *type, Ast *type_expr, Ast *body, String name) {
	irValue *v = ir_alloc_value(irValue_Proc);
	v->Proc.module = m;
	v->Proc.entity = entity;
	v->Proc.type   = type;
	v->Proc.type_expr = type_expr;
	v->Proc.body   = body;
	v->Proc.name   = name;
	array_init(&v->Proc.referrers, heap_allocator());

	Type *t = base_type(type);
	GB_ASSERT(is_type_proc(t));
	array_init(&v->Proc.params, heap_allocator(), 0, t->Proc.param_count);

	return v;
}


irValue *ir_generate_array(irModule *m, Type *elem_type, i64 count, String prefix, i64 id) {
	gbAllocator a = ir_allocator();
	Token token = {Token_Ident};
	isize name_len = prefix.len + 1 + 20;

	auto suffix_id = cast(unsigned long long)id;
	char *text = gb_alloc_array(a, char, name_len+1);
	gb_snprintf(text, name_len,
	            "%.*s-%llu", LIT(prefix), suffix_id);
	text[name_len] = 0;

	String s = make_string_c(text);

	Entity *e = alloc_entity_variable(nullptr, make_token_ident(s), alloc_type_array(elem_type, count));
	irValue *value = ir_value_global(e, nullptr);
	value->Global.is_private = true;
	ir_module_add_value(m, e, value);
	map_set(&m->members, hash_string(s), value);
	return value;
}

irBlock *ir_new_block(irProcedure *proc, Ast *node, char const *label) {
	Scope *scope = nullptr;
	if (node != nullptr) {
		scope = scope_of_node(node);
		GB_ASSERT_MSG(scope != nullptr, "Block scope not found for %.*s", LIT(ast_strings[node->kind]));
	}

	irValue *v = ir_alloc_value(irValue_Block);
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


irValue *ir_emit_transmute(irProcedure *proc, irValue *value, Type *t);
irValue *ir_address_from_load_or_generate_local(irProcedure *proc, irValue *val);
irValue *ir_emit_struct_ep(irProcedure *proc, irValue *s, i32 index);




irDefer ir_add_defer_node(irProcedure *proc, isize scope_index, Ast *stmt) {
	irDefer d = {irDefer_Node};
	d.scope_index = scope_index;
	d.context_stack_count = proc->context_stack.count;
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

irDefer ir_add_defer_proc(irProcedure *proc, isize scope_index, irValue *deferred, Array<irValue *> const &result_as_args) {
	irDefer d = {irDefer_Proc};
	d.scope_index = proc->scope_index;
	d.block = proc->curr_block;
	d.proc.deferred = deferred;
	d.proc.result_as_args = result_as_args;
	array_add(&proc->defer_stmts, d);
	return d;
}




irValue *ir_add_module_constant(irModule *m, Type *type, ExactValue value) {
	gbAllocator a = ir_allocator();

	if (is_type_slice(type)) {
		if (value.kind == ExactValue_String) {
			GB_ASSERT(is_type_u8_slice(type));
			return ir_find_or_add_entity_string_byte_slice(m, value.value_string);
		} else {
			ast_node(cl, CompoundLit, value.value_compound);

			isize count = cl->elems.count;
			if (count == 0) {
				return ir_value_nil(type);
			}
			count = gb_max(cl->max_count, count);
			Type *elem = base_type(type)->Slice.elem;
			Type *t = alloc_type_array(elem, count);
			irValue *backing_array = ir_add_module_constant(m, t, value);


			isize max_len = 7+8+1;
			u8 *str = cast(u8 *)gb_alloc_array(a, u8, max_len);
			isize len = gb_snprintf(cast(char *)str, max_len, "csba$%x", m->global_array_index);
			m->global_array_index++;

			String name = make_string(str, len-1);

			Entity *e = alloc_entity_constant(nullptr, make_token_ident(name), t, value);
			irValue *g = ir_value_global(e, backing_array);
			ir_module_add_value(m, e, g);
			map_set(&m->members, hash_string(name), g);

			return ir_value_constant_slice(type, g, count);
		}
	}

	return ir_value_constant(type, value);
}

irValue *ir_add_global_string_array(irModule *m, String string) {

	irValue *global_constant_value = nullptr;
	{
		HashKey key = hash_string(string);
		irValue **found = map_get(&m->const_string_byte_slices, key);
		if (found != nullptr) {
			global_constant_value = *found;

			irValue **global_found = map_get(&m->constant_value_to_global, hash_pointer(global_constant_value));
			if (global_found != nullptr) {
				return *global_found;
			}
		}
	}

	if (global_constant_value == nullptr) {
		global_constant_value = ir_find_or_add_entity_string_byte_slice(m, string);
	}
	Type *type = alloc_type_array(t_u8, string.len+1);


	isize max_len = 6+8+1;
	u8 *str = cast(u8 *)gb_alloc_array(ir_allocator(), u8, max_len);
	isize len = gb_snprintf(cast(char *)str, max_len, "str$%x", m->global_string_index);
	m->global_string_index++;

	String name = make_string(str, len-1);
	Token token = {Token_String};
	token.string = name;

	Entity *entity = alloc_entity_constant(nullptr, token, type, exact_value_string(string));

	irValue *g = ir_value_global(entity, global_constant_value);
	g->Global.is_private      = true;
	g->Global.is_unnamed_addr = true;
	g->Global.is_constant = true;

	map_set(&m->constant_value_to_global, hash_pointer(global_constant_value), g);


	ir_module_add_value(m, entity, g);
	map_set(&m->members, hash_string(name), g);

	return g;
}

void ir_add_foreign_library_path(irModule *m, Entity *e) {
	if (e == nullptr) {
		return;
	}
	GB_ASSERT(e->kind == Entity_LibraryName);
	GB_ASSERT(e->flags & EntityFlag_Used);

	for_array(i, e->LibraryName.paths) {
		String library_path = e->LibraryName.paths[i];
		if (library_path.len == 0) {
			continue;
		}

		bool ok = true;
		for_array(path_index, m->foreign_library_paths) {
			String path = m->foreign_library_paths[path_index];
	#if defined(GB_SYSTEM_WINDOWS)
			if (str_eq_ignore_case(path, library_path)) {
	#else
			if (str_eq(path, library_path)) {
	#endif
				ok = false;
				break;
			}
		}

		if (ok) {
			array_add(&m->foreign_library_paths, library_path);
		}
	}
}



void ir_push_context_onto_stack(irProcedure *proc, irValue *ctx) {
	irContextData cd = {ctx, proc->scope_index};
	array_add(&proc->context_stack, cd);
}

irValue *ir_add_local(irProcedure *proc, Entity *e, Ast *expr, bool zero_initialized, i32 param_index = 0) {
	irBlock *b = proc->decl_block; // all variables must be in the first block
	irValue *instr = ir_instr_local(proc, e, true);
	instr->Instr.block = b;
	array_add(&b->instrs, instr);
	array_add(&b->locals, instr);
	proc->local_count++;

	if (zero_initialized) {
		ir_emit_zero_init(proc, instr, expr);
	}
	set_procedure_abi_types(heap_allocator(), e->type);

	// if (proc->module->generate_debug_info && expr != nullptr && proc->entity != nullptr) {
	// if (proc->module->generate_debug_info && proc->entity != nullptr) {
	if (proc->module->generate_debug_info) {
		// GB_ASSERT_NOT_NULL(proc->debug_scope);
		if (expr != nullptr) {
			ir_emit(proc, ir_instr_debug_declare(proc, expr, e, true, instr));
		}
		if (e->scope != nullptr && proc->debug_scope != nullptr) {
			irDebugInfo *di_local = ir_add_debug_info_local(proc, e, param_index);
		}
	}

	return instr;
}

irValue *ir_add_local_for_identifier(irProcedure *proc, Ast *ident, bool zero_initialized) {
	Entity *e = entity_of_ident(ident);
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
				irValue *g = ir_value_global(e, nullptr);
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

irValue *ir_add_local_generated(irProcedure *proc, Type *type, bool zero_initialized) {
	GB_ASSERT(type != nullptr);
	type = default_type(type);

	Scope *scope = nullptr;
	if (proc->curr_block) {
		scope = proc->curr_block->scope;
	}
	Entity *e = alloc_entity_variable(scope, empty_token, type);
	return ir_add_local(proc, e, nullptr, zero_initialized);
}


irValue *ir_add_global_generated(irModule *m, Type *type, irValue *value) {
	GB_ASSERT(type != nullptr);
	type = default_type(type);

	isize max_len = 7+8+1;
	u8 *str = cast(u8 *)gb_alloc_array(ir_allocator(), u8, max_len);
	isize len = gb_snprintf(cast(char *)str, max_len, "ggv$%x", m->global_generated_index);
	m->global_generated_index++;
	String name = make_string(str, len-1);

	Scope *scope = nullptr;
	Entity *e = alloc_entity_variable(scope, make_token_ident(name), type);
	irValue *g = ir_value_global(e, value);
	ir_module_add_value(m, e, g);
	map_set(&m->members, hash_string(name), g);
	return g;
}


irValue *ir_add_param(irProcedure *proc, Entity *e, Ast *expr, Type *abi_type, i32 index) {
	irValue *v = ir_value_param(proc, e, abi_type, index);
	array_add(&proc->params, v);
	irValueParam *p = &v->Param;

	irValue *res = nullptr;

	ir_push_debug_location(proc->module, e ? e->identifier : nullptr, proc->debug_scope, e);
	defer (ir_pop_debug_location(proc->module));

	switch (p->kind) {
	case irParamPass_Value: {
		irValue *l = ir_add_local(proc, e, expr, false, index);
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
		irValue *l = ir_add_local(proc, e, expr, false, index);
		irValue *iptr = ir_emit_conv(proc, l, alloc_type_pointer(p->type));
		ir_emit_store(proc, iptr, v);
		return ir_emit_load(proc, l);
	}

	case irParamPass_ConstRef:
		ir_module_add_value(proc->module, e, v);
		return ir_emit_load(proc, v);

	case irParamPass_BitCast: {
		irValue *l = ir_add_local(proc, e, expr, false, index);
		irValue *x = ir_emit_transmute(proc, v, e->type);
		ir_emit_store(proc, l, x);
		return x;
	}
	case irParamPass_Tuple: {
		irValue *l = ir_add_local(proc, e, expr, true, index);
		Type *st = struct_type_from_systemv_distribute_struct_fields(abi_type);
		irValue *ptr = ir_emit_transmute(proc, l, alloc_type_pointer(st));
		if (abi_type->Tuple.variables.count > 0) {
			array_pop(&proc->params);
		}
		for_array(i, abi_type->Tuple.variables) {
			Type *t = abi_type->Tuple.variables[i]->type;

			irValue *elem = ir_value_param(proc, nullptr, t, index+cast(i32)i);
			array_add(&proc->params, elem);

			irValue *dst = ir_emit_struct_ep(proc, ptr, cast(i32)i);
			ir_emit_store(proc, dst, elem);
		}
		return ir_emit_load(proc, l);
	}

	}

	GB_PANIC("Unreachable");
	return nullptr;
}



////////////////////////////////////////////////////////////////
//
// @Debug
//
////////////////////////////////////////////////////////////////

irDebugInfo *ir_add_debug_info_type(irModule *module, Type *type, Entity *e, irDebugInfo *scope, irDebugInfo *file);

irDebugInfo *ir_add_debug_info_array(irModule *module, isize count, isize capacity) {
	irDebugInfo *di = ir_alloc_debug_info(irDebugInfo_DebugInfoArray);
	array_init(&di->DebugInfoArray.elements, ir_allocator(), count, capacity);
	map_set(&module->debug_info, hash_pointer(di), di);
	return di;
}

irDebugInfo *ir_add_debug_info_file(irModule *module, AstFile *file) {
	// if (!proc->module->generate_debug_info) {
	// 	return nullptr;
	// }

	irDebugInfo **existing = map_get(&module->debug_info, hash_ast_file(file));
	if (existing != nullptr) {
		GB_ASSERT((*existing)->kind == irDebugInfo_File);
		return *existing;
	}

	GB_ASSERT(file != nullptr);
	irDebugInfo *di = ir_alloc_debug_info(irDebugInfo_File);
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

	map_set(&module->debug_info, hash_ast_file(file), di);
	return di;
}

irDebugEncoding ir_debug_encoding_for_basic(BasicKind kind) {
	switch (kind) {
	case Basic_llvm_bool:
	case Basic_bool:
	case Basic_b8:
	case Basic_b16:
	case Basic_b32:
	case Basic_b64:
		return irDebugBasicEncoding_boolean;

	case Basic_i8:
		return irDebugBasicEncoding_signed_char;

	case Basic_u8:
		return irDebugBasicEncoding_unsigned_char;


	case Basic_i16:
	case Basic_i32:
	case Basic_i64:
	case Basic_i128:
	case Basic_i16le:
	case Basic_i32le:
	case Basic_i64le:
	case Basic_i128le:
	case Basic_i16be:
	case Basic_i32be:
	case Basic_i64be:
	case Basic_i128be:
	case Basic_int:
	case Basic_rune:
	case Basic_typeid:
		return irDebugBasicEncoding_signed;

	case Basic_u16:
	case Basic_u32:
	case Basic_u64:
	case Basic_u128:
	case Basic_u16le:
	case Basic_u32le:
	case Basic_u64le:
	case Basic_u128le:
	case Basic_u16be:
	case Basic_u32be:
	case Basic_u64be:
	case Basic_u128be:
	case Basic_uint:
	case Basic_uintptr:
		return irDebugBasicEncoding_unsigned;

	// case Basic_f16:
	case Basic_f32:
	case Basic_f64:
		return irDebugBasicEncoding_float;

	// case Basic_complex32:
	case Basic_complex64:
	case Basic_complex128:
	case Basic_cstring:
	case Basic_string:
	case Basic_any:
	case Basic_rawptr:
	case Basic_quaternion128:
	case Basic_quaternion256:
		break; // not a "DIBasicType"
	}

	GB_PANIC("Unreachable %d", kind);
	return irDebugBasicEncoding_Invalid;
}

i32 ir_debug_info_bits(i64 size) {
	return 8*cast(i32)size;
}

i32 ir_debug_size_bits(Type *type) {
	return ir_debug_info_bits(type_size_of(type));
}

i32 ir_debug_align_bits(Type *type) {
	return ir_debug_info_bits(type_align_of(type));
}

irDebugInfo *ir_add_debug_info_field_internal(irModule *module, String name, Type *type, i32 offset_bits, Entity *e, irDebugInfo *scope) {
	// NOTE(lachsinc): Caller is expected to insert the returned value into map themselves.
	// "scope", if set, should be inserted into map prior to calling to ensure no cyclical dependency issues.

	irDebugInfo *di = ir_alloc_debug_info(irDebugInfo_DerivedType);
	// GB_ASSERT_MSG(name.len > 0, "%s", type_to_string(type));
	di->DerivedType.name = name;
	di->DerivedType.tag = irDebugBasicEncoding_member;
	di->DerivedType.size = ir_debug_size_bits(type);
	di->DerivedType.offset = offset_bits;
	di->DerivedType.scope = scope;

	// NOTE(lachsinc): It is "safe" to overwrite this base_type after a call to this function,
	// if you need to set a specific type for this field.
	di->DerivedType.base_type = ir_add_debug_info_type(module, type, e, scope, nullptr);
	GB_ASSERT_NOT_NULL(di->DerivedType.base_type);
	return di;
}

irDebugInfo *ir_add_debug_info_field(irModule *module, irDebugInfo *scope, Entity *e, Type *scope_type, i32 index, Type *type, irDebugInfo *file) {
	// NOTE(lachsinc): This lookup will only work for struct fields!!
	if (e) {
		irDebugInfo **existing = map_get(&module->debug_info, hash_entity(e));
		if (existing != nullptr) {
			return *existing;
		}
	}

	irDebugInfo *di = ir_add_debug_info_field_internal(module, make_string(nullptr, 0), type, 0, e, scope);
	void *ptr_to_hash = nullptr;
	if (scope_type) {
		Type *scope_base = base_type(scope_type);
		if (is_type_struct(scope_type) || is_type_tuple(scope_type)) {
			if (is_type_struct(scope_type) && scope_base->Struct.are_offsets_set) {
				di->DerivedType.offset = ir_debug_info_bits(scope_base->Struct.offsets[index]);
			} else if (is_type_tuple(scope_type) && scope_base->Tuple.are_offsets_set) {
				di->DerivedType.offset = ir_debug_info_bits(scope_base->Tuple.offsets[index]);
			} else {
				di->DerivedType.offset = ir_debug_info_bits(type_offset_of(scope_base, index));
			}
			if (e) {
				ptr_to_hash = e;
				di->DerivedType.name = e->token.string;
				if (e->token.string.len == 0) {
					// If no name available for field, use its field index as its name.
					isize max_len = 8;
					u8 *str = cast(u8 *)gb_alloc_array(heap_allocator(), u8, max_len);
					isize len = gb_snprintf(cast(char *)str, 8, "%d", index);
					di->DerivedType.name = make_string(str, len-1);
				}
				di->DerivedType.pos = e->token.pos;
			} else {
				GB_PANIC("Unreachable"); // struct field Entity's should be provided.
			}
		} else if (is_type_union(scope_base)) {
			// TODO(lachsinc): Handle this in a more generic manner/pass in??...
			// Token token = base_type(scope_base)->Union.node->UnionType.token;
			// di->DerivedType.name = token.string;
			// di->DerivedType.pos = token.pos;
			if (is_type_named(type)) {
				di->DerivedType.name = type->kind == Type_Named ? type->Named.name : type->Basic.name;
			}
			ptr_to_hash = di;
		}
	}

	di->DerivedType.file = file;

	GB_ASSERT_NOT_NULL(ptr_to_hash);
	map_set(&module->debug_info, hash_pointer(ptr_to_hash), di);

	return di;
}

irDebugInfo *ir_add_debug_info_enumerator(irModule *module, Entity *e) {
	irDebugInfo **existing = map_get(&module->debug_info, hash_entity(e));
	if (existing != nullptr) {
		return *existing;
	}

	irDebugInfo *di = ir_alloc_debug_info(irDebugInfo_Enumerator);
	di->Enumerator.name = e->token.string;
	GB_ASSERT(e->kind == Entity_Constant);
	GB_ASSERT(e->Constant.value.kind == ExactValue_Integer);
	di->Enumerator.value = big_int_to_i64(&e->Constant.value.value_integer);

	map_set(&module->debug_info, hash_entity(e), di);
	return di;
}

irDebugInfo *ir_add_debug_info_type_dynamic_array(irModule *module, Type *type, Entity *e, irDebugInfo *scope, irDebugInfo *file) {
	GB_ASSERT(type->kind == Type_DynamicArray);

	irDebugInfo *di = ir_alloc_debug_info(irDebugInfo_CompositeType);
	di->CompositeType.name = str_lit("dynamic_array"); // TODO(lachsinc): [dynamic] .. type->DynamicArray.elem name
	di->CompositeType.tag = irDebugBasicEncoding_structure_type;
	di->CompositeType.size = ir_debug_size_bits(t_rawptr) +
	                         ir_debug_size_bits(t_int) +
	                         ir_debug_size_bits(t_int) +
	                         ir_debug_size_bits(t_allocator);
	di->CompositeType.align = ir_debug_align_bits(t_rawptr);
	map_set(&module->debug_info, hash_type(type), di);

	// Data pointer type
	// TODO(lachsinc): Perhaps lookup/alloc-a-fake Type_Pointer type and go via ir_add_debug_info_type() with it.
	irDebugInfo *data_ptr_di = ir_alloc_debug_info(irDebugInfo_DerivedType);
	data_ptr_di->DerivedType.tag = irDebugBasicEncoding_pointer_type;
	data_ptr_di->DerivedType.size = ir_debug_size_bits(t_rawptr);
	map_set(&module->debug_info, hash_pointer(data_ptr_di), data_ptr_di);
	data_ptr_di->DerivedType.base_type = ir_add_debug_info_type(module, type->DynamicArray.elem, e, scope, file);

	irDebugInfo *data_di = ir_add_debug_info_field_internal(module, str_lit("data"), t_rawptr,
	                                                        0,
	                                                        nullptr,
	                                                        di);
	data_di->DerivedType.base_type = data_ptr_di;
	map_set(&module->debug_info, hash_pointer(data_di), data_di);

	irDebugInfo *len_di = ir_add_debug_info_field_internal(module, str_lit("len"), t_int,
	                                                       data_di->DerivedType.size,
	                                                       nullptr,
	                                                       di);
	map_set(&module->debug_info, hash_pointer(len_di), len_di);

	irDebugInfo *cap_di = ir_add_debug_info_field_internal(module, str_lit("cap"), t_int,
	                                                       data_di->DerivedType.size +
	                                                       len_di->DerivedType.size,
	                                                       nullptr,
	                                                       di);
	map_set(&module->debug_info, hash_pointer(cap_di), cap_di);

	irDebugInfo *alloc_di = ir_add_debug_info_field_internal(module, str_lit("allocator"), t_allocator,
	                                                         data_di->DerivedType.size +
	                                                         len_di->DerivedType.size +
	                                                         cap_di->DerivedType.size,
	                                                         nullptr,
	                                                         di);
	map_set(&module->debug_info, hash_pointer(alloc_di), alloc_di);

	irDebugInfo *elements_di = ir_add_debug_info_array(module, 0, 4);
	array_add(&elements_di->DebugInfoArray.elements, data_di);
	array_add(&elements_di->DebugInfoArray.elements, len_di);
	array_add(&elements_di->DebugInfoArray.elements, cap_di);
	array_add(&elements_di->DebugInfoArray.elements, alloc_di);
	di->CompositeType.elements = elements_di;
	map_set(&module->debug_info, hash_pointer(elements_di), elements_di);

	return di;
}

irDebugInfo *ir_add_debug_info_type_bit_field(irModule *module, Type *type, Entity *e, irDebugInfo *scope) {
	GB_ASSERT(type->kind == Type_BitField || (type->kind == Type_Named && type->Named.base->kind == Type_BitField));

	Type *bf_type = base_type(type);

	irDebugInfo *di = ir_alloc_debug_info(irDebugInfo_CompositeType);
	di->CompositeType.name = is_type_named(type) ? type->Named.name : str_lit("bit_field");
	di->CompositeType.tag = irDebugBasicEncoding_structure_type;
	di->CompositeType.size = ir_debug_size_bits(bf_type);
	map_set(&module->debug_info, hash_type(type), di);

	GB_ASSERT(bf_type->BitField.fields.count == bf_type->BitField.offsets.count &&
	          bf_type->BitField.fields.count == bf_type->BitField.sizes.count);

	irDebugInfo *elements_di = ir_add_debug_info_array(module, 0, bf_type->BitField.fields.count);
	di->CompositeType.elements = elements_di;
	map_set(&module->debug_info, hash_pointer(elements_di), elements_di);

	for_array(field_index, bf_type->BitField.fields) {
		Entity *field = bf_type->BitField.fields[field_index];
		u32 offset    = bf_type->BitField.offsets[field_index];
		u32 size      = bf_type->BitField.sizes[field_index];
		String name = str_lit("field_todo");
		if (field != nullptr && field->token.string.len > 0) {
			name = field->token.string;
		}
		// TODO(lachsinc): t_i64 may not be safe to use for all bitfields?
		irDebugInfo *field_di = ir_add_debug_info_field_internal(module, name, t_i64,
		                                                         0,
		                                                         nullptr,
		                                                         di);
		// NOTE(lachsinc): Above calls BitFieldValues type_size_of() which returns size in bits,
		// replace with its true bit value here..
		field_di->DerivedType.size = size;
		field_di->DerivedType.offset = offset; // Offset stored in bits already, no need to convert
		field_di->DerivedType.flags = irDebugInfoFlag_Bitfield;
		map_set(&module->debug_info, hash_pointer(field_di), field_di);
		array_add(&elements_di->DebugInfoArray.elements, field_di);
	}

	return di;
}

irDebugInfo *ir_add_debug_info_type_bit_set(irModule *module, Type *type, Entity *e, irDebugInfo *scope) {
	GB_ASSERT(type->kind == Type_BitSet || type->kind == Type_Named);

	Type *base = base_type(type);

	Type *named = nullptr;
	if (type->kind == Type_Named) {
		named = type;
	}

	Type *elem_type = nullptr;
	if (base->BitSet.elem != nullptr) {
		// TODO(lachsinc): Do bitsets have integration with non-primitive types other than enums?
		elem_type = base->BitSet.elem;
		if (elem_type->kind == Type_Enum) {
			GB_ASSERT(elem_type->Enum.fields.count == base->BitSet.upper + 1);
		}
	}

	irDebugInfo *di = ir_alloc_debug_info(irDebugInfo_CompositeType);
	di->CompositeType.name = named != nullptr ? named->Named.name : str_lit("bit_set");
	di->CompositeType.tag = irDebugBasicEncoding_structure_type;
	di->CompositeType.size = ir_debug_size_bits(base);
	map_set(&module->debug_info, hash_type(type), di);

	irDebugInfo *elements_di = ir_add_debug_info_array(module, 0, base->BitSet.upper + 1);
	di->CompositeType.elements = elements_di;
	map_set(&module->debug_info, hash_pointer(elements_di), elements_di);

	for (i64 i = 0; i <= base->BitSet.upper; ++i) {
		u32 offset = cast(u32)i;
		// TODO(lachsinc): Maybe name these fields numbered ascending?
		String name = str_lit("field_todo");
		if (elem_type != nullptr && is_type_enum(elem_type)) {
			// name = base_type(elem_type)->Enum.fields[i]->token.string;
		}
		irDebugInfo *field_di = ir_add_debug_info_field_internal(module, name, t_u32, // TODO(lachsinc): u32 fine??
		                                                         0,
		                                                         nullptr,
		                                                         di);
		field_di->DerivedType.size   = 1;
		field_di->DerivedType.offset = offset; // Offset stored in bits already, no need to convert
		field_di->DerivedType.flags  = irDebugInfoFlag_Bitfield;
		map_set(&module->debug_info, hash_pointer(field_di), field_di);
		array_add(&elements_di->DebugInfoArray.elements, field_di);
	}

	return di;
}

irDebugInfo *ir_add_debug_info_type_string(irModule *module, irDebugInfo *scope, Entity *e, Type *type) {
	// TODO(lachsinc): Does this only occur once ??
	irDebugInfo **existing = map_get(&module->debug_info, hash_type(t_string));
	if (existing != nullptr) {
		GB_ASSERT((*existing)->kind == irDebugInfo_CompositeType);
		return *existing;
	} else {
		irDebugInfo *di = ir_alloc_debug_info(irDebugInfo_CompositeType);
		di->CompositeType.name = type->Basic.name;
		di->CompositeType.tag = irDebugBasicEncoding_structure_type;
		di->CompositeType.size = ir_debug_size_bits(t_string);
		di->CompositeType.align = ir_debug_align_bits(t_string);

		map_set(&module->debug_info, hash_type(type), di);

		// Field "data"
		irDebugInfo *data_di = ir_add_debug_info_field_internal(module, str_lit("data"), t_cstring,
		                                                        0,
		                                                        nullptr,
		                                                        di);
		map_set(&module->debug_info, hash_pointer(data_di), data_di);

		// Field "len"
		irDebugInfo *len_di = ir_add_debug_info_field_internal(module, str_lit("len"), t_i64,
		                                                       data_di->DerivedType.size,
		                                                       nullptr,
		                                                       di);
		map_set(&module->debug_info, hash_pointer(len_di), len_di);

		irDebugInfo *elements_di = ir_add_debug_info_array(module, 0, 2);
		array_add(&elements_di->DebugInfoArray.elements, data_di);
		array_add(&elements_di->DebugInfoArray.elements, len_di);
		di->CompositeType.elements = elements_di;
		map_set(&module->debug_info, hash_pointer(elements_di), elements_di);

		return di;
	}
}

irDebugInfo *ir_add_debug_info_type_any(irModule *module) {
	irDebugInfo **existing = map_get(&module->debug_info, hash_type(t_any));
	if (existing != nullptr) {
		GB_ASSERT((*existing)->kind == irDebugInfo_CompositeType);
		return *existing;
	} else {
		irDebugInfo *di = ir_alloc_debug_info(irDebugInfo_CompositeType);
		di->CompositeType.name = t_any->Basic.name;
		di->CompositeType.tag = irDebugBasicEncoding_structure_type;
		di->CompositeType.size = ir_debug_size_bits(t_any);
		di->CompositeType.align = ir_debug_align_bits(t_any);

		map_set(&module->debug_info, hash_type(t_any), di);

		// Field "data"
		irDebugInfo *data_di = ir_add_debug_info_field_internal(module, str_lit("data"), t_rawptr,
		                                                        0,
		                                                        nullptr,
		                                                        di);
		map_set(&module->debug_info, hash_pointer(data_di), data_di);

		// Field "id"
		irDebugInfo *id_di = ir_add_debug_info_field_internal(module, str_lit("id"), t_typeid,
		                                                      data_di->DerivedType.size,
		                                                      nullptr,
		                                                      di);
		map_set(&module->debug_info, hash_pointer(id_di), id_di);

		irDebugInfo *elements_di = ir_add_debug_info_array(module, 0, 2);
		array_add(&elements_di->DebugInfoArray.elements, data_di);
		array_add(&elements_di->DebugInfoArray.elements, id_di);
		di->CompositeType.elements = elements_di;
		map_set(&module->debug_info, hash_pointer(elements_di), elements_di);

		return di;
	}
}

irDebugInfo *ir_add_debug_info_type_complex(irModule *module, Type *type) {
	GB_ASSERT(type->kind == Type_Basic && is_type_complex(type));

	irDebugInfo *di = ir_alloc_debug_info(irDebugInfo_CompositeType);
	map_set(&module->debug_info, hash_type(type), di);

	di->CompositeType.name = type->Basic.name;
	di->CompositeType.tag = irDebugBasicEncoding_structure_type;
	di->CompositeType.size = ir_debug_size_bits(type);

	Type *field_type = base_complex_elem_type(type);

	irDebugInfo *real_di = ir_add_debug_info_field_internal(module, str_lit("real"), field_type, 0*cast(i32)type_size_of(field_type), nullptr, di);
	irDebugInfo *imag_di = ir_add_debug_info_field_internal(module, str_lit("imag"), field_type, 1*cast(i32)type_size_of(field_type), nullptr, di);
	map_set(&module->debug_info, hash_pointer(real_di), real_di);
	map_set(&module->debug_info, hash_pointer(imag_di), imag_di);

	irDebugInfo *elements_di = ir_add_debug_info_array(module, 0, 2);
	array_add(&elements_di->DebugInfoArray.elements, real_di);
	array_add(&elements_di->DebugInfoArray.elements, imag_di);
	di->CompositeType.elements = elements_di;
	map_set(&module->debug_info, hash_pointer(elements_di), elements_di);

	return di;
}

irDebugInfo *ir_add_debug_info_type_quaternion(irModule *module, Type *type) {
	GB_ASSERT(type->kind == Type_Basic && is_type_quaternion(type));

	irDebugInfo *di = ir_alloc_debug_info(irDebugInfo_CompositeType);
	map_set(&module->debug_info, hash_type(type), di);

	di->CompositeType.name = type->Basic.name;
	di->CompositeType.tag = irDebugBasicEncoding_structure_type;
	di->CompositeType.size = ir_debug_size_bits(type);

	Type *field_type = base_complex_elem_type(type);

	// @QuaternionLayout
	irDebugInfo *imag_di = ir_add_debug_info_field_internal(module, str_lit("imag"), field_type, 0*cast(i32)type_size_of(field_type), nullptr, di);
	irDebugInfo *jmag_di = ir_add_debug_info_field_internal(module, str_lit("jmag"), field_type, 1*cast(i32)type_size_of(field_type), nullptr, di);
	irDebugInfo *kmag_di = ir_add_debug_info_field_internal(module, str_lit("kmag"), field_type, 2*cast(i32)type_size_of(field_type), nullptr, di);
	irDebugInfo *real_di = ir_add_debug_info_field_internal(module, str_lit("real"), field_type, 3*cast(i32)type_size_of(field_type), nullptr, di);

	map_set(&module->debug_info, hash_pointer(imag_di), imag_di);
	map_set(&module->debug_info, hash_pointer(jmag_di), jmag_di);
	map_set(&module->debug_info, hash_pointer(kmag_di), kmag_di);
	map_set(&module->debug_info, hash_pointer(real_di), real_di);

	irDebugInfo *elements_di = ir_add_debug_info_array(module, 0, 4);
	array_add(&elements_di->DebugInfoArray.elements, imag_di);
	array_add(&elements_di->DebugInfoArray.elements, jmag_di);
	array_add(&elements_di->DebugInfoArray.elements, kmag_di);
	array_add(&elements_di->DebugInfoArray.elements, real_di);
	di->CompositeType.elements = elements_di;
	map_set(&module->debug_info, hash_pointer(elements_di), elements_di);

	return di;
}

irDebugInfo *ir_add_debug_info_proc_type(irModule *module, Type *type) {
	GB_ASSERT(type->kind == Type_Proc);

	irDebugInfo **existing = map_get(&module->debug_info, hash_type(type));
	if (existing != nullptr) {
		GB_ASSERT((*existing)->kind == irDebugInfo_ProcType);
		return *existing;
	}

	irDebugInfo *di = ir_alloc_debug_info(irDebugInfo_ProcType);
	map_set(&module->debug_info, hash_type(type), di);

	isize result_count = type->Proc.result_count;
	isize param_count = type->Proc.param_count;
	// gb_max(result_count, 1) because llvm expects explicit "null" return type
	di->ProcType.types = ir_add_debug_info_array(module, 0, gb_max(result_count, 1) + param_count);

	// TODO(bill): Is this even correct?!
	irDebugInfo *scope = di;

	// Result/return types
	if (result_count >= 1) {
		TypeTuple *results_tuple = &type->Proc.results->Tuple;
		for_array(i, results_tuple->variables) {
			Entity *e = results_tuple->variables[i];
			if (e->kind != Entity_Variable) {
				continue;
			}

			irDebugInfo *type_di = ir_add_debug_info_type(module, e->type, e, scope, nullptr);
			GB_ASSERT_NOT_NULL(type_di);
			array_add(&di->ProcType.types->DebugInfoArray.elements, type_di);
		}
	} else {
		// llvm expects "!{null}" for a function without return type, use nullptr to represent it.
		array_add(&di->ProcType.types->DebugInfoArray.elements, (irDebugInfo*)nullptr);
	}

	// Param types
	if (param_count >= 1) {
		TypeTuple *params_tuple = &type->Proc.params->Tuple;
		for_array(i, params_tuple->variables) {
			Entity *e = params_tuple->variables[i];
			if (e->kind != Entity_Variable) {
				continue;
			}

			irDebugInfo *type_di = ir_add_debug_info_type(module, e->type, e, scope, nullptr);
			GB_ASSERT_NOT_NULL(type_di);
			array_add(&di->ProcType.types->DebugInfoArray.elements, type_di);
		}
	}

	return di;
}

irDebugInfo *ir_add_debug_info_type(irModule *module, Type *type, Entity *e, irDebugInfo *scope, irDebugInfo *file) {
	// NOTE(lachsinc): Special handling for procedure pointers - we hash their types directly into DISubroutineType's
	// but we need them interpreted as pointers when we use them as variables.
	if (type->kind == Type_Proc) {
		if (e->kind == Entity_Variable || e->kind == Entity_TypeName) {
			// TODO(lachsinc): Wasteful (maybe?). Create a derived type for _every_ different proc ptr type
			irDebugInfo *di = ir_alloc_debug_info(irDebugInfo_DerivedType);
			map_set(&module->debug_info, hash_pointer(di), di);
			di->DerivedType.tag = irDebugBasicEncoding_pointer_type;
			di->DerivedType.size = ir_debug_size_bits(t_rawptr);
			di->DerivedType.base_type = ir_add_debug_info_proc_type(module, type);
			return di;
		} else {
			GB_PANIC("Proc definitions should have their type created manually (not through this function)");
		}
	}

	irDebugInfo **existing = map_get(&module->debug_info, hash_type(type));
	if (existing != nullptr) {
		return *existing;
	}

	// Reset entity/location info, if applicable, for every type we try add.
	// TODO(lachsinc): Confirm this doesn't mess up field's scopes etc.
	if (type->kind == Type_Named) {
		e = type->Named.type_name;
		if (e) {
			CheckerInfo *info = module->info;
			file = ir_add_debug_info_file(module, ast_file_of_filename(info, e->token.pos.file));
			// TODO(lachsinc): Determine proper scope for type declaration location stuff.
			scope = file;
		}
	}

	// TODO(lachsinc): Reorder if tests, "unique" types, like basic etc. should go last, they are most likely to hit the existing hashed type
	// and no point checking them for the rest of the types. Or just use a massive switch...

	// NOTE(lachsinc): Types should be inserted into debug_info map as their named, not base_type()'d counterparts.
	Type *base = base_type(type);

	if (type->kind == Type_Named) {
		Type *named_base = type->Named.base;
		// TODO(lachsinc): Better way to determine distinct etc. or just handle structs, enums before we reach here.
		// ir_is_type_aggregate() except with no call to base_type().
		if (named_base->kind != Type_Struct &&
			named_base->kind != Type_Union &&
			named_base->kind != Type_Enum &&
			named_base->kind != Type_BitField &&
			named_base->kind != Type_Tuple) {
			// distinct / typedef etc.
			irDebugInfo *di = ir_alloc_debug_info(irDebugInfo_DerivedType);
			if (type->kind == Type_Named) {
				di->DerivedType.name = type->Named.name;
			} else if (named_base->kind == Type_Basic) {
				di->DerivedType.name = named_base->Basic.name;
			}
			di->DerivedType.tag = irDebugBasicEncoding_typedef;
			map_set(&module->debug_info, hash_type(type), di);
			// TODO(lachsinc): Do we need to try and resolve a new entity/scope for the base type?
			// Maybe we also want to pull out type->Named.type_name ?? in the case it is a Named
			di->DerivedType.base_type = ir_add_debug_info_type(module, named_base, e, scope, file);
			return di;
		}
	}

	if (type->kind == Type_Basic) {
		switch (type->Basic.kind) {
		// Composite basic types
		case Basic_complex64: case Basic_complex128:
			return ir_add_debug_info_type_complex(module, type);
		case Basic_quaternion128: case Basic_quaternion256:
			return ir_add_debug_info_type_quaternion(module, type);
		case Basic_string:
			return ir_add_debug_info_type_string(module, scope, e, type);
		case Basic_any:
			return ir_add_debug_info_type_any(module);

		// Derived basic types
		case Basic_cstring:
		case Basic_rawptr: {
			irDebugInfo *di = ir_alloc_debug_info(irDebugInfo_DerivedType);
			di->DerivedType.name = type->Basic.name;
			di->DerivedType.tag = irDebugBasicEncoding_pointer_type;
			di->DerivedType.size = ir_debug_size_bits(t_rawptr);
			di->DerivedType.align = ir_debug_align_bits(t_rawptr); // TODO(lachsinc): Not sure if align is required.
			map_set(&module->debug_info, hash_type(type), di);
			if (type->Basic.kind == Basic_cstring) {
				di->DerivedType.base_type = ir_add_debug_info_type(module, t_i8, e, scope, file);
			} else {
				// NOTE(lachsinc): llvm expects "null" for rawptr/voidptr
			}
			return di;
		}

		// Basic basic types
		default: {
			irDebugInfo *di = ir_alloc_debug_info(irDebugInfo_BasicType);
			di->BasicType.encoding = ir_debug_encoding_for_basic(type->Basic.kind);
			di->BasicType.name = type->Basic.name;
			di->BasicType.size = ir_debug_size_bits(type);
			di->BasicType.align = ir_debug_align_bits(type);
			map_set(&module->debug_info, hash_type(type), di);
			return di;
		}
		}
	}

	if (is_type_pointer(type)) {
		// TODO(lachsinc): Ensure this handles pointer-to-pointer of same type etc. correctly.
		Type *deref = type_deref(base);
		irDebugInfo *di = ir_alloc_debug_info(irDebugInfo_DerivedType);
		di->DerivedType.tag = irDebugBasicEncoding_pointer_type;
		di->DerivedType.size = ir_debug_size_bits(type);
		// NOTE(lachsinc): Map set before creating base_type to avoid circular dependency issues.
		map_set(&module->debug_info, hash_type(type), di);
		if (is_type_struct(deref)) {
			int i = 123;
		}
		di->DerivedType.base_type = ir_add_debug_info_type(module, deref, e, scope, file);
		return di;
	}

	if (is_type_opaque(type)) {
		return ir_add_debug_info_type(module, strip_opaque_type(type), e, scope, file);
	}

	if (is_type_struct(type) ||
	    is_type_union(type) || is_type_enum(type) || is_type_tuple(type)) {
		if (type->kind == Type_Named) {
			// NOTE(lachsinc): Named named's should always be handled prior as typedefs.
			GB_ASSERT(type->Named.base->kind != Type_Named);
		}

		irDebugInfo *di = ir_alloc_debug_info(irDebugInfo_CompositeType);
		// NOTE(lachsinc): Set map value before resolving field types to avoid circular dependencies.
		map_set(&module->debug_info, hash_type(type), di);
		if (is_type_named(type)) {
			di->CompositeType.name = type->kind == Type_Named ? type->Named.name : type->Basic.name;
		}
		if (e) {
			di->CompositeType.file = file;
			di->CompositeType.scope = scope;
			di->CompositeType.pos = e->token.pos;
		}
		di->CompositeType.size = ir_debug_size_bits(type);
		// di->CompositeType.align = ir_debug_align_bits(type); // TODO(lachsinc): Necessary?

		if (is_type_struct(type)) {
			GB_ASSERT(base->kind == Type_Struct);
			if (!is_type_named(type)) {
				di->CompositeType.name = str_lit("struct");
				GB_ASSERT_NOT_NULL(scope);
				di->CompositeType.scope = scope;
			}
			di->CompositeType.tag = irDebugBasicEncoding_structure_type;
			di->CompositeType.elements = ir_add_debug_info_array(module, 0, base->Struct.fields.count);
			for_array(field_index, base->Struct.fields) {
				array_add(&di->CompositeType.elements->DebugInfoArray.elements,
				          ir_add_debug_info_field(module, di, base->Struct.fields[field_index], type,
				                                  cast(i32)field_index, base->Struct.fields[field_index]->type, file));
			}
		} else if (is_type_union(type)) {
			GB_ASSERT(base->kind == Type_Union);
			if (!is_type_named(type)) {
				di->CompositeType.name = str_lit("union");
				GB_ASSERT_NOT_NULL(scope);
				di->CompositeType.scope = scope;
			}
			di->CompositeType.tag = irDebugBasicEncoding_union_type;
			di->CompositeType.elements = ir_add_debug_info_array(module, 0, base->Union.variants.count);
			// TODO(lachsinc): Cleanup; this should be handled in a more generic manner for all types.
			file = ir_add_debug_info_file(module, base->Union.node->file);
			GB_ASSERT_NOT_NULL(file); // Union debug info requires file info
			di->CompositeType.file = file;
			di->CompositeType.pos = base->Union.node->UnionType.token.pos;
			for_array(field_index, base->Union.variants) {
				// TODO(bill): Union pseudo-"fields"
				// irDebugInfo *di = ir_add_debug_info_field(module, di, nullptr, type, cast(i32)field_index, base->Union.variants[field_index], file);
				// array_add(&di->CompositeType.elements->DebugInfoArray.elements, di);
			}
		} else if (is_type_enum(type)) {
			GB_ASSERT(base->kind == Type_Enum);
			if (!is_type_named(type)) {
				di->CompositeType.name = str_lit("enum");
				GB_ASSERT_NOT_NULL(scope);
				di->CompositeType.scope = scope;
			}
			di->CompositeType.tag = irDebugBasicEncoding_enumeration_type;
			di->CompositeType.base_type = ir_add_debug_info_type(module, base->Enum.base_type, e, scope, file);
			di->CompositeType.elements = ir_add_debug_info_array(module, 0, base->Enum.fields.count);
			for_array(field_index, base->Enum.fields) {
				array_add(&di->CompositeType.elements->DebugInfoArray.elements,
				          ir_add_debug_info_enumerator(module, base->Enum.fields[field_index]));
			}

			// TODO(lachsinc): Do we want to ensure this is an enum in the global scope before
			// adding it into the modules enum array ??
			array_add(&module->debug_compile_unit->CompileUnit.enums->DebugInfoArray.elements, di);
		} else if (is_type_tuple(type)) {
			GB_ASSERT(base->kind == Type_Tuple);
			if (!is_type_named(type)) {
				di->CompositeType.name = str_lit("tuple");
				GB_ASSERT_NOT_NULL(scope);
				di->CompositeType.scope = scope;
			}
			di->CompositeType.tag = irDebugBasicEncoding_structure_type;
			di->CompositeType.elements = ir_add_debug_info_array(module, 0, base->Tuple.variables.count);
			// TODO(lachsinc): Ensure offsets are set properly?
			for_array(var_index, base->Tuple.variables) {
				array_add(&di->CompositeType.elements->DebugInfoArray.elements,
				          ir_add_debug_info_field(module, di, base->Tuple.variables[var_index], type,
				                                  cast(i32)var_index, base->Tuple.variables[var_index]->type, file));
			}
		}

		return di;
	}

	if (is_type_dynamic_array(type)) {
		return ir_add_debug_info_type_dynamic_array(module, type, e, scope, file);
	}

	if (is_type_array(type)) {
		irDebugInfo *di = ir_alloc_debug_info(irDebugInfo_CompositeType);
		di->CompositeType.size = ir_debug_size_bits(type);
		di->CompositeType.align = ir_debug_align_bits(type);
		di->CompositeType.tag = irDebugBasicEncoding_array_type;
		di->CompositeType.array_count = (i32)type->Array.count;

		map_set(&module->debug_info, hash_type(type), di);
		di->CompositeType.base_type = ir_add_debug_info_type(module, type->Array.elem, e, scope, file);
		GB_ASSERT(base->kind != Type_Named);

		return di;
	}

	if (is_type_enumerated_array(type)) {
		irDebugInfo *di = ir_alloc_debug_info(irDebugInfo_CompositeType);
		di->CompositeType.size = ir_debug_size_bits(type);
		di->CompositeType.align = ir_debug_align_bits(type);
		di->CompositeType.tag = irDebugBasicEncoding_array_type;
		di->CompositeType.array_count = (i32)type->EnumeratedArray.count;

		map_set(&module->debug_info, hash_type(type), di);
		di->CompositeType.base_type = ir_add_debug_info_type(module, type->EnumeratedArray.elem, e, scope, file);
		GB_ASSERT(base->kind != Type_Named);

		return di;
	}

	if (is_type_slice(type)) {
		// NOTE(lachsinc): Every slice type has its own composite type / field debug infos created. This is sorta wasteful.
		irDebugInfo *di = ir_alloc_debug_info(irDebugInfo_CompositeType);
		di->CompositeType.name = str_lit("slice");
		di->CompositeType.tag = irDebugBasicEncoding_structure_type;
		di->CompositeType.size = ir_debug_size_bits(type); // TODO(lachsinc): Correct ??
		di->CompositeType.align = ir_debug_align_bits(type);
		map_set(&module->debug_info, hash_type(type), di);

		// Data pointer type
		irDebugInfo *data_ptr_di = ir_alloc_debug_info(irDebugInfo_DerivedType);
		Type *elem_type = type->Slice.elem;
		if (is_type_named(elem_type)) {
			data_ptr_di->DerivedType.name = elem_type->kind == Type_Named ? elem_type->Named.name : elem_type->Basic.name;
		}
		data_ptr_di->DerivedType.tag = irDebugBasicEncoding_pointer_type;
		data_ptr_di->DerivedType.size = ir_debug_size_bits(t_rawptr);
		map_set(&module->debug_info, hash_pointer(data_ptr_di), data_ptr_di);
		data_ptr_di->DerivedType.base_type = ir_add_debug_info_type(module, elem_type, e, scope, file);

		irDebugInfo *data_di = ir_add_debug_info_field_internal(module, str_lit("data"), t_rawptr,
		                                                        0,
		                                                        nullptr,
		                                                        di);
		data_di->DerivedType.base_type = data_ptr_di;
		map_set(&module->debug_info, hash_pointer(data_di), data_di);

		irDebugInfo *len_di = ir_add_debug_info_field_internal(module, str_lit("len"), t_int,
		                                                       data_di->DerivedType.size,
		                                                       nullptr,
		                                                       di);
		map_set(&module->debug_info, hash_pointer(len_di), len_di);

		irDebugInfo *elements_di = ir_add_debug_info_array(module, 0, 2);
		array_add(&elements_di->DebugInfoArray.elements, data_di);
		array_add(&elements_di->DebugInfoArray.elements, len_di);
		di->CompositeType.elements = elements_di;
		map_set(&module->debug_info, hash_pointer(elements_di), elements_di);

		return di;
	}

	if (is_type_map(type)) {
		// TODO(lachsinc): Looks like "generated_struct_type" map.entries.data is just a u8*, we could
		// always look at the map header and create the debug info manually (if we
		// want struct members to be interpreted as the correct type).
		// Also; are hashes meant to be interpreted as bool*'s ?? or is that simply slot occupied data?
		return ir_add_debug_info_type(module, type->Map.generated_struct_type, e, scope, file);
	}

	// NOTE(lachsinc): For now we just interpret all BitFieldValues as i64 inside ir_add_debug_info_type_bit_field().
	/*
	if (is_type_bit_field_value(type)) {
		// NOTE(Lachsinc): Suboptimal; creates a new type for each unique bit field value type
		irDebugInfo *di = ir_alloc_debug_info(irDebugInfo_BasicType);
		di->BasicType.encoding = irDebugBasicEncoding_unsigned;
		// di->BasicType.name = str_lit("todo");
		di->BasicType.size = base->BitFieldValue.bits;
		map_set(&module->debug_info, hash_type(type), di);
		return di;
	}
	*/

	if (is_type_bit_field(type)) {
		return ir_add_debug_info_type_bit_field(module, type, e, scope);
	}

	if (is_type_bit_set(type)) {
		return ir_add_debug_info_type_bit_set(module, type, e, scope);
	}

	if (is_type_simd_vector(type)) {
		irDebugInfo *di = ir_alloc_debug_info(irDebugInfo_CompositeType);
		di->CompositeType.size = ir_debug_size_bits(type);
		di->CompositeType.align = ir_debug_align_bits(type);
		di->CompositeType.tag = irDebugBasicEncoding_array_type;
		di->CompositeType.array_count = (i32)type->SimdVector.count;

		map_set(&module->debug_info, hash_type(type), di);
		di->CompositeType.base_type = ir_add_debug_info_type(module, type->SimdVector.elem, e, scope, file);
		GB_ASSERT(base->kind != Type_Named);
		return di;
	}

	GB_PANIC("Unreachable %s", type_to_string(type));
	return nullptr;
}

irDebugInfo *ir_add_debug_info_global(irModule *module, irValue *v) {
	if (!module->generate_debug_info) {
		return nullptr;
	}

	Entity *e = v->Global.entity;

	// NOTE(lachsinc): Just to be safe/robust; globals are likely added once only?
	irDebugInfo **existing = map_get(&module->debug_info, hash_entity(e));
	if (existing != nullptr) {
		return *existing;
	}

	irDebugInfo *di = ir_alloc_debug_info(irDebugInfo_GlobalVariableExpression);
	map_set(&module->debug_info, hash_entity(e), di);

	// Create or fetch file debug info.
	CheckerInfo *info = module->info;
	String filename = e->token.pos.file;
	AstFile *f = ast_file_of_filename(info, filename);
	GB_ASSERT_NOT_NULL(f);
	irDebugInfo *scope = ir_add_debug_info_file(module, f);

	irDebugInfo *var_di = ir_alloc_debug_info(irDebugInfo_GlobalVariable);
	var_di->GlobalVariable.name = e->token.string;
	var_di->GlobalVariable.scope = scope;
	var_di->GlobalVariable.file = scope;
	var_di->GlobalVariable.pos = e->token.pos;
	var_di->GlobalVariable.variable = v;

	// NOTE(lachsinc): The "DIGlobalVariableExpression" owns us, and is what we refer to from other
	// locations in the ir source, so we will reserve the "e" hash for it, and use something else
	// unique for the DIGlobalVariable's hash.
	map_set(&module->debug_info, hash_pointer(var_di), var_di);

	var_di->GlobalVariable.type = ir_add_debug_info_type(module, e->type, nullptr, scope, nullptr);
	GB_ASSERT_NOT_NULL(var_di->GlobalVariable.type);

	di->GlobalVariableExpression.var = var_di;

	array_add(&module->debug_compile_unit->CompileUnit.globals->DebugInfoArray.elements, di);

	return di;
}

irDebugInfo *ir_add_debug_info_block(irProcedure *proc, Scope *scope) {
	irModule *module = proc->module;

	irDebugInfo **existing = map_get(&module->debug_info, hash_pointer(scope));
	if (existing != nullptr) {
		GB_ASSERT((*existing)->kind == irDebugInfo_LexicalBlock);
		return *existing;
	}

	Ast *block = scope->node;

	irDebugInfo *di = ir_alloc_debug_info(irDebugInfo_LexicalBlock);
	di->LexicalBlock.file = proc->debug_scope->Proc.file;
	di->LexicalBlock.scope = proc->debug_scope;
	di->LexicalBlock.pos = ast_token(block).pos;
	map_set(&module->debug_info, hash_pointer(scope), di);
	return di;
}

irDebugInfo *ir_add_debug_info_local(irProcedure *proc, Entity *e, i32 arg_id) {
	// TODO(lachsinc): Not sure if this handles generated locals properly as they may not have
	// enough information contained inside "e".

	irModule *module = proc->module;
	if (!module->generate_debug_info) {
		return nullptr;
	}

	irDebugInfo *scope = nullptr;
	irDebugInfo *file = nullptr;
	if (e->scope && e->scope->node->kind == Ast_ProcType) {
		scope = proc->debug_scope;
		file = proc->debug_scope->Proc.file;
	} else {
		scope = ir_add_debug_info_block(proc, e->scope);
		file = scope->LexicalBlock.file;
	}
	GB_ASSERT_NOT_NULL(scope);
	GB_ASSERT_NOT_NULL(file);

	irDebugInfo *di = ir_alloc_debug_info(irDebugInfo_LocalVariable);
	di->LocalVariable.name = e->token.string;
	di->LocalVariable.scope = scope;
	di->LocalVariable.file = file;
	di->LocalVariable.pos = e->token.pos;
	di->LocalVariable.arg = arg_id;
	di->LocalVariable.type = ir_add_debug_info_type(module, e->type, e, scope, file); // TODO(lachsinc): Is this the correct entity to pass? Or do we want a TypeName ??

	map_set(&module->debug_info, hash_entity(e), di);
	return di;
}

irDebugInfo *ir_add_debug_info_proc(irProcedure *proc) {
	irModule *module = proc->module;
	if (!module->generate_debug_info) {
		return nullptr;
	}

	Entity *entity = proc->entity;

	// Add / retrieve debug info for file.
	CheckerInfo *info = proc->module->info;
	String filename = proc->entity->token.pos.file;
	AstFile *f = ast_file_of_filename(info, filename);
	irDebugInfo *file = nullptr;
	if (f) {
		file = ir_add_debug_info_file(proc->module, f);
	}
	// TODO(lachsinc): Should scope be made separate to file?
	irDebugInfo *scope = file;

	irDebugInfo *di = ir_alloc_debug_info(irDebugInfo_Proc);
	map_set(&proc->module->debug_info, hash_entity(entity), di);
	di->Proc.entity = entity;
	di->Proc.name = proc->name;
	di->Proc.file = file;
	di->Proc.pos = entity->token.pos;
	di->Proc.type = ir_add_debug_info_proc_type(proc->module, proc->type);

	proc->debug_scope = di;
	return di;
}

irDebugInfo *ir_add_debug_info_location(irModule *m, Ast *node, irDebugInfo *scope, Entity *e) {
	if (node == nullptr || scope == nullptr) {
		if (e != nullptr && scope != nullptr) {
			// irDebugInfo **existing = map_get(&m->debug_info, hash_entity(e));
			// if (existing != nullptr) {
			// 	return *existing;
			// }

			// // TODO HACK(bill): This is a little dirty but it is should do for the weird edge cases
			// irDebugInfo *di = ir_alloc_debug_info(irDebugInfo_Location);
			// di->Location.pos = e->token.pos;
			// di->Location.scope = scope;
			// map_set(&m->debug_info, hash_entity(e), di);
			// return di;
		}
		return nullptr;
	}
	// TODO(lachsinc): Should we traverse the node/children until we find one with
	// valid token/pos and use that instead??
	irDebugInfo **existing = map_get(&m->debug_info, hash_node(node));
	if (existing != nullptr) {
		return *existing;
	}
	irDebugInfo *di = ir_alloc_debug_info(irDebugInfo_Location);
	di->Location.pos = ast_token(node).pos;
	di->Location.scope = scope;
	map_set(&m->debug_info, hash_node(node), di);
	return di;
}

void ir_push_debug_location(irModule *m, Ast *node, irDebugInfo *scope, Entity *e) {
	irDebugInfo *debug_location = ir_add_debug_info_location(m, node, scope, e);
	array_add(&m->debug_location_stack, debug_location);
}

void ir_pop_debug_location(irModule *m) {
	GB_ASSERT_MSG(m->debug_location_stack.count > 0, "Attempt to pop debug location stack too many times");
	array_pop(&m->debug_location_stack);
}

////////////////////////////////////////////////////////////////
//
// @Emit
//
////////////////////////////////////////////////////////////////

irValue *ir_emit_runtime_call(irProcedure *proc,                            char const *name_, Array<irValue *> args, Ast *expr = nullptr, ProcInlining inlining = ProcInlining_none);
irValue *ir_emit_package_call(irProcedure *proc, char const *package_name_, char const *name_, Array<irValue *> args, Ast *expr = nullptr, ProcInlining inlining = ProcInlining_none);


irValue *ir_emit_store(irProcedure *p, irValue *address, irValue *value, bool is_volatile) {
	Type *a = type_deref(ir_type(address));

	if (is_type_boolean(a)) {
		// NOTE(bill): There are multiple sized booleans, thus force a conversion (if necessarily)
		value = ir_emit_conv(p, value, a);
	}

	if (address) address->uses += 1;
	if (value) value->uses += 1;


	Type *b = ir_type(value);
	if (!is_type_untyped(b)) {
		GB_ASSERT_MSG(are_types_identical(core_type(a), core_type(b)), "%s %s", type_to_string(a), type_to_string(b));
	}
	return ir_emit(p, ir_instr_store(p, address, value, is_volatile));
}
irValue *ir_emit_load(irProcedure *p, irValue *address, i64 custom_align) {
	GB_ASSERT(address != nullptr);
	Type *t = type_deref(ir_type(address));
	// if (is_type_boolean(t)) {
		// return ir_emit(p, ir_instr_load_bool(p, address));
	// }
	if (address) address->uses += 1;
	auto instr = ir_instr_load(p, address);
	instr->Instr.Load.custom_align = custom_align;
	return ir_emit(p, instr);
}
irValue *ir_emit_select(irProcedure *p, irValue *cond, irValue *t, irValue *f) {
	if (cond) cond->uses += 1;
	if (t) t->uses += 1;
	if (f) f->uses += 1;

	return ir_emit(p, ir_instr_select(p, cond, t, f));
}

void ir_value_set_debug_location(irProcedure *proc, irValue *v) {
	GB_ASSERT_NOT_NULL(proc);
	GB_ASSERT_NOT_NULL(v);

	if (v->loc != nullptr) {
		return; // Already set
	}

	irModule *m = proc->module;
	GB_ASSERT(m->debug_location_stack.count > 0);
	v->loc = *array_end_ptr(&m->debug_location_stack);

	if (v->loc == nullptr && proc->entity != nullptr) {
		if (proc->is_entry_point || (string_compare(proc->name, str_lit(IR_STARTUP_RUNTIME_PROC_NAME)) == 0)) {
			// NOTE(lachsinc): Entry point (main()) and runtime_startup are the only ones where null location is considered valid.
		} else {
			if (v->kind == irValue_Instr) {
				auto *instr = &v->Instr;
				gb_printf_err("Instruction kind: %.*s\n", LIT(ir_instr_strings[instr->kind]));
				if (instr->kind == irInstr_DebugDeclare) {
					gb_printf_err("\t%.*s\n", LIT(instr->DebugDeclare.entity->token.string));
				}
			}
			GB_PANIC("Value without debug location: %.*s %p; %p :: %s", LIT(proc->name), proc->entity, v, type_to_string(proc->type));
		}
	}
}

void ir_emit_zero_init(irProcedure *p, irValue *address, Ast *expr) {
	gbAllocator a = ir_allocator();
	Type *t = type_deref(ir_type(address));
	isize sz = type_size_of(t);

	if (address) address->uses += 1;

	if (!(gb_is_power_of_two(sz) && sz <= build_context.max_align)) {
		// TODO(bill): Is this a good idea?
		auto args = array_make<irValue *>(a, 2);
		args[0] = ir_emit_conv(p, address, t_rawptr);
		args[1] = ir_const_int(type_size_of(t));
		AstPackage *pkg_runtime = get_core_package(p->module->info, str_lit("runtime"));
		if (p->entity != nullptr) {
			String name = p->entity->token.string;
			if (p->entity->pkg != pkg_runtime && !(name == "mem_zero" || name == "memset")) {
				ir_emit_comment(p, str_lit("ZeroInit"));
				irValue *v = ir_emit_package_call(p, "runtime", "mem_zero", args, expr);
				return;
			}
		}
	}
	ir_emit(p, ir_instr_zero_init(p, address));
}

irValue *ir_emit_comment(irProcedure *p, String text) {
	return ir_emit(p, ir_instr_comment(p, text));
}

void ir_emit_init_context(irProcedure *proc, irValue *c = nullptr) {
	irModule *m = proc->module;
	gbAllocator a = ir_allocator();
	auto args = array_make<irValue *>(a, 1);
	args[0] = c ? c : m->global_default_context;
	ir_emit_runtime_call(proc, "__init_context", args);
}






irValue *ir_copy_value_to_ptr(irProcedure *proc, irValue *val, Type *new_type, i64 alignment) {
	i64 type_alignment = type_align_of(new_type);
	if (alignment < type_alignment) {
		alignment = type_alignment;
	}
	GB_ASSERT_MSG(are_types_identical(new_type, ir_type(val)), "%s %s", type_to_string(new_type), type_to_string(ir_type(val)));

	irValue *ptr = ir_add_local_generated(proc, new_type, false);
	ptr->Instr.Local.alignment = alignment;
	ir_emit_store(proc, ptr, val);

	return ptr;
}

irValue *ir_emit_bitcast(irProcedure *proc, irValue *data, Type *type) {
	return ir_emit(proc, ir_instr_conv(proc, irConv_bitcast, data, ir_type(data), type));
}

void ir_emit_unreachable(irProcedure *proc) {
	ir_emit(proc, ir_instr_unreachable(proc));
}


irValue *ir_get_package_value(irModule *m, String package_name, String entity_name) {
	AstPackage *rt_pkg = get_core_package(m->info, package_name);
	Entity *e = scope_lookup_current(rt_pkg->scope, entity_name);
	irValue **found = map_get(&m->values, hash_entity(e));
	GB_ASSERT_MSG(found != nullptr, "%.*s", LIT(e->token.string));
	return *found;
}

irValue *ir_find_or_generate_context_ptr(irProcedure *proc) {
	if (proc->context_stack.count > 0) {
		return proc->context_stack[proc->context_stack.count-1].value;
	}

	irBlock *tmp_block = proc->curr_block;
	proc->curr_block = proc->blocks[0];

	defer (proc->curr_block = tmp_block);

	irValue *c = ir_add_local_generated(proc, t_context, true);
	ir_push_context_onto_stack(proc, c);
	ir_emit_store(proc, c, ir_emit_load(proc, proc->module->global_default_context));
	ir_emit_init_context(proc, c);
	return c;
}

Array<irValue *> ir_value_to_array(irProcedure *p, irValue *value) {
	Array<irValue *> array = {};
	Type *t = base_type(ir_type(value));
	if (t == nullptr) {
		// Do nothing
	} else if (is_type_tuple(t)) {
		GB_ASSERT(t->kind == Type_Tuple);
		auto *rt = &t->Tuple;
		if (rt->variables.count > 0) {
			array = array_make<irValue *>(ir_allocator(), rt->variables.count);
			for_array(i, rt->variables) {
				irValue *elem = ir_emit_struct_ev(p, value, cast(i32)i);
				array[i] = elem;
			}
		}
	} else {
		array = array_make<irValue *>(ir_allocator(), 1);
		array[0] = value;
	}
	return array;
}


irValue *ir_emit_call(irProcedure *p, irValue *value, Array<irValue *> const &args, ProcInlining inlining = ProcInlining_none, bool use_return_ptr_hint = false) {
	Type *pt = base_type(ir_type(value));
	GB_ASSERT(pt->kind == Type_Proc);
	Type *results = pt->Proc.results;

	if (p->entity != nullptr) {
		if (p->entity->flags & EntityFlag_Disabled) {
			return nullptr;
		}
	}

	irValue *context_ptr = nullptr;
	if (pt->Proc.calling_convention == ProcCC_Odin) {
		context_ptr = ir_find_or_generate_context_ptr(p);
	}

	set_procedure_abi_types(heap_allocator(), pt);

	bool is_c_vararg = pt->Proc.c_vararg;
	isize param_count = pt->Proc.param_count;
	if (is_c_vararg) {
		GB_ASSERT(param_count-1 <= args.count);
		param_count -= 1;
	} else {
		GB_ASSERT_MSG(param_count == args.count, "%td == %td", param_count, args.count);
	}

	auto processed_args = array_make<irValue *>(heap_allocator(), 0, args.count);

	for (isize i = 0; i < param_count; i++) {
		Entity *e = pt->Proc.params->Tuple.variables[i];
		if (e->kind != Entity_Variable) {
			array_add(&processed_args, args[i]);
			continue;
		}
		GB_ASSERT(e->flags & EntityFlag_Param);

		Type *original_type = e->type;
		Type *new_type = pt->Proc.abi_compat_params[i];
		Type *arg_type = ir_type(args[i]);
		if (are_types_identical(arg_type, new_type)) {
			// NOTE(bill): Done
			array_add(&processed_args, args[i]);
		} else if (!are_types_identical(original_type, new_type)) {
			if (is_type_pointer(new_type) && !is_type_pointer(original_type)) {
				if (e->flags&EntityFlag_ImplicitReference) {
					array_add(&processed_args, ir_address_from_load_or_generate_local(p, args[i]));
				} else if (!is_type_pointer(arg_type)) {
					array_add(&processed_args, ir_copy_value_to_ptr(p, args[i], original_type, 16));
				}
			} else if (is_type_integer(new_type) || is_type_float(new_type)) {
				array_add(&processed_args, ir_emit_transmute(p, args[i], new_type));
			} else if (new_type == t_llvm_bool) {
				array_add(&processed_args, ir_emit_conv(p, args[i], new_type));
			} else if (is_type_simd_vector(new_type)) {
				array_add(&processed_args, ir_emit_transmute(p, args[i], new_type));
			} else if (is_type_tuple(new_type)) {
				Type *abi_type = pt->Proc.abi_compat_params[i];
				Type *st = struct_type_from_systemv_distribute_struct_fields(abi_type);
				irValue *x = ir_emit_transmute(p, args[i], st);
				for (isize j = 0; j < new_type->Tuple.variables.count; j++) {
					irValue *xx = ir_emit_struct_ev(p, x, cast(i32)j);
					array_add(&processed_args, xx);
				}
			}
		} else {
			irValue *x = ir_emit_conv(p, args[i], new_type);
			array_add(&processed_args, x);
		}
	}

	if (inlining == ProcInlining_none) {
		inlining = p->inlining;
	}

	irValue *result = nullptr;

	Type *abi_rt = pt->Proc.abi_compat_result_type;
	Type *rt = reduce_tuple_to_single_type(results);
	if (pt->Proc.return_by_pointer) {
		irValue *return_ptr = nullptr;
		if (use_return_ptr_hint && p->return_ptr_hint_value != nullptr) {
			if (are_types_identical(type_deref(ir_type(p->return_ptr_hint_value)), rt)) {
				return_ptr = p->return_ptr_hint_value;
				p->return_ptr_hint_used = true;
				return_ptr->uses += 1;
			}
		}
		if (return_ptr == nullptr) {
			return_ptr = ir_add_local_generated(p, rt, true);
		}
		GB_ASSERT(is_type_pointer(ir_type(return_ptr)));
		ir_emit(p, ir_instr_call(p, value, return_ptr, processed_args, nullptr, context_ptr, inlining));
		result = ir_emit_load(p, return_ptr);
	} else {
		result = ir_emit(p, ir_instr_call(p, value, nullptr, processed_args, abi_rt, context_ptr, inlining));
		if (abi_rt != results) {
			result = ir_emit_transmute(p, result, rt);
		}
	}

	if (value->kind == irValue_Proc) {
		irProcedure *the_proc = &value->Proc;
		Entity *e = the_proc->entity;
		if (e != nullptr && entity_has_deferred_procedure(e)) {
			DeferredProcedureKind kind = e->Procedure.deferred_procedure.kind;
			Entity *deferred_entity = e->Procedure.deferred_procedure.entity;
			irValue **deferred_found = map_get(&p->module->values, hash_entity(deferred_entity));
			GB_ASSERT(deferred_found != nullptr);
			irValue *deferred = *deferred_found;


			auto in_args = args;
			Array<irValue *> result_as_args = {};
			switch (kind) {
			case DeferredProcedure_none:
				break;
			case DeferredProcedure_in:
				result_as_args = in_args;
				break;
			case DeferredProcedure_out:
				result_as_args = ir_value_to_array(p, result);
				break;
			}

			ir_add_defer_proc(p, p->scope_index, deferred, result_as_args);
		}
	}

	return result;
}

irValue *ir_emit_runtime_call(irProcedure *proc, char const *name_, Array<irValue *> args, Ast *expr, ProcInlining inlining) {
	String name = make_string_c(cast(char *)name_);

	AstPackage *p = proc->module->info->runtime_package;
	Entity *e = scope_lookup_current(p->scope, name);
	irValue **found = map_get(&proc->module->values, hash_entity(e));
	GB_ASSERT_MSG(found != nullptr, "%.*s", LIT(name));
	irValue *gp = *found;
	irValue *call = ir_emit_call(proc, gp, args, inlining);
	return call;
}
irValue *ir_emit_package_call(irProcedure *proc, char const *package_name_, char const *name_, Array<irValue *> args, Ast *expr, ProcInlining inlining) {
	String name = make_string_c(cast(char *)name_);
	String package_name = make_string_c(cast(char *)package_name_);

	AstPackage *p = get_core_package(proc->module->info, package_name);
	Entity *e = scope_lookup_current(p->scope, name);
	irValue **found = map_get(&proc->module->values, hash_entity(e));
	GB_ASSERT_MSG(found != nullptr, "%s.%.*s", package_name_, LIT(name));
	irValue *gp = *found;
	irValue *call = ir_emit_call(proc, gp, args, inlining);
	return call;
}



void ir_emit_defer_stmts(irProcedure *proc, irDeferExitKind kind, irBlock *block) {
	isize count = proc->defer_stmts.count;
	isize i = count;
	while (i --> 0) {
		irDefer d = proc->defer_stmts[i];
		if (proc->context_stack.count >= d.context_stack_count) {
			proc->context_stack.count = d.context_stack_count;
		}

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
			isize lower_limit = block->scope_index;
			if (lower_limit < d.scope_index) {
				ir_build_defer_stmt(proc, d);
			}
		}
	}
}


void ir_open_scope(irProcedure *proc) {
	proc->scope_index++;
}

void ir_close_scope(irProcedure *proc, irDeferExitKind kind, irBlock *block, bool pop_stack=true) {
	ir_emit_defer_stmts(proc, kind, block);
	GB_ASSERT(proc->scope_index > 0);


	// NOTE(bill): Remove `context`s made in that scope

	isize end_idx = proc->context_stack.count-1;
	isize pop_count = 0;

	for (;;) {
		if (end_idx < 0) {
			break;
		}
		irContextData *end = &proc->context_stack[end_idx];
		if (end == nullptr) {
			break;
		}
		if (end->scope_index != proc->scope_index) {
			break;
		}
		end_idx -= 1;
		pop_count += 1;
	}
	if (pop_stack) {
		for (isize i = 0; i < pop_count; i++) {
			array_pop(&proc->context_stack);
		}
	}


	proc->scope_index--;
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

	if (v) v->uses += 1;
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

	if (cond) cond->uses += 1;
}




irValue *ir_emit_comp(irProcedure *proc, TokenKind op_kind, irValue *left, irValue *right);

irValue *ir_gen_map_header(irProcedure *proc, irValue *map_val_ptr, Type *map_type) {
	GB_ASSERT_MSG(is_type_pointer(ir_type(map_val_ptr)), "%s", type_to_string(ir_type(map_val_ptr)));
	gbAllocator a = ir_allocator();
	irValue *h = ir_add_local_generated(proc, t_map_header, false); // all the values will be initialzed later
	map_type = base_type(map_type);

	Type *key_type = map_type->Map.key;
	Type *val_type = map_type->Map.value;

	// NOTE(bill): Removes unnecessary allocation if split gep
	irValue *gep0 = ir_emit_struct_ep(proc, h, 0);
	irValue *m = ir_emit_conv(proc, map_val_ptr, type_deref(ir_type(gep0)));
	ir_emit_store(proc, gep0, m);

	ir_emit_store(proc, ir_emit_struct_ep(proc, h, 1), ir_const_bool(is_type_string(key_type)));

	i64 entry_size   = type_size_of  (map_type->Map.entry_type);
	i64 entry_align  = type_align_of (map_type->Map.entry_type);
	i64 value_offset = type_offset_of(map_type->Map.entry_type, 2);
	i64 value_size   = type_size_of  (map_type->Map.value);

	ir_emit_store(proc, ir_emit_struct_ep(proc, h, 2), ir_const_int(entry_size));
	ir_emit_store(proc, ir_emit_struct_ep(proc, h, 3), ir_const_int(entry_align));
	ir_emit_store(proc, ir_emit_struct_ep(proc, h, 4), ir_const_uintptr(value_offset));
	ir_emit_store(proc, ir_emit_struct_ep(proc, h, 5), ir_const_int(value_size));

	return ir_emit_load(proc, h);
}

irValue *ir_gen_map_key(irProcedure *proc, irValue *key, Type *key_type) {
	Type *hash_type = t_u64;
	irValue *v = ir_add_local_generated(proc, t_map_key, true);
	Type *t = base_type(ir_type(key));
	key = ir_emit_conv(proc, key, key_type);
	if (is_type_integer(t)) {
		ir_emit_store(proc, ir_emit_struct_ep(proc, v, 0), ir_emit_conv(proc, key, hash_type));
	} else if (is_type_enum(t)) {
		ir_emit_store(proc, ir_emit_struct_ep(proc, v, 0), ir_emit_conv(proc, key, hash_type));
	} else if (is_type_typeid(t)) {
		irValue *i = ir_emit_bitcast(proc, key, t_uint);
		ir_emit_store(proc, ir_emit_struct_ep(proc, v, 0), ir_emit_conv(proc, i, hash_type));
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
			hashed_str = ir_value_constant(t_u64, exact_value_u64(hs));
		} else {
			auto args = array_make<irValue *>(ir_allocator(), 1);
			args[0] = str;
			hashed_str = ir_emit_runtime_call(proc, "default_hash_string", args);
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
	irValue *local = ir_add_local_generated(proc, type, false);
	ir_emit_store(proc, local, val);
	return local;
}


Type *ir_addr_type(irAddr const &addr) {
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
irValue *ir_emit_source_code_location(irProcedure *proc, Ast *node);
irValue *ir_emit_ptr_offset(irProcedure *proc, irValue *ptr, irValue *offset);
irValue *ir_emit_arith(irProcedure *proc, TokenKind op, irValue *left, irValue *right, Type *type);
irValue *ir_emit_deep_field_gep(irProcedure *proc, irValue *e, Selection sel);
void ir_emit_bounds_check(irProcedure *proc, Token token, irValue *index, irValue *len);


irValue *ir_insert_dynamic_map_key_and_value(irProcedure *proc, irValue *addr, Type *map_type,
                                             irValue *map_key, irValue *map_value) {
	map_type = base_type(map_type);

	irValue *h = ir_gen_map_header(proc, addr, map_type);
	irValue *key = ir_gen_map_key(proc, map_key, map_type->Map.key);
	irValue *v = ir_emit_conv(proc, map_value, map_type->Map.value);

	irValue *ptr = ir_add_local_generated(proc, ir_type(v), false);
	ir_emit_store(proc, ptr, v);

	auto args = array_make<irValue *>(ir_allocator(), 4);
	args[0] = h;
	args[1] = key;
	args[2] = ir_emit_conv(proc, ptr, t_rawptr);
	args[3] = ir_emit_source_code_location(proc, nullptr);
	return ir_emit_runtime_call(proc, "__dynamic_map_set", args);
}



irValue *ir_soa_struct_len(irProcedure *proc, irValue *value) {
	Type *t = base_type(ir_type(value));
	bool is_ptr = false;
	if (is_type_pointer(t)) {
		is_ptr = true;
		t = base_type(type_deref(t));
	}


	if (t->Struct.soa_kind == StructSoa_Fixed) {
		return ir_const_int(t->Struct.soa_count);
	}

	GB_ASSERT(t->Struct.soa_kind == StructSoa_Slice ||
	          t->Struct.soa_kind == StructSoa_Dynamic);

	isize n = 0;
	Type *elem = base_type(t->Struct.soa_elem);
	if (elem->kind == Type_Struct) {
		n = elem->Struct.fields.count;
	} else if (elem->kind == Type_Array) {
		n = elem->Array.count;
	} else {
		GB_PANIC("Unreachable");
	}

	if (is_ptr) {
		irValue *v = ir_emit_struct_ep(proc, value, cast(i32)n);
		return ir_emit_load(proc, v);
	}
	return ir_emit_struct_ev(proc, value, cast(i32)n);
}

irValue *ir_soa_struct_cap(irProcedure *proc, irValue *value) {
	Type *t = base_type(ir_type(value));

	bool is_ptr = false;
	if (is_type_pointer(t)) {
		is_ptr = true;
		t = base_type(type_deref(t));
	}

	if (t->Struct.soa_kind == StructSoa_Fixed) {
		return ir_const_int(t->Struct.soa_count);
	}

	GB_ASSERT(t->Struct.soa_kind == StructSoa_Dynamic);

	isize n = 0;
	Type *elem = base_type(t->Struct.soa_elem);
	if (elem->kind == Type_Struct) {
		n = elem->Struct.fields.count+1;
	} else if (elem->kind == Type_Array) {
		n = elem->Array.count+1;
	} else {
		GB_PANIC("Unreachable");
	}

	if (is_ptr) {
		irValue *v = ir_emit_struct_ep(proc, value, cast(i32)n);
		return ir_emit_load(proc, v);
	}
	return ir_emit_struct_ev(proc, value, cast(i32)n);
}



void ir_addr_store(irProcedure *proc, irAddr const &addr, irValue *value) {
	if (addr.addr == nullptr) {
		return;
	}
	if (addr.kind == irAddr_Map) {
		ir_insert_dynamic_map_key_and_value(proc, addr.addr, addr.map_type, addr.map_key, value);
		return;
	} else if (addr.kind == irAddr_BitField) {
		gbAllocator a = ir_allocator();

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
			return;
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
		bytes = ir_emit_ptr_offset(proc, bytes, ir_const_int(byte_index));


		if (bit_inset == 0) {
			irValue *v = value;
			i32 sa = 8*size_in_bytes - size_in_bits;
			if (sa > 0) {
				irValue *shift_amount = ir_const_int(sa);
				v = ir_emit_arith(proc, Token_Shl, v, shift_amount, int_type);
				v = ir_emit_arith(proc, Token_Shr, v, shift_amount, int_type);
			}
			irValue *ptr = ir_emit_conv(proc, bytes, alloc_type_pointer(int_type));


			irValue *sv = ir_emit_load(proc, ptr, 1);
			// NOTE(bill): Zero out the lower bits that need to be stored to
			sv = ir_emit_arith(proc, Token_Shr, sv, ir_const_int(size_in_bits), int_type);
			sv = ir_emit_arith(proc, Token_Shl, sv, ir_const_int(size_in_bits), int_type);

			v = ir_emit_arith(proc, Token_Or, sv, v, int_type);
			ir_emit_store(proc, ptr, v, true);
			return;
		}

		GB_ASSERT(0 < bit_inset && bit_inset < 8);

		// First byte
		{
			irValue *shift_amount = ir_const_int(bit_inset);

			irValue *ptr = ir_emit_conv(proc, bytes, alloc_type_pointer(t_u8));

			irValue *v = ir_emit_conv(proc, value, t_u8);
			v = ir_emit_arith(proc, Token_Shl, v, shift_amount, t_u8);

			irValue *sv = ir_emit_load(proc, bytes, 1);
			// NOTE(bill): Zero out the upper bits that need to be stored to
			sv = ir_emit_arith(proc, Token_Shl, sv, ir_const_int(8-bit_inset), t_u8);
			sv = ir_emit_arith(proc, Token_Shr, sv, ir_const_int(8-bit_inset), t_u8);

			v = ir_emit_arith(proc, Token_Or, sv, v, t_u8);
			ir_emit_store(proc, ptr, v, true);
		}

		// Remaining bytes
		if (bit_inset+size_in_bits > 8) {
			irValue *ptr = ir_emit_conv(proc, ir_emit_ptr_offset(proc, bytes, v_one), alloc_type_pointer(int_type));
			irValue *v = ir_emit_conv(proc, value, int_type);
			v = ir_emit_arith(proc, Token_Shr, v, ir_const_int(8-bit_inset), int_type);

			irValue *sv = ir_emit_load(proc, ptr, 1);
			// NOTE(bill): Zero out the lower bits that need to be stored to
			sv = ir_emit_arith(proc, Token_Shr, sv, ir_const_int(size_in_bits-bit_inset), int_type);
			sv = ir_emit_arith(proc, Token_Shl, sv, ir_const_int(size_in_bits-bit_inset), int_type);

			v = ir_emit_arith(proc, Token_Or, sv, v, int_type);
			ir_emit_store(proc, ptr, v, true);
		}
		return;
	} else if (addr.kind == irAddr_Context) {
		irValue *old = ir_emit_load(proc, ir_find_or_generate_context_ptr(proc));
		irValue *next = ir_add_local_generated(proc, t_context, true);
		ir_emit_store(proc, next, old);
		ir_push_context_onto_stack(proc, next);

		if (addr.ctx.sel.index.count > 0) {
			irValue *lhs = ir_emit_deep_field_gep(proc, next, addr.ctx.sel);
			irValue *rhs = ir_emit_conv(proc, value, type_deref(ir_type(lhs)));
			ir_emit_store(proc, lhs, rhs);
		} else {
			irValue *lhs = next;
			irValue *rhs = ir_emit_conv(proc, value, ir_addr_type(addr));
			ir_emit_store(proc, lhs, rhs);
		}

		return;
	} else if (addr.kind == irAddr_SoaVariable) {
		Type *t = type_deref(ir_type(addr.addr));
		t = base_type(t);
		GB_ASSERT(t->kind == Type_Struct && t->Struct.soa_kind != StructSoa_None);
		value = ir_emit_conv(proc, value, t->Struct.soa_elem);

		irValue *index = addr.soa.index;
		if (index->kind != irValue_Constant || t->Struct.soa_kind != StructSoa_Fixed) {
			Type *t = base_type(type_deref(ir_type(addr.addr)));
			GB_ASSERT(t->kind == Type_Struct && t->Struct.soa_kind != StructSoa_None);
			i64 count = t->Struct.soa_count;
			irValue *len = ir_const_int(count);
			ir_emit_bounds_check(proc, ast_token(addr.soa.index_expr), index, len);
		}

		for_array(i, t->Struct.fields) {
			irValue *dst = ir_emit_struct_ep(proc, addr.addr, cast(i32)i);
			dst = ir_emit_array_ep(proc, dst, index);
			irValue *src = ir_emit_struct_ev(proc, value, cast(i32)i);
			ir_emit_store(proc, dst, src);
		}
		return;
	}

	irValue *v = ir_emit_conv(proc, value, ir_addr_type(addr));
	ir_emit_store(proc, addr.addr, v);
}

irValue *ir_addr_load(irProcedure *proc, irAddr const &addr) {
	if (addr.addr == nullptr) {
		GB_PANIC("Illegal addr load");
		return nullptr;
	}

	if (addr.kind == irAddr_Map) {
		// TODO(bill): map lookup
		Type *map_type = base_type(addr.map_type);
		irValue *v = ir_add_local_generated(proc, map_type->Map.lookup_result_type, true);
		irValue *h = ir_gen_map_header(proc, addr.addr, map_type);
		irValue *key = ir_gen_map_key(proc, addr.map_key, map_type->Map.key);

		auto args = array_make<irValue *>(ir_allocator(), 2);
		args[0] = h;
		args[1] = key;

		irValue *ptr = ir_emit_runtime_call(proc, "__dynamic_map_get", args);
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
		gbAllocator a = ir_allocator();


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
			return v_zero32;
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
		bytes = ir_emit_ptr_offset(proc, bytes, ir_const_int(byte_index));

		Type *int_ptr = alloc_type_pointer(int_type);

		i32 sa = 8*size_in_bytes - size_in_bits;
		if (bit_inset == 0) {
			irValue *v = ir_emit_load(proc, ir_emit_conv(proc, bytes, int_ptr), 1);
			if (sa > 0) {
				irValue *shift_amount = ir_const_int(sa);
				v = ir_emit_arith(proc, Token_Shl, v, shift_amount, int_type);
				v = ir_emit_arith(proc, Token_Shr, v, shift_amount, int_type);
			}
			return v;
		}

		GB_ASSERT(8 > bit_inset);

		irValue *ptr = ir_emit_conv(proc, bytes, int_ptr);
		irValue *v = ir_emit_load(proc, ptr, 1);
		v = ir_emit_arith(proc, Token_Shr, v, ir_const_int(bit_inset), int_type);
		if (sa > 0) {
			irValue *shift_amount = ir_const_int(sa);
			v = ir_emit_arith(proc, Token_Shl, v, shift_amount, int_type);
			v = ir_emit_arith(proc, Token_Shr, v, shift_amount, int_type);
		}
		return v;
	} else if (addr.kind == irAddr_Context) {
		if (addr.ctx.sel.index.count > 0) {
			irValue *a = addr.addr;
			irValue *b = ir_emit_deep_field_gep(proc, a, addr.ctx.sel);
			return ir_emit_load(proc, b);
		}
	} else if (addr.kind == irAddr_SoaVariable) {
		Type *t = type_deref(ir_type(addr.addr));
		t = base_type(t);
		GB_ASSERT(t->kind == Type_Struct && t->Struct.soa_kind != StructSoa_None);
		Type *elem = t->Struct.soa_elem;

		irValue *len = nullptr;
		if (t->Struct.soa_kind == StructSoa_Fixed) {
			len = ir_const_int(t->Struct.soa_count);
		} else {
			irValue *v = ir_emit_load(proc, addr.addr);
			len = ir_soa_struct_len(proc, v);
		}

		irValue *res = ir_add_local_generated(proc, elem, true);

		if (addr.soa.index->kind != irValue_Constant || t->Struct.soa_kind != StructSoa_Fixed) {
			ir_emit_bounds_check(proc, ast_token(addr.soa.index_expr), addr.soa.index, len);
		}

		if (t->Struct.soa_kind == StructSoa_Fixed) {
			for_array(i, t->Struct.fields) {
				Entity *field = t->Struct.fields[i];
				Type *base_type = field->type;
				GB_ASSERT(base_type->kind == Type_Array);

				irValue *dst = ir_emit_struct_ep(proc, res, cast(i32)i);
				irValue *src_ptr = ir_emit_struct_ep(proc, addr.addr, cast(i32)i);
				src_ptr = ir_emit_array_ep(proc, src_ptr, addr.soa.index);
				irValue *src = ir_emit_load(proc, src_ptr);
				ir_emit_store(proc, dst, src);
			}
		} else {
			isize field_count = t->Struct.fields.count;
			if (t->Struct.soa_kind == StructSoa_Slice) {
				field_count -= 1;
			} else if (t->Struct.soa_kind == StructSoa_Dynamic) {
				field_count -= 3;
			}
			for (isize i = 0; i < field_count; i++) {
				Entity *field = t->Struct.fields[i];
				Type *base_type = field->type;
				GB_ASSERT(base_type->kind == Type_Pointer);
				Type *elem = base_type->Pointer.elem;

				irValue *dst = ir_emit_struct_ep(proc, res, cast(i32)i);
				irValue *src_ptr = ir_emit_struct_ep(proc, addr.addr, cast(i32)i);
				src_ptr = ir_emit_ptr_offset(proc, src_ptr, addr.soa.index);
				irValue *src = ir_emit_load(proc, src_ptr);
				src = ir_emit_load(proc, src);
				ir_emit_store(proc, dst, src);
			}
		}

		return ir_emit_load(proc, res);
	}

	Type *t = base_type(ir_type(addr.addr));
	if (t->kind == Type_Proc) {
		// NOTE(bill): Imported procedures don't require a load as they are pointers
		return addr.addr;
	}
	return ir_emit_load(proc, addr.addr);
}

irValue *ir_addr_get_ptr(irProcedure *proc, irAddr const &addr) {
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

	case irAddr_Context:
		GB_PANIC("irAddr_Context should be handled elsewhere");
	}

	return addr.addr;
}

irValue *ir_build_addr_ptr(irProcedure *proc, Ast *expr) {
	irAddr addr = ir_build_addr(proc, expr);
	return ir_addr_get_ptr(proc, addr);
}


irValue *ir_dynamic_array_len(irProcedure *proc, irValue *da);
irValue *ir_dynamic_array_cap(irProcedure *proc, irValue *da);


irValue *ir_map_entries(irProcedure *proc, irValue *value) {
	gbAllocator a = ir_allocator();
	Type *t = base_type(ir_type(value));
	GB_ASSERT_MSG(t->kind == Type_Map, "%s", type_to_string(t));
	init_map_internal_types(t);
	Type *gst = t->Map.generated_struct_type;
	i32 index = 1;
	irValue *entries = ir_emit(proc, ir_instr_struct_extract_value(proc, value, index, gst->Struct.fields[index]->type));
	return entries;
}

irValue *ir_map_entries_ptr(irProcedure *proc, irValue *value) {
	gbAllocator a = ir_allocator();
	Type *t = base_type(type_deref(ir_type(value)));
	GB_ASSERT_MSG(t->kind == Type_Map, "%s", type_to_string(t));
	init_map_internal_types(t);
	Type *gst = t->Map.generated_struct_type;
	i32 index = 1;
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




struct irLoopData {
	irValue *idx_addr;
	irValue *idx;
	irBlock *body;
	irBlock *done;
	irBlock *loop;
};

irLoopData ir_loop_start(irProcedure *proc, isize count, Type *index_type=t_int) {
	irLoopData data = {};

	irValue *max = ir_const_int(count);

	data.idx_addr = ir_add_local_generated(proc, index_type, true);

	data.body = ir_new_block(proc, nullptr, "loop.body");
	data.done = ir_new_block(proc, nullptr, "loop.done");
	data.loop = ir_new_block(proc, nullptr, "loop.loop");

	ir_emit_jump(proc, data.loop);
	ir_start_block(proc, data.loop);

	data.idx = ir_emit_load(proc, data.idx_addr);

	irValue *cond = ir_emit_comp(proc, Token_Lt, data.idx, max);
	ir_emit_if(proc, cond, data.body, data.done);
	ir_start_block(proc, data.body);

	return data;
}

void ir_loop_end(irProcedure *proc, irLoopData const &data) {
	if (data.idx_addr != nullptr) {
		ir_emit_increment(proc, data.idx_addr);
		ir_emit_jump(proc, data.loop);
		ir_start_block(proc, data.done);
	}
}




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

		// NOTE(bill): Doesn't need to be zero because it will be initialized in the loops
		irValue *res = ir_add_local_generated(proc, type, false);

		bool inline_array_arith = type_size_of(type) <= build_context.max_align;

		i32 count = cast(i32)tl->Array.count;

		if (inline_array_arith) {
			// inline
			for (i32 i = 0; i < count; i++) {
				irValue *e = ir_emit_load(proc, ir_emit_array_epi(proc, val, i));
				irValue *z = ir_emit_unary_arith(proc, op, e, elem_type);
				ir_emit_store(proc, ir_emit_array_epi(proc, res, i), z);
			}
		} else {
			auto loop_data = ir_loop_start(proc, count, t_i32);

			irValue *e = ir_emit_load(proc, ir_emit_array_ep(proc, val, loop_data.idx));
			irValue *z = ir_emit_unary_arith(proc, op, e, elem_type);
			ir_emit_store(proc, ir_emit_array_ep(proc, res, loop_data.idx), z);

			ir_loop_end(proc, loop_data);
		}
		ir_emit_comment(proc, str_lit("array.arith.end"));
		return ir_emit_load(proc, res);

	}

	if (op == Token_Not) {
		irValue *cmp = ir_emit_comp(proc, Token_CmpEq, x, v_false);
		return ir_emit_conv(proc, cmp, type);
	}

	if (op == Token_Sub && is_type_integer(type) && is_type_different_to_arch_endianness(type)) {
		Type *platform_type = integer_endian_type_to_platform_type(type);
		irValue *v = ir_emit_byte_swap(proc, x, platform_type);
		irValue *res = ir_emit(proc, ir_instr_unary_op(proc, op, v, platform_type));
		return ir_emit_byte_swap(proc, res, type);
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

		// NOTE(bill): Doesn't need to be zero because it will be initialized in the loops
		irValue *res = ir_add_local_generated(proc, type, false);
		i64 count = base_type(type)->Array.count;

		bool inline_array_arith = type_size_of(type) <= build_context.max_align;

		if (inline_array_arith) {
			// inline
			for (i32 i = 0; i < count; i++) {
				irValue *x = ir_emit_load(proc, ir_emit_array_epi(proc, lhs, i));
				irValue *y = ir_emit_load(proc, ir_emit_array_epi(proc, rhs, i));
				irValue *z = ir_emit_arith(proc, op, x, y, elem_type);
				ir_emit_store(proc, ir_emit_array_epi(proc, res, i), z);
			}
		} else {
			auto loop_data = ir_loop_start(proc, count, t_i32);

			irValue *x = ir_emit_load(proc, ir_emit_array_ep(proc, lhs, loop_data.idx));
			irValue *y = ir_emit_load(proc, ir_emit_array_ep(proc, rhs, loop_data.idx));
			irValue *z = ir_emit_arith(proc, op, x, y, elem_type);
			ir_emit_store(proc, ir_emit_array_ep(proc, res, loop_data.idx), z);

			ir_loop_end(proc, loop_data);
		}
		ir_emit_comment(proc, str_lit("array.arith.end"));
		return ir_emit_load(proc, res);
	}

	if (is_type_complex(t_left)) {
		ir_emit_comment(proc, str_lit("complex.arith.begin"));
		defer (ir_emit_comment(proc, str_lit("complex.arith.end")));

		Type *ft = base_complex_elem_type(t_left);

		if (op == Token_Quo) {
			auto args = array_make<irValue *>(heap_allocator(), 2);
			args[0] = left;
			args[1] = right;

			switch (type_size_of(ft)) {
			case 4: return ir_emit_runtime_call(proc, "quo_complex64", args);
			case 8: return ir_emit_runtime_call(proc, "quo_complex128", args);
			default: GB_PANIC("Unknown float type"); break;
			}
		}

		irValue *res = ir_add_local_generated(proc, type, false); // NOTE: initialized in full later
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
		}

		ir_emit_store(proc, ir_emit_struct_ep(proc, res, 0), real);
		ir_emit_store(proc, ir_emit_struct_ep(proc, res, 1), imag);

		return ir_emit_load(proc, res);
	}

	if (is_type_quaternion(t_left)) {
		ir_emit_comment(proc, str_lit("complex.arith.begin"));
		defer (ir_emit_comment(proc, str_lit("complex.arith.end")));

		right = ir_emit_conv(proc, right, t_left);

		Type *ft = base_complex_elem_type(t_left);

		if (op == Token_Add || op == Token_Sub) {
			irValue *res = ir_add_local_generated(proc, type, false); // NOTE: initialized in full later
			irValue *x0 = ir_emit_struct_ev(proc, left,  0);
			irValue *x1 = ir_emit_struct_ev(proc, left,  1);
			irValue *x2 = ir_emit_struct_ev(proc, left,  2);
			irValue *x3 = ir_emit_struct_ev(proc, left,  3);

			irValue *y0 = ir_emit_struct_ev(proc, right, 0);
			irValue *y1 = ir_emit_struct_ev(proc, right, 1);
			irValue *y2 = ir_emit_struct_ev(proc, right, 2);
			irValue *y3 = ir_emit_struct_ev(proc, right, 3);

			irValue *z0 = ir_emit_arith(proc, op, x0, y0, ft);
			irValue *z1 = ir_emit_arith(proc, op, x1, y1, ft);
			irValue *z2 = ir_emit_arith(proc, op, x2, y2, ft);
			irValue *z3 = ir_emit_arith(proc, op, x3, y3, ft);

			ir_emit_store(proc, ir_emit_struct_ep(proc, res, 0), z0);
			ir_emit_store(proc, ir_emit_struct_ep(proc, res, 1), z1);
			ir_emit_store(proc, ir_emit_struct_ep(proc, res, 2), z2);
			ir_emit_store(proc, ir_emit_struct_ep(proc, res, 3), z3);

			return ir_emit_load(proc, res);
		} else if (op == Token_Mul) {
			auto args = array_make<irValue *>(heap_allocator(), 2);
			args[0] = left;
			args[1] = right;

			switch (8*type_size_of(ft)) {
			case 32: return ir_emit_runtime_call(proc, "mul_quaternion128", args);
			case 64: return ir_emit_runtime_call(proc, "mul_quaternion256", args);
			default: GB_PANIC("Unknown float type"); break;
			}
		} else if (op == Token_Quo) {
			auto args = array_make<irValue *>(heap_allocator(), 2);
			args[0] = left;
			args[1] = right;

			switch (8*type_size_of(ft)) {
			case 32: return ir_emit_runtime_call(proc, "quo_quaternion128", args);
			case 64: return ir_emit_runtime_call(proc, "quo_quaternion256", args);
			default: GB_PANIC("Unknown float type"); break;
			}
		}
	}


#if 0
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
			irValue *elem_size = ir_const_int(type_size_of(ptr_type->Pointer.elem));
			irValue *x = ir_emit_conv(proc, ir_emit_conv(proc, left, t_uintptr), type);
			irValue *y = ir_emit_conv(proc, ir_emit_conv(proc, right, t_uintptr), type);
			irValue *diff = ir_emit_arith(proc, op, x, y, type);
			return ir_emit_arith(proc, Token_Quo, diff, elem_size, type);
		}
	}
#endif

	if (is_type_integer(type) && is_type_different_to_arch_endianness(type)) {
		switch (op) {
		case Token_AndNot:
		case Token_And:
		case Token_Or:
		case Token_Xor:
			goto handle_op;
		}
		Type *platform_type = integer_endian_type_to_platform_type(type);
		irValue *x = ir_emit_byte_swap(proc, left, integer_endian_type_to_platform_type(t_left));
		irValue *y = ir_emit_byte_swap(proc, right, integer_endian_type_to_platform_type(t_right));

		irValue *res = ir_emit_arith(proc, op, x, y, platform_type);

		return ir_emit_byte_swap(proc, res, type);
	}

handle_op:
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
		if (is_type_unsigned(type)) {
			op = Token_Mod;
		} else {
			irValue *a = ir_emit_arith(proc, Token_Mod, left, right, type);
			irValue *b = ir_emit_arith(proc, Token_Add, a,    right, type);
			return ir_emit_arith(proc, Token_Mod, b, right, type);
		}
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
	if (is_type_pointer(t)) {
		return ir_emit_comp(proc, op_kind, x, v_raw_nil);
	} else if (is_type_cstring(t)) {
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
		if (type_size_of(t) == 0) {
			return ir_emit_comp(proc, op_kind, v_zero, v_zero);
		} else {
			irValue *tag = ir_emit_union_tag_value(proc, x);
			return ir_emit_comp(proc, op_kind, tag, v_zero);
		}
	} else if (is_type_typeid(t)) {
		irValue *invalid_typeid = ir_value_constant(t_typeid, exact_value_i64(0));
		return ir_emit_comp(proc, op_kind, x, invalid_typeid);
	} else if (is_type_bit_field(t)) {
		auto args = array_make<irValue *>(heap_allocator(), 2);
		irValue *lhs = ir_address_from_load_or_generate_local(proc, x);
		args[0] = ir_emit_conv(proc, lhs, t_rawptr);
		args[1] = ir_const_int(type_size_of(t));
		irValue *val = ir_emit_runtime_call(proc, "memory_compare_zero", args);
		irValue *res = ir_emit_comp(proc, op_kind, val, v_zero);
		return ir_emit_conv(proc, res, t_bool);
	} else if (is_type_soa_struct(t)) {
		Type *bt = base_type(t);
		if (bt->Struct.soa_kind == StructSoa_Slice) {
			ir_emit_comment(proc, str_lit("soa-slice-nil-comp"));
			irValue *len  = ir_soa_struct_len(proc, x);
			if (bt->Struct.fields.count > 1) {
				irValue *data = ir_emit_struct_ev(proc, x, 0);
				if (op_kind == Token_CmpEq) {
					irValue *a = ir_emit_comp(proc, Token_CmpEq, data, v_raw_nil);
					irValue *b = ir_emit_comp(proc, Token_CmpEq, len, v_zero);
					return ir_emit_arith(proc, Token_Or, a, b, t_bool);
				} else if (op_kind == Token_NotEq) {
					irValue *a = ir_emit_comp(proc, Token_NotEq, data, v_raw_nil);
					irValue *b = ir_emit_comp(proc, Token_NotEq, len, v_zero);
					return ir_emit_arith(proc, Token_And, a, b, t_bool);
				}
			} else {
				return ir_emit_comp(proc, op_kind, len, v_zero);
			}
		} else if (bt->Struct.soa_kind == StructSoa_Dynamic) {
			ir_emit_comment(proc, str_lit("soa-dynamic-array-nil-comp"));

			irValue *cap  = ir_soa_struct_len(proc, x);
			if (bt->Struct.fields.count > 1) {
				irValue *data = ir_emit_struct_ev(proc, x, 0);
				if (op_kind == Token_CmpEq) {
					irValue *a = ir_emit_comp(proc, Token_CmpEq, data, v_raw_nil);
					irValue *b = ir_emit_comp(proc, Token_CmpEq, cap, v_zero);
					return ir_emit_arith(proc, Token_Or, a, b, t_bool);
				} else if (op_kind == Token_NotEq) {
					irValue *a = ir_emit_comp(proc, Token_NotEq, data, v_raw_nil);
					irValue *b = ir_emit_comp(proc, Token_NotEq, cap, v_zero);
					return ir_emit_arith(proc, Token_And, a, b, t_bool);
				}
			} else {
				return ir_emit_comp(proc, op_kind, cap, v_zero);
			}
		}
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
		gbAllocator a = ir_allocator();

		Type *lt = ir_type(left);
		Type *rt = ir_type(right);

		if (is_type_bit_set(lt) && is_type_bit_set(rt)) {
			Type *blt = base_type(lt);
			Type *brt = base_type(rt);
			GB_ASSERT(is_type_bit_field_value(blt));
			GB_ASSERT(is_type_bit_field_value(brt));
			i64 bits = gb_max(blt->BitFieldValue.bits, brt->BitFieldValue.bits);
			i64 bytes = bits / 8;
			switch (bytes) {
			case 1:
				left = ir_emit_conv(proc, left, t_u8);
				right = ir_emit_conv(proc, right, t_u8);
				break;
			case 2:
				left = ir_emit_conv(proc, left, t_u16);
				right = ir_emit_conv(proc, right, t_u16);
				break;
			case 4:
				left = ir_emit_conv(proc, left, t_u32);
				right = ir_emit_conv(proc, right, t_u32);
				break;
			case 8:
				left = ir_emit_conv(proc, left, t_u64);
				right = ir_emit_conv(proc, right, t_u64);
				break;
			default: GB_PANIC("Unknown integer size"); break;
			}
		}

		lt = ir_type(left);
		rt = ir_type(right);
		i64 ls = type_size_of(lt);
		i64 rs = type_size_of(rt);
		if (ls < rs) {
			left = ir_emit_conv(proc, left, rt);
		} else if (ls > rs) {
			right = ir_emit_conv(proc, right, lt);
		} else {
			right = ir_emit_conv(proc, right, lt);
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
		} else if (op_kind == Token_CmpEq) {
			res = v_true;
			cmp_op = Token_And;
		}

		bool inline_array_arith = type_size_of(tl) <= build_context.max_align;
		i32 count = cast(i32)tl->Array.count;

		if (inline_array_arith) {
			// inline
			irValue *val = ir_add_local_generated(proc, t_bool, false);
			ir_emit_store(proc, val, res);
			for (i32 i = 0; i < count; i++) {
				irValue *x = ir_emit_load(proc, ir_emit_array_epi(proc, lhs, i));
				irValue *y = ir_emit_load(proc, ir_emit_array_epi(proc, rhs, i));
				irValue *cmp = ir_emit_comp(proc, op_kind, x, y);
				irValue *new_res = ir_emit_arith(proc, cmp_op, ir_emit_load(proc, val), cmp, t_bool);
				ir_emit_store(proc, val, ir_emit_conv(proc, new_res, t_bool));
			}

			return ir_emit_load(proc, val);
		} else {
			if (is_type_simple_compare(tl) && (op_kind == Token_CmpEq || op_kind == Token_NotEq)) {
				// TODO(bill): Test to see if this is actually faster!!!!
				auto args = array_make<irValue *>(heap_allocator(), 3);
				args[0] = ir_emit_conv(proc, lhs, t_rawptr);
				args[1] = ir_emit_conv(proc, rhs, t_rawptr);
				args[2] = ir_const_int(type_size_of(tl));
				irValue *val = ir_emit_runtime_call(proc, "memory_compare", args);
				irValue *res = ir_emit_comp(proc, op_kind, val, v_zero);
				return ir_emit_conv(proc, res, t_bool);
			} else {
				irValue *val = ir_add_local_generated(proc, t_bool, false);
				ir_emit_store(proc, val, res);
				auto loop_data = ir_loop_start(proc, count, t_i32);
				{
					irValue *i = loop_data.idx;
					irValue *x = ir_emit_load(proc, ir_emit_array_ep(proc, lhs, i));
					irValue *y = ir_emit_load(proc, ir_emit_array_ep(proc, rhs, i));
					irValue *cmp = ir_emit_comp(proc, op_kind, x, y);
					irValue *new_res = ir_emit_arith(proc, cmp_op, ir_emit_load(proc, val), cmp, t_bool);
					ir_emit_store(proc, val, ir_emit_conv(proc, new_res, t_bool));
				}
				ir_loop_end(proc, loop_data);

				return ir_emit_load(proc, val);
			}
		}
	}

	if (is_type_string(a)) {
		if (is_type_cstring(a)) {
			left  = ir_emit_conv(proc, left, t_string);
			right = ir_emit_conv(proc, right, t_string);
		}

		char const *runtime_proc = nullptr;
		switch (op_kind) {
		case Token_CmpEq: runtime_proc = "string_eq"; break;
		case Token_NotEq: runtime_proc = "string_ne"; break;
		case Token_Lt:    runtime_proc = "string_lt"; break;
		case Token_Gt:    runtime_proc = "string_gt"; break;
		case Token_LtEq:  runtime_proc = "string_le"; break;
		case Token_GtEq:  runtime_proc = "string_gt"; break;
		}
		GB_ASSERT(runtime_proc != nullptr);

		auto args = array_make<irValue *>(ir_allocator(), 2);
		args[0] = left;
		args[1] = right;
		return ir_emit_runtime_call(proc, runtime_proc, args);
	}

	if (is_type_complex(a)) {
		char const *runtime_proc = "";
		i64 sz = 8*type_size_of(a);
		switch (sz) {
		case 64:
			switch (op_kind) {
			case Token_CmpEq: runtime_proc = "complex64_eq"; break;
			case Token_NotEq: runtime_proc = "complex64_ne"; break;
			}
			break;
		case 128:
			switch (op_kind) {
			case Token_CmpEq: runtime_proc = "complex128_eq"; break;
			case Token_NotEq: runtime_proc = "complex128_ne"; break;
			}
			break;
		}
		GB_ASSERT(runtime_proc != nullptr);

		auto args = array_make<irValue *>(ir_allocator(), 2);
		args[0] = left;
		args[1] = right;
		return ir_emit_runtime_call(proc, runtime_proc, args);
	}

	if (is_type_quaternion(a)) {
		char const *runtime_proc = "";
		i64 sz = 8*type_size_of(a);
		switch (sz) {
		case 128:
			switch (op_kind) {
			case Token_CmpEq: runtime_proc = "quaternion128_eq"; break;
			case Token_NotEq: runtime_proc = "quaternion128_ne"; break;
			}
			break;
		case 256:
			switch (op_kind) {
			case Token_CmpEq: runtime_proc = "quaternion256_eq"; break;
			case Token_NotEq: runtime_proc = "quaternion256_ne"; break;
			}
			break;
		}
		GB_ASSERT(runtime_proc != nullptr);

		auto args = array_make<irValue *>(ir_allocator(), 2);
		args[0] = left;
		args[1] = right;
		return ir_emit_runtime_call(proc, runtime_proc, args);
	}

	if (is_type_bit_set(a)) {
		switch (op_kind) {
		case Token_Lt:
		case Token_LtEq:
		case Token_Gt:
		case Token_GtEq:
			{
				Type *it = bit_set_to_int(a);
				irValue *lhs = ir_emit_bitcast(proc, left, it);
				irValue *rhs = ir_emit_bitcast(proc, right, it);
				irValue *res = ir_emit_arith(proc, Token_And, lhs, rhs, it);

				if (op_kind == Token_Lt || op_kind == Token_LtEq) {
					// (lhs & rhs) == lhs
					res = ir_emit(proc, ir_instr_binary_op(proc, Token_CmpEq, res, lhs, t_llvm_bool));
				} else if (op_kind == Token_Gt || op_kind == Token_GtEq) {
					// (lhs & rhs) == rhs
					res = ir_emit(proc, ir_instr_binary_op(proc, Token_CmpEq, res, rhs, t_llvm_bool));
				}

				// NOTE(bill): Strict subsets
				if (op_kind == Token_Lt || op_kind == Token_Gt) {
					// res &~ (lhs == rhs)
					irValue *eq = ir_emit(proc, ir_instr_binary_op(proc, Token_CmpEq, lhs, rhs, t_llvm_bool));
					res = ir_emit_arith(proc, Token_AndNot, res, eq, t_llvm_bool);
				}

				return res;
			}
		}
	}

	if (op_kind != Token_CmpEq && op_kind != Token_NotEq) {
		Type *t = ir_type(left);
		if (is_type_integer(t) && is_type_different_to_arch_endianness(t)) {
			Type *platform_type = integer_endian_type_to_platform_type(t);
			irValue *x = ir_emit_byte_swap(proc, left, platform_type);
			irValue *y = ir_emit_byte_swap(proc, right, platform_type);
			return ir_emit(proc, ir_instr_binary_op(proc, op_kind, x, y, t_llvm_bool));
		}
	}

	return ir_emit(proc, ir_instr_binary_op(proc, op_kind, left, right, t_llvm_bool));
}

irValue *ir_emit_array_ep(irProcedure *proc, irValue *s, irValue *index) {
	GB_ASSERT(index != nullptr);
	Type *t = ir_type(s);
	GB_ASSERT(is_type_pointer(t));
	Type *st = base_type(type_deref(t));
	GB_ASSERT_MSG(is_type_array(st) || is_type_enumerated_array(st), "%s", type_to_string(st));

	// NOTE(bill): For some weird legacy reason in LLVM, structure elements must be accessed as an i32
	index = ir_emit_conv(proc, index, t_i32);
	return ir_emit(proc, ir_instr_array_element_ptr(proc, s, index));
}

irValue *ir_emit_array_epi(irProcedure *proc, irValue *s, i32 index) {
	return ir_emit_array_ep(proc, s, ir_const_i32(index));
}



irValue *ir_emit_struct_ep(irProcedure *proc, irValue *s, i32 index) {
	gbAllocator a = ir_allocator();
	GB_ASSERT(is_type_pointer(ir_type(s)));
	Type *t = base_type(type_deref(ir_type(s)));
	Type *result_type = nullptr;

	if (t->kind == Type_Opaque) {
		t = t->Opaque.elem;
	}

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
	} else if (is_type_quaternion(t)) {
		Type *ft = base_complex_elem_type(t);
		switch (index) {
		case 0: result_type = alloc_type_pointer(ft); break;
		case 1: result_type = alloc_type_pointer(ft); break;
		case 2: result_type = alloc_type_pointer(ft); break;
		case 3: result_type = alloc_type_pointer(ft); break;
		}
	} else if (is_type_slice(t)) {
		switch (index) {
		case 0: result_type = alloc_type_pointer(alloc_type_pointer(t->Slice.elem)); break;
		case 1: result_type = alloc_type_pointer(t_int); break;
		}
	} else if (is_type_string(t)) {
		switch (index) {
		case 0: result_type = alloc_type_pointer(t_u8_ptr); break;
		case 1: result_type = alloc_type_pointer(t_int);    break;
		}
	} else if (is_type_any(t)) {
		switch (index) {
		case 0: result_type = alloc_type_pointer(t_rawptr); break;
		case 1: result_type = alloc_type_pointer(t_typeid); break;
		}
	} else if (is_type_dynamic_array(t)) {
		switch (index) {
		case 0: result_type = alloc_type_pointer(alloc_type_pointer(t->DynamicArray.elem)); break;
		case 1: result_type = t_int_ptr;       break;
		case 2: result_type = t_int_ptr;       break;
		case 3: result_type = t_allocator_ptr; break;
		}
	} else if (is_type_map(t)) {
		init_map_internal_types(t);
		Type *itp = alloc_type_pointer(t->Map.internal_type);
		s = ir_emit_transmute(proc, s, itp);

		Type *gst = t->Map.internal_type;
		GB_ASSERT(gst->kind == Type_Struct);
		switch (index) {
		case 0: result_type = alloc_type_pointer(gst->Struct.fields[0]->type); break;
		case 1: result_type = alloc_type_pointer(gst->Struct.fields[1]->type); break;
		}
	} else if (is_type_array(t)) {
		return ir_emit_array_epi(proc, s, index);
	} else {
		GB_PANIC("TODO(bill): struct_gep type: %s, %d", type_to_string(ir_type(s)), index);
	}

	GB_ASSERT_MSG(result_type != nullptr, "%s %d", type_to_string(t), index);

	return ir_emit(proc, ir_instr_struct_element_ptr(proc, s, index, result_type));
}


irValue *ir_emit_struct_ev(irProcedure *proc, irValue *s, i32 index) {
	// NOTE(bill): For some weird legacy reason in LLVM, structure elements must be accessed as an i32

	if (s->kind == irValue_Instr) {
		if (s->Instr.kind == irInstr_Load) {
			irValue *addr = s->Instr.Load.address;
			irValue *ptr = ir_emit_struct_ep(proc, addr, index);
			return ir_emit_load(proc, ptr);
		}
	}

	gbAllocator a = ir_allocator();
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
			case 0: result_type = t_rawptr; break;
			case 1: result_type = t_typeid; break;
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
		case Basic_quaternion128: case Basic_quaternion256:
		{
			Type *ft = base_complex_elem_type(t);
			switch (index) {
			case 0: result_type = ft; break;
			case 1: result_type = ft; break;
			case 2: result_type = ft; break;
			case 3: result_type = ft; break;
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
		case 1: result_type = t_int;                                    break;
		case 2: result_type = t_int;                                    break;
		case 3: result_type = t_allocator;                              break;
		}
		break;

	case Type_Map:
		{
			init_map_internal_types(t);
			Type *gst = t->Map.generated_struct_type;
			switch (index) {
			case 0: result_type = gst->Struct.fields[0]->type; break;
			case 1: result_type = gst->Struct.fields[1]->type; break;
			}
		}
		break;

	case Type_Array:
		result_type = t->Array.elem;
		break;

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
	gbAllocator a = ir_allocator();

	for_array(i, sel.index) {
		i32 index = cast(i32)sel.index[i];
		if (is_type_pointer(type)) {
			type = type_deref(type);
			e = ir_emit_load(proc, e);
			// e = ir_emit_ptr_offset(proc, e, v_zero); // TODO(bill): Do I need these copies?
		}
		type = core_type(type);
		if (type->kind == Type_Opaque) {
			type = type->Opaque.elem;
		}

		if (is_type_quaternion(type)) {
			e = ir_emit_struct_ep(proc, e, index);
		} else if (is_type_raw_union(type)) {
			type = type->Struct.fields[index]->type;
			GB_ASSERT(is_type_pointer(ir_type(e)));
			e = ir_emit_bitcast(proc, e, alloc_type_pointer(type));
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
			e = ir_emit_struct_ep(proc, e, index);
		} else {
			GB_PANIC("un-gep-able type %s", type_to_string(type));
		}
	}

	return e;
}


irValue *ir_emit_deep_field_ev(irProcedure *proc, irValue *e, Selection sel) {
	GB_ASSERT(sel.index.count > 0);

	if (e->kind == irValue_Instr) {
		if (e->Instr.kind == irInstr_Load) {
			irValue *addr = e->Instr.Load.address;
			irValue *ptr = ir_emit_deep_field_gep(proc, addr, sel);
			return ir_emit_load(proc, ptr);
		}
	}

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
	return ir_const_int(t->Array.count);
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
	auto args = array_make<irValue *>(ir_allocator(), 1);
	args[0] = ir_emit_conv(proc, value, t_cstring);
	return ir_emit_runtime_call(proc, "cstring_len", args);
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
	irValue *str = ir_add_local_generated(proc, t_string, false);
	ir_fill_string(proc, str, elem, len);
	return ir_emit_load(proc, str);
}


irValue *ir_add_local_slice(irProcedure *proc, Type *slice_type, irValue *base, irValue *low, irValue *high) {
	// TODO(bill): array bounds checking for slice creation
	// TODO(bill): check that low < high <= max
	gbAllocator a = ir_allocator();
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

	irValue *slice = ir_add_local_generated(proc, slice_type, false);
	ir_fill_slice(proc, slice, elem, len);
	return slice;
}



irValue *ir_find_or_add_entity_string(irModule *m, String str) {
	HashKey key = hash_string(str);
	irValue **found = map_get(&m->const_strings, key);
	if (found != nullptr) {
		return *found;
	}
	irValue *v = ir_value_constant(t_string, exact_value_string(str));
	map_set(&m->const_strings, key, v);
	return v;

}

irValue *ir_find_or_add_entity_string_byte_slice(irModule *m, String str) {
	HashKey key = hash_string(str);
	irValue **found = map_get(&m->const_string_byte_slices, key);
	if (found != nullptr) {
		return *found;
	}
	Type *t = t_u8_slice;
	irValue *v = ir_value_constant(t, exact_value_string(str));
	map_set(&m->const_string_byte_slices, key, v);
	return v;

}


irValue *ir_const_union_tag(Type *u, Type *v) {
	return ir_value_constant(union_tag_type(u), exact_value_i64(union_variant_index(u, v)));
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

irValue *ir_emit_byte_swap(irProcedure *proc, irValue *value, Type *t) {
	Type *vt = core_type(ir_type(value));
	if (is_type_untyped(vt)) {
		return value;
	}
	GB_ASSERT(type_size_of(vt) == type_size_of(t));
	return ir_emit(proc, ir_instr_conv(proc, irConv_byteswap, value, vt, t));
}


void ir_emit_store_union_variant(irProcedure *proc, irValue *parent, irValue *variant, Type *variant_type) {
	gbAllocator a = ir_allocator();
	irValue *underlying = ir_emit_conv(proc, parent, alloc_type_pointer(variant_type));

	ir_emit_store(proc, underlying, variant);

	Type *t = type_deref(ir_type(parent));

	if (is_type_union_maybe_pointer(t)) {
		// No tag needed!
	} else {
		irValue *tag_ptr = ir_emit_union_tag_ptr(proc, parent);
		ir_emit_store(proc, tag_ptr, ir_const_union_tag(t, variant_type));
	}
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
		return ir_value_nil(t);
	}
	if (is_type_untyped_undef(src)) {
		return ir_value_undef(t);
	}

	if (value->kind == irValue_Constant) {
		if (is_type_any(dst)) {
			irValue *default_value = ir_add_local_generated(proc, default_type(src_type), false);
			ir_emit_store(proc, default_value, value);
			return ir_emit_conv(proc, ir_emit_load(proc, default_value), t_any);
		} else if (dst->kind == Type_Basic) {
			ExactValue ev = value->Constant.value;
			if (is_type_float(dst)) {
				ev = exact_value_to_float(ev);
			} else if (is_type_complex(dst)) {
				ev = exact_value_to_complex(ev);
			} else if (is_type_quaternion(dst)) {
				ev = exact_value_to_quaternion(ev);
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

		if (sz > 1 && is_type_different_to_arch_endianness(src)) {
			Type *platform_src_type = integer_endian_type_to_platform_type(src);
			value = ir_emit_byte_swap(proc, value, platform_src_type);
		}
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

		if (dz > 1 && is_type_different_to_arch_endianness(dst)) {
			Type *platform_dst_type = integer_endian_type_to_platform_type(dst);
			irValue *res = ir_emit(proc, ir_instr_conv(proc, kind, value, src_type, platform_dst_type));
			return ir_emit_byte_swap(proc, res, t);
		} else {
			return ir_emit(proc, ir_instr_conv(proc, kind, value, src_type, t));
		}
	}

	// boolean -> boolean/integer
	if (is_type_boolean(src) && (is_type_boolean(dst) || is_type_integer(dst))) {
		irValue *b = ir_emit(proc, ir_instr_binary_op(proc, Token_NotEq, value, v_zero, t_llvm_bool));
		return ir_emit(proc, ir_instr_conv(proc, irConv_zext, b, t_llvm_bool, t));
	}

	if (is_type_cstring(src) && is_type_u8_ptr(dst)) {
		return ir_emit_bitcast(proc, value, dst);
	}
	if (is_type_u8_ptr(src) && is_type_cstring(dst)) {
		return ir_emit_bitcast(proc, value, dst);
	}
	if (is_type_cstring(src) && is_type_rawptr(dst)) {
		return ir_emit_bitcast(proc, value, dst);
	}
	if (is_type_rawptr(src) && is_type_cstring(dst)) {
		return ir_emit_bitcast(proc, value, dst);
	}

	if (are_types_identical(src, t_cstring) && are_types_identical(dst, t_string)) {
		irValue *c = ir_emit_conv(proc, value, t_cstring);
		auto args = array_make<irValue *>(ir_allocator(), 1);
		args[0] = c;
		irValue *s = ir_emit_runtime_call(proc, "cstring_to_string", args);
		return ir_emit_conv(proc, s, dst);
	}


	// integer -> boolean
	if (is_type_integer(src) && is_type_boolean(dst)) {
		return ir_emit_comp(proc, Token_NotEq, value, v_zero);
	}

	// float -> float
	if (is_type_float(src) && is_type_float(dst)) {
		gbAllocator a = ir_allocator();
		i64 sz = type_size_of(src);
		i64 dz = type_size_of(dst);
		irConvKind kind = irConv_fptrunc;
		if (dz >= sz) {
			kind = irConv_fpext;
		}
		return ir_emit(proc, ir_instr_conv(proc, kind, value, src_type, t));
	}

	if (is_type_complex(src) && is_type_complex(dst)) {
		Type *ft = base_complex_elem_type(dst);
		irValue *gen = ir_add_local_generated(proc, dst, false);
		irValue *real = ir_emit_conv(proc, ir_emit_struct_ev(proc, value, 0), ft);
		irValue *imag = ir_emit_conv(proc, ir_emit_struct_ev(proc, value, 1), ft);
		ir_emit_store(proc, ir_emit_struct_ep(proc, gen, 0), real);
		ir_emit_store(proc, ir_emit_struct_ep(proc, gen, 1), imag);
		return ir_emit_load(proc, gen);
	}

	if (is_type_quaternion(src) && is_type_quaternion(dst)) {
		// @QuaternionLayout
		Type *ft = base_complex_elem_type(dst);
		irValue *gen = ir_add_local_generated(proc, dst, false);
		irValue *q0 = ir_emit_conv(proc, ir_emit_struct_ev(proc, value, 0), ft);
		irValue *q1 = ir_emit_conv(proc, ir_emit_struct_ev(proc, value, 1), ft);
		irValue *q2 = ir_emit_conv(proc, ir_emit_struct_ev(proc, value, 2), ft);
		irValue *q3 = ir_emit_conv(proc, ir_emit_struct_ev(proc, value, 3), ft);
		ir_emit_store(proc, ir_emit_struct_ep(proc, gen, 0), q0);
		ir_emit_store(proc, ir_emit_struct_ep(proc, gen, 1), q1);
		ir_emit_store(proc, ir_emit_struct_ep(proc, gen, 2), q2);
		ir_emit_store(proc, ir_emit_struct_ep(proc, gen, 3), q3);
		return ir_emit_load(proc, gen);
	}

	if (is_type_float(src) && is_type_complex(dst)) {
		Type *ft = base_complex_elem_type(dst);
		irValue *gen = ir_add_local_generated(proc, dst, true);
		irValue *real = ir_emit_conv(proc, value, ft);
		ir_emit_store(proc, ir_emit_struct_ep(proc, gen, 0), real);
		return ir_emit_load(proc, gen);
	}
	if (is_type_float(src) && is_type_quaternion(dst)) {
		Type *ft = base_complex_elem_type(dst);
		irValue *gen = ir_add_local_generated(proc, dst, true);
		irValue *real = ir_emit_conv(proc, value, ft);
		// @QuaternionLayout
		ir_emit_store(proc, ir_emit_struct_ep(proc, gen, 3), real);
		return ir_emit_load(proc, gen);
	}
	if (is_type_complex(src) && is_type_quaternion(dst)) {
		Type *ft = base_complex_elem_type(dst);
		irValue *gen = ir_add_local_generated(proc, dst, true);
		irValue *real = ir_emit_conv(proc, ir_emit_struct_ev(proc, value, 0), ft);
		irValue *imag = ir_emit_conv(proc, ir_emit_struct_ev(proc, value, 1), ft);
		// @QuaternionLayout
		ir_emit_store(proc, ir_emit_struct_ep(proc, gen, 3), real);
		ir_emit_store(proc, ir_emit_struct_ep(proc, gen, 0), imag);
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
				gbAllocator a = ir_allocator();
				irValue *parent = ir_add_local_generated(proc, t, true);
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

		bool st_is_ptr = is_type_pointer(src_type);
		st = base_type(st);

		Type *dt = t;
		bool dt_is_ptr = type_deref(dt) != dt;

		GB_ASSERT(is_type_struct(st) || is_type_raw_union(st));
		String field_name = ir_lookup_subtype_polymorphic_field(proc->module->info, t, src_type);
		if (field_name.len > 0) {
			// NOTE(bill): It can be casted
			Selection sel = lookup_field(st, field_name, false, true);
			if (sel.entity != nullptr) {
				ir_emit_comment(proc, str_lit("cast - polymorphism"));
				if (st_is_ptr) {
					irValue *res = ir_emit_deep_field_gep(proc, value, sel);
					Type *rt = ir_type(res);
					if (!are_types_identical(rt, dt) && are_types_identical(type_deref(rt), dt)) {
						res = ir_emit_load(proc, res);
					}
					return res;
				} else {
					if (is_type_pointer(ir_type(value))) {
						Type *rt = ir_type(value);
						if (!are_types_identical(rt, dt) && are_types_identical(type_deref(rt), dt)) {
							value = ir_emit_load(proc, value);
						} else {
							value = ir_emit_deep_field_gep(proc, value, sel);
							return ir_emit_load(proc, value);
						}
					}

					return ir_emit_deep_field_ev(proc, value, sel);

				}
			} else {
				GB_PANIC("invalid subtype cast  %s.%.*s", type_to_string(src_type), LIT(field_name));
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
		irValue *elem_ptr = ir_add_local_generated(proc, ir_type(elem), false);
		ir_emit_store(proc, elem_ptr, elem);

		irValue *len  = ir_string_len(proc, value);
		irValue *slice = ir_add_local_slice(proc, t, elem_ptr, v_zero, len);
		return ir_emit_load(proc, slice);
	}

	if (is_type_array(dst)) {
		Type *elem = dst->Array.elem;
		irValue *e = ir_emit_conv(proc, value, elem);
		// NOTE(bill): Doesn't need to be zero because it will be initialized in the loops
		irValue *v = ir_add_local_generated(proc, t, false);
		isize index_count = cast(isize)dst->Array.count;

		for (i32 i = 0; i < index_count; i++) {
			irValue *elem = ir_emit_array_epi(proc, v, i);
			ir_emit_store(proc, elem, e);
		}
		return ir_emit_load(proc, v);
	}

	if (is_type_any(dst)) {
		irValue *result = ir_add_local_generated(proc, t_any, true);

		if (is_type_untyped_nil(src)) {
			return ir_emit_load(proc, result);
		}

		Type *st = default_type(src_type);

		irValue *data = ir_address_from_load_or_generate_local(proc, value);
		GB_ASSERT_MSG(is_type_pointer(ir_type(data)), type_to_string(ir_type(data)));
		GB_ASSERT_MSG(is_type_typed(st), "%s", type_to_string(st));
		data = ir_emit_conv(proc, data, t_rawptr);


		irValue *id = ir_typeid(proc->module, st);

		ir_emit_store(proc, ir_emit_struct_ep(proc, result, 0), data);
		ir_emit_store(proc, ir_emit_struct_ep(proc, result, 1), id);

		return ir_emit_load(proc, result);
	}

	if (is_type_untyped(src)) {
		if (is_type_string(src) && is_type_string(dst)) {
			irValue *result = ir_add_local_generated(proc, t, false);
			ir_emit_store(proc, result, value);
			return ir_emit_load(proc, result);
		}
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
		case Basic_quaternion128:
		case Basic_quaternion256:
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
	case Type_SimdVector:
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
	if (is_type_uintptr(src) && is_type_proc(dst)) {
		irValue *ptr = ir_emit_uintptr_to_ptr(proc, value, t_rawptr);
		return ir_emit_bitcast(proc, ptr, dst);
	}
	if (is_type_proc(src) && is_type_uintptr(dst)) {
		irValue *ptr = ir_emit_uintptr_to_ptr(proc, value, t_rawptr);
		return ir_emit_bitcast(proc, ptr, dst);
	}

	if (is_type_integer(src) && (is_type_pointer(dst) || is_type_cstring(dst))) {
		Type *vt = core_type(ir_type(value));
		return ir_emit(proc, ir_instr_conv(proc, irConv_inttoptr, value, vt, t));
	} else if ((is_type_pointer(src) || is_type_cstring(src)) && is_type_integer(dst)) {
		Type *vt = core_type(ir_type(value));
		return ir_emit(proc, ir_instr_conv(proc, irConv_ptrtoint, value, vt, t));
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
	gbAllocator a = ir_allocator();

	Type *src_type = ir_type(value);
	bool is_ptr = is_type_pointer(src_type);

	bool is_tuple = true;
	Type *tuple = type;
	if (type->kind != Type_Tuple) {
		is_tuple = false;
		tuple = make_optional_ok_type(type);
	}

	irValue *v = ir_add_local_generated(proc, tuple, true);

	if (is_ptr) {
		value = ir_emit_load(proc, value);
	}
	Type *src = base_type(type_deref(src_type));
	GB_ASSERT_MSG(is_type_union(src), "%s", type_to_string(src_type));
	Type *dst = tuple->Tuple.variables[0]->type;

	irValue *value_  = ir_address_from_load_or_generate_local(proc, value);

	irValue *tag = nullptr;
	irValue *dst_tag = nullptr;
	irValue *cond = nullptr;
	irValue *data = nullptr;

	irValue *gep0 = ir_emit_struct_ep(proc, v, 0);
	irValue *gep1 = ir_emit_struct_ep(proc, v, 1);

	if (is_type_union_maybe_pointer(src)) {
		data = ir_emit_load(proc, ir_emit_conv(proc, value_, ir_type(gep0)));
	} else {
		tag     = ir_emit_load(proc, ir_emit_union_tag_ptr(proc, value_));
		dst_tag = ir_const_union_tag(src, dst);
	}

	irBlock *ok_block = ir_new_block(proc, nullptr, "union_cast.ok");
	irBlock *end_block = ir_new_block(proc, nullptr, "union_cast.end");

	if (data != nullptr) {
		GB_ASSERT(is_type_union_maybe_pointer(src));
		cond = ir_emit_comp_against_nil(proc, Token_NotEq, data);
	} else {
		cond = ir_emit_comp(proc, Token_CmpEq, tag, dst_tag);
	}

	ir_emit_if(proc, cond, ok_block, end_block);
	ir_start_block(proc, ok_block);



	if (data == nullptr) {
		data = ir_emit_load(proc, ir_emit_conv(proc, value_, ir_type(gep0)));
	}
	ir_emit_store(proc, gep0, data);
	ir_emit_store(proc, gep1, v_true);

	ir_emit_jump(proc, end_block);
	ir_start_block(proc, end_block);

	if (!is_tuple) {
		if (do_conversion_check) {
			// NOTE(bill): Panic on invalid conversion
			Type *dst_type = tuple->Tuple.variables[0]->type;

			irValue *ok = ir_emit_load(proc, ir_emit_struct_ep(proc, v, 1));
			auto args = array_make<irValue *>(ir_allocator(), 6);
			args[0] = ok;

			args[1] = ir_find_or_add_entity_string(proc->module, pos.file);
			args[2] = ir_const_int(pos.line);
			args[3] = ir_const_int(pos.column);

			args[4] = ir_typeid(proc->module, src_type);
			args[5] = ir_typeid(proc->module, dst_type);
			ir_emit_runtime_call(proc, "type_assertion_check", args);
		}

		return ir_emit_load(proc, ir_emit_struct_ep(proc, v, 0));
	}
	return ir_emit_load(proc, v);
}

irAddr ir_emit_any_cast_addr(irProcedure *proc, irValue *value, Type *type, TokenPos pos) {
	gbAllocator a = ir_allocator();
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

	irValue *v = ir_add_local_generated(proc, tuple, true);

	irValue *dst_typeid = ir_typeid(proc->module, dst_type);
	irValue *any_typeid = ir_emit_struct_ev(proc, value, 1);


	irBlock *ok_block = ir_new_block(proc, nullptr, "any_cast.ok");
	irBlock *end_block = ir_new_block(proc, nullptr, "any_cast.end");
	irValue *cond = ir_emit_comp(proc, Token_CmpEq, any_typeid, dst_typeid);
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
		auto args = array_make<irValue *>(ir_allocator(), 6);
		args[0] = ok;

		args[1] = ir_find_or_add_entity_string(proc->module, pos.file);
		args[2] = ir_const_int(pos.line);
		args[3] = ir_const_int(pos.column);

		args[4] = any_typeid;
		args[5] = dst_typeid;
		ir_emit_runtime_call(proc, "type_assertion_check", args);

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
gb_global irValue *ir_global_type_info_member_tags    = nullptr;

gb_global i32      ir_global_type_info_data_index           = 0;
gb_global i32      ir_global_type_info_member_types_index   = 0;
gb_global i32      ir_global_type_info_member_names_index   = 0;
gb_global i32      ir_global_type_info_member_offsets_index = 0;
gb_global i32      ir_global_type_info_member_usings_index  = 0;
gb_global i32      ir_global_type_info_member_tags_index    = 0;

isize ir_type_info_count(CheckerInfo *info) {
	return info->minimum_dependency_type_info_set.entries.count+1;
}

isize ir_type_info_index(CheckerInfo *info, Type *type, bool err_on_not_found=true) {
	isize index = type_info_index(info, type, false);
	if (index >= 0) {
		auto *set = &info->minimum_dependency_type_info_set;
		for_array(i, set->entries) {
			if (set->entries[i].ptr == index) {
				return i+1;
			}
		}
	}
	if (err_on_not_found) {
		GB_PANIC("NOT FOUND ir_type_info_index %s @ index %td", type_to_string(type), index);
	}
	return -1;
}

irValue *ir_type_info(irProcedure *proc, Type *type) {
	CheckerInfo *info = proc->module->info;
	type = default_type(type);

	i32 id = cast(i32)ir_type_info_index(info, type);
	GB_ASSERT(id >= 0);
	return ir_emit_array_ep(proc, ir_global_type_info_data, ir_const_i32(id));
}

// IMPORTANT NOTE(bill): This must match the same as the in core.odin
enum Typeid_Kind : u8 {
	Typeid_Invalid,
	Typeid_Integer,
	Typeid_Rune,
	Typeid_Float,
	Typeid_Complex,
	Typeid_Quaternion,
	Typeid_String,
	Typeid_Boolean,
	Typeid_Any,
	Typeid_Type_Id,
	Typeid_Pointer,
	Typeid_Procedure,
	Typeid_Array,
	Typeid_Enumerated_Array,
	Typeid_Dynamic_Array,
	Typeid_Slice,
	Typeid_Tuple,
	Typeid_Struct,
	Typeid_Union,
	Typeid_Enum,
	Typeid_Map,
	Typeid_Bit_Field,
	Typeid_Bit_Set,
};


irValue *ir_typeid(irModule *m, Type *type) {
	type = default_type(type);

	u64 id = cast(u64)ir_type_info_index(m->info, type);
	GB_ASSERT(id >= 0);

	u64 kind = Typeid_Invalid;
	u64 named = is_type_named(type) && type->kind != Type_Basic;
	u64 special = 0;
	u64 reserved = 0;

	Type *bt = base_type(type);
	TypeKind tk = bt->kind;
	switch (tk) {
	case Type_Basic: {
		u32 flags = bt->Basic.flags;
		if (flags & BasicFlag_Boolean)  kind = Typeid_Boolean;
		if (flags & BasicFlag_Integer)  kind = Typeid_Integer;
		if (flags & BasicFlag_Unsigned) kind = Typeid_Integer;
		if (flags & BasicFlag_Float)    kind = Typeid_Float;
		if (flags & BasicFlag_Complex)  kind = Typeid_Complex;
		if (flags & BasicFlag_Pointer)  kind = Typeid_Pointer;
		if (flags & BasicFlag_String)   kind = Typeid_String;
		if (flags & BasicFlag_Rune)     kind = Typeid_Rune;
	} break;
	case Type_Pointer:         kind = Typeid_Pointer;       break;
	case Type_Array:           kind = Typeid_Array;         break;
	case Type_EnumeratedArray: kind = Typeid_Enumerated_Array; break;
	case Type_Slice:           kind = Typeid_Slice;         break;
	case Type_DynamicArray:    kind = Typeid_Dynamic_Array; break;
	case Type_Map:             kind = Typeid_Map;           break;
	case Type_Struct:          kind = Typeid_Struct;        break;
	case Type_Enum:            kind = Typeid_Enum;          break;
	case Type_Union:           kind = Typeid_Union;         break;
	case Type_Tuple:           kind = Typeid_Tuple;         break;
	case Type_Proc:            kind = Typeid_Procedure;     break;
	case Type_BitField:        kind = Typeid_Bit_Field;     break;
	case Type_BitSet:          kind = Typeid_Bit_Set;       break;
	}

	if (is_type_cstring(type)) {
		special = 1;
	} else if (is_type_integer(type) && !is_type_unsigned(type)) {
		special = 1;
	}

	u64 data = 0;
	if (build_context.word_size == 4) {
		data |= (id       &~ (1u<<24)) << 0u;  // index
		data |= (kind     &~ (1u<<5))  << 24u; // kind
		data |= (named    &~ (1u<<1))  << 29u; // kind
		data |= (special  &~ (1u<<1))  << 30u; // kind
		data |= (reserved &~ (1u<<1))  << 31u; // kind
	} else {
		GB_ASSERT(build_context.word_size == 8);
		data |= (id       &~ (1ull<<56)) << 0ul;  // index
		data |= (kind     &~ (1ull<<5))  << 56ull; // kind
		data |= (named    &~ (1ull<<1))  << 61ull; // kind
		data |= (special  &~ (1ull<<1))  << 62ull; // kind
		data |= (reserved &~ (1ull<<1))  << 63ull; // kind
	}


	return ir_value_constant(t_typeid, exact_value_u64(data));
}


irValue *ir_emit_logical_binary_expr(irProcedure *proc, TokenKind op, Ast *left, Ast *right, Type *type) {
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

	auto edges = array_make<irValue *>(ir_allocator(), 0, done->preds.count+1);
	for_array(i, done->preds) {
		array_add(&edges, short_circuit);
	}

	ir_start_block(proc, rhs);
	irValue *edge = ir_build_expr(proc, right);
	array_add(&edges, edge);
	ir_emit_jump(proc, done);
	ir_start_block(proc, done);

	return ir_emit(proc, ir_instr_phi(proc, edges, type));
}

irValue *ir_emit_logical_binary_expr(irProcedure *proc, Ast *expr) {
	ast_node(be, BinaryExpr, expr);

	Type *type = type_of_expr(expr);
	type = default_type(type);

	return ir_emit_logical_binary_expr(proc, be->op.kind, be->left, be->right, type);
}


void ir_emit_bounds_check(irProcedure *proc, Token token, irValue *index, irValue *len) {
	if (build_context.no_bounds_check) {
		return;
	}
	if ((proc->module->state_flags & StateFlag_no_bounds_check) != 0) {
		return;
	}

	index = ir_emit_conv(proc, index, t_int);
	len = ir_emit_conv(proc, len, t_int);

	gbAllocator a = ir_allocator();
	irValue *file = ir_find_or_add_entity_string(proc->module, token.pos.file);
	irValue *line = ir_const_int(token.pos.line);
	irValue *column = ir_const_int(token.pos.column);


	auto args = array_make<irValue *>(ir_allocator(), 5);
	args[0] = file;
	args[1] = line;
	args[2] = column;
	args[3] = index;
	args[4] = len;

	ir_emit_runtime_call(proc, "bounds_check_error", args);
}

void ir_emit_slice_bounds_check(irProcedure *proc, Token token, irValue *low, irValue *high, irValue *len, bool lower_value_used) {
	if (build_context.no_bounds_check) {
		return;
	}
	if ((proc->module->state_flags & StateFlag_no_bounds_check) != 0) {
		return;
	}

	gbAllocator a = ir_allocator();
	irValue *file = ir_find_or_add_entity_string(proc->module, token.pos.file);
	irValue *line = ir_const_int(token.pos.line);
	irValue *column = ir_const_int(token.pos.column);
	high = ir_emit_conv(proc, high, t_int);

	if (!lower_value_used) {
		auto args = array_make<irValue *>(ir_allocator(), 5);
		args[0] = file;
		args[1] = line;
		args[2] = column;
		args[3] = high;
		args[4] = len;

		ir_emit_runtime_call(proc, "slice_expr_error_hi", args);
	} else {
		// No need to convert unless used
		low  = ir_emit_conv(proc, low, t_int);

		auto args = array_make<irValue *>(ir_allocator(), 6);
		args[0] = file;
		args[1] = line;
		args[2] = column;
		args[3] = low;
		args[4] = high;
		args[5] = len;

		ir_emit_runtime_call(proc, "slice_expr_error_lo_hi", args);
	}
}

void ir_emit_dynamic_array_bounds_check(irProcedure *proc, Token token, irValue *low, irValue *high, irValue *max) {
	if (build_context.no_bounds_check) {
		return;
	}
	if ((proc->module->state_flags & StateFlag_no_bounds_check) != 0) {
		return;
	}

	gbAllocator a = ir_allocator();
	irValue *file = ir_find_or_add_entity_string(proc->module, token.pos.file);
	irValue *line = ir_const_int(token.pos.line);
	irValue *column = ir_const_int(token.pos.column);
	low  = ir_emit_conv(proc, low,  t_int);
	high = ir_emit_conv(proc, high, t_int);

	auto args = array_make<irValue *>(ir_allocator(), 6);
	args[0] = file;
	args[1] = line;
	args[2] = column;
	args[3] = low;
	args[4] = high;
	args[5] = max;

	ir_emit_runtime_call(proc, "dynamic_array_expr_error", args);
}



////////////////////////////////////////////////////////////////
//
// @Build
//
////////////////////////////////////////////////////////////////

String ir_mangle_name(irGen *s, Entity *e) {
	irModule *m = &s->module;
	CheckerInfo *info = m->info;
	gbAllocator a = ir_allocator();

	String name = e->token.string;

	AstPackage *pkg = e->pkg;
	GB_ASSERT_MSG(pkg != nullptr, "Missing package for '%.*s'", LIT(name));
	String pkgn = pkg->name;
	GB_ASSERT(!rune_is_digit(pkgn[0]));



	isize max_len = pkgn.len + 1 + name.len + 1;
	bool require_suffix_id = is_type_polymorphic(e->type, true);
	if (require_suffix_id) {
		max_len += 21;
	}

	u8 *new_name = gb_alloc_array(a, u8, max_len);
	isize new_name_len = gb_snprintf(
		cast(char *)new_name, max_len,
		"%.*s.%.*s", LIT(pkgn), LIT(name)
	);
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
	if (is_type_proc(field->type)) {
		set_procedure_abi_types(heap_allocator(), field->type);
	}

	String cn = field->token.string;
	isize max_len = parent.len + 1 + 16 + 1 + cn.len;
	bool require_suffix_id = is_type_polymorphic(field->type, true);
	if (require_suffix_id) {
		max_len += 21;
	}

	u8 *new_name = gb_alloc_array(ir_allocator(), u8, max_len);
	isize new_name_len = gb_snprintf(cast(char *)new_name, max_len,
	                                 "%.*s.%.*s", LIT(parent), LIT(cn));

	if (require_suffix_id) {
		char *str = cast(char *)new_name + new_name_len-1;
		isize len = max_len-new_name_len;
		isize extra = gb_snprintf(str, len, "-%llu", cast(unsigned long long)field->id);
		new_name_len += extra-1;
	}

	String child = {new_name, new_name_len-1};
	GB_ASSERT(child.len > 0);
	ir_add_entity_name(m, field, child);
	ir_gen_global_type_name(m, field, child);
}


irBranchBlocks ir_lookup_branch_blocks(irProcedure *proc, Ast *ident) {
	GB_ASSERT(ident->kind == Ast_Ident);
	Entity *e = entity_of_ident(ident);
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


irTargetList *ir_push_target_list(irProcedure *proc, Ast *label, irBlock *break_, irBlock *continue_, irBlock *fallthrough_) {
	irTargetList *tl = gb_alloc_item(ir_allocator(), irTargetList);
	tl->prev          = proc->target_list;
	tl->break_        = break_;
	tl->continue_     = continue_;
	tl->fallthrough_  = fallthrough_;
	proc->target_list = tl;

	if (label != nullptr) { // Set label blocks
		GB_ASSERT(label->kind == Ast_Label);

		for_array(i, proc->branch_blocks) {
			irBranchBlocks *b = &proc->branch_blocks[i];
			GB_ASSERT(b->label != nullptr && label != nullptr);
			GB_ASSERT(b->label->kind == Ast_Label);
			if (b->label == label) {
				b->break_    = break_;
				b->continue_ = continue_;
				return tl;
			}
		}

		GB_PANIC("ir_set_label_blocks: Unreachable");
	}

	return tl;
}

void ir_pop_target_list(irProcedure *proc) {
	proc->target_list = proc->target_list->prev;
}



irValue *ir_gen_anonymous_proc_lit(irModule *m, String prefix_name, Ast *expr, irProcedure *proc = nullptr) {
	ast_node(pl, ProcLit, expr);

	// NOTE(bill): Generate a new name
	// parent$count
	isize name_len = prefix_name.len + 1 + 8 + 1;
	u8 *name_text = gb_alloc_array(ir_allocator(), u8, name_len);
	i32 name_id = cast(i32)m->anonymous_proc_lits.entries.count;

	name_len = gb_snprintf(cast(char *)name_text, name_len, "%.*s$anon-%d", LIT(prefix_name), name_id);
	String name = make_string(name_text, name_len-1);

	Type *type = type_of_expr(expr);
	set_procedure_abi_types(heap_allocator(), type);
	irValue *value = ir_value_procedure(m, nullptr, type, pl->type, pl->body, name);

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
				// gb_printf_err("--> %.*s %p\n", LIT(sub->token.string), sub);
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
	irValue *t = ir_value_type_name(name, e->type);
	ir_module_add_value(m, e, t);
	map_set(&m->members, hash_string(name), t);

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
		irValue *instr = cast(irValue *)gb_alloc_copy(ir_allocator(), d.instr, gb_size_of(irValue));
		ir_emit(proc, instr);
	} else if (d.kind == irDefer_Proc) {
		ir_emit_call(proc, d.proc.deferred, d.proc.result_as_args);
	}
}

irValue *ir_emit_min(irProcedure *proc, Type *t, irValue *x, irValue *y) {
	x = ir_emit_conv(proc, x, t);
	y = ir_emit_conv(proc, y, t);

	if (is_type_float(t)) {
		gbAllocator a = ir_allocator();
		i64 sz = 8*type_size_of(t);
		auto args = array_make<irValue *>(ir_allocator(), 2);
		args[0] = x;
		args[1] = y;
		switch (sz) {
		case 32: return ir_emit_runtime_call(proc, "min_f32", args);
		case 64: return ir_emit_runtime_call(proc, "min_f64", args);
		}
		GB_PANIC("Unknown float type");
	}
	return ir_emit_select(proc, ir_emit_comp(proc, Token_Lt, x, y), x, y);
}
irValue *ir_emit_max(irProcedure *proc, Type *t, irValue *x, irValue *y) {
	x = ir_emit_conv(proc, x, t);
	y = ir_emit_conv(proc, y, t);

	if (is_type_float(t)) {
		gbAllocator a = ir_allocator();
		i64 sz = 8*type_size_of(t);
		auto args = array_make<irValue *>(ir_allocator(), 2);
		args[0] = x;
		args[1] = y;
		switch (sz) {
		case 32: return ir_emit_runtime_call(proc, "max_f32", args);
		case 64: return ir_emit_runtime_call(proc, "max_f64", args);
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
	AstPackage *pkg = proc->module->info->runtime_package;
	Entity *e = scope_lookup_current(pkg->scope, name);
	irValue **value = map_get(&proc->module->values, hash_entity(e));
	GB_ASSERT_MSG(value != nullptr, "Unable to find global variable '%.*s'", LIT(name));
	return *value;
}

void ir_build_stmt_list(irProcedure *proc, Array<Ast *> stmts);
void ir_build_assign_op(irProcedure *proc, irAddr const &lhs, irValue *value, TokenKind op);

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


u64 ir_generate_source_code_location_hash(TokenPos pos) {
	u64 h = 0xcbf29ce484222325;
	for (isize i = 0; i < pos.file.len; i++) {
		h = (h ^ u64(pos.file[i])) * 0x100000001b3;
	}
	h = h ^ (u64(pos.line) * 0x100000001b3);
	h = h ^ (u64(pos.column) * 0x100000001b3);
	return h;
}

irValue *ir_emit_source_code_location(irProcedure *proc, String procedure, TokenPos pos) {
	gbAllocator a = ir_allocator();
	irValue *v = ir_alloc_value(irValue_SourceCodeLocation);
	v->SourceCodeLocation.file      = ir_find_or_add_entity_string(proc->module, pos.file);
	v->SourceCodeLocation.line      = ir_const_int(pos.line);
	v->SourceCodeLocation.column    = ir_const_int(pos.column);
	v->SourceCodeLocation.procedure = ir_find_or_add_entity_string(proc->module, procedure);
	v->SourceCodeLocation.hash      = ir_generate_source_code_location_hash(pos);
	return v;
}


irValue *ir_emit_source_code_location(irProcedure *proc, Ast *node) {
	String proc_name = {};
	if (proc->entity) {
		proc_name = proc->entity->token.string;
	}
	TokenPos pos = {};
	if (node) {
		pos = ast_token(node).pos;
	}
	return ir_emit_source_code_location(proc, proc_name, pos);
}

void ir_emit_increment(irProcedure *proc, irValue *addr) {
	GB_ASSERT(is_type_pointer(ir_type(addr)));
	Type *type = type_deref(ir_type(addr));
	ir_emit_store(proc, addr, ir_emit_arith(proc, Token_Add, ir_emit_load(proc, addr), v_one, type));

}

void ir_init_data_with_defaults(irProcedure *proc, irValue *ptr, irValue *count, Ast *expr) {
	Type *elem_type = type_deref(ir_type(ptr));
	GB_ASSERT(is_type_struct(elem_type) || is_type_array(elem_type));

	irValue *index = ir_add_local_generated(proc, t_int, false);
	ir_emit_store(proc, index, ir_const_int(0));

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
	ir_emit(proc, ir_instr_zero_init(proc, offset_ptr)); // Use simple zero for this
	// ir_emit_zero_init(proc, offset_ptr, expr);

	ir_emit_increment(proc, index);

	ir_emit_jump(proc, loop);
	ir_start_block(proc, done);
}


irValue *ir_build_builtin_proc(irProcedure *proc, Ast *expr, TypeAndValue tv, BuiltinProcId id) {
	ast_node(ce, CallExpr, expr);

	switch (id) {
	case BuiltinProc_DIRECTIVE: {
		ast_node(bd, BasicDirective, ce->proc);
		String name = bd->name;
		GB_ASSERT(name == "location");
		String procedure = proc->entity->token.string;
		TokenPos pos = ast_token(ce->proc).pos;
		if (ce->args.count > 0) {
			Ast *ident = unselector_expr(ce->args[0]);
			GB_ASSERT(ident->kind == Ast_Ident);
			Entity *e = entity_of_ident(ident);
			GB_ASSERT(e != nullptr);

			if (e->parent_proc_decl != nullptr && e->parent_proc_decl->entity != nullptr) {
				procedure = e->parent_proc_decl->entity->token.string;
			} else {
				procedure = str_lit("");
			}
			pos = e->token.pos;

		}
		return ir_emit_source_code_location(proc, procedure, pos);
	}

	case BuiltinProc_type_info_of: {
		Ast *arg = ce->args[0];
		TypeAndValue tav = type_and_value_of_expr(arg);
		if (tav.mode == Addressing_Type) {
			Type *t = default_type(type_of_expr(arg));
			return ir_type_info(proc, t);
		}
		GB_ASSERT(is_type_typeid(tav.type));

		auto args = array_make<irValue *>(ir_allocator(), 1);
		args[0] = ir_build_expr(proc, arg);
		return ir_emit_runtime_call(proc, "__type_info_of", args);
	}

	case BuiltinProc_typeid_of: {
		Ast *arg = ce->args[0];
		TypeAndValue tav = type_and_value_of_expr(arg);
		if (tav.mode == Addressing_Type) {
			Type *t = default_type(type_of_expr(arg));
			return ir_typeid(proc->module, t);
		}
		Type *t = base_type(tav.type);
		GB_ASSERT(are_types_identical(t, t_type_info_ptr));

		auto args = array_make<irValue *>(ir_allocator(), 1);
		args[0] = ir_emit_conv(proc, ir_build_expr(proc, arg), t_type_info_ptr);
		return ir_emit_runtime_call(proc, "__typeid_of", args);
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
		} else if (is_type_soa_struct(t)) {
			return ir_soa_struct_len(proc, v);
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
		} else if (is_type_soa_struct(t)) {
			return ir_soa_struct_cap(proc, v);
		}

		GB_PANIC("Unreachable");

		break;
	}

	case BuiltinProc_swizzle: {
		ir_emit_comment(proc, str_lit("swizzle.begin"));
		irAddr addr = ir_build_addr(proc, ce->args[0]);
		isize index_count = ce->args.count-1;
		if (index_count == 0) {
			return ir_addr_load(proc, addr);
		}
		irValue *src = ir_addr_get_ptr(proc, addr);
		// TODO(bill): Should this be zeroed or not?
		irValue *dst = ir_add_local_generated(proc, tv.type, true);

		for (i32 i = 1; i < ce->args.count; i++) {
			TypeAndValue tv = type_and_value_of_expr(ce->args[i]);
			GB_ASSERT(is_type_integer(tv.type));
			GB_ASSERT(tv.value.kind == ExactValue_Integer);

			i32 src_index = cast(i32)big_int_to_i64(&tv.value.value_integer);
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
		irValue *dst = ir_add_local_generated(proc, tv.type, false);

		Type *ft = base_complex_elem_type(tv.type);
		real = ir_emit_conv(proc, real, ft);
		imag = ir_emit_conv(proc, imag, ft);
		ir_emit_store(proc, ir_emit_struct_ep(proc, dst, 0), real);
		ir_emit_store(proc, ir_emit_struct_ep(proc, dst, 1), imag);

		return ir_emit_load(proc, dst);
	}

	case BuiltinProc_quaternion: {
		ir_emit_comment(proc, str_lit("quaternion"));
		irValue *real = ir_build_expr(proc, ce->args[0]);
		irValue *imag = ir_build_expr(proc, ce->args[1]);
		irValue *jmag = ir_build_expr(proc, ce->args[2]);
		irValue *kmag = ir_build_expr(proc, ce->args[3]);

		// @QuaternionLayout
		irValue *dst = ir_add_local_generated(proc, tv.type, false);
		Type *ft = base_complex_elem_type(tv.type);
		real = ir_emit_conv(proc, real, ft);
		imag = ir_emit_conv(proc, imag, ft);
		jmag = ir_emit_conv(proc, jmag, ft);
		kmag = ir_emit_conv(proc, kmag, ft);
		ir_emit_store(proc, ir_emit_struct_ep(proc, dst, 3), real);
		ir_emit_store(proc, ir_emit_struct_ep(proc, dst, 0), imag);
		ir_emit_store(proc, ir_emit_struct_ep(proc, dst, 1), jmag);
		ir_emit_store(proc, ir_emit_struct_ep(proc, dst, 2), kmag);

		return ir_emit_load(proc, dst);
	}

	case BuiltinProc_real: {
		ir_emit_comment(proc, str_lit("real"));
		irValue *val = ir_build_expr(proc, ce->args[0]);
		if (is_type_complex(ir_type(val))) {
			irValue *real = ir_emit_struct_ev(proc, val, 0);
			return ir_emit_conv(proc, real, tv.type);
		} else if (is_type_quaternion(ir_type(val))) {
			// @QuaternionLayout
			irValue *real = ir_emit_struct_ev(proc, val, 3);
			return ir_emit_conv(proc, real, tv.type);
		}
		GB_PANIC("invalid type for real");
		return nullptr;
	}
	case BuiltinProc_imag: {
		ir_emit_comment(proc, str_lit("imag"));
		irValue *val = ir_build_expr(proc, ce->args[0]);
		if (is_type_complex(ir_type(val))) {
			irValue *imag = ir_emit_struct_ev(proc, val, 1);
			return ir_emit_conv(proc, imag, tv.type);
		} else if (is_type_quaternion(ir_type(val))) {
			// @QuaternionLayout
			irValue *imag = ir_emit_struct_ev(proc, val, 0);
			return ir_emit_conv(proc, imag, tv.type);
		}
		GB_PANIC("invalid type for imag");
		return nullptr;
	}
	case BuiltinProc_jmag: {
		ir_emit_comment(proc, str_lit("jmag"));
		irValue *val = ir_build_expr(proc, ce->args[0]);
		if (is_type_quaternion(ir_type(val))) {
			// @QuaternionLayout
			irValue *imag = ir_emit_struct_ev(proc, val, 1);
			return ir_emit_conv(proc, imag, tv.type);
		}
		GB_PANIC("invalid type for jmag");
		return nullptr;
	}
	case BuiltinProc_kmag: {
		ir_emit_comment(proc, str_lit("kmag"));
		irValue *val = ir_build_expr(proc, ce->args[0]);
		if (is_type_quaternion(ir_type(val))) {
			// @QuaternionLayout
			irValue *imag = ir_emit_struct_ev(proc, val, 2);
			return ir_emit_conv(proc, imag, tv.type);
		}
		GB_PANIC("invalid type for kmag");
		return nullptr;
	}

	case BuiltinProc_conj: {
		ir_emit_comment(proc, str_lit("conj"));
		irValue *val = ir_build_expr(proc, ce->args[0]);
		irValue *res = nullptr;
		Type *t = ir_type(val);
		if (is_type_complex(t)) {
			res = ir_add_local_generated(proc, tv.type, false);
			irValue *real = ir_emit_struct_ev(proc, val, 0);
			irValue *imag = ir_emit_struct_ev(proc, val, 1);
			imag = ir_emit_unary_arith(proc, Token_Sub, imag, ir_type(imag));
			ir_emit_store(proc, ir_emit_struct_ep(proc, res, 0), real);
			ir_emit_store(proc, ir_emit_struct_ep(proc, res, 1), imag);
		} else if (is_type_quaternion(t)) {
			// @QuaternionLayout
			res = ir_add_local_generated(proc, tv.type, false);
			irValue *real = ir_emit_struct_ev(proc, val, 3);
			irValue *imag = ir_emit_struct_ev(proc, val, 0);
			irValue *jmag = ir_emit_struct_ev(proc, val, 1);
			irValue *kmag = ir_emit_struct_ev(proc, val, 2);
			imag = ir_emit_unary_arith(proc, Token_Sub, imag, ir_type(imag));
			jmag = ir_emit_unary_arith(proc, Token_Sub, jmag, ir_type(jmag));
			kmag = ir_emit_unary_arith(proc, Token_Sub, kmag, ir_type(kmag));
			ir_emit_store(proc, ir_emit_struct_ep(proc, res, 3), real);
			ir_emit_store(proc, ir_emit_struct_ep(proc, res, 0), imag);
			ir_emit_store(proc, ir_emit_struct_ep(proc, res, 1), jmag);
			ir_emit_store(proc, ir_emit_struct_ep(proc, res, 2), kmag);
		}
		return ir_emit_load(proc, res);
	}

	case BuiltinProc_expand_to_tuple: {
		ir_emit_comment(proc, str_lit("expand_to_tuple"));
		irValue *val = ir_build_expr(proc, ce->args[0]);
		Type *t = base_type(ir_type(val));

		if (!is_type_tuple(tv.type)) {
			if (t->kind == Type_Struct) {
				GB_ASSERT(t->Struct.fields.count == 1);
				return ir_emit_struct_ev(proc, val, 0);
			} else if (t->kind == Type_Array) {
				GB_ASSERT(t->Array.count == 1);
				return ir_emit_array_epi(proc, val, 0);
			} else {
				GB_PANIC("Unknown type of expand_to_tuple");
			}

		}

		GB_ASSERT(is_type_tuple(tv.type));
		// NOTE(bill): Doesn't need to be zero because it will be initialized in the loops
		irValue *tuple = ir_add_local_generated(proc, tv.type, false);
		if (t->kind == Type_Struct) {
			for_array(src_index, t->Struct.fields) {
				Entity *field = t->Struct.fields[src_index];
				i32 field_index = field->Variable.field_index;
				irValue *f = ir_emit_struct_ev(proc, val, field_index);
				irValue *ep = ir_emit_struct_ep(proc, tuple, cast(i32)src_index);
				ir_emit_store(proc, ep, f);
			}
		} else if (t->kind == Type_Array) {
			// TODO(bill): Clean-up this code
			irValue *ap = ir_address_from_load_or_generate_local(proc, val);
			for (i32 i = 0; i < cast(i32)t->Array.count; i++) {
				irValue *f = ir_emit_load(proc, ir_emit_array_epi(proc, ap, i));
				irValue *ep = ir_emit_struct_ep(proc, tuple, i);
				ir_emit_store(proc, ep, f);
			}
		} else {
			GB_PANIC("Unknown type of expand_to_tuple");
		}
		return ir_emit_load(proc, tuple);
	}

	case BuiltinProc_min: {
		ir_emit_comment(proc, str_lit("min"));
		Type *t = type_of_expr(expr);
		if (ce->args.count == 2) {
			return ir_emit_min(proc, t, ir_build_expr(proc, ce->args[0]), ir_build_expr(proc, ce->args[1]));
		} else {
			irValue *x = ir_build_expr(proc, ce->args[0]);
			for (isize i = 1; i < ce->args.count; i++) {
				x = ir_emit_min(proc, t, x, ir_build_expr(proc, ce->args[i]));
			}
			return x;
		}
	}

	case BuiltinProc_max: {
		ir_emit_comment(proc, str_lit("max"));
		Type *t = type_of_expr(expr);
		if (ce->args.count == 2) {
			return ir_emit_max(proc, t, ir_build_expr(proc, ce->args[0]), ir_build_expr(proc, ce->args[1]));
		} else {
			irValue *x = ir_build_expr(proc, ce->args[0]);
			for (isize i = 1; i < ce->args.count; i++) {
				x = ir_emit_max(proc, t, x, ir_build_expr(proc, ce->args[i]));
			}
			return x;
		}
	}

	case BuiltinProc_abs: {
		gbAllocator a = ir_allocator();
		irValue *x = ir_build_expr(proc, ce->args[0]);
		Type *t = ir_type(x);
		if (is_type_unsigned(t)) {
			return x;
		}
		ir_emit_comment(proc, str_lit("abs"));
		if (is_type_quaternion(t)) {
			i64 sz = 8*type_size_of(t);
			auto args = array_make<irValue *>(ir_allocator(), 1);
			args[0] = x;
			switch (sz) {
			case 128: return ir_emit_runtime_call(proc, "abs_quaternion128", args);
			case 256: return ir_emit_runtime_call(proc, "abs_quaternion256", args);
			}
			GB_PANIC("Unknown complex type");
		} else if (is_type_complex(t)) {
			i64 sz = 8*type_size_of(t);
			auto args = array_make<irValue *>(ir_allocator(), 1);
			args[0] = x;
			switch (sz) {
			case 64:  return ir_emit_runtime_call(proc, "abs_complex64",  args);
			case 128: return ir_emit_runtime_call(proc, "abs_complex128", args);
			}
			GB_PANIC("Unknown complex type");
		} else if (is_type_float(t)) {
			i64 sz = 8*type_size_of(t);
			auto args = array_make<irValue *>(ir_allocator(), 1);
			args[0] = x;
			switch (sz) {
			case 32: return ir_emit_runtime_call(proc, "abs_f32", args);
			case 64: return ir_emit_runtime_call(proc, "abs_f64", args);
			}
			GB_PANIC("Unknown float type");
		}
		irValue *zero = ir_emit_conv(proc, v_zero, t);
		irValue *cond = ir_emit_comp(proc, Token_Lt, x, zero);
		irValue *neg = ir_emit(proc, ir_instr_unary_op(proc, Token_Sub, x, t));
		return ir_emit_select(proc, cond, neg, x);
	}

	case BuiltinProc_clamp:
		ir_emit_comment(proc, str_lit("clamp"));
		return ir_emit_clamp(proc, type_of_expr(expr),
		                     ir_build_expr(proc, ce->args[0]),
		                     ir_build_expr(proc, ce->args[1]),
		                     ir_build_expr(proc, ce->args[2]));



	// "Intrinsics"
	case BuiltinProc_atomic_fence:
	case BuiltinProc_atomic_fence_acq:
	case BuiltinProc_atomic_fence_rel:
	case BuiltinProc_atomic_fence_acqrel:
		return ir_emit(proc, ir_instr_atomic_fence(proc, id));

	case BuiltinProc_atomic_store:
	case BuiltinProc_atomic_store_rel:
	case BuiltinProc_atomic_store_relaxed:
	case BuiltinProc_atomic_store_unordered: {
		irValue *dst = ir_build_expr(proc, ce->args[0]);
		irValue *val = ir_build_expr(proc, ce->args[1]);
		val = ir_emit_conv(proc, val, type_deref(ir_type(dst)));
		return ir_emit(proc, ir_instr_atomic_store(proc, dst, val, id));
	}

	case BuiltinProc_atomic_load:
	case BuiltinProc_atomic_load_acq:
	case BuiltinProc_atomic_load_relaxed:
	case BuiltinProc_atomic_load_unordered: {
		irValue *dst = ir_build_expr(proc, ce->args[0]);
		return ir_emit(proc, ir_instr_atomic_load(proc, dst, id));
	}

	case BuiltinProc_atomic_add:
	case BuiltinProc_atomic_add_acq:
	case BuiltinProc_atomic_add_rel:
	case BuiltinProc_atomic_add_acqrel:
	case BuiltinProc_atomic_add_relaxed:
	case BuiltinProc_atomic_sub:
	case BuiltinProc_atomic_sub_acq:
	case BuiltinProc_atomic_sub_rel:
	case BuiltinProc_atomic_sub_acqrel:
	case BuiltinProc_atomic_sub_relaxed:
	case BuiltinProc_atomic_and:
	case BuiltinProc_atomic_and_acq:
	case BuiltinProc_atomic_and_rel:
	case BuiltinProc_atomic_and_acqrel:
	case BuiltinProc_atomic_and_relaxed:
	case BuiltinProc_atomic_nand:
	case BuiltinProc_atomic_nand_acq:
	case BuiltinProc_atomic_nand_rel:
	case BuiltinProc_atomic_nand_acqrel:
	case BuiltinProc_atomic_nand_relaxed:
	case BuiltinProc_atomic_or:
	case BuiltinProc_atomic_or_acq:
	case BuiltinProc_atomic_or_rel:
	case BuiltinProc_atomic_or_acqrel:
	case BuiltinProc_atomic_or_relaxed:
	case BuiltinProc_atomic_xor:
	case BuiltinProc_atomic_xor_acq:
	case BuiltinProc_atomic_xor_rel:
	case BuiltinProc_atomic_xor_acqrel:
	case BuiltinProc_atomic_xor_relaxed:
	case BuiltinProc_atomic_xchg:
	case BuiltinProc_atomic_xchg_acq:
	case BuiltinProc_atomic_xchg_rel:
	case BuiltinProc_atomic_xchg_acqrel:
	case BuiltinProc_atomic_xchg_relaxed: {
		irValue *dst = ir_build_expr(proc, ce->args[0]);
		irValue *val = ir_build_expr(proc, ce->args[1]);
		val = ir_emit_conv(proc, val, type_deref(ir_type(dst)));
		return ir_emit(proc, ir_instr_atomic_rmw(proc, dst, val, id));
	}

	case BuiltinProc_atomic_cxchg:
	case BuiltinProc_atomic_cxchg_acq:
	case BuiltinProc_atomic_cxchg_rel:
	case BuiltinProc_atomic_cxchg_acqrel:
	case BuiltinProc_atomic_cxchg_relaxed:
	case BuiltinProc_atomic_cxchg_failrelaxed:
	case BuiltinProc_atomic_cxchg_failacq:
	case BuiltinProc_atomic_cxchg_acq_failrelaxed:
	case BuiltinProc_atomic_cxchg_acqrel_failrelaxed:
	case BuiltinProc_atomic_cxchgweak:
	case BuiltinProc_atomic_cxchgweak_acq:
	case BuiltinProc_atomic_cxchgweak_rel:
	case BuiltinProc_atomic_cxchgweak_acqrel:
	case BuiltinProc_atomic_cxchgweak_relaxed:
	case BuiltinProc_atomic_cxchgweak_failrelaxed:
	case BuiltinProc_atomic_cxchgweak_failacq:
	case BuiltinProc_atomic_cxchgweak_acq_failrelaxed:
	case BuiltinProc_atomic_cxchgweak_acqrel_failrelaxed: {
		Type *type = expr->tav.type;

		irValue *address = ir_build_expr(proc, ce->args[0]);
		Type *elem = type_deref(ir_type(address));
		irValue *old_value = ir_build_expr(proc, ce->args[1]);
		irValue *new_value = ir_build_expr(proc, ce->args[2]);
		old_value = ir_emit_conv(proc, old_value, elem);
		new_value = ir_emit_conv(proc, new_value, elem);

		return ir_emit(proc, ir_instr_atomic_cxchg(proc, type, address, old_value, new_value, id));
	}


	}

	GB_PANIC("Unhandled built-in procedure");
	return nullptr;
}

irValue *ir_build_expr_internal(irProcedure *proc, Ast *expr);

irValue *ir_build_expr(irProcedure *proc, Ast *expr) {
	u64 prev_state_flags = proc->module->state_flags;
	defer (proc->module->state_flags = prev_state_flags);

	if (expr->state_flags != 0) {
		u64 in = expr->state_flags;
		u64 out = proc->module->state_flags;

		if (in & StateFlag_bounds_check) {
			out |= StateFlag_bounds_check;
			out &= ~StateFlag_no_bounds_check;
		} else if (in & StateFlag_no_bounds_check) {
			out |= StateFlag_no_bounds_check;
			out &= ~StateFlag_bounds_check;
		}

		proc->module->state_flags = out;
	}

	irValue *v = ir_build_expr_internal(proc, expr);
	return v;
}

irValue *ir_build_expr_internal(irProcedure *proc, Ast *expr) {
	expr = unparen_expr(expr);
	// ir_push_debug_location(proc->module, expr, proc->debug_scope);
	// defer (ir_pop_debug_location(proc->module));

	TypeAndValue tv = type_and_value_of_expr(expr);
	GB_ASSERT(tv.mode != Addressing_Invalid);
	GB_ASSERT(tv.mode != Addressing_Type);

	if (tv.value.kind != ExactValue_Invalid) {
		// NOTE(bill): Edge case
		if (tv.value.kind != ExactValue_Compound &&
		    is_type_array(tv.type)) {
			Type *elem = core_array_type(tv.type);
			ExactValue value = convert_exact_value_for_type(tv.value, elem);
			irValue *x = ir_add_module_constant(proc->module, elem, value);
			return ir_emit_conv(proc, x, tv.type);
		}

		if (tv.value.kind == ExactValue_Typeid) {
			irValue *v = ir_typeid(proc->module, tv.value.value_typeid);
			return ir_emit_conv(proc, v, tv.type);
		}

		return ir_add_module_constant(proc->module, tv.type, tv.value);
	}

	if (tv.mode == Addressing_Variable) {
		return ir_addr_load(proc, ir_build_addr(proc, expr));
	}

	if (tv.mode == Addressing_Constant) {
		GB_ASSERT(tv.value.kind == ExactValue_Invalid);
		// NOTE(bill): Zero value constant
		return ir_add_module_constant(proc->module, tv.type, tv.value);
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
		return ir_value_undef(tv.type);
	case_end;

	case_ast_node(i, Ident, expr);
		Entity *e = entity_of_ident(expr);
		GB_ASSERT_MSG(e != nullptr, "%s", expr_to_string(expr));
		if (e->kind == Entity_Builtin) {
			Token token = ast_token(expr);
			GB_PANIC("TODO(bill): ir_build_expr Entity_Builtin '%.*s'\n"
			         "\t at %.*s(%td:%td)", LIT(builtin_procs[e->Builtin.id].name),
			         LIT(token.pos.file), token.pos.line, token.pos.column);
			return nullptr;
		} else if (e->kind == Entity_Nil) {
			return ir_value_nil(tv.type);
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

	case_ast_node(de, DerefExpr, expr);
		return ir_addr_load(proc, ir_build_addr(proc, expr));
	case_end;

	case_ast_node(se, SelectorExpr, expr);
		TypeAndValue tav = type_and_value_of_expr(expr);
		GB_ASSERT(tav.mode != Addressing_Invalid);
		return ir_addr_load(proc, ir_build_addr(proc, expr));
	case_end;

	case_ast_node(ise, ImplicitSelectorExpr, expr);
		TypeAndValue tav = type_and_value_of_expr(expr);
		GB_ASSERT(tav.mode == Addressing_Constant);

		return ir_add_module_constant(proc->module, tv.type, tv.value);
	case_end;

	case_ast_node(te, TernaryExpr, expr);
		ir_emit_comment(proc, str_lit("TernaryExpr"));

		auto edges = array_make<irValue *>(ir_allocator(), 0, 2);

		GB_ASSERT(te->y != nullptr);
		irBlock *then  = ir_new_block(proc, nullptr, "if.then");
		irBlock *done  = ir_new_block(proc, nullptr, "if.done"); // NOTE(bill): Append later
		irBlock *else_ = ir_new_block(proc, nullptr, "if.else");

		irValue *cond = ir_build_cond(proc, te->cond, then, else_);
		ir_start_block(proc, then);

		Type *type = type_of_expr(expr);

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
		TokenPos pos = ast_token(expr).pos;
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
			Ast *ue_expr = unparen_expr(ue->expr);
			if (ue_expr->kind == Ast_TypeAssertion) {
				gbAllocator a = ir_allocator();
				GB_ASSERT(is_type_pointer(tv.type));

				ast_node(ta, TypeAssertion, ue_expr);
				TokenPos pos = ast_token(expr).pos;
				Type *type = type_of_expr(ue_expr);
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
					irValue *dst_tag = ir_const_union_tag(src_type, dst_type);

					irValue *ok = ir_emit_comp(proc, Token_CmpEq, src_tag, dst_tag);
					auto args = array_make<irValue *>(ir_allocator(), 6);
					args[0] = ok;

					args[1] = ir_find_or_add_entity_string(proc->module, pos.file);
					args[2] = ir_const_int(pos.line);
					args[3] = ir_const_int(pos.column);

					args[4] = ir_typeid(proc->module, src_type);
					args[5] = ir_typeid(proc->module, dst_type);
					ir_emit_runtime_call(proc, "type_assertion_check", args);

					irValue *data_ptr = v;
					return ir_emit_conv(proc, data_ptr, tv.type);
				} else if (is_type_any(t)) {
					irValue *v = e;
					if (is_type_pointer(ir_type(v))) {
						v = ir_emit_load(proc, v);
					}

					irValue *data_ptr = ir_emit_struct_ev(proc, v, 0);
					irValue *any_id = ir_emit_struct_ev(proc, v, 1);
					irValue *id = ir_typeid(proc->module, type);


					irValue *ok = ir_emit_comp(proc, Token_CmpEq, any_id, id);
					auto args = array_make<irValue *>(ir_allocator(), 6);
					args[0] = ok;

					args[1] = ir_find_or_add_entity_string(proc->module, pos.file);
					args[2] = ir_const_int(pos.line);
					args[3] = ir_const_int(pos.column);

					args[4] = any_id;
					args[5] = id;
					ir_emit_runtime_call(proc, "type_assertion_check", args);

					return ir_emit_conv(proc, data_ptr, tv.type);
				} else {
					GB_PANIC("TODO(bill): type assertion %s", type_to_string(type));
				}
			} else if (ue_expr->kind == Ast_IndexExpr) {
			#if 0
				ast_node(ie, IndexExpr, ue_expr);
				if (is_type_slice(ie->expr->tav.type)) {
					auto tav = ie->index->tav;
					if (tav.mode == Addressing_Constant) {
						if (exact_value_to_i64(tav.value) == 0) {
							irValue *s = ir_build_expr(proc, ie->expr);
							if (is_type_pointer(ir_type(s))) {
								s = ir_emit_load(proc, s);
							}
							return ir_slice_elem(proc, s);
						}
					}
				}
			#endif
			}

			return ir_build_addr_ptr(proc, ue->expr);
		}
		default:
			return ir_emit_unary_arith(proc, ue->op.kind, ir_build_expr(proc, ue->expr), tv.type);
		}
	case_end;

	case_ast_node(be, BinaryExpr, expr);
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
			irValue *left = ir_build_expr(proc, be->left);
			Type *type = default_type(tv.type);
			irValue *right = ir_build_expr(proc, be->right);
			return ir_emit_arith(proc, be->op.kind, left, right, type);
		}


		case Token_CmpEq:
		case Token_NotEq:
		case Token_Lt:
		case Token_LtEq:
		case Token_Gt:
		case Token_GtEq: {
			irValue *left = ir_build_expr(proc, be->left);
			Type *type = default_type(tv.type);
			irValue *right = ir_build_expr(proc, be->right);
			irValue *cmp = ir_emit_comp(proc, be->op.kind, left, right);
			return ir_emit_conv(proc, cmp, type);
		}

		case Token_CmpAnd:
		case Token_CmpOr:
			return ir_emit_logical_binary_expr(proc, expr);


		case Token_in:
		case Token_not_in: {
			irValue *left = ir_build_expr(proc, be->left);
			Type *type = default_type(tv.type);
			irValue *right = ir_build_expr(proc, be->right);
			Type *rt = base_type(ir_type(right));
			switch (rt->kind) {
			case Type_Map:
				{
					if (be->op.kind == Token_in) {
						ir_emit_comment(proc, str_lit("map in"));
					} else {
						ir_emit_comment(proc, str_lit("map not_in"));
					}

					irValue *addr = ir_address_from_load_or_generate_local(proc, right);
					irValue *h = ir_gen_map_header(proc, addr, rt);
					irValue *key = ir_gen_map_key(proc, left, rt->Map.key);

					auto args = array_make<irValue *>(ir_allocator(), 2);
					args[0] = h;
					args[1] = key;

					irValue *ptr = ir_emit_runtime_call(proc, "__dynamic_map_get", args);
					if (be->op.kind == Token_in) {
						return ir_emit_conv(proc, ir_emit_comp(proc, Token_NotEq, ptr, v_raw_nil), t_bool);
					} else {
						return ir_emit_conv(proc, ir_emit_comp(proc, Token_CmpEq, ptr, v_raw_nil), t_bool);
					}
				}
				break;
			case Type_BitSet:
				{
					if (be->op.kind == Token_in) {
						ir_emit_comment(proc, str_lit("bit_set in"));
					} else {
						ir_emit_comment(proc, str_lit("bit_set not_in"));
					}

					Type *key_type = rt->BitSet.elem;
					GB_ASSERT(are_types_identical(ir_type(left), key_type));

					Type *it = bit_set_to_int(rt);

					irValue *lower = ir_value_constant(it, exact_value_i64(rt->BitSet.lower));
					irValue *key = ir_emit_arith(proc, Token_Sub, left, lower, ir_type(left));
					irValue *bit = ir_emit_arith(proc, Token_Shl, v_one, key, ir_type(left));
					bit = ir_emit_conv(proc, bit, it);

					irValue *old_value = ir_emit_bitcast(proc, right, it);
					irValue *new_value = ir_emit_arith(proc, Token_And, old_value, bit, it);

					if (be->op.kind == Token_in) {
						return ir_emit_conv(proc, ir_emit_comp(proc, Token_NotEq, new_value, v_zero), t_bool);
					} else {
						return ir_emit_conv(proc, ir_emit_comp(proc, Token_CmpEq, new_value, v_zero), t_bool);
					}
				}
				break;
			default:
				GB_PANIC("Invalid 'in' type");
			}
			break;

		}

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
		TypeAndValue proc_tv = type_and_value_of_expr(ce->proc);
		AddressingMode proc_mode = proc_tv.mode;
		if (proc_mode == Addressing_Type) {
			GB_ASSERT(ce->args.count == 1);
			irValue *x = ir_build_expr(proc, ce->args[0]);
			irValue *y = ir_emit_conv(proc, x, tv.type);
			return y;
		}

		Ast *p = unparen_expr(ce->proc);
		if (proc_mode == Addressing_Builtin) {
			Entity *e = entity_of_node(p);
			BuiltinProcId id = BuiltinProc_Invalid;
			if (e != nullptr) {
				id = cast(BuiltinProcId)e->Builtin.id;
			} else {
				id = BuiltinProc_DIRECTIVE;
			}
			return ir_build_builtin_proc(proc, expr, tv, id);
		}

		// NOTE(bill): Regular call
		irValue *value = nullptr;
		Ast *proc_expr = unparen_expr(ce->proc);
		if (proc_expr->tav.mode == Addressing_Constant) {
			ExactValue v = proc_expr->tav.value;
			switch (v.kind) {
			case ExactValue_Integer:
				{
					u64 u = big_int_to_u64(&v.value_integer);
					irValue *x = ir_const_uintptr(u);
					x = ir_emit_conv(proc, x, t_rawptr);
					value = ir_emit_conv(proc, x, proc_expr->tav.type);
					break;
				}
			case ExactValue_Pointer:
				{
					u64 u = cast(u64)v.value_pointer;
					irValue *x = ir_const_uintptr(u);
					x = ir_emit_conv(proc, x, t_rawptr);
					value = ir_emit_conv(proc, x, proc_expr->tav.type);
					break;
				}
			}
		}

		if (value == nullptr) {
			value = ir_build_expr(proc, proc_expr);
		}

		GB_ASSERT(value != nullptr);
		Type *proc_type_ = base_type(ir_type(value));
		GB_ASSERT(proc_type_->kind == Type_Proc);
		TypeProc *pt = &proc_type_->Proc;
		set_procedure_abi_types(heap_allocator(), proc_type_);

		if (is_call_expr_field_value(ce)) {
			auto args = array_make<irValue *>(ir_allocator(), pt->param_count);

			for_array(arg_index, ce->args) {
				Ast *arg = ce->args[arg_index];
				ast_node(fv, FieldValue, arg);
				GB_ASSERT(fv->field->kind == Ast_Ident);
				String name = fv->field->Ident.token.string;
				isize index = lookup_procedure_parameter(pt, name);
				GB_ASSERT(index >= 0);
				TypeAndValue tav = type_and_value_of_expr(fv->value);
				if (tav.mode == Addressing_Type) {
					args[index] = ir_value_nil(tav.type);
				} else {
					args[index] = ir_build_expr(proc, fv->value);
				}
			}
			TypeTuple *params = &pt->params->Tuple;
			for (isize i = 0; i < args.count; i++) {
				Entity *e = params->variables[i];
				if (e->kind == Entity_TypeName) {
					args[i] = ir_value_nil(e->type);
				} else if (e->kind == Entity_Constant) {
					continue;
				} else {
					GB_ASSERT(e->kind == Entity_Variable);
					if (args[i] == nullptr) {
						switch (e->Variable.param_value.kind) {
						case ParameterValue_Constant:
							args[i] = ir_value_constant(e->type, e->Variable.param_value.value);
							break;
						case ParameterValue_Nil:
							args[i] = ir_value_nil(e->type);
							break;
						case ParameterValue_Location:
							args[i] = ir_emit_source_code_location(proc, proc->entity->token.string, ast_token(expr).pos);
							break;
						case ParameterValue_Value:
							args[i] = ir_build_expr(proc, e->Variable.param_value.ast_value);
							break;
						}
					} else {
						args[i] = ir_emit_conv(proc, args[i], e->type);
					}
				}
			}

			return ir_emit_call(proc, value, args, ce->inlining, proc->return_ptr_hint_ast == expr);
		}

		isize arg_index = 0;

		isize arg_count = 0;
		for_array(i, ce->args) {
			Ast *arg = ce->args[i];
			TypeAndValue tav = type_and_value_of_expr(arg);
			GB_ASSERT_MSG(tav.mode != Addressing_Invalid, "%s %s", expr_to_string(arg), expr_to_string(expr));
			GB_ASSERT_MSG(tav.mode != Addressing_ProcGroup, "%s", expr_to_string(arg));
			Type *at = tav.type;
			if (at->kind == Type_Tuple) {
				arg_count += at->Tuple.variables.count;
			} else {
				arg_count++;
			}
		}

		isize param_count = 0;
		if (pt->params) {
			GB_ASSERT(pt->params->kind == Type_Tuple);
			param_count = pt->params->Tuple.variables.count;
		}

		auto args = array_make<irValue *>(ir_allocator(), cast(isize)gb_max(param_count, arg_count));
		isize variadic_index = pt->variadic_index;
		bool variadic = pt->variadic && variadic_index >= 0;
		bool vari_expand = ce->ellipsis.pos.line != 0;
		bool is_c_vararg = pt->c_vararg;

		String proc_name = {};
		if (proc->entity != nullptr) {
			proc_name = proc->entity->token.string;
		}
		TokenPos pos = ast_token(ce->proc).pos;

		TypeTuple *param_tuple = nullptr;
		if (pt->params) {
			GB_ASSERT(pt->params->kind == Type_Tuple);
			param_tuple = &pt->params->Tuple;
		}

		for_array(i, ce->args) {
			Ast *arg = ce->args[i];
			TypeAndValue arg_tv = type_and_value_of_expr(arg);
			if (arg_tv.mode == Addressing_Type) {
				args[arg_index++] = ir_value_nil(arg_tv.type);
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
				isize end = cast(isize)param_count;
				if (variadic) {
					end = variadic_index;
				}
				while (arg_index < end) {
					Entity *e = param_tuple->variables[arg_index];
					GB_ASSERT(e->kind == Entity_Variable);

					switch (e->Variable.param_value.kind) {
					case ParameterValue_Constant:
						args[arg_index++] = ir_value_constant(e->type, e->Variable.param_value.value);
						break;
					case ParameterValue_Nil:
						args[arg_index++] = ir_value_nil(e->type);
						break;
					case ParameterValue_Location:
						args[arg_index++] = ir_emit_source_code_location(proc, proc_name, pos);
						break;
					case ParameterValue_Value:
						args[arg_index++] = ir_build_expr(proc, e->Variable.param_value.ast_value);
						break;
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
				for (isize i = 0; i < param_count; i++) {
					Entity *e = param_tuple->variables[i];
					if (e->kind == Entity_Variable) {
						GB_ASSERT(args[i] != nullptr);
						args[i] = ir_emit_conv(proc, args[i], e->type);
					}
				}
			}

			if (variadic && !vari_expand && !is_c_vararg) {
				ir_emit_comment(proc, str_lit("variadic call argument generation"));
				gbAllocator allocator = ir_allocator();
				Type *slice_type = param_tuple->variables[variadic_index]->type;
				Type *elem_type  = base_type(slice_type)->Slice.elem;
				irValue *slice = ir_add_local_generated(proc, slice_type, true);
				isize slice_len = arg_count+1 - (variadic_index+1);

				if (slice_len > 0) {
					irValue *base_array = ir_add_local_generated(proc, alloc_type_array(elem_type, slice_len), true);

					for (isize i = variadic_index, j = 0; i < arg_count; i++, j++) {
						irValue *addr = ir_emit_array_epi(proc, base_array, cast(i32)j);
						ir_emit_store(proc, addr, args[i]);
					}

					irValue *base_elem = ir_emit_array_epi(proc, base_array, 0);
					irValue *len = ir_const_int(slice_len);
					ir_fill_slice(proc, slice, base_elem, len);
				}

				arg_count = param_count;
				args[variadic_index] = ir_emit_load(proc, slice);
			}
		}

		if (variadic && variadic_index+1 < param_count) {
			for (isize i = variadic_index+1; i < param_count; i++) {
				Entity *e = param_tuple->variables[i];
				switch (e->Variable.param_value.kind) {
				case ParameterValue_Constant:
					args[i] = ir_value_constant(e->type, e->Variable.param_value.value);
					break;
				case ParameterValue_Nil:
					args[i] = ir_value_nil(e->type);
					break;
				case ParameterValue_Location:
					args[i] = ir_emit_source_code_location(proc, proc_name, pos);
					break;
				case ParameterValue_Value:
					args[i] = ir_build_expr(proc, e->Variable.param_value.ast_value);
					break;
				}
			}
		}

		isize final_count = param_count;
		if (is_c_vararg) {
			final_count = arg_count;
		}

		auto call_args = array_slice(args, 0, final_count);
		return ir_emit_call(proc, value, call_args, ce->inlining, proc->return_ptr_hint_ast == expr);
	case_end;

	case_ast_node(se, SliceExpr, expr);
		return ir_addr_load(proc, ir_build_addr(proc, expr));
	case_end;

	case_ast_node(ie, IndexExpr, expr);
		return ir_addr_load(proc, ir_build_addr(proc, expr));
	case_end;
	}

	GB_PANIC("Unexpected expression: %.*s", LIT(ast_strings[expr->kind]));
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

bool ir_is_elem_const(irModule *m, Ast *elem, Type *elem_type) {
	if (!elem_type_can_be_constant(elem_type)) {
		return false;
	}
	if (elem->kind == Ast_FieldValue) {
		elem = elem->FieldValue.value;
	}
	TypeAndValue tav = type_and_value_of_expr(elem);
	GB_ASSERT_MSG(tav.mode != Addressing_Invalid, "%s %s", expr_to_string(elem), type_to_string(tav.type));
	return tav.value.kind != ExactValue_Invalid;
}

irAddr ir_build_addr_from_entity(irProcedure *proc, Entity *e, Ast *expr) {
	GB_ASSERT(e != nullptr);
	if (e->kind == Entity_Constant) {
		Type *t = default_type(type_of_expr(expr));
		irValue *v = ir_add_module_constant(proc->module, t, e->Constant.value);
		irValue *g = ir_add_global_generated(proc->module, ir_type(v), v);
		return ir_addr(g);
	}


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


struct irCompoundLitElemTempData {
	Ast *expr;
	irValue *value;
	i32 elem_index;
	irValue *gep;
};

irAddr ir_build_addr(irProcedure *proc, Ast *expr) {
	switch (expr->kind) {
	case_ast_node(i, Implicit, expr);
		irValue *v = nullptr;
		switch (i->kind) {
		case Token_context:
			v = ir_find_or_generate_context_ptr(proc);
			break;
		}

		GB_ASSERT(v != nullptr);
		return ir_addr_context(v);
	case_end;

	case_ast_node(i, Ident, expr);
		if (is_blank_ident(expr)) {
			irAddr val = {};
			return val;
		}
		String name = i->token.string;
		Entity *e = entity_of_ident(expr);
		// GB_ASSERT(name == e->token.string);
		return ir_build_addr_from_entity(proc, e, expr);
	case_end;

	case_ast_node(pe, ParenExpr, expr);
		return ir_build_addr(proc, unparen_expr(expr));
	case_end;

	case_ast_node(se, SelectorExpr, expr);
		ir_emit_comment(proc, str_lit("SelectorExpr"));
		Ast *sel = unparen_expr(se->selector);
		if (sel->kind == Ast_Ident) {
			String selector = sel->Ident.token.string;
			TypeAndValue tav = type_and_value_of_expr(se->expr);

			if (tav.mode == Addressing_Invalid) {
				// NOTE(bill): Imports
				Entity *imp = entity_of_ident(se->expr);
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
				irAddr addr = ir_build_addr(proc, se->expr);
				if (addr.kind == irAddr_Context) {
					GB_ASSERT(sel.index.count > 0);
					if (addr.ctx.sel.index.count >= 0) {
						sel = selection_combine(addr.ctx.sel, sel);
					}
					addr.ctx.sel = sel;

					return addr;
				} else if (addr.kind == irAddr_SoaVariable) {
					irValue *index = addr.soa.index;
					i32 first_index = sel.index[0];
					Selection sub_sel = sel;
					sub_sel.index.data += 1;
					sub_sel.index.count -= 1;

					irValue *arr = ir_emit_struct_ep(proc, addr.addr, first_index);

					Type *t = base_type(type_deref(ir_type(addr.addr)));
					GB_ASSERT(is_type_soa_struct(t));

					if (addr.soa.index->kind != irValue_Constant || t->Struct.soa_kind != StructSoa_Fixed) {
						irValue *len = ir_soa_struct_len(proc, addr.addr);
						ir_emit_bounds_check(proc, ast_token(addr.soa.index_expr), addr.soa.index, len);
					}

					irValue *item = nullptr;

					if (t->Struct.soa_kind == StructSoa_Fixed) {
						item = ir_emit_array_ep(proc, arr, index);
					} else {
						item = ir_emit_load(proc, ir_emit_ptr_offset(proc, arr, index));
					}
					if (sub_sel.index.count > 0) {
						item = ir_emit_deep_field_gep(proc, item, sub_sel);
					}
					return ir_addr(item);
				}
				irValue *a = ir_addr_get_ptr(proc, addr);
				a = ir_emit_deep_field_gep(proc, a, sel);
				return ir_addr(a);
			}
		} else {
			GB_PANIC("Unsupported selector expression");
		}
	case_end;

	case_ast_node(ta, TypeAssertion, expr);
		gbAllocator a = ir_allocator();
		TokenPos pos = ast_token(expr).pos;
		irValue *e = ir_build_expr(proc, ta->expr);
		Type *t = type_deref(ir_type(e));
		if (is_type_union(t)) {
			Type *type = type_of_expr(expr);
			irValue *v = ir_add_local_generated(proc, type, false);
			ir_emit_comment(proc, str_lit("cast - union_cast"));
			ir_emit_store(proc, v, ir_emit_union_cast(proc, ir_build_expr(proc, ta->expr), type, pos));
			return ir_addr(v);
		} else if (is_type_any(t)) {
			ir_emit_comment(proc, str_lit("cast - any_cast"));
			Type *type = type_of_expr(expr);
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
		if (is_type_pointer(t)) {
			return ir_addr(v);
		}
		return ir_addr(ir_address_from_load_or_generate_local(proc, v));
	case_end;

	case_ast_node(ie, IndexExpr, expr);
		ir_emit_comment(proc, str_lit("IndexExpr"));
		Type *t = base_type(type_of_expr(ie->expr));
		gbAllocator a = ir_allocator();

		bool deref = is_type_pointer(t);
		t = base_type(type_deref(t));
		if (is_type_soa_struct(t)) {
			// SOA STRUCTURES!!!!
			irValue *val = ir_build_addr_ptr(proc, ie->expr);
			if (deref) {
				val = ir_emit_load(proc, val);
			}

			irValue *index = ir_build_expr(proc, ie->index);
			return ir_addr_soa_variable(val, index, ie->index);
		}

		if (ie->expr->tav.mode == Addressing_SoaVariable) {
			// SOA Structures for slices/dynamic arrays
			GB_ASSERT(is_type_pointer(type_of_expr(ie->expr)));

			irValue *field = ir_build_expr(proc, ie->expr);
			irValue *index = ir_build_expr(proc, ie->index);


			if (!build_context.no_bounds_check) {
				// TODO HACK(bill): Clean up this hack to get the length for bounds checking
				GB_ASSERT(field->kind == irValue_Instr);
				irInstr *instr = &field->Instr;

				GB_ASSERT(instr->kind == irInstr_Load);
				irValue *a = instr->Load.address;

				GB_ASSERT(a->kind == irValue_Instr);
				irInstr *b = &a->Instr;
				GB_ASSERT(b->kind == irInstr_StructElementPtr);
				irValue *base_struct = b->StructElementPtr.address;

				GB_ASSERT(is_type_soa_struct(type_deref(ir_type(base_struct))));
				irValue *len = ir_soa_struct_len(proc, base_struct);
				ir_emit_bounds_check(proc, ast_token(ie->index), index, len);
			}

			irValue *val = ir_emit_ptr_offset(proc, field, index);
			return ir_addr(val);
		}

		GB_ASSERT_MSG(is_type_indexable(t), "%s %s", type_to_string(t), expr_to_string(expr));

		if (is_type_map(t)) {
			irValue *map_val = ir_build_addr_ptr(proc, ie->expr);
			if (deref) {
				map_val = ir_emit_load(proc, map_val);
			}

			irValue *key = ir_build_expr(proc, ie->index);
			key = ir_emit_conv(proc, key, t->Map.key);

			Type *result_type = type_of_expr(expr);
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

			auto index_tv = type_and_value_of_expr(ie->index);
			if (index_tv.mode != Addressing_Constant) {
				irValue *len = ir_const_int(t->Array.count);
				ir_emit_bounds_check(proc, ast_token(ie->index), index, len);
			}
			return ir_addr(elem);
		}

		case Type_EnumeratedArray: {
			irValue *array = nullptr;
			if (using_addr != nullptr) {
				array = using_addr;
			} else {
				array = ir_build_addr_ptr(proc, ie->expr);
				if (deref) {
					array = ir_emit_load(proc, array);
				}
			}

			Type *index_type = t->EnumeratedArray.index;

			auto index_tv = type_and_value_of_expr(ie->index);

			irValue *index = nullptr;
			if (compare_exact_values(Token_NotEq, t->EnumeratedArray.min_value, exact_value_i64(0))) {
				if (index_tv.mode == Addressing_Constant) {
					ExactValue idx = exact_value_sub(index_tv.value, t->EnumeratedArray.min_value);
					index = ir_value_constant(index_type, idx);
				} else {
					index = ir_emit_conv(proc, ir_build_expr(proc, ie->index), t_int);
					index = ir_emit_arith(proc, Token_Sub, index, ir_value_constant(index_type, t->EnumeratedArray.min_value), index_type);
				}
			} else {
				index = ir_emit_conv(proc, ir_build_expr(proc, ie->index), t_int);
			}

			irValue *elem = ir_emit_array_ep(proc, array, index);

			if (index_tv.mode != Addressing_Constant) {
				irValue *len = ir_const_int(t->EnumeratedArray.count);
				ir_emit_bounds_check(proc, ast_token(ie->index), index, len);
			}
			return ir_addr(elem);
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
			ir_emit_bounds_check(proc, ast_token(ie->index), index, len);
			irValue *v = ir_emit_ptr_offset(proc, elem, index);
			return ir_addr(v);
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
			ir_emit_bounds_check(proc, ast_token(ie->index), index, len);
			irValue *v = ir_emit_ptr_offset(proc, elem, index);
			return ir_addr(v);
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
			ir_emit_bounds_check(proc, ast_token(ie->index), index, len);

			return ir_addr(ir_emit_ptr_offset(proc, elem, index));
		}
		}
	case_end;

	case_ast_node(se, SliceExpr, expr);
		ir_emit_comment(proc, str_lit("SliceExpr"));
		gbAllocator a = ir_allocator();
		irValue *low  = v_zero;
		irValue *high = nullptr;

		if (se->low  != nullptr) low  = ir_build_expr(proc, se->low);
		if (se->high != nullptr) high = ir_build_expr(proc, se->high);

		bool no_indices = se->low == nullptr && se->high == nullptr;

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

			if (!no_indices) {
				ir_emit_slice_bounds_check(proc, se->open, low, high, len, se->low != nullptr);
			}

			irValue *elem   = ir_emit_ptr_offset(proc, ir_slice_elem(proc, base), low);
			irValue *new_len = ir_emit_arith(proc, Token_Sub, high, low, t_int);

			irValue *slice = ir_add_local_generated(proc, slice_type, false);
			ir_fill_slice(proc, slice, elem, new_len);
			return ir_addr(slice);
		}

		case Type_DynamicArray: {
			Type *elem_type = type->DynamicArray.elem;
			Type *slice_type = alloc_type_slice(elem_type);

			irValue *len = ir_dynamic_array_len(proc, base);
			if (high == nullptr) high = len;

			if (!no_indices) {
				ir_emit_slice_bounds_check(proc, se->open, low, high, len, se->low != nullptr);
			}

			irValue *elem    = ir_emit_ptr_offset(proc, ir_dynamic_array_elem(proc, base), low);
			irValue *new_len = ir_emit_arith(proc, Token_Sub, high, low, t_int);

			irValue *slice = ir_add_local_generated(proc, slice_type, false);
			ir_fill_slice(proc, slice, elem, new_len);
			return ir_addr(slice);
		}


		case Type_Array: {
			Type *slice_type = alloc_type_slice(type->Array.elem);
			irValue *len = ir_array_len(proc, base);

			if (high == nullptr) high = len;

			bool low_const  = type_and_value_of_expr(se->low).mode  == Addressing_Constant;
			bool high_const = type_and_value_of_expr(se->high).mode == Addressing_Constant;

			if (!low_const || !high_const) {
				if (!no_indices) {
					ir_emit_slice_bounds_check(proc, se->open, low, high, len, se->low != nullptr);
				}
			}
			irValue *elem    = ir_emit_ptr_offset(proc, ir_array_elem(proc, addr), low);
			irValue *new_len = ir_emit_arith(proc, Token_Sub, high, low, t_int);

			irValue *slice = ir_add_local_generated(proc, slice_type, false);
			ir_fill_slice(proc, slice, elem, new_len);
			return ir_addr(slice);
		}

		case Type_Basic: {
			GB_ASSERT(type == t_string);
			irValue *len = ir_string_len(proc, base);
			if (high == nullptr) high = len;

			if (!no_indices) {
				ir_emit_slice_bounds_check(proc, se->open, low, high, len, se->low != nullptr);
			}

			irValue *elem    = ir_emit_ptr_offset(proc, ir_string_elem(proc, base), low);
			irValue *new_len = ir_emit_arith(proc, Token_Sub, high, low, t_int);

			irValue *str = ir_add_local_generated(proc, t_string, false);
			ir_fill_string(proc, str, elem, new_len);
			return ir_addr(str);
		}


		case Type_Struct:
			if (is_type_soa_struct(type)) {
				irValue *len = ir_soa_struct_len(proc, addr);
				if (high == nullptr) high = len;

				if (!no_indices) {
					ir_emit_slice_bounds_check(proc, se->open, low, high, len, se->low != nullptr);
				}

				irValue *dst = ir_add_local_generated(proc, type_of_expr(expr), true);
				if (type->Struct.soa_kind == StructSoa_Fixed) {
					i32 field_count = cast(i32)type->Struct.fields.count;
					for (i32 i = 0; i < field_count; i++) {
						irValue *field_dst = ir_emit_struct_ep(proc, dst, i);
						irValue *field_src = ir_emit_struct_ep(proc, addr, i);
						field_src = ir_emit_array_ep(proc, field_src, low);
						ir_emit_store(proc, field_dst, field_src);
					}

					irValue *len_dst = ir_emit_struct_ep(proc, dst, field_count);
					irValue *new_len = ir_emit_arith(proc, Token_Sub, high, low, t_int);
					ir_emit_store(proc, len_dst, new_len);
				} else if (type->Struct.soa_kind == StructSoa_Slice) {
					if (no_indices) {
						ir_emit_store(proc, dst, base);
					} else {
						i32 field_count = cast(i32)type->Struct.fields.count - 1;
						for (i32 i = 0; i < field_count; i++) {
							irValue *field_dst = ir_emit_struct_ep(proc, dst, i);
							irValue *field_src = ir_emit_struct_ev(proc, base, i);
							field_src = ir_emit_ptr_offset(proc, field_src, low);
							ir_emit_store(proc, field_dst, field_src);
						}


						irValue *len_dst = ir_emit_struct_ep(proc, dst, field_count);
						irValue *new_len = ir_emit_arith(proc, Token_Sub, high, low, t_int);
						ir_emit_store(proc, len_dst, new_len);
					}
				} else if (type->Struct.soa_kind == StructSoa_Dynamic) {
					i32 field_count = cast(i32)type->Struct.fields.count - 3;
					for (i32 i = 0; i < field_count; i++) {
						irValue *field_dst = ir_emit_struct_ep(proc, dst, i);
						irValue *field_src = ir_emit_struct_ev(proc, base, i);
						field_src = ir_emit_ptr_offset(proc, field_src, low);
						ir_emit_store(proc, field_dst, field_src);
					}


					irValue *len_dst = ir_emit_struct_ep(proc, dst, field_count);
					irValue *new_len = ir_emit_arith(proc, Token_Sub, high, low, t_int);
					ir_emit_store(proc, len_dst, new_len);
				}

				return ir_addr(dst);
			}
			break;

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
		irValue *v = ir_add_local_generated(proc, ir_type(e), false);
		ir_emit_store(proc, v, e);
		return ir_addr(v);
	case_end;

	case_ast_node(cl, CompoundLit, expr);
		ir_emit_comment(proc, str_lit("CompoundLit"));
		Type *type = type_of_expr(expr);
		Type *bt = base_type(type);

		irValue *v = ir_add_local_generated(proc, type, true);

		Type *et = nullptr;
		switch (bt->kind) {
		case Type_Array:  et = bt->Array.elem;  break;
		case Type_EnumeratedArray: et = bt->EnumeratedArray.elem; break;
		case Type_Slice:  et = bt->Slice.elem;  break;
		case Type_BitSet: et = bt->BitSet.elem; break;
		case Type_SimdVector: et = bt->SimdVector.elem; break;
		}

		String proc_name = {};
		if (proc->entity) {
			proc_name = proc->entity->token.string;
		}
		TokenPos pos = ast_token(expr).pos;

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
					Ast *elem = cl->elems[field_index];

					irValue *field_expr = nullptr;
					Entity *field = nullptr;
					isize index = field_index;

					if (elem->kind == Ast_FieldValue) {
						ast_node(fv, FieldValue, elem);
						String name = fv->field->Ident.token.string;
						Selection sel = lookup_field(bt, name, false);
						index = sel.index[0];
						elem = fv->value;
						TypeAndValue tav = type_and_value_of_expr(elem);
					} else {
						TypeAndValue tav = type_and_value_of_expr(elem);
						Selection sel = lookup_field_from_index(bt, st->fields[field_index]->Variable.field_src_index);
						index = sel.index[0];
					}

					field = st->fields[index];
					Type *ft = field->type;
					if (!is_raw_union && !is_type_typeid(ft) && ir_is_elem_const(proc->module, elem, ft)) {
						continue;
					}

					field_expr = ir_build_expr(proc, elem);


					GB_ASSERT(ir_type(field_expr)->kind != Type_Tuple);

					Type *fet = ir_type(field_expr);
					// HACK TODO(bill): THIS IS A MASSIVE HACK!!!!
					if (is_type_union(ft) && !are_types_identical(fet, ft) && !is_type_untyped(fet)) {
						GB_ASSERT_MSG(union_variant_index(ft, fet) > 0, "%s", type_to_string(fet));

						irValue *gep = ir_emit_struct_ep(proc, v, cast(i32)index);
						ir_emit_store_union_variant(proc, gep, field_expr, fet);
					} else {
						irValue *fv = ir_emit_conv(proc, field_expr, ft);
						irValue *gep = ir_emit_struct_ep(proc, v, cast(i32)index);
						ir_emit_store(proc, gep, fv);
					}
				}
			}
			break;
		}

		case Type_Map: {
			if (cl->elems.count == 0) {
				break;
			}
			gbAllocator a = ir_allocator();
			{
				auto args = array_make<irValue *>(a, 3);
				args[0] = ir_gen_map_header(proc, v, type);
				args[1] = ir_const_int(2*cl->elems.count);
				args[2] = ir_emit_source_code_location(proc, proc_name, pos);
				ir_emit_runtime_call(proc, "__dynamic_map_reserve", args);
			}
			for_array(field_index, cl->elems) {
				Ast *elem = cl->elems[field_index];
				ast_node(fv, FieldValue, elem);

				irValue *key   = ir_build_expr(proc, fv->field);
				irValue *value = ir_build_expr(proc, fv->value);
				ir_insert_dynamic_map_key_and_value(proc, v, type, key, value);
			}
			break;
		}

		case Type_Array: {
			if (cl->elems.count > 0) {
				ir_emit_store(proc, v, ir_add_module_constant(proc->module, type, exact_value_compound(expr)));

				auto temp_data = array_make<irCompoundLitElemTempData>(heap_allocator(), 0, cl->elems.count);
				defer (array_free(&temp_data));

				// NOTE(bill): Separate value, gep, store into their own chunks
				for_array(i, cl->elems) {
					Ast *elem = cl->elems[i];
					if (elem->kind == Ast_FieldValue) {
						ast_node(fv, FieldValue, elem);
						if (ir_is_elem_const(proc->module, fv->value, et)) {
							continue;
						}
						if (is_ast_range(fv->field)) {
							ast_node(ie, BinaryExpr, fv->field);
							TypeAndValue lo_tav = ie->left->tav;
							TypeAndValue hi_tav = ie->right->tav;
							GB_ASSERT(lo_tav.mode == Addressing_Constant);
							GB_ASSERT(hi_tav.mode == Addressing_Constant);

							TokenKind op = ie->op.kind;
							i64 lo = exact_value_to_i64(lo_tav.value);
							i64 hi = exact_value_to_i64(hi_tav.value);
							if (op == Token_Ellipsis) {
								hi += 1;
							}

							irValue *value = ir_build_expr(proc, fv->value);

							for (i64 k = lo; k < hi; k++) {
								irCompoundLitElemTempData data = {};
								data.value = value;
								data.elem_index = cast(i32)k;
								array_add(&temp_data, data);
							}

						} else {
							auto tav = fv->field->tav;
							GB_ASSERT(tav.mode == Addressing_Constant);
							i64 index = exact_value_to_i64(tav.value);

							irCompoundLitElemTempData data = {};
							data.value = ir_emit_conv(proc, ir_build_expr(proc, fv->value), et);
							data.expr = fv->value;
							data.elem_index = cast(i32)index;
							array_add(&temp_data, data);
						}

					} else {
						if (ir_is_elem_const(proc->module, elem, et)) {
							continue;
						}
						irCompoundLitElemTempData data = {};
						data.expr = elem;
						data.elem_index = cast(i32)i;
						array_add(&temp_data, data);
					}
				}

				for_array(i, temp_data) {
					temp_data[i].gep = ir_emit_array_epi(proc, v, temp_data[i].elem_index);
				}

				for_array(i, temp_data) {
					auto return_ptr_hint_ast   = proc->return_ptr_hint_ast;
					auto return_ptr_hint_value = proc->return_ptr_hint_value;
					auto return_ptr_hint_used  = proc->return_ptr_hint_used;
					defer (proc->return_ptr_hint_ast   = return_ptr_hint_ast);
					defer (proc->return_ptr_hint_value = return_ptr_hint_value);
					defer (proc->return_ptr_hint_used  = return_ptr_hint_used);

					irValue *field_expr = temp_data[i].value;
					Ast *expr = temp_data[i].expr;

					proc->return_ptr_hint_value = temp_data[i].gep;
					proc->return_ptr_hint_ast = unparen_expr(expr);

					if (field_expr == nullptr) {
						field_expr = ir_build_expr(proc, expr);
					}
					Type *t = ir_type(field_expr);
					GB_ASSERT(t->kind != Type_Tuple);
					irValue *ev = ir_emit_conv(proc, field_expr, et);

					if (!proc->return_ptr_hint_used) {
						temp_data[i].value = ev;
					}
				}

				for_array(i, temp_data) {
					if (temp_data[i].value != nullptr) {
						ir_emit_store(proc, temp_data[i].gep, temp_data[i].value, false);
					}
				}
			}
			break;
		}
		case Type_EnumeratedArray: {
			if (cl->elems.count > 0) {
				ir_emit_store(proc, v, ir_add_module_constant(proc->module, type, exact_value_compound(expr)));

				auto temp_data = array_make<irCompoundLitElemTempData>(heap_allocator(), 0, cl->elems.count);
				defer (array_free(&temp_data));

				// NOTE(bill): Separate value, gep, store into their own chunks
				for_array(i, cl->elems) {
					Ast *elem = cl->elems[i];
					if (elem->kind == Ast_FieldValue) {
						ast_node(fv, FieldValue, elem);
						if (ir_is_elem_const(proc->module, fv->value, et)) {
							continue;
						}
						if (is_ast_range(fv->field)) {
							ast_node(ie, BinaryExpr, fv->field);
							TypeAndValue lo_tav = ie->left->tav;
							TypeAndValue hi_tav = ie->right->tav;
							GB_ASSERT(lo_tav.mode == Addressing_Constant);
							GB_ASSERT(hi_tav.mode == Addressing_Constant);

							TokenKind op = ie->op.kind;
							i64 lo = exact_value_to_i64(lo_tav.value);
							i64 hi = exact_value_to_i64(hi_tav.value);
							if (op == Token_Ellipsis) {
								hi += 1;
							}

							irValue *value = ir_build_expr(proc, fv->value);

							for (i64 k = lo; k < hi; k++) {
								irCompoundLitElemTempData data = {};
								data.value = value;
								data.elem_index = cast(i32)k;
								array_add(&temp_data, data);
							}

						} else {
							auto tav = fv->field->tav;
							GB_ASSERT(tav.mode == Addressing_Constant);
							i64 index = exact_value_to_i64(tav.value);

							irCompoundLitElemTempData data = {};
							data.value = ir_emit_conv(proc, ir_build_expr(proc, fv->value), et);
							data.expr = fv->value;
							data.elem_index = cast(i32)index;
							array_add(&temp_data, data);
						}

					} else {
						if (ir_is_elem_const(proc->module, elem, et)) {
							continue;
						}
						irCompoundLitElemTempData data = {};
						data.expr = elem;
						data.elem_index = cast(i32)i;
						array_add(&temp_data, data);
					}
				}


				i32 index_offset = cast(i32)exact_value_to_i64(bt->EnumeratedArray.min_value);

				for_array(i, temp_data) {
					i32 index = temp_data[i].elem_index - index_offset;
					temp_data[i].gep = ir_emit_array_epi(proc, v, index);
				}

				for_array(i, temp_data) {
					auto return_ptr_hint_ast   = proc->return_ptr_hint_ast;
					auto return_ptr_hint_value = proc->return_ptr_hint_value;
					auto return_ptr_hint_used  = proc->return_ptr_hint_used;
					defer (proc->return_ptr_hint_ast   = return_ptr_hint_ast);
					defer (proc->return_ptr_hint_value = return_ptr_hint_value);
					defer (proc->return_ptr_hint_used  = return_ptr_hint_used);

					irValue *field_expr = temp_data[i].value;
					Ast *expr = temp_data[i].expr;

					proc->return_ptr_hint_value = temp_data[i].gep;
					proc->return_ptr_hint_ast = unparen_expr(expr);

					if (field_expr == nullptr) {
						field_expr = ir_build_expr(proc, expr);
					}
					Type *t = ir_type(field_expr);
					GB_ASSERT(t->kind != Type_Tuple);
					irValue *ev = ir_emit_conv(proc, field_expr, et);

					if (!proc->return_ptr_hint_used) {
						temp_data[i].value = ev;
					}
				}

				for_array(i, temp_data) {
					if (temp_data[i].value != nullptr) {
						ir_emit_store(proc, temp_data[i].gep, temp_data[i].value, false);
					}
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

				auto temp_data = array_make<irCompoundLitElemTempData>(heap_allocator(), 0, cl->elems.count);
				defer (array_free(&temp_data));

				for_array(i, cl->elems) {
					Ast *elem = cl->elems[i];
					if (elem->kind == Ast_FieldValue) {
						ast_node(fv, FieldValue, elem);

						if (ir_is_elem_const(proc->module, fv->value, et)) {
							continue;
						}

						if (is_ast_range(fv->field)) {
							ast_node(ie, BinaryExpr, fv->field);
							TypeAndValue lo_tav = ie->left->tav;
							TypeAndValue hi_tav = ie->right->tav;
							GB_ASSERT(lo_tav.mode == Addressing_Constant);
							GB_ASSERT(hi_tav.mode == Addressing_Constant);

							TokenKind op = ie->op.kind;
							i64 lo = exact_value_to_i64(lo_tav.value);
							i64 hi = exact_value_to_i64(hi_tav.value);
							if (op == Token_Ellipsis) {
								hi += 1;
							}

							irValue *value = ir_emit_conv(proc, ir_build_expr(proc, fv->value), et);

							for (i64 k = lo; k < hi; k++) {
								irCompoundLitElemTempData data = {};
								data.value = value;
								data.elem_index = cast(i32)k;
								array_add(&temp_data, data);
							}

						} else {
							GB_ASSERT(fv->field->tav.mode == Addressing_Constant);
							i64 index = exact_value_to_i64(fv->field->tav.value);

							irValue *field_expr = ir_build_expr(proc, fv->value);
							GB_ASSERT(!is_type_tuple(ir_type(field_expr)));

							irValue *ev = ir_emit_conv(proc, field_expr, et);

							irCompoundLitElemTempData data = {};
							data.value = ev;
							data.elem_index = cast(i32)index;
							array_add(&temp_data, data);
						}
					} else {
						if (ir_is_elem_const(proc->module, elem, et)) {
							continue;
						}
						irValue *field_expr = ir_build_expr(proc, elem);
						GB_ASSERT(!is_type_tuple(ir_type(field_expr)));

						irValue *ev = ir_emit_conv(proc, field_expr, et);

						irCompoundLitElemTempData data = {};
						data.value = ev;
						data.elem_index = cast(i32)i;
						array_add(&temp_data, data);
					}
				}

				for_array(i, temp_data) {
					temp_data[i].gep = ir_emit_ptr_offset(proc, data, ir_const_int(temp_data[i].elem_index));
				}

				for_array(i, temp_data) {
					ir_emit_store(proc, temp_data[i].gep, temp_data[i].value);
				}

				irValue *count = ir_const_int(slice->ConstantSlice.count);
				ir_fill_slice(proc, v, data, count);
			}
			break;
		}

		case Type_DynamicArray: {
			if (cl->elems.count == 0) {
				break;
			}
			Type *et = bt->DynamicArray.elem;
			gbAllocator a = ir_allocator();
			irValue *size  = ir_const_int(type_size_of(et));
			irValue *align = ir_const_int(type_align_of(et));

			i64 item_count = gb_max(cl->max_count, cl->elems.count);
			{

				auto args = array_make<irValue *>(a, 5);
				args[0] = ir_emit_conv(proc, v, t_rawptr);
				args[1] = size;
				args[2] = align;
				args[3] = ir_const_int(2*item_count); // TODO(bill): Is this too much waste?
				args[4] = ir_emit_source_code_location(proc, proc_name, pos);
				ir_emit_runtime_call(proc, "__dynamic_array_reserve", args);
			}

			irValue *items = ir_generate_array(proc->module, et, item_count, str_lit("dacl$"), cast(i64)cast(intptr)expr);

			for_array(i, cl->elems) {
				Ast *elem = cl->elems[i];
				if (elem->kind == Ast_FieldValue) {
					ast_node(fv, FieldValue, elem);
					if (is_ast_range(fv->field)) {
						ast_node(ie, BinaryExpr, fv->field);
						TypeAndValue lo_tav = ie->left->tav;
						TypeAndValue hi_tav = ie->right->tav;
						GB_ASSERT(lo_tav.mode == Addressing_Constant);
						GB_ASSERT(hi_tav.mode == Addressing_Constant);

						TokenKind op = ie->op.kind;
						i64 lo = exact_value_to_i64(lo_tav.value);
						i64 hi = exact_value_to_i64(hi_tav.value);
						if (op == Token_Ellipsis) {
							hi += 1;
						}

						irValue *value = ir_emit_conv(proc, ir_build_expr(proc, fv->value), et);

						for (i64 k = lo; k < hi; k++) {
							irValue *ep = ir_emit_array_epi(proc, items, cast(i32)k);
							ir_emit_store(proc, ep, value);
						}
					} else {
						GB_ASSERT(fv->field->tav.mode == Addressing_Constant);

						i64 field_index = exact_value_to_i64(fv->field->tav.value);

						irValue *ev = ir_build_expr(proc, fv->value);
						irValue *value = ir_emit_conv(proc, ev, et);
						irValue *ep = ir_emit_array_epi(proc, items, cast(i32)field_index);
						ir_emit_store(proc, ep, value);
					}
				} else {
					irValue *value = ir_emit_conv(proc, ir_build_expr(proc, elem), et);
					irValue *ep = ir_emit_array_epi(proc, items, cast(i32)i);
					ir_emit_store(proc, ep, value);
				}
			}

			{
				auto args = array_make<irValue *>(a, 6);
				args[0] = ir_emit_conv(proc, v, t_rawptr);
				args[1] = size;
				args[2] = align;
				args[3] = ir_emit_conv(proc, items, t_rawptr);
				args[4] = ir_const_int(item_count);
				args[5] = ir_emit_source_code_location(proc, proc_name, pos);
				ir_emit_runtime_call(proc, "__dynamic_array_append", args);
			}
			break;
		}

		case Type_Basic: {
			GB_ASSERT(is_type_any(bt));
			if (cl->elems.count > 0) {
				ir_emit_store(proc, v, ir_add_module_constant(proc->module, type, exact_value_compound(expr)));
				String field_names[2] = {
					str_lit("data"),
					str_lit("id"),
				};
				Type *field_types[2] = {
					t_rawptr,
					t_typeid,
				};

				for_array(field_index, cl->elems) {
					Ast *elem = cl->elems[field_index];

					irValue *field_expr = nullptr;
					isize index = field_index;

					if (elem->kind == Ast_FieldValue) {
						ast_node(fv, FieldValue, elem);
						Selection sel = lookup_field(bt, fv->field->Ident.token.string, false);
						index = sel.index[0];
						elem = fv->value;
					} else {
						TypeAndValue tav = type_and_value_of_expr(elem);
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

			break;
		}

		case Type_BitSet: {
			i64 sz = type_size_of(type);
			if (cl->elems.count > 0 && sz > 0) {
				ir_emit_store(proc, v, ir_add_module_constant(proc->module, type, exact_value_compound(expr)));

				irValue *lower = ir_value_constant(t_int, exact_value_i64(bt->BitSet.lower));
				for_array(i, cl->elems) {
					Ast *elem = cl->elems[i];
					GB_ASSERT(elem->kind != Ast_FieldValue);

					if (ir_is_elem_const(proc->module, elem, et)) {
						continue;
					}

					irValue *expr = ir_build_expr(proc, elem);
					GB_ASSERT(ir_type(expr)->kind != Type_Tuple);

					Type *it = bit_set_to_int(bt);
					irValue *e = ir_emit_conv(proc, expr, it);
					e = ir_emit_arith(proc, Token_Sub, e, lower, it);
					e = ir_emit_arith(proc, Token_Shl, v_one, e, it);

					irValue *old_value = ir_emit_bitcast(proc, ir_emit_load(proc, v), it);
					irValue *new_value = ir_emit_arith(proc, Token_Or, old_value, e, it);
					new_value = ir_emit_bitcast(proc, new_value, type);
					ir_emit_store(proc, v, new_value);
				}
			}
			break;
		}

		}

		return ir_addr(v);
	case_end;

	case_ast_node(tc, TypeCast, expr);
		Type *type = type_of_expr(expr);
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
		irValue *v = ir_add_local_generated(proc, type, false);
		ir_emit_store(proc, v, e);
		return ir_addr(v);
	case_end;

	case_ast_node(ac, AutoCast, expr);
		return ir_build_addr(proc, ac->expr);
	case_end;
	}

	TokenPos token_pos = ast_token(expr).pos;
	GB_PANIC("Unexpected address expression\n"
	         "\tAst: %.*s @ "
	         "%.*s(%td:%td)\n",
	         LIT(ast_strings[expr->kind]),
	         LIT(token_pos.file), token_pos.line, token_pos.column);


	return ir_addr(nullptr);
}

void ir_build_assign_op(irProcedure *proc, irAddr const &lhs, irValue *value, TokenKind op) {
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

irValue *ir_build_cond(irProcedure *proc, Ast *cond, irBlock *true_block, irBlock *false_block) {
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

void ir_build_nested_proc(irProcedure *proc, AstProcLit *pd, Entity *e) {
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
	u8 *name_text = gb_alloc_array(ir_allocator(), u8, name_len);

	i32 guid = cast(i32)proc->children.count;
	name_len = gb_snprintf(cast(char *)name_text, name_len, "%.*s.%.*s-%d", LIT(proc->name), LIT(pd_name), guid);
	String name = make_string(name_text, name_len-1);

	set_procedure_abi_types(heap_allocator(), e->type);
	irValue *value = ir_value_procedure(proc->module, e, e->type, pd->type, pd->body, name);

	value->Proc.tags = pd->tags;
	value->Proc.inlining = pd->inlining;
	value->Proc.parent = proc;

	ir_module_add_value(proc->module, e, value);
	array_add(&proc->children, &value->Proc);
	array_add(&proc->module->procs_to_generate, value);
}


void ir_build_constant_value_decl(irProcedure *proc, AstValueDecl *vd) {
	if (vd == nullptr || vd->is_mutable) {
		return;
	}

	for_array(i, vd->names) {
		Ast *ident = vd->names[i];
		GB_ASSERT(ident->kind == Ast_Ident);
		Entity *e = entity_of_ident(ident);
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
			u8 *name_text = gb_alloc_array(ir_allocator(), u8, name_len);
			i32 guid = cast(i32)m->members.entries.count;
			name_len = gb_snprintf(cast(char *)name_text, name_len, "%.*s.%.*s-%d", LIT(proc->name), LIT(ts_name), guid);

			String name = make_string(name_text, name_len-1);

			irValue *value = ir_value_type_name(name, e->type);
			ir_add_entity_name(m, e, name);
			ir_gen_global_type_name(m, e, name);
		} else if (e->kind == Entity_Procedure) {
			CheckerInfo *info = proc->module->info;
			DeclInfo *decl = decl_info_of_entity(e);
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
						DeclInfo *d = decl_info_of_entity(e);
						ir_build_nested_proc(proc, &d->proc_lit->ProcLit, e);
					}
				} else {
					ir_build_nested_proc(proc, pl, e);
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

				HashKey key = hash_string(name);
				irValue **prev_value = map_get(&proc->module->members, key);
				if (prev_value != nullptr) {
					// NOTE(bill): Don't do mutliple declarations in the IR
					return;
				}

				set_procedure_abi_types(heap_allocator(), e->type);
				irValue *value = ir_value_procedure(proc->module, e, e->type, pl->type, pl->body, name);

				value->Proc.tags = pl->tags;
				value->Proc.inlining = pl->inlining;

				if (value->Proc.is_foreign || value->Proc.is_export) {
					map_set(&proc->module->members, key, value);
				} else {
					array_add(&proc->children, &value->Proc);
				}

				ir_module_add_value(proc->module, e, value);
				ir_build_proc(value, proc);
			}
		}
	}
}

void ir_build_stmt_list(irProcedure *proc, Array<Ast *> stmts) {
	// NOTE(bill): Precollect constant entities
	for_array(i, stmts) {
		Ast *stmt = stmts[i];
		switch (stmt->kind) {
		case_ast_node(vd, ValueDecl, stmt);
			ir_build_constant_value_decl(proc, vd);
		case_end;
		case_ast_node(fb, ForeignBlockDecl, stmt);
			ast_node(block, BlockStmt, fb->body);
			ir_build_stmt_list(proc, block->stmts);
		case_end;
		}
	}
	for_array(i, stmts) {
		ir_build_stmt(proc, stmts[i]);
	}
}

void ir_build_stmt_internal(irProcedure *proc, Ast *node);
void ir_build_stmt(irProcedure *proc, Ast *node) {
	u64 prev_state_flags = proc->module->state_flags;
	defer (proc->module->state_flags = prev_state_flags);

	if (node->state_flags != 0) {
		u64 in = node->state_flags;
		u64 out = proc->module->state_flags;

		if (in & StateFlag_bounds_check) {
			out |= StateFlag_bounds_check;
			out &= ~StateFlag_no_bounds_check;
		} else if (in & StateFlag_no_bounds_check) {
			out |= StateFlag_no_bounds_check;
			out &= ~StateFlag_bounds_check;
		}

		proc->module->state_flags = out;
	}

	ir_push_debug_location(proc->module, node, proc->debug_scope);
	ir_build_stmt_internal(proc, node);
	ir_pop_debug_location(proc->module);

}

void ir_build_when_stmt(irProcedure *proc, AstWhenStmt *ws) {
	irValue *cond = ir_build_expr(proc, ws->cond);
	GB_ASSERT(cond->kind == irValue_Constant &&
	          is_type_boolean(ir_type(cond)));

	GB_ASSERT(cond->Constant.value.kind == ExactValue_Bool);
	if (cond->Constant.value.value_bool) {
		ir_build_stmt_list(proc, ws->body->BlockStmt.stmts);
	} else if (ws->else_stmt) {
		switch (ws->else_stmt->kind) {
		case Ast_BlockStmt:
			ir_build_stmt_list(proc, ws->else_stmt->BlockStmt.stmts);
			break;
		case Ast_WhenStmt:
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
		count = ir_const_int(expr_type->Array.count);
		break;
	}

	irValue *val = nullptr;
	irValue *idx = nullptr;
	irBlock *loop = nullptr;
	irBlock *done = nullptr;
	irBlock *body = nullptr;


	irValue *index = ir_add_local_generated(proc, t_int, false);
	ir_emit_store(proc, index, ir_const_int(-1));

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
	case Type_EnumeratedArray: {
		if (val_type != nullptr) {
			val = ir_emit_load(proc, ir_emit_array_ep(proc, expr, idx));
			// NOTE(bill): Override the idx value for the enumeration
			Type *index_type =expr_type->EnumeratedArray.index;
			if (compare_exact_values(Token_NotEq, expr_type->EnumeratedArray.min_value, exact_value_u64(0))) {
				idx = ir_emit_arith(proc, Token_Add, idx, ir_value_constant(index_type, expr_type->EnumeratedArray.min_value), index_type);
			}
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
		irValue *key = ir_add_local_generated(proc, expr_type->Map.key, true);

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


	irValue *offset_ = ir_add_local_generated(proc, t_int, false);
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
	auto args = array_make<irValue *>(ir_allocator(), 1);
	args[0] = ir_emit_string(proc, str_elem, str_len);
	irValue *rune_and_len = ir_emit_runtime_call(proc, "string_decode_rune", args);
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


void ir_build_range_interval(irProcedure *proc, AstBinaryExpr *node, Type *val_type,
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
	irValue *value = ir_add_local_generated(proc, val_type, false);
	ir_emit_store(proc, value, lower);

	irValue *index = ir_add_local_generated(proc, t_int, false);
	ir_emit_store(proc, index, ir_const_int(0));

	loop = ir_new_block(proc, nullptr, "for.interval.loop");
	ir_emit_jump(proc, loop);
	ir_start_block(proc, loop);

	body = ir_new_block(proc, nullptr, "for.interval.body");
	done = ir_new_block(proc, nullptr, "for.interval.done");


	TokenKind op = Token_Lt;
	switch (node->op.kind) {
	case Token_Ellipsis:  op = Token_LtEq; break;
	case Token_RangeHalf: op = Token_Lt;  break;
	default: GB_PANIC("Invalid interval operator"); break;
	}

	upper = ir_build_expr(proc, node->right);

	irValue *curr_value = ir_emit_load(proc, value);
	irValue *cond = ir_emit_comp(proc, op, curr_value, upper);
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

void ir_build_range_enum(irProcedure *proc, Type *enum_type, Type *val_type, irValue **val_, irValue **idx_, irBlock **loop_, irBlock **done_) {
	Type *t = enum_type;
	GB_ASSERT(is_type_enum(t));
	Type *enum_ptr = alloc_type_pointer(t);
	t = base_type(t);
	Type *core_elem = core_type(t);
	GB_ASSERT(t->kind == Type_Enum);
	i64 enum_count = t->Enum.fields.count;
	irValue *max_count = ir_const_int(enum_count);

	irValue *ti          = ir_type_info(proc, t);
	irValue *variant     = ir_emit_struct_ep(proc, ti, 3);
	irValue *eti_ptr     = ir_emit_conv(proc, variant, t_type_info_enum_ptr);
	irValue *values      = ir_emit_load(proc, ir_emit_struct_ep(proc, eti_ptr, 2));
	irValue *values_data = ir_slice_elem(proc, values);

	irValue *offset_ = ir_add_local_generated(proc, t_int, false);
	ir_emit_store(proc, offset_, v_zero);

	irBlock *loop = ir_new_block(proc, nullptr, "for.enum.loop");
	ir_emit_jump(proc, loop);
	ir_start_block(proc, loop);

	irBlock *body = ir_new_block(proc, nullptr, "for.enum.body");
	irBlock *done = ir_new_block(proc, nullptr, "for.enum.done");

	irValue *offset = ir_emit_load(proc, offset_);
	irValue *cond = ir_emit_comp(proc, Token_Lt, offset, max_count);
	ir_emit_if(proc, cond, body, done);
	ir_start_block(proc, body);

	irValue *val_ptr = ir_emit_ptr_offset(proc, values_data, offset);
	ir_emit_increment(proc, offset_);

	irValue *val = nullptr;
	if (val_type != nullptr) {
		GB_ASSERT(are_types_identical(enum_type, val_type));

		if (is_type_integer(core_elem)) {
			irValue *i = ir_emit_load(proc, ir_emit_conv(proc, val_ptr, t_i64_ptr));
			val = ir_emit_conv(proc, i, t);
		} else {
			GB_PANIC("TODO(bill): enum core type %s", type_to_string(core_elem));
		}
	}

	if (val_)  *val_  = val;
	if (idx_)  *idx_  = offset;
	if (loop_) *loop_ = loop;
	if (done_) *done_ = done;
}

void ir_build_range_tuple(irProcedure *proc, Ast *expr, Type *val0_type, Type *val1_type,
                          irValue **val0_, irValue **val1_, irBlock **loop_, irBlock **done_) {
	irBlock *loop = ir_new_block(proc, nullptr, "for.tuple.loop");
	ir_emit_jump(proc, loop);
	ir_start_block(proc, loop);

	irBlock *body = ir_new_block(proc, nullptr, "for.tuple.body");
	irBlock *done = ir_new_block(proc, nullptr, "for.tuple.done");

	irValue *tuple_value = ir_build_expr(proc, expr);
	Type *tuple = ir_type(tuple_value);
	GB_ASSERT(tuple->kind == Type_Tuple);
	i32 tuple_count = cast(i32)tuple->Tuple.variables.count;
	i32 cond_index = tuple_count-1;

	irValue *cond = ir_emit_struct_ev(proc, tuple_value, cond_index);
	ir_emit_if(proc, cond, body, done);
	ir_start_block(proc, body);

	irValue *val0 = nullptr;


	if (val0_) *val0_ = ir_emit_struct_ev(proc, tuple_value, 0);
	if (val1_) *val1_ = ir_emit_struct_ev(proc, tuple_value, 1);
	if (loop_) *loop_ = loop;
	if (done_) *done_ = done;
}


void ir_store_type_case_implicit(irProcedure *proc, Ast *clause, irValue *value) {
	Entity *e = implicit_entity_of_node(clause);
	GB_ASSERT(e != nullptr);
#if 1
	irValue *x = ir_add_local(proc, e, nullptr, false);
	ir_emit_store(proc, x, value);
#else
	irValue *x = ir_address_from_load_or_generate_local(proc, value);
	ir_module_add_value(proc->module, e, x);
#endif
}

void ir_type_case_body(irProcedure *proc, Ast *label, Ast *clause, irBlock *body, irBlock *done) {
	ast_node(cc, CaseClause, clause);

	ir_push_target_list(proc, label, done, nullptr, nullptr);
	ir_open_scope(proc);
	ir_build_stmt_list(proc, cc->stmts);
	ir_close_scope(proc, irDeferExit_Default, body);
	ir_pop_target_list(proc);

	ir_emit_jump(proc, done);
}


void ir_build_stmt_internal(irProcedure *proc, Ast *node) {
	switch (node->kind) {
	case_ast_node(bs, EmptyStmt, node);
	case_end;

	case_ast_node(us, UsingStmt, node);
	case_end;

	case_ast_node(ws, WhenStmt, node);
		ir_build_when_stmt(proc, ws);
	case_end;

	case_ast_node(vd, ValueDecl, node);
		if (vd->is_mutable) {
			irModule *m = proc->module;

			bool is_static = false;
			if (vd->names.count > 0) {
				Entity *e = entity_of_ident(vd->names[0]);
				if (e->flags & EntityFlag_Static) {
					// NOTE(bill): If one of the entities is static, they all are
					is_static = true;
				}
			}

			if (is_static) {
				for_array(i, vd->names) {
					irValue *value = nullptr;
					if (vd->values.count > 0) {
						GB_ASSERT(vd->names.count == vd->values.count);
						Ast *ast_value = vd->values[i];
						GB_ASSERT(ast_value->tav.mode == Addressing_Constant ||
						          ast_value->tav.mode == Addressing_Invalid);

						value = ir_add_module_constant(m, ast_value->tav.type, ast_value->tav.value);
					}

					Ast *ident = vd->names[i];
					GB_ASSERT(!is_blank_ident(ident));
					Entity *e = entity_of_ident(ident);
					GB_ASSERT(e->flags & EntityFlag_Static);
					String name = e->token.string;

					String mangled_name = {};
					{
						gbString str = gb_string_make_length(heap_allocator(), proc->name.text, proc->name.len);
						str = gb_string_appendc(str, "-");
						str = gb_string_append_fmt(str, ".%.*s-%llu", LIT(name), cast(long long)e->id);
						mangled_name.text = cast(u8 *)str;
						mangled_name.len = gb_string_length(str);
					}

					HashKey key = hash_string(mangled_name);
					ir_add_entity_name(m, e, mangled_name);

					irValue *g = ir_value_global(e, value);
					g->Global.name = mangled_name;
					g->Global.is_private = true;
					if (e->Variable.thread_local_model != "") {
						g->Global.thread_local_model = e->Variable.thread_local_model;
					} else {
						g->Global.is_internal = true;
					}
					ir_module_add_value(proc->module, e, g);
					map_set(&proc->module->members, key, g);
				}
				return;
			}

			gbTempArenaMemory tmp = gb_temp_arena_memory_begin(&m->tmp_arena);
			defer (gb_temp_arena_memory_end(tmp));

			if (vd->values.count == 0) { // declared and zero-initialized
				for_array(i, vd->names) {
					Ast *name = vd->names[i];
					if (!is_blank_ident(name)) {
						ir_add_local_for_identifier(proc, name, true);
					}
				}
			} else { // Tuple(s)
				auto lvals = array_make<irAddr>(m->tmp_allocator, 0, vd->names.count);
				auto inits = array_make<irValue *>(m->tmp_allocator, 0, vd->names.count);

				for_array(i, vd->names) {
					Ast *name = vd->names[i];
					irAddr lval = ir_addr(nullptr);
					if (!is_blank_ident(name)) {
						ir_add_local_for_identifier(proc, name, false);
						lval = ir_build_addr(proc, name);
					}
					array_add(&lvals, lval);
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
			auto lvals = array_make<irAddr>(m->tmp_allocator, 0, as->lhs.count);

			for_array(i, as->lhs) {
				Ast *lhs = as->lhs[i];
				irAddr lval = {};
				if (!is_blank_ident(lhs)) {
					lval = ir_build_addr(proc, lhs);
				}
				array_add(&lvals, lval);
			}

			if (as->lhs.count == as->rhs.count) {
				if (as->lhs.count == 1) {
					Ast *rhs = as->rhs[0];
					irValue *init = ir_build_expr(proc, rhs);
					ir_addr_store(proc, lvals[0], init);
				} else {
					auto inits = array_make<irValue *>(m->tmp_allocator, 0, lvals.count);

					for_array(i, as->rhs) {
						irValue *init = ir_build_expr(proc, as->rhs[i]);
						array_add(&inits, init);
					}

					for_array(i, inits) {
						auto lval = lvals[i];
						ir_addr_store(proc, lval, inits[i]);
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
			if (op == Token_CmpAnd || op == Token_CmpOr) {
				Type *type = as->lhs[0]->tav.type;
				irValue *new_value = ir_emit_logical_binary_expr(proc, cast(TokenKind)op, as->lhs[0], as->rhs[0], type);

				irAddr lhs = ir_build_addr(proc, as->lhs[0]);
				ir_addr_store(proc, lhs, new_value);
			} else {
				irAddr lhs = ir_build_addr(proc, as->lhs[0]);
				irValue *value = ir_build_expr(proc, as->rhs[0]);
				ir_build_assign_op(proc, lhs, value, cast(TokenKind)op);
			}
			return;
		}
		}
	case_end;

	case_ast_node(es, ExprStmt, node);
		// NOTE(bill): No need to use return value
		ir_build_expr(proc, es->expr);
	case_end;

	case_ast_node(bs, BlockStmt, node);
		if (bs->label != nullptr) {
			irBlock *done = ir_new_block(proc, node, "block.done");
			irTargetList *tl = ir_push_target_list(proc, bs->label, done, nullptr, nullptr);
			tl->is_block = true;

			ir_open_scope(proc);
			ir_build_stmt_list(proc, bs->stmts);
			ir_close_scope(proc, irDeferExit_Default, nullptr);

			ir_emit_jump(proc, done);
			ir_start_block(proc, done);

		} else {
			ir_open_scope(proc);
			ir_build_stmt_list(proc, bs->stmts);
			ir_close_scope(proc, irDeferExit_Default, nullptr);
		}
	case_end;

	case_ast_node(ds, DeferStmt, node);
		ir_emit_comment(proc, str_lit("DeferStmt"));
		isize scope_index = proc->scope_index;
		// TODO(bill): What was the original rationale behind this line?
		// if (ds->stmt->kind == Ast_BlockStmt) scope_index--;
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
			// NOTE(bill): Doesn't need to be zero because it will be initialized in the loops
			v = ir_add_local_generated(proc, ret_type, false);
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
		ir_open_scope(proc); // Scope #1

		if (is->init != nullptr) {
			// TODO(bill): Should this have a separate block to begin with?
		#if 1
			irBlock *init = ir_new_block(proc, node, "if.init");
			ir_emit_jump(proc, init);
			ir_start_block(proc, init);
		#endif
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

		if (is->label != nullptr) {
			irTargetList *tl = ir_push_target_list(proc, is->label, done, nullptr, nullptr);
			tl->is_block = true;
		}

		// ir_open_scope(proc);
		ir_build_stmt(proc, is->body);
		// ir_close_scope(proc, irDeferExit_Default, nullptr);

		ir_emit_jump(proc, done);

		if (is->else_stmt != nullptr) {
			ir_start_block(proc, else_);

			ir_open_scope(proc);
			ir_build_stmt(proc, is->else_stmt);
			ir_close_scope(proc, irDeferExit_Default, nullptr);

			ir_emit_jump(proc, done);
		}


		ir_start_block(proc, done);
		ir_close_scope(proc, irDeferExit_Default, nullptr);

	case_end;

	case_ast_node(fs, ForStmt, node);
		ir_emit_comment(proc, str_lit("ForStmt"));
		ir_open_scope(proc); // Open Scope here

		if (fs->init != nullptr) {
		#if 1
			irBlock *init = ir_new_block(proc, node, "for.init");
			ir_emit_jump(proc, init);
			ir_start_block(proc, init);
		#endif
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
		ir_open_scope(proc); // Open scope here

		Type *val0_type = nullptr;
		Type *val1_type = nullptr;
		if (rs->val0 != nullptr && !is_blank_ident(rs->val0)) {
			val0_type = type_of_expr(rs->val0);
		}
		if (rs->val1 != nullptr && !is_blank_ident(rs->val1)) {
			val1_type = type_of_expr(rs->val1);
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
		Ast *expr = unparen_expr(rs->expr);
		bool is_map = false;

		TypeAndValue tav = type_and_value_of_expr(expr);

		if (is_ast_range(expr)) {
			ir_build_range_interval(proc, &expr->BinaryExpr, val0_type, &val, &key, &loop, &done);
		} else if (tav.mode == Addressing_Type) {
			ir_build_range_enum(proc, type_deref(tav.type), val0_type, &val, &key, &loop, &done);
		} else {
			Type *expr_type = type_of_expr(expr);
			Type *et = base_type(type_deref(expr_type));
			switch (et->kind) {
			case Type_Map: {
				is_map = true;
				gbAllocator a = ir_allocator();
				irAddr addr = ir_build_addr(proc, expr);
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
				irValue *array = ir_build_addr_ptr(proc, expr);
				if (is_type_pointer(type_deref(ir_type(array)))) {
					array = ir_emit_load(proc, array);
				}
				count_ptr = ir_add_local_generated(proc, t_int, false);
				ir_emit_store(proc, count_ptr, ir_const_int(et->Array.count));
				ir_build_range_indexed(proc, array, val0_type, count_ptr, &val, &key, &loop, &done);
				break;
			}
			case Type_EnumeratedArray: {
				irValue *count_ptr = nullptr;
				irValue *array = ir_build_addr_ptr(proc, expr);
				if (is_type_pointer(type_deref(ir_type(array)))) {
					array = ir_emit_load(proc, array);
				}
				count_ptr = ir_add_local_generated(proc, t_int, false);
				ir_emit_store(proc, count_ptr, ir_const_int(et->EnumeratedArray.count));
				ir_build_range_indexed(proc, array, val0_type, count_ptr, &val, &key, &loop, &done);
				break;
			}
			case Type_DynamicArray: {
				irValue *count_ptr = nullptr;
				irValue *array = ir_build_addr_ptr(proc, expr);
				if (is_type_pointer(type_deref(ir_type(array)))) {
					array = ir_emit_load(proc, array);
				}
				count_ptr = ir_emit_struct_ep(proc, array, 1);
				ir_build_range_indexed(proc, array, val0_type, count_ptr, &val, &key, &loop, &done);
				break;
			}
			case Type_Slice: {
				irValue *count_ptr = nullptr;
				irValue *slice = ir_build_expr(proc, expr);
				if (is_type_pointer(ir_type(slice))) {
					count_ptr = ir_emit_struct_ep(proc, slice, 1);
					slice = ir_emit_load(proc, slice);
				} else {
					count_ptr = ir_add_local_generated(proc, t_int, false);
					ir_emit_store(proc, count_ptr, ir_slice_len(proc, slice));
				}
				ir_build_range_indexed(proc, slice, val0_type, count_ptr, &val, &key, &loop, &done);
				break;
			}
			case Type_Basic: {
				irValue *string = ir_build_expr(proc, expr);
				if (is_type_pointer(ir_type(string))) {
					string = ir_emit_load(proc, string);
				}
				if (is_type_untyped(expr_type)) {
					irValue *s = ir_add_local_generated(proc, default_type(ir_type(string)), false);
					ir_emit_store(proc, s, string);
					string = ir_emit_load(proc, s);
				}
				Type *t = base_type(ir_type(string));
				GB_ASSERT(!is_type_cstring(t));
				ir_build_range_string(proc, string, val0_type, &val, &key, &loop, &done);
				break;
			}
			case Type_Tuple:
				ir_build_range_tuple(proc, expr, val0_type, val1_type, &val, &key, &loop, &done);
				break;
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

		ir_build_stmt(proc, rs->body);
		ir_close_scope(proc, irDeferExit_Default, nullptr);

		ir_pop_target_list(proc);
		ir_emit_jump(proc, loop);
		ir_start_block(proc, done);
	case_end;

	case_ast_node(rs, InlineRangeStmt, node);
		ir_emit_comment(proc, str_lit("InlineRangeStmt"));
		ir_open_scope(proc); // Open scope here

		Type *val0_type = nullptr;
		Type *val1_type = nullptr;
		if (rs->val0 != nullptr && !is_blank_ident(rs->val0)) {
			val0_type = type_of_expr(rs->val0);
		}
		if (rs->val1 != nullptr && !is_blank_ident(rs->val1)) {
			val1_type = type_of_expr(rs->val1);
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
		Ast *expr = unparen_expr(rs->expr);

		TypeAndValue tav = type_and_value_of_expr(expr);

		if (is_ast_range(expr)) {

			irAddr val0_addr = {};
			irAddr val1_addr = {};
			if (val0_type) val0_addr = ir_build_addr(proc, rs->val0);
			if (val1_type) val1_addr = ir_build_addr(proc, rs->val1);

			TokenKind op = expr->BinaryExpr.op.kind;
			Ast *start_expr = expr->BinaryExpr.left;
			Ast *end_expr   = expr->BinaryExpr.right;
			GB_ASSERT(start_expr->tav.mode == Addressing_Constant);
			GB_ASSERT(end_expr->tav.mode == Addressing_Constant);

			ExactValue start = start_expr->tav.value;
			ExactValue end   = end_expr->tav.value;
			if (op == Token_Ellipsis) { // .. [start, end]
				ExactValue index = exact_value_i64(0);
				for (ExactValue val = start;
				     compare_exact_values(Token_LtEq, val, end);
				     val = exact_value_increment_one(val), index = exact_value_increment_one(index)) {

					if (val0_type) ir_addr_store(proc, val0_addr, ir_value_constant(val0_type, val));
					if (val1_type) ir_addr_store(proc, val1_addr, ir_value_constant(val1_type, index));

					ir_build_stmt(proc, rs->body);
				}
			} else if (op == Token_RangeHalf) { // ..< [start, end)
				ExactValue index = exact_value_i64(0);
				for (ExactValue val = start;
				     compare_exact_values(Token_Lt, val, end);
				     val = exact_value_increment_one(val), index = exact_value_increment_one(index)) {

					if (val0_type) ir_addr_store(proc, val0_addr, ir_value_constant(val0_type, val));
					if (val1_type) ir_addr_store(proc, val1_addr, ir_value_constant(val1_type, index));

					ir_build_stmt(proc, rs->body);
				}
			}


		} else if (tav.mode == Addressing_Type) {
			GB_ASSERT(is_type_enum(type_deref(tav.type)));
			Type *et = type_deref(tav.type);
			Type *bet = base_type(et);

			irAddr val0_addr = {};
			irAddr val1_addr = {};
			if (val0_type) val0_addr = ir_build_addr(proc, rs->val0);
			if (val1_type) val1_addr = ir_build_addr(proc, rs->val1);

			for_array(i, bet->Enum.fields) {
				Entity *field = bet->Enum.fields[i];
				GB_ASSERT(field->kind == Entity_Constant);
				if (val0_type) ir_addr_store(proc, val0_addr, ir_value_constant(val0_type, field->Constant.value));
				if (val1_type) ir_addr_store(proc, val1_addr, ir_value_constant(val1_type, exact_value_i64(i)));

				ir_build_stmt(proc, rs->body);
			}
		} else {
			irAddr val0_addr = {};
			irAddr val1_addr = {};
			if (val0_type) val0_addr = ir_build_addr(proc, rs->val0);
			if (val1_type) val1_addr = ir_build_addr(proc, rs->val1);

			GB_ASSERT(expr->tav.mode == Addressing_Constant);

			Type *t = base_type(expr->tav.type);


			switch (t->kind) {
			case Type_Basic:
				GB_ASSERT(is_type_string(t));
				{
					ExactValue value = expr->tav.value;
					GB_ASSERT(value.kind == ExactValue_String);
					String str = value.value_string;
					Rune codepoint = 0;
					isize offset = 0;
					do {
						isize width = gb_utf8_decode(str.text+offset, str.len-offset, &codepoint);
						if (val0_type) ir_addr_store(proc, val0_addr, ir_value_constant(val0_type, exact_value_i64(codepoint)));
						if (val1_type) ir_addr_store(proc, val1_addr, ir_value_constant(val1_type, exact_value_i64(offset)));
						ir_build_stmt(proc, rs->body);

						offset += width;
					} while (offset < str.len);
				}
				break;
			case Type_Array:
				if (t->Array.count > 0) {
					irValue *val = ir_build_expr(proc, expr);
					irValue *val_addr = ir_address_from_load_or_generate_local(proc, val);

					for (i64 i = 0; i < t->Array.count; i++) {
						if (val0_type) {
							// NOTE(bill): Due to weird legacy issues in LLVM, this needs to be an i32
							irValue *elem = ir_emit_array_epi(proc, val_addr, cast(i32)i);
							ir_addr_store(proc, val0_addr, ir_emit_load(proc, elem));
						}
						if (val1_type) ir_addr_store(proc, val1_addr, ir_value_constant(val1_type, exact_value_i64(i)));

						ir_build_stmt(proc, rs->body);
					}

				}
				break;
			case Type_EnumeratedArray:
				if (t->EnumeratedArray.count > 0) {
					irValue *val = ir_build_expr(proc, expr);
					irValue *val_addr = ir_address_from_load_or_generate_local(proc, val);

					for (i64 i = 0; i < t->EnumeratedArray.count; i++) {
						if (val0_type) {
							// NOTE(bill): Due to weird legacy issues in LLVM, this needs to be an i32
							irValue *elem = ir_emit_array_epi(proc, val_addr, cast(i32)i);
							ir_addr_store(proc, val0_addr, ir_emit_load(proc, elem));
						}
						if (val1_type) {
							ExactValue idx = exact_value_add(exact_value_i64(i), t->EnumeratedArray.min_value);
							ir_addr_store(proc, val1_addr, ir_value_constant(val1_type, idx));
						}

						ir_build_stmt(proc, rs->body);
					}

				}
				break;
			default:
				GB_PANIC("Invalid inline for type");
				break;
			}
		}


		ir_close_scope(proc, irDeferExit_Default, nullptr);
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

		Array<Ast *> default_stmts = {};
		irBlock *default_fall = nullptr;
		irBlock *default_block = nullptr;

		irBlock *fall = nullptr;
		bool append_fall = false;

		isize case_count = body->stmts.count;
		for_array(i, body->stmts) {
			Ast *clause = body->stmts[i];
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
				Ast *expr = unparen_expr(cc->list[j]);
				next_cond = ir_new_block(proc, clause, "switch.case.next");
				irValue *cond = v_false;
				if (is_ast_range(expr)) {
					ast_node(ie, BinaryExpr, expr);
					TokenKind op = Token_Invalid;
					switch (ie->op.kind) {
					case Token_Ellipsis:  op = Token_LtEq; break;
					case Token_RangeHalf: op = Token_Lt;   break;
					default: GB_PANIC("Invalid interval operator"); break;
					}
					irValue *lhs = ir_build_expr(proc, ie->left);
					irValue *rhs = ir_build_expr(proc, ie->right);
					// TODO(bill): do short circuit here
					irValue *cond_lhs = ir_emit_comp(proc, Token_LtEq, lhs, tag);
					irValue *cond_rhs = ir_emit_comp(proc, op, tag, rhs);
					cond = ir_emit_arith(proc, Token_And, cond_lhs, cond_rhs, t_bool);
				} else {
					if (expr->tav.mode == Addressing_Type) {
						GB_ASSERT(is_type_typeid(ir_type(tag)));
						irValue *e = ir_typeid(proc->module, expr->tav.type);
						e = ir_emit_conv(proc, e, ir_type(tag));
						cond = ir_emit_comp(proc, Token_CmpEq, tag, e);
					} else {
						cond = ir_emit_comp(proc, Token_CmpEq, tag, ir_build_expr(proc, expr));
					}
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
		gbAllocator allocator = ir_allocator();

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
		Ast *default_ = nullptr;

		ast_node(body, BlockStmt, ss->body);

		gb_local_persist i32 weird_count = 0;

		for_array(i, body->stmts) {
			Ast *clause = body->stmts[i];
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
				case_type = type_of_expr(cc->list[type_index]);
				irValue *cond = nullptr;
				if (switch_kind == TypeSwitch_Union) {
					Type *ut = base_type(type_deref(parent_type));
					irValue *variant_tag = ir_const_union_tag(ut, case_type);
					cond = ir_emit_comp(proc, Token_CmpEq, tag_index, variant_tag);
				} else if (switch_kind == TypeSwitch_Any) {
					irValue *any_typeid  = ir_emit_load(proc, ir_emit_struct_ep(proc, parent_ptr, 1));
					irValue *case_typeid = ir_typeid(proc->module, case_type);
					cond = ir_emit_comp(proc, Token_CmpEq, any_typeid, case_typeid);
				}
				GB_ASSERT(cond != nullptr);

				ir_emit_if(proc, cond, body, next);
				ir_start_block(proc, next);
			}

			Entity *case_entity = implicit_entity_of_node(clause);

			irValue *value = parent_value;

			ir_start_block(proc, body);

			// bool any_or_not_ptr = is_type_any(type_deref(parent_type)) || !is_parent_ptr;
			bool any_or_not_ptr = !is_parent_ptr;
			if (cc->list.count == 1) {

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
				if (t->is_block) {
					continue;
				}

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
	}
}







////////////////////////////////////////////////////////////////
//
// @Procedure
//
////////////////////////////////////////////////////////////////

void ir_number_proc_registers(irProcedure *proc) {
	// i32 reg_index = proc->parameter_count;
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
	gbAllocator a = ir_allocator();
	array_add(&proc->module->procs, proc);

	array_init(&proc->blocks,           heap_allocator());
	array_init(&proc->defer_stmts,      heap_allocator());
	array_init(&proc->children,         heap_allocator());
	array_init(&proc->branch_blocks,    heap_allocator());
	array_init(&proc->context_stack,    heap_allocator());

	DeclInfo *decl = decl_info_of_entity(proc->entity);
	if (decl != nullptr) {
		for_array(i, decl->labels) {
			BlockLabel bl = decl->labels[i];
			irBranchBlocks bb = {bl.label, nullptr, nullptr};
			array_add(&proc->branch_blocks, bb);
		}
	}

	// NOTE(lachsinc): This is somewhat of a fallback/catch-all; We use the procedure's identifer as a debug location..
	// Additional debug locations should be pushed for the procedures statements/expressions themselves.
	if (proc->module->generate_debug_info && proc->entity && proc->entity->identifier) { // TODO(lachsinc): Better way to determine if these procs are main/runtime_startup.
		// TODO(lachsinc): Passing the file for the scope may not be correct for nested procedures? This should probably be
		// handled all inside push_debug_location, with just the Ast * we can pull out everything we need to construct scope/file debug info etc.
		ir_add_debug_info_proc(proc);
		ir_push_debug_location(proc->module, proc->entity->identifier, proc->debug_scope);
		GB_ASSERT_NOT_NULL(proc->debug_scope);
	} else {
		ir_push_debug_location(proc->module, nullptr, nullptr);
	}

	proc->decl_block  = ir_new_block(proc, proc->type_expr, "decls");
	ir_start_block(proc, proc->decl_block);
	proc->entry_block = ir_new_block(proc, proc->type_expr, "entry");
	ir_start_block(proc, proc->entry_block);

	i32 parameter_index = 0;

	if (proc->type->Proc.return_by_pointer) {
		// NOTE(bill): this must be the first parameter stored
		Type *ptr_type = alloc_type_pointer(reduce_tuple_to_single_type(proc->type->Proc.results));
		Entity *e = alloc_entity_param(nullptr, make_token_ident(str_lit("agg.result")), ptr_type, false, false);
		e->flags |= EntityFlag_Sret | EntityFlag_NoAlias;

		irValue *param = ir_value_param(proc, e, ptr_type, -1);
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
				GB_ASSERT(fl->list[0]->kind == Ast_Field);
				if (q_index == fl->list[param_index]->Field.names.count) {
					q_index = 0;
					param_index++;
				}
				ast_node(field, Field, fl->list[param_index]);
				Ast *name = field->names[q_index++];

				Entity *e = params->variables[i];
				if (e->kind != Entity_Variable) {
					parameter_index += 1;
					continue;
				}

				Type *abi_type = proc->type->Proc.abi_compat_params[i];
				if (e->token.string != "") {
					ir_add_param(proc, e, name, abi_type, parameter_index);
				}

				if (is_type_tuple(abi_type)) {
					parameter_index += cast(i32)abi_type->Tuple.variables.count;
				} else {
					parameter_index += 1;
				}
			}
		} else {
			auto abi_types = proc->type->Proc.abi_compat_params;

			for_array(i, params->variables) {
				Entity *e = params->variables[i];
				if (e->kind != Entity_Variable) {
					parameter_index += 1;
					continue;
				}
				Type *abi_type = e->type;
				if (abi_types.count > 0) {
					abi_type = abi_types[i];
				}
				if (e->token.string != "") {
					ir_add_param(proc, e, nullptr, abi_type, parameter_index);
				}
				if (is_type_tuple(abi_type)) {
					parameter_index += cast(i32)abi_type->Tuple.variables.count;
				} else {
					parameter_index += 1;
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

				irValue *c = nullptr;
				switch (e->Variable.param_value.kind) {
				case ParameterValue_Constant:
					c = ir_value_constant(e->type, e->Variable.param_value.value);
					break;
				case ParameterValue_Nil:
					c = ir_value_nil(e->type);
					break;
				case ParameterValue_Location:
					GB_PANIC("ParameterValue_Location");
					break;
				}
				if (c != nullptr) {
					ir_emit_store(proc, res, c);
				}
			}
		}
	}


	if (proc->type->Proc.calling_convention == ProcCC_Odin) {
		Entity *e = alloc_entity_param(nullptr, make_token_ident(str_lit("__.context_ptr")), t_context_ptr, false, false);
		e->flags |= EntityFlag_NoAlias;
		irValue *param = ir_value_param(proc, e, e->type, -1);
		ir_module_add_value(proc->module, e, param);
		irContextData ctx = {param, proc->scope_index};
		array_add(&proc->context_stack, ctx);
	}

	proc->parameter_count = parameter_index;
}


bool ir_remove_dead_instr(irProcedure *proc) {
	isize elimination_count = 0;
retry:
#if 1
	for_array(i, proc->blocks) {
		irBlock *b = proc->blocks[i];
		b->index = cast(i32)i;
		for (isize j = 0; j < b->instrs.count; /**/) {
			irValue *value = b->instrs[j];
			GB_ASSERT_MSG(value->kind == irValue_Instr, "%.*s", LIT(proc->name));
			irInstr *instr = &value->Instr;
			if (value->uses == 0) {
				switch (instr->kind) {
				case irInstr_Load:
					instr->Load.address->uses -= 1;
					array_ordered_remove(&b->instrs, j);
					elimination_count += 1;
					continue;
				case irInstr_Local:
					array_ordered_remove(&b->instrs, j);
					elimination_count += 1;
					continue;
				case irInstr_AtomicLoad:
					instr->AtomicLoad.address->uses -= 1;
					array_ordered_remove(&b->instrs, j);
					elimination_count += 1;
					continue;
				case irInstr_PtrOffset:
					instr->PtrOffset.address->uses -= 1;
					instr->PtrOffset.offset->uses -= 1;
					array_ordered_remove(&b->instrs, j);
					elimination_count += 1;
					continue;
				case irInstr_ArrayElementPtr:
					instr->ArrayElementPtr.address->uses -= 1;
					instr->ArrayElementPtr.elem_index->uses -= 1;
					array_ordered_remove(&b->instrs, j);
					elimination_count += 1;
					continue;
				case irInstr_StructElementPtr:
					instr->StructElementPtr.address->uses -= 1;
					array_ordered_remove(&b->instrs, j);
					elimination_count += 1;
					continue;
				case irInstr_StructExtractValue:
					instr->StructExtractValue.address->uses -= 1;
					array_ordered_remove(&b->instrs, j);
					elimination_count += 1;
					continue;
				case irInstr_UnionTagPtr:
					instr->UnionTagPtr.address->uses -= 1;
					array_ordered_remove(&b->instrs, j);
					elimination_count += 1;
					continue;
				case irInstr_UnionTagValue:
					instr->UnionTagValue.address->uses -= 1;
					array_ordered_remove(&b->instrs, j);
					elimination_count += 1;
					continue;
				// case irInstr_Conv:
				// 	// instr->Conv.value->uses -= 1;
				// 	array_ordered_remove(&b->instrs, j);
				// 	elimination_count += 1;
				// 	continue;
				// case irInstr_UnaryOp:
				// 	// instr->UnaryOp.expr->uses -= 1;
				// 	array_ordered_remove(&b->instrs, j);
				// 	elimination_count += 1;
				// 	continue;
				// case irInstr_BinaryOp:
				// 	// instr->BinaryOp.left->uses -= 1;
				// 	// instr->BinaryOp.right->uses -= 1;
				// 	array_ordered_remove(&b->instrs, j);
				// 	elimination_count += 1;
				// 	continue;
				}
			}
			j += 1;
		}
	}
#endif
	if (elimination_count > 0) {
		// gb_printf_err("Retry ir_remove_dead_instr, count: %td; %.*s\n", elimination_count, LIT(proc->name));
		elimination_count = 0;
		goto retry;
	}
	return elimination_count > 0;
}

void ir_end_procedure_body(irProcedure *proc) {
	if (proc->type->Proc.result_count == 0) {
		ir_emit_return(proc, nullptr);
	}

	if (proc->curr_block->instrs.count == 0) {
		ir_emit_unreachable(proc);
	}

	GB_ASSERT(proc->scope_index == 0);

	proc->curr_block = proc->decl_block;
	ir_emit_jump(proc, proc->entry_block);
	proc->curr_block = nullptr;

	ir_remove_dead_instr(proc);

	ir_number_proc_registers(proc);

	ir_pop_debug_location(proc->module);
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

	set_procedure_abi_types(heap_allocator(), proc->type);

	proc->parent = parent;

	if (proc->body != nullptr) {
		u64 prev_state_flags = proc->module->state_flags;

		if (proc->tags != 0) {
			u64 in = proc->tags;
			u64 out = proc->module->state_flags;
			if (in & ProcTag_bounds_check) {
				out |= StateFlag_bounds_check;
				out &= ~StateFlag_no_bounds_check;
			} else if (in & ProcTag_no_bounds_check) {
				out |= StateFlag_no_bounds_check;
				out &= ~StateFlag_bounds_check;
			}
			proc->module->state_flags = out;
		}

		ir_begin_procedure_body(proc);
		ir_insert_code_before_proc(proc, parent);
		ir_build_stmt(proc, proc->body);
		ir_end_procedure_body(proc);

		proc->module->state_flags = prev_state_flags;
	}

	// NOTE(lachsinc): For now we pop the debug location inside ir_end_procedure_body().
	// This may result in debug info being missing for below.

	if (proc->type->Proc.has_proc_default_values) {
		auto *p = &proc->type->Proc;
		if (p->params != nullptr) for_array(i, p->params->Tuple.variables) {
			Entity *f = p->params->Tuple.variables[i];
			if (f->kind == Entity_Variable) {
				ParameterValue pv = f->Variable.param_value;
				if (pv.kind ==  ParameterValue_Constant && pv.value.kind == ExactValue_Procedure) {
					Ast *expr = f->Variable.param_value.value.value_procedure;
					GB_ASSERT(expr != nullptr);
					if (expr->kind == Ast_ProcLit) {
						ir_gen_anonymous_proc_lit(proc->module, proc->name, expr, proc);
					}
				}
			}
		}
		if (p->results != nullptr) for_array(i, p->results->Tuple.variables) {
			Entity *f = p->results->Tuple.variables[i];
			if (f->kind == Entity_Variable) {
				ParameterValue pv = f->Variable.param_value;
				if (pv.kind ==  ParameterValue_Constant && pv.value.kind == ExactValue_Procedure) {
					Ast *expr = f->Variable.param_value.value.value_procedure;
					GB_ASSERT(expr != nullptr);
					if (expr->kind == Ast_ProcLit) {
						ir_gen_anonymous_proc_lit(proc->module, proc->name, expr, proc);
					}
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
	// TODO(lachsinc): This may not be the most sensible place to do this!
	// it may be more sensible to look for more specific locations that call ir_value_global and assign it a value? maybe?
	// ir_value_global itself doesn't have access to module though.
	if (v->kind == irValue_Global && v->Global.value != nullptr && e->state == EntityState_Resolved) {
		ir_add_debug_info_global(m, v);
	}
}

void ir_init_module(irModule *m, Checker *c) {
	// TODO(bill): Determine a decent size for the arena
	isize token_count = c->parser->total_token_count;
	isize arena_size = 4 * token_count * gb_size_of(irValue);
	gb_arena_init_from_allocator(&m->tmp_arena, heap_allocator(), arena_size);
	ir_allocator() = ir_allocator();
	m->tmp_allocator = gb_arena_allocator(&m->tmp_arena);
	m->info = &c->info;

	m->generate_debug_info = false;
	if (build_context.ODIN_DEBUG) {
		m->generate_debug_info = build_context.ODIN_OS == "windows" && build_context.word_size == 8;
	}

	map_init(&m->values,                   heap_allocator());
	map_init(&m->members,                  heap_allocator());
	map_init(&m->debug_info,               heap_allocator());
	map_init(&m->entity_names,             heap_allocator());
	map_init(&m->anonymous_proc_lits,      heap_allocator());
	array_init(&m->procs,                  heap_allocator());
	array_init(&m->procs_to_generate,      heap_allocator());
	array_init(&m->foreign_library_paths,  heap_allocator());
	map_init(&m->const_strings,            heap_allocator());
	map_init(&m->const_string_byte_slices, heap_allocator());
	map_init(&m->constant_value_to_global, heap_allocator());

	// Default states
	m->state_flags = 0;
	m->state_flags |= StateFlag_bounds_check;

	{
		// Add type info data
		{
			isize max_type_info_count = ir_type_info_count(m->info);

			String name = str_lit(IR_TYPE_INFO_DATA_NAME);
			Entity *e = alloc_entity_variable(nullptr, make_token_ident(name), alloc_type_array(t_type_info, max_type_info_count));
			irValue *g = ir_value_global(e, nullptr);
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

				isize index = ir_type_info_index(m->info, t, false);
				if (index < 0) {
					continue;
				}

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

			if (count > 0) {
				{
					String name = str_lit(IR_TYPE_INFO_TYPES_NAME);
					Entity *e = alloc_entity_variable(nullptr, make_token_ident(name),
					                                  alloc_type_array(t_type_info_ptr, count));
					irValue *g = ir_value_global(e, nullptr);
					ir_module_add_value(m, e, g);
					map_set(&m->members, hash_string(name), g);
					ir_global_type_info_member_types = g;
				}
				{
					String name = str_lit(IR_TYPE_INFO_NAMES_NAME);
					Entity *e = alloc_entity_variable(nullptr, make_token_ident(name),
					                                  alloc_type_array(t_string, count));
					irValue *g = ir_value_global(e, nullptr);
					ir_module_add_value(m, e, g);
					map_set(&m->members, hash_string(name), g);
					ir_global_type_info_member_names = g;
				}
				{
					String name = str_lit(IR_TYPE_INFO_OFFSETS_NAME);
					Entity *e = alloc_entity_variable(nullptr, make_token_ident(name),
					                                  alloc_type_array(t_uintptr, count));
					irValue *g = ir_value_global(e, nullptr);
					ir_module_add_value(m, e, g);
					map_set(&m->members, hash_string(name), g);
					ir_global_type_info_member_offsets = g;
				}

				{
					String name = str_lit(IR_TYPE_INFO_USINGS_NAME);
					Entity *e = alloc_entity_variable(nullptr, make_token_ident(name),
					                                  alloc_type_array(t_bool, count));
					irValue *g = ir_value_global(e, nullptr);
					ir_module_add_value(m, e, g);
					map_set(&m->members, hash_string(name), g);
					ir_global_type_info_member_usings = g;
				}

				{
					String name = str_lit(IR_TYPE_INFO_TAGS_NAME);
					Entity *e = alloc_entity_variable(nullptr, make_token_ident(name),
					                                  alloc_type_array(t_string, count));
					irValue *g = ir_value_global(e, nullptr);
					ir_module_add_value(m, e, g);
					map_set(&m->members, hash_string(name), g);
					ir_global_type_info_member_tags = g;
				}
			}
		}
	}

	{
		irDebugInfo *di = ir_alloc_debug_info(irDebugInfo_CompileUnit);

		GB_ASSERT(m->info->files.entries.count > 0);
		AstFile *file = m->info->files.entries[0].value;

		di->CompileUnit.file = file; // Zeroth is the init file
		di->CompileUnit.producer = str_lit("odin");

		map_set(&m->debug_info, hash_pointer(m), di);

		m->debug_compile_unit = di;

		irDebugInfo *enums_di = ir_alloc_debug_info(irDebugInfo_DebugInfoArray);
		array_init(&enums_di->DebugInfoArray.elements, heap_allocator()); // TODO(lachsinc): ir_allocator() ??
		map_set(&m->debug_info, hash_pointer(enums_di), enums_di);
		m->debug_compile_unit->CompileUnit.enums = enums_di;

		irDebugInfo *globals_di = ir_alloc_debug_info(irDebugInfo_DebugInfoArray);
		array_init(&globals_di->DebugInfoArray.elements, heap_allocator()); // TODO(lachsinc): ir_allocator() ??
		map_set(&m->debug_info, hash_pointer(globals_di), globals_di);
		m->debug_compile_unit->CompileUnit.globals = globals_di;

		array_init(&m->debug_location_stack, heap_allocator()); // TODO(lachsinc): ir_allocator() ??
	}

	{
		for_array(i, m->info->files.entries) {
			AstFile *file = m->info->files.entries[i].value;
			ir_add_debug_info_file(m, file);
		}
	}
}

void ir_destroy_module(irModule *m) {
	map_destroy(&m->values);
	map_destroy(&m->members);
	map_destroy(&m->entity_names);
	map_destroy(&m->anonymous_proc_lits);
	map_destroy(&m->debug_info);
	map_destroy(&m->const_strings);
	map_destroy(&m->const_string_byte_slices);
	map_destroy(&m->constant_value_to_global);
	array_free(&m->procs);
	array_free(&m->procs_to_generate);
	array_free(&m->foreign_library_paths);
	array_free(&m->debug_location_stack);
	gb_arena_free(&m->tmp_arena);
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

	arena_init(&global_ir_arena, heap_allocator());

	ir_init_module(&s->module, c);
	// s->module.generate_debug_info = false;

	String init_fullpath = c->parser->init_fullpath;

	if (build_context.out_filepath.len == 0) {
		s->output_name = remove_directory_from_path(init_fullpath);
		s->output_name = remove_extension_from_path(s->output_name);
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
	i32 index = cast(i32)ir_type_info_index(proc->module->info, type);
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
irValue *ir_type_info_member_tags_offset(irProcedure *proc, isize count) {
	irValue *offset = ir_emit_array_epi(proc, ir_global_type_info_member_tags, ir_global_type_info_member_tags_index);
	ir_global_type_info_member_tags_index += cast(i32)count;
	return offset;
}






void ir_setup_type_info_data(irProcedure *proc) { // NOTE(bill): Setup type_info data
	irModule *m = proc->module;
	gbAllocator a = ir_allocator();
	CheckerInfo *info = m->info;

	if (true) {
		irValue *global_type_table = ir_find_global_variable(proc, str_lit("type_table"));
		Type *type = base_type(type_deref(ir_type(ir_global_type_info_data)));
		GB_ASSERT(is_type_array(type));
		irValue *len = ir_const_int(type->Array.count);
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

		isize entry_index = ir_type_info_index(info, t, false);
		if (entry_index <= 0) {
			continue;
		}

		irValue *tag = nullptr;
		irValue *ti_ptr = ir_emit_array_epi(proc, ir_global_type_info_data, cast(i32)entry_index);
		irValue *variant_ptr = ir_emit_struct_ep(proc, ti_ptr, 3);

		ir_emit_store(proc, ir_emit_struct_ep(proc, ti_ptr, 0), ir_const_int(type_size_of(t)));
		ir_emit_store(proc, ir_emit_struct_ep(proc, ti_ptr, 1), ir_const_int(type_align_of(t)));
		ir_emit_store(proc, ir_emit_struct_ep(proc, ti_ptr, 2), ir_typeid(proc->module, t));


		switch (t->kind) {
		case Type_Named: {
			ir_emit_comment(proc, str_lit("Type_Info_Named"));
			tag = ir_emit_conv(proc, variant_ptr, t_type_info_named_ptr);

			// TODO(bill): Which is better? The mangled name or actual name?
			irValue *name = ir_const_string(proc->module, t->Named.type_name->token.string);
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
			case Basic_i128:
			case Basic_u128:

			case Basic_i16le:
			case Basic_u16le:
			case Basic_i32le:
			case Basic_u32le:
			case Basic_i64le:
			case Basic_u64le:
			case Basic_i128le:
			case Basic_u128le:
			case Basic_i16be:
			case Basic_u16be:
			case Basic_i32be:
			case Basic_u32be:
			case Basic_i64be:
			case Basic_u64be:
			case Basic_i128be:
			case Basic_u128be:

			case Basic_int:
			case Basic_uint:
			case Basic_uintptr: {
				tag = ir_emit_conv(proc, variant_ptr, t_type_info_integer_ptr);
				irValue *is_signed = ir_const_bool((t->Basic.flags & BasicFlag_Unsigned) == 0);
				ir_emit_store(proc, ir_emit_struct_ep(proc, tag, 0), is_signed);
				// NOTE(bill): This is matches the runtime layout
				u8 endianness_value = 0;
				if (t->Basic.flags & BasicFlag_EndianLittle) {
					endianness_value = 1;
				} else if (t->Basic.flags & BasicFlag_EndianBig) {
					endianness_value = 2;
				}
				irValue *endianness = ir_const_u8(endianness_value);
				ir_emit_store(proc, ir_emit_struct_ep(proc, tag, 1), endianness);
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

			case Basic_quaternion128:
			case Basic_quaternion256:
				tag = ir_emit_conv(proc, variant_ptr, t_type_info_quaternion_ptr);
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

			case Basic_typeid:
				tag = ir_emit_conv(proc, variant_ptr, t_type_info_typeid_ptr);
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

			i64 ez = type_size_of(t->Array.elem);
			irValue *elem_size = ir_emit_struct_ep(proc, tag, 1);
			ir_emit_store(proc, elem_size, ir_const_int(ez));

			irValue *count = ir_emit_struct_ep(proc, tag, 2);
			ir_emit_store(proc, count, ir_const_int(t->Array.count));

			break;
		}
		case Type_EnumeratedArray: {
			ir_emit_comment(proc, str_lit("Type_Info_Enumerated_Array"));
			tag = ir_emit_conv(proc, variant_ptr, t_type_info_enumerated_array_ptr);
			irValue *elem = ir_get_type_info_ptr(proc, t->EnumeratedArray.elem);
			ir_emit_store(proc, ir_emit_struct_ep(proc, tag, 0), elem);

			irValue *index = ir_get_type_info_ptr(proc, t->EnumeratedArray.index);
			ir_emit_store(proc, ir_emit_struct_ep(proc, tag, 1), index);

			i64 ez = type_size_of(t->EnumeratedArray.elem);
			irValue *elem_size = ir_emit_struct_ep(proc, tag, 2);
			ir_emit_store(proc, elem_size, ir_const_int(ez));

			irValue *count = ir_emit_struct_ep(proc, tag, 3);
			ir_emit_store(proc, count, ir_const_int(t->EnumeratedArray.count));

			irValue *min_value = ir_emit_struct_ep(proc, tag, 4);
			irValue *max_value = ir_emit_struct_ep(proc, tag, 5);

			irValue *min_v = ir_value_constant(core_type(t->EnumeratedArray.index), t->EnumeratedArray.min_value);
			irValue *max_v = ir_value_constant(core_type(t->EnumeratedArray.index), t->EnumeratedArray.max_value);

			ir_emit_store_union_variant(proc, min_value, min_v, ir_type(min_v));
			ir_emit_store_union_variant(proc, max_value, max_v, ir_type(max_v));
			break;
		}
		case Type_DynamicArray: {
			ir_emit_comment(proc, str_lit("Type_Info_Dynamic_Array"));
			tag = ir_emit_conv(proc, variant_ptr, t_type_info_dynamic_array_ptr);
			irValue *gep = ir_get_type_info_ptr(proc, t->DynamicArray.elem);
			ir_emit_store(proc, ir_emit_struct_ep(proc, tag, 0), gep);

			i64 ez = type_size_of(t->DynamicArray.elem);
			irValue *elem_size = ir_emit_struct_ep(proc, tag, 1);
			ir_emit_store(proc, elem_size, ir_const_int(ez));
			break;
		}
		case Type_Slice: {
			ir_emit_comment(proc, str_lit("Type_Info_Slice"));
			tag = ir_emit_conv(proc, variant_ptr, t_type_info_slice_ptr);
			irValue *gep = ir_get_type_info_ptr(proc, t->Slice.elem);
			ir_emit_store(proc, ir_emit_struct_ep(proc, tag, 0), gep);

			i64 ez = type_size_of(t->Slice.elem);
			irValue *elem_size = ir_emit_struct_ep(proc, tag, 1);
			ir_emit_store(proc, elem_size, ir_const_int(ez));
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
			ir_emit_store(proc, variadic, ir_const_bool(t->Proc.variadic));
			ir_emit_store(proc, convention, ir_const_int(t->Proc.calling_convention));

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

				irValue *index     = ir_const_int(i);
				irValue *type_info = ir_emit_ptr_offset(proc, memory_types, index);

				ir_emit_store(proc, type_info, ir_type_info(proc, f->type));
				if (f->token.string.len > 0) {
					irValue *name = ir_emit_ptr_offset(proc, memory_names, index);
					ir_emit_store(proc, name, ir_const_string(proc->module, f->token.string));
				}
			}

			irValue *count = ir_const_int(t->Tuple.variables.count);
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

				if (t->Enum.fields.count > 0) {
					auto fields = t->Enum.fields;
					irValue *name_array  = ir_generate_array(m, t_string, fields.count,
					                                         str_lit("$enum_names"), cast(i64)entry_index);
					irValue *value_array = ir_generate_array(m, t_type_info_enum_value, fields.count,
					                                         str_lit("$enum_values"), cast(i64)entry_index);

					GB_ASSERT(is_type_integer(t->Enum.base_type));

					for_array(i, fields) {
						irValue *name_ep  = ir_emit_array_epi(proc, name_array, cast(i32)i);
						irValue *value_ep = ir_emit_array_epi(proc, value_array, cast(i32)i);

						ExactValue value = fields[i]->Constant.value;
						irValue *v = ir_value_constant(t->Enum.base_type, value);

						ir_emit_store_union_variant(proc, value_ep, v, ir_type(v));
						ir_emit_store(proc, name_ep, ir_const_string(proc->module, fields[i]->token.string));
					}

					irValue *v_count = ir_const_int(fields.count);

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
				irValue *variant_types    = ir_emit_struct_ep(proc, tag, 0);
				irValue *tag_offset_ptr   = ir_emit_struct_ep(proc, tag, 1);
				irValue *tag_type_ptr     = ir_emit_struct_ep(proc, tag, 2);
				irValue *custom_align_ptr = ir_emit_struct_ep(proc, tag, 3);
				irValue *no_nil_ptr       = ir_emit_struct_ep(proc, tag, 4);
				irValue *maybe_ptr        = ir_emit_struct_ep(proc, tag, 5);

				isize variant_count = gb_max(0, t->Union.variants.count);
				irValue *memory_types = ir_type_info_member_types_offset(proc, variant_count);

				// NOTE(bill): Zeroth is nil so ignore it
				for (isize variant_index = 0; variant_index < variant_count; variant_index++) {
					Type *vt = t->Union.variants[variant_index];
					irValue *tip = ir_get_type_info_ptr(proc, vt);

					irValue *index     = ir_const_int(variant_index);
					irValue *type_info = ir_emit_ptr_offset(proc, memory_types, index);
					ir_emit_store(proc, type_info, ir_type_info(proc, vt));
				}

				irValue *count = ir_const_int(variant_count);
				ir_fill_slice(proc, variant_types, memory_types, count);

				i64 tag_size   = union_tag_size(t);
				i64 tag_offset = align_formula(t->Union.variant_block_size, tag_size);

				if (tag_size > 0) {
					ir_emit_store(proc, tag_offset_ptr, ir_const_uintptr(tag_offset));
					ir_emit_store(proc, tag_type_ptr,   ir_type_info(proc, union_tag_type(t)));
				}

				irValue *is_custom_align = ir_const_bool(t->Union.custom_align != 0);
				ir_emit_store(proc, custom_align_ptr, is_custom_align);

				ir_emit_store(proc, no_nil_ptr, ir_const_bool(t->Union.no_nil));
				ir_emit_store(proc, maybe_ptr, ir_const_bool(t->Union.maybe));
			}

			break;
		}

		case Type_Struct: {
			ir_emit_comment(proc, str_lit("Type_Info_Struct"));
			tag = ir_emit_conv(proc, variant_ptr, t_type_info_struct_ptr);

			{
				irValue *is_packed       = ir_const_bool(t->Struct.is_packed);
				irValue *is_raw_union    = ir_const_bool(t->Struct.is_raw_union);
				irValue *is_custom_align = ir_const_bool(t->Struct.custom_align != 0);
				ir_emit_store(proc, ir_emit_struct_ep(proc, tag, 5), is_packed);
				ir_emit_store(proc, ir_emit_struct_ep(proc, tag, 6), is_raw_union);
				ir_emit_store(proc, ir_emit_struct_ep(proc, tag, 7), is_custom_align);

				if (t->Struct.soa_kind != StructSoa_None) {
					irValue *kind = ir_emit_struct_ep(proc, tag, 8);
					Type *kind_type = type_deref(ir_type(kind));

					irValue *soa_kind = ir_value_constant(kind_type, exact_value_i64(t->Struct.soa_kind));
					irValue *soa_type = ir_type_info(proc, t->Struct.soa_elem);
					irValue *soa_len = ir_const_int(t->Struct.soa_count);


					ir_emit_store(proc, kind, soa_kind);
					ir_emit_store(proc, ir_emit_struct_ep(proc, tag, 9), soa_type);
					ir_emit_store(proc, ir_emit_struct_ep(proc, tag, 10), soa_len);
				}
			}

			isize count = t->Struct.fields.count;
			if (count > 0) {
				irValue *memory_types   = ir_type_info_member_types_offset  (proc, count);
				irValue *memory_names   = ir_type_info_member_names_offset  (proc, count);
				irValue *memory_offsets = ir_type_info_member_offsets_offset(proc, count);
				irValue *memory_usings  = ir_type_info_member_usings_offset (proc, count);
				irValue *memory_tags    = ir_type_info_member_tags_offset   (proc, count);

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

					irValue *index     = ir_const_int(source_index);
					irValue *type_info = ir_emit_ptr_offset(proc, memory_types,   index);
					irValue *offset    = ir_emit_ptr_offset(proc, memory_offsets, index);
					irValue *is_using  = ir_emit_ptr_offset(proc, memory_usings,  index);

					ir_emit_store(proc, type_info, ir_type_info(proc, f->type));
					if (f->token.string.len > 0) {
						irValue *name = ir_emit_ptr_offset(proc, memory_names,   index);
						ir_emit_store(proc, name, ir_const_string(proc->module, f->token.string));
					}
					ir_emit_store(proc, offset, ir_const_uintptr(foffset));
					ir_emit_store(proc, is_using, ir_const_bool((f->flags&EntityFlag_Using) != 0));

					if (t->Struct.tags.count > 0) {
						String tag_string = t->Struct.tags[source_index];
						if (tag_string.len > 0) {
							irValue *tag_ptr = ir_emit_ptr_offset(proc, memory_tags, index);
							ir_emit_store(proc, tag_ptr, ir_const_string(proc->module, tag_string));
						}
					}

				}

				irValue *cv = ir_const_int(count);
				ir_fill_slice(proc, ir_emit_struct_ep(proc, tag, 0), memory_types,   cv);
				ir_fill_slice(proc, ir_emit_struct_ep(proc, tag, 1), memory_names,   cv);
				ir_fill_slice(proc, ir_emit_struct_ep(proc, tag, 2), memory_offsets, cv);
				ir_fill_slice(proc, ir_emit_struct_ep(proc, tag, 3), memory_usings,  cv);
				ir_fill_slice(proc, ir_emit_struct_ep(proc, tag, 4), memory_tags,    cv);
			}
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
				irValue *name_array   = ir_generate_array(m, t_string, count, str_lit("$bit_field_names"),   cast(i64)entry_index);
				irValue *bit_array    = ir_generate_array(m, t_i32,    count, str_lit("$bit_field_bits"),    cast(i64)entry_index);
				irValue *offset_array = ir_generate_array(m, t_i32,    count, str_lit("$bit_field_offsets"), cast(i64)entry_index);

				for (isize i = 0; i < count; i++) {
					Entity *f = fields[i];
					GB_ASSERT(f->type != nullptr);
					GB_ASSERT(f->type->kind == Type_BitFieldValue);
					irValue *name_ep   = ir_emit_array_epi(proc, name_array,   cast(i32)i);
					irValue *bit_ep    = ir_emit_array_epi(proc, bit_array,    cast(i32)i);
					irValue *offset_ep = ir_emit_array_epi(proc, offset_array, cast(i32)i);

					ir_emit_store(proc, name_ep, ir_const_string(proc->module, f->token.string));
					ir_emit_store(proc, bit_ep, ir_const_i32(f->type->BitFieldValue.bits));
					ir_emit_store(proc, offset_ep, ir_const_i32(t->BitField.offsets[i]));

				}

				irValue *v_count = ir_const_int(count);

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

		case Type_BitSet:
			ir_emit_comment(proc, str_lit("Type_Info_Bit_Set"));
			tag = ir_emit_conv(proc, variant_ptr, t_type_info_bit_set_ptr);

			GB_ASSERT(is_type_typed(t->BitSet.elem));
			ir_emit_store(proc, ir_emit_struct_ep(proc, tag, 0), ir_get_type_info_ptr(proc, t->BitSet.elem));
			if (t->BitSet.underlying != nullptr) {
				ir_emit_store(proc, ir_emit_struct_ep(proc, tag, 1), ir_get_type_info_ptr(proc, t->BitSet.underlying));
			}
			ir_emit_store(proc, ir_emit_struct_ep(proc, tag, 2), ir_const_i64(t->BitSet.lower));
			ir_emit_store(proc, ir_emit_struct_ep(proc, tag, 3), ir_const_i64(t->BitSet.upper));
			break;

		case Type_Opaque:
			ir_emit_comment(proc, str_lit("Type_Opaque"));
			tag = ir_emit_conv(proc, variant_ptr, t_type_info_opaque_ptr);
			ir_emit_store(proc, ir_emit_struct_ep(proc, tag, 0), ir_get_type_info_ptr(proc, t->Opaque.elem));
			break;

		case Type_SimdVector:
			ir_emit_comment(proc, str_lit("Type_SimdVector"));
			tag = ir_emit_conv(proc, variant_ptr, t_type_info_simd_vector_ptr);
			if (t->SimdVector.is_x86_mmx) {
				ir_emit_store(proc, ir_emit_struct_ep(proc, tag, 3), v_true);
			} else {
				ir_emit_store(proc, ir_emit_struct_ep(proc, tag, 0), ir_get_type_info_ptr(proc, t->SimdVector.elem));
				ir_emit_store(proc, ir_emit_struct_ep(proc, tag, 1), ir_const_int(type_size_of(t->SimdVector.elem)));
				ir_emit_store(proc, ir_emit_struct_ep(proc, tag, 2), ir_const_int(t->SimdVector.count));
			}
			break;
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
	gbAllocator a = ir_allocator();

	if (v_zero == nullptr) {
		v_zero    = ir_const_int (0);
		v_one     = ir_const_int (1);
		v_zero32  = ir_const_i32 (0);
		v_one32   = ir_const_i32 (1);
		v_two32   = ir_const_i32 (2);
		v_false   = ir_const_bool(false);
		v_true    = ir_const_bool(true);
		v_raw_nil = ir_value_constant(t_rawptr, exact_value_pointer(0));
	}

	isize global_variable_max_count = 0;
	Entity *entry_point = info->entry_point;
	bool has_dll_main = false;
	bool has_win_main = false;

	for_array(i, info->entities) {
		Entity *e = info->entities[i];
		String name = e->token.string;

		bool is_global = e->pkg != nullptr;

		if (e->kind == Entity_Variable) {
			global_variable_max_count++;
		} else if (e->kind == Entity_Procedure && !is_global) {
			if ((e->scope->flags&ScopeFlag_Init) && name == "main") {
				GB_ASSERT(e == entry_point);
				// entry_point = e;
			}
			if (e->Procedure.is_export ||
			    (e->Procedure.link_name.len > 0) ||
			    ((e->scope->flags&ScopeFlag_File) && e->Procedure.link_name.len > 0)) {
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

		Entity *e = d->entity;

		if ((e->scope->flags & ScopeFlag_File) == 0) {
			continue;
		}

		if (!ir_min_dep_entity(m, e)) {
			continue;
		}
		DeclInfo *decl = decl_info_of_entity(e);
		if (decl == nullptr) {
			continue;
		}
		GB_ASSERT(e->kind == Entity_Variable);

		bool is_foreign = e->Variable.is_foreign;
		bool is_export  = e->Variable.is_export;
		bool no_name_mangle = e->Variable.link_name.len > 0 || is_foreign || is_export;

		String name = e->token.string;
		if (!no_name_mangle) {
			name = ir_mangle_name(s, e);
		}
		ir_add_entity_name(m, e, name);

		irValue *g = ir_value_global(e, nullptr);
		g->Global.name = name;
		g->Global.thread_local_model = e->Variable.thread_local_model;
		g->Global.is_foreign = is_foreign;
		g->Global.is_export  = is_export;

		irGlobalVariable var = {};
		var.var = g;
		var.decl = decl;

		if (decl->init_expr != nullptr && !is_type_any(e->type)) {
			TypeAndValue tav = type_and_value_of_expr(decl->init_expr);
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

	for_array(i, info->entities) {
		Entity *  e     = info->entities[i];
		String    name  = e->token.string;
		DeclInfo *decl  = e->decl_info;
		Scope *   scope = e->scope;

		if ((scope->flags & ScopeFlag_File) == 0) {
			continue;
		}

		Scope *package_scope = scope->parent;
		GB_ASSERT(package_scope->flags & ScopeFlag_Pkg);

		switch (e->kind) {
		case Entity_Variable:
			// NOTE(bill): Handled above as it requires a specific load order
			continue;
		case Entity_ProcGroup:
			continue;

		case Entity_Procedure:
			break;
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

	#if 0
		if (!package_scope->is_global || polymorphic_struct || is_type_polymorphic(e->type)) {
			if (e->kind == Entity_Procedure && e->Procedure.is_export) {
			} else if (e->kind == Entity_Procedure && e->Procedure.link_name.len > 0) {
				// Handle later
			} else {
				name = ir_mangle_name(s, e);
			}
		}
	#else
			if (e->kind == Entity_Procedure && e->Procedure.is_export) {
				// Okay
			} else if (e->kind == Entity_Procedure && e->Procedure.link_name.len > 0) {
				// Handle later
			} else {
				name = ir_mangle_name(s, e);
			}
	#endif

		ir_add_entity_name(m, e, name);

		switch (e->kind) {
		case Entity_TypeName:
			ir_gen_global_type_name(m, e, name);
			break;

		case Entity_Procedure: {
			ast_node(pl, ProcLit, decl->proc_lit);
			String original_name = name;
			Ast *body = pl->body;

			if (e->Procedure.is_foreign) {
				name = e->token.string; // NOTE(bill): Don't use the mangled name
				ir_add_foreign_library_path(m, e->Procedure.foreign_library);
			}
			if (e->Procedure.link_name.len > 0) {
				name = e->Procedure.link_name;
			}

			Ast *type_expr = pl->type;

			set_procedure_abi_types(heap_allocator(), e->type);
			irValue *p = ir_value_procedure(m, e, e->type, type_expr, body, name);
			p->Proc.tags = pl->tags;
			p->Proc.inlining = pl->inlining;
			p->Proc.is_export = e->Procedure.is_export;

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

		Ast *body = alloc_ast_node(nullptr, Ast_Invalid);
		Entity *e = alloc_entity_procedure(nullptr, make_token_ident(name), proc_type, 0);
		irValue *p = ir_value_procedure(m, e, proc_type, nullptr, body, name);

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

#if 0
		if (str_eq_ignore_case(cross_compile_target, str_lit("Essence"))) {
			// This is a bit hacky,
			// because this makes this function the first function run in the executable
			// so it won't actually have the argc/argv arguments.
			name = str_lit("ProgramEntry");
		}
#endif

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

		Ast *body = alloc_ast_node(nullptr, Ast_Invalid);
		Entity *e     = alloc_entity_procedure(nullptr, make_token_ident(name), proc_type, 0);
		irValue *p    = ir_value_procedure(m, e, proc_type, nullptr, body, name);

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

		irValue *global_args = ir_find_global_variable(proc, str_lit("args__"));

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

#if defined(GB_SYSTEM_WINDOWS)
	// if (!m->build_context->is_dll && !has_win_main) {
	// 	// proc WinMain(inst, prev: rawptr, cmd_line: ^byte, cmd_show: i32) -> i32
	// 	String name = str_lit("WinMain");
	// 	Type *proc_params = alloc_type_tuple();
	// 	Type *proc_results = alloc_type_tuple();

	// 	Scope *proc_scope = gb_alloc_item(a, Scope);

	// 	proc_params->Tuple.variables = gb_alloc_array(a, Entity *, 4);
	// 	proc_params->Tuple.variable_count = 4;

	// 	proc_results->Tuple.variables = gb_alloc_array(a, Entity *, 1);
	// 	proc_results->Tuple.variable_count = 1;

	// 	proc_params->Tuple.variables[0] = alloc_entity_param(proc_scope, blank_token, t_rawptr, false);
	// 	proc_params->Tuple.variables[1] = alloc_entity_param(proc_scope, blank_token, t_rawptr, false);
	// 	proc_params->Tuple.variables[2] = alloc_entity_param(proc_scope, blank_token, t_u8_ptr, false);
	// 	proc_params->Tuple.variables[3] = alloc_entity_param(proc_scope, blank_token, t_i32,    false);

	// 	proc_results->Tuple.variables[0] = alloc_entity_param(proc_scope, empty_token, t_i32, false);


	// 	Type *proc_type = alloc_type_proc(a, proc_scope,
	// 	                                 proc_params, 4,
	// 	                                 proc_results, 1, false, ProcCC_Std);

	// 	Ast *body = alloc_ast_node(nullptr, Ast_Invalid);
	// 	Entity *e = alloc_entity_procedure(a, nullptr, make_token_ident(name), proc_type, 0);
	// 	irValue *p = ir_value_procedure(m, e, proc_type, nullptr, body, name);

	// 	m->entry_point_entity = e;

	// 	map_set(&m->values, hash_entity(e), p);
	// 	map_set(&m->members, hash_string(name), p);

	// 	irProcedure *proc = &p->Proc;
	// 	proc->tags = ProcTag_no_inline; // TODO(bill): is no_inline a good idea?
	// 	e->Procedure.link_name = name;

	// 	ir_begin_procedure_body(proc);
	// 	ir_emit_runtime_call(proc, "main", nullptr, 0);
	// 	ir_emit_return(proc, v_one32);
	// 	ir_end_procedure_body(proc);
	// }
	if (!build_context.is_dll && build_context.no_crt) {
		s->print_chkstk = true;

		{
			// void mainCRTStartup(void)
			String name = str_lit("mainCRTStartup");
			Type *proc_params = alloc_type_tuple();
			Type *proc_results = alloc_type_tuple();


			Type *proc_type = alloc_type_proc(nullptr,
			                                  nullptr, 0,
			                                  nullptr, 0,
			                                  false,
			                                  ProcCC_StdCall);

			Ast *body = alloc_ast_node(nullptr, Ast_Invalid);
			Entity *e = alloc_entity_procedure(nullptr, make_token_ident(name), proc_type, 0);
			irValue *p = ir_value_procedure(m, e, proc_type, nullptr, body, name);

			m->entry_point_entity = e;

			map_set(&m->values, hash_entity(e), p);
			map_set(&m->members, hash_string(name), p);

			irProcedure *proc = &p->Proc;
			// proc->tags = ProcTag_no_inline; // TODO(bill): is no_inline a good idea?
			e->Procedure.link_name = name;

			ir_begin_procedure_body(proc);
			ir_emit(proc, ir_alloc_instr(proc, irInstr_StartupRuntime));
			irValue **found = map_get(&proc->module->values, hash_entity(entry_point));
			if (found != nullptr) {
				Array<irValue *> args = {};
				ir_emit_call(proc, *found, args);
			}
			ir_end_procedure_body(proc);
		}
	}

	for_array(i, m->info->required_foreign_imports_through_force) {
		Entity *e = m->info->required_foreign_imports_through_force[i];
		ir_add_foreign_library_path(m, e);
	}

#endif
	{ // Startup Runtime
		// Cleanup(bill): probably better way of doing code insertion
		String name = str_lit(IR_STARTUP_RUNTIME_PROC_NAME);
		Type *proc_type = alloc_type_proc(gb_alloc_item(a, Scope),
		                                  nullptr, 0,
		                                  nullptr, 0, false,
		                                  ProcCC_Contextless);
		Ast *body = alloc_ast_node(nullptr, Ast_Invalid);
		Entity *e = alloc_entity_procedure(nullptr, make_token_ident(name), proc_type, 0);
		irValue *p = ir_value_procedure(m, e, proc_type, nullptr, body, name);

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

			if (e->flags & EntityFlag_Static) {
				var->var->Global.is_internal = true;
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

	GB_ASSERT_MSG(m->debug_location_stack.count == 0, "Debug location stack contains unpopped entries.");

	// Number debug info
	for_array(i, m->debug_info.entries) {
		auto *entry = &m->debug_info.entries[i];
		irDebugInfo *di = entry->value;
		di->id = cast(i32)(i+1);
	}


	// m->layout = str_lit("e-p:64:64:64-i1:8:8-i8:8:8-i16:16:16-i32:32:32-i64:64:64-f32:32:32-f64:64:64-v64:64:64-v128:128:128-a0:0:64-s0:64:64-f80:128:128-n8:16:32:64");
}

