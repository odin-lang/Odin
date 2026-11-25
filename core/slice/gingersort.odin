#+private
package slice

import "base:builtin"
import "base:intrinsics"

// NOTE(bill, 2026-11-25): gingersort is the sort behind every procedure in this package.
// It is stable, sorts in place, and needs no allocator.
// Its only scratch space is a stack buffer of at most GINGER_SWAP_BYTES.
// Small inputs use a smaller local buffer instead, and large inputs of small elements a buffer of GINGER_LARGE items.
// With cheap comparisons, fewer than 8 items go straight to the sorting networks.
// Otherwise the smallest inputs are sorted by insertion, with a higher cut-off where moves cost more.
// Small inputs and small partitions are sorted with branchless sorting networks and parity merges, then merged through the buffer.
// Larger inputs are checked for quarters that are already ordered or reversed.
// The rest is partitioned stably around a sampled pivot, using rotations where a part does not fit the buffer.
// Elements too large for 32 of them to fit in the buffer are sorted in blocks of GINGER_BLOCK by insertion and merged with rotations.
// A comparator that is not a strict weak order still leaves a permutation of the input.
// `ginger_parity_merge` checks that its front and back cursors met, and copies its source over its output when they did not.
// `ginger_cross_merge` merges from both ends only while both runs have 16 items left.

ORD :: intrinsics.type_is_ordered

Sort_Kind :: enum {
	Ordered,
	Ordered_Reverse,
	Less,
	Less_Reverse,
	Less_With_Data,
	Cmp,
	Cmp_Reverse,
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

GINGER_SWAP_BYTES      :: 16 * 1024
GINGER_OUT             :: 96
GINGER_BLOCK           :: 16
GINGER_SMALL           :: 96
GINGER_LARGE           :: 1024
GINGER_SMALL_BYTES     :: 2048
GINGER_INSERTION_SMALL :: 8
GINGER_INSERTION_LARGE :: 32

gingersort :: proc(data: []$E, call: $P, $KIND: Sort_Kind) {
	when ODIN_OPTIMIZATION_MODE == .Size {
		ginger_sort_shared(data, call, KIND)
	} else {
		ginger_sort_typed(data, call, KIND)
	}
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

	when (KIND == .Ordered || KIND == .Ordered_Reverse) && !intrinsics.type_is_string(E) {
		if n < 8 {
			tiny: [7]E = ---
			ginger_tiny_sort(data, tiny[:], call, KIND)
			return
		}
	} else {
		when size_of(E) <= 8 {
			INSERTION_LIMIT :: GINGER_INSERTION_SMALL
		} else {
			INSERTION_LIMIT :: GINGER_INSERTION_LARGE
		}

		if n <= INSERTION_LIMIT {
			ginger_insertion_sort(data, call, KIND)
			return
		}
	}

	when size_of(E)*GINGER_SMALL <= GINGER_SMALL_BYTES {
		if n <= GINGER_SMALL {
			small: [GINGER_SMALL]E = ---
			ginger_quadsort(data, small[:], call, KIND)
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
	} else when KIND == .Less {
		return call(b, a)
	} else when KIND == .Less_Reverse {
		return call(a, b)
	} else when KIND == .Less_With_Data {
		return call.less(b, a, call.user_data)
	} else when KIND == .Cmp {
		return call(a, b) == .Greater
	} else when KIND == .Cmp_Reverse {
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
		if ginger_greater(from[ptl], from[ptr], call, KIND) {
			dest[ptd] = from[ptr]
			ptr += 1
		} else {
			dest[ptd] = from[ptl]
			ptl += 1
		}
		ptd += 1
	}

	if ginger_greater(from[ptl], from[ptr], call, KIND) {
		dest[ptd] = from[ptr]
		ptr += 1
	} else {
		dest[ptd] = from[ptl]
		ptl += 1
	}
	ptd += 1

	for _ in 1..<left {
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

	if ginger_greater(from[tpl], from[tpr], call, KIND) {
		dest[tpd] = from[tpl]
		tpl -= 1
	} else {
		dest[tpd] = from[tpr]
		tpr -= 1
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
	State :: enum u8 {
		Unordered,
		Ordered,
		Reversed,
	}

	n     := len(a)
	count := n / 8
	i     := 0
	pts   := 0
	state := State.Unordered

	reversed_to_end := false

	blocks: for {
		switch state {
		case .Unordered:
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
					state = .Ordered
					continue blocks
				}
				ginger_quad_swap_merge(a[i:i+8], s, call, KIND)
			} else if v1 && v2 && v3 && v4 &&
			          ginger_greater(a[i+1], a[i+2], call, KIND) &&
			          ginger_greater(a[i+3], a[i+4], call, KIND) &&
			          ginger_greater(a[i+5], a[i+6], call, KIND) {
				pts   = i
				state = .Reversed
				continue blocks
			} else {
				ginger_swap_if(a, i,   v1)
				ginger_swap_if(a, i+2, v2)
				ginger_swap_if(a, i+4, v3)
				ginger_swap_if(a, i+6, v4)
				ginger_quad_swap_merge(a[i:i+8], s, call, KIND)
			}
			i += 8

		case .Ordered:
			i += 8
			if count == 0 {
				break blocks
			}
			count -= 1

			v1 := ginger_greater(a[i],   a[i+1], call, KIND)
			v2 := ginger_greater(a[i+2], a[i+3], call, KIND)
			v3 := ginger_greater(a[i+4], a[i+5], call, KIND)
			v4 := ginger_greater(a[i+6], a[i+7], call, KIND)

			if v1 || v2 || v3 || v4 {
				if v1 && v2 && v3 && v4 &&
				   ginger_greater(a[i+1], a[i+2], call, KIND) &&
				   ginger_greater(a[i+3], a[i+4], call, KIND) &&
				   ginger_greater(a[i+5], a[i+6], call, KIND) {
					pts   = i
					state = .Reversed
					continue blocks
				}
				ginger_swap_if(a, i,   v1)
				ginger_swap_if(a, i+2, v2)
				ginger_swap_if(a, i+4, v3)
				ginger_swap_if(a, i+6, v4)
				ginger_quad_swap_merge(a[i:i+8], s, call, KIND)
				i += 8
				state = .Unordered
				continue blocks
			}

			if !ginger_greater(a[i+1], a[i+2], call, KIND) &&
			   !ginger_greater(a[i+3], a[i+4], call, KIND) &&
			   !ginger_greater(a[i+5], a[i+6], call, KIND) {
				continue blocks
			}
			ginger_quad_swap_merge(a[i:i+8], s, call, KIND)
			i += 8
			state = .Unordered

		case .Reversed:
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
					reverse(a[pts:i+rest])
					if pts == 0 {
						return true
					}
					reversed_to_end = true
					break blocks
				}
				reverse(a[pts:i])
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
			reverse(a[pts:i])

			if o1 && o2 && o3 && o4 &&
			   !ginger_greater(a[i+1], a[i+2], call, KIND) &&
			   !ginger_greater(a[i+3], a[i+4], call, KIND) &&
			   !ginger_greater(a[i+5], a[i+6], call, KIND) {
				state = .Ordered
				continue blocks
			}

			if !(o1 || o2 || o3 || o4) &&
			   ginger_greater(a[i+1], a[i+2], call, KIND) &&
			   ginger_greater(a[i+3], a[i+4], call, KIND) &&
			   ginger_greater(a[i+5], a[i+6], call, KIND) {
				pts = i
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
			state = .Unordered
		}
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

	for ptl <= tpl {
		dest[ptd] = from[ptl]
		ptl += 1
		ptd += 1
	}

	for ptr <= tpr {
		dest[ptd] = from[ptr]
		ptr += 1
		ptd += 1
	}
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

	for ptl <= tpl {
		a[out] = s[ptl]
		ptl += 1
		out += 1
	}
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
			if !ginger_greater(a[tpl], s[tpr-1], call, KIND) {
				a[tpa]   = s[tpr]
				a[tpa-1] = s[tpr-1]
				tpa -= 2
				tpr -= 2
			} else if ginger_greater(a[tpl-1], s[tpr], call, KIND) {
				a[tpa]   = a[tpl]
				a[tpa-1] = a[tpl-1]
				tpa -= 2
				tpl -= 2
			} else {
				right_after := !ginger_greater(a[tpl], s[tpr], call, KIND)
				right_item  := s[tpr]
				left_item   := a[tpl]
				tpa -= 1
				a[tpa+int(right_after)]  = right_item
				a[tpa+int(!right_after)] = left_item
				tpr -= 1
				tpl -= 1
				tpa -= 1

				if ginger_greater(a[tpl], s[tpr], call, KIND) {
					a[tpa] = a[tpl]
					tpl -= 1
				} else {
					a[tpa] = s[tpr]
					tpr -= 1
				}
				tpa -= 1
			}
		}
	}

	for tpr > 1 && tpl > 1 {
		if !ginger_greater(a[tpl], s[tpr-1], call, KIND) {
			a[tpa]   = s[tpr]
			a[tpa-1] = s[tpr-1]
			tpa -= 2
			tpr -= 2
			continue
		}

		if ginger_greater(a[tpl-1], s[tpr], call, KIND) {
			a[tpa]   = a[tpl]
			a[tpa-1] = a[tpl-1]
			tpa -= 2
			tpl -= 2
			continue
		}

		right_after := !ginger_greater(a[tpl], s[tpr], call, KIND)
		right_item  := s[tpr]
		left_item   := a[tpl]
		tpa -= 1
		a[tpa+int(right_after)]  = right_item
		a[tpa+int(!right_after)] = left_item
		tpr -= 1
		tpl -= 1
		tpa -= 1

		if ginger_greater(a[tpl], s[tpr], call, KIND) {
			a[tpa] = a[tpl]
			tpl -= 1
		} else {
			a[tpa] = s[tpr]
			tpr -= 1
		}
		tpa -= 1
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

	for tpr >= 0 {
		a[tpa] = s[tpr]
		tpa -= 1
		tpr -= 1
	}
}

ginger_tail_merge :: proc(a, s: []$E, start_block: int, call: $P, $KIND: Sort_Kind) #no_bounds_check {
	n     := len(a)
	block := start_block

	for block < n && block <= len(s) {
		for pta := 0; pta+block < n; pta += block*2 {
			if pta+block*2 < n {
				ginger_partial_backward_merge(a[pta:pta+block*2], s, block, call, KIND)
				continue
			}

			ginger_partial_backward_merge(a[pta:n], s, block, call, KIND)
			break
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

		for count := (ptd - pta) / 2; count > 0; count -= 1 {
			temp := a[pta]
			ptd -= 1
			a[pta] = a[ptd]
			pta += 1
			a[ptd] = temp
		}

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

		for count := (ptd - pta) / 2; count > 0; count -= 1 {
			temp := a[pta]
			ptd -= 1
			a[pta] = a[ptd]
			pta += 1
			a[ptd] = temp
		}

	case:
		for k in 0..<left {
			a[k], a[left+k] = a[left+k], a[k]
		}
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
			if pta+block*2 < n {
				ginger_rotate_merge_block(a[pta:pta+block*2], s, block, block, call, KIND)
				continue
			}

			ginger_rotate_merge_block(a[pta:n], s, block, n-pta-block, call, KIND)
			break
		}
		block *= 2
	}
}

ginger_quadsort :: proc(a, s: []$E, call: $P, $KIND: Sort_Kind) #no_bounds_check {
	if len(a) <= 96 && len(a) <= len(s) {
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

// Moves the items not greater than `pivot` to the front, keeping their order and that of the rest.
@(require_results)
ginger_default_partition :: proc(a, s: []$E, pivot: E, call: $P, $KIND: Sort_Kind) -> (count: int) #no_bounds_check {
	n := len(a)
	if n > len(s) {
		half  := n / 2
		left  := ginger_default_partition(a[:half], s, pivot, call, KIND)
		right := ginger_default_partition(a[half:], s, pivot, call, KIND)
		ginger_trinity_rotation(a[left:half+right], s, half-left)
		return left + right
	}

	for k in 0..<n {
		item := a[k]
		keep := !ginger_greater(item, pivot, call, KIND)
		a[count]   = item
		s[k-count] = item
		count += int(keep)
	}
	copy(a[count:n], s[:n-count])
	return
}

// Moves the items less than `pivot` to the front, keeping their order and that of the rest.
@(require_results)
ginger_reverse_partition :: proc(a, s: []$E, pivot: E, call: $P, $KIND: Sort_Kind) -> (count: int) #no_bounds_check {
	n := len(a)
	if n > len(s) {
		half  := n / 2
		left  := ginger_reverse_partition(a[:half], s, pivot, call, KIND)
		right := ginger_reverse_partition(a[half:], s, pivot, call, KIND)
		ginger_trinity_rotation(a[left:half+right], s, half-left)
		return left + right
	}

	for k in 0..<n {
		item := a[k]
		keep := ginger_greater(pivot, item, call, KIND)
		a[count]   = item
		s[k-count] = item
		count += int(keep)
	}
	copy(a[count:n], s[:n-count])
	return
}

ginger_partition :: proc(a, s: []$E, call: $P, $KIND: Sort_Kind) #no_bounds_check {
	n := len(a)

	low_count  := 0
	high_count := 0

	pivot, previous_pivot: E

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

		if low_count != 0 && !ginger_greater(previous_pivot, pivot, call, KIND) {
			low_count  = ginger_reverse_partition(a[:n], s, pivot, call, KIND)
			high_count = n - low_count

			if high_count <= low_count/16 || low_count <= GINGER_OUT {
				ginger_quadsort(a[:low_count], s, call, KIND)
				return
			}
			n = low_count
			low_count = 0
			continue
		}

		low_count  = ginger_default_partition(a[:n], s, pivot, call, KIND)
		high_count = n - low_count

		if low_count <= high_count/16 || high_count <= GINGER_OUT {
			if high_count == 0 {
				low_count  = ginger_reverse_partition(a[:low_count], s, pivot, call, KIND)
				high_count = n - low_count

				if high_count <= low_count/16 || low_count <= GINGER_OUT {
					ginger_quadsort(a[:low_count], s, call, KIND)
					return
				}
				n = low_count
				low_count = 0
				continue
			}
			ginger_quadsort(a[low_count:n], s, call, KIND)
		} else {
			ginger_partition(a[low_count:n], s, call, KIND)
		}

		if high_count <= low_count/16 || low_count <= GINGER_OUT {
			ginger_quadsort(a[:low_count], s, call, KIND)
			return
		}
		n = low_count
		previous_pivot = pivot
	}
}

ginger_analyze :: proc(a, s: []$E, call: $P, $KIND: Sort_Kind) #no_bounds_check {
	n := len(a)

	half1 := n / 2
	quad1 := half1 / 2
	quad2 := half1 - quad1
	half2 := n - half1
	quad3 := half2 / 2
	quad4 := half2 - quad3

	pta := 0
	ptb := quad1
	ptc := half1
	ptd := half1 + quad3

	astreaks := 0
	bstreaks := 0
	cstreaks := 0
	dstreaks := 0

	abalance := 0
	bbalance := 0
	cbalance := 0
	dbalance := 0

	count := n
	for /**/; count > 132; count -= 128 {
		asum := 0
		bsum := 0
		csum := 0
		dsum := 0

		for _ in 0..<32 {
			asum += int(ginger_greater(a[pta], a[pta+1], call, KIND))
			bsum += int(ginger_greater(a[ptb], a[ptb+1], call, KIND))
			csum += int(ginger_greater(a[ptc], a[ptc+1], call, KIND))
			dsum += int(ginger_greater(a[ptd], a[ptd+1], call, KIND))
			pta += 1
			ptb += 1
			ptc += 1
			ptd += 1
		}

		abalance += asum
		bbalance += bsum
		cbalance += csum
		dbalance += dsum

		astreak := asum == 0 || asum == 32
		bstreak := bsum == 0 || bsum == 32
		cstreak := csum == 0 || csum == 32
		dstreak := dsum == 0 || dsum == 32

		astreaks += int(astreak)
		bstreaks += int(bstreak)
		cstreaks += int(cstreak)
		dstreaks += int(dstreak)

		if count > 516 && !(astreak || bstreak || cstreak || dstreak) {
			abalance += 48
			bbalance += 48
			cbalance += 48
			dbalance += 48
			pta += 96
			ptb += 96
			ptc += 96
			ptd += 96
			count -= 384
		}
	}

	for /**/; count > 7; count -= 4 {
		abalance += int(ginger_greater(a[pta], a[pta+1], call, KIND))
		bbalance += int(ginger_greater(a[ptb], a[ptb+1], call, KIND))
		cbalance += int(ginger_greater(a[ptc], a[ptc+1], call, KIND))
		dbalance += int(ginger_greater(a[ptd], a[ptd+1], call, KIND))
		pta += 1
		ptb += 1
		ptc += 1
		ptd += 1
	}

	if quad1 < quad2 {
		bbalance += int(ginger_greater(a[ptb], a[ptb+1], call, KIND))
		ptb += 1
	}

	if quad1 < quad3 {
		cbalance += int(ginger_greater(a[ptc], a[ptc+1], call, KIND))
		ptc += 1
	}

	if quad1 < quad4 {
		dbalance += int(ginger_greater(a[ptd], a[ptd+1], call, KIND))
		ptd += 1
	}

	if abalance+bbalance+cbalance+dbalance == 0 {
		if !ginger_greater(a[pta], a[pta+1], call, KIND) &&
		   !ginger_greater(a[ptb], a[ptb+1], call, KIND) &&
		   !ginger_greater(a[ptc], a[ptc+1], call, KIND) {
			return
		}
	}

	areversed := quad1-abalance == 1
	breversed := quad2-bbalance == 1
	creversed := quad3-cbalance == 1
	dreversed := quad4-dbalance == 1

	if areversed || breversed || creversed || dreversed {
		span1 := areversed && breversed && ginger_greater(a[pta], a[pta+1], call, KIND)
		span2 := breversed && creversed && ginger_greater(a[ptb], a[ptb+1], call, KIND)
		span3 := creversed && dreversed && ginger_greater(a[ptc], a[ptc+1], call, KIND)

		switch int(span1) | int(span2)*2 | int(span3)*4 {
		case 0:
		case 1:
			reverse(a[0:ptb+1])
			abalance = 0
			bbalance = 0
		case 2:
			reverse(a[pta+1:ptc+1])
			bbalance = 0
			cbalance = 0
		case 3:
			reverse(a[0:ptc+1])
			abalance = 0
			bbalance = 0
			cbalance = 0
		case 4:
			reverse(a[ptb+1:ptd+1])
			cbalance = 0
			dbalance = 0
		case 5:
			reverse(a[0:ptb+1])
			reverse(a[ptb+1:ptd+1])
			abalance = 0
			bbalance = 0
			cbalance = 0
			dbalance = 0
		case 6:
			reverse(a[pta+1:ptd+1])
			bbalance = 0
			cbalance = 0
			dbalance = 0
		case 7:
			reverse(a[0:ptd+1])
			return
		}

		if areversed && abalance != 0 {
			reverse(a[0:pta+1])
			abalance = 0
		}

		if breversed && bbalance != 0 {
			reverse(a[pta+1:ptb+1])
			bbalance = 0
		}

		if creversed && cbalance != 0 {
			reverse(a[ptb+1:ptc+1])
			cbalance = 0
		}

		if dreversed && dbalance != 0 {
			reverse(a[ptc+1:ptd+1])
			dbalance = 0
		}
	}

	limit := n / 256
	aordered := astreaks > limit
	bordered := bstreaks > limit
	cordered := cstreaks > limit
	dordered := dstreaks > limit

	quarter_a := a[0:quad1]
	quarter_b := a[pta+1:pta+1+quad2]
	quarter_c := a[ptb+1:ptb+1+quad3]
	quarter_d := a[ptc+1:ptc+1+quad4]

	switch int(aordered) | int(bordered)*2 | int(cordered)*4 | int(dordered)*8 {
	case 0:
		ginger_partition(a, s, call, KIND)
		return

	case 1:
		if abalance != 0 {
			ginger_quadsort(quarter_a, s, call, KIND)
		}
		ginger_partition(a[pta+1:pta+1+quad2+half2], s, call, KIND)

	case 2:
		ginger_partition(quarter_a, s, call, KIND)
		if bbalance != 0 {
			ginger_quadsort(quarter_b, s, call, KIND)
		}
		ginger_partition(a[ptb+1:ptb+1+half2], s, call, KIND)

	case 3:
		if abalance != 0 {
			ginger_quadsort(quarter_a, s, call, KIND)
		}
		if bbalance != 0 {
			ginger_quadsort(quarter_b, s, call, KIND)
		}
		ginger_partition(a[ptb+1:ptb+1+half2], s, call, KIND)

	case 4:
		ginger_partition(a[0:half1], s, call, KIND)
		if cbalance != 0 {
			ginger_quadsort(quarter_c, s, call, KIND)
		}
		ginger_partition(quarter_d, s, call, KIND)

	case 8:
		ginger_partition(a[0:half1+quad3], s, call, KIND)
		if dbalance != 0 {
			ginger_quadsort(quarter_d, s, call, KIND)
		}

	case 9:
		if abalance != 0 {
			ginger_quadsort(quarter_a, s, call, KIND)
		}
		ginger_partition(a[pta+1:pta+1+quad2+quad3], s, call, KIND)
		if dbalance != 0 {
			ginger_quadsort(quarter_d, s, call, KIND)
		}

	case 12:
		ginger_partition(a[0:half1], s, call, KIND)
		if cbalance != 0 {
			ginger_quadsort(quarter_c, s, call, KIND)
		}
		if dbalance != 0 {
			ginger_quadsort(quarter_d, s, call, KIND)
		}

	case:
		switch {
		case !aordered:     ginger_partition(quarter_a, s, call, KIND)
		case abalance != 0: ginger_quadsort (quarter_a, s, call, KIND)
		}
		switch {
		case !bordered:     ginger_partition(quarter_b, s, call, KIND)
		case bbalance != 0: ginger_quadsort (quarter_b, s, call, KIND)
		}
		switch {
		case !cordered:     ginger_partition(quarter_c, s, call, KIND)
		case cbalance != 0: ginger_quadsort (quarter_c, s, call, KIND)
		}
		switch {
		case !dordered:     ginger_partition(quarter_d, s, call, KIND)
		case dbalance != 0: ginger_quadsort (quarter_d, s, call, KIND)
		}
	}

	switch {
	case ginger_greater(a[pta], a[pta+1], call, KIND):
		ginger_rotate_merge_block(a[0:half1], s, quad1, quad2, call, KIND)
		if ginger_greater(a[ptc], a[ptc+1], call, KIND) {
			ginger_rotate_merge_block(a[half1:n], s, quad3, quad4, call, KIND)
		}

	case ginger_greater(a[ptc], a[ptc+1], call, KIND):
		ginger_rotate_merge_block(a[half1:n], s, quad3, quad4, call, KIND)

	case !ginger_greater(a[ptb], a[ptb+1], call, KIND):
		return
	}

	ginger_rotate_merge_block(a, s, half1, half2, call, KIND)
}
