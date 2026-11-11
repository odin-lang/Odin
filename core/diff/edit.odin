package diff

import "base:runtime"

DEFAULT_CONTEXT_LEN :: 3

// What happened to a run of tokens.
Op :: enum u8 {
	Equal,
	Delete,
	Insert,
}

/*
	A run of tokens with the same `Op`: the token ranges `a[a_lo:a_hi]` and `b[b_lo:b_hi]`.
	A `.Delete` has an empty `b` range. An `.Insert` has an empty `a` range.
*/
Edit :: struct {
	op:         Op,
	a_lo, a_hi: int,
	b_lo, b_hi: int,
}

// The token ranges of a group of changes and up to `context_len` equal tokens around it.
Hunk :: struct {
	a_lo, a_hi: int,
	b_lo, b_hi: int,
}

Edit_Iterator :: struct {
	changes:    Changes,
	i, j:       int, // the next token on each side
	a_hi, b_hi: int, // where iteration stops on each side
}

Hunk_Iterator :: struct {
	changes:     Changes,
	context_len: int,
	i, j:        int, // the next token on each side
}


// Makes an iterator over every edit in `c`.
@(require_results)
edit_iterator_make :: proc "contextless" (c: Changes) -> Edit_Iterator {
	return {changes = c, a_hi = c.n, b_hi = c.m}
}

// Makes an iterator over the edits inside `h`, including its context.
@(require_results)
edit_iterator_make_hunk :: proc "contextless" (c: Changes, h: Hunk) -> Edit_Iterator {
	return {changes = c, i = h.a_lo, j = h.b_lo, a_hi = h.a_hi, b_hi = h.b_hi}
}

/*
	Iterates over edits in order. Never allocates.

	Usage:
		it := diff.edit_iterator_make(changes)
		for e in diff.edit_iterate(&it) {
			...
		}
*/
@(require_results)
edit_iterate :: proc "contextless" (it: ^Edit_Iterator) -> (e: Edit, ok: bool) {
	c := it.changes
	i, j := it.i, it.j

	switch {
	case i < it.a_hi && is_deleted(c, i):
		e = {.Delete, i, i + _deleted_run(c, i, it.a_hi), j, j}
	case j < it.b_hi && is_inserted(c, j):
		e = {.Insert, i, i, j, j + _inserted_run(c, j, it.b_hi)}
	case i < it.a_hi && j < it.b_hi:
		n := _equal_run(c, i, j, it.a_hi, it.b_hi)
		e = {.Equal, i, i + n, j, j + n}
	case i < it.a_hi || j < it.b_hi:
		panic_contextless("changes do not describe a diff: kept tokens are left over on one side")
	case:
		return
	}
	it.i, it.j = e.a_hi, e.b_hi
	return e, true
}

@(require_results)
edit_count :: proc "contextless" (c: Changes) -> (count: int) {
	it := edit_iterator_make(c)
	for _ in edit_iterate(&it) {
		count += 1
	}
	return
}

// Fills `buf` with every edit in `c` and returns the filled part. `buf` must hold at least `edit_count(c)` edits.
@(require_results)
edits_fill :: proc(c: Changes, buf: []Edit, loc := #caller_location) -> []Edit {
	n := 0
	it := edit_iterator_make(c)
	for e in edit_iterate(&it) {
		assert(n < len(buf), "buffer too small for the edits", loc)
		buf[n] = e
		n += 1
	}
	return buf[:n]
}

// Allocates exactly `edit_count(c)` edits and fills them.
@(require_results)
edits_make :: proc(c: Changes, allocator: runtime.Allocator, loc := #caller_location) -> (edits: []Edit, err: runtime.Allocator_Error) {
	edits = make([]Edit, edit_count(c), allocator, loc) or_return
	return edits_fill(c, edits, loc), nil
}


// A negative `context_len` is treated as 0.
@(require_results)
hunk_iterator_make :: proc "contextless" (c: Changes, context_len := DEFAULT_CONTEXT_LEN) -> Hunk_Iterator {
	return {changes = c, context_len = max(context_len, 0)}
}

/*
	Iterates over hunks in order. Hunks whose context would overlap or touch are merged. Never allocates.

	Usage:
		hunks := diff.hunk_iterator_make(changes)
		for h in diff.hunk_iterate(&hunks) {
			edits := diff.edit_iterator_make_hunk(changes, h)
			for e in diff.edit_iterate(&edits) {
				...
			}
		}
*/
@(require_results)
hunk_iterate :: proc "contextless" (it: ^Hunk_Iterator) -> (h: Hunk, ok: bool) {
	c   := it.changes
	ctx := it.context_len

	// Skip to the next change
	gap  := _equal_run(c, it.i, it.j, c.n, c.m)
	i, j := it.i + gap, it.j + gap
	if i == c.n && j == c.m {
		return
	}
	lead := min(ctx, gap)
	h.a_lo, h.b_lo = i - lead, j - lead

	for {
		// Take the change: its deletions, then its insertions
		deleted  := _deleted_run (c, i, c.n)
		inserted := _inserted_run(c, j, c.m)
		if deleted == 0 && inserted == 0 {
			panic_contextless("changes do not describe a diff: kept tokens are left over on one side")
		}
		i += deleted
		j += inserted

		gap = _equal_run(c, i, j, c.n, c.m)
		if gap - ctx > ctx || (i + gap == c.n && j + gap == c.m) {
			trail := min(ctx, gap)
			h.a_hi, h.b_hi = i + trail, j + trail
			it.i, it.j = i, j
			return h, true
		}

		// Close enough to the next change for their context to touch. They share a hunk
		i += gap
		j += gap
	}
}


// Returns how many equal pairs there are from `a[i]` and `b[j]`, up to `a_hi` and `b_hi`.
@(require_results)
_equal_run :: proc "contextless" (c: Changes, i, j, a_hi, b_hi: int) -> int {
	offset := _inserted_offset(c)
	return min(_bit_run(c.bits, i, a_hi, false), _bit_run(c.bits, offset + j, offset + b_hi, false))
}

// Returns how many tokens from `a[i]`, up to `a_hi`, are deleted.
@(require_results)
_deleted_run :: proc "contextless" (c: Changes, i, a_hi: int) -> int {
	return _bit_run(c.bits, i, a_hi, true)
}

// Returns how many tokens from `b[j]`, up to `b_hi`, are inserted.
@(require_results)
_inserted_run :: proc "contextless" (c: Changes, j, b_hi: int) -> int {
	offset := _inserted_offset(c)
	return _bit_run(c.bits, offset + j, offset + b_hi, true)
}
