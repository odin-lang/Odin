typedef enum   ssaOp               ssaOp;
typedef struct ssaModule           ssaModule;
typedef struct ssaValue            ssaValue;
typedef struct ssaValueArgs        ssaValueArgs;
typedef struct ssaBlock            ssaBlock;
typedef struct ssaProc             ssaProc;
typedef struct ssaEdge             ssaEdge;
typedef struct ssaRegister         ssaRegister;
typedef struct ssaTargetList       ssaTargetList;
typedef enum   ssaBlockKind        ssaBlockKind;
typedef enum   ssaBranchPrediction ssaBranchPrediction;

String ssa_mangle_name(ssaModule *m, String path, Entity *e);

#define MAP_TYPE ssaValue *
#define MAP_PROC map_ssa_value_
#define MAP_NAME MapSsaValue
#include "map.c"

typedef Array(ssaValue *) ssaValueArray;


#define SSA_OPS \
	SSA_OP(Invalid)\
\
	SSA_OP(Unknown)\
\
	SSA_OP(Comment) /* Does nothing */\
\
	SSA_OP(SP)    /* Stack Pointer */\
	SSA_OP(SB)    /* Stack Base */\
	SSA_OP(Addr)  /* Address of something - special rules for certain types when loading and storing (e.g. Maps) */\
\
	SSA_OP(Local)\
	SSA_OP(Global)\
	SSA_OP(Proc)\
\
	SSA_OP(Load)\
	SSA_OP(Store)\
	SSA_OP(Move)\
	SSA_OP(Zero) /* Zero initialize */\
\
	SSA_OP(ArrayIndex)  /* Index for a fixed array */\
	SSA_OP(PtrIndex)    /* Index for a struct/tuple/etc */\
	SSA_OP(OffsetPtr)\
	SSA_OP(ValueIndex) /* Extract for a value from a register */\
\
	SSA_OP(Phi)\
	SSA_OP(Copy)\
\
	/* TODO(bill): calling conventions */\
	SSA_OP(CallOdin)\
	SSA_OP(CallC)\
	SSA_OP(CallStd)\
	SSA_OP(CallFast)\
\
	SSA_OP(BoundsCheck)\
	SSA_OP(SliceBoundsCheck)\
\
	/* Built in operations/procedures */\
	SSA_OP(Bswap16)\
	SSA_OP(Bswap32)\
	SSA_OP(Bswap64)\
\
	SSA_OP(Assume)\
	SSA_OP(DebugTrap)\
	SSA_OP(Trap)\
	SSA_OP(ReadCycleCounter)\
\
\
	SSA_OP(ConstBool)\
	SSA_OP(ConstString)\
	SSA_OP(ConstSlice)\
	SSA_OP(ConstNil)\
	SSA_OP(Const8)\
	SSA_OP(Const16)\
	SSA_OP(Const32)\
	SSA_OP(Const64)\
	SSA_OP(Const32F)\
	SSA_OP(Const64F)\
\
	/* These should be all the operations I could possibly need for the mean time */\
	SSA_OP(Add8)\
	SSA_OP(Add16)\
	SSA_OP(Add32)\
	SSA_OP(Add64)\
	SSA_OP(AddPtr)\
	SSA_OP(Add32F)\
	SSA_OP(Add64F)\
	SSA_OP(Sub8)\
	SSA_OP(Sub16)\
	SSA_OP(Sub32)\
	SSA_OP(Sub64)\
	SSA_OP(SubPtr)\
	SSA_OP(Sub32F)\
	SSA_OP(Sub64F)\
	SSA_OP(Mul8)\
	SSA_OP(Mul16)\
	SSA_OP(Mul32)\
	SSA_OP(Mul64)\
	SSA_OP(Mul32F)\
	SSA_OP(Mul64F)\
	SSA_OP(Div8)\
	SSA_OP(Div8U)\
	SSA_OP(Div16)\
	SSA_OP(Div16U)\
	SSA_OP(Div32)\
	SSA_OP(Div32U)\
	SSA_OP(Div64)\
	SSA_OP(Div64U)\
	SSA_OP(Div32F)\
	SSA_OP(Div64F)\
	SSA_OP(Mod8)\
	SSA_OP(Mod8U)\
	SSA_OP(Mod16)\
	SSA_OP(Mod16U)\
	SSA_OP(Mod32)\
	SSA_OP(Mod32U)\
	SSA_OP(Mod64)\
	SSA_OP(Mod64U)\
\
	SSA_OP(And8)\
	SSA_OP(And16)\
	SSA_OP(And32)\
	SSA_OP(And64)\
	SSA_OP(Or8)\
	SSA_OP(Or16)\
	SSA_OP(Or32)\
	SSA_OP(Or64)\
	SSA_OP(Xor8)\
	SSA_OP(Xor16)\
	SSA_OP(Xor32)\
	SSA_OP(Xor64)\
	SSA_OP(AndNot8)\
	SSA_OP(AndNot16)\
	SSA_OP(AndNot32)\
	SSA_OP(AndNot64)\
\
	SSA_OP(Lsh8x8)\
	SSA_OP(Lsh8x16)\
	SSA_OP(Lsh8x32)\
	SSA_OP(Lsh8x64)\
	SSA_OP(Lsh16x8)\
	SSA_OP(Lsh16x16)\
	SSA_OP(Lsh16x32)\
	SSA_OP(Lsh16x64)\
	SSA_OP(Lsh32x8)\
	SSA_OP(Lsh32x16)\
	SSA_OP(Lsh32x32)\
	SSA_OP(Lsh32x64)\
	SSA_OP(Lsh64x8)\
	SSA_OP(Lsh64x16)\
	SSA_OP(Lsh64x32)\
	SSA_OP(Lsh64x64)\
	SSA_OP(Rsh8x8)\
	SSA_OP(Rsh8x16)\
	SSA_OP(Rsh8x32)\
	SSA_OP(Rsh8x64)\
	SSA_OP(Rsh16x8)\
	SSA_OP(Rsh16x16)\
	SSA_OP(Rsh16x32)\
	SSA_OP(Rsh16x64)\
	SSA_OP(Rsh32x8)\
	SSA_OP(Rsh32x16)\
	SSA_OP(Rsh32x32)\
	SSA_OP(Rsh32x64)\
	SSA_OP(Rsh64x8)\
	SSA_OP(Rsh64x16)\
	SSA_OP(Rsh64x32)\
	SSA_OP(Rsh64x64)\
	SSA_OP(Rsh8Ux8)\
	SSA_OP(Rsh8Ux16)\
	SSA_OP(Rsh8Ux32)\
	SSA_OP(Rsh8Ux64)\
	SSA_OP(Rsh16Ux8)\
	SSA_OP(Rsh16Ux16)\
	SSA_OP(Rsh16Ux32)\
	SSA_OP(Rsh16Ux64)\
	SSA_OP(Rsh32Ux8)\
	SSA_OP(Rsh32Ux16)\
	SSA_OP(Rsh32Ux32)\
	SSA_OP(Rsh32Ux64)\
	SSA_OP(Rsh64Ux8)\
	SSA_OP(Rsh64Ux16)\
	SSA_OP(Rsh64Ux32)\
	SSA_OP(Rsh64Ux64)\
\
	SSA_OP(Eq8)\
	SSA_OP(Eq16)\
	SSA_OP(Eq32)\
	SSA_OP(Eq64)\
	SSA_OP(EqPtr)\
	SSA_OP(Eq32F)\
	SSA_OP(Eq64F)\
	SSA_OP(Ne8)\
	SSA_OP(Ne16)\
	SSA_OP(Ne32)\
	SSA_OP(Ne64)\
	SSA_OP(NePtr)\
	SSA_OP(Ne32F)\
	SSA_OP(Ne64F)\
	SSA_OP(Lt8)\
	SSA_OP(Lt16)\
	SSA_OP(Lt32)\
	SSA_OP(Lt64)\
	SSA_OP(LtPtr)\
	SSA_OP(Lt32F)\
	SSA_OP(Lt64F)\
	SSA_OP(Gt8)\
	SSA_OP(Gt16)\
	SSA_OP(Gt32)\
	SSA_OP(Gt64)\
	SSA_OP(GtPtr)\
	SSA_OP(Gt32F)\
	SSA_OP(Gt64F)\
	SSA_OP(Le8)\
	SSA_OP(Le16)\
	SSA_OP(Le32)\
	SSA_OP(Le64)\
	SSA_OP(LePtr)\
	SSA_OP(Le32F)\
	SSA_OP(Le64F)\
	SSA_OP(Ge8)\
	SSA_OP(Ge16)\
	SSA_OP(Ge32)\
	SSA_OP(Ge64)\
	SSA_OP(GePtr)\
	SSA_OP(Ge32F)\
	SSA_OP(Ge64F)\
\
	SSA_OP(NotB)\
	SSA_OP(EqB)\
	SSA_OP(NeB)\
\
	SSA_OP(Neg8)\
	SSA_OP(Neg16)\
	SSA_OP(Neg32)\
	SSA_OP(Neg64)\
	SSA_OP(Neg32F)\
	SSA_OP(Neg64F)\
\
	SSA_OP(Not8)\
	SSA_OP(Not16)\
	SSA_OP(Not32)\
	SSA_OP(Not64)\
\
	SSA_OP(SignExt8to16)\
	SSA_OP(SignExt8to32)\
	SSA_OP(SignExt8to64)\
	SSA_OP(SignExt16to32)\
	SSA_OP(SignExt16to64)\
	SSA_OP(SignExt32to64)\
	SSA_OP(ZeroExt8to16)\
	SSA_OP(ZeroExt8to32)\
	SSA_OP(ZeroExt8to64)\
	SSA_OP(ZeroExt16to32)\
	SSA_OP(ZeroExt16to64)\
	SSA_OP(ZeroExt32to64)\
	SSA_OP(Trunc16to8)\
	SSA_OP(Trunc32to8)\
	SSA_OP(Trunc32to16)\
	SSA_OP(Trunc64to8)\
	SSA_OP(Trunc64to16)\
	SSA_OP(Trunc64to32)\
\
	SSA_OP(Cvt32to32F)\
	SSA_OP(Cvt32to64F)\
	SSA_OP(Cvt64to32F)\
	SSA_OP(Cvt64to64F)\
	SSA_OP(Cvt32Fto32)\
	SSA_OP(Cvt32Fto64)\
	SSA_OP(Cvt64Fto32)\
	SSA_OP(Cvt64Fto64)\
	SSA_OP(Cvt32Fto64F)\
	SSA_OP(Cvt64Fto32F)\
	SSA_OP(Cvt32Uto32F)\
	SSA_OP(Cvt32Uto64F)\
	SSA_OP(Cvt32Fto32U)\
	SSA_OP(Cvt64Fto32U)\
	SSA_OP(Cvt64Uto32F)\
	SSA_OP(Cvt64Uto64F)\
	SSA_OP(Cvt32Fto64U)\
	SSA_OP(Cvt64Fto64U)\


enum ssaOp {
#define SSA_OP(k) GB_JOIN2(ssaOp_, k),
	SSA_OPS
#undef SSA_OP
};

String const ssa_op_strings[] = {
#define SSA_OP(k) {cast(u8 *)#k, gb_size_of(#k)-1},
	SSA_OPS
#undef SSA_OP
};


#define SSA_DEFAULT_VALUE_ARG_CAPACITY 8
struct ssaValueArgs {
	ssaValue ** e;
	isize       count;
	isize       capacity;
	ssaValue *  backing[SSA_DEFAULT_VALUE_ARG_CAPACITY];
	gbAllocator allocator;
};

struct ssaValue {
	i32           id;    // Unique identifier but the pointer could be used too
	ssaOp         op;    // Operation that computes this value
	Type *        type;
	ssaBlock *    block; // Containing basic block

	i32           uses;
	ssaValueArgs  args;
	ExactValue    exact_value; // Used for constants

	String        comment_string;
};

enum ssaBlockKind {
	ssaBlock_Invalid,

	// NOTE(bill): These are the generic block types and for more specific
	// architectures, these could become conditions blocks like amd64 LT or EQ
	ssaBlock_Entry, // Entry point
	ssaBlock_Plain,
	ssaBlock_If,
	ssaBlock_Ret,
	ssaBlock_RetJmp, // Stores return value and jumps to Ret block
	ssaBlock_Exit,

	ssaBlock_Count,
};

enum ssaBranchPrediction {
	ssaBranch_Unknown  = 0,
	ssaBranch_Likely   = +1,
	ssaBranch_Unlikely = -1,
};

// ssaEdge represents a control flow graph (CFG) edge
struct ssaEdge {
	// Succs array: Block To
	// Preds array: Block From
	ssaBlock *block;
	// Index of reverse edge
	isize     index;
};

typedef Array(ssaEdge) ssaEdgeArray;

struct ssaBlock {
	i32                  id;   // Unique identifier but the pointer could be used too
	ssaBlockKind         kind;
	ssaProc *            proc; // Containing procedure
	String               name; // Optional

	// Likely branch direction
	ssaBranchPrediction likeliness;

	// Determines how a block exits
	// It depends on the type of block:
	//  - BlockIf will be a boolean value
	//  - BlockExit will be a memory control value
	ssaValue *control;

	ssaValueArray values;
	ssaEdgeArray  preds;
	ssaEdgeArray  succs;
};

struct ssaTargetList {
	ssaTargetList *prev;
	ssaBlock *     break_;
	ssaBlock *     continue_;
	ssaBlock *     fallthrough_;
};

struct ssaProc {
	ssaModule *       module;     // Parent module
	String            name;       // Mangled name
	Entity *          entity;
	DeclInfo *        decl_info;

	Array(ssaBlock *) blocks;
	ssaBlock *        entry;      // Entry block
	ssaBlock *        exit;       // Exit block
	ssaBlock *        curr_block;

	ssaTargetList *   target_list;

	i32               block_id;
	i32               value_id;
	MapSsaValue       values;   // Key: Entity *
};

struct ssaRegister {
	i32 id;
	i32 size;
};

struct ssaModule {
	CheckerInfo *      info;
	gbAllocator        allocator;
	gbArena            arena;
	gbAllocator        tmp_allocator;
	gbArena            tmp_arena;

	MapEntity          min_dep_map; // Key: Entity *
	MapSsaValue        values;      // Key: Entity *
	// List of registers for the specific architecture
	Array(ssaRegister) registers;

	ssaProc *proc; // current procedure

	Entity *entry_point_entity;

	u32 stmt_state_flags;

	Array(ssaProc *)  procs;
	ssaValueArray     procs_to_generate;
};


void ssa_push_target_list(ssaProc *p, ssaBlock *break_, ssaBlock *continue_, ssaBlock *fallthrough_) {
	ssaTargetList *tl = gb_alloc_item(p->module->allocator, ssaTargetList);
	tl->prev          = p->target_list;
	tl->break_        = break_;
	tl->continue_     = continue_;
	tl->fallthrough_  = fallthrough_;
	p->target_list    = tl;
}

void ssa_pop_target_list(ssaProc *p) {
	p->target_list = p->target_list->prev;
}


ssaBlock *ssa_new_block(ssaProc *p, ssaBlockKind kind, char *name) {
	ssaBlock *b = gb_alloc_item(p->module->allocator, ssaBlock);
	b->id = p->block_id++;
	b->kind = kind;
	b->proc = p;
	if (name != NULL || name[0] != 0) {
		b->name = make_string_c(name);
	}

	array_init(&b->values, heap_allocator());
	array_init(&b->preds,  heap_allocator());
	array_init(&b->succs,  heap_allocator());
	array_add(&p->blocks, b);
	return b;
}

void ssa_clear_block(ssaProc *p, ssaBlock *b) {
	GB_ASSERT(b->proc != NULL);
	array_clear(&b->values);
	array_clear(&b->preds);
	array_clear(&b->succs);
	b->proc = NULL;
	b->kind = ssaBlock_Plain;
}


void ssa_start_block(ssaProc *p, ssaBlock *b) {
	GB_ASSERT(p->curr_block == NULL);
	p->curr_block = b;
}

ssaBlock *ssa_end_block(ssaProc *p) {
	ssaBlock *b = p->curr_block;
	if (b == NULL) {
		return NULL;
	}
	p->curr_block = NULL;
	return b;
}

void ssa_add_edge_to(ssaBlock *b, ssaBlock *c) {
	if (b == NULL) {
		return;
	}
	GB_ASSERT(c != NULL);
	isize i = b->succs.count;
	isize j = b->preds.count;
	ssaEdge s = {c, j};
	ssaEdge p = {b, i};
	array_add(&b->succs, s);
	array_add(&c->preds, p);
}

void ssa_set_control(ssaBlock *b, ssaValue *v) {
	if (b->control != NULL) {
		b->control->uses--;
	}
	b->control = v;
	if (v != NULL) {
		v->uses++;
	}
}

void ssa_emit_jump(ssaProc *p, ssaBlock *edge) {
	ssa_add_edge_to(ssa_end_block(p), edge);
}

void ssa_init_value_args(ssaValueArgs *va, gbAllocator a) {
	va->e              = va->backing;
	va->count          = 0;
	va->capacity       = gb_count_of(va->backing);
	va->allocator      = a;
}

void ssa_add_arg(ssaValueArgs *va, ssaValue *arg) {
	if (va->count >= va->capacity) {
		isize capacity = 2*va->capacity;
		if (va->e == va->backing) { // Replace the backing with an allocated version instead
			ssaValue **new_args = gb_alloc_array(va->allocator, ssaValue *, capacity);
			gb_memcopy_array(new_args, va->e, va->count);
			va->e = new_args;
		} else {
			isize old_cap_size = va->capacity * gb_size_of(ssaValue *);
			isize new_cap_size = capacity * gb_size_of(ssaValue *);
			va->e = gb_resize(va->allocator, va->e, old_cap_size, new_cap_size);
		}
		va->capacity = capacity;
	}
	va->e[va->count++] = arg; arg->uses++;
}



ssaValue *ssa_new_value(ssaProc *p, ssaOp op, Type *t, ssaBlock *b) {
	ssaValue *v = gb_alloc_item(p->module->allocator, ssaValue);
	v->id    = p->value_id++;
	v->op    = op;
	v->type  = t;
	v->block = b;
	ssa_init_value_args(&v->args, p->module->allocator);
	array_add(&b->values, v);
	return v;
}

ssaValue *ssa_new_value0(ssaBlock *b, ssaOp op, Type *t) {
	ssaValue *v = ssa_new_value(b->proc, op, t, b);
	return v;
}
ssaValue *ssa_new_value0v(ssaBlock *b, ssaOp op, Type *t, ExactValue exact_value) {
	ssaValue *v = ssa_new_value0(b, op, t);
	v->exact_value = exact_value;
	return v;
}

ssaValue *ssa_new_value1(ssaBlock *b, ssaOp op, Type *t, ssaValue *arg) {
	ssaValue *v = ssa_new_value(b->proc, op, t, b);
	ssa_add_arg(&v->args, arg);
	return v;
}
ssaValue *ssa_new_value1v(ssaBlock *b, ssaOp op, Type *t, ExactValue exact_value, ssaValue *arg) {
	ssaValue *v = ssa_new_value1(b, op, t, arg);
	v->exact_value = exact_value;
	return v;
}

ssaValue *ssa_new_value2(ssaBlock *b, ssaOp op, Type *t, ssaValue *arg0, ssaValue *arg1) {
	ssaValue *v = ssa_new_value(b->proc, op, t, b);
	ssa_add_arg(&v->args, arg0);
	ssa_add_arg(&v->args, arg1);
	return v;
}
ssaValue *ssa_new_value2v(ssaBlock *b, ssaOp op, Type *t, ExactValue exact_value, ssaValue *arg0, ssaValue *arg1) {
	ssaValue *v = ssa_new_value2(b, op, t, arg0, arg1);
	v->exact_value = exact_value;
	return v;
}

ssaValue *ssa_new_value3(ssaBlock *b, ssaOp op, Type *t, ssaValue *arg0, ssaValue *arg1, ssaValue *arg2) {
	ssaValue *v = ssa_new_value(b->proc, op, t, b);
	ssa_add_arg(&v->args, arg0);
	ssa_add_arg(&v->args, arg1);
	ssa_add_arg(&v->args, arg2);
	return v;
}
ssaValue *ssa_new_value3v(ssaBlock *b, ssaOp op, Type *t, ExactValue exact_value, ssaValue *arg0, ssaValue *arg1, ssaValue *arg2) {
	ssaValue *v = ssa_new_value3(b, op, t, arg0, arg1, arg2);
	v->exact_value = exact_value;
	return v;
}

ssaValue *ssa_new_value4(ssaBlock *b, ssaOp op, Type *t, ssaValue *arg0, ssaValue *arg1, ssaValue *arg2, ssaValue *arg3) {
	ssaValue *v = ssa_new_value(b->proc, op, t, b);
	ssa_add_arg(&v->args, arg0);
	ssa_add_arg(&v->args, arg1);
	ssa_add_arg(&v->args, arg2);
	ssa_add_arg(&v->args, arg3);
	return v;
}

ssaValue *ssa_const_val(ssaProc *p, ssaOp op, Type *t, ExactValue exact_value) {
	return ssa_new_value0v(p->curr_block, op, t, exact_value);
}

ssaValue *ssa_const_bool        (ssaProc *p, Type *t, bool   c)     { return ssa_const_val(p, ssaOp_ConstBool,   t, exact_value_bool(c)); }
ssaValue *ssa_const_i8          (ssaProc *p, Type *t, i8     c)     { return ssa_const_val(p, ssaOp_Const8,      t, exact_value_integer(cast(i64)c)); }
ssaValue *ssa_const_i16         (ssaProc *p, Type *t, i16    c)     { return ssa_const_val(p, ssaOp_Const16,     t, exact_value_integer(cast(i64)c)); }
ssaValue *ssa_const_i32         (ssaProc *p, Type *t, i32    c)     { return ssa_const_val(p, ssaOp_Const32,     t, exact_value_integer(cast(i64)c)); }
ssaValue *ssa_const_i64         (ssaProc *p, Type *t, i64    c)     { return ssa_const_val(p, ssaOp_Const64,     t, exact_value_integer(cast(i64)c)); }
ssaValue *ssa_const_f32         (ssaProc *p, Type *t, f32    c)     { return ssa_const_val(p, ssaOp_Const32F,    t, exact_value_float(c)); }
ssaValue *ssa_const_f64         (ssaProc *p, Type *t, f64    c)     { return ssa_const_val(p, ssaOp_Const64F,    t, exact_value_float(c)); }
ssaValue *ssa_const_string      (ssaProc *p, Type *t, String c)     { return ssa_const_val(p, ssaOp_ConstString, t, exact_value_string(c)); }
ssaValue *ssa_const_empty_string(ssaProc *p, Type *t)               { return ssa_const_val(p, ssaOp_ConstString, t, (ExactValue){0}); }
ssaValue *ssa_const_slice       (ssaProc *p, Type *t, ExactValue v) { return ssa_const_val(p, ssaOp_ConstSlice,  t, v); }
ssaValue *ssa_const_nil         (ssaProc *p, Type *t)               { return ssa_const_val(p, ssaOp_ConstNil,    t, (ExactValue){0}); }

ssaValue *ssa_const_int(ssaProc *p, Type *t, i64 c) {
	switch (8*type_size_of(p->module->allocator, t)) {
	case 8:  return ssa_const_i8 (p, t, cast(i8)c);
	case 16: return ssa_const_i16(p, t, cast(i16)c);
	case 32: return ssa_const_i32(p, t, cast(i32)c);
	case 64: return ssa_const_i64(p, t, cast(i64)c);
	}
	GB_PANIC("Unknown int size");
	return NULL;
}

void ssa_reset_value_args(ssaValue *v) {
	for_array(i, v->args) {
		v->args.e[i]->uses--;
	}
	v->args.count = 0;
}



bool ssa_is_blank_ident(AstNode *node) {
	if (node->kind == AstNode_Ident) {
		ast_node(i, Ident, node);
		return is_blank_ident(i->string);
	}
	return false;
}


typedef enum ssaAddrKind {
	ssaAddr_Default,
	ssaAddr_Map,
} ssaAddrKind;

typedef struct ssaAddr {
	ssaValue *  addr;
	ssaAddrKind kind;
} ssaAddr;

ssaAddr ssa_addr(ssaValue *v) {
	if (v != NULL) {
		GB_ASSERT(is_type_pointer(v->type));
	}
	ssaAddr addr = {0};
	addr.addr = v;
	return addr;
}

Type *ssa_addr_type(ssaAddr addr) {
	if (addr.addr == NULL) {
		return NULL;
	}

	if (addr.kind == ssaAddr_Map) {
		GB_PANIC("TODO: ssa_addr_type");
		return NULL;
	}

	Type *t = addr.addr->type;
	GB_ASSERT(is_type_pointer(t));
	return type_deref(t);
}



ssaProc *ssa_new_proc(ssaModule *m, String name, Entity *entity, DeclInfo *decl_info) {
	ssaProc *p = gb_alloc_item(m->allocator, ssaProc);
	p->module    = m;
	p->name      = name;
	p->entity    = entity;
	p->decl_info = decl_info;

	array_init(&p->blocks, heap_allocator());
	map_ssa_value_init(&p->values, heap_allocator());

	return p;
}

ssaAddr ssa_add_local(ssaProc *p, Entity *e, AstNode *expr) {
	Type *t = make_type_pointer(p->module->allocator, e->type);
	ssaValue *local = ssa_new_value0(p->entry, ssaOp_Local, t);
	map_ssa_value_set(&p->values,         hash_pointer(e), local);
	map_ssa_value_set(&p->module->values, hash_pointer(e), local);
	local->comment_string = e->token.string;

	ssaValue *addr = ssa_new_value1(p->curr_block, ssaOp_Addr, local->type, local);
	ssa_new_value1(p->curr_block, ssaOp_Zero, t, addr);
	return ssa_addr(addr);
}
ssaAddr ssa_add_local_for_ident(ssaProc *p, AstNode *name) {
	Entity **found = map_entity_get(&p->module->info->definitions, hash_pointer(name));
	if (found) {
		Entity *e = *found;
		return ssa_add_local(p, e, name);
	}

	return ssa_addr(NULL);
}

ssaAddr ssa_add_local_generated(ssaProc *p, Type *t) {
	GB_ASSERT(t != NULL);

	Scope *scope = NULL;
	if (p->curr_block) {
		// scope = p->curr_block->scope;
	}
	Entity *e = make_entity_variable(p->module->allocator, scope, empty_token, t, false);
	return ssa_add_local(p, e, NULL);
}

void ssa_emit_comment(ssaProc *p, String s) {
	// ssa_new_value0v(p->curr_block, ssaOp_Comment, NULL, exact_value_string(s));
}

#define SSA_MAX_STRUCT_FIELD_COUNT 4

bool can_ssa_type(Type *t) {
	i64 s = type_size_of(heap_allocator(), t);
	if (s > 4*build_context.word_size) {
		return false;
	}
	t = core_type(t);

	switch (t->kind) {
	case Type_Array:
		return t->Array.count == 0;
	case Type_Vector:
		return s < 2*build_context.word_size;

	case Type_DynamicArray:
		return false;
	case Type_Map:
		return false;
	case Type_Tuple:
		if (t->Tuple.variable_count > SSA_MAX_STRUCT_FIELD_COUNT) {
			return false;
		}
		for (isize i = 0; i < t->Tuple.variable_count; i++) {
			if (!can_ssa_type(t->Tuple.variables[i]->type)) {
				return false;
			}
		}
		return true;
	case Type_Record:
		if (t->Record.kind == TypeRecord_Union) {
			return false;
		} else if (t->Record.kind == TypeRecord_Struct) {
			if (t->Record.field_count > SSA_MAX_STRUCT_FIELD_COUNT) {
				return false;
			}
			for (isize i = 0; i < t->Record.field_count; i++) {
				if (!can_ssa_type(t->Record.fields[i]->type)) {
					return false;
				}
			}
		}
		return true;
	}
	return true;
}



void ssa_build_stmt(ssaProc *p, AstNode *node);
void ssa_build_stmt_list(ssaProc *p, AstNodeArray nodes);

void ssa_addr_store(ssaProc *p, ssaAddr addr, ssaValue *value) {
	if (addr.addr == NULL) {
		return;
	}
	if (addr.kind == ssaAddr_Map) {
		GB_PANIC("TODO(bill): ssa_addr_store");
		return;
	}

	ssa_new_value2(p->curr_block, ssaOp_Store, addr.addr->type, addr.addr, value);
}

ssaValue *ssa_addr_load(ssaProc *p, ssaAddr addr) {
	if (addr.addr == NULL) {
		return NULL;
	}

	if (addr.kind == ssaAddr_Map) {
		GB_PANIC("here\n");
		return NULL;
	}

	Type *t = addr.addr->type;
	Type *bt = base_type(t);
	if (bt->kind == Type_Proc) {
		return addr.addr;
	}

	return ssa_new_value1(p->curr_block, ssaOp_Load, type_deref(t), addr.addr);
}

ssaValue *ssa_get_using_variable(ssaProc *p, Entity *e) {
	GB_PANIC("TODO(bill): ssa_get_using_variable");
	return NULL;
	// GB_ASSERT(e->kind == Entity_Variable && e->flags & EntityFlag_Anonymous);
	// String name = e->token.string;
	// Entity *parent = e->using_parent;
	// Selection sel = lookup_field(proc->module->allocator, parent->type, name, false);
	// GB_ASSERT(sel.entity != NULL);
	// irValue **pv = map_ir_value_get(&proc->module->values, hash_pointer(parent));
	// irValue *v = NULL;
	// if (pv != NULL) {
	// 	v = *pv;
	// } else {
	// 	v = ir_build_addr(proc, e->using_expr).addr;
	// }
	// GB_ASSERT(v != NULL);
	// return ir_emit_deep_field_gep(proc, parent->type, v, sel);
}

ssaAddr ssa_build_addr_from_entity(ssaProc *p, Entity *e, AstNode *expr) {
	GB_ASSERT(e != NULL);

	ssaValue *v = NULL;
	ssaValue **found = map_ssa_value_get(&p->module->values, hash_pointer(e));
	if (found) {
		v = *found;
	} else if (e->kind == Entity_Variable && e->flags & EntityFlag_Anonymous) {
		// NOTE(bill): Calculate the using variable every time
		v = ssa_get_using_variable(p, e);
	}

	if (v == NULL) {
		GB_PANIC("Unknown value: %.*s, entity: %p %.*s\n", LIT(e->token.string), e, LIT(entity_strings[e->kind]));
	}

	return ssa_addr(v);
}

ssaAddr ssa_build_addr(ssaProc *p, AstNode *expr) {
	switch (expr->kind) {
	case_ast_node(i, Ident, expr);
		if (ssa_is_blank_ident(expr)) {
			ssaAddr val = {0};
			return val;
		}
		Entity *e = entity_of_ident(p->module->info, expr);
		return ssa_build_addr_from_entity(p, e, expr);
	case_end;

	case_ast_node(pe, ParenExpr, expr);
		return ssa_build_addr(p, unparen_expr(expr));
	case_end;
	}

	GB_PANIC("Cannot get entity's address");
	return ssa_addr(NULL);
}


Type *ssa_proper_type(Type *t) {
	t = default_type(core_type(t));

	if (t->kind == Type_Basic) {
		switch (t->Basic.kind) {
		case Basic_int:
			if (build_context.word_size == 8) {
				return t_i64;
			}
			return t_i32;
		case Basic_uint:
			if (build_context.word_size == 8) {
				return t_u64;
			}
			return t_u32;
		}
	}

	return t;
}

ssaOp ssa_determine_op(TokenKind op, Type *t) {
	t = ssa_proper_type(t);
	if (t->kind == Type_Basic) {
		switch (t->Basic.kind) {
		case Basic_bool:
			switch (op) {
			case Token_And:    return ssaOp_And8;
			case Token_Or:     return ssaOp_Or8;
			case Token_Xor:    return ssaOp_Xor8;
			case Token_AndNot: return ssaOp_AndNot8;
			}
			break;
		case Basic_i8:
			switch (op) {
			case Token_Add:    return ssaOp_Add8;
			case Token_Sub:    return ssaOp_Sub8;
			case Token_Mul:    return ssaOp_Mul8;
			case Token_Quo:    return ssaOp_Div8;
			case Token_Mod:    return ssaOp_Mod8;
			case Token_And:    return ssaOp_And8;
			case Token_Or:     return ssaOp_Or8;
			case Token_Xor:    return ssaOp_Xor8;
			case Token_AndNot: return ssaOp_AndNot8;
			case Token_Lt:     return ssaOp_Lt8;
			case Token_LtEq:   return ssaOp_Le8;
			case Token_Gt:     return ssaOp_Gt8;
			case Token_GtEq:   return ssaOp_Ge8;
			case Token_CmpEq:  return ssaOp_Eq8;
			case Token_NotEq:  return ssaOp_Ne8;
			}
			break;
		case Basic_u8:
			switch (op) {
			case Token_Add:    return ssaOp_Add8;
			case Token_Sub:    return ssaOp_Sub8;
			case Token_Mul:    return ssaOp_Mul8;
			case Token_Quo:    return ssaOp_Div8U;
			case Token_Mod:    return ssaOp_Mod8U;
			case Token_And:    return ssaOp_And8;
			case Token_Or:     return ssaOp_Or8;
			case Token_Xor:    return ssaOp_Xor8;
			case Token_AndNot: return ssaOp_AndNot8;
			case Token_Lt:     return ssaOp_Lt8;
			case Token_LtEq:   return ssaOp_Le8;
			case Token_Gt:     return ssaOp_Gt8;
			case Token_GtEq:   return ssaOp_Ge8;
			case Token_CmpEq:  return ssaOp_Eq8;
			case Token_NotEq:  return ssaOp_Ne8;
			}
			break;
		case Basic_i16:
			switch (op) {
			case Token_Add:    return ssaOp_Add16;
			case Token_Sub:    return ssaOp_Sub16;
			case Token_Mul:    return ssaOp_Mul16;
			case Token_Quo:    return ssaOp_Div16;
			case Token_Mod:    return ssaOp_Mod16;
			case Token_And:    return ssaOp_And16;
			case Token_Or:     return ssaOp_Or16;
			case Token_Xor:    return ssaOp_Xor16;
			case Token_AndNot: return ssaOp_AndNot16;
			case Token_Lt:     return ssaOp_Lt16;
			case Token_LtEq:   return ssaOp_Le16;
			case Token_Gt:     return ssaOp_Gt16;
			case Token_GtEq:   return ssaOp_Ge16;
			case Token_CmpEq:  return ssaOp_Eq16;
			case Token_NotEq:  return ssaOp_Ne16;
			}
			break;
		case Basic_u16:
			switch (op) {
			case Token_Add:    return ssaOp_Add16;
			case Token_Sub:    return ssaOp_Sub16;
			case Token_Mul:    return ssaOp_Mul16;
			case Token_Quo:    return ssaOp_Div16U;
			case Token_Mod:    return ssaOp_Mod16U;
			case Token_And:    return ssaOp_And16;
			case Token_Or:     return ssaOp_Or16;
			case Token_Xor:    return ssaOp_Xor16;
			case Token_AndNot: return ssaOp_AndNot16;
			case Token_Lt:     return ssaOp_Lt16;
			case Token_LtEq:   return ssaOp_Le16;
			case Token_Gt:     return ssaOp_Gt16;
			case Token_GtEq:   return ssaOp_Ge16;
			case Token_CmpEq:  return ssaOp_Eq16;
			case Token_NotEq:  return ssaOp_Ne16;
			}
			break;
		case Basic_i32:
			switch (op) {
			case Token_Add:    return ssaOp_Add32;
			case Token_Sub:    return ssaOp_Sub32;
			case Token_Mul:    return ssaOp_Mul32;
			case Token_Quo:    return ssaOp_Div32;
			case Token_Mod:    return ssaOp_Mod32;
			case Token_And:    return ssaOp_And32;
			case Token_Or:     return ssaOp_Or32;
			case Token_Xor:    return ssaOp_Xor32;
			case Token_AndNot: return ssaOp_AndNot32;
			case Token_Lt:     return ssaOp_Lt32;
			case Token_LtEq:   return ssaOp_Le32;
			case Token_Gt:     return ssaOp_Gt32;
			case Token_GtEq:   return ssaOp_Ge32;
			case Token_CmpEq:  return ssaOp_Eq32;
			case Token_NotEq:  return ssaOp_Ne32;
			}
			break;
		case Basic_u32:
			switch (op) {
			case Token_Add:    return ssaOp_Add32;
			case Token_Sub:    return ssaOp_Sub32;
			case Token_Mul:    return ssaOp_Mul32;
			case Token_Quo:    return ssaOp_Div32U;
			case Token_Mod:    return ssaOp_Mod32U;
			case Token_And:    return ssaOp_And32;
			case Token_Or:     return ssaOp_Or32;
			case Token_Xor:    return ssaOp_Xor32;
			case Token_AndNot: return ssaOp_AndNot32;
			case Token_Lt:     return ssaOp_Lt32;
			case Token_LtEq:   return ssaOp_Le32;
			case Token_Gt:     return ssaOp_Gt32;
			case Token_GtEq:   return ssaOp_Ge32;
			case Token_CmpEq:  return ssaOp_Eq32;
			case Token_NotEq:  return ssaOp_Ne32;
			}
			break;
		case Basic_i64:
			switch (op) {
			case Token_Add:    return ssaOp_Add64;
			case Token_Sub:    return ssaOp_Sub64;
			case Token_Mul:    return ssaOp_Mul64;
			case Token_Quo:    return ssaOp_Div64;
			case Token_Mod:    return ssaOp_Mod64;
			case Token_And:    return ssaOp_And64;
			case Token_Or:     return ssaOp_Or64;
			case Token_Xor:    return ssaOp_Xor64;
			case Token_AndNot: return ssaOp_AndNot64;
			case Token_Lt:     return ssaOp_Lt64;
			case Token_LtEq:   return ssaOp_Le64;
			case Token_Gt:     return ssaOp_Gt64;
			case Token_GtEq:   return ssaOp_Ge64;
			case Token_CmpEq:  return ssaOp_Eq64;
			case Token_NotEq:  return ssaOp_Ne64;
			}
			break;
		case Basic_u64:
			switch (op) {
			case Token_Add:    return ssaOp_Add64;
			case Token_Sub:    return ssaOp_Sub64;
			case Token_Mul:    return ssaOp_Mul64;
			case Token_Quo:    return ssaOp_Div64U;
			case Token_Mod:    return ssaOp_Mod64U;
			case Token_And:    return ssaOp_And64;
			case Token_Or:     return ssaOp_Or64;
			case Token_Xor:    return ssaOp_Xor64;
			case Token_AndNot: return ssaOp_AndNot64;
			case Token_Lt:     return ssaOp_Lt64;
			case Token_LtEq:   return ssaOp_Le64;
			case Token_Gt:     return ssaOp_Gt64;
			case Token_GtEq:   return ssaOp_Ge64;
			case Token_CmpEq:  return ssaOp_Eq64;
			case Token_NotEq:  return ssaOp_Ne64;
			}
			break;
		case Basic_f32:
			switch (op) {
			case Token_Add:    return ssaOp_Add32F;
			case Token_Sub:    return ssaOp_Sub32F;
			case Token_Mul:    return ssaOp_Mul32F;
			case Token_Quo:    return ssaOp_Div32F;
			case Token_Lt:     return ssaOp_Lt32F;
			case Token_LtEq:   return ssaOp_Le32F;
			case Token_Gt:     return ssaOp_Gt32F;
			case Token_GtEq:   return ssaOp_Ge32F;
			case Token_CmpEq:  return ssaOp_Eq32F;
			case Token_NotEq:  return ssaOp_Ne32F;
			}
			break;
		case Basic_f64:
			switch (op) {
			case Token_Add:    return ssaOp_Add64F;
			case Token_Sub:    return ssaOp_Sub64F;
			case Token_Mul:    return ssaOp_Mul64F;
			case Token_Quo:    return ssaOp_Div64F;
			case Token_Lt:     return ssaOp_Lt64F;
			case Token_LtEq:   return ssaOp_Le64F;
			case Token_Gt:     return ssaOp_Gt64F;
			case Token_GtEq:   return ssaOp_Ge64F;
			case Token_CmpEq:  return ssaOp_Eq64F;
			case Token_NotEq:  return ssaOp_Ne64F;
			}
			break;
		}
	}

	GB_PANIC("Invalid Op for type");
	return ssaOp_Invalid;
}

ssaValue *ssa_build_expr(ssaProc *p, AstNode *expr) {
	expr = unparen_expr(expr);

	TypeAndValue *tv = map_tav_get(&p->module->info->types, hash_pointer(expr));
	GB_ASSERT_NOT_NULL(tv);

	if (tv->value.kind != ExactValue_Invalid) {
		Type *t = core_type(tv->type);
		if (is_type_boolean(t)) {
			return ssa_const_bool(p, tv->type, tv->value.value_bool);
		} else if (is_type_string(t)) {
			GB_ASSERT(tv->value.kind == ExactValue_String);
			return ssa_const_string(p, tv->type, tv->value.value_string);
		} else if(is_type_slice(t)) {
			return ssa_const_slice(p, tv->type, tv->value);
		} else if (is_type_integer(t)) {
			GB_ASSERT(tv->value.kind == ExactValue_Integer);

			i64 s = 8*type_size_of(p->module->allocator, t);
			switch (s) {
			case 8:  return ssa_const_i8 (p, tv->type, tv->value.value_integer);
			case 16: return ssa_const_i16(p, tv->type, tv->value.value_integer);
			case 32: return ssa_const_i32(p, tv->type, tv->value.value_integer);
			case 64: return ssa_const_i64(p, tv->type, tv->value.value_integer);
			default: GB_PANIC("Unknown integer size");
			}
		} else if (is_type_float(t)) {
			GB_ASSERT(tv->value.kind == ExactValue_Float);
			i64 s = 8*type_size_of(p->module->allocator, t);
			switch (s) {
			case 32: return ssa_const_f32(p, tv->type, tv->value.value_float);
			case 64: return ssa_const_f64(p, tv->type, tv->value.value_float);
			default: GB_PANIC("Unknown float size");
			}
		}
		// IMPORTANT TODO(bill): Do constant record/array literals correctly
		return ssa_const_nil(p, tv->type);
	}

	if (tv->mode == Addressing_Variable) {
		return ssa_addr_load(p, ssa_build_addr(p, expr));
	}


	switch (expr->kind) {
	case_ast_node(bl, BasicLit, expr);
		GB_PANIC("Non-constant basic literal");
	case_end;

	case_ast_node(bd, BasicDirective, expr);
		TokenPos pos = bd->token.pos;
		GB_PANIC("Non-constant basic literal %.*s(%td:%td) - %.*s", LIT(pos.file), pos.line, pos.column, LIT(bd->name));
	case_end;

	case_ast_node(i, Ident, expr);
		Entity *e = *map_entity_get(&p->module->info->uses, hash_pointer(expr));
		if (e->kind == Entity_Builtin) {
			Token token = ast_node_token(expr);
			GB_PANIC("TODO(bill): ssa_build_expr Entity_Builtin `%.*s`\n"
			         "\t at %.*s(%td:%td)", LIT(builtin_procs[e->Builtin.id].name),
			         LIT(token.pos.file), token.pos.line, token.pos.column);
			return NULL;
		} else if (e->kind == Entity_Nil) {
			GB_PANIC("TODO(bill): nil");
			return NULL;
		}

		ssaValue **found = map_ssa_value_get(&p->module->values, hash_pointer(e));
		if (found) {
			ssaValue *v = *found;
			if (v->op == ssaOp_Proc) {
				return v;
			}

			ssaAddr addr = ssa_build_addr(p, expr);
			return ssa_addr_load(p, addr);
		}
	case_end;

	case_ast_node(ue, UnaryExpr, expr);
		switch (ue->op.kind) {
		case Token_Pointer: {
			ssaValue *ptr = ssa_build_addr(p, ue->expr).addr;
			return ssa_new_value1(p->curr_block, ssaOp_Copy, tv->type, ptr);
		} break;

		case Token_Add:
			return ssa_build_expr(p, ue->expr);

		case Token_Not: // Boolean not
			return ssa_new_value1(p->curr_block, ssaOp_NotB, tv->type, ssa_build_expr(p, ue->expr));
		case Token_Xor: { // Bitwise not
			ssaValue *x = ssa_build_expr(p, ue->expr);
			isize bits = 8*type_size_of(p->module->allocator, x->type);
			switch (bits) {
			case  8: return ssa_new_value1(p->curr_block, ssaOp_Not8,  tv->type, x);
			case 16: return ssa_new_value1(p->curr_block, ssaOp_Not16, tv->type, x);
			case 32: return ssa_new_value1(p->curr_block, ssaOp_Not32, tv->type, x);
			case 64: return ssa_new_value1(p->curr_block, ssaOp_Not64, tv->type, x);
			}
			GB_PANIC("unknown integer size");
		} break;

		case Token_Sub: { // 0-x
			ssaValue *x = ssa_build_expr(p, ue->expr);
			isize bits = 8*type_size_of(p->module->allocator, x->type);
			if (is_type_integer(x->type)) {
				switch (bits) {
				case  8: return ssa_new_value1(p->curr_block, ssaOp_Neg8,  tv->type, x);
				case 16: return ssa_new_value1(p->curr_block, ssaOp_Neg16, tv->type, x);
				case 32: return ssa_new_value1(p->curr_block, ssaOp_Neg32, tv->type, x);
				case 64: return ssa_new_value1(p->curr_block, ssaOp_Neg64, tv->type, x);
				}
			} else if (is_type_float(x->type)) {
				switch (bits) {
				case 32: return ssa_new_value1(p->curr_block, ssaOp_Neg32F, tv->type, x);
				case 64: return ssa_new_value1(p->curr_block, ssaOp_Neg64F, tv->type, x);
				}
			}
			GB_PANIC("unknown type for -x");
		} break;
		}
	case_end;

	case_ast_node(be, BinaryExpr, expr);
		Type *type = default_type(tv->type);

		switch (be->op.kind) {
		case Token_Add:
		case Token_Sub:
		case Token_Mul:
		case Token_Quo:
		case Token_Mod:
		case Token_And:
		case Token_Or:
		case Token_Xor:
		case Token_AndNot: {
			ssaValue *x = ssa_build_expr(p, be->left);
			ssaValue *y = ssa_build_expr(p, be->right);
			GB_ASSERT(x != NULL && y != NULL);
			return ssa_new_value2(p->curr_block, ssa_determine_op(be->op.kind, x->type), tv->type, x, y);
		}

		case Token_Shl:
		case Token_Shr: {
			GB_PANIC("TODO: shifts");
			return NULL;
		}

		case Token_CmpEq:
		case Token_NotEq:
		case Token_Lt:
		case Token_LtEq:
		case Token_Gt:
		case Token_GtEq: {
			ssaValue *x = ssa_build_expr(p, be->left);
			ssaValue *y = ssa_build_expr(p, be->right);
			GB_ASSERT(x != NULL && y != NULL);
			return ssa_new_value2(p->curr_block, ssa_determine_op(be->op.kind, x->type), tv->type, x, y);
		} break;

		case Token_CmpAnd:
		case Token_CmpOr:
			GB_PANIC("TODO: inline && and ||");
			return NULL;
			// return ir_emit_logical_binary_expr(proc, expr);

		default:
			GB_PANIC("Invalid binary expression");
			break;
		}
	case_end;
	}


	return NULL;
}



void ssa_build_stmt_list(ssaProc *p, AstNodeArray nodes) {
	for_array(i, nodes) {
		ssa_build_stmt(p, nodes.e[i]);
	}
}


ssaValue *ssa_emit_struct_ep(ssaProc *p, ssaValue *ptr, i32 index) {
	GB_ASSERT(ptr->type != NULL);
	GB_ASSERT(is_type_pointer(ptr->type));
	return NULL;
}


ssaValue *ssa_build_cond(ssaProc *p, AstNode *cond, ssaBlock *yes, ssaBlock *no) {
	switch (cond->kind) {
	case_ast_node(pe, ParenExpr, cond);
		return ssa_build_cond(p, pe->expr, yes, no);
	case_end;

	case_ast_node(ue, UnaryExpr, cond);
		if (ue->op.kind == Token_Not) {
			return ssa_build_cond(p, ue->expr, no, yes);
		}
	case_end;

	case_ast_node(be, BinaryExpr, cond);
		if (be->op.kind == Token_CmpAnd) {
			ssaBlock *block = ssa_new_block(p, ssaBlock_Plain, "cmd.and");
			ssa_build_cond(p, be->left, block, no);
			ssa_start_block(p, block);
			return ssa_build_cond(p, be->right, yes, no);
		} else if (be->op.kind == Token_CmpOr) {
			ssaBlock *block = ssa_new_block(p, ssaBlock_Plain, "cmp.or");
			ssa_build_cond(p, be->left, yes, block);
			ssa_start_block(p, block);
			return ssa_build_cond(p, be->right, yes, no);
		}
	case_end;
	}

	ssaValue *c = ssa_build_expr(p, cond);
	ssaBlock *b = ssa_end_block(p);
	b->kind = ssaBlock_If;
	ssa_set_control(b, c);
	ssa_add_edge_to(b, yes);
	ssa_add_edge_to(b, no);
	return c;
}

void ssa_build_when_stmt(ssaProc *p, AstNodeWhenStmt *ws) {
	ssaValue *cond = ssa_build_expr(p, ws->cond);
	GB_ASSERT(is_type_boolean(cond->type));

	GB_ASSERT(cond->exact_value.kind == ExactValue_Bool);
	if (cond->exact_value.value_bool) {
		ssa_build_stmt_list(p, ws->body->BlockStmt.stmts);
	} else if (ws->else_stmt) {
		switch (ws->else_stmt->kind) {
		case AstNode_BlockStmt:
			ssa_build_stmt_list(p, ws->else_stmt->BlockStmt.stmts);
			break;
		case AstNode_WhenStmt:
			ssa_build_when_stmt(p, &ws->else_stmt->WhenStmt);
			break;
		default:
			GB_PANIC("Invalid `else` statement in `when` statement");
			break;
		}
	}
}

void ssa_build_assign_op(ssaProc *p, ssaAddr lhs, ssaValue *value, TokenKind op) {
	// ssaValue *old_value = ssa_addr_load(p, lhs);
	// Type *type = old_value->type;

	// ssaValue *change = value;
	// if (is_type_pointer(type) && is_type_integer(value->type)) {
	// 	change = ssa_emit_conv(p, value, default_type(value->type));
	// } else {
	// 	change = ssa_emit_conv(p, value, type);
	// }
	// ssaValue *new_value = ssa_emit_arith(p, op, old_value, change, type);
	// ssa_addr_store(p, lhs, new_value);
}


void ssa_build_stmt(ssaProc *p, AstNode *node) {
	if (p->curr_block == NULL) {
		ssaBlock *dead_block = ssa_new_block(p, ssaBlock_Plain, "");
		ssa_start_block(p, dead_block);
	}

	switch (node->kind) {
	case_ast_node(es, EmptyStmt, node);
	case_end;

	case_ast_node(bs, BlockStmt, node);
		ssa_build_stmt_list(p, bs->stmts);
	case_end;

	case_ast_node(us, UsingStmt, node);
		AstNode *decl = unparen_expr(us->node);
		if (decl->kind == AstNode_ValueDecl) {
			ssa_build_stmt(p, decl);
		}
	case_end;

	case_ast_node(ws, WhenStmt, node);
		ssa_build_when_stmt(p, ws);
	case_end;

	case_ast_node(s, IncDecStmt, node);
		TokenKind op = Token_Add;
		if (s->op.kind == Token_Dec) {
			op = Token_Sub;
		}
		ssaAddr addr = ssa_build_addr(p, s->expr);
		Type *t = ssa_addr_type(addr);
		ssa_build_assign_op(p, addr, ssa_const_int(p, t, 1), op);
	case_end;

	case_ast_node(vd, ValueDecl, node);
		if (vd->is_var) {
			ssaModule *m = p->module;
			gbTempArenaMemory tmp = gb_temp_arena_memory_begin(&m->tmp_arena);
			if (vd->values.count == 0) {
				for_array(i, vd->names) {
					AstNode *name = vd->names.e[i];
					if (!ssa_is_blank_ident(name)) {
						ssa_add_local_for_ident(p, name);
					}
				}
			} else {
				Array(ssaAddr) lvals = {0};
				ssaValueArray  inits = {0};
				array_init_reserve(&lvals, m->tmp_allocator, vd->names.count);
				array_init_reserve(&inits, m->tmp_allocator, vd->names.count);

				for_array(i, vd->names) {
					AstNode *name = vd->names.e[i];
					ssaAddr lval = ssa_addr(NULL);
					if (!ssa_is_blank_ident(name)) {
						lval = ssa_add_local_for_ident(p, name);
					}

					array_add(&lvals, lval);
				}

				for_array(i, vd->values) {
					ssaValue *init = ssa_build_expr(p, vd->values.e[i]);
					if (init == NULL) { // TODO(bill): remove this
						continue;
					}
					Type *t = type_deref(init->type);
					if (init->op == ssaOp_Addr && t->kind == Type_Tuple) {
						for (isize i = 0; i < t->Tuple.variable_count; i++) {
							Entity *e = t->Tuple.variables[i];
							ssaValue *v = ssa_emit_struct_ep(p, init, i);
							array_add(&inits, v);
						}
					} else {
						array_add(&inits, init);
					}
				}

				for_array(i, inits) {
					ssa_addr_store(p, lvals.e[i], inits.e[i]);
				}
			}

			gb_temp_arena_memory_end(tmp);
		}
	case_end;

	case_ast_node(as, AssignStmt, node);
		ssa_emit_comment(p, str_lit("AssignStmt"));

		ssaModule *m = p->module;
		gbTempArenaMemory tmp = gb_temp_arena_memory_begin(&m->tmp_arena);

		switch (as->op.kind) {
		case Token_Eq: {
			Array(ssaAddr) lvals = {0};
			array_init(&lvals, m->tmp_allocator);

			for_array(i, as->lhs) {
				AstNode *lhs = as->lhs.e[i];
				ssaAddr lval = {0};
				if (!ssa_is_blank_ident(lhs)) {
					lval = ssa_build_addr(p, lhs);
				}
				array_add(&lvals, lval);
			}

			if (as->lhs.count == as->rhs.count) {
				if (as->lhs.count == 1) {
					AstNode *rhs = as->rhs.e[0];
					ssaValue *init = ssa_build_expr(p, rhs);
					ssa_addr_store(p, lvals.e[0], init);
				} else {
					ssaValueArray inits;
					array_init_reserve(&inits, m->tmp_allocator, lvals.count);

					for_array(i, as->rhs) {
						ssaValue *init = ssa_build_expr(p, as->rhs.e[i]);
						array_add(&inits, init);
					}

					for_array(i, inits) {
						ssa_addr_store(p, lvals.e[i], inits.e[i]);
					}
				}
			} else {
				ssaValueArray inits;
				array_init_reserve(&inits, m->tmp_allocator, lvals.count);

				for_array(i, as->rhs) {
					ssaValue *init = ssa_build_expr(p, as->rhs.e[i]);
					Type *t = type_deref(init->type);
					// TODO(bill): refactor for code reuse as this is repeated a bit
					if (init->op == ssaOp_Addr && t->kind == Type_Tuple) {
						for (isize i = 0; i < t->Tuple.variable_count; i++) {
							Entity *e = t->Tuple.variables[i];
							ssaValue *v = ssa_emit_struct_ep(p, init, i);
							array_add(&inits, v);
						}
					} else {
						array_add(&inits, init);
					}
				}

				for_array(i, inits) {
					ssa_addr_store(p, lvals.e[i], inits.e[i]);
				}
			}
		} break;

		default: {
			GB_PANIC("TODO(bill): assign operations");
			// NOTE(bill): Only 1 += 1 is allowed, no tuples
			// +=, -=, etc
			// i32 op = cast(i32)as->op.kind;
			// op += Token_Add - Token_AddEq; // Convert += to +
			// ssaAddr lhs = ssa_build_addr(p, as->lhs.e[0]);
			// ssaValue *value = ssa_build_expr(p, as->rhs.e[0]);
			// ssa_build_assign_op(p, lhs, value, cast(TokenKind)op);
		} break;
		}

		gb_temp_arena_memory_end(tmp);
	case_end;

	case_ast_node(es, ExprStmt, node);
		// NOTE(bill): No need to use return value
		ssa_build_expr(p, es->expr);
	case_end;

	case_ast_node(ds, DeferStmt, node);
		GB_PANIC("TODO: DeferStmt");
	case_end;

	case_ast_node(rs, ReturnStmt, node);
		GB_PANIC("TODO: ReturnStmt");
	case_end;

	case_ast_node(is, IfStmt, node);
		ssa_emit_comment(p, str_lit("IfStmt"));
		if (is->init != NULL) {
			ssaBlock *init = ssa_new_block(p, ssaBlock_Plain, "if.init");
			ssa_emit_jump(p, init);
			ssa_start_block(p, init);
			ssa_build_stmt(p, is->init);
		}
		ssaBlock *then  = ssa_new_block(p, ssaBlock_Plain, "if.then");
		ssaBlock *done  = ssa_new_block(p, ssaBlock_Plain, "if.done");
		ssaBlock *else_ = done;
		if (is->else_stmt != NULL) {
			else_ = ssa_new_block(p, ssaBlock_Plain, "if.else");
		}
		ssaBlock *b = NULL;

		ssa_build_cond(p, is->cond, then, else_);
		ssa_start_block(p, then);

		// ssa_open_scope(p);
		ssa_build_stmt(p, is->body);
		// ssa_close_scope(p, ssaDeferExit_Default, NULL);

		ssa_emit_jump(p, done);

		if (is->else_stmt != NULL) {
			ssa_start_block(p, else_);

			// ssa_open_scope(p);
			ssa_build_stmt(p, is->else_stmt);
			// ssa_close_scope(p, ssaDeferExit_Default, NULL);

			ssa_emit_jump(p, done);
		}

		ssa_start_block(p, done);
	case_end;


	case_ast_node(fs, ForStmt, node);
		ssa_emit_comment(p, str_lit("ForStmt"));
		if (fs->init != NULL) {
			ssaBlock *init = ssa_new_block(p, ssaBlock_Plain, "for.init");
			ssa_emit_jump(p, init);
			ssa_start_block(p, init);
			ssa_build_stmt(p, fs->init);
		}

		ssaBlock *body = ssa_new_block(p, ssaBlock_Plain, "for.body");
		ssaBlock *done = ssa_new_block(p, ssaBlock_Plain, "for.done");
		ssaBlock *loop = body;
		if (fs->cond != NULL) {
			loop = ssa_new_block(p, ssaBlock_Plain, "for.loop");
		}
		ssaBlock *post = loop;
		if (fs->post != NULL) {
			post = ssa_new_block(p, ssaBlock_Plain, "for.post");
		}

		ssa_emit_jump(p, loop);
		ssa_start_block(p, loop);

		if (loop != body) {
			ssa_build_cond(p, fs->cond, body, done);
			ssa_start_block(p, body);
		}

		ssa_push_target_list(p, done, post, NULL);
		// ssa_open_scope(p);
		ssa_build_stmt(p, fs->body);
		// ssa_close_scope(p, ssaDeferExit_Default, NULL);
		ssa_pop_target_list(p);

		ssa_emit_jump(p, post);

		if (fs->post != NULL) {
			ssa_start_block(p, post);
			ssa_build_stmt(p, fs->post);
			ssa_emit_jump(p, post);
		}

		ssa_start_block(p, done);
	case_end;

	case_ast_node(rs, RangeStmt, node);
		GB_PANIC("TODO: RangeStmt");
	case_end;

	case_ast_node(rs, MatchStmt, node);
		GB_PANIC("TODO: MatchStmt");
	case_end;

	case_ast_node(rs, TypeMatchStmt, node);
		GB_PANIC("TODO: TypeMatchStmt");
	case_end;

	case_ast_node(bs, BranchStmt, node);
		ssaBlock *b = NULL;
		switch (bs->token.kind) {
		case Token_break:
			for (ssaTargetList *t = p->target_list; t != NULL && b == NULL; t = t->prev) {
				b = t->break_;
			}
			break;
		case Token_continue:
			for (ssaTargetList *t = p->target_list; t != NULL && b == NULL; t = t->prev) {
				b = t->continue_;
			}
			break;
		case Token_fallthrough:
			for (ssaTargetList *t = p->target_list; t != NULL && b == NULL; t = t->prev) {
				b = t->fallthrough_;
			}
			break;
		}
		if (b != NULL) {
			// ssa_emit_defer_stmts(p, irDeferExit_Branch, b);
		}
		switch (bs->token.kind) {
		case Token_break:       ssa_emit_comment(p, str_lit("break"));       break;
		case Token_continue:    ssa_emit_comment(p, str_lit("continue"));    break;
		case Token_fallthrough: ssa_emit_comment(p, str_lit("fallthrough")); break;
		}
		ssa_emit_jump(p, b);
	case_end;

	case_ast_node(pa, PushAllocator, node);
		GB_PANIC("TODO: PushAllocator");
	case_end;
	case_ast_node(pc, PushContext, node);
		GB_PANIC("TODO: PushContext");
	case_end;
	}
}

void ssa_print_value(gbFile *f, ssaValue *v) {
	if (v == NULL) {
		gb_fprintf(f, "nil");
	}
	gb_fprintf(f, "v%d", v->id);
}

void ssa_print_exact_value(gbFile *f, ssaValue *v) {
	Type *t = default_type(v->type);
	ExactValue ev = v->exact_value;
	switch (ev.kind) {
	case ExactValue_Bool:
		if (ev.value_bool == false) {
			gb_fprintf(f, " [false]");
		} else {
			gb_fprintf(f, " [true]");
		}
		break;
	case ExactValue_Integer:
		if (is_type_unsigned(t)) {
			gb_fprintf(f, " [%llu]", ev.value_integer);
		} else {
			gb_fprintf(f, " [%lld]", ev.value_integer);
		}
		break;
	case ExactValue_Float:
		if (is_type_f32(t)) {
			f32 fp = cast(f32)ev.value_float;
			u32 x = *cast(u32 *)&fp;
			gb_fprintf(f, " [0x%x]", x);
		} else if (is_type_f64(t)) {
			f64 fp = cast(f64)ev.value_float;
			u64 x = *cast(u64 *)&fp;
			gb_fprintf(f, " [0x%llx]", x);
		} else {
			GB_PANIC("unhandled integer");
		}
		break;
	case ExactValue_String:
		gb_fprintf(f, " [%.*s]", LIT(ev.value_string));
		break;
	case ExactValue_Pointer:
		gb_fprintf(f, " [0x%llx]", ev.value_pointer);
		break;
	}
}


void ssa_print_reg_value(gbFile *f, ssaValue *v) {
	gb_fprintf(f, "    ");
	gb_fprintf(f, "v%d = %.*s", v->id, LIT(ssa_op_strings[v->op]));

	if (v->type != NULL) {
		gbString type_str = type_to_string(default_type(v->type));
		gb_fprintf(f, " %s", type_str);
		gb_string_free(type_str);
	}

	ssa_print_exact_value(f, v);

	for_array(i, v->args) {
		gb_fprintf(f, " ");
		ssa_print_value(f, v->args.e[i]);
	}

	if (v->comment_string.len > 0) {
		gb_fprintf(f, " ; %.*s", LIT(v->comment_string));
	}

	gb_fprintf(f, "\n");

}

void ssa_print_proc(gbFile *f, ssaProc *p) {
	gbString type_str = type_to_string(p->entity->type);
	gb_fprintf(f, "%.*s %s\n", LIT(p->name), type_str);
	gb_string_free(type_str);

	bool *printed = gb_alloc_array(heap_allocator(), bool, p->value_id+1);

	for_array(i, p->blocks) {
		ssaBlock *b = p->blocks.e[i];
		gb_fprintf(f, "  b%d:", b->id);
		if (b->preds.count > 0) {
			gb_fprintf(f, " <-");
			for_array(j, b->preds) {
				ssaBlock *pred = b->preds.e[j].block;
				gb_fprintf(f, " b%d", pred->id);
			}
		}
		gb_fprintf(f, "\n");

		isize n = 0;
		for_array(j, b->values) {
			ssaValue *v = b->values.e[j];
			if (v->op != ssaOp_Phi) {
				continue;
			}
			ssa_print_reg_value(f, v);
			printed[v->id] = true;
			n++;
		}

		while (n < b->values.count) {
			isize m = 0;
			for_array(j, b->values) {
				ssaValue *v = b->values.e[j];
				if (printed[v->id]) {
					continue;
				}
				bool skip = false;
				for_array(k, v->args) {
					ssaValue *w = v->args.e[k];
					if (w != NULL && w->block == b && !printed[w->id]) {
						skip = true;
						break;
					}
				}

				if (skip) {
					break;
				}

				ssa_print_reg_value(f, v);
				printed[v->id] = true;
				n++;
			}
			if (m == n) {
				gb_fprintf(f, "!!!!DepCycle!!!!\n");
				for_array(k, b->values) {
					ssaValue *v = b->values.e[k];
					if (printed[v->id]) {
						continue;
					}

					ssa_print_reg_value(f, v);
					printed[v->id] = true;
					n++;
				}
			}
		}

		if (b->kind == ssaBlock_Plain) {
			GB_ASSERT(b->succs.count == 1);
			ssaBlock *next = b->succs.e[0].block;
			gb_fprintf(f, "    ");
			gb_fprintf(f, "jump b%d", next->id);
			gb_fprintf(f, "\n");
		} else if (b->kind == ssaBlock_If) {
			GB_ASSERT(b->succs.count == 2);
			ssaBlock *yes = b->succs.e[0].block;
			ssaBlock *no = b->succs.e[1].block;
			gb_fprintf(f, "    ");
			gb_fprintf(f, "branch v%d, b%d, b%d", b->control->id, yes->id, no->id);
			gb_fprintf(f, "\n");
		} else if (b->kind == ssaBlock_Exit) {
			gb_fprintf(f, "    ");
			gb_fprintf(f, "exit");
			gb_fprintf(f, "\n");
		} else if (b->kind == ssaBlock_Ret) {
			gb_fprintf(f, "    ");
			gb_fprintf(f, "ret");
			gb_fprintf(f, "\n");
		}
	}

	gb_free(heap_allocator(), printed);
}


void ssa_build_proc(ssaModule *m, ssaProc *p) {
	p->module = m;
	m->proc = p;

	if (p->decl_info->proc_lit == NULL ||
	    p->decl_info->proc_lit->kind != AstNode_ProcLit) {
		return;
	}

	ast_node(pl, ProcLit, p->decl_info->proc_lit);
	if (pl->body == NULL) {
		return;
	}
	p->entry = ssa_new_block(p, ssaBlock_Entry, "entry");

	ssa_start_block(p, p->entry);
	ssa_build_stmt(p, pl->body);

	p->exit = ssa_new_block(p, ssaBlock_Exit, "exit");
	ssa_emit_jump(p, p->exit);

	ssa_print_proc(gb_file_get_standard(gbFileStandard_Error), p);
}



bool ssa_generate(Parser *parser, CheckerInfo *info) {
	if (global_error_collector.count != 0) {
		return false;
	}

	ssaModule m = {0};
	{ // Init ssaModule
		m.info = info;

		isize token_count = parser->total_token_count;
		isize arena_size = 4 * token_count * gb_max3(gb_size_of(ssaValue), gb_size_of(ssaBlock), gb_size_of(ssaProc));

		gb_arena_init_from_allocator(&m.arena,     heap_allocator(), arena_size);
		gb_arena_init_from_allocator(&m.tmp_arena, heap_allocator(), arena_size);
		m.tmp_allocator = gb_arena_allocator(&m.tmp_arena);
		m.allocator     = gb_arena_allocator(&m.arena);

		map_ssa_value_init(&m.values,    heap_allocator());
		array_init(&m.registers,         heap_allocator());
		array_init(&m.procs,             heap_allocator());
		array_init(&m.procs_to_generate, heap_allocator());
	}

	isize global_variable_max_count = 0;
	Entity *entry_point = NULL;
	bool has_dll_main = false;
	bool has_win_main = false;

	for_array(i, info->entities.entries) {
		MapDeclInfoEntry *entry = &info->entities.entries.e[i];
		Entity *e = cast(Entity *)cast(uintptr)entry->key.key;
		String name = e->token.string;
		if (e->kind == Entity_Variable) {
			global_variable_max_count++;
		} else if (e->kind == Entity_Procedure && !e->scope->is_global) {
			if (e->scope->is_init && str_eq(name, str_lit("main"))) {
				entry_point = e;
			}
			if ((e->Procedure.tags & ProcTag_export) != 0 ||
			    (e->Procedure.link_name.len > 0) ||
			    (e->scope->is_file && e->Procedure.link_name.len > 0)) {
				if (!has_dll_main && str_eq(name, str_lit("DllMain"))) {
					has_dll_main = true;
				} else if (!has_win_main && str_eq(name, str_lit("WinMain"))) {
					has_win_main = true;
				}
			}
		}
	}


	m.entry_point_entity = entry_point;
	m.min_dep_map = generate_minimum_dependency_map(info, entry_point);

	for_array(i, info->entities.entries) {
		MapDeclInfoEntry *entry = &info->entities.entries.e[i];
		Entity *e = cast(Entity *)entry->key.ptr;
		String name = e->token.string;
		DeclInfo *decl = entry->value;
		Scope *scope = e->scope;

		if (!scope->is_file) {
			continue;
		}

		if (map_entity_get(&m.min_dep_map, hash_pointer(e)) == NULL) {
			// NOTE(bill): Nothing depends upon it so doesn't need to be built
			continue;
		}

		if (!scope->is_global) {
			if (e->kind == Entity_Procedure && (e->Procedure.tags & ProcTag_export) != 0) {
			} else if (e->kind == Entity_Procedure && e->Procedure.link_name.len > 0) {
				// Handle later
			} else if (scope->is_init && e->kind == Entity_Procedure && str_eq(name, str_lit("main"))) {
			} else {
				name = ssa_mangle_name(&m, e->token.pos.file, e);
			}
		}


		switch (e->kind) {
		case Entity_TypeName:
			break;

		case Entity_Variable: {

		} break;

		case Entity_Procedure: {
			ast_node(pd, ProcLit, decl->proc_lit);
			String original_name = name;
			AstNode *body = pd->body;
			if (e->Procedure.is_foreign) {
				name = e->token.string; // NOTE(bill): Don't use the mangled name
			}
			if (pd->foreign_name.len > 0) {
				name = pd->foreign_name;
			} else if (pd->link_name.len > 0) {
				name = pd->link_name;
			}

			if (e == entry_point) {
				ssaProc *p = ssa_new_proc(&m, name, e, decl);
				ssa_build_proc(&m, p);
			}

			// ssaValue *p = ssa_make_value_procedure(a, m, e, e->type, decl->type_expr, body, name);
			// p->Proc.tags = pd->tags;

			// ssa_module_add_value(m, e, p);
			// HashKey hash_name = hash_string(name);
			// if (map_ssa_value_get(&m.members, hash_name) == NULL) {
				// map_ssa_value_set(&m.members, hash_name, p);
			// }
		} break;
		}
	}

	return true;
}






String ssa_mangle_name(ssaModule *m, String path, Entity *e) {
	// NOTE(bill): prefix names not in the init scope
	// TODO(bill): make robust and not just rely on the file's name
	String name = e->token.string;
	CheckerInfo *info = m->info;
	gbAllocator a = m->allocator;
	AstFile *file = *map_ast_file_get(&info->files, hash_string(path));

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

	isize max_len = base_len + 1 + 10 + 1 + name.len;
	bool is_overloaded = check_is_entity_overloaded(e);
	if (is_overloaded) {
		max_len += 21;
	}

	u8 *new_name = gb_alloc_array(a, u8, max_len);
	isize new_name_len = gb_snprintf(
		cast(char *)new_name, max_len,
		"%.*s-%u.%.*s",
		cast(int)base_len, base,
		file->id,
		LIT(name));
	if (is_overloaded) {
		char *str = cast(char *)new_name + new_name_len-1;
		isize len = max_len-new_name_len;
		isize extra = gb_snprintf(str, len, "-%tu", cast(usize)cast(uintptr)e);
		new_name_len += extra-1;
	}

	return make_string(new_name, new_name_len-1);
}
