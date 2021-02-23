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
package runtime

// NOTE(bill): This must match the compiler's
Calling_Convention :: enum u8 {
	Invalid     = 0,
	Odin        = 1,
	Contextless = 2,
	CDecl       = 3,
	Std_Call    = 4,
	Fast_Call   = 5,

	None        = 6,
}

Type_Info_Enum_Value :: distinct i64;

Platform_Endianness :: enum u8 {
	Platform = 0,
	Little   = 1,
	Big      = 2,
}

// Procedure type to test whether two values of the same type are equal
Equal_Proc :: distinct proc "contextless" (rawptr, rawptr) -> bool;
// Procedure type to hash a value, default seed value is 0
Hasher_Proc :: distinct proc "contextless" (data: rawptr, seed: uintptr = 0) -> uintptr;

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
	loc:  Source_Code_Location,
};
Type_Info_Integer    :: struct {signed: bool, endianness: Platform_Endianness};
Type_Info_Rune       :: struct {};
Type_Info_Float      :: struct {endianness: Platform_Endianness};
Type_Info_Complex    :: struct {};
Type_Info_Quaternion :: struct {};
Type_Info_String     :: struct {is_cstring: bool};
Type_Info_Boolean    :: struct {};
Type_Info_Any        :: struct {};
Type_Info_Type_Id    :: struct {};
Type_Info_Pointer :: struct {
	elem: ^Type_Info, // nil -> rawptr
};
Type_Info_Procedure :: struct {
	params:     ^Type_Info, // Type_Info_Tuple
	results:    ^Type_Info, // Type_Info_Tuple
	variadic:   bool,
	convention: Calling_Convention,
};
Type_Info_Array :: struct {
	elem:      ^Type_Info,
	elem_size: int,
	count:     int,
};
Type_Info_Enumerated_Array :: struct {
	elem:      ^Type_Info,
	index:     ^Type_Info,
	elem_size: int,
	count:     int,
	min_value: Type_Info_Enum_Value,
	max_value: Type_Info_Enum_Value,
};
Type_Info_Dynamic_Array :: struct {elem: ^Type_Info, elem_size: int};
Type_Info_Slice         :: struct {elem: ^Type_Info, elem_size: int};
Type_Info_Tuple :: struct { // Only used for procedures parameters and results
	types:        []^Type_Info,
	names:        []string,
};

Type_Info_Struct :: struct {
	types:        []^Type_Info,
	names:        []string,
	offsets:      []uintptr,
	usings:       []bool,
	tags:         []string,
	is_packed:    bool,
	is_raw_union: bool,
	custom_align: bool,

	equal: Equal_Proc, // set only when the struct has .Comparable set but does not have .Simple_Compare set

	// These are only set iff this structure is an SOA structure
	soa_kind:      Type_Info_Struct_Soa_Kind,
	soa_base_type: ^Type_Info,
	soa_len:       int,
};
Type_Info_Union :: struct {
	variants:     []^Type_Info,
	tag_offset:   uintptr,
	tag_type:     ^Type_Info,
	custom_align: bool,
	no_nil:       bool,
	maybe:        bool,
};
Type_Info_Enum :: struct {
	base:      ^Type_Info,
	names:     []string,
	values:    []Type_Info_Enum_Value,
};
Type_Info_Map :: struct {
	key:              ^Type_Info,
	value:            ^Type_Info,
	generated_struct: ^Type_Info,
	key_equal:        Equal_Proc,
	key_hasher:       Hasher_Proc,
};
Type_Info_Bit_Set :: struct {
	elem:       ^Type_Info,
	underlying: ^Type_Info, // Possibly nil
	lower:      i64,
	upper:      i64,
};
Type_Info_Simd_Vector :: struct {
	elem:       ^Type_Info,
	elem_size:  int,
	count:      int,
	is_x86_mmx: bool,
};
Type_Info_Relative_Pointer :: struct {
	pointer:      ^Type_Info,
	base_integer: ^Type_Info,
};
Type_Info_Relative_Slice :: struct {
	slice:        ^Type_Info,
	base_integer: ^Type_Info,
};

Type_Info_Flag :: enum u8 {
	Comparable     = 0,
	Simple_Compare = 1,
};
Type_Info_Flags :: distinct bit_set[Type_Info_Flag; u32];

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
		Type_Info_Procedure,
		Type_Info_Array,
		Type_Info_Enumerated_Array,
		Type_Info_Dynamic_Array,
		Type_Info_Slice,
		Type_Info_Tuple,
		Type_Info_Struct,
		Type_Info_Union,
		Type_Info_Enum,
		Type_Info_Map,
		Type_Info_Bit_Set,
		Type_Info_Simd_Vector,
		Type_Info_Relative_Pointer,
		Type_Info_Relative_Slice,
	},
}

// NOTE(bill): This must match the compiler's
Typeid_Kind :: enum u8 {
	Invalid,
	Integer,
	Rune,
	Float,
	Complex,
	Quaternion,
	String,
	Boolean,
	Any,
	Type_Id,
	Pointer,
	Procedure,
	Array,
	Enumerated_Array,
	Dynamic_Array,
	Slice,
	Tuple,
	Struct,
	Union,
	Enum,
	Map,
	Bit_Set,
	Simd_Vector,
	Relative_Pointer,
	Relative_Slice,
}
#assert(len(Typeid_Kind) < 32);

// Typeid_Bit_Field :: bit_field #align align_of(uintptr) {
// 	index:    8*size_of(uintptr) - 8,
// 	kind:     5, // Typeid_Kind
// 	named:    1,
// 	special:  1, // signed, cstring, etc
// 	reserved: 1,
// }
// #assert(size_of(Typeid_Bit_Field) == size_of(uintptr));

// NOTE(bill): only the ones that are needed (not all types)
// This will be set by the compiler
type_table: []Type_Info;

args__: []cstring;

// IMPORTANT NOTE(bill): Must be in this order (as the compiler relies upon it)


Source_Code_Location :: struct {
	file_path:    string,
	line, column: int,
	procedure:    string,
}

Assertion_Failure_Proc :: #type proc(prefix, message: string, loc: Source_Code_Location);


// Allocation Stuff
Allocator_Mode :: enum byte {
	Alloc,
	Free,
	Free_All,
	Resize,
	Query_Features,
	Query_Info,
}

Allocator_Mode_Set :: distinct bit_set[Allocator_Mode];

Allocator_Query_Info :: struct {
	pointer:   rawptr,
	size:      Maybe(int),
	alignment: Maybe(int),
}

Allocator_Proc :: #type proc(allocator_data: rawptr, mode: Allocator_Mode,
                             size, alignment: int,
                             old_memory: rawptr, old_size: int, flags: u64 = 0, location: Source_Code_Location = #caller_location) -> rawptr;
Allocator :: struct {
	procedure: Allocator_Proc,
	data:      rawptr,
}

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

Logger_Options :: bit_set[Logger_Option];
Logger_Proc :: #type proc(data: rawptr, level: Logger_Level, text: string, options: Logger_Options, location := #caller_location);

Logger :: struct {
	procedure:    Logger_Proc,
	data:         rawptr,
	lowest_level: Logger_Level,
	options:      Logger_Options,
}

Context :: struct {
	allocator:              Allocator,
	temp_allocator:         Allocator,
	assertion_failure_proc: Assertion_Failure_Proc,
	logger:                 Logger,

	thread_id:  int,

	user_data:  any,
	user_ptr:   rawptr,
	user_index: int,

	// Internal use only
	_internal: rawptr,
}


Raw_String :: struct {
	data: ^byte,
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

Raw_Map :: struct {
	hashes:  []int,
	entries: Raw_Dynamic_Array,
}


/////////////////////////////
// Init Startup Procedures //
/////////////////////////////

// IMPORTANT NOTE(bill): Do not call this unless you want to explicitly set up the entry point and how it gets called
// This is probably only useful for freestanding targets
foreign {
	@(link_name="__$startup_runtime")
	_startup_runtime :: proc "contextless" () ---
}


/////////////////////////////
/////////////////////////////
/////////////////////////////


type_info_base :: proc "contextless" (info: ^Type_Info) -> ^Type_Info {
	if info == nil {
		return nil;
	}

	base := info;
	loop: for {
		#partial switch i in base.variant {
		case Type_Info_Named: base = i.base;
		case: break loop;
		}
	}
	return base;
}


type_info_core :: proc "contextless" (info: ^Type_Info) -> ^Type_Info {
	if info == nil {
		return nil;
	}

	base := info;
	loop: for {
		#partial switch i in base.variant {
		case Type_Info_Named:  base = i.base;
		case Type_Info_Enum:   base = i.base;
		case: break loop;
		}
	}
	return base;
}
type_info_base_without_enum :: type_info_core;

__type_info_of :: proc "contextless" (id: typeid) -> ^Type_Info {
	MASK :: 1<<(8*size_of(typeid) - 8) - 1;
	data := transmute(uintptr)id;
	n := int(data & MASK);
	if n < 0 || n >= len(type_table) {
		n = 0;
	}
	return &type_table[n];
}

typeid_base :: proc "contextless" (id: typeid) -> typeid {
	ti := type_info_of(id);
	ti = type_info_base(ti);
	return ti.id;
}
typeid_core :: proc "contextless" (id: typeid) -> typeid {
	ti := type_info_base_without_enum(type_info_of(id));
	return ti.id;
}
typeid_base_without_enum :: typeid_core;



@(default_calling_convention = "none")
foreign {
	@(link_name="llvm.assume")
	assume :: proc(cond: bool) ---;

	@(link_name="llvm.debugtrap")
	debug_trap :: proc() ---;

	@(link_name="llvm.trap")
	trap :: proc() -> ! ---;

	@(link_name="llvm.readcyclecounter")
	read_cycle_counter :: proc() -> u64 ---;
}



default_logger_proc :: proc(data: rawptr, level: Logger_Level, text: string, options: Logger_Options, location := #caller_location) {
	// Nothing
}

default_logger :: proc() -> Logger {
	return Logger{default_logger_proc, nil, Logger_Level.Debug, nil};
}


default_context :: proc "contextless" () -> Context {
	c: Context;
	__init_context(&c);
	return c;
}

@private
__init_context_from_ptr :: proc "contextless" (c: ^Context, other: ^Context) {
	if c == nil {
		return;
	}
	c^ = other^;
	__init_context(c);
}

@private
__init_context :: proc "contextless" (c: ^Context) {
	if c == nil {
		return;
	}

	// NOTE(bill): Do not initialize these procedures with a call as they are not defined with the "contexless" calling convention
	c.allocator.procedure = default_allocator_proc;
	c.allocator.data = nil;

	c.temp_allocator.procedure = default_temp_allocator_proc;
	c.temp_allocator.data = &global_default_temp_allocator_data;

	c.thread_id = current_thread_id(); // NOTE(bill): This is "contextless" so it is okay to call
	c.assertion_failure_proc = default_assertion_failure_proc;

	c.logger.procedure = default_logger_proc;
	c.logger.data = nil;
}


default_assertion_failure_proc :: proc(prefix, message: string, loc: Source_Code_Location) {
	print_caller_location(loc);
	print_string(" ");
	print_string(prefix);
	if len(message) > 0 {
		print_string(": ");
		print_string(message);
	}
	print_byte('\n');
	debug_trap();
}
