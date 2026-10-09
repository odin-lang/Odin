// Frontend: checked AST -> xb IR.
//
// Scalars (integers, floats, pointers, ...) live in virtual registers. Everything
// else lives in memory and is passed around by address. Anything not supported
// yet bails out of the procedure, which is then left to LLVM.

#include <setjmp.h>

enum xbValueKind : u8 {
	xbValue_Invalid,
	xbValue_Reg, // scalar in a vreg
	xbValue_Mem, // value stored in memory at `mem`, which must not be written through
};

struct xbValue {
	xbValueKind kind;
	Type *      type;
	u32         reg;
	xbMem       mem;
	// for a scalar loaded from memory: where it came from, like an LLVM load instruction
	bool        has_origin;
	xbMem       origin;
};

enum xbAddrKind : u8 {
	xbAddr_Invalid,
	xbAddr_Default,
	xbAddr_Context,
	xbAddr_Map,
	xbAddr_BitField,
	xbAddr_Discard,
	xbAddr_SoaVariable, // element `index` of the #soa container at `mem`
	xbAddr_Swizzle,     // elements `swizzle_indices` of the array at `mem`
	xbAddr_SwizzleSoa,  // components `soa_swizzle` of the array element `index` of the #soa container at `mem`
};

struct xbAddr {
	xbAddrKind kind;
	Type *     type;  // type of the value at the address
	xbMem      mem;
	// Context: the selection into the context
	Selection  ctx_sel;
	// Map
	xbValue    map_key;
	Type *     map_type;
	Type *     map_result;
	// BitField
	i64        bit_offset;
	i64        bit_size;
	// SoaVariable
	u32        soa_index;
	Ast *      soa_index_expr; // set when the index needs a bounds check
	Type *     soa_container;
	// Swizzle
	u8         swizzle_count;
	u8         swizzle_indices; // 2 bits per element
	Type *     swizzle_elem;
	// SwizzleSoa (with the SoaVariable fields)
	Slice<i32> soa_swizzle;
};

struct xbVar {
	xbMem mem;
	bool  indirect;   // mem holds a pointer to the value
	bool  is_soa;     // an #soa element: mem holds a pointer to the container
	i32   soa_index_local;
	Type *soa_container;
};

struct xbDefer {
	isize scope_index;
	isize context_stack_count;
	Ast * stmt;
	// a deferred procedure call (`@(deferred_*)`)
	bool  is_proc;
	xbValue proc;
	Entity *proc_entity;
	Array<xbValue> args;
	TokenPos pos;
};

struct xbTargetList {
	xbTargetList *prev;
	bool     is_block;
	xbBlock *break_;
	xbBlock *continue_;
	xbBlock *fallthrough_;
};

struct xbBranchBlocks {
	Ast *    label;
	xbBlock *break_;
	xbBlock *continue_;
};

struct xbContextEntry {
	xbMem mem;      // the context struct, or a local holding a pointer to it
	bool  indirect;
	isize scope_index;
	isize uses;
};

// a selector call `x->f()` is `x.f(x)`, and `x` must be evaluated only once
struct xbSelectorCache {
	Ast *   expr;
	bool    is_addr;
	xbValue value;
	xbAddr  addr;
};

// What the builder knows of a vreg's value. Every vreg has one definition.
struct xbVregInfo {
	i64  k;     // the constant, sign extended from the type's width
	u64  umax;  // the largest value the vreg can hold, zero extended
	bool is_k;
};

struct xbProc {
	xbModule *  m;
	Entity *    entity;
	Type *      type;
	String      name;
	i32         sym;
	Ast *       body;
	xbAbiFunc * abi;
	DeclInfo *  decl;
	bool        is_startup; // runs once; literals that outlive it get static storage
	bool        naked;      // no prologue, epilogue or stack slots
	bool        va_home;       // Win64: c_va_start is used, the prologue homes rcx, rdx, r8 and r9
	i32         va_save_local; // SysV and AAPCS64: the local the prologue saves the argument registers into for c_va_start, or -1

	Array<xbBlock *>  blocks;
	Array<xbBlock *>  order;
	xbBlock *         curr;
	Array<xbType>     vregs;
	Array<xbVregInfo> vinfo;
	Array<xbLocal>    locals;
	Array<xbCall>     calls;
	Array<xbAsmBlock> asms;
	Array<xbParamIn>  params_in;

	PtrMap<Entity *, xbVar> vars;
	Array<xbContextEntry>   context_stack;
	Array<xbDefer>          defers;
	isize                   scope_index;
	xbTargetList *          targets;
	Array<xbBranchBlocks>   branch_blocks;
	Array<xbSelectorCache>  selector_cache;

	i32         sret_local;
	Array<i32>  split_ret_locals;
	i32         ret_temp_local;

	jmp_buf *   bail;
	char const *fail_reason;
	Ast *       fail_node;

	i32         file_id;
	i32         last_line;
	i32         last_column;
	u16         state_flags;
	Ast *       curr_stmt;
	TokenPos    branch_location_pos; // where the running defers were triggered, for #branch_location

	Array<xbDebugVar> debug_vars;
	Array<i32>        debug_scope_parent;
	Array<xbInlineSite> inline_sites;
	i32               debug_scope;
	struct xbFamily * family;
	struct xbInline * inl; // the innermost #force_inline body being built, or nullptr
	// #force_inline procedures whose body cannot be inlined here; per procedure, so what one
	// procedure's build finds does not change another's
	PtrSet<Entity *>  inline_failed;
};

// A #force_inline procedure whose body is built into its caller.
struct xbInline {
	xbInline *prev;
	Entity *  caller;  // the procedure the body is built into, itself maybe inlined
	xbMem     result;  // the returns store the results here
	xbBlock * exit;    // and jump here
	i32       exits;   // the jumps to exit
	xbBlock * exit_from; // the block of the last one
	xbInlineSite site; // for the debug info, its scope set when the body starts
};

// A procedure and every procedure declared inside it. They are compiled together,
// or all left to LLVM, which generates nested procedures along with their parent.
struct xbFamily {
	DeclInfo *         root_decl;
	PtrSet<DeclInfo *> roots;     // procedures whose nested procedures belong here
	Array<Entity *>    queue;
	PtrSet<Entity *>   seen;
	PtrSet<Entity *>   on_demand; // referenced, but generated by nobody else
	PtrMap<Entity *, i32> statics; // static locals, which nested procedures may use too
	Array<xbProc *>    procs;
};

gb_internal void xb_family_add(xbFamily *f, Entity *e) {
	if (ptr_set_update(&f->seen, e)) return;
	array_add(&f->queue, e);
}

gb_internal Slice<xbValue> xb_args(xbValue *data, isize count) {
	Slice<xbValue> s = {data, count};
	return s;
}

#define XB_UNSUPPORTED(p, reason) xb_unsupported(p, reason, nullptr)

[[noreturn]] gb_internal void xb_unsupported(xbProc *p, char const *reason, Ast *node) {
	p->fail_reason = reason;
	p->fail_node = node;
	Ast *at = node ? node : p->curr_stmt;
	if (at != nullptr) p->m->fail_pos = ast_token(at).pos;
	longjmp(*p->bail, 1);
}

////////////////////////////////////////////////////////////////
// IR building
////////////////////////////////////////////////////////////////

gb_internal u32 xb_new_vreg(xbProc *p, xbType t) {
	GB_ASSERT(t != xbType_None);
	u32 r = cast(u32)p->vregs.count;
	array_add(&p->vregs, t);
	// a rolled back inline body leaves stale entries
	if (p->vinfo.count > r) p->vinfo.count = r;
	while (p->vinfo.count < r) {
		xbVregInfo none = {0, ~0ull, false};
		array_add(&p->vinfo, none);
	}
	xbVregInfo info = {0, ~0ull, false};
	array_add(&p->vinfo, info);
	return r;
}

////////////////////////////////////////////////////////////////
// Folding. Every vreg has one definition that comes before its uses, so what is known of
// it holds at every use.
////////////////////////////////////////////////////////////////

gb_internal u64 xb_width_mask(xbType t) {
	i32 size = xb_type_size(t);
	return size >= 8 ? ~0ull : (1ull << (8*size)) - 1;
}

// v as the `t` value it is, sign extended
gb_internal i64 xb_fold_norm(xbType t, i64 v) {
	i32 size = xb_type_size(t);
	if (size >= 8) return v;
	u32 sh = cast(u32)(64 - 8*size);
	return cast(i64)(cast(u64)v << sh) >> sh;
}

gb_internal bool xb_known(xbProc *p, u32 v, i64 *out) {
	if (v == 0 || v >= p->vinfo.count || !p->vinfo[v].is_k) return false;
	*out = p->vinfo[v].k;
	return true;
}

// the largest value v can hold, unsigned
gb_internal u64 xb_umax(xbProc *p, u32 v) {
	if (v == 0 || v >= p->vinfo.count) return ~0ull;
	xbType t = p->vregs[v];
	if (!xb_type_is_int(t)) return ~0ull;
	xbVregInfo const &i = p->vinfo[v];
	if (i.is_k) return cast(u64)i.k & xb_width_mask(t);
	return gb_min(i.umax, xb_width_mask(t));
}

gb_internal void xb_note_umax(xbProc *p, u32 v, u64 umax) {
	if (v != 0 && v < p->vinfo.count) p->vinfo[v].umax = umax;
}

gb_internal bool xb_is_pow2(u64 v, u32 *log2) {
	if (v == 0 || (v & (v - 1)) != 0) return false;
	u32 n = 0;
	while ((1ull << n) != v) n++;
	*log2 = n;
	return true;
}

gb_internal xbBlock *xb_new_block(xbProc *p) {
	xbBlock *b = xb_alloc_item<xbBlock>();
	b->index = cast(i32)p->blocks.count;
	b->instrs = array_make<xbInstr>(xb_allocator(), 0, 8);
	b->scope_index = p->scope_index;
	array_add(&p->blocks, b);
	return b;
}

gb_internal void xb_start_block(xbProc *p, xbBlock *b, bool line_row=true) {
	GB_ASSERT(!b->placed);
	b->placed = true;
	b->debug_scope = p->debug_scope;
	array_add(&p->order, b);
	p->curr = b;
	// a block starts its own line row, so a debugger's step stops where a jump lands, as at a loop's head;
	// without one it goes on in the row before, like LLVM loop heads that start with a reload of no line
	if (line_row && p->last_line > 0) {
		xbInstr i = {};
		i.op = xbOp_Loc;
		i.imm = p->last_line;
		i.a = cast(u32)p->file_id;
		i.b = cast(u32)p->last_column;
		array_add(&b->instrs, i);
	}
}

gb_internal bool xb_is_terminator(xbOp op) {
	switch (op) {
	case xbOp_Jump:
	case xbOp_Branch:
	case xbOp_Ret:
	case xbOp_Unreachable:
		return true;
	}
	return false;
}

gb_internal bool xb_block_terminated(xbBlock *b) {
	if (b == nullptr) return true;
	if (b->instrs.count == 0) return false;
	return xb_is_terminator(b->instrs[b->instrs.count-1].op);
}

gb_internal bool xb_curr_terminated(xbProc *p) {
	return xb_block_terminated(p->curr);
}

gb_internal xbInstr *xb_emit(xbProc *p, xbInstr const &instr) {
	if (xb_curr_terminated(p)) {
		// dead code after a terminator, put it in a block that is never placed
		p->curr = xb_new_block(p);
	}
	array_add(&p->curr->instrs, instr);
	return &p->curr->instrs[p->curr->instrs.count-1];
}

gb_internal xbInstr xb_instr(xbOp op, xbType type=xbType_None) {
	xbInstr i = {};
	i.op = op;
	i.type = type;
	return i;
}

gb_internal u32 xb_iconst(xbProc *p, xbType t, i64 v) {
	xbInstr i = xb_instr(xbOp_IConst, t);
	i.dst = xb_new_vreg(p, t);
	i.imm = v;
	xb_emit(p, i);
	if (xb_type_is_int(t)) {
		p->vinfo[i.dst].is_k = true;
		p->vinfo[i.dst].k = xb_fold_norm(t, v);
	}
	return i.dst;
}

gb_internal u32 xb_fconst(xbProc *p, xbType t, f64 v) {
	xbInstr i = xb_instr(xbOp_FConst, t);
	i.dst = xb_new_vreg(p, t);
	if (t == xbType_F32) {
		f32 f = cast(f32)v;
		u32 bits = 0;
		gb_memmove(&bits, &f, 4);
		i.imm = bits;
	} else {
		u64 bits = 0;
		gb_memmove(&bits, &v, 8);
		i.imm = cast(i64)bits;
	}
	xb_emit(p, i);
	return i.dst;
}

gb_internal u32 xb_lea(xbProc *p, xbMem mem) {
	if (mem.kind == xbMem_Reg && mem.offset == 0) {
		return mem.base;
	}
	xbInstr i = xb_instr(xbOp_Lea, xbType_I64);
	i.dst = xb_new_vreg(p, xbType_I64);
	i.mem = mem;
	xb_emit(p, i);
	return i.dst;
}

gb_internal u32 xb_stored_value(xbProc *p, xbType t, xbMem m);

gb_internal u32 xb_load(xbProc *p, xbType t, xbMem mem) {
	if (u32 v = xb_stored_value(p, t, mem)) return v;
	xbInstr i = xb_instr(xbOp_Load, t);
	i.dst = xb_new_vreg(p, t);
	i.mem = mem;
	xb_emit(p, i);
	return i.dst;
}

gb_internal void xb_store(xbProc *p, xbType t, xbMem mem, u32 v) {
	xbInstr i = xb_instr(xbOp_Store, t);
	i.a = v;
	i.mem = mem;
	xb_emit(p, i);
}

// The x86 shifts, which the lowerings copy: narrow values shift as 32 bits, the count masked.
gb_internal i64 xb_fold_shift(xbOp op, xbType t, i64 x, i64 c) {
	i32 size = xb_type_size(t);
	u32 n = cast(u32)(c & (size == 8 ? 63 : 31));
	u64 ux = cast(u64)x & xb_width_mask(t);
	switch (op) {
	case xbOp_Shl:  return cast(i64)(ux << n);
	case xbOp_LShr: return cast(i64)(ux >> n);
	case xbOp_AShr: return xb_fold_norm(t, x) >> n;
	}
	return 0;
}

gb_internal u32 xb_binop(xbProc *p, xbOp op, xbType t, u32 a, u32 b) {
	if (xb_type_is_int(t)) {
		i64 x = 0, y = 0;
		bool kx = xb_known(p, a, &x);
		bool ky = xb_known(p, b, &y);
		u64 mask = xb_width_mask(t);
		u64 ux = cast(u64)x & mask, uy = cast(u64)y & mask;
		if (kx && ky) {
			bool ok = true;
			i64 r = 0;
			switch (op) {
			case xbOp_Add: r = cast(i64)(cast(u64)x + cast(u64)y); break;
			case xbOp_Sub: r = cast(i64)(cast(u64)x - cast(u64)y); break;
			case xbOp_Mul: r = cast(i64)(cast(u64)x * cast(u64)y); break;
			case xbOp_And: r = x & y; break;
			case xbOp_Or:  r = x | y; break;
			case xbOp_Xor: r = x ^ y; break;
			case xbOp_Shl:
			case xbOp_LShr:
			case xbOp_AShr: r = xb_fold_shift(op, t, x, y); break;
			case xbOp_UDiv: ok = uy != 0; if (ok) r = cast(i64)(ux / uy); break;
			case xbOp_URem: ok = uy != 0; if (ok) r = cast(i64)(ux % uy); break;
			case xbOp_SDiv: ok = y != 0 && !(y == -1 && x == xb_fold_norm(t, cast(i64)(1ull << (8*xb_type_size(t)-1)))); if (ok) r = x / y; break;
			case xbOp_SRem: ok = y != 0 && !(y == -1 && x == xb_fold_norm(t, cast(i64)(1ull << (8*xb_type_size(t)-1)))); if (ok) r = x % y; break;
			default: ok = false; break;
			}
			if (ok) return xb_iconst(p, t, xb_fold_norm(t, r));
		}
		// x op identity
		if (ky) {
			switch (op) {
			case xbOp_Add: case xbOp_Sub: case xbOp_Or: case xbOp_Xor:
			case xbOp_Shl: case xbOp_LShr: case xbOp_AShr:
				if (y == 0) return a;
				break;
			case xbOp_Mul:
			case xbOp_UDiv:
			case xbOp_SDiv:
				if (y == 1) return a;
				break;
			case xbOp_And:
				if (uy == mask) return a;
				if (y == 0) return b;
				break;
			}
			u32 n = 0;
			if (xb_is_pow2(uy, &n)) {
				if (op == xbOp_Mul)  return xb_binop(p, xbOp_Shl, t, a, xb_iconst(p, t, n));
				if (op == xbOp_UDiv) return xb_binop(p, xbOp_LShr, t, a, xb_iconst(p, t, n));
				if (op == xbOp_URem) return xb_binop(p, xbOp_And, t, a, xb_iconst(p, t, xb_fold_norm(t, cast(i64)(uy - 1))));
			}
		}
		if (kx) {
			switch (op) {
			case xbOp_Add: case xbOp_Or: case xbOp_Xor:
				if (x == 0) return b;
				break;
			case xbOp_Mul:
				if (x == 1) return b;
				break;
			case xbOp_And:
				if (ux == mask) return b;
				if (x == 0) return a;
				break;
			}
			u32 n = 0;
			if (op == xbOp_Mul && xb_is_pow2(ux, &n)) return xb_binop(p, xbOp_Shl, t, b, xb_iconst(p, t, n));
		}
	}
	xbInstr i = xb_instr(op, t);
	i.dst = xb_new_vreg(p, t);
	i.a = a;
	i.b = b;
	xb_emit(p, i);
	if (xb_type_is_int(t)) {
		i64 y = 0;
		switch (op) {
		case xbOp_And:
			xb_note_umax(p, i.dst, gb_min(xb_umax(p, a), xb_umax(p, b)));
			break;
		case xbOp_LShr:
			if (xb_known(p, b, &y) && y >= 0 && y < 8*xb_type_size(t)) xb_note_umax(p, i.dst, xb_umax(p, a) >> y);
			break;
		case xbOp_URem:
			if (xb_known(p, b, &y) && (cast(u64)y & xb_width_mask(t)) != 0) xb_note_umax(p, i.dst, (cast(u64)y & xb_width_mask(t)) - 1);
			break;
		}
	}
	return i.dst;
}

gb_internal u32 xb_unop(xbProc *p, xbOp op, xbType t, u32 a) {
	i64 x = 0;
	if (xb_type_is_int(t) && xb_known(p, a, &x)) {
		if (op == xbOp_Neg) return xb_iconst(p, t, xb_fold_norm(t, cast(i64)(0ull - cast(u64)x)));
		if (op == xbOp_Not) return xb_iconst(p, t, xb_fold_norm(t, ~x));
	}
	xbInstr i = xb_instr(op, t);
	i.dst = xb_new_vreg(p, t);
	i.a = a;
	xb_emit(p, i);
	return i.dst;
}

// a <cond> b when it is known, -1 otherwise
gb_internal i32 xb_fold_cmp(xbProc *p, xbCond cond, xbType t, u32 a, u32 b) {
	if (!xb_type_is_int(t)) return -1;
	i64 x = 0, y = 0;
	bool kx = xb_known(p, a, &x);
	bool ky = xb_known(p, b, &y);
	u64 mask = xb_width_mask(t);
	if (kx && ky) {
		u64 ux = cast(u64)x & mask, uy = cast(u64)y & mask;
		switch (cond) {
		case xbCond_EQ:  return x == y;
		case xbCond_NE:  return x != y;
		case xbCond_SLT: return x < y;
		case xbCond_SLE: return x <= y;
		case xbCond_SGT: return x > y;
		case xbCond_SGE: return x >= y;
		case xbCond_ULT: return ux < uy;
		case xbCond_ULE: return ux <= uy;
		case xbCond_UGT: return ux > uy;
		case xbCond_UGE: return ux >= uy;
		}
		return -1;
	}
	// a value below a constant bound, like a masked shift count
	if (ky) {
		u64 uy = cast(u64)y & mask;
		u64 hi = xb_umax(p, a);
		if (cond == xbCond_ULT && hi < uy)  return 1;
		if (cond == xbCond_UGE && hi < uy)  return 0;
		if (cond == xbCond_ULE && hi <= uy) return 1;
		if (cond == xbCond_UGT && hi <= uy) return 0;
	}
	return -1;
}

gb_internal u32 xb_cmp(xbProc *p, xbCond cond, xbType t, u32 a, u32 b) {
	i32 known = xb_fold_cmp(p, cond, t, a, b);
	if (known >= 0) return xb_iconst(p, xbType_I8, known);
	// a bool tested against zero is itself
	i64 y = 0;
	if (t == xbType_I8 && cond == xbCond_NE && xb_known(p, b, &y) && y == 0 && xb_umax(p, a) <= 1) return a;
	xbInstr i = xb_instr(xb_type_is_float(t) ? xbOp_FCmp : xbOp_ICmp, t);
	i.aux = cond;
	i.dst = xb_new_vreg(p, xbType_I8);
	i.a = a;
	i.b = b;
	xb_emit(p, i);
	xb_note_umax(p, i.dst, 1);
	return i.dst;
}

gb_internal u32 xb_convop(xbProc *p, xbOp op, xbType dst, xbType src, u32 a) {
	i64 x = 0;
	if (xb_type_is_int(dst) && xb_type_is_int(src) && xb_known(p, a, &x)) {
		switch (op) {
		case xbOp_Zext:  return xb_iconst(p, dst, xb_fold_norm(dst, cast(i64)(cast(u64)x & xb_width_mask(src))));
		case xbOp_Sext:
		case xbOp_Trunc: return xb_iconst(p, dst, xb_fold_norm(dst, x));
		}
	}
	xbInstr i = xb_instr(op, dst);
	i.aux = src;
	i.dst = xb_new_vreg(p, dst);
	i.a = a;
	xb_emit(p, i);
	if (xb_type_is_int(dst) && xb_type_is_int(src)) {
		if (op == xbOp_Zext)  xb_note_umax(p, i.dst, xb_umax(p, a));
		if (op == xbOp_Trunc) xb_note_umax(p, i.dst, gb_min(xb_umax(p, a), xb_width_mask(dst)));
	}
	return i.dst;
}

gb_internal u32 xb_fma(xbProc *p, xbType t, u32 a, u32 b, u32 c) {
	xbInstr i = xb_instr(xbOp_Fma, t);
	i.dst = xb_new_vreg(p, t);
	i.a = a;
	i.b = b;
	i.c = c;
	xb_emit(p, i);
	return i.dst;
}

gb_internal u32 xb_select(xbProc *p, xbType t, u32 cond, u32 a, u32 b) {
	i64 c = 0;
	if (xb_known(p, cond, &c)) return (c & 0xff) != 0 ? a : b;
	if (a == b) return a;
	xbInstr i = xb_instr(xbOp_Select, t);
	i.dst = xb_new_vreg(p, t);
	i.a = cond;
	i.b = a;
	i.c = b;
	xb_emit(p, i);
	if (xb_type_is_int(t)) xb_note_umax(p, i.dst, gb_max(xb_umax(p, a), xb_umax(p, b)));
	return i.dst;
}

gb_internal void xb_memcopy(xbProc *p, xbMem dst, xbMem src, i64 size) {
	if (size <= 0) return;
	// both memory operands are needed, so both go through pointer vregs
	xbInstr i = xb_instr(xbOp_MemCopy);
	i.a = xb_lea(p, dst);
	i.b = xb_lea(p, src);
	i.imm = size;
	xb_emit(p, i);
}

gb_internal void xb_memzero(xbProc *p, xbMem dst, i64 size) {
	if (size <= 0) return;
	xbInstr i = xb_instr(xbOp_MemZero);
	i.mem = dst;
	i.imm = size;
	xb_emit(p, i);
}

gb_internal void xb_jump(xbProc *p, xbBlock *target) {
	if (xb_curr_terminated(p)) return;
	xbInstr i = xb_instr(xbOp_Jump);
	i.imm = target->index;
	xb_emit(p, i);
}

gb_internal void xb_branch(xbProc *p, u32 cond, xbBlock *then_, xbBlock *else_) {
	if (xb_curr_terminated(p)) return;
	i64 c = 0;
	if (xb_known(p, cond, &c)) {
		xb_jump(p, (c & 0xff) != 0 ? then_ : else_);
		return;
	}
	xbInstr i = xb_instr(xbOp_Branch);
	i.a = cond;
	i.imm = then_->index;
	i.c = cast(u32)else_->index;
	xb_emit(p, i);
}

gb_internal void xb_unreachable(xbProc *p) {
	if (xb_curr_terminated(p)) return;
	xb_emit(p, xb_instr(xbOp_Unreachable));
}

gb_internal i32 xb_add_local_raw(xbProc *p, i64 size, i64 align) {
	if (align > 4096) {
		XB_UNSUPPORTED(p, "over-aligned local");
	}
	xbLocal l = {};
	l.size = gb_max(size, cast(i64)1);
	l.align = gb_max(align, cast(i64)1);
	if (align > 16) {
		l.over_align = align;
		l.align = 16;
	}
	array_add(&p->locals, l);
	return cast(i32)(p->locals.count-1);
}

gb_internal xbMem xb_add_local(xbProc *p, Type *t, bool zero) {
	i64 size = type_size_of(t);
	i64 align = type_align_of(t);
	i32 l = xb_add_local_raw(p, size, align);
	xbMem m = xb_mem(xbMem_Local, cast(u32)l);
	if (zero) {
		xb_memzero(p, m, size);
	}
	return m;
}

////////////////////////////////////////////////////////////////
// Types
////////////////////////////////////////////////////////////////

// The vreg type for an Odin type held in a register, or None if it lives in memory.
gb_internal xbType xb_scalar_type(Type *t) {
	t = core_type(t);
	switch (t->kind) {
	case Type_Basic:
		switch (t->Basic.kind) {
		case Basic_llvm_bool:
		case Basic_bool: case Basic_b8: case Basic_i8: case Basic_u8:
			return xbType_I8;
		case Basic_b16: case Basic_i16: case Basic_u16: case Basic_i16le: case Basic_u16le: case Basic_i16be: case Basic_u16be:
			return xbType_I16;
		case Basic_b32: case Basic_i32: case Basic_u32: case Basic_rune: case Basic_i32le: case Basic_u32le: case Basic_i32be: case Basic_u32be:
			return xbType_I32;
		case Basic_b64: case Basic_i64: case Basic_u64: case Basic_i64le: case Basic_u64le: case Basic_i64be: case Basic_u64be:
		case Basic_int: case Basic_uint: case Basic_uintptr:
		case Basic_rawptr: case Basic_cstring: case Basic_cstring16: case Basic_typeid:
			return xbType_I64;
		case Basic_f32: case Basic_f32le: case Basic_f32be:
			return xbType_F32;
		case Basic_f64: case Basic_f64le: case Basic_f64be:
			return xbType_F64;
		}
		return xbType_None;
	case Type_Pointer:
	case Type_MultiPointer:
	case Type_Proc:
		return xbType_I64;
	case Type_Enum:
		return xb_scalar_type(t->Enum.base_type);
	case Type_BitSet: {
		Type *backing = bit_set_to_int(t);
		if (is_type_array(backing)) backing = base_array_type(backing);
		if (is_type_different_to_arch_endianness(backing) || is_type_endian_big(backing)) {
			return xbType_None;
		}
		i64 sz = type_size_of(t);
		switch (sz) {
		case 1: return xbType_I8;
		case 2: return xbType_I16;
		case 4: return xbType_I32;
		case 8: return xbType_I64;
		}
		return xbType_None;
	}
	case Type_BitField:
		return xb_scalar_type(t->BitField.backing_type);
	}
	return xbType_None;
}

gb_internal bool xb_is_scalar(Type *t) {
	return xb_scalar_type(t) != xbType_None;
}

gb_internal bool xb_type_is_signed(Type *t) {
	t = core_type(t);
	if (t->kind == Type_Enum) {
		return xb_type_is_signed(t->Enum.base_type);
	}
	if (t->kind == Type_BitSet || t->kind == Type_BitField) {
		return false;
	}
	if (t->kind == Type_Basic) {
		if (t->Basic.flags & BasicFlag_Integer) {
			return !(t->Basic.flags & BasicFlag_Unsigned);
		}
		if (t->Basic.kind == Basic_rune) {
			return true;
		}
	}
	return false;
}

////////////////////////////////////////////////////////////////
// Values
////////////////////////////////////////////////////////////////

gb_internal xbValue xb_value_reg(Type *t, u32 reg) {
	xbValue v = {};
	v.kind = xbValue_Reg;
	v.type = t;
	v.reg = reg;
	return v;
}

gb_internal xbValue xb_value_mem(Type *t, xbMem mem) {
	xbValue v = {};
	v.kind = xbValue_Mem;
	v.type = t;
	v.mem = mem;
	return v;
}

gb_internal xbAddr xb_addr(Type *t, xbMem mem) {
	xbAddr a = {};
	a.kind = xbAddr_Default;
	a.type = t;
	a.mem = mem;
	return a;
}

gb_internal xbValue xb_load_value(xbProc *p, Type *t, xbMem mem) {
	xbType st = xb_scalar_type(t);
	if (st != xbType_None) {
		xbValue v = xb_value_reg(t, xb_load(p, st, mem));
		v.has_origin = true;
		v.origin = mem;
		return v;
	}
	return xb_value_mem(t, mem);
}

gb_internal void xb_store_value(xbProc *p, xbMem dst, xbValue v);

// lb_address_from_load_or_generate_local
gb_internal xbMem xb_address_from_load_or_generate_local(xbProc *p, xbValue v) {
	if (v.kind == xbValue_Mem) return v.mem;
	if (v.has_origin) return v.origin;
	xbMem m = xb_add_local(p, v.type, false);
	xb_store_value(p, m, v);
	return m;
}

// Copies the value to memory at `dst`.
gb_internal void xb_store_value(xbProc *p, xbMem dst, xbValue v) {
	GB_ASSERT(v.kind != xbValue_Invalid);
	if (v.kind == xbValue_Reg) {
		xbType st = xb_scalar_type(v.type);
		GB_ASSERT_MSG(st != xbType_None, "%s", type_to_string(v.type));
		xb_store(p, st, dst, v.reg);
	} else {
		i64 size = type_size_of(v.type);
		if (dst.kind == v.mem.kind && dst.base == v.mem.base && dst.offset == v.mem.offset) {
			return;
		}
		xb_memcopy(p, dst, v.mem, size);
	}
}

// A copy of the value in fresh memory, safe from later writes to its source.
gb_internal xbValue xb_value_copy_to_temp(xbProc *p, xbValue v) {
	xbMem m = xb_add_local(p, v.type, false);
	xb_store_value(p, m, v);
	return xb_value_mem(v.type, m);
}

// The address of the value, spilling it to a temporary if it is in a register.
gb_internal xbMem xb_value_to_mem(xbProc *p, xbValue v) {
	if (v.kind == xbValue_Mem) {
		return v.mem;
	}
	xbMem m = xb_add_local(p, v.type, false);
	xb_store_value(p, m, v);
	return m;
}

gb_internal u32 xb_value_to_reg(xbProc *p, xbValue v) {
	if (v.kind == xbValue_Reg) {
		return v.reg;
	}
	xbType st = xb_scalar_type(v.type);
	GB_ASSERT_MSG(st != xbType_None, "%s", type_to_string(v.type));
	return xb_load(p, st, v.mem);
}

gb_internal xbValue xb_zero_value(xbProc *p, Type *t) {
	if (is_type_untyped_nil(t) || is_type_untyped_uninit(t)) {
		xbValue v = {};
		v.kind = xbValue_Invalid;
		v.type = t;
		return v;
	}
	xbType st = xb_scalar_type(t);
	if (st != xbType_None) {
		if (xb_type_is_float(st)) {
			return xb_value_reg(t, xb_fconst(p, st, 0));
		}
		return xb_value_reg(t, xb_iconst(p, st, 0));
	}
	return xb_value_mem(t, xb_add_local(p, t, true));
}

gb_internal xbValue xb_const_int(xbProc *p, Type *t, i64 v) {
	xbType st = xb_scalar_type(t);
	GB_ASSERT(xb_type_is_int(st));
	return xb_value_reg(t, xb_iconst(p, st, v));
}

gb_internal xbValue xb_const_bool(xbProc *p, bool b) {
	return xb_value_reg(t_bool, xb_iconst(p, xbType_I8, b ? 1 : 0));
}

// pointer arithmetic helpers
gb_internal u32 xb_ptr_add_const(xbProc *p, u32 ptr, i64 offset) {
	if (offset == 0) return ptr;
	return xb_lea(p, xb_mem(xbMem_Reg, ptr, cast(i32)offset));
}

gb_internal u32 xb_ptr_add_scaled(xbProc *p, u32 ptr, u32 index, i64 scale) {
	u32 off = index;
	if (scale != 1) {
		off = xb_binop(p, xbOp_Mul, xbType_I64, index, xb_iconst(p, xbType_I64, scale));
	}
	return xb_binop(p, xbOp_Add, xbType_I64, ptr, off);
}

// a value of type `t` that is a field at `offset` in memory value `v`
gb_internal xbValue xb_value_field(xbProc *p, xbValue v, i64 offset, Type *field_type) {
	GB_ASSERT(v.kind == xbValue_Mem);
	return xb_load_value(p, field_type, xb_mem_offset(v.mem, offset));
}

gb_internal xbMem xb_mem_from_ptr(xbProc *p, xbValue ptr) {
	return xb_mem(xbMem_Reg, xb_value_to_reg(p, ptr), 0);
}

////////////////////////////////////////////////////////////////
// Symbols
////////////////////////////////////////////////////////////////

// The hash of a symbol name or string literal: murmur reads 8 bytes a step, fnv32a one, and
// mangled names are long.
gb_internal u32 xb_name_hash(String s) {
	u32 hash = cast(u32)gb_murmur64(s.text, s.len) & 0x7fffffff;
	return hash | (hash == 0);
}

gb_internal i32 *xb_symbol_find(xbModule *m, String name) {
	return string_map_get(&m->symbol_map, xb_name_hash(name), name);
}

gb_internal i32 xb_symbol(xbModule *m, String name) {
	i32 index = -1;
	u32 hash = xb_name_hash(name);
	if (i32 *found = string_map_get(&m->symbol_map, hash, name)) {
		index = *found;
	} else {
		xbSymbol s = {};
		s.name = copy_string(permanent_allocator(), name);
		s.section = xbSection_Undef;
		s.flags = xbSymbolFlag_Global;
		index = cast(i32)m->symbols.count;
		array_add(&m->symbols, s);
		string_map_set(&m->symbol_map, hash, s.name, index);
	}
	if (xb_shadow_logs(m) && !xb_shadow_seen(m, xbShadowOp_Sym, cast(u64)index)) {
		// every use: the real module may only get the symbol in a later one
		xbShadowOp *op = xb_shadow_log(m, xbShadowOp_Sym);
		op->str = m->symbols[index].name;
		op->sym = index;
	}
	return index;
}

// The only writes to a symbol's fields while procedures are built, so they can be replayed.
gb_internal void xb_sym_add_flags(xbModule *m, i32 sym, u8 flags) {
	m->symbols[sym].flags |= flags;
	if (xb_shadow_logs(m) && !xb_shadow_seen(m, xbShadowOp_SymAddFlags, cast(u64)sym | (cast(u64)flags << 32))) {
		xbShadowOp *op = xb_shadow_log(m, xbShadowOp_SymAddFlags);
		op->sym = sym;
		op->a = flags;
	}
}

gb_internal void xb_sym_set_flags(xbModule *m, i32 sym, u8 flags) {
	m->symbols[sym].flags = flags;
	if (xb_shadow_logs(m)) {
		xbShadowOp *op = xb_shadow_log(m, xbShadowOp_SymSetFlags);
		op->sym = sym;
		op->a = flags;
	}
}

gb_internal void xb_sym_set_realign(xbModule *m, i32 sym, i64 realign) {
	m->symbols[sym].realign = realign;
	if (xb_shadow_logs(m)) {
		xbShadowOp *op = xb_shadow_log(m, xbShadowOp_SymRealign);
		op->sym = sym;
		op->a = realign;
	}
}

gb_internal i32 xb_symbol(xbModule *m, String name);

// Places the symbol in a data section.
gb_internal void xb_sym_define(xbModule *m, i32 sym, xbSection section, i64 offset, i64 size) {
	xbSymbol *s = &m->symbols[sym];
	s->section = section;
	s->offset = offset;
	s->size = size;
	if (xb_shadow_logs(m)) {
		xbShadowOp *op = xb_shadow_log(m, xbShadowOp_SymDefine);
		op->sym = sym;
		op->sec = section;
		op->a = offset;
		op->b = size;
	}
}

// A symbol for data at `offset` in `section`, named after the offset: `prefix` and the offset.
gb_internal i32 xb_offset_symbol(xbModule *m, char const *prefix, xbSection section, i64 offset, i64 size, u8 flags) {
	char name[96] = {};
	gb_snprintf(name, gb_size_of(name), "%s%lld", prefix, cast(long long)offset);
	m->shadow_quiet += 1;
	i32 sym = xb_symbol(m, make_string_c(name));
	xb_sym_define(m, sym, section, offset, size);
	xb_sym_set_flags(m, sym, flags);
	m->shadow_quiet -= 1;
	if (xb_shadow_logs(m)) {
		// named after the offset in the real module
		xbShadowOp *op = xb_shadow_log(m, xbShadowOp_OffsetSym);
		op->str = copy_string(permanent_allocator(), make_string_c(prefix));
		op->sec = section;
		op->a = offset;
		op->b = size;
		op->c = flags;
		op->sym = sym;
	}
	return sym;
}

gb_internal String xb_entity_name(xbModule *m, Entity *e);
gb_internal void xb_log_fallback(xbModule *m, char const *what, String name, TokenPos fallback_pos, char const *reason);

// the linker needs every foreign library a foreign entity comes from
gb_internal void xb_note_foreign_library(xbModule *m, Entity *lib) {
	if (lib == nullptr) return;
	if (!ptr_set_update(&m->foreign_libs_set, lib)) {
		array_add(&m->foreign_libs, lib);
	}
	if (xb_shadow_logs(m) && !xb_shadow_seen(m, xbShadowOp_ForeignLib, cast(u64)cast(uintptr)lib)) {
		xb_shadow_log(m, xbShadowOp_ForeignLib)->ptr = lib;
	}
}

gb_internal i32 xb_entity_symbol(xbProc *p, Entity *e) {
	String name = xb_entity_name(p->m, e);
	i32 sym = xb_symbol(p->m, name);
	u8 flags = 0;
	if (e->kind == Entity_Procedure) {
		flags |= xbSymbolFlag_Func;
		if (e->Procedure.is_export) flags |= xbSymbolFlag_Export;
		if (e->Procedure.is_foreign) {
			flags |= xbSymbolFlag_Foreign;
			xb_note_foreign_library(p->m, e->Procedure.foreign_library);
		}
	} else if (e->kind == Entity_Variable) {
		if (e->Variable.is_export) flags |= xbSymbolFlag_Export;
		if (e->Variable.is_foreign) {
			flags |= xbSymbolFlag_Foreign;
			xb_note_foreign_library(p->m, e->Variable.foreign_library);
		}
		if (e->Variable.thread_local_model.len != 0) {
			flags |= xbSymbolFlag_TLS;
			xb_sym_set_realign(p->m, sym, lb_tls_realign(e));
		}
	}
	xb_sym_add_flags(p->m, sym, flags);
	return sym;
}

// Appends bytes to a section with contents, after zeros up to `align`. Returns their offset.
// Unlike xb_section_reserve, it leaves the section's alignment alone.
gb_internal i64 xb_section_append(xbModule *m, xbSection section, void const *data, isize size, i64 align) {
	Array<u8> *sec = &m->sections[section];
	while (sec->count % align != 0) {
		array_add(sec, cast(u8)0);
	}
	i64 offset = sec->count;
	if (data != nullptr) {
		array_add_elems(sec, cast(u8 const *)data, size);
	} else {
		array_resize(sec, offset + size);
		gb_zero_size(sec->data + offset, size);
	}
	if (xb_shadow_logs(m)) {
		// the replay takes the bytes as the shadow leaves them, with later writes
		xbShadowOp *op = xb_shadow_log(m, xbShadowOp_Append);
		op->sec = section;
		op->a = offset;
		op->b = size;
		op->c = align;
	}
	return offset;
}

// Overwrites bytes that are already in a section.
gb_internal void xb_section_write(xbModule *m, xbSection section, i64 offset, void const *data, isize size) {
	gb_memmove(m->sections[section].data + offset, data, size);
}

// Read-only data.
gb_internal i32 xb_rodata(xbModule *m, void const *data, isize size, i64 align) {
	i64 offset = xb_section_append(m, xbSection_Rodata, data, size, align);
	return xb_offset_symbol(m, ".Lxb.ro.", xbSection_Rodata, offset, size, 0);
}

// A NUL terminated string literal in read-only data.
gb_internal i32 xb_string_literal(xbModule *m, String str) {
	u32 hash = xb_name_hash(str);
	i32 sym = -1;
	String key = {};
	MapFindResult fr = string_map__find(&m->string_lits, hash, str);
	if (fr.entry_index != MAP_SENTINEL) {
		sym = m->string_lits.entries[fr.entry_index].value;
		key = m->string_lits.entries[fr.entry_index].key;
	} else {
		m->shadow_quiet += 1;
		sym = xb_rodata(m, str.text, str.len, 1);
		u8 nul = 0;
		xb_section_append(m, xbSection_Rodata, &nul, 1, 1);
		xb_sym_define(m, sym, xbSection_Rodata, m->symbols[sym].offset, str.len+1);
		m->shadow_quiet -= 1;
		key = copy_string(permanent_allocator(), str);
		string_map_set(&m->string_lits, hash, key, sym);
	}
	if (xb_shadow_logs(m) && !xb_shadow_seen(m, xbShadowOp_StringLit, cast(u64)sym)) {
		// every use: the real module may only get the literal in a later one
		xbShadowOp *op = xb_shadow_log(m, xbShadowOp_StringLit);
		op->str = key;
		op->sym = sym;
	}
	return sym;
}

gb_internal i32 xb_string16_literal_raw(xbModule *m, String16 s16, isize *len_out) {
	TEMPORARY_ALLOCATOR_GUARD();
	*len_out = s16.len;
	u16 *buf = gb_alloc_array(temporary_allocator(), u16, s16.len+1);
	gb_memmove(buf, s16.text, s16.len*2);
	buf[s16.len] = 0;
	return xb_rodata(m, buf, (s16.len+1)*2, 2);
}

gb_internal i32 xb_string16_literal(xbModule *m, String str, isize *len_out) {
	TEMPORARY_ALLOCATOR_GUARD();
	String16 s16 = string_to_string16(temporary_allocator(), str);
	*len_out = s16.len;
	u16 *buf = gb_alloc_array(temporary_allocator(), u16, s16.len+1);
	gb_memmove(buf, s16.text, s16.len*2);
	buf[s16.len] = 0;
	return xb_rodata(m, buf, (s16.len+1)*2, 2);
}

////////////////////////////////////////////////////////////////
// Context
////////////////////////////////////////////////////////////////

gb_internal void xb_push_context(xbProc *p, xbMem mem, bool indirect) {
	xbContextEntry e = {};
	e.mem = mem;
	e.indirect = indirect;
	e.scope_index = p->scope_index;
	array_add(&p->context_stack, e);
}

gb_internal void xb_emit_runtime_call_init_context(xbProc *p, xbMem ctx);

// The address of the current context struct.
gb_internal xbMem xb_context_mem(xbProc *p) {
	if (p->context_stack.count == 0) {
		// procedures without an implicit context make their own
		xbMem c = xb_add_local(p, t_context, true);
		xb_emit_runtime_call_init_context(p, c);
		xb_push_context(p, c, false);
		p->context_stack[p->context_stack.count-1].scope_index = -1;
		// a debugger shows it as `context`, like LLVM's
		xbDebugVar dv = {};
		dv.name = str_lit("context");
		dv.type = t_context;
		dv.local = cast(i32)c.base;
		dv.line = p->entity ? p->entity->token.pos.line : 0;
		dv.scope = p->debug_scope;
		array_add(&p->debug_vars, dv);
	}
	xbContextEntry *e = &p->context_stack[p->context_stack.count-1];
	e->uses += 1;
	if (e->indirect) {
		return xb_mem(xbMem_Reg, xb_load(p, xbType_I64, e->mem), 0);
	}
	return e->mem;
}

gb_internal u32 xb_context_ptr(xbProc *p) {
	return xb_lea(p, xb_context_mem(p));
}

////////////////////////////////////////////////////////////////
// Conversions
////////////////////////////////////////////////////////////////

gb_internal xbValue xb_emit_conv(xbProc *p, xbValue v, Type *t);
gb_internal xbValue xb_emit_transmute(xbProc *p, xbValue v, Type *t);
gb_internal xbValue xb_emit_runtime_call(xbProc *p, char const *name, Slice<xbValue> args);
gb_internal xbValue xb_typeid_value(xbProc *p, Type *t);
gb_internal xbValue xb_emit_union_wrap(xbProc *p, Type *union_type, Type *variant, xbValue v);
gb_internal xbCond  xb_cond_for(TokenKind op, bool is_signed, bool is_float);
gb_internal IntegerDivisionByZeroKind xb_division_by_zero_behaviour(xbProc *p);
gb_internal xbValue xb_emit_record_equal(xbProc *p, TokenKind op, xbValue left, xbValue right, Type *type);
gb_internal i32     xb_equal_proc_sym(xbProc *caller, Type *type);
gb_internal i32     xb_hasher_proc_sym(xbProc *caller, Type *type);
gb_internal i32     xb_map_cell_info_sym(xbModule *m, Type *type);
gb_internal xbValue xb_emit_call_internal(xbProc *p, xbValue proc, i32 direct_sym, Slice<xbValue> args);
gb_internal void    xb_emit_ret(xbProc *p, xbMem direct_result);
gb_internal xbAbiFunc *xb_get_abi(xbProc *p, Type *proc_type);
gb_internal void    xb_begin_proc(xbProc *p);
gb_internal void    xb_end_proc(xbProc *p);
gb_internal xbValue xb_simd_conv(xbProc *p, xbValue v, Type *t);
gb_internal xbValue xb_simd_comp(xbProc *p, TokenKind op, xbValue left, xbValue right);
gb_internal xbValue xb_simd_neg(xbProc *p, xbValue x, Type *type);
gb_internal xbValue xb_simd_not(xbProc *p, xbValue x, Type *type);
gb_internal xbValue xb_build_builtin_simd_proc(xbProc *p, Ast *expr, TypeAndValue const &tv, BuiltinProcId id);
gb_internal xbValue xb_build_builtin_vector_proc(xbProc *p, Ast *expr, TypeAndValue const &tv, BuiltinProcId id);
gb_internal xbValue xb_build_objc_builtin(xbProc *p, Ast *expr, BuiltinProcId id);
gb_internal xbValue xb_objc_auto_send(xbProc *p, Ast *expr, Slice<xbValue> arg_values);
gb_internal xbValue xb_objc_ivar_ptr(xbProc *p, xbValue self);

// int -> int of possibly different width
gb_internal u32 xb_int_resize(xbProc *p, u32 v, xbType from, xbType to, bool from_signed) {
	i32 fs = xb_type_size(from);
	i32 ts = xb_type_size(to);
	if (fs == ts) return v;
	if (ts < fs) return xb_convop(p, xbOp_Trunc, to, from, v);
	return xb_convop(p, from_signed ? xbOp_Sext : xbOp_Zext, to, from, v);
}

gb_internal u32 xb_to_bool_reg(xbProc *p, xbValue v) {
	// any non-zero value is true
	u32 r = xb_value_to_reg(p, v);
	xbType st = xb_scalar_type(v.type);
	if (v.type == t_llvm_bool) {
		return r; // already 0 or 1
	}
	return xb_cmp(p, xbCond_NE, st, r, xb_iconst(p, st, 0));
}


////////////////////////////////////////////////////////////////
// 128-bit integers, held in memory as two 64-bit halves
////////////////////////////////////////////////////////////////

struct xbPair {
	u32 lo;
	u32 hi;
};

gb_internal bool xb_is_int128(Type *t) {
	return is_type_integer_128bit(core_type(t));
}

gb_internal bool xb_op_is_pure(xbOp op);

// The vreg stored to the frame local `m` earlier in the current block, if nothing since may
// have written it, or 0.
gb_internal u32 xb_stored_value(xbProc *p, xbType t, xbMem m) {
	if (p->curr == nullptr || m.kind != xbMem_Local || xb_curr_terminated(p)) return 0;
	// a short look back keeps long blocks linear
	isize stop = gb_max(p->curr->instrs.count - 64, 0);
	for (isize i = p->curr->instrs.count-1; i >= stop; i--) {
		xbInstr const &in = p->curr->instrs[i];
		switch (in.op) {
		case xbOp_Nop:
		case xbOp_Loc:
		case xbOp_Scope:
		case xbOp_Load:
			continue;
		case xbOp_Store:
			if (in.flags & xbInstrFlag_Volatile) return 0;
			if (in.mem.kind == xbMem_Reg) return 0; // may point into the local
			if (in.mem.kind != xbMem_Local || in.mem.base != m.base) continue;
			if (in.mem.offset == m.offset && in.type == t) return in.a;
			if (in.mem.offset + xb_type_size(in.type) <= m.offset || m.offset + xb_type_size(t) <= in.mem.offset) continue;
			return 0;
		}
		if (!xb_op_is_pure(in.op)) return 0;
	}
	return 0;
}

gb_internal xbPair xb_pair_load(xbProc *p, xbMem m) {
	xbPair r = {};
	xbMem hi = xb_mem_offset(m, 8);
	r.lo = xb_stored_value(p, xbType_I64, m);
	r.hi = xb_stored_value(p, xbType_I64, hi);
	if (r.lo == 0) r.lo = xb_load(p, xbType_I64, m);
	if (r.hi == 0) r.hi = xb_load(p, xbType_I64, hi);
	return r;
}

gb_internal xbValue xb_pair_value(xbProc *p, Type *t, xbPair v) {
	xbMem m = xb_add_local(p, t, false);
	xb_store(p, xbType_I64, m, v.lo);
	xb_store(p, xbType_I64, xb_mem_offset(m, 8), v.hi);
	return xb_value_mem(t, m);
}

gb_internal xbPair xb_pair_of(xbProc *p, xbValue v) {
	return xb_pair_load(p, xb_value_to_mem(p, v));
}

gb_internal u32 xb_i64(xbProc *p, i64 v) { return xb_iconst(p, xbType_I64, v); }

gb_internal bool xb_vreg_const(xbProc *p, u32 v, i64 *out);

// shifts of a pair by a count in a vreg, with Odin's semantics for large counts
gb_internal xbPair xb_pair_shift(xbProc *p, xbPair x, u32 count, TokenKind op, bool is_signed) {
	i64 c = 0;
	if (xb_vreg_const(p, count, &c)) {
		u64 n = cast(u64)c;
		xbOp sh = op == Token_Shl ? xbOp_Shl : is_signed ? xbOp_AShr : xbOp_LShr;
		u32 fill = (op != Token_Shl && is_signed) ? xb_binop(p, xbOp_AShr, xbType_I64, x.hi, xb_i64(p, 63)) : xb_i64(p, 0);
		xbPair r = {};
		if (n == 0) return x;
		if (n >= 128) return xbPair{fill, fill};
		if (n >= 64) {
			if (op == Token_Shl) {
				r.lo = fill;
				r.hi = n == 64 ? x.lo : xb_binop(p, xbOp_Shl, xbType_I64, x.lo, xb_i64(p, n-64));
			} else {
				r.lo = n == 64 ? x.hi : xb_binop(p, sh, xbType_I64, x.hi, xb_i64(p, n-64));
				r.hi = fill;
			}
			return r;
		}
		u32 by = xb_i64(p, n);
		u32 back = xb_i64(p, 64-n);
		if (op == Token_Shl) {
			r.lo = xb_binop(p, xbOp_Shl, xbType_I64, x.lo, by);
			r.hi = xb_binop(p, xbOp_Or, xbType_I64, xb_binop(p, xbOp_Shl, xbType_I64, x.hi, by), xb_binop(p, xbOp_LShr, xbType_I64, x.lo, back));
		} else {
			r.lo = xb_binop(p, xbOp_Or, xbType_I64, xb_binop(p, xbOp_LShr, xbType_I64, x.lo, by), xb_binop(p, xbOp_Shl, xbType_I64, x.hi, back));
			r.hi = xb_binop(p, sh, xbType_I64, x.hi, by);
		}
		return r;
	}
	u32 zero = xb_i64(p, 0);
	u32 c64 = xb_i64(p, 64);
	u32 big = xb_cmp(p, xbCond_UGE, xbType_I64, count, xb_i64(p, 128));
	u32 ge64 = xb_cmp(p, xbCond_UGE, xbType_I64, count, c64);
	u32 is0 = xb_cmp(p, xbCond_EQ, xbType_I64, count, zero);
	u32 inv = xb_binop(p, xbOp_Sub, xbType_I64, c64, count);       // 64-c, used when 0 < c < 64
	u32 cm = xb_binop(p, xbOp_Sub, xbType_I64, count, c64);        // c-64, used when 64 <= c < 128
	xbPair r = {};
	if (op == Token_Shl) {
		u32 hi_small = xb_binop(p, xbOp_Or, xbType_I64, xb_binop(p, xbOp_Shl, xbType_I64, x.hi, count), xb_binop(p, xbOp_LShr, xbType_I64, x.lo, inv));
		hi_small = xb_select(p, xbType_I64, is0, x.hi, hi_small);
		u32 lo_small = xb_binop(p, xbOp_Shl, xbType_I64, x.lo, count);
		u32 hi_large = xb_binop(p, xbOp_Shl, xbType_I64, x.lo, cm);
		r.hi = xb_select(p, xbType_I64, ge64, hi_large, hi_small);
		r.lo = xb_select(p, xbType_I64, ge64, zero, lo_small);
		r.hi = xb_select(p, xbType_I64, big, zero, r.hi);
		r.lo = xb_select(p, xbType_I64, big, zero, r.lo);
		return r;
	}
	xbOp sh = is_signed ? xbOp_AShr : xbOp_LShr;
	u32 fill = is_signed ? xb_binop(p, xbOp_AShr, xbType_I64, x.hi, xb_i64(p, 63)) : zero;
	u32 lo_small = xb_binop(p, xbOp_Or, xbType_I64, xb_binop(p, xbOp_LShr, xbType_I64, x.lo, count), xb_binop(p, xbOp_Shl, xbType_I64, x.hi, inv));
	lo_small = xb_select(p, xbType_I64, is0, x.lo, lo_small);
	u32 hi_small = xb_binop(p, sh, xbType_I64, x.hi, count);
	u32 lo_large = xb_binop(p, sh, xbType_I64, x.hi, cm);
	r.lo = xb_select(p, xbType_I64, ge64, lo_large, lo_small);
	r.hi = xb_select(p, xbType_I64, ge64, fill, hi_small);
	r.lo = xb_select(p, xbType_I64, big, fill, r.lo);
	r.hi = xb_select(p, xbType_I64, big, fill, r.hi);
	return r;
}

gb_internal xbValue xb_emit_arith_128(xbProc *p, TokenKind op, xbValue x, xbValue y, Type *type) {
	bool is_signed = !is_type_unsigned(type);
	if (op == Token_Shl || op == Token_Shr) {
		xbPair a = xb_pair_of(p, xb_emit_conv(p, x, type));
		u32 count = 0;
		if (xb_is_int128(y.type)) {
			xbPair c = xb_pair_of(p, y);
			// any high bits make it a huge count
			u32 hi_set = xb_cmp(p, xbCond_NE, xbType_I64, c.hi, xb_i64(p, 0));
			count = xb_select(p, xbType_I64, hi_set, xb_i64(p, 128), c.lo);
		} else {
			xbType yt = xb_scalar_type(y.type);
			if (yt == xbType_None || xb_type_is_float(yt)) XB_UNSUPPORTED(p, "shift count type");
			count = xb_int_resize(p, xb_value_to_reg(p, y), yt, xbType_I64, false);
		}
		return xb_pair_value(p, type, xb_pair_shift(p, a, count, op, is_signed));
	}
	xbPair a = xb_pair_of(p, xb_emit_conv(p, x, type));
	xbPair b = xb_pair_of(p, xb_emit_conv(p, y, type));
	xbPair r = {};
	switch (op) {
	case Token_Add: {
		r.lo = xb_binop(p, xbOp_Add, xbType_I64, a.lo, b.lo);
		u32 carry = xb_int_resize(p, xb_cmp(p, xbCond_ULT, xbType_I64, r.lo, a.lo), xbType_I8, xbType_I64, false);
		r.hi = xb_binop(p, xbOp_Add, xbType_I64, xb_binop(p, xbOp_Add, xbType_I64, a.hi, b.hi), carry);
		break;
	}
	case Token_Sub: {
		r.lo = xb_binop(p, xbOp_Sub, xbType_I64, a.lo, b.lo);
		u32 borrow = xb_int_resize(p, xb_cmp(p, xbCond_ULT, xbType_I64, a.lo, b.lo), xbType_I8, xbType_I64, false);
		r.hi = xb_binop(p, xbOp_Sub, xbType_I64, xb_binop(p, xbOp_Sub, xbType_I64, a.hi, b.hi), borrow);
		break;
	}
	case Token_Mul: {
		// a high half known to be zero adds nothing, as for widened 64 bit values
		i64 c = 0;
		bool a_hi_zero = xb_vreg_const(p, a.hi, &c) && c == 0;
		bool b_hi_zero = xb_vreg_const(p, b.hi, &c) && c == 0;
		r.lo = xb_binop(p, xbOp_Mul, xbType_I64, a.lo, b.lo);
		u32 hi = xb_binop(p, xbOp_MulHiU, xbType_I64, a.lo, b.lo);
		if (!b_hi_zero) hi = xb_binop(p, xbOp_Add, xbType_I64, hi, xb_binop(p, xbOp_Mul, xbType_I64, a.lo, b.hi));
		if (!a_hi_zero) hi = xb_binop(p, xbOp_Add, xbType_I64, hi, xb_binop(p, xbOp_Mul, xbType_I64, a.hi, b.lo));
		r.hi = hi;
		break;
	}
	case Token_And: r.lo = xb_binop(p, xbOp_And, xbType_I64, a.lo, b.lo); r.hi = xb_binop(p, xbOp_And, xbType_I64, a.hi, b.hi); break;
	case Token_Or:  r.lo = xb_binop(p, xbOp_Or,  xbType_I64, a.lo, b.lo); r.hi = xb_binop(p, xbOp_Or,  xbType_I64, a.hi, b.hi); break;
	case Token_Xor: r.lo = xb_binop(p, xbOp_Xor, xbType_I64, a.lo, b.lo); r.hi = xb_binop(p, xbOp_Xor, xbType_I64, a.hi, b.hi); break;
	case Token_AndNot:
		r.lo = xb_binop(p, xbOp_And, xbType_I64, a.lo, xb_unop(p, xbOp_Not, xbType_I64, b.lo));
		r.hi = xb_binop(p, xbOp_And, xbType_I64, a.hi, xb_unop(p, xbOp_Not, xbType_I64, b.hi));
		break;
	case Token_Quo:
	case Token_Mod:
	case Token_ModMod: {
		Type *rt = is_signed ? t_i128 : t_u128;
		IntegerDivisionByZeroKind behaviour = xb_division_by_zero_behaviour(p);
		bool is_div = op == Token_Quo;
		xbMem res = xb_add_local(p, type, false);
		xbBlock *safe_block = xb_new_block(p);
		xbBlock *edge_block = xb_new_block(p);
		xbBlock *done_block = xb_new_block(p);
		u32 bz = xb_binop(p, xbOp_Or, xbType_I64, b.lo, b.hi);
		xb_branch(p, xb_cmp(p, xbCond_NE, xbType_I64, bz, xb_i64(p, 0)), safe_block, edge_block);

		xb_start_block(p, safe_block);
		{
			xbPair sb = b;
			if (!is_div && is_signed) {
				// a -1 divisor becomes 1, min(T) % -1 is 0
				u32 m1 = xb_binop(p, xbOp_And, xbType_I8,
					xb_cmp(p, xbCond_EQ, xbType_I64, b.lo, xb_i64(p, -1)),
					xb_cmp(p, xbCond_EQ, xbType_I64, b.hi, xb_i64(p, -1)));
				sb.lo = xb_select(p, xbType_I64, m1, xb_i64(p, 1), b.lo);
				sb.hi = xb_select(p, xbType_I64, m1, xb_i64(p, 0), b.hi);
			}
			char const *name = nullptr;
			if (is_div) name = is_signed ? "divti3" : "udivti3";
			else name = is_signed ? "modti3" : "umodti3";
			xbValue args[2] = {xb_pair_value(p, rt, a), xb_pair_value(p, rt, sb)};
			xbValue r = xb_emit_runtime_call(p, name, xb_args(args, 2));
			xbPair rp = xb_pair_of(p, r);
			if (op == Token_ModMod && is_signed) {
				// r + b when the signs differ and r is not zero
				xbPair a2 = xb_pair_load(p, xb_value_to_mem(p, xb_pair_value(p, rt, a)));
				u32 different = xb_cmp(p, xbCond_SLT, xbType_I64, xb_binop(p, xbOp_Xor, xbType_I64, a2.hi, b.hi), xb_i64(p, 0));
				u32 nonzero = xb_cmp(p, xbCond_NE, xbType_I64, xb_binop(p, xbOp_Or, xbType_I64, rp.lo, rp.hi), xb_i64(p, 0));
				u32 cond = xb_binop(p, xbOp_And, xbType_I8, different, nonzero);
				xbPair sum = xb_pair_of(p, xb_emit_arith_128(p, Token_Add, xb_pair_value(p, rt, rp), xb_pair_value(p, rt, b), rt));
				rp.lo = xb_select(p, xbType_I64, cond, sum.lo, rp.lo);
				rp.hi = xb_select(p, xbType_I64, cond, sum.hi, rp.hi);
			}
			xb_store(p, xbType_I64, res, rp.lo);
			xb_store(p, xbType_I64, xb_mem_offset(res, 8), rp.hi);
		}
		xb_jump(p, done_block);

		xb_start_block(p, edge_block);
		{
			xbPair ev = {};
			bool trap = false;
			switch (behaviour) {
			case IntegerDivisionByZero_Trap: trap = true; break;
			case IntegerDivisionByZero_Zero: ev = is_div ? xbPair{xb_i64(p, 0), xb_i64(p, 0)} : a; break;
			case IntegerDivisionByZero_Self: ev = is_div ? a : xbPair{xb_i64(p, 0), xb_i64(p, 0)}; break;
			case IntegerDivisionByZero_AllBits: ev = is_div ? xbPair{xb_i64(p, -1), xb_i64(p, -1)} : a; break;
			}
			if (trap) {
				xb_emit(p, xb_instr(xbOp_Trap));
				xb_unreachable(p);
			} else {
				xb_store(p, xbType_I64, res, ev.lo);
				xb_store(p, xbType_I64, xb_mem_offset(res, 8), ev.hi);
			}
		}
		xb_jump(p, done_block);
		xb_start_block(p, done_block);
		return xb_value_mem(type, res);
	}
	default:
		XB_UNSUPPORTED(p, "128-bit operation");
	}
	return xb_pair_value(p, type, r);
}

gb_internal xbValue xb_emit_comp_128(xbProc *p, TokenKind op, xbValue x, xbValue y, Type *type) {
	xbPair a = xb_pair_of(p, x);
	xbPair b = xb_pair_of(p, y);
	if (op == Token_CmpEq || op == Token_NotEq) {
		u32 lo = xb_cmp(p, xbCond_EQ, xbType_I64, a.lo, b.lo);
		u32 hi = xb_cmp(p, xbCond_EQ, xbType_I64, a.hi, b.hi);
		u32 eq = xb_binop(p, xbOp_And, xbType_I8, lo, hi);
		if (op == Token_NotEq) eq = xb_binop(p, xbOp_Xor, xbType_I8, eq, xb_iconst(p, xbType_I8, 1));
		return xb_value_reg(t_llvm_bool, eq);
	}
	bool sgn = !is_type_unsigned(type);
	xbCond hi_cond = xb_cond_for(op, sgn, false);
	xbCond lo_cond = xb_cond_for(op, false, false);
	// strict on the high half, the full predicate on the low half when the high halves are equal
	xbCond hi_strict = hi_cond;
	switch (hi_cond) {
	case xbCond_SLE: hi_strict = xbCond_SLT; break;
	case xbCond_SGE: hi_strict = xbCond_SGT; break;
	case xbCond_ULE: hi_strict = xbCond_ULT; break;
	case xbCond_UGE: hi_strict = xbCond_UGT; break;
	}
	u32 hs = xb_cmp(p, hi_strict, xbType_I64, a.hi, b.hi);
	u32 he = xb_cmp(p, xbCond_EQ, xbType_I64, a.hi, b.hi);
	u32 lc = xb_cmp(p, lo_cond, xbType_I64, a.lo, b.lo);
	u32 r = xb_binop(p, xbOp_Or, xbType_I8, hs, xb_binop(p, xbOp_And, xbType_I8, he, lc));
	return xb_value_reg(t_llvm_bool, r);
}

////////////////////////////////////////////////////////////////
// f16, held in memory and computed through f32
////////////////////////////////////////////////////////////////

gb_internal bool xb_is_f16(Type *t) {
	Type *c = core_type(t);
	return c->kind == Type_Basic && is_type_float(c) && type_size_of(c) == 2;
}

gb_internal xbValue xb_byte_swap_any(xbProc *p, xbValue v, Type *t);

// Without LLVM's f16 support the runtime's helpers pass the bits as a u16, see __ODIN_LLVM_F16_SUPPORTED.
gb_internal bool xb_f16_helpers_take_bits(void) {
	return xb_is_darwin() && build_context.metrics.arch == TargetArch_amd64;
}

gb_internal xbValue xb_f16_to_f32(xbProc *p, xbValue v) {
	if (is_type_different_to_arch_endianness(v.type)) v = xb_byte_swap_any(p, v, t_f16);
	v.type = t_f16;
	if (xb_is_arm64()) {
		// LLVM converts with fcvt on arm64, which rounds unlike the runtime's helpers
		u32 bits = xb_load(p, xbType_I16, xb_value_to_mem(p, v));
		return xb_value_reg(t_f32, xb_convop(p, xbOp_HalfToF, xbType_F32, xbType_I16, bits));
	}
	xbValue args[1] = {v};
	if (xb_f16_helpers_take_bits()) {
		args[0] = xb_value_reg(t_u16, xb_load(p, xbType_I16, xb_value_to_mem(p, v)));
	}
	xbValue r = xb_emit_runtime_call(p, "extendhfsf2", xb_args(args, 1));
	return xb_value_reg(t_f32, xb_value_to_reg(p, r));
}

gb_internal xbValue xb_float_to_f16(xbProc *p, xbValue v, Type *t) {
	if (is_type_different_to_arch_endianness(t)) {
		return xb_byte_swap_any(p, xb_float_to_f16(p, v, t_f16), t);
	}
	xbType st = xb_scalar_type(v.type);
	if (xb_is_arm64()) {
		// an f16 lives in memory
		u32 bits = xb_convop(p, xbOp_FToHalf, xbType_I16, st, xb_value_to_reg(p, v));
		xbMem m = xb_add_local(p, t, false);
		xb_store(p, xbType_I16, m, bits);
		return xb_value_mem(t, m);
	}
	xbValue args[1] = {v};
	xbValue r = xb_emit_runtime_call(p, st == xbType_F64 ? "truncdfhf2" : "truncsfhf2", xb_args(args, 1));
	if (xb_f16_helpers_take_bits()) {
		xbMem m = xb_add_local(p, t, false);
		xb_store(p, xbType_I16, m, xb_value_to_reg(p, r));
		return xb_value_mem(t, m);
	}
	r = xb_value_copy_to_temp(p, r);
	r.type = t;
	return r;
}


////////////////////////////////////////////////////////////////
// complex and quaternion values: arrays of 2 or 4 floats in memory
////////////////////////////////////////////////////////////////

gb_internal xbValue xb_complex_part(xbProc *p, xbValue v, i64 index) {
	Type *ft = base_complex_elem_type(core_type(v.type));
	xbMem m = xb_value_to_mem(p, v);
	return xb_load_value(p, ft, xb_mem_offset(m, index*type_size_of(ft)));
}

gb_internal xbValue xb_complex_build(xbProc *p, Type *t, xbValue *parts, isize n) {
	Type *ft = base_complex_elem_type(core_type(t));
	xbMem m = xb_add_local(p, t, false);
	for (isize i = 0; i < n; i++) {
		xb_store_value(p, xb_mem_offset(m, i*type_size_of(ft)), xb_emit_conv(p, parts[i], ft));
	}
	return xb_value_mem(t, m);
}

gb_internal xbValue xb_byte_swap(xbProc *p, xbValue v, Type *t) {
	if (xb_is_int128(v.type)) {
		// the halves trade places, each one byte swapped
		xbPair a = xb_pair_of(p, v);
		xbPair r = {xb_unop(p, xbOp_Bswap, xbType_I64, a.hi), xb_unop(p, xbOp_Bswap, xbType_I64, a.lo)};
		return xb_pair_value(p, t, r);
	}
	xbType st = xb_scalar_type(v.type);
	if (st == xbType_None || xb_type_is_float(st)) XB_UNSUPPORTED(p, "byte swap type");
	u32 r = xb_value_to_reg(p, v);
	if (xb_type_size(st) > 1) r = xb_unop(p, xbOp_Bswap, st, r);
	return xb_value_reg(t, r);
}

gb_internal xbValue xb_reinterpret(xbProc *p, xbValue v, Type *t);

// the same bits in the other byte order, as type t of the same size
gb_internal xbValue xb_byte_swap_any(xbProc *p, xbValue v, Type *t) {
	if (xb_is_f16(v.type)) {
		u32 bits = xb_load(p, xbType_I16, xb_value_to_mem(p, v));
		xbMem m = xb_add_local(p, t, false);
		xb_store(p, xbType_I16, m, xb_unop(p, xbOp_Bswap, xbType_I16, bits));
		return xb_value_mem(t, m);
	}
	xbType st = xb_scalar_type(v.type);
	if (xb_type_is_float(st)) {
		xbType it = st == xbType_F32 ? xbType_I32 : xbType_I64;
		u32 bits = xb_convop(p, xbOp_Bitcast, it, st, xb_value_to_reg(p, v));
		bits = xb_unop(p, xbOp_Bswap, it, bits);
		return xb_value_reg(t, xb_convop(p, xbOp_Bitcast, st, it, bits));
	}
	return xb_byte_swap(p, v, t);
}

gb_internal xbValue xb_reinterpret(xbProc *p, xbValue v, Type *t) {
	// same size, same register class: just retype
	xbType ss = xb_scalar_type(v.type);
	xbType ds = xb_scalar_type(t);
	if (ss != xbType_None && ds != xbType_None && xb_type_is_float(ss) == xb_type_is_float(ds) && xb_type_size(ss) == xb_type_size(ds)) {
		xbValue r = xb_value_reg(t, xb_value_to_reg(p, v));
		r.has_origin = v.has_origin;
		r.origin = v.origin;
		return r;
	}
	return xb_emit_transmute(p, v, t);
}

gb_internal xbValue xb_float_to_int(xbProc *p, xbValue v, Type *t) {
	Type *src = core_type(v.type);
	Type *dst = core_type(t);
	xbType ss = xb_scalar_type(src);
	xbType ds = xb_scalar_type(dst);
	if (ss == xbType_None || ds == xbType_None) XB_UNSUPPORTED(p, "float to int type");
	u32 r = xb_value_to_reg(p, v);
	i64 sz = gb_max(type_size_of(src), type_size_of(dst));
	u32 res = 0;
	if (is_type_unsigned(dst)) {
		if (sz <= 4) {
			// fptoui to u32, through a wider signed conversion
			u32 w = xb_convop(p, xbOp_FToSI, xbType_I64, ss, r);
			res = xb_int_resize(p, w, xbType_I64, ds, false);
		} else {
			u32 w = xb_convop(p, xbOp_FToUI, xbType_I64, ss, r);
			res = xb_int_resize(p, w, xbType_I64, ds, false);
		}
	} else {
		if (sz <= 4) {
			u32 w = xb_convop(p, xbOp_FToSI, xbType_I32, ss, r);
			res = xb_int_resize(p, w, xbType_I32, ds, true);
		} else {
			u32 w = xb_convop(p, xbOp_FToSI, xbType_I64, ss, r);
			res = xb_int_resize(p, w, xbType_I64, ds, true);
		}
	}
	return xb_value_reg(t, res);
}

gb_internal xbValue xb_union_conv(xbProc *p, xbValue v, Type *t, bool *ok);
gb_internal xbMem   xb_matrix_elem_mem(xbMem m, Type *mt, i64 row, i64 column);
gb_internal xbValue xb_matrix_ev(xbProc *p, xbMem m, Type *mt, i64 row, i64 column);
gb_internal xbValue xb_const_value(xbProc *p, Type *type, ExactValue value);
gb_internal xbAddr xb_emit_deep_field(xbProc *p, Type *type, xbMem mem, Selection const &sel);

// A port of lb_emit_conv, in the same order.
gb_internal xbValue xb_emit_conv(xbProc *p, xbValue v, Type *t) {
	t = reduce_tuple_to_single_type(t);
	Type *src_type = v.type;
	if (are_types_identical(t, src_type)) {
		v.type = t;
		return v;
	}
	Type *src = core_type(src_type);
	Type *dst = core_type(t);

	if (is_type_untyped_uninit(src)) {
		return xb_value_mem(t, xb_add_local(p, t, false));
	}
	if (is_type_untyped_nil(src)) {
		return xb_zero_value(p, t);
	}

	if (are_types_identical(src, dst)) {
		return xb_reinterpret(p, v, t);
	}

	xbType ss = xb_scalar_type(src);
	xbType ds = xb_scalar_type(dst);

	// bool <-> llvm bool
	if (is_type_boolean(src) && dst == t_llvm_bool) {
		return xb_value_reg(t, xb_to_bool_reg(p, v));
	}
	if (src == t_llvm_bool && is_type_boolean(dst)) {
		return xb_value_reg(t, xb_int_resize(p, xb_value_to_reg(p, v), xbType_I8, ds, false));
	}

	bool endian = (is_type_different_to_arch_endianness(src) || is_type_different_to_arch_endianness(dst) || is_type_endian_big(src) || is_type_endian_big(dst));

	// numbers in a non-native byte order convert through the platform types
	if ((is_type_integer(src) || is_type_float(src)) && (is_type_integer(dst) || is_type_float(dst)) &&
	    ((type_size_of(src) > 1 && is_type_different_to_arch_endianness(src)) ||
	     (type_size_of(dst) > 1 && is_type_different_to_arch_endianness(dst)))) {
		bool src_swap = type_size_of(src) > 1 && is_type_different_to_arch_endianness(src);
		bool dst_swap = type_size_of(dst) > 1 && is_type_different_to_arch_endianness(dst);
		Type *ps = integer_endian_type_to_platform_type(src);
		Type *pd = integer_endian_type_to_platform_type(dst);
		if (src_swap && dst_swap && type_size_of(src) == type_size_of(dst) && are_types_identical(ps, pd)) {
			return xb_reinterpret(p, v, t);
		}
		xbValue x = v;
		if (src_swap) {
			x = xb_byte_swap_any(p, v, ps);
		} else {
			x.type = ps;
		}
		x = xb_emit_conv(p, x, pd);
		if (dst_swap) return xb_byte_swap_any(p, x, t);
		x.type = t;
		return x;
	}

	// integer -> integer
	if (is_type_integer(src) && is_type_integer(dst)) {
		i64 sz = type_size_of(default_type(src));
		i64 dz = type_size_of(default_type(dst));
		bool src_swap = sz > 1 && is_type_different_to_arch_endianness(src);
		bool dst_swap = dz > 1 && is_type_different_to_arch_endianness(dst);
		if (sz == 16 || dz == 16) {
			if (src_swap || dst_swap) {
				// through the platform types
				Type *ps = integer_endian_type_to_platform_type(src);
				Type *pd = integer_endian_type_to_platform_type(dst);
				xbValue x = src_swap ? xb_byte_swap(p, v, ps) : xb_reinterpret(p, v, ps);
				x = xb_emit_conv(p, x, pd);
				return dst_swap ? xb_byte_swap(p, x, t) : xb_reinterpret(p, x, t);
			}
			if (sz == dz) return xb_reinterpret(p, v, t);
			if (dz == 16) {
				// widen to 128 bits
				bool sgn = !is_type_unsigned(src);
				u32 lo = xb_int_resize(p, xb_value_to_reg(p, v), ss, xbType_I64, sgn);
				u32 hi = sgn ? xb_binop(p, xbOp_AShr, xbType_I64, lo, xb_i64(p, 63)) : xb_i64(p, 0);
				xbPair pr = {lo, hi};
				return xb_pair_value(p, t, pr);
			}
			xbPair pr = xb_pair_of(p, v);
			return xb_value_reg(t, xb_int_resize(p, pr.lo, xbType_I64, ds, false));
		}
		if (sz == dz) {
			if (dz > 1 && !types_have_same_internal_endian(src, dst)) {
				return xb_byte_swap(p, v, t);
			}
			return xb_reinterpret(p, v, t);
		}
		u32 r = xb_value_to_reg(p, v);
		if (src_swap) r = xb_unop(p, xbOp_Bswap, ss, r);
		r = xb_int_resize(p, r, ss, ds, !is_type_unsigned(src));
		if (dst_swap) r = xb_unop(p, xbOp_Bswap, ds, r);
		return xb_value_reg(t, r);
	}

	// boolean -> boolean/integer
	if (is_type_boolean(src) && (is_type_boolean(dst) || is_type_integer(dst))) {
		if (endian && is_type_integer(dst)) {
			// to the platform integer, then into the byte order
			return xb_emit_conv(p, xb_emit_conv(p, v, integer_endian_type_to_platform_type(dst)), t);
		}
		if (endian) XB_UNSUPPORTED(p, "endian bool conversion");
		if (xb_is_int128(dst)) {
			xbPair pr = {xb_int_resize(p, xb_to_bool_reg(p, v), xbType_I8, xbType_I64, false), xb_i64(p, 0)};
			return xb_pair_value(p, t, pr);
		}
		if (ds == xbType_None) {
			gbString r = gb_string_make(permanent_allocator(), "bool to wide integer ");
			r = gb_string_appendc(r, type_to_string(dst));
			XB_UNSUPPORTED(p, r);
		}
		u32 b = xb_to_bool_reg(p, v);
		return xb_value_reg(t, xb_int_resize(p, b, xbType_I8, ds, false));
	}

	if ((is_type_cstring(src) && (is_type_u8_ptr(dst) || is_type_u8_multi_ptr(dst) || is_type_rawptr(dst))) ||
	    ((is_type_u8_ptr(src) || is_type_u8_multi_ptr(src) || is_type_rawptr(src)) && is_type_cstring(dst))) {
		return xb_reinterpret(p, v, t);
	}
	if (are_types_identical(src, t_cstring) && are_types_identical(dst, t_string)) {
		xbValue args[1] = {xb_reinterpret(p, v, t_cstring)};
		return xb_emit_conv(p, xb_emit_runtime_call(p, "cstring_to_string", xb_args(args, 1)), t);
	}
	if ((is_type_cstring16(src) && (is_type_u16_ptr(dst) || is_type_u16_multi_ptr(dst) || is_type_rawptr(dst))) ||
	    ((is_type_u16_ptr(src) || is_type_u16_multi_ptr(src) || is_type_rawptr(src)) && is_type_cstring16(dst))) {
		return xb_reinterpret(p, v, t);
	}
	if (are_types_identical(src, t_cstring16) && are_types_identical(dst, t_string16)) {
		xbValue args[1] = {xb_reinterpret(p, v, t_cstring16)};
		return xb_emit_conv(p, xb_emit_runtime_call(p, "cstring16_to_string16", xb_args(args, 1)), t);
	}

	// integer -> boolean
	if (is_type_integer(src) && is_type_boolean(dst)) {
		if (xb_is_int128(src) && ds != xbType_None) {
			// any bit set, in either byte order
			xbPair pr = xb_pair_of(p, v);
			u32 any = xb_binop(p, xbOp_Or, xbType_I64, pr.lo, pr.hi);
			u32 b = xb_cmp(p, xbCond_NE, xbType_I64, any, xb_i64(p, 0));
			return xb_emit_conv(p, xb_value_reg(t_llvm_bool, b), t);
		}
		if (ss == xbType_None || ds == xbType_None) XB_UNSUPPORTED(p, "wide integer to bool");
		u32 b = xb_cmp(p, xbCond_NE, ss, xb_value_to_reg(p, v), xb_iconst(p, ss, 0));
		return xb_emit_conv(p, xb_value_reg(t_llvm_bool, b), t);
	}

	// float -> float
	if (is_type_float(src) && is_type_float(dst)) {
		if (endian) {
			if (xb_is_f16(src) || xb_is_f16(dst)) XB_UNSUPPORTED(p, "endian f16");
			// swap the bytes of the source into the platform order, convert, swap back
			xbValue x = v;
			if (is_type_different_to_arch_endianness(src)) {
				xbType it = ss == xbType_F32 ? xbType_I32 : xbType_I64;
				u32 bits = xb_convop(p, xbOp_Bitcast, it, ss, xb_value_to_reg(p, v));
				bits = xb_unop(p, xbOp_Bswap, it, bits);
				x = xb_value_reg(integer_endian_type_to_platform_type(src), xb_convop(p, xbOp_Bitcast, ss, it, bits));
			}
			Type *pdst = integer_endian_type_to_platform_type(dst);
			x = xb_emit_conv(p, x, pdst);
			if (is_type_different_to_arch_endianness(dst)) {
				xbType it = ds == xbType_F32 ? xbType_I32 : xbType_I64;
				u32 bits = xb_convop(p, xbOp_Bitcast, it, ds, xb_value_to_reg(p, x));
				bits = xb_unop(p, xbOp_Bswap, it, bits);
				return xb_value_reg(t, xb_convop(p, xbOp_Bitcast, ds, it, bits));
			}
			return xb_value_reg(t, xb_value_to_reg(p, x));
		}
		if (xb_is_f16(src) && xb_is_f16(dst)) return xb_reinterpret(p, v, t);
		if (xb_is_f16(src)) return xb_emit_conv(p, xb_f16_to_f32(p, v), t);
		if (xb_is_f16(dst)) return xb_float_to_f16(p, v, t);
		if (ss == ds) return xb_reinterpret(p, v, t);
		return xb_value_reg(t, xb_convop(p, ss == xbType_F32 ? xbOp_FExt : xbOp_FTrunc, ds, ss, xb_value_to_reg(p, v)));
	}

	if (is_type_complex(src) && is_type_complex(dst)) {
		xbValue parts[2] = {xb_complex_part(p, v, 0), xb_complex_part(p, v, 1)};
		return xb_complex_build(p, t, parts, 2);
	}
	if (is_type_quaternion(src) && is_type_quaternion(dst)) {
		xbValue parts[4] = {xb_complex_part(p, v, 0), xb_complex_part(p, v, 1), xb_complex_part(p, v, 2), xb_complex_part(p, v, 3)};
		return xb_complex_build(p, t, parts, 4);
	}
	if ((is_type_integer(src) || is_type_float(src)) && (is_type_complex(dst) || is_type_quaternion(dst))) {
		Type *ft = base_complex_elem_type(dst);
		xbValue real = xb_emit_conv(p, v, ft);
		xbValue zero = xb_zero_value(p, ft);
		if (is_type_complex(dst)) {
			xbValue parts[2] = {real, zero};
			return xb_complex_build(p, t, parts, 2);
		}
		// @QuaternionLayout: imag, jmag, kmag, real
		xbValue parts[4] = {zero, zero, zero, real};
		return xb_complex_build(p, t, parts, 4);
	}
	if (is_type_complex(src) && is_type_quaternion(dst)) {
		Type *ft = base_complex_elem_type(dst);
		xbValue zero = xb_zero_value(p, ft);
		xbValue parts[4] = {xb_complex_part(p, v, 1), zero, zero, xb_complex_part(p, v, 0)};
		return xb_complex_build(p, t, parts, 4);
	}
	if ((is_type_complex(src) || is_type_complex(dst) || is_type_quaternion(src) || is_type_quaternion(dst)) && !is_type_any(dst) && !is_type_union(dst)) {
		XB_UNSUPPORTED(p, "complex conversion");
	}

	// float <-> integer
	if (is_type_float(src) && is_type_integer(dst)) {
		if (endian) XB_UNSUPPORTED(p, "endian float conversion");
		if (xb_is_f16(src)) return xb_emit_conv(p, xb_f16_to_f32(p, v), t);
		if (is_type_integer_128bit(dst)) {
			xbValue args[1] = {xb_emit_conv(p, v, t_f64)};
			xbValue r = xb_emit_runtime_call(p, is_type_unsigned(dst) ? "fixunsdfti" : "fixdfti", xb_args(args, 1));
			return xb_emit_conv(p, r, t);
		}
		return xb_float_to_int(p, v, t);
	}
	if (is_type_integer(src) && is_type_float(dst)) {
		if (endian) XB_UNSUPPORTED(p, "endian float conversion");
		if (is_type_integer_128bit(src)) {
			xbValue args[1] = {v};
			xbValue r = xb_emit_runtime_call(p, is_type_unsigned(src) ? "floattidf_unsigned" : "floattidf", xb_args(args, 1));
			return xb_emit_conv(p, r, t);
		}
		if (xb_is_f16(dst)) return xb_float_to_f16(p, xb_emit_conv(p, v, t_f32), t);
		bool sgn = !is_type_unsigned(src);
		u32 r = xb_value_to_reg(p, v);
		xbType it = ss;
		if (xb_type_size(it) < 4) {
			r = xb_int_resize(p, r, it, xbType_I32, sgn);
			it = xbType_I32;
		}
		return xb_value_reg(t, xb_convop(p, sgn ? xbOp_SIToF : xbOp_UIToF, ds, it, r));
	}

	if (is_type_simd_vector(dst)) {
		return xb_simd_conv(p, v, t);
	}

	// bit_field / bit_set <-> backing type
	if (is_type_bit_field(src) && are_types_identical(src->BitField.backing_type, dst)) return xb_reinterpret(p, v, t);
	if (is_type_bit_field(dst) && are_types_identical(src, dst->BitField.backing_type)) return xb_reinterpret(p, v, t);
	if (is_type_bit_set(src) && are_types_identical(bit_set_to_int(src), dst)) return xb_reinterpret(p, v, t);
	if (is_type_bit_set(dst) && are_types_identical(src, bit_set_to_int(dst))) return xb_reinterpret(p, v, t);

	// pointer <-> uintptr
	if ((is_type_pointer(src) || is_type_multi_pointer(src)) && is_type_uintptr(dst)) return xb_reinterpret(p, v, t);
	if (is_type_uintptr(src) && (is_type_pointer(dst) || is_type_multi_pointer(dst))) return xb_reinterpret(p, v, t);

	if (is_type_union(dst)) {
		bool ok = false;
		xbValue r = xb_union_conv(p, v, t, &ok);
		if (ok) return r;
	}

	// subtype polymorphism, before pointer <-> pointer
	if (check_is_assignable_to_using_subtype(src_type, t)) {
		Type *st = base_type(type_deref(type_deref(src_type)));
		bool st_is_ptr = is_type_pointer(src_type);
		TEMPORARY_ALLOCATOR_GUARD();
		Selection sel = {};
		sel.index.allocator = temporary_allocator();
		if ((is_type_struct(st) || is_type_raw_union(st)) && lookup_subtype_polymorphic_selection(t, src_type, &sel)) {
			GB_ASSERT(sel.entity != nullptr);
			Selection copy = sel;
			copy.index = array_clone(heap_allocator(), sel.index);
			if (st_is_ptr) {
				// &value.field
				xbMem base = xb_mem(xbMem_Reg, xb_value_to_reg(p, v), 0);
				xbAddr a = xb_emit_deep_field(p, type_deref(src_type), base, copy);
				if (are_types_identical(a.type, t)) {
					return xb_load_value(p, t, a.mem);
				}
				return xb_value_reg(t, xb_lea(p, a.mem));
			}
			xbMem m = xb_address_from_load_or_generate_local(p, v);
			xbAddr a = xb_emit_deep_field(p, src_type, m, copy);
			return xb_load_value(p, t, a.mem);
		}
	}

	// pointer <-> pointer, proc <-> proc, pointer <-> proc
	if ((is_type_pointer(src) || is_type_multi_pointer(src) || is_type_proc(src)) &&
	    (is_type_pointer(dst) || is_type_multi_pointer(dst) || is_type_proc(dst))) {
		return xb_reinterpret(p, v, t);
	}
	if ((is_type_u16_multi_ptr(src) || is_type_u16_ptr(src)) && is_type_cstring16(dst)) return xb_reinterpret(p, v, t);
	if (is_type_cstring16(src) && (is_type_u16_multi_ptr(dst) || is_type_u16_ptr(dst))) return xb_reinterpret(p, v, t);

	// []u16 <-> string16, []u8 <-> string
	if ((is_type_u16_slice(src) && is_type_string16(dst)) || (is_type_string16(src) && is_type_u16_slice(dst)) ||
	    (is_type_u8_slice(src) && is_type_string(dst)) || (is_type_string(src) && is_type_u8_slice(dst))) {
		return xb_emit_transmute(p, v, t);
	}

	if (is_type_array(dst) && is_type_array(src)) {
		Type *dst_elem = base_array_type(dst);
		Type *src_elem = base_array_type(src);
		if (dst->Array.count == src->Array.count && type_array_depth(dst) == type_array_depth(src)) {
			if (are_types_identical(dst_elem, src_elem)) {
				v.type = t;
				return v;
			}
			i64 count = dst->Array.count;
			if (count > 64) XB_UNSUPPORTED(p, "large array conversion");
			xbMem sm = xb_address_from_load_or_generate_local(p, v);
			xbMem dm = xb_add_local(p, t, true);
			Type *se = dst->Array.elem;
			Type *de = src->Array.elem;
			gb_unused(se); gb_unused(de);
			i64 sstride = type_size_of(src->Array.elem);
			i64 dstride = type_size_of(dst->Array.elem);
			for (i64 i = 0; i < count; i++) {
				xbValue e = xb_load_value(p, src->Array.elem, xb_mem_offset(sm, i*sstride));
				xb_store_value(p, xb_mem_offset(dm, i*dstride), xb_emit_conv(p, e, dst->Array.elem));
			}
			return xb_value_mem(t, dm);
		}
	}

	if (is_type_array_like(dst)) {
		// broadcast
		Type *elem = base_array_type(dst);
		i64 count = get_array_type_count(dst);
		if (count > 256) XB_UNSUPPORTED(p, "large array broadcast");
		xbValue e = xb_emit_conv(p, v, elem);
		if (e.kind == xbValue_Mem) e = xb_value_copy_to_temp(p, e);
		xbMem dm = xb_add_local(p, t, false);
		i64 stride = type_size_of(elem);
		for (i64 i = 0; i < count; i++) {
			xb_store_value(p, xb_mem_offset(dm, i*stride), e);
		}
		return xb_value_mem(t, dm);
	}

	if (is_type_matrix(dst) && !is_type_matrix(src)) {
		// a scalar becomes the diagonal
		Type *elem = base_array_type(dst);
		xbValue e = xb_emit_conv(p, v, elem);
		if (e.kind == xbValue_Mem) e = xb_value_copy_to_temp(p, e);
		xbValue zero = xb_zero_value(p, elem);
		xbMem m = xb_add_local(p, t, false);
		for (i64 j = 0; j < dst->Matrix.column_count; j++) {
			for (i64 i = 0; i < dst->Matrix.row_count; i++) {
				xb_store_value(p, xb_matrix_elem_mem(m, dst, i, j), i == j ? e : zero);
			}
		}
		return xb_value_mem(t, m);
	}
	if (is_type_matrix(dst) && is_type_matrix(src)) {
		xbMem m = xb_add_local(p, t, true);
		xbMem sm = xb_address_from_load_or_generate_local(p, v);
		Type *de = dst->Matrix.elem;
		if (dst->Matrix.row_count == src->Matrix.row_count && dst->Matrix.column_count == src->Matrix.column_count) {
			for (i64 j = 0; j < dst->Matrix.column_count; j++) {
				for (i64 i = 0; i < dst->Matrix.row_count; i++) {
					xb_store_value(p, xb_matrix_elem_mem(m, dst, i, j), xb_emit_conv(p, xb_matrix_ev(p, sm, src, i, j), de));
				}
			}
		} else if (is_matrix_square(dst)) {
			// the top left corner, the rest of the identity
			for (i64 j = 0; j < dst->Matrix.column_count; j++) {
				for (i64 i = 0; i < dst->Matrix.row_count; i++) {
					if (i < src->Matrix.row_count && j < src->Matrix.column_count) {
						xb_store_value(p, xb_matrix_elem_mem(m, dst, i, j), xb_emit_conv(p, xb_matrix_ev(p, sm, src, i, j), de));
					} else if (i == j) {
						xb_store_value(p, xb_matrix_elem_mem(m, dst, i, j), xb_const_value(p, de, exact_value_i64(1)));
					}
				}
			}
		} else {
			// the same elements in column major order
			i64 count = src->Matrix.row_count*src->Matrix.column_count;
			Type *se = src->Matrix.elem;
			if (are_types_identical(base_type(de), base_type(se)) && type_size_of(dst) == type_size_of(src)) {
				xb_memcopy(p, m, sm, type_size_of(dst));
			} else {
				for (i64 i = 0; i < count; i++) {
					xbValue e = xb_load_value(p, se, xb_mem_offset(sm, matrix_column_major_index_to_offset(src, i)*type_size_of(se)));
					xb_store_value(p, xb_mem_offset(m, matrix_column_major_index_to_offset(dst, i)*type_size_of(de)), xb_emit_conv(p, e, de));
				}
			}
		}
		return xb_value_mem(t, m);
	}

	if (is_type_any(dst)) {
		Type *st = default_type(src_type);
		if (!is_type_typed(st)) XB_UNSUPPORTED(p, "untyped to any");
		if (is_type_untyped(src_type)) {
			v = xb_emit_conv(p, v, st);
		}
		xbMem data = xb_address_from_load_or_generate_local(p, v);
		xbMem res = xb_add_local(p, t_any, false);
		xb_store(p, xbType_I64, res, xb_lea(p, data));
		xbValue id = xb_typeid_value(p, st);
		xb_store(p, xbType_I64, xb_mem_offset(res, 8), id.reg);
		return xb_value_mem(t, res);
	}

	i64 src_sz = type_size_of(src);
	i64 dst_sz = type_size_of(dst);
	if (src_sz == dst_sz) {
		if (is_type_integer(src) && is_type_bit_set(dst)) {
			xbValue r = xb_emit_conv(p, v, bit_set_to_int(dst));
			return xb_reinterpret(p, r, t);
		}
		if (is_type_bit_set(src) && is_type_integer(dst)) {
			xbValue bs = xb_reinterpret(p, v, bit_set_to_int(src));
			return xb_emit_conv(p, bs, t);
		}
		if ((is_type_integer(src) && is_type_typeid(dst)) || (is_type_typeid(src) && is_type_integer(dst))) {
			return xb_emit_transmute(p, v, t);
		}
	}

	if (is_type_untyped(src)) {
		if (is_type_string(src) && is_type_string(dst)) {
			xbValue r = xb_value_copy_to_temp(p, v);
			r.type = t;
			return r;
		}
	}

	{
		gbString r = gb_string_make(permanent_allocator(), "conversion ");
		r = gb_string_append_fmt(r, "%s -> %s", type_to_string(src), type_to_string(dst));
		XB_UNSUPPORTED(p, r);
	}
	return {};
}

gb_internal xbValue xb_emit_transmute(xbProc *p, xbValue v, Type *t) {
	if (are_types_identical(v.type, t)) {
		return v;
	}
	i64 ssz = type_size_of(v.type);
	i64 dsz = type_size_of(t);
	if (ssz != dsz) {
		XB_UNSUPPORTED(p, "transmute of different sizes");
	}
	xbType ss = xb_scalar_type(v.type);
	xbType ds = xb_scalar_type(t);
	if (ss != xbType_None && ds != xbType_None) {
		u32 r = xb_value_to_reg(p, v);
		if (xb_type_is_float(ss) != xb_type_is_float(ds)) {
			return xb_value_reg(t, xb_convop(p, xbOp_Bitcast, ds, ss, r));
		}
		return xb_value_reg(t, r);
	}
	xbMem m = xb_value_to_mem(p, v);
	if (type_align_of(t) > type_align_of(v.type) && ds == xbType_None) {
		xbMem n = xb_add_local(p, t, false);
		xb_memcopy(p, n, m, dsz);
		m = n;
	}
	return xb_load_value(p, t, m);
}
