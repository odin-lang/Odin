struct ssaProcedure;
struct ssaBlock;
struct ssaValue;
struct ssaDebugInfo;

struct ssaModule {
	CheckerInfo * info;
	BaseTypeSizes sizes;
	gbArena       arena;
	gbArena       tmp_arena;
	gbAllocator   allocator;
	gbAllocator   tmp_allocator;
	b32 generate_debug_info;

	u32 stmt_state_flags;

	// String source_filename;
	String layout;
	// String triple;

	Map<ssaValue *>     values;     // Key: Entity *
	Map<ssaValue *>     members;    // Key: String
	Map<String>         type_names; // Key: Type *
	Map<ssaDebugInfo *> debug_info; // Key: Unique pointer
	i32                 global_string_index;
	i32                 global_array_index; // For ConstantSlice

	Array<ssaValue *> procs; // NOTE(bill): Procedures to generate
};

// NOTE(bill): For more info, see https://en.wikipedia.org/wiki/Dominator_(graph_theory)
struct ssaDomNode {
	ssaBlock *        idom; // Parent (Immediate Dominator)
	Array<ssaBlock *> children;
	i32               pre, post; // Ordering in tree
};


struct ssaBlock {
	i32           index;
	String        label;
	ssaProcedure *parent;
	AstNode *     node; // Can be NULL
	Scope *       scope;
	isize         scope_index;
	ssaDomNode    dom;
	i32           gaps;

	Array<ssaValue *> instrs;
	Array<ssaValue *> locals;

	Array<ssaBlock *> preds;
	Array<ssaBlock *> succs;
};

struct ssaTargetList {
	ssaTargetList *prev;
	ssaBlock *     break_;
	ssaBlock *     continue_;
	ssaBlock *     fallthrough_;
};

enum ssaDeferExitKind {
	ssaDeferExit_Default,
	ssaDeferExit_Return,
	ssaDeferExit_Branch,
};
enum ssaDeferKind {
	ssaDefer_Node,
	ssaDefer_Instr,
};

struct ssaDefer {
	ssaDeferKind kind;
	isize        scope_index;
	ssaBlock *   block;
	union {
		AstNode *stmt;
		// NOTE(bill): `instr` will be copied every time to create a new one
		ssaValue *instr;
	};
};

struct ssaProcedure {
	ssaProcedure *        parent;
	Array<ssaProcedure *> children;

	Entity *              entity;
	ssaModule *           module;
	String                name;
	Type *                type;
	AstNode *             type_expr;
	AstNode *             body;
	u64                   tags;

	Array<ssaValue *>     params;
	Array<ssaDefer>       defer_stmts;
	Array<ssaBlock *>     blocks;
	i32                   scope_index;
	ssaBlock *            decl_block;
	ssaBlock *            entry_block;
	ssaBlock *            curr_block;
	ssaTargetList *       target_list;
	Array<ssaValue *>     referrers;

	i32                   local_count;
	i32                   instr_count;
	i32                   block_count;
};

#define SSA_STARTUP_RUNTIME_PROC_NAME  "__$startup_runtime"
#define SSA_TYPE_INFO_DATA_NAME        "__$type_info_data"
#define SSA_TYPE_INFO_DATA_MEMBER_NAME "__$type_info_data_member"


#define SSA_INSTR_KINDS \
	SSA_INSTR_KIND(Invalid), \
	SSA_INSTR_KIND(Comment), \
	SSA_INSTR_KIND(Local), \
	SSA_INSTR_KIND(ZeroInit), \
	SSA_INSTR_KIND(Store), \
	SSA_INSTR_KIND(Load), \
	SSA_INSTR_KIND(PtrOffset), \
	SSA_INSTR_KIND(ArrayElementPtr), \
	SSA_INSTR_KIND(StructElementPtr), \
	SSA_INSTR_KIND(ArrayExtractValue), \
	SSA_INSTR_KIND(StructExtractValue), \
	SSA_INSTR_KIND(Conv), \
	SSA_INSTR_KIND(Jump), \
	SSA_INSTR_KIND(If), \
	SSA_INSTR_KIND(Return), \
	SSA_INSTR_KIND(Select), \
	SSA_INSTR_KIND(Phi), \
	SSA_INSTR_KIND(Unreachable), \
	SSA_INSTR_KIND(BinaryOp), \
	SSA_INSTR_KIND(Call), \
	SSA_INSTR_KIND(VectorExtractElement), \
	SSA_INSTR_KIND(VectorInsertElement), \
	SSA_INSTR_KIND(VectorShuffle), \
	SSA_INSTR_KIND(StartupRuntime), \
	SSA_INSTR_KIND(BoundsCheck), \
	SSA_INSTR_KIND(SliceBoundsCheck), \

#define SSA_CONV_KINDS \
	SSA_CONV_KIND(Invalid), \
	SSA_CONV_KIND(trunc), \
	SSA_CONV_KIND(zext), \
	SSA_CONV_KIND(fptrunc), \
	SSA_CONV_KIND(fpext), \
	SSA_CONV_KIND(fptoui), \
	SSA_CONV_KIND(fptosi), \
	SSA_CONV_KIND(uitofp), \
	SSA_CONV_KIND(sitofp), \
	SSA_CONV_KIND(ptrtoint), \
	SSA_CONV_KIND(inttoptr), \
	SSA_CONV_KIND(bitcast),

enum ssaInstrKind {
#define SSA_INSTR_KIND(x) GB_JOIN2(ssaInstr_, x)
	SSA_INSTR_KINDS
#undef SSA_INSTR_KIND
};

String const ssa_instr_strings[] = {
#define SSA_INSTR_KIND(x) {cast(u8 *)#x, gb_size_of(#x)-1}
	SSA_INSTR_KINDS
#undef SSA_INSTR_KIND
};

enum ssaConvKind {
#define SSA_CONV_KIND(x) GB_JOIN2(ssaConv_, x)
	SSA_CONV_KINDS
#undef SSA_CONV_KIND
};

String const ssa_conv_strings[] = {
#define SSA_CONV_KIND(x) {cast(u8 *)#x, gb_size_of(#x)-1}
	SSA_CONV_KINDS
#undef SSA_CONV_KIND
};

struct ssaInstr {
	ssaInstrKind kind;

	ssaBlock *parent;
	Type *type;

	union {
		struct {
			String text;
		} Comment;
		struct {
			Entity *          entity;
			Type *            type;
			b32               zero_initialized;
			Array<ssaValue *> referrers;
		} Local;
		struct {
			ssaValue *address;
		} ZeroInit;
		struct {
			ssaValue *address;
			ssaValue *value;
		} Store;
		struct {
			Type *type;
			ssaValue *address;
		} Load;
		struct {
			ssaValue *address;
			Type *    result_type;
			ssaValue *elem_index;
		} ArrayElementPtr;
		struct {
			ssaValue *address;
			Type *    result_type;
			i32       elem_index;
		} StructElementPtr;
		struct {
			ssaValue *address;
			ssaValue *offset;
		} PtrOffset;
		struct {
			ssaValue *address;
			Type *    result_type;
			i32       index;
		} ArrayExtractValue;
		struct {
			ssaValue *address;
			Type *    result_type;
			i32       index;
		} StructExtractValue;
		struct {
			ssaValue *value;
			ssaValue *elem;
			i32       index;
		} InsertValue;
		struct {
			ssaConvKind kind;
			ssaValue *value;
			Type *from, *to;
		} Conv;
		struct {
			ssaBlock *block;
		} Jump;
		struct {
			ssaValue *cond;
			ssaBlock *true_block;
			ssaBlock *false_block;
		} If;
		struct {
			ssaValue *value;
		} Return;
		struct {} Unreachable;
		struct {
			ssaValue *cond;
			ssaValue *true_value;
			ssaValue *false_value;
		} Select;
		struct {
			Array<ssaValue *> edges;
			Type *type;
		} Phi;
		struct {
			Type *type;
			TokenKind op;
			ssaValue *left, *right;
		} BinaryOp;
		struct {
			Type *type; // return type
			ssaValue *value;
			ssaValue **args;
			isize arg_count;
		} Call;
		struct {
			ssaValue *vector;
			ssaValue *index;
		} VectorExtractElement;
		struct {
			ssaValue *vector;
			ssaValue *elem;
			ssaValue *index;
		} VectorInsertElement;
		struct {
			ssaValue *vector;
			i32 *indices;
			isize index_count;
			Type *type;
		} VectorShuffle;

		struct {} StartupRuntime;
		struct {
			TokenPos  pos;
			ssaValue *index;
			ssaValue *len;
		} BoundsCheck;
		struct {
			TokenPos  pos;
			ssaValue *low;
			ssaValue *high;
			ssaValue *max;
			b32       is_substring;
		} SliceBoundsCheck;
	};
};


enum ssaValueKind {
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
};

struct ssaValue {
	ssaValueKind kind;
	i32 index;
	union {
		struct {
			Type *     type;
			ExactValue value;
		} Constant;
		struct {
			Type *    type;
			ssaValue *backing_array;
			i64       count;
		} ConstantSlice;
		struct {
			Type *type;
		} Nil;
		struct {
			Type * type;
			String name;
		} TypeName;
		struct {
			Entity *          entity;
			Type *            type;
			ssaValue *        value;
			Array<ssaValue *> referrers;
			b8                is_constant;
			b8                is_private;
			b8                is_thread_local;
			b8                is_unnamed_addr;
		} Global;
		struct {
			ssaProcedure *    parent;
			Entity *          entity;
			Type *            type;
			Array<ssaValue *> referrers;
		} Param;
		ssaProcedure Proc;
		ssaBlock     Block;
		ssaInstr     Instr;
	};
};

gb_global ssaValue *v_zero    = NULL;
gb_global ssaValue *v_one     = NULL;
gb_global ssaValue *v_zero32  = NULL;
gb_global ssaValue *v_one32   = NULL;
gb_global ssaValue *v_two32   = NULL;
gb_global ssaValue *v_false   = NULL;
gb_global ssaValue *v_true    = NULL;

enum ssaAddrKind {
	ssaAddr_Default,
	ssaAddr_Vector,
};

struct ssaAddr {
	ssaValue *  addr;
	AstNode *   expr; // NOTE(bill): Just for testing - probably remove later
	ssaAddrKind kind;
	union {
		struct { ssaValue *index; } Vector;
	};
};

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



enum ssaDebugEncoding {
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

};

enum ssaDebugInfoKind {
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
};

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
			Array<ssaDebugInfo *> procs;
		} AllProcs;


		struct {
			String           name;
			i32              size;
			i32              align;
			ssaDebugEncoding encoding;
		} BasicType;
		struct {
			ssaDebugInfo *        return_type;
			Array<ssaDebugInfo *> param_types;
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
			Array<ssaDebugInfo *> elements;
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



struct ssaFileBuffer {
	gbVirtualMemory vm;
	isize offset;
	gbFile *output;
};

void ssa_file_buffer_init(ssaFileBuffer *f, gbFile *output) {
	isize size = 8*gb_virtual_memory_page_size(NULL);
	f->vm = gb_vm_alloc(NULL, size);
	f->offset = 0;
	f->output = output;
}

void ssa_file_buffer_destroy(ssaFileBuffer *f) {
	if (f->offset > 0) {
		// NOTE(bill): finish writing buffered data
		gb_file_write(f->output, f->vm.data, f->offset);
	}

	gb_vm_free(f->vm);
}

void ssa_file_buffer_write(ssaFileBuffer *f, void *data, isize len) {
	if (len > f->vm.size) {
		gb_file_write(f->output, data, len);
		return;
	}

	if ((f->vm.size - f->offset) < len) {
		gb_file_write(f->output, f->vm.data, f->offset);
		f->offset = 0;
	}
	u8 *cursor = cast(u8 *)f->vm.data + f->offset;
	gb_memmove(cursor, data, len);
	f->offset += len;
}


void ssa_fprintf(ssaFileBuffer *f, char *fmt, ...) {
	va_list va;
	va_start(va, fmt);
	char buf[4096] = {};
	isize len = gb_snprintf_va(buf, gb_size_of(buf), fmt, va);
	ssa_file_buffer_write(f, buf, len-1);
	va_end(va);
}


void ssa_file_write(ssaFileBuffer *f, void *data, isize len) {
	ssa_file_buffer_write(f, data, len);
}

ssaValue *ssa_lookup_member(ssaModule *m, String name) {
	ssaValue **v = map_get(&m->members, hash_string(name));
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



b32 ssa_is_blank_ident(AstNode *node) {
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
			ssaValue *v = block->instrs[len-1];
			GB_ASSERT(v->kind == ssaValue_Instr);
			return &v->Instr;
		}
	}
	return NULL;

}

b32 ssa_is_instr_terminating(ssaInstr *i) {
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

Array<ssaValue *> *ssa_value_referrers(ssaValue *v) {
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



#include "make.cpp"
#include "debug.cpp"
#include "emit.cpp"
#include "build.cpp"
#include "opt.cpp"
#include "proc.cpp"




void ssa_module_add_value(ssaModule *m, Entity *e, ssaValue *v) {
	map_set(&m->values, hash_pointer(e), v);
}

void ssa_init_module(ssaModule *m, Checker *c) {
	// TODO(bill): Determine a decent size for the arena
	isize token_count = c->parser->total_token_count;
	isize arena_size = 4 * token_count * gb_size_of(ssaValue);
	gb_arena_init_from_allocator(&m->arena, heap_allocator(), arena_size);
	gb_arena_init_from_allocator(&m->tmp_arena, heap_allocator(), arena_size);
	m->allocator     = gb_arena_allocator(&m->arena);
	m->tmp_allocator = gb_arena_allocator(&m->tmp_arena);
	m->info = &c->info;
	m->sizes = c->sizes;

	map_init(&m->values,     heap_allocator());
	map_init(&m->members,    heap_allocator());
	map_init(&m->debug_info, heap_allocator());
	map_init(&m->type_names, heap_allocator());
	array_init(&m->procs,  heap_allocator());

	// Default states
	m->stmt_state_flags = 0;
	m->stmt_state_flags |= StmtStateFlag_bounds_check;

	{
		// Add type info data
		{
			String name = make_string(SSA_TYPE_INFO_DATA_NAME);
			isize count = c->info.type_info_map.entries.count;
			Entity *e = make_entity_variable(m->allocator, NULL, make_token_ident(name), make_type_array(m->allocator, t_type_info, count));
			ssaValue *g = ssa_make_value_global(m->allocator, e, NULL);
			g->Global.is_private  = true;
			ssa_module_add_value(m, e, g);
			map_set(&m->members, hash_string(name), g);
		}

		// Type info member buffer
		{
			// NOTE(bill): Removes need for heap allocation by making it global memory
			isize count = 0;

			for_array(entry_index, m->info->type_info_map.entries) {
				auto *entry = &m->info->type_info_map.entries[entry_index];
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

			String name = make_string(SSA_TYPE_INFO_DATA_MEMBER_NAME);
			Entity *e = make_entity_variable(m->allocator, NULL, make_token_ident(name),
			                                 make_type_array(m->allocator, t_type_info_member, count));
			ssaValue *g = ssa_make_value_global(m->allocator, e, NULL);
			ssa_module_add_value(m, e, g);
			map_set(&m->members, hash_string(name), g);
		}
	}

	{
		ssaDebugInfo *di = ssa_alloc_debug_info(m->allocator, ssaDebugInfo_CompileUnit);
		di->CompileUnit.file = m->info->files.entries[0].value; // Zeroth is the init file
		di->CompileUnit.producer = make_string("odin");

		map_set(&m->debug_info, hash_pointer(m), di);
	}
}

void ssa_destroy_module(ssaModule *m) {
	map_destroy(&m->values);
	map_destroy(&m->members);
	map_destroy(&m->type_names);
	map_destroy(&m->debug_info);
	array_free(&m->procs);
	gb_arena_free(&m->arena);
}




#include "codegen.cpp"


