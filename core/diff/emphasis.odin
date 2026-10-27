package diff

import "core:io"
import "core:unicode"
import "core:unicode/utf8"

/*
	Emphasis highlights the changed part of changed lines. It works on blocks: the deleted lines of a change
	and the inserted lines after them. A block with only one side has nothing to compare.

	- `.Prefix_Suffix` pairs the lines of a block in order when both sides have as many. It highlights what
	  lies between their common prefix and suffix.
	- `.Words` diffs the words of the deleted text against those of the inserted text. It highlights the
	  changed words, even across lines.

	Parts sharing nothing but whitespace stay plain. Highlighting all of them would say nothing.
*/

// One `.Delete` edit and the `.Insert` edit straight after it, being written.
@(private)
Emphasis_Block :: struct {
	active:   bool,
	emphasis: Emphasis,
	del, ins: string, // the block's deleted and inserted lines, newlines included

	// Byte offset in `del` and `ins` of the next line to be written
	del_line, ins_line: int,

	// `.Prefix_Suffix`: byte offset of the next line's partner on the other side
	del_partner, ins_partner: int,

	// `.Words`: the word diff of `del` against `ins`, and the next word on each side
	words:              Changes,
	del_word, ins_word: Word_Cursor,
}

@(private)
Word_Cursor :: struct {
	pos:   int, // byte offset of the word
	index: int, // which word it is
}

// Returns the scratch bytes `write_unified`, `unified_size`, and `unified` need for `emphasis`. 0 unless it is `.Words`.
@(require_results)
emphasis_scratch_size :: proc(d: Text_Diff, emphasis: Emphasis, loc := #caller_location) -> int {
	if emphasis != .Words {
		return 0
	}
	assert(d.token == .Line, "emphasis needs a line diff", loc)

	largest := 0
	a_pos, b_pos := 0, 0
	del: string

	it := edit_iterator_make(d.changes)
	for e in edit_iterate(&it) {
		a_end := _skip_tokens(d.a, a_pos, e.a_hi - e.a_lo, .Line)
		b_end := _skip_tokens(d.b, b_pos, e.b_hi - e.b_lo, .Line)

		switch e.op {
		case .Equal:
			del = ""
		case .Delete:
			del = d.a[a_pos:a_end]
		case .Insert:
			if del != "" {
				n, m := token_count(del, .Word), token_count(d.b[b_pos:b_end], .Word)
				largest = max(largest, words_scratch_size(n, m))
			}
			del = ""
		}

		a_pos, b_pos = a_end, b_end
	}

	return largest
}

// The scratch the word diff of a block of `n` and `m` words needs, its `Changes` included.
@(private, require_results)
words_scratch_size :: proc "contextless" (n, m: int) -> int {
	return SCRATCH_ALIGN + scratch_bytes(u64, changes_size(n, m)) + scratch_size_text(n, m)
}

/*
	Sets up the block starting at `line`: the first line of the iterator's `.Delete` edit. Leaves it
	inactive when there is nothing to compare it with.
*/
@(private, require_results)
emphasis_block_make :: proc(it: ^Unified_Iterator, line: Unified_Line, emphasis: Emphasis, scratch: []byte, loc := #caller_location) -> (block: Emphasis_Block) {
	d   := it.d
	del := it.edit

	// The iterator has already moved past `line`
	line_len := len(line.text)
	if !it.no_newline {
		line_len += 1
	}
	del_start := it.a_pos - line_len
	del_end   := _skip_tokens(d.a, del_start, del.a_hi - del.a_lo, .Line)

	peek := it.edits
	ins, has_ins := edit_iterate(&peek)
	if !has_ins || ins.op != .Insert {
		return
	}
	ins_end := _skip_tokens(d.b, it.b_pos, ins.b_hi - ins.b_lo, .Line)

	block.emphasis = emphasis
	block.del      = d.a[del_start:del_end]
	block.ins      = d.b[it.b_pos:ins_end]

	switch emphasis {
	case .None:
		return

	case .Prefix_Suffix:
		block.active = del.a_hi - del.a_lo == ins.b_hi - ins.b_lo

	case .Words:
		n, m := token_count(block.del, .Word), token_count(block.ins, .Word)
		assert(len(scratch) >= words_scratch_size(n, m), ".Words emphasis needs `emphasis_scratch_size` bytes of scratch", loc)

		s := Scratch{buf = scratch}
		bits := scratch_take(&s, u64, changes_size(n, m), loc)
		block.words = changes_from_buffer(n, m, bits, loc)

		words := diff_text_buffer(block.del, block.ins, block.words, scratch[s.pos:], .Word, loc = loc)

		@(require_results)
		is_all_space :: proc(s: string) -> bool {
			for r in s {
				if !unicode.is_space(r) {
					return false
				}
			}
			return true
		}

		// Sharing only whitespace, such as the line breaks, is not having anything in common
		spans := span_iterator_make(words)
		for span in span_iterate(&spans) {
			if span.op == .Equal && !is_all_space(span.text) {
				block.active = true
				break
			}
		}
	}
	return
}

// Writes a deleted or inserted line of `block`, highlighting its changed part.
@(private)
write_emphasized :: proc(w: io.Writer, block: ^Emphasis_Block, kind: Unified_Kind, text: string, style: Style) -> io.Error {
	Pen :: struct {
		w:          io.Writer,
		base:       string,
		emph:       string,
		reset:      string,
		emphasized: bool,
		colored:    bool, // a colour is on: `reset` is due before the next one or at the end
	}

	pen_start :: proc(p: ^Pen) -> io.Error {
		if p.base != "" {
			io.write_string(p.w, p.base) or_return
			p.colored = true
		}
		return nil
	}

	pen_write :: proc(p: ^Pen, text: string, emphasized: bool) -> io.Error {
		if text == "" {
			return nil
		}

		switch {
		case emphasized && !p.emphasized:
			if p.emph != "" {
				io.write_string(p.w, p.emph) or_return
				p.colored = true
			}
		case !emphasized && p.emphasized:
			if p.colored {
				io.write_string(p.w, p.reset) or_return
				p.colored = false
			}
			pen_start(p) or_return
		}
		p.emphasized = emphasized

		_, err := io.write_string(p.w, text)
		return err
	}

	pen_end :: proc(p: ^Pen) -> io.Error {
		if p.colored {
			_, err := io.write_string(p.w, p.reset)
			return err
		}
		return nil
	}

	// The line at `s[pos]` without its "\n", and where the next line starts
	@(require_results)
	line_at :: proc(s: string, pos: int) -> (text: string, next: int) {
		next = _token_end(s, pos, .Line)
		text = s[pos:next]
		if len(text) > 0 && text[len(text)-1] == '\n' {
			text = text[:len(text)-1]
		}
		return
	}

	base, emph, prefix := style.delete, style.delete_emphasis, "-"
	if kind == .Insert {
		base, emph, prefix = style.insert, style.insert_emphasis, "+"
	}
	pen := Pen{w = w, base = base, emph = emph, reset = style.reset}
	pen_start(&pen) or_return
	io.write_string(w, prefix) or_return

	switch block.emphasis {
	case .None:
		io.write_string(w, text) or_return

	case .Prefix_Suffix:
		partner: string
		if kind == .Delete {
			partner, block.ins_partner = line_at(block.ins, block.ins_partner)
		} else {
			partner, block.del_partner = line_at(block.del, block.del_partner)
		}

		prefix_len, suffix_len := _common_affixes(text, partner)
		if prefix_len == 0 && suffix_len == 0 {
			io.write_string(w, text) or_return
		} else {
			pen_write(&pen, text[:prefix_len], false)                    or_return
			pen_write(&pen, text[prefix_len:len(text)-suffix_len], true) or_return
			pen_write(&pen, text[len(text)-suffix_len:], false)          or_return
		}

	case .Words:
		src, line_pos, cursor := block.del, block.del_line, &block.del_word
		if kind == .Insert {
			src, line_pos, cursor = block.ins, block.ins_line, &block.ins_word
		}
		line_end := line_pos + len(text)

		for cursor.pos < line_end {
			word_end := _token_end(src, cursor.pos, .Word)
			changed  := is_deleted(block.words, cursor.index)
			if kind == .Insert {
				changed = is_inserted(block.words, cursor.index)
			}

			// A word of whitespace can run on past the end of the line, into the next
			lo, hi := max(cursor.pos, line_pos), min(word_end, line_end)
			pen_write(&pen, src[lo:hi], changed) or_return
			if word_end > line_end {
				break
			}
			cursor.pos    = word_end
			cursor.index += 1
		}
	}

	if kind == .Delete {
		_, block.del_line = line_at(block.del, block.del_line)
	} else {
		_, block.ins_line = line_at(block.ins, block.ins_line)
	}
	pen_end(&pen) or_return
	return io.write_byte(w, '\n')
}


// Returns how many bytes `x` and `y` share at the start and at the end, on rune boundaries and without overlapping.
@(require_results)
_common_affixes :: proc(x, y: string) -> (prefix, suffix: int) {
	// Whether a rune starts at `s[i]`, counting the end of `s` as a start
	@(require_results)
	rune_starts :: #force_inline proc "contextless" (s: string, i: int) -> bool {
		return i >= len(s) || utf8.rune_start(s[i])
	}


	n := min(len(x), len(y))
	for prefix < n && x[prefix] == y[prefix] {
		prefix += 1
	}
	for prefix > 0 && !(rune_starts(x, prefix) && rune_starts(y, prefix)) {
		prefix -= 1
	}

	for suffix < n - prefix && x[len(x)-1-suffix] == y[len(y)-1-suffix] {
		suffix += 1
	}
	for suffix > 0 && !(rune_starts(x, len(x)-suffix) && rune_starts(y, len(y)-suffix)) {
		suffix -= 1
	}
	return
}
