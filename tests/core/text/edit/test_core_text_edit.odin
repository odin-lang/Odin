package test_core_text_edit

import "core:slice"
import "core:strings"
import "core:testing"
import "core:text/edit"

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

	for translation in edit.Translation {
		s.state.selection = {0, 0}
		testing.expectf(t, edit.translate_position(&s.state, translation) == 0, "%v: expected 0", translation)
	}

	edit.select_word(&s.state)
	testing.expect_value(t, s.state.selection, [2]int{0, 0})
	edit.select_line(&s.state)
	testing.expect_value(t, s.state.selection, [2]int{0, 0})
	edit.select_hard_line(&s.state)
	testing.expect_value(t, s.state.selection, [2]int{0, 0})
}
