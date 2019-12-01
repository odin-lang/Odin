package mem

import "core:runtime"

foreign _ {
	@(link_name = "llvm.bswap.i16") swap16 :: proc(b: u16) -> u16 ---;
	@(link_name = "llvm.bswap.i32") swap32 :: proc(b: u32) -> u32 ---;
	@(link_name = "llvm.bswap.i64") swap64 :: proc(b: u64) -> u64 ---;
}
swap :: proc{swap16, swap32, swap64};



set :: proc "contextless" (data: rawptr, value: byte, len: int) -> rawptr {
	if data == nil do return nil;
	if len < 0 do return data;
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
zero :: inline proc "contextless" (data: rawptr, len: int) -> rawptr {
	return set(data, 0, len);
}
zero_item :: inline proc "contextless" (item: $P/^$T) {
	set(item, 0, size_of(T));
}
zero_slice :: proc "contextless" (data: $T/[]$E) {
	if n := len(data); n > 0 {
		zero(&data[0], size_of(E)*n);
	}
}


copy :: proc "contextless" (dst, src: rawptr, len: int) -> rawptr {
	return runtime.mem_copy(dst, src, len);
}
copy_non_overlapping :: proc "contextless" (dst, src: rawptr, len: int) -> rawptr {
	return runtime.mem_copy_non_overlapping(dst, src, len);
}
compare :: inline proc "contextless" (a, b: []byte) -> int {
	return compare_byte_ptrs(&a[0], &b[0], min(len(a), len(b)));
}
compare_byte_ptrs :: proc "contextless" (a, b: ^byte, n: int) -> int #no_bounds_check {
	x := slice_ptr(a, n);
	y := slice_ptr(b, n);

	SU :: size_of(uintptr);
	fast := n/SU + 1;
	offset := (fast-1)*SU;
	curr_block := 0;
	if n < SU {
		fast = 0;
	}

	la := slice_ptr((^uintptr)(a), fast);
	lb := slice_ptr((^uintptr)(b), fast);

	for /**/; curr_block < fast; curr_block += 1 {
		if la[curr_block] ~ lb[curr_block] != 0 {
			for pos := curr_block*SU; pos < n; pos += 1 {
				if x[pos] ~ y[pos] != 0 {
					return (int(x[pos]) - int(y[pos])) < 0 ? -1 : +1;
				}
			}
		}
	}

	for /**/; offset < n; offset += 1 {
		if x[offset] ~ y[offset] != 0 {
			return (int(x[offset]) - int(y[offset])) < 0 ? -1 : +1;
		}
	}

	return 0;
}

compare_ptrs :: inline proc "contextless" (a, b: rawptr, n: int) -> int {
	return compare_byte_ptrs((^byte)(a), (^byte)(b), n);
}

ptr_offset :: inline proc "contextless" (ptr: $P/^$T, n: int) -> P {
	new := int(uintptr(ptr)) + size_of(T)*n;
	return P(uintptr(new));
}

ptr_sub :: inline proc "contextless" (a, b: $P/^$T) -> int {
	return (int(uintptr(a)) - int(uintptr(b)))/size_of(T);
}

slice_ptr :: inline proc "contextless" (ptr: ^$T, len: int) -> []T {
	assert(len >= 0);
	slice := Raw_Slice{data = ptr, len = len};
	return transmute([]T)slice;
}

slice_to_bytes :: inline proc "contextless" (slice: $E/[]$T) -> []byte {
	s := transmute(Raw_Slice)slice;
	s.len *= size_of(T);
	return transmute([]byte)s;
}

slice_data_cast :: inline proc "contextless" ($T: typeid/[]$A, slice: $S/[]$B) -> T {
	when size_of(A) == 0 || size_of(B) == 0 {
		return nil;
	} else {
		s := transmute(Raw_Slice)slice;
		s.len = (len(slice) * size_of(B)) / size_of(A);
		return transmute(T)s;
	}
}


buffer_from_slice :: inline proc(backing: $T/[]$E) -> [dynamic]E {
	s := transmute(Raw_Slice)backing;
	d := Raw_Dynamic_Array{
		data      = s.data,
		len       = 0,
		cap       = s.len,
		allocator = nil_allocator(),
	};
	return transmute([dynamic]E)d;
}

ptr_to_bytes :: inline proc "contextless" (ptr: ^$T, len := 1) -> []byte {
	assert(len >= 0);
	return transmute([]byte)Raw_Slice{ptr, len*size_of(T)};
}

any_to_bytes :: inline proc "contextless" (val: any) -> []byte {
	ti := type_info_of(val.id);
	size := ti != nil ? ti.size : 0;
	return transmute([]byte)Raw_Slice{val.data, size};
}


kilobytes :: inline proc "contextless" (x: int) -> int do return          (x) * 1024;
megabytes :: inline proc "contextless" (x: int) -> int do return kilobytes(x) * 1024;
gigabytes :: inline proc "contextless" (x: int) -> int do return megabytes(x) * 1024;
terabytes :: inline proc "contextless" (x: int) -> int do return gigabytes(x) * 1024;

is_power_of_two :: inline proc(x: uintptr) -> bool {
	if x <= 0 do return false;
	return (x & (x-1)) == 0;
}

align_forward :: inline proc(ptr: rawptr, align: uintptr) -> rawptr {
	return rawptr(align_forward_uintptr(uintptr(ptr), align));
}

align_forward_uintptr :: proc(ptr, align: uintptr) -> uintptr {
	assert(is_power_of_two(align));

	p := ptr;
	modulo := p & (align-1);
	if modulo != 0 do p += align - modulo;
	return p;
}

align_forward_int :: inline proc(ptr, align: int) -> int {
	return int(align_forward_uintptr(uintptr(ptr), uintptr(align)));
}
align_forward_uint :: inline proc(ptr, align: uint) -> uint {
	return uint(align_forward_uintptr(uintptr(ptr), uintptr(align)));
}

align_backward :: inline proc(ptr: rawptr, align: uintptr) -> rawptr {
	return rawptr(align_backward_uintptr(uintptr(ptr), align));
}

align_backward_uintptr :: proc(ptr, align: uintptr) -> uintptr {
	assert(is_power_of_two(align));

	ptr := rawptr(ptr - align);
	return uintptr(align_forward(ptr, align));
}

align_backward_int :: inline proc(ptr, align: int) -> int {
	return int(align_backward_uintptr(uintptr(ptr), uintptr(align)));
}
align_backward_uint :: inline proc(ptr, align: uint) -> uint {
	return uint(align_backward_uintptr(uintptr(ptr), uintptr(align)));
}

context_from_allocator :: proc(a: Allocator) -> type_of(context) {
	context.allocator = a;
	return context;
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



align_formula :: proc(size, align: int) -> int {
	result := size + align-1;
	return result - result%align;
}

calc_padding_with_header :: proc(ptr: uintptr, align: uintptr, header_size: int) -> int {
	p := uintptr(ptr);
	a := uintptr(align);
	modulo := p & (a-1);

	padding := uintptr(0);
	if modulo != 0 do padding = a - modulo;

	needed_space := uintptr(header_size);
	if padding < needed_space {
		needed_space -= padding;

		if needed_space & (a-1) > 0 {
			padding += align * (1+(needed_space/align));
		} else {
			padding += align * (needed_space/align);
		}
	}

	return int(padding);
}
