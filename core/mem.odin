#import "fmt.odin"
#import "os.odin"

set :: proc(data: rawptr, value: i32, len: int) -> rawptr #link_name "__mem_set" {
	llvm_memset_64bit :: proc(dst: rawptr, val: byte, len: int, align: i32, is_volatile: bool) #foreign "llvm.memset.p0i8.i64"
	llvm_memset_64bit(data, value as byte, len, 1, false)
	return data
}

zero :: proc(data: rawptr, len: int) -> rawptr {
	return set(data, 0, len)
}

copy :: proc(dst, src: rawptr, len: int) -> rawptr #link_name "__mem_copy" {
	// NOTE(bill): This _must_ implemented like C's memmove
	llvm_memmove_64bit :: proc(dst, src: rawptr, len: int, align: i32, is_volatile: bool) #foreign "llvm.memmove.p0i8.p0i8.i64"
	llvm_memmove_64bit(dst, src, len, 1, false)
	return dst
}

copy_non_overlapping :: proc(dst, src: rawptr, len: int) -> rawptr #link_name "__mem_copy_non_overlapping" {
	// NOTE(bill): This _must_ implemented like C's memcpy
	llvm_memcpy_64bit :: proc(dst, src: rawptr, len: int, align: i32, is_volatile: bool) #foreign "llvm.memcpy.p0i8.p0i8.i64"
	llvm_memcpy_64bit(dst, src, len, 1, false)
	return dst
}


compare :: proc(dst, src: rawptr, n: int) -> int #link_name "__mem_compare" {
	// Translation of http://mgronhol.github.io/fast-strcmp/
	a := slice_ptr(dst as ^byte, n)
	b := slice_ptr(src as ^byte, n)

	fast := n/size_of(int) + 1
	offset := (fast-1)*size_of(int)
	curr_block := 0
	if n <= size_of(int) {
		fast = 0
	}

	la := slice_ptr(^a[0] as ^int, fast)
	lb := slice_ptr(^b[0] as ^int, fast)

	for ; curr_block < fast; curr_block++ {
		if (la[curr_block] ~ lb[curr_block]) != 0 {
			for pos := curr_block*size_of(int); pos < n; pos++ {
				if (a[pos] ~ b[pos]) != 0 {
					return a[pos] as int - b[pos] as int
				}
			}
		}

	}

	for ; offset < n; offset++ {
		if (a[offset] ~ b[offset]) != 0 {
			return a[offset] as int - b[offset] as int
		}
	}

	return 0
}



kilobytes :: proc(x: int) -> int #inline { return          (x) * 1024 }
megabytes :: proc(x: int) -> int #inline { return kilobytes(x) * 1024 }
gigabytes :: proc(x: int) -> int #inline { return gigabytes(x) * 1024 }
terabytes :: proc(x: int) -> int #inline { return terabytes(x) * 1024 }

is_power_of_two :: proc(x: int) -> bool {
	if x <= 0 {
		return false
	}
	return (x & (x-1)) == 0
}

align_forward :: proc(ptr: rawptr, align: int) -> rawptr {
	assert(is_power_of_two(align))

	a := align as uint
	p := ptr as uint
	modulo := p & (a-1)
	if modulo != 0 {
		p += a - modulo
	}
	return p as rawptr
}


AllocationHeader :: struct {
	size: int
}
allocation_header_fill :: proc(header: ^AllocationHeader, data: rawptr, size: int) {
	header.size = size
	ptr := ptr_offset(header, 1) as ^int

	for i := 0; ptr as rawptr < data; i++ {
		ptr_offset(ptr, i)^ = -1
	}
}
allocation_header :: proc(data: rawptr) -> ^AllocationHeader {
	p := data as ^int
	for ptr_offset(p, -1)^ == -1 {
		p = ptr_offset(p, -1)
	}
	return ptr_offset(p as ^AllocationHeader, -1)
}



// Custom allocators

Arena :: struct {
	backing:    Allocator
	memory:     []u8
	temp_count: int
}

Temp_Arena_Memory :: struct {
	arena:          ^Arena
	original_count: int
}



init_arena_from_memory :: proc(using a: ^Arena, data: []byte) {
	backing    = Allocator{}
	memory     = data[:0]
	temp_count = 0
}

init_arena_from_context :: proc(using a: ^Arena, size: int) {
	backing = current_context().allocator
	memory = new_slice(u8, 0, size)
	temp_count = 0
}

init_sub_arena :: proc(sub, parent: ^Arena, size: int) {
	push_allocator arena_allocator(parent) {
		init_arena_from_context(sub, size)
	}
}

free_arena :: proc(using a: ^Arena) {
	if backing.procedure != null {
		push_allocator backing {
			free(memory.data)
			memory = memory[0:0:0]
		}
	}
}

arena_allocator :: proc(arena: ^Arena) -> Allocator {
	return Allocator{
		procedure = arena_allocator_proc,
		data = arena,
	}
}

arena_allocator_proc :: proc(allocator_data: rawptr, mode: Allocator.Mode,
                             size, alignment: int,
                             old_memory: rawptr, old_size: int, flags: u64) -> rawptr {
	arena := allocator_data as ^Arena

	using Allocator.Mode
	match mode {
	case ALLOC:
		total_size := size + alignment

		if arena.memory.count + total_size > arena.memory.capacity {
			fmt.fprintln(os.stderr, "Arena out of memory")
			return null
		}

		#no_bounds_check end := ^arena.memory[arena.memory.count]

		ptr := align_forward(end, alignment)
		arena.memory.count += total_size
		return zero(ptr, size)

	case FREE:
		// NOTE(bill): Free all at once
		// Use Temp_Arena_Memory if you want to free a block

	case FREE_ALL:
		arena.memory.count = 0

	case RESIZE:
		return default_resize_align(old_memory, old_size, size, alignment)
	}

	return null
}

begin_temp_arena_memory :: proc(a: ^Arena) -> Temp_Arena_Memory {
	tmp: Temp_Arena_Memory
	tmp.arena = a
	tmp.original_count = a.memory.count
	a.temp_count++
	return tmp
}

end_temp_arena_memory :: proc(using tmp: Temp_Arena_Memory) {
	assert(arena.memory.count >= original_count)
	assert(arena.temp_count > 0)
	arena.memory.count = original_count
	arena.temp_count--
}
