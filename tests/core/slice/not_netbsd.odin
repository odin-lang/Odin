#+build !netbsd
package test_core_slice

import "core:slice"
import "core:testing"
import "core:math/rand"

// Disable on NetBSD due to Illegal Instruction on CI, even with `microarch:native`
// `@(test, disable="...")` still runs the test.

@(test)
test_unique :: proc(t: ^testing.T) {
	for v in UNIQUE_TEST_VECTORS {
		assorted := v[0]
		expected := v[1]

		uniq := slice.unique(assorted)
		testing.expectf(t, slice.equal(uniq, expected), "Expected slice.uniq(%v) == %v, got %v", v[0], v[1], uniq)
	}

	for v in UNIQUE_TEST_VECTORS {
		assorted := v[0]
		expected := v[1]

		uniq := slice.unique_proc(assorted, proc(a, b: int) -> bool {
			return a == b
		})
		testing.expectf(t, slice.equal(uniq, expected), "Expected slice.unique_proc(%v, ...) == %v, got %v", v[0], v[1], uniq)
	}

	r := rand.create(t.seed)
	context.random_generator = rand.default_random_generator(&r)

	// 10_000 random tests
	for _ in 0..<10_000 {
		assorted: [dynamic]i64
		expected: [dynamic]i64

		// Prime with 1 value
		old := rand.int63()
		append(&assorted, old)
		append(&expected, old)

		// Add 99 additional random values
		for _ in 1..<100 {
			new := rand.int63()
			append(&assorted, new)
			if old != new {
				append(&expected, new)
			}
			old = new
		}

		original := slice.clone(assorted[:])
		uniq := slice.unique(assorted[:])
		testing.expectf(t, slice.equal(uniq, expected[:]), "Expected slice.uniq(%v) == %v, got %v", original, expected, uniq)

		delete(assorted)
		delete(original)
		delete(expected)
	}
}