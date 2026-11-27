// With optimizations, a range loop over an `#soa[]T` or `#soa[dynamic]T` reads the columns from the array's header once when
// its body cannot change them, and still reads them for each field of an element when what the body writes may hold them
package test_range_snapshot

import "core:testing"

@(private="file")
Node :: struct {
	items: #soa[dynamic]Node,
	v:     int,
}

@(private="file")
V :: struct {
	x: int,
	y: f32,
}

@(private="file")
Split :: struct {
	#soa_split pos: [3]f32,
	w: int,
}

@(private="file")
g_soa: #soa[dynamic]V

@(private="file")
fill :: proc(a: ^#soa[dynamic]V, scale: int) {
	for i in 0..<5 {
		append(a, V{x = i*scale})
	}
}

// The header is inside the elements: writing another header into the first element moves the loop onto that array
@(test)
test_soa_header_in_elements :: proc(t: ^testing.T) {
	root: Node
	defer delete(root.items)
	other: #soa[dynamic]Node
	defer delete(other)
	append(&root.items, Node{v = 1}, Node{v = 2}, Node{v = 3})
	append(&other, Node{v = 10}, Node{v = 20}, Node{v = 30})
	h := &root.items[0].items
	h^ = root.items

	sum := 0
	for &x, i in h {
		sum += x.v
		if i == 0 {
			x.items = other
		}
	}
	testing.expect_value(t, sum, 1 + 20 + 30)
}

@(private="file")
Inner :: struct {
	a:     int,
	items: #soa[dynamic]Outer,
}

@(private="file")
Outer :: struct {
	v: int,
	#soa_split inner: Inner,
}

// The header is inside the elements in a column other than the first, that of `inner.items`: writing another header into it,
// or into all of `inner`, moves the loop onto that array, and writing only the other columns does not
@(test)
test_soa_header_in_split_column :: proc(t: ^testing.T) {
	root, other: #soa[dynamic]Outer
	defer delete(root)
	defer delete(other)
	append(&root, Outer{v = 1}, Outer{v = 2}, Outer{v = 3})
	append(&other, Outer{v = 10}, Outer{v = 20}, Outer{v = 30})
	h := &root[0].inner.items

	h^ = root
	sum := 0
	for &x, i in h {
		sum += x.v
		if i == 0 {
			x.inner.items = other
		}
	}
	testing.expect_value(t, sum, 1 + 20 + 30)

	h^ = root
	sum = 0
	for &x, i in h {
		sum += x.v
		if i == 0 {
			x.inner = Inner{a = 7, items = other}
		}
	}
	testing.expect_value(t, sum, 1 + 20 + 30)
	testing.expect_value(t, root[0].inner.a, 7)

	h^ = root
	sum = 0
	for &x in h {
		sum += x.v
		x.v += 100
		x.inner.a = 8
	}
	testing.expect_value(t, sum, 1 + 2 + 3)
	testing.expect_value(t, root[2].v, 103)
	testing.expect_value(t, root[2].inner.a, 8)
}

// Overwriting the array being ranged over moves the loop onto the new columns, for a local, a global, and an `#soa[]T`
@(test)
test_soa_overwritten_array :: proc(t: ^testing.T) {
	local, other: #soa[dynamic]V
	fill(&local, 1)
	fill(&other, 10)
	saved := local
	defer delete(saved)
	defer delete(other)
	sum, n := 0, 0
	for &v in local {
		sum += v.x
		v.y = 1
		n += 1
		if n == 2 {
			local = other
		}
	}
	testing.expect_value(t, sum, 0 + 1 + 20 + 30 + 40)
	testing.expect_value(t, saved[1].y, 1)
	testing.expect_value(t, other[4].y, 1)

	fill(&g_soa, 1)
	saved_global := g_soa
	defer delete(saved_global)
	sum, n = 0, 0
	for v in g_soa {
		sum += v.x
		n += 1
		if n == 2 {
			g_soa = other
		}
	}
	testing.expect_value(t, sum, 0 + 1 + 20 + 30 + 40)

	s := saved[:]
	sum, n = 0, 0
	for &v in s {
		sum += v.x
		v.y = 2
		n += 1
		if n == 2 {
			s = other[:]
		}
	}
	testing.expect_value(t, sum, 0 + 1 + 20 + 30 + 40)
}

@(private="file")
replace :: proc(a: ^#soa[dynamic]V, b: #soa[dynamic]V) {
	a^ = b
}

// A call may change the header, so the loop still writes into the columns the array has after it
@(test)
test_soa_call_in_body :: proc(t: ^testing.T) {
	h, other: #soa[dynamic]V
	fill(&h, 1)
	fill(&other, 10)
	saved := h
	defer delete(saved)
	defer delete(other)
	for &v, i in h {
		if i == 0 {
			replace(&h, other)
		}
		v.x += 100
	}
	testing.expect_value(t, saved[2].x, 2)
	testing.expect_value(t, other[2].x, 120)
}

// The address of an element names the array's header, so it still reaches the columns the array has later
@(test)
test_soa_elem_address :: proc(t: ^testing.T) {
	h, other: #soa[dynamic]V
	fill(&h, 1)
	fill(&other, 10)
	saved := h
	defer delete(saved)
	defer delete(other)
	p: #soa^#soa[dynamic]V
	for &v, i in h {
		if i == 1 {
			p = &v
		}
	}
	h = other
	testing.expect_value(t, p.x, 10)
}

@(private="file")
soa_scale :: proc(h: ^#soa[dynamic]V) {
	for &v in h {
		v.x = v.x*2 + 1
		v.y = f32(v.x)
	}
}

@(private="file")
soa_reverse_sum :: proc(s: #soa[]V) -> (sum: int) {
	#reverse for &v, i in s {
		v.x += i
		sum += v.x
	}
	return
}

@(private="file")
soa_labelled :: proc(s: #soa[]V) -> (n: int) {
	outer: for &v, i in s {
		if i == 1 {
			continue
		}
		for j in 0..<3 {
			if j == 2 && i == 3 {
				continue outer
			}
			v.x += j
		}
		if i == 4 {
			break outer
		}
		n += 1
	}
	return
}

// Loops which read the columns once give the same results as before
@(test)
test_soa_loops :: proc(t: ^testing.T) {
	h: #soa[dynamic]V
	defer delete(h)
	append(&h, V{x = 1}, V{x = 2}, V{x = 3}, V{x = 4}, V{x = 5}, V{x = 6})

	soa_scale(&h)
	testing.expect_value(t, h[5].x, 13)
	testing.expect_value(t, h[5].y, 13)
	testing.expect_value(t, soa_reverse_sum(h[:]), 63)
	testing.expect_value(t, h[5].x, 18)
	testing.expect_value(t, soa_labelled(h[:]), 2)
	testing.expect_value(t, h[0].x, 6)
	testing.expect_value(t, h[1].x, 6)
	testing.expect_value(t, h[3].x, 13)

	empty: #soa[dynamic]V
	soa_scale(&empty)
	testing.expect_value(t, len(empty), 0)

	split: #soa[dynamic]Split
	defer delete(split)
	append(&split, Split{}, Split{}, Split{}, Split{})
	for &e, i in split {
		e.pos.y = f32(i)
		e.w = i*2
	}
	testing.expect_value(t, split[3].pos.y, 3)
	testing.expect_value(t, split[3].w, 6)

	xs := []int{1, 2, 3}
	ys := []f32{0, 0, 0}
	zipped := soa_zip(x=xs, y=ys)
	for &e in zipped {
		e.y = f32(e.x) * 2
	}
	testing.expect_value(t, ys[2], 6)

	fixed: #soa[dynamic; 4]V
	append(&fixed, V{x = 1}, V{x = 2}, V{x = 3})
	for &v in fixed {
		v.x *= 2
	}
	testing.expect_value(t, fixed[2].x, 6)
}
