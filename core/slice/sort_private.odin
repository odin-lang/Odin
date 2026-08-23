#+private
package slice

import "base:builtin"
import "base:intrinsics"
_ :: intrinsics

ORD :: intrinsics.type_is_ordered

Sort_Kind :: enum {
	Ordered,
	Less,
	Cmp,
}

_stable_sort_general :: proc(data: $T/[]$E, call: $P, $KIND: Sort_Kind) where (ORD(E) && KIND == .Ordered) || (KIND != .Ordered) #no_bounds_check {
	less :: #force_inline proc(a, b: E, call: P) -> bool {
		when KIND == .Ordered {
			return a < b
		} else when KIND == .Less {
			return call(a, b)
		} else when KIND == .Cmp {
			return call(a, b) == .Less
		} else {
			#panic("unhandled Sort_Kind")
		}
	}

	merge_rotate(data, call)

	insertion_sort :: proc(data: T, call: P) {
		for i in 1..<len(data) {
			j := i
			temp := data[j]
			for ; j > 0 && less(temp, data[j - 1], call); j -= 1 {
				data[j] = data[j - 1]
			}
			data[j] = temp
		}
	}

	merge_rotate :: proc(data: T, call: P) {
		if len(data) <= 200 {
			insertion_sort(data, call)
			return
		}

		mid := len(data) / 2
		merge_rotate(data[:mid], call)
		merge_rotate(data[mid:], call)

		merge(data, mid, len(data) - mid, call)
	}

	bin_search_left :: proc(data: T, value: E, call: P) -> (from: int) {
		n := len(data)

		for n > 0 {
			half := n / 2
			mid := from + half

			if less(data[mid], value, call) {
				from = mid + 1
				n -= half + 1
			} else {
				n = half
			}
		}

		return from
	}

	bin_search_right :: proc(data: T, value: E, call: P) -> (from: int) {
		n := len(data)

		for n > 0 {
			half := n / 2
			mid := from + half

			if less(value, data[mid], call) {
				n = half
			} else {
				from = mid + 1
				n -= half + 1
			}
		}

		return from
	}

	merge :: proc(data: T, left, right: int, call: P) {
		if left == 0 || right == 0 {
			return
		}

		if left + right == 2 {
			if less(data[1], data[0], call) {
				data[1], data[0] = data[0], data[1]
			}
			return
		} 

		first_cut, second_cut: int
		left2, right2: int

		if left > right {
			left2 = left / 2
			first_cut = left2

			second_cut = left + bin_search_left(data[left:], data[first_cut], call)
			right2 = second_cut - left
		} else {
			right2 = right / 2
			second_cut = left + right2

			first_cut = bin_search_right(data[:left], data[second_cut], call)
			left2 = first_cut
		}

		rotate_left(data[first_cut:second_cut], left - first_cut)
		new_mid := first_cut + right2

		merge(data[:new_mid], left2       , right2        , call)
		merge(data[new_mid:], left - left2, right - right2, call)
	}
}

@(private)
_generic_quicksort :: proc(data: [^]byte, length, width: uint, cmp: Generic_Cmp, arg: rawptr) {
	loop(data, int(length), int(width), cmp, arg, 0)

	loop :: proc(data: [^]byte, length, width: int, cmp: Generic_Cmp, arg: rawptr, last_piv: int) {
		if length <= 16 {
			insertion_sort(data, length, width, cmp, arg)
			return
		}

		log2 :: proc(n: int) -> (log: int) {
			for n := n; n > 0; n >>= 1 {
				log += 1
			}
			return
		}
		depth := log2(length + 16) / 5
		pivot_index := median_3(data, 0, length, width, cmp, arg, depth)

		if last_piv != 0 && cmp(data[pivot_index * width:], data[last_piv * width:], arg) == .Equal {
			left := partition_lumoto_reverse(data, length, width, cmp, arg, pivot_index)
			right := length - left
			#must_tail loop(data[left * width:], right, width, cmp, arg, 0)
			return
		} 


		left := partition_lumoto_block(data, length, width, cmp, arg, pivot_index)
		right := length - left

		if left < right {
			loop(data, left, width, cmp, arg, left)
			#must_tail loop(data[(left + 1) * width:], right - 1, width, cmp, arg, -1)
			return
		} else {
			loop(data[(left + 1) * width:], right - 1, width, cmp, arg, -1)
			#must_tail loop(data, left, width, cmp, arg, left)
			return
		}
	}

	// the worst smallsort in the history of smallsorts
	insertion_sort :: proc(data: [^]byte, length, width: int, cmp: Generic_Cmp, arg: rawptr) #no_bounds_check {
		for i in 1..<length {
			j := i
			for ; j > 0 && cmp(data[j * width:], data[(j - 1) * width:], arg) == .Less; j -= 1 {
				ptr_swap_non_overlapping(data[(j - 1) * width:], data[j * width:], width)
			}
		}
	}

	median_3 :: proc(data: [^]byte, start, end, width: int, cmp: Generic_Cmp, arg: rawptr, depth: int) -> int #no_bounds_check {
		if depth == 0 {
			return start
		}

		div := (end - start) / 3

		swap := [3]int{
			median_3(data, start          , start + div    , width, cmp, arg, depth - 1),
			median_3(data, start + div    , start + div * 2, width, cmp, arg, depth - 1),
			median_3(data, start + div * 2, end            , width, cmp, arg, depth - 1),
		}
		
		x := cmp(data[swap[0] * width:], data[swap[1] * width:], arg) == .Less
		y := cmp(data[swap[0] * width:], data[swap[2] * width:], arg) == .Less
		z := cmp(data[swap[1] * width:], data[swap[2] * width:], arg) == .Less

		return swap[(int)(x == y) + (int)(y ~ z)]
	}

	partition_lumoto_block :: proc(data: [^]byte, length, width: int, cmp: Generic_Cmp, arg: rawptr, pivot_index: int) -> (left: int) #no_bounds_check {
		if pivot_index != 0 {
			ptr_swap_non_overlapping(data[0:], data[pivot_index * width:], width)
		}
		pivot := data[0:]
		left = 1

		BLOCK_SIZE :: 64
		block : [BLOCK_SIZE]u8 = ---
		read := 1
		block_base := 1

		for {
			unkown := length - read
			less := 0
			if unkown >= BLOCK_SIZE {
				#unroll(8) for i in u8(0)..<BLOCK_SIZE {
					block[less] = i 
					less += cast(int)(cmp(data[read * width:], pivot, arg) == .Less)
					read += 1
				}
			} else {
				for i in 0..<unkown {
					block[less] = u8(i) 
					less += cast(int)(cmp(data[read * width:], pivot, arg) == .Less)
					read += 1
				}
			}
			for i in 0..<less {
				ptr_swap_non_overlapping(data[(block_base + int(block[i])) * width:], data[left * width:], width)
				left += 1
			}
			if unkown <= BLOCK_SIZE {break}
			block_base = read
			
		}

		left -= 1

		ptr_swap_non_overlapping(data[0:], data[left * width:], width)
		return left
	}

	partition_lumoto_reverse :: proc(data: [^]byte, length, width: int, cmp: Generic_Cmp, arg: rawptr, pivot_index: int) -> (right: int) #no_bounds_check {
		if pivot_index != length - 1 {
			ptr_swap_non_overlapping(data[(length - 1) * width:], data[pivot_index * width:], width)
		}
		pivot := data[(length - 1) * width:]
		right = length - 2


		for read := length - 2; read >= 0; read -= 1 {
			if cmp(data[read * width:], pivot, arg) == .Greater {
				ptr_swap_non_overlapping(data[right * width:], data[read * width:], width)
				right -= 1
			}
		}
		right += 1

		ptr_swap_non_overlapping(data[(length - 1) * width:], data[right * width:], width)

		return right
	}
}