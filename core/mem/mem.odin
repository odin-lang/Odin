package mem

import "core:runtime"
import "core:intrinsics"

Byte     :: 1
Kilobyte :: 1024 * Byte
Megabyte :: 1024 * Kilobyte
Gigabyte :: 1024 * Megabyte
Terabyte :: 1024 * Gigabyte

set :: proc "contextless" (data: rawptr, value: byte, len: int) -> rawptr {
	return runtime.memset(data, i32(value), len)
}
zero :: proc "contextless" (data: rawptr, len: int) -> rawptr {
	intrinsics.mem_zero(data, len)
	return data
}
zero_explicit :: proc "contextless" (data: rawptr, len: int) -> rawptr {
	// This routine tries to avoid the compiler optimizing away the call,
	// so that it is always executed.  It is intended to provided
	// equivalent semantics to those provided by the C11 Annex K 3.7.4.1
	// memset_s call.
	intrinsics.mem_zero_volatile(data, len) // Use the volatile mem_zero
	intrinsics.atomic_thread_fence(.Seq_Cst) // Prevent reordering
	return data
}
zero_item :: proc "contextless" (item: $P/^$T) {
	intrinsics.mem_zero(item, size_of(T))
}
zero_slice :: proc "contextless" (data: $T/[]$E) {
	zero(raw_data(data), size_of(E)*len(data))
}


copy :: proc "contextless" (dst, src: rawptr, len: int) -> rawptr {
	intrinsics.mem_copy(dst, src, len)
	return dst
}
copy_non_overlapping :: proc "contextless" (dst, src: rawptr, len: int) -> rawptr {
	intrinsics.mem_copy_non_overlapping(dst, src, len)
	return dst
}
compare :: proc "contextless" (a, b: []byte) -> int {
	res := compare_byte_ptrs(raw_data(a), raw_data(b), min(len(a), len(b)))
	if res == 0 && len(a) != len(b) {
		return len(a) <= len(b) ? -1 : +1
	} else if len(a) == 0 && len(b) == 0 {
		return 0
	}
	return res
}

compare_byte_ptrs :: proc "contextless" (a, b: ^byte, n: int) -> int #no_bounds_check {
	switch {
	case a == b:
		return 0
	case a == nil:
		return -1
	case b == nil:
		return -1
	case n == 0:
		return 0
	}

	x := slice_ptr(a, n)
	y := slice_ptr(b, n)

	SU :: size_of(uintptr)
	fast := n/SU + 1
	offset := (fast-1)*SU
	curr_block := 0
	if n < SU {
		fast = 0
	}

	la := slice_ptr((^uintptr)(a), fast)
	lb := slice_ptr((^uintptr)(b), fast)

	for /**/; curr_block < fast; curr_block += 1 {
		if la[curr_block] ~ lb[curr_block] != 0 {
			for pos := curr_block*SU; pos < n; pos += 1 {
				if x[pos] ~ y[pos] != 0 {
					return (int(x[pos]) - int(y[pos])) < 0 ? -1 : +1
				}
			}
		}
	}

	for /**/; offset < n; offset += 1 {
		if x[offset] ~ y[offset] != 0 {
			return (int(x[offset]) - int(y[offset])) < 0 ? -1 : +1
		}
	}

	return 0
}

check_zero :: proc(data: []byte) -> bool {
	return check_zero_ptr(raw_data(data), len(data))
}

check_zero_ptr :: proc(ptr: rawptr, len: int) -> bool {
	switch {
	case len <= 0:
		return true
	case ptr == nil:
		return true
	}

	start := uintptr(ptr)
	start_aligned := align_forward_uintptr(start, align_of(uintptr))
	end := start + uintptr(len)
	end_aligned := align_backward_uintptr(end, align_of(uintptr))

	for b in start..<start_aligned {
		if (^byte)(b)^ != 0 {
			return false
		}
	}

	for b := start_aligned; b < end_aligned; b += size_of(uintptr) {
		if (^uintptr)(b)^ != 0 {
			return false
		}
	}

	for b in end_aligned..<end {
		if (^byte)(b)^ != 0 {
			return false
		}
	}

	return true
}

simple_equal :: proc "contextless" (a, b: $T) -> bool where intrinsics.type_is_simple_compare(T) {
	a, b := a, b
	return compare_byte_ptrs((^byte)(&a), (^byte)(&b), size_of(T)) == 0
}

compare_ptrs :: proc "contextless" (a, b: rawptr, n: int) -> int {
	return compare_byte_ptrs((^byte)(a), (^byte)(b), n)
}

ptr_offset :: intrinsics.ptr_offset
ptr_sub :: intrinsics.ptr_sub

slice_ptr :: proc "contextless" (ptr: ^$T, len: int) -> []T {
	return ([^]T)(ptr)[:len]
}

byte_slice :: #force_inline proc "contextless" (data: rawptr, len: int) -> []byte {
	return ([^]u8)(data)[:max(len, 0)]
}

slice_to_bytes :: proc "contextless" (slice: $E/[]$T) -> []byte {
	s := transmute(Raw_Slice)slice
	s.len *= size_of(T)
	return transmute([]byte)s
}

slice_data_cast :: proc "contextless" ($T: typeid/[]$A, slice: $S/[]$B) -> T {
	when size_of(A) == 0 || size_of(B) == 0 {
		return nil
	} else {
		s := transmute(Raw_Slice)slice
		s.len = (len(slice) * size_of(B)) / size_of(A)
		return transmute(T)s
	}
}

slice_to_components :: proc "contextless" (slice: $E/[]$T) -> (data: ^T, len: int) {
	s := transmute(Raw_Slice)slice
	return (^T)(s.data), s.len
}

buffer_from_slice :: proc "contextless" (backing: $T/[]$E) -> [dynamic]E {
	return transmute([dynamic]E)Raw_Dynamic_Array{
		data      = raw_data(backing),
		len       = 0,
		cap       = len(backing),
		allocator = Allocator{
			procedure = nil_allocator_proc,
			data = nil,
		},
	}
}

ptr_to_bytes :: proc "contextless" (ptr: ^$T, len := 1) -> []byte {
	return transmute([]byte)Raw_Slice{ptr, len*size_of(T)}
}

any_to_bytes :: proc "contextless" (val: any) -> []byte {
	ti := type_info_of(val.id)
	size := ti != nil ? ti.size : 0
	return transmute([]byte)Raw_Slice{val.data, size}
}


is_power_of_two :: proc "contextless" (x: uintptr) -> bool {
	if x <= 0 {
		return false
	}
	return (x & (x-1)) == 0
}

align_forward :: proc(ptr: rawptr, align: uintptr) -> rawptr {
	return rawptr(align_forward_uintptr(uintptr(ptr), align))
}

align_forward_uintptr :: proc(ptr, align: uintptr) -> uintptr {
	assert(is_power_of_two(align))

	p := ptr
	modulo := p & (align-1)
	if modulo != 0 {
		p += align - modulo
	}
	return p
}

align_forward_int :: proc(ptr, align: int) -> int {
	return int(align_forward_uintptr(uintptr(ptr), uintptr(align)))
}
align_forward_uint :: proc(ptr, align: uint) -> uint {
	return uint(align_forward_uintptr(uintptr(ptr), uintptr(align)))
}

align_backward :: proc(ptr: rawptr, align: uintptr) -> rawptr {
	return rawptr(align_backward_uintptr(uintptr(ptr), align))
}

align_backward_uintptr :: proc(ptr, align: uintptr) -> uintptr {
	return align_forward_uintptr(ptr - align + 1, align)
}

align_backward_int :: proc(ptr, align: int) -> int {
	return int(align_backward_uintptr(uintptr(ptr), uintptr(align)))
}
align_backward_uint :: proc(ptr, align: uint) -> uint {
	return uint(align_backward_uintptr(uintptr(ptr), uintptr(align)))
}

context_from_allocator :: proc(a: Allocator) -> type_of(context) {
	context.allocator = a
	return context
}

reinterpret_copy :: proc "contextless" ($T: typeid, ptr: rawptr) -> (value: T) {
	copy(&value, ptr, size_of(T))
	return
}


Fixed_Byte_Buffer :: distinct [dynamic]byte

make_fixed_byte_buffer :: proc "contextless" (backing: []byte) -> Fixed_Byte_Buffer {
	s := transmute(Raw_Slice)backing
	d: Raw_Dynamic_Array
	d.data = s.data
	d.len = 0
	d.cap = s.len
	d.allocator = Allocator{
		procedure = nil_allocator_proc,
		data = nil,
	}
	return transmute(Fixed_Byte_Buffer)d
}



align_formula :: proc "contextless" (size, align: int) -> int {
	result := size + align-1
	return result - result%align
}

calc_padding_with_header :: proc "contextless" (ptr: uintptr, align: uintptr, header_size: int) -> int {
	p, a := ptr, align
	modulo := p & (a-1)

	padding := uintptr(0)
	if modulo != 0 {
		padding = a - modulo
	}

	needed_space := uintptr(header_size)
	if padding < needed_space {
		needed_space -= padding

		if needed_space & (a-1) > 0 {
			padding += align * (1+(needed_space/align))
		} else {
			padding += align * (needed_space/align)
		}
	}

	return int(padding)
}



clone_slice :: proc(slice: $T/[]$E, allocator := context.allocator, loc := #caller_location) -> (new_slice: T) {
	new_slice, _ = make(T, len(slice), allocator, loc)
	runtime.copy(new_slice, slice)
	return new_slice
}
