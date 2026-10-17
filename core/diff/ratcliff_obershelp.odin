#+private
package diff

/*
	Ratcliff/Obershelp ("gestalt pattern matching"). Split each region around its longest common block, then
	diff both sides the same way. Ties go to the block ending earliest in `a`, then earliest in `b`.
	Not minimal, but the matches are long and contiguous.

	Dynamic programming over two rows finds the longest block. `row[j+1]` is the length of the run of matches
	ending at the current token of `a` and at `b[j]`. A row holds only the runs reaching it, listed by
	position. The rows stay sparse and are cleared through the same lists.

	A token occurring in `b` more than `RO_FREQUENT` times (often `}` or a blank line in code) can carry a run
	on but never start one. Its row only continues the runs that reached the token before it. That costs no
	more than there are runs, however often the token occurs. Any other token's row starts a run at each of
	its occurrences, found through a chain. A block's length counts the frequent tokens inside it. The chosen
	block grows back through any equal tokens just before it. A region with only frequent tokens in common
	goes to Myers.

	The search can still be quadratic when tokens repeat a lot. The whole diff has a budget of
	`RO_STEPS_PER_TOKEN * (n+m)` steps, or `max_cost * (n+m)` when that is set. Myers diffs the regions left
	when it runs out, and any region whose search would overrun it.
*/

// The default budget for the whole diff, in search steps per token.
RO_STEPS_PER_TOKEN :: 64

// A token occurring in `b` more often than this cannot start a block. Histogram's anchors have the same limit.
RO_FREQUENT :: 64

// The end of a chain of occurrences.
RO_NONE :: -1
//
Ratcliff_Obershelp :: struct {
	a, b:      []i32,
	first:     []i32, // the first occurrence of each ID in the region of `b` being searched, or `RO_NONE`
	next:      []i32, // the next occurrence of `b[j]` in that region, or `RO_NONE`
	b_count:   []i32, // occurrences of each ID in the whole of `b`
	prev, cur: []i32, // the rows: the length of the run ending at `b[j]` is at index `j+1`
	prev_at:   []i32, // where in `b` the runs of `prev` end, the first `prev_len` of them
	cur_at:    []i32,
	prev_len:  int,
	myers:     Myers,
	max_cost:  int,
	work_left: int,
}

@(require_results)
ratcliff_obershelp_scratch_size :: proc "contextless" (n, m: int, id_count: int) -> int {
	chains := scratch_bytes(i32, id_count) + scratch_bytes(i32, m)
	counts := scratch_bytes(i32, id_count)
	rows   := 2*scratch_bytes(i32, m+1) + 2*scratch_bytes(i32, m)
	return chains + counts + rows + myers_scratch_size(n, m)
}

ratcliff_obershelp :: proc(a, b: []i32, id_count: int, changes: Changes, s: ^Scratch, max_cost: int, loc := #caller_location) {
	n, m := len(a), len(b)
	ro := Ratcliff_Obershelp{
		a         = a,
		b         = b,
		first     = scratch_take(s, i32, id_count, loc),
		next      = scratch_take(s, i32, m,        loc),
		b_count   = scratch_take(s, i32, id_count, loc),
		prev      = scratch_take(s, i32, m+1,      loc),
		cur       = scratch_take(s, i32, m+1,      loc),
		prev_at   = scratch_take(s, i32, m,        loc),
		cur_at    = scratch_take(s, i32, m,        loc),
		myers     = myers_make(a, b, s, loc),
		max_cost  = max_cost,
		work_left = RO_STEPS_PER_TOKEN * (n + m),
	}
	if max_cost > 0 {
		tokens := max(n + m, 1)
		ro.work_left = max_cost <= max(int)/tokens ? max_cost*tokens : max(int)
	}
	for &x in ro.first {
		x = RO_NONE
	}
	for &x in ro.prev {
		x = 0
	}
	for &x in ro.cur {
		x = 0
	}
	for &x in ro.b_count {
		x = 0
	}
	for id in b {
		ro.b_count[id] += 1
	}

	stack: [MYERS_MAX_DEPTH]Box
	depth := 0
	box   := Box{0, n, 0, m, false}
	for {
		switch {
		case box.a_lo == box.a_hi:
			_mark_inserted(changes, box.b_lo, box.b_hi)
		case box.b_lo == box.b_hi:
			_mark_deleted(changes, box.a_lo, box.a_hi)
		case:
			i, j, k, searched := ratcliff_obershelp_longest_block(&ro, box)
			switch {
			case !searched:
				region_n, region_m := box.a_hi - box.a_lo, box.b_hi - box.b_lo
				myers_box(&ro.myers, changes, box, myers_cost(ro.max_cost, region_n, region_m), loc)

			case k == 0:
				_mark_deleted(changes, box.a_lo, box.a_hi)
				_mark_inserted(changes, box.b_lo, box.b_hi)

			case:
				lo := Box{box.a_lo, i, box.b_lo, j, false}
				hi := Box{i + k, box.a_hi, j + k, box.b_hi, false}

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
}

/*
	Returns the longest block `a[i:i+k] == b[j:j+k]` within `box` that starts with a token that is not
	frequent. The block is grown back through any equal tokens before it. `k == 0` means there is none.
	`searched` is false when the region needs diffing another way: the work budget ran out first, or only
	frequent tokens match.
*/
@(require_results)
ratcliff_obershelp_longest_block :: proc(ro: ^Ratcliff_Obershelp, box: Box) -> (i, j, k: int, searched: bool) {
	a, b := ro.a, ro.b
	if ro.work_left < 0 {
		return
	}

	// Chain the occurrences of each token in this region of `b`, in order
	for y := box.b_hi - 1; y >= box.b_lo; y -= 1 {
		ro.next[y]     = ro.first[b[y]]
		ro.first[b[y]] = i32(y)
	}

	searched = true
	frequent_in_common := false
	ro.prev_len = 0
	for x in box.a_lo..<box.a_hi {
		cur_len := 0

		switch {
		case int(ro.b_count[a[x]]) > RO_FREQUENT:
			if ro.first[a[x]] != RO_NONE {
				frequent_in_common = true
			}

			// Carry on the runs that reached the token before, where `a[x]` matches next
			for p in ro.prev_at[:ro.prev_len] {
				y := int(p) + 1
				if y < box.b_hi && b[y] == a[x] {
					cur_len = ratcliff_obershelp_extend(ro, cur_len, x, y, &i, &j, &k)
				}
				ro.work_left -= 1
			}

		case:
			// Every occurrence starts a run, or carries on the one ending just before it
			for y := int(ro.first[a[x]]); y != RO_NONE; y = int(ro.next[y]) {
				cur_len = ratcliff_obershelp_extend(ro, cur_len, x, y, &i, &j, &k)
				ro.work_left -= 1
			}
		}

		// Clear the previous row through its list, then swap the rows
		for p in ro.prev_at[:ro.prev_len] {
			ro.prev[p + 1] = 0
		}
		ro.prev,    ro.cur    = ro.cur,    ro.prev
		ro.prev_at, ro.cur_at = ro.cur_at, ro.prev_at
		ro.prev_len = cur_len

		if ro.work_left < 0 {
			searched = false
			break
		}
	}

	// Leave the rows and chains empty for the next region
	for p in ro.prev_at[:ro.prev_len] {
		ro.prev[p + 1] = 0
	}
	ro.prev_len = 0
	for y in box.b_lo..<box.b_hi {
		ro.first[b[y]] = RO_NONE
	}

	if searched {
		switch {
		case k > 0:
			// Take in the equal tokens just before it, frequent ones included
			for i > box.a_lo && j > box.b_lo && a[i-1] == b[j-1] {
				i -= 1
				j -= 1
				k += 1
			}

		case frequent_in_common:
			// Only frequent tokens match. Myers diffs that better than calling it all changes
			searched = false
		}
	}
	return
}

// Records the run through `a[x]` and `b[y]` in the current row, and keeps it if it is the longest so far.
@(require_results)
ratcliff_obershelp_extend :: #force_inline proc "contextless" (ro: ^Ratcliff_Obershelp, cur_len, x, y: int, i, j, k: ^int) -> int {
	length := ro.prev[y] + 1
	ro.cur[y + 1]       = length
	ro.cur_at[cur_len]  = i32(y)
	if int(length) > k^ {
		i^ = x - int(length) + 1
		j^ = y - int(length) + 1
		k^ = int(length)
	}
	return cur_len + 1
}
