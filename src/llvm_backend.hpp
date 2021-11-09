#if defined(GB_SYSTEM_WINDOWS)
#include "llvm-c/Core.h"
#include "llvm-c/ExecutionEngine.h"
#include "llvm-c/Target.h"
#include "llvm-c/Analysis.h"
#include "llvm-c/Object.h"
#include "llvm-c/BitWriter.h"
#include "llvm-c/DebugInfo.h"
#include "llvm-c/Transforms/AggressiveInstCombine.h"
#include "llvm-c/Transforms/InstCombine.h"
#include "llvm-c/Transforms/IPO.h"
#include "llvm-c/Transforms/PassManagerBuilder.h"
#include "llvm-c/Transforms/Scalar.h"
#include "llvm-c/Transforms/Utils.h"
#include "llvm-c/Transforms/Vectorize.h"
#else
#include <llvm-c/Core.h>
#include <llvm-c/ExecutionEngine.h>
#include <llvm-c/Target.h>
#include <llvm-c/Analysis.h>
#include <llvm-c/Object.h>
#include <llvm-c/BitWriter.h>
#include <llvm-c/DebugInfo.h>
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

	lbAddr_RelativePointer,
	lbAddr_RelativeSlice,

	lbAddr_Swizzle,
	lbAddr_SwizzleLarge,
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

struct lbIncompleteDebugType {
	Type *type;
	LLVMMetadataRef metadata;
};

typedef Slice<i32> lbStructFieldRemapping;

struct lbModule {
	LLVMModuleRef mod;
	LLVMContextRef ctx;

	struct lbGenerator *gen;

	CheckerInfo *info;
	AstPackage *pkg; // associated

	PtrMap<Type *, LLVMTypeRef> types;
	PtrMap<void *, lbStructFieldRemapping> struct_field_remapping; // Key: LLVMTypeRef or Type *
	i32 internal_type_level;

	PtrMap<Entity *, lbValue> values;           
	PtrMap<Entity *, lbAddr>  soa_values;       
	StringMap<lbValue>  members;
	StringMap<lbProcedure *> procedures;
	PtrMap<LLVMValueRef, Entity *> procedure_values;
	Array<lbProcedure *> missing_procedures_to_check;

	StringMap<LLVMValueRef> const_strings;

	PtrMap<Type *, struct lbFunctionType *> function_type_map; 

	PtrMap<Type *, lbProcedure *> equal_procs;
	PtrMap<Type *, lbProcedure *> hasher_procs;

	u32 nested_type_name_guid;

	Array<lbProcedure *> procedures_to_generate;
	Array<String> foreign_library_paths;

	lbProcedure *curr_procedure;

	LLVMDIBuilderRef debug_builder;
	LLVMMetadataRef debug_compile_unit;
	PtrMap<void *, LLVMMetadataRef> debug_values; 

	Array<lbIncompleteDebugType> debug_incomplete_types;
};

struct lbGenerator {
	CheckerInfo *info;

	Array<String> output_object_paths;
	Array<String> output_temp_paths;
	String   output_base;
	String   output_name;
	PtrMap<AstPackage *, lbModule *> modules; 
	PtrMap<LLVMContextRef, lbModule *> modules_through_ctx; 
	lbModule default_module;

	PtrMap<Ast *, lbProcedure *> anonymous_proc_lits; 

	std::atomic<u32> global_array_index;
	std::atomic<u32> global_generated_index;
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
	lbDefer_Instr,
	lbDefer_Proc,
};

struct lbDefer {
	lbDeferKind kind;
	isize       scope_index;
	isize       context_stack_count;
	lbBlock *   block;
	union {
		Ast *stmt;
		// NOTE(bill): 'instr' will be copied every time to create a new one
		lbValue instr;
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


enum lbProcedureFlag : u32 {
	lbProcedureFlag_WithoutMemcpyPass = 1<<0,
};

struct lbCopyElisionHint {
	lbValue ptr;
	Ast *   ast;
	bool    used;
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
	Array<lbValue>   params;
	Array<lbDefer>   defer_stmts;
	Array<lbBlock *> blocks;
	Array<lbBranchBlocks> branch_blocks;
	Scope *          curr_scope;
	i32              scope_index;
	lbBlock *        decl_block;
	lbBlock *        entry_block;
	lbBlock *        curr_block;
	lbTargetList *   target_list;

	Ast *curr_stmt;

	Array<Scope *>       scope_stack;
	Array<lbContextData> context_stack;

	LLVMMetadataRef debug_info;

	lbCopyElisionHint copy_elision_hint;
};





bool lb_init_generator(lbGenerator *gen, Checker *c);
void lb_generate_module(lbGenerator *gen);

String lb_mangle_name(lbModule *m, Entity *e);
String lb_get_entity_name(lbModule *m, Entity *e, String name = {});

LLVMAttributeRef lb_create_enum_attribute(LLVMContextRef ctx, char const *name, u64 value=0);
LLVMAttributeRef lb_create_enum_attribute_with_type(LLVMContextRef ctx, char const *name, LLVMTypeRef type);
void lb_add_proc_attribute_at_index(lbProcedure *p, isize index, char const *name, u64 value);
void lb_add_proc_attribute_at_index(lbProcedure *p, isize index, char const *name);
lbProcedure *lb_create_procedure(lbModule *module, Entity *entity, bool ignore_body=false);
void lb_end_procedure(lbProcedure *p);


LLVMTypeRef  lb_type(lbModule *m, Type *type);

lbBlock *lb_create_block(lbProcedure *p, char const *name, bool append=false);

lbValue lb_const_nil(lbModule *m, Type *type);
lbValue lb_const_undef(lbModule *m, Type *type);
lbValue lb_const_value(lbModule *m, Type *type, ExactValue value, bool allow_local=true);
lbValue lb_const_bool(lbModule *m, Type *type, bool value);
lbValue lb_const_int(lbModule *m, Type *type, u64 value);


lbAddr lb_addr(lbValue addr);
Type *lb_addr_type(lbAddr const &addr);
LLVMTypeRef lb_addr_lb_type(lbAddr const &addr);
void lb_addr_store(lbProcedure *p, lbAddr addr, lbValue value);
lbValue lb_addr_load(lbProcedure *p, lbAddr const &addr);
lbValue lb_emit_load(lbProcedure *p, lbValue v);
void lb_emit_store(lbProcedure *p, lbValue ptr, lbValue value);


void    lb_build_stmt(lbProcedure *p, Ast *stmt);
lbValue lb_build_expr(lbProcedure *p, Ast *expr);
lbAddr  lb_build_addr(lbProcedure *p, Ast *expr);
void lb_build_stmt_list(lbProcedure *p, Array<Ast *> const &stmts);

lbValue lb_build_gep(lbProcedure *p, lbValue const &value, i32 index) ;

lbValue lb_emit_struct_ep(lbProcedure *p, lbValue s, i32 index);
lbValue lb_emit_struct_ev(lbProcedure *p, lbValue s, i32 index);
lbValue lb_emit_array_epi(lbProcedure *p, lbValue value, isize index);
lbValue lb_emit_array_ep(lbProcedure *p, lbValue s, lbValue index);
lbValue lb_emit_deep_field_gep(lbProcedure *p, lbValue e, Selection sel);
lbValue lb_emit_deep_field_ev(lbProcedure *p, lbValue e, Selection sel);

lbValue lb_emit_matrix_ep(lbProcedure *p, lbValue s, lbValue row, lbValue column);
lbValue lb_emit_matrix_epi(lbProcedure *p, lbValue s, isize row, isize column);
lbValue lb_emit_matrix_ev(lbProcedure *p, lbValue s, isize row, isize column);


lbValue lb_emit_arith(lbProcedure *p, TokenKind op, lbValue lhs, lbValue rhs, Type *type);
lbValue lb_emit_byte_swap(lbProcedure *p, lbValue value, Type *end_type);
void lb_emit_defer_stmts(lbProcedure *p, lbDeferExitKind kind, lbBlock *block);
lbValue lb_emit_transmute(lbProcedure *p, lbValue value, Type *t);
lbValue lb_emit_comp(lbProcedure *p, TokenKind op_kind, lbValue left, lbValue right);
lbValue lb_emit_call(lbProcedure *p, lbValue value, Array<lbValue> const &args, ProcInlining inlining = ProcInlining_none, bool use_return_ptr_hint = false);
lbValue lb_emit_conv(lbProcedure *p, lbValue value, Type *t);
lbValue lb_emit_comp_against_nil(lbProcedure *p, TokenKind op_kind, lbValue x);

void lb_emit_jump(lbProcedure *p, lbBlock *target_block);
void lb_emit_if(lbProcedure *p, lbValue cond, lbBlock *true_block, lbBlock *false_block);
void lb_start_block(lbProcedure *p, lbBlock *b);

lbValue lb_build_call_expr(lbProcedure *p, Ast *expr);


lbAddr lb_find_or_generate_context_ptr(lbProcedure *p);
lbContextData *lb_push_context_onto_stack(lbProcedure *p, lbAddr ctx);
lbContextData *lb_push_context_onto_stack_from_implicit_parameter(lbProcedure *p);


lbAddr lb_add_global_generated(lbModule *m, Type *type, lbValue value={});
lbAddr lb_add_local(lbProcedure *p, Type *type, Entity *e=nullptr, bool zero_init=true, i32 param_index=0, bool force_no_init=false);

void lb_add_foreign_library_path(lbModule *m, Entity *e);

lbValue lb_typeid(lbModule *m, Type *type);

lbValue lb_address_from_load_or_generate_local(lbProcedure *p, lbValue value);
lbValue lb_address_from_load(lbProcedure *p, lbValue value);
void    lb_add_defer_node(lbProcedure *p, isize scope_index, Ast *stmt);
lbAddr lb_add_local_generated(lbProcedure *p, Type *type, bool zero_init);

lbValue lb_emit_runtime_call(lbProcedure *p, char const *c_name, Array<lbValue> const &args);


lbValue lb_emit_ptr_offset(lbProcedure *p, lbValue ptr, lbValue index);
lbValue lb_string_elem(lbProcedure *p, lbValue string);
lbValue lb_string_len(lbProcedure *p, lbValue string);
lbValue lb_cstring_len(lbProcedure *p, lbValue value);
lbValue lb_array_elem(lbProcedure *p, lbValue array_ptr);
lbValue lb_slice_elem(lbProcedure *p, lbValue slice);
lbValue lb_slice_len(lbProcedure *p, lbValue slice);
lbValue lb_dynamic_array_elem(lbProcedure *p, lbValue da);
lbValue lb_dynamic_array_len(lbProcedure *p, lbValue da);
lbValue lb_dynamic_array_cap(lbProcedure *p, lbValue da);
lbValue lb_dynamic_array_allocator(lbProcedure *p, lbValue da);
lbValue lb_map_entries(lbProcedure *p, lbValue value);
lbValue lb_map_entries_ptr(lbProcedure *p, lbValue value);
lbValue lb_map_len(lbProcedure *p, lbValue value);
lbValue lb_map_cap(lbProcedure *p, lbValue value);
lbValue lb_soa_struct_len(lbProcedure *p, lbValue value);
void lb_emit_increment(lbProcedure *p, lbValue addr);
lbValue lb_emit_select(lbProcedure *p, lbValue cond, lbValue x, lbValue y);

lbValue lb_emit_mul_add(lbProcedure *p, lbValue a, lbValue b, lbValue c, Type *t);

void lb_fill_slice(lbProcedure *p, lbAddr const &slice, lbValue base_elem, lbValue len);

lbValue lb_type_info(lbModule *m, Type *type);

lbValue lb_find_or_add_entity_string(lbModule *m, String const &str);
lbValue lb_generate_anonymous_proc_lit(lbModule *m, String const &prefix_name, Ast *expr, lbProcedure *parent = nullptr);

bool lb_is_const(lbValue value);
bool lb_is_const_or_global(lbValue value);
bool lb_is_const_nil(lbValue value);
String lb_get_const_string(lbModule *m, lbValue value);

lbValue lb_generate_local_array(lbProcedure *p, Type *elem_type, i64 count, bool zero_init=true);
lbValue lb_generate_global_array(lbModule *m, Type *elem_type, i64 count, String prefix, i64 id);
lbValue lb_gen_map_header(lbProcedure *p, lbValue map_val_ptr, Type *map_type);
lbValue lb_gen_map_hash(lbProcedure *p, lbValue key, Type *key_type);
void    lb_insert_dynamic_map_key_and_value(lbProcedure *p, lbAddr addr, Type *map_type, lbValue map_key, lbValue map_value, Ast *node);

lbValue lb_find_procedure_value_from_entity(lbModule *m, Entity *e);
lbValue lb_find_value_from_entity(lbModule *m, Entity *e);

void lb_store_type_case_implicit(lbProcedure *p, Ast *clause, lbValue value);
lbAddr lb_store_range_stmt_val(lbProcedure *p, Ast *stmt_val, lbValue value);
lbValue lb_emit_source_code_location(lbProcedure *p, String const &procedure, TokenPos const &pos);

lbValue lb_handle_param_value(lbProcedure *p, Type *parameter_type, ParameterValue const &param_value, TokenPos const &pos);

lbValue lb_get_equal_proc_for_type(lbModule *m, Type *type);
lbValue lb_get_hasher_proc_for_type(lbModule *m, Type *type);
lbValue lb_emit_conv(lbProcedure *p, lbValue value, Type *t);

LLVMMetadataRef lb_debug_type(lbModule *m, Type *type);

lbValue lb_emit_count_ones(lbProcedure *p, lbValue x, Type *type);
lbValue lb_emit_count_zeros(lbProcedure *p, lbValue x, Type *type);
lbValue lb_emit_count_trailing_zeros(lbProcedure *p, lbValue x, Type *type);
lbValue lb_emit_count_leading_zeros(lbProcedure *p, lbValue x, Type *type);
lbValue lb_emit_reverse_bits(lbProcedure *p, lbValue x, Type *type);

lbValue lb_emit_bit_set_card(lbProcedure *p, lbValue x);

void lb_mem_zero_addr(lbProcedure *p, LLVMValueRef ptr, Type *type);

void lb_build_nested_proc(lbProcedure *p, AstProcLit *pd, Entity *e);
lbValue lb_emit_logical_binary_expr(lbProcedure *p, TokenKind op, Ast *left, Ast *right, Type *type);
lbValue lb_build_cond(lbProcedure *p, Ast *cond, lbBlock *true_block, lbBlock *false_block);

LLVMValueRef llvm_const_named_struct(lbModule *m, Type *t, LLVMValueRef *values, isize value_count_);
LLVMValueRef llvm_const_named_struct_internal(LLVMTypeRef t, LLVMValueRef *values, isize value_count_);
void lb_set_entity_from_other_modules_linkage_correctly(lbModule *other_module, Entity *e, String const &name);

lbValue lb_expr_untyped_const_to_typed(lbModule *m, Ast *expr, Type *t);
bool lb_is_expr_untyped_const(Ast *expr);

void lb_mem_zero_ptr(lbProcedure *p, LLVMValueRef ptr, Type *type, unsigned alignment);

void lb_emit_init_context(lbProcedure *p, lbAddr addr);

lbCopyElisionHint lb_set_copy_elision_hint(lbProcedure *p, lbAddr const &addr, Ast *ast);
void lb_reset_copy_elision_hint(lbProcedure *p, lbCopyElisionHint prev_hint);
lbValue lb_consume_copy_elision_hint(lbProcedure *p);


lbStructFieldRemapping lb_get_struct_remapping(lbModule *m, Type *t);
LLVMTypeRef lb_type_padding_filler(lbModule *m, i64 padding, i64 padding_align);

LLVMValueRef llvm_basic_shuffle(lbProcedure *p, LLVMValueRef vector, LLVMValueRef mask);

void lb_mem_copy_overlapping(lbProcedure *p, lbValue dst, lbValue src, lbValue len, bool is_volatile=false);
void lb_mem_copy_non_overlapping(lbProcedure *p, lbValue dst, lbValue src, lbValue len, bool is_volatile=false);


#define LB_STARTUP_RUNTIME_PROC_NAME   "__$startup_runtime"
#define LB_STARTUP_TYPE_INFO_PROC_NAME "__$startup_type_info"
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


char const *llvm_linkage_strings[] = {
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

#define ODIN_METADATA_REQUIRE "odin-metadata-require", 21
