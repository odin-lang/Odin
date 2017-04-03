#import "fmt.odin";
#import "os.odin";

swap :: proc(b: u16) -> u16 #foreign __llvm_core "llvm.bswap.i16";
swap :: proc(b: u32) -> u32 #foreign __llvm_core "llvm.bswap.i32";
swap :: proc(b: u64) -> u64 #foreign __llvm_core "llvm.bswap.i64";


set :: proc(data: rawptr, value: i32, len: int) -> rawptr {
	return __mem_set(data, value, len);
}
zero :: proc(data: rawptr, len: int) -> rawptr {
	return __mem_zero(data, len);
}
copy :: proc(dst, src: rawptr, len: int) -> rawptr {
	return __mem_copy(dst, src, len);
}
copy_non_overlapping :: proc(dst, src: rawptr, len: int) -> rawptr {
	return __mem_copy_non_overlapping(dst, src, len);
}
compare :: proc(a, b: []byte) -> int {
	return __mem_compare(^a[0], ^b[0], min(len(a), len(b)));
}



kilobytes :: proc(x: int) -> int #inline { return          (x) * 1024; }
megabytes :: proc(x: int) -> int #inline { return kilobytes(x) * 1024; }
gigabytes :: proc(x: int) -> int #inline { return megabytes(x) * 1024; }
terabytes :: proc(x: int) -> int #inline { return gigabytes(x) * 1024; }

is_power_of_two :: proc(x: int) -> bool {
	if x <= 0 {
		return false;
	}
	return (x & (x-1)) == 0;
}

align_forward :: proc(ptr: rawptr, align: int) -> rawptr {
	assert(is_power_of_two(align));

	a := cast(uint)align;
	p := cast(uint)ptr;
	modulo := p & (a-1);
	if modulo != 0 {
		p += a - modulo;
	}
	return cast(rawptr)p;
}



Allocation_Header :: struct {
	size: int,
}

allocation_header_fill :: proc(header: ^Allocation_Header, data: rawptr, size: int) {
	header.size = size;
	ptr := cast(^int)(header+1);

	for i := 0; cast(rawptr)ptr < data; i++ {
		(ptr+i)^ = -1;
	}
}
allocation_header :: proc(data: rawptr) -> ^Allocation_Header {
	if data == nil {
		return nil;
	}
	p := cast(^int)data;
	for (p-1)^ == -1 {
		p = (p-1);
	}
	return cast(^Allocation_Header)p-1;
}





// Custom allocators
Arena :: struct {
	backing:    Allocator,
	offset:     int,
	memory:     []byte,
	temp_count: int,
}

Arena_Temp_Memory :: struct {
	arena:          ^Arena,
	original_count: int,
}





init_arena_from_memory :: proc(using a: ^Arena, data: []byte) {
	backing    = Allocator{};
	memory     = data[..0];
	temp_count = 0;
}

init_arena_from_context :: proc(using a: ^Arena, size: int) {
	backing = context.allocator;
	memory = make([]byte, size);
	temp_count = 0;
}

free_arena :: proc(using a: ^Arena) {
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

arena_allocator_proc :: proc(allocator_data: rawptr, mode: Allocator_Mode,
                          size, alignment: int,
                          old_memory: rawptr, old_size: int, flags: u64) -> rawptr {
	using Allocator_Mode;
	arena := cast(^Arena)allocator_data;

	match mode {
	case ALLOC:
		total_size := size + alignment;

		if arena.offset + total_size > len(arena.memory) {
			fmt.fprintln(os.stderr, "Arena out of memory");
			return nil;
		}

		#no_bounds_check end := ^arena.memory[arena.offset];

		ptr := align_forward(end, alignment);
		arena.offset += total_size;
		return zero(ptr, size);

	case FREE:
		// NOTE(bill): Free all at once
		// Use Arena_Temp_Memory if you want to free a block

	case FREE_ALL:
		arena.offset = 0;

	case RESIZE:
		return default_resize_align(old_memory, old_size, size, alignment);
	}

	return nil;
}

begin_arena_temp_memory :: proc(a: ^Arena) -> Arena_Temp_Memory {
	tmp: Arena_Temp_Memory;
	tmp.arena = a;
	tmp.original_count = len(a.memory);
	a.temp_count++;
	return tmp;
}

end_arena_temp_memory :: proc(using tmp: Arena_Temp_Memory) {
	assert(len(arena.memory) >= original_count);
	assert(arena.temp_count > 0);
	arena.memory = arena.memory[..original_count];
	arena.temp_count--;
}







align_of_type_info :: proc(type_info: ^Type_Info) -> int {
	prev_pow2 :: proc(n: i64) -> i64 {
		if n <= 0 {
			return 0;
		}
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
	match info in type_info {
	case Named:
		return align_of_type_info(info.base);
	case Integer:
		return info.size;
	case Float:
		return info.size;
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
		size := size_of_type_info(info.elem);
		count := cast(int)max(prev_pow2(cast(i64)info.count), 1);
		total := size * count;
		return clamp(total, 1, MAX_ALIGN);
	case Tuple:
		return info.align;
	case Struct:
		return info.align;
	case Union:
		return info.align;
	case Raw_Union:
		return info.align;
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
	match info in type_info {
	case Named:
		return size_of_type_info(info.base);
	case Integer:
		return info.size;
	case Float:
		return info.size;
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
		if count == 0 {
			return 0;
		}
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
		if count == 0 {
			return 0;
		}
		size      := size_of_type_info(info.elem);
		align     := align_of_type_info(info.elem);
		alignment := align_formula(size, align);
		return alignment*(count-1) + size;
	case Struct:
		return info.size;
	case Union:
		return info.size;
	case Raw_Union:
		return info.size;
	case Enum:
		return size_of_type_info(info.base);
	case Map:
		return size_of_type_info(info.generated_struct);
	}

	return 0;
}

