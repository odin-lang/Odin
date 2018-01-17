import "core:raw.odin"

foreign __llvm_core {
	@(link_name = "llvm.bswap.i16") swap16 :: proc(b: u16) -> u16 ---;
	@(link_name = "llvm.bswap.i32") swap32 :: proc(b: u32) -> u32 ---;
	@(link_name = "llvm.bswap.i64") swap64 :: proc(b: u64) -> u64 ---;
}
swap :: proc[swap16, swap32, swap64];


set :: proc "contextless" (data: rawptr, value: i32, len: int) -> rawptr {
	return __mem_set(data, value, len);
}
zero :: proc "contextless" (data: rawptr, len: int) -> rawptr {
	return __mem_zero(data, len);
}
copy :: proc "contextless" (dst, src: rawptr, len: int) -> rawptr {
	return __mem_copy(dst, src, len);
}
copy_non_overlapping :: proc "contextless" (dst, src: rawptr, len: int) -> rawptr {
	return __mem_copy_non_overlapping(dst, src, len);
}
compare :: proc "contextless" (a, b: []byte) -> int {
	return __mem_compare(&a[0], &b[0], min(len(a), len(b)));
}


slice_ptr :: proc "contextless" (ptr: ^$T, len: int) -> []T {
	assert(len >= 0);
	slice := raw.Slice{data = ptr, len = len};
	return transmute([]T)slice;
}

slice_to_bytes :: proc "contextless" (slice: $E/[]$T) -> []byte {
	s := transmute(raw.Slice)slice;
	s.len *= size_of(T);
	return transmute([]byte)s;
}

ptr_to_bytes :: proc "contextless" (ptr: ^$T, len := 1) -> []byte {
    assert(len >= 0);
    return transmute([]byte)raw.Slice{ptr, len*size_of(T)};
}


kilobytes :: inline proc "contextless" (x: int) -> int do return          (x) * 1024;
megabytes :: inline proc "contextless" (x: int) -> int do return kilobytes(x) * 1024;
gigabytes :: inline proc "contextless" (x: int) -> int do return megabytes(x) * 1024;
terabytes :: inline proc "contextless" (x: int) -> int do return gigabytes(x) * 1024;

is_power_of_two :: proc(x: uintptr) -> bool {
	if x <= 0 do return false;
	return (x & (x-1)) == 0;
}

align_forward :: proc(ptr: rawptr, align: uintptr) -> rawptr {
	assert(is_power_of_two(align));

	a := uintptr(align);
	p := uintptr(ptr);
	modulo := p & (a-1);
	if modulo != 0 do p += a - modulo;
	return rawptr(p);
}



AllocationHeader :: struct {size: int};

allocation_header_fill :: proc(header: ^AllocationHeader, data: rawptr, size: int) {
	header.size = size;
	ptr := cast(^uint)(header+1);
	n := cast(^uint)data - ptr;

	for i in 0..n {
		(ptr+i)^ = ~uint(0);
	}
}
allocation_header :: proc(data: rawptr) -> ^AllocationHeader {
	if data == nil do return nil;
	p := cast(^uint)data;
	for (p-1)^ == ~uint(0) do p = (p-1);
	return cast(^AllocationHeader)(p-1);
}


Fixed_Byte_Buffer :: [dynamic]byte;

make_fixed_byte_buffer :: proc(backing: []byte) -> Fixed_Byte_Buffer {
	s := transmute(raw.Slice)backing;
	d: raw.Dynamic_Array;
	d.data = s.data;
	d.len = 0;
	d.cap = s.len;
	d.allocator = nil_allocator();
	return transmute(Fixed_Byte_Buffer)d;
}



// Custom allocators

Arena :: struct {
	backing:    Allocator,
	memory:     Fixed_Byte_Buffer,
	temp_count: int,
}

ArenaTempMemory :: struct {
	arena:          ^Arena,
	original_count: int,
}





init_arena_from_memory :: proc(using a: ^Arena, data: []byte) {
	backing    = Allocator{};
	memory     = make_fixed_byte_buffer(data);
	temp_count = 0;
}

init_arena_from_context :: proc(using a: ^Arena, size: int) {
	backing = context.allocator;
	memory = make_fixed_byte_buffer(make([]byte, size));
	temp_count = 0;
}


context_from_allocator :: proc(a: Allocator) -> Context {
	c := context;
	c.allocator = a;
	return c;
}

destroy_arena :: proc(using a: ^Arena) {
	if backing.procedure != nil {
		context <- context_from_allocator(backing) {
			if memory != nil {
				free(&memory[0]);
			}
			memory = nil;
		}
	}
}

arena_allocator :: proc(arena: ^Arena) -> Allocator {
	return Allocator{
		procedure = arena_allocator_proc,
		data = arena,
	};
}

arena_allocator_proc :: proc(allocator_data: rawptr, mode: Allocator_Mode,
                             size, alignment: int,
                             old_memory: rawptr, old_size: int, flags: u64, location := #caller_location) -> rawptr {
	using Allocator_Mode;
	arena := cast(^Arena)allocator_data;


	switch mode {
	case Alloc:
		total_size := size + alignment;

		if len(arena.memory) + total_size > cap(arena.memory) {
			return nil;
		}

		#no_bounds_check end := &arena.memory[len(arena.memory)];

		ptr := align_forward(end, uintptr(alignment));
		(^raw.Slice)(&arena.memory).len += total_size;
		return zero(ptr, size);

	case Free:
		// NOTE(bill): Free all at once
		// Use ArenaTempMemory if you want to free a block

	case FreeAll:
		(^raw.Slice)(&arena.memory).len = 0;

	case Resize:
		return default_resize_align(old_memory, old_size, size, alignment);
	}

	return nil;
}

begin_arena_temp_memory :: proc(a: ^Arena) -> ArenaTempMemory {
	tmp: ArenaTempMemory;
	tmp.arena = a;
	tmp.original_count = len(a.memory);
	a.temp_count += 1;
	return tmp;
}

end_arena_temp_memory :: proc(using tmp: ArenaTempMemory) {
	assert(len(arena.memory) >= original_count);
	assert(arena.temp_count > 0);
	(^raw.Dynamic_Array)(&arena.memory).len = original_count;
	arena.temp_count -= 1;
}







align_of_type_info :: proc(type_info: ^Type_Info) -> int {
	prev_pow2 :: proc(n: i64) -> i64 {
		if n <= 0 do return 0;
		n |= n >> 1;
		n |= n >> 2;
		n |= n >> 4;
		n |= n >> 8;
		n |= n >> 16;
		n |= n >> 32;
		return n - (n >> 1);
	}

	WORD_SIZE :: size_of(int);
	MAX_ALIGN :: 2*align_of(rawptr); // TODO(bill): Should these constants be builtin constants?
	switch info in type_info.variant {
	case Type_Info_Named:
		return align_of_type_info(info.base);
	case Type_Info_Integer:
		return type_info.align;
	case Type_Info_Rune:
		return type_info.align;
	case Type_Info_Float:
		return type_info.align;
	case Type_Info_String:
		return WORD_SIZE;
	case Type_Info_Boolean:
		return 1;
	case Type_Info_Any:
		return WORD_SIZE;
	case Type_Info_Pointer:
		return WORD_SIZE;
	case Type_Info_Procedure:
		return WORD_SIZE;
	case Type_Info_Array:
		return align_of_type_info(info.elem);
	case Type_Info_Dynamic_Array:
		return WORD_SIZE;
	case Type_Info_Slice:
		return WORD_SIZE;
	case Type_Info_Tuple:
		return type_info.align;
	case Type_Info_Struct:
		return type_info.align;
	case Type_Info_Union:
		return type_info.align;
	case Type_Info_Enum:
		return align_of_type_info(info.base);
	case Type_Info_Map:
		return align_of_type_info(info.generated_struct);
	}

	return 0;
}

align_formula :: proc(size, align: int) -> int {
	result := size + align-1;
	return result - result%align;
}

size_of_type_info :: proc(type_info: ^Type_Info) -> int {
	WORD_SIZE :: size_of(int);
	switch info in type_info.variant {
	case Type_Info_Named:
		return size_of_type_info(info.base);
	case Type_Info_Integer:
		return type_info.size;
	case Type_Info_Rune:
		return type_info.size;
	case Type_Info_Float:
		return type_info.size;
	case Type_Info_String:
		return 2*WORD_SIZE;
	case Type_Info_Boolean:
		return 1;
	case Type_Info_Any:
		return 2*WORD_SIZE;
	case Type_Info_Pointer:
		return WORD_SIZE;
	case Type_Info_Procedure:
		return WORD_SIZE;
	case Type_Info_Array:
		count := info.count;
		if count == 0 do return 0;
		size      := size_of_type_info(info.elem);
		align     := align_of_type_info(info.elem);
		alignment := align_formula(size, align);
		return alignment*(count-1) + size;
	case Type_Info_Dynamic_Array:
		return size_of(rawptr) + 2*size_of(int) + size_of(Allocator);
	case Type_Info_Slice:
		return 2*WORD_SIZE;
	case Type_Info_Struct:
		return type_info.size;
	case Type_Info_Union:
		return type_info.size;
	case Type_Info_Enum:
		return size_of_type_info(info.base);
	case Type_Info_Map:
		return size_of_type_info(info.generated_struct);
	}

	return 0;
}

