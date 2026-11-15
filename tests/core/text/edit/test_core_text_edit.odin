package test_core_text_edit

import "core:slice"
import "core:strings"
import "core:testing"
import "core:text/edit"
import "core:time"

// "hi", a thumbs-up with a skin tone modifier, an "e" with a combining acute, and "!".
// The escapes are spelled out so the byte offsets below do not depend on how this
// file happens to be normalized.
//
//	byte:  0  1  2            6            10  11         13  14
//	rune:  h  i  U+1F44D      U+1F3FD      e   U+0301      !
GRAPHEME_SAMPLE :: "hi\U0001F44D\U0001F3FDe\u0301!"

WORD_SAMPLE :: "foo bar  baz"

// Two multi-byte lines around an empty one, then an empty last line.
//
//	byte:  0  1       3   4   5       8  9   10
//	rune:  a  U+00E9  \n  \n  U+4E16  b  \n
HARD_LINE_SAMPLE :: "aé\n\n世b\n"

CRLF_SAMPLE :: "ab\r\ncd"

// An indented line with trailing blanks (bytes 0..<9), a blank line (10..<13), and an empty one (14).
SMART_SAMPLE :: "  été \t\n \t \n"

// One hard line, wrapped as "    foo " (bytes 0..<8) and "bar baz" (8..<15).
WRAPPED_SAMPLE :: "    foo bar baz"

State :: struct {
	state:   edit.State,
	builder: strings.Builder,
}

state_init :: proc(s: ^State, str: string, translate_by_grapheme: bool) {
	s.builder = strings.builder_make()
	strings.write_string(&s.builder, str)

	edit.init(&s.state, context.allocator, context.allocator)
	edit.setup_once(&s.state, &s.builder)
	s.state.translate_by_grapheme = translate_by_grapheme
}

state_destroy :: proc(s: ^State) {
	edit.destroy(&s.state)
	strings.builder_destroy(&s.builder)
}

// Walk the caret from `start` in direction `t` until it stops moving, collecting
// every position it comes to rest on.
walk :: proc(s: ^State, start: int, t: edit.Translation) -> (stops: [dynamic]int) {
	s.state.selection = {start, start}
	for {
		prev := s.state.selection[0]
		edit.move_to(&s.state, t)
		if s.state.selection[0] == prev {
			return
		}
		append(&stops, s.state.selection[0])
	}
}

expect_walk :: proc(t: ^testing.T, s: ^State, start: int, translation: edit.Translation, expected: []int) {
	stops := walk(s, start, translation)
	defer delete(stops)

	testing.expectf(t, slice.equal(stops[:], expected),
		"%v from %v: expected stops %v, got %v", translation, start, expected, stops[:])
}

// Moving by grapheme must stop on grapheme cluster boundaries, never inside the
// emoji modifier sequence or between a base rune and its combining marks.
@(test)
test_translate_by_grapheme :: proc(t: ^testing.T) {
	s: State
	state_init(&s, GRAPHEME_SAMPLE, true)
	defer state_destroy(&s)

	expect_walk(t, &s, 0, .Right, {1, 2, 10, 13, 14})
	expect_walk(t, &s, len(GRAPHEME_SAMPLE), .Left, {13, 10, 2, 1, 0})
}

// The default translation moves by codepoint, so it steps through the two runes
// of the emoji sequence and the two runes of "e" + combining acute separately.
@(test)
test_translate_by_codepoint :: proc(t: ^testing.T) {
	s: State
	state_init(&s, GRAPHEME_SAMPLE, false)
	defer state_destroy(&s)

	expect_walk(t, &s, 0, .Right, {1, 2, 6, 10, 11, 13, 14})
	expect_walk(t, &s, len(GRAPHEME_SAMPLE), .Left, {13, 11, 10, 6, 2, 1, 0})
}

@(test)
test_translate_by_word :: proc(t: ^testing.T) {
	s: State
	state_init(&s, WORD_SAMPLE, false)
	defer state_destroy(&s)

	expect_walk(t, &s, 0, .Word_Right, {3, 7, 12})
	expect_walk(t, &s, len(WORD_SAMPLE), .Word_Left, {9, 4, 0})

	// From inside "bar", to the edges of that word.
	s.state.selection = {5, 5}
	testing.expect_value(t, edit.translate_position(&s.state, .Word_Start), 4)
	testing.expect_value(t, edit.translate_position(&s.state, .Word_End), 7)
}

@(test)
test_translate_to_bounds :: proc(t: ^testing.T) {
	s: State
	state_init(&s, GRAPHEME_SAMPLE, true)
	defer state_destroy(&s)

	s.state.selection = {5, 5}
	testing.expect_value(t, edit.translate_position(&s.state, .Start), 0)
	testing.expect_value(t, edit.translate_position(&s.state, .End), len(GRAPHEME_SAMPLE))

	// Translating past either end must clamp rather than run off the buffer.
	s.state.selection = {0, 0}
	testing.expect_value(t, edit.translate_position(&s.state, .Left), 0)
	s.state.selection = {len(GRAPHEME_SAMPLE), len(GRAPHEME_SAMPLE)}
	testing.expect_value(t, edit.translate_position(&s.state, .Right), len(GRAPHEME_SAMPLE))
}

@(test)
test_translate_by_page :: proc(t: ^testing.T) {
	s: State
	state_init(&s, HARD_LINE_SAMPLE, false)
	defer state_destroy(&s)

	s.state.page_up_index   = 1
	s.state.page_down_index = 8

	s.state.selection = {4, 4}
	testing.expect_value(t, edit.translate_position(&s.state, .Page_Up),   1)
	testing.expect_value(t, edit.translate_position(&s.state, .Page_Down), 8)

	edit.move_to(&s.state, .Page_Down)
	testing.expect_value(t, s.state.selection, [2]int{8, 8})
	edit.select_to(&s.state, .Page_Up)
	testing.expect_value(t, s.state.selection, [2]int{1, 8})

	// Stale indices clamp to the text.
	s.state.page_up_index   = -1
	s.state.page_down_index = len(HARD_LINE_SAMPLE)+5
	testing.expect_value(t, edit.translate_position(&s.state, .Page_Up),   0)
	testing.expect_value(t, edit.translate_position(&s.state, .Page_Down), len(HARD_LINE_SAMPLE))
}

@(test)
test_translate_by_hard_line :: proc(t: ^testing.T) {
	Case :: struct {
		text:       string,
		caret:      int,
		start, end: int,
	}
	@(static, rodata)
	cases := [?]Case{
		{HARD_LINE_SAMPLE,  0,  0,  3},
		{HARD_LINE_SAMPLE,  1,  0,  3},
		{HARD_LINE_SAMPLE,  3,  0,  3},
		{HARD_LINE_SAMPLE,  4,  4,  4},
		{HARD_LINE_SAMPLE,  5,  5,  9},
		{HARD_LINE_SAMPLE,  8,  5,  9},
		{HARD_LINE_SAMPLE,  9,  5,  9},
		{HARD_LINE_SAMPLE, 10, 10, 10},
		{CRLF_SAMPLE,       1,  0,  2},
		{CRLF_SAMPLE,       2,  0,  2},
		{CRLF_SAMPLE,       4,  4,  6},
		{CRLF_SAMPLE,       6,  4,  6},
		{WRAPPED_SAMPLE,   12,  0, 15},
		{"\nx",             0,  0,  0},
		{"\nx",             1,  1,  2},
	}

	for c in cases {
		s: State
		state_init(&s, c.text, false)
		defer state_destroy(&s)

		s.state.selection = {c.caret, c.caret}
		start := edit.translate_position(&s.state, .Hard_Line_Start)
		end   := edit.translate_position(&s.state, .Hard_Line_End)
		testing.expectf(t, start == c.start && end == c.end,
			"%q from %v: expected hard line %v..<%v, got %v..<%v", c.text, c.caret, c.start, c.end, start, end)
	}
}

@(test)
test_translate_by_smart_line :: proc(t: ^testing.T) {
	Case :: struct {
		text:       string,
		line:       [2]int,
		caret:      int,
		start, end: int,
	}
	@(static, rodata)
	cases := [?]Case{
		{SMART_SAMPLE,   { 0,   9},  4,  2,  7},
		{SMART_SAMPLE,   { 0,   9},  2,  0,  7},
		{SMART_SAMPLE,   { 0,   9},  0,  2,  7},
		{SMART_SAMPLE,   { 0,   9},  1,  2,  7},
		{SMART_SAMPLE,   { 0,   9},  7,  2,  9},
		{SMART_SAMPLE,   { 0,   9},  8,  2,  7},
		{SMART_SAMPLE,   { 0,   9},  9,  2,  7},
		{SMART_SAMPLE,   {10,  13}, 11, 10, 13},
		{SMART_SAMPLE,   {10,  13}, 10, 10, 13},
		{SMART_SAMPLE,   {10,  13}, 13, 10, 13},
		{SMART_SAMPLE,   {14,  14}, 14, 14, 14},

		// On a wrapped row, the hard line's indentation is out of reach.
		{WRAPPED_SAMPLE, { 0,   8},  6,  4,  7},
		{WRAPPED_SAMPLE, { 0,   8},  4,  0,  7},
		{WRAPPED_SAMPLE, { 0,   8},  7,  4,  8},
		{WRAPPED_SAMPLE, { 8,  15}, 12,  8, 15},
		{WRAPPED_SAMPLE, { 8,  15},  8,  8, 15},
		{WRAPPED_SAMPLE, { 8,  15}, 15,  8, 15},

		{"  x ",         {-5, 100},  3,  2,  4},
	}

	for c in cases {
		s: State
		state_init(&s, c.text, false)
		defer state_destroy(&s)

		s.state.line_start = c.line[0]
		s.state.line_end   = c.line[1]
		s.state.selection  = {c.caret, c.caret}
		start := edit.translate_position(&s.state, .Smart_Line_Start)
		end   := edit.translate_position(&s.state, .Smart_Line_End)
		testing.expectf(t, start == c.start && end == c.end,
			"%q line %v from %v: expected smart start %v and end %v, got %v and %v",
			c.text, c.line, c.caret, c.start, c.end, start, end)
	}

	// Repeated presses toggle between the text and the line's start.
	s: State
	state_init(&s, SMART_SAMPLE, false)
	defer state_destroy(&s)

	s.state.line_start = 0
	s.state.line_end   = 9
	s.state.selection  = {4, 4}
	for expected in ([?]int{2, 0, 2, 0}) {
		edit.move_to(&s.state, .Smart_Line_Start)
		testing.expect_value(t, s.state.selection, [2]int{expected, expected})
	}
}

@(test)
test_select_word :: proc(t: ^testing.T) {
	Case :: struct {
		text:     string,
		caret:    int,
		expected: [2]int,
	}
	@(static, rodata)
	cases := [?]Case{
		{WORD_SAMPLE,               0, { 3, 0}},
		{WORD_SAMPLE,               2, { 3, 0}},
		{WORD_SAMPLE,               3, { 3, 0}},
		{WORD_SAMPLE,               4, { 7, 4}},
		{WORD_SAMPLE,               7, { 7, 4}},
		{WORD_SAMPLE,               8, { 9, 7}},
		{WORD_SAMPLE,               9, {12, 9}},
		{WORD_SAMPLE,              12, {12, 9}},
		{"über straße",   2, { 5, 0}},
		{"über straße",  10, {13, 6}},
		{"über straße",  13, {13, 6}},
		{"a \t b",                  2, { 4, 1}},
		{"foo\n\n  \nbar",          3, { 3, 0}},
		{"foo\n\n  \nbar",          4, { 4, 4}},
		{"foo\n\n  \nbar",          6, { 7, 5}},
		{"foo\n\n  \nbar",          8, {11, 8}},
		{"",                        0, { 0, 0}},
	}

	for c in cases {
		s: State
		state_init(&s, c.text, false)
		defer state_destroy(&s)

		s.state.selection = {c.caret, c.caret}
		edit.select_word(&s.state)
		testing.expectf(t, s.state.selection == c.expected,
			"%q from %v: expected selection %v, got %v", c.text, c.caret, c.expected, s.state.selection)
	}
}

@(test)
test_select_line :: proc(t: ^testing.T) {
	Case :: struct {
		text:     string,
		line:     [2]int,
		caret:    int,
		expected: [2]int,
	}
	@(static, rodata)
	cases := [?]Case{
		{WRAPPED_SAMPLE, {0,  8},  2, { 8, 0}},
		{WRAPPED_SAMPLE, {8, 15}, 10, {15, 8}},
		{"foo bar\nbaz", {0,  4},  1, { 4, 0}},
		{"foo bar\nbaz", {4,  7},  5, { 8, 4}},
		{"foo bar\nbaz", {8, 11},  9, {11, 8}},
		{CRLF_SAMPLE,    {0,  2},  1, { 4, 0}},
		{"",             {0,  0},  0, { 0, 0}},
	}

	for c in cases {
		s: State
		state_init(&s, c.text, false)
		defer state_destroy(&s)

		s.state.line_start = c.line[0]
		s.state.line_end   = c.line[1]
		s.state.selection  = {c.caret, c.caret}
		edit.select_line(&s.state)
		testing.expectf(t, s.state.selection == c.expected,
			"%q line %v from %v: expected selection %v, got %v", c.text, c.line, c.caret, c.expected, s.state.selection)
	}
}

@(test)
test_select_hard_line :: proc(t: ^testing.T) {
	Case :: struct {
		text:     string,
		caret:    int,
		expected: [2]int,
	}
	@(static, rodata)
	cases := [?]Case{
		{HARD_LINE_SAMPLE,  0, { 4,  0}},
		{HARD_LINE_SAMPLE,  3, { 4,  0}},
		{HARD_LINE_SAMPLE,  4, { 5,  4}},
		{HARD_LINE_SAMPLE,  8, {10,  5}},
		{HARD_LINE_SAMPLE, 10, {10, 10}},
		{CRLF_SAMPLE,       1, { 4,  0}},
		{CRLF_SAMPLE,       5, { 6,  4}},
		{WRAPPED_SAMPLE,   12, {15,  0}},
		{"",                0, { 0,  0}},
	}

	for c in cases {
		s: State
		state_init(&s, c.text, false)
		defer state_destroy(&s)

		s.state.selection = {c.caret, c.caret}
		edit.select_hard_line(&s.state)
		testing.expectf(t, s.state.selection == c.expected,
			"%q from %v: expected selection %v, got %v", c.text, c.caret, c.expected, s.state.selection)
	}
}

@(test)
test_perform_command :: proc(t: ^testing.T) {
	Case :: struct {
		command:  edit.Command,
		expected: [2]int,
	}
	@(static, rodata)
	cases := [?]Case{
		{.Page_Up,                 { 1,  1}},
		{.Page_Down,               {17, 17}},
		{.Hard_Line_Start,         { 6,  6}},
		{.Hard_Line_End,           {16, 16}},
		{.Smart_Line_Start,        { 8,  8}},
		{.Smart_Line_End,          {11, 11}},
		{.Select_Page_Up,          { 1,  9}},
		{.Select_Page_Down,        {17,  9}},
		{.Select_Hard_Line_Start,  { 6,  9}},
		{.Select_Hard_Line_End,    {16,  9}},
		{.Select_Smart_Line_Start, { 8,  9}},
		{.Select_Smart_Line_End,   {11,  9}},
		{.Select_All,              {17,  0}},
		{.Select_Word,             {11,  8}},
		{.Select_Line,             {12,  8}},
		{.Select_Hard_Line,        {17,  6}},
	}

	// The caret is in "bar" (8..<11), its hard line is "  bar baz " (6..<16), and its soft line is "bar " (8..<12).
	TEXT :: "  foo\n  bar baz \n"

	for c in cases {
		s: State
		state_init(&s, TEXT, false)
		defer state_destroy(&s)

		s.state.line_start      = 8
		s.state.line_end        = 12
		s.state.page_up_index   = 1
		s.state.page_down_index = 17

		s.state.selection = {10, 9}
		edit.perform_command(&s.state, c.command)
		testing.expectf(t, s.state.selection == c.expected,
			"%v: expected selection %v, got %v", c.command, c.expected, s.state.selection)
	}

	testing.expect(t, edit.Command_Set{.Page_Up, .Page_Down, .Select_Page_Up, .Select_Page_Down} <= edit.MULTILINE_COMMANDS)
}

@(test)
test_moved_vertically :: proc(t: ^testing.T) {
	VERTICAL :: edit.Command_Set{
		.Up, .Down, .Page_Up, .Page_Down,
		.Select_Up, .Select_Down, .Select_Page_Up, .Select_Page_Down,
	}
	UNCHANGED :: edit.Command_Set{.None, .Copy}

	set_clipboard :: proc(_: rawptr, _: string) -> (ok: bool) {
		return true
	}
	get_clipboard :: proc(_: rawptr) -> (text: string, ok: bool) {
		return "x", true
	}

	// Give every command something to do.
	for command in edit.Command {
		for before in ([?]bool{false, true}) {
			s: State
			state_init(&s, HARD_LINE_SAMPLE, false)
			defer state_destroy(&s)

			s.state.set_clipboard = set_clipboard
			s.state.get_clipboard = get_clipboard
			edit.undo_state_push(&s.state, &s.state.undo)
			edit.undo_state_push(&s.state, &s.state.redo)

			s.state.selection        = {5, 1}
			s.state.moved_vertically = before
			edit.perform_command(&s.state, command)

			expected := false
			switch {
			case command in VERTICAL:  expected = true
			case command in UNCHANGED: expected = before
			}
			testing.expectf(t, s.state.moved_vertically == expected,
				"%v from %v: expected moved_vertically to be %v", command, before, expected)
		}
	}

	@(static, rodata)
	clearers := [?]proc(s: ^State){
		proc(s: ^State) { edit.input_rune(&s.state, 'x') },
		proc(s: ^State) { edit.input_runes(&s.state, {'x'}) },
		proc(s: ^State) { edit.delete_to(&s.state, .Hard_Line_End) },
		proc(s: ^State) { edit.setup_once(&s.state, &s.builder) },
		proc(s: ^State) { edit.clear_all(&s.state) },
		proc(s: ^State) { edit.begin(&s.state, 1, &s.builder); edit.end(&s.state) },
	}

	for clearer, i in clearers {
		s: State
		state_init(&s, HARD_LINE_SAMPLE, false)
		defer state_destroy(&s)

		s.state.selection        = {5, 5}
		s.state.moved_vertically = true
		clearer(&s)
		testing.expectf(t, !s.state.moved_vertically, "clearers[%v]: expected moved_vertically to be cleared", i)
	}
}

@(test)
test_empty_buffer :: proc(t: ^testing.T) {
	s: State
	state_init(&s, "", true)
	defer state_destroy(&s)

	// Stale layout clamps to the empty text.
	s.state.line_start      = 3
	s.state.line_end        = 5
	s.state.up_index        = 3
	s.state.down_index      = 5
	s.state.page_up_index   = 3
	s.state.page_down_index = 5

	for class in ([?]proc(r: rune) -> edit.Word_Class{nil, edit.word_class_ascii, edit.word_class_unicode}) {
		s.state.word_class = class
		for translation in edit.Translation {
			s.state.selection = {0, 0}
			testing.expectf(t, edit.translate_position(&s.state, translation) == 0, "%v: expected 0", translation)
		}
	}

	edit.select_word(&s.state)
	testing.expect_value(t, s.state.selection, [2]int{0, 0})
	edit.select_line(&s.state)
	testing.expect_value(t, s.state.selection, [2]int{0, 0})
	edit.select_hard_line(&s.state)
	testing.expect_value(t, s.state.selection, [2]int{0, 0})
}

CODE_SAMPLE :: "foo.bar(baz) qux"

expect_words :: proc(
	t:           ^testing.T,
	text:        string,
	class:       proc(r: rune) -> edit.Word_Class,
	translation: edit.Translation,
	expected:    []int,
	loc        := #caller_location,
) {
	s: State
	state_init(&s, text, false)
	defer state_destroy(&s)

	s.state.word_class = class
	stops := walk(&s, 0 if translation == .Word_Right else len(text), translation)
	defer delete(stops)

	testing.expectf(t, slice.equal(stops[:], expected),
		"%q %v: expected stops %v, got %v", text, translation, expected, stops[:], loc=loc)
}

@(test)
test_word_class :: proc(t: ^testing.T) {
	expect_words(t, CODE_SAMPLE,   nil,                     .Word_Right, {12, 16})
	expect_words(t, CODE_SAMPLE,   nil,                     .Word_Left,  {13, 0})
	expect_words(t, CODE_SAMPLE,   edit.word_class_ascii,   .Word_Right, {3, 4, 7, 8, 11, 12, 16})
	expect_words(t, CODE_SAMPLE,   edit.word_class_ascii,   .Word_Left,  {13, 11, 8, 7, 4, 3, 0})
	expect_words(t, "foo_bar.baz", edit.word_class_ascii,   .Word_Right, {7, 8, 11})
	expect_words(t, "café—naïve",  edit.word_class_ascii,   .Word_Right, {14})
	expect_words(t, "café—naïve",  edit.word_class_unicode, .Word_Right, {5, 8, 14})
	expect_words(t, "a　b",    edit.word_class_ascii,   .Word_Right, {5})
	expect_words(t, "a　b",    edit.word_class_unicode, .Word_Right, {1, 5})

	// Marks, joiners, and modifiers stay with the rune before them.
	expect_words(t, "!́a",                      edit.word_class_ascii,   .Word_Right, {3, 4})
	expect_words(t, "a\U0001F468‍\U0001F469b", edit.word_class_unicode, .Word_Right, {1, 12, 13})
	expect_words(t, "a\U0001F468‍\U0001F469b", edit.word_class_unicode, .Word_Left,  {12, 1, 0})

	// Except after a line break: it ends a grapheme cluster.
	expect_words(t, "a\ńb", nil,                   .Word_Left,  {2, 0})
	expect_words(t, "a\ń.", edit.word_class_ascii, .Word_Right, {1, 4, 5})

	s: State
	state_init(&s, "foo.bar", false)
	defer state_destroy(&s)

	s.state.word_class = edit.word_class_ascii
	s.state.selection  = {3, 3}
	testing.expect_value(t, edit.translate_position(&s.state, .Word_Start), 0)
	testing.expect_value(t, edit.translate_position(&s.state, .Word_End),   4)

	s.state.selection = {7, 7}
	edit.perform_command(&s.state, .Delete_Word_Left)
	testing.expect_value(t, strings.to_string(s.builder), "foo.")
}

@(test)
test_select_word_class :: proc(t: ^testing.T) {
	Case :: struct {
		text:     string,
		class:    proc(r: rune) -> edit.Word_Class,
		caret:    int,
		expected: [2]int,
	}
	@(static, rodata)
	cases := [?]Case{
		{"foo.bar",        edit.word_class_ascii,   2, {3, 0}},
		{"foo.bar",        edit.word_class_ascii,   3, {3, 0}},
		{"foo.bar",        edit.word_class_ascii,   4, {7, 4}},
		{"a..b",           edit.word_class_ascii,   2, {3, 1}},
		{"a　　b", edit.word_class_unicode, 4, {7, 1}},
		{"foo\r\n",        nil,                     1, {3, 0}},
	}

	for c in cases {
		s: State
		state_init(&s, c.text, false)
		defer state_destroy(&s)

		s.state.word_class = c.class
		s.state.selection  = {c.caret, c.caret}
		edit.select_word(&s.state)
		testing.expectf(t, s.state.selection == c.expected,
			"%q from %v: expected selection %v, got %v", c.text, c.caret, c.expected, s.state.selection)
	}
}

@(test)
test_keep_indent :: proc(t: ^testing.T) {
	Case :: struct {
		text:      string,
		selection: [2]int,
		expected:  string,
		caret:     int,
	}
	@(static, rodata)
	cases := [?]Case{
		{"    foo",     { 7, 7}, "    foo\n    ",  12},
		{"\t foo",      { 5, 5}, "\t foo\n\t ",     8},
		{"    foo",     { 2, 2}, "  \n    foo",      5},
		{"a\n  b",      { 5, 5}, "a\n  b\n  ",       8},
		{"    foo bar", {11, 8}, "    foo \n    ", 13},
		{"foo",         { 3, 3}, "foo\n",            4},
		{"",            { 0, 0}, "\n",               1},
	}

	for c in cases {
		s: State
		state_init(&s, c.text, false)
		defer state_destroy(&s)

		s.state.options   = {.Keep_Indent}
		s.state.selection = c.selection
		edit.perform_command(&s.state, .New_Line)
		testing.expectf(t, strings.to_string(s.builder) == c.expected && s.state.selection == {c.caret, c.caret},
			"%q at %v: expected %q with the caret at %v, got %q at %v",
			c.text, c.selection, c.expected, c.caret, strings.to_string(s.builder), s.state.selection)
	}

	s: State
	state_init(&s, "    foo", false)
	defer state_destroy(&s)

	// Without the option, a bare line break.
	s.state.selection = {7, 7}
	edit.perform_command(&s.state, .New_Line)
	testing.expect_value(t, strings.to_string(s.builder), "    foo\n")

	// An indentation longer than one copy chunk, undone as one step.
	strings.builder_reset(&s.builder)
	for _ in 0..<100 {
		strings.write_byte(&s.builder, ' ')
	}
	strings.write_byte(&s.builder, 'x')
	before := strings.clone(strings.to_string(s.builder))
	defer delete(before)

	edit.update_time(&s.state)
	s.state.options     = {.Keep_Indent}
	s.state.undo_breaks = {.Every_Edit}
	s.state.selection   = {101, 101}
	edit.perform_command(&s.state, .New_Line)
	expected := strings.concatenate({before, "\n", before[:100]})
	defer delete(expected)
	testing.expect_value(t, strings.to_string(s.builder), expected)
	testing.expect_value(t, s.state.selection, [2]int{202, 202})

	expect_undos(t, &s, {before})
}

clipboard_set :: proc(user_data: rawptr, text: string) -> (ok: bool) {
	b := (^strings.Builder)(user_data)
	strings.builder_reset(b)
	strings.write_string(b, text)
	return true
}

clipboard_get :: proc(user_data: rawptr) -> (text: string, ok: bool) {
	return strings.to_string((^strings.Builder)(user_data)^), true
}

@(test)
test_line_clipboard :: proc(t: ^testing.T) {
	clipboard: strings.Builder
	defer strings.builder_destroy(&clipboard)

	s: State
	state_init(&s, "ab\ncd\nef", false)
	defer state_destroy(&s)

	s.state.set_clipboard       = clipboard_set
	s.state.get_clipboard       = clipboard_get
	s.state.clipboard_user_data = &clipboard

	// Without the option, nothing selected copies nothing.
	s.state.selection = {4, 4}
	edit.copy(&s.state)
	testing.expect_value(t, strings.to_string(clipboard), "")

	s.state.options = {.Line_Clipboard}
	edit.copy(&s.state)
	testing.expect_value(t, strings.to_string(clipboard), "cd\n")
	s.state.selection = {7, 7}
	edit.copy(&s.state)
	testing.expect_value(t, strings.to_string(clipboard), "ef")

	s.state.selection = {4, 4}
	edit.cut(&s.state)
	testing.expect_value(t, strings.to_string(s.builder), "ab\nef")
	testing.expect_value(t, strings.to_string(clipboard), "cd\n")
	testing.expect_value(t, s.state.selection, [2]int{3, 3})

	// A line goes back above the caret's line, and the caret stays with its text.
	s.state.selection = {4, 4}
	edit.paste(&s.state)
	testing.expect_value(t, strings.to_string(s.builder), "ab\ncd\nef")
	testing.expect_value(t, s.state.selection, [2]int{7, 7})

	// The last line has no break of its own and gets one.
	edit.copy(&s.state)
	s.state.selection = {1, 1}
	edit.paste(&s.state)
	testing.expect_value(t, strings.to_string(s.builder), "ef\nab\ncd\nef")
	testing.expect_value(t, s.state.selection, [2]int{4, 4})

	// A selection is replaced as usual.
	s.state.selection = {5, 3}
	edit.paste(&s.state)
	testing.expect_value(t, strings.to_string(s.builder), "ef\nef\ncd\nef")
	testing.expect_value(t, s.state.selection, [2]int{5, 5})

	// Text copied from a selection pastes at the caret.
	s.state.selection = {2, 0}
	edit.copy(&s.state)
	s.state.selection = {1, 1}
	edit.paste(&s.state)
	testing.expect_value(t, strings.to_string(s.builder), "eeff\nef\ncd\nef")
	testing.expect_value(t, s.state.selection, [2]int{3, 3})

	// So does text that replaced a copied line on the clipboard.
	s.state.selection = {4, 4}
	edit.copy(&s.state)
	clipboard_set(&clipboard, "zz")
	s.state.selection = {0, 0}
	edit.paste(&s.state)
	testing.expect_value(t, strings.to_string(s.builder), "zzeeff\nef\ncd\nef")
	testing.expect_value(t, s.state.selection, [2]int{2, 2})
}

type_text :: proc(s: ^State, text: string) {
	for r in text {
		edit.input_rune(&s.state, r)
	}
}

expect_undos :: proc(t: ^testing.T, s: ^State, expected: []string, loc := #caller_location) {
	for e, i in expected {
		edit.perform_command(&s.state, .Undo)
		testing.expectf(t, strings.to_string(s.builder) == e,
			"undo %v: expected %q, got %q", i, e, strings.to_string(s.builder), loc=loc)
	}
	testing.expectf(t, len(s.state.undo) == 0, "expected no more undo steps, got %v", len(s.state.undo), loc=loc)
}

// Starts the clock once: only the first edit sees a pause.
undo_init :: proc(s: ^State, text: string, breaks: edit.Undo_Break_Set) {
	state_init(s, text, false)
	edit.update_time(&s.state)
	s.state.undo_breaks = breaks
}

pause :: proc(s: ^State) {
	s.state.current_time = time.tick_add(s.state.current_time, time.Second)
}

@(test)
test_undo_breaks :: proc(t: ^testing.T) {
	{
		s: State
		undo_init(&s, "", {})
		defer state_destroy(&s)

		type_text(&s, "ab")
		edit.perform_command(&s.state, .Backspace)
		type_text(&s, "c")
		expect_undos(t, &s, {""})
	}
	{
		s: State
		undo_init(&s, "", {})
		defer state_destroy(&s)

		type_text(&s, "a")
		pause(&s)
		type_text(&s, "b")
		expect_undos(t, &s, {"a", ""})
	}
	{
		s: State
		undo_init(&s, "", {.Kind})
		defer state_destroy(&s)

		type_text(&s, "ab")
		edit.perform_command(&s.state, .Backspace)
		type_text(&s, "c")
		expect_undos(t, &s, {"a", "ab", ""})
	}
	{
		clipboard: strings.Builder
		defer strings.builder_destroy(&clipboard)
		clipboard_set(&clipboard, "x")

		s: State
		undo_init(&s, "", {.Kind})
		defer state_destroy(&s)

		s.state.get_clipboard       = clipboard_get
		s.state.clipboard_user_data = &clipboard
		type_text(&s, "a")
		edit.perform_command(&s.state, .Paste)
		edit.perform_command(&s.state, .Paste)
		type_text(&s, "b")
		expect_undos(t, &s, {"axx", "ax", "a", ""})
	}
	{
		// Typing over a selection deletes and inserts in one step.
		s: State
		undo_init(&s, "abc", {.Kind})
		defer state_destroy(&s)

		s.state.selection = {3, 0}
		type_text(&s, "x")
		expect_undos(t, &s, {"abc"})
	}
	{
		s: State
		undo_init(&s, "", {.Word})
		defer state_destroy(&s)

		type_text(&s, "hello world")
		expect_undos(t, &s, {"hello ", ""})
	}
	{
		s: State
		undo_init(&s, "", {.Caret_Move})
		defer state_destroy(&s)

		type_text(&s, "ab")
		edit.perform_command(&s.state, .Left)
		type_text(&s, "c")
		expect_undos(t, &s, {"ab", ""})
	}
	{
		// Deleting leaves the caret where the next edit continues.
		s: State
		undo_init(&s, "", {.Caret_Move})
		defer state_destroy(&s)

		type_text(&s, "ab")
		edit.perform_command(&s.state, .Backspace)
		type_text(&s, "c")
		expect_undos(t, &s, {""})
	}
	{
		s: State
		undo_init(&s, "abc", {.Caret_Move})
		defer state_destroy(&s)

		s.state.selection = {3, 1}
		edit.selection_delete(&s.state)
		type_text(&s, "x")
		expect_undos(t, &s, {"abc"})
	}
	{
		s: State
		undo_init(&s, "", {.Every_Edit})
		defer state_destroy(&s)

		type_text(&s, "abc")
		expect_undos(t, &s, {"ab", "a", ""})
	}
	{
		// An edit after an undo starts a new step.
		s: State
		undo_init(&s, "", {})
		defer state_destroy(&s)

		type_text(&s, "abc")
		edit.perform_command(&s.state, .Undo)
		type_text(&s, "d")
		expect_undos(t, &s, {""})
	}
}

@(test)
test_undo_groups :: proc(t: ^testing.T) {
	{
		s: State
		undo_init(&s, "", {.Every_Edit})
		defer state_destroy(&s)

		edit.undo_group_begin(&s.state)
		type_text(&s, "abc")
		edit.undo_group_end(&s.state)
		type_text(&s, "d")
		expect_undos(t, &s, {"abc", ""})
	}
	{
		s: State
		undo_init(&s, "", {.Every_Edit})
		defer state_destroy(&s)

		edit.undo_group_begin(&s.state)
		edit.undo_group_begin(&s.state)
		type_text(&s, "ab")
		edit.undo_group_end(&s.state)
		type_text(&s, "c")
		edit.undo_group_end(&s.state)
		expect_undos(t, &s, {""})
	}
	{
		// A group is its own step, even when its edits would have merged with others.
		s: State
		undo_init(&s, "", {})
		defer state_destroy(&s)

		type_text(&s, "x")
		edit.undo_group_begin(&s.state)
		type_text(&s, "abc")
		edit.undo_group_end(&s.state)
		type_text(&s, "d")
		expect_undos(t, &s, {"xabc", "x", ""})
	}
	{
		s: State
		undo_init(&s, "", {})
		defer state_destroy(&s)

		edit.undo_group_begin(&s.state)
		type_text(&s, "a")
		pause(&s)
		type_text(&s, "b")
		edit.undo_group_end(&s.state)
		expect_undos(t, &s, {""})
	}
}
