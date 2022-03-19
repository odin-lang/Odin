/*
	Odin Middle End Notation

	"me" prefix means middle end
*/

struct meModule; // Build/Translation Unit
struct meValue;
struct meProcedure;
struct meBlock;
struct meInstruction;
struct meConstant;
struct meGlobalVariable;
struct meParameter;


enum meValueKind : u8 {
	meValue_Invalid = 0,
	meValue_Instruction,
	meValue_ConstantValue,
	meValue_Block,
	meValue_Procedure,
	meValue_GlobalVariable,
	meValue_Parameter,
};
struct meValue {
	meValueKind kind;
	union {
		meInstruction    *instr;
		meConstant       *constant;
		meBlock          *block;
		meProcedure      *proc;
		meGlobalVariable *global;
		meParameter      *param;
	};
};

enum meOpKind : u8 {
	meOp_Invalid = 0,

	meOp_Unreachable,
	meOp_Return,
	meOp_Jump,
	meOp_CondJump,
	meOp_Switch,
	meOp_Phi,

	// Unary Operators
	meOp_Neg,
	meOp_LogicalNot,
	meOp_BitwiseNot,

	// Binary Arithmetic Operators
	meOp_Add,
	meOp_Sub,
	meOp_Mul,
	meOp_Div,
	meOp_Rem,

	// Binary Bitwise Operators
	meOp_Shl,
	meOp_LShr,
	meOp_AShr,
	meOp_And,
	meOp_Or,
	meOp_Xor,

	// Memory Operators
	meOp_Alloca,
	meOp_Load,
	meOp_Store,
	meOp_UnalignedLoad,
	meOp_UnalignedStore,
	meOp_GetElementPtr,
	meOp_PtrOffset,
	meOp_PtrSub,

	// Cast Operators
	meOp_Cast,
	meOp_Transmute,

	// Binary Comparison Operators
	meOp_Eq,
	meOp_NotEq,
	meOp_Lt,
	meOp_LtEq,
	meOp_Gt,
	meOp_GtEq,

	meOp_Min,
	meOp_Max,

	// Ternary Operators
	meOp_Select,

	// Other
	meOp_Call,
	meOp_BuiltinCall,

	meOp_ExtractValue,
	meOp_Swizzle,

	meOp_Alias, // alias of another value

	// Atomics
	meOp_Fence,
	meOp_AtomicXchg,
	meOp_AtomicCmpXchg,
};

enum meInstructionFlags : u16 {
	meInstructionFlag_Volatile       = 1<<0,
	meInstructionFlag_AtomicRMW      = 1<<1,
	meInstructionFlag_ForceInline    = 1<<2,
	meInstructionFlag_ForceNoInline  = 1<<3,
	meInstructionFlag_HasSideEffects = 1<<4,
};

enum meAtomicOrderingKind : u8 {
	meAtomicOrdering_NotAtomic,
	meAtomicOrdering_Unordered,
	meAtomicOrdering_Monotonic,
	meAtomicOrdering_Acquire,
	meAtomicOrdering_Release,
	meAtomicOrdering_AcquireRelease,
	meAtomicOrdering_SequentiallyConsistent,
	meAtomicOrdering_COUNT,
};

enum meLinkageKind : u8 {
	meLinkage_Strong,
	meLinkage_Weak,
	meLinkage_Internal,
	meLinkage_LinkOnce,
	meLinkage_Export,
};


enum {me_INSTRUCTION_MAX_ARG_COUNT = 4};

struct meInstruction {
	meOpKind             op;
	meAtomicOrderingKind atomic_ordering;
	u16                  flags;
	u16                  alignment;
	u16                  uses;

	Type *       type;
	meProcedure *parent;
	TokenPos     pos;

	meValue ops[me_INSTRUCTION_MAX_ARG_COUNT];
	isize op_count;

	Slice<meValue> *extra_ops; // non-null if used
};

struct meConstant {
	ExactValue value;
	Type *type;
};

struct meBlock {
	meProcedure *          parent;
	String                 name;
	Array<meInstruction *> instructions;
	Scope *                scope;
	i32                    scope_index;
	Array<meBlock *>       preds;
	Array<meBlock *>       succs;
};

struct meBranchBlocks {
	Ast *label;
	meBlock *break_;
	meBlock *continue_;
};

struct meTargetList {
	meTargetList *prev;
	bool is_block;
	meBlock *break_;
	meBlock *continue_;
	meBlock *fallthrough_;
};

enum meGlobalVariableFlags : u16 {
	meGlobalVariableFlag_ThreadLocal_default      = 1<<0,
	meGlobalVariableFlag_ThreadLocal_localdynamic = 1<<1,
	meGlobalVariableFlag_ThreadLocal_initialexec  = 1<<2,
	meGlobalVariableFlag_ThreadLocal_localexec    = 1<<3,
};


struct meGlobalVariable {
	meModule *    module;
	Entity *      entity;
	Type *        type;
	String        name; // link name
	meLinkageKind linkage;
	u16           flags;
	ExactValue    value;
	i32           uses;
	DeclInfo *    decl;
};

struct meParameter {
	String       name;
	Entity *     entity;
	meProcedure *parent;
	i32          uses;
};

enum meAddrKind : u32 {
	meAddr_Default = 0,
	meAddr_Map,
	meAddr_Context,
	meAddr_SoaVariable,

	meAddr_RelativePointer,
	meAddr_RelativeSlice,

	meAddr_Swizzle,
	meAddr_SwizzleLarge,
};

struct meAddr {
	meAddrKind kind;
	meValue    addr;
	union {
		struct {
			meValue key;
			Type *type;
			Type *result;
		} map;
		struct {
			Selection sel;
		} ctx;
		struct {
			meValue index;
			Ast *index_expr;
		} soa;
		struct {
			meValue index;
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



struct meContextData {
	meAddr ctx;
	i32 scope_index;
	i32 uses;
};

enum meDeferKind {
	meDefer_Node,
	meDefer_Proc,
};

struct meDefer {
	meDeferKind kind;
	i32         scope_index;
	i32         context_stack_count;
	meBlock *   block;
	union {
		Ast *stmt;
		struct {
			meValue deferred;
			Array<meValue> result_as_args;
		} proc;
	};
};

enum meDeferExitKind {
	meDeferExit_Default,
	meDeferExit_Return,
	meDeferExit_Branch,
};



enum meProcedureFlags : u32 {
	meProcedureFlag_Foreign    = 1<<1,
	meProcedureFlag_Export     = 1<<2,
	meProcedureFlag_EntryPoint = 1<<3,
	meProcedureFlag_Startup    = 1<<4,

	meProcedureFlag_Inline    = 1<<5,
	meProcedureFlag_NoInline  = 1<<6,

	meProcedureFlag_Cold          = 1<<7,
	meProcedureFlag_Hot           = 1<<8,
	meProcedureFlag_WithoutMemcpy = 1<<9,
};

struct meProcedure {
	meModule *       module;
	Entity *         entity;
	Type *           type;
	String           name; // link name
	meLinkageKind    linkage;
	u32              flags;
	i32              uses;
	BuiltinProcId    builtin_id;

	u16  state_flags;
	bool is_done;

	meProcedure *        parent;
	Array<meProcedure *> children;

	Ast *type_expr;
	Ast *body;
	u64  tags;

	meAddr           return_ptr;
	Array<meDefer>   defer_stmts;

	Array<meBlock *> blocks;
	meBlock *        decl_block;
	meBlock *        entry_block;
	meBlock *        curr_block;

	Array<meBranchBlocks> branch_blocks;

	Scope *curr_scope;
	i32    scope_index;

	meTargetList *target_list;

	Ast *curr_stmt;

	Array<Scope *> scope_stack;

	Array<meContextData> context_stack;
};

struct meModule { // Build/Translation Unit
	CheckerInfo *info;
	AstPackage *pkg; // associated

	PtrMap<Entity *, meValue> values;
	PtrMap<Entity *, meAddr>  soa_values;
	StringMap<meValue>  members;
	StringMap<meProcedure *> procedures;
	PtrMap<meProcedure *, Entity *> procedure_values;
	Array<meProcedure *> missing_procedures_to_check;

	StringMap<meValue> const_strings;

	PtrMap<Type *, meProcedure *> equal_procs;
	PtrMap<Type *, meProcedure *> hasher_procs;

	u32 nested_type_name_guid;

	Array<meProcedure *> procedures_to_generate;
	Array<String> foreign_library_paths;

	meProcedure *curr_procedure;

	StringMap<meAddr> objc_classes;
	StringMap<meAddr> objc_selectors;
};


bool me_generate(Checker *c);

String me_get_entity_name(meModule *m, Entity *e, String default_name = {});

meProcedure *me_procedure_create(meModule *m, Entity *entity, bool ignore_body=false);


meValue me_value(meInstruction *instr);
meValue me_value(meConstant *constant);
meValue me_value(meBlock *block);
meValue me_value(meProcedure *proc);
meValue me_value(meGlobalVariable *global);
meValue me_value(meParameter *param);


void me_build_stmt(meProcedure *p, Ast *stmt);
meValue me_build_expr(meProcedure *p, Ast *expr);
meValue me_emit_conv(meProcedure *p, meValue value, Type *type);

