package test_core_diff

import "base:runtime"
import "core:diff"
import "core:math/rand"
import "core:mem"
import "core:slice"
import "core:strings"
import "core:testing"

/*
	Harness
*/

// IDs by first appearance in `a` then `b`, worked out with a map rather than `core:diff`'s own table.
ids_of :: proc(a, b: []$T) -> (ia, ib: []i32, id_count: int) {
	seen := make(map[T]i32)
	defer delete(seen)

	ia = make([]i32, len(a))
	ib = make([]i32, len(b))
	for x, k in a {
		if x not_in seen {
			seen[x] = i32(len(seen))
		}
		ia[k] = seen[x]
	}
	for x, k in b {
		if x not_in seen {
			seen[x] = i32(len(seen))
		}
		ib[k] = seen[x]
	}
	return ia, ib, len(seen)
}

// The algorithms only look at which tokens are equal, so interning must not change the result by a single bit.
check_matches_interned :: proc(t: ^testing.T, a, b: []$T, c: diff.Changes, opts: diff.Options, loc := #caller_location) -> bool {
	ia, ib, id_count := ids_of(a, b)
	defer delete(ia)
	defer delete(ib)

	check_valid(t, ia, ib, c, loc) or_return

	expected := must(diff.diff_interned(ia, ib, id_count, context.allocator, context.allocator, opts = opts))
	defer diff.changes_destroy(expected, context.allocator)
	return testing.expectf(t, slice.equal(c.bits, expected.bits), "%v: result differs from diffing the interned IDs", opts, loc = loc)
}

@(rodata)
WORDS := [?]string{"the", "quick", "brown", "fox", "jumps", "over", "lazy", "dog", "", "fox\x00"}

random_words :: proc(length, vocabulary: int) -> []string {
	s := make([]string, length)
	for &x in s {
		x = WORDS[rand.int_max(min(vocabulary, len(WORDS)))]
	}
	return s
}

Counting_Allocator :: struct {
	backing: runtime.Allocator,
	allocs:  int,
	frees:   int,
	fail:    bool, // every allocation fails
}

counting_allocator :: proc(ca: ^Counting_Allocator) -> runtime.Allocator {
	return {counting_allocator_proc, ca}
}

counting_allocator_proc :: proc(data: rawptr, mode: runtime.Allocator_Mode, size, alignment: int, old_memory: rawptr, old_size: int, loc := #caller_location) -> ([]byte, runtime.Allocator_Error) {
	ca := (^Counting_Allocator)(data)
	#partial switch mode {
	case .Alloc, .Alloc_Non_Zeroed:
		if ca.fail {
			return nil, .Out_Of_Memory
		}
		ca.allocs += 1
	case .Free:
		ca.frees += 1
	}
	return ca.backing.procedure(ca.backing.data, mode, size, alignment, old_memory, old_size, loc)
}

Folded :: struct {
	equals: int,
	hashes: int,
}

// Case-insensitive equality, counting its calls through `user_data`.
folded_equal :: proc(x, y: string, user_data: rawptr) -> bool {
	(^Folded)(user_data).equals += 1
	return strings.equal_fold(x, y)
}

folded_hash :: proc(x: string, user_data: rawptr) -> u64 {
	(^Folded)(user_data).hashes += 1
	h := u64(14695981039346656037)
	for c in transmute([]byte)x {
		h = (h ~ u64(c | 0x20)) * 1099511628211
	}
	return h
}

constant_hash :: proc(x: string, _: rawptr) -> u64 {
	return 7
}

string_equal :: proc(x, y: string, _: rawptr) -> bool {
	return x == y
}


/*
	Tests
*/

@(test)
test_generic_ints :: proc(t: ^testing.T) {
	rand.reset(t.seed)
	for _ in 0..<100 {
		alphabet := 1 + rand.int_max(12)
		a32 := random_sequence(rand.int_max(200), alphabet)
		defer delete(a32)
		b32 := mutate(a32, rand.int_max(40), alphabet)
		defer delete(b32)

		// Widen and spread the values, so they are nothing like dense IDs
		a := make([]int, len(a32))
		defer delete(a)
		b := make([]int, len(b32))
		defer delete(b)
		for x, k in a32 {
			a[k] = int(x)*1_000_003 - 500
		}
		for x, k in b32 {
			b[k] = int(x)*1_000_003 - 500
		}

		for opts in PAIR_OPTIONS {
			c := must(diff.diff(a, b, context.allocator, context.allocator, opts = opts))
			defer diff.changes_destroy(c, context.allocator)
			if !check_matches_interned(t, a, b, c, opts) {
				return
			}
		}
	}
}

@(test)
test_generic_strings :: proc(t: ^testing.T) {
	rand.reset(t.seed)
	for _ in 0..<100 {
		vocabulary := 1 + rand.int_max(len(WORDS))
		a := random_words(rand.int_max(150), vocabulary)
		defer delete(a)
		b := random_words(rand.int_max(150), vocabulary)
		defer delete(b)

		c := must(diff.diff(a, b, context.allocator, context.allocator))
		defer diff.changes_destroy(c, context.allocator)
		if !check_matches_interned(t, a, b, c, {}) {
			return
		}
	}
}

@(test)
test_generic_structs :: proc(t: ^testing.T) {
	Token :: struct {
		kind: u8,
		text: string,
		line: i32,
	}
	a := []Token{{1, "x", 1}, {2, "y", 1}, {1, "x", 2}, {3, "", 0}, {2, "y", 1}}
	b := []Token{{2, "y", 1}, {1, "x", 1}, {3, "", 0}, {1, "z", 1}, {2, "y", 1}}

	c := must(diff.diff(a, b, context.allocator, context.allocator))
	defer diff.changes_destroy(c, context.allocator)
	check_matches_interned(t, a, b, c, {})
}

@(test)
test_generic_empty :: proc(t: ^testing.T) {
	x := []string{"a", "b"}

	c := must(diff.diff([]string{}, []string{}, context.allocator, context.allocator))
	defer diff.changes_destroy(c, context.allocator)
	testing.expect_value(t, diff.stats(c), diff.Stats{})

	c_insert := must(diff.diff([]string{}, x, context.allocator, context.allocator))
	defer diff.changes_destroy(c_insert, context.allocator)
	testing.expect_value(t, diff.stats(c_insert), diff.Stats{inserted = 2})

	c_delete := must(diff.diff(x, []string{}, context.allocator, context.allocator))
	defer diff.changes_destroy(c_delete, context.allocator)
	testing.expect_value(t, diff.stats(c_delete), diff.Stats{deleted = 2})
}

@(test)
test_diff_by_custom_equality :: proc(t: ^testing.T) {
	a := []string{"Hello", "World", "foo", "BAR", "baz"}
	b := []string{"hello", "world", "FOO", "qux", "bar", "Baz"}

	folded: Folded
	c := must(diff.diff_by(a, b, folded_equal, folded_hash, &folded, context.allocator, context.allocator))
	defer diff.changes_destroy(c, context.allocator)

	testing.expect_value(t, folded.hashes, len(a) + len(b))
	testing.expect(t, folded.equals > 0, "equal was never called through user_data")

	// The same as diffing the lowered strings
	lower_a := make([]string, len(a))
	defer delete(lower_a)
	lower_b := make([]string, len(b))
	defer delete(lower_b)
	for s, k in a {
		lower_a[k] = strings.to_lower(s, context.temp_allocator)
	}
	for s, k in b {
		lower_b[k] = strings.to_lower(s, context.temp_allocator)
	}
	expected := must(diff.diff(lower_a, lower_b, context.allocator, context.allocator))
	defer diff.changes_destroy(expected, context.allocator)
	testing.expect(t, slice.equal(c.bits, expected.bits), "case-insensitive diff differs from diffing the lowered strings")
	testing.expect_value(t, diff.stats(c), diff.Stats{equal = 5, inserted = 1})
}

// Every token hashing the same must still be correct: `equal` alone tells the tokens apart.
@(test)
test_diff_by_hash_collisions :: proc(t: ^testing.T) {
	rand.reset(t.seed)
	for _ in 0..<50 {
		a := random_words(rand.int_max(80), len(WORDS))
		defer delete(a)
		b := random_words(rand.int_max(80), len(WORDS))
		defer delete(b)

		c := must(diff.diff_by(a, b, string_equal, constant_hash, nil, context.allocator, context.allocator))
		defer diff.changes_destroy(c, context.allocator)
		if !check_matches_interned(t, a, b, c, {}) {
			return
		}
	}
}

// The convenience procedures make exactly one allocation from each allocator, and free only the scratch.
@(test)
test_allocations :: proc(t: ^testing.T) {
	a := []string{"a", "b", "c", "d"}
	b := []string{"a", "c", "d", "e"}

	result    := Counting_Allocator{backing = context.allocator}
	transient := Counting_Allocator{backing = context.allocator}

	c := must(diff.diff(a, b, counting_allocator(&result), counting_allocator(&transient)))
	testing.expect_value(t, result.allocs, 1)
	testing.expect_value(t, result.frees, 0)
	testing.expect_value(t, transient.allocs, 1)
	testing.expect_value(t, transient.frees, 1)
	diff.changes_destroy(c, counting_allocator(&result))
	testing.expect_value(t, result.frees, 1)
}

// When the scratch cannot be had, the result is freed again; the test runner reports any leak.
@(test)
test_allocation_failure :: proc(t: ^testing.T) {
	a := []string{"a", "b"}
	b := []string{"b", "c"}

	result    := Counting_Allocator{backing = context.allocator}
	transient := Counting_Allocator{backing = context.allocator, fail = true}

	c, err := diff.diff(a, b, counting_allocator(&result), counting_allocator(&transient))
	testing.expect_value(t, err, runtime.Allocator_Error.Out_Of_Memory)
	testing.expect_value(t, len(c.bits), 0)
	testing.expect_value(t, result.allocs, 1)
	testing.expect_value(t, result.frees, 1)
}

// One fixed buffer exactly big enough for the result and the scratch, used as both allocators.
@(test)
test_single_arena :: proc(t: ^testing.T) {
	rand.reset(t.seed)
	a := random_words(500, len(WORDS))
	defer delete(a)
	b := random_words(450, len(WORDS))
	defer delete(b)

	needed := diff.changes_size(len(a), len(b))*size_of(u64) + diff.scratch_size(len(a), len(b))
	buf := make([]byte, needed + 8) // the result is aligned to 8
	defer delete(buf)

	arena: mem.Arena
	mem.arena_init(&arena, buf)
	arena_allocator := mem.arena_allocator(&arena)

	c, err := diff.diff(a, b, arena_allocator, arena_allocator)
	testing.expect_value(t, err, nil)
	check_matches_interned(t, a, b, c, {})
}

// Scratch of exactly `scratch_size` bytes must work at every alignment.
@(test)
test_generic_scratch_alignment :: proc(t: ^testing.T) {
	rand.reset(t.seed)
	a := random_words(300, len(WORDS))
	defer delete(a)
	b := random_words(320, len(WORDS))
	defer delete(b)

	size := diff.scratch_size(len(a), len(b))
	buf  := make([]byte, size + 16)
	defer delete(buf)

	for offset in 0..<16 {
		c := must(diff.changes_make(len(a), len(b), context.allocator))
		defer diff.changes_destroy(c, context.allocator)
		diff.diff_buffer(a, b, c, buf[offset:][:size])
		if !check_matches_interned(t, a, b, c, {}) {
			return
		}
	}
}
