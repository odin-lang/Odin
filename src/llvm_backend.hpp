#if defined(GB_SYSTEM_WINDOWS)
#include <llvm-c/Config/llvm-config.h>
#else
#include <llvm/Config/llvm-config.h>
#endif

#include <llvm-c/Core.h>
#include <llvm-c/ExecutionEngine.h>
#include <llvm-c/Target.h>
#include <llvm-c/Analysis.h>
#include <llvm-c/Object.h>
#include <llvm-c/BitWriter.h>
#include <llvm-c/DebugInfo.h>
#if LLVM_VERSION_MAJOR >= 17
#include <llvm-c/Transforms/PassBuilder.h>
#else
#include <llvm-c/Transforms/AggressiveInstCombine.h>
#include <llvm-c/Transforms/InstCombine.h>
#include <llvm-c/Transforms/IPO.h>
#include <llvm-c/Transforms/PassManagerBuilder.h>
#include <llvm-c/Transforms/Scalar.h>
#include <llvm-c/Transforms/Utils.h>
#include <llvm-c/Transforms/Vectorize.h>
#endif

#if LLVM_VERSION_MAJOR < 11
#error "LLVM Version 11 is the minimum required"
#elif LLVM_VERSION_MAJOR == 12 && !(LLVM_VERSION_MINOR > 0 || LLVM_VERSION_PATCH > 0)
#error "If LLVM Version 12.x.y is wanted, at least LLVM 12.0.1 is required"
#endif

#if LLVM_VERSION_MAJOR > 12 || (LLVM_VERSION_MAJOR == 12 && LLVM_VERSION_MINOR >= 0 && LLVM_VERSION_PATCH > 0)
#define ODIN_LLVM_MINIMUM_VERSION_12 1
#else
#define ODIN_LLVM_MINIMUM_VERSION_12 0
#endif

#if LLVM_VERSION_MAJOR > 13 || (LLVM_VERSION_MAJOR == 13 && LLVM_VERSION_MINOR >= 0 && LLVM_VERSION_PATCH > 0)
#define ODIN_LLVM_MINIMUM_VERSION_13 1
#else
#define ODIN_LLVM_MINIMUM_VERSION_13 0
#endif

#if LLVM_VERSION_MAJOR > 14 || (LLVM_VERSION_MAJOR == 14 && LLVM_VERSION_MINOR >= 0 && LLVM_VERSION_PATCH > 0)
#define ODIN_LLVM_MINIMUM_VERSION_14 1
#else
#define ODIN_LLVM_MINIMUM_VERSION_14 0
#endif

#if LLVM_VERSION_MAJOR == 15 || LLVM_VERSION_MAJOR == 16
#error "LLVM versions 15 and 16 are not supported"
#endif

#if LLVM_VERSION_MAJOR >= 17
#define LB_USE_NEW_PASS_SYSTEM 1
#else
#define LB_USE_NEW_PASS_SYSTEM 0
#endif

#if LLVM_VERSION_MAJOR >= 19
#define LLVMDIBuilderInsertDeclareAtEnd(...) LLVMDIBuilderInsertDeclareRecordAtEnd(__VA_ARGS__)
#endif

gb_internal bool lb_use_new_pass_system(void) {
	return LB_USE_NEW_PASS_SYSTEM;
}

struct lbProcedure;

struct lbValue {
	LLVMValueRef value;
	Type *type;
};


enum lbAddrKind {
	lbAddr_Default,
	lbAddr_Map,
	lbAddr_Context,
	lbAddr_SoaVariable,


	lbAddr_Swizzle,
	lbAddr_SwizzleLarge,

	lbAddr_BitField,
};

struct lbAddr {
	lbAddrKind kind;
	lbValue addr;
	union {
		struct {
			lbValue key;
			Type *type;
			Type *result;
		} map;
		struct {
			Selection sel;
		} ctx;
		struct {
			lbValue index;
			Ast *index_expr;
		} soa;
		struct {
			lbValue index;
			Ast *node;
		} index_set;
		struct {
			Type *type;
			u8 count;      // 2, 3, or 4 components
			u8 indices[4];
		} swizzle;
		struct {
			Type *type;
			Slice<i32> indices;
		} swizzle_large;
		struct {
			Type *type;
			i64 bit_offset;
			i64 bit_size;
		} bitfield;
	};
};

struct lbIncompleteDebugType {
	Type *type;
	LLVMMetadataRef metadata;
};

typedef Slice<i32> lbStructFieldRemapping;

enum lbFunctionPassManagerKind {
	lbFunctionPassManager_default,
	lbFunctionPassManager_default_without_memcpy,
	lbFunctionPassManager_none,
	lbFunctionPassManager_COUNT
};

struct lbPadType {
	i64 padding;
	i64 padding_align;
	LLVMTypeRef type;
};

struct lbModule {
	LLVMModuleRef mod;
	LLVMContextRef ctx;

	struct lbGenerator *gen;
	LLVMTargetMachineRef target_machine;

	CheckerInfo *info;
	AstPackage *pkg; // possibly associated
	AstFile *file;   // possibly associated
	char const *module_name;

	PtrMap<u64/*type hash*/, LLVMTypeRef>  types;                  // mutex: types_mutex
	PtrMap<void *, lbStructFieldRemapping> struct_field_remapping; // Key: LLVMTypeRef or Type *, mutex: types_mutex
	PtrMap<u64/*type hash*/, LLVMTypeRef>  func_raw_types;         // mutex: func_raw_types_mutex
	RecursiveMutex types_mutex;
	RecursiveMutex func_raw_types_mutex;
	i32 internal_type_level;

	RwMutex values_mutex;

	std::atomic<u32> global_array_index;

	PtrMap<Entity *, lbValue> values;           
	PtrMap<Entity *, lbAddr>  soa_values;       
	StringMap<lbValue>  members;
	StringMap<lbProcedure *> procedures;
	PtrMap<LLVMValueRef, Entity *> procedure_values;
	Array<lbProcedure *> missing_procedures_to_check;

	StringMap<LLVMValueRef> const_strings;

	PtrMap<u64/*type hash*/, struct lbFunctionType *> function_type_map;

	StringMap<lbProcedure *> gen_procs;   // key is the canonicalized name

	Array<lbProcedure *> procedures_to_generate;
	Array<Entity *> global_procedures_to_create;
	Array<Entity *> global_types_to_create;

	lbProcedure *curr_procedure;

	LLVMBuilderRef const_dummy_builder;

	LLVMDIBuilderRef debug_builder;
	LLVMMetadataRef debug_compile_unit;

	RecursiveMutex debug_values_mutex;
	PtrMap<void *, LLVMMetadataRef> debug_values; 


	StringMap<lbAddr> objc_classes;
	StringMap<lbAddr> objc_selectors;

	PtrMap<u64/*type hash*/, lbAddr> map_cell_info_map; // address of runtime.Map_Info
	PtrMap<u64/*type hash*/, lbAddr> map_info_map;      // address of runtime.Map_Cell_Info

	PtrMap<Ast *, lbAddr> exact_value_compound_literal_addr_map; // Key: Ast_CompoundLit

	LLVMPassManagerRef function_pass_managers[lbFunctionPassManager_COUNT];

	BlockingMutex pad_types_mutex;
	Array<lbPadType> pad_types;
};

struct lbEntityCorrection {
	lbModule *  other_module;
	Entity *    e;
	char const *cname;
};

struct lbObjCGlobal {
	lbModule *module;
	gbString  global_name;
	String    name;
	Type *    type;
};

struct lbGenerator : LinkerData {
	CheckerInfo *info;

	PtrMap<void *, lbModule *> modules; // key is `AstPackage *` (`void *` is used for future use)
	PtrMap<LLVMContextRef, lbModule *> modules_through_ctx; 
	lbModule default_module;

	RecursiveMutex anonymous_proc_lits_mutex;
	PtrMap<Ast *, lbProcedure *> anonymous_proc_lits; 

	isize used_module_count;

	lbProcedure *startup_runtime;
	lbProcedure *cleanup_runtime;
	lbProcedure *objc_names;

	MPSCQueue<lbEntityCorrection> entities_to_correct_linkage;
	MPSCQueue<lbObjCGlobal> objc_selectors;
	MPSCQueue<lbObjCGlobal> objc_classes;
};


struct lbBlock {
	LLVMBasicBlockRef block;
	Scope *scope;
	isize scope_index;
	bool appended;

	Array<lbBlock *> preds;
	Array<lbBlock *> succs;
};

struct lbBranchBlocks {
	Ast *label;
	lbBlock *break_;
	lbBlock *continue_;
};


struct lbContextData {
	lbAddr ctx;
	isize scope_index;
	isize uses;
};

enum lbParamPasskind {
	lbParamPass_Value,    // Pass by value
	lbParamPass_Pointer,  // Pass as a pointer rather than by value
	lbParamPass_Integer,  // Pass as an integer of the same size
	lbParamPass_ConstRef, // Pass as a pointer but the value is immutable
	lbParamPass_BitCast,  // Pass by value and bit cast to the correct type
	lbParamPass_Tuple,    // Pass across multiple parameters (System V AMD64, up to 2)
};

enum lbDeferExitKind {
	lbDeferExit_Default,
	lbDeferExit_Return,
	lbDeferExit_Branch,
};

enum lbDeferKind {
	lbDefer_Node,
	lbDefer_Proc,
};

struct lbDefer {
	lbDeferKind kind;
	isize       scope_index;
	isize       context_stack_count;
	lbBlock *   block;
	union {
		Ast *stmt;
		struct {
			lbValue deferred;
			Array<lbValue> result_as_args;
		} proc;
	};
};

struct lbTargetList {
	lbTargetList *prev;
	bool          is_block;
	lbBlock *     break_;
	lbBlock *     continue_;
	lbBlock *     fallthrough_;
};


struct lbTupleFix {
	Slice<lbValue> values;
};

enum lbProcedureFlag : u32 {
	lbProcedureFlag_WithoutMemcpyPass = 1<<0,
	lbProcedureFlag_DebugAllocaCopy = 1<<1,
};

struct lbVariadicReuseSlices {
	Type *slice_type;
	lbAddr slice_addr;
};

struct lbProcedure {
	u32 flags;
	u16 state_flags;

	lbProcedure *parent;
	Array<lbProcedure *> children;

	Entity *     entity;
	lbModule *   module;
	String       name;
	Type *       type;
	Ast *        type_expr;
	Ast *        body;
	u64          tags;
	ProcInlining inlining;
	bool         is_foreign;
	bool         is_export;
	bool         is_entry_point;
	bool         is_startup;

	lbFunctionType *abi_function_type;

	LLVMValueRef    value;
	LLVMBuilderRef  builder;
	bool            is_done;

	lbAddr           return_ptr;
	Array<lbDefer>   defer_stmts;
	Array<lbBlock *> blocks;
	Array<lbBranchBlocks> branch_blocks;
	Scope *          curr_scope;
	i32              scope_index;
	lbBlock *        decl_block;
	lbBlock *        entry_block;
	lbBlock *        curr_block;
	lbTargetList *   target_list;
	PtrMap<Entity *, lbValue> direct_parameters;
	bool             in_multi_assignment;
	Array<LLVMValueRef> raw_input_parameters;

	u32 global_generated_index;

	bool             uses_branch_location;
	TokenPos         branch_location_pos;
	TokenPos         curr_token_pos;

	Array<lbVariadicReuseSlices> variadic_reuses;
	lbAddr variadic_reuse_base_array_ptr;

	LLVMValueRef temp_callee_return_struct_memory;
	Ast *curr_stmt;

	Array<Scope *>       scope_stack;
	Array<lbContextData> context_stack;

	LLVMMetadataRef debug_info;

	PtrMap<Ast *, lbValue> selector_values;
	PtrMap<Ast *, lbAddr>  selector_addr;
	PtrMap<LLVMValueRef, lbTupleFix> tuple_fix_map;
};


#ifndef ABI_PKG_NAME_SEPARATOR
#define ABI_PKG_NAME_SEPARATOR "."
#endif


#if !ODIN_LLVM_MINIMUM_VERSION_14
#define LLVMConstGEP2(Ty__, ConstantVal__, ConstantIndices__, NumIndices__) LLVMConstGEP(ConstantVal__, ConstantIndices__, NumIndices__)
#define LLVMConstInBoundsGEP2(Ty__, ConstantVal__, ConstantIndices__, NumIndices__) LLVMConstInBoundsGEP(ConstantVal__, ConstantIndices__, NumIndices__)
#define LLVMBuildPtrDiff2(Builder__, Ty__, LHS__, RHS__, Name__) LLVMBuildPtrDiff(Builder__, LHS__, RHS__, Name__)
#endif

gb_internal bool lb_init_generator(lbGenerator *gen, Checker *c);

gb_internal String lb_mangle_name(Entity *e);
gb_internal String lb_get_entity_name(lbModule *m, Entity *e);

gb_internal LLVMAttributeRef lb_create_enum_attribute(LLVMContextRef ctx, char const *name, u64 value=0);
gb_internal LLVMAttributeRef lb_create_enum_attribute_with_type(LLVMContextRef ctx, char const *name, LLVMTypeRef type);
gb_internal void lb_add_proc_attribute_at_index(lbProcedure *p, isize index, char const *name, u64 value);
gb_internal void lb_add_proc_attribute_at_index(lbProcedure *p, isize index, char const *name);
gb_internal lbProcedure *lb_create_procedure(lbModule *module, Entity *entity, bool ignore_body=false);
gb_internal void lb_end_procedure(lbProcedure *p);


gb_internal LLVMTypeRef lb_type(lbModule *m, Type *type);
gb_internal LLVMTypeRef llvm_get_element_type(LLVMTypeRef type);

gb_internal lbBlock *lb_create_block(lbProcedure *p, char const *name, bool append=false);

gb_internal lbValue lb_const_nil(lbModule *m, Type *type);
gb_internal lbValue lb_const_undef(lbModule *m, Type *type);
gb_internal lbValue lb_const_value(lbModule *m, Type *type, ExactValue value, bool allow_local=true, bool is_rodata=false);
gb_internal lbValue lb_const_bool(lbModule *m, Type *type, bool value);
gb_internal lbValue lb_const_int(lbModule *m, Type *type, u64 value);


gb_internal lbAddr lb_addr(lbValue addr);
gb_internal Type *lb_addr_type(lbAddr const &addr);
gb_internal LLVMTypeRef llvm_addr_type(lbModule *module, lbValue addr_val);
gb_internal void lb_addr_store(lbProcedure *p, lbAddr addr, lbValue value);
gb_internal lbValue lb_addr_load(lbProcedure *p, lbAddr const &addr);
gb_internal lbValue lb_emit_load(lbProcedure *p, lbValue v);
gb_internal void lb_emit_store(lbProcedure *p, lbValue ptr, lbValue value);


gb_internal void    lb_build_stmt(lbProcedure *p, Ast *stmt);
gb_internal lbValue lb_build_expr(lbProcedure *p, Ast *expr);
gb_internal lbAddr  lb_build_addr(lbProcedure *p, Ast *expr);
gb_internal void lb_build_stmt_list(lbProcedure *p, Array<Ast *> const &stmts);

gb_internal lbValue lb_emit_epi(lbProcedure *p, lbValue const &value, isize index);
gb_internal lbValue lb_emit_epi(lbModule *m, lbValue const &value, isize index);
gb_internal lbValue lb_emit_array_epi(lbModule *m, lbValue s, isize index);
gb_internal lbValue lb_emit_struct_ep(lbProcedure *p, lbValue s, i32 index);
gb_internal lbValue lb_emit_struct_ev(lbProcedure *p, lbValue s, i32 index);
gb_internal lbValue lb_emit_tuple_ev(lbProcedure *p, lbValue value, i32 index);
gb_internal lbValue lb_emit_array_epi(lbProcedure *p, lbValue value, isize index);
gb_internal lbValue lb_emit_array_ep(lbProcedure *p, lbValue s, lbValue index);
gb_internal lbValue lb_emit_deep_field_gep(lbProcedure *p, lbValue e, Selection sel);
gb_internal lbValue lb_emit_deep_field_ev(lbProcedure *p, lbValue e, Selection sel);

gb_internal lbValue lb_emit_matrix_ep(lbProcedure *p, lbValue s, lbValue row, lbValue column);
gb_internal lbValue lb_emit_matrix_epi(lbProcedure *p, lbValue s, isize row, isize column);
gb_internal lbValue lb_emit_matrix_ev(lbProcedure *p, lbValue s, isize row, isize column);


gb_internal lbValue lb_emit_arith(lbProcedure *p, TokenKind op, lbValue lhs, lbValue rhs, Type *type);
gb_internal lbValue lb_emit_byte_swap(lbProcedure *p, lbValue value, Type *end_type);
gb_internal void lb_emit_defer_stmts(lbProcedure *p, lbDeferExitKind kind, lbBlock *block, TokenPos pos);
gb_internal void lb_emit_defer_stmts(lbProcedure *p, lbDeferExitKind kind, lbBlock *block, Ast *node);
gb_internal lbValue lb_emit_transmute(lbProcedure *p, lbValue value, Type *t);
gb_internal lbValue lb_emit_comp(lbProcedure *p, TokenKind op_kind, lbValue left, lbValue right);
gb_internal lbValue lb_emit_call(lbProcedure *p, lbValue value, Array<lbValue> const &args, ProcInlining inlining = ProcInlining_none);
gb_internal lbValue lb_emit_conv(lbProcedure *p, lbValue value, Type *t);
gb_internal lbValue lb_emit_comp_against_nil(lbProcedure *p, TokenKind op_kind, lbValue x);

gb_internal void lb_emit_jump(lbProcedure *p, lbBlock *target_block);
gb_internal void lb_emit_if(lbProcedure *p, lbValue cond, lbBlock *true_block, lbBlock *false_block);
gb_internal void lb_start_block(lbProcedure *p, lbBlock *b);

gb_internal lbValue lb_build_call_expr(lbProcedure *p, Ast *expr);


gb_internal lbAddr lb_find_or_generate_context_ptr(lbProcedure *p);
gb_internal lbContextData *lb_push_context_onto_stack(lbProcedure *p, lbAddr ctx);
gb_internal lbContextData *lb_push_context_onto_stack_from_implicit_parameter(lbProcedure *p);


gb_internal lbAddr lb_add_global_generated_from_procedure(lbProcedure *p, Type *type, lbValue value={});
gb_internal lbAddr lb_add_global_generated_with_name(lbModule *m, Type *type, lbValue value, String name, Entity **entity_=nullptr);
gb_internal lbAddr lb_add_local(lbProcedure *p, Type *type, Entity *e=nullptr, bool zero_init=true, bool force_no_init=false);

gb_internal void lb_add_foreign_library_path(lbModule *m, Entity *e);

gb_internal lbValue lb_typeid(lbModule *m, Type *type);

gb_internal lbValue lb_address_from_load_or_generate_local(lbProcedure *p, lbValue value);
gb_internal lbValue lb_address_from_load(lbProcedure *p, lbValue value);
gb_internal void    lb_add_defer_node(lbProcedure *p, isize scope_index, Ast *stmt);
gb_internal lbAddr lb_add_local_generated(lbProcedure *p, Type *type, bool zero_init);

gb_internal lbValue lb_emit_runtime_call(lbProcedure *p, char const *c_name, Array<lbValue> const &args);


gb_internal lbValue lb_emit_ptr_offset(lbProcedure *p, lbValue ptr, lbValue index);
gb_internal lbValue lb_const_ptr_offset(lbModule *m, lbValue ptr, lbValue index);
gb_internal lbValue lb_string_elem(lbProcedure *p, lbValue string);
gb_internal lbValue lb_string_len(lbProcedure *p, lbValue string);
gb_internal lbValue lb_cstring_len(lbProcedure *p, lbValue value);
gb_internal lbValue lb_array_elem(lbProcedure *p, lbValue array_ptr);
gb_internal lbValue lb_slice_elem(lbProcedure *p, lbValue slice);
gb_internal lbValue lb_slice_len(lbProcedure *p, lbValue slice);
gb_internal lbValue lb_dynamic_array_elem(lbProcedure *p, lbValue da);
gb_internal lbValue lb_dynamic_array_len(lbProcedure *p, lbValue da);
gb_internal lbValue lb_dynamic_array_cap(lbProcedure *p, lbValue da);
gb_internal lbValue lb_dynamic_array_allocator(lbProcedure *p, lbValue da);
gb_internal lbValue lb_map_len(lbProcedure *p, lbValue value);
gb_internal lbValue lb_map_cap(lbProcedure *p, lbValue value);
gb_internal lbValue lb_soa_struct_len(lbProcedure *p, lbValue value);
gb_internal void lb_emit_increment(lbProcedure *p, lbValue addr);
gb_internal lbValue lb_emit_select(lbProcedure *p, lbValue cond, lbValue x, lbValue y);

gb_internal lbValue lb_emit_mul_add(lbProcedure *p, lbValue a, lbValue b, lbValue c, Type *t);

gb_internal void lb_fill_slice(lbProcedure *p, lbAddr const &slice, lbValue base_elem, lbValue len);

gb_internal lbValue lb_type_info(lbProcedure *p, Type *type);

gb_internal lbValue lb_find_or_add_entity_string(lbModule *m, String const &str);
gb_internal lbValue lb_generate_anonymous_proc_lit(lbModule *m, String const &prefix_name, Ast *expr, lbProcedure *parent = nullptr);

gb_internal bool lb_is_const(lbValue value);
gb_internal bool lb_is_const_or_global(lbValue value);
gb_internal bool lb_is_const_nil(lbValue value);
gb_internal String lb_get_const_string(lbModule *m, lbValue value);

gb_internal lbValue lb_generate_local_array(lbProcedure *p, Type *elem_type, i64 count, bool zero_init=true);
gb_internal lbValue lb_generate_global_array(lbModule *m, Type *elem_type, i64 count, String prefix, i64 id);
gb_internal lbValue lb_gen_map_key_hash(lbProcedure *p, lbValue const &map_ptr, lbValue key, lbValue *key_ptr_);
gb_internal lbValue lb_gen_map_cell_info_ptr(lbModule *m, Type *type);
gb_internal lbValue lb_gen_map_info_ptr(lbModule *m, Type *map_type);

gb_internal lbValue lb_internal_dynamic_map_get_ptr(lbProcedure *p, lbValue const &map_ptr, lbValue const &key);
gb_internal void    lb_internal_dynamic_map_set(lbProcedure *p, lbValue const &map_ptr, Type *map_type, lbValue const &map_key, lbValue const &map_value, Ast *node);
gb_internal lbValue lb_dynamic_map_reserve(lbProcedure *p, lbValue const &map_ptr, isize const capacity, TokenPos const &pos);

gb_internal lbValue lb_find_procedure_value_from_entity(lbModule *m, Entity *e);
gb_internal lbValue lb_find_value_from_entity(lbModule *m, Entity *e);

gb_internal void lb_store_type_case_implicit(lbProcedure *p, Ast *clause, lbValue value, bool is_default_case);
gb_internal lbAddr lb_store_range_stmt_val(lbProcedure *p, Ast *stmt_val, lbValue value);
gb_internal lbValue lb_emit_source_code_location_const(lbProcedure *p, String const &procedure, TokenPos const &pos);
gb_internal lbValue lb_const_source_code_location_const(lbModule *m, String const &procedure, TokenPos const &pos);

gb_internal lbValue lb_handle_param_value(lbProcedure *p, Type *parameter_type, ParameterValue const &param_value, TypeProc *procedure_type, Ast *call_expression);

gb_internal lbValue lb_equal_proc_for_type(lbModule *m, Type *type);
gb_internal lbValue lb_hasher_proc_for_type(lbModule *m, Type *type);
gb_internal lbValue lb_emit_conv(lbProcedure *p, lbValue value, Type *t);

gb_internal LLVMMetadataRef lb_debug_type(lbModule *m, Type *type);

gb_internal lbValue lb_emit_count_ones(lbProcedure *p, lbValue x, Type *type);
gb_internal lbValue lb_emit_count_zeros(lbProcedure *p, lbValue x, Type *type);
gb_internal lbValue lb_emit_count_trailing_zeros(lbProcedure *p, lbValue x, Type *type);
gb_internal lbValue lb_emit_count_leading_zeros(lbProcedure *p, lbValue x, Type *type);
gb_internal lbValue lb_emit_reverse_bits(lbProcedure *p, lbValue x, Type *type);

gb_internal lbValue lb_emit_bit_set_card(lbProcedure *p, lbValue x);

gb_internal void lb_mem_zero_addr(lbProcedure *p, LLVMValueRef ptr, Type *type);

gb_internal void lb_build_nested_proc(lbProcedure *p, AstProcLit *pd, Entity *e);
gb_internal lbValue lb_emit_logical_binary_expr(lbProcedure *p, TokenKind op, Ast *left, Ast *right, Type *type);
gb_internal lbValue lb_build_cond(lbProcedure *p, Ast *cond, lbBlock *true_block, lbBlock *false_block);

gb_internal LLVMValueRef llvm_const_named_struct(lbModule *m, Type *t, LLVMValueRef *values, isize value_count_);
gb_internal LLVMValueRef llvm_const_named_struct_internal(LLVMTypeRef t, LLVMValueRef *values, isize value_count_);
gb_internal void lb_set_entity_from_other_modules_linkage_correctly(lbModule *other_module, Entity *e, String const &name);

gb_internal lbValue lb_expr_untyped_const_to_typed(lbModule *m, Ast *expr, Type *t);
gb_internal bool lb_is_expr_untyped_const(Ast *expr);

gb_internal LLVMValueRef llvm_alloca(lbProcedure *p, LLVMTypeRef llvm_type, isize alignment, char const *name = "");

gb_internal void lb_mem_zero_ptr(lbProcedure *p, LLVMValueRef ptr, Type *type, unsigned alignment);

gb_internal void lb_emit_init_context(lbProcedure *p, lbAddr addr);

gb_internal lbBranchBlocks lb_lookup_branch_blocks(lbProcedure *p, Ast *ident);

gb_internal lbStructFieldRemapping lb_get_struct_remapping(lbModule *m, Type *t);
gb_internal LLVMTypeRef lb_type_padding_filler(lbModule *m, i64 padding, i64 padding_align);

gb_internal LLVMValueRef llvm_basic_shuffle(lbProcedure *p, LLVMValueRef vector, LLVMValueRef mask);

gb_internal LLVMValueRef lb_call_intrinsic(lbProcedure *p, const char *name, LLVMValueRef* args, unsigned arg_count, LLVMTypeRef* types, unsigned type_count);
gb_internal void lb_mem_copy_overlapping(lbProcedure *p, lbValue dst, lbValue src, lbValue len, bool is_volatile=false);
gb_internal void lb_mem_copy_non_overlapping(lbProcedure *p, lbValue dst, lbValue src, lbValue len, bool is_volatile=false);
gb_internal LLVMValueRef lb_mem_zero_ptr_internal(lbProcedure *p, LLVMValueRef ptr, LLVMValueRef len, unsigned alignment, bool is_volatile);
gb_internal LLVMValueRef lb_mem_zero_ptr_internal(lbProcedure *p, LLVMValueRef ptr, usize len, unsigned alignment, bool is_volatile);

gb_internal gb_inline i64 lb_max_zero_init_size(void) {
	return cast(i64)(4*build_context.int_size);
}

gb_internal LLVMTypeRef OdinLLVMGetArrayElementType(LLVMTypeRef type);
gb_internal LLVMTypeRef OdinLLVMGetVectorElementType(LLVMTypeRef type);

gb_internal String lb_filepath_ll_for_module(lbModule *m);

gb_internal LLVMTypeRef lb_type_internal_for_procedures_raw(lbModule *m, Type *type);

gb_internal lbValue lb_emit_source_code_location_as_global_ptr(lbProcedure *p, String const &procedure, TokenPos const &pos);

gb_internal LLVMMetadataRef lb_debug_location_from_token_pos(lbProcedure *p, TokenPos pos);

gb_internal LLVMTypeRef llvm_array_type(LLVMTypeRef ElementType, uint64_t ElementCount) {
#if LB_USE_NEW_PASS_SYSTEM
	return LLVMArrayType2(ElementType, ElementCount);
#else
	return LLVMArrayType(ElementType, cast(unsigned)ElementCount);
#endif
}


gb_internal String lb_internal_gen_name_from_type(char const *prefix, Type *type);


gb_internal void lb_set_metadata_custom_u64(lbModule *m, LLVMValueRef v_ref, String name, u64 value);
gb_internal u64 lb_get_metadata_custom_u64(lbModule *m, LLVMValueRef v_ref, String name);

#define LB_STARTUP_RUNTIME_PROC_NAME   "__$startup_runtime"
#define LB_CLEANUP_RUNTIME_PROC_NAME   "__$cleanup_runtime"
#define LB_TYPE_INFO_DATA_NAME       "__$type_info_data"
#define LB_TYPE_INFO_TYPES_NAME      "__$type_info_types_data"
#define LB_TYPE_INFO_NAMES_NAME      "__$type_info_names_data"
#define LB_TYPE_INFO_OFFSETS_NAME    "__$type_info_offsets_data"
#define LB_TYPE_INFO_USINGS_NAME     "__$type_info_usings_data"
#define LB_TYPE_INFO_TAGS_NAME       "__$type_info_tags_data"



enum lbCallingConventionKind : unsigned {
	lbCallingConvention_C = 0,
	lbCallingConvention_Fast = 8,
	lbCallingConvention_Cold = 9,
	lbCallingConvention_GHC = 10,
	lbCallingConvention_HiPE = 11,
	lbCallingConvention_WebKit_JS = 12,
	lbCallingConvention_AnyReg = 13,
	lbCallingConvention_PreserveMost = 14,
	lbCallingConvention_PreserveAll = 15,
	lbCallingConvention_Swift = 16,
	lbCallingConvention_CXX_FAST_TLS = 17,
	lbCallingConvention_FirstTargetCC = 64,
	lbCallingConvention_X86_StdCall = 64,
	lbCallingConvention_X86_FastCall = 65,
	lbCallingConvention_ARM_APCS = 66,
	lbCallingConvention_ARM_AAPCS = 67,
	lbCallingConvention_ARM_AAPCS_VFP = 68,
	lbCallingConvention_MSP430_INTR = 69,
	lbCallingConvention_X86_ThisCall = 70,
	lbCallingConvention_PTX_Kernel = 71,
	lbCallingConvention_PTX_Device = 72,
	lbCallingConvention_SPIR_FUNC = 75,
	lbCallingConvention_SPIR_KERNEL = 76,
	lbCallingConvention_Intel_OCL_BI = 77,
	lbCallingConvention_X86_64_SysV = 78,
	lbCallingConvention_Win64 = 79,
	lbCallingConvention_X86_VectorCall = 80,
	lbCallingConvention_HHVM = 81,
	lbCallingConvention_HHVM_C = 82,
	lbCallingConvention_X86_INTR = 83,
	lbCallingConvention_AVR_INTR = 84,
	lbCallingConvention_AVR_SIGNAL = 85,
	lbCallingConvention_AVR_BUILTIN = 86,
	lbCallingConvention_AMDGPU_VS = 87,
	lbCallingConvention_AMDGPU_GS = 88,
	lbCallingConvention_AMDGPU_PS = 89,
	lbCallingConvention_AMDGPU_CS = 90,
	lbCallingConvention_AMDGPU_KERNEL = 91,
	lbCallingConvention_X86_RegCall = 92,
	lbCallingConvention_AMDGPU_HS = 93,
	lbCallingConvention_MSP430_BUILTIN = 94,
	lbCallingConvention_AMDGPU_LS = 95,
	lbCallingConvention_AMDGPU_ES = 96,
	lbCallingConvention_AArch64_VectorCall = 97,
	lbCallingConvention_AArch64_SVE_VectorCall = 98,
	lbCallingConvention_WASM_EmscriptenInvoke = 99,
	lbCallingConvention_MaxID = 1023,
};

lbCallingConventionKind const lb_calling_convention_map[ProcCC_MAX] = {
	lbCallingConvention_C,            // ProcCC_Invalid,
	lbCallingConvention_C,            // ProcCC_Odin,
	lbCallingConvention_C,            // ProcCC_Contextless,
	lbCallingConvention_C,            // ProcCC_CDecl,
	lbCallingConvention_X86_StdCall,  // ProcCC_StdCall,
	lbCallingConvention_X86_FastCall, // ProcCC_FastCall,

	lbCallingConvention_C,            // ProcCC_None,
	lbCallingConvention_C,            // ProcCC_Naked,
	lbCallingConvention_C,            // ProcCC_InlineAsm,

	lbCallingConvention_Win64,        // ProcCC_Win64,
	lbCallingConvention_X86_64_SysV,  // ProcCC_SysV,

};

enum : LLVMDWARFTypeEncoding {
	LLVMDWARFTypeEncoding_Address = 1,
	LLVMDWARFTypeEncoding_Boolean = 2,
	LLVMDWARFTypeEncoding_ComplexFloat = 3,
	LLVMDWARFTypeEncoding_Float = 4,
	LLVMDWARFTypeEncoding_Signed = 5,
	LLVMDWARFTypeEncoding_SignedChar = 6,
	LLVMDWARFTypeEncoding_Unsigned = 7,
	LLVMDWARFTypeEncoding_UnsignedChar = 8,
	LLVMDWARFTypeEncoding_ImaginaryFloat = 9,
	LLVMDWARFTypeEncoding_PackedDecimal = 10,
	LLVMDWARFTypeEncoding_NumericString = 11,
	LLVMDWARFTypeEncoding_Edited = 12,
	LLVMDWARFTypeEncoding_SignedFixed = 13,
	LLVMDWARFTypeEncoding_UnsignedFixed = 14,
	LLVMDWARFTypeEncoding_DecimalFloat = 15,
	LLVMDWARFTypeEncoding_Utf = 16,
	LLVMDWARFTypeEncoding_LoUser = 128,
	LLVMDWARFTypeEncoding_HiUser = 255
};


enum {
	DW_TAG_array_type       = 1,
	DW_TAG_enumeration_type = 4,
	DW_TAG_structure_type   = 19,
	DW_TAG_union_type       = 23,
	DW_TAG_vector_type      = 259,
	DW_TAG_subroutine_type  = 21,
	DW_TAG_inheritance      = 28,
};


enum : LLVMAttributeIndex {
	LLVMAttributeIndex_ReturnIndex = 0u,
	LLVMAttributeIndex_FunctionIndex = ~0u,
	LLVMAttributeIndex_FirstArgIndex = 1,
};


gb_global char const *llvm_linkage_strings[] = {
	"external linkage",
	"available externally linkage",
	"link once any linkage",
	"link once odr linkage",
	"link once odr auto hide linkage",
	"weak any linkage",
	"weak odr linkage",
	"appending linkage",
	"internal linkage",
	"private linkage",
	"dllimport linkage",
	"dllexport linkage",
	"external weak linkage",
	"ghost linkage",
	"common linkage",
	"linker private linkage",
	"linker private weak linkage"
};

#define ODIN_METADATA_IS_PACKED str_lit("odin-is-packed")
#define ODIN_METADATA_MIN_ALIGN str_lit("odin-min-align")
#define ODIN_METADATA_MAX_ALIGN str_lit("odin-max-align")
