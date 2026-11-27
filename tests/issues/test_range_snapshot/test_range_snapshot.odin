// With optimizations, a range loop over a `[dynamic]T` or `[dynamic; N]T` reads the array's data and length once when its body
// cannot change them, and still reads them for each element when what the body writes may hold them
package test_range_snapshot

import "core:testing"

@(private="file")
Node :: struct {
	items: [dynamic]Node,
	v:     int,
}

@(private="file")
Holder :: struct {
	items: [dynamic]int,
}

@(private="file")
g_items: [dynamic]int

// The header is inside the elements: zeroing the first element ends the loop
@(test)
test_header_in_elements :: proc(t: ^testing.T) {
	root: Node
	defer delete(root.items)
	append(&root.items, Node{v = 1}, Node{v = 2}, Node{v = 3})
	h := &root.items[0]
	h.items = root.items

	n := 0
	for &x in h.items {
		x = {}
		n += 1
	}
	testing.expect_value(t, n, 1)
}

// Overwriting the array being ranged over ends the loop, for a local, a global, and a `[dynamic; N]T`
@(test)
test_overwritten_array :: proc(t: ^testing.T) {
	local: [dynamic]int
	append(&local, 1, 2, 3, 4, 5)
	saved := local
	defer delete(saved)
	n := 0
	for &x in local {
		x += 1
		n += 1
		if n == 2 {
			local = {}
		}
	}
	testing.expect_value(t, n, 2)
	testing.expect_value(t, saved[1], 3)

	append(&g_items, 1, 2, 3, 4, 5)
	saved_global := g_items
	defer delete(saved_global)
	n = 0
	for &x in g_items {
		x += 1
		n += 1
		if n == 2 {
			g_items = {}
		}
	}
	testing.expect_value(t, n, 2)

	fixed: [dynamic; 8]int
	append(&fixed, 1, 2, 3, 4, 5)
	n = 0
	for &x in fixed {
		x += 1
		n += 1
		if n == 2 {
			fixed = {}
		}
	}
	testing.expect_value(t, n, 2)
}

// A call may change the array, so the loop still sees what it appends
@(test)
test_call_in_body :: proc(t: ^testing.T) {
	h: Holder
	defer delete(h.items)
	append(&h.items, 1, 2, 3)
	n := 0
	for x in h.items {
		if x == 3 {
			append(&h.items, 100)
		}
		n += 1
	}
	testing.expect_value(t, n, 4)
}

// A static declared before the loop is checked against the array, one declared in the body has no address before it
@(test)
test_statics :: proc(t: ^testing.T) {
	h: Holder
	defer delete(h.items)
	append(&h.items, 1, 2, 3)

	@(static) before: int
	before = 0
	for x in h.items {
		before += x
	}
	testing.expect_value(t, before, 6)

	n := 0
	for x in h.items {
		@(static) within: int
		within = x
		n += within
	}
	testing.expect_value(t, n, 6)
}

@(private="file")
scale :: proc(h: ^Holder) {
	for &x in h.items {
		x = x*2 + 1
	}
}

@(private="file")
reverse_sum :: proc(h: ^Holder) -> (sum: int) {
	#reverse for &x, i in h.items {
		x += i
		sum += x
	}
	return
}

@(private="file")
labelled :: proc(h: ^Holder) -> (n: int) {
	outer: for &x, i in h.items {
		if i == 1 {
			continue
		}
		for j in 0..<3 {
			if j == 2 && i == 3 {
				continue outer
			}
			x += j
		}
		if i == 4 {
			break outer
		}
		n += 1
	}
	return
}

// Loops which read the array once give the same results as before
@(test)
test_loops :: proc(t: ^testing.T) {
	h: Holder
	defer delete(h.items)
	append(&h.items, 1, 2, 3, 4, 5, 6)

	scale(&h)
	testing.expect_value(t, h.items[5], 13)
	testing.expect_value(t, reverse_sum(&h), 63)
	testing.expect_value(t, h.items[5], 18)
	testing.expect_value(t, labelled(&h), 2)
	testing.expect_value(t, h.items[0], 6)
	testing.expect_value(t, h.items[1], 6)
	testing.expect_value(t, h.items[3], 13)

	empty: Holder
	scale(&empty)
	testing.expect_value(t, len(empty.items), 0)

	fixed: [dynamic; 4]f32
	append(&fixed, 1, 2, 3)
	for &x in fixed {
		x *= 2
	}
	testing.expect_value(t, fixed[2], 6)
}
