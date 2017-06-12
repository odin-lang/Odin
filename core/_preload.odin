#shared_global_scope;

#import "os.odin";
#import "fmt.odin";
#import "utf8.odin";
#import "raw.odin";

// Naming Conventions:
// In general, PascalCase for types and snake_case for values
//
// Import Name:        snake_case (but prefer single word)
// Types:              PascalCase
// Union Variants:     PascalCase
// Enum Values:        PascalCase
// Procedures:         snake_case
// Local Variables:    snake_case
// Constant Variables: SCREAMING_SNAKE_CASE

// IMPORTANT NOTE(bill): `type_info` & `type_info_val` cannot be used within a
// #shared_global_scope due to  the internals of the compiler.
// This could change at a later date if the all these data structures are
// implemented within the compiler rather than in this "preload" file


// IMPORTANT NOTE(bill): Do not change the order of any of this data
// The compiler relies upon this _exact_ order
const TypeInfoEnumValue = raw_union {
	f: f64,
	i: i128,
}
// NOTE(bill): This must match the compiler's
const CallingConvention = enum {
	Odin = 0,
	C    = 1,
	Std  = 2,
	Fast = 3,
}

const TypeInfoRecord = struct #ordered {
	types:        []^TypeInfo,
	names:        []string,
	offsets:      []int,  // offsets may not be used in tuples
	usings:       []bool, // usings may not be used in tuples
	packed:       bool,
	ordered:      bool,
	custom_align: bool,
}

const TypeInfo = union {
	size:  int,
	align: int,

	Named{name: string, base: ^TypeInfo},
	Integer{signed: bool},
	Rune{},
	Float{},
	Complex{},
	String{},
	Boolean{},
	Any{},
	Pointer{
		elem: ^TypeInfo, // nil -> rawptr
	},
	Atomic{elem: ^TypeInfo},
	Procedure{
		params:     ^TypeInfo, // TypeInfo.Tuple
		results:    ^TypeInfo, // TypeInfo.Tuple
		variadic:   bool,
		convention: CallingConvention,
	},
	Array{
		elem:      ^TypeInfo,
		elem_size: int,
		count:     int,
	},
	DynamicArray{elem: ^TypeInfo, elem_size: int},
	Slice       {elem: ^TypeInfo, elem_size: int},
	Vector      {elem: ^TypeInfo, elem_size, count: int},
	Tuple       {using record: TypeInfoRecord}, // Only really used for procedures
	Struct      {using record: TypeInfoRecord},
	RawUnion    {using record: TypeInfoRecord},
	Union{
		common_fields: struct {
			types:     []^TypeInfo,
			names:     []string,
			offsets:   []int,    // offsets may not be used in tuples
		},
		variant_names: []string,
		variant_types: []^TypeInfo,
	},
	Enum{
		base:   ^TypeInfo,
		names:  []string,
		values: []TypeInfoEnumValue,
	},
	Map{
		key:              ^TypeInfo,
		value:            ^TypeInfo,
		generated_struct: ^TypeInfo,
		count:            int, // == 0 if dynamic
	},
	BitField{
		names:   []string,
		bits:    []i32,
		offsets: []i32,
	},
}


// NOTE(bill): only the ones that are needed (not all types)
// This will be set by the compiler
var __type_table: []TypeInfo;

var __argv__: ^^u8;
var __argc__: i32;

const type_info_base = proc(info: ^TypeInfo) -> ^TypeInfo {
	if info == nil {
		return nil;
	}
	var base = info;
	match i in base {
	case TypeInfo.Named:
		base = i.base;
	}
	return base;
}


const type_info_base_without_enum = proc(info: ^TypeInfo) -> ^TypeInfo {
	if info == nil {
		return nil;
	}
	var base = info;
	match i in base {
	case TypeInfo.Named:
		base = i.base;
	case TypeInfo.Enum:
		base = i.base;
	}
	return base;
}



const assume = proc(cond: bool) #foreign __llvm_core "llvm.assume";

const __debug_trap       = proc()        #foreign __llvm_core "llvm.debugtrap";
const __trap             = proc()        #foreign __llvm_core "llvm.trap";
const read_cycle_counter = proc() -> u64 #foreign __llvm_core "llvm.readcyclecounter";


// IMPORTANT NOTE(bill): Must be in this order (as the compiler relies upon it)
const AllocatorMode = enum u8 {
	Alloc,
	Free,
	FreeAll,
	Resize,
}
const AllocatorProc = type proc(allocator_data: rawptr, mode: AllocatorMode,
                           size, alignment: int,
                           old_memory: rawptr, old_size: int, flags: u64) -> rawptr;
const Allocator = struct #ordered {
	procedure: AllocatorProc,
	data:      rawptr,
}


const Context = struct #ordered {
	thread_id: int,

	allocator: Allocator,

	user_data:  rawptr,
	user_index: int,
}

#thread_local var __context: Context;


const DEFAULT_ALIGNMENT = align_of([vector 4]f32);


const __check_context = proc() {
	var c = &__context;

	if c.allocator.procedure == nil {
		c.allocator = default_allocator();
	}
	if c.thread_id == 0 {
		c.thread_id = os.current_thread_id();
	}
}

const alloc = proc(size: int) -> rawptr #inline { return alloc_align(size, DEFAULT_ALIGNMENT); }

const alloc_align = proc(size, alignment: int) -> rawptr #inline {
	__check_context();
	var a = context.allocator;
	return a.procedure(a.data, AllocatorMode.Alloc, size, alignment, nil, 0, 0);
}

const free_ptr_with_allocator = proc(a: Allocator, ptr: rawptr) #inline {
	if ptr == nil {
		return;
	}
	if a.procedure == nil {
		return;
	}
	a.procedure(a.data, AllocatorMode.Free, 0, 0, ptr, 0, 0);
}

const free_ptr = proc(ptr: rawptr) #inline {
	__check_context();
	free_ptr_with_allocator(context.allocator, ptr);
}

const free_all = proc() #inline {
	__check_context();
	var a = context.allocator;
	a.procedure(a.data, AllocatorMode.FreeAll, 0, 0, nil, 0, 0);
}


const resize       = proc(ptr: rawptr, old_size, new_size: int) -> rawptr #inline { return resize_align(ptr, old_size, new_size, DEFAULT_ALIGNMENT); }
const resize_align = proc(ptr: rawptr, old_size, new_size, alignment: int) -> rawptr #inline {
	__check_context();
	var a = context.allocator;
	return a.procedure(a.data, AllocatorMode.Resize, new_size, alignment, ptr, old_size, 0);
}



const default_resize_align = proc(old_memory: rawptr, old_size, new_size, alignment: int) -> rawptr {
	if old_memory == nil {
		return alloc_align(new_size, alignment);
	}

	if new_size == 0 {
		free(old_memory);
		return nil;
	}

	if new_size == old_size {
		return old_memory;
	}

	var new_memory = alloc_align(new_size, alignment);
	if new_memory == nil {
		return nil;
	}

	__mem_copy(new_memory, old_memory, min(old_size, new_size));;
	free(old_memory);
	return new_memory;
}


const default_allocator_proc = proc(allocator_data: rawptr, mode: AllocatorMode,
                               size, alignment: int,
                               old_memory: rawptr, old_size: int, flags: u64) -> rawptr {
	using AllocatorMode;

	match mode {
	case Alloc:
		return os.heap_alloc(size);

	case Free:
		os.heap_free(old_memory);
		return nil;

	case FreeAll:
		// NOTE(bill): Does nothing

	case Resize:
		var ptr = os.heap_resize(old_memory, size);
		assert(ptr != nil);
		return ptr;
	}

	return nil;
}

const default_allocator = proc() -> Allocator {
	return Allocator{
		procedure = default_allocator_proc,
		data = nil,
	};
}









const __string_eq = proc(a, b: string) -> bool {
	if len(a) != len(b) {
		return false;
	}
	if len(a) == 0 {
		return true;
	}
	if &a[0] == &b[0] {
		return true;
	}
	return __string_cmp(a, b) == 0;
}

const __string_cmp = proc(a, b: string) -> int {
	return __mem_compare(&a[0], &b[0], min(len(a), len(b)));
}

const __string_ne = proc(a, b: string) -> bool #inline { return !__string_eq(a, b); }
const __string_lt = proc(a, b: string) -> bool #inline { return __string_cmp(a, b) < 0; }
const __string_gt = proc(a, b: string) -> bool #inline { return __string_cmp(a, b) > 0; }
const __string_le = proc(a, b: string) -> bool #inline { return __string_cmp(a, b) <= 0; }
const __string_ge = proc(a, b: string) -> bool #inline { return __string_cmp(a, b) >= 0; }


const __complex64_eq  = proc(a, b: complex64)  -> bool #inline { return real(a) == real(b) && imag(a) == imag(b); }
const __complex64_ne  = proc(a, b: complex64)  -> bool #inline { return real(a) != real(b) || imag(a) != imag(b); }

const __complex128_eq = proc(a, b: complex128) -> bool #inline { return real(a) == real(b) && imag(a) == imag(b); }
const __complex128_ne = proc(a, b: complex128) -> bool #inline { return real(a) != real(b) || imag(a) != imag(b); }

const __assert = proc(file: string, line, column: int, msg: string) #inline {
	fmt.fprintf(os.stderr, "%s(%d:%d) Runtime assertion: %s\n",
	            file, line, column, msg);
	__debug_trap();
}
const __panic = proc(file: string, line, column: int, msg: string) #inline {
	fmt.fprintf(os.stderr, "%s(%d:%d) Panic: %s\n",
	            file, line, column, msg);
	__debug_trap();
}
const __bounds_check_error = proc(file: string, line, column: int, index, count: int) {
	if 0 <= index && index < count {
		return;
	}
	fmt.fprintf(os.stderr, "%s(%d:%d) Index %d is out of bounds range 0..<%d\n",
	            file, line, column, index, count);
	__debug_trap();
}

const __slice_expr_error = proc(file: string, line, column: int, low, high, max: int) {
	if 0 <= low && low <= high && high <= max {
		return;
	}
	fmt.fprintf(os.stderr, "%s(%d:%d) Invalid slice indices: [%d..<%d..<%d]\n",
	            file, line, column, low, high, max);
	__debug_trap();
}

const __substring_expr_error = proc(file: string, line, column: int, low, high: int) {
	if 0 <= low && low <= high {
		return;
	}
	fmt.fprintf(os.stderr, "%s(%d:%d) Invalid substring indices: [%d..<%d]\n",
	            file, line, column, low, high);
	__debug_trap();
}
const __type_assertion_check = proc(ok: bool, file: string, line, column: int, from, to: ^TypeInfo) {
	if !ok {
		fmt.fprintf(os.stderr, "%s(%d:%d) Invalid type_assertion from %T to %T\n",
		            file, line, column, from, to);
		__debug_trap();
	}
}

const __string_decode_rune = proc(s: string) -> (rune, int) #inline {
	return utf8.decode_rune(s);
}


const __mem_set = proc(data: rawptr, value: i32, len: int) -> rawptr {
	const llvm_memset_64bit = proc(dst: rawptr, val: u8, len: int, align: i32, is_volatile: bool) #foreign __llvm_core "llvm.memset.p0i8.i64";
	llvm_memset_64bit(data, u8(value), len, 1, false);
	return data;
}
const __mem_zero = proc(data: rawptr, len: int) -> rawptr {
	return __mem_set(data, 0, len);
}
const __mem_copy = proc(dst, src: rawptr, len: int) -> rawptr {
	// NOTE(bill): This _must_ be implemented like C's memmove
	const llvm_memmove_64bit = proc(dst, src: rawptr, len: int, align: i32, is_volatile: bool) #foreign __llvm_core "llvm.memmove.p0i8.p0i8.i64";
	llvm_memmove_64bit(dst, src, len, 1, false);
	return dst;
}
const __mem_copy_non_overlapping = proc(dst, src: rawptr, len: int) -> rawptr {
	// NOTE(bill): This _must_ be implemented like C's memcpy
	const llvm_memcpy_64bit = proc(dst, src: rawptr, len: int, align: i32, is_volatile: bool) #foreign __llvm_core "llvm.memcpy.p0i8.p0i8.i64";
	llvm_memcpy_64bit(dst, src, len, 1, false);
	return dst;
}

const __mem_compare = proc(a, b: ^u8, n: int) -> int {
	for i in 0..<n {
		match {
		case (a+i)^ < (b+i)^:
			return -1;
		case (a+i)^ > (b+i)^:
			return +1;
		}
	}
	return 0;
}

const __sqrt_f32 = proc(x: f32) -> f32 #foreign __llvm_core "llvm.sqrt.f32";
const __sqrt_f64 = proc(x: f64) -> f64 #foreign __llvm_core "llvm.sqrt.f64";
const __abs_complex64 = proc(x: complex64) -> f32 #inline {
	var r, i = real(x), imag(x);
	return __sqrt_f32(r*r + i*i);
}
const __abs_complex128 = proc(x: complex128) -> f64 #inline {
	var r, i = real(x), imag(x);
	return __sqrt_f64(r*r + i*i);
}




const __dynamic_array_make = proc(array_: rawptr, elem_size, elem_align: int, len, cap: int) {
	var array = ^raw.DynamicArray(array_);
	__check_context();
	array.allocator = context.allocator;
	assert(array.allocator.procedure != nil);

	if cap > 0 {
		__dynamic_array_reserve(array_, elem_size, elem_align, cap);
		array.len = len;
	}
}

const __dynamic_array_reserve = proc(array_: rawptr, elem_size, elem_align: int, cap: int) -> bool {
	var array = ^raw.DynamicArray(array_);

	if cap <= array.cap {
		return true;
	}

	__check_context();
	if array.allocator.procedure == nil {
		array.allocator = context.allocator;
	}
	assert(array.allocator.procedure != nil);

	var old_size  = array.cap * elem_size;
	var new_size  = cap * elem_size;
	var allocator = array.allocator;

	var new_data = allocator.procedure(allocator.data, AllocatorMode.Resize, new_size, elem_align, array.data, old_size, 0);
	if new_data == nil {
		return false;
	}

	array.data = new_data;
	array.cap = cap;
	return true;
}

const __dynamic_array_resize = proc(array_: rawptr, elem_size, elem_align: int, len: int) -> bool {
	var array = ^raw.DynamicArray(array_);

	var ok = __dynamic_array_reserve(array_, elem_size, elem_align, len);
	if ok {
		array.len = len;
	}
	return ok;
}


const __dynamic_array_append = proc(array_: rawptr, elem_size, elem_align: int,
                               items: rawptr, item_count: int) -> int {
	var array = ^raw.DynamicArray(array_);

	if item_count <= 0 || items == nil {
		return array.len;
	}


	var ok = true;
	if array.cap <= array.len+item_count {
		var cap = 2 * array.cap + max(8, item_count);
		ok = __dynamic_array_reserve(array, elem_size, elem_align, cap);
	}
	if !ok {
		// TODO(bill): Better error handling for failed reservation
		return array.len;
	}
	var data = ^u8(array.data);
	assert(data != nil);
	__mem_copy(data + (elem_size*array.len), items, elem_size * item_count);
	array.len += item_count;
	return array.len;
}

const __dynamic_array_append_nothing = proc(array_: rawptr, elem_size, elem_align: int) -> int {
	var array = ^raw.DynamicArray(array_);

	var ok = true;
	if array.cap <= array.len+1 {
		var cap = 2 * array.cap + max(8, 1);
		ok = __dynamic_array_reserve(array, elem_size, elem_align, cap);
	}
	if !ok {
		// TODO(bill): Better error handling for failed reservation
		return array.len;
	}
	var data = ^u8(array.data);
	assert(data != nil);
	__mem_zero(data + (elem_size*array.len), elem_size);
	array.len++;
	return array.len;
}

const __slice_append = proc(slice_: rawptr, elem_size, elem_align: int,
                       items: rawptr, item_count: int) -> int {
	var slice = ^raw.Slice(slice_);

	if item_count <= 0 || items == nil {
		return slice.len;
	}

	item_count = min(slice.cap-slice.len, item_count);
	if item_count > 0 {
		var data = ^u8(slice.data);
		assert(data != nil);
		__mem_copy(data + (elem_size*slice.len), items, elem_size * item_count);
		slice.len += item_count;
	}
	return slice.len;
}


// Map stuff

const __default_hash = proc(data: []u8) -> u128 {
	const fnv128a = proc(data: []u8) -> u128 {
		var h: u128 = 0x6c62272e07bb014262b821756295c58d;
		for b in data {
			h = (h ~ u128(b)) * 0x1000000000000000000013b;
		}
		return h;
	}
	return fnv128a(data);
}
const __default_hash_string = proc(s: string) -> u128 {
	return __default_hash([]u8(s));
}

const __INITIAL_MAP_CAP = 16;

const __MapKey = struct #ordered {
	hash: u128,
	str:  string,
}

const __MapFindResult = struct #ordered {
	hash_index:  int,
	entry_prev:  int,
	entry_index: int,
}

const __MapEntryHeader = struct #ordered {
	key:  __MapKey,
	next: int,
/*
	value: Value_Type,
*/
}

const __MapHeader = struct #ordered {
	m:             ^raw.DynamicMap,
	is_key_string: bool,
	entry_size:    int,
	entry_align:   int,
	value_offset:  int,
	value_size:    int,
}

const __dynamic_map_reserve = proc(using header: __MapHeader, cap: int)  {
	__dynamic_array_reserve(&m.hashes, size_of(int), align_of(int), cap);
	__dynamic_array_reserve(&m.entries, entry_size, entry_align,    cap);
}

const __dynamic_map_rehash = proc(using header: __MapHeader, new_count: int) {
	var new_header: __MapHeader = header;
	var nm: raw.DynamicMap;
	new_header.m = &nm;

	var header_hashes = ^raw.DynamicArray(&header.m.hashes);
	var nm_hashes = ^raw.DynamicArray(&nm.hashes);

	__dynamic_array_resize(nm_hashes, size_of(int), align_of(int), new_count);
	__dynamic_array_reserve(&nm.entries, entry_size, entry_align, m.entries.len);
	for i in 0..<new_count {
		nm.hashes[i] = -1;
	}

	for var i = 0; i < m.entries.len; i++ {
		if len(nm.hashes) == 0 {
			__dynamic_map_grow(new_header);
		}

		var entry_header = __dynamic_map_get_entry(header, i);
		var data = ^u8(entry_header);

		var fr = __dynamic_map_find(new_header, entry_header.key);
		var j = __dynamic_map_add_entry(new_header, entry_header.key);
		if fr.entry_prev < 0 {
			nm.hashes[fr.hash_index] = j;
		} else {
			var e = __dynamic_map_get_entry(new_header, fr.entry_prev);
			e.next = j;
		}

		var e = __dynamic_map_get_entry(new_header, j);
		e.next = fr.entry_index;
		var ndata = ^u8(e);
		__mem_copy(ndata+value_offset, data+value_offset, value_size);

		if __dynamic_map_full(new_header) {
			__dynamic_map_grow(new_header);
		}
	}
	free_ptr_with_allocator(header_hashes.allocator, header_hashes.data);
	free_ptr_with_allocator(header.m.entries.allocator, header.m.entries.data);
	header.m^ = nm;
}

const __dynamic_map_get = proc(h: __MapHeader, key: __MapKey) -> rawptr {
	var index = __dynamic_map_find(h, key).entry_index;
	if index >= 0 {
		var data = ^u8(__dynamic_map_get_entry(h, index));
		var val = data + h.value_offset;
		return val;
	}
	return nil;
}

const __dynamic_map_set = proc(using h: __MapHeader, key: __MapKey, value: rawptr) {
	var index: int;
	assert(value != nil);


	if len(m.hashes) == 0 {
		__dynamic_map_reserve(h, __INITIAL_MAP_CAP);
		__dynamic_map_grow(h);
	}

	var fr = __dynamic_map_find(h, key);
	if fr.entry_index >= 0 {
		index = fr.entry_index;
	} else {
		index = __dynamic_map_add_entry(h, key);
		if fr.entry_prev >= 0 {
			var entry = __dynamic_map_get_entry(h, fr.entry_prev);
			entry.next = index;
		} else {
			m.hashes[fr.hash_index] = index;
		}
	}
	{
		var e = __dynamic_map_get_entry(h, index);
		e.key = key;
		var val = ^u8(e) + value_offset;
		__mem_copy(val, value, value_size);
	}

	if __dynamic_map_full(h) {
		__dynamic_map_grow(h);
	}
}


const __dynamic_map_grow = proc(using h: __MapHeader) {
	var new_count = max(2*m.entries.cap + 8, __INITIAL_MAP_CAP);
	__dynamic_map_rehash(h, new_count);
}

const __dynamic_map_full = proc(using h: __MapHeader) -> bool {
	return int(0.75 * f64(len(m.hashes))) <= m.entries.cap;
}


const __dynamic_map_hash_equal = proc(h: __MapHeader, a, b: __MapKey) -> bool {
	if a.hash == b.hash {
		if h.is_key_string {
			return a.str == b.str;
		}
		return true;
	}
	return false;
}

const __dynamic_map_find = proc(using h: __MapHeader, key: __MapKey) -> __MapFindResult {
	var fr = __MapFindResult{-1, -1, -1};
	if len(m.hashes) > 0 {
		fr.hash_index = int(key.hash % u128(len(m.hashes)));
		fr.entry_index = m.hashes[fr.hash_index];
		for fr.entry_index >= 0 {
			var entry = __dynamic_map_get_entry(h, fr.entry_index);
			if __dynamic_map_hash_equal(h, entry.key, key) {
				return fr;
			}
			fr.entry_prev = fr.entry_index;
			fr.entry_index = entry.next;
		}
	}
	return fr;
}

const __dynamic_map_add_entry = proc(using h: __MapHeader, key: __MapKey) -> int {
	var prev = m.entries.len;
	var c = __dynamic_array_append_nothing(&m.entries, entry_size, entry_align);
	if c != prev {
		var end = __dynamic_map_get_entry(h, c-1);
		end.key = key;
		end.next = -1;
	}
	return prev;
}


const __dynamic_map_delete = proc(using h: __MapHeader, key: __MapKey) {
	var fr = __dynamic_map_find(h, key);
	if fr.entry_index >= 0 {
		__dynamic_map_erase(h, fr);
	}
}

const __dynamic_map_get_entry = proc(using h: __MapHeader, index: int) -> ^__MapEntryHeader {
	var data = ^u8(m.entries.data) + index*entry_size;
	return ^__MapEntryHeader(data);
}

const __dynamic_map_erase = proc(using h: __MapHeader, fr: __MapFindResult) {
	if fr.entry_prev < 0 {
		m.hashes[fr.hash_index] = __dynamic_map_get_entry(h, fr.entry_index).next;
	} else {
		__dynamic_map_get_entry(h, fr.entry_prev).next = __dynamic_map_get_entry(h, fr.entry_index).next;
	}

	if fr.entry_index == m.entries.len-1 {
		m.entries.len--;
	}
	__mem_copy(__dynamic_map_get_entry(h, fr.entry_index), __dynamic_map_get_entry(h, m.entries.len-1), entry_size);
	var last = __dynamic_map_find(h, __dynamic_map_get_entry(h, fr.entry_index).key);
	if last.entry_prev >= 0 {
		__dynamic_map_get_entry(h, last.entry_prev).next = fr.entry_index;
	} else {
		m.hashes[last.hash_index] = fr.entry_index;
	}
}
