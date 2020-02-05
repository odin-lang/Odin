#include "llvm-c/Core.h"
#include "llvm-c/ExecutionEngine.h"
#include "llvm-c/Target.h"
#include "llvm-c/Analysis.h"
#include "llvm-c/Object.h"
#include "llvm-c/BitWriter.h"
#include "llvm-c/Transforms/AggressiveInstCombine.h"
#include "llvm-c/Transforms/InstCombine.h"
#include "llvm-c/Transforms/IPO.h"

struct lbValue {
	LLVMValueRef value;
	Type *type;
};


enum lbAddrKind {
	lbAddr_Default,
	lbAddr_Map,
	lbAddr_BitField,
	lbAddr_Context,
	lbAddr_SoaVariable,
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
			i32 value_index;
		} bit_field;
		struct {
			Selection sel;
		} ctx;
		struct {
			lbValue index;
			Ast *index_expr;
		} soa;
	};
};

struct lbModule {
	LLVMModuleRef mod;
	LLVMContextRef ctx;
	CheckerInfo *info;

	Map<LLVMTypeRef> types; // Key: Type *

	Map<lbValue> values; // Key: Entity *
	Map<lbValue> members; // Key: String

	Map<lbValue> const_strings; // Key: String
	Map<lbValue> const_string_byte_slices; // Key: String

	lbAddr global_default_context;

	u32 global_array_index;
	u32 global_generated_index;
};

struct lbGenerator {
	lbModule module;
	CheckerInfo *info;

	gbFile   output_file;
	String   output_base;
	String   output_name;
};


struct lbBlock {
	LLVMBasicBlockRef block;
	Scope *scope;
	isize scope_index;
};

struct lbBranchBlocks {
	Ast *label;
	lbBlock *break_;
	lbBlock *continue_;
};


struct lbContextData {
	lbAddr ctx;
	isize scope_index;
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

struct lbTargetList {
	lbTargetList *prev;
	bool          is_block;
	lbBlock *     break_;
	lbBlock *     continue_;
	lbBlock *     fallthrough_;
};



struct lbProcedure {
	lbProcedure *parent;
	Array<lbProcedure> children;

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


	LLVMValueRef    value;
	LLVMBuilderRef  builder;

	lbAddr           return_ptr;
	Array<lbValue>   params;
	Array<lbBlock *> blocks;
	Array<lbBranchBlocks> branch_blocks;
	Scope *          curr_scope;
	i32              scope_index;
	lbBlock *        decl_block;
	lbBlock *        entry_block;
	lbBlock *        curr_block;
	lbTargetList *   target_list;

	Array<lbContextData> context_stack;

	lbValue  return_ptr_hint_value;
	Ast *    return_ptr_hint_ast;
	bool     return_ptr_hint_used;
};





bool lb_init_generator(lbGenerator *gen, Checker *c);
void lb_generate_module(lbGenerator *gen);

String lb_mangle_name(lbModule *m, Entity *e);
String lb_get_entity_name(lbModule *m, Entity *e, String name = {});

LLVMAttributeRef lb_create_enum_attribute(LLVMContextRef ctx, char const *name, u64 value);
void lb_add_proc_attribute_at_index(lbProcedure *p, isize index, char const *name, u64 value);
void lb_add_proc_attribute_at_index(lbProcedure *p, isize index, char const *name);
lbProcedure *lb_create_procedure(lbModule *module, Entity *entity);
void lb_end_procedure(lbProcedure *p);


LLVMTypeRef  lb_type(lbModule *m, Type *type);

lbBlock *lb_create_block(lbProcedure *p, char const *name);

lbValue lb_const_nil(lbModule *m, Type *type);
lbValue lb_const_value(lbModule *m, Type *type, ExactValue value);


lbAddr lb_addr(lbValue addr);
Type *lb_addr_type(lbAddr const &addr);
LLVMTypeRef lb_addr_lb_type(lbAddr const &addr);
void lb_addr_store(lbProcedure *p, lbAddr const &addr, lbValue const &value);
lbValue lb_addr_load(lbProcedure *p, lbAddr const &addr);
lbValue lb_emit_load(lbProcedure *p, lbValue v);

void    lb_build_stmt(lbProcedure *p, Ast *stmt);
lbValue lb_build_expr(lbProcedure *p, Ast *expr);
lbAddr  lb_build_addr(lbProcedure *p, Ast *expr);
void lb_build_stmt_list(lbProcedure *p, Array<Ast *> const &stmts);

lbValue lb_build_gep(lbProcedure *p, lbValue const &value, i32 index) ;

lbValue lb_emit_struct_ep(lbProcedure *p, lbValue s, i32 index);
lbValue lb_emit_struct_ev(lbProcedure *p, lbValue s, i32 index);
lbValue lb_emit_array_epi(lbProcedure *p, lbValue value, i32 index);


lbValue lb_emit_arith(lbProcedure *p, TokenKind op, lbValue lhs, lbValue rhs, Type *type);



lbValue lb_emit_conv(lbProcedure *p, lbValue value, Type *t);
lbValue lb_build_call_expr(lbProcedure *p, Ast *expr);


lbAddr lb_add_global_generated(lbModule *m, Type *type, lbValue value={});

lbAddr lb_add_local(lbProcedure *p, Type *type, Entity *e=nullptr, bool zero_init=true, i32 param_index=0);

lbValue lb_emit_transmute(lbProcedure *p, lbValue value, Type *t);


enum lbCallingConventionKind {
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
};
