#load "win32.odin"
#load "print.odin"

// IMPORTANT NOTE(bill): Do not change the order of any of this data
// The compiler relies upon this _exact_ order
Type_Info :: union {
	Member :: struct #ordered {
		name:      string     // can be empty if tuple
		type_info: ^Type_Info
		offset:    int        // offsets are not used in tuples
	}
	Record :: struct #ordered {
		fields: []Member
	}


	Named: struct #ordered {
		name: string
		base: ^Type_Info
	}
	Integer: struct #ordered {
		size: int // in bytes
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
		params:  ^Type_Info // Type_Info.Tuple
		results: ^Type_Info // Type_Info.Tuple
		variadic: bool
	}
	Array: struct #ordered {
		elem: ^Type_Info
		elem_size: int
		len: int
	}
	Slice: struct #ordered {
		elem: ^Type_Info
		elem_size: int
	}
	Vector: struct #ordered {
		elem: ^Type_Info
		elem_size: int
		len: int
	}
	Tuple:     Record
	Struct:    Record
	Union:     Record
	Raw_Union: Record
	Enum: struct #ordered {
		base: ^Type_Info
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

fmuladd_f32 :: proc(a, b, c: f32) -> f32 #foreign "llvm.fmuladd.f32"
fmuladd_f64 :: proc(a, b, c: f64) -> f64 #foreign "llvm.fmuladd.f64"

heap_alloc   :: proc(len: int) -> rawptr {
	return HeapAlloc(GetProcessHeap(), HEAP_ZERO_MEMORY, len)
}

heap_dealloc :: proc(ptr: rawptr) {
	_ = HeapFree(GetProcessHeap(), 0, ptr)
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
	llvm_memmove_64bit :: proc(dst, src: rawptr, len: int, align: i32, is_volatile: bool) #foreign "llvm.memmove.p0i8.p0i8.i64"
	llvm_memmove_64bit(dst, src, len, 1, false)
}

__string_eq :: proc(a, b: string) -> bool {
	if len(a) != len(b) {
		return false
	}
	if ^a[0] == ^b[0] {
		return true
	}
	return memory_compare(^a[0], ^b[0], len(a)) == 0
}

__string_cmp :: proc(a, b : string) -> int {
	// Translation of http://mgronhol.github.io/fast-strcmp/
	n := min(len(a), len(b))

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




Allocation_Mode :: enum {
	ALLOC,
	DEALLOC,
	DEALLOC_ALL,
	RESIZE,
}

Allocator_Proc :: type proc(allocator_data: rawptr, mode: Allocation_Mode,
                            size, alignment: int,
                            old_memory: rawptr, old_size: int, flags: u64) -> rawptr

Allocator :: struct {
	procedure: Allocator_Proc;
	data:      rawptr
}


Context :: struct {
	thread_ptr: rawptr

	user_data:  rawptr
	user_index: int

	allocator: Allocator
}

#thread_local context: Context

DEFAULT_ALIGNMENT :: 2*size_of(int)


__check_context :: proc() {
	if context.allocator.procedure == null {
		context.allocator = __default_allocator()
	}
	if context.thread_ptr == null {
		// TODO(bill):
		// context.thread_ptr = current_thread_pointer()
	}
}


alloc :: proc(size: int) -> rawptr #inline { return alloc_align(size, DEFAULT_ALIGNMENT) }

alloc_align :: proc(size, alignment: int) -> rawptr #inline {
	__check_context()
	a := context.allocator
	return a.procedure(a.data, Allocation_Mode.ALLOC, size, alignment, null, 0, 0)
}

dealloc :: proc(ptr: rawptr) #inline {
	__check_context()
	a := context.allocator
	_ = a.procedure(a.data, Allocation_Mode.DEALLOC, 0, 0, ptr, 0, 0)
}
dealloc_all :: proc(ptr: rawptr) #inline {
	__check_context()
	a := context.allocator
	_ = a.procedure(a.data, Allocation_Mode.DEALLOC_ALL, 0, 0, ptr, 0, 0)
}


resize       :: proc(ptr: rawptr, old_size, new_size: int) -> rawptr #inline { return resize_align(ptr, old_size, new_size, DEFAULT_ALIGNMENT) }
resize_align :: proc(ptr: rawptr, old_size, new_size, alignment: int) -> rawptr #inline {
	__check_context()
	a := context.allocator
	return a.procedure(a.data, Allocation_Mode.RESIZE, new_size, alignment, ptr, old_size, 0)
}



default_resize_align :: proc(old_memory: rawptr, old_size, new_size, alignment: int) -> rawptr {
	if old_memory == null {
		return alloc_align(new_size, alignment)
	}

	if new_size == 0 {
		dealloc(old_memory)
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
	dealloc(old_memory)
	return new_memory
}


__default_allocator_proc :: proc(allocator_data: rawptr, mode: Allocation_Mode,
                                 size, alignment: int,
                                 old_memory: rawptr, old_size: int, flags: u64) -> rawptr {
	using Allocation_Mode
	match mode {
	case ALLOC:
		return heap_alloc(size)
	case RESIZE:
		return default_resize_align(old_memory, old_size, size, alignment)
	case DEALLOC:
		heap_dealloc(old_memory)
		return null
	case DEALLOC_ALL:
		// NOTE(bill): Does nothing
	}

	return null
}

__default_allocator :: proc() -> Allocator {
	return Allocator{
		__default_allocator_proc,
		null,
	}
}




__assert :: proc(msg: string) {
	file_write(file_get_standard(File_Standard.ERROR), msg as []byte)
	__debug_trap()
}

__bounds_check_error :: proc(file: string, line, column: int,
                             index, count: int) {
	println_err("%(%:%) Index % is out of bounds range [0, %)",
	            file, line, column, index, count)
	__debug_trap()
}

__slice_expr_error :: proc(file: string, line, column: int,
                           low, high, max: int) {
	print_err("%(%:%) Invalid slice indices: [%:%:%]\n",
	          file, line, column, low, high, max)
	__debug_trap()
}
__substring_expr_error :: proc(file: string, line, column: int,
                               low, high: int) {
	print_err("%(%:%) Invalid substring indices: [%:%:%]\n",
	          file, line, column, low, high)
	__debug_trap()
}





