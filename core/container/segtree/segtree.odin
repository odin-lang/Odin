// This package implements Segment tree data structure
package container_segtree

import "base:runtime"
import "base:intrinsics"

// Reference(s): https://github.com/atcoder/ac-library/blob/master/atcoder/segtree.hpp
//               https://cp-algorithms.com/data_structures/segment_tree.html

Segtree :: struct($T: typeid) {
	data:      []T,
	size, log: uint,
	id:        T,
	op:        proc "contextless" (x, y: T) -> T,

	_allocator: runtime.Allocator,
}

destroy :: proc(tree: ^$T/Segtree) {
	delete_slice(tree.data, tree._allocator)
}

init :: proc(tree: ^$T/Segtree($E), id: E, op: proc "contextless" (x, y: E) -> E, #any_int len: int, allocator := context.allocator) -> runtime.Allocator_Error {
	size := uint(len)

	tree._allocator = allocator
	tree.id   = id
	tree.op   = op
	tree.size = _bit_ceil(size)
	tree.log  = intrinsics.count_trailing_zeros(tree.size)
	// FIXME: Is there a better way to make a slice and fill each element with a value
	err: runtime.Allocator_Error = ---
	tree.data, err = make_slice([]E, tree.size * 2, allocator)

	if err != .None {
		return err
	}

	if id != {} {
		for &e in tree.data {
			e = id
		}
	}

	for i := size - 1; i >= 1; i -= 1 {
		_update(tree, i)
	}

	return .None
}

// NOTE: Other containers that have `init_from_slice` usually use the slice as the backing memory but since
//       the backing memory will need to be larger than the input the segtree `init_from_slice` copies from the 
//       input slice
init_from_slice :: proc(tree: ^$T/Segtree($E), id: E, op: proc "contextless" (x, y: E) -> E, src: $S/[]E, allocator := context.allocator) -> runtime.Allocator_Error {
	size := uint(len(src))

	tree._allocator = allocator
	tree.id   = id
	tree.op   = op
	tree.size = _bit_ceil(size)
	tree.log  = intrinsics.count_trailing_zeros(tree.size)
	err: runtime.Allocator_Error = ---
	tree.data, err = make([]E, tree.size * 2, allocator)

	if err != .None do return err

	if id != {} {
		for &elem in tree.data {
			elem = id
		}
	}

	for i := uint(0); i < size; i += 1 {
		tree.data[size + i] = src[i]
	}

	for i := size - 1; i >= 1; i -= 1 {
		_update(tree, i)
	}

	return .None
}

set :: proc(tree: ^$T/Segtree($E), #any_int idx: int, v: E) {
	p := idx + tree.size
	tree.data[p] = v
	for i := 1; i <= tree.log; i += 1 {
		_update(p >> i)
	}
}

prod :: proc(tree: ^$T/Segtree($E), #any_int left_idx, right_idx: int) -> E {
	pl, pr := tree.id
	l := left_idx + tree.size
	r := right_idx + tree.size

	for l < r {
		if l & 1 {
			pl = op(pl, tree.data[l])
			l += 1
		}

		if r & 1 {
			r -= 1
			pr = op(tree.data[r], pr)
		}

		l >>= 1
		r >>= 1
	}

	return tree.op(pl, pr)
}

prod_all :: proc(tree: ^$T/Segtree($E)) -> E {
	return tree.data[1]
}


get :: proc(tree: ^$T/Segtree($E), #any_int p: int) -> E {
	return tree.data[p + tree.size]
}

max_right :: proc(tree: ^$T/Segtree($E), #any_int left_idx: int, f: proc "contextless" (x: E) -> bool, loc := #caller_location) -> int {
	assert(condition=f(tree.id), loc=loc)
	n := len(tree.data)
	if left_idx == n do return n

	l := uint(left_idx) + tree.size
	sum := tree.id

	for {
		for l % 2 == 0 do l >>= 1
		if !f(tree.op(sum, tree.data[l])) {
			for l < tree.size {
				l *= 2
				x := tree.op(sum, tree.data[l])
				if f(x) {
					sum = x
					l += 1
				}
			}
			return int(l) - int(tree.size)
		}
		sum = tree.op(sum, tree.data[l])
		l += 1
		if (l & -l) == l do break
	}

	return n
}

min_left :: proc(tree: ^$T/Segtree($E), #any_int right_idx: int, f: proc "contextless" (x: E) -> bool, loc := #caller_location) -> int {
	assert(condition=f(tree.id), loc=loc)
	if right_idx == 0 do return 0

	r := uint(right_idx) + tree.size
	sum := tree.id

	for {
		r -= 1
		for r > 1 && r % 2 != 0 do r >>= 1
		if !f(tree.op(tree.data[r], sum)) {
			for r < tree.size {
				r = 2*r + 1
				x := tree.op(tree.data[r], sum)
				if f(x) {
					sum = x
					r -= 1
				}
			}
			return int(r) + 1 - int(tree.size)
		}
		sum = tree.op(tree.data[r], sum)
		if (r & -r) == r do break
	}

	return 0
}

// FIXME: Move to core:math/bits?
@(private)
_bit_ceil :: proc(#any_int x: int) -> uint {
	if x <= 1 do return 1
	u := uint(x)
	n := size_of(u) * 8 - uint(intrinsics.count_leading_zeros(u - 1))
	return 1 << n
}

@(private)
_update :: proc(tree: ^$T/Segtree($E), k: uint) {
	tree.data[k] = tree.op(tree.data[2 * k], tree.data[2 * k + 1])
}