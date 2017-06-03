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
TypeInfoEnumValue :: raw_union {
	f: f64,
	i: i64,
}
// NOTE(bill): This must match the compiler's
CallingConvention :: enum {
	ODIN = 0,
	C    = 1,
	STD  = 2,
	FAST = 3,
}

TypeInfoRecord :: struct #ordered {
	types:        []^TypeInfo,
	names:        []string,
	offsets:      []int,  // offsets may not be used in tuples
	usings:       []bool, // usings may not be used in tuples
	packed:       bool,
	ordered:      bool,
	custom_align: bool,
}

TypeInfo :: union {
	size:  int,
	align: int,

	Named{name: string, base: ^TypeInfo},
	Integer{signed: bool},
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
__type_table: []TypeInfo;

__argv__: ^^byte;
__argc__: i32;

type_info_base :: proc(info: ^TypeInfo) -> ^TypeInfo {
	if info == nil {
		return nil;
	}
	base := info;
	match i in base {
	case TypeInfo.Named:
		base = i.base;
	}
	return base;
}


type_info_base_without_enum :: proc(info: ^TypeInfo) -> ^TypeInfo {
	if info == nil {
		return nil;
	}
	base := info;
	match i in base {
	case TypeInfo.Named:
		base = i.base;
	case TypeInfo.Enum:
		base = i.base;
	}
	return base;
}



assume :: proc(cond: bool) #foreign __llvm_core "llvm.assume";

__debug_trap       :: proc()        #foreign __llvm_core "llvm.debugtrap";
__trap             :: proc()        #foreign __llvm_core "llvm.trap";
read_cycle_counter :: proc() -> u64 #foreign __llvm_core "llvm.readcyclecounter";


// IMPORTANT NOTE(bill): Must be in this order (as the compiler relies upon it)
AllocatorMode :: enum u8 {
	Alloc,
	Free,
	FreeAll,
	Resize,
}
AllocatorProc :: #type proc(allocator_data: rawptr, mode: AllocatorMode,
                             size, alignment: int,
                             old_memory: rawptr, old_size: int, flags: u64) -> rawptr;
Allocator :: struct #ordered {
	procedure: AllocatorProc,
	data:      rawptr,
}


Context :: struct #ordered {
	thread_id: int,

	allocator: Allocator,

	user_data:  rawptr,
	user_index: int,
}

#thread_local __context: Context;


DEFAULT_ALIGNMENT :: align_of([vector 4]f32);


__check_context :: proc() {
	c := &__context;

	if c.allocator.procedure == nil {
		c.allocator = default_allocator();
	}
	if c.thread_id == 0 {
		c.thread_id = os.current_thread_id();
	}
}

alloc :: proc(size: int) -> rawptr #inline { return alloc_align(size, DEFAULT_ALIGNMENT); }

alloc_align :: proc(size, alignment: int) -> rawptr #inline {
	__check_context();
	a := context.allocator;
	return a.procedure(a.data, AllocatorMode.Alloc, size, alignment, nil, 0, 0);
}

free_ptr_with_allocator :: proc(a: Allocator, ptr: rawptr) #inline {
	if ptr == nil {
		return;
	}
	if a.procedure == nil {
		return;
	}
	a.procedure(a.data, AllocatorMode.Free, 0, 0, ptr, 0, 0);
}

free_ptr :: proc(ptr: rawptr) #inline {
	__check_context();
	free_ptr_with_allocator(context.allocator, ptr);
}

free_all :: proc() #inline {
	__check_context();
	a := context.allocator;
	a.procedure(a.data, AllocatorMode.FreeAll, 0, 0, nil, 0, 0);
}


resize       :: proc(ptr: rawptr, old_size, new_size: int) -> rawptr #inline { return resize_align(ptr, old_size, new_size, DEFAULT_ALIGNMENT); }
resize_align :: proc(ptr: rawptr, old_size, new_size, alignment: int) -> rawptr #inline {
	__check_context();
	a := context.allocator;
	return a.procedure(a.data, AllocatorMode.Resize, new_size, alignment, ptr, old_size, 0);
}



default_resize_align :: proc(old_memory: rawptr, old_size, new_size, alignment: int) -> rawptr {
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

	new_memory := alloc_align(new_size, alignment);
	if new_memory == nil {
		return nil;
	}

	__mem_copy(new_memory, old_memory, min(old_size, new_size));;
	free(old_memory);
	return new_memory;
}


default_allocator_proc :: proc(allocator_data: rawptr, mode: AllocatorMode,
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









__string_eq :: proc(a, b: string) -> bool {
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

__string_cmp :: proc(a, b: string) -> int {
	return __mem_compare(&a[0], &b[0], min(len(a), len(b)));
}

__string_ne :: proc(a, b: string) -> bool #inline { return !__string_eq(a, b); }
__string_lt :: proc(a, b: string) -> bool #inline { return __string_cmp(a, b) < 0; }
__string_gt :: proc(a, b: string) -> bool #inline { return __string_cmp(a, b) > 0; }
__string_le :: proc(a, b: string) -> bool #inline { return __string_cmp(a, b) <= 0; }
__string_ge :: proc(a, b: string) -> bool #inline { return __string_cmp(a, b) >= 0; }


__complex64_eq  :: proc(a, b: complex64)  -> bool #inline { return real(a) == real(b) && imag(a) == imag(b); }
__complex64_ne  :: proc(a, b: complex64)  -> bool #inline { return real(a) != real(b) || imag(a) != imag(b); }

__complex128_eq :: proc(a, b: complex128) -> bool #inline { return real(a) == real(b) && imag(a) == imag(b); }
__complex128_ne :: proc(a, b: complex128) -> bool #inline { return real(a) != real(b) || imag(a) != imag(b); }


__assert :: proc(file: string, line, column: int, msg: string) #inline {
	fmt.fprintf(os.stderr, "%s(%d:%d) Runtime assertion: %s\n",
	            file, line, column, msg);
	__debug_trap();
}
__panic :: proc(file: string, line, column: int, msg: string) #inline {
	fmt.fprintf(os.stderr, "%s(%d:%d) Panic: %s\n",
	            file, line, column, msg);
	__debug_trap();
}
__bounds_check_error :: proc(file: string, line, column: int, index, count: int) {
	if 0 <= index && index < count {
		return;
	}
	fmt.fprintf(os.stderr, "%s(%d:%d) Index %d is out of bounds range 0..<%d\n",
	            file, line, column, index, count);
	__debug_trap();
}

__slice_expr_error :: proc(file: string, line, column: int, low, high, max: int) {
	if 0 <= low && low <= high && high <= max {
		return;
	}
	fmt.fprintf(os.stderr, "%s(%d:%d) Invalid slice indices: [%d..<%d..<%d]\n",
	            file, line, column, low, high, max);
	__debug_trap();
}

__substring_expr_error :: proc(file: string, line, column: int, low, high: int) {
	if 0 <= low && low <= high {
		return;
	}
	fmt.fprintf(os.stderr, "%s(%d:%d) Invalid substring indices: [%d..<%d]\n",
	            file, line, column, low, high);
	__debug_trap();
}
__type_assertion_check :: proc(ok: bool, file: string, line, column: int, from, to: ^TypeInfo) {
	if !ok {
		fmt.fprintf(os.stderr, "%s(%d:%d) Invalid type_assertion from %T to %T\n",
		            file, line, column, from, to);
		__debug_trap();
	}
}

__string_decode_rune :: proc(s: string) -> (rune, int) #inline {
	return utf8.decode_rune(s);
}


__mem_set :: proc(data: rawptr, value: i32, len: int) -> rawptr {
	llvm_memset_64bit :: proc(dst: rawptr, val: byte, len: int, align: i32, is_volatile: bool) #foreign __llvm_core "llvm.memset.p0i8.i64";
	llvm_memset_64bit(data, byte(value), len, 1, false);
	return data;
}
__mem_zero :: proc(data: rawptr, len: int) -> rawptr {
	return __mem_set(data, 0, len);
}
__mem_copy :: proc(dst, src: rawptr, len: int) -> rawptr {
	// NOTE(bill): This _must_ be implemented like C's memmove
	llvm_memmove_64bit :: proc(dst, src: rawptr, len: int, align: i32, is_volatile: bool) #foreign __llvm_core "llvm.memmove.p0i8.p0i8.i64";
	llvm_memmove_64bit(dst, src, len, 1, false);
	return dst;
}
__mem_copy_non_overlapping :: proc(dst, src: rawptr, len: int) -> rawptr {
	// NOTE(bill): This _must_ be implemented like C's memcpy
	llvm_memcpy_64bit :: proc(dst, src: rawptr, len: int, align: i32, is_volatile: bool) #foreign __llvm_core "llvm.memcpy.p0i8.p0i8.i64";
	llvm_memcpy_64bit(dst, src, len, 1, false);
	return dst;
}

__mem_compare :: proc(a, b: ^byte, n: int) -> int {
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

__sqrt_f32 :: proc(x: f32) -> f32 #foreign __llvm_core "llvm.sqrt.f32";
__sqrt_f64 :: proc(x: f64) -> f64 #foreign __llvm_core "llvm.sqrt.f64";
__abs_complex64 :: proc(x: complex64) -> f32 #inline {
	r, i := real(x), imag(x);
	return __sqrt_f32(r*r + i*i);
}
__abs_complex128 :: proc(x: complex128) -> f64 #inline {
	r, i := real(x), imag(x);
	return __sqrt_f64(r*r + i*i);
}




__dynamic_array_make :: proc(array_: rawptr, elem_size, elem_align: int, len, cap: int) {
	array := ^raw.DynamicArray(array_);
	__check_context();
	array.allocator = context.allocator;
	assert(array.allocator.procedure != nil);

	if cap > 0 {
		__dynamic_array_reserve(array_, elem_size, elem_align, cap);
		array.len = len;
	}
}

__dynamic_array_reserve :: proc(array_: rawptr, elem_size, elem_align: int, cap: int) -> bool {
	array := ^raw.DynamicArray(array_);

	if cap <= array.cap {
		return true;
	}

	__check_context();
	if array.allocator.procedure == nil {
		array.allocator = context.allocator;
	}
	assert(array.allocator.procedure != nil);

	old_size  := array.cap * elem_size;
	new_size  := cap * elem_size;
	allocator := array.allocator;

	new_data := allocator.procedure(allocator.data, AllocatorMode.Resize, new_size, elem_align, array.data, old_size, 0);
	if new_data == nil {
		return false;
	}

	array.data = new_data;
	array.cap = cap;
	return true;
}

__dynamic_array_resize :: proc(array_: rawptr, elem_size, elem_align: int, len: int) -> bool {
	array := ^raw.DynamicArray(array_);

	ok := __dynamic_array_reserve(array_, elem_size, elem_align, len);
	if ok {
		array.len = len;
	}
	return ok;
}


__dynamic_array_append :: proc(array_: rawptr, elem_size, elem_align: int,
                               items: rawptr, item_count: int) -> int {
	array := ^raw.DynamicArray(array_);

	if item_count <= 0 || items == nil {
		return array.len;
	}


	ok := true;
	if array.cap <= array.len+item_count {
		cap := 2 * array.cap + max(8, item_count);
		ok = __dynamic_array_reserve(array, elem_size, elem_align, cap);
	}
	if !ok {
		// TODO(bill): Better error handling for failed reservation
		return array.len;
	}
	data := ^byte(array.data);
	assert(data != nil);
	__mem_copy(data + (elem_size*array.len), items, elem_size * item_count);
	array.len += item_count;
	return array.len;
}

__dynamic_array_append_nothing :: proc(array_: rawptr, elem_size, elem_align: int) -> int {
	array := ^raw.DynamicArray(array_);

	ok := true;
	if array.cap <= array.len+1 {
		cap := 2 * array.cap + max(8, 1);
		ok = __dynamic_array_reserve(array, elem_size, elem_align, cap);
	}
	if !ok {
		// TODO(bill): Better error handling for failed reservation
		return array.len;
	}
	data := ^byte(array.data);
	assert(data != nil);
	__mem_zero(data + (elem_size*array.len), elem_size);
	array.len++;
	return array.len;
}

__slice_append :: proc(slice_: rawptr, elem_size, elem_align: int,
                       items: rawptr, item_count: int) -> int {
	slice := ^raw.Slice(slice_);

	if item_count <= 0 || items == nil {
		return slice.len;
	}

	item_count = min(slice.cap-slice.len, item_count);
	if item_count > 0 {
		data := ^byte(slice.data);
		assert(data != nil);
		__mem_copy(data + (elem_size*slice.len), items, elem_size * item_count);
		slice.len += item_count;
	}
	return slice.len;
}


// Map stuff

__default_hash :: proc(data: []byte) -> u64 {
	fnv64a :: proc(data: []byte) -> u64 {
		h: u64 = 0xcbf29ce484222325;
		for b in data {
			h = (h ~ u64(b)) * 0x100000001b3;
		}
		return h;
	}
	return fnv64a(data);
}
__default_hash_string :: proc(s: string) -> u64 {
	return __default_hash([]byte(s));
}

__INITIAL_MAP_CAP :: 16;

__MapKey :: struct #ordered {
	hash: u64,
	str:  string,
}

__MapFindResult :: struct #ordered {
	hash_index:  int,
	entry_prev:  int,
	entry_index: int,
}

__MapEntryHeader :: struct #ordered {
	key:  __MapKey,
	next: int,
/*
	value: Value_Type,
*/
}

__MapHeader :: struct #ordered {
	m:             ^raw.DynamicMap,
	is_key_string: bool,
	entry_size:    int,
	entry_align:   int,
	value_offset:  int,
	value_size:    int,
}

__dynamic_map_reserve :: proc(using header: __MapHeader, cap: int)  {
	__dynamic_array_reserve(&m.hashes, size_of(int), align_of(int), cap);
	__dynamic_array_reserve(&m.entries, entry_size, entry_align,    cap);
}

__dynamic_map_rehash :: proc(using header: __MapHeader, new_count: int) {
	new_header: __MapHeader = header;
	nm: raw.DynamicMap;
	new_header.m = &nm;

	header_hashes := ^raw.DynamicArray(&header.m.hashes);
	nm_hashes := ^raw.DynamicArray(&nm.hashes);

	__dynamic_array_resize(nm_hashes, size_of(int), align_of(int), new_count);
	__dynamic_array_reserve(&nm.entries, entry_size, entry_align, m.entries.len);
	for i in 0..<new_count {
		nm.hashes[i] = -1;
	}

	for i := 0; i < m.entries.len; i++ {
		if len(nm.hashes) == 0 {
			__dynamic_map_grow(new_header);
		}

		entry_header := __dynamic_map_get_entry(header, i);
		data := ^byte(entry_header);

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
		ndata := ^byte(e);
		__mem_copy(ndata+value_offset, data+value_offset, value_size);

		if __dynamic_map_full(new_header) {
			__dynamic_map_grow(new_header);
		}
	}
	free_ptr_with_allocator(header_hashes.allocator, header_hashes.data);
	free_ptr_with_allocator(header.m.entries.allocator, header.m.entries.data);
	header.m^ = nm;
}

__dynamic_map_get :: proc(h: __MapHeader, key: __MapKey) -> rawptr {
	index := __dynamic_map_find(h, key).entry_index;
	if index >= 0 {
		data := ^byte(__dynamic_map_get_entry(h, index));
		val := data + h.value_offset;
		return val;
	}
	return nil;
}

__dynamic_map_set :: proc(using h: __MapHeader, key: __MapKey, value: rawptr) {
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
		val := ^byte(e) + value_offset;
		__mem_copy(val, value, value_size);
	}

	if __dynamic_map_full(h) {
		__dynamic_map_grow(h);
	}
}


__dynamic_map_grow :: proc(using h: __MapHeader) {
	new_count := max(2*m.entries.cap + 8, __INITIAL_MAP_CAP);
	__dynamic_map_rehash(h, new_count);
}

__dynamic_map_full :: proc(using h: __MapHeader) -> bool {
	return int(0.75 * f64(len(m.hashes))) <= m.entries.cap;
}


__dynamic_map_hash_equal :: proc(h: __MapHeader, a, b: __MapKey) -> bool {
	if a.hash == b.hash {
		if h.is_key_string {
			return a.str == b.str;
		}
		return true;
	}
	return false;
}

__dynamic_map_find :: proc(using h: __MapHeader, key: __MapKey) -> __MapFindResult {
	fr := __MapFindResult{-1, -1, -1};
	if len(m.hashes) > 0 {
		fr.hash_index = int(key.hash % u64(len(m.hashes)));
		fr.entry_index = m.hashes[fr.hash_index];
		for fr.entry_index >= 0 {
			entry := __dynamic_map_get_entry(h, fr.entry_index);
			if __dynamic_map_hash_equal(h, entry.key, key) {
				return fr;
			}
			fr.entry_prev = fr.entry_index;
			fr.entry_index = entry.next;
		}
	}
	return fr;
}

__dynamic_map_add_entry :: proc(using h: __MapHeader, key: __MapKey) -> int {
	prev := m.entries.len;
	c := __dynamic_array_append_nothing(&m.entries, entry_size, entry_align);
	if c != prev {
		end := __dynamic_map_get_entry(h, c-1);
		end.key = key;
		end.next = -1;
	}
	return prev;
}


__dynamic_map_delete :: proc(using h: __MapHeader, key: __MapKey) {
	fr := __dynamic_map_find(h, key);
	if fr.entry_index >= 0 {
		__dynamic_map_erase(h, fr);
	}
}

__dynamic_map_get_entry :: proc(using h: __MapHeader, index: int) -> ^__MapEntryHeader {
	data := ^byte(m.entries.data) + index*entry_size;
	return ^__MapEntryHeader(data);
}

__dynamic_map_erase :: proc(using h: __MapHeader, fr: __MapFindResult) {
	if fr.entry_prev < 0 {
		m.hashes[fr.hash_index] = __dynamic_map_get_entry(h, fr.entry_index).next;
	} else {
		__dynamic_map_get_entry(h, fr.entry_prev).next = __dynamic_map_get_entry(h, fr.entry_index).next;
	}

	if fr.entry_index == m.entries.len-1 {
		m.entries.len--;
	}
	__mem_copy(__dynamic_map_get_entry(h, fr.entry_index), __dynamic_map_get_entry(h, m.entries.len-1), entry_size);
	last := __dynamic_map_find(h, __dynamic_map_get_entry(h, fr.entry_index).key);
	if last.entry_prev >= 0 {
		__dynamic_map_get_entry(h, last.entry_prev).next = fr.entry_index;
	} else {
		m.hashes[last.hash_index] = fr.entry_index;
	}
}
