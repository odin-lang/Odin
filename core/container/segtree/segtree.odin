// This package implements Segment tree data structure
package container_segtree

import "base:runtime"
import "base:intrinsics"
import "core:math"

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
	tree.size = math.next_power_of_two(size)
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

	if err != .None {
		return err
	}

	if id != {} {
		for &elem in tree.data {
			elem = id
		}
	}

	for i := uint(0); i < size; i += 1 {
		tree.data[tree.size + i] = src[i]
	}

	for i := tree.size - 1; i >= 1; i -= 1 {
		_update(tree, i)
	}

	return .None
}

set :: proc(tree: ^$T/Segtree($E), #any_int idx: int, v: E) {
	p := uint(idx) + tree.size
	tree.data[p] = v
	for i := uint(1); i <= tree.log; i += 1 {
		_update(tree, p >> i)
	}
}

prod :: proc(tree: ^$T/Segtree($E), #any_int left_idx, right_idx: int) -> E {
	pl := tree.id
	pr := tree.id
	l := uint(left_idx) + tree.size
	r := uint(right_idx) + tree.size

	for l < r {
		if l & 1 == 1 {
			pl = tree.op(pl, tree.data[l])
			l += 1
		}

		if r & 1 == 1 {
			r -= 1
			pr = tree.op(tree.data[r], pr)
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
	return tree.data[uint(p) + tree.size]
}

max_right :: proc(tree: ^$T/Segtree($E), #any_int left_idx: int, f: proc "contextless" (x: E) -> bool, loc := #caller_location) -> int {
	assert(condition=f(tree.id), loc=loc)
	n := len(tree.data)
	if left_idx == n {
		return n
	}

	l := uint(left_idx) + tree.size
	sum := tree.id

	for {
		for l % 2 == 0 {
			l >>= 1			
		}
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
		if (l & -l) == l {
			break
		}
	}

	return n
}

min_left :: proc(tree: ^$T/Segtree($E), #any_int right_idx: int, f: proc "contextless" (x: E) -> bool, loc := #caller_location) -> int {
	assert(condition=f(tree.id), loc=loc)
	if right_idx == 0 {
		return 0
	}

	r := uint(right_idx) + tree.size
	sum := tree.id

	for {
		r -= 1
		for r > 1 && r % 2 != 0 {
			r >>= 1
		}
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
		if (r & -r) == r {
			break
		}
	}

	return 0
}

@(private)
_update :: proc(tree: ^$T/Segtree($E), k: uint) {
	tree.data[k] = tree.op(tree.data[2 * k], tree.data[2 * k + 1])
}