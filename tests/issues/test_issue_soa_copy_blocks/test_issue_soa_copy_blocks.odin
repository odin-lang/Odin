// `copy` between slices and #soa slices, built with `-microarch:native`.
// With AVX2 it copies 8 elements of 4-byte fields, or 4 of 8-byte fields, per block.
// A field count under the block width also reads or writes the next element, which must exist.
package test_issue_soa_copy_blocks

import "core:slice"
import "core:testing"

check :: proc(t: ^testing.T, $E: typeid, loc := #caller_location) {
	// What lies past the copied elements, which must stay as it is
	past: E
	for &b in ([^]u8)(&past)[:size_of(E)] {
		b = 0xab
	}

	for n in 0..=25 {
		n := n if n < 25 else 100

		aos := make([]E, n)
		defer delete(aos)
		for &b, i in slice.to_bytes(aos) {
			b = u8(i*7 + 3)
		}

		soa := make(#soa[]E, n+3)
		defer delete(soa)
		for i in n..<n+3 {
			soa[i] = past
		}
		testing.expect_value(t, copy(soa, aos), n, loc=loc)
		for i in 0..<n {
			if !testing.expect_value(t, soa[i], aos[i], loc=loc) {
				return
			}
		}
		for i in n..<n+3 {
			testing.expect_value(t, soa[i], past, loc=loc)
		}

		back := make([]E, n+3)
		defer delete(back)
		for i in n..<n+3 {
			back[i] = past
		}
		testing.expect_value(t, copy(back, soa[:n]), n, loc=loc)
		for i in 0..<n {
			if !testing.expect_value(t, back[i], aos[i], loc=loc) {
				return
			}
		}
		for i in n..<n+3 {
			testing.expect_value(t, back[i], past, loc=loc)
		}
	}
}

@(test)
test_soa_copy_blocks :: proc(t: ^testing.T) {
	check(t, struct {a, b, c, d, e: u32})
	check(t, struct {a, b, c, d, e, f: u32})
	check(t, struct {a, b, c, d, e, f, g: u32})
	check(t, struct {a, b, c, d, e, f, g, h: u32})
	check(t, struct {a, b, c, d, e, f, g, h, i: u32})
	check(t, struct {a, b, c, d, e, f, g, h, i, j, k, l: u32})
	check(t, struct {a, b, c, d, e, f, g, h, i, j, k, l, m, n, o, p, q: u32})

	check(t, struct {a, b, c: u64})
	check(t, struct {a, b, c, d: u64})
	check(t, struct {a, b, c, d, e: u64})
	check(t, struct {a, b, c, d, e, f: u64})
	check(t, [4]u64)
}
