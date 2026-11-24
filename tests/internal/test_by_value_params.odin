package test_internal

import "core:testing"

// A parameter over 16 bytes keeps the value it had at the call, whatever the callee writes through other paths.

@(private="file")
Big :: struct {
	a, b, c, d: int,
	tag:        u8,
}

@(private="file")
g_big: Big

@(private="file")
g_stash: ^Big

@(private="file")
write_global_read :: #force_no_inline proc(v: Big) -> int {
	g_big.a = 99
	return v.a
}

@(private="file")
write_ptr_read :: #force_no_inline proc(v: Big, p: ^Big) -> int {
	p.a = 99
	return v.a
}

@(private="file")
write_stash_read :: #force_no_inline proc(v: Big) -> int {
	g_stash.a = 99
	return v.a
}

@(private="file")
write_any_read :: #force_no_inline proc(v: Big, a: any) -> int {
	(^Big)(a.data).a = 99
	return v.a
}

@(private="file")
forward :: #force_no_inline proc(v: Big) -> int {
	return write_global_read(v)
}

@(private="file")
g_write: proc()

@(private="file")
write_global :: proc() {
	g_big.a = 99
}

@(private="file")
write_through_proc_read :: #force_no_inline proc(v: Big) -> int {
	g_write()
	return v.a
}

@(private="file")
write_through_callee_read :: #force_no_inline proc(v: Big) -> int {
	write_global()
	return v.a
}

// writes nothing outside its own memory: a call to it needs no copy
@(private="file")
read_both :: #force_no_inline proc(v: Big, p: ^Big) -> int {
	return v.a*1000 + p.a
}

@(test)
test_by_value_params :: proc(t: ^testing.T) {
	g_big = {a = 1}
	testing.expect_value(t, write_global_read(g_big), 1)

	g_big = {a = 1}
	testing.expect_value(t, forward(g_big), 1)

	x := Big{a = 1}
	testing.expect_value(t, write_ptr_read(x, &x), 1)

	p := new(Big, context.temp_allocator)
	p.a = 1
	testing.expect_value(t, write_ptr_read(p^, p), 1)

	y := Big{a = 1}
	testing.expect_value(t, write_any_read(y, y), 1)

	g_big = {a = 1}
	g_write = write_global
	testing.expect_value(t, write_through_proc_read(g_big), 1)

	g_big = {a = 1}
	testing.expect_value(t, write_through_callee_read(g_big), 1)

	g_big = {a = 1}
	testing.expect_value(t, read_both(g_big, &g_big), 1001)
}

@(private="file")
g_kept: any

@(private="file")
keep_any :: proc(a: any) {
	g_kept = a
}

@(private="file")
write_kept_read :: #force_no_inline proc(v: Big) -> int {
	(^Big)(g_kept.data).a = 99
	return v.a
}

// An `any` given to an earlier call may be kept, and the value it refers to escapes.
// Only a variadic `..any` argument of a procedure which is not polymorphic is never kept past its call.
@(test)
test_by_value_params_kept_any :: proc(t: ^testing.T) {
	keep := keep_any // through a procedure value, which the stack-escape warning does not follow
	x := Big{a = 1}
	keep(x)
	testing.expect_value(t, write_kept_read(x), 1)
	g_kept = nil
}

@(private="file")
write_appended_read :: #force_no_inline proc(v: Big, list: ^[dynamic]any) -> int {
	(^Big)(list[0].data).a = 99
	return v.a
}

// A polymorphic procedure may keep its variadic arguments, e.g. `append_elems` with its `..E` as `..any`.
@(test)
test_by_value_params_appended_any :: proc(t: ^testing.T) {
	list: [dynamic]any
	defer delete(list)
	x := Big{a = 1}
	y := 2
	append(&list, x, y) // two values, so through the variadic `append_elems`
	testing.expect_value(t, write_appended_read(x, &list), 1)
}

@(private="file")
g_big2: Big

@(private="file")
write_global2_read :: #force_no_inline proc(v: Big) -> int {
	g_big2.a = 99
	return v.a
}

@(private="file")
write_globals_read :: #force_no_inline proc(v, w: Big) -> int {
	g_big.a  = 99
	g_big2.a = 99
	return v.a*10 + w.a
}

@(private="file")
write_global_add :: #force_no_inline proc(v: Big, n: int) -> int {
	g_big.a = 99
	return v.a*10 + n
}

// The copies for one call are live at the same time and must not share a slot.
// Neither may a nested call's copy and the outer call's copy when both are live.
// Copies whose calls do not overlap may share one.
@(test)
test_by_value_params_shared_slots :: proc(t: ^testing.T) {
	g_big, g_big2 = {a = 1}, {a = 2}
	testing.expect_value(t, write_globals_read(g_big, g_big2), 12)

	g_big, g_big2 = {a = 1}, {a = 2}
	testing.expect_value(t, write_global_add(g_big, write_global2_read(g_big2)), 12)

	g_big = {a = 1}
	testing.expect_value(t, write_global_read(g_big) + write_global_read(g_big), 100)

	r := 0
	for i in 0..<4 {
		g_big, g_big2 = {a = 1}, {a = 2}
		if i % 2 == 0 {
			r += write_global_read(g_big)
		} else {
			r += write_global2_read(g_big2)
		}
	}
	testing.expect_value(t, r, 6)
}

@(private="file")
Huge :: struct {
	cells: [200*1024]u8,
	tick:  int,
}

@(private="file")
g_huge: Huge

@(private="file")
g_huge_sum: int

@(private="file")
add_huge :: #force_no_inline proc(h: Huge) {
	g_huge_sum += int(h.cells[h.tick]) + h.tick
}

// Each call's copy of `g_huge` is only live until its call returns, and the copies share one slot.
// A slot for each call would not fit in a 1 MB stack, the size of a thread's stack on Windows.
@(test)
test_by_value_params_huge_copies_share_a_slot :: proc(t: ^testing.T) {
	g_huge     = {}
	g_huge_sum = 0
	add_huge(g_huge); g_huge.tick += 1
	add_huge(g_huge); g_huge.tick += 1
	add_huge(g_huge); g_huge.tick += 1
	add_huge(g_huge); g_huge.tick += 1
	add_huge(g_huge); g_huge.tick += 1
	add_huge(g_huge)
	testing.expect_value(t, g_huge_sum, 0+1+2+3+4+5)
}

// The address is taken after the first call: the loop brings the call back round.
@(test)
test_by_value_params_address_taken_later :: proc(t: ^testing.T) {
	x: Big
	r := 0
	for i in 0..<2 {
		x.a = 1
		g_stash = &g_big
		if i == 1 {
			g_stash = &x
		}
		r += write_stash_read(x)
	}
	testing.expect_value(t, r, 2)
}

@(private="file")
Aligned :: struct {
	v: #simd[4]f32,
	n: i128,
}

@(private="file")
Packed_Aligned :: struct #packed {
	tag:   u8,
	inner: Aligned,
}

@(private="file")
g_packed_aligned: Packed_Aligned

// A variadic `..any` argument refers to the value itself: the parameter's memory as the caller gave it
@(private="file")
address_aligned :: proc(args: ..any) -> bool {
	return uintptr(args[0].data) % align_of(Aligned) == 0
}

// writes nothing outside its own memory: a call to it needs no copy of a global or of memory through a pointer
@(private="file")
aligned_read :: #force_no_inline proc(v: Aligned) -> bool {
	return address_aligned(v)
}

// writes outside its own memory: a call to it needs no copy of a local whose address is not taken
@(private="file")
aligned_write :: #force_no_inline proc(v: Aligned) -> bool {
	g_big.a += 1
	return address_aligned(v)
}

// A field of a `#packed` struct may not be aligned for its type, wherever the struct is.
// The copy that aligns it stays, whatever else needs no copy.
@(test)
test_by_value_params_packed_field :: proc(t: ^testing.T) {
	local: Packed_Aligned
	testing.expect(t, aligned_read(local.inner))
	testing.expect(t, aligned_write(local.inner))
	testing.expect(t, aligned_read(g_packed_aligned.inner))
	p := &g_packed_aligned
	testing.expect(t, aligned_read(p.inner))
	testing.expect(t, aligned_write(p.inner))
}

// Each writes its result while it still reads its parameter, and writes nothing else outside its own memory.
@(private="file")
reverse :: #force_no_inline proc(v: Big) -> Big {
	return {a = v.d, b = v.c, c = v.b, d = v.a, tag = v.tag}
}

@(private="file")
reverse_named :: #force_no_inline proc(v: Big) -> (r: Big) {
	r.a = v.d
	r.b = v.c
	r.c = v.b
	r.d = v.a
	return
}

@(private="file")
reverse_pair :: #force_no_inline proc(v: Big) -> (Big, int) {
	return {a = v.d, b = v.c, c = v.b, d = v.a}, v.a
}

// returned through memory on every target
@(private="file")
Row :: struct {cells: [16]int}

@(private="file")
reverse_row :: #force_no_inline proc(v: Row) -> (r: Row) {
	for i in 0..<16 {
		r.cells[i] = v.cells[15-i]
	}
	return
}

// A result reaches its destination after the call, even where the destination is the argument.
@(test)
test_by_value_params_result_into_argument :: proc(t: ^testing.T) {
	forwards  := Big{a = 1, b = 2, c = 3, d = 4}
	backwards := Big{a = 4, b = 3, c = 2, d = 1}

	x := forwards
	x = reverse(x)
	testing.expect_value(t, x, backwards)
	x = reverse_named(x)
	testing.expect_value(t, x, forwards)
	n: int
	x, n = reverse_pair(x)
	testing.expect_value(t, x, backwards)
	testing.expect_value(t, n, 1)

	g_big = forwards
	g_big = reverse(g_big)
	testing.expect_value(t, g_big, backwards)

	s: struct {tag: u8, big: Big}
	s.big = forwards
	s.big = reverse(s.big)
	testing.expect_value(t, s.big, backwards)

	arr: [2]Big
	arr[1] = forwards
	arr[1], n = reverse_pair(arr[1])
	testing.expect_value(t, arr[1], backwards)
	testing.expect_value(t, n, 1)

	row: Row
	for &c, i in row.cells {
		c = i
	}
	row = reverse_row(row)
	testing.expect_value(t, row.cells[0], 15)
	testing.expect_value(t, row.cells[15], 0)
}
