package diff

import "base:intrinsics"
import "base:runtime"

// The algorithm used to compute a diff.
Algorithm :: enum u8 {
	Myers,              // Myers O(ND) with a cost cap; close to minimal (default)
	Minimal,            // Myers with no cost cap; always minimal, but can be slow on very different inputs
	Histogram,          // anchors on rare tokens; falls back to Myers
	Ratcliff_Obershelp, // longest common block first; not minimal; falls back to Myers at the cost cap
}

Option_Flag :: enum u8 {
	Prune,            // pre-pass: set aside the common ends, tokens with no match, and runs of very frequent tokens
	Compact,          // post-pass: slide each group of changes to where git puts it
	Indent_Heuristic, // with .Compact, for line diffs of text: slide each group by the indentation around it
}
Option_Flags :: bit_set[Option_Flag; u8]

Options :: struct {
	algorithm: Algorithm,
	flags:     Option_Flags,
	max_cost:  int, // 0 means the default heuristic; ignored by `.Minimal`
}

/*
	The result of a diff: one bit per token on each side.

	A set bit `i` on the `a` side means `a[i]` was deleted.
	A set bit `j` on the `b` side means `b[j]` was inserted.
	The `a` side is the first `(n+63)/64` words of `bits`; the `b` side is the rest.
*/
Changes :: struct {
	bits: []u64,
	n, m: int,
}

// Counts of tokens by what happened to them.
Stats :: struct {
	equal, deleted, inserted: int,
}


// Returns the number of words `Changes` needs for inputs of length `n` and `m`.
@(require_results)
changes_size :: proc "contextless" (n, m: int) -> (words: int) {
	return bit_words(n) + bit_words(m)
}

// Makes `Changes` from a caller-provided buffer of at least `changes_size(n, m)` words.
@(require_results)
changes_from_buffer :: proc(n, m: int, bits: []u64, loc := #caller_location) -> Changes {
	words := changes_size(n, m)
	assert(len(bits) >= words, "buffer too small for the changes", loc)
	return {bits[:words], n, m}
}

@(require_results)
changes_make :: proc(n, m: int, allocator: runtime.Allocator, loc := #caller_location) -> (c: Changes, err: runtime.Allocator_Error) {
	bits := make([]u64, changes_size(n, m), allocator, loc) or_return
	return {bits, n, m}, nil
}

// Frees `c` with the allocator it was made with.
changes_destroy :: proc(c: Changes, allocator: runtime.Allocator, loc := #caller_location) {
	delete(c.bits, allocator, loc)
}

@(require_results)
is_deleted :: #force_inline proc "contextless" (c: Changes, i: int) -> bool {
	return bit_get(c.bits, i)
}

@(require_results)
is_inserted :: #force_inline proc "contextless" (c: Changes, j: int) -> bool {
	return bit_get(c.bits, _inserted_offset(c) + j)
}

@(require_results)
stats :: proc "contextless" (c: Changes) -> (s: Stats) {
	a_words := bit_words(c.n)
	for w in c.bits[:a_words] {
		s.deleted += int(intrinsics.count_ones(w))
	}
	for w in c.bits[a_words:] {
		s.inserted += int(intrinsics.count_ones(w))
	}
	s.equal = c.n - s.deleted
	return
}

// Returns `2*equal / (n+m)`, from 0 (nothing in common) to 1 (identical); 1 when both inputs are empty.
@(require_results)
similarity :: proc "contextless" (c: Changes) -> f64 {
	if c.n + c.m == 0 {
		return 1
	}
	s := stats(c)
	return 2*f64(s.equal) / f64(c.n + c.m)
}


/*
	Core procedures: these never allocate.

	`scratch` may have any alignment. The scratch sizes include slack to align it.
	A buffer smaller than the size asked for is an assertion failure, not an error.
*/

/*
	Returns the scratch bytes `diff_buffer` and `diff_by_buffer` need for inputs of length `n` and `m`.

	The token IDs last the whole diff. The interning table and the algorithm share the rest, one after the other.
*/
@(require_results)
scratch_size :: proc "contextless" (n, m: int, opts := Options{}) -> int {
	tokens := n + m
	return SCRATCH_ALIGN + scratch_bytes(i32, tokens) + max(intern_scratch_size(tokens), algorithm_scratch_size(n, m, tokens, opts))
}

// Returns the scratch bytes `diff_interned_buffer` needs for already-interned inputs.
@(require_results)
scratch_size_interned :: proc "contextless" (n, m: int, id_count: int, opts := Options{}) -> int {
	return SCRATCH_ALIGN + algorithm_scratch_size(n, m, id_count, opts)
}

// Diffs already-interned inputs: equal tokens share an ID, and every ID is in `[0, id_count)`.
diff_interned_buffer :: proc(a, b: []i32, id_count: int, changes: Changes, scratch: []byte, opts := Options{}, loc := #caller_location) {
	// Positions are kept as `i32`. Interning keeps them the same way
	assert(len(a) + len(b) < int(max(i32)), "too many tokens to diff", loc)

	s := Scratch{buf = scratch}
	diff_interned_scratch(a, b, nil, id_count, changes, &s, opts, loc)
}

diff_buffer :: proc(a, b: []$T, changes: Changes, scratch: []byte, opts := Options{}, loc := #caller_location) where intrinsics.type_is_comparable(T) {
	equal :: proc(x, y: T, _: rawptr) -> bool {
		return x == y
	}
	hash :: proc(x: T, _: rawptr) -> u64 {
		x := x
		return u64(intrinsics.type_hasher_proc(T)(&x, 0))
	}
	diff_by_buffer(a, b, equal, hash, nil, changes, scratch, opts, loc)
}

// `equal` and `hash` must agree: equal tokens must hash the same.
diff_by_buffer :: proc(
	a, b:      []$T,
	equal:     proc(x, y: T, user_data: rawptr) -> bool,
	hash:      proc(x: T, user_data: rawptr) -> u64,
	user_data: rawptr,
	changes:   Changes,
	scratch:   []byte,
	opts := Options{},
	loc  := #caller_location,
) {
	n, m := len(a), len(b)
	assert(changes.n == n && changes.m == m, "changes sized for different inputs", loc)
	assert(n + m < int(max(i32)), "too many tokens to intern", loc)

	s := Scratch{buf = scratch}
	ids := scratch_take(&s, i32, n + m, loc)

	table_start := s.pos
	table := scratch_take(&s, Intern_Slot, intern_table_len(n + m), loc)
	id_count := intern(a, b, T, equal, hash, user_data, ids, table)
	s.pos = table_start

	diff_interned_scratch(ids[:n], ids[n:], nil, id_count, changes, &s, opts, loc)
}


/*
	Allocating procedures.

	Each takes its allocators explicitly:
	- `allocator` gives the returned memory. Free it with the same allocator.
	- `transient_allocator` gives the scratch. It lives only for the call.

	The result is allocated first and the scratch last. The scratch is freed before returning, even when
	allocating it fails. Heap allocators never leak. Allocators that free in reverse order (e.g. `mem.Stack`)
	work when passed as both.

	One bump arena passed as both cannot free the scratch. It stays until the arena is reset. Use separate
	arenas for the two lifetimes, or a `*_buffer` procedure with scratch from a temporary region of the arena.
*/

@(require_results)
diff :: proc(
	a, b:                []$T,
	allocator:           runtime.Allocator,
	transient_allocator: runtime.Allocator,
	opts := Options{},
	loc  := #caller_location,
) -> (c: Changes, err: runtime.Allocator_Error) where intrinsics.type_is_comparable(T) {
	scratch: []byte
	c, scratch = _changes_and_scratch_make(
		len(a),
		len(b),
		scratch_size(len(a), len(b), opts),
		allocator,
		transient_allocator,
		loc,
	) or_return
	diff_buffer(a, b, c, scratch, opts, loc)
	delete(scratch, transient_allocator, loc)
	return
}

@(require_results)
diff_by :: proc(
	a, b:                []$T,
	equal:               proc(x, y: T, user_data: rawptr) -> bool,
	hash:                proc(x: T, user_data: rawptr) -> u64,
	user_data:           rawptr,
	allocator:           runtime.Allocator,
	transient_allocator: runtime.Allocator,
	opts := Options{},
	loc  := #caller_location,
) -> (c: Changes, err: runtime.Allocator_Error) {
	scratch: []byte
	c, scratch = _changes_and_scratch_make(
		len(a),
		len(b),
		scratch_size(len(a), len(b), opts),
		allocator,
		transient_allocator,
		loc,
	) or_return
	diff_by_buffer(a, b, equal, hash, user_data, c, scratch, opts, loc)
	delete(scratch, transient_allocator, loc)
	return
}

@(require_results)
diff_interned :: proc(
	a, b:                []i32,
	id_count:            int,
	allocator:           runtime.Allocator,
	transient_allocator: runtime.Allocator,
	opts := Options{},
	loc  := #caller_location,
) -> (c: Changes, err: runtime.Allocator_Error) {
	scratch: []byte
	c, scratch = _changes_and_scratch_make(
		len(a), len(b),
		scratch_size_interned(len(a), len(b), id_count, opts),
		allocator,
		transient_allocator,
		loc,
	) or_return
	diff_interned_buffer(a, b, id_count, c, scratch, opts, loc)
	delete(scratch, transient_allocator, loc)
	return
}


/*
	Scratch for diffing interned tokens: the `.Prune` pre-pass, if asked for, and the algorithm.
	`.Compact` runs once they are done. Its scratch for `.Histogram` reuses theirs.
*/
@(private, require_results)
algorithm_scratch_size :: proc "contextless" (n, m: int, id_count: int, opts: Options) -> int {
	size := unpruned_scratch_size(n, m, id_count, opts)
	if .Prune in opts.flags {
		size = prune_scratch_size(n, m, id_count, opts)
	}
	if .Compact in opts.flags && opts.algorithm == .Histogram {
		size = max(size, rediff_scratch_size(n, m, id_count))
	}
	return size
}

// Scratch for the algorithm alone.
@(private, require_results)
unpruned_scratch_size :: proc "contextless" (n, m: int, id_count: int, opts: Options) -> int {
	switch opts.algorithm {
	case .Myers, .Minimal:
		return myers_scratch_size(n, m)
	case .Histogram:
		return histogram_scratch_size(n, m, id_count)
	case .Ratcliff_Obershelp:
		return ratcliff_obershelp_scratch_size(n, m, id_count)
	}
	return 0
}

// `indents` holds the indent of each line of `a` then `b`, for `.Indent_Heuristic`; only text has them.
@(private)
diff_interned_scratch :: proc(
	a, b:     []i32,
	indents:  []u8,
	id_count: int,
	changes:  Changes,
	s:        ^Scratch,
	opts:     Options,
	loc := #caller_location,
) {
	assert(changes.n == len(a), "changes sized for different inputs", loc)
	assert(changes.m == len(b), "changes sized for different inputs", loc)
	assert(len(changes.bits) >= changes_size(changes.n, changes.m), "buffer too small for the changes", loc)
	assert(id_count >= 0, "negative id_count", loc)

	if .Indent_Heuristic in opts.flags {
		assert(.Compact in opts.flags, ".Indent_Heuristic only applies with .Compact", loc)
		assert(indents != nil, ".Indent_Heuristic needs a line diff of text", loc)
	}

	for &w in changes.bits {
		w = 0
	}

	start := s.pos
	if .Prune in opts.flags {
		prune(a, b, id_count, changes, s, opts, loc)
	} else {
		run_algorithm(a, b, id_count, changes, s, opts, loc)
	}

	// The scratch of what ran before is free again
	if .Compact in opts.flags {
		s.pos = start
		compact(a, b, indents, id_count, changes, s, opts, loc)
	}
}

// Runs the chosen algorithm into `changes`. `changes` must already be zeroed.
@(private)
run_algorithm :: proc(a, b: []i32, id_count: int, changes: Changes, s: ^Scratch, opts: Options, loc := #caller_location) {
	switch opts.algorithm {
	case .Myers, .Minimal:
		myers(a, b, changes, s, opts.algorithm == .Minimal, opts.max_cost, loc)
	case .Histogram:
		histogram(a, b, id_count, changes, s, opts.max_cost, loc)
	case .Ratcliff_Obershelp:
		ratcliff_obershelp(a, b, id_count, changes, s, opts.max_cost, loc)
	}
}

// Allocates the result first, then the scratch; if the scratch fails, the result is freed again.
@(require_results)
_changes_and_scratch_make :: proc(
	n, m:                int,
	scratch_len:         int,
	allocator:           runtime.Allocator,
	transient_allocator: runtime.Allocator,
	loc := #caller_location,
) -> (c: Changes, scratch: []byte, err: runtime.Allocator_Error) {

	c = changes_make(n, m, allocator, loc) or_return
	scratch, err = make([]byte, scratch_len, transient_allocator, loc)
	if err != nil {
		changes_destroy(c, allocator, loc)
		c = {}
	}
	return
}


@(private, require_results)
bit_words :: #force_inline proc "contextless" (n: int) -> int {
	return (n + 63) >> 6
}

// Where the bits of `b` start in `c.bits`: after those of `a`, rounded up to a whole word.
@(require_results)
_inserted_offset :: #force_inline proc "contextless" (c: Changes) -> int {
	return bit_words(c.n)*64
}

@(private, require_results)
bit_get :: #force_inline proc "contextless" (bits: []u64, i: int) -> bool {
	return bits[i >> 6] & (u64(1) << uint(i & 63)) != 0
}

// Marks `a[lo:hi]` as deleted.
_mark_deleted :: proc "contextless" (c: Changes, lo, hi: int) {
	_set_bit_range(c.bits, lo, hi)
}

// Marks `b[lo:hi]` as inserted.
_mark_inserted :: proc "contextless" (c: Changes, lo, hi: int) {
	offset := _inserted_offset(c)
	_set_bit_range(c.bits, offset + lo, offset + hi)
}

_set_bit_range :: proc "contextless" (bits: []u64, lo, hi: int) {
	for i in lo..<hi {
		mask := u64(1) << uint(i & 63)
		bits[i >> 6] |= mask
	}
}

// Returns how many bits from `lo` up to `hi` are all set, or all clear when `set` is false.
@(require_results)
_bit_run :: proc "contextless" (bits: []u64, lo, hi: int, set: bool) -> int {
	for i := lo; i < hi; /**/ {
		w := bits[i >> 6]
		if !set {
			w = ~w
		}

		shift := uint(i & 63)
		left  := 64 - int(shift)

		// A 1 for each bit that differs including the bits shifted in at the top
		miss := ~(w >> shift)

		run  := 64
		if miss != 0 {
			run = int(intrinsics.count_trailing_zeros(miss))
		}

		if run < left {
			return min(i + run, hi) - lo
		}
		i += left
	}
	return hi - lo
}