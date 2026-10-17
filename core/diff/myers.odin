#+private
package diff

/*
	Myers' O(ND) diff in linear space: Eugene W. Myers, "An O(ND) Difference Algorithm and Its Variations"
	(Algorithmica, 1986), section 4b.

	Each box is trimmed of its equal ends, then split where a search forward from its top-left corner meets a
	search backward from its bottom-right corner. Both halves are diffed the same way. Positions are `(x, y)`,
	with `x` indexing `a` and `y` indexing `b`, on diagonal `k = x - y`.

	A box that is not `minimal` can give up on an exact split in two ways:
	- the long-snake heuristic: past `MYERS_HEURISTIC_COST` edits, at a long run of equal pairs that has come far
	- the cost cap: at `max_cost` edits, at the furthest either search has come

	The half the search has explored then becomes minimal, and the other half does not. An exact split makes
	both halves minimal.
*/

// The depth of the work stacks. Taking the smaller half of each split first keeps them within it.
MYERS_MAX_DEPTH :: 64

// The default cost cap is never lower than this.
MYERS_MIN_COST :: 256

// The long-snake heuristic only starts past this many edits.
MYERS_HEURISTIC_COST :: 256

// A snake is long past this many equal pairs. A split by the heuristic needs this many equal pairs beside it.
MYERS_SNAKE_LEN :: 20

// A split by the heuristic must have come further than this many times the edits.
MYERS_HEURISTIC_FACTOR :: 4

// What a search holds on a diagonal it has not reached yet.
MYERS_FORWARD_UNREACHED  :: -1
MYERS_BACKWARD_UNREACHED :: max(i32)

// `a[a_lo:a_hi]` against `b[b_lo:b_hi]`. A minimal box is always diffed exactly.
Box :: struct {
	a_lo, a_hi: int,
	b_lo, b_hi: int,
	minimal:    bool,
}

/*
	Diffs any box within `a` and `b`. For each diagonal, `fwd` holds the largest `x` the forward search has
	reached, and `bwd` the smallest `x` the backward search has reached. Both are indexed by the diagonal
	itself, from `-len(b)-1` to `len(a)+1`.
*/
Myers :: struct {
	a, b:     []i32,
	fwd, bwd: [^]i32,
}

@(require_results)
box_size :: proc "contextless" (box: Box) -> int {
	return (box.a_hi - box.a_lo) + (box.b_hi - box.b_lo)
}

// The scratch `myers_make` takes for inputs of length `n` and `m`.
@(require_results)
myers_scratch_size :: proc "contextless" (n, m: int) -> int {
	return 2*scratch_bytes(i32, n + m + 3)
}

// The cost cap for `n` by `m` tokens: `max_cost` when it is set, otherwise about the square root of the tokens.
@(require_results)
myers_cost :: proc "contextless" (max_cost, n, m: int) -> int {
	if max_cost > 0 {
		return max_cost
	}
	return max(rough_sqrt(n + m + 3), MYERS_MIN_COST)
}

// A power of two near the square root of `n`: one bit for every two bits of `n`. 1 for 0.
@(require_results)
rough_sqrt :: proc "contextless" (n: int) -> (r: int) {
	r = 1
	for rest := n; rest > 0; rest >>= 2 {
		r <<= 1
	}
	return
}

// Diffs `a` against `b` into zeroed `changes`. Gives back its scratch.
myers :: proc(a, b: []i32, changes: Changes, s: ^Scratch, minimal: bool, max_cost: int, loc := #caller_location) {
	start := s.pos
	md    := myers_make(a, b, s, loc)
	myers_box(&md, changes, {0, len(a), 0, len(b), minimal}, myers_cost(max_cost, len(a), len(b)), loc)
	s.pos = start
}

// Takes `myers_scratch_size(len(a), len(b))` bytes from `s`.
@(require_results)
myers_make :: proc(a, b: []i32, s: ^Scratch, loc := #caller_location) -> Myers {
	diagonals := len(a) + len(b) + 3
	fwd       := scratch_take(s, i32, diagonals, loc)
	bwd       := scratch_take(s, i32, diagonals, loc)

	// Diagonal 0 sits after the `len(b) + 1` diagonals below it
	zero := len(b) + 1
	return {
		a   = a,
		b   = b,
		fwd = raw_data(fwd)[zero:],
		bwd = raw_data(bwd)[zero:],
	}
}

// Diffs `box` into `changes`, marking bits only inside it. Boxes that are not minimal give up at `max_cost` edits.
myers_box :: proc(md: ^Myers, changes: Changes, box: Box, max_cost: int, loc := #caller_location) {
	a, b := md.a, md.b
	assert(0 <= box.a_lo && box.a_lo <= box.a_hi && box.a_hi <= len(a), "box outside the inputs", loc)
	assert(0 <= box.b_lo && box.b_lo <= box.b_hi && box.b_hi <= len(b), "box outside the inputs", loc)

	stack: [MYERS_MAX_DEPTH]Box
	depth := 0
	box   := box
	for {
		// Equal ends need nothing marked
		for box.a_lo < box.a_hi && box.b_lo < box.b_hi && a[box.a_lo] == b[box.b_lo] {
			box.a_lo += 1
			box.b_lo += 1
		}
		for box.a_lo < box.a_hi && box.b_lo < box.b_hi && a[box.a_hi-1] == b[box.b_hi-1] {
			box.a_hi -= 1
			box.b_hi -= 1
		}

		switch {
		case box.a_lo == box.a_hi:
			_mark_inserted(changes, box.b_lo, box.b_hi)

		case box.b_lo == box.b_hi:
			_mark_deleted(changes, box.a_lo, box.a_hi)

		case:
			lo, hi := myers_split(md, box, max_cost)
			assert(box.a_lo <= lo.a_hi && lo.a_hi <= box.a_hi, "Myers split outside its box", loc)
			assert(box.b_lo <= lo.b_hi && lo.b_hi <= box.b_hi, "Myers split outside its box", loc)

			// A half is only the whole box when it is handed on as minimal
			assert(box_size(lo) < box_size(box) || (lo.minimal && !box.minimal), "Myers split made no progress", loc)
			assert(box_size(hi) < box_size(box) || (hi.minimal && !box.minimal), "Myers split made no progress", loc)

			// The smaller half first, keeping the stack within `MYERS_MAX_DEPTH`
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

		if depth == 0 {
			break
		}
		depth -= 1
		box = stack[depth]
	}
}

/*
	Splits `box` in two where the forward and backward searches meet, or where a box that is not minimal gives
	up. Both sides are non-empty, and the first and last tokens differ.
*/
@(require_results)
myers_split :: proc(md: ^Myers, box: Box, max_cost: int) -> (lo, hi: Box) {
	@(require_results)
	split_at :: #force_inline proc "contextless" (box: Box, x, y: int, lo_minimal, hi_minimal: bool) -> (lo, hi: Box) {
		lo = {box.a_lo, x, box.b_lo, y, lo_minimal}
		hi = {x, box.a_hi, y, box.b_hi, hi_minimal}
		return
	}

	// Whether `MYERS_SNAKE_LEN` pairs from `a[x]` and `b[y]` on are equal
	@(require_results)
	equal_run :: proc "contextless" (a, b: []i32, x, y: int) -> bool {
		for t in 0..<MYERS_SNAKE_LEN {
			if a[x+t] != b[y+t] {
				return false
			}
		}
		return true
	}


	a, b       := md.a, md.b
	fwd, bwd   := md.fwd, md.bwd
	a_lo, a_hi := box.a_lo, box.a_hi
	b_lo, b_hi := box.b_lo, box.b_hi

	// The diagonals through the box, those of the two corners the searches start from, and which step checks
	// whether the searches meet
	diag_lo      := a_lo - b_hi
	diag_hi      := a_hi - b_lo
	fwd_start    := a_lo - b_lo
	bwd_start    := a_hi - b_hi
	meet_forward := (fwd_start - bwd_start) & 1 != 0

	fwd_lo, fwd_hi := fwd_start, fwd_start
	bwd_lo, bwd_hi := bwd_start, bwd_start
	fwd[fwd_start] = i32(a_lo)
	bwd[bwd_start] = i32(a_hi)

	for d := 1; /**/; d += 1 {
		long_snake := false

		// Forward: widen the range by a diagonal on each side, or narrow it at the box's sides
		if fwd_lo > diag_lo {
			fwd_lo -= 1
			fwd[fwd_lo-1] = MYERS_FORWARD_UNREACHED
		} else {
			fwd_lo += 1
		}
		if fwd_hi < diag_hi {
			fwd_hi += 1
			fwd[fwd_hi+1] = MYERS_FORWARD_UNREACHED
		} else {
			fwd_hi -= 1
		}

		for k := fwd_hi; k >= fwd_lo; k -= 2 {
			// From the diagonal below by a deletion, ties included, or from the one above by an insertion
			x: int
			if fwd[k-1] >= fwd[k+1] {
				x = int(fwd[k-1]) + 1
			} else {
				x = int(fwd[k+1])
			}
			y := x - k

			start := x
			for x < a_hi && y < b_hi && a[x] == b[y] {
				x += 1
				y += 1
			}
			if x - start > MYERS_SNAKE_LEN {
				long_snake = true
			}

			fwd[k] = i32(x)
			if meet_forward && bwd_lo <= k && k <= bwd_hi && int(bwd[k]) <= x {
				return split_at(box, x, y, true, true)
			}
		}

		// Backward: the same from the other corner
		if bwd_lo > diag_lo {
			bwd_lo -= 1
			bwd[bwd_lo-1] = MYERS_BACKWARD_UNREACHED
		} else {
			bwd_lo += 1
		}
		if bwd_hi < diag_hi {
			bwd_hi += 1
			bwd[bwd_hi+1] = MYERS_BACKWARD_UNREACHED
		} else {
			bwd_hi -= 1
		}

		for k := bwd_hi; k >= bwd_lo; k -= 2 {
			// From the diagonal below by an insertion, or from the one above by a deletion, ties included
			x: int
			if bwd[k-1] < bwd[k+1] {
				x = int(bwd[k-1])
			} else {
				x = int(bwd[k+1]) - 1
			}
			y := x - k

			end := x
			for x > a_lo && y > b_lo && a[x-1] == b[y-1] {
				x -= 1
				y -= 1
			}
			if end - x > MYERS_SNAKE_LEN {
				long_snake = true
			}

			bwd[k] = i32(x)
			if !meet_forward && fwd_lo <= k && k <= fwd_hi && x <= int(fwd[k]) {
				return split_at(box, x, y, true, true)
			}
		}

		if box.minimal {
			continue
		}

		// The long-snake heuristic: split after a long snake that has come far, forward first
		if long_snake && d > MYERS_HEURISTIC_COST {
			best   := 0
			best_x := 0
			best_y := 0
			for k := fwd_hi; k >= fwd_lo; k -= 2 {
				x := int(fwd[k])
				y := x - k
				v := (x - a_lo) + (y - b_lo) - abs(k - fwd_start)
				if v > MYERS_HEURISTIC_FACTOR*d &&
				   v > best                     &&
				   a_lo + MYERS_SNAKE_LEN <= x  &&
				   x < a_hi                     &&
				   b_lo + MYERS_SNAKE_LEN <= y  &&
				   y < b_hi                     &&
				   equal_run(a, b, x - MYERS_SNAKE_LEN, y - MYERS_SNAKE_LEN) {
					best   = v
					best_x = x
					best_y = y
				}
			}
			if best > 0 {
				return split_at(box, best_x, best_y, true, false)
			}

			for k := bwd_hi; k >= bwd_lo; k -= 2 {
				x := int(bwd[k])
				y := x - k
				v := (a_hi - x) + (b_hi - y) - abs(k - bwd_start)
				if v > MYERS_HEURISTIC_FACTOR*d &&
				   v > best                     &&
				   a_lo < x                     &&
				   x <= a_hi - MYERS_SNAKE_LEN  &&
				   b_lo < y                     &&
				   y <= b_hi - MYERS_SNAKE_LEN  &&
				   equal_run(a, b, x, y) {
					best   = v
					best_x = x
					best_y = y
				}
			}
			if best > 0 {
				return split_at(box, best_x, best_y, false, true)
			}
		}

		// The cost cap: split where the search that has come further got to
		if d >= max_cost {
			fwd_sum := -1
			fwd_x   := 0
			fwd_y   := 0
			for k := fwd_hi; k >= fwd_lo; k -= 2 {
				x := min(int(fwd[k]), a_hi)
				y := x - k
				if y > b_hi {
					x = b_hi + k
					y = b_hi
				}
				if x + y > fwd_sum {
					fwd_sum = x + y
					fwd_x   = x
					fwd_y   = y
				}
			}

			bwd_sum := max(int)
			bwd_x   := 0
			bwd_y   := 0
			for k := bwd_hi; k >= bwd_lo; k -= 2 {
				x := max(int(bwd[k]), a_lo)
				y := x - k
				if y < b_lo {
					x = b_lo + k
					y = b_lo
				}
				if x + y < bwd_sum {
					bwd_sum = x + y
					bwd_x   = x
					bwd_y   = y
				}
			}

			if (a_hi + b_hi) - bwd_sum < fwd_sum - (a_lo + b_lo) {
				return split_at(box, fwd_x, fwd_y, true, false)
			}
			return split_at(box, bwd_x, bwd_y, false, true)
		}
	}
}
