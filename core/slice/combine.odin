package slice

import "base:runtime"
import "base:intrinsics"

/*
 An iterator that generate all the combination of length 'k' from a slice of length 'n', 'n' choose 'k'.
 The iterator have a field 'combination' that hold the next combination produced after a call to `combine`.
 */
Combination_Iterator :: struct($T: typeid) {
    k: int,
    j: int,
    first: bool,
    counters: []int,
    slice: []T,
    combination: []T,
}

/*
Make an iterator to get the 'n' choose 'k' combination from a slice.

* Allocated Using Provided Allocator *

This procedure allocates some state to assist in combine, it does not make a copy
of the underlying slice but also it doesn't mutate the slice.

Inputs:
- slice: The slice to combine.
- k: The selections size.
- allocator: (default is context.allocator).

Returns:
- iter: The iterator, to be passed to `combine`.
- error: An `Allocation_Error`, if allocation failed.
*/
make_combination_iterator :: proc(
    slice: []$T,
    k: int,
    allocator := context.allocator,
) -> (
    iter: Combination_Iterator(T),
    error: runtime.Allocator_Error, 
) #optional_allocator_error {
    assert(k >= 0 && len(slice) >= k)

    iter.combination = make([]T, k, allocator) or_return
    iter.counters, error = make([]int, k + 2, allocator)
    if error != nil {
        delete(iter.counters)
        return iter, error
    }

    for i in 0..<k {
        iter.counters[i] = i
    }
    iter.counters[k] = len(slice)

    iter.j = k
    iter.k = k
    iter.slice = slice
    iter.first = true

    return
}

/*
Free the state allocate by `make_combination_iterator`.

Inputs:
- iter: The iterator create by `make_combination_iterator`
- allocator: The allocator used to create the iterator. (default is context.allocator)
*/
destroy_combination_iterator :: proc(
    iter: Combination_Iterator($T),
    allocator := context.allocator,
) {
    delete(iter.combination, allocator = allocator)
    delete(iter.counters, allocator = allocator)
}


/*
Combine the slice ('n' choose 'k') placing the values into the `combination`.

Note that the first iteration will always be the first 'k' elements of the original slice.

Inputs:
- iter: The iterator created by `make_combination_iterator`.
Returns:
- ok: True if the combination succeeded, false if all the combination have already been produced.
*/
combine :: proc(iter: ^Combination_Iterator($T)) -> (ok: bool) #no_bounds_check {
    // This is an iterative implementation of the 'Algorithm T' described in
    // 'The Art of Computer Programming, Volume 4a' by Donal E. Knuth.
    defer if ok {
        for i in 0..<iter.k {
            iter.combination[i] = iter.slice[iter.counters[i]]
        }
    }

    if iter.first {
        iter.first = false
        return true
    }

    j := iter.j

    if j > 0 {
        x := iter.counters[j - 1] + 1
        iter.counters[j - 1] = x
        iter.j -= 1
        return true
    }

    if iter.counters[0] + 1 < iter.counters[1] {
        iter.counters[0] += 1
        return true
    }

    j = 2
    for {
        iter.counters[j - 2] = j - 2
        x := iter.counters[j - 1] + 1
        if x != iter.counters[j] {
            break
        }
        j += 1
    }

    if j > iter.k {
        return false
    }

    iter.counters[j - 1] = iter.counters[j - 1] + 1
    iter.j = j - 1
    return true
}
