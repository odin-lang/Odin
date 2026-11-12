/*
Text edit primitives to use in a text box.

Based off the articles by rxi:
- [[ https://rxi.github.io/textbox_behaviour.html ]]
- [[ https://rxi.github.io/a_simple_undo_system.html ]]
*/
package text_edit

import "base:runtime"
import "core:time"
import "core:hash"
import "core:mem"
import "core:strings"
import "core:unicode"
import "core:unicode/utf8"

DEFAULT_UNDO_TIMEOUT :: 300 * time.Millisecond

State :: struct {
	selection: [2]int,
	line_start, line_end: int,

	// initialized each "frame" with `begin`
	builder: ^strings.Builder, // let the caller store the text buffer data

	up_index, down_index:           int, // multi-lines
	page_up_index, page_down_index: int, // multi-lines

	// set by up, down, and page moves: while set, keep aiming them at the same column (multi-lines)
	// - edits and other moves clear it; clear it yourself on a click
	moved_vertically: bool,

	translate_by_grapheme: bool, // translates by codepoint by default

	// classifies runes for word moves and selection.
	// nil: only spaces, tabs, and newlines separate words
	word_class: proc(r: rune) -> Word_Class,

	options: Option_Set, // opt-in behaviours

	// undo
	undo: [dynamic]^Undo_State,
	redo: [dynamic]^Undo_State,
	undo_text_allocator: runtime.Allocator,
	undo_breaks: Undo_Break_Set, // what starts a new undo step, besides a pause of `undo_timeout`

	id: u64, // useful for immediate mode GUIs

	// Timeout information
	current_time:   time.Tick,
	last_edit_time: time.Tick,
	undo_timeout:   time.Duration,

	// Set these if you want cut/copy/paste functionality
	set_clipboard: proc(user_data: rawptr, text: string) -> (ok: bool),
	get_clipboard: proc(user_data: rawptr) -> (text: string, ok: bool),
	clipboard_user_data: rawptr,

	// owned by the package
	_last_edit:           Edit_Kind,
	_last_caret:          int,
	_edit_depth:          int,
	_undo_groups:         int,
	_undo_break:          bool,
	_clipboard_line_hash: u64,
}

Undo_State :: struct {
	selection: [2]int,
	len:       int,
	text:      [0]byte, // string(us.text[:us.len]) --- requiring #no_bounds_check
}

Translation :: enum u32 {
	Start,
	End,
	Left,
	Right,
	Up,
	Down,
	Page_Up,
	Page_Down,
	Word_Left,
	Word_Right,
	Word_Start,
	Word_End,
	Soft_Line_Start,
	Soft_Line_End,
	Hard_Line_Start,
	Hard_Line_End,
	Smart_Line_Start,
	Smart_Line_End,
}

Translation_Set :: distinct bit_set[Translation; u32]

VERTICAL_TRANSLATIONS :: Translation_Set{.Up, .Down, .Page_Up, .Page_Down}

// a rune's class for word moves: a word is a run of one class, and word moves skip `Space`
Word_Class :: enum u32 {
	Space,
	Punctuation,
	Word,
}

// opt-in behaviours, for `State.options`
Option :: enum u32 {
	Keep_Indent,    // `New_Line` copies the hard line's leading spaces and tabs, up to the caret
	Line_Clipboard, // with nothing selected, `Copy` and `Cut` take the caret's hard line; `Paste` puts such a line above the caret's
}

Option_Set :: distinct bit_set[Option; u32]

// what starts a new undo step, besides a pause of `State.undo_timeout`
Undo_Break :: enum u32 {
	Kind,       // switching between typing, deleting, pasting, and cutting; every paste and cut is its own step
	Word,       // typing the first rune of a word, by `State.word_class`
	Caret_Move, // editing away from where the last edit left the caret
	Every_Edit,
}

Undo_Break_Set :: distinct bit_set[Undo_Break; u32]

@(private)
Edit_Kind :: enum u32 {
	None,
	Insert,
	Remove,
	Paste,
	Cut,
}

// init the state to some timeout and set the respective allocators
// - undo_state_allocator dictates the dynamic undo|redo arrays allocators
// - undo_text_allocator is the allocator which allocates strings only
init :: proc(s: ^State, undo_text_allocator, undo_state_allocator: runtime.Allocator, undo_timeout := DEFAULT_UNDO_TIMEOUT) {
	s.undo_timeout = undo_timeout

	// Used for allocating `Undo_State`
	s.undo_text_allocator = undo_text_allocator

	s.undo.allocator = undo_state_allocator
	s.redo.allocator = undo_state_allocator
}

// clear undo|redo strings and delete their stacks
destroy :: proc(s: ^State) {
	undo_clear(s, &s.undo)
	undo_clear(s, &s.redo)
	delete(s.undo)
	delete(s.redo)
	s.builder = nil
}

// Call at the beginning of each frame
begin :: proc(s: ^State, id: u64, builder: ^strings.Builder) {
	assert(builder != nil)
	if s.id != 0 {
		end(s)
	}
	s.id = id
	s.selection = {len(builder.buf), 0}
	s.moved_vertically = false
	s.builder = builder
	update_time(s)
	undo_clear(s, &s.undo)
	undo_clear(s, &s.redo)
}

// Call at the end of each frame
end :: proc(s: ^State) {
	s.id = 0
	s.builder = nil
}

// update current time so "insert" can check for timeouts
update_time :: proc(s: ^State) {
	s.current_time = time.tick_now()
	if s.undo_timeout <= 0 {
		s.undo_timeout = DEFAULT_UNDO_TIMEOUT
	}
}

// setup the builder, selection and undo|redo state once allowing to retain selection
setup_once :: proc(s: ^State, builder: ^strings.Builder) {
	s.builder = builder
	s.selection = { len(builder.buf), 0 }
	s.moved_vertically = false
	undo_clear(s, &s.undo)
	undo_clear(s, &s.redo)
}

// returns true when the builder had content to be cleared
// clear builder&selection and the undo|redo stacks
clear_all :: proc(s: ^State) -> (cleared: bool) {
	if s.builder != nil && len(s.builder.buf) > 0 {
		clear(&s.builder.buf)
		s.selection = {}
		s.moved_vertically = false
		cleared = true
	}

	undo_clear(s, &s.undo)
	undo_clear(s, &s.redo)
	return
}

// push current text state to the wanted undo|redo stack
undo_state_push :: proc(s: ^State, undo: ^[dynamic]^Undo_State) -> mem.Allocator_Error {
	if s.builder == nil {
		return nil
	}
	text := string(s.builder.buf[:])
	item := (^Undo_State)(mem.alloc(size_of(Undo_State) + len(text), align_of(Undo_State), s.undo_text_allocator) or_return)
	item.selection = s.selection
	item.len = len(text)
	#no_bounds_check {
		runtime.copy(item.text[:len(text)], text)
	}
	append(undo, item) or_return
	return nil
}

// pop undo|redo state - push to redo|undo - set selection & text
undo :: proc(s: ^State, undo, redo: ^[dynamic]^Undo_State) {
	if len(undo) > 0 {
		undo_state_push(s, redo)
		item := pop(undo)
		s.selection = item.selection
		s.moved_vertically = false
		s._undo_break = true
		#no_bounds_check if s.builder != nil {
			strings.builder_reset(s.builder)
			strings.write_string(s.builder, string(item.text[:item.len]))
		}
		free(item, s.undo_text_allocator)
	}
}

// iteratively clearn the undo|redo stack and free each allocated text state
undo_clear :: proc(s: ^State, undo: ^[dynamic]^Undo_State) {
	for len(undo) > 0 {
		item := pop(undo)
		free(item, s.undo_text_allocator)
	}
}

// clear redo stack and check if the undo timeout gets hit
undo_check :: proc(s: ^State) {
	undo_clear(s, &s.redo)
	if time.tick_diff(s.last_edit_time, s.current_time) > s.undo_timeout {
		undo_state_push(s, &s.undo)
	}
	s.last_edit_time = s.current_time
}

// Starts a group of edits that undo as one step until the matching `undo_group_end`
undo_group_begin :: proc(s: ^State) {
	if s._undo_groups == 0 {
		s._undo_break = true
	}
	s._undo_groups += 1
}

// Ends a group of edits started by `undo_group_begin`
undo_group_end :: proc(s: ^State) {
	assert(s._undo_groups > 0, "undo_group_end without undo_group_begin")
	s._undo_groups -= 1
	if s._undo_groups == 0 {
		s._undo_break = true
	}
}

@(private)
undo_step :: proc(s: ^State, kind: Edit_Kind, at: int, first: rune) {
	@(require_results)
	starts_word :: proc(s: ^State, at: int, first: rune) -> bool {
		if word_class_of(s, first) == .Space {
			return false
		}
		before, _ := word_class_before(s, at)
		return before == .Space
	}

	@(require_results)
	starts_step :: proc(s: ^State, kind: Edit_Kind, at: int, first: rune) -> bool {
		if s._undo_break {
			return true
		}

		if time.tick_diff(s.last_edit_time, s.current_time) > s.undo_timeout {
			return true
		}

		if .Every_Edit in s.undo_breaks {
			return true
		}

		if .Kind in s.undo_breaks {
			if kind != s._last_edit {
				return true
			}
			// every paste and cut is a step of its own
			if kind == .Cut || kind == .Paste {
				return true
			}
		}

		if .Caret_Move in s.undo_breaks {
			caret_moved := s.selection != [2]int{s._last_caret, s._last_caret}
			if caret_moved {
				return true
			}
		}

		if .Word in s.undo_breaks && kind == .Insert {
			if starts_word(s, at, first) {
				return true
			}
		}

		return false
	}

	undo_clear(s, &s.redo)
	defer s.last_edit_time = s.current_time

	// The rest of a compound edit joins the step its first edit decided on
	if s._edit_depth > 0 {
		return
	}

	// After its first edit, the rest of an undo group joins its step
	if s._undo_groups > 0 && !s._undo_break {
		return
	}

	if starts_step(s, kind, at, first) {
		undo_state_push(s, &s.undo)
	}
	s._undo_break = false
	s._last_edit  = kind
}

// A compound edit, such as typing over a selection, is one undo step
@(private)
edit_begin :: proc(s: ^State, kind: Edit_Kind, first: rune) {
	lo, _ := sorted_selection(s)
	undo_step(s, kind, lo, first)
	s._edit_depth += 1
}

@(private)
edit_end :: proc(s: ^State) {
	s._edit_depth -= 1
	s._last_caret  = s.selection[0]
}

// insert text into the edit state - deletes the current selection
input_text :: proc(s: ^State, text: string) -> int {
	if len(text) == 0 {
		return 0
	}

	first, _ := utf8.decode_rune(text)
	edit_begin(s, .Insert, first)
	defer edit_end(s)

	if has_selection(s) {
		selection_delete(s)
	}
	n := insert(s, s.selection[0], text)
	offset := s.selection[0] + n
	s.selection = {offset, offset}
	return n
}

// insert slice of runes into the edit state - deletes the current selection
input_runes :: proc(s: ^State, text: []rune) {
	if len(text) == 0 {
		return
	}

	edit_begin(s, .Insert, text[0])
	defer edit_end(s)

	if has_selection(s) {
		selection_delete(s)
	}
	offset := s.selection[0]
	for r in text {
		b, w := utf8.encode_rune(r)
		n := insert(s, offset, string(b[:w]))
		offset += n
		if n != w {
			break
		}
	}
	s.selection = {offset, offset}
}

// insert a single rune into the edit state - deletes the current selection
input_rune :: proc(s: ^State, r: rune) {
	edit_begin(s, .Insert, r)
	defer edit_end(s)

	if has_selection(s) {
		selection_delete(s)
	}
	offset := s.selection[0]
	b, w := utf8.encode_rune(r)
	n := insert(s, offset, string(b[:w]))
	offset += n
	s.selection = {offset, offset}
}

// Inserts a line break, followed by the hard line's indentation with `.Keep_Indent`
new_line :: proc(s: ^State) {
	if .Keep_Indent not_in s.options || s.builder == nil {
		input_text(s, "\n")
		return
	}

	edit_begin(s, .Insert, '\n')
	defer edit_end(s)

	if has_selection(s) {
		selection_delete(s)
	}

	// The indentation is the hard line's leading spaces and tabs, up to the caret
	caret, _     := sorted_selection(s)
	indent_start := translate_position(s, .Hard_Line_Start)
	indent_end   := indent_start
	for indent_end < caret && is_blank(s.builder.buf[indent_end]) {
		indent_end += 1
	}

	at := caret + insert(s, caret, "\n")

	// Copy the indentation through a small buffer: the builder's own bytes move when it grows
	for i := indent_start; i < indent_end; /**/ {
		chunk: [64]byte
		n := runtime.copy(chunk[:], s.builder.buf[i:indent_end])

		inserted := insert(s, at, string(chunk[:n]))
		at += inserted
		if inserted < n {
			break // the builder is full
		}

		i += n
	}

	s.selection = {at, at}
}

// insert a single rune into the edit state - deletes the current selection
insert :: proc(s: ^State, at: int, text: string) -> int {
	first, _ := utf8.decode_rune(text)
	undo_step(s, .Insert, at, first)
	s.moved_vertically = false
	if s.builder != nil {
		if ok, _ := inject_at(&s.builder.buf, at, text); !ok {
			n := cap(s.builder.buf) - len(s.builder.buf)
			assert(n < len(text))
			for is_continuation_byte(text[n]) {
				n -= 1
			}
			if ok2, _ := inject_at(&s.builder.buf, at, text[:n]); !ok2 {
				n = 0
			}
			return n
		}
		return len(text)
	}
	return 0
}

// remove the wanted range withing, usually the selection within byte indices
remove :: proc(s: ^State, lo, hi: int) {
	undo_step(s, .Remove, lo, 0)
	s.moved_vertically = false
	if s.builder != nil {
		remove_range(&s.builder.buf, lo, hi)
	}
}

// true if selection head and tail dont match and form a selection of multiple characters
has_selection :: proc(s: ^State) -> bool {
	return s.selection[0] != s.selection[1]
}

// return the clamped lo/hi of the current selection
// since the selection[0] moves around and could be ahead of selection[1]
// useful when rendering and needing left->right
sorted_selection :: proc(s: ^State) -> (lo, hi: int) {
	lo = min(s.selection[0], s.selection[1])
	hi = max(s.selection[0], s.selection[1])
	lo = clamp(lo, 0, len(s.builder.buf) if s.builder != nil else 0)
	hi = clamp(hi, 0, len(s.builder.buf) if s.builder != nil else 0)
	return
}

// delete the current selection range and set the proper selection afterwards
selection_delete :: proc(s: ^State) {
	edit_begin(s, .Remove, 0)
	defer edit_end(s)

	lo, hi := sorted_selection(s)
	remove(s, lo, hi)
	s.selection = {lo, lo}
}

is_continuation_byte :: proc(b: byte) -> bool {
	return b >= 0x80 && b < 0xc0
}

// translates the caret position
// - soft line: the caret's line as laid out, from `State.line_start` to `State.line_end`
// - hard line: the caret's line as written, up to a `\n` or `\r\n`
// - smart start/end: skip the soft line's leading/trailing spaces and tabs, or go to its start/end if already there or the line is blank
translate_position :: proc(s: ^State, t: Translation) -> int {
	buf := text_bytes(s)
	pos := clamp(s.selection[0], 0, len(buf))

	switch t {
	case .Start:
		pos = 0
	case .End:
		pos = len(buf)
	case .Left:
		if s.translate_by_grapheme {
			// TODO(bill): determine if there is a faster way to determine the last grapheme
			// rather than iterate across the entire string (which may be very slow)
			it := utf8.decode_grapheme_iterator_make(string(buf[:pos]))
			g: utf8.Grapheme
			for {
				_, g = utf8.decode_grapheme_iterate(&it) or_break
			}
			pos -= max(len(g.text), 1)
		} else {
			pos -= 1
			for pos >= 0 && is_continuation_byte(buf[pos]) {
				pos -= 1
			}
		}
	case .Right:
		if s.translate_by_grapheme {
			it := utf8.decode_grapheme_iterator_make(string(buf[pos:]))

			_, g, _ := utf8.decode_grapheme_iterate(&it)
			pos += max(len(g.text), 1)
		} else {
			pos += 1
			for pos < len(buf) && is_continuation_byte(buf[pos]) {
				pos += 1
			}
		}
	case .Up:
		pos = s.up_index
	case .Down:
		pos = s.down_index
	case .Page_Up:
		pos = s.page_up_index
	case .Page_Down:
		pos = s.page_down_index
	case .Word_Left:
		// Skip the spaces, then the word or punctuation before them
		pos = word_run_start(s, pos, .Space)
		class, _ := word_class_before(s, pos)
		pos = word_run_start(s, pos, class)
	case .Word_Right:
		pos = word_run_end(s, pos, .Space)
		class, _ := word_class_after(s, pos)
		pos = word_run_end(s, pos, class)
	case .Word_Start:
		class, _ := word_class_before(s, pos)
		if class != .Space {
			pos = word_run_start(s, pos, class)
		}
	case .Word_End:
		class, _ := word_class_after(s, pos)
		if class != .Space {
			pos = word_run_end(s, pos, class)
		}
	case .Soft_Line_Start:
		pos = s.line_start
	case .Soft_Line_End:
		pos = s.line_end
	case .Hard_Line_Start:
		for pos > 0 && buf[pos-1] != '\n' {
			pos -= 1
		}
	case .Hard_Line_End:
		for pos < len(buf) && buf[pos] != '\n' {
			pos += 1
		}
		if 0 < pos && pos < len(buf) && buf[pos-1] == '\r' {
			pos -= 1
		}
	case .Smart_Line_Start:
		lo := clamp(s.line_start, 0, len(buf))
		hi := clamp(s.line_end, lo, len(buf))
		text_start := lo
		for text_start < hi && is_blank(buf[text_start]) {
			text_start += 1
		}
		pos = lo if text_start == hi || text_start == pos else text_start
	case .Smart_Line_End:
		lo := clamp(s.line_start, 0, len(buf))
		hi := clamp(s.line_end, lo, len(buf))
		text_end := hi
		for text_end > lo && is_blank(buf[text_end-1]) {
			text_end -= 1
		}
		pos = hi if text_end == lo || text_end == pos else text_end
	}
	return clamp(pos, 0, len(buf))
}

@(private, require_results)
is_blank :: proc(b: byte) -> bool {
	return b == ' ' || b == '\t'
}

// Word classes for code: ASCII punctuation separates words, except `_`
@(require_results)
word_class_ascii :: proc(r: rune) -> Word_Class {
	switch r {
	case ' ', '\t', '\n', '\v', '\f', '\r':
		return .Space
	case '!'..='/', ':'..='@', '['..='^', '`', '{'..='~':
		return .Punctuation
	}
	return .Word
}

// Word classes for any text: Unicode spaces, punctuation, and symbols separate words, except `_`
@(require_results)
word_class_unicode :: proc(r: rune) -> Word_Class {
	switch {
	case r < utf8.RUNE_SELF:
		return word_class_ascii(r)
	case unicode.is_space(r):
		return .Space
	case unicode.is_punct(r), unicode.is_symbol(r):
		return .Punctuation
	}
	return .Word
}

@(private, require_results)
text_bytes :: proc(s: ^State) -> []byte {
	if s.builder == nil {
		return nil
	}
	return s.builder.buf[:]
}

@(private, require_results)
word_class_of :: proc(s: ^State, r: rune) -> Word_Class {
	if s.word_class != nil {
		return s.word_class(r)
	}

	switch r {
	case ' ', '\t', '\n':
		return .Space
	}
	return .Word
}

// Combining marks, joiners, and emoji modifiers: runes that extend the rune before them
@(private, require_results)
is_extender :: proc(r: rune) -> bool {
	if r < utf8.RUNE_SELF {
		return false
	}
	if r == unicode.ZERO_WIDTH_JOINER {
		return true
	}
	return unicode.is_gcb_extend_class(r) || unicode.is_spacing_mark(r)
}

// The class of the character before `pos`, and where it starts
// - a character is a rune and the extenders after it
@(private, require_results)
word_class_before :: proc(s: ^State, pos: int) -> (class: Word_Class, start: int) {
	if pos <= 0 {
		return .Space, pos
	}
	buf := text_bytes(s)

	// Step back over the extenders first: they take the class of the rune before them
	start = pos
	extender: rune
	for start > 0 {
		r, w := utf8.decode_last_rune(buf[:start])
		if !is_extender(r) {
			break
		}
		extender = r
		start   -= w
	}
	if start == 0 {
		return word_class_of(s, extender), start
	}

	r, w := utf8.decode_last_rune(buf[:start])

	// Extenders after a line break or other control stand alone
	if start < pos && unicode.is_control(r) {
		return word_class_of(s, extender), start
	}
	return word_class_of(s, r), start-w
}

// The class of the character at `pos`, and where it ends
@(private, require_results)
word_class_after :: proc(s: ^State, pos: int) -> (class: Word_Class, end: int) {
	buf := text_bytes(s)
	if pos >= len(buf) {
		return .Space, pos
	}

	r, w := utf8.decode_rune(buf[pos:])
	end = pos + w

	// Extenders after a line break or other control stand alone
	if unicode.is_control(r) {
		return word_class_of(s, r), end
	}

	for end < len(buf) {
		next, next_w := utf8.decode_rune(buf[end:])
		if !is_extender(next) {
			break
		}
		end += next_w
	}
	return word_class_of(s, r), end
}

// The start of the run of `class` that ends at `pos`
@(private, require_results)
word_run_start :: proc(s: ^State, pos: int, class: Word_Class) -> int {
	start := pos
	for start > 0 {
		before, before_start := word_class_before(s, start)
		if before != class {
			break
		}
		start = before_start
	}
	return start
}

// The end of the run of `class` that starts at `pos`
@(private, require_results)
word_run_end :: proc(s: ^State, pos: int, class: Word_Class) -> int {
	end := pos
	for end < len(text_bytes(s)) {
		after, after_end := word_class_after(s, end)
		if after != class {
			break
		}
		end = after_end
	}
	return end
}

// Moves the position of the caret (both sides of the selection)
move_to :: proc(s: ^State, t: Translation) {
	s.moved_vertically = t in VERTICAL_TRANSLATIONS
	if t == .Left && has_selection(s) {
		lo, _ := sorted_selection(s)
		s.selection = {lo, lo}
	} else if t == .Right && has_selection(s) {
		_, hi := sorted_selection(s)
		s.selection = {hi, hi}
	} else {
		pos := translate_position(s, t)
		s.selection = {pos, pos}
	}
}

// Moves only the head of the selection and leaves the tail uneffected
select_to :: proc(s: ^State, t: Translation) {
	s.moved_vertically = t in VERTICAL_TRANSLATIONS
	s.selection[0] = translate_position(s, t)
}

// Selects all the text
select_all :: proc(s: ^State) {
	s.selection = {len(s.builder.buf) if s.builder != nil else 0, 0}
	s.moved_vertically = false
}

// Selects the word at the caret, or the spaces around it if there is no word
select_word :: proc(s: ^State) {
	pos := clamp(s.selection[0], 0, len(text_bytes(s)))

	// Prefer a word to punctuation, and either to spaces
	before, _ := word_class_before(s, pos)
	after,  _ := word_class_after(s, pos)
	class: Word_Class
	switch {
	case before == .Word || after == .Word:
		class = .Word
	case before == .Punctuation || after == .Punctuation:
		class = .Punctuation
	case:
		class = .Space
	}

	lo := word_run_start(s, pos, class)
	hi := word_run_end(s, pos, class)

	// Stay on the caret's line: a run of spaces can cross line breaks
	lo = max(lo, translate_position(s, .Hard_Line_Start))
	hi = min(hi, translate_position(s, .Hard_Line_End))

	s.selection = {hi, lo}
	s.moved_vertically = false
}

// Selects the caret's soft line and its line break
select_line :: proc(s: ^State) {
	lo := translate_position(s, .Soft_Line_Start)
	hi := translate_position(s, .Soft_Line_End)
	s.selection = {skip_line_break(s, hi), lo}
	s.moved_vertically = false
}

// Selects the caret's hard line and its line break
select_hard_line :: proc(s: ^State) {
	lo := translate_position(s, .Hard_Line_Start)
	hi := translate_position(s, .Hard_Line_End)
	s.selection = {skip_line_break(s, hi), lo}
	s.moved_vertically = false
}

@(private, require_results)
skip_line_break :: proc(s: ^State, pos: int) -> int {
	if s.builder == nil {
		return pos
	}

	rest := string(s.builder.buf[pos:])
	switch {
	case strings.has_prefix(rest, "\n"):   return pos+1
	case strings.has_prefix(rest, "\r\n"): return pos+2
	}
	return pos
}

// Deletes everything between the caret and resultant position
delete_to :: proc(s: ^State, t: Translation) {
	edit_begin(s, .Remove, 0)
	defer edit_end(s)

	if has_selection(s) {
		selection_delete(s)
	} else {
		lo := s.selection[0]
		hi := translate_position(s, t)
		lo, hi = min(lo, hi), max(lo, hi)
		remove(s, lo, hi)
		s.selection = {lo, lo}
	}
}

// return the currently selected text
current_selected_text :: proc(s: ^State) -> string {
	lo, hi := sorted_selection(s)
	if s.builder != nil {
		return string(s.builder.buf[lo:hi])
	}
	return ""
}

// copy & delete the current selection when copy() succeeds
cut :: proc(s: ^State) -> bool {
	if !copy(s) {
		return false
	}

	edit_begin(s, .Cut, 0)
	defer edit_end(s)

	lo, hi, _ := clipboard_range(s)
	remove(s, lo, hi)
	s.selection = {lo, lo}
	return true
}

// try and copy the currently selected text to the clipboard
// State.set_clipboard needs to be assigned
copy :: proc(s: ^State) -> bool {
	if s.set_clipboard == nil {
		return false
	}

	lo, hi, whole_line := clipboard_range(s)
	text := text_bytes(s)[lo:hi]

	// Remember a copied line by its hash: `paste` puts it back as a line
	s._clipboard_line_hash = 0
	if whole_line {
		s._clipboard_line_hash = hash.fnv64a(text)
	}

	return s.set_clipboard(s.clipboard_user_data, string(text))
}

// reinsert whatever the get_clipboard would return
// State.get_clipboard needs to be assigned
paste :: proc(s: ^State) -> bool {
	@(require_results)
	is_copied_line :: proc(s: ^State, text: string) -> bool {
		if .Line_Clipboard not_in s.options {
			return false
		}
		if has_selection(s) {
			return false
		}
		if s._clipboard_line_hash == 0 {
			return false
		}
		return s._clipboard_line_hash == hash.fnv64a(transmute([]byte)text)
	}

	if s.get_clipboard == nil {
		return false
	}
	text := s.get_clipboard(s.clipboard_user_data) or_return
	if len(text) == 0 {
		return true
	}

	edit_begin(s, .Paste, 0)
	defer edit_end(s)

	if !is_copied_line(s, text) {
		input_text(s, text)
		return true
	}

	// Put the line above the caret's line, and keep the caret on its own text
	caret, _ := sorted_selection(s)
	at := translate_position(s, .Hard_Line_Start)
	n  := insert(s, at, text)
	if n == len(text) && !strings.has_suffix(text, "\n") {
		n += insert(s, at+n, "\n")
	}
	s.selection = {caret+n, caret+n}
	return true
}

// What `copy` and `cut` take: the selection, or with `.Line_Clipboard` and nothing selected, the caret's hard line
@(private, require_results)
clipboard_range :: proc(s: ^State) -> (lo, hi: int, whole_line: bool) {
	if has_selection(s) || .Line_Clipboard not_in s.options {
		lo, hi = sorted_selection(s)
		return
	}

	lo = translate_position(s, .Hard_Line_Start)
	hi = skip_line_break(s, translate_position(s, .Hard_Line_End))
	return lo, hi, true
}


Command_Set :: distinct bit_set[Command; u64]

Command :: enum u32 {
	None,
	Undo,
	Redo,
	New_Line,         // multi-lines
	Cut,
	Copy,
	Paste,
	Select_All,
	Select_Word,
	Select_Line,
	Select_Hard_Line,
	Backspace,
	Delete,
	Delete_Word_Left,
	Delete_Word_Right,
	Left,
	Right,
	Up,               // multi-lines
	Down,             // multi-lines
	Page_Up,          // multi-lines
	Page_Down,        // multi-lines
	Word_Left,
	Word_Right,
	Start,
	End,
	Line_Start,
	Line_End,
	Hard_Line_Start,
	Hard_Line_End,
	Smart_Line_Start,
	Smart_Line_End,
	Select_Left,
	Select_Right,
	Select_Up,        // multi-lines
	Select_Down,      // multi-lines
	Select_Page_Up,   // multi-lines
	Select_Page_Down, // multi-lines
	Select_Word_Left,
	Select_Word_Right,
	Select_Start,
	Select_End,
	Select_Line_Start,
	Select_Line_End,
	Select_Hard_Line_Start,
	Select_Hard_Line_End,
	Select_Smart_Line_Start,
	Select_Smart_Line_End,
}

MULTILINE_COMMANDS :: Command_Set{
	.New_Line,
	.Up, .Down, .Page_Up, .Page_Down,
	.Select_Up, .Select_Down, .Select_Page_Up, .Select_Page_Down,
}

perform_command :: proc(s: ^State, cmd: Command) {
	switch cmd {
	case .None:                    /**/
	case .Undo:                    undo(s, &s.undo, &s.redo)
	case .Redo:                    undo(s, &s.redo, &s.undo)
	case .New_Line:                new_line(s)
	case .Cut:                     cut(s)
	case .Copy:                    copy(s)
	case .Paste:                   paste(s)
	case .Select_All:              select_all(s)
	case .Select_Word:             select_word(s)
	case .Select_Line:             select_line(s)
	case .Select_Hard_Line:        select_hard_line(s)
	case .Backspace:               delete_to(s, .Left)
	case .Delete:                  delete_to(s, .Right)
	case .Delete_Word_Left:        delete_to(s, .Word_Left)
	case .Delete_Word_Right:       delete_to(s, .Word_Right)
	case .Left:                    move_to(s, .Left)
	case .Right:                   move_to(s, .Right)
	case .Up:                      move_to(s, .Up)
	case .Down:                    move_to(s, .Down)
	case .Page_Up:                 move_to(s, .Page_Up)
	case .Page_Down:               move_to(s, .Page_Down)
	case .Word_Left:               move_to(s, .Word_Left)
	case .Word_Right:              move_to(s, .Word_Right)
	case .Start:                   move_to(s, .Start)
	case .End:                     move_to(s, .End)
	case .Line_Start:              move_to(s, .Soft_Line_Start)
	case .Line_End:                move_to(s, .Soft_Line_End)
	case .Hard_Line_Start:         move_to(s, .Hard_Line_Start)
	case .Hard_Line_End:           move_to(s, .Hard_Line_End)
	case .Smart_Line_Start:        move_to(s, .Smart_Line_Start)
	case .Smart_Line_End:          move_to(s, .Smart_Line_End)
	case .Select_Left:             select_to(s, .Left)
	case .Select_Right:            select_to(s, .Right)
	case .Select_Up:               select_to(s, .Up)
	case .Select_Down:             select_to(s, .Down)
	case .Select_Page_Up:          select_to(s, .Page_Up)
	case .Select_Page_Down:        select_to(s, .Page_Down)
	case .Select_Word_Left:        select_to(s, .Word_Left)
	case .Select_Word_Right:       select_to(s, .Word_Right)
	case .Select_Start:            select_to(s, .Start)
	case .Select_End:              select_to(s, .End)
	case .Select_Line_Start:       select_to(s, .Soft_Line_Start)
	case .Select_Line_End:         select_to(s, .Soft_Line_End)
	case .Select_Hard_Line_Start:  select_to(s, .Hard_Line_Start)
	case .Select_Hard_Line_End:    select_to(s, .Hard_Line_End)
	case .Select_Smart_Line_Start: select_to(s, .Smart_Line_Start)
	case .Select_Smart_Line_End:   select_to(s, .Smart_Line_End)
	}
}
