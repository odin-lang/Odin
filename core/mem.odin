import (
	"fmt.odin";
	"os.odin";
)

proc set(data rawptr, value i32, len int) -> rawptr #link_name "__mem_set" {
	proc llvm_memset_64bit(dst rawptr, val byte, len int, align i32, is_volatile bool) #foreign "llvm.memset.p0i8.i64"
	llvm_memset_64bit(data, value as byte, len, 1, false);
	return data;
}

proc zero(data rawptr, len int) -> rawptr #link_name "__mem_zero" {
	return set(data, 0, len);
}

proc copy(dst, src rawptr, len int) -> rawptr #link_name "__mem_copy" {
	// NOTE(bill): This _must_ implemented like C's memmove
	proc llvm_memmove_64bit(dst, src rawptr, len int, align i32, is_volatile bool) #foreign "llvm.memmove.p0i8.p0i8.i64"
	llvm_memmove_64bit(dst, src, len, 1, false);
	return dst;
}

proc copy_non_overlapping(dst, src rawptr, len int) -> rawptr #link_name "__mem_copy_non_overlapping" {
	// NOTE(bill): This _must_ implemented like C's memcpy
	proc llvm_memcpy_64bit(dst, src rawptr, len int, align i32, is_volatile bool) #foreign "llvm.memcpy.p0i8.p0i8.i64"
	llvm_memcpy_64bit(dst, src, len, 1, false);
	return dst;
}


proc compare(dst, src rawptr, n int) -> int #link_name "__mem_compare" {
	// Translation of http://mgronhol.github.io/fast-strcmp/
	var a = slice_ptr(dst as ^byte, n);
	var b = slice_ptr(src as ^byte, n);

	var fast = n/size_of(int) + 1;
	var offset = (fast-1)*size_of(int);
	var curr_block = 0;
	if n <= size_of(int) {
		fast = 0;
	}

	var la = slice_ptr(^a[0] as ^int, fast);
	var lb = slice_ptr(^b[0] as ^int, fast);

	for ; curr_block < fast; curr_block++ {
		if (la[curr_block] ~ lb[curr_block]) != 0 {
			for var pos = curr_block*size_of(int); pos < n; pos++ {
				if (a[pos] ~ b[pos]) != 0 {
					return a[pos] as int - b[pos] as int;
				}
			}
		}

	}

	for ; offset < n; offset++ {
		if (a[offset] ~ b[offset]) != 0 {
			return a[offset] as int - b[offset] as int;
		}
	}

	return 0;
}



proc kilobytes(x int) -> int #inline { return          (x) * 1024; }
proc megabytes(x int) -> int #inline { return kilobytes(x) * 1024; }
proc gigabytes(x int) -> int #inline { return gigabytes(x) * 1024; }
proc terabytes(x int) -> int #inline { return terabytes(x) * 1024; }

proc is_power_of_two(x int) -> bool {
	if x <= 0 {
		return false;
	}
	return (x & (x-1)) == 0;
}

proc align_forward(ptr rawptr, align int) -> rawptr {
	assert(is_power_of_two(align));

	var a = align as uint;
	var p = ptr as uint;
	var modulo = p & (a-1);
	if modulo != 0 {
		p += a - modulo;
	}
	return p as rawptr;
}



type Allocation_Header struct {
	size int;
}

proc allocation_header_fill(header ^Allocation_Header, data rawptr, size int) {
	header.size = size;
	var ptr = (header+1) as ^int;

	for var i = 0; ptr as rawptr < data; i++ {
		(ptr+i)^ = -1;
	}
}
proc allocation_header(data rawptr) -> ^Allocation_Header {
	var p = data as ^int;
	for (p-1)^ == -1 {
		p = (p-1);
	}
	return (p as ^Allocation_Header)-1;
}





// Custom allocators
type (
	Arena struct {
		backing    Allocator;
		memory     []byte;
		temp_count int;
	}

	Arena_Temp_Memory struct {
		arena          ^Arena;
		original_count int;
	}
)




proc init_arena_from_memory(using a ^Arena, data []byte) {
	backing    = Allocator{};
	memory     = data[:0];
	temp_count = 0;
}

proc init_arena_from_context(using a ^Arena, size int) {
	backing = context.allocator;
	memory = new_slice(byte, 0, size);
	temp_count = 0;
}

proc free_arena(using a ^Arena) {
	if backing.procedure != nil {
		push_allocator backing {
			free(memory.data);
			memory = memory[0:0:0];
		}
	}
}

proc arena_allocator(arena ^Arena) -> Allocator {
	return Allocator{
		procedure = arena_allocator_proc,
		data = arena,
	};
}

proc arena_allocator_proc(allocator_data rawptr, mode Allocator_Mode,
                          size, alignment int,
                          old_memory rawptr, old_size int, flags u64) -> rawptr {
	var arena = allocator_data as ^Arena;

	match mode {
	case ALLOCATOR_ALLOC:
		var total_size = size + alignment;

		if arena.memory.count + total_size > arena.memory.capacity {
			fmt.fprintln(os.stderr, "Arena out of memory");
			return nil;
		}

		#no_bounds_check var end = ^arena.memory[arena.memory.count];

		var ptr = align_forward(end, alignment);
		arena.memory.count += total_size;
		return zero(ptr, size);

	case ALLOCATOR_FREE:
		// NOTE(bill): Free all at once
		// Use Arena_Temp_Memory if you want to free a block

	case ALLOCATOR_FREE_ALL:
		arena.memory.count = 0;

	case ALLOCATOR_RESIZE:
		return default_resize_align(old_memory, old_size, size, alignment);
	}

	return nil;
}

proc begin_arena_temp_memory(a ^Arena) -> Arena_Temp_Memory {
	var tmp Arena_Temp_Memory;
	tmp.arena = a;
	tmp.original_count = a.memory.count;
	a.temp_count++;
	return tmp;
}

proc end_arena_temp_memory(using tmp Arena_Temp_Memory) {
	assert(arena.memory.count >= original_count);
	assert(arena.temp_count > 0);
	arena.memory.count = original_count;
	arena.temp_count--;
}







proc align_of_type_info(type_info ^Type_Info) -> int {
	proc prev_pow2(n i64) -> i64 {
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

	const WORD_SIZE = size_of(int);
	const MAX_ALIGN = size_of([vector 64]f64); // TODO(bill): Should these constants be builtin constants?
	using Type_Info;

	match type info : type_info {
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
	case Pointer:
		return WORD_SIZE;
	case Maybe:
		return max(align_of_type_info(info.elem), 1);
	case Procedure:
		return WORD_SIZE;
	case Array:
		return align_of_type_info(info.elem);
	case Slice:
		return WORD_SIZE;
	case Vector:
		var size = size_of_type_info(info.elem);
		var count = max(prev_pow2(info.count as i64), 1) as int;
		var total = size * count;
		return clamp(total, 1, MAX_ALIGN);
	case Struct:
		return info.align;
	case Union:
		return info.align;
	case Raw_Union:
		return info.align;
	}

	return 0;
}

proc align_formula(size, align int) -> int {
	var result = size + align-1;
	return result - result%align;
}

proc size_of_type_info(type_info ^Type_Info) -> int {
	const WORD_SIZE = size_of(int);
	using Type_Info;
	match type info : type_info {
	case Named:
		return size_of_type_info(info.base);
	case Integer:
		return info.size;
	case Float:
		return info.size;
	case Any:
		return 2*WORD_SIZE;
	case String:
		return 2*WORD_SIZE;
	case Boolean:
		return 1;
	case Pointer:
		return WORD_SIZE;
	case Maybe:
		return size_of_type_info(info.elem) + 1;
	case Procedure:
		return WORD_SIZE;
	case Array:
		var count = info.count;
		if count == 0 {
			return 0;
		}
		var size      = size_of_type_info(info.elem);
		var align     = align_of_type_info(info.elem);
		var alignment = align_formula(size, align);
		return alignment*(count-1) + size;
	case Slice:
		return 3*WORD_SIZE;
	case Vector:
		proc is_bool(type_info ^Type_Info) -> bool {
			match type info : type_info {
			case Named:
				return is_bool(info.base);
			case Boolean:
				return true;
			}
			return false;
		}

		var count = info.count;
		if count == 0 {
			return 0;
		}
		var bit_size = 8*size_of_type_info(info.elem);
		if is_bool(info.elem) {
			// NOTE(bill): LLVM can store booleans as 1 bit because a boolean _is_ an `i1`
			// Silly LLVM spec
			bit_size = 1;
		}
		var total_size_in_bits = bit_size * count;
		var total_size = (total_size_in_bits+7)/8;
		return total_size;

	case Struct:
		return info.size;
	case Union:
		return info.size;
	case Raw_Union:
		return info.size;
	}

	return 0;
}

