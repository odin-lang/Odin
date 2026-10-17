#+private
package diff

/*
	Histogram diff. Each region is split around a run of equal tokens anchored on its rarest tokens. The regions
	before and after the run are then diffed the same way. How rare a token is counts only the region of `a`.

	A token occurring more than `HISTOGRAM_MAX_OCCURRENCES` times in the region cannot anchor a run. A region whose
	tokens in common are all that frequent is diffed again by `rediff`: Myers after `.Prune`'s preparation.
*/

// A token occurring more often than this in the region of `a` is too frequent to anchor on.
HISTOGRAM_MAX_OCCURRENCES :: 64

// The end of a chain of occurrences.
HISTOGRAM_NONE :: -1

Histogram :: struct {
	a, b:  []i32,
	count: []i32, // the occurrences of each ID in the region of `a`, zero outside a search
	first: []i32, // the first occurrence of each ID in the region of `a`, wherever `count` is not 0
	next:  []i32, // the next occurrence of `a[i]` in the region, or `HISTOGRAM_NONE`
}

// What the search of a region found.
Histogram_Found :: enum u8 {
	Nothing,   // no tokens in common
	Run,       // a run to split around
	Fall_Back, // only tokens too frequent to anchor on
}

@(require_results)
histogram_scratch_size :: proc "contextless" (n, m: int, id_count: int) -> int {
	return 2*scratch_bytes(i32, id_count) + scratch_bytes(i32, n) + rediff_scratch_size(n, m, id_count)
}

// Diffs `a` against `b` into zeroed `changes`. Gives back its scratch.
histogram :: proc(a, b: []i32, id_count: int, changes: Changes, s: ^Scratch, max_cost: int, loc := #caller_location) {
	start := s.pos
	h := Histogram{
		a     = a,
		b     = b,
		count = scratch_take(s, i32, id_count, loc),
		first = scratch_take(s, i32, id_count, loc),
		next  = scratch_take(s, i32, len(a),   loc),
	}
	for &x in h.count {
		x = 0
	}

	stack: [MYERS_MAX_DEPTH]Box
	depth := 0
	box   := Box{0, len(a), 0, len(b), false}
	for {
		switch {
		case box.a_lo == box.a_hi:
			_mark_inserted(changes, box.b_lo, box.b_hi)

		case box.b_lo == box.b_hi:
			_mark_deleted(changes, box.a_lo, box.a_hi)

		case:
			run, found := histogram_best_run(&h, box)
			switch found {
			case .Fall_Back:
				this  := Compact_Side{a, 0, nil}
				other := Compact_Side{b, _inserted_offset(changes), nil}
				rediff(changes, this, other, {box.a_lo, box.a_hi}, {box.b_lo, box.b_hi}, id_count, max_cost, s, loc)

			case .Nothing:
				_mark_deleted(changes, box.a_lo, box.a_hi)
				_mark_inserted(changes, box.b_lo, box.b_hi)

			case .Run:
				lo := Box{box.a_lo, run.a_lo, box.b_lo, run.b_lo, false}
				hi := Box{run.a_hi, box.a_hi, run.b_hi, box.b_hi, false}

				// The smaller side first, keeping the stack within `MYERS_MAX_DEPTH`
				if box_size(lo) <= box_size(hi) {
					stack[depth] = hi
					box = lo
				} else {
					stack[depth] = lo
					box = hi
				}
				depth += 1
				continue
			}
		}

		if depth == 0 {
			break
		}
		depth -= 1
		box = stack[depth]
	}
	s.pos = start
}

/*
	Finds the run of equal tokens to split `box` around. Both sides are non-empty.

	Each token of `b`, in order, anchors a run at every occurrence of its ID in `a` when it is rare enough. The
	run grows both ways. It is the best if it is longer than the best so far, or if its rarest token is rarer.
	Tokens of `b` inside a run are not tried on their own.
*/
@(require_results)
histogram_best_run :: proc(h: ^Histogram, box: Box) -> (run: Box, found: Histogram_Found) {
	a, b  := h.a, h.b
	count := h.count
	first := h.first
	next  := h.next

	// Chain the occurrences of each ID in the region of `a`, from the lowest index
	for i := box.a_hi - 1; i >= box.a_lo; i -= 1 {
		id := a[i]
		next[i] = HISTOGRAM_NONE
		if count[id] > 0 {
			next[i] = first[id]
		}
		first[id] = i32(i)
		count[id] += 1
	}

	best_count := HISTOGRAM_MAX_OCCURRENCES + 1
	best_span  := 0 // the best run's length in `a` minus one
	has_common := false
	has_run    := false
	for j := box.b_lo; j < box.b_hi; /**/ {
		next_j := j + 1
		c      := int(count[b[j]])
		switch {
		case c == 0:
			// Not in the region of `a`
		case c > best_count:
			has_common = true
		case:
			has_common = true
			for i := int(first[b[j]]); i != HISTOGRAM_NONE; /**/ {
				// Grow the run around `a[i] == b[j]`, noting its rarest token
				rarest := c
				a_lo, b_lo := i, j
				for a_lo > box.a_lo && b_lo > box.b_lo && a[a_lo-1] == b[b_lo-1] {
					a_lo -= 1
					b_lo -= 1
					if rarest > 1 {
						rarest = min(rarest, int(count[a[a_lo]]))
					}
				}
				a_last, b_last := i, j
				for a_last < box.a_hi - 1 && b_last < box.b_hi - 1 && a[a_last+1] == b[b_last+1] {
					a_last += 1
					b_last += 1
					if rarest > 1 {
						rarest = min(rarest, int(count[a[a_last]]))
					}
				}

				next_j = max(next_j, b_last + 1)
				if a_last - a_lo > best_span || rarest < best_count {
					run        = {a_lo, a_last + 1, b_lo, b_last + 1, false}
					best_span  = a_last - a_lo
					best_count = rarest
					has_run    = true
				}

				// The next occurrence past the run
				i = int(next[i])
				for i != HISTOGRAM_NONE && i <= a_last {
					i = int(next[i])
				}
			}
		}
		j = next_j
	}

	// Leave the counts zeroed for the next region
	for i in box.a_lo..<box.a_hi {
		count[a[i]] = 0
	}

	switch {
	case has_common && best_count > HISTOGRAM_MAX_OCCURRENCES:
		found = .Fall_Back
	case has_run:
		found = .Run
	case:
		found = .Nothing
	}
	return
}
