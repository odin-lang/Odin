#+build js wasm32, js wasm64p32
package wasm_js_interface

foreign import dom_lib "odin_dom"

Event_Kind :: enum u32 {
	Invalid,

	Load,
	Unload,
	Error,
	Resize,
	Visibility_Change,
	Fullscreen_Change,
	Fullscreen_Error,

	Click,
	Double_Click,
	Mouse_Move,
	Mouse_Over,
	Mouse_Out,
	Mouse_Up,
	Mouse_Down,

	Key_Up,
	Key_Down,
	Key_Press,

	Scroll,
	Wheel,

	Focus,
	Focus_In,
	Focus_Out,
	Submit,
	Blur,
	Change,
	Hash_Change,
	Select,

	Animation_Start,
	Animation_End,
	Animation_Iteration,
	Animation_Cancel,

	Copy,
	Cut,
	Paste,

	// Drag,
	// Drag_Start,
	// Drag_End,
	// Drag_Enter,
	// Drag_Leave,
	// Drag_Over,
	// Drop,

	Pointer_Cancel,
	Pointer_Down,
	Pointer_Enter,
	Pointer_Leave,
	Pointer_Move,
	Pointer_Over,
	Pointer_Up,
	Got_Pointer_Capture,
	Lost_Pointer_Capture,
	Pointer_Lock_Change,
	Pointer_Lock_Error,

	Selection_Change,
	Selection_Start,

	Touch_Cancel,
	Touch_End,
	Touch_Move,
	Touch_Start,

	Transition_Start,
	Transition_End,
	Transition_Run,
	Transition_Cancel,

	Context_Menu,

	Gamepad_Connected,
	Gamepad_Disconnected,

	Custom,

}
event_kind_string := [Event_Kind]string{
	.Invalid = "",

	.Load         = "load",
	.Unload       = "unload",
	.Error        = "error",
	.Resize       = "resize",
	.Visibility_Change = "visibilitychange",
	.Fullscreen_Change = "fullscreenchange",
	.Fullscreen_Error  = "fullscreenerror",

	.Click        = "click",
	.Double_Click = "dblclick",
	.Mouse_Move   = "mousemove",
	.Mouse_Over   = "mouseover",
	.Mouse_Out    = "mouseout",
	.Mouse_Up     = "mouseup",
	.Mouse_Down   = "mousedown",

	.Key_Up       = "keyup",
	.Key_Down     = "keydown",
	.Key_Press    = "keypress",

	.Scroll = "scroll",
	.Wheel = "wheel",

	.Focus        = "focus",
	.Focus_In     = "focusin",
	.Focus_Out    = "focusout",
	.Submit       = "submit",
	.Blur         = "blur",
	.Change       = "change",
	.Hash_Change  = "hashchange",
	.Select       = "select",

	.Animation_Start     = "animationstart",
	.Animation_End       = "animationend",
	.Animation_Iteration = "animationiteration",
	.Animation_Cancel    = "animationcancel",

	.Copy   = "copy",
	.Cut    = "cut",
	.Paste  = "paste",

	// .Drag,       = "drag",
	// .Drag_Start, = "dragstart",
	// .Drag_End,   = "dragend",
	// .Drag_Enter, = "dragenter",
	// .Drag_Leave, = "dragleave",
	// .Drag_Over,  = "dragover",
	// .Drop,       = "drop",

	.Pointer_Cancel       = "pointercancel",
	.Pointer_Down         = "pointerdown",
	.Pointer_Enter        = "pointerenter",
	.Pointer_Leave        = "pointerleave",
	.Pointer_Move         = "pointermove",
	.Pointer_Over         = "pointerover",
	.Pointer_Up           = "pointerup",
	.Got_Pointer_Capture  = "gotpointercapture",
	.Lost_Pointer_Capture = "lostpointercapture",
	.Pointer_Lock_Change  = "pointerlockchange",
	.Pointer_Lock_Error   = "pointerlockerror",

	.Selection_Change = "selectionchange",
	.Selection_Start  = "selectionstart",

	.Transition_Start  = "transitionstart",
	.Transition_End    = "transitionend",
	.Transition_Run    = "transitionrun",
	.Transition_Cancel = "transitioncancel",

	.Touch_Cancel = "touchcancel",
	.Touch_End    = "touchend",
	.Touch_Move   = "touchmove",
	.Touch_Start  = "touchstart",

	.Context_Menu = "contextmenu",

	.Gamepad_Connected    = "gamepadconnected",
	.Gamepad_Disconnected = "gamepaddisconnected",

	.Custom = "?custom?",
}

Delta_Mode :: enum u32 {
	Pixel = 0,
	Line  = 1,
	Page  = 2,
}

Key_Location :: enum u8 {
	Standard = 0,
	Left     = 1,
	Right    = 2,
	Numpad   = 3,
}

KEYBOARD_MAX_KEY_SIZE  :: 32
KEYBOARD_MAX_CODE_SIZE :: 32

GAMEPAD_MAX_ID_SIZE      :: 64
GAMEPAD_MAX_MAPPING_SIZE :: 64

GAMEPAD_MAX_BUTTONS :: 64
GAMEPAD_MAX_AXES    :: 16

Event_Target_Kind :: enum u32 {
	Element  = 0,
	Document = 1,
	Window   = 2,
}

Event_Phase :: enum u8 {
	None            = 0,
	Capturing_Phase = 1,
	At_Target       = 2,
	Bubbling_Phase  = 3,
}

Event_Option :: enum u8 {
	Bubbles    = 0,
	Cancelable = 1,
	Composed   = 2,
}
Event_Options :: distinct bit_set[Event_Option; u8]

Gamepad_Button :: struct {
	value:   f64,
	pressed: bool,
	touched: bool,
}

Gamepad_State :: struct {
	id:           string,
	mapping:      string,
	index:        int,
	connected:    bool,
	timestamp:    f64,

	button_count: int,
	axis_count:   int,
	buttons: [GAMEPAD_MAX_BUTTONS]Gamepad_Button `fmt:"v,button_count"`,
	axes:    [GAMEPAD_MAX_AXES]f64               `fmt:"v,axes_count"`,

	_id_len:      int `fmt:"-"`,
	_mapping_len: int `fmt:"-"`,
	_id_buf:      [GAMEPAD_MAX_ID_SIZE]byte      `fmt:"-"`,
	_mapping_buf: [GAMEPAD_MAX_MAPPING_SIZE]byte `fmt:"-"`,
}

Event :: struct {
	kind:                 Event_Kind,
	target_kind:          Event_Target_Kind,
	current_target_kind:  Event_Target_Kind,
	id:           string,
	timestamp:    f64,

	phase:        Event_Phase,
	options:      Event_Options,
	is_composing: bool,
	is_trusted:   bool,

	using data: struct #raw_union #align(8) {
		scroll: struct {
			delta: [2]f64,
		},
		visibility_change: struct {
			is_visible: bool,
		},
		wheel: struct {
			delta: [3]f64,
			delta_mode: Delta_Mode,
		},

		key: struct {
			key:  string,
			code: string,
			location: Key_Location,

			ctrl:   bool,
			shift:  bool,
			alt:    bool,
			meta:   bool,

			repeat: bool,

			_key_len:  int                         `fmt:"-"`,
			_code_len: int                         `fmt:"-"`,
			_key_buf:  [KEYBOARD_MAX_KEY_SIZE]byte `fmt:"-"`,
			_code_buf: [KEYBOARD_MAX_KEY_SIZE]byte `fmt:"-"`,
		},

		mouse: struct {
			screen:    [2]i64,
			client:    [2]i64,
			offset:    [2]i64,
			page:      [2]i64,
			movement:  [2]i64,

			ctrl:   bool,
			shift:  bool,
			alt:    bool,
			meta:   bool,

			button:  i16,
			buttons: bit_set[0..<16; u16],
		},

		gamepad: Gamepad_State,
	},


	user_data: rawptr,
	callback:  proc(e: Event),
}

@(default_calling_convention="contextless")
foreign dom_lib {
	event_stop_propagation           :: proc() ---
	event_stop_immediate_propagation :: proc() ---
	event_prevent_default            :: proc() ---
	dispatch_custom_event            :: proc(id: string, name: string, options := Event_Options{}) -> bool ---
}

add_event_listener :: proc(id: string, kind: Event_Kind, user_data: rawptr, callback: proc(e: Event), use_capture := false) -> bool {
	@(default_calling_convention="contextless")
	foreign dom_lib {
		@(link_name="add_event_listener")
		_add_event_listener :: proc(id: string, name: string, name_code: Event_Kind, user_data: rawptr, callback: proc "odin" (Event), use_capture: bool) -> bool ---
	}
	// TODO: Pointer_Lock_Change etc related stuff for all different browsers
	return _add_event_listener(id, event_kind_string[kind], kind, user_data, callback, use_capture)
}

remove_event_listener :: proc(id: string, kind: Event_Kind, user_data: rawptr, callback: proc(e: Event)) -> bool {
	@(default_calling_convention="contextless")
	foreign dom_lib {
		@(link_name="remove_event_listener")
		_remove_event_listener :: proc(id: string, name: string, user_data: rawptr, callback: proc "odin" (Event)) -> bool ---
	}
	return _remove_event_listener(id, event_kind_string[kind], user_data, callback)
}

add_window_event_listener :: proc(kind: Event_Kind, user_data: rawptr, callback: proc(e: Event), use_capture := false) -> bool {
	@(default_calling_convention="contextless")
	foreign dom_lib {
		@(link_name="add_window_event_listener")
		_add_window_event_listener :: proc(name: string, name_code: Event_Kind, user_data: rawptr, callback: proc "odin" (Event), use_capture: bool) -> bool ---
	}
	return _add_window_event_listener(event_kind_string[kind], kind, user_data, callback, use_capture)
}

remove_window_event_listener :: proc(kind: Event_Kind, user_data: rawptr, callback: proc(e: Event)) -> bool {
	@(default_calling_convention="contextless")
	foreign dom_lib {
		@(link_name="remove_window_event_listener")
		_remove_window_event_listener :: proc(name: string, user_data: rawptr, callback: proc "odin" (Event)) -> bool ---
	}
	return _remove_window_event_listener(event_kind_string[kind], user_data, callback)
}

remove_event_listener_from_event :: proc(e: Event) -> bool {
	if e.id == "" {
		return remove_window_event_listener(e.kind, e.user_data, e.callback)
	}
	return remove_event_listener(e.id, e.kind, e.user_data, e.callback)
}

add_custom_event_listener :: proc(id: string, name: string, user_data: rawptr, callback: proc(e: Event), use_capture := false) -> bool {
	@(default_calling_convention="contextless")
	foreign dom_lib {
		@(link_name="add_event_listener")
		_add_event_listener :: proc(id: string, name: string, name_code: Event_Kind, user_data: rawptr, callback: proc "odin" (Event), use_capture: bool) -> bool ---
	}
	return _add_event_listener(id, name, .Custom, user_data, callback, use_capture)
}
remove_custom_event_listener :: proc(id: string, name: string, user_data: rawptr, callback: proc(e: Event)) -> bool {
	@(default_calling_convention="contextless")
	foreign dom_lib {
		@(link_name="remove_event_listener")
		_remove_event_listener :: proc(id: string, name: string, user_data: rawptr, callback: proc "odin" (Event)) -> bool ---
	}
	return _remove_event_listener(id, name, user_data, callback)
}

get_gamepad_state :: proc "contextless" (index: int, s: ^Gamepad_State) -> bool {
	@(default_calling_convention="contextless")
	foreign dom_lib {
		@(link_name="get_gamepad_state")
		_get_gamepad_state :: proc(index: int, s: ^Gamepad_State) -> bool ---
	}

	if s == nil {
		return false
	}
	return _get_gamepad_state(index, s)
}


@(export, link_name="odin_dom_do_event_callback")
do_event_callback :: proc(user_data: rawptr, callback: proc(e: Event)) {
	@(default_calling_convention="contextless")
	foreign dom_lib {
		init_event_raw :: proc(e: ^Event) ---
	}

	if callback != nil {
		event := Event{
			user_data = user_data,
			callback  = callback,
		}


		init_event_raw(&event)

		#partial switch event.kind {
		case .Key_Up, .Key_Down, .Key_Press:
			event.key.key = string(event.key._key_buf[:event.key._key_len]) 
			event.key.code = string(event.key._code_buf[:event.key._code_len]) 
		case .Gamepad_Connected, .Gamepad_Disconnected:
			event.gamepad.id = string(event.gamepad._id_buf[:event.gamepad._id_len])
			event.gamepad.mapping = string(event.gamepad._mapping_buf[:event.gamepad._mapping_len])
		}

		callback(event)
	}
}