struct cgModule;
struct cgNode;
struct cgProcedure;
struct cgGraphBuilder;

enum cgMemoryOrder : u8 {
	cgMemoryOrder_Relaxed,
	cgMemoryOrder_AcqRel,
	cgMemoryOrder_SeqCst,
};

enum cgTypeKind : u8 {
	cgType_void,
	
	cgType_bool,

	cgType_i8,
	cgType_i16,
	cgType_i32,
	cgType_i64,
	// cgType_i128,
	
	cgType_ptr,
	
	cgType_f16,
	cgType_f32,
	cgType_f64,


	cgType_control,

	cgType_memory,

	cgType_tuple,
};

struct cgType {
	cgTypeKind kind;
};

gb_internal gb_inline bool operator==(cgType x, cgType y) {
	return x.kind == y.kind;
}

gb_global cgType const CG_TYPE_VOID    = cgType{cgType_void};
gb_global cgType const CG_TYPE_BOOL    = cgType{cgType_bool};
gb_global cgType const CG_TYPE_I8      = cgType{cgType_i8};
gb_global cgType const CG_TYPE_I16     = cgType{cgType_i16};
gb_global cgType const CG_TYPE_I32     = cgType{cgType_i32};
gb_global cgType const CG_TYPE_I64     = cgType{cgType_i64};
// gb_global cgType const CG_TYPE_I128    = cgType{cgType_i128};
gb_global cgType const CG_TYPE_PTR     = cgType{cgType_ptr};
gb_global cgType const CG_TYPE_F16     = cgType{cgType_f16};
gb_global cgType const CG_TYPE_F32     = cgType{cgType_f32};
gb_global cgType const CG_TYPE_F64     = cgType{cgType_f64};
gb_global cgType const CG_TYPE_V64     = cgType{cgType_v64};
gb_global cgType const CG_TYPE_V128    = cgType{cgType_v128};
gb_global cgType const CG_TYPE_V256    = cgType{cgType_v256};
gb_global cgType const CG_TYPE_V512    = cgType{cgType_v512};
gb_global cgType const CG_TYPE_CONTROL = cgType{cgType_control};
gb_global cgType const CG_TYPE_MEMORY  = cgType{cgType_memory};
gb_global cgType const CG_TYPE_TUPLE   = cgType{cgType_tuple};


enum cgLinkage : u8 {
	cgLinkage_Public,
	cgLinkage_Private,
};

enum cgSymbolKind : u8 {
	cgSymbol_None,
	cgSymbol_External,
	cgSymbol_Global,
	cgSymbol_Procedure,
	cgSymbol_Dead,
	cgSymbol_COUNT,
};

struct cgSymbol {
	cgSymbolKind kind;
	cgLinkage    linkage;

	String name;
	Entity *entity;

	cgModule *module;

	i64 ordinal;
};

enum cgCompareOp : u8 {
	cgCompareOp_Unknown,
	cgCompareOp_COUNT,
};

enum cgBinaryOpInt : u8 {
	cgBinaryOpInt_Unknown,
	cgBinaryOpInt_COUNT,
};

enum cgUnaryOp : u8 {
	cgUnaryOp_Unknown,
	cgUnaryOp_COUNT,
};

enum cgBinaryOpFloat : u8 {
	cgBinaryOpFloat_Unknown,
	cgBinaryOpFloat_COUNT,
};

enum cgCastOp : u8 {
	cgCastOp_Unknown,
	cgCastOp_COUNT,
};

struct cgUser {
	cgNode *node;
	i32     slot;
};

struct cgSafepoint {
	cgProcedure *procedure;
	cgNode *node;
	void *user_data;

	u32 ip;
	u32 frame_size;
};


enum cgNodeKind : u8 {
	cgNode_NULL,

	cgNode_Branch,
	cgNode_If,
	cgNode_Proj,
	cgNode_BranchProj,

	cgNode_SymbolTable,
	
	cgNode_Local,
	cgNode_Int,
	cgNode_Int128,
	cgNode_F16,
	cgNode_F32,
	cgNode_F64,
	cgNode_Symbol,

	cgNode_Compare,
	cgNode_BinaryOpInt,

	cgNode_MemAccess,

	cgNode_DebugLoc,
	cgNode_Atomic,

	cgNode_Safepoint,

	cgNode_Call,

	cgNode_Tailcall,

	cgNode_VShuffle,

	cgNode_Region,

	cgNode_COUNT,
};

struct cgNode {
	explicit cgNode(cgNodeKind kind) : kind{kind} {}

	cgNodeKind kind;
	cgType     type;

	u16 padding0;

	u32 gvn;

	u16 input_count;
	u16 input_capacity;

	u16 user_count;
	u16 user_capacity;

	// ordered use-def edges
	// after input_count (and up to input_capacity) goes an unordered set of nodes
	// which act as extra deps, storing things like anti-deps and other scheduling related edges
	cgNode **inputs_;
	// def-use edges, unordered
	cgUser * users_;

	Type *odin_type; // usually `nullptr`

	cgNode *inputs(isize index) {
		GB_ASSERT(0 <= index && index < this->input_count);
		return this->inputs_[index];
	}

	cgNode *unordered_inputs(isize index) {
		GB_ASSERT(0 <= index && index < (this->input_capacity - this->input_count));
		return this->inputs_[index+this->input_count];
	}

	cgUser &users(isize index) {
		GB_ASSERT(0 <= index && index < this->user_count);
		return this->users_[index];
	}
};

struct cgNodeBranch : cgNode {
	cgNodeBranch() : cgNode{cgNode_Branch} {}

	u64   total_hits;
	isize succ_count;
};
struct cgNodeIf : cgNode {
	cgNodeIf() : cgNode{cgNode_If} {}

	f32 prob;
};
struct cgNodeProj : cgNode {
	cgNodeProj() : cgNode{cgNode_Proj} {}

	i32 index;
};
struct cgNodeBranchProj : cgNode {
	cgNodeBranchProj() : cgNode{cgNode_BranchProj} {}

	i32 index;
	u64 taken;
	i64 key;
};
struct cgNodeSymbolTable : cgNode {
	cgNodeSymbolTable() : cgNode{cgNode_SymbolTable} {}

	bool complete;
};
struct cgNodeLocal : cgNode {
	cgNodeLocal() : cgNode{cgNode_Local} {}

	u32 size, align;

	i32 stack_pos;

	InternedString name;

	Type *allocated_type() const {
		return type_deref(this->odin_type);
	}
};
struct cgNodeInt : cgNode {
	cgNodeInt() : cgNode{cgNode_Int} {}

	u64 value;
};
struct cgNodeInt128 : cgNode {
	cgNodeInt128() : cgNode{cgNode_Int128} {}

	u64 lo;
	u64 hi;
};

struct cgNodeF16 : cgNode {
	cgNodeF16() : cgNode{cgNode_F16} {}

	u16 val;
};
struct cgNodeF32 : cgNode {
	cgNodeF32() : cgNode{cgNode_F32} {}

	f32 val;
};
struct cgNodeF64 : cgNode {
	cgNodeF64() : cgNode{cgNode_F64} {}

	f64 val;
};
struct cgNodeSymbol : cgNode {
	cgNodeSymbol() : cgNode{cgNode_Symbol} {}
};
struct cgNodeCompare : cgNode {
	cgNodeCompare() : cgNode{cgNode_Compare} {}

	cgCompareOp op;
	cgType      type;
};
struct cgNodeBinaryOpInt : cgNode {
	cgNodeBinaryOpInt() : cgNode{cgNode_BinaryOpInt} {}

	cgBinaryOpInt op;
};
struct cgNodeMemAccess : cgNode {
	cgNodeMemAccess() : cgNode{cgNode_MemAccess} {}

	u32 align;
};
struct cgNodeDebugLoc : cgNode {
	cgNodeDebugLoc() : cgNode{cgNode_DebugLoc} {}

	TokenPos pos;
};
struct cgNodeAtomic : cgNode {
	cgNodeAtomic() : cgNode{cgNode_Atomic} {}

	cgMemoryOrder order;
	cgMemoryOrder order_fail;
};
struct cgNodeSafepoint : cgNode {
	cgNodeSafepoint() : cgNode{cgNode_Safepoint} {}
	void *user_data;
	cgSafepoint *safe_point;
	isize saved_value_count;
};
struct cgNodeCall : cgNode {
	cgNodeCall() : cgNode{cgNode_Call} {}
};
struct cgNodeTailcall : cgNode {
	cgNodeTailcall() : cgNode{cgNode_Tailcall} {}
};
struct cgNodeVShuffle : cgNode {
	cgNodeVShuffle() : cgNode{cgNode_VShuffle} {}

	Slice<i32> indices;
};
struct cgNodeRegion : cgNode {
	cgNodeRegion() : cgNode{cgNode_Region} {}

	String name;
};


template <typename T>
gb_internal T *cg_alloc_node(cgProcedure *p, cgType type, isize input_count, isize input_capacity, Type *odin_type=nullptr);


/////////////////
// Builder API //
/////////////////

gb_internal cgGraphBuilder *cg_builder_enter(cgProcedure *p, Type *odin_signature);
gb_internal void            cg_builder_exit(cgGraphBuilder *b);


gb_internal cgNode *cg_builder_bool(cgGraphBuilder *b, bool x);
gb_internal cgNode *cg_builder_uint(cgGraphBuilder *b, cgType type, u64 x);
gb_internal cgNode *cg_builder_int (cgGraphBuilder *b, cgType type, i64 x);
gb_internal cgNode *cg_builder_f16(cgGraphBuilder *b, u16 x);
gb_internal cgNode *cg_builder_f32(cgGraphBuilder *b, f32 x);
gb_internal cgNode *cg_builder_f64(cgGraphBuilder *b, f64 x);
gb_internal cgNode *cg_builder_symbol(cgGraphBuilder *b, cgSymbol *s);
gb_internal cgNode *cg_builder_string_ptr(cgGraphBuilder *b, String str);


gb_internal cgNode *cg_builder_binary_op_int(cgGraphBuilder *b, cgBinaryOpInt op, cgNode *x, cgNode *y);
gb_internal cgNode *cg_builder_binary_op_float(cgGraphBuilder *b, cgBinaryOpInt op, cgNode *x, cgNode *y);

gb_internal cgNode *cg_builder_select(cgGraphBuilder *b, cgNode *cond, cgNode *x, cgNode *y);
gb_internal cgNode *cg_builder_cast(cgGraphBuilder *b, cgType type, cgCastOp op, cgNode *src);

gb_internal cgNode *cg_builder_unary(cgGraphBuilder *b, cgUnaryOp op, cgNode *src);
gb_internal cgNode *cg_builder_neg(cgGraphBuilder *b, cgNode *src);
gb_internal cgNode *cg_builder_not(cgGraphBuilder *b, cgNode *src);

gb_internal cgNode *cg_builder_cmp(cgGraphBuilder *b, cgCompareOp op, cgNode *x, cgNode *y);

// base + index*stride
gb_internal cgNode *cg_builder_ptr_array(cgGraphBuilder *b, cgNode *base, cgNode *index, i64 stride);
// base + offset
gb_internal cgNode *cg_builder_ptr_member(cgGraphBuilder *b, cgNode *base, i64 offset);


gb_internal cgNode *cg_builder_load(cgGraphBuilder *b, int mem_var, bool ctrl_dep, cgType type, cgNode *addr, u32 align, bool is_volatile);
gb_internal cgNode *cg_builder_store(cgGraphBuilder *b, int mem_var, bool ctrl_dep, cgType type, cgNode *addr, cgNode *val, u32 align, bool is_volatile);
gb_internal cgNode *cg_builder_memcpy(cgGraphBuilder *b, int mem_var, bool ctrl_dep, cgType type, cgNode *dst, cgNode *src, cgNode *size, u32 align, bool is_volatile);
gb_internal cgNode *cg_builder_memmove(cgGraphBuilder *b, int mem_var, bool ctrl_dep, cgType type, cgNode *dst, cgNode *src, cgNode *size, u32 align, bool is_volatile);
gb_internal cgNode *cg_builder_memzero(cgGraphBuilder *b, int mem_var, bool ctrl_dep, cgType type, cgNode *dst, cgNode *size, u32 align, bool is_volatile);


gb_internal cgNode *cg_builder_local(cgGraphBuilder *b, u32 size, u32 align);
gb_internal cgNode *cg_builder_local_debug(cgGraphBuilder *b, cgNode *n, String name, Type *odin_type);

gb_internal cgNode *cg_builder_frame_ptr(cgGraphBuilder *b);


// Control Flow Primitives using Regions

gb_internal cgNode *cg_builder_label(cgGraphBuilder *b, cgNode *label=nullptr, bool allow_backward_jumps=false);
// Once a labe is complete, you can no longer insert jumps into it.
// The phi nodes are placed and you can then insert code into the label's body.
gb_internal cgNode *cg_builder_label_complete(cgGraphBuilder *b, cgNode *label);

gb_internal void    cg_builder_label_kill(cgGraphBuilder *b, cgNode *label);

gb_internal cgNode *cg_builder_if(cgGraphBuilder *b, cgNode *cond, cgNode *x, cgNode *y);
gb_internal void    cg_builder_jump(cgGraphBuilder *b, cgNode *target);
gb_internal cgNode *cg_builder_loop(cgGraphBuilder *b);
gb_internal cgNode *cg_builder_phi(cgGraphBuilder *b, Slice<cgNode *> vals);

gb_internal cgNode *cg_builder_switch(cgGraphBuilder *b, cgNode *cond);
gb_internal cgNode *cg_builder_case_default(cgGraphBuilder *b, cgNode *br_syms);
gb_internal cgNode *cg_builder_case_key(cgGraphBuilder *b, cgNode *br_syms, u64 key);


gb_internal void cg_builder_ret(cgGraphBuilder *b, int mem_var, Slice<cgNode *> args);
gb_internal void cg_builder_unreachable(cgGraphBuilder *b, int mem_var);
gb_internal void cg_builder_trap(cgGraphBuilder *b, int mem_var);
gb_internal void cg_builder_debug_trap(cgGraphBuilder *b, int mem_var);
// All the passed arguments have their lifetimes anchored to this points
gb_internal void cg_builder_black_hole(cgGraphBuilder *b, Slice<cgNode *> args);

gb_internal cgNode *cg_builder_call(cgGraphBuilder *b, Type *odin_signature, int mem_var, cgNode *target, Slice<cgNode *> args);
gb_internal cgNode *cg_builder_syscall(cgGraphBuilder *b, cgType dt, int mem_var, cgNode *target, Slice<cgNode *> args);

gb_internal cgNode *cg_builder_atomic_rmw(cgGraphBuilder *b, int mem_var, int op, cgNode *addr, cgNode *val, cgMemoryOrder order);
gb_internal cgNode *cg_builder_atomic_load(cgGraphBuilder *b, int mem_var, cgType type, cgNode *addr, cgMemoryOrder order);

gb_internal bool cg_node_is_constant_zero(cgGraphBuilder *b, cgNode *n);




//////////////////////
// Construction API //
//////////////////////


enum cgValueKind : u8 {
	cgValueKind_Value,  // rvalue
	cgValueKind_Addr,   // lvalue
	cgValueKind_Symbol, // global
	cgValueKind_Multi,  // multiple values
};

struct cgValueMulti;

struct cgValue {
	cgValueKind kind;
	Type *type;
	union {
		cgNode *      node;
		cgSymbol *    symbol;
		cgValueMulti *multi;
	};
};

struct cgValueMulti {
	Slice<cgValue> values;
};

enum cgAddrKind : u8 {
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

struct cgExternal : cgSymbol {

};


enum cgGlobalInitObjectKind : u8 {
	cgGlobalInitObject_Region,
	cgGlobalInitObject_Reloc,
};

struct cgGlobalInitObject {
	cgGlobalInitObjectKind kind;
	u64 offset;

	union {
		struct {
			void *ptr;
			isize size;
		} region;
		cgSymbol *reloc;
	};
};

struct cgGlobal : cgSymbol {
	u64 size;
	u32 align;

	Type *debug_odin_type;

	Array<cgGlobalInitObject> objects;
};


struct cgProcedure : cgSymbol {
	Arena arena;

	u32 flags;
	u16 state_flags;

	cgProcedure *parent;
	Array<cgProcedure *> children;

	Entity *entity;
	cgModule *module;

	String name;

	Type *type;
	Ast *type_expr;
	Ast *body;
	u64 tags;
	ProcInlining inlining;
	bool is_foreign;
	bool is_export;
	bool is_entry_point;
	bool is_startup;

	cgValue value;
};


struct cgModule {
	Array<cgSymbol *> symbols;


	Array<cgProcedure *> procedures;
};