#+private
package slice

import "base:builtin"
import "base:intrinsics"

/*
	NOTE(bill, 2026-11-25): hodgepodge sort is the sort behind every procedure in this package.
	It is stable, sorts in place, and needs no allocator: its only scratch space is a stack buffer of at most HODGEPODGE_SWAP_BYTES.
	A comparator that is not a strict weak order still leaves a permutation of the input.

	No one algorithm is fastest on every input, and this sort is a hodgepodge of them, hence its name:
	a cheap look at the input chooses, part by part, the technique that suits it.
	Comparisons are cheap for numbers in their own order and for comparators known at compile time.
	Where each comparison is a call instead, the sort does more of its other work to make fewer of them.

	## Small arrays
	Fewer than 8 items with cheap comparisons take sorting networks, and other small arrays take insertion sort.
	Up to HODGEPODGE_SMALL items, quad swaps and parity merges sort through a small stack buffer
	(hodgepodge_tiny_sort, hodgepodge_tail_swap), from quadsort [1].

	## Merges
	Through the buffer, a branchless merge fills the output from both ends at once (hodgepodge_cross_merge), from quadsort [1].
	Merges longer than the buffer split by a monobound binary search and rotations
	(hodgepodge_rank, hodgepodge_rotate_merge_block, hodgepodge_trinity_rotation), after blitsort [2].
	Where both sides are long and interleave, blocks of half the buffer are put in order and merged locally instead
	(hodgepodge_block_merge), after the block merge of Huang and Langston [3].

	## Reading the input
	Descents counted in four quarters choose the route (hodgepodge_analyse), after fluxsort [4] and blitsort [2].
	Sorted and reversed quarters cost one pass.
	With cheap comparisons, quarters with order in them take the merges above.
	Otherwise they merge their natural runs in the order of Powersort [5], with the lazy unsorted runs of Glidesort [6].
	Input sorted apart from items scattered through every quarter takes drop-merge sort [7] (hodgepodge_drop_merge).
	Where more items are out of place than a few buffers hold, they gather in blocks in the array instead
	(hodgepodge_drop_split), and sort on their own before merging back in.

	## Input without order
	A stable partition around a pivot sampled from about the cube root of n items (hodgepodge_partition), after fluxsort [4].
	A range within the buffer partitions through it, and a longer one halves and rotates, after blitsort [2].
	A much longer one collects each side in blocks that are then put in order, like the block distribution of IPS4o [8].
	Where a byte shuffle is one instruction, f32 keys move four lanes at a time with a shuffle table, after Gueron and Krasnov [9].
	Integers in their own order take an in-place radix sort instead (hodgepodge_radix_sort): the American flag sort [10].
	Where unsigned 32-bit min and max are one instruction, its small buckets of 4-byte integers sort with a bitonic
	network in SIMD registers (hodgepodge_radix_network), after Batcher [11].

	## Large elements and code size
	Elements of HODGEPODGE_HEAVY_BYTES or more take the block merge wherever it can run: rotations copy them too often.
	Elements over HODGEPODGE_HUGE_BYTES, where fewer than 32 fit the buffer, cost more to move than to compare.
	Insertion in blocks of HODGEPODGE_BLOCK and merges stand in for the partition and quad swaps, which need more buffer
	(hodgepodge_large_element_sort).
	Drop-merge leaves their set-aside items in place and notes their offsets in the buffer (hodgepodge_drop_notes),
	and each segment then sorts by one permutation.
	Where few items cross, a merge swaps those over and merges them in by one permutation too (hodgepodge_sparse_merge).
	Either way every item moves at most once, along the permutation's cycles, fetched ahead (hodgepodge_follow_cycles).
	At -o:size, element types of one size and alignment share one body (Sort_Shared_Item).

	## Stability
	For a comparator that is a strict weak order, equal items keep their input order.
	No step moves an item past an equal one, and runs only merge with their neighbours.
	Swaps exchange neighbours only when the first is greater, and insertion stops at the first item not greater.
	Merges take the left side's item on a tie from either end, and the block merge orders its blocks the same way.
	A split for a rotation keeps the right side's equal items behind the left side's.
	Rotations keep the order within each part, and reversals only turn strictly descending runs.
	Partitions, the SIMD lanes among them, keep both sides in input order, and equal items land on the same side.
	Drop-merge sets aside two kinds of item, each in input order, in the buffer or in blocks: spikes go in front of
	equal items, the others behind.
	A kept item equal to a spike always comes after it, and one equal to any other set-aside item always before it.
	Noted set-aside items sort in the order of their notes, which is their input order, before they rank by those rules.
	The sparse merge's split is the stable merge's, and the items it swaps over merge in on the side they came from:
	the left side's in front of equal items, the right side's behind.
	A permutation keeps the order its ranks give.
	The radix sort and its network only take integers in their own order, where equal keys are the same bits.

	Four bounds hold by construction.
	A Powersort power is the leading-zero count of a non-zero 64-bit word, and the stack's powers strictly increase [5]:
	64 entries hold any stack.
	The block merge and drop-merge's split only run where they have at most HODGEPODGE_BLOCKS blocks, and their bit
	sets hold that many.
	Positions scaled by n, in the samples and Powersort's midpoints, are computed in 64 and 128 bits:
	a 32-bit int would wrap past about 8 million items.
	A drop-merge segment ends before its offsets reach HODGEPODGE_NOTE_SPAN, and the sparse merge only runs below 2^31
	items: their top bits stay free for marks.

	## Provenance
	The code that came from blitsort [2], with its parts of quadsort [1] and fluxsort [4], is in the public domain under
	the Unlicense. The other sources gave ideas only: no code was taken from them.

	## Sources
	[1]  Igor van den Hoven, quadsort (2020): https://github.com/scandum/quadsort
	[2]  Igor van den Hoven, blitsort (2021): https://github.com/scandum/blitsort
	[3]  Bing-Chao Huang and Michael A. Langston, "Practical In-Place Merging", Communications of the ACM 31(3), 1988:
	     https://doi.org/10.1145/42392.42403
	[4]  Igor van den Hoven, fluxsort (2021): https://github.com/scandum/fluxsort
	[5]  J. Ian Munro and Sebastian Wild, "Nearly-Optimal Mergesorts: Fast, Practical Sorting Methods That Optimally Adapt
	     to Existing Runs", ESA 2018: https://arxiv.org/abs/1805.04154
	[6]  Orson Peters, Glidesort (2023): https://github.com/orlp/glidesort
	[7]  Emil Ernerfeldt, drop-merge sort (2016): https://github.com/emilk/drop-merge-sort
	[8]  Michael Axtmann, Sascha Witt, Daniel Ferizovic, and Peter Sanders, "In-place Parallel Super Scalar Samplesort
	     (IPS4o)", ESA 2017: https://arxiv.org/abs/1705.02257
	[9]  Shay Gueron and Vlad Krasnov, "Fast Quicksort Implementation Using AVX Instructions", The Computer Journal 59(1),
	     2016: https://doi.org/10.1093/comjnl/bxv063
	[10] Peter M. McIlroy, Keith Bostic, and M. Douglas McIlroy, "Engineering Radix Sort", Computing Systems 6(1), 1993:
	     https://www.usenix.org/legacy/publications/compsystems/1993/win_mcilroy.pdf
	[11] K. E. Batcher, "Sorting Networks and Their Applications", AFIPS Spring Joint Computer Conference, 1968:
	     https://doi.org/10.1145/1468075.1468121
*/

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

// The kinds that compare the items themselves with `<` and `>`, and the kinds whose comparator is known at compile time.
HODGEPODGE_ORDERED_KINDS  :: bit_set[Sort_Kind]{.Ordered, .Ordered_Reverse}
HODGEPODGE_CONSTANT_KINDS :: bit_set[Sort_Kind]{.Less_Constant, .Less_Reverse_Constant, .Cmp_Constant, .Cmp_Reverse_Constant}

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

HODGEPODGE_SWAP_BYTES       :: 16 * 1024
HODGEPODGE_OUT              :: 96
HODGEPODGE_BLOCK            :: 16
HODGEPODGE_SMALL            :: 96
HODGEPODGE_LARGE            :: 1024
HODGEPODGE_SMALL_BYTES      :: 2048
HODGEPODGE_INSERTION_SMALL  :: 8
HODGEPODGE_INSERTION_LARGE  :: 32
HODGEPODGE_INSERTION_HUGE   :: 64
HODGEPODGE_NETWORK_BYTES    :: 16
HODGEPODGE_BLOCKS           :: 4096
HODGEPODGE_PARTITION_HALVES :: 4
HODGEPODGE_MERGE_STEP       :: 32
HODGEPODGE_MERGE_CARRIED    :: 2
HODGEPODGE_RADIX_SMALL      :: 64
HODGEPODGE_RADIX_NETWORK    :: 9
HODGEPODGE_RUN_MIN          :: 32
HODGEPODGE_DROP_DESCENTS    :: 32
HODGEPODGE_RADIX_DESCENTS   :: 16
HODGEPODGE_DROP_NEW_RUN     :: 16
HODGEPODGE_DROP_ASCENT      :: 8
HODGEPODGE_DROP_SPIKES      :: 4
HODGEPODGE_DROP_EARLY       :: 8
HODGEPODGE_DROP_STREAK      :: 4
HODGEPODGE_DROP_SEGMENTS    :: 8
HODGEPODGE_SPLIT_DESCENTS   :: 96
HODGEPODGE_SPLIT_RADIX      :: 32
HODGEPODGE_FAR_DESCENTS     :: 48
HODGEPODGE_FAR_FROM         :: 8192
HODGEPODGE_RADIX_FEW        :: 4
HODGEPODGE_RADIX_FEW_LANES  :: 32
HODGEPODGE_RADIX_FEW_BYTES  :: 1 << 20
HODGEPODGE_HEAVY_BYTES      :: 128
HODGEPODGE_HUGE_BYTES       :: HODGEPODGE_SWAP_BYTES / 32
HODGEPODGE_SPARSE           :: 16
HODGEPODGE_AHEAD            :: 8
HODGEPODGE_NOTE_MARK        :: u16(1) << 15
HODGEPODGE_NOTE_SPAN        :: int(HODGEPODGE_NOTE_MARK) - 1
HODGEPODGE_RANK_MARK        :: u32(1) << 31

hodgepodge_sort :: proc(data: []$E, call: $P, $KIND: Sort_Kind) {
	when size_of(E) == 0 {
		return
	} else when ODIN_OPTIMIZATION_MODE == .Size {
		hodgepodge_sort_shared(data, call, KIND)
	} else {
		hodgepodge_sort_typed(data, call, KIND)
	}
}

@(require_results)
hodgepodge_is_sorted :: proc(a: []$E, call: $P, $KIND: Sort_Kind) -> bool {
	for i := len(a)-1; i > 0; i -= 1 {
		if hodgepodge_greater(a[i-1], a[i], call, KIND) {
			return false
		}
	}
	return true
}

// Fills `indices` with the order that sorts `data`, then permutes `data` into it.
hodgepodge_sort_indices :: proc(data: []$E, indices: []int, call: $P, $KIND: Sort_Kind) {
	for &index, i in indices {
		index = i
	}
	hodgepodge_sort(indices, call, KIND)
	sort_from_permutation_indices(data, indices)
}

hodgepodge_sort_shared :: proc(data: []$E, call: $P, $KIND: Sort_Kind) {
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
		hodgepodge_sort_typed(data, call, KIND)
	} else {
		Item :: Sort_Shared_Item(size_of(E)/size_of(W), W)
		#assert(size_of(Item) == size_of(E) && align_of(Item) == align_of(E))

		greater :: proc(a, b: Item, call: rawptr) -> bool {
			return hodgepodge_greater(transmute(E)a, transmute(E)b, (^P)(call)^, KIND)
		}

		call := call
		hodgepodge_sort_typed(transmute([]Item)data, Sort_Shared_Call(Item){greater, &call}, .Shared)
	}
}

hodgepodge_sort_typed :: proc(data: []$E, call: $P, $KIND: Sort_Kind) #no_bounds_check {
	n := len(data)
	if n < 2 {
		return
	}

	ORDERED  :: KIND in HODGEPODGE_ORDERED_KINDS && !intrinsics.type_is_string(E)
	CONSTANT :: KIND in HODGEPODGE_CONSTANT_KINDS

	when ORDERED || CONSTANT && size_of(E) <= HODGEPODGE_NETWORK_BYTES {
		if n < 8 {
			tiny: [7]E = ---
			hodgepodge_tiny_sort(data, tiny[:], call, KIND)
			return
		}
	} else {
		when CONSTANT {
			INSERTION_LIMIT :: HODGEPODGE_INSERTION_LARGE
		} else when size_of(E) <= 8 {
			INSERTION_LIMIT :: HODGEPODGE_INSERTION_SMALL
		} else when size_of(E) <= 32 {
			INSERTION_LIMIT :: HODGEPODGE_INSERTION_LARGE
		} else {
			INSERTION_LIMIT :: HODGEPODGE_INSERTION_HUGE
		}

		if n <= INSERTION_LIMIT {
			hodgepodge_insertion_sort(data, call, KIND)
			return
		}
	}

	when size_of(E)*HODGEPODGE_SMALL <= HODGEPODGE_SMALL_BYTES {
		if n <= HODGEPODGE_SMALL {
			small: [HODGEPODGE_SMALL]E = ---
			hodgepodge_tail_swap(data, small[:], call, KIND)
			return
		}
	}
	when size_of(E)*HODGEPODGE_LARGE <= HODGEPODGE_SWAP_BYTES {
		if n > HODGEPODGE_LARGE {
			hodgepodge_large_buffered_sort(data, call, KIND)
			return
		}
	}
	hodgepodge_buffered_sort(data, call, KIND)
}

hodgepodge_large_buffered_sort :: #force_no_inline proc(data: []$E, call: $P, $KIND: Sort_Kind) #no_bounds_check {
	swap: [HODGEPODGE_LARGE]E = ---
	hodgepodge_analyse(data, swap[:], call, KIND)
}

hodgepodge_buffered_sort :: #force_no_inline proc(data: []$E, call: $P, $KIND: Sort_Kind) #no_bounds_check {
	// A power of two from 32 to 512 items, or as many as fit.
	when size_of(E)*32 <= HODGEPODGE_SWAP_BYTES {
		SWAP_LEN :: builtin.min(512, 1 << intrinsics.constant_log2(HODGEPODGE_SWAP_BYTES/size_of(E)))
	} else {
		SWAP_LEN :: builtin.max(HODGEPODGE_SWAP_BYTES/size_of(E), 1)
	}

	swap: [SWAP_LEN]E = ---
	// One item leaves no room for drop-merge's notes or a merge's ranks.
	when SWAP_LEN < 2 {
		hodgepodge_large_element_sort(data, swap[:], call, KIND)
	} else {
		if len(data) <= 132 {
			hodgepodge_quadsort(data, swap[:], call, KIND)
		} else {
			hodgepodge_analyse(data, swap[:], call, KIND)
		}
	}
}

hodgepodge_insertion_sort :: proc(a: []$E, call: $P, $KIND: Sort_Kind) #no_bounds_check {
	for i in 1..<len(a) {
		item := a[i]
		j := i
		for j > 0 && hodgepodge_greater(a[j-1], item, call, KIND) {
			a[j] = a[j-1]
			j -= 1
		}
		a[j] = item
	}
}

hodgepodge_large_element_sort :: proc(a, s: []$E, call: $P, $KIND: Sort_Kind) #no_bounds_check {
	n := len(a)
	for lo := 0; lo < n; lo += HODGEPODGE_BLOCK {
		hodgepodge_insertion_sort(a[lo:builtin.min(lo+HODGEPODGE_BLOCK, n)], call, KIND)
	}

	if n > HODGEPODGE_BLOCK {
		hodgepodge_rotate_merge(a, s, HODGEPODGE_BLOCK, call, KIND)
	}
}

@(require_results)
hodgepodge_greater :: #force_inline proc(a, b: $E, call: $P, $KIND: Sort_Kind) -> bool #no_bounds_check {
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

hodgepodge_swap_if :: #force_inline proc(a: []$E, i: int, swap: bool) #no_bounds_check {
	lo := a[i+1] if swap else a[i]
	hi := a[i]   if swap else a[i+1]
	a[i]   = lo
	a[i+1] = hi
}

hodgepodge_order_pair :: #force_inline proc(a: []$E, i: int, call: $P, $KIND: Sort_Kind) #no_bounds_check {
	hodgepodge_swap_if(a, i, hodgepodge_greater(a[i], a[i+1], call, KIND))
}

hodgepodge_reverse :: proc(a: []$E) #no_bounds_check {
	for i, j := 0, len(a)-1; i < j; i, j = i+1, j-1 {
		temp := a[i]
		a[i] = a[j]
		a[j] = temp
	}
}

hodgepodge_parity_swap_four :: #force_inline proc(a: []$E, call: $P, $KIND: Sort_Kind) #no_bounds_check {
	hodgepodge_order_pair(a, 0, call, KIND)
	hodgepodge_order_pair(a, 2, call, KIND)

	if hodgepodge_greater(a[1], a[2], call, KIND) {
		a[1], a[2] = a[2], a[1]

		hodgepodge_order_pair(a, 0, call, KIND)
		hodgepodge_order_pair(a, 2, call, KIND)
		hodgepodge_order_pair(a, 1, call, KIND)
	}
}

hodgepodge_parity_swap_five :: #force_inline proc(a: []$E, call: $P, $KIND: Sort_Kind) #no_bounds_check {
	hodgepodge_order_pair(a, 0, call, KIND)
	hodgepodge_order_pair(a, 2, call, KIND)

	x := hodgepodge_greater(a[1], a[2], call, KIND)
	hodgepodge_swap_if(a, 1, x)

	y := hodgepodge_greater(a[3], a[4], call, KIND)
	hodgepodge_swap_if(a, 3, y)

	if x || y {
		hodgepodge_order_pair(a, 0, call, KIND)
		hodgepodge_order_pair(a, 2, call, KIND)
		hodgepodge_order_pair(a, 1, call, KIND)
		hodgepodge_order_pair(a, 3, call, KIND)
		hodgepodge_order_pair(a, 0, call, KIND)
		hodgepodge_order_pair(a, 2, call, KIND)
	}
}

hodgepodge_parity_swap_six :: #force_inline proc(a, s: []$E, call: $P, $KIND: Sort_Kind) #no_bounds_check {
	hodgepodge_order_pair(a, 0, call, KIND)
	hodgepodge_order_pair(a, 1, call, KIND)
	hodgepodge_order_pair(a, 4, call, KIND)
	hodgepodge_order_pair(a, 3, call, KIND)

	if !hodgepodge_greater(a[2], a[3], call, KIND) {
		hodgepodge_order_pair(a, 0, call, KIND)
		hodgepodge_order_pair(a, 4, call, KIND)
		return
	}

	x := int(hodgepodge_greater(a[0], a[1], call, KIND))
	s[0] = a[x]
	s[1] = a[1-x]
	s[2] = a[2]

	y := int(hodgepodge_greater(a[4], a[5], call, KIND))
	s[3] = a[3]
	s[4] = a[4+y]
	s[5] = a[5-y]

	hodgepodge_parity_merge(a[:6], s[:6], 3, 3, call, KIND)
}

hodgepodge_parity_swap_seven :: #force_inline proc(a, s: []$E, call: $P, $KIND: Sort_Kind) #no_bounds_check {
	hodgepodge_order_pair(a, 0, call, KIND)
	hodgepodge_order_pair(a, 2, call, KIND)
	hodgepodge_order_pair(a, 4, call, KIND)

	x := hodgepodge_greater(a[1], a[2], call, KIND)
	hodgepodge_swap_if(a, 1, x)

	y := hodgepodge_greater(a[3], a[4], call, KIND)
	hodgepodge_swap_if(a, 3, y)

	z := hodgepodge_greater(a[5], a[6], call, KIND)
	hodgepodge_swap_if(a, 5, z)

	if !(x || y || z) {
		return
	}

	hodgepodge_order_pair(a, 4, call, KIND)

	i := int(hodgepodge_greater(a[0], a[1], call, KIND))
	s[0] = a[i]
	s[1] = a[1-i]
	s[2] = a[2]

	j := int(hodgepodge_greater(a[3], a[4], call, KIND))
	s[3] = a[3+j]
	s[4] = a[4-j]

	k := int(hodgepodge_greater(a[5], a[6], call, KIND))
	s[5] = a[5+k]
	s[6] = a[6-k]

	hodgepodge_parity_merge(a[:7], s[:7], 3, 4, call, KIND)
}

hodgepodge_tiny_sort :: #force_inline proc(a, s: []$E, call: $P, $KIND: Sort_Kind) #no_bounds_check {
	switch len(a) {
	case 2:
		hodgepodge_order_pair(a, 0, call, KIND)
	case 3:
		hodgepodge_order_pair(a, 0, call, KIND)
		hodgepodge_order_pair(a, 1, call, KIND)
		hodgepodge_order_pair(a, 0, call, KIND)
	case 4:
		hodgepodge_parity_swap_four(a, call, KIND)
	case 5:
		hodgepodge_parity_swap_five(a, call, KIND)
	case 6:
		hodgepodge_parity_swap_six(a, s, call, KIND)
	case 7:
		hodgepodge_parity_swap_seven(a, s, call, KIND)
	}
}

// Merges `from[:left]` and `from[left:][:right]` into `dest` from both ends at once, where `right` is `left` or `left+1`.
hodgepodge_parity_merge :: proc(dest, from: []$E, left, right: int, call: $P, $KIND: Sort_Kind) #no_bounds_check {
	ptl := 0
	ptr := left
	tpl := left - 1
	tpr := left + right - 1
	ptd := 0
	tpd := left + right - 1

	if left < right {
		take_left := !hodgepodge_greater(from[ptl], from[ptr], call, KIND)
		dest[ptd] = from[ptl] if take_left else from[ptr]
		ptl += int(take_left)
		ptr += int(!take_left)
		ptd += 1
	}

	for _ in 0..<left {
		take_left := !hodgepodge_greater(from[ptl], from[ptr], call, KIND)
		dest[ptd] = from[ptl] if take_left else from[ptr]
		ptl += int(take_left)
		ptr += int(!take_left)
		ptd += 1

		take_right := !hodgepodge_greater(from[tpl], from[tpr], call, KIND)
		dest[tpd] = from[tpr] if take_right else from[tpl]
		tpr -= int(take_right)
		tpl -= int(!take_right)
		tpd -= 1
	}

	if ptl != tpl+1 || ptr != tpr+1 {
		copy(dest[:left+right], from[:left+right])
	}
}

hodgepodge_tail_swap :: proc(a, s: []$E, call: $P, $KIND: Sort_Kind) #no_bounds_check {
	n := len(a)
	if n < 8 {
		hodgepodge_tiny_sort(a, s, call, KIND)
		return
	}

	half1 := n / 2
	quad1 := half1 / 2
	quad2 := half1 - quad1
	half2 := n - half1
	quad3 := half2 / 2
	quad4 := half2 - quad3

	hodgepodge_tail_swap(a[:quad1],            s, call, KIND)
	hodgepodge_tail_swap(a[quad1:half1],       s, call, KIND)
	hodgepodge_tail_swap(a[half1:half1+quad3], s, call, KIND)
	hodgepodge_tail_swap(a[half1+quad3:],      s, call, KIND)

	if !hodgepodge_greater(a[quad1-1],       a[quad1],       call, KIND) &&
	   !hodgepodge_greater(a[half1-1],       a[half1],       call, KIND) &&
	   !hodgepodge_greater(a[half1+quad3-1], a[half1+quad3], call, KIND) {
		return
	}

	hodgepodge_parity_merge(s[:half1],  a[:half1],  quad1, quad2, call, KIND)
	hodgepodge_parity_merge(s[half1:n], a[half1:n], quad3, quad4, call, KIND)
	hodgepodge_parity_merge(a[:n],      s[:n],      half1, half2, call, KIND)
}

hodgepodge_quad_swap_merge :: proc(a, s: []$E, call: $P, $KIND: Sort_Kind) #no_bounds_check {
	hodgepodge_parity_merge(s[0:4], a[0:4], 2, 2, call, KIND)
	hodgepodge_parity_merge(s[4:8], a[4:8], 2, 2, call, KIND)
	hodgepodge_parity_merge(a[0:8], s[0:8], 4, 4, call, KIND)
}

// Sorts blocks of 8 and then of 32, reversing descending runs in one go.
// Returns true when the whole of `a` was one descending run, which is now sorted.
@(require_results)
hodgepodge_quad_swap :: proc(a, s: []$E, call: $P, $KIND: Sort_Kind) -> bool #no_bounds_check {
	// Whether the seams between the pairs of a[i:][:8] all ascend, or all descend.
	seams_ascend :: #force_inline proc(a: []E, i: int, call: P) -> bool #no_bounds_check {
		return !hodgepodge_greater(a[i+1], a[i+2], call, KIND) &&
		       !hodgepodge_greater(a[i+3], a[i+4], call, KIND) &&
		       !hodgepodge_greater(a[i+5], a[i+6], call, KIND)
	}
	seams_descend :: #force_inline proc(a: []E, i: int, call: P) -> bool #no_bounds_check {
		return hodgepodge_greater(a[i+1], a[i+2], call, KIND) &&
		       hodgepodge_greater(a[i+3], a[i+4], call, KIND) &&
		       hodgepodge_greater(a[i+5], a[i+6], call, KIND)
	}

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

			v1 := hodgepodge_greater(a[i],   a[i+1], call, KIND)
			v2 := hodgepodge_greater(a[i+2], a[i+3], call, KIND)
			v3 := hodgepodge_greater(a[i+4], a[i+5], call, KIND)
			v4 := hodgepodge_greater(a[i+6], a[i+7], call, KIND)

			if !(v1 || v2 || v3 || v4) {
				if seams_ascend(a, i, call) {
					i += 8
					continue blocks
				}
				hodgepodge_quad_swap_merge(a[i:i+8], s, call, KIND)
			} else if v1 && v2 && v3 && v4 && seams_descend(a, i, call) {
				pts = i
				in_reversed_run = true
				continue blocks
			} else {
				hodgepodge_swap_if(a, i,   v1)
				hodgepodge_swap_if(a, i+2, v2)
				hodgepodge_swap_if(a, i+4, v3)
				hodgepodge_swap_if(a, i+6, v4)
				hodgepodge_quad_swap_merge(a[i:i+8], s, call, KIND)
			}
			i += 8
			continue blocks
		}

		i += 8
		if count == 0 {
			rest := n % 8

			descending := true
			for k := rest; k >= 1; k -= 1 {
				if !hodgepodge_greater(a[i+k-2], a[i+k-1], call, KIND) {
					descending = false
					break
				}
			}

			if descending {
				hodgepodge_reverse(a[pts:i+rest])
				if pts == 0 {
					return true
				}
				reversed_to_end = true
				break blocks
			}
			hodgepodge_reverse(a[pts:i])
			break blocks
		}
		count -= 1

		o1 := !hodgepodge_greater(a[i],   a[i+1], call, KIND)
		o2 := !hodgepodge_greater(a[i+2], a[i+3], call, KIND)
		o3 := !hodgepodge_greater(a[i+4], a[i+5], call, KIND)
		o4 := !hodgepodge_greater(a[i+6], a[i+7], call, KIND)

		if !(o1 || o2 || o3 || o4) {
			if hodgepodge_greater(a[i-1], a[i], call, KIND) && seams_descend(a, i, call) {
				continue blocks
			}
		}
		hodgepodge_reverse(a[pts:i])
		in_reversed_run = false

		if o1 && o2 && o3 && o4 && seams_ascend(a, i, call) {
			i += 8
			continue blocks
		}

		if !(o1 || o2 || o3 || o4) && seams_descend(a, i, call) {
			pts = i
			in_reversed_run = true
			continue blocks
		}

		hodgepodge_swap_if(a, i,   !o1)
		hodgepodge_swap_if(a, i+2, !o2)
		hodgepodge_swap_if(a, i+4, !o3)
		hodgepodge_swap_if(a, i+6, !o4)

		if !seams_ascend(a, i, call) {
			hodgepodge_quad_swap_merge(a[i:i+8], s, call, KIND)
		}
		i += 8
	}

	if !reversed_to_end {
		hodgepodge_tail_swap(a[i:i+n%8], s, call, KIND)
	}

	j := 0
	for c := n / 32; c > 0; c -= 1 {
		if !hodgepodge_greater(a[j+7],  a[j+8],  call, KIND) &&
		   !hodgepodge_greater(a[j+15], a[j+16], call, KIND) &&
		   !hodgepodge_greater(a[j+23], a[j+24], call, KIND) {
			j += 32
			continue
		}

		hodgepodge_parity_merge(s[0:16],    a[j:j+16],    8,  8,  call, KIND)
		hodgepodge_parity_merge(s[16:32],   a[j+16:j+32], 8,  8,  call, KIND)
		hodgepodge_parity_merge(a[j:j+32],  s[0:32],      16, 16, call, KIND)
		j += 32
	}

	if n%32 > 8 {
		hodgepodge_tail_merge(a[j:j+n%32], s, 8, call, KIND)
	}
	return false
}

// Merges `from[:left]` and `from[left:][:right]` into `dest`.
hodgepodge_cross_merge :: proc(dest, from: []$E, left, right: int, call: $P, $KIND: Sort_Kind) #no_bounds_check {
	ptl := 0
	ptr := left
	tpl := left - 1
	tpr := left + right - 1

	if left+1 >= right && right >= left && left >= 32 {
		if  hodgepodge_greater(from[ptl+15], from[ptr],    call, KIND) &&
		   !hodgepodge_greater(from[ptl],    from[ptr+15], call, KIND) &&
		    hodgepodge_greater(from[tpl],    from[tpr-15], call, KIND) &&
		   !hodgepodge_greater(from[tpl-15], from[tpr],    call, KIND) {
			hodgepodge_parity_merge(dest, from, left, right, call, KIND)
			return
		}
	}

	ptd := 0
	tpd := left + right - 1

	for ptl <= tpl && ptr <= tpr {
		if tpl-ptl > 8 {
			if !hodgepodge_greater(from[ptl+7], from[ptr], call, KIND) {
				copy(dest[ptd:ptd+8], from[ptl:ptl+8])
				ptd += 8
				ptl += 8
				continue
			}

			if hodgepodge_greater(from[tpl-7], from[tpr], call, KIND) {
				copy(dest[tpd-7:tpd+1], from[tpl-7:tpl+1])
				tpd -= 8
				tpl -= 8
				continue
			}
		}

		if tpr-ptr > 8 {
			if hodgepodge_greater(from[ptl], from[ptr+7], call, KIND) {
				copy(dest[ptd:ptd+8], from[ptr:ptr+8])
				ptd += 8
				ptr += 8
				continue
			}

			if !hodgepodge_greater(from[tpl], from[tpr-7], call, KIND) {
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
			take_left := !hodgepodge_greater(from[ptl], from[ptr], call, KIND)
			dest[ptd] = from[ptl] if take_left else from[ptr]
			ptl += int(take_left)
			ptr += int(!take_left)
			ptd += 1

			take_right := !hodgepodge_greater(from[tpl], from[tpr], call, KIND)
			dest[tpd] = from[tpr] if take_right else from[tpl]
			tpr -= int(take_right)
			tpl -= int(!take_right)
			tpd -= 1
		}
	}

	for ptl <= tpl && ptr <= tpr {
		if hodgepodge_greater(from[ptl], from[ptr], call, KIND) {
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

hodgepodge_quad_merge_block :: proc(a, s: []$E, block: int, call: $P, $KIND: Sort_Kind) #no_bounds_check {
	b2 := block * 2
	p1 := block
	p3 := block * 3

	first_ordered  := !hodgepodge_greater(a[p1-1], a[p1], call, KIND)
	second_ordered := !hodgepodge_greater(a[p3-1], a[p3], call, KIND)

	switch {
	case first_ordered && second_ordered:
		if !hodgepodge_greater(a[b2-1], a[b2], call, KIND) {
			return
		}
		copy(s[:b2*2], a[:b2*2])

	case first_ordered:
		copy(s[:b2], a[:b2])
		hodgepodge_cross_merge(s[b2:b2*2], a[b2:b2*2], block, block, call, KIND)

	case second_ordered:
		hodgepodge_cross_merge(s[:b2], a[:b2], block, block, call, KIND)
		copy(s[b2:b2*2], a[b2:b2*2])

	case:
		hodgepodge_cross_merge(s[:b2],     a[:b2],     block, block, call, KIND)
		hodgepodge_cross_merge(s[b2:b2*2], a[b2:b2*2], block, block, call, KIND)
	}

	hodgepodge_cross_merge(a[:b2*2], s[:b2*2], b2, b2, call, KIND)
}

@(require_results)
hodgepodge_quad_merge :: proc(a, s: []$E, start_block: int, call: $P, $KIND: Sort_Kind) -> int #no_bounds_check {
	n     := len(a)
	block := start_block * 4

	for block <= n && block <= len(s) {
		pta := 0
		for pta+block <= n {
			hodgepodge_quad_merge_block(a[pta:pta+block], s, block/4, call, KIND)
			pta += block
		}

		hodgepodge_tail_merge(a[pta:n], s, block/4, call, KIND)
		block *= 4
	}

	hodgepodge_tail_merge(a, s, block/4, call, KIND)
	return block / 2
}

hodgepodge_partial_forward_merge :: proc(a, s: []$E, block: int, call: $P, $KIND: Sort_Kind) #no_bounds_check {
	n   := len(a)
	ptr := block
	tpr := n - 1
	if !hodgepodge_greater(a[ptr-1], a[ptr], call, KIND) {
		return
	}

	copy(s[:block], a[:block])
	ptl := 0
	tpl := block - 1
	out := 0

	for ptl < tpl-1 && ptr < tpr-1 {
		if hodgepodge_greater(s[ptl], a[ptr+1], call, KIND) {
			a[out]   = a[ptr]
			a[out+1] = a[ptr+1]
			out += 2
			ptr += 2
			continue
		}

		if !hodgepodge_greater(s[ptl+1], a[ptr], call, KIND) {
			a[out]   = s[ptl]
			a[out+1] = s[ptl+1]
			out += 2
			ptl += 2
			continue
		}

		left_first := !hodgepodge_greater(s[ptl], a[ptr], call, KIND)
		right_item := a[ptr]
		left_item  := s[ptl]
		a[out+int(left_first)]  = right_item
		a[out+int(!left_first)] = left_item
		out += 2
		ptr += 1
		ptl += 1

		if hodgepodge_greater(s[ptl], a[ptr], call, KIND) {
			a[out] = a[ptr]
			ptr += 1
		} else {
			a[out] = s[ptl]
			ptl += 1
		}
		out += 1
	}

	for ptl <= tpl && ptr <= tpr {
		if hodgepodge_greater(s[ptl], a[ptr], call, KIND) {
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
hodgepodge_backward_merge_step :: #force_inline proc(a, s: []$E, tpl, tpr, tpa: int, call: $P, $KIND: Sort_Kind) -> (int, int, int) #no_bounds_check {
	if !hodgepodge_greater(a[tpl], s[tpr-1], call, KIND) {
		a[tpa]   = s[tpr]
		a[tpa-1] = s[tpr-1]
		return tpl, tpr-2, tpa-2
	}

	if hodgepodge_greater(a[tpl-1], s[tpr], call, KIND) {
		a[tpa]   = a[tpl]
		a[tpa-1] = a[tpl-1]
		return tpl-2, tpr, tpa-2
	}

	right_after := !hodgepodge_greater(a[tpl], s[tpr], call, KIND)
	right_item  := s[tpr]
	left_item   := a[tpl]
	a[tpa-1+int(right_after)]  = right_item
	a[tpa-1+int(!right_after)] = left_item

	if hodgepodge_greater(a[tpl-1], s[tpr-1], call, KIND) {
		a[tpa-2] = a[tpl-1]
		return tpl-2, tpr-1, tpa-3
	}
	a[tpa-2] = s[tpr-1]
	return tpl-1, tpr-2, tpa-3
}

hodgepodge_partial_backward_merge :: proc(a, s: []$E, block: int, call: $P, $KIND: Sort_Kind) #no_bounds_check {
	n   := len(a)
	tpl := block - 1
	tpa := n - 1
	if !hodgepodge_greater(a[tpl], a[tpl+1], call, KIND) {
		return
	}

	right := n - block
	if n <= len(s) && right >= 64 {
		hodgepodge_cross_merge(s[:n], a[:n], block, right, call, KIND)
		copy(a[:n], s[:n])
		return
	}

	copy(s[:right], a[block:n])
	tpr := right - 1

	bulk: for tpl > 16 && tpr > 16 {
		for !hodgepodge_greater(a[tpl], s[tpr-15], call, KIND) {
			for _ in 0..<16 {
				a[tpa] = s[tpr]
				tpa -= 1
				tpr -= 1
			}
			if tpr <= 16 {
				break bulk
			}
		}

		for hodgepodge_greater(a[tpl-15], s[tpr], call, KIND) {
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
			tpl, tpr, tpa = hodgepodge_backward_merge_step(a, s, tpl, tpr, tpa, call, KIND)
		}
	}

	for tpr > 1 && tpl > 1 {
		tpl, tpr, tpa = hodgepodge_backward_merge_step(a, s, tpl, tpr, tpa, call, KIND)
	}

	for tpr >= 0 && tpl >= 0 {
		if hodgepodge_greater(a[tpl], s[tpr], call, KIND) {
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

hodgepodge_tail_merge :: proc(a, s: []$E, start_block: int, call: $P, $KIND: Sort_Kind) #no_bounds_check {
	n     := len(a)
	block := start_block

	for block < n && block <= len(s) {
		for pta := 0; pta+block < n; pta += block*2 {
			hodgepodge_partial_backward_merge(a[pta:builtin.min(pta+block*2, n)], s, block, call, KIND)
		}
		block *= 2
	}
}

// Rotates `a` so that `a[left:]` comes before `a[:left]`.
hodgepodge_trinity_rotation :: proc(a, s: []$E, left: int) #no_bounds_check {
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
		hodgepodge_reverse(a[pta:ptd])

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
		hodgepodge_reverse(a[pta:ptd])

	case:
		swap_with_slice(a[:left], a[left:])
	}
}

// Which items go in front of a given one: those not greater than it, or only those less than it.
// The two differ only in where equal items go.
Hodgepodge_Front :: enum {
	Not_Greater,
	Less,
}

@(require_results)
hodgepodge_in_front :: #force_inline proc(item, x: $E, call: $P, $KIND: Sort_Kind, $FRONT: Hodgepodge_Front) -> bool {
	return hodgepodge_greater(x, item, call, KIND) if FRONT == .Less else !hodgepodge_greater(item, x, call, KIND)
}

// How many items of the sorted `a` go in front of x. The search halves the same way whatever the comparisons find.
@(require_results)
hodgepodge_rank :: proc(a: []$E, x: E, call: $P, $KIND: Sort_Kind, $FRONT: Hodgepodge_Front) -> int #no_bounds_check {
	top := len(a)
	end := top
	for top > 1 {
		mid := top / 2
		if !hodgepodge_in_front(a[end-mid], x, call, KIND, FRONT) {
			end -= mid
		}
		top -= mid
	}
	if top == 1 && !hodgepodge_in_front(a[end-1], x, call, KIND, FRONT) {
		end -= 1
	}
	return end
}

// Whether a[:left] and a[left:] interleave enough for a block merge. They are taken in steps of g items, in order of
// the steps' first items. A step that ends before the other side's step before it has what is left of that step carried
// past it, and fewer than 1/HODGEPODGE_MERGE_CARRIED of the steps may be. Each side needs two steps.
@(require_results)
hodgepodge_interleaved :: proc(a: []$E, left, g: int, call: $P, $KIND: Sort_Kind) -> bool #no_bounds_check {
	head   := left % g
	lefts  := left / g
	rights := (len(a)-left) / g
	steps  := lefts + rights
	if lefts < 2 || rights < 2 {
		return false
	}

	carried, l := 0, 0
	last_l, last_r := -1, -1
	for t in 0..<steps {
		r := t - l
		if l == lefts || r < rights && hodgepodge_greater(a[head + l*g], a[left + r*g], call, KIND) {
			last_r = left + r*g + g-1
			carried += int(last_l >= 0 && hodgepodge_greater(a[last_l], a[last_r], call, KIND))
		} else {
			last_l = head + l*g + g-1
			carried += int(last_r >= 0 && !hodgepodge_greater(a[last_l], a[last_r], call, KIND))
			l += 1
		}
		// The steps still to come cannot change the answer.
		if carried*HODGEPODGE_MERGE_CARRIED >= steps || (carried + steps-1-t)*HODGEPODGE_MERGE_CARRIED < steps {
			break
		}
	}
	return carried*HODGEPODGE_MERGE_CARRIED < steps
}

// Merges what is left, c[:f], with the next block c[f:], of the other side, until one of them runs out: the merged items
// go to the front of `c`, and what is left of the other stays at the back. Returns how many items merged and whether what
// is left is the right side's. The left side's items go before equal items of the right side.
@(require_results)
hodgepodge_merge_fragment :: proc(c, s: []$E, f: int, f_right: bool, call: $P, $KIND: Sort_Kind) -> (merged: int, rest_right: bool) #no_bounds_check {
	// How many items of the sorted `a`, of the right side or not, go in front of x, of the other side.
	before :: proc(a: []E, x: E, a_right: bool, call: P) -> int {
		return hodgepodge_rank(a, x, call, KIND, .Less) if a_right else hodgepodge_rank(a, x, call, KIND, .Not_Greater)
	}

	x      := len(c) - f
	f_last := c[f-1]
	x_last := c[len(c)-1]
	// Whether what is left runs out first: its last item goes before the block's.
	f_first := hodgepodge_greater(x_last, f_last, call, KIND) if f_right else !hodgepodge_greater(f_last, x_last, call, KIND)

	// The items that merge: the block's up to the last of what is left, or what is left up to the block's last.
	taken_f, taken_x := f, x
	if f_first {
		taken_x = before(c[f:], f_last, !f_right, call)
	} else {
		taken_f = before(c[:f], x_last, f_right, call)
	}
	l, r := c[:taken_f], c[f:][:taken_x]
	if f_right {
		l, r = r, l
	}
	copy(s, l)
	copy(s[len(l):], r)
	// The rest of what is left goes after the block.
	copy(c[taken_f+x:], c[taken_f:f])
	hodgepodge_cross_merge(c[:taken_f+taken_x], s, len(l), len(r), call, KIND)
	return taken_f + taken_x, f_right != f_first
}

// Fills `ranks` with how many bits of `words` are set before each word, and returns how many are set in all.
hodgepodge_word_ranks :: proc "contextless" (ranks: []int, words: []u64) -> (count: int) #no_bounds_check {
	for word, i in words {
		ranks[i] = count
		count += int(intrinsics.count_ones(word))
	}
	return
}

// How many bits of `words` before bit i are set, given their `ranks`, and whether bit i is.
@(require_results)
hodgepodge_bit_rank :: #force_inline proc "contextless" (words: []u64, ranks: []int, i: int) -> (rank: int, set: bool) #no_bounds_check {
	word := words[i>>6]
	return ranks[i>>6] + int(intrinsics.count_ones(word & (1 << uint(i&63) - 1))), word & (1 << uint(i&63)) != 0
}

// Merges a[:left] and a[left:] in blocks of half the buffer, at most HODGEPODGE_BLOCKS of them, after the block merge
// of Huang and Langston ("Practical In-Place Merging", 1988) with the buffer outside the array. The blocks are put in
// order of their first items, the left side's first on a tie, and one pass merges each block with what is left of the
// blocks before it, through the buffer. The left side's first left%b items start what is left, and the right side's
// last items short of a block merge in at the end. It stays out of line, or its bit sets sit in every recursive frame of
// rotate_merge_block.
hodgepodge_block_merge :: #force_no_inline proc(a, s: []$E, left: int, call: $P, $KIND: Sort_Kind) #no_bounds_check {
	WORDS :: HODGEPODGE_BLOCKS / 64

	n      := len(a)
	b      := len(s) / 2
	head   := left % b
	lefts  := left / b
	blocks := lefts + (n-left) / b
	tail   := (n-left) % b

	// Bit t: the t-th block in order is the right side's.
	rights: [WORDS]u64
	for t, l := 0, 0; t < blocks; t += 1 {
		r := t - l
		right := l == lefts || r < blocks-lefts && hodgepodge_greater(a[head + l*b], a[left + r*b], call, KIND)
		rights[t>>6] |= u64(right) << uint(t&63)
		l += int(!right)
	}

	// Puts the blocks in order, following each cycle with one block held in the buffer. The block that goes at t is the
	// left side's next one or the right side's, by how many of the right side's go before it.
	ranks: [WORDS]int = ---
	hodgepodge_word_ranks(ranks[:], rights[:(blocks+63)/64])
	source :: #force_inline proc(t, lefts: int, rights: []u64, ranks: []int) -> int {
		r, right := hodgepodge_bit_rank(rights, ranks, t)
		return lefts + r if right else t - r
	}
	placed: [WORDS]u64
	for start in 0..<blocks {
		from := source(start, lefts, rights[:], ranks[:])
		if from == start || placed[start>>6] & (1 << uint(start&63)) != 0 {
			continue
		}
		copy(s[:b], a[head + start*b:][:b])
		t := start
		for from != start {
			placed[t>>6] |= 1 << uint(t&63)
			copy(a[head + t*b:][:b], a[head + from*b:][:b])
			t, from = from, source(from, lefts, rights[:], ranks[:])
		}
		placed[t>>6] |= 1 << uint(t&63)
		copy(a[head + t*b:][:b], s[:b])
	}

	// a[o:pos] is what is left of the blocks before pos, all from one side. Each side's blocks come in order, and the other
	// side's blocks still to come start no lower than the next block: before a block of its own side, what is left is in
	// place.
	o, pos := 0, head
	f_right := false
	for t in 0..<blocks {
		x_right := rights[t>>6] & (1 << uint(t&63)) != 0
		end := pos + b
		if o == pos || x_right == f_right {
			o, f_right = pos, x_right
		} else {
			merged: int
			merged, f_right = hodgepodge_merge_fragment(a[o:end], s, pos-o, f_right, call, KIND)
			o += merged
		}
		pos = end
	}
	if tail > 0 {
		hodgepodge_partial_backward_merge(a, s, n-tail, call, KIND)
	}
}

// The bytes of s[1:] as items of I: s[0] holds the item that starts a cycle.
@(require_results)
hodgepodge_words :: proc(s: []$E, $I: typeid) -> []I {
	bytes := ([^]u8)(raw_data(s))[size_of(E):len(s)*size_of(E)]
	skip  := -int(uintptr(raw_data(bytes))) & (align_of(I) - 1)
	return ([^]I)(raw_data(bytes[skip:]))[:(len(bytes) - skip) / size_of(I)]
}

// A merge carried out by moving items: merged item t, of the sorted `ranks`, sits at from+t and goes to ranks[t]+t, and
// the other items, from `others` on, keep their order around them. HODGEPODGE_RANK_MARK in a rank marks an item a cycle
// has passed through.
Hodgepodge_Ranks :: struct {
	ranks:        []u32,
	from, others: int,
}

// The notes of a drop-merge segment: its set-aside items sit at offsets `at`, ascending, and the t-th of them in order
// is note order[t], which goes to ranks[t]+t. The kept items keep their order around them. HODGEPODGE_NOTE_MARK in an
// offset marks a spike while the segment is read, and an item a cycle has passed through while it sorts.
Hodgepodge_Notes :: struct {
	at, order, ranks: []u16,
}

// How many merged items of the sorted `ranks` go before place p, and whether the next goes to p. Merged item t goes to
// ranks[t]+t, and a rank's top bit is a mark.
@(require_results)
hodgepodge_merged_before :: proc "contextless" (ranks: []$I, p: int) -> (t: int, here: bool) #no_bounds_check {
	RANK :: builtin.max(I) >> 1
	hi := len(ranks)
	for t < hi {
		mid := (t + hi) / 2
		if int(ranks[mid] & RANK) + mid < p {
			t = mid + 1
		} else {
			hi = mid
		}
	}
	return t, t < len(ranks) && int(ranks[t] & RANK) + t == p
}

// Where the item that goes to place p comes from.
@(require_results)
hodgepodge_ranks_source :: proc "contextless" (moves: Hodgepodge_Ranks, p: int) -> int {
	t, here := hodgepodge_merged_before(moves.ranks, p)
	return moves.from + t if here else moves.others + p - t
}

@(require_results)
hodgepodge_notes_source :: proc "contextless" (notes: Hodgepodge_Notes, p: int) -> int #no_bounds_check {
	t, here := hodgepodge_merged_before(notes.ranks, p)
	if here {
		return int(notes.at[notes.order[t]] &~ HODGEPODGE_NOTE_MARK)
	}
	// Kept item j sits past the notes u with at[u]-u <= j.
	j := p - t
	lo, hi := 0, len(notes.at)
	for lo < hi {
		mid := (lo + hi) / 2
		if int(notes.at[mid] &~ HODGEPODGE_NOTE_MARK) - mid <= j {
			lo = mid + 1
		} else {
			hi = mid
		}
	}
	return j + lo
}

// The place of the t-th merged item, and whether no cycle has passed through it yet, which it now marks.
@(require_results)
hodgepodge_ranks_leader :: proc "contextless" (moves: Hodgepodge_Ranks, t: int) -> (place: int, fresh: bool) #no_bounds_check {
	fresh = moves.ranks[t] & HODGEPODGE_RANK_MARK == 0
	moves.ranks[t] |= HODGEPODGE_RANK_MARK
	return moves.from + t, fresh
}

@(require_results)
hodgepodge_notes_leader :: proc "contextless" (notes: Hodgepodge_Notes, t: int) -> (place: int, fresh: bool) #no_bounds_check {
	fresh = notes.at[t] & HODGEPODGE_NOTE_MARK == 0
	notes.at[t] |= HODGEPODGE_NOTE_MARK
	return int(notes.at[t] &~ HODGEPODGE_NOTE_MARK), fresh
}

// Marks that a cycle has passed through place p, where a merged item sits.
hodgepodge_ranks_pass :: proc "contextless" (moves: Hodgepodge_Ranks, p: int) #no_bounds_check {
	if t := p - moves.from; 0 <= t && t < len(moves.ranks) {
		moves.ranks[t] |= HODGEPODGE_RANK_MARK
	}
}

hodgepodge_notes_pass :: proc "contextless" (notes: Hodgepodge_Notes, p: int) #no_bounds_check {
	lo, hi := 0, len(notes.at)
	for lo < hi {
		mid := (lo + hi) / 2
		if int(notes.at[mid] &~ HODGEPODGE_NOTE_MARK) < p {
			lo = mid + 1
		} else {
			hi = mid
		}
	}
	if lo < len(notes.at) && int(notes.at[lo] &~ HODGEPODGE_NOTE_MARK) == p {
		notes.at[lo] |= HODGEPODGE_NOTE_MARK
	}
}

hodgepodge_source :: proc{hodgepodge_ranks_source, hodgepodge_notes_source}
hodgepodge_leader :: proc{hodgepodge_ranks_leader, hodgepodge_notes_leader}
hodgepodge_pass   :: proc{hodgepodge_ranks_pass, hodgepodge_notes_pass}

// Moves every item of r to where `moves` puts it, following each cycle of the permutation from a merged item's place:
// every cycle passes through one, as the other items keep their order. The items of a cycle lie far apart, so the next
// HODGEPODGE_AHEAD of them are fetched ahead.
hodgepodge_follow_cycles :: proc(r, s: []$E, moves: $M) #no_bounds_check {
	for t in 0..<len(moves.ranks) {
		start, fresh := hodgepodge_leader(moves, t)
		if !fresh {
			continue
		}
		ahead: [HODGEPODGE_AHEAD]int
		head, count := 0, 0
		cur, last := start, start
		closed := false
		for {
			for count < HODGEPODGE_AHEAD && !closed {
				next := hodgepodge_source(moves, last)
				closed = next == start
				if !closed {
					ahead[(head + count) % HODGEPODGE_AHEAD] = next
					for offset := 0; offset < size_of(E); offset += 64 {
						intrinsics.prefetch_read_data(rawptr(uintptr(&r[next]) + uintptr(offset)), 3)
					}
					last = next
					count += 1
				}
			}
			if count == 0 {
				if cur != start {
					r[cur] = s[0]
				}
				break
			}
			if cur == start {
				s[0] = r[start]
			}
			next := ahead[head]
			head = (head + 1) % HODGEPODGE_AHEAD
			count -= 1
			hodgepodge_pass(moves, next)
			r[cur] = r[next]
			cur = next
		}
	}
}

// How many items of the sorted `a` go in front of x, given that the first `from` do: a galloping search from there.
@(require_results)
hodgepodge_gallop :: proc(a: []$E, from: int, x: E, call: $P, $KIND: Sort_Kind, $FRONT: Hodgepodge_Front) -> int #no_bounds_check {
	lo, step := from, 1
	for lo+step <= len(a) && hodgepodge_in_front(a[lo+step-1], x, call, KIND, FRONT) {
		lo   += step
		step *= 2
	}
	return lo + hodgepodge_rank(a[lo:builtin.min(lo+step-1, len(a))], x, call, KIND, FRONT)
}

// Merges the sorted r[:l] with the sorted items after it, each item moving at most once. Chunks of the items after rank
// among r[:l], FRONT saying which go in front of them, and move by hodgepodge_follow_cycles.
hodgepodge_merge_after :: proc(r, s: []$E, l: int, call: $P, $KIND: Sort_Kind, $FRONT: Hodgepodge_Front) #no_bounds_check {
	ranks := hodgepodge_words(s, u32)
	for from := l; from < len(r); /**/ {
		m := builtin.min(len(r) - from, len(ranks))
		rank := 0
		for t in 0..<m {
			rank = hodgepodge_gallop(r[:from], rank, r[from+t], call, KIND, FRONT)
			ranks[t] = u32(rank)
		}
		hodgepodge_follow_cycles(r[:from+m], s, Hodgepodge_Ranks{ranks[:m], from, 0})
		from += m
	}
}

// Merges the sorted items r[:m] into the sorted r[m:] as hodgepodge_merge_after does, from the other end: the last
// chunk goes first.
hodgepodge_merge_before :: proc(r, s: []$E, m: int, call: $P, $KIND: Sort_Kind, $FRONT: Hodgepodge_Front) #no_bounds_check {
	ranks := hodgepodge_words(s, u32)
	for end := m; end > 0; /**/ {
		c := builtin.min(end, len(ranks))
		chunk := r[end-c:]
		rank := 0
		for t in 0..<c {
			rank = hodgepodge_gallop(chunk[c:], rank, chunk[t], call, KIND, FRONT)
			ranks[t] = u32(rank)
		}
		hodgepodge_follow_cycles(chunk, s, Hodgepodge_Ranks{ranks[:c], 0, c})
		end -= c
	}
}

// Merges a[:left] and a[left:], whose last and first items are out of order, moving each item at most once where at
// most 1/HODGEPODGE_SPARSE of the items cross: the k items of each side that belong on the other swap over, and each
// side's k then merge into the rest of it. Returns false, leaving `a` as it was, where more cross.
@(require_results)
hodgepodge_sparse_merge :: proc(a, s: []$E, left: int, call: $P, $KIND: Sort_Kind) -> bool #no_bounds_check {
	// How many of the left side's items are among the first `left` merged, the left side's first on a tie.
	lo, hi := builtin.max(0, 2*left - len(a)), left
	for lo < hi {
		mid := (lo + hi + 1) / 2
		if hodgepodge_greater(a[mid-1], a[2*left - mid], call, KIND) {
			hi = mid - 1
		} else {
			lo = mid
		}
	}
	k := left - lo
	if k*HODGEPODGE_SPARSE > len(a) || u64(len(a)) >= u64(HODGEPODGE_RANK_MARK) {
		return false
	}

	for done := 0; done < k; done += len(s) {
		c := builtin.min(len(s), k - done)
		copy(s[:c], a[lo+done:][:c])
		copy(a[lo+done:][:c], a[left+done:][:c])
		copy(a[left+done:][:c], s[:c])
	}
	// The right side's k go behind equal items of the left side's, and the left side's k in front of the right side's.
	if k <= len(s) {
		hodgepodge_partial_backward_merge(a[:left], s, lo, call, KIND)
		hodgepodge_partial_forward_merge(a[left:], s, k, call, KIND)
	} else {
		hodgepodge_merge_after(a[:left], s, lo, call, KIND, .Not_Greater)
		hodgepodge_merge_before(a[left:], s, k, call, KIND, .Less)
	}
	return true
}

hodgepodge_rotate_merge_block :: proc(a, s: []$E, block, count: int, call: $P, $KIND: Sort_Kind, try_blocks := true) #no_bounds_check {
	// Merges a part through the buffer where the part fits, or where its sides differ more than twofold and one of them
	// fits: a backward merge buffers the right side, and a forward merge the left. Other parts take rotations.
	part :: proc(a, s: []E, block, count: int, call: P, try_blocks: bool) {
		unbalanced := count*2 < block || block*2 < count
		switch {
		case unbalanced && count <= len(s) || block+count <= len(s):
			hodgepodge_partial_backward_merge(a, s, block, call, KIND)
		case unbalanced && block <= len(s):
			hodgepodge_partial_forward_merge(a, s, block, call, KIND)
		case:
			hodgepodge_rotate_merge_block(a, s, block, count, call, KIND, try_blocks)
		}
	}

	if !hodgepodge_greater(a[block-1], a[block], call, KIND) {
		return
	}

	// Huge elements cost more to move than to compare. Where few cross, each moves at most once.
	when size_of(E) > HODGEPODGE_HUGE_BYTES {
		if block > len(s) && count > len(s) && len(s) > 1 && hodgepodge_sparse_merge(a, s, block, call, KIND) {
			return
		}
	}

	// Where both sides overlap the other by more than the buffer, a block merge moves each item about three times, and
	// rotations move it once per halving. The left side's items not above the right side's first are in place, and so
	// are the right side's items not below the left side's last. The halves below try a block merge only where this merge
	// has too many blocks for one. Items of HODGEPODGE_HEAVY_BYTES or more take it however little the sides interleave:
	// copies cost them more than comparisons.
	try_halves := false
	b := len(s) / 2
	if try_blocks && block > len(s) && count > len(s) && b > 0 {
		lo := hodgepodge_rank(a[:block], a[block], call, KIND, .Not_Greater)
		hi := block + hodgepodge_rank(a[block:], a[block-1], call, KIND, .Less)
		if block-lo > len(s) && hi-block > len(s) {
			if (hi-lo)/b > HODGEPODGE_BLOCKS {
				try_halves = true
			} else if size_of(E) >= HODGEPODGE_HEAVY_BYTES ||
			          hodgepodge_interleaved(a[lo:hi], block-lo, builtin.max(b, HODGEPODGE_MERGE_STEP), call, KIND) {
				hodgepodge_block_merge(a[lo:hi], s, block-lo, call, KIND)
				return
			}
		}
	}

	if block == 1 {
		position := hodgepodge_rank(a[1:], a[0], call, KIND, .Less)
		hodgepodge_trinity_rotation(a[:1+position], s, 1)
		return
	}

	rblock := block / 2
	lblock := block - rblock

	left  := hodgepodge_rank(a[lblock+rblock:], a[lblock], call, KIND, .Less)
	right := count - left

	if left > 0 {
		if lblock+left <= len(s) {
			copy(s[:lblock], a[:lblock])
			copy(s[lblock:lblock+left], a[lblock+rblock:lblock+rblock+left])
			copy(a[lblock+left:lblock+left+rblock], a[lblock:lblock+rblock])
			hodgepodge_cross_merge(a[:lblock+left], s[:lblock+left], lblock, left, call, KIND)
		} else {
			hodgepodge_trinity_rotation(a[lblock:lblock+rblock+left], s, rblock)
			part(a[:lblock+left], s, lblock, left, call, try_halves)
		}
	}

	if right > 0 {
		part(a[lblock+left:lblock+left+rblock+right], s, rblock, right, call, try_halves)
	}
}

hodgepodge_rotate_merge :: proc(a, s: []$E, start_block: int, call: $P, $KIND: Sort_Kind) #no_bounds_check {
	n     := len(a)
	block := start_block

	if block < n && n <= block*2 && n-block <= len(s) {
		hodgepodge_partial_backward_merge(a, s, block, call, KIND)
		return
	}

	for block < n {
		for pta := 0; pta+block < n; pta += block*2 {
			end := builtin.min(pta+block*2, n)
			hodgepodge_rotate_merge_block(a[pta:end], s, block, end-pta-block, call, KIND)
		}
		block *= 2
	}
}

hodgepodge_quadsort :: proc(a, s: []$E, call: $P, $KIND: Sort_Kind) #no_bounds_check {
	if len(a) <= HODGEPODGE_SMALL && len(a) <= len(s) {
		hodgepodge_tail_swap(a, s, call, KIND)
		return
	}

	// Quad swaps take 32 items of buffer, more than fit of huge elements.
	when size_of(E) > HODGEPODGE_HUGE_BYTES {
		hodgepodge_large_element_sort(a, s, call, KIND)
	} else {
		if !hodgepodge_quad_swap(a, s, call, KIND) {
			block := hodgepodge_quad_merge(a, s, 32, call, KIND)
			hodgepodge_rotate_merge(a, s, block, call, KIND)
		}
	}
}

// How many of 256 evenly spaced adjacent pairs descend.
@(require_results)
hodgepodge_sample_descents :: proc(a: []$E, call: $P, $KIND: Sort_Kind) -> (descents: int) #no_bounds_check {
	n := len(a)
	for t in 0..<256 {
		i := int(i64(t)*i64(n-1)/256)
		descents += int(hodgepodge_greater(a[i], a[i+1], call, KIND))
	}
	return
}

// Whether the points of hodgepodge_sample_descents's sample have fewer than HODGEPODGE_FAR_DESCENTS descents between
// each other: sorted at large scale, however disordered between neighbours.
@(require_results)
hodgepodge_sorted_at_scale :: proc(a: []$E, call: $P, $KIND: Sort_Kind) -> bool #no_bounds_check {
	n := len(a)
	descents := 0
	for t in 1..<256 {
		descents += int(hodgepodge_greater(a[int(i64(t-1)*i64(n-1)/256)], a[int(i64(t)*i64(n-1)/256)], call, KIND))
	}
	return descents < HODGEPODGE_FAR_DESCENTS
}

// Drop-merge, after Ernerfeldt's drop-merge sort (2016), for input sorted apart from scattered items: a non-decreasing
// sequence stays in place, and the items that break it are set aside. Up to HODGEPODGE_DROP_SPIKES kept items that
// stand above what follows them, spikes, are set aside instead of what follows. Kept items equal to a spike come after
// it, and those equal to any other set-aside item come before it: the two kinds gather unsorted at the two ends of the
// buffer, and each sorts on its own. When the buffer is full, what is done so far merges into one sorted segment and
// the scan carries on. The segments then merge in Powersort's order. Concatenated runs pass for nearly sorted too, but
// each new run starts below the kept items and would be set aside whole: when the input does that, drop-merge stops
// and returns where. Before that are sorted segments, and after it the input as it was. It stays out of line: inlined
// into hodgepodge_analyse, it slows the routes that do not take it.
@(require_results)
hodgepodge_drop_merge :: #force_no_inline proc(a, s: []$E, call: $P, $KIND: Sort_Kind) -> (rest: int) #no_bounds_check {
	// Merges the kept a[base:][:k] with the set-aside items into a[base:][:k+lows+spikes]. They sort through the space
	// after the kept items, the spikes having gathered back to front.
	flush :: proc(a, s: []E, base, k, lows, spikes: int, call: P) {
		free := a[base+k:][:lows+spikes]
		low  := s[:lows]
		high := s[len(s)-spikes:]
		hodgepodge_reverse(high)
		hodgepodge_quadsort(low,  free, call, KIND)
		hodgepodge_quadsort(high, free, call, KIND)

		// From the back, each set-aside item goes in front of the kept items above it: a spike in front of equal items,
		// and any other set-aside item behind them.
		i, h, j, w := lows-1, spikes-1, base+k, base+k+lows+spikes
		for i >= 0 || h >= 0 {
			x:     E
			front: int
			if h < 0 || i >= 0 && !hodgepodge_greater(high[h], low[i], call, KIND) {
				x = low[i]
				i -= 1
				front = base + hodgepodge_rank(a[base:j], x, call, KIND, .Not_Greater)
			} else {
				x = high[h]
				h -= 1
				front = base + hodgepodge_rank(a[base:j], x, call, KIND, .Less)
			}
			behind := j - front
			copy(a[w-behind:w], a[front:j])
			w -= behind + 1
			j = front
			a[w] = x
		}
	}

	n := len(a)
	base, k, lows, spikes := 0, 0, 0, 0
	// The greatest set-aside item that is not a spike. Every kept item after it must be above it.
	max_low: E
	for i in 0..<n {
		x   := a[i]
		top := base + k
		if k == 0 || !hodgepodge_greater(a[top-1], x, call, KIND) {
			a[top] = x
			k += 1
			continue
		}
		if lows+spikes+HODGEPODGE_DROP_SPIKES > len(s) {
			flush(a, s, base, k, lows, spikes, call)
			base, k, lows, spikes = i, 1, 0, 0
			continue
		}

		// x is below the last kept item. If x still fits after the few kept items before it, and the next item is
		// below those too, they are the odd ones out.
		c := 1
		for c <= HODGEPODGE_DROP_SPIKES && c < k && hodgepodge_greater(a[top-c-1], x, call, KIND) {
			c += 1
		}
		if c <= HODGEPODGE_DROP_SPIKES && c < k && i+1 < n && hodgepodge_greater(a[top-c], a[i+1], call, KIND) &&
		   (lows == 0 || hodgepodge_greater(x, max_low, call, KIND)) {
			for t in top-c..<top {
				spikes += 1
				s[len(s)-spikes] = a[t]
			}
			a[top-c] = x
			k -= c - 1
			continue
		}

		if lows == 0 || hodgepodge_greater(x, max_low, call, KIND) {
			max_low = x
		}
		s[lows] = x
		lows += 1

		// A new run below the kept items: x and the next HODGEPODGE_DROP_ASCENT items ascend, and the last of them is
		// below the HODGEPODGE_DROP_NEW_RUN-th last kept item. Low outliers in a row rarely ascend that far.
		if lows % HODGEPODGE_DROP_NEW_RUN == 0 && k >= HODGEPODGE_DROP_NEW_RUN && i+HODGEPODGE_OUT < n &&
		   hodgepodge_greater(a[base+k-HODGEPODGE_DROP_NEW_RUN], a[i+HODGEPODGE_DROP_ASCENT], call, KIND) &&
		   hodgepodge_is_sorted(a[i:][:HODGEPODGE_DROP_ASCENT+1], call, KIND) {
			flush(a, s, base, k, lows, spikes, call)
			return i + 1
		}
	}
	if lows+spikes > 0 {
		flush(a, s, base, k, lows, spikes, call)
	}
	if base > 0 {
		hodgepodge_power_merge(a, s, call, KIND)
	}
	return n
}

// The block size of hodgepodge_drop_split for a buffer of `buffer` items: three stages fit, the kept items' with
// HODGEPODGE_DROP_NEW_RUN to spare and the spikes' with one less.
@(require_results)
hodgepodge_split_block :: proc "contextless" (buffer: int) -> int {
	return (buffer - 2*HODGEPODGE_DROP_NEW_RUN + 1) / 3
}

// Drop-merge's scan for more set-aside items than the buffer holds: they stay in the array. Kept items, spikes, and
// lows each gather in a stage of the buffer and go back as whole blocks into the part of `a` already read. The blocks
// are then put in order, and a[:rest] becomes the spikes, the kept items, and the lows, each in the order the scan set
// them down. The kept stage holds back its last HODGEPODGE_DROP_NEW_RUN items for pops and the new-run test.
// No segment ends to reset the scan, so it recovers from bad choices on its own. A set-aside item above every kept
// item not above it, and above every low, goes with the spikes and leaves max_low alone. After HODGEPODGE_DROP_STREAK
// set-asides in a row, a pop may take up to HODGEPODGE_DROP_NEW_RUN-1 kept items. Before the first kept block, a pop
// may take all of them. Each keeps drop-merge's tie rules.
@(require_results)
hodgepodge_drop_split :: #force_no_inline proc(a, s: []$E, call: $P, $KIND: Sort_Kind) -> (rest, spikes, kept: int) #no_bounds_check {
	WORDS   :: HODGEPODGE_BLOCKS / 64
	NEW_RUN :: HODGEPODGE_DROP_NEW_RUN
	SPIKES  :: HODGEPODGE_DROP_SPIKES

	n  := len(a)
	b  := hodgepodge_split_block(len(s))
	ks := s[:b+NEW_RUN]
	ss := s[b+NEW_RUN:][:b+NEW_RUN-1]
	ls := s[2*b+2*NEW_RUN-1:][:b]

	// Bit t: block t is spikes, or kept items. Blocks of neither are lows.
	spike_blocks, kept_blocks: [WORDS]u64
	blocks := 0
	kc, sc, lc, lows, streak := 0, 0, 0, 0, 0
	kept_out := false
	// The greatest low. Every kept item after it must be above it.
	max_low: E
	rest = n
	scan: for i in 0..<n {
		x := a[i]
		if kc == 0 || !hodgepodge_greater(ks[kc-1], x, call, KIND) {
			ks[kc] = x
			kc += 1
			streak = 0
			if kc == len(ks) {
				copy(a[blocks*b:][:b], ks[:b])
				kept_blocks[blocks>>6] |= 1 << uint(blocks&63)
				kept_out = true
				blocks += 1
				copy(ks, ks[b:kc])
				kc -= b
			}
			continue
		}

		// The last c kept items are above x, and x fits after the one before them, within the held-back items.
		c := 1
		for c <= SPIKES && c < kc && hodgepodge_greater(ks[kc-c-1], x, call, KIND) {
			c += 1
		}
		fits := c < kc
		if c > SPIKES && fits {
			w := ks[builtin.max(kc-NEW_RUN, 0):kc-c]
			r := hodgepodge_rank(w, x, call, KIND, .Not_Greater)
			c += len(w) - r
			fits = r > 0
		}
		first := c == kc && !kept_out
		guard := lows == 0 || hodgepodge_greater(x, max_low, call, KIND)
		limit := SPIKES if streak < HODGEPODGE_DROP_STREAK else NEW_RUN-1

		switch {
		case (fits || first) && guard && c <= limit && i+1 < n && hodgepodge_greater(ks[kc-c], a[i+1], call, KIND):
			// The kept items above x, and above the next item too, are the odd ones out.
			copy(ss[sc:][:c], ks[kc-c:kc])
			sc += c
			ks[kc-c] = x
			kc -= c - 1
			streak = 0
		case guard && (first || fits && hodgepodge_greater(x, ks[kc-c-1], call, KIND)):
			ss[sc] = x
			sc += 1
			streak += 1
		case:
			if lows == 0 || hodgepodge_greater(x, max_low, call, KIND) {
				max_low = x
			}
			ls[lc] = x
			lc += 1
			lows += 1
			streak += 1
			if lc == b {
				copy(a[blocks*b:][:b], ls[:b])
				blocks += 1
				lc = 0
			}
			// A new run below the kept items, as in hodgepodge_drop_merge.
			if lows % NEW_RUN == 0 && kc >= NEW_RUN && i+HODGEPODGE_OUT < n &&
			   hodgepodge_greater(ks[kc-NEW_RUN], a[i+HODGEPODGE_DROP_ASCENT], call, KIND) &&
			   !hodgepodge_greater(x, a[i+1], call, KIND) &&
			   hodgepodge_is_sorted(a[i+1:][:HODGEPODGE_DROP_ASCENT], call, KIND) {
				rest = i + 1
				break scan
			}
		}
		// A pop can set aside more than a block.
		for sc >= b {
			copy(a[blocks*b:][:b], ss[:b])
			spike_blocks[blocks>>6] |= 1 << uint(blocks&63)
			blocks += 1
			copy(ss, ss[b:sc])
			sc -= b
		}
	}

	// The stages follow the blocks: spikes, kept items, lows.
	tail := blocks*b
	copy(a[tail:][:sc], ss[:sc])
	copy(a[tail+sc:][:kc], ks[:kc])
	copy(a[tail+sc+kc:][:lc], ls[:lc])

	// Puts the blocks in order, spikes, kept items, then lows, following each cycle through two blocks of the buffer.
	words := (blocks+63) / 64
	spike_ranks, kept_ranks: [WORDS]int = ---, ---
	spike_count := hodgepodge_word_ranks(spike_ranks[:], spike_blocks[:words])
	kept_count  := hodgepodge_word_ranks(kept_ranks[:],  kept_blocks[:words])
	destination :: #force_inline proc(t, spike_count, kept_count: int, spike_blocks, kept_blocks: []u64, spike_ranks, kept_ranks: []int) -> int {
		rs, is_spike := hodgepodge_bit_rank(spike_blocks, spike_ranks, t)
		rk, is_kept  := hodgepodge_bit_rank(kept_blocks,  kept_ranks,  t)
		switch {
		case is_spike: return rs
		case is_kept:  return spike_count + rk
		case:          return spike_count + kept_count + t - rs - rk
		}
	}
	placed: [WORDS]u64
	for start in 0..<blocks {
		if placed[start>>6] & (1 << uint(start&63)) != 0 {
			continue
		}
		placed[start>>6] |= 1 << uint(start&63)
		d := destination(start, spike_count, kept_count, spike_blocks[:], kept_blocks[:], spike_ranks[:], kept_ranks[:])
		if d == start {
			continue
		}

		carry, spare := s[:b], s[b:][:b]
		copy(carry, a[start*b:][:b])
		for d != start {
			placed[d>>6] |= 1 << uint(d&63)
			copy(spare, a[d*b:][:b])
			copy(a[d*b:][:b], carry)
			carry, spare = spare, carry
			d = destination(d, spike_count, kept_count, spike_blocks[:], kept_blocks[:], spike_ranks[:], kept_ranks[:])
		}
		copy(a[start*b:][:b], carry)
	}

	// The spikes' and kept items' stages move up behind their blocks.
	low_count := blocks - spike_count - kept_count
	spikes = spike_count*b + sc
	kept   = kept_count*b + kc
	if sc > 0 && kept_count+low_count > 0 {
		hodgepodge_trinity_rotation(a[spike_count*b:tail+sc], s, (kept_count+low_count)*b)
	}
	if kc > 0 && low_count > 0 {
		hodgepodge_trinity_rotation(a[spikes+kept_count*b:tail+sc+kc], s, low_count*b)
	}
	return
}

// Drop-merge for huge elements, which cost more to move than to compare and of which few fit the buffer. Kept items
// stay where they are, and the set-aside items are noted by their offsets from the segment's start, in the bytes of
// s[1:]. A segment ends where its notes fill up or their offsets would not fit, and sorts by one permutation
// (hodgepodge_notes_sort), every item moving at most once. Segments run long, and the scan keeps the rules of
// hodgepodge_drop_split: those of hodgepodge_drop_merge stop them early.
@(require_results)
hodgepodge_drop_notes :: #force_no_inline proc(a, s: []$E, call: $P, $KIND: Sort_Kind) -> (rest: int) #no_bounds_check {
	NEW_RUN :: HODGEPODGE_DROP_NEW_RUN
	SPIKES  :: HODGEPODGE_DROP_SPIKES

	words := hodgepodge_words(s, u16)
	room  := len(words) / 3
	notes := Hodgepodge_Notes{words[:room], words[room:][:room], words[2*room:][:room]}
	first_notes :: proc "contextless" (notes: Hodgepodge_Notes, h: int) -> Hodgepodge_Notes {
		return {notes.at[:h], notes.order[:h], notes.ranks[:h]}
	}
	// The places of the last len(out) kept items before i, last first.
	kept_back :: proc "contextless" (at: []u16, base, i: int, out: []int) {
		u := len(at) - 1
		p := i - 1
		for t := 0; t < len(out); p -= 1 {
			if u >= 0 && base + int(at[u] &~ HODGEPODGE_NOTE_MARK) == p {
				u -= 1
				continue
			}
			out[t] = p
			t += 1
		}
	}

	n := len(a)
	base, k, h, lows, streak := 0, 0, 0, 0, 0
	// The last kept item, and the greatest low: every kept item after it must be above it.
	last_kept, max_low := 0, 0
	for i in 0..<n {
		if i-base == HODGEPODGE_NOTE_SPAN {
			hodgepodge_notes_sort(a[base:i], s, first_notes(notes, h), call, KIND)
			base, k, h, lows, streak = i, 0, 0, 0, 0
		}
		if k == 0 || !hodgepodge_greater(a[last_kept], a[i], call, KIND) {
			k += 1
			last_kept = i
			streak = 0
			continue
		}
		if h+NEW_RUN > room {
			hodgepodge_notes_sort(a[base:i], s, first_notes(notes, h), call, KIND)
			base, k, h, lows, streak, last_kept = i, 1, 0, 0, 0, i
			continue
		}

		// kept[t] is the (t+1)-th last kept item. The last c kept items are above x, and x fits after the one before
		// them, within the last NEW_RUN.
		kept: [NEW_RUN]int
		reach := builtin.min(k, NEW_RUN)
		kept_back(notes.at[:h], base, i, kept[:reach])
		c := 1
		for c <= SPIKES && c < k && hodgepodge_greater(a[kept[c]], a[i], call, KIND) {
			c += 1
		}
		fits := c < k
		if c > SPIKES && fits {
			not_above := 0
			for t := reach-1; t >= c && !hodgepodge_greater(a[kept[t]], a[i], call, KIND); t -= 1 {
				not_above += 1
			}
			c    = reach - not_above
			fits = not_above > 0
		}
		first := c == k
		guard := lows == 0 || hodgepodge_greater(a[i], a[max_low], call, KIND)
		most  := SPIKES if streak < HODGEPODGE_DROP_STREAK else NEW_RUN-1

		switch {
		case (fits || first) && guard && c <= most && i+1 < n && hodgepodge_greater(a[kept[c-1]], a[i+1], call, KIND):
			// The kept items above x, and above the next item too, are the odd ones out: each is noted as a spike,
			// in order among the notes after it.
			for t in 0..<c {
				offset := u16(kept[t] - base)
				u := h
				for u > 0 && notes.at[u-1] &~ HODGEPODGE_NOTE_MARK > offset {
					notes.at[u] = notes.at[u-1]
					u -= 1
				}
				notes.at[u] = offset | HODGEPODGE_NOTE_MARK
				h += 1
			}
			k -= c - 1
			last_kept = i
			streak = 0
		case guard && (first || fits && hodgepodge_greater(a[i], a[kept[c]], call, KIND)):
			notes.at[h] = u16(i - base) | HODGEPODGE_NOTE_MARK
			h += 1
			streak += 1
		case:
			if lows == 0 || hodgepodge_greater(a[i], a[max_low], call, KIND) {
				max_low = i
			}
			notes.at[h] = u16(i - base)
			h += 1
			lows += 1
			streak += 1
			// A new run below the kept items, as in hodgepodge_drop_merge.
			if lows%NEW_RUN == 0 && k >= NEW_RUN && i+HODGEPODGE_OUT < n &&
			   hodgepodge_greater(a[kept[NEW_RUN-1]], a[i+HODGEPODGE_DROP_ASCENT], call, KIND) &&
			   hodgepodge_is_sorted(a[i:][:HODGEPODGE_DROP_ASCENT+1], call, KIND) {
				hodgepodge_notes_sort(a[base:i+1], s, first_notes(notes, h), call, KIND)
				return i + 1
			}
		}
	}
	hodgepodge_notes_sort(a[base:], s, first_notes(notes, h), call, KIND)
	if base > 0 {
		hodgepodge_power_merge(a, s, call, KIND)
	}
	return n
}

// Sorts segment r of hodgepodge_drop_notes by one permutation: its kept items are in order, and `notes` holds where the
// others are. The set-aside items sort by their notes and rank among the kept items, and then every item moves at most
// once.
hodgepodge_notes_sort :: proc(r, s: []$E, notes: Hodgepodge_Notes, call: $P, $KIND: Sort_Kind) #no_bounds_check {
	h := len(notes.at)
	if h == 0 {
		return
	}
	place :: #force_inline proc "contextless" (at: []u16, u: u16) -> int {
		return int(at[u] &~ HODGEPODGE_NOTE_MARK)
	}

	// The set-aside items in order, by a merge sort of their notes with `ranks` as the spare. Equal items keep the
	// order of their notes, which is their input order.
	for u in 0..<h {
		notes.order[u] = u16(u)
	}
	from, to := notes.order, notes.ranks
	for width := 1; width < h; width *= 2 {
		for lo := 0; lo < h; lo += 2*width {
			mid := builtin.min(lo + width, h)
			hi  := builtin.min(lo + 2*width, h)
			i, j, o := lo, mid, lo
			for i < mid && j < hi {
				right := hodgepodge_greater(r[place(notes.at, from[i])], r[place(notes.at, from[j])], call, KIND)
				to[o] = from[j] if right else from[i]
				j += int(right)
				i += int(!right)
				o += 1
			}
			copy(to[o:], from[i:mid])
			copy(to[o+mid-i:], from[j:hi])
		}
		from, to = to, from
	}
	copy(notes.order, from)

	// Each set-aside item's rank among the kept items: spikes go in front of equal kept items, the others behind.
	kept, skipped := 0, 0
	for t in 0..<h {
		x := place(notes.at, notes.order[t])
		spike := notes.at[notes.order[t]] & HODGEPODGE_NOTE_MARK != 0
		for kept < len(r)-h {
			if skipped < h && place(notes.at, u16(skipped)) == kept+skipped {
				skipped += 1
				continue
			}
			y := kept + skipped
			in_front := hodgepodge_greater(r[x], r[y], call, KIND) if spike else !hodgepodge_greater(r[y], r[x], call, KIND)
			if !in_front {
				break
			}
			kept += 1
		}
		notes.ranks[t] = u16(kept)
	}
	for &offset in notes.at {
		offset &~= HODGEPODGE_NOTE_MARK
	}
	hodgepodge_follow_cycles(r, s, notes)
}

// Sorts input sorted apart from items scattered through it, and returns where the sorted part ends, or -1 where neither
// drop-merge suits. While the set-aside items, about one per descent the quarter scan has `seen`, fit
// HODGEPODGE_DROP_SEGMENTS buffers, drop-merge's single pass costs least. More of them take the split, whose spikes and
// lows sort on their own and merge with the kept items. A radix sort beats both at fewer descents than the partition
// does. Huge elements take hodgepodge_drop_notes. It stays out of line: inlined into hodgepodge_analyse, it slows the
// routes that do not take it.
@(require_results)
hodgepodge_drop_route :: #force_no_inline proc(a, s: []$E, seen: int, call: $P, $KIND: Sort_Kind) -> (rest: int) #no_bounds_check {
	RADIX          :: KIND in HODGEPODGE_ORDERED_KINDS && intrinsics.type_is_integer(E) &&
	                  intrinsics.type_is_endian_platform(E)
	DROP_DESCENTS  :: HODGEPODGE_RADIX_DESCENTS when RADIX else HODGEPODGE_DROP_DESCENTS
	SPLIT_DESCENTS :: HODGEPODGE_SPLIT_RADIX when RADIX else HODGEPODGE_SPLIT_DESCENTS

	descents := hodgepodge_sample_descents(a, call, KIND)
	when size_of(E) > HODGEPODGE_HUGE_BYTES {
		return hodgepodge_drop_notes(a, s, call, KIND) if descents < DROP_DESCENTS else -1
	} else {
		switch {
		case descents < DROP_DESCENTS && seen <= HODGEPODGE_DROP_SEGMENTS*len(s):
			return hodgepodge_drop_merge(a, s, call, KIND)
		case descents < SPLIT_DESCENTS && len(a) <= HODGEPODGE_BLOCKS*hodgepodge_split_block(len(s)):
			spikes, kept: int
			rest, spikes, kept = hodgepodge_drop_split(a, s, call, KIND)
			for part in ([2][]E{a[:spikes], a[spikes+kept:rest]}) {
				if len(part) <= HODGEPODGE_OUT {
					if len(part) > 1 {
						hodgepodge_quadsort(part, s, call, KIND)
					}
				} else {
					when RADIX {
						hodgepodge_radix_sort(part, s, call, KIND)
					} else {
						hodgepodge_partition(part, s, call, KIND)
					}
				}
			}
			// Spikes go in front of the kept items they equal, and lows behind: merges take the left side's item
			// on a tie.
			if spikes > 0 {
				hodgepodge_rotate_merge_block(a[:spikes+kept], s, spikes, kept, call, KIND)
			}
			if spikes+kept < rest {
				hodgepodge_rotate_merge_block(a[:rest], s, spikes+kept, rest-spikes-kept, call, KIND)
			}
			return
		case descents < DROP_DESCENTS:
			return hodgepodge_drop_merge(a, s, call, KIND)
		}
		return -1
	}
}

// The end of the natural run at `start`: non-descending, or strictly descending and then reversed.
@(require_results)
hodgepodge_natural_run :: proc(a: []$E, start: int, call: $P, $KIND: Sort_Kind) -> int #no_bounds_check {
	n   := len(a)
	end := start + 1
	if end == n {
		return end
	}
	if hodgepodge_greater(a[start], a[end], call, KIND) {
		for end < n-1 && hodgepodge_greater(a[end], a[end+1], call, KIND) {
			end += 1
		}
		hodgepodge_reverse(a[start:end+1])
	} else {
		for end < n-1 && !hodgepodge_greater(a[end], a[end+1], call, KIND) {
			end += 1
		}
	}
	return end + 1
}

// Merges the natural runs of `a` in the order of Powersort (Munro and Wild, "Nearly-Optimal Mergesorts: Fast, Practical
// Sorting Methods That Optimally Adapt to Existing Runs", 2018): a boundary between two runs merges before any of
// higher power. Where no run of HODGEPODGE_RUN_MIN items starts, that many items make an unsorted run, after the lazy
// runs of Glidesort (Orson Peters, 2023). Unsorted runs merge by joining, and are sorted only when they meet a sorted
// run, or at the end.
hodgepodge_power_merge :: proc(a, s: []$E, call: $P, $KIND: Sort_Kind) #no_bounds_check {
	// The first bit in which the midpoints of runs [s1, s1+n1) and [s1+n1, s1+n1+n2) differ, as fractions of n.
	power :: proc "contextless" (s1, n1, n2, n: int) -> int {
		x := u64(((2*u128(s1) + u128(n1)) << 63) / u128(n))
		y := u64(((2*u128(s1) + 2*u128(n1) + u128(n2)) << 63) / u128(n))
		return int(intrinsics.count_leading_zeros(x ~ y))
	}

	Run :: struct {
		start, end, power: int,
		sorted:            bool,
	}

	next_run :: proc(a: []E, start: int, call: P) -> Run {
		end := hodgepodge_natural_run(a, start, call, KIND)
		if end-start >= HODGEPODGE_RUN_MIN {
			return {start, end, 0, true}
		}
		return {start, builtin.min(start + HODGEPODGE_RUN_MIN, len(a)), 0, false}
	}

	sort_run :: proc(a, s: []E, call: P) {
		when size_of(E) > HODGEPODGE_HUGE_BYTES {
			hodgepodge_large_element_sort(a, s, call, KIND)
		} else {
			if len(a) <= HODGEPODGE_OUT {
				hodgepodge_quadsort(a, s, call, KIND)
			} else {
				hodgepodge_partition(a, s, call, KIND)
			}
		}
	}

	merge :: proc(a, s: []E, left, right: Run, call: P) -> Run {
		if !left.sorted && !right.sorted {
			return {left.start, right.end, 0, false}
		}
		if !left.sorted {
			sort_run(a[left.start:left.end], s, call)
		}
		if !right.sorted {
			sort_run(a[right.start:right.end], s, call)
		}
		hodgepodge_rotate_merge_block(a[left.start:right.end], s, left.end-left.start, right.end-left.end, call, KIND)
		return {left.start, right.end, 0, true}
	}

	// Powers on the stack strictly increase, and there are 64 of them.
	stack: [64]Run
	top := 0
	n   := len(a)
	run := next_run(a, 0, call)
	for {
		// Past the last run, everything left on the stack merges.
		next: Run
		power_here := -1
		if run.end < n {
			next       = next_run(a, run.end, call)
			power_here = power(run.start, run.end-run.start, next.end-run.end, n)
		}
		for top > 0 && stack[top-1].power > power_here {
			top -= 1
			run = merge(a, s, stack[top], run, call)
		}
		if run.end == n {
			if !run.sorted {
				sort_run(a[run.start:run.end], s, call)
			}
			return
		}
		run.power = power_here
		stack[top] = run
		top += 1
		run = next
	}
}

@(require_results)
hodgepodge_binary_median :: proc(pa, pb: []$E, length: int, call: $P, $KIND: Sort_Kind) -> E #no_bounds_check {
	a := 0
	b := 0

	for l := length / 2; l > 0; l /= 2 {
		if hodgepodge_greater(pa[a+l], pb[b+l], call, KIND) {
			b += l
		} else {
			a += l
		}
	}

	if hodgepodge_greater(pa[a], pb[b], call, KIND) {
		return pa[a]
	}
	return pb[b]
}

hodgepodge_trim_four :: proc(p: []$E, call: $P, $KIND: Sort_Kind) #no_bounds_check {
	x := int(hodgepodge_greater(p[0], p[1], call, KIND))
	t := p[1-x]
	p[0] = p[x]
	p[1] = t

	x = int(hodgepodge_greater(p[2], p[3], call, KIND))
	t = p[3-x]
	p[2] = p[2+x]
	p[3] = t

	x = int(!hodgepodge_greater(p[0], p[2], call, KIND)) * 2
	p[2] = p[x]

	x = int(hodgepodge_greater(p[1], p[3], call, KIND)) * 2
	p[1] = p[1+x]
}

@(require_results)
hodgepodge_median_of_nine :: proc(a, s: []$E, call: $P, $KIND: Sort_Kind) -> E #no_bounds_check {
	step := len(a) / 9
	for k in 0..<9 {
		s[k] = a[k*step]
	}

	hodgepodge_trim_four(s[0:4], call, KIND)
	hodgepodge_trim_four(s[4:8], call, KIND)

	s[0] = s[5]
	s[3] = s[8]
	hodgepodge_trim_four(s[0:4], call, KIND)

	s[0] = s[6]
	x := hodgepodge_greater(s[0], s[1], call, KIND)
	y := hodgepodge_greater(s[0], s[2], call, KIND)
	z := hodgepodge_greater(s[1], s[2], call, KIND)
	return s[int(x == y) + int(y ~ z)]
}

@(require_results)
hodgepodge_median_of_cbrt :: proc(a, s: []$E, call: $P, $KIND: Sort_Kind) -> (pivot: E, all_equal: bool) #no_bounds_check {
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
		hodgepodge_trim_four(s[pa:pa+4], call, KIND)
		hodgepodge_trim_four(s[pb:pb+4], call, KIND)
		s[pa]   = s[pb+1]
		s[pa+3] = s[pb+2]
		pa += 4
		pb += 4
	}

	quarter := cbrt / 4
	hodgepodge_quadsort(s[0:quarter],         s[quarter*2:quarter*3], call, KIND)
	hodgepodge_quadsort(s[quarter:quarter*2], s[quarter*2:quarter*3], call, KIND)

	all_equal = !hodgepodge_greater(s[quarter*2-1], s[0], call, KIND)
	pivot     = hodgepodge_binary_median(s[0:quarter], s[quarter:quarter*2], quarter, call, KIND)
	return
}

// The partition moves four 32-bit items at a time with a 16-byte `simd_runtime_swizzle`, where that is one instruction:
// SSSE3 on x86 (x86-64-v2, the default, has it), NEON on ARM, and simd128 on wasm.
// Elsewhere the swizzle is emulated a lane at a time, several times slower than the scalar loop.
HODGEPODGE_PARTITION_SIMD :: (ODIN_ARCH == .amd64  || ODIN_ARCH == .i386)      && intrinsics.has_target_feature("ssse3") ||
                         (ODIN_ARCH == .arm64  || ODIN_ARCH == .arm32)     && intrinsics.has_target_feature("neon")  ||
                         (ODIN_ARCH == .wasm32 || ODIN_ARCH == .wasm64p32) && intrinsics.has_target_feature("simd128")

// For each mask of four lanes, the byte shuffle that moves the masked lanes to the front, in order, and the others after them.
@(rodata)
hodgepodge_lane_shuffles := [16]#simd[16]u8{
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
hodgepodge_partition_lanes :: #force_inline proc(src, lows, highs: ^$E, pivot: E, call: $P, $KIND: Sort_Kind, $FRONT: Hodgepodge_Front, $LANES: int) -> int #no_bounds_check {
	when LANES == 1 {
		item := src^
		keep := hodgepodge_in_front(item, pivot, call, KIND, FRONT)
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
		intrinsics.unaligned_store((^#simd[16]u8)(lows),  intrinsics.simd_runtime_swizzle(bytes, hodgepodge_lane_shuffles[mask]))
		intrinsics.unaligned_store((^#simd[16]u8)(highs), intrinsics.simd_runtime_swizzle(bytes, hodgepodge_lane_shuffles[mask ~ 0xF]))
		return int(intrinsics.count_ones(mask))
	}
}

// Moves the items FRONT selects to the front, keeping their order and that of the rest.
@(require_results)
hodgepodge_stable_partition :: proc(a, s: []$E, pivot: E, call: $P, $KIND: Sort_Kind, $FRONT: Hodgepodge_Front) -> (count: int) #no_bounds_check {
	// Integers come here from hodgepodge_radix_sort when they have few distinct values.
	NUMERIC :: (intrinsics.type_is_integer(E) || intrinsics.type_is_float(E)) && intrinsics.type_is_endian_platform(E)
	LANES   :: 4 when HODGEPODGE_PARTITION_SIMD && KIND in HODGEPODGE_ORDERED_KINDS && NUMERIC && size_of(E) == 4 else 1

	n := len(a)
	if n <= len(s) {
		// Scalar items stay in a plain `k < n` loop. LLVM cannot count the trips of `k+1 <= n` without nsw.
		k := 0
		when LANES > 1 {
			for /**/; k+LANES <= n; k += LANES {
				count += hodgepodge_partition_lanes(&a[k], &a[count], &s[k-count], pivot, call, KIND, FRONT, LANES)
			}
		}
		for /**/; k < n; k += 1 {
			count += hodgepodge_partition_lanes(&a[k], &a[count], &s[k-count], pivot, call, KIND, FRONT, 1)
		}
		copy(a[count:n], s[:n-count])
		return
	}
	// Up to HODGEPODGE_PARTITION_HALVES levels of halving and rotating are cheaper than the block passes.
	// A block leaves the rest of its half of the buffer for what one step carries past it.
	block := len(s)/2 - (LANES-1)
	if n > len(s) << HODGEPODGE_PARTITION_HALVES && block >= LANES && n <= HODGEPODGE_BLOCKS*block {
		return hodgepodge_block_partition(a, s, block, pivot, call, KIND, FRONT, LANES)
	}

	half  := n / 2
	left  := hodgepodge_stable_partition(a[:half], s, pivot, call, KIND, FRONT)
	right := hodgepodge_stable_partition(a[half:], s, pivot, call, KIND, FRONT)
	hodgepodge_trinity_rotation(a[left:half+right], s, half-left)
	return left + right
}

// Each half of the buffer collects one side and is written back as a whole block of `b` items once full, into the part of `a` already read.
// The blocks are then put in order. Every item moves a fixed number of times, not once per level of halving.
@(require_results)
hodgepodge_block_partition :: proc(a, s: []$E, b: int, pivot: E, call: $P, $KIND: Sort_Kind, $FRONT: Hodgepodge_Front, $LANES: int) -> (count: int) #no_bounds_check {
	WORDS :: HODGEPODGE_BLOCKS / 64

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
			kept := hodgepodge_partition_lanes(&a[k], &lows[nl], &highs[nh], pivot, call, KIND, FRONT, LANES)
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
			kept := hodgepodge_partition_lanes(&a[k], &lows[nl], &highs[nh], pivot, call, KIND, FRONT, 1)
			nl += kept
			nh += 1 - kept
		}
	} else {
		for /**/; k < n; k += 1 {
			kept := hodgepodge_partition_lanes(&a[k], &lows[nl], &highs[nh], pivot, call, KIND, FRONT, 1)
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

	ranks: [WORDS]int = ---
	low_count := hodgepodge_word_ranks(ranks[:], low_blocks[:(blocks+63)/64])

	destination :: #force_inline proc(i: int, low_blocks: []u64, ranks: []int, low_count: int) -> int {
		below, low := hodgepodge_bit_rank(low_blocks, ranks, i)
		return below if low else low_count + i - below
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

	hodgepodge_trinity_rotation(a[low_count*b:tail+nl], s, (blocks-low_count)*b)
	return low_count*b + nl
}

// Small buckets of 4-byte integers sort with a network in 4-lane vectors, where unsigned 32-bit min and max are one
// instruction: SSE4.1 on x86, NEON on ARM, and simd128 on wasm.
HODGEPODGE_RADIX_SIMD :: (ODIN_ARCH == .amd64  || ODIN_ARCH == .i386)      && intrinsics.has_target_feature("sse4.1") ||
                         (ODIN_ARCH == .arm64  || ODIN_ARCH == .arm32)     && intrinsics.has_target_feature("neon")   ||
                         (ODIN_ARCH == .wasm32 || ODIN_ARCH == .wasm64p32) && intrinsics.has_target_feature("simd128")

// Sorts N keys with Batcher's bitonic sorting network, four to a vector.
// Lanes i and i~J compare at each step, the smaller going first unless i&K.
// Steps across vectors take lane-wise mins and maxes. Steps within one swap lanes, and each lane keeps the min or the max.
hodgepodge_lane_network :: proc "contextless" (keys: ^[$N]u32) #no_bounds_check {
	V :: #simd[4]u32
	LANE :: V{0, 1, 2, 3}

	step :: #force_inline proc "contextless" (v: ^[N/4]V, $K, $J: int) {
		when J >= 4 {
			#unroll for r in 0..<N/4 {
				p := r ~ J/4
				if r < p {
					lo := intrinsics.simd_min(v[r], v[p])
					hi := intrinsics.simd_max(v[r], v[p])
					if 4*r & K == 0 {
						v[r], v[p] = lo, hi
					} else {
						v[r], v[p] = hi, lo
					}
				}
			}
		} else {
			#unroll for r in 0..<N/4 {
				when J == 2 {
					t := intrinsics.simd_shuffle(v[r], v[r], 2, 3, 0, 1)
				} else {
					t := intrinsics.simd_shuffle(v[r], v[r], 1, 0, 3, 2)
				}
				upper := intrinsics.simd_lanes_ne(LANE & V(J), V{})
				desc  := intrinsics.simd_lanes_ne((LANE + V(4*r)) & V(K), V{})
				v[r] = intrinsics.simd_select(upper ~ desc, intrinsics.simd_max(v[r], t), intrinsics.simd_min(v[r], t))
			}
		}
		when J > 1 {
			step(v, K, J/2)
		}
	}
	stage :: #force_inline proc "contextless" (v: ^[N/4]V, $K: int) {
		step(v, K, K/2)
		when K < N {
			stage(v, K*2)
		}
	}

	v := transmute([N/4]V)keys^
	stage(&v, 2)
	keys^ = transmute([N]u32)v
}

// Sorts a radix sort's small bucket of 4-byte integers as their unsigned keys `K(x) ~ FLIP` with a network. Unused
// lanes take the largest key. Equal integers are the same bits: the padding cannot be told from a real key.
hodgepodge_radix_network :: #force_no_inline proc(a: []$E, $FLIP: u32) #no_bounds_check {
	sort :: #force_inline proc(a: []E, $N: int) #no_bounds_check {
		keys: [N]u32 = ---
		for x, i in a {
			keys[i] = transmute(u32)x ~ FLIP
		}
		for i in len(a)..<N {
			keys[i] = builtin.max(u32)
		}
		hodgepodge_lane_network(&keys)
		for &x, i in a {
			x = transmute(E)(keys[i] ~ FLIP)
		}
	}
	switch n := len(a); {
	case n <= 16:
		sort(a, 16)
	case n <= 32:
		sort(a, 32)
	case:
		sort(a, 64)
	}
}

// An in-place MSD radix sort, the American flag sort of McIlroy, Bostic and McIlroy, "Engineering Radix Sort" (1993).
// It is unstable, but equal integers are the same bits: the result is exactly what a stable sort gives.
hodgepodge_radix_sort :: proc(a, s: []$E, call: $P, $KIND: Sort_Kind) #no_bounds_check {
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
	if n <= HODGEPODGE_RADIX_SMALL {
		when HODGEPODGE_RADIX_SIMD && size_of(E) == 4 {
			if n >= HODGEPODGE_RADIX_NETWORK {
				hodgepodge_radix_network(a, u32(FLIP))
				return
			}
		}
		hodgepodge_quadsort(a, s, call, KIND)
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
	top   := uint(8*size_of(K) - 1 - int(intrinsics.count_leading_zeros(differ)))
	shift := top &~ 7

	// Few distinct keys make the in-place cycle a poor buy: each pass costs several partition passes and splits only a
	// few ways. A sample of the eight highest differing bits shows them. With lanes the partition is cheap enough to take
	// more of them at any size, and without only once the cycle misses the cache. The last byte takes the counting fill.
	LANES    :: HODGEPODGE_PARTITION_SIMD && size_of(E) == 4
	FEW      :: HODGEPODGE_RADIX_FEW_LANES when LANES else HODGEPODGE_RADIX_FEW
	FEW_FROM :: 0 when LANES else HODGEPODGE_RADIX_FEW_BYTES / size_of(E)
	if shift > 0 && n > len(s) && n > FEW_FROM {
		seen: [4]u64
		for i in 0..<256 {
			d := digit(a[int(i64(i)*i64(n)/256)], top - 7)
			seen[d >> 6] |= 1 << uint(d & 63)
		}
		used := 0
		for w in seen {
			used += int(intrinsics.count_ones(w))
		}
		if used <= FEW {
			hodgepodge_partition(a, s, call, KIND)
			return
		}
	}

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
			hodgepodge_radix_sort(a[start:end], s, call, KIND)
		}
		start = end
	}
}

hodgepodge_partition :: proc(a, s: []$E, call: $P, $KIND: Sort_Kind) #no_bounds_check {
	n := len(a)

	pivot, previous_pivot: E
	has_previous := false

	for {
		if n <= 2048 {
			pivot = hodgepodge_median_of_nine(a[:n], s, call, KIND)
		} else {
			all_equal: bool
			pivot, all_equal = hodgepodge_median_of_cbrt(a[:n], s, call, KIND)
			if all_equal {
				hodgepodge_quadsort(a[:n], s, call, KIND)
				return
			}
		}

		// Partitioning on .Less leaves only items equal to the pivot on the high side, which needs no sorting.
		equal_high := has_previous && !hodgepodge_greater(previous_pivot, pivot, call, KIND)
		low_count := 0
		if !equal_high {
			low_count  = hodgepodge_stable_partition(a[:n], s, pivot, call, KIND, .Not_Greater)
			equal_high = low_count == n
		}
		if equal_high {
			low_count = hodgepodge_stable_partition(a[:n], s, pivot, call, KIND, .Less)
		}
		high_count := n - low_count

		if !equal_high {
			if low_count <= high_count/16 || high_count <= HODGEPODGE_OUT {
				hodgepodge_quadsort(a[low_count:n], s, call, KIND)
			} else {
				hodgepodge_partition(a[low_count:n], s, call, KIND)
			}
		}

		if high_count <= low_count/16 || low_count <= HODGEPODGE_OUT {
			hodgepodge_quadsort(a[:low_count], s, call, KIND)
			return
		}
		n = low_count
		previous_pivot = pivot
		has_previous = !equal_high
	}
}

hodgepodge_analyse :: proc(a, s: []$E, call: $P, $KIND: Sort_Kind) #no_bounds_check {
	// Integers in their own order take a radix sort where a partition would go. Single bytes need one
	// counting pass, which beats any use of the order already there.
	RADIX :: KIND in HODGEPODGE_ORDERED_KINDS && intrinsics.type_is_integer(E) && intrinsics.type_is_endian_platform(E)
	// Where a comparison is a call, not a few inlined instructions, a quarter with order in it merges its natural runs
	// instead of being sorted in fixed blocks, and input sorted at large scale merges its natural runs: fewer
	// comparisons, and merges that follow the data.
	CHEAP :: KIND in HODGEPODGE_ORDERED_KINDS && !intrinsics.type_is_string(E) || KIND in HODGEPODGE_CONSTANT_KINDS
	when RADIX && size_of(E) == 1 {
		hodgepodge_radix_sort(a, s, call, KIND)
		return
	}
	when RADIX {
		unordered :: hodgepodge_radix_sort
	} else when size_of(E) > HODGEPODGE_HUGE_BYTES {
		// The partition's samples take more buffer than fits of huge elements.
		unordered :: hodgepodge_large_element_sort
	} else {
		unordered :: hodgepodge_partition
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
				sum[k] += int(hodgepodge_greater(q[i], q[i+1], call, KIND))
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
			balance[k] += int(hodgepodge_greater(a[bounds[k]+i], a[bounds[k]+i+1], call, KIND))
		}
		i += 1
	}

	for k in 1..<4 {
		if bounds[k+1]-bounds[k] > quad1 {
			balance[k] += int(hodgepodge_greater(a[bounds[k]+i], a[bounds[k]+i+1], call, KIND))
		}
	}

	no_descents := balance == [4]int{}
	if no_descents &&
	   !hodgepodge_greater(a[bounds[1]-1], a[bounds[1]], call, KIND) &&
	   !hodgepodge_greater(a[bounds[2]-1], a[bounds[2]], call, KIND) &&
	   !hodgepodge_greater(a[bounds[3]-1], a[bounds[3]], call, KIND) {
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
		for end < 4 && reversed[end] && hodgepodge_greater(a[bounds[end]-1], a[bounds[end]], call, KIND) {
			end += 1
		}

		hodgepodge_reverse(a[bounds[k]:bounds[end]])
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

	// Items scattered through every quarter take drop-merge. Where a quarter has no descents, the disorder is local
	// and the quarters sort only where it is.
	none_ordered := ordered == [4]bool{}
	rest := -1
	if builtin.min(balance[0], balance[1], balance[2], balance[3]) > 0 {
		rest = hodgepodge_drop_route(a, s, balance[0]+balance[1]+balance[2]+balance[3], call, KIND)
	}
	if rest >= 0 {
		// Where drop-merge stops, the rest sorts the way its quarters would and merges with what it sorted. Without
		// order in the quarters, sorting all of it again costs less before n/HODGEPODGE_DROP_EARLY. With order in them,
		// calls merge the natural runs from the sorted part on, and cheap comparisons take the quarter path below:
		// every quarter has descents and sorts whatever drop-merge left in it.
		if rest == n {
			return
		}
		if none_ordered {
			if rest < n/HODGEPODGE_DROP_EARLY {
				unordered(a, s, call, KIND)
			} else {
				unordered(a[rest:], s, call, KIND)
				hodgepodge_power_merge(a, s, call, KIND)
			}
			return
		}
		when !CHEAP {
			hodgepodge_power_merge(a, s, call, KIND)
			return
		}
	}

	if none_ordered {
		when !CHEAP {
			// Merging runs of keys from all over interleaves them, and the partition does that for less. Runs of keys
			// near their place barely overlap.
			if n >= HODGEPODGE_FAR_FROM && hodgepodge_sorted_at_scale(a, call, KIND) {
				hodgepodge_power_merge(a, s, call, KIND)
				return
			}
		}
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
			when CHEAP {
				hodgepodge_quadsort(a[bounds[k]:bounds[k+1]], s, call, KIND)
			} else {
				hodgepodge_power_merge(a[bounds[k]:bounds[k+1]], s, call, KIND)
			}
		}
	}

	switch {
	case hodgepodge_greater(a[quad1-1], a[quad1], call, KIND):
		hodgepodge_rotate_merge_block(a[0:half1], s, quad1, half1-quad1, call, KIND)
		if hodgepodge_greater(a[half1+quad3-1], a[half1+quad3], call, KIND) {
			hodgepodge_rotate_merge_block(a[half1:n], s, quad3, half2-quad3, call, KIND)
		}

	case hodgepodge_greater(a[half1+quad3-1], a[half1+quad3], call, KIND):
		hodgepodge_rotate_merge_block(a[half1:n], s, quad3, half2-quad3, call, KIND)

	case !hodgepodge_greater(a[half1-1], a[half1], call, KIND):
		return
	}

	hodgepodge_rotate_merge_block(a, s, half1, half2, call, KIND)
}
