// Glossary (because i don't know where else to put it)
//   IR   - intermediate representation
//   SoN  - sea of nodes (https://www.oracle.com/technetwork/java/javase/tech/c2-ir95-150110.pdf)
//   SSA  - single static assignment
//   GVN  - global value numbering
//   CSE  - common subexpression elimination
//   CFG  - control flow graph
//   DSE  - dead store elimination
//   GCM  - global code motion
//   SROA - scalar replacement of aggregates
//   CCP  - conditional constant propagation
//   SCCP - sparse conditional constant propagation
//   RPO  - reverse postorder
//   RA   - register allocation
//   BB   - basic block
//   ZTC  - zero trip count
//   MAF  - monotone analysis framework
//   SCC  - strongly connected components
//   MOP  - meet over all paths
#ifndef TB_CORE_H
#define TB_CORE_H

#include <assert.h>
#include <inttypes.h>
#include <stdbool.h>
#include <stdint.h>
#include <stdio.h>
#include <stddef.h>
#include <stdlib.h>
#include <string.h>

#define TB_VERSION_MAJOR 0
#define TB_VERSION_MINOR 4
#define TB_VERSION_PATCH 0

#define TB_PACKED_USERS 1

#ifndef TB_API
#  ifdef __cplusplus
#    define TB_EXTERN extern "C"
#  else
#    define TB_EXTERN
#  endif
#  ifdef TB_DLL
#    ifdef TB_IMPORT_DLL
#      define TB_API TB_EXTERN __declspec(dllimport)
#    else
#      define TB_API TB_EXTERN __declspec(dllexport)
#    endif
#  else
#    define TB_API TB_EXTERN
#  endif
#endif

// These are flags
typedef enum TB_ArithmeticBehavior {
    TB_ARITHMATIC_NONE = 0,
    TB_ARITHMATIC_NSW  = 1,
    TB_ARITHMATIC_NUW  = 2,
} TB_ArithmeticBehavior;

typedef enum TB_DebugFormat {
    TB_DEBUGFMT_NONE,

    TB_DEBUGFMT_DWARF,
    TB_DEBUGFMT_CODEVIEW,

    TB_DEBUGFMT_SDG,
} TB_DebugFormat;

typedef enum TB_Arch {
    TB_ARCH_UNKNOWN,

    TB_ARCH_X86_64,
    TB_ARCH_AARCH64,

    // they're almost identical so might as well do both.
    TB_ARCH_MIPS32,
    TB_ARCH_MIPS64,

    TB_ARCH_WASM32,

    TB_ARCH_MAX,
} TB_Arch;

typedef enum TB_System {
    TB_SYSTEM_WINDOWS,
    TB_SYSTEM_LINUX,
    TB_SYSTEM_MACOS,
    TB_SYSTEM_ANDROID, // Not supported yet
    TB_SYSTEM_WASM,

    TB_SYSTEM_MAX,
} TB_System;

typedef enum TB_WindowsSubsystem {
    TB_WIN_SUBSYSTEM_UNKNOWN,

    TB_WIN_SUBSYSTEM_WINDOWS,
    TB_WIN_SUBSYSTEM_CONSOLE,
    TB_WIN_SUBSYSTEM_EFI_APP,
} TB_WindowsSubsystem;

typedef enum TB_ABI {
    // Used on 64bit Windows platforms
    TB_ABI_WIN64,

    // Used on Mac, BSD and Linux platforms
    TB_ABI_SYSTEMV,
} TB_ABI;

typedef enum TB_OutputFlavor {
    TB_FLAVOR_OBJECT,     // .o  .obj
    TB_FLAVOR_SHARED,     // .so .dll
    TB_FLAVOR_STATIC,     // .a  .lib
    TB_FLAVOR_EXECUTABLE, //     .exe
} TB_OutputFlavor;

typedef enum TB_CallingConv {
    TB_CDECL,
    TB_STDCALL
} TB_CallingConv;

typedef enum TB_FeatureSet_X64 {
    TB_FEATURE_X64_SSE2   = (1u << 0u),
    TB_FEATURE_X64_SSE3   = (1u << 1u),
    TB_FEATURE_X64_SSE41  = (1u << 2u),
    TB_FEATURE_X64_SSE42  = (1u << 3u),

    TB_FEATURE_X64_POPCNT = (1u << 4u),
    TB_FEATURE_X64_LZCNT  = (1u << 5u),

    TB_FEATURE_X64_CLMUL  = (1u << 6u),
    TB_FEATURE_X64_F16C   = (1u << 7u),

    TB_FEATURE_X64_BMI1   = (1u << 8u),
    TB_FEATURE_X64_BMI2   = (1u << 9u),

    TB_FEATURE_X64_AVX    = (1u << 10u),
    TB_FEATURE_X64_AVX2   = (1u << 11u),
} TB_FeatureSet_X64;

typedef enum TB_FeatureSet_Generic {
    TB_FEATURE_FRAME_PTR  = (1u << 0u),
} TB_FeatureSet_Generic;

typedef struct TB_FeatureSet {
    uint32_t gen; // TB_FeatureSet_Generic
    uint32_t x64; // TB_FeatureSet_X64
} TB_FeatureSet;

typedef enum TB_Linkage {
    TB_LINKAGE_PUBLIC,
    TB_LINKAGE_PRIVATE
} TB_Linkage;

typedef enum {
    TB_COMDAT_NONE,
    TB_COMDAT_MATCH_ANY,
} TB_ComdatType;

typedef enum TB_MemoryOrder {
    // atomic ops, unordered
    TB_MEM_ORDER_RELAXED,

    // acquire for loads:
    //   loads/stores from after this load cannot be reordered
    //   after this load.
    //
    // release for stores:
    //   loads/stores from before this store on this thread
    //   can't be reordered after this store.
    TB_MEM_ORDER_ACQ_REL,

    // acquire, release and total order across threads.
    TB_MEM_ORDER_SEQ_CST,
} TB_MemoryOrder;

typedef enum TB_DataTypeEnum {
    // Integers, note void is an i0 and bool is an i1
    //   i(0-64)
    TB_TAG_INT,
    // Floating point numbers
    TB_TAG_F32,
    TB_TAG_F64,
    // Pointers
    TB_TAG_PTR,
    // represents control flow for REGION, BRANCH
    TB_TAG_CONTROL,
    // represents memory (and I/O)
    TB_TAG_MEMORY,
    // Tuples, these cannot be used in memory ops, just accessed via projections
    TB_TAG_TUPLE,
} TB_DataTypeEnum;

typedef union TB_DataType {
    struct {
        uint16_t type : 4;
        // for integers it's the bitwidth
        uint16_t data : 12;
    };
    uint16_t raw;
} TB_DataType;
static_assert(sizeof(TB_DataType) == 2, "im expecting this to be a uint16_t");

// classify data types
#define TB_IS_VOID_TYPE(x)     ((x).type == TB_TAG_INT && (x).data == 0)
#define TB_IS_BOOL_TYPE(x)     ((x).type == TB_TAG_INT && (x).data == 1)
#define TB_IS_INTEGER_TYPE(x)  ((x).type == TB_TAG_INT)
#define TB_IS_FLOAT_TYPE(x)    ((x).type == TB_TAG_F32 || (x).type == TB_TAG_F64)
#define TB_IS_POINTER_TYPE(x)  ((x).type == TB_TAG_PTR)
#define TB_IS_SCALAR_TYPE(x)   ((x).type <= TB_TAG_PTR)

// accessors
#define TB_GET_INT_BITWIDTH(x) ((x).data)
#define TB_GET_FLOAT_FORMAT(x) ((x).data)
#define TB_GET_PTR_ADDRSPACE(x) ((x).data)

////////////////////////////////
// ANNOTATIONS
////////////////////////////////
//
//   (A, B) -> (C, D)
//
//   node takes A and B, produces C, D. if there's multiple
//   results we need to use projections and the indices are
//   based on the order seen here, proj0 is C, proj1 is D.
//
//   (A, B) & C -> Int
//
//   nodes takes A and B along with C in it's extra data. this is
//   where non-node inputs fit.
//
typedef enum TB_NodeTypeEnum {
    TB_NULL = 0,

    ////////////////////////////////
    // CONSTANTS
    ////////////////////////////////
    TB_ICONST,
    TB_F32CONST,
    TB_F64CONST,

    ////////////////////////////////
    // PROJECTIONS
    ////////////////////////////////
    // projections just extract a single field of a tuple
    TB_PROJ,          // Tuple & Int -> Any
    // control projection for TB_BRANCH
    TB_BRANCH_PROJ,   // Branch & Int -> Control
    // this is a hack for me to add nodes which need to be scheduled directly
    // after a tuple (like a projection) but don't really act like projections
    // in any other context.
    TB_MACH_PROJ, // (T) & Index -> T

    ////////////////////////////////
    // MISCELLANEOUS
    ////////////////////////////////
    // this is an unspecified value, usually generated by the optimizer
    // when malformed input is folded into an operation.
    TB_POISON,        // () -> Any
    // this is a simple way to embed machine code into the code
    TB_INLINE_ASM,    // (Control, Memory) & InlineAsm -> (Control, Memory)
    // reads the TSC on x64
    TB_CYCLE_COUNTER, // (Control) -> Int64
    // prefetches data for reading. The number next to the
    //
    //   0   is temporal
    //   1-3 are just cache levels
    TB_PREFETCH,      // (Memory, Ptr) & Int -> Memory
    // this is a bookkeeping node for constructing IR while optimizing, so we
    // don't keep track of nodes while running peeps.
    TB_SYMBOL_TABLE,

    ////////////////////////////////
    // CONTROL
    ////////////////////////////////
    //   there's only one ROOT per function, it's inputs are the return values, it's
    //   outputs are the initial params.
    TB_ROOT,         // (Callgraph, Exits...) -> (Control, Memory, RPC, Data...)
    //   return nodes feed into ROOT, jumps through the RPC out of this stack frame.
    TB_RETURN,       // (Control, Memory, RPC, Data...) -> ()
    //   regions are used to represent paths which have multiple entries.
    //   each input is a predecessor.
    TB_REGION,       // (Control...) -> (Control)
    //   a natural loop header has the first edge be the dominating predecessor, every other edge
    //   is a backedge.
    TB_NATURAL_LOOP, // (Control...) -> (Control)
    //   a natural loop header (thus also a region) with an affine induction var (and thus affine loop bounds)
    TB_AFFINE_LOOP,  // (Control...) -> (Control)
    //   phi nodes work the same as in SSA CFG, the value is based on which predecessor was taken.
    //   each input lines up with the regions such that region.in[i] will use phi.in[i+1] as the
    //   subsequent data.
    TB_PHI,          // (Control, Data...) -> Data
    //   branch is used to implement most control flow, it acts like a switch
    //   statement in C usually. they take a key and match against some cases,
    //   if they match, it'll jump to that successor, if none match it'll take
    //   the default successor.
    //
    //   if (cond) { A; } else { B; }    is just     switch (cond) { case 0: B; default: A; }
    //
    //   it's possible to not pass a key and the default successor is always called, this is
    //   a GOTO. tb_inst_goto, tb_inst_if can handle common cases for you.
    TB_BRANCH,      // (Control, Data) -> (Control...)
    //   just a branch but tagged as the latch to some affine loop.
    TB_AFFINE_LATCH,// (Control, Data) -> (Control...)
    //   this is a fake branch which acts as a backedge for infinite loops, this keeps the
    //   graph from getting disconnected with the endpoint.
    //
    //   CProj0 is the taken path, CProj1 is exits the loop.
    TB_NEVER_BRANCH,// (Control) -> (Control...)
    //   this is a fake branch that lets us define multiple entry points into the function for whatever
    //   reason.
    TB_ENTRY_FORK,
    //   debugbreak will trap in a continuable manner.
    TB_DEBUGBREAK,  // (Control, Memory) -> (Control)
    //   trap will not be continuable but will stop execution.
    TB_TRAP,        // (Control, Memory) -> (Control)
    //   unreachable means it won't trap or be continuable.
    TB_UNREACHABLE, // (Control, Memory) -> (Control)
    //   all dead paths are stitched here
    TB_DEAD,        // (Control) -> (Control)

    ////////////////////////////////
    // CONTROL + MEMORY
    ////////////////////////////////
    //   nothing special, it's just a function call, 3rd argument here is the
    //   target pointer (or syscall number) and the rest are just data args.
    TB_CALL,           // (Control, Memory, Ptr, Data...) -> (Control, Memory, Data)
    TB_SYSCALL,        // (Control, Memory, Ptr, Data...) -> (Control, Memory, Data)
    //   performs call while recycling the stack frame somewhat
    TB_TAILCALL,       // (Control, Memory, RPC, Data, Data...) -> ()
    //   this is a safepoint used for traditional C debugging, each of these nodes
    //   annotates a debug line location.
    TB_DEBUG_LOCATION, // (Control, Memory) -> (Control, Memory)
    //   safepoint polls are the same except they only trigger if the poll site
    //   says to (platform specific but almost always just the page being made
    //   unmapped/guard), 3rd argument is the poll site.
    TB_SAFEPOINT_POLL, // (Control, Memory, Ptr?, Data...) -> (Control)
    //   this special op tracks calls such that we can produce our cool call graph, there's
    //   one call graph node per function that never moves.
    TB_CALLGRAPH,      // (Call...) -> Void

    ////////////////////////////////
    // MEMORY
    ////////////////////////////////
    //   produces a set of non-aliasing memory effects
    TB_SPLITMEM,    // (Memory) -> (Memory...)
    //   MERGEMEM will join multiple non-aliasing memory effects, because
    //   they don't alias there's no ordering guarentee.
    TB_MERGEMEM,    // (Split, Memory...) -> Memory
    //   LOAD and STORE are standard memory accesses, they can be folded away.
    TB_LOAD,        // (Control?, Memory, Ptr)      -> Data
    TB_STORE,       // (Control, Memory, Ptr, Data) -> Memory
    //   bulk memory ops.
    TB_MEMCPY,      // (Control, Memory, Ptr, Ptr, Size)  -> Memory
    TB_MEMSET,      // (Control, Memory, Ptr, Int8, Size) -> Memory
    //   these memory accesses represent "volatile" which means
    //   they may produce side effects and thus cannot be eliminated.
    TB_READ,        // (Control, Memory, Ptr)       -> (Memory, Data)
    TB_WRITE,       // (Control, Memory, Ptr, Data) -> (Memory, Data)
    //   atomics have multiple observers (if not they wouldn't need to
    //   be atomic) and thus produce side effects everywhere just like
    //   volatiles except they have synchronization guarentees. the atomic
    //   data ops will return the value before the operation is performed.
    //   Atomic CAS return the old value and a boolean for success (true if
    //   the value was changed)
    TB_ATOMIC_LOAD,   // (Control, Memory, Ptr)        -> (Memory, Data)
    TB_ATOMIC_XCHG,   // (Control, Memory, Ptr, Data)  -> (Memory, Data)
    TB_ATOMIC_ADD,    // (Control, Memory, Ptr, Data)  -> (Memory, Data)
    TB_ATOMIC_AND,    // (Control, Memory, Ptr, Data)  -> (Memory, Data)
    TB_ATOMIC_XOR,    // (Control, Memory, Ptr, Data)  -> (Memory, Data)
    TB_ATOMIC_OR,     // (Control, Memory, Ptr, Data)  -> (Memory, Data)
    TB_ATOMIC_PTROFF, // (Control, Memory, Ptr, Ptr)   -> (Memory, Ptr)
    TB_ATOMIC_CAS,    // (Control, Memory, Data, Data) -> (Memory, Data, Bool)

    // like a multi-way branch but without the control flow aspect, but for data.
    TB_LOOKUP,

    ////////////////////////////////
    // POINTERS
    ////////////////////////////////
    //   LOCAL will statically allocate stack space
    TB_LOCAL,         // () & (Int, Int) -> Ptr
    //   SYMBOL will return a pointer to a TB_Symbol
    TB_SYMBOL,        // () & TB_Symbol* -> Ptr
    //   offsets pointer by byte amount (handles all ptr math you actually want)
    TB_PTR_OFFSET,    // (Ptr, Int) -> Ptr

    // Conversions
    TB_TRUNCATE,
    TB_FLOAT_TRUNC,
    TB_FLOAT_EXT,
    TB_SIGN_EXT,
    TB_ZERO_EXT,
    TB_UINT2FLOAT,
    TB_FLOAT2UINT,
    TB_INT2FLOAT,
    TB_FLOAT2INT,
    TB_BITCAST,

    // Select
    TB_SELECT,

    // Bitmagic
    TB_BSWAP,
    TB_CLZ,
    TB_CTZ,
    TB_POPCNT,

    // Unary operations
    TB_NEG,
    TB_FNEG,

    // Integer arithmatic
    TB_AND,
    TB_OR,
    TB_XOR,
    TB_ADD,
    TB_SUB,
    TB_MUL,

    TB_SHL,
    TB_SHR,
    TB_SAR,
    TB_ROL,
    TB_ROR,
    TB_UDIV,
    TB_SDIV,
    TB_UMOD,
    TB_SMOD,

    // Float arithmatic
    TB_FADD,
    TB_FSUB,
    TB_FMUL,
    TB_FDIV,
    TB_FMIN,
    TB_FMAX,

    // Comparisons
    TB_CMP_EQ,
    TB_CMP_NE,
    TB_CMP_ULT,
    TB_CMP_ULE,
    TB_CMP_SLT,
    TB_CMP_SLE,
    TB_CMP_FLT,
    TB_CMP_FLE,

    // Special ops
    //   add with carry
    TB_ADC,     // (Int, Int, Bool?) -> (Int, Bool)
    //   division and modulo
    TB_UDIVMOD, // (Int, Int) -> (Int, Int)
    TB_SDIVMOD, // (Int, Int) -> (Int, Int)
    //   does full multiplication (64x64=128 and so on) returning
    //   the low and high values in separate projections
    TB_MULPAIR,

    // variadic
    TB_VA_START,

    // x86 intrinsics
    TB_X86INTRIN_LDMXCSR,
    TB_X86INTRIN_STMXCSR,
    TB_X86INTRIN_SQRT,
    TB_X86INTRIN_RSQRT,

    // general machine nodes:
    // does the phi move
    TB_MACH_MOVE,
    TB_MACH_COPY,
    // just... it, idk, it's the frame ptr
    TB_MACH_FRAME_PTR,
    // isn't the pointer value itself, just a placeholder for
    // referring to a global.
    TB_MACH_SYMBOL,

    // limit on generic nodes
    TB_NODE_TYPE_MAX,

    // each family of machine nodes gets 256 nodes
    // first machine op, we have some generic ops here:
    TB_MACH_X86  = TB_ARCH_X86_64 * 0x100,
    TB_MACH_MIPS = TB_ARCH_MIPS32 * 0x100,
} TB_NodeTypeEnum;
typedef uint16_t TB_NodeType;
static_assert(sizeof(TB_NODE_TYPE_MAX) < 0x100, "this is the bound where machine nodes start");

// just represents some region of bytes, usually in file parsing crap
typedef struct {
    const uint8_t* data;
    size_t length;
} TB_Slice;

// represents byte counts
typedef uint32_t TB_CharUnits;

// will get interned so each TB_Module has a unique identifier for the source file
typedef struct {
    // used by the debug info export
    int id;

    size_t len;
    uint8_t path[];
} TB_SourceFile;

typedef struct TB_Location {
    TB_SourceFile* file;
    int line, column;
    uint32_t pos;
} TB_Location;

// SO refers to shared objects which mean either shared libraries (.so or .dll)
// or executables (.exe or ELF executables)
typedef enum {
    // exports to the rest of the shared object
    TB_EXTERNAL_SO_LOCAL,

    // exports outside of the shared object
    TB_EXTERNAL_SO_EXPORT,
} TB_ExternalType;

typedef struct TB_Global            TB_Global;
typedef struct TB_External          TB_External;
typedef struct TB_Function          TB_Function;

typedef struct TB_Module            TB_Module;
typedef struct TB_DebugType         TB_DebugType;
typedef struct TB_ModuleSection     TB_ModuleSection;
typedef struct TB_FunctionPrototype TB_FunctionPrototype;

// TODO(NeGate): get rid of the lack of namespace here
typedef struct RegMask RegMask;

enum { TB_MODULE_SECTION_NONE = -1 };
typedef int32_t TB_ModuleSectionHandle;
typedef struct TB_Attrib TB_Attrib;

// target-specific, just a unique ID for the registers
typedef int TB_PhysicalReg;

// Thread local module state
typedef struct TB_ThreadInfo TB_ThreadInfo;

typedef enum {
    TB_SYMBOL_NONE,
    TB_SYMBOL_EXTERNAL,
    TB_SYMBOL_GLOBAL,
    TB_SYMBOL_FUNCTION,
    TB_SYMBOL_MAX,
} TB_SymbolTag;

// Refers generically to objects within a module
//
// TB_Function, TB_Global, and TB_External are all subtypes of TB_Symbol
// and thus are safely allowed to cast into a symbol for operations.
typedef struct TB_Symbol {
    TB_SymbolTag tag;

    // which thread info it's tied to (we may need to remove it, this
    // is used for that)
    TB_ThreadInfo* info;
    char* name;

    // It's kinda a weird circular reference but yea
    TB_Module* module;

    // helpful for sorting and getting consistent builds
    uint64_t ordinal;

    union {
        // if we're JITing then this maps to the address of the symbol
        void* address;
        size_t symbol_id;
    };

    // after this point it's tag-specific storage
} TB_Symbol;

typedef struct TB_Node TB_Node;

typedef struct {
    #if TB_PACKED_USERS
    uint64_t _n    : 48;
    uint64_t _slot : 16;
    #else
    TB_Node* _n;
    int _slot;
    #endif
} TB_User;

struct TB_Node {
    TB_NodeType type;
    TB_DataType dt;

    uint16_t input_cap;
    uint16_t input_count;

    uint16_t user_cap;
    uint16_t user_count;

    // makes it easier to track in graph walks
    uint32_t gvn;
    // use-def edges, unordered
    TB_User* users;
    // ordered def-use edges, jolly ol' semantics.
    //   after input_count (and up to input_cap) goes an unordered set of nodes which
    //   act as extra deps, this is where anti-deps and other scheduling related edges
    //   are placed. stole this trick from Cliff... ok if you look at my compiler impl
    //   stuff it's either gonna be like trad compiler stuff, Cnile, LLVM or Cliff that's
    //   just how i learned :p
    TB_Node** inputs;

    char extra[];
};

// These are the extra data in specific nodes
#define TB_NODE_GET_EXTRA(n)         ((void*) n->extra)
#define TB_NODE_GET_EXTRA_T(n, T)    ((T*) (n)->extra)
#define TB_NODE_SET_EXTRA(n, T, ...) (*((T*) (n)->extra) = (T){ __VA_ARGS__ })

// this represents switch (many targets), if (one target)
typedef struct { // TB_BRANCH
    uint64_t total_hits;
    size_t succ_count;
} TB_NodeBranch;

typedef struct { // TB_MACH_COPY
    RegMask* use;
    RegMask* def;
} TB_NodeMachCopy;

typedef struct { // TB_PROJ
    int index;
} TB_NodeProj;

typedef struct { // TB_SYMBOL_TABLE
    bool complete;
} TB_NodeSymbolTable;

typedef struct { // TB_MACH_PROJ
    int index;
    RegMask* def;
} TB_NodeMachProj;

typedef struct { // TB_MACH_SYMBOL
    TB_Symbol* sym;
} TB_NodeMachSymbol;

typedef struct { // TB_BRANCH_PROJ
    int index;
    uint64_t taken;
    int64_t key;
} TB_NodeBranchProj;

typedef struct { // TB_ICONST
    uint64_t value;
} TB_NodeInt;

typedef struct { // any compare operator
    TB_DataType cmp_dt;
} TB_NodeCompare;

typedef struct { // any integer binary operator
    TB_ArithmeticBehavior ab;
} TB_NodeBinopInt;

typedef struct {
    TB_CharUnits align;
} TB_NodeMemAccess;

typedef struct { // TB_DEBUG_LOCATION
    TB_SourceFile* file;
    int line, column;
} TB_NodeDbgLoc;

typedef struct {
    int level;
} TB_NodePrefetch;

typedef struct {
    TB_CharUnits size, align;

    // 0 if local is used beyond direct memops, 1...n as a unique alias name
    int alias_index;

    // used when machine-ifying it
    int stack_pos;

    // dbg info
    char* name;
    TB_DebugType* type;
} TB_NodeLocal;

typedef struct {
    float value;
} TB_NodeFloat32;

typedef struct {
    double value;
} TB_NodeFloat64;

typedef struct {
    // if true, we just duplicate the input memory per projection
    // the alias_idx is unused.
    bool same_edges;

    int alias_cnt;
    int alias_idx[];
} TB_NodeMemSplit;

typedef struct {
    TB_Symbol* sym;
} TB_NodeSymbol;

typedef struct {
    TB_MemoryOrder order;
    TB_MemoryOrder order2;
} TB_NodeAtomic;

typedef struct {
    TB_FunctionPrototype* proto;
    int proj_count;
} TB_NodeCall;

typedef struct {
    TB_FunctionPrototype* proto;
} TB_NodeTailcall;

typedef struct {
    void* userdata;
    int param_start;
} TB_NodeSafepoint;

typedef struct {
    const char* tag;

    // used for IR building
    TB_Node *mem_in;
} TB_NodeRegion;

typedef struct {
    int64_t key;
    uint64_t val;
} TB_LookupEntry;

typedef struct {
    size_t entry_count;
    TB_LookupEntry entries[];
} TB_NodeLookup;

typedef struct TB_MultiOutput {
    size_t count;
    union {
        // count = 1
        TB_Node* single;
        // count > 1
        TB_Node** multiple;
    };
} TB_MultiOutput;
#define TB_MULTI_OUTPUT(o) ((o).count > 1 ? (o).multiple : &(o).single)

typedef struct {
    int64_t key;
    TB_Node* value;
} TB_SwitchEntry;

typedef enum {
    TB_EXECUTABLE_UNKNOWN,
    TB_EXECUTABLE_PE,
    TB_EXECUTABLE_ELF,
} TB_ExecutableType;

typedef struct TB_Safepoint {
    TB_Node* node; // type == TB_SAFEPOINT
    void* userdata;

    uint32_t ip;    // relative to the function body.
    uint32_t count; // same as node->input_count
    int32_t values[];
} TB_Safepoint;

typedef enum {
    TB_MODULE_SECTION_WRITE = 1,
    TB_MODULE_SECTION_EXEC  = 2,
    TB_MODULE_SECTION_TLS   = 4,
} TB_ModuleSectionFlags;

typedef void (*TB_InlineAsmRA)(TB_Node* n, void* ctx);

// This is the function that'll emit bytes from a TB_INLINE_ASM node
typedef size_t (*TB_InlineAsmEmit)(TB_Node* n, void* ctx, size_t out_cap, uint8_t* out);

typedef struct {
    void* ctx;
    TB_InlineAsmRA   ra;
    TB_InlineAsmEmit emit;
} TB_NodeInlineAsm;

// *******************************
// Public macros
// *******************************
#ifdef __cplusplus

#define TB_TYPE_TUPLE   TB_DataType{ { TB_TAG_TUPLE      } }
#define TB_TYPE_CONTROL TB_DataType{ { TB_TAG_CONTROL    } }
#define TB_TYPE_VOID    TB_DataType{ { TB_TAG_INT,    0  } }
#define TB_TYPE_I8      TB_DataType{ { TB_TAG_INT,    8  } }
#define TB_TYPE_I16     TB_DataType{ { TB_TAG_INT,    16 } }
#define TB_TYPE_I32     TB_DataType{ { TB_TAG_INT,    32 } }
#define TB_TYPE_I64     TB_DataType{ { TB_TAG_INT,    64 } }
#define TB_TYPE_F32     TB_DataType{ { TB_TAG_F32    } }
#define TB_TYPE_F64     TB_DataType{ { TB_TAG_F64    } }
#define TB_TYPE_BOOL    TB_DataType{ { TB_TAG_INT,    1  } }
#define TB_TYPE_PTR     TB_DataType{ { TB_TAG_PTR,    0  } }
#define TB_TYPE_MEMORY  TB_DataType{ { TB_TAG_MEMORY, 0  } }
#define TB_TYPE_INTN(N) TB_DataType{ { TB_TAG_INT,   (N) } }
#define TB_TYPE_PTRN(N) TB_DataType{ { TB_TAG_PTR,   (N) } }

#else

#define TB_TYPE_TUPLE   (TB_DataType){ { TB_TAG_TUPLE      } }
#define TB_TYPE_CONTROL (TB_DataType){ { TB_TAG_CONTROL    } }
#define TB_TYPE_VOID    (TB_DataType){ { TB_TAG_INT,    0  } }
#define TB_TYPE_I8      (TB_DataType){ { TB_TAG_INT,    8  } }
#define TB_TYPE_I16     (TB_DataType){ { TB_TAG_INT,    16 } }
#define TB_TYPE_I32     (TB_DataType){ { TB_TAG_INT,    32 } }
#define TB_TYPE_I64     (TB_DataType){ { TB_TAG_INT,    64 } }
#define TB_TYPE_F32     (TB_DataType){ { TB_TAG_F32    } }
#define TB_TYPE_F64     (TB_DataType){ { TB_TAG_F64    } }
#define TB_TYPE_BOOL    (TB_DataType){ { TB_TAG_INT,    1  } }
#define TB_TYPE_PTR     (TB_DataType){ { TB_TAG_PTR,    0  } }
#define TB_TYPE_MEMORY  (TB_DataType){ { TB_TAG_MEMORY, 0  } }
#define TB_TYPE_INTN(N) (TB_DataType){ { TB_TAG_INT,   (N) } }
#define TB_TYPE_PTRN(N) (TB_DataType){ { TB_TAG_PTR,   (N) } }

#endif

// defined in common/arena.h
#ifndef TB_OPAQUE_ARENA_DEF
#define TB_OPAQUE_ARENA_DEF
typedef struct TB_ArenaChunk TB_ArenaChunk;
typedef struct {
    TB_ArenaChunk* top;

    #ifndef NDEBUG
    uint32_t allocs;
    uint32_t alloc_bytes;
    #endif
} TB_Arena;

typedef struct TB_ArenaSavepoint {
    TB_ArenaChunk* top;
    char* avail;
} TB_ArenaSavepoint;
#endif // TB_OPAQUE_ARENA_DEF

TB_API void tb_arena_create(TB_Arena* restrict arena);
TB_API void tb_arena_destroy(TB_Arena* restrict arena);
TB_API void tb_arena_clear(TB_Arena* restrict arena);
TB_API bool tb_arena_is_empty(TB_Arena* restrict arena);
TB_API TB_ArenaSavepoint tb_arena_save(TB_Arena* arena);
TB_API void tb_arena_restore(TB_Arena* arena, TB_ArenaSavepoint sp);

////////////////////////////////
// Module management
////////////////////////////////
// Creates a module with the correct target and settings
TB_API TB_Module* tb_module_create(TB_Arch arch, TB_System sys, bool is_jit);

// Creates a module but defaults on the architecture and system based on the host machine
TB_API TB_Module* tb_module_create_for_host(bool is_jit);

// Frees all resources for the TB_Module and it's functions, globals and
// compiled code.
TB_API void tb_module_destroy(TB_Module* m);

// When targetting windows & thread local storage, you'll need to bind a tls index
// which is usually just a global that the runtime support has initialized, if you
// dont and the tls_index is used, it'll crash
TB_API void tb_module_set_tls_index(TB_Module* m, ptrdiff_t len, const char* name);

// not thread-safe
TB_API TB_ModuleSectionHandle tb_module_create_section(TB_Module* m, ptrdiff_t len, const char* name, TB_ModuleSectionFlags flags, TB_ComdatType comdat);

typedef struct {
    TB_ThreadInfo* info;
    size_t i;
} TB_SymbolIter;

// Lovely iterator for all the symbols... it's probably not "fast"
TB_SymbolIter tb_symbol_iter(TB_Module* mod);
TB_Symbol* tb_symbol_iter_next(TB_SymbolIter* iter);

////////////////////////////////
// Compiled code introspection
////////////////////////////////
enum { TB_ASSEMBLY_CHUNK_CAP = 4*1024 - sizeof(size_t[2]) };

typedef struct TB_Assembly TB_Assembly;
struct TB_Assembly {
    TB_Assembly* next;

    // nice chunk of text here
    size_t length;
    char data[];
};

// this is where the machine code and other relevant pieces go.
typedef struct TB_FunctionOutput TB_FunctionOutput;

TB_API void tb_output_print_asm(TB_FunctionOutput* out, FILE* fp);

TB_API uint8_t* tb_output_get_code(TB_FunctionOutput* out, size_t* out_length);

// returns NULL if there's no line info
TB_API TB_Location* tb_output_get_locations(TB_FunctionOutput* out, size_t* out_count);

// returns NULL if no assembly was generated
TB_API TB_Assembly* tb_output_get_asm(TB_FunctionOutput* out);

// this is relative to the start of the function (the start of the prologue)
TB_API TB_Safepoint* tb_safepoint_get(TB_Function* f, uint32_t relative_ip);

////////////////////////////////
// Disassembler
////////////////////////////////
TB_API ptrdiff_t tb_print_disassembly_inst(TB_Arch arch, size_t length, const void* ptr);

////////////////////////////////
// JIT compilation
////////////////////////////////
typedef struct TB_JIT TB_JIT;

#ifdef EMSCRIPTEN
TB_API void* tb_jit_wasm_obj(TB_Arena* arena, TB_Function* f);
#else
typedef struct TB_CPUContext TB_CPUContext;

// passing 0 to jit_heap_capacity will default to 4MiB
TB_API TB_JIT* tb_jit_begin(TB_Module* m, size_t jit_heap_capacity);
TB_API void* tb_jit_place_function(TB_JIT* jit, TB_Function* f);
TB_API void* tb_jit_place_global(TB_JIT* jit, TB_Global* g);
TB_API void* tb_jit_alloc_obj(TB_JIT* jit, size_t size, size_t align);
TB_API void tb_jit_free_obj(TB_JIT* jit, void* ptr);
TB_API void tb_jit_dump_heap(TB_JIT* jit);
TB_API void tb_jit_end(TB_JIT* jit);

typedef struct {
    void* tag;
    uint32_t offset;
} TB_ResolvedAddr;

TB_API void* tb_jit_resolve_addr(TB_JIT* jit, void* ptr, uint32_t* offset);
TB_API void* tb_jit_get_code_ptr(TB_Function* f);

// you can take an tag an allocation, fresh space for random userdata :)
TB_API void tb_jit_tag_object(TB_JIT* jit, void* ptr, void* tag);

// Debugger stuff
//   creates a new context we can run JIT code in, you don't
//   technically need this but it's a nice helper for writing
//   JITs especially when it comes to breakpoints (and eventually
//   safepoints)
TB_API TB_CPUContext* tb_jit_thread_create(TB_JIT* jit, size_t ud_size);
TB_API void* tb_jit_thread_get_userdata(TB_CPUContext* cpu);
TB_API void tb_jit_breakpoint(TB_JIT* jit, void* addr);

// offsetof pollsite in the CPUContext
TB_API size_t tb_jit_thread_pollsite(void);

// Only relevant when you're pausing the thread
TB_API void* tb_jit_thread_pc(TB_CPUContext* cpu);
TB_API void* tb_jit_thread_sp(TB_CPUContext* cpu);

TB_API bool tb_jit_thread_call(TB_CPUContext* cpu, void* pc, uint64_t* ret, size_t arg_count, void** args);

// returns true if we stepped off the end and returned through the trampoline
TB_API bool tb_jit_thread_step(TB_CPUContext* cpu, uint64_t* ret, uintptr_t pc_start, uintptr_t pc_end);
#endif

////////////////////////////////
// Exporter
////////////////////////////////
// Export buffers are generated in chunks because it's easier, usually the
// chunks are "massive" (representing some connected piece of the buffer)
// but they don't have to be.
typedef struct TB_ExportChunk TB_ExportChunk;
struct TB_ExportChunk {
    TB_ExportChunk* next;
    size_t pos, size;
    uint8_t data[];
};

typedef struct {
    size_t total;
    TB_ExportChunk *head, *tail;
} TB_ExportBuffer;

TB_API TB_ExportBuffer tb_module_object_export(TB_Module* m, TB_Arena* dst_arena, TB_DebugFormat debug_fmt);
TB_API bool tb_export_buffer_to_file(TB_ExportBuffer buffer, const char* path);

////////////////////////////////
// Linker exporter
////////////////////////////////
// This is used to export shared objects or executables
typedef struct TB_Linker TB_Linker;
typedef struct TB_LinkerSection TB_LinkerSection;
typedef struct TB_LinkerSectionPiece TB_LinkerSectionPiece;

typedef struct {
    enum {
        TB_LINKER_MSG_NULL,

        // pragma comment(lib, "blah")
        TB_LINKER_MSG_IMPORT,
    } tag;
    union {
        // pragma lib request
        TB_Slice import_path;
    };
} TB_LinkerMsg;

TB_API TB_ExecutableType tb_system_executable_format(TB_System s);

TB_API TB_Linker* tb_linker_create(TB_ExecutableType type, TB_Arch arch);
TB_API TB_ExportBuffer tb_linker_export(TB_Linker* l, TB_Arena* arena);
TB_API void tb_linker_destroy(TB_Linker* l);

TB_API bool tb_linker_get_msg(TB_Linker* l, TB_LinkerMsg* msg);

// windows only
TB_API void tb_linker_set_subsystem(TB_Linker* l, TB_WindowsSubsystem subsystem);

TB_API void tb_linker_set_entrypoint(TB_Linker* l, const char* name);

// Links compiled module into output
TB_API void tb_linker_append_module(TB_Linker* l, TB_Module* m);

// Adds object file to output
TB_API void tb_linker_append_object(TB_Linker* l, TB_Slice obj_name, TB_Slice content);

// Adds static library to output
//   this can include imports (wrappers for DLL symbols) along with
//   normal sections.
TB_API void tb_linker_append_library(TB_Linker* l, TB_Slice ar_name, TB_Slice content);

////////////////////////////////
// Symbols
////////////////////////////////
TB_API bool tb_extern_resolve(TB_External* e, TB_Symbol* sym);
TB_API TB_External* tb_extern_create(TB_Module* m, ptrdiff_t len, const char* name, TB_ExternalType type);

TB_API TB_SourceFile* tb_get_source_file(TB_Module* m, ptrdiff_t len, const char* path);

// Called once you're done with TB operations on a thread (or i guess when it's
// about to be killed :p), not calling it can only result in leaks on that thread
// and calling it too early will result in TB potentially reallocating it but there's
// should be no crashes from this, just potential slowdown or higher than expected memory
// usage.
TB_API void tb_free_thread_resources(void);

////////////////////////////////
// Function Prototypes
////////////////////////////////
typedef struct TB_PrototypeParam {
    TB_DataType dt;
    TB_DebugType* debug_type;

    // does not apply for returns
    const char* name;
} TB_PrototypeParam;

struct TB_FunctionPrototype {
    // header
    TB_CallingConv call_conv;
    uint16_t return_count, param_count;
    bool has_varargs;

    // params are directly followed by returns
    TB_PrototypeParam params[];
};
#define TB_PROTOTYPE_RETURNS(p) ((p)->params + (p)->param_count)

// creates a function prototype used to define a function's parameters and returns.
//
// function prototypes do not get freed individually and last for the entire run
// of the backend, they can also be reused for multiple functions which have
// matching signatures.
TB_API TB_FunctionPrototype* tb_prototype_create(TB_Module* m, TB_CallingConv cc, size_t param_count, const TB_PrototypeParam* params, size_t return_count, const TB_PrototypeParam* returns, bool has_varargs);

// same as tb_function_set_prototype except it will handle lowering from types like the TB_DebugType
// into the correct ABI and exposing sane looking nodes to the parameters.
//
// returns the parameters
TB_API TB_Node** tb_function_set_prototype_from_dbg(TB_Function* f, TB_ModuleSectionHandle section, TB_DebugType* dbg, size_t* out_param_count);
TB_API TB_FunctionPrototype* tb_prototype_from_dbg(TB_Module* m, TB_DebugType* dbg);

// used for ABI parameter passing
typedef enum {
    // needs a direct value
    TB_PASSING_DIRECT,

    // needs an address to the value
    TB_PASSING_INDIRECT,

    // doesn't use this parameter
    TB_PASSING_IGNORE,
} TB_PassingRule;

TB_API TB_PassingRule tb_get_passing_rule_from_dbg(TB_Module* mod, TB_DebugType* param_type, bool is_return);

////////////////////////////////
// Globals
////////////////////////////////
TB_API TB_Global* tb_global_create(TB_Module* m, ptrdiff_t len, const char* name, TB_DebugType* dbg_type, TB_Linkage linkage);

// allocate space for the global
TB_API void tb_global_set_storage(TB_Module* m, TB_ModuleSectionHandle section, TB_Global* global, size_t size, size_t align, size_t max_objects);

// returns a buffer which the user can fill to then have represented in the initializer
TB_API void* tb_global_add_region(TB_Module* m, TB_Global* global, size_t offset, size_t size);

// places a relocation for a global at offset, the size of the relocation
// depends on the pointer size
TB_API void tb_global_add_symbol_reloc(TB_Module* m, TB_Global* global, size_t offset, TB_Symbol* symbol);

TB_API TB_ModuleSectionHandle tb_module_get_text(TB_Module* m);
TB_API TB_ModuleSectionHandle tb_module_get_rdata(TB_Module* m);
TB_API TB_ModuleSectionHandle tb_module_get_data(TB_Module* m);
TB_API TB_ModuleSectionHandle tb_module_get_tls(TB_Module* m);

////////////////////////////////
// Function Attributes
////////////////////////////////
// These are parts of a function that describe metadata for instructions
TB_API void tb_function_attrib_variable(TB_Function* f, TB_Node* n, TB_Node* parent, ptrdiff_t len, const char* name, TB_DebugType* type);
TB_API void tb_function_attrib_scope(TB_Function* f, TB_Node* n, TB_Node* parent);

////////////////////////////////
// Debug info Generation
////////////////////////////////
TB_API TB_DebugType* tb_debug_get_void(TB_Module* m);
TB_API TB_DebugType* tb_debug_get_bool(TB_Module* m);
TB_API TB_DebugType* tb_debug_get_integer(TB_Module* m, bool is_signed, int bits);
TB_API TB_DebugType* tb_debug_get_float32(TB_Module* m);
TB_API TB_DebugType* tb_debug_get_float64(TB_Module* m);
TB_API TB_DebugType* tb_debug_create_ptr(TB_Module* m, TB_DebugType* base);
TB_API TB_DebugType* tb_debug_create_array(TB_Module* m, TB_DebugType* base, size_t count);
TB_API TB_DebugType* tb_debug_create_alias(TB_Module* m, TB_DebugType* base, ptrdiff_t len, const char* tag);
TB_API TB_DebugType* tb_debug_create_struct(TB_Module* m, ptrdiff_t len, const char* tag);
TB_API TB_DebugType* tb_debug_create_union(TB_Module* m, ptrdiff_t len, const char* tag);
TB_API TB_DebugType* tb_debug_create_field(TB_Module* m, TB_DebugType* type, ptrdiff_t len, const char* name, TB_CharUnits offset);

// returns the array you need to fill with fields
TB_API TB_DebugType** tb_debug_record_begin(TB_Module* m, TB_DebugType* type, size_t count);
TB_API void tb_debug_record_end(TB_DebugType* type, TB_CharUnits size, TB_CharUnits align);

TB_API TB_DebugType* tb_debug_create_func(TB_Module* m, TB_CallingConv cc, size_t param_count, size_t return_count, bool has_varargs);

TB_API TB_DebugType* tb_debug_field_type(TB_DebugType* type);

TB_API size_t tb_debug_func_return_count(TB_DebugType* type);
TB_API size_t tb_debug_func_param_count(TB_DebugType* type);

// you'll need to fill these if you make a function
TB_API TB_DebugType** tb_debug_func_params(TB_DebugType* type);
TB_API TB_DebugType** tb_debug_func_returns(TB_DebugType* type);

////////////////////////////////
// Symbols
////////////////////////////////
// returns NULL if the tag doesn't match
TB_API TB_Function* tb_symbol_as_function(TB_Symbol* s);
TB_API TB_External* tb_symbol_as_external(TB_Symbol* s);
TB_API TB_Global* tb_symbol_as_global(TB_Symbol* s);

////////////////////////////////
// Function IR Generation
////////////////////////////////
TB_API void tb_get_data_type_size(TB_Module* mod, TB_DataType dt, size_t* size, size_t* align);

TB_API void tb_inst_location(TB_Function* f, TB_SourceFile* file, int line, int column);

// this is where the STOP will be
TB_API void tb_inst_set_exit_location(TB_Function* f, TB_SourceFile* file, int line, int column);

// if section is NULL, default to .text
TB_API TB_Function* tb_function_create(TB_Module* m, ptrdiff_t len, const char* name, TB_Linkage linkage);

TB_API TB_Arena* tb_function_get_arena(TB_Function* f, int i);

// if len is -1, it's null terminated
TB_API void tb_symbol_set_name(TB_Symbol* s, ptrdiff_t len, const char* name);

TB_API void tb_symbol_bind_ptr(TB_Symbol* s, void* ptr);
TB_API const char* tb_symbol_get_name(TB_Symbol* s);

// if arena is NULL, defaults to module arena which is freed on tb_free_thread_resources
TB_API void tb_function_set_prototype(TB_Function* f, TB_ModuleSectionHandle section, TB_FunctionPrototype* p);
TB_API TB_FunctionPrototype* tb_function_get_prototype(TB_Function* f);

// if len is -1, it's null terminated
TB_API void tb_inst_set_region_name(TB_Function* f, TB_Node* n, ptrdiff_t len, const char* name);

TB_API TB_Node* tb_inst_poison(TB_Function* f, TB_DataType dt);

TB_API TB_Node* tb_inst_root_node(TB_Function* f);
TB_API TB_Node* tb_inst_param(TB_Function* f, int param_id);

TB_API TB_Node* tb_inst_fpxt(TB_Function* f, TB_Node* src, TB_DataType dt);
TB_API TB_Node* tb_inst_sxt(TB_Function* f, TB_Node* src, TB_DataType dt);
TB_API TB_Node* tb_inst_zxt(TB_Function* f, TB_Node* src, TB_DataType dt);
TB_API TB_Node* tb_inst_trunc(TB_Function* f, TB_Node* src, TB_DataType dt);
TB_API TB_Node* tb_inst_int2ptr(TB_Function* f, TB_Node* src);
TB_API TB_Node* tb_inst_ptr2int(TB_Function* f, TB_Node* src, TB_DataType dt);
TB_API TB_Node* tb_inst_int2float(TB_Function* f, TB_Node* src, TB_DataType dt, bool is_signed);
TB_API TB_Node* tb_inst_float2int(TB_Function* f, TB_Node* src, TB_DataType dt, bool is_signed);
TB_API TB_Node* tb_inst_bitcast(TB_Function* f, TB_Node* src, TB_DataType dt);

TB_API TB_Node* tb_inst_local(TB_Function* f, TB_CharUnits size, TB_CharUnits align);

TB_API TB_Node* tb_inst_load(TB_Function* f, TB_DataType dt, TB_Node* addr, TB_CharUnits align, bool is_volatile);
TB_API void tb_inst_store(TB_Function* f, TB_DataType dt, TB_Node* addr, TB_Node* val, TB_CharUnits align, bool is_volatile);

TB_API void tb_inst_safepoint_poll(TB_Function* f, void* tag, TB_Node* addr, int input_count, TB_Node** inputs);

TB_API TB_Node* tb_inst_bool(TB_Function* f, bool imm);
TB_API TB_Node* tb_inst_sint(TB_Function* f, TB_DataType dt, int64_t imm);
TB_API TB_Node* tb_inst_uint(TB_Function* f, TB_DataType dt, uint64_t imm);
TB_API TB_Node* tb_inst_float32(TB_Function* f, float imm);
TB_API TB_Node* tb_inst_float64(TB_Function* f, double imm);
TB_API TB_Node* tb_inst_cstring(TB_Function* f, const char* str);
TB_API TB_Node* tb_inst_string(TB_Function* f, size_t len, const char* str);

// write 'val' over 'count' bytes on 'dst'
TB_API void tb_inst_memset(TB_Function* f, TB_Node* dst, TB_Node* val, TB_Node* count, TB_CharUnits align);

// zero 'count' bytes on 'dst'
TB_API void tb_inst_memzero(TB_Function* f, TB_Node* dst, TB_Node* count, TB_CharUnits align);

// performs a copy of 'count' elements from one memory location to another
// both locations cannot overlap.
TB_API void tb_inst_memcpy(TB_Function* f, TB_Node* dst, TB_Node* src, TB_Node* count, TB_CharUnits align);

// result = base + (index * stride)
TB_API TB_Node* tb_inst_array_access(TB_Function* f, TB_Node* base, TB_Node* index, int64_t stride);

// result = base + offset
// where base is a pointer
TB_API TB_Node* tb_inst_member_access(TB_Function* f, TB_Node* base, int64_t offset);

TB_API TB_Node* tb_inst_get_symbol_address(TB_Function* f, TB_Symbol* target);

// Performs a conditional select between two values, if the operation is
// performed wide then the cond is expected to be the same type as a and b where
// the condition is resolved as true if the MSB (per component) is 1.
//
// result = cond ? a : b
// a, b must match in type
TB_API TB_Node* tb_inst_select(TB_Function* f, TB_Node* cond, TB_Node* a, TB_Node* b);

// Integer arithmatic
TB_API TB_Node* tb_inst_add(TB_Function* f, TB_Node* a, TB_Node* b, TB_ArithmeticBehavior arith_behavior);
TB_API TB_Node* tb_inst_sub(TB_Function* f, TB_Node* a, TB_Node* b, TB_ArithmeticBehavior arith_behavior);
TB_API TB_Node* tb_inst_mul(TB_Function* f, TB_Node* a, TB_Node* b, TB_ArithmeticBehavior arith_behavior);
TB_API TB_Node* tb_inst_div(TB_Function* f, TB_Node* a, TB_Node* b, bool signedness);
TB_API TB_Node* tb_inst_mod(TB_Function* f, TB_Node* a, TB_Node* b, bool signedness);

// Bitmagic operations
TB_API TB_Node* tb_inst_bswap(TB_Function* f, TB_Node* n);
TB_API TB_Node* tb_inst_clz(TB_Function* f, TB_Node* n);
TB_API TB_Node* tb_inst_ctz(TB_Function* f, TB_Node* n);
TB_API TB_Node* tb_inst_popcount(TB_Function* f, TB_Node* n);

// Bitwise operations
TB_API TB_Node* tb_inst_not(TB_Function* f, TB_Node* n);
TB_API TB_Node* tb_inst_neg(TB_Function* f, TB_Node* n);
TB_API TB_Node* tb_inst_and(TB_Function* f, TB_Node* a, TB_Node* b);
TB_API TB_Node* tb_inst_or(TB_Function* f, TB_Node* a, TB_Node* b);
TB_API TB_Node* tb_inst_xor(TB_Function* f, TB_Node* a, TB_Node* b);
TB_API TB_Node* tb_inst_sar(TB_Function* f, TB_Node* a, TB_Node* b);
TB_API TB_Node* tb_inst_shl(TB_Function* f, TB_Node* a, TB_Node* b, TB_ArithmeticBehavior arith_behavior);
TB_API TB_Node* tb_inst_shr(TB_Function* f, TB_Node* a, TB_Node* b);
TB_API TB_Node* tb_inst_rol(TB_Function* f, TB_Node* a, TB_Node* b);
TB_API TB_Node* tb_inst_ror(TB_Function* f, TB_Node* a, TB_Node* b);

// Atomics
// By default you can use TB_MEM_ORDER_SEQ_CST for the memory order to get
// correct but possibly slower results on certain platforms (those with relaxed
// memory models).

// Must be aligned to the natural alignment of dt
TB_API TB_Node* tb_inst_atomic_load(TB_Function* f, TB_Node* addr, TB_DataType dt, TB_MemoryOrder order);

// All atomic operations here return the old value and the operations are
// performed in the same data type as 'src' with alignment of 'addr' being
// the natural alignment of 'src'
TB_API TB_Node* tb_inst_atomic_xchg(TB_Function* f, TB_Node* addr, TB_Node* src, TB_MemoryOrder order);
TB_API TB_Node* tb_inst_atomic_add(TB_Function* f, TB_Node* addr, TB_Node* src, TB_MemoryOrder order);
TB_API TB_Node* tb_inst_atomic_and(TB_Function* f, TB_Node* addr, TB_Node* src, TB_MemoryOrder order);
TB_API TB_Node* tb_inst_atomic_xor(TB_Function* f, TB_Node* addr, TB_Node* src, TB_MemoryOrder order);
TB_API TB_Node* tb_inst_atomic_or(TB_Function* f, TB_Node* addr, TB_Node* src, TB_MemoryOrder order);

// returns old_value from *addr
TB_API TB_Node* tb_inst_atomic_cmpxchg(TB_Function* f, TB_Node* addr, TB_Node* expected, TB_Node* desired, TB_MemoryOrder succ, TB_MemoryOrder fail);

// Float math
TB_API TB_Node* tb_inst_fadd(TB_Function* f, TB_Node* a, TB_Node* b);
TB_API TB_Node* tb_inst_fsub(TB_Function* f, TB_Node* a, TB_Node* b);
TB_API TB_Node* tb_inst_fmul(TB_Function* f, TB_Node* a, TB_Node* b);
TB_API TB_Node* tb_inst_fdiv(TB_Function* f, TB_Node* a, TB_Node* b);

// Comparisons
TB_API TB_Node* tb_inst_cmp_eq(TB_Function* f, TB_Node* a, TB_Node* b);
TB_API TB_Node* tb_inst_cmp_ne(TB_Function* f, TB_Node* a, TB_Node* b);

TB_API TB_Node* tb_inst_cmp_ilt(TB_Function* f, TB_Node* a, TB_Node* b, bool signedness);
TB_API TB_Node* tb_inst_cmp_ile(TB_Function* f, TB_Node* a, TB_Node* b, bool signedness);
TB_API TB_Node* tb_inst_cmp_igt(TB_Function* f, TB_Node* a, TB_Node* b, bool signedness);
TB_API TB_Node* tb_inst_cmp_ige(TB_Function* f, TB_Node* a, TB_Node* b, bool signedness);

TB_API TB_Node* tb_inst_cmp_flt(TB_Function* f, TB_Node* a, TB_Node* b);
TB_API TB_Node* tb_inst_cmp_fle(TB_Function* f, TB_Node* a, TB_Node* b);
TB_API TB_Node* tb_inst_cmp_fgt(TB_Function* f, TB_Node* a, TB_Node* b);
TB_API TB_Node* tb_inst_cmp_fge(TB_Function* f, TB_Node* a, TB_Node* b);

// General intrinsics
TB_API TB_Node* tb_inst_va_start(TB_Function* f, TB_Node* a);
TB_API TB_Node* tb_inst_cycle_counter(TB_Function* f);
TB_API TB_Node* tb_inst_prefetch(TB_Function* f, TB_Node* addr, int level);

// x86 Intrinsics
TB_API TB_Node* tb_inst_x86_ldmxcsr(TB_Function* f, TB_Node* a);
TB_API TB_Node* tb_inst_x86_stmxcsr(TB_Function* f);
TB_API TB_Node* tb_inst_x86_sqrt(TB_Function* f, TB_Node* a);
TB_API TB_Node* tb_inst_x86_rsqrt(TB_Function* f, TB_Node* a);

// Control flow
//   trace is a single-entry piece of IR.
typedef struct {
    TB_Node* top_ctrl;
    TB_Node* bot_ctrl;

    // latest memory effect, for now there's
    // only one stream going at a time but that'll
    // have to change for some of the interesting
    // langs later.
    TB_Node* mem;
} TB_Trace;

// Old-style uses regions for all control flow similar to how people use basic blocks
TB_API TB_Node* tb_inst_region(TB_Function* f);
TB_API void tb_inst_set_control(TB_Function* f, TB_Node* region);
TB_API TB_Node* tb_inst_get_control(TB_Function* f);

// But since regions aren't basic blocks (they only guarentee single entry, not single exit)
// the new-style is built for that.
TB_API TB_Trace tb_inst_new_trace(TB_Function* f);
TB_API void tb_inst_set_trace(TB_Function* f, TB_Trace trace);
TB_API TB_Trace tb_inst_get_trace(TB_Function* f);

// only works on regions which haven't been constructed yet
TB_API TB_Trace tb_inst_trace_from_region(TB_Function* f, TB_Node* region);
TB_API TB_Node* tb_inst_region_mem_in(TB_Function* f, TB_Node* region);

TB_API TB_Node* tb_inst_syscall(TB_Function* f, TB_DataType dt, TB_Node* syscall_num, size_t param_count, TB_Node** params);
TB_API TB_MultiOutput tb_inst_call(TB_Function* f, TB_FunctionPrototype* proto, TB_Node* target, size_t param_count, TB_Node** params);
TB_API void tb_inst_tailcall(TB_Function* f, TB_FunctionPrototype* proto, TB_Node* target, size_t param_count, TB_Node** params);

TB_API TB_Node* tb_inst_safepoint(TB_Function* f, TB_Node* poke_site, size_t param_count, TB_Node** params);

TB_API TB_Node* tb_inst_incomplete_phi(TB_Function* f, TB_DataType dt, TB_Node* region, size_t preds);
TB_API bool tb_inst_add_phi_operand(TB_Function* f, TB_Node* phi, TB_Node* region, TB_Node* val);

TB_API TB_Node* tb_inst_phi2(TB_Function* f, TB_Node* region, TB_Node* a, TB_Node* b);
TB_API TB_Node* tb_inst_if(TB_Function* f, TB_Node* cond, TB_Node* true_case, TB_Node* false_case);
TB_API TB_Node* tb_inst_branch(TB_Function* f, TB_DataType dt, TB_Node* key, TB_Node* default_case, size_t entry_count, const TB_SwitchEntry* keys);
TB_API void tb_inst_unreachable(TB_Function* f);
TB_API void tb_inst_debugbreak(TB_Function* f);
TB_API void tb_inst_trap(TB_Function* f);
TB_API void tb_inst_goto(TB_Function* f, TB_Node* target);
TB_API void tb_inst_never_branch(TB_Function* f, TB_Node* if_true, TB_Node* if_false);

TB_API const char* tb_node_get_name(TB_NodeTypeEnum n_type);

// revised API for if, this one returns the control projections such that a target is not necessary while building
//   projs[0] is the true case, projs[1] is false.
TB_API TB_Node* tb_inst_if2(TB_Function* f, TB_Node* cond, TB_Node* projs[2]);

// n is a TB_BRANCH with two successors, taken is the number of times it's true
TB_API void tb_inst_set_branch_freq(TB_Function* f, TB_Node* n, int total_hits, int taken);

TB_API void tb_inst_ret(TB_Function* f, size_t count, TB_Node** values);

////////////////////////////////
// Optimizer API
////////////////////////////////
// To avoid allocs, you can make a worklist and keep it across multiple functions so long
// as they're not trying to use it at the same time.
typedef struct TB_Worklist TB_Worklist;

TB_API TB_Worklist* tb_worklist_alloc(void);
TB_API void tb_worklist_free(TB_Worklist* ws);

// if you decide during tb_opt that you wanna preserve the types, this is how you'd later free them.
TB_API void tb_opt_free_types(TB_Function* f);

// this will allocate the worklist, you can free worklist once you're done with analysis/transforms.
TB_API void tb_opt_push_all_nodes(TB_Function* f);
TB_API void tb_opt_dump_stats(TB_Function* f);

// returns GVN on a new node, returning either the same node or a duplicate node 'k'.
// it deletes 'n' if it's a duplicate btw.
TB_API TB_Node* tb_opt_gvn_node(TB_Function* f, TB_Node* n);
// returns isomorphic node that's run it's peepholes.
TB_API TB_Node* tb_opt_peep_node(TB_Function* f, TB_Node* n);

// Uses the two function arenas pretty heavily, may even flip their purposes (as a form
// of GC compacting)
//
// returns true if any graph rewrites were performed.
TB_API bool tb_opt(TB_Function* f, TB_Worklist* ws, bool preserve_types);

// print in SSA-CFG looking form (with BB params for the phis), if tmp is NULL it'll use the
// function's tmp arena
TB_API void tb_print(TB_Function* f);
TB_API void tb_print_dumb(TB_Function* f);

// super special experimental stuff (no touchy yet)
TB_API char* tb_c_prelude(TB_Module* mod);
TB_API char* tb_print_c(TB_Function* f, TB_Worklist* ws);

// codegen:
//   output goes at the top of the code_arena, feel free to place multiple functions
//   into the same code arena (although arenas aren't thread-safe you'll want one per thread
//   at least)
//
//   if code_arena is NULL, the IR arena will be used.
TB_API TB_FunctionOutput* tb_codegen(TB_Function* f, TB_Worklist* ws, TB_Arena* code_arena, const TB_FeatureSet* features, bool emit_asm);

// interprocedural optimizer iter
TB_API bool tb_module_ipo(TB_Module* m);

////////////////////////////////
// Cooler IR building
////////////////////////////////
typedef struct TB_GraphBuilder TB_GraphBuilder;
enum { TB_GRAPH_BUILDER_PARAMS = 0 };

// if ws != NULL, i'll run the peepholes while you're constructing nodes. why? because it
// avoids making junk nodes before they become a problem for memory bandwidth.
TB_API TB_GraphBuilder* tb_builder_enter(TB_Function* f, TB_ModuleSectionHandle section, TB_FunctionPrototype* proto, TB_Worklist* ws);

// parameter's addresses are available through the tb_builder_param_addr, they're not tracked as mutable vars.
TB_API TB_GraphBuilder* tb_builder_enter_from_dbg(TB_Function* f, TB_ModuleSectionHandle section, TB_DebugType* dbg, TB_Worklist* ws);

TB_API void tb_builder_exit(TB_GraphBuilder* g);
TB_API TB_Node* tb_builder_param_addr(TB_GraphBuilder* g, int i);

TB_API TB_Node* tb_builder_bool(TB_GraphBuilder* g, bool x);
TB_API TB_Node* tb_builder_uint(TB_GraphBuilder* g, TB_DataType dt, uint64_t x);
TB_API TB_Node* tb_builder_sint(TB_GraphBuilder* g, TB_DataType dt, int64_t x);
TB_API TB_Node* tb_builder_float32(TB_GraphBuilder* g, float imm);
TB_API TB_Node* tb_builder_float64(TB_GraphBuilder* g, double imm);
TB_API TB_Node* tb_builder_symbol(TB_GraphBuilder* g, TB_Symbol* sym);
TB_API TB_Node* tb_builder_string(TB_GraphBuilder* g, ptrdiff_t len, const char* str);

// works with type: AND, OR, XOR, ADD, SUB, MUL, SHL, SHR, SAR, ROL, ROR, UDIV, SDIV, UMOD, SMOD.
// note that arithmetic behavior is irrelevant for some of the operations (but 0 is always a good default).
TB_API TB_Node* tb_builder_binop_int(TB_GraphBuilder* g, int type, TB_Node* a, TB_Node* b, TB_ArithmeticBehavior ab);
TB_API TB_Node* tb_builder_binop_float(TB_GraphBuilder* g, int type, TB_Node* a, TB_Node* b);

TB_API TB_Node* tb_builder_select(TB_GraphBuilder* g, TB_Node* cond, TB_Node* a, TB_Node* b);
TB_API TB_Node* tb_builder_cast(TB_GraphBuilder* g, TB_DataType dt, int type, TB_Node* src);

// ( a -- b )
TB_API TB_Node* tb_builder_unary(TB_GraphBuilder* g, int type, TB_Node* src);

TB_API TB_Node* tb_builder_neg(TB_GraphBuilder* g, TB_Node* src);
TB_API TB_Node* tb_builder_not(TB_GraphBuilder* g, TB_Node* src);

// ( a b -- c )
TB_API TB_Node* tb_builder_cmp(TB_GraphBuilder* g, int type, TB_Node* a, TB_Node* b);

// pointer arithmetic
//   base + index*stride
TB_API TB_Node* tb_builder_ptr_array(TB_GraphBuilder* g, TB_Node* base, TB_Node* index, int64_t stride);
//   base + offset
TB_API TB_Node* tb_builder_ptr_member(TB_GraphBuilder* g, TB_Node* base, int64_t offset);

// memory
TB_API TB_Node* tb_builder_load(TB_GraphBuilder* g, int mem_var, bool ctrl_dep, TB_DataType dt, TB_Node* addr, TB_CharUnits align, bool is_volatile);
TB_API void tb_builder_store(TB_GraphBuilder* g, int mem_var, bool ctrl_dep, TB_Node* addr, TB_Node* val, TB_CharUnits align, bool is_volatile);
TB_API void tb_builder_memcpy(TB_GraphBuilder* g, int mem_var, bool ctrl_dep, TB_Node* dst, TB_Node* src, TB_Node* size, TB_CharUnits align, bool is_volatile);
TB_API void tb_builder_memset(TB_GraphBuilder* g, int mem_var, bool ctrl_dep, TB_Node* dst, TB_Node* val, TB_Node* size, TB_CharUnits align, bool is_volatile);
TB_API void tb_builder_memzero(TB_GraphBuilder* g, int mem_var, bool ctrl_dep, TB_Node* dst, TB_Node* size, TB_CharUnits align, bool is_volatile);

// returns initially loaded value
TB_API TB_Node* tb_builder_atomic_rmw(TB_GraphBuilder* g, int mem_var, int op, TB_Node* addr, TB_Node* val, TB_MemoryOrder order);
TB_API TB_Node* tb_builder_atomic_load(TB_GraphBuilder* g, int mem_var, TB_DataType dt, TB_Node* addr, TB_MemoryOrder order);

// splitting/merging:
//   splits the in_mem variable into multiple streams of the same "type".
//
//   returns the first newly allocated mem var (the rest are consecutive). *out_split will have the split node written to
//   it (because merge mem needs to know which split it's attached to).
TB_API int tb_builder_split_mem(TB_GraphBuilder* g, int in_mem, int split_count, TB_Node** out_split);
//   this will merge the memory effects back into out_mem, split_vars being the result of a tb_builder_split_mem(...)
TB_API void tb_builder_merge_mem(TB_GraphBuilder* g, int out_mem, int split_count, int split_vars, TB_Node* split);

TB_API void tb_builder_loc(TB_GraphBuilder* g, int mem_var, TB_SourceFile* file, int line, int column);

// function call
TB_API TB_Node** tb_builder_call(TB_GraphBuilder* g, TB_FunctionPrototype* proto, int mem_var, TB_Node* target, int arg_count, TB_Node** args);
TB_API TB_Node*  tb_builder_syscall(TB_GraphBuilder* g, TB_DataType dt, int mem_var, TB_Node* target, int arg_count, TB_Node** args);

// locals (variables but as stack vars)
TB_API TB_Node* tb_builder_local(TB_GraphBuilder* g, TB_CharUnits size, TB_CharUnits align);
TB_API void tb_builder_local_dbg(TB_GraphBuilder* g, TB_Node* n, ptrdiff_t len, const char* name, TB_DebugType* type);

// variables:
//   just gives you the ability to construct mutable names, from
//   there we just slot in the phis and such for you :)
TB_API int tb_builder_decl(TB_GraphBuilder* g);
TB_API TB_Node* tb_builder_get_var(TB_GraphBuilder* g, int id);
TB_API void tb_builder_set_var(TB_GraphBuilder* g, int id, TB_Node* v);

// control flow primitives:
//   makes a region we can jump to (generally for forward jumps)
TB_API TB_Node* tb_builder_label_make(TB_GraphBuilder* g);
//   once a label is complete you can no longer insert jumps to it, the phis
//   are placed and you can then insert code into the label's body.
TB_API void tb_builder_label_complete(TB_GraphBuilder* g, TB_Node* label);
//   begin building on the label (has to be completed now)
TB_API void tb_builder_label_set(TB_GraphBuilder* g, TB_Node* label);
//   just makes a label from an existing label (used when making the loop body defs)
TB_API TB_Node* tb_builder_label_clone(TB_GraphBuilder* g, TB_Node* label);
//   active label
TB_API TB_Node* tb_builder_label_get(TB_GraphBuilder* g);
//   number of predecessors at that point in time
TB_API int tb_builder_label_pred_count(TB_GraphBuilder* g, TB_Node* label);
//   kill node
TB_API void tb_builder_label_kill(TB_GraphBuilder* g, TB_Node* label);
//   returns an array of TB_GraphCtrl which represent each path on the
//   branch, [0] is the false case and [1] is the true case.
TB_API void tb_builder_if(TB_GraphBuilder* g, TB_Node* cond, TB_Node* paths[2]);
//   unconditional jump to target
TB_API void tb_builder_br(TB_GraphBuilder* g, TB_Node* target);
//   forward and backward branch target
TB_API TB_Node* tb_builder_loop(TB_GraphBuilder* g);

// technically TB has multiple returns, in practice it's like 2 regs before
// ABI runs out of shit.
TB_API void tb_builder_ret(TB_GraphBuilder* g, int mem_var, int arg_count, TB_Node** args);
TB_API void tb_builder_unreachable(TB_GraphBuilder* g, int mem_var);
TB_API void tb_builder_trap(TB_GraphBuilder* g, int mem_var);
TB_API void tb_builder_debugbreak(TB_GraphBuilder* g, int mem_var);

// allows you to define multiple entry points
TB_API void tb_builder_entry_fork(TB_GraphBuilder* g, int count, TB_Node* paths[]);

// general intrinsics
TB_API TB_Node* tb_builder_cycle_counter(TB_GraphBuilder* g);
TB_API TB_Node* tb_builder_prefetch(TB_GraphBuilder* g, TB_Node* addr, int level);

// x86 Intrinsics
TB_API TB_Node* tb_builder_x86_ldmxcsr(TB_GraphBuilder* g, TB_Node* a);
TB_API TB_Node* tb_builder_x86_stmxcsr(TB_GraphBuilder* g);

////////////////////////////////
// IR access
////////////////////////////////
TB_API bool tb_node_is_constant_non_zero(TB_Node* n);
TB_API bool tb_node_is_constant_zero(TB_Node* n);

#endif /* TB_CORE_H */
