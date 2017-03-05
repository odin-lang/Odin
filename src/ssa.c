typedef enum   ssaOp       ssaOp;
typedef struct ssaModule   ssaModule;
typedef struct ssaValue    ssaValue;
typedef struct ssaBlock    ssaBlock;
typedef struct ssaProc     ssaProc;
typedef struct ssaEdge     ssaEdge;
typedef struct ssaRegister ssaRegister;
typedef enum ssaBlockKind  ssaBlockKind;
typedef enum ssaBranchPredicition ssaBranchPredicition;

String ssa_mangle_name(ssaModule *m, String path, Entity *e);

#define MAP_TYPE ssaValue *
#define MAP_PROC map_ssa_value_
#define MAP_NAME MapSsaValue
#include "map.c"

typedef Array(ssaValue *) ssaValueArray;

enum ssaOp {
	ssaOp_Invalid,

	ssaOp_Unknown,

	ssaOp_SP,    // Stack Pointer
	ssaOp_SB,    // Stack Base
	ssaOp_Addr,  // Address of something - special rules for certain types when loading and storing (e.g. Maps)

	ssaOp_Local,
	ssaOp_Global,
	ssaOp_Proc,

	ssaOp_Load,
	ssaOp_Store,
	ssaOp_Move,
	ssaOp_Zero, // Zero initialize

	ssaOp_ArrayIndex, // Index for a fixed array
	ssaOp_PtrIndex,   // Index for a struct/tuple/etc
	ssaOp_OffsetPtr,

	ssaOp_Phi,
	ssaOp_Copy,

	// TODO(bill): calling conventions
	ssaOp_CallOdin,
	ssaOp_CallC,
	ssaOp_CallStd,
	ssaOp_CallFast,

	ssaOp_BoundsCheck,
	ssaOp_SliceBoundsCheck,

	// Built in operations/procedures
	ssaOp_Bswap16,
	ssaOp_Bswap32,
	ssaOp_Bswap64,

	ssaOp_Assume,
	ssaOp_DebugTrap,
	ssaOp_Trap,
	ssaOp_ReadCycleCounter,


	ssaOp_ConstBool,
	ssaOp_ConstString,
	ssaOp_ConstSlice,
	ssaOp_ConstNil,
	ssaOp_Const8,
	ssaOp_Const16,
	ssaOp_Const32,
	ssaOp_Const64,
	ssaOp_Const32F,
	ssaOp_Const64F,

	// These should be all the operations I could possibly need for the mean time
	ssaOp_Add8,
	ssaOp_Add16,
	ssaOp_Add32,
	ssaOp_Add64,
	ssaOp_AddPtr,
	ssaOp_Add32F,
	ssaOp_Add64F,
	ssaOp_Sub8,
	ssaOp_Sub16,
	ssaOp_Sub32,
	ssaOp_Sub64,
	ssaOp_SubPtr,
	ssaOp_Sub32F,
	ssaOp_Sub64F,
	ssaOp_Mul8,
	ssaOp_Mul16,
	ssaOp_Mul32,
	ssaOp_Mul64,
	ssaOp_Mul32F,
	ssaOp_Mul64F,
	ssaOp_Div8,
	ssaOp_Div8U,
	ssaOp_Div16,
	ssaOp_Div16U,
	ssaOp_Div32,
	ssaOp_Div32U,
	ssaOp_Div64,
	ssaOp_Div64U,
	ssaOp_Div32F,
	ssaOp_Div64F,
	ssaOp_Mod8,
	ssaOp_Mod8U,
	ssaOp_Mod16,
	ssaOp_Mod16U,
	ssaOp_Mod32,
	ssaOp_Mod32U,
	ssaOp_Mod64,
	ssaOp_Mod64U,

	ssaOp_And8,
	ssaOp_And16,
	ssaOp_And32,
	ssaOp_And64,
	ssaOp_Or8,
	ssaOp_Or16,
	ssaOp_Or32,
	ssaOp_Or64,
	ssaOp_Xor8,
	ssaOp_Xor16,
	ssaOp_Xor32,
	ssaOp_Xor64,

	ssaOp_Lsh8x8,
	ssaOp_Lsh8x16,
	ssaOp_Lsh8x32,
	ssaOp_Lsh8x64,
	ssaOp_Lsh16x8,
	ssaOp_Lsh16x16,
	ssaOp_Lsh16x32,
	ssaOp_Lsh16x64,
	ssaOp_Lsh32x8,
	ssaOp_Lsh32x16,
	ssaOp_Lsh32x32,
	ssaOp_Lsh32x64,
	ssaOp_Lsh64x8,
	ssaOp_Lsh64x16,
	ssaOp_Lsh64x32,
	ssaOp_Lsh64x64,
	ssaOp_Rsh8x8,
	ssaOp_Rsh8x16,
	ssaOp_Rsh8x32,
	ssaOp_Rsh8x64,
	ssaOp_Rsh16x8,
	ssaOp_Rsh16x16,
	ssaOp_Rsh16x32,
	ssaOp_Rsh16x64,
	ssaOp_Rsh32x8,
	ssaOp_Rsh32x16,
	ssaOp_Rsh32x32,
	ssaOp_Rsh32x64,
	ssaOp_Rsh64x8,
	ssaOp_Rsh64x16,
	ssaOp_Rsh64x32,
	ssaOp_Rsh64x64,
	ssaOp_Rsh8Ux8,
	ssaOp_Rsh8Ux16,
	ssaOp_Rsh8Ux32,
	ssaOp_Rsh8Ux64,
	ssaOp_Rsh16Ux8,
	ssaOp_Rsh16Ux16,
	ssaOp_Rsh16Ux32,
	ssaOp_Rsh16Ux64,
	ssaOp_Rsh32Ux8,
	ssaOp_Rsh32Ux16,
	ssaOp_Rsh32Ux32,
	ssaOp_Rsh32Ux64,
	ssaOp_Rsh64Ux8,
	ssaOp_Rsh64Ux16,
	ssaOp_Rsh64Ux32,
	ssaOp_Rsh64Ux64,

	ssaOp_Eq8,
	ssaOp_Eq16,
	ssaOp_Eq32,
	ssaOp_Eq64,
	ssaOp_EqPtr,
	ssaOp_Eq32F,
	ssaOp_Eq64F,
	ssaOp_Ne8,
	ssaOp_Ne16,
	ssaOp_Ne32,
	ssaOp_Ne64,
	ssaOp_NePtr,
	ssaOp_Ne32F,
	ssaOp_Ne64F,
	ssaOp_Lt8,
	ssaOp_Lt16,
	ssaOp_Lt32,
	ssaOp_Lt64,
	ssaOp_LtPtr,
	ssaOp_Lt32F,
	ssaOp_Lt64F,
	ssaOp_Gt8,
	ssaOp_Gt16,
	ssaOp_Gt32,
	ssaOp_Gt64,
	ssaOp_GtPtr,
	ssaOp_Gt32F,
	ssaOp_Gt64F,
	ssaOp_Le8,
	ssaOp_Le16,
	ssaOp_Le32,
	ssaOp_Le64,
	ssaOp_LePtr,
	ssaOp_Le32F,
	ssaOp_Le64F,
	ssaOp_Ge8,
	ssaOp_Ge16,
	ssaOp_Ge32,
	ssaOp_Ge64,
	ssaOp_GePtr,
	ssaOp_Ge32F,
	ssaOp_Ge64F,

	ssaOp_NotB,
	ssaOp_EqB,
	ssaOp_NeB,

	ssaOp_Neg8,
	ssaOp_Neg16,
	ssaOp_Neg32,
	ssaOp_Neg64,
	ssaOp_Neg32F,
	ssaOp_Neg64F,

	ssaOp_Not8,
	ssaOp_Not16,
	ssaOp_Not32,
	ssaOp_Not64,

	ssaOp_SignExt8to16,
	ssaOp_SignExt8to32,
	ssaOp_SignExt8to64,
	ssaOp_SignExt16to32,
	ssaOp_SignExt16to64,
	ssaOp_SignExt32to64,
	ssaOp_ZeroExt8to16,
	ssaOp_ZeroExt8to32,
	ssaOp_ZeroExt8to64,
	ssaOp_ZeroExt16to32,
	ssaOp_ZeroExt16to64,
	ssaOp_ZeroExt32to64,
	ssaOp_Trunc16to8,
	ssaOp_Trunc32to8,
	ssaOp_Trunc32to16,
	ssaOp_Trunc64to8,
	ssaOp_Trunc64to16,
	ssaOp_Trunc64to32,

	ssaOp_Cvt32to32F,
	ssaOp_Cvt32to64F,
	ssaOp_Cvt64to32F,
	ssaOp_Cvt64to64F,
	ssaOp_Cvt32Fto32,
	ssaOp_Cvt32Fto64,
	ssaOp_Cvt64Fto32,
	ssaOp_Cvt64Fto64,
	ssaOp_Cvt32Fto64F,
	ssaOp_Cvt64Fto32F,
	ssaOp_Cvt32Uto32F,
	ssaOp_Cvt32Uto64F,
	ssaOp_Cvt32Fto32U,
	ssaOp_Cvt64Fto32U,
	ssaOp_Cvt64Uto32F,
	ssaOp_Cvt64Uto64F,
	ssaOp_Cvt32Fto64U,
	ssaOp_Cvt64Fto64U,

	ssaOp_Count,
};

#define SSA_MAX_ARGS 4

struct ssaValue {
	i32           id;    // Unique identifier but the pointer could be used too
	ssaOp         op;    // Operation that computes this value
	Type *        type;
	ssaBlock *    block; // Containing basic block

	i32           uses;
	// Most values will only a few number of arguments
	// Procedure calls may need a lot more so they will use the `var_args` parameter instead
	ssaValue *    args[SSA_MAX_ARGS];
	isize         arg_count;

	ssaValueArray var_args; // Only used in procedure calls as the SSA_MAX_ARGS may be too small

	ExactValue    exact_value; // Used for constants
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

enum ssaBranchPredicition {
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

	// Likely branch direction
	ssaBranchPredicition likeliness;

	ssaValueArray values;
	ssaEdgeArray  preds;
	ssaEdgeArray  succs;
};

struct ssaProc {
	ssaModule *       module;     // Parent module
	String            name;       // Mangled name
	Entity *          entity;
	DeclInfo *        decl_info;

	Array(ssaBlock *) blocks;
	ssaBlock *        entry;      // Entry block
	ssaBlock *        curr_block;

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





ssaBlock *ssa_new_block(ssaProc *p, ssaBlockKind kind) {
	ssaBlock *b = gb_alloc_item(p->module->allocator, ssaBlock);
	b->id = p->block_id++;
	b->kind = kind;
	b->proc = p;

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

void ssa_add_to_edge(ssaBlock *b, ssaBlock *c) {
	isize i = b->succs.count;
	isize j = b->preds.count;
	ssaEdge s = {c, j};
	ssaEdge p = {b, i};
	array_add(&b->succs, s);
	array_add(&b->preds, p);
}


ssaValue *ssa_new_value(ssaProc *p, ssaOp op, Type *t, ssaBlock *b) {
	ssaValue *v = gb_alloc_item(p->module->allocator, ssaValue);
	v->id    = p->value_id++;
	v->op    = op;
	v->type  = t;
	v->block = b;
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
	v->args[v->arg_count++] = arg; arg->uses++;
	return v;
}
ssaValue *ssa_new_value1v(ssaBlock *b, ssaOp op, Type *t, ExactValue exact_value, ssaValue *arg) {
	ssaValue *v = ssa_new_value1(b, op, t, arg);
	v->exact_value = exact_value;
	return v;
}

ssaValue *ssa_new_value2(ssaBlock *b, ssaOp op, Type *t, ssaValue *arg0, ssaValue *arg1) {
	ssaValue *v = ssa_new_value(b->proc, op, t, b);
	v->args[v->arg_count++] = arg0; arg0->uses++;
	v->args[v->arg_count++] = arg1; arg1->uses++;
	return v;
}
ssaValue *ssa_new_value2v(ssaBlock *b, ssaOp op, Type *t, ExactValue exact_value, ssaValue *arg0, ssaValue *arg1) {
	ssaValue *v = ssa_new_value2(b, op, t, arg0, arg1);
	v->exact_value = exact_value;
	return v;
}

ssaValue *ssa_new_value3(ssaBlock *b, ssaOp op, Type *t, ssaValue *arg0, ssaValue *arg1, ssaValue *arg2) {
	ssaValue *v = ssa_new_value(b->proc, op, t, b);
	v->args[v->arg_count++] = arg0; arg0->uses++;
	v->args[v->arg_count++] = arg1; arg1->uses++;
	v->args[v->arg_count++] = arg2; arg2->uses++;
	return v;
}
ssaValue *ssa_new_value3v(ssaBlock *b, ssaOp op, Type *t, ExactValue exact_value, ssaValue *arg0, ssaValue *arg1, ssaValue *arg2) {
	ssaValue *v = ssa_new_value3(b, op, t, arg0, arg1, arg2);
	v->exact_value = exact_value;
	return v;
}

ssaValue *ssa_new_value4(ssaBlock *b, ssaOp op, Type *t, ssaValue *arg0, ssaValue *arg1, ssaValue *arg2, ssaValue *arg3) {
	ssaValue *v = ssa_new_value(b->proc, op, t, b);
	v->args[v->arg_count++] = arg0; arg0->uses++;
	v->args[v->arg_count++] = arg1; arg1->uses++;
	v->args[v->arg_count++] = arg2; arg2->uses++;
	v->args[v->arg_count++] = arg3; arg3->uses++;
	return v;
}

ssaValue *ssa_const_val(ssaProc *p, ssaOp op, Type *t, ExactValue exact_value) {
	return ssa_new_value0v(p->curr_block, op, t, exact_value);
}

ssaValue *ssa_const_bool        (ssaProc *p, Type *t, bool   c) { return ssa_const_val(p, ssaOp_ConstBool,   t, exact_value_bool(c)); }
ssaValue *ssa_const_i8          (ssaProc *p, Type *t, i8     c) { return ssa_const_val(p, ssaOp_Const8,      t, exact_value_integer(cast(i64)c)); }
ssaValue *ssa_const_i16         (ssaProc *p, Type *t, i16    c) { return ssa_const_val(p, ssaOp_Const16,     t, exact_value_integer(cast(i64)c)); }
ssaValue *ssa_const_i32         (ssaProc *p, Type *t, i32    c) { return ssa_const_val(p, ssaOp_Const32,     t, exact_value_integer(cast(i64)c)); }
ssaValue *ssa_const_i64         (ssaProc *p, Type *t, i64    c) { return ssa_const_val(p, ssaOp_Const64,     t, exact_value_integer(cast(i64)c)); }
ssaValue *ssa_const_f32         (ssaProc *p, Type *t, f32    c) { return ssa_const_val(p, ssaOp_Const32F,    t, exact_value_float(c)); }
ssaValue *ssa_const_f64         (ssaProc *p, Type *t, f64    c) { return ssa_const_val(p, ssaOp_Const64F,    t, exact_value_float(c)); }
ssaValue *ssa_const_string      (ssaProc *p, Type *t, String c) { return ssa_const_val(p, ssaOp_ConstString, t, exact_value_string(c)); }
ssaValue *ssa_const_empty_string(ssaProc *p, Type *t)           { return ssa_const_val(p, ssaOp_ConstString, t, (ExactValue){0}); }
ssaValue *ssa_const_slice       (ssaProc *p, Type *t)           { return ssa_const_val(p, ssaOp_ConstSlice,  t, (ExactValue){0}); }
ssaValue *ssa_const_nil         (ssaProc *p, Type *t)           { return ssa_const_val(p, ssaOp_ConstNil,    t, (ExactValue){0}); }

bool ssa_is_blank_ident(AstNode *node) {
	if (node->kind == AstNode_Ident) {
		ast_node(i, Ident, node);
		return is_blank_ident(i->string);
	}
	return false;
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

ssaValue *ssa_add_local(ssaProc *p, Entity *e, AstNode *expr) {
	Type *t = make_type_pointer(p->module->allocator, e->type);
	ssaValue *local = ssa_new_value0(p->entry, ssaOp_Local, t);
	map_ssa_value_set(&p->values,         hash_pointer(e), local);
	map_ssa_value_set(&p->module->values, hash_pointer(e), local);

	ssaValue *addr = ssa_new_value1(p->curr_block, ssaOp_Addr, local->type, local);
	ssa_new_value1(p->curr_block, ssaOp_Zero, t, addr);
	return addr;
}
ssaValue *ssa_add_local_for_ident(ssaProc *p, AstNode *name) {
	Entity **found = map_entity_get(&p->module->info->definitions, hash_pointer(name));
	if (found) {
		Entity *e = *found;
		return ssa_add_local(p, e, name);
	}
	return NULL;
}

ssaValue *ssa_add_local_generated(ssaProc *p, Type *t) {
	GB_ASSERT(t != NULL);

	Scope *scope = NULL;
	if (p->curr_block) {
		// scope = p->curr_block->scope;
	}
	Entity *e = make_entity_variable(p->module->allocator, scope, empty_token, t, false);
	return ssa_add_local(p, e, NULL);
}







void ssa_build_stmt(ssaProc *p, AstNode *node);
void ssa_build_stmt_list(ssaProc *p, AstNodeArray nodes);


ssaValue *ssa_build_addr(ssaProc *p, AstNode *node) {
	return NULL;
}

ssaValue *ssa_build_expr(ssaProc *p, AstNode *expr) {
	expr = unparen_expr(expr);

	TypeAndValue *tv = map_tav_get(&p->module->info->types, hash_pointer(expr));
	GB_ASSERT_NOT_NULL(tv);

	if (tv->value.kind != ExactValue_Invalid) {
		return NULL;
		// return llir_add_module_constant(p->module, tv->type, tv->value);
	}

	switch (expr->kind) {
	case_ast_node(bl, BasicLit, expr);
		GB_PANIC("Non-constant basic literal");
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
			return v;
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

void ssa_addr_store(ssaProc *p, ssaValue *addr, ssaValue *value) {

}


ssaValue *ssa_emit_struct_ep(ssaProc *p, ssaValue *ptr, i32 index) {
	GB_ASSERT(ptr->type != NULL);
	GB_ASSERT(is_type_pointer(ptr->type));
	return NULL;
}


void ssa_build_stmt(ssaProc *p, AstNode *node) {
	if (p->curr_block == NULL) {
		ssaBlock *dead_block = ssa_new_block(p, ssaBlock_Plain);
		ssa_start_block(p, dead_block);
	}

	switch (node->kind) {
	case_ast_node(es, EmptyStmt, node);
	case_end;

	case_ast_node(bs, BlockStmt, node);
		ssa_build_stmt_list(p, bs->stmts);
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
				ssaValueArray lvals = {0};
				ssaValueArray inits = {0};
				array_init_reserve(&lvals, m->tmp_allocator, vd->names.count);
				array_init_reserve(&inits, m->tmp_allocator, vd->names.count);

				for_array(i, vd->names) {
					AstNode *name = vd->names.e[i];
					ssaValue *lval = NULL;
					if (!ssa_is_blank_ident(name)) {
						lval = ssa_add_local_for_ident(p, name);
					}

					array_add(&lvals, lval);
				}

				for_array(i, vd->values) {
					ssaValue *init = ssa_build_expr(p, vd->values.e[i]);
					if (init == NULL || init->type == NULL) {
						// TODO(bill): remove this
						continue;
					}
					Type *t = base_type(init->type);
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
					if (lvals.e[i] == NULL) {
						continue;
					}
					ssa_addr_store(p, lvals.e[i], inits.e[i]);
				}
			}

			gb_temp_arena_memory_end(tmp);
		}
	case_end;
	}
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
	p->entry = ssa_new_block(p, ssaBlock_Entry);
	p->curr_block = ssa_new_block(p, ssaBlock_Plain);

	ssa_build_stmt(p, pl->body);
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
				gb_printf("%.*s\n", LIT(name));

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
