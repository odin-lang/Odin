#if defined(GB_SYSTEM_WINDOWS)
	#pragma warning(push)
	#pragma warning(disable: 4200)
	#pragma warning(disable: 4201)
	#define restrict gb_restrict
#endif

#include "tilde/tb.h"

#define TB_TYPE_I128   TB_DataType{ { TB_INT, 0, 128 } }
#define TB_TYPE_INT    TB_TYPE_INTN(cast(u16)build_context.int_size)
#define TB_TYPE_INTPTR TB_TYPE_INTN(cast(u16)build_context.ptr_size)

#if defined(GB_SYSTEM_WINDOWS)
	#pragma warning(pop)
#endif

#define CG_STARTUP_RUNTIME_PROC_NAME   "__$startup_runtime"
#define CG_CLEANUP_RUNTIME_PROC_NAME   "__$cleanup_runtime"
#define CG_STARTUP_TYPE_INFO_PROC_NAME "__$startup_type_info"
#define CG_TYPE_INFO_DATA_NAME       "__$type_info_data"
#define CG_TYPE_INFO_TYPES_NAME      "__$type_info_types_data"
#define CG_TYPE_INFO_NAMES_NAME      "__$type_info_names_data"
#define CG_TYPE_INFO_OFFSETS_NAME    "__$type_info_offsets_data"
#define CG_TYPE_INFO_USINGS_NAME     "__$type_info_usings_data"
#define CG_TYPE_INFO_TAGS_NAME       "__$type_info_tags_data"

struct cgModule;


enum cgValueKind : u32 {
	cgValue_Value,
	cgValue_Addr,
	cgValue_Symbol,
};

struct cgValue {
	cgValueKind kind;
	Type *      type;
	union {
		TB_Symbol *symbol;
		TB_Node *  node;
	};
};

enum cgAddrKind {
	cgAddr_Default,
	cgAddr_Map,
	cgAddr_Context,
	cgAddr_SoaVariable,

	cgAddr_RelativePointer,
	cgAddr_RelativeSlice,

	cgAddr_Swizzle,
	cgAddr_SwizzleLarge,
};

struct cgAddr {
	cgAddrKind kind;
	cgValue addr;
	union {
		struct {
			cgValue key;
			Type *type;
			Type *result;
		} map;
		struct {
			Selection sel;
		} ctx;
		struct {
			cgValue index;
			Ast *index_expr;
		} soa;
		struct {
			cgValue index;
			Ast *node;
		} index_set;
		struct {
			bool deref;
		} relative;
		struct {
			Type *type;
			u8 count;      // 2, 3, or 4 components
			u8 indices[4];
		} swizzle;
		struct {
			Type *type;
			Slice<i32> indices;
		} swizzle_large;
	};
};


struct cgTargetList {
	cgTargetList *prev;
	bool          is_block;
	// control regions
	TB_Node *     break_;
	TB_Node *     continue_;
	TB_Node *     fallthrough_;
};

struct cgBranchBlocks {
	Ast *    label;
	TB_Node *break_;
	TB_Node *continue_;
};

enum cgDeferExitKind {
	cgDeferExit_Default,
	cgDeferExit_Return,
	cgDeferExit_Branch,
};

struct cgContextData {
	cgAddr ctx;
	isize scope_index;
	isize uses;
};

struct cgProcedure {
	u32 flags;
	u16 state_flags;

	cgProcedure *parent;
	Array<cgProcedure *> children;

	TB_Function *func;
	TB_Symbol *symbol;

	Entity *  entity;
	cgModule *module;
	String    name;
	Type *    type;
	Ast *     type_expr;
	Ast *     body;
	u64       tags;
	ProcInlining inlining;
	bool         is_foreign;
	bool         is_export;
	bool         is_entry_point;
	bool         is_startup;

	cgValue value;

	Ast *curr_stmt;

	cgTargetList *        target_list;
	Array<cgBranchBlocks> branch_blocks;

	Scope *curr_scope;
	i32    scope_index;

	Array<Scope *>       scope_stack;
	Array<cgContextData> context_stack;
};


struct cgModule {
	TB_Module *  mod;
	Checker *    checker;
	CheckerInfo *info;

	RwMutex values_mutex;
	PtrMap<Entity *, cgValue> values;
	StringMap<cgValue> members;

	StringMap<cgProcedure *> procedures;
	PtrMap<TB_Function *, Entity *> procedure_values;
	Array<cgProcedure *> procedures_to_generate;

	PtrMap<uintptr, TB_FileID> file_id_map; // Key: AstFile.id (i32 cast to uintptr)

	std::atomic<u32> nested_type_name_guid;
	std::atomic<u32> const_nil_guid;
};

#ifndef ABI_PKG_NAME_SEPARATOR
#define ABI_PKG_NAME_SEPARATOR "."
#endif

gb_global Entity *cg_global_type_info_data_entity   = {};
gb_global cgAddr cg_global_type_info_member_types   = {};
gb_global cgAddr cg_global_type_info_member_names   = {};
gb_global cgAddr cg_global_type_info_member_offsets = {};
gb_global cgAddr cg_global_type_info_member_usings  = {};
gb_global cgAddr cg_global_type_info_member_tags    = {};

gb_global isize cg_global_type_info_data_index           = 0;
gb_global isize cg_global_type_info_member_types_index   = 0;
gb_global isize cg_global_type_info_member_names_index   = 0;
gb_global isize cg_global_type_info_member_offsets_index = 0;
gb_global isize cg_global_type_info_member_usings_index  = 0;
gb_global isize cg_global_type_info_member_tags_index    = 0;

gb_internal cgValue cg_value(TB_Global *  g,    Type *type);
gb_internal cgValue cg_value(TB_External *e,    Type *type);
gb_internal cgValue cg_value(TB_Function *f,    Type *type);
gb_internal cgValue cg_value(TB_Symbol *  s,    Type *type);
gb_internal cgValue cg_value(TB_Node *    node, Type *type);

gb_internal cgAddr cg_addr(cgValue const &value);


gb_internal cgValue cg_const_value(cgProcedure *p, Type *type, ExactValue const &value);
gb_internal cgValue cg_const_nil(cgProcedure *p, Type *type);

gb_internal void cg_build_stmt(cgProcedure *p, Ast *stmt);
gb_internal void cg_build_stmt_list(cgProcedure *p, Slice<Ast *> const &stmts);
gb_internal void cg_build_when_stmt(cgProcedure *p, AstWhenStmt *ws);

gb_internal cgValue cg_build_expr(cgProcedure *p, Ast *expr);
gb_internal cgAddr  cg_build_addr(cgProcedure *p, Ast *expr);

gb_internal Type *  cg_addr_type(cgAddr const &addr);
gb_internal cgValue cg_addr_load(cgProcedure *p, cgAddr addr);
gb_internal void    cg_addr_store(cgProcedure *p, cgAddr addr, cgValue value);

gb_internal cgValue cg_emit_load(cgProcedure *p, cgValue const &ptr, bool is_volatile=false);
gb_internal void cg_emit_store(cgProcedure *p, cgValue dst, cgValue const &src, bool is_volatile=false);

gb_internal cgAddr cg_add_local(cgProcedure *p, Type *type, Entity *e, bool zero_init);

gb_internal cgValue cg_build_call_expr(cgProcedure *p, Ast *expr);

gb_internal cgValue cg_find_procedure_value_from_entity(cgModule *m, Entity *e);

gb_internal TB_DebugType *cg_debug_type(cgModule *m, Type *type);