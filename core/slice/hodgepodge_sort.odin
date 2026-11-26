#+private
package slice

import "base:builtin"
import "base:intrinsics"

// NOTE(bill, 2026-11-25): gingersort is the sort behind every procedure in this package.
// It is stable, sorts in place, and needs no allocator: its only scratch space is a stack buffer of at most GINGER_SWAP_BYTES.
// Small runs are sorted with branchless networks and merged through the buffer, and larger inputs are partitioned stably around a sampled pivot.
// A comparator that is not a strict weak order still leaves a permutation of the input.

ORD :: intrinsics.type_is_ordered

Sort_Kind :: enum {
	Ordered,
	Ordered_Reverse,
	Less,
	Less_Reverse,
	Less_Constant,
	Less_Reverse_Constant,
	Less_With_Data,
	Cmp,
	Cmp_Reverse,
	Cmp_Constant,
	Cmp_Reverse_Constant,
	Cmp_With_Data,
	Generic_Cmp,
	Key,
	Key_Reverse,
	Indices_Ordered,
	Indices_Less,
	Indices_Less_With_Data,
	Shared,
}

Sort_Less_With_Data :: struct($E: typeid) {
	less:      proc(i, j: E, user_data: rawptr) -> bool,
	user_data: rawptr,
}

Sort_Cmp_With_Data :: struct($E: typeid) {
	cmp:       proc(i, j: E, user_data: rawptr) -> Ordering,
	user_data: rawptr,
}

Sort_Generic_Cmp :: struct {
	cmp:       Generic_Cmp,
	user_data: rawptr,
}

Sort_Indices_Less :: struct($E: typeid) {
	less: proc(i, j: E) -> bool,
	data: []E,
}

Sort_Indices_Less_With_Data :: struct($E: typeid) {
	less:      proc(i, j: E, user_data: rawptr) -> bool,
	data:      []E,
	user_data: rawptr,
}

// At -o:size, elements are sorted as a stand-in of the same size and alignment, through a small per-type comparison.
// Every element type with that size and alignment then shares one body.
Sort_Shared_Item :: struct($N: int, $W: typeid) {
	words: [N]W,
}

Sort_Shared_Call :: struct($T: typeid) {
	greater: proc(a, b: T, call: rawptr) -> bool,
	call:    rawptr,
}

GINGER_SWAP_BYTES       :: 16 * 1024
GINGER_OUT              :: 96
GINGER_BLOCK            :: 16
GINGER_SMALL            :: 96
GINGER_LARGE            :: 1024
GINGER_SMALL_BYTES      :: 2048
GINGER_INSERTION_SMALL  :: 8
GINGER_INSERTION_LARGE  :: 32
GINGER_INSERTION_HUGE   :: 64
GINGER_NETWORK_BYTES    :: 16
GINGER_PARTITION_BLOCKS :: 4096
GINGER_PARTITION_HALVES :: 4
GINGER_RADIX_SMALL      :: 64

gingersort :: proc(data: []$E, call: $P, $KIND: Sort_Kind) {
	when size_of(E) == 0 {
		return
	} else when ODIN_OPTIMIZATION_MODE == .Size {
		ginger_sort_shared(data, call, KIND)
	} else {
		ginger_sort_typed(data, call, KIND)
	}
}

@(require_results)
ginger_is_sorted :: proc(a: []$E, call: $P, $KIND: Sort_Kind) -> bool {
	for i := len(a)-1; i > 0; i -= 1 {
		if ginger_greater(a[i-1], a[i], call, KIND) {
			return false
		}
	}
	return true
}

// Fills `indices` with the order that sorts `data`, then permutes `data` into it.
ginger_sort_indices :: proc(data: []$E, indices: []int, call: $P, $KIND: Sort_Kind) {
	for &index, i in indices {
		index = i
	}
	gingersort(indices, call, KIND)
	sort_from_permutation_indices(data, indices)
}

ginger_sort_shared :: proc(data: []$E, call: $P, $KIND: Sort_Kind) {
	when size_of(E)%8 == 0 && align_of(E) == 8 && align_of(u64) == 8 {
		W     :: u64
		SHARE :: true
	} else when size_of(E)%4 == 0 && align_of(E) == 4 && align_of(u32) == 4 {
		W     :: u32
		SHARE :: true
	} else when size_of(E)%2 == 0 && align_of(E) == 2 && align_of(u16) == 2 {
		W     :: u16
		SHARE :: true
	} else {
		W     :: u8
		SHARE :: align_of(E) == 1
	}

	when !SHARE {
		ginger_sort_typed(data, call, KIND)
	} else {
		Item :: Sort_Shared_Item(size_of(E)/size_of(W), W)
		#assert(size_of(Item) == size_of(E) && align_of(Item) == align_of(E))

		greater :: proc(a, b: Item, call: rawptr) -> bool {
			return ginger_greater(transmute(E)a, transmute(E)b, (^P)(call)^, KIND)
		}

		call := call
		ginger_sort_typed(transmute([]Item)data, Sort_Shared_Call(Item){greater, &call}, .Shared)
	}
}

ginger_sort_typed :: proc(data: []$E, call: $P, $KIND: Sort_Kind) #no_bounds_check {
	n := len(data)
	if n < 2 {
		return
	}

	CHEAP    :: (KIND == .Ordered || KIND == .Ordered_Reverse) && !intrinsics.type_is_string(E)
	CONSTANT :: KIND == .Less_Constant || KIND == .Less_Reverse_Constant || KIND == .Cmp_Constant || KIND == .Cmp_Reverse_Constant

	when CHEAP || (CONSTANT && size_of(E) <= GINGER_NETWORK_BYTES) {
		if n < 8 {
			tiny: [7]E = ---
			ginger_tiny_sort(data, tiny[:], call, KIND)
			return
		}
	} else {
		when CONSTANT {
			INSERTION_LIMIT :: GINGER_INSERTION_LARGE
		} else when size_of(E) <= 8 {
			INSERTION_LIMIT :: GINGER_INSERTION_SMALL
		} else when size_of(E) <= 32 {
			INSERTION_LIMIT :: GINGER_INSERTION_LARGE
		} else {
			INSERTION_LIMIT :: GINGER_INSERTION_HUGE
		}

		if n <= INSERTION_LIMIT {
			ginger_insertion_sort(data, call, KIND)
			return
		}
	}

	when size_of(E)*GINGER_SMALL <= GINGER_SMALL_BYTES {
		if n <= GINGER_SMALL {
			small: [GINGER_SMALL]E = ---
			ginger_tail_swap(data, small[:], call, KIND)
			return
		}
	}
	when size_of(E)*GINGER_LARGE <= GINGER_SWAP_BYTES {
		if n > GINGER_LARGE {
			ginger_large_buffered_sort(data, call, KIND)
			return
		}
	}
	ginger_buffered_sort(data, call, KIND)
}

ginger_large_buffered_sort :: #force_no_inline proc(data: []$E, call: $P, $KIND: Sort_Kind) #no_bounds_check {
	swap: [GINGER_LARGE]E = ---
	ginger_analyze(data, swap[:], call, KIND)
}

ginger_buffered_sort :: #force_no_inline proc(data: []$E, call: $P, $KIND: Sort_Kind) #no_bounds_check {
	when size_of(E)*512 <= GINGER_SWAP_BYTES {
		SWAP_LEN :: 512
	} else when size_of(E)*256 <= GINGER_SWAP_BYTES {
		SWAP_LEN :: 256
	} else when size_of(E)*128 <= GINGER_SWAP_BYTES {
		SWAP_LEN :: 128
	} else when size_of(E)*64 <= GINGER_SWAP_BYTES {
		SWAP_LEN :: 64
	} else when size_of(E)*32 <= GINGER_SWAP_BYTES {
		SWAP_LEN :: 32
	} else {
		SWAP_LEN :: builtin.max(GINGER_SWAP_BYTES/size_of(E), 1)
	}

	swap: [SWAP_LEN]E = ---
	when SWAP_LEN < 32 {
		ginger_large_element_sort(data, swap[:], call, KIND)
	} else {
		if len(data) <= 132 {
			ginger_quadsort(data, swap[:], call, KIND)
		} else {
			ginger_analyze(data, swap[:], call, KIND)
		}
	}
}

ginger_insertion_sort :: proc(a: []$E, call: $P, $KIND: Sort_Kind) #no_bounds_check {
	for i in 1..<len(a) {
		item := a[i]
		j := i
		for j > 0 && ginger_greater(a[j-1], item, call, KIND) {
			a[j] = a[j-1]
			j -= 1
		}
		a[j] = item
	}
}

ginger_large_element_sort :: proc(a, s: []$E, call: $P, $KIND: Sort_Kind) #no_bounds_check {
	n := len(a)
	for lo := 0; lo < n; lo += GINGER_BLOCK {
		ginger_insertion_sort(a[lo:builtin.min(lo+GINGER_BLOCK, n)], call, KIND)
	}

	if n > GINGER_BLOCK {
		ginger_rotate_merge(a, s, GINGER_BLOCK, call, KIND)
	}
}

@(require_results)
ginger_greater :: #force_inline proc(a, b: $E, call: $P, $KIND: Sort_Kind) -> bool #no_bounds_check {
	when KIND == .Ordered {
		return a > b
	} else when KIND == .Ordered_Reverse {
		return a < b
	} else when KIND == .Less || KIND == .Less_Constant {
		return call(b, a)
	} else when KIND == .Less_Reverse || KIND == .Less_Reverse_Constant {
		return call(a, b)
	} else when KIND == .Less_With_Data {
		return call.less(b, a, call.user_data)
	} else when KIND == .Cmp || KIND == .Cmp_Constant {
		return call(a, b) == .Greater
	} else when KIND == .Cmp_Reverse || KIND == .Cmp_Reverse_Constant {
		return call(b, a) == .Greater
	} else when KIND == .Cmp_With_Data {
		return call.cmp(a, b, call.user_data) == .Greater
	} else when KIND == .Generic_Cmp {
		x, y := a, b
		return call.cmp(&x, &y, call.user_data) == .Greater
	} else when KIND == .Key {
		return call(a) > call(b)
	} else when KIND == .Key_Reverse {
		return call(a) < call(b)
	} else when KIND == .Indices_Ordered {
		return call[a] > call[b]
	} else when KIND == .Indices_Less {
		return call.less(call.data[b], call.data[a])
	} else when KIND == .Indices_Less_With_Data {
		return call.less(call.data[b], call.data[a], call.user_data)
	} else when KIND == .Shared {
		return call.greater(a, b, call.call)
	} else {
		#panic("unhandled Sort_Kind")
	}
}

ginger_swap_if :: #force_inline proc(a: []$E, i: int, swap: bool) #no_bounds_check {
	lo := a[i+1] if swap else a[i]
	hi := a[i]   if swap else a[i+1]
	a[i]   = lo
	a[i+1] = hi
}

ginger_order_pair :: #force_inline proc(a: []$E, i: int, call: $P, $KIND: Sort_Kind) #no_bounds_check {
	ginger_swap_if(a, i, ginger_greater(a[i], a[i+1], call, KIND))
}

ginger_reverse :: proc(a: []$E) #no_bounds_check {
	for i, j := 0, len(a)-1; i < j; i, j = i+1, j-1 {
		temp := a[i]
		a[i] = a[j]
		a[j] = temp
	}
}

ginger_parity_swap_four :: #force_inline proc(a: []$E, call: $P, $KIND: Sort_Kind) #no_bounds_check {
	ginger_order_pair(a, 0, call, KIND)
	ginger_order_pair(a, 2, call, KIND)

	if ginger_greater(a[1], a[2], call, KIND) {
		a[1], a[2] = a[2], a[1]

		ginger_order_pair(a, 0, call, KIND)
		ginger_order_pair(a, 2, call, KIND)
		ginger_order_pair(a, 1, call, KIND)
	}
}

ginger_parity_swap_five :: #force_inline proc(a: []$E, call: $P, $KIND: Sort_Kind) #no_bounds_check {
	ginger_order_pair(a, 0, call, KIND)
	ginger_order_pair(a, 2, call, KIND)

	x := ginger_greater(a[1], a[2], call, KIND)
	ginger_swap_if(a, 1, x)

	y := ginger_greater(a[3], a[4], call, KIND)
	ginger_swap_if(a, 3, y)

	if x || y {
		ginger_order_pair(a, 0, call, KIND)
		ginger_order_pair(a, 2, call, KIND)
		ginger_order_pair(a, 1, call, KIND)
		ginger_order_pair(a, 3, call, KIND)
		ginger_order_pair(a, 0, call, KIND)
		ginger_order_pair(a, 2, call, KIND)
	}
}

ginger_parity_swap_six :: #force_inline proc(a, s: []$E, call: $P, $KIND: Sort_Kind) #no_bounds_check {
	ginger_order_pair(a, 0, call, KIND)
	ginger_order_pair(a, 1, call, KIND)
	ginger_order_pair(a, 4, call, KIND)
	ginger_order_pair(a, 3, call, KIND)

	if !ginger_greater(a[2], a[3], call, KIND) {
		ginger_order_pair(a, 0, call, KIND)
		ginger_order_pair(a, 4, call, KIND)
		return
	}

	x := int(ginger_greater(a[0], a[1], call, KIND))
	s[0] = a[x]
	s[1] = a[1-x]
	s[2] = a[2]

	y := int(ginger_greater(a[4], a[5], call, KIND))
	s[3] = a[3]
	s[4] = a[4+y]
	s[5] = a[5-y]

	ginger_parity_merge(a[:6], s[:6], 3, 3, call, KIND)
}

ginger_parity_swap_seven :: #force_inline proc(a, s: []$E, call: $P, $KIND: Sort_Kind) #no_bounds_check {
	ginger_order_pair(a, 0, call, KIND)
	ginger_order_pair(a, 2, call, KIND)
	ginger_order_pair(a, 4, call, KIND)

	x := ginger_greater(a[1], a[2], call, KIND)
	ginger_swap_if(a, 1, x)

	y := ginger_greater(a[3], a[4], call, KIND)
	ginger_swap_if(a, 3, y)

	z := ginger_greater(a[5], a[6], call, KIND)
	ginger_swap_if(a, 5, z)

	if !(x || y || z) {
		return
	}

	ginger_order_pair(a, 4, call, KIND)

	i := int(ginger_greater(a[0], a[1], call, KIND))
	s[0] = a[i]
	s[1] = a[1-i]
	s[2] = a[2]

	j := int(ginger_greater(a[3], a[4], call, KIND))
	s[3] = a[3+j]
	s[4] = a[4-j]

	k := int(ginger_greater(a[5], a[6], call, KIND))
	s[5] = a[5+k]
	s[6] = a[6-k]

	ginger_parity_merge(a[:7], s[:7], 3, 4, call, KIND)
}

ginger_tiny_sort :: #force_inline proc(a, s: []$E, call: $P, $KIND: Sort_Kind) #no_bounds_check {
	switch len(a) {
	case 2:
		ginger_order_pair(a, 0, call, KIND)
	case 3:
		ginger_order_pair(a, 0, call, KIND)
		ginger_order_pair(a, 1, call, KIND)
		ginger_order_pair(a, 0, call, KIND)
	case 4:
		ginger_parity_swap_four(a, call, KIND)
	case 5:
		ginger_parity_swap_five(a, call, KIND)
	case 6:
		ginger_parity_swap_six(a, s, call, KIND)
	case 7:
		ginger_parity_swap_seven(a, s, call, KIND)
	}
}

// Merges `from[:left]` and `from[left:][:right]` into `dest` from both ends at once, where `right` is `left` or `left+1`.
ginger_parity_merge :: proc(dest, from: []$E, left, right: int, call: $P, $KIND: Sort_Kind) #no_bounds_check {
	ptl := 0
	ptr := left
	tpl := left - 1
	tpr := left + right - 1
	ptd := 0
	tpd := left + right - 1

	if left < right {
		take_left := !ginger_greater(from[ptl], from[ptr], call, KIND)
		dest[ptd] = from[ptl] if take_left else from[ptr]
		ptl += int(take_left)
		ptr += int(!take_left)
		ptd += 1
	}

	for _ in 0..<left {
		take_left := !ginger_greater(from[ptl], from[ptr], call, KIND)
		dest[ptd] = from[ptl] if take_left else from[ptr]
		ptl += int(take_left)
		ptr += int(!take_left)
		ptd += 1

		take_right := !ginger_greater(from[tpl], from[tpr], call, KIND)
		dest[tpd] = from[tpr] if take_right else from[tpl]
		tpr -= int(take_right)
		tpl -= int(!take_right)
		tpd -= 1
	}

	if ptl != tpl+1 || ptr != tpr+1 {
		copy(dest[:left+right], from[:left+right])
	}
}

ginger_tail_swap :: proc(a, s: []$E, call: $P, $KIND: Sort_Kind) #no_bounds_check {
	n := len(a)
	if n < 8 {
		ginger_tiny_sort(a, s, call, KIND)
		return
	}

	half1 := n / 2
	quad1 := half1 / 2
	quad2 := half1 - quad1
	half2 := n - half1
	quad3 := half2 / 2
	quad4 := half2 - quad3

	ginger_tail_swap(a[:quad1],            s, call, KIND)
	ginger_tail_swap(a[quad1:half1],       s, call, KIND)
	ginger_tail_swap(a[half1:half1+quad3], s, call, KIND)
	ginger_tail_swap(a[half1+quad3:],      s, call, KIND)

	if !ginger_greater(a[quad1-1],       a[quad1],       call, KIND) &&
	   !ginger_greater(a[half1-1],       a[half1],       call, KIND) &&
	   !ginger_greater(a[half1+quad3-1], a[half1+quad3], call, KIND) {
		return
	}

	ginger_parity_merge(s[:half1],  a[:half1],  quad1, quad2, call, KIND)
	ginger_parity_merge(s[half1:n], a[half1:n], quad3, quad4, call, KIND)
	ginger_parity_merge(a[:n],      s[:n],      half1, half2, call, KIND)
}

ginger_quad_swap_merge :: proc(a, s: []$E, call: $P, $KIND: Sort_Kind) #no_bounds_check {
	ginger_parity_merge(s[0:4], a[0:4], 2, 2, call, KIND)
	ginger_parity_merge(s[4:8], a[4:8], 2, 2, call, KIND)
	ginger_parity_merge(a[0:8], s[0:8], 4, 4, call, KIND)
}

// Sorts blocks of 8 and then of 32, reversing descending runs in one go.
// Returns true when the whole of `a` was one descending run, which is now sorted.
@(require_results)
ginger_quad_swap :: proc(a, s: []$E, call: $P, $KIND: Sort_Kind) -> bool #no_bounds_check {
	n     := len(a)
	count := n / 8
	i     := 0
	pts   := 0

	in_reversed_run := false
	reversed_to_end := false

	blocks: for {
		if !in_reversed_run {
			if count == 0 {
				break blocks
			}
			count -= 1

			v1 := ginger_greater(a[i],   a[i+1], call, KIND)
			v2 := ginger_greater(a[i+2], a[i+3], call, KIND)
			v3 := ginger_greater(a[i+4], a[i+5], call, KIND)
			v4 := ginger_greater(a[i+6], a[i+7], call, KIND)

			if !(v1 || v2 || v3 || v4) {
				if !ginger_greater(a[i+1], a[i+2], call, KIND) &&
				   !ginger_greater(a[i+3], a[i+4], call, KIND) &&
				   !ginger_greater(a[i+5], a[i+6], call, KIND) {
					i += 8
					continue blocks
				}
				ginger_quad_swap_merge(a[i:i+8], s, call, KIND)
			} else if v1 && v2 && v3 && v4 &&
			          ginger_greater(a[i+1], a[i+2], call, KIND) &&
			          ginger_greater(a[i+3], a[i+4], call, KIND) &&
			          ginger_greater(a[i+5], a[i+6], call, KIND) {
				pts = i
				in_reversed_run = true
				continue blocks
			} else {
				ginger_swap_if(a, i,   v1)
				ginger_swap_if(a, i+2, v2)
				ginger_swap_if(a, i+4, v3)
				ginger_swap_if(a, i+6, v4)
				ginger_quad_swap_merge(a[i:i+8], s, call, KIND)
			}
			i += 8
			continue blocks
		}

		i += 8
		if count == 0 {
			rest := n % 8

			descending := true
			for k := rest; k >= 1; k -= 1 {
				if !ginger_greater(a[i+k-2], a[i+k-1], call, KIND) {
					descending = false
					break
				}
			}

			if descending {
				ginger_reverse(a[pts:i+rest])
				if pts == 0 {
					return true
				}
				reversed_to_end = true
				break blocks
			}
			ginger_reverse(a[pts:i])
			break blocks
		}
		count -= 1

		o1 := !ginger_greater(a[i],   a[i+1], call, KIND)
		o2 := !ginger_greater(a[i+2], a[i+3], call, KIND)
		o3 := !ginger_greater(a[i+4], a[i+5], call, KIND)
		o4 := !ginger_greater(a[i+6], a[i+7], call, KIND)

		if !(o1 || o2 || o3 || o4) {
			if ginger_greater(a[i-1], a[i],   call, KIND) &&
			   ginger_greater(a[i+1], a[i+2], call, KIND) &&
			   ginger_greater(a[i+3], a[i+4], call, KIND) &&
			   ginger_greater(a[i+5], a[i+6], call, KIND) {
				continue blocks
			}
		}
		ginger_reverse(a[pts:i])
		in_reversed_run = false

		if o1 && o2 && o3 && o4 &&
		   !ginger_greater(a[i+1], a[i+2], call, KIND) &&
		   !ginger_greater(a[i+3], a[i+4], call, KIND) &&
		   !ginger_greater(a[i+5], a[i+6], call, KIND) {
			i += 8
			continue blocks
		}

		if !(o1 || o2 || o3 || o4) &&
		   ginger_greater(a[i+1], a[i+2], call, KIND) &&
		   ginger_greater(a[i+3], a[i+4], call, KIND) &&
		   ginger_greater(a[i+5], a[i+6], call, KIND) {
			pts = i
			in_reversed_run = true
			continue blocks
		}

		ginger_swap_if(a, i,   !o1)
		ginger_swap_if(a, i+2, !o2)
		ginger_swap_if(a, i+4, !o3)
		ginger_swap_if(a, i+6, !o4)

		if ginger_greater(a[i+1], a[i+2], call, KIND) ||
		   ginger_greater(a[i+3], a[i+4], call, KIND) ||
		   ginger_greater(a[i+5], a[i+6], call, KIND) {
			ginger_quad_swap_merge(a[i:i+8], s, call, KIND)
		}
		i += 8
	}

	if !reversed_to_end {
		ginger_tail_swap(a[i:i+n%8], s, call, KIND)
	}

	j := 0
	for c := n / 32; c > 0; c -= 1 {
		if !ginger_greater(a[j+7],  a[j+8],  call, KIND) &&
		   !ginger_greater(a[j+15], a[j+16], call, KIND) &&
		   !ginger_greater(a[j+23], a[j+24], call, KIND) {
			j += 32
			continue
		}

		ginger_parity_merge(s[0:16],    a[j:j+16],    8,  8,  call, KIND)
		ginger_parity_merge(s[16:32],   a[j+16:j+32], 8,  8,  call, KIND)
		ginger_parity_merge(a[j:j+32],  s[0:32],      16, 16, call, KIND)
		j += 32
	}

	if n%32 > 8 {
		ginger_tail_merge(a[j:j+n%32], s, 8, call, KIND)
	}
	return false
}

// Merges `from[:left]` and `from[left:][:right]` into `dest`.
ginger_cross_merge :: proc(dest, from: []$E, left, right: int, call: $P, $KIND: Sort_Kind) #no_bounds_check {
	ptl := 0
	ptr := left
	tpl := left - 1
	tpr := left + right - 1

	if left+1 >= right && right >= left && left >= 32 {
		if  ginger_greater(from[ptl+15], from[ptr],    call, KIND) &&
		   !ginger_greater(from[ptl],    from[ptr+15], call, KIND) &&
		    ginger_greater(from[tpl],    from[tpr-15], call, KIND) &&
		   !ginger_greater(from[tpl-15], from[tpr],    call, KIND) {
			ginger_parity_merge(dest, from, left, right, call, KIND)
			return
		}
	}

	ptd := 0
	tpd := left + right - 1

	for ptl <= tpl && ptr <= tpr {
		if tpl-ptl > 8 {
			if !ginger_greater(from[ptl+7], from[ptr], call, KIND) {
				copy(dest[ptd:ptd+8], from[ptl:ptl+8])
				ptd += 8
				ptl += 8
				continue
			}

			if ginger_greater(from[tpl-7], from[tpr], call, KIND) {
				copy(dest[tpd-7:tpd+1], from[tpl-7:tpl+1])
				tpd -= 8
				tpl -= 8
				continue
			}
		}

		if tpr-ptr > 8 {
			if ginger_greater(from[ptl], from[ptr+7], call, KIND) {
				copy(dest[ptd:ptd+8], from[ptr:ptr+8])
				ptd += 8
				ptr += 8
				continue
			}

			if !ginger_greater(from[tpl], from[tpr-7], call, KIND) {
				copy(dest[tpd-7:tpd+1], from[tpr-7:tpr+1])
				tpd -= 8
				tpr -= 8
				continue
			}
		}

		if tpl-ptl < 15 || tpr-ptr < 15 {
			break
		}

		for _ in 0..<8 {
			take_left := !ginger_greater(from[ptl], from[ptr], call, KIND)
			dest[ptd] = from[ptl] if take_left else from[ptr]
			ptl += int(take_left)
			ptr += int(!take_left)
			ptd += 1

			take_right := !ginger_greater(from[tpl], from[tpr], call, KIND)
			dest[tpd] = from[tpr] if take_right else from[tpl]
			tpr -= int(take_right)
			tpl -= int(!take_right)
			tpd -= 1
		}
	}

	for ptl <= tpl && ptr <= tpr {
		if ginger_greater(from[ptl], from[ptr], call, KIND) {
			dest[ptd] = from[ptr]
			ptr += 1
		} else {
			dest[ptd] = from[ptl]
			ptl += 1
		}
		ptd += 1
	}

	copy(dest[ptd:], from[ptl:tpl+1])
	copy(dest[ptd:], from[ptr:tpr+1])
}

ginger_quad_merge_block :: proc(a, s: []$E, block: int, call: $P, $KIND: Sort_Kind) #no_bounds_check {
	b2 := block * 2
	p1 := block
	p3 := block * 3

	first_ordered  := !ginger_greater(a[p1-1], a[p1], call, KIND)
	second_ordered := !ginger_greater(a[p3-1], a[p3], call, KIND)

	switch {
	case first_ordered && second_ordered:
		if !ginger_greater(a[b2-1], a[b2], call, KIND) {
			return
		}
		copy(s[:b2*2], a[:b2*2])

	case first_ordered:
		copy(s[:b2], a[:b2])
		ginger_cross_merge(s[b2:b2*2], a[b2:b2*2], block, block, call, KIND)

	case second_ordered:
		ginger_cross_merge(s[:b2], a[:b2], block, block, call, KIND)
		copy(s[b2:b2*2], a[b2:b2*2])

	case:
		ginger_cross_merge(s[:b2],     a[:b2],     block, block, call, KIND)
		ginger_cross_merge(s[b2:b2*2], a[b2:b2*2], block, block, call, KIND)
	}

	ginger_cross_merge(a[:b2*2], s[:b2*2], b2, b2, call, KIND)
}

@(require_results)
ginger_quad_merge :: proc(a, s: []$E, start_block: int, call: $P, $KIND: Sort_Kind) -> int #no_bounds_check {
	n     := len(a)
	block := start_block * 4

	for block <= n && block <= len(s) {
		pta := 0
		for pta+block <= n {
			ginger_quad_merge_block(a[pta:pta+block], s, block/4, call, KIND)
			pta += block
		}

		ginger_tail_merge(a[pta:n], s, block/4, call, KIND)
		block *= 4
	}

	ginger_tail_merge(a, s, block/4, call, KIND)
	return block / 2
}

ginger_partial_forward_merge :: proc(a, s: []$E, block: int, call: $P, $KIND: Sort_Kind) #no_bounds_check {
	n := len(a)
	if block == 0 || n == block {
		return
	}

	ptr := block
	tpr := n - 1
	if !ginger_greater(a[ptr-1], a[ptr], call, KIND) {
		return
	}

	copy(s[:block], a[:block])
	ptl := 0
	tpl := block - 1
	out := 0

	for ptl < tpl-1 && ptr < tpr-1 {
		if ginger_greater(s[ptl], a[ptr+1], call, KIND) {
			a[out]   = a[ptr]
			a[out+1] = a[ptr+1]
			out += 2
			ptr += 2
			continue
		}

		if !ginger_greater(s[ptl+1], a[ptr], call, KIND) {
			a[out]   = s[ptl]
			a[out+1] = s[ptl+1]
			out += 2
			ptl += 2
			continue
		}

		left_first := !ginger_greater(s[ptl], a[ptr], call, KIND)
		right_item := a[ptr]
		left_item  := s[ptl]
		a[out+int(left_first)]  = right_item
		a[out+int(!left_first)] = left_item
		out += 2
		ptr += 1
		ptl += 1

		if ginger_greater(s[ptl], a[ptr], call, KIND) {
			a[out] = a[ptr]
			ptr += 1
		} else {
			a[out] = s[ptl]
			ptl += 1
		}
		out += 1
	}

	for ptl <= tpl && ptr <= tpr {
		if ginger_greater(s[ptl], a[ptr], call, KIND) {
			a[out] = a[ptr]
			ptr += 1
		} else {
			a[out] = s[ptl]
			ptl += 1
		}
		out += 1
	}

	copy(a[out:], s[ptl:tpl+1])
}

// Moves the last two or three items of `a[:tpl+1]` and `s[:tpr+1]` to `a[:tpa+1]`, in order.
@(require_results)
ginger_backward_merge_step :: #force_inline proc(a, s: []$E, tpl, tpr, tpa: int, call: $P, $KIND: Sort_Kind) -> (int, int, int) #no_bounds_check {
	if !ginger_greater(a[tpl], s[tpr-1], call, KIND) {
		a[tpa]   = s[tpr]
		a[tpa-1] = s[tpr-1]
		return tpl, tpr-2, tpa-2
	}

	if ginger_greater(a[tpl-1], s[tpr], call, KIND) {
		a[tpa]   = a[tpl]
		a[tpa-1] = a[tpl-1]
		return tpl-2, tpr, tpa-2
	}

	right_after := !ginger_greater(a[tpl], s[tpr], call, KIND)
	right_item  := s[tpr]
	left_item   := a[tpl]
	a[tpa-1+int(right_after)]  = right_item
	a[tpa-1+int(!right_after)] = left_item

	if ginger_greater(a[tpl-1], s[tpr-1], call, KIND) {
		a[tpa-2] = a[tpl-1]
		return tpl-2, tpr-1, tpa-3
	}
	a[tpa-2] = s[tpr-1]
	return tpl-1, tpr-2, tpa-3
}

ginger_partial_backward_merge :: proc(a, s: []$E, block: int, call: $P, $KIND: Sort_Kind) #no_bounds_check {
	n := len(a)
	if block == 0 || n == block {
		return
	}

	tpl := block - 1
	tpa := n - 1
	if !ginger_greater(a[tpl], a[tpl+1], call, KIND) {
		return
	}

	right := n - block
	if n <= len(s) && right >= 64 {
		ginger_cross_merge(s[:n], a[:n], block, right, call, KIND)
		copy(a[:n], s[:n])
		return
	}

	copy(s[:right], a[block:n])
	tpr := right - 1

	bulk: for tpl > 16 && tpr > 16 {
		for !ginger_greater(a[tpl], s[tpr-15], call, KIND) {
			for _ in 0..<16 {
				a[tpa] = s[tpr]
				tpa -= 1
				tpr -= 1
			}
			if tpr <= 16 {
				break bulk
			}
		}

		for ginger_greater(a[tpl-15], s[tpr], call, KIND) {
			for _ in 0..<16 {
				a[tpa] = a[tpl]
				tpa -= 1
				tpl -= 1
			}
			if tpl <= 16 {
				break bulk
			}
		}

		for _ in 0..<8 {
			tpl, tpr, tpa = ginger_backward_merge_step(a, s, tpl, tpr, tpa, call, KIND)
		}
	}

	for tpr > 1 && tpl > 1 {
		tpl, tpr, tpa = ginger_backward_merge_step(a, s, tpl, tpr, tpa, call, KIND)
	}

	for tpr >= 0 && tpl >= 0 {
		if ginger_greater(a[tpl], s[tpr], call, KIND) {
			a[tpa] = a[tpl]
			tpl -= 1
		} else {
			a[tpa] = s[tpr]
			tpr -= 1
		}
		tpa -= 1
	}

	copy(a[tpa-tpr:tpa+1], s[:tpr+1])
}

ginger_tail_merge :: proc(a, s: []$E, start_block: int, call: $P, $KIND: Sort_Kind) #no_bounds_check {
	n     := len(a)
	block := start_block

	for block < n && block <= len(s) {
		for pta := 0; pta+block < n; pta += block*2 {
			ginger_partial_backward_merge(a[pta:builtin.min(pta+block*2, n)], s, block, call, KIND)
		}
		block *= 2
	}
}

// Rotates `a` so that `a[left:]` comes before `a[:left]`.
ginger_trinity_rotation :: proc(a, s: []$E, left: int) #no_bounds_check {
	n         := len(a)
	right     := n - left
	swap_size := builtin.min(len(s), 65536)

	switch {
	case left < right:
		if left <= swap_size {
			copy(s[:left], a[:left])
			copy(a[:right], a[left:n])
			copy(a[right:n], s[:left])
			return
		}

		pta := 0
		ptb := left

		bridge := right - left
		if bridge <= swap_size && bridge > 3 {
			ptc := right
			ptd := right + left
			copy(s[:bridge], a[ptb:ptb+bridge])

			for _ in 0..<left {
				ptc -= 1
				ptd -= 1
				a[ptc] = a[ptd]
				ptb -= 1
				a[ptd] = a[ptb]
			}
			copy(a[pta:pta+bridge], s[:bridge])
			return
		}

		ptc := ptb
		ptd := ptb + right

		for count := left / 2; count > 0; count -= 1 {
			ptb -= 1
			temp := a[ptb]
			a[ptb] = a[pta]
			a[pta] = a[ptc]
			pta += 1
			ptd -= 1
			a[ptc] = a[ptd]
			ptc += 1
			a[ptd] = temp
		}

		for count := (ptd - ptc) / 2; count > 0; count -= 1 {
			temp := a[ptc]
			ptd -= 1
			a[ptc] = a[ptd]
			ptc += 1
			a[ptd] = a[pta]
			a[pta] = temp
			pta += 1
		}
		ginger_reverse(a[pta:ptd])

	case right < left:
		if right <= swap_size {
			copy(s[:right], a[left:n])
			copy(a[right:n], a[:left])
			copy(a[:right], s[:right])
			return
		}

		pta := 0
		ptb := left

		bridge := left - right
		if bridge <= swap_size && bridge > 3 {
			ptc := right
			ptd := right + left
			copy(s[:bridge], a[ptc:ptc+bridge])

			for _ in 0..<right {
				a[ptc] = a[pta]
				ptc += 1
				a[pta] = a[ptb]
				pta += 1
				ptb += 1
			}
			copy(a[ptd-bridge:ptd], s[:bridge])
			return
		}

		ptc := ptb
		ptd := ptb + right

		for count := right / 2; count > 0; count -= 1 {
			ptb -= 1
			temp := a[ptb]
			a[ptb] = a[pta]
			a[pta] = a[ptc]
			pta += 1
			ptd -= 1
			a[ptc] = a[ptd]
			ptc += 1
			a[ptd] = temp
		}

		for count := (ptb - pta) / 2; count > 0; count -= 1 {
			ptb -= 1
			temp := a[ptb]
			a[ptb] = a[pta]
			ptd -= 1
			a[pta] = a[ptd]
			pta += 1
			a[ptd] = temp
		}
		ginger_reverse(a[pta:ptd])

	case:
		swap_with_slice(a[:left], a[left:])
	}
}

// The index of the first item of `a[:top]` that `value` is not greater than.
@(require_results)
ginger_monobound_binary_first :: proc(a: []$E, value: E, top: int, call: $P, $KIND: Sort_Kind) -> int #no_bounds_check {
	top := top
	end := top

	for top > 1 {
		mid := top / 2
		if !ginger_greater(value, a[end-mid], call, KIND) {
			end -= mid
		}
		top -= mid
	}

	if !ginger_greater(value, a[end-1], call, KIND) {
		end -= 1
	}
	return end
}

ginger_rotate_merge_block :: proc(a, s: []$E, block, count: int, call: $P, $KIND: Sort_Kind) #no_bounds_check {
	if block == 0 || !ginger_greater(a[block-1], a[block], call, KIND) {
		return
	}

	if block == 1 {
		position := ginger_monobound_binary_first(a[1:], a[0], count, call, KIND)
		ginger_trinity_rotation(a[:1+position], s, 1)
		return
	}

	rblock := block / 2
	lblock := block - rblock

	left  := ginger_monobound_binary_first(a[lblock+rblock:], a[lblock], count, call, KIND)
	right := count - left

	if left > 0 {
		if lblock+left <= len(s) {
			copy(s[:lblock], a[:lblock])
			copy(s[lblock:lblock+left], a[lblock+rblock:lblock+rblock+left])
			copy(a[lblock+left:lblock+left+rblock], a[lblock:lblock+rblock])
			ginger_cross_merge(a[:lblock+left], s[:lblock+left], lblock, left, call, KIND)
		} else {
			ginger_trinity_rotation(a[lblock:lblock+rblock+left], s, rblock)

			unbalanced := left*2 < lblock || lblock*2 < left
			switch {
			case unbalanced && left <= len(s):
				ginger_partial_backward_merge(a[:lblock+left], s, lblock, call, KIND)
			case unbalanced && lblock <= len(s):
				ginger_partial_forward_merge(a[:lblock+left], s, lblock, call, KIND)
			case:
				ginger_rotate_merge_block(a[:lblock+left], s, lblock, left, call, KIND)
			}
		}
	}

	if right > 0 {
		rest := a[lblock+left:lblock+left+rblock+right]

		unbalanced := right*2 < rblock || rblock*2 < right
		switch {
		case (unbalanced && right <= len(s)) || right+rblock <= len(s):
			ginger_partial_backward_merge(rest, s, rblock, call, KIND)
		case unbalanced && rblock <= len(s):
			ginger_partial_forward_merge(rest, s, rblock, call, KIND)
		case:
			ginger_rotate_merge_block(rest, s, rblock, right, call, KIND)
		}
	}
}

ginger_rotate_merge :: proc(a, s: []$E, start_block: int, call: $P, $KIND: Sort_Kind) #no_bounds_check {
	n     := len(a)
	block := start_block

	if block <= n && n <= block*2 && n-block <= len(s) {
		ginger_partial_backward_merge(a, s, block, call, KIND)
		return
	}

	for block < n {
		for pta := 0; pta+block < n; pta += block*2 {
			end := builtin.min(pta+block*2, n)
			ginger_rotate_merge_block(a[pta:end], s, block, end-pta-block, call, KIND)
		}
		block *= 2
	}
}

ginger_quadsort :: proc(a, s: []$E, call: $P, $KIND: Sort_Kind) #no_bounds_check {
	if len(a) <= GINGER_SMALL && len(a) <= len(s) {
		ginger_tail_swap(a, s, call, KIND)
		return
	}

	if !ginger_quad_swap(a, s, call, KIND) {
		block := ginger_quad_merge(a, s, 32, call, KIND)
		ginger_rotate_merge(a, s, block, call, KIND)
	}
}

@(require_results)
ginger_binary_median :: proc(pa, pb: []$E, length: int, call: $P, $KIND: Sort_Kind) -> E #no_bounds_check {
	a := 0
	b := 0

	for l := length / 2; l > 0; l /= 2 {
		if ginger_greater(pa[a+l], pb[b+l], call, KIND) {
			b += l
		} else {
			a += l
		}
	}

	if ginger_greater(pa[a], pb[b], call, KIND) {
		return pa[a]
	}
	return pb[b]
}

ginger_trim_four :: proc(p: []$E, call: $P, $KIND: Sort_Kind) #no_bounds_check {
	x := int(ginger_greater(p[0], p[1], call, KIND))
	t := p[1-x]
	p[0] = p[x]
	p[1] = t

	x = int(ginger_greater(p[2], p[3], call, KIND))
	t = p[3-x]
	p[2] = p[2+x]
	p[3] = t

	x = int(!ginger_greater(p[0], p[2], call, KIND)) * 2
	p[2] = p[x]

	x = int(ginger_greater(p[1], p[3], call, KIND)) * 2
	p[1] = p[1+x]
}

@(require_results)
ginger_median_of_nine :: proc(a, s: []$E, call: $P, $KIND: Sort_Kind) -> E #no_bounds_check {
	step := len(a) / 9
	for k in 0..<9 {
		s[k] = a[k*step]
	}

	ginger_trim_four(s[0:4], call, KIND)
	ginger_trim_four(s[4:8], call, KIND)

	s[0] = s[5]
	s[3] = s[8]
	ginger_trim_four(s[0:4], call, KIND)

	s[0] = s[6]
	x := ginger_greater(s[0], s[1], call, KIND)
	y := ginger_greater(s[0], s[2], call, KIND)
	z := ginger_greater(s[1], s[2], call, KIND)
	return s[int(x == y) + int(y ~ z)]
}

@(require_results)
ginger_median_of_cbrt :: proc(a, s: []$E, call: $P, $KIND: Sort_Kind) -> (pivot: E, all_equal: bool) #no_bounds_check {
	n := len(a)

	cbrt := 32
	for n > cbrt*cbrt*cbrt && cbrt < len(s) {
		cbrt *= 2
	}

	step := n / cbrt
	for k in 0..<cbrt {
		s[k] = a[k*step]
	}

	pa := 0
	pb := cbrt / 2
	for _ in 0..<cbrt/8 {
		ginger_trim_four(s[pa:pa+4], call, KIND)
		ginger_trim_four(s[pb:pb+4], call, KIND)
		s[pa]   = s[pb+1]
		s[pa+3] = s[pb+2]
		pa += 4
		pb += 4
	}

	quarter := cbrt / 4
	ginger_quadsort(s[0:quarter],         s[quarter*2:quarter*3], call, KIND)
	ginger_quadsort(s[quarter:quarter*2], s[quarter*2:quarter*3], call, KIND)

	all_equal = !ginger_greater(s[quarter*2-1], s[0], call, KIND)
	pivot     = ginger_binary_median(s[0:quarter], s[quarter:quarter*2], quarter, call, KIND)
	return
}

// Which items a partition moves to the front: those not greater than the pivot, or only those less than it.
// The two differ only in where the items equal to the pivot go.
Ginger_Front :: enum {
	Not_Greater,
	Less,
}

// The partition moves four 32-bit items at a time with a 16-byte `simd_runtime_swizzle`, where that is one instruction:
// SSSE3 on x86 (x86-64-v2, the default, has it), NEON on ARM, and simd128 on wasm.
// Elsewhere the swizzle is emulated a lane at a time, several times slower than the scalar loop.
GINGER_PARTITION_SIMD :: (ODIN_ARCH == .amd64  || ODIN_ARCH == .i386)      && intrinsics.has_target_feature("ssse3") ||
                         (ODIN_ARCH == .arm64  || ODIN_ARCH == .arm32)     && intrinsics.has_target_feature("neon")  ||
                         (ODIN_ARCH == .wasm32 || ODIN_ARCH == .wasm64p32) && intrinsics.has_target_feature("simd128")

// For each mask of four lanes, the byte shuffle that moves the masked lanes to the front, in order, and the others after them.
@(rodata)
ginger_lane_shuffles := [16]#simd[16]u8{
	{ 0,  1,  2,  3,  4,  5,  6,  7,  8,  9, 10, 11, 12, 13, 14, 15},
	{ 0,  1,  2,  3,  4,  5,  6,  7,  8,  9, 10, 11, 12, 13, 14, 15},
	{ 4,  5,  6,  7,  0,  1,  2,  3,  8,  9, 10, 11, 12, 13, 14, 15},
	{ 0,  1,  2,  3,  4,  5,  6,  7,  8,  9, 10, 11, 12, 13, 14, 15},
	{ 8,  9, 10, 11,  0,  1,  2,  3,  4,  5,  6,  7, 12, 13, 14, 15},
	{ 0,  1,  2,  3,  8,  9, 10, 11,  4,  5,  6,  7, 12, 13, 14, 15},
	{ 4,  5,  6,  7,  8,  9, 10, 11,  0,  1,  2,  3, 12, 13, 14, 15},
	{ 0,  1,  2,  3,  4,  5,  6,  7,  8,  9, 10, 11, 12, 13, 14, 15},
	{12, 13, 14, 15,  0,  1,  2,  3,  4,  5,  6,  7,  8,  9, 10, 11},
	{ 0,  1,  2,  3, 12, 13, 14, 15,  4,  5,  6,  7,  8,  9, 10, 11},
	{ 4,  5,  6,  7, 12, 13, 14, 15,  0,  1,  2,  3,  8,  9, 10, 11},
	{ 0,  1,  2,  3,  4,  5,  6,  7, 12, 13, 14, 15,  8,  9, 10, 11},
	{ 8,  9, 10, 11, 12, 13, 14, 15,  0,  1,  2,  3,  4,  5,  6,  7},
	{ 0,  1,  2,  3,  8,  9, 10, 11, 12, 13, 14, 15,  4,  5,  6,  7},
	{ 4,  5,  6,  7,  8,  9, 10, 11, 12, 13, 14, 15,  0,  1,  2,  3},
	{ 0,  1,  2,  3,  4,  5,  6,  7,  8,  9, 10, 11, 12, 13, 14, 15},
}

// Moves the LANES items at `src` in order, the kept ones to `lows` and the rest to `highs`, and returns how many it kept.
// With four lanes, each destination takes a whole vector.
@(require_results)
ginger_partition_lanes :: #force_inline proc(src, lows, highs: ^$E, pivot: E, call: $P, $KIND: Sort_Kind, $FRONT: Ginger_Front, $LANES: int) -> int #no_bounds_check {
	when LANES == 1 {
		item := src^
		keep := ginger_greater(pivot, item, call, KIND) if FRONT == .Less else !ginger_greater(item, pivot, call, KIND)
		lows^  = item
		highs^ = item
		return int(keep)
	} else {
		#assert(LANES == 4 && size_of(E) == 4)
		V :: #simd[4]E

		x := intrinsics.unaligned_load((^V)(src))
		p := V(pivot)
		// Orders the operands so that `simd_lanes_gt(a, b)` is greater(item, pivot) in the sort's direction.
		when KIND == .Ordered {
			a, b := x, p
		} else {
			a, b := p, x
		}
		when FRONT == .Less {
			keep := intrinsics.simd_lanes_gt(b, a)  // greater(pivot, item)
		} else {
			keep := ~intrinsics.simd_lanes_gt(a, b) // not greater(item, pivot)
		}
		mask := transmute(u8)intrinsics.simd_extract_msbs(keep)

		bytes := transmute(#simd[16]u8)x
		intrinsics.unaligned_store((^#simd[16]u8)(lows),  intrinsics.simd_runtime_swizzle(bytes, ginger_lane_shuffles[mask]))
		intrinsics.unaligned_store((^#simd[16]u8)(highs), intrinsics.simd_runtime_swizzle(bytes, ginger_lane_shuffles[mask ~ 0xF]))
		return int(intrinsics.count_ones(mask))
	}
}

// Moves the items FRONT selects to the front, keeping their order and that of the rest.
@(require_results)
ginger_stable_partition :: proc(a, s: []$E, pivot: E, call: $P, $KIND: Sort_Kind, $FRONT: Ginger_Front) -> (count: int) #no_bounds_check {
	// Integers in their own order take ginger_radix_sort instead. Only f32 comes here to use lanes.
	F32   :: intrinsics.type_is_float(E) && intrinsics.type_is_endian_platform(E) && size_of(E) == 4
	LANES :: 4 when GINGER_PARTITION_SIMD && (KIND == .Ordered || KIND == .Ordered_Reverse) && F32 else 1

	n := len(a)
	if n <= len(s) {
		// Scalar items stay in a plain `k < n` loop. LLVM cannot count the trips of `k+1 <= n` without nsw.
		k := 0
		when LANES > 1 {
			for /**/; k+LANES <= n; k += LANES {
				count += ginger_partition_lanes(&a[k], &a[count], &s[k-count], pivot, call, KIND, FRONT, LANES)
			}
		}
		for /**/; k < n; k += 1 {
			count += ginger_partition_lanes(&a[k], &a[count], &s[k-count], pivot, call, KIND, FRONT, 1)
		}
		copy(a[count:n], s[:n-count])
		return
	}
	// Up to GINGER_PARTITION_HALVES levels of halving and rotating are cheaper than the block passes.
	// A block leaves the rest of its half of the buffer for what one step carries past it.
	block := len(s)/2 - (LANES-1)
	if n > len(s) << GINGER_PARTITION_HALVES && block >= LANES && n <= GINGER_PARTITION_BLOCKS*block {
		return ginger_block_partition(a, s, block, pivot, call, KIND, FRONT, LANES)
	}

	half  := n / 2
	left  := ginger_stable_partition(a[:half], s, pivot, call, KIND, FRONT)
	right := ginger_stable_partition(a[half:], s, pivot, call, KIND, FRONT)
	ginger_trinity_rotation(a[left:half+right], s, half-left)
	return left + right
}

// Each half of the buffer collects one side and is written back as a whole block of `b` items once full, into the part of `a` already read.
// The blocks are then put in order. Every item moves a fixed number of times, not once per level of halving.
@(require_results)
ginger_block_partition :: proc(a, s: []$E, b: int, pivot: E, call: $P, $KIND: Sort_Kind, $FRONT: Ginger_Front, $LANES: int) -> (count: int) #no_bounds_check {
	WORDS :: GINGER_PARTITION_BLOCKS / 64

	n     := len(a)
	half  := len(s) / 2
	lows  := s[:half]
	highs := s[half:][:half]

	low_blocks: [WORDS]u64
	blocks := 0
	nl, nh := 0, 0
	k      := 0
	// A vector step can run past a full block into the rest of its half. The last few items go there too and are never flushed.
	// One item fills a block exactly. Sharing the vector loop's form made scalar sorts 5-14% slower.
	when LANES > 1 {
		for /**/; k+LANES <= n; k += LANES {
			kept := ginger_partition_lanes(&a[k], &lows[nl], &highs[nh], pivot, call, KIND, FRONT, LANES)
			nl += kept
			nh += LANES - kept

			if nl >= b {
				copy(a[blocks*b:][:b], lows[:b])
				copy(lows, lows[b:nl])
				low_blocks[blocks>>6] |= 1 << uint(blocks&63)
				blocks += 1
				nl -= b
			}
			if nh >= b {
				copy(a[blocks*b:][:b], highs[:b])
				copy(highs, highs[b:nh])
				blocks += 1
				nh -= b
			}
		}
		for /**/; k < n; k += 1 {
			kept := ginger_partition_lanes(&a[k], &lows[nl], &highs[nh], pivot, call, KIND, FRONT, 1)
			nl += kept
			nh += 1 - kept
		}
	} else {
		for /**/; k < n; k += 1 {
			kept := ginger_partition_lanes(&a[k], &lows[nl], &highs[nh], pivot, call, KIND, FRONT, 1)
			nl += kept
			nh += 1 - kept

			if nl == b {
				copy(a[blocks*b:][:b], lows[:b])
				low_blocks[blocks>>6] |= 1 << uint(blocks&63)
				blocks += 1
				nl = 0
			} else if nh == b {
				copy(a[blocks*b:][:b], highs[:b])
				blocks += 1
				nh = 0
			}
		}
	}

	tail := blocks*b
	copy(a[tail:][:nl], lows[:nl])
	copy(a[tail+nl:], highs[:nh])

	ranks: [WORDS]int
	low_count := 0
	for i in 0..<(blocks+63)/64 {
		ranks[i] = low_count
		low_count += int(intrinsics.count_ones(low_blocks[i]))
	}

	destination :: #force_inline proc(i: int, low_blocks: []u64, ranks: []int, low_count: int) -> int {
		word  := low_blocks[i>>6]
		below := ranks[i>>6] + int(intrinsics.count_ones(word & (1 << uint(i&63) - 1)))
		return below if word & (1 << uint(i&63)) != 0 else low_count + i - below
	}

	placed: [WORDS]u64
	for start in 0..<blocks {
		if placed[start>>6] & (1 << uint(start&63)) != 0 {
			continue
		}
		placed[start>>6] |= 1 << uint(start&63)
		d := destination(start, low_blocks[:], ranks[:], low_count)
		if d == start {
			continue
		}

		carry, spare := lows, highs
		copy(carry, a[start*b:][:b])
		for d != start {
			placed[d>>6] |= 1 << uint(d&63)
			copy(spare, a[d*b:][:b])
			copy(a[d*b:][:b], carry)
			carry, spare = spare, carry
			d = destination(d, low_blocks[:], ranks[:], low_count)
		}
		copy(a[start*b:][:b], carry)
	}

	ginger_trinity_rotation(a[low_count*b:tail+nl], s, (blocks-low_count)*b)
	return low_count*b + nl
}

// An in-place MSD radix sort, the American flag sort of McIlroy, Bostic and McIlroy, "Engineering Radix Sort" (1993).
// It is unstable, but equal integers are the same bits: the result is exactly what a stable sort gives.
ginger_radix_sort :: proc(a, s: []$E, call: $P, $KIND: Sort_Kind) #no_bounds_check {
	// type_integer_to_unsigned takes neither unsigned types nor rune.
	when intrinsics.type_is_unsigned(E) {
		K :: E
	} else when intrinsics.type_is_rune(E) {
		K :: u32
	} else {
		K :: intrinsics.type_integer_to_unsigned(E)
	}
	// Sorting by `K(x) ~ FLIP` as unsigned: signed integers flip their sign bit, and reverse sorts every bit.
	SIGN :: K(0) when intrinsics.type_is_unsigned(E) else K(1) << (8*size_of(K) - 1)
	FLIP :: SIGN when KIND == .Ordered else ~SIGN

	digit :: #force_inline proc "contextless" (x: E, shift: uint) -> int {
		return int(((K(x) ~ FLIP) >> shift) & 0xFF)
	}

	n := len(a)
	if n <= GINGER_RADIX_SMALL {
		ginger_quadsort(a, s, call, KIND)
		return
	}

	// Sorting starts at the highest byte any two keys differ in. Bytes they all share sort nothing.
	differ := K(0)
	for x in a {
		differ |= K(x) ~ K(a[0])
	}
	if differ == 0 {
		return
	}
	shift := uint(8*size_of(K) - 1 - int(intrinsics.count_leading_zeros(differ))) &~ 7

	// Each bucket's count, until a prefix sum in place makes it the bucket's end.
	ends: [256]int
	for x in a {
		ends[digit(x, shift)] += 1
	}

	// On the last byte the keys share every other byte. Equal integers being the same bits, the counts say what goes where.
	if shift == 0 {
		prefix := (K(a[0]) ~ FLIP) &~ 0xFF
		i := 0
		for c, b in ends {
			fill(a[i:][:c], E((prefix | K(b)) ~ FLIP))
			i += c
		}
		return
	}

	// Summed in place, with the starts copied after. A loop storing to one stack array while loading from another
	// exactly 2 KB away stalls on Zen 4: whole sorts ran 3x slower.
	sum := 0
	for &end in ends {
		sum += end
		end = sum
	}
	nexts: [256]int
	copy(nexts[1:], ends[:255])

	// From a copy in the buffer the stores are independent. In place, each item goes straight to its bucket
	// and the item it displaces moves next, until the cycle closes: every step waits on the one before.
	if n <= len(s) {
		copy(s, a)
		for x in s[:n] {
			next := &nexts[digit(x, shift)]
			a[next^] = x
			next^ += 1
		}
	} else {
		for b in 0..<256 {
			for nexts[b] < ends[b] {
				x := a[nexts[b]]
				d := digit(x, shift)
				for d != b {
					next := &nexts[d]
					a[next^], x = x, a[next^]
					next^ += 1
					d = digit(x, shift)
				}
				a[nexts[b]] = x
				nexts[b] += 1
			}
		}
	}

	start := 0
	for end in ends {
		if end - start > 1 {
			ginger_radix_sort(a[start:end], s, call, KIND)
		}
		start = end
	}
}

ginger_partition :: proc(a, s: []$E, call: $P, $KIND: Sort_Kind) #no_bounds_check {
	n := len(a)

	pivot, previous_pivot: E
	has_previous := false

	for {
		if n <= 2048 {
			pivot = ginger_median_of_nine(a[:n], s, call, KIND)
		} else {
			all_equal: bool
			pivot, all_equal = ginger_median_of_cbrt(a[:n], s, call, KIND)
			if all_equal {
				ginger_quadsort(a[:n], s, call, KIND)
				return
			}
		}

		// Partitioning on .Less leaves only items equal to the pivot on the high side, which needs no sorting.
		equal_high := has_previous && !ginger_greater(previous_pivot, pivot, call, KIND)
		low_count := 0
		if !equal_high {
			low_count  = ginger_stable_partition(a[:n], s, pivot, call, KIND, .Not_Greater)
			equal_high = low_count == n
		}
		if equal_high {
			low_count = ginger_stable_partition(a[:n], s, pivot, call, KIND, .Less)
		}
		high_count := n - low_count

		if !equal_high {
			if low_count <= high_count/16 || high_count <= GINGER_OUT {
				ginger_quadsort(a[low_count:n], s, call, KIND)
			} else {
				ginger_partition(a[low_count:n], s, call, KIND)
			}
		}

		if high_count <= low_count/16 || low_count <= GINGER_OUT {
			ginger_quadsort(a[:low_count], s, call, KIND)
			return
		}
		n = low_count
		previous_pivot = pivot
		has_previous = !equal_high
	}
}

ginger_analyze :: proc(a, s: []$E, call: $P, $KIND: Sort_Kind) #no_bounds_check {
	// Integers in their own order take a radix sort where a partition would go. Single bytes need one
	// counting pass, which beats any use of the order already there.
	RADIX :: (KIND == .Ordered || KIND == .Ordered_Reverse) && intrinsics.type_is_integer(E) && intrinsics.type_is_endian_platform(E)
	when RADIX && size_of(E) == 1 {
		ginger_radix_sort(a, s, call, KIND)
		return
	}
	when RADIX {
		unordered :: ginger_radix_sort
	} else {
		unordered :: ginger_partition
	}

	n := len(a)

	half1 := n / 2
	half2 := n - half1
	quad1 := half1 / 2
	quad3 := half2 / 2

	bounds := [5]int{0, quad1, half1, half1+quad3, n}

	balance: [4]int
	streaks: [4]int

	i := 0
	count := n
	for /**/; count > 132; count -= 128 {
		sum: [4]int
		for _ in 0..<32 {
			// Unrolled with a quarter slice so LLVM carries q[i+1] into the next step's q[i].
			#unroll for k in 0..<4 {
				q := a[bounds[k]:]
				sum[k] += int(ginger_greater(q[i], q[i+1], call, KIND))
			}
			i += 1
		}

		any_streak := false
		for k in 0..<4 {
			balance[k] += sum[k]
			if sum[k] == 0 || sum[k] == 32 {
				streaks[k] += 1
				any_streak = true
			}
		}

		if count > 516 && !any_streak {
			for k in 0..<4 {
				balance[k] += 48
			}
			i += 96
			count -= 384
		}
	}

	for /**/; count > 7; count -= 4 {
		for k in 0..<4 {
			balance[k] += int(ginger_greater(a[bounds[k]+i], a[bounds[k]+i+1], call, KIND))
		}
		i += 1
	}

	for k in 1..<4 {
		if bounds[k+1]-bounds[k] > quad1 {
			balance[k] += int(ginger_greater(a[bounds[k]+i], a[bounds[k]+i+1], call, KIND))
		}
	}

	no_descents := balance == [4]int{}
	if no_descents &&
	   !ginger_greater(a[bounds[1]-1], a[bounds[1]], call, KIND) &&
	   !ginger_greater(a[bounds[2]-1], a[bounds[2]], call, KIND) &&
	   !ginger_greater(a[bounds[3]-1], a[bounds[3]], call, KIND) {
		return
	}

	reversed: [4]bool
	for k in 0..<4 {
		reversed[k] = bounds[k+1]-bounds[k]-balance[k] == 1
	}

	for k := 0; k < 4; /**/ {
		if !reversed[k] {
			k += 1
			continue
		}

		end := k + 1
		for end < 4 && reversed[end] && ginger_greater(a[bounds[end]-1], a[bounds[end]], call, KIND) {
			end += 1
		}

		ginger_reverse(a[bounds[k]:bounds[end]])
		if k == 0 && end == 4 {
			return
		}
		for j in k..<end {
			balance[j] = 0
		}
		k = end
	}

	ordered: [4]bool
	for k in 0..<4 {
		ordered[k] = streaks[k] > n/256
	}

	none_ordered := ordered == [4]bool{}
	if none_ordered {
		unordered(a, s, call, KIND)
		return
	}

	unordered_from := -1
	for k in 0..=4 {
		if k < 4 && !ordered[k] {
			if unordered_from < 0 {
				unordered_from = k
			}
			continue
		}

		if unordered_from >= 0 {
			unordered(a[bounds[unordered_from]:bounds[k]], s, call, KIND)
			unordered_from = -1
		}
		if k < 4 && balance[k] != 0 {
			ginger_quadsort(a[bounds[k]:bounds[k+1]], s, call, KIND)
		}
	}

	switch {
	case ginger_greater(a[quad1-1], a[quad1], call, KIND):
		ginger_rotate_merge_block(a[0:half1], s, quad1, half1-quad1, call, KIND)
		if ginger_greater(a[half1+quad3-1], a[half1+quad3], call, KIND) {
			ginger_rotate_merge_block(a[half1:n], s, quad3, half2-quad3, call, KIND)
		}

	case ginger_greater(a[half1+quad3-1], a[half1+quad3], call, KIND):
		ginger_rotate_merge_block(a[half1:n], s, quad3, half2-quad3, call, KIND)

	case !ginger_greater(a[half1-1], a[half1], call, KIND):
		return
	}

	ginger_rotate_merge_block(a, s, half1, half2, call, KIND)
}
