package runtime

import "base:intrinsics"
_ :: intrinsics

/*

	SOA types are implemented with this sort of layout:

	SOA Fixed Array
	struct {
		f0: [N]T0,
		f1: [N]T1,
		f2: [N]T2,
	}

	SOA Slice
	struct {
		f0: ^T0,
		f1: ^T1,
		f2: ^T2,

		len: int,
	}

	SOA Dynamic Array
	struct {
		f0: ^T0,
		f1: ^T1,
		f2: ^T2,

		len: int,
		cap: int,
		allocator: Allocator,
	}

	A footer is used rather than a header purely to simplify access to the fields internally
	i.e. field index of the AOS == SOA

*/


Raw_SOA_Footer_Slice :: struct {
	len: int,
}

Raw_SOA_Footer_Dynamic_Array :: struct {
	len: int,
	cap: int,
	allocator: Allocator,
}

// Note: When casting array to access footer/fields
// uintptr(array) lowers to LLVM ptrtoint and captures pointer provenance,
// whcih defeats #no_alias on the array in any code following (including in callers).
// Multipointer indexing lowers to GEP and doesn't capture, so prefer that throughout.

@(builtin, require_results)
raw_soa_footer_slice :: proc "contextless" (array: ^$T/#soa[]$E) -> (footer: ^Raw_SOA_Footer_Slice) {
	if array == nil {
		return nil
	}
	field_count := len(E) when intrinsics.type_is_array(E) else intrinsics.type_struct_field_count(E)
	offset := (field_count*size_of(rawptr) + align_of(Raw_SOA_Footer_Slice) - 1) &~ (align_of(Raw_SOA_Footer_Slice) - 1)
	footer = (^Raw_SOA_Footer_Slice)(&([^]byte)(array)[offset])
	return
}
@(builtin, require_results)
raw_soa_footer_dynamic_array :: proc "contextless" (array: ^$T/#soa[dynamic]$E) -> (footer: ^Raw_SOA_Footer_Dynamic_Array) {
	if array == nil {
		return nil
	}
	field_count := len(E) when intrinsics.type_is_array(E) else intrinsics.type_struct_field_count(E)
	offset := (field_count*size_of(rawptr) + align_of(Raw_SOA_Footer_Dynamic_Array) - 1) &~ (align_of(Raw_SOA_Footer_Dynamic_Array) - 1)
	footer = (^Raw_SOA_Footer_Dynamic_Array)(&([^]byte)(array)[offset])
	return
}
raw_soa_footer :: proc{
	raw_soa_footer_slice,
	raw_soa_footer_dynamic_array,
}



@(builtin, require_results)
make_soa_aligned :: proc($T: typeid/#soa[]$E, #any_int length, alignment: int, allocator := context.allocator, loc := #caller_location) -> (array: T, err: Allocator_Error) #optional_allocator_error {
	if length <= 0 {
		return
	}

	footer := raw_soa_footer(&array)
	if size_of(E) == 0 {
		footer.len = length
		return
	}

	max_align := max(alignment, align_of(E))

	FIELD_COUNT :: len(E) when intrinsics.type_is_array(E) else intrinsics.type_struct_field_count(E)

	offsets: [FIELD_COUNT]int
	total_size := _soa_layout(intrinsics.type_soa_field_sizes(T)[:], length, max_align, offsets[:]) or_return

	allocator := allocator
	if allocator.procedure == nil {
		allocator = context.allocator
		assert(allocator.procedure != nil)
	}

	new_bytes: []byte
	new_bytes, err = allocator.procedure(
		allocator.data, .Alloc, total_size, max_align,
		nil, 0, loc,
	)
	if new_bytes == nil || err != nil {
		return
	}
	new_data := raw_data(new_bytes)

	for offset, i in offsets {
		([^]rawptr)(&array)[i] = &new_data[offset]
	}
	footer.len = length

	return
}

@(builtin, require_results)
make_soa_slice :: proc($T: typeid/#soa[]$E, #any_int length: int, allocator := context.allocator, loc := #caller_location) -> (array: T, err: Allocator_Error) #optional_allocator_error {
	return make_soa_aligned(T, length, align_of(E), allocator, loc)
}

@(builtin, require_results)
make_soa_dynamic_array :: proc($T: typeid/#soa[dynamic]$E, allocator := context.allocator, loc := #caller_location) -> (array: T, err: Allocator_Error) #optional_allocator_error {
	context.allocator = allocator
	array.allocator = allocator
	reserve_soa(&array, 0, loc) or_return
	return array, nil
}

@(builtin, require_results)
make_soa_dynamic_array_len :: proc($T: typeid/#soa[dynamic]$E, #any_int length: int, allocator := context.allocator, loc := #caller_location) -> (array: T, err: Allocator_Error) #optional_allocator_error {
	context.allocator = allocator
	array.allocator = allocator
	resize_soa(&array, length, loc) or_return
	return array, nil
}

@(builtin, require_results)
make_soa_dynamic_array_len_cap :: proc($T: typeid/#soa[dynamic]$E, #any_int length, capacity: int, allocator := context.allocator, loc := #caller_location) -> (array: T, err: Allocator_Error) #optional_allocator_error {
	context.allocator = allocator
	array.allocator = allocator
	reserve_soa(&array, capacity, loc) or_return
	if err = resize_soa(&array, length, loc); err != nil {
		delete_soa(array, loc)
		return {}, err
	}
	return array, nil
}


@builtin
make_soa :: proc{
	make_soa_slice,
	make_soa_dynamic_array,
	make_soa_dynamic_array_len,
	make_soa_dynamic_array_len_cap,
}


@builtin
resize_soa :: proc(#no_alias array: ^$T/#soa[dynamic]$E, #any_int length: int, loc := #caller_location) -> Allocator_Error {
	if array == nil {
		return nil
	}

	footer := raw_soa_footer(array)
	old_len := footer.len
	old_cap := footer.cap

	if length > old_cap {
		reserve_soa(array, length, loc) or_return
	}

	// reserve_soa has zeroed any newly allocated [old_cap, length)
	// reused [old_len, min(old_cap, length)) still needs zeroing
	to_zero_end := min(old_cap, length)
	if size_of(E) > 0 && to_zero_end > old_len {
		_soa_zero(array[:], old_len, to_zero_end - old_len)
	}

	footer.len = max(length, 0)
	return nil
}

@builtin
non_zero_resize_soa :: proc(#no_alias array: ^$T/#soa[dynamic]$E, #any_int length: int, loc := #caller_location) -> Allocator_Error {
	if array == nil {
		return nil
	}
	non_zero_reserve_soa(array, length, loc) or_return
	footer := raw_soa_footer(array)
	footer.len = max(length, 0)
	return nil
}

// `reserve_soa` will try to reserve memory of a passed SOA dynamic array to the requested element count (setting the `cap`).
@builtin
reserve_soa :: proc(array: ^$T/#soa[dynamic]$E, #any_int capacity: int, loc := #caller_location) -> Allocator_Error {
	return _reserve_soa(array, capacity, true, loc)
}

@builtin
non_zero_reserve_soa :: proc(array: ^$T/#soa[dynamic]$E, #any_int capacity: int, loc := #caller_location) -> Allocator_Error {
	return _reserve_soa(array, capacity, false, loc)
}

// Shrinks the capacity of an #soa dynamic array down to the current length, or the given capacity.
//
// If `new_cap` is negative, then `len(array)` is used.
//
// Returns false if `cap(array) < new_cap`, or the allocator report failure.
//
// If `len(array) < new_cap`, then `len(array)` will be left unchanged.
//
// Note: Prefer the procedure group `shrink`
@builtin
shrink_soa :: proc(#no_alias array: ^$T/#soa[dynamic]$E, #any_int new_cap := -1, loc := #caller_location) -> (did_shrink: bool, err: Allocator_Error) {
	if array == nil {
		return
	}

	footer  := raw_soa_footer(array)
	new_cap := new_cap if new_cap >= 0 else footer.len
	old_cap := footer.cap
	if new_cap > old_cap {
		return
	}
	keep := min(new_cap, footer.len)
	if new_cap == old_cap || size_of(E) == 0 {
		footer.len = keep
		footer.cap = new_cap
		return true, nil
	}

	FIELD_COUNT :: len(E) when intrinsics.type_is_array(E) else intrinsics.type_struct_field_count(E)
	max_align   :: align_of(E)

	// NOTE(bill): The layout of the columns depends on the capacity, so the elements are copied to new memory.
	sizes := intrinsics.type_soa_field_sizes(T)
	old_offsets, new_offsets: [FIELD_COUNT]int
	old_size := _soa_layout(sizes[:], old_cap, max_align, old_offsets[:]) or_return
	new_size := _soa_layout(sizes[:], new_cap, max_align, new_offsets[:]) or_return

	columns  := ([^]rawptr)(array)
	old_data := columns[0]
	new_data: [^]byte
	if new_cap > 0 {
		new_bytes := array.allocator.procedure(
			array.allocator.data, .Alloc_Non_Zeroed, new_size, max_align,
			nil, 0, loc,
		) or_return
		new_data = raw_data(new_bytes)
	}

	for size, i in sizes {
		column: rawptr
		if new_data != nil {
			column = &new_data[new_offsets[i]]
			mem_copy_non_overlapping(column, columns[i], size*keep)
		}
		columns[i] = column
	}
	footer.len = keep
	footer.cap = new_cap

	// NOTE(bill): An allocator that cannot free, such as an arena, keeps the old memory, as it would after a resize.
	did_shrink = true
	_, free_err := array.allocator.procedure(
		array.allocator.data, .Free, 0, max_align,
		old_data, old_size, loc,
	)
	if free_err != .Mode_Not_Implemented {
		err = free_err
	}
	return
}

// Moves `count` elements of `s` from index `from` to index `to`, field by field
@(private)
_soa_move :: proc "contextless" (s: $S/#soa[]$E, to, from, count: int) {
	s := s
	columns := ([^][^]byte)(&s)
	for size, i in intrinsics.type_soa_field_sizes(S) {
		mem_copy(&columns[i][to*size], &columns[i][from*size], count*size)
	}
}

// Zeroes `count` elements of `s` from index `from`, field by field
@(private)
_soa_zero :: proc "contextless" (s: $S/#soa[]$E, from, count: int) {
	s := s
	columns := ([^][^]byte)(&s)
	for size, i in intrinsics.type_soa_field_sizes(S) {
		mem_zero(&columns[i][from*size], count*size)
	}
}

// `copy_soa` is a built-in procedure that copies elements from a source #soa slice `src` to a destination #soa slice `dst`.
// The source and destination may overlap. Copy returns the number of elements copied, which will be the minimum
// of len(src) and len(dst).
//
// Prefer the procedure group `copy`.
@builtin
copy_soa :: proc "contextless" (dst, src: $S/#soa[]$E) -> int {
	n := min(len(dst), len(src))
	if n <= 0 {
		return 0
	}
	dst, src := dst, src
	dst_columns := ([^][^]byte)(&dst)
	src_columns := ([^][^]byte)(&src)
	for size, i in intrinsics.type_soa_field_sizes(S) {
		mem_copy(dst_columns[i], src_columns[i], n*size)
	}
	return n
}

// `copy_soa_from_slice` is a built-in procedure that copies elements from a source slice `src` to a destination #soa slice `dst`.
// The source and destination must not overlap. Copy returns the number of elements copied, which will be the minimum
// of len(src) and len(dst).
//
// Prefer the procedure group `copy`.
@builtin
copy_soa_from_slice :: proc "contextless" (dst: $S/#soa[]$E, src: []E) -> int #no_bounds_check {
	n := min(len(dst), len(src))
	i := 0
	when size_of(E) >= 8 && size_of(E)%4 == 0 {
		sizes := intrinsics.type_soa_field_sizes(S)
		k     := len(sizes)
		soa   := dst
		switch _soa_uniform_field_size(sizes[:], size_of(E)) {
		case 4:
			V :: #simd[4]u32
			columns := ([^][^]u32)(&soa)
			rows    := ([^]u32)(raw_data(src))
			switch k {
			case 2:
				for /**/; i+4 <= n; i += 4 {
					r0 := intrinsics.unaligned_load((^V)(&rows[i*2]))
					r1 := intrinsics.unaligned_load((^V)(&rows[i*2+4]))
					intrinsics.unaligned_store((^V)(&columns[0][i]), intrinsics.simd_shuffle(r0, r1, 0, 2, 4, 6))
					intrinsics.unaligned_store((^V)(&columns[1][i]), intrinsics.simd_shuffle(r0, r1, 1, 3, 5, 7))
				}
			case 3:
				for /**/; i+4 <= n; i += 4 {
					r0 := intrinsics.unaligned_load((^V)(&rows[i*3]))
					r1 := intrinsics.unaligned_load((^V)(&rows[i*3+4]))
					r2 := intrinsics.unaligned_load((^V)(&rows[i*3+8]))

					t0 := intrinsics.simd_shuffle(r0, r1, 0, 3, 6, 0)
					t1 := intrinsics.simd_shuffle(r0, r1, 1, 4, 7, 0)
					t2 := intrinsics.simd_shuffle(r0, r1, 2, 5, 0, 0)

					intrinsics.unaligned_store((^V)(&columns[0][i]), intrinsics.simd_shuffle(t0, r2, 0, 1, 2, 5))
					intrinsics.unaligned_store((^V)(&columns[1][i]), intrinsics.simd_shuffle(t1, r2, 0, 1, 2, 6))
					intrinsics.unaligned_store((^V)(&columns[2][i]), intrinsics.simd_shuffle(t2, r2, 0, 1, 4, 7))
				}
			case:
				for /**/; i+4 <= n; i += 4 {
					block := rows[i*k:]
					for w := 0; w < k; w += 4 {
						f := min(w, k-4)

						r0 := intrinsics.unaligned_load((^V)(&block[f]))
						r1 := intrinsics.unaligned_load((^V)(&block[k+f]))
						r2 := intrinsics.unaligned_load((^V)(&block[2*k+f]))
						r3 := intrinsics.unaligned_load((^V)(&block[3*k+f]))

						t0 := intrinsics.simd_shuffle(r0, r1, 0, 4, 1, 5)
						t1 := intrinsics.simd_shuffle(r0, r1, 2, 6, 3, 7)
						t2 := intrinsics.simd_shuffle(r2, r3, 0, 4, 1, 5)
						t3 := intrinsics.simd_shuffle(r2, r3, 2, 6, 3, 7)

						intrinsics.unaligned_store((^V)(&columns[f+0][i]), intrinsics.simd_shuffle(t0, t2, 0, 1, 4, 5))
						intrinsics.unaligned_store((^V)(&columns[f+1][i]), intrinsics.simd_shuffle(t0, t2, 2, 3, 6, 7))
						intrinsics.unaligned_store((^V)(&columns[f+2][i]), intrinsics.simd_shuffle(t1, t3, 0, 1, 4, 5))
						intrinsics.unaligned_store((^V)(&columns[f+3][i]), intrinsics.simd_shuffle(t1, t3, 2, 3, 6, 7))
					}
				}
			}
		case 8:
			V :: #simd[2]u64
			columns := ([^][^]u64)(&soa)
			rows    := ([^]u64)(raw_data(src))
			if k >= 2 {
				for /**/; i+2 <= n; i += 2 {
					block := rows[i*k:]
					for w := 0; w < k; w += 2 {
						f := min(w, k-2)

						r0 := intrinsics.unaligned_load((^V)(&block[f]))
						r1 := intrinsics.unaligned_load((^V)(&block[k+f]))

						intrinsics.unaligned_store((^V)(&columns[f+0][i]), intrinsics.simd_shuffle(r0, r1, 0, 2))
						intrinsics.unaligned_store((^V)(&columns[f+1][i]), intrinsics.simd_shuffle(r0, r1, 1, 3))
					}
				}
			}
		}
	}
	for /**/; i < n; i += 1 {
		dst[i] = src[i]
	}
	return n
}

// `copy_slice_from_soa` is a built-in procedure that copies elements from a source #soa slice `src` to a destination slice `dst`.
// The source and destination must not overlap. Copy returns the number of elements copied, which will be the minimum
// of len(src) and len(dst).
//
// Prefer the procedure group `copy`.
@builtin
copy_slice_from_soa :: proc "contextless" (dst: []$E, src: $S/#soa[]E) -> int #no_bounds_check {
	n := min(len(dst), len(src))
	i := 0
	when size_of(E) >= 8 && size_of(E)%4 == 0 {
		sizes := intrinsics.type_soa_field_sizes(S)
		k     := len(sizes)
		soa   := src
		switch _soa_uniform_field_size(sizes[:], size_of(E)) {
		case 4:
			V :: #simd[4]u32
			columns := ([^][^]u32)(&soa)
			rows    := ([^]u32)(raw_data(dst))
			switch k {
			case 2:
				for /**/; i+4 <= n; i += 4 {
					c0 := intrinsics.unaligned_load((^V)(&columns[0][i]))
					c1 := intrinsics.unaligned_load((^V)(&columns[1][i]))
					intrinsics.unaligned_store((^V)(&rows[i*2]),   intrinsics.simd_shuffle(c0, c1, 0, 4, 1, 5))
					intrinsics.unaligned_store((^V)(&rows[i*2+4]), intrinsics.simd_shuffle(c0, c1, 2, 6, 3, 7))
				}
			case 3:
				for /**/; i+4 <= n; i += 4 {
					c0 := intrinsics.unaligned_load((^V)(&columns[0][i]))
					c1 := intrinsics.unaligned_load((^V)(&columns[1][i]))
					c2 := intrinsics.unaligned_load((^V)(&columns[2][i]))

					t0 := intrinsics.simd_shuffle(c0, c1, 0, 4, 1, 0)
					t1 := intrinsics.simd_shuffle(c1, c2, 1, 5, 2, 0)
					t2 := intrinsics.simd_shuffle(c2, c0, 2, 7, 3, 0)

					intrinsics.unaligned_store((^V)(&rows[i*3]),   intrinsics.simd_shuffle(t0, c2, 0, 1, 4, 2))
					intrinsics.unaligned_store((^V)(&rows[i*3+4]), intrinsics.simd_shuffle(t1, c0, 0, 1, 6, 2))
					intrinsics.unaligned_store((^V)(&rows[i*3+8]), intrinsics.simd_shuffle(t2, c1, 0, 1, 7, 2))
				}
			case:
				for /**/; i+4 <= n; i += 4 {
					block := rows[i*k:]
					for w := 0; w < k; w += 4 {
						f := min(w, k-4)

						c0 := intrinsics.unaligned_load((^V)(&columns[f+0][i]))
						c1 := intrinsics.unaligned_load((^V)(&columns[f+1][i]))
						c2 := intrinsics.unaligned_load((^V)(&columns[f+2][i]))
						c3 := intrinsics.unaligned_load((^V)(&columns[f+3][i]))

						t0 := intrinsics.simd_shuffle(c0, c1, 0, 4, 1, 5)
						t1 := intrinsics.simd_shuffle(c0, c1, 2, 6, 3, 7)
						t2 := intrinsics.simd_shuffle(c2, c3, 0, 4, 1, 5)
						t3 := intrinsics.simd_shuffle(c2, c3, 2, 6, 3, 7)

						intrinsics.unaligned_store((^V)(&block[f]),     intrinsics.simd_shuffle(t0, t2, 0, 1, 4, 5))
						intrinsics.unaligned_store((^V)(&block[k+f]),   intrinsics.simd_shuffle(t0, t2, 2, 3, 6, 7))
						intrinsics.unaligned_store((^V)(&block[2*k+f]), intrinsics.simd_shuffle(t1, t3, 0, 1, 4, 5))
						intrinsics.unaligned_store((^V)(&block[3*k+f]), intrinsics.simd_shuffle(t1, t3, 2, 3, 6, 7))
					}
				}
			}
		case 8:
			V :: #simd[2]u64
			columns := ([^][^]u64)(&soa)
			rows    := ([^]u64)(raw_data(dst))
			if k >= 2 {
				for /**/; i+2 <= n; i += 2 {
					block := rows[i*k:]
					for w := 0; w < k; w += 2 {
						f := min(w, k-2)

						c0 := intrinsics.unaligned_load((^V)(&columns[f+0][i]))
						c1 := intrinsics.unaligned_load((^V)(&columns[f+1][i]))

						intrinsics.unaligned_store((^V)(&block[f]),   intrinsics.simd_shuffle(c0, c1, 0, 2))
						intrinsics.unaligned_store((^V)(&block[k+f]), intrinsics.simd_shuffle(c0, c1, 1, 3))
					}
				}
			}
		}
	}
	for /**/; i < n; i += 1 {
		dst[i] = src[i]
	}
	return n
}

// The size of each field of an #soa element when they are all the same, with no padding between them, otherwise 0.
// Blocks of such elements are copied as small matrices, transposed with shuffles.
@(private, require_results)
_soa_uniform_field_size :: proc "contextless" (sizes: []int, elem_size: int) -> int {
	size := sizes[0]
	for s in sizes {
		if s != size {
			return 0
		}
	}
	if size*len(sizes) != elem_size {
		return 0
	}
	return size
}

// NOTE(bill): Columns starting a multiple of 4 KiB apart, as power-of-two capacities make them, evict each other from the L1 cache.
// A column starting within 128 bytes of an earlier one, modulo 4 KiB, moves forward to a 128-byte boundary that does not.
// 128 bytes also covers the cache lines of Apple Silicon.
// A column moves at most its own size, and only the first 32 move, to keep the padding small.
@(private, require_results)
_soa_layout :: proc(sizes: []int, count, max_align: int, offsets: []int) -> (total: int, err: Allocator_Error) {
	PERIOD :: 4096
	SLOT   :: 128

	step := max(max_align, SLOT)
	for &offset, i in offsets {
		size  := _checked_size_mul(sizes[i],  count) or_return
		_      = _checked_size_add(total,    2*step) or_return
		offset = align_forward_int(total, max_align)

		start := offset
		for j := 0; i < PERIOD/SLOT && j < i; j += 1 {
			apart   := offset - offsets[j]
			residue := apart % PERIOD
			// Columns less than 4 KiB apart share cache lines, not sets
			if apart >= PERIOD - SLOT && (residue < SLOT || residue > PERIOD - SLOT) {
				offset = align_forward_int(offset + 1, step)
				if offset - start > min(size, PERIOD) {
					offset = start
					break
				}
				j = -1 // the moved column could now collide with an earlier one
			}
		}
		total = _checked_size_add(offset, size) or_return
	}
	total = align_forward_int(total, max_align)
	return
}

_reserve_soa :: #force_no_inline proc(array: ^$T/#soa[dynamic]$E, capacity: int, zero_memory: bool, loc := #caller_location) -> Allocator_Error {
	if array == nil {
		return nil
	}

	old_cap := cap(array)
	if capacity <= old_cap {
		if capacity < 0 {
			return .Invalid_Argument
		}
		return nil
	}

	if array.allocator.procedure == nil {
		array.allocator = context.allocator
		assert(array.allocator.procedure != nil)
	}

	footer := raw_soa_footer(array)
	if size_of(E) == 0 {
		footer.cap = capacity
		return nil
	}

	FIELD_COUNT :: len(E) when intrinsics.type_is_array(E) else intrinsics.type_struct_field_count(E)
	assert(footer.cap == old_cap)

	max_align :: align_of(E)
	sizes := intrinsics.type_soa_field_sizes(T)
	old_offsets, new_offsets: [FIELD_COUNT]int
	old_size := _soa_layout(sizes[:], old_cap,  max_align, old_offsets[:]) or_return
	new_size := _soa_layout(sizes[:], capacity, max_align, new_offsets[:]) or_return

	columns  := ([^]rawptr)(array)
	old_data := ([^]byte)(columns[0])
	new_data: [^]byte

	// NOTE(bill): Less padding can make a larger capacity smaller, and then it cannot be resized in place.
	if old_data != nil && new_size >= old_size {
		new_bytes, resize_err := array.allocator.procedure(
			array.allocator.data, .Resize_Non_Zeroed, new_size, max_align,
			old_data, old_size, loc,
		)
		#partial switch resize_err {
		case .None:                 new_data = raw_data(new_bytes)
		case .Mode_Not_Implemented: // allocate instead
		case:                       return resize_err
		}
	}

	in_place := new_data != nil
	if !in_place {
		new_bytes := array.allocator.procedure(
			array.allocator.data, .Alloc if zero_memory else .Alloc_Non_Zeroed, new_size, max_align,
			nil, old_size, loc,
		) or_return
		new_data = raw_data(new_bytes)
	}
	old_columns := new_data if in_place else old_data
	footer.cap = capacity

	// NOTE(bill): In place, columns moving up are moved from the last one, then columns moving down from the first one.
	// No column is then overwritten before it moves.
	for k in 0..<2*FIELD_COUNT {
		up := k < FIELD_COUNT
		i  := FIELD_COUNT-1-k if up else k-FIELD_COUNT
		if (new_offsets[i] >= old_offsets[i]) != up {
			continue
		}
		size   := sizes[i]
		column := &new_data[new_offsets[i]]
		mem_copy(column, &old_columns[old_offsets[i]], size*old_cap)
		if zero_memory && in_place {
			mem_zero(&new_data[new_offsets[i] + size*old_cap], size*(capacity - old_cap))
		}
		columns[i] = column
	}

	if old_data != nil && !in_place {
		array.allocator.procedure(
			array.allocator.data, .Free, 0, max_align,
			old_data, old_size, loc,
		) or_return
	}
	return nil
}


@builtin
append_soa_elem :: proc(array: ^$T/#soa[dynamic]$E, #no_broadcast arg: E, loc := #caller_location) -> (n: int, err: Allocator_Error) #optional_allocator_error {
	return _append_soa_elem(array, true, arg, loc)
}

@builtin
non_zero_append_soa_elem :: proc(array: ^$T/#soa[dynamic]$E, #no_broadcast arg: E, loc := #caller_location) -> (n: int, err: Allocator_Error) #optional_allocator_error {
	return _append_soa_elem(array, false, arg, loc)
}

_append_soa_elem :: proc(#no_alias array: ^$T/#soa[dynamic]$E, zero_memory: bool, #no_broadcast arg: E, loc := #caller_location) -> (n: int, err: Allocator_Error) #optional_allocator_error {
	if array == nil {
		return 0, nil
	}

	if cap(array) < len(array) + 1 {
		// Same behavior as append_soa_elems but there's only one arg, so we always just add DEFAULT_DYNAMIC_ARRAY_CAPACITY.
		cap := 2 * cap(array) + DEFAULT_DYNAMIC_ARRAY_CAPACITY
		err = _reserve_soa(array, cap, zero_memory, loc) // do not 'or_return' here as it could be a partial success
	}

	if size_of(E) == 0 {
		footer := raw_soa_footer(array)
		footer.len += 1
		return 1, nil
	}

	if size_of(E) > 0 && cap(array)-len(array) > 0 {
		footer := raw_soa_footer(array)
		// Field stores are generated by the compiler's #soa
		// element store lowering, specialized for E.
		// Note that #no_bounds_check is not optional, we write at index == len.
		#no_bounds_check {
			array[footer.len] = arg
		}
		footer.len += 1
		return 1, err
	}
	return 0, err
}

@builtin
append_soa_elems :: proc(array: ^$T/#soa[dynamic]$E, #no_broadcast args: ..E, loc := #caller_location) -> (n: int, err: Allocator_Error) #optional_allocator_error {
	return _append_soa_elems(array, true, args=args, loc=loc)
}

@builtin
non_zero_append_soa_elems :: proc(array: ^$T/#soa[dynamic]$E, #no_broadcast args: ..E, loc := #caller_location) -> (n: int, err: Allocator_Error) #optional_allocator_error {
	return _append_soa_elems(array, false, args=args, loc=loc)
}


_append_soa_elems :: proc(#no_alias array: ^$T/#soa[dynamic]$E, zero_memory: bool, #no_broadcast args: []E, loc := #caller_location) -> (n: int, err: Allocator_Error) #optional_allocator_error {
	if array == nil {
		return
	}

	arg_len := len(args)
	if arg_len == 0 {
		return
	}

	if cap(array) < len(array)+arg_len {
		cap := 2 * cap(array) + max(DEFAULT_DYNAMIC_ARRAY_CAPACITY, arg_len)
		err = _reserve_soa(array, cap, zero_memory, loc) // do not 'or_return' here as it could be a partial success
	}
	arg_len = min(cap(array)-len(array), arg_len)

	footer := raw_soa_footer(array)
	if size_of(E) > 0 && arg_len > 0 {
		FIELD_COUNT :: len(E) when intrinsics.type_is_array(E) else intrinsics.type_struct_field_count(E)
		// Advance len before the copy, soa_copy_from_slice needs the final len to be set
		when FIELD_COUNT != 0 {
			offset := footer.len
		}

		footer.len += arg_len

		when FIELD_COUNT == 0 {
			// do nothing
		} else when FIELD_COUNT <= 16 && ODIN_OPTIMIZATION_MODE <= .Size {
			// Use the compiler's #soa element store lowering, more compact at these field counts.
			#no_bounds_check for j in 0..<arg_len {
				array[offset + j] = args[j]
			}
		} else {
			intrinsics.soa_copy_from_slice(array, offset, args[:arg_len])
		}
	} else {
		footer.len += arg_len
	}
	return arg_len, err
}

// `append_soa_slice` appends the elements of the #soa slice `elems` to the end of an #soa dynamic array.
// `elems` may be a part of the array itself.
@builtin
append_soa_slice :: proc(#no_alias array: ^$T/#soa[dynamic]$E, elems: $S/#soa[]E, loc := #caller_location) -> (n: int, err: Allocator_Error) #optional_allocator_error {
	if array == nil {
		return
	}
	old_len := len(array)
	from    := _soa_index_in(array[:], elems)

	err = _grow_soa(array, old_len+len(elems), false, loc) // do not 'or_return' here as it could be a partial success
	n = min(cap(array)-old_len, len(elems))
	if n <= 0 {
		return
	}
	raw_soa_footer(array).len = old_len + n

	src := elems
	if from >= 0 {
		src = array[from:]
	}
	copy_soa(array[old_len:], src[:n])
	return
}

// The append_soa built-in procedure appends elements to the end of an #soa dynamic array
@builtin
append_soa :: proc{
	append_soa_elem,
	append_soa_elems,
	append_soa_slice,
	append_soa_fixed_capacity_elem,
	append_soa_fixed_capacity_elems,
	append_soa_fixed_capacity_slice,
}

// The index in `s` of the first element of `part` when `part` is a part of `s`, otherwise -1
@(private, require_results)
_soa_index_in :: proc "contextless" (s, part: $S/#soa[]$E) -> int {
	s, part := s, part
	columns := ([^]uintptr)(&s)
	parts   := ([^]uintptr)(&part)
	for size, i in intrinsics.type_soa_field_sizes(S) {
		if size == 0 {
			continue
		}
		if !(columns[i] <= parts[i] && parts[i] < columns[i] + uintptr(len(s)*size)) {
			return -1
		}
		return int(parts[i] - columns[i]) / size
	}
	return -1
}

// Copies `elems` into `s` at `index`, once the elements from `index` have moved along by `len(elems)`.
// `from` is where `elems` was in `s` before that move, or -1 when it is not a part of `s`.
@(private)
_soa_copy_injected :: proc "contextless" (s, elems: $S/#soa[]$E, index, from: int) {
	m := len(elems)
	switch {
	case from < 0:
		copy_soa(s[index:], elems)
	case from+m <= index:
		copy_soa(s[index:], s[from:][:m])
	case from >= index:
		copy_soa(s[index:], s[from+m:][:m])
	case:
		// `elems` straddles `index`, so only its end moved
		k := index - from
		copy_soa(s[index:],   s[from:][:k])
		copy_soa(s[index+k:], s[index+m:][:m-k])
	}
}


// Reserves room for `length` elements, growing the capacity as `append_soa` does, so growing a few elements at a time stays cheap
@(private)
_grow_soa :: proc(array: ^$T/#soa[dynamic]$E, length: int, zero_memory: bool, loc := #caller_location) -> Allocator_Error {
	if length <= cap(array) {
		return nil
	}
	return _reserve_soa(array, max(length, 2*cap(array) + DEFAULT_DYNAMIC_ARRAY_CAPACITY), zero_memory, loc)
}

// `append_nothing_soa` appends an empty value to a dynamic SOA array. It returns `1, nil` if successful, and `0, err` when it was not possible,
// whatever `err` happens to be.
@builtin
append_nothing_soa :: proc(array: ^$T/#soa[dynamic]$E, loc := #caller_location) -> (n: int, err: Allocator_Error) #optional_allocator_error {
	if array == nil {
		return 0, nil
	}
	prev_len := len(array)
	_grow_soa(array, len(array)+1, true, loc) or_return
	resize_soa(array, len(array)+1, loc) or_return
	return len(array)-prev_len, nil
}


// `inject_at_elem_soa` injects an element in a dynamic SOA array at a specified index and moves the previous elements after that index "across"
@builtin
inject_at_elem_soa :: proc(#no_alias array: ^$T/#soa[dynamic]$E, #any_int index: int, #no_broadcast arg: E, loc := #caller_location) -> (ok: bool, err: Allocator_Error) #optional_allocator_error {
	return inject_at_elems_soa(array, index, arg, loc=loc)
}

// `inject_at_elems_soa` injects multiple elements in a dynamic SOA array at a specified index and moves the previous elements after that index "across"
@builtin
inject_at_elems_soa :: proc(#no_alias array: ^$T/#soa[dynamic]$E, #any_int index: int, #no_broadcast args: ..E, loc := #caller_location) -> (ok: bool, err: Allocator_Error) #no_bounds_check #optional_allocator_error {
	when !ODIN_NO_BOUNDS_CHECK {
		ensure(index >= 0, "Index must be positive.", loc)
	}
	if array == nil {
		return
	}
	if len(args) == 0 {
		ok = true
		return
	}

	old_len := len(array)
	n := max(old_len, index)
	m := len(args)
	new_len := n + m

	// The tail shift and the stored elements cover every new slot,
	// except a gap of [old_len, index) when injecting past the end, which is zeroed below.
	_grow_soa(array, new_len, false, loc) or_return
	non_zero_resize_soa(array, new_len, loc) or_return

	when size_of(E) != 0 {
		if index > old_len {
			_soa_zero(array[:], old_len, index - old_len)
		}
		_soa_move(array[:], index + m, index, n - index)
		intrinsics.soa_copy_from_slice(array, index, args)
	}

	ok = true
	return
}

// `inject_at_slice_soa` injects the elements of the #soa slice `elems` in a dynamic SOA array at a specified index and moves the previous elements after that index "across".
// `elems` may be a part of the array itself.
@builtin
inject_at_slice_soa :: proc(#no_alias array: ^$T/#soa[dynamic]$E, #any_int index: int, elems: $S/#soa[]E, loc := #caller_location) -> (ok: bool, err: Allocator_Error) #no_bounds_check #optional_allocator_error {
	when !ODIN_NO_BOUNDS_CHECK {
		ensure(index >= 0, "Index must be positive.", loc)
	}
	if array == nil {
		return
	}
	m := len(elems)
	if m == 0 {
		ok = true
		return
	}

	old_len := len(array)
	n       := max(old_len, index)
	from    := _soa_index_in(array[:], elems)

	_grow_soa(array, n + m, false, loc) or_return
	non_zero_resize_soa(array, n + m, loc) or_return

	if index > old_len {
		_soa_zero(array[:], old_len, index - old_len)
	}
	_soa_move(array[:], index + m, index, n - index)
	_soa_copy_injected(array[:], elems, index, from)

	ok = true
	return
}

// `inject_at_soa` injects something into a dynamic SOA array at a specified index and moves the previous elements after that index "across"
@builtin
inject_at_soa :: proc{
	inject_at_elem_soa,
	inject_at_elems_soa,
	inject_at_slice_soa,
	inject_at_elem_soa_fixed_capacity,
	inject_at_elems_soa_fixed_capacity,
	inject_at_slice_soa_fixed_capacity,
}

@builtin
delete_soa_slice :: proc(array: $T/#soa[]$E, allocator := context.allocator, loc := #caller_location) -> Allocator_Error {
	field_count :: len(E) when intrinsics.type_is_array(E) else intrinsics.type_struct_field_count(E)
	when field_count != 0 {
		array := array
		ptr := (^rawptr)(&array)^
		free(ptr, allocator, loc) or_return
	}
	return nil
}

@builtin
delete_soa_dynamic_array :: proc(array: $T/#soa[dynamic]$E, loc := #caller_location) -> Allocator_Error {
	field_count :: len(E) when intrinsics.type_is_array(E) else intrinsics.type_struct_field_count(E)
	when field_count != 0 {
		array := array
		ptr := (^rawptr)(&array)^
		footer := raw_soa_footer(&array)
		free(ptr, footer.allocator, loc) or_return
	}
	return nil
}


@builtin
delete_soa :: proc{
	delete_soa_slice,
	delete_soa_dynamic_array,
}

@builtin
clear_soa_dynamic_array :: proc(array: ^$T/#soa[dynamic]$E) {
	field_count :: len(E) when intrinsics.type_is_array(E) else intrinsics.type_struct_field_count(E)
	when field_count != 0 {
		footer := raw_soa_footer(array)
		footer.len = 0
	}
}

@builtin
clear_soa :: proc{
	clear_soa_dynamic_array,
	clear_soa_fixed_capacity,
}

// Converts soa slice into a soa dynamic array without cloning or allocating memory
@(require_results)
into_dynamic_soa :: proc(array: $T/#soa[]$E) -> #soa[dynamic]E {
	d: #soa[dynamic]E
	footer := raw_soa_footer_dynamic_array(&d)
	footer^ = {
		cap = len(array),
		len = 0,
		allocator = nil_allocator(),
	}

	field_count := uintptr(len(E) when intrinsics.type_is_array(E) else intrinsics.type_struct_field_count(E))

	array := array
	dynamic_data := ([^]rawptr)(&d)[:field_count]
	slice_data   := ([^]rawptr)(&array)[:field_count]
	copy(dynamic_data, slice_data)

	return d
}

// `pop_soa` will remove and return the end value of the #soa dynamic array `array` and reduces the length of `array` by 1.
//
// Note: If the #soa dynamic array has no elements (`len(array) == 0`), this procedure will panic.
@builtin
pop_soa :: proc(#no_alias array: ^$T/#soa[dynamic]$E, loc := #caller_location) -> (res: E) #no_bounds_check {
	assert(len(array) > 0, loc=loc)
	res = array[len(array)-1]
	raw_soa_footer_dynamic_array(array).len -= 1
	return
}

// `pop_safe_soa` trys to remove and return the end value of the #soa dynamic array `array` and reduces the length of `array` by 1.
// If the operation is not possible, it will return false.
@builtin
pop_safe_soa :: proc "contextless" (#no_alias array: ^$T/#soa[dynamic]$E) -> (res: E, ok: bool) #no_bounds_check {
	if len(array) == 0 {
		return
	}
	res, ok = array[len(array)-1], true
	raw_soa_footer_dynamic_array(array).len -= 1
	return
}

// `pop_front_soa` will remove and return the first value of the #soa dynamic array `array` and reduces the length of `array` by 1,
// whilst keeping the order of the other elements.
//
// Note: This is an O(N) operation.
// Note: If the #soa dynamic array has no elements (`len(array) == 0`), this procedure will panic.
@builtin
pop_front_soa :: proc(#no_alias array: ^$T/#soa[dynamic]$E, loc := #caller_location) -> (res: E) #no_bounds_check {
	assert(len(array) > 0, loc=loc)
	res = array[0]
	_ordered_remove_soa(array, 0)
	return
}

// `pop_front_safe_soa` trys to remove and return the first value of the #soa dynamic array `array` and reduces the
// length of `array` by 1, whilst keeping the order of the other elements.
// If the operation is not possible, it will return false.
//
// Note: This is an O(N) operation.
@builtin
pop_front_safe_soa :: proc "contextless" (#no_alias array: ^$T/#soa[dynamic]$E) -> (res: E, ok: bool) #no_bounds_check {
	if len(array) == 0 {
		return
	}

	res, ok = array[0], true
	_ordered_remove_soa(array, 0)
	return
}

// `unordered_remove_soa` removed the element at the specified `index`. It does so by replacing the current end value
// with the old value, and reducing the length of the dynamic array by 1.
//
// Note: This is an O(1) operation.
// Note: If you want the elements to remain in their order, use `ordered_remove_soa`.
// Note: If the index is out of bounds, this procedure will panic.
@builtin
unordered_remove_soa :: proc(#no_alias array: ^$T/#soa[dynamic]$E, #any_int index: int, loc := #caller_location) #no_bounds_check {
	bounds_check_error_loc(loc, index, len(array))
	if index+1 < len(array) {
		array[index] = array[len(array)-1]
	}
	raw_soa_footer_dynamic_array(array).len -= 1
}

// `ordered_remove_soa` removed the element at the specified `index` whilst keeping the order of the other elements.
//
// Note: This is an O(N) operation.
// Note: If the elements do not have to remain in their order, prefer `unordered_remove_soa`.
// Note: If the index is out of bounds, this procedure will panic.
@builtin
ordered_remove_soa :: proc(#no_alias array: ^$T/#soa[dynamic]$E, #any_int index: int, loc := #caller_location) #no_bounds_check {
	bounds_check_error_loc(loc, index, len(array))
	_ordered_remove_soa(array, index)
}

// the unchecked body of ordered_remove_soa, shared with the front pops.
// index must already be known to be in bounds.
_ordered_remove_soa :: proc "contextless" (#no_alias array: ^$T/#soa[dynamic]$E, index: int) #no_bounds_check {
	if index+1 < len(array) {
		_soa_move(array[:], index, index + 1, len(array) - 1 - index)
	}
	raw_soa_footer_dynamic_array(array).len -= 1
}

// `#soa[dynamic; N]T` holds its elements inline, as `#soa[N]T` does, and a length.
// Like `[dynamic; N]T` it never allocates: growing past `N` fails instead.

@(private, require_results)
_soa_fixed_capacity_len :: #force_inline proc "contextless" (array: ^$T/#soa[dynamic; $N]$E) -> ^int {
	return (^int)(&([^]byte)(array)[intrinsics.type_fixed_capacity_dynamic_array_len_offset(T)])
}

@builtin
clear_soa_fixed_capacity :: proc "contextless" (array: ^$T/#soa[dynamic; $N]$E) {
	if array != nil {
		_soa_fixed_capacity_len(array)^ = 0
	}
}

// `resize_soa_fixed_capacity` sets the length to `length`, at most `N`, and zeroes any new elements
@builtin
resize_soa_fixed_capacity :: proc "contextless" (array: ^$T/#soa[dynamic; $N]$E, #any_int length: int) -> bool {
	if array == nil {
		return false
	}
	old_len := len(array)
	new_len := clamp(length, 0, N)
	_soa_fixed_capacity_len(array)^ = new_len
	if new_len > old_len {
		_soa_zero(array[:], old_len, new_len - old_len)
	}
	return true
}

@builtin
non_zero_resize_soa_fixed_capacity :: proc "contextless" (array: ^$T/#soa[dynamic; $N]$E, #any_int length: int) -> bool {
	if array == nil {
		return false
	}
	_soa_fixed_capacity_len(array)^ = clamp(length, 0, N)
	return true
}

// `append_soa_fixed_capacity_elem` appends an element, and returns 0 when the array is full
@builtin
append_soa_fixed_capacity_elem :: proc "contextless" (array: ^$T/#soa[dynamic; $N]$E, #no_broadcast arg: E) -> (num_appended: int) {
	n := len(array)
	if n >= N {
		return 0
	}
	_soa_fixed_capacity_len(array)^ = n + 1
	#no_bounds_check array[n] = arg
	return 1
}

// `append_soa_fixed_capacity_elems` appends as many of `args` as fit, and returns how many
@builtin
append_soa_fixed_capacity_elems :: proc "contextless" (array: ^$T/#soa[dynamic; $N]$E, #no_broadcast args: ..E) -> (num_appended: int) {
	n := len(array)
	num_appended = min(N - n, len(args))
	_soa_fixed_capacity_len(array)^ = n + num_appended
	#no_bounds_check for j in 0..<num_appended {
		array[n + j] = args[j]
	}
	return
}

// `append_soa_fixed_capacity_slice` appends as many of the elements of the #soa slice `elems` as fit, and returns how many
@builtin
append_soa_fixed_capacity_slice :: proc "contextless" (array: ^$T/#soa[dynamic; $N]$E, elems: $S/#soa[]E) -> (num_appended: int) {
	n := len(array)
	num_appended = min(N - n, len(elems))
	_soa_fixed_capacity_len(array)^ = n + num_appended
	copy_soa(array[n:], elems[:num_appended])
	return
}

@builtin
append_nothing_soa_fixed_capacity :: proc "contextless" (array: ^$T/#soa[dynamic; $N]$E) -> (n: int, ok: bool) {
	if array == nil {
		return 0, true
	}
	prev_len := len(array)
	resize_soa_fixed_capacity(array, prev_len+1) or_return
	return len(array)-prev_len, true
}

// `inject_at_elem_soa_fixed_capacity` injects an element at `index`, and fails when it does not fit
@builtin
inject_at_elem_soa_fixed_capacity :: proc(array: ^$T/#soa[dynamic; $N]$E, #any_int index: int, #no_broadcast arg: E, loc := #caller_location) -> (ok: bool) {
	return inject_at_elems_soa_fixed_capacity(array, index, arg, loc=loc)
}

// `inject_at_elems_soa_fixed_capacity` injects elements at `index`, and fails when they do not all fit
@builtin
inject_at_elems_soa_fixed_capacity :: proc(array: ^$T/#soa[dynamic; $N]$E, #any_int index: int, #no_broadcast args: ..E, loc := #caller_location) -> (ok: bool) #no_bounds_check {
	when !ODIN_NO_BOUNDS_CHECK {
		ensure(index >= 0, "Index must be positive.", loc)
	}
	if array == nil {
		return false
	}
	if len(args) == 0 {
		return true
	}

	old_len := len(array)
	n := max(old_len, index)
	m := len(args)
	if n + m > N {
		return false
	}

	_soa_fixed_capacity_len(array)^ = n + m
	if index > old_len {
		_soa_zero(array[:], old_len, index - old_len)
	}
	_soa_move(array[:], index + m, index, n - index)
	for arg, j in args {
		array[index + j] = arg
	}
	return true
}

// `inject_at_slice_soa_fixed_capacity` injects the elements of the #soa slice `elems` at `index`, and fails when they do not all fit.
// `elems` may be a part of the array itself.
@builtin
inject_at_slice_soa_fixed_capacity :: proc(array: ^$T/#soa[dynamic; $N]$E, #any_int index: int, elems: $S/#soa[]E, loc := #caller_location) -> (ok: bool) #no_bounds_check {
	when !ODIN_NO_BOUNDS_CHECK {
		ensure(index >= 0, "Index must be positive.", loc)
	}
	if array == nil {
		return false
	}
	m := len(elems)
	if m == 0 {
		return true
	}

	old_len := len(array)
	n       := max(old_len, index)
	if n + m > N {
		return false
	}
	from := _soa_index_in(array[:], elems)

	_soa_fixed_capacity_len(array)^ = n + m
	if index > old_len {
		_soa_zero(array[:], old_len, index - old_len)
	}
	_soa_move(array[:], index + m, index, n - index)
	_soa_copy_injected(array[:], elems, index, from)
	return true
}

@builtin
pop_soa_fixed_capacity :: proc(array: ^$T/#soa[dynamic; $N]$E, loc := #caller_location) -> (res: E) #no_bounds_check {
	assert(len(array) > 0, loc=loc)
	res = array[len(array)-1]
	_soa_fixed_capacity_len(array)^ -= 1
	return
}

@builtin
pop_safe_soa_fixed_capacity :: proc "contextless" (array: ^$T/#soa[dynamic; $N]$E) -> (res: E, ok: bool) #no_bounds_check {
	if len(array) == 0 {
		return
	}
	res, ok = array[len(array)-1], true
	_soa_fixed_capacity_len(array)^ -= 1
	return
}

@builtin
pop_front_soa_fixed_capacity :: proc(array: ^$T/#soa[dynamic; $N]$E, loc := #caller_location) -> (res: E) #no_bounds_check {
	assert(len(array) > 0, loc=loc)
	res = array[0]
	_ordered_remove_soa_fixed_capacity(array, 0)
	return
}

@builtin
pop_front_safe_soa_fixed_capacity :: proc "contextless" (array: ^$T/#soa[dynamic; $N]$E) -> (res: E, ok: bool) #no_bounds_check {
	if len(array) == 0 {
		return
	}
	res, ok = array[0], true
	_ordered_remove_soa_fixed_capacity(array, 0)
	return
}

@builtin
unordered_remove_soa_fixed_capacity :: proc(array: ^$T/#soa[dynamic; $N]$E, #any_int index: int, loc := #caller_location) #no_bounds_check {
	bounds_check_error_loc(loc, index, len(array))
	if index+1 < len(array) {
		array[index] = array[len(array)-1]
	}
	_soa_fixed_capacity_len(array)^ -= 1
}

@builtin
ordered_remove_soa_fixed_capacity :: proc(array: ^$T/#soa[dynamic; $N]$E, #any_int index: int, loc := #caller_location) #no_bounds_check {
	bounds_check_error_loc(loc, index, len(array))
	_ordered_remove_soa_fixed_capacity(array, index)
}

// The unchecked body of ordered_remove_soa_fixed_capacity, shared with the front pops
_ordered_remove_soa_fixed_capacity :: proc "contextless" (array: ^$T/#soa[dynamic; $N]$E, index: int) #no_bounds_check {
	if index+1 < len(array) {
		_soa_move(array[:], index, index + 1, len(array) - 1 - index)
	}
	_soa_fixed_capacity_len(array)^ -= 1
}
