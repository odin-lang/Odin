#shared_global_scope;

#import "os.odin";
#import "fmt.odin";
#import "mem.odin";

// IMPORTANT NOTE(bill): `type_info` & `type_info_val` cannot be used within a
// #shared_global_scope due to  the internals of the compiler.
// This could change at a later date if the all these data structures are
// implemented within the compiler rather than in this "preload" file


// IMPORTANT NOTE(bill): Do not change the order of any of this data
// The compiler relies upon this _exact_ order
type Type_Info_Member struct #ordered {
	name      string;     // can be empty if tuple
	type_info ^Type_Info;
	offset    int;        // offsets are not used in tuples
}
type Type_Info_Record struct #ordered {
	fields  []Type_Info_Member;
	size    int; // in bytes
	align   int; // in bytes
	packed  bool;
	ordered bool;
}

type Type_Info union {
	Named struct #ordered {
		name string;
		base ^Type_Info; // This will _not_ be a Type_Info.Named
	};
	Integer struct #ordered {
		size   int; // in bytes
		signed bool;
	};
	Float struct #ordered {
		size int; // in bytes
	};
	Any     struct #ordered {};
	String  struct #ordered {};
	Boolean struct #ordered {};
	Pointer struct #ordered {
		elem ^Type_Info; // nil -> rawptr
	};
	Maybe struct #ordered {
		elem ^Type_Info;
	};
	Procedure struct #ordered {
		params   ^Type_Info; // Type_Info.Tuple
		results  ^Type_Info; // Type_Info.Tuple
		variadic bool;
	};
	Array struct #ordered {
		elem      ^Type_Info;
		elem_size int;
		count     int;
	};
	Slice struct #ordered {
		elem      ^Type_Info;
		elem_size int;
	};
	Vector struct #ordered {
		elem      ^Type_Info;
		elem_size int;
		count     int;
		align     int;
	};
	Tuple     Type_Info_Record;
	Struct    Type_Info_Record;
	Union     Type_Info_Record;
	Raw_Union Type_Info_Record;
	Enum struct #ordered {
		base   ^Type_Info;
		values []i64;
		names  []string;
	};
};

proc type_info_base(info ^Type_Info) -> ^Type_Info {
	if info == nil {
		return nil;
	}
	var base = info;
	match type i : base {
	case Type_Info.Named:
		base = i.base;
	}
	return base;
}



proc assume(cond bool) #foreign "llvm.assume"

proc __debug_trap      ()        #foreign "llvm.debugtrap"
proc __trap            ()        #foreign "llvm.trap"
proc read_cycle_counter() -> u64 #foreign "llvm.readcyclecounter"

proc bit_reverse16(b u16) -> u16 #foreign "llvm.bitreverse.i16"
proc bit_reverse32(b u32) -> u32 #foreign "llvm.bitreverse.i32"
proc bit_reverse64(b u64) -> u64 #foreign "llvm.bitreverse.i64"

proc byte_swap16(b u16) -> u16 #foreign "llvm.bswap.i16"
proc byte_swap32(b u32) -> u32 #foreign "llvm.bswap.i32"
proc byte_swap64(b u64) -> u64 #foreign "llvm.bswap.i64"

proc fmuladd32(a, b, c f32) -> f32 #foreign "llvm.fmuladd.f32"
proc fmuladd64(a, b, c f64) -> f64 #foreign "llvm.fmuladd.f64"






type Allocator_Mode enum {
	ALLOC,
	FREE,
	FREE_ALL,
	RESIZE,
}
type Allocator_Proc proc(allocator_data rawptr, mode Allocator_Mode,
                         size, alignment int,
                         old_memory rawptr, old_size int, flags u64) -> rawptr;



type Allocator struct #ordered {
	procedure Allocator_Proc;
	data      rawptr;
}


type Context struct #ordered {
	thread_id int;

	allocator Allocator;

	user_data  rawptr;
	user_index int;
}

#thread_local var __context Context;


const DEFAULT_ALIGNMENT = align_of([vector 4]f32);


proc __check_context() {
	var c = ^__context;

	if c.allocator.procedure == nil {
		c.allocator = default_allocator();
	}
	if c.thread_id == 0 {
		c.thread_id = os.current_thread_id();
	}
}

proc alloc(size int) -> rawptr #inline { return alloc_align(size, DEFAULT_ALIGNMENT); }

proc alloc_align(size, alignment int) -> rawptr #inline {
	__check_context();
	var a = context.allocator;
	return a.procedure(a.data, Allocator_Mode.ALLOC, size, alignment, nil, 0, 0);
}

proc free(ptr rawptr) #inline {
	__check_context();
	var a = context.allocator;
	if ptr != nil {
		a.procedure(a.data, Allocator_Mode.FREE, 0, 0, ptr, 0, 0);
	}
}
proc free_all() #inline {
	__check_context();
	var a = context.allocator;
	a.procedure(a.data, Allocator_Mode.FREE_ALL, 0, 0, nil, 0, 0);
}


proc resize      (ptr rawptr, old_size, new_size int) -> rawptr #inline { return resize_align(ptr, old_size, new_size, DEFAULT_ALIGNMENT); }
proc resize_align(ptr rawptr, old_size, new_size, alignment int) -> rawptr #inline {
	__check_context();
	var a = context.allocator;
	return a.procedure(a.data, Allocator_Mode.RESIZE, new_size, alignment, ptr, old_size, 0);
}



proc default_resize_align(old_memory rawptr, old_size, new_size, alignment int) -> rawptr {
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

	mem.copy(new_memory, old_memory, min(old_size, new_size));;
	free(old_memory);
	return new_memory;
}


proc default_allocator_proc(allocator_data rawptr, mode Allocator_Mode,
                            size, alignment int,
                            old_memory rawptr, old_size int, flags u64) -> rawptr {
	using Allocator_Mode;
	when false {
		match mode {
		case ALLOC:
			var total_size = size + alignment + size_of(mem.AllocationHeader);
			var ptr = os.heap_alloc(total_size);
			var header = ptr as ^mem.AllocationHeader;
			ptr = mem.align_forward(header+1, alignment);
			mem.allocation_header_fill(header, ptr, size);
			return mem.zero(ptr, size);

		case FREE:
			os.heap_free(mem.allocation_header(old_memory));
			return nil;

		case FREE_ALL:
			// NOTE(bill): Does nothing

		case RESIZE:
			var total_size = size + alignment + size_of(mem.AllocationHeader);
			var ptr = os.heap_resize(mem.allocation_header(old_memory), total_size);
			var header = ptr as ^mem.AllocationHeader;
			ptr = mem.align_forward(header+1, alignment);
			mem.allocation_header_fill(header, ptr, size);
			return mem.zero(ptr, size);
		}
	} else {
		match mode {
		case ALLOC:
			return os.heap_alloc(size);

		case FREE:
			os.heap_free(old_memory);
			return nil;

		case FREE_ALL:
			// NOTE(bill): Does nothing

		case RESIZE:
			return os.heap_resize(old_memory, size);
		}
	}

	return nil;
}

proc default_allocator() -> Allocator {
	return Allocator{
		procedure = default_allocator_proc,
		data = nil,
	};
}











proc __string_eq(a, b string) -> bool {
	if a.count != b.count {
		return false;
	}
	if a.data == b.data {
		return true;
	}
	return mem.compare(a.data, b.data, a.count) == 0;
}

proc __string_cmp(a, b string) -> int {
	return mem.compare(a.data, b.data, min(a.count, b.count));
}

proc __string_ne(a, b string) -> bool #inline { return !__string_eq(a, b); }
proc __string_lt(a, b string) -> bool #inline { return __string_cmp(a, b) < 0; }
proc __string_gt(a, b string) -> bool #inline { return __string_cmp(a, b) > 0; }
proc __string_le(a, b string) -> bool #inline { return __string_cmp(a, b) <= 0; }
proc __string_ge(a, b string) -> bool #inline { return __string_cmp(a, b) >= 0; }


proc __assert(file string, line, column int, msg string) #inline {
	fmt.fprintf(os.stderr, "%(%:%) Runtime assertion: %\n",
	            file, line, column, msg);
	__debug_trap();
}

proc __bounds_check_error(file string, line, column int, index, count int) {
	if 0 <= index && index < count {
		return;
	}
	fmt.fprintf(os.stderr, "%(%:%) Index % is out of bounds range [0, %)\n",
	            file, line, column, index, count);
	__debug_trap();
}

proc __slice_expr_error(file string, line, column int, low, high, max int) {
	if 0 <= low && low <= high && high <= max {
		return;
	}
	fmt.fprintf(os.stderr, "%(%:%) Invalid slice indices: [%:%:%]\n",
	            file, line, column, low, high, max);
	__debug_trap();
}
proc __substring_expr_error(file string, line, column int, low, high int) {
	if 0 <= low && low <= high {
		return;
	}
	fmt.fprintf(os.stderr, "%(%:%) Invalid substring indices: [%:%:%]\n",
	            file, line, column, low, high);
	__debug_trap();
}

proc __enum_to_string(info ^Type_Info, value i64) -> string {
	match type ti : type_info_base(info) {
	case Type_Info.Enum:
		// TODO(bill): Search faster than linearly
		for var i = 0; i < ti.values.count; i++ {
			if ti.values[i] == value {
				return ti.names[i];
			}
		}
	}
	return "";
}


