// This is the runtime code required by the compiler
// IMPORTANT NOTE(bill): Do not change the order of any of this data
// The compiler relies upon this _exact_ order
//
// Naming Conventions:
// In general, Ada_Case for types and snake_case for values
//
// Package Name:       snake_case (but prefer single word)
// Import Name:        snake_case (but prefer single word)
// Types:              Ada_Case
// Enum Values:        Ada_Case
// Procedures:         snake_case
// Local Variables:    snake_case
// Constant Variables: SCREAMING_SNAKE_CASE
//
// IMPORTANT NOTE(bill): `type_info_of` cannot be used within a
// #shared_global_scope due to  the internals of the compiler.
// This could change at a later date if the all these data structures are
// implemented within the compiler rather than in this "preload" file
//
#+no-instrumentation
package runtime

import "base:intrinsics"

// NOTE(bill): This must match the compiler's
Calling_Convention :: enum u8 {
	Invalid     = 0,
	Odin        = 1,
	Contextless = 2,
	CDecl       = 3,
	Std_Call    = 4,
	Fast_Call   = 5,

	None        = 6,
	Naked       = 7,

	_           = 8, // reserved

	Win64       = 9,
	SysV        = 10,
}

Type_Info_Enum_Value :: distinct i64

Platform_Endianness :: enum u8 {
	Platform = 0,
	Little   = 1,
	Big      = 2,
}

// Procedure type to test whether two values of the same type are equal
Equal_Proc :: distinct proc "contextless" (rawptr, rawptr) -> bool
// Procedure type to hash a value, default seed value is 0
Hasher_Proc :: distinct proc "contextless" (data: rawptr, seed: uintptr = 0) -> uintptr

Type_Info_Struct_Soa_Kind :: enum u8 {
	None    = 0,
	Fixed   = 1,
	Slice   = 2,
	Dynamic = 3,
}

// Variant Types
Type_Info_Named :: struct {
	name: string,
	base: ^Type_Info,
	pkg:  string,
	loc:  ^Source_Code_Location,
}
Type_Info_Integer    :: struct {signed: bool, endianness: Platform_Endianness}
Type_Info_Rune       :: struct {}
Type_Info_Float      :: struct {endianness: Platform_Endianness}
Type_Info_Complex    :: struct {}
Type_Info_Quaternion :: struct {}
Type_Info_String     :: struct {is_cstring: bool}
Type_Info_Boolean    :: struct {}
Type_Info_Any        :: struct {}
Type_Info_Type_Id    :: struct {}
Type_Info_Pointer :: struct {
	elem: ^Type_Info, // nil -> rawptr
}
Type_Info_Multi_Pointer :: struct {
	elem: ^Type_Info,
}
Type_Info_Procedure :: struct {
	params:     ^Type_Info, // Type_Info_Parameters
	results:    ^Type_Info, // Type_Info_Parameters
	variadic:   bool,
	convention: Calling_Convention,
}
Type_Info_Array :: struct {
	elem:      ^Type_Info,
	elem_size: int,
	count:     int,
}
Type_Info_Enumerated_Array :: struct {
	elem:      ^Type_Info,
	index:     ^Type_Info,
	elem_size: int,
	count:     int,
	min_value: Type_Info_Enum_Value,
	max_value: Type_Info_Enum_Value,
	is_sparse: bool,
}
Type_Info_Dynamic_Array :: struct {elem: ^Type_Info, elem_size: int}
Type_Info_Slice         :: struct {elem: ^Type_Info, elem_size: int}

Type_Info_Parameters :: struct { // Only used for procedures parameters and results
	types:        []^Type_Info,
	names:        []string,
}
Type_Info_Tuple :: Type_Info_Parameters // Will be removed eventually

Type_Info_Struct_Flags :: distinct bit_set[Type_Info_Struct_Flag; u8]
Type_Info_Struct_Flag :: enum u8 {
	packed    = 0,
	raw_union = 1,
	no_copy   = 2,
	align     = 3,
}

Type_Info_Struct :: struct {
	// Slice these with `field_count`
	types:   [^]^Type_Info `fmt:"v,field_count"`,
	names:   [^]string     `fmt:"v,field_count"`,
	offsets: [^]uintptr    `fmt:"v,field_count"`,
	usings:  [^]bool       `fmt:"v,field_count"`,
	tags:    [^]string     `fmt:"v,field_count"`,

	field_count: i32,

	flags: Type_Info_Struct_Flags,

	// These are only set iff this structure is an SOA structure
	soa_kind:      Type_Info_Struct_Soa_Kind,
	soa_len:       i32,
	soa_base_type: ^Type_Info,

	equal: Equal_Proc, // set only when the struct has .Comparable set but does not have .Simple_Compare set
}
Type_Info_Union :: struct {
	variants:     []^Type_Info,
	tag_offset:   uintptr,
	tag_type:     ^Type_Info,

	equal: Equal_Proc, // set only when the struct has .Comparable set but does not have .Simple_Compare set

	custom_align: bool,
	no_nil:       bool,
	shared_nil:   bool,
}
Type_Info_Enum :: struct {
	base:   ^Type_Info,
	names:  []string,
	values: []Type_Info_Enum_Value,
}
Type_Info_Map :: struct {
	key:      ^Type_Info,
	value:    ^Type_Info,
	map_info: ^Map_Info,
}
Type_Info_Bit_Set :: struct {
	elem:       ^Type_Info,
	underlying: ^Type_Info, // Possibly nil
	lower:      i64,
	upper:      i64,
}
Type_Info_Simd_Vector :: struct {
	elem:       ^Type_Info,
	elem_size:  int,
	count:      int,
}
Type_Info_Matrix :: struct {
	elem:         ^Type_Info,
	elem_size:    int,
	elem_stride:  int, // elem_stride >= row_count
	row_count:    int,
	column_count: int,
	// Total element count = column_count * elem_stride
	layout: enum u8 {
		Column_Major, // array of column vectors
		Row_Major,    // array of row vectors
	},
}
Type_Info_Soa_Pointer :: struct {
	elem: ^Type_Info,
}
Type_Info_Bit_Field :: struct {
	backing_type: ^Type_Info,
	names:        [^]string     `fmt:"v,field_count"`,
	types:        [^]^Type_Info `fmt:"v,field_count"`,
	bit_sizes:    [^]uintptr    `fmt:"v,field_count"`,
	bit_offsets:  [^]uintptr    `fmt:"v,field_count"`,
	tags:         [^]string     `fmt:"v,field_count"`,
	field_count:  int,
}

Type_Info_Flag :: enum u8 {
	Comparable     = 0,
	Simple_Compare = 1,
}
Type_Info_Flags :: distinct bit_set[Type_Info_Flag; u32]

Type_Info :: struct {
	size:  int,
	align: int,
	flags: Type_Info_Flags,
	id:    typeid,

	variant: union {
		Type_Info_Named,
		Type_Info_Integer,
		Type_Info_Rune,
		Type_Info_Float,
		Type_Info_Complex,
		Type_Info_Quaternion,
		Type_Info_String,
		Type_Info_Boolean,
		Type_Info_Any,
		Type_Info_Type_Id,
		Type_Info_Pointer,
		Type_Info_Multi_Pointer,
		Type_Info_Procedure,
		Type_Info_Array,
		Type_Info_Enumerated_Array,
		Type_Info_Dynamic_Array,
		Type_Info_Slice,
		Type_Info_Parameters,
		Type_Info_Struct,
		Type_Info_Union,
		Type_Info_Enum,
		Type_Info_Map,
		Type_Info_Bit_Set,
		Type_Info_Simd_Vector,
		Type_Info_Matrix,
		Type_Info_Soa_Pointer,
		Type_Info_Bit_Field,
	},
}

// NOTE(bill): only the ones that are needed (not all types)
// This will be set by the compiler
type_table: []^Type_Info

args__: []cstring

when ODIN_OS == .Windows {
	// NOTE(Jeroen): If we're a Windows DLL, fwdReason will be populated.
	// This tells a DLL if it's first loaded, about to be unloaded, or a thread is joining/exiting.

	DLL_Forward_Reason :: enum u32 {
		Process_Detach = 0, // About to unload DLL
		Process_Attach = 1, // Entry point
		Thread_Attach  = 2,
		Thread_Detach  = 3,
	}
	dll_forward_reason: DLL_Forward_Reason

	dll_instance: rawptr
}

// IMPORTANT NOTE(bill): Must be in this order (as the compiler relies upon it)


Source_Code_Location :: struct {
	file_path:    string,
	line, column: i32,
	procedure:    string,
}

/*
	Used by the built-in directory `#load_directory(path: string) -> []Load_Directory_File`
*/
Load_Directory_File :: struct {
	name: string,
	data: []byte, // immutable data
}

Assertion_Failure_Proc :: #type proc(prefix, message: string, loc: Source_Code_Location) -> !

// Allocation Stuff
Allocator_Mode :: enum byte {
	Alloc,
	Free,
	Free_All,
	Resize,
	Query_Features,
	Query_Info,
	Alloc_Non_Zeroed,
	Resize_Non_Zeroed,
}

Allocator_Mode_Set :: distinct bit_set[Allocator_Mode]

Allocator_Query_Info :: struct {
	pointer:   rawptr,
	size:      Maybe(int),
	alignment: Maybe(int),
}

Allocator_Error :: enum byte {
	None                 = 0,
	Out_Of_Memory        = 1,
	Invalid_Pointer      = 2,
	Invalid_Argument     = 3,
	Mode_Not_Implemented = 4,
}

Allocator_Proc :: #type proc(allocator_data: rawptr, mode: Allocator_Mode,
                             size, alignment: int,
                             old_memory: rawptr, old_size: int,
                             location: Source_Code_Location = #caller_location) -> ([]byte, Allocator_Error)
Allocator :: struct {
	procedure: Allocator_Proc,
	data:      rawptr,
}

Byte     :: 1
Kilobyte :: 1024 * Byte
Megabyte :: 1024 * Kilobyte
Gigabyte :: 1024 * Megabyte
Terabyte :: 1024 * Gigabyte
Petabyte :: 1024 * Terabyte
Exabyte  :: 1024 * Petabyte

// Logging stuff

Logger_Level :: enum uint {
	Debug   = 0,
	Info    = 10,
	Warning = 20,
	Error   = 30,
	Fatal   = 40,
}

Logger_Option :: enum {
	Level,
	Date,
	Time,
	Short_File_Path,
	Long_File_Path,
	Line,
	Procedure,
	Terminal_Color,
	Thread_Id,
}

Logger_Options :: bit_set[Logger_Option]
Logger_Proc :: #type proc(data: rawptr, level: Logger_Level, text: string, options: Logger_Options, location := #caller_location)

Logger :: struct {
	procedure:    Logger_Proc,
	data:         rawptr,
	lowest_level: Logger_Level,
	options:      Logger_Options,
}


Random_Generator_Mode :: enum {
	Read,
	Reset,
	Query_Info,
}

Random_Generator_Query_Info_Flag :: enum u32 {
	Cryptographic,
	Uniform,
	External_Entropy,
	Resettable,
}
Random_Generator_Query_Info :: distinct bit_set[Random_Generator_Query_Info_Flag; u32]

Random_Generator_Proc :: #type proc(data: rawptr, mode: Random_Generator_Mode, p: []byte)

Random_Generator :: struct {
	procedure: Random_Generator_Proc,
	data:      rawptr,
}

Context :: struct {
	allocator:              Allocator,
	temp_allocator:         Allocator,
	assertion_failure_proc: Assertion_Failure_Proc,
	logger:                 Logger,
	random_generator:       Random_Generator,

	user_ptr:   rawptr,
	user_index: int,

	// Internal use only
	_internal: rawptr,
}


Raw_String :: struct {
	data: [^]byte,
	len:  int,
}

Raw_Slice :: struct {
	data: rawptr,
	len:  int,
}

Raw_Dynamic_Array :: struct {
	data:      rawptr,
	len:       int,
	cap:       int,
	allocator: Allocator,
}

// The raw, type-erased representation of a map.
//
// 32-bytes on 64-bit
// 16-bytes on 32-bit
Raw_Map :: struct {
	// A single allocation spanning all keys, values, and hashes.
	// {
	//   k: Map_Cell(K) * (capacity / ks_per_cell)
	//   v: Map_Cell(V) * (capacity / vs_per_cell)
	//   h: Map_Cell(H) * (capacity / hs_per_cell)
	// }
	//
	// The data is allocated assuming 64-byte alignment, meaning the address is
	// always a multiple of 64. This means we have 6 bits of zeros in the pointer
	// to store the capacity. We can store a value as large as 2^6-1 or 63 in
	// there. This conveniently is the maximum log2 capacity we can have for a map
	// as Odin uses signed integers to represent capacity.
	//
	// Since the hashes are backed by Map_Hash, which is just a 64-bit unsigned
	// integer, the cell structure for hashes is unnecessary because 64/8 is 8 and
	// requires no padding, meaning it can be indexed as a regular array of
	// Map_Hash directly, though for consistency sake it's written as if it were
	// an array of Map_Cell(Map_Hash).
	data:      uintptr,   // 8-bytes on 64-bits, 4-bytes on 32-bits
	len:       uintptr,   // 8-bytes on 64-bits, 4-bytes on 32-bits
	allocator: Allocator, // 16-bytes on 64-bits, 8-bytes on 32-bits
}

Raw_Any :: struct {
	data: rawptr,
	id:   typeid,
}
#assert(size_of(Raw_Any) == size_of(any))

Raw_Cstring :: struct {
	data: [^]byte,
}
#assert(size_of(Raw_Cstring) == size_of(cstring))

Raw_Soa_Pointer :: struct {
	data:  rawptr,
	index: int,
}

Raw_Complex32     :: struct {real, imag: f16}
Raw_Complex64     :: struct {real, imag: f32}
Raw_Complex128    :: struct {real, imag: f64}
Raw_Quaternion64  :: struct {imag, jmag, kmag: f16, real: f16}
Raw_Quaternion128 :: struct {imag, jmag, kmag: f32, real: f32}
Raw_Quaternion256 :: struct {imag, jmag, kmag: f64, real: f64}
Raw_Quaternion64_Vector_Scalar  :: struct {vector: [3]f16, scalar: f16}
Raw_Quaternion128_Vector_Scalar :: struct {vector: [3]f32, scalar: f32}
Raw_Quaternion256_Vector_Scalar :: struct {vector: [3]f64, scalar: f64}


/*
	// Defined internally by the compiler
	Odin_OS_Type :: enum int {
		Unknown,
		Windows,
		Darwin,
		Linux,
		Essence,
		FreeBSD,
		OpenBSD,
		NetBSD,
		Haiku,
		WASI,
		JS,
		Orca,
		Freestanding,
	}
*/
Odin_OS_Type :: type_of(ODIN_OS)

/*
	// Defined internally by the compiler
	Odin_Arch_Type :: enum int {
		Unknown,
		amd64,
		i386,
		arm32,
		arm64,
		wasm32,
		wasm64p32,
		riscv64,
	}
*/
Odin_Arch_Type :: type_of(ODIN_ARCH)

Odin_Arch_Types :: bit_set[Odin_Arch_Type]

ALL_ODIN_ARCH_TYPES :: Odin_Arch_Types{
	.amd64,
	.i386,
	.arm32,
	.arm64,
	.wasm32,
	.wasm64p32,
	.riscv64,
}

/*
	// Defined internally by the compiler
	Odin_Build_Mode_Type :: enum int {
		Executable,
		Dynamic,
		Static,
		Object,
		Assembly,
		LLVM_IR,
	}
*/
Odin_Build_Mode_Type :: type_of(ODIN_BUILD_MODE)

/*
	// Defined internally by the compiler
	Odin_Endian_Type :: enum int {
		Unknown,
		Little,
		Big,
	}
*/
Odin_Endian_Type :: type_of(ODIN_ENDIAN)

Odin_OS_Types :: bit_set[Odin_OS_Type]

ALL_ODIN_OS_TYPES :: Odin_OS_Types{
	.Windows,
	.Darwin,
	.Linux,
	.Essence,
	.FreeBSD,
	.OpenBSD,
	.NetBSD,
	.Haiku,
	.WASI,
	.JS,
	.Orca,
	.Freestanding,
}

/*
	// Defined internally by the compiler
	Odin_Platform_Subtarget_Type :: enum int {
		Default,
		iOS,
	}
*/
Odin_Platform_Subtarget_Type :: type_of(ODIN_PLATFORM_SUBTARGET)

/*
	// Defined internally by the compiler
	Odin_Sanitizer_Flag :: enum u32 {
		Address = 0,
		Memory  = 1,
		Thread  = 2,
	}
	Odin_Sanitizer_Flags :: distinct bit_set[Odin_Sanitizer_Flag; u32]

	ODIN_SANITIZER_FLAGS // is a constant
*/
Odin_Sanitizer_Flags :: type_of(ODIN_SANITIZER_FLAGS)

/*
	// Defined internally by the compiler
	Odin_Optimization_Mode :: enum int {
		None       = -1,
		Minimal    =  0,
		Size       =  1,
		Speed      =  2,
		Aggressive =  3,
	}

	ODIN_OPTIMIZATION_MODE // is a constant
*/
Odin_Optimization_Mode :: type_of(ODIN_OPTIMIZATION_MODE)

/////////////////////////////
// Init Startup Procedures //
/////////////////////////////

// IMPORTANT NOTE(bill): Do not call this unless you want to explicitly set up the entry point and how it gets called
// This is probably only useful for freestanding targets
foreign {
	@(link_name="__$startup_runtime")
	_startup_runtime :: proc "odin" () ---
	@(link_name="__$cleanup_runtime")
	_cleanup_runtime :: proc "odin" () ---
}

_cleanup_runtime_contextless :: proc "contextless" () {
	context = default_context()
	_cleanup_runtime()
}


/////////////////////////////
/////////////////////////////
/////////////////////////////


type_info_base :: proc "contextless" (info: ^Type_Info) -> ^Type_Info {
	if info == nil {
		return nil
	}

	base := info
	loop: for {
		#partial switch i in base.variant {
		case Type_Info_Named: base = i.base
		case: break loop
		}
	}
	return base
}


type_info_core :: proc "contextless" (info: ^Type_Info) -> ^Type_Info {
	if info == nil {
		return nil
	}

	base := info
	loop: for {
		#partial switch i in base.variant {
		case Type_Info_Named:     base = i.base
		case Type_Info_Enum:      base = i.base
		case Type_Info_Bit_Field: base = i.backing_type
		case: break loop
		}
	}
	return base
}
type_info_base_without_enum :: type_info_core

__type_info_of :: proc "contextless" (id: typeid) -> ^Type_Info #no_bounds_check {
	n := u64(len(type_table))
	i := transmute(u64)id % n
	for _ in 0..<n {
		ptr := type_table[i]
		if ptr != nil && ptr.id == id {
			return ptr
		}
		i = i+1 if i+1 < n else 0
	}
	return type_table[0]
}

when !ODIN_NO_RTTI {
	typeid_base :: proc "contextless" (id: typeid) -> typeid {
		ti := type_info_of(id)
		ti = type_info_base(ti)
		return ti.id
	}
	typeid_core :: proc "contextless" (id: typeid) -> typeid {
		ti := type_info_core(type_info_of(id))
		return ti.id
	}
	typeid_base_without_enum :: typeid_core
}



debug_trap         :: intrinsics.debug_trap
trap               :: intrinsics.trap
read_cycle_counter :: intrinsics.read_cycle_counter



default_logger_proc :: proc(data: rawptr, level: Logger_Level, text: string, options: Logger_Options, location := #caller_location) {
	// Nothing
}

default_logger :: proc() -> Logger {
	return Logger{default_logger_proc, nil, Logger_Level.Debug, nil}
}


default_context :: proc "contextless" () -> Context {
	c: Context
	__init_context(&c)
	return c
}

@private
__init_context_from_ptr :: proc "contextless" (c: ^Context, other: ^Context) {
	if c == nil {
		return
	}
	c^ = other^
	__init_context(c)
}

@private
__init_context :: proc "contextless" (c: ^Context) {
	if c == nil {
		return
	}

	// NOTE(bill): Do not initialize these procedures with a call as they are not defined with the "contextless" calling convention
	c.allocator.procedure = default_allocator_proc
	c.allocator.data = nil

	c.temp_allocator.procedure = default_temp_allocator_proc
	when !NO_DEFAULT_TEMP_ALLOCATOR {
		c.temp_allocator.data = &global_default_temp_allocator_data
	}
	
	when !ODIN_DISABLE_ASSERT {
		c.assertion_failure_proc = default_assertion_failure_proc
	}

	c.logger.procedure = default_logger_proc
	c.logger.data = nil

	c.random_generator.procedure = default_random_generator_proc
	c.random_generator.data = nil
}

default_assertion_failure_proc :: proc(prefix, message: string, loc: Source_Code_Location) -> ! {
	default_assertion_contextless_failure_proc(prefix, message, loc)
}

default_assertion_contextless_failure_proc :: proc "contextless" (prefix, message: string, loc: Source_Code_Location) -> ! {
	when ODIN_OS == .Freestanding {
		// Do nothing
	} else {
		when ODIN_OS != .Orca && !ODIN_DISABLE_ASSERT {
			print_caller_location(loc)
			print_string(" ")
		}
		print_string(prefix)
		if len(message) > 0 {
			print_string(": ")
			print_string(message)
		}

		when ODIN_OS == .Orca {
			assert_fail(
				cstring(raw_data(loc.file_path)),
				cstring(raw_data(loc.procedure)),
				loc.line,
				"",
				cstring(raw_data(orca_stderr_buffer[:orca_stderr_buffer_idx])),
			)
		} else {
			print_byte('\n')
		}
	}
	trap()
}
