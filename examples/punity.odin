import win32 "core:sys/windows.odin";
import "core:fmt.odin";
import "core:os.odin";
import "core:mem.odin";


CANVAS_WIDTH  :: 128;
CANVAS_HEIGHT :: 128;
CANVAS_SCALE  :: 3;
FRAME_TIME    :: 1.0/30.0;
WINDOW_TITLE  :: "Punity\x00";

#assert(CANVAS_WIDTH % 16 == 0);


WINDOW_WIDTH  :: CANVAS_WIDTH  * CANVAS_SCALE;
WINDOW_HEIGHT :: CANVAS_HEIGHT * CANVAS_SCALE;


STACK_CAPACITY   :: 1<<20;
STORAGE_CAPACITY :: 1<<20;

DRAW_LIST_RESERVE :: 128;

MAX_KEYS :: 256;

Core :: struct {
	stack:   ^Bank,
	storage: ^Bank,

	running:       bool,
	key_modifiers: u32,
	key_states:    [MAX_KEYS]u8,
	key_deltas:    [MAX_KEYS]u8,

	perf_frame,
	perf_frame_inner,
	perf_step,
	perf_audio,
	perf_blit,
	perf_blit_cvt,
	perf_blit_gdi: Perf_Span,

	frame: i64,

	canvas:    Canvas,
	draw_list: ^Draw_List,
}

Perf_Span :: struct {
	stamp: f64,
	delta: f32,
}

Bank :: struct {
	memory: []u8,
	cursor: int,
}

Bank_State :: struct {
	state: Bank,
	bank: ^Bank,
}


Color :: struct #raw_union {
	using channels: struct{a, b, g, r: u8},
	rgba: u32,
}

Palette :: struct {
	colors: [256]Color,
	colors_count: u8,
}


Rect :: struct #raw_union {
	using minmax: struct {min_x, min_y, max_x, max_y: int},
	using pos: struct {left, top, right, bottom: int},
	e: [4]int,
}

Bitmap :: struct {
	pixels: []u8,
	width:  int,
	height: int,
}

Font :: struct {
	using bitmap: Bitmap,
	char_width:   int,
	char_height:  int,
}

Canvas :: struct {
	using bitmap: ^Bitmap,
	palette:      Palette,
	translate_x:  int,
	translate_y:  int,
	clip:         Rect,
	font:         ^Font,
}

DrawFlag :: enum {
	NONE   = 0,
	FLIP_H = 1<<0,
	FLIP_V = 1<<1,
	MASK   = 1<<2,
}

Draw_Item :: struct {}
Draw_List :: struct {
	items: []Draw_Item,
}

Key :: enum {
	Mod_Shift   = 0x0001,
	Mod_Control = 0x0002,
	Mod_Alt     = 0x0004,
	Mod_Super   = 0x0008,


	Unknown            =-1,
	Invalid            =-2,


	Lbutton            = 1,
	Rbutton            = 2,
	Cancel             = 3,
	Mbutton            = 4,


	Back               = 8,
	Tab                = 9,
	Clear              = 12,
	Return             = 13,
	Shift              = 16,
	Control            = 17,
	Menu               = 18,
	Pause              = 19,
	Capital            = 20,
	Kana               = 0x15,
	Hangeul            = 0x15,
	Hangul             = 0x15,
	Junja              = 0x17,
	Final              = 0x18,
	Hanja              = 0x19,
	Kanji              = 0x19,
	Escape             = 0x1B,
	Convert            = 0x1C,
	Non_Convert        = 0x1D,
	Accept             = 0x1E,
	Mode_Change        = 0x1F,
	Space              = 32,
	Prior              = 33,
	Next               = 34,
	End                = 35,
	Home               = 36,
	Left               = 37,
	Up                 = 38,
	Right              = 39,
	Down               = 40,
	Select             = 41,
	Print              = 42,
	Exec               = 43,
	Snapshot           = 44,
	Insert             = 45,
	Delete             = 46,
	Help               = 47,
	Lwin               = 0x5B,
	Rwin               = 0x5C,
	Apps               = 0x5D,
	Sleep              = 0x5F,
	Numpad0            = 0x60,
	Numpad1            = 0x61,
	Numpad2            = 0x62,
	Numpad3            = 0x63,
	Numpad4            = 0x64,
	Numpad5            = 0x65,
	Numpad6            = 0x66,
	Numpad7            = 0x67,
	Numpad8            = 0x68,
	Numpad9            = 0x69,
	Multiply           = 0x6A,
	Add                = 0x6B,
	Separator          = 0x6C,
	Subtract           = 0x6D,
	Decimal            = 0x6E,
	Divide             = 0x6F,
	F1                 = 0x70,
	F2                 = 0x71,
	F3                 = 0x72,
	F4                 = 0x73,
	F5                 = 0x74,
	F6                 = 0x75,
	F7                 = 0x76,
	F8                 = 0x77,
	F9                 = 0x78,
	F10                = 0x79,
	F11                = 0x7A,
	F12                = 0x7B,
	F13                = 0x7C,
	F14                = 0x7D,
	F15                = 0x7E,
	F16                = 0x7F,
	F17                = 0x80,
	F18                = 0x81,
	F19                = 0x82,
	F20                = 0x83,
	F21                = 0x84,
	F22                = 0x85,
	F23                = 0x86,
	F24                = 0x87,
	Numlock            = 0x90,
	Scroll             = 0x91,
	Lshift             = 0xA0,
	Rshift             = 0xA1,
	Lcontrol           = 0xA2,
	Rcontrol           = 0xA3,
	Lmenu              = 0xA4,
	Rmenu              = 0xA5,


	Apostrophe         = 39,  /* ' */
	Comma              = 44,  /* , */
	Minus              = 45,  /* - */
	Period             = 46,  /* . */
	Slash              = 47,  /* / */
	Num0               = 48,
	Num1               = 49,
	Num2               = 50,
	Num3               = 51,
	Num4               = 52,
	Num5               = 53,
	Num6               = 54,
	Num7               = 55,
	Num8               = 56,
	Num9               = 57,
	Semicolon          = 59,  /* ; */
	Equal              = 61,  /* = */
	A                  = 65,
	B                  = 66,
	C                  = 67,
	D                  = 68,
	E                  = 69,
	F                  = 70,
	G                  = 71,
	H                  = 72,
	I                  = 73,
	J                  = 74,
	K                  = 75,
	L                  = 76,
	M                  = 77,
	N                  = 78,
	O                  = 79,
	P                  = 80,
	Q                  = 81,
	R                  = 82,
	S                  = 83,
	T                  = 84,
	U                  = 85,
	V                  = 86,
	W                  = 87,
	X                  = 88,
	Y                  = 89,
	Z                  = 90,
	Left_Bracket       = 91,  /* [ */
	Backslash          = 92,  /* \ */
	Right_Bracket      = 93,  /* ] */
	Grave_Accent       = 96,  /* ` */
};


key_down :: proc(k: Key) -> bool {
	return _core.key_states[k] != 0;
}

key_pressed :: proc(k: Key) -> bool {
	return (_core.key_deltas[k] != 0) && key_down(k);
}




win32_perf_count_freq := win32.get_query_performance_frequency();
time_now :: proc() -> f64 {
	assert(win32_perf_count_freq != 0);

	counter: i64;
	win32.query_performance_counter(&counter);
	return f64(counter) / f64(win32_perf_count_freq);
}

_core: Core;

run :: proc(user_init, user_step: proc(c: ^Core)) {
	using win32;

	_core.running = true;

	win32_proc :: proc(hwnd: win32.Hwnd, msg: u32, wparam: win32.Wparam, lparam: win32.Lparam) -> win32.Lresult #no_inline #cc_c {
		win32_app_key_mods :: proc() -> u32 {
			mods: u32 = 0;

			if is_key_down(Key_Code.Shift)   do mods |= u32(Key.Mod_Shift);
			if is_key_down(Key_Code.Control) do mods |= u32(Key.Mod_Control);
			if is_key_down(Key_Code.Menu)    do mods |= u32(Key.Mod_Alt);
			if is_key_down(Key_Code.Lwin)    do mods |= u32(Key.Mod_Super);
			if is_key_down(Key_Code.Rwin)    do mods |= u32(Key.Mod_Super);

			return mods;
		}

		match msg {
		case WM_KEYDOWN:
			_core.key_modifiers = win32_app_key_mods();
			if wparam < MAX_KEYS {
				_core.key_states[wparam] = 1;
				_core.key_deltas[wparam] = 1;
			}
			return 0;

		case WM_KEYUP:
			_core.key_modifiers = win32_app_key_mods();
			if wparam < MAX_KEYS {
				_core.key_states[wparam] = 0;
				_core.key_deltas[wparam] = 1;
			}
			return 0;

		case WM_CLOSE:
			post_quit_message(0);
			_core.running = false;
			return 0;
		}

		return def_window_proc_a(hwnd, msg, wparam, lparam);
	}


	class_name := "Punity\x00";
	window_class := Wnd_Class_Ex_A{
		class_name = &class_name[0],
		size       = size_of(Wnd_Class_Ex_A),
		style      = CS_HREDRAW | CS_VREDRAW | CS_OWNDC,
		instance   = Hinstance(get_module_handle_a(nil)),
		wnd_proc   = win32_proc,
		background = Hbrush(get_stock_object(BLACK_BRUSH)),
	};

	if register_class_ex_a(&window_class) == 0 {
		fmt.fprintln(os.stderr, "register_class_ex_a failed");
		return;
	}

	screen_width  := get_system_metrics(SM_CXSCREEN);
	screen_height := get_system_metrics(SM_CYSCREEN);

	rc: Rect;
	rc.left   = (screen_width - WINDOW_WIDTH)   / 2;
	rc.top    = (screen_height - WINDOW_HEIGHT) / 2;
	rc.right  = rc.left + WINDOW_WIDTH;
	rc.bottom = rc.top + WINDOW_HEIGHT;

	style: u32 = WS_CAPTION | WS_SYSMENU | WS_MINIMIZEBOX;
	assert(adjust_window_rect(&rc, style, 0) != 0);

	wt := WINDOW_TITLE;

	win32_window := create_window_ex_a(0,
	                                   window_class.class_name,
	                                   &wt[0],
	                                   style,
	                                   rc.left, rc.top,
	                                   rc.right-rc.left, rc.bottom-rc.top,
	                                   nil, nil, window_class.instance,
	                                   nil);

	if win32_window == nil {
		fmt.fprintln(os.stderr, "create_window_ex_a failed");
		return;
	}


	window_bmi: Bitmap_Info;
	window_bmi.size        = size_of(Bitmap_Info_Header);
	window_bmi.width       = CANVAS_WIDTH;
	window_bmi.height      = CANVAS_HEIGHT;
	window_bmi.planes      = 1;
	window_bmi.bit_count   = 32;
	window_bmi.compression = BI_RGB;


	user_init(&_core);

	show_window(win32_window, SW_SHOW);

	window_buffer := make([]u32, CANVAS_WIDTH * CANVAS_HEIGHT);
	defer free(window_buffer);

	for _, i in window_buffer do window_buffer[i] = 0xff00ff;

	dt: f64;
	prev_time := time_now();
	curr_time := time_now();
	total_time: f64 = 0;
	offset_x := 0;
	offset_y := 0;

	message: Msg;
	for _core.running {
		curr_time = time_now();
		dt = curr_time - prev_time;
		prev_time = curr_time;
		total_time += dt;

		offset_x += 1;
		offset_y += 2;

		{
			buf: [128]u8;
			s := fmt.bprintf(buf[..], "Punity: %.4f ms\x00", dt*1000);
			win32.set_window_text_a(win32_window, &s[0]);
		}


		for y in 0..CANVAS_HEIGHT {
			for x in 0..CANVAS_WIDTH {
				g := (x % 32) * 8;
				b := (y % 32) * 8;
				window_buffer[x + y*CANVAS_WIDTH] = u32(g << 8 | b);
			}
		}

		mem.zero(&_core.key_deltas[0], size_of(_core.key_deltas));

		for peek_message_a(&message, nil, 0, 0, PM_REMOVE) != 0 {
			if message.message == WM_QUIT {
				_core.running = false;
			}
			translate_message(&message);
			dispatch_message_a(&message);
		}

		user_step(&_core);

		dc := get_dc(win32_window);
		stretch_dibits(dc,
		               0, 0, CANVAS_WIDTH * CANVAS_SCALE, CANVAS_HEIGHT * CANVAS_SCALE,
		               0, 0, CANVAS_WIDTH, CANVAS_HEIGHT,
		               &window_buffer[0],
		               &window_bmi,
		               DIB_RGB_COLORS,
		               SRCCOPY);
		release_dc(win32_window, dc);



		delta := time_now() - prev_time;
		if ms := i32((FRAME_TIME - delta) * 1000); ms > 0 {
			win32.sleep(ms);
		}

		_core.frame += 1;
	}
}


main :: proc() {
	user_init :: proc(c: ^Core) {

	}

	user_step :: proc(c: ^Core) {

	}

	run(user_init, user_step);
}
