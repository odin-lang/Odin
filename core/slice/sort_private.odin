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
_generic_quicksort :: proc(data: [^]byte, length, width: int, cmp: Generic_Cmp, arg: rawptr) {
	loop(data, length, width, cmp, arg, true, 0)

	loop :: proc(data: [^]byte, length, width: int, cmp: Generic_Cmp, arg: rawptr, leftmost: bool, unbalanced: int) {
		data := data
		length := length
		leftmost := leftmost
		unbalanced := unbalanced

		for {
			if length <= 64 {
				shell_sort(data, length, width, cmp, arg)
				return
			}

			log2 := 0
			for n := length; n > 0; n >>= 1 {
				log2 += 1
			}

			median_3_depth := log2 / 5
			rand := 0
			if unbalanced >= 3 {
				unbalanced -= 1
				rand = cast(int)intrinsics.read_cycle_counter() & (63 if length > 2048 else 3)
			}
			pivot_index := median_3(data, rand * width, length, width, cmp, arg, median_3_depth)

			if !leftmost {
				if cmp(data[pivot_index * width:], data[-width:], arg) == .Equal {
					left := partition_hoare_reverse(data, length, width, cmp, arg, pivot_index)

					data = data[left * width:]
					length = length - left
					leftmost = false
					continue
				}
			}

			left := partition_hoare(data, length, width, cmp, arg, pivot_index)
			right := length - left

			if left < right {
				loop(data, left, width, cmp, arg, leftmost, 0)
				data = data[(left + 1) * width:]
				length = right - 1
				leftmost = false
				if left < right / 32 {
					unbalanced += 1
				}
			} else {
				loop(data[(left + 1) * width:], right - 1, width, cmp, arg, false, 0)
				length = left
				if right < left / 32 {
					unbalanced += 1
				}
			}
		}
		
	}

	shell_sort :: #force_inline proc(data: [^]byte, length, width: int, cmp: Generic_Cmp, arg: rawptr) #no_bounds_check {
		if length < 2 {
			return
		}

		gaps := []int{51, 23, 10, 4, 1}

		for gap in gaps {
			for i := gap ; i < length; i += 1 {
				if !(cmp(data[(i - gap) * width:], data[i * width:], arg) == .Greater) {
					continue
				}
				j := i - gap

				for ; j >= gap && cmp(data[(j - gap) * width:], data[i * width:], arg) == .Greater; j -= gap {}
				
				buf: [256]u8 = ---
				w := width
				d := data
				for w != 0 {
					l := builtin.min(size_of(buf), w)
					copy(buf[:l], d[i*width:][:l])
					for e := i; e > j; e -= gap {
						copy(d[(e)*width:][:l], d[(e - gap)*width:][:l])
					}
					copy(d[j*width:][:l], buf[:l])
					d = d[l:]
					w -= l
				}
			}
		}
	}

	median_3 :: proc(data: [^]byte, start, end, width: int, cmp: Generic_Cmp, arg: rawptr, depth: int) -> (piv: int) #no_bounds_check {
		if depth == 0 {
			return start
		}

		div := (end - start) / 3

		swap := [3]int{
			median_3(data, start          , start + div    , width, cmp, arg, depth - 1),
			median_3(data, start + div    , start + div * 2, width, cmp, arg, depth - 1),
			median_3(data, start + div * 2, end            , width, cmp, arg, depth - 1),
		}

		x := cast(int)(cmp(data[swap[0] * width:], data[swap[1] * width:], arg) == .Less)
		y := cast(int)(cmp(data[swap[1] * width:], data[swap[2] * width:], arg) == .Less)

		switch x + 2*y {
		case 0, 3: piv = swap[1]
		case 1: 
			if cmp(data[swap[0] * width:], data[swap[2] * width:], arg) == .Less {
				piv = swap[2]
			} else {
				piv = swap[0]
			}
		case 2: 
			if cmp(data[swap[0] * width:], data[swap[2] * width:], arg) == .Less {
				piv = swap[0]
			} else {
				piv = swap[2]
			}
		}
		
		return piv
	}

	// [ < |p| >= ]
	partition_hoare :: #force_inline proc(data: [^]byte, length, width: int, cmp: Generic_Cmp, arg: rawptr, pivot_index: int) -> (left: int) {
		ptr_swap_non_overlapping(data[0:], data[pivot_index * width:], width)

		left = 1
		right := length - 1

		for { 
			for left <= right && cmp(data[left * width:], data[0:], arg) == .Less { left += 1 }
			for left <= right && cmp(data[right * width:], data[0:], arg) != .Less { right -= 1 }
			
			if left >= right {
				break
			}

			ptr_swap_non_overlapping(data[left * width:], data[right * width:], width)
			left += 1
			right -= 1
		}
		left -= 1
		ptr_swap_non_overlapping(data[0:], data[left * width:], width)

		return left
	}

	// [ <= |p| > ]
	partition_hoare_reverse :: #force_inline proc(data: [^]byte, length, width: int, cmp: Generic_Cmp, arg: rawptr, pivot_index: int) -> (left: int) {
		ptr_swap_non_overlapping(data[0:], data[pivot_index * width:], width)

		left = 1
		right := length - 1

		for {
			for left <= right && cmp(data[left * width:], data[0:], arg) != .Greater { left += 1 }
			for left <= right && cmp(data[right * width:], data[0:], arg) == .Greater { right -= 1 }

			if left >= right {
				break
			}

			ptr_swap_non_overlapping(data[left * width:], data[right * width:], width)
			left += 1
			right -= 1
		}
		left -= 1
		ptr_swap_non_overlapping(data[0:], data[left * width:], width)

		return left
	}
}