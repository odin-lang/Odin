// This is the runtime code required by the compiler
// IMPORTANT NOTE(bill): Do not change the order of any of this data
// The compiler relies upon this _exact_ order
package runtime

import "core:os"
import "core:mem"
import "core:log"

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


// IMPORTANT NOTE(bill): `type_info_of` cannot be used within a
// #shared_global_scope due to  the internals of the compiler.
// This could change at a later date if the all these data structures are
// implemented within the compiler rather than in this "preload" file

// NOTE(bill): This must match the compiler's
Calling_Convention :: enum {
	Invalid     = 0,
	Odin        = 1,
	Contextless = 2,
	C           = 3,
	Std         = 4,
	Fast        = 5,
}

Type_Info_Enum_Value :: union {
	rune,
	i8, i16, i32, i64, int,
	u8, u16, u32, u64, uint, uintptr,
};

// Variant Types
Type_Info_Named    :: struct {name: string, base: ^Type_Info};
Type_Info_Integer  :: struct {signed: bool};
Type_Info_Rune     :: struct {};
Type_Info_Float    :: struct {};
Type_Info_Complex  :: struct {};
Type_Info_String   :: struct {is_cstring: bool};
Type_Info_Boolean  :: struct {};
Type_Info_Any      :: struct {};
Type_Info_Type_Id  :: struct {};
Type_Info_Pointer  :: struct {
	elem: ^Type_Info // nil -> rawptr
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
Type_Info_Dynamic_Array :: struct {elem: ^Type_Info, elem_size: int};
Type_Info_Slice         :: struct {elem: ^Type_Info, elem_size: int};
Type_Info_Tuple :: struct { // Only really used for procedures
	types:        []^Type_Info,
	names:        []string,
};
Type_Info_Struct :: struct {
	types:        []^Type_Info,
	names:        []string,
	offsets:      []uintptr, // offsets may not be used in tuples
	usings:       []bool,    // usings may not be used in tuples
	is_packed:    bool,
	is_raw_union: bool,
	custom_align: bool,
};
Type_Info_Union :: struct {
	variants:   []^Type_Info,
	tag_offset: uintptr,
	tag_type:   ^Type_Info,
	custom_align: bool,
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
};
Type_Info_Bit_Field :: struct {
	names:   []string,
	bits:    []i32,
	offsets: []i32,
};
Type_Info_Bit_Set :: struct {
	elem:       ^Type_Info,
	underlying: ^Type_Info, // Possibly nil
	lower:      i64,
	upper:      i64,
};

Type_Info_Opaque :: struct {
	elem: ^Type_Info,
}

Type_Info :: struct {
	size:  int,
	align: int,
	id:    typeid,

	variant: union {
		Type_Info_Named,
		Type_Info_Integer,
		Type_Info_Rune,
		Type_Info_Float,
		Type_Info_Complex,
		Type_Info_String,
		Type_Info_Boolean,
		Type_Info_Any,
		Type_Info_Type_Id,
		Type_Info_Pointer,
		Type_Info_Procedure,
		Type_Info_Array,
		Type_Info_Dynamic_Array,
		Type_Info_Slice,
		Type_Info_Tuple,
		Type_Info_Struct,
		Type_Info_Union,
		Type_Info_Enum,
		Type_Info_Map,
		Type_Info_Bit_Field,
		Type_Info_Bit_Set,
		Type_Info_Opaque,
	},
}

// NOTE(bill): This must match the compiler's
Typeid_Kind :: enum u8 {
	Invalid,
	Integer,
	Rune,
	Float,
	Complex,
	String,
	Boolean,
	Any,
	Type_Id,
	Pointer,
	Procedure,
	Array,
	Dynamic_Array,
	Slice,
	Tuple,
	Struct,
	Union,
	Enum,
	Map,
	Bit_Field,
	Bit_Set,
	Opaque,
}

Typeid_Bit_Field :: bit_field #align align_of(uintptr) {
	index:    8*size_of(align_of(uintptr)) - 8,
	kind:     5, // Typeid_Kind
	named:    1,
	special:  1, // signed, cstring, etc
	reserved: 1,
}

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

Context :: struct {
	allocator:      mem.Allocator,
	temp_allocator: mem.Allocator,
	assertion_failure_proc: Assertion_Failure_Proc,
	logger: log.Logger,

	thread_id:  int,

	user_data:  any,
	user_index: int,

	derived:    any, // May be used for derived data types
}

global_scratch_allocator_data: mem.Scratch_Allocator;





INITIAL_MAP_CAP :: 16;

Map_Key :: struct {
	hash: u64,
	str:  string,
}

Map_Find_Result :: struct {
	hash_index:  int,
	entry_prev:  int,
	entry_index: int,
}

Map_Entry_Header :: struct {
	key:  Map_Key,
	next: int,
/*
	value: Value_Type,
*/
}

Map_Header :: struct {
	m:             ^mem.Raw_Map,
	is_key_string: bool,
	entry_size:    int,
	entry_align:   int,
	value_offset:  uintptr,
	value_size:    int,
}






type_info_base :: proc "contextless" (info: ^Type_Info) -> ^Type_Info {
	if info == nil do return nil;

	base := info;
	loop: for {
		switch i in base.variant {
		case Type_Info_Named: base = i.base;
		case: break loop;
		}
	}
	return base;
}


type_info_base_without_enum :: proc "contextless" (info: ^Type_Info) -> ^Type_Info {
	if info == nil do return nil;

	base := info;
	loop: for {
		switch i in base.variant {
		case Type_Info_Named: base = i.base;
		case Type_Info_Enum:  base = i.base;
		case: break loop;
		}
	}
	return base;
}

__type_info_of :: proc "contextless" (id: typeid) -> ^Type_Info {
	data := transmute(Typeid_Bit_Field)id;
	n := int(data.index);
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
typeid_base_without_enum :: proc "contextless" (id: typeid) -> typeid {
	ti := type_info_base_without_enum(type_info_of(id));
	return ti.id;
}



@(default_calling_convention = "c")
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





__init_context_from_ptr :: proc "contextless" (c: ^Context, other: ^Context) {
	if c == nil do return;
	c^ = other^;
	__init_context(c);
}

__init_context :: proc "contextless" (c: ^Context) {
	if c == nil do return;

	c.allocator.procedure = os.heap_allocator_proc;
	c.allocator.data = nil;

	c.temp_allocator.procedure = mem.scratch_allocator_proc;
	c.temp_allocator.data = &global_scratch_allocator_data;

	c.thread_id = os.current_thread_id(); // NOTE(bill): This is "contextless" so it is okay to call
	c.assertion_failure_proc = default_assertion_failure_proc;

	c.logger.procedure = log.nil_logger_proc;
	c.logger.data = nil;
}

@(builtin)
init_global_temporary_allocator :: proc(data: []byte, backup_allocator := context.allocator) {
	mem.scratch_allocator_init(&global_scratch_allocator_data, data, backup_allocator);
}

default_assertion_failure_proc :: proc(prefix, message: string, loc: Source_Code_Location) {
	fd := os.stderr;
	print_caller_location(fd, loc);
	os.write_string(fd, " ");
	os.write_string(fd, prefix);
	if len(message) > 0 {
		os.write_string(fd, ": ");
		os.write_string(fd, message);
	}
	os.write_byte(fd, '\n');
	debug_trap();
}



@(builtin)
copy :: proc "contextless" (dst, src: $T/[]$E) -> int {
	n := max(0, min(len(dst), len(src)));
	if n > 0 do mem.copy(&dst[0], &src[0], n*size_of(E));
	return n;
}



@(builtin)
pop :: proc "contextless" (array: ^$T/[dynamic]$E) -> E {
	if array == nil do return E{};
	assert(len(array) > 0);
	res := array[len(array)-1];
	(^mem.Raw_Dynamic_Array)(array).len -= 1;
	return res;
}

@(builtin)
unordered_remove :: proc(array: ^$D/[dynamic]$T, index: int, loc := #caller_location) {
	bounds_check_error_loc(loc, index, len(array));
	n := len(array)-1;
	if index != n {
		array[index] = array[n];
	}
	pop(array);
}

@(builtin)
ordered_remove :: proc(array: ^$D/[dynamic]$T, index: int, loc := #caller_location) {
	bounds_check_error_loc(loc, index, len(array));
	copy(array[index:], array[index+1:]);
	pop(array);
}


@(builtin)
clear :: proc[clear_dynamic_array, clear_map];

@(builtin)
reserve :: proc[reserve_dynamic_array, reserve_map];

@(builtin)
resize :: proc[resize_dynamic_array];


@(builtin)
new :: proc[mem.new];

@(builtin)
new_clone :: proc[mem.new_clone];

@(builtin)
free :: proc[mem.free];

@(builtin)
free_all :: proc[mem.free_all];

@(builtin)
delete :: proc[
	mem.delete_string,
	mem.delete_cstring,
	mem.delete_dynamic_array,
	mem.delete_slice,
	mem.delete_map,
];

@(builtin)
make :: proc[
	mem.make_slice,
	mem.make_dynamic_array,
	mem.make_dynamic_array_len,
	mem.make_dynamic_array_len_cap,
	mem.make_map,
];




@(builtin)
clear_map :: inline proc "contextless" (m: ^$T/map[$K]$V) {
	if m == nil do return;
	raw_map := (^mem.Raw_Map)(m);
	entries := (^mem.Raw_Dynamic_Array)(&raw_map.entries);
	entries.len = 0;
	for _, i in raw_map.hashes {
		raw_map.hashes[i] = -1;
	}
}

@(builtin)
reserve_map :: proc(m: ^$T/map[$K]$V, capacity: int) {
	if m != nil do __dynamic_map_reserve(__get_map_header(m), capacity);
}

@(builtin)
delete_key :: proc(m: ^$T/map[$K]$V, key: K) {
	if m != nil do __dynamic_map_delete_key(__get_map_header(m), __get_map_key(key));
}



@(builtin)
append_elem :: proc(array: ^$T/[dynamic]$E, arg: E, loc := #caller_location) -> int {
	if array == nil do return 0;

	arg_len := 1;

	if cap(array) <= len(array)+arg_len {
		cap := 2 * cap(array) + max(8, arg_len);
		_ = reserve(array, cap, loc);
	}
	arg_len = min(cap(array)-len(array), arg_len);
	if arg_len > 0 {
		a := (^mem.Raw_Dynamic_Array)(array);
		data := (^E)(a.data);
		assert(data != nil);
		mem.copy(mem.ptr_offset(data, a.len), &arg, size_of(E));
		a.len += arg_len;
	}
	return len(array);
}
@(builtin)
append_elems :: proc(array: ^$T/[dynamic]$E, args: ..E, loc := #caller_location) -> int {
	if array == nil do return 0;

	arg_len := len(args);
	if arg_len <= 0 do return len(array);


	if cap(array) <= len(array)+arg_len {
		cap := 2 * cap(array) + max(8, arg_len);
		_ = reserve(array, cap, loc);
	}
	arg_len = min(cap(array)-len(array), arg_len);
	if arg_len > 0 {
		a := (^mem.Raw_Dynamic_Array)(array);
		data := (^E)(a.data);
		assert(data != nil);
		mem.copy(mem.ptr_offset(data, a.len), &args[0], size_of(E) * arg_len);
		a.len += arg_len;
	}
	return len(array);
}
@(builtin) append :: proc[append_elem, append_elems];



@(builtin)
append_string :: proc(array: ^$T/[dynamic]$E/u8, args: ..string, loc := #caller_location) -> int {
	for arg in args {
		append(array = array, args = ([]E)(arg), loc = loc);
	}
	return len(array);
}

@(builtin)
clear_dynamic_array :: inline proc "contextless" (array: ^$T/[dynamic]$E) {
	if array != nil do (^mem.Raw_Dynamic_Array)(array).len = 0;
}

@(builtin)
reserve_dynamic_array :: proc(array: ^$T/[dynamic]$E, capacity: int, loc := #caller_location) -> bool {
	if array == nil do return false;
	a := (^mem.Raw_Dynamic_Array)(array);

	if capacity <= a.cap do return true;

	if a.allocator.procedure == nil {
		a.allocator = context.allocator;
	}
	assert(a.allocator.procedure != nil);

	old_size  := a.cap * size_of(E);
	new_size  := capacity * size_of(E);
	allocator := a.allocator;

	new_data := allocator.procedure(
		allocator.data, mem.Allocator_Mode.Resize, new_size, align_of(E),
		a.data, old_size, 0, loc,
	);
	if new_data == nil do return false;

	a.data = new_data;
	a.cap = capacity;
	return true;
}

@(builtin)
resize_dynamic_array :: proc(array: ^$T/[dynamic]$E, length: int, loc := #caller_location) -> bool {
	if array == nil do return false;
	a := (^mem.Raw_Dynamic_Array)(array);

	if length <= a.cap {
		a.len = max(length, 0);
		return true;
	}

	if a.allocator.procedure == nil {
		a.allocator = context.allocator;
	}
	assert(a.allocator.procedure != nil);

	old_size  := a.cap * size_of(E);
	new_size  := length * size_of(E);
	allocator := a.allocator;

	new_data := allocator.procedure(
		allocator.data, mem.Allocator_Mode.Resize, new_size, align_of(E),
		a.data, old_size, 0, loc,
	);
	if new_data == nil do return false;

	a.data = new_data;
	a.len = length;
	a.cap = length;
	return true;
}



@(builtin)
incl_elem :: inline proc(s: ^$S/bit_set[$E; $U], elem: E) -> S {
	s^ |= {elem};
	return s^;
}
@(builtin)
incl_elems :: inline proc(s: ^$S/bit_set[$E; $U], elems: ..E) -> S {
	for elem in elems do s^ |= {elem};
	return s^;
}
@(builtin)
incl_bit_set :: inline proc(s: ^$S/bit_set[$E; $U], other: S) -> S {
	s^ |= other;
	return s^;
}
@(builtin)
excl_elem :: inline proc(s: ^$S/bit_set[$E; $U], elem: E) -> S {
	s^ &~= {elem};
	return s^;
}
@(builtin)
excl_elems :: inline proc(s: ^$S/bit_set[$E; $U], elems: ..E) -> S {
	for elem in elems do s^ &~= {elem};
	return s^;
}
@(builtin)
excl_bit_set :: inline proc(s: ^$S/bit_set[$E; $U], other: S) -> S {
	s^ &~= other;
	return s^;
}

@(builtin) incl :: proc[incl_elem, incl_elems, incl_bit_set];
@(builtin) excl :: proc[excl_elem, excl_elems, excl_bit_set];







@(builtin)
assert :: proc "contextless" (condition: bool, message := "", loc := #caller_location) -> bool {
	if !condition {
		p := context.assertion_failure_proc;
		if p == nil {
			p = default_assertion_failure_proc;
		}
		p("Runtime assertion", message, loc);
	}
	return condition;
}

@(builtin)
panic :: proc "contextless" (message: string, loc := #caller_location) -> ! {
	p := context.assertion_failure_proc;
	if p == nil {
		p = default_assertion_failure_proc;
	}
	p("Panic", message, loc);
}

@(builtin)
unimplemented :: proc "contextless" (message := "", loc := #caller_location) -> ! {
	p := context.assertion_failure_proc;
	if p == nil {
		p = default_assertion_failure_proc;
	}
	p("not yet implemented", message, loc);
}

@(builtin)
unreachable :: proc "contextless" (message := "", loc := #caller_location) -> ! {
	p := context.assertion_failure_proc;
	if p == nil {
		p = default_assertion_failure_proc;
	}
	if message != "" {
		p("internal error", message, loc);
	} else {
		p("internal error", "entered unreachable code", loc);
	}
}


// Dynamic Array


__dynamic_array_make :: proc(array_: rawptr, elem_size, elem_align: int, len, cap: int, loc := #caller_location) {
	array := (^mem.Raw_Dynamic_Array)(array_);
	array.allocator = context.allocator;
	assert(array.allocator.procedure != nil);

	if cap > 0 {
		__dynamic_array_reserve(array_, elem_size, elem_align, cap, loc);
		array.len = len;
	}
}

__dynamic_array_reserve :: proc(array_: rawptr, elem_size, elem_align: int, cap: int, loc := #caller_location) -> bool {
	array := (^mem.Raw_Dynamic_Array)(array_);

	if cap <= array.cap do return true;

	if array.allocator.procedure == nil {
		array.allocator = context.allocator;
	}
	assert(array.allocator.procedure != nil);

	old_size  := array.cap * elem_size;
	new_size  := cap * elem_size;
	allocator := array.allocator;

	new_data := allocator.procedure(allocator.data, mem.Allocator_Mode.Resize, new_size, elem_align, array.data, old_size, 0, loc);
	if new_data == nil do return false;

	array.data = new_data;
	array.cap = cap;
	return true;
}

__dynamic_array_resize :: proc(array_: rawptr, elem_size, elem_align: int, len: int, loc := #caller_location) -> bool {
	array := (^mem.Raw_Dynamic_Array)(array_);

	ok := __dynamic_array_reserve(array_, elem_size, elem_align, len, loc);
	if ok do array.len = len;
	return ok;
}


__dynamic_array_append :: proc(array_: rawptr, elem_size, elem_align: int,
                               items: rawptr, item_count: int, loc := #caller_location) -> int {
	array := (^mem.Raw_Dynamic_Array)(array_);

	if items == nil    do return 0;
	if item_count <= 0 do return 0;


	ok := true;
	if array.cap <= array.len+item_count {
		cap := 2 * array.cap + max(8, item_count);
		ok = __dynamic_array_reserve(array, elem_size, elem_align, cap, loc);
	}
	// TODO(bill): Better error handling for failed reservation
	if !ok do return array.len;

	assert(array.data != nil);
	data := uintptr(array.data) + uintptr(elem_size*array.len);

	mem.copy(rawptr(data), items, elem_size * item_count);
	array.len += item_count;
	return array.len;
}

__dynamic_array_append_nothing :: proc(array_: rawptr, elem_size, elem_align: int, loc := #caller_location) -> int {
	array := (^mem.Raw_Dynamic_Array)(array_);

	ok := true;
	if array.cap <= array.len+1 {
		cap := 2 * array.cap + max(8, 1);
		ok = __dynamic_array_reserve(array, elem_size, elem_align, cap, loc);
	}
	// TODO(bill): Better error handling for failed reservation
	if !ok do return array.len;

	assert(array.data != nil);
	data := uintptr(array.data) + uintptr(elem_size*array.len);
	mem.zero(rawptr(data), elem_size);
	array.len += 1;
	return array.len;
}




// Map

__get_map_header :: proc "contextless" (m: ^$T/map[$K]$V) -> Map_Header {
	header := Map_Header{m = (^mem.Raw_Map)(m)};
	Entry :: struct {
		key:   Map_Key,
		next:  int,
		value: V,
	}

	_, is_string := type_info_base(type_info_of(K)).variant.(Type_Info_String);
	header.is_key_string = is_string;
	header.entry_size    = int(size_of(Entry));
	header.entry_align   = int(align_of(Entry));
	header.value_offset  = uintptr(offset_of(Entry, value));
	header.value_size    = int(size_of(V));
	return header;
}

__get_map_key :: proc "contextless" (key: $K) -> Map_Key {
	map_key: Map_Key;
	ti := type_info_base_without_enum(type_info_of(K));
	switch _ in ti.variant {
	case Type_Info_Integer:
		switch 8*size_of(key) {
		case   8: map_key.hash = u64((  ^u8)(&key)^);
		case  16: map_key.hash = u64(( ^u16)(&key)^);
		case  32: map_key.hash = u64(( ^u32)(&key)^);
		case  64: map_key.hash = u64(( ^u64)(&key)^);
		case: panic("Unhandled integer size");
		}
	case Type_Info_Rune:
		map_key.hash = u64((^rune)(&key)^);
	case Type_Info_Pointer:
		map_key.hash = u64(uintptr((^rawptr)(&key)^));
	case Type_Info_Float:
		switch 8*size_of(key) {
		case 32: map_key.hash = u64((^u32)(&key)^);
		case 64: map_key.hash = u64((^u64)(&key)^);
		case: panic("Unhandled float size");
		}
	case Type_Info_String:
		str := (^string)(&key)^;
		map_key.hash = default_hash_string(str);
		map_key.str  = str;
	case:
		panic("Unhandled map key type");
	}
	return map_key;
}


default_hash :: proc(data: []byte) -> u64 {
	fnv64a :: proc(data: []byte) -> u64 {
		h: u64 = 0xcbf29ce484222325;
		for b in data {
			h = (h ~ u64(b)) * 0x100000001b3;
		}
		return h;
	}
	return fnv64a(data);
}
default_hash_string :: proc(s: string) -> u64 do return default_hash(([]byte)(s));


__slice_resize :: proc(array_: ^$T/[]$E, new_count: int, allocator: mem.Allocator, loc := #caller_location) -> bool {
	array := (^mem.Raw_Slice)(array_);

	if new_count < array.len do return true;

	assert(allocator.procedure != nil);

	old_size := array.len*size_of(T);
	new_size := new_count*size_of(T);

	new_data := mem.resize(array.data, old_size, new_size, align_of(T), allocator, loc);
	if new_data == nil do return false;
	array.data = new_data;
	array.len = new_count;
	return true;
}

__dynamic_map_reserve :: proc(using header: Map_Header, cap: int, loc := #caller_location) {
	__dynamic_array_reserve(&m.entries, entry_size, entry_align, cap, loc);

	old_len := len(m.hashes);
	__slice_resize(&m.hashes, cap, m.entries.allocator, loc);
	for i in old_len..len(m.hashes)-1 do m.hashes[i] = -1;

}
__dynamic_map_rehash :: proc(using header: Map_Header, new_count: int, loc := #caller_location) #no_bounds_check {
	new_header: Map_Header = header;
	nm := mem.Raw_Map{};
	nm.entries.allocator = m.entries.allocator;
	new_header.m = &nm;

	c := context;
	if m.entries.allocator.procedure != nil {
		c.allocator = m.entries.allocator;
	}
	context = c;

	__dynamic_array_reserve(&nm.entries, entry_size, entry_align, m.entries.len, loc);
	__slice_resize(&nm.hashes, new_count, m.entries.allocator, loc);
	for i in 0 .. new_count-1 do nm.hashes[i] = -1;

	for i in 0 .. m.entries.len-1 {
		if len(nm.hashes) == 0 do __dynamic_map_grow(new_header, loc);

		entry_header := __dynamic_map_get_entry(header, i);
		data := uintptr(entry_header);

		fr := __dynamic_map_find(new_header, entry_header.key);
		j := __dynamic_map_add_entry(new_header, entry_header.key, loc);
		if fr.entry_prev < 0 {
			nm.hashes[fr.hash_index] = j;
		} else {
			e := __dynamic_map_get_entry(new_header, fr.entry_prev);
			e.next = j;
		}

		e := __dynamic_map_get_entry(new_header, j);
		e.next = fr.entry_index;
		ndata := uintptr(e);
		mem.copy(rawptr(ndata+value_offset), rawptr(data+value_offset), value_size);

		if __dynamic_map_full(new_header) do __dynamic_map_grow(new_header, loc);
	}
	delete(m.hashes, m.entries.allocator, loc);
	free(m.entries.data, m.entries.allocator, loc);
	header.m^ = nm;
}

__dynamic_map_get :: proc(h: Map_Header, key: Map_Key) -> rawptr {
	index := __dynamic_map_find(h, key).entry_index;
	if index >= 0 {
		data := uintptr(__dynamic_map_get_entry(h, index));
		return rawptr(data + h.value_offset);
	}
	return nil;
}

__dynamic_map_set :: proc(h: Map_Header, key: Map_Key, value: rawptr, loc := #caller_location) #no_bounds_check {

	index: int;
	assert(value != nil);

	if len(h.m.hashes) == 0 {
		__dynamic_map_reserve(h, INITIAL_MAP_CAP, loc);
		__dynamic_map_grow(h, loc);
	}

	fr := __dynamic_map_find(h, key);
	if fr.entry_index >= 0 {
		index = fr.entry_index;
	} else {
		index = __dynamic_map_add_entry(h, key, loc);
		if fr.entry_prev >= 0 {
			entry := __dynamic_map_get_entry(h, fr.entry_prev);
			entry.next = index;
		} else {
			h.m.hashes[fr.hash_index] = index;
		}
	}
	{
		e := __dynamic_map_get_entry(h, index);
		e.key = key;
		val := (^byte)(uintptr(e) + h.value_offset);
		mem.copy(val, value, h.value_size);
	}

	if __dynamic_map_full(h) {
		__dynamic_map_grow(h, loc);
	}
}


__dynamic_map_grow :: proc(using h: Map_Header, loc := #caller_location) {
	// TODO(bill): Determine an efficient growing rate
	new_count := max(4*m.entries.cap + 7, INITIAL_MAP_CAP);
	__dynamic_map_rehash(h, new_count, loc);
}

__dynamic_map_full :: inline proc(using h: Map_Header) -> bool {
	return int(0.75 * f64(len(m.hashes))) <= m.entries.cap;
}


__dynamic_map_hash_equal :: proc(h: Map_Header, a, b: Map_Key) -> bool {
	if a.hash == b.hash {
		if h.is_key_string do return a.str == b.str;
		return true;
	}
	return false;
}

__dynamic_map_find :: proc(using h: Map_Header, key: Map_Key) -> Map_Find_Result #no_bounds_check {
	fr := Map_Find_Result{-1, -1, -1};
	if n := u64(len(m.hashes)); n > 0 {
		fr.hash_index = int(key.hash % n);
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

__dynamic_map_add_entry :: proc(using h: Map_Header, key: Map_Key, loc := #caller_location) -> int {
	prev := m.entries.len;
	c := __dynamic_array_append_nothing(&m.entries, entry_size, entry_align, loc);
	if c != prev {
		end := __dynamic_map_get_entry(h, c-1);
		end.key = key;
		end.next = -1;
	}
	return prev;
}

__dynamic_map_delete_key :: proc(using h: Map_Header, key: Map_Key) {
	fr := __dynamic_map_find(h, key);
	if fr.entry_index >= 0 {
		__dynamic_map_erase(h, fr);
	}
}

__dynamic_map_get_entry :: proc(using h: Map_Header, index: int) -> ^Map_Entry_Header {
	assert(0 <= index && index < m.entries.len);
	return (^Map_Entry_Header)(uintptr(m.entries.data) + uintptr(index*entry_size));
}

__dynamic_map_erase :: proc(using h: Map_Header, fr: Map_Find_Result) #no_bounds_check {
	if fr.entry_prev < 0 {
		m.hashes[fr.hash_index] = __dynamic_map_get_entry(h, fr.entry_index).next;
	} else {
		prev := __dynamic_map_get_entry(h, fr.entry_prev);
		curr := __dynamic_map_get_entry(h, fr.entry_index);
		prev.next = curr.next;
	}
	if (fr.entry_index == m.entries.len-1) {
		// NOTE(bill): No need to do anything else, just pop
	} else {
		old := __dynamic_map_get_entry(h, fr.entry_index);
		end := __dynamic_map_get_entry(h, m.entries.len-1);
		mem.copy(old, end, entry_size);

		if last := __dynamic_map_find(h, old.key); last.entry_prev >= 0 {
			last_entry := __dynamic_map_get_entry(h, last.entry_prev);
			last_entry.next = fr.entry_index;
		} else {
			m.hashes[last.hash_index] = fr.entry_index;
		}
	}

	// TODO(bill): Is this correct behaviour?
	m.entries.len -= 1;
}
