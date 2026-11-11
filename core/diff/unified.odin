package diff

import "base:runtime"
import "core:io"
import "core:strings"
import "core:terminal/ansi"

Unified_Kind :: enum u8 {
	Hunk_Header, // "@@ -a,b +c,d @@"; the ranges are in `Unified_Line.hunk`
	Equal,       // " line"
	Delete,      // "-line"
	Insert,      // "+line"
	No_Newline,  // "\ No newline at end of file", after the line it applies to
}

Unified_Line :: struct {
	kind:           Unified_Kind,
	text:           string, // the line without its prefix or newline; empty for `.Hunk_Header` and `.No_Newline`
	hunk:           Hunk,   // only set for `.Hunk_Header`
	a_line, b_line: int,    // 1-based line numbers; 0 when the line is not on that side
}

Unified_Iterator :: struct {
	d:                Text_Diff,
	hunks:            Hunk_Iterator,
	edits:            Edit_Iterator,
	edit:             Edit, // the edit whose lines are being given
	a_index, b_index: int,  // the next line on each side
	a_pos, b_pos:     int,  // byte offset of that line
	in_hunk:          bool,
	no_newline:       bool, // a `.No_Newline` line is due
}

// Escape sequences written before each kind of output, and `reset` after it. All empty means no colour.
Style :: struct {
	file_header:     string,
	hunk_header:     string,
	equal:           string,
	delete:          string,
	insert:          string,
	delete_emphasis: string, // the changed part within a deleted line
	insert_emphasis: string, // the changed part within an inserted line
	reset:           string,
}

STYLE_NONE :: Style{}

// Colours similar to git's defaults.
STYLE_ANSI :: Style{
	file_header     = ansi.CSI + ansi.BOLD     + ansi.SGR,
	hunk_header     = ansi.CSI + ansi.FG_CYAN  + ansi.SGR,
	delete          = ansi.CSI + ansi.FG_RED   + ansi.SGR,
	insert          = ansi.CSI + ansi.FG_GREEN + ansi.SGR,
	delete_emphasis = ansi.CSI + ansi.FG_RED   + ";" + ansi.INVERT + ansi.SGR,
	insert_emphasis = ansi.CSI + ansi.FG_GREEN + ";" + ansi.INVERT + ansi.SGR,
	reset           = ansi.CSI + ansi.RESET    + ansi.SGR,
}

// How the changed part within a changed line is highlighted.
Emphasis :: enum u8 {
	None,
	Prefix_Suffix, // trim the common prefix and suffix of paired deleted and inserted lines; needs no scratch
	Words,         // word diff of each block of deleted and inserted lines; needs `emphasis_scratch_size` bytes of scratch
}

/*
	How `unified` and `write_unified_to_builder` make room for the output.

	- `.Exact` writes the diff twice: once to count its bytes, then into one allocation of exactly that size.
	  Nothing is resized. Suits any allocator, including fixed buffers and bump arenas.
	- `.Grow` writes the diff once into growing memory, then shrinks it to fit. Close to twice as fast.
	  Suits the heap and allocators that resize their last allocation in place: `core:mem`'s `Arena`, `Stack`,
	  and `Small_Stack`, and `core:mem/virtual`'s `Arena` while its current block has room. With nothing else
	  allocated from them meanwhile, these end up holding exactly the output. Inside a temporary region of
	  either `Arena`, the shrink cannot give memory back: up to as much again stays in use until the region
	  ends. A `Dynamic_Arena` copies an allocation larger than its out-of-band size to grow it, and keeps every
	  copy until it is reset. Use `.Exact` with it.
*/
Sizing :: enum u8 {
	Exact,
	Grow,
}


// Makes an iterator over the lines of unified output, without the "---" and "+++" file headers. `d` must be a line diff.
@(require_results)
unified_iterator_make :: proc(d: Text_Diff, context_len := DEFAULT_CONTEXT_LEN, loc := #caller_location) -> Unified_Iterator {
	assert(d.token == .Line, "unified output needs a line diff", loc)
	return {d = d, hunks = hunk_iterator_make(d.changes, context_len)}
}

/*
	Iterates over the lines of unified output in order. Never allocates.

	Usage:
		it := diff.unified_iterator_make(d)
		for line in diff.unified_iterate(&it) {
			switch line.kind {
			case .Hunk_Header: ...
			case .Equal:       ...
			case .Delete:      ...
			case .Insert:      ...
			case .No_Newline:  ...
			}
		}
*/
@(require_results)
unified_iterate :: proc(it: ^Unified_Iterator) -> (line: Unified_Line, ok: bool) {
	@(require_results)
	next_line :: proc(s: string, pos, index: ^int) -> (text: string, no_newline: bool) {
		start := pos^
		pos^ = _token_end(s, start, .Line)
		index^ += 1
		text = s[start:pos^]
		if len(text) > 0 && text[len(text) - 1] == '\n' {
			return text[:len(text) - 1], false
		}
		return text, true
	}


	if it.no_newline {
		it.no_newline = false
		return {kind = .No_Newline}, true
	}

	d := it.d
	for {
		if !it.in_hunk {
			h := hunk_iterate(&it.hunks) or_return
			it.a_pos   = _skip_tokens(d.a, it.a_pos, h.a_lo - it.a_index, .Line)
			it.b_pos   = _skip_tokens(d.b, it.b_pos, h.b_lo - it.b_index, .Line)
			it.a_index = h.a_lo
			it.b_index = h.b_lo
			it.edits   = edit_iterator_make_hunk(d.changes, h)
			it.edit    = {}
			it.in_hunk = true
			return {kind = .Hunk_Header, hunk = h}, true
		}

		e := it.edit
		switch e.op {
		case .Equal:
			if it.a_index < e.a_hi {
				line = {
					kind   = .Equal,
					a_line = it.a_index + 1,
					b_line = it.b_index + 1,
				}
				line.text, it.no_newline = next_line(d.a, &it.a_pos, &it.a_index)
				_, _ = next_line(d.b, &it.b_pos, &it.b_index)
				return line, true
			}
		case .Delete:
			if it.a_index < e.a_hi {
				line = {
					kind   = .Delete,
					a_line = it.a_index + 1,
				}
				line.text, it.no_newline = next_line(d.a, &it.a_pos, &it.a_index)
				return line, true
			}
		case .Insert:
			if it.b_index < e.b_hi {
				line = {
					kind   = .Insert,
					b_line = it.b_index + 1,
				}
				line.text, it.no_newline = next_line(d.b, &it.b_pos, &it.b_index)
				return line, true
			}
		}

		// This edit is used up: move on to the next, or out of the hunk
		next, has_next := edit_iterate(&it.edits)
		if !has_next {
			it.in_hunk = false
			continue
		}
		it.edit = next
	}
}

// Writes `d` as a unified diff, file headers included. Writes nothing without changes. `d` must be a line diff. Never allocates.
write_unified :: proc(
	w: io.Writer,
	d: Text_Diff,
	a_name      := "a",
	b_name      := "b",
	context_len := DEFAULT_CONTEXT_LEN,
	style       := STYLE_NONE,
	emphasis    := Emphasis.None,
	scratch:       []byte = nil,
	loc         := #caller_location,
) -> io.Error {
	write_styled :: proc(w: io.Writer, color, reset, prefix, text: string) -> io.Error {
		if color != "" {
			io.write_string(w, color) or_return
		}
		io.write_string(w, prefix) or_return
		io.write_string(w, text)   or_return
		if color != "" {
			io.write_string(w, reset) or_return
		}
		return io.write_byte(w, '\n')
	}

	// GNU diff style ranges
	write_range :: proc(w: io.Writer, lo, hi: int) -> io.Error {
		count := hi - lo
		io.write_int(w, count == 0 ? lo : lo + 1) or_return
		if count != 1 {
			io.write_byte(w, ',')  or_return
			io.write_int(w, count) or_return
		}
		return nil
	}

	// Without an emphasis colour there is nothing to show
	emphasis := emphasis
	if style.delete_emphasis == "" && style.insert_emphasis == "" {
		emphasis = .None
	}

	it := unified_iterator_make(d, context_len, loc)
	block: Emphasis_Block
	headers_written := false
	for line in unified_iterate(&it) {
		if !headers_written {
			write_styled(w, style.file_header, style.reset, "--- ", a_name) or_return
			write_styled(w, style.file_header, style.reset, "+++ ", b_name) or_return
			headers_written = true
		}

		switch line.kind {
		case .Hunk_Header:
			block = {}
			if style.hunk_header != "" {
				io.write_string(w, style.hunk_header) or_return
			}
			io.write_string(w, "@@ -")                     or_return
			write_range(w, line.hunk.a_lo, line.hunk.a_hi) or_return
			io.write_string(w, " +")                       or_return
			write_range(w, line.hunk.b_lo, line.hunk.b_hi) or_return
			io.write_string(w, " @@")                      or_return
			if style.hunk_header != "" {
				io.write_string(w, style.reset) or_return
			}
			io.write_byte(w, '\n') or_return
		case .Equal:
			block = {}
			write_styled(w, style.equal, style.reset, " ", line.text) or_return
		case .Delete:
			if emphasis != .None && line.a_line - 1 == it.edit.a_lo {
				block = emphasis_block_make(&it, line, emphasis, scratch, loc)
			}
			if block.active {
				write_emphasized(w, &block, .Delete, line.text, style) or_return
			} else {
				write_styled(w, style.delete, style.reset, "-", line.text) or_return
			}
		case .Insert:
			if block.active {
				write_emphasized(w, &block, .Insert, line.text, style) or_return
			} else {
				write_styled(w, style.insert, style.reset, "+", line.text) or_return
			}
		case .No_Newline:
			io.write_string(w, "\\ No newline at end of file\n") or_return
		}
	}
	return nil
}

/*
	Appends `d` to `sb` as a unified diff, file headers included. `d` must be a line diff.

	`.Exact` grows `sb` once, by exactly `unified_size` bytes. `.Grow` grows it while writing.
	If `sb` cannot grow enough, nothing is appended.
*/
write_unified_to_builder :: proc(
	sb: ^strings.Builder,
	d:  Text_Diff,
	a_name      := "a",
	b_name      := "b",
	context_len := DEFAULT_CONTEXT_LEN,
	style       := STYLE_NONE,
	emphasis    := Emphasis.None,
	scratch:       []byte = nil,
	sizing      := Sizing.Exact,
	loc         := #caller_location,
) -> runtime.Allocator_Error {
	switch sizing {
	case .Exact:
		size := unified_size(d, a_name, b_name, context_len, style, emphasis, scratch, loc)
		reserve(&sb.buf, len(sb.buf) + size, loc) or_return
		err := write_unified(strings.to_writer(sb), d, a_name, b_name, context_len, style, emphasis, scratch, loc)
		assert(err == nil, "unified output outgrew its own size", loc)

	case .Grow:
		// A builder only fails to take a write when it cannot grow
		start := len(sb.buf)
		if write_unified(strings.to_writer(sb), d, a_name, b_name, context_len, style, emphasis, scratch, loc) != nil {
			resize(&sb.buf, start, loc)
			return .Out_Of_Memory
		}
	}
	return nil
}

// Returns the exact number of bytes `write_unified` would write.
@(require_results)
unified_size :: proc(
	d: Text_Diff,
	a_name      := "a",
	b_name      := "b",
	context_len := DEFAULT_CONTEXT_LEN,
	style       := STYLE_NONE,
	emphasis    := Emphasis.None,
	scratch:       []byte = nil,
	loc         := #caller_location,
) -> int {
	// With no stream to pass them on to, the writes are only counted
	counter: io.Counting_Stream
	_ = write_unified(io.counting_stream_init(&counter, {}), d, a_name, b_name, context_len, style, emphasis, scratch, loc)
	return int(counter.bytes_written)
}

/*
	Returns `d` as a unified diff, allocated from `allocator`. Free it with the same allocator.

	`.Exact` makes one allocation of exactly `unified_size` bytes. `.Grow` grows the memory while writing,
	then shrinks it to fit. On failure, nothing stays allocated.
*/
@(require_results)
unified :: proc(
	d:         Text_Diff,
	allocator: runtime.Allocator,
	a_name      := "a",
	b_name      := "b",
	context_len := DEFAULT_CONTEXT_LEN,
	style       := STYLE_NONE,
	emphasis    := Emphasis.None,
	scratch:       []byte = nil,
	sizing      := Sizing.Exact,
	loc         := #caller_location,
) -> (s: string, err: runtime.Allocator_Error) {
	switch sizing {
	case .Exact:
		size := unified_size(d, a_name, b_name, context_len, style, emphasis, scratch, loc)
		buf  := make([]byte, size, allocator, loc) or_return
		sb   := strings.builder_from_bytes(buf)
		write_err := write_unified(strings.to_writer(&sb), d, a_name, b_name, context_len, style, emphasis, scratch, loc)
		assert(write_err == nil, "unified output outgrew its own size", loc)
		assert(len(sb.buf) == size, "unified output outgrew its own size", loc)
		return string(buf), nil

	case .Grow:
		sb := strings.builder_make(allocator, loc) or_return
		err = write_unified_to_builder(&sb, d, a_name, b_name, context_len, style, emphasis, scratch, .Grow, loc)
		if err == nil {
			// Fitted, the memory is exactly what is freed with the string
			_, err = shrink(&sb.buf, loc = loc)
		}
		if err != nil {
			strings.builder_destroy(&sb)
			return "", err
		}
		return strings.to_string(sb), nil
	}
	return
}
