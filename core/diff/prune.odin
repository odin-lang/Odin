#+private
package diff

/*
	The `.Prune` pre-pass. It sets aside the common prefix and suffix, the tokens with no match on the other side,
	and some of the frequent tokens among those. The algorithm then diffs only the tokens kept, and its result is
	mapped back.

	A token is frequent when its ID occurs on the other side about `sqrt(n)` times or more, for this side's length
	`n`. No token is frequent with `.Minimal`. A frequent token is set aside only from inside a run of tokens that
	are not kept, with tokens that have no match on both sides of it, and only when few of that run are frequent.
*/

// The limit for a frequent token is never higher than this.
PRUNE_MAX_MATCHES :: 1024

// How far to look back and ahead from a frequent token.
PRUNE_WINDOW :: 100

// A frequent token is set aside when fewer than one in this many of the run around it are frequent.
PRUNE_RUN_FACTOR :: 4

// What the other side says about a token of a middle.
Prune_Class :: enum u8 {
	Discard,  // no match: set aside
	Keep,     // a few matches: kept
	Frequent, // many matches: decided by the tokens around it
}

/*
	The kept tokens and their `Changes` come first. The counts and classes come next. The algorithm reuses their
	space once they are done.
*/
@(require_results)
prune_scratch_size :: proc "contextless" (n, m: int, id_count: int, opts: Options) -> int {
	kept      := scratch_bytes(i32, n) + scratch_bytes(i32, m)
	classes   := 2*scratch_bytes(i32, id_count) + scratch_bytes(Prune_Class, n) + scratch_bytes(Prune_Class, m)
	algorithm := scratch_bytes(u64, changes_size(n, m)) + unpruned_scratch_size(n, m, id_count, opts)
	return kept + max(classes, algorithm)
}

// Diffs `a` against `b` into zeroed `changes`, with the tokens that cannot usefully match set aside.
prune :: proc(a, b: []i32, id_count: int, changes: Changes, s: ^Scratch, opts: Options, loc := #caller_location) {
	// Gives each token of `ids` its class, by the occurrences of its ID in the whole of the other side
	classify :: proc "contextless" (class: []Prune_Class, ids: []i32, other_count: []i32, limit: int) {
		for id, i in ids {
			count := int(other_count[id])
			switch {
			case count == 0:     class[i] = .Discard
			case count <  limit: class[i] = .Keep
			case:                class[i] = .Frequent
			}
		}
	}

	/*
		Counts the tokens that are not kept, from `class[from]` on by `step`, for `PRUNE_WINDOW` tokens at most.
		Stops at the first kept token or at the end of the middle.
	*/
	@(require_results)
	count_run :: proc "contextless" (class: []Prune_Class, from, step: int) -> (discards, frequent: int) {
		frequent = 1
		for r, steps := from, 0; 0 <= r && r < len(class) && steps < PRUNE_WINDOW; r, steps = r + step, steps + 1 {
			switch class[r] {
			case .Keep:     return
			case .Discard:  discards += 1
			case .Frequent: frequent += 1
			}
		}
		return
	}

	// Whether the frequent token at `class[i]` is set aside: discards on both sides, and few frequent tokens
	@(require_results)
	set_aside :: proc "contextless" (class: []Prune_Class, i: int) -> bool {
		back_discards, back_frequent := count_run(class, i - 1, -1)
		if back_discards == 0 {
			return false
		}
		ahead_discards, ahead_frequent := count_run(class, i + 1, +1)
		if ahead_discards == 0 {
			return false
		}

		frequent := back_frequent + ahead_frequent
		discards := back_discards + ahead_discards
		return frequent*PRUNE_RUN_FACTOR < frequent + discards
	}

	/*
		Copies the kept tokens of a middle to `kept`, and sets the bits of the others from `offset` in `bits`.
		Each frequent token is decided from the classes alone.
	*/
	@(require_results)
	keep :: proc "contextless" (kept: []i32, ids: []i32, class: []Prune_Class, bits: []u64, offset: int) -> (count: int) {
		for id, i in ids {
			if class[i] == .Keep || (class[i] == .Frequent && !set_aside(class, i)) {
				kept[count] = id
				count += 1
			} else {
				_set_bit_range(bits, offset + i, offset + i + 1)
			}
		}
		return
	}

	// Copies the shorter diff's bits, from `kept[kept_lo]` on, to the kept tokens of `bits[lo:hi]`: those still clear
	map_back :: proc "contextless" (bits: []u64, lo, hi: int, kept: []u64, kept_lo: int) {
		i := lo
		k := kept_lo
		for i < hi {
			i += _bit_run(bits, i, hi, true)

			run := _bit_run(bits, i, hi, false)
			for t := 0; t < run; /**/ {
				t += _bit_run(kept, k + t, k + run, false)

				changed := _bit_run(kept, k + t, k + run, true)
				_set_bit_range(bits, i + t, i + t + changed)

				t += changed
			}

			i += run
			k += run
		}
	}


	n, m := len(a), len(b)

	// The common ends are equal: nothing to mark
	prefix := 0
	for prefix < n && prefix < m && a[prefix] == b[prefix] {
		prefix += 1
	}
	suffix := 0
	for suffix < n - prefix && suffix < m - prefix && a[n-1-suffix] == b[m-1-suffix] {
		suffix += 1
	}
	a_mid := a[prefix:n-suffix]
	b_mid := b[prefix:m-suffix]

	// With one middle empty, every token of the other is a change whatever it is classed as
	switch {
	case len(a_mid) == 0:
		_mark_inserted(changes, prefix, m - suffix)
		return
	case len(b_mid) == 0:
		_mark_deleted(changes, prefix, n - suffix)
		return
	}

	start  := s.pos
	kept_a := scratch_take(s, i32, len(a_mid), loc)
	kept_b := scratch_take(s, i32, len(b_mid), loc)

	// The counts and classes are done once the kept tokens are known
	counted := s.pos
	a_count := scratch_take(s, i32, id_count, loc)
	b_count := scratch_take(s, i32, id_count, loc)
	for &x in a_count {
		x = 0
	}
	for &x in b_count {
		x = 0
	}
	for id in a {
		a_count[id] += 1
	}
	for id in b {
		b_count[id] += 1
	}

	// Each side's limit comes from its own whole length
	a_limit := max(int)
	b_limit := max(int)
	if opts.algorithm != .Minimal {
		a_limit = min(rough_sqrt(n), PRUNE_MAX_MATCHES)
		b_limit = min(rough_sqrt(m), PRUNE_MAX_MATCHES)
	}

	a_class := scratch_take(s, Prune_Class, len(a_mid), loc)
	b_class := scratch_take(s, Prune_Class, len(b_mid), loc)
	classify(a_class, a_mid, b_count, a_limit)
	classify(b_class, b_mid, a_count, b_limit)

	a_offset := prefix
	b_offset := _inserted_offset(changes) + prefix
	kept_n := keep(kept_a, a_mid, a_class, changes.bits, a_offset)
	kept_m := keep(kept_b, b_mid, b_class, changes.bits, b_offset)
	s.pos = counted

	// Diff what is kept, then map it back
	words := scratch_take(s, u64, changes_size(kept_n, kept_m), loc)
	for &w in words {
		w = 0
	}
	kept := changes_from_buffer(kept_n, kept_m, words, loc)
	run_algorithm(kept_a[:kept_n], kept_b[:kept_m], id_count, kept, s, opts, loc)

	map_back(changes.bits, a_offset, a_offset + len(a_mid), kept.bits, 0)
	map_back(changes.bits, b_offset, b_offset + len(b_mid), kept.bits, _inserted_offset(kept))
	s.pos = start
}
