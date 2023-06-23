package text_edit

/*
	Based off the articles by rxi:
		* https://rxi.github.io/textbox_behaviour.html
		* https://rxi.github.io/a_simple_undo_system.html
*/

import "core:runtime"
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


init :: proc(s: ^State, undo_text_allocator, undo_state_allocator: runtime.Allocator, undo_timeout := DEFAULT_UNDO_TIMEOUT) {
	s.undo_timeout = undo_timeout

	// Used for allocating `Undo_State`
	s.undo_text_allocator = undo_text_allocator

	s.undo.allocator = undo_state_allocator
	s.redo.allocator = undo_state_allocator
}

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
	s.current_time = time.tick_now()
	if s.undo_timeout <= 0 {
		s.undo_timeout = DEFAULT_UNDO_TIMEOUT
	}
	set_text(s, string(s.builder.buf[:]))
	undo_clear(s, &s.undo)
	undo_clear(s, &s.redo)
}

// Call at the end of each frame
end :: proc(s: ^State) {
	s.id = 0
	s.builder = nil
}

set_text :: proc(s: ^State, text: string) {
	strings.builder_reset(s.builder)
	strings.write_string(s.builder, text)
}


undo_state_push :: proc(s: ^State, undo: ^[dynamic]^Undo_State) -> mem.Allocator_Error {
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

undo :: proc(s: ^State, undo, redo: ^[dynamic]^Undo_State) {
	if len(undo) > 0 {
		undo_state_push(s, redo)
		item := pop(undo)
		s.selection = item.selection
		#no_bounds_check {
			set_text(s, string(item.text[:item.len]))
		}
		free(item, s.undo_text_allocator)
	}
}

undo_clear :: proc(s: ^State, undo: ^[dynamic]^Undo_State) {
	for len(undo) > 0 {
		item := pop(undo)
		free(item, s.undo_text_allocator)
	}
}

undo_check :: proc(s: ^State) {
	undo_clear(s, &s.redo)
	if time.tick_diff(s.last_edit_time, s.current_time) > s.undo_timeout {
		undo_state_push(s, &s.undo)
	}
	s.last_edit_time = s.current_time
}



input_text :: proc(s: ^State, text: string) {
	if len(text) == 0 {
		return
	}
	if has_selection(s) {
		selection_delete(s)
	}
	insert(s, s.selection[0], text)
	offset := s.selection[0] + len(text)
	s.selection = {offset, offset}
}

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
		insert(s, offset, string(b[:w]))
		offset += w
	}
	s.selection = {offset, offset}
}


insert :: proc(s: ^State, at: int, text: string) {
	undo_check(s)
	inject_at(&s.builder.buf, at, text)
}

remove :: proc(s: ^State, lo, hi: int) {
	undo_check(s)
	remove_range(&s.builder.buf, lo, hi)
}



has_selection :: proc(s: ^State) -> bool {
	return s.selection[0] != s.selection[1]
}

sorted_selection :: proc(s: ^State) -> (lo, hi: int) {
	lo = min(s.selection[0], s.selection[1])
	hi = max(s.selection[0], s.selection[1])
	lo = clamp(lo, 0, len(s.builder.buf))
	hi = clamp(hi, 0, len(s.builder.buf))
	s.selection[0] = lo
	s.selection[1] = hi
	return
}


selection_delete :: proc(s: ^State) {
	lo, hi := sorted_selection(s)
	remove(s, lo, hi)
	s.selection = {lo, lo}
}



translate_position :: proc(s: ^State, pos: int, t: Translation) -> int {
	is_continuation_byte :: proc(b: byte) -> bool {
		return b >= 0x80 && b < 0xc0
	}
	is_space :: proc(b: byte) -> bool {
		return b == ' ' || b == '\t' || b == '\n'
	}

	buf := s.builder.buf[:]

	pos := pos
	pos = clamp(pos, 0, len(buf))

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

move_to :: proc(s: ^State, t: Translation) {
	if t == .Left && has_selection(s) {
		lo, _ := sorted_selection(s)
		s.selection = {lo, lo}
	} else if t == .Right && has_selection(s) {
		_, hi := sorted_selection(s)
		s.selection = {hi, hi}
	} else {
		pos := translate_position(s, s.selection[0], t)
		s.selection = {pos, pos}
	}
}
select_to :: proc(s: ^State, t: Translation) {
	s.selection[0] = translate_position(s, s.selection[0], t)
}
delete_to :: proc(s: ^State, t: Translation) {
	if has_selection(s) {
		selection_delete(s)
	} else {
		lo := s.selection[0]
		hi := translate_position(s, lo, t)
		lo, hi = min(lo, hi), max(lo, hi)
		remove(s, lo, hi)
		s.selection = {lo, lo}
	}
}


current_selected_text :: proc(s: ^State) -> string {
	lo, hi := sorted_selection(s)
	return string(s.builder.buf[lo:hi])
}


cut :: proc(s: ^State) -> bool {
	if copy(s) {
		selection_delete(s)
		return true
	}
	return false
}

copy :: proc(s: ^State) -> bool {
	if s.set_clipboard != nil {
		return s.set_clipboard(s.clipboard_user_data, current_selected_text(s))
	}
	return s.set_clipboard != nil
}

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
	case .Select_All:        s.selection = {len(s.builder.buf), 0}
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
