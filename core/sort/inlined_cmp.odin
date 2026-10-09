package sort

import "base:intrinsics"

Ordering :: enum {
	Less = -1,
	Equal = 0,
	Greater = 1,
}

/*
WARNING: each call generates a new quicksort, only use in performance critical path

This sort is not guaranteed to be stable

	example :: proc() {
		arr := []int{3,2,1}
		sort.sort_inlined(arr)
	}
*/
sort_inlined :: proc(arr: $T/[]$E) where ORD(E) {
	when size_of(E) != 0 {
		if len(arr) > 1 {
			base_type :: intrinsics.type_core_type(E)
			_quick_lomuto(transmute([]base_type)arr, rawptr(nil), proc(l, r: base_type, data: rawptr) -> bool {
				return l < r
			})
		}
	}
}


/*
WARNING: each call generates a new quicksort, only use in performance critical path

This sort is not guaranteed to be stable

	example :: proc() {
		Data :: struct { rand: int, data: int }
		data_less :: proc(l, r: Data) -> bool { return l.rand < r.rand }
		arr := make([]Data, 10)
		// fill with data
		sort.sort_inlined_by(arr, data_less)
	}
*/
sort_inlined_by :: proc(arr: $T/[]$E, $LESS: proc(l, r: E) -> bool) {
	when size_of(E) != 0 {
		if len(arr) > 1 {
			_quick_lomuto(arr, rawptr(nil), proc(l, r: E, data: rawptr) -> bool {
				return LESS(l, r)
			})
		}
	}
}

/*
WARNING: each call generates a new quicksort, only use in performance critical path

This sort is not guaranteed to be stable

	example :: proc() {
		arr := []int{3,2,1}
		indices := sort.sort_inlined_with_indices(arr)
		// arr = {1,2,3}
		defer delete(indices)
	}
*/
sort_inlined_with_indices :: proc(arr: $T/[]$E, allocator := context.allocator) -> (indices: []int) where ORD(E) {
	indices = make([]int, len(arr), allocator)

	when size_of(E) != 0 {
		if len(arr) > 1 {
			for &index, i in indices{
				index = i
			}

			base_type :: intrinsics.type_core_type(E)
			base := transmute([]base_type)arr
			_quick_lomuto(indices, base, proc(l, r: int, arr: []base_type) -> bool {
				return arr[l] < arr[r]
			})
			
			sort_from_permutation_indices(arr, indices)
		}
	}
	return indices
}

/*
WARNING: each call generates a new quicksort, only use in performance critical path

This sort is not guaranteed to be stable

	example :: proc() {
		Data :: struct { rand: int, data: [10]int }
		data_less :: proc(l, r: Data) -> bool { return l.rand < r.rand }
		arr := make([]Data, 10)
		// fill with data
		sort.sort_inlined_by_with_indices(arr, data_less, context.temp_allocator)
		free_all(context.temp_allocator)
	}
*/
sort_inlined_by_with_indices :: proc(arr: $T/[]$E, $LESS: proc(l, r: E) -> bool, allocator := context.allocator) -> (indices: []int) {
	indices = make([]int, len(arr), allocator)

	when size_of(E) != 0 {
		if len(arr) > 1 {
			for &index, i in indices{
				index = i
			}

			_quick_lomuto(indices, arr, proc(l, r: int, arr: T) -> bool {
				return LESS(arr[l], arr[r])
			})

			sort_from_permutation_indices(arr, indices)
		}
	}
	return indices
}

/*
WARNING: each call generates a new quicksort, only use in performance critical path

This sort is not guaranteed to be stable

	example :: proc() {
		Data :: struct { rand: int, data: [10]int }
		modulus := []int{5,4,6,7,3,2,1,8,9,0}
		less_data_modulus :: proc(l, r: Data, mod: ^[]int)->bool{
			left := l.rand %% 10
			right := r.rand %% 10
			return mod[left] < mod[right]
		}
		arr := make([]Data, 10)
		// fill with data
		sort.sort_inlined_by_with_data(data, less_data_modulus, &modulus)
	}
*/
sort_inlined_by_with_data :: proc(arr: $T/[]$E, $LESS: proc(l, r: E, user_data: ^$D) -> bool, user_data: ^D) {
	when size_of(E) != 0 {
		if len(arr) > 1 {
			_quick_lomuto(arr, user_data, proc(l, r: E, user_data: ^D) -> bool {
				return LESS(l, r, user_data)
			})
		}
	}
}

/*
WARNING: each call generates a new quicksort, only use in performance critical path

This sort is not guaranteed to be stable

	example :: proc() {
		Data :: struct { rand: int, data: [10]int }
		modulus := []int{5,4,6,7,3,2,1,8,9,0}
		less_data_modulus :: proc(l, r: Data, mod: ^[]int)->bool{
			left := l.rand %% 10
			right := r.rand %% 10
			return mod[left] < mod[right]
		}
		arr := make([]Data, 10)
		// fill with data
		indices := sort.sort_inlined_by_with_indices_with_data(data, less_data_modulus, &modulus)
		defer delete(indices)
	}
*/
sort_inlined_by_with_indices_with_data :: proc(arr: $T/[]$E, $LESS: proc(l, r: E, user_data: ^$D) -> bool, user_data: ^D, allocator := context.allocator) -> (indices: []int) {
	indices = make([]int, len(arr), allocator)
	
	when size_of(E) != 0 {
		if len(arr) > 1 {
			for &index, i in indices{
				index = i
			}
			
			Context :: struct {
				arr: T,
				user_data: ^D,
			}
			ctx := Context{arr, user_data}

			_quick_lomuto(indices, ctx, proc(l, r: int, ctx: Context) -> bool {
				return LESS(ctx.arr[l], ctx.arr[r], ctx.user_data)
			})

			sort_from_permutation_indices(arr, indices)
		}
	}
	return indices
}

// WARNING: each call generates a new quicksort, only use in performance critical path
//
// This sort is not guaranteed to be stable
sort_inlined_by_cmp :: proc(arr: $T/[]$E, $CMP: proc(l, r: E) -> Ordering) {
	when size_of(E) != 0 {
		if len(arr) > 1 {
			_quick_lomuto(arr, rawptr(nil), proc(l, r: E, user_data: rawptr) -> bool {
				return CMP(l, r) == .Less
			})
		}
	}
}

// WARNING: each call generates a new quicksort, only use in performance critical path
//
// This sort is not guaranteed to be stable
sort_inlined_by_cmp_with_data :: proc(arr: $T/[]$E, $CMP: proc(l, r: E, user_data: ^$D) -> Ordering, user_data: ^D) {
	when size_of(E) != 0 {
		if len(arr) > 1 {
			_quick_lomuto(arr, user_data, proc(l, r: E, user_data: ^D) -> bool {
				return CMP(l, r, user_data) == .Less
			})
		}
	}
}

@private
sort_from_permutation_indices :: proc(data: $T/[]$E, indices: []int) {
	assert(len(data) == len(indices))
	if len(indices) <= 1 {
		return
	}

	for i in 0..<len(indices) {
		next_index := indices[i]

		if next_index < 0 {
			indices[i] *= -1
			continue
		}
		
		if next_index <= i {
			continue
		}

		cur_index := i
		temp := data[cur_index]

		for next_index != i {
			indices[cur_index] *= -1

			data[cur_index] = data[next_index]
			
			cur_index = next_index
			next_index = indices[cur_index]
		}
		
		data[cur_index] = temp
		indices[i] *= -1
	}
}

@private
_quick_lomuto :: proc(arr: $T/[]$E, data: $D, $LESS: $P) #no_bounds_check {
	loop(arr, data, true)
	
	loop :: proc(arr: T, data: D, leftmost: bool) #no_bounds_check {
		arr := arr; leftmost := leftmost

		for {
			if len(arr) <= 32 {
				if leftmost {
					insertion_sort(arr, data)
				} else {
					unguarded_insertion_sort(arr, data)
				}
				return
			}
			
			median_3_depth := log2(len(arr)) / 5
			pivot_index := median_3(arr, data, 0, len(arr) - 1, median_3_depth)

			if !leftmost {
				if !LESS(arr[-1], arr[pivot_index], data) {
					left := partition_lomuto_reverse(arr, data, pivot_index)
					arr = arr[left + 1:]
					leftmost = false
					continue					
				}
			} 

			when size_of(E) > 80 {
				left := partition_hoare(arr, data, pivot_index)
			} else {
				left := partition_lomuto(arr, data, pivot_index)
			}
			
			right := len(arr) - left

			if left < right {
				loop(arr[:left], data, leftmost)
				arr = arr[left + 1:]
				leftmost = false
			} else {
				loop(arr[left + 1:], data, false)
				arr = arr[:left]
			}
		}
	}

	log2 :: proc(n: int) -> (log: int) {
		for n := n; n > 0; n >>= 1 {
			log += 1
		}
		return log
	}

	median_3 :: proc(arr: T, data: D, start, end, depth: int) -> int #no_bounds_check {
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

	insertion_sort :: proc(arr: T, data: D) #no_bounds_check {
		for i in 1..<len(arr) {
			current := arr[i]
			j := i
			for ; j > 0 && LESS(current, arr[j - 1], data); j -= 1 {
				arr[j] = arr[j - 1]
			}
			arr[j] = current
		}
	}

	unguarded_insertion_sort :: proc(arr: T, data: D) #no_bounds_check {
		for i in 1..<len(arr) {
			current := arr[i]
			j := i
			for ; LESS(current, arr[j - 1], data); j -= 1 {
				arr[j] = arr[j - 1]
			}
			arr[j] = current
		}
	}

	// branchless partitioning
	// [  <  |0|  >=  |  ?  ]
	//	    left    right ->
	partition_lomuto :: proc(arr: T, data: D, pivot_index: int) -> (left: int) #no_bounds_check {
		pivot := arr[pivot_index]
		arr[pivot_index] = arr[0]

		j := 0
		for _ in arr[:len(arr) - 1] {
			arr[j] = arr[left]
			j += 1
			arr[left] = arr[j]
			left += cast(int)LESS(arr[left], pivot, data)
		}

		arr[j] = arr[left]
		arr[left] = pivot

		return left
	}

	// [  ?  |  <=  |0|  >  ]
	//   <- left   right
	partition_lomuto_reverse :: proc(arr: T, data: D, pivot_index: int) -> (right: int) #no_bounds_check {
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

		return right
	}

	// only used for large types as it uses less data moves
	// [  <  |0|   ?   |  >=  ]
	//	 ->  left    right <-
	partition_hoare :: proc(arr: T, data: D, pivot_index: int) -> (left: int) #no_bounds_check {
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
				return left
			}
			arr[right] = arr[left]
			right -= 1
		}
	}
}

