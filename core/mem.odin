import (
	"fmt.odin";
	"os.odin";
)
foreign __llvm_core {
	proc swap(b: u16) -> u16 #link_name "llvm.bswap.i16";
	proc swap(b: u32) -> u32 #link_name "llvm.bswap.i32";
	proc swap(b: u64) -> u64 #link_name "llvm.bswap.i64";
}

proc set(data: rawptr, value: i32, len: int) -> rawptr {
	return __mem_set(data, value, len);
}
proc zero(data: rawptr, len: int) -> rawptr {
	return __mem_zero(data, len);
}
proc copy(dst, src: rawptr, len: int) -> rawptr {
	return __mem_copy(dst, src, len);
}
proc copy_non_overlapping(dst, src: rawptr, len: int) -> rawptr {
	return __mem_copy_non_overlapping(dst, src, len);
}
proc compare(a, b: []u8) -> int {
	return __mem_compare(&a[0], &b[0], min(len(a), len(b)));
}



proc kilobytes(x: int) -> int #inline { return          (x) * 1024; }
proc megabytes(x: int) -> int #inline { return kilobytes(x) * 1024; }
proc gigabytes(x: int) -> int #inline { return megabytes(x) * 1024; }
proc terabytes(x: int) -> int #inline { return gigabytes(x) * 1024; }

proc is_power_of_two(x: int) -> bool {
	if x <= 0 {
		return false;
	}
	return (x & (x-1)) == 0;
}

proc align_forward(ptr: rawptr, align: int) -> rawptr {
	assert(is_power_of_two(align));

	a := uint(align);
	p := uint(ptr);
	modulo := p & (a-1);
	if modulo != 0 {
		p += a - modulo;
	}
	return rawptr(p);
}



type AllocationHeader struct {
	size: int,
}

proc allocation_header_fill(header: ^AllocationHeader, data: rawptr, size: int) {
	header.size = size;
	ptr := ^int(header+1);

	for i := 0; rawptr(ptr) < data; i++ {
		(ptr+i)^ = -1;
	}
}
proc allocation_header(data: rawptr) -> ^AllocationHeader {
	if data == nil {
		return nil;
	}
	p := ^int(data);
	for (p-1)^ == -1 {
		p = (p-1);
	}
	return ^AllocationHeader(p-1);
}





// Custom allocators
type (
	Arena struct {
		backing:    Allocator,
		offset:     int,
		memory:     []u8,
		temp_count: int,
	}

	ArenaTempMemory struct {
		arena:          ^Arena,
		original_count: int,
	}
)




proc init_arena_from_memory(using a: ^Arena, data: []u8) {
	backing    = Allocator{};
	memory     = data[0..<0];
	temp_count = 0;
}

proc init_arena_from_context(using a: ^Arena, size: int) {
	backing = context.allocator;
	memory = make([]u8, size);
	temp_count = 0;
}

proc free_arena(using a: ^Arena) {
	if backing.procedure != nil {
		push_allocator backing {
			free(memory);
			memory = nil;
			offset = 0;
		}
	}
}

proc arena_allocator(arena: ^Arena) -> Allocator {
	return Allocator{
		procedure = arena_allocator_proc,
		data = arena,
	};
}

proc arena_allocator_proc(allocator_data: rawptr, mode: AllocatorMode,
                          size, alignment: int,
                          old_memory: rawptr, old_size: int, flags: u64) -> rawptr {
	using AllocatorMode;
	arena := ^Arena(allocator_data);

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

proc begin_arena_temp_memory(a: ^Arena) -> ArenaTempMemory {
	tmp: ArenaTempMemory;
	tmp.arena = a;
	tmp.original_count = len(a.memory);
	a.temp_count++;
	return tmp;
}

proc end_arena_temp_memory(using tmp: ArenaTempMemory) {
	assert(len(arena.memory) >= original_count);
	assert(arena.temp_count > 0);
	arena.memory = arena.memory[0..<original_count];
	arena.temp_count--;
}







proc align_of_type_info(type_info: ^TypeInfo) -> int {
	proc prev_pow2(n: i64) -> i64 {
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
	using TypeInfo;
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
	case DynamicArray:
		return WORD_SIZE;
	case Slice:
		return WORD_SIZE;
	case Vector:
		size  := size_of_type_info(info.elem);
		count := int(max(prev_pow2(i64(info.count)), 1));
		total := size * count;
		return clamp(total, 1, MAX_ALIGN);
	case Tuple:
		return info.align;
	case Struct:
		return info.align;
	case Union:
		return info.align;
	case RawUnion:
		return info.align;
	case Enum:
		return align_of_type_info(info.base);
	case Map:
		return align_of_type_info(info.generated_struct);
	}

	return 0;
}

proc align_formula(size, align: int) -> int {
	result := size + align-1;
	return result - result%align;
}

proc size_of_type_info(type_info: ^TypeInfo) -> int {
	WORD_SIZE :: size_of(int);
	using TypeInfo;
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
	case DynamicArray:
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
	case RawUnion:
		return info.size;
	case Enum:
		return size_of_type_info(info.base);
	case Map:
		return size_of_type_info(info.generated_struct);
	}

	return 0;
}

