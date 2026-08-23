package sort

import "core:slice"
import "base:intrinsics"


// This sort is not guaranteed to be stable
sort_inlined :: proc(arr: $T/[]$E) where ORD(E) {
	when size_of(E) != 0 {
		if len(arr) > 1 {
			base_type :: intrinsics.type_core_type(E)
			_quick_lumoto(transmute([]base_type)arr, nil, proc(l, r: base_type, data: rawptr) -> bool { return l < r })
		}
	}
}

// WARNING: each call generates a new quicksort, only use in performance critical path
//
// This sort is not guaranteed to be stable
sort_inlined_by :: proc(arr: $T/[]$E, $LESS: proc(l, r: E) -> bool) {
	when size_of(E) != 0 {
		if len(arr) > 1 {
			_quick_lumoto(arr, nil, proc(l, r: E, data: rawptr) -> bool { return LESS(l, r) })
		}
	}
}

// This sort is not guaranteed to be stable
sort_inlined_with_indices :: proc(arr: $T/[]$E, allocator := context.allocator) -> (indices: []int) where ORD(E) {
	indices = make([]int, len(arr), allocator)
	when size_of(E) != 0 {
		if len(arr) > 1 {
			for &index, i in indices{
				index = i
			}

			base_type :: intrinsics.type_core_type(E)
			arr := transmute([]base_type)arr
			_quick_lumoto(indices, &arr, proc(l, r: int, user_data: rawptr) -> bool {
				data := (^T)(user_data)
				return data[l] < data[r]
			})

			slice.sort_from_permutation_indices(arr, indices)
		}
	}
	return indices
}

// WARNING: each call generates a new quicksort, only use in performance critical path
//
// This sort is not guaranteed to be stable
sort_inlined_by_with_indices :: proc(arr: $T/[]$E, $LESS: proc(l, r: E) -> bool, allocator := context.allocator) -> (indices: []int) {
	indices = make([]int, len(arr), allocator)

	when size_of(E) != 0 {
		if len(arr) > 1 {
			for &index, i in indices{
				index = i
			}

			arr := arr
			_quick_lumoto(indices, &arr, proc(l, r: int, user_data: rawptr) -> bool {
				data := (^T)(user_data)
				return LESS(data[l], data[r])
			})

			slice.sort_from_permutation_indices(arr, indices)
		}
	}
	return indices
}

// WARNING: each call generates a new quicksort, only use in performance critical path
//
// This sort is not guaranteed to be stable
sort_inlined_by_with_data :: proc(arr: $T/[]$E, $LESS: proc(l, r: E, user_data: rawptr) -> bool, user_data: rawptr) {
	when size_of(E) != 0 {
		if len(arr) > 1 {
			_quick_lumoto(arr, user_data, proc(l, r: E, user_data: rawptr) -> bool {
				return LESS(l, r, user_data)
			})
		}
	}
}

// WARNING: each call generates a new quicksort, only use in performance critical path
//
// This sort is not guaranteed to be stable
sort_inlined_by_with_indices_with_data :: proc(arr: $T/[]$E, $LESS: proc(l, r: E, user_data: rawptr) -> bool, user_data: rawptr, allocator := context.allocator) -> (indices: []int) {
	indices = make([]int, len(arr), allocator)
	when size_of(E) != 0 {
		if len(arr) > 1 {
			for &index, i in indices{
				index = i
			}
			
			Context :: struct {
				arr: T,
				user_data: rawptr,
			}
			arr := arr
			ctx := &Context{arr, user_data}

			_quick_lumoto(indices, ctx, proc(l, r: int, user_data: rawptr) -> bool {
				ctx := (^Context)(user_data)
				left := ctx.arr[l]
				right := ctx.arr[r]
				return LESS(left , right, ctx.user_data)
			})

			slice.sort_from_permutation_indices(arr, indices)
		}
	}
	return indices
}

// WARNING: each call generates a new quicksort, only use in performance critical path
//
// This sort is not guaranteed to be stable
sort_inlined_by_cmp :: proc(arr: $T/[]$E, $CMP: proc(l, r: E) -> slice.Ordering) {
	when size_of(E) != 0 {
		if len(arr) > 1 {
			_quick_lumoto(arr, nil, proc(l, r: E, user_data: rawptr) -> bool { return CMP(l, r) == .Less })
		}
	}
}

// WARNING: each call generates a new quicksort, only use in performance critical path
//
// This sort is not guaranteed to be stable
sort_inlined_by_cmp_with_data :: proc(arr: $T/[]$E, $CMP: proc(l, r: E, user_data: rawptr) -> slice.Ordering, user_data: rawptr) {
	when size_of(E) != 0 {
		if len(arr) > 1 {
			_quick_lumoto(arr, user_data, proc(l, r: E, user_data: rawptr) -> bool {
				return CMP(l, r, user_data) == .Less
			})
		}
	}
}


@private
_quick_lumoto :: proc(arr: $T/[]$E, data: rawptr, $LESS: $P) {
	loop(arr, data, 0)
	
	loop :: proc(arr: T, data: rawptr, last_piv: int) #no_bounds_check {
		if len(arr) <= 32 {
			insertion_sort(arr, data)
			return
		}
		
		depth := log2(len(arr)) / 5
		pivot_index := median_3(arr, data, 0, len(arr) - 1, depth)

		if last_piv != 0 && !LESS(arr[last_piv], arr[pivot_index], data) {
			left := partition_lumoto_reverse(arr, data, pivot_index)
			#must_tail loop(arr[left + 1:], data, 0)
			return
		} 

		when size_of(T) > 80 {
			left := prtition_hoare(arr, data, pivot_index)
		} else {
			left := partition_lumoto(arr, data, pivot_index)
		}
		
		right := len(arr) - left

		if left < right {
			loop(arr[:left], data, left)
			#must_tail loop(arr[left + 1:], data, -1)
			return
		} else {
			loop(arr[left + 1:], data, -1)
			#must_tail loop(arr[:left], data, left)
			return
		}
	}

	log2 :: proc(n: int) -> (log: int) {
		for n := n; n > 0; n >>= 1 {
			log += 1
		}
		return
	}

	median_3 :: proc(arr: T, data: rawptr, start, end, depth: int) -> int #no_bounds_check {
		if depth == 0 {
			return start
		}

		div := (end - start) / 3

		swap := [3]int{
			median_3(arr, data, start, start + div, depth - 1),
			median_3(arr, data, start + div, start + div * 2, depth - 1),
			median_3(arr, data, start + div * 2, end, depth - 1),
		}
		
		x := LESS(arr[swap[0]], arr[swap[1]], data)
		y := LESS(arr[swap[0]], arr[swap[2]], data)
		z := LESS(arr[swap[1]], arr[swap[2]], data)

		return swap[(int)(x == y) + (int)(y ~ z)]
	}

	insertion_sort :: #force_inline proc(arr: T, data: rawptr) #no_bounds_check {
		for i in 1..<len(arr) {
			current := arr[i]
			j := i
			for ; j > 0 && LESS(current, arr[j - 1], data); j -= 1 {
				arr[j] = arr[j - 1]
			}
			arr[j] = current
		}
	}


	// branchless partitioning
	// [  <  |0|  >=  |  ?  ]
	//	    left    right ->
	partition_lumoto :: #force_inline proc(arr: T, data: rawptr, pivot_index: int) -> (left: int) #no_bounds_check {
		pivot := arr[pivot_index]
		arr[pivot_index] = arr[0]

		j := 0
		#unroll(8) for _ in arr[:len(arr) - 1] {
			arr[j] = arr[left]
			j += 1
			arr[left] = arr[j]
			left += cast(int)LESS(arr[left], pivot, data)
		}

		arr[j] = arr[left]
		arr[left] = pivot

		return
	}

	// [  ?  |  <=  |0|  >  ]
	//   <- left   right
	partition_lumoto_reverse :: proc(arr: T, data: rawptr, pivot_index: int) -> (right: int) #no_bounds_check {
		right = len(arr) - 1

		pivot := arr[pivot_index]
		arr[pivot_index] = arr[right]

		j := right
		for j >= 1 {
			arr[j] = arr[right]
			j -= 1
			arr[right] = arr[j]
			right -= cast(int)LESS(pivot, arr[right], data)
		}

		arr[j] = arr[right]
		arr[right] = pivot

		return
	}

	// only used for large types as it uses less data moves
	// [  <=  |0|   ?   |  >  ]
	//	  ->  left    right <-
	prtition_hoare :: proc(arr: T, data: rawptr, pivot_index: int) -> (left: int) #no_bounds_check {
		right := len(arr) - 1

		pivot := arr[pivot_index]
		arr[pivot_index] = arr[0]

		for {
			for !LESS(arr[right], pivot, data) && left < right { right -= 1 }
			if left >= right {
				arr[left] = pivot
				return left 
			}
			arr[left] = arr[right]
			left += 1

			for LESS(arr[left], pivot, data) && left < right { left += 1 }
			if left >= right {
				arr[right] = pivot
				left = right
				return  
			}
			arr[right] = arr[left]
			right -= 1
		}
	}
}

