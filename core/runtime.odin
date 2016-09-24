#shared_global_scope

#import "os.odin"
#import "fmt.odin"
#import "mem.odin"

// IMPORTANT NOTE(bill): Do not change the order of any of this data
// The compiler relies upon this _exact_ order
Type_Info :: union {
	Member :: struct #ordered {
		name:      string     // can be empty if tuple
		type_info: ^Type_Info
		offset:    int        // offsets are not used in tuples
	}
	Record :: struct #ordered {
		fields:  []Member
		packed:  bool
		ordered: bool
	}

	Named: struct #ordered {
		name: string
		base: ^Type_Info
	}
	Integer: struct #ordered {
		size:   int // in bytes
		signed: bool
	}
	Float: struct #ordered {
		size: int // in bytes
	}
	String:  struct #ordered {}
	Boolean: struct #ordered {}
	Pointer: struct #ordered {
		elem: ^Type_Info
	}
	Procedure: struct #ordered {
		params:   ^Type_Info // Type_Info.Tuple
		results:  ^Type_Info // Type_Info.Tuple
		variadic: bool
	}
	Array: struct #ordered {
		elem:      ^Type_Info
		elem_size: int
		count:     int
	}
	Slice: struct #ordered {
		elem:      ^Type_Info
		elem_size: int
	}
	Vector: struct #ordered {
		elem:      ^Type_Info
		elem_size: int
		count:     int
	}
	Tuple:     Record
	Struct:    Record
	Union:     Record
	Raw_Union: Record
	Enum: struct #ordered {
		base: ^Type_Info
		values: []i64
		names:  []string
	}
}

type_info_base :: proc(info: ^Type_Info) -> ^Type_Info {
	if info == null {
		return null
	}
	for {
		match type i : info {
		case Type_Info.Named:
			info = i.base
			continue
		}

		return info
	}
}



assume :: proc(cond: bool) #foreign "llvm.assume"

__debug_trap       :: proc()        #foreign "llvm.debugtrap"
__trap             :: proc()        #foreign "llvm.trap"
read_cycle_counter :: proc() -> u64 #foreign "llvm.readcyclecounter"

bit_reverse16 :: proc(b: u16) -> u16 #foreign "llvm.bitreverse.i16"
bit_reverse32 :: proc(b: u32) -> u32 #foreign "llvm.bitreverse.i32"
bit_reverse64 :: proc(b: u64) -> u64 #foreign "llvm.bitreverse.i64"

byte_swap16 :: proc(b: u16) -> u16 #foreign "llvm.bswap.i16"
byte_swap32 :: proc(b: u32) -> u32 #foreign "llvm.bswap.i32"
byte_swap64 :: proc(b: u64) -> u64 #foreign "llvm.bswap.i64"

fmuladd32 :: proc(a, b, c: f32) -> f32 #foreign "llvm.fmuladd.f32"
fmuladd64 :: proc(a, b, c: f64) -> f64 #foreign "llvm.fmuladd.f64"

current_thread_id :: proc() -> int {
	GetCurrentThreadId :: proc() -> u32 #foreign #dll_import
	return GetCurrentThreadId() as int
}

memory_zero :: proc(data: rawptr, len: int) {
	llvm_memset_64bit :: proc(dst: rawptr, val: byte, len: int, align: i32, is_volatile: bool) #foreign "llvm.memset.p0i8.i64"
	llvm_memset_64bit(data, 0, len, 1, false)
}

memory_compare :: proc(dst, src: rawptr, len: int) -> int {
	// TODO(bill): make a faster `memory_compare`
	a := slice_ptr(dst as ^byte, len)
	b := slice_ptr(src as ^byte, len)
	for i := 0; i < len; i++ {
		if a[i] != b[i] {
			return (a[i] - b[i]) as int
		}
	}
	return 0
}

memory_copy :: proc(dst, src: rawptr, len: int) #inline {
	// NOTE(bill): This _must_ implemented like C's memmove
	llvm_memmove_64bit :: proc(dst, src: rawptr, len: int, align: i32, is_volatile: bool) #foreign "llvm.memmove.p0i8.p0i8.i64"
	llvm_memmove_64bit(dst, src, len, 1, false)
}









Allocator :: struct #ordered {
	Mode :: enum {
		ALLOC,
		FREE,
		FREE_ALL,
		RESIZE,
	}
	Proc :: type proc(allocator_data: rawptr, mode: Mode,
	                  size, alignment: int,
	                  old_memory: rawptr, old_size: int, flags: u64) -> rawptr


	procedure: Proc;
	data:      rawptr
}


Context :: struct #ordered {
	thread_id: int

	allocator: Allocator

	user_data:  rawptr
	user_index: int
}

#thread_local __context: Context


DEFAULT_ALIGNMENT :: align_of({4}f32)


current_context :: proc() -> Context { // Copy of context
	return __context
}

__check_context :: proc() {
	c := ^__context

	if c.allocator.procedure == null {
		c.allocator = __default_allocator()
	}
	if c.thread_id == 0 {
		c.thread_id = current_thread_id()
	}
}

alloc :: proc(size: int) -> rawptr #inline { return alloc_align(size, DEFAULT_ALIGNMENT) }

alloc_align :: proc(size, alignment: int) -> rawptr #inline {
	__check_context()
	a := current_context().allocator
	return a.procedure(a.data, Allocator.Mode.ALLOC, size, alignment, null, 0, 0)
}

free :: proc(ptr: rawptr) #inline {
	__check_context()
	a := current_context().allocator
	if ptr != null {
		a.procedure(a.data, Allocator.Mode.FREE, 0, 0, ptr, 0, 0)
	}
}
free_all :: proc() #inline {
	__check_context()
	a := current_context().allocator
	a.procedure(a.data, Allocator.Mode.FREE_ALL, 0, 0, null, 0, 0)
}


resize       :: proc(ptr: rawptr, old_size, new_size: int) -> rawptr #inline { return resize_align(ptr, old_size, new_size, DEFAULT_ALIGNMENT) }
resize_align :: proc(ptr: rawptr, old_size, new_size, alignment: int) -> rawptr #inline {
	a := current_context().allocator
	return a.procedure(a.data, Allocator.Mode.RESIZE, new_size, alignment, ptr, old_size, 0)
}



default_resize_align :: proc(old_memory: rawptr, old_size, new_size, alignment: int) -> rawptr {
	if old_memory == null {
		return alloc_align(new_size, alignment)
	}

	if new_size == 0 {
		free(old_memory)
		return null
	}

	if new_size == old_size {
		return old_memory
	}

	new_memory := alloc_align(new_size, alignment)
	if new_memory == null {
		return null
	}

	memory_copy(new_memory, old_memory, min(old_size, new_size));
	free(old_memory)
	return new_memory
}


__default_allocator_proc :: proc(allocator_data: rawptr, mode: Allocator.Mode,
                                 size, alignment: int,
                                 old_memory: rawptr, old_size: int, flags: u64) -> rawptr {
	using Allocator.Mode
	match mode {
	case ALLOC:
		total_size := size + alignment + size_of(mem.AllocationHeader)
		ptr := os.heap_alloc(total_size)
		header := ptr as ^mem.AllocationHeader
		ptr = mem.align_forward(ptr_offset(header, 1), alignment)
		mem.allocation_header_fill(header, ptr, size)
		memory_zero(ptr, size)
		return ptr
	case FREE:
		os.heap_free(mem.allocation_header(old_memory))
		return null
	case FREE_ALL:
		// NOTE(bill): Does nothing
	case RESIZE:
		total_size := size + alignment + size_of(mem.AllocationHeader)
		ptr := os.heap_resize(mem.allocation_header(old_memory), total_size)
		header := ptr as ^mem.AllocationHeader
		ptr = mem.align_forward(ptr_offset(header, 1), alignment)
		mem.allocation_header_fill(header, ptr, size)
		memory_zero(ptr, size)
		return ptr
	}

	return null
}

__default_allocator :: proc() -> Allocator {
	return Allocator{
		procedure = __default_allocator_proc,
		data = null,
	}
}











__string_eq :: proc(a, b: string) -> bool {
	if a.count != b.count {
		return false
	}
	if ^a[0] == ^b[0] {
		return true
	}
	return memory_compare(^a[0], ^b[0], a.count) == 0
}

__string_cmp :: proc(a, b : string) -> int {
	// Translation of http://mgronhol.github.io/fast-strcmp/
	n := min(a.count, b.count)

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

__string_ne :: proc(a, b : string) -> bool #inline { return !__string_eq(a, b) }
__string_lt :: proc(a, b : string) -> bool #inline { return __string_cmp(a, b) < 0 }
__string_gt :: proc(a, b : string) -> bool #inline { return __string_cmp(a, b) > 0 }
__string_le :: proc(a, b : string) -> bool #inline { return __string_cmp(a, b) <= 0 }
__string_ge :: proc(a, b : string) -> bool #inline { return __string_cmp(a, b) >= 0 }


__assert :: proc(file: string, line, column: int, msg: string) #inline {
	fmt.fprintf(os.stderr, "%(%:%) Runtime assertion: %\n",
	            file, line, column, msg)
	__debug_trap()
}

__bounds_check_error :: proc(file: string, line, column: int,
                             index, count: int) {
	if 0 <= index && index < count {
		return
	}
	fmt.fprintf(os.stderr, "%(%:%) Index % is out of bounds range [0, %)\n",
	            file, line, column, index, count)
	__debug_trap()
}

__slice_expr_error :: proc(file: string, line, column: int,
                           low, high, max: int) {
	if 0 <= low && low <= high && high <= max {
		return
	}
	fmt.fprintf(os.stderr, "%(%:%) Invalid slice indices: [%:%:%]\n",
	            file, line, column, low, high, max)
	__debug_trap()
}
__substring_expr_error :: proc(file: string, line, column: int,
                               low, high: int) {
	if 0 <= low && low <= high {
		return
	}
	fmt.fprintf(os.stderr, "%(%:%) Invalid substring indices: [%:%:%]\n",
	            file, line, column, low, high)
	__debug_trap()
}

__enum_to_string :: proc(info: ^Type_Info, value: i64) -> string {
	info = type_info_base(info)

	match type ti : info {
	case Type_Info.Enum:
		// TODO(bill): Search faster than linearly
		for i := 0; i < ti.values.count; i++ {
			if ti.values[i] == value {
				return ti.names[i]
			}
		}
	}
	return ""
}



