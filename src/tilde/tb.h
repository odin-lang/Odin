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

// https://semver.org/
#define TB_VERSION_MAJOR 0
#define TB_VERSION_MINOR 2
#define TB_VERSION_PATCH 0

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

    TB_DEBUGFMT_COLINPILLED
} TB_DebugFormat;

typedef enum TB_Arch {
    TB_ARCH_UNKNOWN,

    TB_ARCH_X86_64,
    TB_ARCH_AARCH64, // unsupported but planned
    TB_ARCH_WASM32,
} TB_Arch;

typedef enum TB_System {
    TB_SYSTEM_WINDOWS,
    TB_SYSTEM_LINUX,
    TB_SYSTEM_MACOS,
    TB_SYSTEM_ANDROID, // Not supported yet
    TB_SYSTEM_WEB,

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
    TB_FEATURE_X64_SSE3   = (1u << 0u),
    TB_FEATURE_X64_SSE41  = (1u << 1u),
    TB_FEATURE_X64_SSE42  = (1u << 2u),

    TB_FEATURE_X64_POPCNT = (1u << 3u),
    TB_FEATURE_X64_LZCNT  = (1u << 4u),

    TB_FEATURE_X64_CLMUL  = (1u << 5u),
    TB_FEATURE_X64_F16C   = (1u << 6u),

    TB_FEATURE_X64_BMI1   = (1u << 7u),
    TB_FEATURE_X64_BMI2   = (1u << 8u),

    TB_FEATURE_X64_AVX    = (1u << 9u),
    TB_FEATURE_X64_AVX2   = (1u << 10u),
} TB_FeatureSet_X64;

typedef struct TB_FeatureSet {
    TB_FeatureSet_X64 x64;
} TB_FeatureSet;

typedef enum TB_BranchHint {
    TB_BRANCH_HINT_NONE,
    TB_BRANCH_HINT_LIKELY,
    TB_BRANCH_HINT_UNLIKELY
} TB_BranchHint;

typedef enum TB_Linkage {
    TB_LINKAGE_PUBLIC,
    TB_LINKAGE_PRIVATE
} TB_Linkage;

typedef enum {
    TB_COMDAT_NONE,

    TB_COMDAT_MATCH_ANY,
} TB_ComdatType;

typedef enum TB_MemoryOrder {
    TB_MEM_ORDER_RELAXED,
    TB_MEM_ORDER_CONSUME,
    TB_MEM_ORDER_ACQUIRE,
    TB_MEM_ORDER_RELEASE,
    TB_MEM_ORDER_ACQ_REL,
    TB_MEM_ORDER_SEQ_CST,
} TB_MemoryOrder;

typedef enum TB_ISelMode {
    // FastISel
    TB_ISEL_FAST,
    TB_ISEL_COMPLEX
} TB_ISelMode;

typedef enum TB_DataTypeEnum {
    // Integers, note void is an i0 and bool is an i1
    //   i(0-2047)
    TB_INT,
    // Floating point numbers
    //   f{32,64}
    TB_FLOAT,
    // Pointers
    //   ptr(0-2047)
    TB_PTR,
    // Tuples, these cannot be used in memory ops, just accessed via projections
    TB_TUPLE,
    // represents control flow as a kind of data
    TB_CONTROL,
} TB_DataTypeEnum;

typedef enum TB_FloatFormat {
    // IEEE 754 floats
    TB_FLT_32, TB_FLT_64
} TB_FloatFormat;

typedef union TB_DataType {
    struct {
        uint8_t type;
        // Only integers and floats can be wide.
        uint8_t width;
        // for integers it's the bitwidth
        uint16_t data;
    };
    uint32_t raw;
} TB_DataType;

// classify data types
#define TB_IS_VOID_TYPE(x)     ((x).type == TB_INT && (x).data == 0)
#define TB_IS_BOOL_TYPE(x)     ((x).type == TB_INT && (x).data == 1)
#define TB_IS_INTEGER_TYPE(x)  ((x).type == TB_INT)
#define TB_IS_FLOAT_TYPE(x)    ((x).type == TB_FLOAT)
#define TB_IS_POINTER_TYPE(x)  ((x).type == TB_PTR)

// accessors
#define TB_GET_INT_BITWIDTH(x) ((x).data)
#define TB_GET_FLOAT_FORMAT(x) ((x).data)
#define TB_GET_PTR_ADDRSPACE(x) ((x).data)

typedef enum TB_NodeTypeEnum {
    TB_NULL = 0,

    // Immediates
    TB_INTEGER_CONST,
    TB_FLOAT32_CONST,
    TB_FLOAT64_CONST,

    // only one per function
    TB_START, // fn()

    // regions represent the begining of BBs
    TB_REGION, // fn(preds: []region)

    // projection
    TB_PROJ,

    TB_CALL,  // normal call
    TB_SCALL, // system call

    // Managed ops
    TB_SAFEPOINT,

    // Memory operations
    TB_STORE, // fn(r: control, addr: data, src: data)
    TB_MEMCPY,
    TB_MEMSET,

    // Atomics
    TB_ATOMIC_TEST_AND_SET,
    TB_ATOMIC_CLEAR,

    TB_ATOMIC_LOAD,
    TB_ATOMIC_XCHG,
    TB_ATOMIC_ADD,
    TB_ATOMIC_SUB,
    TB_ATOMIC_AND,
    TB_ATOMIC_XOR,
    TB_ATOMIC_OR,

    TB_ATOMIC_CMPXCHG,
    TB_DEBUGBREAK,

    // Terminators
    TB_BRANCH,
    TB_RET,
    TB_UNREACHABLE,
    TB_TRAP,

    TB_POISON,

    // Load
    TB_LOAD,

    // Pointers
    TB_LOCAL,

    TB_GET_SYMBOL_ADDRESS,

    TB_MEMBER_ACCESS,
    TB_ARRAY_ACCESS,

    // Conversions
    TB_TRUNCATE,
    TB_FLOAT_EXT,
    TB_SIGN_EXT,
    TB_ZERO_EXT,
    TB_INT2PTR,
    TB_PTR2INT,
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
    TB_NOT,
    TB_NEG,

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
    // does full multiplication (64x64=128 and so on) returning
    // the low and high values in separate projections
    TB_MULPAIR,

    // PHI
    TB_PHI, // fn(r: region, x: []data)

    // variadic
    TB_VA_START,

    // x86 intrinsics
    TB_X86INTRIN_RDTSC,
    TB_X86INTRIN_LDMXCSR,
    TB_X86INTRIN_STMXCSR,
    TB_X86INTRIN_SQRT,
    TB_X86INTRIN_RSQRT,
} TB_NodeTypeEnum;
typedef uint8_t TB_NodeType;

typedef int TB_Label;

// just represents some region of bytes, usually in file parsing crap
typedef struct {
    size_t length;
    const uint8_t* data;
} TB_Slice;

// represents byte counts
typedef uint32_t TB_CharUnits;

typedef unsigned int TB_FileID;

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
typedef struct TB_Attrib            TB_Attrib;
typedef struct TB_DebugType         TB_DebugType;
typedef struct TB_ModuleSection     TB_ModuleSection;
typedef struct TB_FunctionPrototype TB_FunctionPrototype;

// Refers generically to objects within a module
//
// TB_Function, TB_Global, and TB_External are all subtypes of TB_Symbol
// and thus are safely allowed to cast into a symbol for operations.
typedef struct TB_Symbol {
    enum TB_SymbolTag {
        TB_SYMBOL_NONE,

        // symbol is dead now
        TB_SYMBOL_TOMBSTONE,

        TB_SYMBOL_EXTERNAL,
        TB_SYMBOL_GLOBAL,
        TB_SYMBOL_FUNCTION,

        TB_SYMBOL_MAX,
    } tag;

    // refers to the prev or next symbol with the same tag
    struct TB_Symbol* next;
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

typedef int TB_Reg;

typedef struct TB_Node TB_Node;
struct TB_Node {
    TB_NodeType type;
    TB_DataType dt;
    uint16_t input_count; // number of node inputs
    uint16_t extra_count; // number of bytes for extra operand data

    TB_Attrib* first_attrib;
    TB_Node** inputs;

    char extra[];
};

#define TB_KILL_NODE(n) ((n)->type = TB_NULL)

// These are the extra data in specific nodes
#define TB_NODE_GET_EXTRA(n)         ((void*) n->extra)
#define TB_NODE_GET_EXTRA_T(n, T)    ((T*) (n)->extra)
#define TB_NODE_SET_EXTRA(n, T, ...) (*((T*) (n)->extra) = (T){ __VA_ARGS__ })

// this represents switch (many targets), if (one target) and goto (only default) logic.
typedef struct { // TB_BRANCH
    // avoid empty structs with flexible members
    int64_t _;
    int64_t keys[];
} TB_NodeBranch;

typedef struct { // TB_PROJ
    int index;
} TB_NodeProj;

typedef struct { // TB_INT
    uint64_t num_words;
    uint64_t words[];
} TB_NodeInt;

typedef struct { // any compare operator
    TB_DataType cmp_dt;
} TB_NodeCompare;

typedef struct { // any integer binary operator
    TB_ArithmeticBehavior ab;
} TB_NodeBinopInt;

typedef struct { // TB_MULPAIR
    TB_Node *lo, *hi;
} TB_NodeMulPair;

typedef struct {
    TB_CharUnits align;
    bool is_volatile;
} TB_NodeMemAccess;

typedef struct {
    TB_CharUnits size, align;
} TB_NodeLocal;

typedef struct {
    TB_FileID file;
    int line;
} TB_NodeLine;

typedef struct {
    float value;
} TB_NodeFloat32;

typedef struct {
    double value;
} TB_NodeFloat64;

typedef struct {
    int64_t stride;
} TB_NodeArray;

typedef struct {
    int64_t offset;
} TB_NodeMember;

typedef struct {
    TB_Symbol* sym;
} TB_NodeSymbol;

typedef struct {
    TB_MemoryOrder order;
    TB_MemoryOrder order2;
} TB_NodeAtomic;

typedef struct {
    TB_FunctionPrototype* proto;
    TB_Node* projs[];
} TB_NodeCall;

typedef struct {
    uint32_t id;
} TB_NodeSafepoint;

typedef struct {
    TB_Node* end;
    const char* tag;

    size_t succ_count;
    TB_Node** succ;

    size_t proj_count;
    TB_Node** projs;
} TB_NodeRegion;

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

typedef struct {
    TB_Node* node; // type == TB_SAFEPOINT
    void* userdata;

    uint32_t ip;    // relative to the function body.
    uint32_t count; // same as node->input_count
    int32_t values[];
} TB_Safepoint;

// *******************************
// Public macros
// *******************************
#ifdef __cplusplus

#define TB_TYPE_TUPLE   TB_DataType{ { TB_TUPLE } }
#define TB_TYPE_CONTROL TB_DataType{ { TB_CONTROL } }
#define TB_TYPE_VOID    TB_DataType{ { TB_INT,   0, 0 } }
#define TB_TYPE_I8      TB_DataType{ { TB_INT,   0, 8 } }
#define TB_TYPE_I16     TB_DataType{ { TB_INT,   0, 16 } }
#define TB_TYPE_I32     TB_DataType{ { TB_INT,   0, 32 } }
#define TB_TYPE_I64     TB_DataType{ { TB_INT,   0, 64 } }
#define TB_TYPE_F32     TB_DataType{ { TB_FLOAT, 0, TB_FLT_32 } }
#define TB_TYPE_F64     TB_DataType{ { TB_FLOAT, 0, TB_FLT_64 } }
#define TB_TYPE_BOOL    TB_DataType{ { TB_INT,   0, 1 } }
#define TB_TYPE_PTR     TB_DataType{ { TB_PTR,   0, 0 } }

#define TB_TYPE_INTN(N) TB_DataType{ { TB_INT,   0, (N) } }
#define TB_TYPE_PTRN(N) TB_DataType{ { TB_PTR,   0, (N) } }

#else

#define TB_TYPE_TUPLE   (TB_DataType){ { TB_TUPLE } }
#define TB_TYPE_CONTROL (TB_DataType){ { TB_CONTROL } }
#define TB_TYPE_VOID    (TB_DataType){ { TB_INT,   0, 0 } }
#define TB_TYPE_I8      (TB_DataType){ { TB_INT,   0, 8 } }
#define TB_TYPE_I16     (TB_DataType){ { TB_INT,   0, 16 } }
#define TB_TYPE_I32     (TB_DataType){ { TB_INT,   0, 32 } }
#define TB_TYPE_I64     (TB_DataType){ { TB_INT,   0, 64 } }
#define TB_TYPE_F32     (TB_DataType){ { TB_FLOAT, 0, TB_FLT_32 } }
#define TB_TYPE_F64     (TB_DataType){ { TB_FLOAT, 0, TB_FLT_64 } }
#define TB_TYPE_BOOL    (TB_DataType){ { TB_INT,   0, 1 } }
#define TB_TYPE_PTR     (TB_DataType){ { TB_PTR,   0, 0 } }
#define TB_TYPE_INTN(N) (TB_DataType){ { TB_INT,  0, (N) } }
#define TB_TYPE_PTRN(N) (TB_DataType){ { TB_PTR,  0, (N) } }

#endif

typedef void (*TB_PrintCallback)(void* user_data, const char* fmt, ...);

// defined in common/arena.h
typedef struct TB_Arena TB_Arena;

// 0 for default
TB_API void tb_arena_create(TB_Arena* restrict arena, size_t chunk_size);
TB_API void tb_arena_destroy(TB_Arena* restrict arena);
TB_API bool tb_arena_is_empty(TB_Arena* arena);

////////////////////////////////
// Module management
////////////////////////////////
// Creates a module with the correct target and settings
TB_API TB_Module* tb_module_create(TB_Arch arch, TB_System sys, const TB_FeatureSet* features, bool is_jit);

// Creates a module but defaults on the architecture and system based on the host machine
TB_API TB_Module* tb_module_create_for_host(const TB_FeatureSet* features, bool is_jit);

TB_API size_t tb_module_get_function_count(TB_Module* m);

// Frees all resources for the TB_Module and it's functions, globals and
// compiled code.
TB_API void tb_module_destroy(TB_Module* m);

// When targetting windows & thread local storage, you'll need to bind a tls index
// which is usually just a global that the runtime support has initialized, if you
// dont and the tls_index is used, it'll crash
TB_API void tb_module_set_tls_index(TB_Module* m, ptrdiff_t len, const char* name);

// You don't need to manually call this unless you want to resolve locations before
// exporting.
TB_API void tb_module_layout_sections(TB_Module* m);

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

// returns NULL if no assembly was generated
TB_API TB_Assembly* tb_output_get_asm(TB_FunctionOutput* out);

// this is relative to the start of the function (the start of the prologue)
TB_API TB_Safepoint* tb_safepoint_get(TB_Function* f, uint32_t relative_ip);

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

TB_API TB_ExportBuffer tb_module_object_export(TB_Module* m, TB_DebugFormat debug_fmt);
TB_API bool tb_export_buffer_to_file(TB_ExportBuffer buffer, const char* path);
TB_API void tb_export_buffer_free(TB_ExportBuffer buffer);

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
TB_API TB_ExportBuffer tb_linker_export(TB_Linker* l);
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
// JIT compilation
////////////////////////////////
typedef struct TB_JITContext TB_JITContext;

// passing 0 to jit_heap_capacity will default to 4MiB
TB_API TB_JITContext* tb_module_begin_jit(TB_Module* m, size_t jit_heap_capacity);
TB_API void* tb_module_apply_function(TB_JITContext* jit, TB_Function* f);
TB_API void* tb_module_apply_global(TB_JITContext* jit, TB_Global* g);
// fixes page permissions, applies missing relocations
TB_API void tb_module_ready_jit(TB_JITContext* jit);
TB_API void tb_module_end_jit(TB_JITContext* jit);

#define TB_FOR_FUNCTIONS(it, module) for (TB_Function* it = tb_first_function(module); it != NULL; it = tb_next_function(it))
TB_API TB_Function* tb_first_function(TB_Module* m);
TB_API TB_Function* tb_next_function(TB_Function* f);

#define TB_FOR_EXTERNALS(it, module) for (TB_External* it = tb_first_external(module); it != NULL; it = tb_next_external(it))
TB_API TB_External* tb_first_external(TB_Module* m);
TB_API TB_External* tb_next_external(TB_External* e);

// this is used JIT scenarios to tell the compiler what externals map to
TB_API TB_ExternalType tb_extern_get_type(TB_External* e);
TB_Global* tb_extern_transmute(TB_External* e, TB_DebugType* dbg_type, TB_Linkage linkage);

TB_API TB_External* tb_extern_create(TB_Module* m, ptrdiff_t len, const char* name, TB_ExternalType type);
TB_API TB_FileID tb_file_create(TB_Module* m, const char* path);

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
TB_API TB_Node** tb_function_set_prototype_from_dbg(TB_Function* f, TB_DebugType* dbg, TB_Arena* arena, size_t* out_param_count);
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
TB_API void tb_global_set_storage(TB_Module* m, TB_ModuleSection* section, TB_Global* global, size_t size, size_t align, size_t max_objects);

// returns a buffer which the user can fill to then have represented in the initializer
TB_API void* tb_global_add_region(TB_Module* m, TB_Global* global, size_t offset, size_t size);

// places a relocation for a global at offset, the size of the relocation
// depends on the pointer size
TB_API void tb_global_add_symbol_reloc(TB_Module* m, TB_Global* global, size_t offset, const TB_Symbol* symbol);

TB_API TB_ModuleSection* tb_module_get_text(TB_Module* m);
TB_API TB_ModuleSection* tb_module_get_rdata(TB_Module* m);
TB_API TB_ModuleSection* tb_module_get_data(TB_Module* m);
TB_API TB_ModuleSection* tb_module_get_tls(TB_Module* m);

////////////////////////////////
// Function Attributes
////////////////////////////////
TB_API void tb_node_append_attrib(TB_Node* n, TB_Attrib* a);

// These are parts of a function that describe metadata for instructions
TB_API TB_Attrib* tb_function_attrib_variable(TB_Function* f, ptrdiff_t len, const char* name, TB_DebugType* type);
TB_API TB_Attrib* tb_function_attrib_scope(TB_Function* f, TB_Attrib* parent_scope);

////////////////////////////////
// Debug info Generation
////////////////////////////////
TB_API TB_DebugType* tb_debug_get_void(TB_Module* m);
TB_API TB_DebugType* tb_debug_get_bool(TB_Module* m);
TB_API TB_DebugType* tb_debug_get_integer(TB_Module* m, bool is_signed, int bits);
TB_API TB_DebugType* tb_debug_get_float(TB_Module* m, TB_FloatFormat fmt);
TB_API TB_DebugType* tb_debug_create_ptr(TB_Module* m, TB_DebugType* base);
TB_API TB_DebugType* tb_debug_create_array(TB_Module* m, TB_DebugType* base, size_t count);
TB_API TB_DebugType* tb_debug_create_alias(TB_Module* m, TB_DebugType* base, ptrdiff_t len, const char* tag);
TB_API TB_DebugType* tb_debug_create_struct(TB_Module* m, ptrdiff_t len, const char* tag);
TB_API TB_DebugType* tb_debug_create_union(TB_Module* m, ptrdiff_t len, const char* tag);
TB_API TB_DebugType* tb_debug_create_field(TB_Module* m, TB_DebugType* type, ptrdiff_t len, const char* name, TB_CharUnits offset);

// returns the array you need to fill with fields
TB_API TB_DebugType** tb_debug_record_begin(TB_DebugType* type, size_t count);
TB_API void tb_debug_record_end(TB_DebugType* type, TB_CharUnits size, TB_CharUnits align);

TB_API TB_DebugType* tb_debug_create_func(TB_Module* m, TB_CallingConv cc, size_t param_count, size_t return_count, bool has_varargs);

TB_API TB_DebugType* tb_debug_field_type(TB_DebugType* type);

TB_API size_t tb_debug_func_return_count(TB_DebugType* type);
TB_API size_t tb_debug_func_param_count(TB_DebugType* type);

// you'll need to fill these if you make a function
TB_API TB_DebugType** tb_debug_func_params(TB_DebugType* type);
TB_API TB_DebugType** tb_debug_func_returns(TB_DebugType* type);

////////////////////////////////
// IR access
////////////////////////////////
// it is an index to the input
#define TB_FOR_INPUT_IN_NODE(it, parent) for (TB_Node **it = parent->inputs, **__end = it + (parent)->input_count; it != __end; it++)

////////////////////////////////
// Symbols
////////////////////////////////
TB_API bool tb_symbol_is_comdat(const TB_Symbol* s);

// returns NULL if the tag doesn't match
TB_API TB_Function* tb_symbol_as_function(TB_Symbol* s);
TB_API TB_External* tb_symbol_as_external(TB_Symbol* s);
TB_API TB_Global* tb_symbol_as_global(TB_Symbol* s);

////////////////////////////////
// Function IR Generation
////////////////////////////////
TB_API void tb_get_data_type_size(TB_Module* mod, TB_DataType dt, size_t* size, size_t* align);

// the user_data is expected to be a valid FILE*
TB_API void tb_default_print_callback(void* user_data, const char* fmt, ...);

TB_API void tb_inst_set_location(TB_Function* f, TB_FileID file, int line);

// if section is NULL, default to .text
TB_API TB_Function* tb_function_create(TB_Module* m, ptrdiff_t len, const char* name, TB_Linkage linkage, TB_ComdatType comdat);

TB_API void* tb_function_get_jit_pos(TB_Function* f);

// if len is -1, it's null terminated
TB_API void tb_symbol_set_name(TB_Symbol* s, ptrdiff_t len, const char* name);

TB_API void tb_symbol_bind_ptr(TB_Symbol* s, void* ptr);
TB_API const char* tb_symbol_get_name(TB_Symbol* s);

// if arena is NULL, defaults to module arena which is freed on tb_free_thread_resources
TB_API void tb_function_set_prototype(TB_Function* f, TB_FunctionPrototype* p, TB_Arena* arena);
TB_API TB_FunctionPrototype* tb_function_get_prototype(TB_Function* f);

TB_API void tb_function_print(TB_Function* f, TB_PrintCallback callback, void* user_data);

TB_API void tb_inst_set_control(TB_Function* f, TB_Node* control);
TB_API TB_Node* tb_inst_get_control(TB_Function* f);

TB_API TB_Node* tb_inst_region(TB_Function* f);

// if len is -1, it's null terminated
TB_API void tb_inst_set_region_name(TB_Node* n, ptrdiff_t len, const char* name);

TB_API void tb_inst_unreachable(TB_Function* f);
TB_API void tb_inst_debugbreak(TB_Function* f);
TB_API void tb_inst_trap(TB_Function* f);
TB_API TB_Node* tb_inst_poison(TB_Function* f);

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

TB_API TB_Node* tb_inst_bool(TB_Function* f, bool imm);
TB_API TB_Node* tb_inst_sint(TB_Function* f, TB_DataType dt, int64_t imm);
TB_API TB_Node* tb_inst_uint(TB_Function* f, TB_DataType dt, uint64_t imm);
TB_API TB_Node* tb_inst_float32(TB_Function* f, float imm);
TB_API TB_Node* tb_inst_float64(TB_Function* f, double imm);
TB_API TB_Node* tb_inst_cstring(TB_Function* f, const char* str);
TB_API TB_Node* tb_inst_string(TB_Function* f, size_t len, const char* str);

// write 'val' over 'count' bytes on 'dst'
TB_API void tb_inst_memset(TB_Function* f, TB_Node* dst, TB_Node* val, TB_Node* count, TB_CharUnits align, bool is_volatile);

// zero 'count' bytes on 'dst'
TB_API void tb_inst_memzero(TB_Function* f, TB_Node* dst, TB_Node* count, TB_CharUnits align, bool is_volatile);

// performs a copy of 'count' elements from one memory location to another
// both locations cannot overlap.
TB_API void tb_inst_memcpy(TB_Function* f, TB_Node* dst, TB_Node* src, TB_Node* count, TB_CharUnits align, bool is_volatile);

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
TB_API TB_Node* tb_inst_atomic_sub(TB_Function* f, TB_Node* addr, TB_Node* src, TB_MemoryOrder order);
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

// x86 Intrinsics
TB_API TB_Node* tb_inst_x86_rdtsc(TB_Function* f);
TB_API TB_Node* tb_inst_x86_ldmxcsr(TB_Function* f, TB_Node* a);
TB_API TB_Node* tb_inst_x86_stmxcsr(TB_Function* f);
TB_API TB_Node* tb_inst_x86_sqrt(TB_Function* f, TB_Node* a);
TB_API TB_Node* tb_inst_x86_rsqrt(TB_Function* f, TB_Node* a);

// Control flow
TB_API TB_Node* tb_inst_syscall(TB_Function* f, TB_DataType dt, TB_Node* syscall_num, size_t param_count, TB_Node** params);
TB_API TB_MultiOutput tb_inst_call(TB_Function* f, TB_FunctionPrototype* proto, TB_Node* target, size_t param_count, TB_Node** params);

// Managed
TB_API TB_Node* tb_inst_safepoint(TB_Function* f, size_t param_count, TB_Node** params);

TB_API TB_Node* tb_inst_incomplete_phi(TB_Function* f, TB_DataType dt, TB_Node* region, size_t preds);
TB_API bool tb_inst_add_phi_operand(TB_Function* f, TB_Node* phi, TB_Node* region, TB_Node* val);

TB_API TB_Node* tb_inst_phi2(TB_Function* f, TB_Node* region, TB_Node* a, TB_Node* b);
TB_API void tb_inst_goto(TB_Function* f, TB_Node* target);
TB_API void tb_inst_if(TB_Function* f, TB_Node* cond, TB_Node* true_case, TB_Node* false_case);
TB_API void tb_inst_branch(TB_Function* f, TB_DataType dt, TB_Node* key, TB_Node* default_case, size_t entry_count, const TB_SwitchEntry* keys);

TB_API void tb_inst_ret(TB_Function* f, size_t count, TB_Node** values);

////////////////////////////////
// Passes
////////////////////////////////
// Function analysis, optimizations, and codegen are all part of this
typedef struct TB_Passes TB_Passes;

// the arena is used to allocate the nodes while passes are being done.
TB_API TB_Passes* tb_pass_enter(TB_Function* f, TB_Arena* arena);
TB_API void tb_pass_exit(TB_Passes* opt);

// transformation passes:
//   peephole: runs most simple reductions on the code,
//     should be run after any bigger passes (it's incremental
//     so it's not that bad)
//
//   mem2reg: lowers TB_LOCALs into SSA values, this makes more
//     data flow analysis possible on the code and allows to codegen
//     to place variables into registers.
//
//   loop: NOT READY
//
TB_API bool tb_pass_peephole(TB_Passes* opt);
TB_API bool tb_pass_mem2reg(TB_Passes* opt);
TB_API bool tb_pass_loop(TB_Passes* opt);

// analysis
//   print: prints IR in a flattened text form.
TB_API bool tb_pass_print(TB_Passes* opt);

// codegen
TB_API TB_FunctionOutput* tb_pass_codegen(TB_Passes* opt, bool emit_asm);

TB_API void tb_pass_kill_node(TB_Passes* opt, TB_Node* n);
TB_API bool tb_pass_mark(TB_Passes* opt, TB_Node* n);
TB_API void tb_pass_mark_users(TB_Passes* opt, TB_Node* n);

////////////////////////////////
// IR access
////////////////////////////////
TB_API const char* tb_node_get_name(TB_Node* n);

TB_API TB_Node* tb_get_parent_region(TB_Node* n);
TB_API bool tb_node_is_constant_non_zero(TB_Node* n);
TB_API bool tb_node_is_constant_zero(TB_Node* n);

#endif /* TB_CORE_H */
