#if defined(GB_SYSTEM_WINDOWS)
	#pragma warning(push)
	#pragma warning(disable: 4200)
	#pragma warning(disable: 4201)
	#define restrict gb_restrict
#endif

#include "tilde/tb.h"
#include "tilde/tb_arena.h"

#define TB_TYPE_F16    TB_DataType{ { TB_INT, 16 } }
#define TB_TYPE_I128   TB_DataType{ { TB_INT, 128 } }
#define TB_TYPE_INT    TB_TYPE_INTN(cast(u16)(8*build_context.int_size))
#define TB_TYPE_INTPTR TB_TYPE_INTN(cast(u16)(8*build_context.ptr_size))

#if defined(GB_SYSTEM_WINDOWS)
	#pragma warning(pop)
#endif

#define CG_STARTUP_RUNTIME_PROC_NAME   "__$startup_runtime"
#define CG_CLEANUP_RUNTIME_PROC_NAME   "__$cleanup_runtime"
#define CG_STARTUP_TYPE_INFO_PROC_NAME "__$startup_type_info"
#define CG_TYPE_INFO_DATA_NAME         "__$type_info_data"
#define CG_TYPE_INFO_TYPES_NAME        "__$type_info_types_data"
#define CG_TYPE_INFO_NAMES_NAME        "__$type_info_names_data"
#define CG_TYPE_INFO_OFFSETS_NAME      "__$type_info_offsets_data"
#define CG_TYPE_INFO_USINGS_NAME       "__$type_info_usings_data"
#define CG_TYPE_INFO_TAGS_NAME         "__$type_info_tags_data"
#define CG_TYPE_INFO_ENUM_VALUES_NAME  "__$type_info_enum_values_data"

struct cgModule;


enum cgValueKind : u32 {
	cgValue_Value,  // rvalue
	cgValue_Addr,   // lvalue
	cgValue_Symbol, // global
	cgValue_Multi,  // multiple values
};

struct cgValueMulti;

struct cgValue {
	cgValueKind kind;
	Type *      type;
	union {
		// NOTE: any value in this union must be a pointer
		TB_Symbol *   symbol;
		TB_Node *     node;
		cgValueMulti *multi;
	};
};

struct cgValueMulti {
	Slice<cgValue> values;
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

struct cgBranchRegions {
	Ast *    label;
	TB_Node *break_;
	TB_Node *continue_;
};

enum cgDeferExitKind {
	cgDeferExit_Default,
	cgDeferExit_Return,
	cgDeferExit_Branch,
};

enum cgDeferKind {
	cgDefer_Node,
	cgDefer_Proc,
};

struct cgDefer {
	cgDeferKind kind;
	isize       scope_index;
	isize       context_stack_count;
	TB_Node *   control_region;
	union {
		Ast *stmt;
		struct {
			cgValue deferred;
			Slice<cgValue> result_as_args;
		} proc;
	};
};


struct cgContextData {
	cgAddr ctx;
	isize scope_index;
	isize uses;
};

struct cgControlRegion {
	TB_Node *control_region;
	isize    scope_index;
};

struct cgProcedure {
	u32 flags;
	u16 state_flags;

	cgProcedure *parent;
	Array<cgProcedure *> children;

	TB_Function *func;
	TB_FunctionPrototype *proto;
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

	TB_DebugType *debug_type;

	cgValue value;

	Ast *curr_stmt;

	cgTargetList *         target_list;
	Array<cgDefer>         defer_stack;
	Array<Scope *>         scope_stack;
	Array<cgContextData>   context_stack;

	Array<cgControlRegion> control_regions;
	Array<cgBranchRegions> branch_regions;

	Scope *curr_scope;
	i32    scope_index;
	bool   in_multi_assignment;
	isize  split_returns_index;
	bool   return_by_ptr;

	PtrMap<Entity *, cgAddr> variable_map;
	PtrMap<Entity *, cgAddr> soa_values_map;
};


struct cgModule {
	TB_Module *  mod;
	Checker *    checker;
	CheckerInfo *info;
	LinkerData * linker_data;

	bool do_threading;
	Array<cgProcedure *> single_threaded_procedure_queue;

	RwMutex values_mutex;
	PtrMap<Entity *, cgValue>       values;
	PtrMap<Entity *, TB_Symbol *>   symbols;
	StringMap<cgValue>              members;
	StringMap<cgProcedure *>        procedures;
	PtrMap<TB_Function *, Entity *> procedure_values;

	RecursiveMutex debug_type_mutex;
	PtrMap<Type *, TB_DebugType *> debug_type_map;
	PtrMap<Type *, TB_DebugType *> proc_debug_type_map; // not pointer to

	RecursiveMutex proc_proto_mutex;
	PtrMap<Type *, TB_FunctionPrototype *> proc_proto_map;

	BlockingMutex anonymous_proc_lits_mutex;
	PtrMap<Ast *, cgProcedure *> anonymous_proc_lits_map;

	RecursiveMutex generated_procs_mutex;
	PtrMap<Type *, cgProcedure *> equal_procs;
	PtrMap<Type *, cgProcedure *> hasher_procs;
	PtrMap<Type *, cgProcedure *> map_get_procs;
	PtrMap<Type *, cgProcedure *> map_set_procs;

	RecursiveMutex map_info_mutex;
	PtrMap<Type *, TB_Symbol *> map_info_map;
	PtrMap<Type *, TB_Symbol *> map_cell_info_map;

	// NOTE(bill): no need to protect this with a mutex
	PtrMap<uintptr, TB_SourceFile *> file_id_map; // Key: AstFile.id (i32 cast to uintptr)

	std::atomic<u32> nested_type_name_guid;
	std::atomic<u32> const_nil_guid;
};

#ifndef ABI_PKG_NAME_SEPARATOR
#define ABI_PKG_NAME_SEPARATOR "@"
#endif

struct GlobalTypeInfoData {
	TB_Global *global;
	Type *     array_type;
	Type *     elem_type;
	isize      index;
};

gb_global Entity *cg_global_type_info_data_entity   = {};
gb_global GlobalTypeInfoData cg_global_type_info_member_types       = {};
gb_global GlobalTypeInfoData cg_global_type_info_member_names       = {};
gb_global GlobalTypeInfoData cg_global_type_info_member_offsets     = {};
gb_global GlobalTypeInfoData cg_global_type_info_member_usings      = {};
gb_global GlobalTypeInfoData cg_global_type_info_member_tags        = {};
gb_global GlobalTypeInfoData cg_global_type_info_member_enum_values = {};

gb_global cgProcedure *cg_startup_runtime_proc = nullptr;
gb_global cgProcedure *cg_cleanup_runtime_proc = nullptr;



gb_internal TB_Arena *cg_arena(void);

gb_internal cgProcedure *cg_procedure_create(cgModule *m, Entity *entity, bool ignore_body=false);
gb_internal void cg_add_procedure_to_queue(cgProcedure *p);
gb_internal void cg_setup_type_info_data(cgModule *m);
gb_internal cgProcedure *cg_procedure_generate_anonymous(cgModule *m, Ast *expr, cgProcedure *parent);

gb_internal isize cg_global_const_calculate_region_count(ExactValue const &value, Type *type);
gb_internal i64   cg_global_const_calculate_region_count_from_basic_type(Type *type);
gb_internal bool  cg_global_const_add_region(cgModule *m, ExactValue const &value, Type *type, TB_Global *global, i64 offset);

gb_internal String cg_get_entity_name(cgModule *m, Entity *e);

gb_internal cgValue cg_value(TB_Global *  g,    Type *type);
gb_internal cgValue cg_value(TB_External *e,    Type *type);
gb_internal cgValue cg_value(TB_Function *f,    Type *type);
gb_internal cgValue cg_value(TB_Symbol *  s,    Type *type);
gb_internal cgValue cg_value(TB_Node *    node, Type *type);

gb_internal cgAddr cg_addr(cgValue const &value);
gb_internal cgAddr cg_addr_map(cgValue addr, cgValue map_key, Type *map_type, Type *map_result);

gb_internal u64 cg_typeid_as_u64(cgModule *m, Type *type);
gb_internal cgValue cg_type_info(cgProcedure *p, Type *type);
gb_internal isize cg_type_info_index(CheckerInfo *info, Type *type, bool err_on_not_found=true);

gb_internal cgValue cg_const_value(cgProcedure *p, Type *type, ExactValue const &value);
gb_internal cgValue cg_const_nil(cgProcedure *p, Type *type);

gb_internal cgValue cg_flatten_value(cgProcedure *p, cgValue value);

gb_internal void cg_build_stmt(cgProcedure *p, Ast *stmt);
gb_internal void cg_build_stmt_list(cgProcedure *p, Slice<Ast *> const &stmts);
gb_internal void cg_build_when_stmt(cgProcedure *p, AstWhenStmt *ws);


gb_internal cgValue cg_build_expr(cgProcedure *p, Ast *expr);
gb_internal cgAddr  cg_build_addr(cgProcedure *p, Ast *expr);
gb_internal cgValue cg_build_addr_ptr(cgProcedure *p, Ast *expr);
gb_internal cgValue cg_build_cond(cgProcedure *p, Ast *cond, TB_Node *true_block, TB_Node *false_block);

gb_internal Type *  cg_addr_type(cgAddr const &addr);
gb_internal cgValue cg_addr_load(cgProcedure *p, cgAddr addr);
gb_internal void    cg_addr_store(cgProcedure *p, cgAddr addr, cgValue value);
gb_internal cgValue cg_addr_get_ptr(cgProcedure *p, cgAddr const &addr);

gb_internal cgValue cg_emit_load(cgProcedure *p, cgValue const &ptr, bool is_volatile=false);
gb_internal void    cg_emit_store(cgProcedure *p, cgValue dst, cgValue src, bool is_volatile=false);

gb_internal cgAddr  cg_add_local (cgProcedure *p, Type *type, Entity *e, bool zero_init);
gb_internal cgAddr  cg_add_global(cgProcedure *p, Type *type, Entity *e);
gb_internal cgValue cg_address_from_load_or_generate_local(cgProcedure *p, cgValue value);
gb_internal cgValue cg_copy_value_to_ptr(cgProcedure *p, cgValue value, Type *original_type, isize min_alignment);

gb_internal cgValue cg_build_call_expr(cgProcedure *p, Ast *expr);

gb_internal void cg_build_return_stmt(cgProcedure *p, Slice<Ast *> const &return_results);
gb_internal void cg_build_return_stmt_internal(cgProcedure *p, Slice<cgValue> const &results);
gb_internal void cg_build_return_stmt_internal_single(cgProcedure *p, cgValue result);
gb_internal void cg_build_range_stmt(cgProcedure *p, Ast *node);

gb_internal cgValue cg_find_value_from_entity(cgModule *m, Entity *e);
gb_internal cgValue cg_find_procedure_value_from_entity(cgModule *m, Entity *e);

gb_internal TB_DebugType *cg_debug_type(cgModule *m, Type *type);

gb_internal String cg_get_entity_name(cgModule *m, Entity *e);

gb_internal cgValue cg_typeid(cgProcedure *m, Type *t);

gb_internal cgValue cg_emit_ptr_offset(cgProcedure *p, cgValue ptr, cgValue index);
gb_internal cgValue cg_emit_array_ep(cgProcedure *p, cgValue s, cgValue index);
gb_internal cgValue cg_emit_array_epi(cgProcedure *p, cgValue s, i64 index);
gb_internal cgValue cg_emit_struct_ep(cgProcedure *p, cgValue s, i64 index);
gb_internal cgValue cg_emit_deep_field_gep(cgProcedure *p, cgValue e, Selection const &sel);
gb_internal cgValue cg_emit_struct_ev(cgProcedure *p, cgValue s, i64 index);

gb_internal cgValue cg_emit_conv(cgProcedure *p, cgValue value, Type *t);
gb_internal cgValue cg_emit_comp_against_nil(cgProcedure *p, TokenKind op_kind, cgValue x);
gb_internal cgValue cg_emit_comp(cgProcedure *p, TokenKind op_kind, cgValue left, cgValue right);
gb_internal cgValue cg_emit_arith(cgProcedure *p, TokenKind op, cgValue lhs, cgValue rhs, Type *type);
gb_internal cgValue cg_emit_unary_arith(cgProcedure *p, TokenKind op, cgValue x, Type *type);
gb_internal void    cg_emit_increment(cgProcedure *p, cgValue addr);

gb_internal cgProcedure *cg_equal_proc_for_type (cgModule *m, Type *type);
gb_internal cgProcedure *cg_hasher_proc_for_type(cgModule *m, Type *type);
gb_internal cgValue     cg_hasher_proc_value_for_type(cgProcedure *p, Type *type);
gb_internal cgValue     cg_equal_proc_value_for_type(cgProcedure *p, Type *type);

gb_internal cgValue cg_emit_call(cgProcedure * p, cgValue value, Slice<cgValue> const &args);
gb_internal cgValue cg_emit_runtime_call(cgProcedure *p, char const *name, Slice<cgValue> const &args);

gb_internal bool    cg_emit_goto(cgProcedure *p, TB_Node *control_region);

gb_internal TB_Node *cg_control_region(cgProcedure *p, char const *name);

gb_internal isize cg_append_tuple_values(cgProcedure *p, Array<cgValue> *dst_values, cgValue src_value);

gb_internal cgValue cg_handle_param_value(cgProcedure *p, Type *parameter_type, ParameterValue const &param_value, TokenPos const &pos);

gb_internal cgValue cg_builtin_len(cgProcedure *p, cgValue value);
gb_internal cgValue cg_builtin_raw_data(cgProcedure *p, cgValue const &x);
gb_internal cgValue cg_builtin_map_info(cgProcedure *p, Type *map_type);
gb_internal cgValue cg_builtin_map_cell_info(cgProcedure *p, Type *type);
gb_internal cgValue cg_emit_source_code_location_as_global(cgProcedure *p, String const &proc_name, TokenPos pos);
gb_internal cgValue cg_emit_source_code_location_as_global(cgProcedure *p, Ast *node);


gb_internal cgValue cg_internal_dynamic_map_get_ptr(cgProcedure *p, cgValue const &map_ptr, cgValue const &key);
gb_internal void cg_internal_dynamic_map_set(cgProcedure *p, cgValue const &map_ptr, Type *map_type,
                                             cgValue const &map_key, cgValue const &map_value, Ast *node);