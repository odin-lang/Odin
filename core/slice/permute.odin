package slice

import "base:runtime"

// An in-place permutation iterator.
Permutation_Iterator :: struct($T: typeid) {
	index: int,
	slice: []T,
	counters: []int,
}

/*
Make an iterator to permute a slice in-place.

*Allocates Using Provided Allocator*

This procedure allocates some state to assist in permutation and does not make
a copy of the underlying slice. If you want to permute a slice without altering
the underlying data, use `clone` to create a copy, then permute that instead.

Inputs:
- slice: The slice to permute.
- allocator: (default is context.allocator)

Returns:
- iter: The iterator, to be passed to `permute`.
- error: An `Allocator_Error`, if allocation failed.
*/
make_permutation_iterator :: proc(
	slice: []$T,
	allocator := context.allocator,
) -> (
	iter: Permutation_Iterator(T),
	error: runtime.Allocator_Error,
) #optional_allocator_error {
	iter.slice = slice
	iter.counters = make([]int, len(iter.slice), allocator) or_return

	return
}
/*
Free the state allocated by `make_permutation_iterator`.

Inputs:
- iter: The iterator created by `make_permutation_iterator`.
- allocator: The allocator used to create the iterator. (default is context.allocator)
*/
destroy_permutation_iterator :: proc(
	iter: Permutation_Iterator($T),
	allocator := context.allocator,
) {
	delete(iter.counters, allocator = allocator)
}
/*
Permute a slice in-place.

Note that the first iteration will always be the original, unpermuted slice.

Inputs:
- iter: The iterator created by `make_permutation_iterator`.

Returns:
- ok: True if the permutation succeeded, false if the iteration is complete.
*/
permute :: proc(iter: ^Permutation_Iterator($T)) -> (ok: bool) {
	// This is an iterative, resumable implementation of Heap's algorithm.
	//
	// The original algorithm was described by B. R. Heap as "Permutations by
	// interchanges" in The Computer Journal, 1963.
	//
	// This implementation is based on the nonrecursive version described by
	// Robert Sedgewick in "Permutation Generation Methods" which was published
	// in ACM Computing Surveys in 1977.

	i := iter.index

	if i == 0 {
		iter.index = 1
		return true
	}

	n := len(iter.counters)
	#no_bounds_check for i < n {
		if iter.counters[i] < i {
			if i & 1 == 0 {
				iter.slice[0], iter.slice[i] = iter.slice[i], iter.slice[0]
			} else {
				iter.slice[iter.counters[i]], iter.slice[i] = iter.slice[i], iter.slice[iter.counters[i]]
			}

			iter.counters[i] += 1
			i = 1

			break
		} else {
			iter.counters[i] = 0
			i += 1
		}
	}
	if i == n {
		return false
	}
	iter.index = i
	return true
}
