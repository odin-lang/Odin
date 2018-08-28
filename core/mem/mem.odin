package mem

import "core:runtime"

foreign _ {
	@(link_name = "llvm.bswap.i16") swap16 :: proc(b: u16) -> u16 ---;
	@(link_name = "llvm.bswap.i32") swap32 :: proc(b: u32) -> u32 ---;
	@(link_name = "llvm.bswap.i64") swap64 :: proc(b: u64) -> u64 ---;
}
swap :: proc[swap16, swap32, swap64];


set :: proc "contextless" (data: rawptr, value: i32, len: int) -> rawptr {
	if data == nil do return nil;
	foreign _ {
		when size_of(rawptr) == 8 {
			@(link_name="llvm.memset.p0i8.i64")
			llvm_memset :: proc(dst: rawptr, val: byte, len: int, align: i32, is_volatile: bool) ---;
		} else {
			@(link_name="llvm.memset.p0i8.i32")
			llvm_memset :: proc(dst: rawptr, val: byte, len: int, align: i32, is_volatile: bool) ---;
		}
	}
	llvm_memset(data, byte(value), len, 1, false);
	return data;
}
zero :: proc "contextless" (data: rawptr, len: int) -> rawptr {
	return set(data, 0, len);
}
copy :: proc "contextless" (dst, src: rawptr, len: int) -> rawptr {
	if src == nil do return dst;
	// NOTE(bill): This _must_ be implemented like C's memmove
	foreign _ {
		when size_of(rawptr) == 8 {
			@(link_name="llvm.memmove.p0i8.p0i8.i64")
			llvm_memmove :: proc(dst, src: rawptr, len: int, align: i32, is_volatile: bool) ---;
		} else {
			@(link_name="llvm.memmove.p0i8.p0i8.i32")
			llvm_memmove :: proc(dst, src: rawptr, len: int, align: i32, is_volatile: bool) ---;
		}
	}
	llvm_memmove(dst, src, len, 1, false);
	return dst;
}
copy_non_overlapping :: proc "contextless" (dst, src: rawptr, len: int) -> rawptr {
	if src == nil do return dst;
	// NOTE(bill): This _must_ be implemented like C's memcpy
	foreign _ {
		when size_of(rawptr) == 8 {
			@(link_name="llvm.memcpy.p0i8.p0i8.i64")
	 		llvm_memcpy :: proc(dst, src: rawptr, len: int, align: i32, is_volatile: bool) ---;
		} else {
			@(link_name="llvm.memcpy.p0i8.p0i8.i32")
	 		llvm_memcpy :: proc(dst, src: rawptr, len: int, align: i32, is_volatile: bool) ---;
		}
	}
	llvm_memcpy(dst, src, len, 1, false);
	return dst;
}
compare :: proc "contextless" (a, b: []byte) -> int {
	return compare_byte_ptrs(&a[0], &b[0], min(len(a), len(b)));
}
compare_byte_ptrs :: proc "contextless" (a, b: ^byte, n: int) -> int {
	pa :: ptr_offset;
	for i in 0..n-1 do switch {
	case pa(a, i)^ < pa(b, i)^: return -1;
	case pa(a, i)^ > pa(b, i)^: return +1;
	}
	return 0;
}

compare_ptrs :: inline proc "contextless" (a, b: rawptr, n: int) -> int {
	return compare_byte_ptrs((^byte)(a), (^byte)(b), n);
}

ptr_offset :: proc "contextless" (ptr: $P/^$T, n: int) -> P {
	new := int(uintptr(ptr)) + size_of(T)*n;
	return P(uintptr(new));
}

ptr_sub :: proc "contextless" (a, b: $P/^$T) -> int {
	return (int(uintptr(a)) - int(uintptr(b)))/size_of(T);
}

slice_ptr :: proc "contextless" (ptr: ^$T, len: int) -> []T {
	assert(len >= 0);
	slice := Raw_Slice{data = ptr, len = len};
	return transmute([]T)slice;
}

slice_to_bytes :: proc "contextless" (slice: $E/[]$T) -> []byte {
	s := transmute(Raw_Slice)slice;
	s.len *= size_of(T);
	return transmute([]byte)s;
}


buffer_from_slice :: proc(backing: $T/[]$E) -> [dynamic]E {
	s := transmute(Raw_Slice)backing;
	d := Raw_Dynamic_Array{
		data      = s.data,
		len       = 0,
		cap       = s.len,
		allocator = nil_allocator(),
	};
	return transmute([dynamic]E)d;
}

ptr_to_bytes :: proc "contextless" (ptr: ^$T, len := 1) -> []byte {
	assert(len >= 0);
	return transmute([]byte)Raw_Slice{ptr, len*size_of(T)};
}

any_to_bytes :: proc "contextless" (val: any) -> []byte {
	ti := type_info_of(val.typeid);
	size := ti != nil ? ti.size : 0;
	return transmute([]byte)Raw_Slice{val.data, size};
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
	ptr := cast(^uint)(ptr_offset(header, 1));
	n := ptr_sub(cast(^uint)data, ptr);

	for i in 0..n-1 {
		ptr_offset(ptr, i)^ = ~uint(0);
	}
}
allocation_header :: proc(data: rawptr) -> ^AllocationHeader {
	if data == nil do return nil;
	p := cast(^uint)data;
	for ptr_offset(p, -1)^ == ~uint(0) do p = ptr_offset(p, -1);
	return (^AllocationHeader)(ptr_offset(p, -1));
}


Fixed_Byte_Buffer :: distinct [dynamic]byte;

make_fixed_byte_buffer :: proc(backing: []byte) -> Fixed_Byte_Buffer {
	s := transmute(Raw_Slice)backing;
	d: Raw_Dynamic_Array;
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


context_from_allocator :: proc(a: Allocator) -> runtime.Context {
	c := context;
	c.allocator = a;
	return c;
}

destroy_arena :: proc(using a: ^Arena) {
	if backing.procedure != nil {
		context = context_from_allocator(backing);
		if memory != nil {
			free(&memory[0]);
		}
		memory = nil;
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
		(^Raw_Slice)(&arena.memory).len += total_size;
		return zero(ptr, size);

	case Free:
		// NOTE(bill): Free all at once
		// Use ArenaTempMemory if you want to free a block

	case Free_All:
		(^Raw_Slice)(&arena.memory).len = 0;

	case Resize:
		return default_resize_align(old_memory, old_size, size, alignment, arena_allocator(arena));
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
	(^Raw_Dynamic_Array)(&arena.memory).len = original_count;
	arena.temp_count -= 1;
}



align_formula :: proc(size, align: int) -> int {
	result := size + align-1;
	return result - result%align;
}
