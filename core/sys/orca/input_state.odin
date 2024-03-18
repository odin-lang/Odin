package orca

import "core:c"

key_state :: struct {
	lastUpdate: u64,
	transitionCount: u32,
	repeatCount: u32,
	down: c.bool,
	sysClicked: c.bool,
	sysDoubleClicked: c.bool,
	sysTripleClicked: c.bool,
}

keyboard_state :: struct {
	keys: [len(key_code)]key_state,
	mods: keymod_flags,
}

mouse_state :: struct {
	lastUpdate: u64,
	posValid: c.bool,
	pos: vec2,
	delta: vec2,
	wheel: vec2,

	_: struct #raw_union {
		buttons: [len(mouse_button)]key_state,

		_: struct {
			left: key_state,
			right: key_state,
			middle: key_state,
			ext1: key_state,
			ext2: key_state,
		}
	}
}

INPUT_TEXT_BACKING_SIZE :: 64

text_state :: struct {
	lastUpdate: u64,
	backing: [INPUT_TEXT_BACKING_SIZE]utf32,
	codePoints: str32,
}

clipboard_state :: struct {
	lastUpdate: u64,
	pastedText: str8,
}

input_state :: struct {
	frameCounter: u64,
	keyboard: keyboard_state,
	mouse: mouse_state,
	text: text_state,
	clipboard: clipboard_state,
}
