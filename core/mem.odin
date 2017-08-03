import (
	"fmt.odin";
	"os.odin";
	"raw.odin";
)
foreign __llvm_core {
	swap :: proc(b: u16) -> u16 #link_name "llvm.bswap.i16" ---;
	swap :: proc(b: u32) -> u32 #link_name "llvm.bswap.i32" ---;
	swap :: proc(b: u64) -> u64 #link_name "llvm.bswap.i64" ---;
}

set :: proc(data: rawptr, value: i32, len: int) -> rawptr #cc_contextless {
	return __mem_set(data, value, len);
}
zero :: proc(data: rawptr, len: int) -> rawptr #cc_contextless {
	return __mem_zero(data, len);
}
copy :: proc(dst, src: rawptr, len: int) -> rawptr #cc_contextless {
	return __mem_copy(dst, src, len);
}
copy_non_overlapping :: proc(dst, src: rawptr, len: int) -> rawptr #cc_contextless {
	return __mem_copy_non_overlapping(dst, src, len);
}
compare :: proc(a, b: []u8) -> int #cc_contextless {
	return __mem_compare(&a[0], &b[0], min(len(a), len(b)));
}


slice_ptr :: proc(ptr: ^$T, len: int) -> []T #cc_contextless {
	assert(len >= 0);
	slice := raw.Slice{data = ptr, len = len, cap = len};
	return (cast(^[]T)&slice)^;
}
slice_ptr :: proc(ptr: ^$T, len, cap: int) -> []T #cc_contextless {
	assert(0 <= len && len <= cap);
	slice := raw.Slice{data = ptr, len = len, cap = cap};
	return (cast(^[]T)&slice)^;
}

slice_to_bytes :: proc(slice: []$T) -> []u8 #cc_contextless {
	s := cast(^raw.Slice)&slice;
	s.len *= size_of(T);
	s.cap *= size_of(T);
	return (cast(^[]u8)s)^;
}


kilobytes :: proc(x: int) -> int #inline #cc_contextless { return          (x) * 1024; }
megabytes :: proc(x: int) -> int #inline #cc_contextless { return kilobytes(x) * 1024; }
gigabytes :: proc(x: int) -> int #inline #cc_contextless { return megabytes(x) * 1024; }
terabytes :: proc(x: int) -> int #inline #cc_contextless { return gigabytes(x) * 1024; }

is_power_of_two :: proc(x: int) -> bool {
	if x <= 0 do return false;
	return (x & (x-1)) == 0;
}

align_forward :: proc(ptr: rawptr, align: int) -> rawptr {
	assert(is_power_of_two(align));

	a := uint(align);
	p := uint(ptr);
	modulo := p & (a-1);
	if modulo != 0 do p += a - modulo;
	return rawptr(p);
}



AllocationHeader :: struct {
	size: int;
}

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





// Custom allocators

Arena :: struct {
	backing:    Allocator;
	offset:     int;
	memory:     []u8;
	temp_count: int;
}

ArenaTempMemory :: struct {
	arena:          ^Arena;
	original_count: int;
}





init_arena_from_memory :: proc(using a: ^Arena, data: []u8) {
	backing    = Allocator{};
	memory     = data[..0];
	temp_count = 0;
}

init_arena_from_context :: proc(using a: ^Arena, size: int) {
	backing = context.allocator;
	memory = make([]u8, size);
	temp_count = 0;
}

destroy_arena :: proc(using a: ^Arena) {
	if backing.procedure != nil {
		push_allocator backing {
			free(memory);
			memory = nil;
			offset = 0;
		}
	}
}

arena_allocator :: proc(arena: ^Arena) -> Allocator {
	return Allocator{
		procedure = arena_allocator_proc,
		data = arena,
	};
}

arena_allocator_proc :: proc(allocator_data: rawptr, mode: Allocator.Mode,
                             size, alignment: int,
                             old_memory: rawptr, old_size: int, flags: u64) -> rawptr {
	using Allocator.Mode;
	arena := cast(^Arena)allocator_data;

	match mode {
	case Alloc:
		total_size := size + alignment;

		if arena.offset + total_size > len(arena.memory) {
			fmt.fprintln(os.stderr, "Arena out of memory");
			return nil;
		}

		#no_bounds_check end := &arena.memory[arena.offset];

		ptr := align_forward(end, alignment);
		arena.offset += total_size;
		return zero(ptr, size);

	case Free:
		// NOTE(bill): Free all at once
		// Use ArenaTempMemory if you want to free a block

	case FreeAll:
		arena.offset = 0;

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
	arena.memory = arena.memory[..original_count];
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
	MAX_ALIGN :: size_of([vector 64]f64); // TODO(bill): Should these constants be builtin constants?
	using Type_Info;
	match info in type_info.variant {
	case Named:
		return align_of_type_info(info.base);
	case Integer:
		return type_info.align;
	case Rune:
		return type_info.align;
	case Float:
		return type_info.align;
	case String:
		return WORD_SIZE;
	case Boolean:
		return 1;
	case Any:
		return WORD_SIZE;
	case Pointer:
		return WORD_SIZE;
	case Procedure:
		return WORD_SIZE;
	case Array:
		return align_of_type_info(info.elem);
	case Dynamic_Array:
		return WORD_SIZE;
	case Slice:
		return WORD_SIZE;
	case Vector:
		size  := size_of_type_info(info.elem);
		count := int(max(prev_pow2(i64(info.count)), 1));
		total := size * count;
		return clamp(total, 1, MAX_ALIGN);
	case Tuple:
		return type_info.align;
	case Struct:
		return type_info.align;
	case Union:
		return type_info.align;
	case Enum:
		return align_of_type_info(info.base);
	case Map:
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
	using Type_Info;
	match info in type_info.variant {
	case Named:
		return size_of_type_info(info.base);
	case Integer:
		return type_info.size;
	case Rune:
		return type_info.size;
	case Float:
		return type_info.size;
	case String:
		return 2*WORD_SIZE;
	case Boolean:
		return 1;
	case Any:
		return 2*WORD_SIZE;
	case Pointer:
		return WORD_SIZE;
	case Procedure:
		return WORD_SIZE;
	case Array:
		count := info.count;
		if count == 0 do return 0;
		size      := size_of_type_info(info.elem);
		align     := align_of_type_info(info.elem);
		alignment := align_formula(size, align);
		return alignment*(count-1) + size;
	case Dynamic_Array:
		return size_of(rawptr) + 2*size_of(int) + size_of(Allocator);
	case Slice:
		return 2*WORD_SIZE;
	case Vector:
		count := info.count;
		if count == 0 do return 0;
		size      := size_of_type_info(info.elem);
		align     := align_of_type_info(info.elem);
		alignment := align_formula(size, align);
		return alignment*(count-1) + size;
	case Struct:
		return type_info.size;
	case Union:
		return type_info.size;
	case Enum:
		return size_of_type_info(info.base);
	case Map:
		return size_of_type_info(info.generated_struct);
	}

	return 0;
}

