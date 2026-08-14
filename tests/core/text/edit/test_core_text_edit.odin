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

	expect_walk(t, &s, 0, .Word_Right, {4, 9, 12})
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
