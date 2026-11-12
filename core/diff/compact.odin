#+private
package diff

/*
	The `.Compact` post-pass. It slides each group of changes along equal tokens to where git puts it: beside a
	change on the other side if it can, otherwise as far down as it goes. With `.Indent_Heuristic` it picks a
	position by the indentation and blank lines around it instead. With `.Histogram` each group that moved or grew
	is diffed again against its partner.

	A group is a maximal run of changed tokens on one side, and may be empty. A side with `u` unchanged tokens has
	`u + 1` groups: one before each unchanged token, and one after the last. The `k`-th group of one side is the
	partner of the `k`-th group of the other. Both sit between the same pair of unchanged tokens.
*/

// The indent of a line of only whitespace.
LINE_INDENT_BLANK :: 255

// An indent is never measured past this.
LINE_INDENT_MAX :: 200

// A tab moves to the next multiple of this.
LINE_INDENT_TAB :: 8

// The indent heuristic tries a group at most this many positions above the bottom.
COMPACT_MAX_SLIDING :: 100

// The indent heuristic looks past at most this many blank lines.
COMPACT_MAX_BLANKS :: 20

// The weights of the indent heuristic. A lower score is a better place to split.
INDENT_START_OF_FILE       :: 1
INDENT_END_OF_FILE         :: 21
INDENT_BLANKS              :: -30 // for each blank line around the split
INDENT_BLANKS_AFTER        :: 6   // for each blank line after the split
INDENT_DEEPER              :: -4  // indented more than above
INDENT_DEEPER_BLANKS       :: 10
INDENT_BLOCK_START         :: 24  // indented less than above, but more below
INDENT_BLOCK_START_BLANKS  :: 17
INDENT_BLOCK_END           :: 23  // indented less than above
INDENT_BLOCK_END_BLANKS    :: 17
INDENT_EFFECTIVE_WEIGHT    :: 60  // for the sign of a difference in effective indent

// The options `rediff` diffs with, apart from `max_cost`.
REDIFF_OPTIONS :: Options{
	algorithm = .Myers,
	flags     = {.Prune},
}

// One side of a diff, for `.Compact`.
Compact_Side :: struct {
	ids:     []i32,
	offset:  int,  // where this side's bits start in `Changes.bits`
	indents: []u8, // one per token, for `.Indent_Heuristic`; nil otherwise
}

// The changed tokens `[start, end)` of one side.
Group :: struct {
	start, end: int,
}

// A group of one side and its partner, walked through both sides in step.
Compact_Walk :: struct {
	c:           Changes,
	this, other: Compact_Side,
	g, go:       Group,
}

// How good a place to split the indent heuristic finds. Lower is better.
Indent_Score :: struct {
	effective_indent: int,
	penalty:          int,
}


/*
	Measures the indent of `line`, its final "\n" included. A space adds 1, a tab moves to the next multiple of
	`LINE_INDENT_TAB`, and the other whitespace adds nothing. Returns at most `LINE_INDENT_MAX`, or
	`LINE_INDENT_BLANK` for a line of only whitespace.
*/
@(require_results)
line_indent :: proc "contextless" (line: string) -> u8 {
	indent := 0
	for i in 0..<len(line) {
		switch line[i] {
		case ' ':                    indent += 1
		case '\t':                   indent += LINE_INDENT_TAB - indent%LINE_INDENT_TAB
		case '\n', '\v', '\f', '\r': // adds nothing
		case:                        return u8(indent)
		}
		if indent >= LINE_INDENT_MAX {
			return LINE_INDENT_MAX
		}
	}
	return LINE_INDENT_BLANK
}

// Compacts `a`'s side against `b`, then `b`'s side against `a`.
compact :: proc(a, b: []i32, indents: []u8, id_count: int, changes: Changes, s: ^Scratch, opts: Options, loc := #caller_location) {
	a_side := Compact_Side{a, 0, nil}
	b_side := Compact_Side{b, _inserted_offset(changes), nil}
	if indents != nil {
		assert(len(indents) == len(a) + len(b), "an indent is needed for every line", loc)
		a_side.indents = indents[:len(a)]
		b_side.indents = indents[len(a):]
	}

	// Diffing merged groups again is git's for histogram only
	rediffing := opts.algorithm == .Histogram
	compact_side(changes, a_side, b_side, rediffing, id_count, opts.max_cost, s, loc)
	compact_side(changes, b_side, a_side, rediffing, id_count, opts.max_cost, s, loc)
}

// The scratch `rediff` takes for any groups within `n` by `m` tokens.
@(require_results)
rediff_scratch_size :: proc "contextless" (n, m: int, id_count: int) -> int {
	return scratch_bytes(u64, changes_size(n, m)) + prune_scratch_size(n, m, id_count, REDIFF_OPTIONS)
}

/*
	Diffs `this.ids[g.start:g.end]` against `other.ids[go.start:go.end]` again, with Myers after `.Prune`'s
	preparation. Every bit of both groups is then set or cleared: `this` takes the deletions, and `other` the
	insertions. Gives back its scratch.
*/
rediff :: proc(c: Changes, this, other: Compact_Side, g, go: Group, id_count: int, max_cost: int, s: ^Scratch, loc := #caller_location) {
	// Copies `count` bits from `src[src_lo:]` to `dst[dst_lo:]`
	copy_bits :: proc "contextless" (dst: []u64, dst_lo: int, src: []u64, src_lo: int, count: int) {
		for t in 0..<count {
			compact_put_bit(dst, dst_lo + t, bit_get(src, src_lo + t))
		}
	}


	start := s.pos
	n     := g.end - g.start
	m     := go.end - go.start
	words := scratch_take(s, u64, changes_size(n, m), loc)
	for &w in words {
		w = 0
	}
	sub := changes_from_buffer(n, m, words, loc)

	opts := REDIFF_OPTIONS
	opts.max_cost = max_cost
	prune(this.ids[g.start:g.end], other.ids[go.start:go.end], id_count, sub, s, opts, loc)

	copy_bits(c.bits, this.offset + g.start,   sub.bits, 0,                    n)
	copy_bits(c.bits, other.offset + go.start, sub.bits, _inserted_offset(sub), m)
	s.pos = start
}


/*
	Walks the groups of `this` in order, with each partner on `other` in step. Each non-empty group is settled,
	placed, and with `rediffing` diffed again if it moved or grew.
*/
compact_side :: proc(
	c:         Changes,
	this:      Compact_Side,
	other:     Compact_Side,
	rediffing: bool,
	id_count:  int,
	max_cost:  int,
	s:         ^Scratch,
	loc := #caller_location,
) {

	w := Compact_Walk{
		c     = c,
		this  = this,
		other = other,
		g     = compact_first_group(c, this),
		go    = compact_first_group(c, other),
	}
	for {
		if w.g.start < w.g.end {
			was := w.g

			// Settle: slide up and down as far as it goes, again while that merges it with another group
			earliest_end := 0
			matching_end := -1
			for {
				size := w.g.end - w.g.start
				matching_end = -1
				for compact_can_slide_up(&w) {
					compact_slide_up(&w)
				}
				earliest_end = w.g.end
				if w.go.start < w.go.end {
					matching_end = w.g.end
				}
				for compact_can_slide_down(&w) {
					compact_slide_down(&w)
					if w.go.start < w.go.end {
						matching_end = w.g.end
					}
				}
				if w.g.end - w.g.start == size {
					break
				}
			}

			// Place: the group is at the bottom
			switch {
			case w.g.end == earliest_end:
				// It cannot slide at all

			case matching_end >= 0:
				// Keep a replacement together, rather than a deletion apart from an insertion
				for w.go.start == w.go.end {
					compact_slide_up(&w)
				}

			case this.indents != nil:
				target := indent_best_end(this.indents, w.g, earliest_end)
				for w.g.end > target {
					compact_slide_up(&w)
				}
			}

			if rediffing && w.go.start < w.go.end && w.g != was {
				rediff(c, this, other, w.g, w.go, id_count, max_cost, s, loc)
			}
		}

		compact_next_group(c, this, &w.g) or_break
		partner_moved := compact_next_group(c, other, &w.go)
		assert(partner_moved, "changes have more unchanged tokens on one side", loc)
	}
	assert(w.go.end == len(other.ids), "changes have more unchanged tokens on one side", loc)
}

compact_put_bit :: #force_inline proc "contextless" (bits: []u64, i: int, set: bool) {
	mask := u64(1) << uint(i & 63)
	if set {
		bits[i >> 6] |= mask
	} else {
		bits[i >> 6] &~= mask
	}
}

// The group before the first unchanged token of `side`.
@(require_results)
compact_first_group :: proc "contextless" (c: Changes, side: Compact_Side) -> Group {
	return {0, _bit_run(c.bits, side.offset, side.offset + len(side.ids), true)}
}

// Moves `g` to the next group of `side`, just past the unchanged token that ends it. False at the last group.
@(require_results)
compact_next_group :: proc "contextless" (c: Changes, side: Compact_Side, g: ^Group) -> bool {
	n := len(side.ids)
	if g.end >= n {
		return false
	}
	g.start = g.end + 1
	g.end   = g.start + _bit_run(c.bits, side.offset + g.start, side.offset + n, true)
	return true
}

// Moves `g` to the previous group of `side`, just before the unchanged token that starts it. False at the first.
@(require_results)
compact_prev_group :: proc "contextless" (c: Changes, side: Compact_Side, g: ^Group) -> bool {
	if g.start <= 0 {
		return false
	}
	g.end   = g.start - 1
	g.start = compact_run_start(c, side, g.end)
	return true
}

// Where the run of changed tokens ending just before `end` starts.
@(require_results)
compact_run_start :: proc "contextless" (c: Changes, side: Compact_Side, end: int) -> (start: int) {
	start = end
	for start > 0 && bit_get(c.bits, side.offset + start - 1) {
		start -= 1
	}
	return
}

@(require_results)
compact_can_slide_down :: proc "contextless" (w: ^Compact_Walk) -> bool {
	ids := w.this.ids
	return w.g.start < w.g.end    &&
	       w.g.end < len(ids)     &&
	       ids[w.g.end] == ids[w.g.start]
}

@(require_results)
compact_can_slide_up :: proc "contextless" (w: ^Compact_Walk) -> bool {
	ids := w.this.ids
	return w.g.start < w.g.end    &&
	       w.g.start > 0          &&
	       ids[w.g.start-1] == ids[w.g.end-1]
}

// Slides the group down one token, taking in any group it then touches. The partner moves to the next group.
compact_slide_down :: proc "contextless" (w: ^Compact_Walk) {
	offset := w.this.offset
	n      := len(w.this.ids)
	compact_put_bit(w.c.bits, offset + w.g.start, false)
	compact_put_bit(w.c.bits, offset + w.g.end,   true)
	w.g.start += 1
	w.g.end   += 1
	w.g.end   += _bit_run(w.c.bits, offset + w.g.end, offset + n, true)

	moved := compact_next_group(w.c, w.other, &w.go)
	assert_contextless(moved, "changes have more unchanged tokens on one side")
}

// Slides the group up one token, taking in any group it then touches. The partner moves to the previous group.
compact_slide_up :: proc "contextless" (w: ^Compact_Walk) {
	offset := w.this.offset
	compact_put_bit(w.c.bits, offset + w.g.start - 1, true)
	compact_put_bit(w.c.bits, offset + w.g.end - 1,   false)
	w.g.end  -= 1
	w.g.start = compact_run_start(w.c, w.this, w.g.start)

	moved := compact_prev_group(w.c, w.other, &w.go)
	assert_contextless(moved, "changes have more unchanged tokens on one side")
}


/*
	The indent heuristic. Tries the group `g`, at the bottom, at each end from up to `COMPACT_MAX_SLIDING` above
	down to where it is, and returns the end that scores best. Ties go to the later, lower end.
*/
@(require_results)
indent_best_end :: proc "contextless" (indents: []u8, g: Group, earliest_end: int) -> (best_end: int) {
	size := g.end - g.start
	best := Indent_Score{}
	best_end = -1
	for end := max(earliest_end, g.end - size - 1, g.end - COMPACT_MAX_SLIDING); end <= g.end; end += 1 {
		score := Indent_Score{}
		indent_score_split(indents, end, &score)
		indent_score_split(indents, end - size, &score)
		if best_end < 0 || indent_compare(score, best) <= 0 {
			best     = score
			best_end = end
		}
	}
	return
}

// Negative when `x` is better than `y`, and zero when they are as good.
@(require_results)
indent_compare :: proc "contextless" (x, y: Indent_Score) -> int {
	sign := 0
	switch {
	case x.effective_indent > y.effective_indent: sign = 1
	case x.effective_indent < y.effective_indent: sign = -1
	}
	return INDENT_EFFECTIVE_WEIGHT*sign + (x.penalty - y.penalty)
}

/*
	Adds to `score` for a split just above line `s`, from the indents of the lines around it. A blank line has
	indent -1, and so does the line past the end.
*/
indent_score_split :: proc "contextless" (indents: []u8, s: int, score: ^Indent_Score) {
	@(require_results)
	indent_of :: #force_inline proc "contextless" (x: u8) -> int {
		if x == LINE_INDENT_BLANK {
			return -1
		}
		return int(x)
	}


	n := len(indents)

	// The line itself
	end_of_file := s >= n
	indent      := -1
	if !end_of_file {
		indent = indent_of(indents[s])
	}

	// The first line above that is not blank, looking past `COMPACT_MAX_BLANKS` blank lines at most
	pre_blank  := 0
	pre_indent := -1
	for i := s - 1; i >= 0; i -= 1 {
		if indents[i] != LINE_INDENT_BLANK {
			pre_indent = int(indents[i])
			break
		}
		pre_blank += 1
		if pre_blank == COMPACT_MAX_BLANKS {
			pre_indent = 0
			break
		}
	}

	// The same below, from the line after it
	post_blank  := 0
	post_indent := -1
	for i := s + 1; i < n; i += 1 {
		if indents[i] != LINE_INDENT_BLANK {
			post_indent = int(indents[i])
			break
		}
		post_blank += 1
		if post_blank == COMPACT_MAX_BLANKS {
			post_indent = 0
			break
		}
	}

	if pre_indent == -1 && pre_blank == 0 {
		score.penalty += INDENT_START_OF_FILE
	}
	if end_of_file {
		score.penalty += INDENT_END_OF_FILE
	}

	// The blank lines after the split, counting the line itself
	post := 0
	if indent == -1 {
		post = 1 + post_blank
	}
	total := pre_blank + post
	score.penalty += INDENT_BLANKS*total + INDENT_BLANKS_AFTER*post

	ind := indent
	if indent == -1 {
		ind = post_indent
	}
	score.effective_indent += ind

	blanks := total != 0
	switch {
	case ind == -1 || pre_indent == -1 || ind == pre_indent:
		// Nothing to say

	case ind > pre_indent:
		score.penalty += blanks ? INDENT_DEEPER_BLANKS : INDENT_DEEPER

	case post_indent != -1 && post_indent > ind:
		score.penalty += blanks ? INDENT_BLOCK_START_BLANKS : INDENT_BLOCK_START

	case:
		score.penalty += blanks ? INDENT_BLOCK_END_BLANKS : INDENT_BLOCK_END
	}
}
