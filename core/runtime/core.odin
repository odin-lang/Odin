// This is the runtime code required by the compiler
// IMPORTANT NOTE(bill): Do not change the order of any of this data
// The compiler relies upon this _exact_ order
package runtime

import "core:os"
import "core:mem"
import "core:log"
import "intrinsics"

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

Platform_Endianness :: enum u8 {
	Platform = 0,
	Little   = 1,
	Big      = 2,
}

Type_Info_Struct_Soa_Kind :: enum u8 {
	None    = 0,
	Fixed   = 1,
	Slice   = 2,
	Dynamic = 3,
}

// Variant Types
Type_Info_Named      :: struct {name: string, base: ^Type_Info};
Type_Info_Integer    :: struct {signed: bool, endianness: Platform_Endianness};
Type_Info_Rune       :: struct {};
Type_Info_Float      :: struct {};
Type_Info_Complex    :: struct {};
Type_Info_Quaternion :: struct {};
Type_Info_String     :: struct {is_cstring: bool};
Type_Info_Boolean    :: struct {};
Type_Info_Any        :: struct {};
Type_Info_Type_Id    :: struct {};
Type_Info_Pointer :: struct {
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
	offsets:      []uintptr,
	usings:       []bool,
	tags:         []string,
	is_packed:    bool,
	is_raw_union: bool,
	custom_align: bool,
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
};
Type_Info_Simd_Vector :: struct {
	elem:       ^Type_Info,
	elem_size:  int,
	count:      int,
	is_x86_mmx: bool,
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
		Type_Info_Quaternion,
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
		Type_Info_Simd_Vector,
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
#assert(len(Typeid_Kind) < 32);

Typeid_Bit_Field :: bit_field #align align_of(uintptr) {
	index:    8*size_of(uintptr) - 8,
	kind:     5, // Typeid_Kind
	named:    1,
	special:  1, // signed, cstring, etc
	reserved: 1,
}
#assert(size_of(Typeid_Bit_Field) == size_of(uintptr));

// NOTE(bill): only the ones that are needed (not all types)
// This will be set by the compiler
type_table: []Type_Info;

args__: []cstring;

// IMPORTANT NOTE(bill): Must be in this order (as the compiler relies upon it)


Source_Code_Location :: struct {
	file_path:    string,
	line, column: int,
	procedure:    string,
	hash:         u64,
}

Assertion_Failure_Proc :: #type proc(prefix, message: string, loc: Source_Code_Location);

Context :: struct {
	allocator:      mem.Allocator,
	temp_allocator: mem.Allocator,
	assertion_failure_proc: Assertion_Failure_Proc,
	logger: log.Logger,

	stdin:  os.Handle,
	stdout: os.Handle,
	stderr: os.Handle,

	thread_id:  int,

	user_data:  any,
	user_ptr:   rawptr,
	user_index: int,

	derived:    any, // May be used for derived data types
}

global_scratch_allocator_data: mem.Scratch_Allocator;



Raw_Slice :: struct {
	data: rawptr,
	len:  int,
}

Raw_Dynamic_Array :: struct {
	data:      rawptr,
	len:       int,
	cap:       int,
	allocator: mem.Allocator,
}

Raw_Map :: struct {
	hashes:  []int,
	entries: Raw_Dynamic_Array,
}

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
	m:             ^Raw_Map,
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


type_info_core :: proc "contextless" (info: ^Type_Info) -> ^Type_Info {
	if info == nil do return nil;

	base := info;
	loop: for {
		switch i in base.variant {
		case Type_Info_Named:  base = i.base;
		case Type_Info_Enum:   base = i.base;
		case Type_Info_Opaque: base = i.elem;
		case: break loop;
		}
	}
	return base;
}
type_info_base_without_enum :: type_info_core;

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
typeid_core :: proc "contextless" (id: typeid) -> typeid {
	ti := type_info_base_without_enum(type_info_of(id));
	return ti.id;
}
typeid_base_without_enum :: typeid_core;



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

	c.stdin  = os.stdin;
	c.stdout = os.stdout;
	c.stderr = os.stderr;
}

@builtin
init_global_temporary_allocator :: proc(data: []byte, backup_allocator := context.allocator) {
	mem.scratch_allocator_init(&global_scratch_allocator_data, data, backup_allocator);
}

default_assertion_failure_proc :: proc(prefix, message: string, loc: Source_Code_Location) {
	fd := context.stderr;
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



@builtin
copy_slice :: proc "contextless" (dst, src: $T/[]$E) -> int {
	n := max(0, min(len(dst), len(src)));
	if n > 0 do mem_copy(&dst[0], &src[0], n*size_of(E));
	return n;
}
@builtin
copy_from_string :: proc "contextless" (dst: $T/[]$E/u8, src: $S/string) -> int {
	n := max(0, min(len(dst), len(src)));
	if n > 0 {
		d := &dst[0];
		s := (transmute(Raw_String)src).data;
		mem_copy(d, s, n);
	}
	return n;
}
@builtin
copy :: proc{copy_slice, copy_from_string};




@builtin
pop :: proc "contextless" (array: ^$T/[dynamic]$E) -> E {
	if array == nil do return E{};
	assert(len(array) > 0);
	res := array[len(array)-1];
	(^Raw_Dynamic_Array)(array).len -= 1;
	return res;
}

@builtin
unordered_remove :: proc(array: ^$D/[dynamic]$T, index: int, loc := #caller_location) {
	bounds_check_error_loc(loc, index, len(array));
	n := len(array)-1;
	if index != n {
		array[index] = array[n];
	}
	pop(array);
}

@builtin
ordered_remove :: proc(array: ^$D/[dynamic]$T, index: int, loc := #caller_location) {
	bounds_check_error_loc(loc, index, len(array));
	if index+1 < len(array) {
		copy(array[index:], array[index+1:]);
	}
	pop(array);
}


@builtin
clear :: proc{clear_dynamic_array, clear_map};

@builtin
reserve :: proc{reserve_dynamic_array, reserve_map};

@builtin
resize :: proc{resize_dynamic_array};


@builtin
new :: proc{mem.new};

@builtin
new_clone :: proc{mem.new_clone};

@builtin
free :: proc{mem.free};

@builtin
free_all :: proc{mem.free_all};

@builtin
delete :: proc{
	mem.delete_string,
	mem.delete_cstring,
	mem.delete_dynamic_array,
	mem.delete_slice,
	mem.delete_map,
};

@builtin
make :: proc{
	mem.make_slice,
	mem.make_dynamic_array,
	mem.make_dynamic_array_len,
	mem.make_dynamic_array_len_cap,
	mem.make_map,
};

@builtin
clear_map :: inline proc "contextless" (m: ^$T/map[$K]$V) {
	if m == nil do return;
	raw_map := (^Raw_Map)(m);
	entries := (^Raw_Dynamic_Array)(&raw_map.entries);
	entries.len = 0;
	for _, i in raw_map.hashes {
		raw_map.hashes[i] = -1;
	}
}

@builtin
reserve_map :: proc(m: ^$T/map[$K]$V, capacity: int) {
	if m != nil do __dynamic_map_reserve(__get_map_header(m), capacity);
}

@builtin
delete_key :: proc(m: ^$T/map[$K]$V, key: K) {
	if m != nil do __dynamic_map_delete_key(__get_map_header(m), __get_map_key(key));
}



@builtin
append_elem :: proc(array: ^$T/[dynamic]$E, arg: E, loc := #caller_location)  {
	if array == nil do return;

	arg_len := 1;

	if cap(array) <= len(array)+arg_len {
		cap := 2 * cap(array) + max(8, arg_len);
		_ = reserve(array, cap, loc);
	}
	arg_len = min(cap(array)-len(array), arg_len);
	if arg_len > 0 {
		a := (^Raw_Dynamic_Array)(array);
		data := (^E)(a.data);
		assert(data != nil);
		val := arg;
		mem_copy(mem.ptr_offset(data, a.len), &val, size_of(E));
		a.len += arg_len;
	}
}
@builtin
append_elems :: proc(array: ^$T/[dynamic]$E, args: ..E, loc := #caller_location)  {
	if array == nil do return;

	arg_len := len(args);
	if arg_len <= 0 do return;


	if cap(array) <= len(array)+arg_len {
		cap := 2 * cap(array) + max(8, arg_len);
		_ = reserve(array, cap, loc);
	}
	arg_len = min(cap(array)-len(array), arg_len);
	if arg_len > 0 {
		a := (^Raw_Dynamic_Array)(array);
		data := (^E)(a.data);
		assert(data != nil);
		mem_copy(mem.ptr_offset(data, a.len), &args[0], size_of(E) * arg_len);
		a.len += arg_len;
	}
}
@builtin
append_elem_string :: proc(array: ^$T/[dynamic]$E/u8, arg: $A/string, loc := #caller_location) {
	args := transmute([]E)arg;
	append_elems(array=array, args=args, loc=loc);
}

@builtin
reserve_soa :: proc(array: ^$T/#soa[dynamic]$E, capacity: int, loc := #caller_location) -> bool {
	if array == nil do return false;

	old_cap := cap(array);
	if capacity <= old_cap do return true;

	if array.allocator.procedure == nil {
		array.allocator = context.allocator;
	}
	assert(array.allocator.procedure != nil);


	ti := type_info_of(typeid_of(T));
	ti = type_info_base(ti);
	si := &ti.variant.(Type_Info_Struct);

	field_count := uintptr(len(si.offsets) - 3);

	if field_count == 0 {
		return true;
	}

	cap_ptr := cast(^int)rawptr(uintptr(array) + (field_count + 1)*size_of(rawptr));
	assert(cap_ptr^ == old_cap);


	old_size := 0;
	new_size := 0;

	max_align := 0;
	for i in 0..<field_count {
		type := si.types[i].variant.(Type_Info_Pointer).elem;
		max_align = max(max_align, type.align);

		old_size = mem.align_forward_int(old_size, type.align);
		new_size = mem.align_forward_int(new_size, type.align);

		old_size += type.size * old_cap;
		new_size += type.size * capacity;
	}

	old_size = mem.align_forward_int(old_size, max_align);
	new_size = mem.align_forward_int(new_size, max_align);

	old_data := (^rawptr)(array)^;

	new_data := array.allocator.procedure(
		array.allocator.data, mem.Allocator_Mode.Alloc, new_size, max_align,
		nil, old_size, 0, loc,
	);
	if new_data == nil do return false;


	cap_ptr^ = capacity;

	old_offset := 0;
	new_offset := 0;
	for i in 0..<field_count {
		type := si.types[i].variant.(Type_Info_Pointer).elem;
		max_align = max(max_align, type.align);

		old_offset = mem.align_forward_int(old_offset, type.align);
		new_offset = mem.align_forward_int(new_offset, type.align);

		new_data_elem := rawptr(uintptr(new_data) + uintptr(new_offset));
		old_data_elem := rawptr(uintptr(old_data) + uintptr(old_offset));

		mem_copy(new_data_elem, old_data_elem, type.size * old_cap);

		(^rawptr)(uintptr(array) + i*size_of(rawptr))^ = new_data_elem;

		old_offset += type.size * old_cap;
		new_offset += type.size * capacity;
	}

	array.allocator.procedure(
		array.allocator.data, mem.Allocator_Mode.Free, 0, max_align,
		old_data, old_size, 0, loc,
	);

	return true;
}

@builtin
append_soa_elem :: proc(array: ^$T/#soa[dynamic]$E, arg: E, loc := #caller_location) {
	if array == nil do return;

	arg_len := 1;

	if cap(array) <= len(array)+arg_len {
		cap := 2 * cap(array) + max(8, arg_len);
		_ = reserve_soa(array, cap, loc);
	}
	arg_len = min(cap(array)-len(array), arg_len);
	if arg_len > 0 {
		ti := type_info_of(typeid_of(T));
		ti = type_info_base(ti);
		si := &ti.variant.(Type_Info_Struct);
		field_count := uintptr(len(si.offsets) - 3);

		if field_count == 0 {
			return;
		}

		data := (^rawptr)(array)^;

		len_ptr := cast(^int)rawptr(uintptr(array) + (field_count + 0)*size_of(rawptr));


		soa_offset := 0;
		item_offset := 0;

		arg_copy := arg;
		arg_ptr := &arg_copy;

		max_align := 0;
		for i in 0..<field_count {
			type := si.types[i].variant.(Type_Info_Pointer).elem;
			max_align = max(max_align, type.align);

			soa_offset  = mem.align_forward_int(soa_offset, type.align);
			item_offset = mem.align_forward_int(item_offset, type.align);

			dst := rawptr(uintptr(data) + uintptr(soa_offset) + uintptr(type.size * len_ptr^));
			src := rawptr(uintptr(arg_ptr) + uintptr(item_offset));
			mem_copy(dst, src, type.size);

			soa_offset  += type.size * cap(array);
			item_offset += type.size;
		}

		len_ptr^ += arg_len;
	}
}

@builtin
append_soa_elems :: proc(array: ^$T/#soa[dynamic]$E, args: ..E, loc := #caller_location) {
	if array == nil do return;

	arg_len := len(args);
	if arg_len == 0 {
		return;
	}

	if cap(array) <= len(array)+arg_len {
		cap := 2 * cap(array) + max(8, arg_len);
		_ = reserve_soa(array, cap, loc);
	}
	arg_len = min(cap(array)-len(array), arg_len);
	if arg_len > 0 {
		ti := type_info_of(typeid_of(T));
		ti = type_info_base(ti);
		si := &ti.variant.(Type_Info_Struct);
		field_count := uintptr(len(si.offsets) - 3);

		if field_count == 0 {
			return;
		}

		data := (^rawptr)(array)^;

		len_ptr := cast(^int)rawptr(uintptr(array) + (field_count + 0)*size_of(rawptr));


		soa_offset := 0;
		item_offset := 0;

		args_ptr := &args[0];

		max_align := 0;
		for i in 0..<field_count {
			type := si.types[i].variant.(Type_Info_Pointer).elem;
			max_align = max(max_align, type.align);

			soa_offset  = mem.align_forward_int(soa_offset, type.align);
			item_offset = mem.align_forward_int(item_offset, type.align);

			dst := uintptr(data) + uintptr(soa_offset) + uintptr(type.size * len_ptr^);
			src := uintptr(args_ptr) + uintptr(item_offset);
			for j in 0..<arg_len {
				d := rawptr(dst + uintptr(j*type.size));
				s := rawptr(src + uintptr(j*size_of(E)));
				mem_copy(d, s, type.size);
			}

			soa_offset  += type.size * cap(array);
			item_offset += type.size;
		}

		len_ptr^ += arg_len;
	}
}

@builtin append :: proc{append_elem, append_elems, append_elem_string};
@builtin append_soa :: proc{append_soa_elem, append_soa_elems};



@builtin
append_string :: proc(array: ^$T/[dynamic]$E/u8, args: ..string, loc := #caller_location) {
	for arg in args {
		append(array = array, args = ([]E)(arg), loc = loc);
	}
}

@builtin
clear_dynamic_array :: inline proc "contextless" (array: ^$T/[dynamic]$E) {
	if array != nil do (^Raw_Dynamic_Array)(array).len = 0;
}

@builtin
reserve_dynamic_array :: proc(array: ^$T/[dynamic]$E, capacity: int, loc := #caller_location) -> bool {
	if array == nil do return false;
	a := (^Raw_Dynamic_Array)(array);

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

@builtin
resize_dynamic_array :: proc(array: ^$T/[dynamic]$E, length: int, loc := #caller_location) -> bool {
	if array == nil do return false;
	a := (^Raw_Dynamic_Array)(array);

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



@builtin
incl_elem :: inline proc(s: ^$S/bit_set[$E; $U], elem: E) -> S {
	s^ |= {elem};
	return s^;
}
@builtin
incl_elems :: inline proc(s: ^$S/bit_set[$E; $U], elems: ..E) -> S {
	for elem in elems do s^ |= {elem};
	return s^;
}
@builtin
incl_bit_set :: inline proc(s: ^$S/bit_set[$E; $U], other: S) -> S {
	s^ |= other;
	return s^;
}
@builtin
excl_elem :: inline proc(s: ^$S/bit_set[$E; $U], elem: E) -> S {
	s^ &~= {elem};
	return s^;
}
@builtin
excl_elems :: inline proc(s: ^$S/bit_set[$E; $U], elems: ..E) -> S {
	for elem in elems do s^ &~= {elem};
	return s^;
}
@builtin
excl_bit_set :: inline proc(s: ^$S/bit_set[$E; $U], other: S) -> S {
	s^ &~= other;
	return s^;
}

@builtin incl :: proc{incl_elem, incl_elems, incl_bit_set};
@builtin excl :: proc{excl_elem, excl_elems, excl_bit_set};


@builtin
card :: proc(s: $S/bit_set[$E; $U]) -> int {
	when size_of(S) == 1 {
		foreign { @(link_name="llvm.ctpop.i8")  count_ones :: proc(i: u8) -> u8 --- }
		return int(count_ones(transmute(u8)s));
	} else when size_of(S) == 2 {
		foreign { @(link_name="llvm.ctpop.i16") count_ones :: proc(i: u16) -> u16 --- }
		return int(count_ones(transmute(u16)s));
	} else when size_of(S) == 4 {
		foreign { @(link_name="llvm.ctpop.i32") count_ones :: proc(i: u32) -> u32 --- }
		return int(count_ones(transmute(u32)s));
	} else when size_of(S) == 8 {
		foreign { @(link_name="llvm.ctpop.i64") count_ones :: proc(i: u64) -> u64 --- }
		return int(count_ones(transmute(u64)s));
	} else {
		#assert(false);
		return 0;
	}
}






@builtin
assert :: proc(condition: bool, message := "", loc := #caller_location) -> bool {
	if !condition {
		proc(message: string, loc: Source_Code_Location) {
			p := context.assertion_failure_proc;
			if p == nil {
				p = default_assertion_failure_proc;
			}
			p("runtime assertion", message, loc);
		}(message, loc);
	}
	return condition;
}

@builtin
panic :: proc(message: string, loc := #caller_location) -> ! {
	p := context.assertion_failure_proc;
	if p == nil {
		p = default_assertion_failure_proc;
	}
	p("panic", message, loc);
}

@builtin
unimplemented :: proc(message := "", loc := #caller_location) -> ! {
	p := context.assertion_failure_proc;
	if p == nil {
		p = default_assertion_failure_proc;
	}
	p("not yet implemented", message, loc);
}

@builtin
unreachable :: proc(message := "", loc := #caller_location) -> ! {
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
	array := (^Raw_Dynamic_Array)(array_);
	array.allocator = context.allocator;
	assert(array.allocator.procedure != nil);

	if cap > 0 {
		__dynamic_array_reserve(array_, elem_size, elem_align, cap, loc);
		array.len = len;
	}
}

__dynamic_array_reserve :: proc(array_: rawptr, elem_size, elem_align: int, cap: int, loc := #caller_location) -> bool {
	array := (^Raw_Dynamic_Array)(array_);

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
	array := (^Raw_Dynamic_Array)(array_);

	ok := __dynamic_array_reserve(array_, elem_size, elem_align, len, loc);
	if ok do array.len = len;
	return ok;
}


__dynamic_array_append :: proc(array_: rawptr, elem_size, elem_align: int,
                               items: rawptr, item_count: int, loc := #caller_location) -> int {
	array := (^Raw_Dynamic_Array)(array_);

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

	mem_copy(rawptr(data), items, elem_size * item_count);
	array.len += item_count;
	return array.len;
}

__dynamic_array_append_nothing :: proc(array_: rawptr, elem_size, elem_align: int, loc := #caller_location) -> int {
	array := (^Raw_Dynamic_Array)(array_);

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
	header := Map_Header{m = (^Raw_Map)(m)};
	Entry :: struct {
		key:   Map_Key,
		next:  int,
		value: V,
	};

	header.is_key_string = intrinsics.type_is_string(K);
	header.entry_size    = int(size_of(Entry));
	header.entry_align   = int(align_of(Entry));
	header.value_offset  = uintptr(offset_of(Entry, value));
	header.value_size    = int(size_of(V));
	return header;
}

__get_map_key :: proc "contextless" (k: $K) -> Map_Key {
	key := k;
	map_key: Map_Key;

	T :: intrinsics.type_core_type(K);

	when intrinsics.type_is_integer(T) {
		sz :: 8*size_of(T);
		     when sz ==  8 do map_key.hash = u64(( ^u8)(&key)^);
		else when sz == 16 do map_key.hash = u64((^u16)(&key)^);
		else when sz == 32 do map_key.hash = u64((^u32)(&key)^);
		else when sz == 64 do map_key.hash = u64((^u64)(&key)^);
		else do #assert(false, "Unhandled integer size");
	} else when intrinsics.type_is_rune(T) {
		map_key.hash = u64((^rune)(&key)^);
	} else when intrinsics.type_is_pointer(T) {
		map_key.hash = u64(uintptr((^rawptr)(&key)^));
	} else when intrinsics.type_is_float(T) {
		sz :: 8*size_of(T);
		     when sz == 32 do map_key.hash = u64((^u32)(&key)^);
		else when sz == 64 do map_key.hash = u64((^u64)(&key)^);
		else do #assert(false, "Unhandled float size");
	} else when intrinsics.type_is_string(T) {
		#assert(T == string);
		str := (^string)(&key)^;
		map_key.hash = default_hash_string(str);
		map_key.str  = str;
	} else {
		#assert(false, "Unhandled map key type");
	}

	return map_key;
}

_fnv64a :: proc(data: []byte, seed: u64 = 0xcbf29ce484222325) -> u64 {
	h: u64 = seed;
	for b in data {
		h = (h ~ u64(b)) * 0x100000001b3;
	}
	return h;
}


default_hash :: proc(data: []byte) -> u64 {
	return _fnv64a(data);
}
default_hash_string :: proc(s: string) -> u64 do return default_hash(transmute([]byte)(s));


source_code_location_hash :: proc(s: Source_Code_Location) -> u64 {
	hash := _fnv64a(transmute([]byte)s.file_path);
	hash = hash ~ (u64(s.line) * 0x100000001b3);
	hash = hash ~ (u64(s.column) * 0x100000001b3);
	return hash;
}



__slice_resize :: proc(array_: ^$T/[]$E, new_count: int, allocator: mem.Allocator, loc := #caller_location) -> bool {
	array := (^Raw_Slice)(array_);

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
	for i in old_len..<len(m.hashes) do m.hashes[i] = -1;

}
__dynamic_map_rehash :: proc(using header: Map_Header, new_count: int, loc := #caller_location) #no_bounds_check {
	new_header: Map_Header = header;
	nm := Raw_Map{};
	nm.entries.allocator = m.entries.allocator;
	new_header.m = &nm;

	c := context;
	if m.entries.allocator.procedure != nil {
		c.allocator = m.entries.allocator;
	}
	context = c;

	__dynamic_array_reserve(&nm.entries, entry_size, entry_align, m.entries.len, loc);
	__slice_resize(&nm.hashes, new_count, m.entries.allocator, loc);
	for i in 0 ..< new_count do nm.hashes[i] = -1;

	for i in 0 ..< m.entries.len {
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
		mem_copy(rawptr(ndata+value_offset), rawptr(data+value_offset), value_size);

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
		mem_copy(val, value, h.value_size);
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
		mem_copy(old, end, entry_size);

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
