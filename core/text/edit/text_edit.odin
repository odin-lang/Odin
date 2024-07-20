package text_edit

/*
	Based off the articles by rxi:
		* https://rxi.github.io/textbox_behaviour.html
		* https://rxi.github.io/a_simple_undo_system.html
*/

import "base:runtime"
import "core:time"
import "core:mem"
import "core:strings"
import "core:unicode/utf8"

DEFAULT_UNDO_TIMEOUT :: 300 * time.Millisecond

State :: struct {
	selection: [2]int,
	line_start, line_end: int,

	// initialized each "frame" with `begin`
	builder: ^strings.Builder, // let the caller store the text buffer data

	up_index, down_index: int, // multi-lines


	// undo
	undo: [dynamic]^Undo_State,
	redo: [dynamic]^Undo_State,
	undo_text_allocator: runtime.Allocator,

	id: u64, // useful for immediate mode GUIs

	// Timeout information
	current_time:   time.Tick,
	last_edit_time: time.Tick,
	undo_timeout:   time.Duration,

	// Set these if you want cut/copy/paste functionality
	set_clipboard: proc(user_data: rawptr, text: string) -> (ok: bool),
	get_clipboard: proc(user_data: rawptr) -> (text: string, ok: bool),
	clipboard_user_data: rawptr,
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
	Word_Left,
	Word_Right,
	Word_Start,
	Word_End,
	Soft_Line_Start,
	Soft_Line_End,
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
	undo_clear(s, &s.undo)
	undo_clear(s, &s.redo)
}

// returns true when the builder had content to be cleared
// clear builder&selection and the undo|redo stacks
clear_all :: proc(s: ^State) -> (cleared: bool) {
	if s.builder != nil && len(s.builder.buf) > 0 {
		clear(&s.builder.buf)
		s.selection = {}
		cleared = true
	}

	undo_clear(s, &s.undo)
	undo_clear(s, &s.redo)
	return
}

// push current text state to the wanted undo|redo stack
undo_state_push :: proc(s: ^State, undo: ^[dynamic]^Undo_State) -> mem.Allocator_Error {
	if s.builder != nil {
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

// insert text into the edit state - deletes the current selection
input_text :: proc(s: ^State, text: string) -> int {
	if len(text) == 0 {
		return 0
	}
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
	if has_selection(s) {
		selection_delete(s)
	}
	offset := s.selection[0]
	b, w := utf8.encode_rune(r)
	n := insert(s, offset, string(b[:w]))
	offset += n
	s.selection = {offset, offset}
}

// insert a single rune into the edit state - deletes the current selection
insert :: proc(s: ^State, at: int, text: string) -> int {
	undo_check(s)
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
	undo_check(s)
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
	lo, hi := sorted_selection(s)
	remove(s, lo, hi)
	s.selection = {lo, lo}
}

is_continuation_byte :: proc(b: byte) -> bool {
	return b >= 0x80 && b < 0xc0
}

// translates the caret position 
translate_position :: proc(s: ^State, t: Translation) -> int {
	is_space :: proc(b: byte) -> bool {
		return b == ' ' || b == '\t' || b == '\n'
	}

	buf: []byte
	if s.builder != nil {
		buf = s.builder.buf[:]
	}
	pos := clamp(s.selection[0], 0, len(buf))

	switch t {
	case .Start:
		pos = 0
	case .End:
		pos = len(buf)
	case .Left:
		pos -= 1
		for pos >= 0 && is_continuation_byte(buf[pos]) {
			pos -= 1
		}
	case .Right:
		pos += 1
		for pos < len(buf) && is_continuation_byte(buf[pos]) {
			pos += 1
		}
	case .Up:
		pos = s.up_index
	case .Down:
		pos = s.down_index
	case .Word_Left:
		for pos > 0 && is_space(buf[pos-1]) {
			pos -= 1
		}
		for pos > 0 && !is_space(buf[pos-1]) {
			pos -= 1
		}
	case .Word_Right:
		for pos < len(buf) && !is_space(buf[pos]) {
			pos += 1
		}
		for pos < len(buf) && is_space(buf[pos]) {
			pos += 1
		}
	case .Word_Start:
		for pos > 0 && !is_space(buf[pos-1]) {
			pos -= 1
		}
	case .Word_End:
		for pos < len(buf) && !is_space(buf[pos]) {
			pos += 1
		}
	case .Soft_Line_Start:
		pos = s.line_start
	case .Soft_Line_End:
		pos = s.line_end
	}
	return clamp(pos, 0, len(buf))
}

// Moves the position of the caret (both sides of the selection)
move_to :: proc(s: ^State, t: Translation) {
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
	s.selection[0] = translate_position(s, t)
}

// Deletes everything between the caret and resultant position
delete_to :: proc(s: ^State, t: Translation) {
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
	if copy(s) {
		selection_delete(s)
		return true
	}
	return false
}

// try and copy the currently selected text to the clipboard
// State.set_clipboard needs to be assigned
copy :: proc(s: ^State) -> bool {
	if s.set_clipboard != nil {
		return s.set_clipboard(s.clipboard_user_data, current_selected_text(s))
	}
	return s.set_clipboard != nil
}

// reinsert whatever the get_clipboard would return
// State.get_clipboard needs to be assigned
paste :: proc(s: ^State) -> bool {
	if s.get_clipboard != nil {
		input_text(s, s.get_clipboard(s.clipboard_user_data) or_return)
	}
	return s.get_clipboard != nil
}


Command_Set :: distinct bit_set[Command; u32]

Command :: enum u32 {
	None,
	Undo,
	Redo,
	New_Line,    // multi-lines
	Cut,
	Copy,
	Paste,
	Select_All,
	Backspace,
	Delete,
	Delete_Word_Left,
	Delete_Word_Right,
	Left,
	Right,
	Up,          // multi-lines
	Down,        // multi-lines
	Word_Left,
	Word_Right,
	Start,
	End,
	Line_Start,
	Line_End,
	Select_Left,
	Select_Right,
	Select_Up,   // multi-lines
	Select_Down, // multi-lines
	Select_Word_Left,
	Select_Word_Right,
	Select_Start,
	Select_End,
	Select_Line_Start,
	Select_Line_End,
}

MULTILINE_COMMANDS :: Command_Set{.New_Line, .Up, .Down, .Select_Up, .Select_Down}

perform_command :: proc(s: ^State, cmd: Command) {
	switch cmd {
	case .None:              /**/
	case .Undo:              undo(s, &s.undo, &s.redo)
	case .Redo:              undo(s, &s.redo, &s.undo)
	case .New_Line:          input_text(s, "\n")
	case .Cut:               cut(s)
	case .Copy:              copy(s)
	case .Paste:             paste(s)
	case .Select_All:        s.selection = {len(s.builder.buf) if s.builder != nil else 0, 0}
	case .Backspace:         delete_to(s, .Left)
	case .Delete:            delete_to(s, .Right)
	case .Delete_Word_Left:  delete_to(s, .Word_Left)
	case .Delete_Word_Right: delete_to(s, .Word_Right)
	case .Left:              move_to(s, .Left)
	case .Right:             move_to(s, .Right)
	case .Up:                move_to(s, .Up)
	case .Down:              move_to(s, .Down)
	case .Word_Left:         move_to(s, .Word_Left)
	case .Word_Right:        move_to(s, .Word_Right)
	case .Start:             move_to(s, .Start)
	case .End:               move_to(s, .End)
	case .Line_Start:        move_to(s, .Soft_Line_Start)
	case .Line_End:          move_to(s, .Soft_Line_End)
	case .Select_Left:       select_to(s, .Left)
	case .Select_Right:      select_to(s, .Right)
	case .Select_Up:         select_to(s, .Up)
	case .Select_Down:       select_to(s, .Down)
	case .Select_Word_Left:  select_to(s, .Word_Left)
	case .Select_Word_Right: select_to(s, .Word_Right)
	case .Select_Start:      select_to(s, .Start)
	case .Select_End:        select_to(s, .End)
	case .Select_Line_Start: select_to(s, .Soft_Line_Start)
	case .Select_Line_End:   select_to(s, .Soft_Line_End)
	}
}
