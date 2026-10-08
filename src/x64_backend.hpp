// A fast, non-optimizing x86-64 backend for debug builds (`-backend:x64`).
//
// Pipeline: checked AST -> xb IR (per procedure) -> machine code -> ELF object.
//
// Procedures the backend cannot compile yet are left to LLVM. Both backends use
// the same symbol names and the same ABI, so their objects link together.

struct xbModule;
struct xbProc;

enum xbType : u8 {
	xbType_None,
	xbType_I8,
	xbType_I16,
	xbType_I32,
	xbType_I64,
	xbType_F32,
	xbType_F64,
	xbType_V128, // only used for ABI pieces: a whole xmm register
	xbType_COUNT,
};

gb_global i32 const xb_type_sizes[xbType_COUNT] = {0, 1, 2, 4, 8, 4, 8, 16};

gb_internal gb_inline i32  xb_type_size(xbType t)     { return xb_type_sizes[t]; }
gb_internal gb_inline bool xb_type_is_float(xbType t) { return t == xbType_F32 || t == xbType_F64; }
gb_internal gb_inline bool xb_type_is_int(xbType t)   { return t >= xbType_I8 && t <= xbType_I64; }

// Where a memory operand lives. Every IR memory access goes through one of these.
enum xbMemKind : u8 {
	xbMem_None,
	xbMem_Reg,      // [vreg + offset], the vreg holds a pointer
	xbMem_Local,    // [frame local + offset]
	xbMem_Sym,      // [symbol + offset]
	xbMem_Incoming, // [incoming stack arguments + offset]
};

struct xbMem {
	xbMemKind kind;
	u8        align;  // known alignment when it may be below the type's (packed fields), 0 if natural
	u32       base;
	i32       offset;
};

gb_internal gb_inline xbMem xb_mem(xbMemKind kind, u32 base, i32 offset=0) {
	xbMem m = {};
	m.kind = kind;
	m.base = base;
	m.offset = offset;
	return m;
}

gb_internal gb_inline xbMem xb_mem_offset(xbMem m, i64 offset) {
	m.offset += cast(i32)offset;
	if (m.align != 0 && offset != 0) {
		// the largest power of two dividing both
		i64 o = offset < 0 ? -offset : offset;
		i64 a = m.align;
		while (a > 1 && (o % a) != 0) a /= 2;
		m.align = cast(u8)a;
	}
	return m;
}

enum xbOp : u8 {
	xbOp_Nop,
	xbOp_Loc,        // source line marker: imm = line, a = file id

	xbOp_IConst,     // dst = imm
	xbOp_FConst,     // dst = bits(imm)
	xbOp_Lea,        // dst = &mem
	xbOp_Load,       // dst = [mem]
	xbOp_Store,      // [mem] = a
	xbOp_Copy,       // dst = a

	xbOp_Add,
	xbOp_Sub,
	xbOp_Mul,
	xbOp_SDiv,
	xbOp_UDiv,
	xbOp_SRem,
	xbOp_URem,
	xbOp_And,
	xbOp_Or,
	xbOp_Xor,
	xbOp_Shl,        // raw x86 shifts, the count is masked by the cpu
	xbOp_LShr,
	xbOp_AShr,

	xbOp_FAdd,
	xbOp_FSub,
	xbOp_FMul,
	xbOp_FDiv,

	xbOp_Neg,
	xbOp_Not,
	xbOp_FNeg,

	xbOp_ICmp,       // dst(i8) = a <aux> b
	xbOp_FCmp,       // dst(i8) = a <aux> b

	xbOp_Zext,       // dst(type) = zext a(aux)
	xbOp_Sext,
	xbOp_Trunc,
	xbOp_SIToF,      // dst(float type) = a(aux int type)
	xbOp_UIToF,
	xbOp_FToSI,      // dst(int type) = a(aux float type)
	xbOp_FToUI,
	xbOp_FExt,
	xbOp_FTrunc,
	xbOp_Bitcast,    // int <-> float of the same size, aux = source type

	xbOp_Select,     // dst = a ? b : c

	xbOp_MemCopy,    // copy imm bytes: [a] <- [b], a and b are pointer vregs
	xbOp_MemMove,    // like MemCopy but the ranges may overlap
	xbOp_MemZero,    // zero imm bytes at [a]
	xbOp_MemCopyDyn, // copy c bytes, c is a vreg
	xbOp_MemMoveDyn,
	xbOp_MemSetDyn,  // set c bytes at [a] to the byte b

	xbOp_Call,       // imm = index into proc->calls

	xbOp_Jump,       // imm = block
	xbOp_Branch,     // if a != 0 goto imm else goto imm2 (stored in c)
	xbOp_Ret,
	xbOp_Unreachable,
	xbOp_Trap,
	xbOp_DebugTrap,

	xbOp_AtomicFence,
	xbOp_AtomicLoad,  // dst = [mem]
	xbOp_AtomicStore, // [mem] = a, with a full fence
	xbOp_AtomicRmw,   // dst = old [mem]; [mem] = old <aux> a
	xbOp_AtomicCas,   // dst = old [mem]; if old == a { [mem] = b }; dst2 (c) = success

	xbOp_ReadCycleCounter,
	xbOp_CpuRelax,
	xbOp_Prefetch,
	xbOp_StackPointer, // dst = rsp
	xbOp_FrameAddress, // dst = rbp
	xbOp_ReturnAddress,
	xbOp_Sqrt,        // dst = sqrt(a)
	xbOp_Bswap,
	xbOp_Popcount,
	xbOp_Ctz,         // count trailing zeros, defined for zero
	xbOp_Clz,         // count leading zeros, defined for zero
	xbOp_Syscall,     // imm = index into proc->calls (args only)
	xbOp_MulOvf,      // dst = a * b, c = overflowed; aux = 1 if signed
	xbOp_MulHiU,      // dst = high 64 bits of the unsigned product a * b
	xbOp_Cpuid,       // [mem] = eax, ebx, ecx, edx of cpuid(eax = a, ecx = b)
	xbOp_Xgetbv,      // [mem] = eax, edx of xgetbv(ecx = a)
	xbOp_Valgrind,    // dst = valgrind client request(default = a, args = [b])
	xbOp_Alloca,      // dst = a bytes of fresh stack memory aligned to imm

	xbOp_COUNT,
};

enum xbCond : u8 {
	xbCond_EQ,
	xbCond_NE,
	xbCond_SLT,
	xbCond_SLE,
	xbCond_SGT,
	xbCond_SGE,
	xbCond_ULT,
	xbCond_ULE,
	xbCond_UGT,
	xbCond_UGE,
	// floating point: ordered unless stated
	xbCond_FEQ,
	xbCond_FNE,  // unordered or not equal
	xbCond_FLT,
	xbCond_FLE,
	xbCond_FGT,
	xbCond_FGE,
};

enum xbRmwOp : u8 {
	xbRmw_Xchg,
	xbRmw_Add,
	xbRmw_Sub,
	xbRmw_And,
	xbRmw_Or,
	xbRmw_Xor,
	xbRmw_Nand,
};

struct xbInstr {
	xbOp   op;
	xbType type;
	u8     aux;   // xbCond, source xbType, or xbRmwOp
	u8     flags;
	u32    dst;
	u32    a;
	u32    b;
	u32    c;
	xbMem  mem;
	i64    imm;
};

enum xbInstrFlag : u8 {
	xbInstrFlag_Volatile = 1<<0,
};

////////////////////////////////////////////////////////////////
// ABI
////////////////////////////////////////////////////////////////

enum xbArgKind : u8 {
	xbArg_Direct,   // passed in registers (or their stack spill slots), split into pieces
	xbArg_Indirect, // a pointer to the value is passed
	xbArg_ByVal,    // the value is copied onto the stack
	xbArg_Ignore,   // zero-sized, not passed at all
};

enum xbLocKind : u8 {
	xbLoc_Gpr,
	xbLoc_Xmm,
	xbLoc_Stack,
};

enum xbExtKind : u8 {
	xbExt_None,
	xbExt_Zero,
	xbExt_Sign,
};

// One register-sized part of an argument or result.
struct xbAbiPiece {
	xbType    type;
	i32       size;       // bytes of the value this piece carries
	i32       src_offset; // where those bytes live within the value
	xbLocKind loc;
	u8        reg;
	xbExtKind ext;
	i32       stack_offset;
};

struct xbAbiArg {
	xbArgKind  kind;
	Type *     type;      // Odin type of the value
	i32        piece_index;
	i32        piece_count;
	// ByVal: where on the stack the copy lives
	i32        stack_offset;
	i32        byval_size;
	i32        byval_align;
};

struct xbAbiFunc {
	ProcCallingConvention cc;
	bool       c_vararg;
	bool       is_odin_cc;
	bool       split_returns;     // all but the last result are returned through pointer params
	bool       has_sret;          // first param is a pointer to the result
	Type *     ret_type;          // the type actually returned (last result if split)
	xbAbiArg   ret;
	xbAbiArg   sret;              // the hidden sret pointer, valid if has_sret
	Array<xbAbiArg>   params;     // one per Odin parameter variable (excluding #c_vararg)
	Array<xbAbiArg>   split_ret_ptrs;
	xbAbiArg   context;           // valid if is_odin_cc
	Array<xbAbiPiece> pieces;
	i32        stack_size;        // bytes of stack arguments
	i32        gpr_count;         // registers used by the fixed params
	i32        xmm_count;
};

////////////////////////////////////////////////////////////////
// Calls
////////////////////////////////////////////////////////////////

enum xbCallArgKind : u8 {
	xbCallArg_Gpr,        // load vreg into gpr
	xbCallArg_Xmm,        // load vreg into xmm
	xbCallArg_GprMem,     // load `size` bytes at mem into gpr
	xbCallArg_XmmMem,     // load `size` bytes at mem into xmm
	xbCallArg_Stack,      // store vreg into [rsp + stack_offset]
	xbCallArg_StackMem,   // copy `size` bytes at mem to [rsp + stack_offset]
};

struct xbCallArg {
	xbCallArgKind kind;
	xbType        type;
	u8            reg;
	xbExtKind     ext;
	u32           vreg;
	xbMem         mem;
	i32           size;
	i32           stack_offset;
};

struct xbCallRet {
	xbLocKind loc; // Gpr or Xmm
	u8        reg;
	xbType    type;
	i32       size;
	xbMem     dst; // stored to memory
};

struct xbCall {
	u32              target_vreg; // 0 if direct
	i32              target_sym;  // -1 if indirect
	Slice<xbCallArg> args;
	Slice<xbCallRet> rets;
	i32              stack_size;
	i32              sse_count;   // for C varargs: number of xmm registers used, else -1
	u32              result_vreg; // for syscalls
};

////////////////////////////////////////////////////////////////
// Procedures
////////////////////////////////////////////////////////////////

struct xbBlock {
	i32            index;
	bool           placed;
	isize          scope_index;
	Array<xbInstr> instrs;
	i32            code_offset;
};

struct xbLocal {
	i64 size;
	i64 align;
	i32 frame_offset;
	i64 over_align; // > 16: frame_offset holds a pointer into an aligned spot of the raw area
	i32 raw_offset;
};

struct xbParamIn {
	xbLocKind loc;
	u8        reg;
	xbType    type;
	i32       size;
	i32       stack_offset;
	xbMem     dst;
};

struct xbLineEntry {
	i32 code_offset;
	i32 file_id;
	i32 line;
	i32 column;
};

struct xbDebugVar {
	String name;
	Type * type;
	i32    local;      // frame local holding the variable, or -1
	i32    frame_offset_fixup; // resolved after layout
	bool   is_param;
	bool   by_ref;     // the local holds a pointer to the value
	i32    line;
	i32    file_id;
	i32    sym;        // @(static): the symbol of its storage, used when local < 0
};

// A global variable or constant, for DWARF.
struct xbGlobalDebug {
	String       name;
	Type *       type;
	i32          sym;   // -1 for a constant, which has no file and line
	i32          file_id;
	i32          line;
	i64          value; // for a constant
};

////////////////////////////////////////////////////////////////
// Module
////////////////////////////////////////////////////////////////

enum xbSection : u8 {
	xbSection_Undef,
	xbSection_Text,
	xbSection_Rodata,
	xbSection_Data,
	xbSection_Bss,
	xbSection_TData,
	xbSection_TBss,
	xbSection_COUNT,
};

enum xbSymbolFlag : u8 {
	xbSymbolFlag_Func    = 1<<0,
	xbSymbolFlag_Global  = 1<<1,
	xbSymbolFlag_Weak    = 1<<2,
	xbSymbolFlag_Hidden  = 1<<3,
	xbSymbolFlag_Foreign = 1<<4, // defined outside the executable, reach data through the GOT
	xbSymbolFlag_TLS     = 1<<5,
};

struct xbSymbol {
	String    name;
	xbSection section;
	u8        flags;
	i64       offset;
	i64       size;
	i32       elf_index;
};

enum xbRelocKind : u8 {
	xbReloc_PC32,       // S + A - P
	xbReloc_PLT32,
	xbReloc_GOTPCRELX,
	xbReloc_REX_GOTPCRELX,
	xbReloc_Abs64,      // S + A
	xbReloc_Abs32,
	xbReloc_TPOFF32,
	xbReloc_GOTTPOFF,
};

struct xbReloc {
	xbSection   section;
	xbRelocKind kind;
	i64         offset;
	i32         sym;
	i64         addend;
};

// The symbols for the start of each section, for relocations in debug info
enum xbSectionSym {
	xbSectionSym_Text,
	xbSectionSym_DebugLine,
	xbSectionSym_DebugAbbrev,
	xbSectionSym_DebugStr,
	xbSectionSym_COUNT,
};

struct xbProcDebug {
	String  name;
	String  link_name;
	i32     sym;
	i64     start;
	i64     end;
	i32     file_id;
	i32     line;
	i32     line_entry_start;
	i32     line_entry_count;
	Array<xbDebugVar> vars;
	Type *  type;
};

struct xbStats {
	isize procs_total;
	isize procs_compiled;
	isize globals_total;
	isize globals_defined;
	StringMap<isize> fail_reasons;
};

struct xbModule {
	CheckerInfo *     info;
	struct lbGenerator *gen;

	Array<xbSymbol>   symbols;
	StringMap<i32>    symbol_map;

	Array<u8>         sections[xbSection_COUNT];
	i64               nobits_size[xbSection_COUNT]; // .bss and .tbss hold no bytes
	i64               section_align[xbSection_COUNT];
	Array<xbReloc>    relocs;

	// debug info
	Array<xbProcDebug> proc_debug;
	Array<xbGlobalDebug> global_debug;
	Array<xbLineEntry> lines;
	Array<String>      files;
	PtrMap<AstFile *, i32> file_ids;

	// entities this backend compiles, so LLVM only declares them
	PtrSet<Entity *>  handled;
	// procedure entities discovered while compiling (nested procedures, etc.)
	Array<Entity *>   proc_queue;
	PtrSet<Entity *>  proc_queued;

	PtrMap<Type *, xbAbiFunc *> abi_cache;
	StringMap<i32>    string_lits;

	xbStats           stats;
	String            object_path;
	i64               limit; // for bisecting: compile at most this many procedures, -1 for all
	bool              verbose;
	TokenPos          fail_pos; // where the last XB_UNSUPPORTED happened
	bool              owns_startup; // __$startup_runtime and __$cleanup_runtime are made here
	bool              owns_type_info;
	bool              owns_test_main;
	bool              test_main_not_needed;
	bool              complete; // nothing is left for LLVM
	PtrSet<Entity *>  foreign_libs_set;
	Array<Entity *>   foreign_libs;
};

gb_internal bool xb_is_enabled(void);

// A bump allocator for everything that only lives while one procedure family is
// compiled. Reset keeps the memory, so the pages stay mapped. Memory comes back zeroed.
struct xbArenaChunk {
	u8 *  base;
	isize size;
};

struct xbArena {
	Array<xbArenaChunk> chunks;
	isize curr;
	isize used;
};

gb_global xbArena xb_arena;

gb_internal void *xb_arena_alloc(isize size, isize align) {
	xbArena *a = &xb_arena;
	if (a->chunks.allocator.proc == nullptr) {
		a->chunks = array_make<xbArenaChunk>(heap_allocator(), 0, 16);
	}
	for (;;) {
		if (a->curr < a->chunks.count) {
			xbArenaChunk *c = &a->chunks[a->curr];
			isize start = (a->used + align - 1) & ~(align - 1);
			if (start + size <= c->size) {
				a->used = start + size;
				u8 *p = c->base + start;
				gb_zero_size(p, size);
				return p;
			}
			a->curr += 1;
			a->used = 0;
			continue;
		}
		xbArenaChunk c = {};
		c.size = gb_max(size + align, cast(isize)(4<<20));
		c.base = cast(u8 *)gb_alloc(heap_allocator(), c.size);
		array_add(&a->chunks, c);
	}
}

gb_internal void xb_arena_reset(void) {
	xb_arena.curr = 0;
	xb_arena.used = 0;
}

gb_internal GB_ALLOCATOR_PROC(xb_arena_allocator_proc) {
	switch (type) {
	case gbAllocation_Alloc:
		return xb_arena_alloc(size, alignment);
	case gbAllocation_Free:
		return nullptr;
	case gbAllocation_Resize: {
		if (size == 0) return nullptr;
		if (size <= old_size) return old_memory;
		void *p = xb_arena_alloc(size, alignment);
		if (old_memory) gb_memmove(p, old_memory, old_size);
		return p;
	}
	case gbAllocation_FreeAll:
		return nullptr;
	}
	return nullptr;
}

gb_internal gbAllocator xb_allocator(void) {
	gbAllocator a = {};
	a.proc = xb_arena_allocator_proc;
	a.data = nullptr;
	return a;
}

template <typename T>
gb_internal T *xb_alloc_item(void) {
	return cast(T *)xb_arena_alloc(gb_size_of(T), gb_align_of(T));
}
gb_internal i32 xb_file_id(xbModule *m, i32 global_file_id);
