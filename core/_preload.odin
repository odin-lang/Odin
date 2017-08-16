#shared_global_scope;

import (
	"os.odin";
	"fmt.odin"; // TODO(bill): Remove the need for `fmt` here
	"utf8.odin";
	"raw.odin";
)
// Naming Conventions:
// In general, Ada_Case for types and snake_case for values
//
// Import Name:        snake_case (but prefer single word)
// Types:              Ada_Case
// Union Variants:     Ada_Case
// Enum Values:        Ada_Case
// Procedures:         snake_case
// Local Variables:    snake_case
// Constant Variables: SCREAMING_SNAKE_CASE




// IMPORTANT NOTE(bill): `type_info_of` cannot be used within a
// #shared_global_scope due to  the internals of the compiler.
// This could change at a later date if the all these data structures are
// implemented within the compiler rather than in this "preload" file

// NOTE(bill): This must match the compiler's
Calling_Convention :: enum {
	Invalid         = 0,
	Odin            = 1,
	Contextless     = 2,
	C               = 3,
	Std             = 4,
	Fast            = 5,
}
// IMPORTANT NOTE(bill): Do not change the order of any of this data
// The compiler relies upon this _exact_ order
Type_Info :: struct #ordered {
// Core Types
	Enum_Value :: union {
		rune,
		i8, i16, i32, i64, i128, int,
		u8, u16, u32, u64, u128, uint,
		f32, f64,
	};

// Variant Types
	Named   :: struct #ordered {name: string; base: ^Type_Info};
	Integer :: struct #ordered {signed: bool};
	Rune    :: struct{};
	Float   :: struct{};
	Complex :: struct{};
	String  :: struct{};
	Boolean :: struct{};
	Any     :: struct{};
	Pointer :: struct #ordered {
		elem: ^Type_Info; // nil -> rawptr
	};
	Procedure :: struct #ordered {
		params:     ^Type_Info; // Type_Info.Tuple
		results:    ^Type_Info; // Type_Info.Tuple
		variadic:   bool;
		convention: Calling_Convention;
	};
	Array :: struct #ordered {
		elem:      ^Type_Info;
		elem_size: int;
		count:     int;
	};
	Dynamic_Array :: struct #ordered {elem: ^Type_Info; elem_size: int};
	Slice         :: struct #ordered {elem: ^Type_Info; elem_size: int};
	Vector        :: struct #ordered {elem: ^Type_Info; elem_size, count: int};
	Tuple :: struct #ordered { // Only really used for procedures
		types:        []^Type_Info;
		names:        []string;
	};
	Struct :: struct #ordered {
		types:        []^Type_Info;
		names:        []string;
		offsets:      []int;  // offsets may not be used in tuples
		usings:       []bool; // usings may not be used in tuples
		is_packed:    bool;
		is_ordered:   bool;
		is_raw_union: bool;
		custom_align: bool;
	};
	Union :: struct #ordered {
		variants:   []^Type_Info;
		tag_offset: int;
	};
	Enum :: struct #ordered {
		base:   ^Type_Info;
		names:  []string;
		values: []Enum_Value;
	};
	Map :: struct #ordered {
		key:              ^Type_Info;
		value:            ^Type_Info;
		generated_struct: ^Type_Info;
	};
	Bit_Field :: struct #ordered {
		names:   []string;
		bits:    []i32;
		offsets: []i32;
	};


// Fields
	size:  int;
	align: int;

	variant: union {
		Named,
		Integer,
		Rune,
		Float,
		Complex,
		String,
		Boolean,
		Any,
		Pointer,
		Procedure,
		Array,
		Dynamic_Array,
		Slice,
		Vector,
		Tuple,
		Struct,
		Union,
		Enum,
		Map,
		Bit_Field,
	};
}

// NOTE(bill): only the ones that are needed (not all types)
// This will be set by the compiler
__type_table: []Type_Info;

__argv__: ^^u8;
__argc__: i32;

// IMPORTANT NOTE(bill): Must be in this order (as the compiler relies upon it)

Allocator :: struct #ordered {
	Mode :: enum u8 {
		Alloc,
		Free,
		FreeAll,
		Resize,
	}
	Proc :: #type proc(allocator_data: rawptr, mode: Mode,
	                   size, alignment: int,
	                   old_memory: rawptr, old_size: int, flags: u64 = 0) -> rawptr;

	procedure: Proc;
	data:      rawptr;
}


Context :: struct #ordered {
	allocator:  Allocator;
	thread_id:  int;

	user_data:  any;
	user_index: int;

	derived:    any; // May be used for derived data types
}

DEFAULT_ALIGNMENT :: align_of([vector 4]f32);

Source_Code_Location :: struct #ordered {
	file_path:    string;
	line, column: i64;
	procedure:    string;
}


__INITIAL_MAP_CAP :: 16;

__Map_Key :: struct #ordered {
	hash: u128;
	str:  string;
}

__Map_Find_Result :: struct #ordered {
	hash_index:  int;
	entry_prev:  int;
	entry_index: int;
}

__Map_Entry_Header :: struct #ordered {
	key:  __Map_Key;
	next: int;
/*
	value: Value_Type;
*/
}

__Map_Header :: struct #ordered {
	m:             ^raw.Map;
	is_key_string: bool;
	entry_size:    int;
	entry_align:   int;
	value_offset:  int;
	value_size:    int;
}



type_info_base :: proc(info: ^Type_Info) -> ^Type_Info {
	if info == nil do return nil;

	base := info;
	match i in base.variant {
	case Type_Info.Named: base = i.base;
	}
	return base;
}


type_info_base_without_enum :: proc(info: ^Type_Info) -> ^Type_Info {
	if info == nil do return nil;

	base := info;
	match i in base.variant {
	case Type_Info.Named: base = i.base;
	case Type_Info.Enum:  base = i.base;
	}
	return base;
}



foreign __llvm_core {
	assume             :: proc(cond: bool) #cc_c #link_name "llvm.assume"           ---;
	__debug_trap       :: proc()           #cc_c #link_name "llvm.debugtrap"        ---;
	__trap             :: proc()           #cc_c #link_name "llvm.trap"             ---;
	read_cycle_counter :: proc() -> u64    #cc_c #link_name "llvm.readcyclecounter" ---;
}



make_source_code_location :: proc(file: string, line, column: i64, procedure: string) -> Source_Code_Location #cc_contextless #inline {
	return Source_Code_Location{file, line, column, procedure};
}




__init_context_from_ptr :: proc(c: ^Context, other: ^Context) #cc_contextless {
	if c == nil do return;
	c^ = other^;

	if c.allocator.procedure == nil {
		c.allocator = default_allocator();
	}
	if c.thread_id == 0 {
		c.thread_id = os.current_thread_id();
	}
}

__init_context :: proc(c: ^Context) #cc_contextless {
	if c == nil do return;

	if c.allocator.procedure == nil {
		c.allocator = default_allocator();
	}
	if c.thread_id == 0 {
		c.thread_id = os.current_thread_id();
	}
}


/*
__check_context :: proc() {
	__init_context(&__context);
}
*/

alloc :: proc(size: int, alignment: int = DEFAULT_ALIGNMENT) -> rawptr #inline {
	a := context.allocator;
	return a.procedure(a.data, Allocator.Mode.Alloc, size, alignment, nil, 0, 0);
}

free_ptr_with_allocator :: proc(a: Allocator, ptr: rawptr) #inline {
	if ptr == nil do return;
	if a.procedure == nil do return;
	a.procedure(a.data, Allocator.Mode.Free, 0, 0, ptr, 0, 0);
}

free_ptr :: proc(ptr: rawptr) #inline do free_ptr_with_allocator(context.allocator, ptr);

free_all :: proc() #inline {
	a := context.allocator;
	a.procedure(a.data, Allocator.Mode.FreeAll, 0, 0, nil, 0, 0);
}


resize :: proc(ptr: rawptr, old_size, new_size: int, alignment: int = DEFAULT_ALIGNMENT) -> rawptr #inline {
	a := context.allocator;
	return a.procedure(a.data, Allocator.Mode.Resize, new_size, alignment, ptr, old_size, 0);
}


copy :: proc(dst, src: $T/[]$E) -> int #cc_contextless {
	n := max(0, min(len(dst), len(src)));
	if n > 0 do __mem_copy(&dst[0], &src[0], n*size_of(E));
	return n;
}


append :: proc(array: ^$T/[]$E, args: ...E) -> int #cc_contextless {
	if array == nil do return 0;

	arg_len := len(args);
	if arg_len <= 0 do return len(array);

	arg_len = min(cap(array)-len(array), arg_len);
	if arg_len > 0 {
		s := cast(^raw.Slice)array;
		data := cast(^E)s.data;
		assert(data != nil);
		sz :: size_of(E);
		__mem_copy(data + s.len, &args[0], sz*arg_len);
		s.len += arg_len;
	}
	return len(array);
}

append :: proc(array: ^$T/[dynamic]$E, args: ...E) -> int {
	if array == nil do return 0;

	arg_len := len(args);
	if arg_len <= 0 do return len(array);


	ok := true;
	if cap(array) <= len(array)+arg_len {
		cap := 2 * cap(array) + max(8, arg_len);
		ok = reserve(array, cap);
	}
	// TODO(bill): Better error handling for failed reservation
	if ok {
		a := cast(^raw.Dynamic_Array)array;
		data := cast(^E)a.data;
		assert(data != nil);
		__mem_copy(data + a.len, &args[0], size_of(E) * arg_len);
		a.len += arg_len;
	}
	return len(array);
}

append :: proc(array: ^$T/[]u8, args: ...string) -> int {
	for arg in args {
		append(array, ...cast([]u8)arg);
	}
	return len(array);
}
append :: proc(array: ^$T/[dynamic]u8, args: ...string) -> int {
	for arg in args {
		append(array, ...cast([]u8)arg);
	}
	return len(array);
}

pop :: proc(array: ^$T/[]$E) -> E #cc_contextless {
	if array == nil do return E{};
	assert(len(array) > 0);
	res := array[len(array)-1];
	(^raw.Slice)(array).len -= 1;
	return res;
}

pop :: proc(array: ^$T/[dynamic]$E) -> E #cc_contextless {
	if array == nil do return E{};
	assert(len(array) > 0);
	res := array[len(array)-1];
	(^raw.Dynamic_Array)(array).len -= 1;
	return res;
}

clear :: proc(slice: ^$T/[]$E) #cc_contextless #inline {
	if slice != nil do (cast(^raw.Slice)slice).len = 0;
}
clear :: proc(array: ^$T/[dynamic]$E) #cc_contextless #inline {
	if array != nil do (cast(^raw.Dynamic_Array)array).len = 0;
}
clear :: proc(m: ^$T/map[$K]$V) #cc_contextless #inline {
	if m == nil do return;
	raw_map := cast(^raw.Map)m;
	hashes  := cast(^raw.Dynamic_Array)&raw_map.hashes;
	entries := cast(^raw.Dynamic_Array)&raw_map.entries;
	hashes.len  = 0;
	entries.len = 0;
}

reserve :: proc(array: ^$T/[dynamic]$E, capacity: int) -> bool {
	if array == nil do return false;
	a := cast(^raw.Dynamic_Array)array;

	if capacity <= a.cap do return true;

	if a.allocator.procedure == nil {
		a.allocator = context.allocator;
	}
	assert(a.allocator.procedure != nil);

	old_size  := a.cap * size_of(E);
	new_size  := capacity * size_of(E);
	allocator := a.allocator;

	new_data := allocator.procedure(allocator.data, Allocator.Mode.Resize, new_size, align_of(E), a.data, old_size, 0);
	if new_data == nil do return false;

	a.data = new_data;
	a.cap = capacity;
	return true;
}


__get_map_header :: proc(m: ^$T/map[$K]$V) -> __Map_Header #cc_contextless {
	header := __Map_Header{m = cast(^raw.Map)m};
	Entry :: struct {
		key:   __Map_Key;
		next:  int;
		value: V;
	}

	_, is_string := type_info_base(type_info_of(K)).variant.(Type_Info.String);
	header.is_key_string = is_string;
	header.entry_size    = size_of(Entry);
	header.entry_align   = align_of(Entry);
	header.value_offset  = offset_of(Entry, value);
	header.value_size    = size_of(V);
	return header;
}

__get_map_key :: proc(key: $K) -> __Map_Key #cc_contextless {
	map_key: __Map_Key;
	ti := type_info_base_without_enum(type_info_of(K));
	match _ in ti {
	case Type_Info.Integer:
		match 8*size_of(key) {
		case   8: map_key.hash = u128((  ^u8)(&key)^);
		case  16: map_key.hash = u128(( ^u16)(&key)^);
		case  32: map_key.hash = u128(( ^u32)(&key)^);
		case  64: map_key.hash = u128(( ^u64)(&key)^);
		case 128: map_key.hash = u128((^u128)(&key)^);
		case: panic("Unhandled integer size");
		}
	case Type_Info.Rune:
		map_key.hash = u128((cast(^rune)&key)^);
	case Type_Info.Pointer:
		map_key.hash = u128(uint((^rawptr)(&key)^));
	case Type_Info.Float:
		match 8*size_of(key) {
		case 32: map_key.hash = u128((^u32)(&key)^);
		case 64: map_key.hash = u128((^u64)(&key)^);
		case: panic("Unhandled float size");
		}
	case Type_Info.String:
		str := (^string)(&key)^;
		map_key.hash = __default_hash_string(str);
		map_key.str  = str;
	case:
		panic("Unhandled map key type");
	}
	return map_key;
}

reserve :: proc(m: ^$T/map[$K]$V, capacity: int) {
	if m != nil do __dynamic_map_reserve(__get_map_header(m), capacity);
}

delete :: proc(m: ^$T/map[$K]$V, key: K) {
	if m != nil do __dynamic_map_delete(__get_map_header(m), __get_map_key(key));
}



new  :: proc(T: type) -> ^T #inline {
	ptr := cast(^T)alloc(size_of(T), align_of(T));
	ptr^ = T{};
	return ptr;
}
new_clone :: proc(data: $T) -> ^T #inline {
	ptr := cast(^T)alloc(size_of(T), align_of(T));
	ptr^ = data;
	return ptr;
}

free :: proc(ptr:   rawptr)         do free_ptr(ptr);
free :: proc(str:   $T/string)      do free_ptr((^raw.String      )(&str).data);
free :: proc(array: $T/[dynamic]$E) do free_ptr((^raw.Dynamic_Array)(&array).data);
free :: proc(slice: $T/[]$E)        do free_ptr((^raw.Slice       )(&slice).data);
free :: proc(m:     $T/map[$K]$V) {
	raw := cast(^raw.Map)&m;
	free(raw.hashes);
	free(raw.entries.data);
}

// NOTE(bill): This code works but I will prefer having `make` a built-in procedure
// to have better error messages
/*
make :: proc(T: type/[]$E, len: int, using location := #caller_location) -> T {
	cap := len;
	__slice_expr_error(file_path, int(line), int(column), 0, len, cap);
	data := cast(^E)alloc(len * size_of(E), align_of(E));
	for i in 0..len do (data+i)^ = E{};
	s := raw.Slice{data = data, len = len, cap = len};
	return (cast(^T)&s)^;
}
make :: proc(T: type/[]$E, len, cap: int, using location := #caller_location) -> T {
	__slice_expr_error(file_path, int(line), int(column), 0, len, cap);
	data := cast(^E)alloc(len * size_of(E), align_of(E));
	for i in 0..len do (data+i)^ = E{};
	s := raw.Slice{data = data, len = len, cap = len};
	return (cast(^T)&s)^;
}
make :: proc(T: type/[dynamic]$E, len: int = 8, using location := #caller_location) -> T {
	cap := len;
	__slice_expr_error(file_path, int(line), int(column), 0, len, cap);
	data := cast(^E)alloc(cap * size_of(E), align_of(E));
	for i in 0..len do (data+i)^ = E{};
	s := raw.Dynamic_Array{data = data, len = len, cap = cap, allocator = context.allocator};
	return (cast(^T)&s)^;
}
make :: proc(T: type/[dynamic]$E, len, cap: int, using location := #caller_location) -> T {
	__slice_expr_error(file_path, int(line), int(column), 0, len, cap);
	data := cast(^E)alloc(cap * size_of(E), align_of(E));
	for i in 0..len do (data+i)^ = E{};
	s := raw.Dynamic_Array{data = data, len = len, cap = cap, allocator = context.allocator};
	return (cast(^T)&s)^;
}

make :: proc(T: type/map[$K]$V, cap: int = 16, using location := #caller_location) -> T {
	if cap < 0 do cap = 16;

	m: T;
	header := __get_map_header(&m);
	__dynamic_map_reserve(header, cap);
	return m;
}
*/



default_resize_align :: proc(old_memory: rawptr, old_size, new_size, alignment: int) -> rawptr {
	if old_memory == nil do return alloc(new_size, alignment);

	if new_size == 0 {
		free(old_memory);
		return nil;
	}

	if new_size == old_size do return old_memory;

	new_memory := alloc(new_size, alignment);
	if new_memory == nil do return nil;

	__mem_copy(new_memory, old_memory, min(old_size, new_size));;
	free(old_memory);
	return new_memory;
}


default_allocator_proc :: proc(allocator_data: rawptr, mode: Allocator.Mode,
                            size, alignment: int,
                            old_memory: rawptr, old_size: int, flags: u64) -> rawptr {
	using Allocator.Mode;

	match mode {
	case Alloc:
		return os.heap_alloc(size);

	case Free:
		os.heap_free(old_memory);
		return nil;

	case FreeAll:
		// NOTE(bill): Does nothing

	case Resize:
		ptr := os.heap_resize(old_memory, size);
		assert(ptr != nil);
		return ptr;
	}

	return nil;
}

default_allocator :: proc() -> Allocator {
	return Allocator{
		procedure = default_allocator_proc,
		data = nil,
	};
}


assert :: proc(condition: bool, message := "", using location := #caller_location) -> bool #cc_contextless {
	if !condition {
		if len(message) > 0 {
			fmt.fprintf(os.stderr, "%s(%d:%d) Runtime assertion: %s\n", file_path, line, column, message);
		} else {
			fmt.fprintf(os.stderr, "%s(%d:%d) Runtime assertion\n", file_path, line, column);
		}
		__debug_trap();
	}
	return condition;
}

panic :: proc(message := "", using location := #caller_location) #cc_contextless {
	if len(message) > 0 {
		fmt.fprintf(os.stderr, "%s(%d:%d) Panic: %s\n", file_path, line, column, message);
	} else {
		fmt.fprintf(os.stderr, "%s(%d:%d) Panic\n", file_path, line, column);
	}
	__debug_trap();
}




__string_eq :: proc(a, b: string) -> bool #cc_contextless {
	match {
	case len(a) != len(b): return false;
	case len(a) == 0:      return true;
	case &a[0] == &b[0]:   return true;
	}
	return __string_cmp(a, b) == 0;
}

__string_cmp :: proc(a, b: string) -> int #cc_contextless {
	return __mem_compare(&a[0], &b[0], min(len(a), len(b)));
}

__string_ne :: proc(a, b: string) -> bool #cc_contextless #inline { return !__string_eq(a, b); }
__string_lt :: proc(a, b: string) -> bool #cc_contextless #inline { return __string_cmp(a, b) < 0; }
__string_gt :: proc(a, b: string) -> bool #cc_contextless #inline { return __string_cmp(a, b) > 0; }
__string_le :: proc(a, b: string) -> bool #cc_contextless #inline { return __string_cmp(a, b) <= 0; }
__string_ge :: proc(a, b: string) -> bool #cc_contextless #inline { return __string_cmp(a, b) >= 0; }


__complex64_eq :: proc (a, b: complex64)  -> bool #cc_contextless #inline { return real(a) == real(b) && imag(a) == imag(b); }
__complex64_ne :: proc (a, b: complex64)  -> bool #cc_contextless #inline { return real(a) != real(b) || imag(a) != imag(b); }

__complex128_eq :: proc(a, b: complex128) -> bool #cc_contextless #inline { return real(a) == real(b) && imag(a) == imag(b); }
__complex128_ne :: proc(a, b: complex128) -> bool #cc_contextless #inline { return real(a) != real(b) || imag(a) != imag(b); }


__bounds_check_error :: proc(file: string, line, column: int, index, count: int) #cc_contextless {
	if 0 <= index && index < count do return;
	fmt.fprintf(os.stderr, "%s(%d:%d) Index %d is out of bounds range 0..%d\n",
	            file, line, column, index, count);
	__debug_trap();
}

__slice_expr_error :: proc(file: string, line, column: int, low, high, max: int) #cc_contextless {
	if 0 <= low && low <= high && high <= max do return;
	fmt.fprintf(os.stderr, "%s(%d:%d) Invalid slice indices: [%d..%d..%d]\n",
	            file, line, column, low, high, max);
	__debug_trap();
}

__substring_expr_error :: proc(file: string, line, column: int, low, high: int) #cc_contextless {
	if 0 <= low && low <= high do return;
	fmt.fprintf(os.stderr, "%s(%d:%d) Invalid substring indices: [%d..%d]\n",
	            file, line, column, low, high);
	__debug_trap();
}
__type_assertion_check :: proc(ok: bool, file: string, line, column: int, from, to: ^Type_Info) #cc_contextless {
	if ok do return;
	fmt.fprintf(os.stderr, "%s(%d:%d) Invalid type_assertion from %T to %T\n",
	            file, line, column, from, to);
	__debug_trap();
}

__string_decode_rune :: proc(s: string) -> (rune, int) #cc_contextless #inline {
	return utf8.decode_rune(s);
}

__bounds_check_error_loc :: proc(using loc := #caller_location, index, count: int) #cc_contextless {
	__bounds_check_error(file_path, int(line), int(column), index, count);
}
__slice_expr_error_loc :: proc(using loc := #caller_location, low, high, max: int) #cc_contextless {
	__slice_expr_error(file_path, int(line), int(column), low, high, max);
}
__substring_expr_error_loc :: proc(using loc := #caller_location, low, high: int) #cc_contextless {
	__substring_expr_error(file_path, int(line), int(column), low, high);
}

__mem_set :: proc(data: rawptr, value: i32, len: int) -> rawptr #cc_contextless {
	if data == nil do return nil;
	when size_of(rawptr) == 8 {
		foreign __llvm_core llvm_memset :: proc(dst: rawptr, val: u8, len: int, align: i32, is_volatile: bool) #link_name "llvm.memset.p0i8.i64" ---;
	} else {
		foreign __llvm_core llvm_memset :: proc(dst: rawptr, val: u8, len: int, align: i32, is_volatile: bool) #link_name "llvm.memset.p0i8.i32" ---;
	}
	llvm_memset(data, u8(value), len, 1, false);
	return data;
}
__mem_zero :: proc(data: rawptr, len: int) -> rawptr #cc_contextless {
	return __mem_set(data, 0, len);
}
__mem_copy :: proc(dst, src: rawptr, len: int) -> rawptr #cc_contextless {
	if src == nil do return dst;
	// NOTE(bill): This _must_ be implemented like C's memmove
	when size_of(rawptr) == 8 {
		foreign __llvm_core llvm_memmove :: proc(dst, src: rawptr, len: int, align: i32, is_volatile: bool) #link_name "llvm.memmove.p0i8.p0i8.i64" ---;
	} else {
		foreign __llvm_core llvm_memmove :: proc(dst, src: rawptr, len: int, align: i32, is_volatile: bool) #link_name "llvm.memmove.p0i8.p0i8.i32" ---;
	}
	llvm_memmove(dst, src, len, 1, false);
	return dst;
}
__mem_copy_non_overlapping :: proc(dst, src: rawptr, len: int) -> rawptr #cc_contextless {
	if src == nil do return dst;
	// NOTE(bill): This _must_ be implemented like C's memcpy
	when size_of(rawptr) == 8 {
		foreign __llvm_core llvm_memcpy :: proc(dst, src: rawptr, len: int, align: i32, is_volatile: bool) #link_name "llvm.memcpy.p0i8.p0i8.i64" ---;
	} else {
		foreign __llvm_core llvm_memcpy :: proc(dst, src: rawptr, len: int, align: i32, is_volatile: bool) #link_name "llvm.memcpy.p0i8.p0i8.i32";
	}
	llvm_memcpy(dst, src, len, 1, false);
	return dst;
}

__mem_compare :: proc(a, b: ^u8, n: int) -> int #cc_contextless {
	for i in 0..n {
		match {
		case (a+i)^ < (b+i)^: return -1;
		case (a+i)^ > (b+i)^: return +1;
		}
	}
	return 0;
}

foreign __llvm_core {
	__sqrt_f32 :: proc(x: f32) -> f32        #link_name "llvm.sqrt.f32" ---;
	__sqrt_f64 :: proc(x: f64) -> f64        #link_name "llvm.sqrt.f64" ---;

	__sin_f32  :: proc(θ: f32) -> f32        #link_name "llvm.sin.f32" ---;
	__sin_f64  :: proc(θ: f64) -> f64        #link_name "llvm.sin.f64" ---;

	__cos_f32  :: proc(θ: f32) -> f32        #link_name "llvm.cos.f32" ---;
	__cos_f64  :: proc(θ: f64) -> f64        #link_name "llvm.cos.f64" ---;

	__pow_f32  :: proc(x, power: f32) -> f32 #link_name "llvm.pow.f32" ---;
	__pow_f64  :: proc(x, power: f64) -> f64 #link_name "llvm.pow.f64" ---;

	fmuladd32  :: proc(a, b, c: f32) -> f32 #link_name "llvm.fmuladd.f32" ---;
	fmuladd64  :: proc(a, b, c: f64) -> f64 #link_name "llvm.fmuladd.f64" ---;
}
__abs_complex64 :: proc(x: complex64) -> f32 #inline #cc_contextless {
	r, i := real(x), imag(x);
	return __sqrt_f32(r*r + i*i);
}
__abs_complex128 :: proc(x: complex128) -> f64 #inline #cc_contextless {
	r, i := real(x), imag(x);
	return __sqrt_f64(r*r + i*i);
}




__dynamic_array_make :: proc(array_: rawptr, elem_size, elem_align: int, len, cap: int) {
	array := cast(^raw.Dynamic_Array)array_;
	array.allocator = context.allocator;
	assert(array.allocator.procedure != nil);

	if cap > 0 {
		__dynamic_array_reserve(array_, elem_size, elem_align, cap);
		array.len = len;
	}
}

__dynamic_array_reserve :: proc(array_: rawptr, elem_size, elem_align: int, cap: int) -> bool {
	array := cast(^raw.Dynamic_Array)array_;

	if cap <= array.cap do return true;

	if array.allocator.procedure == nil {
		array.allocator = context.allocator;
	}
	assert(array.allocator.procedure != nil);

	old_size  := array.cap * elem_size;
	new_size  := cap * elem_size;
	allocator := array.allocator;

	new_data := allocator.procedure(allocator.data, Allocator.Mode.Resize, new_size, elem_align, array.data, old_size, 0);
	if new_data == nil do return false;

	array.data = new_data;
	array.cap = cap;
	return true;
}

__dynamic_array_resize :: proc(array_: rawptr, elem_size, elem_align: int, len: int) -> bool {
	array := cast(^raw.Dynamic_Array)array_;

	ok := __dynamic_array_reserve(array_, elem_size, elem_align, len);
	if ok do array.len = len;
	return ok;
}


__dynamic_array_append :: proc(array_: rawptr, elem_size, elem_align: int,
                               items: rawptr, item_count: int) -> int {
	array := cast(^raw.Dynamic_Array)array_;

	if items == nil    do return 0;
	if item_count <= 0 do return 0;


	ok := true;
	if array.cap <= array.len+item_count {
		cap := 2 * array.cap + max(8, item_count);
		ok = __dynamic_array_reserve(array, elem_size, elem_align, cap);
	}
	// TODO(bill): Better error handling for failed reservation
	if !ok do return array.len;

	data := cast(^u8)array.data;
	assert(data != nil);
	__mem_copy(data + (elem_size*array.len), items, elem_size * item_count);
	array.len += item_count;
	return array.len;
}

__dynamic_array_append_nothing :: proc(array_: rawptr, elem_size, elem_align: int) -> int {
	array := cast(^raw.Dynamic_Array)array_;

	ok := true;
	if array.cap <= array.len+1 {
		cap := 2 * array.cap + max(8, 1);
		ok = __dynamic_array_reserve(array, elem_size, elem_align, cap);
	}
	// TODO(bill): Better error handling for failed reservation
	if !ok do return array.len;

	data := cast(^u8)array.data;
	assert(data != nil);
	__mem_zero(data + (elem_size*array.len), elem_size);
	array.len += 1;
	return array.len;
}

__slice_append :: proc(slice_: rawptr, elem_size, elem_align: int,
                       items: rawptr, item_count: int) -> int {
	slice := cast(^raw.Slice)slice_;

	if item_count <= 0 || items == nil {
		return slice.len;
	}

	item_count = min(slice.cap-slice.len, item_count);
	if item_count > 0 {
		data := cast(^u8)slice.data;
		assert(data != nil);
		__mem_copy(data + (elem_size*slice.len), items, elem_size * item_count);
		slice.len += item_count;
	}
	return slice.len;
}

// Map stuff

__default_hash :: proc(data: []u8) -> u128 {
	fnv128a :: proc(data: []u8) -> u128 {
		h: u128 = 0x6c62272e07bb014262b821756295c58d;
		for b in data {
			h = (h ~ u128(b)) * 0x1000000000000000000013b;
		}
		return h;
	}
	return fnv128a(data);
}
__default_hash_string :: proc(s: string) -> u128 do return __default_hash(cast([]u8)s);

__dynamic_map_reserve :: proc(using header: __Map_Header, cap: int)  {
	__dynamic_array_reserve(&m.hashes, size_of(int), align_of(int), cap);
	__dynamic_array_reserve(&m.entries, entry_size, entry_align,    cap);
}

__dynamic_map_rehash :: proc(using header: __Map_Header, new_count: int) {
	new_header: __Map_Header = header;
	nm: raw.Map;
	new_header.m = &nm;

	header_hashes := cast(^raw.Dynamic_Array)&header.m.hashes;
	nm_hashes     := cast(^raw.Dynamic_Array)&nm.hashes;

	__dynamic_array_resize(nm_hashes, size_of(int), align_of(int), new_count);
	__dynamic_array_reserve(&nm.entries, entry_size, entry_align, m.entries.len);
	for i in 0..new_count do nm.hashes[i] = -1;

	for i in 0..m.entries.len {
		if len(nm.hashes) == 0 do __dynamic_map_grow(new_header);

		entry_header := __dynamic_map_get_entry(header, i);
		data := cast(^u8)entry_header;

		fr := __dynamic_map_find(new_header, entry_header.key);
		j := __dynamic_map_add_entry(new_header, entry_header.key);
		if fr.entry_prev < 0 {
			nm.hashes[fr.hash_index] = j;
		} else {
			e := __dynamic_map_get_entry(new_header, fr.entry_prev);
			e.next = j;
		}

		e := __dynamic_map_get_entry(new_header, j);
		e.next = fr.entry_index;
		ndata := cast(^u8)e;
		__mem_copy(ndata+value_offset, data+value_offset, value_size);

		if __dynamic_map_full(new_header) do __dynamic_map_grow(new_header);
	}
	free_ptr_with_allocator(header_hashes.allocator, header_hashes.data);
	free_ptr_with_allocator(header.m.entries.allocator, header.m.entries.data);
	header.m^ = nm;
}

__dynamic_map_get :: proc(h: __Map_Header, key: __Map_Key) -> rawptr {
	index := __dynamic_map_find(h, key).entry_index;
	if index >= 0 {
		data := cast(^u8)__dynamic_map_get_entry(h, index);
		return data + h.value_offset;
	}
	return nil;
}

__dynamic_map_set :: proc(using h: __Map_Header, key: __Map_Key, value: rawptr) {
	index: int;
	assert(value != nil);

	if len(m.hashes) == 0 {
		__dynamic_map_reserve(h, __INITIAL_MAP_CAP);
		__dynamic_map_grow(h);
	}

	fr := __dynamic_map_find(h, key);
	if fr.entry_index >= 0 {
		index = fr.entry_index;
	} else {
		index = __dynamic_map_add_entry(h, key);
		if fr.entry_prev >= 0 {
			entry := __dynamic_map_get_entry(h, fr.entry_prev);
			entry.next = index;
		} else {
			m.hashes[fr.hash_index] = index;
		}
	}
	{
		e := __dynamic_map_get_entry(h, index);
		e.key = key;
		val := cast(^u8)e + value_offset;
		__mem_copy(val, value, value_size);
	}

	if __dynamic_map_full(h) {
		__dynamic_map_grow(h);
	}
}


__dynamic_map_grow :: proc(using h: __Map_Header) {
	new_count := max(2*m.entries.cap + 8, __INITIAL_MAP_CAP);
	__dynamic_map_rehash(h, new_count);
}

__dynamic_map_full :: proc(using h: __Map_Header) -> bool #inline {
	return int(0.75 * f64(len(m.hashes))) <= m.entries.cap;
}


__dynamic_map_hash_equal :: proc(h: __Map_Header, a, b: __Map_Key) -> bool {
	if a.hash == b.hash {
		if h.is_key_string do return a.str == b.str;
		return true;
	}
	return false;
}

__dynamic_map_find :: proc(using h: __Map_Header, key: __Map_Key) -> __Map_Find_Result {
	fr := __Map_Find_Result{-1, -1, -1};
	if len(m.hashes) > 0 {
		fr.hash_index = int(key.hash % u128(len(m.hashes)));
		fr.entry_index = m.hashes[fr.hash_index];
		for fr.entry_index >= 0 {
			entry := __dynamic_map_get_entry(h, fr.entry_index);
			if __dynamic_map_hash_equal(h, entry.key, key) do return fr;
			fr.entry_prev = fr.entry_index;
			fr.entry_index = entry.next;
		}
	}
	return fr;
}

__dynamic_map_add_entry :: proc(using h: __Map_Header, key: __Map_Key) -> int {
	prev := m.entries.len;
	c := __dynamic_array_append_nothing(&m.entries, entry_size, entry_align);
	if c != prev {
		end := __dynamic_map_get_entry(h, c-1);
		end.key = key;
		end.next = -1;
	}
	return prev;
}

__dynamic_map_delete :: proc(using h: __Map_Header, key: __Map_Key) {
	fr := __dynamic_map_find(h, key);
	if fr.entry_index >= 0 {
		__dynamic_map_erase(h, fr);
	}
}

__dynamic_map_get_entry :: proc(using h: __Map_Header, index: int) -> ^__Map_Entry_Header {
	return cast(^__Map_Entry_Header)(cast(^u8)m.entries.data + index*entry_size);
}

__dynamic_map_erase :: proc(using h: __Map_Header, fr: __Map_Find_Result) {
	if fr.entry_prev < 0 {
		m.hashes[fr.hash_index] = __dynamic_map_get_entry(h, fr.entry_index).next;
	} else {
		__dynamic_map_get_entry(h, fr.entry_prev).next = __dynamic_map_get_entry(h, fr.entry_index).next;
	}

	if fr.entry_index == m.entries.len-1 {
		m.entries.len -= 1;
	}
	__mem_copy(__dynamic_map_get_entry(h, fr.entry_index), __dynamic_map_get_entry(h, m.entries.len-1), entry_size);
	last := __dynamic_map_find(h, __dynamic_map_get_entry(h, fr.entry_index).key);
	if last.entry_prev >= 0 {
		__dynamic_map_get_entry(h, last.entry_prev).next = fr.entry_index;
	} else {
		m.hashes[last.hash_index] = fr.entry_index;
	}
}
